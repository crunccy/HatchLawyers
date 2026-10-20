# environment-redesign/space_base_v2/sbv2_build.py - SPACE BASE v2 (2026-10-20, mr.robe's session; user's call: "do the same
# for the rest of the islands"), on crnuch's Ocean Shore v2 benchmark (kit/hl_v2.py): classic Roblox studs, ONE continuous
# moon-plate floor Chief Justice Eclipse roams (Config.Bosses: Pull r 44 (inner 12, 2 s at 16) and Ring r 38, Windup 1.4,
# every 2.5 s, WalkSpeed 44, Scale 3.2, Hitbox 15 wide, 33 tall), egg fields across it, the spawn dock SW, the purple
# escape portal NE, all scenery (violet moon-rock cliffs with crystal caps, plasma pools + a plasma fall, the rocket, the
# observatory, the habitat domes, the robot factory, the dish, the UFO, alien plants) OUTSIDE his reach. Under stars and
# a ringed planet (the camera sees deep space). v1 (../space_base/) is untouched.
#   Blender -b --python environment-redesign/space_base_v2/sbv2_build.py [-- norender | -- only=aerial,diagram]
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
for p in (HERE, os.path.join(ROOT, "kit"), os.path.join(ROOT, "space_base")):
    sys.path.insert(0, p)
import hl_kit as K
import hl_v2 as V
import sb_parts as SB  # (v1's space pieces, drawn here with smooth classic primitives)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
K.PAL.update({"moon_plate": (196, 190, 214), "moon_plate_dark": (166, 160, 188), "regolith_grass": (120, 210, 190)})
ECLIPSE = {"Name": "Chief Justice Eclipse", "Model": "Eclipse", "Scale": 3.2, "WalkSpeed": 44, "Chase": 0.95, "AttackEvery": 2.5,
           "Windup": 1.4, "Attack": ["Pull", "Ring"], "Radius": 44, "Inner": 12, "PullTime": 2, "PullSpeed": 16, "RingRadius": 38,
           "HitboxWidth": 2 * 2.4 * 3.2, "Height": 10.3 * 3.2, "TriggerRange": 60}
I = V.V2(HERE, "SBV2", "Space_Base_V2", ECLIPSE, (-92.0, -80.0, 92.0, 90.0), seed=5505)
rng = I.rng
Z = I.Z

I.body(rim="moon_dark", rim_top="moon", floor="moon_plate_dark", floor_top="moon_plate", under=("rock_violet", "rock_violet_dark"),
       crags=("rock_violet", "rock_violet_dark", "moon_dark"), crag_top="moon_light", band=("moon_dark", "rock_violet"),
       hang=("rock_violet", "rock_violet_dark", "moon_dark"), vine=None, root=None)
I.patches(("moon_plate_dark", "moon_light"), n=18)
for k in range(9):  # shallow flush craters on the plate (walk-through rings)
    for _ in range(60):
        x, y = rng.uniform(I.box[0], I.box[2]), rng.uniform(I.box[1], I.box[3])
        if I.in_sand(x, y, 14) and math.hypot(x - I.pad[0], y - I.pad[1]) > 24:
            R = rng.uniform(4, 8)
            I.dec.ring(R, R + 1.4, Z - 0.04, Z + 0.1, "moon_light", cx=x, cy=y, segs=28)
            I.dec.cyl(x, y, R, Z - 0.04, Z + 0.02, "crater", segs=28)
            break
pts = [(rng.uniform(-60, 60), rng.uniform(-50, 60)) for _ in range(9)]  # a constellation inlaid in the plate
for (ax, ay), (bx, by) in zip(pts, pts[1:]):
    if math.hypot(bx - ax, by - ay) < 70:
        I.dec.brick((ax + bx) / 2, (ay + by) / 2, Z - 0.03, math.hypot(bx - ax, by - ay), 0.5, 0.08, "gold",
                    rot=math.degrees(math.atan2(by - ay, bx - ax)), bevel=0.0, studs=False)
for (x, y) in pts:
    I.dec.cyl(x, y, 1.0, Z - 0.03, Z + 0.06, "glow_white", segs=12)


def lamp(m, x, y, z):
    SB.beacon_lamp(K.Frame(m, 0, 0, 0, z=z), x, y, h=6.0, glow=rng.choice(("glow_cyan", "glow_magenta")))


I.landmarks(lamp=lamp, boss_facing=135, spawn_name="the classic blue-and-white spawn pad at the end of a beacon-lit gantry")
REGIONS = {"Crater Rim": ((-60, 26), 22, "west, by the moon-rock cliffs: mid risk"),
           "Landing Lawn": ((0, -52), 20, "south, nearest the spawn: the safer start"),
           "Crystal Flats": ((62, -14), 22, "east, by the plasma pools: mid risk"),
           "Orbit Walk": ((-26, 66), 18, "north, inside his pull: high risk"),
           "Nebula Patch": ((54, 62), 18, "north-east, on the way to the portal: high risk")}
