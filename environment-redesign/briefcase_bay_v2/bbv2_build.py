# environment-redesign/briefcase_bay_v2/bbv2_build.py - BRIEFCASE BAY v2, the LAYOUT for crnuch's approval (2026-10-19),
# on the Ocean Shore v2 benchmark (classic Roblox studs, not LEGO; one continuous flat surface the boss roams; spawn and
# escape portal on opposite sides; egg regions across his box; all scenery outside his reach). Built round The Senior
# Partner's real numbers (Config.Bosses: Cone 45 radius x 110 deg, Windup 1.2, every 3.5 s, TriggerRange 60, WalkSpeed
# 38, Scale 3.5). A green headland park on a sheltered bay, limestone cliffs, the office skyline behind.
# v1 (../briefcase_bay/) is untouched.
#   Blender -b --python environment-redesign/briefcase_bay_v2/bbv2_build.py [-- norender | -- only=aerial,diagram]
import bpy, json, math, os, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_classic as CL
import hl_island as HI
import bbv2_parts as P
OP, OD = P.OP, P.OD

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(1907)
rng = P.rng

scene = K.reset(["Briefcase_Bay_V2", "Vegetation", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("BBV2_Terrain", "BBV2_Underside", "BBV2_Scenery", "BBV2_Skyline", "BBV2_Water", "BBV2_Play_Decor", "BBV2_Landmarks",
          "BBV2_Sky", "BBV2_Labels", "BBV2_Diagram", "BBV2_Gameplay_Markers", "BBV2_Preview_Eggs"):
    K.col(n, "Briefcase_Bay_V2")

# ------------------------------------------------------------------ the measured gameplay frame (Config.Bosses / Zones)
SENIOR = {"Scale": 3.5, "WalkSpeed": 38, "Chase": 0.85, "AttackEvery": 3.5, "Windup": 1.2, "Attack": "Cone", "Radius": 45,
          "Angle": 110, "StayNearMiddle": 14, "TriggerRange": 60, "HitboxWidth": 2 * 3.3 * 3.5, "HitboxBack": 1.4 * 3.5,
          "HitboxFront": 1.8 * 3.5, "HitboxHeight": 11.5 * 3.5, "ModelHeight": round(10.8 * 3.5, 1)}
DROP_MAX = 14 * (1 + 0.04 * 12)  # DropScatter max x the 12-egg Diamond Briefcase spread = 20.7 studs
REACH = SENIOR["Radius"]  # his swing reaches 45 studs from where he stands (his body only 11.6 to the side)
BOX = (-100.0, -85.0, 100.0, 85.0)  # his roaming box (x0, y0, x1, y1): the whole dangerous lawn
GM_MIN, GM_MAX = 30.0, 44.0  # the Green runs 30-44 studs past the box (organic): all of it inside his 45-stud swing
HX, HY = (BOX[2] - BOX[0]) / 2 + GM_MAX, (BOX[3] - BOX[1]) / 2 + GM_MAX  # the Green's bounding half sizes
BOUNDS = (BOX[0] - GM_MAX, BOX[1] - GM_MAX, BOX[2] + GM_MAX, BOX[3] + GM_MAX)  # suggested zone Bounds: covers the whole Green
SAND_Z = 1.0  # the playable surface's top (the Green)
CENTER = (0.0, 0.0)
SPAWN_DEG, PORTAL_DEG, BAY_DEG = 270.0, 90.0, 326.0
PATROL = 14  # today's StayNearMiddle band


def box_dist(x, y):
    dx = max(BOX[0] - x, 0, x - BOX[2])
    dy = max(BOX[1] - y, 0, y - BOX[3])
    return math.hypot(dx, dy)


def in_box(x, y, pad=0.0):
    return BOX[0] - pad <= x <= BOX[2] + pad and BOX[1] - pad <= y <= BOX[3] + pad


def _bump(deg, at, amp, sig):
    d = (deg - at + 180) % 360 - 180
    return amp * math.exp(-0.5 * (d / sig) ** 2)


def margin(deg):
    """How far the Green runs past his box at this angle: the scenery bites in at the bay, the cascade, the grotto and the
    east pool, the lawn swells by the lobes; always 30-44 (inside his 45-stud swing: no safe strip round the edge)."""
    a = math.radians(deg)
    m = 40 + 1.6 * math.sin(7 * a + 0.5) + 1.0 * math.sin(13 * a + 2.0)
    m -= _bump(deg, 326, 9, 13) + _bump(deg, 140, 7, 14) + _bump(deg, 198, 6, 12) + _bump(deg, 16, 6, 12) + _bump(deg, 236, 4, 10)
    m += _bump(deg, 64, 2, 10)
    return max(GM_MIN, min(GM_MAX, m))


def green_sd(x, y):
    """Signed distance to the Green's edge (negative inside): his box grown by margin() - round corners, organic sides."""
    return box_dist(x, y) - margin(math.degrees(math.atan2(y - CENTER[1], x - CENTER[0])))


def in_green(x, y, pad=0.0):
    return green_sd(x, y) < -pad


def polar(r, deg, c=CENTER):
    return (c[0] + r * math.cos(math.radians(deg)), c[1] + r * math.sin(math.radians(deg)))


def r_green(deg):
    lo, hi = 0.0, 400.0
    for _ in range(40):
        mid = (lo + hi) / 2
        if in_green(*polar(mid, deg)):
            lo = mid
        else:
            hi = mid
    return lo


def lobe(deg, at, amp, sig):
    d = (deg - at + 180) % 360 - 180
    return amp * math.exp(-0.5 * (d / sig) ** 2)


def ring_w(deg):
    a = math.radians(deg)
    w = 54 + 9 * math.sin(3 * a + 0.7) + 5 * math.sin(7 * a)
    w += lobe(deg, SPAWN_DEG, 26, 13) + lobe(deg, PORTAL_DEG, 30, 12)  # (room for the lobes)
    w += lobe(deg, 110, 18, 30)  # the skyline's deep back ring
    w += lobe(deg, BAY_DEG, 16, 14)  # the bay's headland
    return w


R_GREEN = {d: r_green(d) for d in range(0, 360)}


def rg(deg):
    d0 = int(math.floor(deg)) % 360
    t = deg - math.floor(deg)
    return R_GREEN[d0] * (1 - t) + R_GREEN[(d0 + 1) % 360] * t


def r_isl(deg):
    return rg(deg) + ring_w(deg)


def outline(fn, f=1.0, n=240):
    return [polar(fn(360 * i / n) * f, 360 * i / n) for i in range(n)]


LAYOUT = {"island": "Briefcase Bay v2 (layout for approval)", "places": [], "egg_regions": [], "egg_spots": [], "checks": {},
          "boss": {"name": "The Senior Partner", "box_blender": list(BOX), "box_roblox_xz": [BOX[0], -BOX[3], BOX[2], -BOX[1]],
                   "reach": REACH, "suggested_bounds_blender": list(BOUNDS),
                   "suggested_bounds_roblox_xz": [BOUNDS[0], -BOUNDS[3], BOUNDS[2], -BOUNDS[1]], **SENIOR}}


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


# ------------------------------------------------------------------ the island body: one cohesive piece + layered underside
ter = CL.ClassicMesh("Island_Top", C["BBV2_Terrain"])
ter.slab(outline(r_isl), -10, 0.6, "dirt_rim", chamfer=0.4, top="moss_dark")
green = CL.ClassicMesh("The_Green", C["BBV2_Terrain"])
GREEN_PTS = outline(rg, n=360)
green.slab(GREEN_PTS, -0.2, SAND_Z, "rock_grey_light", chamfer=0.3, top="lawn")
und = CL.ClassicMesh("Island_Underside", C["BBV2_Underside"])
for f, z0, z1, look in ((0.93, -26, -10, "rock_grey"), (0.8, -44, -26, "rock_grey_dark"), (0.62, -62, -44, "rock_grey"),
                        (0.42, -78, -62, "rock_grey_dark"), (0.22, -90, -78, "rock_grey")):
    und.slab(outline(lambda d, f=f: r_isl(d) * f * (1 + 0.03 * math.sin(math.radians(9 * d) + f * 7))), z0, z1, look, chamfer=1.5)
for k in range(150):  # craggy limestone faces round the rim, moss on the upper ones
    d = rng.uniform(0, 360)
    tier = rng.random()
    f = 0.99 if tier < 0.55 else (0.92 if tier < 0.85 else 0.79)
    z0 = -10 - rng.uniform(0, 14) if f > 0.95 else (-28 if f > 0.9 else -46)
    x, y = polar(r_isl(d) * f - 1.5, d)
    s = rng.uniform(6, 13)
    und.rock(x, y, z0, s, s * 0.8, rng.uniform(6, 14), rng.choice(("rock_grey", "rock_grey_dark", "rock_grey_light")),
             top="moss" if f > 0.95 and rng.random() < 0.6 else None, rot=d + rng.uniform(-20, 20))
for k in range(60):  # hanging rocks
    d = rng.uniform(0, 360)
    f = rng.uniform(0.2, 0.85)
    x, y = polar(r_isl(d) * f, d)
    zt = -90 if f < 0.3 else -62 - (0.62 - f) * 40 if f < 0.62 else -44
    h = rng.uniform(8, 22)
    und.rock(x, y, zt - h, rng.uniform(5, 10), rng.uniform(4, 9), h, rng.choice(("rock_grey", "rock_grey_dark")), rot=rng.uniform(0, 90), taper=-0.3)
for k in range(40):  # vines down the rim
    d = rng.uniform(0, 360)
    x, y = polar(r_isl(d) + 0.3, d)
    OP.vine(und, x, y, 0.4, rng.uniform(6, 18), d)
for k in range(220):  # the brown soil band right under the grass rim
    d = k * 360 / 220 + rng.uniform(-0.6, 0.6)
    x, y = polar(r_isl(d) - 0.6 + rng.uniform(-0.3, 0.6), d)
    und.rock(x, y, -9.5 + rng.uniform(-1.5, 1.5), rng.uniform(4, 7), rng.uniform(3, 5), rng.uniform(4, 8),
             rng.choice(("dirt_rim", "dirt_rim_dark", "dirt_rim")), rot=d + 90 + rng.uniform(-8, 8), jitter=0.12, taper=0.0)
for k in range(70):  # roots hanging out of the soil band
    d = rng.uniform(0, 360)
    x, y = polar(r_isl(d) + 0.4, d)
    p0 = (x, y, rng.uniform(-6, -2))
    for j in range(3):
        p1 = (p0[0] + rng.uniform(-0.6, 0.6), p0[1] + rng.uniform(-0.6, 0.6), p0[2] - rng.uniform(1.5, 3.2))
        und.beam(p0, p1, 0.3, 0.3, "root")
        p0 = p1
ter.done()
green.done()
und.done()

# ------------------------------------------------------------------ landmarks: the arrival terrace S, the escape portal N
lm = CL.ClassicMesh("Landmarks", C["BBV2_Landmarks"])
NECK_W = 16.0
SP_C = (0.0, BOX[1] - 81.0)  # the arrival terrace's centre
SPAWN = (0.0, SP_C[1] - 2.0)
PO_C = (0.0, BOX[3] + 78.0)  # the portal plaza's centre
PORTAL = (0.0, PO_C[1] + 4.0)
SP_R, PO_R = 18.0, 19.5


def circle(cx, cy, r, n=40, wob=0.0):
    return [(cx + r * (1 + wob * math.sin(3 * a + cx)) * math.cos(a), cy + r * (1 + wob * math.sin(3 * a + cx)) * math.sin(a))
            for a in [2 * math.pi * i / n for i in range(n)]]


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


SP_NECK = (-NECK_W / 2, SP_C[1] + SP_R * 0.6, NECK_W / 2, BOX[1] - margin(SPAWN_DEG) + 6)
PO_NECK = (-NECK_W / 2, BOX[3] + margin(PORTAL_DEG) - 6, NECK_W / 2, PO_C[1] - PO_R * 0.6)


def in_rect(x, y, r, pad=0.0):
    return r[0] + pad <= x <= r[2] - pad and r[1] + pad <= y <= r[3] - pad


def in_lobes(x, y, pad=0.0):
    return (math.hypot(x - SP_C[0], y - SP_C[1]) < SP_R - pad or in_rect(x, y, SP_NECK, pad)
            or math.hypot(x - PO_C[0], y - PO_C[1]) < PO_R - pad or in_rect(x, y, PO_NECK, pad))


lm.slab(rect(*SP_NECK), SAND_Z - 0.6, SAND_Z + 0.04, "paving_dark", chamfer=0.1, top="paving")
lm.slab(circle(*SP_C, SP_R, 48), SAND_Z - 0.6, SAND_Z + 0.05, "paving_dark", chamfer=0.15, top="paving")
lm.ring(SP_R - 2.2, SP_R - 1.4, SAND_Z + 0.05, SAND_Z + 0.09, "gold", cx=SP_C[0], cy=SP_C[1], segs=48, a0=110, a1=430)
OP.spawn_pad(lm, *SPAWN, SAND_Z + 0.05)
for k in range(6):  # lamp posts + benches round the terrace (all far out of his reach)
    a = math.radians(200 + k * 28)
    if abs(math.degrees(a) - 270) < 12:
        continue
    lx, ly = SP_C[0] + math.cos(a) * (SP_R - 1.4), SP_C[1] + math.sin(a) * (SP_R - 1.4)
    P.lamp_post(lm, lx, ly, SAND_Z + 0.05)
for a in (155, 25):
    bx, by = SP_C[0] + math.cos(math.radians(a)) * (SP_R - 4), SP_C[1] + math.sin(math.radians(a)) * (SP_R - 4)
    P.bench(lm, bx, by, SAND_Z + 0.05, a + 90)
P.welcome_sign(lm, 0.0, SP_NECK[1] + 2.0, SAND_Z + 0.04, 0.0, C["BBV2_Landmarks"], span=NECK_W + 2.5)
note("SPAWN (arrival terrace, safe zone)", *SPAWN, "classic blue-and-white spawn pad on a round limestone terrace, lamp posts + benches; the BRIEFCASE BAY arch over the way in")
lm.slab(rect(*PO_NECK), SAND_Z - 0.6, SAND_Z + 0.04, "paving_dark", chamfer=0.1, top="paving")
lm.slab(circle(*PO_C, PO_R, 48), SAND_Z - 0.6, SAND_Z + 0.05, "paving_dark", chamfer=0.15, top="paving")
OP.escape_portal(lm, *PORTAL, SAND_Z + 0.05, rot=PORTAL_DEG - 90)
note("ESCAPE PORTAL (RETURN HOME)", *PORTAL, "the purple vortex in a limestone arch on a round plaza, flush with the lawn (a level walk-in)")
lm.done()
HI.boss(C["BBV2_Landmarks"], "SeniorPartner", 0.0, 0.0, z=SAND_Z + 0.1, scale=SENIOR["Scale"], facing=180)

# ------------------------------------------------------------------ the Green: the boss pad, the path, colour patches
dec = CL.ClassicMesh("Green_Decor", C["BBV2_Play_Decor"])
BOSS_PAD = (0.0, 0.0)
P.scales_pad(dec, *BOSS_PAD, SAND_Z)
note("The Senior Partner's start pad", *BOSS_PAD, "a round limestone patch with a gold scales-of-justice inlay, flush with the lawn (he leaves it to hunt)")
PATH = [(0, SP_NECK[3] - 1), (5, -104), (-5, -58), (0, -14), (0, 14), (6, 52), (-4, 96), (0, PO_NECK[1] + 1)]
P.path(dec, PATH, SAND_Z, width=7.0)


def path_dist(x, y):
    best = 1e9
    for (x0, y0), (x1, y1) in zip(PATH, PATH[1:]):
        L2 = (x1 - x0) ** 2 + (y1 - y0) ** 2
        t = max(0.0, min(1.0, ((x - x0) * (x1 - x0) + (y - y0) * (y1 - y0)) / L2))
        best = min(best, math.hypot(x - x0 - t * (x1 - x0), y - y0 - t * (y1 - y0)))
    return best


def blob(cx, cy, r, n=14):
    return [(cx + r * (1 + 0.25 * math.sin(3 * a + cx)) * math.cos(a), cy + r * 0.8 * (1 + 0.2 * math.cos(2 * a + cy)) * math.sin(a))
            for a in [2 * math.pi * i / n for i in range(n)]]


patches = tries = 0
while patches < 44 and tries < 4000:
    tries += 1
    x, y = rng.uniform(-HX, HX), rng.uniform(-HY, HY)
    r = rng.uniform(6, 18)
    if not in_green(x, y, r * 0.8 + 1) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < r + 15 or path_dist(x, y) < r + 4:
        continue
    look = ("lawn_light", "lawn_dark", "clover", "lawn_light", "worn_grass")[patches % 5]
    pts = blob(x, y, r)
    dec.slab(pts, SAND_Z - 0.05, SAND_Z + 0.05, look, chamfer=0.03)
    if look == "clover":  # a clover patch carries a meadow of low flowers
        for j in range(rng.randint(4, 9)):
            a, rr = rng.uniform(0, 2 * math.pi), rng.uniform(0, r * 0.7)
            P.flower_tuft(dec, x + math.cos(a) * rr, y + math.sin(a) * rr * 0.8, SAND_Z + 0.05)
    patches += 1

# ------------------------------------------------------------------ egg regions (candidate EggSpots: planned, not modelled eggs)
REGIONS = {"Welcome Lawn": ((-34, -54), 25, "south, nearest the spawn: the safer start"),
           "Harbour Green": ((66, -44), 23, "south-east, by the bay: mid risk"),
           "Cascade Lawn": ((-68, 32), 25, "west, under the cascade cliffs: mid risk"),
           "Ledger Row": ((58, 8), 21, "east, on his patrol line: high risk"),
           "Skyline Lawn": ((26, 60), 22, "north, on the way to the portal: high risk")}
mk = CL.ClassicMesh("Egg_Spot_Markers", C["BBV2_Gameplay_Markers"])
pe = CL.ClassicMesh("Preview_Eggs", C["BBV2_Preview_Eggs"])
spots = []
for name, ((cx, cy), R, why) in REGIONS.items():
    LAYOUT["egg_regions"].append({"name": name, "blender_xy": [cx, cy], "roblox_xz": [cx, -cy], "radius": R, "risk": why})
    want = 6 if R >= 24 else 5
    tries = got = 0
    while got < want and tries < 3000:
        tries += 1
        a, f = rng.uniform(0, 2 * math.pi), math.sqrt(rng.uniform(0.05, 1))
        x, y = cx + R * f * math.cos(a), cy + R * f * math.sin(a)
        if not in_green(x, y, DROP_MAX + 2) or not in_box(x, y, -4) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < 22 or path_dist(x, y) < 6:
            continue
        if any((x - qx) ** 2 + (y - qy) ** 2 < 81 for qx, qy, _ in spots):
            continue
        spots.append((x, y, name))
        got += 1
for i, (x, y, name) in enumerate(spots):
    OP.egg_marker(mk, x, y, SAND_Z + 0.06)
    if i % 2 == 0:
        P.egg_preview(pe, x, y, SAND_Z)
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "region": name})
mk.done()
pe.done()
EGG_KEEP = [(x, y) for x, y, _ in spots]

