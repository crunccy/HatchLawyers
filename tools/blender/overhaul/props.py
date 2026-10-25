# tools/blender/overhaul/props.py - MAP MODEL OVERHAUL stage 2: the PROP KIT (crnuch's calls 2026-10-24, CLAUDE.md
# "MODEL OVERHAUL"). The street furniture, greenery, signs and legal cargo every area of the map reuses, remade as smooth
# meshes in the approved benchmark style (trees / portal / shack): chunky toy shapes, chamfered edges, round posts with
# turned profiles, one mesh per colour (<Prop>_<Part>), foliage = ONE green lumpy surface (crnuch: not two-tone), NO studs on small props
# (studs only on broad structural tops - docs/ART_STYLE_STUDS.md + "Studs stay LOW"). Sign text is preview only: in the
# game it is a SurfaceGui in the game's fonts on the board.
#   Blender -b --factory-startup --python tools/blender/overhaul/props.py -- <out_dir>
# Renders: three line-ups (street furniture / greenery / signs + legal cargo, each with a 5-stud player), a plaza scene
# with everything in use, and today's kit props beside the new ones.
import bpy, math, os, sys, random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
from ohkit import at, box, cyl, lathe, sphere, tube, arc, prism, poly, text, studs_rect, star, leafy, flowers_on, rock, tuft
import trees as T

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rng = random.Random(7)


# ================================================================== street furniture
def lantern(n, c, s=1.0):
    """A four-sided lantern (iron frame, glowing panes wider at the top, pyramid hood, gold finial); c = its foot."""
    x, y, z = c
    cyl(n + "_Iron", "iron", (x, y, z), 0.72 * s, 0.16 * s, segs=4, spin=45, smooth=False)
    cyl(n + "_Glow", "lamp_glow", (x, y, z + 0.16 * s), 0.6 * s, 1.25 * s, segs=4, spin=45, r_top=0.82 * s, smooth=False)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        ca, sa = math.cos(a), math.sin(a)
        tube(n + "_Iron", "iron", [(x + ca * 0.64 * s, y + sa * 0.64 * s, z + 0.14 * s), (x + ca * 0.86 * s, y + sa * 0.86 * s, z + 1.43 * s)],
             0.07 * s, segs=6)
        b = math.radians(90 * k)
        cb, sb = math.cos(b), math.sin(b)
        tube(n + "_Iron", "iron", [(x + cb * 0.44 * s, y + sb * 0.44 * s, z + 0.16 * s), (x + cb * 0.6 * s, y + sb * 0.6 * s, z + 1.41 * s)],
             0.045 * s, segs=5)
    cyl(n + "_Iron", "iron", (x, y, z + 1.41 * s), 0.95 * s, 0.12 * s, segs=4, spin=45, smooth=False)
    cyl(n + "_Iron", "iron", (x, y, z + 1.53 * s), 1.05 * s, 0.66 * s, segs=4, spin=45, r_top=0.2 * s, smooth=False)
    cyl(n + "_Iron", "iron", (x, y, z + 2.17 * s), 0.17 * s, 0.18 * s, segs=8)
    sphere(n + "_Gold", "gold", (x, y, z + 2.5 * s), 0.19 * s, sub=1)
    cyl(n + "_Gold", "gold", (x, y, z + 2.66 * s), 0.07 * s, 0.32 * s, segs=6, r_top=0.0)


def lamp_base(n, r=1.0):
    cyl(n + "_Iron", "iron", (0, 0, 0), 0.98 * r, 0.42, segs=8, smooth=False)
    cyl(n + "_Iron", "iron", (0, 0, 0.42), 0.8 * r, 0.46, segs=8, r_top=0.6 * r, smooth=False)


def lamp():
    """Street lamp, 11 studs: octagon plinth, turned post with gold rings, scroll brackets, the lantern."""
    n = "Lamp"
    lamp_base(n)
    lathe(n + "_Iron", "iron", [(0.52, 0.86, True), (0.42, 1.05), (0.31, 1.32), (0.27, 1.6), (0.24, 7.3), (0.28, 7.55),
                                (0.36, 7.7, True), (0.36, 7.9, True), (0.22, 8.05), (0.2, 8.4)], segs=12)
    cyl(n + "_Gold", "gold", (0, 0, 1.5), 0.34, 0.14, segs=12)
    cyl(n + "_Gold", "gold", (0, 0, 7.36), 0.31, 0.12, segs=12)
    for k in range(4):  # little scrolls holding the lantern
        a = math.radians(45 + 90 * k)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(0.2, 7.95), (0.42, 7.98), (0.58, 8.14), (0.62, 8.36)]
        tube(n + "_Iron", "iron", [(ca * r, sa * r, z) for r, z in pts], 0.055, segs=5)
    lantern(n, (0, 0, 8.38))


