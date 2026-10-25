# tools/blender/overhaul/island_space_base.py - MAP MODEL OVERHAUL stage 5: SPACE BASE re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). The approved v2 island (environment-redesign/space_base_v2/sbv2_build.py on hl_v2: the moon
# floor, violet outcrops, plasma pools, the gantry dock, egg regions, the Eclipse's box, the sky planets) runs UNCHANGED in
# the island_kit sandbox, its space pieces remade here at the same spots + sizes:
#   beacon lamps, alien mushrooms, tentacle plants, bulb plants, spike plants, crystals + crystal clusters, moon rocks, the
#   rocket + gantry, the observatory + its dome, the habitat domes, the robot factory (with its radar), the solar farm,
#   the satellite dish, the fuel depot, the UFO, the floor's pebbles / sprouts / stud lights; the Return Home rock portal
#   comes from island_kit. Every model passes check_models.py.
#   Blender -b --factory-startup --python tools/blender/overhaul/island_space_base.py -- <out_dir> [places_only]
import bpy, math, os, sys, random, importlib
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import island_kit as IK
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text

ROOT = IK.ROOT
SCRIPT = os.path.join(ROOT, "space_base_v2", "sbv2_build.py")
for _p in (os.path.dirname(SCRIPT), os.path.join(ROOT, "space_base")):
    sys.path.insert(0, _p)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rr = random.Random(5505)
TAU = math.tau
for k_, v_ in {"hull_dark": (60, 64, 80), "hull_grey": (150, 156, 170), "hull_white": (240, 242, 248), "rocket_red": (226, 56, 56),
               "space_navy": (40, 50, 110), "panel_blue": (60, 110, 220), "alien_pink": (250, 110, 200), "alien_purple": (150, 90, 230),
               "alien_teal": (60, 200, 190), "alien_lime": (170, 240, 80), "crystal_cyan": (120, 230, 255), "crystal_pink": (255, 140, 220),
               "crystal_violet": (170, 120, 255), "moon_light": (210, 210, 220), "moon_dark": (130, 130, 146), "rock_violet": (120, 96, 170),
               "rock_violet_dark": (84, 66, 128), "soil_purple": (90, 60, 120), "hazard": (255, 204, 40), "space_purple": (110, 70, 200)}.items():
    O.K.PAL.setdefault(k_, v_)
for k_, v_ in {"glow_pink": ((255, 120, 220), 1.8), "glow_lime": ((180, 255, 90), 1.8)}.items():
    O.K.GLOWS.setdefault(k_, v_)


def L(look):
    return look.title().replace("_", "")


# ================================================================== plants, crystals, rocks, lamps
def beacon_lamp(F, x, y, h=8.0, glow="glow_cyan"):
    n = "SpaceLamp"
    with IK.place(F, x, y):
        lathe(n + "_Dark", "hull_dark", [(1.0, 0.0), (1.0, 0.5, True), (0.75, 0.7), (0.4, 0.85)], segs=12)
        cyl(n + "_Grey", "hull_grey", (0, 0, 0.8), 0.35, h - 0.8, segs=10)
        for z in (2.0, 4.0):
            cyl(n + "_Dark", "hull_dark", (0, 0, z), 0.5, 0.3, segs=10)
        lathe(n + "_White", "hull_white", [(0.3, h - 0.1), (0.75, h), (0.75, h + 0.3, True), (0.0, h + 0.3)], segs=12)
        sphere(n + "_" + L(glow), glow, (0, 0, h + 0.95), 0.7, sub=2)
        tube(n + "_Grey", "hull_grey", [(0.3, 0, h - 1.4), (0.9, 0, h - 1.2)], 0.08, segs=5)
        lathe(n + "_White", "hull_white", [(0.0, -0.1), (0.45, 0.0), (0.5, 0.15, True), (0.0, 0.05)], segs=12, c=(1.05, 0, h - 1.2), rot=(0, 60, 0))


