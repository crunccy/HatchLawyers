# environment-redesign/pet_park_v2/ppv2_build.py - PET PARK v2 (2026-10-20, mr.robe's session; user's call: "do the same for
# the rest of the islands"), on crnuch's Ocean Shore v2 benchmark (kit/hl_v2.py = that benchmark as a frame): classic
# Roblox studs, ONE continuous mown lawn Barrister Bulldog roams (Config.Bosses: Ring 34 all round, Windup 1.4, every 3 s,
# WalkSpeed 44, Scale 3.5, Hitbox 18 wide, 26.6 tall), egg fields across it, the spawn dock SW, the purple escape portal
# NE, all scenery (mossy outcrops, park trees, ponds + a fall, the corgi + cat statues, dog houses, pet shops) OUTSIDE
# his reach. v1 (../pet_park/) is untouched.
#   Blender -b --python environment-redesign/pet_park_v2/ppv2_build.py [-- norender | -- only=aerial,diagram]
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
for p in (HERE, os.path.join(ROOT, "kit"), os.path.join(ROOT, "pet_park"), os.path.join(ROOT, "briefcase_bay_v2")):
    sys.path.insert(0, p)
import hl_kit as K
import hl_v2 as V
import pp_parts as PP  # (v1's pet pieces, drawn here with smooth classic primitives)
import bbv2_detail as BD  # (Briefcase Bay v2's park trees, topiary, flower beds)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
K.PAL.update({"lawn": (118, 214, 70), "lawn_dark": (92, 186, 56), "lawn_light": (146, 228, 92), "clover": (80, 170, 60),
              "daisy_white": (250, 250, 240), "ball_yellow": (214, 240, 60), "frisbee_red": (236, 70, 70), "frisbee_blue": (70, 140, 240),
              "lily": (70, 170, 80), "duck": (255, 220, 60), "duck_beak": (255, 140, 40), "lamp_green": (50, 110, 70)})
K.GLASS.update({"pond": (70, 190, 210), "pond_deep": (40, 150, 190)})
BULLDOG = {"Name": "Barrister Bulldog", "Model": "BarristerBulldog", "Scale": 3.5, "WalkSpeed": 44, "Chase": 0.9, "AttackEvery": 3,
           "Windup": 1.4, "Attack": "Ring", "Radius": 34, "HitboxWidth": 2 * 2.6 * 3.5, "Height": 7.6 * 3.5, "TriggerRange": 60}
I = V.V2(HERE, "PPV2", "Pet_Park_V2", BULLDOG, (-100.0, -88.0, 100.0, 98.0), seed=2202)
rng = I.rng
Z = I.Z

I.body(rim="dirt_rim", rim_top="moss", floor="lawn_dark", floor_top="lawn")
I.patches(("clover", "lawn_dark"), n=14)
FLOOR = I.outline(I.r_sand, n=300)


def band_x(yc):
    xs = [x0 + (yc - y0) * (x1 - x0) / (y1 - y0) for (x0, y0), (x1, y1) in zip(FLOOR, FLOOR[1:] + FLOOR[:1])
          if (y0 <= yc < y1) or (y1 <= yc < y0)]
    return (min(xs), max(xs)) if len(xs) >= 2 else None


for k in range(0, 13, 2):  # mowing stripes across the lawn (flush, walk-through)
    yc = -120 + k * 20
    ext = band_x(yc)
    if ext:
        x0, x1 = ext[0] + 8, ext[1] - 8
        I.dec.slab([(x0, yc - 5), (x1, yc - 5), (x1, yc + 5), (x0, yc + 5)], Z - 0.04, Z + 0.03, "lawn_light", chamfer=0.02)


def park_lamp(m, x, y, z):
    m.cyl(x, y, 0.7, z, z + 0.5, "lamp_green", segs=10)
    m.cyl(x, y, 0.25, z + 0.5, z + 5.2, "lamp_green", segs=8)
    m.sphere(x, y, z + 5.8, 0.75, 0.75, 0.75, "glow_lantern", seg=10, rings=6)
    m.cone(x, y, 0.9, z + 6.4, z + 7.0, "lamp_green", segs=10)


I.landmarks(lamp=park_lamp, boss_facing=135, spawn_name="the classic blue-and-white spawn pad at the end of a lamp-lit boardwalk")
REGIONS = {"Fetch Field": ((-68, 28), 24, "west, by the tennis-ball pile: mid risk"),
           "Bowl Green": ((0, -58), 22, "south, nearest the spawn: the safer start"),
           "Ball Pit Meadow": ((70, -22), 24, "east, under the outcrops: mid risk"),
           "Agility Lawn": ((-30, 72), 20, "north, on the bulldog's patrol line: high risk"),
           "Bone Garden": ((62, 66), 20, "north-east, on the way to the portal: high risk")}
