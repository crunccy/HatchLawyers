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
sys.path.insert(0, HERE)
import hl_kit as K

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
FBX = "--fbx" in argv
os.makedirs(OUT, exist_ok=True) if __name__ == "__main__" else None
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


def studs_annulus(name, look, r0, r1, z, pitch=1.0):
    """The game's standard studs (ohstuds: 0.10 tall, rounded square) on the 1-stud grid inside a ring."""
    import ohstuds
    bm = bm_for(name, look)
    n = int(r1 / pitch) + 1
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x, y = (i + 0.5) * pitch, (j + 0.5) * pitch
            if r0 + 0.45 < math.hypot(x, y) < r1 - 0.45:
                ohstuds.add_stud(bm, (x, y, z))


# ------------------------------------------------------------------ the portal (v2, crnuch 2026-10-24: "circular and
# symmetrical around so it looks the same from all sides": it stands in the middle of the hub plaza)
def to_world(cx, cy, ang, lx, ly):
    return (cx + lx * math.cos(ang) - ly * math.sin(ang), cy + lx * math.sin(ang) + ly * math.cos(ang))


def gem_radial(name, look, centre, r, out, facets=8):
    """A faceted crystal pointing outward along `out` (a horizontal direction)."""
    bm = bm_for(name, look)
    c, out = Vector(centre), Vector(out).normalized()
    side = Vector((-out.y, out.x, 0))
    ring = [bm.verts.new(c + (side * math.cos(k / facets * TAU) + Vector((0, 0, 1)) * math.sin(k / facets * TAU)) * r)
            for k in range(facets)]
    tip, back = bm.verts.new(c + out * r * 0.95), bm.verts.new(c - out * r * 0.5)
    for k in range(facets):
        j = (k + 1) % facets
        bm.faces.new((ring[k], ring[j], tip))
        bm.faces.new((ring[j], ring[k], back))


def arc(name, look, p0, p1, rise, r=0.28, n=12, segs=8):
    """A curved band from p0 to p1 bowing up by `rise` (the gold arches between the pillars)."""
    bm = bm_for(name, look)
    p0, p1 = Vector(p0), Vector(p1)
    pts = [p0.lerp(p1, t) + Vector((0, 0, rise * math.sin(t * math.pi))) for t in (i / (n - 1) for i in range(n))]
    rings, side = [], None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        side = side or d.cross(Vector((0, 0, 1))).normalized()
        side = (side - d * side.dot(d)).normalized()
        up = side.cross(d).normalized()
        rings.append([bm.verts.new(p + (side * math.cos(k / segs * TAU) + up * math.sin(k / segs * TAU)) * r) for k in range(segs)])
    for i in range(n - 1):
        for k in range(segs):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % segs], rings[i + 1][(k + 1) % segs], rings[i + 1][k]))


PAD_Z = 3.1
PILLAR_R = 9.6      # pillar ring radius
PILLAR_H = 13.0
CROWN_Z = PAD_Z + 1.45 + PILLAR_H + 1.2   # the crown ring sits on the pillar caps
N_PILLARS = 6


def stage():
    """Three round tiers: bevelled white bodies, a gold lip, a recessed neon channel, studded tops; steps on 4 sides."""
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
    for q in range(3):  # three matching stairways every 120 degrees, each landing in a gap between pillars
        ang = q * TAU / 3
        for i in range(4):  # each step 0.775 up, ending flush with the top tier (3.1)
            h = (i + 1) * 0.775
            x, y = to_world(0, 0, ang, 0, -15.6 + i * 1.5)
            box("Stage_White", "stage_white", (x, y, h / 2), (5.6, 1.5, h), bevel=0.1, rot=ang)
            x, y = to_world(0, 0, ang, 0, -16.35 + i * 1.5)
            box("Stage_Gold", "trim_gold", (x, y, h - 0.06), (5.7, 0.16, 0.12), rot=ang)
    # the pad: a dark recessed disc with glowing rings + the flat swirl
    z = PAD_Z
    lathe("Pad_Dark", "pad_dark", [(7.4, z + 0.05), (7.0, z - 0.2), (0.0, z - 0.2)])
    for r0, r1, look in ((6.6, 7.0, "neon_cyan"), (5.0, 5.3, "neon_pink"), (3.3, 3.55, "neon_cyan")):
        lathe("Pad_Rings", look, [(r1, z - 0.18), (r1, z - 0.05), (r0, z - 0.05), (r0, z - 0.18)])
    lathe("SwirlDisc", "swirl", [(2.9, z - 0.12), (0.0, z - 0.1)])
    lathe("SwirlCore", "core", [(0.9, z - 0.06), (0.6, z + 0.25), (0.0, z + 0.3)])
    for k in range(4):  # spiral arms lying flat on the pad (spun by the client)
        bm = bm_for(f"SwirlArm{k + 1}", "swirl")
        prev = None
        for i in range(16):
            t = i / 15
            a = k / 4 * TAU + t * 3.4
            r = 0.9 + t * 5.4
            w = 0.5 * (1 - t) + 0.12
            p = Vector((math.cos(a) * r, math.sin(a) * r, z - 0.02))
            nrm = Vector((-math.sin(a), math.cos(a), 0))
            pair = (bm.verts.new(p + nrm * w), bm.verts.new(p - nrm * w))
            if prev:
                bm.faces.new((prev[0], prev[1], pair[1], pair[0]))
            prev = pair


