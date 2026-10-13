# tools/blender/incubator.py - the incubator, v5 (2026-10-12, mr.robe: "remake ... everything to do with the eggs
# through blender"; the incubator part of it: "scale with rarity" - every egg floats in and the dome spins shut, Rare+
# cook longer, Legendary+ overload and launch the egg into the sky).
# A chunky white machine: a round base with a teal stripe and a control panel, a cradle on a lift, a glass dome that
# rises and spins, a floating halo ring, two heat lamps on an arch, glowing tubes. Meshes -> _egg_export/Incubator_*.json
# (uploaded by tools/zones/BuildEggsV5.lua), and four keyframed clips sampled at 30 fps -> tools/zones/incubator.json:
#   Open (dome up, cradle up), Close (dome down with a bounce), Cook (lamps aim, cradle + halo spin), Overload (rattle,
#   dome blown up, lamps flailing, halo spinning fast, the cradle crouches and launches).
# Front = +Y (Roblox -Z); the base stands on z = 0. Run: tools/blender/send.ps1 -File tools/blender/incubator.py
import bpy, json, math, os, sys
from mathutils import Vector, Matrix, Euler

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import importlib
import meshkit
importlib.reload(meshkit)
from meshkit import Mesh, lathe, sweep, frame_along, circle, rounded_rect, torus, box, export_mesh, to_object, smooth, UV0

OUT = os.path.join(REPO, "_egg_export")
CLIPS_OUT = os.path.join(REPO, "tools", "zones", "incubator.json")
PREVIEW = os.path.join(REPO, "art", "eggs", "incubator_preview.png")
os.makedirs(OUT, exist_ok=True)

WHITE, TEAL, GOLD = (242, 244, 250), (64, 196, 196), (255, 200, 52)
DARK, GLASS = (56, 58, 78), (190, 235, 255)

parts = {}  # name -> dict(mesh, rgb, mat, pivot)


def add(name, m, rgb, mat=None, pivot=(0, 0, 0)):
    m.name = name
    parts[name] = dict(mesh=m, rgb=rgb, mat=mat, pivot=Vector(pivot))


def rot_pts(m, centre, axis, deg):
    R = Matrix.Rotation(math.radians(deg), 3, axis)
    c = Vector(centre)
    return m.moved(lambda p: c + R @ (p - c))


# ------------------------------------------------------------------ the static body
add("Base", lathe("Base", [(0, 0), (2.55, 0), (2.75, 0.1), (2.82, 0.32), (2.82, 0.95), (2.72, 1.12), (2.5, 1.2), (0, 1.2)], 56), WHITE)
add("Stripe", lathe("Stripe", [(2.8, 0.42), (2.87, 0.46), (2.87, 0.66), (2.8, 0.7)], 56), TEAL)
gold = torus("Trim", 2.62, 0.09, 64, 10, (0, 0, 1.2))
# the arch (two pillars and a bowed crossbar) at the back
arch = Mesh("Arch")
for sx in (-1, 1):
    arch.merge(box("Pillar", (0.44, 0.44, 6.0), (sx * 2.25, -2.5, 3.0), bevel=0.12))
bar = [Vector((-2.25 + 4.5 * i / 20, -2.5, 6.0 + 0.45 * math.sin(math.pi * i / 20))) for i in range(21)]
arch.merge(sweep("Bar", frame_along(bar), rounded_rect(0.44, 0.44, 0.12)))
add("Arch", arch, WHITE)
for sx in (-1, 1):
    gold.merge(box("Collar", (0.62, 0.62, 0.26), (sx * 2.25, -2.5, 0.13), bevel=0.1))
    gold.merge(box("Collar", (0.58, 0.58, 0.18), (sx * 2.25, -2.5, 5.9), bevel=0.1))
