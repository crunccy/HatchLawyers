# tools/blender/hub_landmarks.py - hub landmarks for the art pass (docs/ART_REMODEL_BRIEF.md stage 1 plan, 2026-10-16,
# crnuch's OK): the BOARDWALK GATEWAY where the plaza meets the Big Case terrace (replaces Hub.Gates.BigCaseGate) and
# the plaza's centre piece, the EGG FOUNTAIN (a giant brick egg on a tiered pedestal with a golden gavel, in a basin).
# Same language as the pier (tools/blender/arcade_pier.py): red / white banded legs, gold caps, bulb rows.
# Every block becomes a studded Part (tools/zones/BuildHubLandmarks.lua); tags: "neon" (Neon, no collision), "water"
# (glassy, no collision). A block with "txt" gets a SurfaceGui with that text on its "fn" face.
# Stage 3 (same day): the SHOP storefront and the MUTATION MACHINE, rebuilt on their old spots (names their scripts use kept).
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/hub_landmarks.py  (Windows: blender.exe -b -P)
# Units: 1 Blender m = 1 stud, Z up; each model's origin is on the ground; the builder places it (PLACE below).
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(here, "..", ".."))

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "hub_landmarks.json")
OUT_PNG = os.path.join(REPO, "art", "map", "hub_landmarks.png")

sc = bpy.data.scenes.get("HubLandmarks") or bpy.data.scenes.new("HubLandmarks")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("HubLandmarks") or bpy.data.collections.new("HubLandmarks")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("HL_Cube")
if me is None:
    me = bpy.data.meshes.new("HL_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

def rgb(r, g, b):
    return (r, g, b)

PAL = dict(
    red=rgb(229, 57, 53), white=rgb(246, 244, 236), gold=rgb(255, 200, 40), ink=rgb(30, 32, 46), cream=rgb(246, 226, 180),
    woodL=rgb(214, 140, 70), woodD=rgb(122, 70, 34), bulb=rgb(255, 236, 150), pink=rgb(255, 120, 200), sky=rgb(90, 200, 255),
    water=rgb(80, 190, 255), stone=rgb(200, 196, 188), green=rgb(98, 205, 48), leaf=rgb(70, 168, 34), purple=rgb(150, 90, 220),
    steel=rgb(150, 160, 182),
    egg=rgb(255, 196, 40), eggSpot=rgb(250, 248, 240),  # a golden egg with white spots (cream read grey in the hub light)
)

ROOTS = {}
def root(name):
    if name not in ROOTS:
        o = bpy.data.objects.new(name, None)
        coll.objects.link(o)
        ROOTS[name] = o
    return ROOTS[name]

def box(model, name, cx, cy, z0, sx, sy, sz, col, rz=0.0, tag="", txt="", fn=None, rx=0.0, ry=0.0, lbl="", prompt=None, light=None):
    """A block whose bottom sits at z0 (centre cx, cy), in `model`'s own space."""
    o = bpy.data.objects.new(name, me)
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, z0 + sz / 2)
    o.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    o["rgb"] = list(col)
    o["tag"] = tag
    o["txt"] = txt
    o["fn"] = list(fn) if fn else []
    o["lbl"] = lbl
    o["prompt"] = json.dumps(prompt) if prompt else ""
    o["light"] = json.dumps(light) if light else ""
    coll.objects.link(o)
    o.parent = root(model)
    return o

