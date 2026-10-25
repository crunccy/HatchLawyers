# tools/blender/overhaul/island_brainrot.py - MAP MODEL OVERHAUL stage 5: BRAINROT ZONE re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). The approved v2 island (environment-redesign/brainrot_zone_v2/brv2_build.py on hl_v2: the
# purple floor, outcrops, goo pools, spawn dock, egg regions, Martello's box) runs UNCHANGED in the island_kit sandbox,
# its surreal pieces remade here at the same spots + sizes:
#   wobble lamps, the twisty tower, the big screen, the melty mall, the upside-down house, upside-down trees, pixel trees
#   (chunky bevelled cubes, ONE colour each), the leaning tower, giant dice, floating eyes + cubes, the neon tower, glow
#   mushrooms, crystals, goo bubbles, the floor's glitch bits; the Return Home rock portal comes from island_kit.
#   Blender -b --factory-startup --python tools/blender/overhaul/island_brainrot.py -- <out_dir> [places_only]
import bpy, math, os, sys, random, importlib
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import island_kit as IK
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, leafy

ROOT = IK.ROOT
SCRIPT = os.path.join(ROOT, "brainrot_zone_v2", "brv2_build.py")
for _p in (os.path.dirname(SCRIPT), os.path.join(ROOT, "brainrot_zone")):
    sys.path.insert(0, _p)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rr = random.Random(3303)
TAU = math.tau
O.K.PAL.update({"night": (40, 30, 70), "violet": (110, 55, 190), "magenta": (230, 50, 200), "lilac": (190, 150, 255), "sky_blue": (110, 190, 250),
                "glitch_lime": (170, 250, 70), "mush_cap": (250, 90, 190), "mush_stem": (240, 230, 250), "house_yellow": (255, 210, 60)})


def rbox(name, look, c, size, r=0.4, rot=(0, 0, 0)):
    box(name, look, c, size, rot=rot, bevel=min(r, min(size) * 0.45), segs=2)


def neon_sign(n, cx, cy, z, w, h, label, frame="glow_magenta", letters="glow_cyan", post_h=None):
    with at(cx, cy, 0):
        if post_h:
            for sx in (-w / 2 + 0.8, w / 2 - 0.8):
                cyl(n + "_Post", "night", (sx, 0.4, 0), 0.4, post_h + 0.2, segs=10)
        rbox(n + "_Panel", "night", (0, 0, z + h / 2), (w, 0.7, h), 0.2)
        pts = [(-w / 2 - 0.1, -0.4, z - 0.1), (w / 2 + 0.1, -0.4, z - 0.1), (w / 2 + 0.1, -0.4, z + h + 0.1), (-w / 2 - 0.1, -0.4, z + h + 0.1),
               (-w / 2 - 0.1, -0.4, z - 0.1)]
        tube(n + "_Neon", frame, pts, 0.18, segs=6, cap=False)
        text(label, letters, (0, -0.42, z + h / 2), min(h * 0.46, (w - 1) / (0.72 * len(label))), extrude=0.06)


# ================================================================== lamps + trees
def wobble_lamp(F, x, y, lean=8.0, rot=0.0, head="glow_magenta", h=11.0):
    n = "RotLamp"
    with IK.place(F, x, y, 0.0, rot):
        lathe(n + "_Base", "night", [(0.95, 0.0), (0.95, 0.3, True), (0.7, 0.45), (0.35, 0.8)], segs=12)
        off, pts = 0.0, []
        for k in range(9):
            off = math.sin(math.radians(lean)) * 0.6 * k * (1 + k * 0.08) + 0.35 * math.sin(k * 1.3)
            pts.append((off, 0, 0.6 + k * (h - 0.6) / 8))
        tube(n + "_Post", "violet", pts, [0.32 - 0.012 * k for k in range(9)], segs=8)
        for k in (2, 5):
            cyl(n + "_Gold", "gold", (pts[k][0], 0, pts[k][2] - 0.1), 0.36, 0.2, segs=10)
        sphere(n + "_Head" + head.title().replace("_", ""), head, (pts[-1][0], 0, pts[-1][2] + 0.9), 0.95, sub=2)
        cyl(n + "_Base", "night", (pts[-1][0], 0, pts[-1][2] - 0.1), 0.45, 0.25, segs=10, r_top=0.6)


