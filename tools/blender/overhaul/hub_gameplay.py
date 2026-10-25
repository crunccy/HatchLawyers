# tools/blender/overhaul/hub_gameplay.py - MAP MODEL OVERHAUL stage 3: the hub's real GAMEPLAY models (the ones players
# see on the island when the hub switch is on - HubMap moves them onto mr.robe's wiring markers): the Shop stall
# (Hub.ShopStall), the License / Carry / Speed counters (Zones.LicenseOffice.Counter_*), a leaderboard
# (Hub.Leaderboards.<Board>) and the Big Case belt (Hub.BigCaseBelt). Same sizes and layout as today's Part models
# (measured in Studio 2026-10-24); at install these stay plain Parts / keep their names (scripts look them up):
#   ShopStall: PromptZone (invisible, ShopPrompt), Sign (SurfaceGui Sign), BigCoin (SurfaceGui Sign), Counter (Title)
#   Counter_*: DeskTop (UpgradePrompt), BoardAnchor | Leaderboard: Face (SurfaceGui List), Header (SurfaceGui Title)
#   BigCaseBelt: BeltStart / BeltEnd markers, Slats.Slat_NN (scrolled one by one by BigCase.client - ONE slat mesh here)
# Blender: X across, Y = Roblox Z (front -Y), Z up, origin on the ground (today's counters / boards pivot at their
# bounding-box centre: counters 4.1 up, boards 8.65 up). One mesh per colour (<Model>_<Part>). Text = preview only.
#   Blender -b --factory-startup --python tools/blender/overhaul/hub_gameplay.py -- <out_dir>
import bpy, math, os, sys, random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, star
import props as PR
import hub_services as HS

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
TAU = math.tau
O.K.PAL.update({"shop_purple": (150, 96, 224), "shop_pink": (255, 128, 190), "cash_green": (84, 196, 96), "rubber": (40, 40, 48),
                "license_yel": (255, 200, 40), "carry_red": (232, 64, 64), "speed_blue": (64, 150, 255), "hazard": (255, 204, 40)})
O.K.GLOWS.update({"screen_glow": ((120, 255, 150), 1.4), "portal_glow": ((170, 110, 255), 1.8)})


def egg(p, look, c, h=1.3):
    prof = [(HS.egg_profile(i / 10, R=h * 0.37), h * i / 10) for i in range(11)]
    lathe(p, look, [(0.0, 0.0)] + prof[1:-1] + [(0.0, h)], segs=14, c=c)


def coin_stack(p, c, n=4, r=0.42, seed=0):
    rr = random.Random(seed)
    for k in range(n):
        cyl(p, "gold", (c[0] + rr.uniform(-0.05, 0.05), c[1] + rr.uniform(-0.05, 0.05), c[2] + k * 0.16), r, 0.14, segs=12)


