# tools/blender/overhaul/island_pet_park.py - MAP MODEL OVERHAUL stage 5: PET PARK re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). The approved v2 island (environment-redesign/pet_park_v2/ppv2_build.py on the shared frame
# hl_v2.V2: lawn, outcrops, ponds, spawn dock, egg regions, the bulldog's box) runs UNCHANGED in the island_kit sandbox,
# with its dressing on the overhaul kit and its pet pieces remade here, same spots + sizes:
#   the giant corgi + giant cat statues, three dog houses (REX / BELLA / MAX), the cat tower, the rabbit hutch, bird
#   houses, bunny topiaries, the duck-pond bridge, THE BARKERY + PAW CLINIC, the lawn toys (tennis balls, frisbees, chew
#   bones, paw prints, daisies), ducks + lily pads, the park lamps, and the Return Home rock portal (island_kit).
#   Blender -b --factory-startup --python tools/blender/overhaul/island_pet_park.py -- <out_dir>
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
SCRIPT = os.path.join(ROOT, "pet_park_v2", "ppv2_build.py")
for _p in (os.path.dirname(SCRIPT), os.path.join(ROOT, "pet_park"), os.path.join(ROOT, "briefcase_bay_v2"), os.path.join(ROOT, "ocean_shore_v2")):
    sys.path.insert(0, _p)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rr = random.Random(2202)
O.K.PAL.update({"corgi": (240, 150, 60), "fur_white": (252, 248, 240), "cat_grey": (128, 134, 150), "eye_green": (90, 200, 90),
                "tennis": (214, 240, 60), "bone": (250, 238, 206), "duck": (255, 220, 60), "duck_beak": (255, 140, 40),
                "lily": (70, 170, 80), "lawn_dark": (92, 186, 56), "clover": (80, 170, 60), "sisal": (214, 186, 130),
                "house_blue": (70, 120, 220), "house_yellow": (255, 210, 60), "house_pink": (255, 140, 190), "roof_green": (70, 170, 70),
                "carrot": (255, 130, 30), "shop_cream": (250, 236, 206), "sky_blue": (110, 190, 250), "purple": (150, 90, 220)})
LOOK = {"roof_blue": "house_blue", "yellow": "house_yellow", "pink": "house_pink", "red": "red", "sky_blue": "sky_blue", "cream": "shop_cream",
        "white": "white", "purple": "purple", "sign_green": "roof_green"}


def F_place(F, x=0.0, y=0.0, s=1.0):
    return IK.place(F, x, y, 0.0, 0.0, s)


def rbox(name, look, c, size, r=0.5):
    """A soft rounded box (the statues' shapes)."""
    box(name, look, c, size, bevel=min(r, min(size) * 0.45), segs=3, smooth=True)


# ================================================================== statues
CORGI_S = 1.35


