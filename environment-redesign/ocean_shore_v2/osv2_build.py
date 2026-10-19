# environment-redesign/ocean_shore_v2/osv2_build.py - OCEAN SHORE v2, the LAYOUT for crnuch's approval (2026-10-19).
# crnuch's brief + concept image (../references/ocean_shore_concept.webp): a natural tropical wilderness, classic Roblox
# studs (not LEGO), ONE continuous flat sand surface where Magistrate Megalodon roams and charges (Config.Bosses: Line
# 130 x 20 at 150 studs/s, Windup 1.0, Dizzy 2, Hitbox 14 wide, 25.6 tall), egg regions across it, the spawn dock SW,
# the purple escape portal NE, all scenery (cliffs, pools, waterfalls, palms, arch, cave, shipwreck) OUTSIDE the
# boss's box. v1 (../ocean_shore/) is untouched.
#   Blender -b --python environment-redesign/ocean_shore_v2/osv2_build.py [-- norender | -- only=aerial,diagram]
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
import osv2_parts as P
import osv2_detail as D

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(1907)
rng = P.rng

scene = K.reset(["Ocean_Shore_V2", "Vegetation", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("OSV2_Terrain", "OSV2_Underside", "OSV2_Scenery", "OSV2_Water", "OSV2_Play_Decor", "OSV2_Landmarks", "OSV2_Sky",
          "OSV2_Labels", "OSV2_Diagram", "OSV2_Gameplay_Markers", "OSV2_Preview_Eggs"):
    K.col(n, "Ocean_Shore_V2")

# ------------------------------------------------------------------ the measured gameplay frame (Config.Bosses / Zones)
MEGALODON = {"Scale": 3.2, "WalkSpeed": 42, "Chase": 0.95, "AttackEvery": 2.8, "Windup": 1.0, "Length": 130, "Width": 20,
             "LineSpeed": 150, "Dizzy": 2, "HitboxWidth": 2 * 2.2 * 3.2, "Height": 25.6, "TriggerRange": 60}
DROP_MAX = 14 * (1 + 0.04 * 12)  # DropScatter max x the 12-egg Diamond Briefcase spread = 20.7 studs
REACH = MEGALODON["Width"] / 2 + MEGALODON["HitboxWidth"] / 2  # how far past his box edge a charge / his body can hit
CENTER = (0.0, 5.0)
BOX = (-120.0, -100.0, 120.0, 110.0)  # Megalodon's roaming box (x0, y0, x1, y1): the whole dangerous sand
SAND_Z = 1.0
A_, B_, NEXP = 138.0, 123.0, 8.0
NE, SW = 44.0, 224.0  # the portal lobe + the spawn lobe (degrees from CENTER)


def squircle(deg):
    a = math.radians(deg)
    return (abs(math.cos(a) / A_) ** NEXP + abs(math.sin(a) / B_) ** NEXP) ** (-1 / NEXP)


def lobe(deg, at, amp, sig):
    d = (deg - at + 180) % 360 - 180
    return amp * math.exp(-0.5 * (d / sig) ** 2)


def r_sand(deg):
    a = math.radians(deg)
    return squircle(deg) * (1 + 0.018 * math.sin(5 * a) + 0.01 * math.sin(11 * a + 1)) + lobe(deg, NE, 54, 8) + lobe(deg, SW, 20, 9)


def ring_w(deg):
    a = math.radians(deg)
    w = 50 + 14 * math.sin(3 * a + 0.7) + 7 * math.sin(7 * a)
    w -= lobe(deg, SW, 44, 9)  # the spawn lobe meets the edge (the dock juts out over the drop)
    w -= lobe(deg, NE, 18, 10)
    return max(6.0, w)


def r_isl(deg):
    return r_sand(deg) + ring_w(deg)


def polar(r, deg, c=CENTER):
    return (c[0] + r * math.cos(math.radians(deg)), c[1] + r * math.sin(math.radians(deg)))


def outline(fn, f=1.0, n=240):
    return [polar(fn(360 * i / n) * f, 360 * i / n) for i in range(n)]


def in_sand(x, y, pad=0.0):
    d = math.hypot(x - CENTER[0], y - CENTER[1])
    return d < r_sand(math.degrees(math.atan2(y - CENTER[1], x - CENTER[0]))) - pad


def box_dist(x, y):
    dx = max(BOX[0] - x, 0, x - BOX[2])
    dy = max(BOX[1] - y, 0, y - BOX[3])
    return math.hypot(dx, dy)


def in_box(x, y, pad=0.0):
    return BOX[0] - pad <= x <= BOX[2] + pad and BOX[1] - pad <= y <= BOX[3] + pad


LAYOUT = {"island": "Ocean Shore v2 (layout for approval)", "places": [], "egg_regions": [], "egg_spots": [], "checks": {},
          "boss": {"box_blender": list(BOX), "box_roblox_xz": [BOX[0], -BOX[3], BOX[2], -BOX[1]], **MEGALODON}}


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


# ------------------------------------------------------------------ the island body: one cohesive piece + layered underside
ter = CL.ClassicMesh("Island_Top", C["OSV2_Terrain"])
ter.slab(outline(r_isl), -10, 0.6, "dirt_rim", chamfer=0.4, top="moss")
sand = CL.ClassicMesh("Sand_Plateau", C["OSV2_Terrain"])
SAND_PTS = outline(r_sand, n=300)
sand.slab(SAND_PTS, -0.2, SAND_Z, "sand_dark", chamfer=0.35, top="sand")
und = CL.ClassicMesh("Island_Underside", C["OSV2_Underside"])
for f, z0, z1, look in ((0.93, -26, -10, "rock_grey"), (0.8, -44, -26, "rock_grey_dark"), (0.62, -62, -44, "rock_grey"),
                        (0.42, -78, -62, "rock_grey_dark"), (0.22, -90, -78, "rock_grey")):
    und.slab(outline(lambda d, f=f: r_isl(d) * f * (1 + 0.03 * math.sin(math.radians(9 * d) + f * 7))), z0, z1, look, chamfer=1.5)
for k in range(150):  # craggy rock faces round the rim (the reference's grey stacked cliffs), moss on the upper ones
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
    zt = -90 + (1 - f) * 0 if f < 0.3 else -62 - (0.62 - f) * 40 if f < 0.62 else -44
    h = rng.uniform(8, 22)
    und.rock(x, y, zt - h, rng.uniform(5, 10), rng.uniform(4, 9), h, rng.choice(("rock_grey", "rock_grey_dark")), rot=rng.uniform(0, 90), taper=-0.3)
for k in range(40):  # vines down the rim
    d = rng.uniform(0, 360)
    x, y = polar(r_isl(d) + 0.3, d)
    P.vine(und, x, y, 0.4, rng.uniform(6, 18), d)
for k in range(220):  # the brown dirt band right under the grass rim, chunky + uneven (the concept's layered edge)
    d = k * 360 / 220 + rng.uniform(-0.6, 0.6)
    x, y = polar(r_isl(d) - 0.6 + rng.uniform(-0.3, 0.6), d)
    und.rock(x, y, -9.5 + rng.uniform(-1.5, 1.5), rng.uniform(4, 7), rng.uniform(3, 5), rng.uniform(4, 8),
             rng.choice(("dirt_rim", "dirt_rim_dark", "dirt_rim")), rot=d + 90 + rng.uniform(-8, 8), jitter=0.12, taper=0.0)
for k in range(70):  # roots hanging out of the dirt band
    d = rng.uniform(0, 360)
    x, y = polar(r_isl(d) + 0.4, d)
    z = rng.uniform(-6, -2)
    p0 = (x, y, z)
    for j in range(3):
        p1 = (p0[0] + rng.uniform(-0.6, 0.6), p0[1] + rng.uniform(-0.6, 0.6), p0[2] - rng.uniform(1.5, 3.2))
        und.beam(p0, p1, 0.3, 0.3, "root")
        p0 = p1
ter.done()
sand.done()
und.done()

# ------------------------------------------------------------------ the playable sand: colour variation + small, flat decor
dec = CL.ClassicMesh("Sand_Decor", C["OSV2_Play_Decor"])
BOSS_PAD = (0.0, 10.0)


def blob(cx, cy, r, n=14):
    return [(cx + r * (1 + 0.25 * math.sin(3 * a + cx)) * math.cos(a), cy + r * 0.8 * (1 + 0.2 * math.cos(2 * a + cy)) * math.sin(a))
            for a in [2 * math.pi * i / n for i in range(n)]]


patches = 0
while patches < 34:
    x, y = rng.uniform(BOX[0], BOX[2]), rng.uniform(BOX[1], BOX[3])
    if not in_sand(x, y, 14) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < 20:
        continue
    look = ("sand_light", "sand_dark", "wet_sand")[patches % 3]
    dec.slab(blob(x, y, rng.uniform(6, 16)), SAND_Z - 0.05, SAND_Z + 0.06, look, chamfer=0.03)
    patches += 1
P.boss_pad(dec, *BOSS_PAD, SAND_Z + 0.06)
note("Megalodon's start pad", *BOSS_PAD, "a subtle ring of sunken flat stones flush with the sand (he leaves it to hunt)")

# ------------------------------------------------------------------ landmarks: spawn dock SW, escape portal NE
lm = CL.ClassicMesh("Landmarks", C["OSV2_Landmarks"])
tip = polar(r_sand(SW) - 4, SW)
dock_end = polar(r_isl(SW) + 26, SW)
SPAWN = polar(r_isl(SW) + 36, SW)
P.spawn_dock(lm, tip[0], tip[1], dock_end[0], dock_end[1], SAND_Z, width=12)
P.spawn_pad(lm, *SPAWN, SAND_Z)
dyaw = math.atan2(dock_end[1] - tip[1], dock_end[0] - tip[0])
dlen = math.hypot(dock_end[0] - tip[0], dock_end[1] - tip[1])
prev = {}
for k in range(int(dlen / 8) + 1):
    t = min(1.0, k * 8 / dlen)
    px, py = tip[0] + (dock_end[0] - tip[0]) * t, tip[1] + (dock_end[1] - tip[1]) * t
    for sgn in (-1, 1):
        qx, qy = px - math.sin(dyaw) * sgn * 6.6, py + math.cos(dyaw) * sgn * 6.6
        D.torch(lm, qx, qy, SAND_Z, 4.6)
        if sgn in prev:
            D.rope(lm, (*prev[sgn], SAND_Z + 3.4), (qx, qy, SAND_Z + 3.4), 0.5)
        prev[sgn] = (qx, qy)
for k, (dl, dw) in enumerate(((6, -9), (9, 8), (12, -8.5))):  # cargo by the landing (out of his reach)
    cx, cy = tip[0] - math.cos(dyaw) * dl - math.sin(dyaw) * dw, tip[1] - math.sin(dyaw) * dl + math.cos(dyaw) * dw
    (D.crate if k % 2 else D.barrel)(lm, cx, cy, SAND_Z)
note("SPAWN (arrival pad, safe zone)", *SPAWN, "classic blue-and-white spawn pad at the end of a lantern-lit boardwalk")
PORTAL = polar(r_sand(NE) - 16, NE)
P.escape_portal(lm, *PORTAL, SAND_Z, rot=NE - 90)
note("ESCAPE PORTAL (RETURN HOME)", *PORTAL, "purple vortex in a ring of craggy rock, flush with the sand (no stairs)")
lm.done()
HI.boss(C["OSV2_Landmarks"], "Megalodon", BOSS_PAD[0], BOSS_PAD[1], z=SAND_Z, scale=MEGALODON["Scale"], facing=135)

# ------------------------------------------------------------------ egg regions (candidate EggSpots: planned, not modelled eggs)
REGIONS = {"Palm Clearing": ((-82, 32), 26, "west, under the palm cliffs: mid risk"),
           "Coral Flats": ((86, -18), 26, "east, by the coral pools: mid risk"),
           "Shell Beach": ((4, -66), 24, "south, nearest the spawn: the safer start"),
           "Driftwood Dunes": ((-38, 82), 22, "north, on Megalodon's patrol line: high risk"),
           "Shipwreck Shore": ((74, 76), 22, "north-east, on the way to the portal: high risk")}
mk = CL.ClassicMesh("Egg_Spot_Markers", C["OSV2_Gameplay_Markers"])
pe = CL.ClassicMesh("Preview_Eggs", C["OSV2_Preview_Eggs"])
spots = []
for name, ((cx, cy), R, why) in REGIONS.items():
    LAYOUT["egg_regions"].append({"name": name, "blender_xy": [cx, cy], "roblox_xz": [cx, -cy], "radius": R, "risk": why})
    want = 6 if R >= 24 else 5
    tries = 0
    got = 0
    while got < want and tries < 2000:
        tries += 1
        a, f = rng.uniform(0, 2 * math.pi), math.sqrt(rng.uniform(0.05, 1))
        x, y = cx + R * f * math.cos(a), cy + R * f * math.sin(a)
        if not in_sand(x, y, DROP_MAX + 2) or not in_box(x, y, -4) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < 22:
            continue
        if any((x - qx) ** 2 + (y - qy) ** 2 < 81 for qx, qy, _ in spots):
            continue
        spots.append((x, y, name))
        got += 1
for i, (x, y, name) in enumerate(spots):
    P.egg_marker(mk, x, y, SAND_Z + 0.06)
    if i % 2 == 0:
        P.preview_egg(pe, x, y, SAND_Z, ("pool", "coral_pink", "gold", "spawn_blue", "shell_pink")[i % 5])
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "region": name})
mk.done()
pe.done()
EGG_KEEP = [(x, y) for x, y, _ in spots]

