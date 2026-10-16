# tools/blender/zone_landmarks.py - the ZONE THRESHOLD LANDMARKS (art pass stage 5, docs/ART_REMODEL_BRIEF.md,
# 2026-10-16): a pair of big brick statues on top of each License gate, showing the zone the gate leads into, so the
# lane reads from far away: PetPark = a puppy, BrainrotBoulevard = a googly brain, FoodCourt = a burger, OceanShore = a
# leaping fish, SpaceBase = a rocket. Each statue stands on a gold plinth. tools/zones/BuildZoneLandmarks.lua puts them
# on the gates (Workspace.ZoneLandmarks, outside Workspace.Zones so a BuildLane re-run leaves them alone).
# Front = Blender +Y; the builder turns them to face players walking down the lane.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/zone_landmarks.py
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "zone_landmarks.json")
OUT_PNG = os.path.join(REPO, "art", "map", "zone_landmarks.png")

sc = bpy.data.scenes.get("ZoneLandmarks") or bpy.data.scenes.new("ZoneLandmarks")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("ZoneLandmarks") or bpy.data.collections.new("ZoneLandmarks")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("ZL_Cube")
if me is None:
    me = bpy.data.meshes.new("ZL_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

def rgb(r, g, b):
    return (r, g, b)
PAL = dict(gold=rgb(255, 200, 40), ink=rgb(30, 32, 46), white=rgb(246, 244, 236), red=rgb(229, 57, 53), pink=rgb(255, 140, 200),
           pinkD=rgb(220, 90, 160), tan=rgb(230, 180, 120), brown=rgb(140, 84, 40), bun=rgb(232, 160, 70), patty=rgb(110, 60, 30),
           cheese=rgb(255, 205, 40), lettuce=rgb(98, 205, 48), tomato=rgb(229, 57, 53), orange=rgb(255, 140, 30), sky=rgb(90, 200, 255),
           blue=rgb(60, 130, 230), steel=rgb(200, 206, 220), flame=rgb(255, 200, 60))

ROOTS = {}
def root(name):
    if name not in ROOTS:
        o = bpy.data.objects.new(name, None)
        coll.objects.link(o)
        ROOTS[name] = o
    return ROOTS[name]

def box(model, name, cx, cy, z0, sx, sy, sz, col, rx=0.0, ry=0.0, rz=0.0, tag=""):
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o["rgb"] = list(col)
    o["tag"] = tag
    coll.objects.link(o)
    o.parent = root(model)
    return o

def plinth(m):
    box(m, "Plinth", 0, 0, 0, 8, 8, 1.2, PAL["gold"])
    box(m, "PlinthTop", 0, 0, 1.2, 7, 7, 0.5, PAL["ink"])
    return 1.7

# ------------------------------------------------------------------ PetPark: a sitting puppy
m = "PetPark"
z = plinth(m)
box(m, "Haunch", 0, -1.0, z, 5.4, 5.0, 3.6, PAL["tan"])
box(m, "Chest", 0, 0.6, z + 2.0, 4.2, 3.2, 4.6, PAL["tan"])
for s in (-1, 1):
    box(m, "Leg", s * 1.2, 1.6, z, 1.3, 1.3, 3.0, PAL["tan"])
    box(m, "Paw", s * 1.2, 2.1, z, 1.5, 1.6, 0.8, PAL["white"])
box(m, "Collar", 0, 0.6, z + 6.2, 4.4, 3.4, 0.6, PAL["red"])
box(m, "Tag", 0, 2.35, z + 5.5, 0.8, 0.2, 0.8, PAL["gold"])
box(m, "Head", 0, 0.8, z + 6.8, 4.6, 4.2, 4.0, PAL["tan"])
box(m, "Snout", 0, 3.2, z + 7.0, 2.4, 1.6, 1.6, PAL["white"])
box(m, "Nose", 0, 4.05, z + 8.0, 1.0, 0.4, 0.7, PAL["ink"])
box(m, "Tongue", 0.4, 3.9, z + 6.6, 0.7, 0.3, 0.8, PAL["pink"])
for s in (-1, 1):
    box(m, "Eye", s * 1.1, 2.95, z + 8.6, 0.7, 0.2, 0.9, PAL["ink"])
    box(m, "Ear", s * 2.6, 0.6, z + 7.4, 0.8, 2.0, 3.2, PAL["brown"], ry=s * 12)
box(m, "Tail", 0, -3.8, z + 1.6, 0.9, 2.2, 0.9, PAL["brown"], rx=-35)

# ------------------------------------------------------------------ BrainrotBoulevard: a googly-eyed brain
m = "BrainrotBoulevard"
z = plinth(m)
box(m, "Stem", 0, 0, z, 1.6, 1.6, 2.0, PAL["pinkD"])
for (w, d, h, dz) in ((7.0, 5.6, 1.6, 2.0), (7.6, 6.2, 1.8, 3.6), (7.4, 6.0, 1.8, 5.4), (6.4, 5.2, 1.4, 7.2), (4.6, 3.8, 1.0, 8.6)):
    box(m, "Brain", 0, 0, z + dz, w, d, h, PAL["pink"])
box(m, "Split", 0, 0, z + 3.0, 0.3, 6.4, 6.4, PAL["pinkD"])
for (x, dz, ln) in ((-2.2, 4.4, 2.4), (2.4, 5.6, 2.0), (-1.4, 7.0, 1.8), (2.0, 3.2, 2.2)):  # folds
    box(m, "Fold", x, 3.15, z + dz, ln, 0.2, 0.3, PAL["pinkD"])
for s in (-1, 1):
    box(m, "EyeWhite", s * 1.8, 3.2, z + 3.9, 2.0, 0.5, 2.0, PAL["white"])
    box(m, "Pupil", s * 1.6, 3.5, z + 4.1, 0.9, 0.3, 0.9, PAL["ink"])
box(m, "Smile", 0, 3.1, z + 2.4, 2.6, 0.3, 0.5, PAL["ink"])

# ------------------------------------------------------------------ FoodCourt: a burger
m = "FoodCourt"
z = plinth(m)
for (name, w, h, col) in (("BunBottom", 6.4, 1.4, PAL["bun"]), ("Patty", 7.0, 1.3, PAL["patty"]), ("Cheese", 7.4, 0.35, PAL["cheese"]),
                          ("Lettuce", 7.2, 0.5, PAL["lettuce"]), ("Tomato", 6.6, 0.6, PAL["tomato"]), ("BunTop", 6.6, 1.6, PAL["bun"]),
                          ("BunTop", 5.6, 1.0, PAL["bun"]), ("BunTop", 4.0, 0.7, PAL["bun"])):
    box(m, name, 0, 0, z, w, w, h, col)
    z += h
for (x, y) in ((-1.6, 1.4), (1.2, 2.0), (0.2, -1.2), (2.0, -0.6), (-1.2, -1.8), (-0.4, 0.4)):  # sesame seeds
    box(m, "Seed", x, y, z - 1.5, 0.5, 0.3, 0.25, PAL["white"])
box(m, "CheeseDrip", 2.8, 2.8, z - 5.1, 1.0, 1.0, 0.9, PAL["cheese"])
box(m, "Flag", 0, 0, z, 0.25, 0.25, 2.2, PAL["ink"])
box(m, "FlagCloth", 0.8, 0, z + 1.2, 1.5, 0.15, 0.9, PAL["red"])

# ------------------------------------------------------------------ OceanShore: a leaping fish over a splash
m = "OceanShore"
z = plinth(m)
for (w, h, col) in ((6.4, 0.8, PAL["blue"]), (4.6, 0.8, PAL["sky"]), (2.4, 0.8, PAL["white"])):
    box(m, "Splash", 0, 0, z, w, w, h, col)
    z += 0.6
box(m, "Spray", 0, 0, z, 0.9, 0.9, 2.6, PAL["sky"])
F = z + 2.2
for (x, w, h) in ((-2.8, 1.8, 2.4), (-1.2, 2.2, 3.4), (0.6, 2.2, 3.8), (2.4, 2.0, 3.2), (4.0, 1.4, 2.0)):  # body, tilted up
    box(m, "Fish", x * 0.95, 0, F + x * 0.55, w + 0.4, 2.2, h, PAL["orange"], ry=-28)
box(m, "Belly", 0.6, 0, F - 0.6, 3.4, 2.3, 1.0, PAL["white"], ry=-28)
box(m, "Tail", -4.6, 0, F - 2.6, 1.0, 0.6, 3.2, PAL["orange"], ry=-50)
box(m, "Tail", -4.9, 0, F - 3.4, 1.0, 0.6, 2.4, PAL["orange"], ry=10)
box(m, "Fin", 0.8, 0, F + 2.4, 1.6, 0.4, 1.4, PAL["red"], ry=-40)
for s in (-1, 1):
    box(m, "Eye", 3.6, s * 1.15, F + 2.6, 0.9, 0.2, 0.9, PAL["white"])
    box(m, "Pupil", 3.8, s * 1.25, F + 2.7, 0.45, 0.2, 0.45, PAL["ink"])

# ------------------------------------------------------------------ SpaceBase: a rocket
m = "SpaceBase"
z = plinth(m)
box(m, "Flame", 0, 0, z, 1.6, 1.6, 1.4, PAL["flame"], tag="neon")
box(m, "Flame", 0, 0, z + 0.4, 2.4, 2.4, 0.6, PAL["orange"], tag="neon")
z += 1.4
box(m, "Nozzle", 0, 0, z, 2.6, 2.6, 0.8, PAL["ink"])
z += 0.8
for (w, h, col) in ((3.8, 3.0, PAL["white"]), (3.8, 0.6, PAL["red"]), (3.8, 3.4, PAL["white"]), (3.2, 1.0, PAL["red"]),
                    (2.6, 1.0, PAL["red"]), (1.8, 0.9, PAL["red"]), (1.0, 0.8, PAL["red"])):
    box(m, "Body", 0, 0, z, w, w, h, col)
    z += h
box(m, "Window", 0, 1.95, z - 6.0, 1.6, 0.2, 1.6, PAL["sky"], tag="neon")
box(m, "WindowRim", 0, 1.92, z - 6.2, 2.1, 0.15, 2.1, PAL["steel"])
for (fx, fy, rz) in ((2.2, 0, 0), (-2.2, 0, 0), (0, 2.2, 90), (0, -2.2, 90)):
    box(m, "Fin", fx, fy, 2.2 + 1.7, 0.5 if rz == 0 else 1.6, 1.6 if rz == 0 else 0.5, 3.0, PAL["red"])

# ------------------------------------------------------------------ export
def to_rbx(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]
Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
models = []
for name, r in ROOTS.items():
    parts = []
    for o in r.children:
        rot = o.rotation_euler.to_matrix()
        R3 = [[rot[i][j] for j in range(3)] for i in range(3)]
        MR = [[sum(Mx[i][k] * R3[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
        Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
        s = o.scale
        parts.append(dict(n=o.name.split(".")[0], p=to_rbx(o.location), s=[round(s[0], 3), round(s[2], 3), round(s[1], 3)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"]))
    models.append(dict(name=name, parts=parts))
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(models=models), fh, separators=(",", ":"))

# ------------------------------------------------------------------ review render (all five in a row)
mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"])
    if key not in mats:
        mt = bpy.data.materials.new("ZL_%d" % len(mats))
        mt.use_nodes = True
        bsdf = next(n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
        bsdf.inputs["Base Color"].default_value = col
        if o["tag"] == "neon":
            bsdf.inputs["Emission Color"].default_value = col
            bsdf.inputs["Emission Strength"].default_value = 1.4
        mats[key] = mt
    return mats[key]
if not me.materials:
    me.materials.append(None)
for i, r in enumerate(ROOTS.values()):
    r.location = ((i - 2) * 11, 0, 0)
    for o in r.children:
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = material_for(o)
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
sc.view_settings.view_transform = "Standard"
world = sc.world or bpy.data.worlds.new("ZL_World")
sc.world = world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.55, 0.78, 1, 1)
sun = bpy.data.objects.new("ZL_Sun", bpy.data.lights.get("ZL_Sun") or bpy.data.lights.new("ZL_Sun", "SUN"))
sun.data.energy = 2.6
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
coll.objects.link(sun)
cam = bpy.data.objects.new("ZL_Cam", bpy.data.cameras.get("ZL_Cam") or bpy.data.cameras.new("ZL_Cam"))
coll.objects.link(cam)
sc.camera = cam
cam.data.lens = 35
frm, at = (0, 70, 16), (0, 0, 6)
cam.location = frm
dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
sc.render.resolution_x, sc.render.resolution_y = 1600, 700
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
sc.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True, scene=sc.name)
print("ZoneLandmarks: " + ", ".join("%s %d" % (m["name"], len(m["parts"])) for m in models) + " -> " + OUT_JSON)
