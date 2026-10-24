# tools/blender/overhaul/island_hub.py - MAP MODEL OVERHAUL stage 5: the HUB ISLAND re-dressed (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"). The approved v2 hub (environment-redesign/central_hub_v2/hubv2_build.py: terrain, paving,
# roads, rings, waterfalls, sky - crnuch's layout) is run UNCHANGED in a sandbox (its .blend + layout JSON writes go to
# the out dir, never over the committed ones; its own renders off), with every dressing call it makes redirected to the
# overhaul's models at the same spot:
#   K.lamp / bench / planter / hedge / flowerbed / bush / rocks / railing -> props.py (one-green foliage)
#   BD.park_tree (oak / blossom / conifer) -> trees.py (oak, one-colour blossom, pine)
#   P.license_building / upgrades / egg_incubator -> hub_license / hub_services; P.shop -> the Shop stall players see;
#   P.travel_portal -> portal.py; P.bigcase_terrace -> a terrace deck + the Big Case belt + the two minigame spots;
#   P.leaderboard -> hub_gameplay; P.booth (Arcade Pier) -> the arcade booth; P.statue_fountain -> the new fountain
#   below; P.wood_sign / lot_sign -> wood boards; the example firms -> firm_stages + firm_hall.
# P.mutation_machine stays today's (Hub.MergeMachine is mr.robe's v3) and so does the spawn pad.
# Renders the v2 hub's own cameras, so its committed renders are the "before".
#   Blender -b --factory-startup --python tools/blender/overhaul/island_hub.py -- <out_dir> [only=<cam>,<cam>]
import bpy, math, os, sys, random, builtins, itertools
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "environment-redesign"))
HUB = os.path.join(ROOT, "central_hub_v2", "hubv2_build.py")
for _p in (HERE, os.path.join(ROOT, "central_hub_v2"), os.path.join(ROOT, "kit"), os.path.join(ROOT, "central_hub"),
           os.path.join(ROOT, "briefcase_bay_v2")):
    sys.path.insert(0, _p)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0]) if argv and "=" not in argv[0] else os.path.join(HERE, "renders")
ONLY = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
os.makedirs(OUT, exist_ok=True)

import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text
import props as PR
import trees as T
import hub_license as HL
import hub_services as HS
import hub_gameplay as HG
import hub_minigames as HM
import firm_stages as FS
import firm_hall as FH
import portal as PT
import hl_kit as K
import hub_parts as P
import bbv2_detail as BD

CNT = itertools.count(1)
rng = random.Random(77)
DEFERRED = []  # built after the hub script (its stud pass would stud them)


def where(m, x, y, rot=0.0, z=0.0):
    """A kit call's (x, y) in world space: m is a classic mesh (world coords) or a kit Frame (local coords)."""
    if isinstance(m, K.Frame):
        wx, wy = m.p(x, y)
        return wx, wy, m.z + z, m.rot + rot
    return x, y, z, rot


def frame_at(F, z=0.0):
    wx, wy = F.p(0, 0)
    return at(wx, wy, F.z + z, rz=F.rot)


# ------------------------------------------------------------------ dressing adapters
def lamp(m, x, y, h=11.0, rot=0.0, double=False):
    wx, wy, wz, r = where(m, x, y, rot)
    if double or h >= 12:
        with at(wx, wy, wz, rz=r + 90, s=h / 12.0):
            PR.lamp_double()
    else:
        with at(wx, wy, wz, rz=r, s=h / 11.0):
            PR.lamp()


def bench(m, x, y, rot=0.0):
    wx, wy, wz, r = where(m, x, y, rot)
    with at(wx, wy, wz, rz=r + 180):  # (the kit's bench faces +y, ours -y)
        PR.bench()


def planter(m, x, y, sx=4, sy=4, rot=0.0, plant="bush"):
    wx, wy, wz, r = where(m, x, y, rot)
    if plant == "flowers":
        with at(wx, wy, wz, rz=r, s=max(sx, sy) / 3.0):
            PR.planter_round()
    else:
        with at(wx, wy, wz, rz=r, s=max(sx, sy) / 4.3):
            PR.planter_square()