# ------------------------------------------------------------------ the BOARDWALK GATEWAY (faces Blender +Y = the plaza)
G = "BoardwalkGate"
LEG_X, LEG_H = 15.5, 20.0
for side in (-1, 1):
    x = side * LEG_X
    box(G, "LegBase", x, 0, 0, 5.2, 5.2, 1.6, PAL["ink"])
    z = 1.6
    k = 0
    while z < LEG_H - 0.1:  # banded leg
        h = min(2.6, LEG_H - z)
        box(G, "Leg", x, 0, z, 4, 4, h, PAL["red"] if k % 2 == 0 else PAL["white"])
        z += h
        k += 1
    box(G, "LegCap", x, 0, LEG_H, 5, 5, 1, PAL["gold"])
    box(G, "LegCapTop", x, 0, LEG_H + 1, 3, 3, 1, PAL["gold"])
    box(G, "Flagpole", x, 0, LEG_H + 2, 0.4, 0.4, 6, PAL["ink"])
    box(G, "Flag", x + side * 1.6, 0, LEG_H + 5.4, 3, 0.2, 2, PAL["purple"] if side < 0 else PAL["green"])
    for zz in (4.0, 9.0, 14.0):  # lanterns on the plaza face of each leg
        box(G, "LegLamp", x, 2.3, zz, 1.2, 0.6, 1.2, PAL["bulb"], tag="neon")
box(G, "Beam", 0, 0, LEG_H - 3.5, 2 * LEG_X + 2, 3, 3.5, PAL["red"])
box(G, "BeamTrim", 0, 0, LEG_H - 3.9, 2 * LEG_X + 2.4, 3.4, 0.4, PAL["gold"])
box(G, "BeamTrim", 0, 0, LEG_H, 2 * LEG_X + 2.4, 3.4, 0.4, PAL["gold"])
# the big sign above the beam, both faces lettered
box(G, "SignBack", 0, 0, LEG_H + 0.4, 26, 1.2, 7.2, PAL["gold"])
box(G, "Sign", 0, 0.75, LEG_H + 0.8, 24, 0.4, 6.4, PAL["ink"], txt="BOARDWALK", fn=(0, 1, 0))
box(G, "Sign", 0, -0.75, LEG_H + 0.8, 24, 0.4, 6.4, PAL["ink"], txt="BOARDWALK", fn=(0, -1, 0))
for i in range(16):  # bulbs along the top and bottom of the sign, plaza side
    t = i / 15
    for zz in (LEG_H + 7.4, LEG_H + 0.1):
        box(G, "Bulb", -12.5 + 25 * t, 0.9, zz, 0.6, 0.6, 0.6, PAL["bulb"] if (i + int(zz)) % 2 == 0 else PAL["pink"], tag="neon")
# the little hanging sign under the beam: where it leads
box(G, "SubSign", 0, 0.6, LEG_H - 6.6, 18, 0.4, 2.6, PAL["purple"], txt="BIG CASES  •  ARCADE PIER", fn=(0, 1, 0))
box(G, "SubSign", 0, -0.6, LEG_H - 6.6, 18, 0.4, 2.6, PAL["purple"], txt="BACK TO THE PLAZA", fn=(0, -1, 0))
for side in (-1, 1):
    box(G, "SubSignChain", side * 7, 0, LEG_H - 4, 0.25, 0.25, 0.6, PAL["ink"])
# planters at the feet, plaza side
for side in (-1, 1):
    px = side * (LEG_X + 5)
    box(G, "Planter", px, 2, 0, 4.4, 4.4, 1.6, PAL["woodD"])
    box(G, "PlanterSoil", px, 2, 1.6, 3.8, 3.8, 0.2, PAL["leaf"])
    box(G, "Bush", px, 2, 1.8, 3.4, 3.4, 2.2, PAL["green"])
    box(G, "Flower", px - 0.8, 1.2, 4.0, 0.8, 0.8, 0.8, PAL["pink"])
    box(G, "Flower", px + 0.9, 2.6, 4.0, 0.8, 0.8, 0.8, PAL["gold"])

# ------------------------------------------------------------------ the EGG FOUNTAIN (centre of the plaza)
F = "EggFountain"
R = 13  # basin half-size: a chunky octagon of two crossed slabs, rim on its eight sides
for (sx, sy) in ((2 * R, 2 * R - 9), (2 * R - 9, 2 * R)):
    box(F, "BasinFloor", 0, 0, 0, sx, sy, 0.6, PAL["stone"])
    box(F, "Water", 0, 0, 0.6, sx - 2, sy - 2, 1.0, PAL["water"], tag="water")
