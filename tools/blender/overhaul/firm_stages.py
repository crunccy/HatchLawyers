# tools/blender/overhaul/firm_stages.py - MAP MODEL OVERHAUL stage 4: the FIRM FRONTS 2-6 (Storefront Practice, Main Street
# Firm, Glass Office, Corporate HQ, Supreme Tower), remade as meshes in the benchmark style (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"; the Dingy Shack is firm_shack.py). Built over today's layout in Server.FirmStages:
#   firm-local x across (front x +-24), y up from the firm floor (the porch steps go down to -1.5), z into the plot
#   (0 = entrance line, -z = the street); lobby z 0..21. KEEP: the door at x -3..3, the clients' lanes (x +-18.4 at z 2,
#   and z 13.4), the back wall's aisle opening (x -6..6, up to 9), the elevator stops (x 17.5, z 20.35 - FirmFeatures),
#   the Showcase strip (z < 5.6), the upstairs room slots (Config.Floors.Slots) and the name sign spot each front returns.
# What stays plain Parts at install (scripts look them up / set attributes): Elevator doors + lights, Showcase pedestals
# (ShowcaseSlot), the HologramPad, LoungeCarpet, the porch colliders, the Sign. Everything else is here as per-colour
# meshes: <Stage>_<Part>. Bought-area furniture is its own <Stage><Area>_<Part> group (FirmStages.applyAreas shows it).
# Blender: X = firm x, Y = firm z (front -Y), Z = firm y. Text = preview only. Studs on broad tops = preview (StudTop).
#   Blender -b --factory-startup --python tools/blender/overhaul/firm_stages.py -- <out_dir> [2 3 4 5 6]
import bpy, math, os, sys, random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, star
import props as PR

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv and not argv[0].isdigit() else os.path.join(HERE, "renders")
ONLY = [int(a) for a in argv if a.isdigit()] or [2, 3, 4, 5, 6]
os.makedirs(OUT, exist_ok=True)
DEPTH = 21
O.K.PAL.update({"brick": (198, 84, 64), "brick_dark": (160, 62, 48), "brick_light": (222, 112, 86), "awning_green": (70, 170, 70),
                "sand": (236, 206, 150), "sand_dark": (204, 170, 112), "panel": (226, 232, 240), "glass_tint": (120, 180, 230)})


def fbox(name, look, x0, y0, z0, x1, y1, z1, bevel=0.0, smooth=False):
    """A box between two firm-local corners (x, y up, z into the plot), like FirmStages' Build:box."""
    box(name, look, ((x0 + x1) / 2, (z0 + z1) / 2, (y0 + y1) / 2), (abs(x1 - x0), abs(z1 - z0), abs(y1 - y0)), bevel=bevel, smooth=smooth)


def accent_bricks(name, look, x0, x1, y0, y1, face_z, r, count, normal=-1, depth=0.06):
    """A few highlighted bricks scattered on a wall face (the cartoon brick look, no full brick pattern)."""
    for _ in range(count):
        w = r.choice((1.2, 1.6, 2.0))
        x = r.uniform(x0 + w, x1 - w)
        y = round(r.uniform(y0 + 0.5, y1 - 0.5) / 0.6) * 0.6
        fbox(name, look, x - w / 2, y - 0.25, face_z + normal * depth, x + w / 2, y + 0.25, face_z, bevel=0.04)


def shell(n, h, look, trim):
    """The lobby shell shared by stages 2-6: side walls, corner pilasters (or quoins), the back wall with the aisle
    opening (x -6..6 up to 9), a base course along the street front."""
    for s in (-1, 1):
        fbox(n + "_Wall", look, s * 24 - 0.4, 0, 0, s * 24 + 0.4, h, DEPTH)
        fbox(n + "_Trim", trim, s * 24 - 0.8, -1.5, -0.9, s * 24 + 0.8, h + 0.3, 0.6, bevel=0.08)
    fbox(n + "_Wall", look, -24, 0, DEPTH - 0.6, -6, h, DEPTH)
    fbox(n + "_Wall", look, 6, 0, DEPTH - 0.6, 24, h, DEPTH)
    fbox(n + "_Wall", look, -6, 9, DEPTH - 0.6, 6, h, DEPTH)
    fbox(n + "_Trim", trim, -24.4, -1.5, -0.9, 24.4, 0.8, -0.3, bevel=0.06)


def entry(n, look, lamps=True):
    """Porch + steps over FirmBuilder's colliders (porch z -4.5..0 at y 0, steps to z -6), a doormat, lamps."""
    fbox(n + "_Porch", look, -11, -1.5, -4.5, 11, 0, 0, bevel=0.08)
    fbox(n + "_Porch", look, -11, -1.5, -5.25, 11, -0.5, -4.5, bevel=0.06)
    fbox(n + "_Porch", look, -11, -1.5, -6, 11, -1.0, -5.25, bevel=0.06)
    fbox(n + "_Mat", "carpet_red", -2.2, 0, -3.2, 2.2, 0.06, -0.8)
    if lamps:
        for s in (-1, 1):
            with at(s * 12.6, -5.0, -1.5, s=0.82):
                PR.lamp()


def wall_lantern(n, x, y, z):
    """A wall lantern on a curly bracket (the street face, z = the wall face)."""
    tube(n + "_Iron", "iron", [(x, z, y + 0.9), (x, z - 0.45, y + 1.0), (x, z - 0.8, y + 0.8)], 0.06, segs=5)
    PR.lantern(n, (x, z - 0.85, y - 0.6), 0.6)


