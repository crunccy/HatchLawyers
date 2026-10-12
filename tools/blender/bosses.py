# tools/blender/bosses.py - the zone bosses (docs/BOSSES.md), brick style: every block becomes a studded Part.
# Built 2026-10-12 for the two zones that exist: The Senior Partner (Briefcase Bay) and Barrister Bulldog (Pet Park).
# Each block belongs to a GROUP (Torso, Head, ArmL, ...) that the client animates around the group's JOINT; groups
# can hang off another group (Head off Torso). Exports tools/zones/bosses.json for tools/zones/BuildBosses.lua and
# renders art/bosses/preview.png. Run inside Blender: tools/blender/send.ps1 -File tools/blender/bosses.py
# Works in its own scene "Bosses". Units: 1 Blender m = 1 stud; feet on z = 0; bosses FACE +Y (= Roblox -Z).
import bpy, math, json, os

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
OUT_JSON = os.path.join(REPO, "tools", "zones", "bosses.json")
OUT_PNG = os.path.join(REPO, "art", "bosses", "preview.png")

sc = bpy.data.scenes.get("Bosses") or bpy.data.scenes.new("Bosses")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)

me = bpy.data.meshes.get("BS_Cube")
if me is None:
    me = bpy.data.meshes.new("BS_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

P = None  # the boss being built
GROUP = "Torso"  # the group new blocks go into


def box(name, cx, cy, z0, sx, sy, sz, col, rx=0.0, ry=0.0, rz=0.0, tag=""):
    """A block whose bottom sits at z0 (centre cx, cy), in the current GROUP."""
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    o["tag"] = tag
    o["group"] = GROUP
    sc.collection.objects.link(o)
    o.parent = P
    return o


def eyes(x, y, z0, s, gap):
    """Square black eyes with a white glint (the cast's eye style)."""
    for sx in (-1, 1):
        box("Eye", sx * gap, y, z0, s, 0.1, s, (24, 24, 30), tag="nocollide")
        box("Glint", sx * gap + s * 0.22, y + 0.03, z0 + s * 0.55, s * 0.3, 0.06, s * 0.3, (255, 255, 255), tag="nocollide")


MODELS = {}  # name -> dict(groups=..., height=...)

# ======================================================================== The Senior Partner (Briefcase Bay)
SUIT, SUIT2, VEST, SHIRT, TIE = (58, 58, 68), (46, 46, 54), (112, 112, 124), (248, 248, 248), (190, 40, 44)
SKIN, SKIN2, HAIR, WHITE, GOLD = (240, 200, 160), (222, 170, 132), (168, 168, 178), (246, 246, 246), (232, 190, 60)
LEATHER, LEATHER2, SHOE = (124, 74, 38), (92, 54, 28), (30, 30, 36)

P = bpy.data.objects.new("SeniorPartner", None)
sc.collection.objects.link(P)
P.location = (-5, 0, 0)
groups = {}

for side, g in ((-1, "LegL"), (1, "LegR")):
    GROUP = g
    groups[g] = dict(joint=(side * 0.85, 0, 4.2), parent="")
    box("Shoe", side * 0.85, 0.25, 0, 1.35, 2.1, 0.6, SHOE)
    box("Leg", side * 0.85, 0, 0.6, 1.3, 1.3, 3.7, SUIT2)

GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, 4.2), parent="")
box("Hips", 0, 0, 4.0, 3.4, 2.2, 0.8, SUIT2)
box("Jacket", 0, 0, 4.4, 4.0, 2.4, 3.2, SUIT)
box("Belly", 0, 1.2, 4.6, 3.2, 0.5, 2.0, SUIT)
box("Vest", 0, 1.46, 4.9, 1.8, 0.1, 2.5, VEST, tag="nocollide")
box("Shirt", 0, 1.5, 6.0, 0.8, 0.1, 1.5, SHIRT, tag="nocollide")
box("Tie", 0, 1.55, 5.2, 0.36, 0.1, 2.1, TIE, tag="nocollide")
box("TieKnot", 0, 1.57, 7.05, 0.5, 0.12, 0.35, TIE, tag="nocollide")
for i in range(3):
    box("Button", 0.6, 1.53, 5.1 + i * 0.55, 0.18, 0.08, 0.18, GOLD, tag="nocollide")
