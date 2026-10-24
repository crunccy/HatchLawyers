# tools/blender/overhaul/firm_shack.py - MAP MODEL OVERHAUL, stage 1 benchmark: the starter firm front, the DINGY SHACK,
# as meshes (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"). Still a shack - just a loved, detailed one: plank
# walls in two wood tones with corner posts, rails and patched boards, framed windows (one shutter hanging crooked), a
# shingled gable roof with overhang, a blue tarp patch and a stovepipe, a porch with steps, a striped awning and a lantern,
# barrels and crates. Studs only on the porch deck and the floor (structural tops); wood, glass and cloth stay smooth.
# Fits Server.FirmStages' rules for stage 1 (firm-local: x across, y up, z into the plot, -z = street):
#   walls x +-12, z -3 .. 21; front door gap x -3..3 (7.5 high); side doorways x +-12, z -0.2..3.2; the back wall open at
#   x -3..3 (the aisle); the floor clear for |x| < 5, z -2 .. 8 (the walk-in route); a roof over the incubators
#   (+-7.8, 0, 14) - the hatch raycasts up for a ceiling; the name sign's spot (0, 9.2, -3.4) left empty.
# Blender: X = firm x, Y = firm z, Z = firm y (front faces -Y = the street). 1 m = 1 stud. One mesh per colour.
#   Blender -b --factory-startup --python tools/blender/overhaul/firm_shack.py -- <out_dir> [--fbx]
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "kit"))
import hl_kit as K

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
FBX = "--fbx" in argv
os.makedirs(OUT, exist_ok=True)
TAU = math.tau
rng = random.Random(1203)

K.PAL.update({
    "plank_light": (196, 136, 82), "plank_dark": (150, 96, 56), "plank_patch": (122, 150, 96), "post_wood": (110, 70, 40),
    "trim_cream": (240, 222, 180), "shingle": (176, 72, 54), "shingle_dark": (134, 52, 40), "tarp": (60, 130, 220),
    "stone_block": (168, 164, 158), "awning_red": (226, 64, 58), "awning_white": (248, 244, 236), "iron": (64, 64, 74),
    "barrel": (160, 104, 58), "crate": (214, 168, 98), "flower_red": (236, 70, 90), "flower_yel": (255, 210, 60),
    "leaf_box": (80, 170, 50), "avatar": (255, 210, 60), "grass": (124, 222, 52), "path": (255, 160, 24),
})
K.GLOWS.update({"lantern": ((255, 214, 130), 3.2)})
ROUGH = {"plank_light": 0.75, "plank_dark": 0.75, "plank_patch": 0.75, "post_wood": 0.8, "trim_cream": 0.6, "shingle": 0.7,
         "shingle_dark": 0.7, "tarp": 0.5, "stone_block": 0.85, "awning_red": 0.6, "awning_white": 0.6, "iron": 0.45,
         "barrel": 0.7, "crate": 0.75, "grass": 0.85, "path": 0.8, "avatar": 0.7, "leaf_box": 0.8}


def mat(look):
    m = K.mat(look)
    if look in ROUGH:
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Roughness"].default_value = ROUGH[look]
    return m


BMS = {}


def bm_for(name, look):
    if name not in BMS:
        BMS[name] = (bmesh.new(), look)
    return BMS[name][0]


def P(x, y, z):
    """firm-local (x across, y up, z into the plot) -> Blender (X, Y, Z)."""
    return Vector((x, z, y))


