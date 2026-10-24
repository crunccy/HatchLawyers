# tools/blender/overhaul/ohkit.py - shared helpers for the MAP MODEL OVERHAUL scripts (CLAUDE.md "MODEL OVERHAUL").
# Every model is a few named per-colour meshes (a Roblox MeshPart takes one Color): name -> one look. Primitives add
# into the current named mesh under the current frame (with at(x, y, z, rz): ...), so a prop is written once at the
# origin and placed anywhere. Faces carry their own shading (boxes flat, round things smooth, caps flat), so one mesh
# can hold a chamfered plinth and a round post. Text is PREVIEW ONLY (Preview_Text_*): in the game, sign text is a
# SurfaceGui in the game's fonts, so it stays editable and crisp.
# Blender coordinates: X across, Y depth (FRONT faces -Y), Z up. 1 m = 1 stud.
#   import ohkit as O; O.reset(); with O.at(4, 0, rz=90): O.box("Lamp_Iron", "iron", (0, 0, 3), (0.4, 0.4, 6), bevel=0.05)
#   O.finish(); O.scene(); O.render(out, "name", cam, target)
import bpy, bmesh, math, os, sys, random
from contextlib import contextmanager
from mathutils import Vector, Matrix, Euler, noise

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "kit"))
sys.path.insert(0, HERE)
import hl_kit as K
import ohstuds

TAU = math.tau

# the overhaul palette (sRGB) on top of the kit's
K.PAL.update({
    "iron": (52, 54, 64), "iron_light": (96, 100, 116), "wood_warm": (196, 132, 74), "wood_deep": (122, 76, 42),
    "plank_light": (206, 152, 96), "plank_dark": (150, 98, 58), "stone_light": (232, 226, 212), "stone_mid": (196, 188, 174),
    "stone_dark": (146, 140, 132), "trim_cream": (248, 238, 214), "gold": (255, 196, 46), "gold_dark": (206, 146, 24),
    "bush_shade": (58, 142, 40), "bush_light": (124, 206, 66), "bush": (88, 182, 54), "hedge": (80, 172, 50), "leaf_sun": (140, 214, 74), "soil": (112, 74, 46),
    "flower_red": (240, 62, 84), "flower_yel": (255, 212, 54), "flower_pink": (255, 128, 190), "flower_purple": (168, 104, 240),
    "flower_white": (252, 250, 244), "flower_orange": (255, 140, 40), "rock": (156, 152, 146), "rock_top": (204, 200, 192),
    "moss": (112, 186, 62), "brief_brown": (136, 84, 46), "brief_black": (46, 46, 56), "file_box": (234, 220, 184),
    "file_lid": (210, 194, 154), "board_cork": (204, 156, 102), "paper": (252, 250, 244), "paper_yel": (255, 238, 150),
    "paper_blue": (170, 214, 255), "pin_red": (232, 58, 58), "bin_green": (64, 156, 84), "bin_dark": (40, 102, 56),
    "red": (226, 58, 58), "white": (248, 246, 240), "sign_wood": (184, 120, 64), "panel_black": (32, 30, 40),
    "terracotta": (218, 114, 72), "terracotta_dark": (178, 84, 52), "parasol_red": (234, 66, 76), "hydrant_red": (228, 52, 52),
    "banner_purple": (128, 72, 210), "plaza": (238, 228, 206), "plaza_edge": (206, 196, 176), "path": (255, 160, 24),
    "grass_ov": (124, 222, 52), "avatar": (255, 210, 60),
    # architecture (hub buildings, firms)
    "wall_cream": (246, 226, 180), "wall_warm": (240, 214, 168), "marble": (244, 242, 236), "marble_shade": (220, 216, 206),
    "navy_roof": (56, 70, 136), "navy_dark": (38, 48, 100), "navy_seam": (82, 98, 168), "glass_blue": (128, 190, 240),
    "glass_deep": (82, 140, 210), "carpet_red": (204, 40, 58), "flag_purple": (140, 80, 220), "flag_red": (232, 56, 64),
    "stone_cool": (182, 188, 200), "stone_cool_dark": (138, 146, 162), "egg_shell": (255, 246, 226), "egg_orange": (255, 150, 50),
    "egg_blue": (110, 200, 250), "copper": (214, 128, 72), "brass": (224, 172, 72), "boot_red": (226, 50, 58),
})
K.GLOWS.update({"heat_glow": ((255, 96, 60), 1.8), "halo_glow": ((110, 230, 255), 1.6), "orb_glow": ((255, 214, 90), 2.0)})
K.GLOWS.update({"lamp_glow": ((255, 208, 120), 1.35), "bulb_glow": ((255, 226, 150), 2.2)})  # (warm, not blown to white)
ROUGH = {"gold": 0.32, "gold_dark": 0.36, "iron": 0.5, "iron_light": 0.5, "brief_black": 0.45, "panel_black": 0.4,
         "glass_blue": 0.12, "glass_deep": 0.12, "navy_roof": 0.6}