# small flat decor on the playable sand: walk-through, under 2.5 studs, never in a lane's way (collision off in Roblox)
for k in range(260):
    x, y = rng.uniform(BOX[0] - 14, BOX[2] + 14), rng.uniform(BOX[1] - 14, BOX[3] + 14)
    if not in_sand(x, y, 3) or math.hypot(x - BOSS_PAD[0], y - BOSS_PAD[1]) < 16 or any((x - a) ** 2 + (y - b) ** 2 < 25 for a, b in EGG_KEEP):
        continue
    edge = not in_sand(x, y, 22)  # (richer decor toward the edges, sparser in the middle)
    roll = rng.random()
    if roll < 0.28:
        P.shell(dec, x, y, SAND_Z, rng.uniform(0.8, 1.3))
    elif roll < 0.48:
        P.starfish(dec, x, y, SAND_Z, rng.uniform(0.8, 1.3))
    elif roll < 0.62:
        P.pebbles(dec, x, y, SAND_Z, rng.randint(2, 5))
    elif roll < 0.8 and (edge or rng.random() < 0.35):
        P.tuft(dec, x, y, SAND_Z, rng.uniform(0.8, 1.2))
    elif roll < 0.9 and (edge or rng.random() < 0.3):
        P.coral(dec, x, y, SAND_Z, rng.uniform(0.4, 0.6))
    elif roll < 0.96:
        P.driftwood(dec, x, y, SAND_Z)