def name_board(n, cx, cy, cz, w, h, look="wood_deep", trim="gold"):
    """The backing board behind the firm's name Sign (FirmBuilder puts the Sign part at the front's returned CFrame)."""
    fbox(n + "_SignBoard", look, cx - w / 2, cy - h / 2, cz, cx + w / 2, cy + h / 2, cz + 0.3, bevel=0.08)
    fbox(n + "_Gold", trim, cx - w / 2 - 0.15, cy - h / 2 - 0.15, cz + 0.08, cx + w / 2 + 0.15, cy + h / 2 + 0.15, cz + 0.22, bevel=0.05)


# ================================================================== 2. STOREFRONT PRACTICE (one storey of brick)
def stage2():
    n, H = "Storefront", 9.0
    r = random.Random(2)
    entry(n, "stone_light")
    shell(n, H, "brick", "marble")
    # front: brick piers + sill + shop-top, two big shop windows (three panes each, white frames), a stall board
    for s in (-1, 1):
        lo, hi = sorted((5 * s, 21 * s))
        fbox(n + "_Wall", "brick", lo, 0, -0.5, hi, 0.9, 0)
        fbox(n + "_Stall", "awning_green", lo + 0.2, 0.05, -0.62, hi - 0.2, 0.85, -0.5, bevel=0.04)
        fbox(n + "_Wall", "brick", lo, 6.6, -0.5, hi, H, 0)
        a, b2 = sorted((21 * s, 24 * s))
        fbox(n + "_Wall", "brick", a, 0, -0.5, b2, H, 0)
        a, b2 = sorted((3 * s, 5 * s))
        fbox(n + "_Wall", "brick", a, 0, -0.5, b2, H, 0)
        fbox(n + "_Glass", "glass", lo, 0.9, -0.35, hi, 6.6, -0.25)
        fbox(n + "_Frame", "white", lo - 0.3, 6.5, -0.75, hi + 0.3, 6.95, -0.2, bevel=0.06)
        fbox(n + "_Frame", "white", lo - 0.3, 0.75, -0.75, hi + 0.3, 1.05, -0.2, bevel=0.06)
        for k in range(4):
            x = lo + (hi - lo) * k / 3
            fbox(n + "_Frame", "white", x - 0.22, 0.9, -0.6, x + 0.22, 6.6, -0.2, bevel=0.04)
        fbox(n + "_Frame", "white", lo, 5.0, -0.5, hi, 5.2, -0.25)  # transom bar
        for k in range(3):  # cartoon shine on each pane
            x = lo + (hi - lo) * (k + 0.3) / 3
            poly(n + "_Shine", "white", [(x, -0.4, 2.0), (x + 0.5, -0.4, 2.0), (x + 1.6, -0.4, 4.4), (x + 1.1, -0.4, 4.4)], thick=0.02)
        # flower box under each window
        fbox(n + "_FlowerBox", "wood_deep", lo + 0.5, 0.2, -1.5, hi - 0.5, 1.0, -0.5, bevel=0.08)
        for k in range(int((hi - lo - 1) / 0.9)):
            x = lo + 1.0 + k * 0.9
            sphere(n + "_FlowerLeaf", "bush", (x, -1.0, 1.05), 0.45, sub=1, scale=(1, 1, 0.7))
            O.flower(n + "_Flower", ("flower_pink", "flower_yel", "flower_red")[k % 3], n + "_FlowerMid", "flower_yel",
                     O.pt((x + r.uniform(-0.2, 0.2), -1.25, 1.42)), Vector((0, -0.35, 1)).normalized(), r=0.26)
        wall_lantern(n, 4.0 * s, 5.2, -0.5)
        accent_bricks(n + "_BrickAccent", "brick_dark", lo, hi, 6.8, 8.8, -0.5, r, 5)
        accent_bricks(n + "_BrickAccent", "brick_light", lo, hi, 6.8, 8.8, -0.5, r, 4)
    fbox(n + "_Wall", "brick", -3, 7, -0.5, 3, H, 0)
    # the shop door: green frame, glass upper half, a brass handle, a little bell
    with at(0, -0.3, 0):
        fbox(n + "_DoorFrame", "awning_green", -3.0, 0, -0.35, -2.6, 7.0, 0.1, bevel=0.05)
        fbox(n + "_DoorFrame", "awning_green", 2.6, 0, -0.35, 3.0, 7.0, 0.1, bevel=0.05)
        fbox(n + "_DoorFrame", "awning_green", -3.0, 6.6, -0.35, 3.0, 7.0, 0.1, bevel=0.05)
        for (a, b2) in ((-2.6, -0.05), (0.05, 2.6)):
            fbox(n + "_Door", "awning_green", a, 0, -0.15, b2, 6.6, 0.0)
            fbox(n + "_Glass", "glass_blue", a + 0.45, 3.2, -0.22, b2 - 0.45, 6.1, -0.12)
        for s in (-1, 1):
            sphere(n + "_Brass", "brass", (s * 0.45, -0.32, 3.2), 0.16, sub=1)
        fbox(n + "_Gold", "gold", -0.05, 0, -0.18, 0.05, 6.6, -0.1)
    name_board(n, 0, 8.05, -0.75 + 0.15, 9.0, 1.7, look="awning_green")
    # striped awning over the front (green / white), sloping out, with a scalloped valance
    g = 12
    for i in range(g):
        x0, x1 = -23 + 46 * i / g, -23 + 46 * (i + 1) / g
        lk, nm = ("awning_green", n + "_Awning") if i % 2 == 0 else ("white", n + "_AwningW")
        if abs((x0 + x1) / 2) < 3.6:
            continue
        poly(nm, lk, [(x0, -0.5, 8.0), (x1, -0.5, 8.0), (x1, -4.8, 6.8), (x0, -4.8, 6.8)], thick=0.12)
        xm = (x0 + x1) / 2
        poly(nm, lk, [(xm + (x1 - x0) / 2 * math.cos(math.pi * (1 - j / 6)), -4.82, 6.8 - 0.55 * math.sin(math.pi * j / 6)) for j in range(7)],
             thick=0.1)
    for s in (-1, 1):
        tube(n + "_Iron", "iron", [(s * 23, -0.5, 8.1), (s * 23, -4.9, 6.75)], 0.07, segs=5)
    # cornice, roof deck, parapet with coping and little urns
    B.cornice(n, 0, DEPTH / 2, H - 0.3, 48.4, DEPTH + 1.0, look="marble")
    fbox(n + "_Roof", "stone_mid", -24, H, 0, 24, H + 0.3, DEPTH)
    for (x0, z0, x1, z1) in ((-24.4, -0.6, 24.4, 0.0), (-24.4, DEPTH - 0.2, 24.4, DEPTH + 0.4), (-24.4, -0.6, -23.8, DEPTH + 0.4),
                             (23.8, -0.6, 24.4, DEPTH + 0.4)):
        fbox(n + "_Parapet", "brick", x0, H + 0.6, z0, x1, H + 1.6, z1)
        fbox(n + "_Coping", "marble", x0 - 0.15, H + 1.6, z0 - 0.15, x1 + 0.15, H + 1.9, z1 + 0.15, bevel=0.06)
    for x in (-24.1, -8, 8, 24.1):
        lathe(n + "_Urn", "marble", [(0.45, 0), (0.35, 0.2), (0.6, 0.6), (0.55, 0.9), (0.4, 1.0, True), (0.0, 1.0)], segs=12, c=(x, -0.3, H + 1.9))
    # side windows (both sides) + side wall accents
    for s in (-1, 1):
        with at(s * 24.4, 0, 0, rz=90 * s):
            for y in (5.0, 14.0):  # (local x runs into the plot on the +X wall, out of it on the -X wall)
                B.window(n + "Win", y * s, 2.2, 3.0, 3.8, arch=True, shutters="awning_green")
    # rooftop café (bought area CafeTerrace): three tables, a planter of flowers, string lights
    with at(prefix="StorefrontCafe_"):
        for x in (-14, 0, 14):
            with at(x, 10, H + 0.3, rz=90, s=0.9):
                PR.cafe_table()
        with at(-16, 17.5, H + 0.3, s=0.9):
            PR.flower_bed()
        pts = [(-23.6, 2, H + 4.6)] + [(-23.6 + 47.2 * i / 10, 2 + 0.0, H + 4.6 - 0.5 * math.sin(math.pi * i / 10)) for i in range(1, 10)] + [(23.6, 2, H + 4.6)]
        tube("Lights", "iron", pts, 0.035, segs=4, cap=False)
        for p in pts[1:-1]:
            sphere("Bulbs", "bulb_glow", (p[0], p[1], p[2] - 0.2), 0.16, sub=1)
        for s in (-1, 1):
            cyl("Lights", "iron", (s * 23.6, 2, H + 0.3), 0.08, 4.4, segs=6)
    B.studtop(n, "stone_mid", -23.6, 23.6, 0.4, 20.6, H + 0.3)


