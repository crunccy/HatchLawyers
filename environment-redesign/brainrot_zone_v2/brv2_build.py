# environment-redesign/brainrot_zone_v2/brv2_build.py - BRAINROT ZONE v2 (2026-10-20, mr.robe's session; user's call: "do the
# same for the rest of the islands"), on crnuch's Ocean Shore v2 benchmark (kit/hl_v2.py): classic Roblox studs, ONE
# continuous checkerboard floor Judge Martello roams and slams (Config.Bosses: Slam radius 26 where you stood, Windup 1.1,
# every 3 s, WalkSpeed 40, Scale 3.4, Hitbox 22 wide, 19 tall), egg fields across it, the spawn dock SW, the purple escape
# portal NE, all scenery (purple crystal cliffs, goo pools + a goo fall, the twisty tower, the big screen, the melty mall,
# the upside-down house, giant dice, floating cubes + eyes, pixel trees) OUTSIDE his reach. A surreal island at dusk.
# v1 (../brainrot_zone/) is untouched.
#   Blender -b --python environment-redesign/brainrot_zone_v2/brv2_build.py [-- norender | -- only=aerial,diagram]
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
for p in (HERE, os.path.join(ROOT, "kit"), os.path.join(ROOT, "brainrot_zone")):
    sys.path.insert(0, p)
import hl_kit as K
import hl_v2 as V
import br_parts as BR  # (v1's surreal pieces, drawn here with smooth classic primitives)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
K.PAL.update({"rot_floor": (196, 166, 236), "rot_floor_dark": (160, 122, 214), "rot_tile": (132, 92, 204), "rot_rim": (96, 64, 146),
              "rot_rim_dark": (70, 46, 110), "rot_grass": (84, 214, 176), "rot_grass_light": (130, 236, 196), "rot_rock": (112, 84, 156),
              "rot_rock_dark": (80, 58, 116), "rot_rock_light": (152, 124, 196), "glitch_lime": (170, 250, 70), "mush_cap": (250, 90, 190),
              "mush_stem": (240, 230, 250)})
K.GLASS.update({"goo_pool": (190, 80, 255), "goo_deep": (130, 40, 220)})
MARTELLO = {"Name": "Judge Martello", "Model": "JudgeMartello", "Scale": 3.4, "WalkSpeed": 40, "Chase": 0.9, "AttackEvery": 3,
            "Windup": 1.1, "Attack": "Slam", "Radius": 26, "HopHeight": 6, "HitboxWidth": 2 * 3.3 * 3.4, "Height": 5.6 * 3.4, "TriggerRange": 60}
I = V.V2(HERE, "BRV2", "Brainrot_Zone_V2", MARTELLO, (-104.0, -90.0, 104.0, 100.0), seed=3303)
rng = I.rng
Z = I.Z

I.body(rim="rot_rim", rim_top="rot_grass", floor="rot_floor_dark", floor_top="rot_floor", under=("rot_rock", "rot_rock_dark"),
       crags=("rot_rock", "rot_rock_dark", "rot_rock_light"), crag_top="rot_grass", band=("rot_rim", "rot_rim_dark"),
       vine=("rot_grass", "rot_grass", "rot_grass_light"), root=None)
I.patches(("rot_tile",), n=0)
for i in range(-9, 10):  # the checkerboard: big flush tiles over the open floor (walk-through)
    for j in range(-9, 10):
        if (i + j) % 2:
            continue
        x, y = i * 12.0, I.center[1] + j * 12.0
        if I.in_sand(x, y, 10):
            I.dec.brick(x, y, Z - 0.04, 11.9, 11.9, 0.08, "rot_tile", bevel=0.0, studs=False)


def lamp(m, x, y, z):
    BR.wobble_lamp(K.Frame(m, 0, 0, 0, z=z), x, y, lean=rng.uniform(-10, 10), h=7.0, head=rng.choice(("glow_magenta", "glow_cyan")))


I.landmarks(lamp=lamp, boss_facing=135, spawn_name="the classic blue-and-white spawn pad at the end of a wobbly-lamp boardwalk")
REGIONS = {"Dice Plaza": ((-70, 30), 24, "west, by the giant dice: mid risk"),
           "Meme Meadow": ((0, -60), 22, "south, nearest the spawn: the safer start"),
           "Glitch Garden": ((72, -20), 24, "east, by the goo pools: mid risk"),
           "Upside Lane": ((-30, 74), 20, "north, under the upside-down house: high risk"),
           "Neon Nook": ((64, 68), 20, "north-east, on the way to the portal: high risk")}
I.eggs(REGIONS, preview_looks=("magenta", "lilac", "glitch_lime", "sky_blue", "violet"))


