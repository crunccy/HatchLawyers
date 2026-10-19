# environment-redesign/brainrot_zone/br_ambience.py - Brainrot Zone's ambience, saved into brainrot_zone.blend
# (Stage 5, 2026-10-19). No preview stills / clips (crnuch's call): scrub the .blend's timeline to see it.
#   Blender -b --python environment-redesign/brainrot_zone/br_ambience.py      (run br_build.py first)
# Exciting without strobing (the brief; young players, so nothing flashes faster than 3 Hz): neon breathes at
# different slow rates; the marquee bulbs blink (~1.4 Hz); the window strips breathe slowly; goo flows down the
# falls and ripples in the ponds; the floating cubes bob; sparkle motes rise; Judge Martello does his little "boing"
# hop in place; clouds drift. Clearances: the cubes only float over open ground (br_build), so their 1.2-stud bob
# never meets a tower; Martello hops in the middle of an empty r-52 floor; the motes are tiny and pass through.
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "brainrot_zone.blend"))
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]

A.CANOPY_LOOKS = A.CANOPY_LOOKS + ("leaf_magenta", "leaf_lilac", "leaf_sky")  # the grove canopies (br_build)
print("[amb] wind on", A.wind(["Vegetation"]))
A.animate_water("goo_fall", True)
A.animate_water("goo", False)
A.breathe("glow_magenta", 2.4, 0.9, 1.6)
A.breathe("glow_cyan", 2.4, 0.8, 2.1, 1.2)
A.breathe("glow_lime", 2.2, 0.8, 1.2, 2.4)
A.breathe("glow_green", 2.6, 1.0, 1.8, 1.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)
A.breathe("glow_white", 2.5, 0.3, 0.7, 0.5)  # window strips: a slow breath (no fast flicker: nothing flashes over 3 Hz)

boss = bpy.data.objects.get("Boss_JudgeMartello")
if boss:
    A.pivot_to(boss, 6, 86, 0)
    A.idle(boss, sway_deg=4, bob=1.6, period=0.9)  # boing
cubes = bpy.data.objects.get("Floating_Cubes")
if cubes:
    A.idle(cubes, sway_deg=0.0, bob=1.2, period=4.0)
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    A.drift(cl, (30, 12, 2), 20)
spark = A.mote(EFX, "Sparkle", "ico", 0.14, (150, 240, 255), emit=2.0)
A.particles(EFX, "Sparkles", (0, 0), (300, 340), 900, spark, lifetime=260, normal=0.35, brownian=0.3, start=-260, end=240, z=0.6)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "brainrot_zone.blend"), compress=True)
print("[amb] ambience added; brainrot_zone.blend saved")
