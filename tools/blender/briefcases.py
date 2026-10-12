# tools/blender/briefcases.py - the Carry upgrade's briefcases (2026-10-12, user's call: "an upgrade that means you
# can carry more eggs, like a briefcase"). One brick model per tier (Config.Zones.Carry[n].Model), worn on the
# player's back by StarterPlayerScripts.CarryPose. Exports tools/zones/briefcases.json for
# tools/zones/BuildBriefcases.lua (every block becomes a studded Part, like the zone decorations) and renders
# art/briefcases/preview.png. Run inside Blender: tools/blender/send.ps1 -File tools/blender/briefcases.py
# Works in its own scene "Briefcases". Units: 1 Blender m = 1 stud.
# Model space: width along X (centred), the bottom on z = 0, the side that touches the player's back on y = 0 and
# the body going toward -y (= Roblox +Z, away from the back), so the clasps face out behind the player.
import bpy, math, json, os

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
OUT_JSON = os.path.join(REPO, "tools", "zones", "briefcases.json")
OUT_PNG = os.path.join(REPO, "art", "briefcases", "preview.png")

sc = bpy.data.scenes.get("Briefcases") or bpy.data.scenes.new("Briefcases")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)

me = bpy.data.meshes.get("BC_Cube")
if me is None:
    me = bpy.data.meshes.new("BC_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()


def box(P, name, cx, cy, z0, sx, sy, sz, col, rx=0.0, ry=0.0, rz=0.0, tag=""):
    """A block whose bottom sits at z0 (centre cx, cy)."""
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    o["tag"] = tag
    sc.collection.objects.link(o)
    o.parent = P
    return o


WHITE, GOLD = (248, 248, 248), (255, 200, 40)
# name, width, height, thickness, body, band (+ handle), metal (clasps), corner caps, front piece
TIERS = [
    dict(name="Briefcase", w=1.4, h=1.0, t=0.42, body=(150, 88, 44), band=(100, 58, 28), metal=GOLD, caps=None, front="plaque"),
    dict(name="BigBriefcase", w=1.7, h=1.2, t=0.5, body=(196, 54, 54), band=(122, 30, 34), metal=GOLD, caps=GOLD, front="plaque"),
    dict(name="GoldenBriefcase", w=1.8, h=1.3, t=0.54, body=GOLD, band=WHITE, metal=WHITE, caps=WHITE, front="star"),
    dict(name="DiamondBriefcase", w=1.9, h=1.4, t=0.58, body=(120, 210, 255), band=WHITE, metal=WHITE, caps=WHITE, front="gem"),
]


def build(P, d):
    w, h, t = d["w"], d["h"], d["t"]
    out = -t  # the outer face (y)
    box(P, "Body", 0, -t / 2, 0, w, t, h, d["body"])
    band_z = h * 0.58
    box(P, "Band", 0, -t / 2, band_z - 0.05, w + 0.06, t + 0.06, 0.1, d["band"])
    for sx in (-1, 1):
        # clasps on the band, facing out
        box(P, "Clasp", sx * w * 0.27, out - 0.04, band_z - 0.1, 0.2, 0.1, 0.2, d["metal"])
        # handle posts on top
        box(P, "HandlePost", sx * w * 0.17, -t / 2, h, 0.12, 0.16, 0.18, d["band"])
        if d["caps"]:
            for z0 in (0.02, h - 0.24):
                box(P, "Corner", sx * (w / 2 - 0.1), out - 0.02, z0, 0.22, 0.08, 0.22, d["caps"], tag="nocollide")
    box(P, "Handle", 0, -t / 2, h + 0.16, w * 0.34 + 0.12, 0.16, 0.12, d["band"])
    fz = h * 0.2
    if d["front"] == "plaque":
        box(P, "Plaque", 0, out - 0.02, fz, w * 0.24, 0.06, h * 0.18, d["metal"], tag="nocollide")
    elif d["front"] == "star":
        # a glowing 4-point star: two crossed bars, one turned 45 degrees
        box(P, "Star", 0, out - 0.03, fz, 0.42, 0.06, 0.12, (255, 246, 190), tag="neon")
        box(P, "Star", 0, out - 0.03, fz - 0.15, 0.12, 0.06, 0.42, (255, 246, 190), tag="neon")
        box(P, "StarTilt", 0, out - 0.035, fz + 0.06 - 0.15, 0.2, 0.06, 0.2, (255, 246, 190), ry=45, tag="neon")
    else:
        # a diamond: a cube turned 45 degrees on its face, glowing
        box(P, "Gem", 0, out - 0.06, fz - 0.05, 0.32, 0.12, 0.32, (160, 240, 255), ry=45, tag="neon")
        box(P, "GemSetting", 0, out - 0.02, fz - 0.02, 0.5, 0.06, 0.06, WHITE, tag="nocollide")


roots = {}
for i, d in enumerate(TIERS):
    P = bpy.data.objects.new(d["name"], None)
    sc.collection.objects.link(P)
    P.location = (i * 3.0, 0, 0)
    build(P, d)
    roots[d["name"]] = (P, d)


# ------------------------------------------------------------------ export (Roblox: Y up; Blender (x, y, z) -> Roblox (x, z, -y))
def to_rbx_vec(v):
    return [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]


Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
data = {}
for name, (P, d) in roots.items():
    parts = []
    for o in P.children:
        R = o.rotation_euler.to_matrix()
        R = [[R[i][j] for j in range(3)] for i in range(3)]
        MR = [[sum(Mx[i][k] * R[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
        Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
        s = o.scale
        parts.append(dict(n=o.name.split(".")[0], p=to_rbx_vec(o.location), s=[round(abs(s[0]), 4), round(abs(s[2]), 4), round(abs(s[1]), 4)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"]))
    data[name] = dict(size=[d["w"], d["h"] + 0.28, d["t"]], parts=parts)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))

# ------------------------------------------------------------------ preview: the four tiers from behind-left (the side people see)
cam_data = bpy.data.cameras.get("BC_Cam") or bpy.data.cameras.new("BC_Cam")
cam = bpy.data.objects.new("BC_Cam", cam_data)
sc.collection.objects.link(cam)
target = (4.5, 0, 0.7)
cam.location = (target[0] - 2.5, target[1] - 13, 4.5)
dx, dy, dz = target[0] - cam.location[0], target[1] - cam.location[1], target[2] - cam.location[2]
cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
cam_data.lens = 40
sc.camera = cam
sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.render.resolution_x, sc.render.resolution_y = 1400, 600
sc.world = sc.world or bpy.data.worlds.new("BC_World")
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"{len(data)} briefcases, {sum(len(v['parts']) for v in data.values())} blocks -> {OUT_JSON}; preview {OUT_PNG}")