dec.done()

# ------------------------------------------------------------------ the scenery ring (DETAILED pass, after crnuch approved the
# layout 2026-10-19). Everything stays 18+ studs clear of Megalodon's reach (clear_of_reach): stacked-stone cliff massifs
# (tall N + NW + W like the concept, low S so the aerial sees in), grass terraces, foam-edged pools with coral gardens,
# shoreline inlets on the sand margin, a high cascade (NW), edge falls (W through an arch, E, a double SE), the north sea
# arch, a west cave, the wreck (E), palm groves (5 styles), bushes, hibiscus, ferns, grass.
sc = CL.ClassicMesh("Scenery_Rocks", C["OSV2_Scenery"])
wat = CL.ClassicMesh("Water", C["OSV2_Water"])
foam = CL.ClassicMesh("Foam_Mist", C["OSV2_Water"])
veg = CL.ClassicMesh("Vegetation", C["Vegetation"])
used = []
LAYOUT["fx"] = {"fall_landings": [], "edge_lips": [], "gull_rings": [], "pools": []}


def clear_of_reach(x, y, r=0.0):
    """Scenery keeps out of everything Megalodon can sweep: his box + REACH (charge lane half-width + body) + 1."""
    return not in_box(x, y, REACH + 1 + r)


def ring_pt(deg, f):
    """A point in the scenery ring at angle deg, f = 0 (sand edge) .. 1 (island rim)."""
    rs = r_sand(deg)
    return polar(rs + 5 + (ring_w(deg) - 9) * f, deg)


def push_out(deg, f, r):
    x, y = ring_pt(deg, f)
    while not clear_of_reach(x, y, r) and f < 1.3:
        f += 0.04
        x, y = ring_pt(deg, f)
    return x, y, f


def sector_h(deg):
    d = deg % 360
    if 206 <= d < 242:
        return 0.0  # the spawn lobe stays open
    if 242 <= d < 300:
        return rng.uniform(5, 10)
    if 300 <= d < 345:
        return rng.uniform(9, 16)
    if d >= 345 or d < 30:
        return rng.uniform(11, 19)
    if 30 <= d < 60:
        return rng.uniform(9, 14)  # (low round the portal: it stays the landmark)
    if 60 <= d < 135:
        return rng.uniform(22, 34)
    if 135 <= d < 162:
        return rng.uniform(30, 40)
    return rng.uniform(19, 29)  # west


