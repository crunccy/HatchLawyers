# tools/blender/overhaul/export_models.py - the MAP MODEL OVERHAUL as .fbx meshes for crnuch to import into Studio
# (crnuch 2026-10-26: "go export them"). Every model is built on its own (the same list as check_models.py, plus the
# trees, the Dingy Shack and the travel portal), or a whole island scene, then:
#   - text / curves become meshes, transforms are applied (1 Blender m = 1 stud);
#   - stud UVs: box-projected on each face's main axis, 1 UV unit = 1 stud, so MaterialService.BrickStuds (StudsPerTile 1)
#     lays the same half-stud grid as on the Parts; a strongly curved face gets its UVs on a plain spot between studs
#     (no studs - gagstuds.py fades them out there too);
#   - a mesh over MAX_TRIS is cut into pieces (a MeshPart takes at most 20,000 triangles).
# One .fbx per group (each model an empty with its meshes, laid out in a row) into exports/overhaul/ (not in git), and
# its looks list into tools/zones/overhaul/<group>.json: per model its origin + size, per mesh the Roblox Color /
# Material / Transparency the install sets (Plastic = studded; glow -> Neon; see-through, water, glass -> SmoothPlastic).
#   Blender -b --factory-startup --python tools/blender/overhaul/export_models.py -- models [<group> ...]
#   Blender -b --factory-startup --python tools/blender/overhaul/export_models.py -- island <hub|bay|pet|rot|food|ocean|space>
#   (add "full" to skip the phone / tablet budget: phone_budget)
# groups: trees shack portal props hub gameplay minigames firms hall bay kit pet rot food ocean space
import bpy, json, os, re, sys
import numpy as np
from mathutils import Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
MODE = ARGS[0] if ARGS else "models"
WANT = set(a for a in ARGS[1:] if a != "full") or None
OUT = os.path.join(ROOT, "exports", "overhaul")
LOOKS = os.path.join(ROOT, "tools", "zones", "overhaul")
TMP = os.path.join(OUT, "_tmp")  # (the build scripts' own out dir: sandbox JSON, no renders)
for d in (OUT, LOOKS, TMP):
    os.makedirs(d, exist_ok=True)
MAX_TRIS = 19500
EDITION = "2"  # (bump for every re-export crnuch imports: island_hub_phone2.fbx ...; 2 = mr.robe's multi-look split, 2026-10-27)
PHONE = "full" not in ARGS  # (the phone / tablet budget: phone_budget; "full" exports every triangle)
FLAT = 0.79  # (a face whose normal is further than this from every axis is curved: no studs)
GAP = 24.0   # (studs between models in a group's row)
SKIP_NAMES = ("Preview", "Scene", "Studs", "StudSource", "Sky_", "Label", "Diagram", "Egg_Spot", "OLD", "Boss_")  # (Boss_: the islands' boss stand-ins - the bosses are ReplicatedStorage.Bosses)
SKIP_COLLS = ("Sky", "Label", "Diagram", "Gameplay_Markers", "Preview", "Camera")
SCATTER = re.compile(r"(Oak|Blossom|Hedge|Pine|Bush|Palm|Tuft|Topiary|Tree|Canopy|Shell|Star|Drift|Coral|Conch|Fan|Brain)")
ISLANDS = {"hub": "island_hub", "bay": "island_briefcase_bay", "pet": "island_pet_park", "rot": "island_brainrot",
           "food": "island_food_court", "ocean": "island_ocean_shore", "space": "island_space_base"}
sys.argv = [sys.argv[0], "--", TMP] + (["places_only"] if MODE == "island" else [])  # (what the build scripts read)
import ohkit as O
import island_kit as IK
import gagstuds
import hl_kit as K


# ------------------------------------------------------------------ meshes
def plain_meshes(objs):
    """Every object as a mesh object in world space (text / curves converted, modifiers + transforms applied)."""
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for ob in objs:
        name = ob.name
        if ob.type == "MESH" and not ob.modifiers:
            if ob.data.users > 1:
                ob.data = ob.data.copy()
            me = ob.data
        else:
            me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg), depsgraph=dg)
        me.transform(ob.matrix_world)
        if me is ob.data:
            ob.parent = None
            ob.matrix_world = Matrix.Identity(4)
            out.append(ob)
            continue
        bpy.data.objects.remove(ob)
        new = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(new)
        out.append(new)
    return out


SPLIT = [0, 0]  # (meshes with more than one look, pieces they became)


