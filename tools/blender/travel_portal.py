# tools/blender/travel_portal.py - the hub's TRAVEL PORTAL, built in Blender out of chunky blocks (every block becomes
# a Part in Studio), rendered for review, and exported as JSON for tools/zones/BuildTravelPortal.lua.
# v1 2026-10-13 (crnuch's cloud session, user's pick "A": one portal + a travel map instead of six teleport pads): a
#    courthouse doorway with a round portal.
# v2 2026-10-13 (mr.robe: "change the teleporters to look way cooler, make the models in blender ... use the reference
#    images"; mr.robe's call: keep crnuch's one portal + map, restyle it). The references: a white tiered round stage
#    under a huge glowing halo (1), a glowing iridescent green vortex tunnel (2), a teleporter pad with glowing rings and
#    a matching emitter ring above it, light + mist between (3). So: a three-step round platform with glowing stripes,
#    a dark pad with glowing rings and a teal / mint vortex in the middle (the swirl lies flat now), a translucent light
#    column up to a floating HALO emitter (concentric glowing rings underneath, a chunky white-and-gold rim, the six zone
#    gems on its front), held by two pylons, and the TRAVEL sign floating over it.
# Names the game looks up (keep them): Gem1-6 (lane order, lit per player), SwirlArm (-> the SwirlArms model, spun about
# the swirl disc's axis), SwirlDisc / SwirlCore (particles), SignPlate ("TRAVEL"), Trigger (walk-in box), Beam (the
# light column, pulsed by StarterPlayerScripts.Travel), HaloCore (the emitter's centre, flares on a trip).
# Run: "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools/blender/travel_portal.py
#   (or tools/blender/send.ps1 -File ..., or headless python with `pip install bpy==5.2.2`).
# Units: 1 Blender m = 1 stud, Z up, the portal's FRONT faces Blender -Y (Roblox +Z after export); it stands on z = 0.
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    try:
        here = os.path.dirname(os.path.abspath(__file__))
        return os.path.abspath(os.path.join(here, "..", ".."))
    except NameError:  # (run from Blender's text editor / send.ps1: no __file__)
        return r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "travel_portal.json")
OUT_PNG = os.path.join(REPO, "art", "travel", "portal.png")
OUT_PNG_LOW = os.path.join(REPO, "art", "travel", "portal_under.png")

