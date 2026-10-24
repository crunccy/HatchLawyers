# tools/blender/overhaul/portal.py - MAP MODEL OVERHAUL, stage 1 benchmark: the hub's TRAVEL PORTAL as meshes
# (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"; references/models/ps99_castle_building + ps99_landmark: every
# edge trimmed, panelled shafts, base / shaft / capital pillars, neon edge strips, deep sockets). Same layout and the same
# looked-up names as the v2 portal (tools/blender/travel_portal.py) so StarterPlayerScripts.Travel keeps working:
#   SwirlDisc, SwirlCore (particles), SwirlArm* (-> the SwirlArms model, spun flat), Gem1-6 (lane order, lit per player),
#   FloatRing1-3_* (-> FloatRing1-3 models, turned + bobbed), Beam (breathes), HaloCore (flares), Sign* + SignPlate
#   ("TRAVEL", the hub's spinning sign), Trigger (walk-in box).
# One mesh per colour; studs only on the stage's walkable tops (structural) - glow, glass and gems stay smooth.
# 1 Blender m = 1 stud, Z up, FRONT faces -Y, stands on z = 0. Footprint ~30 x 30 like the v2 portal.
#   Blender -b --factory-startup --python tools/blender/overhaul/portal.py -- <out_dir> [--fbx]
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "kit"))
import hl_kit as K

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
FBX = "--fbx" in argv
os.makedirs(OUT, exist_ok=True)
TAU = math.tau

K.PAL.update({
    "stage_white": (244, 244, 250), "stage_shade": (206, 210, 226), "trim_gold": (255, 196, 46), "pad_dark": (34, 30, 62),
    "pylon_purple": (112, 70, 214), "pylon_deep": (70, 40, 150), "sign_black": (26, 24, 36), "bulb": (255, 236, 170),
    "avatar": (255, 210, 60), "grass": (124, 222, 52), "plaza": (236, 226, 204),
})
K.GLOWS.update({"neon_cyan": ((80, 220, 255), 3.0), "neon_pink": ((255, 90, 210), 2.6), "swirl": ((110, 235, 255), 2.2),
                "core": ((220, 250, 255), 4.0), "bulb_glow": ((255, 226, 150), 3.4)})
ZONE_GEMS = [(104, 152, 236), (120, 196, 50), (170, 80, 210), (240, 84, 74), (70, 160, 225), (120, 100, 230)]  # Config.Zones colours
for i, c in enumerate(ZONE_GEMS):
    K.GLOWS[f"gem{i + 1}"] = (c, 1.6)
MATTE = {"stage_white": 0.55, "stage_shade": 0.6, "pad_dark": 0.5, "pylon_purple": 0.5, "pylon_deep": 0.5, "sign_black": 0.6,
         "grass": 0.85, "plaza": 0.8, "avatar": 0.7}


def mat(look):
    m = K.mat(look)
    if look in MATTE:
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Roughness"].default_value = MATTE[look]
    return m


BMS = {}  # mesh name -> (bmesh, look)


def bm_for(name, look):
    if name not in BMS:
        BMS[name] = (bmesh.new(), look)
    return BMS[name][0]


# ------------------------------------------------------------------ primitives (into a named mesh)
def lathe(name, look, prof, segs=48, cx=0.0, cy=0.0):
    """Revolve a profile [(r, z)] (outside-in or bottom-up) around a vertical axis - tiers, rims, bevelled edges."""
    bm = bm_for(name, look)
    rings = [[bm.verts.new((cx + math.cos(k / segs * TAU) * r, cy + math.sin(k / segs * TAU) * r, z)) for k in range(segs)]
             for r, z in prof]
    for i in range(len(rings) - 1):
        for k in range(segs):
            j = (k + 1) % segs
            bm.faces.new((rings[i][k], rings[i][j], rings[i + 1][j], rings[i + 1][k]))
    return rings