def giant_corgi(F, s=1.0):
    """A sitting corgi statue: the orange body (with its ears, legs and haunches) and the white patches (chest, muzzle,
    paws, blaze, tail) are each ONE fused solid, so nothing floats or pokes through; eyes / nose / tongue / collar sit
    half-sunk into the surface."""
    n = "PetCorgi"
    with F_place(F, s=s):
        lathe(n + "_Rock", "rock", [(9.0, 0.0), (9.0, 1.6, True), (8.6, 2.0), (8.2, 2.25, True), (0.0, 2.25)], segs=20)
        cyl(n + "_Moss", "moss", (0, 0, 2.2), 8.0, 0.55, segs=20, r_top=7.7)
        with at(0, 0, 2.75, s=CORGI_S):  # (the dog 1.35x on the same plinth, so the landmark reads from the spawn - audit N11)
            z = 0.0
            o, w = n + "_Orange", n + "_White"
            for sx in (-1, 1):
                rbox(o, "corgi", (sx * 1.55, -2.5, z + 2.6), (1.5, 1.5, 4.6), 0.6)          # front legs (into the body)
                rbox(o, "corgi", (sx * 2.4, 1.6, z + 1.6), (2.6, 4.6, 3.2), 1.1)            # haunches
                rbox(w, "fur_white", (sx * 1.55, -3.0, z + 0.45), (1.7, 2.2, 0.95), 0.42)   # front paws (under the legs)
                rbox(w, "fur_white", (sx * 2.5, -0.2, z + 0.4), (1.6, 2.0, 0.85), 0.38)     # back paws
                with at(sx * 1.45, -1.3, z + 8.15):                                          # ears: sunk into the head
                    prism(o, "corgi", [(-0.95, 0), (0.95, 0), (0.12 * sx, 3.0)], 0.9, rot=(0, -sx * 12, 0))
            rbox(o, "corgi", (0, 0.4, z + 3.4), (5.2, 6.2, 4.8), 1.8)                        # body
            rbox(o, "corgi", (0, -0.9, z + 5.6), (3.4, 3.4, 2.4), 1.0)                      # neck (body into head)
            rbox(o, "corgi", (0, -1.4, z + 7.2), (4.6, 4.2, 3.4), 1.4)                      # head
            rbox(w, "fur_white", (0, -1.75, z + 4.0), (3.0, 2.8, 4.2), 1.2)                # chest (just through the body's front)
            rbox(w, "fur_white", (0, -3.35, z + 6.5), (2.6, 1.9, 1.7), 0.75)               # muzzle (out of the head)
            rbox(w, "fur_white", (0, -3.1, z + 8.0), (1.0, 0.8, 1.8), 0.35)                # blaze
            sphere(w, "fur_white", (0, 3.4, z + 3.2), 1.1, sub=2)                          # tail fluff (into the rump)
            O.fuse(o, voxel=0.14, smooth_iters=3, faces=9000)
            O.fuse(w, voxel=0.12, smooth_iters=3, faces=5000)
            for sx in (-1, 1):
                with at(sx * 1.45, -1.62, z + 8.35):                                         # pink inner ears, on the ears' front
                    prism(n + "_Pink", "flower_pink", [(-0.5, 0.15), (0.5, 0.15), (0.08 * sx, 2.1)], 0.34, rot=(0, -sx * 12, 0))
                sphere(n + "_Eye", "panel_black", (sx * 1.05, -3.42, z + 7.7), 0.36, sub=2)
                sphere(n + "_Shine", "fur_white", (sx * 1.05 + 0.1, -3.7, z + 7.85), 0.1, sub=1)
            sphere(n + "_Nose", "panel_black", (0, -4.25, z + 6.95), 0.45, sub=2, scale=(1.2, 0.8, 0.8))
            rbox(n + "_Tongue", "flower_pink", (0.3, -4.05, z + 5.75), (0.8, 0.6, 0.9), 0.28)
            ring = [(2.05 * math.cos(a / 16 * math.tau), -1.25 + 1.95 * math.sin(a / 16 * math.tau), z + 5.7) for a in range(17)]
            tube(n + "_Collar", "red", ring, 0.3, segs=6, cap=False)
            sphere(n + "_Gold", "gold", (0, -3.25, z + 5.3), 0.45, sub=2)


def giant_cat(F, s=1.0):
    """A sitting cat statue: grey body + head + ears + tail fused into one solid, white chest / paws / muzzle fused into
    another; eyes, nose, whiskers and collar sit on the surface."""
    n = "PetCat"
    with F_place(F, s=s):
        box(n + "_Marble", "marble", (0, 0, 0.6), (7, 7, 1.2), bevel=0.2)
        box(n + "_Gold", "gold", (0, 0, 1.1614), (7.2, 7.2, 0.12))  # (gold top 0.03 proud of the marble's at s 1.4: never in its plane)
        z = 1.2
        g, w = n + "_Grey", n + "_White"
        rbox(g, "cat_grey", (0, 0.5, z + 2.55), (4.4, 4.6, 5.1), 1.6)                  # body
        rbox(g, "cat_grey", (0, -0.2, z + 5.2), (3.2, 3.0, 1.8), 0.8)                  # neck
        rbox(g, "cat_grey", (0, -0.3, z + 6.7), (4.2, 3.8, 3.4), 1.4)                  # head
        for sx in (-1, 1):
            cyl(g, "cat_grey", (sx * 1.2, -0.4, z + 7.6), 1.0, 2.2, segs=4, spin=45, r_top=0.08, smooth=False)  # ears, sunk in
        tail = [(2.0 + 0.4 * math.sin(t / 8 * 2.4), 1.8 - t * 0.25, z + 0.4 + t * 0.62) for t in range(9)]
        tail[0] = (1.2, 1.8, z + 0.9)                                                    # (starts inside the body)
        tube(g, "cat_grey", tail, [0.55 - 0.02 * t for t in range(9)], segs=10)
        rbox(w, "fur_white", (0, -1.45, z + 2.8), (2.6, 1.6, 3.6), 0.7)                # chest
        for sx in (-1, 1):
            rbox(w, "fur_white", (sx * 1.2, -1.75, z + 0.5), (1.3, 1.9, 1.0), 0.42)    # paws
        rbox(w, "fur_white", (0, -1.95, z + 6.2), (2.2, 0.9, 1.3), 0.4)                # muzzle
        O.fuse(g, voxel=0.12, smooth_iters=2, faces=8000)
        O.fuse(w, voxel=0.1, smooth_iters=2, faces=4000)
        for sx in (-1, 1):
            cyl(n + "_Pink", "flower_pink", (sx * 1.2, -0.95, z + 7.9), 0.45, 1.3, segs=4, spin=45, r_top=0.04, smooth=False)
            sphere(n + "_Eye", "eye_green", (sx * 0.9, -2.08, z + 7.1), 0.38, sub=2, scale=(1, 0.6, 1.1))
            box(n + "_Pupil", "panel_black", (sx * 0.9, -2.3, z + 7.1), (0.12, 0.06, 0.55))
            for k in range(2):
                tube(n + "_Whisker", "white", [(sx * 0.95, -2.35, z + 6.15 + k * 0.25), (sx * 2.5, -2.45, z + 6.3 + k * 0.4)], 0.045, segs=4)
        sphere(n + "_Pink", "flower_pink", (0, -2.42, z + 6.5), 0.22, sub=1)
        ring = [(1.95 * math.cos(a / 16 * math.tau), -0.25 + 1.65 * math.sin(a / 16 * math.tau), z + 5.25) for a in range(17)]
        tube(n + "_Collar", "house_blue", ring, 0.24, segs=6, cap=False)
        sphere(n + "_Gold", "gold", (0, -1.95, z + 4.95), 0.36, sub=2)


