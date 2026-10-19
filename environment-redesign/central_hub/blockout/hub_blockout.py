# environment-redesign/central_hub/blockout/hub_blockout.py - STAGE 2: the central hub BLOCKOUT (2026-10-18).
# Dimensionally accurate, colour-coded volumes - not final art. Layout follows crnuch's approved reference
# (ChatGPT "Map Layout Overview": round floating island, spawn plaza + statue fountain in the middle, a main avenue up
# to the Law License Building, Travel Portal / Egg Incubator / Shop / Upgrades on an inner ring, firms on the outer
# ring, waterfalls off the cliffs) with the game's REAL numbers (environment-redesign/01_AUDIT.md):
#   8 plots (Workspace.Plots.Plot1-8), each 56 x 56 today; a fully expanded firm is 53 wide, ~141 deep from the
#   street-side steps (FirmBuilder: porch 6 + lobby 21 + 10 office segments x 11 + 3) and its Supreme Tower spire
#   tops out ~161 studs up (FirmStages FRONTS[6]). Lots here are 56 x 145 so a max firm fits with margin.
# 1 Blender m = 1 stud. Blender +Y = NORTH (the top of the layout render); Roblox (x, y, z) = (bx, bz, -by).
# Run headless:  /Applications/Blender.app/Contents/MacOS/Blender -b --python environment-redesign/central_hub/blockout/hub_blockout.py
# Writes: central_hub_blockout.blend, hub_layout.json (positions in Roblox coords) and renders/*.jpg.
import bpy, bmesh, json, math, os, random

HERE = os.path.dirname(os.path.abspath(__file__))
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
rng = random.Random(1218)
TAU = math.tau


def rad(deg):
    return math.radians(deg)


def polar(r, deg):
    return (r * math.cos(rad(deg)), r * math.sin(rad(deg)))


# ------------------------------------------------------------------ the plan (studs)
PLAZA_R = 58  # spawn plaza
INNER_ROAD = (62, 74)  # ring road round the plaza
SERVICE_R = 102  # centre line of the services ring
OUTER_ROAD = (130, 142)  # ring road every firm opens onto
LOT_FRONT = 148  # a lot starts here (its street edge) ...
LOT_W, LOT_D = 56, 145  # ... and runs outward
ISLAND_R = 332  # mean island radius, 317-347 with the wobble (lot corners stay >= 23 studs from the cliff)
PLOT_ANGLES = [60, 20, -20, -60, 240, 200, 160, 120]  # Plot1..8, clockwise from the north-east
AVENUE_W = 22

# max firm envelope in lot-local (x across, d outward from the lot's street edge), from FirmBuilder / FirmStages
FIRM = dict(
    porch=(0, 6), lobby=(6, 27, 24, 19.7 + 1.5),  # d0, d1, half-width, top
    tower=(8, 25, 20, 127.6 + 1.5), crown=(9, 24, 18, 133.6 + 1.5), spire=(-15, 21, 161.3),
    hall=(27, 141, 24, 8.5 + 1.5),
)

# ------------------------------------------------------------------ scene + collections
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"

TOP = ["Central_Hub", "Briefcase_Bay", "Pet_Park", "Brainrot_Zone", "Food_Court", "Ocean_Shore", "Space_Base",
       "Shared_Props", "Vegetation", "Buildings", "Environmental_Effects", "Lighting", "Presentation"]
COLS = {}
for n in TOP:
    c = bpy.data.collections.new(n)
    scene.collection.children.link(c)
    COLS[n] = c
for n in ["Hub_Island", "Hub_Plaza", "Hub_Roads", "Hub_Lots", "Hub_Firms_DYNAMIC", "Hub_Services", "Hub_Landscaping",
          "Hub_Water", "Hub_Labels"]:
    c = bpy.data.collections.new(n)
    COLS["Central_Hub"].children.link(c)
    COLS[n] = c

MATS = {}


def mat(name, rgb, emit=0.0, alpha=1.0):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    col = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255)
    lin = tuple(c ** 2.2 for c in col)
    m.diffuse_color = (*lin, alpha)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*lin, 1)
    bsdf.inputs["Roughness"].default_value = 0.65
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*lin, 1)
        bsdf.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            pass
    MATS[name] = m
    return m


