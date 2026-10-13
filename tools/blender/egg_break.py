# tools/blender/egg_break.py - the hatch's shell break, simulated in Blender (2026-10-12, eggs v5).
# Loads the 12 shell chunks that tools/blender/eggs_v5.py wrote to _egg_export/, gives each a kick, and lets
# Blender's rigid-body physics (gravity, tumbling, bouncing on the floor at z = 0) play it out. Three takes:
#   pop    (Common, Uncommon)  the top cap pops up and tumbles off, the cup falls open like petals
#   burst  (Rare, Epic)        harder: everything flies, the top higher
#   blast  (Legendary+)        an explosion: chunks fly far and bounce
# Exported to tools/zones/egg_break.json (30 fps, each chunk's centre + rotation per frame, Roblox axes, egg space:
# the egg's bottom centre at the origin, 3.8 tall) -> tools/zones/BuildEggsV5.lua writes it into
# ReplicatedStorage.EggModels.BreakAnims. Run inside Blender: tools/blender/send.ps1 -File tools/blender/egg_break.py
import bpy, json, math, os, random
from mathutils import Vector, Matrix

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
SRC = os.path.join(REPO, "_egg_export")
OUT = os.path.join(REPO, "tools", "zones", "egg_break.json")
FPS, FRAMES = 30, 54
GRAVITY = -42.0  # (snappier than real gravity: the egg is 3.8 studs, cartoon timing)
manifest = json.load(open(os.path.join(SRC, "manifest.json")))

TAKES = {
    # top: (up, out), bottom: (up, out), spin, seed
    "pop": dict(top=(14.0, 2.4), bot=(1.5, 1.7), spin=4.5, seed=1),
    "burst": dict(top=(19.0, 9.0), bot=(6.5, 8.0), spin=10.0, seed=2),
    "blast": dict(top=(16.0, 19.0), bot=(11.0, 17.0), spin=17.0, seed=3),
}


def rbx_to_b(x, y, z):
    return Vector((x, -z, y))


def load_chunk(name):
    d = json.load(open(os.path.join(SRC, manifest["meshes"][name]["file"])))
    lo, hi = d["lo"], d["hi"]
    c_r = [(lo[i] + hi[i]) / 2 for i in range(3)]
    c = rbx_to_b(*c_r)
    v = d["v"]
    verts = [tuple(rbx_to_b(v[i], v[i + 1], v[i + 2])) for i in range(0, len(v), 3)]  # (the export already centres each mesh on its box)
    f = d["f"]
    faces = [(f[i], f[i + 3], f[i + 6]) for i in range(0, len(f), 9)]
    return verts, faces, c, c_r


sc = bpy.data.scenes.get("EggBreak") or bpy.data.scenes.new("EggBreak")
win = bpy.context.window
prev_scene = win.scene
win.scene = sc
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc.render.fps = FPS
sc.frame_start, sc.frame_end = 1, FRAMES + 2
if sc.rigidbody_world is None:
    bpy.ops.rigidbody.world_add()
rbw = sc.rigidbody_world
if rbw.collection is None:
    rbw.collection = bpy.data.collections.new("EggBreakRB")
sc.gravity = (0, 0, GRAVITY)
rbw.substeps_per_frame = 20
rbw.solver_iterations = 20
rbw.point_cache.frame_start, rbw.point_cache.frame_end = 1, FRAMES + 2

# the floor
me = bpy.data.meshes.new("EB_Floor")
me.from_pydata([(-60, -60, 0), (60, -60, 0), (60, 60, 0), (-60, 60, 0)], [], [(0, 1, 2, 3)])
floor = bpy.data.objects.new("EB_Floor", me)
sc.collection.objects.link(floor)
with bpy.context.temp_override(scene=sc, object=floor, active_object=floor, selected_objects=[floor], selected_editable_objects=[floor]):
    bpy.ops.rigidbody.object_add(type="PASSIVE")
floor.rigid_body.friction = 0.7
floor.rigid_body.restitution = 0.45
floor.rigid_body.collision_collections = [True] * 20

