# tools/blender/overhaul/trees.py - MAP MODEL OVERHAUL, stage 1 benchmark: the tree family (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). Smooth MESH trees in the style of the reference stills (references/models/: PS99's lobed
# canopies on curved, tapering trunks; the Blender tutorial's clustered canopy) - natural detail stays unstudded
# (docs/ART_STYLE_STUDS.md). One mesh per colour (a Roblox MeshPart takes one Color):
#   <Tree>_Trunk   bark                       <Tree>_Canopy  the canopy's shaded underside / sides
#   <Tree>_Light   the canopy's sunlit top    (the canopy is ONE merged surface split by which way each face points, so
#                                              the two tones meet without overlapping - no z-fighting)
# 1 Blender m = 1 stud, Z up here (Roblox Y).
#   Blender -b --factory-startup --python tools/blender/overhaul/trees.py -- <out_dir> [--fbx]
# Renders a line-up (with a 5-stud player and today's lollipop tree for scale) + close views; --fbx also exports one
# .fbx per tree for crnuch to import into Studio.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "kit"))
import hl_kit as K  # palette, materials, sky, camera, EEVEE setup

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
FBX = "--fbx" in argv
os.makedirs(OUT, exist_ok=True) if __name__ == "__main__" else None
TAU = math.tau

# the overhaul's tree colours (sRGB): <kind>_shade = underside, <kind>_leaf / _light = the sunlit top
TREE_PAL = {
    "oak_shade": (64, 150, 44), "oak_light": (132, 212, 70),
    "blossom_shade": (236, 130, 176), "blossom_light": (255, 200, 225),
    "poplar_shade": (44, 140, 76), "poplar_light": (104, 196, 96),
    "pine_shade": (30, 112, 62), "pine_light": (72, 168, 90),
    "palm_shade": (70, 160, 50), "palm_light": (140, 214, 84),
    "bush_shade": (58, 142, 40), "bush_light": (124, 206, 66),
    "bark": (134, 84, 48), "bark_dark": (96, 60, 36), "palm_bark": (198, 152, 98), "nut": (110, 70, 40),
    "old_ball": (70, 168, 34), "old_trunk": (122, 70, 34), "avatar": (255, 210, 60),
}
K.PAL.update(TREE_PAL)


def matte(look):
    """Roblox Plastic reads matte: high roughness, little specular (the first pass looked like glossy balloons)."""
    m = K.mat(look)
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.8
    try:
        bsdf.inputs["Specular IOR Level"].default_value = 0.18
    except Exception:
        pass
    return m


# ------------------------------------------------------------------ helpers
def link(ob, coll=None):
    (coll or bpy.context.scene.collection).objects.link(ob)
    return ob


def mesh_object(name, bm, look, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(matte(look))
    for p in me.polygons:
        p.use_smooth = smooth
    return bpy.data.objects.new(name, me)


def apply_modifiers(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    bpy.data.meshes.remove(old)


def canopy(name, blobs, shade, light, voxel=0.4, faces=1400, lumpy=0.7, seed=0, squash=1.0, split=0.28):
    """Overlapping spheres -> ONE organic surface (voxel remesh + lumps + smooth + thin), split by face direction into
    <name>_Canopy (shade) and <name>_Light (sunlit top). squash < 1 flattens it (an umbrella crown)."""
    bm = bmesh.new()
    for c, r in blobs:
        g = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=r)
        for v in g["verts"]:
            v.co += Vector(c)
    ob = link(mesh_object(name + "_tmp", bm, shade))
    rm = ob.modifiers.new("Remesh", "REMESH")
    rm.mode, rm.voxel_size = "VOXEL", voxel
    apply_modifiers(ob)
    cz = sum((Vector(c).z for c, _ in blobs), 0.0) / len(blobs)
    for v in ob.data.vertices:  # mid-frequency lumps = the leafy clusters
        n1 = noise.noise(v.co * 0.42 + Vector((seed * 7.1, seed * 3.3, 1.7)))
        n2 = noise.noise(v.co * 0.9 + Vector((seed * 2.3, 5.1, seed)))
        v.co += v.normal * (n1 * lumpy + n2 * lumpy * 0.35)
        if squash != 1.0:
            v.co.z = cz + (v.co.z - cz) * squash
    sm = ob.modifiers.new("Smooth", "SMOOTH")
    sm.factor, sm.iterations = 0.5, 3
    dec = ob.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = min(1.0, faces / max(1, len(ob.data.polygons)))
    apply_modifiers(ob)
    # split: faces looking up (with a noisy edge so the line between the tones is organic) -> the sunlit mesh
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    bm.faces.ensure_lookup_table()
    keep_up = set()
    for f in bm.faces:
        c = f.calc_center_median()
        edge = noise.noise(c * 0.3 + Vector((seed, 1.3, 2.1))) * 0.18  # low-frequency: a wavy, not jagged, line
        if f.normal.z + edge > split:
            keep_up.add(f.index)
    # clean the boundary: a few majority passes remove lone specks and fill pin-holes
    nbrs = {f.index: {g.index for v in f.verts for g in v.link_faces if g is not f} for f in bm.faces}  # corner neighbours
    for _ in range(5):
        nxt = set(keep_up)
        for i, ns in nbrs.items():
            frac = sum(1 for j in ns if j in keep_up) / max(1, len(ns))
            if i in keep_up and frac < 0.4:
                nxt.discard(i)
            elif i not in keep_up and frac > 0.6:
                nxt.add(i)
        keep_up = nxt
    lit_bm = bm.copy()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index in keep_up], context="FACES")
    lit_bm.faces.ensure_lookup_table()
    bmesh.ops.delete(lit_bm, geom=[f for f in lit_bm.faces if f.index not in keep_up], context="FACES")
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    link(mesh_object(name + "_Canopy", bm, shade))
    link(mesh_object(name + "_Light", lit_bm, light))


