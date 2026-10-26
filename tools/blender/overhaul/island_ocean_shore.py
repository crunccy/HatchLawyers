# tools/blender/overhaul/island_ocean_shore.py - MAP MODEL OVERHAUL stage 5: OCEAN SHORE re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). crnuch's APPROVED benchmark (environment-redesign/ocean_shore_v2/osv2_build.py: the sand,
# cliffs, rock arches, lagoons, waterfalls, spawn dock, egg regions) runs UNCHANGED in the island_kit sandbox; its natural +
# seafaring details are remade here at the same spots + sizes:
#   branching / fan / brain / tube corals, seaweed, scallop shells, starfish, conches, sand dollars, pebbles, driftwood
#   and the shipwreck (keel, ribs - some snapped - planks with gaps, a broken deck, a tilted mast with a crow's nest and a
#   torn sail, ropes, spilled cargo); palms / bushes / hibiscus / ferns / grass / torches / cargo / the Return Home rock
#   portal come from island_kit. Every model passes check_models.py (nothing floats; corals, starfish + conches are fused).
#   Blender -b --factory-startup --python tools/blender/overhaul/island_ocean_shore.py -- <out_dir>
import bpy, math, os, sys, random, importlib
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import island_kit as IK
import ohkit as O
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly

ROOT = IK.ROOT
SCRIPT = os.path.join(ROOT, "ocean_shore_v2", "osv2_build.py")
sys.path.insert(0, os.path.dirname(SCRIPT))
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
rr = random.Random(1907)
TAU = math.tau
for k_, v_ in {"coral_pink": (250, 110, 150), "coral_orange": (255, 140, 70), "coral_purple": (170, 100, 220), "coral_red": (232, 72, 72),
               "shell": (252, 236, 220), "shell_pink": (250, 190, 190), "starfish": (250, 120, 60), "starfish_red": (232, 70, 60),
               "driftwood": (176, 150, 116), "driftwood_dark": (130, 108, 82), "dock_wood": (176, 112, 62), "dock_wood_dark": (128, 80, 44),
               "hull_wood": (110, 74, 44), "pebble": (180, 176, 168), "seaweed": (56, 140, 82), "sail": (240, 232, 210), "rope": (196, 170, 120),
               "brain_coral": (240, 150, 100), "tube_coral": (110, 196, 220), "tube_coral_in": (60, 120, 160), "conch": (250, 204, 172),
               "conch_in": (250, 150, 150), "sand_dollar": (236, 220, 196)}.items():
    O.K.PAL.setdefault(k_, v_)
CNT = IK.CNT


def L(look):
    return look.title().replace("_", "")


# ================================================================== the sea's details
def coral(m, x, y, z0, s=1.0, look=None):
    """A branching coral: a stub forking into arms with round tips - fused into one smooth piece."""
    look = look or rr.choice(("coral_pink", "coral_orange", "coral_purple", "coral_red"))
    nm = "OceanCoral%d" % next(CNT)
    with IK.place(m, x, y, z0):
        sphere(nm, look, (0, 0, 0.2 * s), 0.6 * s, sub=2)
        for k in range(rr.randint(3, 5)):
            a = rr.uniform(0, TAU)
            el = rr.uniform(0.9, 1.4) * s
            p1 = (math.cos(a) * 0.6 * el, math.sin(a) * 0.6 * el, 1.4 * el)
            tube(nm, look, [(0, 0, 0.1), p1], [0.42 * s, 0.36 * s], segs=8)
            for j in (-1, 1):
                b = a + j * 0.6
                p2 = (p1[0] + math.cos(b) * 0.7 * el, p1[1] + math.sin(b) * 0.7 * el, p1[2] + 1.0 * el)
                tube(nm, look, [p1, p2], [0.34 * s, 0.28 * s], segs=8)
                sphere(nm, look, p2, 0.36 * s, sub=1)
        O.fuse(nm, voxel=0.08 * max(1.0, s), smooth_iters=2, faces=900)


