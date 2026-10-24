# tools/blender/overhaul/firm_shack.py - MAP MODEL OVERHAUL, stage 1 benchmark: the starter firm front, the DINGY SHACK,
# as meshes (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"). v2 (crnuch: "it does not look dingy enough"):
# weathered grey planks of uneven widths with gaps, broken bottoms and crooked boards nailed over holes, moss at the base;
# a SAGGING shingle roof with missing shingles, rusty corrugated patches, a faded tarp held down by a tyre; one window
# boarded up, one cracked; the door hanging off a hinge; a sagging porch with a broken step and leaning posts; a faded,
# torn awning; and junk - trash bags, a dumpster, a tyre stack, a cone, weeds, a crooked mailbox, a puddle. Still cute and
# readable (kid audience). Studs only on the porch deck and the floor (structural tops).
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

K.PAL.update({  # weathered: greyer, duller, but still the game's warm toy palette
    "plank_light": (172, 140, 106), "plank_dark": (126, 98, 74), "plank_patch": (118, 128, 100), "post_wood": (92, 64, 44),
    "trim_cream": (204, 190, 158), "shingle": (156, 86, 70), "shingle_dark": (116, 66, 56), "tarp": (86, 124, 176),
    "stone_block": (150, 146, 140), "awning_red": (196, 98, 86), "awning_white": (226, 214, 190), "iron": (62, 62, 70),
    "rust": (172, 94, 52), "sheet": (150, 158, 166), "moss": (98, 146, 60), "trash": (44, 48, 54), "dumpster": (64, 112, 74),
    "tire": (36, 36, 40), "cone": (255, 124, 34), "cone_white": (240, 240, 240), "weed": (96, 168, 52), "mailbox": (120, 130, 144),
    "cardboard": (198, 160, 112), "crate": (186, 150, 100), "barrel": (140, 96, 60), "dark_hole": (34, 28, 26),
    "plant_dead": (140, 110, 60), "pot": (178, 98, 64), "avatar": (255, 210, 60), "grass": (124, 222, 52), "path": (255, 160, 24),
})
K.GLOWS.update({"lantern": ((255, 196, 110), 1.6)})  # a dim, tired bulb
K.GLASS.update({"glass_dirty": (150, 176, 170)})
ROUGH = {k: 0.8 for k in ("plank_light", "plank_dark", "plank_patch", "post_wood", "trim_cream", "shingle", "shingle_dark",
                          "stone_block", "moss", "dumpster", "tire", "weed", "cardboard", "crate", "barrel", "plant_dead",
                          "pot", "grass", "path", "avatar", "awning_red", "awning_white", "rust", "trash", "dark_hole")}
ROUGH.update({"tarp": 0.55, "iron": 0.5, "sheet": 0.45, "mailbox": 0.5, "cone": 0.6, "cone_white": 0.6})


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


def blob(name, look, c, r, squash=1.0, sub=1):
    bm = bm_for(name, look)
    g = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    for v in g["verts"]:
        v.co = Vector((v.co.x, v.co.y, v.co.z * squash)) + P(*c)


def footings_and_floor():
    """The floor on stone blocks (one sunk lower: the whole shack leans a hair), studded planks, a couple of boards gone."""
    for x in (-11.4, -3.8, 3.8, 11.4):
        for z in (-2.4, 6.0, 13.0, 20.4):
            sunk = 0.25 if (x, z) == (11.4, -2.4) else 0.0
            box("Shack_Stone", "stone_block", (x, -0.75 - sunk, z), (1.4, 1.5, 1.4), rot=(0, rng.uniform(-8, 8), 0), bevel=0.12)
    box("Shack_Floor", "dark_hole", (0, -0.25, 9.0), (24.0, 0.3, 24.0))
    for i in range(24):  # floor boards: two tones, uneven, two missing (dark gaps) away from the walk-in route
        z = Z0 + 0.5 + i * 1.0
        if i in (17, 18) :
            box("Shack_FloorBoards", "plank_dark", (-8.5, 0.0, z), (7.0, 0.12, 0.92))  # only the left part left
            box("Shack_FloorBoards", "plank_dark", (8.0, 0.0, z), (8.0, 0.12, 0.92))
            continue
        look = "plank_light" if i % 2 else "plank_dark"
        box("Shack_FloorLight" if i % 2 else "Shack_FloorBoards", look, (0, 0.0 + rng.uniform(-0.03, 0.03), z), (23.6, 0.12, 0.92))
    studs("Shack_FloorStuds", "plank_dark", X0 + 0.6, X1 - 0.6, Z0 + 0.6, Z1 - 0.6, 0.06,
          skip=lambda x, z: 13.5 < z < 15.6 and abs(x) < 4.5)