def lamp_double():
    """Double lamp, 12.5 studs: two scroll arms with hanging lanterns + a purple and gold banner."""
    n = "LampDouble"
    lamp_base(n, 1.12)
    lathe(n + "_Iron", "iron", [(0.56, 0.86, True), (0.45, 1.05), (0.33, 1.35), (0.29, 1.6), (0.26, 10.0), (0.32, 10.25),
                                (0.4, 10.4, True), (0.4, 10.6, True), (0.26, 10.75), (0.18, 11.0), (0.0, 11.05)], segs=12)
    cyl(n + "_Gold", "gold", (0, 0, 1.5), 0.36, 0.14, segs=12)
    cyl(n + "_Gold", "gold", (0, 0, 9.0), 0.33, 0.12, segs=12)
    sphere(n + "_Gold", "gold", (0, 0, 11.3), 0.3, sub=2)
    cyl(n + "_Gold", "gold", (0, 0, 11.55), 0.09, 0.45, segs=6, r_top=0.0)
    for s in (-1, 1):
        tube(n + "_Iron", "iron", [(s * 0.2, 0, 10.05), (s * 0.7, 0, 10.42), (s * 1.3, 0, 10.55), (s * 1.85, 0, 10.42),
                                   (s * 2.1, 0, 10.12)], 0.11, segs=8)
        tube(n + "_Iron", "iron", [(s * 0.22, 0, 9.2), (s * 0.55, 0, 9.32), (s * 0.85, 0, 9.62), (s * 1.02, 0, 10.0),
                                   (s * 1.08, 0, 10.45)], 0.075, segs=6)
        spiral = [(s * (0.62 + 0.24 * (1 - t / 9 * 0.55) * math.cos(t / 9 * 5.2 + 3.4)), 0,
                   9.72 + 0.24 * (1 - t / 9 * 0.55) * math.sin(t / 9 * 5.2 + 3.4)) for t in range(10)]
        tube(n + "_Gold", "gold", spiral, 0.05, segs=5)
        tube(n + "_Iron", "iron", [(s * 2.1, 0, 10.12), (s * 2.1, 0, 9.82)], 0.05, segs=5)
        lantern(n, (s * 2.1, 0, 7.62), 0.85)
    # banner: two gold rods off the post, a swallow-tailed purple cloth with a gold edge and a gold coin emblem
    for z in (6.9, 3.95):
        tube(n + "_Gold", "gold", [(0.2, -0.0, z), (1.75, 0, z)], 0.06, segs=6)
        sphere(n + "_Gold", "gold", (1.8, 0, z), 0.1, sub=1)
    edge = [(0.25, 3.35), (1.0, 3.8), (1.75, 3.35), (1.75, 6.9), (0.25, 6.9)]
    prism(n + "_Gold", "gold_dark", edge, 0.08)
    prism(n + "_Banner", "banner_purple", [(0.33, 3.53), (1.0, 3.93), (1.67, 3.53), (1.67, 6.83), (0.33, 6.83)], 0.14)
    cyl(n + "_Gold", "gold", (1.0, -0.07, 5.45), 0.42, 0.06, segs=16, rot=(90, 0, 0))
    cyl(n + "_Gold", "gold", (1.0, 0.07, 5.45), 0.42, 0.06, segs=16, rot=(-90, 0, 0))


def bench():
    """Park bench, 6 wide: four seat slats + three back slats on curly iron ends with armrests."""
    n = "Bench"
    for sx in (-2.55, 2.55):
        tube(n + "_Iron", "iron", [(sx, -0.78, 0.06), (sx, -0.74, 0.9), (sx, -0.7, 1.4), (sx, -0.45, 1.5), (sx, 0.45, 1.5),
                                   (sx, 0.7, 1.4), (sx, 0.8, 0.8), (sx, 0.88, 0.06)], 0.11, segs=8)
        tube(n + "_Iron", "iron", [(sx, 0.62, 1.48), (sx, 0.8, 2.2), (sx, 0.96, 2.9), (sx, 1.06, 3.3), (sx, 1.0, 3.5),
                                   (sx, 0.86, 3.52), (sx, 0.8, 3.4)], 0.1, segs=8)
        tube(n + "_Iron", "iron", [(sx, -0.72, 1.5), (sx, -0.86, 1.88), (sx, -0.8, 2.24), (sx, -0.55, 2.4), (sx, 0.2, 2.46),
                                   (sx, 0.72, 2.55)], 0.1, segs=8)
        tube(n + "_Iron", "iron", [(sx, -1.0 + 0.16 * math.cos(math.radians(a)), 1.95 + 0.16 * math.sin(math.radians(a)))
                                   for a in range(0, 340, 40)], 0.06, segs=5)
        for y in (-0.78, 0.88):
            box(n + "_Iron", "iron", (sx, y, 0.05), (0.42, 0.52, 0.1), bevel=0.03)
    box(n + "_Iron", "iron", (0, 0, 1.52), (0.16, 1.3, 0.12), bevel=0.03)
    for y in (-0.6, -0.2, 0.2, 0.6):
        box(n + "_Wood", "wood_warm", (0, y, 1.67), (5.9, 0.36, 0.15), bevel=0.05)
    lean = math.radians(13.4)
    for z in (2.15, 2.6, 3.05):
        y = 0.62 + (z - 1.45) * math.tan(lean) - 0.14
        box(n + "_Wood", "wood_warm", (0, y, z), (5.9, 0.13, 0.36), rot=(-13.4, 0, 0), bevel=0.05)


def bin_():
    """Litter bin: ribbed green barrel, dark rim + domed lid with a push flap."""
    n = "Bin"
    cyl(n + "_Dark", "bin_dark", (0, 0, 0), 0.76, 0.2, segs=16)
    lathe(n + "_Green", "bin_green", [(0.7, 0.2, True), (0.74, 0.3), (0.82, 1.82, True), (0.0, 1.82)], segs=16)
    lathe(n + "_Dark", "bin_dark", [(0.84, 1.78, True), (0.9, 1.84), (0.92, 1.98), (0.88, 2.04, True), (0.8, 2.22), (0.6, 2.4),
                                    (0.32, 2.5), (0.0, 2.53)], segs=16)
    for k in range(8):
        a = (k + 0.5) / 8 * math.tau
        ca, sa = math.cos(a), math.sin(a)
        tube(n + "_Dark", "bin_dark", [(ca * 0.745, sa * 0.745, 0.32), (ca * 0.83, sa * 0.83, 1.72)], 0.055, segs=5)
    box(n + "_Dark", "iron", (0, -0.62, 2.28), (0.7, 0.12, 0.2), rot=(32, 0, 0), bevel=0.04)


def bollard():
    n = "Bollard"
    lathe(n + "_Iron", "iron", [(0.42, 0.0), (0.42, 0.18, True), (0.33, 0.28), (0.29, 0.5), (0.27, 1.55), (0.33, 1.62, True),
                                (0.33, 1.76, True), (0.26, 1.83), (0.21, 1.96), (0.11, 2.05), (0.0, 2.08)], segs=12)
    cyl(n + "_Gold", "gold", (0, 0, 1.28), 0.31, 0.12, segs=12)
    sphere(n + "_Gold", "gold", (0, 0, 2.12), 0.1, sub=1)


