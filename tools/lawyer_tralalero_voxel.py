"""Tralalero Tralala (Legendary lawyer) - VOXEL remake, run inside Blender:
    exec(open("/Users/ryanchen/HatchLawyers/tools/lawyer_tralalero_voxel.py").read()); print(build())

User 2026-10-10: "it should still be blocky, cartoony, and reminiscent of other brainrot / steal an egg games. it
shouldn't look so realistic and flat." The references (references/ref1-roll-path, ref2-item-shop: the voxel monkey,
palms and crates) are built from small chunky cubes; every cube reads on its own (darker rim, lighter top-left,
a little shade variation block to block) and characters have big cartoon eyes. So the shark is now a voxel
sculpture on a VOXEL-stud grid, sampled from an analytic cartoon design (deep chunky body, big head, big eyes,
fat sneakers), and every exposed cube face is UV'd to a "bevelled tile" cell of one palette texture.

Same conventions as every character: 1 Blender m = 1 stud, feet at z = 0, front (toward the client) = -Y,
nose toward -X (side-on along the desk, like the reference). Meshes Tralalero_<Part> with Part in Head /
UpperTorso / LeftUpperArm / RightUpperArm / LeftUpperLeg / LeftLowerLeg / RightUpperLeg (Shared.Puppet names).
"""
import math
import os

import bmesh
import bpy
from mathutils import Vector

ID = "Tralalero"
OUT = "/Users/ryanchen/HatchLawyers/Models - Characters/Lawyers"
VOXEL = 0.25

# palette (base colours; every voxel picks one of 3 shade variants)
TOP = (88, 132, 178)       # cartoon blue-grey back
TOP_FIN = (74, 114, 160)
BELLY = (240, 240, 236)
LINE = (34, 40, 58)        # gills, mouth, brow
EYE_W = (255, 255, 255)
PUPIL = (20, 20, 28)
TEETH = (255, 253, 244)
GUM = (210, 70, 90)
SHOE = (64, 168, 245)
SHOE_DARK = (38, 118, 205)
SOLE = (250, 250, 250)
SWOOSH = (255, 255, 255)
LACE = (245, 245, 245)

# ---------------------------------------------------------------------------------------------- design (analytic)
# body sections: (x, centre z, half width, half height) - chunkier & shorter than the smooth v4, big head
BODY = [
    (-2.60, 3.05, 0.10, 0.10),
    (-2.45, 3.02, 0.36, 0.34),
    (-2.20, 2.97, 0.58, 0.62),
    (-1.90, 2.93, 0.72, 0.84),
    (-1.55, 2.90, 0.80, 0.98),
    (-1.15, 2.88, 0.82, 1.04),
    (-0.65, 2.88, 0.78, 1.00),
    (-0.15, 2.92, 0.68, 0.88),
    (0.35, 2.98, 0.54, 0.70),
    (0.85, 3.05, 0.40, 0.50),
    (1.30, 3.12, 0.28, 0.34),
    (1.65, 3.18, 0.20, 0.22),
    (1.90, 3.22, 0.16, 0.17),
]
HEAD_X = -1.40   # voxels in front of this are the Head (it nods)


def section(x):
    if x <= BODY[0][0]:
        return None
    for a, b in zip(BODY, BODY[1:]):
        if a[0] <= x <= b[0]:
            t = (x - a[0]) / (b[0] - a[0])
            t = t * t * (3 - 2 * t)     # smooth between keys
            return tuple(a[i] + (b[i] - a[i]) * t for i in (1, 2, 3))
    return None


def in_body(x, y, z):
    s = section(x)
    if not s:
        return False
    cz, ry, rz = s
    # rounder-boxier toy cross-section (superellipse, n = 2.6)
    return (abs(y) / ry) ** 2.6 + (abs(z - cz) / rz) ** 2.6 <= 1.0


def body_top(x):
    s = section(x)
    return s[0] + s[2] if s else 0


def in_poly(px, pz, poly):
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > pz) != (zj > pz) and px < (xj - xi) * (pz - zi) / (zj - zi + 1e-9) + xi:
            inside = not inside
        j = i
    return inside


def dorsal_poly():
    t = body_top(-0.45)
    return [(-1.05, t - 0.3), (-0.85, t + 0.35), (-0.55, t + 0.85), (-0.25, t + 1.25), (-0.05, t + 1.35),
            (-0.10, t + 0.95), (0.10, t + 0.45), (0.35, body_top(0.35) - 0.2)]


