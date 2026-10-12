# tools/blender/carry_anim.py - the egg-carry animation (2026-10-12, replaces CarryPose's per-frame arm Transforms).
# Builds Roblox's default R15 rig (tools/blender/r15_rig.json, read from Studio) as an armature + block parts, the
# carried egg pile on the chest, keys a looping carry pose, renders it (art/carry/*.png) and exports the keyframes as
# Roblox joint Transforms (tools/blender/carry_anim.json) -> tools/zones/BuildCarryAnimation.lua makes the
# KeyframeSequence in Studio.
# The trick that keeps it exact: every bone's rest matrix is its Roblox joint frame (Part0.CFrame * C0) mapped into
# Blender, so a pose bone's local rotation IS the joint's Transform (same axes, same handedness). Roblox (x, y, z) ->
# Blender (x, -z, y); the character faces Roblox -Z = Blender +Y.
# Works in its own scene "CarryAnim"; never touches the other scenes.
import bpy, json, math, os
from mathutils import Matrix, Vector

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
RIG = json.load(open(os.path.join(REPO, "tools", "blender", "r15_rig.json")))
OUT_JSON = os.path.join(REPO, "tools", "blender", "carry_anim.json")
ART = os.path.join(REPO, "art", "carry")
os.makedirs(ART, exist_ok=True)

FPS, LOOP = 30, 60  # a 2 s loop
# ------------------------------------------------------------------ the pose (degrees, Roblox joint space)
# Shoulder: pitch forward (+X), then turn in (Y; +right / -left). Elbow: bend forward (+X). Wrist: cup in (Z roll).
# Waist: lean back a little under the weight (+X tips the chest back).
POSE = {
    "shoulder_pitch": None, "shoulder_in": None, "elbow": None,  # None = solved (hands on the bottom egg's sides)
    "wrist_cup": 14, "waist_back": 5,
    # the idle loop: a slow "hug" - arms squeeze in and lift a touch, the chest breathes
    "hug_pitch": 2.5, "hug_in": 2, "breathe": 1.5,
}
# the egg pile (same numbers as StarterPlayerScripts.CarryPose): EGG_WIDTH x the torso's width, the bottom egg's
# centre EGG_DROP x the torso's height below the torso's centre, touching the chest
EGG_WIDTH, EGG_TALL, EGG_DROP, NEST, LEAN_BACK, LEAN_TILT = 0.68, 1.22, 0.27, 0.78, 0.12, math.radians(5)
HAND_GRIP = (0.30, -0.12, -0.18)  # where each hand's centre sits: x outside the egg's side, y / z from its centre
JITTER = [(0, 0, 0), (0.16, 9, 25), (-0.14, -11, -40)]
EGG_COLORS = [(0.96, 0.78, 0.27), (0.95, 0.55, 0.65), (1.0, 0.80, 0.16)]

M4 = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))  # Roblox -> Blender
GROUND = Matrix.Translation((0, -96.807, 0))  # rig's feet on y = 0 (Roblox space)


def cf(c):
    return Matrix(((c[3], c[4], c[5], c[0]), (c[6], c[7], c[8], c[1]), (c[9], c[10], c[11], c[2]), (0, 0, 0, 1)))


def angles(rx, ry, rz):  # Roblox CFrame.Angles = Rx * Ry * Rz
    return Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z")


parts = {n: {"size": p["size"], "cf": GROUND @ cf(p["cf"])} for n, p in RIG["parts"].items()}
joints = RIG["joints"]
bone_of_part = {j["p1"]: name for name, j in joints.items()}  # part -> joint that moves it

# ------------------------------------------------------------------ scene
sc = bpy.data.scenes.get("CarryAnim") or bpy.data.scenes.new("CarryAnim")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc.render.fps = FPS
sc.frame_start, sc.frame_end = 0, LOOP

arm_data = bpy.data.armatures.new("CarryRig")
arm = bpy.data.objects.new("CarryRig", arm_data)
sc.collection.objects.link(arm)

# edit bones need the armature in edit mode, in a view layer of this scene
win = bpy.context.window
prev_scene = win.scene
win.scene = sc
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
frames = {}  # joint name -> rest frame (Roblox space)
for name, j in joints.items():
    frames[name] = parts[j["p0"]]["cf"] @ cf(j["c0"])
for name, j in joints.items():
    eb = arm_data.edit_bones.new(j["p1"])
    eb.head, eb.tail = (0, 0, 0), (0, 0.25, 0)
    eb.matrix = M4 @ frames[name]
