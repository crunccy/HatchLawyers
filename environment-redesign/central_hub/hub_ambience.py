# environment-redesign/central_hub/hub_ambience.py - STAGE 4: the central hub's ambience, animated in Blender (2026-10-18).
# Opens central_hub.blend (build it first with hub_build.py), adds the living details, saves it back and renders previews:
#   Blender -b --python environment-redesign/central_hub/hub_ambience.py [-- stills | -- clips | -- only=plaza,aerial]
#   stills: a few JPG frames per clip (to review);  clips: the MP4 previews in renders/ambience/
# What moves (and how Roblox would do it: AMBIENCE.md):
#   wind sway on every tree canopy (+ its studs)    Geometry Nodes, Scene Time
#   waterfalls flowing, ponds / fountain rippling   animated shader (scrolling bands / 4D noise)
#   glows breathing (portal, crystals, halos)       emission drivers
#   the portal's light swirl spinning               object rotation about the ring's axis
#   big cases riding the belt                       a cycling slide
#   butterflies (flapping, meandering)              keyframed paths + cycling wing flaps
#   floating pollen over the plaza                  particle system (no gravity, brownian)
#   clouds + islets drifting                        object animation
import bpy, math, os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "kit"))
import hl_kit as K

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.join(HERE, "renders", "ambience")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(HERE, "central_hub.blend"))
scene = bpy.context.scene
FPS = 24
scene.render.fps = FPS
rng = random.Random(44)
EFX = bpy.data.collections.get("Environmental_Effects")


def lin(c):
    return tuple((v / 255) ** 2.2 for v in c)


# ------------------------------------------------------------------ helpers
def time_value(nt):
    """A Value node that is the scene time in seconds (a simple driver: no Python needed at render)."""
    v = nt.nodes.new("ShaderNodeValue")
    fc = v.outputs[0].driver_add("default_value")
    fc.driver.type = "SCRIPTED"
    fc.driver.expression = f"frame / {FPS}"
    return v.outputs[0]


def math_node(nt, op, a, b=None, clamp=False):
    n = nt.nodes.new("ShaderNodeMath")
    n.operation = op
    n.use_clamp = clamp
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            n.inputs[i].default_value = v
        else:
            nt.links.new(v, n.inputs[i])
    return n.outputs[0]


def fcurves(ob):
    """An object's F-curves on both the legacy and the layered (Blender 4.4+ / 5.x) action layout."""
    ad = ob.animation_data
    act = ad.action if ad else None
    if not act:
        return []
    if hasattr(act, "fcurves"):
        try:
            if len(act.fcurves):
                return list(act.fcurves)
        except Exception:
            pass
    out = []
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for cb in getattr(strip, "channelbags", []):
                out.extend(cb.fcurves)
    return out


def loop(ob, linear=False):
    for fc in fcurves(ob):
        if linear:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"
        fc.modifiers.new("CYCLES")


