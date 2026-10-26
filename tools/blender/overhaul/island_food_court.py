# tools/blender/overhaul/island_food_court.py - MAP MODEL OVERHAUL stage 5: FOOD COURT re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). The approved v2 island (environment-redesign/food_court_v2/fcv2_build.py on hl_v2: the cake
# outcrops, soda + chocolate pools, spawn dock, egg regions, Big Cheese's box) runs UNCHANGED in the island_kit sandbox,
# its food pieces remade here at the same spots + sizes:
#   condiment-bottle lamps, fruit trees (one-green canopy, fruit on it), cupcakes, swirl lollipops, striped candy canes,
#   watermelon slices, BURGER BARN, PIZZA PALACE, DONUT DINER, TACO TOWER, the giant burger, giant fries, the soda-cup
#   fountain, the giant ice cream, and the floor's crumbs / sprinkles / grapes; the Return Home rock portal (island_kit).
#   Blender -b --factory-startup --python tools/blender/overhaul/island_food_court.py -- <out_dir> [places_only]
import bpy, math, os, sys, random, importlib
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import island_kit as IK
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, leafy
import props as PR

ROOT = IK.ROOT
SCRIPT = os.path.join(ROOT, "food_court_v2", "fcv2_build.py")
for _p in (os.path.dirname(SCRIPT), os.path.join(ROOT, "food_court")):
    sys.path.insert(0, _p)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rr = random.Random(4404)
TAU = math.tau
for k_, v_ in {"ketchup": (222, 40, 40), "mustard": (250, 200, 40), "bun": (230, 152, 62), "patty": (112, 62, 36), "cheese": (255, 206, 52),
               "tomato": (236, 62, 46), "lettuce": (132, 212, 62), "fry": (255, 212, 84), "crust": (222, 152, 72), "frosting": (255, 170, 200),
               "cream_soft": (255, 240, 214), "choc": (110, 60, 32), "waffle": (214, 150, 70), "apple_red": (230, 50, 50), "lemon": (255, 230, 70),
               "orange": (255, 150, 40), "pink": (255, 140, 190), "sky_blue": (110, 190, 250), "melon_red": (240, 70, 80), "melon_rind": (70, 170, 70),
               "grape": (140, 70, 200), "crumb": (214, 160, 90), "napkin": (250, 250, 250), "cracker": (230, 180, 100), "brick_red": (190, 70, 50),
               "veg_green": (78, 172, 52), "chrome": (210, 216, 226)}.items():
    O.K.PAL.setdefault(k_, v_)
O.ROUGH["chrome"] = 0.25
SPRINKLES = ("pink", "lemon", "sky_blue", "white", "lettuce", "orange")


def L(look):
    return look.title().replace("_", "")


def rbox(name, look, c, size, r=0.4, rot=(0, 0, 0)):
    box(name, look, c, size, rot=rot, bevel=min(r, min(size) * 0.45), segs=2)


def stick_spheres(objs, name, look, pts, r=0.5):
    """Spheres (fruit, cherries) sitting on a canopy's surface: ray-cast from pts (local frame) straight down."""
    bpy.context.view_layer.update()
    for p in pts:
        wp = O.pt(p)
        for ob in objs:
            inv = ob.matrix_world.inverted()
            hit, loc, nor, _ = ob.ray_cast(inv @ wp, (inv.to_3x3() @ Vector((0, 0, -1))).normalized())
            if hit:
                wl = ob.matrix_world @ loc
                nw = (ob.matrix_world.to_3x3() @ nor).normalized()
                c = wl + nw * r * 0.7
                import bmesh
                tmp = bmesh.new()
                bmesh.ops.create_icosphere(tmp, subdivisions=2, radius=r)
                for f in tmp.faces:
                    f.smooth = True
                O._merge(name, look, tmp, O.Matrix.Translation(c), world=True)
                break


# ================================================================== lamps, trees, sweets
def condiment_lamp(F, x, y, kind="ketchup"):
    n = "FoodLamp"
    with IK.place(F, x, y):
        lathe(n + "_" + L(kind), kind, [(1.2, 0.0), (1.32, 0.15), (1.35, 2.4, True)], segs=18)
        lathe(n + "_Label", "white", [(1.37, 2.4, True), (1.37, 4.0, True)], segs=18)
        lathe(n + "_" + L(kind), kind, [(1.35, 4.0, True), (1.35, 5.8), (1.15, 6.5), (0.7, 7.0), (0.5, 7.2, True)], segs=18)
        lathe(n + "_Nozzle", "white", [(0.55, 7.2), (0.42, 7.6), (0.28, 8.4), (0.18, 8.6)], segs=12)
        sphere(n + "_Glow", "lamp_glow", (0, 0, 9.1), 0.7, sub=2)
        text("KETCHUP" if kind == "ketchup" else "MUSTARD", kind, (0, -1.38, 3.2), 0.3, extrude=0.01)