def tube(bm, path, radii, segs=10, cap_top=True):
    """A tapered tube along points (a trunk / branch); parallel-transported ring frames (no twists or kinks)."""
    rings, side = [], None
    for i, p in enumerate(path):
        p = Vector(p)
        d = (Vector(path[min(i + 1, len(path) - 1)]) - Vector(path[max(i - 1, 0)])).normalized()
        if side is None:
            side = d.cross(Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 1, 0))).normalized()
        side = (side - d * side.dot(d)).normalized()
        up = side.cross(d).normalized()
        rings.append([bm.verts.new(p + (side * math.cos(k / segs * TAU) + up * math.sin(k / segs * TAU)) * radii[i]) for k in range(segs)])
    for i in range(len(rings) - 1):
        for k in range(segs):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[i + 1][(k + 1) % segs], rings[i + 1][k]))
    if cap_top:
        bm.faces.new(list(reversed(rings[-1])))
    return rings


def curve(p0, p1, bend, n=6):
    p0, p1, bend = Vector(p0), Vector(p1), Vector(bend)
    return [p0.lerp(p1, t) + bend * math.sin(t * math.pi) for t in (i / (n - 1) for i in range(n))]


def trunk(name, look, parts, roots=4, root_r=None, seed=0):
    """parts: [(path, r_base, r_tip)]; the first is the trunk. `roots` short flared roots spread at its foot."""
    r = random.Random(seed)
    bm = bmesh.new()
    for path, r0, r1 in parts:
        n = len(path)
        tube(bm, path, [r0 + (r1 - r0) * (j / (n - 1)) ** 0.75 for j in range(n)], segs=10)
    base = Vector(parts[0][0][0])
    rr = root_r or parts[0][1]
    for k in range(roots):
        a = k / roots * TAU + r.uniform(-0.3, 0.3)
        d = Vector((math.cos(a), math.sin(a), 0))
        tube(bm, [base + Vector((0, 0, rr * 1.6)), base + d * rr * 1.3 + Vector((0, 0, 0.45 * rr)), base + d * rr * 2.3 - Vector((0, 0, 0.1))],
             [rr * 0.55, rr * 0.4, rr * 0.18], segs=8)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    link(mesh_object(name + "_Trunk", bm, look))


# ------------------------------------------------------------------ the family
def tree_oak(x, y, name="Oak", s=1.0, shade="oak_shade", light="oak_light", seed=1):
    """Round broadleaf: a curved trunk forking into visible branches under a cluster crown."""
    o = Vector((x, y, 0))
    top = o + Vector((0.5, 0.2, 9.0)) * s
    trunk(name, "bark", [
        (curve(o, top, Vector((0.6, -0.3, 0)) * s, 7), 1.15 * s, 0.7 * s),
        (curve(top - Vector((0, 0, 2.0)) * s, top + Vector((3.6, 1.0, 2.6)) * s, Vector((0, 0, 0.7)) * s, 5), 0.55 * s, 0.25 * s),
        (curve(top - Vector((0, 0, 1.4)) * s, top + Vector((-3.0, -1.6, 3.0)) * s, Vector((0, 0, 0.6)) * s, 5), 0.5 * s, 0.22 * s),
        (curve(top - Vector((0, 0, 0.6)) * s, top + Vector((-0.4, 2.8, 3.4)) * s, Vector((0, 0, 0.5)) * s, 5), 0.45 * s, 0.2 * s),
    ], seed=seed)
    c = top + Vector((0, 0, 4.6)) * s
    lobes = [(c + Vector(d) * s, rr * s) for d, rr in (
        ((0, 0, 0.6), 4.6), ((4.0, 1.2, -1.0), 3.6), ((-3.8, -1.6, -0.6), 3.8), ((0.8, 4.0, -0.8), 3.4),
        ((-0.6, -4.0, -0.4), 3.4), ((2.8, -2.8, 0.4), 3.0), ((-2.6, 2.8, 0.8), 3.0), ((0.4, 0.2, 3.6), 3.4),
        ((3.0, 1.4, 2.2), 2.6), ((-2.8, -0.8, 2.6), 2.6))]
    canopy(name, lobes, shade, light, voxel=0.38 * s, faces=1500, lumpy=0.75 * s, seed=seed)