gold.merge(box("Badge", (1.1, 0.14, 0.62), (0, -2.25, 6.42), bevel=0.06))
# glowing tubes on both sides, with gold caps
tubes, liquid = Mesh("Tubes"), Mesh("Liquid")
for sx in (-1, 1):
    c = (sx * 2.5, 1.05, 0)
    tubes.merge(lathe("Tube", [(0.2, 1.15), (0.2, 3.45), (0.15, 3.6), (0, 3.64)], 20, c))
    liquid.merge(lathe("Liq", [(0, 1.2), (0.15, 1.2), (0.15, 2.95), (0, 2.98)], 16, c))
    gold.merge(lathe("TubeCap", [(0, 1.08), (0.27, 1.08), (0.27, 1.32), (0, 1.32)], 20, c))
    gold.merge(lathe("TubeTop", [(0, 3.52), (0.24, 3.52), (0.24, 3.68), (0.1, 3.78), (0, 3.8)], 20, c))
add("Gold", gold, GOLD, "metal")
add("Tubes", tubes, GLASS, "glass")
add("Liquid", liquid, (120, 255, 170), "neon")
add("HeatRing", torus("HeatRing", 1.55, 0.07, 48, 8, (0, 0, 1.24)), (255, 140, 40), "neon")
# the control panel on the front, tilted back, with a screen and two buttons
pc, tilt = Vector((0, 2.78, 0.78)), -35
add("Panel", rot_pts(box("Panel", (1.7, 0.5, 0.82), pc, bevel=0.12), pc, "X", tilt), DARK)
add("Screen", rot_pts(box("Screen", (1.25, 0.08, 0.36), pc + Vector((0, 0.27, 0.14)), bevel=0.04), pc, "X", tilt), (90, 255, 160), "neon")
for name, x, rgb in (("ButtonA", -0.42, (240, 70, 70)), ("ButtonB", 0.42, (255, 205, 50))):
    btn = lathe(name, [(0, 0), (0.13, 0), (0.13, 0.07), (0, 0.09)], 18)
    btn = btn.moved(lambda p, x=x: Vector((p.x, p.z, -p.y)) + pc + Vector((x, 0.25, -0.2)))  # face +Y
    add(name, rot_pts(btn, pc, "X", tilt), rgb)

# ------------------------------------------------------------------ moving parts
add("CradleBowl", lathe("Bowl", [(0, 1.2), (0.75, 1.2), (1.08, 1.3), (1.27, 1.55), (1.32, 1.76), (1.22, 1.82), (1.02, 1.64), (0.6, 1.52), (0, 1.5)], 40), TEAL)
add("CradlePad", lathe("Pad", [(0, 1.5), (0.88, 1.52), (0.98, 1.6), (0.82, 1.67), (0, 1.69)], 32), (255, 240, 214))
add("Dome", lathe("Dome", [(1.96, 1.25), (1.96, 2.6), (1.86, 3.3), (1.56, 3.95), (1.06, 4.4), (0.42, 4.62), (0, 4.66)], 56), GLASS, "glass")
add("DomeRim", lathe("Rim", [(1.94, 1.22), (2.04, 1.22), (2.12, 1.28), (2.12, 1.46), (2.02, 1.52), (1.94, 1.5)], 56), GOLD, "metal")
add("DomeCap", lathe("Cap", [(0, 4.58), (0.36, 4.58), (0.33, 4.74), (0.14, 4.82), (0.11, 5.06), (0.2, 5.14), (0.06, 5.3), (0, 5.32)], 24), GOLD, "metal")
halo = torus("Halo", 2.48, 0.06, 64, 8, (0, 0, 0))
halo = rot_pts(halo, (0, 0, 0), "X", 10).moved(lambda p: p + Vector((0, 0, 3.1)))
add("Halo", halo, (90, 230, 255), "neon", pivot=(0, 0, 3.1))
arms = Mesh("LampArms")
AIM = {}
for sx, side in ((-1, "L"), (1, "R")):
    hinge = Vector((sx * 1.0, -2.5, 6.12))
    head = Vector((sx * 1.95, -1.65, 5.35))  # (outside the dome, also when it is raised)
    armpts = [hinge.lerp(head, i / 10) + Vector((0, 0, 0.25 * math.sin(math.pi * i / 10))) for i in range(11)]
    arms.merge(sweep("Arm", frame_along(armpts), circle(0.08, 10)))
    shade = lathe("Shade", [(0, 0.4), (0.14, 0.4), (0.2, 0.3), (0.46, -0.04), (0.43, -0.08), (0.17, 0.2), (0, 0.2)], 28, (head.x, head.y, head.z - 0.3))
    bulb = lathe("Bulb", [(0, -0.02), (0.3, -0.02), (0.3, 0.04), (0, 0.07)], 24, (head.x, head.y, head.z - 0.28))
    add("Lamp" + side, shade, (72, 74, 92), None, pivot=head)
    add("Bulb" + side, bulb, (255, 205, 120), "neon", pivot=head)
    d = (Vector((0, 0, 1.9)) - head).normalized()
    e = Vector((0, 0, -1)).rotation_difference(d).to_euler("XYZ")
    AIM[side] = tuple(math.degrees(x) for x in e)