def hydrant():
    n = "Hydrant"
    lathe(n + "_Red", "hydrant_red", [(0.62, 0.0), (0.62, 0.16, True), (0.46, 0.24, True), (0.42, 0.3), (0.4, 1.5),
                                      (0.5, 1.55, True), (0.5, 1.7, True), (0.4, 1.76), (0.36, 1.95), (0.22, 2.1), (0.0, 2.14)], segs=14)
    for s in (-1, 1):
        cyl(n + "_Red", "hydrant_red", (s * 0.3, 0, 1.08), 0.16, 0.5, segs=10, rot=(0, s * 90, 0))
        cyl(n + "_Gold", "gold", (s * 0.8, 0, 1.08), 0.13, 0.1, segs=6, rot=(0, s * 90, 0), smooth=False)
    cyl(n + "_Red", "hydrant_red", (0, -0.3, 0.95), 0.23, 0.42, segs=12, rot=(90, 0, 0))
    cyl(n + "_Gold", "gold", (0, -0.72, 0.95), 0.18, 0.12, segs=6, rot=(90, 0, 0), smooth=False)
    cyl(n + "_Gold", "gold", (0, 0, 2.1), 0.12, 0.18, segs=5, smooth=False)
    for k in range(6):  # flange bolts
        a = k / 6 * math.tau
        sphere(n + "_Gold", "gold", (math.cos(a) * 0.46, math.sin(a) * 0.46, 1.71), 0.05, sub=1)


def chair():
    """Café chair at the origin, back toward +Y."""
    n = "CafeTable"
    cyl(n + "_Seat", "parasol_red", (0, 0, 1.36), 0.62, 0.14, segs=16)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        tube(n + "_Iron", "iron", [(math.cos(a) * 0.42, math.sin(a) * 0.42, 1.38), (math.cos(a) * 0.58, math.sin(a) * 0.58, 0.04)],
             0.05, segs=5)
    hoop = [(0.5 * math.cos(math.radians(a)), 0.5, 1.5 + 1.1 * math.sin(math.radians(a))) for a in range(0, 181, 15)]
    tube(n + "_Iron", "iron", hoop, 0.06, segs=6)
    tube(n + "_Iron", "iron", [(0, 0.5, 1.5), (0, 0.5, 2.6)], 0.04, segs=5)
    tube(n + "_Iron", "iron", [(-0.45, 0.5, 2.1), (0.45, 0.5, 2.1)], 0.04, segs=5)


def cafe_table():
    """Round café table, two chairs, red and white striped parasol with a scalloped edge."""
    n = "CafeTable"
    cyl(n + "_Iron", "iron", (0, 0, 0), 0.62, 0.1, segs=12, smooth=False)
    lathe(n + "_Iron", "iron", [(0.5, 0.1, True), (0.22, 0.28), (0.12, 0.5), (0.1, 2.0), (0.22, 2.14), (0.34, 2.2)], segs=12)
    cyl(n + "_Top", "white", (0, 0, 2.2), 1.3, 0.14, segs=24)
    for sx in (-1, 1):
        with at(sx * 2.05, 0, rz=-90 * sx):
            chair()
    cyl(n + "_Iron", "iron", (0, 0, 2.34), 0.07, 3.3, segs=8)
    apex, mid_r, mid_z, rim_r, rim_z, g = 5.75, 1.45, 5.28, 2.7, 4.55, 10
    for i in range(g):
        a0, a1 = i / g * math.tau, (i + 1) / g * math.tau
        lk, nm = ("parasol_red", n + "_Red") if i % 2 == 0 else ("white", n + "_White")
        P = lambda r, z, a: (r * math.cos(a), r * math.sin(a), z)
        poly(nm, lk, [P(0, apex, 0), P(mid_r, mid_z, a0), P(mid_r, mid_z, a1)][::-1], thick=0.05)
        poly(nm, lk, [P(mid_r, mid_z, a0), P(rim_r, rim_z, a0), P(rim_r, rim_z, a1), P(mid_r, mid_z, a1)][::-1], thick=0.05)
        am = (a0 + a1) / 2  # scallop flap
        flap = [P(rim_r, rim_z, a0), P(rim_r * 1.0, rim_z - 0.32, a0 + (a1 - a0) * 0.2), P(rim_r * 1.0, rim_z - 0.42, am),
                P(rim_r * 1.0, rim_z - 0.32, a1 - (a1 - a0) * 0.2), P(rim_r, rim_z, a1)]
        poly(n + ("_White" if i % 2 == 0 else "_Red"), "white" if i % 2 == 0 else "parasol_red", flap, thick=0.04)
    sphere(n + "_Gold", "gold", (0, 0, apex + 0.12), 0.18, sub=1)


def railing():
    """Iron railing, 8 long: posts with gold balls, bars, a band of gold rings under the top rail."""
    n = "Railing"
    for x in (-4, 4):
        box(n + "_Iron", "iron", (x, 0, 0.12), (0.55, 0.55, 0.24), bevel=0.05)
        box(n + "_Iron", "iron", (x, 0, 1.4), (0.32, 0.32, 2.4), bevel=0.05)
        cyl(n + "_Iron", "iron", (x, 0, 2.6), 0.26, 0.14, segs=4, spin=45, smooth=False)
        sphere(n + "_Gold", "gold", (x, 0, 2.94), 0.22, sub=2)
    for z in (0.55, 2.0, 2.4):
        tube(n + "_Iron", "iron", [(-3.85, 0, z), (3.85, 0, z)], 0.07 if z != 2.0 else 0.05, segs=6)
    xs = [-3.6 + 0.4 * i for i in range(19)]
    for x in xs:
        cyl(n + "_Iron", "iron", (x, 0, 0.55), 0.05, 1.45, segs=6)
    for x0 in xs[:-1:2]:
        tube(n + "_Gold", "gold", arc(x0 + 0.2, 2.2, 0.13, 0, 360, 10), 0.03, segs=4, cap=False)


