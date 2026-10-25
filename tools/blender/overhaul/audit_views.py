# tools/blender/overhaul/audit_views.py - review renders of every MAP MODEL OVERHAUL model on its own: four views at a
# player's eye height (front, front-left, back-right, side) at a normal viewing distance, with a player for scale.
#   Blender -b --factory-startup --python tools/blender/overhaul/audit_views.py -- <out dir> [<group> ...]
# (same groups as check_models.py). Writes <out>/<group>_<name>_<view>.jpg.
import bpy, os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv else os.path.join(HERE, "renders", "audit")
WANT = set(argv[1:]) or None
os.makedirs(OUT, exist_ok=True)
import check_models as CM  # (its main only runs as a script)
import ohkit as O
from mathutils import Vector

VIEWS = (("front", 0.0), ("frontleft", -40.0), ("backright", 140.0), ("side", 90.0))


def main():
    O.reset()
    sc = O.scene()
    sc.eevee.taa_render_samples = 16
    O.box("Preview_Ground", "grass", (0, 0, -0.25), (900, 900, 0.5))
    O.finish()
    for group, name, fn, args in CM.models():
        if WANT and group not in WANT:
            continue
        before = set(bpy.data.objects.keys())
        try:
            fn(*args)
        except Exception as e:
            print(f"[audit] {group}.{name} FAILED: {e!r}")
            O.BMS.clear()
            continue
        O.finish()
        objs = [bpy.data.objects[n] for n in set(bpy.data.objects.keys()) - before]
        meshes = [ob for ob in objs if ob.type == "MESH" and not ob.name.startswith(("Preview", "Studs"))]
        if not meshes:
            continue
        pts = [ob.matrix_world @ Vector(c) for ob in meshes for c in ob.bound_box]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        size, mid = hi - lo, (lo + hi) / 2
        O.player(lo.x - 2.5, mid.y + size.y * 0.25, 0.0)  # (scale reference, beside the -X end, clear of the side view)
        O.finish()
        span = max(size.x, size.y)
        dist = max(11.0, span * 0.95 + size.z * 0.55)
        eye = 5.2
        look_z = min(max(size.z * 0.42, 2.0), eye + dist * 0.35)
        lens = 24 if size.z > span * 1.4 else 30
        for view, ang in VIEWS:
            a = math.radians(ang)
            d = Vector((math.sin(a), -math.cos(a), 0.0))  # (fronts face -Y)
            cam = mid + d * (dist + span * 0.5)
            O.render(OUT, f"{group}_{name}_{view}", (cam.x, cam.y, eye), (mid.x, mid.y, look_z), lens=lens, res=(800, 450))
        for ob in list(bpy.data.objects):
            if ob.name not in before:
                bpy.data.objects.remove(ob)
    print("[audit] done")


main()
