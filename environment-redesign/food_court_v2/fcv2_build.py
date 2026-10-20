# environment-redesign/food_court_v2/fcv2_build.py - FOOD COURT v2 (2026-10-20, mr.robe's session; user's call: "do the same
# for the rest of the islands"), on crnuch's Ocean Shore v2 benchmark (kit/hl_v2.py): classic Roblox studs, ONE continuous
# giant picnic tablecloth Prosecutor Big Cheese rolls across (Config.Bosses: Line 110 x 22 at 120 studs/s, Windup 1.2,
# every 3.5 s, WalkSpeed 40, Scale 3.2, Hitbox 21 wide, 20.5 tall; Wheel Split lanes for 2+ players), egg fields across
# it, the spawn dock SW, the purple escape portal NE, all scenery (layered cake cliffs with frosting caps + chocolate
# drips, soda + chocolate pools and a soda fall, the restaurants, giant food, fruit orchards) OUTSIDE his reach.
# v1 (../food_court/) is untouched.
#   Blender -b --python environment-redesign/food_court_v2/fcv2_build.py [-- norender | -- only=aerial,diagram]
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
for p in (HERE, os.path.join(ROOT, "kit"), os.path.join(ROOT, "food_court")):
    sys.path.insert(0, p)
import hl_kit as K
import hl_v2 as V
import fc_parts as FP  # (v1's food pieces, drawn here with smooth classic primitives)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
K.PAL.update({"cloth": (252, 246, 236), "cloth_shade": (236, 226, 212), "cloth_red": (226, 62, 62), "cake": (250, 222, 180),
              "cake_dark": (232, 196, 146), "biscuit": (222, 168, 98), "choc_rock": (120, 70, 40), "frost_pink": (255, 160, 200),
              "frost_cream": (255, 244, 226), "crumb": (214, 160, 92), "napkin": (120, 200, 250), "icing_grass": (130, 220, 110)})
FP.K.GLASS.update({"soda_pool": (255, 150, 50), "choc_pool": (110, 60, 32)})
CHEESE = {"Name": "Prosecutor Big Cheese", "Model": "BigCheese", "Scale": 3.2, "WalkSpeed": 40, "Chase": 0.85, "AttackEvery": 3.5,
          "Windup": 1.2, "Attack": "Line", "Length": 110, "Width": 22, "LineSpeed": 120, "HitboxWidth": 2 * 3.3 * 3.2, "Height": 6.4 * 3.2,
          "TriggerRange": 60}
I = V.V2(HERE, "FCV2", "Food_Court_V2", CHEESE, (-115.0, -95.0, 115.0, 105.0), seed=4404)
rng = I.rng
Z = I.Z

I.body(rim="biscuit", rim_top="icing_grass", floor="cloth_shade", floor_top="cloth", under=("cake_dark", "choc_rock"),
       crags=("cake", "cake_dark", "biscuit"), crag_top="frost_cream", band=("choc_rock", "biscuit"), vine=None, root=None)
I.patches(("cloth_shade",), n=0)
for i in range(-10, 11):  # the tablecloth's red checks (flush, walk-through)
    for j in range(-10, 11):
        if (i + j) % 2:
            continue
        x, y = i * 12.0, I.center[1] + j * 12.0
        if I.in_sand(x, y, 10):
            I.dec.brick(x, y, Z - 0.04, 11.9, 11.9, 0.08, "cloth_red", bevel=0.0, studs=False)


def lamp(m, x, y, z):
    FP.condiment_lamp(K.Frame(m, 0, 0, 0, z=z), x, y, rng.choice(("ketchup", "mustard")))


I.landmarks(lamp=lamp, boss_facing=135, spawn_name="the classic blue-and-white spawn pad at the end of a condiment-lamp boardwalk")
REGIONS = {"Picnic Corner": ((-74, 30), 26, "west, by the cake cliffs: mid risk"),
           "Dessert Spot": ((4, -64), 24, "south, nearest the spawn: the safer start"),
           "Salad Bowl": ((80, -20), 26, "east, by the soda pools: mid risk"),
           "Snack Trail": ((-34, 80), 22, "north, on Big Cheese's roll line: high risk"),
           "Sundae Row": ((70, 74), 22, "north-east, on the way to the portal: high risk")}
I.eggs(REGIONS, preview_looks=("bun", "frosting", "gold", "lemon", "cheese"))


