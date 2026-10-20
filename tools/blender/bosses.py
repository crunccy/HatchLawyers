# tools/blender/bosses.py - the zone bosses (docs/BOSSES.md), brick style: every block becomes a studded Part.
# Built 2026-10-12 for the two zones that exist: The Senior Partner (Briefcase Bay) and Barrister Bulldog (Pet Park).
# Each block belongs to a GROUP (Torso, Head, ArmL, ...) that the client animates around the group's JOINT; groups
# can hang off another group (Head off Torso). Exports tools/zones/bosses.json for tools/zones/BuildBosses.lua and
# renders art/bosses/preview.png. Run inside Blender: tools/blender/send.ps1 -File tools/blender/bosses.py
# Works in its own scene "Bosses". Units: 1 Blender m = 1 stud; feet on z = 0; bosses FACE +Y (= Roblox -Z).
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


def disc(name, cx, cy, cz, r, thick, col, tag=""):
    """A blocky disc of radius r centred at (cx, cy, cz), facing +-y (rows of blocks)."""
    n = max(3, int(r * 2.5))
    step = 2 * r / n
    for i in range(n):
        u = -r + step * (i + 0.5)
        h = 2 * math.sqrt(max(0.0, r * r - u * u))
        box(name, cx + u, cy, cz - h / 2, step + 0.02, thick, h, col, tag=tag)


# ======================================================================== Judge Martello (Brainrot Boulevard)
# a walking giant wooden gavel: the hammer head is the body, a face on its front, a tiny judge's collar, two little
# arms; the handle splits into two legs in black shoes. Very brainrot. It HOPS.
WOOD, WOOD2, BLACK = (196, 126, 62), (150, 92, 46), (30, 30, 36)
P = bpy.data.objects.new("JudgeMartello", None)
sc.collection.objects.link(P)
P.location = (15, 0, 0)
groups = {}
for side, g in ((-1, "LegL"), (1, "LegR")):
    GROUP = g
    groups[g] = dict(joint=(side * 0.6, 0, 2.0), parent="")
    box("Shoe", side * 0.6, 0.2, 0, 1.0, 1.5, 0.45, BLACK)
    box("Leg", side * 0.6, 0, 0.45, 0.7, 0.7, 1.6, WOOD2)
GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, 2.0), parent="")
box("Handle", 0, 0, 1.9, 1.0, 1.0, 0.7, WOOD2)
box("Head", 0, 0, 2.5, 6.0, 3.0, 3.0, WOOD)
for sx in (-1, 1):
    box("Band", sx * 2.2, 0, 2.45, 0.45, 3.1, 3.1, GOLD)
    box("EndCap", sx * 2.95, 0, 2.6, 0.2, 2.6, 2.8, WOOD2)
eyes(0, 1.55, 4.0, 0.55, 0.85)
for sx in (-1, 1):
    box("Brow", sx * 0.85, 1.56, 4.75, 0.9, 0.12, 0.22, BLACK, ry=sx * -15, tag="nocollide")  # (inner ends down: cross)
box("Mouth", 0, 1.56, 3.35, 1.3, 0.1, 0.22, BLACK, tag="nocollide")
box("Collar", 0, 1.56, 2.5, 1.8, 0.1, 0.35, BLACK, tag="nocollide")
for sx in (-1, 1):
    box("Jabot", sx * 0.22, 1.6, 2.0, 0.4, 0.1, 0.7, WHITE, tag="nocollide")
for side, g in ((-1, "ArmL"), (1, "ArmR")):
    GROUP = g
    groups[g] = dict(joint=(side * 3.15, 0, 4.2), parent="Torso")
    box("Sleeve", side * 3.3, 0, 2.9, 0.65, 0.65, 1.4, BLACK)
    box("Glove", side * 3.3, 0, 2.35, 0.7, 0.7, 0.6, WHITE)
MODELS["JudgeMartello"] = dict(root=P, groups=groups, height=5.6)

