# tools/blender/overhaul/hub_license.py - MAP MODEL OVERHAUL stage 3: the hub's LAW LICENSE BUILDING (crnuch's calls
# 2026-10-24, CLAUDE.md "MODEL OVERHAUL"), remade as meshes in the benchmark style. Same footprint and layout as the
# v2 hub's (environment-redesign/central_hub/hub_parts.py license_building) so mr.robe's hub wiring markers still fit:
#   podium x +-31, y -15..23, top z 4 | grand stairs x +-17 from y -27.2 | stair cheeks x +-19.5 | portico columns y -10
#   hall x +-18, y -7..19 | wings x 18.2..30.6 | dome on the hall at (0, 8) | doors at y -7 (main x 0, side x +-9)
#   KEEP CLEAR: the forecourt x +-10, y -15..-7 on the podium (the red carpet to the doors: the License counter area)
# Local frame: origin = the building's centre on the ground, front = -Y (faces the plaza). One mesh per colour
# (License_<Part>). Text is preview only (a SurfaceGui in the game). Podium + roof deck studs are PREVIEW (StudTop).
#   Blender -b --factory-startup --python tools/blender/overhaul/hub_license.py -- <out_dir>
import bpy, math, os, sys
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
N = "License"


def scales(p, x, y, z, s=1.0):
    """Gold scales of justice: stepped round base, turned post, a beam with curled ends, two pans on three chains."""
    with at(x, y, z):
        lathe(p + "_Gold", "gold", [(1.2 * s, 0.0), (1.2 * s, 0.3 * s, True), (0.95 * s, 0.4 * s), (0.9 * s, 0.6 * s, True),
                                    (0.55 * s, 0.7 * s), (0.28 * s, 0.95 * s), (0.22 * s, 1.2 * s)], segs=20)
        lathe(p + "_Gold", "gold", [(0.22 * s, 1.2 * s), (0.18 * s, 3.6 * s), (0.3 * s, 3.8 * s), (0.22 * s, 4.0 * s), (0.0, 4.05 * s)],
              segs=12)
        sphere(p + "_Gold", "gold", (0, 0, 4.55 * s), 0.42 * s, sub=2)
        tube(p + "_Gold", "gold", [(-2.3 * s, 0, 4.1 * s), (-1.2 * s, 0, 4.25 * s), (0, 0, 4.3 * s), (1.2 * s, 0, 4.25 * s), (2.3 * s, 0, 4.1 * s)],
             0.13 * s, segs=8)
        for sg in (-1, 1):
            curl = [(sg * (2.3 + 0.22 * math.cos(math.radians(a))) * s, 0, (4.32 + 0.22 * math.sin(math.radians(a))) * s)
                    for a in range(-90, 200, 40)]
            tube(p + "_Gold", "gold", curl, 0.07 * s, segs=5)
            px = sg * 2.3 * s
            for k in range(3):
                a = k / 3 * math.tau
                tube(p + "_Gold", "gold", [(px, 0, 4.05 * s), (px + math.cos(a) * 0.75 * s, math.sin(a) * 0.75 * s, 2.45 * s)], 0.04 * s,
                     segs=4)
            lathe(p + "_Gold", "gold", [(0.0, 2.05 * s), (0.5 * s, 2.1 * s), (0.85 * s, 2.32 * s), (0.95 * s, 2.45 * s, True),
                                        (0.88 * s, 2.47 * s), (0.0, 2.38 * s)], segs=16, c=(px, 0, 0))


