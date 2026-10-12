# tools/blender/eggs.py - the eggs' looks (2026-10-12, user: "make the eggs look different and more detailed ...
# similar to the reference video, keeping the cartoonish look"). One model per egg (Briefcase, Pet, Brainrot, Food,
# Ocean, Space) + "GoldenKit" (the extras a golden egg wears: crown, jewelled band, lattice). Smooth glossy shapes
# (no studs) like the reference. Exports tools/zones/eggs.json -> tools/zones/BuildEggs.lua ->
# ReplicatedStorage.EggModels; Shared.EggLook builds an egg from them (zone eggs, loose eggs, carried eggs, the hatch).
# Run inside Blender: tools/blender/send.ps1 -File tools/blender/eggs.py   (own scene "Eggs"; 1 m = 1 stud)
# Shapes (field "k"): "egg" = an ellipsoid (Roblox: Part + SpecialMesh Sphere), "ball", "cyl" (axis along the part's
# X in Roblox), "block". Every egg stands on z = 0, 3.8 tall, 3 wide; the front faces +Y (= Roblox -Z).
import bpy, bmesh, math, json, os, random
from mathutils import Vector, Matrix

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
OUT_JSON = os.path.join(REPO, "tools", "zones", "eggs.json")
OUT_PNG = os.path.join(REPO, "art", "eggs", "preview.png")

sc = bpy.data.scenes.get("Eggs") or bpy.data.scenes.new("Eggs")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)

MESH = {}


def mesh(kind):
    if kind in MESH:
        return MESH[kind]
    me = bpy.data.meshes.new("EG_" + kind)
    bm = bmesh.new()
    if kind in ("egg", "ball"):
        bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=0.5)
    elif kind == "cyl":  # axis along X (like Roblox cylinders)
        bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=0.5, radius2=0.5, depth=1.0)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
    else:
        bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = kind != "block"
    MESH[kind] = me
    return me


P = None
H, W = 3.8, 3.0
# the shell: a fuller lower ellipsoid + a narrower upper one = an egg shape
LOW = dict(c=1.6, rx=1.5, rz=1.6)
TOP = dict(c=2.15, rx=1.3, rz=1.65)


def radius_at(z):
    r = 0.0
    for e in (LOW, TOP):
        d = (z - e["c"]) / e["rz"]
        if abs(d) < 1:
            r = max(r, e["rx"] * math.sqrt(1 - d * d))
    return r


def surface(theta, z, out=0.0):
    """A point on the shell at height z, angle theta (0 = front, +Y), pushed `out` along the normal; and the normal."""
    r = radius_at(z)
    dz = 0.02
    dr = (radius_at(min(H - 0.01, z + dz)) - radius_at(max(0.01, z - dz))) / (2 * dz)
    radial = Vector((math.sin(theta), math.cos(theta), 0))
    n = (radial - Vector((0, 0, dr))).normalized()
    p = Vector((radial.x * r, radial.y * r, z)) + n * out
    return p, n


def part(name, kind, size, loc, col, rot=None, tag="", normal=None, spin=0.0):
    """size = (x, y, z) in Blender; normal: turn the part so its local Z points along it (patches on the shell)."""
    o = bpy.data.objects.new(name, mesh(kind))
    o.scale = size
    o.location = loc
    if normal is not None:
        q = Vector((0, 0, 1)).rotation_difference(normal)
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = q @ Matrix.Rotation(spin, 4, "Z").to_quaternion()
    elif rot is not None:
        o.rotation_euler = rot
    o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
    o["rgb"] = list(col)
    o["tag"] = tag
    o["k"] = kind
    sc.collection.objects.link(o)
    o.parent = P
    return o


def shell(low, top=None):
    part("Shell", "egg", (LOW["rx"] * 2, LOW["rx"] * 2, LOW["rz"] * 2), (0, 0, LOW["c"]), low)
    part("ShellTop", "egg", (TOP["rx"] * 2, TOP["rx"] * 2, TOP["rz"] * 2), (0, 0, TOP["c"]), top or low)


def patch(name, theta, z, w, h, col, thick=0.22, tag="", spin=0.0, kind="egg"):
    p, n = surface(theta, z, out=0.0)
    return part(name, kind, (w, h, thick), p, col, normal=n, tag=tag, spin=spin)


def band(name, z, height, col, grow=0.08, tag=""):
    r = radius_at(z) + grow
    return part(name, "cyl", (height, r * 2, r * 2), (0, 0, z), col, rot=(0, math.pi / 2, 0), tag=tag)