# small flat decor on the Green: walk-through, low, never on a spot or the path (collision off in Roblox)
for k in range(300):
    x, y = rng.uniform(-HX, HX), rng.uniform(-HY, HY)
    if not in_green(x, y, 3) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < 16 or path_dist(x, y) < 5.5:
        continue
    if any((x - a) ** 2 + (y - b) ** 2 < 25 for a, b in EGG_KEEP):
        continue
    edge = not in_green(x, y, 22)  # (richer toward the edges, sparser in the middle)
    roll = rng.random()
    if roll < 0.3:
        P.daisies(dec, x, y, SAND_Z)
    elif roll < 0.48 and (edge or rng.random() < 0.4):
        P.flower_tuft(dec, x, y, SAND_Z)
    elif roll < 0.68:
        P.paper(dec, x, y, SAND_Z)
    elif roll < 0.8:
        OP.pebbles(dec, x, y, SAND_Z, rng.randint(2, 4))
    elif roll < 0.9 and edge:
        a = rng.uniform(0, 2 * math.pi)
        P.stepping_stones(dec, x, y, x + math.cos(a) * 12, y + math.sin(a) * 12, SAND_Z)
dec.done()

# ------------------------------------------------------------------ the scenery ring. Everything tall keeps out of his reach
# (box + 45, clear_of_reach); only low dressing (hedges, flower beds) sits on the Green's rim inside it.
sc = CL.ClassicMesh("Scenery_Rocks", C["BBV2_Scenery"])
sky = CL.ClassicMesh("Skyline", C["BBV2_Skyline"])
wat = CL.ClassicMesh("Water", C["BBV2_Water"])
foam = CL.ClassicMesh("Foam_Mist", C["BBV2_Water"])
veg = CL.ClassicMesh("Vegetation", C["Vegetation"])
used = []
LAYOUT["fx"] = {"fall_landings": [], "edge_lips": [], "pools": [], "beacons": []}