def pixel_tree(F, x, y, s=1.0, look="magenta", top="lilac"):
    """A pixel-art tree: a stacked-cube trunk under a chunky voxel blob of bevelled cubes (one colour)."""
    n = "RotPixelTree"
    with IK.place(F, x, y, 0.0, rr.uniform(0, 90), s):
        for k in range(3):
            rbox(n + "_Trunk", "violet", (0.15 * (k % 2), 0, 0.85 + k * 1.65), (1.6, 1.6, 1.65), 0.18)
        R, step = 3.6, 1.55
        for i in range(-3, 4):
            for j in range(-3, 4):
                for k in range(-2, 3):
                    p = Vector((i * step, j * step, k * step))
                    d = Vector((p.x, p.y, p.z * 1.25)).length
                    if R - step < d < R + 0.2:
                        rbox(n + "_" + look.title().replace("_", ""), look, (p.x, p.y, 7.2 + p.z), (step * 0.96,) * 3, 0.22)
        for k in range(3):  # stray glitch pixels floating off it
            a = rr.uniform(0, TAU)
            rbox(n + "_" + look.title().replace("_", ""), look, (math.cos(a) * 5.0, math.sin(a) * 5.0, 8.0 + rr.uniform(-1, 2)), (0.7, 0.7, 0.7), 0.12)


def upside_down_tree(F, x, y, s=1.0):
    n = "RotUpsideTree"
    i = next(IK.CNT)
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz, s=s):
        leafy("RotUpsideCanopy%d" % i, [((0, 0, 1.4), 3.4), ((1.8, 0.8, 1.0), 2.4), ((-1.6, -0.9, 1.1), 2.4), ((0.2, -1.8, 2.2), 2.0)],
              look="lilac", voxel=0.3, faces=700, lumpy=0.3, seed=i, squash=0.6)
        tube(n + "_Trunk", "wood_deep", [(0, 0, 2.6), (0.3, 0, 6.0), (0.1, 0, 9.5), (0, 0, 11.0)], [0.9, 0.8, 0.7, 0.6], segs=10)
        for a in (20, 110, 200, 290):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            tube(n + "_Trunk", "wood_deep", [(0, 0, 10.6), (ca * 1.4, sa * 1.4, 11.6), (ca * 2.6, sa * 2.6, 11.9), (ca * 3.4, sa * 3.4, 12.6)],
                 [0.45, 0.35, 0.25, 0.12], segs=7)


# ================================================================== surreal buildings
def twisty_tower(F, w=16, floors=12, looks=("violet", "magenta", "lilac"), trim="glow_cyan"):
    n = "RotTwisty"
    FL = 4.0
    with IK.place(F, 0, 0):
        rbox(n + "_Base", "night", (0, 0, 0.5), (w + 6, w + 6, 1.0), 0.3)
        for k in range(floors):
            rot = k * 7.5
            z = 1.0 + k * FL
            with at(0, 0, z, rz=rot):
                lk = looks[k % len(looks)]
                rbox(n + "_" + lk.title(), lk, (0, 0, (FL - 0.5) / 2), (w, w, FL - 0.5), 0.35)
                tl = trim if k % 3 == 0 else "night"
                rbox(n + "_Trim" + tl.title().replace("_", ""), tl, (0, 0, FL - 0.25), (w + 1.2, w + 1.2, 0.5), 0.2)
                for j in range(4):
                    with at(rz=j * 90):
                        gl = "glow_white" if (k + j) % 3 else "glow_magenta"
                        box(n + "_Win" + gl.title().replace("_", ""), gl, (0, -w / 2 - 0.04, 1.8), (w * 0.7, 0.12, 1.6), bevel=0.05)
                        for xx in (-w * 0.2, 0, w * 0.2):
                            box(n + "_Trim" + "Night", "night", (xx, -w / 2 - 0.08, 1.8), (0.3, 0.1, 1.7))
        top = 1.0 + floors * FL
        prof = [(w * 0.45 * (1 - t) + 0.4, top + t * 8) for t in [i / 8 for i in range(9)]]
        lathe(n + "_Spire", "magenta", [(w * 0.5, top)] + prof + [(0.0, top + 8.2)], segs=8, smooth=False)
        sphere(n + "_Orb", "glow_cyan", (0, 0, top + 9.5), 1.6, sub=2)
        neon_sign(n + "Sign", 0, -w / 2 - 3, 4.5, 12, 3, "TWISTY", post_h=4.5)
    return top


