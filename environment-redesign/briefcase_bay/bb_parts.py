# environment-redesign/briefcase_bay/bb_parts.py - Briefcase Bay's buildings + props (Stage 5, 2026-10-18).
# World 1: a bright business & legal district. Palette: blues, greens, whites, warm wood / orange accents.
# Every function builds in a LOCAL frame (hl_kit.Frame): origin = the piece's centre on the ground, front = local -y.
# Firm names on signs are fictional (CLAUDE.md: no real people or brands).
import math
import hl_kit as K

rng = K.rng


def polar(r, deg):
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


# ------------------------------------------------------------------ signs
def board(F, x, y, z, w, h, text, bg="roof_navy", fg="gold", trim="gold", size=None, rot=0.0, kind="bold"):
    G = F.sub(x, y, rot)
    G.brick(0, 0, z, w, 0.6, h, bg, studs=False)
    G.brick(0, 0, z - 0.2, w + 0.5, 0.75, 0.35, trim, studs=False)
    G.brick(0, 0, z + h - 0.15, w + 0.5, 0.75, 0.35, trim, studs=False)
    G.text(text, 0, -0.4, z + h / 2, size or h * 0.5, fg, kind=kind, extrude=0.12)


def marquee(F, x, y, z, w, h, text, size=None, rot=0.0, post_h=None):
    """The attraction sign: black panel, gold letters, bulbs top and bottom."""
    G = F.sub(x, y, rot)
    if post_h:
        for sgn in (-1, 1):
            G.brick(sgn * (w / 2 - 0.6), 0.4, 0, 0.8, 0.8, post_h, "metal_dark", studs=False)
    G.brick(0, 0, z, w, 0.8, h, "black", studs=False)
    for zz in (z - 0.25, z + h - 0.15):
        G.brick(0, 0, zz, w + 0.6, 1.0, 0.4, "gold", studs=False)
    n = max(3, int(w / 1.6))
    for k in range(n):
        bx = -w / 2 + 0.8 + k * (w - 1.6) / (n - 1)
        for zz in (z + 0.2, z + h - 0.65):
            G.brick(bx, -0.45, zz, 0.45, 0.3, 0.45, "glow_bulb", studs=False, bevel=0.1)  # (its own look: the bulbs chase)
    G.text(text, 0, -0.5, z + h / 2, size or h * 0.46, "gold", kind="bold", extrude=0.2)