def clear_of_reach(x, y, r=0.0):
    """Tall scenery keeps out of everything the Senior Partner can swing at: his box + REACH (45) + 1."""
    return box_dist(x, y) > REACH + 1 + r


def ring_pt(deg, f):
    """A point in the scenery ring at angle deg, f = 0 (the Green's edge) .. 1 (the island rim)."""
    return polar(rg(deg) + 4 + (ring_w(deg) - 8) * f, deg)


def push_out(deg, f, r):
    x, y = ring_pt(deg, f)
    while not clear_of_reach(x, y, r) and f < 1.3:
        f += 0.03
        x, y = ring_pt(deg, f)
    return x, y, f


def near_lobe(deg, w=11):
    return abs((deg - SPAWN_DEG + 180) % 360 - 180) < w or abs((deg - PORTAL_DEG + 180) % 360 - 180) < w


# the rim of the Green: low clipped hedges + flower beds (they mark where the playable lawn ends), gaps at the lobes + bay
deg = 0.0
while deg < 360:
    step = rng.uniform(3.0, 4.2)
    if not near_lobe(deg, 9):
        x0, y0 = polar(rg(deg) + 2.2, deg)
        x1, y1 = polar(rg(deg + step * 0.8) + 2.2, deg + step * 0.8)
        if rng.random() < 0.72:
            P.hedge_run(sc, x0, y0, x1, y1, 0.6, h=rng.uniform(2.0, 2.4))
        else:
            mx, my = (x0 + x1) / 2, (y0 + y1) / 2
            for j in range(3):
                P.flower_tuft(veg, mx + rng.uniform(-2, 2), my + rng.uniform(-1.2, 1.2), 0.6)
    deg += step