def fence():
    """White picket fence, 8 long: capped posts, pointed pickets on two rails."""
    n = "Fence"
    for x in (-4, 0, 4):
        box(n + "_White", "white", (x, 0, 1.4), (0.46, 0.46, 2.8), bevel=0.06)
        cyl(n + "_White", "white", (x, 0, 2.8), 0.4, 0.34, segs=4, spin=45, r_top=0.06, smooth=False)
    for z in (0.75, 1.95):
        box(n + "_White", "white", (0, 0.05, z), (8.0, 0.14, 0.28), bevel=0.04)
    for i in range(-7, 8):
        x = i * 0.53
        if any(abs(x - p) < 0.45 for p in (-4, 0, 4)):
            continue
        prism(n + "_White", "white", [(x - 0.17, 0.12), (x + 0.17, 0.12), (x + 0.17, 2.22), (x, 2.48), (x - 0.17, 2.22)], 0.12,
              c=(0, -0.1, 0))


# ================================================================== greenery
def planter_square():
    n = "PlanterSq"
    box(n + "_Base", "stone_mid", (0, 0, 0.15), (4.3, 4.3, 0.3), bevel=0.08)
    box(n + "_Stone", "stone_light", (0, 0, 0.95), (3.9, 3.9, 1.3), bevel=0.1)
    for k in range(4):
        with at(rz=90 * k):
            box(n + "_Base", "stone_mid", (0, -1.98, 0.95), (2.7, 0.1, 0.72), bevel=0.04)
    for (x, y, sx, sy) in ((0, -1.95, 4.4, 0.5), (0, 1.95, 4.4, 0.5), (-1.95, 0, 0.5, 3.4), (1.95, 0, 0.5, 3.4)):
        box(n + "_Trim", "trim_cream", (x, y, 1.74), (sx, sy, 0.28), bevel=0.07)
    box(n + "_Soil", "soil", (0, 0, 1.7), (3.42, 3.42, 0.2))
    obs = leafy(n + "_Bush", [((0, 0, 2.75), 1.4), ((0.65, 0.45, 2.4), 1.0), ((-0.6, -0.35, 2.45), 1.0), ((0.25, -0.55, 3.3), 0.8),
                              ((-0.3, 0.5, 3.2), 0.8)], voxel=0.22, faces=750, lumpy=0.22, seed=3)
    flowers_on(obs, n + "_Flower", "flower_pink", n + "_FlowerMid", "flower_yel",
               [(1.3 * math.cos(a), 1.3 * math.sin(a), 6) for a in [0.3, 1.2, 2.0, 2.9, 3.9, 4.7, 5.6]] + [(0.2, 0.1, 6)], r=0.24)


def planter_round():
    n = "PlanterRound"
    lathe(n + "_Pot", "terracotta", [(0.86, 0.0), (0.92, 0.04), (0.95, 0.2, True), (1.06, 0.5), (1.3, 1.24, True), (0.0, 1.24)], segs=24)
    lathe(n + "_Rim", "terracotta_dark", [(1.32, 1.2, True), (1.47, 1.28), (1.5, 1.42), (1.47, 1.56), (1.38, 1.6, True), (1.22, 1.6),
                                          (1.18, 1.45, True)], segs=24)
    cyl(n + "_Soil", "soil", (0, 0, 1.24), 1.2, 0.24, segs=20, smooth=False)
    obs = leafy(n + "_Bush", [((0, 0, 2.35), 1.12), ((0.5, 0.3, 2.05), 0.8), ((-0.45, 0.2, 2.1), 0.8), ((0, -0.4, 2.85), 0.7)],
                voxel=0.2, faces=600, lumpy=0.18, seed=5)
    flowers_on(obs, n + "_Flower", "flower_yel", n + "_FlowerMid", "flower_orange",
               [(0.8 * math.cos(a), 0.8 * math.sin(a), 5) for a in [0.1, 1.1, 2.2, 3.1, 4.2, 5.2]] + [(0.1, -0.2, 5)], r=0.22)


def flower_bed():
    """Flower bed 8 x 3: a ring of rounded curb stones, a soil mound, three leafy clumps in flower (red / yellow / purple)."""
    n = "FlowerBed"
    r = random.Random(11)
    hx, hy = 4.0, 1.5

    def run(x0, y0, x1, y1):
        L = math.hypot(x1 - x0, y1 - y0)
        t = 0.0
        while t < L - 0.3:
            ln = min(r.uniform(0.85, 1.25), L - t)
            m = (t + ln / 2) / L
            cx, cy = x0 + (x1 - x0) * m, y0 + (y1 - y0) * m
            ang = math.degrees(math.atan2(y1 - y0, x1 - x0)) + r.uniform(-4, 4)
            lk, nm = ("stone_light", n + "_Stone") if r.random() < 0.6 else ("stone_mid", n + "_Stone2")
            box(nm, lk, (cx, cy, 0.22), (ln - 0.08, 0.6, r.uniform(0.4, 0.52)), rot=(0, 0, ang), bevel=0.16, segs=2, smooth=True)
            t += ln

    run(-hx - 0.3, -hy, hx + 0.3, -hy)
    run(hx, -hy + 0.3, hx, hy - 0.3)
    run(hx + 0.3, hy, -hx - 0.3, hy)
    run(-hx, hy - 0.3, -hx, -hy + 0.3)
    box(n + "_Soil", "soil", (0, 0, 0.18), (7.5, 2.55, 0.42), bevel=0.15, segs=2, smooth=True)
    for gi, (x0, look, mid) in enumerate(((-2.45, "flower_red", "flower_yel"), (0.0, "flower_yel", "flower_orange"),
                                          (2.45, "flower_purple", "flower_yel"))):
        blobs = [((x0 + dx, dy, 0.62), rr) for dx, dy, rr in ((-0.6, -0.3, 0.72), (0.55, 0.25, 0.72), (0.0, 0.0, 0.8), (0.7, -0.45, 0.55),
                                                             (-0.65, 0.45, 0.55))]
        obs = leafy(n + "_Leaves%d" % gi, blobs, voxel=0.18, faces=420, lumpy=0.14, seed=20 + gi)
        pts = [(x0 + r.uniform(-1.05, 1.05), r.uniform(-0.75, 0.75), 4) for _ in range(9)]
        flowers_on(obs, n + "_Flower" + look.split("_")[1].title(), look, n + "_FlowerMid" + mid.split("_")[1].title(), mid, pts, r=0.24)