def box(name, look, c, size, rot=(0, 0, 0), bevel=0.0):
    """A box centred at firm-local c with size (sx, sy up, sz deep), rotated (degrees about firm x, y, z)."""
    bm = bm_for(name, look)
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    for v in tmp.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[2], v.co.z * size[1]))
    if bevel > 0:
        bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=bevel, segments=1, affect="EDGES", profile=0.5)
    # firm rotation (x, y, z) -> Blender axes (X, Z, Y)
    R = Euler((math.radians(rot[0]), math.radians(rot[2]), math.radians(rot[1])), "XYZ").to_matrix().to_4x4()
    M = Matrix.Translation(P(*c)) @ R
    for v in tmp.verts:
        v.co = M @ v.co
    me = bpy.data.meshes.new("t")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def cyl(name, look, c, r, h, segs=16, axis="y", r_top=None):
    bm = bm_for(name, look)
    r_top = r if r_top is None else r_top
    base = P(*c)
    if axis == "y":
        a_up, a1, a2 = Vector((0, 0, 1)), Vector((1, 0, 0)), Vector((0, 1, 0))
    elif axis == "x":
        a_up, a1, a2 = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
    else:
        a_up, a1, a2 = Vector((0, 1, 0)), Vector((1, 0, 0)), Vector((0, 0, 1))
    bot = [bm.verts.new(base + (a1 * math.cos(k / segs * TAU) + a2 * math.sin(k / segs * TAU)) * r) for k in range(segs)]
    top = [bm.verts.new(base + a_up * h + (a1 * math.cos(k / segs * TAU) + a2 * math.sin(k / segs * TAU)) * r_top) for k in range(segs)]
    for k in range(segs):
        j = (k + 1) % segs
        bm.faces.new((bot[k], bot[j], top[j], top[k]))
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)


def studs(name, look, x0, x1, z0, z1, y, skip=None, rad=0.32, h=0.2, segs=10):
    """Classic studs on the 1-stud grid over a rectangle (firm-local), skipping cells where skip(x, z) is true."""
    bm = bm_for(name, look)
    x = math.floor(x0) + 0.5
    while x < x1:
        z = math.floor(z0) + 0.5
        while z < z1:
            if not (skip and skip(x, z)):
                b = P(x, y, z)
                bot = [bm.verts.new(b + Vector((math.cos(k / segs * TAU) * rad, math.sin(k / segs * TAU) * rad, 0))) for k in range(segs)]
                top = [bm.verts.new(b + Vector((math.cos(k / segs * TAU) * rad * 0.94, math.sin(k / segs * TAU) * rad * 0.94, h))) for k in range(segs)]
                for k in range(segs):
                    j = (k + 1) % segs
                    bm.faces.new((bot[k], bot[j], top[j], top[k]))
                bm.faces.new(top)
            z += 1
        x += 1


# ------------------------------------------------------------------ the shack
WALL_H = 9.0
X0, X1, Z0, Z1 = -12.0, 12.0, -3.0, 21.0


def footings_and_floor():
    """The floor sits on stone blocks (a little raised off the ground), studded planks on top."""
    for x in (-11.4, -3.8, 3.8, 11.4):
        for z in (-2.4, 6.0, 13.0, 20.4):
            box("Shack_Stone", "stone_block", (x, -0.75, z), (1.4, 1.5, 1.4), bevel=0.12)
    box("Shack_Floor", "plank_dark", (0, -0.2, 9.0), (24.0, 0.4, 24.0))
    for i in range(12):  # floor boards: alternating light / dark strips across
        z = Z0 + 1.0 + i * 2.0
        box("Shack_FloorBoards" if i % 2 else "Shack_Floor", "plank_light" if i % 2 else "plank_dark", (0, 0.02, z), (23.6, 0.06, 1.9))
    # studs on the floor, except under the walk-in route? (studs are low, the route stays walkable - keep them all)
    studs("Shack_FloorStuds", "plank_light", X0 + 0.6, X1 - 0.6, Z0 + 0.6, Z1 - 0.6, 0.05)


