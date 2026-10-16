"""Blender-authored block kit for the hub's two physical minigames.

Run with Blender's Python API (UI or --background). One Blender metre = one stud.
Exports a compact parts description consumed by tools/zones/BuildMinigameKit.lua.
"""
import bpy
import json
import math
import os
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
OUT_JSON = os.path.join(ROOT, "tools", "zones", "minigame_kit.json")
OUT_BLEND = os.path.join(ROOT, "art", "minigames", "MinigameKit.blend")

sc = bpy.data.scenes.get("MinigameKit") or bpy.data.scenes.new("MinigameKit")
for obj in list(sc.collection.all_objects):
    bpy.data.objects.remove(obj, do_unlink=True)

cube_mesh = bpy.data.meshes.get("MinigameKitCube")
if cube_mesh is None:
    cube_mesh = bpy.data.meshes.new("MinigameKitCube")
    cube_mesh.from_pydata(
        [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, .5, -.5), (-.5, .5, -.5),
         (-.5, -.5, .5), (.5, -.5, .5), (.5, .5, .5), (-.5, .5, .5)],
        [],
        [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)],
    )
    cube_mesh.update()

MODEL_DATA = {"models": {}, "animations": {}}
MODEL_ROOTS = {}
MAT = {
    "brick": 0,
    "smooth": 1,
    "metal": 2,
    "neon": 3,
}


def model(name, display_x=0):
    root = bpy.data.objects.new(name, None)
    root.empty_display_type = "CUBE"
    root.empty_display_size = .3
    root.location = (display_x, 0, 0)
    sc.collection.objects.link(root)
    MODEL_ROOTS[name] = root
    return root


def block(root, name, pos, size, rgb, material="brick", rot=(0, 0, 0)):
    obj = bpy.data.objects.new(name, cube_mesh)
    obj.rotation_euler = tuple(math.radians(v) for v in rot)
    obj.color = (*[v / 255 for v in rgb], 1)
    obj["rgb"] = list(rgb)
    obj["surface"] = material
    sc.collection.objects.link(obj)
    obj.parent = root
    obj.location = pos
    obj.scale = size
    return obj


WOOD = (150, 88, 50)
DARK_WOOD = (96, 54, 32)
GOLD = (255, 200, 46)
GREEN = (75, 180, 75)
PALE = (238, 235, 207)
RED = (225, 67, 63)
BLUE = (64, 150, 220)
INK = (43, 37, 52)

# All coordinates are Blender local: X = Roblox X, Z = Roblox Y, -Y = Roblox Z.
# The pivot for the two tables is the centre of the playable top surface. The Lua game places
# its hit targets and cases relative to this pivot, then animates those objects in Roblox.
bench = model("GavelBench", -18)
block(bench, "BenchTop", (0, 0, 0), (13.2, 6.8, .55), WOOD)
block(bench, "TopInlay", (0, -.02, .29), (12.65, 6.25, .08), (186, 117, 66), "smooth")
block(bench, "FrontApron", (0, -2.98, -1.05), (12.8, .45, 1.7), DARK_WOOD)
block(bench, "BackApron", (0, 2.98, -1.05), (12.8, .45, 1.7), DARK_WOOD)
for x in (-5.7, 5.7):
    for y in (-2.55, 2.55):
        block(bench, "ChunkyLeg", (x, y, -1.35), (1.05, 1.05, 2.7), WOOD)
        block(bench, "Foot", (x, y, -2.82), (1.25, 1.25, .24), GOLD, "metal")
block(bench, "FrontGoldBand", (0, -3.22, -.72), (12.2, .1, .16), GOLD, "metal")
block(bench, "BackGoldBand", (0, 3.22, -.72), (12.2, .1, .16), GOLD, "metal")
block(bench, "GameBoard", (0, 0, .38), (11.6, 4.8, .16), GREEN)
# Nine deep brick sockets match the target hitbox grid in Minigames.client.lua.
for row in range(3):
    for col in range(3):
        x, y = (col - 1) * 3.6, (row - 1) * 1.65
        block(bench, "SocketOuter", (x, y, .52), (2.9, 1.55, .18), DARK_WOOD)
        block(bench, "SocketRim", (x, y, .63), (2.65, 1.3, .12), GOLD, "metal")
        block(bench, "SocketWell", (x, y, .71), (2.4, 1.08, .1), INK, "smooth")
for x in (-5.65, 5.65):
    block(bench, "CornerPost", (x, 2.75, 1.45), (.38, .38, 2.3), RED)