def rim(x0, y0, x1, y1):
    L = math.hypot(x1 - x0, y1 - y0)
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    box(F, "Rim", (x0 + x1) / 2, (y0 + y1) / 2, 0, L + 1.2, 1.8, 2.2, PAL["white"], rz=ang)
    box(F, "RimTop", (x0 + x1) / 2, (y0 + y1) / 2, 2.2, L + 1.6, 2.2, 0.5, PAL["gold"], rz=ang)
c = R - 4.5  # where the octagon's corners start
pts = [(c, R), (R, c), (R, -c), (c, -R), (-c, -R), (-R, -c), (-R, c), (-c, R)]
for a, b in zip(pts, pts[1:] + pts[:1]):
    rim(a[0], a[1], b[0], b[1])
# tiered pedestal
tiers = [(9, 1.6, PAL["cream"]), (7, 1.4, PAL["gold"]), (5.4, 1.4, PAL["cream"]), (4.2, 1.0, PAL["gold"])]
z = 0.6
for (w, h, col) in tiers:
    box(F, "Pedestal", 0, 0, z, w, w, h, col)
    z += h
# the giant brick egg: stacked slices, widest a little below the middle, an orange spotted band
EGG = [2.6, 3.8, 4.6, 5.1, 5.3, 5.3, 5.1, 4.7, 4.2, 3.5, 2.7, 1.6]
eggBottom = z
for i, w in enumerate(EGG):
    box(F, "Egg", 0, 0, z, w, w, 0.95, PAL["egg"])
    z += 0.95
box(F, "EggBand", 0, 0, eggBottom + 4 * 0.95, 5.5, 5.5, 0.7, PAL["eggSpot"])
for (sx, sy) in ((2.45, 0), (-2.45, 0), (0, 2.45), (0, -2.45)):
    box(F, "EggSpot", sx * 1.04, sy * 1.04, eggBottom + 6 * 0.95, 0.9 if sx == 0 else 0.4, 0.9 if sy == 0 else 0.4, 0.9, PAL["eggSpot"])
box(F, "EggCrack", 1.2, 2.66, eggBottom + 8 * 0.95, 1.8, 0.2, 0.25, PAL["woodD"], rz=0, ry=25)
# a golden gavel leaning on the egg (head + handle), on the side players arrive from (the lane, Roblox -Z = Blender +Y)
box(F, "GavelHandle", 2.2, 3.6, 1.2, 0.7, 0.7, 7.5, PAL["woodD"], rx=18, ry=22)
box(F, "GavelHead", 3.7, 5.2, 7.2, 4.2, 1.9, 1.9, PAL["gold"], rx=18, ry=22)
box(F, "GavelBand", 3.7, 5.2, 7.2, 1.0, 2.0, 2.0, PAL["woodD"], rx=18, ry=22)
# four spouts: little gold fish on the rim corners spitting water into the basin
for (x, y) in ((R - 2.5, R - 2.5), (-R + 2.5, R - 2.5), (R - 2.5, -R + 2.5), (-R + 2.5, -R + 2.5)):
    box(F, "Spout", x, y, 2.7, 1.4, 1.4, 1.4, PAL["gold"])
    dx, dy = -x / abs(x), -y / abs(y)
    for k in range(4):
        box(F, "SpoutWater", x + dx * (1.2 + k * 0.9), y + dy * (1.2 + k * 0.9), 3.0 - k * 0.55, 0.5, 0.5, 0.5, PAL["sky"], tag="water")
# lily pads + a coin or two in the water
for (x, y, col) in ((6, 3, PAL["leaf"]), (-5, -6, PAL["leaf"]), (4, -7, PAL["gold"]), (-7, 4, PAL["gold"])):
    box(F, "Pad", x, y, 1.6, 1.6 if col == PAL["leaf"] else 0.7, 1.6 if col == PAL["leaf"] else 0.7, 0.12, col)