def plank_wall(name_prefix, x0, z0, x1, z1, openings, base_y=0.0, top_y=WALL_H):
    """A wall of vertical planks from (x0, z0) to (x1, z1), leaving `openings` [(u0, u1, y0, y1)] (u = distance along the
    wall). Planks alternate light / dark, a few are patched green, their tops are slightly ragged."""
    L = math.hypot(x1 - x0, z1 - z0)
    dx, dz = (x1 - x0) / L, (z1 - z0) / L
    yaw = -math.degrees(math.atan2(dz, dx))
    w = 1.0
    n = int(L / w)
    for i in range(n):
        u0, u1 = i * w, (i + 1) * w
        uc = (u0 + u1) / 2
        segs = [(base_y, top_y + rng.uniform(-0.25, 0.25))]
        for o0, o1, oy0, oy1 in openings:
            if u1 > o0 and u0 < o1:  # this plank crosses an opening: cut the opening out of it
                new = []
                for a, b in segs:
                    if b <= oy0 or a >= oy1:
                        new.append((a, b))
                    else:
                        if a < oy0:
                            new.append((a, oy0))
                        if b > oy1:
                            new.append((oy1, b))
                segs = new
        look, name = ("plank_light", name_prefix + "_PlankLight") if i % 2 == 0 else ("plank_dark", name_prefix + "_PlankDark")
        if rng.random() < 0.08:
            look, name = "plank_patch", name_prefix + "_Patch"
        for a, b in segs:
            if b - a < 0.3:
                continue
            cx, cz = x0 + dx * uc, z0 + dz * uc
            box(name, look, (cx, (a + b) / 2, cz), (w * 0.96, b - a, 0.5), rot=(0, yaw, rng.uniform(-0.6, 0.6)))
    # horizontal rails top + bottom (on the outside)
    nx, nz = dz, -dx  # outward normal for a wall going counter-clockwise
    for ry in (0.5, top_y - 0.6):
        box("Shack_Rail", "post_wood", ((x0 + x1) / 2 + nx * 0.32, ry, (z0 + z1) / 2 + nz * 0.32), (L, 0.45, 0.2), rot=(0, yaw, 0))


def walls():
    # front (z = -3, from x -12 to 12): door gap -3..3 (to 7.5 high), windows at x +-7.5
    plank_wall("Shack", X1, Z0, X0, Z0, [(9 - 3.0, 9 + 3.0, 0, 7.5), (2.8, 6.4, 3.0, 6.4), (17.6, 21.2, 3.0, 6.4)])
    # back (z = 21, from x -12 to 12): the aisle gap -3..3
    plank_wall("Shack", X0, Z1, X1, Z1, [(9, 15, 0, 8.0)])
    # sides: doorways near the front (z -0.2 .. 3.2), a window further back on each
    plank_wall("Shack", X0, Z0, X0, Z1, [(2.8, 6.2, 0, 7.2), (12.0, 15.4, 3.0, 6.4)])
    plank_wall("Shack", X1, Z1, X1, Z0, [(24 - 6.2, 24 - 2.8, 0, 7.2), (24 - 15.4, 24 - 12.0, 3.0, 6.4)])
    for x, z in ((X0, Z0), (X1, Z0), (X0, Z1), (X1, Z1)):  # chunky corner posts
        box("Shack_Post", "post_wood", (x, WALL_H / 2, z), (1.0, WALL_H + 0.4, 1.0), bevel=0.1)
    # door frame + a door leaf hanging open (swung in), the side doorway frames
    box("Shack_Trim", "trim_cream", (-3.2, 3.9, Z0 - 0.3), (0.5, 7.9, 0.5), bevel=0.06)
    box("Shack_Trim", "trim_cream", (3.2, 3.9, Z0 - 0.3), (0.5, 7.9, 0.5), bevel=0.06)
    box("Shack_Trim", "trim_cream", (0, 7.8, Z0 - 0.3), (6.9, 0.5, 0.5), bevel=0.06)
    box("Shack_Door", "plank_dark", (-2.6 + 1.4, 3.6, Z0 + 1.6), (2.8, 7.0, 0.25), rot=(0, -78, 0))
    for sx in (-1, 1):
        for z in (-0.4, 3.4):
            box("Shack_Trim", "trim_cream", (sx * (12.3), 3.6, z), (0.4, 7.2, 0.4), bevel=0.05)
        box("Shack_Trim", "trim_cream", (sx * 12.3, 7.3, 1.5), (0.4, 0.4, 4.2), bevel=0.05)


