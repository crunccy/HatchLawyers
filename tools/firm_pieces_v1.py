"""The law-firm kit pieces. Each function returns a firm_kit.Piece (one mesh).

Plot layout (studs): width 48 (x = -24..24). Street/entrance is -Y; the plot runs toward +Y:
  Entrance (y -6..0) -> WaitingRoom (y 0..21) -> OfficeSegment x N (8 deep each, one lawyer slot per side)
  -> BackWall (3 deep). Locked expansions use ExpansionLock (same 8-deep footprint as a segment).
Lawyer slots: LawyerDesk is built for the RIGHT side (x > 0, lawyer faces -X toward the aisle);
Studio mirrors it for the left side by rotating 180 degrees.
"""
from firm_kit import Piece, sw

W = 24.0  # half width

# ------------------------------------------------------------------------------------------- swatches
FLOOR_WOOD = sw("floor_wood", (205, 140, 82), "plank")
FLOOR_TILE = sw("floor_tile", (238, 224, 192), "tile")
CARPET = sw("carpet_red", (196, 44, 52), "carpet")
CARPET_EDGE = sw("carpet_gold", (240, 190, 60))
WALL = sw("wall_cream", (246, 226, 180))
WOOD = sw("wood", (214, 140, 70))
WOOD_LIGHT = sw("wood_light", (232, 172, 102))
WOOD_DARK = sw("wood_dark", (122, 70, 34))
MARBLE = sw("marble", (240, 236, 228))
MARBLE_SHADE = sw("marble_shade", (214, 208, 198))
GOLD = sw("gold", (255, 200, 40))
LEATHER = sw("leather_green", (52, 135, 78))
LEATHER_DARK = sw("leather_green_dark", (34, 98, 56))
RUG_GREEN = sw("rug_green", (70, 150, 90), "carpet")
CUSHION_RED = sw("cushion_red", (210, 60, 60))
WHITE = sw("white", (246, 246, 240))
PAPER = sw("paper", (252, 250, 240))
METAL = sw("metal", (150, 156, 172))
DARK = sw("dark", (40, 40, 48))
SCREEN = sw("screen", (70, 160, 240))
WATER = sw("water", (120, 190, 255))
LEAF = sw("leaf", (70, 168, 34))
LEAF_LIGHT = sw("leaf_light", (124, 222, 52))
POT = sw("pot", (230, 120, 50))
BOOKS_RED = sw("books_red", (200, 60, 60), "books")
BOOKS_BLUE = sw("books_blue", (60, 110, 200), "books")
BOOKS_GREEN = sw("books_green", (60, 150, 90), "books")
BOOKS_GOLD = sw("books_gold", (220, 170, 60), "books")
MAG_RED = sw("mag_red", (235, 80, 80))
MAG_BLUE = sw("mag_blue", (80, 140, 235))
MAG_YELLOW = sw("mag_yellow", (250, 210, 70))
VELVET = sw("velvet", (175, 30, 42))
CONCRETE = sw("concrete", (176, 178, 186), "stud")
CARDBOARD = sw("cardboard", (200, 160, 110))
GLASS = sw("glass", (190, 225, 245))


# ----------------------------------------------------------------------------------------- helpers
def plant(p, x, y, size=1.0):
    p.box((x - 0.7 * size, y - 0.7 * size, 0), (x + 0.7 * size, y + 0.7 * size, 1.4 * size), POT, 0.08)
    p.box((x - 0.8 * size, y - 0.8 * size, 1.3 * size), (x + 0.8 * size, y + 0.8 * size, 1.5 * size), POT, 0.05)
    p.box((x - 1.0 * size, y - 1.0 * size, 1.5 * size), (x + 1.0 * size, y + 1.0 * size, 2.9 * size), LEAF, 0.15)
    p.box((x - 0.7 * size, y - 0.7 * size, 2.9 * size), (x + 0.7 * size, y + 0.7 * size, 3.8 * size), LEAF_LIGHT, 0.15)
    p.box((x - 0.35 * size, y - 0.35 * size, 3.8 * size), (x + 0.35 * size, y + 0.35 * size, 4.3 * size), LEAF, 0.1)