I.eggs(REGIONS, preview_looks=("space_egg", "crystal_cyan", "gold", "crystal_pink", "space_purple"))


def floor_bit(m, x, y, z, edge, roll):
    F = K.Frame(m, 0, 0, 0, z=z)
    if roll < 0.3:  # moon pebbles
        for k in range(rng.randint(2, 4)):
            m.rock(x + rng.uniform(-1.2, 1.2), y + rng.uniform(-1.2, 1.2), z, rng.uniform(0.5, 1.1), rng.uniform(0.4, 0.9), rng.uniform(0.3, 0.7),
                   rng.choice(("moon_dark", "rock_violet")), rot=rng.uniform(0, 90))
    elif roll < 0.45:  # a tiny crystal
        SB.crystal(F, x, y, rng.uniform(1.2, 2.2), 0.4, rng.choice(("crystal_cyan", "crystal_pink", "crystal_violet")), "glow_cyan")
    elif roll < 0.58:  # a glowing floor stud light (flush)
        m.cyl(x, y, 0.5, z - 0.03, z + 0.05, rng.choice(("glow_cyan", "glow_magenta")), segs=10)
    elif roll < 0.72 and (edge or rng.random() < 0.4):  # little alien sprouts
        for k in range(rng.randint(2, 3)):
            fx, fy = x + rng.uniform(-1, 1), y + rng.uniform(-1, 1)
            m.brick(fx, fy, z, 0.18, 0.18, 1.0, "alien_lime", bevel=0.0, studs=False)
            m.sphere(fx, fy, z + 1.2, 0.3, 0.3, 0.3, rng.choice(("glow_lime", "glow_pink", "glow_cyan")), seg=8, rings=5)
    elif roll < 0.84 and edge:
        m.slab(V.V2.blob(x, y, rng.uniform(1.6, 2.6), 10), z - 0.04, z + 0.12, "moon_light", chamfer=0.02)


I.scatter(floor_bit, n=260)

# ------------------------------------------------------------------ the scenery ring (all clear of Eclipse's pull)
sc, wat, foam, veg = I.scenery_meshes()
ROCKS = ("rock_violet", "rock_violet_dark", "moon_dark")


def tops(x, y, z, w, d):
    F = K.Frame(veg, 0, 0, 0, z=z)
    roll = rng.random()
    if roll < 0.4:
        SB.crystal_cluster(F, x, y, rng.uniform(0.5, 0.8), rng.choice((("crystal_cyan", "glow_cyan"), ("crystal_pink", "glow_pink"), ("crystal_violet", "glow_purple"))))
    elif roll < 0.6:
        SB.alien_mushroom(F, x, y, rng.uniform(0.8, 1.1), rng.choice(("alien_pink", "alien_purple", "alien_teal")), rng.choice(("glow_pink", "glow_cyan")))
    elif roll < 0.72:
        SB.bulb_plant(F, x, y, rng.uniform(0.8, 1.0), rng.choice(("glow_cyan", "glow_lime")))


def colfn(x, y, h, w, d, yaw, kind):
    plants = kind in ("back", "terrace") or (kind == "link" and rng.random() < 0.4)
    I.column(sc, x, y, 0.4, h, w, d, yaw, ROCKS, cap=None if kind == "boulder" else "moon_light", cap_top=rng.choice(("moon", "moon_light")),
             drip=rng.choice(("crystal_cyan", "rock_violet_dark")), top_fn=tops if plants else None)


def plasma_rim(x, y, a):
    I.column(sc, x, y, 0.4, rng.uniform(2, 5), rng.uniform(4, 6), rng.uniform(3.5, 5), a, ROCKS, cap="moon_light", cap_top="moon")


def plasma_garden(x, y):
    SB.crystal(K.Frame(sc, 0, 0, 0, z=0.4), x, y, rng.uniform(1.5, 3.0), 0.5, rng.choice(("crystal_cyan", "crystal_violet")), "glow_cyan")


for deg, R, f, fall in ((150, 14, 0.32, None), (330, 14, 0.42, 8), (22, 12, 0.45, None), (268, 10, 0.4, None)):
    I.pool(deg, R, f, "goo_plasma", "goo_plasma", "rock_violet_dark", "moon_light", rim_fn=plasma_rim, garden_fn=plasma_garden, fall=fall, fall_look="goo_plasma_fall")
