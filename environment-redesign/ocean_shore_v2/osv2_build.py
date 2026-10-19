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

# ------------------------------------------------------------------ the scenery ring (outside the boss's box): cliffs, pools,
# waterfalls, palm groves, the arch, the cave, the shipwreck, coral
sc = CL.ClassicMesh("Scenery_Rocks", C["OSV2_Scenery"])
wat = CL.ClassicMesh("Water", C["OSV2_Water"])
veg = CL.ClassicMesh("Vegetation", C["Vegetation"])
POOLS = {175: 17, 128: 14, 336: 15, 16: 13, 262: 12}
FALLS = {175: 9, 128: 7, 336: 8, 16: 7}
used = []


def clear_of_reach(x, y, r=0.0):
    """Scenery keeps out of everything Megalodon can sweep: his box + REACH (charge lane half-width + body) + 1."""
    return not in_box(x, y, REACH + 1 + r)


def ring_pt(deg, f):
    """A point in the scenery ring at angle deg, f = 0 (sand edge) .. 1 (island rim)."""
    rs = r_sand(deg)
    return polar(rs + 5 + (ring_w(deg) - 9) * f, deg)


for deg, R in POOLS.items():  # turquoise pools in rock pockets, spilling into the waterfalls
    f = 0.42
    px, py = ring_pt(deg, f)
    while not clear_of_reach(px, py, R + 4) and f < 1.2:  # (pushed out past his reach)
        f += 0.05
        px, py = ring_pt(deg, f)
    wat.slab(blob(px, py, R, 18), 0.0, 0.75, "pool_deep", chamfer=0.1, top="pool")
    used.append((px, py, R + 3))
    for k in range(10):
        a = math.radians(k * 36 + rng.uniform(-10, 10))
        rx_, ry_ = px + math.cos(a) * (R + 3), py + math.sin(a) * (R * 0.8 + 3)
        if clear_of_reach(rx_, ry_, 4):
            P.rock_cluster(sc, rx_, ry_, 0.4, rng.uniform(5, 9), rng.uniform(2, 7), grass=rng.random() < 0.5, n=1)
    for k in range(4):
        a = math.radians(rng.uniform(0, 360))
        P.coral(sc, px + math.cos(a) * R * 0.5, py + math.sin(a) * R * 0.4, 0.75, rng.uniform(0.7, 1.1))
    if deg in FALLS:
        ex, ey = polar(r_isl(deg) - 0.5, deg)
        wat.beam((px, py, 0.7), (ex, ey, 0.65), FALLS[deg] * 0.8, 0.3, "pool")  # the stream to the edge
        P.waterfall(wat, ex, ey, 0.6, -72, deg, width=FALLS[deg])
        note(f"Waterfall ({deg} deg)", ex, ey, "a pool spilling over the island edge")
note("Rock pools", 0, 0, "five turquoise pools in rock pockets round the edge (scenery, not playable)")

ARCH, CAVE, WRECK = 96, 194, 8
ax, ay = ring_pt(ARCH, 0.55)
while not clear_of_reach(ax, ay, 16):
    ax, ay = polar(math.hypot(ax - CENTER[0], ay - CENTER[1]) + 2, ARCH)
P.rock_arch(sc, ax, ay, 0.4, span=22, h=20, rot=ARCH - 90)
used.append((ax, ay, 20))
note("Rock arch", ax, ay, "a natural sea arch on the north rim")
cx_, cy_ = ring_pt(CAVE, 0.6)
while not clear_of_reach(cx_, cy_, 16):
    cx_, cy_ = polar(math.hypot(cx_ - CENTER[0], cy_ - CENTER[1]) + 2, CAVE)
P.rock_cluster(sc, cx_, cy_, 0.4, 26, 30, grass=True, n=5, rot=CAVE)
sc.disc_v(*polar(r_sand(CAVE) + 9, CAVE), 5.5, 7.0, 0.6, "black", rot=CAVE + 90, segs=20)
used.append((cx_, cy_, 22))
note("Coastal cave", cx_, cy_, "a cave mouth in the west cliff")
wx, wy = ring_pt(WRECK, 0.62)
while not clear_of_reach(wx, wy, 16):
    wx, wy = polar(math.hypot(wx - CENTER[0], wy - CENTER[1]) + 2, WRECK)
P.shipwreck(sc, wx, wy, 0.4, rot=WRECK + 70)
used.append((wx, wy, 20))
note("Shipwreck", wx, wy, "a broken hull beached on the east rocks")

