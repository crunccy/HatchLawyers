# tools/blender/overhaul/firm_hall.py - MAP MODEL OVERHAUL stage 4: the firm's OFFICE HALL kit (crnuch's calls 2026-10-24,
# CLAUDE.md "MODEL OVERHAUL"): ServerStorage.Templates.FirmKitParts' OfficeSegment, LawyerDesk, ExpansionLock and BackWall,
# remade as meshes with today's sizes (measured in Studio 2026-10-24):
#   OfficeSegment 48 x 11 (z 0..11): floor at y 0 (the plot's ground is 1.5 lower), white half-walls 5 tall at x +-23.6 with a
#     cap rail and planter boxes, a post at each segment line (z 0), a carpet runner down the aisle (x -4..4).
#   LawyerDesk (desk frame = FirmBuilder.slotFrame): +X faces the client / the aisle, the lawyer stands at -X, the long side
#     runs along Z; top 2.8 x 0.45 x 5.6 with its surface at y 2.645 (DeskLook's TOP_Y), rug on the client side.
#   ExpansionLock: the next segment while it's locked (a building site behind a striped barrier).
#   BackWall: the hall's end wall (bookshelves, the gold scales emblem).
# Named per colour so the scripts can recolour by NAME at install (DeskLook tells today's parts apart by size; dressHall
# restyles the hall walls per stage): <Piece>_Wall / _Cap / _Post (hall), Desk_Top / _Body / _Handle / _Trim (desk).
# Blender: X = firm x, Y = firm z (into the plot), Z = up.
#   Blender -b --factory-startup --python tools/blender/overhaul/firm_hall.py -- <out_dir>
import bpy, math, os, sys, random
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ohkit as O
import ohbuild as B
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text, leafy, flowers_on
import props as PR

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else os.path.join(HERE, "renders")
os.makedirs(OUT, exist_ok=True)
O.K.PAL.update({"floor_a": (226, 160, 98), "floor_b": (210, 144, 84), "hazard": (255, 204, 40), "cone": (255, 120, 30),
                "book_red": (220, 60, 60), "book_blue": (60, 120, 220), "book_green": (70, 170, 90), "book_yel": (250, 200, 60),
                "lamp_shade": (60, 160, 90), "laptop": (52, 56, 70)})
O.K.GLOWS.update({"screen_glow": ((120, 220, 255), 1.2)})


def planks(n, x0, x1, y0, y1, z, w=1.5):
    k, x = 0, x0
    while x < x1 - 0.01:
        xe = min(x + w, x1)
        box(n + ("_FloorA" if k % 2 == 0 else "_FloorB"), "floor_a" if k % 2 == 0 else "floor_b", ((x + xe) / 2, (y0 + y1) / 2, z - 0.1),
            (xe - x - 0.04, y1 - y0, 0.2), bevel=0.03)
        x, k = xe, k + 1


def carpet(n, y0, y1, look="carpet_red"):
    box(n + "_Carpet", look, (0, (y0 + y1) / 2, 0.03), (8.0, y1 - y0, 0.06))
    for sx in (-4.15, 4.15):
        box(n + "_Gold", "gold", (sx, (y0 + y1) / 2, 0.04), (0.3, y1 - y0, 0.08))


