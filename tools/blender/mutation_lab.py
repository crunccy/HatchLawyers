# tools/blender/mutation_lab.py - the MUTATION LAB: the stage the mutation sequence plays on (StarterPlayerScripts.Merger
# + Shared.MutationFx clone ReplicatedStorage.MutationLab far above the map, client-only, like the Mythic / Supreme hatch
# stages). Built in Blender out of chunky blocks (every block becomes a studded Part in Studio), rendered for review,
# exported as JSON for tools/zones/BuildMutationLab.lua.
# v1 2026-10-21 (mr.robe: "a better 3d looking menu with some real animations when they mutate, similar to the egg
#    hatching"). The look follows the hub's Mutation Machine: violet bricks, a gold plinth, cyan / pink / lime lights.
#    A round studded lab floor, a glass CAPSULE on a gold plinth in the middle (where the three lawyers are pulled in and
#    the result comes out), three intake PADS in front with pipes into the capsule, two TESLA COILS at the back (the
#    charge arcs from them into the capsule), and a curved back wall with screens, bulbs and the sign.
# Names the client looks up (keep them): Pad1-3 (the pad tops: a lawyer stands on each, left / front / right),
# PipeGlow<p>_<k> (pad p's pipe collars, k = 1 at the pad .. 3 at the capsule: lit in turn as a lawyer is pulled in),
# CapsuleCore (the light column in the glass), CapsuleCentre (a marker in the capsule's middle), Lid* (glass, ribs, cap:
# the builder puts them in a Model "Lid" that lifts to open the capsule), CoilTop1-2 (where the arcs start), FloorGlow
# (glowing bands, recoloured to the tier), Bulb / LidBulb (chase lights), Screen (wall screens), SignPlate (the builder
# writes "MUTATION MACHINE" on it).
# Run: "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools/blender/mutation_lab.py
# Units: 1 Blender m = 1 stud, Z up, the lab's FRONT faces Blender -Y (Roblox +Z after export); the floor top is z = 0.
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
OUT_JSON = os.path.join(REPO, "tools", "zones", "mutation_lab.json")
OUT_PNG = os.path.join(REPO, "art", "mutation", "lab.png")
OUT_PNG_CLOSE = os.path.join(REPO, "art", "mutation", "lab_close.png")

