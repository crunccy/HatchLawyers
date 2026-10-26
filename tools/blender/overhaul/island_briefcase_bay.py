# tools/blender/overhaul/island_briefcase_bay.py - MAP MODEL OVERHAUL stage 5: BRIEFCASE BAY re-dressed (crnuch's calls
# 2026-10-24, CLAUDE.md "MODEL OVERHAUL"). crnuch's approved v2 bay (environment-redesign/briefcase_bay_v2/bbv2_build.py:
# terrain, cliffs, water, the skyline towers, paths, the spawn dock, the gameplay markers) runs UNCHANGED in the
# island_kit sandbox; its dressing goes to the overhaul kit and its landmarks are remade here, same spots + sizes:
#   the giant briefcase + the giant gavel (with plaques and flower beds), the welcome fountain (its splash points are
#   returned unchanged for the ambience), the lighthouse + keeper's cottage (returns the lantern; the night beam stays the
#   v2 one), the Bay Ferry, the sailboat, the BRIEFCASE BAY welcome arch, the Return Home (escape) arch portal.
#   Blender -b --factory-startup --python tools/blender/overhaul/island_briefcase_bay.py -- <out_dir> [only=<cam>,...]
import bpy, bmesh, math, os, sys, random
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import island_kit as IK
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text
import props as PR

ROOT = IK.ROOT
SCRIPT = os.path.join(ROOT, "briefcase_bay_v2", "bbv2_build.py")
sys.path.insert(0, os.path.dirname(SCRIPT))
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
ONLY = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
os.makedirs(OUT, exist_ok=True)
rng = random.Random(250)
TAU = math.tau
O.K.PAL.update({"leather": (150, 88, 46), "leather_dark": (104, 58, 30), "tag": (255, 236, 160), "plaque": (176, 120, 60),
                "cottage_wall": (246, 236, 214), "cottage_roof": (204, 70, 56)})


def F_at(m, x, y, z=0.0, rot=0.0, s=1.0):
    return IK.place(m, x, y, z, rot, s)


def hull(name, look, pts, z0, z1, taper=0.82):
    """A boat hull: an outline [(x, y)] at z1 tapering to `taper` of it at z0 (the keel), solid."""
    tmp = bmesh.new()
    top = [tmp.verts.new((x, y, z1)) for x, y in pts]
    bot = [tmp.verts.new((x * taper, y * taper * 0.8, z0)) for x, y in pts]
    tmp.faces.new(top)
    tmp.faces.new(list(reversed(bot)))
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        tmp.faces.new((bot[i], bot[j], top[j], top[i]))
    bmesh.ops.triangulate(tmp, faces=[f for f in tmp.faces if len(f.verts) > 4])
    for f in tmp.faces:
        f.smooth = False
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces[:])
    O._merge(name, look, tmp, Matrix.Identity(4))


# ================================================================== the monuments
def plinth(n, w, d, z0, look="limestone"):
    box(n + "_Plinth", "limestone_dark", (0, 0, z0 + 1.0), (w, d, 2.0), bevel=0.2)
    box(n + "_Plinth", look, (0, 0, z0 + 2.2), (w - 2, d - 1.4, 0.4), bevel=0.1)
    box(n + "_Gold", "gold", (0, 0, z0 + 1.95), (w + 0.1, d + 0.1, 0.18))


