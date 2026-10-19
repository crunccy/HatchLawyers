# environment-redesign/pet_park/pp_build.py - STAGE 5, island 2: PET PARK (2026-10-18).
# A lush, cheerful animal park. Route (crnuch's call: return portal past the boss):
#   ARRIVAL (south) -> PET PARK bone gate -> a winding path to the POND (giant corgi on its island, a little bridge)
#   -> the pond loop branches to three EGG MEADOWS (Dog Meadow W, Cat Garden E, Bunny Hills SE)
#   -> BARK COURT (the boss arena: Barrister Bulldog) -> RETURN HOME portal (north; home WITH eggs)
#   Blender -b --python environment-redesign/pet_park/pp_build.py [-- norender | -- only=aerial,layout]
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import hl_world as W
import pp_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(2024)
polar = HI.polar

scene = K.reset(["Pet_Park", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("PP_Terrain", "PP_Cliffs", "PP_Paths", "PP_Meadows", "PP_Arena", "PP_Water", "PP_Sky", "PP_Labels", "PP_Gameplay_Markers"):
    K.col(n, "Pet_Park")
I = HI.Island("Pet_Park", rx=170, ry=190, seed=23, wobble=(7, 5, 2))
LAYOUT = {"island": "Pet Park", "radius_xy": [170, 190], "places": [], "egg_spots": []}


def face_to(x, y, tx, ty):
    return math.degrees(math.atan2(tx - x, -(ty - y)))


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


ARRIVAL = (0, -155)
POND, POND_R, RING_R = (0, -25), 26, 34
ARENA, ARENA_R = (0, 78), 54
PORTAL = (0, round(I.r(90) - 27))
MEADOWS = {"Dog Meadow": ((-102, -28), (40, 36)), "Cat Garden": ((100, -22), (38, 34)), "Bunny Hills": ((72, -115), (26, 24))}
print(f"[pp] island top at north = {I.r(90):.1f}; portal at {PORTAL}")

# ------------------------------------------------------------------ paths + plazas
pth = K.Mesh("Paths", C["PP_Paths"])
pth.cyl(*ARRIVAL, 24, 0, 0.35, "stone_warm", segs=64, studs=True)
pth.ring(22.5, 23.7, 0.35, 0.6, "pink", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
I.cover_circle(*ARRIVAL, 25)
W.path_curve(pth, I, [(0, -131), (-10, -106), (8, -86), (0, -62)], w=8)
ring = [polar(RING_R, a) for a in range(0, 360, 30)]
W.path_curve(pth, I, [(POND[0] + x, POND[1] + y) for x, y in ring], w=7, closed=True)
W.path_curve(pth, I, [(0, POND[1] + RING_R), (0, ARENA[1] - ARENA_R + 1)], w=8)
W.path_curve(pth, I, [(-RING_R, POND[1]), (-60, -20), (-82, -28)], w=6)
W.path_curve(pth, I, [(RING_R, POND[1]), (62, -30), (82, -24)], w=6)
W.path_curve(pth, I, [(17, -141), (45, -128), (62, -116)], w=6)
W.path_curve(pth, I, [(-17, -141), (-40, -134), (-50, -130)], w=6)
pth.brick(0, ARENA[1] + ARENA_R + 6, 0, 14, 14, 0.4, "stone_warm", studs=True)
I.cover_rect(0, ARENA[1] + ARENA_R + 6, 14, 14)
pth.done()

# ------------------------------------------------------------------ the pond, the corgi island, the bridge; two waterfalls
wat = K.Mesh("Water", C["PP_Water"])
wat.ring(POND_R, POND_R + 2.2, 0.0, 1.4, "stone_warm", cx=POND[0], cy=POND[1], segs=56, studs=True)
wat.cyl(*POND, POND_R, 0.0, 0.8, "water", segs=56)
for k in range(14):  # lily pads
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(13, POND_R - 3), a)
    wat.cyl(POND[0] + x, POND[1] + y, K.rng.uniform(0.9, 1.6), 0.8, 0.95, "leaf_light", segs=10)
    if k % 3 == 0:
        wat.brick(POND[0] + x, POND[1] + y, 0.95, 0.6, 0.6, 0.4, "pink", studs=False, bevel=0.1)
I.cover_circle(*POND, POND_R + 3)
P.giant_corgi(K.Frame(wat, POND[0], POND[1] + 1, 0), 1.7)  # (the island's headline landmark: ~23 studs tall)
P.wood_bridge(K.Frame(wat, 0, POND[1] - 20, 90), L=22, w=6)
note("The pond + giant corgi", *POND, "landmark: a corgi statue on its island, a bridge from the south, lily pads")
I.waterfall(wat, 215, stream=22)
I.waterfall(wat, 330, stream=22)
wat.done()

# ------------------------------------------------------------------ landmarks + buildings
bld = K.Mesh("Buildings", C["Buildings"])


def place(fn, x, y, rot, title, what, cover=None, **kw):
    fn(K.Frame(bld, x, y, rot), **kw)
    note(title, x, y, what)
    if cover:
        I.cover_rect(x, y, cover[0], cover[1], rot, pad=1)


place(W.arrival_pad, ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players", (18, 18), accent="pink", glow="glow_cyan")
place(P.pet_gate, 0, ARRIVAL[1] + 28, 0, "PET PARK gate", "the bone arch", (30, 6))
place(P.paw_clinic, -118, 52, face_to(-118, 52, 0, 30), "Paw Clinic", "vet (decor)", (26, 22))
place(P.fluff_and_puff, 118, 52, face_to(118, 52, 0, 30), "Fluff & Puff", "grooming salon (decor)", (26, 22))
place(P.barkery, -66, -128, face_to(-66, -128, 0, -150), "The Barkery", "dog bakery café (decor)", (26, 24))
place(lambda F: W.return_portal(F, ring=("pink", "pink", "yellow"), rim="gold", runes="glow_gold", base_glow="glow_green",
                                keystone=P.paw_keystone, sign_rot=20),
      PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "home WITH eggs, past the boss (crnuch's call)", (42, 50))
for x in (-40, 40):
    place(P.giant_cat if x > 0 else P.bunny_topiary, x, ARENA[1] + ARENA_R + 16, 0, "Giant cat" if x > 0 else "Bunny topiary",
          "sculpture by the arena's north exit", (10, 10), s=1.6 if x > 0 else 1.4)
bld.done()

# ------------------------------------------------------------------ BARK COURT + Barrister Bulldog (scale reference)
ar = K.Mesh("Bark_Court", C["PP_Arena"])
P.bark_court(K.Frame(ar, *ARENA, 0), R=ARENA_R)
ar.done()
I.cover_circle(*ARENA, ARENA_R + 2)
I.cover_circle(*ARENA, ARENA_R + 18, ground=False)
note("BARK COURT (boss arena)", *ARENA, f"open floor r {ARENA_R}: Barrister Bulldog (34-stud bark ring, 60-stud trigger)")
HI.boss(C["PP_Arena"], "BarristerBulldog", ARENA[0] + 8, ARENA[1] + 4, scale=3.5, facing=200)

# ------------------------------------------------------------------ the three egg meadows
mea = K.Mesh("Meadows", C["PP_Meadows"])
mk = K.Mesh("Egg_Spots", C["PP_Gameplay_Markers"])
spots = []
M = K.Frame(mea, 0, 0, 0)


def ellipse_fence(cx, cy, rx, ry, gaps, look="white"):
    n = 36
    for k in range(n):
        a0, a1 = k * 360 / n, (k + 1) * 360 / n
        mid = (a0 + a1) / 2
        if any(abs(HI.angdiff(mid, g)) < 9 for g in gaps):
            continue
        p0 = (cx + rx * math.cos(math.radians(a0)), cy + ry * math.sin(math.radians(a0)))
        p1 = (cx + rx * math.cos(math.radians(a1)), cy + ry * math.sin(math.radians(a1)))
        P.picket_fence(M, *p0, *p1, look=look)


def in_ellipse(x, y, c, r, inset=0.0):
    return ((x - c[0]) / (r[0] - inset)) ** 2 + ((y - c[1]) / (r[1] - inset)) ** 2 < 1


# Dog Meadow (west): doghouses, a giant bone, tennis balls, hydrants, a water bowl
(c, r) = MEADOWS["Dog Meadow"]
ellipse_fence(*c, *r, gaps=(0, 180), look="white")
for k, (dx, dy, body, roof, name) in enumerate(((-22, 14, "roof_blue", "red", "REX"), (-8, 24, "yellow", "roof_blue", "BISCUIT"),
                                                (-26, -12, "red", "sign_green", "NOODLE"))):
    P.dog_house(K.Frame(mea, c[0] + dx, c[1] + dy, face_to(c[0] + dx, c[1] + dy, *c)), body=body, roof=roof, name=name)
    I.cover_circle(c[0] + dx, c[1] + dy, 5.5)
P.giant_bone(K.Frame(mea, c[0] + 8, c[1] - 18, 25), 1.2, "white")
I.cover_circle(c[0] + 8, c[1] - 18, 7)
for dx, dy in ((14, 10), (20, -4), (2, 16)):
    P.tennis_ball(M, c[0] + dx, c[1] + dy, 1.8)
    I.cover_circle(c[0] + dx, c[1] + dy, 2.5)
for dx, dy in ((-14, -24), (24, 14)):
    P.fire_hydrant(M, c[0] + dx, c[1] + dy)
    I.cover_circle(c[0] + dx, c[1] + dy, 1.5)
P.food_bowl(K.Frame(mea, c[0] - 4, c[1] - 2, 0), 4.0, water=True)
I.cover_circle(c[0] - 4, c[1] - 2, 5)
# Cat Garden (east): cat towers, a giant cat, yarn balls, flower beds
(c, r) = MEADOWS["Cat Garden"]
ellipse_fence(*c, *r, gaps=(180, 0), look="pink")
for dx, dy in ((18, 12), (-10, 20)):
    P.cat_tower(K.Frame(mea, c[0] + dx, c[1] + dy, face_to(c[0] + dx, c[1] + dy, *c)))
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5)
P.giant_cat(K.Frame(mea, c[0] + 14, c[1] - 16, face_to(c[0] + 14, c[1] - 16, *c)), 1.3)
I.cover_circle(c[0] + 14, c[1] - 16, 6)
for dx, dy, lk in ((-18, -8, "pink"), (2, -20, "sky_blue"), (24, -2, "purple")):
    P.yarn_ball(M, c[0] + dx, c[1] + dy, 1.6, lk)
    I.cover_circle(c[0] + dx, c[1] + dy, 2.5)
for dx, dy in ((-4, 2), (-20, 10)):
    K.flowerbed(mea, c[0] + dx, c[1] + dy, 7, 4, rot=20)
    I.cover_circle(c[0] + dx, c[1] + dy, 5)
# Bunny Hills (south-east): hutches, topiary, carrots
(c, r) = MEADOWS["Bunny Hills"]
ellipse_fence(*c, *r, gaps=(160, 330), look="wood")
P.rabbit_hutch(K.Frame(mea, c[0] + 8, c[1] + 10, face_to(c[0] + 8, c[1] + 10, *c)))
I.cover_circle(c[0] + 8, c[1] + 10, 6.5)
P.bunny_topiary(K.Frame(mea, c[0] - 12, c[1] - 6, 30), 1.0)
I.cover_circle(c[0] - 12, c[1] - 6, 4)
for name, (c, r) in MEADOWS.items():
    target = 4 if name == "Bunny Hills" else 8
    got = tries = 0
    while got < target and tries < 600:
        tries += 1
        a = K.rng.uniform(0, 360)
        f = math.sqrt(K.rng.uniform(0, 1))
        ex, ey = c[0] + (r[0] - 5) * f * math.cos(math.radians(a)), c[1] + (r[1] - 5) * f * math.sin(math.radians(a))
        if I.covered(ex, ey, 2.6) or any((ex - qx) ** 2 + (ey - qy) ** 2 < 49 for qx, qy, _ in spots):
            continue
        spots.append((ex, ey, name))
        got += 1
for a in (30, 150, 210, 330):
    ex, ey = polar(ARENA_R - 7, a)
    spots.append((ARENA[0] + ex, ARENA[1] + ey, "BARK COURT (bonus, inside the boss arena)"))
for i, (x, y, where) in enumerate(spots):
    W.egg_spot(K.Frame(mk, 0, 0, 0), x, y)
    if i % 3 == 0:
        P.pet_egg(M, x, y, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
for name, (c, r) in MEADOWS.items():
    note(name + " (egg meadow)", *c, "fenced egg field")
mea.done()
mk.done()

# ------------------------------------------------------------------ landscaping: birdhouses, flowers, groves, hills, sky
props = K.Mesh("Park_Props", C["Shared_Props"])
for k in range(14):  # birdhouses along the paths
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(46, 150), a)
    if I.inside(x, y, 14) and not I.covered(x, y, 3):
        P.bird_house(K.Frame(props, 0, 0, 0), x, y, K.rng.choice(["sky_blue", "yellow", "pink", "white"]), K.rng.choice(["red", "roof_blue", "purple"]))
        I.cover_circle(x, y, 1.5, ground=False)
for k in range(10):
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(40, 150), a)
    if I.inside(x, y, 12) and not I.covered(x, y, 5):
        K.flowerbed(props, x, y, K.rng.choice([6, 8]), K.rng.choice([3, 4]), rot=K.rng.uniform(0, 90), border="wood")
        I.cover_circle(x, y, 5)
for k in range(10):  # benches by the pond
    a = k * 36 + 18
    x, y = polar(RING_R + 5.5, a)
    if not I.covered(POND[0] + x, POND[1] + y, 0.5):
        K.bench(props, POND[0] + x, POND[1] + y, rot=a - 90)
props.done()
veg = K.Mesh("Vegetation", C["Vegetation"])
I.build_top(C["PP_Terrain"])
I.cover_circle(*PORTAL, 22)
I.cover_circle(-32, -68, 14, ground=False)  # an open lawn by the pond path (the pond view looks across it)
I.groves(veg, 30, kinds=("round", "blossom", "blossom", "pine", "mixed"), margin=14, spacing=26, sizes=(5, 10),
         area=lambda x, y: not any(in_ellipse(x, y, c, r, -6) for c, r in MEADOWS.values()))
for k in range(10):  # palms by the pond (the reference has them)
    x, y = polar(RING_R + 12 + (k % 2) * 4, k * 36 + 9)
    x, y = POND[0] + x, POND[1] + y
    if I.inside(x, y, 8) and not I.covered(x, y, 3.5):
        K.tree_palm(veg, x, y, 1.0)
        I.cover_circle(x, y, 3, ground=False)
I.hills(veg, 8, rmin_f=0.62, area=lambda x, y: not any(in_ellipse(x, y, c, r, -8) for c, r in MEADOWS.values()))
for k in range(220):  # wildflowers everywhere it's open
    a = K.rng.uniform(0, 360)
    x, y = polar(math.sqrt(K.rng.uniform(0.05, 1)) * (I.r(a) - 6), a)
    if not I.covered(x, y, 1.5):
        veg.brick(x, y, 0.1, 0.9, 0.9, 0.8, K.rng.choice(["pink", "yellow", "white", "sky_blue", "purple"]), studs=False, bevel=0.15)
veg.done()
I.build_cliffs(C["PP_Cliffs"], lip=("grass_dark", "grass", "leaf_light"))
sk = K.Mesh("Clouds_Islets", C["PP_Sky"])
I.clouds(sk, n=16, islets=8)
sk.done()
I.grass_studs()
K.studs_done(C["Pet_Park"])

lab = K.Mesh("Label_Plates", C["PP_Labels"])
for text, x, y in (("ARRIVAL", 0, -155), ("PET PARK GATE", 0, -121), ("POND +\nGIANT CORGI", 0, -25), ("EGG MEADOW\nDog Meadow", -102, -28),
                   ("EGG MEADOW\nCat Garden", 100, -22), ("EGG MEADOW\nBunny Hills", 72, -115), ("BARK COURT\nboss arena", 0, 78),
                   ("RETURN HOME\nportal", 0, PORTAL[1] + 6), ("PAW CLINIC", -118, 52), ("FLUFF & PUFF", 118, 52), ("THE BARKERY", -66, -128),
                   ("N", 0, 222)):
    HI.label(C["PP_Labels"], lab, text, x, y, 5.5)
lab.done()

world, sun = K.sky_and_sun(scene, sun_energy=3.8, sun_rot=(52, 6, -40))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "pet_park.blend"), compress=True)
with open(os.path.join(HERE, "pp_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[pp] saved; {len(spots)} egg spots")

CAMS = {
    "aerial": (("Cam_Aerial", (-260, -580, 420), (0, 0, -25), 34), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, -176, 9), (0, -60, 13), 24), 1920, 1080),
    "ground_pond": (("Cam_Ground_Pond", (-38, -70, 12), (0, -22, 10), 26), 1920, 1080),
    "ground_arena": (("Cam_Ground_Arena", (6, 12, 9), (2, 120, 16), 24), 1920, 1080),
    "ground_meadow": (("Cam_Ground_Meadow", (-70, -50, 11), (-112, -22, 3), 26), 1920, 1080),
    "cliff": (("Cam_Cliff", (-330, -230, -40), (-140, -100, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"pp_{key}.jpg"), w, h, hide=("PP_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 4, 1200), (0, 4, 0), ortho=480, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        C["PP_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "pp_layout_topdown.jpg"), 2000, 2200)
