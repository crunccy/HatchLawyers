# tools/blender/lane_preview.py - renders the egg-zone lane (exported from Studio as JSON part lists) from the same
# angles as the reference shots and saves side-by-side comparisons. For when Studio's viewport can't be captured.
# Input: EXPORT_DIR/lane_parts_*.json ({p, s, r (row-major 3x3), c, t, m, sh}) and lane_spots.json (Roblox coords).
# Output: art/zone_decor/lane_view_<n>.png and art/zone_decor/compare_<n>.png (reference left, ours right).
# Works in its own scene "LanePreview"; never touches the other scenes. Roblox (x, y, z) -> Blender (x, -z, y).
import bpy, bmesh, math, json, os, glob, random
import numpy as np
from mathutils import Matrix, Vector

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
EXPORT_DIR = r"C:\Users\siddi\AppData\Local\Temp\claude\lane_export"
OUT = os.path.join(REPO, "art", "zone_decor")
os.makedirs(OUT, exist_ok=True)

sc = bpy.data.scenes.get("LanePreview") or bpy.data.scenes.new("LanePreview")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("LanePreview") or bpy.data.collections.new("LanePreview")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)

def mesh_from(name, verts, faces):
    m = bpy.data.meshes.get(name)
    if m is None:
        m = bpy.data.meshes.new(name)
        m.from_pydata(verts, [], faces)
        m.update()
    return m

CUBE = mesh_from("LP_Cube", [(x, y, z) for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)],
                 [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
def make_sphere():
    m = bpy.data.meshes.get("LP_Ball")
    if m:
        return m
    m = bpy.data.meshes.new("LP_Ball")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.5)
    bm.to_mesh(m)
    bm.free()
    return m
def make_cyl():  # Roblox cylinders run along local X
    m = bpy.data.meshes.get("LP_Cyl")
    if m:
        return m
    m = bpy.data.meshes.new("LP_Cyl")
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.5, radius2=0.5, depth=1.0)
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, 'Y'))
    bm.to_mesh(m)
    bm.free()
    return m
# Roblox wedge in Blender local axes (X, Y = Roblox -Z, Z = Roblox Y): full height at the back (Roblox +Z = Blender -Y)
WEDGE = mesh_from("LP_Wedge", [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, .5, -.5), (-.5, .5, -.5), (-.5, -.5, .5), (.5, -.5, .5)],
                  [(0, 1, 2, 3), (0, 4, 5, 1), (3, 2, 5, 4), (0, 3, 4), (1, 5, 2)])
BALL, CYL = make_sphere(), make_cyl()

N = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender
def add_part(d):
    if d["t"] >= 0.3:
        return  # see-through bits (gate barriers, glass) are left out of the preview
    mesh = {"Ball": BALL, "Cylinder": CYL, "Wedge": WEDGE}.get(d["sh"], CUBE)
    o = bpy.data.objects.new("P", mesh)
    r = d["r"]
    R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
    Rb = N @ R @ N.transposed()
    p = Vector(d["p"])
    pb = Vector((p.x, -p.z, p.y))
    s = d["s"]
    o.matrix_world = Matrix.Translation(pb) @ Rb.to_4x4() @ Matrix.Diagonal((s[0], s[2], s[1], 1))
    c = d["c"]
    bright = 1.25 if d["m"] == "Neon" else 1.0
    o.color = (min(1, c[0] / 255 * bright), min(1, c[1] / 255 * bright), min(1, c[2] / 255 * bright), 1)
    coll.objects.link(o)

count = 0
for f in sorted(glob.glob(os.path.join(EXPORT_DIR, "lane_parts_*.json"))):
    for d in json.load(open(f)):
        add_part(d)
        count += 1

# ------------------------------------------------------------------ eggs where the game spawns them (14 per zone, like Config)
def txt(body, loc, rot, size, col):
    cu = bpy.data.curves.new("T", "FONT")
    cu.body = body
    cu.size = size
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.extrude = 0.02
    o = bpy.data.objects.new("Text", cu)
    o.location = loc
    o.rotation_euler = rot
    o.color = (*[x / 255 for x in col], 1)
    coll.objects.link(o)
    return o

spots = json.load(open(os.path.join(EXPORT_DIR, "lane_spots.json")))
rng = random.Random(3)
eggs = []
for zone in ("BriefcaseBay", "PetPark"):
    zs = [s for s in spots if s["z"] == zone]
    rng.shuffle(zs)
    for i, s in enumerate(zs[:14]):
        golden = i == 0
        size = (2.8, 3.5) if golden else (2.3, 2.9)
        col = (255, 205, 40) if golden else ((245, 200, 70) if zone == "BriefcaseBay" else (255, 180, 110))
        x, y, z = s["p"]
        o = bpy.data.objects.new("Egg", BALL)
        o.location = (x, -z, y + size[1] / 2)
        o.scale = (size[0], size[0], size[1])
        o.color = (*[v / 255 for v in col], 1)
        coll.objects.link(o)
        if zone == "BriefcaseBay":
            b = bpy.data.objects.new("Band", BALL)
            b.location = (x, -z, y + size[1] / 2 - 0.2)
            b.scale = (size[0] * 1.03, size[0] * 1.03, 0.6)
            b.color = (150 / 255, 88 / 255, 44 / 255, 1)
            coll.objects.link(b)
        name = ("Golden " if golden else "") + ("Briefcase Egg" if zone == "BriefcaseBay" else "Pet Egg")
        eggs.append((Vector((x, -z, y + size[1] + 1.3)), name, "Rare" if golden else "Common"))