def alien_mushroom(F, x, y, s=1.0, cap="alien_pink", glow="glow_pink"):
    n = "SpaceMush"
    with IK.place(F, x, y, 0.0, rr.uniform(0, 360), s):
        lathe(n + "_Stem", "moon_light", [(0.8, 0.0), (0.62, 0.3), (0.55, 1.6), (0.62, 3.0), (0.8, 3.4, True), (0.0, 3.4)], segs=12)
        prof = [(2.45 * math.cos(t), 3.2 + 1.8 * math.sin(t)) for t in [i / 8 * math.pi / 2 for i in range(9)]]
        lathe(n + "_" + L(cap), cap, [(0.6, 3.0), (2.0, 3.1), (2.45, 3.25)] + prof[1:-1] + [(0.0, 5.0)], segs=20)
        for k in range(5):
            a = k / 5 * TAU + 0.2
            rad = 1.5
            z = 3.2 + 1.8 * math.sqrt(max(0.0, 1 - (rad / 2.45) ** 2))
            sphere(n + "_" + L(glow), glow, (math.cos(a) * rad, math.sin(a) * rad, z - 0.05), 0.32, sub=1, scale=(1, 1, 0.7))


def tentacle_plant(F, x, y, s=1.0, look="alien_teal", glow="glow_lime", n="SpaceTentacle"):
    with IK.place(F, x, y, 0.0, rr.uniform(0, 360), s):
        lathe(n + "_Soil", "soil_purple", [(1.3, 0.0), (1.2, 0.5), (0.8, 0.85), (0.0, 0.9)], segs=14)
        for k in range(5):
            a = k / 5 * TAU + rr.uniform(-0.2, 0.2)
            ca, sa = math.cos(a), math.sin(a)
            pts = []
            for j in range(8):
                t = j / 7
                rad = 0.3 + 1.6 * math.sin(t * 2.2)
                pts.append((ca * rad, sa * rad, 0.6 + 4.2 * t - 1.1 * t * t))
            tube(n + "_" + L(look), look, pts, [0.38 - 0.04 * j for j in range(8)], segs=8)
            sphere(n + "_" + L(glow), glow, pts[-1], 0.4, sub=1)


def bulb_plant(F, x, y, s=1.0, glow="glow_cyan", n="SpaceBulb"):
    with IK.place(F, x, y, 0.0, rr.uniform(0, 360), s):
        lathe(n + "_Soil", "soil_purple", [(1.4, 0.0), (1.2, 0.3), (0.0, 0.4)], segs=12)
        for k in range(3):
            a = k / 3 * TAU + rr.uniform(0, 0.6)
            rad = rr.uniform(0.2, 0.9)
            h = rr.uniform(2.6, 4.6)
            base = (math.cos(a) * rad, math.sin(a) * rad, 0.1)
            top = (math.cos(a) * (rad + 0.4), math.sin(a) * (rad + 0.4), h)
            tube(n + "_Stem", "alien_lime", [base, ((base[0] + top[0]) / 2 + 0.2, (base[1] + top[1]) / 2, h * 0.5), top], [0.2, 0.17, 0.15], segs=6)
            sphere(n + "_" + L(glow), glow, (top[0], top[1], top[2] + 0.45), 0.6, sub=2)
            poly(n + "_Leaf", "alien_lime", [(base[0], base[1], 0.6), (base[0] + 0.9 * math.cos(a + 0.6), base[1] + 0.9 * math.sin(a + 0.6), 1.3),
                                              (base[0] + 0.3 * math.cos(a + 0.9), base[1] + 0.3 * math.sin(a + 0.9), 1.0)], thick=0.05)


