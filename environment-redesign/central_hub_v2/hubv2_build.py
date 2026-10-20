# environment-redesign/central_hub_v2/hubv2_build.py - the CENTRAL HUB v2 (2026-10-20, mr.robe's session; user's call:
# "also change the main island to v2"). crnuch's approved hub (../central_hub/hub_build.py, Stage 3: blockout/LAYOUT.md +
# his 5 decisions, the buildings in ../central_hub/hub_parts.py) kept exactly - plaza, avenue, rings, services, the 8 lots,
# the License Building, the waterfalls, the Arcade Pier - and rebuilt to the v2 standard of the islands (crnuch's Ocean
# Shore v2 benchmark): classic Roblox studs, NOT LEGO. Every mesh is an hl_classic.ClassicMesh (smooth Roblox shapes:
# real cylinders, balls, wedges), the island is one cohesive grass top over a chunky dirt band and layered rock slabs
# with craggy faces + hanging rocks (the v2 islands' underside), classic ball trees, cloud puffs + rock islets in the
# sky, and studs only on broad terrain / paving / structural tops. v1 (../central_hub/) is untouched.
#   Blender -b --python environment-redesign/central_hub_v2/hubv2_build.py [-- norender | -- only=<cam>,<cam>]
# 1 stud = 1 m, +Y = north (Roblox -Z). DYNAMIC (player firms) is its own collection: never ship it as scenery.
import bpy, math, os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
for _p in (HERE, os.path.join(ROOT, "kit"), os.path.join(ROOT, "central_hub"), os.path.join(ROOT, "briefcase_bay_v2")):
    sys.path.insert(0, _p)
import hl_kit as K
import hl_classic as CL
import hub_parts as P  # (crnuch's hub buildings, drawn here with smooth classic primitives)
import bbv2_detail as BD  # (Briefcase Bay v2's classic ball trees)

rng = random.Random(2026)
K.rng.seed(1018)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)

# ------------------------------------------------------------------ the approved plan (blockout/LAYOUT.md)
PLAZA_R = 58
INNER_ROAD = (62, 74)
SERVICE_R = 102
STREET = (131, 141)  # the outer ring street (firm frontage)
LOT_FRONT, LOT_W, LOT_D = 148, 56, 145
ISLAND_R = 332
PLOT_ANGLES = [60, 20, -20, -60, 240, 200, 160, 120]
AVENUE_W = 22
SPOKES = (22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5)
FIRMS = {1: ("supreme", 10), 2: ("glass", 8), 3: ("main", 6), 5: ("main", 5), 6: ("glass", 7), 7: ("main", 7)}  # 4 + 8 empty
WATERFALLS = (180, 0, -40, 220)
GAZEBOS = (40, 140)
TOP = ["Central_Hub", "Briefcase_Bay", "Pet_Park", "Brainrot_Zone", "Food_Court", "Ocean_Shore", "Space_Base",
       "Shared_Props", "Vegetation", "Buildings", "Environmental_Effects", "Lighting", "Presentation"]


def polar(r, deg):
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


def angdiff(a, b):
    return (a - b + 180) % 360 - 180


def island_r(deg):
    a = math.radians(deg)
    return ISLAND_R + 9 * math.sin(3 * a + 1.3) + 6 * math.sin(7 * a + 0.4) + 3 * math.sin(13 * a + 2.0)


scene = K.reset(TOP)
C = K.COLS
for n in ("Hub_Terrain", "Hub_Cliffs", "Hub_Roads", "Hub_Plaza", "Hub_Lots", "Hub_Services", "Hub_Water", "Hub_Sky",
          "Hub_Labels", "Hub_Firms_DYNAMIC"):
    K.col(n, "Central_Hub")

LAYOUT = {"services": [], "plots": []}


# ------------------------------------------------------------------ what covers the ground (for grass studs + planting)
def on_road(x, y, pad=0.0):
    r = math.hypot(x, y)
    a = math.degrees(math.atan2(y, x))
    if r < PLAZA_R + pad:
        return True
    if INNER_ROAD[0] - 1 - pad < r < INNER_ROAD[1] + 1 + pad or STREET[0] - 7 - pad < r < STREET[1] + 7 + pad:
        return True  # (street incl. both sidewalks)
    if abs(x) < AVENUE_W / 2 + 1 + pad and (y < 0 or r < 150):
        return True
    for sa in SPOKES:
        if INNER_ROAD[1] < r < STREET[0] and abs(r * math.sin(math.radians(angdiff(a, sa)))) < 6 + pad and abs(angdiff(a, sa)) < 90:
            return True
    return False


def in_lot(x, y, pad=0.0):
    r = math.hypot(x, y)
    a = math.degrees(math.atan2(y, x))
    for pa in PLOT_ANGLES:
        d = r * math.cos(math.radians(angdiff(a, pa))) - LOT_FRONT
        lat = r * math.sin(math.radians(angdiff(a, pa)))
        if -1 - pad < d < LOT_D + pad and abs(lat) < LOT_W / 2 + 1 + pad:
            return True
    return False


BUCKET = 16
FOOT = {}  # bucket -> [(x, y, r, ground)]: ground = no grass studs under it (ponds, paths, buildings)