# ------------------------------------------------------------------ the painted-on text the parts export can't carry
txt("SAFE ZONE", (-268.5, 0, 0.2), (0, 0, math.radians(90)), 5.0, (255, 255, 255))
for x, title, sub in ((-673.6, "PET PARK", "Bronze License  ·  5M"), (-1085.6, "BRAINROT", "Silver License  ·  COMING SOON")):
    txt(title, (x, 0, 25.6), (math.radians(90), 0, math.radians(90)), 3.2, (255, 214, 60))
    txt(sub, (x, 0, 22.2), (math.radians(90), 0, math.radians(90)), 1.9, (255, 255, 255))

# ------------------------------------------------------------------ camera, render settings
cam_data = bpy.data.cameras.get("LP_Cam") or bpy.data.cameras.new("LP_Cam")
cam = bpy.data.objects.new("LP_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.display.shading.show_shadows = True
sc.display.shading.shadow_intensity = 0.35
sc.view_settings.view_transform = "Standard"
sc.world = sc.world or bpy.data.worlds.new("LP_World")
sc.world.color = (0.55, 0.78, 0.98)
sc.render.resolution_x = 1280
sc.render.resolution_y = 800

def rbx(x, y, z):
    return Vector((x, -z, y))

label_objs = []
def place_labels(cam_pos):
    for o in label_objs:
        bpy.data.objects.remove(o, do_unlink=True)
    label_objs.clear()
    for (pos, name, rarity) in eggs:
        if (pos - cam_pos).length > 140:
            continue
        d = cam_pos - pos
        yaw = math.atan2(d.y, d.x) + math.pi / 2  # face the camera
        label_objs.append(txt(name, pos + Vector((0, 0, 0.45)), (math.radians(90), 0, yaw), 0.75, (255, 255, 255)))
        label_objs.append(txt(rarity, pos - Vector((0, 0, 0.45)), (math.radians(90), 0, yaw), 0.7,
                              (33, 150, 243) if rarity == "Rare" else (158, 158, 158)))

VIEWS = [
    # (name, reference image, camera (Roblox coords), look-at (Roblox coords), lens)
    ("safezone", "zones-ref-forest-eggs.webp", (-247, 13, 6), (-330, 2, 0), 20),
    ("lane", "zones-ref-desert-lane.webp", (-560, 32, 0), (-780, 2, 0), 20),
    ("gate", "zones-ref-snow-lane.webp", (-640, 24, 4), (-820, 3, 0), 20),
    ("base", "zones-ref-base-safezone.webp", (-205, 55, 40), (-300, 0, 0), 22),
]
outputs = []
for name, ref, cpos, look, lens in VIEWS:
    cp = rbx(*cpos)
    lp = rbx(*look)
    cam.location = cp
    d = lp - cp
    cam.rotation_euler = (math.atan2(math.hypot(d.x, d.y), -d.z), 0, math.atan2(d.y, d.x) - math.pi / 2)
    cam_data.lens = lens
    place_labels(cp)
    path = os.path.join(OUT, f"lane_view_{name}.png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True, scene=sc.name)
    # side by side: the reference (cropped to the game view) on the left, ours on the right, both 600 tall
    try:
        a = bpy.data.images.load(os.path.join(REPO, "references", ref), check_existing=False)
        b = bpy.data.images.load(path, check_existing=False)
        H = 600
        def to_np(img):
            w, h = img.size
            nw = int(w * H / h)
            img.scale(nw, H)
            return np.array(img.pixels[:], dtype=np.float32).reshape(H, nw, 4)
        A, B = to_np(a), to_np(b)
        gap = np.ones((H, 16, 4), dtype=np.float32)
        out = np.concatenate([A, gap, B], axis=1)
        img = bpy.data.images.new(f"cmp_{name}", out.shape[1], H, alpha=True)
        img.pixels = out.ravel()
        img.filepath_raw = os.path.join(OUT, f"compare_{name}.png")
        img.file_format = "PNG"
        img.save()
        outputs.append(f"compare_{name}.png")
        for im in (a, b, img):
            bpy.data.images.remove(im)
    except Exception as e:
        outputs.append(f"{name}: compare failed ({e})")
print(f"{count} parts; " + ", ".join(outputs))