M = dict(
    grass=mat("Grass_Hub", (124, 222, 52)), grass2=mat("Grass_Dark", (96, 196, 40)),
    dirt=mat("Dirt", (150, 96, 52)), rock=mat("Rock", (128, 122, 116)), rock2=mat("Rock_Dark", (96, 90, 86)),
    paving=mat("Paving_Stone", (214, 206, 190)), paving2=mat("Paving_Warm", (236, 214, 170)),
    road=mat("Road_Stone", (176, 172, 166)), path=mat("Path_Orange", (255, 160, 24)), curb=mat("Curb_White", (246, 242, 232)),
    lot=mat("Lot_Grass", (150, 230, 84)), lotedge=mat("Lot_Border", (246, 226, 180)),
    firm=mat("Firm_Envelope_DYNAMIC", (110, 130, 170)), firmhall=mat("Firm_Hall_DYNAMIC", (150, 166, 196)),
    glass=mat("Glass_Blue", (110, 190, 245)), gold=mat("Gold", (255, 200, 40)), cream=mat("Wall_Cream", (246, 226, 180)),
    white=mat("White", (240, 238, 232)), red=mat("Red", (226, 58, 58)), wood=mat("Wood", (214, 140, 70)),
    wooddark=mat("Wood_Dark", (122, 70, 34)), leaf=mat("Leaf", (70, 168, 34)), leaf2=mat("Leaf_Light", (110, 200, 60)),
    water=mat("Water", (60, 170, 240), alpha=0.92), portal=mat("Portal_Glow", (90, 200, 255), emit=3.0),
    egg=mat("Egg_Shell", (252, 236, 190)), eggspot=mat("Egg_Spot", (255, 190, 60)),
    purple=mat("Purple", (150, 90, 220)), navy=mat("Label_Plate", (28, 36, 70)), label=mat("Label_Text", (255, 255, 255), emit=0.6),
    flowers=[mat("Flower_Pink", (255, 120, 180)), mat("Flower_Yellow", (255, 220, 60)), mat("Flower_Red", (240, 70, 70)),
             mat("Flower_Purple", (170, 110, 240))],
    cloud=mat("Cloud", (250, 252, 255)), lamp=mat("Lamp_Post", (40, 40, 52)), lampglow=mat("Lamp_Glow", (255, 236, 160), emit=2.0),
    stripeR=mat("Awning_Red", (230, 50, 50)), stripeW=mat("Awning_White", (250, 250, 250)), bridge=mat("Bridge_Wood", (190, 120, 60)),
)


class Builder:
    """Many boxes / prisms into ONE mesh object (with material slots) - keeps the scene light."""

    def __init__(self, name, col):
        self.name, self.col = name, col
        self.bm = bmesh.new()
        self.mats = []

    def _mi(self, m):
        if m not in self.mats:
            self.mats.append(m)
        return self.mats.index(m)

    def prism(self, pts, z0, z1, m):
        """A vertical prism over a CCW polygon pts [(x, y)]."""
        mi = self._mi(m)
        bot = [self.bm.verts.new((x, y, z0)) for x, y in pts]
        top = [self.bm.verts.new((x, y, z1)) for x, y in pts]
        f = self.bm.faces.new(top)
        f.material_index = mi
        f = self.bm.faces.new(list(reversed(bot)))
        f.material_index = mi
        n = len(pts)
        for i in range(n):
            j = (i + 1) % n
            f = self.bm.faces.new((bot[i], bot[j], top[j], top[i]))
            f.material_index = mi

    def box(self, cx, cy, sx, sy, z0, z1, m, rot=0.0):
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        pts = []
        for px, py in ((-sx / 2, -sy / 2), (sx / 2, -sy / 2), (sx / 2, sy / 2), (-sx / 2, sy / 2)):
            pts.append((cx + px * c - py * s, cy + px * s + py * c))
        self.prism(pts, z0, z1, m)

    def cyl(self, cx, cy, r, z0, z1, m, segs=24):
        self.prism([(cx + r * math.cos(TAU * i / segs), cy + r * math.sin(TAU * i / segs)) for i in range(segs)], z0, z1, m)

    def ring(self, r0, r1, z0, z1, m, segs=96, a0=0.0, a1=360.0, cx=0.0, cy=0.0):
        """An annulus (or an arc of one)."""
        mi = self._mi(m)
        full = abs(a1 - a0) >= 359.99
        n = segs if full else max(2, int(segs * abs(a1 - a0) / 360) + 1)
        def pt(r, k):
            a = rad(a0 + (a1 - a0) * k / (n if full else n - 1))
            return (cx + r * math.cos(a), cy + r * math.sin(a))
        loops = []
        for r, z in ((r0, z0), (r1, z0), (r1, z1), (r0, z1)):
            loops.append([self.bm.verts.new((*pt(r, k), z)) for k in range(n)])
        rng_k = range(n) if full else range(n - 1)
        for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):
            for k in rng_k:
                j = (k + 1) % n
                f = self.bm.faces.new((loops[a][k], loops[a][j], loops[b][j], loops[b][k]))
                f.material_index = mi
        if not full:
            for k in (0, n - 1):
                f = self.bm.faces.new((loops[0][k], loops[1][k], loops[2][k], loops[3][k]))
                f.material_index = mi

    def cone(self, cx, cy, r, z0, z1, m, segs=8):
        mi = self._mi(m)
        base = [self.bm.verts.new((cx + r * math.cos(TAU * i / segs), cy + r * math.sin(TAU * i / segs), z0)) for i in range(segs)]
        tip = self.bm.verts.new((cx, cy, z1))
        for i in range(segs):
            f = self.bm.faces.new((base[i], base[(i + 1) % segs], tip) if z1 > z0 else (base[(i + 1) % segs], base[i], tip))
            f.material_index = mi

    def done(self):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(m)
        ob = bpy.data.objects.new(self.name, me)
        self.col.objects.link(ob)
        return ob