def spike_plant(F, x, y, s=1.0):
    n = "SpaceSpike"
    with IK.place(F, x, y, 0.0, rr.uniform(0, 360), s):
        lathe(n + "_Body", "alien_purple", [(1.4, 0.0), (1.3, 1.0), (0.95, 2.4), (0.55, 3.4), (0.0, 4.1)], segs=8, smooth=False)
        for k in range(6):
            a = k / 6 * TAU
            z = 1.0 + (k % 3) * 0.8
            rad = 1.3 - (k % 3) * 0.2
            tube(n + "_Spike", "alien_pink", [(math.cos(a) * (rad - 0.3), math.sin(a) * (rad - 0.3), z), (math.cos(a) * (rad + 1.0), math.sin(a) * (rad + 1.0), z + 0.4)],
                 [0.18, 0.02], segs=6)


def crystal(F, x, y, h=6.0, r=1.0, look="crystal_cyan", core="glow_cyan"):
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz):
        cyl("SpaceCrystal_" + L(look), look, (0, 0, 0), r, h * 0.72, segs=6, r_top=r * 0.92, smooth=False)
        cyl("SpaceCrystal_" + L(look), look, (0, 0, h * 0.72), r * 0.92, h * 0.28, segs=6, r_top=0.0, smooth=False)
        lathe("SpaceCrystal_" + L(core), core, [(r * 0.98, 0.0), (r * 1.15, 0.08), (r * 1.15, 0.28), (r * 0.98, 0.34)], segs=6, smooth=False)


def crystal_cluster(F, x, y, s=1.0, looks=("crystal_cyan", "glow_cyan")):
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz):
        crystal(IK.O_NONE, 0, 0, 7.0 * s, 1.2 * s, *looks)
        for k in range(5):
            a = k / 5 * TAU + rr.uniform(-0.3, 0.3)
            d = rr.uniform(1.0, 1.6) * s
            IK.crystal("SpaceCrystal_" + L(looks[0]), looks[0], (math.cos(a) * d, math.sin(a) * d, -0.1), rr.uniform(2.4, 4.6) * s,
                       lean=(-math.sin(a) * 22, math.cos(a) * 22))


def moon_rocks(F, x, y, s=1.0):
    wx, wy, wz, _ = IK.where(F, x, y)
    with at(wx, wy, wz, rz=rr.uniform(0, 360), s=s):
        look = rr.choice(("moon_dark", "rock_violet"))
        for k, (dx, dy, r) in enumerate(((0, 0, 1.4), (1.6, 0.6, 0.9), (-1.3, -0.7, 0.7), (0.5, -1.4, 0.5))):
            O.rock("SpaceRock_" + L(look), "SpaceRockTop", (dx, dy, r * 0.1), r, seed=next(IK.CNT), squash=0.7, look=look, top="moon_light")


