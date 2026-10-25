# tools/blender/overhaul/hub_minigames.py - MAP MODEL OVERHAUL stage 3: the hub MINIGAME SPOTS (Hub.SpecialSpots:
# SpecialSpot1 = Gavel Bonk, SpecialSpot2 = Lucky Briefcase) and the ARCADE PIER booth (ArcadePier.Booths.<Game>), remade
# as meshes in the benchmark style (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"). Same layout as today's
# Part models (measured in Studio 2026-10-24). Scripted pieces stay separate so each instance can be swapped 1 for 1:
#   Station: PlayButton (PlayPrompt), StatusAnchor, Board (SurfaceGui), Sign (SurfaceGui), Bulb1-14 (attr Bulb),
#            Case1-3 (Models, attrs Rest / Slot - Minigames.client moves them), Peeker1-3 (attr Rest), the gavel + judge.
#   Booth:   PlayZone (PlayPrompt), Marquee (SurfaceGui Sign), Screen (SurfaceGui Board), Bulb x20.
# Here: the static scenery (spot frame, the courtroom bench, the felt table + board, podiums, lamps, booth shell) as
# per-colour meshes, plus ONE briefcase case, ONE bulb and the gavel as their own small models. The peekers and the
# judge are characters (the character stage, later). Blender: X across, Y = Roblox Z (front -Y), Z up, origin on the
# ground (the spots pivot on the ground; the booths at their bounding-box centre, 7.5 up). Text = preview only.
#   Blender -b --factory-startup --python tools/blender/overhaul/hub_minigames.py -- <out_dir>
import bpy, math, os, sys
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, star
import props as PR

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
O.K.PAL.update({"felt": (40, 150, 96), "felt_dark": (30, 110, 70), "court_wood": (150, 92, 52), "court_dark": (100, 58, 32),
                "booth_teal": (40, 190, 200), "booth_pink": (255, 110, 170), "booth_orange": (255, 150, 40), "rubber": (40, 40, 48)})
O.K.GLOWS.update({"screen_glow": ((120, 220, 255), 1.2)})


# ================================================================== the spot frame (both minigames)
def spot_frame(n, label, accent):
    """Base 20.4 x 22.4 (centre y -1): chamfered stone platform, an inset play floor, a front step, four lamp posts with
    gold caps, and a wood sign board on a post at the front left."""
    box(n + "_Base", "stone_mid", (0, -1, 0.35), (20.4, 22.4, 0.7), bevel=0.12)
    box(n + "_Inset", "plaza", (0, -1, 0.72), (18.4, 20.4, 0.1))
    box(n + "_Trim", "gold", (0, -12.18, 0.5), (20.6, 0.12, 0.3))
    box(n + "_Base", "stone_mid", (0, -12.9, 0.18), (8, 1.6, 0.36), bevel=0.08)
    for sx in (-9.4, 9.4):
        for sy in (-11.4, 9.4):
            lathe(n + "_Post", "marble", [(0.55, 0.7), (0.55, 1.1, True), (0.4, 1.3), (0.35, 3.6), (0.45, 3.8, True), (0.0, 3.8)], segs=12,
                  c=(sx, sy, 0))
            sphere(n + "_Gold", "gold", (sx, sy, 4.1), 0.36, sub=1)
    with at(-8.2, -13.6, 0, rz=-12):
        box(n + "_SignPost", "wood_deep", (0, 0.3, 2.5), (0.45, 0.45, 5.0), bevel=0.06)
        box(n + "_Sign", "sign_wood", (0, 0, 4.4), (5.6, 0.35, 2.0), bevel=0.08)
        box(n + "_SignFrame", "wood_deep", (0, 0.05, 4.4), (6.0, 0.25, 2.4), bevel=0.06)
        text(label, "white", (0, -0.2, 4.4), 0.62, extrude=0.02)
    # a podium with the PLAY button, a carpet runner
    box(n + "_Carpet", accent, (0, -5, 0.8), (6, 7, 0.06))
    for sx in (-3.05, 3.05):
        box(n + "_Gold", "gold", (sx, -5, 0.82), (0.12, 7, 0.08))
    lathe(n + "_Podium", "marble", [(1.6, 0.77), (1.6, 1.05, True), (1.2, 1.2), (1.0, 1.4), (1.0, 3.6), (1.25, 3.8, True), (1.3, 4.0),
                                    (0.0, 4.0)], segs=20, c=(0, -3, 0))
    cyl(n + "_Gold", "gold", (0, -3, 2.4), 1.05, 0.16, segs=20)
    cyl(n + "_Button", "red", (0, -3, 4.0), 0.75, 0.35, segs=20, r_top=0.65)
    cyl(n + "_Gold", "gold", (0, -3, 4.0), 0.9, 0.12, segs=20)