def giant_briefcase(m, veg, x, y, z0, rot, col):
    n = "BayBriefcase"
    with F_at(m, x, y, 0, rot):
        plinth(n, 22, 11, z0)
        zb, W, D, H = z0 + 2.4, 17.0, 6.0, 12.0
        box(n + "_Leather", "leather", (0, 0, zb + H / 2), (W, D, H), bevel=0.9, segs=3)
        box(n + "_Seam", "leather_dark", (0, 0, zb + H * 0.62), (W + 0.12, D + 0.12, 0.45), bevel=0.15)
        for zz in (1.1, H * 0.62 + 0.7, H - 1.1):  # stitching (on the flat face, clear of the rounded edges)
            for k in range(12):
                box(n + "_Stitch", "paper", (-W / 2 + 2.0 + k * (W - 4.0) / 11, -D / 2 - 0.01, zb + zz), (0.55, 0.1, 0.13))
        for sx in (-1, 1):  # gold corners, clasps
            for sz in (0, 1):
                box(n + "_Gold", "gold", (sx * (W / 2 - 0.85), 0, zb + 0.9 + sz * (H - 1.8)), (1.9, D + 0.3, 1.9), bevel=0.35, segs=2)
            box(n + "_Gold", "gold", (sx * 3.2, -D / 2 - 0.15, zb + H * 0.55), (1.6, 0.4, 1.6), bevel=0.2)
            box(n + "_Gold", "gold_dark", (sx * 3.2, -D / 2 - 0.36, zb + H * 0.55), (0.6, 0.06, 0.8), bevel=0.05)
        for k in range(3):  # papers peeking out of the lid seam
            box(n + "_Paper", "paper", (-4.5 + k * 3.6, -D / 2 - 0.12, zb + H * 0.62 + 0.25), (2.6, 0.08, 1.6), rot=(0, rng.uniform(-14, 14), 0))
        box(n + "_Seam", "leather_dark", (0, 0, zb + H + 0.25), (7.0, 1.6, 0.5), bevel=0.15)
        handle = [(3.0 * math.cos(math.radians(a)), 0, zb + H + 0.5 + 2.6 * math.sin(math.radians(a))) for a in range(0, 181, 15)]
        tube(n + "_Handle", "leather_dark", handle, 0.62, segs=10)
        for sx in (-1, 1):
            box(n + "_Gold", "gold", (sx * 3.0, 0, zb + H + 0.545), (1.1, 1.7, 0.9), bevel=0.15)  # (bevels 0.03 off the seam's: it sat on their diagonal)
        tube(n + "_String", "lighthouse_red", [(2.0, 0, zb + H + 2.8), (3.1, -1.0, zb + H - 0.4)], 0.07, segs=5)
        box(n + "_Tag", "tag", (3.2, -1.05, zb + H - 1.6), (1.8, 0.14, 2.4), rot=(0, 8, 0), bevel=0.12)
        box(n + "_Plaque", "plaque", (0, -5.55, z0 + 1.0), (6.0, 0.15, 1.4), bevel=0.06)
        text("BRIEFCASE BAY", "gold", (0, -5.66, z0 + 1.0), 0.62, extrude=0.02)
        for sx in (-1, 1):
            with at(sx * 14.5, 0, z0, rz=90, s=0.95):
                PR.flower_bed()


def giant_gavel(m, veg, x, y, z0, rot, col):
    n = "BayGavel"
    with F_at(m, x, y, 0, rot):
        plinth(n, 20, 12, z0)
        zb = z0 + 2.4
        with at(4, 0, zb):
            lathe(n + "_Wood", "court_wood", [(4.2, 0.0), (4.35, 0.1, True), (4.35, 1.7, True), (4.2, 1.8), (0.0, 1.8)], segs=40)
            cyl(n + "_Gold", "gold", (0, 0, 0.6), 4.42, 0.4, segs=40)
            zc = 1.8 + 2.4
            head = [(0.0, -4.5), (2.1, -4.5, True), (2.4, -4.2), (2.4, 4.2), (2.1, 4.5, True), (0.0, 4.5)]
            lathe(n + "_Wood", "court_wood", head, segs=28, c=(0, 0, zc), rot=(90, 0, 0))
            for sy in (-2.9, 2.9):
                cyl(n + "_Gold", "gold", (0, sy + 0.35, zc), 2.55, 0.7, segs=28, rot=(90, 0, 0))
        tube(n + "_Wood", "court_wood", [(3.4, 0, zb + 4.0), (-2.0, 0, zb + 2.6), (-9.0, 0, zb + 0.95)], [0.68, 0.66, 0.62], segs=14)
        sphere(n + "_Gold", "gold", (-9.6, 0, zb + 0.85), 0.9, sub=2)
        box(n + "_Plaque", "plaque", (0, -6.05, z0 + 1.0), (6.0, 0.15, 1.4), bevel=0.06)
        text("ORDER!", "gold", (0, -6.16, z0 + 1.0), 0.75, extrude=0.02)
        for sx in (-1, 1):
            with at(sx * 13.5, 0, z0, rz=90, s=0.95):
                PR.flower_bed()


O.K.PAL.setdefault("court_wood", (150, 92, 52))