def fruit_tree(m, x, y, s=1.0, fruit="orange"):
    i = next(IK.CNT)
    wx, wy, wz, _ = IK.where(m, x, y)
    with at(wx, wy, wz, rz=rr.uniform(0, 90), s=s):
        tube("FoodTree_Trunk", "wood_warm", [(0, 0, 0), (0.3, 0.1, 3.0), (0.1, 0, 6.0)], [0.8, 0.6, 0.5], segs=10)
        obs = leafy("FoodTree%d" % i, [((0, 0, 7.2), 3.4), ((2.2, 0.6, 6.5), 2.4), ((-2.0, -0.8, 6.6), 2.4), ((0.4, 1.9, 8.4), 2.0), ((-0.4, -1.6, 8.9), 1.9)],
                    look="bush", voxel=0.3, faces=800, lumpy=0.32, seed=i)
        stick_spheres(obs, "FoodTree_" + L(fruit), fruit, [(3.4 * math.cos(a), 3.4 * math.sin(a), 20) for a in [k * TAU / 7 + 0.3 for k in range(7)]], r=0.6)


def cupcake(F, x, y, s=1.0, wrapper="pink", frost="cream_soft"):
    n = "FoodCupcake"
    with IK.place(F, x, y, 0.0, rr.uniform(0, 90), s):
        lathe(n + "_" + L(wrapper), wrapper, [(0.0, 0.0), (2.6, 0.0, True), (3.4, 3.2, True), (0.0, 3.2)], segs=24, smooth=False)
        for k in range(12):
            a = k / 12 * TAU
            tube(n + "_Pleat", "white", [(2.62 * math.cos(a), 2.62 * math.sin(a), 0.1), (3.4 * math.cos(a), 3.4 * math.sin(a), 3.15)], 0.12, segs=4)
        lathe(n + "_" + L(frost), frost, [(3.5, 3.1), (3.7, 3.5), (3.3, 4.3), (2.9, 4.5), (3.0, 4.9), (2.4, 5.6), (1.9, 5.8), (1.8, 6.3), (1.0, 7.0), (0.4, 7.4), (0.0, 7.5)],
              segs=24)
        sphere(n + "_Cherry", "apple_red", (0, 0, 8.05), 0.85, sub=2)
        tube(n + "_Stem", "wood_deep", [(0, 0, 8.7), (0.3, 0, 9.4), (0.7, 0, 9.8)], 0.08, segs=5)
        for k in range(12):
            a = rr.uniform(0, TAU)
            rad = rr.uniform(1.2, 2.9)
            zz = 4.6 + (3.4 - rad) * 0.9
            lk = rr.choice(SPRINKLES)
            tube(n + "_Sprinkle" + L(lk), lk, [(rad * math.cos(a), rad * math.sin(a), zz), (rad * math.cos(a) + 0.4 * math.cos(a + 1.5), rad * math.sin(a) + 0.4 * math.sin(a + 1.5), zz + 0.05)],
                 0.09, segs=4)


def lollipop(F, x, y, h=10.0, r=4.0, looks=("red", "white"), rot=0.0):
    n = "FoodLolly"
    with IK.place(F, x, y, 0.0, rot):
        cyl(n + "_Stick", "white", (0, 0, 0), 0.35, h - r + 0.5, segs=10)
        cyl(n + "_" + L(looks[0]), looks[0], (0, 0.5, h), r, 1.0, segs=32, rot=(90, 0, 0))
        for sy in (-0.52, 0.52):
            pts = [(r * 0.92 * t * math.cos(t * 4.2 * TAU / 1.0 * 0.25), sy, h + r * 0.92 * t * math.sin(t * 4.2 * TAU * 0.25)) for t in [i / 60 for i in range(61)]]
            tube(n + "_" + L(looks[1]), looks[1], pts, 0.28, segs=6, cap=False)
        cyl(n + "_Band", looks[1], (0, 0.52, h), r + 0.05, 1.04, segs=32, rot=(90, 0, 0), cap=False)