BMS = {}          # name -> (bmesh, look)
CUR = [Matrix.Identity(4)]
PREFIX = [""]
rng = random.Random(2024)


def reset():
    BMS.clear()
    CUR[:] = [Matrix.Identity(4)]
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)


@contextmanager
def at(x=0.0, y=0.0, z=0.0, rz=0.0, prefix=None, s=1.0):
    """Place what is built inside at (x, y, z), turned rz degrees about Z, scaled s (nests). prefix renames the meshes
    made inside."""
    CUR.append(CUR[-1] @ Matrix.Translation((x, y, z)) @ Matrix.Rotation(math.radians(rz), 4, "Z") @ Matrix.Scale(s, 4))
    if prefix is not None:
        PREFIX.append(prefix)
    try:
        yield
    finally:
        CUR.pop()
        if prefix is not None:
            PREFIX.pop()


def pt(p):
    return CUR[-1] @ Vector(p)


def mat(look):
    m = K.mat(look)
    if look in K.PAL and look not in K.GLOWS and look not in K.GLASS:
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Roughness"].default_value = ROUGH.get(look, 0.78)  # Roblox Plastic reads matte
        try:
            b.inputs["Specular IOR Level"].default_value = 0.22
        except Exception:
            pass
    return m


def bm_for(name, look):
    key = PREFIX[-1] + name
    if key not in BMS:
        BMS[key] = (bmesh.new(), look)
    return BMS[key][0]


def _merge(name, look, tmp, M, world=False):
    M = M if world else CUR[-1] @ M
    for v in tmp.verts:
        v.co = M @ v.co
    me = bpy.data.meshes.new("t")
    tmp.to_mesh(me)
    tmp.free()
    bm_for(name, look).from_mesh(me)
    bpy.data.meshes.remove(me)


def xform(c, rot=(0, 0, 0)):
    return Matrix.Translation(Vector(c)) @ Euler(tuple(math.radians(a) for a in rot), "XYZ").to_matrix().to_4x4()


def _shade(faces, smooth):
    for f in faces:
        f.smooth = smooth


# ------------------------------------------------------------------ primitives
def box(name, look, c, size, rot=(0, 0, 0), bevel=0.0, segs=1, smooth=False):
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    for v in tmp.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    if bevel > 0:
        bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=min(bevel, min(size) * 0.45), segments=segs, affect="EDGES", profile=0.5)
    _shade(tmp.faces, smooth)
    _merge(name, look, tmp, xform(c, rot))


def cyl(name, look, c, r, h, segs=16, rot=(0, 0, 0), r_top=None, cap=True, smooth=True, spin=0.0):
    """A (tapered) cylinder standing on c (its base centre) along local +Z, then rotated. segs=4 + spin=45 = a square."""
    tmp = bmesh.new()
    r_top = r if r_top is None else r_top
    a0 = math.radians(spin)
    bot = [tmp.verts.new((math.cos(a0 + k / segs * TAU) * r, math.sin(a0 + k / segs * TAU) * r, 0)) for k in range(segs)]
    top = [tmp.verts.new((math.cos(a0 + k / segs * TAU) * r_top, math.sin(a0 + k / segs * TAU) * r_top, h)) for k in range(segs)]
    _shade([tmp.faces.new((bot[k], bot[(k + 1) % segs], top[(k + 1) % segs], top[k])) for k in range(segs)], smooth)
    if cap:
        tmp.faces.new(list(reversed(bot))).smooth = False
        if r_top > 0.001:
            tmp.faces.new(top).smooth = False
    _merge(name, look, tmp, xform(c, rot))