# ======================================================================== Prosecutor Big Cheese (Food Court)
# a giant wheel of cheese standing on its edge: holes, a smug face, a twirly moustache, a tiny prosecutor's tie, little
# arms holding a cocktail-stick sword with an olive on it. It ROLLS.
CHEESE, RIND, HOLE, OLIVE = (255, 204, 70), (232, 168, 40), (214, 150, 30), (110, 160, 50)
R = 3.2
P = bpy.data.objects.new("BigCheese", None)
sc.collection.objects.link(P)
P.location = (25, 0, 0)
groups = {}
GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, R), parent="")
disc("Rind", 0, 0, R, R, 1.9, RIND)
disc("Wheel", 0, 0, R, R - 0.25, 2.3, CHEESE)
for (x, z, s) in ((-1.9, 4.6, 0.6), (1.7, 1.6, 0.7), (-1.5, 1.4, 0.5), (2.1, 4.4, 0.45), (0.2, 1.0, 0.4), (-2.4, 3.0, 0.4)):
    for y in (1.16, -1.16):
        box("Hole", x, y, z, s, 0.06, s, HOLE, tag="nocollide")
eyes(0, 1.18, 3.85, 0.5, 0.75)
for sx in (-1, 1):
    box("Lid", sx * 0.75, 1.2, 4.25, 0.7, 0.08, 0.2, RIND, tag="nocollide")  # smug half-shut eyes
    box("Moustache", sx * 0.55, 1.22, 3.1, 0.9, 0.1, 0.22, BLACK, ry=sx * -12, tag="nocollide")
    box("MoustacheCurl", sx * 1.05, 1.22, 3.25, 0.22, 0.1, 0.35, BLACK, tag="nocollide")
box("Smirk", 0.25, 1.21, 2.7, 0.8, 0.08, 0.15, BLACK, ry=-10, tag="nocollide")
box("TieKnot", 0, 1.22, 2.15, 0.35, 0.1, 0.3, RED, tag="nocollide")
box("Tie", 0, 1.22, 1.35, 0.32, 0.1, 0.8, RED, tag="nocollide")
for side, g in ((-1, "ArmL"), (1, "ArmR")):
    GROUP = g
    groups[g] = dict(joint=(side * (R + 0.05), 0.3, R + 0.3), parent="Torso")
    box("Arm", side * (R + 0.3), 0.3, R - 1.1, 0.5, 0.5, 1.4, BLACK)
    box("Hand", side * (R + 0.3), 0.3, R - 1.55, 0.55, 0.55, 0.45, WHITE)
GROUP = "ArmR"
box("Stick", R + 0.3, 1.3, R - 1.4, 0.15, 2.6, 0.15, (220, 190, 140), rx=20)
box("Olive", R + 0.3, 2.4, R - 1.1, 0.6, 0.6, 0.6, OLIVE)
box("Pimento", R + 0.3, 2.72, R - 0.95, 0.25, 0.08, 0.25, RED, tag="nocollide")
MODELS["BigCheese"] = dict(root=P, groups=groups, height=2 * R)

# ======================================================================== Magistrate Megalodon (Ocean Shore)
# an enormous shark walking upright on stubby legs in a navy magistrate's robe with a gold chain of office; jagged
# teeth, little reading glasses, a gavel in one fin, a glowing lantern fish dangling from a badge. It CHARGES.
# v2 (2026-10-19, the attack-animation overhaul, docs/BOSS_ANIMATION.md): the body is split at the mouth line so the
# whole upper head HINGES open at the back (a real chomp: a mouth cavity with 3D teeth, cheek flaps keep the sides
# closed), and the dorsal
# Fin (with a FinGlow shell the client lights up), the Glasses, each Eye (they spin when dizzy), the Lure and the
# Cape (the robe's back panel) are groups of their own. The robe stops at the mouth line so nothing clips the hinge.
SHARK, SHARK2, BELLY, NAVY, GUM = (110, 132, 162), (90, 110, 140), (236, 238, 244), (30, 42, 92), (190, 50, 60)
GULLET, ELECTRIC = (110, 24, 40), (120, 220, 255)
P = bpy.data.objects.new("Megalodon", None)
sc.collection.objects.link(P)
P.location = (34, 0, 0)
groups = {}
for side, g in ((-1, "LegL"), (1, "LegR")):
    GROUP = g
    groups[g] = dict(joint=(side * 0.85, 0, 1.6), parent="")
    box("Foot", side * 0.85, 0.25, 0, 1.3, 1.7, 0.4, SHARK2)
    box("Leg", side * 0.85, 0, 0.4, 1.0, 1.0, 1.25, SHARK)
GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, 1.6), parent="")
# the mouth (v3, 2026-10-19, crnuch: "teeth 3D and inside its mouth"): a real cavity cut into the front (x +-1.2,
# 0.5 deep), red gums, a dark throat, and 3D teeth (diamond prisms half sunk into the gums) along both jaws
box("Body", 0, 0, 1.4, 3.3, 2.9, 3.2, SHARK)
box("JawBack", 0, -0.25, 4.6, 2.4, 2.4, 0.45, SHARK)
for sx in (-1, 1):
    box("CheekLow", sx * 1.425, 0, 4.6, 0.45, 2.9, 0.45, SHARK)
    box("GumSide", sx * 1.18, 1.2, 4.6, 0.04, 0.5, 0.45, GUM, tag="nocollide")
box("Throat", 0, 0.97, 4.6, 2.4, 0.04, 0.45, GULLET, tag="nocollide")
box("GumLow", 0, 1.2, 4.6, 2.4, 0.5, 0.05, GUM, tag="nocollide")
box("Gullet", 0, -0.2, 5.05, 2.7, 2.3, 0.03, GULLET, tag="nocollide")
box("Belly", 0, 1.46, 1.6, 2.4, 0.12, 3.0, BELLY, tag="nocollide")
for i in range(4):
    box("ToothBottom", -0.675 + i * 0.45, 1.22, 4.48, 0.34, 0.36, 0.34, WHITE, ry=45, tag="nocollide")
for sx in (-1, 1):
    box("RobeSide", sx * 1.72, 0, 1.4, 0.2, 3.0, 3.6, NAVY)
box("Chain", 0, 1.5, 3.7, 2.6, 0.1, 0.2, GOLD, tag="nocollide")
box("Medallion", 0, 1.55, 3.05, 0.7, 0.12, 0.7, GOLD, tag="nocollide")
box("Badge", -0.95, 1.52, 2.6, 0.45, 0.1, 0.45, GOLD, tag="nocollide")
GROUP = "Cape"
groups["Cape"] = dict(joint=(0, -1.52, 5.0), parent="Torso")
box("RobeBack", 0, -1.52, 1.4, 3.4, 0.2, 3.6, NAVY)  # (3.4 wide: swept-back fins clear it)
GROUP = "Lure"
groups["Lure"] = dict(joint=(-0.95, 1.7, 2.6), parent="Torso")
box("LureStalk", -0.95, 1.7, 1.85, 0.08, 0.08, 0.75, (60, 60, 70), tag="nocollide")
box("Lure", -0.95, 1.75, 1.45, 0.45, 0.45, 0.45, (120, 220, 255), tag="neon")
GROUP = "Head"
groups["Head"] = dict(joint=(0, -1.45, 5.05), parent="Torso")
box("Snout", 0, 0, 5.5, 3.3, 2.9, 0.9, SHARK)
box("JawTop", 0, -0.25, 5.05, 2.4, 2.4, 0.45, SHARK)
for sx in (-1, 1):
    box("CheekTop", sx * 1.425, 0, 5.05, 0.45, 2.9, 0.45, SHARK)
    box("GumSide", sx * 1.18, 1.2, 5.05, 0.04, 0.5, 0.45, GUM, tag="nocollide")