# ================================================================== pet houses
def dog_house(F, body="roof_blue", roof="red", name="REX"):
    n = "PetDogHouse"
    b, rf = LOOK.get(body, body), LOOK.get(roof, roof)
    with F_place(F):
        box(n + "_Base", "wood_deep", (0, 0, 0.25), (6.4, 7, 0.5), bevel=0.08)
        box(n + "_Wall" + b.title(), b, (0, 0.3, 2.7), (5.6, 6.0, 4.4), bevel=0.15)
        for sx in (-2.75, 2.75):
            for sy in (-2.65, 3.25):
                box(n + "_Trim", "white", (sx, sy, 2.7), (0.35, 0.35, 4.4), bevel=0.06)
        prism(n + "_Door", "panel_black", B.opening(2.6, 3.4, True), 0.12, c=(0, -2.72, 0.5))
        with at(0, -2.7, 0.5):
            B.ring(n + "_Trim", "white", B.opening(2.6, 3.4, True, grow=0.3), [(x, -0.03 if z == 0 else z) for x, z in B.opening(2.6, 3.4, True)],
                   -0.15, 0.05)  # (threshold 0.03 into the base, not in its top)
        prism(n + "_Wall" + b.title(), b, [(-2.8, 0), (2.8, 0), (0, 2.1)], 6.0, c=(0, 0.3, 4.9))
        for sgn in (-1, 1):
            box(n + "_Roof" + rf.title(), rf, (sgn * 1.62, 0.3, 6.0), (3.8, 7.2, 0.35), rot=(0, sgn * 35, 0), bevel=0.08)
        tube(n + "_Trim", "white", [(0, -3.3, 7.05), (0, 3.9, 7.05)], 0.16, segs=8)
        box(n + "_Plate", "white", (0, -2.78, 5.6), (3.0, 0.15, 0.8), bevel=0.06)      # (on the gable's face, y -2.7)
        text(name, "panel_black", (0, -2.88, 5.6), 0.5, extrude=0.015)
        lathe(n + "_Bowl", "red", [(0.0, 0.0), (0.75, 0.0, True), (1.0, 0.4, True), (0.85, 0.42), (0.7, 0.2)], segs=16, c=(3.6, -3.4, 0))
        for k in range(7):
            sphere(n + "_Kibble", "wood_warm", (3.6 + rr.uniform(-0.35, 0.35), -3.4 + rr.uniform(-0.35, 0.35), 0.16), 0.18, sub=1)
        chew_bone(n, (-2.6, -4.3, 0.0), 20)