def fan_coral(m, x, y, z0, s=1.0, look="coral_purple", rot=None):
    rot = rr.uniform(0, 180) if rot is None else rot
    nm = "OceanFan%d" % next(CNT)
    with IK.place(m, x, y, z0, rot, s):
        fan = [(1.7 * math.cos(math.radians(a)) * (1 + 0.06 * math.sin(a * 0.3)), 1.0 + 1.7 * math.sin(math.radians(a))) for a in range(0, 181, 12)]
        prism(nm, look, [(0.2, 0.6), *fan[1:-1], (-0.2, 0.6)], 0.14)
        for a in range(15, 170, 22):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            tube(nm, look, [(0, 0, 0.7), (1.6 * ca, -0.06, 1.0 + 1.6 * sa)], [0.12, 0.06], segs=5)
        tube(nm, look, [(0, 0, 0.0), (0, 0, 0.9)], [0.28, 0.2], segs=8)
        O.fuse(nm, voxel=0.06 * s, smooth_iters=1, faces=900)


def brain_coral(m, x, y, z0, r=1.6, look="brain_coral"):
    nm = "OceanBrain%d" % next(CNT)
    with IK.place(m, x, y, z0):
        sphere(nm, look, (0, 0, r * 0.4), r, sub=3, scale=(1, 1, 0.75))
        for k in range(3):  # wavy grooves, sunk into the dome
            rad = r * (0.35 + 0.22 * k)
            zz = r * 0.4 + r * 0.75 * math.sqrt(max(0.0, 1 - (rad / r) ** 2)) - 0.04
            pts = [((rad + 0.08 * math.sin(i * 1.3)) * math.cos(i / 24 * TAU), (rad + 0.08 * math.sin(i * 1.3)) * math.sin(i / 24 * TAU), zz) for i in range(25)]
            tube(nm + "_Groove", "coral_red", pts, 0.08, segs=5, cap=False)


def tube_coral(m, x, y, z0, s=1.0):
    with IK.place(m, x, y, z0):
        for k in range(rr.randint(4, 7)):
            a = rr.uniform(0, TAU)
            rad = rr.uniform(0.2, 1.1) * s
            h = rr.uniform(1.0, 2.6) * s
            c = (math.cos(a) * rad, math.sin(a) * rad, 0)
            lathe("OceanTube_Coral", "tube_coral", [(0.36 * s, 0.0), (0.34 * s, h), (0.38 * s, h + 0.08, True), (0.24 * s, h + 0.08), (0.24 * s, h - 0.3, True),
                                                   (0.0, h - 0.3)], segs=10, c=c)
            cyl("OceanTube_In", "tube_coral_in", (c[0], c[1], h - 0.32), 0.25 * s, 0.05, segs=10)  # (0.03 above the tube's floor)


def seaweed(m, x, y, z0, h=3.0):
    with IK.place(m, x, y, z0, rr.uniform(0, 360)):
        for k in range(3):
            a = k / 3 * TAU + rr.uniform(-0.3, 0.3)
            base = Vector((math.cos(a) * 0.25, math.sin(a) * 0.25, -0.1))
            prev = None
            for i in range(9):
                t = i / 8
                p = base + Vector((0.35 * math.sin(t * 6 + k), 0.2 * math.cos(t * 5 + k), t * h * rr.uniform(0.9, 1.05)))
                w = 0.32 * (1 - t * 0.6)
                side = Vector((-math.sin(a), math.cos(a), 0)) * w
                if prev:
                    poly("OceanSeaweed", "seaweed", [prev[0] - prev[1], prev[0] + prev[1], p + side, p - side], thick=0.05, smooth=True)
                prev = (p, side)


def shell(m, x, y, z0, s=1.0):
    look = rr.choice(("shell", "shell_pink"))
    nm = "OceanShell%d" % next(CNT)
    with IK.place(m, x, y, z0, rr.uniform(0, 360), s):
        k = 9
        for i in range(k):  # a scallop: ribbed fan segments rising from the hinge
            a0, a1 = math.radians(20 + 140 * i / k), math.radians(20 + 140 * (i + 1) / k)
            am = (a0 + a1) / 2
            poly(nm, look, [(0, -0.35, 0.08), (0.95 * math.cos(a0), -0.35 + 0.95 * math.sin(a0), 0.18), (1.0 * math.cos(am), -0.35 + 1.0 * math.sin(am), 0.32),
                            (0.95 * math.cos(a1), -0.35 + 0.95 * math.sin(a1), 0.18)], thick=0.1)
        box(nm, look, (0, -0.4, 0.08), (0.7, 0.25, 0.16), bevel=0.05)
        O.fuse(nm, voxel=0.04, smooth_iters=1, faces=500)