for name, j in joints.items():
    parent_joint = bone_of_part.get(j["p0"])
    if parent_joint:
        arm_data.edit_bones[j["p1"]].parent = arm_data.edit_bones[joints[parent_joint]["p1"]]
bpy.ops.object.mode_set(mode="OBJECT")


def box(name, size, world, bone, color):
    sx, sy, sz = size[0] / 2, size[1] / 2, size[2] / 2
    corners = [(x, y, z) for x in (-sx, sx) for y in (-sy, sy) for z in (-sz, sz)]
    verts = [(M4 @ world @ Vector(c)).to_tuple() for c in corners]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    vg = ob.vertex_groups.new(name=bone)
    vg.add(list(range(8)), 1.0, "REPLACE")
    ob.modifiers.new("Rig", "ARMATURE").object = arm
    ob.color = (*color, 1)
    return ob


SKIN, SUIT, PANTS = (1.0, 0.80, 0.55), (0.20, 0.30, 0.55), (0.22, 0.22, 0.28)
for n, p in parts.items():
    if n == "HumanoidRootPart":
        continue
    col = SKIN if ("Arm" in n and "Upper" not in n) or "Hand" in n or n == "Head" else SUIT if "Torso" in n or "UpperArm" in n else PANTS
    box(n, p["size"], p["cf"], n, col)

# eggs: weighted to the UpperTorso bone (CarryPose welds them to UpperTorso)
torso = parts["UpperTorso"]
tsize = torso["size"]
w = tsize[0] * EGG_WIDTH
h = w * EGG_TALL
egg_offsets = []
y = -tsize[1] * EGG_DROP
z = -(tsize[2] * 0.5 + w * 0.5 - 0.1)
egg1_centre = Vector((0, y, z))
tilt = 0.0
for i, (jx, jroll, jyaw) in enumerate(JITTER):
    if i > 0:
        y += h * NEST
        z += LEAN_BACK
        tilt += LEAN_TILT
    off = Matrix.Translation((jx * w, y, z)) @ angles(tilt, math.radians(jyaw), math.radians(jroll))
    egg_offsets.append(off)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1)
    ob = bpy.context.active_object
    for c in ob.users_collection:
        c.objects.unlink(ob)
    sc.collection.objects.link(ob)
    ob.name = f"Egg{i + 1}"
    ob.data.transform(M4 @ torso["cf"] @ off @ Matrix.Diagonal((w / 2, h / 2, w / 2, 1)))
    vg = ob.vertex_groups.new(name="UpperTorso")
    vg.add(list(range(len(ob.data.vertices))), 1.0, "REPLACE")
    ob.modifiers.new("Rig", "ARMATURE").object = arm
    ob.color = (*EGG_COLORS[i], 1)


# ------------------------------------------------------------------ solve the arm (torso space, right side; left mirrors)
def hand_centre(pitch, turn, elbow):
    sh, el, wr = joints["RightShoulder"], joints["RightElbow"], joints["RightWrist"]
    upper = cf(sh["c0"]) @ Matrix.Rotation(turn, 4, "Y") @ Matrix.Rotation(pitch, 4, "X") @ cf(sh["c1"]).inverted()
    lower = upper @ cf(el["c0"]) @ Matrix.Rotation(elbow, 4, "X") @ cf(el["c1"]).inverted()
    return (lower @ cf(wr["c0"]) @ cf(wr["c1"]).inverted()).translation


target = egg1_centre + Vector((w / 2 + HAND_GRIP[0], HAND_GRIP[1], HAND_GRIP[2]))
best = None
for p in range(0, 101, 2):
    for t in range(0, 41, 2):
        for e in range(0, 121, 2):
            d = (hand_centre(math.radians(p), math.radians(t), math.radians(e)) - target).length
            # (a little preference for a relaxed elbow and less turn-in, so near-ties pick the natural pose)
            score = d + 0.0008 * e + 0.0015 * t
            if best is None or score < best[0]:
                best = (score, p, t, e, d)
_, sp, st, se, miss = best
POSE["shoulder_pitch"] = POSE["shoulder_pitch"] if POSE["shoulder_pitch"] is not None else sp
POSE["shoulder_in"] = POSE["shoulder_in"] if POSE["shoulder_in"] is not None else st
POSE["elbow"] = POSE["elbow"] if POSE["elbow"] is not None else se