def half_wall(n, y0, y1, planter=True, seed=0):
    """The hall's side half-walls (x +-23.6): panelled white wainscot, a wood baseboard, a cap rail; planter boxes."""
    for s in (-1, 1):
        x = s * 23.6
        box(n + "_Wall", "white", (x, (y0 + y1) / 2, 2.5), (0.8, y1 - y0, 5.0))
        box(n + "_Footing", "stone_mid", (x, (y0 + y1) / 2, -0.75), (1.1, y1 - y0, 1.5), bevel=0.06)
        box(n + "_Base", "wood_warm", (x - s * 0.45, (y0 + y1) / 2, 0.5), (0.12, y1 - y0, 1.0), bevel=0.03)
        for k in range(int((y1 - y0) // 3.6)):  # raised panels on the inner face
            y = y0 + 1.9 + k * 3.6
            box(n + "_Panel", "trim_cream", (x - s * 0.44, y, 2.9), (0.08, 2.8, 2.6), bevel=0.05)
        box(n + "_Cap", "wood_warm", (x, (y0 + y1) / 2, 5.15), (1.4, y1 - y0, 0.4), bevel=0.08)
        if planter:
            with at(x, (y0 + y1) / 2, 5.35):
                box(n + "_Planter", "wood_deep", (0, 0, 0.3), (1.3, 3.4, 0.6), bevel=0.08)
                obs = leafy(n + "_PlanterBush%d" % (s + seed), [((0, -0.9, 0.85), 0.62), ((0, 0.1, 0.9), 0.7), ((0, 1.0, 0.82), 0.6)],
                            voxel=0.15, faces=380, lumpy=0.1, seed=seed + s)
                flowers_on(obs, n + "_Flower", "flower_pink", n + "_FlowerMid", "flower_yel", [(0, y, 3) for y in (-1.1, -0.3, 0.5, 1.2)], r=0.2)
        # shrubs outside the wall, on the plot's ground (1.5 below the floor)
        with at(s * 25.2, (y0 + y1) / 2, -1.5):
            leafy(n + "_Shrub%d" % (s + seed), [((0, -2.2, 0.5), 0.95), ((0.2, -1.2, 0.6), 1.0), ((-0.1, 2.0, 0.45), 0.9), ((0, 2.9, 0.4), 0.75)],
                  voxel=0.2, faces=520, lumpy=0.18, seed=seed + 7 + s)


def post(n, y):
    for s in (-1, 1):
        lathe(n + "_Post", "wood_deep", [(0.85, -1.5), (0.85, 0.2, True), (0.7, 0.4), (0.62, 5.8), (0.8, 6.0, True), (0.0, 6.0)], segs=12,
              c=(s * 23.5, y, 0))
        cyl(n + "_Gold", "gold", (s * 23.5, y, 6.0), 0.9, 0.25, segs=12)
        sphere(n + "_Gold", "gold", (s * 23.5, y, 6.6), 0.4, sub=1)


# ================================================================== the segment
def office_segment(n="HallSegment", seed=0):
    planks(n, -23.2, 23.2, 0, 11, 0.0)
    carpet(n, 0, 11)
    half_wall(n, 0, 11, seed=seed)
    post(n, 0)


# ================================================================== the lawyer's desk
def lawyer_desk(n="Desk"):
    """Desk frame: +X = the client's side (the aisle), -X = the lawyer's, long side along Y (firm z)."""
    for y in (-1.8, 1.8):
        box(n + "_Body", "wood_warm", (0, y, 1.1), (2.3, 1.5, 2.2), bevel=0.1)
        for k, z in enumerate((0.6, 1.5)):  # drawers on the lawyer's side
            box(n + "_Drawer", "wood_deep", (-1.16, y, z), (0.06, 1.25, 0.75), bevel=0.03)
            box(n + "_Handle", "gold", (-1.24, y, z), (0.1, 0.55, 0.14), bevel=0.03)
    box(n + "_Body", "wood_warm", (0.9, 0, 1.45), (0.3, 2.1, 1.7), bevel=0.05)      # modesty panel (client side)
    box(n + "_Front", "gold", (1.08, 0, 1.45), (0.06, 1.4, 0.9), bevel=0.02)
    box(n + "_Top", "wood_deep", (0, 0, 2.42), (2.8, 5.6, 0.45), bevel=0.12, segs=2)
    box(n + "_Trim", "gold", (1.42, 0, 2.42), (0.06, 5.4, 0.2))                       # (DeskLook: the gold band)
    # laptop (open, facing the lawyer), papers + pen cup, a mug, a banker's lamp, a name plate for the client
    with at(-0.2, 0.9, 2.645):
        box(n + "_Laptop", "laptop", (0, 0, 0.05), (1.1, 1.5, 0.1), bevel=0.03)
        box(n + "_Laptop", "laptop", (0.55, 0, 0.5), (0.08, 1.5, 0.95), rot=(0, -10, 0), bevel=0.03)
        box(n + "_Screen", "screen_glow", (0.5, 0, 0.5), (0.02, 1.32, 0.78), rot=(0, -10, 0))
    with at(0.1, -1.3, 2.645):
        for k in range(3):
            box(n + "_Paper", "white", (0, 0, 0.04 + k * 0.05), (1.0, 1.25, 0.05), rot=(0, 0, k * 7 - 7))
        cyl(n + "_PenCup", "iron", (-0.6, -0.5, 0), 0.18, 0.45, segs=10)
        for k, lk in enumerate(("book_red", "book_blue")):
            tube(n + "_Pen" + lk.title().replace("_", ""), lk, [(-0.6 + k * 0.06, -0.5, 0.3), (-0.55 + k * 0.12, -0.45, 0.75)], 0.035, segs=4)
    lathe(n + "_Mug", "white", [(0.0, 2.645), (0.22, 2.645), (0.24, 3.1), (0.2, 3.1, True), (0.18, 2.75)], segs=12, c=(-0.6, -2.15, 0))
    tube(n + "_Mug", "white", [(-0.38, -2.15, 3.0), (-0.24, -2.15, 2.95), (-0.24, -2.15, 2.8), (-0.38, -2.15, 2.75)], 0.04, segs=4)
    with at(0.85, 2.2, 2.645):
        lathe(n + "_Lamp", "brass", [(0.32, 0.0), (0.32, 0.08, True), (0.1, 0.14), (0.06, 0.8), (0.0, 0.8)], segs=12)
        box(n + "_LampShade", "lamp_shade", (0, 0, 0.95), (0.5, 0.9, 0.32), bevel=0.14, segs=2, smooth=True)
        box(n + "_Glow", "lamp_glow", (0, 0, 0.78), (0.4, 0.75, 0.04))
    with at(1.25, 0, 2.645):
        prism(n + "_Plate", "brass", [(-0.18, 0), (0.18, 0), (0.04, 0.32), (-0.1, 0.32)], 1.3)
    box(n + "_Rug", "speed_blue" if "speed_blue" in O.K.PAL else "navy_roof", (2.9, 0, 0.03), (2.6, 3.6, 0.06), bevel=0.02)
    # the lawyer's chair (behind, at -X)
    with at(-2.0, 0, 0):
        lathe(n + "_Chair", "iron", [(0.9, 0.0), (0.9, 0.1, True), (0.12, 0.2), (0.1, 1.3), (0.0, 1.3)], segs=10)
        box(n + "_ChairSeat", "navy_dark", (0, 0, 1.45), (1.3, 1.4, 0.35), bevel=0.15, segs=2, smooth=True)
        box(n + "_ChairSeat", "navy_dark", (-0.6, 0, 2.4), (0.3, 1.4, 1.7), bevel=0.15, segs=2, smooth=True)


# ================================================================== the locked segment (building site)
def cone(n, c):
    with at(*c):
        box(n + "_ConeBase", "iron", (0, 0, 0.08), (1.1, 1.1, 0.16), bevel=0.04)
        cyl(n + "_Cone", "cone", (0, 0, 0.16), 0.42, 1.3, segs=12, r_top=0.08)
        cyl(n + "_ConeBand", "white", (0, 0, 0.62), 0.33, 0.22, segs=12, r_top=0.29)


def expansion_lock(n="ExpansionLock"):
    planks(n, -23.2, 23.2, 0, 11, 0.0)
    for (x, y, w, d) in ((19.1, 8.1, 8.2, 5.8), (0.5, 8.6, 11, 4.8), (-17.0, 3.1, 6, 2.6), (-11.0, 9.0, 6, 2.0), (-21.1, 8.5, 4.2, 5.0)):
        box(n + "_Dirt", "soil", (x, y, 0.03), (w, d, 0.08), bevel=0.04)
    half_wall(n, 0, 11, planter=False, seed=3)
    post(n, 0)
    # the barrier across the front: posts with striped boards (yellow / black) and a hanging sign
    for x in (-22.8, -18.0, -13.0, -8.0, -3.2, 3.2, 8.0, 13.0, 18.0, 22.8):
        box(n + "_BarrierPost", "wood_deep", (x, 0.6, 1.3), (0.6, 0.6, 2.6), bevel=0.06)
    for x0, x1 in ((-22.8, -3.2), (3.2, 22.8)):
        for z in (1.1, 2.0):
            k, x = 0, x0
            while x < x1 - 0.01:
                xe = min(x + 2.0, x1)
                box(n + ("_Hazard" if k % 2 == 0 else "_HazardBlack"), "hazard" if k % 2 == 0 else "panel_black", ((x + xe) / 2, 0.6, z),
                    (xe - x, 0.35, 0.5), bevel=0.04)
                x, k = xe, k + 1
    with at(0, 0.6, 0):  # the sign on two posts in the gap
        for sx in (-2.0, 2.0):
            box(n + "_BarrierPost", "wood_deep", (sx, 0.15, 1.88), (0.4, 0.4, 3.76), bevel=0.05)  # (tops 0.04 under the sign's: their bevels shared a plane)
        box(n + "_Sign", "hazard", (0, 0, 3.0), (5.0, 0.2, 1.6), bevel=0.1)
        text("COMING SOON", "panel_black", (0, -0.12, 3.0), 0.6, extrude=0.015)
    for c in ((5.0, 1.8, 0), (-5.0, 1.8, 0), (11.5, 6.0, 0), (-11.0, 2.6, 0), (23.0, 1.6, 0)):
        cone(n, c)
    for (x, y, sz) in ((20.0, 4.3, 2.2), (17.6, 4.6, 1.8), (19.4, 4.4, 1.6), (-20.6, 5.0, 1.6), (-18.4, 5.4, 2.0), (-18.6, 5.5, 1.4), (15.6, 5.8, 1.4)):
        zb = 0.0 if not (x == 19.4 or x == -18.6) else (2.2 if x == 19.4 else 2.0)
        with at(x, y, zb, rz=(x * 7) % 30):
            box(n + "_Crate", "plank_light", (0, 0, sz / 2), (sz * 0.9, sz * 0.9, sz * 0.9))
            for a in (-1, 1):
                for b2 in (-1, 1):
                    box(n + "_CrateFrame", "wood_deep", (a * sz * 0.45, b2 * sz * 0.45, sz / 2), (sz * 0.14, sz * 0.14, sz), bevel=0.03)
            box(n + "_CrateFrame", "wood_deep", (0, -sz * 0.46, sz / 2), (sz * 1.1, 0.06, sz * 0.12), rot=(0, 45, 0))
    for k in range(4):  # lumber stack
        for j in range(3):
            box(n + "_Lumber", "plank_light", (-11.2 + j * 0.0, 5.0 + j * 0.7, 0.2 + k * 0.38), (6.0, 0.62, 0.34), rot=(0, 0, 2 * (k % 2)), bevel=0.04)
    for k, (w, d) in enumerate(((3.0, 1.6), (2.2, 1.2), (1.2, 0.8))):  # brick pile
        box(n + "_Bricks", "brick" if "brick" in O.K.PAL else "red", (-13.0, 2.6, 0.25 + k * 0.5), (w, d, 0.5), bevel=0.06)
    for k, (w, d) in enumerate(((4.0, 2.6), (3.0, 1.8), (1.4, 1.0))):  # a pile of gold coins (what the next office costs)
        box(n + "_Coins", "gold", (10.5, 3.1, 0.25 + k * 0.45), (w, d, 0.45), bevel=0.2, segs=2, smooth=True)
    with at(6.0, 7.0, 0, rz=-25):  # a wheelbarrow
        lathe(n + "_Wheel", "iron", [(0.0, -0.15), (0.45, -0.15, True), (0.45, 0.15, True), (0.0, 0.15)], segs=14, c=(1.3, 0, 0.45), rot=(90, 0, 0))
        prism(n + "_Barrow", "speed_blue" if "speed_blue" in O.K.PAL else "navy_roof", [(-1.0, 0.6), (1.2, 0.6), (1.5, 1.4), (-1.3, 1.4)], 1.4)
        for s in (-1, 1):
            tube(n + "_Iron", "iron", [(1.3, s * 0.5, 0.45), (0.6, s * 0.6, 0.65), (-2.0, s * 0.6, 1.1)], 0.06, segs=5)
            tube(n + "_Iron", "iron", [(-0.6, s * 0.55, 0.6), (-0.7, s * 0.55, 0.0)], 0.05, segs=4)


# ================================================================== the back wall
def back_wall(n="BackWall"):
    planks(n, -23.2, 23.2, 0, 3.0, 0.0)
    carpet(n, 0, 2.97)  # (carpet + half walls end 0.03 inside the wall, not in its back face)
    half_wall(n, 0, 2.97, planter=False, seed=5)
    post(n, 0)
    box(n + "_Wall", "white", (0, 2.6, 3.25), (48.0, 0.8, 6.5))
    box(n + "_Footing", "stone_mid", (0, 2.6, -0.765), (48.4, 1.1, 1.47), bevel=0.06)  # (top 0.03 under the floor planks)
    box(n + "_Cap", "wood_warm", (0, 2.7, 6.75), (48.6, 1.3, 0.5), bevel=0.08)
    box(n + "_Band", "carpet_red", (0, 2.7, 7.2), (48.0, 1.2, 0.4), bevel=0.06)
    r = random.Random(9)
    for x in (-16.0, -9.0, 9.0, 16.0):  # bookshelves
        box(n + "_Shelf", "wood_deep", (x, 1.75, 2.8), (5.9, 1.0, 5.6), bevel=0.08)
        for k in range(5):
            zb = 0.45 + k * 1.05
            box(n + "_Shelf", "wood_deep", (x, 1.3, zb - 0.05), (5.6, 0.9, 0.1))
            xx = x - 2.6
            while xx < x + 2.5:
                w = r.uniform(0.32, 0.5)
                h = r.uniform(0.65, 0.92)
                lk = r.choice(("book_red", "book_blue", "book_green", "book_yel"))
                tilt = r.choice((0, 0, 0, 8))
                box(n + "_Book" + lk.title().replace("_", ""), lk, (xx + w / 2, 1.35, zb + h / 2), (w - 0.04, 0.7, h), rot=(0, tilt, 0), bevel=0.03)
                xx += w
    # the emblem: gold scales on a navy panel in a gold frame
    box(n + "_Panel", "navy_dark", (0, 2.05, 3.5), (9.0, 0.3, 5.0), bevel=0.1)
    box(n + "_Gold", "gold", (0, 2.12, 3.5), (9.6, 0.2, 5.6), bevel=0.08)
    import hub_license as HL
    HL.scales(n + "Scales", 0, 1.7, 1.3, 0.85)
    for x in (-5.8, 5.8, -12.6, 12.6):
        with at(x, 0.9, 0, s=0.8):
            PR.planter_round()


# ================================================================== renders
def main():
    O.reset()
    O.scene(sun_rot=(52, 8, -40))
    with O.region("hall"):
        y = 0.0
        for i in range(3):
            with at(0, y, 0):
                office_segment(seed=i)
                for side, rz in ((-1, 0), (1, 180)):
                    for dy in (3.0, 8.0):
                        with at(side * 10.5, dy, 0, rz=rz):
                            lawyer_desk()
            y += 11
        with at(0, y, 0):
            expansion_lock()
        y += 11
        with at(0, y, 0):
            back_wall()
        box("Preview_Ground", "grass_ov", (0, 20, -1.6), (120, 120, 0.2))
        O.player(1.5, 6, 0)
        O.player(-12.5, 14, 0)
    with O.region("desk"):
        with at(200, 0, 0, rz=-90):
            lawyer_desk()
        box("Preview_Ground", "floor_a", (200, 0, -0.1), (40, 40, 0.2))
        O.player(203, -2.5, 0)
    O.stats()
    O.render(OUT, "hall_overview", (34, -26, 30), (0, 18, 1), lens=30, show=["hall"])
    O.render(OUT, "hall_aisle", (0, -10, 7), (0, 20, 2.5), lens=28, show=["hall"])
    O.render(OUT, "hall_lock", (14, 22, 8), (0, 36, 1.5), lens=28, show=["hall"])
    O.render(OUT, "hall_desk", (196, -8, 5.5), (200, 0, 2.6), lens=32, show=["desk"])


if __name__ == "__main__":
    main()