def hedge(m, x, y, length, rot, h=2.6, w=2.4):
    wx, wy, wz, r = where(m, x, y, rot)
    i = next(CNT)
    with at(wx, wy, wz, rz=r):
        n = max(2, int(length / 0.9))
        rr = min(h, w) * 0.36
        blobs = [((-length / 2 + rr + (length - 2 * rr) * k / (n - 1), yy, zz), rr) for k in range(n) for yy in (-w * 0.17, w * 0.17)
                 for zz in (h * 0.36, h * 0.66)]
        O.leafy("HubHedge%d" % i, blobs, look="hedge", voxel=0.3, faces=int(90 * length), lumpy=0.15, seed=i)


def flowerbed(m, x, y, sx, sy, rot=0.0, border="stone"):
    wx, wy, wz, r = where(m, x, y, rot)
    with at(wx, wy, wz, rz=r, s=max(0.6, min(sx / 8.6, sy / 3.6))):
        PR.flower_bed()


def bush(m, x, y, s=1.0, look="leaf"):
    wx, wy, wz, r = where(m, x, y)
    i = next(CNT)
    with at(wx, wy, wz, rz=rng.uniform(0, 360)):
        O.leafy("HubBush%d" % i, [((0, 0, 1.15 * s), 1.45 * s), ((0.9 * s, 0.4 * s, 0.9 * s), 1.05 * s), ((-0.8 * s, -0.3 * s, 0.95 * s), 1.05 * s)],
                voxel=0.25, faces=480, lumpy=0.22, seed=i)


def rocks(m, x, y, s=1.0, look="rock"):
    wx, wy, wz, r = where(m, x, y)
    with at(wx, wy, wz, rz=rng.uniform(0, 360), s=s * 0.9):
        PR.rocks()


def railing(m, x0, y0, x1, y1, z=0.0, h=2.6, look="white", post_every=3.0):
    ax, ay, az, _ = where(m, x0, y0)
    bx, by, _, _ = where(m, x1, y1)
    L = math.hypot(bx - ax, by - ay)
    n = max(1, round(L / 8))
    ang = math.degrees(math.atan2(by - ay, bx - ax))
    for k in range(n):
        t = (k + 0.5) / n
        with at(ax + (bx - ax) * t, ay + (by - ay) * t, az + z, rz=ang, s=(L / n) / 8.0):
            PR.railing()


def banner(*a, **k):
    pass  # (the double lamps carry their own banners)


def park_tree(m, x, y, z0, s=1.0, kind="oak"):
    wx, wy, wz, _ = where(m, x, y, z=z0)
    i = next(CNT)
    before = set(bpy.data.objects.keys())
    if kind == "conifer":
        T.tree_pine(wx, wy, name="HubPine%d" % i, s=s * 0.78, seed=i)
    elif kind == "blossom":
        T.tree_blossom(wx, wy, name="HubBlossom%d" % i, s=s * 0.62, seed=i)
    else:
        T.tree_oak(wx, wy, name="HubOak%d" % i, s=s * 0.62, seed=i)
    if wz:
        for nm in set(bpy.data.objects.keys()) - before:
            bpy.data.objects[nm].location.z += wz
    return wz + 11 * s


# ------------------------------------------------------------------ landmark adapters
def license_building(F):
    with frame_at(F):
        HL.building()


def upgrades(F):
    with frame_at(F):
        HS.upgrades()


def egg_incubator(F):
    with frame_at(F):
        HS.incubator()


def shop(F):
    with frame_at(F):
        HG.shop_stall()


def travel_portal(F, fx=None):
    wx, wy = F.p(0, 0)
    DEFERRED.append(("portal", Matrix.Translation((wx, wy, F.z)) @ Matrix.Rotation(math.radians(F.rot), 4, "Z")))