def big_screen(F, w=28, d=16, h=30):
    n = "RotScreen"
    with IK.place(F, 0, 0):
        rbox(n + "_Base", "night", (0, 0, 0.5), (w + 4, d + 4, 1.0), 0.3)
        rbox(n + "_Tower", "night", (0, 0, 1.0 + h / 2), (w, d, h), 0.4)
        for k in range(int(h / 4)):
            for sx in (-1, 1):
                gl = "glow_white" if k % 2 else "glow_cyan"
                box(n + "_Win" + gl.title().replace("_", ""), gl, (sx * (w / 2 + 0.02), 0, 3.7 + k * 4), (0.12, d * 0.8, 1.4), bevel=0.04)
        rbox(n + "_Roof", "magenta", (0, 0, h + 1.5), (w + 1, d + 1, 1.0), 0.3)
        for x in (-w / 4, w / 4):
            lathe(n + "_Antenna", "iron", [(1.2, h + 2), (1.0, h + 4), (0.3, h + 8.5), (0.0, h + 9)], segs=8, c=(x, 0, 0))
            sphere(n + "_Red", "glow_red", (x, 0, h + 9.6), 0.8, sub=1)
        with at(0, -d / 2 - 0.4, 0):
            rbox(n + "_Frame", "glow_magenta", (0, 0, 8 + (h - 10) / 2), (w - 4, 0.6, h - 10), 0.3)
            box(n + "_Field", "sky_blue", (0, -0.25, 9 + (h - 12) / 2), (w - 6, 0.5, h - 12), bevel=0.1)
            cz = 9 + (h - 12) / 2
            for sx in (-1, 1):
                rbox(n + "_EyeWhite", "white", (sx * 4.5, -0.6, cz + 4.5), (5, 0.4, 5), 0.6)
                rbox(n + "_Pupil", "panel_black", (sx * 4.5 + 1.2, -0.85, cz + 2.7 + 1.3), (2.2, 0.3, 2.6), 0.5)
            rbox(n + "_Grin", "panel_black", (0, -0.6, cz - 3.9), (10, 0.4, 2.2), 0.6)
            rbox(n + "_Tongue", "flower_pink", (2.5, -0.8, cz - 4.5), (3, 0.3, 1.4), 0.5)
        neon_sign(n + "Sign", 0, -d / 2 - 4, 3.5, 16, 3, "BIG SCREEN", post_h=3.5)


def melty_mall(F, w=30, d=20, h=12):
    n = "RotMall"
    r = random.Random(7)
    with IK.place(F, 0, 0):
        rbox(n + "_Base", "night", (0, 0, 0.5), (w + 4, d + 4, 1.0), 0.3)
        rbox(n + "_Wall", "lilac", (0, 0, 1 + h / 2), (w, d, h), 0.3)
        for k in range(5):
            x = -w / 2 + 3 + k * (w - 6) / 4
            with at(x, -d / 2, 1.0):
                B.window(n + "Win", 0, 1.0, 3.6, 4.6, arch=False, frame="white", glass="glass_blue", sill=False)
                rbox(n + "_Awning", "glow_cyan", (0, -0.6, 6.3), (4.6, 1.2, 0.35), 0.12)
        rbox(n + "_Icing", "magenta", (0, 0, 1 + h + 1.0), (w + 1.4, d + 1.4, 2.0), 0.9)
        for k in range(26):
            side = k % 4
            t = r.uniform(-0.45, 0.45)
            L = r.uniform(2, 6)
            if side in (0, 1):
                x, y = t * w, (-1 if side == 0 else 1) * (d / 2 + 0.7)
            else:
                x, y = (-1 if side == 2 else 1) * (w / 2 + 0.7), t * d
            rad = r.uniform(0.45, 0.8)
            tube(n + "_Icing", "magenta", [(x, y, 1 + h + 0.6), (x, y, 1 + h - L * 0.5), (x, y, 1 + h - L)], [rad, rad * 0.9, rad * 0.8], segs=10)
            sphere(n + "_Icing", "magenta", (x, y, 1 + h - L), rad * 1.15, sub=2)
        for k in range(9):  # sprinkles on the icing
            box(n + "_Sprinkle" + ("Lime" if k % 2 else "Cyan"), "glitch_lime" if k % 2 else "sky_blue", (r.uniform(-w / 2.4, w / 2.4), r.uniform(-d / 2.4, d / 2.4), 1 + h + 2.05),
                (0.9, 0.25, 0.2), rot=(0, 0, r.uniform(0, 180)), bevel=0.06)
        neon_sign(n + "Sign", 0, -d / 2 - 1.2, h - 2.4, 16, 3, "MELTY MALL")


