# tools/blender/stud_tiles.py - the raised stud of the studded-brick world (2026-10-18, docs/ART_STYLE_STUDS.md).
# Builds ONE stud in Blender at two detail levels and exports it to tools/zones/stud_tiles.json; Studio
# (tools/zones/BuildStudTiles.lua) repeats it over the tile grids (8x8 ... 1x1) into EditableMeshes and uploads them,
# so a big floor is a handful of MeshParts, never thousands of stud instances.
# The shape copies ROBLOX'S OWN STUD (crnuch's call: "look like the roblox studs"): a low rounded square with slanted
# sides, about half a stud wide - but as real raised geometry instead of the flat SurfaceType.Studs texture.
#   full: 4 segments per rounded corner (near the camera, PC)       low: 1 segment per corner (phones / low graphics)
# 1 Blender m = 1 stud, 1-stud pitch (crnuch's call). Top 0.46 wide, foot 0.60 wide, 0.10 above the face, sunk 0.05
# into it so it never shows a seam. Blender (x, y, z) -> Roblox (x, z, -y); the stud's axis is +Z (Roblox +Y).
# Run headless:  /Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender/stud_tiles.py
# Also renders art/studs/stud_tiles_preview.png (an 8x8 tile, a 4x2 and a 1x1).
import bpy, json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT_JSON = os.path.join(ROOT, "tools", "zones", "stud_tiles.json")
OUT_PNG = os.path.join(ROOT, "art", "studs", "stud_tiles_preview.png")

PITCH, HEIGHT, SINK = 1.0, 0.10, 0.05
TOP_HALF, TOP_R = 0.23, 0.09  # the flat top: half-width, corner radius
SLANT = 0.07  # how far the slanted side reaches out past the top edge (the foot is 0.60 wide)
TILES = [[8, 8], [8, 4], [8, 2], [8, 1], [4, 4], [4, 2], [4, 1], [2, 2], [2, 1], [1, 1]]


def outline(half, r, segs):
    """A rounded square's outline, counter-clockwise: [(x, y, nx, ny)] (the normal points out)."""
    c = half - r
    pts = []
    for k, (sx, sy) in enumerate(((1, 1), (-1, 1), (-1, -1), (1, -1))):
        for i in range(segs + 1):
            a = (k + i / segs) * math.pi / 2 if segs else k * math.pi / 2 + math.pi / 4
            nx, ny = math.cos(a), math.sin(a)
            pts.append((sx * c + r * nx, sy * c + r * ny, nx, ny))
    return pts


def stud(segs):
    """One stud as (verts, normals, tris): tris = ((vi, ni) x 3), counter-clockwise seen from outside."""
    top = outline(TOP_HALF, TOP_R, segs)
    foot = outline(TOP_HALF + SLANT, TOP_R + SLANT, segs)
    k = len(top)
    rise = HEIGHT + SINK
    L = math.hypot(rise, SLANT)
    v = [(x, y, -SINK) for x, y, _, _ in foot] + [(x, y, HEIGHT) for x, y, _, _ in top] + [(0, 0, HEIGHT)]
    n = [(nx * rise / L, ny * rise / L, SLANT / L) for _, _, nx, ny in top] + [(0, 0, 1)]  # slanted wall, then up
    up, centre = k, 2 * k
    f = []
    for i in range(k):
        j = (i + 1) % k
        f.append(((i, i), (j, j), (k + j, j)))  # the slanted wall (smooth round the corners)
        f.append(((i, i), (k + j, j), (k + i, i)))
        f.append(((k + i, up), (k + j, up), (centre, up)))  # the flat top
    return v, n, f


def to_rbx(p):
    return (p[0], p[2], -p[1])


def export(segs):
    v, n, f = stud(segs)
    norm = []
    for x in n:
        L = math.sqrt(sum(c * c for c in x)) or 1
        norm.extend(round(c / L, 4) for c in to_rbx(x))
    return dict(
        v=[round(c, 4) for p in v for c in to_rbx(p)],
        n=norm,
        f=[i for tri in f for corner in tri for i in corner],
        tris=len(f),
    )


def preview(data):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)

    def make(name, lod, w, d, origin, colour):
        mesh = bpy.data.meshes.new(name)
        verts, faces = [], []
        sv, sf = data["lods"][lod]["v"], data["lods"][lod]["f"]
        k = len(sv) // 3
        for gx in range(w):
            for gz in range(d):
                off = len(verts)
                cx, cy = origin[0] + (gx + 0.5) * PITCH, origin[1] + (gz + 0.5) * PITCH
                for i in range(k):  # back to Blender axes for the preview
                    x, y, z = sv[3 * i], sv[3 * i + 1], sv[3 * i + 2]
                    verts.append((x + cx, -z + cy, y + origin[2]))
                for t in range(0, len(sf), 6):
                    faces.append((sf[t] + off, sf[t + 2] + off, sf[t + 4] + off))
        mesh.from_pydata(verts, [], faces)
        mesh.shade_smooth()
        ob = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(ob)
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = (*colour, 1)
        ob.data.materials.append(mat)

    def block(name, size, loc, colour):
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
        ob = bpy.context.active_object
        ob.name = name
        ob.scale = size
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = (*colour, 1)
        ob.data.materials.append(mat)

    green, orange, white = (0.12, 0.52, 0.02), (1.0, 0.35, 0.01), (0.9, 0.9, 0.9)
    block("Floor", (16, 12, 1), (4, 2, -0.5), green)
    make("Tile8x8", "full", 8, 8, (-4, -4, 0), green)
    block("Path", (2, 4, 1), (6, -2, -0.4), orange)
    make("Tile4x2", "full", 2, 4, (5, -4, 0.1), orange)
    block("Rim", (1, 1, 1.4), (10.5, 6.5, -0.3), white)
    make("Tile1x1", "low", 1, 1, (10, 6, 0.4), white)

    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_WORKBENCH"
    except TypeError:
        pass
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.display.shading.show_cavity = True
    sc.render.resolution_x, sc.render.resolution_y = 1200, 800
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = (13, -14, 11)
    d = [4 - 13, 2 + 14, -1 - 11]
    import mathutils
    cam.rotation_euler = mathutils.Vector(d).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 38
    os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
    sc.render.filepath = OUT_PNG
    bpy.ops.render.render(write_still=True)


data = dict(
    pitch=PITCH, half=TOP_HALF + SLANT, height=HEIGHT, sink=SINK, tiles=TILES,
    lods=dict(full=export(4), low=export(1)),
)
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))
for k, L in data["lods"].items():
    print(f"[studs] {k}: {L['tris']} tris/stud, 8x8 tile = {L['tris'] * 64} tris")
preview(data)
print("[studs] wrote", OUT_JSON, "and", OUT_PNG)