# ------------------------------------------------------------------ buildings
def office_tower(F, w=24, d=20, floors=9, glass="glass_dark", frame="white", accent="roof_blue", name="LEXICON LAW", crown="stepped"):
    """A glass office tower: stone podium lobby, banded glass floors with mullions, a set-back top, a lit crown."""
    FL = 4.2
    F.brick(0, 0, 0, w + 4, d + 4, 0.8, "stone_warm")
    F.brick(0, 0, 0.8, w, d, 6.0, "glass", studs=False, bevel=0.0)  # lobby glass
    for x in [-w / 2 + 1 + k * (w - 2) / 5 for k in range(6)]:
        F.brick(x, -d / 2 - 0.3, 0.8, 1.4, 1.0, 6.0, "stone", studs=False)  # lobby piers
    F.brick(0, 0, 6.8, w + 1.2, d + 1.2, 0.9, frame, studs=False)
    H = 7.7 + floors * FL
    top = floors - 2 if crown == "stepped" else floors
    F.brick(0, 0, 7.7, w, d, top * FL, glass, studs=False, bevel=0.0)
    for k in range(top + 1):
        F.brick(0, 0, 7.7 + k * FL - 0.25, w + 0.5, d + 0.5, 0.5, frame, studs=False)
    for x in [-w / 2 + k * w / 8 for k in range(9)]:
        F.brick(x, -d / 2 - 0.15, 7.7, 0.45, 0.5, top * FL, frame, studs=False)
        F.brick(x, d / 2 + 0.15, 7.7, 0.45, 0.5, top * FL, frame, studs=False)
    for y in [-d / 2 + k * d / 6 for k in range(7)]:
        for sx in (-1, 1):
            F.brick(sx * (w / 2 + 0.15), y, 7.7, 0.5, 0.45, top * FL, frame, studs=False)
    zt = 7.7 + top * FL
    if crown == "stepped":  # two set-back floors + a lit crown
        F.brick(0, 1, zt, w - 6, d - 4, 2 * FL, glass, studs=False, bevel=0.0)
        for k in range(3):
            F.brick(0, 1, zt + k * FL - 0.25, w - 5.5, d - 3.5, 0.5, frame, studs=False)
        F.brick(0, -d / 2 + 1.0, zt, w + 0.6, 1.4, 1.2, accent)  # terrace edge
        F.brick(0, 1, zt + 2 * FL, w - 5, d - 3, 1.0, frame)
        F.brick(0, 1, zt + 2 * FL + 1.0, w - 9, d - 7, 3.0, accent)
        F.brick(0, -d / 2 + 2.9, zt + 2 * FL + 1.4, w - 9.6, 0.3, 2.2, "glow_cyan", studs=False, bevel=0.02)
        zt = zt + 2 * FL + 4.0
    else:
        F.brick(0, 0, zt, w + 0.8, d + 0.8, 1.2, frame)
        zt += 1.2
    for k, (x, y) in enumerate(((-w / 4, d / 5), (w / 5, -d / 6), (w / 4, d / 4))):  # roof plant
        F.brick(x * 0.6, y * 0.6, zt, 3, 3, 2, "metal", studs=True)
        F.cyl(x * 0.6, y * 0.6, 1.0, zt + 2, zt + 2.3, "metal_dark", segs=10)
    F.cyl(w / 6, 0, 0.3, zt, zt + 9, "metal", segs=6)
    F.sphere(w / 6, 0, zt + 9.3, 0.5, 0.5, 0.5, "glow_red", seg=8, rings=5)
    # entrance: canopy, revolving door, name band
    F.brick(0, -d / 2 - 2.5, 5.6, 12, 5, 0.6, accent, studs=False)
    for sgn in (-1, 1):
        F.brick(sgn * 5.4, -d / 2 - 4.6, 0.8, 0.5, 0.5, 4.8, "metal", studs=False)
    F.cyl(0, -d / 2 - 0.2, 1.8, 0.8, 5.0, "glass", segs=12)
    F.cyl(0, -d / 2 - 0.2, 1.9, 5.0, 5.3, "metal", segs=12)
    if name:
        F.brick(0, -d / 2 - 0.7, 7.95, w * 0.7, 0.4, 2.2, frame, studs=False)
        F.text(name, 0, -d / 2 - 1.0, 9.05, 1.3, accent, kind="bold", extrude=0.1)
    return H


def office_block(F, w=26, d=18, floors=4, wall="cream", trim="white", roof="stone_warm", name=None, shutters="roof_blue"):
    """A mid-rise: punched windows with shutters, string courses, a cornice, a studded roof with plant + water tank."""
    FL = 5.0
    F.brick(0, 0, 0, w + 3, d + 3, 0.8, "stone_warm")
    F.brick(0, 0, 0.8, w, d, floors * FL, wall, studs=False)
    for k in range(1, floors):
        F.brick(0, 0, 0.8 + k * FL - 0.3, w + 0.6, d + 0.6, 0.5, trim, studs=False)
    for fl in range(floors):
        z = 2.2 + fl * FL
        nx = max(2, int(w / 5.5))
        for i in range(nx):
            x = -w / 2 + (i + 0.5) * w / nx
            if fl == 0 and abs(x) < 3.5:
                continue
            K.window(F, x, -d / 2 - 0.05, z, 2.6, 3.0, 0, frame=trim, shutters=shutters if fl % 2 else None)
        for sx in (-1, 1):
            for i in range(max(2, int(d / 6))):
                y = -d / 2 + (i + 0.5) * d / max(2, int(d / 6))
                K.window(F.sub(sx * (w / 2 + 0.05), y, rot=90 * sx), 0, 0, z, 2.6, 3.0, 0, frame=trim, depth=0.5)
    K.door(F, 0, -d / 2 - 0.05, 0.8, 4, 6.2, 0, frame=trim, leaf="roof_navy", arch=True)
    H = 0.8 + floors * FL
    F.brick(0, 0, H, w + 1.4, d + 1.4, 1.0, trim, studs=False)
    F.brick(0, 0, H + 1.0, w, d, 0.5, roof)
    for sx in (-1, 1):  # water tank on stilts
        F.brick(w / 4 + sx * 1.5, d / 5, H + 1.5, 0.5, 0.5, 3, "wood_dark", studs=False)
    F.cyl(w / 4, d / 5, 2.4, H + 4.5, H + 8, "wood", segs=14, studs=True)
    F.cone(w / 4, d / 5, 2.6, H + 8, H + 9.6, "wood_dark", segs=14)
    F.brick(-w / 4, -d / 6, H + 1.5, 4, 3, 2, "metal")
    if name:
        board(F, 0, -d / 2 - 0.5, 7.0 if floors > 1 else 4.0, min(w - 4, 16), 2.4, name, size=1.3)
    return H