def add_foot(x, y, r, ground=True):
    for bx in range(int((x - r - 8) // BUCKET), int((x + r + 8) // BUCKET) + 1):
        for by in range(int((y - r - 8) // BUCKET), int((y + r + 8) // BUCKET) + 1):
            FOOT.setdefault((bx, by), []).append((x, y, r, ground))


def covered(x, y, pad=0.0, ground_only=False):
    if on_road(x, y, pad) or in_lot(x, y, pad):
        return True
    for fx, fy, fr, g in FOOT.get((int(x // BUCKET), int(y // BUCKET)), ()):
        if ground_only and not g:
            continue
        if (x - fx) ** 2 + (y - fy) ** 2 < (fr + pad) ** 2:
            return True
    return False


# ------------------------------------------------------------------ services + landmarks (placed first: footprints)
FX = {}  # name -> (fx object, frame) for the ambience pass


def place(fn, r, a, name, note, foot, fx=False, **kw):
    x, y = polar(r, a)
    m = CL.ClassicMesh(name, C["Hub_Services"])
    F = K.Frame(m, x, y, a - 90)
    if fx:  # moving parts in their own object (Environmental_Effects), animated by hub_ambience.py
        fm = CL.ClassicMesh(name + "_FX", C["Environmental_Effects"])
        fn(F, fx=K.Frame(fm, x, y, a - 90), **kw)
        FX[name] = (fm.done(), F)
    else:
        fn(F, **kw)
    m.done()
    add_foot(x, y, foot)
    LAYOUT["services"].append({"name": name, "x": round(x, 1), "y": round(y, 1), "roblox_xz": [round(x, 1), round(-y, 1)], "note": note})


place(P.license_building, 172, 90, "Law License Building", "licenses (crnuch: split from Upgrades)", 36)
place(P.travel_portal, SERVICE_R, 135, "Travel Portal", "Hub.TravelPortal; island destinations", 24, fx=True)
place(P.egg_incubator, SERVICE_R, 45, "Egg Incubator", "landmark only (crnuch's call); hatching stays in firms", 20)
place(P.shop, SERVICE_R, 225, "Shop", "Hub.ShopStall", 20)
place(P.upgrades, SERVICE_R, 315, "Upgrades", "Carry + Speed (crnuch: split from the License Office)", 20)
place(P.mutation_machine, SERVICE_R, 180, "Mutation Machine", "Hub.MergeMachine", 17)
place(P.bigcase_terrace, SERVICE_R, 0, "Big Case Terrace", "Hub.BigCaseBelt + minigame pads", 36, fx=True)
pob, pF = FX["Travel Portal"]
cx_, cy_ = pF.p(0, 2.6)
pob["pivot"] = (cx_, cy_, 4.6 + 15.2)
pob["axis"] = (-pF.s, pF.c, 0.0)  # local +y in world (the ring's normal)
bob, bF = FX["Big Case Terrace"]
bob["slide"] = (bF.c, bF.s, 0.0)  # local +x in world (along the belt)
lb = CL.ClassicMesh("Leaderboards", C["Hub_Services"])
for (x, y, title) in ((-22, -84, "RICHEST FIRMS"), (-22, -104, "MOST CASES WON"), (22, -84, "TOP LAWYER"), (22, -104, "BIGGEST PAYOUT")):
    P.leaderboard(K.Frame(lb, x, y, -90 if x < 0 else 90), title)
    add_foot(x, y, 8)
lb.done()
LAYOUT["services"].append({"name": "Leaderboards x4", "roblox_xz": [[-22, 84], [-22, 104], [22, 84], [22, 104]], "note": "facing the avenue"})
fo = CL.ClassicMesh("Statue_Fountain", C["Hub_Plaza"])
P.statue_fountain(K.Frame(fo, 0, 0, 0))
P.spawn_pad(K.Frame(fo, 0, -36, 0))
fo.done()

# ------------------------------------------------------------------ roads, plaza, avenue
rd = CL.ClassicMesh("Roads", C["Hub_Roads"])
rd.ring(STREET[0], STREET[1], 0, 0.3, "road", segs=220, studs=True)
for r0, r1, z1, lk in ((STREET[0] - 1, STREET[0], 0.7, "curb"), (STREET[1], STREET[1] + 1, 0.7, "curb"),
                       (STREET[1] + 1, STREET[1] + 6, 0.6, "stone_warm"), (STREET[0] - 6, STREET[0] - 1, 0.6, "stone_warm")):
    rd.ring(r0, r1, 0, z1, lk, segs=220, studs=(lk != "curb"))
for k in range(150):  # dashed centre line
    a = k * 360 / 150
    if all(abs(angdiff(a, s)) > 3 for s in (90, 270)):
        x, y = polar(136, a)
        rd.brick(x, y, 0.3, 2.4, 0.5, 0.12, "white", rot=a + 90, studs=False, bevel=0.03)
rd.ring(*INNER_ROAD, 0, 0.35, "stone_warm", segs=140, studs=True)
rd.ring(INNER_ROAD[0] - 1, INNER_ROAD[0], 0, 0.7, "curb", segs=140)
rd.ring(INNER_ROAD[1], INNER_ROAD[1] + 1, 0, 0.7, "curb", segs=140)
# the avenue: marble with a gold inlay, north to the License stairs, south to the bridge
for y0, y1 in ((PLAZA_R - 2, 146), (-island_r(270) + 2, -PLAZA_R + 2)):
    L = y1 - y0
    rd.brick(0, (y0 + y1) / 2, 0, AVENUE_W, L, 0.4, "marble", studs=True)
    rd.brick(0, (y0 + y1) / 2, 0.4, 1.2, L, 0.08, "gold", studs=False, bevel=0.02)
    for sx in (-1, 1):
        rd.brick(sx * (AVENUE_W / 2 + 0.5), (y0 + y1) / 2, 0, 1, L, 0.8, "curb", studs=False)
# crosswalks where the avenue and spokes cross the street
for a in (90, 270) + SPOKES:
    for k in range(6):
        x, y = polar(132 + k * 1.6, a)
        rd.brick(x, y, 0.3, 0.9, 8 if a in (90, 270) else 6, 0.1, "white", rot=a, studs=False, bevel=0.02)
# spokes: orange paths with white dashed edges (the game's path look)
for a in SPOKES:
    r0, r1 = INNER_ROAD[1] + 1, STREET[0] - 6
    cx, cy = polar((r0 + r1) / 2, a)
    rd.brick(cx, cy, 0, r1 - r0, 9, 0.4, "path", rot=a)
    for k in range(int((r1 - r0) / 2)):
        if k % 2 == 0:
            for sgn in (-1, 1):
                rr = r0 + k * 2 + 1
                ex, ey = polar(rr, a)
                ox, oy = -math.sin(math.radians(a)) * sgn * 4.7, math.cos(math.radians(a)) * sgn * 4.7
                rd.brick(ex + ox, ey + oy, 0.4, 1.4, 0.5, 0.12, "path_edge", rot=a, studs=False, bevel=0.03)
rd.done()

pz = CL.ClassicMesh("Plaza_Paving", C["Hub_Plaza"])
pz.cyl(0, 0, PLAZA_R, 0, 0.3, "stone", segs=96)
pz.ring(21, 30, 0.3, 0.45, "stone_warm", segs=96, studs=True)
for k in range(16):  # pie-pattern paving between r 30 and 46
    a0 = k * 22.5
    pts = [polar(30, a0), polar(46, a0), polar(46, a0 + 11.25), polar(46, a0 + 22.5), polar(30, a0 + 22.5), polar(30, a0 + 11.25)]
    pts = [pts[0], pts[5], pts[4], pts[3], pts[2], pts[1]][::-1]
    pz.prism(pts, 0.3, 0.45, "cobble" if k % 2 else "stone_warm", studs=True)
pz.ring(46, 47.2, 0.3, 0.6, "gold", segs=96)
pz.ring(47.2, PLAZA_R, 0.3, 0.45, "stone", segs=96, studs=True)
for k in range(12):  # benches, lamps, planters, between the 4 avenue/road openings
    a = k * 30 + 15
    if min(abs(angdiff(a, 90)), abs(angdiff(a, 270))) < 14:
        continue
    bx, by = polar(50, a)
    K.bench(pz, bx, by, rot=a - 90)
    lx, ly = polar(55.5, a + 8)
    K.lamp(pz, lx, ly, 11)
    px, py = polar(54, a - 9)
    K.planter(pz, px, py, 4, 4, plant="flowers" if k % 2 else "bush")
for a, text in ((80, "LAW LICENSES"), (135, "TRAVEL PORTAL"), (225, "SHOP"), (300, "ARCADE PIER")):
    x, y = polar(60, a)
    P.wood_sign(K.Frame(pz, x, y, a - 90), 0, 0, 5.0, 9, 2.4, text, size=1.0)
pz.done()

# services ring: paved forecourts from the inner road to each service, hedges along the road with gaps
fc = CL.ClassicMesh("Service_Forecourts", C["Hub_Roads"])
SERVICE_ANGLES = (135, 45, 225, 315, 180, 0)
for a in SERVICE_ANGLES:
    r0, r1 = INNER_ROAD[1] + 1, SERVICE_R - (8 if a in (0,) else 12)
    cx, cy = polar((r0 + r1) / 2, a)
    fc.brick(cx, cy, 0, r1 - r0 + 2, 16, 0.35, "stone_warm", rot=a)
    for sgn in (-1, 1):
        ox, oy = -math.sin(math.radians(a)) * sgn * 8.6, math.cos(math.radians(a)) * sgn * 8.6
        fc.brick(cx + ox, cy + oy, 0, r1 - r0 + 2, 1.0, 0.7, "curb", rot=a, studs=False)
        px, py = polar(r0 + 2.5, a)
        K.planter(fc, px + ox * 1.25, py + oy * 1.25, 3, 3, plant="flowers")
    for x, y in ((cx, cy),):
        add_foot(x, y, 9)
for k in range(120):
    a = k * 3.0 + 1.5
    if any(abs(angdiff(a, g)) < 9 for g in SERVICE_ANGLES + (90, 270)) or any(abs(angdiff(a, g)) < 5 for g in SPOKES):
        continue
    x, y = polar(INNER_ROAD[1] + 3.2, a)
    K.hedge(fc, x, y, 3.6, a + 90, h=2.2, w=2.2)
fc.done()

# avenue dressing: planters with trees + lamps with banners, both sides
av = CL.ClassicMesh("Avenue_Dressing", C["Hub_Roads"])
for y in list(range(80, 140, 16)) + list(range(-120, -300, -18)):
    for sx in (-1, 1):
        x = sx * (AVENUE_W / 2 + 4)
        if abs(y + 94) < 16:
            continue  # the leaderboards
        K.planter(av, x, y, 5, 5)
        K.lamp(av, x, y + 8, 12)
        K.banner(av, x + sx * 0.3, y + 8.6, 6.0, 5.0, 1.8, "purple" if y > 0 else "roof_blue", rot=0)
av.done()

# ------------------------------------------------------------------ the 8 lots + example firms (DYNAMIC)
lots = CL.ClassicMesh("Lots", C["Hub_Lots"])
for i, a in enumerate(PLOT_ANGLES):
    n = i + 1
    ox, oy = polar(LOT_FRONT, a)
    F = K.Frame(lots, ox, oy, a - 90)  # local -y faces the centre, +y runs out to the lot's back
    # in this frame local +y points OUT (away from the centre): a firm's street edge is y = 0
    F.brick(0, LOT_D / 2, 0, LOT_W, LOT_D, 0.6, "grass")
    for sx in (-1, 1):
        F.brick(sx * (LOT_W / 2 - 0.5), LOT_D / 2, 0, 1.0, LOT_D, 1.0, "stone", studs=False)
        for k in range(9):
            K.hedge(F, sx * (LOT_W / 2 + 2.2), 12 + k * 15, 12, 90)
        K.lamp(F, sx * (LOT_W / 2 - 3), 2.5, 11)
    F.brick(0, LOT_D - 0.5, 0, LOT_W, 1.0, 1.0, "stone", studs=False)
    F.brick(0, -3, 0, 20, 7, 0.65, "stone_warm")  # forecourt across the sidewalk
    LAYOUT["plots"].append({"plot": f"Plot{n}", "angle": a, "street_edge_roblox_xz": [round(ox, 1), round(-oy, 1)],
                            "yaw": round((a + 90) % 360, 1), "example": FIRMS.get(n, ("empty", 0))[0]})
lots.done()
for i, a in enumerate(PLOT_ANGLES):
    n = i + 1
    ox, oy = polar(LOT_FRONT, a)
    style = FIRMS.get(n)
    fm = CL.ClassicMesh(f"Plot{n}_Firm_EXAMPLE" if style else f"Plot{n}_EmptyLot", C["Hub_Firms_DYNAMIC"])
    F = K.Frame(fm, ox, oy, a - 90)  # the firm's front (-y) faces the centre; it is built outward along +y
    if not style:
        P.lot_sign(F)
    elif style[0] == "supreme":
        P.firm_supreme_tower(F, style[1])
    elif style[0] == "glass":
        P.firm_glass_office(F, style[1])
    else:
        P.firm_main_street(F, style[1])
    fm.done()

# ------------------------------------------------------------------ the island (v2, the Ocean Shore v2 look): one cohesive
# grass top with a chamfered rim, a chunky dirt band under it, layered rock slabs below with craggy faces, hanging rocks
# (gold crystals here and there), vines down the rim
N = 240
top = [polar(island_r(360 * i / N), 360 * i / N) for i in range(N)]
ter = CL.ClassicMesh("Island_Top", C["Hub_Terrain"])
ter.slab(top, -10, 0.0, "dirt", chamfer=0.4, top="grass")
ter.done()
cl = CL.ClassicMesh("Island_Cliffs", C["Hub_Cliffs"])
for k, (f, z0, z1, look) in enumerate(((0.93, -28, -10, "rock_warm"), (0.8, -48, -28, "rock"), (0.62, -70, -48, "rock_dark"),
                                      (0.42, -90, -70, "rock"), (0.22, -106, -90, "rock_dark"))):
    cl.slab([polar(island_r(360 * i / N) * f * (1 + 0.03 * math.sin(math.radians(9 * 360 * i / N) + f * 7)), 360 * i / N) for i in range(N)],
            z0, z1, look, chamfer=1.5)
for k in range(200):  # craggy rock faces round the rim (grass caps on the upper ones)
    a = rng.uniform(0, 360)
    t = rng.random()
    f = 0.99 if t < 0.55 else (0.92 if t < 0.85 else 0.79)
    z0 = -10 - rng.uniform(0, 14) if f > 0.95 else (-30 if f > 0.9 else -50)
    x, y = polar(island_r(a) * f - 1.5, a)
    s = rng.uniform(7, 15)
    cl.rock(x, y, z0, s, s * 0.8, rng.uniform(7, 16), rng.choice(("rock", "rock_dark", "rock_warm", "stone_dark")),
            top="grass_dark" if f > 0.95 and rng.random() < 0.6 else None, rot=a + rng.uniform(-20, 20))
for k in range(80):  # hanging rocks, a gold crystal under every eighth
    a = rng.uniform(0, 360)
    f = rng.uniform(0.2, 0.85)
    x, y = polar(island_r(a) * f, a)
    zt = -106 if f < 0.3 else (-70 - (0.62 - f) * 40 if f < 0.62 else -48)
    h = rng.uniform(10, 26)
    cl.rock(x, y, zt - h, rng.uniform(6, 12), rng.uniform(5, 10), h, rng.choice(("rock", "rock_dark")), rot=rng.uniform(0, 90), taper=-0.3)
    if k % 8 == 0:
        cl.cone(x, y, 2.2, zt - h - 1, zt - h - 9, "glow_gold", segs=6)
for k in range(260):  # the dirt band right under the grass rim, chunky + uneven
    a = k * 360 / 260 + rng.uniform(-0.5, 0.5)
    x, y = polar(island_r(a) - 0.6 + rng.uniform(-0.3, 0.6), a)
    cl.rock(x, y, -9.5 + rng.uniform(-1.5, 1.5), rng.uniform(4, 7), rng.uniform(3, 5), rng.uniform(4, 8), rng.choice(("dirt", "dirt_dark", "dirt")),
            rot=a + 90 + rng.uniform(-8, 8), jitter=0.12, taper=0.0)
for k in range(60):  # vines down the rim
    a = rng.uniform(0, 360)
    x, y = polar(island_r(a) + 0.3, a)
    L = rng.uniform(6, 18)
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    cl.beam((x, y, 0.0), (x + c * 0.2, y + s * 0.2, -L), 0.25, 0.25, "leaf_deep")
    for j in range(int(L / 2.2)):
        cl.brick(x + c * 0.3, y + s * 0.3, -1.2 - j * 2.2, 0.9, 0.5, 0.9, "grass_dark" if j % 2 else "leaf_deep", rot=a + j * 40, bevel=0.15)
cl.done()

# ------------------------------------------------------------------ water: ponds, streams, stepped waterfalls, mist
wt = CL.ClassicMesh("Waterfalls", C["Hub_Water"])
for a in WATERFALLS:
    er = island_r(a)
    px, py = polar(er - 44, a)
    wt.cyl(px, py, 10, -0.6, 0.15, "water", segs=28)
    wt.ring(10, 11.6, -0.6, 0.9, "stone", cx=px, cy=py, segs=28, studs=True)
    add_foot(px, py, 12)
    for k in range(int(30 / 2)):  # stream to the edge between stone banks
        r = er - 33 + k * 2
        sx, sy = polar(r, a)
        wt.brick(sx, sy, -0.4, 2.2, 5, 0.5, "water", rot=a, studs=False, bevel=0.0)
        for sgn in (-1, 1):
            bx, by = sx - math.sin(math.radians(a)) * sgn * 3.4, sy + math.cos(math.radians(a)) * sgn * 3.4
            wt.brick(bx, by, -0.4, 2.2, 1.6, 1.0 + rng.random() * 0.6, "stone", rot=a)
        add_foot(sx, sy, 4)
    # the fall: a curtain of water dropping clear of the cliff, streaked, with foam at the lip and mist below
    lip = er + 0.8
    for k in range(4):
        fx, fy = polar(lip + k * 0.9, a)
        wt.brick(fx, fy, -0.4 - k * 0.9, 1.2, 5.2, 0.9, "water_fall", rot=a, studs=False, bevel=0.2)
    fx, fy = polar(lip + 4.2, a)
    z = -3.0
    k = 0
    while z > -150:
        h = rng.uniform(6, 12)
        w = 12.0 + min(6.0, k * 0.5) + rng.uniform(-1.5, 1.5)
        sway = rng.uniform(-0.8, 0.8)
        ox_, oy_ = -math.sin(math.radians(a)) * sway, math.cos(math.radians(a)) * sway
        wt.brick(fx + ox_, fy + oy_, z - h, 1.8, w, h, "water_fall", rot=a, studs=False, bevel=0.3)
        for e in (-1, 1):  # white water along both edges
            ex, ey = -math.sin(math.radians(a)) * e * (w / 2 - 0.4), math.cos(math.radians(a)) * e * (w / 2 - 0.4)
            wt.brick(fx + ox_ + ex + math.cos(math.radians(a)) * 0.6, fy + oy_ + ey + math.sin(math.radians(a)) * 0.6, z - h, 0.8, 1.2, h,
                     "glow_white", rot=a, studs=False, bevel=0.2)
        if k % 2 == 0:
            sx_ = rng.uniform(-w / 3, w / 3)
            ox, oy = -math.sin(math.radians(a)) * sx_, math.cos(math.radians(a)) * sx_
            wt.brick(fx + ox + math.cos(math.radians(a)) * 0.8, fy + oy + math.sin(math.radians(a)) * 0.8, z - h * 0.8, 0.3, 0.6, h * 0.6,
                     "glow_white", rot=a, studs=False, bevel=0.1)
        z -= h * 0.92
        k += 1
    wt.brick(fx, fy, -1.2, 3.0, 7.0, 1.2, "glow_white", rot=a, studs=False, bevel=0.5)  # foam at the lip
    for j in range(7):  # mist cloud where it fades out
        mx, my = polar(lip + rng.uniform(-4, 14), a + rng.uniform(-3, 3))
        w = rng.uniform(10, 22)
        wt.brick(mx, my, -150 + rng.uniform(-6, 8), w, w * 0.8, rng.uniform(5, 10), "white", rot=a + rng.uniform(0, 40))
wt.done()

# ------------------------------------------------------------------ landscaping: wedge gardens, lookouts, gazebos, trees
veg = CL.ClassicMesh("Vegetation", C["Vegetation"])
props = CL.ClassicMesh("Garden_Props", C["Shared_Props"])
wedges = [40, 0, -40, 220, 180, 140]
for w in wedges:
    er = island_r(w)
    # a path from the street's sidewalk out to a cliff lookout
    r0, r1 = STREET[1] + 6, er - 12
    if w in WATERFALLS:
        r1 = er - 58
    cx, cy = polar((r0 + r1) / 2, w + (6 if w in WATERFALLS else 0))
    pa = w + (6 if w in WATERFALLS else 0)
    props.brick(cx, cy, 0, r1 - r0, 6, 0.4, "path", rot=pa)
    for k in range(0, int(r1 - r0), 14):
        lx, ly = polar(r0 + k + 6, pa)
        ox, oy = -math.sin(math.radians(pa)) * 4.5, math.cos(math.radians(pa)) * 4.5
        K.lamp(props, lx + ox, ly + oy, 9)
    for k in range(int((r1 - r0) / 3)):
        x, y = polar(r0 + k * 3, pa)
        add_foot(x, y, 4)
    if w not in WATERFALLS:  # lookout with a railing, benches and a telescope
        lx, ly = polar(er - 14, w)
        props.cyl(lx, ly, 8, 0, 0.6, "stone_warm", segs=24, studs=True)
        for k in range(-3, 4):
            a0, a1 = w + k * 20, w + (k + 1) * 20
            x0, y0 = polar(8, a0)
            x1, y1 = polar(8, a1)
            K.railing(props, lx + x0, ly + y0, lx + x1, ly + y1, 0.6, 2.4, "white")
        K.bench(props, lx - math.cos(math.radians(w)) * 3, ly - math.sin(math.radians(w)) * 3, rot=w + 90)
        tx, ty = polar(5, w + 50)
        props.brick(lx + tx, ly + ty, 0.6, 0.6, 0.6, 3.6, "black", studs=False)
        props.brick(lx + tx, ly + ty, 4.2, 2.6, 0.9, 0.9, "gold", rot=w, studs=False, bevel=0.2)
        add_foot(lx, ly, 10)
    if w in GAZEBOS:  # a raised garden terrace with an octagonal gazebo
        gx, gy = polar(212, w + 9)
        props.cyl(gx, gy, 13, 0, 1.6, "stone", segs=8, studs=True)
        props.cyl(gx, gy, 11, 1.6, 2.2, "stone_warm", segs=8, studs=True)
        for k in range(8):
            px_, py_ = polar(9, k * 45 + 22.5)
            props.brick(gx + px_, gy + py_, 2.2, 1.2, 1.2, 8, "white", studs=False)
        props.cyl(gx, gy, 11.5, 10.2, 11.0, "white", segs=8)
        for k in range(4):
            props.cyl(gx, gy, 10.5 - k * 2.4, 11.0 + k * 1.2, 12.2 + k * 1.2, "roof_teal" if k % 2 == 0 else "teal", segs=8, studs=True)
        props.sphere(gx, gy, 16.6, 0.8, 0.8, 0.8, "gold", seg=8, rings=6)
        K.bench(props, gx, gy - 4, rot=0)
        add_foot(gx, gy, 15)

# flower beds + bushes inside the services ring, then trees everywhere that is free
for k in range(70):
    a = rng.uniform(0, 360)
    r = rng.uniform(INNER_ROAD[1] + 4, STREET[0] - 9)
    x, y = polar(r, a)
    if covered(x, y, 4):
        continue
    if k % 3 == 0:
        K.flowerbed(veg, x, y, rng.choice([4, 5, 6]), rng.choice([3, 4]), rot=a)
    else:
        K.bush(veg, x, y, rng.uniform(0.7, 1.1))
    add_foot(x, y, 3, ground=False)
# elevation: stepped grassy hills + rock outcrops in the outer gardens (studded tiers, dirt risers)
hills = 0
tries = 0
while hills < 14 and tries < 4000:
    tries += 1
    a = rng.uniform(0, 360)
    r = rng.uniform(205, island_r(a) - 26)
    x, y = polar(r, a)
    R = rng.uniform(11, 18)
    if covered(x, y, R + 4):
        continue
    tiers = rng.randint(2, 4)
    for k in range(tiers):
        rr = R * (1 - k / (tiers + 0.6))
        pts = [(x + rr * (1 + 0.12 * math.sin(3 * t + k)) * math.cos(t), y + rr * (1 + 0.12 * math.sin(3 * t + k)) * math.sin(t))
               for t in [math.tau * i / 18 for i in range(18)]]
        veg.prism(pts, k * 1.6, (k + 1) * 1.6 - 0.25, "dirt" if k == 0 else "dirt_dark")
        veg.prism([(x + (px - x) * 0.97, y + (py - y) * 0.97) for px, py in pts], (k + 1) * 1.6 - 0.25, (k + 1) * 1.6, "grass", studs=True)
    if rng.random() < 0.6:
        K.rocks(K.Frame(veg, x, y, 0, z=tiers * 1.6), 0, 0, 1.3, "rock")
    else:
        BD.park_tree(veg, x, y, tiers * 1.6, 1.1, "oak")
    add_foot(x, y, R + 2)
    hills += 1

# trees grow in GROVES (deliberate clusters with open lawns between), each grove one or two species
groves = []
while len(groves) < 46:
    a = rng.uniform(0, 360)
    r = rng.uniform(STREET[1] + 22, island_r(a) - 18)
    x, y = polar(r, a)
    if not covered(x, y, 6) and all((x - gx) ** 2 + (y - gy) ** 2 > 34 ** 2 for gx, gy, _ in groves):
        groves.append((x, y, rng.choice(["round", "round", "pine", "blossom", "mixed", "mixed"])))
for a in range(0, 360, 45):  # a few small groves inside the services ring
    x, y = polar(116, a + 22.5 + 6)
    groves.append((x, y, "small"))
for gx, gy, kind in groves:
    n = 4 if kind == "small" else rng.randint(7, 13)
    spread = 7 if kind == "small" else rng.uniform(10, 16)
    for i in range(n * 3):
        if n <= 0:
            break
        x, y = gx + rng.gauss(0, spread), gy + rng.gauss(0, spread)
        if covered(x, y, 5):
            continue
        s_ = rng.uniform(0.85, 1.3) if kind != "small" else rng.uniform(0.7, 0.9)
        pick = kind if kind in ("round", "pine", "blossom") else rng.choice(["round", "pine", "blossom", "round"])
        if pick == "round":
            BD.park_tree(veg, x, y, 0.0, s_, "oak")
        elif pick == "pine":
            BD.park_tree(veg, x, y, 0.0, s_, "conifer")
        else:
            BD.park_tree(veg, x, y, 0.0, s_ * 0.95, "blossom")
        add_foot(x, y, 4.5 * s_, ground=False)
        n -= 1
    for j in range(3):  # bushes + rocks at the grove's edge
        a = rng.uniform(0, 360)
        x, y = gx + math.cos(math.radians(a)) * spread * 1.6, gy + math.sin(math.radians(a)) * spread * 1.6
        if not covered(x, y, 3):
            (K.bush if j < 2 else K.rocks)(veg, x, y, rng.uniform(0.8, 1.1))
            add_foot(x, y, 3, ground=False)
for k in range(160):  # flowers + tufts scattered in the open grass
    a = rng.uniform(0, 360)
    r = math.sqrt(rng.uniform(0.05, 1)) * (island_r(a) - 6)
    x, y = polar(r, a)
    if covered(x, y, 2):
        continue
    veg.brick(x, y, 0.1, 0.9, 0.9, 0.8, rng.choice(["pink", "yellow", "white", "red", "purple"]), studs=False, bevel=0.15)
veg.done()
props.done()

# ------------------------------------------------------------------ Arcade Pier (south, off the edge) - mr.robe's booths go here
ap = CL.ClassicMesh("Arcade_Pier", C["Hub_Services"])
se = island_r(270)
L = 80
for k in range(int(L / 1.6)):  # plank bridge
    y = -(se - 2 + k * 1.6)
    ap.brick(0, y, -0.6, 14, 1.5, 0.6, "wood" if k % 2 else "wood_dark", studs=True)
for sgn in (-1, 1):
    ap.brick(sgn * 7.4, -(se + L / 2 - 2), -0.6, 0.8, L, 0.6, "wood_dark", studs=False)
    for k in range(9):
        y = -(se + k * 10)
        ap.brick(sgn * 7.4, y, 0, 0.8, 0.8, 3.4, "wood_dark", studs=False)
        ap.brick(sgn * 7.4, y, 3.4, 1.0, 1.0, 0.4, "gold", studs=False)
    ap.brick(sgn * 7.4, -(se + L / 2 - 2), 2.6, 0.3, L, 0.3, "wood", studs=False)
py0 = -(se + L + 52)
pier_isle = [(x * 0.2, y * 0.2 + py0) for x, y in top]
ap.prism(pier_isle, -20, -1, "rock_warm")
ap.prism([(x * 0.13, y * 0.13 + py0) for x, y in top], -40, -20, "rock")
ap.cone(0, py0, 24, -40, -76, "rock_dark", segs=8)
ap.brick(0, py0, -1, 84, 104, 1.2, "wood", studs=True)
for k, (x, y, title, canopy) in enumerate(((-24, py0 + 26, "LIE DETECTOR", "purple"), (24, py0 + 26, "FILING FRENZY", "roof_teal"),
                                            (-24, py0 - 14, "CASE STACK", "orange"), (24, py0 - 14, "ARCADE", "red"))):
    P.booth(K.Frame(ap, x, y, 0, z=0.2), 0, 0, title, canopy, lambda G: None)
lx, ly = 0, py0 - 44
for k in range(7):  # lighthouse
    ap.cyl(lx, ly, 4.4 - k * 0.3, 0.2 + k * 3, 3.2 + k * 3, "red" if k % 2 == 0 else "white", segs=16)
ap.cyl(lx, ly, 3.0, 21.2, 25, "glass", segs=12)
ap.cyl(lx, ly, 1.6, 21.6, 24.6, "glow_warm", segs=12)
ap.cone(lx, ly, 3.6, 25, 29, "red", segs=12)
ap.done()
LAYOUT["services"].append({"name": "Arcade Pier", "roblox_xz": [0, round(-py0, 1)], "note": "mr.robe's Arcade booths (LieDetector, FilingFrenzy, BriefcaseStack)"})

# ------------------------------------------------------------------ sky (v2): the sea far below, cloud puffs, rock islets
sea = CL.ClassicMesh("Sky_Sea", C["Hub_Sky"])
sea.cyl(0, 0, 5000, -330, -320, "water", segs=64)
sea.done()
sk = CL.ClassicMesh("Clouds_Islets", C["Hub_Sky"])
K.STUD_GROUP = sk.name  # (the ambience drifts this object)
for i in range(22):
    a = rng.uniform(0, 360)
    x, y = polar(rng.uniform(420, 680), a)
    z = rng.uniform(-190, 40)
    for j in range(rng.randint(6, 10)):
        r = rng.uniform(10, 24)
        sk.sphere(x + rng.uniform(-30, 30), y + rng.uniform(-18, 18), z + rng.uniform(-3, 9), r, r * 0.8, r * 0.55, "white", seg=14, rings=8)
for i in range(10):
    a = rng.uniform(0, 360)
    x, y = polar(rng.uniform(410, 560), a)
    z = rng.uniform(-70, 25)
    s = rng.uniform(12, 24)
    pts = [(x + s * (1 + 0.25 * math.sin(3 * t + x)) * math.cos(t), y + s * 0.8 * (1 + 0.2 * math.cos(2 * t + y)) * math.sin(t))
           for t in [math.tau * k / 12 for k in range(12)]]
    sk.slab(pts, z - 3, z, "dirt", chamfer=0.4, top="grass")
    for j in range(3):
        sk.rock(x, y, z - 3 - (j + 1) * s * 0.4, s * (1.2 - j * 0.3), s * (1.0 - j * 0.25), s * 0.42, rng.choice(("rock", "rock_dark")), rot=a + j * 20, taper=-0.3)
    BD.park_tree(sk, x + rng.uniform(-3, 3), y + rng.uniform(-3, 3), z, 0.9, rng.choice(("oak", "blossom", "conifer")))
K.STUD_GROUP = None
sk.done()

# studs (classic Roblox): broad terrain, paving, decks + structural tops only; leaves, flowers, water, glow, glass stay smooth
STUD_LOOKS = {"grass", "grass_dark", "path", "cobble", "stone", "stone_warm", "stone_dark", "marble", "floor", "sand", "curb",
              "wood", "wood_dark", "roof_red", "roof_blue", "roof_navy", "roof_teal", "brick_red", "cream", "kerb", "soil"}
K.studs_done(C["Central_Hub"], only=lambda o, look: look in STUD_LOOKS and not o.name.startswith(("Sky_", "Label", "Clouds")))

# ------------------------------------------------------------------ labels (layout render only)
LBL_Z = 260
lab = CL.ClassicMesh("Label_Plates", C["Hub_Labels"])


def label(text, x, y, size=8.0):
    cu = bpy.data.curves.new("Label", "FONT")
    cu.body = text
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size = size
    cu.font = K.font("rounded")
    ob = bpy.data.objects.new("Label_" + text[:16], cu)
    ob.location = (x, y, LBL_Z + 1)
    cu.materials.append(K.mat("white"))
    C["Hub_Labels"].objects.link(ob)
    lines = text.split("\n")
    lab.brick(x, y, LBL_Z - 0.6, max(len(t) for t in lines) * size * 0.6 + size, len(lines) * size * 1.25 + size * 0.4, 0.5, "ink", studs=False, bevel=0.0)


label("SPAWN PLAZA", 0, 22, 6)
for s in LAYOUT["services"]:
    if "x" in s:
        label(s["name"].upper(), s["x"], s["y"], 6)
for p in LAYOUT["plots"]:
    x, y = polar(LOT_FRONT + 72, p["angle"])
    label(p["plot"].upper() + ("\n" + p["example"] + " (example)" if p["example"] != "empty" else "\nempty lot"), x, y, 6)
label("ARCADE PIER", 0, py0, 7)
label("OUTER RING STREET", *polar(136, 101), 4.5)
label("N", 0, ISLAND_R + 34, 10)
lab.done()

# ------------------------------------------------------------------ light, cameras, renders
world, sun = K.sky_and_sun(scene, sun_energy=3.8, sun_rot=(52, 6, -40))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=48)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "central_hub_v2.blend"), compress=True)
import json
with open(os.path.join(HERE, "hubv2_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print("[hubv2] saved central_hub_v2.blend")

CAMS = {
    "aerial": (("Cam_Aerial", (-280, -860, 540), (10, 10, -40), 38), 2400, 1350),
    "aerial_close": (("Cam_Aerial_Close", (-160, -330, 190), (0, 40, 0), 30), 2400, 1350),
    "ground_plaza": (("Cam_Ground_Plaza", (0, -50, 10), (0, 172, 22), 24), 1920, 1080),
    "ground_street": (("Cam_Ground_Street", (*polar(134, -40), 9.0), (*polar(178, -8), 16.0), 22), 1920, 1080),
    "ground_portal": (("Cam_Ground_Portal", (-20, -6, 9), (-72, 72, 16), 26), 1920, 1080),
    "cliff": (("Cam_Cliff_Waterfall", (-520, 120, -40), (-300, 0, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"hubv2_{key}.jpg"), w, h, hide=("Hub_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, -110, 1200), (0, -110, 0), ortho=1000, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        C["Hub_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "hubv2_layout_topdown.jpg"), 2200, 2700)