def hedge():
    """Clipped hedge 8 x 2.4 x 2.6 on a low wooden edging."""
    n = "Hedge"
    blobs = [((x, y, z), 0.86) for x in [-3.4 + 0.85 * i for i in range(9)] for y in (-0.42, 0.42) for z in (0.7, 1.6)]
    leafy(n + "_Hedge", blobs, look="hedge", voxel=0.28, faces=1100, lumpy=0.16, seed=9)
    for (x, y, sx, sy) in ((0, -1.42, 9.0, 0.26), (0, 1.42, 9.0, 0.26), (-4.37, 0, 0.26, 2.58), (4.37, 0, 0.26, 2.58)):
        box(n + "_Edge", "wood_deep", (x, y, 0.2), (sx, sy, 0.4), bevel=0.05)


def rocks():
    """A boulder cluster with mossy and pale tops and grass tufts."""
    n = "Rocks"
    rock(n + "_Rock", n + "_Moss", (0, 0, 0.15), 1.7, seed=1, top="moss")
    rock(n + "_Rock", n + "_Top", (1.9, 0.9, 0.1), 1.05, seed=2)
    rock(n + "_Rock", n + "_Top", (-1.6, -1.0, 0.06), 0.75, seed=3)
    rock(n + "_Rock", n + "_Top", (0.9, -1.7, 0.03), 0.42, seed=4)
    rock(n + "_Rock", n + "_Top", (-2.3, 0.6, 0.03), 0.36, seed=5)
    for i, (x, y) in enumerate(((1.0, -1.1), (-1.0, 1.3), (2.9, 0.2), (-2.6, -0.4), (0.3, 1.8))):
        tuft(n + "_Grass", "leaf_sun", (x, y, 0), h=0.8, blades=6, seed=i)


# ================================================================== signs + legal cargo
def sign_post():
    """Wayfinding post (the game's sign style: brown wood boards, white text): three arrows at different angles."""
    n = "SignPost"
    box(n + "_Post", "wood_deep", (0, 0, 0.15), (0.95, 0.95, 0.3), bevel=0.06)
    box(n + "_Post", "wood_deep", (0, 0, 4.15), (0.55, 0.55, 8.0), bevel=0.08)
    cyl(n + "_Post", "wood_deep", (0, 0, 8.15), 0.52, 0.42, segs=4, spin=45, r_top=0.08, smooth=False)
    sphere(n + "_Gold", "gold", (0, 0, 8.66), 0.17, sub=1)
    for (label, z, ang, d) in (("SHOP", 7.1, 0, 1), ("PORTAL", 5.85, 28, -1), ("ISLANDS", 4.6, -22, 1)):
        with at(rz=ang):
            pts = [(0.25, -0.5), (3.85, -0.5), (4.55, 0.0), (3.85, 0.5), (0.25, 0.5)]
            pts = [(d * x, zz + z) for x, zz in pts]
            pts = pts if d > 0 else pts[::-1]
            fr = [(d * x, zz + z) for x, zz in [(0.12, -0.64), (3.9, -0.64), (4.74, 0.0), (3.9, 0.64), (0.12, 0.64)]]
            prism(n + "_Frame", "wood_deep", fr if d > 0 else fr[::-1], 0.22)
            prism(n + "_Board", "sign_wood", pts, 0.34)
            for k, xx in enumerate((0.75, 3.5)):
                O.sphere(n + "_Post", "iron", (d * xx, -0.19, z), 0.06, sub=1)
            text(label, "white", (d * 2.1, -0.2, z), 0.62, extrude=0.02)
            text(label, "white", (d * 2.1, 0.2, z), 0.62, rot=(90, 0, 180), extrude=0.02)


def notice_board():
    """Case notice board: cork in a wood frame under a little red roof, pinned papers."""
    n = "NoticeBoard"
    r = random.Random(4)
    for x in (-3.5, 3.5):
        box(n + "_Wood", "wood_deep", (x, 0, 2.8), (0.5, 0.5, 5.6), bevel=0.07)
    box(n + "_Wood", "wood_deep", (0, 0, 3.2), (7.0, 0.3, 3.6), bevel=0.05)
    box(n + "_Cork", "board_cork", (0, -0.18, 3.2), (6.3, 0.1, 2.9))
    for (x, z, sx, sz) in ((0, 4.85, 7.3, 0.42), (0, 1.55, 7.3, 0.42), (-3.42, 3.2, 0.42, 2.9), (3.42, 3.2, 0.42, 2.9)):
        box(n + "_Frame", "wood_warm", (x, -0.12, z), (sx, 0.32, sz), bevel=0.06)
    for s in (-1, 1):
        box(n + "_Roof", "red", (s * 2.05, 0, 5.5), (4.55, 1.5, 0.24), rot=(0, s * 15, 0), bevel=0.06)
    prism(n + "_Wood", "wood_deep", [(-3.6, 5.07), (3.6, 5.07), (0.0, 5.95)], 0.3)
    tube(n + "_Wood", "wood_deep", [(0, -0.8, 6.12), (0, 0.8, 6.12)], 0.14, segs=8)
    papers = [(-2.3, 3.6, "paper"), (-0.95, 2.6, "paper_yel"), (-1.0, 3.95, "paper_blue"), (0.5, 3.4, "paper"), (1.85, 3.85, "paper_yel"),
              (2.2, 2.4, "paper"), (0.6, 2.2, "paper_blue"), (-2.4, 2.3, "paper_yel")]
    for x, z, lk in papers:
        w, h, ry = r.uniform(0.95, 1.25), r.uniform(0.95, 1.3), r.uniform(-9, 9)
        box(n + "_" + lk.title().replace("_", ""), lk, (x, -0.245, z), (w, 0.03, h), rot=(0, ry, 0))
        R = O.xform((x, 0, z), (0, ry, 0))
        for i in range(3):  # scribbled lines
            box(n + "_Ink", "iron_light", tuple(R @ Vector((-w * 0.08, -0.265, h * 0.22 - i * h * 0.2))), (w * 0.62, 0.012, 0.06),
                rot=(0, ry, 0))
        sphere(n + "_Pin", "pin_red", tuple(R @ Vector((0, -0.3, h * 0.42))), 0.08, sub=1)
    text("CASE BOARD", "white", (0, -0.3, 4.85), 0.3, extrude=0.015)