def side_walls(p, y0, y1, height=4.2):
    for s in (-1, 1):
        x_in, x_out = s * (W - 0.8), s * W
        lo, hi = min(x_in, x_out), max(x_in, x_out)
        p.box((lo, y0, 0), (hi, y1, height), WALL, 0.05)
        p.box((lo - 0.15, y0, height), (hi + 0.15, y1, height + 0.45), WOOD, 0.08)      # cap rail
        bx = (lo - 0.12, hi) if s > 0 else (lo, hi + 0.12)
        p.box((bx[0], y0, 0), (bx[1], y1, 0.5), WOOD_DARK, 0.04)                         # baseboard


def pilaster(p, x, y, height=5.0):
    p.box((x - 0.6, y - 0.6, 0), (x + 0.6, y + 0.6, height), WOOD_DARK, 0.08)
    p.box((x - 0.75, y - 0.75, height), (x + 0.75, y + 0.75, height + 0.35), WOOD, 0.06)


def scales_of_justice(p, cx, cy, cz, s=1.0, facing_y=True):
    """Gold scales emblem standing upright in the XZ plane (seen from -Y)."""
    t = 0.18 * s
    p.box((cx - 0.12 * s, cy - t, cz), (cx + 0.12 * s, cy + t, cz + 2.4 * s), GOLD, 0.03)          # post
    p.box((cx - 0.6 * s, cy - t, cz - 0.1 * s), (cx + 0.6 * s, cy + t, cz + 0.12 * s), GOLD, 0.03)  # foot
    p.box((cx - 1.5 * s, cy - t, cz + 2.1 * s), (cx + 1.5 * s, cy + t, cz + 2.3 * s), GOLD, 0.03)   # beam
    for sx in (-1, 1):
        x = cx + sx * 1.35 * s
        p.box((x - 0.04 * s, cy - t * 0.5, cz + 1.2 * s), (x + 0.04 * s, cy + t * 0.5, cz + 2.1 * s), GOLD, 0)
        p.box((x - 0.45 * s, cy - t, cz + 1.05 * s), (x + 0.45 * s, cy + t, cz + 1.25 * s), GOLD, 0.03)  # pan
    p.box((cx - 0.22 * s, cy - t, cz + 2.4 * s), (cx + 0.22 * s, cy + t, cz + 2.75 * s), GOLD, 0.05)     # finial


# ------------------------------------------------------------------------------------------ pieces
def entrance():
    p = Piece("Entrance")
    # porch and steps down to the street (plot floor is z = 0, ground is about z = -1)
    p.box((-11, -4, -1), (11, 0, 0), MARBLE, 0.06)
    p.box((-11, -5, -1), (11, -4, -0.33), MARBLE_SHADE, 0.05)
    p.box((-11, -6, -1), (11, -5, -0.66), MARBLE, 0.05)
    # front walls either side of the portico
    for s in (-1, 1):
        lo, hi = sorted((s * 9.5, s * W))
        p.box((lo, -0.8, 0), (hi, 0.2, 5.0), WALL, 0.05)
        p.box((lo, -0.95, 5.0), (hi, 0.35, 5.5), WOOD, 0.08)
        p.box((lo, -0.92, 0), (hi, 0.2, 0.5), WOOD_DARK, 0.04)
        # windows with wood frames
        for wx in (s * 13.5, s * 19.0):
            p.box((wx - 1.8, -0.9, 1.5), (wx + 1.8, -0.75, 4.2), WOOD_DARK, 0.04)
            p.box((wx - 1.5, -0.95, 1.8), (wx + 1.5, -0.8, 3.9), GLASS, 0.02)
            p.box((wx - 0.08, -1.0, 1.8), (wx + 0.08, -0.85, 3.9), WOOD_DARK, 0)
        plant(p, s * 10.6, -2.0, 0.8)
    # courthouse portico: 4 columns, entablature, stepped pediment, gold scales
    for cx in (-7.5, -3.5, 3.5, 7.5):
        p.box((cx - 0.9, -2.6, 0), (cx + 0.9, -0.8, 0.5), MARBLE_SHADE, 0.06)          # base
        p.cyl((cx, -1.7, 3.75), 0.62, 6.5, MARBLE, segments=12)                       # shaft
        for k in range(6):                                                            # fluting hint
            pass
        p.box((cx - 0.95, -2.65, 7.0), (cx + 0.95, -0.75, 7.45), MARBLE_SHADE, 0.06)   # capital
    p.box((-9.5, -2.9, 7.45), (9.5, 0.3, 8.6), MARBLE, 0.08)                            # entablature
    p.box((-9.7, -3.05, 8.6), (9.7, 0.35, 8.9), MARBLE_SHADE, 0.05)
    p.box((-8.5, -2.8, 8.9), (8.5, 0.2, 9.7), MARBLE, 0.06)                             # pediment steps
    p.box((-6.0, -2.8, 9.7), (6.0, 0.2, 10.5), MARBLE, 0.06)
    p.box((-3.2, -2.8, 10.5), (3.2, 0.2, 11.2), MARBLE, 0.06)
    scales_of_justice(p, 0, -3.0, 8.95, s=0.75)
    # welcome mat
    p.box((-2.5, -3.6, 0.0), (2.5, -0.9, 0.06), CARPET, 0.01)
    return p