def pylons():
    """Six identical pillars on a ring, each turned to face outward: plinth, panelled shaft with neon edges and gold bands,
    a flared capital; gold arches join neighbours just under the crown."""
    base_z = PAD_Z
    for i in range(N_PILLARS):
        ang = i / N_PILLARS * TAU  # pillars at 0, 60, 120 ... degrees; the gaps (30, 90, ...) hold the stairways + the gems
        cx, cy = math.cos(ang) * PILLAR_R, math.sin(ang) * PILLAR_R
        face = ang + math.pi / 2  # local -y points outward
        def B(look_name, look, lx, ly, z, size, bevel=0.0):
            x, y = to_world(cx, cy, face, lx, ly)
            box(look_name, look, (x, y, z), size, bevel=bevel, rot=face)
        B("Pylon_Base", "stage_white", 0, 0, base_z + 0.6, (3.4, 3.4, 1.2), 0.22)
        B("Pylon_Gold", "trim_gold", 0, 0, base_z + 1.3, (3.1, 3.1, 0.3), 0.08)
        B("Pylon_Shaft", "pylon_purple", 0, 0, base_z + 1.45 + PILLAR_H / 2, (2.1, 2.1, PILLAR_H), 0.22)
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            B("Pylon_Glow", "neon_cyan", dx * 1.01, dy * 1.01, base_z + 1.45 + PILLAR_H / 2, (0.22, 0.22, PILLAR_H - 0.8))
        for k in range(3):  # recessed panels on all four faces (the pillar looks the same from any side too)
            pz = base_z + 3.6 + k * 4.0
            for lx, ly, sx, sy in ((0, -0.99, 1.35, 0.2), (0, 0.99, 1.35, 0.2), (-0.99, 0, 0.2, 1.35), (0.99, 0, 0.2, 1.35)):
                B("Pylon_Deep", "pylon_deep", lx, ly, pz, (sx, sy, 3.0), 0.05)
        for bz in (base_z + 1.45 + 4.4, base_z + 1.45 + 8.4):
            B("Pylon_Gold", "trim_gold", 0, 0, bz + 0.4, (2.4, 2.4, 0.3), 0.08)
        top = base_z + 1.45 + PILLAR_H
        B("Pylon_Shaft", "pylon_purple", 0, 0, top + 0.3, (3.0, 3.0, 0.6), 0.2)
        B("Pylon_Gold", "trim_gold", 0, 0, top + 0.75, (3.2, 3.2, 0.3), 0.1)
        gem_radial("Pylon_Crystal", "neon_pink", (cx, cy, CROWN_Z + 2.4), 0.8, (math.cos(ang), math.sin(ang), 0), facets=6)
    # gold arches between neighbouring pillars, just under the crown
    for i in range(N_PILLARS):
        a0, a1 = i / N_PILLARS * TAU, (i + 1) / N_PILLARS * TAU
        z = PAD_Z + 1.45 + PILLAR_H - 2.6
        arc("Arch_Gold", "trim_gold", (math.cos(a0) * PILLAR_R, math.sin(a0) * PILLAR_R, z),
            (math.cos(a1) * PILLAR_R, math.sin(a1) * PILLAR_R, z), 1.6, r=0.3)


