# tools/blender/overhaul/firm_shack.py - MAP MODEL OVERHAUL: the starter firm front (Firm stage 1, "Dingy Shack" on
# screen), as meshes. v3 (crnuch 2026-11-02: the v2 shack "is too advanced for the style of the game"): a simple, bright
# STARTER CABIN in the same chunky toy style as the other firm stages - few big pieces, the game's warm palette.
#   Walls of wide horizontal planks (two wood tones), chunky corner posts, a front-gable roof in four big shingle rows a
#   side with cream bargeboards and a ridge cap, a square stone chimney, one wood patch on the roof (the only "humble"
#   touch), cream-framed windows with flower boxes, a porch with a low railing, two steps, a red mat and a lantern, and a
#   few props: a crate stack, a barrel, two flower pots. No junk, no broken boards, no dark filler boxes (v2's
#   near-black "Hole" boxes filled the shack in the game, 2026-10-27).
# v2 (weathered planks, sagging roof, trash bags, dumpster ...) is in git history before 2026-11-02.
# Fits Server.FirmStages' rules for stage 1 (firm-local: x across, y up, z into the plot, -z = street):
#   walls x +-12, z -3 .. 21; front door gap x -3..3 (7.5 high); side doorways x +-12, z -0.2..3.2; the back wall open at
#   x -3..3 (the aisle); the floor clear for |x| < 5, z -2 .. 8 (the walk-in route); a roof over the incubators
#   (+-7.8, 0, 14) - the hatch raycasts up for a ceiling; the name sign's spot (0, 9.2, -3.4) left empty (on the gable).
# Mesh names InstallFirmMeshes / FirmStages look up: Shack_FloorBoards / Shack_FloorLight / Shack_PorchBoards /
#   Shack_PorchLight / Shack_Steps (the only parts that collide) and Shack_Lantern (gets a PointLight).
# Blender: X = firm x, Y = firm z, Z = firm y (front faces -Y = the street). 1 m = 1 stud. One mesh per colour.
#   Blender -b --factory-startup --python tools/blender/overhaul/firm_shack.py -- <out_dir> [--fbx] [--check]
#   (--check: the overhaul checks - floating pieces, z-fighting, buried sheets - instead of renders)
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "kit"))
sys.path.insert(0, HERE)
import hl_kit as K

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv and not argv[0].startswith("--") else os.path.join(HERE, "renders")
FBX = "--fbx" in argv
CHECK = "--check" in argv
os.makedirs(OUT, exist_ok=True)
TAU = math.tau

K.PAL.update({  # the game's warm toy palette (CLAUDE.md "Palette"), same saturation as the other firm stages
    "plank_light": (214, 140, 70), "plank_dark": (184, 110, 52), "post_wood": (122, 70, 34), "trim_cream": (246, 226, 180),
    "floor": (222, 160, 96), "floor_dark": (200, 138, 78), "shingle": (226, 76, 60), "shingle_dark": (194, 58, 48),
    "stone_block": (170, 170, 178), "stone_dark": (130, 130, 140), "iron": (62, 62, 70), "mat_red": (240, 70, 70),
    "crate": (226, 166, 92), "barrel": (160, 98, 54), "pot": (222, 112, 70), "leaf": (70, 168, 34),
    "flower_red": (240, 70, 70), "flower_yellow": (255, 200, 40), "avatar": (255, 210, 60), "grass": (124, 222, 52),
    "path": (255, 160, 24),
})
K.GLOWS.update({"lantern": ((255, 210, 130), 2.0)})
ROUGH = 0.8


def mat(look):
    m = K.mat(look)
    if look in K.PAL and look not in K.GLASS:
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Roughness"].default_value = ROUGH
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


def span(name, look, x0, y0, z0, x1, y1, z1, bevel=0.0):
    """An axis-aligned box from corner to corner (firm-local)."""
    box(name, look, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)), bevel=bevel)