chunks = []
for i, name in enumerate(manifest["chunks"]):
    verts, faces, c, c_r = load_chunk(name)
    me = bpy.data.meshes.new("EB_" + name)
    me.from_pydata(verts, [], faces)
    o = bpy.data.objects.new("EB_" + name, me)
    o.location = c
    sc.collection.objects.link(o)
    with bpy.context.temp_override(scene=sc, object=o, active_object=o, selected_objects=[o], selected_editable_objects=[o]):
        bpy.ops.rigidbody.object_add(type="ACTIVE")
    rb = o.rigid_body
    rb.collision_shape = "CONVEX_HULL"
    rb.mass = 1.0
    rb.friction = 0.6
    rb.restitution = 0.4
    rb.linear_damping = 0.04
    rb.angular_damping = 0.15
    rb.use_margin = True
    rb.collision_margin = 0.01
    # chunks only hit the floor, never each other (they start interlocked)
    cc = [False] * 20
    cc[i % 19 + 1] = True
    rb.collision_collections = cc
    chunks.append(dict(name=name, obj=o, c=c, top=manifest["meshes"][name].get("top", False)))

def set_linear(o):
    """LINEAR interpolation on every key of o's animation (Blender 4.4+ keeps keys in action layers / slots)."""
    act = o.animation_data and o.animation_data.action
    if not act:
        return
    curves = []
    if hasattr(act, "fcurves"):
        try:
            curves = list(act.fcurves)
        except Exception:
            curves = []
    if not curves and hasattr(act, "layers"):
        for layer in act.layers:
            for strip in layer.strips:
                for bag in getattr(strip, "channelbags", []):
                    curves.extend(bag.fcurves)
    for fc in curves:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"


Mx = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
result = dict(fps=FPS, frames=FRAMES, chunks=manifest["chunks"], rest={}, takes={})
for ch in chunks:
    result["rest"][ch["name"]] = [round(ch["c"].x, 4), round(ch["c"].z, 4), round(-ch["c"].y, 4)]

for take, cfg in TAKES.items():
    rnd = random.Random(cfg["seed"])
    rbw.point_cache.frame_start = 1
    # the kick: animated (kinematic) for frames 1-2 moving along the velocity, dynamic from frame 3 - Blender hands
    # the animation's velocity to the physics
    for ch in chunks:
        o = ch["obj"]
        o.animation_data_clear()
        c = ch["c"]
        radial = Vector((c.x, c.y, 0))
        radial = radial.normalized() if radial.length > 1e-4 else Vector((1, 0, 0))
        up, out = cfg["top"] if ch["top"] else cfg["bot"]
        up *= rnd.uniform(0.8, 1.2)
        out *= rnd.uniform(0.75, 1.25)
        vel = radial * out + Vector((0, 0, up))
        spin = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) * cfg["spin"]
        dt = 1.0 / FPS
        for f in (1, 2, 3):  # moving at a steady speed through frame 3 (LINEAR keys), physics from frame 4
            o.location = c + vel * dt * (f - 1)
            o.rotation_euler = tuple(spin * dt * (f - 1))
            o.keyframe_insert("location", frame=f)
            o.keyframe_insert("rotation_euler", frame=f)
            o.rigid_body.kinematic = True
            o.rigid_body.keyframe_insert("kinematic", frame=f)
        o.rigid_body.kinematic = False
        o.rigid_body.keyframe_insert("kinematic", frame=4)
        set_linear(o)
    rbw.point_cache.frame_end = FRAMES + 2
    # step the simulation frame by frame (the cache fills as it goes)
    sc.frame_set(1)
    frames = {ch["name"]: [] for ch in chunks}
    for f in range(1, FRAMES + 1):
        sc.frame_set(f)
        for ch in chunks:
            mw = ch["obj"].matrix_world
            p = mw.to_translation()
            R = mw.to_3x3().normalized()
            Rr = Mx @ R @ Mx.transposed()
            q = Rr.to_quaternion()
            frames[ch["name"]].extend([round(p.x, 3), round(p.z, 3), round(-p.y, 3), round(q.x, 4), round(q.y, 4), round(q.z, 4), round(q.w, 4)])
    result["takes"][take] = frames
    # reset for the next take
    rbw.point_cache.frame_start = 1
    sc.frame_set(1)
    bpy.ops.ptcache.free_bake_all()

with open(OUT, "w") as fh:
    json.dump(result, fh, separators=(",", ":"))
# a quick report: how high / far the chunks got in each take
rep = []
for take, frames in result["takes"].items():
    maxh = max(v[i + 1] for v in frames.values() for i in range(0, len(v), 7))
    far = max(math.hypot(v[i], v[i + 2]) for v in frames.values() for i in range(0, len(v), 7))
    endh = max(v[-6] for v in frames.values())
    rep.append(f"{take}: top {maxh:.2f}, far {far:.2f}, end max height {endh:.2f}")
win.scene = prev_scene
print("; ".join(rep), "->", OUT)