add("LampArms", arms, (72, 74, 92))
EGG_SPOT = Vector((0, 0, 1.64))
fxring = torus("FxRing", 1.0, 0.07, 64, 8, (0, 0, 0))

# ------------------------------------------------------------------ export meshes
manifest_path = os.path.join(OUT, "manifest.json")
manifest = json.load(open(manifest_path)) if os.path.exists(manifest_path) else dict(meshes={})
inc = dict(parts={}, eggSpot=[EGG_SPOT.x, EGG_SPOT.z, -EGG_SPOT.y])
for name, pdef in parts.items():
    key = "Incubator_" + name
    info = export_mesh(pdef["mesh"], os.path.join(OUT, key + ".json"))
    manifest["meshes"][key] = info
    inc["parts"][name] = dict(mesh=key, rgb=pdef["rgb"], mat=pdef["mat"])
manifest["incubator"] = inc
manifest["meshes"]["FxRing"] = export_mesh(fxring, os.path.join(OUT, "FxRing.json"))
with open(manifest_path, "w") as fh:
    json.dump(manifest, fh, indent=1)

# ------------------------------------------------------------------ objects + keyframed clips
sc = bpy.data.scenes.get("Incubator") or bpy.data.scenes.new("Incubator")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)
sc.render.fps = 30
win = bpy.context.window
prev_scene = win.scene
win.scene = sc  # (animation only evaluates in the window's scene)


def mat_for(rgb, kind):
    name = f"IN_{rgb}_{kind}"
    mt = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mt.use_nodes = True
    bs = mt.node_tree.nodes.get("Principled BSDF")
    c = tuple((x / 255) ** 2.2 for x in rgb) + (1,)
    bs.inputs["Base Color"].default_value = c
    bs.inputs["Roughness"].default_value = 0.3 if kind in ("metal", "glass") else 0.45
    if kind == "metal":
        bs.inputs["Metallic"].default_value = 0.85
    if kind == "neon":
        bs.inputs["Emission Color"].default_value = c
        bs.inputs["Emission Strength"].default_value = 4.0
    if kind == "glass":
        bs.inputs["Alpha"].default_value = 0.3
        try:
            mt.surface_render_method = "BLENDED"
        except Exception:
            pass
    return mt


objs = {}
for name, pdef in parts.items():
    m = pdef["mesh"]
    piv = pdef["pivot"]
    local = m.moved(lambda p, piv=piv: p - piv)
    local.flat = getattr(m, "flat", False)
    local.f = [tuple((vi, n, uv) for vi, n, uv in fa) for fa in m.f]
    o = to_object(bpy, sc, local, "IN_" + name, mat_for(pdef["rgb"], pdef["mat"]), piv)
    o.rotation_mode = "XYZ"
    objs[name] = o
    lo = Vector([min(v[i] for v in m.v) for i in range(3)])
    hi = Vector([max(v[i] for v in m.v) for i in range(3)])
    pdef["centre_local"] = (lo + hi) / 2 - piv