# ------------------------------------------------------------------ scene + shared meshes
sc = bpy.data.scenes.get("TravelPortal") or bpy.data.scenes.new("TravelPortal")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("TravelPortal") or bpy.data.collections.new("TravelPortal")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("TP_Cube")
if me is None:
    me = bpy.data.meshes.new("TP_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

# a unit cylinder along X (Roblox's Cylinder shape runs along its X axis too): length 1, diameter 1
cyl_me = bpy.data.meshes.get("TP_Cyl")
if cyl_me is None:
    cyl_me = bpy.data.meshes.new("TP_Cyl")
    n = 48
    v = [(x, 0.5 * math.cos(2 * math.pi * i / n), 0.5 * math.sin(2 * math.pi * i / n)) for x in (-0.5, 0.5) for i in range(n)]
    f = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    cyl_me.from_pydata(v, [], f)
    cyl_me.update()

def rgb(r, g, b):
    return (r, g, b)

PAL = dict(
    white=rgb(238, 242, 250), white2=rgb(212, 218, 232), steel=rgb(150, 160, 182), navy=rgb(36, 42, 72), navy2=rgb(52, 60, 96),
    ink=rgb(30, 32, 46), gold=rgb(255, 200, 40), goldDark=rgb(217, 154, 16),
    cyan=rgb(90, 230, 255), violet=rgb(170, 110, 255), core=rgb(250, 252, 255),
    swirl1=rgb(30, 190, 160), swirl2=rgb(110, 255, 200), swirl3=rgb(190, 255, 240),
)
# the six zones in lane order (Config.Zones.List[i].Color)
ZONE_COLORS = [rgb(104, 152, 236), rgb(120, 196, 50), rgb(170, 80, 210), rgb(240, 84, 74), rgb(70, 160, 225), rgb(80, 70, 160)]

ROOT = bpy.data.objects.new("TravelPortal", None)
coll.objects.link(ROOT)

def box(name, cx, cy, z0, sx, sy, sz, col, rx=0.0, ry=0.0, rz=0.0, tag="", alpha=0.0, mesh=None, shape=""):
    """A block whose bottom sits at z0 (centre cx, cy), turned rx / ry / rz degrees about its centre.
    alpha = its Transparency in Studio; shape "cyl" = a Cylinder part (mesh along X)."""
    o = bpy.data.objects.new(name, mesh or me)
    o["alpha"] = alpha
    o["shape"] = shape
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    o["tag"] = tag
    coll.objects.link(o)
    o.parent = ROOT
    return o

def vdisc(name, cx, cy, z0, d, h, col, tag="", alpha=0.0):
    """A round disc / drum lying flat: diameter d, height h, its bottom at z0 (a Cylinder part stood on end)."""
    o = box(name, cx, cy, 0, h, d, d, col, ry=90, tag=tag, alpha=alpha, mesh=cyl_me, shape="cyl")
    o.location = (cx, cy, z0 + h / 2)
    return o

def ring_of_blocks(name, r, z0, n, size, cols, tag="", start=0.0, span=360.0, height=None):
    """n blocks round a circle of radius r (centres), each turned to face out."""
    for i in range(n):
        a = math.radians(start + (i + 0.5) / n * span)
        col = cols[i % len(cols)]
        box(name, math.cos(a) * r, math.sin(a) * r, z0, size[0], size[1], height or size[2], col, rz=math.degrees(a), tag=tag)

# ------------------------------------------------------------------ the base: three round steps with glowing stripes (ref 1)
vdisc("Step", 0, 0, 0.0, 30.0, 1.0, PAL["white2"])
vdisc("StepGlow", 0, 0, 0.35, 30.35, 0.32, PAL["cyan"], tag="neon")
vdisc("Step", 0, 0, 1.0, 24.0, 1.0, PAL["white"])
vdisc("StepGlow", 0, 0, 1.35, 24.35, 0.32, PAL["violet"], tag="neon")
vdisc("Step", 0, 0, 2.0, 18.0, 0.8, PAL["white2"])
vdisc("StepGlow", 0, 0, 2.25, 18.35, 0.3, PAL["cyan"], tag="neon")
FLOOR = 2.8
# little lamp posts round the lowest step (front half), glowing tops
for k, deg in enumerate((205, 235, 265 + 10, 305, 335)):
    a = math.radians(deg)
    x, y = math.cos(a) * 13.6, math.sin(a) * 13.6
    box("Bollard", x, y, 1.0, 0.9, 0.9, 1.6, PAL["steel"])
    box("BollardLamp", x, y, 2.6, 0.7, 0.7, 0.6, PAL["cyan"] if k % 2 == 0 else PAL["violet"], tag="neon")

# ------------------------------------------------------------------ the pad: glowing rings + the vortex (refs 3 + 2)
# layered discs, biggest lowest, each a hair higher, so every ring shows as a band (no z-fighting)
z = FLOOR
layers = [
    (16.6, PAL["navy"], ""), (15.8, PAL["cyan"], "neon"), (15.0, PAL["navy2"], ""), (13.2, PAL["violet"], "neon"),
    (12.6, PAL["navy"], ""),
]
for d, col, tag in layers:
    vdisc("PadRing" if tag else "Pad", 0, 0, z, d, 0.08, col, tag=tag)
    z += 0.06
PAD_TOP = z + 0.02
# the vortex: a ForceField disc (Studio animates its shimmer), translucent glowing layers, a bright core
vdisc("SwirlDisc", 0, 0, PAD_TOP - 0.06, 12.0, 0.1, PAL["swirl1"], tag="field")
vdisc("SwirlGlow", 0, 0, PAD_TOP - 0.02, 9.0, 0.06, PAL["swirl2"], tag="neon", alpha=0.45)
vdisc("SwirlGlow", 0, 0, PAD_TOP + 0.02, 5.6, 0.06, PAL["swirl3"], tag="neon", alpha=0.35)
vdisc("SwirlCore", 0, 0, PAD_TOP + 0.06, 2.2, 0.06, PAL["core"], tag="neon", alpha=0.1)
# three spiral arms of small glowing blocks lying on the pad: the client spins them (a smooth disc spinning doesn't show)
for arm in range(3):
    for k in range(7):
        t = k / 6
        ang = arm * 2 * math.pi / 3 + t * 2.6
        rad = 1.0 + t * 4.6
        size = 0.45 + 0.6 * t
        box("SwirlArm", math.cos(ang) * rad, math.sin(ang) * rad, PAD_TOP + 0.1, size * 1.5, size, 0.12,
            PAL["swirl3"] if k % 2 == 0 else PAL["swirl2"], rz=math.degrees(ang) + 70, tag="neon", alpha=0.25 + 0.4 * t)

# ------------------------------------------------------------------ the light column + mist (ref 3)
HALO_Z = 20.0  # the halo's underside
vdisc("Beam", 0, 0, PAD_TOP + 0.2, 9.0, HALO_Z - PAD_TOP - 0.4, PAL["cyan"], tag="neon", alpha=0.86)
vdisc("BeamCore", 0, 0, PAD_TOP + 0.2, 3.6, HALO_Z - PAD_TOP - 0.4, PAL["core"], tag="neon", alpha=0.8)
# three rings of glowing blocks floating round the column (FloatRing1-3: the builder makes each a model, the client
# turns them - alternate ways - and bobs them)
for k, (zr, r, n, col) in enumerate(((7.5, 6.2, 22, PAL["cyan"]), (11.5, 5.6, 20, PAL["violet"]), (15.5, 6.2, 22, PAL["cyan"]))):
    for i in range(n):
        a = math.radians((i + 0.5) / n * 360 + k * 7)
        box("FloatRing%d" % (k + 1), math.cos(a) * r, math.sin(a) * r, zr, 1.15, 0.45, 0.35, col, rz=math.degrees(a) + 90, tag="neon")

# ------------------------------------------------------------------ the halo emitter (refs 1 + 3)
# underneath, seen from below: lowest layer = the centre; each layer above shows as a ring round it
z = HALO_Z
under = [  # (diameter, colour, tag), bottom-most first
    (6.0, PAL["core"], "neon"), (8.6, PAL["navy"], ""), (10.4, PAL["violet"], "neon"), (13.0, PAL["navy2"], ""),
    (14.8, PAL["cyan"], "neon"),
]
for i, (d, col, tag) in enumerate(under):
    vdisc("HaloCore" if i == 0 else ("HaloRing" if tag else "HaloUnder"), 0, 0, z, d, 0.1, col, tag=tag)
    z += 0.08
vdisc("Halo", 0, 0, z, 17.0, 1.5, PAL["white"])
HALO_TOP = z + 1.5
# a chunky white-and-gold rim round it, and a glowing stripe round its side (inside the body, so from below it only
# shows as a thin ring past the rim - a full disc under the rim would hide the rings underneath)
ring_of_blocks("HaloRim", 8.9, HALO_Z - 0.3, 28, (1.7, 1.5, 2.3), [PAL["white"], PAL["gold"]])
vdisc("HaloBand", 0, 0, HALO_TOP - 0.9, 18.6, 0.35, PAL["violet"], tag="neon")
# the dome on top + a beacon
vdisc("HaloDome", 0, 0, HALO_TOP, 11.0, 0.9, PAL["white2"])
vdisc("HaloDome", 0, 0, HALO_TOP + 0.9, 6.4, 0.8, PAL["white"])
vdisc("HaloDomeGlow", 0, 0, HALO_TOP + 0.6, 11.3, 0.25, PAL["violet"], tag="neon")
vdisc("Beacon", 0, 0, HALO_TOP + 1.7, 2.0, 0.9, PAL["core"], tag="neon")
# the six zone gems across the front of the rim, lane order left to right (the client lights the ones you can use)
for k in range(6):
    a = math.radians(-150 + k * 24)  # front = -Y: angles round -90 degrees
    x, y = math.cos(a) * 9.95, math.sin(a) * 9.95
    box("Gem%d" % (k + 1), x, y, HALO_Z + 0.25, 1.35, 1.35, 1.35, ZONE_COLORS[k], rx=45, rz=math.degrees(a), tag="neon")

# ------------------------------------------------------------------ two pylons holding the halo (back left / right)
for side in (-1, 1):
    px, py = side * 11.2, 7.6
    box("PylonFoot", px, py, 1.0, 3.6, 3.6, 0.8, PAL["steel"])
    zz = 1.8
    k = 0
    while zz < HALO_Z + 1.0:
        box("Pylon", px, py, zz, 2.6, 2.6, 1.6, PAL["white"] if k % 2 == 0 else PAL["white2"])
        zz += 1.6
        k += 1
    # a glowing strip down the inner face, gold caps
    ix, iy = px - side * 1.35, py - 0.0
    box("PylonGlow", ix, iy, 2.2, 0.2, 0.9, HALO_Z - 2.6, PAL["cyan"], tag="neon")
    box("PylonCap", px, py, zz, 3.2, 3.2, 0.7, PAL["gold"])
    # the arm over to the halo rim
    tx, ty = side * 7.2, 4.6
    dx, dy = tx - px, ty - py
    L = math.hypot(dx, dy)
    box("PylonArm", (px + tx) / 2, (py + ty) / 2, HALO_Z + 0.2, L + 1.0, 1.8, 1.4, PAL["white2"], rz=math.degrees(math.atan2(dy, dx)))
    box("PylonArmGlow", (px + tx) / 2, (py + ty) / 2, HALO_Z + 0.05, L, 0.5, 0.2, PAL["violet"], rz=math.degrees(math.atan2(dy, dx)), tag="neon")

# ------------------------------------------------------------------ the TRAVEL sign floating over the halo's front
SIGN_Z = HALO_TOP + 2.2
box("SignPost", -4.2, -2.0, HALO_TOP, 0.5, 0.5, 2.4, PAL["steel"])
box("SignPost", 4.2, -2.0, HALO_TOP, 0.5, 0.5, 2.4, PAL["steel"])
box("SignBack", 0, -2.0, SIGN_Z - 0.15, 12.6, 0.6, 2.9, PAL["white"])
box("SignPlate", 0, -2.4, SIGN_Z, 12.0, 0.25, 2.6, PAL["ink"])  # the builder writes "TRAVEL" on its front
box("SignGlow", 0, -2.33, SIGN_Z - 0.3, 12.9, 0.2, 0.25, PAL["cyan"], tag="neon")
box("SignGlow", 0, -2.33, SIGN_Z + 2.65, 12.9, 0.2, 0.25, PAL["cyan"], tag="neon")

# walking onto the pad opens the travel map (invisible, no collision)
box("Trigger", 0, 0, PAD_TOP, 8.0, 8.0, 7.0, PAL["core"], tag="trigger")

# ------------------------------------------------------------------ export the blocks for Studio (Roblox: Y up, -Z forward)
def to_rbx_vec(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]

Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
parts = []
for o in ROOT.children:
    if o.get("preview"):
        continue
    loc, rot = o.location, o.rotation_euler.to_matrix()
    R3 = [[rot[i][j] for j in range(3)] for i in range(3)]
    MR = [[sum(Mx[i][k] * R3[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
    s = o.scale
    parts.append(dict(n=o.name.split(".")[0], p=to_rbx_vec(loc), s=[round(abs(s[0]), 3), round(abs(s[2]), 3), round(abs(s[1]), 3)],
                      r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"],
                      a=round(o["alpha"], 2), shape=o["shape"]))
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(front="+Z", size=[30, round(SIGN_Z + 3.0, 2), 30], parts=parts), fh, separators=(",", ":"))

# ------------------------------------------------------------------ renders
# sparkles + mist for the review shots only (the game uses Shared.Effects particles instead)
import random
rnd = random.Random(7)
for i in range(70):
    a, rad = rnd.uniform(0, 2 * math.pi), rnd.uniform(0.5, 5.5)
    sp = box("Sparkle", math.cos(a) * rad, math.sin(a) * rad, rnd.uniform(PAD_TOP + 0.5, HALO_Z - 1), 0.22, 0.22, 0.22,
             rnd.choice([PAL["core"], PAL["swirl2"], PAL["cyan"]]), rx=45, ry=45, tag="neon")
    sp["preview"] = True

mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"], round(o["alpha"], 2))
    if key in mats:
        return mats[key]
    m = bpy.data.materials.new("TP_%d" % len(mats))
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = 0.5
    alpha = 1 - o["alpha"]
    if o["tag"] in ("neon", "field"):
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = 1.6 if o["tag"] == "neon" else 0.6
        if o["tag"] == "field":
            alpha = 0.7  # (Studio's ForceField is see-through on its own)
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1:
        m.surface_render_method = "BLENDED"
    mats[key] = m
    return m
for mesh in (me, cyl_me):  # the shared meshes get one material slot; each object fills it (link = OBJECT)
    if not mesh.materials:
        mesh.materials.append(None)
for o in ROOT.children:
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = material_for(o)

sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_EEVEE"
sc.eevee.taa_render_samples = 32
try:
    sc.eevee.use_bloom = True  # (older EEVEE; 5.x does glow through the compositor and ignores this)
except AttributeError:
    pass
world = sc.world or bpy.data.worlds.new("TP_World")
sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.62, 0.86, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
sun_data = bpy.data.lights.get("TP_Sun") or bpy.data.lights.new("TP_Sun", "SUN")
sun_data.energy = 2.4
sun = bpy.data.objects.new("TP_Sun", sun_data)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
coll.objects.link(sun)
cam_data = bpy.data.cameras.get("TP_Cam") or bpy.data.cameras.new("TP_Cam")
cam = bpy.data.objects.new("TP_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam
for o in ROOT.children:
    if o.name.startswith("Trigger"):
        o.hide_render = True

def look(at, frm):
    cam.location = frm
    dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
    cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)

cam_data.type = "PERSP"
cam_data.lens = 32
sc.render.resolution_x, sc.render.resolution_y = 1400, 1100
sc.render.film_transparent = False
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
# 1) the review shot: three-quarter front view, a little above eye height
look((0, 0, 11), (26, -46, 16))
sc.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True, scene=sc.name)
# 2) standing on the pad's edge looking up into the halo (what a player sees from the pad)
look((0, 0, HALO_Z - 2), (8, -15, 5))
sc.render.filepath = OUT_PNG_LOW
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"TravelPortal v2: {len(parts)} blocks -> {OUT_JSON}; renders {OUT_PNG}, {OUT_PNG_LOW}")