def torus_v(name, look, centre, R, r, segs=48, tube=12, axis="y", sx=1.0):
    """A ring standing up (axis 'y' = facing front) - the halo rim, float rings lie flat with axis 'z'."""
    bm = bm_for(name, look)
    c = Vector(centre)
    rings = []
    for k in range(segs):
        a = k / segs * TAU
        ring = []
        for t in range(tube):
            b = t / tube * TAU
            rr = R + math.cos(b) * r * sx
            if axis == "y":
                p = Vector((math.cos(a) * rr, math.sin(b) * r, math.sin(a) * rr))
            else:
                p = Vector((math.cos(a) * rr, math.sin(a) * rr, math.sin(b) * r))
            ring.append(bm.verts.new(c + p))
        rings.append(ring)
    for k in range(segs):
        for t in range(tube):
            a, b = rings[k][t], rings[k][(t + 1) % tube]
            cc, d = rings[(k + 1) % segs][(t + 1) % tube], rings[(k + 1) % segs][t]
            bm.faces.new((a, d, cc, b))


def box(name, look, centre, size, bevel=0.0, rot=0.0):
    """A box with bevelled edges (bevel = edge size), rotated about Z."""
    bm = bm_for(name, look)
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0)
    for v in tmp.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    if bevel > 0:
        bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=bevel, segments=2, affect="EDGES", profile=0.5)
    M = Matrix.Translation(Vector(centre)) @ Matrix.Rotation(rot, 4, "Z")
    for v in tmp.verts:
        v.co = M @ v.co
    me = bpy.data.meshes.new("t")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def gem(name, look, centre, r, facets=8, axis_front=True):
    """A faceted crystal (double pyramid with a girdle) facing front."""
    bm = bm_for(name, look)
    c = Vector(centre)
    ring = []
    for k in range(facets):
        a = k / facets * TAU
        p = Vector((math.cos(a) * r, 0, math.sin(a) * r)) if axis_front else Vector((math.cos(a) * r, math.sin(a) * r, 0))
        ring.append(bm.verts.new(c + p))
    front = bm.verts.new(c + (Vector((0, -r * 0.9, 0)) if axis_front else Vector((0, 0, r * 1.4))))
    back = bm.verts.new(c + (Vector((0, r * 0.5, 0)) if axis_front else Vector((0, 0, -r * 0.8))))
    for k in range(facets):
        j = (k + 1) % facets
        bm.faces.new((ring[k], ring[j], front))
        bm.faces.new((ring[j], ring[k], back))


def studs_annulus(name, look, r0, r1, z, pitch=1.0, rad=0.32, h=0.22, segs=10):
    """Classic Roblox studs on the 1-stud grid inside a ring (the stage tiers' walkable tops)."""
    bm = bm_for(name, look)
    n = int(r1 / pitch) + 1
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x, y = (i + 0.5) * pitch, (j + 0.5) * pitch
            d = math.hypot(x, y)
            if r0 + 0.45 < d < r1 - 0.45:
                bot = [bm.verts.new((x + math.cos(k / segs * TAU) * rad, y + math.sin(k / segs * TAU) * rad, z)) for k in range(segs)]
                top = [bm.verts.new((x + math.cos(k / segs * TAU) * rad * 0.94, y + math.sin(k / segs * TAU) * rad * 0.94, z + h))
                       for k in range(segs)]
                for k in range(segs):
                    m = (k + 1) % segs
                    bm.faces.new((bot[k], bot[m], top[m], top[k]))
                bm.faces.new(top)