def candy_cane(F, x, y, h=12.0, rot=0.0, R=2.5):
    n = "FoodCane"
    with IK.place(F, x, y, 0.0, rot):
        path = [(0, 0, z) for z in [i * h / 12 for i in range(13)]]
        path += [(R + R * math.cos(math.radians(180 - j * 18)), 0, h + R * math.sin(math.radians(180 - j * 18))) for j in range(1, 11)]
        path += [(2 * R, 0, h - 1.2)]
        for i in range(len(path) - 1):
            lk = "red" if i % 2 == 0 else "white"
            tube(n + "_" + L(lk), lk, [path[i], path[i + 1]], 0.62, segs=12, cap=(i == 0 or i == len(path) - 2))
            sphere(n + "_" + L(lk), lk, path[i + 1], 0.62, sub=1)


def watermelon_slice(F, x, y, R=6.0, depth=2.0, rot=0.0):
    n = "FoodMelon"
    with IK.place(F, x, y, 0.0, rot):
        arc = lambda rad: [(rad * math.cos(math.radians(a)), R - math.sqrt(max(0.0, R * R - (rad * math.cos(math.radians(a))) ** 2)) * 0 + rad * math.sin(math.radians(a)))
                           for a in range(0, 181, 12)]
        prism(n + "_Rind", "melon_rind", [(R * math.cos(math.radians(a)), R * math.sin(math.radians(a))) for a in range(0, 181, 12)], depth, rot=(180, 0, 0), c=(0, 0, R))
        prism(n + "_White", "cream_soft", [((R - 0.8) * math.cos(math.radians(a)), (R - 0.8) * math.sin(math.radians(a))) for a in range(0, 181, 12)], depth + 0.1,
              rot=(180, 0, 0), c=(0, 0, R + 0.03))  # (the cut face steps up 0.03 per layer, like the sides: no shared plane)
        prism(n + "_Red", "melon_red", [((R - 1.2) * math.cos(math.radians(a)), (R - 1.2) * math.sin(math.radians(a))) for a in range(0, 181, 12)], depth + 0.2,
              rot=(180, 0, 0), c=(0, 0, R + 0.06))
        for (px, pz) in ((-2.2, 4.0), (0, 3.2), (2.4, 4.4), (-1, 2.2), (1.2, 2.0)):
            for sgn in (-1, 1):
                sphere(n + "_Seed", "panel_black", (px * R / 6, sgn * (depth / 2 + 0.12), R - (R - pz * R / 6)), 0.2, sub=1, scale=(0.7, 0.4, 1.1))


# ================================================================== the eateries
def picnic_table(n, c, rot=0.0, umbrella="red"):
    with at(*c, rz=rot):
        box(n + "_Table", "wood_warm", (0, 0, 2.3), (5.0, 2.4, 0.3), bevel=0.06)
        for sy in (-1.8, 1.8):
            box(n + "_Table", "wood_warm", (0, sy, 1.3), (5.0, 0.8, 0.25), bevel=0.06)
        for sx in (-1.8, 1.8):
            box(n + "_Leg", "wood_deep", (sx, 0, 1.15), (0.3, 4.0, 0.3), rot=(0, 0, 0), bevel=0.04)
            for sy in (-1, 1):
                box(n + "_Leg", "wood_deep", (sx, sy * 0.9, 1.1), (0.3, 0.3, 2.3), rot=(sy * 22, 0, 0), bevel=0.04)
        cyl(n + "_Pole", "iron", (0, 0, 2.45), 0.09, 3.95, segs=6)
        for i in range(8):
            a0, a1 = i / 8 * TAU, (i + 1) / 8 * TAU
            lk = umbrella if i % 2 == 0 else "white"
            P = lambda rad, z, a: (rad * math.cos(a), rad * math.sin(a), z)
            poly(n + "_Umbrella" + L(lk), lk, [P(0, 6.3, 0), P(3.0, 5.0, a1), P(3.0, 5.0, a0)], thick=0.05)