def cyl(name, look, c, r, h, segs=16, r_top=None):
    """An upright cylinder (or cone) standing on firm-local c."""
    bm = bm_for(name, look)
    r_top = r if r_top is None else r_top
    base = P(*c)
    ring = lambda rr, dz: [bm.verts.new(base + Vector((math.cos(k / segs * TAU) * rr, math.sin(k / segs * TAU) * rr, dz)))
                           for k in range(segs)]
    bot, top = ring(r, 0.0), ring(r_top, h)
    for k in range(segs):
        j = (k + 1) % segs
        bm.faces.new((bot[k], bot[j], top[j], top[k]))
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)


def blob(name, look, c, r, squash=1.0, sub=2):
    bm = bm_for(name, look)
    g = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    for v in g["verts"]:
        v.co = Vector((v.co.x, v.co.y, v.co.z * squash)) + P(*c)


# ------------------------------------------------------------------ the cabin
WALL_H = 9.0
ROW_H = 1.5                       # six plank rows
X0, X1, Z0, Z1 = -12.0, 12.0, -3.0, 21.0
T = 0.5                           # wall thickness
GROUND = -1.5                     # the plot's lawn under FirmBuilder's floor (y 0)
OVER_X, OVER_Z = 1.2, 1.0         # roof overhang at the sides / front + back
RIDGE_Y = WALL_H + 5.5
PITCH = math.atan2(RIDGE_Y - WALL_H, X1)
ROOF_T = 0.6


def base_and_floor():
    """A stone base under the cabin and the porch, wide floor boards (two tones) on top (top at y 0.05)."""
    span("Shack_Stone", "stone_block", X0 - 0.5, GROUND - 0.25, Z0 - 0.5, X1 + 0.5, -0.25, Z1 + 0.5)
    span("Shack_Stone", "stone_block", -10.7, GROUND - 0.25, -7.3, 10.7, -0.25, Z0 - 0.5)
    for i in range(12):
        x = X0 + 1.0 + i * 2.0
        name, look = ("Shack_FloorBoards", "floor") if i % 2 == 0 else ("Shack_FloorLight", "floor_dark")
        span(name, look, x - 1.0, -0.25, Z0 - T / 2, x + 1.0, 0.05, Z1 + T / 2, bevel=0.06)


def wall(axis, at, a0, a1, openings):
    """A straight wall of horizontal planks along `axis` ("x": z = at, "z": x = at) from a0 to a1, rows alternating two
    wood tones, cut around openings [(lo, hi, y0, y1)] (in the axis coordinate)."""
    for r in range(int(WALL_H / ROW_H)):
        ya, yb = r * ROW_H + 0.05, (r + 1) * ROW_H + 0.05
        look = "plank_light" if r % 2 == 0 else "plank_dark"
        name = "Shack_PlankLight" if r % 2 == 0 else "Shack_PlankDark"
        cuts = sorted({a0, a1} | {v for lo, hi, oy0, oy1 in openings if oy0 < yb and oy1 > ya for v in (lo, hi)})
        for u0, u1 in zip(cuts, cuts[1:]):
            mid = (u0 + u1) / 2
            pieces = [(ya, yb)]
            for lo, hi, oy0, oy1 in openings:
                if lo <= mid <= hi:
                    pieces = [(a, b) for a, b in ((ya, max(ya, min(yb, oy0))), (max(ya, min(yb, oy1)), yb)) if b - a > 0.05]
            for a, b in pieces:
                if axis == "x":
                    span(name, look, u0, a, at - T / 2, u1, b, at + T / 2, bevel=0.08)
                else:
                    span(name, look, at - T / 2, a, u0, at + T / 2, b, u1, bevel=0.08)