box("WatchChain", -0.45, 1.53, 5.6, 0.9, 0.06, 0.08, GOLD, rz=0, ry=-12, tag="nocollide")
box("PocketSquare", -1.4, 1.22, 6.6, 0.5, 0.1, 0.35, WHITE, tag="nocollide")
for side in (-1, 1):
    box("Lapel", side * 1.15, 1.25, 5.9, 0.5, 0.1, 1.6, SUIT2, ry=side * 18, tag="nocollide")
box("Neck", 0, 0, 7.55, 1.3, 1.3, 0.35, SKIN)

GROUP = "Head"
groups["Head"] = dict(joint=(0, 0, 7.7), parent="Torso")
box("Head", 0, 0.1, 7.8, 3.0, 2.8, 2.8, SKIN)
box("HairBack", 0, -1.35, 8.3, 3.1, 0.35, 1.7, HAIR)
for side in (-1, 1):
    box("HairSide", side * 1.55, -0.2, 8.4, 0.35, 2.2, 1.3, HAIR)
    box("Ear", side * 1.6, 0.3, 8.6, 0.25, 0.6, 0.8, SKIN2)
box("CombOver", 0.3, -0.1, 10.55, 2.5, 1.9, 0.22, HAIR, rx=0, ry=-7)
eyes(0, 1.52, 8.95, 0.45, 0.65)
for side in (-1, 1):
    # bushy grumpy brows (inner ends down) and half-moon glasses (only the lower rims)
    box("Brow", side * 0.7, 1.55, 9.55, 0.95, 0.16, 0.26, WHITE, ry=side * -12, tag="nocollide")
    box("GlassRim", side * 0.65, 1.58, 8.78, 0.85, 0.08, 0.1, GOLD, tag="nocollide")
    box("GlassSide", side * 1.1, 1.58, 8.78, 0.08, 0.08, 0.45, GOLD, tag="nocollide")
box("GlassBridge", 0, 1.58, 9.05, 0.45, 0.08, 0.08, GOLD, tag="nocollide")
box("Nose", 0, 1.7, 8.35, 0.55, 0.5, 0.6, SKIN2)
box("Moustache", 0, 1.68, 7.95, 1.7, 0.4, 0.5, WHITE)
for side in (-1, 1):
    box("MoustacheDroop", side * 0.95, 1.62, 7.6, 0.55, 0.38, 0.75, WHITE, ry=side * 10)

for side, g in ((-1, "ArmL"), (1, "ArmR")):
    GROUP = g
    groups[g] = dict(joint=(side * 2.55, 0, 7.1), parent="Torso")
    box("Sleeve", side * 2.6, 0, 4.6, 1.1, 1.25, 3.0, SUIT)
    box("Cuff", side * 2.6, 0, 4.35, 1.16, 1.3, 0.28, SHIRT)
    box("Hand", side * 2.6, 0, 3.45, 1.0, 1.0, 0.9, SKIN)
GROUP = "ArmL"  # the pocket watch he keeps checking
box("Watch", -2.6, 0.62, 3.6, 0.65, 0.16, 0.65, GOLD)
box("WatchFace", -2.6, 0.71, 3.7, 0.45, 0.04, 0.45, WHITE, tag="nocollide")
GROUP = "ArmR"  # the huge battered briefcase, hanging from his hand by its handle
box("CaseHandle", 2.6, 0, 3.3, 0.35, 1.2, 0.2, LEATHER2)
for sy in (-1, 1):
    box("CaseHandlePost", 2.6, sy * 0.5, 3.05, 0.3, 0.2, 0.35, LEATHER2)