def chew_bone(n, c, rz=0.0, s=1.0):
    with at(*c, rz=rz, s=s):
        tube(n + "_Bone", "bone", [(-0.7, 0, 0.3), (0.7, 0, 0.3)], 0.22, segs=8)
        for sx in (-0.8, 0.8):
            for sy in (-0.2, 0.2):
                sphere(n + "_Bone", "bone", (sx, sy, 0.3), 0.3, sub=1)


def cat_tower(F):
    n = "PetCatTower"
    with F_place(F):
        box(n + "_Carpet", "house_pink", (0, 0, 0.3), (6, 6, 0.6), bevel=0.15)
        for (x, y, h) in ((-1.6, -1.6, 9), (1.8, 1.4, 6), (1.8, -1.6, 12)):
            cyl(n + "_Sisal", "sisal", (x, y, 0.6), 0.6, h - 0.6, segs=12)
            for k in range(int((h - 1.0) / 0.7)):
                cyl(n + "_Rope", "rope", (x, y, 1.0 + k * 0.7), 0.64, 0.14, segs=10)
            lathe(n + "_Platform", "purple", [(0.0, h), (1.9, h), (2.0, h + 0.1), (2.0, h + 0.5), (1.85, h + 0.6, True), (0.0, h + 0.6)], segs=20,
                  c=(x, y, 0))  # (on top of its post)
        box(n + "_Box", "house_pink", (-0.4, 1.8, 4.3), (3.6, 3.0, 2.6), bevel=0.35, segs=2)
        cyl(n + "_Hole", "panel_black", (-0.4, 0.31, 4.3), 0.75, 0.06, segs=16, rot=(90, 0, 0))
        tube(n + "_String", "white", [(3.5, -1.6, 12.2), (3.55, -1.6, 10.6)], 0.045, segs=4)   # (from inside the top platform)
        sphere(n + "_Ball", "house_yellow", (3.55, -1.6, 10.25), 0.42, sub=2)


def bird_house(F, x, y, look="sky_blue", roof="red", h=6.0):
    n = "PetBirdHouse"
    with IK.place(F, x, y, 0.0):
        box(n + "_Post", "wood_deep", (0, 0, h / 2), (0.5, 0.5, h), bevel=0.06)
        box(n + "_House", "sky_blue", (0, 0, h + 1.0), (2.0, 2.0, 2.0), bevel=0.15)
        cyl(n + "_Roof", "red", (0, 0, h + 2.0), 1.75, 1.3, segs=4, spin=45, r_top=0.1, smooth=False)
        cyl(n + "_Hole", "panel_black", (0, -0.99, h + 1.2), 0.32, 0.06, segs=12, rot=(90, 0, 0))
        tube(n + "_Perch", "wood_deep", [(0, -1.0, h + 0.6), (0, -1.5, h + 0.6)], 0.07, segs=5)


def rabbit_hutch(F):
    n = "PetHutch"
    with F_place(F):
        for sx in (-1, 1):
            for sy in (-1, 1):
                box(n + "_Leg", "wood_deep", (sx * 4.6, sy * 2.1, 1.45), (0.6, 0.6, 2.9), bevel=0.06)
        box(n + "_Floor", "wood_deep", (0, 0, 2.75), (10.2, 5.2, 0.3), bevel=0.06)
        box(n + "_Body", "wood_warm", (0, 0, 4.6), (10, 5, 3.4), bevel=0.12)
        box(n + "_Frame", "wood_deep", (-2.2, -2.56, 4.6), (4.8, 0.2, 2.8), bevel=0.05)
        box(n + "_Inside", "panel_black", (-2.2, -2.6, 4.6), (4.2, 0.06, 2.3))  # (0.03 behind the frame's face, as reviewed: wood front)
        for k in range(9):
            cyl(n + "_Wire", "iron_light", (-4.2 + k * 0.5, -2.62, 3.4), 0.035, 2.4, segs=4)
        for k in range(4):
            tube(n + "_Wire", "iron_light", [(-4.5, -2.62, 3.6 + k * 0.6), (0.1, -2.62, 3.6 + k * 0.6)], 0.035, segs=4)
        box(n + "_Door", "wood_deep", (2.6, -2.56, 4.6), (3.4, 0.2, 2.6), bevel=0.06)
        for z in (3.8, 5.4):
            box(n + "_Iron", "iron", (1.2, -2.68, z), (0.5, 0.08, 0.18))
        for sgn in (-1, 1):
            box(n + "_Roof", "roof_green", (0, sgn * 1.38, 6.82), (10.6, 3.2, 0.3), rot=(-sgn * 25, 0, 0), bevel=0.08)
        prism(n + "_Body", "wood_warm", [(-2.5, 0), (2.5, 0), (0, 1.2)], 10.0, c=(0, 0, 6.3), rot=(0, 0, 90))
        box(n + "_Ramp", "wood_warm", (3.2, -3.9, 1.4), (1.6, 3.4, 0.2), rot=(-48, 0, 0), bevel=0.05)
        for k in range(3):
            with at(4.0 + k * 0.7, -3.4 - k * 0.3, 0.2, rz=k * 25):
                cyl(n + "_Carrot", "carrot", (0, 0, 0), 0.22, 1.2, segs=8, rot=(0, 90, 0), r_top=0.02)
                for j in range(3):
                    poly(n + "_Leaf", "leaf_sun", [(-0.05, 0, 0), (-0.55, -0.15 + j * 0.15, 0.25 + j * 0.1), (-0.5, 0.05 + j * 0.15, 0.2)], thick=0.03)