def tree_umbrella(x, y, name="Umbrella", s=1.0, seed=2):
    """Wide and low: a leaning trunk and a broad, flat crown (the 'savanna' silhouette)."""
    o = Vector((x, y, 0))
    top = o + Vector((-1.6, 0.4, 8.0)) * s
    trunk(name, "bark", [
        (curve(o, top, Vector((-0.9, 0.2, 0)) * s, 7), 1.05 * s, 0.6 * s),
        (curve(top - Vector((0, 0, 1.4)) * s, top + Vector((4.6, 0.6, 2.0)) * s, Vector((0, 0, 0.9)) * s, 5), 0.5 * s, 0.22 * s),
        (curve(top - Vector((0, 0, 0.8)) * s, top + Vector((-2.4, -2.6, 2.0)) * s, Vector((0, 0, 0.6)) * s, 5), 0.42 * s, 0.2 * s),
    ], seed=seed)
    c = top + Vector((1.2, 0, 3.0)) * s
    lobes = [(c + Vector((dx, dy, dz)) * s, rr * s) for dx, dy, dz, rr in
             ((0, 0, 0.4, 4.2), (4.6, 0.8, -0.2, 3.6), (-4.2, -0.6, 0, 3.6), (0.6, 4.0, -0.1, 3.2), (-0.4, -4.0, 0, 3.2),
              (3.4, -3.0, -0.3, 2.8), (-3.0, 3.2, -0.3, 2.8), (6.8, 1.2, -0.6, 2.4), (-6.4, -1.0, -0.4, 2.4))]
    canopy(name, lobes, "oak_shade", "oak_light", voxel=0.38 * s, faces=1400, lumpy=0.6 * s, seed=seed, squash=0.62, split=0.2)


def tree_poplar(x, y, name="Poplar", s=1.0, seed=3):
    """Tall and oval: reads from far away, frames paths in rows."""
    o = Vector((x, y, 0))
    trunk(name, "bark", [(curve(o, o + Vector((0.2, 0, 6.0)) * s, Vector((0.3, 0, 0)) * s, 6), 0.95 * s, 0.55 * s)], roots=3, seed=seed)
    r = random.Random(seed)
    blobs = [(o + Vector((0.2 + r.uniform(-0.6, 0.6), r.uniform(-0.6, 0.6), z)) * s, rr * s)
             for z, rr in ((7.6, 3.2), (9.6, 3.7), (12.0, 3.8), (14.4, 3.5), (16.6, 3.0), (18.6, 2.3), (20.2, 1.5))]
    canopy(name, blobs, "poplar_shade", "poplar_light", voxel=0.36 * s, faces=1300, lumpy=0.6 * s, seed=seed, split=0.12)


def tree_blossom(x, y, name="Blossom", s=1.0, seed=4):
    tree_oak(x, y, name, s * 0.92, shade="blossom_shade", light="blossom_light", seed=seed)