def podium():
    box(N + "_Plinth", "stone_mid", (0, 4, 0.4), (62.8, 38.8, 0.8), bevel=0.12)
    box(N + "_Podium", "stone_light", (0, 4, 2.2), (62, 38, 2.8), bevel=0.1)
    box(N + "_Cap", "trim_cream", (0, 4, 3.8), (62.8, 38.8, 0.4), bevel=0.08)
    # rusticated bands on the visible faces (front beside the stairs, sides, back)
    for z in (1.75, 2.75):
        for s in (-1, 1):
            box(N + "_Plinth", "stone_mid", (s * 26.75, -15.02, z), (8.5, 0.12, 0.14))
            box(N + "_Plinth", "stone_mid", (s * 31.02, 4, z), (0.12, 38, 0.14))
        box(N + "_Plinth", "stone_mid", (0, 23.02, z), (62, 0.12, 0.14))
    # grand stairs: solid chamfered steps, a red carpet runner with gold stair rods
    for k in range(8):
        y0 = -27.2 + 1.4 * k
        top = 0.5 * (k + 1)
        box(N + "_Steps", "marble", (0, (y0 - 15.0) / 2, top / 2), (34, -15.0 - y0, top), bevel=0.05)
        box(N + "_Carpet", "carpet_red", (0, y0 + 0.7, top + 0.03), (8, 1.4, 0.06))
        box(N + "_Carpet", "carpet_red", (0, y0 - 0.03, top - 0.25), (8, 0.06, 0.5))
        tube(N + "_Gold", "gold", [(-4.3, y0 + 0.08, top + 0.1), (4.3, y0 + 0.08, top + 0.1)], 0.07, segs=6)
        for sx in (-4.3, 4.3):
            sphere(N + "_Gold", "gold", (sx, y0 + 0.08, top + 0.1), 0.12, sub=1)
    box(N + "_Carpet", "carpet_red", (0, -11.3, 4.03), (8, 8.0, 0.06))
    for sx in (-4.15, 4.15):
        box(N + "_Gold", "gold", (sx, -11.3, 4.05), (0.2, 8.0, 0.08))
    # stair cheeks: marble blocks with gold-trimmed caps, the scales statues and double lamps
    for s in (-1, 1):
        x = s * 19.5
        box(N + "_Cheek", "marble", (x, -21, 2.3), (5, 12, 4.6), bevel=0.1)
        box(N + "_Cheek", "marble_shade", (x, -21, 4.75), (5.6, 12.6, 0.3), bevel=0.06)
        box(N + "_Gold", "gold", (x, -21, 4.55), (5.3, 12.3, 0.12))
        for y in (-25.5, -19.5):
            box(N + "_Cheek", "marble_shade", (x - s * 2.52, y, 2.0), (0.1, 3.4, 2.4), bevel=0.04)  # panel on the outer face
        scales(N + "Scales", x, -23.6, 4.9, 0.95)
        with at(x, -17.3, 4.9, rz=90):
            PR.lamp_double()


def hall():
    # walls + base band
    box(N + "_Wall", "wall_cream", (0, 6, 13.5), (36, 26, 19))
    box(N + "_Base", "stone_mid", (0, 6, 4.7), (36.3, 26.3, 1.4), bevel=0.06)
    # front wall (behind the portico): main door, side doors with windows over them, the oculus
    with at(0, -7.0):
        B.door(N + "Door", 0, 4.0, 7.0, 11.0)
        for s in (-1, 1):
            B.door(N + "SideDoor", s * 9, 4.0, 3.6, 7.0, frame="marble", depth=0.4)
            B.window(N + "Win", s * 9, 13.0, 3.6, 5.2, arch=True)
            for x in (s * 5.6, s * 12.6, s * 17.3):
                box(N + "_Pilaster", "marble", (x, -0.2, 13.5), (1.0, 0.4, 19), bevel=0.05)
        lathe(N + "_Gold", "gold", [(1.8, -0.1, True), (2.5, -0.1), (2.5, 0.5), (1.8, 0.5, True), (1.8, -0.1)], segs=24,
              c=(0, 0, 19.0), rot=(-90, 0, 0))
        cyl(N + "_Glass", "glass_blue", (0, 0.05, 19.0), 1.85, 0.2, segs=24, rot=(90, 0, 0))
        for a in range(0, 360, 45):
            tube(N + "_Gold", "gold", [(0, -0.12, 19.0), (1.8 * math.cos(math.radians(a)), -0.12, 19.0 + 1.8 * math.sin(math.radians(a)))],
                 0.06, segs=4)
    # back wall windows
    with at(0, 19.0, rz=180):
        for x in (-12, -4, 4, 12):
            B.window(N + "Win", x, 8.0, 3.2, 7.5, arch=True)
            B.window(N + "Win", x, 17.0, 2.6, 3.6, arch=False, mullions=False)
    # side walls above the wing roofs: small square windows
    for s in (-1, 1):
        with at(s * 18.0, 6, rz=90 * s):
            for y in (-8, 0, 8):
                B.window(N + "Win", y, 19.8, 2.0, 2.0, arch=False, mullions=False, sill=False)
    B.cornice(N, 0, 6, 23.0, 36, 26, look="marble", trim="gold")
    box(N + "_Deck", "stone_mid", (0, 6, 24.3), (36.6, 26.6, 0.4))
    for (x0, y0, x1, y1) in ((-18, -6.6, 18, -6.6), (-18, 18.6, 18, 18.6), (-18, -6.6, -18, 18.6), (18, -6.6, 18, 18.6)):
        B.balustrade(N + "Bal", x0, y0, x1, y1, 24.5, h=1.5)