# ------------------------------------------------------------------ the SHOP (stage 3, 2026-10-16): a brick storefront, its counter facing Blender +Y
S = "ShopStall"
box(S, "Floor", 0, 0, 0, 17, 13, 0.6, PAL["cream"])
box(S, "FloorTrim", 0, 6.55, 0, 17.4, 0.4, 0.7, PAL["gold"])
box(S, "BackWall", 0, -5.9, 0.6, 15, 1.0, 10.4, PAL["cream"])
for side in (-1, 1):
    box(S, "SideWall", side * 7.4, -1.5, 0.6, 1.0, 9.0, 10.4, PAL["cream"])
    box(S, "SideStripe", side * 7.95, -1.5, 3.0, 0.15, 8.0, 0.8, PAL["pink"])
    for (cy) in (-5.9, 3.4):  # banded corner posts, like the hub's gate
        z = 0.6
        for k in range(4):
            box(S, "CornerPost", side * 7.6, cy, z, 1.8, 1.8, 2.6, PAL["red"] if k % 2 == 0 else PAL["white"])
            z += 2.6
        box(S, "CornerCap", side * 7.6, cy, z, 2.2, 2.2, 0.6, PAL["gold"])
# shelves on the back wall with what the shop sells
for (zz) in (3.2, 5.8, 8.4):
    box(S, "Shelf", 0, -5.0, zz, 12.5, 1.6, 0.3, PAL["woodD"])
for i, x in enumerate((-4.8, -3.2, -1.6)):  # coin stacks (2x Cash)
    for k in range(3 + i):
        box(S, "Coin", x, -5.0, 3.5 + k * 0.32, 1.1, 1.1, 0.3, PAL["gold"])
for k, w in enumerate((0.9, 1.4, 1.6, 1.5, 1.1, 0.6)):  # a golden egg (Lucky Eggs)
    box(S, "WareEgg", 1.6, -5.0, 3.5 + k * 0.42, w, w, 0.42, PAL["egg"])
for i in range(3):  # cash bundles
    box(S, "Cash", 4.4, -5.0 + (i - 1) * 0.1, 3.5 + i * 0.36, 2.2, 1.0, 0.34, PAL["green"])
    box(S, "CashBand", 4.4, -5.0 + (i - 1) * 0.1, 3.5 + i * 0.36, 0.4, 1.05, 0.36, PAL["white"])
box(S, "Boot", -3.6, -5.0, 6.1, 1.0, 1.0, 1.6, PAL["red"])  # speedy boots
box(S, "BootToe", -3.6, -4.3, 6.1, 1.0, 0.8, 0.7, PAL["red"])
box(S, "BootWing", -4.25, -5.0, 7.0, 0.25, 0.9, 0.6, PAL["white"])
box(S, "MiniFirm", 0.5, -5.0, 6.1, 2.4, 1.4, 1.6, PAL["woodL"])  # a bigger firm
box(S, "MiniFirmRoof", 0.5, -5.0, 7.7, 2.8, 1.6, 0.5, PAL["red"])
box(S, "Briefcase", 3.8, -5.0, 6.1, 1.8, 0.8, 1.2, PAL["woodD"])
box(S, "BriefcaseHandle", 3.8, -5.0, 7.3, 0.8, 0.2, 0.3, PAL["gold"])
for x in (-4.0, 0.0, 4.0):  # a few eggs on the top shelf
    box(S, "ShelfEgg", x, -5.0, 8.7, 1.0, 1.0, 1.3, [PAL["sky"], PAL["pink"], PAL["green"]][int(x / 4 + 1)])
