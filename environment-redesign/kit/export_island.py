# environment-redesign/kit/export_island.py - runs an island's build script with hl_export recording, and writes the
# Roblox parts JSON for tools/zones/BuildRedesignIsland.lua (2026-10-19, mr.robe's session). Nothing is saved to the
# island's .blend / layout JSON (saving is switched off while it runs).
#   Blender -b --python environment-redesign/kit/export_island.py -- <island folder> <build script> <out name>
#   e.g.  ... -- ocean_shore os_build.py OceanShore     -> tools/zones/redesign/OceanShore.json
import bpy, json, os, runpy, sys, builtins
KIT = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(KIT)
REPO = os.path.dirname(ROOT)
args = sys.argv[sys.argv.index("--") + 1:]
folder, script, out = args[0], args[1], args[2]
HERE = os.path.join(ROOT, folder)
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_export as X

_wm = bpy.ops.wm


class _NoSave:  # (don't touch the committed .blend: bpy.ops.wm is rebuilt on every access, so swap the whole submodule)
    def __getattr__(self, n):
        return getattr(_wm, n)

    def save_as_mainfile(self, *a, **k):
        return {"FINISHED"}


bpy.ops.wm = _NoSave()
_open = builtins.open


def guarded_open(path, mode="r", *a, **k):  # (nor the committed layout JSON)
    if "w" in mode and str(path).startswith(HERE):
        return _open(os.devnull, mode, *a, **k)
    return _open(path, mode, *a, **k)


builtins.open = guarded_open
sys.argv = [os.path.join(HERE, script), "--", "norender"]
try:
    runpy.run_path(os.path.join(HERE, script), run_name="__main__")
finally:
    builtins.open = _open
os.makedirs(os.path.join(REPO, "tools", "zones", "redesign"), exist_ok=True)
dest = os.path.join(REPO, "tools", "zones", "redesign", out + ".json")
with _open(dest, "w") as fh:
    json.dump({"island": out, "looks": X.LOOKS, "groups": X.GROUPS, "parts": X.RECORDS}, fh, separators=(",", ":"))
kinds = {}
for r in X.RECORDS:
    kinds[r[0]] = kinds.get(r[0], 0) + 1
print(f"[export] {out}: {len(X.RECORDS)} parts {kinds} in {len(X.GROUPS)} groups -> {dest} ({os.path.getsize(dest) // 1024} KB)")