def rgb(r, g, b):
    return (r, g, b)


EGGS = {}


def egg(name):
    def deco(fn):
        EGGS[name] = fn
        return fn
    return deco


GOLD, CREAM, INK = rgb(255, 205, 50), rgb(250, 240, 220), rgb(30, 28, 40)


@egg("Briefcase")
def _():
    # a leather briefcase as an egg: stitched belt, gold clasp, a handle on top
    shell(rgb(205, 140, 75), rgb(214, 150, 82))
    band("Belt", 1.7, 0.42, rgb(110, 62, 30))
    for k in range(14):
        th = k * math.tau / 14
        p, n = surface(th, 1.7, out=0.1)
        part("Stitch", "block", (0.07, 0.24, 0.05), p, CREAM, normal=n, spin=math.pi / 2, tag="nocollide")
    p, n = surface(0, 1.7, out=0.12)
    part("Clasp", "block", (0.55, 0.5, 0.16), p, GOLD, normal=n)
    p, n = surface(0, 1.7, out=0.2)
    part("ClaspSlot", "block", (0.3, 0.08, 0.05), p, INK, normal=n, tag="nocollide")
    for sx in (-1, 1):
        part("HandlePost", "block", (0.18, 0.3, 0.45), (sx * 0.38, 0, 3.72), rgb(90, 50, 24))
    part("Handle", "block", (0.95, 0.3, 0.2), (0, 0, 3.98), rgb(90, 50, 24))
    for th, z in ((0.9, 2.6), (-1.1, 0.9), (2.4, 2.2)):
        patch("Scuff", th, z, 0.5, 0.35, rgb(230, 170, 100), thick=0.12, tag="nocollide")


@egg("Pet")
def _():
    # cream with calico patches, a paw print on the front and a red collar with a gold bone tag
    shell(rgb(255, 236, 212))
    for th, z, w, h in ((1.2, 2.7, 1.3, 1.0), (-1.4, 2.0, 1.1, 1.3), (2.6, 1.0, 1.4, 1.0), (-2.5, 3.0, 0.9, 0.7)):
        patch("Patch", th, z, w, h, rgb(225, 145, 75))
    pad = rgb(255, 150, 175)
    patch("Pad", 0, 2.05, 0.75, 0.62, pad, thick=0.25)
    for th, z in ((-0.33, 2.6), (0, 2.75), (0.33, 2.6)):
        patch("Toe", th, z, 0.3, 0.3, pad, thick=0.22)
    band("Collar", 0.95, 0.32, rgb(220, 40, 50))
    p, n = surface(0, 0.62, out=0.18)
    part("Tag", "cyl", (0.1, 0.5, 0.5), p, GOLD, rot=(0, math.pi / 2, math.pi / 2))


@egg("Brainrot")
def _():
    # purple with neon-pink blobs (like the reference's Secret egg), big googly eyes and a little antenna
    shell(rgb(150, 80, 230))
    rnd = random.Random(7)
    for k in range(7):
        patch("Blob", rnd.uniform(0, math.tau), rnd.uniform(0.6, 3.2), rnd.uniform(0.7, 1.3), rnd.uniform(0.5, 1.0),
              rgb(255, 90, 200), thick=0.2, spin=rnd.uniform(0, 3), tag="neon")
    for th in (-0.36, 0.36):
        p, n = surface(th, 2.7, out=0.18)
        part("Eye", "ball", (0.82, 0.82, 0.82), p, rgb(255, 255, 255))
        p2, _ = surface(th * 0.86, 2.62, out=0.5)
        part("Pupil", "ball", (0.36, 0.36, 0.36), p2, INK)
    part("Antenna", "cyl", (0.7, 0.1, 0.1), (0, 0, 4.0), rgb(90, 50, 150), rot=(0, math.pi / 2, 0))
    part("AntennaBall", "ball", (0.38, 0.38, 0.38), (0, 0, 4.4), rgb(150, 255, 90), tag="neon")


