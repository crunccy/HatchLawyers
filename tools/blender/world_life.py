# tools/blender/world_life.py - small props the WorldLife client animates (design pass, 2026-10-16): a blocky seagull
# ("Bird": Body, Head, Beak, WingL, WingR - the client flaps the wings and flies it round the hub).
# tools/zones/BuildWorldLife.lua makes ReplicatedStorage.WorldLife from the JSON. Roblox axes, front = -Z.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/world_life.py
import bpy, json, os

REPO = os.environ.get("HATCH_REPO") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_JSON = os.path.join(REPO, "tools", "zones", "world_life.json")
WHITE, GREY, ORANGE, INK = (246, 244, 236), (170, 176, 190), (255, 160, 24), (30, 32, 46)
parts = []
def box(name, cx, cy, cz, sx, sy, sz, col):
    parts.append(dict(n=name, p=[cx, cy, cz], s=[sx, sy, sz], c=list(col)))
box("Body", 0, 0, 0, 1.0, 0.9, 2.2, WHITE)
box("Tail", 0, 0.1, 1.3, 0.8, 0.3, 0.6, GREY)
box("Head", 0, 0.4, -1.3, 0.8, 0.8, 0.8, WHITE)
box("Beak", 0, 0.3, -1.95, 0.3, 0.25, 0.5, ORANGE)
box("EyeL", -0.41, 0.55, -1.45, 0.05, 0.2, 0.2, INK)
box("EyeR", 0.41, 0.55, -1.45, 0.05, 0.2, 0.2, INK)
box("WingL", -1.6, 0.2, 0, 2.4, 0.15, 1.2, GREY)
box("WingR", 1.6, 0.2, 0, 2.4, 0.15, 1.2, GREY)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(models=[dict(name="Bird", parts=parts)]), fh, separators=(",", ":"))
print("WorldLife: Bird %d blocks -> %s" % (len(parts), OUT_JSON))