def law_library(F):
    F.brick(0, 0, 0, 32, 24, 2.4, "stone")
    K.stairs(F, 0, -17.8, 0, 16, 4, 0.6, 1.4, 90, look="marble")
    F.brick(0, 2, 2.4, 26, 18, 12, "cream", studs=False)
    for x in (-9, -3, 3, 9):
        K.column(F, x, -9.2, 2.4, 11, 1.6)
    F.brick(0, -9.2, 13.4, 22, 3, 1.6, "marble", studs=False)
    F.brick(0, -10.75, 13.6, 16, 0.3, 1.2, "roof_navy", studs=False)
    F.text("LAW LIBRARY", 0, -10.95, 14.2, 1.0, "gold", kind="bold", extrude=0.08)
    for k in range(5):
        F.brick(0, -8.8, 15.0 + k * 0.9, 24 - k * 5, 4, 0.9, "marble")
    F.brick(0, 2, 14.4, 27, 19, 0.8, "white", studs=False)
    F.roof_hip(0, 3, 15.2, 25, 15, 4, "roof_teal", trim="gold", cap="gold")
    K.door(F, 0, -6.95, 2.4, 4, 7, 0, frame="gold", leaf="wood_dark", arch=True)
    for sx in (-1, 1):
        K.window(F.sub(sx * 13.05, 2, rot=90 * sx), 0, 0, 5, 3, 6, 0, frame="white", mullions=1, depth=0.5)
        for k in range(3):  # stacks of books by the door
            F.brick(sx * 6.2, -11.5, 2.4 + k * 0.6, 1.8, 1.2, 0.6, ["red", "roof_blue", "sign_green"][k], rot=k * 9, studs=False, bevel=0.05)


def coffee_shop(F):
    F.brick(0, 0, 0, 22, 18, 0.8, "stone_warm")
    F.brick(0, 3, 0.8, 18, 12, 7.5, "brick_red", studs=False)
    F.brick(0, 3, 8.3, 19, 13, 0.8, "white", studs=False)
    F.brick(0, 3, 9.1, 17, 11, 0.4, "stone_warm")
    K.window(F, -5, -3.05, 2.0, 5.5, 4.2, 0, frame="white", mullions=2)
    K.window(F, 5, -3.05, 2.0, 5.5, 4.2, 0, frame="white", mullions=2)
    K.door(F, 0, -3.05, 0.8, 3, 5.6, 0, frame="white", leaf="sign_green")
    for k in range(10):  # green / white awning
        x = -9 + (k + 0.5) * 1.8
        for j in range(3):
            F.brick(x, -3.7 - j * 0.9, 7.0 - j * 0.5, 1.8, 1.0, 0.55, "sign_green" if k % 2 == 0 else "awning_white", studs=(j == 0))
    board(F, 0, -3.3, 8.6, 12, 2.4, "COFFEE BREAK", bg="sign_green", fg="white", trim="white", size=1.15)
    # giant cup on the roof (the steam rises in the ambience pass)
    F.cyl(0, 4, 2.6, 9.5, 14.5, "white", segs=20, bevel=0.2)
    F.cyl(0, 4, 2.7, 11.0, 12.6, "wood", segs=20)
    F.ring_v(3.0, 4, 12.0, 1.0, 1.6, 0.6, "white", rot=0, segs=10, gap=0.05)
    F.cyl(0, 4, 2.2, 14.5, 14.7, "wood_dark", segs=20)
    for k, (x, y) in enumerate(((-7, -8.5), (0, -9.5), (7, -8.5))):  # tables + umbrellas
        F.cyl(x, y, 1.3, 0.8, 3.0, "white", segs=10)
        F.cyl(x, y, 0.2, 3.0, 6.0, "metal_dark", segs=6)
        F.cone(x, y, 3.2, 5.8, 7.0, "sign_green" if k % 2 == 0 else "orange", segs=8)
        for sgn in (-1, 1):
            F.brick(x + sgn * 2.0, y, 0.8, 1.1, 1.1, 1.6, "wood", studs=False)