# ------------------------------------------------------------------ 1. wind: canopies (and the studs on them) sway
def wind_group():
    ng = bpy.data.node_groups.new("WindSway", "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    N, L = ng.nodes, ng.links
    gi, go = N.new("NodeGroupInput"), N.new("NodeGroupOutput")
    sp = N.new("GeometryNodeSetPosition")
    pos = N.new("GeometryNodeInputPosition")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(pos.outputs[0], sep.inputs[0])
    t = N.new("GeometryNodeInputSceneTime").outputs["Seconds"]
    x, y, z = sep.outputs[0], sep.outputs[1], sep.outputs[2]
    phase = math_node(ng, "ADD", math_node(ng, "MULTIPLY", x, 0.06), math_node(ng, "MULTIPLY", y, 0.045))
    s1 = math_node(ng, "SINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 1.3), phase))
    s2 = math_node(ng, "COSINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 0.95), math_node(ng, "MULTIPLY", phase, 1.4)))
    gust = math_node(ng, "ADD", 0.75, math_node(ng, "MULTIPLY", math_node(ng, "SINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 0.35), math_node(ng, "MULTIPLY", x, 0.004))), 0.25))
    f = math_node(ng, "POWER", math_node(ng, "DIVIDE", math_node(ng, "SUBTRACT", z, 4.5), 12.0, clamp=True), 1.5)
    amp = math_node(ng, "MULTIPLY", f, gust)
    comb = N.new("ShaderNodeCombineXYZ")
    L.new(math_node(ng, "MULTIPLY", math_node(ng, "MULTIPLY", s1, amp), 0.42), comb.inputs[0])
    L.new(math_node(ng, "MULTIPLY", math_node(ng, "MULTIPLY", s2, amp), 0.3), comb.inputs[1])
    L.new(gi.outputs[0], sp.inputs["Geometry"])
    L.new(comb.outputs[0], sp.inputs["Offset"])
    L.new(sp.outputs[0], go.inputs[0])
    return ng


WIND = wind_group()
swayed = []
for ob in bpy.data.objects:
    if ob.type != "MESH":
        continue
    canopy_studs = ob.name.startswith("Studs_") and ob.name.split("Studs_", 1)[1] in ("leaf", "leaf_light", "leaf_deep", "blossom", "blossom_light")
    if ob.name == "Vegetation" or canopy_studs:
        ob.modifiers.new("Wind", "NODES").node_group = WIND
        swayed.append(ob.name)
print("[amb] wind on", swayed)


# ------------------------------------------------------------------ 2. water: falls flow down, ponds + fountain ripple
def animate_water(name, falling):
    m = bpy.data.materials.get(name)
    if not m:
        return
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    base = tuple(bsdf.inputs["Base Color"].default_value)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    t = time_value(nt)
    if falling:  # bright bands scrolling down
        mp = nt.nodes.new("ShaderNodeMapping")
        nt.links.new(geo.outputs["Position"], mp.inputs["Vector"])
        cz = nt.nodes.new("ShaderNodeCombineXYZ")
        nt.links.new(math_node(nt, "MULTIPLY", t, 14.0), cz.inputs[2])
        nt.links.new(cz.outputs[0], mp.inputs["Location"])
        wave = nt.nodes.new("ShaderNodeTexWave")
        wave.wave_type, wave.bands_direction = "BANDS", "Z"
        wave.inputs["Scale"].default_value = 0.09
        wave.inputs["Distortion"].default_value = 6.0
        wave.inputs["Detail"].default_value = 3.0
        nt.links.new(mp.outputs[0], wave.inputs["Vector"])
        fac = wave.outputs["Fac"]
    else:  # gentle 4D ripples
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.noise_dimensions = "4D"
        noise.inputs["Scale"].default_value = 0.35
        noise.inputs["Detail"].default_value = 3.0
        nt.links.new(geo.outputs["Position"], noise.inputs["Vector"])
        nt.links.new(math_node(nt, "MULTIPLY", t, 0.6), noise.inputs["W"])
        fac = noise.outputs["Fac"]
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.45 if falling else 0.5
    ramp.color_ramp.elements[0].color = base
    ramp.color_ramp.elements[1].position = 0.8 if falling else 0.72
    ramp.color_ramp.elements[1].color = (0.75, 0.9, 1.0, 1)
    nt.links.new(fac, ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 0.18 if falling else 0.08


animate_water("water_fall", True)
animate_water("water", False)


# ------------------------------------------------------------------ 3. glows breathe
def breathe(name, base, amp, speed, phase=0.0):
    m = bpy.data.materials.get(name)
    if not m:
        return
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    fc = bsdf.inputs["Emission Strength"].driver_add("default_value")
    fc.driver.type = "SCRIPTED"
    fc.driver.expression = f"{base} + {amp} * sin(frame / {FPS} * {speed} + {phase})"


breathe("glow_cyan", 2.4, 0.9, 2.2)
breathe("glow_purple", 2.0, 0.9, 1.7, 1.0)
breathe("glow_gold", 2.6, 0.8, 1.3, 2.0)
breathe("portal_field", 1.1, 0.45, 3.0)
breathe("glow_green", 2.6, 1.0, 2.6, 0.5)

# ------------------------------------------------------------------ 4. the portal's swirl spins; 5. big cases ride the belt
sw = bpy.data.objects.get("Travel Portal_FX")
if sw:
    px, py, pz = sw["pivot"]
    ax, ay, az = sw["axis"]
    me = sw.data
    for v in me.vertices:
        v.co.x -= px
        v.co.y -= py
        v.co.z -= pz
    sw.location = (px, py, pz)
    sw.rotation_mode = "AXIS_ANGLE"
    for f, ang in ((1, 0.0), (1 + FPS * 8, -math.tau * 2)):
        sw.rotation_axis_angle = (ang, ax, ay, az)
        sw.keyframe_insert("rotation_axis_angle", frame=f)
belt = bpy.data.objects.get("Big Case Terrace_FX")
if belt:
    sx, sy, sz = belt["slide"]
    for f, d in ((1, 0.0), (1 + FPS * 2, 8.0)):
        belt.location = (sx * d, sy * d, 0)
        belt.keyframe_insert("location", frame=f)
for ob in (sw, belt):
    if ob:
        loop(ob, linear=True)
        print("[amb] looping", ob.name, len(fcurves(ob)), "curves")

# ------------------------------------------------------------------ 6. clouds + islets drift
cl = bpy.data.objects.get("Clouds_Islets")
if cl:
    for f, d in ((1, (0, 0, 0)), (1 + FPS * 20, (36, 14, 3))):
        cl.location = d
        cl.keyframe_insert("location", frame=f)

# ------------------------------------------------------------------ 7. butterflies
K.MATS.clear()  # (the kit's cache belonged to the build run; reuse existing materials by name)


def kmat(name):
    return bpy.data.materials.get(name) or K.mat(name)


def box(name, sx, sy, sz, look, parent=None, loc=(0, 0, 0)):
    me = bpy.data.meshes.new(name)
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    vs = [(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
    fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(vs, [], fs)
    me.materials.append(kmat(look))
    ob = bpy.data.objects.new(name, me)
    ob.location = loc
    if parent:
        ob.parent = parent
    EFX.objects.link(ob)
    return ob


WING_LOOKS = ["yellow", "pink", "sky_blue", "orange", "white", "purple"]
spots = [(0, 0, 58, 10), (-72, 72, 26, 6), (72, 72, 26, 6), (72, -72, 26, 6), (-72, -72, 26, 6), (0, -95, 30, 6)]
for i in range(22):
    cx, cy, R, n = spots[i % len(spots)]
    body = box(f"Butterfly_{i}", 0.25, 0.7, 0.25, "black")
    look = WING_LOOKS[i % len(WING_LOOKS)]
    for sgn in (-1, 1):
        hinge = bpy.data.objects.new(f"Butterfly_{i}_Hinge{sgn}", None)
        hinge.parent = body
        EFX.objects.link(hinge)
        box(f"Butterfly_{i}_Wing{sgn}", 0.9, 0.8, 0.06, look, parent=hinge, loc=(sgn * 0.5, 0.05, 0))
        for f, ang in ((1, 0.15), (4, 1.1), (7, 0.15)):
            hinge.rotation_euler = (0, sgn * ang, 0)
            hinge.keyframe_insert("rotation_euler", frame=f + (i % 3))
        loop(hinge)
    # a meandering path: a new waypoint every second
    a0 = rng.uniform(0, 360)
    for k in range(0, 13):
        a = a0 + k * rng.uniform(15, 40)
        r = rng.uniform(R * 0.55, R)
        body.location = (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)), rng.uniform(2.5, 7.5))
        body.rotation_euler = (0, 0, math.radians(a + 90))
        body.keyframe_insert("location", frame=1 + k * FPS)
        body.keyframe_insert("rotation_euler", frame=1 + k * FPS)

# ------------------------------------------------------------------ 8. pollen floating over the plaza
pm = bpy.data.materials.new("Pollen")
pm.use_nodes = True
pb = next(n for n in pm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
pb.inputs["Base Color"].default_value = (*lin((255, 240, 170)), 1)
pb.inputs["Emission Color"].default_value = (*lin((255, 240, 170)), 1)
pb.inputs["Emission Strength"].default_value = 0.7
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.09, location=(0, 0, -500))
mote = bpy.context.active_object
mote.name = "Pollen_Mote"
mote.data.materials.append(pm)
for c in mote.users_collection:
    c.objects.unlink(mote)
EFX.objects.link(mote)
bpy.ops.mesh.primitive_plane_add(size=140, location=(0, 0, 1.5))
em = bpy.context.active_object
em.name = "Pollen_Emitter"
for c in em.users_collection:
    c.objects.unlink(em)
EFX.objects.link(em)
ps = em.modifiers.new("Pollen", "PARTICLE_SYSTEM").particle_system.settings
ps.count = 1400
ps.frame_start, ps.frame_end = -240, 200
ps.lifetime = 420
ps.emit_from = "FACE"
ps.normal_factor = 0.9
ps.factor_random = 0.6
ps.brownian_factor = 0.35
ps.effector_weights.gravity = 0.0
ps.render_type = "OBJECT"
ps.instance_object = mote
ps.particle_size = 1.0
ps.size_random = 0.6
em.show_instancer_for_render = False
em.particle_systems[0].point_cache.frame_start = -240
em.particle_systems[0].point_cache.frame_end = 250
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "central_hub.blend"), compress=True)
print("[amb] ambience added; central_hub.blend saved")
# (baked AFTER saving: the cache would add ~6 MB to the .blend; it is only needed for the renders below)
try:  # bake so any frame (stills included) has the pollen already floating
    with bpy.context.temp_override(scene=scene):
        bpy.ops.ptcache.bake_all(bake=True)
    print("[amb] pollen baked")
except Exception as e:
    print("[amb] pollen bake skipped:", e)


# ------------------------------------------------------------------ previews
from mathutils import Vector


def track_cam(name, keys, lens):
    """keys: [(frame, loc, look)] - a camera tracking an empty, both keyframed (smooth Bezier)."""
    cd = bpy.data.cameras.new(name)
    cd.lens, cd.clip_end = lens, 6000
    cam = bpy.data.objects.new(name, cd)
    tgt = bpy.data.objects.new(name + "_Target", None)
    col = bpy.data.collections.get("Presentation")
    col.objects.link(cam)
    col.objects.link(tgt)
    con = cam.constraints.new("TRACK_TO")
    con.target, con.track_axis, con.up_axis = tgt, "TRACK_NEGATIVE_Z", "UP_Y"
    for f, loc, look in keys:
        cam.location, tgt.location = loc, look
        cam.keyframe_insert("location", frame=f)
        tgt.keyframe_insert("location", frame=f)
    return cam


def orbit_keys(n, r, z, a0, a1, look, frames):
    out = []
    for k in range(n):
        t = k / (n - 1)
        a = math.radians(a0 + (a1 - a0) * t)
        out.append((1 + int(frames * t), (r * math.cos(a), r * math.sin(a), z), look))
    return out


CLIPS = {  # (camera, frames): short previews - 24 fps
    "plaza": (track_cam("Clip_Plaza", [(1, (0, -60, 9), (0, 30, 13)), (96, (12, -34, 11), (-5, 40, 15))], 24), 96),
    "aerial": (track_cam("Clip_Aerial", orbit_keys(4, 920, 520, 252, 268, (10, 10, -40), 96), 36), 96),
    "portal": (track_cam("Clip_Portal", [(1, (-36, 6, 8), (-72, 72, 19)), (72, (-42, 18, 9.5), (-73, 73, 19))], 26), 72),
    # (the belt runs north-south at world x = 108; booths at y = +-21, the arch at y = +-11: look between them)
    "bigcase": (track_cam("Clip_BigCase", [(1, (86, -19, 19), (108, -14, 3.5)), (48, (86, -13, 19), (108, -9, 3.5))], 28), 48),
    "waterfall": (track_cam("Clip_Waterfall", [(1, (-470, 90, -30), (-330, 0, -50)), (72, (-470, 70, -38), (-330, 0, -58))], 32), 72),
}
for c in ("Hub_Labels",):
    col = bpy.data.collections.get(c)
    if col:
        col.hide_render = True
K.setup_eevee(scene, samples=8)  # previews: ~0.6 s per sample per frame on this Mac (681k studs), so keep it low
scene.eevee.use_raytracing = False
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
for key, (cam, frames) in CLIPS.items():
    if only and key not in only:
        continue
    scene.camera = cam
    scene.frame_start, scene.frame_end = 1, frames
    if "stills" in argv:
        scene.render.resolution_x, scene.render.resolution_y = 960, 540
        scene.render.image_settings.file_format = "JPEG"
        for f in (1, frames // 2, frames):
            scene.frame_set(f)
            scene.render.filepath = os.path.join(OUT, f"{key}_f{f:03d}.jpg")
            bpy.ops.render.render(write_still=True)
        print("[amb] stills", key)
    if "clips" in argv:
        scene.render.resolution_x, scene.render.resolution_y = 960, 540
        try:
            scene.render.image_settings.media_type = "VIDEO"
        except Exception:
            pass
        scene.render.image_settings.file_format = "FFMPEG"
        ff = scene.render.ffmpeg
        ff.format, ff.codec = "MPEG4", "H264"
        ff.constant_rate_factor = "MEDIUM"
        ff.ffmpeg_preset = "GOOD"
        scene.render.filepath = os.path.join(OUT, f"hub_ambience_{key}.mp4")
        bpy.ops.render.render(animation=True)
        print("[amb] clip", key)
