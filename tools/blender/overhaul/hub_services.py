# tools/blender/overhaul/hub_services.py - MAP MODEL OVERHAUL stage 3: the hub island's UPGRADES building and EGG
# INCUBATOR landmark (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"). These two stay on the island when the hub
# switch is on (unlike the island's Shop / Mutation Machine look-alikes, which HubMap parks for the real Hub.* models),
# so they are remade here with the same footprints as environment-redesign/central_hub/hub_parts.py:
#   Upgrades: base slab 32 x 26 (y -11..15), building x +-14, y -6..14 (front y -6, door at x 0), Carry pedestal
#             (-14, -10), Speed pedestal (14, -10). The Carry / Speed counters (mr.robe's wiring) stand out front.
#   Egg Incubator: round base r 16, marble deck r 14.5 (top z 3), steps in front (y -19.2..-15), the egg on its cradle
#             at the centre, heat lamps x +-11.5, boiler at the back (0, 11.5), sign at (14.5, -13.5) turned -35.
# Local frame: origin = the piece's centre on the ground, front = -Y. One mesh per colour (<Piece>_<Part>); the
# Upgrades gear is its own mesh (Upgrades_Gear) so the game can spin it. Big flat tops: preview studs only.
#   Blender -b --factory-startup --python tools/blender/overhaul/hub_services.py -- <out_dir>
import bpy, math, os, sys, random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text
import props as PR

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
TAU = math.tau


def gear(p, look, c, r, teeth=12, depth=0.8, hub="iron", spokes=5):
    """A gear standing in the local XZ plane (facing -Y) at c: toothed rim, spokes, a hub with a gold cap."""
    with at(*c):
        outer, inner = [], []
        for k in range(teeth):
            a0, da = k / teeth * TAU, TAU / teeth
            for f, rr in ((0.0, 0.8), (0.16, 1.0), (0.5, 1.0), (0.66, 0.8)):
                a = a0 + f * da
                outer.append((r * rr * math.cos(a), r * rr * math.sin(a)))
                inner.append((r * 0.6 * math.cos(a), r * 0.6 * math.sin(a)))
        B.ring(p, look, outer, inner, -depth / 2, depth / 2)
        for k in range(spokes):
            a = k / spokes * TAU
            box(p, look, (r * 0.32 * math.cos(a), 0, r * 0.32 * math.sin(a)), (r * 0.58, depth * 0.7, r * 0.14), rot=(0, -math.degrees(a), 0))
        cyl(p + "Hub", hub, (0, depth * 0.7, 0), r * 0.26, depth * 1.4, segs=16, rot=(90, 0, 0))
        cyl(p, look, (0, -depth * 0.7, 0), r * 0.13, 0.2, segs=12, rot=(90, 0, 0))


# ================================================================== UPGRADES
def boot(p, c, rz=0.0, s=1.0):
    """A winged red sneaker-boot (Speed): white sole + toe cap, laces, a gold wing on each side."""
    with at(*c, rz=rz, s=s):
        box(p + "_Sole", "white", (0.2, 0, 0.22), (4.6, 2.1, 0.44), bevel=0.18, segs=2)
        box(p + "_Boot", "boot_red", (-0.4, 0, 1.15), (3.2, 2.0, 1.5), bevel=0.45, segs=3, smooth=True)
        sphere(p + "_Sole", "white", (1.55, 0, 0.75), 1.0, sub=2, scale=(1.15, 1.0, 0.7))
        box(p + "_Boot", "boot_red", (-1.1, 0, 2.5), (1.9, 1.85, 2.6), bevel=0.45, segs=3, smooth=True)
        box(p + "_Sole", "white", (-1.1, 0, 3.85), (2.05, 2.0, 0.42), bevel=0.15, segs=2)
        for k in range(4):  # laces
            box(p + "_Sole", "white", (-0.05 + k * 0.42, 0, 1.92 - k * 0.12), (0.16, 1.5, 0.14), rot=(0, -12, 0), bevel=0.05)
        for sg in (-1, 1):  # wings: three layered feathers
            for k, (ln, z) in enumerate(((2.6, 3.2), (2.1, 2.7), (1.6, 2.25))):
                pts = [(0, 0), (ln * 0.55, 0.32), (ln, 0.9 - k * 0.1), (ln * 0.7, 0.62), (0.1, 0.42)]
                prism(p + "_Wing", "gold", [(-0.8 - x, zz + z - 0.4) for x, zz in pts], 0.16, c=(0, sg * 1.06, 0), rot=(0, 0, 0))