def upside_down_house(F):
    n = "RotUpsideHouse"
    with IK.place(F, 0, 0):
        with at(0, 0, 0, rz=90):
            prism(n + "_Roof", "red", [(-0.6, 0.0), (0.6, 0.0), (8.2, 6.0), (-8.2, 6.0)], 14.0)
        tube(n + "_Ridge", "white", [(0, -7.2, 0.25), (0, 7.2, 0.25)], 0.3, segs=8)
        rbox(n + "_Wall", "house_yellow", (0, 0, 10.0), (15, 12, 8), 0.3)
        rbox(n + "_Trim", "white", (0, 0, 6.2), (15.4, 12.4, 0.4), 0.1)
        with at(0, -6.0, 6.0):
            for sx in (-3.8, 3.8):
                B.window(n + "Win", sx, 2.6, 2.6, 3.0, arch=False, shutters="house_blue" if "house_blue" in O.K.PAL else "violet")
            rbox(n + "_Door", "awning_green" if "awning_green" in O.K.PAL else "violet", (0, -0.1, 4.0), (2.6, 0.3, 5.0), 0.15)
            sphere(n + "_Knob", "gold", (0.8, -0.35, 2.0), 0.2, sub=1)  # (the knob at the bottom: it's upside down)
        rbox(n + "_Floor", "wood_deep", (0, 0, 14.3), (15.6, 12.6, 0.6), 0.15)
        rbox(n + "_Table", "wood_warm", (-4.5, 0, 15.8), (4, 2, 0.4), 0.1)
        for sx in (-1, 1):
            for sy in (-1, 1):
                cyl(n + "_Table", "wood_deep", (-4.5 + sx * 1.6, sy * 0.7, 16.0), 0.18, 1.4, segs=6)
        with at(4.0, 2.0, 14.6):
            rbox(n + "_Chair", "red", (0, 0, 0.4), (1.4, 1.4, 0.3), 0.08)
            rbox(n + "_Chair", "red", (0, 0.6, 1.2), (1.4, 0.25, 1.6), 0.08)
        rbox(n + "_Chimney", "brick" if "brick" in O.K.PAL else "red", (4.0, 2.5, 2.0), (1.6, 1.6, 3.4), 0.1)


def leaning_tower(F, x, y, lean=10, rot=0.0, h=22, look="violet"):
    n = "RotLeaning"
    with IK.place(F, x, y, 0.0, rot):
        off = 0.0
        for k in range(int(h / 2)):
            off += 0.12 * k * lean / 10
            lk = look if k % 2 else "lilac"
            rbox(n + "_" + lk.title(), lk, (off, 0, k * 2 + 1.0), (4.2 - k * 0.05, 4.2 - k * 0.05, 2.0), 0.35)
            if k % 3 == 1:
                box(n + "_Win", "glow_cyan", (off, -2.12 + k * 0.025, k * 2 + 1.0), (2.0, 0.12, 0.8), bevel=0.05)
        sphere(n + "_Orb", "glow_magenta", (off, 0, h + 1.2), 1.2, sub=2)


def giant_dice(F, x, y, s=4.0, look="white", pip="magenta", rot=0.0):
    n = "RotDice"
    with IK.place(F, x, y, 0.0, rot):
        box(n + "_Cube", look, (0, 0, s / 2), (s, s, s), bevel=s * 0.14, segs=3, smooth=True)
        for (c, nrm) in (((0, -s / 2, s / 2), (90, 0, 0)), ((-s / 2, -s / 4, s * 0.75), (0, -90, 0)), ((-s / 2, s / 4, s / 4), (0, -90, 0)),
                         ((-s / 4, -s / 4, s), (0, 0, 0)), ((0, 0, s), (0, 0, 0)), ((s / 4, s / 4, s), (0, 0, 0))):
            cyl(n + "_Pip", pip, c, s * 0.1, 0.06, segs=14, rot=nrm)