def attraction_sign(label="BIG CASES"):
    """Attraction sign (the game's style: black panel, gold text, light bulbs) on two posts, a gold star on top."""
    n = "AttractionSign"
    for x in (-3.25, 3.25):
        box(n + "_Iron", "iron", (x, 0, 0.12), (0.8, 0.8, 0.24), bevel=0.05)
        cyl(n + "_Iron", "iron", (x, 0, 0.24), 0.2, 3.4, segs=10)
    box(n + "_Panel", "panel_black", (0, 0, 4.6), (7.2, 0.42, 2.2), bevel=0.1)
    for (x, z, sx, sz) in ((0, 5.75, 7.6, 0.26), (0, 3.45, 7.6, 0.26), (-3.67, 4.6, 0.26, 2.04), (3.67, 4.6, 0.26, 2.04)):
        box(n + "_Gold", "gold", (x, 0, z), (sx, 0.54, sz), bevel=0.06)
    bulbs = [(x, 5.75) for x in [-3.3 + 0.6 * i for i in range(12)]] + [(x, 3.45) for x in [-3.3 + 0.6 * i for i in range(12)]] + \
            [(s * 3.67, z) for s in (-1, 1) for z in (4.0, 4.6, 5.2)]
    for x, z in bulbs:
        for y in (-0.3, 0.3):
            sphere(n + "_Bulbs", "bulb_glow", (x, y, z), 0.12, sub=1)
    prism(n + "_Gold", "gold", [(x, z + 6.65) for x, z in star(0.85, 0.38)], 0.3, c=(0, 0, -0.1))
    sphere(n + "_Bulbs", "bulb_glow", (0, -0.17, 6.52), 0.14, sub=1)
    size = min(0.86, 6.4 / (0.72 * len(label)))
    text(label, "gold", (0, -0.25, 4.6), size, extrude=0.05)
    text(label, "gold", (0, 0.25, 4.6), size, rot=(90, 0, 180), extrude=0.05)


def gavel_statue():
    """A giant gavel lying on its sound block, on a stone plinth (plinth cap = a broad top: low studs)."""
    n = "Gavel"
    box(n + "_Stone2", "stone_mid", (0, 0, 0.18), (5.0, 5.0, 0.36), bevel=0.08)
    box(n + "_Stone", "stone_light", (0, 0, 1.08), (4.4, 4.4, 1.44), bevel=0.12)
    box(n + "_Stone2", "stone_mid", (0, 0, 1.95), (4.8, 4.8, 0.3), bevel=0.08)
    studs_rect(n + "_Stone2", "stone_mid", -2.4, 2.4, -2.4, 2.4, 2.1, skip=lambda x, y: math.hypot(x, y) < 1.75 or (x > 0.9 and abs(y) < 0.8))
    box(n + "_Gold", "gold", (0, -2.23, 1.05), (2.4, 0.08, 0.8), bevel=0.03)
    text("ORDER!", "panel_black", (0, -2.29, 1.05), 0.5, extrude=0.015)
    cyl(n + "_Block", "wood_deep", (0, 0, 2.1), 1.45, 0.48, segs=28)
    cyl(n + "_Gold", "gold", (0, 0, 2.26), 1.48, 0.12, segs=28)
    head = [(0.0, 0.0), (0.5, 0.0, True), (0.56, 0.06), (0.6, 0.3, True), (0.6, 2.2, True), (0.56, 2.44), (0.5, 2.5, True), (0.0, 2.5)]
    lathe(n + "_Wood", "wood_warm", head, segs=20, c=(0, 1.25, 3.18), rot=(90, 0, 0))
    for y in (0.75, -0.75):
        cyl(n + "_Gold", "gold", (0, y + 0.09, 3.18), 0.63, 0.18, segs=20, rot=(90, 0, 0))
    tube(n + "_Wood", "wood_warm", [(0.4, 0, 3.12), (1.2, 0, 2.88), (1.9, 0, 2.62), (2.3, 0, 2.48)], [0.24, 0.23, 0.22, 0.22], segs=12)
    sphere(n + "_Wood", "wood_warm", (2.42, 0, 2.45), 0.28, sub=2)
    cyl(n + "_Gold", "gold", (0.55, 0, 3.08), 0.27, 0.16, segs=12, rot=(0, 108, 0))