DOME = ("Dome", "DomeRim", "DomeCap")
CRADLE = ("CradleBowl", "CradlePad")
LAMPS = {"L": ("LampL", "BulbL"), "R": ("LampR", "BulbR")}


def key(names, frame, loc=(0, 0, 0), rot=(0, 0, 0)):
    for n in names:
        o = objs[n]
        o.location = parts[n]["pivot"] + Vector(loc)
        o.rotation_euler = Euler(tuple(math.radians(a) for a in rot), "XYZ")
        o.keyframe_insert("location", frame=frame)
        o.keyframe_insert("rotation_euler", frame=frame)


CLIPS = {"Open": (1, 18), "Close": (101, 15), "Cook": (201, 36), "Overload": (301, 30)}
ALL = list(parts.keys())
for clip, (f0, n) in CLIPS.items():  # every clip starts and ends on keys of its own
    key(ALL, f0 - 1)

# Open: the dome rises and turns, overshooting a little; the cradle lifts; the halo climbs and turns
f0 = CLIPS["Open"][0]
key(DOME, f0)
key(DOME, f0 + 12, (0, 0, 4.9), (0, 0, 100))
key(DOME, f0 + 18, (0, 0, 4.7), (0, 0, 90))
key(CRADLE, f0)
key(CRADLE, f0 + 12, (0, 0, 0.62))
key(CRADLE, f0 + 18, (0, 0, 0.5))
key(["Halo"], f0)
key(["Halo"], f0 + 18, (0, 0, 1.4), (0, 0, 180))
# Close: back down with a little bounce
f0 = CLIPS["Close"][0]
key(DOME, f0, (0, 0, 4.7), (0, 0, 90))
key(DOME, f0 + 10, (0, 0, -0.07), (0, 0, -4))
key(DOME, f0 + 13, (0, 0, 0.05), (0, 0, 2))
key(DOME, f0 + 15)
key(CRADLE, f0, (0, 0, 0.5))
key(CRADLE, f0 + 10)
key(CRADLE, f0 + 15)
key(["Halo"], f0, (0, 0, 1.4), (0, 0, 180))
key(["Halo"], f0 + 15, (0, 0, 0), (0, 0, 360))
# Cook: the lamps swing in and aim at the cradle, the cradle turns, the halo spins
f0 = CLIPS["Cook"][0]
for side, names in LAMPS.items():
    s = -1 if side == "L" else 1
    key(names, f0)
    key(names, f0 + 7, (0, 0, 0), AIM[side])
    key(names, f0 + 29, (0, 0, 0), AIM[side])
    key(names, f0 + 36)
key(CRADLE, f0)
key(CRADLE, f0 + 18, (0, 0, 0.08), (0, 0, 180))
key(CRADLE, f0 + 36, (0, 0, 0), (0, 0, 360))
key(["Halo"], f0)
key(["Halo"], f0 + 36, (0, 0, 0.25), (0, 0, 720))
key(DOME, f0)
key(DOME, f0 + 36)
# Overload: rattling, the dome blown off upward, lamps flailing, halo spinning hard, the cradle crouches + launches
f0 = CLIPS["Overload"][0]
key(DOME, f0)
for i, (z, rz) in enumerate(((0.3, 6), (0.05, -5), (0.38, 8), (0.0, -4), (0.25, 5))):
    key(DOME, f0 + 2 + i * 2, (0, 0, z), (0, 0, rz))
key(DOME, f0 + 16, (3.0, 0, 5.2), (8, 16, 210))
key(DOME, f0 + 22, (3.5, 0, 4.5), (-3, 9, 250))
key(DOME, f0 + 30, (3.4, 0, 4.7), (1, 11, 270))
for side, names in LAMPS.items():
    s = -1 if side == "L" else 1
    key(names, f0)
    for i, a in enumerate((32, -22, 38, -16, 28)):
        key(names, f0 + 4 + i * 4, (0, 0, 0), (AIM[side][0] + a, AIM[side][1] + 18 * s * (1 if i % 2 else -1), 0))
    key(names, f0 + 30, (0, 0, 0), AIM[side])