def window(cx, cz, face_axis, yaw, crooked=False):
    """A framed window with a cross mullion, glass, a sill and a flower box; one shutter (crooked on request)."""
    def at(u, y, d):  # u along the wall, d outward (firm-local)
        if face_axis == "z":
            return (cx + u, y, cz - d)
        return (cx + d * (1 if cx > 0 else -1), y, cz + u)
    sz = (lambda a, b, c: (a, b, c)) if face_axis == "z" else (lambda a, b, c: (c, b, a))
    box("Shack_Glass", "glass", at(0, 4.7, -0.05), sz(3.4, 3.2, 0.1))
    for u in (-1.85, 1.85):
        box("Shack_Trim", "trim_cream", at(u, 4.7, 0.3), sz(0.35, 3.9, 0.35), bevel=0.05)
    for y in (3.0, 6.4):
        box("Shack_Trim", "trim_cream", at(0, y, 0.3), sz(4.05, 0.35, 0.35), bevel=0.05)
    box("Shack_Trim", "trim_cream", at(0, 4.7, 0.2), sz(0.2, 3.2, 0.2))
    box("Shack_Trim", "trim_cream", at(0, 4.7, 0.2), sz(3.4, 0.2, 0.2))
    box("Shack_Trim", "trim_cream", at(0, 2.8, 0.55), sz(4.3, 0.25, 0.8), bevel=0.05)  # sill
    box("Shack_FlowerBox", "plank_dark", at(0, 2.3, 0.75), sz(3.8, 0.8, 0.8), bevel=0.06)
    bm = bm_for("Shack_Flowers", "flower_red")
    for k in range(7):
        c = at(-1.5 + k * 0.5, 2.95 + rng.uniform(0, 0.25), 0.75)
        g = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.28)
        for v in g["verts"]:
            v.co += P(*c)
    bm = bm_for("Shack_Leaves", "leaf_box")
    for k in range(6):
        c = at(-1.3 + k * 0.52, 2.8, 0.82)
        g = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.32)
        for v in g["verts"]:
            v.co += P(*c)
    # one shutter, hanging off one hinge when crooked
    tilt = 14 if crooked else 0
    box("Shack_Shutter", "awning_red" if not crooked else "plank_patch", at(-2.9, 4.6 - (0.35 if crooked else 0), 0.35),
        sz(1.6, 3.4, 0.18), rot=(0, 0, tilt) if face_axis == "z" else (tilt, 0, 0), bevel=0.05)


