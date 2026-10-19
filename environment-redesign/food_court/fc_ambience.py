# environment-redesign/food_court/fc_ambience.py - Food Court's ambience, saved into food_court.blend
# (Stage 5, 2026-10-19). No preview stills / clips (crnuch's call): scrub the .blend's timeline to see it.
#   Blender -b --python environment-redesign/food_court/fc_ambience.py      (run fc_build.py first)
# Cheerful, busy, inviting (the brief): steam from the stall vents + the Fry Factory chimney, a little smoke from the
# pizza oven and the picnic grill, the BURGER BARN burger / DONUT DINER donut / PIZZA PALACE slice signs turning,
# soda pouring from the fountain, both falls flowing, string lights twinkling (bulbs blink at ~1.4 Hz, nothing over
# 3 Hz), warm lamps breathing, Big Cheese wobbling upright, orchard canopies swaying, clouds drifting.
# Clearances (nobody previews this, so they are reasoned here; fc_build places everything):
#   - steam / smoke rise from vents and chimneys with nothing above them (the stall vent sits at the roof's back corner,
#     clear of the roof food and of the string lights, which run from the stall FRONTS to the straw)
#   - the burger sign (r ~4.5) turns at z 18-24 beside the barn, above its eaves (z ~12 at that side)
#   - the donut sign (R 4.4, centre z 20.6) turns over the diner's side yard, above its roof (z 10.6 + roof donuts 1.8)
#   - the pizza slice (half-width 5) turns on the palace roof at local (0, 4): the front crenellations are at y -7.2,
#     the oven chimney at x 7.5-10.5, the turrets at x 14 - all outside its circle
#   - Big Cheese only wobbles in place (5 degrees, a 0.25 bob) in the middle of the open board
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "food_court.blend"))
LAY = json.load(open(os.path.join(HERE, "fc_layout.json")))
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]

print("[amb] wind on", A.wind(["Vegetation"]))
A.animate_water("soda_fall", True, highlight=(1.0, 0.93, 0.78))
A.animate_water("soda", False, highlight=(1.0, 0.86, 0.62))
A.animate_water("choco_fall", True, highlight=(0.64, 0.44, 0.28))
A.animate_water("choco", False, highlight=(0.56, 0.37, 0.22))
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)  # marquee + string-light bulbs blink (~1.4 Hz)
A.breathe("glow_warm", 2.4, 0.6, 1.3)
A.breathe("glow_red", 2.2, 0.5, 1.0, 1.4)  # the noodle-house lanterns
A.breathe("glow_green", 2.6, 1.0, 1.8, 1.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)

for sp in LAY["fx"]["spinners"]:  # the turning signs (each its own object; its studs are its children)
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

board = next(p for p in LAY["places"] if p["name"].startswith("THE CHEESE BOARD"))["blender_xy"]
boss = bpy.data.objects.get("Boss_BigCheese")
if boss:
    A.pivot_to(boss, 6, board[1] - 12, 0)
    A.idle(boss, sway_deg=5, bob=0.25, period=2.6)
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    A.drift(cl, (30, 12, 2), 20)

steam = A.mote(EFX, "Steam_Puff", "ico", 0.5, (245, 248, 255), emit=0.35)
for k, (x, y, z) in enumerate(LAY["fx"]["steam"]):
    big = z > 20  # the factory chimney puffs more
    A.particles(EFX, f"Steam_{k}", (x, y), (1.4, 1.4) if not big else (2.6, 2.6), 60 if not big else 140, steam,
                lifetime=60 if not big else 80, normal=2.0, brownian=0.25, start=-120, end=200, z=z, size_random=0.8)
smoke = A.mote(EFX, "Smoke_Puff", "ico", 0.6, (150, 150, 158), emit=0.0)
for k, (x, y, z) in enumerate(LAY["fx"]["smoke"]):
    A.particles(EFX, f"Smoke_{k}", (x, y), (1.6, 1.6), 50, smoke, lifetime=90, normal=1.4, brownian=0.3, start=-140,
                end=200, z=z, size_random=0.7)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "food_court.blend"), compress=True)
print("[amb] ambience added; food_court.blend saved")