# ------------------------------------------------------------------ shared pieces for the taller fronts
def fpost(name, look, x, z, y0, y1, r, segs=16):
    cyl(name, look, (x, z, y0), r, y1 - y0, segs=segs)


def fdisc(name, look, x, z, y, r, h, segs=24):
    cyl(name, look, (x, z, y), r, h, segs=segs)


def floor_plate(n, y, look="marble"):
    fbox(n + "_Floor", look, -24.4, y - 0.45, -0.4, 24.4, y + 0.45, DEPTH + 0.4, bevel=0.06)


def glass_front(n, y0, y1, mullion="white", door=False, glass="glass", every=6.0):
    """A glazed street front from y0 to y1: glass, mullions every `every`, a head bar; a door gap x -3..3 if door."""
    if door:
        fbox(n + "_Glass", glass, -24, y0, -0.45, -3, y1, -0.3)
        fbox(n + "_Glass", glass, 3, y0, -0.45, 24, y1, -0.3)
        fbox(n + "_Glass", glass, -3, 7.5, -0.45, 3, y1, -0.3)
        for sx in (-1, 1):
            fbox(n + "_Mullion", mullion, sx * 3 - 0.3, y0, -0.8, sx * 3 + 0.3, 7.8, 0, bevel=0.05)
        fbox(n + "_Mullion", mullion, -3.3, 7.5, -0.8, 3.3, 7.9, 0, bevel=0.05)
        for (a2, b2) in ((-2.9, -0.05), (0.05, 2.9)):  # glass double doors with a gold push bar
            fbox(n + "_Door", glass, a2, 0, -0.4, b2, 7.4, -0.3)
            fbox(n + "_DoorBar", "gold", a2 + 0.4, 3.4, -0.55, b2 - 0.4, 3.6, -0.4, bevel=0.04)
    else:
        fbox(n + "_Glass", glass, -24, y0, -0.45, 24, y1, -0.3)
    x = -18.0
    while x <= 18.01:
        if not (door and abs(x) < 4):
            fbox(n + "_Mullion", mullion, x - 0.2, y0, -0.8, x + 0.2, y1, -0.35, bevel=0.04)
        x += every
    fbox(n + "_Mullion", mullion, -24.2, y1 - 0.35, -0.8, 24.2, y1 + 0.05, -0.3, bevel=0.04)
    for k in range(4):  # shine streaks
        x = -21 + k * 12.5
        poly(n + "_Shine", "white", [(x, -0.5, y0 + 1.5), (x + 0.6, -0.5, y0 + 1.5), (x + 2.2, -0.5, y1 - 1.5), (x + 1.6, -0.5, y1 - 1.5)],
             thick=0.02)