# ================================================================== landmarks
def rocket(F):
    n = "SpaceRocket"
    with IK.place(F, 0, 0):
        cyl(n + "_Pad", "hull_dark", (0, 0, 0), 14.0, 1.2, segs=8, spin=22.5, smooth=False)
        lathe(n + "_Hazard", "hazard", [(12.6, 1.2), (13.6, 1.2), (13.6, 1.32), (12.6, 1.32)], segs=8, smooth=False)
        cyl(n + "_Stand", "hull_grey", (0, 0, 1.2), 9.0, 0.8, segs=24)
        for k in range(4):
            a = math.radians(k * 90 + 45)
            lathe(n + "_Bell", "hull_dark", [(0.0, 2.0), (1.2, 2.0), (1.2, 2.2, True), (0.9, 3.4), (0.65, 4.4), (0.0, 4.4)], segs=14,
                  c=(math.cos(a) * 1.9, math.sin(a) * 1.9, 0))
        for k in range(9):
            lk = "rocket_red" if k in (0, 4, 8) else "hull_white"
            lathe(n + "_" + L(lk), lk, [(3.6, 4.4 + k * 3.0), (3.6, 7.4 + k * 3.0)], segs=28)
        lathe(n + "_Base", "hull_grey", [(0.0, 4.3), (3.62, 4.3), (3.62, 4.5, True), (0.0, 4.5)], segs=28)  # (the engine plate the bells hang from)
        prof = [(3.6 * (1 - t ** 1.6) + 0.02, 31.4 + 7.0 * t) for t in [i / 10 for i in range(11)]]
        lathe(n + "_Nose", "rocket_red", prof[:-1] + [(0.0, 38.4)], segs=28)
        for z in (15.0, 26.0):
            for a in (45, 135, 225, 315):  # (clear of the gantry arms on +X)
                ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
                with at(ca * 3.55, sa * 3.55, z, rz=a + 90):
                    cyl(n + "_Glass", "glass_dark", (0, 0.05, 0), 0.8, 0.12, segs=14, rot=(90, 0, 0))
                    lathe(n + "_Porthole", "hull_grey", [(0.8, -0.05), (1.05, -0.05), (1.05, 0.2), (0.8, 0.2)], segs=14, rot=(90, 0, 0))
        for a in (45, 135, 225, 315):
            with at(0, 0, 0, rz=a):
                prism(n + "_Fin", "rocket_red", [(3.3, 4.4), (6.4, 2.0), (6.6, 6.2), (3.3, 11.0)], 0.5)  # (tips stand on the stand)
        G = (10, 0)
        with at(*G, 1.2):  # the gantry: posts, braces, two arms reaching the rocket, a beacon
            for sx in (-1.8, 1.8):
                for sy in (-1.8, 1.8):
                    box(n + "_Gantry", "hull_grey", (sx, sy, 18.0), (0.6, 0.6, 36.0), bevel=0.05)
            for k in range(9):
                z = 1.8 + k * 4.0
                for (cx, cy, sx, sy) in ((0, -1.8, 4.2, 0.4), (0, 1.8, 4.2, 0.4), (-1.8, 0, 0.4, 4.2), (1.8, 0, 0.4, 4.2)):
                    box(n + "_Brace", "rocket_red", (cx, cy, z), (sx, sy, 0.4), bevel=0.04)
            for z in (13.8, 25.8):  # (on the brace levels, so they hang off the frame)
                box(n + "_Gantry", "hull_grey", (-4.0, 0, z), (5.0, 1.4, 0.8), bevel=0.08)
            box(n + "_Gantry", "hull_dark", (0, 0, 36.3), (4.6, 4.6, 0.6), bevel=0.08)
            sphere(n + "_Beacon", "glow_red", (0, 0, 37.1), 0.6, sub=2)


def observatory(F):
    n = "SpaceObservatory"
    with IK.place(F, 0, 0):
        lathe(n + "_Base", "hull_grey", [(12.0, 0.0), (12.0, 0.8, True), (0.0, 0.8)], segs=40)
        lathe(n + "_Drum", "hull_white", [(10.0, 0.8), (10.0, 9.0)], segs=40)
        lathe(n + "_Gold", "gold", [(10.0, 7.6), (10.15, 7.65), (10.15, 8.35), (10.0, 8.4)], segs=40)
        lathe(n + "_Top", "hull_grey", [(10.0, 9.0), (10.4, 9.05), (10.4, 9.8, True), (0.0, 9.8)], segs=40)
        with at(0, -9.95, 0.8):
            B.door(n + "Door", 0, 0, 3.0, 5.4, frame="gold", leaf="space_navy", panel="hull_grey", depth=0.4)
        with at(0, -9.9, 0):
            box(n + "_Sign", "space_navy", (0, -0.2, 6.9 + 1.1 - 0.3), (11.0, 0.4, 2.0), bevel=0.1)
            box(n + "_Gold", "gold", (0, -0.12, 7.7), (11.5, 0.3, 2.5), bevel=0.1)
            text("OBSERVATORY", "gold", (0, -0.45, 7.7), 1.0, extrude=0.03)


