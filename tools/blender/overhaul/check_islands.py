# tools/blender/overhaul/check_islands.py - builds a re-dressed island (no renders) and lists where its overhaul models run
# INTO something (crnuch 2026-10-25: "a lot of buildings overlap each other"): every overhaul function an island script
# swapped in is wrapped so each placed instance gets its own mesh names; each landmark (6+ studs across or tall) is then
# tested against the v2 scenery (cliffs, crags, terraces, pools' rims ...), the other placed models and the trees.
# Contact at its own base (standing on the floor) is not counted - only overlaps 0.4+ above the model's lowest point.
#   Blender -b --factory-startup --python tools/blender/overhaul/check_islands.py -- <island> [<out dir>]
# island: pet rot food space ocean bay hub. Report: $TMPDIR/overlaps_<island>.txt (one line per landmark + what it hits).
import bpy, os, sys, math, importlib, itertools
from collections import defaultdict
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ISL = argv[0] if argv else "food"
OUT = os.path.abspath(argv[1]) if len(argv) > 1 else os.path.join(os.environ.get("TMPDIR", "/tmp"), "check_islands")
os.makedirs(OUT, exist_ok=True)
MODS = {"pet": "island_pet_park", "rot": "island_brainrot", "food": "island_food_court", "space": "island_space_base",
        "ocean": "island_ocean_shore", "bay": "island_briefcase_bay", "hub": "island_hub"}
sys.argv = [sys.argv[0], "--", OUT]  # (the island scripts read their out dir from argv)
M = importlib.import_module(MODS[ISL])
import island_kit as IK
import ohkit as O

SKIP = ("Preview", "Label", "Diagram", "Sky_", "Egg", "Studs", "Gameplay", "Water", "Foam", "Cloud", "Marker", "Boss")


def by_design(label, other, height):
    """Contacts that are meant: the boardwalk's ropes tied to its lamp posts, a portal's rocks set into the ground, the
    observatory's dome on the observatory, a tree in its planter."""
    lab = label.lower()
    return (("lamp" in lab or "torch" in lab) and other == "scenery Landmarks" or
            "portal" in lab and other.startswith(("scenery Floor_", "scenery Island_Top", "scenery Sand_Plateau")) and height <= 2.0 or
            "observatory" in lab and "observatory_dome" in other or
            "planter" in lab and other.startswith(("tree", "scenery Hub")) and "Trunk" in other or
            "lighthouse" in lab and other == "scenery Lighthouse_Beam" or  # (its own light beam)
            "portal" in lab and other.startswith("tree IslPalm") and height <= 2.0)  # (the palms planted at its feet)
CNT = itertools.count(1)


def wrap_all():
    """Wrap every overhaul function the island's patch() put on the v2 modules: each call builds under its own prefix."""
    n = 0
    for mod in list(sys.modules.values()):
        f = getattr(mod, "__file__", None) or ""
        if "environment-redesign" not in f:
            continue
        for nm, fn in list(vars(mod).items()):
            code = getattr(fn, "__code__", None)
            if not code or HERE not in code.co_filename or getattr(fn, "_wrapped", False):
                continue

            def w(*a, _fn=fn, _nm=nm, **k):
                with O.at(prefix="LM%05d_%s__" % (next(CNT), _nm[:16])):
                    return _fn(*a, **k)
            w._wrapped = True
            setattr(mod, nm, w)
            n += 1
    print("[islands] wrapped", n, "overhaul functions")


def build():
    if ISL == "bay":
        M.patch({nm: importlib.import_module(nm) for nm in ("bbv2_parts", "bbv2_detail")})
    else:
        M.patch()
    wrap_all()
    O.BMS.clear()
    if ISL == "hub":
        return M.run_hub()
    over = {"pet": ("pond_rim", "park_lamp", "floor_bit", "pond_garden"), "rot": ("floor_bit", "mushroom", "crystal", "goo_garden"),
            "food": ("floor_bit", "soda_garden"), "space": ("floor_bit",)}.get(ISL, ())
    clear = IK.CLEAR_OVERRIDES if ISL in ("pet", "rot", "food", "space") else {}  # (as the island scripts build them)
    return IK.run_island(M.SCRIPT, OUT, overrides={**clear, **{k: getattr(M, k) for k in over}})


