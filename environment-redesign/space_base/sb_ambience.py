# environment-redesign/space_base/sb_ambience.py - Space Base's ambience, saved into space_base.blend
# (Stage 5, 2026-10-19, mr.robe's session). No preview stills / clips (crnuch's call): scrub the .blend's timeline.
#   Blender -b --python environment-redesign/space_base/sb_ambience.py      (run sb_build.py first)
# Quiet, glowing, a little mysterious (the brief): the hologram planet turning over mission control, the observatory
# dome creeping round, the radar and the big dish sweeping, steam curling off the rocket's pad, glowing spores drifting
# over the alien garden, plasma falls flowing, neon breathing, red beacons blinking (~0.7 Hz; marquee bulbs ~1.4 Hz,
# nothing over 3 Hz), Chief Justice Eclipse hovering, asteroids drifting.
# Clearances (nobody previews this, so they are reasoned here; sb_build places everything):
#   - the hologram planet (r 4.2, its ring r 7.4, moons at r 9.5) turns at z ~16.8 above the plaza's projector; the
#     kiosks' light strings run round the ring at r ~22-26, outside its sweep
#   - the observatory dome turns on its own drum (r 10 inside the drum's r 10.4 rim); the telescope poking out of the
#     slit reaches r ~10.4 at z +5..9 above the drum, clear of everything (nothing tall within 14 studs)
#   - the radar (half-width 2.5) turns on the factory roof between the two vent stacks (x -8 / +8, r 2.2): 5.5 studs clear
#   - the big dish (r ~7.8 bowl) turns on its own pad at the west edge, nothing within 9 studs
#   - Eclipse only hovers in place (4 degrees, a 1.0 bob) in the middle of the open ring
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "space_base.blend"))
LAY = json.load(open(os.path.join(HERE, "sb_layout.json")))
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]

A.animate_water("goo_plasma", False, highlight=(0.88, 1.0, 1.0))
A.animate_water("goo_plasma_fall", True, highlight=(0.92, 1.0, 1.0))
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)  # marquee bulbs blink (~1.4 Hz)
A.breathe("glow_red", 2.4, 1.4, 4.4, square=True)  # beacons blink (~0.7 Hz)
A.breathe("glow_cyan", 2.4, 0.8, 1.6)
A.breathe("glow_magenta", 2.4, 0.8, 1.3, 1.0)
A.breathe("glow_lime", 2.2, 0.7, 1.1, 2.0)
A.breathe("glow_pink", 2.4, 0.8, 1.4, 0.5)
A.breathe("glow_purple", 2.0, 0.7, 1.0, 1.5)
A.breathe("glow_gold", 3.0, 0.8, 1.2)
A.breathe("portal_holo", 1.1, 0.5, 2.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)

for sp in LAY["fx"]["spinners"]:  # the hologram, the dome, the radar, the dish (each its own object; studs are children)
    ob = bpy.data.objects.get(sp["name"])
    if not ob:
        continue
    A.pivot_to(ob, *sp["pivot"])
    frames = int(A.FPS * sp["seconds_per_turn"])
    ob.rotation_euler = (0, 0, 0)
    ob.keyframe_insert("rotation_euler", frame=1)
    ob.rotation_euler = (0, 0, math.tau)
    ob.keyframe_insert("rotation_euler", frame=1 + frames)
    A.loop(ob, linear=True)

ring = next(p for p in LAY["places"] if p["name"].startswith("THE ECLIPSE RING"))["blender_xy"]
boss = bpy.data.objects.get("Boss_Eclipse")
if boss:
    A.pivot_to(boss, 0, ring[1], 1.4)
    A.idle(boss, sway_deg=4, bob=1.0, period=4.0)
ast = bpy.data.objects.get("Asteroids")
if ast:
    A.drift(ast, (24, 10, 4), 20)

steam = A.mote(EFX, "Steam_Puff", "ico", 0.7, (240, 244, 255), emit=0.3)
for k, (x, y, z) in enumerate(LAY["fx"]["steam"]):
    A.particles(EFX, f"Steam_{k}", (x, y), (7.0, 7.0), 140, steam, lifetime=70, normal=1.2, brownian=0.6, start=-120,
                end=200, z=z, size_random=0.8)
spore = A.mote(EFX, "Spore", "ico", 0.15, (190, 255, 150), emit=3.0)
for k, (x, y, z, r) in enumerate(LAY["fx"]["motes"]):
    A.particles(EFX, f"Spores_{k}", (x, y), (r, r), 90, spore, lifetime=140, normal=0.25, brownian=0.45, start=-200,
                end=200, z=z, size_random=0.6)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "space_base.blend"), compress=True)
print("[amb] ambience added; space_base.blend saved")
