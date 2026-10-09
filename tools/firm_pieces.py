"""The law-firm kit pieces, v2 "voxel island" style. Each function returns a firm_kit.Piece (one mesh).

Style (matches references/ and mr.robe's island): every surface is studded blocks (1-stud cells on floors and
walls, half-stud cells on props), stepped voxel shapes, mossy stone foundation, voxel palms + bushes,
orange path with white dashes down the middle, terracotta roof lips, wood posts and fences.

Plot layout (studs): width 48 (x = -24..24). Street/entrance is -Y; the plot runs toward +Y:
  Entrance (y -6..0) -> WaitingRoom (y 0..21) -> OfficeSegment x N (8 deep each, one lawyer slot per side)
  -> BackWall (3 deep). Locked expansions use ExpansionLock (same 8-deep footprint as a segment).
Floor top is z = 0 and sits FH studs above the plot grass (FirmBuilder raises the frame by FH).
Lawyer slots: LawyerDesk is built for the RIGHT side (x > 0, lawyer faces -X toward the aisle);
Studio mirrors it for the left side by rotating 180 degrees.
"""
from firm_kit import Piece, sw

W = 24.0    # half width
FH = 1.5    # foundation height (floor above the grass)
SEG = 11.0  # office segment depth = spacing between lawyers along a wall (was 8: felt cramped)
T = 1.0     # stud cell size on floors / walls
TP = 1.0    # stud cell size on props

# ------------------------------------------------------------------------------------------- swatches
# v3: mr.robe's courtroom palette (ReplicatedStorage.CourtroomSet): flat Plastic colors, warm woods, gold,
# courtroom red, cream + marble. Only books / crates / caution keep a printed pattern.
FLOOR_WOOD = sw("floor_wood", (156, 96, 52))
FLOOR_WOOD_B = sw("floor_wood_b", (170, 104, 52))
FLOOR_TILE = sw("floor_cream", (245, 236, 214))
FLOOR_TILE_B = sw("floor_marble", (250, 250, 248))
PATH = sw("carpet_red", (150, 30, 30))
DASH = sw("carpet_gold", (255, 190, 50))
WALL = sw("wall_cream", (245, 236, 214))
WOOD = sw("wood", (170, 104, 52))
WOOD_PLANK = sw("wood_plank", (176, 112, 62))
WOOD_LIGHT = sw("wood_light", (176, 112, 62))
WOOD_DARK = sw("wood_dark", (128, 70, 32))
WOOD_DEEP = sw("wood_deep", (92, 48, 22))
MARBLE = sw("marble", (250, 250, 248))
MARBLE_SHADE = sw("marble_shade", (226, 222, 214))
STONE = sw("stone", (163, 162, 165))
STONE_DARK = sw("stone_dark", (120, 124, 132))
GRASS = sw("grass", (98, 180, 60))
LEAF = sw("leaf", (46, 128, 56))
LEAF_LIGHT = sw("leaf_light", (84, 168, 70))
TRUNK = sw("trunk", (128, 70, 32))
TRUNK_DARK = sw("trunk_dark", (92, 48, 22))
COCONUT = sw("coconut", (92, 48, 22))
POT = sw("pot", (176, 112, 62))
POT_RIM = sw("pot_rim", (128, 70, 32))
ROOF = sw("roof_red", (150, 30, 30))
ROOF_DARK = sw("roof_red_dark", (120, 25, 35))
GOLD = sw("gold", (255, 190, 50))
GOLD_FLAT = GOLD
LEATHER = sw("leather_green", (30, 110, 50))
LEATHER_DARK = sw("leather_green_dark", (22, 84, 40))
RUG = sw("rug_navy", (28, 44, 110))
RUG_EDGE = sw("rug_gold", (255, 190, 50))
CUSHION = sw("cushion_red", (150, 30, 30))
WHITE = sw("white", (250, 248, 238))
PAPER = sw("paper", (252, 250, 240))
METAL = sw("metal", (120, 124, 132))
DARK = sw("dark", (22, 22, 24))
SCREEN = sw("screen", (60, 140, 255))
WATER = sw("water", (150, 210, 255))
GLASS = sw("glass", (170, 220, 255))
BOOKS_RED = sw("books_red", (150, 30, 30), "books")
BOOKS_BLUE = sw("books_blue", (28, 44, 110), "books")
BOOKS_GREEN = sw("books_green", (30, 110, 50), "books")
BOOKS_GOLD = sw("books_gold", (230, 200, 130), "books")
MAG_RED = sw("mag_red", (170, 30, 40))
MAG_BLUE = sw("mag_blue", (60, 110, 200))
MAG_YELLOW = sw("mag_yellow", (255, 240, 190))
VELVET = sw("velvet", (150, 30, 30))
DIRT = sw("dirt", (128, 84, 48))
CRATE = sw("crate", (176, 112, 62), "crate")
CAUTION = sw("caution", (255, 190, 50), "caution")
CONE = sw("cone_orange", (240, 120, 40))
FLOWER_RED = sw("flower_red", (200, 40, 50))
FLOWER_YELLOW = sw("flower_yellow", (255, 214, 80))
FLOWER_PINK = sw("flower_pink", (240, 140, 190))
SAND = sw("sand", (230, 200, 130))