box("Case", 2.7, 0, 0.35, 1.1, 4.2, 2.75, LEATHER)
box("CaseBand", 2.7, 0, 2.35, 1.16, 4.26, 0.16, LEATHER2)
box("CasePatch", 3.27, -1.0, 0.8, 0.06, 1.0, 0.75, (150, 96, 52), tag="nocollide")
box("CaseStrap", 3.27, 0.9, 0.35, 0.06, 0.35, 2.75, LEATHER2, tag="nocollide")
for sy in (-1, 1):
    box("CaseClasp", 3.29, sy * 1.1, 2.2, 0.08, 0.42, 0.36, GOLD, tag="nocollide")
    box("CaseCorner", 3.28, sy * 1.92, 0.35, 0.07, 0.36, 0.36, GOLD, tag="nocollide")
    box("CaseCornerTop", 3.28, sy * 1.92, 2.74, 0.07, 0.36, 0.36, GOLD, tag="nocollide")

GROUP = "Papers"  # sheets swirling round his ankles (the client spins this group)
groups["Papers"] = dict(joint=(0, 0, 0.3), parent="")
for i in range(6):
    a = i * math.tau / 6 + 0.3
    r = 2.6 + (i % 2) * 0.5
    box("Paper", math.cos(a) * r, math.sin(a) * r, 0.25 + (i % 3) * 0.35, 0.9, 1.15, 0.05, WHITE,
        rx=20 + i * 9, ry=-15 + i * 11, rz=math.degrees(a), tag="nocollide")
MODELS["SeniorPartner"] = dict(root=P, groups=groups, height=10.8)

# ======================================================================== Barrister Bulldog (Pet Park)
FAWN, FAWN2, CREAM, ROBE, WIG, NOSE, EAR, RED = (214, 168, 110), (190, 140, 88), (248, 238, 220), (36, 36, 46), (250, 250, 250), (30, 26, 30), (112, 72, 42), (210, 40, 46)
P = bpy.data.objects.new("BarristerBulldog", None)
sc.collection.objects.link(P)
P.location = (5, 0, 0)
groups = {}

for g, x, y in (("LegFL", -1.65, 1.7), ("LegFR", 1.65, 1.7), ("LegBL", -1.65, -2.4), ("LegBR", 1.65, -2.4)):
    GROUP = g
    groups[g] = dict(joint=(x, y, 1.9), parent="")
    box("Leg", x, y, 0.35, 1.25, 1.25, 1.6, FAWN)
    box("Paw", x, y + 0.15, 0, 1.4, 1.55, 0.4, CREAM)

GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, 3.4), parent="")
box("Body", 0, -0.35, 1.8, 4.6, 6.0, 3.3, FAWN)
box("Chest", 0, 2.66, 2.0, 3.4, 0.3, 2.5, CREAM)
box("Belly", 0, -0.2, 1.6, 3.4, 4.6, 0.3, CREAM)
box("RobeTop", 0, -0.9, 5.05, 5.0, 4.9, 0.4, ROBE)
for side in (-1, 1):
    box("RobeSide", side * 2.45, -0.9, 2.3, 0.3, 5.1, 2.9, ROBE)
    box("RobeSleeve", side * 2.4, 1.7, 2.4, 0.35, 1.4, 2.6, ROBE)
box("RobeBack", 0, -3.45, 2.1, 5.0, 0.3, 3.3, ROBE)
for side in (-1, 1):
    box("Band", side * 0.24, 2.86, 2.55, 0.38, 0.1, 0.85, WIG, tag="nocollide")  # barrister's bands
    box("BowWing", side * 0.62, 2.88, 3.55, 0.75, 0.24, 0.65, RED, ry=side * 10)
box("BowKnot", 0, 2.92, 3.62, 0.42, 0.3, 0.5, RED)