def portico():
    for x in (-15, -9, -3, 3, 9, 15):
        B.column(N + "Col", x, -10, 4.0, 18.0, r=1.05)
    box(N + "_Entab", "marble", (0, -9.7, 22.5), (41, 5.4, 1.0), bevel=0.06)         # architrave
    box(N + "_Gold", "gold", (0, -12.42, 23.05), (41, 0.12, 0.12))
    box(N + "_Frieze", "navy_dark", (0, -9.7, 23.65), (40.4, 5.2, 1.2))               # frieze (the LAW LICENSES band)
    box(N + "_Gold", "gold", (0, -12.33, 24.22), (40.6, 0.12, 0.12))
    box(N + "_Entab", "marble", (0, -9.7, 24.5), (42.2, 6.2, 0.5), bevel=0.08)         # cornice
    text("LAW LICENSES", "gold", (0, -12.36, 23.65), 0.95, extrude=0.03)
    for x in [-18 + 2.0 * i for i in range(19)]:  # little dentils under the cornice
        box(N + "_Entab", "marble", (x, -12.62, 24.12), (0.5, 0.35, 0.35))
    B.gable(N, "marble", 0, -9.7, 24.75, 41, 6.4, 5.4, trim="marble", tympanum="navy_roof")
    scales(N + "Scales", 0, -12.45, 25.15, 0.6)
    # the portico's ceiling + a gold lantern hanging over the door
    box(N + "_Ceiling", "marble_shade", (0, -9.7, 21.85), (36, 4.8, 0.3))
    tube(N + "_Iron", "iron", [(0, -9.3, 21.7), (0, -9.3, 20.6)], 0.06, segs=5)
    PR.lantern(N, (0, -9.3, 18.3), 0.9)