# pools (rock pockets with a sand bank, foam on the water's edge, coral gardens), the falls they feed
POOLS = {148: (15, 0.28, None), 175: (15, 0.4, 9), 326: (17, 0.45, 7), 22: (13, 0.45, 7), 266: (11, 0.4, None), 108: (10, 0.22, None)}
for deg, (R, f, fall) in POOLS.items():
    px, py, f = push_out(deg, f, R + 4)
    pts = P_pts = [(px + R * (1 + 0.18 * math.sin(3 * a + deg)) * math.cos(a), py + R * 0.8 * (1 + 0.15 * math.cos(2 * a + deg)) * math.sin(a))
                   for a in [2 * math.pi * i / 22 for i in range(22)]]
    bank = [(px + (x - px) * 1.18, py + (y - py) * 1.18) for x, y in pts]
    sc.slab(bank, 0.3, 0.68, "wet_sand", chamfer=0.1, top="sand_light")
    wat.slab(pts, 0.0, 0.8, "pool_deep", chamfer=0.08, top="pool")
    D.foam_outline(foam, pts, 0.8)
    used.append((px, py, R + 4))
    LAYOUT["fx"]["pools"].append([round(px, 1), round(py, 1), R])
    for k in range(12):  # the rock rim (not all the way round: open on the sand side)
        a = math.radians(k * 30 + rng.uniform(-8, 8))
        rx_, ry_ = px + math.cos(a) * (R + 3.5), py + math.sin(a) * (R * 0.8 + 3.5)
        if clear_of_reach(rx_, ry_, 4) and math.hypot(rx_ - CENTER[0], ry_ - CENTER[1]) > math.hypot(px - CENTER[0], py - CENTER[1]) - R * 0.3:
            D.cliff_column(sc, veg, rx_, ry_, 0.4, rng.uniform(2, 6), rng.uniform(4, 7), rng.uniform(3.5, 6), math.degrees(a), plants=rng.random() < 0.5)
    for k in range(rng.randint(5, 8)):  # the coral garden in the pool
        a, rr = math.radians(rng.uniform(0, 360)), rng.uniform(0.15, 0.6) * R
        cx_, cy_ = px + math.cos(a) * rr, py + math.sin(a) * rr * 0.8
        pick = rng.random()
        if pick < 0.3:
            P.coral(sc, cx_, cy_, 0.8, rng.uniform(0.8, 1.2))
        elif pick < 0.5:
            D.brain_coral(sc, cx_, cy_, 0.5, rng.uniform(1.2, 1.8))
        elif pick < 0.7:
            D.tube_coral(sc, cx_, cy_, 0.8, rng.uniform(0.8, 1.1))
        elif pick < 0.85:
            P.fan_coral(sc, cx_, cy_, 0.8, rng.uniform(0.8, 1.2), rng.choice(("coral_purple", "coral_pink")))
        else:
            D.seaweed(sc, cx_, cy_, 0.5, rng.uniform(2.5, 4))
    for k in range(6):  # shells, starfish, a conch on the bank
        a = math.radians(rng.uniform(0, 360))
        bx, by = px + math.cos(a) * (R + 1.6), py + math.sin(a) * (R * 0.8 + 1.6)
        (P.starfish if k % 3 == 0 else (D.conch if k % 3 == 1 else P.shell))(sc, bx, by, 0.68)
    if fall:
        ex, ey = polar(r_isl(deg) - 0.5, deg)
        wat.beam((px, py, 0.75), (ex, ey, 0.7), fall * 0.85, 0.3, "pool")  # the stream to the edge
        D.foam_outline(foam, [(px, py), (ex, ey)], 0.85, step=2.2)
        D.edge_fall(wat, foam, ex, ey, 0.6, -80, deg, width=fall)
        LAYOUT["fx"]["edge_lips"].append([round(ex, 1), round(ey, 1), 0.6, deg])
        note(f"Waterfall off the edge ({deg} deg)", ex, ey, "a pool spilling over the island edge, foam + spray")
        if deg == 326:  # the SE double fall (as in the concept)
            ex2, ey2 = polar(r_isl(deg - 9) - 0.5, deg - 9)
            wat.beam((px, py, 0.75), (ex2, ey2, 0.7), fall * 0.7, 0.3, "pool")
            D.edge_fall(wat, foam, ex2, ey2, 0.6, -70, deg - 9, width=fall * 0.85)
            LAYOUT["fx"]["edge_lips"].append([round(ex2, 1), round(ey2, 1), 0.6, deg - 9])
        if deg == 175:  # the west fall pours out under a small rock arch
            mx, my = polar(r_isl(deg) - 7, deg)
            P.rock_arch(sc, mx, my, 0.4, span=fall + 7, h=12, rot=deg + 90)
            used.append((mx, my, 10))
note("Rock pools", 0, 0, "six turquoise pools in rock pockets round the edge, sand banks, foam, coral gardens (scenery)")

# the high cascade (NW): from the tallest cliff top down into the NW pool
hp = [(dd, v) for dd, v in POOLS.items() if dd == 148][0]
hx, hy, hf = push_out(148, hp[1][1], hp[1][0] + 4)
cdx, cdy = math.cos(math.radians(148)), math.sin(math.radians(148))
cx_, cy_ = hx + cdx * (hp[1][0] + 10), hy + cdy * (hp[1][0] + 10)
ctop = D.cliff_column(sc, veg, cx_, cy_, 0.4, 38, 16, 13, 148, plants=False)
for sgn in (-1, 1):  # flanking towers so the fall comes out of a notch
    D.cliff_column(sc, veg, cx_ - cdy * sgn * 12, cy_ + cdx * sgn * 12, 0.4, rng.uniform(34, 42), 12, 11, 148)
land = D.waterfall_tall(wat, foam, (cx_ - cdx * 6.5, cy_ - cdy * 6.5, ctop - 0.9), 0.8, 148 + 180, width=6.5, ledges=2)
LAYOUT["fx"]["fall_landings"].append([round(land[0], 1), round(land[1], 1), 0.8])
used.append((cx_, cy_, 22))
note("The high cascade", cx_, cy_, "a waterfall dropping ~38 studs in three steps from the NW cliffs into a pool")

ARCH, CAVE, WRECK = 96, 200, 4
ax, ay, _ = push_out(ARCH, 0.62, 18)
P.rock_arch(sc, ax, ay, 0.4, span=24, h=24, rot=ARCH - 90)
used.append((ax, ay, 22))
note("Sea arch", ax, ay, "a big natural arch on the north rim")
cvx, cvy, _ = push_out(CAVE, 0.62, 16)
for k in range(5):  # the cave massif, its mouth facing the sand
    a = math.radians(CAVE + (k - 2) * 7)
    D.cliff_column(sc, veg, cvx + math.cos(a) * 6 * (k - 2) * 0.4, cvy + math.sin(a) * 6 * (k - 2) * 0.4, 0.4, rng.uniform(24, 30), 12, 11, CAVE)
