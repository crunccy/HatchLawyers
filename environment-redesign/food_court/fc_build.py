# environment-redesign/food_court/fc_build.py - STAGE 5, island 4: FOOD COURT (2026-10-19).
# The game's "Food Court" zone as an oversized food festival on its own island. Route (return portal past the boss):
#   ARRIVAL (south) -> the FOOD COURT gate (ketchup + mustard bottles holding a hot dog) -> an orange path past giant
#   food (a burger, a fries box, statues of the game's food lawyers) -> THE FOOD COURT PLAZA (a soda fountain ringed by
#   eight stalls + seating) -> side paths to three EGG FIELDS (Picnic Park W, Dessert Garden E, Veggie Patch NE)
#   -> THE CHEESE BOARD (the boss arena: Prosecutor Big Cheese rolls 110 studs) -> RETURN HOME portal (north)
#   Blender -b --python environment-redesign/food_court/fc_build.py [-- norender | -- only=aerial,layout]
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import hl_world as W
import fc_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(5151)
polar = HI.polar

scene = K.reset(["Food_Court", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("FC_Terrain", "FC_Cliffs", "FC_Paths", "FC_Plaza", "FC_EggFields", "FC_Arena", "FC_Falls", "FC_Spinners", "FC_Sky",
          "FC_Labels", "FC_Gameplay_Markers"):
    K.col(n, "Food_Court")

I = HI.Island("Food_Court", rx=175, ry=215, seed=41, wobble=(7, 5, 3))
LAYOUT = {"island": "Food Court (game zone: Food Court)", "radius_xy": [175, 215], "places": [], "egg_spots": [],
          "fx": {"steam": [], "smoke": [], "spinners": []}}


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
BOARD_L, BOARD_W = 130.0, 72.0
BOARD = (0, round(PORTAL[1] - 22.4 - 6 - BOARD_L / 2))  # its north end stops 6 studs short of the portal stairs
BOARD_S = BOARD[1] - BOARD_L / 2
PLAZA, PLAZA_R = (0, -40), 34
FIELDS = {"Picnic Park": ((-112, -10), 34), "Dessert Garden": ((112, -40), 32), "Veggie Patch": ((92, 75), 24)}
print(f"[fc] island top at north = {I.r(90):.1f}, south = {I.r(270):.1f}; portal {PORTAL}; board {BOARD} (south end {BOARD_S})")

# ------------------------------------------------------------------ paths (orange, white dashed edges: the world's own)
pa = K.Mesh("Paths", C["FC_Paths"])
pa.cyl(*ARRIVAL, 22, 0, 0.35, "path", segs=64, studs=True)
pa.ring(20.6, 21.6, 0.35, 0.5, "path_edge", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
I.cover_circle(*ARRIVAL, 23)
SOUTH = [(0, ARR_Y + 14), (0, ARR_Y + 36), (-18, -122), (14, -96), (0, PLAZA[1] - PLAZA_R + 2)]
NORTH = [(0, PLAZA[1] + PLAZA_R - 2), (-14, 8), (0, BOARD_S + 1)]
W.path_curve(pa, I, SOUTH, w=12)
W.path_curve(pa, I, NORTH, w=12)
W.path_curve(pa, I, [(-PLAZA_R + 2, -40), (-58, -30), (-82, -18)], w=7)
W.path_curve(pa, I, [(PLAZA_R - 2, -40), (58, -46), (82, -44)], w=7)
W.path_curve(pa, I, [(-6, 12), (36, 40), (70, 66)], w=7)
pa.brick(0, BOARD[1] + BOARD_L / 2 + 3.5, 0, 14, 7, 0.35, "path")  # board -> portal stairs
I.cover_rect(0, BOARD[1] + BOARD_L / 2 + 3.5, 14, 7)
pa.done()

# ------------------------------------------------------------------ THE FOOD COURT PLAZA: tablecloth floor, soda fountain, stalls
pz = K.Mesh("Food_Court_Plaza", C["FC_Plaza"])
cell = 4.0
for i in range(-9, 10):
    for j in range(-9, 10):
        x, y = PLAZA[0] + i * cell, PLAZA[1] + j * cell
        if math.hypot(x - PLAZA[0], y - PLAZA[1]) < PLAZA_R - 1.5:
            pz.brick(x, y, 0, cell, cell, 0.4, "red" if (i + j) % 2 else "white", bevel=0.0)
pz.ring(PLAZA_R - 1.5, PLAZA_R, 0, 0.6, "white", cx=PLAZA[0], cy=PLAZA[1], segs=80, studs=True)
I.cover_circle(*PLAZA, PLAZA_R + 1)
PF = K.Frame(pz, PLAZA[0], PLAZA[1], 0, z=0.4)
P.soda_fountain(PF)
STALLS = ((30, "PIZZA", "red", lambda G: P.pizza_slice_upright(G.sub(0, 0, z=0.2), H=6, depth=1.2)),
          (60, "HOT DOGS", "mustard", lambda G: P.hot_dog(G, 0, 0, 0.2, L=7)),
          (120, "ICE CREAM", "frosting", lambda G: P.ice_cream(G, 0, 0, 0.2, 0.55)),
          (150, "LEMONADE", "yellow", lambda G: P.ball(G, 0, 0, 0.2, 2.4, "lemon", step=0.5)),
          (210, "DONUTS", "sky_blue", lambda G: P.donut_flat(G, 0, 0, 0.2, R=2.6, a=1.0)),
          (240, "POPCORN", "red", lambda G: (P.taper(G, 0, 0, 0.2, 1.6, 2.4, 3.6, "red", step=0.6, studs=False,
                                                       looks=lambda k: "red" if k % 2 == 0 else "white"),
                                             [P.ball(G, dx, dy, 3.6, 0.9, "cream_soft", step=0.4) for dx, dy in ((0, 0), (1.2, 0.6), (-1.1, 0.5), (0.2, -1.2), (-0.5, 1.2))])),
          (300, "NOODLES", "roof_teal", lambda G: (P.taper(G, 0, 0, 0.2, 1.2, 2.6, 2.2, "white", step=0.55, studs=False),
                                                   G.cyl(0, 0, 2.4, 2.2, 2.45, "lemon"))),
          (330, "BURGERS", "orange", lambda G: P.giant_burger(G, 0, 0, 0.36)))
for ang, name, color, prop in STALLS:
    x, y = polar(27, ang)
    SF = K.Frame(pz, PLAZA[0] + x, PLAZA[1] + y, ang - 90, z=0.4)
    P.food_stall(SF, name, color, prop)
    LAYOUT["fx"]["steam"].append(world(SF, 4.2, 2.8, 11.2))  # (the roof vent)
    top = world(SF, 0, -4.2, 11.4)
    P.festoon(K.Frame(pz, 0, 0, 0), tuple(top), (PLAZA[0] + 1.4, PLAZA[1] + 0.8, 21.6), n=10, sag=1.4)  # to the straw
for ang in (45, 135, 225, 315):  # outdoor seating between the fountain and the stalls (the cardinal lanes stay open)
    x, y = polar(16, ang)
    P.picnic_table(PF, x, y, rot=ang + 90, umbrella="red" if ang in (45, 225) else "yellow")
note("THE FOOD COURT PLAZA", *PLAZA, "tablecloth floor, a giant soda-cup fountain, 8 food stalls, seating, string lights")
pz.done()

# ------------------------------------------------------------------ buildings, giant food, statues, trucks, gate
bld = K.Mesh("Buildings", C["Buildings"])
SPIN = []  # (object name, builder(F), pivot xyz, seconds per turn)


def place(fn, x, y, rot, title, what, cover=None):
    F = K.Frame(bld, x, y, rot)
    fn(F)
    note(title, x, y, what)
    if cover:
        I.cover_rect(x, y, cover[0], cover[1], rot, pad=1)
    return F


place(lambda F: W.arrival_pad(F, accent="red", glow="glow_warm"), ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players", (18, 18))
place(P.food_gate, 0, ARR_Y + 26, 0, "FOOD COURT gate", "ketchup + mustard bottles holding a giant hot dog", (40, 9))
F = place(P.burger_barn, -118, 62, face_to(-118, 62, 0, 40), "BURGER BARN", "red barn diner; its giant burger sign turns", (32, 36))
pole = world(F, 18, -6, 0)
bld.cyl(pole[0], pole[1], 0.6, 0, 18, "metal_dark", segs=10)
bld.cyl(pole[0], pole[1], 1.4, 0, 1.0, "stone_dark", segs=12)
I.cover_circle(pole[0], pole[1], 2)
SPIN.append(("Spin_BurgerSign", lambda G: P.giant_burger(G, 0, 0, 0.6), (pole[0], pole[1], 18.0), 9.0))
F = place(lambda F: P.pizza_palace(F, slice_sign=False), 138, 26, face_to(138, 26, 0, 0), "PIZZA PALACE", "crenellated pizzeria; a pizza slice turns on the roof; oven smoke", (32, 26))
LAYOUT["fx"]["smoke"].append(world(F, 9, 6, 19.4))
sl = world(F, 0, 4, 11.6)
SPIN.append(("Spin_PizzaSlice", lambda G: P.pizza_slice_upright(G, H=11, depth=1.6), tuple(sl), 12.0))
F = place(P.fry_factory, -128, -92, face_to(-128, -92, 0, -40), "FRY FACTORY", "sawtooth-roof factory, a fries box on the roof, chimney steam", (36, 26))
LAYOUT["fx"]["steam"].append(world(F, 12, 7, 22.6))
F = place(P.donut_diner, 105, -118, face_to(105, -118, 0, -60), "DONUT DINER", "retro pink diner; its donut sign turns", (32, 24))
pole = world(F, 17, -5, 0)
bld.cyl(pole[0], pole[1], 0.6, 0, 16, "metal", segs=10)
bld.cyl(pole[0], pole[1], 1.4, 0, 1.0, "stone_dark", segs=12)
I.cover_circle(pole[0], pole[1], 2)
SPIN.append(("Spin_DonutSign", lambda G: P.donut_upright(G, 0.0), (pole[0], pole[1], 20.6), 10.0))
place(P.taco_tower, -82, 150, face_to(-82, 150, 0, 95), "TACO TOWER", "three stacked storeys, a giant taco on top", (26, 26))
place(P.noodle_house, 86, 150, face_to(86, 150, 0, 95), "NOODLE HOUSE", "two-tier roof, lanterns, a giant noodle bowl", (36, 26))
for (x, y, rot, body, sign, prop) in ((-44, -112, 90, "sky_blue", "ICE CREAM", lambda G: P.ice_cream(G, 0, 0, 0, 0.5)),
                                      (40, -132, -90, "red", "HOT DOGS", lambda G: P.hot_dog(G, 0, 0, 0, L=8))):
    P.food_truck(K.Frame(bld, x, y, rot), body=body, sign=sign, prop=prop)
    I.cover_rect(x, y, 18, 10, rot, pad=1)
note("Food trucks", 0, -120, "ICE CREAM + HOT DOGS trucks parked by the south path")
place(lambda F: W.return_portal(F, ring=("red", "red", "yellow"), rim="gold", runes="glow_warm", base_glow="glow_green",
                                keystone=P.cherry_keystone, sign_rot=20),
      PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "home WITH eggs, past the boss (crnuch's call)", (42, 50))
for (x, y, fn, r, title) in ((-52, -70, lambda: P.giant_burger(K.Frame(bld, 0, 0, 0), -52, -70, 1.5), 11.5, "Giant burger"),
                             (52, -72, lambda: P.giant_fries(K.Frame(bld, 0, 0, 0), 52, -72, 1.5, rot=-20), 8, "Giant fries box"),
                             (-42, 18, lambda: P.lawn_pizza(K.Frame(bld, 0, 0, 0), -42, 18, 11), 11.5, "Lawn pizza"),
                             (44, 2, lambda: P.lawn_pizza(K.Frame(bld, 0, 0, 0), 44, 2, 10), 10.5, "Lawn pizza")):
    fn()
    I.cover_circle(x, y, r)
    note(title, x, y, "giant food sculpture" if "Lawn" not in title else "a whole pizza lying on the lawn (walkable)")
bld.done()
stat = K.Mesh("Statue_Plinths", C["Buildings"])
for name, x, y, scale, facing in (("ChiliProsecutor", -40, -140, 4.0, -90), ("DragonFruitDuke", 36, -110, 3.6, 90),
                                  ("GrandGateauJustice", -58, 0, 2.3, -90)):
    stat.cyl(x, y, 9, 0, 2.0, "stone_warm", segs=24, studs=True)
    stat.ring(8.6, 9.4, 2.0, 2.4, "gold", cx=x, cy=y, segs=24)
    HI.lawyer(C["Buildings"], name, x, y, z=2.0, scale=scale, facing=facing)
    I.cover_circle(x, y, 10)
    note(f"Statue: {name}", x, y, f"the game's {name} lawyer at {scale}x on a plinth")
stat.done()

# the turning signs: one object each (pivoted in the ambience pass), their studs ride along (K.STUD_GROUP)
for name, fn, piv, secs in SPIN:
    m = K.Mesh(name, C["FC_Spinners"])
    K.STUD_GROUP = name
    fn(K.Frame(m, piv[0], piv[1], 0, z=piv[2]))
    K.STUD_GROUP = None
    m.done()
    LAYOUT["fx"]["spinners"].append({"name": name, "pivot": [round(v, 2) for v in piv], "seconds_per_turn": secs})

# ------------------------------------------------------------------ THE CHEESE BOARD + Prosecutor Big Cheese
ar = K.Mesh("Cheese_Board", C["FC_Arena"])
P.cheese_board(K.Frame(ar, *BOARD, 0), L=BOARD_L, Wd=BOARD_W)
AF = K.Frame(ar, 0, 0, 0)
W.marquee(AF, 0, BOARD_S - 6, 7.0, 22, 4, "THE CHEESE BOARD", size=1.5, post_h=7.0, panel="red", letters="gold")
for (x, y) in ((-46, BOARD[1] - 50), (46, BOARD[1] + 52)):
    for k in range(3):
        P.cracker(K.Frame(ar, 0, 0, 0, z=k * 0.9), x, y, 1.2, rot=k * 17)
P.grapes(AF, 48, BOARD[1] + 22, 1.4)
P.grapes(AF, -46, BOARD[1] + 34, 1.2)
for (x, y) in ((44, BOARD[1] - 32), (-44, BOARD[1] - 22), (-44, BOARD[1] + 56)):
    P.olive_pick(AF, x, y, 1.0)
P.cheese_wedge(AF, 50, BOARD[1] - 6, 1.2, rot=-90)
P.cheese_wedge(AF, -50, BOARD[1] + 18, 1.0, rot=90)
P.butter_knife(AF, 54, BOARD[1] + 44, 30, rot=90)
for (x, y) in ((-24, BOARD_S - 8), (24, BOARD_S - 8), (-24, BOARD[1] + BOARD_L / 2 + 6), (24, BOARD[1] + BOARD_L / 2 + 6)):
    P.condiment_lamp(AF, x, y, "ketchup" if x < 0 else "mustard")
ar.done()
I.cover_rect(*BOARD, BOARD_W + 4, BOARD_L + 4)
I.cover_rect(BOARD[0] - BOARD_W / 2 - 8, BOARD[1], 18, 16)
I.cover_rect(*BOARD, BOARD_W + 40, BOARD_L + 30, pad=0)  # (the decor ring round it)
note("THE CHEESE BOARD (boss arena)", *BOARD, f"open wooden board {BOARD_W:.0f} x {BOARD_L:.0f}: Big Cheese rolls 110 studs along it")
HI.boss(C["FC_Arena"], "BigCheese", 6, BOARD[1] - 12, scale=3.2, facing=180)

# ------------------------------------------------------------------ the three egg fields
fld = K.Mesh("Egg_Fields", C["FC_EggFields"])
mk = K.Mesh("Egg_Spots", C["FC_Gameplay_Markers"])
FF = K.Frame(fld, 0, 0, 0)
spots = []
# Picnic Park (W): blankets, baskets, watermelon slices, apples, a BBQ grill, picnic tables
(c, R) = FIELDS["Picnic Park"]
fld.ring(R, R + 1.2, 0, 0.4, "red", cx=c[0], cy=c[1], segs=64, studs=True)
for k, (dx, dy, rot, look) in enumerate(((-14, 12, 10, "red"), (12, 16, -15, "sky_blue"), (-16, -14, 25, "red"), (16, -12, 5, "yellow"))):
    P.picnic_blanket(FF, c[0] + dx, c[1] + dy, 5, 2.0, rot, look)
    P.basket(FF, c[0] + dx + 3, c[1] + dy - 3, rot + 20)
    I.cover_circle(c[0] + dx, c[1] + dy, 7.5)
for (dx, dy, rot, R_) in ((0, 24, 0, 5.5), (-26, 0, 80, 5.0), (24, -2, -70, 5.0)):
    P.watermelon_slice(FF, c[0] + dx, c[1] + dy, R_, 2.0, rot)
    I.cover_circle(c[0] + dx, c[1] + dy, R_ + 1)
for (dx, dy, r) in ((-4, -26, 2.8), (2, 4, 2.4), (-24, 18, 2.6)):
    P.apple(FF, c[0] + dx, c[1] + dy, r)
    I.cover_circle(c[0] + dx, c[1] + dy, r + 1)
g = (c[0] + 6, c[1] - 26)  # the BBQ grill (smoke)
fld.brick(g[0], g[1], 0, 6, 3.4, 3.2, "black", studs=False)
fld.brick(g[0], g[1], 3.2, 6.4, 3.8, 0.3, "metal")
for k in range(4):
    fld.brick(g[0] - 1.8 + k * 1.2, g[1], 3.5, 0.8, 2.6, 0.6, "sausage", studs=False, bevel=0.2)
I.cover_circle(*g, 4.5)
LAYOUT["fx"]["smoke"].append([g[0], g[1], 4.2])
for (dx, dy) in ((-20, -26), (26, 14)):
    P.picnic_table(FF, c[0] + dx, c[1] + dy, rot=30, umbrella="red")
    I.cover_circle(c[0] + dx, c[1] + dy, 5)
I.cover_circle(*c, R + 1.5, ground=True)
# Dessert Garden (E): pink frosting floor with sprinkles; lollipops, cupcakes, candy canes, donuts, ice-cream trees
(c, R) = FIELDS["Dessert Garden"]
fld.cyl(*c, R, 0, 0.35, "frosting", segs=64, studs=True)
fld.ring(R, R + 1.4, 0, 0.6, "cream_soft", cx=c[0], cy=c[1], segs=64, studs=True)
for k in range(70):
    px, py = polar(K.rng.uniform(2, R - 2), K.rng.uniform(0, 360))
    fld.brick(c[0] + px, c[1] + py, 0.35, 0.9, 0.3, 0.2, K.rng.choice(P.SPRINKLES), rot=K.rng.uniform(0, 180), studs=False, bevel=0.05)
for k, (dx, dy, h, looks) in enumerate(((-18, 14, 12, ("red", "white")), (20, 18, 10, ("sky_blue", "white")),
                                        (-20, -16, 11, ("lemon", "frosting")), (14, -22, 12, ("lettuce", "white")))):
    P.lollipop(FF, c[0] + dx, c[1] + dy, h, 3.6, looks, rot=K.rng.uniform(0, 180))
    I.cover_circle(c[0] + dx, c[1] + dy, 4.4)
for (dx, dy, s, wr) in ((0, 22, 1.3, "sky_blue"), (-24, 0, 1.1, "lemon"), (24, -2, 1.2, "lettuce")):
    P.cupcake(FF, c[0] + dx, c[1] + dy, s, wr, "frosting" if wr != "sky_blue" else "cream_soft")
    I.cover_circle(c[0] + dx, c[1] + dy, 3.6 * s + 1)
for (dx, dy, rot) in ((-6, -26, 30), (8, 6, -60), (-10, 6, 120)):
    P.candy_cane(FF, c[0] + dx, c[1] + dy, 10, rot)
    I.cover_circle(c[0] + dx, c[1] + dy, 3.4)
for (dx, dy, fr) in ((2, -10, "choc"), (-26, 18, "frosting")):
    P.donut_flat(FF, c[0] + dx, c[1] + dy, 0.35, R=4.0, a=1.6, frost=fr)
    I.cover_circle(c[0] + dx, c[1] + dy, 6)
I.cover_circle(*c, R + 1.5, ground=True)
# Veggie Patch (NE, beside the board): raised beds with giant carrots, broccoli trees, giant tomatoes
(c, R) = FIELDS["Veggie Patch"]
fld.cyl(*c, R, 0, 0.3, "dirt", segs=56, studs=True)
fld.ring(R, R + 1.0, 0, 0.8, "wood", cx=c[0], cy=c[1], segs=56, studs=True)
BF = K.Frame(fld, 0, 0, 0, z=0.3)
for k, (dx, dy) in enumerate(((-8, 9), (9, 9), (-8, -9), (9, -9))):
    P.garden_bed(BF, c[0] + dx, c[1] + dy, 11, 5, 0)
    for j in range(3):
        P.carrot(K.Frame(fld, 0, 0, 0, z=0.9), c[0] + dx - 3.5 + j * 3.5, c[1] + dy, 0.75)
    I.cover_rect(c[0] + dx, c[1] + dy, 12, 6)
for (dx, dy) in ((-17, 0), (18, 1)):
    P.broccoli(FF, c[0] + dx, c[1] + dy, 1.1)
    I.cover_circle(c[0] + dx, c[1] + dy, 4.5)
for (dx, dy) in ((0, 18), (0, -19)):
    P.ball(FF, c[0] + dx, c[1] + dy, 0.3, 2.6, "tomato", squash=0.85, step=0.5)
    FF.brick(c[0] + dx, c[1] + dy, 4.6, 2.2, 0.6, 0.4, "veg_green", rot=45, studs=False)
    FF.brick(c[0] + dx, c[1] + dy, 4.6, 2.2, 0.6, 0.4, "veg_green", rot=-45, studs=False)
    I.cover_circle(c[0] + dx, c[1] + dy, 3.6)
I.cover_circle(*c, R + 1.5, ground=True)
for name, (c, R) in FIELDS.items():
    target = 8 if name != "Veggie Patch" else 4
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
        blocked = blocked or any(fn(ex, ey, 2.4) for fn in I.cover_fns)  # (the raised beds are rectangles)
        if blocked or any((ex - qx) ** 2 + (ey - qy) ** 2 < 49 for qx, qy, _ in spots):
            continue
        spots.append((ex, ey, name))
        got += 1
for (dx, dy) in ((-22, -40), (22, -40), (-22, 40), (22, 40)):
    spots.append((BOARD[0] + dx, BOARD[1] + dy, "THE CHEESE BOARD (bonus, on the boss arena)"))
for i, (x, y, where) in enumerate(spots):
    z = 1.2 if "BOARD" in where else 0.0
    W.egg_spot(K.Frame(mk, 0, 0, 0, z=z), x, y)
    if i % 3 == 0:
        P.food_egg(K.Frame(fld, 0, 0, 0, z=z), x, y, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
for name, (c, R) in FIELDS.items():
    note(name + " (egg field)", *c, "egg field")
fld.done()
mk.done()

# ------------------------------------------------------------------ lamps along the paths (condiment bottles)
props = K.Mesh("Path_Props", C["Shared_Props"])
PR = K.Frame(props, 0, 0, 0)
for path in (SOUTH, NORTH):
    for k in range(len(path) - 1):
        (x0, y0), (x1, y1) = path[k], path[k + 1]
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        for t in (0.5,):  # (one pair per stretch: two crowded the plaza entrance)
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for sgn in (-1, 1):
                ox, oy = -math.sin(math.radians(a)) * sgn * 9.0, math.cos(math.radians(a)) * sgn * 9.0
                if not I.covered(x + ox, y + oy, 1.6):
                    P.condiment_lamp(PR, x + ox, y + oy, "ketchup" if (k + sgn) % 2 else "mustard")
                    I.cover_circle(x + ox, y + oy, 1.6)
props.done()


# ------------------------------------------------------------------ soda + chocolate falls (angles chosen clear of everything)
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


falls = K.Mesh("Falls", C["FC_Falls"])
A_SODA = clear_fall(232)
I.waterfall(falls, A_SODA, stream=22, look="soda_fall", pond_look="soda", bank="white")
A_CHOC = clear_fall(330)
I.waterfall(falls, A_CHOC, stream=22, look="choco_fall", pond_look="choco", bank="crust")
falls.done()
print(f"[fc] soda falls at {A_SODA}, chocolate falls at {A_CHOC}")
note("Soda falls", *polar(I.r(A_SODA) - 35, A_SODA), "an orange-soda pond, stream and waterfall")
note("Chocolate falls", *polar(I.r(A_CHOC) - 35, A_CHOC), "a chocolate pond, stream and waterfall")

# ------------------------------------------------------------------ terrain, orchards, hills, cliffs, sky
veg = K.Mesh("Vegetation", C["Vegetation"])
I.build_top(C["FC_Terrain"])
I.cover_circle(*PORTAL, 22)
groves, tries = [], 0
while len(groves) < 12 and tries < 4000:  # fruit-tree ORCHARDS, one fruit each
    tries += 1
    a = K.rng.uniform(0, 360)
    x, y = polar(K.rng.uniform(40, I.r(a) - 18), a)
    if not I.covered(x, y, 8) and all((x - gx) ** 2 + (y - gy) ** 2 > 32 ** 2 for gx, gy, _ in groves):
        groves.append((x, y, K.rng.choice(["orange", "apple_red", "lemon"])))
for gx, gy, fruit in groves:
    for k in range(K.rng.randint(4, 7)):
        x, y = gx + K.rng.gauss(0, 7), gy + K.rng.gauss(0, 7)
        if I.covered(x, y, 4.5) or not I.inside(x, y, 8):
            continue
        P.fruit_tree(veg, x, y, K.rng.uniform(0.9, 1.25), fruit)
        I.cover_circle(x, y, 5, ground=False)
I.hills(veg, 6, rmin_f=0.62)
veg.done()
I.build_cliffs(C["FC_Cliffs"], lip=("grass_dark", "grass", "leaf_light"))
sk = K.Mesh("Clouds_Islets", C["FC_Sky"])
I.clouds(sk, n=14, islets=7)
sk.done()
I.grass_studs()
K.studs_done(C["Food_Court"])

lab = K.Mesh("Label_Plates", C["FC_Labels"])
for text, x, y in (("ARRIVAL", 0, ARR_Y), ("FOOD COURT GATE", 0, ARR_Y + 33), ("THE FOOD COURT\nplaza", 0, -40),
                   ("EGG FIELD\nPicnic Park", -112, -10), ("EGG FIELD\nDessert Garden", 112, -40), ("EGG FIELD\nVeggie Patch", 92, 75),
                   ("THE CHEESE BOARD\nboss arena", 0, BOARD[1]), ("RETURN HOME\nportal", 0, PORTAL[1] + 6), ("BURGER BARN", -118, 62),
                   ("PIZZA PALACE", 138, 26), ("FRY FACTORY", -128, -92), ("DONUT DINER", 105, -118), ("TACO TOWER", -82, 150),
                   ("NOODLE HOUSE", 86, 150), ("CHILI", -40, -140), ("DRAGON FRUIT", 36, -110), ("GATEAU", -58, 0),
                   ("SODA FALLS", *polar(I.r(A_SODA) - 35, A_SODA)), ("CHOCOLATE FALLS", *polar(I.r(A_CHOC) - 35, A_CHOC)),
                   ("N", 0, I.r(90) + 14)):
    HI.label(C["FC_Labels"], lab, text, x, y, 5.5)
lab.done()

# a sunny afternoon (the warmth comes from the palette: a peach horizon flooded the whole aerial)
world_, sun = K.sky_and_sun(scene, sun_energy=3.8, sun_rot=(48, 6, -30), sky=(0.24, 0.5, 0.95), horizon=(0.72, 0.8, 0.95))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "food_court.blend"), compress=True)
with open(os.path.join(HERE, "fc_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[fc] saved; {len(spots)} egg spots")

CAMS = {
    "aerial": (("Cam_Aerial", (-270, -640, 450), (0, 0, -25), 34), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, ARR_Y - 4, 9), (0, -90, 14), 24), 1920, 1080),
    "ground_plaza": (("Cam_Ground_Plaza", (-6, -84, 9), (4, -36, 11), 22), 1920, 1080),  # (through the south entrance gap)
    "ground_arena": (("Cam_Ground_Arena", (0, BOARD_S - 34, 21), (2, BOARD[1] + 40, 8), 24), 1920, 1080),
    "ground_fields": (("Cam_Ground_Fields", (70, -52, 10), (118, -36, 6), 24), 1920, 1080),
    "cliff": (("Cam_Cliff", (-330, -230, -40), (-150, -100, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"fc_{key}.jpg"), w, h, hide=("FC_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 4, 1200), (0, 4, 0), ortho=500, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world_.color = (0.62, 0.78, 0.95)
        C["FC_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "fc_layout_topdown.jpg"), 2000, 2200)