def floating_eye(F, x, y, z, r=3.0):
    n = "RotEye"
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz):
        sphere(n + "_White", "white", (0, 0, z), r, sub=3)
        cyl(n + "_Iris", "sky_blue", (0, -r * 0.9, z), r * 0.52, 0.25, segs=24, rot=(90, 0, 0))
        cyl(n + "_Pupil", "panel_black", (0, -r * 0.98, z), r * 0.25, 0.12, segs=18, rot=(90, 0, 0))
        sphere(n + "_White", "white", (r * 0.15, -r * 1.07, z + r * 0.15), r * 0.08, sub=1)
        for k in range(4):
            a = math.radians(30 + k * 75)
            tube(n + "_Vein", "red", [(r * 0.98 * math.cos(a), r * 0.2 * math.sin(a) - r * 0.1, z + r * 0.98 * math.sin(a)),
                                      (r * 0.85 * math.cos(a + 0.3), -r * 0.45, z + r * 0.85 * math.sin(a + 0.3))], 0.06, segs=4)
        lathe(n + "_Ring", "glow_cyan", [(r * 1.3, z - r * 0.1), (r * 1.4, z - r * 0.05), (r * 1.4, z + 0.05), (r * 1.3, z)], segs=28)


def floating_cube(F, x, y, z, s=3.0, look="lilac", rot=20.0):
    n = "RotCube"
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz, rz=rot):
        box(n + "_" + look.title().replace("_", ""), look, (0, 0, z + s / 2), (s, s, s), bevel=s * 0.12, segs=2)
        box(n + "_Glow", "glow_cyan", (0, 0, z - 0.3), (s * 0.5, s * 0.5, 0.2), bevel=0.05)
        for sx in (-1, 1):
            for sy in (-1, 1):
                sphere(n + "_Glow", "glow_cyan", (sx * s / 2, sy * s / 2, z + s), 0.25, sub=1)


def neon_tower(F, w=14, d=14, h=40, body="night", strips=("glow_magenta", "glow_cyan"), crown="magenta", sign=None):
    n = "RotNeon"
    with IK.place(F, 0, 0):
        rbox(n + "_Base", "night", (0, 0, 0.5), (w + 4, d + 4, 1.0), 0.3)
        rbox(n + "_Body", body, (0, 0, 1 + h / 2), (w, d, h), 0.4)
        for k in range(int(h / 3.2)):
            z = 2.9 + k * 3.2
            lk = strips[k % len(strips)]
            for sgn in (-1, 1):
                box(n + "_Strip" + lk.title().replace("_", ""), lk, (0, sgn * (d / 2 + 0.03), z), (w * 0.8, 0.12, 1.0), bevel=0.04)
                box(n + "_Strip" + lk.title().replace("_", ""), lk, (sgn * (w / 2 + 0.03), 0, z), (0.12, d * 0.8, 1.0), bevel=0.04)
        for sx in (-1, 1):
            for sy in (-1, 1):
                tube(n + "_Edge", strips[0], [(sx * w / 2, sy * d / 2, 1.2), (sx * w / 2, sy * d / 2, h + 1)], 0.16, segs=6)
        rbox(n + "_Crown", crown, (0, 0, h + 1.5), (w + 1, d + 1, 1.0), 0.3)
        rbox(n + "_Body", body, (0, 0, h + 3.5), (w - 4, d - 4, 3.0), 0.3)
        rbox(n + "_Crown", crown, (0, 0, h + 6.0), (w - 8, d - 8, 2.0), 0.3)
        lathe(n + "_Antenna", "iron", [(0.5, h + 7), (0.35, h + 10), (0.12, h + 16), (0.0, h + 16.2)], segs=8)
        sphere(n + "_Red", "glow_red", (0, 0, h + 16.5), 0.7, sub=1)
        if sign:
            neon_sign(n + "Sign", 0, -d / 2 - 0.6, h - 6, w + 2, 3.4, sign)