def observatory_dome(F):
    n = "SpaceDome"
    with IK.place(F, 0, 0):
        prof = [(10.0 * math.cos(t), 8.0 * math.sin(t)) for t in [i / 12 * math.pi / 2 for i in range(13)]]
        lathe(n + "_White", "hull_white", [(10.2, 0.0)] + prof + [(0.0, 8.0)], segs=40)
        pts = [(0.0, -10.0 * math.cos(t) - 0.05, 8.0 * math.sin(t) + 0.05) for t in [i / 10 * math.pi / 2 for i in range(11)]]
        for i in range(10):
            a, b = Vector(pts[i]), Vector(pts[i + 1])
            poly(n + "_Slit", "space_navy", [a + Vector((-1.1, 0, 0)), a + Vector((1.1, 0, 0)), b + Vector((1.1, 0, 0)), b + Vector((-1.1, 0, 0))], thick=0.3)
        tube(n + "_Scope", "hull_grey", [(0, -3.0, 3.0), (0, -8.6, 7.4)], [0.8, 0.7], segs=14)
        lathe(n + "_Gold", "gold", [(0.75, 0.0), (0.95, 0.1), (0.95, 0.5), (0.75, 0.6)], segs=14, c=(0, -8.6, 7.4), rot=(-52, 0, 0))


def habitat_domes(F):
    n = "SpaceHabitat"
    spots = ((0, 0, 9.0), (-15, -8, 6.5), (14, -9, 6.0))
    with IK.place(F, 0, 0):
        for (x, y, r) in spots:
            with at(x, y, 0):
                lathe(n + "_Ring", "hull_white", [(r + 1.0, 0.0), (r + 1.0, 1.2, True), (0.0, 1.2)], segs=32)
                lathe(n + "_Glow", "glow_cyan", [(r + 0.2, 1.2), (r + 1.0, 1.2), (r + 1.0, 1.45), (r + 0.2, 1.45)], segs=32)
                cyl(n + "_Soil", "soil_purple", (0, 0, 1.2), r * 0.6, 0.4, segs=20)
                with at(0, 0, 1.6, s=0.8):
                    bulb_plant(IK.O_NONE, 0, 0, 1.0, "glow_lime")
                prof = [(r * math.cos(t), 1.2 + r * 0.85 * math.sin(t)) for t in [i / 12 * math.pi / 2 for i in range(13)]]
                lathe(n + "_Glass", "glass", prof + [(0.0, 1.2 + r * 0.85)], segs=32)
        for (a, b) in ((0, 1), (0, 2)):
            (x0, y0, r0), (x1, y1, r1) = spots[a], spots[b]
            d = Vector((x1 - x0, y1 - y0, 0))
            u = d.normalized()
            p0 = Vector((x0, y0, 2.5)) + u * (r0 - 0.5)
            p1 = Vector((x1, y1, 2.5)) - u * (r1 - 0.5)
            tube(n + "_Tube", "hull_white", [tuple(p0), tuple(p1)], 1.3, segs=16)
            for t in (0.3, 0.7):
                pm = p0 + (p1 - p0) * t
                tube(n + "_Glow", "glow_cyan", [tuple(pm + u * 0.15), tuple(pm - u * 0.15)], 1.36, segs=16)
        with at(0, -10.4, 0):
            for sx in (-4.2, 4.2):
                cyl(n + "_Post", "hull_grey", (sx, 0.3, 0), 0.2, 3.4, segs=8)
            box(n + "_Sign", "space_purple", (0, 0, 2.4), (10, 0.4, 2.0), bevel=0.1)
            text("HABITAT", "white", (0, -0.25, 2.4), 1.0, extrude=0.03)


def radar(n, c):
    with at(*c):
        cyl(n + "_Grey", "hull_grey", (0, 0, 0), 0.5, 3.0, segs=10)
        lathe(n + "_Dish", "hull_white", [(0.0, -0.2), (1.5, 0.0), (2.5, 0.5), (2.6, 0.75, True), (0.0, 0.0)], segs=18, c=(0, -0.6, 4.2), rot=(-70, 0, 0))
        tube(n + "_Grey", "hull_grey", [(0, -0.4, 2.9), (0, -0.7, 4.0)], 0.2, segs=6)
        tube(n + "_Grey", "hull_grey", [(0, -0.9, 4.3), (0, -2.4, 4.9)], 0.07, segs=5)
        sphere(n + "_Red", "glow_red", (0, -2.5, 4.95), 0.3, sub=1)