def briefcase(n, lk, band, c, rot):
    with at(*c, rz=rot[2]):
        rx = rot[0]
        box(n + "_" + lk.title().replace("_", ""), lk, (0, 0, 0), (2.6, 0.9, 1.8), rot=(rx, 0, 0), bevel=0.18, segs=2, smooth=False)
        box(n + "_Band", band, (0, 0, 0), (2.64, 0.94, 0.08), rot=(rx, 0, 0), bevel=0.03)
        R = O.xform((0, 0, 0), (rx, 0, 0))
        for sx in (-0.75, 0.75):
            box(n + "_Gold", "gold", tuple(R @ Vector((sx, -0.47, 0.55))), (0.32, 0.1, 0.26), rot=(rx, 0, 0), bevel=0.03)
        for sx in (-0.5, 0.5):
            box(n + "_Gold", "gold", tuple(R @ Vector((sx, 0, 0.93))), (0.18, 0.3, 0.1), rot=(rx, 0, 0), bevel=0.02)
        handle = [tuple(R @ Vector((x, 0, 0.92 + z))) for x, _, z in arc(0, 0, 0.5, 180, 0, 8)]
        handle = [(x * 0.95, y, z) for x, y, z in handle]
        tube(n + "_Handle", "brief_black", [tuple(R @ Vector((-0.5, 0, 0.95)))] + handle[1:-1] + [tuple(R @ Vector((0.5, 0, 0.95)))],
             0.09, segs=6)


def briefcase_stack():
    n = "Briefcases"
    briefcase(n, "brief_brown", "wood_deep", (0, 0, 0.45), (-90, 0, 0))
    briefcase(n, "brief_black", "iron_light", (0.1, 0.15, 1.36), (-90, 0, 14))
    briefcase(n, "brief_brown", "wood_deep", (2.35, -0.2, 0.9), (0, 0, -24))


def file_box(n, c, rz):
    with at(*c, rz=rz):
        box(n + "_Box", "file_box", (0, 0, 0.55), (1.5, 2.1, 1.1), bevel=0.04)
        box(n + "_Lid", "file_lid", (0, 0, 1.15), (1.6, 2.2, 0.3), bevel=0.04)
        for y in (-1.09, 1.09):
            box(n + "_Slot", "iron", (0, y, 0.78), (0.6, 0.06, 0.2), bevel=0.02)
        box(n + "_Label", "paper", (-0.77, 0, 0.6), (0.04, 1.0, 0.5))
        box(n + "_Stripe", "red", (-0.79, 0, 0.6), (0.02, 1.0, 0.1))


def file_boxes():
    n = "FileBoxes"
    file_box(n, (-0.85, 0, 0), 0)
    file_box(n, (0.85, 0.1, 0), 4)
    file_box(n, (0.05, -0.05, 1.3), -9)
    for i, rz in enumerate((-12, 8)):
        box(n + "_Paper", "paper", (0.05 + i * 0.3, 0.2, 2.55), (1.0, 0.03, 0.7), rot=(0, 10 - i * 20, rz))


def crate():
    n = "Crate"
    box(n + "_Planks", "plank_light", (0, 0, 1.1), (2.0, 2.0, 2.0))
    e, h = 0.28, 1.0
    for a in (-1, 1):
        for b in (-1, 1):
            box(n + "_Frame", "wood_deep", (a * h, b * h, 1.1), (e, e, 2.2), bevel=0.04)
            box(n + "_Frame", "wood_deep", (0, a * h, 1.1 + b * h), (2.2, e, e), bevel=0.04)
            box(n + "_Frame", "wood_deep", (a * h, 0, 1.1 + b * h), (e, 2.2, e), bevel=0.04)
    for k in range(4):
        with at(rz=90 * k):
            box(n + "_Frame", "wood_deep", (0, -1.04, 1.1), (2.4, 0.1, 0.24), rot=(0, 45 if k % 2 else -45, 0), bevel=0.03)
            for z in (0.78, 1.42):
                box(n + "_Gap", "plank_dark", (0, -1.005, z), (1.72, 0.02, 0.05))
    for x in (-0.33, 0.33):
        box(n + "_Gap", "plank_dark", (x, 0, 2.105), (0.05, 1.72, 0.02))


# ================================================================== layout + renders
LINEUP = {
    "street": [(lamp, 0), (lamp_double, 0), (bench, 0), (bin_, 0), (bollard, 0), (hydrant, 0), (cafe_table, 0), (railing, 0), (fence, 0)],
    "green": [(planter_square, 0), (planter_round, 0), (flower_bed, 0), (hedge, 0), (rocks, 0)],
    "signs": [(sign_post, 0), (notice_board, 0), (attraction_sign, 0), (gavel_statue, 0), (briefcase_stack, 0), (file_boxes, 0), (crate, 0)],
}
WIDTH = {lamp: 3, lamp_double: 6, bench: 7, bin_: 2.5, bollard: 2, hydrant: 2.5, cafe_table: 7, railing: 9, fence: 9,
         planter_square: 5.5, planter_round: 4, flower_bed: 9.5, hedge: 10, rocks: 7,
         sign_post: 9.5, notice_board: 8.5, attraction_sign: 9, gavel_statue: 7.5, briefcase_stack: 6, file_boxes: 4.5, crate: 3.5}
ROW_Y = {"street": 200, "green": 230, "signs": 260}
POS = {}


def build_lineups():
    for row, items in LINEUP.items():
        with O.region(row):
            x = 0.0
            for fn, rz in items:
                w = WIDTH[fn]
                with at(x + w / 2, ROW_Y[row], rz=rz):
                    fn()
                POS[fn] = (x + w / 2, w)
                x += w + 1.0
            O.player(x + 1.5, ROW_Y[row])
            box("Preview_Ground", "grass_ov", (x / 2, ROW_Y[row] + 20, -0.1), (x + 160, 120, 0.2))


def shoot(name, row, fns, tall=4.0):
    """A line-up shot framing fns (left to right) from the front, a little above."""
    x0 = POS[fns[0]][0] - POS[fns[0]][1] / 2 - 1
    x1 = POS[fns[-1]][0] + POS[fns[-1]][1] / 2 + 1
    span = x1 - x0
    d = max(span * 0.95, tall * 2.6)
    cx = (x0 + x1) / 2
    O.render(OUT, name, (cx, ROW_Y[row] - d, tall * 0.55 + d * 0.22), (cx, ROW_Y[row], tall * 0.5), lens=34, show=[row])