GROUP = "Head"
groups["Head"] = dict(joint=(0, 2.4, 4.6), parent="Torso")
box("Head", 0, 3.7, 3.5, 4.2, 3.2, 3.3, FAWN)
box("Muzzle", 0, 5.55, 3.55, 2.9, 0.9, 1.6, CREAM)
box("Nose", 0, 6.05, 4.7, 1.05, 0.4, 0.6, NOSE)
for side in (-1, 1):
    box("Jowl", side * 1.5, 5.2, 3.1, 1.05, 1.5, 1.5, FAWN2)
    box("Tooth", side * 0.6, 6.06, 3.85, 0.32, 0.12, 0.35, WIG, tag="nocollide")
    box("Drool", side * 1.5, 5.6, 2.75, 0.2, 0.2, 0.4, WIG, tag="nocollide")
    box("Ear", side * 2.0, 2.9, 6.3, 0.9, 0.55, 0.9, EAR, ry=side * 25)
for i in range(2):
    box("Wrinkle", 0, 5.32, 6.1 + i * 0.28, 2.4 - i * 0.6, 0.08, 0.13, FAWN2, tag="nocollide")
eyes(0, 5.33, 5.4, 0.55, 1.0)
# the curly barrister's wig: rows of white curls over the top (alternate rows sit higher, so it reads curly), and
# rolls down each side and at the back
box("WigCap", 0, 3.5, 6.75, 3.6, 2.8, 0.3, WIG)
for row in range(4):
    for col in range(5):
        box("WigTopCurl", -1.6 + col * 0.8, 2.35 + row * 0.78, 6.95 + (0.14 if (row + col) % 2 == 0 else 0), 0.74, 0.74, 0.5, WIG)
for side in (-1, 1):
    for row in range(3):
        for col in range(2):
            box("WigCurl", side * 2.25, 2.7 + col * 0.75, 5.0 + row * 0.62, 0.62, 0.62, 0.62, WIG)
for col in range(4):
    box("WigBackCurl", -1.2 + col * 0.8, 2.05, 5.5, 0.66, 0.6, 0.66, WIG)

GROUP = "Tail"
groups["Tail"] = dict(joint=(0, -3.4, 4.3), parent="Torso")
box("Tail", 0, -3.75, 4.05, 0.6, 0.8, 0.6, FAWN, rx=30)
MODELS["BarristerBulldog"] = dict(root=P, groups=groups, height=7.4)


# ------------------------------------------------------------------ export (Blender (x, y, z) -> Roblox (x, z, -y))
def to_rbx_vec(v):
    return [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]


Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
data = {}
for name, d in MODELS.items():
    parts = []
    for o in d["root"].children:
        R = o.rotation_euler.to_matrix()
        R = [[R[i][j] for j in range(3)] for i in range(3)]
        MR = [[sum(Mx[i][k] * R[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
        Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
        s = o.scale
        parts.append(dict(n=o.name.split(".")[0], g=o["group"], p=to_rbx_vec(o.location),
                          s=[round(abs(s[0]), 4), round(abs(s[2]), 4), round(abs(s[1]), 4)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"]))
    data[name] = dict(height=d["height"], parts=parts,
                      groups={g: dict(joint=to_rbx_vec(v["joint"]), parent=v["parent"]) for g, v in d["groups"].items()})
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))

# ------------------------------------------------------------------ preview: both bosses from the front-left, a player-sized block for scale
GROUP = ""
P = bpy.data.objects.new("Scale", None)
sc.collection.objects.link(P)
box("PlayerForScale", 0, 3.5, 0, 2, 1, 5, (98, 205, 48))
cam_data = bpy.data.cameras.get("BS_Cam") or bpy.data.cameras.new("BS_Cam")
cam = bpy.data.objects.new("BS_Cam", cam_data)
sc.collection.objects.link(cam)
target = (0, 0, 4.5)
cam.location = (-10, 26, 11)
dx, dy, dz = target[0] - cam.location[0], target[1] - cam.location[1], target[2] - cam.location[2]
cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
cam_data.lens = 38
sc.camera = cam
sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.display.shading.show_shadows = True
sc.render.resolution_x, sc.render.resolution_y = 1400, 900
sc.world = sc.world or bpy.data.worlds.new("BS_World")
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"{len(data)} bosses, " + ", ".join(f"{k}: {len(v['parts'])} blocks / {len(v['groups'])} groups" for k, v in data.items()) + f" -> {OUT_JSON}")