# ----------------------------------------------------------------------------------------- helpers
def B(p, mn, mx, col, t=TP, bottom=False):
    """A sharp block. Flat colors (mr.robe's Plastic look) are one box; printed swatches tile."""
    from firm_kit import SW
    if SW[col][2] == "flat":
        p.box(mn, mx, col, 0.0)
    else:
        p.box(mn, mx, col, 0.0, tile=t, bottom=bottom)


def F(p, mn, mx, col):
    """A small flat-colored detail block."""
    p.box(mn, mx, col, 0.0)


def rnd(i):
    return ((i * 9301 + 49297) % 233280) / 233280.0


def cube(p, x, y, z, s, col, t=None):
    B(p, (x - s / 2, y - s / 2, z), (x + s / 2, y + s / 2, z + s), col, t or s)


def bush(p, x, y, z, s=1.0):
    cube(p, x, y, z, 1.6 * s, LEAF)
    cube(p, x + 0.7 * s, y + 0.4 * s, z, 1.2 * s, LEAF_LIGHT)
    cube(p, x - 0.6 * s, y - 0.5 * s, z, 1.1 * s, LEAF)
    cube(p, x + 0.1 * s, y - 0.1 * s, z + 1.4 * s, 1.0 * s, LEAF_LIGHT)


def flowers(p, x0, x1, y0, y1, z, seed=0):
    """A strip of voxel flowers on a leafy bed."""
    B(p, (x0, y0, z), (x1, y1, z + 0.35), LEAF, 0.5)
    n = max(1, int((x1 - x0) / 0.7) + int((y1 - y0) / 0.7))
    cols = (FLOWER_RED, FLOWER_YELLOW, FLOWER_PINK)
    for i in range(n):
        fx = x0 + 0.2 + rnd(seed + i * 3) * (x1 - x0 - 0.5)
        fy = y0 + 0.2 + rnd(seed + i * 3 + 1) * (y1 - y0 - 0.5)
        F(p, (fx, fy, z + 0.35), (fx + 0.32, fy + 0.32, z + 0.7), cols[(seed + i) % 3])


def palm(p, x, y, z=0.0, h=4.5, lean=(1, 0), pot=True):
    """(Palms removed at the user's request, 2026-10-08: kept as a no-op so the piece code stays as is.)"""
    return
    """Potted voxel palm like the reference ones: banded trunk curving one way, drooping cube fronds."""
    if pot:
        B(p, (x - 0.8, y - 0.8, z), (x + 0.8, y + 0.8, z + 1.0), POT)
        B(p, (x - 0.95, y - 0.95, z + 0.9), (x + 0.95, y + 0.95, z + 1.25), POT_RIM)
        z += 1.25
    seg = 0.5
    n = int(h / seg)
    tx, ty = x, y
    for i in range(n):
        drift = 0.04 * i * i / n
        tx = x + lean[0] * drift * 3
        ty = y + lean[1] * drift * 3
        s = 0.62 if i % 2 == 0 else 0.55
        B(p, (tx - s / 2, ty - s / 2, z + i * seg), (tx + s / 2, ty + s / 2, z + (i + 1) * seg),
          TRUNK if i % 2 == 0 else TRUNK_DARK, 0.62)
    top = z + n * seg
    cube(p, tx, ty, top - 0.2, 1.1, LEAF)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (0.72, 0.72), (-0.72, 0.72), (0.72, -0.72), (-0.72, -0.72)):
        length = 4 if dx * dy == 0 else 3
        for k in range(1, length + 1):
            d = 0.62 * k
            drop = [0, 0.1, 0.35, 0.8][k - 1]
            cube(p, tx + dx * d, ty + dy * d, top + 0.25 - drop, 0.62, LEAF_LIGHT if k % 2 else LEAF)
    F(p, (tx - 0.45, ty - 0.1, top - 0.6), (tx - 0.1, ty + 0.25, top - 0.25), COCONUT)
    F(p, (tx + 0.1, ty - 0.3, top - 0.55), (tx + 0.45, ty + 0.05, top - 0.2), COCONUT)