def plaza_scene():
    """Everything in use: a studded plaza with an orange path (white dashed edges), lamps, benches, planters, hedges,
    flower beds, café tables, signs, a gavel statue, cargo by the notice board, rocks + trees on the grass."""
    box("Preview_Ground", "grass_ov", (0, 0, -0.1), (400, 400, 0.2))
    with at(prefix="Scene_"):
        box("Plaza", "plaza", (0, 0, 0.15), (52, 34, 0.3))
        box("PlazaEdge", "plaza_edge", (0, 0, 0.1), (53.2, 35.2, 0.2), bevel=0.06)
        box("Path", "path", (0, 0, 0.16), (52.02, 6.0, 0.3))
        box("Path", "path", (-60, 0, 0.1), (68, 6.0, 0.2))
        for xs in range(-25, 26, 3):
            for y in (-2.6, 2.6):
                box("Dash", "white", (xs, y, 0.32), (1.8, 0.4, 0.04))
        studs_rect("Plaza", "plaza", -26, 26, -17, 17, 0.3, skip=lambda x, y: abs(y) < 3.6)
        studs_rect("Path", "path", -26, 26, -3, 3, 0.31, skip=lambda x, y: abs(abs(y) - 2.6) < 0.45)
        for x in (-18, -6, 6, 18):
            with at(x, 5.2):
                lamp()
            with at(x, -5.2, rz=90):
                lamp_double()
        for x in (-12, 0, 12):
            with at(x, 8.4):
                bench()
            for s in (-1, 1):
                with at(x + s * 4.6, 9.4):
                    planter_round()
        with at(-6, 13.6):
            hedge()
        with at(6, 13.6):
            hedge()
        with at(0, 22.5):
            attraction_sign()
        for x in (-12, 0, 12):
            with at(x, -10.5):
                flower_bed()
        with at(19, -12.5):
            cafe_table()
        with at(23.5, -6.8, rz=40):
            cafe_table()
        with at(-30, -5.5, rz=15):
            sign_post()
        for y in (-2.0, 2.0):
            with at(-26.6, y):
                bollard()
        with at(-20.5, 13.5):
            planter_square()
        with at(-20.5, 22.5):
            gavel_statue()
        with at(17.5, 12.5):
            notice_board()
        with at(22.8, 13.2, rz=10):
            crate()
        with at(13.2, 13.8):
            file_boxes()
        with at(15, 9.3, rz=-14):
            briefcase_stack()
        with at(-8.9, 6.4):
            bin_()
        with at(9.5, -7.4):
            bin_()
        with at(29.5, 4.0):
            hydrant()
        with at(36, -14, rz=30):
            rocks()
        with at(-38, 16, rz=-20):
            rocks()
        for i, x in enumerate((-26.5, -18.5, -10.5)):
            with at(x, -18.4):
                fence()
        for i, x in enumerate((10.5, 18.5, 26.5)):
            with at(x, -18.4):
                railing()
    T.tree_oak(-36, -8, name="SceneOakA", s=0.9, seed=1)
    T.tree_blossom(34, 22, name="SceneBlossomA", s=0.85, seed=4)
    T.tree_oak(40, -2, name="SceneOakB", s=0.75, seed=8)
    T.tree_blossom(-34, 26, name="SceneBlossomB", s=0.8, seed=9)
    O.player(-3.5, -1.0)
    O.player(16.5, -15.5)


def old_kit_row():
    """Today's props, from the kit builder they were made with (environment-redesign/kit/hl_kit.py), beside the new ones."""
    import hl_kit as K
    for lk in ("metal_dark", "black", "glow_warm", "wood", "stone", "stone_warm", "dirt_dark", "leaf", "leaf_light", "leaf_deep",
               "rock", "rock_dark", "pink", "yellow", "red", "purple", "white", "orange"):
        if lk not in K.PAL and lk not in K.GLOWS:
            print("[props] old look missing:", lk)
    m = K.Mesh("Old_Kit", bpy.context.scene.collection)
    y = 600
    K.lamp(m, 0, y)
    K.lamp(m, 6, y, double=True)
    K.bench(m, 14, y)
    K.planter(m, 22, y)
    K.hedge(m, 30, y, 8, 0)
    K.flowerbed(m, 41, y, 8, 3)
    K.rocks(m, 50, y)
    m.done()
    for fn, x in ((lamp, 0), (lamp_double, 6), (bench, 14), (planter_square, 22), (hedge, 30), (flower_bed, 41), (rocks, 50)):
        with at(x + 100, y, prefix="Old2_"):
            fn()
    O.player(-5, y)
    O.player(95, y)
    box("Preview_Ground", "grass_ov", (75, y + 40, -0.1), (400, 200, 0.2))


def main():
    O.reset()
    O.scene()
    build_lineups()
    with O.region("plaza"):
        plaza_scene()
    with O.region("compare"):
        old_kit_row()
    O.stats()
    shoot("props_street_a", "street", [lamp, lamp_double, bench, bin_, bollard, hydrant], tall=12)
    shoot("props_street_b", "street", [cafe_table, railing, fence], tall=6)
    shoot("props_green", "green", [planter_square, planter_round, flower_bed, hedge, rocks], tall=4)
    shoot("props_signs_a", "signs", [sign_post, notice_board, attraction_sign], tall=8)
    shoot("props_signs_b", "signs", [gavel_statue, briefcase_stack, file_boxes, crate], tall=4)
    O.render(OUT, "props_plaza", (34, -58, 34), (0, 2, 2), lens=30, show=["plaza"])
    O.render(OUT, "props_plaza_eye", (-14, -22, 6.5), (6, 10, 3.2), lens=26, show=["plaza"])
    O.render(OUT, "props_before", (24, 600 - 44, 10), (24, 600, 3.5), lens=28, show=["compare"])
    O.render(OUT, "props_after", (124, 600 - 44, 10), (124, 600, 3.5), lens=28, show=["compare"])


if __name__ == "__main__":  # (the hub / firm scripts import the props)
    main()