mouth = polar(math.hypot(cvx - CENTER[0], cvy - CENTER[1]) - 6.2, CAVE)
sc.ring_v(*mouth, 5.4, 4.8, 7.6, 3.0, ["rock_grey_dark", "rock_grey"], rot=CAVE + 90, segs=9, gap=0.2, a0=0, a1=180)
sc.disc_v(*mouth, 4.6, 5.0, 0.4, "black", rot=CAVE + 90, segs=20)
sc.brick(*mouth, 0.4, 9.6, 1.2, 4.6, "black", rot=CAVE + 90, bevel=0.0)
used.append((cvx, cvy, 20))
note("Coastal cave", cvx, cvy, "a dark cave mouth in the west cliffs (scenery: not enterable)")
wx, wy, _ = push_out(WRECK, 0.6, 18)
D.shipwreck2(sc, wx, wy, 0.4, rot=WRECK + 75)
used.append((wx, wy, 24))
note("Shipwreck", wx, wy, "a heeled-over wreck on the east rocks: ribs, torn sail, spilled barrels + crates")

# shoreline inlets: shallow water over the sand margin (flush, walk-through), foam on their edge
for deg in (182, 160, 120, 82, 300, 352, 14, 272):
    rs = r_sand(deg)
    ix, iy = polar(rs - 5.5, deg)
    if in_box(ix, iy, 2):
        continue
    tx_, ty_ = -math.sin(math.radians(deg)), math.cos(math.radians(deg))
    L, Wd = rng.uniform(10, 16), rng.uniform(4, 6)
    pts = [(ix + tx_ * L * math.cos(a) + math.cos(math.radians(deg)) * Wd * math.sin(a) * (1 + 0.2 * math.sin(3 * a)),
            iy + ty_ * L * math.cos(a) + math.sin(math.radians(deg)) * Wd * math.sin(a) * (1 + 0.2 * math.sin(3 * a)))
           for a in [2 * math.pi * i / 18 for i in range(18)]]
    pts = [(x, y) for x, y in pts if not in_box(x, y, 0.5)] or pts
    if len(pts) >= 6:
        wat.slab(pts, SAND_Z - 0.04, SAND_Z + 0.07, "shallows", chamfer=0.02)
        D.foam_outline(foam, pts, SAND_Z + 0.07, step=1.8)

# the cliff massifs: one continuous wall of stacked stone round the outer ring (a smooth height profile: tallest NW, low
# south so the aerial sees in), its columns overlapping + joined by lower connector blocks so it reads as a cliff, not a
# row of pillars; a front row of grass-topped terraces; boulders at their feet
ANCH = [(0, 15), (22, 17), (38, 12), (56, 13), (72, 27), (98, 31), (126, 34), (148, 40), (168, 30), (190, 27), (204, 16),
        (212, 0), (240, 0), (250, 8), (275, 8), (300, 11), (325, 15), (345, 15), (360, 15)]


def massif_h(deg):
    d = deg % 360
    for (a0, h0), (a1, h1) in zip(ANCH, ANCH[1:]):
        if a0 <= d <= a1:
            t = (d - a0) / max(1e-6, a1 - a0)
            t = t * t * (3 - 2 * t)
            h = h0 + (h1 - h0) * t
            return max(0.0, h + 2.4 * math.sin(math.radians(7 * d)) + 1.6 * math.sin(math.radians(13 * d) + 1)) if h > 0.5 else 0.0
    return 0.0


back = []
deg = 0.0
while deg < 360:
    H = massif_h(deg)
    if H > 0.5:
        f = 0.76 + 0.07 * math.sin(math.radians(5 * deg))
        x, y = ring_pt(deg, f)
        w = rng.uniform(15, 20)
        if clear_of_reach(x, y, w / 2 + 2) and not any(math.hypot(x - ux, y - uy) < ur for ux, uy, ur in used):
            h = H * rng.uniform(0.92, 1.08)
            D.cliff_column(sc, veg, x, y, 0.4, h, w, w * rng.uniform(0.75, 0.9), deg + 90 + rng.uniform(-6, 6))
            if back and math.hypot(x - back[-1][0], y - back[-1][1]) < 26:  # a connector block joins it to the last column
                bx, by, bh = back[-1]
                mx, my = (x + bx) / 2, (y + by) / 2
                D.cliff_column(sc, veg, mx, my, 0.4, min(h, bh) * rng.uniform(0.55, 0.72), math.hypot(x - bx, y - by) + 5, w * 0.7,
                               math.degrees(math.atan2(y - by, x - bx)), plants=rng.random() < 0.4)
            back.append((x, y, h))
        else:
            back.append((x, y, 0)) if False else None
    deg += 3.4
for k in range(0, 360, 7):  # the front terraces (lower, grass-topped, plants on them)
    deg = k + rng.uniform(-2, 2)
    H = massif_h(deg)
    if H <= 0.5:
        continue
    x, y = ring_pt(deg, rng.uniform(0.38, 0.5))
    w = rng.uniform(10, 15)
    if not clear_of_reach(x, y, w / 2 + 2) or any(math.hypot(x - ux, y - uy) < ur for ux, uy, ur in used):
        continue
    D.cliff_column(sc, veg, x, y, 0.4, H * rng.uniform(0.38, 0.55), w, w * rng.uniform(0.75, 0.95), deg + 90 + rng.uniform(-10, 10))
    used.append((x, y, w * 0.5))
for k in range(70):  # boulders at the feet of the cliffs, toward the sand (still clear of his reach)
    deg = rng.uniform(0, 360)
    if massif_h(deg) <= 0.5:
        continue
    x, y = ring_pt(deg, rng.uniform(0.02, 0.2))
    if not clear_of_reach(x, y, 3) or any(math.hypot(x - ux, y - uy) < ur * 0.8 for ux, uy, ur in used):
        continue
    D.cliff_column(sc, veg, x, y, 0.4, rng.uniform(2, 4.5), rng.uniform(3, 5.5), rng.uniform(2.5, 4.5), rng.uniform(0, 90), plants=False)