def skirt(p, y0, y1, seed=0, back=False):
    """Foundation along both side edges between y0 and y1 (and the back face if back=True):
    grey studded stone, a dark wood deck rim, mossy stones and bushes on the grass outside."""
    for s in (-1, 1):
        lo, hi = sorted((s * (W - 1.0), s * W))
        B(p, (lo, y0, -FH), (hi, y1, -0.3), STONE, T)
        rlo, rhi = sorted((s * (W - 0.4), s * (W + 0.25)))
        B(p, (rlo, y0, -0.4), (rhi, y1, 0.05), WOOD_DARK, TP)
        # mossy stones poking out of the foundation, irregular like the reference cliffs
        y = y0 + 0.6 + rnd(seed + s) * 1.5
        i = 0
        while y < y1 - 1.2:
            r = rnd(seed * 7 + i * 13 + s)
            wy = 1.0 + r * 1.4
            hz = 0.5 + rnd(seed + i * 5 + 2) * 0.6
            olo, ohi = sorted((s * W, s * (W + 0.5 + r * 0.4)))
            B(p, (olo, y, -FH), (ohi, min(y + wy, y1), -FH + hz), STONE_DARK if i % 2 else STONE, TP)
            B(p, (olo, y, -FH + hz), (ohi, min(y + wy, y1), -FH + hz + 0.2), GRASS, TP)
            if rnd(seed + i * 11) > 0.55 and y + 2.5 < y1:
                bush(p, s * (W + 1.4), y + 1.2, -FH, 0.7 + 0.3 * r)
            y += wy + 1.5 + rnd(seed + i * 17) * 2.5
            i += 1
    if back:
        B(p, (-W, y1 - 1.0, -FH), (W, y1, -0.3), STONE, T)
        B(p, (-W - 0.25, y1 - 0.4, -0.4), (W + 0.25, y1 + 0.25, 0.05), WOOD_DARK, TP)


def floor(p, y0, y1, col, path=True):
    """Floor slab (top z = 0). Wood = alternating board strips along Y; cream = big cream/marble checker.
    The aisle gets courtroom red carpet with gold edges."""
    B(p, (-W, y0, -0.3), (W, y1, -0.02), col)
    if col == FLOOR_WOOD:
        x = -W
        i = 0
        while x < W - 0.01:
            if i % 2 == 1:
                B(p, (x, y0, -0.02), (min(x + 1.5, W), y1, 0), FLOOR_WOOD_B)
            x += 1.5
            i += 1
    elif col == FLOOR_TILE:
        x, i = -W, 0
        while x < W - 0.01:
            y, j = y0, 0
            while y < y1 - 0.01:
                if (i + j) % 2 == 1:
                    B(p, (x, y, -0.02), (min(x + 4, W), min(y + 4, y1), 0), FLOOR_TILE_B)
                y += 4
                j += 1
            x += 4
            i += 1
    if path:
        B(p, (-4.0, y0, 0), (4.0, y1, 0.06), PATH)
        for s_ in (-1, 1):
            lo, hi = sorted((s_ * 4.0, s_ * 4.5))
            B(p, (lo, y0, 0), (hi, y1, 0.07), DASH)


def side_walls(p, y0, y1, height=5.0, posts=True, planters=True, seed=0):
    for s in (-1, 1):
        lo, hi = sorted((s * (W - 0.8), s * W))
        B(p, (lo, y0, 0), (hi, y1, height), WALL, T)
        wlo, whi = sorted((s * (W - 1.05), s * (W - 0.8)))
        B(p, (wlo, y0, 0), (whi, y1, 1.5), WOOD_PLANK, TP)                       # wainscot inside
        clo, chi = sorted((s * (W - 1.1), s * (W + 0.3)))
        B(p, (clo, y0, height), (chi, y1, height + 0.5), WOOD_PLANK, TP)         # cap beam
        if posts:
            plo, phi = sorted((s * (W - 1.3), s * (W + 0.35)))
            B(p, (plo, y0 - 0.6, -0.3), (phi, y0 + 0.6, height + 0.9), WOOD_DARK, TP)
            B(p, (plo - 0.1, y0 - 0.7, height + 0.9), (phi + 0.1, y0 + 0.7, height + 1.2), WOOD, TP)
        if planters and y1 - y0 >= 6:
            ym = (y0 + y1) / 2
            B(p, (clo, ym - 1.6, height + 0.5), (chi, ym + 1.6, height + 1.0), POT)
            flowers(p, clo + 0.1, chi - 0.1, ym - 1.5, ym + 1.5, height + 1.0, seed + (3 if s > 0 else 0))


def window(p, x, y, z0=1.4, w=3.6, h=3.0, box_seed=0):
    """Window on a wall whose outer face is at y (seen from -Y), with a flower box under it."""
    B(p, (x - w / 2 - 0.25, y - 0.25, z0 - 0.25), (x + w / 2 + 0.25, y + 0.05, z0 + h + 0.25), WOOD_DARK)
    B(p, (x - w / 2, y - 0.3, z0), (x + w / 2, y - 0.15, z0 + h), GLASS)
    F(p, (x - 0.12, y - 0.4, z0), (x + 0.12, y - 0.25, z0 + h), WOOD_DARK)
    F(p, (x - w / 2, y - 0.4, z0 + h / 2 - 0.12), (x + w / 2, y - 0.25, z0 + h / 2 + 0.12), WOOD_DARK)
    B(p, (x - w / 2 - 0.2, y - 1.0, z0 - 0.75), (x + w / 2 + 0.2, y - 0.25, z0 - 0.15), WOOD_PLANK)
    flowers(p, x - w / 2 - 0.1, x + w / 2 + 0.1, y - 0.95, y - 0.3, z0 - 0.15, box_seed)