def fountain(m, wat, foam, x, y, z):
    """The welcome fountain: a kerbed limestone basin, a two-tier pedestal, a gold briefcase spouting four arcs.
    Returns the arcs' landing points (unchanged, for the ambience's splashes)."""
    n = "BayFountain"
    with at(x, y, z):
        lathe(n + "_Stone", "limestone", [(10.2, 0.0), (10.2, 1.2, True), (10.6, 1.4), (10.6, 1.7, True), (9.6, 1.75), (9.0, 1.4, True),
                                          (9.0, 0.6, True), (0.0, 0.6)], segs=48)
        cyl(n + "_Water", "water", (0, 0, 0.6), 9.05, 0.4, segs=48)
        lathe(n + "_Foam", "white", [(8.4, 1.0), (8.95, 1.05), (8.95, 1.12), (8.4, 1.1)], segs=48)
        lathe(n + "_Stone", "limestone", [(2.6, 0.6), (2.4, 1.0), (2.2, 3.0), (3.6, 3.3), (4.6, 3.55), (4.7, 3.85, True), (4.2, 3.9),
                                          (4.0, 3.75, True), (0.0, 3.75)], segs=32)
        cyl(n + "_Water", "water", (0, 0, 3.6), 4.05, 0.25, segs=32)
        lathe(n + "_Stone", "limestone", [(1.3, 3.8), (1.15, 4.4), (1.05, 6.0), (1.45, 6.25, True), (0.0, 6.4)], segs=20)
        cyl(n + "_Gold", "gold", (0, 0, 5.0), 1.12, 0.25, segs=20)
        with at(0, 0, 6.3, rz=0, s=1.3):
            PR.briefcase(n, "gold", "gold_dark", (0, 0, 0.9), (0, 0, 0))
    lands = []
    for k in range(4):
        a = math.radians(45 + k * 90)
        ca, sa = math.cos(a), math.sin(a)
        pts = []
        for t in range(13):
            u = t / 12
            r = 1.4 + u * 5.8
            zz = z + 8.0 + 2.4 * 4 * u * (1 - u) * 1.0 - u * 7.0
            pts.append((x + ca * r, y + sa * r, zz))
        tube(n + "_Jet", "water_fall", pts, [0.32 - 0.12 * t / 12 for t in range(13)], segs=8)
        p3 = (x + ca * 7.2, y + sa * 7.2, z + 1.0)
        lathe(n + "_Foam", "white", [(0.4, 1.02), (0.95, 1.08), (1.1, 1.18), (0.8, 1.22), (0.5, 1.16)], segs=14, c=(p3[0], p3[1], z))
        lands.append([round(p3[0], 1), round(p3[1], 1), z + 1.0])
    return lands