# the counter (the prompt sits in front of it) + till
box(S, "Counter", 0, 3.6, 0.6, 13.0, 2.0, 3.0, PAL["red"])
box(S, "CounterTop", 0, 3.6, 3.6, 13.6, 2.6, 0.5, PAL["woodL"])
box(S, "CounterStripe", 0, 4.62, 1.6, 13.0, 0.15, 0.7, PAL["white"])
box(S, "Till", -4.0, 3.4, 4.1, 2.2, 1.6, 1.2, PAL["ink"])
box(S, "TillScreen", -4.0, 3.0, 5.3, 1.6, 0.3, 0.9, PAL["green"], tag="neon")
for k in range(4):
    box(S, "CoinPile", 3.0 + (k % 2) * 0.6, 3.6, 4.1 + k * 0.3, 1.0, 1.0, 0.3, PAL["gold"])
# striped awning sloping out over the counter
for i in range(8):
    box(S, "Awning", -7.5 + (i + 0.5) * (15 / 8), 5.3, 9.0, 15 / 8 + 0.02, 5.2, 0.4, PAL["red"] if i % 2 == 0 else PAL["white"], rx=-16)
box(S, "AwningEdge", 0, 7.8, 8.0, 15.4, 0.4, 0.8, PAL["gold"])
# roof, the SHOP sign with bulbs, a giant coin on top
box(S, "Roof", 0, -1.5, 11.0, 17.2, 10.6, 1.0, PAL["purple"])
box(S, "RoofTrim", 0, -1.5, 12.0, 17.6, 11.0, 0.4, PAL["gold"])
box(S, "SignBack", 0, 3.0, 12.4, 13.2, 1.0, 4.6, PAL["gold"])
box(S, "Sign", 0, 3.55, 12.7, 12.2, 0.4, 4.0, PAL["ink"], txt="SHOP", fn=(0, 1, 0))
for i in range(12):
    t = i / 11
    for zz in (17.05, 12.3):
        box(S, "Bulb", -6.0 + 12 * t, 3.7, zz, 0.55, 0.55, 0.55, PAL["bulb"] if (i + int(zz)) % 2 == 0 else PAL["pink"], tag="neon")
box(S, "CoinStand", 0, -3.5, 12.4, 0.8, 0.8, 2.0, PAL["ink"])
box(S, "BigCoin", 0, -3.5, 14.4, 5.0, 1.0, 5.0, PAL["gold"], txt="$", fn=(0, 1, 0))
box(S, "BigCoinRim", 0, -3.5, 14.1, 5.6, 0.8, 5.6, PAL["eggSpot"])
box(S, "PromptZone", 0, 7.4, 0.6, 8, 4, 6, PAL["white"], tag="prompt",
    prompt=dict(name="ShopPrompt", action="Open Shop", object="Shop", max=14))

# ------------------------------------------------------------------ the MUTATION MACHINE (stage 3): faces Blender +Y; names its scripts use:
# Body (MergePrompt), WindowFrame (the scene's focus), Screen (the "?/!" Mark + light), Console, Dome (the Title billboard)
M = "MergeMachine"
for (sx, sy) in ((17, 11), (11, 17)):  # gold octagon plinth with a glowing ring
    box(M, "Plinth", 0, 0, 0, sx, sy, 1.2, PAL["gold"])
    box(M, "PlinthTrim", 0, 0, 1.2, sx - 0.6, sy - 0.6, 0.25, PAL["sky"], tag="neon")
box(M, "PlinthTop", 0, 0, 1.45, 10, 10, 0.4, PAL["ink"])
box(M, "Body", 0, -0.5, 1.85, 9, 6.5, 8.4, PAL["purple"],
    prompt=dict(name="MergePrompt", action="Mutate", object="Mutation Machine", max=14))
for zz in (3.6, 8.6):
    box(M, "BodyBand", 0, -0.5, 1.85 + zz - 0.5, 9.4, 6.9, 0.7, rgb(110, 60, 180))