def robot_factory(F):
    n = "SpaceFactory"
    with IK.place(F, 0, 0):
        box(n + "_Base", "hull_dark", (0, 0, 0.4), (30, 24, 0.8), bevel=0.12)
        box(n + "_Wall", "hull_grey", (0, 2, 6.3), (26, 18, 11), bevel=0.2)
        for k in range(4):  # panel seams
            box(n + "_Seam", "hull_dark", (-9.75 + k * 6.5, -7.02, 6.3), (0.2, 0.08, 10.6))
        box(n + "_Roof", "hull_white", (0, 2, 12.2), (27, 19, 0.8), bevel=0.15)
        for k in range(5):
            box(n + "_Window", "glow_cyan", (-10 + k * 5, -7.06, 7.2), (3.0, 0.12, 2.4), bevel=0.05)
        box(n + "_Door", "hull_dark", (0, -7.1, 3.8), (8, 0.2, 6.0), bevel=0.06)
        for k in range(6):
            box(n + ("_Hazard" if k % 2 == 0 else "_HazardBlack"), "hazard" if k % 2 == 0 else "panel_black", (-3.5 + k * 1.4, -7.25, 7.2), (1.4, 0.2, 0.8))
        for sx in (-8, 8):
            lathe(n + "_Stack", "hull_dark", [(2.0, 12.6), (2.0, 19.0, True), (2.2, 19.0), (2.2, 19.6, True), (0.0, 19.6)], segs=16, c=(sx, 6, 0))
            cyl(n + "_Glow", "glow_magenta", (sx, 6, 19.6), 1.6, 0.2, segs=16)
        with at(0, -7.0, 0):
            box(n + "_Sign", "space_navy", (0, -0.15, 9.6), (16, 0.3, 2.4), bevel=0.1)
            text("ROBOT FACTORY", "white", (0, -0.35, 9.6), 1.1, extrude=0.03)
        radar(n + "Radar", (-2, 6, 12.6))


def solar_farm(F, cols=4, rows=3):
    n = "SpaceSolar"
    with IK.place(F, 0, 0):
        for i in range(cols):
            for j in range(rows):
                x, y = (i - (cols - 1) / 2) * 7.0, (j - (rows - 1) / 2) * 6.0
                cyl(n + "_Post", "hull_grey", (x, y, 0), 0.28, 2.3, segs=8)
                with at(x, y, 2.4):
                    box(n + "_Frame", "hull_grey", (0, 0, 0), (6.2, 4.4, 0.25), rot=(-18, 0, 0), bevel=0.05)
                    for ci in range(3):
                        for cj in range(2):
                            M = O.xform((0, 0, 0), (-18, 0, 0))
                            c = M @ Vector((-2.0 + ci * 2.0, -1.0 + cj * 2.0, 0.16))
                            box(n + "_Cell", "panel_blue", tuple(c), (1.8, 1.8, 0.08), rot=(-18, 0, 0))
        with at((cols / 2) * 7.0 + 1.5, 0, 0):
            box(n + "_Box", "hull_white", (0, 0, 1.2), (2.4, 2.0, 2.4), bevel=0.15)
            box(n + "_Glow", "glow_lime", (0, -1.02, 1.6), (1.2, 0.06, 0.4))


