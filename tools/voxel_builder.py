"""Voxel character builder for Hatch a Lawyer & Get Rich! clients.

Run inside Blender (via blender-mcp). Builds cartoony voxel characters on the same R15 skeleton as the
imported lawyer (LawyerSkin_Rig), so the lawyer animations play on every client. All characters share one
palette texture (ClientPalette.png) whose swatches have a painted bevel, giving the voxel-tile look.

Conventions (match the lawyer): 1 Blender metre = 1 Roblox stud, the character faces -Y, its right is -X.
Each body part is its own mesh named like the R15 part, fully weighted to the bone of the same name.
"""
import bpy, bmesh, os
from mathutils import Vector

OUT_DIR = "/Users/ryanchen/HatchLawyers/Models - Characters/Clients"
REF_RIG = "LawyerSkin_Rig"

# ----------------------------------------------------------------------------------------------- palette
PALETTE = {}
GRID, CELL = 16, 32  # 16x16 swatches of 32 px -> 512 px texture


def pal(name, rgb):
    if name not in PALETTE:
        PALETTE[name] = (len(PALETTE), rgb)
    return name


def build_palette_image():
    size = GRID * CELL
    img = bpy.data.images.get("ClientPalette")
    if img and img.size[0] != size:
        bpy.data.images.remove(img)
        img = None
    if not img:
        img = bpy.data.images.new("ClientPalette", size, size, alpha=False)
    px = [0.0] * (size * size * 4)
    for name, (idx, rgb) in PALETTE.items():
        base = [v / 255 for v in rgb]
        gap = [v * 0.55 for v in base]
        light = [min(1, v * 1.15 + 0.06) for v in base]
        shade = [v * 0.84 for v in base]
        cx, cy = idx % GRID, idx // GRID
        ox, oy = cx * CELL, (GRID - 1 - cy) * CELL  # image rows start at the bottom
        for y in range(CELL):
            for x in range(CELL):
                edge = min(x, y, CELL - 1 - x, CELL - 1 - y)
                if edge < 2:
                    c = gap            # dark gap between voxels
                elif y >= CELL - 6:
                    c = light          # top highlight
                elif x >= CELL - 6 or y < 6:
                    c = shade          # bottom/right shadow
                else:
                    c = base
                i = ((oy + y) * size + ox + x) * 4
                px[i:i + 4] = [c[0], c[1], c[2], 1.0]
    img.pixels = px
    os.makedirs(OUT_DIR, exist_ok=True)
    img.filepath_raw = os.path.join(OUT_DIR, "ClientPalette.png")
    img.file_format = "PNG"
    img.save()
    return img


def cell_uv(name):
    idx = PALETTE[name][0]
    cx, cy = idx % GRID, idx // GRID
    u0 = cx / GRID
    v0 = (GRID - 1 - cy) / GRID
    pad = 0.5 / (GRID * CELL)
    return (u0 + pad, v0 + pad, u0 + 1 / GRID - pad, v0 + 1 / GRID - pad)


def palette_material():
    mat = bpy.data.materials.get("ClientPalette")
    img = build_palette_image()
    if not mat:
        mat = bpy.data.materials.new("ClientPalette")
        mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    try:
        bsdf.inputs["Roughness"].default_value = 0.85
    except KeyError:
        pass
    return mat

