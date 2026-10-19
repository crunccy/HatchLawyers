# environment-redesign/kit/hl_kit.py - the shared STUDDED-BRICK kit for every island (2026-10-18).
# Imported by each island's build script (sys.path.insert(0, <this folder>); import hl_kit as K).
# Style rule: docs/ART_STYLE_STUDS.md - real raised studs (Roblox's own rounded-square shape, 1-stud pitch), chunky
# bricks with small chamfers, plastic look. Everything here is plain modular geometry so it can become Roblox Parts /
# MeshParts later (notes in ROBLOX_MATERIAL and environment-redesign/README.md).
#
#   K.reset()                         fresh scene + collections
#   b = K.Mesh("Name", collection)    many bricks into ONE object (material slots); b.done() makes it
#   b.brick(cx, cy, z0, sx, sy, h, "grass", rot=0, studs=True, bevel=0.08)
#   b.cyl / b.prism / b.wedge / b.pyramid / b.ring / b.cone
#   K.studs_done()                    THE STUD PASS: raised studs on every exposed top of every object (call last)
#   Everything is VOXEL (crnuch's call 2026-10-19): cyl / ring / cone / sphere / prism / wedge / pyramid / ring_v /
#   disc_v all build stepped bricks on the 1-stud grid; nothing smooth, nothing round.
#   props: K.tree_round / tree_pine / tree_palm / tree_blossom / bush / flowerbed / rocks / lamp / bench / planter /
#          signpost / flag / railing / stairs / column / window / door / label3d
# Units: 1 Blender m = 1 stud. +Z up, +Y = north. Roblox (x, y, z) = (bx, bz, -by).
import bpy, bmesh, math, random
from mathutils import Vector

TAU = math.tau
rng = random.Random(7)


def rad(d):
    return math.radians(d)


# ------------------------------------------------------------------ palette (sRGB 0-255) + Roblox material per look
PAL = {
    # world (CLAUDE.md palette)
    "grass": (124, 222, 52), "grass_dark": (96, 196, 40), "leaf": (70, 168, 34), "leaf_light": (110, 200, 60),
    "leaf_deep": (46, 128, 30), "path": (255, 160, 24), "path_edge": (250, 246, 236), "wood": (214, 140, 70),
    "wood_dark": (122, 70, 34), "floor": (222, 160, 96), "cream": (246, 226, 180), "sign_green": (98, 205, 48),
    # stone + build
    "stone": (214, 208, 196), "stone_warm": (236, 214, 170), "stone_dark": (150, 144, 136), "cobble": (188, 182, 172),
    "road": (120, 124, 134), "curb": (240, 238, 232), "white": (246, 244, 238), "marble": (250, 248, 242),
    "brick_red": (196, 86, 62), "brick_dark": (124, 58, 40), "roof_red": (214, 66, 52), "roof_blue": (58, 110, 200),
    "roof_navy": (40, 54, 104), "roof_teal": (30, 150, 150), "dirt": (150, 96, 52), "dirt_dark": (110, 70, 40),
    "rock": (138, 132, 126), "rock_dark": (98, 92, 88), "rock_warm": (170, 140, 110), "sand": (240, 222, 170),
    # accents
    "gold": (255, 200, 40), "gold_dark": (214, 150, 20), "red": (226, 58, 58), "orange": (255, 140, 30),
    "yellow": (255, 220, 60), "blue": (60, 140, 240), "sky_blue": (120, 200, 255), "purple": (150, 90, 220),
    "purple_dark": (90, 50, 150), "pink": (255, 120, 180), "teal": (40, 190, 180), "ink": (40, 40, 52),
    "metal": (170, 176, 186), "metal_dark": (80, 86, 98), "black": (30, 30, 36), "bronze": (168, 112, 58), "eggshell": (252, 238, 200), "hazard": (250, 200, 30),
    "magenta": (230, 50, 200), "violet": (110, 55, 190), "lilac": (190, 150, 255), "night": (40, 30, 70), "teal_dark": (20, 120, 130),
    "blossom": (255, 170, 200), "blossom_light": (255, 205, 225), "awning_red": (230, 50, 50), "awning_white": (252, 250, 246),
}
GLOWS = {"glow_warm": ((255, 226, 150), 3.0), "glow_cyan": ((90, 210, 255), 2.6), "glow_purple": ((170, 90, 255), 2.2),
         "glow_gold": ((255, 210, 90), 3.0), "glow_green": ((120, 255, 140), 3.0), "glow_red": ((255, 90, 90), 3.0),
         "glow_white": ((255, 255, 255), 2.5), "glow_bulb": ((255, 230, 160), 3.2), "glow_magenta": ((255, 60, 220), 2.6),
         "glow_lime": ((170, 255, 60), 2.4)}
GLASS = {"glass": (150, 210, 245), "glass_dark": (60, 110, 170), "water": (60, 170, 240), "water_fall": (70, 175, 245), "goo": (190, 70, 255), "goo_fall": (210, 90, 255), "water_deep": (30, 120, 210),
         "portal_field": (40, 140, 255), "portal_home": (70, 230, 140)}
# Roblox equivalent per look family (for integration; Blender-only shading is listed in the README)
ROBLOX_MATERIAL = {"glow_": "Neon", "glass": "Glass (Transparency 0.4)", "water": "Glass / Terrain Water",
                   "metal": "Metal", "gold": "Plastic (gold colour) or Foil", "portal_field": "Neon + Transparency 0.5",
                   "*": "Plastic, TopSurface = Studs far away + raised stud tiles near (docs/ART_STYLE_STUDS.md)"}

MATS = {}


def lin(c):
    return tuple((v / 255) ** 2.2 for v in c)


def mat(name):
    """The material for a look name (created on first use)."""
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    if name in GLOWS:
        rgb, strength = GLOWS[name]
        bsdf.inputs["Base Color"].default_value = (*lin(rgb), 1)
        bsdf.inputs["Emission Color"].default_value = (*lin(rgb), 1)
        bsdf.inputs["Emission Strength"].default_value = strength
        m.diffuse_color = (*lin(rgb), 1)
    elif name in GLASS:
        rgb = GLASS[name]
        bsdf.inputs["Base Color"].default_value = (*lin(rgb), 1)
        bsdf.inputs["Roughness"].default_value = 0.08
        a = 0.55 if name.startswith("glass") else (0.6 if name.startswith("portal_") else (0.97 if name.startswith("choco") else
                                                                                           (0.16 if name.startswith("beam") else 0.82)))
        bsdf.inputs["Alpha"].default_value = a
        if name.startswith("portal_") or name.startswith("goo") or name.startswith("beam"):  # (beam*: a see-through light beam)
            bsdf.inputs["Emission Color"].default_value = (*lin(rgb), 1)
            bsdf.inputs["Emission Strength"].default_value = 0.6 if name.startswith("beam") else 1.1
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
        m.diffuse_color = (*lin(rgb), a)
    else:
        rgb = PAL[name]
        bsdf.inputs["Base Color"].default_value = (*lin(rgb), 1)
        metal = name.startswith("metal") or name.startswith("gold") or name == "bronze"
        bsdf.inputs["Roughness"].default_value = 0.32 if metal else 0.42  # toy plastic: a soft sheen
        bsdf.inputs["Metallic"].default_value = 0.55 if metal else 0.0
        try:
            bsdf.inputs["Specular IOR Level"].default_value = 0.45
        except Exception:
            pass
        m.diffuse_color = (*lin(rgb), 1)
    MATS[name] = m
    return m


# ------------------------------------------------------------------ scene
COLS = {}


def reset(top_collections):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear()
    COLS.clear()
    STUDS.clear()
    FONTS.clear()
    scene = bpy.context.scene
    for n in top_collections:
        col(n)
    col("Kit_Sources").hide_render = True
    return scene