LAYOUT = {"units": "studs; Roblox coords (x, z) = (blender x, -blender y); north = -Z", "plots": [], "services": []}


def rbx(x, y):
    return [round(x, 1), round(-y, 1)]


# ------------------------------------------------------------------ the island
def island_r(deg):
    a = rad(deg)
    return ISLAND_R + 9 * math.sin(3 * a + 1.3) + 6 * math.sin(7 * a + 0.4) + 3 * math.sin(13 * a + 2.0)


isl = Builder("Island_Landmass", COLS["Hub_Island"])
N = 160
top = [(island_r(360 * i / N) * math.cos(TAU * i / N), island_r(360 * i / N) * math.sin(TAU * i / N)) for i in range(N)]
isl.prism(top, -3, 0, M["grass"])
isl.prism([(x * 0.996, y * 0.996) for x, y in top], -11, -3, M["dirt"])
# layered cliffs: tiers stepping in, each with its own jagged edge (blocky: radius snapped to 2-stud steps)
for k, (f, z0, z1, m) in enumerate(((0.95, -38, -11, M["rock"]), (0.82, -66, -38, M["rock2"]), (0.64, -96, -66, M["rock"]),
                                     (0.42, -124, -96, M["rock2"]), (0.2, -150, -124, M["rock"]))):
    pts = []
    for i in range(N):
        a = TAU * i / N
        r = island_r(360 * i / N) * f * (1 + 0.035 * math.sin(5 * a + k) + 0.02 * math.sin(11 * a + 2 * k))
        r = round(r / 2) * 2
        pts.append((r * math.cos(a), r * math.sin(a)))
    isl.prism(pts, z0, z1, m)
# hanging rock spikes under the tiers
for i in range(70):
    a = rng.uniform(0, 360)
    f = rng.uniform(0.2, 0.9)
    x, y = polar(island_r(a) * f, a)
    zt = -11 - (1 - f) * 150 * 0.95
    isl.cone(x, y, rng.uniform(5, 14), zt, zt - rng.uniform(14, 40), M["rock2"] if i % 2 else M["rock"], segs=6)
isl.done()

# ------------------------------------------------------------------ roads + plaza
roads = Builder("Roads", COLS["Hub_Roads"])
roads.ring(*INNER_ROAD, 0.0, 0.25, M["road"])
roads.ring(INNER_ROAD[0] - 1, INNER_ROAD[0], 0, 0.45, M["curb"])
roads.ring(INNER_ROAD[1], INNER_ROAD[1] + 1, 0, 0.45, M["curb"])
roads.ring(*OUTER_ROAD, 0.0, 0.25, M["road"], segs=160)
roads.ring(OUTER_ROAD[0] - 1, OUTER_ROAD[0], 0, 0.45, M["curb"], segs=160)
roads.ring(OUTER_ROAD[1], OUTER_ROAD[1] + 1, 0, 0.45, M["curb"], segs=160)
# main avenue: plaza -> north to the License Building, plaza -> south to the edge (Arcade bridge)
roads.box(0, (PLAZA_R + 150) / 2, AVENUE_W, 150 - PLAZA_R, 0, 0.3, M["paving2"])
roads.box(0, -(PLAZA_R + ISLAND_R) / 2, AVENUE_W, ISLAND_R - PLAZA_R, 0, 0.3, M["paving2"])
for sx in (-1, 1):
    roads.box(sx * (AVENUE_W / 2 + 0.5), (PLAZA_R + 150) / 2, 1, 150 - PLAZA_R, 0, 0.5, M["curb"])
    roads.box(sx * (AVENUE_W / 2 + 0.5), -(PLAZA_R + ISLAND_R) / 2, 1, ISLAND_R - PLAZA_R, 0, 0.5, M["curb"])
# spokes between the services: inner ring -> outer ring
for a in (22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5):
    r0, r1 = INNER_ROAD[1], OUTER_ROAD[0]
    cx, cy = polar((r0 + r1) / 2, a)
    roads.box(cx, cy, r1 - r0, 10, 0, 0.25, M["path"], rot=a)
roads.done()

plaza = Builder("Spawn_Plaza", COLS["Hub_Plaza"])
plaza.cyl(0, 0, PLAZA_R, 0, 0.35, M["paving"], segs=72)
plaza.ring(24, 30, 0.35, 0.45, M["paving2"], segs=64)
plaza.ring(44, 46, 0.35, 0.45, M["paving2"], segs=64)
for i in range(16):  # radiating paving pattern
    a = i * 22.5
    cx, cy = polar(37, a)
    plaza.box(cx, cy, 14, 1.2, 0.35, 0.45, M["paving2"], rot=a)