# ------------------------------------------------------------------ keys
def pose_at(f):
    s = math.sin(2 * math.pi * f / LOOP)  # one hug per loop
    P = POSE
    out = {"UpperTorso": angles(math.radians(P["waist_back"] + P["breathe"] * s * 0.5), 0, 0)}
    for side, pre in ((1, "Right"), (-1, "Left")):
        pitch = math.radians(P["shoulder_pitch"] + P["hug_pitch"] * s)
        turn = math.radians(P["shoulder_in"] + P["hug_in"] * s)
        out[pre + "UpperArm"] = Matrix.Rotation(side * turn, 4, "Y") @ Matrix.Rotation(pitch, 4, "X")
        out[pre + "LowerArm"] = angles(math.radians(P["elbow"]), 0, 0)
        out[pre + "Hand"] = angles(0, 0, math.radians(side * P["wrist_cup"]))
    return out


KEYS = list(range(0, LOOP + 1, 6))  # dense enough that Linear easing in Roblox still looks like the sine
arm.animation_data_create()
arm.animation_data.action = bpy.data.actions.new("CarryEggs")
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
for f in KEYS:
    for bone, m in pose_at(f).items():
        pb = arm.pose.bones[bone]
        pb.rotation_quaternion = m.to_quaternion()
        pb.keyframe_insert("rotation_quaternion", frame=f)

# ------------------------------------------------------------------ check: where are the hands vs the bottom egg?
report = []
sc.frame_set(0)
dg = bpy.context.evaluated_depsgraph_get()
arm_eval = arm.evaluated_get(dg)
inv4 = M4.inverted()
t_frame = inv4 @ arm_eval.pose.bones["UpperTorso"].matrix @ cf(joints["Waist"]["c1"]).inverted()  # torso part, Roblox
egg1 = egg_offsets[0]
for pre in ("Right", "Left"):
    pb = arm_eval.pose.bones[pre + "Hand"]
    hand = inv4 @ pb.matrix @ cf(joints[pre + "Wrist"]["c1"]).inverted()
    rel = t_frame.inverted() @ hand.translation
    in_egg = egg1.inverted() @ rel
    # distance from the hand's centre to the egg's surface (ellipsoid, approx.)
    nd = Vector((in_egg.x / (w / 2), in_egg.y / (h / 2), in_egg.z / (w / 2))).length
    report.append(f"{pre} hand (torso space) ({rel.x:.2f}, {rel.y:.2f}, {rel.z:.2f})  egg-normalised dist {nd:.2f}")

# ------------------------------------------------------------------ renders
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_object_outline = True
sc.display.shading.show_cavity = True
sc.render.resolution_x = sc.render.resolution_y = 700
sc.render.film_transparent = False
sc.world = sc.world or bpy.data.worlds.new("CarryWorld")
cam_data = bpy.data.cameras.new("CarryCam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = 8.5
cam = bpy.data.objects.new("CarryCam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
target = Vector((0, 0.5, 3.4))
views = {"front": Vector((0, 12, 3.4)), "side": Vector((12, 0.5, 3.4)), "three_quarter": Vector((8, 8, 6.0))}
for name, pos in views.items():
    cam.location = pos
    cam.rotation_euler = (target - pos).to_track_quat("-Z", "Y").to_euler()
    sc.frame_set(0)
    sc.render.filepath = os.path.join(ART, f"carry_{name}.png")
    bpy.ops.render.render(write_still=True, scene=sc.name)

# ------------------------------------------------------------------ export (joint Transforms per key, Roblox CFrame components)
export = {"fps": FPS, "length": LOOP / FPS, "priority": "Action", "looped": True, "keys": [],
          "parents": {j["p1"]: j["p0"] for j in joints.values()},
          "eggs": {"width": EGG_WIDTH, "tall": EGG_TALL, "drop": EGG_DROP, "nest": NEST, "lean_back": LEAN_BACK},
          "solved": {"shoulder_pitch": POSE["shoulder_pitch"], "shoulder_in": POSE["shoulder_in"], "elbow": POSE["elbow"]}}
for f in KEYS:
    sc.frame_set(f)
    poses = {}
    for bone in pose_at(f):
        m = arm.pose.bones[bone].matrix_basis
        poses[bone] = [round(v, 5) for v in (m[0][3], m[1][3], m[2][3], m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2])]
    export["keys"].append({"time": f / FPS, "poses": poses})
with open(OUT_JSON, "w") as fh:
    json.dump(export, fh, indent=1)

win.scene = prev_scene
print(f"solved: shoulder {sp}° forward, {st}° in, elbow {se}° (hand misses its spot by {miss:.2f})\n"
      + "\n".join(report) + f"\negg w {w:.2f} h {h:.2f}, bottom egg centre ({egg1_centre.y:.2f}, {egg1_centre.z:.2f})"
      + f"\nkeys {len(KEYS)}, renders in {ART}")