def col(name, parent=None):
    if name in COLS:
        return COLS[name]
    c = bpy.data.collections.new(name)
    (COLS[parent] if parent else bpy.context.scene.collection).children.link(c)
    COLS[name] = c
    return c


# ------------------------------------------------------------------ the stud (Roblox's shape; from tools/blender/stud_tiles.py)
STUD_TOP_HALF, STUD_TOP_R, STUD_SLANT, STUD_H, STUD_SINK = 0.23, 0.09, 0.07, 0.10, 0.05


def _outline(half, r, segs):
    c = half - r
    pts = []
    for k, (sx, sy) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        for i in range(segs + 1):
            a = (k + i / segs) * math.pi / 2
            pts.append((sx * c + r * math.cos(a), sy * c + r * math.sin(a), math.cos(a), math.sin(a)))
    return pts


def stud_mesh(segs=3):
    me = bpy.data.meshes.new("Stud")
    top = _outline(STUD_TOP_HALF, STUD_TOP_R, segs)
    foot = _outline(STUD_TOP_HALF + STUD_SLANT, STUD_TOP_R + STUD_SLANT, segs)
    k = len(top)
    verts = [(x, y, -STUD_SINK) for x, y, _, _ in foot] + [(x, y, STUD_H) for x, y, _, _ in top] + [(0, 0, STUD_H)]
    faces = []
    for i in range(k):
        j = (i + 1) % k
        faces.append((i, j, k + j, k + i))
        faces.append((k + i, k + j, 2 * k))
    me.from_pydata(verts, [], faces)
    me.validate()
    return me


STUDS = {}  # (kept for old callers; unused - the stud pass below finds every exposed top itself)
STUD_GROUP = None  # (kept for old callers: every object now carries its own studs)
STUD_MIN_FACE = 0.55  # a top face narrower than this can't hold a 1-stud stud (foot 0.60)


def add_studs(look, pts, owner=None):
    """No-op since 2026-10-19: studs_done() studs every exposed top face of every object by itself."""
    return None


def _stud_sources():
    src_mesh, made = stud_mesh(), {}

    def get(look_mat):
        if look_mat.name in made:
            return made[look_mat.name]
        src = bpy.data.objects.new("StudSource_" + look_mat.name, src_mesh.copy())
        src.data.materials.append(look_mat)
        COLS["Kit_Sources"].objects.link(src)
        ng = bpy.data.node_groups.new("StudInstancer_" + look_mat.name, "GeometryNodeTree")
        ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
        ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
        N, L = ng.nodes, ng.links
        gi, go = N.new("NodeGroupInput"), N.new("NodeGroupOutput")
        topts, inst, info = N.new("GeometryNodeMeshToPoints"), N.new("GeometryNodeInstanceOnPoints"), N.new("GeometryNodeObjectInfo")
        info.inputs["Object"].default_value = src
        na = N.new("GeometryNodeInputNamedAttribute")
        na.data_type = "FLOAT"
        na.inputs["Name"].default_value = "rz"
        cx = N.new("ShaderNodeCombineXYZ")
        L.new(gi.outputs[0], topts.inputs["Mesh"])
        L.new(topts.outputs["Points"], inst.inputs["Points"])
        L.new(info.outputs["Geometry"], inst.inputs["Instance"])
        L.new(na.outputs["Attribute"], cx.inputs["Z"])
        L.new(cx.outputs["Vector"], inst.inputs["Rotation"])
        L.new(inst.outputs["Instances"], go.inputs[0])
        made[look_mat.name] = ng
        return ng
    return get


def studs_done(target_collection=None, name="Studs", only=None):
    """THE STUD PASS (crnuch's call 2026-10-19: studded voxel on EVERYTHING): raised studs on every exposed top face of
    every mesh object in the scene - terrain, paths, buildings, props, eggs, liquids, clouds, bosses, statues.
    A grid point is studded unless something sits on it or hangs just above it (rays against all the geometry, at
    the stud's centre and four corners); overlapping coplanar tops are deduped. Each object gets its OWN instancers,
    parented to it (Studs_<object>_<look>), so studs ride whatever moves: wind, drift, turning signs, boss idles.
    only(obj, look_name) -> bool limits which tops get studs (the classic-Roblox style: broad terrain + structural
    surfaces only; water, glow and natural details stay smooth - crnuch's Ocean Shore v2 brief). Big organic faces
    (more than 4 corners, e.g. a sand plateau) are studded on the WORLD grid, so the studs line up island-wide."""
    from mathutils.bvhtree import BVHTree
    skip = {"Kit_Sources", "Presentation"}
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith(("Studs_", "StudSource_"))
            and not any(c.name in skip or "Labels" in c.name or c.name == "Lighting" for c in o.users_collection)]
    occluders = list(objs)
    objs = [o for o in objs if not o.name.startswith("Sky_")]  # (far Blender-only backdrops, 1000+ studs out: sub-pixel studs)
    verts, polys, data = [], [], []
    for o in occluders:
        mw = o.matrix_world
        base = len(verts)
        co = [mw @ v.co for v in o.data.vertices]
        verts.extend(co)
        polys.extend([[base + i for i in p.vertices] for p in o.data.polygons])
        if o in objs:
            data.append((o, co))
    bvh = BVHTree.FromPolygons(verts, polys)
    UP = Vector((0, 0, 1))

    def free(x, y, z):
        hit = bvh.ray_cast(Vector((x, y, z + 0.02)), UP, 120.0)
        if hit[0] is None:
            return True
        if hit[1].z > 0.0:  # we are INSIDE something (we hit its top from within)
            return False
        return hit[3] > 0.16  # something hangs right above

    seen = {}

    def dupe(x, y, z):
        key = (round(x), round(y), round(z * 4))
        for kx in (key[0] - 1, key[0], key[0] + 1):
            for ky in (key[1] - 1, key[1], key[1] + 1):
                for (px, py) in seen.get((kx, ky, key[2]), ()):
                    if (px - x) ** 2 + (py - y) ** 2 < 0.25:
                        return True
        seen.setdefault(key, []).append((x, y))
        return False

    source = _stud_sources()
    total = n_obj = 0
    for o, co in data:
        me = o.data
        r3 = o.matrix_world.to_3x3()
        per = {}
        for p in me.polygons:
            n = (r3 @ p.normal)
            if n.length == 0 or n.z / n.length < 0.995:
                continue
            look = me.materials[p.material_index] if me.materials else None
            if look is None or (only and not only(o, look.name)):
                continue
            vs = [co[i] for i in p.vertices]
            z = sum(v.z for v in vs) / len(vs)
            if len(vs) > 4:  # a big organic face: the world grid, inside its outline
                xs_, ys_ = [v.x for v in vs], [v.y for v in vs]
                poly = [(v.x, v.y) for v in vs]
                gx = math.floor(min(xs_)) + 0.5
                while gx < max(xs_):
                    gy = math.floor(min(ys_)) + 0.5
                    while gy < max(ys_):
                        if _inside(poly, gx, gy) and free(gx, gy, z) and \
                                all(free(gx + a * 0.27, gy + b * 0.27, z) for a in (-1, 1) for b in (-1, 1)) and not dupe(gx, gy, z):
                            per.setdefault(look.name, (look, []))[1].append((gx, gy, z, 0.0))
                        gy += 1.0
                    gx += 1.0
                continue
            best, ex = 0.0, None
            for k in range(len(vs)):
                e = vs[(k + 1) % len(vs)] - vs[k]
                L2 = e.x * e.x + e.y * e.y
                if L2 > best:
                    best, ex = L2, (e.x, e.y)
            if not ex:
                continue
            L = math.sqrt(best)
            ux, uy = ex[0] / L, ex[1] / L
            vx, vy = -uy, ux
            uv = [((v.x - vs[0].x) * ux + (v.y - vs[0].y) * uy, (v.x - vs[0].x) * vx + (v.y - vs[0].y) * vy) for v in vs]
            us, vv = [q[0] for q in uv], [q[1] for q in uv]
            w, d = max(us) - min(us), max(vv) - min(vv)
            if w < STUD_MIN_FACE or d < STUD_MIN_FACE:
                continue
            nu, nv = max(1, int(w + 0.35)), max(1, int(d + 0.35))
            uc, vc = (max(us) + min(us)) / 2, (max(vv) + min(vv)) / 2
            rect = len(vs) == 4 and abs(w * d - abs(sum(uv[k][0] * uv[(k + 1) % 4][1] - uv[(k + 1) % 4][0] * uv[k][1] for k in range(4)) / 2)) < 0.02 * w * d + 1e-6
            rz = math.atan2(uy, ux)
            for i in range(nu):
                for j in range(nv):
                    pu, pv = uc + (i - (nu - 1) / 2), vc + (j - (nv - 1) / 2)
                    if not rect and not _inside(uv, pu, pv):
                        continue
                    x, y = vs[0].x + pu * ux + pv * vx, vs[0].y + pu * uy + pv * vy
                    if not free(x, y, z):
                        continue
                    if not all(free(x + a * ux * 0.27 + b * vx * 0.27, y + a * uy * 0.27 + b * vy * 0.27, z) for a in (-1, 1) for b in (-1, 1)):
                        continue
                    if dupe(x, y, z):
                        continue
                    per.setdefault(look.name, (look, []))[1].append((x, y, z, rz))
        inv = o.matrix_world.inverted()
        for lname, (look, pts) in per.items():
            oname = f"{name}_{o.name}_{lname}"
            sm = bpy.data.meshes.new(oname)
            sm.from_pydata([tuple(inv @ Vector(q[:3])) for q in pts], [], [])
            attr = sm.attributes.new("rz", "FLOAT", "POINT")
            attr.data.foreach_set("value", [q[3] for q in pts])
            so = bpy.data.objects.new(oname, sm)
            for c in o.users_collection:
                c.objects.link(so)
            so.parent = o
            so.visible_shadow = False  # (as in Roblox: the raised-stud tiles are CastShadow = false; also keeps renders fast)
            so.modifiers.new("Studs", "NODES").node_group = source(look)
            total += len(pts)
            n_obj += 1
    print(f"[kit] studs: {total} raised studs on every exposed top ({n_obj} instancers on {len(objs)} objects)")
    return total