def kiosk(F):
    F.brick(0, 0, 0, 6, 5, 0.6, "stone_warm")
    F.brick(0, 0.5, 0.6, 5, 3.6, 3.4, "sign_green", studs=False)
    F.brick(0, -1.5, 2.2, 5.2, 1.2, 0.3, "wood", studs=False)  # counter
    for k in range(4):  # newspaper stacks
        F.brick(-1.8 + k * 1.2, -1.6, 2.5, 1.0, 0.8, 0.3 + 0.2 * (k % 2), "white", studs=False, bevel=0.03)
    F.roof_hip(0, 0.2, 4.0, 5.4, 4.6, 1.6, "sign_green", cap="gold", overhang=0.4, courses=2)
    F.brick(0, -2.2, 4.0, 4.4, 0.3, 1.0, "white", studs=False)
    F.text("NEWS", 0, -2.4, 4.5, 0.6, "sign_green", kind="bold", extrude=0.05)


def bus_stop(F):
    F.brick(0, 0, 0, 9, 4, 0.4, "stone")
    for sx in (-1, 1):
        F.brick(sx * 4, 1.2, 0.4, 0.4, 0.4, 5.2, "metal", studs=False)
    F.brick(0, 1.6, 0.4, 8.4, 0.3, 4.6, "glass", studs=False, bevel=0.0)
    F.brick(0, 0.4, 5.6, 9.2, 3.2, 0.4, "roof_blue")
    K.bench(F, 0, 0.6, 0)
    F.brick(5.2, -1.2, 0.4, 0.3, 0.3, 6.5, "metal", studs=False)
    F.cyl(5.2, -1.2, 0.9, 6.0, 6.3, "roof_blue", segs=12)


def traffic_light(F, x, y, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, 0.5, 0.5, 6.5, "black", studs=False)
    G.brick(0, -0.2, 6.5, 1.2, 1.0, 3.2, "black", studs=False)
    for k, lk in enumerate(("glow_red", "yellow", "glow_green")):
        G.brick(0, -0.75, 9.0 - k * 1.0, 0.7, 0.2, 0.7, lk, studs=False, bevel=0.15)


def filing_planter(F, x, y, rot=0.0):
    """A filing cabinet turned planter (office humour)."""
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, 2.4, 2.0, 3.4, "metal", studs=False)
    for k in range(3):
        G.brick(0, -1.05, 0.3 + k * 1.05, 2.0, 0.2, 0.8, "metal_dark", studs=False, bevel=0.03)
        G.brick(0, -1.2, 0.6 + k * 1.05, 0.7, 0.2, 0.2, "gold", studs=False, bevel=0.03)
    G.brick(0, 0, 3.4, 2.4, 2.0, 1.2, "leaf")
    G.brick(0.3, 0.2, 4.6, 1.2, 1.2, 0.8, "leaf_light")


def water_cooler(F, x, y):
    F.brick(x, y, 0, 1.4, 1.4, 2.8, "white", studs=False)
    F.cyl(x, y, 0.6, 2.8, 4.4, "glass", segs=10)
    F.brick(x, y - 0.75, 1.8, 0.4, 0.2, 0.3, "roof_blue", studs=False)


# ------------------------------------------------------------------ monuments
def giant_briefcase(F, s=1.0, look="wood_dark"):
    F.brick(0, 0, 0, 12 * s, 7 * s, 2 * s, "marble")
    F.brick(0, 0, 2 * s, 12.6 * s, 7.6 * s, 0.4 * s, "gold", studs=False)
    F.brick(0, 0, 2.4 * s, 10 * s, 4 * s, 7 * s, look, studs=False)
    for z in (2.4, 9.0):
        F.brick(0, 0, z * s, 10.3 * s, 4.3 * s, 0.4 * s, "gold", studs=False)
    for sx in (-1, 1):
        F.brick(sx * 3 * s, -2.15 * s, 7.4 * s, 1.4 * s, 0.4 * s, 1.0 * s, "gold", studs=False)  # clasps
        F.brick(sx * 1.6 * s, 0, 9.4 * s, 0.7 * s, 1.0 * s, 1.8 * s, "gold", studs=False)
    F.brick(0, 0, 11.0 * s, 3.9 * s, 1.0 * s, 0.7 * s, "gold", studs=False)  # handle