def bunny_topiary(F, s=1.0):
    n = "PetBunny"
    with F_place(F, s=s):
        box(n + "_Planter", "brick" if "brick" in O.K.PAL else "red", (0, 0, 0.8), (5, 5, 1.6), bevel=0.15)
        box(n + "_Rim", "limestone", (0, 0, 1.68), (5.3, 5.3, 0.2), bevel=0.06)
        box(n + "_Soil", "soil", (0, 0, 1.65), (4.4, 4.4, 0.2))
        blobs = [((0, 0.2, 3.6), 2.0), ((0, -0.4, 3.1), 1.6), ((0, 0, 2.1), 1.4), ((0, -1.4, 6.3), 1.45)]
        for sx in (-1, 1):
            blobs += [((sx * 0.6, -1.4, 8.0 + k * 0.7), 0.42) for k in range(4)]
        leafy(n + "Shape", blobs, look="hedge", voxel=0.16, faces=900, lumpy=0.07, seed=4)
        sphere(n + "_Tail", "fur_white", (0, 2.1, 3.6), 0.75, sub=2)


def wood_bridge(F, L=16, w=6):
    n = "PetBridge"
    arch = lambda xx: 0.9 + 1.4 * math.sin(math.pi * (xx + L / 2) / L)
    with F_place(F):
        k, x = 0, -L / 2
        while x < L / 2 - 0.1:
            xe = min(x + 1.15, L / 2)
            xm = (x + xe) / 2
            slope = math.degrees(math.atan2(arch(xe) - arch(x), xe - x))
            box(n + ("_Plank" if k % 2 else "_PlankDark"), "wood_warm" if k % 2 else "wood_deep", (xm, 0, arch(xm)), (xe - x + 0.08, w, 0.4),
                rot=(0, -slope, 0), bevel=0.05)
            x, k = xe, k + 1
        for sx in (-1, 1):  # stone footings under both ends (the bridge sits on them)
            box(n + "_Stone", "limestone_dark", (sx * (L / 2 + 0.3), 0, 0.55), (1.6, w + 0.6, 1.1), bevel=0.15)
        for sgn in (-1, 1):
            for j in range(5):
                xx = -L / 2 + j * L / 4
                box(n + "_Post", "wood_deep", (xx, sgn * (w / 2 - 0.2), arch(xx) + 1.3), (0.45, 0.45, 2.6), bevel=0.06)
                sphere(n + "_Post", "wood_deep", (xx, sgn * (w / 2 - 0.2), arch(xx) + 2.75), 0.3, sub=1)
            tube(n + "_Rail", "wood_warm", [(-L / 2 + t * L / 12, sgn * (w / 2 - 0.2), arch(-L / 2 + t * L / 12) + 2.35) for t in range(13)], 0.14, segs=6)


# ================================================================== the shops
def paw_print(n, look, c, rz=0.0, s=0.6):
    with at(*c, rz=rz, s=s):
        cyl(n, look, (0, 0, 0), 0.9, 0.1, segs=12)
        for dx, dy in ((-1.0, 1.1), (-0.35, 1.5), (0.35, 1.5), (1.0, 1.1)):
            cyl(n, look, (dx, dy, 0), 0.36, 0.1, segs=10)