def eatery(n, w, d, h, wall, trim, awning, label, sign_bg=None):
    """The shared restaurant shell (front = local -y): base, walls, windows, a door, a striped awning, the sign board."""
    box(n + "_Base", "stone_light", (0, 0, 0.4), (w + 4, d + 6, 0.8), bevel=0.12)
    rbox(n + "_Wall", wall, (0, 1.5, 0.8 + h / 2), (w, d, h), 0.25)
    rbox(n + "_Trim", trim, (0, 1.5, 0.8 + h + 0.4), (w + 1, d + 1, 0.8), 0.2)
    with at(0, -d / 2 + 1.5, 0.8):
        for k in range(int(w / 8)):
            x = -w / 2 + 4 + k * 8
            if abs(x) > 3:
                B.window(n + "Win", x, 1.4, 4.4, 4.4, arch=False, frame=trim if trim != "gold" else "white")
        B.door(n + "Door", 0, 0, 3.6, 6.2, frame=trim if trim != "gold" else "white", leaf=awning, panel="white")
    g = int(w / 1.8)
    for i in range(g):
        x0, x1 = -w / 2 + w * i / g, -w / 2 + w * (i + 1) / g
        lk = awning if i % 2 == 0 else "white"
        poly(n + "_Awning" + L(lk), lk, [(x0, -d / 2 + 1.52, 7.9), (x1, -d / 2 + 1.52, 7.9), (x1, -d / 2 - 1.4, 6.6), (x0, -d / 2 - 1.4, 6.6)], thick=0.12)
        xm = (x0 + x1) / 2
        poly(n + "_Awning" + L(lk), lk, [(xm + (x1 - x0) / 2 * math.cos(math.pi * (1 - j / 6)), -d / 2 - 1.42, 6.6 - 0.45 * math.sin(math.pi * j / 6)) for j in range(7)],
             thick=0.1)
    sw = min(w - 4, 20)
    rbox(n + "_Sign", sign_bg or awning, (0, -d / 2 + 0.9, 8.6 + 1.5), (sw, 0.5, 3.0), 0.2)
    rbox(n + "_SignTrim", "white", (0, -d / 2 + 1.05, 8.6 + 1.5), (sw + 0.5, 0.4, 3.5), 0.2)
    text(label, "white", (0, -d / 2 + 0.6, 10.1), min(1.5, (sw - 1) / (0.72 * len(label))), extrude=0.04)
    return 0.8 + h + 0.8


def burger_barn(F):
    n = "FoodBarn"
    with IK.place(F, 0, 0):
        box(n + "_Base", "stone_light", (0, 0, 0.4), (30, 26, 0.8), bevel=0.12)
        rbox(n + "_Wall", "brick_red", (0, 2, 6.3), (26, 18, 11), 0.2)
        for sx in (-1, 1):
            box(n + "_Trim", "white", (sx * 13.1, -6.9, 6.3), (0.8, 0.8, 11), bevel=0.06)
        prism(n + "_Wall", "brick_red", [(-13.2, 0), (13.2, 0), (0, 7.0)], 18.0, c=(0, 2, 11.8))
        for sgn in (-1, 1):
            box(n + "_Roof", "red", (sgn * 7.0, 2, 15.4), (15.6, 20.0, 0.45), rot=(0, sgn * 28, 0), bevel=0.1)
        tube(n + "_Ridge", "white", [(0, -8.03, 19.0), (0, 12.03, 19.0)], 0.25, segs=8)  # (ends 0.03 past the gables)
        with at(0, -7.05, 0.8):
            box(n + "_Door", "wood_deep", (0, -0.15, 4.0), (8, 0.3, 8), bevel=0.06)
            for sx in (-2, 2):
                box(n + "_Trim", "white", (sx, -0.35, 4.0), (0.5, 0.2, 8), bevel=0.04)
                for zz in (0.25, 3.8, 7.75):
                    box(n + "_Trim", "white", (sx, -0.36, zz), (4.0, 0.2, 0.4), bevel=0.04)
                box(n + "_Trim", "white", (sx, -0.38, 4.0), (5.0, 0.15, 0.4), rot=(0, 52 if sx > 0 else -52, 0), bevel=0.04)
            B.window(n + "Win", 0, 12.4, 3.6, 3.0, arch=False, shutters="wood_warm")
            for sx in (-9, 9):
                B.window(n + "Win", sx, 2.2, 4.0, 4.0, arch=False)
            rbox(n + "_Sign", "cream_soft", (0, -0.6, 10.8), (14, 0.5, 2.6), 0.2)
            text("BURGER BARN", "red", (0, -0.9, 10.8), 1.3, extrude=0.04)
        for (x, y, u) in ((-9, -12, "red"), (0, -13, "mustard"), (9, -12, "red")):
            picnic_table(n, (x, y, 0.8), 0, umbrella=u)