# ================================================================== GAVEL BONK: a courtroom bench with three pop-up windows
def gavel(n, c, rz=0.0):
    with at(*c, rz=rz):
        lathe(n + "_GavelHead", "court_wood", [(0.0, -1.1), (0.5, -1.1, True), (0.56, -1.0), (0.56, 1.0), (0.5, 1.1, True), (0.0, 1.1)],
              segs=16, rot=(0, 90, 0))
        for x in (-0.65, 0.65):
            cyl(n + "_GavelBand", "gold", (x - 0.1, 0, 0), 0.6, 0.2, segs=16, rot=(0, 90, 0))
        tube(n + "_GavelHandle", "court_wood", [(0, -0.4, 0), (0, -1.6, -0.15), (0, -3.0, -0.3)], [0.18, 0.17, 0.16], segs=10)
        sphere(n + "_GavelHandle", "court_wood", (0, -3.1, -0.3), 0.24, sub=1)


def gavel_bonk():
    n = "GavelBonk"
    spot_frame(n, "GAVEL BONK", "carpet_red")
    # the bench front with three windows (the peekers pop up in them), posts, rails
    for x in (-6.9, -2.0, 2.0, 6.9):
        box(n + "_Bench", "court_wood", (x, 3.0, 3.8), (1.8 if abs(x) > 6 else 1.6, 0.6, 6.0), bevel=0.08)
    box(n + "_Bench", "court_wood", (0, 3.0, 1.85), (15.6, 0.7, 2.1), bevel=0.08)
    box(n + "_Bench", "court_wood", (0, 3.0, 6.3), (15.6, 0.7, 1.0), bevel=0.08)
    for x in (-4.45, 0.0, 4.45):  # gold window frames
        with at(x, 3.0, 2.9):
            B.ring(n + "_Gold", "gold", B.opening(2.7, 2.9, False, n=4, grow=0.22), B.opening(2.7, 2.9, False, n=4), -0.42, 0.42)
    box(n + "_BenchTop", "court_dark", (0, 5.0, 7.0), (16.4, 5.2, 0.45), bevel=0.1)
    box(n + "_Gold", "gold", (0, 2.4, 7.0), (16.5, 0.1, 0.48))
    for sx in (-7.6, 7.6):
        box(n + "_Bench", "court_wood", (sx, 5.0, 3.6), (0.6, 4.6, 6.8), bevel=0.08)
    box(n + "_Bench", "court_wood", (0, 7.3, 3.6), (15.6, 0.6, 6.8), bevel=0.06)
    box(n + "_Inside", "court_dark", (0, 5.0, 0.95), (14.6, 4.0, 0.3))
    # the judge's high bench behind, with the gold seal
    box(n + "_High", "court_wood", (0, 6.6, 8.9), (8.4, 2.2, 3.4), bevel=0.1)
    box(n + "_BenchTop", "court_dark", (0, 6.5, 10.75), (9.2, 3.0, 0.4), bevel=0.1)
    box(n + "_Gold", "gold", (0, 5.42, 10.75), (9.25, 0.1, 0.42))
    for x in (-3.6, 3.6):
        box(n + "_Gold", "gold", (x, 5.45, 8.9), (0.18, 0.1, 3.0))
    cyl(n + "_Gold", "gold", (0, 5.55, 8.9), 1.05, 0.12, segs=24, rot=(90, 0, 0))
    cyl(n + "_Seal", "navy_dark", (0, 5.43, 8.9), 0.8, 0.06, segs=24, rot=(90, 0, 0))
    with at(0, 5.36, 8.9, s=0.28):
        B.ring(n + "_Gold", "gold", [(x, z) for x, z in star(2.0, 0.9)], [(x * 0.55, z * 0.55) for x, z in star(2.0, 0.9)], -0.1, 0.1)
    gavel(n, (-5.0, 4.2, 7.8), rz=-30)
    for sx in (-9.0, 9.0):  # courtroom lamps at the front corners
        with at(sx, -7.0, 0.7, s=0.82):
            PR.lamp()