def pedestal(p, x, y, label):
    with at(x, y):
        lathe(p + "_Pedestal", "marble", [(2.6, 0.0), (2.6, 0.45, True), (2.25, 0.62), (2.0, 0.85, True), (2.0, 2.3, True),
                                          (2.3, 2.45), (2.45, 2.75, True), (0.0, 2.75)], segs=28)
        cyl(p + "_Gold", "gold", (0, 0, 1.35), 2.05, 0.18, segs=28)
        box(p + "_Gold", "gold", (0, -2.02, 1.65), (2.0, 0.08, 0.55), bevel=0.02)
        text(label, "navy_dark", (0, -2.08, 1.65), 0.38, extrude=0.012)


def upgrades():
    n = "Upgrades"
    box(n + "_Base", "stone_mid", (0, 2, 0.4), (32, 26, 0.8), bevel=0.1)
    W, D, H = 28, 20, 16.0
    box(n + "_Wall", "stone_cool", (0, 4, 0.8 + H / 2), (W, D, H))
    box(n + "_Band", "stone_cool_dark", (0, 4, 1.5), (W + 0.3, D + 0.3, 1.4), bevel=0.06)
    box(n + "_Trim", "marble", (0, 4, 8.7), (W + 0.4, D + 0.4, 0.5), bevel=0.06)  # string course between the floors
    for (x, y, d) in ((-14, -6, (-1, -1)), (14, -6, (1, -1)), (-14, 14, (-1, 1)), (14, 14, (1, 1))):
        B.quoins(n, x, y, 2.2, 16.6, look="stone_cool_dark", dir=d)
    with at(0, -6):  # front: gold arched door, windows, the UPGRADES board
        B.door(n + "Door", 0, 0.8, 5.0, 8.0, frame="gold", leaf="navy_dark", panel="navy_roof")
        for x in (-9.5, 9.5):
            B.window(n + "Win", x, 2.8, 3.8, 4.2, arch=False, shutters="navy_roof")
            B.window(n + "Win", x, 10.2, 3.6, 4.6, arch=True)
        box(n + "_Board", "navy_dark", (0, -0.3, 11.0), (12.4, 0.5, 2.8), bevel=0.1)
        for z in (9.55, 12.45):
            box(n + "_Gold", "gold", (0, -0.36, z), (13.0, 0.62, 0.3), bevel=0.06)
        for x in (-6.35, 6.35):
            box(n + "_Gold", "gold", (x, -0.36, 11.0), (0.3, 0.62, 3.2), bevel=0.06)
            sphere(n + "_Gold", "gold", (x, -0.7, 11.0), 0.28, sub=1)
        text("UPGRADES", "gold", (0, -0.58, 11.0), 1.5, extrude=0.04)
    for s in (-1, 1):
        with at(s * 14, 4, rz=90 * s):
            for y in (-5, 5):
                B.window(n + "Win", y, 2.8, 3.2, 4.2, arch=False)
                B.window(n + "Win", y, 10.2, 3.2, 4.6, arch=True)
    with at(0, 14, rz=180):
        for x in (-8, 0, 8):
            B.window(n + "Win", x, 2.8, 3.2, 4.2, arch=False)
            B.window(n + "Win", x, 10.2, 3.2, 4.6, arch=True)
    B.cornice(n, 0, 4, 16.8, W, D, look="marble", trim="gold")
    B.hip_roof(n, "navy_roof", 0, 4, 17.95, W, D, 6.0, over=0.7)
    # front dormer carrying the big gold gear
    box(n + "_Dormer", "stone_cool", (0, -2.6, 19.9), (7.2, 7.0, 4.2))
    box(n + "_Trim", "marble", (0, -2.6, 22.1), (7.8, 7.6, 0.4), bevel=0.06)
    prism(n + "_DormerRoof", "navy_roof", [(-4.3, 0), (4.3, 0), (0, 2.5)], 7.8, c=(0, -2.5, 22.3))
    tube(n + "_Gold", "gold", [(0, -6.4, 24.85), (0, 1.4, 24.85)], 0.16, segs=8)
    sphere(n + "_Gold", "gold", (0, -6.45, 24.9), 0.32, sub=1)
    gear(n + "_Gear", "gold", (0, -6.35, 20.3), 2.7, teeth=12, depth=0.6)
    box(n + "_Chimney", "stone_cool_dark", (8.5, 9.0, 23.0), (2.2, 2.2, 6.0), bevel=0.06)
    box(n + "_Trim", "marble", (8.5, 9.0, 26.1), (2.7, 2.7, 0.35), bevel=0.06)
    # Carry + Speed pedestals, lamps, planters
    pedestal(n, -14, -10, "CARRY")
    with at(-14, -10, 2.75, rz=8, s=1.9):
        PR.briefcase(n, "brief_brown", "wood_deep", (0, 0, 0.9), (0, 0, 0))
    pedestal(n, 14, -10, "SPEED")
    boot(n + "Boot", (14, -10, 2.75), rz=-20, s=1.05)
    for s in (-1, 1):
        with at(s * 17.5, -6.5):
            PR.lamp()
        with at(s * 6.5, -8.5):
            PR.planter_round()
    B.studtop(n, "stone_mid", -16, 16, -11, 15, 0.8,
              skip=lambda x, y: (abs(x) < 14.4 and -6.4 < y < 14.4) or (abs(x) < 9 and y < -6.2 and abs(x) > 4.6)
              or (abs(abs(x) - 6.5) < 1.6 and abs(y + 8.5) < 1.6) or (abs(abs(x) - 17.5) < 1.2 and abs(y + 6.5) < 1.2)
              or (abs(abs(x) - 14) < 2.7 and y < -7.2))