# vegetation on the ring's grass: palm groves (lean in), bushes, hibiscus, ferns, grass
placed = 0
tries = 0
while placed < 150 and tries < 6000:
    tries += 1
    deg = rng.uniform(0, 360)
    x, y = ring_pt(deg, rng.uniform(-0.04, 0.95))
    if abs((deg - SW + 180) % 360 - 180) < 9 or not clear_of_reach(x, y, 9):
        continue
    if any(math.hypot(x - ux, y - uy) < ur * 0.75 for ux, uy, ur in used):
        continue
    z = 0.6
    roll = rng.random()
    lean_in = math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-50, 50)
    if roll < 0.32:
        D.palm2(veg, x, y, z, lean=lean_in)
        used.append((x, y, 4))
    elif roll < 0.55:
        D.bush(veg, x, y, z, rng.uniform(0.8, 1.3))
    elif roll < 0.68:
        D.hibiscus(veg, x, y, z, rng.uniform(0.8, 1.1))
    elif roll < 0.82:
        P.fern_bush(veg, x, y, z, rng.uniform(0.8, 1.3))
    else:
        D.grass_clump(veg, x, y, z, rng.uniform(0.9, 1.3))
    placed += 1
for k in range(6):  # palms by the spawn lobe + round the portal (only where they clear his reach)
    for (x, y, z) in ((*polar(r_sand(SW) - 2, SW + rng.choice((-1, 1)) * rng.uniform(13, 19)), SAND_Z),
                      (*polar(r_sand(NE) + 7, NE + rng.choice((-1, 1)) * rng.uniform(20, 30)), 0.6)):
        if clear_of_reach(x, y, 10):
            D.palm2(veg, x, y, z, lean=math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-40, 40))
LAYOUT["fx"]["gull_rings"] = [[0, 20, 150, 46], [-120, 120, 60, 38], [140, -60, 70, 34]]
sc.done()
wat.done()
foam.done()
veg.done()

# ------------------------------------------------------------------ the sky: the sea far below, clouds (drift), floating islets
sea = CL.ClassicMesh("Sky_Sea", C["OSV2_Sky"])
sea.cyl(0, 0, 4000, -330, -320, "sea", segs=64)
sea.done()
cl = CL.ClassicMesh("Sky_Clouds", C["OSV2_Sky"])
for k in range(18):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(330, 720), d, (0, 0))
    z = rng.uniform(-140, 70)
    for j in range(rng.randint(6, 10)):
        r = rng.uniform(9, 22)
        cl.sphere(x + rng.uniform(-28, 28), y + rng.uniform(-16, 16), z + rng.uniform(-3, 9), r, r * 0.8, r * 0.55, "white", seg=14, rings=8)
cl.done()
isl = CL.ClassicMesh("Sky_Islets", C["OSV2_Sky"])
for k in range(8):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(390, 620), d, (0, 0))  # (well clear of the island's silhouette)
    z = rng.uniform(-60, 40)
    s_ = rng.uniform(12, 24)
    isl.slab(blob(x, y, s_, 12), z - 3, z, "dirt_rim", chamfer=0.4, top="moss")
    for j in range(3):  # a layered rock underside
        isl.rock(x, y, z - 3 - (j + 1) * s_ * 0.4, s_ * (1.2 - j * 0.3), s_ * (1.0 - j * 0.25), s_ * 0.42, rng.choice(("rock_grey", "rock_grey_dark")), rot=d + j * 20, taper=-0.3)
    D.palm2(isl, x + rng.uniform(-3, 3), y + rng.uniform(-3, 3), z, style=rng.choice(("short", "lean", "twin")))
    D.bush(isl, x + rng.uniform(-5, 5), y + rng.uniform(-5, 5), z, 1.0)
isl.done()

# ------------------------------------------------------------------ studs: broad terrain + structural tops only (classic Roblox)
K.studs_done(C["Ocean_Shore_V2"], only=lambda o, look: look in P.STUD_LOOKS and not o.name.startswith(("Sky_", "Preview", "Egg_Spot", "Label", "Diagram")))

# ------------------------------------------------------------------ gameplay checks (measured on the built geometry)
objs = [o for o in scene.objects if o.type == "MESH" and not o.name.startswith(("Studs_", "StudSource_", "Sky_", "Preview", "Egg_Spot", "Boss_", "Sand_Decor"))]
_dec = bpy.data.objects["Sand_Decor"]
LAYOUT["checks"]["sand_decor"] = (f"small walk-through decor on the sand (shells, starfish, pebbles, tufts, tiny coral, flat driftwood, "
                                  f"patches): at most {max(v.co.z for v in _dec.data.vertices) - SAND_Z:.1f} studs tall, collision off in Roblox")
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
OBST = 2.5  # anything taller than this above the sand would block a charge / a warning lane


def ground(x, y):
    hit = bvh.ray_cast(Vector((x, y, 300)), DOWN, 600)
    return hit[0].z if hit[0] is not None else None


def blocked(x, y):
    hit = bvh.ray_cast(Vector((x, y, 300)), DOWN, 600)
    z = hit[0].z if hit[0] is not None else None
    bad = z is None or z > SAND_Z + OBST or z < SAND_Z - 0.6
    if bad:
        k = "off the island" if z is None else (owner[hit[2]] + (" (above)" if z > SAND_Z else " (below the sand)"))
        WHY[k] = WHY.get(k, 0) + 1
        if len(WHY.setdefault("_pts", [])) < 12 and z is not None:
            WHY["_pts"].append((round(x), round(y), round(z, 1), owner[hit[2]], round(box_dist(x, y), 1)))
    return bad


# 1. the boss's box: every point on open sand?
cells = bad = 0
y = BOX[1]
while y <= BOX[3]:
    x = BOX[0]
    while x <= BOX[2]:
        cells += 1
        bad += blocked(x, y) or not in_sand(x, y)
        x += 4
    y += 4
