# environment-redesign/ocean_shore/os_ambience.py - Ocean Shore's ambience, saved into ocean_shore.blend
# (Stage 5, 2026-10-19, mr.robe's session). No preview stills / clips (crnuch's call): scrub the .blend's timeline.
#   Blender -b --python environment-redesign/ocean_shore/os_ambience.py      (run os_build.py first)
# Sunny, breezy, relaxed (the brief): palms swaying, the lagoon + rock pools rippling, both falls flowing, Big Blue's
# spout spraying, bubbles rising in the tide pools, the lighthouse beam sweeping round, the SURF CLUB surfboard and
# the AQUARIUM fish signs turning, tiki flames breathing, marquee bulbs blinking (~1.4 Hz, nothing over 3 Hz), gulls
# circling, Megalodon swaying on the dock, clouds drifting.
# Clearances (nobody previews this, so they are reasoned here; os_build places everything):
#   - the lighthouse beam turns at z 34.9 (the lamp's centre), r 3.2-40: its first 2.8 studs are only 0.5 tall
#     (z 34.65-35.15), above the gallery ring (top z 34.6, r 4.9-5.3) and below the lamp-room roof (z 37.2); nothing
#     else within 40 studs of the lighthouse is taller than ~16 (palms, the cottage at ~10)
#   - the surfboard sign (half-width 1.6) turns at z 16-26 beside the SURF CLUB, 3 studs past its eaves (x 14)
#   - the fish sign (half-length ~5) turns at z 22-28 on its pole above the aquarium dome's top (z 19.6)
#   - spray rises from the spout top (z 14.2 over the plaza) and falls back into the pool (gravity), below the bunting
#     which runs round the shack ring at r ~21-26, not over the fountain
#   - gulls circle at r 176-205 round the island at z 26-38 (the lighthouse top, z 42.6, stands at r <= 172; the
#     hotel roof tops out at ~22) and at r 30-55 round the dock's middle at z 26-34 (Megalodon's head is at z ~27 but
#     stands within r ~19 of that centre)
#   - Megalodon only sways in place (6 degrees, a 0.3 bob) on the open dock
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "ocean_shore.blend"))
LAY = json.load(open(os.path.join(HERE, "os_layout.json")))
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]

print("[amb] wind on", A.wind(["Vegetation"]))
A.animate_water("lagoon", False, highlight=(0.82, 1.0, 0.98))
A.animate_water("water", False)
A.animate_water("water_fall", True)
A.animate_water("rockpool", False, highlight=(0.8, 0.96, 1.0))
A.animate_water("spout", True, highlight=(1.0, 1.0, 1.0))
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)  # marquee bulbs blink (~1.4 Hz)
A.breathe("glow_warm", 2.6, 0.7, 2.2)  # tiki flames + lamps breathe (~0.35 Hz)
A.breathe("glow_cyan", 2.4, 0.8, 1.6, 0.6)
A.breathe("glow_green", 2.6, 1.0, 1.8, 1.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)

for sp in LAY["fx"]["spinners"]:  # the beam + the turning signs (each its own object; its studs are its children)
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

dock = next(p for p in LAY["places"] if p["name"].startswith("THE SHARK DOCK"))["blender_xy"]
boss = bpy.data.objects.get("Boss_Megalodon")
if boss:
    A.pivot_to(boss, 6, dock[1] - 12, 1.2)
    A.idle(boss, sway_deg=6, bob=0.3, period=2.4)
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    A.drift(cl, (30, 12, 2), 20)

spray = A.mote(EFX, "Spray_Drop", "ico", 0.28, (215, 240, 255), emit=0.25)
for k, (x, y, z) in enumerate(LAY["fx"]["spray"]):
    A.particles(EFX, f"Spray_{k}", (x, y), (1.0, 1.0), 220, spray, lifetime=36, normal=4.5, brownian=0.4, gravity=0.6,
                start=-80, end=200, z=z, size_random=0.7)
bubble = A.mote(EFX, "Bubble", "ico", 0.16, (235, 250, 255), emit=0.15)
for k, (x, y, z, r) in enumerate(LAY["fx"]["bubbles"]):
    A.particles(EFX, f"Bubbles_{k}", (x, y), (r * 0.9, r * 0.9), 40, bubble, lifetime=40, normal=0.5, brownian=0.15,
                start=-60, end=200, z=z, size_random=0.6)
A.butterflies(EFX, [tuple(r) for r in LAY["fx"]["gull_rings"]], n=12, seed=55, looks=("white",))  # gulls (white wings)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "ocean_shore.blend"), compress=True)
print("[amb] ambience added; ocean_shore.blend saved")
