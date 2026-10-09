"""Run inside Blender (blender-mcp): rebuilds the FirmKit collection + a FirmPreview layout.
exec(open("/Users/ryanchen/HatchLawyers/tools/build_firm.py").read())  then  export()  to write the FBX.
"""
import sys, importlib, math, bpy
sys.path.insert(0, "/Users/ryanchen/HatchLawyers/tools")
import firm_kit, firm_pieces
importlib.reload(firm_kit)
importlib.reload(firm_pieces)

MAX_TRIS = 19000


def build():
    kit = firm_kit.fresh_collection("FirmKit")
    prev = firm_kit.fresh_collection("FirmPreview")
    pieces = [fn() for fn in firm_pieces.PIECES]       # registers every swatch first
    mat = firm_kit.palette_material()                   # then paint the palette
    objs, report = {}, []
    for pc in pieces:
        o = pc.build(kit, mat)
        objs[o.name] = o
        tris = sum(len(f.vertices) - 2 for f in o.data.polygons)
        report.append(f"{o.name} {tris} tris" + ("  <-- TOO MANY" if tris > MAX_TRIS else ""))

    def inst(name, x, y, rotz=0.0):
        o = objs[name].copy()
        o.name = name + "_preview"
        o.location = (x, y, 0)
        o.rotation_euler = (0, 0, rotz)
        prev.objects.link(o)

    inst("Entrance", 0, 0)
    inst("WaitingRoom", 0, 0)
    seg = firm_pieces.SEG
    for s in range(4):
        y = 21 + s * seg
        inst("OfficeSegment", 0, y)
        inst("LawyerDesk", 15.5, y + seg / 2)
        inst("LawyerDesk", -15.5, y + seg / 2, math.pi)
    inst("ExpansionLock", 0, 21 + 4 * seg)
    inst("BackWall", 0, 21 + 5 * seg)
    # grass around it, at the plot level, so the raised floor reads in the preview
    g = bpy.data.objects.get("PreviewGrass")
    if not g:
        bpy.ops.mesh.primitive_plane_add(size=1)
        g = bpy.context.active_object
        g.name = "PreviewGrass"
        m = bpy.data.materials.get("PreviewGrass") or bpy.data.materials.new("PreviewGrass")
        m.diffuse_color = (0.25, 0.75, 0.1, 1)
        m.use_nodes = True
        next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs[0].default_value = (0.2, 0.72, 0.05, 1)
        g.data.materials.append(m)
    for c in g.users_collection:
        c.objects.unlink(g)
    prev.objects.link(g)
    g.scale = (64, 90, 1)
    g.location = (0, 30, -firm_pieces.FH - 0.01)
    kit.hide_viewport = True
    prev.hide_viewport = False
    return report


def export():
    kit = bpy.data.collections["FirmKit"]
    kit.hide_viewport = False
    path = firm_kit.export_kit("FirmKit", "LawFirmKit.fbx")
    kit.hide_viewport = True
    return path


print("\n".join(build()))