LAYOUT["checks"]["box_open_sand"] = f"{cells - bad}/{cells} sample points (4-stud grid) are open sand"
# 2. charges: from a grid of start points, 16 directions, the lane (20 wide) clear for its full clamped length?
lanes = clear = full = 0
for sx in range(int(BOX[0]) + 10, int(BOX[2]), 30):
    for sy in range(int(BOX[1]) + 10, int(BOX[3]), 30):
        for k in range(16):
            a = math.radians(k * 22.5)
            dx, dy = math.cos(a), math.sin(a)
            L = MEGALODON["Length"]
            ex, ey = min(max(sx + dx * L, BOX[0]), BOX[2]), min(max(sy + dy * L, BOX[1]), BOX[3])
            L2 = math.hypot(ex - sx, ey - sy)
            lanes += 1
            full += L2 >= L - 0.5
            if L2 > 0.1:  # (BossService walks straight to the CLAMPED goal: the lane follows that path)
                dx, dy = (ex - sx) / L2, (ey - sy) / L2
            ok = True
            t = 0.0
            while t <= L2 and ok:
                for off in (-10, -5, 0, 5, 10):
                    if blocked(sx + dx * t - dy * off, sy + dy * t + dx * off):
                        ok = False
                        break
                t += 4
            clear += ok
print("[osv2] lane blockers:", sorted(((k, v) for k, v in WHY.items() if k != "_pts"), key=lambda kv: -kv[1])[:8], WHY.get("_pts"))
WHY.clear()
LAYOUT["checks"]["charge_lanes"] = f"{clear}/{lanes} sampled charges (20-wide lanes) run clear to their end; {full} of them get the full 130 studs (the rest stop at the box edge, as BossService clamps)"
# 3. eggs: drop scatter room
mins = {}
for x, y, name in spots:
    d = math.hypot(x - CENTER[0], y - CENTER[1])
    edge = r_sand(math.degrees(math.atan2(y - CENTER[1], x - CENTER[0]))) - d
    mins[name] = round(min(mins.get(name, 1e9), edge), 1)
LAYOUT["checks"]["egg_edge_clearance"] = {k: f"{v} studs to the sand edge (drops scatter at most {DROP_MAX:.1f})" for k, v in mins.items()}
# 4. spawn + portal vs the box (how far a charge / the body reaches past the box edge = REACH)


def box_dist(x, y):
    dx = max(BOX[0] - x, 0, x - BOX[2])
    dy = max(BOX[1] - y, 0, y - BOX[3])
    return math.hypot(dx, dy)


LAYOUT["checks"]["spawn_safe"] = f"spawn pad {box_dist(*SPAWN):.0f} studs outside the box (his reach past it: {REACH:.1f})"
LAYOUT["checks"]["portal_threat"] = f"portal {box_dist(*PORTAL):.0f} studs outside the box: the last ~{max(0.0, MEGALODON['TriggerRange'] - box_dist(*PORTAL)):.0f} studs of the approach are inside his 60-stud trigger, but he can't follow onto the portal"
# 5. connectivity: spawn -> portal on walkable ground, and NO route that stays out of his reach


def walk_ok(x, y, avoid_reach=False):
    on = in_sand(x, y, 1) or math.hypot(x - SPAWN[0], y - SPAWN[1]) < 10 or \
        abs((math.degrees(math.atan2(y - CENTER[1], x - CENTER[0])) - SW + 180) % 360 - 180) < 3 and math.hypot(x - CENTER[0], y - CENTER[1]) < r_isl(SW) + 40 or \
        math.hypot(x - PORTAL[0], y - PORTAL[1]) < 12
    if not on:
        return False
    if avoid_reach and in_box(x, y, REACH):
        return False
    z = ground(x, y)
    return z is not None and z < SAND_Z + OBST


def bfs(avoid_reach):
    step = 3.0
    start = (round(SPAWN[0] / step), round(SPAWN[1] / step))
    goal = (round(PORTAL[0] / step), round(PORTAL[1] / step))
    seen, todo = {start}, [start]
    while todo:
        cx, cy = todo.pop()
        if abs(cx - goal[0]) <= 3 and abs(cy - goal[1]) <= 3:
            return True
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if (nx, ny) not in seen and walk_ok(nx * step, ny * step, avoid_reach):
                seen.add((nx, ny))
                todo.append((nx, ny))
    return False


LAYOUT["checks"]["spawn_to_portal"] = "reachable on level ground" if bfs(False) else "NOT reachable - fix"
LAYOUT["checks"]["no_safe_bypass"] = "no walkable route avoids his reach (every route crosses his box)" if not bfs(True) else "a route AVOIDS him - fix"
corners = all(in_sand(x, y, 2) for x in (BOX[0], BOX[2]) for y in (BOX[1], BOX[3]))
LAYOUT["checks"]["box_on_sand"] = "all four box corners are on sand" if corners else "a box corner is off the sand - fix"
LAYOUT["checks"]["egg_spots"] = f"{len(spots)} candidate spots in {len(REGIONS)} regions (the zone shows at most 14 eggs at once)"
print("[osv2] checks:", json.dumps(LAYOUT["checks"], indent=1))

# ------------------------------------------------------------------ the gameplay diagram overlays (diagram render only)
dg = CL.ClassicMesh("Diagram_Overlays", C["OSV2_Diagram"])
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


K.PAL.update({"diag_red": (235, 50, 60), "diag_blue": (40, 110, 240), "diag_yellow": (250, 190, 30), "diag_purple": (150, 70, 230),
              "diag_charge": (255, 120, 120)})
for (x0, y0, x1, y1) in ((BOX[0], BOX[1], BOX[2], BOX[1]), (BOX[2], BOX[1], BOX[2], BOX[3]), (BOX[2], BOX[3], BOX[0], BOX[3]), (BOX[0], BOX[3], BOX[0], BOX[1])):
    dash_line(x0, y0, x1, y1, "diag_red", w=2.0)
for name, ((cx, cy), R, why) in REGIONS.items():
    dg.ring(R - 1.0, R + 0.6, ZD, ZD + 0.3, "diag_yellow", cx=cx, cy=cy, segs=48)