# ================================================================== SHOP STALL (17.6 x 19.7 x 16.4)
def shop_stall():
    n = "ShopStall"
    # deck: planks across, a gold front trim
    for i in range(13):
        y = -6.5 + 0.5 + i
        box(n + "_Deck", "plank_light" if i % 2 else "wood_warm", (0, y, 0.25), (17.0, 0.96, 0.5), bevel=0.05)
    box(n + "_Gold", "gold", (0, -6.62, 0.38), (17.4, 0.36, 0.6), bevel=0.06)
    # walls: wood panelling with a purple stripe band, back wall with a round window
    for sx in (-7.4, 7.4):
        box(n + "_Wall", "wall_warm", (sx, 1.5, 5.65), (1.0, 9.0, 10.3))
        box(n + "_Stripe", "shop_purple", (sx + (0.52 if sx > 0 else -0.52), 1.5, 3.4), (0.06, 8.6, 0.8))
        for y in (-1.5, 1.5, 4.5):
            box(n + "_Panel", "wood_warm", (sx + (0.53 if sx > 0 else -0.53), y, 6.9), (0.06, 2.4, 3.6), bevel=0.04)
    box(n + "_Wall", "wall_warm", (0, 5.9, 5.6), (15.0, 1.0, 10.2))
    box(n + "_Stripe", "shop_purple", (0, 5.38, 2.0), (14.6, 0.06, 0.8))
    # back cabinet with two shelves of wares: eggs, a mini boot + briefcase + firm, cash bundles, coins
    box(n + "_Cabinet", "wood_deep", (0, 4.9, 1.6), (13.0, 1.6, 2.2), bevel=0.06)
    for z in (5.6, 8.6):
        box(n + "_Cabinet", "wood_deep", (0, 4.9, z), (12.6, 1.7, 0.3), bevel=0.05)
        for sx in (-6.4, 6.4):
            box(n + "_Cabinet", "wood_deep", (sx, 4.9, z - 0.6), (0.3, 1.6, 1.3))
    for k, (x, lk) in enumerate(((-5.0, "egg_blue"), (-3.6, "shop_pink"), (-2.2, "egg_shell"), (2.2, "license_yel"), (3.6, "egg_orange"),
                                 (5.0, "speed_blue"))):
        egg(n + "_Egg" + lk.title().replace("_", ""), lk, (x, 4.9, 8.75), 1.25)
        cyl(n + "_Gold", "gold", (x, 4.9, 8.75), 0.34, 0.1, segs=10)
    HS.boot(n + "Boot", (-4.0, 4.9, 5.75), rz=20, s=0.32)
    with at(-1.2, 4.9, 5.75, rz=-10, s=0.55):
        PR.briefcase(n, "brief_brown", "wood_deep", (0, 0, 0.9), (0, 0, 0))
    with at(1.6, 4.9, 5.75):  # a mini firm house
        box(n + "_MiniFirm", "egg_orange", (0, 0, 0.7), (2.0, 1.2, 1.4), bevel=0.08)
        prism(n + "_MiniRoof", "red", [(-1.2, 1.4), (1.2, 1.4), (0, 2.3)], 1.4)
        box(n + "_Gold", "gold", (0, -0.62, 0.55), (0.5, 0.06, 0.8))
    for k in range(3):
        with at(4.3, 4.9, 5.75 + k * 0.32, rz=k * 9):
            box(n + "_Cash", "cash_green", (0, 0, 0.15), (2.0, 0.95, 0.3), bevel=0.04)
            box(n + "_CashBand", "white", (0, 0, 0.15), (0.35, 0.99, 0.32))
    for x in (-5.4, -4.6, 5.2):
        coin_stack(n + "_Gold", (x, 4.6, 2.7), n=5, seed=int(x * 10))
    # the counter: red with white candy stripes, a wood top with a gold edge, till, bell, coin piles
    box(n + "_Counter", "parasol_red", (0, -3.6, 2.05), (12.9, 2.0, 3.1), bevel=0.08)
    for i in range(12):
        box(n + "_CounterStripe", "white", (-5.95 + i * 1.08, -4.62, 2.05), (0.45, 0.06, 2.9))
    box(n + "_Top", "wood_warm", (0, -3.6, 3.82), (13.6, 2.6, 0.45), bevel=0.1)
    box(n + "_Gold", "gold", (0, -4.92, 3.82), (13.7, 0.12, 0.5), bevel=0.03)
    cyl(n + "_Gold", "gold", (0, -4.7, 2.05), 0.95, 0.1, segs=20, rot=(90, 0, 0))
    text("$", "wood_deep", (0, -4.82, 2.05), 1.2, extrude=0.02)
    with at(-4.0, -3.3, 4.05):  # cash register
        box(n + "_Till", "brass", (0, 0.1, 0.55), (2.2, 1.5, 1.1), bevel=0.15)
        box(n + "_Till", "brass", (0, -0.55, 1.05), (2.0, 0.9, 0.35), rot=(-28, 0, 0), bevel=0.08)
        for i in range(3):
            for j in range(2):
                box(n + "_Keys", "white", (-0.6 + i * 0.6, -0.55 + j * 0.3, 1.25 - j * 0.15), (0.38, 0.22, 0.12), rot=(-28, 0, 0), bevel=0.03)
        box(n + "_Till", "brass", (0, 0.45, 1.65), (1.5, 0.5, 1.0), bevel=0.1)
        box(n + "_Screen", "screen_glow", (0, 0.18, 1.7), (1.2, 0.06, 0.6))
        box(n + "_Till", "gold_dark", (0, -0.68, 0.32), (1.8, 0.1, 0.4), bevel=0.04)
        tube(n + "_Till", "brass", [(1.1, 0.1, 0.7), (1.45, 0.1, 0.7), (1.45, 0.1, 1.2)], 0.08, segs=6)
        sphere(n + "_Keys", "white", (1.45, 0.1, 1.3), 0.14, sub=1)
    with at(4.0, -3.5, 4.05):  # desk bell + coin piles
        lathe(n + "_Gold", "gold", [(0.5, 0.0), (0.5, 0.08, True), (0.42, 0.14), (0.38, 0.35), (0.25, 0.55), (0.0, 0.62)], segs=16)
        sphere(n + "_Gold", "gold", (0, 0, 0.7), 0.09, sub=1)
    for (x, y, k) in ((2.2, -3.3, 4), (2.8, -3.9, 3), (5.5, -3.2, 5)):
        coin_stack(n + "_Gold", (x, y, 4.05), n=k, seed=k)
    # front posts (turned, white + gold), the roof, the striped scalloped awning and bunting
    for sx in (-7.6, 7.6):
        lathe(n + "_Post", "white", [(0.95, 0.5), (0.95, 1.0, True), (0.6, 1.2), (0.5, 1.6), (0.45, 9.6), (0.55, 9.8), (0.7, 10.5, True),
                                     (0.0, 10.5)], segs=16, c=(sx, -3.4, 0))
        cyl(n + "_Gold", "gold", (sx, -3.4, 2.4), 0.5, 0.2, segs=16)
        box(n + "_Gold", "gold", (sx, -3.4, 10.75), (2.2, 2.2, 0.5), bevel=0.08)
    box(n + "_Roof", "shop_purple", (0, 1.5, 11.5), (17.2, 10.6, 0.9), bevel=0.12)
    box(n + "_Gold", "gold", (0, 1.5, 12.05), (17.6, 11.0, 0.3), bevel=0.06)
    g = 8
    for i in range(g):
        x0, x1 = -8.6 + 17.2 * i / g, -8.6 + 17.2 * (i + 1) / g
        lk, nm = ("shop_purple", n + "_Awning") if i % 2 == 0 else ("white", n + "_AwningW")
        poly(nm, lk, [(x0, -3.6, 11.1), (x1, -3.6, 11.1), (x1, -7.6, 8.9), (x0, -7.6, 8.9)], thick=0.12)
        xm = (x0 + x1) / 2
        flap = [(x0, -7.6, 8.9)] + [(xm + (x1 - x0) / 2 * math.cos(math.pi * (1 - j / 6)), -7.62, 8.9 - 0.65 * math.sin(math.pi * j / 6))
                                    for j in range(7)] + [(x1, -7.6, 8.9)]
        poly(nm, lk, flap[1:-1], thick=0.1)
    pts = [(-7.6 + 15.2 * i / 14, -3.9, 9.9 - 0.7 * math.sin(math.pi * i / 14)) for i in range(15)]
    tube(n + "_Gold", "gold", pts, 0.035, segs=4, cap=False)
    for i in range(14):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        lk = ("shop_pink", "license_yel", "speed_blue", "cash_green")[i % 4]
        m = (a + b) / 2
        poly(n + "_Bunting" + lk.title().replace("_", ""), lk, [a + Vector((0.08, 0, -0.05)), b + Vector((-0.08, 0, -0.05)),
                                                                m + Vector((0, 0, -0.85))], thick=0.04)
    # SHOP sign: black panel in a gold back plate ringed with bulbs; the big gold coin on its stand behind
    box(n + "_Gold", "gold", (0, -3.0, 14.45), (13.2, 1.0, 4.6), bevel=0.15)          # (stands on the roof trim, top 12.2)
    box(n + "_Sign", "panel_black", (0, -3.55, 14.45), (12.2, 0.2, 3.6), bevel=0.06)
    for x in [-6.1 + 1.0 * i for i in range(13)]:
        for z in (12.48, 16.42):
            sphere(n + "_Bulbs", "bulb_glow", (x, -3.5, z), 0.17, sub=1)
    text("SHOP", "gold", (0, -3.68, 14.45), 2.4, extrude=0.05)
    lathe(n + "_Iron", "iron", [(0.7, 12.2), (0.7, 12.5, True), (0.35, 12.7), (0.32, 14.2), (0.0, 14.3)], segs=12, c=(0, 3.5, 0))
    with at(0, 3.5, 16.9):
        lathe(n + "_Gold", "gold", [(0.0, -0.5), (2.5, -0.5, True), (2.8, -0.45), (2.8, 0.45), (2.5, 0.5, True), (0.0, 0.5)], segs=40,
              rot=(90, 0, 0))
        lathe(n + "_Gold", "gold_dark", [(2.2, -0.55), (2.35, -0.55), (2.35, 0.55), (2.2, 0.55)], segs=40, rot=(90, 0, 0))
        text("$", "gold_dark", (0, -0.55, 0), 3.0, extrude=0.06)