# ------------------------------------------------------------------ scene + shared meshes
sc = bpy.data.scenes.get("MutationLab") or bpy.data.scenes.new("MutationLab")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("MutationLab") or bpy.data.collections.new("MutationLab")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("ML_Cube")
if me is None:
    me = bpy.data.meshes.new("ML_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

# a unit cylinder along X (Roblox's Cylinder shape runs along its X axis too): length 1, diameter 1
cyl_me = bpy.data.meshes.get("ML_Cyl")
if cyl_me is None:
    cyl_me = bpy.data.meshes.new("ML_Cyl")
    n = 48
    v = [(x, 0.5 * math.cos(2 * math.pi * i / n), 0.5 * math.sin(2 * math.pi * i / n)) for x in (-0.5, 0.5) for i in range(n)]
    f = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    cyl_me.from_pydata(v, [], f)
    cyl_me.update()

# a unit ball (Roblox's Ball shape), diameter 1
ball_me = bpy.data.meshes.get("ML_Ball")
if ball_me is None:
    ball_me = bpy.data.meshes.new("ML_Ball")
    rings, segs = 12, 24
    v = [(0, 0, 0.5)]
    for r in range(1, rings):
        th = math.pi * r / rings
        for s in range(segs):
            ph = 2 * math.pi * s / segs
            v.append((0.5 * math.sin(th) * math.cos(ph), 0.5 * math.sin(th) * math.sin(ph), 0.5 * math.cos(th)))
    v.append((0, 0, -0.5))
    f = []
    for s in range(segs):
        f.append((0, 1 + s, 1 + (s + 1) % segs))
    for r in range(rings - 2):
        a0, b0 = 1 + r * segs, 1 + (r + 1) * segs
        for s in range(segs):
            f.append((a0 + s, b0 + s, b0 + (s + 1) % segs, a0 + (s + 1) % segs))
    last = len(v) - 1
    base = 1 + (rings - 2) * segs
    for s in range(segs):
        f.append((base + (s + 1) % segs, base + s, last))
    ball_me.from_pydata(v, [], f)
    ball_me.update()

def rgb(r, g, b):
    return (r, g, b)

# the hub Mutation Machine's colours (violet bricks, gold plinth, cyan / pink / lime lights)
PAL = dict(
    violet=rgb(124, 72, 232), violetDark=rgb(78, 42, 160), violetDeep=rgb(48, 28, 96), floor=rgb(58, 36, 104),
    floorTop=rgb(72, 46, 128), ink=rgb(30, 32, 46), steel=rgb(150, 160, 182),
    gold=rgb(255, 200, 40), goldDark=rgb(217, 154, 16),
    cyan=rgb(90, 230, 255), pink=rgb(255, 120, 220), lime=rgb(190, 255, 40), white=rgb(250, 252, 255),
    glass=rgb(205, 235, 255), core=rgb(225, 250, 255),
)

ROOT = bpy.data.objects.new("MutationLab", None)
coll.objects.link(ROOT)

def box(name, cx, cy, z0, sx, sy, sz, col, rx=0.0, ry=0.0, rz=0.0, tag="", alpha=0.0, mesh=None, shape=""):
    """A block whose bottom sits at z0 (centre cx, cy), turned rx / ry / rz degrees about its centre.
    tag: "neon" (glowing), "glass" (see-through, reflective), "marker" (invisible); alpha = its Transparency in Studio;
    shape "cyl" = a Cylinder part (mesh along X), "ball" = a Ball part."""
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

def ball(name, cx, cy, cz, d, col, tag="", alpha=0.0):
    """A ball of diameter d centred at (cx, cy, cz)."""
    o = box(name, cx, cy, 0, d, d, d, col, tag=tag, alpha=alpha, mesh=ball_me, shape="ball")
    o.location = (cx, cy, cz)
    return o

def ring_of_blocks(name, r, z0, n, size, cols, tag="", start=0.0, span=360.0):
    """n blocks round a circle of radius r (centres), each turned to face out."""
    for i in range(n):
        a = math.radians(start + (i + 0.5) / n * span)
        box(name, math.cos(a) * r, math.sin(a) * r, z0, size[0], size[1], size[2], cols[i % len(cols)], rz=math.degrees(a), tag=tag)

# ------------------------------------------------------------------ the lab floor: a round studded stage with a glowing band
vdisc("Floor", 0, 0, -2.4, 46.0, 2.0, PAL["violetDeep"])
vdisc("FloorGlow", 0, 0, -1.25, 46.4, 0.35, PAL["violet"], tag="neon")
vdisc("Floor", 0, 0, -0.4, 42.0, 0.4, PAL["floor"])
# a gold rim of blocks round the edge, and a darker inner field so the middle reads as "the machine"
ring_of_blocks("Rim", 20.6, -0.05, 36, (0.9, 3.7, 0.55), [PAL["gold"], PAL["goldDark"]])
vdisc("FloorInner", 0, 0, -0.05, 30.0, 0.05, PAL["floorTop"])
# hazard stripes round the capsule (gold / ink), where the lawyers must not stand
ring_of_blocks("Hazard", 8.2, -0.02, 28, (1.0, 1.7, 0.1), [PAL["gold"], PAL["ink"]])
# little floor lamps round the front half
for k, deg in enumerate((200, 225, 250, 290, 315, 340)):
    a = math.radians(deg)
    x, y = math.cos(a) * 18.4, math.sin(a) * 18.4
    box("LampPost", x, y, -0.05, 0.9, 0.9, 1.4, PAL["ink"])
    box("Bulb", x, y, 1.35, 0.7, 0.7, 0.6, [PAL["cyan"], PAL["pink"], PAL["lime"]][k % 3], tag="neon")

# ------------------------------------------------------------------ the capsule: gold plinth, glass tube, cap (the Lid lifts)
vdisc("Plinth", 0, 0, -0.05, 11.6, 1.0, PAL["gold"])
vdisc("PlinthTrim", 0, 0, 0.95, 12.0, 0.3, PAL["goldDark"])
vdisc("Plinth", 0, 0, 1.25, 9.6, 0.7, PAL["violetDark"])
vdisc("FloorGlow", 0, 0, 1.5, 10.0, 0.22, PAL["cyan"], tag="neon")
BASE_TOP = 1.95
vdisc("CoreGlow", 0, 0, BASE_TOP, 6.4, 0.12, PAL["core"], tag="neon", alpha=0.2)
GLASS_H = 10.6
vdisc("LidGlass", 0, 0, BASE_TOP + 0.05, 7.2, GLASS_H, PAL["glass"], tag="glass", alpha=0.6)
vdisc("CapsuleCore", 0, 0, BASE_TOP + 0.1, 3.0, GLASS_H - 0.2, PAL["core"], tag="neon", alpha=0.82)
for deg in (0, 60, 120, 180):  # gold ribs holding the cap (sides + back: the front stays open for the camera)
    a = math.radians(deg)
    box("LidRib", math.cos(a) * 3.85, math.sin(a) * 3.85, BASE_TOP, 0.7, 0.7, GLASS_H + 0.1, PAL["gold"], rz=deg)
for zz in (BASE_TOP + 0.1,):  # a thin gold band round the glass foot
    vdisc("LidBand", 0, 0, zz, 7.5, 0.35, PAL["goldDark"])
CAP = BASE_TOP + GLASS_H + 0.05
vdisc("LidCap", 0, 0, CAP, 8.6, 1.3, PAL["violetDark"])
vdisc("LidCapRing", 0, 0, CAP + 0.35, 9.0, 0.5, PAL["gold"])
vdisc("LidCap", 0, 0, CAP + 1.3, 6.4, 0.8, PAL["violet"])
vdisc("LidCap", 0, 0, CAP + 2.1, 4.2, 0.6, PAL["violetDark"])
box("LidAntenna", 0, 0, CAP + 2.7, 0.35, 0.35, 0.3, PAL["ink"])
ball("LidLamp", 0, 0, CAP + 3.45, 1.3, PAL["pink"], tag="neon")
ring_of_blocks("LidBulb", 4.45, CAP + 0.45, 12, (0.4, 0.55, 0.45), [PAL["cyan"], PAL["pink"], PAL["lime"]], tag="neon")
# where the lawyers go: the capsule's middle (invisible)
box("CapsuleCentre", 0, 0, BASE_TOP + GLASS_H / 2 - 0.5, 1, 1, 1, PAL["white"], tag="marker")

# ------------------------------------------------------------------ three intake pads in front, piped into the capsule
PAD_R = 13.5
PAD_ANGLES = (222, 270, 318)  # left, front, right (Blender degrees; -Y is the front)
for p, deg in enumerate(PAD_ANGLES, start=1):
    a = math.radians(deg)
    x, y = math.cos(a) * PAD_R, math.sin(a) * PAD_R
    vdisc("PadBase", x, y, -0.05, 5.6, 0.5, PAL["ink"])
    vdisc("FloorGlow", x, y, 0.2, 5.9, 0.16, PAL["cyan"], tag="neon")
    vdisc("PadRim", x, y, 0.45, 5.0, 0.25, PAL["gold"])
    vdisc("Pad%d" % p, x, y, 0.7, 4.3, 0.2, PAL["violet"])
    # the pipe: lying on the floor from the pad's edge to the plinth, with three glowing collars
    r0, r1 = PAD_R - 2.9, 6.1
    mid = (r0 + r1) / 2
    length = r0 - r1
    box("Pipe", math.cos(a) * mid, math.sin(a) * mid, -0.05, length, 1.4, 1.1, PAL["violet"], rz=deg)
    box("PipeTop", math.cos(a) * mid, math.sin(a) * mid, 1.05, length, 0.8, 0.15, PAL["gold"], rz=deg)
    for k in range(1, 4):
        rr = r0 - (k - 0.5) * length / 3
        box("PipeGlow%d_%d" % (p, k), math.cos(a) * rr, math.sin(a) * rr, -0.1, 0.55, 1.7, 1.35, PAL["cyan"], rz=deg, tag="neon")

# ------------------------------------------------------------------ two tesla coils at the back
for c, sx in enumerate((-1, 1), start=1):
    x, y = sx * 14.2, 6.4
    box("CoilBase", x, y, -0.05, 3.4, 3.4, 1.4, PAL["ink"])
    box("CoilBaseTrim", x, y, 1.35, 3.0, 3.0, 0.3, PAL["gold"])
    vdisc("CoilColumn", x, y, 1.65, 1.5, 6.6, PAL["violetDark"])
    for zz in (2.4, 3.9, 5.4, 6.9):
        vdisc("CoilRing", x, y, zz, 2.7, 0.35, PAL["gold"])
    vdisc("CoilCap", x, y, 8.25, 3.0, 0.5, PAL["ink"])
    ball("CoilTop%d" % c, x, y, 9.85, 2.6, PAL["cyan"], tag="neon")

# ------------------------------------------------------------------ the curved back wall: violet panels, screens, bulbs
WALL_R = 20.0
N = 11
SPAN0, SPAN1 = 18.0, 162.0  # behind the capsule (+Y side), the front stays open for the camera
for i in range(N):
    deg = SPAN0 + (i + 0.5) / N * (SPAN1 - SPAN0)
    a = math.radians(deg)
    x, y = math.cos(a) * WALL_R, math.sin(a) * WALL_R
    w = 2 * WALL_R * math.sin(math.radians((SPAN1 - SPAN0) / N / 2)) + 0.25
    h = 19.6 if i in (N // 2 - 1, N // 2, N // 2 + 1) else 12.0
    box("Wall", x, y, -0.05, 1.4, w, h, PAL["violet"] if i % 2 == 0 else PAL["violetDark"], rz=deg)
    box("WallTrim", x, y, h - 0.05, 1.8, w + 0.1, 0.6, PAL["gold"], rz=deg)
    box("WallFoot", x, y, -0.05, 2.0, w + 0.1, 0.8, PAL["ink"], rz=deg)
    inx, iny = math.cos(a) * (WALL_R - 0.75), math.sin(a) * (WALL_R - 0.75)
    if i not in (N // 2,):
        box("ScreenFrame", inx, iny, 4.6, 0.25, w * 0.66, 4.0, PAL["ink"], rz=deg)
        box("Screen", math.cos(a) * (WALL_R - 0.9), math.sin(a) * (WALL_R - 0.9), 4.9, 0.12, w * 0.54, 3.4,
            [PAL["cyan"], PAL["pink"], PAL["lime"]][i % 3], rz=deg, tag="neon", alpha=0.15)
    for k in range(3):  # a row of bulbs along the top
        t = (k + 0.5) / 3 - 0.5
        bx, by = x + math.cos(a + math.pi / 2) * t * w * 0.9, y + math.sin(a + math.pi / 2) * t * w * 0.9
        box("Bulb", bx - math.cos(a) * 0.85, by - math.sin(a) * 0.85, h - 1.2, 0.5, 0.5, 0.5,
            [PAL["cyan"], PAL["pink"], PAL["white"]][(i + k) % 3], rz=deg, tag="neon")
# the sign over the middle panels (the builder writes "MUTATION MACHINE" on its front)
SIGN_Z = 20.4
box("SignBack", 0, WALL_R - 1.2, SIGN_Z - 0.4, 17.4, 0.8, 4.4, PAL["gold"])
box("SignPlate", 0, WALL_R - 1.7, SIGN_Z, 16.2, 0.25, 3.6, PAL["ink"])
for i in range(12):
    t = i / 11
    for zz in (SIGN_Z + 3.7, SIGN_Z - 0.45):
        box("Bulb", -7.8 + 15.6 * t, WALL_R - 1.85, zz, 0.5, 0.3, 0.5,
            [PAL["cyan"], PAL["pink"], PAL["gold"]][(i + (1 if zz > SIGN_Z else 0)) % 3], tag="neon")
# two big pipes from the wall into the capsule's cap (it is "plugged into the lab")
for sx in (-1, 1):
    box("WallPipe", sx * 3.2, WALL_R - 7.6, CAP + 0.2, 1.4, 15.2, 1.4, PAL["violetDark"])
    box("WallPipeGlow", sx * 3.2, WALL_R - 4.0, CAP + 0.05, 1.8, 0.6, 1.7, PAL["pink"], tag="neon")
    box("WallPipeGlow", sx * 3.2, WALL_R - 9.0, CAP + 0.05, 1.8, 0.6, 1.7, PAL["pink"], tag="neon")

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
    json.dump(dict(front="+Z", size=[46, round(SIGN_Z + 4.2, 2), 46], parts=parts), fh, separators=(",", ":"))

# ------------------------------------------------------------------ renders (review only)
mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"], round(o["alpha"], 2))
    if key in mats:
        return mats[key]
    m = bpy.data.materials.new("ML_%d" % len(mats))
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = 0.5
    alpha = 1 - o["alpha"]
    if o["tag"] == "neon":
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = 1.6
    elif o["tag"] == "glass":
        alpha = 0.35
    elif o["tag"] == "marker":
        alpha = 0.0
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1:
        m.surface_render_method = "BLENDED"
    mats[key] = m
    return m
for mesh in (me, cyl_me, ball_me):  # the shared meshes get one material slot; each object fills it (link = OBJECT)
    if not mesh.materials:
        mesh.materials.append(None)
for o in ROOT.children:
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = material_for(o)
    if o["tag"] == "marker":
        o.hide_render = True

sc.view_settings.view_transform = "Standard"
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
sc.eevee.taa_render_samples = 32
world = sc.world or bpy.data.worlds.new("ML_World")
sc.world = world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.10, 0.06, 0.22, 1)
bg.inputs["Strength"].default_value = 0.8
sun_data = bpy.data.lights.get("ML_Sun") or bpy.data.lights.new("ML_Sun", "SUN")
sun_data.energy = 2.2
sun = bpy.data.objects.new("ML_Sun", sun_data)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
coll.objects.link(sun)
cam_data = bpy.data.cameras.get("ML_Cam") or bpy.data.cameras.new("ML_Cam")
cam = bpy.data.objects.new("ML_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam

def look(at, frm):
    cam.location = frm
    dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
    cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)

cam_data.type = "PERSP"
cam_data.lens = 30
sc.render.resolution_x, sc.render.resolution_y = 1400, 900
sc.render.film_transparent = False
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
# 1) the wide shot the sequence opens on (front, a little to the side, above head height)
look((0, 2, 5), (9, -38, 13))
sc.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True, scene=sc.name)
# 2) the close shot on the capsule (the reveal)
look((0, 0, 7), (3, -17, 7.5))
sc.render.filepath = OUT_PNG_CLOSE
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"MutationLab v1: {len(parts)} blocks -> {OUT_JSON}; renders {OUT_PNG}, {OUT_PNG_CLOSE}")
