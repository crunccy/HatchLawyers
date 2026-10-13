# tools/blender/travel_portal.py - the hub's TRAVEL PORTAL (2026-10-13, user's pick "A": one portal + a travel map
# instead of six teleport pads). Built in Blender out of chunky blocks (every block becomes a studded Part in Studio),
# rendered for review, and exported as JSON for tools/zones/BuildTravelPortal.lua. Also renders the TRAVEL HUD icon.
# Run it in Blender (tools/blender/send.ps1 -File tools/blender/travel_portal.py), or headless:
#   python travel_portal.py   (with `pip install bpy==5.2.2`; set HATCH_REPO to the repo if it isn't found)
# Units: 1 Blender m = 1 stud, Z up, the portal's FRONT faces Blender -Y (Roblox +Z after export); it stands on z = 0.
# A courthouse doorway: stepped base, two columns with gold bands, a beam with a sign plate, a stepped pediment
# with a gold compass, and in the doorway a round, see-through portal in a smooth gold ring with six gems (Gem1-6 =
# the six zones, lit per player by the client): a ForceField disc (Studio animates its shimmer) under two
# translucent neon layers and a bright core, three spiral arms (SwirlArm, spun by the client) and particles
# (the client adds Shared.Effects.ambient on the disc - the sparkles in the preview render only show the idea).
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
OUT_ICON = os.path.join(REPO, "art", "icons", "travel.png")

# ------------------------------------------------------------------ scene + a shared unit cube
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
    stone=rgb(176, 178, 190), stone2=rgb(150, 152, 166), cream=rgb(246, 226, 180), cream2=rgb(232, 210, 160),
    gold=rgb(255, 200, 40), goldDark=rgb(217, 154, 16), ink=rgb(40, 40, 52), terracotta=rgb(200, 100, 90),
    leaf=rgb(70, 168, 34), leaf2=rgb(96, 196, 40), leafTop=rgb(150, 222, 82), lamp=rgb(255, 220, 110),
    swirl1=rgb(70, 90, 230), swirl2=rgb(160, 90, 255), swirl3=rgb(150, 225, 255), core=rgb(250, 250, 255),
)
# the six zones in lane order (their floor / edge colours in tools/zones/BuildLane.lua; Config.Zones.List[i].Color)
ZONE_COLORS = [rgb(104, 152, 236), rgb(156, 214, 64), rgb(170, 80, 210), rgb(240, 84, 74), rgb(90, 170, 230), rgb(90, 240, 255)]

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

def round_disc(name, cx, cy, cz, d, thick, col, tag="neon", alpha=0.0):
    """A smooth round disc facing the front (a Cylinder part turned to face -Y / Roblox +Z)."""
    return box(name, cx, cy, cz - d / 2, thick, d, d, col, rz=90, tag=tag, alpha=alpha, mesh=cyl_me, shape="cyl")

def disc(name, cx, cy, cz, r, thick, col, tag="neon"):
    """A blocky disc of radius r facing the front (rows of blocks, the house style - tools/blender/zone_decor.py)."""
    n = max(2, int(r * 2))
    step = 2 * r / n
    for i in range(n):
        u = -r + step * (i + 0.5)
        h = 2 * math.sqrt(max(0.0, r * r - u * u))
        box(name, cx + u, cy, cz - h / 2, step + 0.02, thick, h, col, tag=tag)

# ------------------------------------------------------------------ the base: three wide steps
box("Step", 0, 0, 0, 32, 16, 0.8, PAL["stone2"])
box("Step", 0, 0.5, 0.8, 27, 13, 0.8, PAL["stone"])
box("Step", 0, 1.0, 1.6, 23, 10, 0.6, PAL["cream2"])
FLOOR = 2.2