def tree_pine(x, y, name="Pine", s=1.0, seed=5):
    """Tiered conifer: 6 drooping skirts with a ragged rim; sunlit upper face / shaded underside as the two meshes."""
    o = Vector((x, y, 0))
    trunk(name, "bark_dark", [(curve(o, o + Vector((0, 0, 5.0)) * s, Vector((0, 0, 0)), 4), 0.85 * s, 0.55 * s)], roots=3, seed=seed)
    top_bm, und_bm = bmesh.new(), bmesh.new()
    tiers = ((2.6, 6.4, 4.6), (4.9, 5.6, 4.4), (7.0, 4.7, 4.0), (9.0, 3.8, 3.6), (10.8, 2.8, 3.2), (12.4, 1.8, 2.8))
    segs = 20
    for k, (z0, rad, h) in enumerate(tiers):
        z0, rad, h = z0 * s, rad * s, h * s
        def rim_pt(i, scale=1.0, dz=0.0):
            a = i / segs * TAU + k * 0.4
            wob = 1 + 0.12 * math.sin(i * 2.0 + k) * (1 if i % 2 == 0 else 0.4)  # ragged needles edge
            return o + Vector((math.cos(a) * rad * wob * scale, math.sin(a) * rad * wob * scale, z0 + dz - (0.55 * s if i % 2 else 0)))
        rim = [top_bm.verts.new(rim_pt(i)) for i in range(segs)]
        mid = [top_bm.verts.new(rim_pt(i, 0.55, h * 0.46)) for i in range(segs)]
        tip = top_bm.verts.new(o + Vector((0, 0, z0 + h)))
        for i in range(segs):
            j = (i + 1) % segs
            top_bm.faces.new((rim[i], rim[j], mid[j], mid[i]))
            top_bm.faces.new((mid[i], mid[j], tip))
        urim = [und_bm.verts.new(rim_pt(i)) for i in range(segs)]
        uin = [und_bm.verts.new(o + Vector((math.cos(i / segs * TAU) * rad * 0.35, math.sin(i / segs * TAU) * rad * 0.35, z0 + 0.9 * s)))
               for i in range(segs)]
        for i in range(segs):
            j = (i + 1) % segs
            und_bm.faces.new((urim[j], urim[i], uin[i], uin[j]))
        und_bm.faces.new(list(reversed(uin)))
    for b in (top_bm, und_bm):
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
    link(mesh_object(name + "_Light", top_bm, "pine_light", smooth=False))
    link(mesh_object(name + "_Canopy", und_bm, "pine_shade", smooth=False))


def tree_palm(x, y, name="Palm", s=1.0, seed=6):
    """Curving ringed trunk + 9 arching, leafleted fronds + coconuts."""
    o = Vector((x, y, 0))
    path = curve(o, o + Vector((3.4, 0.6, 15.5)) * s, Vector((1.8, 0.2, 0)) * s, 16)
    n = len(path)
    radii = [(0.95 - 0.38 * j / (n - 1)) * s * (1.1 if j % 2 == 0 else 0.94) for j in range(n)]  # ringed bark
    radii[0] *= 1.45
    bm = bmesh.new()
    tube(bm, path, radii, segs=12)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    link(mesh_object(name + "_Trunk", bm, "palm_bark"))
    crown = Vector(path[-1])
    top_bm, und_bm = bmesh.new(), bmesh.new()
    for k in range(9):
        a = k / 9 * TAU + 0.3
        d = Vector((math.cos(a), math.sin(a), 0))
        side = Vector((-d.y, d.x, 0))
        L = (7.8 if k % 2 == 0 else 6.6) * s
        rise = 0.6 if k % 3 == 0 else 0.0
        pts = 14
        for b_, flip in ((top_bm, 1), (und_bm, -1)):
            left, mid, right = [], [], []
            for i in range(pts):
                t = i / (pts - 1)
                p = crown + d * (t * L) + Vector((0, 0, ((1.9 + rise) * math.sin(t * 2.0) - 4.0 * t * t) * s))
                saw = 1.0 if i % 2 == 0 else 0.7  # leaflets: a sawtooth edge
                w = (1.35 * math.sin(t * math.pi) ** 0.6 * saw + 0.06) * s
                fold = 0.4 * s * (1 - t)
                off = Vector((0, 0, -0.1 * s * (1 if flip < 0 else 0)))  # the underside sits a little below the top
                mid.append(b_.verts.new(p + Vector((0, 0, fold)) + off))
                left.append(b_.verts.new(p + side * w - Vector((0, 0, 0.3 * s)) + off))
                right.append(b_.verts.new(p - side * w - Vector((0, 0, 0.3 * s)) + off))
            for i in range(pts - 1):
                q1 = (left[i], mid[i], mid[i + 1], left[i + 1])
                q2 = (mid[i], right[i], right[i + 1], mid[i + 1])
                b_.faces.new(q1 if flip > 0 else tuple(reversed(q1)))
                b_.faces.new(q2 if flip > 0 else tuple(reversed(q2)))
    link(mesh_object(name + "_Light", top_bm, "palm_light"))
    link(mesh_object(name + "_Canopy", und_bm, "palm_shade"))
    nb = bmesh.new()
    for a in (0.4, 2.5, 4.5):
        g = bmesh.ops.create_icosphere(nb, subdivisions=2, radius=0.6 * s)
        for v in g["verts"]:
            v.co += crown + Vector((math.cos(a) * 0.8, math.sin(a) * 0.8, -1.0)) * s
    link(mesh_object(name + "_Nuts", nb, "nut"))