# ================================================================== the harbour
def lighthouse(m, beam_m, x, y, z0, h, sea_deg):
    n = "BayLighthouse"
    with at(x, y, z0):
        lathe(n + "_Rock", "rock", [(7.6, -0.4), (7.4, 0.3), (6.8, 0.6, True), (0.0, 0.6)], segs=28)
        lathe(n + "_Base", "limestone", [(6.0, 0.6), (6.0, 2.4, True), (6.2, 2.5), (6.2, 2.7, True), (0.0, 2.7)], segs=32)
        r0, r1, zb = 4.2, 3.0, 2.7
        bands = 6
        for k in range(bands):
            za, zc = zb + (h - 2) * k / bands, zb + (h - 2) * (k + 1) / bands
            ra, rc = r0 + (r1 - r0) * k / bands, r0 + (r1 - r0) * (k + 1) / bands
            lathe(n + ("_Red" if k % 2 else "_White"), "lighthouse_red" if k % 2 else "lighthouse_white", [(ra, za), (rc, zc)], segs=28)
        zt = zb + h - 2
        for k in range(4):  # little windows climbing round the tower
            a = math.radians(-90 + k * 75)
            zz = zb + 4 + k * 5.2
            rr = r0 + (r1 - r0) * (zz - zb) / (h - 2) + 0.02
            with at(math.cos(a) * rr, math.sin(a) * rr, zz, rz=math.degrees(a) + 90):
                box(n + "_Frame", "lighthouse_white" if k % 2 else "lighthouse_red", (0, 0, 0.75), (1.3, 0.3, 1.8), bevel=0.06)
                box(n + "_Glass", "glass_blue", (0, -0.1, 0.75), (0.9, 0.2, 1.3))
        with at(0, -r0 + 0.1, zb):  # the door
            B.door(n + "Door", 0, 0, 2.2, 3.4, frame="lighthouse_red", leaf="wood_deep", panel="wood_warm", depth=0.3)
        lathe(n + "_Red", "lighthouse_red", [(3.2, zt), (4.6, zt + 0.1), (4.7, zt + 0.6, True), (0.0, zt + 0.6)], segs=32)
        for k in range(18):
            a = k / 18 * TAU
            cyl(n + "_Iron", "iron", (math.cos(a) * 4.35, math.sin(a) * 4.35, zt + 0.6), 0.08, 1.3, segs=6)
        tube(n + "_Iron", "iron", [(4.35 * math.cos(a / 24 * TAU), 4.35 * math.sin(a / 24 * TAU), zt + 1.9) for a in range(25)], 0.1, segs=5, cap=False)
        cyl(n + "_Glow", "beacon_glow", (0, 0, zt + 0.6), 2.3, 3.0, segs=20)
        for k in range(8):
            a = k / 8 * TAU
            box(n + "_Iron", "iron", (math.cos(a) * 2.35, math.sin(a) * 2.35, zt + 2.1), (0.22, 0.22, 3.06), rot=(0, 0, math.degrees(a)))  # (0.03 past the glow's ends)
        lathe(n + "_Red", "lighthouse_red", [(3.3, zt + 3.6), (3.0, zt + 4.3), (2.2, zt + 5.3), (1.0, zt + 6.0), (0.0, zt + 6.2)], segs=28)
        cyl(n + "_Red", "lighthouse_red", (0, 0, zt + 3.4), 3.3, 0.25, segs=28)
        sphere(n + "_Gold", "gold", (0, 0, zt + 6.45), 0.45, sub=2)
        cyl(n + "_Iron", "iron", (0, 0, zt + 6.8), 0.07, 1.6, segs=5)
        prism(n + "_Gold", "gold", [(0, 0), (1.3, 0.25), (0, 0.5)], 0.06, c=(0.05, 0, zt + 7.8))
    # the keeper's cottage
    a = math.radians(sea_deg + 140)
    hx, hy = x + math.cos(a) * 11.5, y + math.sin(a) * 11.5
    with at(hx, hy, z0, rz=sea_deg + 140 + 90):
        box(n + "_Cottage", "cottage_wall", (0, 0, 2.0), (8.0, 6.0, 4.4), bevel=0.15)
        box(n + "_Base", "limestone_dark", (0, 0, 0.3), (8.3, 6.3, 0.6), bevel=0.08)
        for sgn in (-1, 1):
            box(n + "_Roof", "cottage_roof", (0, sgn * 1.85, 5.2), (9.2, 4.4, 0.35), rot=(-sgn * 34, 0, 0), bevel=0.08)
        with at(0, 0, 0, rz=90):
            prism(n + "_Cottage", "cottage_wall", [(-3.0, 4.2), (3.0, 4.2), (0, 6.2)], 8.0)
        tube(n + "_Ridge", "lighthouse_red", [(-4.6, 0, 6.45), (4.6, 0, 6.45)], 0.18, segs=8)
        with at(0, -3.0, 0.2):
            B.door(n + "Cottage", 0, 0, 1.8, 3.0, frame="lighthouse_white", leaf="hull_blue", panel="speed_blue" if "speed_blue" in O.K.PAL else "hull_blue",
                   depth=0.3)
            for sx in (-2.6, 2.6):
                B.window(n + "Cottage", sx, 1.2, 1.4, 1.4, arch=False, shutters="hull_blue")
        box(n + "_Chimney", "limestone_dark", (2.4, 1.6, 6.4), (1.0, 1.0, 2.6), bevel=0.08)
    lz = z0 + 0.6 + h + 2.1
    sa = math.radians(sea_deg)
    for w, L, look in ((1.6, 46, "beam_light"), (3.4, 38, "beam_light")):  # (the v2 night beam, its own object)
        beam_m.beam((x, y, lz), (x + math.cos(sa) * L, y + math.sin(sa) * L, lz - 2.5), w, w, look)
    return (x, y, lz)


