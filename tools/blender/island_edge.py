# tools/blender/island_edge.py - the ISLAND'S EDGE (design pass, 2026-10-16): the hub island used to stop at a flat
# 8-stud sand strip and then the flat sea. Now: a two-step beach all round (dry sand, then wet sand just above the
# water - gaps where the zone lane and the pier leave the island), rock clusters along it, two small docks with rowboats
# beside the pier, sailboats out on the water (Bob = the client bobs them) and three far islands on the horizon.
# Same JSON shape as tools/blender/hub_landmarks.py ("parent" = Workspace.IslandEdge); built by
# tools/zones/BuildHubLandmarks.lua with _G.LANDMARKS_JSON = ".../island_edge.json".
# Island: grass x +-256, z +-160 (Roblox), sand strip to +-264 / +-168 at top -0.2; the sea (Baseplate) top is -1.4.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/island_edge.py
import bpy, math, json, os, random

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "island_edge.json")
rnd = random.Random(1016)

def rgb(r, g, b):
    return (r, g, b)
PAL = dict(sand=rgb(246, 222, 160), sandWet=rgb(214, 186, 128), rock=rgb(150, 156, 168), rockD=rgb(112, 118, 132),
           woodL=rgb(214, 140, 70), woodD=rgb(122, 70, 34), white=rgb(246, 244, 236), red=rgb(229, 57, 53), gold=rgb(255, 200, 40),
           green=rgb(98, 205, 48), leaf=rgb(70, 168, 34), grass=rgb(124, 222, 52), blue=rgb(60, 130, 230), ink=rgb(30, 32, 46),
           trunk=rgb(150, 100, 50), cliff=rgb(176, 168, 150))

MODELS = {}
def box(model, cx, cz, y0, sx, sy, sz, col, ry=0.0, tag="", name=None):
    """Roblox-space block (x, z on the ground, y0 = bottom) - this file thinks in Roblox axes; ry = yaw degrees."""
    c, s = math.cos(math.radians(ry)), math.sin(math.radians(ry))
    MODELS.setdefault(model, []).append(dict(n=name or model, p=[round(cx, 3), round(y0 + sy / 2, 3), round(cz, 3)], s=[round(sx, 3), round(sy, 3), round(sz, 3)],
                                             r=[c, 0, s, 0, 1, 0, -s, 0, c], c=list(col), t=tag))

# ------------------------------------------------------------------ the beach: dry step (top -0.7) then wet step (top -1.2)
def strip(x0, z0, x1, z1, col, top, name):
    box("Beach", (x0 + x1) / 2, (z0 + z1) / 2, top - 1.0, abs(x1 - x0), 1.0, abs(z1 - z0), col, name=name)
for (w0, w1, top, col, name) in ((0, 14, -0.7, PAL["sand"], "Dry"), (14, 24, -1.2, PAL["sandWet"], "Wet")):
    X0, Z0 = 264 + w0, 168 + w0
    X1, Z1 = 264 + w1, 168 + w1
    # north (+z): leave the pier (x +-40) clear
    strip(-X1, Z0, -40, Z1, col, top, name)
    strip(40, Z0, X1, Z1, col, top, name)
    # south (-z): leave the lane (x +-76) clear
    strip(-X1, -Z1, -76, -Z0, col, top, name)
    strip(76, -Z1, X1, -Z0, col, top, name)
    # east / west
    strip(X0, -Z0, X1, Z0, col, top, name)
    strip(-X1, -Z0, -X0, Z0, col, top, name)

# ------------------------------------------------------------------ a rock cluster (copies scattered along the beach)
for i, (dx, dz, w, h, col) in enumerate(((0, 0, 4.0, 3.2, PAL["rock"]), (2.6, 1.4, 2.8, 2.2, PAL["rockD"]), (-2.4, 1.0, 2.4, 1.6, PAL["rock"]),
                                          (0.8, -2.2, 2.2, 1.4, PAL["rockD"]), (0.4, 0.2, 2.6, 1.0, PAL["rock"]))):
    box("RockCluster", dx, dz, -1.0 + (3.2 if i == 4 else 0), w, h, w * 0.9, col, ry=i * 23)

# ------------------------------------------------------------------ a dock with a rowboat (front = +z, out to sea)
for k in range(8):
    box("Dock", 0, k * 4 + 2, -0.6, 8, 0.6, 3.8, PAL["woodL"] if k % 2 == 0 else PAL["woodD"])
for k in (0, 2, 4, 6, 8):
    for sx in (-1, 1):
        box("Dock", sx * 3.6, k * 4, -4, 0.9, 5.4, 0.9, PAL["woodD"])