def walls():
    e = 0.55  # the planks stop at the corner posts
    win = 1.75
    wall("x", Z0, X0 + e, X1 - e, [(-3, 3, 0, 7.55), (-7.5 - win, -7.5 + win, 3.05, 6.05), (7.5 - win, 7.5 + win, 3.05, 6.05)])
    wall("x", Z1, X0 + e, X1 - e, [(-3, 3, 0, 7.55)])
    for x in (X0, X1):
        wall("z", x, Z0 + e, Z1 - e, [(-0.2, 3.2, 0, 7.55), (13.75 - win, 13.75 + win, 3.05, 6.05)])
    for x in (X0, X1):  # chunky corner posts
        for z in (Z0, Z1):
            span("Shack_Post", "post_wood", x - 0.55, 0.05, z - 0.55, x + 0.55, WALL_H, z + 0.55, bevel=0.1)
    # door frames (front, the two side doorways, the aisle at the back): cream, proud of both faces
    for z in (Z0, Z1):
        for x0, x1 in ((-3.5, -2.9), (2.9, 3.5)):  # (0.1 over the plank ends: no flush faces)
            span("Shack_DoorFrame", "trim_cream", x0, 0.0, z - 0.35, x1, 7.55, z + 0.35)  # (feet in the floor)
        span("Shack_DoorFrame", "trim_cream", -3.5, 7.45, z - 0.35, 3.5, 8.05, z + 0.35)
    for x in (X0, X1):
        for z0, z1 in ((-0.7, -0.1), (3.1, 3.7)):
            span("Shack_DoorFrame", "trim_cream", x - 0.35, 0.0, z0, x + 0.35, 7.55, z1)
        span("Shack_DoorFrame", "trim_cream", x - 0.35, 7.45, -0.7, x + 0.35, 8.05, 3.7)


def window(axis, at, c, out):
    """A cream-framed 3.5 x 3 window (y 3.05 .. 6.05) in the wall `axis`/`at` centred on c, with a cross mullion and a sill;
    out = the outside's sign (a flower box hangs there on the front windows)."""
    w, y0, y1, f = 1.75, 3.05, 6.05, 0.4
    def s(lo, ylo, dlo, hi, yhi, dhi, name, look):
        if axis == "x":
            span(name, look, lo, ylo, at + dlo, hi, yhi, at + dhi)
        else:
            span(name, look, at + dlo, ylo, lo, at + dhi, yhi, hi)
    d = 0.35
    s(c - w - f, y0 - f, -d, c + w + f, y0 + 0.1, d, "Shack_Trim", "trim_cream")    # bottom (each 0.1 over the cut planks)
    s(c - w - f, y1 - 0.1, -d, c + w + f, y1 + f, d, "Shack_Trim", "trim_cream")    # top
    s(c - w - f, y0, -d, c - w + 0.1, y1, d, "Shack_Trim", "trim_cream")            # sides
    s(c + w - 0.1, y0, -d, c + w + f, y1, d, "Shack_Trim", "trim_cream")
    s(c - w, y0, -0.05, c + w, y1, 0.05, "Shack_Glass", "glass")                   # the pane, in the wall's middle
    s(c - 0.1, y0, -0.2, c + 0.1, y1, 0.2, "Shack_Trim", "trim_cream")             # cross mullion
    s(c - w, (y0 + y1) / 2 - 0.1, -0.2, c - 0.1, (y0 + y1) / 2 + 0.1, 0.2, "Shack_Trim", "trim_cream")
    s(c + 0.1, (y0 + y1) / 2 - 0.1, -0.2, c + w, (y0 + y1) / 2 + 0.1, 0.2, "Shack_Trim", "trim_cream")
    lo, hi = sorted((out * d, out * (d + 0.5)))
    s(c - w - 0.6, y0 - f - 0.25, lo, c + w + 0.6, y0 - f, hi, "Shack_Trim", "trim_cream")  # sill
    return w


def flower_box(cx, z):
    """A wood box under a front window (outside = -z), one solid green bush in it and a few flowers."""
    span("Shack_Crate", "crate", cx - 2.0, 1.6, z - 1.0, cx + 2.0, 2.4, z, bevel=0.08)
    blob("Shack_Bush", "leaf", (cx, 2.45, z - 0.5), 1.0, squash=0.5)
    blob("Shack_Bush", "leaf", (cx - 1.1, 2.4, z - 0.5), 0.75, squash=0.55)
    blob("Shack_Bush", "leaf", (cx + 1.1, 2.4, z - 0.5), 0.75, squash=0.55)
    for k, dx in enumerate((-1.3, -0.4, 0.5, 1.4)):
        blob("Shack_FlowerRed" if k % 2 == 0 else "Shack_FlowerYellow", "flower_red" if k % 2 == 0 else "flower_yellow",
             (cx + dx, 2.85 - 0.1 * (k % 2), z - 0.55 - 0.15 * (k % 2)), 0.26, sub=1)