def scales_of_justice(p, cx, cy, cz, s=1.0):
    """Gold scales emblem standing upright in the XZ plane (seen from -Y), chunky voxel version."""
    t = 0.25 * s
    B(p, (cx - 0.2 * s, cy - t, cz), (cx + 0.2 * s, cy + t, cz + 2.4 * s), GOLD, max(0.5, 0.4 * s))
    B(p, (cx - 0.8 * s, cy - t, cz), (cx + 0.8 * s, cy + t, cz + 0.3 * s), GOLD, max(0.5, 0.4 * s))
    B(p, (cx - 1.6 * s, cy - t, cz + 2.1 * s), (cx + 1.6 * s, cy + t, cz + 2.4 * s), GOLD, max(0.5, 0.4 * s))
    for sx in (-1, 1):
        x = cx + sx * 1.35 * s
        F(p, (x - 0.06 * s, cy - t * 0.5, cz + 1.3 * s), (x + 0.06 * s, cy + t * 0.5, cz + 2.1 * s), GOLD_FLAT)
        B(p, (x - 0.55 * s, cy - t, cz + 1.0 * s), (x + 0.55 * s, cy + t, cz + 1.3 * s), GOLD, max(0.5, 0.4 * s))
    B(p, (cx - 0.3 * s, cy - t, cz + 2.4 * s), (cx + 0.3 * s, cy + t, cz + 2.9 * s), GOLD, max(0.5, 0.4 * s))


def sq_column(p, x, y, z0, z1, w=1.3):
    """Square voxel column: wide base, stacked shaft blocks, wide capital."""
    B(p, (x - w / 2 - 0.35, y - w / 2 - 0.35, z0), (x + w / 2 + 0.35, y + w / 2 + 0.35, z0 + 0.6), MARBLE_SHADE)
    B(p, (x - w / 2, y - w / 2, z0 + 0.6), (x + w / 2, y + w / 2, z1 - 0.55), MARBLE)
    B(p, (x - w / 2 - 0.35, y - w / 2 - 0.35, z1 - 0.55), (x + w / 2 + 0.35, y + w / 2 + 0.35, z1), MARBLE_SHADE)


def gold_post(p, x, y, h=2.4):
    B(p, (x - 0.4, y - 0.4, 0), (x + 0.4, y + 0.4, 0.3), GOLD, 1.0)
    B(p, (x - 0.16, y - 0.16, 0.3), (x + 0.16, y + 0.16, h), GOLD, 1.0)
    B(p, (x - 0.28, y - 0.28, h), (x + 0.28, y + 0.28, h + 0.4), GOLD, 1.0)


def crate(p, x, y, z, s):
    B(p, (x - s / 2, y - s / 2, z), (x + s / 2, y + s / 2, z + s), CRATE, s)


def cone(p, x, y):
    B(p, (x - 0.55, y - 0.55, 0), (x + 0.55, y + 0.55, 0.2), CONE, 0.25)
    B(p, (x - 0.38, y - 0.38, 0.2), (x + 0.38, y + 0.38, 0.6), CONE, 0.25)
    B(p, (x - 0.32, y - 0.32, 0.6), (x + 0.32, y + 0.32, 0.85), WHITE, 0.25)
    B(p, (x - 0.24, y - 0.24, 0.85), (x + 0.24, y + 0.24, 1.25), CONE, 0.25)
    B(p, (x - 0.14, y - 0.14, 1.25), (x + 0.14, y + 0.14, 1.5), WHITE, 0.25)


