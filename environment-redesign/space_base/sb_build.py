# environment-redesign/space_base/sb_build.py - STAGE 5, island 6: SPACE BASE (2026-10-19, mr.robe's session).
# The game's "Space Base" zone as a lunar base on its own island under a starry sky. Route (return portal past the
# boss, as decided):
#   ARRIVAL (south, the landing pad) -> the SPACE BASE airlock gate -> an orange path past the rocket on its launch
#   pad and statues of the game's Space lawyers -> MISSION CONTROL PLAZA (a hologram planet ringed by eight kiosks)
#   -> side paths to three EGG FIELDS (Crater Field W, Alien Garden E, Crystal Field NE)
#   -> THE ECLIPSE RING (the round boss arena: Chief Justice Eclipse pulls r 44, gavel ring r 38) -> RETURN HOME (north)
#   Blender -b --python environment-redesign/space_base/sb_build.py [-- norender | -- only=aerial,layout]
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import hl_world as W
import sb_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(6161)
polar = HI.polar

scene = K.reset(["Space_Base", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("SB_Terrain", "SB_Cliffs", "SB_Paths", "SB_Plaza", "SB_EggFields", "SB_Arena", "SB_Falls", "SB_Spinners", "SB_Sky",
          "SB_Labels", "SB_Gameplay_Markers"):
    K.col(n, "Space_Base")

I = HI.Island("Space_Base", rx=180, ry=212, seed=61, wobble=(8, 6, 3))
LAYOUT = {"island": "Space Base (game zone: Space Base)", "radius_xy": [180, 212], "places": [], "egg_spots": [],
          "fx": {"steam": [], "motes": [], "spinners": [], "beacons": []}}


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


def face_to(x, y, tx, ty):
    return math.degrees(math.atan2(tx - x, -(ty - y)))


def world(F, lx, ly, lz):
    wx, wy = F.p(lx, ly)
    return [round(wx, 2), round(wy, 2), round(lz + F.z, 2)]


ARR_Y = -round(I.r(270) - 30)
ARRIVAL = (0, ARR_Y)
PORTAL = (0, round(I.r(90) - 27))
ARENA_R = 72.0
ARENA = (0, round(PORTAL[1] - 22.4 - 6 - ARENA_R))  # its north edge stops 6 studs short of the portal stairs
ARENA_S = ARENA[1] - ARENA_R
PLAZA_R = 34
PLAZA = (0, round(ARENA_S - 12 - PLAZA_R))
FIELDS = {"Crater Field": ((-114, PLAZA[1] + 28), 34), "Alien Garden": ((116, PLAZA[1]), 32), "Crystal Field": ((116, 92), 24)}
print(f"[sb] island top at north = {I.r(90):.1f}, south = {I.r(270):.1f}; portal {PORTAL}; arena {ARENA} r {ARENA_R}; plaza {PLAZA}")

# ------------------------------------------------------------------ paths (orange, white dashed edges: the world's own)
pa = K.Mesh("Paths", C["SB_Paths"])
pa.cyl(*ARRIVAL, 22, 0, 0.35, "path", segs=64, studs=True)
pa.ring(20.6, 21.6, 0.35, 0.5, "path_edge", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
I.cover_circle(*ARRIVAL, 23)
SOUTH = [(0, ARR_Y + 14), (0, ARR_Y + 36), (-18, -122), (14, -96), (0, PLAZA[1] - PLAZA_R + 2)]
NORTH = [(0, PLAZA[1] + PLAZA_R - 2), (0, ARENA_S + 1)]
W.path_curve(pa, I, SOUTH, w=12)
W.path_curve(pa, I, NORTH, w=12)
W.path_curve(pa, I, [(-PLAZA_R + 2, PLAZA[1]), (-58, PLAZA[1] + 8), (-80, PLAZA[1] + 24)], w=7)
W.path_curve(pa, I, [(PLAZA_R - 2, PLAZA[1]), (58, PLAZA[1] - 4), (84, PLAZA[1])], w=7)
W.path_curve(pa, I, [(58, PLAZA[1] - 4), (78, -8), (90, 40), (104, 74)], w=7)  # (branches off the east path)
pa.brick(0, ARENA[1] + ARENA_R + 3.5, 0, 14, 7, 0.35, "path")  # arena -> portal stairs
I.cover_rect(0, ARENA[1] + ARENA_R + 3.5, 14, 7)
pa.done()

# ------------------------------------------------------------------ MISSION CONTROL PLAZA: ringed tiles, the hologram, kiosks
pz = K.Mesh("Mission_Control_Plaza", C["SB_Plaza"])
cell = 4.0
for i in range(-9, 10):
    for j in range(-9, 10):
        x, y = PLAZA[0] + i * cell, PLAZA[1] + j * cell
        d = math.hypot(x - PLAZA[0], y - PLAZA[1])
        if d < PLAZA_R - 1.5:
            band = int(d / 4.2)
            pz.brick(x, y, 0, cell, cell, 0.4, ("hull_white", "hull_grey", "hull_white", "moon_light", "space_purple", "hull_white", "hull_grey", "space_purple")[band % 8], bevel=0.0)
pz.ring(PLAZA_R - 1.5, PLAZA_R, 0, 0.6, "hull_white", cx=PLAZA[0], cy=PLAZA[1], segs=80, studs=True)
pz.ring(PLAZA_R - 2.1, PLAZA_R - 1.5, 0.4, 0.5, "glow_cyan", cx=PLAZA[0], cy=PLAZA[1], segs=80)
I.cover_circle(*PLAZA, PLAZA_R + 1)
PF = K.Frame(pz, PLAZA[0], PLAZA[1], 0, z=0.4)
P.hologram_fountain(PF)
SPIN = []  # (object name, builder(F), pivot xyz, seconds per turn)
SPIN.append(("Spin_HoloPlanet", P.holo_planet, (PLAZA[0], PLAZA[1], 16.4 + 0.4), 14.0))


def mini_rocket(G):
    G.cyl(0, 0, 0.9, 0, 3.6, "hull_white", segs=12)
    G.cyl(0, 0, 0.95, 1.2, 1.8, "rocket_red", segs=12)
    P.taper(G, 0, 0, 3.6, 0.9, 0.2, 1.6, "rocket_red", step=0.4, segs=12, studs=False)
    for a in (0, 120, 240):
        px, py = polar(1.1, a)
        G.brick(px, py, 0, 1.0, 0.25, 1.4, "rocket_red", rot=a, studs=False)


MODULES = ((30, "ASTRO SNACKS", "rocket_red", mini_rocket),
           (60, "MOON ROCKS", "space_purple", lambda G: P.ball(G, 0, 0, 0, 1.8, "moon_dark", step=0.45)),
           (120, "STAR MAPS", "space_navy", lambda G: P.pixel_rows(G, [[(-1.4, -0.5, "gold"), (0.5, 1.4, "gold")], [(-1.0, 1.0, "gold")], [(-2.2, 2.2, "gold")], [(-0.8, 0.8, "gold")], [(-0.35, 0.35, "gold")]], 0.7, 0.6)),
           (150, "SPACE SUITS", "panel_blue", lambda G: (P.ball(G, 0, 0, 0, 1.7, "hull_white", step=0.4), G.brick(0, -1.4, 1.2, 2.0, 0.6, 1.2, "glass_dark", studs=False))),
           (210, "COSMIC CONES", "alien_pink", lambda G: (P.taper(G, 0, 0, 0, 0.3, 1.3, 2.4, "waffle" if "waffle" in K.PAL else "wood", step=0.4, studs=False),
                                                          P.ball(G, 0, 0, 2.1, 1.5, "crystal_pink", step=0.4))),
           (240, "ROBOT REPAIR", "hull_dark", lambda G: (G.brick(0, 0, 0, 2.6, 2.2, 2.2, "hull_grey"), G.brick(-0.6, -1.15, 1.1, 0.5, 0.15, 0.5, "glow_cyan", studs=False),
                                                         G.brick(0.6, -1.15, 1.1, 0.5, 0.15, 0.5, "glow_cyan", studs=False), G.cyl(0, 0, 0.12, 2.2, 3.4, "hull_grey", segs=6),
                                                         G.sphere(0, 0, 3.6, 0.3, 0.3, 0.3, "glow_red", seg=8, rings=5))),
           (300, "ALIEN PETS", "alien_teal", lambda G: (P.ball(G, 0, 0, 0, 1.6, "alien_lime", step=0.4, studs=False), G.brick(0, -1.45, 1.8, 0.9, 0.2, 0.9, "white", studs=False),
                                                        G.brick(0, -1.55, 1.9, 0.45, 0.15, 0.45, "black", studs=False))),
           (330, "GADGETS", "hazard", lambda G: (G.brick(0, 0, 0, 1.0, 1.0, 1.6, "hull_grey", studs=False),
                                                                                                P.dome(G, 0, 0, 1.6, 1.8, 0.9, "hull_white", step=0.3, studs=False),
                                                                                                G.sphere(0, 0, 3.0, 0.3, 0.3, 0.3, "glow_cyan", seg=8, rings=5))))
tops = []
for ang, name, color, prop in MODULES:
    x, y = polar(26, ang)
    MF = K.Frame(pz, PLAZA[0] + x, PLAZA[1] + y, ang - 90, z=0.4)
    P.space_module(MF, name, color, prop)
    tops.append(world(MF, 0, -4.0, 10.4))
for k in range(len(tops)):  # neon light strings from each kiosk's sign to the next one's, round the ring
    P.festoon(K.Frame(pz, 0, 0, 0), tuple(tops[k]), tuple(tops[(k + 1) % len(tops)]), n=12, sag=1.2,
              looks=("glow_cyan", "glow_magenta", "glow_lime"))
for ang in (45, 135, 225, 315):  # round tables with stools and a little holo lamp (the cardinal lanes stay open)
    x, y = polar(17, ang)
    G = PF.sub(x, y)
    G.cyl(0, 0, 1.8, 2.2, 2.6, "hull_white", segs=16)
    G.cyl(0, 0, 0.3, 0, 2.2, "hull_grey", segs=8)
    G.sphere(0, 0, 3.2, 0.5, 0.5, 0.5, "portal_holo", seg=10, rings=6)
    for sx in (-1, 1):
        G.cyl(sx * 2.8, 0, 0.8, 0, 1.5, "space_purple" if sx > 0 else "panel_blue", segs=12)
note("MISSION CONTROL PLAZA", *PLAZA, "ringed tiles, the hologram planet, 8 kiosks, neon light strings, tables")
pz.done()

# ------------------------------------------------------------------ buildings, landmarks, statues, gate
bld = K.Mesh("Buildings", C["Buildings"])


def place(fn, x, y, rot, title, what, cover=None):
    F = K.Frame(bld, x, y, rot)
    fn(F)
    note(title, x, y, what)
    if cover:
        I.cover_rect(x, y, cover[0], cover[1], rot, pad=1)
    return F


place(lambda F: W.arrival_pad(F, accent="space_purple", glow="glow_cyan"), ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players (the landing pad)", (18, 18))
place(P.airlock_gate, 0, ARR_Y + 26, 0, "SPACE BASE gate", "an airlock: white pylons with hazard feet, the doors slid open, beacons", (44, 9))
F = place(P.rocket, -64, -118, face_to(-64, -118, 0, -60), "ROCKET + LAUNCH PAD", "red-and-white rocket with a gantry (exhaust steam)", (40, 30))
LAYOUT["fx"]["steam"].append(world(F, 0, 0, 1.6))
F = place(P.observatory, -118, 62, face_to(-118, 62, 0, 40), "OBSERVATORY", "white drum, gold band; its dome turns slowly", (28, 28))
top = world(F, 0, 0, 9.8)
SPIN.append(("Spin_ObservatoryDome", P.observatory_dome, tuple(top), 60.0))
place(P.habitat_domes, 138, 26, face_to(138, 26, 0, 0), "HABITAT DOMES", "three glass domes joined by tubes, alien gardens inside", (40, 30))
F = place(P.robot_factory, 105, -118, face_to(105, -118, 0, -60), "ROBOT FACTORY", "grey factory, neon windows, glowing vent stacks; its radar turns", (32, 28))
SPIN.append(("Spin_Radar", P.radar, tuple(world(F, 0, 6, 12.6)), 6.0))
place(lambda F: P.solar_farm(F, 4, 3), -82, 150, face_to(-82, 150, 0, 95), "SOLAR FARM", "rows of blue solar panels", (34, 22))
place(P.fuel_depot, 86, 150, face_to(86, 150, 0, 95), "FUEL DEPOT", "two round tanks on legs, pipes, hazard bands", (28, 16))
F = place(lambda F: F.cyl(0, 0, 5, 0, 1.0, "hull_dark", segs=20, studs=True), -150, 8, 0, "SATELLITE DISH", "a big dish on the west edge; it turns", (12, 12))
SPIN.append(("Spin_SatDish", P.sat_dish, (-150, 8, 1.0), 16.0))
place(P.ufo, -130, -72, 0, "UFO LANDING", "a parked flying saucer on a landing ring (fictional)", (28, 28))
place(lambda F: W.return_portal(F, ring=("violet", "purple", "lilac"), rim="gold", runes="glow_cyan", base_glow="glow_green",
                                keystone=P.planet_keystone, sign_rot=20),
      PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "home WITH eggs, past the boss (crnuch's call)", (42, 50))
for (x, y, title) in ((44, -70, "Moon rocks"), (-44, -60, "Meteorite")):
    if "Meteorite" in title:
        P.meteorite(K.Frame(bld, 0, 0, 0), x, y, 1.6)
    else:
        for k in range(3):
            P.moon_rocks(K.Frame(bld, 0, 0, 0), x + k * 3 - 3, y + (k % 2) * 3, 1.5)
    I.cover_circle(x, y, 8)
    note(title, x, y, "lawn landmark")
bld.done()
stat = K.Mesh("Statue_Plinths", C["Buildings"])
for name, x, y, scale, facing in (("CometCounsel", 38, -136, 5.0, 90), ("NebulaArbiter", -34, -88, 4.0, -90),
                                  ("SupernovaSovereign", -58, -4, 2.6, -90)):
    stat.cyl(x, y, 9, 0, 2.0, "hull_grey", segs=24, studs=True)
    stat.ring(8.6, 9.4, 2.0, 2.4, "gold", cx=x, cy=y, segs=24)
    stat.ring(8.0, 8.6, 2.0, 2.2, "glow_cyan", cx=x, cy=y, segs=24)
    ob = HI.lawyer(C["Buildings"], name, x, y, z=2.0, scale=scale, facing=facing)
    I.cover_circle(x, y, 10)
    note(f"Statue: {name}", x, y, f"the game's {name} lawyer at {scale}x on a plinth")
    print(f"[sb] statue {name}: {ob.dimensions.z:.1f} studs tall")
stat.done()

for name, fn, piv, secs in SPIN:  # the turning things: one object each (pivoted in the ambience pass), studs ride along
    m = K.Mesh(name, C["SB_Spinners"])
    K.STUD_GROUP = name
    fn(K.Frame(m, piv[0], piv[1], 0, z=piv[2]))
    K.STUD_GROUP = None
    m.done()
    LAYOUT["fx"]["spinners"].append({"name": name, "pivot": [round(v, 2) for v in piv], "seconds_per_turn": secs})
I.cover_circle(-150, 8, 9)

# ------------------------------------------------------------------ THE ECLIPSE RING + Chief Justice Eclipse
ar = K.Mesh("Eclipse_Ring", C["SB_Arena"])
P.eclipse_ring(K.Frame(ar, *ARENA, 0), R=ARENA_R)
AF = K.Frame(ar, 0, 0, 0)
W.marquee(AF, 0, ARENA_S - 8, 7.0, 22, 4, "ECLIPSE RING", size=1.6, post_h=7.0, panel="space_navy", letters="gold")
for sx in (-1, 1):
    P.star_chart(AF, sx * 16, ARENA_S - 11, rot=sx * 14)
    P.beacon_lamp(AF, sx * 12, ARENA_S - 3, glow="glow_purple")
    P.beacon_lamp(AF, sx * 12, ARENA[1] + ARENA_R + 3, glow="glow_purple")
for a in (30, 150, 210, 330):
    x, y = polar(ARENA_R + 9, a)
    P.telescope(AF, ARENA[0] + x, ARENA[1] + y, rot=face_to(ARENA[0] + x, ARENA[1] + y, *ARENA) + 180)
    I.cover_circle(ARENA[0] + x, ARENA[1] + y, 3)
ar.done()
I.cover_circle(*ARENA, ARENA_R + 3)
I.cover_rect(0, ARENA_S - 9, 44, 12)
I.cover_rect(0, ARENA[1] + ARENA_R + 3, 30, 4)
note("THE ECLIPSE RING (boss arena)", *ARENA, f"open round observation floor r {ARENA_R:.0f}: Eclipse pulls r 44 and throws his gavel ring r 38")
eclipse = HI.boss(C["SB_Arena"], "Eclipse", 0, ARENA[1], z=1.4, scale=3.2, facing=180)
print(f"[sb] Eclipse at 3.2x: {eclipse.dimensions.x:.1f} x {eclipse.dimensions.y:.1f} x {eclipse.dimensions.z:.1f}")

# ------------------------------------------------------------------ the three egg fields
fld = K.Mesh("Egg_Fields", C["SB_EggFields"])
mk = K.Mesh("Egg_Spots", C["SB_Gameplay_Markers"])
spots = []
# Crater Field (W): darker moon dust, craters, moon rocks, a meteorite, a planted flag, a rover
(c, R) = FIELDS["Crater Field"]
fld.cyl(*c, R, 0, 0.3, "moon_dark", segs=64, studs=True)
fld.ring(R, R + 1.4, 0, 0.6, "hull_grey", cx=c[0], cy=c[1], segs=64, studs=True)
GF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, r) in ((-14, 12, 5.0), (12, 16, 4.0), (-16, -14, 4.4), (16, -12, 5.2), (0, 0, 3.4)):
    P.crater(GF, c[0] + dx, c[1] + dy, r)
    I.cover_circle(c[0] + dx, c[1] + dy, r + 2.8)
for (dx, dy, s) in ((0, 24, 1.3), (-26, 0, 1.1), (24, 2, 1.2)):
    P.moon_rocks(GF, c[0] + dx, c[1] + dy, s * 1.3)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.4 * s)
P.meteorite(GF, c[0] + 6, c[1] - 26, 1.0)
I.cover_circle(c[0] + 6, c[1] - 26, 5)
P.flag(GF, c[0] - 22, c[1] - 22)
I.cover_circle(c[0] - 22, c[1] - 22, 2)
P.rover(GF, c[0] + 22, c[1] + 22, rot=35)
I.cover_circle(c[0] + 22, c[1] + 22, 5)
I.cover_circle(*c, R + 1.5, ground=True)
# Alien Garden (E): purple soil, glowing mushrooms, tentacle plants, bulb plants, spike plants (motes in the ambience)
(c, R) = FIELDS["Alien Garden"]
fld.cyl(*c, R, 0, 0.3, "soil_purple", segs=64, studs=True)
fld.ring(R, R + 1.4, 0, 0.6, "alien_teal", cx=c[0], cy=c[1], segs=64, studs=True)
AGF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, s, cap, glow) in ((-16, 14, 1.4, "alien_pink", "glow_pink"), (14, 18, 1.2, "alien_purple", "glow_magenta"),
                               (-18, -14, 1.1, "alien_teal", "glow_cyan"), (16, -16, 1.3, "alien_pink", "glow_pink")):
    P.alien_mushroom(AGF, c[0] + dx, c[1] + dy, s, cap, glow)
    I.cover_circle(c[0] + dx, c[1] + dy, 2.6 * s + 0.6)
for (dx, dy) in ((0, 24), (-26, 0), (24, 0)):
    P.tentacle_plant(AGF, c[0] + dx, c[1] + dy, 1.1)
    I.cover_circle(c[0] + dx, c[1] + dy, 3.8)
for (dx, dy) in ((-6, -24), (8, 4), (-8, 6)):
    P.bulb_plant(AGF, c[0] + dx, c[1] + dy, 1.0, K.rng.choice(("glow_cyan", "glow_lime", "glow_pink")))
    I.cover_circle(c[0] + dx, c[1] + dy, 2.2)
for (dx, dy) in ((24, 18), (-24, -24), (22, -26)):
    P.spike_plant(AGF, c[0] + dx, c[1] + dy, 1.0)
    I.cover_circle(c[0] + dx, c[1] + dy, 2.4)
LAYOUT["fx"]["motes"].append([c[0], c[1], 1.5, R - 4])
I.cover_circle(*c, R + 1.5, ground=True)
# Crystal Field (NE): pale moon ground, crystal clusters in three colours
(c, R) = FIELDS["Crystal Field"]
fld.cyl(*c, R, 0, 0.3, "moon_light", segs=56, studs=True)
fld.ring(R, R + 1.0, 0, 0.7, "crystal_violet", cx=c[0], cy=c[1], segs=56, studs=True)
CF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, s, lk) in ((-10, 8, 1.0, ("crystal_cyan", "glow_cyan")), (10, -10, 0.9, ("crystal_pink", "glow_pink")),
                        (12, 12, 0.7, ("crystal_violet", "glow_purple")), (-12, -10, 0.6, ("crystal_violet", "glow_purple"))):
    P.crystal_cluster(CF, c[0] + dx, c[1] + dy, s, lk)
    I.cover_circle(c[0] + dx, c[1] + dy, 3.4 * s + 0.8)