# statue fountain (the existing EggFountain's spot; reference: statue on a round blue basin)
plaza.ring(15, 18, 0.35, 3.2, M["white"], segs=48)
plaza.cyl(0, 0, 15, 0.35, 2.4, M["water"], segs=48)
plaza.cyl(0, 0, 5, 2.4, 6, M["white"], segs=16)
plaza.box(0, 0, 3.5, 2.2, 6, 13, M["rock"])  # statue figure (blockout)
plaza.box(0, 0, 2.2, 2.2, 13, 15.5, M["rock"])
# spawn pad (HubSpawn) on the south side, facing the fountain
plaza.box(0, -36, 14, 14, 0.35, 0.8, M["portal"])
# benches + lamps round the plaza
for i in range(12):
    a = i * 30 + 15
    cx, cy = polar(51, a)
    plaza.box(cx, cy, 6, 1.6, 0.35, 1.8, M["wood"], rot=a + 90)
    lx, ly = polar(55.5, a + 15)
    plaza.box(lx, ly, 0.8, 0.8, 0.35, 11, M["lamp"])
    plaza.box(lx, ly, 1.8, 1.8, 11, 12.6, M["lampglow"])
plaza.done()
LAYOUT["spawn"] = {"plaza_centre": rbx(0, 0), "plaza_radius": PLAZA_R, "spawn_pad": rbx(0, -36)}

# ------------------------------------------------------------------ the 8 lots + max firm envelopes (DYNAMIC)
lots = Builder("Lots", COLS["Hub_Lots"])
firms = Builder("Firm_Max_Envelopes_DYNAMIC", COLS["Hub_Firms_DYNAMIC"])
towers = Builder("Firm_Tower_Envelopes_DYNAMIC", COLS["Hub_Firms_DYNAMIC"])


def lot_point(a, x, d):
    """lot-local (x across, d outward from the street edge) -> world (bx, by)."""
    ox, oy = polar(LOT_FRONT + d, a)
    tx, ty = -math.sin(rad(a)), math.cos(rad(a))
    return ox + tx * x, oy + ty * x


def lot_box(b, a, x0, x1, d0, d1, z0, z1, m):
    cx, cy = lot_point(a, (x0 + x1) / 2, (d0 + d1) / 2)
    b.box(cx, cy, d1 - d0, x1 - x0, z0, z1, m, rot=a)


for i, a in enumerate(PLOT_ANGLES):
    lot_box(lots, a, -LOT_W / 2, LOT_W / 2, 0, LOT_D, 0, 0.6, M["lot"])
    for x0, x1, d0, d1 in ((-LOT_W / 2, -LOT_W / 2 + 1, 0, LOT_D), (LOT_W / 2 - 1, LOT_W / 2, 0, LOT_D), (-LOT_W / 2, LOT_W / 2, LOT_D - 1, LOT_D)):
        lot_box(lots, a, x0, x1, d0, d1, 0, 0.9, M["lotedge"])
    # forecourt from the ring road to the lot
    lot_box(lots, a, -9, 9, OUTER_ROAD[1] - LOT_FRONT, 0, 0, 0.3, M["paving2"])
    # the biggest firm the game can build (Supreme Tower, 10 office segments)
    d0, d1, hw, h = FIRM["lobby"]
    lot_box(firms, a, -hw, hw, d0, d1, 0.6, h, M["firm"])
    lot_box(firms, a, -FIRM["hall"][2], FIRM["hall"][2], FIRM["hall"][0], FIRM["hall"][1], 0.6, FIRM["hall"][3], M["firmhall"])
    lot_box(firms, a, -14, 14, -6 + 6, 6, 0.6, 1.6, M["white"])  # porch / steps
    d0, d1, hw, h = FIRM["tower"]
    lot_box(towers, a, -hw, hw, d0, d1, FIRM["lobby"][3], h, M["glass"])
    d0, d1, hw, h = FIRM["crown"]
    lot_box(towers, a, -hw, hw, d0, d1, FIRM["tower"][3], h, M["gold"])
    sx, sd, sh = FIRM["spire"]
    lot_box(towers, a, sx - 0.6, sx + 0.6, sd - 0.6, sd + 0.6, FIRM["crown"][3], sh, M["gold"])
    fx, fy = lot_point(a, 0, 0)
    bx, by = lot_point(a, 0, LOT_D)
    LAYOUT["plots"].append({
        "plot": f"Plot{i + 1}", "angle_deg_ccw_from_east": a,
        "street_edge_centre": rbx(fx, fy), "back_edge_centre": rbx(bx, by),
        "size": [LOT_W, LOT_D], "faces": "the hub centre",
        "roblox_yaw_deg": round((a + 90) % 360, 1),
    })
lots.done()
firms.done()
towers.done()

# ------------------------------------------------------------------ services (blockout volumes, reference positions)
svc = Builder("Services", COLS["Hub_Services"])


def at(r, a):
    return polar(r, a)