# ================================================================== LUCKY BRIEFCASE: a felt table, three cases, a bulb board
def case_model(n):
    """One of the three cases (Case1-3, 3 x 3 x 1): a gold-cornered briefcase with a '?' plate."""
    with at(0, 0, 0):
        box(n + "_Case", "brief_brown", (0, 0, 1.25), (3.0, 1.0, 2.3), bevel=0.2, segs=2)
        box(n + "_Band", "wood_deep", (0, 0, 1.25), (3.04, 1.04, 0.1))
        for sx in (-1.38, 1.38):
            for sz in (0.22, 2.28):
                box(n + "_Gold", "gold", (sx, 0, sz), (0.36, 1.08, 0.36), bevel=0.06)
        box(n + "_Gold", "gold", (0, -0.52, 1.7), (1.0, 0.08, 0.8), bevel=0.04)
        text("?", "panel_black", (0, -0.57, 1.7), 0.62, extrude=0.015)
        tube(n + "_Handle", "brief_black", [(-0.55, 0, 2.4)] + [(0.55 * math.cos(math.radians(a)), 0, 2.4 + 0.45 * math.sin(math.radians(a)))
                                                            for a in range(150, 20, -26)] + [(0.55, 0, 2.4)], 0.09, segs=6)


def bulb(n, c):
    """One board bulb (Bulb1-14): a brass socket and a glowing globe."""
    with at(*c):
        cyl(n + "_Socket", "brass", (0, 0.1, 0), 0.2, 0.22, segs=10, rot=(90, 0, 0))
        sphere(n + "_Globe", "bulb_glow", (0, -0.2, 0), 0.24, sub=1)


def lucky_briefcase():
    n = "LuckyBriefcase"
    spot_frame(n, "LUCKY CASE", "flag_purple")
    # a card table: gold-trimmed green felt on turned legs
    for (x, y) in ((-6.8, 0.2), (6.8, 0.2), (-6.8, 5.8), (6.8, 5.8)):
        lathe(n + "_Leg", "court_dark", [(0.42, 0.75), (0.35, 1.2), (0.42, 1.8), (0.28, 2.6), (0.38, 3.6), (0.0, 3.6)], segs=12, c=(x, y, 0))
    box(n + "_Table", "court_wood", (0, 3.0, 3.85), (15.2, 6.8, 0.5), bevel=0.15)
    box(n + "_Felt", "felt", (0, 3.0, 4.12), (14.2, 5.8, 0.06))
    box(n + "_Gold", "gold", (0, -0.42, 3.85), (15.3, 0.1, 0.52))
    for x in (-4, 0, 4):  # the three slots on the felt
        box(n + "_FeltDark", "felt_dark", (x, 3.0, 4.16), (3.4, 1.6, 0.03))
    # the bulb board behind (Board gui in the middle)
    for sx in (-6.3, 6.3):
        lathe(n + "_Post", "court_dark", [(0.5, 0.7), (0.5, 1.0, True), (0.38, 1.2), (0.36, 12.3), (0.5, 12.6, True), (0.0, 12.6)], segs=12,
              c=(sx, 7.0, 0))
        sphere(n + "_Gold", "gold", (sx, 7.0, 12.95), 0.4, sub=2)
    box(n + "_BoardFrame", "panel_black", (0, 7.1, 9.0), (12.6, 0.5, 7.4), bevel=0.15)
    box(n + "_Board", "navy_dark", (0, 6.82, 9.0), (11.6, 0.1, 6.4))
    box(n + "_Gold", "gold", (0, 7.05, 12.55), (13.4, 0.8, 0.5), bevel=0.1)
    text("LUCKY CASE", "gold", (0, 6.74, 10.9), 1.1, extrude=0.03)
    for i in range(7):
        x = -5.0 + i * (10.0 / 6)
        for z in (5.95, 12.05):
            bulb(n + "Bulb", (x, 6.8, z))
    for k, x in enumerate((-4, 0, 4)):
        with at(x, 3.0, 4.15, rz=(k - 1) * 6):
            case_model(n + "Case")