def pizza_palace(F, slice_sign=True):
    n = "FoodPizza"
    with IK.place(F, 0, 0):
        top = eatery(n, 28, 18, 10, "cream_soft", "white", "red", "PIZZA PALACE", "red")
        for k in range(9):
            if k % 2 == 0:
                rbox(n + "_Brick", "brick_red", (-14 + k * 3.5, -7.2, top + 0.8), (2.4, 1.2, 1.6), 0.15)
        for sx in (-1, 1):
            lathe(n + "_Brick", "brick_red", [(2.6, 0.8), (2.6, top + 4, True), (2.9, top + 4.2), (2.9, top + 4.5, True), (0.0, top + 4.5)], segs=16, c=(sx * 14, -7.5, 0))
            lathe(n + "_Roof", "red", [(2.7, top + 4.45), (3.15, top + 4.55), (2.4, top + 5.8), (1.2, top + 7.2), (0.0, top + 7.8)], segs=16,
                  c=(sx * 14, -7.5, 0))
            sphere(n + "_Gold", "gold", (sx * 14, -7.5, top + 8.1), 0.35, sub=1)
        if slice_sign:  # a slice of pizza standing on the roof
            with at(0, 4, top):
                prism(n + "_Crust", "crust", [(-5.8, 10.4), (5.8, 10.4), (6.2, 11.6), (-6.2, 11.6)], 1.8)
                prism(n + "_Cheese", "cheese", [(0, 0.2), (5.8, 10.4), (-5.8, 10.4)], 1.6)
                for (px, pz) in ((-2.0, 7.5), (1.8, 8.4), (0.0, 4.6), (-2.8, 9.6), (2.9, 6.6)):
                    cyl(n + "_Pepperoni", "tomato", (px, -0.85, pz), 0.85, 0.15, segs=14, rot=(90, 0, 0))
                cyl(n + "_Post", "iron", (0, 0.6, 0), 0.25, 2.0, segs=8)
        rbox(n + "_Brick", "brick_red", (9, 6, top + 3.5), (3.0, 3.0, 7.0), 0.15)
        rbox(n + "_Stone", "stone_mid", (9, 6, top + 7.3), (3.6, 3.6, 0.6), 0.1)


def donut(n, c, R=2.2, a=0.9, frost="frosting"):
    """A donut lying flat: a dough torus with a frosting top and sprinkles."""
    with at(*c):
        ring = [(R + a * math.cos(t), a * math.sin(t)) for t in [i / 16 * TAU for i in range(17)]]
        lathe(n + "_Dough", "waffle", [(r_, z_ + a) for r_, z_ in ring], segs=28)
        top = [(R + a * 1.04 * math.cos(t), a * 1.04 * math.sin(t) + a) for t in [i / 8 * math.pi for i in range(9)]]
        lathe(n + "_" + L(frost), frost, top, segs=28)
        for k in range(10):
            ang = rr.uniform(0, TAU)
            lk = rr.choice(SPRINKLES)
            box(n + "_Sprinkle" + L(lk), lk, ((R + rr.uniform(-0.4, 0.4)) * math.cos(ang), (R + rr.uniform(-0.4, 0.4)) * math.sin(ang), 2 * a + 0.05),
                (0.45, 0.14, 0.12), rot=(0, 0, rr.uniform(0, 180)), bevel=0.04)


def donut_diner(F):
    n = "FoodDonut"
    with IK.place(F, 0, 0):
        top = eatery(n, 26, 16, 9, "frosting", "white", "sky_blue", "DONUT DINER", "sky_blue")
        box(n + "_Chrome", "chrome", (0, -6.55, 7.0), (26.2, 0.3, 0.6), bevel=0.1)
        for k in range(13):
            box(n + "_Check" + ("White" if k % 2 else "Black"), "white" if k % 2 else "panel_black", (-12 + k * 2, -9.6, 0.9), (2, 2, 0.2))
        for k in range(3):
            donut(n, (-8 + k * 8, 3, top), frost=("frosting", "choc", "cream_soft")[k])


