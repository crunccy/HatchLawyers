# environment-redesign/ocean_shore/os_build.py - STAGE 5, island 5: OCEAN SHORE (2026-10-19, mr.robe's session).
# The game's "Ocean Shore" zone as a sunny tropical beach on its own island: a sand beach all round a green middle.
# Route (return portal past the boss, as decided):
#   ARRIVAL (south, on the beach) -> the OCEAN SHORE gate (two giant surfboards + a driftwood beam) -> an orange path
#   past the lighthouse, statues of the game's Ocean lawyers -> SEASIDE PLAZA (a whale fountain ringed by eight beach
#   shacks) -> side paths to three EGG FIELDS (Coral Garden W, Tide Pools E, Sandcastle Beach NE)
#   -> THE SHARK DOCK (the boss arena over the lagoon: Magistrate Megalodon charges 130 studs) -> RETURN HOME (north)
#   Blender -b --python environment-redesign/ocean_shore/os_build.py [-- norender | -- only=aerial,layout]
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import hl_world as W
import os_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(5353)
polar = HI.polar

scene = K.reset(["Ocean_Shore", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("OS_Terrain", "OS_Beach", "OS_Cliffs", "OS_Paths", "OS_Plaza", "OS_EggFields", "OS_Arena", "OS_Lagoon", "OS_Falls",
          "OS_Spinners", "OS_Sky", "OS_Labels", "OS_Gameplay_Markers"):
    K.col(n, "Ocean_Shore")

I = HI.Island("Ocean_Shore", rx=185, ry=210, seed=53, wobble=(8, 5, 3))
LAYOUT = {"island": "Ocean Shore (game zone: Ocean Shore)", "radius_xy": [185, 210], "places": [], "egg_spots": [],
          "fx": {"spray": [], "bubbles": [], "spinners": [], "gull_rings": []}}


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


def face_to(x, y, tx, ty):
    return math.degrees(math.atan2(tx - x, -(ty - y)))


def world(F, lx, ly, lz):
    wx, wy = F.p(lx, ly)
    return [round(wx, 2), round(wy, 2), round(lz + F.z, 2)]


# the beach: everything outside the wavy shoreline is sand, the middle is grass (a 0.06 step up, the grass's edge)
def shore_r(a):
    return I.r(a) * 0.80 + 4.0 * math.sin(math.radians(5 * a) + 0.7) + 2.5 * math.sin(math.radians(11 * a) + 1.9)


def inland(x, y, margin=0.0):
    return math.hypot(x, y) < shore_r(math.degrees(math.atan2(y, x))) - margin


def on_beach(x, y, margin=0.0):
    return I.inside(x, y, margin) and not inland(x, y, -margin)


GRASS_Z = 0.06
ARR_Y = -round(I.r(270) - 30)
ARRIVAL = (0, ARR_Y)
PORTAL = (0, round(I.r(90) - 27))
DOCK_L, DOCK_W = 148.0, 72.0
DOCK = (0, round(PORTAL[1] - 22.4 - 6 - DOCK_L / 2))  # its north end stops 6 studs short of the portal stairs
DOCK_S, DOCK_N = DOCK[1] - DOCK_L / 2, DOCK[1] + DOCK_L / 2
PLAZA_R = 34
PLAZA = (0, round(DOCK_S - 12 - PLAZA_R))
LAG_HX, LAG_HY, LAG_RC = DOCK_W / 2 + 26, DOCK_L / 2 - 16, 20.0  # the lagoon round the dock's middle
FIELDS = {"Coral Garden": ((-114, PLAZA[1] + 30), 34), "Tide Pools": ((116, PLAZA[1]), 32), "Sandcastle Beach": ((122, 92), 24)}
print(f"[os] island top at north = {I.r(90):.1f}, south = {I.r(270):.1f}; portal {PORTAL}; dock {DOCK} ({DOCK_S}..{DOCK_N}); plaza {PLAZA}")


def rrect(cx, cy, hx, hy, rc, n=10):
    pts = []
    for (qx, qy, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + qx * (hx - rc) + rc * math.cos(a), cy + qy * (hy - rc) + rc * math.sin(a)))
    return pts


def in_lagoon(x, y, pad=0.0):
    dx, dy = abs(x - DOCK[0]) - (LAG_HX - LAG_RC), abs(y - DOCK[1]) - (LAG_HY - LAG_RC)
    return math.hypot(max(dx, 0.0), max(dy, 0.0)) < LAG_RC + pad


# ------------------------------------------------------------------ paths (orange, white dashed edges: the world's own)
pa = K.Mesh("Paths", C["OS_Paths"])
pa.cyl(*ARRIVAL, 22, 0, 0.35, "path", segs=64, studs=True)
pa.ring(20.6, 21.6, 0.35, 0.5, "path_edge", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
I.cover_circle(*ARRIVAL, 23)
SOUTH = [(0, ARR_Y + 14), (0, ARR_Y + 36), (-18, -122), (14, -98), (0, PLAZA[1] - PLAZA_R + 2)]
NORTH = [(0, PLAZA[1] + PLAZA_R - 2), (0, DOCK_S + 1)]
W.path_curve(pa, I, SOUTH, w=12)
W.path_curve(pa, I, NORTH, w=12)
W.path_curve(pa, I, [(-PLAZA_R + 2, PLAZA[1]), (-58, PLAZA[1] + 8), (-80, PLAZA[1] + 26)], w=7)
W.path_curve(pa, I, [(PLAZA_R - 2, PLAZA[1]), (58, PLAZA[1] - 4), (84, PLAZA[1])], w=7)
W.path_curve(pa, I, [(58, PLAZA[1] - 4), (74, -14), (80, 30), (94, 58), (106, 74)], w=7)  # (branches off the east path)
pa.brick(0, DOCK_N + 3.5, 0, 14, 7, 0.35, "path")  # dock -> portal stairs
I.cover_rect(0, DOCK_N + 3.5, 14, 7)
pa.done()

# ------------------------------------------------------------------ SEASIDE PLAZA: a wavy mosaic floor, the whale fountain, shacks
pz = K.Mesh("Seaside_Plaza", C["OS_Plaza"])
cell = 4.0
for i in range(-9, 10):
    for j in range(-9, 10):
        x, y = PLAZA[0] + i * cell, PLAZA[1] + j * cell
        d = math.hypot(x - PLAZA[0], y - PLAZA[1])
        if d < PLAZA_R - 1.5:
            band = int((d + 2.0 * math.sin(6 * math.atan2(y - PLAZA[1], x - PLAZA[0]))) / 4.5)
            pz.brick(x, y, 0, cell, cell, 0.4, ("white", "sky_blue", "white", "pastel_blue", "sand", "seafoam", "sand", "pastel_blue")[band % 8], bevel=0.0)
pz.ring(PLAZA_R - 1.5, PLAZA_R, 0, 0.6, "white", cx=PLAZA[0], cy=PLAZA[1], segs=80, studs=True)
I.cover_circle(*PLAZA, PLAZA_R + 1)
PF = K.Frame(pz, PLAZA[0], PLAZA[1], 0, z=0.4)
WF = PF.sub(0, 0, -90)  # (Big Blue faces south, toward the players arriving)
P.whale_fountain(WF)
LAYOUT["fx"]["spray"].append(world(WF, 0.8, 0, 14.2))
SHACKS = ((30, "SURF SHOP", "coral", lambda G: P.surfboard(G, 0, 0, 0, L=6.0, w=2.0, body="sky_blue", stripe="white", depth=0.5)),
          (60, "SHAVED ICE", "sky_blue", lambda G: (P.taper(G, 0, 0, 0, 0.4, 1.6, 2.6, "shell_cream", step=0.45, studs=False),
                                                    P.ball(G, 0, 0, 2.2, 1.9, "coral_pink", step=0.45, looks=lambda k: ("coral_pink", "sky_blue", "coral_yellow")[k // 3 % 3]))),
          (120, "SMOOTHIES", "coral_pink", lambda G: (P.ball(G, 0, 0, 0, 1.8, "wood_dark", step=0.45, studs=False),
                                                      G.cyl(0.5, 0, 0.2, 3.0, 5.6, "coral_pink", segs=6),
                                                      G.brick(-1.2, 0, 3.2, 1.6, 0.2, 1.0, "lemon" if "lemon" in K.PAL else "yellow", studs=False))),
          (150, "SEASHELLS", "teal", lambda G: P.shell(G, 0, 0, -0.6, R=2.6, depth=1.0)),
          (210, "BEACH TOYS", "yellow", lambda G: P.beach_ball(G, 0, 0, 1.6)),
          (240, "FISH & CHIPS", "navy", lambda G: P.fish(G, 0, L=5.0, body="fish_orange", depth=0.8)),
          (300, "SNORKELS", "purple", lambda G: (G.ring_v(-1.1, 0, 1.2, 0.5, 1.2, 0.6, "sky_blue", segs=10),
                                                 G.ring_v(1.1, 0, 1.2, 0.5, 1.2, 0.6, "sky_blue", segs=10),
                                                 G.brick(0, 0, 1.0, 1.2, 0.5, 0.4, "black", studs=False),
                                                 G.brick(2.4, 0.3, 0, 0.5, 0.5, 3.6, "coral_yellow", studs=False))),
          (330, "FLOATS", "red", lambda G: G.ring_v(0, 0, 1.6, 0.9, 2.0, 1.0, ["red", "white"], segs=8, gap=0.06)))
tops = []
for ang, name, color, prop in SHACKS:
    x, y = polar(26, ang)
    SF = K.Frame(pz, PLAZA[0] + x, PLAZA[1] + y, ang - 90, z=0.4)
    P.beach_shack(SF, name, color, prop)
    tops.append(world(SF, 0, -4.6, 10.6))
for k in range(len(tops)):  # bunting from each shack's sign to the next one's, round the ring (over the lanes too)
    P.bunting(K.Frame(pz, 0, 0, 0), tuple(tops[k]), tuple(tops[(k + 1) % len(tops)]), n=12, sag=1.2)
for ang in (45, 135, 225, 315):  # umbrella tables between the fountain and the shacks (the cardinal lanes stay open)
    x, y = polar(17, ang)
    G = PF.sub(x, y)
    G.cyl(0, 0, 1.6, 0, 2.6, "white", segs=14)
    P.umbrella(G, 0, 0, P.UMBRELLAS[(ang // 90) % len(P.UMBRELLAS)], h=6.8, R=3.6, towel=False)
    for sx in (-1, 1):
        G.brick(sx * 2.6, 0, 0, 1.4, 1.4, 1.5, "coral" if sx > 0 else "sky_blue", studs=False)
note("SEASIDE PLAZA", *PLAZA, "wavy mosaic floor, Big Blue the whale fountain, 8 beach shacks, umbrella tables, bunting")
pz.done()

# ------------------------------------------------------------------ buildings, landmarks, statues, gate
bld = K.Mesh("Buildings", C["Buildings"])
SPIN = []  # (object name, builder(F), pivot xyz, seconds per turn)


def place(fn, x, y, rot, title, what, cover=None):
    F = K.Frame(bld, x, y, rot)
    fn(F)
    note(title, x, y, what)
    if cover:
        I.cover_rect(x, y, cover[0], cover[1], rot, pad=1)
    return F


place(lambda F: W.arrival_pad(F, accent="roof_blue", glow="glow_cyan"), ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players (on the beach)", (18, 18))
place(P.ocean_gate, 0, ARR_Y + 26, 0, "OCEAN SHORE gate", "two giant surfboards + a driftwood beam, life rings, a starfish crest", (42, 9))
F = place(P.lighthouse, -128, -100, face_to(-128, -100, 0, -60), "LIGHTHOUSE", "red-and-white striped tower, keeper's cottage; its beam turns", (46, 24))
lamp = world(F, 0, 0, 34.9)


def beam(G):
    for sgn in (-1, 1):
        for (r0, r1, w, h) in ((3.2, 6.0, 0.8, 0.5), (6.0, 14.0, 1.4, 1.2), (14.0, 26.0, 2.2, 1.8), (26.0, 40.0, 3.2, 2.6)):
            G.brick(sgn * (r0 + r1) / 2, 0, -h / 2, r1 - r0, w, h, "beam_light", studs=False, bevel=0.0)


SPIN.append(("Spin_LighthouseBeam", beam, tuple(lamp), 8.0))
F = place(P.surf_club, -118, 62, face_to(-118, 62, 0, 40), "SURF CLUB", "two-storey beach house, surfboards along the front; its surfboard sign turns", (32, 26))
pole = world(F, 17, -6, 0)
bld.cyl(pole[0], pole[1], 0.6, 0, 16, "white", segs=10)
bld.cyl(pole[0], pole[1], 1.4, 0, 1.0, "stone_dark", segs=12)
I.cover_circle(pole[0], pole[1], 2)
SPIN.append(("Spin_SurfSign", lambda G: P.surfboard(G, 0, 0, 0, L=10.0, w=3.2, body="coral", stripe="white", depth=0.8), (pole[0], pole[1], 16.0), 10.0))
F = place(P.aquarium, 138, 26, face_to(138, 26, 0, 0), "AQUARIUM", "round mint aquarium with a glass dome; its fish sign turns on top", (32, 36))
top = world(F, 0, 0, 0)
bld.cyl(top[0], top[1], 0.3, 18.0, 22.4, "white", segs=8)
SPIN.append(("Spin_FishSign", lambda G: P.fish(G, 0, L=8.0, body="fish_blue", stripe="white", depth=1.2), (top[0], top[1], 22.4), 12.0))
place(P.boat_house, 105, -118, face_to(105, -118, 0, -60), "BOAT HOUSE", "plank boathouse, a sailboat on the slipway", (28, 34))
place(P.beach_cafe, -82, 150, face_to(-82, 150, 0, 95), "BEACH CAFE", "white cafe, teal awning, umbrella tables", (28, 32))
place(P.seaside_hotel, 86, 150, face_to(86, 150, 0, 95), "SEASIDE HOTEL", "three-storey peach hotel with balconies", (34, 28))
place(lambda F: P.shipwreck(F), -150, 18, 12, "SHIPWRECK", "a wrecked ship stuck in the west beach, a spilled treasure chest", (34, 40))
place(lambda F: W.return_portal(F, ring=("sky_blue", "blue", "white"), rim="gold", runes="glow_cyan", base_glow="glow_green",
                                keystone=P.shell_keystone, sign_rot=20),
      PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "home WITH eggs, past the boss (crnuch's call)", (42, 50))
for (x, y, s, title) in ((-46, -66, 1.6, "Giant sandcastle"), (50, -78, 1.3, "Giant sandcastle")):
    P.sandcastle(K.Frame(bld, 0, 0, 0), x, y, s=s, look="sand_wet" if x > 0 else "sand")
    I.cover_circle(x, y, 7 * s)
    note(title, x, y, "a studded sandcastle as tall as a house")
bld.done()
stat = K.Mesh("Statue_Plinths", C["Buildings"])
for name, x, y, scale, facing in (("HammerheadAdvocate", -40, -138, 5.0, -90), ("NarwhalMagistrate", 36, -112, 3.6, 90),
                                  ("TidalSovereign", -58, -8, 2.5, -90)):
    stat.cyl(x, y, 9, 0, 2.0, "stone_warm", segs=24, studs=True)
    stat.ring(8.6, 9.4, 2.0, 2.4, "gold", cx=x, cy=y, segs=24)
    ob = HI.lawyer(C["Buildings"], name, x, y, z=2.0, scale=scale, facing=facing)
    I.cover_circle(x, y, 10)
    note(f"Statue: {name}", x, y, f"the game's {name} lawyer at {scale}x on a plinth")
    print(f"[os] statue {name}: {ob.dimensions.z:.1f} studs tall")
stat.done()

for name, fn, piv, secs in SPIN:  # the turning signs: one object each (pivoted in the ambience pass), studs ride along
    m = K.Mesh(name, C["OS_Spinners"])
    K.STUD_GROUP = name
    fn(K.Frame(m, piv[0], piv[1], 0, z=piv[2]))
    K.STUD_GROUP = None
    m.done()
    LAYOUT["fx"]["spinners"].append({"name": name, "pivot": [round(v, 2) for v in piv], "seconds_per_turn": secs})

# ------------------------------------------------------------------ THE LAGOON + THE SHARK DOCK + Magistrate Megalodon
lg = K.Mesh("Lagoon", C["OS_Lagoon"])
LPTS = rrect(DOCK[0], DOCK[1], LAG_HX, LAG_HY, LAG_RC)
lg.prism(LPTS, -0.4, 0.08, "sand_wet")
lg.prism(rrect(DOCK[0], DOCK[1], LAG_HX - 0.2, LAG_HY - 0.2, LAG_RC - 0.2), 0.08, 0.3, "lagoon")
for i in range(len(LPTS)):  # a low sandy bank with a few rocks (gaps where the dock crosses)
    (x0, y0), (x1, y1) = LPTS[i], LPTS[(i + 1) % len(LPTS)]
    L = math.hypot(x1 - x0, y1 - y0)
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    nseg = max(1, int(L / 3))
    for k in range(nseg):
        t = (k + 0.5) / nseg
        bx, by = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        if abs(bx - DOCK[0]) < DOCK_W / 2 + 2:
            continue
        ox, oy = math.sin(math.radians(a)) * 1.2, -math.cos(math.radians(a)) * 1.2  # (outward: the outline runs CCW)
        lg.brick(bx + ox, by + oy, 0, L / nseg + 0.3, 2.4, 0.55, "sand_wet" if k % 3 else "sand", rot=a)
        if K.rng.random() < 0.12:
            K.rocks(K.Frame(lg, bx + ox * 1.6, by + oy * 1.6, 0), 0, 0, 0.7)
I.cover_fn(lambda x, y, p: in_lagoon(x, y, 2.4 + p))
LF = K.Frame(lg, 0, 0, 0, z=0.08)
for k in range(26):  # a little reef under the water, clear of the dock + the moorings
    for _ in range(40):
        x, y = K.rng.uniform(DOCK_W / 2 + 4, LAG_HX - 4) * K.rng.choice((-1, 1)), DOCK[1] + K.rng.uniform(-LAG_HY + 6, LAG_HY - 6)
        if in_lagoon(x, y, -3) and not any(abs(x - bx) < 5 and abs(y - by) < 8 for bx, by in ((-44, DOCK[1] - 22), (44, DOCK[1] + 18), (-44, DOCK[1] + 34), (44, DOCK[1] - 36))):
            break
    pick = k % 4
    if pick == 0:
        P.starfish(LF, x, y, 0, 0.8, K.rng.choice(("starfish", "coral_pink", "coral_yellow")))
    elif pick == 1:
        P.brain_coral(LF, x, y, 1.3, K.rng.choice(("coral_yellow", "coral_pink")))
    elif pick == 2:
        P.tube_coral(LF, x, y, K.rng.choice(("coral_pink", "coral_purple", "coral")))
    else:
        P.shell(LF, x, y, 0, R=1.2, rot=K.rng.uniform(0, 180), depth=0.6)
for (x, y, fn) in ((-44, DOCK[1] - 22, lambda F, x, y: P.sailboat(F, x, y, 0, hull="hull_blue", sail="white", stripe="coral", z=0.1)),
                   (44, DOCK[1] + 18, lambda F, x, y: P.sailboat(F, x, y, 180, hull="hull_red", z=0.1)),
                   (-44, DOCK[1] + 34, lambda F, x, y: P.rowboat(F, x, y, 0, hull="coral_yellow", z=0.1)),
                   (44, DOCK[1] - 36, lambda F, x, y: P.rowboat(F, x, y, 180, hull="teal", z=0.1))):
    fn(K.Frame(lg, 0, 0, 0), x, y)
for (x, y, lk) in ((-56, DOCK[1] - 44, "red"), (56, DOCK[1] - 6, "coral_yellow"), (-56, DOCK[1] + 10, "coral_yellow"), (56, DOCK[1] + 44, "red")):
    P.buoy(K.Frame(lg, 0, 0, 0), x, y, lk, z=0.1)
lg.done()
note("THE LAGOON", *DOCK, f"shallow turquoise water {2 * LAG_HX:.0f} x {2 * LAG_HY:.0f} round the dock's middle: boats, buoys, a little reef")

ar = K.Mesh("Shark_Dock", C["OS_Arena"])
P.shark_dock(K.Frame(ar, *DOCK, 0), L=DOCK_L, Wd=DOCK_W)
AF = K.Frame(ar, 0, 0, 0)
W.marquee(AF, 0, DOCK_S - 6, 7.0, 22, 4, "SHARK DOCK", size=1.6, post_h=7.0, panel="navy", letters="gold")
for sx in (-1, 1):
    W.wood_sign(AF, sx * 16, DOCK_S - 10, 2.6, 9, 2.6, "SHARK ZONE!", rot=sx * 12)
    P.tiki_lamp(AF, sx * 24, DOCK_S - 8)
    P.tiki_lamp(AF, sx * 24, DOCK_N + 6)
P.lifeguard_tower(AF, 52, DOCK[1] - LAG_HY - 10, rot=face_to(52, DOCK[1] - LAG_HY - 10, 0, DOCK[1]))
for (x, y, r) in ((-44, DOCK_N - 6, 15), (-47.2, DOCK_N - 3.4, -12)):
    P.crate(AF, x, y, 0, 1.0, r)
P.fishing_net(AF, 47, DOCK_N - 5, rot=10)
P.anchor(AF, -56, DOCK_N - 4, s=1.6, rot=20)
ar.done()
I.cover_rect(*DOCK, DOCK_W + 4, DOCK_L + 4)
I.cover_rect(0, DOCK_S - 8, 40, 12)  # (the marquee, signs + lamps at its south end)
I.cover_circle(52, DOCK[1] - LAG_HY - 10, 9)
I.cover_rect(-48, DOCK_N - 4, 16, 10)
I.cover_rect(47, DOCK_N - 5, 10, 6)
note("THE SHARK DOCK (boss arena)", *DOCK, f"open wooden dock {DOCK_W:.0f} x {DOCK_L:.0f} over the lagoon: Megalodon charges 130 studs along it")
mega = HI.boss(C["OS_Arena"], "Megalodon", 6, DOCK[1] - 12, z=1.2, scale=3.2, facing=180)
print(f"[os] Megalodon at 3.2x: {mega.dimensions.x:.1f} x {mega.dimensions.y:.1f} x {mega.dimensions.z:.1f}")

# ------------------------------------------------------------------ the three egg fields
fld = K.Mesh("Egg_Fields", C["OS_EggFields"])
mk = K.Mesh("Egg_Spots", C["OS_Gameplay_Markers"])
FF = K.Frame(fld, 0, 0, 0)
spots = []
# Coral Garden (W): pink sand, corals of every kind, giant shells, kelp, anemones, a treasure chest
(c, R) = FIELDS["Coral Garden"]
fld.cyl(*c, R, 0, 0.3, "sand_pink", segs=64, studs=True)
fld.ring(R, R + 1.4, 0, 0.6, "shell_cream", cx=c[0], cy=c[1], segs=64, studs=True)
GF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, s, lk) in ((-16, 14, 1.3, "coral"), (14, 18, 1.1, "coral_orange"), (-20, -12, 1.2, "coral_pink"), (18, -16, 1.0, "coral")):
    P.coral_branch(GF, c[0] + dx, c[1] + dy, s, lk)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5 * s)
for (dx, dy, lk) in ((0, 24, "coral_purple"), (-26, 2, "coral_pink"), (24, 0, "coral_purple")):
    P.coral_fan(GF, c[0] + dx, c[1] + dy, 4.2, lk)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.8)
for (dx, dy, r) in ((-6, -24, 2.6), (8, 4, 2.2)):
    P.brain_coral(GF, c[0] + dx, c[1] + dy, r)
    I.cover_circle(c[0] + dx, c[1] + dy, r + 1)
for (dx, dy, R_, rot) in ((-4, 12, 3.2, 20), (20, -30 + 8, 3.6, -40), (-24, 22, 2.8, 70)):
    P.shell(GF, c[0] + dx, c[1] + dy, 0, R=R_, rot=rot)
    I.cover_circle(c[0] + dx, c[1] + dy, R_ + 0.8)
for (dx, dy) in ((-10, -2), (12, -4), (2, -14)):
    P.anemone(GF, c[0] + dx, c[1] + dy, 1.1, K.rng.choice(("coral_pink", "coral_purple", "coral_yellow")))
    I.cover_circle(c[0] + dx, c[1] + dy, 2)
for (dx, dy) in ((-28, -14), (-26, -18), (28, 12), (26, 16), (6, 28)):
    P.kelp(GF, c[0] + dx, c[1] + dy, K.rng.uniform(5, 8))
    I.cover_circle(c[0] + dx, c[1] + dy, 1.6)
P.treasure_chest(GF, c[0] - 12, c[1] + 26, rot=-20)
I.cover_circle(c[0] - 12, c[1] + 26, 3.4)
for k in range(10):
    px, py = polar(K.rng.uniform(4, R - 4), K.rng.uniform(0, 360))
    if not I.covered(c[0] + px, c[1] + py, 2.4):
        P.starfish(GF, c[0] + px, c[1] + py, 0, K.rng.uniform(0.5, 0.8), K.rng.choice(("starfish", "coral_yellow", "coral_purple")))
I.cover_circle(*c, R + 1.5, ground=True)
# Tide Pools (E): wet sand with rock pools (bubbles), rocks, crabs, urchins, starfish
(c, R) = FIELDS["Tide Pools"]
fld.cyl(*c, R, 0, 0.3, "sand_wet", segs=64, studs=True)
fld.ring(R, R + 1.4, 0, 0.6, "rock", cx=c[0], cy=c[1], segs=64, studs=True)
TF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, R_) in ((-14, 12, 5.5), (12, 16, 4.6), (-16, -14, 4.8), (14, -12, 5.2), (0, 0, 3.6)):
    P.rock_pool(TF, c[0] + dx, c[1] + dy, R_)
    I.cover_circle(c[0] + dx, c[1] + dy, R_ + 2.4)
    LAYOUT["fx"]["bubbles"].append([round(c[0] + dx, 2), round(c[1] + dy, 2), 0.6, R_])
for (dx, dy, s) in ((0, 24, 1.3), (-26, 0, 1.1), (24, 0, 1.2)):
    K.rocks(TF, c[0] + dx, c[1] + dy, s * 1.4)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5 * s)
for (dx, dy, s) in ((6, -24, 1.0), (-6, 24, 0.9), (-24, 12, 0.8)):
    P.crab(TF, c[0] + dx, c[1] + dy, s)
    I.cover_circle(c[0] + dx, c[1] + dy, 3.4 * s)
for (dx, dy) in ((22, 18), (-22, -24), (20, -24)):
    P.urchin(TF, c[0] + dx, c[1] + dy, 1.0)
    I.cover_circle(c[0] + dx, c[1] + dy, 2.2)
I.cover_circle(*c, R + 1.5, ground=True)
# Sandcastle Beach (NE, on the beach): sandcastles, buckets, umbrellas, towels, a beach ball
(c, R) = FIELDS["Sandcastle Beach"]
fld.cyl(*c, R, 0, 0.3, "sand", segs=56, studs=True)
fld.ring(R, R + 1.0, 0, 0.7, "driftwood", cx=c[0], cy=c[1], segs=56, studs=True)
SBF = K.Frame(fld, 0, 0, 0, z=0.3)
for (dx, dy, s, fl) in ((-10, 8, 0.9, "red"), (10, -10, 0.8, "sky_blue"), (12, 12, 0.6, "coral_yellow")):
    P.sandcastle(SBF, c[0] + dx, c[1] + dy, s=s, look="sand_wet", flag=fl)
    I.cover_circle(c[0] + dx, c[1] + dy, 6.6 * s)
for (dx, dy, lk) in ((-12, -10, P.UMBRELLAS[0]), (2, 18, P.UMBRELLAS[3])):
    P.umbrella(SBF, c[0] + dx, c[1] + dy, lk, h=7.0, R=4.2, rot=K.rng.uniform(0, 90))
    I.cover_circle(c[0] + dx, c[1] + dy, 4.8)
for (dx, dy, lk) in ((-4, -2, "red"), (4, 4, "sky_blue"), (-18, 2, "coral_yellow")):
    P.bucket(SBF, c[0] + dx, c[1] + dy, lk, rot=K.rng.uniform(0, 180))
    I.cover_circle(c[0] + dx, c[1] + dy, 2.8)
P.beach_ball(SBF, c[0] + 16, c[1] - 2, 1.4)
I.cover_circle(c[0] + 16, c[1] - 2, 2)
I.cover_circle(*c, R + 1.5, ground=True)
for name, (c, R) in FIELDS.items():
    target = 8 if name != "Sandcastle Beach" else 4
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
for (dx, dy) in ((-22, -40), (22, -40), (-22, 40), (22, 40)):
    spots.append((DOCK[0] + dx, DOCK[1] + dy, "THE SHARK DOCK (bonus, on the boss arena)"))
for i, (x, y, where) in enumerate(spots):
    z = 1.2 if "DOCK" in where else 0.3
    W.egg_spot(K.Frame(mk, 0, 0, 0, z=z), x, y)
    if i % 3 == 0:
        P.ocean_egg(K.Frame(fld, 0, 0, 0, z=z), x, y, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
for name, (c, R) in FIELDS.items():
    note(name + " (egg field)", *c, "egg field")
fld.done()
mk.done()

# ------------------------------------------------------------------ tiki lamps along the paths
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
                P.tiki_lamp(PR, x + ox, y + oy)
                I.cover_circle(x + ox, y + oy, 1.6)
props.done()


# ------------------------------------------------------------------ waterfalls (angles chosen clear of everything)
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


falls = K.Mesh("Falls", C["OS_Falls"])
A_W = clear_fall(200)
I.waterfall(falls, A_W, stream=22, bank="rock")
A_E = clear_fall(338)
I.waterfall(falls, A_E, stream=22, bank="rock")
falls.done()
print(f"[os] falls at {A_W} and {A_E}")
note("West falls", *polar(I.r(A_W) - 35, A_W), "a rock pool, a stream and a waterfall off the edge")
note("East falls", *polar(I.r(A_E) - 35, A_E), "a rock pool, a stream and a waterfall off the edge")

# ------------------------------------------------------------------ the beach: umbrellas, chairs, boats, surfboards, shells ...
bd = K.Mesh("Beach_Decor", C["OS_Beach"])
BF = K.Frame(bd, 0, 0, 0)
KINDS = ([("umbrella", 4.8)] * 14 + [("chairs", 3.6)] * 6 + [("ball", 1.8)] * 6 + [("castle", 4.4)] * 5 + [("board", 2.2)] * 8 +
         [("board_flat", 4.6)] * 4 + [("rowboat", 5.6)] * 3 + [("drift", 3.6)] * 6 + [("shell", 2.4)] * 8 + [("star", 1.8)] * 14 +
         [("rocks", 3.2)] * 8 + [("bucket", 2.6)] * 5)
K.rng.shuffle(KINDS)
placed = 0
for kind, rad in KINDS:
    for _ in range(200):
        a = K.rng.uniform(0, 360)
        r0, r1 = shore_r(a) + 3 + rad, I.r(a) - 7 - rad
        if r1 <= r0:
            continue
        x, y = polar(K.rng.uniform(r0, r1), a)
        if not I.covered(x, y, rad):
            break
    else:
        continue
    out = a  # (facing out to sea)
    if kind == "umbrella":
        P.umbrella(BF, x, y, K.rng.choice(P.UMBRELLAS), h=K.rng.uniform(6.4, 7.6), R=K.rng.uniform(3.8, 4.8), rot=out - 90)
    elif kind == "chairs":
        for sgn in (-1, 1):
            cx, cy = x - math.sin(math.radians(out)) * sgn * 1.7, y + math.cos(math.radians(out)) * sgn * 1.7
            P.deck_chair(BF, cx, cy, rot=out + 90, look=K.rng.choice(("sky_blue", "coral", "yellow", "teal")))
    elif kind == "ball":
        P.beach_ball(BF, x, y, K.rng.uniform(0.9, 1.4))
    elif kind == "castle":
        P.sandcastle(BF, x, y, s=K.rng.uniform(0.45, 0.7), look="sand_wet", flag=K.rng.choice(("red", "sky_blue", "coral_yellow")))
    elif kind == "board":
        b, s_ = K.rng.choice(P.UMBRELLAS)
        P.surfboard(BF, x, y, 0, L=K.rng.uniform(6.5, 8.5), w=K.rng.uniform(1.8, 2.3), body=b, stripe=s_, rot=K.rng.uniform(0, 180), depth=0.45)
    elif kind == "board_flat":
        b, s_ = K.rng.choice(P.UMBRELLAS)
        P.surfboard_flat(BF, x, y, L=8.0, w=2.4, body=b, stripe=s_, rot=K.rng.uniform(0, 180))
    elif kind == "rowboat":
        P.rowboat(BF, x, y, rot=out - 90 + K.rng.uniform(-25, 25), hull=K.rng.choice(("hull_blue", "hull_red", "teal", "coral_yellow")))
    elif kind == "drift":
        P.driftwood(BF, x, y, K.rng.uniform(4.5, 7), K.rng.uniform(0, 180))
    elif kind == "shell":
        P.shell(BF, x, y, 0, R=K.rng.uniform(1.4, 2.2), rot=K.rng.uniform(0, 180), depth=0.8)
    elif kind == "star":
        P.starfish(BF, x, y, 0, K.rng.uniform(0.6, 1.0), K.rng.choice(("starfish", "coral_pink", "coral_yellow", "coral_purple")))
    elif kind == "rocks":
        K.rocks(BF, x, y, K.rng.uniform(0.9, 1.4), look=K.rng.choice(("rock", "rock_warm")))
    elif kind == "bucket":
        P.bucket(BF, x, y, K.rng.choice(("red", "sky_blue", "coral_yellow")), rot=K.rng.uniform(0, 180))
    I.cover_circle(x, y, rad, ground=kind not in ("star", "shell", "ball", "board", "board_flat"))
    placed += 1
bd.done()
print(f"[os] beach decor: {placed} of {len(KINDS)} placed")

# ------------------------------------------------------------------ terrain (sand top + the grass middle), palms, cliffs, sky
I.build_top(C["OS_Terrain"], look="sand")
GPTS = [polar(shore_r(360 * i / I.N), 360 * i / I.N) for i in range(I.N)]
gm = K.Mesh("Ocean_Shore_Grass", C["OS_Terrain"])
gm.prism(GPTS, -1.0, GRASS_Z, "grass")
for i in range(0, I.N, 2):  # a lighter grass lip along the shoreline (low, studless)
    a = 360 * i / I.N
    x, y = polar(shore_r(a) - 0.4, a)
    if not I.covered(x, y, 1.5):
        gm.brick(x, y, GRASS_Z - 0.2, 1.2, 2 * math.pi * shore_r(a) / I.N * 2 + 0.4, 0.42, "grass_dark", rot=a, studs=False, bevel=0.04)
gm.done()
I.top_look = "grass"  # (hills sit inland)
I.cover_circle(*PORTAL, 22)
veg = K.Mesh("Vegetation", C["Vegetation"])
I.groves(veg, 11, kinds=("palm",), margin=10, spacing=34, sizes=(4, 7), area=lambda x, y: on_beach(x, y, 4))
I.groves(veg, 6, kinds=("round", "round", "mixed"), margin=20, spacing=30, sizes=(4, 7), area=lambda x, y: inland(x, y, 10))
for k in range(30):  # single palms leaning over the beach
    for _ in range(60):
        a = K.rng.uniform(0, 360)
        x, y = polar(K.rng.uniform(shore_r(a) + 4, I.r(a) - 9), a)
        if not I.covered(x, y, 4.5):
            K.tree_palm(veg, x, y, K.rng.uniform(0.9, 1.2), lean=a + K.rng.uniform(-30, 30))
            I.cover_circle(x, y, 4.5, ground=False)
            break
I.hills(veg, 5, rmin_f=0.3, area=lambda x, y: inland(x, y, 20))
veg.done()
I.build_cliffs(C["OS_Cliffs"], earth=("sand_wet", "dirt", "sand_wet"), lip=("sand", "sand_wet", "sand"))
sk = K.Mesh("Clouds_Islets", C["OS_Sky"])
I.clouds(sk, n=14, islets=7)
sk.done()
I.top_look = "sand"
K.add_studs("sand", K.grid_in_polygon(I.top_pts(0.995), 0.0, keep=lambda x, y: not inland(x, y, -0.6) and not I.covered(x, y, ground_only=True)), "Ocean_Shore_Top")
K.add_studs("grass", K.grid_in_polygon(GPTS, GRASS_Z, keep=lambda x, y: inland(x, y, 1.2) and not I.covered(x, y, ground_only=True)), "Ocean_Shore_Grass")
K.studs_done(C["Ocean_Shore"])
LAYOUT["fx"]["gull_rings"] = [[0, 0, 176, 205, 26, 38], [0, DOCK[1], 30, 55, 26, 34]]

lab = K.Mesh("Label_Plates", C["OS_Labels"])
for text, x, y in (("ARRIVAL", 0, ARR_Y), ("OCEAN SHORE GATE", 0, ARR_Y + 33), ("SEASIDE PLAZA", *PLAZA),
                   ("EGG FIELD\nCoral Garden", *FIELDS["Coral Garden"][0]), ("EGG FIELD\nTide Pools", *FIELDS["Tide Pools"][0]),
                   ("EGG FIELD\nSandcastle Beach", *FIELDS["Sandcastle Beach"][0]), ("THE SHARK DOCK\nboss arena", *DOCK),
                   ("RETURN HOME\nportal", 0, PORTAL[1] + 6), ("LIGHTHOUSE", -128, -100), ("SURF CLUB", -118, 62), ("AQUARIUM", 138, 26),
                   ("BOAT HOUSE", 105, -118), ("BEACH CAFE", -82, 150), ("SEASIDE HOTEL", 86, 150), ("SHIPWRECK", -150, 18),
                   ("HAMMERHEAD", -40, -138), ("NARWHAL", 36, -112), ("TIDAL SOVEREIGN", -58, -8),
                   ("FALLS", *polar(I.r(A_W) - 35, A_W)), ("FALLS", *polar(I.r(A_E) - 35, A_E)), ("N", 0, I.r(90) + 14)):
    HI.label(C["OS_Labels"], lab, text, x, y, 5.5)
lab.done()

# a bright beach noon
world_, sun = K.sky_and_sun(scene, sun_energy=4.0, sun_rot=(46, 6, -28), sky=(0.18, 0.48, 0.98), horizon=(0.56, 0.77, 0.98))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "ocean_shore.blend"), compress=True)
with open(os.path.join(HERE, "os_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[os] saved; {len(spots)} egg spots")

CAMS = {
    "aerial": (("Cam_Aerial", (-270, -640, 450), (0, 0, -25), 34), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, ARR_Y - 4, 9), (0, -90, 14), 24), 1920, 1080),
    "ground_plaza": (("Cam_Ground_Plaza", (-6, PLAZA[1] - 44, 9), (4, PLAZA[1] + 4, 10), 22), 1920, 1080),  # (through the south lane)
    "ground_arena": (("Cam_Ground_Arena", (0, DOCK_S - 34, 21), (2, DOCK[1] + 40, 8), 24), 1920, 1080),
    "ground_fields": (("Cam_Ground_Fields", (74, PLAZA[1] - 14, 10), (118, PLAZA[1] + 2, 4), 24), 1920, 1080),
    "cliff": (("Cam_Cliff", (-330, -230, -40), (-150, -100, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"os_{key}.jpg"), w, h, hide=("OS_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 4, 1200), (0, 4, 0), ortho=500, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world_.color = (0.62, 0.78, 0.95)
        C["OS_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "os_layout_topdown.jpg"), 2000, 2200)