# ================================================================== ARCADE BOOTH (16 x 15 x 15.2)
def arcade_booth(game="FilingFrenzy"):
    n = "Booth" + game
    accent = {"FilingFrenzy": "booth_teal", "BriefcaseStack": "booth_orange", "LieDetector": "booth_pink"}[game]
    box(n + "_Floor", "plank_light", (0, 0, 0.25), (16, 15.2, 0.5), bevel=0.08)
    for i in range(8):
        box(n + "_Planks", "plank_dark", (0, -7.0 + i * 2.0, 0.51), (15.6, 0.06, 0.02))
    box(n + "_Wall", "white", (0, 7.1, 6.0), (15.6, 1.0, 11.0))
    for sx in (-7.6, 7.6):
        box(n + "_Wall", "white", (sx, 1.5, 6.0), (0.8, 11.2, 11.0))
        for k in range(5):  # candy stripes on the side walls
            box(n + "_Stripe", accent, (sx + (0.42 if sx > 0 else -0.42), -3.0 + k * 2.2, 6.0), (0.06, 1.0, 10.6))
        lathe(n + "_Post", "gold", [(0.45, 0.5), (0.45, 0.8, True), (0.35, 1.0), (0.3, 11.6), (0.45, 11.8, True), (0.0, 11.8)], segs=12,
              c=(sx, -6.6, 0))
    # counter across the front with a striped apron and a gold top edge
    box(n + "_Counter", accent, (0, -4.6, 1.95), (14.4, 1.8, 2.9), bevel=0.1)
    for i in range(9):
        box(n + "_CounterStripe", "white", (-6.4 + i * 1.6, -5.52, 1.95), (0.6, 0.06, 2.7))
    box(n + "_Top", "wood_warm", (0, -4.6, 3.6), (15.0, 2.4, 0.4), bevel=0.1)
    box(n + "_Gold", "gold", (0, -5.82, 3.6), (15.1, 0.1, 0.42))
    # the back screen (the Board gui) in a gold frame, the marquee + bulbs on top, a striped awning between
    box(n + "_ScreenFrame", "gold", (0, 6.5, 6.8), (8.8, 0.4, 5.6), bevel=0.12)
    box(n + "_Screen", "screen_glow", (0, 6.28, 6.8), (8.0, 0.1, 4.8))
    for i in range(7):
        x0, x1 = -8.0 + 16 * i / 7, -8.0 + 16 * (i + 1) / 7
        lk, nm = (accent, n + "_Awning") if i % 2 == 0 else ("white", n + "_AwningW")
        poly(nm, lk, [(x0, 6.6, 11.6), (x1, 6.6, 11.6), (x1, -7.2, 10.4), (x0, -7.2, 10.4)], thick=0.15)
        xm = (x0 + x1) / 2
        poly(nm, lk, [(xm + (x1 - x0) / 2 * math.cos(math.pi * (1 - j / 6)), -7.22, 10.4 - 0.6 * math.sin(math.pi * j / 6)) for j in range(7)],
             thick=0.1)
    box(n + "_MarqueeBack", "gold", (0, -6.4, 13.4), (15.6, 0.8, 3.4), bevel=0.15)   # (its ends rest on the corner posts)
    box(n + "_Marquee", "panel_black", (0, -6.85, 13.4), (12.6, 0.2, 2.6), bevel=0.06)
    text({"FilingFrenzy": "FILING FRENZY", "BriefcaseStack": "CASE STACK", "LieDetector": "LIE DETECTOR"}[game], "gold",
         (0, -6.97, 13.4), 1.05, extrude=0.03)
    for i in range(10):
        for z in (11.85, 14.95):
            sphere(n + "_Bulbs", "bulb_glow", (-6.0 + i * (12.0 / 9), -6.85, z), 0.16, sub=1)
    # game props on the counter
    if game == "FilingFrenzy":
        with at(-3.5, -4.4, 3.8):
            box(n + "_Tray", "iron", (0, 0, 0.15), (3.2, 1.8, 0.3), bevel=0.06)
            for k, lk in enumerate(("carpet_red", "cash_green", "speed_blue", "license_yel")):
                box(n + "_Folder" + lk.title().replace("_", ""), lk, (-1.1 + k * 0.72, 0, 0.75), (0.5, 1.5, 1.1), rot=(0, 10 - k * 6, 0), bevel=0.04)
                box(n + "_Paper", "paper", (-1.1 + k * 0.72, 0, 1.34), (0.38, 1.3, 0.1), rot=(0, 10 - k * 6, 0))
        with at(3.8, -4.4, 3.8):
            for k in range(3):
                box(n + "_Paper", "paper", (0, 0, 0.03 + k * 0.055), (1.4, 1.0, 0.06), rot=(0, 0, k * 8))
            tube(n + "_Pen", "speed_blue", [(-0.4, -0.2, 0.24), (0.5, 0.3, 0.24)], 0.07, segs=6)
    elif game == "BriefcaseStack":
        for k, (x, y, z, rz) in enumerate(((-3.8, -4.4, 3.8, 4), (-3.6, -4.5, 4.29, -8), (-3.9, -4.4, 4.78, 10))):
            with at(x, y, z, rz=rz, s=0.55):
                PR.briefcase(n, ("brief_brown", "brief_black", "carry_red")[k], "gold_dark", (0, 0, 0.45), (-90, 0, 0))
        with at(3.8, -4.4, 3.8):
            box(n + "_Tray", "iron", (0, 0, 0.12), (2.4, 1.6, 0.24), bevel=0.05)
    else:
        with at(-3.6, -4.3, 3.8):  # a lie-detector machine: a box with a paper roll and a needle, two lamps
            box(n + "_Machine", "iron_light", (0, 0, 0.7), (2.6, 1.6, 1.4), bevel=0.12)
            cyl(n + "_Paper", "paper", (-0.9, 0, 1.5), 0.3, 1.8, segs=12, rot=(0, 90, 0))
            for k in range(5):
                box(n + "_Ink", "carpet_red", (-0.6 + k * 0.3, -0.32, 1.52 + 0.08 * math.sin(k * 2.1)), (0.24, 0.02, 0.05), rot=(0, 30 if k % 2 else -30, 0))
            box(n + "_Machine", "screen_glow", (0.5, -0.81, 0.85), (1.0, 0.04, 0.6))
            for k, lk in enumerate(("cash_green", "carpet_red")):
                sphere(n + "_Lamp" + lk.title().replace("_", ""), lk, (-0.5 + k * 0.6, -0.82, 0.4), 0.16, sub=1)
        for x in (2.4, 5.2):
            with at(x, -4.3, 3.8):
                lathe(n + "_Lamp", "brass", [(0.4, 0.0), (0.4, 0.1, True), (0.1, 0.2), (0.1, 1.4), (0.0, 1.4)], segs=10)
                lathe(n + "_LampShade", "cash_green", [(0.2, 1.3), (0.6, 1.5), (0.6, 1.62), (0.0, 1.62)], segs=14)