def bigcase_terrace(F, fx=None):
    with frame_at(F):
        box("HubTerrace_Deck", "stone_mid", (0, 0, 0.6), (66, 34, 1.2), bevel=0.15)
        box("HubTerrace_Gold", "gold", (0, 0, 0.95), (66.5, 34.5, 0.3), bevel=0.06)
        with at(0, 6, 1.2):
            HG.case_belt()
        with at(-20, -9.5, 1.2, s=0.72):
            HM.gavel_bonk()
        with at(20, -9.5, 1.2, s=0.72):
            HM.lucky_briefcase()
        for x, y in ((-30, 14), (30, 14)):
            with at(x, y, 1.2, s=0.9):
                PR.planter_square()
        with at(0, -13.5, 1.2, s=0.9):
            PR.attraction_sign("BIG CASES!")
        B.studtop("HubTerrace", "stone_mid", -33, 33, -17, 17, 1.2,
                  skip=lambda x, y: abs(y - 6) < 4.3 or (abs(abs(x) - 20) < 7.6 and y < 0.5) or (abs(abs(x) - 30) < 2.2 and y > 11.5)
                  or (abs(x) < 4.2 and -15.5 < y < -11))


BOARDS = itertools.count()


def leaderboard(F, title):
    with frame_at(F):
        HG.leaderboard(accent=("gold", "license_yel", "gold", "license_yel")[next(BOARDS) % 4], title=title)


ARCADE = itertools.cycle(("FilingFrenzy", "BriefcaseStack", "LieDetector"))


def booth(F, x, y, title, canopy, prop):
    wx, wy = F.p(x, y)
    with at(wx, wy, F.z, rz=F.rot, s=0.78):
        HM.arcade_booth(next(ARCADE))


def wood_board(label, w, h, z, post=True):
    if post:
        for sx in (-w / 2 + 0.6, w / 2 - 0.6):
            box("HubSign_Post", "wood_deep", (sx, 0.3, (z + h) / 2), (0.5, 0.5, z + h), bevel=0.06)
    box("HubSign_Board", "sign_wood", (0, 0, z + h / 2), (w, 0.4, h), bevel=0.1)
    box("HubSign_Frame", "wood_deep", (0, 0.05, z + h / 2), (w + 0.4, 0.3, h + 0.4), bevel=0.08)
    text(label, "white", (0, -0.24, z + h / 2), min(h * 0.42, w / (0.72 * max(1, len(label)))), extrude=0.02)


def wood_sign(F, x, y, z, w, h, label, rot=0.0, post=True, size=None):
    wx, wy = F.p(x, y)
    with at(wx, wy, F.z, rz=F.rot + rot):
        wood_board(label, w, h, z, post)


def lot_sign(F):
    with frame_at(F):
        with at(0, 14, 0):
            wood_board("EMPTY LOT", 12, 3.4, 4.0)
        for k in range(4):
            with at(-8 + k * 5, 22, 0, rz=k * 11, s=0.9):
                PR.crate()


def statue_fountain(F):
    with frame_at(F):
        fountain()


def firm(stage):
    def build(F, segments=6, name="YOUR FIRM"):
        with frame_at(F, z=2.1):
            FS.STAGES[stage]()
            for k in range(segments):
                with at(0, 21 + 11 * k, 0):
                    FH.office_segment(seed=k)
            with at(0, 21 + 11 * segments, 0):
                FH.back_wall()
    return build


# ------------------------------------------------------------------ the plaza's statue fountain (r 20)
def statue_lawyer(n, s, look="navy_dark", accent="gold"):
    """The heroic brick lawyer (fictional), gavel raised, briefcase in hand - the game's character frame x s."""
    def b(lk, cx, cy, z0, sx, sy, sz, bev=0.06):
        box(n + ("_Gold" if lk == accent else "_Bronze"), lk, (cx * s, cy * s, (z0 + sz / 2) * s), (sx * s, sy * s, sz * s), bevel=bev * s)
    for g in (-1, 1):
        b(look, g * 0.5, -0.15, 0, 0.95, 1.25, 0.32)
        b(look, g * 0.5, 0, 0.3, 0.9, 0.9, 1.3)
    b(look, 0, 0, 1.6, 2.0, 1.1, 1.5)
    b(accent, 0, -0.56, 2.0, 0.7, 0.1, 1.1, 0.02)
    b(look, 0, -0.6, 2.0, 0.25, 0.1, 1.0, 0.02)
    b(look, -1.35, 0, 1.75, 0.7, 0.8, 1.45)
    b(accent, -1.35, -0.1, 0.75, 1.4, 0.5, 1.0)
    b(look, 1.35, 0, 3.1, 0.7, 0.8, 1.5)
    b("wood_deep", 1.35, 0, 4.6, 0.25, 0.25, 1.5, 0.03)
    b(accent, 1.35, 0, 6.0, 1.6, 0.7, 0.7, 0.12)
    for g in (-1, 1):
        b(accent, g * 0.5, -0.57, 2.3, 0.25, 0.1, 0.8, 0.02)
    b(accent, 0, 0, 1.55, 2.05, 1.15, 0.18, 0.02)
    b(accent, 0, 0, 3.0, 1.0, 1.0, 0.15, 0.02)
    b(look, 0, 0, 3.1, 2.0, 1.8, 1.8, 0.12)
    for k in range(3):
        b(look, 0, 0.2 + k * 0.1, 4.75 + k * 0.3, 2.15 - k * 0.4, 1.95 - k * 0.3, 0.35, 0.06)
    for g in (-1, 1):
        b(accent, g * 0.45, -0.92, 3.9, 0.35, 0.1, 0.4, 0.02)
    b(accent, 0, -0.92, 3.45, 0.8, 0.1, 0.15, 0.02)
    for g in (-1, 1):
        b(accent, g * 0.35, -0.92, 3.55, 0.15, 0.1, 0.15, 0.02)