# ------------------------------------------------------------------------------------------ pieces
def entrance():
    p = Piece("Entrance")
    # porch landing + two steps down to the grass (grass is z = -FH)
    B(p, (-11, -4.5, -FH), (11, 0, 0), MARBLE, T)
    B(p, (-11, -5.25, -FH), (11, -4.5, -0.5), MARBLE_SHADE, T)
    B(p, (-11, -6.0, -FH), (11, -5.25, -1.0), MARBLE, T)
    B(p, (-2.6, -3.8, 0), (2.6, -1.0, 0.06), PATH, 0.5)                                      # red welcome carpet
    # foundation under the front walls and the side edges of this piece
    for s in (-1, 1):
        lo, hi = sorted((s * 11, s * W))
        B(p, (lo, -1.0, -FH), (hi, 0, 0), STONE, T)
        B(p, (lo, -1.15, -0.4), (hi, 0, 0.05), WOOD_DARK, TP)
        # planter bed in front of the wall: stone border, grass, bushes and flowers
        blo, bhi = sorted((s * 11.6, s * 23.6))
        B(p, (blo, -3.6, -FH), (bhi, -1.15, -FH + 0.7), STONE_DARK, TP)
        B(p, (blo + 0.3, -3.3, -FH + 0.7), (bhi - 0.3, -1.15, -FH + 0.8), GRASS, TP)
        bush(p, s * 22.4, -2.3, -FH + 0.8, 0.8)
        bush(p, s * 16.2, -2.4, -FH + 0.8, 0.6)
        flowers(p, min(s * 17.4, s * 21.0), max(s * 17.4, s * 21.0), -3.0, -1.6, -FH + 0.8, 5 + s)
        flowers(p, min(s * 12.2, s * 15.2), max(s * 12.2, s * 15.2), -3.0, -1.6, -FH + 0.8, 9 + s)
    # front walls either side of the portico, with windows, corner posts and a terracotta roof lip
    for s in (-1, 1):
        lo, hi = sorted((s * 9.5, s * W))
        B(p, (lo, -0.8, 0), (hi, 0.2, 5.5), WALL, T)
        B(p, (lo, -1.0, 0), (hi, -0.8, 1.2), WOOD_PLANK, TP)                                   # wainscot
        for px in (s * 9.5, s * (W - 0.2)):
            B(p, (px - 0.65, -1.3, -0.3), (px + 0.65, 0.2, 6.4), WOOD_DARK)
        for wx in (s * 13.5, s * 19.0):
            window(p, wx, -1.0, box_seed=int(wx))
        B(p, (lo - 0.2, -2.0, 5.5), (hi + 0.2, 0.4, 6.0), ROOF)
        B(p, (lo - 0.1, -1.5, 6.0), (hi + 0.1, 0.4, 6.5), ROOF_DARK)
        B(p, (lo, -1.0, 6.5), (hi, 0.4, 6.9), ROOF)
    # courthouse portico: 4 square voxel columns, entablature, stepped pediment, gold scales
    for cx in (-7.5, -3.5, 3.5, 7.5):
        sq_column(p, cx, -1.7, 0, 7.45)
    B(p, (-9.6, -2.9, 7.45), (9.6, 0.3, 8.6), MARBLE, T)
    B(p, (-9.9, -3.1, 8.6), (9.9, 0.4, 9.0), GOLD, TP)
    B(p, (-8.5, -2.8, 9.0), (8.5, 0.2, 9.9), MARBLE, T)
    B(p, (-6.0, -2.8, 9.9), (6.0, 0.2, 10.8), MARBLE, T)
    B(p, (-3.2, -2.8, 10.8), (3.2, 0.2, 11.7), MARBLE, T)
    B(p, (-1.2, -2.8, 11.7), (1.2, 0.2, 12.4), GOLD, TP)
    scales_of_justice(p, 0, -3.05, 9.15, s=0.8)
    # potted palms flanking the steps
    palm(p, -10.0, -3.4, 0, 4.0, lean=(-1, -0.3))
    palm(p, 10.0, -3.4, 0, 4.0, lean=(1, -0.3))
    return p