# ================================================================== COUNTERS (4.4 x 8.2 x 3.2)
def counter(kind):
    n = "Counter" + kind
    colour = {"License": "license_yel", "Carry": "carry_red", "Speed": "speed_blue"}[kind]
    box(n + "_Base", "iron", (0, 0.2, 0.15), (4.3, 2.8, 0.3), bevel=0.06)
    box(n + "_Desk", "marble", (0, 0.2, 1.7), (4.0, 2.5, 2.8), bevel=0.3, segs=3, smooth=False)
    box(n + "_Front", colour, (0, -1.07, 1.65), (3.3, 0.1, 2.1), bevel=0.06)
    for sx in (-1.82, 1.82):
        lathe(n + "_Gold", "gold", [(0.22, 0.3), (0.22, 3.0)], segs=10, c=(sx, -1.0, 0))
    box(n + "_Gold", "gold", (0, -0.98, 2.88), (4.1, 0.14, 0.18), bevel=0.04)
    box(n + "_Top", "wood_deep", (0, 0.2, 3.25), (4.4, 2.9, 0.3), bevel=0.08)
    box(n + "_Gold", "gold", (0, -1.24, 3.25), (4.45, 0.08, 0.32))
    cyl(n + "_Gold", "gold", (0, -1.12, 1.65), 0.55, 0.06, segs=18, rot=(90, 0, 0))
    # desk bits: a gold bell and a paper stack
    lathe(n + "_Gold", "gold", [(0.32, 3.4), (0.32, 3.45, True), (0.26, 3.5), (0.22, 3.65), (0.12, 3.78), (0.0, 3.82)], segs=12, c=(1.4, 0.5, 0))
    for k in range(3):
        box(n + "_Paper", "paper", (-1.3, 0.6, 3.45 + k * 0.05), (1.0, 0.75, 0.05), rot=(0, 0, k * 6 - 6))
    # the floating icon (its own mesh: the game can bob / spin it), a little above today's 4.1 so it clears the desk
    with at(0, 0.1, 4.7):
        if kind == "License":  # a rolled certificate with a red ribbon and a gold seal
            cyl(n + "_Icon", "paper", (-1.0, 0, 0), 0.42, 2.0, segs=16, rot=(0, 90, 0))
            for sx in (-1.05, 0.95):
                cyl(n + "_Icon", "paper_yel", (sx, 0, 0), 0.46, 0.1, segs=16, rot=(0, 90, 0))
            cyl(n + "_IconRibbon", "carpet_red", (-0.15, 0, 0), 0.45, 0.3, segs=16, rot=(0, 90, 0))
            for s in (-1, 1):
                prism(n + "_IconRibbon", "carpet_red", [(-0.08, -0.3), (0.08, -0.3), (0.12 + s * 0.2, -1.0), (s * 0.2, -0.85), (-0.12 + s * 0.2, -1.0)],
                      0.08, c=(0, -0.42, 0))
            cyl(n + "_IconSeal", "gold", (0, -0.45, -0.3), 0.32, 0.12, segs=14, rot=(90, 0, 0))
        elif kind == "Carry":
            with at(0, 0, -0.75, s=0.95):
                PR.briefcase(n + "_Icon", "carry_red", "gold_dark", (0, 0, 0.9), (0, 0, 0))
        else:
            HS.boot(n + "_Icon", (0.3, 0, -0.9), rz=0, s=0.55)