def floor_bit(m, x, y, z, edge, roll):
    if roll < 0.3:  # a glitch square (flush)
        m.brick(x, y, z - 0.03, rng.uniform(1.2, 2.6), rng.uniform(1.2, 2.6), 0.1, rng.choice(("magenta", "glitch_lime", "sky_blue", "violet")),
                rot=rng.uniform(0, 90), bevel=0.0, studs=False)
    elif roll < 0.45:  # a little die
        s = rng.uniform(0.8, 1.2)
        m.brick(x, y, z, s, s, s, "white", rot=rng.uniform(0, 90), bevel=0.12, studs=False)
        m.brick(x, y, z + s - 0.02, s * 0.3, s * 0.3, 0.06, "magenta", rot=rng.uniform(0, 90), bevel=0.0, studs=False)
    elif roll < 0.62 and (edge or rng.random() < 0.4):  # pixel flowers
        for k in range(rng.randint(2, 4)):
            fx, fy = x + rng.uniform(-1.2, 1.2), y + rng.uniform(-1.2, 1.2)
            m.brick(fx, fy, z, 0.2, 0.2, 1.0, "rot_grass", bevel=0.0, studs=False)
            m.brick(fx, fy, z + 1.0, 0.7, 0.7, 0.5, rng.choice(("magenta", "glitch_lime", "yellow", "sky_blue")), bevel=0.05, studs=False)
    elif roll < 0.74:  # a tiny eyeball
        m.sphere(x, y, z + 0.5, 0.5, 0.5, 0.5, "white", seg=10, rings=6)
        m.sphere(x + 0.35, y, z + 0.6, 0.22, 0.22, 0.22, "black", seg=8, rings=5)
    elif roll < 0.86 and edge:
        m.slab(V.V2.blob(x, y, rng.uniform(1.6, 2.8), 10), z - 0.04, z + 0.12, "rot_grass", chamfer=0.02)


I.scatter(floor_bit, n=280)

# ------------------------------------------------------------------ the scenery ring (all clear of Martello's reach)
sc, wat, foam, veg = I.scenery_meshes()
ROCKS = ("rot_rock", "rot_rock_light", "rot_rock_dark")


def mushroom(m, x, y, z, s):
    m.cyl(x, y, 0.5 * s, z, z + 3.0 * s, "mush_stem", segs=10)
    m.sphere(x, y, z + 3.2 * s, 2.0 * s, 2.0 * s, 1.1 * s, "mush_cap", seg=14, rings=8)
    for k in range(4):
        a = math.radians(k * 90 + 20)
        m.sphere(x + math.cos(a) * 1.2 * s, y + math.sin(a) * 1.2 * s, z + 3.9 * s, 0.3 * s, 0.3 * s, 0.2 * s, "glow_cyan", seg=8, rings=5)


def crystal(m, x, y, z, h, look):
    m.cone(x, y, 0.9, z, z + h, look, segs=6, r1=0.15)


def top_things(x, y, z, w, d):
    roll = rng.random()
    if roll < 0.35:
        BR.pixel_tree(K.Frame(veg, 0, 0, 0, z=z), x, y, rng.uniform(0.8, 1.1), rng.choice(("magenta", "violet", "lilac")), rng.choice(("lilac", "magenta")))
    elif roll < 0.6:
        for k in range(rng.randint(2, 4)):
            crystal(veg, x + rng.uniform(-w / 4, w / 4), y + rng.uniform(-d / 4, d / 4), z, rng.uniform(2.5, 5.5), rng.choice(("glow_magenta", "glow_cyan", "lilac")))
    elif roll < 0.8:
        mushroom(veg, x, y, z, rng.uniform(0.8, 1.2))


def colfn(x, y, h, w, d, yaw, kind):
    plants = kind in ("back", "terrace") or (kind == "link" and rng.random() < 0.4)
    I.column(sc, x, y, 0.4, h, w, d, yaw, ROCKS, cap=None if kind == "boulder" else "rot_grass", cap_top=rng.choice(("rot_grass", "rot_grass_light")),
             drip="glow_magenta" if rng.random() < 0.3 else "rot_grass_light", top_fn=top_things if plants else None)


def goo_rim(x, y, a):
    I.column(sc, x, y, 0.4, rng.uniform(2, 5), rng.uniform(4, 6), rng.uniform(3.5, 5), a, ROCKS, cap="rot_grass", cap_top="rot_grass")


def goo_garden(x, y):
    if rng.random() < 0.5:
        sc.sphere(x, y, 0.9, 0.8, 0.8, 0.8, "goo_deep", seg=10, rings=6)  # a bubble
    else:
        crystal(sc, x, y, 0.5, rng.uniform(1.5, 3.0), "glow_cyan")


for deg, R, f, fall in ((150, 14, 0.32, None), (330, 14, 0.42, 8), (22, 12, 0.45, None), (268, 10, 0.4, None)):
    I.pool(deg, R, f, "goo_pool", "goo_deep", "rot_rim", "rot_grass", rim_fn=goo_rim, garden_fn=goo_garden, fall=fall, fall_look="goo_fall")