def starfish(m, x, y, z0, s=1.0):
    look = rr.choice(("starfish", "starfish_red"))
    nm = "OceanStar%d" % next(CNT)
    with IK.place(m, x, y, z0, rr.uniform(0, 72), s):
        sphere(nm, look, (0, 0, 0.12), 0.38, sub=2, scale=(1, 1, 0.45))
        for k in range(5):
            a = k / 5 * TAU
            tube(nm, look, [(0, 0, 0.12), (math.cos(a) * 0.55, math.sin(a) * 0.55, 0.12), (math.cos(a + 0.12) * 1.0, math.sin(a + 0.12) * 1.0, 0.08)],
                 [0.24, 0.17, 0.06], segs=6)
        O.fuse(nm, voxel=0.04, smooth_iters=2, faces=500)


def conch(m, x, y, z0, s=1.0, yaw=None):
    yaw = rr.uniform(0, 360) if yaw is None else yaw
    nm = "OceanConch%d" % next(CNT)
    with IK.place(m, x, y, z0, yaw, s):
        pts, rad = [], []
        for i in range(16):  # a conical spiral of shrinking whorls
            t = i / 15
            ang = t * 2.4 * TAU
            rr_ = 0.55 * (1 - t * 0.8)
            pts.append((t * 1.6, rr_ * math.cos(ang), 0.5 + rr_ * math.sin(ang) * 0.8 + t * 0.2))
            rad.append(0.42 * (1 - t * 0.75))
        tube(nm, "conch", pts, rad, segs=10)
        sphere(nm, "conch", (0.0, 0.0, 0.45), 0.55, sub=2, scale=(1.2, 1, 0.8))
        O.fuse(nm, voxel=0.05, smooth_iters=2, faces=700)
        cyl("OceanConch_In", "conch_in", (-0.55, 0, 0.45), 0.32, 0.12, segs=12, rot=(0, -90, 0))


def sand_dollar(m, x, y, z0):
    with IK.place(m, x, y, z0):
        lathe("OceanDollar", "sand_dollar", [(0.0, 0.0), (0.72, 0.0), (0.75, 0.05), (0.7, 0.1), (0.0, 0.14)], segs=16)
        for k in range(5):
            a = k / 5 * TAU
            tube("OceanDollar_Petal", "shell_pink", [(math.cos(a) * 0.15, math.sin(a) * 0.15, 0.13), (math.cos(a) * 0.45, math.sin(a) * 0.45, 0.11)], 0.05, segs=4)


def pebbles(m, x, y, z0, n=4):
    wx, wy, wz, _ = IK.where(m, x, y, 0.0, z0)
    with at(wx, wy, wz):
        for k in range(n):
            s = rr.uniform(0.5, 1.2)
            O.rock("OceanPebble", "OceanPebbleTop", (rr.uniform(-1.6, 1.6), rr.uniform(-1.6, 1.6), 0.0), s * 0.5, seed=next(CNT), squash=0.55, look="pebble",
                   top="rock_top")


def _seg_dist(x, y, a, b):
    ax, ay, bx, by = a[0], a[1], b[0], b[1]
    t = max(0.0, min(1.0, ((x - ax) * (bx - ax) + (y - ay) * (by - ay)) / max(1e-6, (bx - ax) ** 2 + (by - ay) ** 2)))
    return math.hypot(x - ax - t * (bx - ax), y - ay - t * (by - ay))


def clear_of_approach(x, y, reach=0.0):
    """Audit N10: no driftwood within 25 studs of the Return Home portal + its stepping-stone approach (30 out front), the
    arrival dock's landing and pad, or within 6 of the walk from the landing to the portal (+ reach, the log's half-length)."""
    P, S, T = IK.running("PORTAL"), IK.running("SPAWN"), IK.running("tip")
    if not (P and S and T):
        return True
    rot = math.radians(IK.running("NE", 44.0) - 90)  # (the portal's rot in osv2_build; its front = local -y)
    front = (P[0] + math.sin(rot) * 30, P[1] - math.cos(rot) * 30)
    return (_seg_dist(x, y, P, front) > 25 + reach and min(math.hypot(x - S[0], y - S[1]), math.hypot(x - T[0], y - T[1])) > 25 + reach and
            _seg_dist(x, y, T, P) > 6 + reach)