def by_material(ob):
    """A mesh with several looks (the v2 frame's ClassicMeshes: road + curbs + dashes + paths, grass + dirt ...) as one
    object per look: a MeshPart takes ONE colour, so the install painted every face the first look (mr.robe 2026-10-26:
    the hub's roads all road-grey, its grass all dirt). Named <name>_<look>."""
    import bmesh
    me = ob.data
    used = sorted(set(p.material_index for p in me.polygons))
    if len(me.materials) < 2 or len(used) < 2:
        return [ob]
    SPLIT[0] += 1
    out = []
    for mi in used:
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != mi], context="FACES")
        nm = bpy.data.meshes.new(me.name)
        bm.to_mesh(nm)
        bm.free()
        mat = me.materials[mi]
        nm.materials.clear()
        nm.materials.append(mat)
        for p in nm.polygons:
            p.material_index = 0
        look = re.sub(r"\.\d+$", "", mat.name) if mat else "?"
        new = bpy.data.objects.new(f"{ob.name}_{look}", nm)
        bpy.context.scene.collection.objects.link(new)
        out.append(new)
    SPLIT[1] += len(out)
    bpy.data.objects.remove(ob)
    return out


def stud_uvs(me):
    """One UV map: each face box-projected on its main axis in studs (u, v = x, y on tops; y, z / x, z on the sides,
    v up); curved faces all sit on (0, 0), the plain corner between four studs."""
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="UVMap")
    nv, nl, npl = len(me.vertices), len(me.loops), len(me.polygons)
    if not nl:
        return
    co = np.empty(nv * 3)
    me.vertices.foreach_get("co", co)
    lv = np.empty(nl, dtype=np.int64)
    me.loops.foreach_get("vertex_index", lv)
    pn = np.empty(npl * 3)
    me.polygons.foreach_get("normal", pn)
    ls, lt = np.empty(npl, dtype=np.int64), np.empty(npl, dtype=np.int64)
    me.polygons.foreach_get("loop_start", ls)
    me.polygons.foreach_get("loop_total", lt)
    poly = np.empty(nl, dtype=np.int64)
    for i in np.argsort(ls):  # (each loop's face)
        poly[ls[i]:ls[i] + lt[i]] = i
    a = np.abs(pn.reshape(-1, 3))[poly]
    p = co.reshape(-1, 3)[lv]
    wz = (a[:, 2] >= a[:, 0]) & (a[:, 2] >= a[:, 1])
    wx = ~wz & (a[:, 0] > a[:, 1])
    u = np.where(wx, p[:, 1], p[:, 0])
    v = np.where(wz, p[:, 1], p[:, 2])
    curved = a.max(axis=1) < FLAT
    u[curved], v[curved] = 0.0, 0.0
    uv.data.foreach_set("uv", np.column_stack((u, v)).astype(np.float32).ravel())


def bounds(objs, world=False):
    """(min, max) corners of the objects' vertices."""
    pts = []
    for ob in objs:
        co = np.empty(len(ob.data.vertices) * 3)
        ob.data.vertices.foreach_get("co", co)
        co = co.reshape(-1, 3)
        if world:
            M = np.array(ob.matrix_world)
            co = co @ M[:3, :3].T + M[:3, 3]
        pts.append((co.min(axis=0), co.max(axis=0)))
    return np.min([p[0] for p in pts], axis=0), np.max([p[1] for p in pts], axis=0)


def tri_counts(me):
    lt = np.empty(len(me.polygons), dtype=np.int64)
    me.polygons.foreach_get("loop_total", lt)
    return lt - 2


FOLIAGE = re.compile(r"leaf|leaves|blossom|hedge|bush|fern|frond|palm|flower|grass|daisy|lily|lotus|ivy|moss|tuft|canopy|petal|"
                     r"seaweed|topiary|pine|needle|kelp|oak", re.I)
SOFT = re.compile(r"underside|foam|mist|water", re.I)