def bush(x, y, name="Bush", s=1.0, seed=7):
    o = Vector((x, y, 0))
    canopy(name, [(o + Vector(d) * s, rr * s) for d, rr in (((0, 0, 1.3), 2.2), ((1.8, 0.6, 0.9), 1.7), ((-1.6, -0.4, 0.9), 1.8),
                                                             ((0.2, -1.6, 0.8), 1.5), ((0.4, 0.4, 2.6), 1.4))],
           "bush_shade", "bush_light", voxel=0.26 * s, faces=700, lumpy=0.32 * s, seed=seed, split=0.15)


def old_lollipop(x, y):
    """Today's hub tree (a ball on a stick), for the comparison."""
    bm = bmesh.new()
    tube(bm, [(x, y, 0), (x, y, 6)], [0.6, 0.6], segs=12)
    link(mesh_object("OLD_Trunk", bm, "old_trunk"))
    bm = bmesh.new()
    g = bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=3.0)
    for v in g["verts"]:
        v.co += Vector((x, y, 8.0))
    link(mesh_object("OLD_Canopy", bm, "old_ball", smooth=False))


def player(x, y):
    """A 5-stud blocky avatar for scale."""
    bm = bmesh.new()
    for (cx, cy, cz, sx, sy, sz) in ((0, 0, 4.4, 1.0, 1.0, 1.0), (0, 0, 2.9, 2.0, 1.0, 2.0), (-1.5, 0, 2.9, 1.0, 1.0, 2.0),
                                      (1.5, 0, 2.9, 1.0, 1.0, 2.0), (-0.5, 0, 0.95, 1.0, 1.0, 1.9), (0.5, 0, 0.95, 1.0, 1.0, 1.9)):
        g = bmesh.ops.create_cube(bm, size=1.0)
        for v in g["verts"]:
            v.co = Vector((v.co.x * sx + x + cx, v.co.y * sy + y + cy, v.co.z * sz + cz))
    link(mesh_object("Player", bm, "avatar", smooth=False))


# ------------------------------------------------------------------ scene
def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    sc = bpy.context.scene
    K.sky_and_sun(sc, sun_energy=3.8, sun_rot=(52, 6, -40))
    link(bpy.data.objects["Sun"])
    gb = bmesh.new()
    bmesh.ops.create_grid(gb, x_segments=1, y_segments=1, size=120)
    link(mesh_object("Ground", gb, "grass", smooth=False))
    old_lollipop(-40, 0)
    player(-34, -6)
    tree_oak(-24, 0)
    tree_umbrella(-6, 2)
    tree_blossom(12, 0)
    tree_poplar(26, 2)
    tree_pine(38, 0)
    tree_palm(50, 1)
    bush(-14, -9)
    bush(4, -9, "Bush2", s=0.8, seed=8)
    return sc


def render(sc, name, loc, look, lens=32, res=(1600, 900)):
    cam = K.camera(name, loc, look, lens=lens)
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = os.path.join(OUT, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


def export_fbx():
    groups = {}
    for ob in bpy.data.objects:
        if ob.type == "MESH" and "_" in ob.name and not ob.name.startswith("OLD"):
            groups.setdefault(ob.name.split("_")[0], []).append(ob)
    for tree, obs in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for ob in obs:
            ob.select_set(True)
        path = os.path.join(OUT, f"Tree_{tree}.fbx")
        bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, axis_forward="-Z", axis_up="Y",
                                 object_types={"MESH"}, mesh_smooth_type="FACE")
        print("exported", path, [o.name for o in obs])


def stats():
    total = {}
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        if ob.type == "MESH" and ob.name != "Ground":
            t = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            total[ob.name.split("_")[0]] = total.get(ob.name.split("_")[0], 0) + t
            print(f"{ob.name:18s} tris={t}")
    print("per tree:", total)


if __name__ == "__main__":  # (other overhaul scripts import the tree builders for their scene renders)
    sc = build()
    K.setup_eevee(sc, samples=48)
    stats()
    render(sc, "trees_lineup", (5, -78, 16), (5, 0, 8), lens=30)
    render(sc, "trees_close", (-30, -34, 9), (-14, 0, 9), lens=30)
    render(sc, "trees_close2", (22, -36, 10), (36, 0, 9), lens=30)
    if FBX:
        export_fbx()