# ------------------------------------------------------------------ the portal
def stage():
    """Three round tiers: bevelled white bodies, a gold lip, a recessed neon channel, studded tops."""
    tiers = ((15.0, 0.0, 1.2), (12.4, 1.2, 1.0), (10.0, 2.2, 0.9))
    for k, (R, z0, h) in enumerate(tiers):
        z1 = z0 + h
        lathe("Stage_White", "stage_white", [(R - 0.3, z0), (R, z0 + 0.3), (R, z0 + h * 0.42), (R - 0.35, z0 + h * 0.42)])
        lathe("Stage_White", "stage_white", [(R - 0.35, z0 + h * 0.62), (R, z0 + h * 0.62), (R, z1 - 0.25), (R - 0.25, z1),
                                             (R - 2.4 if k < 2 else 0.0, z1)])
        lathe("Stage_Glow", "neon_cyan" if k != 1 else "neon_pink",
              [(R - 0.35, z0 + h * 0.42), (R - 0.12, z0 + h * 0.46), (R - 0.12, z0 + h * 0.58), (R - 0.35, z0 + h * 0.62)])
        lathe("Stage_Gold", "trim_gold", [(R + 0.05, z1 - 0.32), (R + 0.22, z1 - 0.2), (R + 0.22, z1 - 0.05), (R - 0.1, z1 + 0.04)])
        inner = tiers[k + 1][0] if k < 2 else 7.4
        studs_annulus("Stage_Studs", "stage_white", inner, R - 0.4, z1 + 0.04)  # classic studs: the surface's own colour
    # front steps up to the pad (they cut through the tier faces: the walk-in side)
    for i in range(4):  # each step 0.775 up, ending flush with the top tier (3.1)
        h = (i + 1) * 0.775
        box("Stage_White", "stage_white", (0, -15.6 + i * 1.5, h / 2), (6.4, 1.5, h), bevel=0.1)
        box("Stage_Gold", "trim_gold", (0, -16.35 + i * 1.5, h - 0.06), (6.5, 0.16, 0.12))
    # the pad: a dark recessed disc with glowing rings + the flat swirl
    z = 3.1
    lathe("Pad_Dark", "pad_dark", [(7.4, z + 0.05), (7.0, z - 0.2), (0.0, z - 0.2)])
    for r0, r1, look in ((6.6, 7.0, "neon_cyan"), (5.0, 5.3, "neon_pink"), (3.3, 3.55, "neon_cyan")):
        lathe("Pad_Rings", look, [(r1, z - 0.18), (r1, z - 0.05), (r0, z - 0.05), (r0, z - 0.18)])
    lathe("SwirlDisc", "swirl", [(2.9, z - 0.12), (0.0, z - 0.1)])
    lathe("SwirlCore", "core", [(0.9, z - 0.06), (0.6, z + 0.25), (0.0, z + 0.3)])
    for k in range(4):  # spiral arms lying flat on the pad (spun by the client)
        bm = bm_for(f"SwirlArm{k + 1}", "swirl")
        pts = 16
        prev = None
        for i in range(pts):
            t = i / (pts - 1)
            a = k / 4 * TAU + t * 3.4
            r = 0.9 + t * 5.4
            w = 0.5 * (1 - t) + 0.12
            p = Vector((math.cos(a) * r, math.sin(a) * r, z - 0.02))
            n = Vector((-math.sin(a), math.cos(a), 0))
            pair = (bm.verts.new(p + n * w), bm.verts.new(p - n * w))
            if prev:
                bm.faces.new((prev[0], prev[1], pair[1], pair[0]))
            prev = pair


def pylons():
    """Two pillars beside the pad: stepped plinth, panelled shaft with neon edge strips, gold-trimmed capital, crystal."""
    for side in (-1, 1):
        x = side * 9.0
        y = 1.0
        base_z = 3.1
        box("Pylon_Base", "stage_white", (x, y, base_z + 0.6), (4.4, 4.4, 1.2), bevel=0.25)
        box("Pylon_Gold", "trim_gold", (x, y, base_z + 1.3), (4.0, 4.0, 0.3), bevel=0.08)
        box("Pylon_Shaft", "pylon_purple", (x, y, base_z + 1.45 + 8.0), (3.2, 3.2, 16.0), bevel=0.3)
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):  # neon edge strips on the four corners
            box("Pylon_Glow", "neon_cyan", (x + dx * 1.55, y + dy * 1.55, base_z + 1.45 + 8.0), (0.28, 0.28, 15.2))
        for face, (nx, ny) in enumerate(((0, -1), (0, 1), (-1, 0), (1, 0))):  # recessed panels with a gold frame, 3 per face
            for k in range(3):
                pz = base_z + 4.2 + k * 4.6
                if nx == 0:
                    box("Pylon_Deep", "pylon_deep", (x, y + ny * 1.52, pz), (2.2, 0.2, 3.6), bevel=0.05)
                    box("Pylon_Gold", "trim_gold", (x, y + ny * 1.6, pz + 1.9), (2.4, 0.16, 0.18))
                else:
                    box("Pylon_Deep", "pylon_deep", (x + nx * 1.52, y, pz), (0.2, 2.2, 3.6), bevel=0.05)
                    box("Pylon_Gold", "trim_gold", (x + nx * 1.6, y, pz + 1.9), (0.16, 2.4, 0.18))
        for bz in (base_z + 1.45 + 5.6, base_z + 1.45 + 10.2):  # gold bands between the panels
            box("Pylon_Gold", "trim_gold", (x, y, bz + 0.5), (3.5, 3.5, 0.35), bevel=0.08)
        top = base_z + 1.45 + 16.0
        box("Pylon_Shaft", "pylon_purple", (x, y, top - 0.4), (3.8, 3.8, 0.8), bevel=0.25)  # the capital flares out
        box("Pylon_Gold", "trim_gold", (x, y, top + 0.3), (4.0, 4.0, 0.6), bevel=0.15)
        box("Pylon_Base", "stage_white", (x, y, top + 1.0), (3.4, 3.4, 0.8), bevel=0.2)
        gem("Pylon_Crystal", "neon_pink", (x, y, top + 2.6), 1.0, facets=6, axis_front=False)
    # the arms that hold the halo: gold-trimmed beams from each capital in to the halo rim
    for side in (-1, 1):
        box("Pylon_Shaft", "pylon_purple", (side * 7.4, 1.0, 20.0), (3.4, 1.6, 1.4), bevel=0.25)
        box("Pylon_Glow", "neon_cyan", (side * 7.4, 0.15, 20.0), (3.0, 0.2, 0.3))