# the cliffs + terraces: rock clusters all round the ring (taller north + west, lower south + east), never on the sand
for k in range(0, 360, 6):
    deg = k + rng.uniform(-2.5, 2.5)
    if abs((deg - SW + 180) % 360 - 180) < 13:
        continue  # (the spawn lobe stays open)
    for f in (0.25, 0.7) if ring_w(deg) > 30 else (0.5,):
        x, y = ring_pt(deg, f + rng.uniform(-0.12, 0.12))
        if not clear_of_reach(x, y, 8) or any(math.hypot(x - ux, y - uy) < ur for ux, uy, ur in used):
            continue
        north = math.sin(math.radians(deg))
        west = -math.cos(math.radians(deg))
        hmax = 8 + 16 * max(0.0, north) + 9 * max(0.0, west)
        if abs((deg - NE + 180) % 360 - 180) < 14:
            hmax = 14  # (the rocks framing the portal)
        h = rng.uniform(0.45, 1.0) * hmax
        top = P.rock_cluster(sc, x, y, 0.4, rng.uniform(9, 17), h, grass=True)
        if rng.random() < 0.4 and h > 9:  # (leaning inward: no fronds hanging off the rim)
            P.palm(veg, x + rng.uniform(-2, 2), y + rng.uniform(-2, 2), top, kind=rng.choice(("short", "tall")),
                   lean=math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-40, 40))
        used.append((x, y, 9))
# the rim wall: tall stacked cliffs along the outer edge (highest north + west, as in the concept), open where the
# waterfalls leave and at the spawn; lower behind the portal so it stays the landmark
for k in range(0, 360, 4):
    deg = k + rng.uniform(-1.5, 1.5)
    if abs((deg - SW + 180) % 360 - 180) < 18 or any(abs((deg - fd + 180) % 360 - 180) < 6 for fd in FALLS):
        continue
    x, y = polar(r_isl(deg) - rng.uniform(7, 11), deg)
    if not clear_of_reach(x, y, 10) or any(math.hypot(x - ux, y - uy) < ur * 0.6 for ux, uy, ur in used if ur > 12):
        continue
    north, west = math.sin(math.radians(deg)), -math.cos(math.radians(deg))
    h = 9 + 20 * max(0.0, north) + 12 * max(0.0, west) + rng.uniform(-3, 4)
    if abs((deg - NE + 180) % 360 - 180) < 16:
        h = min(h, 16)
    top = P.rock_cluster(sc, x, y, 0.4, rng.uniform(11, 16), h, grass=True)
    if rng.random() < 0.3 and h > 14:
        P.palm(veg, x, y, top, kind=rng.choice(("short", "tall")), lean=math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-30, 30))
# palm groves + ferns on the ring's grass (and a few leaning out over the sand edge, as in the concept)
palms = 0
tries = 0
while palms < 46 and tries < 3000:
    tries += 1
    deg = rng.uniform(0, 360)
    if abs((deg - SW + 180) % 360 - 180) < 10:
        continue
    x, y = ring_pt(deg, rng.uniform(-0.05, 0.9))
    if not clear_of_reach(x, y, 10) or any(math.hypot(x - ux, y - uy) < ur * 0.7 for ux, uy, ur in used):  # (fronds never over his lanes)
        continue
    P.palm(veg, x, y, 0.6 if not in_sand(x, y) else SAND_Z, lean=math.degrees(math.atan2(CENTER[1] - y, CENTER[0] - x)) + rng.uniform(-50, 50))
    if rng.random() < 0.5:
        P.fern_bush(veg, x + rng.uniform(-4, 4), y + rng.uniform(-4, 4), 0.6, rng.uniform(0.8, 1.3))
    used.append((x, y, 5))
    palms += 1
for k in range(4):  # palms by the spawn lobe + round the portal (only where they clear his reach)
    for (x, y, z, kind) in ((*polar(r_sand(SW) - 2, SW + (-16 if k % 2 else 16) + rng.uniform(-3, 3)), SAND_Z, "tall"),
                            (*polar(r_sand(NE) + 6, NE + (-22 if k % 2 else 22) + rng.uniform(-4, 4)), 0.6, rng.choice(("tall", "curve")))):
        if clear_of_reach(x, y, 10):
            P.palm(veg, x, y, z, kind=kind)
sc.done()
wat.done()
veg.done()

# ------------------------------------------------------------------ the sky: the sea far below, clouds, floating islets
sky = CL.ClassicMesh("Sky_Sea", C["OSV2_Sky"])
sky.cyl(0, 0, 4000, -330, -320, "sea", segs=64)
for k in range(16):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(330, 700), d, (0, 0))
    z = rng.uniform(-150, 60)
    for j in range(rng.randint(5, 9)):
        r = rng.uniform(10, 22)
        sky.sphere(x + rng.uniform(-26, 26), y + rng.uniform(-14, 14), z + rng.uniform(-4, 8), r, r * 0.8, r * 0.6, "white", seg=14, rings=8)
for k in range(7):
    d = rng.uniform(0, 360)
    x, y = polar(rng.uniform(300, 520), d, (0, 0))
    z = rng.uniform(-60, 40)
    s = rng.uniform(14, 26)
    sky.slab(blob(x, y, s, 10), z - 3, z, "dirt_rim", chamfer=0.4, top="moss")
    sky.rock(x, y, z - s * 1.4, s * 1.1, s * 0.9, s * 1.4 - 3, "rock_grey", rot=d, taper=-0.5)
    P.palm(sky, x, y, z, kind="short")
sky.done()

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
        scene.eevee.taa_render_samples = 32 if key == "aerial" else 16
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