def ferry(m, x, y, z, rot, col):
    n = "BayFerry"
    L, W = 24.0, 8.6
    pts = [(-L / 2, -W / 2), (L / 2 - 5, -W / 2), (L / 2, -0.6), (L / 2, 0.6), (L / 2 - 5, W / 2), (-L / 2, W / 2)]
    with F_at(m, x, y, 0, rot):
        hull(n + "_Hull", "hull_white", pts, z - 1.8, z + 1.2)
        hull(n + "_Blue", "hull_blue", [(px * 1.006, py * 1.02) for px, py in pts], z + 0.25, z + 0.75, taper=1.0)
        hull(n + "_Red", "hull_red", [(px * 0.97, py * 0.93) for px, py in pts], z - 0.65, z - 0.3, taper=1.0)
        hull(n + "_Deck", "deck_wood", [(px * 0.95, py * 0.88) for px, py in pts], z + 1.2, z + 1.4, taper=1.0)
        for sgn in (-1, 1):
            tube(n + "_Rail", "white", [(-L / 2 + 1.0, sgn * (W / 2 - 0.55), z + 2.35), (L / 2 - 5.5, sgn * (W / 2 - 0.55), z + 2.35)], 0.08, segs=5)
            for k in range(10):
                cyl(n + "_Rail", "white", (-L / 2 + 1.0 + k * 1.8, sgn * (W / 2 - 0.55), z + 1.4), 0.07, 0.95, segs=5)
        box(n + "_Cabin", "hull_white", (-3, 0, z + 3.0), (10, 6.0, 3.2), bevel=0.35)
        for k in range(4):
            for sgn in (-1, 1):
                box(n + "_Glass", "glass_blue", (-6.6 + k * 2.4, sgn * 3.02, z + 3.1), (1.6, 0.1, 1.3), bevel=0.05)
        box(n + "_Glass", "glass_blue", (2.02, 0, z + 3.1), (0.1, 3.6, 1.3), bevel=0.05)
        box(n + "_Blue", "hull_blue", (-3, 0, z + 4.8), (10.6, 6.6, 0.4), bevel=0.12)
        box(n + "_Cabin", "hull_white", (-0.5, 0, z + 6.2), (3.6, 4.4, 2.4), bevel=0.3)
        box(n + "_Glass", "glass_blue", (1.32, 0, z + 6.4), (0.1, 3.4, 1.1), bevel=0.04)
        for sgn in (-1, 1):
            box(n + "_Bench", "deck_wood", (-5.5, sgn * 1.6, z + 5.25), (2.6, 0.6, 0.5), bevel=0.08)
            IK.lifebuoy(n + "Buoy", (-3, sgn * 3.2, z + 3.0), r=0.62, face=(0, sgn, 0))
        with at(-6.2, 0, z + 5.0):
            lathe(n + "_Funnel", "hull_red", [(1.15, 0.0), (1.1, 2.2), (1.2, 2.3, True)], segs=18)
            lathe(n + "_Funnel2", "iron", [(1.2, 2.3, True), (1.2, 3.0, True), (0.95, 3.0), (0.95, 2.6)], segs=18)
        cyl(n + "_Mast", "iron", (-L / 2 + 0.8, 0, z + 1.4), 0.1, 5.2, segs=6)
        poly(n + "_Flag", "hull_blue", [(-L / 2 + 0.7, 0, z + 6.5), (-L / 2 - 1.3, 0.25, z + 6.2), (-L / 2 - 1.1, 0.1, z + 5.4), (-L / 2 + 0.7, 0, z + 5.6)],
             thick=0.05)
        for sgn in (-1, 1):
            text("BAY FERRY", "hull_blue", (3.5, sgn * (W / 2 + 0.05), z - 0.05), 1.0, rot=(90, 0, 0 if sgn < 0 else 180), extrude=0.03)