def service(name, r, a, note):
    x, y = at(r, a)
    LAYOUT["services"].append({"name": name, "centre": rbx(x, y), "radius": r, "angle_deg_ccw_from_east": a, "note": note})
    return x, y


# Law License Building - north end of the avenue, between Plot1 and Plot8 (reference: grand hall, gold, stairs)
lx, ly = service("Law License Building", 172, 90, "License / zone unlocks (today: Zones.LicenseOffice UpgradePrompt)")
svc.box(lx, ly + 4, 58, 40, 0, 4, M["white"])  # podium
for k in range(6):  # stairs down to the ring road
    svc.box(lx, ly - 16 - k * 1.6, 30, 1.6, 0, 4 - k * 0.66, M["white"])
svc.box(lx, ly + 8, 50, 30, 4, 24, M["cream"])
svc.box(lx, ly + 8, 54, 34, 24, 26, M["gold"])
svc.box(lx, ly + 10, 30, 20, 26, 36, M["cream"])
svc.cone(lx, ly + 10, 13, 36, 48, M["gold"], segs=16)
for k in range(6):
    svc.cyl(lx - 20 + k * 8, ly - 8, 1.4, 4, 24, M["white"], segs=10)
svc.box(lx, ly - 9, 40, 3, 24, 30, M["cream"])  # pediment band
# Travel Portal - inner ring NW, facing the plaza
px, py = service("Travel Portal", SERVICE_R, 135, "Hub.TravelPortal (Remotes.Travel); island destinations")
svc.cyl(px, py, 19, 0, 2.5, M["white"], segs=32)
svc.cyl(px, py, 15, 2.5, 4.5, M["purple"], segs=32)
for k in range(4):
    sx, sy = at(SERVICE_R - 19 - k * 2, 135)
    svc.box(sx, sy, 2, 18, 0, 2.4 - k * 0.6, M["white"], rot=135)
# ring standing upright, facing the plaza
ring_ob_center = (px, py)
# Egg Incubator - inner ring NE (reference: a giant egg in a cradle)
ex, ey = service("Egg Incubator (landmark)", SERVICE_R, 45, "Today eggs hatch in each firm's 2 incubators; this is a hub landmark - see audit")
svc.cyl(ex, ey, 17, 0, 3, M["white"], segs=32)
svc.ring(10, 14, 3, 9, M["gold"], segs=32, cx=ex, cy=ey)
# Shop - inner ring SW (reference: red/white striped awning)
sx_, sy_ = service("Shop", SERVICE_R, 225, "Hub.ShopStall + ShopSpot (Shop.client)")
svc.box(sx_, sy_, 28, 22, 0, 16, M["cream"], rot=225 + 90)
for k in range(6):
    ox, oy = at(SERVICE_R - 13, 225)
    tx, ty = -math.sin(rad(225)), math.cos(rad(225))
    off = -12.5 + k * 5
    svc.box(ox + tx * off, oy + ty * off, 6, 5, 10, 12, M["stripeR"] if k % 2 == 0 else M["stripeW"], rot=225)
svc.box(sx_, sy_, 30, 24, 16, 18, M["red"], rot=225 + 90)
# Upgrades - inner ring SE
ux, uy = service("Upgrades", SERVICE_R, 315, "Carry (briefcases) + Speed upgrades; today at the License Office")
svc.box(ux, uy, 28, 22, 0, 16, M["cream"], rot=315 + 90)
svc.box(ux, uy, 30, 24, 16, 18, M["navy"], rot=315 + 90)
svc.cone(ux, uy, 15, 18, 26, M["navy"], segs=4)
# Mutation Machine - inner ring W
mx, my = service("Mutation Machine", SERVICE_R, 180, "Hub.MergeMachine (Remotes.MergeSelected)")
svc.cyl(mx, my, 12, 0, 3, M["white"], segs=24)
svc.box(mx, my, 14, 14, 3, 17, M["purple"], rot=180)
svc.cyl(mx, my, 6, 17, 22, M["glass"], segs=16)
# Big Case belt + minigame pads - inner ring E
bxx, byy = service("Big Case belt + minigames", SERVICE_R, 0, "Hub.BigCaseBelt + SpecialSpots (Gavel Bonk, Lucky Briefcase)")
svc.box(bxx, byy, 34, 66, 0, 1.2, M["paving2"])
svc.box(bxx, byy, 8, 60, 1.2, 4, M["lamp"])
svc.cyl(bxx - 10, byy + 22, 7, 1.2, 2.2, M["gold"])
svc.cyl(bxx - 10, byy - 22, 7, 1.2, 2.2, M["gold"])
# Leaderboards - flanking the south avenue
for sgn in (-1, 1):
    x, y = sgn * 22, -88
    svc.box(x, y, 16, 2, 0, 16, M["navy"])
    svc.box(x, y, 17, 3, 16, 17.5, M["gold"])
service("Leaderboards", 88, 270, "Hub.Leaderboards (two boards either side of the avenue)")
svc.done()

