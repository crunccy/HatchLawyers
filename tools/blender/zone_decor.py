# tools/blender/zone_decor.py - builds the egg-zone decoration set in Blender out of chunky blocks (the game's brick
# style: every block becomes a studded Part in Studio), renders a preview, and exports the blocks as JSON for
# tools/zones/BuildDecorLibrary.lua. Run inside Blender (tools/blender/send.ps1 -File tools/blender/zone_decor.py).
# Works in its own scene "ZoneDecor" and never touches the other scenes of the open file.
# Units: 1 Blender m = 1 stud, Z up; models stand on z = 0 at their origin. Colours are the game palette (CLAUDE.md).
import bpy, math, random, json, os

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
OUT_JSON = os.path.join(REPO, "tools", "zones", "decor_library.json")
OUT_PNG = os.path.join(REPO, "art", "zone_decor", "preview.png")

# ------------------------------------------------------------------ scene + a shared unit cube
sc = bpy.data.scenes.get("ZoneDecor") or bpy.data.scenes.new("ZoneDecor")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("ZoneDecor")
if coll is None:
    coll = bpy.data.collections.new("ZoneDecor")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)

me = bpy.data.meshes.get("ZD_Cube")
if me is None:
    me = bpy.data.meshes.new("ZD_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

def rgb(r, g, b):
    return (r, g, b)

PAL = dict(
    trunk=rgb(122, 70, 34), trunk2=rgb(100, 58, 28), leaf=rgb(70, 168, 34), leaf2=rgb(96, 196, 40),
    leaf3=rgb(58, 150, 30), leaf4=rgb(124, 206, 60), leafTop=rgb(150, 222, 82), pink=rgb(255, 120, 190),
    yellow=rgb(255, 214, 60), white=rgb(248, 248, 248), red=rgb(230, 50, 50), orange=rgb(255, 160, 24),
    purple=rgb(150, 80, 230), sky=rgb(120, 200, 255), rock=rgb(150, 150, 160), rock2=rgb(120, 122, 134),
    rock3=rgb(176, 176, 186), soil=rgb(110, 70, 40), terracotta=rgb(200, 100, 90), card=rgb(200, 160, 100),
    card2=rgb(176, 136, 84), ink=rgb(40, 40, 52), steel=rgb(160, 165, 175), water=rgb(120, 190, 255),
    wood=rgb(214, 140, 70), woodDark=rgb(122, 70, 34), bone=rgb(245, 240, 225), tennis=rgb(206, 240, 60),
    gold=rgb(255, 200, 40), cream=rgb(246, 226, 180),
)

def box(P, name, cx, cy, z0, sx, sy, sz, col, rz=0.0, rx=0.0, ry=0.0, tag=None):
    """A block whose bottom sits at z0 (centre cx, cy), turned rz/rx/ry degrees."""
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    if tag:
        o["tag"] = tag
    coll.objects.link(o)
    o.parent = P
    return o

MODELS = {}  # name -> (theme, builder)
def model(name, theme):
    def deco(fn):
        MODELS[name] = (theme, fn)
        return fn
    return deco

# ------------------------------------------------------------------ nature (all zones)
def make_tree(P, seed, size, greens=None, top=None):
    """A brick tree like the reference's: a visible trunk that forks into 2-3 stepped branches, each ending in its
    own chunky clump of near-cube leaf blocks (a lively, gappy silhouette - not one flat cap)."""
    r = random.Random(seed)
    greens = greens or [PAL["leaf"], PAL["leaf2"], PAL["leaf3"], PAL["leaf4"]]
    top = top or PAL["leafTop"]
    w = 1.6 * size
    box(P, "Root", 0, 0, 0, w * 1.7, w * 1.7, 0.6 * size, PAL["trunk2"])
    for a in (0, 180):  # little root feet
        rad = math.radians(a + r.uniform(-20, 20))
        box(P, "RootFoot", math.cos(rad) * w * 0.9, math.sin(rad) * w * 0.9, 0, 0.8 * size, 0.8 * size, 0.9 * size, PAL["trunk2"], rz=a)
    fork = r.uniform(4.0, 5.2) * size
    box(P, "Trunk", 0, 0, 0, w, w, fork * 0.55, PAL["trunk"])
    jx, jy = r.choice([-0.3, 0.3]) * size, r.choice([-0.3, 0.3]) * size
    box(P, "Trunk", jx, jy, fork * 0.55, w * 0.9, w * 0.9, fork * 0.45 + 0.1, PAL["trunk"])
    n = r.choice([2, 3, 3])
    base = r.uniform(0, 360)
    for b in range(n):
        ang = math.radians(base + b * 360 / n + r.uniform(-25, 25))
        bx, by, bz = jx, jy, fork - 0.2 * size
        steps = r.randint(3, 4)
        for st in range(steps):  # each step: out and up, like a brick staircase
            bx += math.cos(ang) * 0.9 * size
            by += math.sin(ang) * 0.9 * size
            box(P, "Branch", bx, by, bz, 0.9 * size, 0.9 * size, 1.0 * size, PAL["trunk"])
            bz += 0.85 * size
        # the leaf clump: near-cube blocks around the branch tip, darker underneath, a light cap on top
        cx, cy, cz = bx, by, bz + 0.6 * size
        for k in range(r.randint(4, 6)):  # (kept lean: every block is a Part on a phone)
            e = r.uniform(2.6, 3.8) * size
            ox, oy = r.uniform(-1.6, 1.6) * size, r.uniform(-1.6, 1.6) * size
            oz = r.uniform(-0.6, 1.8) * size
            shade = greens[2] if oz < 0.4 * size else r.choice(greens)
            box(P, "Leaves", cx + ox, cy + oy, cz + oz, e, e * r.uniform(0.85, 1.15), e * r.uniform(0.8, 1.0), shade, rz=r.choice([0, 0, 20, -20]))
        box(P, "LeavesTop", cx + r.uniform(-0.5, 0.5) * size, cy + r.uniform(-0.5, 0.5) * size, cz + 3.0 * size, 2.4 * size, 2.4 * size, 1.4 * size, top)
    # a small centre clump so the fork isn't bare from below
    box(P, "Leaves", jx, jy, fork + 1.2 * size, 2.6 * size, 2.6 * size, 2.2 * size, greens[0])

for i, (sz, nm) in enumerate([(0.8, "TreeS"), (1.05, "TreeM"), (1.3, "TreeL"), (1.6, "TreeXL")]):
    def _b(P, sz=sz, i=i):
        make_tree(P, 100 + i, sz)
    MODELS[nm] = ("nature", _b)

@model("TreeBlossom", "nature")
def _(P):
    make_tree(P, 7, 1.15, greens=[PAL["pink"], rgb(255, 150, 205), rgb(240, 100, 170)], top=rgb(255, 200, 225))

def make_bush(P, seed, flowers):
    r = random.Random(seed)
    for k in range(r.randint(4, 6)):
        sx, sy, sz = r.uniform(1.8, 3.2), r.uniform(1.8, 3.2), r.uniform(1.4, 2.4)
        box(P, "Bush", r.uniform(-1.2, 1.2), r.uniform(-1.2, 1.2), 0, sx, sy, sz, r.choice([PAL["leaf"], PAL["leaf2"], PAL["leaf3"]]))
    for k in range(flowers):
        col = r.choice([PAL["pink"], PAL["yellow"], PAL["white"], PAL["purple"]])
        box(P, "Flower", r.uniform(-1.6, 1.6), r.uniform(-1.6, 1.6), r.uniform(1.6, 2.4), 0.6, 0.6, 0.6, col, tag="nocollide")

@model("Bush", "nature")
def _(P):
    make_bush(P, 21, 0)

@model("BushFlowers", "nature")
def _(P):
    make_bush(P, 22, 7)

@model("FlowerBed", "nature")
def _(P):
    r = random.Random(31)
    box(P, "Frame", 0, 0, 0, 7, 3.4, 1.0, PAL["woodDark"])
    box(P, "Soil", 0, 0, 1.0, 6.4, 2.8, 0.2, PAL["soil"])
    for ix in range(6):
        for iy in range(2):
            x, y = -2.7 + ix * 1.08, -0.6 + iy * 1.2
            hgt = r.uniform(0.6, 1.2)
            box(P, "Stem", x, y, 1.2, 0.25, 0.25, hgt, PAL["leaf3"], tag="nocollide")
            box(P, "Bloom", x, y, 1.2 + hgt, 0.7, 0.7, 0.55, r.choice([PAL["pink"], PAL["yellow"], PAL["red"], PAL["purple"], PAL["white"]]), tag="nocollide")

@model("Rocks", "nature")
def _(P):
    r = random.Random(41)
    for k in range(4):
        s = r.uniform(1.4, 3.0)
        box(P, "Rock", r.uniform(-1.5, 1.5), r.uniform(-1.5, 1.5), 0, s * 1.3, s, s * 0.8, r.choice([PAL["rock"], PAL["rock2"], PAL["rock3"]]), rz=r.uniform(0, 60))
    box(P, "Moss", 0.3, 0.2, 1.6, 1.4, 1.2, 0.3, PAL["leaf2"], tag="nocollide")

@model("GrassTuft", "nature")
def _(P):
    r = random.Random(51)
    for k in range(5):
        box(P, "Blade", r.uniform(-0.5, 0.5), r.uniform(-0.5, 0.5), 0, 0.3, 0.3, r.uniform(0.8, 1.6), r.choice([PAL["leaf"], PAL["leaf2"], PAL["leaf4"]]),
            rx=r.uniform(-25, 25), ry=r.uniform(-25, 25), tag="nocollide")

# ------------------------------------------------------------------ Briefcase Bay (office park)
@model("OfficePlant", "office")
def _(P):
    box(P, "Pot", 0, 0, 0, 2.2, 2.2, 1.8, PAL["white"])
    box(P, "PotRim", 0, 0, 1.8, 2.6, 2.6, 0.4, PAL["white"])
    box(P, "PotBand", 0, 0, 0.6, 2.25, 2.25, 0.35, PAL["terracotta"])
    box(P, "Soil", 0, 0, 2.2, 2.2, 2.2, 0.1, PAL["soil"])
    for k in range(7):  # a fan of chunky leaves
        a = k * (360 / 7)
        rad = math.radians(a)
        box(P, "Leaf", math.cos(rad) * 0.9, math.sin(rad) * 0.9, 2.2, 0.7, 0.25, 3.4, PAL["leaf2"] if k % 2 else PAL["leaf"],
            rz=a, ry=28, tag="nocollide")
    box(P, "Heart", 0, 0, 2.2, 0.8, 0.8, 3.6, PAL["leaf3"], tag="nocollide")

@model("FileBoxes", "office")
def _(P):
    r = random.Random(61)
    z = 0.0
    x = y = 0.0
    for k in range(4):
        h = 2.4
        rz = r.uniform(-14, 14)
        col = PAL["card"] if k % 2 == 0 else PAL["card2"]
        box(P, "FileBox", x, y, z, 3.6, 2.8, h, col, rz=rz)
        box(P, "Lid", x, y, z + h - 0.45, 3.8, 3.0, 0.5, PAL["card2"] if k % 2 == 0 else PAL["card"], rz=rz)
        box(P, "Label", x, y - 1.42, z + 0.9, 1.6, 0.06, 0.8, PAL["white"], rz=rz, tag="nocollide")
        z += h
        x += r.uniform(-0.35, 0.35)
        y += r.uniform(-0.35, 0.35)
    box(P, "LooseBox", 3.0, 1.0, 0, 2.6, 2.0, 1.8, PAL["card"], rz=30)
    box(P, "LoosePapers", -2.4, 1.2, 0, 1.6, 2.2, 0.3, PAL["white"], rz=-20, tag="nocollide")

@model("WaterCooler", "office")
def _(P):
    box(P, "Body", 0, 0, 0, 2.2, 2.2, 3.8, PAL["white"])
    box(P, "Panel", 0, -1.12, 1.6, 1.6, 0.06, 1.6, PAL["steel"], tag="nocollide")
    box(P, "TapHot", -0.4, -1.2, 2.6, 0.4, 0.3, 0.4, PAL["red"], tag="nocollide")
    box(P, "TapCold", 0.4, -1.2, 2.6, 0.4, 0.3, 0.4, PAL["sky"], tag="nocollide")
    box(P, "Neck", 0, 0, 3.8, 1.0, 1.0, 0.4, PAL["water"], tag="glass")
    box(P, "Jug", 0, 0, 4.2, 1.9, 1.9, 2.3, PAL["water"], tag="glass")
    box(P, "Cups", 1.4, 0, 1.8, 0.6, 0.6, 1.4, PAL["white"])

@model("ParkBench", "office")
def _(P):
    for x in (-2.2, 2.2):
        box(P, "Leg", x, 0, 0, 0.5, 2.2, 1.6, PAL["ink"])
        box(P, "BackLeg", x, 0.9, 1.6, 0.5, 0.4, 2.0, PAL["ink"])
    for k in range(3):
        box(P, "Seat", 0, -0.7 + k * 0.7, 1.6, 6.0, 0.6, 0.3, PAL["wood"])
    for k in range(2):
        box(P, "Back", 0, 1.05, 2.3 + k * 0.8, 6.0, 0.3, 0.5, PAL["wood"], rx=-10)

@model("FlowerHedge", "office")
def _(P):
    r = random.Random(71)
    box(P, "Hedge", 0, 0, 0, 9, 2.6, 2.8, PAL["leaf3"])
    box(P, "HedgeTop", 0, 0, 2.8, 8.4, 2.0, 0.6, PAL["leaf2"])
    for k in range(9):
        box(P, "Flower", -4 + k, r.uniform(-0.8, 0.8), 3.2, 0.6, 0.6, 0.5, r.choice([PAL["pink"], PAL["white"], PAL["yellow"]]), tag="nocollide")

# ------------------------------------------------------------------ Pet Park
def voxel_ball(P, name, x, y, z0, d, col):
    box(P, name, x, y, z0 + d * 0.15, d * 0.7, d * 0.7, d * 0.7, col)
    box(P, name, x, y, z0, d * 0.45, d * 0.45, d, col)
    box(P, name, x, y, z0 + d * 0.275, d, d * 0.45, d * 0.45, col)
    box(P, name, x, y, z0 + d * 0.275, d * 0.45, d, d * 0.45, col)

@model("DogHouse", "pets")
def _(P):
    walls = random.Random(81).choice([PAL["sky"], PAL["yellow"], PAL["cream"]])
    box(P, "Floor", 0, 0, 0, 6.4, 6.4, 0.5, PAL["woodDark"])
    box(P, "Walls", 0, 0, 0.5, 5.6, 5.6, 4.0, walls)
    for k in range(4):  # stepped gable roof
        box(P, "Roof", 0, 0, 4.5 + k * 0.8, 6.6 - k * 1.7, 6.8, 0.8, PAL["red"] if k % 2 == 0 else rgb(205, 40, 40))
    box(P, "Door", 0, -2.82, 0.5, 2.2, 0.1, 2.6, PAL["ink"], tag="nocollide")
    box(P, "DoorTop", 0, -2.82, 3.1, 1.4, 0.1, 0.5, PAL["ink"], tag="nocollide")
    box(P, "NamePlate", 0, -2.86, 3.7, 2.4, 0.08, 0.6, PAL["white"], tag="nocollide")
    box(P, "Bowl", 2.0, -4.2, 0, 1.6, 1.6, 0.6, PAL["red"])
    box(P, "Kibble", 2.0, -4.2, 0.6, 1.2, 1.2, 0.15, PAL["soil"], tag="nocollide")

def bone(P, x, y, z0, rz, s=1.0):
    rad = math.radians(rz)
    box(P, "Bone", x, y, z0, 4.2 * s, 1.0 * s, 1.0 * s, PAL["bone"], rz=rz)
    for d in (-2.1, 2.1):
        for e in (-0.5, 0.5):
            cx = x + math.cos(rad) * d * s - math.sin(rad) * e * s
            cy = y + math.sin(rad) * d * s + math.cos(rad) * e * s
            box(P, "Knob", cx, cy, z0 - 0.1 * s, 1.2 * s, 1.2 * s, 1.2 * s, PAL["bone"], rz=rz)

@model("BonePile", "pets")
def _(P):
    bone(P, 0, 0, 0, 20, 1.2)
    bone(P, 0.6, 0.4, 1.1, -40, 1.0)
    bone(P, -1.2, 1.4, 0, 75, 0.9)

@model("ToyPile", "pets")
def _(P):
    voxel_ball(P, "Ball", 0, 0, 0, 2.2, PAL["tennis"])
    voxel_ball(P, "Ball", 2.1, 0.6, 0, 1.8, PAL["red"])
    voxel_ball(P, "Ball", -1.6, 1.4, 0, 1.6, PAL["sky"])
    voxel_ball(P, "Ball", 0.8, 0.9, 1.7, 1.5, PAL["pink"])
    for k in range(6):  # a rope toy in stripes
        box(P, "Rope", -2.6 + k * 0.7, -2.0, 0, 0.7, 0.7, 0.7, PAL["white"] if k % 2 else PAL["orange"], rz=10)

@model("Hydrant", "pets")
def _(P):
    box(P, "Base", 0, 0, 0, 2.4, 2.4, 0.5, rgb(200, 40, 40))
    box(P, "Body", 0, 0, 0.5, 1.8, 1.8, 3.0, PAL["red"])
    box(P, "Band", 0, 0, 2.6, 2.1, 2.1, 0.4, PAL["gold"])
    box(P, "Cap", 0, 0, 3.5, 1.4, 1.4, 0.7, PAL["red"])
    box(P, "Top", 0, 0, 4.2, 0.6, 0.6, 0.4, PAL["gold"])
    box(P, "Nozzles", 0, 0, 1.8, 3.0, 0.8, 0.8, PAL["gold"])
    box(P, "Front", 0, -1.0, 1.7, 0.9, 0.6, 0.9, PAL["gold"])

# ------------------------------------------------------------------ build all models in a preview grid
roots = {}
col_per_row = 6
for i, (name, (theme, fn)) in enumerate(MODELS.items()):
    P = bpy.data.objects.new(name, None)
    P.empty_display_size = 1
    coll.objects.link(P)
    P.location = ((i % col_per_row) * 16.0, -(i // col_per_row) * 18.0, 0)
    P["theme"] = theme
    fn(P)
    roots[name] = P

# ------------------------------------------------------------------ export the blocks for Studio (Roblox: Y up, -Z forward)
def to_rbx_vec(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]

data = {}
for name, P in roots.items():
    parts = []
    for o in P.children:
        # read location / rotation straight from the properties: matrix_local isn't updated until the scene is
        # evaluated, and this scene never is (that exported every block at the origin once)
        loc = o.location
        rot = o.rotation_euler.to_matrix()
        # R_rbx = M R M^T with M mapping (x, y, z) -> (x, z, -y); the box's Blender Y size becomes its Roblox Z size
        Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
        R = [[rot[i][j] for j in range(3)] for i in range(3)]
        MR = [[sum(Mx[i][k] * R[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
        Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
        s = o.scale
        parts.append(dict(n=o.name.split(".")[0], p=to_rbx_vec(loc), s=[round(abs(s[0]), 3), round(abs(s[2]), 3), round(abs(s[1]), 3)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o.get("tag", "")))
    data[name] = dict(theme=P["theme"], parts=parts)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))

# ------------------------------------------------------------------ preview render (Workbench, object colours, outlines)
cam_data = bpy.data.cameras.get("ZD_Cam") or bpy.data.cameras.new("ZD_Cam")
cam = bpy.data.objects.new("ZD_Cam", cam_data)
coll.objects.link(cam)
rows = (len(MODELS) + col_per_row - 1) // col_per_row
cx, cy = (col_per_row - 1) * 16.0 / 2, -(rows - 1) * 18.0 / 2
cam.location = (cx + 52, cy - 96, 74)
dx, dy, dz = cx - cam.location[0], cy - cam.location[1], 2 - cam.location[2]
cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
cam_data.lens = 36
sc.view_settings.view_transform = "Standard"  # show the palette as-is (the default transform washes it out)
sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.display.shading.show_shadows = True
sc.render.resolution_x = 1600
sc.render.resolution_y = 1000
sc.render.film_transparent = False
sc.world = sc.world or bpy.data.worlds.new("ZD_World")
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
result = f"{len(MODELS)} models, {sum(len(d['parts']) for d in data.values())} blocks -> {OUT_JSON}; preview {OUT_PNG}"
print(result)