def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.28:  # crumbs
        for k in range(rng.randint(3, 6)):
            m.brick(x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5), z, rng.uniform(0.3, 0.6), rng.uniform(0.3, 0.6), 0.25, "crumb",
                    rot=rng.uniform(0, 90), bevel=0.05, studs=False)
    elif roll < 0.45:  # sprinkles
        for k in range(rng.randint(4, 8)):
            m.brick(x + rng.uniform(-1.6, 1.6), y + rng.uniform(-1.6, 1.6), z, 0.7, 0.22, 0.18, rng.choice(FP.SPRINKLES), rot=rng.uniform(0, 180),
                    bevel=0.05, studs=False)
    elif roll < 0.58:  # a napkin (flush)
        m.brick(x, y, z - 0.03, 2.6, 2.6, 0.1, "napkin", rot=rng.uniform(0, 90), bevel=0.0, studs=False)
    elif roll < 0.7:  # a grape or two
        for k in range(rng.randint(1, 3)):
            m.sphere(x + rng.uniform(-0.8, 0.8), y + rng.uniform(-0.8, 0.8), z + 0.5, 0.5, 0.5, 0.5, "grape", seg=10, rings=6)
    elif roll < 0.8:  # a cracker
        m.brick(x, y, z, 1.6, 1.6, 0.3, "cracker", rot=rng.uniform(0, 90), bevel=0.08, studs=False)
    elif roll < 0.9 and edge:  # a little cheese crumb pile
        m.brick(x, y, z, 1.0, 0.8, 0.5, "cheese", rot=rng.uniform(0, 90), bevel=0.1, studs=False)


I.scatter(floor_bit, n=280)

# ------------------------------------------------------------------ the scenery ring (all clear of Big Cheese's reach)
sc, wat, foam, veg = I.scenery_meshes()
ROCKS = ("cake", "cake_dark", "biscuit")


def treats(x, y, z, w, d):
    roll = rng.random()
    F = K.Frame(veg, 0, 0, 0, z=z)
    if roll < 0.3 and w > 5:
        FP.fruit_tree(F, x, y, rng.uniform(0.8, 1.1), rng.choice(("orange", "apple_red", "lemon")))
    elif roll < 0.5:
        FP.cupcake(F, x, y, rng.uniform(0.8, 1.1), rng.choice(("pink", "sky_blue", "lemon")), rng.choice(("cream_soft", "frosting")))
    elif roll < 0.65:
        FP.lollipop(F, x, y, rng.uniform(5, 8), rng.uniform(1.8, 2.6), rng.choice((("red", "white"), ("sky_blue", "white"), ("lemon", "frosting"))))
    elif roll < 0.75:
        FP.candy_cane(F, x, y, rng.uniform(5, 8), rng.uniform(0, 180), R=1.6)


def colfn(x, y, h, w, d, yaw, kind):
    plants = kind in ("back", "terrace") or (kind == "link" and rng.random() < 0.4)
    I.column(sc, x, y, 0.4, h, w, d, yaw, ROCKS, cap=None if kind == "boulder" else "frost_cream",
             cap_top=rng.choice(("frost_pink", "frost_cream", "frosting")), drip=rng.choice(("choc", "frost_pink", "frosting")),
             top_fn=treats if plants else None)


def soda_rim(x, y, a):
    I.column(sc, x, y, 0.4, rng.uniform(2, 5), rng.uniform(4, 6), rng.uniform(3.5, 5), a, ROCKS, cap="frost_cream", cap_top="frosting", drip="choc")


def soda_garden(x, y):
    if rng.random() < 0.6:  # ice cubes bobbing
        sc.brick(x, y, 0.4, 1.4, 1.4, 1.0, "glass", rot=rng.uniform(0, 90), bevel=0.15, studs=False)
    else:  # a lemon slice
        sc.cyl(x, y, 1.2, 0.8, 1.0, "lemon", segs=14)


for deg, R, f, fall, look, deep in ((150, 14, 0.32, None, "choc_pool", "choc_pool"), (330, 14, 0.42, 8, "soda_pool", "soda"),
                                    (22, 12, 0.45, None, "soda_pool", "soda"), (268, 10, 0.4, None, "choc_pool", "choc_pool")):
    I.pool(deg, R, f, look, deep, "biscuit", "frost_cream", rim_fn=soda_rim, garden_fn=soda_garden, fall=fall, fall_look="soda_fall")