I.eggs(REGIONS, preview_looks=("lawn_light", "sky_blue", "pink", "yellow", "orange"))


def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.22:
        m.sphere(x, y, z + 0.6, 0.6, 0.6, 0.6, "ball_yellow", seg=10, rings=6)  # a tennis ball
    elif roll < 0.4:
        for k in range(4):  # a trail of paw prints
            a = math.radians(rng.uniform(0, 360))
            m.cyl(x + math.cos(a) * k * 1.4, y + math.sin(a) * k * 1.4, 0.55, z, z + 0.05, "lawn_dark", segs=8)
    elif roll < 0.55:
        m.cyl(x, y, 1.1, z, z + 0.2, rng.choice(("frisbee_red", "frisbee_blue")), segs=16)  # a frisbee
    elif roll < 0.72 and (edge or rng.random() < 0.4):
        for k in range(rng.randint(3, 6)):  # daisies
            m.sphere(x + rng.uniform(-1.4, 1.4), y + rng.uniform(-1.4, 1.4), z + 0.35, 0.3, 0.3, 0.18, rng.choice(("daisy_white", "yellow")), seg=8, rings=4)
    elif roll < 0.82:
        m.brick(x, y, z, 1.6, 0.5, 0.45, "white", rot=rng.uniform(0, 180), bevel=0.2)  # a chew bone
        for sgn in (-1, 1):
            m.sphere(x + sgn * 0.8, y, z + 0.3, 0.35, 0.35, 0.3, "white", seg=8, rings=5)
    elif roll < 0.9 and edge:
        m.slab(V.V2.blob(x, y, rng.uniform(1.6, 2.6), 10), z - 0.04, z + 0.12, "clover", chamfer=0.02)


I.scatter(floor_bit, n=280)

# ------------------------------------------------------------------ the scenery ring (all clear of the bulldog's reach)
sc, wat, foam, veg = I.scenery_meshes()
ROCKS = ("rock_grey", "rock_grey_light", "rock_warm_grey")


def tree_or_bush(x, y, z, w, d):
    if rng.random() < 0.5 and w > 5:
        BD.park_tree(veg, x + rng.uniform(-1, 1), y + rng.uniform(-1, 1), z, rng.uniform(0.8, 1.1), rng.choice(("oak", "oak", "blossom", "conifer")))
    elif rng.random() < 0.7:
        V.D.bush(veg, x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5), z, rng.uniform(0.8, 1.2))


def colfn(x, y, h, w, d, yaw, kind):
    plants = kind in ("back", "terrace") or (kind == "link" and rng.random() < 0.4)
    I.column(sc, x, y, 0.4, h, w, d, yaw, ROCKS, cap=None if kind == "boulder" else "moss", cap_top=rng.choice(("moss", "moss_light")),
             drip="moss_dark", top_fn=tree_or_bush if plants else None)


def pond_rim(x, y, a):
    I.column(sc, x, y, 0.4, rng.uniform(2, 5), rng.uniform(4, 6), rng.uniform(3.5, 5), a, ROCKS, cap="moss", cap_top="moss", top_fn=None)


def pond_garden(x, y):
    if rng.random() < 0.6:  # lily pads
        sc.cyl(x, y, rng.uniform(0.9, 1.6), 0.8, 0.86, "lily", segs=12)
    else:  # a duck
        sc.sphere(x, y, 1.2, 0.8, 0.6, 0.55, "duck", seg=10, rings=6)
        sc.sphere(x + 0.6, y, 1.8, 0.4, 0.4, 0.4, "duck", seg=8, rings=5)
        sc.brick(x + 1.05, y, 1.65, 0.4, 0.3, 0.18, "duck_beak", bevel=0.05)


for deg, R, f, fall in ((150, 15, 0.32, None), (330, 14, 0.42, 8), (20, 12, 0.45, None), (265, 10, 0.4, None)):
    px, py = I.pool(deg, R, f, "pond", "pond_deep", "wet_sand", "moss", rim_fn=pond_rim, garden_fn=pond_garden, fall=fall, fall_look="foam_fall")
    if deg == 150:
        PP.wood_bridge(K.Frame(sc, px, py, deg, z=0.7), L=2 * R + 4, w=5)
        I.note("Duck pond + bridge", px, py, "a pond with lily pads, ducks and a little wooden bridge (scenery)")