def driftwood(m, x, y, z0, L=None, rot=None):
    L = L or rr.uniform(6, 11)
    rot = rr.uniform(0, 180) if rot is None else rot
    if not clear_of_approach(x, y, L / 2):
        return
    nm = "OceanDrift%d" % next(CNT)
    with IK.place(m, x, y, z0, rot):
        pts = [(-L / 2 + L * t / 6, 0.15 * math.sin(t * 1.7), 0.42 - 0.05 * t / 6) for t in range(7)]
        tube(nm, "driftwood", pts, [0.48, 0.5, 0.46, 0.44, 0.42, 0.38, 0.3], segs=10)
        tube(nm, "driftwood", [(L * 0.15, 0, 0.5), (L * 0.15 + 0.8, 1.6, 0.35), (L * 0.15 + 1.1, 2.3, 0.3)], [0.24, 0.18, 0.12], segs=8)
        O.fuse(nm, voxel=0.08, smooth_iters=1, faces=900)
        for k in range(3):
            sphere("OceanDrift_Knot", "driftwood_dark", (-L / 3 + k * L / 3, 0.0, 0.85), 0.16, sub=1, scale=(1.4, 1, 0.6))


# ================================================================== the shipwreck
def shipwreck2(m, x, y, z0, rot=0.0):
    n = "OceanWreck"
    heel = 0.35
    with IK.place(m, x, y, z0, rot):
        tube(n + "_Hull", "hull_wood", [(-18, 0, 0.8), (16, 0.6, 1.2)], 0.72, segs=10)                       # keel
        tube(n + "_Hull", "hull_wood", [(16, 0.6, 1.2), (18, 0.7, 3.5), (19, 0.8, 6.0)], [0.66, 0.62, 0.55], segs=10)  # stem
        for k in range(10):  # ribs (a few snapped)
            lx = -15 + k * 3.3
            snapped = k in (2, 5, 8)
            for sgn in (-1, 1):
                pts = []
                for j in range(7):
                    a = j / 6
                    ly = sgn * (0.2 + 6.4 * math.sin(a * math.pi / 2)) + heel * a * 6
                    lz = 0.9 + 7.5 * a - (heel * 4 if sgn < 0 else -heel * 2) * a
                    pts.append((lx, ly, lz))
                tube(n + "_Hull", "hull_wood", pts[:5] if (snapped and sgn > 0) else pts, 0.36, segs=8)
        for row in range(5):  # planks on the low side, with gaps (on the ribs)
            if row == 2:
                continue
            a = (row + 0.5) / 5
            ly = 0.2 + 6.4 * math.sin(a * math.pi / 2) + heel * a * 6
            lz = 0.9 + 7.5 * a + heel * 2 * a
            x0, x1 = -15.2 + rr.uniform(0, 4), 13.2 - rr.uniform(0, 6)
            tube(n + ("_Plank" if row % 2 else "_PlankDark"), "dock_wood" if row % 2 else "dock_wood_dark", [(x0, ly + 0.25, lz), (x1, ly + 0.25, lz + 0.2)],
                 0.5, segs=6)
        for k in range(6):  # the broken deck (each plank resting on a rib)
            lx = -11.7 + k * 3.3
            box(n + ("_Deck" if k % 2 else "_DeckDark"), "dock_wood" if k % 2 else "dock_wood_dark", (lx, 1.2, 5.7), (2.6, 13.0, 0.35),
                rot=(6, 0, 0), bevel=0.06)  # (wide enough to rest on the ribs both sides)
        mb, mt = Vector((-2, 0.5, 6.0)), Vector((4, 9.0, 24.0))
        tube(n + "_Mast", "driftwood_dark", [tuple(mb), tuple(mt)], [0.55, 0.42], segs=10)
        nest = mb + (mt - mb) * 0.82
        lathe(n + "_Nest", "hull_wood", [(0.0, -0.1), (1.3, -0.1, True), (1.35, 0.9, True), (1.15, 0.9), (1.1, 0.1)], segs=14, c=tuple(nest))
        y0, y1 = mb + (mt - mb) * 0.66 + Vector((-3.5, -2.4, 0)), mb + (mt - mb) * 0.66 + Vector((3.5, 2.4, 0.8))
        tube(n + "_Mast", "driftwood_dark", [tuple(y0), tuple(y1)], 0.28, segs=8)
        cols = []
        for i in range(7):  # the torn sail hanging from the yard (both sides, ragged bottom)
            t = i / 6
            top = y0 + (y1 - y0) * t
            drop = (7.0 + rr.uniform(-2.5, 1.5)) if 0 < i < 6 else 4.5
            bill = 1.0 * math.sin(math.pi * t)
            cols.append((top, top + Vector((bill * 0.3, bill, -drop))))
        for i in range(6):
            (a, b), (c, d) = cols[i], cols[i + 1]
            poly(n + "_Sail", "sail", [a, c, d, b], thick=0.06)
        for p0, p1 in ((mt, Vector((18, 0.8, 6.0))), (mt, Vector((-14, -2.0, 6.8))), (nest, Vector((8, -5, 0.0)))):
            mid = (p0 + p1) / 2 - Vector((0, 0, 1.2))
            tube(n + "_Rope", "rope", [tuple(p0), tuple(mid), tuple(p1)], 0.09, segs=5)
    for k, (lx, ly) in enumerate(((-20, -8), (-23, -3), (21, -6), (-17, -12), (12, -11))):  # spilled cargo on the rocks
        c_, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        wx, wy, wz, _ = IK.where(m, x + lx * c_ - ly * s_, y + lx * s_ + ly * c_, 0.0, z0)
        if k % 2:
            IK.crate(IK.O_NONE, wx, wy, wz, rr.uniform(1.6, 2.2), rot + rr.uniform(0, 60))
        else:
            IK.barrel(IK.O_NONE, wx, wy, wz, k == 2, rot + rr.uniform(0, 180))