block(bench, "BackRail", (0, 2.75, 2.55), (11.7, .42, .38), GOLD, "metal")
block(bench, "SignBoard", (0, 2.70, 3.35), (7.3, .5, 1.0), RED)
block(bench, "SignFace", (0, 2.42, 3.35), (6.5, .12, .7), PALE, "smooth")
for x in (-3.25, 3.25):
    block(bench, "SignBolt", (x, 2.32, 3.35), (.18, .1, .18), GOLD, "metal")

table = model("LuckyBriefcaseTable", 0)
block(table, "TableTop", (0, 0, 0), (13.2, 6.2, .5), GREEN)
block(table, "PlaySurface", (0, -.05, .27), (12.65, 5.55, .08), (92, 196, 110), "smooth")
block(table, "FrontApron", (0, -2.72, -1.1), (12.8, .42, 1.65), DARK_WOOD)
block(table, "BackApron", (0, 2.72, -1.1), (12.8, .42, 1.65), DARK_WOOD)
for x in (-5.7, 5.7):
    for y in (-2.3, 2.3):
        block(table, "ChunkyLeg", (x, y, -1.35), (.95, .95, 2.7), WOOD)
        block(table, "Foot", (x, y, -2.82), (1.15, 1.15, .24), GOLD, "metal")
block(table, "FrontGoldBand", (0, -2.98, -.72), (12.2, .1, .17), GOLD, "metal")
block(table, "BackGoldBand", (0, 2.98, -.72), (12.2, .1, .17), GOLD, "metal")
for slot in range(3):
    x = (slot - 1) * 3.6
    block(table, "CasePadBorder", (x, 0, .37), (3.25, 2.5, .12), GOLD, "metal")
    block(table, "CasePad", (x, 0, .45), (3.0, 2.25, .08), (51, 120, 69), "smooth")
    for side in (-1, 1):
        block(table, "PadStud", (x + side * 1.28, 0, .53), (.12, .12, .08), PALE, "metal")
for x in (-5.8, 5.8):
    block(table, "MarqueePost", (x, 2.45, 1.3), (.38, .38, 2.3), BLUE)
block(table, "Marquee", (0, 2.45, 2.5), (12.0, .42, .48), BLUE)
block(table, "MarqueeFace", (0, 2.19, 2.5), (10.4, .1, .26), GOLD, "metal")
for x in (-4.8, -3.2, -1.6, 0, 1.6, 3.2, 4.8):
    block(table, "MarqueeBulb", (x, 2.10, 2.5), (.18, .12, .18), PALE, "neon")

# Reusable low-part-count game case. Its pivot is the centre of the body, with the lid and
# clasp separate so Roblox can animate the open/reveal beat. Dimensions match the Lua slots.
case = model("LuckyBriefcase", 18)
block(case, "Body", (0, 0, 0), (2.5, 1.8, 1.1), WOOD)
block(case, "LowerBand", (0, -.93, -.12), (2.58, .08, .18), DARK_WOOD)
block(case, "Lid", (0, 0, .65), (2.5, 1.8, .2), (122, 71, 41))
block(case, "Clasp", (0, -1.0, .2), (.42, .12, .3), GOLD, "metal")
block(case, "HandleBase", (-.42, 0, .78), (.18, .3, .16), GOLD, "metal")
block(case, "HandleBase", (.42, 0, .78), (.18, .3, .16), GOLD, "metal")
block(case, "Handle", (0, 0, .93), (1.05, .24, .14), DARK_WOOD)
block(case, "CornerCap", (-1.12, -.94, -.34), (.23, .08, .23), GOLD, "metal")
block(case, "CornerCap", (1.12, -.94, -.34), (.23, .08, .23), GOLD, "metal")

# Small visual mallet that swings on a click, authored in the same chunky brick palette.
mallet = model("GavelMallet", 0)
block(mallet, "Grip", (0, 0, 1.1), (.5, .5, 2.5), DARK_WOOD)
block(mallet, "GripEnd", (0, 0, -.18), (.7, .7, .22), GOLD, "metal")
block(mallet, "HeadCore", (0, 0, 2.5), (2.15, .85, .8), WOOD)
block(mallet, "HeadCap", (-1.15, 0, 2.5), (.3, 1.0, 1.0), GOLD, "metal")
block(mallet, "HeadCap", (1.15, 0, 2.5), (.3, 1.0, 1.0), GOLD, "metal")
for side in (-1, 1):
    block(mallet, "HeadStud", (side * .58, 0, 2.93), (.22, .22, .12), PALE, "metal")