def pet_shop(F, wall, roof, awning, label, extra=None):
    n = "PetShop" + label.replace(" ", "").replace("THE", "").title()
    wl, rf, aw = LOOK.get(wall, wall), LOOK.get(roof, roof), LOOK.get(awning, awning)
    with F_place(F):
        box(n + "_Base", "stone_light", (0, 0, 0.4), (24, 18, 0.8), bevel=0.12)
        box(n + "_Wall", wl, (0, 2, 5.3), (20, 12, 9.0))
        box(n + "_Base2", "stone_mid", (0, 2, 1.4), (20.3, 12.3, 1.2), bevel=0.06)
        B.cornice(n, 0, 2, 9.8, 20, 12, look="white")
        prism(n + "_Wall", wl, [(-10.2, 0), (10.2, 0), (0, 5.0)], 12.0, c=(0, 2, 10.8))
        for sgn in (-1, 1):
            box(n + "_Roof", rf, (sgn * 5.35, 2, 13.3), (11.6, 13.8, 0.45), rot=(0, sgn * 26, 0), bevel=0.1)
        tube(n + "_Ridge", "white", [(0, -4.9, 15.95), (0, 8.9, 15.95)], 0.2, segs=8)
        with at(0, -4.0, 0.8):
            for sx in (-6, 6):
                B.window(n + "Win", sx, 1.8, 4.0, 4.0, arch=False, shutters=aw)
            B.door(n + "Door", 0, 0, 3.4, 6.2, frame="white", leaf=aw, panel="white")
        for sgn in (-1, 1):
            with at(sgn * 10, 2, 0.8, rz=90 * sgn):
                B.window(n + "Win", 0, 2.0, 3.4, 4.0, arch=True)
        g = 12
        for i in range(g):  # the awning: its back edge ON the wall (y -4.0), a scalloped front edge
            x0, x1 = -10 + 20 * i / g, -10 + 20 * (i + 1) / g
            lk, nm = (aw, n + "_Awning") if i % 2 == 0 else ("white", n + "_AwningW")
            if abs((x0 + x1) / 2) < 2.0:
                continue
            poly(nm, lk, [(x0, -3.98, 8.3), (x1, -3.98, 8.3), (x1, -6.8, 7.0), (x0, -6.8, 7.0)], thick=0.12)
            xm = (x0 + x1) / 2
            poly(nm, lk, [(xm + (x1 - x0) / 2 * math.cos(math.pi * (1 - j / 6)), -6.75, 7.0 - 0.5 * math.sin(math.pi * j / 6)) for j in range(7)], thick=0.1)
        for sx in (-9.6, -2.4, 2.4, 9.6):  # iron brackets from the wall to the awning's front edge
            tube(n + "_Iron", "iron", [(sx, -4.0, 6.4), (sx, -5.6, 6.9), (sx, -6.7, 7.0)], 0.06, segs=5)
        box(n + "_Gold", "gold", (0, -4.15, 12.1), (13.5, 0.4, 3.1), bevel=0.12)   # (flush on the gable wall, y -4.0)
        box(n + "_Sign", aw, (0, -4.35, 12.1), (13, 0.3, 2.6), bevel=0.12)
        text(label, "white", (0, -4.53, 12.1), min(1.2, 11.5 / (0.72 * len(label))), extrude=0.03)
        for x in (-8.6, 8.6):
            box(n + "_FlowerBox", "wood_deep", (x, -6.4, 1.3), (4, 1.4, 1.0), bevel=0.08)
            for j in range(4):
                sphere(n + "_Leaf", "bush", (x - 1.5 + j, -6.4, 1.85), 0.42, sub=1, scale=(1, 1, 0.7))
                O.flower(n + "_Flower", ("flower_pink", "flower_yel", "speed_blue" if "speed_blue" in O.K.PAL else "flower_white", "flower_purple")[j],
                         n + "_FlowerMid", "flower_yel", O.pt((x - 1.5 + j, -6.5, 2.07)), Vector((0, -0.3, 1)).normalized(), r=0.28)
        for k in range(4):  # (on the paving, then on the path beyond it)
            yk = -8.5 - k * 2.4
            paw_print(n + "_Paw", "white", (-2 + (k % 2) * 4, yk, 0.8 if yk > -9.0 else 0.0), rz=0)
        if extra:
            extra(n)


def barkery(F):
    def treats(n):
        with at(0, 2, 15.5, s=2.2):  # (resting on the ridge)
            chew_bone(n, (0, 0, 0))
    pet_shop(F, "cream", "red", "red", "THE BARKERY", extra=treats)
    with F_place(F):
        for x in (-7, 7):
            with at(x, -11, 0, s=0.85):
                PR.cafe_table()