def sailboat(m, x, y, z, rot):
    n = "BaySailboat"
    L, W = 9.0, 3.4
    pts = [(-L / 2, -W / 2), (L / 2 - 2, -W / 2), (L / 2, 0), (L / 2 - 2, W / 2), (-L / 2, W / 2)]
    with F_at(m, x, y, 0, rot):
        hull(n + "_Hull", "hull_white", pts, z - 0.8, z + 0.7)
        hull(n + "_Red", "lighthouse_red", [(px * 1.01, py * 1.04) for px, py in pts], z + 0.1, z + 0.35, taper=1.0)
        hull(n + "_Deck", "deck_wood", [(px * 0.92, py * 0.82) for px, py in pts], z + 0.7, z + 0.82, taper=1.0)
        cyl(n + "_Mast", "wood_deep", (0.6, 0, z + 0.8), 0.17, 10.4, segs=8)
        tube(n + "_Mast", "wood_deep", [(-3.6, 0, z + 1.7), (0.6, 0, z + 1.7)], 0.12, segs=6)
        def sail(pa, pb, pc, bulge):
            k = 6
            for i in range(k):
                for j in range(k - i):
                    def P(u, v):
                        p = Vector(pa) + (Vector(pb) - Vector(pa)) * u + (Vector(pc) - Vector(pa)) * v
                        w = 4 * u * v * (1 - u - v) * 3
                        return tuple(p + Vector((0, bulge * w, 0)))
                    a2, b2, c2 = P(i / k, j / k), P((i + 1) / k, j / k), P(i / k, (j + 1) / k)
                    poly(n + "_Sail", "sail", [a2, b2, c2], thick=0.04, smooth=True)
                    if j < k - i - 1:
                        poly(n + "_Sail", "sail", [b2, P((i + 1) / k, (j + 1) / k), c2], thick=0.04, smooth=True)
        sail((0.5, 0, z + 1.9), (0.5, 0, z + 10.8), (-3.5, 0, z + 1.9), 0.6)
        sail((0.75, 0, z + 9.0), (4.3, 0, z + 1.3), (0.75, 0, z + 1.4), 0.45)
        poly(n + "_Flag", "lighthouse_red", [(0.6, 0, z + 11.2), (1.8, 0.1, z + 10.95), (0.6, 0, z + 10.7)], thick=0.04)


# ================================================================== the arrival
def welcome_sign(m, x, y, z0, rot, col, span=16.0):
    n = "BayWelcome"
    with F_at(m, x, y, 0, rot):
        for sgn in (-1, 1):
            with at(sgn * span / 2, 0, z0):
                box(n + "_Pillar", "limestone_dark", (0, 0, 0.5), (3.0, 3.0, 1.0), bevel=0.15)
                box(n + "_Pillar", "limestone", (0, 0, 6.0), (2.4, 2.4, 10.0), bevel=0.2)
                for zz in (3.5, 7.0):
                    box(n + "_Pillar", "limestone_dark", (0, 0, zz), (2.55, 2.55, 0.3), bevel=0.05)
                box(n + "_Gold", "gold", (0, 0, 11.415), (2.9, 2.9, 0.83), bevel=0.15)  # (top 0.03 above the board frame's)
                sphere(n + "_Gold", "gold", (0, 0, 12.5), 0.9, sub=2)
                O.leafy("BayWelcomeIvy%d" % sgn, [((0.9 * sgn, -1.1, 1.6), 0.9), ((0.4 * sgn, -1.2, 3.0), 0.7), ((1.1 * sgn, -0.9, 0.7), 0.8)],
                        voxel=0.15, faces=300, lumpy=0.1, seed=sgn + 3)
        box(n + "_Board", "sign_wood", (0, 0, z0 + 9.7), (span + 2, 0.8, 3.4), bevel=0.15)
        box(n + "_Frame", "wood_deep", (0, 0, z0 + 7.9), (span + 2.6, 1.0, 0.4), bevel=0.08)
        box(n + "_Frame", "wood_deep", (0, 0, z0 + 11.6), (span + 2.6, 1.0, 0.4), bevel=0.08)
        for sx in (-1, 1):
            IK.lifebuoy(n + "Buoy", (sx * (span / 2 - 2.6), -0.6, z0 + 6.0), r=0.7)
            tube(n + "_Rope", "rope", [(sx * (span / 2 - 2.6), -0.5, z0 + 7.85), (sx * (span / 2 - 2.6), -0.55, z0 + 6.7)], 0.06, segs=5)
        text("BRIEFCASE BAY", "white", (0, -0.45, z0 + 9.7), 1.8, extrude=0.05)
        text("BRIEFCASE BAY", "white", (0, 0.45, z0 + 9.7), 1.8, rot=(90, 0, 180), extrude=0.05)


def crystal(name, look, c, h, lean=(0, 0)):
    """A six-sided crystal shard with a pointed tip."""
    with at(*c):
        cyl(name, look, (0, 0, 0), h * 0.16, h * 0.7, segs=6, rot=(lean[0], lean[1], 0), smooth=False, r_top=h * 0.18)
        M = O.xform((0, 0, 0), (lean[0], lean[1], 0)) @ Vector((0, 0, h * 0.7))
        cyl(name, look, tuple(M), h * 0.18, h * 0.3, segs=6, rot=(lean[0], lean[1], 0), smooth=False, r_top=0.0)