# the landmarks round the ring, pushed out of his reach
for deg, fn, r, title in ((112, lambda F: PP.giant_corgi(F, 1.6), 18, "Giant corgi statue"),
                          (64, lambda F: PP.giant_cat(F, 1.4), 16, "Giant cat statue"),
                          (185, lambda F: PP.dog_house(F, "roof_blue", "red", "REX"), 8, "Dog house"),
                          (196, lambda F: PP.dog_house(F, "yellow", "roof_blue", "BELLA"), 8, "Dog house"),
                          (207, lambda F: PP.dog_house(F, "pink", "red", "MAX"), 8, "Dog house"),
                          (300, lambda F: PP.cat_tower(F), 10, "Cat tower"),
                          (350, lambda F: PP.rabbit_hutch(F), 10, "Rabbit hutch"),
                          (88, lambda F: PP.barkery(F), 18, "THE BARKERY"),
                          (128, lambda F: PP.paw_clinic(F), 18, "PAW CLINIC")):
    x, y, _ = I.push_out(deg, 0.55, r)
    if not I.free(x, y, r * 0.6):
        x, y, _ = I.push_out(deg + 6, 0.7, r)
    fn(K.Frame(sc, x, y, I.ang(x, y) - 90, z=0.6))  # (local -y faces the lawn)
    I.used.append((x, y, r))
    I.note(title, x, y, "scenery round the lawn, out of the bulldog's reach")
for deg in (40, 160, 240, 280, 318):  # bunny topiaries + bird houses
    x, y, _ = I.push_out(deg, 0.3, 4)
    if I.free(x, y, 3):
        (PP.bunny_topiary(K.Frame(sc, x, y, deg, z=0.6), 1.0) if deg % 2 == 0 else PP.bird_house(K.Frame(sc, 0, 0, 0, z=0.6), x, y))
        I.used.append((x, y, 4))
ANCH = [(0, 12), (24, 14), (40, 9), (56, 10), (72, 18), (100, 20), (130, 22), (150, 24), (172, 18), (194, 12), (206, 0), (242, 0),
        (252, 7), (280, 8), (305, 10), (330, 12), (348, 12), (360, 12)]
I.massifs(ANCH, colfn)


def plant(m, x, y, z, roll, lean):
    if roll < 0.34:
        BD.park_tree(m, x, y, z, rng.uniform(0.8, 1.2), rng.choice(("oak", "oak", "blossom", "conifer")))
        return 4.5
    if roll < 0.56:
        V.D.bush(m, x, y, z, rng.uniform(0.8, 1.3))
    elif roll < 0.68:
        BD.flower_bed(sc, m, x, y, z, rng.uniform(4, 7), rng.uniform(2.4, 3.6), rng.uniform(0, 180))
        return 3.5
    elif roll < 0.8:
        BD.topiary(m, x, y, z, rng.uniform(0, 90))
    elif roll < 0.9:
        V.D.hibiscus(m, x, y, z, rng.uniform(0.8, 1.1))
    else:
        V.D.grass_clump(m, x, y, z, rng.uniform(0.9, 1.3))
    return 2.0


I.ring_plants(plant, n=160)
I.LAYOUT["fx"]["gull_rings"] = [[0, 20, 150, 40]]
I.done_scenery()


def islet_tree(m, x, y, z):
    BD.park_tree(m, x + rng.uniform(-3, 3), y + rng.uniform(-3, 3), z, 0.9, rng.choice(("oak", "blossom")))


I.sky("day", islet=islet_tree)
STUDS = V.P.STUD_LOOKS | {"lawn", "lawn_dark", "lawn_light", "moss_light", "rock_warm_grey"}
I.studs(STUDS)
I.checks()
b = I.box
I.diagram([("SPAWN\nsafe zone", I.SPAWN[0] + 26, I.SPAWN[1] - 6), ("ESCAPE PORTAL", I.PORTAL[0] + 4, I.PORTAL[1] + 24),
           ("BULLDOG START", I.pad[0], I.pad[1] - 22), (f"BULLDOG ROAMS THE WHOLE\nRED BOX ({b[2] - b[0]:.0f} x {b[3] - b[1]:.0f})", 38, 34),
           *[(f"EGGS: {n}", c[0], c[1] + R + 6) for n, (c, R, _) in REGIONS.items()],
           ("RING = 34 all round\n(1.4 s windup)", -60, -40), ("SCENERY: outcrops, park,\nponds (not playable)", -175, 120), ("N", 0, 270)])
I.finish("pet_park_v2", argv=argv)