def roof():
    """A shingled gable roof (ridge along x) with an overhang, a tarp patch, a stovepipe, cream fascia boards."""
    ridge_y, eave_y = WALL_H + 4.4, WALL_H - 0.2
    over = 1.4
    zc = (Z0 + Z1) / 2
    half = (Z1 - Z0) / 2 + over
    pitch = math.degrees(math.atan2(ridge_y - eave_y, half))
    slope_len = math.hypot(ridge_y - eave_y, half)
    for side in (-1, 1):  # rows of overlapping shingle strips, alternating tones
        rows = 9
        for r in range(rows):
            t = (r + 0.5) / rows
            z = zc + side * half * (1 - t)
            y = eave_y + (ridge_y - eave_y) * t + 0.15
            look, name = ("shingle", "Shack_Shingle") if r % 2 == 0 else ("shingle_dark", "Shack_ShingleDark")
            box(name, look, (0, y, z), (24 + over * 2, 0.35, slope_len / rows + 0.35), rot=(-side * pitch, 0, 0))
        # the roof deck under the shingles (closes the gaps)
        box("Shack_RoofDeck", "plank_dark", (0, (ridge_y + eave_y) / 2 - 0.1, zc + side * half / 2), (24 + over * 2, 0.3, slope_len),
            rot=(-side * pitch, 0, 0))
        box("Shack_Trim", "trim_cream", (0, eave_y - 0.1, zc + side * half), (24 + over * 2 + 0.4, 0.5, 0.35), bevel=0.06)  # fascia
    box("Shack_Trim", "trim_cream", (0, ridge_y + 0.4, zc), (24 + over * 2 + 0.4, 0.5, 0.9), bevel=0.1)  # ridge cap
    # gable ends: triangles of planks filling the wall top up to the ridge
    for x in (X0, X1):
        bm = bm_for("Shack_Gable", "plank_light")
        a, b, c = P(x, WALL_H, Z0), P(x, WALL_H, Z1), P(x, ridge_y - 0.2, zc)
        off = Vector((0.25 if x > 0 else -0.25, 0, 0))
        va = [bm.verts.new(p + off) for p in (a, b, c)]
        vb = [bm.verts.new(p - off) for p in (a, b, c)]
        bm.faces.new(va)
        bm.faces.new(list(reversed(vb)))
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((va[i], va[j], vb[j], vb[i]))
        box("Shack_Trim", "trim_cream", (x * 1.02, WALL_H + 1.6, zc), (0.3, 1.8, 1.8), rot=(45, 0, 0), bevel=0.05)  # a vent
    # blue tarp patch over the right-hand incubator, pinned with stones; a stovepipe with a cap
    box("Shack_Tarp", "tarp", (6.5, eave_y + (ridge_y - eave_y) * 0.42 + 0.45, zc + half * 0.55), (7.5, 0.15, 6.0), rot=(-pitch, 0, -3))
    for dx, dz in ((-3.2, -2.2), (3.4, 2.4), (-2.8, 2.6)):
        g = bm_for("Shack_TarpStones", "stone_block")
        s_ = bmesh.ops.create_icosphere(g, subdivisions=1, radius=0.45)
        for v in s_["verts"]:
            v.co += P(6.5 + dx, eave_y + (ridge_y - eave_y) * (0.42 - dz * 0.05) + 0.8, zc + half * 0.55 + dz)
    cyl("Shack_Pipe", "iron", (-7.0, ridge_y - 1.6, zc + 3.0), 0.55, 4.2, segs=14)
    cyl("Shack_Pipe", "iron", (-7.0, ridge_y + 2.6, zc + 3.0), 1.0, 0.4, segs=14)


def porch():
    """A plank deck across the front with three steps, two posts holding a little striped awning over the door, a hanging
    lantern, a crooked OPEN sign, barrels and crates."""
    box("Shack_PorchDeck", "plank_light", (0, -0.15, -5.0), (22.0, 0.3, 4.0))
    for i in range(11):
        box("Shack_PorchBoards", "plank_dark", (-10.0 + i * 2.0, 0.02, -5.0), (0.15, 0.06, 3.9))
    studs("Shack_PorchStuds", "plank_light", -10.8, 10.8, -6.8, -3.2, 0.0)
    for i in range(3):
        box("Shack_Steps", "plank_dark" if i % 2 else "plank_light", (0, -0.5 - i * 0.45, -7.4 - i * 0.9), (8.0, 0.4, 0.9), bevel=0.06)
    for sx in (-1, 1):
        box("Shack_Post", "post_wood", (sx * 4.2, 3.6, -6.6), (0.55, 7.4, 0.55), bevel=0.06)
    # the striped awning (sloping out from the wall over the door), with a scalloped valance
    for i in range(8):
        x = -4.6 + i * (9.2 / 8) + 9.2 / 16
        box("Shack_AwningRed" if i % 2 == 0 else "Shack_AwningWhite", "awning_red" if i % 2 == 0 else "awning_white",
            (x, 7.4, -5.0), (9.2 / 8, 0.18, 4.2), rot=(16, 0, 0))  # high at the wall, low at the street
    for i in range(8):
        x = -4.6 + i * (9.2 / 8) + 9.2 / 16
        cyl("Shack_AwningRed" if i % 2 == 0 else "Shack_AwningWhite", "awning_red" if i % 2 == 0 else "awning_white",
            (x - 9.2 / 16, 6.62, -7.0), 0.42, 9.2 / 8, segs=10, axis="x")
    # lantern on a bracket by the door
    box("Shack_Iron", "iron", (4.0, 7.0, -3.9), (0.15, 0.15, 1.6))
    box("Shack_Iron", "iron", (4.0, 6.4, -4.6), (0.9, 0.15, 0.9))
    box("Shack_Lantern", "lantern", (4.0, 5.8, -4.6), (0.65, 1.0, 0.65))
    box("Shack_Iron", "iron", (4.0, 5.2, -4.6), (0.9, 0.15, 0.9))
    # crooked OPEN sign on the wall, right of the door
    box("Shack_OpenSign", "flower_yel", (8.0, 6.6, -3.45), (3.4, 1.2, 0.15), rot=(0, 0, 6), bevel=0.05)
    # barrels + crates at the porch ends
    for x, z in ((-9.6, -5.2), (-8.0, -6.0)):
        cyl("Shack_Barrel", "barrel", (x, 0.0, z), 0.8, 1.9, segs=16)
        for y in (0.35, 1.5):
            cyl("Shack_Iron", "iron", (x, y, z), 0.84, 0.12, segs=16)
    for (x, y, z, s, r) in ((9.4, 0.6, -5.4, 1.2, 8), (10.2, 0.6, -6.6, 1.0, -12), (9.6, 1.8, -5.5, 0.9, 20)):
        box("Shack_Crate", "crate", (x, y, z), (s, s, s), rot=(0, r, 0), bevel=0.08)
        box("Shack_Iron", "post_wood", (x, y, z), (s * 1.02, s * 0.2, s * 1.02), rot=(0, r, 0))