def phone_budget(ob, key):
    """Phones and tablets (crnuch 2026-10-26): every mesh loses its coplanar triangles (no visible change); lumpy foliage
    keeps a quarter of its triangles, round props over 1,500 triangles half, undersides / foam / water 40% (Roblox's own
    LOD lowers them further with distance). Returns (before, after) triangles."""
    import bmesh, math
    me = ob.data
    t0 = int(tri_counts(me).sum())
    look = me.materials[0].name if me.materials else ""
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1.0), verts=bm.verts[:], edges=bm.edges[:])
    bm.to_mesh(me)
    bm.free()
    smooth = sum(p.use_smooth for p in me.polygons) / max(1, len(me.polygons))
    t1 = int(tri_counts(me).sum())
    ratio = 0.25 if (FOLIAGE.search(look) or FOLIAGE.search(key)) and not re.search(r"bark|trunk|wood", look, re.I) else \
        0.4 if SOFT.search(look) or SOFT.search(key) else 0.5 if smooth > 0.5 and t1 > 1500 else None
    if ratio:
        mod = ob.modifiers.new("phone", "DECIMATE")
        mod.ratio = ratio
        with bpy.context.temp_override(object=ob, active_object=ob):
            bpy.ops.object.modifier_apply(modifier=mod.name)
    return t0, int(tri_counts(ob.data).sum())


BUDGET = [0, 0]


def split(ob):
    """A mesh over MAX_TRIS cut in halves along its longest side until every piece fits: [objects]."""
    import bmesh
    me = ob.data
    t = tri_counts(me)
    if t.sum() <= MAX_TRIS:
        return [ob]
    c = np.empty(len(me.polygons) * 3)
    me.polygons.foreach_get("center", c)
    c = c.reshape(-1, 3)

    def parts(idx):
        if t[idx].sum() <= MAX_TRIS or len(idx) < 2:
            return [idx]
        cc = c[idx]
        order = idx[np.argsort(cc[:, int(np.argmax(cc.max(0) - cc.min(0)))], kind="stable")]
        cum = np.cumsum(t[order])
        cut = int(np.clip(np.searchsorted(cum, cum[-1] / 2.0), 1, len(order) - 1))
        return parts(order[:cut]) + parts(order[cut:])
    out = []
    for k, idx in enumerate(parts(np.arange(len(me.polygons)))):
        keep = np.zeros(len(me.polygons), dtype=bool)
        keep[idx] = True
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.faces.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if not keep[f.index]], context="FACES")
        m2 = bpy.data.meshes.new(f"{ob.name}_{k + 1}")
        bm.to_mesh(m2)
        bm.free()
        for m in me.materials:
            m2.materials.append(m)
        o2 = bpy.data.objects.new(f"{ob.name}_{k + 1}", m2)
        bpy.context.scene.collection.objects.link(o2)
        out.append(o2)
    bpy.data.objects.remove(ob)
    return out


# ------------------------------------------------------------------ looks
def srgb(x):
    return 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055


def look_of(ob):
    """What the install sets on the MeshPart: Color, Material (Plastic = the studs), Transparency, Reflectance."""
    m = ob.data.materials[0] if ob.data.materials else None
    look = re.sub(r"\.\d+$", "", m.name) if m else "?"
    b = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) if m and m.use_nodes else None
    alpha = b.inputs["Alpha"].default_value if b else 1.0
    emit = b.inputs["Emission Strength"].default_value if b else 0.0
    if look in K.GLOWS:
        rgb = K.GLOWS[look][0]
    elif look in K.GLASS:
        rgb = K.GLASS[look]
    elif look in K.PAL:
        rgb = K.PAL[look]
    else:
        col = b.inputs["Base Color"].default_value if b else (m.diffuse_color if m else (1, 1, 1, 1))
        rgb = tuple(round(255 * srgb(col[i])) for i in range(3))
    smooth = any(k in look.lower() for k in gagstuds.SKIP) or alpha < 0.99 or emit > 0.01 or \
        (b is not None and b.inputs["Transmission Weight"].default_value > 0.01)
    return {"look": look, "color": [int(round(x)) for x in rgb],
            "material": "Neon" if emit > 0.01 else ("SmoothPlastic" if smooth else "Plastic"),
            "transparency": round(1.0 - alpha, 2) if alpha < 0.99 else 0,
            "reflectance": 0.2 if look.startswith("glass") else 0}


# ------------------------------------------------------------------ groups
EXPORT = []   # (the objects of the group being written)
MODELS = {}   # (model -> its looks entry)
CURSOR = [0.0]


def wanted(ob, colls=True):
    if ob.type not in ("MESH", "CURVE", "FONT") or ob.name.startswith(SKIP_NAMES) or ob.hide_render:
        return False
    return not (colls and any(any(k in c.name for k in SKIP_COLLS) for c in ob.users_collection))