# ================================================================== EGG INCUBATOR
def egg_profile(t, R=8.2, peak=0.4):
    if t < peak:
        u = (peak - t) / peak
        return R * math.sqrt(max(0.0, 1 - u * u))
    u = (t - peak) / (1 - peak)
    return R * math.sqrt(max(0.0, 1 - u ** 1.7))


def incubator():
    n = "Incubator"
    r = random.Random(5)
    lathe(n + "_Base", "stone_mid", [(16.0, 0.0), (16.0, 1.0, True), (15.4, 1.2, True), (0.0, 1.2)], segs=64)
    lathe(n + "_Deck", "marble", [(14.6, 1.2, True), (14.6, 2.75), (14.4, 3.0, True), (0.0, 3.0)], segs=64)
    lathe(n + "_Gold", "gold", [(14.62, 2.55), (14.9, 2.65), (14.9, 2.95), (14.62, 3.05)], segs=64)
    for k in range(3):  # steps in front
        y0 = -19.2 + 1.4 * k
        box(n + "_Deck", "marble", (0, (y0 - 13.8) / 2, (k + 1) * 0.5), (10, -13.8 - y0, (k + 1) * 1.0), bevel=0.05)
    for sx in (-5.6, 5.6):
        box(n + "_Base", "stone_mid", (sx, -16.4, 1.6), (1.2, 5.6, 3.2), bevel=0.08)
        sphere(n + "_Gold", "gold", (sx, -18.6, 3.55), 0.42, sub=2)
    # cradle: dark metal drum, rivets, the glowing heat ring
    lathe(n + "_Metal", "iron", [(9.4, 3.0), (9.4, 3.3, True), (9.0, 3.5), (8.8, 4.3, True), (8.0, 4.5), (0.0, 4.5)], segs=48)
    lathe(n + "_Heat", "orb_glow", [(9.45, 3.55), (9.8, 3.7), (9.8, 3.95), (9.45, 4.1)], segs=48)
    for k in range(24):
        a = k / 24 * TAU
        sphere(n + "_Gold", "gold", (math.cos(a) * 9.42, math.sin(a) * 9.42, 3.32), 0.16, sub=1)
    # the egg: one smooth shell, two coloured bands (a zigzag crack band + a gold band), spots
    ez, eh = 4.2, 22.0
    prof = [(egg_profile(i / 40), ez + eh * i / 40) for i in range(41)]
    prof[0] = (egg_profile(0.02), ez)
    lathe(n + "_Egg", "egg_shell", [(0.0, ez)] + prof[1:-1] + [(0.0, ez + eh)], segs=48)

    def band(look, t0, t1, zig=0.0, teeth=16):
        """A painted band round the shell: ONE closed smooth ring (out 0.09 above the shell, in 0.05 below it), its lower
        edge (and upper, mirrored) zigzagging when zig > 0."""
        import bmesh
        k = 96
        tmp = bmesh.new()
        rows = []
        for t, sgn in ((t0, 1), (t1, -1)):
            for off in (0.09, -0.05):
                row = []
                for i in range(k):
                    a = i / k * TAU
                    tri = 1 - abs(((i * teeth / k) % 1) * 2 - 1)  # 0..1..0 per tooth
                    tt = t + sgn * zig * (tri - 0.5) / eh
                    rr = egg_profile(tt) + off
                    row.append(tmp.verts.new((math.cos(a) * rr, math.sin(a) * rr, ez + tt * eh)))
                rows.append(row)
        lo_out, lo_in, hi_out, hi_in = rows
        for i in range(k):
            j = (i + 1) % k
            for f in ((lo_out[i], lo_out[j], hi_out[j], hi_out[i]), (hi_in[i], hi_in[j], lo_in[j], lo_in[i]),
                      (lo_in[i], lo_in[j], lo_out[j], lo_out[i]), (hi_out[i], hi_out[j], hi_in[j], hi_in[i])):
                tmp.faces.new(f).smooth = True
        O._merge(n + "_" + look.title().replace("_", ""), look, tmp, O.Matrix.Identity(4))
    band("egg_orange", 0.34, 0.42, zig=0.9, teeth=18)
    band("gold", 0.455, 0.48)
    band("egg_blue", 0.62, 0.66, zig=0.5, teeth=14)
    for k in range(22):
        t = r.uniform(0.12, 0.86)
        if 0.3 < t < 0.5 or 0.6 < t < 0.68:
            continue
        a = r.uniform(0, TAU)
        rr = egg_profile(t)
        nrm = Vector((math.cos(a), math.sin(a), (egg_profile(t - 0.01) - egg_profile(t + 0.01)) / (0.02 * eh))).normalized()
        c = Vector((math.cos(a) * rr, math.sin(a) * rr, ez + t * eh))
        lk = r.choice(["egg_orange", "egg_blue", "gold"])
        sz = r.uniform(0.7, 1.3)
        tmp_name = n + "_Spot" + lk.title().replace("_", "")
        import bmesh
        tmp = bmesh.new()
        bmesh.ops.create_icosphere(tmp, subdivisions=2, radius=1.0)
        for v in tmp.verts:
            v.co = Vector((v.co.x * sz, v.co.y * sz * 0.8, v.co.z * 0.22))
        for f in tmp.faces:
            f.smooth = True
        O._merge(tmp_name, lk, tmp, O.Matrix.Translation(c) @ nrm.to_track_quat("Z", "Y").to_matrix().to_4x4())
    # four gold claws hugging the egg, each holding a glowing orb
    for q in range(4):
        a = math.radians(45 + 90 * q)
        pts, rad = [], []
        for i in range(12):
            t = 0.02 + i / 11 * 0.6
            rr = egg_profile(t) + 0.55 + 0.25 * math.sin(i / 11 * math.pi)
            pts.append((math.cos(a) * rr, math.sin(a) * rr, ez + t * eh))
            rad.append(0.75 - 0.4 * i / 11)
        tube(n + "_Claw", "gold", pts, rad, segs=10)
        tip = Vector(pts[-1]) + Vector((math.cos(a), math.sin(a), 0)) * 0.9 + Vector((0, 0, 0.4))
        tube(n + "_Claw", "gold", [pts[-1], tuple(tip)], [0.35, 0.3], segs=8)
        lathe(n + "_Claw", "gold_dark", [(0.0, -0.3), (0.55, -0.2), (0.75, 0.15), (0.6, 0.3, True), (0.5, 0.2)], segs=14, c=tuple(tip))
        sphere(n + "_Orb", "orb_glow", tuple(tip + Vector((0, 0, 0.75))), 0.7, sub=2)
        for i in (3, 7):
            sphere(n + "_Gold", "gold_dark", pts[i], rad[i] * 1.18, sub=2)
    # two floating halo rings, clear of the claws / orbs / heat lamps / boiler by 0.5+ through a full turn (audit N3): one
    # round the egg's waist above the lamps' bowls, one round its crown above the orbs
    for cz, R, tilt in ((12.8, 10.4, 2.5), (21.3, egg_profile((21.3 - ez) / eh) + 2.15, -5)):
        ring_pts = []
        for i in range(49):
            a = i / 48 * TAU
            ring_pts.append((math.cos(a) * R, math.sin(a) * R, cz + math.sin(a) * math.tan(math.radians(tilt)) * R))
        tube(n + "_Halo", "halo_glow", ring_pts, 0.22, segs=8, cap=False)
    # heat lamps: gooseneck posts with red-glowing bowls aimed at the egg
    for s in (-1, 1):
        x = s * 11.5
        lathe(n + "_Metal", "iron", [(0.9, 3.0), (0.9, 3.4, True), (0.55, 3.6), (0.45, 4.0)], segs=12, c=(x, 4, 0))
        path = [(x, 4, 3.8), (x, 4, 10), (x, 4, 13.5), (x - s * 0.6, 4, 15.2), (x - s * 1.8, 4, 15.9), (x - s * 3.0, 4, 15.4)]
        tube(n + "_Metal", "iron", path, 0.32, segs=10)
        with at(x - s * 3.4, 4, 15.0):
            lathe(n + "_Lamp", "brass", [(0.35, 0.55), (1.0, 0.2), (1.55, -0.6), (1.65, -0.85, True), (0.0, -0.85)], segs=20)
            cyl(n + "_HeatGlow", "heat_glow", (0, 0, -0.95), 1.4, 0.15, segs=20)  # (top 0.05 up inside the bowl, clear of its rim plane)
    # boiler at the back: copper tank, brass bands, a pressure gauge, pipes into the cradle
    with at(0, 11.5, 3.0):
        lathe(n + "_Boiler", "copper", [(2.6, 0.0), (3.0, 0.3), (3.1, 1.0), (3.1, 6.0), (2.9, 6.8), (2.2, 7.4), (1.0, 7.75), (0.0, 7.8)],
              segs=28)
        for z in (1.2, 3.5, 5.8):
            cyl(n + "_Brass", "brass", (0, 0, z), 3.16, 0.28, segs=28)
        cyl(n + "_Brass", "brass", (0, 0, 7.6), 0.35, 1.0, segs=10)
        sphere(n + "_Brass", "brass", (0, 0, 8.8), 0.45, sub=1)
        with at(0, -3.1, 4.6):
            cyl(n + "_Brass", "brass", (0, 0.15, 0), 1.25, 0.35, segs=24, rot=(90, 0, 0))
            cyl(n + "_Dial", "white", (0, -0.2, 0), 1.0, 0.08, segs=24, rot=(90, 0, 0))
            box(n + "_Needle", "red", (0.32, -0.3, 0.22), (0.9, 0.05, 0.12), rot=(0, -35, 0))
            for k in range(7):
                a = math.radians(200 - k * 36.7)
                box(n + "_Needle", "iron", (0.78 * math.cos(a), -0.29, 0.78 * math.sin(a)), (0.2, 0.03, 0.06), rot=(0, -math.degrees(a), 0))
        for s in (-1, 1):
            tube(n + "_Brass", "brass", [(s * 2.8, -1.2, 1.2), (s * 3.8, -2.6, 1.0), (s * 4.6, -4.8, 0.9), (s * 5.4, -6.4, 1.0)], 0.32, segs=10)
            cyl(n + "_Brass", "brass", (s * 5.4, -6.4, 0.6), 0.5, 0.5, segs=10)
    with at(14.5, -13.5, rz=-35):
        PR.attraction_sign("EGG INCUBATOR")
    B.studtop(n, "marble", -14.5, 14.5, -14.5, 14.5, 3.0,
              skip=lambda x, y: math.hypot(x, y) > 14.1 or math.hypot(x, y) < 9.9 or (abs(x) > 10.3 and abs(y - 4) < 1.2)
              or math.hypot(x, y - 11.5) < 3.6 or (abs(abs(x) - 5.4) < 1.0 and abs(y - 5.1) < 2.0))


