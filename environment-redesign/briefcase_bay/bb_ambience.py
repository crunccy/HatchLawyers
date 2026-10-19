# environment-redesign/briefcase_bay/bb_ambience.py - Briefcase Bay's ambience in Blender (Stage 5, 2026-10-18).
# Opens briefcase_bay.blend (run bb_build.py first), adds the living details, saves, renders previews:
#   Blender -b --python environment-redesign/briefcase_bay/bb_ambience.py [-- stills | -- clips | -- only=arrival,arena]
# Busy, professional, playful (the brief): canopies sway; the harbour ripples + both waterfalls flow; tower crowns,
# the arrival pad and the RETURN HOME ring breathe; the marquee bulbs chase; steam rises from Coffee Break's giant cup;
# papers flutter across Partners' Plaza; butterflies in the office parks; The Senior Partner idles; clouds drift.
# Clearance (AMBIENCE.md rules): butterflies fly above every park prop (z 5.5+, inside the hedges); papers stay low
# over the open arena floor; the boss turns in place.
import bpy, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, KIT)
import hl_kit as K
import hl_ambience as A

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.join(HERE, "renders", "ambience")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "briefcase_bay.blend"))
scene = bpy.context.scene
scene.render.fps = A.FPS
EFX = bpy.data.collections["Environmental_Effects"]
PRES = bpy.data.collections["Presentation"]

print("[amb] wind on", A.wind(["Vegetation", "Street_Trees"]))
A.animate_water("water_fall", True)
A.animate_water("water", False)
A.breathe("glow_cyan", 2.4, 0.9, 2.0)
A.breathe("glow_green", 2.6, 1.0, 1.8, 1.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)
A.breathe("glow_gold", 2.6, 0.8, 1.3, 2.0)
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)  # marquee bulbs chase / blink

boss = bpy.data.objects.get("Boss_SeniorPartner")
if boss:
    A.pivot_to(boss, 10, 76, 0)
    A.idle(boss, sway_deg=6, bob=0.0, period=4.0)
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    A.drift(cl, (30, 12, 2), 20)

# steam from Coffee Break's giant cup (the shop sits at (60, -118) turned 180: the cup is at (60, -122), top z 14.7)
steam = A.mote(EFX, "Steam_Puff", "ico", 0.55, (245, 248, 255), emit=0.35)
A.particles(EFX, "Steam", (60, -122), (2.2, 2.2), 140, steam, lifetime=70, normal=2.2, brownian=0.25, start=-120, end=200,
            z=14.9, size_random=0.8)
# papers fluttering low over Partners' Plaza's open floor
paper = A.mote(EFX, "Paper", "box", (0.9, 1.2, 0.04), (252, 252, 250))
A.particles(EFX, "Papers", (0, 70), (96, 96), 220, paper, lifetime=420, normal=0.12, brownian=0.55, start=-300, end=200,
            rotations=True, ang_vel=2.5, z=0.8, size_random=0.3)
# butterflies over the four office parks (inside the hedges, above the benches / planters / filing cabinets)
A.butterflies(EFX, [(-62, -82, 8, 26, 5.5, 8.5), (-62, -22, 6, 20, 5.5, 8.5), (46, -82, 8, 18, 5.5, 8.5), (46, -22, 6, 16, 5.5, 8.5)], n=16)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "briefcase_bay.blend"), compress=True)
print("[amb] ambience added; briefcase_bay.blend saved")
A.bake()

CLIPS = {
    "arrival": (A.track_cam("Clip_Arrival", [(1, (0, -176, 9), (0, -60, 14)), (72, (0, -156, 10), (0, -50, 16))], 24, PRES), 72),
    "arena": (A.track_cam("Clip_Arena", [(1, (-22, 4, 9), (8, 80, 20)), (72, (2, 2, 9), (10, 80, 20))], 24, PRES), 72),
    "coffee": (A.track_cam("Clip_Coffee", [(1, (44, -92, 10), (60, -120, 10)), (48, (50, -92, 10), (60, -120, 11))], 26, PRES), 48),
    "aerial": (A.track_cam("Clip_Aerial", [(1, (-250, -560, 400), (0, 0, -25)), (72, (-200, -580, 400), (0, 0, -25))], 34, PRES), 72),
}
if bpy.data.collections.get("BB_Labels"):
    bpy.data.collections["BB_Labels"].hide_render = True
A.render_clips(scene, CLIPS, OUT, "bb_ambience", argv, K)