def plank_wall(prefix, x0, z0, x1, z1, openings, top_y=WALL_H, gaps=(), crossboards=()):
    """Vertical planks of uneven widths from (x0, z0) to (x1, z1) (counter-clockwise seen from above, so the outside is on the
    right), leaving `openings` [(u0, u1, y0, y1)] (u = distance along the wall). `gaps` = u ranges with missing planks
    (dark behind), `crossboards` = (u, y, length, angle) boards nailed across."""
    L = math.hypot(x1 - x0, z1 - z0)
    dx, dz = (x1 - x0) / L, (z1 - z0) / L
    nx, nz = -dz, dx  # outward (the street side of the front wall is -z)
    yaw = -math.degrees(math.atan2(dz, dx))
    u = 0.0
    k = 0
    while u < L - 0.05:
        w = min(rng.choice((0.7, 0.85, 1.0, 1.0, 1.2, 1.35)), L - u)
        u0, u1 = u, u + w
        uc = (u0 + u1) / 2
        u = u1
        k += 1
        if any(g0 <= uc <= g1 for g0, g1 in gaps):
            continue
        bottom = rng.choice((0.0, 0.0, 0.0, 0.0, 0.4, 0.8))  # some boards rotted off at the bottom
        segs = [(bottom, top_y + rng.uniform(-0.7, 0.3))]
        for o0, o1, oy0, oy1 in openings:
            if u1 > o0 and u0 < o1:
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
        r = rng.random()
        look, name = (("plank_light", prefix + "_PlankLight") if k % 2 else ("plank_dark", prefix + "_PlankDark"))
        if r < 0.12:
            look, name = "plank_patch", prefix + "_Patch"
        for a, b in segs:
            if b - a < 0.3:
                continue
            cx, cz = x0 + dx * uc, z0 + dz * uc
            box(name, look, (cx, (a + b) / 2, cz), (w * 0.94, b - a, 0.5), rot=(0, yaw, rng.uniform(-1.6, 1.6)))
    box(prefix + "_Hole", "dark_hole", ((x0 + x1) / 2 - nx * 0.4, top_y / 2, (z0 + z1) / 2 - nz * 0.4), (L, top_y, 0.1),
        rot=(0, yaw, 0))  # dark backing: gaps between planks look like holes, not daylight
    for ry in (0.6, top_y - 0.9):
        box("Shack_Rail", "post_wood", ((x0 + x1) / 2 + nx * 0.32, ry + rng.uniform(-0.1, 0.1), (z0 + z1) / 2 + nz * 0.32),
            (L, 0.45, 0.2), rot=(0, yaw, rng.uniform(-0.8, 0.8)))
    for cu, cy, cl, ca in crossboards:
        cx, cz = x0 + dx * cu + nx * 0.45, z0 + dz * cu + nz * 0.45
        box("Shack_CrossBoard", "plank_patch", (cx, cy, cz), (cl, 0.55, 0.15), rot=(0, yaw, ca))
    for i in range(int(L / 1.6)):  # moss creeping up the base
        uu = rng.uniform(0.5, L - 0.5)
        blob("Shack_Moss", "moss", (x0 + dx * uu + nx * 0.4, rng.uniform(0.0, 0.5), z0 + dz * uu + nz * 0.4), rng.uniform(0.35, 0.7), 0.6)