# ================================================================== the mapping + run
def patch():
    importlib.import_module("osv2_parts"), importlib.import_module("osv2_detail")
    BD, OD, OP = IK.patch_v2_common()  # (keeps Ocean Shore's own colours: grey cliffs ...)
    OD.brain_coral, OD.tube_coral, OD.seaweed, OD.conch, OD.sand_dollar = brain_coral, tube_coral, seaweed, conch, sand_dollar
    OD.shipwreck2 = IK.landmark(shipwreck2, "shipwreck")  # (its real footprint: loose palms / bushes keep off it)
    if not getattr(OD.cliff_column, "_cleared", False):  # (cliff columns keep off the portal + what's built before them)
        OD.cliff_column = IK.clear_cliff(OD.cliff_column, OD)
        OD.cliff_column._cleared = True
    for nm, fn in (("coral", coral), ("fan_coral", fan_coral), ("shell", shell), ("starfish", starfish), ("pebbles", pebbles), ("driftwood", driftwood)):
        setattr(OP, nm, fn)
    OP.tuft = lambda m, x, y, z0, s=1.0, look=None: IK.grass_clump(m, x, y, z0, s)
    OP.fern_bush = lambda m, x, y, z0, s=1.0: IK.fern(m, x, y, z0, s)
    OP.palm = lambda m, x, y, z0=0.0, h=None, lean=None, kind=None, fronds=None: IK.tree(m, x, y, z0, (h or 16.0) / 16.0 * 1.2, "palm")


def post(g):
    """After the v2 script: the shipwreck (decoration) slides clear of the rocks it was beached into (crnuch: "fix it")."""
    IK.settle_landmarks(("shipwreck",), ("Scenery_Rocks", "Landmarks"))


def main():
    patch()
    O.BMS.clear()
    g = IK.run_island(SCRIPT, OUT, post=post)
    O.finish()
    O.stats(skip=("Preview", "Scene", "Studs", "Sky_", "Label", "OSV2", "Diagram", "Egg_Spot"))
    IK.render_cams(g, OUT, "ocean_")


if __name__ == "__main__":
    main()