def paw_clinic(F):
    def medallion(n):
        cyl(n + "_Medal", "white", (0, -4.0, 12.3 + 3.2), 1.9, 0.3, segs=24, rot=(90, 0, 0))
        with at(0, -4.32, 15.3):
            cyl(n + "_PawPink", "flower_pink", (0, 0, -0.5), 0.75, 0.08, segs=14, rot=(90, 0, 0))
            for dx, dz in ((-0.85, 0.35), (-0.3, 0.75), (0.3, 0.75), (0.85, 0.35)):
                cyl(n + "_PawPink", "flower_pink", (dx, 0, dz), 0.28, 0.08, segs=10, rot=(90, 0, 0))
    pet_shop(F, "white", "sky_blue", "sky_blue", "PAW CLINIC", extra=medallion)


# ================================================================== lawn bits, pond bits, lamps
def park_lamp(m, x, y, z):
    IK.lamp_post(m, x, y, z, 5.6)


def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.22 and (not edge or IK.in_egg_area(x, y)):  # (a ball is round + egg-sized: only by the floor's rim, a flat bone elsewhere - audit N2)
        chew_bone("PetToy", (x, y, z), rr.uniform(0, 180))
    elif roll < 0.22:
        sphere("PetToy_Tennis", "tennis", (x, y, z + 0.6), 0.6, sub=2)
        tube("PetToy_Seam", "white", [(x + 0.6 * math.cos(a / 12 * math.tau), y + 0.25 * math.sin(a / 12 * math.tau),
                                       z + 0.6 + 0.55 * math.sin(a / 12 * math.tau)) for a in range(13)], 0.05, segs=4, cap=False)
    elif roll < 0.4:
        a = rr.uniform(0, math.tau)
        for k in range(4):
            paw_print("PetPaws", "lawn_dark", (x + math.cos(a) * k * 1.4, y + math.sin(a) * k * 1.4, z + 0.01), rz=math.degrees(a) - 90, s=0.45)
    elif roll < 0.55:
        lathe("PetToy_Frisbee" + ("Red" if roll < 0.47 else "Blue"), "red" if roll < 0.47 else "house_blue",
              [(0.0, 0.18), (0.9, 0.16), (1.1, 0.1, True), (1.05, 0.0), (0.9, 0.05)], segs=18, c=(x, y, z))
    elif roll < 0.72 and (edge or rr.random() < 0.4):
        IK.daisies(IK.O_NONE, x, y, z)
    elif roll < 0.82:
        chew_bone("PetToy", (x, y, z), rr.uniform(0, 180))
    elif roll < 0.9 and edge:
        import hl_v2 as V
        m.slab(V.V2.blob(x, y, rr.uniform(1.6, 2.6), 10), z - 0.04, z + 0.12, "clover", chamfer=0.02)


def pond_garden(x, y):
    if rr.random() < 0.6:
        r_ = rr.uniform(0.9, 1.6)
        prism("PetLily", "lily", [(r_ * math.cos(a), r_ * math.sin(a)) for a in [math.radians(20 + i * 340 / 14) for i in range(15)]] + [(0, 0)],
              0.06, c=(x, y, 0.84), rot=(90, 0, rr.uniform(0, 360)))
        if rr.random() < 0.4:
            O.flower("PetLotus", "flower_pink", "PetLotusMid", "flower_yel", (x, y, 0.95), Vector((0, 0, 1)), r=0.45)
    else:
        with at(x, y, 0.8, rz=rr.uniform(0, 360)):
            sphere("PetDuck", "duck", (0, 0, 0.45), 0.8, sub=2, scale=(1.25, 0.85, 0.7))
            sphere("PetDuck", "duck", (0.65, 0, 1.15), 0.48, sub=2)
            cyl("PetDuck_Beak", "duck_beak", (1.05, 0, 1.08), 0.2, 0.35, segs=8, rot=(0, 90, 0), r_top=0.06)
            for sy in (-0.3, 0.3):
                sphere("PetDuck_Eye", "panel_black", (0.95, sy, 1.3), 0.08, sub=1)
            prism("PetDuck", "duck", [(-1.0, 0.3), (-1.55, 0.95), (-0.7, 0.55)], 0.3)


