"""Tralalero Tralala (Legendary lawyer) - real-shape remake, run inside Blender:
    exec(open("/Users/ryanchen/HatchLawyers/tools/lawyer_tralalero.py").read()); build(); render_views()

User 2026-10-10: models must look like the actual thing, with their own proportions (the old one was the shared
2.1 x 5.5 x 1.1 block humanoid with a shark head). Reference: the original meme image (Wikimedia
"Italian_brainrot_characters.png", top left): a whole shark standing side-on on THREE thin legs in light-blue
sneakers with a white swoosh; slate-blue back, white belly, tall dorsal fin, upright two-lobed tail.

Fits an office: the lawyer stands 2.25 studs behind the desk centre, so the shark stands SIDE-ON along the desk
(like the reference), nose toward -X. 1 Blender m = 1 stud, feet at z = 0, front (toward the client) = -Y.
Target: ~5.6 long, ~4.7 to the dorsal fin tip, belly ~2.0 up, <= ~3k tris.

Meshes (Shared.Puppet / SkinLook names): Tralalero_Head (snout -> gills), Tralalero_UpperTorso (body, dorsal +
tail + small fins), Tralalero_LeftUpperArm / _RightUpperArm (pectoral fins), Tralalero_LeftUpperLeg (front leg),
Tralalero_LeftLowerLeg (middle leg), Tralalero_RightUpperLeg (rear leg) - each leg includes its sneaker.
Colours: one palette texture (Models - Characters/Lawyers/LawyerPalette.png), faces UV'd to swatches.
"""
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

ID = "Tralalero"
OUT = "/Users/ryanchen/HatchLawyers/Models - Characters/Lawyers"
GRID, CELL = 16, 8

TOP = (96, 126, 156)        # slate blue-grey back
TOP_DARK = (78, 104, 132)   # fin edges / leg shade
BELLY = (238, 238, 233)
LINE = (38, 46, 60)         # gills, mouth line
EYE = (18, 18, 24)
SHINE = (255, 255, 255)
TEETH = (250, 249, 240)
MOUTH = (150, 60, 72)
SHOE = (70, 165, 240)
SHOE_DARK = (40, 120, 205)
SOLE = (250, 250, 250)
SWOOSH = (255, 255, 255)

COLORS = {}