def giant_gavel(F, s=1.0):
    F.brick(0, 0, 0, 10 * s, 10 * s, 1.6 * s, "marble")
    F.cyl(0, 0, 4.0 * s, 1.6 * s, 3.4 * s, "wood_dark", segs=20, studs=True)  # sound block
    F.cyl(0, 0, 4.2 * s, 3.0 * s, 3.4 * s, "gold", segs=20)
    for k in range(6):  # the handle, leaning
        F.brick((-0.4 + k * 0.6) * s, 0, (3.4 + k * 1.3) * s, 0.9 * s, 0.9 * s, 1.4 * s, "wood", rot=0, studs=False)
    F.brick(3.2 * s, 0, 10.8 * s, 6.0 * s, 3.0 * s, 3.0 * s, "wood_dark", studs=False, bevel=0.3 * s)  # head
    for sx in (-1, 1):
        F.brick((3.2 + sx * 2.4) * s, 0, 10.7 * s, 0.6 * s, 3.2 * s, 3.2 * s, "gold", studs=False)


def welcome_gate(F, width=24):
    for sx in (-1, 1):
        x = sx * (width / 2 + 1.6)
        F.brick(x, 0, 0, 4, 4, 1.2, "stone_dark")
        F.brick(x, 0, 1.2, 3, 3, 14, "roof_navy", studs=False)
        F.brick(x, 0, 15.2, 3.8, 3.8, 0.8, "gold", studs=False)
        F.sphere(x, 0, 16.8, 1.2, 1.2, 1.2, "glow_gold", seg=10, rings=6)
        for k in range(3):
            F.brick(x, -1.6, 3 + k * 4, 2, 0.3, 0.4, "gold", studs=False)
    F.brick(0, 0, 13.2, width + 6, 2.6, 1.6, "roof_navy", studs=False)
    marquee(F, 0, -1.5, 14.6, width - 2, 4.2, "BRIEFCASE BAY", size=2.0)
    giant_briefcase(F.sub(0, 0.6, z=18.9), 0.45, "orange")


# ------------------------------------------------------------------ arrival + return portal
def arrival_pad(F):
    F.cyl(0, 0, 9.0, 0, 0.5, "stone_dark", segs=40)
    F.cyl(0, 0, 8.0, 0.5, 0.9, "marble", segs=40, studs=True)
    F.ring(6.2, 7.2, 0.9, 1.1, "glow_cyan", segs=40)
    F.cyl(0, 0, 4.0, 0.9, 1.05, "roof_blue", segs=24)
    for k in range(4):
        x, y = polar(8.6, k * 90 + 45)
        F.brick(x, y, 0.5, 1.4, 1.4, 4.5, "white", studs=False)
        F.sphere(x, y, 5.6, 0.8, 0.8, 0.8, "glow_cyan", seg=10, rings=6)