def groups():
    """landmark groups (prefix -> objects), trees (one each), the scenery (everything else that is solid)."""
    G, scenery = defaultdict(list), []
    for ob in bpy.data.objects:
        if ob.type != "MESH" or not ob.data.polygons or any(s in ob.name for s in SKIP):
            continue
        if ob.name.startswith("LM") and "__" in ob.name:
            G[ob.name.split("__", 1)[0]].append(ob)
        elif ob.name.startswith(("IslOak", "IslPalm", "IslPine", "IslBlossom")):
            G["TREE_" + "".join(ch for ch in ob.name if ch.isdigit())].append(ob)
        else:
            scenery.append(ob)
    return G, scenery


def bbox(obs):
    pts = [ob.matrix_world @ Vector(c) for ob in obs for c in ob.bound_box]
    return (Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts))),
            Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts))))


def main():
    g = build()
    O.finish()
    print("[islands] kept clear of the landmarks:", IK.CLEARED)
    dg = bpy.context.evaluated_depsgraph_get()
    G, scenery = groups()
    box = {k: bbox(v) for k, v in G.items()}
    for ob in scenery:
        box["S:" + ob.name] = bbox([ob])
    trees = {}

    def tree_of(ob):
        if ob.name not in trees:
            me = ob.data
            vs = [ob.matrix_world @ v.co for v in me.vertices]
            trees[ob.name] = (BVHTree.FromPolygons(vs, [p.vertices[:] for p in me.polygons]), vs, me)
        return trees[ob.name]

    big = [k for k, (lo, hi) in box.items() if not k.startswith("S:") and not k.startswith("TREE_") and
           (max(hi.x - lo.x, hi.y - lo.y) >= 6.0 or hi.z - lo.z >= 6.0)]  # (buildings + landmarks; small planting only as what they hit)
    others = [(k, G[k] if not k.startswith("S:") else [bpy.data.objects[k[2:]]]) for k in box]
    lines = []
    for k in sorted(big):
        lo, hi = box[k]
        base = lo.z + 0.4
        hits = defaultdict(lambda: [0, -1e9, None])
        for k2, obs2 in others:
            if k2 == k:
                continue
            lo2, hi2 = box[k2]
            if lo2.x > hi.x or hi2.x < lo.x or lo2.y > hi.y or hi2.y < lo.y or lo2.z > hi.z or hi2.z < base:
                continue
            for a in G[k]:
                ta, va, ma = tree_of(a)
                for b in obs2:
                    tb, vb, mb = tree_of(b)
                    for ia, ib in ta.overlap(tb):
                        pa = [va[i] for i in ma.polygons[ia].vertices]
                        pb = [vb[i] for i in mb.polygons[ib].vertices]
                        zz = min(max(p.z for p in pa), max(p.z for p in pb))
                        if zz < base:
                            continue
                        h = hits[(k2, b.name if k2.startswith("S:") else b.name.split("__", 1)[-1])]
                        h[0] += 1
                        if zz > h[1]:
                            h[1], h[2] = zz, sum(pa, Vector()) / len(pa)
        label = G[k][0].name.split("__", 1)[0].split("_", 1)[1]
        what = {key: ("scenery " + key[1]) if key[0].startswith("S:") else ("tree " + key[1] if key[0].startswith("TREE_") else
                                                                            "model " + G[key[0]][0].name.split("__", 1)[0].split("_", 1)[1] + " / " + key[1])
                for key in hits}
        hits = {key: h for key, h in hits.items() if not by_design(label, what[key], h[1] - lo.z)}
        if not hits:
            continue
        c = (lo + hi) / 2
        lines.append(f"{ISL} {label} @({c.x:.0f},{c.y:.0f}) size {hi.x - lo.x:.0f}x{hi.y - lo.y:.0f}x{hi.z - lo.z:.0f}:")
        for key, (cnt, zz, p) in sorted(hits.items(), key=lambda kv: -kv[1][0])[:8]:
            lines.append(f"    {what[key]}: {cnt} tri pairs, up to {zz - lo.z:.1f} above its base, e.g. ({p.x:.1f}, {p.y:.1f}, {p.z:.1f})")
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"), f"overlaps_{ISL}.txt")
    with open(path, "w") as fh:
        fh.write("\n".join(lines))
    print(f"[islands] {ISL}: {sum(1 for l in lines if not l.startswith(' '))} landmarks run into something; report: {path}")


main()