def waiting_room():
    p = Piece("WaitingRoom")
    depth = 21.0
    floor(p, 0, depth, FLOOR_TILE)
    skirt(p, 0, depth, seed=3)
    side_walls(p, 0, depth, seed=1)
    for s in (-1, 1):
        # rug under each seating area
        lo, hi = sorted((s * 9.0, s * 22.4))
        B(p, (lo - 0.3, 2.2, 0), (hi + 0.3, 13.8, 0.04), RUG_EDGE, TP)
        B(p, (lo, 2.5, 0), (hi, 13.5, 0.07), RUG, T)
        # two chunky couches against the side wall, facing the aisle
        for y0 in (3.0, 8.5):
            x_back, x_front = s * 22.6, s * 19.4
            lo, hi = sorted((x_back, x_front))
            B(p, (lo, y0, 0), (hi, y0 + 4.6, 1.2), LEATHER_DARK)                              # base
            for i in range(2):
                cy0 = y0 + 0.4 + i * 1.95
                clo, chi = sorted((s * 21.8, x_front))
                B(p, (clo, cy0, 1.2), (chi, cy0 + 1.85, 1.7), CUSHION)                        # seat cushions
            blo, bhi = sorted((x_back, s * 21.6))
            B(p, (blo, y0, 1.2), (bhi, y0 + 4.6, 3.2), LEATHER)                               # back
            for ay in (y0, y0 + 4.6 - 0.6):
                B(p, (lo, ay, 1.2), (hi, ay + 0.6, 2.3), LEATHER_DARK)                         # arms
        # coffee table with magazines and a mug
        tlo, thi = sorted((s * 14.0, s * 17.5))
        B(p, (tlo, 4.5, 1.0), (thi, 11.5, 1.45), WOOD_LIGHT)
        for lx in (tlo + 0.35, thi - 0.35):
            for ly in (4.85, 11.15):
                B(p, (lx - 0.25, ly - 0.25, 0), (lx + 0.25, ly + 0.25, 1.0), WOOD_DARK, 0.25)
        mx = (tlo + thi) / 2
        F(p, (mx - 1.0, 5.4, 1.45), (mx + 0.4, 7.2, 1.55), MAG_RED)
        F(p, (mx - 0.6, 6.2, 1.55), (mx + 0.9, 8.0, 1.65), MAG_BLUE)
        F(p, (mx - 0.9, 9.0, 1.45), (mx + 0.6, 10.8, 1.55), MAG_YELLOW)
        B(p, (mx + 0.25, 9.9, 1.45), (mx + 0.75, 10.4, 2.0), CUSHION, 0.25)
        # armchair at the aisle end, facing the wall couches (-Y side open)
        alo, ahi = sorted((s * 9.4, s * 12.0))
        B(p, (alo, 14.0, 0), (ahi, 16.6, 1.2), LEATHER_DARK)
        B(p, (alo + 0.4, 14.1, 1.2), (ahi - 0.4, 16.0, 1.7), CUSHION)
        B(p, (alo, 16.0, 1.2), (ahi, 16.6, 3.1), LEATHER)
        for ax in (alo, ahi - 0.4):
            B(p, (ax, 14.0, 1.2), (ax + 0.4, 16.0, 2.2), LEATHER_DARK)
        palm(p, s * 21.8, 1.4, 0, 4.2, lean=(-s, 0.4))
        palm(p, s * 21.8, 19.4, 0, 4.6, lean=(-s, -0.4))
    # water cooler (left) and magazine rack (right), against the walls
    B(p, (-22.9, 15.2, 0), (-21.5, 16.6, 2.6), WHITE)
    B(p, (-22.75, 15.35, 2.6), (-21.65, 16.45, 3.9), WATER)
    B(p, (21.7, 14.5, 0), (23.0, 17.5, 3.2), WOOD)
    for i, mag in enumerate((MAG_RED, MAG_BLUE, MAG_YELLOW)):
        F(p, (21.5, 14.8 + i * 0.95, 1.0 + i * 0.7), (21.75, 15.6 + i * 0.95, 2.0 + i * 0.7), mag)
    # reception counter (right of the aisle) with bell, computer, papers and gold trim
    B(p, (8.0, 17.6, 0), (19.0, 19.6, 3.0), WOOD)
    B(p, (7.7, 17.3, 3.0), (19.3, 19.9, 3.4), WOOD_PLANK)
    B(p, (8.0, 17.4, 0.3), (19.0, 17.6, 0.9), WOOD_DARK)
    B(p, (8.2, 17.35, 1.5), (18.8, 17.6, 1.8), GOLD)
    F(p, (14.5, 18.3, 3.4), (16.3, 19.1, 3.5), DARK)
    B(p, (14.6, 19.15, 3.4), (16.2, 19.45, 4.7), DARK, 0.25)
    F(p, (14.75, 19.1, 3.55), (16.05, 19.15, 4.55), SCREEN)
    B(p, (9.7, 18.1, 3.4), (10.3, 18.7, 3.75), GOLD, 0.3)
    F(p, (11.4, 18.0, 3.4), (12.8, 19.0, 3.55), PAPER)
    scales_of_justice(p, 12.6, 19.4, 3.4, s=0.35)
    # velvet-rope queue on the left
    for y in (17.0, 19.6):
        for x in (-8.5, -13.5, -18.5):
            gold_post(p, x, y)
        for xa, xb in ((-13.5, -8.5), (-18.5, -13.5)):
            B(p, (xa, y - 0.12, 1.9), (xb, y + 0.12, 2.18), VELVET, 1.0)
    # divider into the offices: low balustrade with short posts and bushes (no overhead arch)
    for s in (-1, 1):
        lo, hi = sorted((s * 6.0, s * (W - 0.8)))
        B(p, (lo, 20.4, 0), (hi, 21.0, 2.0), WOOD)
        B(p, (lo - 0.1, 20.25, 2.0), (hi + 0.1, 21.15, 2.4), WOOD_PLANK)
        px = s * 6.6
        B(p, (px - 0.7, 20.0, 0), (px + 0.7, 21.4, 2.9), WOOD_DARK)
        B(p, (px - 0.8, 19.9, 2.9), (px + 0.8, 21.5, 3.2), WOOD)
        bush(p, px, 20.7, 3.2, 0.5)
    return p


def office_segment():
    p = Piece("OfficeSegment")
    depth = SEG
    floor(p, 0, depth, FLOOR_WOOD)
    skirt(p, 0, depth, seed=11)
    side_walls(p, 0, depth, seed=4)
    for s in (-1, 1):
        # partition between neighbouring offices: wood lower panel, glass top, chunky post at the aisle
        lo, hi = sorted((s * 8.5, s * (W - 0.8)))
        B(p, (lo, -0.25, 0), (hi, 0.25, 2.2), WOOD)
        B(p, (lo, -0.15, 2.2), (hi, 0.15, 3.8), GLASS)
        B(p, (lo, -0.3, 3.8), (hi, 0.3, 4.2), WOOD_PLANK)
        B(p, (s * 8.5 - 0.5, -0.5, 0), (s * 8.5 + 0.5, 0.5, 4.8), WOOD_DARK)
        B(p, (s * 8.5 - 0.6, -0.6, 4.8), (s * 8.5 + 0.6, 0.6, 5.1), WOOD)
    return p


