# environment-redesign/pet_park/pp_ambience.py - Pet Park's ambience in Blender (Stage 5, 2026-10-18).
# Opens pet_park.blend (run pp_build.py first), adds the living details, saves, renders previews:
#   Blender -b --python environment-redesign/pet_park/pp_ambience.py [-- stills | -- clips | -- only=pond,arena]
# Peaceful, adorable, lively (the brief): blossom + leaf canopies sway; petals and leaves drift down over the island;
# butterflies over the meadows and the pond; the pond ripples and both waterfalls flow; the arrival pad and RETURN
# HOME breathe; the marquee bulbs blink; Barrister Bulldog idles; clouds drift.
# Clearance (AMBIENCE.md rules), checked against pp_build.py's props:
#   Dog Meadow  ring r 7-13 round its centre (inside the bowl r 4.5 ... toys r 16+), z 3.5-7 (bowl 2.2, balls 3.6)
#   Cat Garden  ring r 5-14 (flower beds only; towers / cat / yarn sit at r 20+), z 3.5-7
#   The pond    ring r 18-24 over the water (corgi plinth r 15.3), z 5.5-8 (the bridge rails reach 4.9)
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, KIT)
import hl_kit as K
import hl_ambience as A

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.join(HERE, "renders", "ambience")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "pet_park.blend"))
scene = bpy.context.scene
scene.render.fps = A.FPS
EFX = bpy.data.collections["Environmental_Effects"]
PRES = bpy.data.collections["Presentation"]

print("[amb] wind on", A.wind(["Vegetation"]))
A.animate_water("water_fall", True)
A.animate_water("water", False)
A.breathe("glow_cyan", 2.4, 0.9, 2.0)
A.breathe("glow_green", 2.6, 1.0, 1.8, 1.0)
A.breathe("portal_home", 1.1, 0.45, 2.6)
A.breathe("glow_gold", 2.6, 0.8, 1.3, 2.0)
A.breathe("glow_bulb", 2.2, 1.2, 9.0, square=True)

boss = bpy.data.objects.get("Boss_BarristerBulldog")
if boss:
    A.pivot_to(boss, 8, 82, 0)
    A.idle(boss, sway_deg=8, bob=0.25, period=2.4)
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    A.drift(cl, (30, 12, 2), 20)

# petals + leaves drifting down over the island (one particle system picking from a petal and a leaf at random)
pick = bpy.data.collections.new("Drift_Motes")
bpy.context.scene.collection.children.link(pick)
pick.hide_render = True
for name, rgb, size in (("Petal", (255, 170, 205), (0.6, 0.45, 0.04)), ("Leaf", (110, 200, 60), (0.7, 0.4, 0.04))):
    ob = A.mote(EFX, name, "box", size, rgb)
    EFX.objects.unlink(ob)
    pick.objects.link(ob)
    ob.location = (0, 0, 0)
em = A.particles(EFX, "Drift", (0, 0), (300, 340), 600, A.mote(EFX, "Drift_Placeholder", "box", (0.01, 0.01, 0.01), (255, 255, 255)),
                 lifetime=520, normal=0.0, brownian=0.45, gravity=0.012, start=-400, end=200, rotations=True, ang_vel=1.8,
                 z=24, size_random=0.4)
ps = em.particle_systems[0].settings
ps.render_type = "COLLECTION"
ps.instance_collection = pick
ps.use_collection_pick_random = True

A.butterflies(EFX, [(-102, -28, 7, 13, 3.5, 7.0), (100, -22, 5, 14, 3.5, 7.0), (0, -25, 18, 24, 5.5, 8.0)], n=18,
              looks=("yellow", "pink", "sky_blue", "white", "orange", "purple"))

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "pet_park.blend"), compress=True)
print("[amb] ambience added; pet_park.blend saved")
A.bake()

CLIPS = {
    "arrival": (A.track_cam("Clip_Arrival", [(1, (0, -176, 9), (0, -60, 13)), (72, (0, -158, 10), (0, -50, 14))], 24, PRES), 72),
    "pond": (A.track_cam("Clip_Pond", [(1, (-38, -70, 12), (0, -22, 10)), (72, (-26, -74, 12), (0, -22, 11))], 26, PRES), 72),
    "arena": (A.track_cam("Clip_Arena", [(1, (-14, 14, 9), (6, 84, 12)), (72, (6, 12, 9), (8, 84, 12))], 24, PRES), 72),
    "aerial": (A.track_cam("Clip_Aerial", [(1, (-260, -580, 420), (0, 0, -25)), (72, (-210, -600, 420), (0, 0, -25))], 34, PRES), 72),
}
if bpy.data.collections.get("PP_Labels"):
    bpy.data.collections["PP_Labels"].hide_render = True
A.render_clips(scene, CLIPS, OUT, "pp_ambience", argv, K)