def halo():
    """The crown: a flat white ring on the pillar caps with gold lips, the six zone gems round its outer edge (each facing
    out, in lane order), and the emitter underneath - concentric glowing rings + the core, shining down the beam."""
    z = CROWN_Z
    lathe("Halo_Rim", "stage_white", [(PILLAR_R - 2.2, z - 0.9), (PILLAR_R + 2.0, z - 0.9), (PILLAR_R + 2.4, z - 0.4),
                                       (PILLAR_R + 2.4, z + 0.5), (PILLAR_R + 2.0, z + 0.9), (PILLAR_R - 2.2, z + 0.9),
                                       (PILLAR_R - 2.5, z + 0.4), (PILLAR_R - 2.5, z - 0.4), (PILLAR_R - 2.2, z - 0.9)], segs=72)
    for zz, rr in ((z + 0.95, PILLAR_R + 2.15), (z - 0.95, PILLAR_R + 2.15), (z + 0.95, PILLAR_R - 2.3)):
        lathe("Halo_Gold", "trim_gold", [(rr + 0.2, zz - 0.12), (rr + 0.2, zz + 0.12), (rr - 0.2, zz + 0.12), (rr - 0.2, zz - 0.12),
                                          (rr + 0.2, zz - 0.12)], segs=72)
    for i in range(6):  # the gems sit between the pillars, each in a gold socket, facing out
        a = i / 6 * TAU - math.pi / 2  # over the six openings between pillars, starting at the front, in lane order
        out = Vector((math.cos(a), math.sin(a), 0))
        p = Vector((0, 0, z)) + out * (PILLAR_R + 2.45)
        bm = bm_for("Halo_Gold", "trim_gold")
        side = Vector((-out.y, out.x, 0))
        ring = []
        for k in range(16):  # the socket: a flat gold ring facing out
            b = k / 16 * TAU
            ring.append((bm.verts.new(p + (side * math.cos(b) + Vector((0, 0, 1)) * math.sin(b)) * 0.95),
                         bm.verts.new(p + (side * math.cos(b) + Vector((0, 0, 1)) * math.sin(b)) * 0.65 + out * 0.15)))
        for k in range(16):
            j = (k + 1) % 16
            bm.faces.new((ring[k][0], ring[j][0], ring[j][1], ring[k][1]))
        gem_radial(f"Gem{i + 1}", f"gem{i + 1}", p + out * 0.2, 0.6, out)
    # the emitter: a dark disc filling the ring, glowing rings facing down, the core
    lathe("Halo_Back", "pad_dark", [(PILLAR_R - 2.2, z - 0.3), (0.0, z - 0.3)], segs=48)
    # the crown's top: a shallow white dome with gold rings (seen from above as you walk up)
    lathe("Halo_Rim", "stage_white", [(PILLAR_R - 2.3, z + 0.85), (5.2, z + 1.5), (3.0, z + 2.0), (1.0, z + 2.2), (0.0, z + 2.22)], segs=64)
    for rr, zz in ((5.2, z + 1.52), (3.0, z + 2.02)):
        lathe("Halo_Gold", "trim_gold", [(rr + 0.25, zz - 0.06), (rr + 0.25, zz + 0.1), (rr - 0.25, zz + 0.1), (rr - 0.25, zz - 0.06)], segs=48)
    for R, look in ((6.2, "neon_cyan"), (4.6, "neon_pink"), (3.0, "neon_cyan")):
        lathe("Halo_Rings", look, [(R + 0.25, z - 0.32), (R + 0.25, z - 0.55), (R - 0.25, z - 0.55), (R - 0.25, z - 0.32)], segs=48)
    bm = bm_for("HaloCore", "core")
    g = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.1)
    for v in g["verts"]:
        v.co += Vector((0, 0, z - 1.2))


def beam_and_rings():
    """The light column from the pad up to the crown, and three floating rings around it (turned + bobbed in game)."""
    lathe("Beam", "neon_cyan", [(2.6, PAD_Z - 0.1), (2.6, CROWN_Z - 0.5), (0.0, CROWN_Z - 0.5)], segs=40)
    for k, (zf, R) in enumerate(((PAD_Z + 4.0, 4.4), (PAD_Z + 7.6, 3.8), (PAD_Z + 11.0, 3.2))):
        name = f"FloatRing{k + 1}"
        torus_v(name + "_White", "stage_white", (0, 0, zf), R, 0.32, segs=48, tube=10, axis="z")
        for i in range(8):
            a = i / 8 * TAU + k * 0.3
            p = Vector((math.cos(a) * R, math.sin(a) * R, zf))
            box(name + "_Glow", "neon_pink" if k == 1 else "neon_cyan", p, (0.9, 0.9, 0.25), bevel=0.1, rot=a)
            box(name + "_Gold", "trim_gold", p + Vector((0, 0, 0.3)), (0.5, 0.5, 0.2), bevel=0.06, rot=a)