def lawyer_desk():
    """One lawyer's office furniture, for the RIGHT side. Origin = slot centre on the floor.
    LawyerSpot = (+2.3, 0) facing -X; ClientSpot = (-2.6, 0) facing +X."""
    p = Piece("LawyerDesk")
    # chunky desk, long side along Y, front facing the aisle (-X)
    for y0, y1 in ((-2.5, -1.0), (1.0, 2.5)):
        B(p, (-1.15, y0, 0), (1.15, y1, 2.2), WOOD)
        for z in (0.55, 1.35):
            F(p, (-1.25, (y0 + y1) / 2 - 0.3, z), (-1.1, (y0 + y1) / 2 + 0.3, z + 0.2), GOLD_FLAT)
    B(p, (-1.0, -1.0, 0.5), (-0.7, 1.0, 2.2), WOOD_DARK)
    B(p, (-1.4, -2.8, 2.2), (1.4, 2.8, 2.65), WOOD_PLANK)
    B(p, (-1.5, -0.9, 2.3), (-1.4, 0.9, 2.6), GOLD, 0.15)                                    # nameplate
    # laptop, papers, pen cup, banker's lamp
    F(p, (-0.3, 0.2, 2.65), (0.8, 1.7, 2.75), DARK)
    F(p, (0.75, 0.2, 2.65), (0.88, 1.7, 3.6), DARK)
    F(p, (0.7, 0.3, 2.78), (0.75, 1.6, 3.5), SCREEN)
    F(p, (-0.6, -1.9, 2.65), (0.4, -0.7, 2.85), PAPER)
    F(p, (-0.5, -1.7, 2.85), (0.5, -0.9, 2.92), BOOKS_RED)
    B(p, (0.4, -2.3, 2.65), (0.8, -1.9, 3.2), METAL, 0.2)
    B(p, (0.65, 1.9, 2.65), (1.15, 2.4, 2.8), GOLD, 0.25)
    F(p, (0.85, 2.1, 2.8), (0.95, 2.2, 3.8), GOLD_FLAT)
    B(p, (0.5, 1.8, 3.7), (1.3, 2.5, 4.15), LEATHER, 0.35)
    # big comfy chair behind the lawyer
    B(p, (3.4, -0.4, 0), (4.4, 0.4, 0.3), DARK, 0.25)
    B(p, (3.7, -0.15, 0.3), (4.1, 0.15, 1.1), METAL, 0.2)
    B(p, (3.0, -1.0, 1.1), (4.7, 1.0, 1.7), LEATHER)
    B(p, (4.3, -1.0, 1.7), (4.9, 1.0, 4.5), LEATHER)
    for ay in (-1.0, 0.7):
        B(p, (3.1, ay, 1.7), (4.3, ay + 0.3, 2.4), LEATHER_DARK, 0.25)
    # bookshelf on the wall behind
    B(p, (6.0, -3.2, 0), (7.6, 3.2, 4.6), WOOD_DARK)
    for i, books in enumerate((BOOKS_RED, BOOKS_BLUE, BOOKS_GREEN, BOOKS_GOLD)):
        z0 = 0.3 + i * 1.05
        p.box((5.95, -2.95, z0), (6.1, 2.95, z0 + 0.8), books, 0.0, tile=1.0)
        B(p, (5.85, -3.2, z0 + 0.8), (6.2, 3.2, z0 + 0.95), WOOD, 0.25)
    B(p, (5.85, -3.3, 4.6), (7.7, 3.3, 4.9), WOOD)
    bush(p, 6.8, 2.2, 4.9, 0.45)
    # filing cabinet beside the bookshelf (offices are 11 deep now)
    B(p, (6.0, 3.7, 0), (7.6, 5.0, 2.6), WOOD_DARK)
    for z in (0.5, 1.3, 2.1):
        F(p, (5.9, 4.1, z), (6.0, 4.6, z + 0.15), GOLD_FLAT)
    bush(p, 6.8, 4.35, 2.6, 0.4)
    # client rug in front of the desk + potted plant in the corner
    B(p, (-4.2, -1.8, 0), (-1.6, 1.8, 0.06), RUG, 0.5)
    B(p, (4.9, -3.6, 0), (6.0, -2.5, 0.9), POT)
    bush(p, 5.45, -3.05, 0.9, 0.55)
    return p