# ================================================================== the script's own bits
def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.3:
        lk = rr.choice(("magenta", "glitch_lime", "sky_blue", "violet"))
        box("RotGlitch" + lk.title().replace("_", ""), lk, (x, y, z + 0.02), (rr.uniform(1.2, 2.6), rr.uniform(1.2, 2.6), 0.1), rot=(0, 0, rr.uniform(0, 90)),
            bevel=0.03)
    elif roll < 0.45:
        s = rr.uniform(0.8, 1.2)
        with at(x, y, z, rz=rr.uniform(0, 90)):
            box("RotToyDie", "white", (0, 0, s / 2), (s, s, s), bevel=s * 0.15, segs=2)
            cyl("RotToyDie_Pip", "magenta", (0, 0, s), s * 0.14, 0.04, segs=10)
    elif roll < 0.62 and (edge or rr.random() < 0.4):
        for k in range(rr.randint(2, 4)):
            fx, fy = x + rr.uniform(-1.2, 1.2), y + rr.uniform(-1.2, 1.2)
            cyl("RotFlower_Stem", "rot_grass" if "rot_grass" in O.K.PAL else "leaf_sun", (fx, fy, z), 0.1, 1.0, segs=5)
            lk = rr.choice(("magenta", "glitch_lime", "house_yellow", "sky_blue"))
            box("RotFlower" + lk.title().replace("_", ""), lk, (fx, fy, z + 1.25), (0.7, 0.7, 0.5), rot=(0, 0, rr.uniform(0, 90)), bevel=0.12)
    elif roll < 0.74:
        sphere("RotTinyEye_White", "white", (x, y, z + 0.5), 0.5, sub=2)
        sphere("RotTinyEye_Pupil", "panel_black", (x + 0.35, y, z + 0.6), 0.2, sub=1)
    elif roll < 0.86 and edge:
        import hl_v2 as V
        m.slab(V.V2.blob(x, y, rr.uniform(1.6, 2.8), 10), z - 0.04, z + 0.12, "rot_grass", chamfer=0.02)


def mushroom(m, x, y, z, s):
    with at(x, y, z, s=s):
        lathe("RotMush_Stem", "mush_stem", [(0.6, 0.0), (0.5, 0.4), (0.42, 2.0), (0.55, 2.8), (0.0, 2.9)], segs=12)
        lathe("RotMush_Cap", "mush_cap", [(0.5, 2.6), (2.0, 2.8), (2.2, 3.1), (1.9, 3.7), (1.2, 4.1), (0.0, 4.25)], segs=18)
        for k in range(5):
            a = k / 5 * TAU + 0.4
            sphere("RotMush_Glow", "glow_cyan", (math.cos(a) * 1.35, math.sin(a) * 1.35, 3.85), 0.3, sub=1, scale=(1, 1, 0.5))


def crystal(m, x, y, z, h, look):
    IK.crystal("RotCrystal" + look.title().replace("_", ""), look, (x, y, z), h, lean=(rr.uniform(-15, 15), rr.uniform(-15, 15)))


def goo_garden(x, y):
    if rr.random() < 0.5:
        sphere("RotGooBubble", "goo_deep", (x, y, 0.9), 0.8, sub=2)
    else:
        crystal(None, x, y, 0.5, rr.uniform(1.5, 3.0), "glow_cyan")


# ================================================================== the mapping + run
def patch():
    IK.patch_v2_common()
    BR = importlib.import_module("br_parts")
    for nm, fn in (("wobble_lamp", wobble_lamp), ("pixel_tree", pixel_tree), ("upside_down_tree", upside_down_tree), ("twisty_tower", twisty_tower),
                   ("big_screen", big_screen), ("melty_mall", melty_mall), ("upside_down_house", upside_down_house), ("leaning_tower", leaning_tower),
                   ("giant_dice", giant_dice), ("floating_eye", floating_eye), ("floating_cube", floating_cube), ("neon_tower", neon_tower)):
        setattr(BR, nm, fn)


def main():
    patch()
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT, overrides={"floor_bit": floor_bit, "mushroom": mushroom, "crystal": crystal, "goo_garden": goo_garden},
                      argv=("only=aerial,ground_spawn,ground_eggs,boss_view,ground_portal",), capture_cams=True)
    O.finish()
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "BRV2", "Diagram", "Egg_Spot"))
    if "places_only" not in argv:
        IK.render_captured(OUT, "rot_")
    IK.render_places(g["I"], OUT, "rot_", ["Twisty tower", "The big screen", "Melty mall", "Upside-down house", "Neon tower", "Giant dice"],
                     dist=44, height=16, look_up=9)


if __name__ == "__main__":
    main()
