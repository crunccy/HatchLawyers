# tools/blender/lot_sign.py - the LOT SIGN for empty firm plots (art pass stage 4, docs/ART_REMODEL_BRIEF.md,
# 2026-10-16): two banded posts with gold caps (the hub's shared language), a hanging green sign "OPEN LOT / A new firm
# opens here!", a couple of traffic cones and a brick pile - a lot waiting for its firm. tools/zones/BuildLotSigns.lua
# puts one at every plot's entrance (Plots.PlotN.LotSign); Server.PlotService hides it while the plot has a firm.
# Same JSON shape as tools/blender/hub_landmarks.py (one model). Front = Blender +Y (= the plot's street side).
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/lot_sign.py
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "lot_sign.json")

def rgb(r, g, b):
    return (r, g, b)
PAL = dict(red=rgb(229, 57, 53), white=rgb(246, 244, 236), gold=rgb(255, 200, 40), ink=rgb(30, 32, 46),
           woodL=rgb(214, 140, 70), woodD=rgb(122, 70, 34), sign=rgb(98, 205, 48), orange=rgb(255, 160, 24),
           brick=rgb(196, 86, 62), sky=rgb(90, 200, 255))

parts = []
def box(name, cx, cy, z0, sx, sy, sz, col, rz=0.0, txt="", fn=None):
    """Same export as the other Blender builders: Roblox Y up, Blender +Y = Roblox -Z."""
    c, s_ = math.cos(math.radians(rz)), math.sin(math.radians(rz))
    # rotation about Blender Z = about Roblox Y (sign flips with the Y/Z swap)
    r = [c, 0, s_, 0, 1, 0, -s_, 0, c]
    parts.append(dict(n=name, p=[round(cx, 3), round(z0 + sz / 2, 3), round(-cy, 3)], s=[sx, sz, sy], r=r, c=list(col),
                      t="", txt=txt or None, fn=[fn[0], fn[2], -fn[1]] if fn else None))

for side in (-1, 1):  # banded posts
    x = side * 6.0
    box("PostFoot", x, 0, 0, 1.8, 1.8, 0.6, PAL["ink"])
    z = 0.6
    for k in range(3):
        box("Post", x, 0, z, 1.2, 1.2, 2.2, PAL["red"] if k % 2 == 0 else PAL["white"])
        z += 2.2
    box("PostCap", x, 0, z, 1.6, 1.6, 0.5, PAL["gold"])
box("Crossbar", 0, 0, 6.2, 13.4, 0.6, 0.6, PAL["woodD"])
for side in (-1, 1):
    box("Chain", side * 3.6, 0, 5.4, 0.2, 0.2, 0.8, PAL["ink"])
box("SignBack", 0, 0, 2.6, 9.6, 0.5, 2.9, PAL["woodL"])
box("Sign", 0, 0.32, 2.75, 9.0, 0.2, 2.6, PAL["woodD"], txt="OPEN LOT", fn=(0, 1, 0))  # wayfinding style: wood board
box("SubSign", 0, 0.3, 1.5, 7.0, 0.3, 1.0, PAL["white"], txt="A new firm opens here!", fn=(0, 1, 0))
box("SubChain", 0, 0, 2.5, 0.15, 0.15, 0.25, PAL["ink"])
# traffic cones by the posts
for side in (-1, 1):
    cx = side * 8.6
    box("ConeBase", cx, 0.8, 0, 1.4, 1.4, 0.2, PAL["orange"])
    for k, w in enumerate((1.0, 0.75, 0.5)):
        box("Cone", cx, 0.8, 0.2 + k * 0.5, w, w, 0.5, PAL["white"] if k == 1 else PAL["orange"])
# a little pile of bricks (and a wheelbarrow-ish crate) behind the sign
for i, (bx, by, bz, rz) in enumerate(((2.0, -2.2, 0, 10), (3.1, -2.4, 0, -6), (2.5, -2.3, 0.6, 30), (-2.4, -2.0, 0, 0))):
    box("Brick", bx, by, bz, 1.1, 0.55, 0.6, PAL["brick"], rz=rz)
box("Crate", -3.6, -2.4, 0, 1.6, 1.6, 1.4, PAL["woodL"])
box("CrateBand", -3.6, -2.4, 0.55, 1.65, 1.65, 0.3, PAL["woodD"])

os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(models=[dict(name="LotSign", parts=parts)]), fh, separators=(",", ":"))
print("LotSign: %d blocks -> %s" % (len(parts), OUT_JSON))