def halo():
    """The floating emitter: a thick white rim with a gold inner lip, six gem sockets, concentric glowing rings, the core."""
    c = Vector((0, 1.0, 20.0))
    torus_v("Halo_Rim", "stage_white", c, 5.6, 1.1, segs=64, tube=14, axis="y", sx=1.0)
    torus_v("Halo_Gold", "trim_gold", c + Vector((0, -0.55, 0)), 4.45, 0.35, segs=64, tube=10, axis="y")
    torus_v("Halo_Gold", "trim_gold", c + Vector((0, -0.55, 0)), 6.75, 0.3, segs=64, tube=10, axis="y")
    for i in range(6):  # gems across the top half, in lane order left -> right
        a = math.radians(160 - i * 28)
        p = c + Vector((math.cos(a) * 5.6, -1.15, math.sin(a) * 5.6))
        torus_v("Halo_Gold", "trim_gold", p + Vector((0, 0.15, 0)), 0.75, 0.16, segs=20, tube=8, axis="y")
        gem(f"Gem{i + 1}", f"gem{i + 1}", p + Vector((0, -0.2, 0)), 0.62, facets=8)
    # the emitter face: concentric rings that glow downwards, the core in the middle
    for R, look in ((3.9, "neon_cyan"), (2.7, "neon_pink"), (1.6, "neon_cyan")):
        torus_v("Halo_Rings", look, c + Vector((0, 0.1, 0)), R, 0.22, segs=48, tube=8, axis="y")
    box("Halo_Back", "pad_dark", c + Vector((0, 0.6, 0)), (9.4, 0.4, 9.4), bevel=0.2)
    bm = bm_for("HaloCore", "core")
    g = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.9)
    for v in g["verts"]:
        v.co += c


def beam_and_rings():
    """The light column from the pad up to the halo, and three floating rings around it (turned + bobbed in game)."""
    lathe("Beam", "neon_cyan", [(2.6, 3.0), (2.6, 19.0), (0.0, 19.0)], segs=40)
    for k, (z, R) in enumerate(((7.0, 4.0), (10.8, 3.4), (14.4, 2.8))):
        name = f"FloatRing{k + 1}"
        torus_v(name + "_White", "stage_white", (0, 0, z), R, 0.32, segs=48, tube=10, axis="z")
        for i in range(8):  # glowing inserts + gold caps around the ring
            a = i / 8 * TAU + k * 0.3
            p = Vector((math.cos(a) * R, math.sin(a) * R, z))
            box(name + "_Glow", "neon_pink" if k == 1 else "neon_cyan", p, (0.9, 0.9, 0.25), bevel=0.1, rot=a)
            box(name + "_Gold", "trim_gold", p + Vector((0, 0, 0.3)), (0.5, 0.5, 0.2), bevel=0.06, rot=a)