def taco_tower(F):
    n = "FoodTaco"
    with IK.place(F, 0, 0):
        box(n + "_Base", "stone_light", (0, 0, 0.4), (24, 24, 0.8), bevel=0.12)
        z = 0.8
        for k, (w, h, look) in enumerate(((20, 10, "orange"), (16, 9, "lemon"), (12, 8, "red"))):
            rbox(n + "_" + L(look), look, (0, 0, z + h / 2), (w, w, h), 0.25)
            rbox(n + "_Trim", "white", (0, 0, z + h + 0.3), (w + 1.2, w + 1.2, 0.6), 0.15)
            with at(0, -w / 2, z):
                for sx in (-1, 1):
                    B.window(n + "Win", sx * w / 4, 2.0, 3.0, h - 5, arch=False)
            z += h + 0.6
        with at(0, -10.0, 0.8):
            B.door(n + "Door", 0, 0, 3.4, 6.0, frame="white", leaf="veg_green", panel="white")
            rbox(n + "_Sign", "veg_green", (0, -0.4, 8.4), (12, 0.5, 2.2), 0.2)
            text("TACO TOWER", "white", (0, -0.7, 8.4), 1.15, extrude=0.04)
        with at(0, 0, z):  # the taco: a half-moon shell, filling poking out
            prism(n + "_Shell", "waffle", [(6.0 * math.cos(math.radians(a)), 6.0 - 6.0 * math.sin(math.radians(a)) * 0 + 6.0 * math.sin(math.radians(a)) - 6.0 + 6.0)
                                           for a in range(180, 361, 12)] if False else [(6.0 * math.cos(math.radians(a)), 6.0 + 6.0 * math.sin(math.radians(a))) for a in range(180, 361, 12)],
                  3.0)
            for k in range(9):
                x = -5 + k * 1.25
                lk = ("lettuce", "tomato", "cheese")[k % 3]
                sphere(n + "_" + L(lk), lk, (x, 0, 6.0 + (k % 2) * 0.3), 0.75, sub=1, scale=(1, 1.6, 0.8))


# ================================================================== the giant food
def giant_burger(F, x, y, s=1.0):
    n = "FoodBurger"
    R = 7.0
    with IK.place(F, x, y, 0.0, 0.0, s):
        lathe(n + "_Bun", "bun", [(0.0, 0.0), (R * 0.9, 0.0), (R * 0.97, 0.6), (R * 0.95, 1.5), (0.0, 1.6)], segs=40)
        lathe(n + "_Patty", "patty", [(0.0, 1.6), (R * 0.98, 1.6), (R * 1.02, 2.6), (R * 0.98, 3.6), (0.0, 3.6)], segs=40)
        with at(0, 0, 3.6, rz=20):
            box(n + "_Cheese", "cheese", (0, 0, 0.25), (R * 1.5, R * 1.5, 0.5), bevel=0.15)
            for sx in (-1, 1):
                for sy in (-1, 1):
                    tube(n + "_Cheese", "cheese", [(sx * R * 0.7, sy * R * 0.7, 0.2), (sx * R * 0.76, sy * R * 0.76, -0.8), (sx * R * 0.76, sy * R * 0.76, -1.5)],
                         [0.45, 0.4, 0.3], segs=8)
        lathe(n + "_Tomato", "tomato", [(0.0, 4.1), (R + 0.5, 4.1), (R + 0.6, 4.45), (R + 0.5, 4.8), (0.0, 4.8)], segs=40)
        frill = [((R + 0.7 + 0.35 * math.sin(a * 9)) * math.cos(a), (R + 0.7 + 0.35 * math.sin(a * 9)) * math.sin(a), 4.85 + 0.2 * math.cos(a * 9)) for a in [i / 72 * TAU for i in range(73)]]
        tube(n + "_Lettuce", "lettuce", frill, 0.45, segs=6, cap=False)
        prof = [(R * math.sqrt(max(0.0, 1 - t * t)), 4.9 + 5.4 * t) for t in [i / 10 for i in range(11)]]
        lathe(n + "_Bun", "bun", [(R * 1.02, 4.9)] + prof[1:-1] + [(0.0, 10.3)], segs=40)
        for k in range(16):
            rad = R * rr.uniform(0.2, 0.85)
            a = rr.uniform(0, TAU)
            z = 4.9 + 5.4 * math.sqrt(max(0.0, 1 - (rad / R) ** 2))
            sphere(n + "_Sesame", "cream_soft", (rad * math.cos(a), rad * math.sin(a), z + 0.05), 0.3, sub=1, scale=(1.5, 0.8, 0.5))


def giant_fries(F, x, y, s=1.0, rot=0.0, box_look="red", sections=4):
    n = "FoodFries"
    with IK.place(F, x, y, 0.0, rot, s):
        top = sections * 2.5
        lathe(n + "_Box", "red", [(0.0, 0.0), (3.6, 0.0, True), (4.6, top, True), (0.0, top)], segs=4, smooth=False)
        lathe(n + "_Trim", "white", [(4.62, top - 0.6), (4.7, top - 0.6), (4.7, top + 0.1), (4.62, top + 0.1)], segs=4, smooth=False)
        prism(n + "_Star", "lemon", O.star(1.5, 0.65), 0.2, c=(0, -3.0, top * 0.5), rot=(-8, 0, 0))
        for i in range(-3, 4):
            for j in range(-2, 3):
                if rr.random() < 0.8:
                    hgt = rr.uniform(4.0, 8.0)
                    box(n + "_Fry", "fry", (i * 0.95, j * 0.95, top - 1.5 + hgt / 2), (0.85, 0.85, hgt + 2), rot=(rr.uniform(-7, 7), rr.uniform(-7, 7), 0), bevel=0.12)