# the bay (SE): a sheltered harbour basin in the ring, a curved quay, a pier, the Bay Ferry, the lighthouse on its headland;
# it spills over the island edge in a waterfall
bx, by, bf = push_out(BAY_DEG, 0.42, 18)
BAY_C = (bx, by)
tx_, ty_ = -math.sin(math.radians(BAY_DEG)), math.cos(math.radians(BAY_DEG))
nx_, ny_ = math.cos(math.radians(BAY_DEG)), math.sin(math.radians(BAY_DEG))
bay_pts = [(bx + tx_ * 33 * math.cos(a) * (1 + 0.08 * math.sin(3 * a)) + nx_ * 19 * math.sin(a) * (1 + 0.1 * math.cos(2 * a)),
            by + ty_ * 33 * math.cos(a) * (1 + 0.08 * math.sin(3 * a)) + ny_ * 19 * math.sin(a) * (1 + 0.1 * math.cos(2 * a)))
           for a in [2 * math.pi * i / 36 for i in range(36)]]
quay = [(bx + (x - bx) * 1.17, by + (y - by) * 1.22) for x, y in bay_pts]
for i in range(len(bay_pts)):  # the quay: a limestone ring round the basin
    j = (i + 1) % len(bay_pts)
    sc.slab([bay_pts[i], bay_pts[j], quay[j], quay[i]], 0.0, 1.2, "rock_grey", chamfer=0.05, top="quay")
wat.slab(bay_pts, -0.6, 0.8, "bay_deep", chamfer=0.08, top="bay")
OD.foam_outline(foam, bay_pts, 0.8)
used.append((bx, by, 36))
for k in range(10):  # bollards + lamp posts on the quay (the inner side, facing the Green)
    a = math.pi * (0.15 + 0.7 * k / 9) + math.pi
    qx = bx + tx_ * 33 * math.cos(a) + nx_ * 20.4 * math.sin(a)
    qy = by + ty_ * 33 * math.cos(a) + ny_ * 20.4 * math.sin(a)
    if k % 3 == 0:
        P.lamp_post(sc, qx, qy, 1.2, 6.5)
    else:
        sc.cyl(qx, qy, 0.55, 1.2, 2.2, "lamp_post", segs=10)
        sc.cyl(qx, qy, 0.7, 2.0, 2.3, "lamp_post", segs=10)
pier0 = (bx - nx_ * 19.5 + tx_ * 6, by - ny_ * 19.5 + ty_ * 6)
pier1 = (bx + nx_ * 2 + tx_ * 6, by + ny_ * 2 + ty_ * 6)
OP.spawn_dock(sc, *pier0, *pier1, 1.6, width=5.0)
P.ferry(sc, bx + nx_ * -4 - tx_ * 8, by + ny_ * -4 - ty_ * 8, 0.8, rot=BAY_DEG + 90)
note("The Bay", bx, by, "a sheltered harbour basin: a limestone quay with bollards + lamps, a pier, the Bay Ferry; spills over the edge (scenery)")
ex, ey = polar(r_isl(BAY_DEG + 4) - 0.6, BAY_DEG + 4)
mx, my = bx + nx_ * 17, by + ny_ * 17
wat.beam((mx, my, 0.75), (ex, ey, 0.72), 9, 0.3, "bay")
OD.edge_fall(wat, foam, ex, ey, 0.7, -80, BAY_DEG + 4, width=10)
LAYOUT["fx"]["edge_lips"].append([round(ex, 1), round(ey, 1), 0.7, BAY_DEG + 4])
hx, hy = polar(r_isl(BAY_DEG - 22) - 10, BAY_DEG - 22)
OD.cliff_column(sc, veg, hx, hy, 0.4, 5, 15, 13, BAY_DEG, plants=False)
P.lighthouse(sc, hx, hy, 5.8, 28)
used.append((hx, hy, 12))
LAYOUT["fx"]["beacons"].append([round(hx, 1), round(hy, 1), 5.8 + 28 + 2])
note("Lighthouse", hx, hy, "a red-and-white lighthouse on the bay's headland (scenery)")

# pools in rock pockets (water, foam, lily pads), the falls they feed
POOLS = {140: (14, 0.3, None), 196: (13, 0.42, None), 14: (12, 0.42, 7), 236: (9, 0.36, None)}
for deg, (R, f, fall) in POOLS.items():
    px, py, f = push_out(deg, f, R + 4)
    pts = [(px + R * (1 + 0.18 * math.sin(3 * a + deg)) * math.cos(a), py + R * 0.8 * (1 + 0.15 * math.cos(2 * a + deg)) * math.sin(a))
           for a in [2 * math.pi * i / 22 for i in range(22)]]
    bank = [(px + (x - px) * 1.18, py + (y - py) * 1.18) for x, y in pts]
    sc.slab(bank, 0.3, 0.68, "rock_grey_light", chamfer=0.1, top="paving")
    wat.slab(pts, 0.0, 0.8, "bay_deep", chamfer=0.08, top="bay")
    OD.foam_outline(foam, pts, 0.8)
    used.append((px, py, R + 4))
    LAYOUT["fx"]["pools"].append([round(px, 1), round(py, 1), R])
    for k in range(12):  # the rock rim, open toward the Green
        a = math.radians(k * 30 + rng.uniform(-8, 8))
        rx_, ry_ = px + math.cos(a) * (R + 3.5), py + math.sin(a) * (R * 0.8 + 3.5)
        if clear_of_reach(rx_, ry_, 4) and math.hypot(rx_ - CENTER[0], ry_ - CENTER[1]) > math.hypot(px - CENTER[0], py - CENTER[1]) - R * 0.3:
            OD.cliff_column(sc, veg, rx_, ry_, 0.4, rng.uniform(2, 6), rng.uniform(4, 7), rng.uniform(3.5, 6), math.degrees(a), plants=rng.random() < 0.5)
    for k in range(rng.randint(4, 7)):  # lily pads
        a, rr = math.radians(rng.uniform(0, 360)), rng.uniform(0.2, 0.75) * R
        lx_, ly_ = px + math.cos(a) * rr, py + math.sin(a) * rr * 0.8
        sc.cyl(lx_, ly_, rng.uniform(0.9, 1.5), 0.8, 0.88, "canopy_light", segs=12)
        if rng.random() < 0.4:
            sc.sphere(lx_ + 0.3, ly_, 1.05, 0.35, 0.35, 0.25, "flower_pink", seg=8, rings=5)
    if fall:
        ex, ey = polar(r_isl(deg) - 0.5, deg)
        wat.beam((px, py, 0.75), (ex, ey, 0.7), fall * 0.85, 0.3, "bay")
        OD.foam_outline(foam, [(px, py), (ex, ey)], 0.85, step=2.2)
        OD.edge_fall(wat, foam, ex, ey, 0.6, -80, deg, width=fall)
        LAYOUT["fx"]["edge_lips"].append([round(ex, 1), round(ey, 1), 0.6, deg])
        note(f"Waterfall off the edge ({deg} deg)", ex, ey, "a pool spilling over the island edge")
note("Pools", 0, 0, "four pools in limestone pockets round the ring (the cascade pool, the grotto pool, an edge-fall pool, a lily pond)")

