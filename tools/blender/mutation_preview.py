# tools/blender/mutation_preview.py - previews LAWYER MUTATIONS (2026-10-13, user: "recolor the entire lawyer model to
# match the mutation ... making sure their distinct body parts can be seen and it doesn't all blend into itself").
# Builds a few lawyers from tools/zones/lawyers_top.json in a grid - Normal / Shiny / Diamond / Cosmic - with the SAME
# recolour rule the game uses (ReplicatedStorage.Shared.MutationLook; keep the two in step), renders
# art/mutations/preview.png. Run it in Blender, or headless (`pip install bpy==5.2.2`, EGL_PLATFORM=surfaceless).
#
# The rule: the face stays as it is (on the Head only: eye whites, pupils, mouth, teeth, tongue, ink brows / nose).
# Every other colour of the lawyer is ranked darkest -> lightest and spread evenly along the mutation's ramp (half by
# rank, half by its real brightness), so parts that were different stay different - just in the new palette.
# Glowing (Neon) parts take the bright end of the ramp.
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    try:
        return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    except NameError:
        return r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"

REPO = find_repo()
SRC = os.path.join(REPO, "tools", "zones", "lawyers_top.json")
OUT_PNG = os.path.join(REPO, "art", "mutations", "preview.png")
SHOW = ["WolfWarden", "ChiliProsecutor", "HammerheadAdvocate", "PhoenixProsecutor"]

# ------------------------------------------------------------------ the rule (twin of Shared.MutationLook)
KEEP = {(251, 250, 246), (15, 15, 18), (90, 20, 25), (216, 74, 90), (28, 28, 32), (36, 36, 44)}  # face + outlines
RAMPS = {  # dark -> light; Config.Lawyers.Mutations[i].Ramp
    "Shiny": [(110, 62, 8), (205, 135, 18), (250, 188, 36), (255, 222, 88), (255, 248, 200)],
    "Diamond": [(18, 40, 95), (40, 110, 200), (90, 180, 240), (170, 230, 255), (240, 252, 255)],
    "Cosmic": [(18, 8, 40), (70, 25, 130), (140, 60, 220), (210, 120, 255), (255, 200, 250)],
}

def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

def ramp_at(stops, t):
    t = min(max(t, 0.0), 1.0) * (len(stops) - 1)
    i = min(int(t), len(stops) - 2)
    f = t - i
    a, b = stops[i], stops[i + 1]
    return tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))

FACE = ("Head", "HeadDetail")  # only the head keeps its face colours (an ink-coloured SUIT still gets recoloured)

def kept(p):
    return p["n"] in FACE and tuple(p["c"]) in KEEP

def recolor_map(parts, mutation):
    """{(rgb, neon?) -> new rgb} for one lawyer (parts where kept(p) are left alone)."""
    stops = RAMPS[mutation]
    out = {}
    for neon in (False, True):
        cols = sorted({tuple(p["c"]) for p in parts if (p["t"] == "neon") == neon and not kept(p)}, key=lum)
        if not cols:
            continue
        lo, hi = lum(cols[0]), lum(cols[-1])
        for i, c in enumerate(cols):
            by_rank = i / (len(cols) - 1) if len(cols) > 1 else 0.5
            by_lum = (lum(c) - lo) / (hi - lo) if hi > lo else 0.5
            t = 0.5 * by_rank + 0.5 * by_lum
            t = 0.7 + 0.3 * t if neon else 0.08 + 0.84 * t
            out[(c, neon)] = ramp_at(stops, t)
    return out

# ------------------------------------------------------------------ scene
sc = bpy.data.scenes.get("Mutations") or bpy.data.scenes.new("Mutations")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("Mutations") or bpy.data.collections.new("Mutations")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)