# ================================================================== renders
def old_version(fn_name, x0):
    sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "central_hub"))
    import hl_kit as K
    import hl_classic as CL
    import hub_parts as HP
    m = CL.ClassicMesh("Old_" + fn_name, bpy.context.scene.collection)
    getattr(HP, fn_name)(K.Frame(m, x0, 0, 0))
    m.done()


def main():
    O.reset()
    O.scene(sun_rot=(50, 8, -38))
    pieces = (("upgrades", upgrades, 0), ("incubator", incubator, 300))
    for name, fn, x0 in pieces:
        with O.region(name):
            with at(x0, 0):
                fn()
            box("Preview_Ground", "grass_ov", (x0, 0, -0.1), (240, 240, 0.2))
            O.player(x0 + 4, -16)
        with O.region(name + "_old"):
            try:
                old_version("upgrades" if name == "upgrades" else "egg_incubator", x0 + 1000)
            except Exception as e:
                print("[services] old", name, "skipped:", e)
            box("Preview_Ground", "grass_ov", (x0 + 1000, 0, -0.1), (240, 240, 0.2))
            O.player(x0 + 1004, -16)
    O.stats()
    O.render(OUT, "upgrades_three_quarter", (40, -50, 26), (0, 0, 9), lens=32, show=["upgrades"])
    O.render(OUT, "upgrades_front", (0, -46, 9), (0, 0, 10), lens=32, show=["upgrades"])
    O.render(OUT, "upgrades_pedestals", (-6, -24, 5.5), (2, -8, 4.5), lens=26, show=["upgrades"])
    O.render(OUT, "upgrades_before", (1040, -50, 26), (1000, 0, 9), lens=32, show=["upgrades_old"])
    O.render(OUT, "upgrades_after", (40, -50, 26), (0, 0, 9), lens=32, show=["upgrades"])
    O.render(OUT, "incubator_three_quarter", (342, -52, 30), (300, 0, 11), lens=32, show=["incubator"])
    O.render(OUT, "incubator_front", (300, -50, 10), (300, 0, 12), lens=30, show=["incubator"])
    O.render(OUT, "incubator_close", (290, -22, 9), (300, 0, 10), lens=26, show=["incubator"])
    O.render(OUT, "incubator_before", (1342, -52, 30), (1300, 0, 11), lens=32, show=["incubator_old"])
    O.render(OUT, "incubator_after", (342, -52, 30), (300, 0, 11), lens=32, show=["incubator"])


if __name__ == "__main__":  # (other overhaul scripts import these builders)
    main()