# ------------------------------------------------------------------ two columns
PX = 9.4
for side in (-1, 1):
    x = side * PX
    box("Plinth", x, 1.0, FLOOR, 4.2, 4.2, 1.2, PAL["stone"])
    z = FLOOR + 1.2
    for k in range(6):
        box("Shaft", x, 1.0, z, 3.0, 3.0, 2.0, PAL["cream"] if k % 2 == 0 else PAL["cream2"])
        z += 2.0
        if k % 2 == 1:
            box("Band", x, 1.0, z - 0.2, 3.3, 3.3, 0.4, PAL["gold"])
    box("Capital", x, 1.0, z, 4.2, 4.2, 1.0, PAL["goldDark"])
    # a lantern on the front of each column
    box("LanternBack", x, -0.6, 10.0, 1.4, 0.4, 2.0, PAL["ink"])
    box("Lantern", x, -0.95, 10.3, 1.0, 0.4, 1.4, PAL["lamp"], tag="neon")
    # a planter at each side of the steps
    px = side * 14.2
    box("Pot", px, -4.6, 0.8, 2.4, 2.4, 1.6, PAL["terracotta"])
    box("Bush", px, -4.6, 2.4, 2.2, 2.2, 1.4, PAL["leaf"])
    box("Bush", px + side * 0.3, -4.8, 3.6, 1.6, 1.6, 1.0, PAL["leaf2"])
    box("BushTop", px, -4.6, 4.5, 0.9, 0.9, 0.6, PAL["leafTop"])
TOP = FLOOR + 1.2 + 12.0 + 1.0  # the column tops

# ------------------------------------------------------------------ the beam + sign plate + the stepped pediment
box("Trim", 0, 1.0, TOP, 24.4, 4.6, 0.4, PAL["gold"])
box("Beam", 0, 1.0, TOP + 0.4, 23.6, 4.2, 2.4, PAL["cream"])
box("Trim", 0, 1.0, TOP + 2.8, 24.4, 4.6, 0.4, PAL["gold"])
box("SignPlate", 0, -1.2, TOP + 0.75, 12.0, 0.25, 1.7, PAL["ink"])  # the builder writes "TRAVEL" on its front
z = TOP + 3.2
for i, w in enumerate((22.6, 18.2, 13.8, 9.4, 5.0)):
    box("Pediment", 0, 1.0, z, w, 3.8, 1.1, PAL["cream2"] if i % 2 == 0 else PAL["cream"])
    box("PedimentEdge", 0, -0.95, z, w + 0.3, 0.2, 0.25, PAL["gold"])
    z += 1.1
# a gold compass star on the pediment's face (travel)
cz = TOP + 5.6
box("Compass", 0, -1.05, cz - 0.8, 1.6, 0.4, 1.6, PAL["gold"])
box("Compass", 0, -1.0, cz - 2.2, 0.7, 0.3, 4.4, PAL["gold"])
box("Compass", 0, -1.0, cz - 0.35, 4.4, 0.3, 0.7, PAL["gold"])
box("Compass", 0, -0.95, cz - 1.5, 0.5, 0.3, 3.0, PAL["goldDark"], ry=45)

# ------------------------------------------------------------------ the portal: a gold ring, six gems, three swirls
DOOR_Z = FLOOR + 7.4  # the portal's centre height
R = 5.6
segs = 32  # (a smooth, full circle; 2026-10-13 user)
for i in range(segs):
    a = (i + 0.5) / segs * 2 * math.pi
    x, zz = math.cos(a) * R, math.sin(a) * R
    box("Ring", x, 0.6, DOOR_Z + zz - 0.75, 1.25, 1.4, 1.5, PAL["gold"] if i % 2 == 0 else PAL["goldDark"], ry=-math.degrees(a))
# six gems across the top of the ring, lane order left to right (the client lights the ones you can travel to)
for k in range(6):
    a = math.radians(150 - k * 24)
    x, zz = math.cos(a) * (R + 0.2), math.sin(a) * (R + 0.2)
    box("Gem%d" % (k + 1), x, -0.25, DOOR_Z + zz - 0.65, 1.3, 0.6, 1.3, ZONE_COLORS[k], ry=45, tag="neon")