# ================================================================== LEADERBOARD (11 x 17.3 x 1.4)
def leaderboard(accent="gold", title="RICHEST"):
    n = "Leaderboard"
    for sx in (-4.2, 4.2):
        box(n + "_Footing", "stone_mid", (sx, 0.3, 0.4), (1.6, 1.6, 0.8), bevel=0.1)
        lathe(n + "_Post", "wood_deep", [(0.48, 0.8), (0.42, 1.1), (0.38, 1.4), (0.38, 16.0), (0.45, 16.3, True), (0.0, 16.3)], segs=12,
              c=(sx, 0.3, 0))
        for z in (1.3, 2.45):
            cyl(n + "_Gold", "gold", (sx, 0.3, z), 0.44, 0.16, segs=12)
    # frame + face (the List gui) + header (the Title gui)
    box(n + "_Frame", "navy_dark", (0, 0.05, 8.65), (10.6, 0.6, 12.6), bevel=0.15)
    box(n + "_Trim", "gold", (0, -0.15, 8.65), (10.3, 0.3, 12.3), bevel=0.08)
    box(n + "_Face", "white", (0, -0.25, 8.65), (10.0, 0.3, 12.0))
    box(n + "_HeaderBack", "navy_dark", (0, -0.05, 15.65), (11.0, 0.9, 2.9), bevel=0.15)
    box(n + "_Header", accent, (0, -0.35, 15.65), (10.4, 0.5, 2.4), bevel=0.1)
    for sx in (-5.5, 5.5):
        sphere(n + "_Gold", "gold", (sx, -0.1, 15.65), 0.42, sub=2)
    # a little seamed gable roof with a gold ridge and a star crest
    for s in (-1, 1):
        box(n + "_Roof", "navy_roof", (s * 2.95, 0.05, 17.6), (6.3, 2.0, 0.3), rot=(0, s * 14, 0), bevel=0.06)
    tube(n + "_Gold", "gold", [(0, -1.0, 18.4), (0, 1.1, 18.4)], 0.13, segs=8)
    prism(n + "_Star", "gold", [(x, z + 19.02) for x, z in star(0.9, 0.42)], 0.3)  # (its two lower points in the roof)
    text(title, "panel_black", (0, -0.62, 15.65), min(1.2, 8.6 / (0.75 * max(1, len(title)))), extrude=0.02)