def walls():
    # front (z = -3, x 12 -> -12): door gap -3..3; windows at x -7.5 (boarded) and +7.5 (cracked)
    plank_wall("Shack", X1, Z0, X0, Z0, [(9 - 3.0, 9 + 3.0, 0, 7.5), (2.8, 6.4, 3.0, 6.4), (17.6, 21.2, 3.0, 6.4)],
               gaps=[(0.6, 1.4)], crossboards=[(1.0, 2.2, 2.2, 28)])
    # back (z = 21, x -12 -> 12): the aisle gap -3..3, a missing plank or two
    plank_wall("Shack", X0, Z1, X1, Z1, [(9, 15, 0, 8.0)], gaps=[(4.0, 4.8), (19.5, 20.3)])
    # sides: doorways near the front (z -0.2 .. 3.2), a window further back
    plank_wall("Shack", X0, Z0, X0, Z1, [(2.8, 6.2, 0, 7.2), (12.0, 15.4, 3.0, 6.4)], gaps=[(19.0, 19.9)],
               crossboards=[(19.4, 4.5, 2.6, -32), (19.4, 3.0, 2.4, 25)])
    plank_wall("Shack", X1, Z1, X1, Z0, [(24 - 6.2, 24 - 2.8, 0, 7.2), (24 - 15.4, 24 - 12.0, 3.0, 6.4)], gaps=[(3.0, 3.8)])
    for x, z in ((X0, Z0), (X1, Z0), (X0, Z1), (X1, Z1)):  # chunky corner posts, not quite plumb
        box("Shack_Post", "post_wood", (x, WALL_H / 2, z), (1.0, WALL_H + 0.4, 1.0), rot=(rng.uniform(-1.5, 1.5), 0, rng.uniform(-1.5, 1.5)), bevel=0.1)
    # the door opening: a sagging lintel, and the door itself hanging off one hinge, leaning out on the porch
    for x in (-3.2, 3.2):
        box("Shack_Trim", "trim_cream", (x, 3.9, Z0 - 0.3), (0.5, 7.9, 0.5), bevel=0.06)
    box("Shack_Trim", "trim_cream", (0, 7.7, Z0 - 0.3), (6.9, 0.5, 0.5), rot=(0, 0, -2.5), bevel=0.06)
    box("Shack_Door", "plank_dark", (-4.6, 3.3, Z0 - 0.9), (2.8, 6.6, 0.25), rot=(0, -14, 9))
    for yy in (1.4, 5.2):
        box("Shack_CrossBoard", "plank_patch", (-4.6 + (yy - 3.3) * 0.15, yy, Z0 - 1.05), (2.6, 0.4, 0.12), rot=(0, -14, 9))
    for sx in (-1, 1):
        for z in (-0.4, 3.4):
            box("Shack_Trim", "trim_cream", (sx * 12.3, 3.6, z), (0.4, 7.2, 0.4), bevel=0.05)
        box("Shack_Trim", "trim_cream", (sx * 12.3, 7.3, 1.5), (0.4, 0.4, 4.2), rot=(sx * 3, 0, 0), bevel=0.05)