def waiting_room():
    p = Piece("WaitingRoom")
    depth = 21.0
    p.box((-W, 0, -0.4), (W, depth, 0), FLOOR_TILE, 0.0, tile=2.0)
    side_walls(p, 0, depth)
    # rugs under each seating area
    for s in (-1, 1):
        lo, hi = sorted((s * 9.0, s * 22.6))
        p.box((lo, 2.5, 0), (hi, 13.5, 0.06), RUG_GREEN, 0.01, tile=2.0)
        p.box((lo - 0.25, 2.25, 0), (hi + 0.25, 13.75, 0.04), CARPET_EDGE, 0.01)
    # couches against the side walls, facing the aisle (3 seats each), two per side
    for s in (-1, 1):
        for y0 in (3.0, 8.5):
            x_back = s * 22.6
            x_front = s * 19.4
            lo, hi = sorted((x_back, x_front))
            p.box((lo, y0, 0.25), (hi, y0 + 4.6, 1.2), LEATHER_DARK, 0.1)                # base
            for i in range(2):                                                          # cushions
                cy0 = y0 + 0.35 + i * 2.0
                clo, chi = sorted((s * 22.0, x_front))
                p.box((clo, cy0, 1.2), (chi, cy0 + 1.9, 1.75), LEATHER, 0.12)
            blo, bhi = sorted((x_back, s * 21.7))
            p.box((blo, y0, 1.2), (bhi, y0 + 4.6, 3.1), LEATHER, 0.14)                   # back
            for ay in (y0, y0 + 4.6 - 0.55):                                             # arms
                p.box((lo, ay, 1.2), (hi, ay + 0.55, 2.2), LEATHER_DARK, 0.12)
            for ly in (y0 + 0.3, y0 + 4.3):                                              # legs
                for lx in (x_back - s * 0.3, x_front + s * 0.3):
                    p.box((lx - 0.15, ly - 0.15, 0), (lx + 0.15, ly + 0.15, 0.25), WOOD_DARK, 0)
        # coffee table with magazines and a mug
        tlo, thi = sorted((s * 14.0, s * 17.5))
        p.box((tlo, 4.5, 1.1), (thi, 11.5, 1.45), WOOD, 0.06)
        for lx in (tlo + 0.3, thi - 0.3):
            for ly in (4.8, 11.2):
                p.box((lx - 0.18, ly - 0.18, 0), (lx + 0.18, ly + 0.18, 1.1), WOOD_DARK, 0.03)
        mx = (tlo + thi) / 2
        p.box((mx - 1.0, 5.4, 1.45), (mx + 0.4, 7.2, 1.53), MAG_RED, 0.01)
        p.box((mx - 0.6, 6.2, 1.53), (mx + 0.9, 8.0, 1.61), MAG_BLUE, 0.01)
        p.box((mx - 0.9, 9.0, 1.45), (mx + 0.6, 10.8, 1.53), MAG_YELLOW, 0.01)
        p.cyl((mx + 0.5, 10.2, 1.75), 0.22, 0.45, CUSHION_RED, segments=8)
        # armchair at the aisle end of each seating area, facing the wall couches
        alo, ahi = sorted((s * 9.4, s * 12.0))
        p.box((alo, 14.0, 0.25), (ahi, 16.6, 1.2), LEATHER_DARK, 0.1)
        p.box((alo, 14.2, 1.2), (ahi, 16.4, 1.7), LEATHER, 0.12)
        p.box((alo, 16.0, 1.2), (ahi, 16.6, 3.0), LEATHER, 0.12)
        plant(p, s * 22.2, 1.2, 0.8)
        plant(p, s * 22.2, 19.6, 0.9)
    # water cooler (left) and magazine rack (right), against the walls
    p.box((-22.9, 15.2, 0), (-21.5, 16.6, 2.6), WHITE, 0.08)
    p.cyl((-22.2, 15.9, 3.2), 0.62, 1.2, WATER, segments=10)
    p.box((21.8, 14.5, 0), (22.9, 17.5, 3.2), WOOD, 0.06)
    for i, mag in enumerate((MAG_RED, MAG_BLUE, MAG_YELLOW)):
        p.box((21.6, 14.8 + i * 0.95, 1.0 + i * 0.7), (21.9, 15.6 + i * 0.95, 2.0 + i * 0.7), mag, 0.01)
    # reception counter (right of the aisle) with bell, computer and papers
    p.box((8.0, 17.6, 0), (19.0, 19.6, 3.0), WOOD, 0.08)
    p.box((7.8, 17.4, 3.0), (19.2, 19.8, 3.35), WOOD_LIGHT, 0.06)
    p.box((8.0, 17.45, 0.3), (19.0, 17.6, 2.7), WOOD_DARK, 0.02)
    p.box((8.4, 17.38, 1.4), (18.6, 17.5, 1.6), GOLD, 0)                                  # gold trim
    p.box((14.5, 18.4, 3.35), (16.3, 19.4, 3.45), DARK, 0.02)                             # keyboard
    p.box((14.6, 19.2, 3.35), (16.2, 19.4, 4.6), DARK, 0.03)                              # monitor
    p.box((14.75, 19.15, 3.5), (16.05, 19.2, 4.45), SCREEN, 0)
    p.cyl((10.0, 18.4, 3.48), 0.3, 0.25, GOLD, segments=10)                               # desk bell
    p.box((11.4, 18.0, 3.35), (12.8, 19.0, 3.5), PAPER, 0.01)
    scales_of_justice(p, 12.6, 19.4, 3.35, s=0.35)
    # velvet-rope queue line on the left, guiding clients toward the offices
    for y in (17.0, 19.6):
        for x in (-8.5, -13.5, -18.5):
            p.cyl((x, y, 0.15), 0.35, 0.3, GOLD, segments=8)
            p.cyl((x, y, 1.3), 0.1, 2.2, GOLD, segments=6)
            p.cyl((x, y, 2.5), 0.2, 0.25, GOLD, segments=8)
        for xa, xb in ((-13.5, -8.5), (-18.5, -13.5)):
            p.box((xa, y - 0.08, 2.0), (xb, y + 0.08, 2.18), VELVET, 0.02)
    # divider into the offices: low balustrade with an arch over the aisle
    for s in (-1, 1):
        lo, hi = sorted((s * 6.0, s * (W - 0.8)))
        p.box((lo, 20.4, 0), (hi, 21.0, 2.2), WOOD, 0.05)
        p.box((lo - 0.1, 20.3, 2.2), (hi + 0.1, 21.1, 2.5), WOOD_DARK, 0.05)
        pilaster(p, s * 6.6, 20.7, height=6.2)
    p.box((-7.4, 20.2, 6.5), (7.4, 21.2, 7.4), WOOD_DARK, 0.08)                            # arch beam
    p.box((-4.5, 20.05, 6.6), (4.5, 20.25, 7.3), GOLD, 0.02)                               # plaque backing
    return p