def roof_y(x):
    """The roof's underside over firm x (the slab's bottom line runs from the ridge to the wall tops)."""
    return RIDGE_Y - math.tan(PITCH) * abs(x)


def roof():
    """A front-gable roof: each side four big shingle rows (two reds), a cream ridge cap and bargeboards, plank gables,
    one wood patch, a square stone chimney."""
    zs, ze = Z0 - OVER_Z, Z1 + OVER_Z
    x_end = X1 + OVER_X
    L = (x_end + 0.3) / math.cos(PITCH)                # from just past the ridge to the eave
    rows = 4
    dirv = Vector((math.cos(PITCH), -math.sin(PITCH)))  # (x, y) down the right-hand slope
    nrm = Vector((math.sin(PITCH), math.cos(PITCH)))   # its outward normal
    start = Vector((-0.3, RIDGE_Y + math.tan(PITCH) * 0.3))
    for side in (-1, 1):
        for r in range(rows):
            c = start + dirv * ((r + 0.5) * L / rows) + nrm * (ROOF_T / 2)
            look, name = ("shingle", "Shack_Shingle") if r % 2 == 0 else ("shingle_dark", "Shack_ShingleDark")
            box(name, look, (side * c.x, c.y, (zs + ze) / 2), (L / rows, ROOF_T, ze - zs),
                rot=(0, 0, side * math.degrees(PITCH)), bevel=0.12)
        for z in (zs - 0.2, ze + 0.2):  # bargeboards on the gable edges
            c = start + dirv * (L / 2) + nrm * (ROOF_T / 2 + 0.05)
            box("Shack_Trim", "trim_cream", (side * c.x, c.y, z), (L, ROOF_T + 0.3, 0.4), rot=(0, 0, side * math.degrees(PITCH)),
                bevel=0.06)
        # the eave board under the bottom row
        c = start + dirv * (L - 0.2) + nrm * (ROOF_T / 2)
        box("Shack_Trim", "trim_cream", (side * c.x, c.y - 0.2, (zs + ze) / 2), (0.5, ROOF_T + 0.2, ze - zs + 0.8),
            rot=(0, 0, side * math.degrees(PITCH)), bevel=0.06)
    span("Shack_Trim", "trim_cream", -0.7, RIDGE_Y + ROOF_T * 0.6, zs - 0.4, 0.7, RIDGE_Y + ROOF_T + 0.75, ze + 0.4, bevel=0.1)
    # gables: plank triangles front and back, sitting under the slabs on the wall tops
    for z in (Z0, Z1):
        for k, (ya, yb) in enumerate(((WALL_H, WALL_H + 2.0), (WALL_H + 2.0, WALL_H + 4.0), (WALL_H + 4.0, RIDGE_Y))):
            name, look = ("Shack_PlankDark", "plank_dark") if k % 2 == 0 else ("Shack_PlankLight", "plank_light")
            bm = bm_for(name, look)
            half = lambda y: max(0.02, (RIDGE_Y - y) / math.tan(PITCH))
            pts = [(-half(ya), ya), (half(ya), ya), (half(yb), yb), (-half(yb), yb)]
            f = [bm.verts.new(P(x, y, z - T / 2)) for x, y in pts]
            b = [bm.verts.new(P(x, y, z + T / 2)) for x, y in pts]
            bm.faces.new(list(reversed(f)))
            bm.faces.new(b)
            for i in range(4):
                j = (i + 1) % 4
                bm.faces.new((f[i], f[j], b[j], b[i]))
    # the one humble touch: a square wood patch nailed on the left slope
    c = start + dirv * (L * 0.45) + nrm * (ROOF_T + 0.08)
    box("Shack_Patch", "plank_light", (-c.x, c.y, 6.0), (3.0, 0.16, 3.0), rot=(0, 0, -math.degrees(PITCH)), bevel=0.04)
    # a square stone chimney through the right slope, with a darker cap
    cx, cz = 6.5, 15.0
    top = roof_y(cx - 0.8) + ROOF_T / math.cos(PITCH) + 2.2
    span("Shack_Chimney", "stone_block", cx - 0.8, roof_y(cx - 0.8) - 0.1, cz - 0.8,  # (bottom inside the slab: not seen indoors)
          cx + 0.8, top, cz + 0.8, bevel=0.08)
    span("Shack_ChimneyCap", "stone_dark", cx - 1.05, top, cz - 1.05, cx + 1.05, top + 0.45, cz + 1.05, bevel=0.08)