# ----------------------------------------------------------------------------------------- body layout
# Part boxes (world space, studs) copied from the imported lawyer so proportions and joints match.
# (x0, y0, z0, x1, y1, z1), voxel counts (nx, ny, nz). y0 is the FRONT (the face side).
PARTS = {
    "Head":          ((-0.578, -0.473, 3.430, 0.578, 0.353, 4.478), (12, 8, 10)),
    "UpperTorso":    ((-0.628, -0.440, 2.640, 0.628, 0.403, 3.525), (13, 8, 9)),
    "LowerTorso":    ((-0.628, -0.440, 1.740, 0.628, 0.403, 2.640), (13, 8, 9)),
    "LeftUpperArm":  ((0.592, -0.156, 2.635, 0.888, 0.156, 3.250), (3, 3, 6)),
    "LeftLowerArm":  ((0.592, -0.156, 1.931, 0.888, 0.156, 2.635), (3, 3, 7)),
    "LeftHand":      ((0.607, -0.140, 1.492, 0.892, 0.140, 1.931), (3, 3, 4)),
    "RightUpperArm": ((-0.888, -0.156, 2.635, -0.592, 0.156, 3.250), (3, 3, 6)),
    "RightLowerArm": ((-0.888, -0.156, 1.931, -0.592, 0.156, 2.635), (3, 3, 7)),
    "RightHand":     ((-0.892, -0.140, 1.492, -0.607, 0.140, 1.931), (3, 3, 4)),
    "LeftUpperLeg":  ((0.107, -0.208, 1.070, 0.453, 0.208, 1.880), (3, 4, 8)),
    "LeftLowerLeg":  ((0.107, -0.208, 0.376, 0.453, 0.208, 1.070), (3, 4, 7)),
    "LeftFoot":      ((0.100, -0.410, 0.000, 0.460, 0.210, 0.376), (4, 6, 3)),
    "RightUpperLeg": ((-0.453, -0.208, 1.070, -0.107, 0.208, 1.880), (3, 4, 8)),
    "RightLowerLeg": ((-0.453, -0.208, 0.376, -0.107, 0.208, 1.070), (3, 4, 7)),
    "RightFoot":     ((-0.460, -0.410, 0.000, -0.100, 0.210, 0.376), (4, 6, 3)),
}
ROOT_BOX = (-0.6, -0.3, 1.95, 0.6, 0.3, 3.15)  # HumanoidRootPart (made invisible in Studio)

FACES = [  # (normal axis, sign, quad corner offsets)
    (0, -1, [(0, 0, 0), (0, 1, 0), (0, 1, 1), (0, 0, 1)]),
    (0, 1, [(1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)]),
    (1, -1, [(0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)]),
    (1, 1, [(0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1)]),
    (2, -1, [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)]),
    (2, 1, [(0, 0, 1), (0, 1, 1), (1, 1, 1), (1, 0, 1)]),
]