def showcase(n, y0, y1, count, mullion="gold"):
    """The street-facing gallery (FirmFeatures stands the best lawyers on its pedestals): glass + floor + back + band.
    The pedestals stay Parts (ShowcaseSlot) - previewed here."""
    glass_front(n + "Show", y0, y1, mullion=mullion)
    fbox(n + "_ShowFloor", "marble", -22, y0, 0, 22, y0 + 0.3, 5.2)
    fbox(n + "_ShowBack", "navy_dark", -24, y0, 5.2, 24, y1, 5.6)
    for i in range(count):
        x = -22 + 44 * (i + 0.5) / count
        fdisc("Preview_Pedestal", "marble", x, 2.6, y0 + 0.3, 1.4, 1.4)
        fdisc("Preview_PedestalRing", "gold", x, 2.6, y0 + 1.7, 1.5, 0.08)
        lathe(n + "_Spot", "iron", [(0.0, y1 - 0.2), (0.45, y1 - 0.25), (0.6, y1 - 0.75, True), (0.0, y1 - 0.75)], segs=10, c=(x, 2.6, 0))
    fbox(n + "_Gold", "gold", -24.2, y0 - 0.1, -0.85, 24.2, y0 + 0.5, -0.3, bevel=0.04)


def parapet(n, y, look, hw=24.4, z0=-0.4, cap="marble"):
    for (x0, a, x1, b2) in ((-hw, z0, hw, z0 + 0.6), (-hw, DEPTH - 0.2, hw, DEPTH + 0.4), (-hw, z0, -hw + 0.6, DEPTH + 0.4),
                            (hw - 0.6, z0, hw, DEPTH + 0.4)):
        fbox(n + "_Parapet", look, x0, y, a, x1, y + 1.2, b2)
        fbox(n + "_Coping", cap, x0 - 0.12, y + 1.2, a - 0.12, x1 + 0.12, y + 1.45, b2 + 0.12, bevel=0.05)


def roof_vents(n, y, spots):
    for (x, z) in spots:
        fbox(n + "_Vent", "iron_light", x - 1.2, y, z - 1.0, x + 1.2, y + 1.4, z + 1.0, bevel=0.12)
        fdisc(n + "_Vent", "iron", x, z, y + 1.4, 0.75, 0.25, segs=14)
        for k in range(3):
            fbox(n + "_VentGrille", "iron", x - 1.0, y + 0.3 + k * 0.35, z - 1.03, x + 1.0, y + 0.45 + k * 0.35, z - 1.0)