box("Throat", 0, 0.97, 5.05, 2.4, 0.04, 0.45, GULLET, tag="nocollide")
box("GumTop", 0, 1.2, 5.45, 2.4, 0.5, 0.05, GUM, tag="nocollide")
box("Palate", 0, -0.2, 5.02, 2.7, 2.3, 0.03, GULLET, tag="nocollide")
box("Head", 0, 0.1, 6.4, 2.7, 2.7, 1.1, SHARK)
box("Crown", 0, 0, 7.5, 1.8, 2.0, 0.5, SHARK)
for i in range(5):
    box("ToothTop", -0.9 + i * 0.45, 1.22, 5.27, 0.36, 0.36, 0.36, WHITE, ry=45, tag="nocollide")
# the cheeks (crnuch: "the top head still connected to the bottom when it yells"): a skin flap each side on the jaw
# hinge, turned by HALF the head's angle (the clips key it), so it fills the side gap whenever the mouth opens and
# hides inside the head + body when it's shut. 1.6 tall covers the gap up to a 0.5 rad jaw.
GROUP = "Cheek"
groups["Cheek"] = dict(joint=(0, -1.45, 5.05), parent="Torso")
for sx in (-1, 1):
    box("CheekFlap", sx * 1.55, -0.075, 4.25, 0.18, 2.75, 1.6, SHARK)
GROUP = "Head"
for side, g in ((-1, "EyeL"), (1, "EyeR")):
    GROUP = g
    groups[g] = dict(joint=(side * 0.85, 1.47, 6.225), parent="Head")
    box("Eye", side * 0.85, 1.47, 6.0, 0.45, 0.1, 0.45, (24, 24, 30), tag="nocollide")
    box("Glint", side * 0.85 + 0.099, 1.5, 6.2475, 0.135, 0.06, 0.135, (255, 255, 255), tag="nocollide")
GROUP = "Glasses"
groups["Glasses"] = dict(joint=(0, 1.52, 5.9), parent="Head")
for sx in (-1, 1):
    box("GlassRim", sx * 0.85, 1.52, 5.85, 0.75, 0.08, 0.1, GOLD, tag="nocollide")
box("GlassBridge", 0, 1.52, 5.87, 0.95, 0.06, 0.06, GOLD, tag="nocollide")
GROUP = "Fin"
groups["Fin"] = dict(joint=(0, -1.25, 6.0), parent="Head")
box("DorsalFin", 0, -1.3, 5.6, 0.45, 1.8, 1.8, SHARK2, rx=-35)
box("FinGlow", 0, -1.3, 5.5, 0.62, 2.0, 2.0, ELECTRIC, rx=-35, tag="glow")
GROUP = "Tail"
groups["Tail"] = dict(joint=(0, -1.4, 1.8), parent="Torso")
box("Tail", 0, -2.3, 0.9, 0.4, 1.8, 1.8, SHARK2, rx=30)
for side, g in ((-1, "ArmL"), (1, "ArmR")):
    GROUP = g
    groups[g] = dict(joint=(side * 1.75, 0.2, 5.0), parent="Torso")
    # (round 3, crnuch: "the fins are detached" - they used to tilt top-OUT, leaving the root ~0.3 off the body;
    # now the root sinks into the shoulder and the tip flares out, like a pectoral fin)
    box("Fin", side * 1.85, 0.2, 3.1, 0.35, 1.3, 2.0, SHARK2, ry=-side * 15)
GROUP = "ArmR"
box("GavelHandle", 2.15, 0.9, 2.7, 0.25, 1.6, 0.25, (122, 70, 34))
box("GavelHead", 2.15, 1.7, 2.45, 0.7, 0.7, 1.2, (150, 92, 46))
MODELS["Megalodon"] = dict(root=P, groups=groups, height=8.0)