TAIL = [(1.75, 3.35), (2.05, 3.75), (2.35, 4.15), (2.60, 4.45), (2.68, 4.30), (2.45, 3.75), (2.30, 3.30),
        (2.48, 2.95), (2.62, 2.65), (2.50, 2.62), (2.20, 2.90), (1.85, 3.05)]


def in_fins(x, y, z):
    """dorsal / tail / small second dorsal: 2 voxels thick around y = 0"""
    if abs(y) > 0.15:
        return False
    if in_poly(x, z, dorsal_poly()) and z > body_top(x) - 0.3:
        return True
    if in_poly(x, z, TAIL):
        return True
    t = body_top(1.2)
    if in_poly(x, z, [(1.05, t - 0.1), (1.25, t + 0.32), (1.40, t - 0.05)]):
        return True
    return False


def pectoral(x, y, z):
    """pectoral fins: a chunky slab out of each side behind the gills, swept back and down. -> side or 0"""
    for side in (-1, 1):
        # fin centre line from root (-1.25, side*0.7, 2.45) to tip (-0.55, side*1.05, 1.75)
        a = Vector((-1.25, side * 0.66, 2.40))
        b = Vector((-0.55, side * 1.00, 1.70))
        p = Vector((x, y, z))
        ab = b - a
        t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
        q = a + ab * t
        width = 0.34 * (1 - t) + 0.10      # wide root, narrow tip
        d = p - q
        # flat along the body normal (y), wide along x/z
        if abs(d.y) <= 0.14 and math.hypot(d.x, d.z) <= width:
            return side
    return 0


# legs: hip, knee, ankle (feet under them); front under the chest, a long middle leg on the client's side,
# rear under the back belly. Shorter + thicker than the smooth version (cartoon proportions).
LEGS = {
    "LeftUpperLeg": (Vector((-1.45, 0.30, 2.0)), Vector((-1.62, 0.30, 1.25)), Vector((-1.55, 0.32, 0.7))),
    "LeftLowerLeg": (Vector((-0.55, -0.35, 1.95)), Vector((-0.35, -0.55, 1.25)), Vector((-0.65, -0.62, 0.7))),
    "RightUpperLeg": (Vector((0.75, 0.10, 2.25)), Vector((0.95, 0.12, 1.35)), Vector((0.85, 0.14, 0.7))),
}


def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length, t


def in_leg(p):
    for name, (hip, knee, ankle) in LEGS.items():
        d1, t1 = seg_dist(p, hip, knee)
        d2, t2 = seg_dist(p, knee, ankle)
        if d1 <= 0.27 - 0.06 * t1 or d2 <= 0.21 - 0.03 * t2:
            return name
    return None


def shoe_at(p):
    """(leg name, colour) if p is inside a sneaker. Toe toward -x. ~1.5 long, 0.75 wide, 0.95 tall at the heel."""
    for name, (hip, knee, ankle) in LEGS.items():
        heel = ankle.x + 0.45
        toe = ankle.x - 1.05
        if not (toe <= p.x <= heel and abs(p.y - ankle.y) <= 0.40 and 0 <= p.z <= 1.0):
            continue
        u = (heel - p.x) / (heel - toe)      # 0 heel .. 1 toe
        dy = p.y - ankle.y
        # sole: thick white slab with a little toe spring
        sole_top = 0.26
        if p.z <= sole_top and not (u > 0.9 and p.z < 0.06):
            return name, SOLE
        # upper: tall at the heel, rounded down to the toe, a touch narrower than the sole
        top = 0.95 - 0.55 * u ** 1.4
        half = 0.36 - 0.10 * u ** 2
        if p.z <= top and abs(dy) <= half:
            # collar opening (dark) at the top behind the laces
            if p.z > top - 0.16 and u < 0.3 and abs(dy) < 0.2:
                return name, SHOE_DARK
            # laces: white stripes across the top of the tongue
            if p.z > top - 0.14 and 0.32 < u < 0.62 and abs(dy) < 0.22 and int(round(u * 12)) % 2 == 0:
                return name, LACE
            # swoosh on the outer faces: a tick from the heel low point sweeping up to the toe
            if abs(abs(dy) - half) < 0.13:
                sw = 0.42 + 0.30 * (u - 0.25) ** 2 * 3 if u < 0.25 else 0.42 + (u - 0.25) * 0.55
                if 0.12 < u < 0.86 and abs(p.z - sw) < 0.13:
                    return name, SWOOSH
            return name, SHOE
    return None