# portal ring + egg as their own objects (round shapes)
bpy.ops.mesh.primitive_torus_add(major_radius=13, minor_radius=2.4, major_segments=48, minor_segments=12,
                                 location=(px, py, 18.5), rotation=(math.pi / 2, 0, rad(135 + 90)))
ring = bpy.context.active_object
ring.name = "TravelPortal_Ring"
ring.data.materials.append(M["portal"])
for c in ring.users_collection:
    c.objects.unlink(ring)
COLS["Hub_Services"].objects.link(ring)
bpy.ops.mesh.primitive_cylinder_add(radius=11, depth=0.6, vertices=48, location=(px, py, 18.5), rotation=(math.pi / 2, 0, rad(135 + 90)))
disc = bpy.context.active_object
disc.name = "TravelPortal_Field"
disc.data.materials.append(mat("Portal_Field", (120, 220, 255), emit=1.5, alpha=0.7))
for c in disc.users_collection:
    c.objects.unlink(disc)
COLS["Hub_Services"].objects.link(disc)
bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=24, ring_count=16, location=(ex, ey, 3 + 12))
egg = bpy.context.active_object
egg.name = "EggIncubator_Egg"
egg.scale = (9, 9, 12.5)
egg.data.materials.append(M["egg"])
for c in egg.users_collection:
    c.objects.unlink(egg)
COLS["Hub_Services"].objects.link(egg)

# ------------------------------------------------------------------ Arcade Pier (south, off the edge)
arc = Builder("Arcade_Pier", COLS["Hub_Services"])
south_edge = island_r(270)
arc.box(0, -(south_edge + 40), 18, 84, -1, 0.3, M["bridge"])  # bridge
for k in range(9):
    for sgn in (-1, 1):
        arc.box(sgn * 9.5, -(south_edge + 2 + k * 10), 1, 1, 0.3, 4, M["wooddark"])
pier_y = -(south_edge + 82 + 50)
arc.box(0, pier_y, 80, 100, -2, 0.4, M["wood"])
arc.prism([(x * 0.18, y * 0.18 + pier_y) for x, y in top], -18, -2, M["rock"])
arc.cone(0, pier_y, 18, -18, -60, M["rock2"], segs=8)
for k, (x, y) in enumerate(((-24, pier_y + 30), (24, pier_y + 30), (-24, pier_y - 10), (24, pier_y - 10))):
    arc.box(x, y, 16, 12, 0.4, 10, M["purple"] if k % 2 else M["stripeR"])
arc.done()
service("Arcade Pier", south_edge + 132, 270, "mr.robe's Arcade (booth games) - layout of booths TBD with that claim")

# ------------------------------------------------------------------ landscaping (trees, hedges, flowers) - kept off roads/lots/buildings
land = Builder("Landscaping", COLS["Hub_Landscaping"])


def blocked(x, y, pad=3.0):
    r = math.hypot(x, y)
    a = math.degrees(math.atan2(y, x)) % 360
    if r < PLAZA_R + pad or r > island_r(a) - 8:
        return True
    if INNER_ROAD[0] - pad < r < INNER_ROAD[1] + pad or OUTER_ROAD[0] - pad < r < OUTER_ROAD[1] + pad:
        return True
    if abs(x) < AVENUE_W / 2 + pad and (y < 0 or y < 200):
        return True
    for pa in PLOT_ANGLES:  # lots (+ forecourt)
        d = r * math.cos(rad(a - pa)) - LOT_FRONT
        lat = r * math.sin(rad(a - pa))
        if -12 < d < LOT_D + pad and abs(lat) < LOT_W / 2 + pad:
            return True
    for s in LAYOUT["services"]:
        sx, sy = s["centre"][0], -s["centre"][1]
        size = 40 if s["name"].startswith("Law") else (40 if s["name"].startswith("Big") else 22)
        if s["name"].startswith("Arcade"):
            continue
        if math.hypot(x - sx, y - sy) < size + pad:
            return True
    for sa in (22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5):  # spokes
        if INNER_ROAD[1] < r < OUTER_ROAD[0] and abs(r * math.sin(rad(a - sa))) < 5 + pad and math.cos(rad(a - sa)) > 0:
            return True
    return False


def tree(x, y, s):
    land.box(x, y, 1.6 * s, 1.6 * s, 0, 6 * s, M["wooddark"])
    land.box(x, y, 8 * s, 8 * s, 5 * s, 10.5 * s, M["leaf"] if rng.random() < 0.6 else M["leaf2"], rot=rng.uniform(0, 90))
    land.box(x, y, 5 * s, 5 * s, 10.5 * s, 14 * s, M["leaf2"], rot=rng.uniform(0, 90))


placed = 0
tries = 0
while placed < 260 and tries < 20000:
    tries += 1
    a = rng.uniform(0, 360)
    r = math.sqrt(rng.uniform(0, 1)) * (ISLAND_R - 6)
    x, y = polar(r, a)
    if blocked(x, y, 4):
        continue
    tree(x, y, rng.uniform(0.8, 1.35))
    placed += 1