key(["Halo"], f0)
key(["Halo"], f0 + 30, (0, 0, 0.9), (34, 0, 1440))
key(CRADLE, f0)
key(CRADLE, f0 + 18, (0, 0, -0.16))
key(CRADLE, f0 + 23, (0, 0, 1.15), (0, 0, 40))
key(CRADLE, f0 + 30, (0, 0, 0.5), (0, 0, 60))
# the halo's spin should be steady, the rest eased (Blender's default Bezier)
act = objs["Halo"].animation_data.action


def all_fcurves(a):
    try:
        return list(a.fcurves)
    except Exception:
        out = []
        for layer in getattr(a, "layers", []):
            for strip in layer.strips:
                for bag in getattr(strip, "channelbags", []):
                    out.extend(bag.fcurves)
        return out


for fc in all_fcurves(act):
    for kp in fc.keyframe_points:
        kp.interpolation = "LINEAR"

Mx = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
animated = list(DOME) + list(CRADLE) + ["Halo", "LampL", "BulbL", "LampR", "BulbR"]
out = dict(fps=30, parts={}, clips={})
for n in parts:
    c = parts[n]["pivot"] + parts[n]["centre_local"]
    out["parts"][n] = [round(c.x, 4), round(c.z, 4), round(-c.y, 4)]
for clip, (f0, n) in CLIPS.items():
    data = {p: [] for p in animated}
    for f in range(f0, f0 + n + 1):
        sc.frame_set(f)
        for p in animated:
            mw = objs[p].matrix_world
            c = mw @ parts[p]["centre_local"]
            R = Mx @ mw.to_3x3().normalized() @ Mx.transposed()
            q = R.to_quaternion()
            data[p].extend([round(c.x, 3), round(c.z, 3), round(-c.y, 3), round(q.x, 4), round(q.y, 4), round(q.z, 4), round(q.w, 4)])
    out["clips"][clip] = dict(frames=n + 1, parts=data)
with open(CLIPS_OUT, "w") as fh:
    json.dump(out, fh, separators=(",", ":"))

# ------------------------------------------------------------------ preview: rest pose + the open pose side by side
sc.frame_set(CLIPS["Open"][0] - 1)
cam_data = bpy.data.cameras.get("IN_Cam") or bpy.data.cameras.new("IN_Cam")
cam = bpy.data.objects.new("IN_Cam", cam_data)
sc.collection.objects.link(cam)
target = Vector((0, 0, 3.0))
cam.location = (9, 13, 7.5)
cam.rotation_euler = (target - Vector(cam.location)).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 45
sc.camera = cam
sun_d = bpy.data.lights.get("IN_Sun") or bpy.data.lights.new("IN_Sun", "SUN")
sun_d.energy = 3.5
sun = bpy.data.objects.new("IN_Sun", sun_d)
sun.rotation_euler = (math.radians(45), math.radians(15), math.radians(30))
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.get("V5_World") or bpy.data.worlds.new("V5_World")
for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        sc.render.engine = eng
        break
    except TypeError:
        pass
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x, sc.render.resolution_y = 900, 900
sc.render.film_transparent = False
for label, frame in (("rest", CLIPS["Open"][0] - 1), ("open", CLIPS["Open"][0] + 18), ("cook", CLIPS["Cook"][0] + 14), ("overload", CLIPS["Overload"][0] + 23)):
    sc.frame_set(frame)
    sc.render.filepath = PREVIEW.replace(".png", f"_{label}.png")
    bpy.ops.render.render(write_still=True, scene=sc.name)
win.scene = prev_scene
print("incubator:", len(parts), "parts;", ", ".join(f"{k} {len(v['mesh'].f)}" for k, v in parts.items()), "| clips:", ", ".join(f"{k} {v['frames']}" for k, v in out["clips"].items()))