box("Dock", -3.6, 32, 0, 0.9, 2.6, 0.9, PAL["woodD"])
box("Dock", -3.6, 32, 2.6, 1.2, 0.4, 1.2, PAL["gold"])
# the rowboat beside the end
for (w, y0, col) in ((2.4, -1.6, PAL["red"]), (3.2, -1.0, PAL["red"]), (3.4, -0.4, PAL["white"])):
    box("Dock", 7.4, 28, y0, w, 0.6, 7.6 if w > 3 else 6.4, col)
box("Dock", 7.4, 28, 0.2, 2.8, 0.25, 6.8, PAL["woodL"])
box("Dock", 7.4, 28, 0.45, 3.2, 0.3, 0.8, PAL["woodD"])  # seat
box("Dock", 6.2, 30, 0.4, 0.3, 0.3, 4.0, PAL["woodD"], ry=30)  # oar

# ------------------------------------------------------------------ a sailboat (out on the water; the client bobs it)
for (w, l, y0, col) in ((3.0, 9.0, -2.4, PAL["blue"]), (4.6, 12.0, -1.6, PAL["blue"]), (5.4, 13.0, -0.8, PAL["white"])):
    box("Sailboat", 0, 0, y0, w, 0.8, l, col)
box("Sailboat", 0, 0, 0.0, 4.6, 0.3, 11.6, PAL["woodL"])
box("Sailboat", 0, -4.8, 0.0, 4.0, 1.2, 2.2, PAL["white"])  # cabin
box("Sailboat", 0, 1.0, 0.0, 0.6, 14.0, 0.6, PAL["woodD"])  # mast
for k in range(5):  # the striped sail
    box("Sailboat", 0.2, 3.6, 2.0 + k * 2.2, 0.2, 2.2, 5.0 - k * 0.8, PAL["red"] if k % 2 == 0 else PAL["white"])
box("Sailboat", 0, 1.0, 14.0, 0.2, 1.0, 1.6, PAL["gold"])  # pennant

# ------------------------------------------------------------------ a far island (a big chunky mound, sand rim, palms, a cliff)
for (r, y0, h, col) in ((60, -1.6, 1.2, PAL["sand"]), (52, -0.4, 3.0, PAL["grass"]), (38, 2.6, 4.0, PAL["green"]), (22, 6.6, 4.0, PAL["leaf"])):
    box("FarIsland", 0, 0, y0, r, h, r * 0.8, col)
box("FarIsland", -10, 4, 6.6, 12, 14, 10, PAL["cliff"])
box("FarIsland", -10, 4, 20.6, 10, 2, 8, PAL["grass"])
for (px, pz) in ((14, -8), (20, 6), (-20, -12)):
    for k in range(5):
        box("FarIsland", px + k * 0.5, pz, 2.6 + k * 2.4, 1.6, 2.4, 1.6, PAL["trunk"])
    for (lx, lz) in ((3, 0), (-3, 0), (0, 3), (0, -3)):
        box("FarIsland", px + 2.5 + lx, pz + lz, 14.6, 4.6 if lx else 2.0, 1.0, 2.0 if lx else 4.6, PAL["leaf"])

# ------------------------------------------------------------------ placements
def along_beach(n):
    out = []
    for _ in range(n):
        side = rnd.choice("NSEW")
        t = rnd.uniform(-1, 1)
        if side == "N":
            x, z = t * 280, 176 + rnd.uniform(0, 12)
            if abs(x) < 110:
                continue
        elif side == "S":
            x, z = t * 280, -176 - rnd.uniform(0, 12)
            if abs(x) < 90:
                continue
        elif side == "E":
            x, z = 272 + rnd.uniform(0, 12), t * 180
        else:
            x, z = -272 - rnd.uniform(0, 12), t * 180
        out.append([round(x, 1), -0.7, round(z, 1), round(rnd.uniform(0, 360))])
    return out

models = [
    dict(name="Beach", place=[0, 0, 0, 0], parts=MODELS["Beach"]),
    dict(name="RockCluster", copies=along_beach(26), parts=MODELS["RockCluster"]),
    dict(name="Dock", copies=[[-90, 0, 168, 0], [90, 0, 168, 0]], parts=MODELS["Dock"]),  # (+z = out to sea)
    dict(name="Sailboat", copies=[[-190, -1.4, 270, 35], [230, -1.4, 330, -60], [-340, -1.4, -60, 100]], parts=MODELS["Sailboat"]),
    dict(name="FarIsland", copies=[[-620, -1.4, 420, 20], [680, -1.4, 260, -30], [-720, -1.4, -340, 60]], parts=MODELS["FarIsland"]),
]
# (this file already speaks Roblox axes, so no Blender scene is needed for the export; Blender only runs it)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(parent="IslandEdge", models=models), fh, separators=(",", ":"))
print("IslandEdge: " + ", ".join("%s %d%s" % (m["name"], len(m["parts"]), " x%d" % len(m["copies"]) if m.get("copies") else "") for m in models) + " -> " + OUT_JSON)
