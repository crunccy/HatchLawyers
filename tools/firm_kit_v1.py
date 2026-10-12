"""Law-firm environment kit builder (run inside Blender via blender-mcp).

Builds the modular pieces the plot is assembled from in Studio. Chunky, beveled, toy-like shapes in the
game palette; every piece is ONE mesh UV-mapped onto a shared flat/patterned palette texture
(FirmPalette.png), so each imports into Roblox as a single MeshPart.

Plot axes (match the characters): 1 m = 1 stud, the street/entrance is -Y, the plot grows toward +Y,
X is left/right (x>0 is the player's right when walking in). Floor top is z = 0.
"""
import bpy, bmesh, os, math
from mathutils import Vector

OUT_DIR = "/Users/ryanchen/HatchLawyers/Models - Environment"

# ------------------------------------------------------------------------------------------------ palette
SW = {}
GRID, CELL = 16, 32


def sw(name, rgb, pattern="flat"):
    if name not in SW:
        SW[name] = (len(SW), rgb, pattern)
    return name


def _palette_pixels():
    size = GRID * CELL
    px = [0.0] * (size * size * 4)
    for name, (idx, rgb, pattern) in SW.items():
        base = [v / 255 for v in rgb]
        dark = [v * 0.78 for v in base]
        light = [min(1, v * 1.12 + 0.04) for v in base]
        cx, cy = idx % GRID, idx // GRID
        ox, oy = cx * CELL, (GRID - 1 - cy) * CELL
        for y in range(CELL):
            for x in range(CELL):
                c = base
                if pattern == "plank":       # wood planks: dark seam every 8 px, offset joints
                    if y % 8 == 0 or (x == (0 if (y // 8) % 2 == 0 else 16)):
                        c = dark
                    elif y % 8 == 7:
                        c = light
                elif pattern == "tile":      # floor tile with a grout border
                    if min(x, y, CELL - 1 - x, CELL - 1 - y) < 2:
                        c = dark
                    elif y > CELL - 6:
                        c = light
                elif pattern == "carpet":    # carpet weave
                    if (x + y) % 6 == 0:
                        c = dark
                elif pattern == "books":     # book spines: vertical stripes of varying shade
                    band = (x // 4) % 4
                    c = [base, light, dark, [v * 0.92 for v in base]][band]
                    if y < 3 or y > CELL - 4:
                        c = dark
                elif pattern == "stud":      # toy-brick studs (like the reference floors)
                    dx, dy = (x % 16) - 7.5, (y % 16) - 7.5
                    r = math.hypot(dx, dy)
                    if 4.5 < r < 6.5:
                        c = dark if dy < 0 else light
                i = ((oy + y) * size + ox + x) * 4
                px[i:i + 4] = [c[0], c[1], c[2], 1.0]
    return px, size


def palette_material():
    px, size = _palette_pixels()
    img = bpy.data.images.get("FirmPalette")
    if img and img.size[0] != size:
        bpy.data.images.remove(img)
        img = None
    if not img:
        img = bpy.data.images.new("FirmPalette", size, size, alpha=False)
    img.pixels = px
    os.makedirs(OUT_DIR, exist_ok=True)
    img.filepath_raw = os.path.join(OUT_DIR, "FirmPalette.png")
    img.file_format = "PNG"
    img.save()
    mat = bpy.data.materials.get("FirmPalette") or bpy.data.materials.new("FirmPalette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    try:
        bsdf.inputs["Roughness"].default_value = 0.8
    except KeyError:
        pass
    return mat


def cell(name):
    idx = SW[name][0]
    cx, cy = idx % GRID, idx // GRID
    pad = 1.0 / (GRID * CELL)
    u0, v0 = cx / GRID + pad, (GRID - 1 - cy) / GRID + pad
    return u0, v0, u0 + 1 / GRID - 2 * pad, v0 + 1 / GRID - 2 * pad

# ------------------------------------------------------------------------------------------- geometry
class Piece:
    """Accumulates beveled boxes / tiled slabs into one bmesh with palette UVs."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")

    def _uv_faces(self, faces, color, tile=None):
        u0, v0, u1, v1 = cell(color)
        for f in faces:
            n = f.normal
            for loop in f.loops:
                p = loop.vert.co
                # planar projection, so patterned swatches line up; flat colors don't care
                if abs(n.z) > 0.7:
                    a, b = p.x, p.y
                elif abs(n.x) > 0.7:
                    a, b = p.y, p.z
                else:
                    a, b = p.x, p.z
                if tile:
                    fa = (a / tile) % 1.0
                    fb = (b / tile) % 1.0
                    loop[self.uv].uv = (u0 + fa * (u1 - u0), v0 + fb * (v1 - v0))
                else:
                    loop[self.uv].uv = ((u0 + u1) / 2, (v0 + v1) / 2)

    def _tiled_box(self, mn, mx, color, tile):
        """Axis-aligned box whose faces are split into tile-sized quads, each showing the full swatch
        (so patterned swatches like planks / tiles / carpet / book spines repeat instead of stretching)."""
        u0, v0, u1, v1 = cell(color)
        faces_def = [  # (fixed axis, fixed value, axis a, axis b, flip winding)
            (2, mx.z, 0, 1, False), (2, mn.z, 0, 1, True),
            (0, mx.x, 1, 2, False), (0, mn.x, 1, 2, True),
            (1, mx.y, 0, 2, True), (1, mn.y, 0, 2, False),
        ]
        for fixed, val, a, b, flip in faces_def:
            a0, a1, b0, b1 = mn[a], mx[a], mn[b], mx[b]
            if a1 - a0 < 1e-6 or b1 - b0 < 1e-6:
                continue
            na = max(1, int(-(-(a1 - a0) // tile)))
            nb = max(1, int(-(-(b1 - b0) // tile)))
            for ia in range(na):
                for ib in range(nb):
                    qa0 = a0 + ia * tile
                    qa1 = min(a1, qa0 + tile)
                    qb0 = b0 + ib * tile
                    qb1 = min(b1, qb0 + tile)
                    fa, fb = (qa1 - qa0) / tile, (qb1 - qb0) / tile
                    corners = [(qa0, qb0, 0, 0), (qa1, qb0, fa, 0), (qa1, qb1, fa, fb), (qa0, qb1, 0, fb)]
                    if flip:
                        corners = corners[::-1]
                    verts, uvs = [], []
                    for ca, cb, ua, ub in corners:
                        co = [0.0, 0.0, 0.0]
                        co[fixed], co[a], co[b] = val, ca, cb
                        verts.append(self.bm.verts.new(co))
                        uvs.append((u0 + ua * (u1 - u0), v0 + ub * (v1 - v0)))
                    f = self.bm.faces.new(verts)
                    for loop, uv in zip(f.loops, uvs):
                        loop[self.uv].uv = uv

    def box(self, mn, mx, color, bevel=0.06, tile=None):
        mn, mx = Vector(mn), Vector(mx)
        if tile:
            self._tiled_box(mn, mx, color, tile)
            return
        size = mx - mn
        geom = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = geom["verts"]
        for v in verts:
            v.co = Vector((mn.x + (v.co.x + 0.5) * size.x, mn.y + (v.co.y + 0.5) * size.y, mn.z + (v.co.z + 0.5) * size.z))
        faces = list({f for v in verts for f in v.link_faces})
        b = min(bevel, size.x * 0.3, size.y * 0.3, size.z * 0.3)
        if b > 0.005:
            edges = list({e for v in verts for e in v.link_edges})
            res = bmesh.ops.bevel(self.bm, geom=edges, offset=b, segments=1, affect="EDGES", profile=0.5)
            # The bevel replaces the cube's verts; the shrunken original faces hang off the new verts.
            faces = list({f for v in res.get("verts", []) for f in v.link_faces} | set(res.get("faces", [])))
        self._uv_faces([f for f in faces if f.is_valid], color, tile)

    def cyl(self, center, radius, height, color, segments=10, axis="Z"):
        cx, cy, cz = center
        geom = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segments,
                                     radius1=radius, radius2=radius, depth=height)
        verts = geom["verts"]
        for v in verts:
            x, y, z = v.co
            if axis == "X":
                x, y, z = z, y, x
            elif axis == "Y":
                x, y, z = x, z, y
            v.co = Vector((cx + x, cy + y, cz + z))
        faces = list({f for v in verts for f in v.link_faces})
        self._uv_faces(faces, color)

    def build(self, collection, mat, location=(0, 0, 0)):
        me = bpy.data.meshes.new(self.name)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        self.bm.to_mesh(me)
        self.bm.free()
        me.materials.append(mat)
        obj = bpy.data.objects.new(self.name, me)
        obj.location = location
        collection.objects.link(obj)
        return obj


def fresh_collection(name):
    coll = bpy.data.collections.get(name)
    if coll:
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
    return coll


def export_kit(collection_name, filename):
    coll = bpy.data.collections[collection_name]
    bpy.ops.object.select_all(action="DESELECT")
    for o in coll.objects:
        o.select_set(True)
    path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"},
                             path_mode="COPY", embed_textures=True, apply_scale_options="FBX_SCALE_ALL")
    return path