def lathe(name, look, prof, segs=24, c=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    """Revolve a profile [(r, z)] / [(r, z, True)] about local Z. True = a hard corner there (the shading breaks, like a
    lip or a step). A point at r = 0 closes the end with a fan."""
    tmp = bmesh.new()
    bands, cur = [], []
    for p in prof:
        cur.append(p[:2])
        if len(p) > 2 and p[2] and len(cur) > 1:
            bands.append(cur)
            cur = [p[:2]]
    if len(cur) > 1:
        bands.append(cur)
    for band in bands:
        rings = []
        for r, z in band:
            if r < 1e-4:
                rings.append(tmp.verts.new((0, 0, z)))
            else:
                rings.append([tmp.verts.new((math.cos(k / segs * TAU) * r, math.sin(k / segs * TAU) * r, z)) for k in range(segs)])
        for i in range(len(rings) - 1):
            a, b = rings[i], rings[i + 1]
            for k in range(segs):
                j = (k + 1) % segs
                if isinstance(a, list) and isinstance(b, list):
                    f = tmp.faces.new((a[k], a[j], b[j], b[k]))
                elif isinstance(a, list):
                    f = tmp.faces.new((a[k], a[j], b))
                elif isinstance(b, list):
                    f = tmp.faces.new((a, b[j], b[k]))
                else:
                    continue
                f.smooth = smooth
    _merge(name, look, tmp, xform(c, rot))


def sphere(name, look, c, r, sub=2, scale=(1, 1, 1), smooth=True):
    tmp = bmesh.new()
    bmesh.ops.create_icosphere(tmp, subdivisions=sub, radius=r)
    for v in tmp.verts:
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2]))
    _shade(tmp.faces, smooth)
    _merge(name, look, tmp, xform(c))


def tube(name, look, path, radii, segs=8, cap=True, smooth=True):
    """A tube along points (local frame) with per-point radii (a number = all the same); parallel-transported rings."""
    if not isinstance(radii, (list, tuple)):
        radii = [radii] * len(path)
    tmp = bmesh.new()
    rings, side = [], None
    for i, p in enumerate(path):
        p = Vector(p)
        d = (Vector(path[min(i + 1, len(path) - 1)]) - Vector(path[max(i - 1, 0)])).normalized()
        if side is None:
            side = d.cross(Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 1, 0))).normalized()
        side = (side - d * side.dot(d)).normalized()
        up = side.cross(d).normalized()
        rings.append([tmp.verts.new(p + (side * math.cos(k / segs * TAU) + up * math.sin(k / segs * TAU)) * radii[i]) for k in range(segs)])
    for i in range(len(rings) - 1):
        _shade([tmp.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[i + 1][(k + 1) % segs], rings[i + 1][k]))
                for k in range(segs)], smooth)
    if cap:
        tmp.faces.new(list(reversed(rings[0]))).smooth = False
        tmp.faces.new(rings[-1]).smooth = False
    _merge(name, look, tmp, Matrix.Identity(4))


def arc(cx, cz, r, a0, a1, n=8, y=0.0):
    """Points on a circle in the local XZ plane (degrees; 0 = +X, 90 = up) - for tube paths (scrolls, handles, hoops)."""
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), y, cz + r * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
            for i in range(n + 1)]


def prism(name, look, pts, depth, c=(0, 0, 0), rot=(0, 0, 0), smooth=False):
    """A flat shape [(x, z)] in the local XZ plane (CCW seen from the front, -Y), extruded depth along Y, centred."""
    tmp = bmesh.new()
    fr = [tmp.verts.new((x, -depth / 2, z)) for x, z in pts]
    bk = [tmp.verts.new((x, depth / 2, z)) for x, z in pts]
    caps = [tmp.faces.new(fr), tmp.faces.new(list(reversed(bk)))]
    n = len(pts)
    sides = [tmp.faces.new((fr[(i + 1) % n], fr[i], bk[i], bk[(i + 1) % n])) for i in range(n)]
    _shade(sides, smooth)
    bmesh.ops.triangulate(tmp, faces=caps)  # (concave outlines: arrows, stars)
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces[:])
    _merge(name, look, tmp, xform(c, rot))


def poly(name, look, pts, thick=0.0, smooth=False, world=False):
    """One face through 3D points (local frame); thick > 0 adds the back face (so it shows from both sides)."""
    tmp = bmesh.new()
    vs = [tmp.verts.new(p) for p in pts]
    f = tmp.faces.new(vs)
    f.smooth = smooth
    if thick > 0:
        tmp.normal_update()
        n = f.normal.copy()
        bv = [tmp.verts.new(Vector(p) - n * thick) for p in pts]
        tmp.faces.new(list(reversed(bv))).smooth = smooth
        k = len(vs)
        for i in range(k):
            tmp.faces.new((vs[(i + 1) % k], vs[i], bv[i], bv[(i + 1) % k])).smooth = smooth
    _merge(name, look, tmp, Matrix.Identity(4), world=world)