def ice_cream(F, x, y, z0=0.0, s=1.0, flavours=("pink", "cream_soft", "choc")):
    n = "FoodIceCream"
    with IK.place(F, x, y, z0, 0.0, s):
        lathe(n + "_Cone", "waffle", [(0.0, 0.0), (0.5, 0.2), (2.6, 7.0), (2.9, 7.2, True), (0.0, 7.2)], segs=24, smooth=False)
        for k in range(6):
            a = k / 6 * TAU
            tube(n + "_Grid", "crust", [(0.55 * math.cos(a), 0.55 * math.sin(a), 0.4), (2.65 * math.cos(a + 0.9), 2.65 * math.sin(a + 0.9), 7.0)], 0.08, segs=4)
            tube(n + "_Grid", "crust", [(0.55 * math.cos(a), 0.55 * math.sin(a), 0.4), (2.65 * math.cos(a - 0.9), 2.65 * math.sin(a - 0.9), 7.0)], 0.08, segs=4)
        for k, lk in enumerate(flavours):
            zc = 8.6 + k * 3.4
            sphere(n + "_" + L(lk), lk, (0, 0, zc), 2.8 - k * 0.2, sub=3, scale=(1, 1, 0.82))
            lathe(n + "_" + L(lk), lk, [(2.5 - k * 0.2, zc - 1.0), (2.9 - k * 0.2, zc - 1.35), (2.45 - k * 0.2, zc - 1.65)], segs=24)
        sphere(n + "_Cherry", "apple_red", (0, 0, 8.6 + 2 * 3.4 + 2.3), 0.8, sub=2)


def soda_fountain(F):
    n = "FoodSoda"
    with IK.place(F, 0, 0):
        lathe(n + "_Basin", "white", [(10.2, 0.0), (10.2, 1.6, True), (10.3, 1.7), (10.3, 2.0, True), (8.6, 2.0), (8.6, 0.6, True), (0.0, 0.6)], segs=48)
        lathe(n + "_Rim", "red", [(10.26, 1.6), (10.5, 1.65), (10.5, 2.05), (10.26, 2.1)], segs=48)
        cyl(n + "_Soda", "soda" if "soda" in O.K.GLASS or "soda" in O.K.PAL else "water", (0, 0, 0.6), 8.6, 0.7, segs=48)
        bands = 7
        for k in range(bands):
            za, zb = 1.3 + 11.6 * k / bands, 1.3 + 11.6 * (k + 1) / bands
            ra, rb = 3.4 + 1.0 * k / bands, 3.4 + 1.0 * (k + 1) / bands
            lk = "red" if k % 2 == 0 else "white"
            lathe(n + "_Cup" + L(lk), lk, [(ra, za), (rb, zb)], segs=32)
        lathe(n + "_Lid", "white", [(4.25, 12.85), (4.75, 13.2), (4.6, 13.5), (3.8, 13.8), (0.0, 13.9)], segs=32)
        straw = [(1.4, 0.8, 12.6), (1.4, 0.8, 18.0), (1.6, 0.8, 19.6), (2.4, 0.8, 20.6), (3.6, 0.8, 21.0)]
        tube(n + "_Straw", "red", straw, 0.55, segs=12)
        for k in range(4):
            a = math.radians(45 + 90 * k)
            ca, sa = math.cos(a), math.sin(a)
            tube(n + "_Nozzle", "white", [(4.6 * ca, 4.6 * sa, 9.6), (5.6 * ca, 5.6 * sa, 9.6)], 0.32, segs=10)
            tube(n + "_Pour", "water_fall", [(5.6 * ca, 5.6 * sa, 9.5), (6.2 * ca, 6.2 * sa, 7.0), (6.4 * ca, 6.4 * sa, 1.3)], [0.3, 0.28, 0.26], segs=8)
            lathe(n + "_Foam", "cream_soft", [(0.3, 1.25), (1.0, 1.35), (1.2, 1.5), (0.8, 1.6), (0.4, 1.5)], segs=14, c=(6.4 * ca, 6.4 * sa, 0))