def sofa(n, look, x, z, y, w=10, rz=0.0):
    with at(x, z, y, rz=rz):
        box(n + "_Sofa", look, (0, 0, 0.55), (w, 3.0, 1.1), bevel=0.3, segs=2, smooth=True)
        box(n + "_Sofa", look, (0, 1.2, 1.5), (w, 0.7, 1.8), bevel=0.3, segs=2, smooth=True)
        for sx in (-1, 1):
            box(n + "_Sofa", look, (sx * (w / 2 - 0.35), 0, 1.25), (0.8, 3.0, 1.2), bevel=0.3, segs=2, smooth=True)
        for k in range(int(w // 2.6)):
            box(n + "_Cushion", "white" if look != "white" else "navy_roof", (-w / 2 + 1.8 + k * 2.6, 0.85, 1.75), (1.6, 0.4, 1.2),
                rot=(-12, 0, 0), bevel=0.25, segs=2, smooth=True)


# ================================================================== 3. MAIN STREET FIRM (sandstone + brick, 2 storeys)
def stage3():
    n, G, H = "MainStreet", 9.0, 18.0
    r = random.Random(3)
    entry(n, "stone_light")
    shell(n, H, "sand", "marble")
    for s in (-1, 1):
        a2, b2 = sorted((3 * s, 24 * s))
        fbox(n + "_Wall", "sand", a2, 0, -0.5, b2, G, 0)
        for y in (3.0, 6.0):  # rusticated courses
            fbox(n + "_Groove", "sand_dark", a2, y - 0.08, -0.56, b2, y + 0.08, -0.5)
        for x in (9, 15, 21):
            with at(x * s, -0.5, 0):
                B.window(n + "Win", 0, 2.2, 3.2, 4.8, arch=False, frame="white", shutters=None)
        lo, hi = sorted((7 * s, 23 * s))
        for x0 in (lo, (lo + hi) / 2 + 0.2):
            fbox(n + "_FlowerBox", "wood_deep", x0 + 0.2, 1.0, -1.5, x0 + (hi - lo) / 2 - 0.4, 1.7, -0.5, bevel=0.06)
        for k in range(16):
            x = lo + 0.8 + k * (hi - lo - 1.6) / 15
            sphere(n + "_FlowerLeaf", "bush", (x, -1.0, 1.75), 0.4, sub=1, scale=(1, 1, 0.7))
            O.flower(n + "_Flower", ("flower_red", "flower_white", "flower_yel")[k % 3], n + "_FlowerMid", "flower_yel" if k % 3 != 2 else "flower_orange",
                     O.pt((x, -1.2, 2.1)), Vector((0, -0.35, 1)).normalized(), r=0.24)
        # upper floor: brick returns at the corners
        a2, b2 = sorted((24 * s, 22.8 * s))
        fbox(n + "_Brick", "brick", a2, G, 0, b2, H, DEPTH)
        wall_lantern(n, 4.2 * s, 5.4, -0.5)
        with at(s * 24.4, 0, 0, rz=90 * s):
            for y in (5.0, 14.0):
                B.window(n + "Win", y * s, 2.2, 3.0, 4.0, arch=False)
                B.window(n + "Win", y * s, G + 2.0, 3.0, 4.6, arch=True)
    fbox(n + "_Wall", "sand", -3, 7.5, -0.5, 3, G, 0)
    with at(0, -0.5, 0):
        B.door(n + "Door", 0, 0, 5.8, 7.5, frame="marble", leaf="wood_deep", panel="wood_warm")
    floor_plate(n, G, "marble")
    fbox(n + "_Trim", "marble", -24.4, G - 0.2, -0.9, 24.4, G + 0.5, -0.3, bevel=0.06)
    showcase(n, G + 0.45, H, 3)
    fbox(n + "_Brick", "brick", -24, H - 1.2, -0.6, 24, H, 0)
    accent_bricks(n + "_BrickAccent", "brick_dark", -23, 23, H - 1.1, H - 0.1, -0.6, r, 8)
    B.cornice(n, 0, DEPTH / 2, H - 0.3, 48.4, DEPTH + 1.0, look="marble")
    fbox(n + "_Roof", "stone_mid", -24, H, 0, 24, H + 0.3, DEPTH)
    parapet(n, H + 0.6, "sand")
    roof_vents(n, H + 0.3, ((14, 14), (-15, 12)))
    # classic porch: four Tuscan columns, an entablature (the name sign goes on its face), a real pediment
    for x in (-8, -3, 3, 8):
        B.column(n + "Col", x, -4.5, 0.0, 9.0, r=0.75)
    fbox(n + "_Entab", "marble", -10, 9.0, -6.0, 10, 10.5, 0, bevel=0.08)
    fbox(n + "_Gold", "gold", -10.05, 9.05, -6.08, 10.05, 9.2, -5.9)
    B.gable(n, "marble", 0, -3.0, 10.5, 20.4, 3.4, 6.0, trim="marble", tympanum="sand")
    B.flag(n, 0, -3.5, 13.9, 3.2, look="flag_red", w=2.4, fh=1.4, seed=3)
    name_board(n, 0, 9.75, -6.35, 14.0, 1.25, look="wood_deep")
    # coffee counter (bought area CoffeeBreak), lobby back-left corner
    with at(prefix="MainStreetCoffee_"):
        fbox("Counter", "wood_warm", -18, 0, 17.5, -9, 3.2, 20, bevel=0.08)
        fbox("Top", "marble", -18.3, 3.2, 17.2, -8.7, 3.6, 20.3, bevel=0.06)
        fbox("Machine", "iron_light", -16.5, 3.6, 18.6, -14.5, 5.6, 19.8, bevel=0.15)
        fbox("Machine", "iron", -16.2, 4.0, 18.5, -14.8, 4.3, 18.6)
        box("Glow", "lamp_glow", (-15.5, 18.5, 5.0), (0.8, 0.06, 0.4))
        for k, x in enumerate((-13, -12, -11)):
            lathe("Cup", "white", [(0.0, 3.6), (0.22, 3.6), (0.28, 4.05), (0.24, 4.05, True), (0.18, 3.7)], segs=10, c=(x, 18.0, 0))
        fbox("Menu", "panel_black", -17.5, 5.5, 20.3, -9.5, 8.0, 20.4, bevel=0.05)
        text("COFFEE", "white", (-13.5, 20.28, 6.75), 0.8, extrude=0.02)
    B.studtop(n, "stone_mid", -23.6, 23.6, 0.4, 20.6, H + 0.3, skip=lambda x, y: (abs(x - 14) < 1.8 and abs(y - 14) < 1.6) or (abs(x + 15) < 1.8 and abs(y - 12) < 1.6))


# ================================================================== 4. GLASS OFFICE (four glass floors)
def stage4():
    n, F = "GlassOffice", 9.0
    entry(n, "stone_light")
    shell(n, 4 * F, "panel", "marble")
    glass_front(n + "Lobby", 0, F, door=True)
    floor_plate(n, F)
    showcase(n, F + 0.45, 2 * F, 6, mullion="white")
    floor_plate(n, 2 * F)
    glass_front(n + "F3", 2 * F + 0.45, 3 * F)
    floor_plate(n, 3 * F)
    glass_front(n + "F4", 3 * F + 0.45, 4 * F)
    for y in (F, 2 * F, 3 * F):  # white spandrel bands between the floors
        fbox(n + "_Spandrel", "white", -24.3, y - 0.6, -0.95, 24.3, y + 0.6, -0.4, bevel=0.08)
    floor_plate(n, 4 * F, "stone_mid")
    parapet(n, 4 * F + 0.45, "white")
    for s in (-1, 1):  # full-height fins
        a2, b2 = sorted((24.6 * s, 24 * s))
        fbox(n + "_Fin", "white", a2, -1.5, -1.6, b2 + (0.6 if s > 0 else -0.6) * 0, 4 * F + 1.8, 3, bevel=0.1)
        with at(s * 24.6, 0, 0, rz=90 * s):
            for y in (7, 14):
                for f in range(4):
                    B.window(n + "Win", y * s, f * F + 2.0, 3.2, 5.0, arch=False, mullions=False, sill=False)
    # canopy over the entrance with a glowing underside, on two slim posts
    fbox(n + "_Canopy", "white", -16, 8.5, -8, 16, 9.3, 0, bevel=0.2)
    fbox(n + "_CanopyGlow", "lamp_glow", -14, 8.38, -6.5, 14, 8.5, -1.5)
    for s in (-1, 1):
        fpost(n + "_Post", "iron", 14 * s, -7, -1.5, 8.5, 0.35)
    # lobby: reception desk + planters, floor 3 planters
    fbox(n + "_Reception", "navy_dark", -18, 0, 17.5, -9, 3, 19.5, bevel=0.15)
    fbox(n + "_ReceptionTop", "marble", -18.3, 3, 17.2, -8.7, 3.4, 19.8, bevel=0.08)
    with at(9, 18.8, 0):
        PR.planter_square()
    with at(-17, 17.5, 2 * F + 0.45, s=0.9):
        PR.planter_square()
    with at(9, 17.5, 2 * F + 0.45, s=0.9):
        PR.planter_square()
    # Law Library (bought area): five shelves of books | Conference Room: a table with eight chairs
    with at(prefix="GlassOfficeLibrary_"):
        for i in range(5):
            x0 = -22 + i * 7.6
            fbox("Shelf", "wood_deep", x0, 3 * F + 0.45, 16, x0 + 5, 4 * F - 1, 20, bevel=0.06)
            for k in range(4):
                y = 3 * F + 1.2 + k * 1.7
                for j in range(8):
                    lk = ("carpet_red", "navy_roof", "awning_green", "license_yel", "flag_purple")[(i + k + j) % 5]
                    hh = 1.0 + 0.15 * ((j * 7 + k) % 3)
                    fbox("Book" + lk.title().replace("_", ""), lk, x0 + 0.3 + j * 0.55, y, 15.75, x0 + 0.78 + j * 0.55, y + hh, 16.05)
    with at(prefix="GlassOfficeConference_"):
        fbox("Table", "wood_warm", -8, 3 * F + 2.0, 6, 8, 3 * F + 2.5, 10, bevel=0.15)
        for x in (-6, 6):
            fbox("Table", "iron", x - 0.3, 3 * F + 0.45, 7.7, x + 0.3, 3 * F + 2.0, 8.3)
        for x in (-6, -2, 2, 6):
            for z, rz in ((4.8, 0), (11.2, 180)):
                with at(x, z, 3 * F + 0.45, rz=rz):
                    box("Chair", "navy_dark", (0, 0, 1.0), (1.2, 1.2, 0.3), bevel=0.1)
                    box("Chair", "navy_dark", (0, -0.55, 1.75) if rz == 0 else (0, -0.55, 1.75), (1.2, 0.2, 1.3), bevel=0.08)
                    cyl("ChairLeg", "iron", (0, 0, 0), 0.08, 1.0, segs=6)
    with at(0, -0.3, 0):
        name_board(n, 0, 4 * F + 1.5, -0.3, 16.0, 1.8, look="navy_dark")
    roof_vents(n, 4 * F + 0.45, ((14, 12), (-14, 14), (0, 16)))
    B.studtop(n, "stone_mid", -23.6, 23.6, 0.4, 20.6, 4 * F + 0.45,
              skip=lambda x, y: any(abs(x - a2) < 1.8 and abs(y - b2) < 1.6 for a2, b2 in ((14, 12), (-14, 14), (0, 16))))


# ================================================================== 5. CORPORATE HQ (atrium, terraces, roof garden)
def stage5():
    n, F = "CorporateHQ", 9.0
    entry(n, "stone_light")
    shell(n, 4 * F, "white", "panel")
    glass_front(n + "Atrium", 0, 2 * F, door=True)
    for (x0, x1) in ((-12, -17), (-12, -7), (12, 17), (12, 7)):  # two white Vs in front of the atrium glass
        tube(n + "_VBeam", "white", [(x0, -1.3, 0.0), (x1, -1.3, 2 * F)], 0.75, segs=12)
    for x in (-12, 12):
        fbox(n + "_VFoot", "panel", x - 1.3, -1.5, -2.3, x + 1.3, 0.8, -0.2, bevel=0.15)
    fbox(n + "_BeamCap", "white", -25, 2 * F - 0.6, -2.0, 25, 2 * F + 0.6, 0, bevel=0.15)
    with at(prefix="CorporateHQCafe_"):  # AtriumCafe (bought area)
        fbox("Bar", "white", -18, 0, 16.5, -8, 3.3, 19.5, bevel=0.15)
        fbox("BarTop", "wood_warm", -18.4, 3.3, 16.1, -7.6, 3.7, 19.9, bevel=0.08)
        for x in (-16, -12.5, -9.5):
            lathe("Stool", "iron", [(0.5, 0.0), (0.5, 0.1, True), (0.1, 0.2), (0.1, 2.0), (0.0, 2.0)], segs=10, c=(x, 15.5, 0))
            cyl("StoolSeat", "booth_orange" if "booth_orange" in O.K.PAL else "egg_orange", (x, 15.5, 2.0), 0.6, 0.25, segs=14)
        fbox("Lamp", "lamp_glow", -14, 7, 17.5, -12, 7.4, 18.5)
    floor_plate(n, 2 * F)
    showcase(n, 2 * F + 0.45, 3 * F, 9)
    floor_plate(n, 3 * F)
    glass_front(n + "Lounge", 3 * F + 0.45, 4 * F)
    with at(prefix="CorporateHQLounge_"):  # ExecLounge (bought area; its carpet stays a Part: LoungeFloor)
        for x in (-16, 0, 16):
            sofa("Lounge", "navy_roof", x, 11.6, 3 * F + 0.6, w=10)
            fbox("Table", "wood_warm", x - 2, 3 * F + 0.6, 6.5, x + 2, 3 * F + 1.6, 8.5, bevel=0.15)
        fbox("Glow", "lamp_glow", -22, 3 * F + 1, 19.5, 22, 4 * F - 1, 20.3)
        fbox("Preview_Carpet", "carpet_red", -23, 3 * F + 0.45, 0.5, 23, 3 * F + 0.6, DEPTH - 1)
    floor_plate(n, 4 * F)
    # floors 5-6: a glass box stepped back 6, a planted terrace in front
    fbox(n + "_UpperGlass", "glass_dark", -21, 4 * F, 6, 21, 6 * F, 6.5)
    for x in range(-18, 19, 6):
        fbox(n + "_Mullion", "white", x - 0.2, 4 * F, 5.7, x + 0.2, 6 * F, 6.1, bevel=0.04)
    for s in (-1, 1):
        a2, b2 = sorted((21 * s, 20.4 * s))
        fbox(n + "_UpperGlass", "glass_dark", a2, 4 * F, 6, b2, 6 * F, DEPTH)
    fbox(n + "_Band", "white", -21.3, 5 * F - 0.45, 5.6, 21.3, 5 * F + 0.45, DEPTH, bevel=0.08)
    fbox(n + "_Band", "white", -21.3, 6 * F - 0.45, 5.6, 21.3, 6 * F + 0.45, DEPTH, bevel=0.08)
    fbox(n + "_Deck", "wood_warm", -24, 4 * F + 0.45, 0, 24, 4 * F + 0.8, 6)
    for k in range(24):
        fbox(n + "_DeckGap", "wood_deep", -24 + k * 2.0, 4 * F + 0.8, 0.05, -24 + k * 2.0 + 0.06, 4 * F + 0.82, 5.95)
    fbox(n + "_RailGlass", "glass_blue", -24, 4 * F + 0.8, -0.2, 24, 4 * F + 2.2, 0.0)
    fbox(n + "_RailTop", "white", -24, 4 * F + 2.2, -0.3, 24, 4 * F + 2.5, 0.3, bevel=0.06)
    for x in (-16, 0, 16):
        with at(x, 2.6, 4 * F + 0.8, s=0.85):
            PR.flower_bed()
    with at(prefix="CorporateHQGarden_"):  # RoofGarden (bought area)
        fbox("Lawn", "grass_ov", -20, 6 * F + 0.45, 7, 20, 6 * F + 0.7, 20)
        for x in (-16, 16):
            with at(x, 13, 6 * F + 0.7):
                cyl("Trunk", "wood_deep", (0, 0, 0), 0.45, 3.0, segs=10)
                leafy("Tree%d" % x, [((0, 0, 4.2), 2.1), ((1.0, 0.4, 3.6), 1.4), ((-0.9, -0.3, 3.8), 1.4)], look="bush", voxel=0.3, faces=600,
                      lumpy=0.3, seed=x)
        for x in (-9, 9):
            with at(x, 18.5, 6 * F + 0.7, rz=180):
                PR.bench()
    parapet(n, 6 * F + 0.45, "white", hw=21.3, z0=5.6)
    fdisc("Preview_HologramPad", "marble", 0, 13.5, 6 * F + 0.45, 4.5, 0.6)
    lathe(n + "_HoloRing", "halo_glow", [(4.5, 6 * F + 1.05), (4.75, 6 * F + 1.1), (4.75, 6 * F + 1.25), (4.5, 6 * F + 1.3)], segs=32)
    fbox(n + "_SignBand", "gold", -14, 3 * F - 2.6, -0.65, 14, 3 * F - 0.4, -0.25, bevel=0.08)
    B.studtop(n, "wood_warm", -23.6, 23.6, 0.2, 5.8, 4 * F + 0.8, skip=lambda x, y: any(abs(x - a2) < 3.9 for a2 in (-16, 0, 16)) and 1.0 < y < 4.2)


# ================================================================== 6. SUPREME TOWER (prestige)
def stage6():
    n, F = "SupremeTower", 9.6
    entry(n, "marble")
    shell(n, 2 * F, "stone_light", "gold")
    glass_front(n + "Lobby", 0, F, door=True, mullion="gold")
    floor_plate(n, F, "gold")
    showcase(n, F + 0.45, 2 * F, 12)
    floor_plate(n, 2 * F, "gold")
    # gold canopy on turned gold columns, glowing underside
    fbox(n + "_Canopy", "gold", -14, 8.6, -9, 14, 9.6, 0, bevel=0.2)
    fbox(n + "_CanopyGlow", "lamp_glow", -12, 8.48, -8, 12, 8.6, -2)
    for s in (-1, 1):
        lathe(n + "_Column", "gold", [(0.9, -1.5), (0.9, -1.0, True), (0.7, -0.8), (0.6, 7.6), (0.8, 8.0), (0.95, 8.6, True), (0.0, 8.6)], segs=16,
              c=(12 * s, -8, 0))
    T0, T1 = 2 * F + 0.45, 2 * F + 0.45 + 108
    # the tower: four glass walls (hollow - the rooms of Config.Floors.Slots[6] stand on its bands), gold every 3rd band
    fbox(n + "_TowerGlass", "glass_dark", -20, T0, 2, 20, T1, 2.6)
    fbox(n + "_TowerGlass", "glass_dark", -20, T0, 18.4, 20, T1, 19)
    fbox(n + "_TowerGlass", "glass_dark", -20, T0, 2.6, -19.4, T1, 18.4)
    fbox(n + "_TowerGlass", "glass_dark", 19.4, T0, 2.6, 20, T1, 18.4)
    for k in range(13):
        y = T0 + (T1 - T0) * k / 12
        fbox(n + ("_BandGold" if k % 3 == 0 else "_Band"), "gold" if k % 3 == 0 else "navy_dark", -20.4, y - 0.35, 1.6, 20.4, y + 0.35, 19.4, bevel=0.06)
    for i in range(11):
        x = -20 + i * 4
        fbox(n + "_Mullion", "navy_dark", x - 0.15, T0, 1.6, x + 0.15, T1, 2.1)
    for s in (-1, 1):  # gold corner fins, full height
        for z in (1.6, 19.4):
            fbox(n + "_Fin", "gold", s * 20 - 0.5, T0 - 0.4, z - 0.5, s * 20 + 0.5, T1 + 0.6, z + 0.5, bevel=0.1)
    with at(prefix="SupremeTowerSuite_"):  # PartnerSuite (bought area): the lit penthouse
        fbox("Glow", "lamp_glow", -19.6, T1 - 18, 1.7, 19.6, T1 - 0.4, 2.2)
    with at(prefix="SupremeTowerCourt_"):  # PrivateCourt (bought area)
        fbox("Panel", "court_wood" if "court_wood" in O.K.PAL else "wood_warm", -19.6, T0 + 45, 1.7, 19.6, T0 + 54, 2.2)
    # the crown: stepped gold tiers with gems, the helipad, the spire with a red beacon
    fbox(n + "_Crown", "gold", -18, T1, 3, 18, T1 + 5, 18, bevel=0.2)
    fbox(n + "_CrownTier", "gold_dark", -18.6, T1 + 4.6, 2.4, 18.6, T1 + 5.2, 18.6, bevel=0.12)
    for i in range(9):
        x = -16 + i * 4
        prism(n + "_CrownSpike", "gold", [(x - 1.2, T1 + 5.2), (x + 1.2, T1 + 5.2), (x, T1 + 7.6)], 0.8, c=(0, 2.8, 0))
        sphere(n + "_Gem", ("carpet_red", "speed_blue", "awning_green")[i % 3], (x, 2.3, T1 + 2.5), 0.55, sub=1)
    fbox(n + "_CrownRail", "gold", -18, T1 + 5, 3, 18, T1 + 6, 3.4)
    fdisc(n + "_Helipad", "iron", 9, 10.5, T1 + 5, 6.8, 0.8, segs=32)
    lathe(n + "_HeliRing", "hazard" if "hazard" in O.K.PAL else "gold", [(5.4, T1 + 5.8), (5.8, T1 + 5.8), (5.8, T1 + 5.86), (5.4, T1 + 5.86)], segs=32)
    for (x0, z0, x1, z1) in ((7.8, 8.5, 8.4, 12.5), (9.6, 8.5, 10.2, 12.5), (8.4, 10.2, 9.6, 10.8)):
        fbox(n + "_HeliH", "white", x0, T1 + 5.8, z0, x1, T1 + 5.9, z1)
    fdisc("Preview_HologramPad", "gold", -9, 10.5, T1 + 5, 4.5, 0.6)
    lathe(n + "_Spire", "gold", [(0.9, T1 + 5), (0.9, T1 + 6.0, True), (0.6, T1 + 6.5), (0.45, T1 + 20), (0.3, T1 + 30.5), (0.0, T1 + 31)], segs=12,
          c=(-15, 15, 0))
    sphere(n + "_Beacon", "heat_glow", (-15, 15, T1 + 31.6), 0.7, sub=2)
    name_board(n, 0, 2 * F - 1.8, -1.05, 18.0, 1.9, look="panel_black")
    B.studtop(n, "gold", -23.6, 23.6, 0.4, 1.4, 2 * F + 0.45)


O.K.PAL.update({"license_yel": (255, 200, 40), "speed_blue": (64, 150, 255), "hazard": (255, 204, 40), "court_wood": (150, 92, 52),
                "booth_orange": (255, 150, 40)})
from ohkit import leafy
STAGES = {2: stage2, 3: stage3, 4: stage4, 5: stage5, 6: stage6}


def lot(x0):
    """A plot around the firm: grass, the street in front, the office hall's floor behind (preview only)."""
    box("Preview_Ground", "grass_ov", (x0, 10, -1.6), (90, 110, 0.2))
    box("Preview_Street", "iron", (x0, -18, -1.55), (90, 14, 0.2))
    box("Preview_Hall", "plaza", (x0, 40, -0.1), (48, 38, 0.2))


def main():
    O.reset()
    O.scene(sun_rot=(50, 8, -38))
    for k in ONLY:
        if k not in STAGES:
            continue
        x0 = (k - 2) * 200
        with O.region("stage%d" % k):
            with at(x0, 0, 0):
                STAGES[k]()
            lot(x0)
            O.player(x0 + 6, -9, -1.5)
    O.stats()
    for k in ONLY:
        if k not in STAGES:
            continue
        x0 = (k - 2) * 200
        d, tall, lz = {2: (60, 12, 5.5), 3: (64, 20, 8.5), 4: (76, 38, 18), 5: (102, 56, 27), 6: (165, 160, 74)}[k]
        res = (1000, 1600) if k == 6 else (1600, 900)
        O.render(OUT, "firm%d_three_quarter" % k, (x0 + d * 0.6, -d * 0.8, tall * 0.4 + 8), (x0, 6, lz), lens=30, res=res, show=["stage%d" % k])
        O.render(OUT, "firm%d_front" % k, (x0, -d, lz * 0.6 + 4), (x0, 4, lz), lens=30, res=res, show=["stage%d" % k])
        O.render(OUT, "firm%d_street" % k, (x0 - 16, -26, 5.0), (x0 - 2, 2, 7.5), lens=26, show=["stage%d" % k])


if __name__ == "__main__":
    main()
