# tools/blender/arcade_pier.py - the ARCADE PIER (2026-10-13, mr.robe's session; user's call: build the minigames in
# docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md). The hub's land ends at z = 168 (north); past it is the sea, so the
# arcade is a wooden boardwalk pier sticking out over the water, booths down both sides facing the middle walkway.
# Built out of chunky blocks (every block becomes a studded Part in Studio), rendered for review, exported as JSON for
# tools/zones/BuildArcadePier.lua.
# Booth slots: 4 down each side; the Phase A games fill them in order (BOOTHS below); the far end stays free for the
# bigger games (Courthouse Obby, Objection! stage ...).
# Names the game looks up: each booth is a group "booth:<GameId>" (the builder makes a Model tagged ArcadeStation with
# attribute ArcadeGame); in it "Screen" (gets the Board SurfaceGui: title + status), "Marquee" (the game's name),
# "PlayZone" (invisible, gets the PlayPrompt). The entrance arch's "ArchSign" gets "ARCADE PIER".
# Run: "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools/blender/arcade_pier.py
# Units: 1 Blender m = 1 stud, Z up. The pier's entrance is at the origin and it runs along Blender +Y; the builder
# turns it so it runs north (Roblox +Z) from the shore.
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    try:
        here = os.path.dirname(os.path.abspath(__file__))
        return os.path.abspath(os.path.join(here, "..", ".."))
    except NameError:
        return r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "arcade_pier.json")
OUT_PNG = os.path.join(REPO, "art", "arcade", "pier.png")
OUT_PNG2 = os.path.join(REPO, "art", "arcade", "pier_walk.png")

