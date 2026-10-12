# tools/blender/zone_render.py - renders a stretch of each egg zone from Studio's real parts, for checking how a zone
# looks when Studio's viewport can't be captured (2026-10-12, zones 3-6). Input: EXPORT_DIR/zone_<Id>.json
# ({ x0, x1, parts = [{ p, s, r (row-major 3x3), c, sh, n (neon), t }] }, exported from Studio with HttpService). Output:
# art/zones/<Id>.png - the view from the zone's entrance looking down the lane. Own scene "ZoneRender".
# Roblox (x, y, z) -> Blender (x, -z, y).
import bpy, math, json, os, glob
from mathutils import Matrix, Vector

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
# (a folder Blender can read - not a Claude session's scratch folder, which other apps can't see; delete it after)
EXPORT_DIR = os.environ.get("ZONE_EXPORT_DIR", os.path.join(REPO, "_zone_export"))
OUT = os.path.join(REPO, "art", "zones")
os.makedirs(OUT, exist_ok=True)

M = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
sc = bpy.data.scenes.get("ZoneRender") or bpy.data.scenes.new("ZoneRender")
meshes = {}


def mesh(kind):
    if kind in meshes:
        return meshes[kind]
    me = bpy.data.meshes.new("ZR_" + kind)
    if kind == "Ball":
        import bmesh
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=8, radius=0.5)
        bm.to_mesh(me)
        bm.free()
    elif kind == "Cylinder":  # Roblox cylinders run along their X axis
        import bmesh
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=18, radius1=0.5, radius2=0.5, depth=1.0)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
        bm.to_mesh(me)
        bm.free()
    else:
        v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
        f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        me.from_pydata(v, [], f)
    me.update()
    meshes[kind] = me
    return me


done = []
for path in sorted(glob.glob(os.path.join(EXPORT_DIR, "zone_*.json"))):
    zone = os.path.basename(path)[5:-5]
    data = json.load(open(path))
    for o in list(sc.collection.all_objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for d in data["parts"]:
        kind = d["sh"] if d["sh"] in ("Ball", "Cylinder") else "Block"
        o = bpy.data.objects.new("P", mesh(kind))
        r = d["r"]
        R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
        # the part's local axes in Roblox, mapped; its size stays on its own local axes
        world = (M @ R).to_4x4()
        world.translation = Vector((d["p"][0], -d["p"][2], d["p"][1]))
        o.matrix_world = world
        o.scale = (d["s"][0], d["s"][1], d["s"][2])  # (sizes stay on the part's own axes; M already mapped them)
        rgb = d["c"]
        o.color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1 - d.get("t", 0) * 0.6)
        sc.collection.objects.link(o)
    # camera at the zone's entrance (its east end), eye-height of a big player, looking down the lane
    x1, x0 = data["x1"], data["x0"]
    cam_data = bpy.data.cameras.get("ZR_Cam") or bpy.data.cameras.new("ZR_Cam")
    cam_data.lens = 22
    cam = bpy.data.objects.new("ZR_Cam", cam_data)
    sc.collection.objects.link(cam)
    cam.location = (x1 + 6, -12, 22)
    target = Vector((x0 + 30, 4, 2))
    if "cam" in data:  # (optional, Roblox coords: any view, e.g. the lane's entrance from the plaza)
        c, tg = data["cam"], data["target"]
        cam.location = (c[0], -c[2], c[1])
        target = Vector((tg[0], -tg[2], tg[1]))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "OBJECT"
    sc.display.shading.show_cavity = True
    sc.display.shading.show_object_outline = True
    sc.display.shading.show_shadows = True
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x, sc.render.resolution_y = 1400, 800
    sc.world = sc.world or bpy.data.worlds.new("ZR_World")
    sc.world.color = (0.55, 0.75, 0.95)
    sc.render.filepath = os.path.join(OUT, zone + ".png")
    bpy.ops.render.render(write_still=True, scene=sc.name)
    done.append(f"{zone}: {len(data['parts'])} parts")
print("; ".join(done) + f" -> {OUT}")