def face_color(x, y, z):
    """colour of a body / head voxel: countershading + the cartoon face"""
    s = section(x)
    cz, ry, rz = s
    rel = (z - cz) / rz            # -1 belly .. 1 back
    side = 1 if y > 0 else -1
    outer = abs(y) > ry * 0.45     # on a side face (not the centre line)
    # big cartoon eye: white oval, black pupil looking forward a bit, a shine voxel
    ex, ez = -1.82, cz + rz * 0.30
    if outer:
        de = ((x - ex) / 0.40) ** 2 + ((z - ez) / 0.36) ** 2
        if de <= 1.0:
            dp = ((x - (ex - 0.10)) / 0.22) ** 2 + ((z - (ez - 0.02)) / 0.24) ** 2
            if dp <= 1.0:
                if abs(x - (ex - 0.18)) < 0.13 and abs(z - (ez + 0.10)) < 0.13:
                    return EYE_W            # shine
                return PUPIL
            return EYE_W
        # cocky brow: a slanted dark bar over the eye (lower toward the snout)
        bz = ez + 0.46 + (x - ex) * 0.35
        if abs(x - ex) < 0.42 and abs(z - bz) < 0.12:
            return LINE
        # gills: three dark vertical slits behind the eye
        for gx in (-1.30, -1.12, -0.94):
            if abs(x - gx) < 0.07 and -0.35 < rel < 0.30:
                return LINE
    # big grin along the lower head: dark line with white teeth under it, curling up at the corner
    if x < -1.35:
        mz = cz - rz * 0.28 + max(0.0, x + 1.75) * 0.9          # rises toward the back corner
        if abs(z - mz) < 0.12 and abs(y) > ry * 0.25:
            return LINE
        if mz - 0.30 < z < mz - 0.10 and abs(y) > ry * 0.25 and x < -1.6:
            # tooth / gap pattern
            return TEETH if int(math.floor((x + 3) / VOXEL)) % 2 == 0 else GUM
    if rel < -0.30 + (0.15 if x < -1.6 else 0.0):
        return BELLY
    return TOP


# ---------------------------------------------------------------------------------------------- voxelize
def classify(p):
    """-> (part, colour) or None for the voxel centred at p"""
    shoe = shoe_at(p)
    if shoe:
        return shoe
    leg = in_leg(p)
    if leg and not in_body(p.x, p.y, p.z):
        return leg, TOP
    pec = pectoral(p.x, p.y, p.z)
    if pec and not in_body(p.x, p.y, p.z):
        return ("RightUpperArm" if pec > 0 else "LeftUpperArm"), TOP_FIN
    if in_body(p.x, p.y, p.z):
        return ("Head" if p.x < HEAD_X else "UpperTorso"), face_color(p.x, p.y, p.z)
    if in_fins(p.x, p.y, p.z):
        return "UpperTorso", TOP_FIN
    return None


def voxelize():
    grid = {}
    nx0, nx1 = int(math.floor(-2.8 / VOXEL)), int(math.ceil(2.8 / VOXEL))
    ny = int(math.ceil(1.15 / VOXEL))
    nz1 = int(math.ceil(4.8 / VOXEL))
    for i in range(nx0, nx1):
        for j in range(-ny, ny):
            for k in range(0, nz1):
                p = Vector(((i + 0.5) * VOXEL, (j + 0.5) * VOXEL, (k + 0.5) * VOXEL))
                c = classify(p)
                if c:
                    grid[(i, j, k)] = c
    return grid


# ---------------------------------------------------------------------------------------------- texture
GRID_CELLS, CELL = 16, 16
CELLS = {}


def variant(i, j, k):
    """stable per-voxel shade variant 0..2 (subtle block-to-block variation, like the references)"""
    h = (i * 73856093) ^ (j * 19349663) ^ (k * 83492791)
    return (h % 7) % 3


def cell_for(rgb, v, top):
    key = (rgb, v, top)
    if key not in CELLS:
        CELLS[key] = len(CELLS)
    return CELLS[key]