# the cascade (NW): from the high cliffs beside the skyline into its pool
hp = POOLS[140]
hx, hy, hf = push_out(140, hp[1], hp[0] + 4)
cdx, cdy = math.cos(math.radians(140)), math.sin(math.radians(140))
cx_, cy_ = hx + cdx * (hp[0] + 10), hy + cdy * (hp[0] + 10)
ctop = OD.cliff_column(sc, veg, cx_, cy_, 0.4, 38, 16, 13, 140, plants=False)
for sgn in (-1, 1):
    OD.cliff_column(sc, veg, cx_ - cdy * sgn * 12, cy_ + cdx * sgn * 12, 0.4, rng.uniform(34, 42), 12, 11, 140)
land = OD.waterfall_tall(wat, foam, (cx_ - cdx * 6.5, cy_ - cdy * 6.5, ctop - 0.9), 0.8, 140 + 180, width=6.5, ledges=2)
LAYOUT["fx"]["fall_landings"].append([round(land[0], 1), round(land[1], 1), 0.8])
used.append((cx_, cy_, 22))
note("The cascade", cx_, cy_, "a waterfall dropping ~38 studs in three steps from the NW cliffs into a pool")

# the grotto (W) and a natural arch on the SW rim
GROTTO, ARCH = 200, 222
cvx, cvy, _ = push_out(GROTTO, 0.66, 16)
for k in range(5):
    a = math.radians(GROTTO + (k - 2) * 7)
    OD.cliff_column(sc, veg, cvx + math.cos(a) * 6 * (k - 2) * 0.4, cvy + math.sin(a) * 6 * (k - 2) * 0.4, 0.4, rng.uniform(22, 28), 12, 11, GROTTO)
mouth = polar(math.hypot(cvx - CENTER[0], cvy - CENTER[1]) - 6.2, GROTTO)
sc.ring_v(*mouth, 5.4, 4.8, 7.6, 3.0, ["rock_grey_dark", "rock_grey"], rot=GROTTO + 90, segs=9, gap=0.2, a0=0, a1=180)
sc.disc_v(*mouth, 4.6, 5.0, 0.4, "black", rot=GROTTO + 90, segs=20)
sc.brick(*mouth, 0.4, 9.6, 1.2, 4.6, "black", rot=GROTTO + 90, bevel=0.0)
used.append((cvx, cvy, 20))
note("Grotto", cvx, cvy, "a dark cave mouth in the west cliffs (scenery: not enterable)")
ax, ay, _ = push_out(ARCH, 0.8, 14)
OP.rock_arch(sc, ax, ay, 0.4, span=18, h=18, rot=ARCH - 90)
used.append((ax, ay, 16))
note("Rock arch", ax, ay, "a natural limestone arch on the south-west rim")

# the monuments: the giant briefcase greets arrivals (SW of the spawn), the giant gavel by the portal (NE)
gx, gy, _ = push_out(250, 0.3, 14)
P.giant_briefcase(sc, gx, gy, 0.6, rot=250 - 90 + 20)
used.append((gx, gy, 16))
note("Giant briefcase", gx, gy, "the zone's emblem on a limestone plinth, beside the arrival terrace (scenery)")
gx, gy, _ = push_out(64, 0.3, 14)
P.giant_gavel(sc, gx, gy, 0.6, rot=64 - 90 - 15)
used.append((gx, gy, 16))
note("Giant gavel", gx, gy, "a giant gavel on its sound block, beside the portal (scenery)")

# the skyline: classic glass towers on the back ring (N), behind the front cliffs, tallest behind the portal's shoulders
TOWERS = [(58, 0.9, 16, 14, 52, "tower_glass"), (72, 0.78, 18, 16, 74, "tower_glass_teal"), (106, 0.74, 20, 18, 92, "tower_glass"),
          (120, 0.86, 16, 16, 66, "tower_glass_dark"), (40, 0.95, 14, 13, 40, "tower_glass_teal"), (132, 0.98, 14, 14, 50, "tower_glass")]
for deg, f, w, d, h, glass in TOWERS:
    tx, ty, _ = push_out(deg, f, max(w, d) * 0.75)
    P.tower(sky, tx, ty, 0.6, w, d, h, rot=deg - 90, glass=glass)
    used.append((tx, ty, max(w, d) * 0.8))
    LAYOUT["fx"]["beacons"].append([round(tx, 1), round(ty, 1), round(0.6 + h + 0.5 + h * 0.12 + 0.4, 1)])
note("The skyline", 0, 200, "six classic glass towers on the back ring behind the cliffs (scenery: the firms the bay is named for)")

# the cliff massifs: a continuous wall of limestone round the outer ring (low S so the aerial sees in, tall behind the
# skyline's feet + the cascade), columns joined by connector blocks; a front row of grass-topped terraces; boulders
ANCH = [(0, 14), (24, 16), (44, 18), (66, 16), (80, 8), (84, 0), (96, 0), (100, 10), (116, 22), (140, 36), (160, 30), (186, 24),
        (212, 16), (236, 10), (254, 7), (260, 0), (280, 0), (288, 6), (300, 0), (352, 0), (356, 10), (360, 14)]


def massif_h(deg):
    d = deg % 360
    for (a0, h0), (a1, h1) in zip(ANCH, ANCH[1:]):
        if a0 <= d <= a1:
            t = (d - a0) / max(1e-6, a1 - a0)
            t = t * t * (3 - 2 * t)
            h = h0 + (h1 - h0) * t
            return max(0.0, h + 2.0 * math.sin(math.radians(7 * d)) + 1.4 * math.sin(math.radians(13 * d) + 1)) if h > 0.5 else 0.0
    return 0.0


back = []
deg = 0.0
while deg < 360:
    H = massif_h(deg)
    if H > 0.5:
        f = 0.8 + 0.07 * math.sin(math.radians(5 * deg))
        x, y = ring_pt(deg, f)
        w = rng.uniform(14, 19)
        if clear_of_reach(x, y, w / 2 + 2) and not any(math.hypot(x - ux, y - uy) < ur + w * 0.3 for ux, uy, ur in used):
            h = H * rng.uniform(0.92, 1.08)
            OD.cliff_column(sc, veg, x, y, 0.4, h, w, w * rng.uniform(0.75, 0.9), deg + 90 + rng.uniform(-6, 6))
            if back and math.hypot(x - back[-1][0], y - back[-1][1]) < 26:
                bx_, by_, bh = back[-1]
                OD.cliff_column(sc, veg, (x + bx_) / 2, (y + by_) / 2, 0.4, min(h, bh) * rng.uniform(0.55, 0.72),
                                math.hypot(x - bx_, y - by_) + 5, w * 0.7, math.degrees(math.atan2(y - by_, x - bx_)), plants=rng.random() < 0.4)
            back.append((x, y, h))
    deg += 3.6
for k in range(0, 360, 8):  # the front terraces (lower, grass-topped)
    deg = k + rng.uniform(-2, 2)
    H = massif_h(deg)
    if H <= 0.5:
        continue
    x, y = ring_pt(deg, rng.uniform(0.38, 0.52))
    w = rng.uniform(10, 15)
    if not clear_of_reach(x, y, w / 2 + 2) or any(math.hypot(x - ux, y - uy) < ur + w * 0.3 for ux, uy, ur in used):
        continue
    OD.cliff_column(sc, veg, x, y, 0.4, H * rng.uniform(0.35, 0.5), w, w * rng.uniform(0.75, 0.95), deg + 90 + rng.uniform(-10, 10))
    used.append((x, y, w * 0.5))