O.K.PAL.update({"cash_green": (84, 196, 96), "license_yel": (255, 200, 40), "carry_red": (232, 64, 64), "speed_blue": (64, 150, 255)})


def main():
    O.reset()
    O.scene(sun_rot=(50, 8, -38))
    with O.region("gavel"):
        gavel_bonk()
        box("Preview_Ground", "grass_ov", (0, 0, -0.1), (120, 120, 0.2))
        O.player(4.5, -9.5, 0.7)
    with O.region("lucky"):
        with at(100, 0):
            lucky_briefcase()
        box("Preview_Ground", "grass_ov", (100, 0, -0.1), (120, 120, 0.2))
        O.player(104.5, -9.5, 0.7)
    with O.region("booths"):
        for i, g in enumerate(("FilingFrenzy", "BriefcaseStack", "LieDetector")):
            with at(200 + (i - 1) * 18, 0):
                arcade_booth(g)
        O.player(207, -10)
        box("Preview_Ground", "plank_light", (200, 0, -0.1), (160, 160, 0.2))
    O.stats()
    O.render(OUT, "gavelbonk", (14, -26, 13), (0, 0, 4.5), lens=30, show=["gavel"])
    O.render(OUT, "luckycase", (114, -26, 13), (100, 0, 5.0), lens=30, show=["lucky"])
    O.render(OUT, "arcade_booths", (212, -46, 16), (200, 0, 6.5), lens=30, show=["booths"])
    O.render(OUT, "arcade_booth_close", (186, -18, 7), (182, 0, 5.5), lens=26, show=["booths"])


if __name__ == "__main__":
    main()