def fountain():
    n = "Fountain"
    lathe(n + "_Base", "stone_mid", [(20.2, 0.0), (20.2, 0.45, True), (19.9, 0.55, True), (0.0, 0.55)], segs=64)
    lathe(n + "_Marble", "marble", [(19.4, 0.5, True), (19.4, 2.4), (19.6, 2.6), (19.8, 2.95, True), (19.4, 3.05), (16.6, 3.05, True),
                                    (16.3, 2.9), (16.2, 1.6, True), (0.0, 1.6)], segs=64)
    lathe(n + "_Gold", "gold", [(19.45, 1.9), (19.65, 1.95), (19.65, 2.25), (19.45, 2.3)], segs=64)
    cyl(n + "_Water", "water", (0, 0, 1.6), 16.25, 0.55, segs=64)
    for k in range(8):  # buttresses with glowing orbs
        a = math.radians(k * 45 + 22.5)
        x, y = math.cos(a) * 19.6, math.sin(a) * 19.6
        lathe(n + "_Marble", "marble", [(1.35, 0.5), (1.35, 0.9, True), (1.05, 1.1), (0.95, 3.6), (1.25, 3.85, True), (1.3, 4.1), (0.0, 4.1)],
              segs=16, c=(x, y, 0))
        cyl(n + "_Gold", "gold", (x, y, 4.1), 0.85, 0.25, segs=16)
        sphere(n + "_Orb", "halo_glow", (x, y, 4.9), 0.62, sub=2)
    # middle drum with gold flutes, the upper bowl, the water curtain falling from its lip
    lathe(n + "_Marble", "marble", [(7.8, 1.6), (7.8, 2.1, True), (7.4, 2.3), (7.3, 4.7), (7.6, 5.0), (8.6, 5.4), (9.6, 5.9), (10.3, 6.3),
                                    (10.5, 6.6, True), (10.1, 6.75), (9.7, 6.6, True), (0.0, 6.6)], segs=56)
    for k in range(16):
        a = k / 16 * math.tau
        box(n + "_Gold", "gold", (math.cos(a) * 7.36, math.sin(a) * 7.36, 3.5), (0.4, 0.5, 2.6), rot=(0, 0, math.degrees(a)), bevel=0.06)
    cyl(n + "_Water", "water", (0, 0, 6.15), 9.75, 0.35, segs=56)
    lathe(n + "_Curtain", "water_fall", [(10.45, 6.55), (10.7, 5.6), (10.75, 3.5), (10.6, 2.15)], segs=56)
    # eight water jets arcing from the bowl's lip into the lower basin, foam rings where they land
    for k in range(8):
        a = math.radians(k * 45)
        pts = []
        for t in range(13):
            u = t / 12
            r = 10.6 + u * 4.8
            z = 6.7 + 2.6 * 4 * u * (1 - u) - u * 4.6
            pts.append((math.cos(a) * r, math.sin(a) * r, z))
        tube(n + "_Jet", "water_fall", pts, [0.32 - 0.1 * (t / 12) for t in range(13)], segs=8)
        cx, cy = math.cos(a) * 15.4, math.sin(a) * 15.4
        lathe(n + "_Foam", "white", [(0.5, 2.1), (1.1, 2.18), (1.25, 2.3), (1.0, 2.36), (0.6, 2.3)], segs=16, c=(cx, cy, 0))
    # plinth + plaque + the statue
    box(n + "_Marble", "marble", (0, 0, 7.4), (6.0, 6.0, 2.6), bevel=0.15)
    box(n + "_Gold", "gold", (0, 0, 9.0), (6.8, 6.8, 0.6), bevel=0.1)
    box(n + "_Marble", "marble", (0, 0, 10.0), (5.0, 5.0, 1.4), bevel=0.12)
    box(n + "_Gold", "gold", (0, -3.06, 7.4), (3.6, 0.15, 1.4), bevel=0.05)
    text("JUSTICE FOR ALL", "navy_dark", (0, -3.16, 7.4), 0.36, extrude=0.015)
    with at(0, 0, 10.7):
        statue_lawyer(n + "Statue", 2.6)