# ================================================================== the mapping + run
def pond_rim(x, y, a):
    """The v2 pond rim (small rocks round each pond), minus the rocks where the duck pond's bridge lands (the 150° pond;
    the bridge runs along 150°): they're thrown away with the same random rolls, so nothing else moves (crnuch: overlaps)."""
    g = IK.CURRENT["g"]
    if g.get("deg") == 150 and abs((a - 150 + 90) % 180 - 90) < 26:
        IK.thrown_away(g["_v2_pond_rim"], x, y, a)
    else:
        g["_v2_pond_rim"](x, y, a)


def portal_side(sgn):
    """Beside the Return Home portal (palms on Ocean Shore): a pine with two bushes at its foot - a temperate park (audit N1)."""
    p = O.pt((sgn * 2.5, 5.0, 0))  # (back + out: its branches clear the arch's crags and legs)
    IK.tree(IK.O_NONE, p.x, p.y, p.z - 0.15, 1.35, "pine")
    IK.bush(IK.O_NONE, -sgn * 2.6, -1.6, 0.0, 1.1)
    IK.bush(IK.O_NONE, sgn * 1.4, -2.6, 0.0, 0.8)


def portal_preset():
    IK.PORTAL.update(rock="rock", top="rock_top", moss="moss", flowers=("flower_pink", "flower_yel"), fern=True, side=portal_side, side_local=True)


def patch():
    portal_preset()
    PP = importlib.import_module("pp_parts")
    BD = importlib.import_module("bbv2_detail")
    OD = importlib.import_module("osv2_detail")
    OP = importlib.import_module("osv2_parts")
    for nm, fn in (("giant_corgi", giant_corgi), ("giant_cat", giant_cat), ("dog_house", dog_house), ("cat_tower", cat_tower),
                   ("bird_house", bird_house), ("rabbit_hutch", rabbit_hutch), ("bunny_topiary", bunny_topiary), ("wood_bridge", wood_bridge),
                   ("barkery", barkery), ("paw_clinic", paw_clinic)):
        setattr(PP, nm, IK.landmark(fn, nm))  # (its real footprint: the cliffs + ring plants keep off it)
    BD.park_tree = lambda m, x, y, z0, s=1.0, kind="oak": IK.tree(m, x, y, z0, s, kind)
    BD.topiary = lambda m, x, y, z0, rot=0.0: IK.topiary(m, x, y, z0, rot)
    BD.flower_bed = lambda m, veg, x, y, z0, sx, sy, rot: IK.flower_bed(m, veg, x, y, z0, sx, sy, rot)
    OD.bush = lambda m, x, y, z0, s=1.0, look=None: IK.bush(m, x, y, z0, s)
    OD.hibiscus = lambda m, x, y, z0, s=1.0: IK.flower_bush(m, x, y, z0, s * 0.8, "flower_red")
    OD.grass_clump = lambda m, x, y, z0, s=1.0: IK.grass_clump(m, x, y, z0, s)
    OD.palm2 = lambda m, x, y, z0, style=None, h=None, lean=None: IK.tree(m, x, y, z0, (h or 10.0) / 10.0, "palm")
    OD.torch = lambda m, x, y, z0, h=5.0: IK.torch(m, x, y, z0, h)
    OD.crate = lambda m, x, y, z0, s=1.8, yaw=0.0: IK.crate(m, x, y, z0, s, yaw)
    OD.barrel = lambda m, x, y, z0, lying=False, yaw=0.0: IK.barrel(m, x, y, z0, lying, yaw)
    OP.escape_portal = lambda m, x, y, z, rot=0.0: IK.rock_portal(m, x, y, z, rot)
    import hl_v2 as V
    V.P.escape_portal = OP.escape_portal  # (hl_v2 holds its own reference to the module: same object, set anyway)


def main():
    patch()
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT, overrides={**IK.CLEAR_OVERRIDES, "pond_rim": pond_rim, "park_lamp": park_lamp, "floor_bit": floor_bit, "pond_garden": pond_garden},
                      argv=("only=aerial,ground_spawn,ground_eggs,boss_view,ground_portal",), capture_cams=True)
    O.finish()
    print("[island] kept clear of the landmarks:", IK.CLEARED)
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "PPV2", "Diagram", "Egg_Spot"))
    if "places_only" not in argv:
        IK.render_captured(OUT, "pet_")
    IK.render_places(g["I"], OUT, "pet_", ["Giant corgi statue", "THE BARKERY", "Dog house", "PAW CLINIC", "Giant cat statue", "Rabbit hutch"])


if __name__ == "__main__":
    main()