def star(r_out, r_in, n=5, a0=90.0):
    return [((r_out if i % 2 == 0 else r_in) * math.cos(math.radians(a0 + i * 180 / n)),
             (r_out if i % 2 == 0 else r_in) * math.sin(math.radians(a0 + i * 180 / n))) for i in range(2 * n)]


def text(body, look, c, size, rot=(90, 0, 0), extrude=0.03, kind="bold"):
    """PREVIEW-ONLY sign text (the game draws a SurfaceGui here). rot (90, 0, 0) stands it up, reading from -Y."""
    cu = bpy.data.curves.new("txt", "FONT")
    cu.body, cu.align_x, cu.align_y, cu.size, cu.extrude = body, "CENTER", "CENTER", size, extrude
    f = K.font(kind)
    if f:
        cu.font = f
    ob = bpy.data.objects.new("txt", cu)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.update()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    tmp = bmesh.new()
    tmp.from_mesh(me)
    bpy.data.meshes.remove(me)
    _merge("Preview_Text_" + look, look, tmp, xform(c, rot))


def studs_rect(name, look, x0, x1, y0, y1, z, skip=None):
    """The game's standard LOW studs (ohstuds) on the 1-stud grid over a local rectangle at height z."""
    bm = bmesh.new()
    x = math.floor(x0) + 0.5
    while x < x1 - 0.3:
        y = math.floor(y0) + 0.5
        while y < y1 - 0.3:
            if x > x0 + 0.3 and y > y0 + 0.3 and not (skip and skip(x, y)):
                ohstuds.add_stud(bm, (x, y, z))
            y += 1
        x += 1
    _merge(name, look, bm, Matrix.Identity(4))


def flower(petal, petal_lk, centre, centre_lk, c, n, r=0.22, lobes=5):
    """A flat flower head (a rounded rose-curve disc + a centre button) at world point c, facing n."""
    tmp = bmesh.new()
    k = 20
    lob = lambda i: r * (0.5 + 0.5 * abs(math.cos(lobes * i / k * TAU / 2)))
    ring = [tmp.verts.new((math.cos(i / k * TAU) * lob(i), math.sin(i / k * TAU) * lob(i), 0.04)) for i in range(k)]
    low = [tmp.verts.new((v.co.x * 0.8, v.co.y * 0.8, -0.03)) for v in ring]
    top, bot = tmp.verts.new((0, 0, 0.07)), tmp.verts.new((0, 0, -0.04))
    for i in range(k):
        j = (i + 1) % k
        tmp.faces.new((ring[i], ring[j], top))
        tmp.faces.new((low[j], low[i], bot))
        tmp.faces.new((low[i], low[j], ring[j], ring[i]))
    _shade(tmp.faces, False)
    M = Matrix.Translation(Vector(c)) @ Vector(n).to_track_quat("Z", "Y").to_matrix().to_4x4() @ Matrix.Rotation(rng.uniform(0, 6.3), 4, "Z")
    _merge(petal, petal_lk, tmp, M, world=True)
    t2 = bmesh.new()
    bmesh.ops.create_cone(t2, cap_ends=True, segments=6, radius1=r * 0.32, radius2=r * 0.24, depth=0.1)
    for v in t2.verts:
        v.co.z += 0.07
    _merge(centre, centre_lk, t2, M, world=True)


def flowers_on(objs, petal, petal_lk, centre, centre_lk, pts, r=0.22, up=Vector((0, 0, 1))):
    """Stick flower heads onto the surface of objs (canopies), casting from pts (local frame) along -up."""
    bpy.context.view_layer.update()
    for p in pts:
        wp = pt(p)
        best = None
        for ob in objs:
            inv = ob.matrix_world.inverted()
            hit, loc, nor, _ = ob.ray_cast(inv @ wp, (inv.to_3x3() @ -up).normalized())
            if hit:
                wl = ob.matrix_world @ loc
                if best is None or (wl - wp).length < (best[0] - wp).length:
                    best = (wl, (ob.matrix_world.to_3x3() @ nor).normalized())
        if best:
            flower(petal, petal_lk, centre, centre_lk, best[0] + best[1] * 0.02, best[1].lerp(up, 0.4).normalized(),
                   r=r * rng.uniform(0.85, 1.15))