# ================================================================== BIG CASE BELT (62.4 x 12.2 x 10.3)
def slat(p, x):
    """One belt slat: a gold chevron (BigCase.client scrolls each slat on its own)."""
    prism(p + "_Slat", "hazard", [(-0.35, -2.6), (0.05, -2.6), (0.55, 0.0), (0.05, 2.6), (-0.35, 2.6), (0.15, 0.0)], 0.12,
          c=(x, 0, 0.55), rot=(90, 0, 0))


def case_belt():
    n = "BigCaseBelt"
    L = 60.0
    # housing: a chunky iron chassis with hazard-striped skirts, gold rails, legs, end rollers
    box(n + "_Chassis", "iron", (0, 0, 0.25), (L, 6.4, 0.5), bevel=0.1)
    box(n + "_Belt", "rubber", (0, 0, 0.47), (L, 6.0, 0.06))
    for s in (-1, 1):
        box(n + "_Skirt", "iron", (0, s * 3.4, 0.3), (L + 0.4, 0.4, 0.8), bevel=0.08)
        for i in range(30):
            prism(n + "_Hazard", "hazard", [(-0.5, -0.32), (0.3, -0.32), (0.9, 0.32), (0.1, 0.32)], 0.06,
                  c=(-L / 2 + 1.0 + i * 2.0, s * 3.63, 0.3))
        tube(n + "_Rail", "gold", [(-L / 2 - 0.4, s * 3.3, 1.05), (L / 2 + 0.4, s * 3.3, 1.05)], 0.28, segs=10)
        for i in range(11):
            x = -L / 2 + 3 + i * 5.4
            cyl(n + "_Rail", "gold", (x, s * 3.3, 0.6), 0.12, 0.45, segs=8)
    for sx in (-L / 2, L / 2):
        cyl(n + "_Roller", "iron_light", (sx, -3.2, 0.3), 0.32, 6.4, segs=16, rot=(-90, 0, 0))
        for s in (-1, 1):
            cyl(n + "_Gold", "gold", (sx, s * 3.25, 0.3), 0.36, 0.2, segs=16, rot=(-90 if s > 0 else 90, 0, 0))
    for i in range(30):
        slat(n, -L / 2 + 1.0 + i * 2.0)
    # the two portals: navy + gold arches over the belt ends with a glowing gate and a gem keystone
    for sx, label in ((-30.6, "IN"), (30.6, "OUT")):
        with at(sx, 0, rz=90):
            B.ring(n + "_Arch", "navy_dark", B.opening(7.6, 10.6, True, n=14, grow=1.3), B.opening(7.6, 10.6, True, n=14), -0.7, 0.7)
            B.ring(n + "_Gold", "gold", B.opening(7.6, 10.6, True, n=14, grow=0.35), B.opening(7.6, 10.6, True, n=14), -0.85, 0.85)
            prism(n + "_Glow", "portal_glow", B.opening(7.6, 10.6, True, n=14), 0.16)
            for s in (-1, 1):
                box(n + "_Footing", "stone_mid", (s * 4.4, 0, 0.5), (2.4, 2.4, 1.0), bevel=0.1)
            prism(n + "_Gold", "gold", [(-0.7, 10.7), (0.7, 10.7), (0.95, 12.1), (-0.95, 12.1)], 1.8)
            sphere(n + "_Gem", "speed_blue", (0, -0.95, 11.4), 0.45, sub=1)
            text(label, "white", (0, -0.9, 9.2), 0.9, extrude=0.03)