for k in range(60):  # boulders at the cliffs' feet (still clear of his reach)
    deg = rng.uniform(0, 360)
    if massif_h(deg) <= 0.5:
        continue
    x, y = ring_pt(deg, rng.uniform(0.15, 0.3))
    if not clear_of_reach(x, y, 3) or any(math.hypot(x - ux, y - uy) < ur * 0.8 for ux, uy, ur in used):
        continue
    OD.cliff_column(sc, veg, x, y, 0.4, rng.uniform(2, 4.5), rng.uniform(3, 5.5), rng.uniform(2.5, 4.5), rng.uniform(0, 90), plants=False)

# vegetation on the ring: round trees, blossom trees, palms by the water, bushes, hibiscus, ferns, grass
placed = tries = 0
while placed < 230 and tries < 9000:
    tries += 1
    deg = rng.uniform(0, 360)
    x, y = ring_pt(deg, rng.uniform(0.05, 0.95))
    if in_lobes(x, y, -7) or not clear_of_reach(x, y, 6) or green_sd(x, y) < 10:  # (no canopy over the lawn or a lobe)
        continue
    if any(math.hypot(x - ux, y - uy) < ur * 0.75 for ux, uy, ur in used):
        continue
    roll = rng.random()
    by_water = any(math.hypot(x - px_, y - py_) < r_ + 14 for px_, py_, r_ in LAYOUT["fx"]["pools"]) or math.hypot(x - BAY_C[0], y - BAY_C[1]) < 48
    if roll < 0.28:
        if by_water or rng.random() < 0.3:
            OD.palm2(veg, x, y, 0.6, lean=math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-50, 50))
        else:
            P.round_tree(veg, x, y, 0.6, rng.uniform(0.9, 1.25), blossom=rng.random() < 0.3)
        used.append((x, y, 4.5))
    elif roll < 0.5:
        OD.bush(veg, x, y, 0.6, rng.uniform(0.8, 1.3))
    elif roll < 0.62:
        OD.hibiscus(veg, x, y, 0.6, rng.uniform(0.8, 1.1))
    elif roll < 0.76:
        OP.fern_bush(veg, x, y, 0.6, rng.uniform(0.8, 1.3))
    else:
        OD.grass_clump(veg, x, y, 0.6, rng.uniform(0.9, 1.3))
    placed += 1
for deg in (SPAWN_DEG, PORTAL_DEG):  # trees flanking the two lobes
    for sgn in (-1, 1):
        for k in range(2):
            x, y = ring_pt(deg + sgn * rng.uniform(10, 16), rng.uniform(0.25, 0.6))
            if clear_of_reach(x, y, 5) and green_sd(x, y) > 10 and not any(math.hypot(x - ux, y - uy) < ur * 0.7 for ux, uy, ur in used):
                P.round_tree(veg, x, y, 0.6, rng.uniform(1.0, 1.3), blossom=(k == 1))
                used.append((x, y, 5))
sc.done()
sky.done()
wat.done()
foam.done()
veg.done()

# ------------------------------------------------------------------ the sky: the sea far below, clouds, floating islets
sea = CL.ClassicMesh("Sky_Sea", C["BBV2_Sky"])
sea.cyl(0, 0, 4000, -330, -320, "sea", segs=64)
sea.done()
cl = CL.ClassicMesh("Sky_Clouds", C["BBV2_Sky"])
for k in range(18):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(340, 720), d, (0, 0))
    z = rng.uniform(-140, 70)
    for j in range(rng.randint(6, 10)):
        r = rng.uniform(9, 22)
        cl.sphere(x + rng.uniform(-28, 28), y + rng.uniform(-16, 16), z + rng.uniform(-3, 9), r, r * 0.8, r * 0.55, "white", seg=14, rings=8)
cl.done()
isl = CL.ClassicMesh("Sky_Islets", C["BBV2_Sky"])
for k in range(8):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(400, 620), d, (0, 0))
    z = rng.uniform(-60, 40)
    s_ = rng.uniform(12, 24)
    isl.slab(blob(x, y, s_, 12), z - 3, z, "dirt_rim", chamfer=0.4, top="moss")
    for j in range(3):
        isl.rock(x, y, z - 3 - (j + 1) * s_ * 0.4, s_ * (1.2 - j * 0.3), s_ * (1.0 - j * 0.25), s_ * 0.42, rng.choice(("rock_grey", "rock_grey_dark")), rot=d + j * 20, taper=-0.3)
    P.round_tree(isl, x + rng.uniform(-3, 3), y + rng.uniform(-3, 3), z, rng.uniform(0.8, 1.1), blossom=rng.random() < 0.4)
    OD.bush(isl, x + rng.uniform(-5, 5), y + rng.uniform(-5, 5), z, 1.0)
isl.done()

# ------------------------------------------------------------------ studs: broad terrain + structural tops only (classic Roblox)
K.studs_done(C["Briefcase_Bay_V2"], only=lambda o, look: look in P.STUD_LOOKS and not o.name.startswith(("Sky_", "Preview", "Egg_Spot", "Label", "Diagram")))

# ------------------------------------------------------------------ gameplay checks (measured on the built geometry)
objs = [o for o in scene.objects if o.type == "MESH" and not o.name.startswith(("Studs_", "StudSource_", "Sky_", "Preview", "Egg_Spot", "Boss_", "Green_Decor"))]
_dec = bpy.data.objects["Green_Decor"]
DECOR_H = max(v.co.z for v in _dec.data.vertices) - SAND_Z
LAYOUT["checks"]["green_decor"] = (f"small walk-through decor on the Green (daisies, flower tufts, papers, pebbles, flat stones, colour patches, the path): "
                                   f"at most {DECOR_H:.1f} studs tall, collision off in Roblox")
verts, polys, owner = [], [], []
for o in objs:
    mw = o.matrix_world
    base = len(verts)
    verts.extend(mw @ v.co for v in o.data.vertices)
    polys.extend([[base + i for i in p.vertices] for p in o.data.polygons])
    owner.extend([o.name] * len(o.data.polygons))
bvh = BVHTree.FromPolygons(verts, polys)
WHY = {}
DOWN = Vector((0, 0, -1))
OBST = 2.5  # anything taller than this above the lawn would be in his way / hide his warning


def ground(x, y):
    hit = bvh.ray_cast(Vector((x, y, 300)), DOWN, 600)
    return hit[0].z if hit[0] is not None else None


def blocked(x, y):
    hit = bvh.ray_cast(Vector((x, y, 300)), DOWN, 600)
    z = hit[0].z if hit[0] is not None else None
    bad = z is None or z > SAND_Z + OBST or z < SAND_Z - 0.6
    if bad:
        k = "off the island" if z is None else (owner[hit[2]] + (" (above)" if z > SAND_Z else " (below the lawn)"))
        WHY[k] = WHY.get(k, 0) + 1
        if len(WHY.setdefault("_pts", [])) < 12 and z is not None:
            WHY["_pts"].append((round(x), round(y), round(z, 1), owner[hit[2]], round(box_dist(x, y), 1)))
    return bad


def walkable(x, y):
    return in_green(x, y, 1) or in_lobes(x, y, 1)


# 1. his box: every point open lawn?
cells = bad = 0
y = BOX[1]
while y <= BOX[3]:
    x = BOX[0]
    while x <= BOX[2]:
        cells += 1
        bad += blocked(x, y) or not in_green(x, y)
        x += 4
    y += 4