def office_segment():
    p = Piece("OfficeSegment")
    depth = 8.0
    p.box((-W, 0, -0.4), (W, depth, 0), FLOOR_WOOD, 0.0, tile=2.0)
    p.box((-5.0, 0, 0), (5.0, depth, 0.07), CARPET, 0.0, tile=2.0)                     # aisle runner
    for s in (-1, 1):
        lo, hi = sorted((s * 5.0, s * 5.6))
        p.box((lo, 0, 0), (hi, depth, 0.08), CARPET_EDGE, 0.0)
    side_walls(p, 0, depth, height=4.6)
    for s in (-1, 1):
        pilaster(p, s * (W - 0.4), 0.0, height=5.6)
        # office partition between neighbouring slots: wood lower panel + frosted glass top
        lo, hi = sorted((s * 8.5, s * (W - 0.8)))
        p.box((lo, -0.2, 0), (hi, 0.2, 2.4), WOOD, 0.05)
        p.box((lo, -0.12, 2.4), (hi, 0.12, 4.0), GLASS, 0.02)
        p.box((lo - 0.05, -0.25, 4.0), (hi + 0.05, 0.25, 4.25), WOOD_DARK, 0.04)
        p.box((s * 8.5 - 0.3, -0.3, 0), (s * 8.5 + 0.3, 0.3, 4.4), WOOD_DARK, 0.05)
    return p