# ======================================================================== Chief Justice Eclipse (Space Base)
# a tall robed judge whose face is an eclipse - a black disc with a blazing gold corona - in a deep purple robe with
# constellations, three gavels orbiting its head, floating a little off the ground. The coolest boss.
ROBE1, ROBE2, VOID, CORONA, STAR, GLOVE = (74, 42, 136), (56, 30, 108), (14, 14, 22), (255, 200, 60), (250, 250, 255), (40, 40, 52)
P = bpy.data.objects.new("Eclipse", None)
sc.collection.objects.link(P)
P.location = (44, 0, 0)
groups = {}
GROUP = "Torso"
groups["Torso"] = dict(joint=(0, 0, 3.5), parent="")
box("Hem", 0, 0, 0.5, 4.6, 3.4, 0.25, CORONA, tag="neon")
box("RobeLow", 0, 0, 0.6, 4.4, 3.2, 1.3, ROBE2)
box("RobeMid", 0, 0, 1.9, 3.7, 2.8, 2.0, ROBE1)
box("RobeTop", 0, 0, 3.9, 3.1, 2.4, 2.1, ROBE1)
box("Collar", 0, 0, 5.9, 3.3, 2.6, 0.4, WHITE)
for (x, z) in ((-1.4, 1.0), (-0.6, 2.3), (0.9, 1.6), (1.6, 0.9), (0.3, 3.3), (-1.1, 4.3), (1.0, 4.6), (-0.2, 1.3)):
    yf = 1.62 if z < 1.9 else (1.42 if z < 3.9 else 1.22)
    box("Star", x, yf, z, 0.22, 0.06, 0.22, STAR, tag="neon")
GROUP = "Head"
groups["Head"] = dict(joint=(0, 0, 6.3), parent="Torso")
disc("Eclipse", 0, 0.1, 8.0, 1.65, 0.5, VOID)
for k in range(12):
    a = k * math.tau / 12
    box("Corona", math.cos(a) * 2.05, 0.0, 8.0 + math.sin(a) * 2.05 - 0.3, 0.6, 0.3, 0.6, CORONA, ry=-math.degrees(a), tag="neon")
for sx in (-1, 1):
    box("EyeGlow", sx * 0.55, 0.38, 8.1, 0.55, 0.06, 0.14, STAR, tag="neon")
for side, g in ((-1, "ArmL"), (1, "ArmR")):
    GROUP = g
    groups[g] = dict(joint=(side * 1.8, 0, 5.6), parent="Torso")
    box("Sleeve", side * 2.05, 0, 3.3, 1.1, 1.3, 2.5, ROBE2)
    box("Glove", side * 2.05, 0, 2.75, 0.75, 0.75, 0.6, GLOVE)
GROUP = "Gavels"
groups["Gavels"] = dict(joint=(0, 0, 8.0), parent="Torso")
for k in range(3):
    a = k * math.tau / 3
    gx, gy = math.cos(a) * 3.2, math.sin(a) * 3.2
    box("OrbitHandle", gx, gy, 7.3, 0.22, 0.22, 1.2, (122, 70, 34), tag="nocollide")
    box("OrbitHead", gx, gy, 8.5, 1.3, 0.65, 0.65, (150, 92, 46), rz=math.degrees(a), tag="nocollide")
    box("OrbitBand", gx, gy, 8.5, 0.3, 0.7, 0.7, CORONA, rz=math.degrees(a), tag="neon")
MODELS["Eclipse"] = dict(root=P, groups=groups, height=10.3)


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
target = (19, 0, 4.5)
cam.location = (12, 68, 18)
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
sc.render.resolution_x, sc.render.resolution_y = 1800, 800
sc.world = sc.world or bpy.data.worlds.new("BS_World")
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"{len(data)} bosses, " + ", ".join(f"{k}: {len(v['parts'])} blocks / {len(v['groups'])} groups" for k, v in data.items()) + f" -> {OUT_JSON}")
