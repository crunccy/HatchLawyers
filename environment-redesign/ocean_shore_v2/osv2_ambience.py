# environment-redesign/ocean_shore_v2/osv2_ambience.py - Ocean Shore v2's ambience, saved into ocean_shore_v2.blend
# (2026-10-19). Scrub the timeline (no preview clips: crnuch's call). Run osv2_build.py first.
#   Blender -b --python environment-redesign/ocean_shore_v2/osv2_ambience.py
# A living tropical island that never hides Megalodon's warning lanes: nothing moves over his box except his own idle.
#   - palms, bushes, grass sway (WindSway on Vegetation + its own studs)
#   - the pools, shallows, falls, foam and the far sea flow (animated water shaders, foam-white highlights)
#   - splashes + mist where the high cascade lands; spray off the edge falls
#   - sun sparkles over the pools; purple motes rising at the portal; the portal breathes; torches flicker (< 3 Hz)
#   - clouds drift, the floating islets bob, gulls circle high round the edges (rings kept off the warning lanes)
#   - Megalodon sways on his start pad
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A
import hl_kit as K
import hl_classic as CL

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "ocean_shore_v2.blend"))
LAY = json.load(open(os.path.join(HERE, "osv2_layout.json")))
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]
for m in bpy.data.materials:  # (reuse the build's materials by name)
    K.MATS[m.name] = m
SAND_Z = 1.0

print("[amb] wind on", len(A.wind(["Vegetation"])), "objects")
A.animate_water("pool", False, highlight=(0.86, 0.98, 1.0))
A.animate_water("pool_deep", False, highlight=(0.7, 0.92, 1.0))
A.animate_water("shallows", False, highlight=(0.92, 1.0, 1.0))
A.animate_water("sea", False, highlight=(0.72, 0.93, 1.0))
A.animate_water("foam_fall", True, highlight=(1.0, 1.0, 1.0))
A.animate_water("foam_water", False, highlight=(1.0, 1.0, 1.0))
A.breathe("glow_portal", 3.0, 0.8, 1.6)
A.breathe("portal_vortex", 1.1, 0.4, 2.2, 0.8)
A.breathe("glow_torch", 3.4, 0.55, 8.5)  # ~1.35 Hz flicker
A.breathe("glow_ember", 2.6, 0.5, 6.0, 1.1)

cl = bpy.data.objects.get("Sky_Clouds")
if cl:
    A.drift(cl, (40, 15, 0), 20)
isl = bpy.data.objects.get("Sky_Islets")
if isl:
    A.idle(isl, sway_deg=0.0, bob=1.2, period=8.0)
boss = bpy.data.objects.get("Boss_Megalodon")
pad = next(p for p in LAY["places"] if p["name"].startswith("Megalodon"))["blender_xy"]
if boss:
    A.pivot_to(boss, pad[0], pad[1], SAND_Z)
    A.idle(boss, sway_deg=6, bob=0.25, period=3.2)

splash = A.mote(EFX, "Splash", "box", (0.32, 0.32, 0.32), (245, 252, 255), emit=0.4)
mist = A.mote(EFX, "Mist_Puff", "box", (1.3, 1.3, 1.0), (240, 250, 255), emit=0.25)
for k, (x, y, z) in enumerate(LAY["fx"]["fall_landings"]):
    A.particles(EFX, f"Cascade_Splash_{k}", (x, y), (3.0, 3.0), 170, splash, lifetime=32, normal=4.5, brownian=0.6, gravity=0.8,
                start=-60, end=240, z=z + 0.3, size_random=0.7)
    A.particles(EFX, f"Cascade_Mist_{k}", (x, y), (5.0, 5.0), 45, mist, lifetime=90, normal=0.6, brownian=0.4, start=-120, end=240,
                z=z + 1.0, size_random=0.6)
for k, (x, y, z, deg) in enumerate(LAY["fx"]["edge_lips"]):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    A.particles(EFX, f"Edge_Spray_{k}", (x + c * 3, y + s * 3), (3.0, 3.0), 90, splash, lifetime=55, normal=1.0, brownian=0.5, gravity=0.35,
                start=-80, end=240, z=z - 3, size_random=0.7)
sparkle = A.mote(EFX, "Sun_Sparkle", "box", (0.18, 0.18, 0.18), (255, 252, 230), emit=3.0)
for k, (x, y, R) in enumerate(LAY["fx"]["pools"]):
    A.particles(EFX, f"Pool_Sparkle_{k}", (x, y), (R * 0.7, R * 0.55), 24, sparkle, lifetime=40, normal=0.15, brownian=0.2,
                start=-60, end=240, z=1.0, size_random=0.5)
portal = next(p for p in LAY["places"] if p["name"].startswith("ESCAPE PORTAL"))["blender_xy"]
mote = A.mote(EFX, "Portal_Mote", "box", (0.28, 0.28, 0.28), (200, 130, 255), emit=3.0)
A.particles(EFX, "Portal_Motes", (portal[0], portal[1]), (9.0, 3.0), 90, mote, lifetime=100, normal=1.2, brownian=0.35, start=-100,
            end=240, z=SAND_Z + 0.6, size_random=0.6)

# gulls: simple white birds with grey wingtips, circling on rings round the island's edge (high, off the lanes)
gm = CL.ClassicMesh("Gull_Model", EFX)
gm.brick(0, 0, -0.35, 2.0, 0.7, 0.7, "white", studs=False, bevel=0.2)
gm.brick(1.2, 0, -0.2, 0.6, 0.5, 0.5, "white", studs=False, bevel=0.15)
gm.brick(1.6, 0, -0.1, 0.4, 0.2, 0.2, "gold", studs=False, bevel=0.05)
for sgn in (-1, 1):
    gm.beam((0.1, sgn * 0.3, 0), (0.0, sgn * 2.2, 0.7), 1.0, 0.12, "white")
    gm.beam((0.0, sgn * 2.2, 0.7), (-0.4, sgn * 3.6, 0.2), 0.8, 0.1, "rock_grey_dark")
gull_src = gm.done()
gull_src.location = (0, 0, -900)
n = 0
for (cx, cy, r, h) in LAY["fx"]["gull_rings"]:
    for j in range(2):
        piv = bpy.data.objects.new(f"Gull_Ring_{n}", None)
        EFX.objects.link(piv)
        piv.location = (cx, cy, h + j * 6)
        g = bpy.data.objects.new(f"Gull_{n}", gull_src.data)
        EFX.objects.link(g)
        g.parent = piv
        g.location = (r + j * 12, 0, 0)
        g.rotation_euler = (0, 0, math.pi / 2)  # (flying along the circle)
        frames = int(A.FPS * (14 + 4 * j + n))
        sign = 1 if (n % 2 == 0) else -1
        piv.rotation_euler = (0, 0, j * 2.1)
        piv.keyframe_insert("rotation_euler", frame=1)
        piv.rotation_euler = (0, 0, j * 2.1 + sign * math.tau)
        piv.keyframe_insert("rotation_euler", frame=1 + frames)
        A.loop(piv, linear=True)
        A.idle(g, sway_deg=8, bob=0.6, period=1.6 + 0.2 * j)
        n += 1
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "ocean_shore_v2.blend"), compress=True)
print(f"[amb] ambience added ({n} gulls); ocean_shore_v2.blend saved")