def lawyer_desk():
    """One lawyer's office furniture, for the RIGHT side. Origin = slot centre on the floor.
    LawyerSpot = (+2.3, 0) facing -X; ClientSpot = (-2.6, 0) facing +X."""
    p = Piece("LawyerDesk")
    # executive desk, long side along Y, front panel facing the aisle (-X)
    p.box((-1.2, -2.6, 2.25), (1.3, 2.6, 2.65), WOOD_LIGHT, 0.07)                       # top
    for y0, y1 in ((-2.5, -1.2), (1.2, 2.5)):                                           # pedestals
        p.box((-1.1, y0, 0), (1.2, y1, 2.25), WOOD, 0.06)
        for z in (0.5, 1.2, 1.85):
            p.box((-1.16, (y0 + y1) / 2 - 0.25, z), (-1.08, (y0 + y1) / 2 + 0.25, z + 0.1), GOLD, 0)
    p.box((-1.15, -1.2, 0.4), (-0.9, 1.2, 2.25), WOOD_DARK, 0.04)                       # modesty panel
    p.box((-1.2, -2.6, 2.1), (-1.1, 2.6, 2.2), GOLD, 0)                                 # gold trim line
    # nameplate facing the aisle, laptop, papers, pen pot, lamp
    p.box((-1.25, -0.9, 2.65), (-0.95, 0.9, 3.0), WOOD_DARK, 0.03)
    p.box((-1.27, -0.75, 2.7), (-1.2, 0.75, 2.95), GOLD, 0)
    p.box((-0.3, 0.2, 2.65), (0.8, 1.7, 2.75), DARK, 0.02)                              # laptop base
    p.box((0.75, 0.2, 2.65), (0.85, 1.7, 3.6), DARK, 0.02)                              # laptop lid
    p.box((0.7, 0.3, 2.75), (0.74, 1.6, 3.5), SCREEN, 0)
    p.box((-0.6, -1.9, 2.65), (0.4, -0.7, 2.8), PAPER, 0.01)
    p.box((-0.5, -1.7, 2.8), (0.5, -0.9, 2.86), BOOKS_RED, 0.01)
    p.cyl((0.6, -2.0, 2.95), 0.18, 0.6, METAL, segments=8)
    p.cyl((0.9, 2.15, 2.75), 0.3, 0.2, GOLD, segments=8)                                # lamp base
    p.box((0.86, 2.11, 2.85), (0.94, 2.19, 3.9), GOLD, 0)
    p.box((0.55, 1.85, 3.8), (1.15, 2.45, 4.2), LEATHER, 0.06)                          # green banker shade
    # executive chair behind the lawyer
    p.cyl((3.9, 0, 0.12), 0.7, 0.24, DARK, segments=8)
    p.cyl((3.9, 0, 0.7), 0.12, 1.0, METAL, segments=6)
    p.box((3.1, -0.9, 1.2), (4.6, 0.9, 1.7), LEATHER, 0.12)
    p.box((4.3, -0.9, 1.7), (4.8, 0.9, 4.3), LEATHER, 0.15)
    p.box((4.25, -0.65, 2.2), (4.35, 0.65, 4.0), LEATHER_DARK, 0.03)                    # tufting line
    # bookshelf on the wall behind
    p.box((6.0, -3.2, 0), (7.0, 3.2, 4.3), WOOD_DARK, 0.06)
    for i, books in enumerate((BOOKS_RED, BOOKS_BLUE, BOOKS_GREEN, BOOKS_GOLD)):
        z0 = 0.3 + i * 1.0
        p.box((5.95, -3.0, z0), (6.1, 3.0, z0 + 0.8), books, 0.0, tile=1.0)
        p.box((5.9, -3.2, z0 + 0.8), (6.2, 3.2, z0 + 0.95), WOOD, 0.02)
    # client rug in front of the desk + small plant in the corner
    p.box((-4.0, -1.6, 0), (-1.6, 1.6, 0.05), RUG_GREEN, 0.01, tile=1.0)
    plant(p, 6.2, -3.2 + 0.0 - 0.6, 0.55)
    return p