def porch():
    """The porch: wide boards on the stone base, two steps down to the lawn, a low railing either side of the steps, a red
    welcome mat and a lantern by the door."""
    for i in range(14):
        x = -10.5 + i * 1.5 + 0.75
        name, look = ("Shack_PorchBoards", "plank_dark") if i % 2 == 0 else ("Shack_PorchLight", "plank_light")
        span(name, look, x - 0.75, -0.25, -7.5, x + 0.75, 0.05, Z0 - T / 2, bevel=0.06)
    span("Shack_Steps", "plank_light", -3.5, GROUND, -8.3, 3.5, -0.45, -7.5, bevel=0.06)
    span("Shack_Steps", "plank_dark", -3.5, GROUND, -9.1, 3.5, -0.95, -8.3, bevel=0.06)
    for s in (-1, 1):  # posts + rails (front run from the steps to the corner, side run back to the wall)
        for x, z in ((s * 4.2, -7.1), (s * 10.2, -7.1)):
            span("Shack_Rail", "post_wood", x - 0.3, 0.05, z - 0.3, x + 0.3, 3.2, z + 0.3, bevel=0.06)
        for y in (1.4, 2.7):
            span("Shack_Rail", "post_wood", min(s * 4.2, s * 10.2), y, -7.28, max(s * 4.2, s * 10.2), y + 0.36, -6.92)
            span("Shack_Rail", "post_wood", s * 10.2 - 0.18, y, -7.1, s * 10.2 + 0.18, y + 0.36, Z0 - T / 2)
    span("Shack_Mat", "mat_red", -1.6, 0.05, -5.0, 1.6, 0.11, -3.5)
    # the lantern on a bracket, left of the door (it gets the shack's PointLight in the game)
    span("Shack_Iron", "iron", 4.15, 6.7, -4.1, 4.45, 6.95, Z0 - T / 2)
    span("Shack_Iron", "iron", 4.0, 6.45, -4.35, 4.6, 6.7, -3.75)
    span("Shack_Lantern", "lantern", 4.02, 5.55, -4.33, 4.58, 6.45, -3.77)
    span("Shack_Iron", "iron", 3.95, 5.35, -4.4, 4.65, 5.55, -3.7)


def props():
    """A crate stack, a barrel and two flower pots by the steps - kept off the walk-in route (|x| < 4 in front)."""
    span("Shack_Crate", "crate", 9.9, GROUND, -11.1, 11.7, GROUND + 1.8, -9.3, bevel=0.1)
    box("Shack_Crate", "crate", (10.7, GROUND + 1.8 + 0.6, -10.2), (1.2, 1.2, 1.2), rot=(0, 18, 0), bevel=0.08)
    cyl("Shack_Barrel", "barrel", (-10.6, GROUND, -9.8), 0.85, 1.9, segs=16)
    for y in (GROUND + 0.35, GROUND + 1.4):
        cyl("Shack_Iron", "iron", (-10.6, y, -9.8), 0.88, 0.16, segs=16)
    for s in (-1, 1):
        x, z = s * 4.7, -8.8
        cyl("Shack_Pot", "pot", (x, GROUND, z), 0.55, 0.9, segs=14, r_top=0.72)
        blob("Shack_Bush", "leaf", (x, GROUND + 1.25, z), 0.8, squash=0.85)
        blob("Shack_FlowerRed" if s < 0 else "Shack_FlowerYellow", "flower_red" if s < 0 else "flower_yellow",
             (x + 0.25, GROUND + 1.85, z - 0.35), 0.28, sub=1)


def player(x, z):
    for (cx, cy, cz, sx, sy, sz) in ((0, 4.4, 0, 1.0, 1.0, 1.0), (0, 2.9, 0, 2.0, 2.0, 1.0), (-1.5, 2.9, 0, 1.0, 2.0, 1.0),
                                      (1.5, 2.9, 0, 1.0, 2.0, 1.0), (-0.5, 0.95, 0, 1.0, 1.9, 1.0), (0.5, 0.95, 0, 1.0, 1.9, 1.0)):
        box("Preview_Player", "avatar", (x + cx, cy - 1.5, z + cz), (sx, sy, sz))