# hedges along the outer road's inner edge (broken where spokes / avenue cross) + flower beds
for k in range(160):
    a = k * 360 / 160
    x, y = polar(OUTER_ROAD[0] - 3, a)
    if not any(abs(((a - sa + 180) % 360) - 180) < 4 for sa in (22.5, 67.5, 90, 112.5, 157.5, 202.5, 247.5, 270, 292.5, 337.5)):
        land.box(x, y, 2.4, 5.2, 0, 2.6, M["leaf"], rot=a)
flowers = 0
while flowers < 140:
    a = rng.uniform(0, 360)
    r = rng.uniform(INNER_ROAD[1] + 4, OUTER_ROAD[0] - 4)
    x, y = polar(r, a)
    if blocked(x, y, 2):
        continue
    land.box(x, y, rng.uniform(3, 6), rng.uniform(3, 6), 0, 0.9, M["flowers"][flowers % 4], rot=rng.uniform(0, 90))
    flowers += 1
# street lamps along the outer ring
for k in range(40):
    a = k * 9 + 4.5
    x, y = polar(OUTER_ROAD[1] + 2.5, a)
    if blocked(x, y, -2.5) and not (OUTER_ROAD[1] < math.hypot(x, y) < OUTER_ROAD[1] + 4):
        continue
    land.box(x, y, 0.8, 0.8, 0, 12, M["lamp"])
    land.box(x, y, 1.8, 1.8, 12, 13.6, M["lampglow"])
land.done()

# ------------------------------------------------------------------ water: ponds + waterfalls off the cliff, clouds, floating rocks
wat = Builder("Waterfalls", COLS["Hub_Water"])
for a in (190, 250, 290, 350):
    er = island_r(a)
    # a stream to the edge, a fall down the cliff tiers, a splash cloud
    cx, cy = polar(er - 16, a)
    wat.box(cx, cy, 30, 8, -0.2, 0.25, M["water"], rot=a)
    fx, fy = polar(er + 1.5, a)
    wat.box(fx, fy, 3, 12, -130, 0.2, M["water"], rot=a)
    gx, gy = polar(er - 34, a)
    wat.cyl(gx, gy, 9, -0.2, 0.25, M["water"], segs=20)
wat.done()
fx_ = Builder("Clouds_FloatingRocks", COLS["Hub_Water"])
for i in range(16):
    a = rng.uniform(0, 360)
    r = rng.uniform(380, 560)
    x, y = polar(r, a)
    z = rng.uniform(-170, 40)
    for j in range(rng.randint(3, 6)):
        fx_.box(x + rng.uniform(-30, 30), y + rng.uniform(-20, 20), rng.uniform(20, 46), rng.uniform(16, 34),
                z + rng.uniform(-4, 4), z + rng.uniform(8, 16), M["cloud"], rot=rng.uniform(0, 90))
for i in range(9):
    a = rng.uniform(0, 360)
    r = rng.uniform(370, 470)
    x, y = polar(r, a)
    z = rng.uniform(-60, 30)
    s = rng.uniform(8, 20)
    fx_.box(x, y, s * 1.6, s * 1.4, z, z + s * 0.5, M["grass"], rot=rng.uniform(0, 90))
    fx_.cone(x, y, s * 0.9, z, z - s * 1.8, M["rock2"], segs=6)
fx_.done()

# ------------------------------------------------------------------ labels (top-down layout only)
FONT = None
for p in ("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"):
    if os.path.exists(p):
        FONT = bpy.data.fonts.load(p)
        break
LBL_Z = 200


def label(text, x, y, size=9.0, plate=True):
    cu = bpy.data.curves.new("Label_" + text.replace(" ", "_")[:28], "FONT")
    cu.body = text
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size = size
    if FONT:
        cu.font = FONT
    ob = bpy.data.objects.new(cu.name, cu)
    ob.location = (x, y, LBL_Z + 1)
    cu.materials.append(M["label"])
    COLS["Hub_Labels"].objects.link(ob)
    if plate:
        lines = text.split("\n")
        w = max(len(s) for s in lines) * size * 0.62 + size
        h = len(lines) * size * 1.25 + size * 0.5
        b = Builder("Plate_" + cu.name, COLS["Hub_Labels"])
        b.box(x, y, w, h, LBL_Z - 0.5, LBL_Z, M["navy"])
        b.done()


label("SPAWN PLAZA\n(statue fountain)", 0, 0, 7)
label("SPAWN", 0, -36, 5)
for s in LAYOUT["services"]:
    x, y = s["centre"][0], -s["centre"][1]
    name = s["name"].replace(" (landmark)", "").replace(" + ", "\n+ ")
    label(name.upper() if len(name) < 18 else name, x, y, 7)
for p in LAYOUT["plots"]:
    a = p["angle_deg_ccw_from_east"]
    x, y = polar(LOT_FRONT + 60, a)
    label(f"{p['plot'].upper()}\nfirm lot 56 x 145", x, y, 7)