LAYOUT["checks"]["box_open_lawn"] = f"{cells - bad}/{cells} sample points (4-stud grid) are open lawn"
# 2. his swing: from a grid of places in the box, 16 facings, the 45 x 110 deg fan - where a player could stand, is the
#    floor open (the warning visible)? how much of the fan lies over the playable Green?
fans = hidden = on_green = pts_all = 0
for sx in range(int(BOX[0]), int(BOX[2]) + 1, 25):
    for sy in range(int(BOX[1]), int(BOX[3]) + 1, 25):
        for k in range(16):
            fans += 1
            face = k * 22.5
            for rr in range(5, 46, 5):
                for j in range(-5, 6):
                    a = math.radians(face + j * SENIOR["Angle"] / 10)
                    px, py = sx + math.cos(a) * rr, sy + math.sin(a) * rr
                    pts_all += 1
                    if walkable(px, py):
                        on_green += 1
                        hidden += blocked(px, py)
print("[bbv2] fan blockers:", sorted(((k, v) for k, v in WHY.items() if k != "_pts"), key=lambda kv: -kv[1])[:8], WHY.get("_pts"))
WHY.clear()
LAYOUT["checks"]["swing_room"] = (f"{fans} sampled swings (45-stud x 110 deg fans from a 25-stud grid, 16 facings): {100 * on_green / pts_all:.0f}% of "
                                  f"their area lies on the playable Green; {hidden} of {on_green} fan points where a player can stand are covered "
                                  f"(warning hidden) - the rest of each fan reaches over the hedges into the scenery ring, where no one can stand")
# 3. dodge room (Config): from the windup start a player at 32 studs/s runs 38.4 studs; the most anyone needs is
#    max over d of min(45 - d, d * sin 55) (straight out of the radius, or sideways out of the angle)
need = max(min(REACH - d / 10, d / 10 * math.sin(math.radians(SENIOR["Angle"] / 2))) for d in range(0, 451))
LAYOUT["checks"]["dodge"] = f"windup 1.2 s = 38.4 studs at the base speed 32; the worst place in the fan needs {need:.1f} (out of the radius or the angle)"
# 4. eggs: drop scatter room
mins = {}
for x, y, name in spots:
    mins[name] = round(min(mins.get(name, 1e9), -green_sd(x, y)), 1)
LAYOUT["checks"]["egg_edge_clearance"] = {k: f"{v} studs to the Green's edge (drops scatter at most {DROP_MAX:.1f})" for k, v in mins.items()}
# drops with TODAY's code: each egg flies 6-14 x (1 + 0.04 x eggs) studs from the hit player, clamped 4 inside Bounds; with
# no Floor under it, it lands at y 0 (lost in the scenery). Sampled over every place on the Green a player can be hit.
import random as _r
_g = _r.Random(5)
for n in (3, 12):
    tot = off = 0
    hits = 0
    while hits < 4000:
        hx_, hy_ = _g.uniform(BOUNDS[0], BOUNDS[2]), _g.uniform(BOUNDS[1], BOUNDS[3])
        if not in_green(hx_, hy_):
            continue
        hits += 1
        for e in range(n):
            a_, r_ = _g.uniform(0, 2 * math.pi), _g.uniform(6, 14) * (1 + 0.04 * n)
            ex_ = min(max(hx_ + math.cos(a_) * r_, BOUNDS[0] + 4), BOUNDS[2] - 4)
            ey_ = min(max(hy_ + math.sin(a_) * r_, BOUNDS[1] + 4), BOUNDS[3] - 4)
            tot += 1
            off += not in_green(ex_, ey_)
    LAYOUT["checks"][f"drops_today_{n}_eggs"] = (f"hit anywhere on the Green carrying {n}: {100 * (tot - off) / tot:.1f}% of eggs land on the lawn "
                                                 f"(the rest only from hits within ~{14 * (1 + 0.04 * n):.0f} studs of its edge)")
# 5. spawn + portal vs his reach
LAYOUT["checks"]["spawn_safe"] = f"spawn pad {box_dist(*SPAWN):.0f} studs outside his box (his swing reaches {REACH}); the arrival terrace's nearest edge {box_dist(SP_C[0], SP_C[1] + SP_R):.0f}"
LAYOUT["checks"]["portal_threat"] = (f"portal {box_dist(*PORTAL):.0f} studs outside his box; the plaza's nearest edge {box_dist(PO_C[0], PO_C[1] - PO_R):.0f} "
                                     f"(out of his swing); with him at the box edge, a player stays inside his 60-stud trigger until "
                                     f"{box_dist(*PORTAL) - SENIOR['TriggerRange']:.0f} studs from the portal (he swings at the air: the swing reaches 45)")
# 6. connectivity: spawn -> portal on walkable ground, and NO route that stays out of his reach


def walk_ok(x, y, avoid_reach=False):
    if not walkable(x, y):
        return False
    if avoid_reach and box_dist(x, y) < REACH:
        return False
    hit = bvh.ray_cast(Vector((x, y, SAND_Z + 7.5)), DOWN, 20)  # (head height: a player walks under the welcome sign)
    return hit[0] is not None and hit[0].z < SAND_Z + OBST and hit[1].z > 0


def bfs(avoid_reach):
    step = 3.0
    start = (round(SPAWN[0] / step), round(SPAWN[1] / step))
    goal = (round(PORTAL[0] / step), round((PORTAL[1] - 10) / step))
    seen, todo = {start}, [start]
    while todo:
        cx, cy = todo.pop()
        if abs(cx - goal[0]) <= 2 and abs(cy - goal[1]) <= 2:
            return True
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if (nx, ny) not in seen and walk_ok(nx * step, ny * step, avoid_reach):
                seen.add((nx, ny))
                todo.append((nx, ny))
    return False


LAYOUT["checks"]["spawn_to_portal"] = "reachable on level ground" if bfs(False) else "NOT reachable - fix"
LAYOUT["checks"]["no_safe_bypass"] = "no walkable route avoids his reach (every route crosses his swing)" if not bfs(True) else "a route AVOIDS him - fix"
corners = all(in_green(x, y, 2) for x in (BOX[0], BOX[2]) for y in (BOX[1], BOX[3]))
LAYOUT["checks"]["box_on_lawn"] = "all four box corners are on the lawn" if corners else "a box corner is off the lawn - fix"
pocket = max(box_dist(*polar(rg(d), d)) for d in range(360))
LAYOUT["checks"]["edge_in_reach"] = (f"the Green's edge is {min(box_dist(*polar(rg(d), d)) for d in range(360)):.0f}-{pocket:.0f} studs from his box, all round: "
                                     f"every place on the lawn is inside his 45-stud swing (no safe strip, no safe corner)")
LAYOUT["checks"]["egg_spots"] = f"{len(spots)} candidate spots in {len(REGIONS)} regions (the zone shows at most 14 eggs at once)"
print("[bbv2] checks:", json.dumps(LAYOUT["checks"], indent=1))

# ------------------------------------------------------------------ the gameplay diagram overlays (diagram render only)
dg = CL.ClassicMesh("Diagram_Overlays", C["BBV2_Diagram"])
ZD = 80.0


def dash_line(x0, y0, x1, y1, look, w=1.4, dash=6.0, gap=3.0):
    L = math.hypot(x1 - x0, y1 - y0)
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    t = 0.0
    while t < L:
        t1 = min(L, t + dash)
        m = (t + t1) / 2 / L
        dg.brick(x0 + (x1 - x0) * m, y0 + (y1 - y0) * m, ZD, t1 - t, w, 0.3, look, rot=a, bevel=0.0)
        t += dash + gap