@egg("Food")
def _():
    # a frosted treat: biscuit below, pink frosting on top with drips and sprinkles, a cherry on top
    shell(rgb(232, 175, 95), rgb(232, 175, 95))
    frost = rgb(255, 150, 195)
    FR = dict(c=2.75, rx=TOP["rx"] + 0.08, rz=1.3)  # the frosting cap: an ellipsoid over the top
    part("Frosting", "egg", (FR["rx"] * 2, FR["rx"] * 2, FR["rz"] * 2), (0, 0, FR["c"]), frost)

    def on_frosting(th, z, out):
        d = (z - FR["c"]) / FR["rz"]
        r = FR["rx"] * math.sqrt(max(0.0, 1 - d * d))
        n = Vector((math.sin(th) * (1 - d * d) ** 0.5 / FR["rx"], math.cos(th) * (1 - d * d) ** 0.5 / FR["rx"], d / FR["rz"])).normalized()
        return Vector((math.sin(th) * r, math.cos(th) * r, z)) + n * out, n

    edge = 2.4  # where the frosting comes out of the biscuit shell (worked out from the two ellipsoids)
    for k in range(9):
        th = k * math.tau / 9 + 0.2
        h = 0.45 + (k % 3) * 0.22
        p, n = surface(th, edge - h / 2 + 0.18, out=0.05)
        part("Drip", "egg", (0.42, 0.42, h), p, frost, normal=Vector((0, 0, 1)))
    rnd = random.Random(11)
    cols = [rgb(255, 230, 60), rgb(90, 220, 255), rgb(150, 255, 90), rgb(255, 255, 255), rgb(190, 110, 255)]
    for k in range(16):
        p, n = on_frosting(rnd.uniform(0, math.tau), rnd.uniform(2.4, 3.7), 0.03)
        part("Sprinkle", "block", (0.09, 0.3, 0.07), p, rnd.choice(cols), normal=n, spin=rnd.uniform(0, 3), tag="nocollide")
    part("Cherry", "ball", (0.58, 0.58, 0.58), (0, 0, 4.05), rgb(220, 30, 40))
    part("Stem", "cyl", (0.5, 0.06, 0.06), (0.1, 0, 4.5), rgb(70, 140, 40), rot=(0, math.pi / 2 - 0.4, 0))


@egg("Ocean")
def _():
    # deep sea below, sky-blue above, a white foam wave around the middle, a starfish and bubbles
    shell(rgb(40, 120, 205), rgb(110, 200, 255))
    for k in range(16):
        th = k * math.tau / 16
        p, n = surface(th, 1.85 + 0.12 * math.sin(k * 1.7), out=0.0)
        part("Foam", "ball", (0.5, 0.5, 0.5), p, rgb(250, 252, 255))
    sp, sn = surface(0, 1.0, out=0.08)
    star = rgb(255, 130, 80)
    for k in range(5):
        a = k * math.tau / 5
        part("StarArm", "egg", (0.22, 0.6, 0.18), sp, star, normal=sn, spin=a)
    part("StarMiddle", "ball", (0.3, 0.3, 0.3), sp, rgb(255, 150, 100))
    for th, z, s in ((0.8, 2.9, 0.5), (1.1, 3.35, 0.32), (-0.9, 2.6, 0.4), (-1.6, 3.2, 0.26)):
        p, n = surface(th, z, out=0.12)
        part("Bubble", "ball", (s, s, s), p, rgb(200, 240, 255), tag="glass")


@egg("Space")
def _():
    # a starry night egg with a glowing nebula, a tilted planet ring and a little moon
    shell(rgb(40, 32, 96), rgb(52, 40, 120))
    rnd = random.Random(23)
    for k in range(4):
        patch("Nebula", k * math.tau / 4 + rnd.uniform(-0.4, 0.4), rnd.uniform(1.0, 3.0), rnd.uniform(1.1, 1.6), rnd.uniform(0.7, 1.1),
              rgb(200, 90, 255), thick=0.14, spin=rnd.uniform(0, 3), tag="neon")
    for k in range(16):
        p, n = surface(rnd.uniform(0, math.tau), rnd.uniform(0.4, 3.5), out=0.08)
        s = rnd.uniform(0.17, 0.27)
        part("Star", "ball", (s, s, s), p, rgb(255, 245, 170), tag="neon")
    tilt = Matrix.Rotation(math.radians(22), 4, "X")
    for k in range(16):
        a = k * math.tau / 16
        p = tilt @ Vector((math.sin(a) * 2.05, math.cos(a) * 2.05, 0))
        rot = (tilt @ Matrix.Rotation(-a, 4, "Z")).to_euler()
        part("Ring", "block", (0.82, 0.24, 0.08), (p.x, p.y, p.z + 2.0), rgb(90, 240, 255), rot=rot, tag="neon")
    part("Moon", "ball", (0.5, 0.5, 0.5), (1.9, 0.6, 2.75), rgb(205, 205, 220))