def mesh_box():
    m = bpy.data.meshes.new("MU_Box")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    m.from_pydata(v, [], [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
    return m
def mesh_cyl(n=24):  # along X, like Roblox
    m = bpy.data.meshes.new("MU_Cyl")
    v = [(x, 0.5 * math.cos(2 * math.pi * i / n), 0.5 * math.sin(2 * math.pi * i / n)) for x in (-0.5, 0.5) for i in range(n)]
    f = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    m.from_pydata(v, [], f)
    return m
def mesh_ball(n=16):
    m = bpy.data.meshes.new("MU_Ball")
    v, f = [], []
    for j in range(n + 1):
        th = math.pi * j / n
        for i in range(n):
            ph = 2 * math.pi * i / n
            v.append((0.5 * math.sin(th) * math.cos(ph), 0.5 * math.sin(th) * math.sin(ph), 0.5 * math.cos(th)))
    for j in range(n):
        for i in range(n):
            a, b = j * n + i, j * n + (i + 1) % n
            f.append((a, b, b + n, a + n))
    m.from_pydata(v, [], f)
    return m
def mesh_wedge():  # Roblox WedgePart: slope rising toward -Z (front low)... preview only
    m = bpy.data.meshes.new("MU_Wedge")
    v = [(-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5)]
    m.from_pydata(v, [], [(0, 1, 3, 2), (2, 3, 5, 4), (0, 2, 4), (1, 5, 3), (0, 4, 5, 1)])
    return m
MESH = dict(box=mesh_box(), cyl=mesh_cyl(), ball=mesh_ball(), wedge=mesh_wedge())

data = json.load(open(SRC))
MUTS = ["Normal", "Shiny", "Diamond", "Cosmic"]
GAP_X, GAP_Y = 9.0, 11.0
for row, lid in enumerate(SHOW):
    model = data[lid]
    for col, mut in enumerate(MUTS):
        remap = recolor_map(model["parts"], mut) if mut != "Normal" else {}
        ox, oz = -col * GAP_X, -row * GAP_Y  # (seen from the front: -X is the viewer's right)
        for p in model["parts"]:
            o = bpy.data.objects.new("P", MESH.get(p["k"], MESH["box"]))
            # Roblox (x, y up, z) -> Blender (x, -z, y); rotation: R_b = M^T R M with M = (x,y,z)->(x,z,-y)
            r = p["r"]
            R = [[r[0], r[1], r[2]], [r[3], r[4], r[5]], [r[6], r[7], r[8]]]
            M = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
            MT = [[M[j][i] for j in range(3)] for i in range(3)]
            RB = [[sum(MT[i][k] * sum(R[k][l] * M[l][j] for l in range(3)) for k in range(3)) for j in range(3)] for i in range(3)]
            from mathutils import Matrix, Vector
            mat = Matrix(RB).to_4x4()
            mat.translation = Vector((p["p"][0] + ox, -p["p"][2], p["p"][1] + oz))
            o.matrix_world = mat @ Matrix.Diagonal((p["s"][0], p["s"][2], p["s"][1], 1))
            c = tuple(p["c"])
            nc = c if kept(p) else remap.get((c, p["t"] == "neon"), c)
            o.color = (nc[0] / 255, nc[1] / 255, nc[2] / 255, 1)
            coll.objects.link(o)

# ------------------------------------------------------------------ render (Workbench, object colours, outlines)
sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.world = sc.world or bpy.data.worlds.new("MU_World")
cam_data = bpy.data.cameras.new("MU_Cam")
cam = bpy.data.objects.new("MU_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam
cx, cz = -(len(MUTS) - 1) * GAP_X / 2, -(len(SHOW) - 1) * GAP_Y / 2 + 4
cam_data.type = "ORTHO"
cam_data.ortho_scale = max(len(SHOW) * GAP_Y, len(MUTS) * GAP_X * 1.08) * 1.02
tilt = math.radians(8)
# the lawyers face Roblox -Z = Blender +Y: look at them from +Y, straight on, a little from above
cam.rotation_euler = (math.radians(90) - tilt, 0, math.radians(180))
d = 80
cam.location = (cx, d * math.cos(tilt), cz + d * math.sin(tilt))
sc.render.resolution_x, sc.render.resolution_y = 1300, 1400
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print("mutation preview ->", OUT_PNG)