def sat_dish(F):
    n = "SpaceSat"
    with IK.place(F, 0, 0):
        lathe(n + "_Grey", "hull_grey", [(1.6, 0.0), (1.6, 1.2, True), (0.9, 1.4), (0.8, 5.0)], segs=16)
        box(n + "_Yoke", "hull_white", (0, 0, 5.4), (1.6, 1.6, 1.2), bevel=0.2)
        lathe(n + "_Dish", "hull_white", [(0.0, 0.0), (2.5, 0.4), (4.5, 1.4), (6.2, 2.9), (6.4, 3.2, True), (6.0, 3.15), (0.0, 0.3)], segs=32,
              c=(0, -0.4, 5.8), rot=(-35, 0, 0))
        tube(n + "_Grey", "hull_grey", [(0, -0.9, 6.6), (0, -3.6, 10.4)], 0.18, segs=6)
        sphere(n + "_Glow", "glow_cyan", (0, -3.75, 10.65), 0.55, sub=2)


def fuel_depot(F):
    n = "SpaceFuel"
    with IK.place(F, 0, 0):
        for sx in (-7, 7):
            for k in range(4):
                a = math.radians(k * 90 + 45)
                tube(n + "_Leg", "hull_dark", [(sx + math.cos(a) * 3.6, math.sin(a) * 3.6, 0.0), (sx + math.cos(a) * 2.9, math.sin(a) * 2.9, 5.2)], 0.3, segs=8)
            sphere(n + "_Tank", "hull_white", (sx, 0, 8.6), 5.0, sub=3)
            lathe(n + "_Hazard", "hazard", [(4.96, 9.1), (5.03, 9.3), (5.03, 9.9), (4.9, 10.1)], segs=32)
        for z in (7.6, 10.4):
            tube(n + "_Pipe", "hull_grey", [(-2.5, 0, z), (2.5, 0, z)], 0.45, segs=10)
        with at(0, -5.6, 0):
            for sx in (-4.2, 4.2):
                cyl(n + "_Post", "hull_dark", (sx, 0.3, 0), 0.2, 3.4, segs=8)
            box(n + "_Sign", "hazard", (0, 0, 2.2), (10, 0.4, 2.0), bevel=0.1)
            text("FUEL DEPOT", "panel_black", (0, -0.25, 2.2), 1.0, extrude=0.03)


def ufo(F):
    n = "SpaceUFO"
    with IK.place(F, 0, 0):
        lathe(n + "_Pad", "hull_dark", [(13.0, 0.0), (13.0, 0.6, True), (0.0, 0.6)], segs=40)
        lathe(n + "_Glow", "glow_lime", [(11.6, 0.6), (12.6, 0.6), (12.6, 0.75), (11.6, 0.75)], segs=40)
        for k in range(4):
            a = math.radians(k * 90 + 45)
            tube(n + "_Leg", "hull_grey", [(math.cos(a) * 6.4, math.sin(a) * 6.4, 0.6), (math.cos(a) * 5.4, math.sin(a) * 5.4, 4.0)], 0.3, segs=8)
            lathe(n + "_Foot", "hull_grey", [(0.0, 0.6), (0.9, 0.6), (0.6, 1.0), (0.0, 1.0)], segs=10, c=(math.cos(a) * 6.4, math.sin(a) * 6.4, 0))
        lathe(n + "_Hull", "hull_grey", [(0.0, 3.4), (5.0, 3.5), (9.0, 4.3), (10.2, 4.9, True)], segs=40)
        lathe(n + "_Rim", "hull_white", [(10.2, 4.9), (10.4, 5.1), (10.0, 5.3, True)], segs=40)
        lathe(n + "_Hull", "hull_grey", [(10.0, 5.3), (8.0, 5.8), (6.8, 6.2, True), (0.0, 6.2)], segs=40)
        for k in range(16):
            a = k / 16 * TAU
            sphere(n + "_Glow", "glow_lime", (math.cos(a) * 10.25, math.sin(a) * 10.25, 5.1), 0.3, sub=1)
        prof = [(5.0 * math.cos(t), 6.2 + 4.2 * math.sin(t)) for t in [i / 10 * math.pi / 2 for i in range(11)]]
        lathe(n + "_Glass", "glass", prof + [(0.0, 10.4)], segs=28)
        cyl(n + "_Glow", "glow_lime", (0, 0, 2.9), 3.0, 0.55, segs=20)