sc = bpy.data.scenes.get("ArcadePier") or bpy.data.scenes.new("ArcadePier")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("ArcadePier") or bpy.data.collections.new("ArcadePier")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("AP_Cube")
if me is None:
    me = bpy.data.meshes.new("AP_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

def rgb(r, g, b):
    return (r, g, b)

PAL = dict(
    woodL=rgb(214, 140, 70), woodD=rgb(122, 70, 34), woodM=rgb(176, 108, 52), white=rgb(246, 244, 236), cream=rgb(246, 226, 180),
    ink=rgb(30, 32, 46), gold=rgb(255, 200, 40), red=rgb(229, 57, 53), steel=rgb(150, 160, 182), rope=rgb(220, 200, 150),
    bulb=rgb(255, 236, 150), pink=rgb(255, 120, 200), sky=rgb(90, 200, 255),
)
# the Phase A games, in booth order (left side front -> back, then right side front -> back)
BOOTHS = [
    ("LieDetector", "Lie Detector", rgb(70, 200, 120)),
    ("BriefcaseStack", "Briefcase Stack", rgb(255, 160, 24)),
    ("FilingFrenzy", "Filing Frenzy", rgb(60, 160, 255)),
]

ROOT = bpy.data.objects.new("ArcadePier", None)
coll.objects.link(ROOT)

def box(name, cx, cy, z0, sx, sy, sz, col, rz=0.0, tag="", group="pier", alpha=0.0, fn=None, rx=0.0, ry=0.0):
    """A block whose bottom sits at z0 (centre cx, cy). fn = the outward normal (Blender) of the face a SurfaceGui goes on."""
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    o["tag"] = tag
    o["group"] = group
    o["alpha"] = alpha
    o["fn"] = list(fn) if fn else []
    coll.objects.link(o)
    o.parent = ROOT
    return o

W, LEN = 70.0, 100.0  # pier width (x -35..35) and length (y 0..LEN)
DECK = 0.0  # deck top (= the hub's ground)

# ------------------------------------------------------------------ the deck: planks across, alternating woods, + beams
y = 0.0
k = 0
while y < LEN:
    box("Deck", 0, y + 2, DECK - 1, W, 4, 1, PAL["woodL"] if k % 2 == 0 else PAL["woodM"])
    y += 4
    k += 1
for x in (-W / 2 + 1, 0.0, W / 2 - 1):  # long beams under the planks (seen from the water)
    box("Beam", x, LEN / 2, DECK - 2.2, 2, LEN, 1.2, PAL["woodD"])
for yy in range(6, int(LEN), 16):  # posts down into the sea
    for x in (-W / 2 + 1, W / 2 - 1):
        box("Post", x, yy, DECK - 7, 2.2, 2.2, 6, PAL["woodD"])

# ------------------------------------------------------------------ railings (sides + the far end), posts with gold caps
def rail_run(x0, y0, x1, y1):
    L = math.hypot(x1 - x0, y1 - y0)
    n = max(1, int(L / 6))
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    for i in range(n + 1):
        t = i / n
        px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        box("RailPost", px, py, DECK, 1.2, 1.2, 4, PAL["white"])
        box("RailCap", px, py, DECK + 4, 1.5, 1.5, 0.5, PAL["gold"])
    box("Rail", (x0 + x1) / 2, (y0 + y1) / 2, DECK + 3.2, L, 0.6, 0.6, PAL["white"], rz=ang)
    box("Rail", (x0 + x1) / 2, (y0 + y1) / 2, DECK + 1.6, L, 0.5, 0.5, PAL["white"], rz=ang)
rail_run(-W / 2 + 0.6, 4, -W / 2 + 0.6, LEN - 0.6)
rail_run(W / 2 - 0.6, 4, W / 2 - 0.6, LEN - 0.6)
rail_run(-W / 2 + 0.6, LEN - 0.6, W / 2 - 0.6, LEN - 0.6)

# ------------------------------------------------------------------ the entrance arch with its sign + bulbs
for side in (-1, 1):
    x = side * 12
    box("ArchLeg", x, 2, DECK, 3, 3, 16, PAL["red"])
    for zz in (4, 8, 12):
        box("ArchBand", x, 2, DECK + zz, 3.4, 3.4, 0.6, PAL["white"])
    box("ArchCap", x, 2, DECK + 16, 4, 4, 1, PAL["gold"])
box("ArchTop", 0, 2, DECK + 16, 27, 3, 2, PAL["red"])
box("ArchSign", 0, 0.3, DECK + 17.6, 20, 0.4, 4.4, PAL["ink"], fn=(0, -1, 0))  # "ARCADE PIER" (builder)
box("ArchSignBack", 0, 0.7, DECK + 17.3, 21, 0.6, 5, PAL["gold"])
for i in range(14):  # bulbs round the sign
    t = i / 13
    box("Bulb", -10.3 + 20.6 * t, 0.15, DECK + 22.4, 0.6, 0.6, 0.6, PAL["bulb"] if i % 2 == 0 else PAL["pink"], tag="neon")
    box("Bulb", -10.3 + 20.6 * t, 0.15, DECK + 16.9, 0.6, 0.6, 0.6, PAL["pink"] if i % 2 == 0 else PAL["bulb"], tag="neon")

# ------------------------------------------------------------------ lamp posts down the walkway + string lights
LAMPS = [(side * 10, yy) for yy in (14, 34, 54, 74, 92) for side in (-1, 1)]
for (x, yy) in LAMPS:
    box("LampPost", x, yy, DECK, 0.9, 0.9, 9, PAL["ink"])
    box("LampArm", x, yy, DECK + 9, 2.4, 0.6, 0.5, PAL["ink"])
    box("Lamp", x, yy, DECK + 9.5, 1.6, 1.6, 1.6, PAL["bulb"], tag="neon")
for side in (-1, 1):  # bulbs strung between the lamps, sagging a little
    for a, b in zip([l for l in LAMPS if l[0] == side * 10][:-1], [l for l in LAMPS if l[0] == side * 10][1:]):
        for i in range(1, 7):
            t = i / 7
            sag = math.sin(t * math.pi) * 1.4
            box("StringBulb", side * 10, a[1] + (b[1] - a[1]) * t, DECK + 9.2 - sag, 0.5, 0.5, 0.5,
                [PAL["bulb"], PAL["pink"], PAL["sky"]][i % 3], tag="neon")

# ------------------------------------------------------------------ booths
def booth(gid, name, col, side, yy):
    """A booth on the `side` (-1 left, +1 right) at y = yy, its counter facing the walkway (x = 0)."""
    g = "booth:" + gid
    face = -side  # the walkway is towards -side
    cx = side * 26.5  # booth centre
    front = cx + face * 5.5  # the counter's front plane
    back = cx - face * 4.5
    # floor platform
    box("BoothFloor", cx, yy, DECK, 12, 14, 0.4, PAL["cream"], group=g)
    # side walls (game colour) + back wall (white) + roof
    for s in (-1, 1):
        box("BoothWall", cx, yy + s * 6.5, DECK + 0.4, 10, 1, 9, col, group=g)
    box("BoothBack", back, yy, DECK + 0.4, 1, 14, 10, PAL["white"], group=g)
    # the board (status screen) on the back wall, facing the walkway
    box("Screen", back + face * 0.65, yy, DECK + 4.2, 0.3, 9, 4.6, PAL["ink"], group=g, fn=(face, 0, 0))
    box("ScreenFrame", back + face * 0.55, yy, DECK + 3.9, 0.3, 9.8, 5.2, PAL["gold"], group=g)
    # counter with a wood top
    box("Counter", front - face * 0.9, yy, DECK + 0.4, 1.8, 12, 3.4, col, group=g)
    box("CounterTop", front - face * 0.9, yy, DECK + 3.8, 2.4, 12.6, 0.5, PAL["woodL"], group=g)
    box("CounterStripe", front + face * 0.02, yy, DECK + 1.6, 0.2, 12, 0.6, PAL["white"], group=g)
    # striped awning (sloping down to the front) + marquee with bulbs
    for i in range(7):
        stripe = col if i % 2 == 0 else PAL["white"]
        box("Awning", cx + face * 1.0, yy - 6 + (i + 0.5) * (14 / 7), DECK + 10.6, 13, 14 / 7 + 0.02, 0.5, stripe,
            ry=face * 12, group=g)
    box("AwningFringe", front + face * 1.2, yy, DECK + 9.6, 0.4, 14.4, 0.8, PAL["gold"], group=g)
    box("Marquee", front + face * 0.6, yy, DECK + 11.6, 0.5, 11, 2.8, PAL["ink"], group=g, fn=(face, 0, 0))
    box("MarqueeBack", front + face * 0.35, yy, DECK + 11.3, 0.5, 11.8, 3.4, col, group=g)
    for i in range(10):
        t = i / 9
        for zz in (11.1, 14.6):
            box("Bulb", front + face * 0.9, yy - 5.6 + 11.2 * t, DECK + zz, 0.45, 0.45, 0.45,
                PAL["bulb"] if (i + int(zz)) % 2 == 0 else PAL["pink"], tag="neon", group=g)
    # where you stand to play (invisible; the builder puts the PlayPrompt on it)
    box("PlayZone", front + face * 2.5, yy, DECK, 4, 6, 5, PAL["white"], tag="prompt", group=g)
    # the game's prop on the counter
    top = DECK + 4.3
    px = front - face * 0.9
    if gid == "LieDetector":  # a polygraph: a box, a paper roll, a swinging needle, a lamp
        box("Prop", px, yy - 2, top, 1.8, 3.2, 1.4, PAL["steel"], group=g)
        box("Prop", px, yy - 2, top + 1.4, 1.2, 2.6, 0.5, PAL["white"], group=g)
        box("Prop", px + face * 0.3, yy - 2, top + 1.2, 0.2, 0.2, 1.6, PAL["red"], rx=25, group=g)
        box("PropLamp", px, yy + 2.5, top, 0.8, 0.8, 1.6, PAL["ink"], group=g)
        box("PropLamp", px, yy + 2.5, top + 1.6, 1.2, 1.2, 0.8, PAL["bulb"], tag="neon", group=g)
    elif gid == "BriefcaseStack":  # a little tower of briefcases
        for i, c in enumerate((rgb(150, 90, 50), rgb(55, 55, 68), rgb(200, 64, 64), rgb(52, 74, 150))):
            box("Prop", px + (i % 2) * 0.2, yy - 1.5 + (i % 2) * 0.4, top + i * 0.9, 1.6, 3.4 - i * 0.3, 0.9, c, group=g)
        box("Prop", px, yy - 1.3, top + 3.6, 0.3, 1.0, 0.3, PAL["woodD"], group=g)
    elif gid == "FilingFrenzy":  # a mini conveyor with papers + three coloured bins
        box("Prop", px, yy - 1.5, top, 1.6, 6, 0.5, PAL["ink"], group=g)
        for i in range(3):
            box("Prop", px, yy - 3.5 + i * 2, top + 0.5, 1.0, 1.2, 0.1, PAL["white"], group=g)
        for i, c in enumerate((PAL["red"], rgb(79, 203, 46), rgb(60, 150, 240))):
            box("Prop", px, yy + 2.6 + (i - 1) * 1.6, top, 1.4, 1.3, 1.2, c, group=g)

SLOTS = [(-1, 22), (1, 22), (-1, 42), (1, 42), (-1, 62), (1, 62), (-1, 82), (1, 82)]  # (alternating sides, front first)
for (gid, name, col), (side, yy) in zip(BOOTHS, SLOTS):
    booth(gid, name, col, side, yy)

# ------------------------------------------------------------------ export (Roblox: Y up; the builder turns the pier to face north)
def to_rbx_vec(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]

Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
parts = []
for o in ROOT.children:
    loc, rot = o.location, o.rotation_euler.to_matrix()
    R3 = [[rot[i][j] for j in range(3)] for i in range(3)]
    MR = [[sum(Mx[i][k] * R3[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
    s = o.scale
    fn = list(o["fn"])
    parts.append(dict(n=o.name.split(".")[0], p=to_rbx_vec(loc), s=[round(abs(s[0]), 3), round(abs(s[2]), 3), round(abs(s[1]), 3)],
                      r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"], g=o["group"],
                      a=round(o["alpha"], 2), fn=to_rbx_vec(fn) if fn else None))
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(size=[W, 26, LEN], booths=[dict(id=b[0], name=b[1], color=list(b[2])) for b in BOOTHS], parts=parts), fh, separators=(",", ":"))

# ------------------------------------------------------------------ renders (review)
mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"])
    if key in mats:
        return mats[key]
    m = bpy.data.materials.new("AP_%d" % len(mats))
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = 0.55
    if o["tag"] == "neon":
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = 1.4
    mats[key] = m
    return m
if not me.materials:
    me.materials.append(None)
for o in ROOT.children:
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = material_for(o)
    if o["tag"] == "prompt":
        o.hide_render = True
# the sea, for the review shot only
sea = bpy.data.objects.new("Sea", me)
sea.scale = (400, 400, 1)
sea.location = (0, 50, -3)
coll.objects.link(sea)
seam = bpy.data.materials.new("AP_Sea")
seam.use_nodes = True
seam.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.15, 0.66, 1, 1)
sea.material_slots[0].link = "OBJECT"
sea.material_slots[0].material = seam

sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_EEVEE"
sc.eevee.taa_render_samples = 24
world = sc.world or bpy.data.worlds.new("AP_World")
sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.78, 1, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
sun_data = bpy.data.lights.get("AP_Sun") or bpy.data.lights.new("AP_Sun", "SUN")
sun_data.energy = 2.6
sun = bpy.data.objects.new("AP_Sun", sun_data)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
coll.objects.link(sun)
cam_data = bpy.data.cameras.get("AP_Cam") or bpy.data.cameras.new("AP_Cam")
cam = bpy.data.objects.new("AP_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam

def look(at, frm):
    cam.location = frm
    dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
    cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)

cam_data.lens = 30
sc.render.resolution_x, sc.render.resolution_y = 1500, 1000
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
look((0, 50, 0), (60, -45, 55))
sc.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True, scene=sc.name)
look((-20, 30, 6), (6, 4, 7))  # walking in: the left booths
sc.render.filepath = OUT_PNG2
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"ArcadePier: {len(parts)} blocks -> {OUT_JSON}; renders {OUT_PNG}, {OUT_PNG2}")