def back_wall():
    p = Piece("BackWall")
    p.box((-W, 0, -0.4), (W, 3.0, 0), FLOOR_WOOD, 0.0, tile=2.0)
    p.box((-W, 2.2, 0), (W, 3.0, 6.5), WALL, 0.05)
    p.box((-W - 0.15, 2.05, 6.5), (W + 0.15, 3.15, 7.0), WOOD, 0.08)
    for s in (-1, 1):                                                                     # library shelves
        for x0 in (6.0, 13.0):
            lo, hi = sorted((s * x0, s * (x0 + 6.0)))
            p.box((lo, 1.2, 0), (hi, 2.2, 5.6), WOOD_DARK, 0.06)
            for i, books in enumerate((BOOKS_BLUE, BOOKS_RED, BOOKS_GOLD, BOOKS_GREEN, BOOKS_RED)):
                z0 = 0.3 + i * 1.05
                p.box((lo + 0.2, 1.15, z0), (hi - 0.2, 1.3, z0 + 0.85), books, 0.0, tile=1.0)
                p.box((lo, 1.1, z0 + 0.85), (hi, 1.4, z0 + 1.0), WOOD, 0.02)
        plant(p, s * 21.8, 1.2, 0.9)
    p.box((-4.5, 1.9, 1.0), (4.5, 2.2, 6.0), LEATHER_DARK, 0.05)                         # emblem banner
    p.box((-4.8, 1.85, 0.8), (4.8, 2.25, 1.1), GOLD, 0.03)
    scales_of_justice(p, 0, 1.75, 1.6, s=1.4)
    return p


def expansion_lock():
    """A not-yet-bought section: bare floor, velvet rope, moving boxes and a sign stand."""
    p = Piece("ExpansionLock")
    depth = 8.0
    p.box((-W, 0, -0.4), (W, depth, 0), CONCRETE, 0.0, tile=2.0)
    for x in (-21.0, -14.0, -7.0, 7.0, 14.0, 21.0):                                     # rope across the front
        p.cyl((x, 0.6, 0.15), 0.4, 0.3, GOLD, segments=8)
        p.cyl((x, 0.6, 1.4), 0.11, 2.4, GOLD, segments=6)
        p.cyl((x, 0.6, 2.7), 0.22, 0.25, GOLD, segments=8)
    for xa, xb in ((-21, -14), (-14, -7), (-7, 7), (7, 14), (14, 21)):
        p.box((xa, 0.52, 2.15), (xb, 0.68, 2.35), VELVET, 0.02)
    for (x, y, sz) in ((-17, 4.5, 1.4), (-15.4, 5.2, 1.0), (-16.6, 4.7, 0.9), (16, 4.0, 1.3), (17.6, 5.4, 1.1)):
        p.box((x - sz, y - sz, 0), (x + sz, y + sz, sz * 1.6), CARDBOARD, 0.05)
        p.box((x - sz, y - 0.12, sz * 1.6 - 0.02), (x + sz, y + 0.12, sz * 1.6 + 0.02), WOOD_LIGHT, 0)
    p.box((-0.25, 3.8, 0), (0.25, 4.2, 3.5), WOOD_DARK, 0.04)                            # sign post
    p.box((-0.9, 3.6, 0), (0.9, 4.4, 0.25), WOOD_DARK, 0.04)
    return p


PIECES = [entrance, waiting_room, office_segment, lawyer_desk, back_wall, expansion_lock]
