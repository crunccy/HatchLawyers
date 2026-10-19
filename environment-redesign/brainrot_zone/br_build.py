# environment-redesign/brainrot_zone/br_build.py - STAGE 5, island 3: BRAINROT ZONE (2026-10-19).
# The game's "Brainrot Boulevard" zone as a surreal neon island. Route (return portal past the boss):
#   ARRIVAL (south) -> the glitched BRAINROT BOULEVARD gate -> a zig-zag NEON BOULEVARD lined with giant statues of
#   the game's own brainrot lawyers -> three EGG FIELDS (Glitch Garden W, Wobble Square E, Upside-Down Park NE)
#   -> THE GAVEL PIT (the boss arena: Judge Martello hops + slams) -> RETURN HOME portal (north; home WITH eggs)
#   Blender -b --python environment-redesign/brainrot_zone/br_build.py [-- norender | -- only=aerial,layout]
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import hl_world as W
import br_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(4242)
polar = HI.polar
K.PAL.update({"rock_purple": (112, 96, 142), "rock_purple_dark": (76, 62, 106), "soil_purple": (70, 45, 95),
              # the groves' canopies get their own looks so the ambience wind sways their studs with them
              "leaf_magenta": (230, 50, 200), "leaf_lilac": (190, 150, 255), "leaf_sky": (120, 200, 255)})