def window(cx, cz, face_axis, kind):
    """kind: 'boarded' (planks nailed across, dark behind), 'cracked' (glass shards with a hole + a hanging shutter),
    'dirty' (grimy glass + a dead plant in a pot on the sill)."""
    def at(u, y, d):
        if face_axis == "z":
            return (cx + u, y, cz - d)
        return (cx + d * (1 if cx > 0 else -1), y, cz + u)
    sz = (lambda a, b, c: (a, b, c)) if face_axis == "z" else (lambda a, b, c: (c, b, a))
    rz = (lambda a: (0, 0, a)) if face_axis == "z" else (lambda a: (a, 0, 0))
    for u in (-1.85, 1.85):
        box("Shack_Trim", "trim_cream", at(u, 4.7, 0.3), sz(0.35, 3.9, 0.35), rot=rz(rng.uniform(-2, 2)), bevel=0.05)
    for y in (3.0, 6.4):
        box("Shack_Trim", "trim_cream", at(0, y, 0.3), sz(4.05, 0.35, 0.35), rot=rz(rng.uniform(-2, 2)), bevel=0.05)
    if kind == "boarded":
        box("Shack_Hole2", "dark_hole", at(0, 4.7, -0.05), sz(3.4, 3.2, 0.1))
        for y, a in ((5.6, 12), (4.5, -9), (3.5, 6)):
            box("Shack_CrossBoard", "plank_patch", at(rng.uniform(-0.2, 0.2), y, 0.5), sz(4.6, 0.6, 0.15), rot=rz(a))
        return
    if kind == "cracked":
        bm = bm_for("Shack_GlassDirty", "glass_dirty")
        c = P(*at(0, 4.7, -0.02))
        side = Vector((1, 0, 0)) if face_axis == "z" else Vector((0, 1, 0))
        up = Vector((0, 0, 1))
        hole = c + side * 0.5 + up * 0.4  # the cracks radiate from here; one shard is missing
        corners = [c + side * sx * 1.7 + up * sy * 1.6 for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        pts = []
        for i in range(4):
            a, b = corners[i], corners[(i + 1) % 4]
            pts += [a, a.lerp(b, 0.45)]
        for i in range(len(pts)):
            if i == 5:
                continue  # the missing shard
            va, vb = pts[i], pts[(i + 1) % len(pts)]
            bm.faces.new((bm.verts.new(hole), bm.verts.new(va), bm.verts.new(vb)))
        box("Shack_Hole2", "dark_hole", at(0, 4.7, -0.15), sz(3.4, 3.2, 0.08))
        box("Shack_Shutter", "awning_red", at(-2.6, 4.0, 0.4), sz(1.6, 3.4, 0.18), rot=rz(-24), bevel=0.05)  # off one hinge
        return
    box("Shack_GlassDirty", "glass_dirty", at(0, 4.7, -0.05), sz(3.4, 3.2, 0.1))
    box("Shack_Trim", "trim_cream", at(0, 2.8, 0.55), sz(4.3, 0.25, 0.8), rot=rz(-3), bevel=0.05)
    cyl("Shack_Pot", "pot", at(0.8, 2.92, 0.6), 0.38, 0.6, segs=12)
    for a in (-30, 10, 40):
        box("Shack_DeadPlant", "plant_dead", at(0.8 + math.sin(math.radians(a)) * 0.3, 3.9, 0.6), sz(0.12, 1.4, 0.12), rot=rz(a))


def roof():
    """A SAGGING shingle gable roof: shingle rows split into tiles along the ridge so the middle dips; some tiles are missing
    (the dark deck shows), two rusty corrugated patches on the front, a faded tarp + a tyre and stones on the back."""
    ridge_y, eave_y = WALL_H + 4.4, WALL_H - 0.2
    over = 1.4
    zc = (Z0 + Z1) / 2
    half = (Z1 - Z0) / 2 + over
    pitch = math.degrees(math.atan2(ridge_y - eave_y, half))
    slope_len = math.hypot(ridge_y - eave_y, half)
    tiles = 7
    tile_w = (24 + over * 2) / tiles

    def sag(x):  # the middle of the roof dips
        return -1.0 * math.sin(math.pi * (x + 12 + over) / (24 + over * 2))

    for side in (-1, 1):
        rows = 9
        for r in range(rows):
            t = (r + 0.5) / rows
            z = zc + side * half * (1 - t)
            y = eave_y + (ridge_y - eave_y) * t + 0.15
            for k in range(tiles):
                x = -12 - over + (k + 0.5) * tile_w
                if rng.random() < 0.09:
                    continue  # a missing shingle
                look, name = ("shingle", "Shack_Shingle") if (r + k) % 2 == 0 else ("shingle_dark", "Shack_ShingleDark")
                box(name, look, (x, y + sag(x) * (0.6 + 0.4 * t) + rng.uniform(-0.06, 0.06), z),
                    (tile_w + 0.06, 0.35, slope_len / rows + 0.35), rot=(-side * pitch + rng.uniform(-2, 2), 0, rng.uniform(-1.5, 1.5)))
        for k in range(tiles):
            x = -12 - over + (k + 0.5) * tile_w
            box("Shack_RoofDeck", "dark_hole", (x, (ridge_y + eave_y) / 2 - 0.15 + sag(x) * 0.8, zc + side * half / 2),
                (tile_w + 0.05, 0.3, slope_len), rot=(-side * pitch, 0, 0))
            box("Shack_Trim", "trim_cream", (x, eave_y - 0.1 + sag(x) * 0.6, zc + side * half), (tile_w + 0.05, 0.5, 0.35))
    for k in range(tiles):
        x = -12 - over + (k + 0.5) * tile_w
        box("Shack_Trim", "trim_cream", (x, ridge_y + 0.4 + sag(x), zc), (tile_w + 0.05, 0.5, 0.9))
    for x in (X0, X1):  # gable ends (planks) + a vent
        bm = bm_for("Shack_Gable", "plank_light")
        a, b, c = P(x, WALL_H, Z0), P(x, WALL_H, Z1), P(x, ridge_y - 0.3, zc)
        off = Vector((0.25 if x > 0 else -0.25, 0, 0))
        va = [bm.verts.new(p + off) for p in (a, b, c)]
        vb = [bm.verts.new(p - off) for p in (a, b, c)]
        bm.faces.new(va)
        bm.faces.new(list(reversed(vb)))
        for i in range(3):
            j = (i + 1) % 3
            bm.faces.new((va[i], va[j], vb[j], vb[i]))
        box("Shack_CrossBoard", "plank_patch", (x * 1.02, WALL_H + 1.6, zc), (0.3, 1.8, 1.8), rot=(38, 0, 0))
    # rusty corrugated patches on the front slope (wavy sheets)
    for (px, pz_t, w, l, look) in ((-6.5, 0.45, 5.0, 4.6, "rust"), (5.5, 0.3, 4.0, 3.6, "sheet")):
        bm = bm_for("Shack_" + look.capitalize(), look)
        ang = math.radians(pitch)
        z0 = zc - half * (1 - pz_t)
        y0 = eave_y + (ridge_y - eave_y) * pz_t + 0.45 + sag(px) * 0.7
        cols, rows_ = 16, 2
        grid = []
        for i in range(cols + 1):
            xx = px - w / 2 + w * i / cols
            wave = 0.14 * math.sin(i * math.pi / 2)
            col = []
            for j in range(rows_ + 1):
                d = -l / 2 + l * j / rows_
                col.append(bm.verts.new(P(xx, y0 + wave + d * math.sin(ang), z0 + d * math.cos(ang))))
            grid.append(col)
        for i in range(cols):
            for j in range(rows_):
                bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
    # faded tarp on the back slope over the right-hand incubator, held by a tyre and stones
    ty = eave_y + (ridge_y - eave_y) * 0.42 + 0.5 + sag(6.5) * 0.7
    tz = zc + half * 0.55
    box("Shack_Tarp", "tarp", (6.5, ty, tz), (7.5, 0.15, 6.0), rot=(-pitch, 0, -3))
    bm = bm_for("Shack_Tire", "tire")
    tc = P(6.5, ty + 0.6, tz)
    for k in range(20):  # a tyre lying on the tarp (a squashed torus from cylinders)
        pass
    cyl("Shack_Tire", "tire", (6.5, ty + 0.2, tz), 1.2, 0.6, segs=16)
    cyl("Shack_TireHole", "dark_hole", (6.5, ty + 0.25, tz), 0.6, 0.6, segs=12)
    for dx, dz in ((-3.0, -2.0), (3.2, 2.2), (-2.6, 2.4)):
        blob("Shack_TarpStones", "stone_block", (6.5 + dx, ty + 0.4 - dz * 0.4, tz + dz), 0.45)
    # a leaning stovepipe with a dented cap
    box("Shack_Pipe", "iron", (-7.0, ridge_y + 0.8, zc + 3.0), (1.0, 4.6, 1.0), rot=(0, 0, 7))
    box("Shack_Pipe", "iron", (-6.75, ridge_y + 3.2, zc + 3.0), (1.8, 0.35, 1.8), rot=(5, 0, 12))


def porch():
    """A sagging plank deck with gaps and a missing board, a broken step, leaning posts, a faded torn awning, a dim
    lantern and a hand-painted cardboard OPEN sign."""
    for i in range(22):
        x = -10.5 + i * 1.0
        if i in (15,):
            continue  # a missing board
        dip = -0.18 * math.sin(math.pi * i / 21)
        box("Shack_PorchBoards" if i % 2 else "Shack_PorchLight", "plank_dark" if i % 2 else "plank_light",
            (x, -0.15 + dip, -5.0), (0.92, 0.25, 4.0), rot=(rng.uniform(-1, 1), 0, rng.uniform(-0.8, 0.8)))
    box("Shack_PorchUnder", "dark_hole", (0, -0.6, -5.0), (22.0, 0.4, 4.0))
    studs("Shack_PorchStuds", "plank_dark", -10.8, 10.8, -6.8, -3.2, -0.05, skip=lambda x, z: 4.0 < x < 5.0)
    for i in range(3):
        if i == 1:  # the middle step is broken: half of it is gone
            box("Shack_Steps", "plank_dark", (-2.2, -0.5 - i * 0.45, -7.4 - i * 0.9), (3.6, 0.4, 0.9), rot=(0, 0, 4))
            continue
        box("Shack_Steps", "plank_light" if i % 2 == 0 else "plank_dark", (0, -0.5 - i * 0.45, -7.4 - i * 0.9), (8.0, 0.4, 0.9),
            rot=(0, 0, rng.uniform(-2, 2)))
    for sx, lean in ((-1, 4), (1, -6)):
        box("Shack_Post", "post_wood", (sx * 4.2, 3.6, -6.6), (0.55, 7.4, 0.55), rot=(0, 0, lean), bevel=0.06)
    # the faded awning: slats sag more toward the street; one slat missing, one torn and hanging down
    for i in range(8):
        x = -4.6 + i * (9.2 / 8) + 9.2 / 16
        if i == 5:
            continue
        red = i % 2 == 0
        if i == 2:  # torn: hangs down off the frame
            box("Shack_AwningRed", "awning_red", (x, 6.1, -7.0), (9.2 / 8, 2.2, 0.15), rot=(8, 0, 6))
            continue
        box("Shack_AwningRed" if red else "Shack_AwningWhite", "awning_red" if red else "awning_white",
            (x, 7.3 - 0.06 * i, -5.0), (9.2 / 8, 0.16, 4.2), rot=(18 + rng.uniform(0, 5), 0, rng.uniform(-2, 2)))
    # dim lantern on a bent bracket
    box("Shack_Iron", "iron", (4.0, 7.0, -3.9), (0.15, 0.15, 1.6), rot=(14, 0, 0))
    box("Shack_Iron", "iron", (4.0, 6.3, -4.7), (0.9, 0.15, 0.9), rot=(0, 0, 8))
    box("Shack_Lantern", "lantern", (4.05, 5.7, -4.7), (0.65, 1.0, 0.65), rot=(0, 0, 8))
    box("Shack_Iron", "iron", (4.1, 5.1, -4.7), (0.9, 0.15, 0.9), rot=(0, 0, 8))
    # a cardboard OPEN sign, crooked, taped to the wall
    box("Shack_Cardboard", "cardboard", (8.2, 6.8, -3.4), (3.0, 1.4, 0.08), rot=(0, 0, -9))
    box("Shack_Tape", "trim_cream", (6.9, 7.3, -3.46), (0.6, 0.18, 0.05), rot=(0, 0, 35))
    box("Shack_Tape", "trim_cream", (9.5, 6.4, -3.46), (0.6, 0.18, 0.05), rot=(0, 0, -30))


def junk():
    """The original shack's junk, back and better: trash bags round a dumpster, a tyre stack, a traffic cone, weeds, a
    crooked mailbox, a puddle, a broken crate. All kept out of the walk-in route (|x| < 4 in front of the steps)."""
    # dumpster (front left of the yard), lid propped open
    box("Shack_Dumpster", "dumpster", (-9.6, 1.4, -10.2), (5.0, 2.8, 3.0), bevel=0.15)
    box("Shack_Dumpster", "dumpster", (-9.6, 2.95, -11.5), (5.2, 0.25, 3.2), rot=(-55, 0, 0), bevel=0.05)
    for x in (-11.6, -7.6):
        for z in (-11.4, -9.0):
            cyl("Shack_Tire", "tire", (x, 0.0, z), 0.32, 0.15, segs=10, axis="x")
    for (x, z, r) in ((-6.4, -11.2, 0.9), (-6.0, -9.6, 0.8), (-12.6, -8.2, 0.85), (-11.8, -12.4, 0.75), (-7.0, -12.6, 0.7),
                      (-6.6, -10.4, 0.6)):
        blob("Shack_Trash", "trash", (x, r * 0.7, z), r, squash=0.85)
        box("Shack_Trash", "trash", (x, r * 1.5, z), (0.25, 0.4, 0.25), rot=(0, 0, rng.uniform(-30, 30)))  # the tied top
    # tyre stack + a cone (front right)
    for i, (dx, dz) in enumerate(((0, 0), (0.15, -0.1), (-0.1, 0.12))):
        cyl("Shack_Tire", "tire", (9.4 + dx, i * 0.62, -10.4 + dz), 1.15, 0.6, segs=16)
        cyl("Shack_TireHole", "dark_hole", (9.4 + dx, i * 0.62 + 0.01, -10.4 + dz), 0.55, 0.6, segs=12)
    cyl("Shack_Cone", "cone", (6.6, 0.0, -11.6), 0.7, 2.2, segs=12, r_top=0.12)
    cyl("Shack_ConeWhite", "cone_white", (6.6, 0.9, -11.6), 0.47, 0.35, segs=12, r_top=0.4)
    box("Shack_Cone", "cone", (6.6, 0.08, -11.6), (1.7, 0.16, 1.7))
    # crooked mailbox on a post
    box("Shack_Post", "post_wood", (5.6, 1.6, -13.2), (0.35, 3.2, 0.35), rot=(0, 0, -8))
    box("Shack_Mailbox", "mailbox", (5.85, 3.4, -13.2), (1.0, 0.9, 1.8), rot=(0, 10, -8), bevel=0.15)
    box("Shack_Mailbox", "awning_red", (6.4, 3.6, -12.7), (0.1, 0.8, 0.15), rot=(0, 10, 50))  # the flag, drooping
    # a puddle by the steps and a broken crate by the wall
    bm = bm_for("Shack_Puddle", "water")
    c = P(4.8, -1.38, -8.6)
    ring = [bm.verts.new(c + Vector((math.cos(k / 14 * TAU) * (1.6 + 0.3 * math.sin(k * 2.3)), math.sin(k / 14 * TAU) * 1.0, 0)))
            for k in range(14)]
    bm.faces.new(ring)
    box("Shack_Crate", "crate", (10.4, 0.55, -4.6), (1.1, 1.1, 1.1), rot=(0, 18, 0), bevel=0.06)
    box("Shack_Crate", "crate", (11.0, 0.3, -6.0), (1.1, 0.6, 1.1), rot=(0, -10, 12), bevel=0.06)  # squashed
    cyl("Shack_Barrel", "barrel", (-10.3, 0.0, -5.0), 0.8, 1.9, segs=16)
    cyl("Shack_Iron", "iron", (-10.3, 0.35, -5.0), 0.84, 0.12, segs=16)
    # weeds: tufts round the footings, the porch and the yard
    spots = [(-12.4, -3.4), (-11.8, -6.4), (12.3, -2.2), (11.6, -7.6), (-4.6, -8.6), (3.8, -9.4), (-12.8, 6), (12.8, 14),
             (-12.6, 19.8), (8.4, -12.6), (-8.0, -13.4), (2.4, -11.6)]
    for x, z in spots:
        for k in range(5):
            a = k / 5 * TAU + rng.uniform(-0.3, 0.3)
            h = rng.uniform(0.7, 1.5)
            box("Shack_Weeds", "weed", (x + math.cos(a) * 0.25, -1.45 + h / 2, z + math.sin(a) * 0.25), (0.14, h, 0.14),
                rot=(math.sin(a) * 22, 0, -math.cos(a) * 22))


def player(x, z):
    for (cx, cy, cz, sx, sy, sz) in ((0, 4.4, 0, 1.0, 1.0, 1.0), (0, 2.9, 0, 2.0, 2.0, 1.0), (-1.5, 2.9, 0, 1.0, 2.0, 1.0),
                                      (1.5, 2.9, 0, 1.0, 2.0, 1.0), (-0.5, 0.95, 0, 1.0, 1.9, 1.0), (0.5, 0.95, 0, 1.0, 1.9, 1.0)):
        box("Preview_Player", "avatar", (x + cx, cy - 1.5, z + cz), (sx, sy, sz))


def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    sc = bpy.context.scene
    K.sky_and_sun(sc, sun_energy=3.8, sun_rot=(52, 8, -32))
    sc.collection.objects.link(bpy.data.objects["Sun"])
    footings_and_floor(); walls(); roof(); porch(); junk()
    window(-7.5, Z0, "z", "boarded")
    window(7.5, Z0, "z", "cracked")
    window(-12.0, 13.7, "x", "dirty")
    window(12.0, 13.7, "x", "boarded")
    player(-2.0, -15.0)
    box("Preview_Ground", "grass", (0, -1.6, 9), (90, 0.2, 90))
    box("Preview_Path", "path", (0, -1.48, -16), (8, 0.1, 14))
    for name, (bm, look) in BMS.items():
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        me.materials.append(mat(look))
        smooth = name in ("Shack_Barrel", "Shack_Moss", "Shack_Trash", "Shack_TarpStones", "Shack_Tire", "Shack_Cone")
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
render(sc, "shack_front", (-14, -40, 7), (0, 4, 4), lens=30)
render(sc, "shack_three_quarter", (32, -32, 16), (0, 6, 3), lens=30)
render(sc, "shack_close", (-6, -17, 3.5), (1, -3, 4.5), lens=26)
if FBX:
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "DingyShack.fbx"), use_selection=True, apply_unit_scale=True,
                             axis_forward="-Z", axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE")