def dome():
    cx, cy = 0, 8
    with at(cx, cy, 24.7):
        lathe(N + "_Drum", "marble", [(10.2, 0.0), (10.2, 0.6, True), (9.7, 0.8), (9.6, 1.4, True), (0.0, 1.4)], segs=40)
        cyl(N + "_DrumWall", "wall_cream", (0, 0, 1.4), 8.8, 6.6, segs=40)
        for k in range(12):
            a = math.radians(k * 30)
            with at(math.cos(a) * 8.8, math.sin(a) * 8.8, 0, rz=k * 30 + 90):
                box(N + "_Pilaster", "marble", (0, -0.25, 4.7), (0.9, 0.5, 6.6), bevel=0.05)
            b = math.radians(k * 30 + 15)
            with at(math.cos(b) * 8.82, math.sin(b) * 8.82, 0, rz=k * 30 + 15 + 90):
                B.window(N + "DomeWin", 0, 2.6, 1.7, 3.7, arch=True, mullions=False, sill=False)
        lathe(N + "_Gold", "gold", [(9.3, 8.0), (9.6, 8.2), (9.6, 8.7), (9.25, 8.9, True), (0.0, 8.9)], segs=40)
        prof = [(9.0 * math.sqrt(max(0.0, 1 - t * t)) + 0.02, 8.9 + 9.6 * t) for t in [i / 14 for i in range(15)]]
        prof = [(max(r, 1.9), z) for r, z in prof if r > 1.85] + [(1.9, prof[-3][1]), (0.0, prof[-3][1])]
        lathe(N + "_Dome", "gold", prof, segs=40)
        for k in range(16):
            a = k / 16 * math.tau
            pts = []
            for i in range(1, 13):
                t = i / 14
                r = 9.0 * math.sqrt(max(0.0, 1 - t * t)) + 0.14
                if r < 2.05:
                    break
                pts.append((math.cos(a) * r, math.sin(a) * r, 8.9 + 9.6 * t))
            tube(N + "_Rib", "gold_dark", pts, 0.16, segs=5)
        ztop = prof[-1][1]
        # lantern: base disc, six little columns round a glowing core, cap, gold cupola, finial, flag
        cyl(N + "_Lantern", "marble", (0, 0, ztop), 2.2, 0.35, segs=20)
        cyl(N + "_Glow", "lamp_glow", (0, 0, ztop + 0.35), 1.2, 2.4, segs=16)
        for k in range(6):
            a = k / 6 * math.tau
            cyl(N + "_Lantern", "marble", (math.cos(a) * 1.65, math.sin(a) * 1.65, ztop + 0.35), 0.24, 2.4, segs=8)
        cyl(N + "_Lantern", "marble", (0, 0, ztop + 2.75), 2.25, 0.35, segs=20)
        lathe(N + "_Gold", "gold", [(2.05, ztop + 3.1), (1.9, ztop + 3.6), (1.4, ztop + 4.2), (0.7, ztop + 4.6), (0.0, ztop + 4.75)], segs=20)
        sphere(N + "_Gold", "gold", (0, 0, ztop + 5.1), 0.42, sub=2)
        B.flag(N, 0, 0, ztop + 5.4, 5.5, look="flag_purple", w=3.4, fh=2.0, seed=1)


def wings():
    for s in (-1, 1):
        cx = s * 24.4
        box(N + "_Wall", "wall_cream", (cx, 4, 10.5), (12.4, 26, 13))
        box(N + "_Base", "stone_mid", (cx, 4, 4.7), (12.7, 26.3, 1.4), bevel=0.06)
        B.cornice(N + "Wing", cx, 4, 17.0, 12.4, 26, look="marble", trim="gold")
        B.hip_roof(N + "Wing", "navy_roof", cx, 4, 18.15, 12.4, 26, 4.6, over=0.6)
        for corner_y, dy in ((-9, -1), (17, 1)):
            B.quoins(N, s * 30.6, corner_y, 5.4, 17.0, dir=(s, dy))
            B.quoins(N, s * 18.2, corner_y, 5.4, 17.0, dir=(-s, dy)) if corner_y == -9 else None
        with at(cx, -9.0):  # front: two floors of windows, shutters below, a banner between
            for x in (-3.2, 3.2):
                B.window(N + "Win", x, 6.6, 2.6, 3.8, arch=False, shutters="navy_dark")
                B.window(N + "Win", x, 11.8, 2.6, 4.0, arch=True)
            box(N + "_Gold", "gold", (0, -0.2, 15.3), (2.4, 0.3, 0.2), bevel=0.04)
            prism(N + "_BannerEdge", "gold_dark", [(-1.15, 7.3), (0, 8.0), (1.15, 7.3), (1.15, 15.2), (-1.15, 15.2)], 0.1, c=(0, -0.3, 0))
            prism(N + "_Banner", "flag_purple", [(-1.0, 7.55), (0, 8.2), (1.0, 7.55), (1.0, 15.1), (-1.0, 15.1)], 0.16, c=(0, -0.3, 0))
            cyl(N + "_Gold", "gold", (0, -0.39, 12.6), 0.62, 0.06, segs=18, rot=(90, 0, 0))
            box(N + "_BannerEdge", "gold_dark", (0, -0.43, 12.6), (0.18, 0.04, 0.8))
        with at(s * 30.6, 4, rz=90 * s):  # outer side: windows on both floors
            for y in (-8, 0, 8):
                B.window(N + "Win", y, 6.6, 2.6, 3.8, arch=False)
                B.window(N + "Win", y, 11.8, 2.6, 4.0, arch=True)
        with at(cx, 17.0, rz=180):
            for x in (-3.2, 3.2):
                B.window(N + "Win", x, 6.6, 2.6, 3.8, arch=False)
                B.window(N + "Win", x, 11.8, 2.6, 4.0, arch=True)
        B.flag(N, cx + s * 2.0, 4, 22.6, 4.5, look="flag_red", w=2.8, fh=1.7, seed=2 + s)