# Key the gameplay prop actions in Blender so the shape, timing, and poses are reviewable here.
# The Roblox client replays the same snappy arcs around live, server-timed interactions.
mallet_root = MODEL_ROOTS["GavelMallet"]
for frame, angle in ((1, 0), (7, -58), (12, 10), (24, 0)):
    mallet_root.rotation_euler.x = math.radians(angle)
    mallet_root.keyframe_insert(data_path="rotation_euler", frame=frame, group="Bonk swing")
mallet_root["swing_degrees"] = 58
case_root = MODEL_ROOTS["LuckyBriefcase"]
lid_obj = next(o for o in case_root.children if o.name == "Lid")
for frame, angle in ((1, 0), (18, 0), (26, -68), (36, -68), (44, 0)):
    lid_obj.rotation_euler.x = math.radians(angle)
    lid_obj.keyframe_insert(data_path="rotation_euler", frame=frame, group="Prize reveal")
case_root["open_degrees"] = 68
for frame, x in ((1, 0), (45, 0), (60, 1.2), (75, 0)):
    case_root.location.x = x
    case_root.keyframe_insert(data_path="location", frame=frame, group="Shuffle hop")
sc.frame_start, sc.frame_end, sc.render.fps = 1, 75, 30

# Export each model as local parts in Roblox's axes. Keep the Blender scene alongside the
# JSON so the asset can be art-directed and its animations can be previewed in Blender.
BLENDER_TO_ROBLOX = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))


def parts_for(root):
    result = []
    for obj in root.children:
        loc = Vector(obj.location)
        rot = obj.rotation_euler.to_matrix()
        converted = BLENDER_TO_ROBLOX @ rot @ BLENDER_TO_ROBLOX.transposed()
        dims = Vector((abs(obj.scale.x), abs(obj.scale.y), abs(obj.scale.z)))
        result.append({
            "n": obj.name,
            "p": [round(loc.x, 4), round(loc.z, 4), round(-loc.y, 4)],
            "s": [round(dims.x, 4), round(dims.z, 4), round(dims.y, 4)],
            "r": [round(converted[i][j], 5) for i in range(3) for j in range(3)],
            "c": list(obj["rgb"]),
            "m": MAT[obj["surface"]],
        })
    return result

for root in MODEL_ROOTS.values():
    bpy.context.view_layer.update()
    MODEL_DATA["models"][root.name] = parts_for(root)
MODEL_DATA["animations"] = {
    "GavelMallet": {"swingDegrees": 58, "downSeconds": 0.10, "recoverSeconds": 0.20},
    "LuckyBriefcase": {"lidOpenDegrees": 68, "openSeconds": 0.20, "closeSeconds": 0.12, "shuffleLift": 0.85},
}

os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w", encoding="utf-8") as out:
    json.dump(MODEL_DATA, out, separators=(",", ":"))

# Open the Gavel scene in a clean, useful modelling view when run in Blender's UI.
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "OBJECT"
sc.display.shading.show_cavity = True
sc.display.shading.show_object_outline = True
sc.render.resolution_x, sc.render.resolution_y = 1200, 720
sc.render.filepath = os.path.join(ROOT, "art", "minigames", "MinigameKit.png")
os.makedirs(os.path.dirname(sc.render.filepath), exist_ok=True)
sc.world = sc.world or bpy.data.worlds.new("MinigameKitWorld")
cam_data = bpy.data.cameras.new("MinigameKitCamera")
cam = bpy.data.objects.new("MinigameKitCamera", cam_data)
sc.collection.objects.link(cam)
cam.location = (0, -42, 20)
target = (0, 0, 0.2)
direction = (target[0] - cam.location.x, target[1] - cam.location.y, target[2] - cam.location.z)
cam.rotation_euler = (Vector(direction).to_track_quat("-Z", "Y").to_euler())
cam_data.type = "ORTHO"
cam_data.ortho_scale = 64
sc.camera = cam
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_distance = 48
            area.spaces.active.region_3d.view_location = (0, 0, 0)
            area.spaces.active.shading.color_type = "OBJECT"
if bpy.context.window:
    bpy.context.window.scene = sc
sc.frame_set(45)
bpy.ops.render.render(write_still=True, scene=sc.name)
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print("Built Blender-authored minigame kit:", {name: len(parts) for name, parts in MODEL_DATA.items()})