def back_wall():
    p = Piece("BackWall")
    floor(p, 0, 3.0, FLOOR_WOOD)
    skirt(p, 0, 3.0, seed=21, back=True)
    side_walls(p, 0, 3.0, planters=False)
    B(p, (-W, 2.2, 0), (W, 3.0, 6.5), WALL, T)
    B(p, (-W - 0.3, 2.0, 6.5), (W + 0.3, 3.3, 7.1), WOOD_PLANK)
    B(p, (-W, 2.0, 7.1), (W, 3.3, 7.5), ROOF)
    for s in (-1, 1):
        for x0 in (6.0, 13.0):
            lo, hi = sorted((s * x0, s * (x0 + 6.0)))
            B(p, (lo, 1.2, 0), (hi, 2.2, 5.6), WOOD_DARK)
            for i, books in enumerate((BOOKS_BLUE, BOOKS_RED, BOOKS_GOLD, BOOKS_GREEN, BOOKS_RED)):
                z0 = 0.3 + i * 1.05
                p.box((lo + 0.25, 1.15, z0), (hi - 0.25, 1.3, z0 + 0.85), books, 0.0, tile=1.0)
                B(p, (lo, 1.05, z0 + 0.85), (hi, 1.4, z0 + 1.0), WOOD, 0.25)
        palm(p, s * 21.6, 1.0, 0, 4.6, lean=(-s, -0.3))
        # bushes outside the back wall
        bush(p, s * 8, 4.3, -FH, 0.8)
        bush(p, s * 18, 4.4, -FH, 0.9)
    B(p, (-4.5, 1.9, 1.0), (4.5, 2.2, 6.0), LEATHER_DARK)
    B(p, (-4.8, 1.85, 0.7), (4.8, 2.25, 1.1), GOLD)
    scales_of_justice(p, 0, 1.7, 1.7, s=1.4)
    return p


def expansion_lock():
    """A not-yet-bought section, as an outdoor construction site so it reads clearly as "not built yet":
    dirt + grass instead of floor, a wooden frame skeleton of the future walls, caution barrier with a gap
    in the middle (the Expand sign stands there), crate stacks, cones, plank and brick piles."""
    p = Piece("ExpansionLock")
    depth = SEG
    B(p, (-W, 0, -0.3), (W, depth, 0), DIRT, T)
    skirt(p, 0, depth, seed=31)
    for (x0, y0, x1, y1) in ((-23.2, 5.2, -15, depth), (-6, 6.2, 5, depth), (14, 1.8, 20, 4.4), (-13, 1.6, -7, 3.6),
                             (19, 6.0, 23.2, depth), (2, 3.2, 6, 5.0), (8, 8.0, 14, 10.0)):
        B(p, (x0, y0, 0), (x1, y1, 0.1), GRASS, T)
    # wooden frame skeleton where the next walls will go
    for s in (-1, 1):
        for y in (0.6, depth / 2, depth - 0.6):
            B(p, (s * (W - 0.4) - 0.35, y - 0.35, 0), (s * (W - 0.4) + 0.35, y + 0.35, 5.0), WOOD_LIGHT)
        lo, hi = sorted((s * (W - 0.75), s * (W - 0.05)))
        B(p, (lo, 0.25, 5.0), (hi, depth - 0.25, 5.5), WOOD_LIGHT)
        B(p, (lo, 0.25, 2.3), (hi, depth - 0.25, 2.6), WOOD_LIGHT)
        bush(p, s * (W + 1.4), 6.0, -FH, 0.8)
    # caution barrier across the front (yellow/black rails on wood posts), gap in the middle for the path
    for s in (-1, 1):
        for x in (3.2, 8.0, 13.0, 18.0, 22.8):
            B(p, (s * x - 0.35, 0.3, 0), (s * x + 0.35, 1.0, 2.6), WOOD_DARK)
        lo, hi = sorted((s * 3.2, s * 22.8))
        for z in (0.9, 1.8):
            B(p, (lo, 0.45, z), (hi, 0.85, z + 0.5), CAUTION, 1.0)
    # the path continues into the site as dirt-dashes leading to the sign
    B(p, (-4.0, 0, 0), (4.0, 2.4, 0.05), PATH, T)
    # crate stacks (big, reference-style X crates), cones, plank pile, brick pile, sand pile
    for (x, y, z, sz) in ((-20.0, 4.3, 0, 2.2), (-17.6, 4.6, 0, 1.8), (-19.4, 4.4, 2.2, 1.6), (-15.6, 5.8, 0, 1.4),
                          (18.4, 5.4, 0, 2.0), (20.6, 5.0, 0, 1.6), (18.6, 5.5, 2.0, 1.4)):
        crate(p, x, y, z, sz)
    for (x, y) in ((-5.0, 1.8), (5.0, 1.8), (-11.5, 6.0), (11.0, 2.6), (-23.0, 1.6)):
        cone(p, x, y)
    for i in range(4):
        B(p, (8.0 + i * 0.15, 5.0 + i * 0.1, i * 0.3), (14.0 + i * 0.15, 5.9 + i * 0.1, i * 0.3 + 0.3), WOOD_LIGHT, 1.0)
    for i, (w, d) in enumerate(((3.0, 1.6), (2.2, 1.2), (1.2, 0.8))):                       # brick pile
        B(p, (13.0 - w / 2, 2.6 - d / 2, i * 0.5), (13.0 + w / 2, 2.6 + d / 2, i * 0.5 + 0.5), ROOF, 0.5)
    B(p, (-12.5, 1.8, 0), (-8.5, 4.4, 0.5), SAND, 0.5)
    B(p, (-12.0, 2.2, 0.5), (-9.0, 4.0, 0.9), SAND, 0.5)
    B(p, (-11.2, 2.6, 0.9), (-9.8, 3.6, 1.25), SAND, 0.5)
    return p


PIECES = [entrance, waiting_room, office_segment, lawyer_desk, back_wall, expansion_lock]