# ================================================================== renders
def main():
    O.reset()
    O.scene(sun_rot=(50, 8, -38))
    with O.region("shop"):
        shop_stall()
        box("Preview_Ground", "plaza", (0, 0, -0.1), (120, 120, 0.2))
        O.player(9.5, -9)
    with O.region("counters"):
        for i, k in enumerate(("License", "Carry", "Speed")):
            with at(100 + (i - 1) * 7, 0):
                counter(k)
        O.player(110.5, -1)
        box("Preview_Ground", "plaza", (100, 0, -0.1), (120, 120, 0.2))
    with O.region("board"):
        with at(200, 0):
            leaderboard()
        O.player(207, -1)
        box("Preview_Ground", "plaza", (200, 0, -0.1), (120, 120, 0.2))
    with O.region("belt"):
        with at(300, 0):
            case_belt()
        O.player(300, -7)
        box("Preview_Ground", "plaza", (300, 0, -0.1), (160, 160, 0.2))
    O.stats()
    O.render(OUT, "shop_three_quarter", (22, -30, 15), (0, 0, 7.5), lens=30, show=["shop"])
    O.render(OUT, "shop_front", (0, -30, 7), (0, 0, 8.5), lens=30, show=["shop"])
    O.render(OUT, "shop_counter", (-7, -13, 6.5), (-1, 0, 4), lens=24, show=["shop"])
    O.render(OUT, "counters", (104, -16, 6.5), (100, 0, 3.2), lens=30, show=["counters"])
    O.render(OUT, "leaderboard", (209, -30, 10), (200, 0, 9.0), lens=32, show=["board"])
    O.render(OUT, "belt_three_quarter", (300, -58, 22), (300, 0, 3.0), lens=30, show=["belt"])
    O.render(OUT, "belt_close", (265, -12, 6), (275, 0, 3.5), lens=26, show=["belt"])


if __name__ == "__main__":  # (the island scripts import these builders)
    main()