# the portal face (2026-10-13 user: "slightly see thru, with vfx particles, a full circle"): a smooth ForceField disc
# (tag "field" - its shimmer moves on its own in Studio), two translucent neon layers, a soft bright core
round_disc("SwirlDisc", 0, 0.9, DOOR_Z, 2 * R - 0.6, 0.2, PAL["swirl1"], tag="field", alpha=0.0)
round_disc("SwirlGlow", 0, 0.75, DOOR_Z, 2 * R - 3.4, 0.2, PAL["swirl2"], tag="neon", alpha=0.55)
round_disc("SwirlGlow", 0, 0.6, DOOR_Z, 2 * R - 6.6, 0.2, PAL["swirl3"], tag="neon", alpha=0.45)
round_disc("SwirlCore", 0, 0.45, DOOR_Z, 1.8, 0.2, PAL["core"], tag="neon", alpha=0.2)
# three spiral arms of small translucent blocks: the client spins them (a smooth disc spinning doesn't show)
for arm in range(3):
    for k in range(6):
        t = k / 5
        ang = arm * 2 * math.pi / 3 + t * 2.4
        rad = 0.9 + t * (R - 1.9)
        size = 0.5 + 0.55 * t
        box("SwirlArm", math.cos(ang) * rad, 0.35, DOOR_Z + math.sin(ang) * rad - size / 2, size * 1.4, 0.2, size,
            PAL["core"], ry=-math.degrees(ang) - 70, tag="neon", alpha=0.35 + 0.35 * t)
# walking into this opens the travel map (invisible, no collision)
box("Trigger", 0, 0.5, FLOOR, 12.0, 4.0, 13.5, PAL["core"], tag="trigger")

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
    json.dump(dict(front="+Z", size=[32, round(TOP + 8.7, 2), 16], parts=parts), fh, separators=(",", ":"))

# ------------------------------------------------------------------ renders
# sparkles for the review shot only (the game uses Shared.Effects.ambient particles on the disc instead)
import random
rnd = random.Random(7)
for i in range(40):
    a, rad = rnd.uniform(0, 2 * math.pi), rnd.uniform(1.0, R + 1.5)
    sp = box("Sparkle", math.cos(a) * rad, rnd.uniform(-2.5, 0.2), DOOR_Z + math.sin(a) * rad, 0.22, 0.22, 0.22,
             rnd.choice([PAL["core"], PAL["swirl3"], PAL["swirl2"]]), rx=45, ry=45, tag="neon")
    sp["preview"] = True

# one material per colour / look, so EEVEE shows the see-through layers and the glow
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
    bsdf.inputs["Roughness"].default_value = 0.55
    alpha = 1 - o["alpha"]
    if o["tag"] in ("neon", "field"):
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = 0.7 if o["tag"] == "neon" else 0.35
        if o["tag"] == "field":
            alpha = 0.6  # (Studio's ForceField is see-through on its own)
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
sc.eevee.taa_render_samples = 24
world = sc.world or bpy.data.worlds.new("TP_World")
sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.34, 0.40, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55
sun_data = bpy.data.lights.get("TP_Sun") or bpy.data.lights.new("TP_Sun", "SUN")
sun_data.energy = 2.2
sun = bpy.data.objects.new("TP_Sun", sun_data)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
coll.objects.link(sun)
cam_data = bpy.data.cameras.get("TP_Cam") or bpy.data.cameras.new("TP_Cam")
cam = bpy.data.objects.new("TP_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam
trig = [o for o in ROOT.children if o.name.startswith("Trigger")][0]
trig.hide_render = True

def look(at, frm):
    cam.location = frm
    dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
    cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)

# 1) the review shot: three-quarter front view (EEVEE: see-through layers + glow)
cam_data.type = "PERSP"
cam_data.lens = 35
look((0, 0, 11), (24, -44, 18))
sc.render.resolution_x, sc.render.resolution_y = 1400, 1100
sc.render.film_transparent = False
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)

# 2) the HUD icon: just the portal ring + gems + swirl, straight on, flat vivid colours, transparent background,
#    square (crnuch uploads it as HudMenu.Icons.Travel)
for o in ROOT.children:
    o.hide_render = not (o.name.startswith(("Ring", "Gem", "Swirl")))
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_object_outline = True
cam_data.type = "ORTHO"
cam_data.ortho_scale = 2 * (R + 1.3)
look((0, 0, DOOR_Z), (0, -60, DOOR_Z))
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.film_transparent = True
sc.render.filepath = OUT_ICON
os.makedirs(os.path.dirname(OUT_ICON), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"TravelPortal: {len(parts)} blocks -> {OUT_JSON}; renders {OUT_PNG}, {OUT_ICON}")