for deg, fn, r, title in ((112, lambda F: BR.twisty_tower(F, w=14, floors=9), 14, "Twisty tower"),
                          (64, lambda F: BR.big_screen(F, w=24, d=12, h=24), 18, "The big screen"),
                          (180, lambda F: BR.melty_mall(F, w=26, d=16, h=10), 20, "Melty mall"),
                          (136, lambda F: BR.upside_down_house(F), 14, "Upside-down house"),
                          (300, lambda F: BR.leaning_tower(K.Frame(F.m, 0, 0, 0, z=0.6), *F.p(0, 0), lean=10, h=20), 10, "Leaning tower"),
                          (350, lambda F: BR.giant_dice(K.Frame(F.m, 0, 0, 0, z=0.6), *F.p(0, 0), s=5.0, rot=25), 8, "Giant dice"),
                          (88, lambda F: BR.neon_tower(F, w=12, d=12, h=32), 12, "Neon tower")):
    x, y, _ = I.push_out(deg, 0.55, r)
    if not I.free(x, y, r * 0.6):
        x, y, _ = I.push_out(deg + 6, 0.7, r)
    fn(K.Frame(sc, x, y, I.ang(x, y) - 90, z=0.6))
    I.used.append((x, y, r))
    I.note(title, x, y, "scenery round the floor, out of Martello's reach")
for k in range(10):  # floating cubes + eyes over the ring (high, never over the floor)
    deg = rng.uniform(0, 360)
    x, y = I.ring_pt(deg, rng.uniform(0.3, 0.9))
    if I.clear_of_reach(x, y, 4):
        (BR.floating_cube if k % 3 else BR.floating_eye)(K.Frame(sc, 0, 0, 0), x, y, rng.uniform(18, 30), *((rng.uniform(2.5, 4.0),) if k % 3 == 0 else (rng.uniform(2.5, 4), rng.choice(("lilac", "magenta", "sky_blue")), rng.uniform(0, 45))))
ANCH = [(0, 14), (24, 16), (40, 10), (56, 12), (72, 22), (100, 26), (130, 28), (150, 30), (172, 22), (194, 14), (206, 0), (242, 0),
        (252, 8), (280, 9), (305, 12), (330, 14), (348, 14), (360, 14)]
I.massifs(ANCH, colfn)


def plant(m, x, y, z, roll, lean):
    if roll < 0.3:
        BR.pixel_tree(K.Frame(m, 0, 0, 0, z=z), x, y, rng.uniform(0.8, 1.2), rng.choice(("magenta", "violet", "lilac")), rng.choice(("lilac", "magenta")))
        return 3.5
    if roll < 0.45:
        BR.upside_down_tree(K.Frame(m, 0, 0, 0, z=z), x, y, rng.uniform(0.7, 1.0))
        return 3.5
    if roll < 0.65:
        mushroom(m, x, y, z, rng.uniform(0.8, 1.4))
    elif roll < 0.8:
        for k in range(rng.randint(2, 4)):
            crystal(m, x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5), z, rng.uniform(2.5, 5.0), rng.choice(("glow_magenta", "glow_cyan", "lilac")))
    else:
        V.D.grass_clump(m, x, y, z, rng.uniform(0.9, 1.3))
    return 2.0


I.ring_plants(plant, n=150)
I.done_scenery()


def islet_thing(m, x, y, z):
    BR.pixel_tree(K.Frame(m, 0, 0, 0, z=z), x, y, 0.9, rng.choice(("magenta", "violet")), "lilac")


I.sky("day", islet=islet_thing, islet_top=("rot_rim", "rot_grass"), islet_rock=("rot_rock", "rot_rock_dark"))
STUDS = V.P.STUD_LOOKS | {"rot_floor", "rot_floor_dark", "rot_grass", "rot_grass_light", "rot_rock", "rot_rock_dark", "rot_rock_light"}
I.studs(STUDS)
I.checks()
b = I.box
I.diagram([("SPAWN\nsafe zone", I.SPAWN[0] + 26, I.SPAWN[1] - 6), ("ESCAPE PORTAL", I.PORTAL[0] + 4, I.PORTAL[1] + 24),
           ("MARTELLO START", I.pad[0], I.pad[1] - 22), (f"MARTELLO ROAMS THE WHOLE\nRED BOX ({b[2] - b[0]:.0f} x {b[3] - b[1]:.0f})", 38, 34),
           *[(f"EGGS: {n}", c[0], c[1] + R + 6) for n, (c, R, _) in REGIONS.items()],
           ("SLAM = 26 round where\nyou stood (1.1 s windup)", -60, -40), ("SCENERY: crystal cliffs,\ngoo, oddities (not playable)", -175, 120), ("N", 0, 270)])
I.finish("brainrot_zone_v2", sun=(3.6, (40, 8, -36)), sky=(0.36, 0.22, 0.62), horizon=(0.98, 0.62, 0.78), argv=argv)