def return_portal(F):
    """RETURN HOME (crnuch's call: past the boss): the way home WITH eggs. Green + gold, a briefcase keystone."""
    F.cyl(0, 2, 20, 0, 1.4, "stone_dark", segs=48)
    F.cyl(0, 2, 18, 1.4, 3.2, "stone", segs=48, bevel=0.3)
    F.ring(17.6, 18.4, 3.2, 3.7, "gold", cx=0, cy=2, segs=48)
    F.cyl(0, 2, 15, 3.2, 4.6, "marble", segs=48, studs=True)
    F.ring(14.6, 15.4, 4.6, 4.9, "glow_green", cx=0, cy=2, segs=48)
    K.stairs(F, 0, -22.4, 0, 12, 6, 0.77, 1.15, 90, look="marble")
    for sgn in (-1, 1):
        F.brick(sgn * 7.0, -19.0, 0, 2.0, 7.6, 5.0, "stone")
        F.brick(sgn * 7.0, -19.0, 5.0, 2.4, 8.0, 0.5, "gold", studs=False)
    cz = 4.6 + 14.2
    F.ring_v(0, 3, cz, 11.8, 14.6, 3.4, ["sign_green", "sign_green", "teal"], segs=28, gap=0.18)
    F.ring_v(0, 1.1, cz, 14.4, 15.2, 0.6, "gold", segs=28, gap=0.1)
    F.ring_v(0, 1.1, cz, 11.1, 11.8, 0.6, "gold", segs=28, gap=0.1)
    F.disc_v(0, 3, cz, 11.8, 0.5, "portal_home", segs=40)
    for k in range(8):
        a = math.radians(k * 45 + 22.5)
        F.brick(13.2 * math.cos(a), 1.0, cz + 13.2 * math.sin(a) - 0.6, 1.2, 0.4, 1.2, "glow_gold", studs=False, bevel=0.1)
    for sgn in (-1, 1):
        F.brick(sgn * 9.0, 3, 4.6, 6, 6, 3.4, "stone_dark")
        F.brick(sgn * 9.0, 3, 8.0, 5.4, 5.4, 1.4, "stone")
    giant_briefcase(F.sub(0, 3, z=cz + 13.6), 0.38, "gold")
    marquee(F, -15.5, -19.5, 6.0, 12, 3.4, "RETURN HOME", size=1.25, post_h=6.0, rot=20)


# ------------------------------------------------------------------ boss arena: Partners' Plaza
def partners_plaza(F, R=62, openings=(270, 90)):
    """An open, studded arena (the boss roams the whole floor - nothing stands inside R), boardroom dressing outside."""
    F.cyl(0, 0, R, 0, 0.4, "stone", segs=96, studs=True)
    F.ring(R - 8, R - 6.5, 0.4, 0.5, "gold", segs=96)
    F.ring(28, 30, 0.4, 0.5, "gold", segs=72)
    F.ring(30, R - 8, 0.4, 0.45, "roof_blue", segs=96, studs=True)
    # the inlaid emblem: gold scales flat in the floor
    F.brick(0, 0, 0.4, 2, 18, 0.12, "gold", studs=False, bevel=0.02)
    F.brick(0, 7, 0.4, 20, 1.6, 0.12, "gold", studs=False, bevel=0.02)
    for sx in (-1, 1):
        F.cyl(sx * 9, 2, 4.5, 0.4, 0.52, "gold", segs=20)
    F.cyl(0, -9, 5, 0.4, 0.52, "gold", segs=20)
    # rim: planters + low hedges, open where the routes come in
    for k in range(48):
        a = k * 7.5
        if any(abs(((a - o + 180) % 360) - 180) < 14 for o in openings):
            continue
        x, y = polar(R + 2.5, a)
        if k % 6 == 0:
            K.planter(F, x, y, 4, 4, plant="bush")
        else:
            K.hedge(F, x, y, 5.6, a + 90, h=2.2, w=2.2)
    # boardroom chairs + floodlight towers outside the rim
    for k in range(8):
        a = k * 45 + 22.5
        if any(abs(((a - o + 180) % 360) - 180) < 20 for o in openings):
            continue
        x, y = polar(R + 9, a)
        G = F.sub(x, y, a + 90)
        G.brick(0, 0, 0, 1.0, 1.0, 3.5, "black", studs=False)
        G.brick(0, 0, 3.5, 6, 6, 1.4, "roof_navy")
        G.brick(0, 2.6, 4.9, 6, 1.0, 7, "roof_navy", studs=False)
        for sx in (-1, 1):
            G.brick(sx * 3.2, 0.3, 4.9, 0.8, 5, 1.2, "black", studs=False)
        for j in range(5):
            jx, jy = polar(2.6, j * 72)
            G.brick(jx, jy, 0, 3.0, 0.6, 0.5, "black", rot=j * 72, studs=False)
    for a in (45, 135, 225, 315):
        x, y = polar(R + 16, a)
        G = F.sub(x, y, a + 90)
        G.brick(0, 0, 0, 3, 3, 1, "stone_dark")
        G.brick(0, 0, 1, 1.2, 1.2, 22, "metal", studs=False)
        G.brick(0, -0.6, 22, 7, 1.6, 4, "metal_dark", studs=False)
        for j in range(3):
            G.brick(-2.2 + j * 2.2, -1.5, 22.6, 1.7, 0.3, 2.8, "glow_white", studs=False, bevel=0.05)
    marquee(F, 0, -R - 12, 7.0, 22, 4, "PARTNERS' PLAZA", size=1.7, post_h=7.0)