def dash_rect(r, look, w=2.0):
    for (x0, y0, x1, y1) in ((r[0], r[1], r[2], r[1]), (r[2], r[1], r[2], r[3]), (r[2], r[3], r[0], r[3]), (r[0], r[3], r[0], r[1])):
        dash_line(x0, y0, x1, y1, look, w=w)


K.PAL.update({"diag_red": (235, 50, 60), "diag_blue": (40, 110, 240), "diag_yellow": (250, 190, 30), "diag_purple": (150, 70, 230),
              "diag_charge": (255, 120, 120), "diag_orange": (255, 140, 30), "diag_white": (255, 255, 255)})
dash_rect(BOX, "diag_red", 2.0)
dash_rect((BOX[0], -PATROL, BOX[2], PATROL), "diag_white", 1.0)  # today's idle patrol band
for (x0, y0, x1, y1) in ((BOX[0], BOX[1] - REACH, BOX[2], BOX[1] - REACH), (BOX[2] + REACH, BOX[1], BOX[2] + REACH, BOX[3]),
                         (BOX[2], BOX[3] + REACH, BOX[0], BOX[3] + REACH), (BOX[0] - REACH, BOX[3], BOX[0] - REACH, BOX[1])):
    dash_line(x0, y0, x1, y1, "diag_orange", w=1.2, dash=3.0, gap=3.0)
for (cx, cy, a0) in ((BOX[2], BOX[3], 0), (BOX[0], BOX[3], 90), (BOX[0], BOX[1], 180), (BOX[2], BOX[1], 270)):
    dg.ring(REACH - 0.6, REACH + 0.6, ZD, ZD + 0.3, "diag_orange", cx=cx, cy=cy, segs=24, a0=a0, a1=a0 + 90)
for name, ((cx, cy), R, why) in REGIONS.items():
    dg.ring(R - 1.0, R + 0.6, ZD, ZD + 0.3, "diag_yellow", cx=cx, cy=cy, segs=48)
dg.ring(SP_R + 1, SP_R + 3, ZD, ZD + 0.3, "diag_blue", cx=SP_C[0], cy=SP_C[1], segs=40)
dg.ring(PO_R + 1, PO_R + 3, ZD, ZD + 0.3, "diag_purple", cx=PO_C[0], cy=PO_C[1], segs=40)
SWINGS = [((0, 0), (-34, -54)), ((70, -60), (66, -44)), ((-100, 40), (-68, 32)), ((40, 85), (26, 60)), ((-30, -85), (0, -126)),
          ((100, 10), (140, 30))]
for (sx, sy), (tx, ty) in SWINGS:  # example swings: the fan he aims at a target (45 x 110 deg)
    face = math.degrees(math.atan2(ty - sy, tx - sx))
    dg.ring(REACH - 1.0, REACH + 0.6, ZD + 0.5, ZD + 0.8, "diag_red", cx=sx, cy=sy, segs=24, a0=face - 55, a1=face + 55)
    dg.ring(0.01, REACH, ZD + 0.2, ZD + 0.4, "diag_charge", cx=sx, cy=sy, segs=24, a0=face - 55, a1=face + 55)
    for s_ in (-1, 1):
        a = math.radians(face + s_ * 55)
        dg.brick(sx + math.cos(a) * REACH / 2, sy + math.sin(a) * REACH / 2, ZD + 0.5, REACH, 1.4, 0.3, "diag_red", rot=math.degrees(a), bevel=0.0)
    dg.cyl(sx, sy, 3.2, ZD + 0.5, ZD + 0.9, "diag_red", segs=16)
dg.done()
lab = K.Mesh("Label_Plates", C["BBV2_Labels"])
for text, x, y in (("SPAWN\nsafe zone", 40, SP_C[1] - 4), ("ESCAPE PORTAL", 40, PO_C[1] + 6), ("SENIOR PARTNER\nSTART", 0, -22),
                   ("BOSS ROAMS THE WHOLE\nRED BOX (200 x 170)", -64, -104), ("HIS SWING REACHES\n45 PAST THE BOX (orange)", 140, -150),
                   ("EGGS: Welcome Lawn", -34, -84), ("EGGS: Harbour Green", 66, -72), ("EGGS: Cascade Lawn", -68, 62),
                   ("EGGS: Ledger Row", 58, 34), ("EGGS: Skyline Lawn", 30, 88), ("SWING = 45 x 110 deg\n(1.2 s warning)", -60, 100),
                   ("today's idle band (+-14)", -40, 22), ("THE BAY (scenery)", 150, -125), ("SKYLINE + CLIFFS\n(scenery, not playable)", -110, 175),
                   ("SCENERY", -190, -20), ("THE GREEN: playable lawn,\nhedges mark its edge", 112, 150), ("N", 0, 262)):
    HI.label(C["BBV2_Labels"], lab, text, x, y, 6.5, z=ZD + 30)
lab.done()

# ------------------------------------------------------------------ light, save
world, sun = K.sky_and_sun(scene, sun_energy=4.0, sun_rot=(48, 8, -28), sky=(0.2, 0.5, 0.98), horizon=(0.66, 0.85, 1.0))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=24)
C["BBV2_Diagram"].hide_render = True
C["BBV2_Labels"].hide_render = True
C["BBV2_Gameplay_Markers"].hide_render = True
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "briefcase_bay_v2.blend"), compress=True)
with open(os.path.join(HERE, "bbv2_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
tris = sum(sum(len(p_.vertices) - 2 for p_ in o.data.polygons) for o in scene.objects if o.type == "MESH" and not o.name.startswith(("Studs_", "StudSource_", "Diagram", "Label")))
print(f"[bbv2] saved; {len(spots)} egg spots; {tris / 1000:.0f}k tris")

CAMS = {
    "aerial": (("Cam_Aerial", (90, -540, 370), (0, 30, -10), 34), 2400, 1350),
    "ground_spawn": (("Cam_Ground_Spawn", (7, SPAWN[1] - 12, SAND_Z + 9), (0, -40, SAND_Z + 7), 24), 1920, 1080),
    "ground_eggs": (("Cam_Ground_Eggs", (-128, -70, SAND_Z + 8), (-40, 10, SAND_Z + 3), 24), 1920, 1080),
    "boss_view": (("Cam_Boss_View", (10, 30, SAND_Z + 50), (-8, -96, SAND_Z), 22), 1920, 1080),  # (over his shoulder)
    "ground_portal": (("Cam_Ground_Portal", (-34, PO_C[1] - 58, SAND_Z + 9), (0, PORTAL[1], SAND_Z + 12), 26), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        scene.eevee.taa_render_samples = 32 if key == "aerial" else 24
        K.render(scene, cam, os.path.join(RENDERS, f"bbv2_{key}.jpg"), w, h)
    if not only or "topdown" in only:
        cam = K.camera("Cam_TopDown", (0, 15, 1500), (0, 15, 0), ortho=560, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.eevee.taa_render_samples = 16
        K.render(scene, cam, os.path.join(RENDERS, "bbv2_topdown.jpg"), 2000, 2000)
    if not only or "diagram" in only:
        cam = bpy.data.objects.get("Cam_TopDown") or K.camera("Cam_TopDown", (0, 15, 1500), (0, 15, 0), ortho=560, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        C["BBV2_Diagram"].hide_render = False
        C["BBV2_Labels"].hide_render = False
        C["BBV2_Gameplay_Markers"].hide_render = False
        C["BBV2_Preview_Eggs"].hide_render = True
        C["BBV2_Sky"].hide_render = True
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        K.render(scene, cam, os.path.join(RENDERS, "bbv2_gameplay_diagram.jpg"), 2000, 2000)