def escape_portal(m, veg, x, y, z, rot=0.0):
    """The Return Home (escape) arch: a limestone arch on buttress legs, gold trim on both faces, a purple vortex down
    to the paving (a level walk-in), glowing runes, a mossy flowered cap, a gold briefcase keystone with purple crystals,
    lamps + topiaries + flower beds at its feet, a purple glow on the paving."""
    n = "BayPortal"
    with F_at(m, x, y, 0, rot):
        with at(0, 0, z):
            W, Hs = 19.6, 22.4  # inner arch: 9.8 radius springing at 12.6
            B.ring(n + "_Stone", "limestone", B.opening(W, Hs, True, n=16, grow=3.2), B.opening(W, Hs, True, n=16), -1.9, 1.9)
            for fy in (-1.95, 1.95):
                B.ring(n + "_Gold", "gold", B.opening(W, Hs, True, n=16, grow=0.45), [(x, -0.03 if z <= 0 else z) for x, z in B.opening(W, Hs, True, n=16, grow=0.03)],
                       fy - 0.12, fy + 0.12)  # (0.03 off the stone's soffit + floor)
                B.ring(n + "_Gold", "gold", B.opening(W, Hs, True, n=16, grow=3.35), B.opening(W, Hs, True, n=16, grow=2.9), fy - 0.12, fy + 0.12)
            prism(n + "_Vortex", "vortex_glow", B.opening(W, Hs, True, n=16), 0.4)
            for r0, a0, a1 in ((4.6, 20, 200), (6.8, 200, 380), (3.4, 110, 290)):
                tube(n + "_Swirl", "portal_glow", [(r0 * math.cos(math.radians(a)), -0.3, 12.1 + r0 * math.sin(math.radians(a))) for a in range(a0, a1 + 1, 15)],
                     0.18, segs=6)
            cyl(n + "_Swirl", "portal_glow", (0, -0.25, 12.1), 2.4, 0.1, segs=24, rot=(90, 0, 0))
            for k in range(9):  # runes round the arch on both faces
                a = math.radians(-20 + 12 + k * (220 - 24) / 8)
                for fy in (-1.93, 1.93):
                    box(n + "_Rune", "portal_glow", (11.4 * math.cos(a), fy, 12.6 + 11.4 * math.sin(a)), (0.9, 0.16, 0.9), rot=(0, -math.degrees(a), 0),
                        bevel=0.08)
            for sgn in (-1, 1):  # buttress legs
                box(n + "_Leg", "limestone_dark", (sgn * 11.4, 0, 3.2), (5.6, 5.0, 6.4), bevel=0.4)
                box(n + "_Gold", "gold", (sgn * 11.4, 0, 6.7), (6.2, 5.6, 0.6), bevel=0.12)
                box(n + "_Leg", "limestone", (sgn * 15.6, 1.0, 1.7), (4.6, 5.4, 3.4), bevel=0.4)
                O.leafy("BayPortalMoss%d" % sgn, [((sgn * 15.6, 1.0, 3.6), 1.6), ((sgn * 14.8, 0.2, 3.4), 1.2)], look="moss", voxel=0.2, faces=260,
                        lumpy=0.12, seed=sgn + 11)
                for k in range(3):
                    crystal(n + "_Crystal", "crystal_purple", (sgn * (8.2 + k * 1.3), -4.0 - k * 0.8, 0), 2.4 + k * 0.8, lean=(10, sgn * 14))
                with at(sgn * 15.5, -6.0, 0, s=0.82):
                    PR.lamp()
            # the mossy cap with flowers over the arch's crown
            obs = O.leafy("BayPortalCap", [((math.cos(math.radians(a)) * 13.4, 0, 12.6 + math.sin(math.radians(a)) * 13.4), 1.5) for a in range(55, 130, 12)],
                          look="moss", voxel=0.22, faces=500, lumpy=0.14, seed=21)
            O.flowers_on(obs, "BayPortal_Flower", "flower_pink", "BayPortal_FlowerMid", "flower_yel",
                         [(math.cos(math.radians(a)) * 13.0, rng.uniform(-1.0, 1.0), 40) for a in range(60, 126, 9)], r=0.3)
            # the keystone: a gold briefcase with purple crystals
            with at(0, 0, 12.6 + 12.9, s=1.9):
                PR.briefcase(n, "gold", "gold_dark", (0, 0, 0.9), (0, 0, 0))
            for sgn in (-1, 1):
                crystal(n + "_Crystal", "crystal_purple", (sgn * 4.2, 0.4, 25.0), 3.2, lean=(0, sgn * 25))
            lathe(n + "_Glow", "portal_glow", [(9.5, 0.02), (11.5, 0.02), (11.5, 0.1), (9.5, 0.1)], segs=40, c=(0, 0, 0))
            for k, ly in enumerate((-14.5, -18.5)):
                box(n + "_Gold", "gold", (0, ly, 0.03), (12 - k * 3, 0.5, 0.1))
    with F_at(m, x, y, 0, rot):  # topiaries + flower beds at its feet
        for sgn in (-1, 1):
            with at(sgn * 18.5, -1.0, z):
                IK.topiary(O_NONE, 0, 0, 0, 0)
            with at(sgn * 16.5, 4.5, z, rz=sgn * 15 + 90, s=0.7):
                PR.flower_bed()