for deg, fn, r, title in ((112, lambda F: FP.burger_barn(F), 18, "BURGER BARN"),
                          (64, lambda F: FP.pizza_palace(F), 18, "PIZZA PALACE"),
                          (180, lambda F: FP.donut_diner(F), 18, "DONUT DINER"),
                          (136, lambda F: FP.taco_tower(F), 14, "TACO TOWER"),
                          (300, lambda F: FP.giant_burger(F, 0, 0, 1.4), 12, "Giant burger"),
                          (350, lambda F: FP.giant_fries(F, 0, 0, 1.3, rot=-20), 9, "Giant fries"),
                          (88, lambda F: FP.soda_fountain(F), 12, "Soda-cup fountain"),
                          (318, lambda F: FP.ice_cream(F, 0, 0, 0, 2.2), 8, "Giant ice cream")):
    x, y, _ = I.push_out(deg, 0.55, r)
    if not I.free(x, y, r * 0.6):
        x, y, _ = I.push_out(deg + 6, 0.7, r)
    fn(K.Frame(sc, x, y, I.ang(x, y) - 90, z=0.6))
    I.used.append((x, y, r))
    I.note(title, x, y, "scenery round the tablecloth, out of Big Cheese's reach")
ANCH = [(0, 12), (24, 14), (40, 9), (56, 10), (72, 20), (100, 22), (130, 24), (150, 26), (172, 20), (194, 12), (206, 0), (242, 0),
        (252, 7), (280, 8), (305, 10), (330, 12), (348, 12), (360, 12)]
I.massifs(ANCH, colfn)


def plant(m, x, y, z, roll, lean):
    F = K.Frame(m, 0, 0, 0, z=z)
    if roll < 0.35:
        FP.fruit_tree(F, x, y, rng.uniform(0.9, 1.25), rng.choice(("orange", "apple_red", "lemon")))
        return 4.5
    if roll < 0.5:
        FP.lollipop(F, x, y, rng.uniform(6, 10), rng.uniform(2.2, 3.2), rng.choice((("red", "white"), ("sky_blue", "white"), ("lemon", "frosting"))))
        return 3.0
    if roll < 0.62:
        FP.cupcake(F, x, y, rng.uniform(0.9, 1.3), rng.choice(("pink", "sky_blue", "lemon")), rng.choice(("cream_soft", "frosting")))
        return 3.0
    if roll < 0.72:
        FP.candy_cane(F, x, y, rng.uniform(6, 9), rng.uniform(0, 180), R=1.8)
    elif roll < 0.82:
        FP.watermelon_slice(F, x, y, rng.uniform(3, 4.5), 1.4, rng.uniform(0, 180))
        return 3.5
    else:
        V.D.grass_clump(m, x, y, z, rng.uniform(0.9, 1.3))
    return 2.0


I.ring_plants(plant, n=150)
I.done_scenery()


def islet_thing(m, x, y, z):
    FP.fruit_tree(K.Frame(m, 0, 0, 0, z=z), x + rng.uniform(-3, 3), y + rng.uniform(-3, 3), 0.9, rng.choice(("orange", "apple_red", "lemon")))


I.sky("day", islet=islet_thing, islet_top=("biscuit", "icing_grass"), islet_rock=("cake_dark", "choc_rock"))
STUDS = V.P.STUD_LOOKS | {"cloth", "cloth_shade", "icing_grass", "cake", "cake_dark", "biscuit", "frost_cream", "frost_pink"}
I.studs(STUDS)
I.checks()
b = I.box
I.diagram([("SPAWN\nsafe zone", I.SPAWN[0] + 26, I.SPAWN[1] - 6), ("ESCAPE PORTAL", I.PORTAL[0] + 4, I.PORTAL[1] + 24),
           ("BIG CHEESE START", I.pad[0], I.pad[1] - 22), (f"BIG CHEESE ROLLS THE WHOLE\nRED BOX ({b[2] - b[0]:.0f} x {b[3] - b[1]:.0f})", 38, 34),
           *[(f"EGGS: {n}", c[0], c[1] + R + 6) for n, (c, R, _) in REGIONS.items()],
           ("ROLL = 110 x 22\n(stops at the box edge)", -60, -40), ("SCENERY: cake cliffs, soda,\nrestaurants (not playable)", -175, 120), ("N", 0, 270)])
I.finish("food_court_v2", sun=(4.0, (48, 6, -30)), sky=(0.24, 0.5, 0.95), horizon=(0.72, 0.8, 0.95), argv=argv)