box(M, "WindowFrame", 0, 2.85, 3.6, 6.6, 0.3, 5.6, PAL["sky"], tag="neon")
box(M, "Screen", 0, 3.0, 4.1, 5.6, 0.4, 4.6, PAL["ink"], txt="?", lbl="Mark", fn=(0, 1, 0), light=[1.0, 14, [180, 140, 255]])
for i in range(7):  # indicator bulbs along the top edge
    box(M, "Indicator", -3.6 + i * 1.2, 2.85, 9.6, 0.6, 0.4, 0.6, [PAL["pink"], PAL["bulb"], PAL["sky"]][i % 3], tag="neon")
# the hopper on top: three gold chutes (three lawyers in) into a dome, an antenna with a glowing tip
box(M, "Cap", 0, -0.5, 10.25, 7, 5.2, 0.8, PAL["gold"])
box(M, "Dome", 0, -0.5, 11.05, 5.2, 4.2, 1.6, PAL["steel"])
box(M, "Dome", 0, -0.5, 12.65, 3.6, 3.0, 1.2, PAL["steel"])
box(M, "CapGlow", 0, -0.5, 13.85, 2.4, 2.0, 0.5, PAL["pink"], tag="neon")
for k, (x, rz) in enumerate(((-3.4, 20), (0, 0), (3.4, -20))):
    box(M, "PipeUp", x, -2.6, 10.6, 1.3, 1.3, 4.2, PAL["gold"], ry=rz)
    box(M, "Funnel", x * 1.18, -2.6, 14.6, 2.4, 2.4, 0.9, PAL["gold"])
    box(M, "FunnelInner", x * 1.18, -2.6, 15.0, 1.6, 1.6, 0.6, PAL["ink"])
box(M, "Antenna", 0, -0.5, 14.35, 0.35, 0.35, 3.0, PAL["ink"])
box(M, "AntennaTip", 0, -0.5, 17.35, 0.9, 0.9, 0.9, PAL["red"], tag="neon")
# side tanks with bubbling glow
for side in (-1, 1):
    tx = side * 6.4
    box(M, "Tank", tx, -0.8, 1.85, 3.0, 3.0, 6.8, PAL["steel"])
    box(M, "TankLight", tx, -0.8 + 1.45, 2.6, 2.0, 0.3, 5.2, PAL["green"] if side < 0 else PAL["pink"], tag="neon")
    for b in range(4):
        box(M, "Bubble", tx + (0.4 if b % 2 else -0.4), 0.9, 3.0 + b * 1.2, 0.45, 0.2, 0.45, PAL["white"])
    box(M, "TankCap", tx, -0.8, 8.65, 3.4, 3.4, 0.6, PAL["gold"])
    box(M, "PipeOver", tx * 0.82, -0.8, 7.4, 2.4, 1.0, 1.0, PAL["gold"])
# the console, front right: buttons, a screen and a big lever
box(M, "Console", 5.4, 4.6, 1.85, 4.2, 2.6, 2.6, PAL["ink"])
box(M, "ConsoleTop", 5.4, 4.6, 4.45, 4.6, 3.0, 0.4, PAL["gold"])
box(M, "ConsoleScreen", 5.4, 5.95, 2.4, 3.0, 0.2, 1.4, PAL["sky"], tag="neon")
for i, col in enumerate((PAL["red"], PAL["bulb"], PAL["green"])):
    box(M, "Button", 4.2 + i * 1.2, 4.6, 4.85, 0.8, 0.8, 0.4, col, tag="neon")
box(M, "Lever", 7.0, 4.0, 4.85, 0.35, 0.35, 2.6, PAL["ink"], rx=-20)
box(M, "LeverKnob", 7.0, 4.45, 7.2, 1.0, 1.0, 1.0, PAL["red"])