def grounds():
    """Podium planting + the preview studs on the podium and roof deck."""
    for s in (-1, 1):
        with at(s * 13.0, -13.1, 4.0):
            PR.flower_bed()
        with at(s * 27.0, -12.0, 4.0):
            PR.planter_square()
        with at(s * 27.0, 20.6, 4.0):
            PR.planter_round()
    for s in (-1, 1):
        with at(s * 9.0, 20.8, 4.0):
            PR.hedge()

    def covered(x, y):
        if abs(x) < 20.6 and -12.9 < y < 19.4:            # hall + portico
            return True
        if abs(x) > 17.7 and -9.5 < y < 17.5:             # wings
            return True
        if abs(x) < 4.6 and y < -6.5:                     # carpet
            return True
        if 8.4 < abs(x) < 17.6 and y < -10.9:             # flower beds
            return True
        if 24.5 < abs(x) < 29.5 and y < -9.5:             # planters
            return True
        if abs(x) > 25.2 and y > 18.8:
            return True
        if 4.0 < abs(x) < 14.0 and y > 19.2:              # hedges
            return True
        return False
    B.studtop(N, "trim_cream", -31.3, 31.3, -15.3, 23.3, 4.0, skip=covered)
    B.studtop(N, "stone_mid", -17.6, 17.6, -6.2, 18.2, 24.5, skip=lambda x, y: math.hypot(x, y - 8) < 10.4)


def building():
    podium()
    hall()
    portico()
    dome()
    wings()
    grounds()


def old_version(x0):
    """Today's v2 hub building (the same builder the hub uses), for the before / after."""
    sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "environment-redesign", "central_hub"))
    import hl_kit as K
    import hl_classic as CL
    import hub_parts as HP
    m = CL.ClassicMesh("Old_License", bpy.context.scene.collection)
    HP.license_building(K.Frame(m, x0, 0, 0))
    m.done()


def main():
    O.reset()
    O.scene(sun_rot=(50, 8, -38))
    with O.region("new"):
        building()
        box("Preview_Ground", "grass_ov", (0, 0, -0.1), (300, 300, 0.2))
        box("Preview_Plaza", "plaza", (0, -40, 0.1), (90, 26, 0.2))
        O.player(6, -30)
        O.player(-2.5, -11, 4.0)
    with O.region("old"):
        try:
            old_version(400)
        except Exception as e:
            print("[license] old version skipped:", e)
        box("Preview_Ground", "grass_ov", (400, 0, -0.1), (300, 300, 0.2))
        box("Preview_Plaza", "plaza", (400, -40, 0.1), (90, 26, 0.2))
        O.player(406, -30)
    O.stats()
    O.render(OUT, "license_front", (0, -98, 22), (0, 0, 15), lens=34, show=["new"])
    O.render(OUT, "license_three_quarter", (66, -74, 44), (0, 2, 13), lens=32, show=["new"])
    O.render(OUT, "license_entrance", (-9, -44, 7.5), (0, -8, 12), lens=26, show=["new"])
    O.render(OUT, "license_back", (-60, 80, 40), (0, 4, 14), lens=32, show=["new"])
    O.render(OUT, "license_before", (466, -74, 44), (400, 2, 13), lens=32, show=["old"])
    O.render(OUT, "license_after", (66, -74, 44), (0, 2, 13), lens=32, show=["new"])


main()