# ================================================================== the script's own bits
def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.3:
        for k in range(rr.randint(2, 4)):
            O.rock("SpacePebble", "SpacePebbleTop", (x + rr.uniform(-1.2, 1.2), y + rr.uniform(-1.2, 1.2), z), rr.uniform(0.35, 0.6), seed=next(IK.CNT),
                   squash=0.6, look=rr.choice(("moon_dark", "rock_violet")), top="moon_light")
    elif roll < 0.45:
        crystal(IK.O_NONE, x, y, rr.uniform(1.2, 2.2), 0.4, rr.choice(("crystal_cyan", "crystal_pink", "crystal_violet")), "glow_cyan")
    elif roll < 0.58:
        lk = rr.choice(("glow_cyan", "glow_magenta"))
        cyl("SpaceStudLight_" + L(lk), lk, (x, y, z - 0.03), 0.5, 0.08, segs=12)
    elif roll < 0.72 and (edge or rr.random() < 0.4):
        for k in range(rr.randint(2, 3)):
            fx, fy = x + rr.uniform(-1, 1), y + rr.uniform(-1, 1)
            tube("SpaceSprout", "alien_lime", [(fx, fy, z), (fx + 0.1, fy, z + 0.6), (fx, fy, z + 1.0)], 0.09, segs=5)
            lk = rr.choice(("glow_lime", "glow_pink", "glow_cyan"))
            sphere("SpaceSprout_" + L(lk), lk, (fx, fy, z + 1.2), 0.3, sub=1)
    elif roll < 0.84 and edge:
        import hl_v2 as V
        m.slab(V.V2.blob(x, y, rr.uniform(1.6, 2.6), 10), z - 0.04, z + 0.12, "moon_light", chamfer=0.02)


# ================================================================== the mapping + run
def portal_side(sgn):
    """Beside the Return Home portal (palms on the other islands): a big tentacle plant and glow bulbs, on its stone base."""
    tentacle_plant(IK.O_NONE, 0, 0, 1.5, n="IslPortalTentacle")
    bulb_plant(IK.O_NONE, -sgn * 4.5, -1.5, 1.1, n="IslPortalBulb")


def patch():
    IK.patch_v2_common()
    IK.PORTAL.update(rock="rock_violet", top="moon_light", moss="alien_teal", flowers=("alien_pink", "alien_lime"), fern=False, side=portal_side)
    SB = importlib.import_module("sb_parts")
    for nm, fn in (("beacon_lamp", beacon_lamp), ("alien_mushroom", alien_mushroom), ("tentacle_plant", tentacle_plant), ("bulb_plant", bulb_plant),
                   ("spike_plant", spike_plant), ("crystal", crystal), ("crystal_cluster", crystal_cluster), ("moon_rocks", moon_rocks), ("rocket", rocket),
                   ("observatory", observatory), ("observatory_dome", observatory_dome), ("habitat_domes", habitat_domes), ("robot_factory", robot_factory),
                   ("solar_farm", solar_farm), ("sat_dish", sat_dish), ("fuel_depot", fuel_depot), ("ufo", ufo)):
        setattr(SB, nm, fn)


def main():
    patch()
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT, overrides={"floor_bit": floor_bit}, argv=("only=aerial,ground_spawn,ground_eggs,boss_view,ground_portal",),
                      capture_cams=True)
    O.finish()
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "SBV2", "Diagram", "Egg_Spot"))
    if "places_only" not in argv:
        IK.render_captured(OUT, "space_")
    IK.render_places(g["I"], OUT, "space_", [("Rocket + launch pad", 72, 22, 17), "Observatory", "Habitat domes", ("Robot factory", 44, 34, 4), "Fuel depot", "UFO landing"],
                     dist=48, height=16, look_up=9)


if __name__ == "__main__":
    main()