def cell_uvs(idx):
    """the 4 corner UVs of a palette cell (inset half a pixel so filtering doesn't bleed)"""
    cx, cy = idx % GRID_CELLS, idx // GRID_CELLS
    size = GRID_CELLS * CELL
    e = 0.5 / size
    u0, u1 = cx / GRID_CELLS + e, (cx + 1) / GRID_CELLS - e
    v1, v0 = 1 - cy / GRID_CELLS - e, 1 - (cy + 1) / GRID_CELLS + e
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def make_texture():
    size = GRID_CELLS * CELL
    px = [0.0] * (size * size * 4)
    for (rgb, v, top), idx in CELLS.items():
        cx, cy = idx % GRID_CELLS, idx // GRID_CELLS
        shade = (1.0, 0.94, 1.05)[v] * (1.06 if top else 0.97)
        base = [min(1.0, c / 255 * shade) for c in rgb]
        for y in range(CELL):
            for x in range(CELL):
                # bevelled tile: darker 1-2 px rim, a light bevel on the top-left, a soft centre
                edge = min(x, y, CELL - 1 - x, CELL - 1 - y)
                k = 1.0
                if edge == 0:
                    k = 0.70
                elif edge == 1:
                    k = 0.84
                elif (x <= 2 or y >= CELL - 3) and edge == 2:
                    k = 1.10           # light catch (top-left)
                elif (x >= CELL - 3 or y <= 2) and edge == 2:
                    k = 0.93
                row = size - 1 - (cy * CELL + y)
                j = (row * size + cx * CELL + x) * 4
                px[j:j + 4] = [min(1.0, base[0] * k), min(1.0, base[1] * k), min(1.0, base[2] * k), 1.0]
    name = f"{ID}VoxelPalette"
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
    bsdf.inputs["Roughness"].default_value = 0.6
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    return mat


# ---------------------------------------------------------------------------------------------- mesh
DIRS = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
        ((-1, 0, 0), [(0, 1, 0), (0, 0, 0), (0, 0, 1), (0, 1, 1)]),
        ((0, 1, 0), [(1, 1, 0), (0, 1, 0), (0, 1, 1), (1, 1, 1)]),
        ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
        ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
        ((0, 0, -1), [(0, 1, 0), (1, 1, 0), (1, 0, 0), (0, 0, 0)])]


def build_meshes(grid, coll, mat):
    parts = {}
    for (i, j, k), (part, rgb) in grid.items():
        parts.setdefault(part, []).append(((i, j, k), rgb))
    obs = []
    for part, cells in parts.items():
        bm = bmesh.new()
        uv = bm.loops.layers.uv.new("UVMap")
        cache = {}

        def vert(co):
            v = cache.get(co)
            if v is None:
                v = bm.verts.new((co[0] * VOXEL, co[1] * VOXEL, co[2] * VOXEL))
                cache[co] = v
            return v
        for (i, j, k), rgb in cells:
            for (dx, dy, dz), corners in DIRS:
                nb = grid.get((i + dx, j + dy, k + dz))
                if nb and nb[0] == part:
                    continue            # hidden inside this part
                f = bm.faces.new([vert((i + a, j + b, k + c)) for a, b, c in corners])
                idx = cell_for(rgb, variant(i, j, k), dz == 1)
                for loop, co in zip(f.loops, cell_uvs(idx)):
                    loop[uv].uv = co
                f.smooth = False
        me = bpy.data.meshes.new(f"{ID}_{part}")
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(f"{ID}_{part}", me)
        ob.data.materials.append(mat)
        coll.objects.link(ob)
        obs.append(ob)
    return obs


def build():
    old = bpy.data.collections.get(ID)
    if old:
        for ob in list(old.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
        coll = old
    else:
        coll = bpy.data.collections.new(ID)
        bpy.context.scene.collection.children.link(coll)
    CELLS.clear()
    grid = voxelize()
    # cells are created while meshing; the texture is drawn after
    mat = bpy.data.materials.get(f"{ID}VoxelPalette") or bpy.data.materials.new(f"{ID}VoxelPalette")
    obs = build_meshes(grid, coll, mat)
    make_texture()
    tris = sum(len(o.data.polygons) * 2 for o in obs)
    zs = [v.co.z for o in obs for v in o.data.vertices]
    xs = [v.co.x for o in obs for v in o.data.vertices]
    ys = [v.co.y for o in obs for v in o.data.vertices]
    return (f"{len(grid)} voxels, {len(obs)} meshes {sorted(o.name for o in obs)}, {tris} tris, "
            f"size {max(xs) - min(xs):.2f} x {max(ys) - min(ys):.2f} x {max(zs) - min(zs):.2f}, bottom {min(zs):.2f}, "
            f"{len(CELLS)} palette cells")