# ================================================================== the script's own bits
def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.28:
        for k in range(rr.randint(3, 6)):
            sphere("FoodCrumb", "crumb", (x + rr.uniform(-1.5, 1.5), y + rr.uniform(-1.5, 1.5), z + 0.12), rr.uniform(0.2, 0.35), sub=1, scale=(1, 0.8, 0.6))
    elif roll < 0.45:
        for k in range(rr.randint(4, 8)):
            lk = rr.choice(SPRINKLES)
            a = rr.uniform(0, 180)
            px, py = x + rr.uniform(-1.6, 1.6), y + rr.uniform(-1.6, 1.6)
            tube("FoodSprinkle" + L(lk), lk, [(px - 0.3 * math.cos(math.radians(a)), py - 0.3 * math.sin(math.radians(a)), z + 0.1),
                                             (px + 0.3 * math.cos(math.radians(a)), py + 0.3 * math.sin(math.radians(a)), z + 0.1)], 0.1, segs=4)
    elif roll < 0.58:
        box("FoodNapkin", "napkin", (x, y, z + 0.02), (2.6, 2.6, 0.08), rot=(0, 0, rr.uniform(0, 90)), bevel=0.02)
    elif roll < 0.7:
        for k in range(rr.randint(1, 3)):
            sphere("FoodGrape", "grape", (x + rr.uniform(-0.8, 0.8), y + rr.uniform(-0.8, 0.8), z + 0.5), 0.5, sub=2)
    elif roll < 0.8:
        box("FoodCracker", "cracker", (x, y, z + 0.15), (1.6, 1.6, 0.3), rot=(0, 0, rr.uniform(0, 90)), bevel=0.08)
        for i in range(2):
            for j in range(2):
                cyl("FoodCrackerHole", "crumb", (x - 0.35 + i * 0.7, y - 0.35 + j * 0.7, z + 0.29), 0.08, 0.03, segs=6)
    elif roll < 0.9 and edge:
        box("FoodCheeseBit", "cheese", (x, y, z + 0.25), (1.0, 0.8, 0.5), rot=(0, 0, rr.uniform(0, 90)), bevel=0.12)


def soda_garden(x, y):
    if rr.random() < 0.6:
        box("FoodIceCube", "glass", (x, y, 0.9), (1.4, 1.4, 1.0), rot=(rr.uniform(-10, 10), rr.uniform(-10, 10), rr.uniform(0, 90)), bevel=0.2, segs=2)
    else:
        with at(x, y, 0.8, rz=rr.uniform(0, 360)):
            cyl("FoodLemon", "lemon", (0, 0, 0), 1.2, 0.25, segs=16)
            cyl("FoodLemonPulp", "cream_soft", (0, 0, 0.24), 1.0, 0.03, segs=16)
            for k in range(8):
                a = k / 8 * TAU
                tube("FoodLemon", "lemon", [(0.15 * math.cos(a), 0.15 * math.sin(a), 0.29), (0.95 * math.cos(a), 0.95 * math.sin(a), 0.29)], 0.05, segs=4)


# ================================================================== the mapping + run
def patch():
    IK.patch_v2_common()
    FP = importlib.import_module("fc_parts")
    for nm, fn in (("condiment_lamp", condiment_lamp), ("fruit_tree", fruit_tree), ("cupcake", cupcake), ("lollipop", lollipop), ("candy_cane", candy_cane),
                   ("watermelon_slice", watermelon_slice), ("burger_barn", burger_barn), ("pizza_palace", pizza_palace), ("donut_diner", donut_diner),
                   ("taco_tower", taco_tower), ("giant_burger", giant_burger), ("giant_fries", giant_fries), ("ice_cream", ice_cream),
                   ("soda_fountain", soda_fountain)):
        setattr(FP, nm, fn)


def main():
    patch()
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT, overrides={"floor_bit": floor_bit, "soda_garden": soda_garden},
                      argv=("only=aerial,ground_spawn,ground_eggs,boss_view,ground_portal",), capture_cams=True)
    O.finish()
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "FCV2", "Diagram", "Egg_Spot"))
    if "places_only" not in argv:
        IK.render_captured(OUT, "food_")
    IK.render_places(g["I"], OUT, "food_", ["BURGER BARN", "PIZZA PALACE", "DONUT DINER", "TACO TOWER", "Giant burger", "Soda-cup fountain"],
                     dist=42, height=14, look_up=8)


if __name__ == "__main__":
    main()
