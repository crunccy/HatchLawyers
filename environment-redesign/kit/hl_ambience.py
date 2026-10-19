# environment-redesign/kit/hl_ambience.py - shared ambience pieces for every island (2026-10-18), from the hub's pass.
# Rules (AMBIENCE.md "Rules for moving parts"): every moving path is checked against the static scene; loops hide
# their seams; review start / middle / end stills before rendering a clip.
import bpy, math, os, random
from mathutils import Vector

FPS = 24


def time_value(nt):
    v = nt.nodes.new("ShaderNodeValue")
    fc = v.outputs[0].driver_add("default_value")
    fc.driver.type = "SCRIPTED"
    fc.driver.expression = f"frame / {FPS}"
    return v.outputs[0]


def math_node(nt, op, a, b=None, clamp=False):
    n = nt.nodes.new("ShaderNodeMath")
    n.operation, n.use_clamp = op, clamp
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            n.inputs[i].default_value = v
        else:
            nt.links.new(v, n.inputs[i])
    return n.outputs[0]


def fcurves(ob):
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


# ------------------------------------------------------------------ wind
def wind_group(amp_x=0.42, amp_y=0.3, z_from=4.5):
    ng = bpy.data.node_groups.get("WindSway")
    if ng:
        return ng
    ng = bpy.data.node_groups.new("WindSway", "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    N, L = ng.nodes, ng.links
    gi, go = N.new("NodeGroupInput"), N.new("NodeGroupOutput")
    sp = N.new("GeometryNodeSetPosition")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(N.new("GeometryNodeInputPosition").outputs[0], sep.inputs[0])
    t = N.new("GeometryNodeInputSceneTime").outputs["Seconds"]
    x, y, z = sep.outputs[0], sep.outputs[1], sep.outputs[2]
    phase = math_node(ng, "ADD", math_node(ng, "MULTIPLY", x, 0.06), math_node(ng, "MULTIPLY", y, 0.045))
    s1 = math_node(ng, "SINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 1.3), phase))
    s2 = math_node(ng, "COSINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 0.95), math_node(ng, "MULTIPLY", phase, 1.4)))
    gust = math_node(ng, "ADD", 0.75, math_node(ng, "MULTIPLY", math_node(ng, "SINE", math_node(ng, "ADD", math_node(ng, "MULTIPLY", t, 0.35), math_node(ng, "MULTIPLY", x, 0.004))), 0.25))
    f = math_node(ng, "POWER", math_node(ng, "DIVIDE", math_node(ng, "SUBTRACT", z, z_from), 12.0, clamp=True), 1.5)
    amp = math_node(ng, "MULTIPLY", f, gust)
    comb = N.new("ShaderNodeCombineXYZ")
    L.new(math_node(ng, "MULTIPLY", math_node(ng, "MULTIPLY", s1, amp), amp_x), comb.inputs[0])
    L.new(math_node(ng, "MULTIPLY", math_node(ng, "MULTIPLY", s2, amp), amp_y), comb.inputs[1])
    L.new(gi.outputs[0], sp.inputs["Geometry"])
    L.new(comb.outputs[0], sp.inputs["Offset"])
    L.new(sp.outputs[0], go.inputs[0])
    return ng


CANOPY_LOOKS = ("leaf", "leaf_light", "leaf_deep", "blossom", "blossom_light")


def wind(object_names):
    """Sway the named objects' canopies + the canopy-coloured stud instancers (so the studs ride the leaves)."""
    ng = wind_group()
    done = []
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        studs = ob.name.startswith("Studs_") and ob.name.split("_", 1)[1] in CANOPY_LOOKS
        if ob.name in object_names or studs:
            ob.modifiers.new("Wind", "NODES").node_group = ng
            done.append(ob.name)
    return done


# ------------------------------------------------------------------ water + glows
def animate_water(name, falling, highlight=(0.75, 0.9, 1.0)):
    m = bpy.data.materials.get(name)
    if not m:
        return
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    base = tuple(bsdf.inputs["Base Color"].default_value)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    t = time_value(nt)
    if falling:
        mp = nt.nodes.new("ShaderNodeMapping")
        nt.links.new(geo.outputs["Position"], mp.inputs["Vector"])
        cz = nt.nodes.new("ShaderNodeCombineXYZ")
        nt.links.new(math_node(nt, "MULTIPLY", t, 14.0), cz.inputs[2])
        nt.links.new(cz.outputs[0], mp.inputs["Location"])
        tex = nt.nodes.new("ShaderNodeTexWave")
        tex.wave_type, tex.bands_direction = "BANDS", "Z"
        tex.inputs["Scale"].default_value = 0.09
        tex.inputs["Distortion"].default_value = 6.0
        tex.inputs["Detail"].default_value = 3.0
        nt.links.new(mp.outputs[0], tex.inputs["Vector"])
    else:
        tex = nt.nodes.new("ShaderNodeTexNoise")
        tex.noise_dimensions = "4D"
        tex.inputs["Scale"].default_value = 0.35
        tex.inputs["Detail"].default_value = 3.0
        nt.links.new(geo.outputs["Position"], tex.inputs["Vector"])
        nt.links.new(math_node(nt, "MULTIPLY", t, 0.6), tex.inputs["W"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.45 if falling else 0.5
    ramp.color_ramp.elements[0].color = base
    ramp.color_ramp.elements[1].position = 0.8 if falling else 0.72
    ramp.color_ramp.elements[1].color = (*highlight, 1)  # (foam / sheen: pale blue for water, cream for soda ...)
    nt.links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 0.18 if falling else 0.08


def breathe(name, base, amp, speed, phase=0.0, square=False):
    """Emission strength over time: a sine breath, or (square=True) an on/off blink for marquee bulbs."""
    m = bpy.data.materials.get(name)
    if not m:
        return
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    fc = bsdf.inputs["Emission Strength"].driver_add("default_value")
    fc.driver.type = "SCRIPTED"
    wave = f"sin(frame / {FPS} * {speed} + {phase})"
    fc.driver.expression = f"{base} + {amp} * ({'(1 if ' + wave + ' > 0 else -1)' if square else wave})"


# ------------------------------------------------------------------ motion
def pivot_to(ob, x, y, z):
    """Re-centre a mesh object (built in world coords) on (x, y, z) so it can turn / bob about that point."""
    for o in [ob] + [ch for ch in ob.children if ch.type == "MESH"]:  # (+ its own stud instancers, K.STUD_GROUP)
        for v in o.data.vertices:
            v.co.x -= x
            v.co.y -= y
            v.co.z -= z
    ob.location = (x, y, z)


def drift(ob, offset, seconds):
    base = Vector(ob.location)
    ob.location = base
    ob.keyframe_insert("location", frame=1)
    ob.location = base + Vector(offset)
    ob.keyframe_insert("location", frame=1 + int(FPS * seconds))


def idle(ob, sway_deg=4.0, bob=0.3, period=3.0):
    """A gentle idle: turn a few degrees back and forth + bob (a looping keyframe cycle)."""
    base_r, base_z = ob.rotation_euler.z, ob.location.z
    n = int(FPS * period)
    for f, k in ((1, 0.0), (1 + n // 4, 1.0), (1 + n // 2, 0.0), (1 + 3 * n // 4, -1.0), (1 + n, 0.0)):
        ob.rotation_euler.z = base_r + math.radians(sway_deg) * k
        ob.location.z = base_z + bob * abs(k)
        ob.keyframe_insert("rotation_euler", frame=f)
        ob.keyframe_insert("location", frame=f)
    loop(ob)


def butterflies(collection, rings, n=18, seed=44, looks=("yellow", "pink", "sky_blue", "orange", "white", "purple")):
    """rings: [(cx, cy, r_min, r_max, z_min, z_max)] kept clear of what stands there."""
    rng = random.Random(seed)

    def box(name, sx, sy, sz, look, parent=None, loc=(0, 0, 0)):
        me = bpy.data.meshes.new(name)
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        me.from_pydata([(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)], [],
                       [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
        me.materials.append(bpy.data.materials.get(look) or bpy.data.materials.get("white"))
        ob = bpy.data.objects.new(name, me)
        ob.location = loc
        ob.parent = parent
        collection.objects.link(ob)
        return ob

    for i in range(n):
        cx, cy, r0, r1, z0, z1 = rings[i % len(rings)]
        body = box(f"Butterfly_{i}", 0.25, 0.7, 0.25, "black")
        for sgn in (-1, 1):
            hinge = bpy.data.objects.new(f"Butterfly_{i}_Hinge{sgn}", None)
            hinge.parent = body
            collection.objects.link(hinge)
            box(f"Butterfly_{i}_Wing{sgn}", 0.9, 0.8, 0.06, looks[i % len(looks)], parent=hinge, loc=(sgn * 0.5, 0.05, 0))
            for f, ang in ((1, 0.15), (4, 1.1), (7, 0.15)):
                hinge.rotation_euler = (0, sgn * ang, 0)
                hinge.keyframe_insert("rotation_euler", frame=f + (i % 3))
            loop(hinge)
        a = rng.uniform(0, 360)
        for k in range(13):
            a += rng.uniform(12, 30)
            r = rng.uniform(r0, r1)
            body.location = (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)), rng.uniform(z0, z1))
            body.rotation_euler = (0, 0, math.radians(a + 90))
            body.keyframe_insert("location", frame=1 + k * FPS)
            body.keyframe_insert("rotation_euler", frame=1 + k * FPS)


def particles(collection, name, at, size, count, mote, lifetime=300, normal=0.9, brownian=0.35, gravity=0.0,
              start=-240, end=200, rotations=False, ang_vel=0.0, z=1.5, size_random=0.6):
    """A drifting particle cloud (pollen, papers, steam) emitted from a plane of `size` at `at` (x, y)."""
    bpy.ops.mesh.primitive_plane_add(size=1, location=(at[0], at[1], z))
    em = bpy.context.active_object
    em.name = name + "_Emitter"
    em.scale = (size[0], size[1], 1)
    for c in em.users_collection:
        c.objects.unlink(em)
    collection.objects.link(em)
    ps = em.modifiers.new(name, "PARTICLE_SYSTEM").particle_system.settings
    ps.count, ps.frame_start, ps.frame_end, ps.lifetime = count, start, end, lifetime
    ps.emit_from, ps.normal_factor, ps.factor_random, ps.brownian_factor = "FACE", normal, 0.6, brownian
    ps.effector_weights.gravity = gravity
    ps.render_type, ps.instance_object = "OBJECT", mote
    ps.particle_size, ps.size_random = 1.0, size_random
    if rotations:
        ps.use_rotations = True
        ps.rotation_mode = "NONE"
        ps.angular_velocity_mode = "RAND"
        ps.angular_velocity_factor = ang_vel
        ps.rotation_factor_random = 1.0
    em.show_instancer_for_render = False
    em.particle_systems[0].point_cache.frame_start = start
    em.particle_systems[0].point_cache.frame_end = end + 50
    return em


def mote(collection, name, kind, size, rgb, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    lin = tuple((v / 255) ** 2.2 for v in rgb)
    b.inputs["Base Color"].default_value = (*lin, 1)
    if emit:
        b.inputs["Emission Color"].default_value = (*lin, 1)
        b.inputs["Emission Strength"].default_value = emit
    if kind == "ico":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=size, location=(0, 0, -800))
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, -800))
        bpy.context.active_object.scale = size
    ob = bpy.context.active_object
    ob.name = name
    ob.data.materials.append(m)
    for c in ob.users_collection:
        c.objects.unlink(ob)
    collection.objects.link(ob)
    return ob


def bake():
    try:
        with bpy.context.temp_override(scene=bpy.context.scene):
            bpy.ops.ptcache.bake_all(bake=True)
        return True
    except Exception as e:
        print("[amb] bake skipped:", e)
        return False


# ------------------------------------------------------------------ cameras + clips
def track_cam(name, keys, lens, collection):
    cd = bpy.data.cameras.new(name)
    cd.lens, cd.clip_end = lens, 6000
    cam = bpy.data.objects.new(name, cd)
    tgt = bpy.data.objects.new(name + "_Target", None)
    collection.objects.link(cam)
    collection.objects.link(tgt)
    con = cam.constraints.new("TRACK_TO")
    con.target, con.track_axis, con.up_axis = tgt, "TRACK_NEGATIVE_Z", "UP_Y"
    for f, loc, look in keys:
        cam.location, tgt.location = loc, look
        cam.keyframe_insert("location", frame=f)
        tgt.keyframe_insert("location", frame=f)
    return cam


def render_clips(scene, clips, out, prefix, argv, K):
    """clips: {key: (camera, frames)}; argv 'stills' -> 3 JPG frames each, 'clips' -> MP4s; only=a,b filters."""
    K.setup_eevee(scene, samples=8)
    scene.eevee.use_raytracing = False
    only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
    for key, (cam, frames) in clips.items():
        if only and key not in only:
            continue
        scene.camera = cam
        scene.frame_start, scene.frame_end = 1, frames
        scene.render.resolution_x, scene.render.resolution_y = 960, 540
        if "stills" in argv:
            scene.render.image_settings.file_format = "JPEG"
            for f in (1, frames // 2, frames):
                scene.frame_set(f)
                scene.render.filepath = os.path.join(out, f"{key}_f{f:03d}.jpg")
                bpy.ops.render.render(write_still=True)
            print("[amb] stills", key)
        if "clips" in argv:
            try:
                scene.render.image_settings.media_type = "VIDEO"
            except Exception:
                pass
            scene.render.image_settings.file_format = "FFMPEG"
            ff = scene.render.ffmpeg
            ff.format, ff.codec, ff.constant_rate_factor, ff.ffmpeg_preset = "MPEG4", "H264", "MEDIUM", "GOOD"
            scene.render.filepath = os.path.join(out, f"{prefix}_{key}.mp4")
            bpy.ops.render.render(animation=True)
            print("[amb] clip", key)
