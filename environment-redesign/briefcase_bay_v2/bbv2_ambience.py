# environment-redesign/briefcase_bay_v2/bbv2_ambience.py - Briefcase Bay v2's ambience, saved into briefcase_bay_v2.blend
# (2026-10-19). Scrub the timeline (no preview clips: crnuch's call). Run bbv2_build.py first.
#   Blender -b --python environment-redesign/briefcase_bay_v2/bbv2_ambience.py
# A living bay that never hides the Senior Partner's warning fan: nothing moves over his lawn except his own idle and the
# papers round his ankles (BOSSES.md: "paper sheets swirl around his ankles").
#   - trees, palms, bushes sway (WindSway on Vegetation + its own studs)
#   - the bay, the pools, the fountain, the falls, foam and the far sea flow (animated water shaders)
#   - the ferry, the sailboat and the buoys bob; splashes + mist at the cascade; spray off the edge falls; fountain splashes
#   - sun sparkles on the pools + the bay; purple motes at the portal; the portal breathes
#   - tower crowns breathe cyan, aviation lights blink (0.5 Hz), the helipad + HQ seam glow, the lighthouse lantern
#     breathes and its beam sweeps the sea side (hidden in daylight stills)
#   - blossom petals drift down under the blossom trees; butterflies over the flower beds; gulls round the bay + edges
#   - clouds drift, the floating islets bob; the Senior Partner turns slowly on his pad
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_ambience as A
import hl_kit as K
import hl_classic as CL

bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "briefcase_bay_v2.blend"))
LAY = json.load(open(os.path.join(HERE, "bbv2_layout.json")))
FX = LAY["fx"]
scene = bpy.context.scene
scene.render.fps = A.FPS
scene.frame_start, scene.frame_end = 1, 240
EFX = bpy.data.collections["Environmental_Effects"]
for m in bpy.data.materials:  # (reuse the build's materials by name)
    K.MATS[m.name] = m
SAND_Z = 1.0

print("[amb] wind on", len(A.wind(["Vegetation"])), "objects")
for name, falling, hi in (("bay", False, (0.82, 0.97, 1.0)), ("bay_deep", False, (0.7, 0.92, 1.0)), ("fountain_water", False, (0.9, 1.0, 1.0)),
                          ("sea", False, (0.72, 0.93, 1.0)), ("foam_fall", True, (1.0, 1.0, 1.0)), ("foam_water", False, (1.0, 1.0, 1.0))):
    if name in bpy.data.materials:
        A.animate_water(name, falling, highlight=hi)
A.breathe("glow_portal", 3.0, 0.8, 1.6)
A.breathe("portal_vortex", 1.1, 0.4, 2.2, 0.8)
A.breathe("glow_cyan", 2.4, 0.6, 0.9)  # tower crowns: a slow breath
A.breathe("glow_aviation", 3.0, 2.8, 3.14, square=True)  # aviation lights: a 0.5 Hz blink
A.breathe("glow_heli", 2.4, 0.5, 1.2, 0.6)
A.breathe("glow_beacon", 3.4, 0.9, 0.8)
A.breathe("glow_scales", 1.6, 0.4, 0.7)

cl = bpy.data.objects.get("Sky_Clouds")
if cl:
    A.drift(cl, (40, 15, 0), 20)
isl = bpy.data.objects.get("Sky_Islets")
if isl:
    A.idle(isl, sway_deg=0.0, bob=1.2, period=8.0)
boats = bpy.data.objects.get("Boats")
if boats:
    A.pivot_to(boats, *FX["ferry"])
    A.idle(boats, sway_deg=1.2, bob=0.18, period=4.2)
boss = bpy.data.objects.get("Boss_SeniorPartner")
if boss:
    A.pivot_to(boss, *FX["boss_pad"])
    A.idle(boss, sway_deg=9, bob=0.08, period=4.4)  # (a slow turn on his pad: the pocket-watch idle in the game)

# the lighthouse beam: swept back and forth over the sea side (+-60 deg round the way it was built, 8 s a sweep)
beam = bpy.data.objects.get("Lighthouse_Beam")
if beam and FX.get("lighthouse"):
    lx, ly, lz, _ = FX["lighthouse"]
    A.pivot_to(beam, lx, ly, lz)
    for f, deg in ((1, -60), (121, 60), (241, -60)):
        beam.rotation_euler = (0, 0, math.radians(deg))
        beam.keyframe_insert("rotation_euler", frame=f)
    A.loop(beam)

splash = A.mote(EFX, "Splash", "box", (0.32, 0.32, 0.32), (245, 252, 255), emit=0.4)
mist = A.mote(EFX, "Mist_Puff", "box", (1.3, 1.3, 1.0), (240, 250, 255), emit=0.25)
for k, (x, y, z) in enumerate(FX["fall_landings"]):
    A.particles(EFX, f"Cascade_Splash_{k}", (x, y), (3.0, 3.0), 170, splash, lifetime=32, normal=4.5, brownian=0.6, gravity=0.8,
                start=-60, end=240, z=z + 0.3, size_random=0.7)
    A.particles(EFX, f"Cascade_Mist_{k}", (x, y), (5.0, 5.0), 45, mist, lifetime=90, normal=0.6, brownian=0.4, start=-120, end=240,
                z=z + 1.0, size_random=0.6)