def sign():
    """The TRAVEL sign over the portal: a black attraction board with a gold frame and bulbs (CLAUDE.md sign styles)."""
    z = 30.0  # clear of the halo's top (26.9)
    box("Sign_Board", "sign_black", (0, 2.0, z), (12.0, 0.8, 3.4), bevel=0.25)
    box("SignPlate", "sign_black", (0, 1.55, z), (11.0, 0.1, 2.6))
    for dz in (1.8, -1.8):
        box("Sign_Gold", "trim_gold", (0, 1.55, z + dz), (12.4, 1.0, 0.35), bevel=0.1)
    for dx in (6.2, -6.2):
        box("Sign_Gold", "trim_gold", (dx, 1.55, z), (0.35, 1.0, 3.9), bevel=0.1)
    for i in range(12):
        bm = bm_for("Sign_Bulbs", "bulb_glow")
        for dz in (1.8, -1.8):
            g = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.2)
            for v in g["verts"]:
                v.co += Vector((-5.5 + i, 1.0, z + dz))
    box("Sign_Post", "pylon_deep", (0, 2.0, 27.4), (0.8, 0.8, 1.8), bevel=0.15)  # the stem down to the halo
    K_font = K.font("bold")  # (Arial Black stands in for Gotham Black in the preview)
    t = K.label3d("TRAVEL", 0, 1.35, z, 2.2, look="trim_gold", rot=0, extrude=0.18, font=K_font)
    t.name = "Preview_TravelText"  # (in game the SurfaceGui on SignPlate says TRAVEL)


def trigger():
    box("Trigger", "pad_dark", (0, 0, 4.6), (12, 12, 3))


# ------------------------------------------------------------------ scene
def player(x, y, z=0.0):
    bm = bm_for("Preview_Player", "avatar")
    for (cx, cy, cz, sx, sy, sz) in ((0, 0, 4.4, 1.0, 1.0, 1.0), (0, 0, 2.9, 2.0, 1.0, 2.0), (-1.5, 0, 2.9, 1.0, 1.0, 2.0),
                                      (1.5, 0, 2.9, 1.0, 1.0, 2.0), (-0.5, 0, 0.95, 1.0, 1.0, 1.9), (0.5, 0, 0.95, 1.0, 1.0, 1.9)):
        g = bmesh.ops.create_cube(bm, size=1.0)
        for v in g["verts"]:
            v.co = Vector((v.co.x * sx + x + cx, v.co.y * sy + y + cy, v.co.z * sz + cz + z))


def build():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    sc = bpy.context.scene
    K.sky_and_sun(sc, sun_energy=3.6, sun_rot=(55, 6, -30))
    sc.collection.objects.link(bpy.data.objects["Sun"])
    stage(); pylons(); halo(); beam_and_rings(); sign(); trigger()
    player(-11, -19)
    gb = bm_for("Preview_Ground", "plaza")
    bmesh.ops.create_grid(gb, x_segments=1, y_segments=1, size=60)
    obs = {}
    for name, (bm, look) in BMS.items():
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        me.materials.append(mat(look))
        smooth = name.startswith(("Halo_Rim", "Halo_Gold", "Halo_Rings", "FloatRing", "Stage_White", "Stage_Gold", "Stage_Glow",
                                  "Pad", "Beam", "HaloCore", "SwirlCore"))
        for p in me.polygons:
            p.use_smooth = smooth
        ob = bpy.data.objects.new(name, me)
        sc.collection.objects.link(ob)
        obs[name] = ob
    obs["Trigger"].hide_render = True
    # the beam is see-through in game (Transparency); preview it as a soft glow
    bmat = obs["Beam"].data.materials[0] = K.mat("portal_field")
    return sc


def stats():
    tot = 0
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            t = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            tot += t
            print(f"{ob.name:20s} tris={t}")
    print("TOTAL tris", tot, "meshes", sum(1 for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Preview")))


def render(sc, name, loc, look, lens=30):
    sc.camera = K.camera(name, loc, look, lens=lens)
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.render.filepath = os.path.join(OUT, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


sc = build()
K.setup_eevee(sc, samples=48)
stats()
render(sc, "portal_front", (0, -60, 9), (0, 0, 15), lens=32)
render(sc, "portal_three_quarter", (-38, -38, 15), (0, 0, 13), lens=32)
render(sc, "portal_close", (13, -17, 7), (8, 1, 9), lens=30)
if FBX:
    bpy.ops.object.select_all(action="DESELECT")
    for ob in bpy.data.objects:
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            ob.select_set(True)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "TravelPortal.fbx"), use_selection=True, apply_unit_scale=True,
                             axis_forward="-Z", axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE")