ROUND = ("Shack_Barrel", "Shack_Bush", "Shack_FlowerRed", "Shack_FlowerYellow", "Shack_Pot")


def build_meshes(preview=True):
    """Makes the cabin's mesh objects (one per name) in the current scene; returns them (previews left out)."""
    BMS.clear()
    base_and_floor(); walls(); roof(); porch(); props()
    window("x", Z0, -7.5, -1); window("x", Z0, 7.5, -1)
    window("z", X0, 13.75, -1); window("z", X1, 13.75, 1)
    flower_box(-7.5, Z0 - T / 2 - 0.35); flower_box(7.5, Z0 - T / 2 - 0.35)
    if preview:
        player(-2.0, -15.0)
        box("Preview_Ground", "grass", (0, GROUND - 0.1, 9), (90, 0.2, 90))
        box("Preview_Path", "path", (0, GROUND + 0.02, -16), (8, 0.06, 14))
    sc = bpy.context.scene
    out = []
    for name, (bm, look) in BMS.items():
        me = bpy.data.meshes.new(name)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        me.materials.append(mat(look))
        for p in me.polygons:
            p.use_smooth = name in ROUND
        ob = bpy.data.objects.new(name, me)
        sc.collection.objects.link(ob)
        if not name.startswith("Preview"):
            out.append(ob)
    BMS.clear()
    return out


def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    sc = bpy.context.scene
    K.sky_and_sun(sc, sun_energy=3.8, sun_rot=(52, 8, -32))
    sc.collection.objects.link(bpy.data.objects["Sun"])
    build_meshes()
    return sc


def stats():
    tot, lo, hi = 0, [1e9] * 3, [-1e9] * 3
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            tot += sum(len(p.vertices) - 2 for p in ob.data.polygons)
            for v in ob.data.vertices:
                p = ob.matrix_world @ v.co
                lo = [min(lo[k], p[k]) for k in range(3)]
                hi = [max(hi[k], p[k]) for k in range(3)]
    print("TOTAL tris", tot, "meshes", sum(1 for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Preview")))
    print("BOUNDS (Blender) min %.2f %.2f %.2f  max %.2f %.2f %.2f" % (*lo, *hi))


def render(sc, name, loc, look, lens=30):
    import gagstuds
    gagstuds.apply_all()  # (Grow a Garden studs on every face)
    sc.camera = K.camera(name, loc, look, lens=lens)
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.render.filepath = os.path.join(OUT, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


def check():
    import ohkit as O
    sys.argv = [sys.argv[0], "--", OUT]
    import check_models as CM
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    objs = build_meshes(preview=False)
    bad = O.check_attached(objs, ground=GROUND, label="shack", grounds=(0.05,))
    zf = O.check_zfight(objs, label="shack", ground=GROUND)
    cl = CM.clips(objs)
    for b in bad:
        print("[check] FLOATING", b[0], b[1], b[2])
    for b in zf:
        print("[check] ZFIGHT", b[0], "/", b[1], "at", b[2], "overlap", b[3])
    for b in cl:
        print("[check] CLIP", b)
    print(f"[check] shack: {len(bad)} floating, {len(zf)} z-fighting, {len(cl)} clipping")


sc = build()
if CHECK:
    check()
else:
    K.setup_eevee(sc, samples=48)
    stats()
    # (Blender coords: X = firm x, Y = firm z, Z = firm y)
    render(sc, "shack_front", (-14, -40, 7), (0, 4, 4), lens=30)
    render(sc, "shack_three_quarter", (32, -32, 16), (0, 6, 3), lens=30)
    render(sc, "shack_close", (-6, -17, 3.5), (1, -3, 4.5), lens=26)
    render(sc, "shack_inside", (0, -6, 4.5), (0, 14, 3), lens=24)
if FBX:
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "DingyShack.fbx"), use_selection=True, apply_unit_scale=True,
                             axis_forward="-Z", axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE")