for k, (x, y, z, deg) in enumerate(FX["edge_lips"]):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    A.particles(EFX, f"Edge_Spray_{k}", (x + c * 3, y + s * 3), (3.0, 3.0), 90, splash, lifetime=55, normal=1.0, brownian=0.5, gravity=0.35,
                start=-80, end=240, z=z - 3, size_random=0.7)
drop = A.mote(EFX, "Fountain_Drop", "box", (0.22, 0.22, 0.22), (235, 250, 255), emit=0.3)
for k, (x, y, z) in enumerate(FX["fountain"]):
    A.particles(EFX, f"Fountain_Splash_{k}", (x, y), (1.2, 1.2), 50, drop, lifetime=20, normal=2.4, brownian=0.4, gravity=0.8,
                start=-40, end=240, z=z + 0.1, size_random=0.6)
sparkle = A.mote(EFX, "Sun_Sparkle", "box", (0.18, 0.18, 0.18), (255, 252, 230), emit=3.0)
for k, (x, y, R) in enumerate(FX["pools"]):
    A.particles(EFX, f"Pool_Sparkle_{k}", (x, y), (R * 0.7, R * 0.55), 24, sparkle, lifetime=40, normal=0.15, brownian=0.2,
                start=-60, end=240, z=1.0, size_random=0.5)
bay = next(p for p in LAY["places"] if p["name"] == "The Bay")["blender_xy"]
A.particles(EFX, "Bay_Sparkle", (bay[0], bay[1]), (24, 14), 50, sparkle, lifetime=40, normal=0.15, brownian=0.2, start=-60, end=240,
            z=1.0, size_random=0.5)
portal = next(p for p in LAY["places"] if p["name"].startswith("ESCAPE PORTAL"))["blender_xy"]
mote = A.mote(EFX, "Portal_Mote", "box", (0.28, 0.28, 0.28), (200, 130, 255), emit=3.0)
A.particles(EFX, "Portal_Motes", (portal[0], portal[1]), (9.0, 3.0), 90, mote, lifetime=100, normal=1.2, brownian=0.35, start=-100,
            end=240, z=SAND_Z + 0.6, size_random=0.6)
petal = A.mote(EFX, "Blossom_Petal", "box", (0.32, 0.32, 0.06), (252, 186, 210), emit=0.1)
for k, (x, y, z) in enumerate(FX["blossoms"]):
    A.particles(EFX, f"Petals_{k}", (x, y), (5.0, 5.0), 14, petal, lifetime=110, normal=-0.05, brownian=0.25, gravity=0.04,
                start=-110, end=240, z=z, size_random=0.5, rotations=True, ang_vel=2.0)
paper = A.mote(EFX, "Paper_Sheet", "box", (0.9, 1.2, 0.03), (250, 250, 244), emit=0.05)
bx, by, bz = FX["boss_pad"]
A.particles(EFX, "Papers_At_His_Ankles", (bx, by), (7.0, 7.0), 16, paper, lifetime=70, normal=0.25, brownian=0.9, gravity=0.02,
            start=-70, end=240, z=bz + 0.4, size_random=0.4, rotations=True, ang_vel=3.0)
A.butterflies(EFX, [tuple(r) for r in FX["butterfly_rings"]], n=12)

# gulls: white birds with grey wingtips circling the bay, the lighthouse and the edges (high, never over the lawn)
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
for (cx, cy, r, h) in FX["gull_rings"]:
    for j in range(2):
        piv = bpy.data.objects.new(f"Gull_Ring_{n}", None)
        EFX.objects.link(piv)
        piv.location = (cx, cy, h + j * 6)
        g = bpy.data.objects.new(f"Gull_{n}", gull_src.data)
        EFX.objects.link(g)
        g.parent = piv
        g.location = (r + j * 8, 0, 0)
        g.rotation_euler = (0, 0, math.pi / 2)
        frames = int(A.FPS * (14 + 4 * j + n))
        sign = 1 if (n % 2 == 0) else -1
        piv.rotation_euler = (0, 0, j * 2.1)
        piv.keyframe_insert("rotation_euler", frame=1)
        piv.rotation_euler = (0, 0, j * 2.1 + sign * math.tau)
        piv.keyframe_insert("rotation_euler", frame=1 + frames)
        A.loop(piv, linear=True)
        A.idle(g, sway_deg=8, bob=0.6, period=1.6 + 0.2 * j)
        n += 1
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "briefcase_bay_v2.blend"), compress=True)
print(f"[amb] ambience added ({n} gulls, {len(FX['blossoms'])} blossom trees); briefcase_bay_v2.blend saved")