I.cover_circle(*c, R + 1.5, ground=True)
for name, (c, R) in FIELDS.items():
    target = 8 if name != "Crystal Field" else 4
    got = tries = 0
    while got < target and tries < 800:
        tries += 1
        a = K.rng.uniform(0, 360)
        f = math.sqrt(K.rng.uniform(0.04, 1))
        ex, ey = c[0] + (R - 4) * f * math.cos(math.radians(a)), c[1] + (R - 4) * f * math.sin(math.radians(a))
        if not I.inside(ex, ey, 6):
            continue
        blocked = any(fr < R - 1 and (ex - fx) ** 2 + (ey - fy) ** 2 < (fr + 2.4) ** 2
                      for fx, fy, fr, gnd in I.foot.get((int(ex // I.BUCKET), int(ey // I.BUCKET)), ()))
        blocked = blocked or any(fn(ex, ey, 2.4) for fn in I.cover_fns)
        if blocked or any((ex - qx) ** 2 + (ey - qy) ** 2 < 49 for qx, qy, _ in spots):
            continue
        spots.append((ex, ey, name))
        got += 1
for (dx, dy) in ((-24, -24), (24, -24), (-24, 24), (24, 24)):
    spots.append((ARENA[0] + dx, ARENA[1] + dy, "THE ECLIPSE RING (bonus, on the boss arena)"))
for i, (x, y, where) in enumerate(spots):
    z = 0.4 if "RING" in where else 0.3
    W.egg_spot(K.Frame(mk, 0, 0, 0, z=z), x, y)
    if i % 3 == 0:
        P.space_egg(K.Frame(fld, 0, 0, 0, z=z), x, y, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
for name, (c, R) in FIELDS.items():
    note(name + " (egg field)", *c, "egg field")
fld.done()
mk.done()

# ------------------------------------------------------------------ beacon lamps along the paths
props = K.Mesh("Path_Props", C["Shared_Props"])
PR = K.Frame(props, 0, 0, 0)
for path in (SOUTH, NORTH):
    for k in range(len(path) - 1):
        (x0, y0), (x1, y1) = path[k], path[k + 1]
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        x, y = (x0 + x1) / 2, (y0 + y1) / 2
        for sgn in (-1, 1):
            ox, oy = -math.sin(math.radians(a)) * sgn * 9.0, math.cos(math.radians(a)) * sgn * 9.0
            if not I.covered(x + ox, y + oy, 1.6):
                P.beacon_lamp(PR, x + ox, y + oy, glow="glow_cyan" if sgn < 0 else "glow_magenta")
                I.cover_circle(x + ox, y + oy, 1.6)
props.done()


# ------------------------------------------------------------------ plasma falls (angles chosen clear of everything)
def clear_fall(prefer):
    for d in sorted(range(0, 360, 3), key=lambda a: min(abs(a - prefer), 360 - abs(a - prefer))):
        er = I.r(d)
        px, py = polar(er - 35, d)
        if I.covered(px, py, 12):
            continue
        if any(I.covered(*polar(er - 22 + k * 2, d), 4) for k in range(11)):
            continue
        return d
    raise RuntimeError("no clear waterfall angle near %d" % prefer)


falls = K.Mesh("Falls", C["SB_Falls"])
A_W = clear_fall(205)
I.waterfall(falls, A_W, stream=22, look="goo_plasma_fall", pond_look="goo_plasma", bank="rock_violet")
A_E = clear_fall(335)
I.waterfall(falls, A_E, stream=22, look="goo_plasma_fall", pond_look="goo_plasma", bank="rock_violet")
falls.done()
print(f"[sb] plasma falls at {A_W} and {A_E}")
note("West plasma falls", *polar(I.r(A_W) - 35, A_W), "a glowing plasma pool, a stream and a fall off the edge")
note("East plasma falls", *polar(I.r(A_E) - 35, A_E), "a glowing plasma pool, a stream and a fall off the edge")

# ------------------------------------------------------------------ the moon: craters, alien plant clusters, crystals, rocks
deco = K.Mesh("Moon_Decor", C["SB_Terrain"])
DF = K.Frame(deco, 0, 0, 0)
made = 0
for k in range(14):  # craters on the open ground
    for _ in range(80):
        a = K.rng.uniform(0, 360)
        R_ = K.rng.uniform(5, 11)
        x, y = polar(K.rng.uniform(30, I.r(a) - R_ - 12), a)
        if not I.covered(x, y, R_ + 4):
            P.crater(DF, x, y, R_)
            I.cover_circle(x, y, R_ + 2.6)
            made += 1
            break
KINDS = ([("mushroom", 3.6)] * 10 + [("tentacle", 3.8)] * 6 + [("bulb", 2.4)] * 10 + [("spike", 2.4)] * 8 + [("crystals", 4.0)] * 10 +
         [("rocks", 3.4)] * 16 + [("flag", 1.5)] * 3)
K.rng.shuffle(KINDS)
for kind, rad in KINDS:
    for _ in range(120):
        a = K.rng.uniform(0, 360)
        x, y = polar(K.rng.uniform(20, I.r(a) - 8 - rad), a)
        if not I.covered(x, y, rad):
            break
    else:
        continue
    if kind == "mushroom":
        cap, glow = K.rng.choice((("alien_pink", "glow_pink"), ("alien_purple", "glow_magenta"), ("alien_teal", "glow_cyan")))
        P.alien_mushroom(DF, x, y, K.rng.uniform(0.9, 1.4), cap, glow)
    elif kind == "tentacle":
        P.tentacle_plant(DF, x, y, K.rng.uniform(0.9, 1.2))
    elif kind == "bulb":
        P.bulb_plant(DF, x, y, K.rng.uniform(0.8, 1.2), K.rng.choice(("glow_cyan", "glow_lime", "glow_pink")))
    elif kind == "spike":
        P.spike_plant(DF, x, y, K.rng.uniform(0.8, 1.2))
    elif kind == "crystals":
        P.crystal_cluster(DF, x, y, K.rng.uniform(0.5, 0.9), K.rng.choice((("crystal_cyan", "glow_cyan"), ("crystal_pink", "glow_pink"), ("crystal_violet", "glow_purple"))))
    elif kind == "rocks":
        P.moon_rocks(DF, x, y, K.rng.uniform(0.9, 1.5))
    elif kind == "flag":
        P.flag(DF, x, y, K.rng.choice(("glow_cyan", "glow_magenta", "glow_lime")))
    I.cover_circle(x, y, rad, ground=kind != "flag")
    made += 1
deco.done()
print(f"[sb] moon decor: {made} pieces")

I.build_top(C["SB_Terrain"], look="moon")
I.cover_circle(*PORTAL, 22)
veg = K.Mesh("Moon_Dunes", C["SB_Terrain"])
_tree = K.tree_round  # (I.hills tops some hills with a tree: on the moon they get a crystal cluster)
K.tree_round = lambda m, x, y, s=1.0, look=None, rot=None: P.crystal_cluster(m, x, y, 0.6 * s, ("crystal_violet", "glow_purple"))
I.hills(veg, 5, rmin_f=0.4)
K.tree_round = _tree
veg.done()
TIERS = ((0.97, -28, -9, ("rock_violet", "moon_dark", "rock_violet", "rock_violet_dark", "hull_dark")),
         (0.87, -52, -28, ("rock_violet_dark", "rock_violet", "moon_dark", "hull_dark")),
         (0.72, -76, -52, ("rock_violet_dark", "rock_violet", "hull_dark", "moon_dark")),
         (0.55, -98, -76, ("rock_violet", "rock_violet_dark", "moon_dark")),
         (0.35, -118, -98, ("rock_violet_dark", "rock_violet")), (0.16, -134, -118, ("rock_violet", "rock_violet_dark")))
I.build_cliffs(C["SB_Cliffs"], tiers=TIERS, earth=("moon_dark", "rock_violet", "moon_dark"), lip=("moon", "moon_light", "moon"), vines="alien_teal")

# the sky: drifting asteroids round the island (their studs ride along) + a far backdrop (stars, a ringed planet, a
# moon) that stays in Blender (Sky_* meshes are not exported to Roblox: the place gets a space skybox instead)
ast = K.Mesh("Asteroids", C["SB_Sky"])
K.STUD_GROUP = "Asteroids"
AFr = K.Frame(ast, 0, 0, 0)
Rr = max(I.rx, I.ry)
for k in range(26):
    x, y = polar(K.rng.uniform(Rr + 60, Rr + 260), K.rng.uniform(0, 360))
    z = K.rng.uniform(-170, 40)
    s = K.rng.uniform(4, 13)
    for j in range(K.rng.randint(2, 4)):
        w = s * K.rng.uniform(0.6, 1.2)
        ast.brick(x + K.rng.uniform(-s, s) * 0.5, y + K.rng.uniform(-s, s) * 0.5, z + K.rng.uniform(-s, s) * 0.3, w, w * K.rng.uniform(0.7, 1.1), w * 0.7,
                  K.rng.choice(("moon_dark", "rock_violet", "rock_violet_dark")), rot=K.rng.uniform(0, 90))
    if k % 4 == 0:
        P.crystal(K.Frame(ast, x, y, 0, z=z + s * 0.7), 0, 0, s * 0.7, s * 0.15, "crystal_cyan", "glow_cyan")
K.STUD_GROUP = None
ast.done()
sky = K.Mesh("Sky_Backdrop", C["SB_Sky"])
for k in range(900):
    az, el = K.rng.uniform(0, 360), K.rng.uniform(-70, 80)  # (stars below the horizon too: it's space)
    d = K.rng.uniform(1700, 2100)
    x, y = polar(d * math.cos(math.radians(el)), az)
    z = d * math.sin(math.radians(el))
    s = K.rng.uniform(1.4, 3.6)
    sky.brick(x, y, z, s, s, s, "glow_white" if k % 5 else K.rng.choice(("glow_cyan", "glow_pink", "glow_gold")), rot=K.rng.uniform(0, 90), studs=False, bevel=0.0)
SF = K.Frame(sky, 0, 0, 0)
P.ball(SF, 700, 1750, 260, 170, "space_purple", step=20, segs=48, studs=False,
       looks=lambda k: ("space_purple", "alien_purple", "space_purple", "alien_pink", "space_purple")[k % 5])
sky.ring(230, 300, 425, 432, "gold", cx=700, cy=1750, segs=96)
sky.ring(310, 340, 425, 431, "crystal_violet", cx=700, cy=1750, segs=96)
P.ball(SF, -950, 1500, 520, 70, "moon_light", step=10, segs=36, studs=False)
sky.done()
I.grass_studs()  # (the moon top's studs; I.top_look = "moon")
K.studs_done(C["Space_Base"])

lab = K.Mesh("Label_Plates", C["SB_Labels"])
for text, x, y in (("ARRIVAL", 0, ARR_Y), ("SPACE BASE GATE", 0, ARR_Y + 33), ("MISSION CONTROL\nplaza", *PLAZA),
                   ("EGG FIELD\nCrater Field", *FIELDS["Crater Field"][0]), ("EGG FIELD\nAlien Garden", *FIELDS["Alien Garden"][0]),
                   ("EGG FIELD\nCrystal Field", *FIELDS["Crystal Field"][0]), ("THE ECLIPSE RING\nboss arena", *ARENA),
                   ("RETURN HOME\nportal", 0, PORTAL[1] + 6), ("ROCKET", -64, -118), ("OBSERVATORY", -118, 62), ("HABITAT", 138, 26),
                   ("ROBOT FACTORY", 105, -118), ("SOLAR FARM", -82, 150), ("FUEL DEPOT", 86, 150), ("DISH", -150, 8), ("UFO", -130, -72),
                   ("COMET", 38, -136), ("NEBULA", -34, -88), ("SUPERNOVA", -58, -4),
                   ("PLASMA FALLS", *polar(I.r(A_W) - 35, A_W)), ("PLASMA FALLS", *polar(I.r(A_E) - 35, A_E)), ("N", 0, I.r(90) + 14)):
    HI.label(C["SB_Labels"], lab, text, x, y, 5.5)
lab.done()

# a starry night, but bright enough for the toy colours: a cool moon-sun + a lifted purple sky
world_, sun = K.sky_and_sun(scene, sun_energy=3.4, sun_rot=(50, 8, -38), sky=(0.05, 0.035, 0.15), horizon=(0.26, 0.16, 0.46))
sun.data.color = (0.92, 0.94, 1.0)
bg = next(n for n in world_.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Strength"].default_value = 1.6
# the camera sees deep space (dark violet); everything else is lit by the lifted purple sky (Light Path: Is Camera Ray)
nt = world_.node_tree
out = next(n for n in nt.nodes if n.type == "OUTPUT_WORLD")
space = nt.nodes.new("ShaderNodeBackground")
space.inputs["Color"].default_value = (0.008, 0.005, 0.03, 1)
space.inputs["Strength"].default_value = 1.0
lp = nt.nodes.new("ShaderNodeLightPath")
mix = nt.nodes.new("ShaderNodeMixShader")
nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs["Fac"])
nt.links.new(bg.outputs["Background"], mix.inputs[1])
nt.links.new(space.outputs["Background"], mix.inputs[2])
nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "space_base.blend"), compress=True)
with open(os.path.join(HERE, "sb_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[sb] saved; {len(spots)} egg spots")

CAMS = {
    "aerial": (("Cam_Aerial", (-270, -640, 450), (0, 0, -25), 34), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, ARR_Y - 4, 9), (0, -90, 14), 24), 1920, 1080),
    "ground_plaza": (("Cam_Ground_Plaza", (-6, PLAZA[1] - 44, 9), (4, PLAZA[1] + 4, 11), 22), 1920, 1080),  # (through the south lane)
    "ground_arena": (("Cam_Ground_Arena", (0, ARENA_S - 34, 21), (2, ARENA[1] + 20, 8), 24), 1920, 1080),
    "ground_fields": (("Cam_Ground_Fields", (74, PLAZA[1] - 14, 10), (118, PLAZA[1] + 2, 4), 24), 1920, 1080),
    "cliff": (("Cam_Cliff", (-330, -230, -40), (-150, -100, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"sb_{key}.jpg"), w, h, hide=("SB_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 4, 1200), (0, 4, 0), ortho=500, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world_.color = (0.62, 0.78, 0.95)
        C["SB_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "sb_layout_topdown.jpg"), 2000, 2200)