# ------------------------------------------------------------------ the bay: harbour basin, boardwalk, moored boat
def harbour(F, R=22):
    # a quay wall round the basin; the water surface sits just below the quay top (z 0.9 vs 1.6)
    F.ring(R, R + 2.5, 0.0, 1.6, "stone_warm", segs=40, studs=True)
    F.ring(R - 0.4, R, 0.0, 0.9, "stone_dark", segs=40)
    F.cyl(0, 0, R - 0.2, 0.0, 0.9, "water", segs=40)
    for k in range(10):  # bollards on the quay
        x, y = polar(R + 1.2, k * 36 + 18)
        F.cyl(x, y, 0.5, 1.6, 2.8, "black", segs=8)
        F.cyl(x, y, 0.65, 2.8, 3.1, "black", segs=8)
    # boardwalk pier into the basin (just above the water)
    for k in range(9):
        F.brick(-R + 2 + k * 2.2, -6, 1.0, 2.1, 5, 0.5, "wood" if k % 2 else "wood_dark")
    for k in range(5):
        for sgn in (-1, 1):
            F.brick(-R + 2 + k * 4.4, -6 + sgn * 2.6, -2.0, 0.6, 0.6, 3.4, "wood_dark", studs=False)
    # a little office ferry, moored
    G = F.sub(2, 4, 15)
    G.brick(0, 0, -0.6, 14, 6, 1.8, "white", studs=False)
    G.brick(0, 0, -1.4, 13, 5.2, 0.8, "red", studs=False)
    G.brick(7.6, 0, -0.6, 2, 4, 1.8, "white", studs=False)  # the bow
    G.brick(-1, 0, 1.2, 7, 4.4, 3, "roof_blue", studs=False)
    for x in (-3.4, -1, 1.4):
        G.brick(x, -2.25, 2.4, 1.6, 0.3, 1.2, "glass", studs=False, bevel=0.0)
    G.brick(-1, 0, 4.2, 7.6, 5, 0.6, "white")
    G.cyl(-3.2, 0, 0.6, 4.8, 7.2, "red", segs=10)
    G.brick(-1, -2.5, 1.4, 4, 0.2, 0.8, "white", studs=False)
    G.text("BAY FERRY", -1, -2.65, 1.8, 0.5, "roof_navy", kind="bold", extrude=0.04)
    F.cyl(-10, 9, 1.2, -0.4, 1.8, "red", segs=10)  # buoy
    F.cone(-10, 9, 1.2, 1.8, 3.2, "white", segs=10)


# ------------------------------------------------------------------ eggs (in game: EggLook, ZoneService spots)
def briefcase_egg(F, x, y, s=1.0, golden=False):
    body = "gold" if golden else "wood"
    band = "glow_gold" if golden else "gold"
    K.voxel_round(F, x, y, 0, lambda t: 1.6 * s * (math.sqrt(max(0, 1 - ((0.4 - t) / 0.4) ** 2)) if t < 0.4 else math.sqrt(max(0, 1 - ((t - 0.4) / 0.6) ** 1.7))),
                  4.2 * s, body, step=0.35 * s, segs=14, studs=False, looks=lambda k: band if k in (4, 5) else body)
    F.brick(x, y, 4.1 * s, 1.2 * s, 0.35 * s, 0.4 * s, band, studs=False, bevel=0.05)
    F.brick(x - 0.45 * s, y, 3.8 * s, 0.25 * s, 0.35 * s, 0.6 * s, band, studs=False, bevel=0.03)
    F.brick(x + 0.45 * s, y, 3.8 * s, 0.25 * s, 0.35 * s, 0.6 * s, band, studs=False, bevel=0.03)


def egg_spot(F, x, y):
    """Where an egg can appear (ZoneService EggSpots): a gold ring set in the ground."""
    F.ring(1.6, 2.2, 0.0, 0.12, "gold", cx=x, cy=y, segs=16)