def rock(name, top_name, c, r, seed=0, squash=0.68, look="rock", top="rock_top", sub=1, top_at=0.55):
    """A chunky faceted boulder; faces looking up go to top_name (a lighter / mossy top)."""
    tmp = bmesh.new()
    bmesh.ops.create_icosphere(tmp, subdivisions=sub, radius=r)
    for v in tmp.verts:
        q = v.co / r
        v.co = v.co * (1 + 0.28 * noise.noise(q * 1.7 + Vector((seed * 3.1, seed * 1.7, 0.5))))
        v.co.z = max(v.co.z * squash, -r * 0.15)
    tmp.normal_update()
    tops = bmesh.new()
    me = bpy.data.meshes.new("t")
    tmp.to_mesh(me)
    tops.from_mesh(me)
    bpy.data.meshes.remove(me)
    tops.normal_update()
    bmesh.ops.delete(tops, geom=[f for f in tops.faces if f.normal.z <= top_at], context="FACES")
    bmesh.ops.delete(tmp, geom=[f for f in tmp.faces if f.normal.z > top_at], context="FACES")
    _shade(tmp.faces, False)
    _shade(tops.faces, False)
    rz = rng.uniform(0, 360)
    _merge(name, look, tmp, xform(c, (0, 0, rz)))
    _merge(top_name, top, tops, xform(c, (0, 0, rz)))


def tuft(name, look, c, h=0.9, blades=6, seed=0):
    """A grass tuft: thin tapering blades fanning out."""
    r = random.Random(seed)
    for i in range(blades):
        a = i / blades * TAU + r.uniform(-0.3, 0.3)
        lean = r.uniform(0.25, 0.55)
        hh = h * r.uniform(0.7, 1.1)
        base = Vector((math.cos(a) * 0.08, math.sin(a) * 0.08, 0))
        tip = Vector((math.cos(a) * lean, math.sin(a) * lean, hh))
        side = Vector((-math.sin(a), math.cos(a), 0)) * 0.09
        poly(name, look, [Vector(c) + base - side, Vector(c) + base + side, Vector(c) + tip], thick=0.03)


# ------------------------------------------------------------------ foliage (the approved tree canopy, from trees.py)
def leafy(name, blobs, look="bush", voxel=0.25, faces=700, lumpy=0.25, seed=0, squash=1.0, split=None, light=None):
    """Overlapping spheres (local frame) -> ONE organic surface (voxel remesh + lumps + smooth + thin) in ONE green
    (crnuch 2026-10-24: two-tone bushes looked like two different colours; the light does the shading). split + light
    = the trees' old two-tone split (<name>_Canopy + <name>_Light), kept only for reference. Returns the objects."""
    shade = look
    full = PREFIX[-1] + name
    bm = bmesh.new()
    for c, r in blobs:
        g = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=r)
        for v in g["verts"]:
            v.co = pt(Vector(v.co) + Vector(c))
    me = bpy.data.meshes.new(full + "_tmp")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(full + "_tmp", me)
    bpy.context.scene.collection.objects.link(ob)
    rm = ob.modifiers.new("Remesh", "REMESH")
    rm.mode, rm.voxel_size = "VOXEL", voxel
    _apply(ob)
    cz = sum((pt(c).z for c, _ in blobs), 0.0) / len(blobs)
    for v in ob.data.vertices:
        n1 = noise.noise(v.co * 0.42 + Vector((seed * 7.1, seed * 3.3, 1.7)))
        n2 = noise.noise(v.co * 0.9 + Vector((seed * 2.3, 5.1, seed)))
        v.co += v.normal * (n1 * lumpy + n2 * lumpy * 0.35)
        if squash != 1.0:
            v.co.z = cz + (v.co.z - cz) * squash
    sm = ob.modifiers.new("Smooth", "SMOOTH")
    sm.factor, sm.iterations = 0.5, 3
    dec = ob.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = min(1.0, faces / max(1, len(ob.data.polygons)))
    _apply(ob)
    if split is None:  # one colour: just name it and smooth it
        ob.name = ob.data.name = full + "_Leaves"
        ob.data.materials.clear()
        ob.data.materials.append(mat(look))
        for p in ob.data.polygons:
            p.use_smooth = True
        return [ob]
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.normal_update()
    bm.faces.ensure_lookup_table()
    keep = set()
    for f in bm.faces:
        cc = f.calc_center_median()
        if f.normal.z + noise.noise(cc * 0.3 + Vector((seed, 1.3, 2.1))) * 0.18 > split:
            keep.add(f.index)
    nbrs = {f.index: {g.index for v in f.verts for g in v.link_faces if g is not f} for f in bm.faces}
    for _ in range(5):
        nxt = set(keep)
        for i, ns in nbrs.items():
            frac = sum(1 for j in ns if j in keep) / max(1, len(ns))
            if i in keep and frac < 0.4:
                nxt.discard(i)
            elif i not in keep and frac > 0.6:
                nxt.add(i)
        keep = nxt
    lit = bm.copy()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index in keep], context="FACES")
    lit.faces.ensure_lookup_table()
    bmesh.ops.delete(lit, geom=[f for f in lit.faces if f.index not in keep], context="FACES")
    old = ob.data
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(old)
    out = []
    for suffix, b, look in (("_Canopy", bm, shade), ("_Light", lit, light)):
        m2 = bpy.data.meshes.new(full + suffix)
        b.to_mesh(m2)
        b.free()
        m2.materials.append(mat(look))
        for p in m2.polygons:
            p.use_smooth = True
        o2 = bpy.data.objects.new(full + suffix, m2)
        bpy.context.scene.collection.objects.link(o2)
        out.append(o2)
    return out