def patch():
    for nm, fn in (("lamp", lamp), ("bench", bench), ("planter", planter), ("hedge", hedge), ("flowerbed", flowerbed), ("bush", bush),
                   ("rocks", rocks), ("railing", railing), ("banner", banner)):
        setattr(K, nm, fn)
    BD.park_tree = park_tree
    for nm, fn in (("license_building", license_building), ("upgrades", upgrades), ("egg_incubator", egg_incubator), ("shop", shop),
                   ("travel_portal", travel_portal), ("bigcase_terrace", bigcase_terrace), ("leaderboard", leaderboard), ("booth", booth),
                   ("wood_sign", wood_sign), ("lot_sign", lot_sign), ("statue_fountain", statue_fountain),
                   ("firm_main_street", firm(3)), ("firm_glass_office", firm(4)), ("firm_supreme_tower", firm(6))):
        setattr(P, nm, fn)


class _NoSave:
    def __init__(self, wm):
        self._wm = wm

    def __getattr__(self, n):
        return getattr(self._wm, n)

    def save_as_mainfile(self, *a, **k):
        print("[island_hub] (skipped saving the hub .blend)")
        return {"FINISHED"}


def run_hub():
    """Run the approved v2 hub script unchanged: no .blend save, its JSON into OUT, no renders of its own."""
    hub_dir = os.path.dirname(HUB)
    real_open = builtins.open

    def safe_open(path, mode="r", *a, **k):
        if "w" in mode and os.path.abspath(str(path)).startswith(hub_dir):
            path = os.path.join(OUT, "sandbox_" + os.path.basename(str(path)))
        return real_open(path, mode, *a, **k)

    wm = bpy.ops.wm
    bpy.ops.wm = _NoSave(wm)
    old_argv = sys.argv
    sys.argv = [HUB, "--", "norender"]
    g = {"__name__": "__main__", "__file__": HUB, "open": safe_open}
    try:
        exec(compile(real_open(HUB).read(), HUB, "exec"), g)
    finally:
        bpy.ops.wm = wm
        sys.argv = old_argv
    return g


def main():
    patch()
    O.BMS.clear()
    g = run_hub()
    for kind, M in DEFERRED:
        if kind == "portal":  # (move everything it makes - its sign text is separate curve objects)
            before = set(bpy.data.objects.keys())
            PT.make_objects()
            for nm in set(bpy.data.objects.keys()) - before:
                ob = bpy.data.objects[nm]
                ob.matrix_world = M @ ob.matrix_world
    O.finish()
    O.stats(skip=("Preview", "Scene", "Old", "Studs", "Sky_", "Label", "Island", "Clouds", "Roads", "Plaza", "Lots", "Waterfall"))
    scene = bpy.context.scene
    for c in bpy.data.collections:
        if "Label" in c.name:
            c.hide_render = True
    cams = {k: v for k, v in g["CAMS"].items() if k != "cliff"}
    for key, ((name, loc, look, lens), w, h) in cams.items():
        if ONLY and key not in ONLY:
            continue
        O.render(OUT, "hub_" + key, loc, look, lens=lens, res=(w // 2 * 2 if w <= 1920 else 1920, h if w <= 1920 else 1080))


if __name__ == "__main__":
    main()