def by_look(objs, key):
    """Objects of one look joined into one mesh (a kind of scattered scenery: its pieces never move on their own)."""
    looks = {}
    for ob in objs:
        looks.setdefault(look_of(ob)["look"], []).append(ob)
    out = []
    for look, obs in sorted(looks.items()):
        if len(obs) > 1:
            with bpy.context.temp_override(active_object=obs[0], selected_editable_objects=obs):
                bpy.ops.object.join()
        obs[0].name = f"{key}_{look}"
        out.append(obs[0])
    return out


def add_model(key, objs, place=True, merge=False):
    """objs (built at the origin) -> plain meshes with stud UVs, split to fit, moved to the next spot in the row
    (place) under an empty named key. merge: one mesh per look first (scattered plants, shells ...)."""
    objs = [ob for ob in objs if wanted(ob)]
    if not objs:
        print(f"[export] {key}: nothing to export")
        return
    meshes, plain = [], []
    for ob in plain_meshes(objs):
        if len(ob.data.polygons):
            plain.append(ob)
        else:
            bpy.data.objects.remove(ob)
    plain = [p for ob in plain for p in by_material(ob)]
    for ob in (by_look(plain, key) if merge else plain):
        if PHONE:
            a, b = phone_budget(ob, key)
            BUDGET[0] += a
            BUDGET[1] += b
        stud_uvs(ob.data)
        meshes += split(ob)
    if not meshes:  # (only empty text / curves)
        print(f"[export] {key}: no faces")
        return
    lo, hi = bounds(meshes)
    dx = (CURSOR[0] - lo[0]) if place else 0.0
    if place:
        CURSOR[0] += (hi[0] - lo[0]) + GAP
    root = bpy.data.objects.new(key, None)
    root.location = (dx, 0.0, 0.0)
    bpy.context.scene.collection.objects.link(root)
    entry = {"origin": [round(dx, 3), 0.0, 0.0], "min": [round(x, 2) for x in lo], "max": [round(x, 2) for x in hi], "meshes": []}
    for ob in meshes:
        ob.data.transform(Matrix.Translation((dx, 0.0, 0.0)))
        ob.parent = root
        ob.matrix_parent_inverse = root.matrix_world.inverted()
        entry["meshes"].append({"name": re.sub(r"\.\d+$", "", ob.name), "fbx_name": ob.name, "tris": int(tri_counts(ob.data).sum()),
                                **look_of(ob)})
    MODELS[key] = entry
    EXPORT.extend([root] + meshes)


def write_group(group):
    if not EXPORT:
        print(f"[export] {group}: empty")
        return
    bpy.context.view_layer.update()
    for ob in bpy.data.objects:
        ob.select_set(False)
    for ob in EXPORT:
        for c in list(ob.users_collection):
            c.objects.unlink(ob)
        bpy.context.scene.collection.objects.link(ob)
        ob.hide_set(False)
        ob.hide_viewport = False
        ob.select_set(True)
    name = group + ("_phone" if PHONE else "_FULL") + EDITION  # (a new name each time: Studio's importer reused an old file of the same name)
    path = os.path.join(OUT, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"EMPTY", "MESH"}, apply_unit_scale=True,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False,
                             add_leaf_bones=False, bake_anim=False, path_mode="AUTO")
    meshes = [m for e in MODELS.values() for m in e["meshes"]]
    info = {"group": group, "fbx": "exports/overhaul/" + name + ".fbx", "made": "2026-10-26",
            "units": "1 Blender m = 1 stud; Blender (x, y, z) -> Roblox (x, z, -y) after the FBX axis change",
            "studs": "Material Plastic = studded by MaterialService.BrickStuds through the stud UVs (StudsPerTile 1)",
            "models": MODELS}
    with open(os.path.join(LOOKS, group + ".json"), "w") as fh:
        json.dump(info, fh, indent=1)
    big = max(m["tris"] for m in meshes)
    if PHONE:
        print(f"[export] {group}: phone budget {BUDGET[0]} -> {BUDGET[1]} tris")
        BUDGET[0] = BUDGET[1] = 0
    print(f"[export] {group}: {len(MODELS)} models, {len(meshes)} meshes, {sum(m['tris'] for m in meshes)} tris "
          f"(biggest mesh {big}), {os.path.getsize(path) // 1024} KB -> {path}")
    print(f"[export] {group}: {SPLIT[0]} meshes had several looks -> {SPLIT[1]} one-look meshes")
    SPLIT[0] = SPLIT[1] = 0
    clear()


def clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    for me in list(bpy.data.meshes):
        if not me.users:
            bpy.data.meshes.remove(me)
    O.BMS.clear()
    EXPORT.clear()
    MODELS.clear()
    CURSOR[0] = 0.0


def built(fn, *args):
    """The objects fn(*args) makes (built at the origin, finished)."""
    before = set(bpy.data.objects.keys())
    with O.at(0.0, 0, 0):
        fn(*args)
    O.finish()
    return [bpy.data.objects[n] for n in sorted(set(bpy.data.objects.keys()) - before)]


def export_trees():
    import trees as T
    T.build()
    groups = {}
    for ob in list(bpy.data.objects):
        if ob.type == "MESH" and "_" in ob.name and not ob.name.startswith(("OLD", "Preview", "Ground")):
            groups.setdefault(ob.name.split("_")[0], []).append(ob)
    for ob in list(bpy.data.objects):  # (the ground, sun, player and old tree go)
        if not any(ob in g for g in groups.values()):
            bpy.data.objects.remove(ob)
    for tree, obs in sorted(groups.items()):  # (each tree back to the origin first: the line-up spaces them)
        lo, hi = bounds(obs, world=True)
        mid = Matrix.Translation((-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, 0.0))
        for ob in obs:
            ob.matrix_world = mid @ ob.matrix_world
        add_model("Tree_" + tree, obs)
    write_group("trees")


def export_shack():
    path = os.path.join(HERE, "firm_shack.py")
    src = open(path).read()
    g = {"__name__": "shack", "__file__": path}
    exec(compile(src[:src.index("\nsc = build()")], path, "exec"), g)  # (its own builders; its renders are left out)
    g["build"]()
    add_model("DingyShack", [ob for ob in bpy.data.objects if ob.type == "MESH"])
    for ob in list(bpy.data.objects):
        if ob not in EXPORT:
            bpy.data.objects.remove(ob)
    write_group("shack")


def export_portal():
    import portal as PT
    add_model("TravelPortal", built(PT.make_objects))
    write_group("portal")


def export_models():
    import check_models as CM
    O.reset()
    order = ["trees", "shack", "portal"]
    lists = {}
    for group, name, fn, args in CM.models():
        if group not in lists:
            order.append(group)
        lists.setdefault(group, []).append((name, fn, args))
    for group in order:
        if WANT and group not in WANT:
            continue
        clear()
        if group == "trees":
            export_trees()
        elif group == "shack":
            export_shack()
        elif group == "portal":
            export_portal()
        else:
            for name, fn, args in lists[group]:
                try:
                    objs = built(fn, *args)
                except Exception as e:
                    print(f"[export] {group}.{name} FAILED to build: {e!r}")
                    continue
                add_model(f"{group}_{name}", objs)
                for ob in list(bpy.data.objects):  # (anything else it left: cameras, lights)
                    if ob not in EXPORT:
                        bpy.data.objects.remove(ob)
            write_group(group)


def export_island(key):
    """A whole island scene: the v2 frame's collections (Terrain, Scenery, Landmarks ...) and the overhaul's models
    (grouped by name: PizzaPalace_..., ...), each an empty at the island's origin (positions kept). Scattered scenery
    (HubOak17, IslBush428, OceanShell3 ...) is one model per kind, joined per look. The hub's example firms are left
    out (the game builds each player's firm on its plot)."""
    import importlib
    noop = lambda *a, **k: []
    O.render = IK.render_cams = IK.render_captured = IK.before_after = noop
    mod = importlib.import_module(ISLANDS[key])
    if key == "hub":
        mod.firm = lambda stage: (lambda *a, **k: None)
    mod.main()
    groups, merged = {}, set()
    for ob in bpy.data.objects:
        if not wanted(ob):
            continue
        coll = next((c.name for c in ob.users_collection if c is not bpy.context.scene.collection), None)
        g = re.sub(r"^[A-Z]{2,4}V2_", "", coll) if coll else ob.name.split("_")[0]
        kind = re.sub(r"\d+$", "", g)
        if kind != g and SCATTER.search(kind):
            g = kind
            merged.add(g)
        groups.setdefault(g, []).append(ob)
    for g, obs in sorted(groups.items()):
        add_model(g, obs, place=False, merge=g in merged)
    for ob in list(bpy.data.objects):
        if ob not in EXPORT:
            bpy.data.objects.remove(ob)
    write_group("island_" + key)


if __name__ == "__main__":
    if MODE == "island":
        for k in (WANT or ISLANDS):
            export_island(k)
    else:
        export_models()
