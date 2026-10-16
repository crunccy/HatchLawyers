# tools/blender/lane_pillar.py - the LANE PILLAR (design pass, 2026-10-16): the zone lane's long brick walls had no rhythm,
# so a banded pillar stands against each wall every ~45 studs: zone-coloured bands ("BandA" - the builder paints them
# the zone's colour) between white ones, a gold cap, a lamp on top and a hanging banner ("Banner", zone colour) facing the
# lane. tools/zones/BuildLanePillars.lua places them (Workspace.ZoneLandmarks.Pillars).
# Roblox axes (x across, y up, z: the model's front is -Z, towards the lane); its back sits on the wall.
# Run: /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/lane_pillar.py
import bpy, json, os

REPO = os.environ.get("HATCH_REPO") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT_JSON = os.path.join(REPO, "tools", "zones", "lane_pillar.json")
WHITE, GOLD, INK, BULB = (246, 244, 236), (255, 200, 40), (30, 32, 46), (255, 236, 150)
parts = []
def box(name, cx, cz, y0, sx, sy, sz, col, tag=""):
    parts.append(dict(n=name, p=[cx, round(y0 + sy / 2, 3), cz], s=[sx, sy, sz], r=[1, 0, 0, 0, 1, 0, 0, 0, 1], c=list(col), t=tag))
box("Base", 0, 0, 0, 3.6, 1.0, 2.8, INK)
y = 1.0
for k in range(5):
    box("BandA" if k % 2 == 0 else "BandB", 0, 0.1, y, 3.0, 2.6, 2.4, WHITE)
    y += 2.6
box("Cap", 0, 0, y, 3.6, 0.6, 2.8, GOLD)
box("Lamp", 0, 0, y + 0.6, 1.6, 1.6, 1.6, BULB, tag="neon")
box("LampCap", 0, 0, y + 2.2, 2.2, 0.5, 2.2, INK)
box("BannerRod", 0, -1.6, 11.2, 3.4, 0.35, 0.35, GOLD)
box("Banner", 0, -1.45, 6.6, 2.6, 4.6, 0.2, WHITE)
box("BannerTail", 0, -1.45, 6.0, 1.2, 0.6, 0.2, WHITE)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(models=[dict(name="LanePillar", parts=parts)]), fh, separators=(",", ":"))
print("LanePillar: %d blocks -> %s" % (len(parts), OUT_JSON))