label("OUTER RING ROAD (firm frontage)", *polar(OUTER_ROAD[0] + 6, 101), 5)
label("INNER RING ROAD", *polar(INNER_ROAD[0] + 6, 101), 5)
label("MAIN AVENUE", 0, -230, 6)
label("WATERFALL", *polar(island_r(190) + 30, 190), 5)
label("WATERFALL", *polar(island_r(350) + 30, 350), 5)
# compass + 100-stud scale bar
label("N  ^", 0, ISLAND_R + 38, 10)
sb = Builder("ScaleBar", COLS["Hub_Labels"])
sb.box(-ISLAND_R + 50, -ISLAND_R - 120, 100, 2.5, LBL_Z, LBL_Z + 0.5, M["white"])
for k in range(5):
    sb.box(-ISLAND_R + k * 25, -ISLAND_R - 120, 1, 6, LBL_Z, LBL_Z + 0.6, M["white"])
sb.done()
label("100 studs", -ISLAND_R + 50, -ISLAND_R - 132, 7)

# a 5-stud player for scale, on the plaza
pl = Builder("Scale_Player_5studs", COLS["Hub_Plaza"])
pl.box(10, -30, 2, 1, 0.35, 2.4, M["navy"])
pl.box(10, -30, 2, 1, 2.4, 4.2, M["red"])
pl.box(10, -30, 1.2, 1.2, 4.2, 5.4, M["egg"])
pl.done()

# ------------------------------------------------------------------ lighting, world, cameras
world = bpy.data.worlds.new("Sky")
scene.world = world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.42, 0.66, 0.98, 1)
bg.inputs["Strength"].default_value = 1.0
sun_d = bpy.data.lights.new("Sun", "SUN")
sun_d.energy = 4.2
sun_d.angle = rad(3)
sun = bpy.data.objects.new("Sun", sun_d)
sun.rotation_euler = (rad(48), rad(10), rad(-35))
COLS["Lighting"].objects.link(sun)


def camera(name, loc, look, lens=35, ortho=None):
    cd = bpy.data.cameras.new(name)
    cd.clip_end = 6000
    if ortho:
        cd.type = "ORTHO"
        cd.ortho_scale = ortho
    else:
        cd.lens = lens
    ob = bpy.data.objects.new(name, cd)
    ob.location = loc
    import mathutils
    d = mathutils.Vector(look) - mathutils.Vector(loc)
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    COLS["Presentation"].objects.link(ob)
    return ob


cam_aerial = camera("Cam_Aerial", (-330, -930, 640), (0, 30, -40), lens=36)
cam_ground = camera("Cam_Ground_Plaza_to_License", (0, -50, 9), (0, 172, 20), lens=24)
# portrait, framing the island (+ the north label) down to the end of the Arcade Pier
cam_top = camera("Cam_TopDown_Layout", (0, 0, 900), (0, 0, 0), ortho=930)
cam_top.rotation_euler = (0, 0, 0)
cam_top.location = (0, -80, 900)


def render(cam, path, w, h, engine, labels):
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = w, h
    scene.render.resolution_percentage = 100
    COLS["Hub_Labels"].hide_render = not labels
    # the layout is a plan: no clouds over it, no tower shadows across it
    bpy.data.objects["Clouds_FloatingRocks"].hide_render = labels
    world.color = (0.62, 0.78, 0.95)
    try:
        scene.render.engine = engine
    except TypeError as e:
        print("[hub] engine", engine, "not available:", e)
        scene.render.engine = "BLENDER_WORKBENCH"
    if scene.render.engine == "BLENDER_WORKBENCH":
        sh = scene.display.shading
        sh.light = "STUDIO"
        sh.color_type = "MATERIAL"
        sh.show_cavity = True
        sh.show_shadows = not labels
    else:
        try:
            scene.eevee.taa_render_samples = 32
        except Exception:
            pass
    scene.view_settings.view_transform = "Standard"
    scene.render.image_settings.file_format = "JPEG"  # (no Git LFS in this repo: JPEG keeps renders ~1-2 MB)
    scene.render.image_settings.quality = 92
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("[hub] rendered", path)


bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "central_hub_blockout.blend"), compress=True)
with open(os.path.join(HERE, "hub_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print("[hub] saved .blend + hub_layout.json")

import sys
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "norender" not in argv:
    eng = "BLENDER_EEVEE_NEXT"
    try:
        scene.render.engine = eng
    except TypeError:
        eng = "BLENDER_EEVEE"
    render(cam_aerial, os.path.join(RENDERS, "hub_blockout_aerial.jpg"), 2400, 1350, eng, labels=False)
    render(cam_ground, os.path.join(RENDERS, "hub_blockout_ground_plaza.jpg"), 1920, 1080, eng, labels=False)
    render(cam_top, os.path.join(RENDERS, "hub_blockout_layout_topdown.jpg"), 2160, 2700, "BLENDER_WORKBENCH", labels=True)