@egg("GoldenKit")
def _():
    # what a golden egg wears on top of its gold shell (Faberge style, like the reference's Mythical egg): a gold
    # lattice, a jewelled band, a gold base ring and a crown with a spire
    gold, light = rgb(255, 200, 40), rgb(255, 240, 160)
    for fam in (-1, 1):
        for k in range(6):
            th0 = k * math.tau / 6
            prev = None
            for s in range(6):
                z = 0.35 + s * 0.62
                th = th0 + fam * (z - 0.35) * 0.55
                p, _ = surface(th, z, out=0.05)
                if prev is not None:
                    mid = (prev + p) / 2
                    d = p - prev
                    o = part("Lattice", "cyl", (d.length + 0.06, 0.1, 0.1), mid, light, tag="nocollide")
                    o.rotation_mode = "QUATERNION"
                    o.rotation_quaternion = Vector((1, 0, 0)).rotation_difference(d.normalized())
                prev = p
    band("GemBand", 1.7, 0.3, rgb(250, 250, 255), grow=0.1)
    gems = [rgb(90, 220, 255), rgb(255, 90, 200), rgb(255, 255, 255)]
    for k in range(12):
        p, n = surface(k * math.tau / 12, 1.7, out=0.2)
        part("Gem", "ball", (0.22, 0.22, 0.22), p, gems[k % 3], tag="neon")
    band("BaseRing", 0.18, 0.22, gold, grow=0.06)
    part("CrownBand", "cyl", (0.32, 1.1, 1.1), (0, 0, 3.75), gold, rot=(0, math.pi / 2, 0))
    for k in range(5):
        a = k * math.tau / 5
        part("CrownSpike", "block", (0.2, 0.2, 0.42), (math.sin(a) * 0.48, math.cos(a) * 0.48, 4.08), gold)
        part("CrownPearl", "ball", (0.16, 0.16, 0.16), (math.sin(a) * 0.48, math.cos(a) * 0.48, 4.33), rgb(255, 255, 255))
    part("Spire", "cyl", (0.6, 0.12, 0.12), (0, 0, 4.2), gold, rot=(0, math.pi / 2, 0))
    part("SpireGem", "ball", (0.3, 0.3, 0.3), (0, 0, 4.58), rgb(255, 90, 120), tag="neon")


roots = {}
for i, (name, fn) in enumerate(EGGS.items()):
    P = bpy.data.objects.new(name, None)
    sc.collection.objects.link(P)
    P.location = (i * 5.0, 0, 0)
    if name == "GoldenKit":  # (shown on a gold shell for the preview only - the kit itself is just the extras)
        P2 = P
        g = part("PreviewShell", "egg", (3, 3, 3.2), (0, 0, 1.6), rgb(255, 200, 40))
        g["preview"] = True
        g2 = part("PreviewShellTop", "egg", (2.6, 2.6, 3.3), (0, 0, 2.15), rgb(255, 200, 40))
        g2["preview"] = True
    fn()
    roots[name] = P


# ------------------------------------------------------------------ export (Blender (x, y, z) -> Roblox (x, z, -y))
def to_rbx(v):
    return [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]


Mx = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
data = {}
for name, P in roots.items():
    parts = []
    for o in P.children:
        if o.get("preview"):
            continue
        R = o.rotation_quaternion.to_matrix() if o.rotation_mode == "QUATERNION" else o.rotation_euler.to_matrix()
        Rr = Mx @ R @ Mx.transposed()
        s = o.scale
        parts.append(dict(n=o.name.split(".")[0], k=o["k"], p=to_rbx(o.location), s=[round(abs(s[0]), 4), round(abs(s[2]), 4), round(abs(s[1]), 4)],
                          r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"]))
    data[name] = dict(height=H, parts=parts)
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))

# ------------------------------------------------------------------ preview
cam_data = bpy.data.cameras.get("EG_Cam") or bpy.data.cameras.new("EG_Cam")
cam = bpy.data.objects.new("EG_Cam", cam_data)
sc.collection.objects.link(cam)
target = Vector((15, 0, 2.2))
cam.location = (15, 46, 9)
cam.rotation_euler = (target - Vector(cam.location)).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 50
sc.camera = cam
sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.display.shading.show_specular_highlight = True
sc.render.resolution_x, sc.render.resolution_y = 1800, 560
sc.world = sc.world or bpy.data.worlds.new("EG_World")
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print(f"{len(data)} egg models: " + ", ".join(f"{k} {len(v['parts'])}" for k, v in data.items()) + f" -> {OUT_JSON}")