# ------------------------------------------------------------------ export (Roblox: Y up; X kept, Blender +Y = Roblox -Z)
def to_rbx(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]
Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
models = []
PLACE = {  # Roblox world: x, y (ground top), z, yaw degrees
    "BoardwalkGate": [0, 0.5, 86, 0],  # the old BigCaseGate's spot; sign faces the plaza (-Z)
    "EggFountain": [0, 0.5, 0, 0],
    # stage 3: same spots as the old ones; yaw turns the front (Roblox -Z at yaw 0) to face the plaza's middle
    "ShopStall": [-30.4, 0.5, -30.4, -135],
    "MergeMachine": [31.47, 0.5, -31.47, 135],
}
TITLE = {"ShopStall": ["Counter", 21.5], "MergeMachine": ["Dome", 9.0]}  # carry the old Title billboard: onto part, height
for name, r in ROOTS.items():
    parts = []
    for o in r.children:
        rot = o.rotation_euler.to_matrix()
        R3 = [[rot[i][j] for j in range(3)] for i in range(3)]
        MR = [[sum(Mx[i][k] * R3[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
        Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
        s = o.scale
        fn = list(o["fn"])
        parts.append(dict(n=o.name.split(".")[0], p=to_rbx(o.location), s=[round(s[0], 3), round(s[2], 3), round(s[1], 3)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"],
                          txt=o["txt"] or None, fn=to_rbx(fn) if fn else None, lbl=o["lbl"] or None,
                          prompt=json.loads(o["prompt"]) if o["prompt"] else None, light=json.loads(o["light"]) if o["light"] else None))
    models.append(dict(name=name, place=PLACE[name], parts=parts, title=TITLE.get(name)))
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(models=models), fh, separators=(",", ":"))

# ------------------------------------------------------------------ review render (both models side by side)
mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"])
    if key not in mats:
        m = bpy.data.materials.new("HL_%d" % len(mats))
        m.use_nodes = True
        bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
        bsdf.inputs["Base Color"].default_value = col
        bsdf.inputs["Roughness"].default_value = 0.55
        if o["tag"] == "neon":
            bsdf.inputs["Emission Color"].default_value = col
            bsdf.inputs["Emission Strength"].default_value = 1.4
        mats[key] = m
    return mats[key]
if not me.materials:
    me.materials.append(None)
for r in ROOTS.values():
    for o in r.children:
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = material_for(o)
ROOTS["BoardwalkGate"].location = (-22, 10, 0)
ROOTS["EggFountain"].location = (24, -4, 0)
ROOTS["ShopStall"].location = (-50, -10, 0)
ROOTS["MergeMachine"].location = (50, -10, 0)
ground = bpy.data.objects.new("Ground", me)
ground.scale = (200, 200, 1)
ground.location = (0, 0, -0.5)
coll.objects.link(ground)
gm = bpy.data.materials.new("HL_Ground")
gm.use_nodes = True
next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = (1, 0.55, 0.1, 1)
ground.material_slots[0].link = "OBJECT"
ground.material_slots[0].material = gm
sc.view_settings.view_transform = "Standard"
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
world = sc.world or bpy.data.worlds.new("HL_World")
sc.world = world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (0.55, 0.78, 1, 1)
bg.inputs["Strength"].default_value = 0.6
sun = bpy.data.objects.new("HL_Sun", bpy.data.lights.get("HL_Sun") or bpy.data.lights.new("HL_Sun", "SUN"))
sun.data.energy = 2.6
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
coll.objects.link(sun)
cam = bpy.data.objects.new("HL_Cam", bpy.data.cameras.get("HL_Cam") or bpy.data.cameras.new("HL_Cam"))
coll.objects.link(cam)
sc.camera = cam
cam.data.lens = 32
frm, at = (0, 95, 42), (0, -4, 8)  # from the plaza side (Blender +Y)
cam.location = frm
dx, dy, dz = at[0] - frm[0], at[1] - frm[1], at[2] - frm[2]
cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
sc.render.resolution_x, sc.render.resolution_y = 1500, 1000
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
sc.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True, scene=sc.name)
print("HubLandmarks: " + ", ".join("%s %d blocks" % (m["name"], len(m["parts"])) for m in models) + " -> " + OUT_JSON)