def _inside(poly, x, y):
    c = False
    n = len(poly)
    for i in range(n):
        (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            c = not c
    return c


# ------------------------------------------------------------------ the mesh builder
class Mesh:
    """Many parts into ONE object with material slots (fast, light, easy to export per object)."""

    def __init__(self, name, collection):
        self.name, self.col = name, collection
        self.bm = bmesh.new()
        self.looks = []

    def _mi(self, look):
        if look not in self.looks:
            self.looks.append(look)
        return self.looks.index(look)

    def _face(self, vs, mi):
        try:
            f = self.bm.faces.new(vs)
            f.material_index = mi
            return f
        except ValueError:
            return None

    # -- chamfered box (the brick) - built directly: 6 faces + 12 edge chamfers + 8 corner triangles
    def brick(self, cx, cy, z0, sx, sy, h, look, rot=0.0, studs=True, bevel=0.08, stud_look=None):
        b = min(bevel, sx / 4, sy / 4, h / 4)
        hx, hy, hz = sx / 2, sy / 2, h / 2
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        zc = z0 + hz

        def P(x, y, z):
            return self.bm.verts.new((cx + x * c - y * s, cy + x * s + y * c, zc + z))

        mi = self._mi(look)
        if b <= 0.001:
            v = {}
            for i, (x, y, z) in enumerate([(sx_, sy_, sz_) for sx_ in (-1, 1) for sy_ in (-1, 1) for sz_ in (-1, 1)]):
                v[(x, y, z)] = P(x * hx, y * hy, z * hz)
            quads = [((1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)), ((-1, 1, -1), (-1, -1, -1), (-1, -1, 1), (-1, 1, 1)),
                     ((1, 1, -1), (-1, 1, -1), (-1, 1, 1), (1, 1, 1)), ((-1, -1, -1), (1, -1, -1), (1, -1, 1), (-1, -1, 1)),
                     ((-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)), ((-1, 1, -1), (1, 1, -1), (1, -1, -1), (-1, -1, -1))]
            for q in quads:
                self._face([v[k] for k in q], mi)
        else:
            V = {}
            for sx_ in (-1, 1):
                for sy_ in (-1, 1):
                    for sz_ in (-1, 1):
                        V[("x", sx_, sy_, sz_)] = P(sx_ * hx, sy_ * (hy - b), sz_ * (hz - b))
                        V[("y", sx_, sy_, sz_)] = P(sx_ * (hx - b), sy_ * hy, sz_ * (hz - b))
                        V[("z", sx_, sy_, sz_)] = P(sx_ * (hx - b), sy_ * (hy - b), sz_ * hz)
            for sx_ in (-1, 1):  # x faces
                self._face([V[("x", sx_, -1, -1)], V[("x", sx_, 1, -1)], V[("x", sx_, 1, 1)], V[("x", sx_, -1, 1)]][:: sx_], mi)
            for sy_ in (-1, 1):
                self._face([V[("y", 1, sy_, -1)], V[("y", -1, sy_, -1)], V[("y", -1, sy_, 1)], V[("y", 1, sy_, 1)]][:: sy_], mi)
            for sz_ in (-1, 1):
                self._face([V[("z", -1, -1, sz_)], V[("z", 1, -1, sz_)], V[("z", 1, 1, sz_)], V[("z", -1, 1, sz_)]][:: sz_], mi)
            for sx_ in (-1, 1):  # chamfers along z (x/y faces)
                for sy_ in (-1, 1):
                    self._face([V[("x", sx_, sy_, -1)], V[("x", sx_, sy_, 1)], V[("y", sx_, sy_, 1)], V[("y", sx_, sy_, -1)]], mi)
            for sx_ in (-1, 1):  # chamfers along y (x/z faces)
                for sz_ in (-1, 1):
                    self._face([V[("x", sx_, -1, sz_)], V[("z", sx_, -1, sz_)], V[("z", sx_, 1, sz_)], V[("x", sx_, 1, sz_)]], mi)
            for sy_ in (-1, 1):  # chamfers along x (y/z faces)
                for sz_ in (-1, 1):
                    self._face([V[("y", -1, sy_, sz_)], V[("y", 1, sy_, sz_)], V[("z", 1, sy_, sz_)], V[("z", -1, sy_, sz_)]], mi)
            for sx_ in (-1, 1):
                for sy_ in (-1, 1):
                    for sz_ in (-1, 1):
                        self._face([V[("x", sx_, sy_, sz_)], V[("y", sx_, sy_, sz_)], V[("z", sx_, sy_, sz_)]], mi)
        # (studs: the stud pass in studs_done() puts them on every exposed top)

    # -- VOXEL primitives (crnuch's call 2026-10-19: "studded voxel on everything"): every round / sloped / polygonal
    #    shape is built from stepped bricks on a 1-stud grid (a finer 0.5 grid only for small upright pieces), turned
    #    with its frame; studs_done() studs every exposed top. Old arguments (segs, bevel, studs) are accepted + ignored.
    @staticmethod
    def _runs(row):
        """[(i, look)] -> [(i0, i1, look)] runs of neighbouring cells with the same look."""
        row = sorted(row)
        out, k = [], 0
        while k < len(row):
            i0, lk = row[k]
            i1 = i0
            while k + 1 < len(row) and row[k + 1][0] == i1 + 1 and row[k + 1][1] == lk:
                k += 1
                i1 = row[k][0]
            out.append((i0, i1, lk))
            k += 1
        return out

    def _flat(self, cx, cy, z0, z1, rot, cells, ox, oy, cell=1.0, bevel=0.06):
        """cells {j: [(i, look)]} at local ((i + ox) * cell, (j + oy) * cell) -> one brick per run."""
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        for j, row in cells.items():
            ly = (j + oy) * cell
            for i0, i1, lk in self._runs(row):
                lx = ((i0 + i1) / 2 + ox) * cell
                self.brick(cx + lx * c - ly * s, cy + lx * s + ly * c, z0, (i1 - i0 + 1) * cell, cell, z1 - z0, lk, rot, bevel=bevel)

    @staticmethod
    def _grid(rx, ry, cell, keep, look_at):
        nx, ny = max(1, round(2 * rx / cell)), max(1, round(2 * ry / cell))
        ox, oy = (0.0 if nx % 2 else 0.5), (0.0 if ny % 2 else 0.5)
        cells = {}
        for j in range(-(ny // 2) - 1, ny // 2 + 2):
            y = (j + oy) * cell
            for i in range(-(nx // 2) - 1, nx // 2 + 2):
                x = (i + ox) * cell
                if keep(x, y):
                    cells.setdefault(j, []).append((i, look_at(x, y)))
        return cells, ox, oy

    def prism(self, pts, z0, z1, look, studs=False, stud_rot=0.0, rot=0.0):
        """A vertical prism over a polygon [(x, y)], voxelized: 1-stud rows (scanline), stepped edges."""
        if z1 < z0:
            z0, z1 = z1, z0
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        loc = [(x * c + y * s, -x * s + y * c) for x, y in pts]
        n = len(loc)
        area = abs(sum(loc[k][0] * loc[(k + 1) % n][1] - loc[(k + 1) % n][0] * loc[k][1] for k in range(n))) / 2
        bevel = 0.0 if area > 300 else 0.05
        ys = [q[1] for q in loc]
        for j in range(math.floor(min(ys)), math.ceil(max(ys))):
            yc = j + 0.5
            xs = []
            for k in range(n):
                (x1, y1), (x2, y2) = loc[k], loc[(k + 1) % n]
                if (y1 > yc) != (y2 > yc):
                    xs.append(x1 + (yc - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                i0, i1 = math.ceil(a - 0.5), math.floor(b - 0.5)
                if i1 >= i0:
                    lx0, lx1 = i0, i1 + 1
                elif b - a > 0.3:
                    lx0, lx1 = a, b
                else:
                    continue
                lx = (lx0 + lx1) / 2
                self.brick(lx * c - yc * s, lx * s + yc * c, z0, lx1 - lx0, 1.0, z1 - z0, look, rot, bevel=bevel)

    def cyl(self, cx, cy, r, z0, z1, look, segs=24, bevel=0.0, studs=False, rot=0.0, cell=1.0):
        """A round column / disc, voxelized: a pixel circle on the 1-stud grid (a square post when thinner than ~1)."""
        if z1 < z0:
            z0, z1 = z1, z0
        if z1 - z0 < 1e-4:
            return
        if r < 0.55:
            self.brick(cx, cy, z0, max(2 * r, 0.3), max(2 * r, 0.3), z1 - z0, look, rot, bevel=0.04)
            return
        cells, ox, oy = self._grid(r, r, cell, lambda x, y: x * x + y * y <= r * r + 0.05 * cell, lambda x, y: look)
        self._flat(cx, cy, z0, z1, rot, cells, ox, oy, cell, bevel=0.06 if r < 6 else 0.0)  # (big rounds: plain steps, light)

    def ring(self, r0, r1, z0, z1, look, segs=96, a0=0.0, a1=360.0, cx=0.0, cy=0.0, studs=False, rot=0.0):
        """A flat ring / arc, voxelized: a pixel ring at least one cell wide."""
        if z1 < z0:
            z0, z1 = z1, z0
        rm, hw = (r0 + r1) / 2, max((r1 - r0) / 2, 0.5)
        span = (a1 - a0) % 360 if abs(a1 - a0) < 359.99 else 360.0

        def keep(x, y):
            if abs(math.hypot(x, y) - rm) > hw + 0.02:
                return False
            if span >= 360.0:
                return True
            wa = math.degrees(math.atan2(x * math.sin(rad(rot)) + y * math.cos(rad(rot)), x * math.cos(rad(rot)) - y * math.sin(rad(rot))))
            return (wa - a0) % 360 <= span + 1e-6

        cells, ox, oy = self._grid(r1 + 0.5, r1 + 0.5, 1.0, keep, lambda x, y: look)
        self._flat(cx, cy, z0, z1, rot, cells, ox, oy)

    def wedge(self, cx, cy, z0, sx, sy, h, look, rot=0.0, ridge="x"):
        """A gable shape, STEPPED: courses narrowing to a ridge along local x (or y)."""
        n = max(2, round(h / 0.8))
        ch = h / n
        for k in range(n):
            f = 1 - k / n
            if ridge == "x":
                self.brick(cx, cy, z0 + k * ch, sx, max(sy * f, 0.6), ch, look, rot, bevel=0.05)
            else:
                self.brick(cx, cy, z0 + k * ch, max(sx * f, 0.6), sy, ch, look, rot, bevel=0.05)

    def roof_gable(self, cx, cy, z0, sx, sy, h, look, rot=0.0, courses=None, trim=None, overhang=0.8):
        """A STEPPED gable (toy-brick roof): courses of studded bricks narrowing to the ridge along local x,
        each course with a lighter lip, plus gable-end trim."""
        n = courses or max(2, int(h / 1.0))
        c, s_ = math.cos(rad(rot)), math.sin(rad(rot))
        ch = h / n
        for k in range(n):
            w = (sy + 2 * overhang) * (1 - k / n)
            self.brick(cx, cy, z0 + k * ch, sx + 2 * overhang, max(w, 1.0), ch, look, rot, studs=True, bevel=0.06)
        self.brick(cx, cy, z0 + h, sx + 2 * overhang + 0.4, 1.0, 0.6, trim or look, rot, studs=False, bevel=0.1)  # ridge cap
        if trim:
            for sgn in (-1, 1):  # bargeboards along the eaves
                ox, oy = -s_ * sgn * (sy / 2 + overhang), c * sgn * (sy / 2 + overhang)
                self.brick(cx + ox, cy + oy, z0 - 0.3, sx + 2 * overhang + 0.4, 0.6, 0.6, trim, rot, studs=False)

    def roof_hip(self, cx, cy, z0, sx, sy, h, look, rot=0.0, courses=None, trim=None, overhang=0.8, cap=None):
        """A STEPPED hip roof: studded courses shrinking on every side, a cap brick on top."""
        n = courses or max(2, int(h / 1.0))
        ch = h / n
        for k in range(n):
            f = 1 - k / (n + 0.6)
            self.brick(cx, cy, z0 + k * ch, (sx + 2 * overhang) * f, (sy + 2 * overhang) * f, ch, look, rot, studs=True, bevel=0.06)
        if trim:
            self.brick(cx, cy, z0 - 0.35, sx + 2 * overhang + 0.6, sy + 2 * overhang + 0.6, 0.45, trim, rot, studs=False)
        if cap:
            self.brick(cx, cy, z0 + h, 1.6, 1.6, 0.8, cap, rot, studs=False, bevel=0.15)

    def pyramid(self, cx, cy, z0, sx, sy, h, look, rot=0.0, top=0.0):
        """A pyramid / hip shape, STEPPED; top > 0 leaves a flat top that wide."""
        n = max(2, round(h / 0.8))
        ch = h / n
        t = top / max(sx, sy) if top > 0 else 0.0
        for k in range(n):
            f = 1 - (1 - t) * k / n
            self.brick(cx, cy, z0 + k * ch, max(sx * f, 0.6), max(sy * f, 0.6), ch, look, rot, bevel=0.05)

    def cone(self, cx, cy, r, z0, z1, look, segs=8, r1=0.0, rot=0.0, cell=None):
        """A cone / frustum, voxelized: stacked pixel circles (z1 < z0 makes it point down)."""
        lo, hi = min(z0, z1), max(z0, z1)
        rb, rt = (r, r1) if z1 >= z0 else (r1, r)
        n = max(2, min(round((hi - lo) / 1.0), 10))  # (at most 10 steps: big cliff rocks stay light)
        dz = (hi - lo) / n
        cell = cell or (2.0 if max(r, r1) >= 5 else 1.0)  # (big cones, e.g. the rocks under the cliffs: 2-stud cells)
        for k in range(n):
            rr = rb + (rt - rb) * (k + 0.5) / n
            if rr >= 0.12:
                self.cyl(cx, cy, rr, lo + k * dz, lo + (k + 1) * dz, look, rot=rot, cell=cell if rr >= cell else 1.0)

    def sphere(self, cx, cy, cz, rx, ry, rz, look, seg=16, rings=10, rot=0.0):
        """A ball / ellipsoid, voxelized: stacked pixel ellipses (plates for small balls)."""
        step = min(1.0, max(0.35, rz / 3))
        n = max(1, round(2 * rz / step))
        dz = 2 * rz / n
        for k in range(n):
            zc = -rz + (k + 0.5) * dz
            f = math.sqrt(max(0.0, 1 - (zc / rz) ** 2))
            a, b = max(rx * f, 0.15), max(ry * f, 0.15)
            zb = cz - rz + k * dz
            if a < 0.55 and b < 0.55:
                self.brick(cx, cy, zb, 2 * a, 2 * b, dz, look, rot, bevel=0.04)
                continue
            cells, ox, oy = self._grid(a, b, 1.0, lambda x, y: (x / a) ** 2 + (y / b) ** 2 <= 1.04, lambda x, y: look)
            self._flat(cx, cy, zb, zb + dz, rot, cells, ox, oy)

    def _upright(self, cx, cy, cz, depth, rot, R, cell, keep, look_at):
        """Pixel art in the local x-z plane (depth along local y): rows of bricks."""
        c, s_ = math.cos(rad(rot)), math.sin(rad(rot))
        n = max(1, round(2 * R / cell))
        o = 0.0 if n % 2 else 0.5
        N = n // 2 + 1
        for j in range(-N, N + 1):
            z = (j + o) * cell
            row = []
            for i in range(-N, N + 1):
                x = (i + o) * cell
                lk = keep(x, z) and look_at(x, z)
                if lk:
                    row.append((i, lk))
            for i0, i1, lk in self._runs(row):
                lx = ((i0 + i1) / 2 + o) * cell
                self.brick(cx + lx * c, cy + lx * s_, cz + z - cell / 2, (i1 - i0 + 1) * cell, depth, cell, lk, rot, bevel=0.04)

    def ring_v(self, cx, cy, cz, r0, r1, depth, looks, rot=0.0, segs=24, gap=0.12, a0=0.0, a1=360.0):
        """An UPRIGHT ring / arch (portal, wheel rim, handle) in the local x-z plane, voxelized: a pixel ring of bricks
        `depth` thick; looks is one look or a list cycled round it in `segs` segments."""
        looks = looks if isinstance(looks, (list, tuple)) else [looks]
        cell = 1.0 if r1 >= 3.0 else 0.5
        rm, hw = (r0 + r1) / 2, max((r1 - r0) / 2, cell / 2)
        full = abs(a1 - a0) >= 359.99
        span = (a1 - a0) / max(1, segs)

        def keep(x, z):
            if abs(math.hypot(x, z) - rm) > hw + 0.02:
                return False
            return full or (math.degrees(math.atan2(z, x)) - a0) % 360 <= (a1 - a0) + 1e-6

        def look_at(x, z):
            rel = (math.degrees(math.atan2(z, x)) - a0) % 360
            return looks[int(rel / span) % len(looks)] if span > 0 else looks[0]

        self._upright(cx, cy, cz, depth, rot, r1 + cell / 2, cell, keep, look_at)

    def disc_v(self, cx, cy, cz, r, depth, look, rot=0.0, segs=32, look_at=None):
        """An UPRIGHT disc (portal field, clock face, wheel) in the local x-z plane, voxelized. look_at(x, z) can colour
        each cell (e.g. a lollipop's swirl bands) - one disc, so neighbouring bands never overlap."""
        cell = 1.0 if r >= 3.0 else 0.5
        if r < cell * 0.55:
            self.brick(cx, cy, cz - r, 2 * r, depth, 2 * r, look, rot, bevel=0.04)
            return
        self._upright(cx, cy, cz, depth, rot, r, cell, lambda x, z: x * x + z * z <= r * r + 0.05 * cell, look_at or (lambda x, z: look))

    def done(self, smooth=False):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        self.bm.to_mesh(me)
        self.bm.free()
        for lk in self.looks:
            me.materials.append(mat(lk))
        if smooth:
            me.shade_smooth()
        ob = bpy.data.objects.new(self.name, me)
        self.col.objects.link(ob)
        return ob


def grid_in_polygon(pts, z, pitch=1.0, keep=None):
    """1-stud grid points (x, y, z, 0) inside a polygon (even-odd test); keep(x, y) can veto points."""
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    out = []
    n = len(pts)
    y = math.floor(min(ys)) + 0.5
    while y < max(ys):
        xi = []
        for i in range(n):
            (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % n]
            if (y1 <= y < y2) or (y2 <= y < y1):
                xi.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
        xi.sort()
        for a, b in zip(xi[0::2], xi[1::2]):
            x = math.floor(a) + 0.5
            while x < b:
                if x - 0.3 > a and x + 0.3 < b and (keep is None or keep(x, y)):
                    out.append((x, y, z, 0.0))
                x += pitch
        y += pitch
    return out


# ------------------------------------------------------------------ vegetation
def tree_round(m, x, y, s=1.0, look=None, rot=None):
    """Chunky broadleaf: a trunk with a root flare and a canopy of offset studded blocks."""
    rot = rng.uniform(0, 90) if rot is None else rot
    look = look or rng.choice(["leaf", "leaf", "leaf_light"])
    m.brick(x, y, 0, 2.6 * s, 2.6 * s, 1 * s, "wood_dark", rot, studs=False)
    m.brick(x, y, 0, 1.8 * s, 1.8 * s, 7.5 * s, "wood", rot, studs=False)
    m.brick(x + 0.8 * s, y, 5 * s, 2.6 * s, 0.9 * s, 0.9 * s, "wood", rot + 30, studs=False)  # branch
    m.brick(x, y, 6 * s, 9 * s, 9 * s, 4 * s, look, rot)
    m.brick(x, y, 6.6 * s, 11 * s, 6 * s, 2.8 * s, look, rot, studs=False)
    m.brick(x, y, 6.6 * s, 6 * s, 11 * s, 2.8 * s, look, rot, studs=False)
    m.brick(x + 0.6 * s, y - 0.4 * s, 10 * s, 6.5 * s, 6.5 * s, 3 * s, "leaf_light" if look == "leaf" else "leaf", rot + 12)
    m.brick(x - 0.3 * s, y + 0.3 * s, 13 * s, 3.6 * s, 3.6 * s, 1.8 * s, "leaf_light", rot + 30)


def tree_pine(m, x, y, s=1.0):
    rot = rng.uniform(0, 90)
    m.brick(x, y, 0, 1.6 * s, 1.6 * s, 4 * s, "wood_dark", rot, studs=False)
    for k, (w, z, h) in enumerate(((9, 3, 3.2), (7, 6, 3), (5, 8.8, 2.8), (3, 11.4, 2.4), (1.4, 13.6, 1.6))):
        m.brick(x, y, z * s, w * s, w * s, h * s, "leaf_deep" if k % 2 == 0 else "leaf", rot + k * 8)


def tree_palm(m, x, y, s=1.0, lean=None):
    lean = rng.uniform(0, 360) if lean is None else lean
    dx, dy = math.cos(rad(lean)), math.sin(rad(lean))
    for k in range(8):  # segmented, curving trunk
        off = 0.14 * k * k * s * 0.25
        m.brick(x + dx * off, y + dy * off, k * 1.6 * s, 1.5 * s, 1.5 * s, 1.5 * s, "wood" if k % 2 else "wood_dark", lean, studs=False)
    tx, ty, tz = x + dx * 0.14 * 49 * s * 0.25, y + dy * 0.14 * 49 * s * 0.25, 12.8 * s
    m.brick(tx, ty, tz, 2.4 * s, 2.4 * s, 1.4 * s, "leaf_deep", lean)
    for k in range(6):
        a = k * 60 + lean
        fx, fy = tx + math.cos(rad(a)) * 3.2 * s, ty + math.sin(rad(a)) * 3.2 * s
        m.brick(fx, fy, tz + 0.4 * s, 6 * s, 1.6 * s, 0.6 * s, "leaf", a, studs=False)
        fx2, fy2 = tx + math.cos(rad(a)) * 6.4 * s, ty + math.sin(rad(a)) * 6.4 * s
        m.brick(fx2, fy2, tz - 0.5 * s, 3 * s, 1.2 * s, 0.5 * s, "leaf_light", a, studs=False)


def tree_blossom(m, x, y, s=1.0):
    tree_round(m, x, y, s, look="blossom")


def bush(m, x, y, s=1.0, look="leaf"):
    rot = rng.uniform(0, 90)
    m.brick(x, y, 0, 4 * s, 4 * s, 2.4 * s, look, rot)
    m.brick(x + 0.4 * s, y - 0.3 * s, 2.2 * s, 2.4 * s, 2.4 * s, 1.2 * s, "leaf_light", rot + 20)


def hedge(m, x, y, length, rot, h=2.6, w=2.4):
    m.brick(x, y, 0, length, w, h, "leaf", rot)
    m.brick(x, y, 0, length + 0.4, w + 0.4, 0.6, "leaf_deep", rot, studs=False)


def flowerbed(m, x, y, sx, sy, rot=0.0, border="stone"):
    m.brick(x, y, 0, sx, sy, 1.0, border, rot, studs=False)
    m.brick(x, y, 0.3, sx - 1, sy - 1, 0.8, "dirt_dark", rot, studs=False)
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    looks = ["pink", "yellow", "red", "purple", "white", "orange"]
    for i in range(int(sx - 1)):
        for j in range(int(sy - 1)):
            if rng.random() < 0.7:
                lx, ly = i + 1 - sx / 2 + 0.0, j + 1 - sy / 2 + 0.0
                fx, fy = x + lx * c - ly * s, y + lx * s + ly * c
                m.brick(fx, fy, 1.1, 0.6, 0.6, 0.6 + rng.random() * 0.4, "leaf", rot, studs=False, bevel=0.05)
                m.brick(fx, fy, 1.8, 0.9, 0.9, 0.5, rng.choice(looks), rot, studs=False, bevel=0.1)


def rocks(m, x, y, s=1.0, look="rock"):
    for k in range(rng.randint(2, 4)):
        w = rng.uniform(1.6, 3.4) * s
        m.brick(x + rng.uniform(-2, 2) * s, y + rng.uniform(-2, 2) * s, 0, w, w * rng.uniform(0.7, 1.2), rng.uniform(1, 2.6) * s,
                look if k % 2 == 0 else "rock_dark", rng.uniform(0, 90), studs=w > 2)


# ------------------------------------------------------------------ street furniture + architecture pieces
def lamp(m, x, y, h=11.0, rot=0.0, double=False):
    m.brick(x, y, 0, 1.8, 1.8, 1.2, "metal_dark", rot, studs=False)
    m.cyl(x, y, 0.45, 1.2, h, "black", segs=8)
    m.brick(x, y, h, 1.4, 1.4, 0.4, "metal_dark", rot, studs=False)
    arms = (1, -1) if double else (0,)
    for sgn in arms:
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        ox, oy = (sgn * 1.8 * c, sgn * 1.8 * s) if double else (0, 0)
        if double:
            m.brick(x + ox / 2, y + oy / 2, h - 0.2, 3.6, 0.4, 0.4, "black", rot, studs=False)
        m.brick(x + ox, y + oy, h - 2.2, 1.6, 1.6, 2.0, "glow_warm", rot, studs=False, bevel=0.05)
        m.brick(x + ox, y + oy, h - 0.3, 2.0, 2.0, 0.5, "black", rot, studs=False)
        m.pyramid(x + ox, y + oy, h + 0.2, 2.0, 2.0, 0.9, "black", rot)


def bench(m, x, y, rot=0.0):
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    for sgn in (-1, 1):
        m.brick(x + sgn * 2.4 * c, y + sgn * 2.4 * s, 0, 0.5, 1.8, 1.4, "black", rot, studs=False)
    m.brick(x, y, 1.3, 6, 1.8, 0.4, "wood", rot, studs=False)
    bx, by = x - 0.8 * -s, y - 0.8 * c
    m.brick(bx, by, 1.7, 6, 0.3, 1.6, "wood", rot, studs=False)


def planter(m, x, y, sx=4, sy=4, rot=0.0, plant="bush"):
    m.brick(x, y, 0, sx, sy, 2.2, "stone", rot, studs=False)
    m.brick(x, y, 2.2, sx + 0.4, sy + 0.4, 0.4, "stone_warm", rot, studs=False)
    m.brick(x, y, 2.0, sx - 0.8, sy - 0.8, 0.7, "dirt_dark", rot, studs=False)
    if plant == "bush":
        m.brick(x, y, 2.6, sx - 1, sy - 1, 2.0, "leaf", rot)
        m.brick(x, y, 4.4, sx - 2.4, sy - 2.4, 1.2, "leaf_light", rot)
    elif plant == "flowers":
        m.brick(x, y, 2.6, sx - 1, sy - 1, 0.6, "leaf", rot, studs=False)
        for k in range(max(5, int(sx * sy * 0.8))):
            m.brick(x + rng.uniform(-sx / 2 + 1, sx / 2 - 1), y + rng.uniform(-sy / 2 + 1, sy / 2 - 1), 2.6, 0.9, 0.9, 0.7,
                    rng.choice(["pink", "yellow", "red", "purple"]), rot, studs=False)


def railing(m, x0, y0, x1, y1, z=0.0, h=2.6, look="white", post_every=3.0):
    L = math.hypot(x1 - x0, y1 - y0)
    rot = math.degrees(math.atan2(y1 - y0, x1 - x0))
    n = max(1, int(L / post_every))
    for k in range(n + 1):
        t = k / n
        m.brick(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, z, 0.5, 0.5, h, look, rot, studs=False)
    m.brick((x0 + x1) / 2, (y0 + y1) / 2, z + h, L + 0.5, 0.7, 0.35, look, rot, studs=False)
    m.brick((x0 + x1) / 2, (y0 + y1) / 2, z + h * 0.5, L, 0.3, 0.25, look, rot, studs=False)


def stairs(m, cx, cy, z0, width, steps, rise, run, rot, look="white", top_z=None):
    """Steps climbing toward local +x from (cx, cy) (the bottom step's front edge centre)."""
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    for k in range(steps):
        d = run * (k + 0.5)
        m.brick(cx + d * c, cy + d * s, z0, run, width, rise * (k + 1), look if k % 2 == 0 else look, rot, studs=True)


def column(m, x, y, z0, h, w=1.6, look="marble", cap="gold"):
    m.brick(x, y, z0, w + 1.0, w + 1.0, 0.8, look, studs=False)
    m.brick(x, y, z0 + 0.8, w + 0.5, w + 0.5, 0.5, look, studs=False)
    m.cyl(x, y, w / 2, z0 + 1.3, z0 + h - 1.3, look, segs=12)
    m.brick(x, y, z0 + h - 1.3, w + 0.5, w + 0.5, 0.5, cap, studs=False)
    m.brick(x, y, z0 + h - 0.8, w + 1.0, w + 1.0, 0.8, look, studs=False)


def window(m, cx, cy, z0, w, h, rot, frame="white", glass="glass", sill=True, mullions=1, shutters=None, depth=0.6):
    """A framed window on a wall face; (cx, cy) on the wall's outer face, local -y = outward."""
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    ox, oy = s * depth / 2, -c * depth / 2  # outward offset
    m.brick(cx, cy, z0, w, 0.3, h, glass, rot, studs=False, bevel=0.0)
    m.brick(cx + ox, cy + oy, z0 + h - 0.4, w + 0.8, depth, 0.6, frame, rot, studs=False)
    m.brick(cx + ox, cy + oy, z0 - 0.2, w + 0.8, depth, 0.5, frame, rot, studs=False)
    for sgn in (-1, 1):
        m.brick(cx + sgn * (w / 2 + 0.2) * c + ox, cy + sgn * (w / 2 + 0.2) * s + oy, z0, 0.5, depth, h, frame, rot, studs=False)
    for k in range(mullions):
        t = (k + 1) / (mullions + 1) - 0.5
        m.brick(cx + t * w * c + ox * 0.6, cy + t * w * s + oy * 0.6, z0, 0.25, 0.3, h, frame, rot, studs=False)
    m.brick(cx + ox * 0.6, cy + oy * 0.6, z0 + h / 2 - 0.12, w, 0.3, 0.25, frame, rot, studs=False)
    if sill:
        m.brick(cx + ox * 1.6, cy + oy * 1.6, z0 - 0.6, w + 1.2, depth * 1.4, 0.4, frame, rot, studs=False)
    if shutters:
        for sgn in (-1, 1):
            m.brick(cx + sgn * (w / 2 + 1.0) * c + ox, cy + sgn * (w / 2 + 1.0) * s + oy, z0, 1.1, 0.25, h, shutters, rot, studs=False)


def door(m, cx, cy, z0, w, h, rot, frame="white", leaf="wood_dark", arch=False, depth=0.8):
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    ox, oy = s * depth / 2, -c * depth / 2
    m.brick(cx, cy, z0, w, 0.4, h, leaf, rot, studs=False)
    for sgn in (-0.25, 0.25):
        m.brick(cx + sgn * w * c + ox * 0.3, cy + sgn * w * s + oy * 0.3, z0 + h * 0.15, w * 0.36, 0.3, h * 0.3, leaf if leaf != "wood_dark" else "wood", rot, studs=False)
        m.brick(cx + sgn * w * c + ox * 0.3, cy + sgn * w * s + oy * 0.3, z0 + h * 0.55, w * 0.36, 0.3, h * 0.3, leaf if leaf != "wood_dark" else "wood", rot, studs=False)
    m.brick(cx + ox, cy + oy, z0 + h, w + 1.6, depth, 0.8, frame, rot, studs=False)
    for sgn in (-1, 1):
        m.brick(cx + sgn * (w / 2 + 0.4) * c + ox, cy + sgn * (w / 2 + 0.4) * s + oy, z0, 0.8, depth, h, frame, rot, studs=False)
    if arch:
        m.wedge(cx + ox, cy + oy, z0 + h + 0.8, w + 1.6, depth, 1.6, frame, rot)
    m.brick(cx + ox * 2.2, cy + oy * 2.2, z0 + h * 0.45, 0.3, 0.3, 0.3, "gold", rot, studs=False, bevel=0.05)  # knob


def flag(m, x, y, z0, h, look, rot=0.0):
    m.cyl(x, y, 0.25, z0, z0 + h, "white", segs=8)
    m.brick(x, y, z0 + h, 0.7, 0.7, 0.7, "gold", rot, studs=False)
    c, s = math.cos(rad(rot)), math.sin(rad(rot))
    for k in range(4):  # a waving flag in 4 offset pieces
        m.brick(x + (1.1 + k * 1.1) * c, y + (1.1 + k * 1.1) * s + math.sin(k * 1.3) * 0.25, z0 + h - 3.4, 1.15, 0.2, 3,
                look, rot + math.sin(k) * 6, studs=False, bevel=0.03)


def banner(m, x, y, z0, h, w, look, rot=0.0, trim="gold"):
    """A hanging vertical banner (on a lamp post or a facade)."""
    m.brick(x, y, z0 + h, w + 0.6, 0.3, 0.3, trim, rot, studs=False)
    m.brick(x, y, z0 + 1.2, w, 0.2, h - 1.2, look, rot, studs=False)
    m.brick(x, y, z0 + 0.4, w * 0.5, 0.2, 0.8, look, rot, studs=False)  # the swallow-tail point
    m.brick(x, y, z0 + h * 0.55, w * 0.5, 0.25, w * 0.5, trim, rot, studs=False)


def label3d(text, x, y, z, size, look="white", rot=0.0, collection=None, extrude=0.15, font=None, face_rot=(90, 0)):
    """Real 3D text (signs). face_rot = (x tilt, extra z rot): 90 stands it up facing -y in its own frame."""
    cu = bpy.data.curves.new("Text_" + text[:20], "FONT")
    cu.body = text
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size = size
    cu.extrude = extrude
    if font:
        cu.font = font
    ob = bpy.data.objects.new(cu.name, cu)
    ob.location = (x, y, z)
    ob.rotation_euler = (rad(face_rot[0]), 0, rad(rot + face_rot[1]))
    cu.materials.append(mat(look))
    (collection or bpy.context.scene.collection).objects.link(ob)
    return ob


FONTS = {}


def font(kind="rounded"):
    if kind in FONTS:
        return FONTS[kind]
    import os
    paths = {"rounded": ["/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", "C:/Windows/Fonts/ARLRDBD.TTF"],
             "bold": ["/System/Library/Fonts/Supplemental/Arial Black.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                      "C:/Windows/Fonts/ariblk.ttf", "C:/Windows/Fonts/arialbd.ttf"]}[kind]  # (macOS, then mr.robe's Windows PC)
    for p in paths:
        if os.path.exists(p):
            FONTS[kind] = bpy.data.fonts.load(p)
            return FONTS[kind]
    return None


# ------------------------------------------------------------------ lighting + render helpers
def sky_and_sun(scene, sun_energy=3.6, sun_rot=(50, 8, -35), sky=(0.22, 0.48, 0.95), horizon=(0.58, 0.78, 1.0)):
    world = bpy.data.worlds.new("Sky")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")  # by the view direction's height: below/horizon -> pale, zenith -> blue
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (*horizon, 1)
    ramp.color_ramp.elements[1].position = 0.45
    ramp.color_ramp.elements[1].color = (*sky, 1)
    nt.links.new(coord.outputs["Generated"], sep.inputs["Vector"])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.85
    world.color = sky
    sd = bpy.data.lights.new("Sun", "SUN")
    sd.energy = sun_energy
    sd.angle = rad(4)
    sd.color = (1.0, 0.96, 0.9)
    sun = bpy.data.objects.new("Sun", sd)
    sun.rotation_euler = tuple(rad(a) for a in sun_rot)
    return world, sun


def camera(name, loc, look, lens=35, ortho=None, collection=None):
    cd = bpy.data.cameras.new(name)
    cd.clip_start, cd.clip_end = 0.5, 8000
    if ortho:
        cd.type = "ORTHO"
        cd.ortho_scale = ortho
    else:
        cd.lens = lens
    ob = bpy.data.objects.new(name, cd)
    ob.location = loc
    d = Vector(look) - Vector(loc)
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    (collection or bpy.context.scene.collection).objects.link(ob)
    return ob


def setup_eevee(scene, samples=48):
    for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            scene.render.engine = eng
            break
        except TypeError:
            continue
    ee = scene.eevee
    for attr, val in (("taa_render_samples", samples), ("use_raytracing", True), ("use_shadows", True),
                      ("shadow_ray_count", 2), ("shadow_step_count", 8), ("use_gtao", True), ("gtao_distance", 2.5)):
        try:
            setattr(ee, attr, val)
        except Exception:
            pass
    try:
        ee.ray_tracing_options.resolution_scale = "2"
    except Exception:
        pass
    vs = scene.view_settings
    vs.view_transform = "Standard"  # keeps the palette's saturated toy colours (AgX washed them out)
    try:
        vs.look = "Medium High Contrast"
    except Exception:
        pass
    vs.exposure = -0.15
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 92
    _bloom(scene)


def _bloom(scene):
    """A soft glare on emissive parts (controlled bloom) via the compositor, if this Blender exposes it."""
    try:
        if hasattr(scene, "compositing_node_group"):
            ng = bpy.data.node_groups.new("Bloom", "CompositorNodeTree")
            scene.compositing_node_group = ng
            rl = ng.nodes.new("CompositorNodeRLayers")
            gl = ng.nodes.new("CompositorNodeGlare")
            out = ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
            go = ng.nodes.new("NodeGroupOutput")
            for k, v in (("glare_type", "BLOOM"), ("quality", "HIGH")):
                try:
                    setattr(gl, k, v)
                except Exception:
                    pass
            for k, v in (("Threshold", 1.2), ("Strength", 0.35), ("Size", 0.5)):
                if k in gl.inputs:
                    gl.inputs[k].default_value = v
            ng.links.new(rl.outputs["Image"], gl.inputs["Image"])
            ng.links.new(gl.outputs["Image"], go.inputs[0])
        else:
            scene.use_nodes = True
            nt = scene.node_tree
            rl = nt.nodes.new("CompositorNodeRLayers")
            gl = nt.nodes.new("CompositorNodeGlare")
            gl.glare_type = "FOG_GLOW"
            gl.threshold = 1.2
            comp = next((n for n in nt.nodes if n.type == "COMPOSITE"), None) or nt.nodes.new("CompositorNodeComposite")
            nt.links.new(rl.outputs["Image"], gl.inputs["Image"])
            nt.links.new(gl.outputs["Image"], comp.inputs["Image"])
    except Exception as e:
        print("[kit] bloom skipped:", e)


def render(scene, cam, path, w, h, hide=()):
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = w, h, 100
    hidden = []
    for n in hide:
        c = COLS.get(n)
        if c and not c.hide_render:
            c.hide_render = True
            hidden.append(c)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for c in hidden:
        c.hide_render = False
    print("[kit] rendered", path)


# ------------------------------------------------------------------ local frames (author at the origin, front = -y)
class Frame:
    """Wraps a Mesh: every call takes LOCAL coords (front faces local -y) and lands in world space at (x, y) turned
    by rot degrees (rot = angle - 90 makes local -y face the centre for a building at polar angle `angle`)."""

    def __init__(self, m, x, y, rot=0.0, z=0.0):
        self.m, self.x, self.y, self.rot, self.z = m, x, y, rot, z
        self.c, self.s = math.cos(rad(rot)), math.sin(rad(rot))
        self.col = m.col

    def p(self, lx, ly):
        return (self.x + lx * self.c - ly * self.s, self.y + lx * self.s + ly * self.c)

    def brick(self, lx, ly, z0, sx, sy, h, look, rot=0.0, **kw):
        self.m.brick(*self.p(lx, ly), z0 + self.z, sx, sy, h, look, rot + self.rot, **kw)

    def cyl(self, lx, ly, r, z0, z1, look, **kw):
        self.m.cyl(*self.p(lx, ly), r, z0 + self.z, z1 + self.z, look, rot=kw.pop("rot", 0.0) + self.rot, **kw)

    def cone(self, lx, ly, r, z0, z1, look, **kw):
        self.m.cone(*self.p(lx, ly), r, z0 + self.z, z1 + self.z, look, rot=kw.pop("rot", 0.0) + self.rot, **kw)

    def sphere(self, lx, ly, cz, rx, ry, rz, look, **kw):
        self.m.sphere(*self.p(lx, ly), cz + self.z, rx, ry, rz, look, rot=kw.pop("rot", 0.0) + self.rot, **kw)

    def ring(self, r0, r1, z0, z1, look, cx=0.0, cy=0.0, a0=0.0, a1=360.0, **kw):
        wx, wy = self.p(cx, cy)
        self.m.ring(r0, r1, z0 + self.z, z1 + self.z, look, cx=wx, cy=wy, a0=a0 + self.rot, a1=a1 + self.rot, rot=self.rot, **kw)

    def prism(self, pts, z0, z1, look, **kw):
        self.m.prism([self.p(x, y) for x, y in pts], z0 + self.z, z1 + self.z, look, rot=self.rot, **kw)

    def wedge(self, lx, ly, z0, sx, sy, h, look, rot=0.0, **kw):
        self.m.wedge(*self.p(lx, ly), z0 + self.z, sx, sy, h, look, rot + self.rot, **kw)

    def pyramid(self, lx, ly, z0, sx, sy, h, look, rot=0.0, **kw):
        self.m.pyramid(*self.p(lx, ly), z0 + self.z, sx, sy, h, look, rot + self.rot, **kw)

    def roof_gable(self, lx, ly, z0, sx, sy, h, look, rot=0.0, **kw):
        self.m.roof_gable(*self.p(lx, ly), z0 + self.z, sx, sy, h, look, rot + self.rot, **kw)

    def roof_hip(self, lx, ly, z0, sx, sy, h, look, rot=0.0, **kw):
        self.m.roof_hip(*self.p(lx, ly), z0 + self.z, sx, sy, h, look, rot + self.rot, **kw)

    def ring_v(self, lx, ly, cz, r0, r1, depth, looks, rot=0.0, **kw):
        self.m.ring_v(*self.p(lx, ly), cz + self.z, r0, r1, depth, looks, rot + self.rot, **kw)

    def disc_v(self, lx, ly, cz, r, depth, look, rot=0.0, **kw):
        self.m.disc_v(*self.p(lx, ly), cz + self.z, r, depth, look, rot + self.rot, **kw)

    def text(self, body, lx, ly, z, size, look="white", rot=0.0, kind="rounded", extrude=0.15, collection=None):
        """Standing 3D text on a facade: its face points local -y (toward the viewer)."""
        wx, wy = self.p(lx, ly)
        return label3d(body, wx, wy, z + self.z, size, look, rot + self.rot, collection or self.col, extrude, font(kind))

    def sub(self, lx, ly, rot=0.0, z=0.0):
        """A child frame inside this one (for repeated pieces)."""
        wx, wy = self.p(lx, ly)
        f = Frame(self.m, wx, wy, self.rot + rot, self.z + z)
        return f


def voxel_round(F, lx, ly, z0, radius_at, h, look, step=1.0, studs=True, segs=28, looks=None):
    """A rounded voxel solid (dome / egg / basin): stacked cylinders, radius_at(t) for t in 0..1 up the height.
    Studs go only on each ring's EXPOSED top (the part the next ring up doesn't cover). looks(k) can vary colours."""
    n = max(2, int(h / step))
    rs = [radius_at((k + 0.5) / n) for k in range(n)] + [0.0]
    for k in range(n):
        r = rs[k]
        if r <= 0.3:
            continue
        lk = looks(k) if looks else look
        F.cyl(lx, ly, r, z0 + k * step, z0 + (k + 1) * step, lk, segs=segs, bevel=0.12)
        if studs:
            inner = rs[k + 1] + 0.35
            pts = []
            R = int(r) + 1
            for i in range(-R, R):
                for j in range(-R, R):
                    px, py = i + 0.5, j + 0.5
                    d = math.hypot(px, py)
                    if inner < d < r - 0.35:
                        wx, wy = F.p(lx + px, ly + py)
                        pts.append((wx, wy, z0 + (k + 1) * step + F.z, rad(F.rot)))
            add_studs(lk, pts, F.m.name)