def sign():
    """The TRAVEL sign on a stem above the crown's centre: a black attraction board with a gold frame and bulbs (it spins in
    game, text on both faces - so it reads from every side too)."""
    z = CROWN_Z + 6.2
    box("Sign_Post", "pylon_deep", (0, 0, CROWN_Z + 2.2), (0.9, 0.9, 4.4), bevel=0.15)
    lathe("Sign_Gold", "trim_gold", [(1.6, CROWN_Z + 2.0), (1.6, CROWN_Z + 2.6), (0.0, CROWN_Z + 2.6)], segs=24)
    box("Sign_Board", "sign_black", (0, 0, z), (12.0, 0.9, 3.4), bevel=0.25)
    for yy in (-0.5, 0.5):
        box("SignPlate" if yy < 0 else "Sign_PlateBack", "sign_black", (0, yy, z), (11.0, 0.1, 2.6))
    for dz in (1.8, -1.8):
        box("Sign_Gold", "trim_gold", (0, 0, z + dz), (12.4, 1.1, 0.35), bevel=0.1)
    for dx in (6.2, -6.2):
        box("Sign_Gold", "trim_gold", (dx, 0, z), (0.35, 1.1, 3.9), bevel=0.1)
    bm = bm_for("Sign_Bulbs", "bulb_glow")
    for i in range(12):
        for dz in (1.8, -1.8):
            for yy in (-0.6, 0.6):
                g = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.2)
                for v in g["verts"]:
                    v.co += Vector((-5.5 + i, yy, z + dz))
    K_font = K.font("bold")  # (Arial Black stands in for Gotham Black in the preview)
    for yy, rot in ((-0.6, 0), (0.6, 180)):
        t = K.label3d("TRAVEL", 0, yy, z, 2.2, look="trim_gold", rot=rot, extrude=0.18, font=K_font)
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
    player(-6, -21)
    gb = bm_for("Preview_Ground", "plaza")
    bmesh.ops.create_grid(gb, x_segments=1, y_segments=1, size=60)
    make_objects()
    return sc


def make_objects():
    """The portal's meshes as objects at the origin (no scene reset) - the island scripts place it with its matrix."""
    sc = bpy.context.scene
    stage(); pylons(); halo(); beam_and_rings(); sign(); trigger()
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
    BMS.clear()
    return [o for o in obs.values() if not o.name.startswith("Preview")]


def stats():
    tot = 0
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        if ob.type == "MESH" and not ob.name.startswith("Preview"):
            t = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            tot += t
            print(f"{ob.name:20s} tris={t}")
    print("TOTAL tris", tot, "meshes", sum(1 for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("Preview")))


def render(sc, name, loc, look, lens=30):
    import gagstuds
    gagstuds.apply_all()  # (Grow a Garden studs on every face)
    sc.camera = K.camera(name, loc, look, lens=lens)
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.render.filepath = os.path.join(OUT, name + ".jpg")
    bpy.ops.render.render(write_still=True)
    print("rendered", sc.render.filepath)


if __name__ == "__main__":  # (the island scripts import make_objects)
    sc = build()
    K.setup_eevee(sc, samples=48)
    stats()
    render(sc, "portal_front", (0, -62, 9), (0, 0, 15), lens=32)
    render(sc, "portal_three_quarter", (-42, -42, 16), (0, 0, 14), lens=32)
    render(sc, "portal_side", (60, 12, 9), (0, 0, 15), lens=32)
    render(sc, "portal_above", (-30, -40, 48), (0, 0, 10), lens=32)
    render(sc, "portal_studs", (-9, -20, 4.5), (-6, -11, 2), lens=30)
    if FBX:
        bpy.ops.object.select_all(action="DESELECT")
        for ob in bpy.data.objects:
            if ob.type == "MESH" and not ob.name.startswith("Preview"):
                ob.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "TravelPortal.fbx"), use_selection=True, apply_unit_scale=True,
                                 axis_forward="-Z", axis_up="Y", object_types={"MESH"}, mesh_smooth_type="FACE")