def swatch(rgb):
    if rgb not in COLORS:
        COLORS[rgb] = len(COLORS)
    i = COLORS[rgb]
    return ((i % GRID + 0.5) / GRID, 1 - (i // GRID + 0.5) / GRID)


# ---------------------------------------------------------------------------------------------- mesh building
class Part:
    """Accumulates geometry for one exported mesh; faces carry a palette colour."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.sharp = []   # faces to keep flat-shaded

    def face(self, verts, rgb, flat=False):
        try:
            f = self.bm.faces.new(verts)
        except ValueError:
            return None
        u = swatch(rgb)
        for loop in f.loops:
            loop[self.uv].uv = u
        f.smooth = not flat
        return f

    def vert(self, co):
        return self.bm.verts.new(co)

    def finish(self, coll, mat):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        me = bpy.data.meshes.new(f"{ID}_{self.name}")
        self.bm.to_mesh(me)
        self.bm.free()
        ob = bpy.data.objects.new(f"{ID}_{self.name}", me)
        ob.data.materials.append(mat)
        coll.objects.link(ob)
        return ob


def catmull(points, t):
    """Catmull-Rom through a list of tuples at t in [0, len-1]."""
    n = len(points)
    i = min(int(t), n - 2)
    u = t - i
    p0, p1, p2, p3 = (points[max(i - 1, 0)], points[i], points[i + 1], points[min(i + 2, n - 1)])
    return tuple(
        0.5 * ((2 * b) + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u * u + (-a + 3 * b - 3 * c + d) * u ** 3)
        for a, b, c, d in zip(p0, p1, p2, p3))


def loft(part, keys, rings, seg, color_of, cap_start=True, cap_end=True):
    """Smooth tube through key sections (x, cz, ry, rz) - interpolated into `rings` rings of `seg` verts.
    color_of(theta, x) -> rgb per face (theta 0 = +y side... measured around the X axis, pi/2 = top)."""
    ring_verts = []
    for r in range(rings):
        x, cz, ry, rz = catmull(keys, r / (rings - 1) * (len(keys) - 1))
        ring = []
        for s in range(seg):
            th = 2 * math.pi * s / seg
            # slightly squared-off ellipse (toy look, flatter belly)
            c, sn = math.cos(th), math.sin(th)
            k = 0.82
            y = ry * math.copysign(abs(c) ** k, c)
            z = cz + rz * math.copysign(abs(sn) ** k, sn) * (0.92 if sn < 0 else 1.0)
            ring.append(part.vert((x, y, z)))
        ring_verts.append((x, ring))
    for r in range(rings - 1):
        x0, a = ring_verts[r]
        x1, b = ring_verts[r + 1]
        for s in range(seg):
            th = 2 * math.pi * (s + 0.5) / seg
            part.face([a[s], a[(s + 1) % seg], b[(s + 1) % seg], b[s]], color_of(th, (x0 + x1) / 2))
    for cap, (x, ring) in ((cap_start, ring_verts[0]), (cap_end, ring_verts[-1])):
        if cap:
            c = part.vert((x, 0, sum(v.co.z for v in ring) / seg))
            for s in range(seg):
                th = 2 * math.pi * (s + 0.5) / seg
                part.face([ring[s], ring[(s + 1) % seg], c], color_of(th, x))
    return ring_verts


def prism(part, outline, y0, thick, rgb, edge_rgb=None, plane="xz", taper=None):
    """A fin / flat shape: 2D outline (u, v) extruded `thick` around y0 (plane xz: u=x, v=z).
    taper(u, v) -> thickness scale (thin tips)."""
    def co(u, v, side):
        t = thick / 2 * (taper(u, v) if taper else 1.0) * side
        if plane == "xz":
            return (u, y0 + t, v)
        return (u, v, y0 + t)   # plane "xy": u=x, v=y, extruded along z
    front = [part.vert(co(u, v, -1)) for u, v in outline]
    back = [part.vert(co(u, v, 1)) for u, v in outline]
    part.face(front[::-1], rgb)
    part.face(back, rgb)
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        part.face([front[i], front[j], back[j], back[i]], edge_rgb or rgb)


def tube(part, points, radii, seg, rgb):
    """A tube through 3D points with per-point radius (legs, mouth line)."""
    rings = []
    for i, p in enumerate(points):
        p = Vector(p)
        d = (Vector(points[min(i + 1, len(points) - 1)]) - Vector(points[max(i - 1, 0)])).normalized()
        a = d.orthogonal().normalized()
        b = d.cross(a).normalized()
        rings.append([part.vert(p + radii[i] * (math.cos(2 * math.pi * s / seg) * a + math.sin(2 * math.pi * s / seg) * b))
                      for s in range(seg)])
    for i in range(len(rings) - 1):
        for s in range(seg):
            part.face([rings[i][s], rings[i][(s + 1) % seg], rings[i + 1][(s + 1) % seg], rings[i + 1][s]], rgb)
    for ring, p in ((rings[0], points[0]), (rings[-1], points[-1])):
        c = part.vert(p)
        for s in range(seg):
            part.face([ring[s], ring[(s + 1) % seg], c], rgb)


def sphere(part, center, r, rgb, seg=10, rings=6, scale=(1, 1, 1)):
    cx, cy, cz = center
    verts = []
    for i in range(1, rings):
        ph = math.pi * i / rings
        verts.append([part.vert((cx + r * scale[0] * math.sin(ph) * math.cos(2 * math.pi * s / seg),
                                 cy + r * scale[1] * math.sin(ph) * math.sin(2 * math.pi * s / seg),
                                 cz + r * scale[2] * math.cos(ph))) for s in range(seg)])
    top = part.vert((cx, cy, cz + r * scale[2]))
    bot = part.vert((cx, cy, cz - r * scale[2]))
    for s in range(seg):
        part.face([top, verts[0][s], verts[0][(s + 1) % seg]], rgb)
        part.face([bot, verts[-1][(s + 1) % seg], verts[-1][s]], rgb)
    for i in range(rings - 2):
        for s in range(seg):
            part.face([verts[i][s], verts[i + 1][s], verts[i + 1][(s + 1) % seg], verts[i][(s + 1) % seg]], rgb)


# ---------------------------------------------------------------------------------------------- the shark
# body key sections: (x, centre z, half width, half height); nose at -x
# (v2: ~30 % deeper and a blunter, rounder snout - the reference shark is deep-chested and chunky)
BODY = [
    (-2.84, 3.09, 0.05, 0.05),   # (v4: snout tipped up a little, like the reference)
    (-2.74, 3.05, 0.22, 0.20),
    (-2.52, 2.96, 0.42, 0.42),
    (-2.22, 2.86, 0.56, 0.62),
    (-1.90, 2.77, 0.66, 0.78),
    (-1.55, 2.74, 0.71, 0.90),
    (-1.10, 2.73, 0.73, 0.97),
    (-0.60, 2.73, 0.70, 0.96),
    (-0.10, 2.75, 0.63, 0.87),
    (0.40, 2.79, 0.53, 0.73),
    (0.90, 2.84, 0.41, 0.56),
    (1.40, 2.90, 0.29, 0.39),
    (1.80, 2.95, 0.20, 0.26),
    (2.12, 2.99, 0.14, 0.17),
    (2.32, 3.02, 0.12, 0.14),
]
HEAD_SPLIT = 5   # head = keys 0..5 (nose -> x -1.50, just behind the gills)


def section_at(x):
    """(cz, ry, rz) of the body at x (linear between keys - good enough for placing details)."""
    for a, b in zip(BODY, BODY[1:]):
        if a[0] <= x <= b[0]:
            t = (x - a[0]) / (b[0] - a[0])
            return tuple(a[i] + (b[i] - a[i]) * t for i in (1, 2, 3))
    return BODY[-1][1:]


def body_color(th, x):
    # countershading: white below a line ~15 deg under the side (a little higher toward the head)
    s = math.sin(th)
    line = -0.30 + (0.12 if x < -1.6 else 0.0)
    return BELLY if s < line else TOP


def surface(x, side, height):
    """A point on the body skin at x, on side -1 (-y, toward the client) / +1, at relative height -1..1."""
    cz, ry, rz = section_at(x)
    th = math.asin(max(-1, min(1, height)))
    y = ry * math.cos(th) ** 0.82
    return Vector((x, side * y, cz + rz * height))


def head_part():
    p = Part("Head")
    # (open where it meets the body: the two lofts share that ring, so the join is seamless)
    loft(p, BODY[:HEAD_SPLIT + 1], rings=14, seg=18, color_of=body_color, cap_start=True, cap_end=False)
    for side in (-1, 1):
        # eye: dark round eye a little behind and above the snout line, with a highlight
        e = surface(-2.05, side, 0.32)
        sphere(p, (e.x, e.y - side * 0.01, e.z), 0.095, EYE, seg=10, rings=6)
        sphere(p, (e.x - 0.03, e.y + side * -0.075, e.z + 0.035), 0.03, SHINE, seg=6, rings=4)
        # gill slits: four curved lines just in front of the split
        for gx in (-1.82, -1.72, -1.62, -1.52):
            pts = [surface(gx + 0.02 * k, side, h) * 1.0 + Vector((0, side * 0.012, 0))
                   for k, h in enumerate((0.42, 0.18, -0.06, -0.28))]
            tube(p, [tuple(v) for v in pts], [0.018, 0.024, 0.024, 0.018], 5, LINE)
        # smiling mouth line under the snout, curling up at the corner, with a row of little teeth
        mouth = [surface(x, side, h) + Vector((0, side * 0.01, 0))
                 for x, h in ((-2.62, -0.35), (-2.45, -0.48), (-2.25, -0.55), (-2.05, -0.5), (-1.92, -0.32))]
        tube(p, [tuple(v) for v in mouth], [0.02, 0.028, 0.03, 0.028, 0.02], 5, LINE)
        for k in range(5):
            t = 0.12 + k * 0.17
            a = mouth[1].lerp(mouth[3], t)
            tip = a + Vector((0, 0, -0.07))
            v1 = p.vert(a + Vector((-0.035, side * 0.012, 0.0)))
            v2 = p.vert(a + Vector((0.035, side * 0.012, 0.0)))
            v3 = p.vert(tip + Vector((0, side * 0.012, 0)))
            p.face([v1, v2, v3], TEETH, flat=True)
    return p


def torso_part():
    p = Part("UpperTorso")
    loft(p, BODY[HEAD_SPLIT:], rings=20, seg=18, color_of=body_color, cap_start=False, cap_end=True)
    top = lambda x: section_at(x)[0] + section_at(x)[2]
    thin = lambda u, v: max(0.35, 1 - (v - 3.5) / 1.6)
    # dorsal fin: swept back, concave trailing edge (side view of a great white)
    base0, base1 = -0.70, 0.30
    t0 = top(-0.2)
    dorsal = [(base0, top(base0) - 0.15), (base0 + 0.12, top(base0) + 0.25), (-0.30, top(-0.3) + 0.62),
              (0.02, t0 + 0.88), (0.22, t0 + 1.05), (0.17, t0 + 0.80), (0.12, t0 + 0.48), (0.18, top(0.18) + 0.22),
              (base1, top(base1) - 0.15)]
    prism(p, dorsal, 0.0, 0.17, TOP, TOP_DARK, taper=lambda u, v: max(0.3, 1 - (v - t0) / 1.2))
    # second (small) dorsal near the tail
    d2 = [(1.45, top(1.45) - 0.08), (1.62, top(1.62) + 0.22), (1.72, top(1.72) - 0.06)]
    prism(p, d2, 0.0, 0.07, TOP, TOP_DARK)
    # tail: tall upper lobe swept back and up, smaller lower lobe (heterocercal)
    tail = [(2.18, 3.17), (2.45, 3.53), (2.70, 3.91), (2.96, 4.27), (3.00, 4.13), (2.82, 3.61), (2.64, 3.09),
            (2.80, 2.71), (2.93, 2.45), (2.84, 2.43), (2.56, 2.73), (2.30, 2.87)]
    prism(p, tail, 0.0, 0.14, TOP, TOP_DARK, taper=lambda u, v: max(0.35, 1 - abs(u - 2.3) / 1.0))
    # small belly fins (pelvic + anal) - white like the belly
    bot = lambda x: section_at(x)[0] - section_at(x)[2] * 0.92
    # (v2: body-coloured and swept back - white spikes read as teeth)
    for x0, x1, drop in ((0.60, 0.95, 0.20), (1.40, 1.65, 0.14)):
        fin = [(x0, bot(x0) + 0.10), (x1, bot(x1) + 0.10), (x1 + 0.12, bot(x1) - drop)]
        prism(p, fin, 0.0, 0.07, TOP_DARK)
    return p


def pectoral_part(name, side):
    """Pectoral fin: rooted low on the side behind the gills, swept back and down (the reference's 'arm')."""
    p = Part(name)
    root = surface(-1.30, side, -0.35)
    outline = [(0.0, 0.0), (0.62, 0.06), (0.82, -0.92), (0.62, -1.02), (0.15, -0.42)]
    verts_f, verts_b = [], []
    # fin plane: along +x (back) and down, angled out from the body by 35 degrees
    out = Vector((0, side, 0)).lerp(Vector((0, 0, -1)), 0.35).normalized()
    across = Vector((1, 0, 0))
    down = across.cross(out).normalized() * (-side)
    if down.z > 0:
        down = -down
    normal = across.cross(down).normalized()
    for u, v in outline:
        base = root + across * u + (out * 0.55 + Vector((0, 0, -1)) * 0.45).normalized() * (-v)
        verts_f.append(p.vert(base + normal * 0.04))
        verts_b.append(p.vert(base - normal * 0.04))
    p.face(verts_f, TOP)
    p.face(verts_b[::-1], TOP)
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        p.face([verts_f[i], verts_b[i], verts_b[j], verts_f[j]], TOP_DARK)
    return p


def sneaker(p, ankle, heading=-1, S=1.45):
    """A chunky running shoe under `ankle`, toe toward x * heading. ~1.4 long, 0.6 wide, 0.6 tall (v2: the
    reference's shoes are huge - each about the size of the shark's head)."""
    L, Wd = 0.95 * S, 0.42 * S
    hx = ankle.x + 0.22 * -heading     # heel sits a little behind the ankle
    cy = ankle.y

    def X(t):   # t 0 = heel, 1 = toe
        return hx + heading * L * t
    # sole: white slab with toe spring (two layers: outsole + midsole)
    sole_keys = [(t, h * S, w * S) for t, h, w in ((0.0, 0.13, 0.18), (0.15, 0.13, 0.21), (0.45, 0.13, 0.22), (0.75, 0.13, 0.21), (0.92, 0.16, 0.16), (1.0, 0.20, 0.07))]
    rings = []
    for t, top, half in sole_keys:
        x = X(t)
        rise = 0.05 * S if t > 0.85 else 0.0
        ring = [p.vert((x, cy - half, rise)), p.vert((x, cy + half, rise)),
                p.vert((x, cy + half, top)), p.vert((x, cy - half, top))]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for s in range(4):
            p.face([a[s], a[(s + 1) % 4], b[(s + 1) % 4], b[s]], SOLE, flat=True)
    p.face(rings[0][::-1], SOLE, flat=True)
    p.face(rings[-1], SOLE, flat=True)
    # upper: lofted rounded shape, tall at the heel collar, low at the toe
    up_keys = [(t, h * S, w * S) for t, h, w in ((0.02, 0.50, 0.18), (0.18, 0.53, 0.205), (0.40, 0.46, 0.205), (0.62, 0.36, 0.195), (0.82, 0.28, 0.165), (0.97, 0.20, 0.09))]
    seg = 10
    urings = []
    for t, h, half in up_keys:
        x = X(t)
        ring = []
        for s in range(seg + 1):
            a = math.pi * s / seg   # 0..pi: one side, over the top, the other side
            ring.append(p.vert((x, cy + half * math.cos(a), 0.13 * S + (h - 0.13 * S) * math.sin(a) ** 0.7)))
        urings.append(ring)
    for i, (a, b) in enumerate(zip(urings, urings[1:])):
        for s in range(seg):
            p.face([a[s], a[s + 1], b[s + 1], b[s]], SHOE)
    for ring, flip in ((urings[0], True), (urings[-1], False)):
        c = p.vert((ring[0].co.x, cy, 0.12 * S))
        for s in range(seg):
            f = [ring[s], ring[s + 1], c]
            p.face(f[::-1] if flip else f, SHOE_DARK if flip else SHOE)
    # collar opening (dark ring where the leg goes in) + heel tab
    sphere(p, (X(0.2), cy, 0.52 * S), 0.15 * S, SHOE_DARK, seg=10, rings=4, scale=(1.2, 1.0, 0.35))
    # laces: three white bars across the top
    for t in (0.36, 0.47, 0.58):
        h = (0.46 - (t - 0.4) * 0.42) * S
        w = 0.09 * S
        prism(p, [(X(t) - 0.04, cy - w), (X(t) + 0.04, cy - w), (X(t) + 0.04, cy + w), (X(t) - 0.04, cy + w)],
              h + 0.005, 0.04, SOLE, plane="xy")
    # swoosh on both sides: a curved white tick from the heel low point sweeping up toward the toe
    for side in (-1, 1):
        ys = cy + side * 0.205 * S
        pts = [(0.12, 0.27), (0.30, 0.18), (0.55, 0.20), (0.82, 0.36), (0.62, 0.26), (0.35, 0.25), (0.18, 0.31)]
        outline = [(X(t), z * S) for t, z in pts]
        prism(p, outline if heading < 0 else outline[::-1], ys + side * 0.012, 0.012, SWOOSH)


def leg_part(name, hip, knee, ankle):
    p = Part(name)
    tube(p, [tuple(hip), tuple(hip.lerp(knee, 0.5)), tuple(knee), tuple(knee.lerp(ankle, 0.5)), tuple(ankle)],
         [0.21, 0.17, 0.135, 0.12, 0.12], 8, TOP)   # (v3: thigh-like top, like the reference)
    sneaker(p, Vector((ankle.x, ankle.y, 0.0)))
    return p


LEGS = {
    # name: (hip, knee, ankle) - front leg under the chest, a long middle leg reaching forward on the client's
    # side (the reference's big foreground shoe), a rear leg under the back belly
    "LeftUpperLeg": (Vector((-1.55, 0.22, 1.98)), Vector((-1.80, 0.26, 1.15)), Vector((-1.68, 0.30, 0.62))),
    "LeftLowerLeg": (Vector((-0.70, -0.30, 1.88)), Vector((-0.42, -0.50, 1.10)), Vector((-0.80, -0.62, 0.62))),
    "RightUpperLeg": (Vector((0.80, 0.10, 2.15)), Vector((1.05, 0.12, 1.20)), Vector((0.95, 0.14, 0.62))),
}


def palette_material():
    size = GRID * CELL
    px = [1.0] * (size * size * 4)
    for rgb, i in COLORS.items():
        cx, cy = i % GRID, i // GRID
        for y in range(CELL):
            for x in range(CELL):
                row = size - 1 - (cy * CELL + y)
                j = (row * size + cx * CELL + x) * 4
                px[j:j + 4] = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0]
    name = f"{ID}Palette"
    img = bpy.data.images.get(name)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, size, size, alpha=False)
    img.pixels = px
    os.makedirs(OUT, exist_ok=True)
    img.filepath_raw = os.path.join(OUT, f"{name}.png")
    img.file_format = "PNG"
    img.save()
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.55
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    return mat


def build():
    coll = bpy.data.collections.get(ID)
    if coll:
        for ob in list(coll.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
    else:
        coll = bpy.data.collections.new(ID)
        bpy.context.scene.collection.children.link(coll)
    COLORS.clear()
    parts = [head_part(), torso_part(), pectoral_part("LeftUpperArm", -1), pectoral_part("RightUpperArm", 1)]
    for name, (hip, knee, ankle) in LEGS.items():
        parts.append(leg_part(name, hip, knee, ankle))
    mat = palette_material()
    obs = [part.finish(coll, mat) for part in parts]
    tris = 0
    for ob in obs:
        ob.data.polygons.foreach_get  # (touch)
        tris += sum(len(poly.vertices) - 2 for poly in ob.data.polygons)
    lo = Vector((min(v.co.x for o in obs for v in o.data.vertices), min(v.co.y for o in obs for v in o.data.vertices), min(v.co.z for o in obs for v in o.data.vertices)))
    hi = Vector((max(v.co.x for o in obs for v in o.data.vertices), max(v.co.y for o in obs for v in o.data.vertices), max(v.co.z for o in obs for v in o.data.vertices)))
    return f"{len(obs)} meshes, {tris} tris, size {tuple(round(c, 2) for c in (hi - lo))}, bottom z {lo.z:.2f}"


def render_views(prefix="/tmp/tralalero"):
    """Studio-like preview renders (Eevee): side (reference view), 3/4 front, front, top-ish."""
    scene = bpy.context.scene
    for ob in list(scene.objects):
        if ob.name in ("Cube",):
            bpy.data.objects.remove(ob, do_unlink=True)
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        try:
            scene.render.engine = "BLENDER_EEVEE"
        except TypeError:
            pass
    scene.render.resolution_x, scene.render.resolution_y = 900, 700
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.78, 0.86, 0.95, 1)
    bg.inputs[1].default_value = 1.0
    # sun + floor
    sun = bpy.data.objects.get("PreviewSun")
    if not sun:
        sun = bpy.data.objects.new("PreviewSun", bpy.data.lights.new("PreviewSun", "SUN"))
        scene.collection.objects.link(sun)
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    if not bpy.data.objects.get("PreviewFloor"):
        bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
        bpy.context.active_object.name = "PreviewFloor"
    cam = bpy.data.objects.get("Camera")
    scene.camera = cam
    cam.data.lens = 50
    views = {"side": ((0.0, -14.0, 2.6), (0.0, 0.0, 2.4)), "threequarter": ((-8.5, -10.5, 4.5), (-0.2, 0.0, 2.2)),
             "back3q": ((9.0, 9.0, 4.5), (0.0, 0.0, 2.2)), "front": ((-13.0, 0.0, 2.8), (0.0, 0.0, 2.3))}
    files = []
    for name, (pos, look) in views.items():
        cam.location = pos
        d = Vector(look) - Vector(pos)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        path = f"{prefix}_{name}.png"
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        files.append(path)
    return files