def _apply(ob):
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


# ------------------------------------------------------------------ scene, finish, render
def player(x, y, z=0.0):
    for (cx, cy, cz, sx, sy, sz) in ((0, 0, 4.4, 1.0, 1.0, 1.0), (0, 0, 2.9, 2.0, 1.0, 2.0), (-1.5, 0, 2.9, 1.0, 1.0, 2.0),
                                      (1.5, 0, 2.9, 1.0, 1.0, 2.0), (-0.5, 0, 0.95, 1.0, 1.0, 1.9), (0.5, 0, 0.95, 1.0, 1.0, 1.9)):
        box("Preview_Player", "avatar", (x + cx, y + cy, z + cz), (sx, sy, sz))


def finish():
    """Every named bmesh -> one object with one material (faces keep their own flat / smooth shading)."""
    sc = bpy.context.scene
    for name, (bm, look) in BMS.items():
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(me)
        bm.free()
        me.materials.append(mat(look))
        sc.collection.objects.link(bpy.data.objects.new(name, me))
    BMS.clear()


def scene(sun_rot=(52, 8, -32), sun=3.8):
    sc = bpy.context.scene
    _, s = K.sky_and_sun(sc, sun_energy=sun, sun_rot=sun_rot)
    sc.collection.objects.link(s)
    K.setup_eevee(sc, samples=48)
    return sc


REGIONS = {}  # region -> object names (built by region())


@contextmanager
def region(name):
    """Build a separate area (a line-up row, a scene): its meshes are finished on exit and remembered, so a render can
    show just that area (render(..., show=[name]))."""
    before = set(bpy.data.objects.keys())
    yield
    finish()
    REGIONS[name] = set(bpy.data.objects.keys()) - before


def render(out, name, loc, look, lens=32, res=(1600, 900), show=None):
    sc = bpy.context.scene
    if show is not None:
        keep = set().union(*(REGIONS[r] for r in show))
        every = set().union(*REGIONS.values())
        for ob in bpy.data.objects:
            ob.hide_render = ob.name in every and ob.name not in keep
    sc.camera = K.camera(name, loc, look, lens=lens)
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = os.path.join(out, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


def stats(skip=("Preview", "Scene", "Old", "Studs")):
    """Triangles per model (<Model>_...), the biggest single mesh (a Roblox MeshPart takes at most 20,000), and the
    preview studs (in the game the Studs system lays them on StudTop surfaces, so they are not part of the meshes)."""
    tot, big = {}, []
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith(skip):
            t = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            key = ob.name.split("_")[0]
            tot[key] = tot.get(key, 0) + t
            big.append((t, ob.name))
    print("tris per model:", dict(sorted(tot.items())))
    big.sort(reverse=True)
    print("biggest meshes:", big[:4], "(limit 20000 each)")
    over = [n for t, n in big if t > 20000]
    if over:
        print("!! OVER THE MESHPART LIMIT:", over)
    print("TOTAL tris", sum(tot.values()), "meshes", len(big))
    n = sum(len(ob.data.polygons) for ob in bpy.data.objects if ob.type == "MESH" and ob.name.startswith("Studs"))
    if n:
        print("preview studs (StudTop surfaces in game):", n // 32, "studs")