def voxel_mesh(name, voxels, origin, step):
    """voxels: {(i,j,k): colorName}. Emits only exposed faces; each face UV'd to its palette swatch."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    for (i, j, k), color in voxels.items():
        u0, v0, u1, v1 = cell_uv(color)
        corners_uv = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
        for axis, sign, quad in FACES:
            n = [i, j, k]
            n[axis] += sign
            if tuple(n) in voxels:
                continue
            verts = []
            for (dx, dy, dz) in quad:
                p = Vector((origin[0] + (i + dx) * step[0], origin[1] + (j + dy) * step[1], origin[2] + (k + dz) * step[2]))
                verts.append(bm.verts.new(p))
            face = bm.faces.new(verts)
            for loop, uvc in zip(face.loops, corners_uv):
                loop[uv].uv = uvc
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    # FACES winds every quad inward; Blender draws both sides so it looked fine, but Roblox culls back
    # faces (clients rendered inside-out / see-through). Flip them so the normals point out.
    bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return me

# ------------------------------------------------------------------------------------------ painting
def grid_rows(art, legend):
    """ASCII art rows (top to bottom) -> {(col,row_from_bottom): color}. '.' = keep base."""
    out = {}
    h = len(art)
    for r, line in enumerate(art):
        for c, ch in enumerate(line):
            if ch != "." and ch != " ":
                out[(c, h - 1 - r)] = legend[ch]
    return out


def paint_part(name, spec):
    (x0, y0, z0, x1, y1, z1), (nx, ny, nz) = PARTS[name]
    base = spec.get("base")
    front = grid_rows(spec["front"], spec["legend"]) if "front" in spec else {}
    rows = spec.get("rows")        # list of colors bottom->top for every face (sleeves, pants...)
    top = spec.get("top")
    back_rows = spec.get("back_rows", {})   # {row_from_bottom: color} for back + sides (hair)
    vox = {}
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                c = base
                if rows:
                    c = rows[min(k, len(rows) - 1)]
                if k in back_rows and (j > 0 or i in (0, nx - 1)):
                    c = back_rows[k]
                if top and k == nz - 1:
                    c = top
                if j == 0 and (i, k) in front:
                    c = front[(i, k)]
                vox[(i, j, k)] = c
    return vox, (x0, y0, z0), ((x1 - x0) / nx, (y1 - y0) / ny, (z1 - z0) / nz)


def box_voxels(box, color, step=0.1):
    """Accessory voxels: fills a world box with ~0.1 cubes. color: name or fn(i,j,k,nx,ny,nz)."""
    x0, y0, z0, x1, y1, z1 = box
    nx = max(1, round((x1 - x0) / step))
    ny = max(1, round((y1 - y0) / step))
    nz = max(1, round((z1 - z0) / step))
    vox = {}
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                c = color(i, j, k, nx, ny, nz) if callable(color) else color
                if c:
                    vox[(i, j, k)] = c
    return vox, (x0, y0, z0), ((x1 - x0) / nx, (y1 - y0) / ny, (z1 - z0) / nz)

# ------------------------------------------------------------------------------------------- building
def join_meshes(meshes, name):
    bm = bmesh.new()
    for me in meshes:
        bm.from_mesh(me)
    out = bpy.data.meshes.new(name)
    bm.to_mesh(out)
    bm.free()
    for me in meshes:
        bpy.data.meshes.remove(me)
    return out


def build_character(char_id, spec, offset_x=0.0):
    ref = bpy.data.objects[REF_RIG]
    coll = bpy.data.collections.get(char_id)
    if coll:
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new(char_id)
        bpy.context.scene.collection.children.link(coll)
    mat = palette_material()

    rig = ref.copy()
    rig.data = ref.data.copy()
    rig.name = char_id + "_Rig"
    rig.animation_data_clear()
    rig.location = (0, 0, 0)            # the reference rig may have been moved around for previews
    rig.rotation_euler = (0, 0, 0)
    rig.scale = (1, 1, 1)
    coll.objects.link(rig)

    def make_obj(part_name, me):
        me.materials.append(mat)
        o = bpy.data.objects.new(part_name if offset_x == 0 else part_name, me)
        o.name = part_name
        o.data.name = f"{char_id}_{part_name}"
        coll.objects.link(o)
        o.parent = rig
        vg = o.vertex_groups.new(name="HumanoidRootNode" if part_name == "HumanoidRootPart" else part_name)
        vg.add(list(range(len(me.vertices))), 1.0, "REPLACE")
        mod = o.modifiers.new("Armature", "ARMATURE")
        mod.object = rig
        return o

    extras = spec.get("extras", {})
    for part_name in PARTS:
        vox, origin, step = paint_part(part_name, spec["parts"][part_name])
        meshes = [voxel_mesh(part_name + "_base", vox, origin, step)]
        for box, color in extras.get(part_name, []):
            v2, o2, s2 = box_voxels(box, color)
            meshes.append(voxel_mesh(part_name + "_extra", v2, o2, s2))
        make_obj(part_name, join_meshes(meshes, part_name))

    # HumanoidRootPart: a plain box (set invisible in Studio), same as the lawyer's.
    v, o, s = box_voxels(ROOT_BOX, spec["parts"]["UpperTorso"].get("base") or "skin_light", step=0.6)
    make_obj("HumanoidRootPart", voxel_mesh("HumanoidRootPart", v, o, s))

    rig.location.x = offset_x
    return rig


def export_character(char_id):
    coll = bpy.data.collections[char_id]
    rig = bpy.data.objects[char_id + "_Rig"]
    old_x = rig.location.x
    rig.location.x = 0
    bpy.ops.object.select_all(action="DESELECT")
    for o in coll.objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = rig
    path = os.path.join(OUT_DIR, f"Client_{char_id}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, object_types={"ARMATURE", "MESH"},
        add_leaf_bones=False, path_mode="COPY", embed_textures=True,
        apply_scale_options="FBX_SCALE_ALL", bake_anim=False,
    )
    rig.location.x = old_x
    return path