class _None:
    pass


O_NONE = _None()


# ================================================================== the mapping + run
def patch(g_modules):
    P, DT = g_modules["bbv2_parts"], g_modules["bbv2_detail"]
    OD, OP = P.OD, P.OP
    P.lamp_post = lambda m, x, y, z0, h=7.0: IK.lamp_post(m, x, y, z0, h)
    P.bench = lambda m, x, y, z0, rot: IK.bench(m, x, y, z0, rot)
    P.flower_tuft = lambda m, x, y, z, look=None: IK.flower_tuft(m, x, y, z, look)
    P.daisies = lambda m, x, y, z, n=None: IK.daisies(m, x, y, z, n)
    P.round_tree = lambda m, x, y, z0, s=1.0, blossom=False: IK.tree(m, x, y, z0, s, "blossom" if blossom else "oak")
    P.hedge_run = lambda m, x0, y0, x1, y1, z0, h=2.4, w=2.2: IK.hedge_run(m, x0, y0, x1, y1, z0, h, w)
    DT.park_tree = lambda m, x, y, z0, s=1.0, kind="oak": IK.tree(m, x, y, z0, s, kind)
    DT.topiary = lambda m, x, y, z0, rot=0.0: IK.topiary(m, x, y, z0, rot)
    DT.flower_bed = lambda m, veg, x, y, z0, sx, sy, rot: IK.flower_bed(m, veg, x, y, z0, sx, sy, rot)
    OD.bush = lambda m, x, y, z0, s=1.0, look=None: IK.bush(m, x, y, z0, s)
    OD.palm2 = lambda m, x, y, z0, style=None, h=None, lean=None: IK.tree(m, x, y, z0, (h or 10.0) / 10.0, "palm")
    OD.hibiscus = lambda m, x, y, z0, s=1.0: IK.flower_bush(m, x, y, z0, s * 0.8, "flower_red")
    OD.grass_clump = lambda m, x, y, z0, s=1.0: IK.grass_clump(m, x, y, z0, s)
    OP.fern_bush = lambda m, x, y, z0, s=1.0, *a, **k: IK.fern(m, x, y, z0, s)
    DT.bollard = lambda m, x, y, z: IK.bollard(m, x, y, z)
    DT.buoy = lambda m, x, y, z: IK.buoy(m, x, y, z)
    DT.lifebuoy_stand = lambda m, x, y, z, rot: IK.lifebuoy_stand(m, x, y, z, rot)
    DT.giant_briefcase2 = giant_briefcase
    DT.giant_gavel2 = giant_gavel
    DT.fountain = fountain
    DT.lighthouse2 = lighthouse
    DT.ferry2 = ferry
    DT.sailboat = sailboat
    P.welcome_sign = welcome_sign
    DT.escape_portal_bb = escape_portal


def main():
    import importlib
    mods = {nm: importlib.import_module(nm) for nm in ("bbv2_parts", "bbv2_detail")}
    patch(mods)
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT)
    O.finish()
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "BBV2", "Diagram", "Egg_Spot"))
    keys = IK.render_cams(g, OUT, "bay_", only=ONLY)
    IK.before_after(OUT, "bay_", keys, os.path.join(ROOT, "briefcase_bay_v2", "renders"), "bbv2_")


if __name__ == "__main__":
    main()