dg.ring(14, 16, ZD, ZD + 0.3, "diag_blue", cx=SPAWN[0], cy=SPAWN[1], segs=40)
for t in (0.0, 0.5, 1.0):
    px, py = tip[0] + (dock_end[0] - tip[0]) * t, tip[1] + (dock_end[1] - tip[1]) * t
    dg.ring(6.5, 8, ZD, ZD + 0.3, "diag_blue", cx=px, cy=py, segs=24)
dg.ring(14, 16, ZD, ZD + 0.3, "diag_purple", cx=PORTAL[0], cy=PORTAL[1], segs=40)
CHARGES = [((0, 10), (-82, 32)), ((60, -40), (4, -66)), ((-70, 60), (74, 76)), ((95, 70), PORTAL), ((-95, -70), SPAWN), ((20, 95), (86, -18))]
for (sx, sy), (tx, ty) in CHARGES:
    a = math.atan2(ty - sy, tx - sx)
    ex, ey = sx + math.cos(a) * 130, sy + math.sin(a) * 130
    ex, ey = min(max(ex, BOX[0]), BOX[2]), min(max(ey, BOX[1]), BOX[3])
    L = math.hypot(ex - sx, ey - sy)
    deg = math.degrees(a)
    for off in (-10, 10):  # the 20-wide warning lane
        ox, oy = -math.sin(a) * off, math.cos(a) * off
        dg.brick((sx + ex) / 2 + ox, (sy + ey) / 2 + oy, ZD + 0.5, L, 1.0, 0.3, "diag_charge", rot=deg, bevel=0.0)
    dg.brick((sx + ex) / 2, (sy + ey) / 2, ZD + 0.5, L, 2.0, 0.3, "diag_red", rot=deg, bevel=0.0)
    for s_ in (-1, 1):  # the arrowhead
        ha = a + math.pi + s_ * 0.5
        dg.brick(ex + math.cos(ha) * 4, ey + math.sin(ha) * 4, ZD + 0.5, 9, 2.0, 0.3, "diag_red", rot=math.degrees(ha), bevel=0.0)
    dg.cyl(sx, sy, 3.2, ZD + 0.5, ZD + 0.8, "diag_red", segs=16)
dg.done()
lab = K.Mesh("Label_Plates", C["OSV2_Labels"])
for text, x, y in (("SPAWN\nsafe zone", SPAWN[0] + 26, SPAWN[1] - 6), ("ESCAPE PORTAL", PORTAL[0] + 4, PORTAL[1] + 24),
                   ("MEGALODON START", BOSS_PAD[0], BOSS_PAD[1] - 22), ("BOSS ROAMS THE WHOLE\nRED BOX (240 x 210)", 38, 34),
                   ("EGGS: Palm Clearing", -82, 62), ("EGGS: Coral Flats", 86, 12), ("EGGS: Shell Beach", 4, -96),
                   ("EGGS: Driftwood Dunes", -38, 108), ("EGGS: Shipwreck Shore", 74, 104), ("CHARGE = 130 x 20\n(stops at the box edge)", -60, -40),
                   ("SCENERY: cliffs, pools,\nwaterfalls, palms (not playable)", -175, 120), ("SCENERY", 190, -40), ("N", 0, 270)):
    HI.label(C["OSV2_Labels"], lab, text, x, y, 6.5, z=ZD + 30)
lab.done()

# ------------------------------------------------------------------ light, save
world, sun = K.sky_and_sun(scene, sun_energy=4.0, sun_rot=(48, 8, -28), sky=(0.2, 0.5, 0.98), horizon=(0.66, 0.85, 1.0))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=24)
C["OSV2_Diagram"].hide_render = True
C["OSV2_Labels"].hide_render = True
C["OSV2_Gameplay_Markers"].hide_render = True
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "ocean_shore_v2.blend"), compress=True)
with open(os.path.join(HERE, "osv2_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[osv2] saved; {len(spots)} egg spots")

sp = (SPAWN[0], SPAWN[1])
CAMS = {
    "aerial": (("Cam_Aerial", (70, -505, 365), (0, 18, -18), 34), 2400, 1350),  # (the concept's angle: spawn bottom-left, portal top-right)
    "ground_spawn": (("Cam_Ground_Spawn", (sp[0] - 9, sp[1] - 9, SAND_Z + 9), (0, 30, SAND_Z + 6), 24), 1920, 1080),
    "ground_eggs": (("Cam_Ground_Eggs", (-122, 6, SAND_Z + 8), (-40, 52, SAND_Z + 3), 24), 1920, 1080),
    "boss_view": (("Cam_Boss_View", (-34, -30, SAND_Z + 30), (70, 85, SAND_Z), 22), 1920, 1080),
    "ground_portal": (("Cam_Ground_Portal", (PORTAL[0] - 52, PORTAL[1] - 46, SAND_Z + 9), (PORTAL[0], PORTAL[1], SAND_Z + 12), 26), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        scene.eevee.taa_render_samples = 32 if key == "aerial" else 24
        K.render(scene, cam, os.path.join(RENDERS, f"osv2_{key}.jpg"), w, h)
    if not only or "topdown" in only:
        cam = K.camera("Cam_TopDown", (0, 20, 1500), (0, 20, 0), ortho=560, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.eevee.taa_render_samples = 16
        K.render(scene, cam, os.path.join(RENDERS, "osv2_topdown.jpg"), 2000, 2000)
    if not only or "diagram" in only:
        cam = bpy.data.objects.get("Cam_TopDown") or K.camera("Cam_TopDown", (0, 20, 1500), (0, 20, 0), ortho=560, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        C["OSV2_Diagram"].hide_render = False
        C["OSV2_Labels"].hide_render = False
        C["OSV2_Gameplay_Markers"].hide_render = False
        C["OSV2_Preview_Eggs"].hide_render = True
        C["OSV2_Sky"].hide_render = True
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        K.render(scene, cam, os.path.join(RENDERS, "osv2_gameplay_diagram.jpg"), 2000, 2000)