scene = K.reset(["Brainrot_Zone", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("BR_Terrain", "BR_Cliffs", "BR_Boulevard", "BR_EggFields", "BR_Arena", "BR_Goo", "BR_Sky", "BR_Labels", "BR_Gameplay_Markers", "BR_Floaters"):
    K.col(n, "Brainrot_Zone")
I = HI.Island("Brainrot_Zone", rx=160, ry=190, seed=31, wobble=(8, 6, 3))
LAYOUT = {"island": "Brainrot Zone (game zone: Brainrot Boulevard)", "radius_xy": [160, 190], "places": [], "egg_spots": []}


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


def face_to(x, y, tx, ty):
    return math.degrees(math.atan2(tx - x, -(ty - y)))


ARRIVAL = (0, -155)
ARENA, ARENA_R = (0, 80), 52
PORTAL = (0, round(I.r(90) - 27))
FIELDS = {"Glitch Garden": ((-98, -55), 30), "Wobble Square": ((96, -72), 28), "Upside-Down Park": ((96, 8), 26)}
print(f"[br] island top at north = {I.r(90):.1f}; portal at {PORTAL}")

# ------------------------------------------------------------------ the arrival plaza + the zig-zag neon boulevard
bv = K.Mesh("Boulevard", C["BR_Boulevard"])
bv.cyl(*ARRIVAL, 24, 0, 0.35, "night", segs=64, studs=True)
bv.ring(22.6, 23.6, 0.35, 0.55, "glow_cyan", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
bv.ring(12, 13, 0.35, 0.5, "glow_magenta", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=48)
I.cover_circle(*ARRIVAL, 25)
BOULEVARD = [(0, -131), (-26, -100), (22, -62), (-20, -24), (12, 8), (0, ARENA[1] - ARENA_R + 1)]
curve = W.path_curve(bv, I, BOULEVARD, w=14, look="night", edge="glow_cyan")
for i in range(4, len(curve) - 2, 6):  # glowing chevrons down the middle, pointing toward the arena
    (x0, y0), (x1, y1) = curve[i], curve[i + 1]
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    for sgn in (-1, 1):
        ox, oy = polar(1.4, a + 90 * sgn)
        bv.brick(x0 + ox, y0 + oy, 0.35, 3.2, 0.6, 0.12, "glow_magenta", rot=a + 135 * sgn, studs=False, bevel=0.03)
W.path_curve(bv, I, [(-20, -24), (-50, -38), (-70, -50)], w=7, look="magenta", edge="glow_cyan")
W.path_curve(bv, I, [(22, -62), (50, -68), (68, -70)], w=7, look="magenta", edge="glow_cyan")
W.path_curve(bv, I, [(12, 8), (44, 10), (70, 8)], w=7, look="magenta", edge="glow_cyan")
bv.brick(0, ARENA[1] + ARENA_R + 6, 0, 14, 14, 0.4, "night", studs=True)
I.cover_rect(0, ARENA[1] + ARENA_R + 6, 14, 14)
bv.done()

# ------------------------------------------------------------------ buildings + landmarks
bld = K.Mesh("Buildings", C["Buildings"])


def place(fn, x, y, rot, title, what, cover=None, **kw):
    fn(K.Frame(bld, x, y, rot), **kw)
    note(title, x, y, what)
    if cover:
        I.cover_rect(x, y, cover[0], cover[1], rot, pad=1)


place(W.arrival_pad, ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players", (18, 18), accent="magenta", glow="glow_cyan")
place(P.glitch_gate, 0, ARRIVAL[1] + 28, 0, "BRAINROT BOULEVARD gate", "a glitched arch", (34, 7))
place(P.big_screen, -112, 30, face_to(-112, 30, 0, 20), "Big Screen", "dark tower with a giant cartoon-face screen", (34, 22))
place(P.twisty_tower, -76, 132, face_to(-76, 132, *ARENA), "Twisty Tower", "every floor turned 7.5 degrees", (26, 26))
place(P.melty_mall, 92, 128, face_to(92, 128, *ARENA), "Melty Mall", "the roof is melting down the walls", (36, 26))
for (x, y, w, d, h, sign, crown) in ((-128, -20, 14, 14, 44, "LOL LAW", "magenta"), (-120, 88, 16, 14, 52, "OBJECTION!", "violet"),
                                     (126, 66, 14, 16, 46, "SIGMA SUITS", "magenta"), (124, -112, 14, 14, 38, "GIGA CASE", "violet"),
                                     (-90, -128, 14, 14, 34, "BRAIN LAB", "magenta")):
    place(P.neon_tower, x, y, face_to(x, y, 0, y * 0.5), "Neon tower " + sign, "neon skyscraper", (w + 6, d + 6), w=w, d=d, h=h, sign=sign, crown=crown)
place(lambda F: W.return_portal(F, ring=("magenta", "magenta", "violet"), rim="lilac", runes="glow_magenta", base_glow="glow_green",
                                keystone=P.brain_keystone, sign_rot=20),
      PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "home WITH eggs, past the boss (crnuch's call)", (42, 50))
for (x, y, s) in ((-40, -132, 1.0), (44, -120, 1.2), (60, -10, 0.9)):
    P.gelato(K.Frame(bld, 0, 0, 0), x, y, s)
    I.cover_circle(x, y, 4 * s)
for (x, y, s) in ((-56, 70, 1.0), (58, 66, 1.1)):
    P.giant_cone(K.Frame(bld, 0, 0, 0), x, y, s)
    I.cover_circle(x, y, 4 * s)
note("Giant gelato / traffic cones", 0, 0, "odd giant objects along the boulevard + by the arena")
bld.done()

# the game's own brainrot lawyers as giant statues on neon plinths along the boulevard
stat = K.Mesh("Statue_Plinths", C["Buildings"])
for name, x, y, scale, facing in (("CactusinoAvvocatino", -50, -96, 4.0, -90), ("DraghettoSpaghetto", 50, -34, 3.4, 90),
                                  ("ImperatorePinguino", -52, -6, 2.4, -90)):
    stat.cyl(x, y, 9, 0, 2.0, "night", segs=24, studs=True)
    stat.ring(8.6, 9.4, 2.0, 2.4, "glow_magenta", cx=x, cy=y, segs=24)
    HI.lawyer(C["Buildings"], name, x, y, z=2.0, scale=scale, facing=facing)
    I.cover_circle(x, y, 10)
    note(f"Statue: {name}", x, y, f"the game's {name} lawyer at {scale}x on a neon plinth")
stat.done()

# ------------------------------------------------------------------ THE GAVEL PIT + Judge Martello (scale reference)
ar = K.Mesh("Gavel_Pit", C["BR_Arena"])
P.gavel_pit(K.Frame(ar, *ARENA, 0), R=ARENA_R)
ar.done()
I.cover_circle(*ARENA, ARENA_R + 3)
I.cover_circle(*ARENA, ARENA_R + 18, ground=False)
note("THE GAVEL PIT (boss arena)", *ARENA, f"open floor r {ARENA_R}: Judge Martello (Slam r 26, hops where you stood)")
HI.boss(C["BR_Arena"], "JudgeMartello", ARENA[0] + 6, ARENA[1] + 6, scale=3.4, facing=200)

# ------------------------------------------------------------------ the three egg fields
fld = K.Mesh("Egg_Fields", C["BR_EggFields"])
mk = K.Mesh("Egg_Spots", C["BR_Gameplay_Markers"])
FF = K.Frame(fld, 0, 0, 0)
spots = []
# Glitch Garden (W): a checkerboard lawn, pixel trees, floating cubes
(c, R) = FIELDS["Glitch Garden"]
for i in range(-7, 8):
    for j in range(-7, 8):
        x, y = c[0] + i * 4, c[1] + j * 4
        if math.hypot(x - c[0], y - c[1]) < R and I.inside(x, y, 6):
            fld.brick(x, y, 0, 4, 4, 0.3, "teal_dark" if (i + j) % 2 else "lilac", studs=True, bevel=0.0)
fld.ring(R, R + 1, 0, 0.5, "glow_cyan", cx=c[0], cy=c[1], segs=48)
for k, (dx, dy) in enumerate(((-16, 14), (14, 18), (-20, -12), (18, -16))):
    P.pixel_tree(FF, c[0] + dx, c[1] + dy, 1.0, "magenta" if k % 2 else "glow_magenta")
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5)
I.cover_circle(*c, R + 1, ground=True)
# Wobble Square (E): leaning towers round a dice plaza
(c, R) = FIELDS["Wobble Square"]
fld.cyl(*c, R, 0, 0.3, "night", segs=48, studs=True)
fld.ring(R - 1, R, 0.3, 0.5, "glow_magenta", cx=c[0], cy=c[1], segs=48)
for k in range(5):
    a = k * 72 + 20
    x, y = polar(R - 4, a)
    P.leaning_tower(FF, c[0] + x, c[1] + y, lean=8 + k * 2, rot=a + 90, h=18 + k * 3, look=("violet", "magenta")[k % 2])
    I.cover_circle(c[0] + x, c[1] + y, 4)
for k, (dx, dy, s) in enumerate(((-6, 4, 4.0), (5, -7, 3.0), (9, 8, 3.4))):
    P.giant_dice(FF, c[0] + dx, c[1] + dy, s, "white" if k != 1 else "magenta", "magenta" if k != 1 else "white", rot=k * 23)
    I.cover_circle(c[0] + dx, c[1] + dy, s)
I.cover_circle(*c, R + 1)
# Upside-Down Park (NE): the cottage on its roof, upside-down trees
(c, R) = FIELDS["Upside-Down Park"]
P.upside_down_house(K.Frame(fld, c[0] + 8, c[1] + 4, face_to(c[0] + 8, c[1] + 4, 12, 8)))
I.cover_circle(c[0] + 8, c[1] + 4, 9)
for dx, dy in ((-14, 12), (-12, -14), (12, -16)):
    P.upside_down_tree(FF, c[0] + dx, c[1] + dy, 0.9)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5)
for name, (c, R) in FIELDS.items():
    target = 8 if name != "Upside-Down Park" else 4
    got = tries = 0
    while got < target and tries < 600:
        tries += 1
        a = K.rng.uniform(0, 360)
        f = math.sqrt(K.rng.uniform(0.04, 1))
        ex, ey = c[0] + (R - 4) * f * math.cos(math.radians(a)), c[1] + (R - 4) * f * math.sin(math.radians(a))
        if not I.inside(ex, ey, 6):
            continue
        # (fields themselves are covered as ground: test props only, with a fresh island-free check)
        blocked = False
        for fx, fy, fr, g in I.foot.get((int(ex // I.BUCKET), int(ey // I.BUCKET)), ()):
            if fr < R - 1 and (ex - fx) ** 2 + (ey - fy) ** 2 < (fr + 2.4) ** 2:
                blocked = True
        if blocked or any((ex - qx) ** 2 + (ey - qy) ** 2 < 49 for qx, qy, _ in spots):
            continue
        spots.append((ex, ey, name))
        got += 1
for a in (30, 150, 210, 330):
    ex, ey = polar(ARENA_R - 8, a)
    spots.append((ARENA[0] + ex, ARENA[1] + ey, "THE GAVEL PIT (bonus, inside the boss arena)"))
for i, (x, y, where) in enumerate(spots):
    W.egg_spot(K.Frame(mk, 0, 0, 0), x, y)
    if i % 3 == 0:
        P.brainrot_egg(FF, x, y, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
for name, (c, R) in FIELDS.items():
    note(name + " (egg field)", *c, "egg field")
fld.done()
mk.done()

# ------------------------------------------------------------------ goo waterfalls, neon lamps, floaters, odd trees
goo = K.Mesh("Goo", C["BR_Goo"])
# (angles chosen so the goo ponds clear the egg fields + towers: 225 is ~7 studs off Glitch Garden, 346 ~7 off both
#  east fields - the fields' egg spots are placed BEFORE this, so a pond on a field could swallow a spot)
I.waterfall(goo, 225, stream=22, look="goo_fall", pond_look="goo", bank="violet")
I.waterfall(goo, 346, stream=22, look="goo_fall", pond_look="goo", bank="violet")
goo.done()
props = K.Mesh("Neon_Props", C["Shared_Props"])
for k in range(len(BOULEVARD) - 1):  # wobbly lamps + floating eyes along the boulevard
    (x0, y0), (x1, y1) = BOULEVARD[k], BOULEVARD[k + 1]
    for t in (0.33, 0.66):
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        for sgn in (-1, 1):
            ox, oy = -math.sin(math.radians(a)) * sgn * 10.5, math.cos(math.radians(a)) * sgn * 10.5
            if not I.covered(x + ox, y + oy, 1.5):
                P.wobble_lamp(K.Frame(props, 0, 0, 0), x + ox, y + oy, lean=8 * sgn, rot=a, head="glow_magenta" if (k + sgn) % 2 else "glow_cyan")
                I.cover_circle(x + ox, y + oy, 1.5)
for (x, y, z) in ((-30, -60, 14), (34, -100, 16), (-8, 40, 18), (70, 40, 15)):
    if not I.covered(x, y, 3):
        P.floating_eye(K.Frame(props, 0, 0, 0), x, y, z, 3.0)
        I.cover_circle(x, y, 1.0, ground=False)
props.done()
flo = K.Mesh("Floating_Cubes", C["BR_Floaters"])  # (their own object: they bob + spin in the ambience pass)
cubes = tries = 0
while cubes < 22 and tries < 2000:  # only over open ground: never inside a tower, statue or field prop (they bob)
    tries += 1
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(30, 150), a)
    s = K.rng.uniform(2.2, 4.5)
    if I.inside(x, y, 10) and not I.covered(x, y, s + 3):
        P.floating_cube(K.Frame(flo, 0, 0, 0), x, y, K.rng.uniform(16, 34), s,
                        K.rng.choice(["lilac", "magenta", "violet", "sky_blue"]), K.rng.uniform(0, 90))
        I.cover_circle(x, y, s + 1, ground=False)  # (groves keep out from under them)
        cubes += 1
flo.done()
veg = K.Mesh("Vegetation", C["Vegetation"])
I.build_top(C["BR_Terrain"], look="violet")
I.cover_circle(*PORTAL, 22)
CAMS = {
    "aerial": (("Cam_Aerial", (-250, -570, 420), (0, 0, -25), 34), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, -176, 9), (0, -60, 16), 24), 1920, 1080),
    "ground_boulevard": (("Cam_Ground_Boulevard", (-6, -78, 10), (-40, -8, 18), 24), 1920, 1080),
    "ground_arena": (("Cam_Ground_Arena", (0, 4, 18), (2, 110, 10), 24), 1920, 1080),
    "ground_fields": (("Cam_Ground_Fields", (64, -40, 14), (100, -76, 8), 26), 1920, 1080),
    "cliff": (("Cam_Cliff", (-320, -200, -40), (-140, -80, -40), 30), 1920, 1080),
}
I.keep_views_clear(CAMS)  # (no grove right in front of a presentation camera)
groves, tries = [], 0
while len(groves) < 13 and tries < 4000:  # pixel-tree GROVES, one colour each (no confetti)
    tries += 1
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(40, I.r(a) - 18), a)
    if not I.covered(x, y, 8) and all((x - gx) ** 2 + (y - gy) ** 2 > 32 ** 2 for gx, gy, _ in groves):
        groves.append((x, y, K.rng.choice(["leaf_magenta", "leaf_lilac", "leaf_sky"])))
for gx, gy, look in groves:
    for k in range(K.rng.randint(4, 7)):
        x, y = gx + K.rng.gauss(0, 7), gy + K.rng.gauss(0, 7)
        if I.covered(x, y, 4) or not I.inside(x, y, 8):
            continue
        P.pixel_tree(K.Frame(veg, 0, 0, 0), x, y, K.rng.uniform(0.9, 1.3), look, top="leaf_magenta" if look == "leaf_lilac" else "leaf_lilac")
        I.cover_circle(x, y, 4.5, ground=False)
I.hills(veg, 7, rmin_f=0.62)
veg.done()
I.build_cliffs(C["BR_Cliffs"], tiers=((0.97, -28, -9, ("rock_purple", "soil_purple", "violet", "rock_purple_dark")),
                                      (0.87, -52, -28, ("rock_purple", "rock_purple_dark", "violet", "night")),
                                      (0.72, -76, -52, ("rock_purple_dark", "rock_purple", "night")),
                                      (0.55, -98, -76, ("rock_purple", "violet", "rock_purple_dark")),
                                      (0.35, -118, -98, ("rock_purple_dark", "night")), (0.16, -134, -118, ("rock_purple", "night"))),
               earth=("soil_purple", "night", "soil_purple"), lip=("violet", "magenta"), vines="lilac")
cry = K.Mesh("Cliff_Crystals", C["BR_Cliffs"])  # glowing crystal clusters set into the cliff faces
for k in range(70):
    a = K.rng.uniform(0, 360)
    f, z0, z1, _ = I.tiers[K.rng.randint(0, 3)]
    x, y = polar(I.face_r(a, f, 0) + 1.5, a)
    z = K.rng.uniform(z0 + 2, z1 - 2)
    look = K.rng.choice(["glow_cyan", "glow_magenta", "glow_lime"])
    cry.cone(x, y, K.rng.uniform(0.8, 1.6), z, z + K.rng.uniform(2.5, 5), look, segs=5)
    cry.cone(x + 0.8, y, 0.6, z, z - 2.4, look, segs=5)
cry.done()
sk = K.Mesh("Clouds_Islets", C["BR_Sky"])
I.clouds(sk, n=14, islets=7)
sk.done()
I.grass_studs()
K.studs_done(C["Brainrot_Zone"])

lab = K.Mesh("Label_Plates", C["BR_Labels"])
for text, x, y in (("ARRIVAL", 0, -155), ("GLITCH GATE", 0, -121), ("NEON BOULEVARD", -12, -40), ("EGG FIELD\nGlitch Garden", -98, -55),
                   ("EGG FIELD\nWobble Square", 96, -72), ("EGG FIELD\nUpside-Down Park", 96, 8), ("THE GAVEL PIT\nboss arena", 0, 80),
                   ("RETURN HOME\nportal", 0, PORTAL[1] + 6), ("BIG SCREEN", -112, 30), ("TWISTY TOWER", -76, 132),
                   ("MELTY MALL", 92, 128), ("CACTUSINO", -50, -96), ("DRAGHETTO", 50, -34), ("PINGUINO", -52, -6), ("N", 0, 222),
                   ("LOL LAW", -128, -20), ("OBJECTION!", -120, 88), ("SIGMA SUITS", 126, 66), ("GIGA CASE", 124, -112), ("BRAIN LAB", -90, -128)):
    HI.label(C["BR_Labels"], lab, text, x, y, 5.5)
lab.done()

# a dusk-ish neon light: a cooler, dimmer sun so the glows pop
world, sun = K.sky_and_sun(scene, sun_energy=2.4, sun_rot=(58, 6, -40), sky=(0.07, 0.04, 0.24), horizon=(0.42, 0.2, 0.55))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "brainrot_zone.blend"), compress=True)
with open(os.path.join(HERE, "br_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[br] saved; {len(spots)} egg spots")

only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"br_{key}.jpg"), w, h, hide=("BR_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 4, 1200), (0, 4, 0), ortho=480, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        C["BR_Sky"].hide_render = True
        C["BR_Floaters"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "br_layout_topdown.jpg"), 2000, 2200)