def player(x, z):
    for (cx, cy, cz, sx, sy, sz) in ((0, 4.4, 0, 1.0, 1.0, 1.0), (0, 2.9, 0, 2.0, 2.0, 1.0), (-1.5, 2.9, 0, 1.0, 2.0, 1.0),
                                      (1.5, 2.9, 0, 1.0, 2.0, 1.0), (-0.5, 0.95, 0, 1.0, 1.9, 1.0), (0.5, 0.95, 0, 1.0, 1.9, 1.0)):
        box("Preview_Player", "avatar", (x + cx, cy, z + cz), (sx, sy, sz))


def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    sc = bpy.context.scene
    K.sky_and_sun(sc, sun_energy=3.8, sun_rot=(52, 8, -32))
    sc.collection.objects.link(bpy.data.objects["Sun"])
    footings_and_floor(); walls(); roof(); porch()
    window(-7.5, Z0, "z", 0)
    window(7.5, Z0, "z", 0, crooked=True)
    window(-12.0, 10.7, "x", 90)
    window(12.0, 10.7, "x", -90)
    player(-6.5, -10.0)
    box("Preview_Ground", "grass", (0, -1.6, 9), (90, 0.2, 90))
    box("Preview_Path", "path", (0, -1.48, -14), (8, 0.1, 14))
    for name, (bm, look) in BMS.items():
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        me.materials.append(mat(look))
        smooth = name in ("Shack_Pipe", "Shack_Barrel", "Shack_Flowers", "Shack_Leaves", "Shack_TarpStones")
        for p in me.polygons:
            p.use_smooth = smooth
        ob = bpy.data.objects.new(name, me)
        sc.collection.objects.link(ob)
    return sc


def stats():
    tot = 0
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            t = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            tot += t
            print(f"{ob.name:20s} tris={t}")
    print("TOTAL tris", tot, "meshes", sum(1 for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Preview")))


def render(sc, name, loc, look, lens=30):
    sc.camera = K.camera(name, loc, look, lens=lens)
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.render.filepath = os.path.join(OUT, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


sc = build()
K.setup_eevee(sc, samples=48)
stats()
# (Blender coords: X = firm x, Y = firm z, Z = firm y)
render(sc, "shack_front", (-16, -36, 7), (0, 6, 5), lens=30)
render(sc, "shack_three_quarter", (30, -30, 16), (0, 8, 4), lens=30)
render(sc, "shack_close", (-4, -14, 4.5), (2, -3, 5.5), lens=26)
if FBX:
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "DingyShack.fbx"), use_selection=True, apply_unit_scale=True,
                             axis_forward="-Z", axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE")