for deg, fn, r, title in ((112, SB.rocket, 16, "Rocket + launch pad"),
                          (64, lambda F: (SB.observatory(F), SB.observatory_dome(F.sub(0, 0, z=9.8))), 14, "Observatory"),
                          (180, SB.habitat_domes, 22, "Habitat domes"),
                          (136, SB.robot_factory, 18, "Robot factory"),
                          (300, lambda F: SB.solar_farm(F, 3, 2), 14, "Solar farm"),
                          (350, SB.fuel_depot, 14, "Fuel depot"),
                          (88, lambda F: (F.cyl(0, 0, 5, 0, 1.0, "hull_dark", segs=20), SB.sat_dish(F.sub(0, 0, z=1.0))), 9, "Satellite dish"),
                          (318, SB.ufo, 14, "UFO landing")):
    x, y, _ = I.push_out(deg, 0.55, r)
    if not I.free(x, y, r * 0.6):
        x, y, _ = I.push_out(deg + 6, 0.7, r)
    fn(K.Frame(sc, x, y, I.ang(x, y) - 90, z=0.6))
    I.used.append((x, y, r))
    I.note(title, x, y, "scenery round the plate, out of Eclipse's pull")
ANCH = [(0, 12), (24, 14), (40, 9), (56, 10), (72, 20), (100, 24), (130, 26), (150, 28), (172, 20), (194, 12), (206, 0), (242, 0),
        (252, 7), (280, 8), (305, 10), (330, 12), (348, 12), (360, 12)]
I.massifs(ANCH, colfn)


def plant(m, x, y, z, roll, lean):
    F = K.Frame(m, 0, 0, 0, z=z)
    if roll < 0.28:
        SB.alien_mushroom(F, x, y, rng.uniform(0.9, 1.4), rng.choice(("alien_pink", "alien_purple", "alien_teal")), rng.choice(("glow_pink", "glow_cyan")))
        return 3.0
    if roll < 0.45:
        SB.tentacle_plant(F, x, y, rng.uniform(0.9, 1.2))
        return 3.0
    if roll < 0.6:
        SB.crystal_cluster(F, x, y, rng.uniform(0.6, 0.9), rng.choice((("crystal_cyan", "glow_cyan"), ("crystal_pink", "glow_pink"), ("crystal_violet", "glow_purple"))))
        return 3.0
    if roll < 0.72:
        SB.spike_plant(F, x, y, rng.uniform(0.8, 1.2))
    elif roll < 0.85:
        SB.bulb_plant(F, x, y, rng.uniform(0.8, 1.2), rng.choice(("glow_cyan", "glow_lime", "glow_pink")))
    else:
        SB.moon_rocks(F, x, y, rng.uniform(0.9, 1.4))
    return 2.0


I.ring_plants(plant, n=150)
I.done_scenery()


def islet_thing(m, x, y, z):
    SB.crystal_cluster(K.Frame(m, 0, 0, 0, z=z), x, y, 0.7, ("crystal_cyan", "glow_cyan"))


I.sky("space", islet=islet_thing, islet_top=("moon_dark", "moon"), islet_rock=("rock_violet", "rock_violet_dark"))
pl = K.Mesh("Sky_Planet", I.col("Sky"))  # a ringed planet + a pale moon far off (Blender only: not exported)
SB.ball(K.Frame(pl, 0, 0, 0), 700, 1750, 260, 170, "space_purple", step=20, segs=48, studs=False,
        looks=lambda k: ("space_purple", "alien_purple", "space_purple", "alien_pink", "space_purple")[k % 5])
pl.ring(230, 300, 425, 432, "gold", cx=700, cy=1750, segs=96)
pl.ring(310, 340, 425, 431, "crystal_violet", cx=700, cy=1750, segs=96)
SB.ball(K.Frame(pl, 0, 0, 0), -950, 1500, 520, 70, "moon_light", step=10, segs=36, studs=False)
pl.done()
STUDS = V.P.STUD_LOOKS | {"moon", "moon_light", "moon_dark", "moon_plate", "moon_plate_dark", "rock_violet", "rock_violet_dark"}
I.studs(STUDS)
I.checks()
b = I.box
I.diagram([("SPAWN\nsafe zone", I.SPAWN[0] + 26, I.SPAWN[1] - 6), ("ESCAPE PORTAL", I.PORTAL[0] + 4, I.PORTAL[1] + 24),
           ("ECLIPSE START", I.pad[0], I.pad[1] - 22), (f"ECLIPSE ROAMS THE WHOLE\nRED BOX ({b[2] - b[0]:.0f} x {b[3] - b[1]:.0f})", 38, 34),
           *[(f"EGGS: {n}", c[0], c[1] + R + 6) for n, (c, R, _) in REGIONS.items()],
           ("PULL = 44 / RING = 38\n(1.4 s windup)", -60, -40), ("SCENERY: moon cliffs, plasma,\nthe base (not playable)", -175, 120), ("N", 0, 270)])
I.finish("space_base_v2", sun=(3.4, (50, 8, -38)), sky=(0.05, 0.035, 0.15), horizon=(0.26, 0.16, 0.46), space=True, argv=argv)
