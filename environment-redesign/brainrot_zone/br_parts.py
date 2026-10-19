# environment-redesign/brainrot_zone/br_parts.py - Brainrot Zone's models (Stage 5, island 3, 2026-10-19).
# A surreal, chaotic, neon cartoon district (the game's zone: Brainrot Boulevard). Palette: purple, magenta, cyan,
# neon accents. Exciting, never strobing (the brief: no excessive flashing). Local frames: front = local -y.
# Faces on screens / props are original cartoon faces (fictional).
import math
import hl_kit as K
import hl_world as W

rng = K.rng
polar = W.polar


# ------------------------------------------------------------------ neon bits
def neon_strip(F, x0, y0, x1, y1, z, look="glow_cyan", w=0.4, h=0.25):
    L = math.hypot(x1 - x0, y1 - y0)
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    F.brick((x0 + x1) / 2, (y0 + y1) / 2, z, L, w, h, look, rot=a, studs=False, bevel=0.05)


def neon_sign(F, x, y, z, w, h, text, frame="glow_magenta", letters="glow_cyan", rot=0.0, size=None, post_h=None):
    """A neon sign: dark panel, glowing frame, glowing letters."""
    G = F.sub(x, y, rot)
    if post_h:
        G.brick(0, 0.5, 0, 1.0, 1.0, post_h + 0.2, "night", studs=False)
    G.brick(0, 0, z, w, 0.7, h, "night", studs=False)
    for zz in (z - 0.15, z + h - 0.15):
        G.brick(0, -0.2, zz, w + 0.4, 0.5, 0.3, frame, studs=False, bevel=0.05)
    for sx in (-1, 1):
        G.brick(sx * (w / 2 + 0.05), -0.2, z, 0.3, 0.5, h, frame, studs=False, bevel=0.05)
    G.text(text, 0, -0.45, z + h / 2, size or h * 0.48, letters, kind="bold", extrude=0.15)


def wobble_lamp(F, x, y, lean=8.0, rot=0.0, head="glow_magenta", h=11.0):
    """A bendy lamp post: stacked segments drifting sideways, a glowing ball on top."""
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, 1.8, 1.8, 0.8, "night", studs=False)
    off = 0.0
    for k in range(7):
        off += math.sin(math.radians(lean)) * 1.5 * (1 + k * 0.15)
        G.brick(off * 0.4, 0, 0.8 + k * 1.5, 0.6, 0.6, 1.55, "violet", studs=False, bevel=0.1)
    G.sphere(off * 0.4, 0, 0.8 + 7 * 1.5 + 0.8, 1.0, 1.0, 1.0, head, seg=12, rings=8)


# ------------------------------------------------------------------ surreal buildings
def twisty_tower(F, w=16, floors=12, looks=("violet", "magenta", "lilac"), trim="glow_cyan"):
    """Each floor turned a little more than the last - a tower in a slow spin."""
    F.brick(0, 0, 0, w + 6, w + 6, 1.0, "night")
    FL = 4.0
    for k in range(floors):
        rot = k * 7.5
        z = 1.0 + k * FL
        F.brick(0, 0, z, w, w, FL - 0.5, looks[k % len(looks)], rot=rot, studs=False)
        F.brick(0, 0, z + FL - 0.5, w + 1.2, w + 1.2, 0.5, trim if k % 3 == 0 else "night", rot=rot, studs=False)
        for j in range(4):  # window strips on each face
            a = rot + j * 90
            ox, oy = polar(w / 2 + 0.05, a - 90)
            F.brick(ox, oy, z + 1.0, w * 0.7, 0.2, 1.6, "glow_white" if (k + j) % 3 else "glow_magenta", rot=a, studs=False, bevel=0.02)
    top = 1.0 + floors * FL
    K.voxel_round(F, 0, 0, top, lambda t: w * 0.45 * (1 - t) + 0.4, 8, "magenta", step=1.0, segs=16)  # stepped spire
    F.sphere(0, 0, top + 9.5, 1.6, 1.6, 1.6, "glow_cyan", seg=14, rings=8)
    neon_sign(F, 0, -w / 2 - 3, 4.5, 12, 3, "TWISTY", post_h=4.5)
    return top


def big_screen(F, w=28, d=16, h=30):
    """A dark tower with a giant cartoon-face screen (the reference's neon face building), fictional face."""
    F.brick(0, 0, 0, w + 4, d + 4, 1.0, "night")
    F.brick(0, 0, 1.0, w, d, h, "night", studs=False)
    for k in range(int(h / 4)):  # window bands on the sides
        for sx in (-1, 1):
            F.brick(sx * (w / 2 + 0.05), 0, 3 + k * 4, 0.2, d * 0.8, 1.4, "glow_white" if k % 2 else "glow_cyan", studs=False, bevel=0.02)
    F.brick(0, 0, h + 1, w + 1, d + 1, 1.0, "magenta")
    for x in (-w / 4, w / 4):
        F.cyl(x, 0, 1.2, h + 2, h + 9, "metal_dark", segs=8)
        F.sphere(x, 0, h + 9.6, 0.8, 0.8, 0.8, "glow_red", seg=8, rings=5)
    # the screen: a magenta frame, a cyan field, a big goofy face
    S = F.sub(0, -d / 2 - 0.4)
    S.brick(0, 0, 8, w - 4, 0.6, h - 10, "glow_magenta", studs=False, bevel=0.1)
    S.brick(0, -0.2, 9, w - 6, 0.6, h - 12, "sky_blue", studs=False, bevel=0.0)
    cz = 9 + (h - 12) / 2
    for sx in (-1, 1):  # eyes: white squares, black pupils looking sideways
        S.brick(sx * 4.5, -0.6, cz + 2, 5, 0.4, 5, "white", studs=False)
        S.brick(sx * 4.5 + 1.2, -0.85, cz + 1.4, 2.2, 0.3, 2.6, "black", studs=False)
    S.brick(0, -0.6, cz - 5, 10, 0.4, 2.2, "black", studs=False)  # grin
    S.brick(2.5, -0.8, cz - 5.2, 3, 0.3, 1.4, "pink", studs=False)  # tongue
    neon_sign(F, 0, -d / 2 - 4, 3.5, 16, 3, "BIG SCREEN", post_h=3.5)


def melty_mall(F, w=30, d=20, h=12):
    """A shop block whose roof is melting: drips hang down the walls."""
    F.brick(0, 0, 0, w + 4, d + 4, 1.0, "night")
    F.brick(0, 0, 1.0, w, d, h, "lilac", studs=False)
    for k in range(5):
        x = -w / 2 + 3 + k * (w - 6) / 4
        F.brick(x, -d / 2 - 0.05, 2.0, 4, 0.3, 5, "glass", studs=False, bevel=0.0)
        F.brick(x, -d / 2 - 0.25, 7.0, 4.6, 0.6, 0.6, "glow_cyan", studs=False)
    F.brick(0, 0, 1 + h, w + 1.4, d + 1.4, 2.0, "magenta")  # the "icing" roof
    for k in range(26):  # drips down the four walls
        side = k % 4
        t = rng.uniform(-0.45, 0.45)
        L = rng.uniform(2, 6)
        if side in (0, 1):
            x, y, r = t * w, (-1 if side == 0 else 1) * (d / 2 + 0.75), 0
        else:
            x, y, r = (-1 if side == 2 else 1) * (w / 2 + 0.75), t * d, 90
        F.brick(x, y, 1 + h - L, rng.uniform(1.0, 1.8), 0.6, L, "magenta", rot=r, studs=False, bevel=0.25)
        F.sphere(x, y, 1 + h - L, 0.8, 0.5, 0.8, "magenta", seg=8, rings=5)
    neon_sign(F, 0, -d / 2 - 1.2, h - 2.4, 16, 3, "MELTY MALL")


def upside_down_house(F):
    """A cottage standing on its roof - the roof's ridge in the grass, the floor up in the air."""
    F.brick(0, 0, 0, 3, 14, 1.5, "roof_red")
    for k in range(5):  # the inverted stepped roof, widening upward
        F.brick(0, 0, 0.5 + k * 1.1, 4 + k * 2.6, 14, 1.1, "roof_red")
    F.brick(0, 0, 6.0, 15, 12, 8, "yellow", studs=False)
    K.window(F, -3.5, -6.05, 9, 2.6, 3, 0, frame="white", shutters="roof_blue")
    K.window(F, 3.5, -6.05, 9, 2.6, 3, 0, frame="white", shutters="roof_blue")
    K.door(F, 0, -6.05, 7.4, 2.6, 5, 0, frame="white", leaf="sign_green")  # (upside down: its knob at the bottom)
    F.brick(0, 0, 14.0, 15.6, 12.6, 0.6, "wood_dark")  # the floor, on top
    F.brick(-4.5, 0, 14.6, 4, 2, 2.4, "wood")  # furniture on the "ceiling" (a table, its legs up)
    for sx in (-1, 1):
        for sy in (-1, 1):
            F.brick(-4.5 + sx * 1.6, sy * 0.7, 17.0, 0.4, 0.4, 1.4, "wood_dark", studs=False)


def upside_down_tree(F, x, y, s=1.0):
    """The canopy sits on the grass, the trunk sticks up, the roots spread in the sky."""
    F.brick(x, y, 0, 8 * s, 8 * s, 3.5 * s, "lilac")
    F.brick(x, y, 3.0 * s, 5.5 * s, 5.5 * s, 2.5 * s, "magenta")
    F.brick(x, y, 5.5 * s, 1.8 * s, 1.8 * s, 6 * s, "wood_dark", studs=False)
    for a in (0, 90, 180, 270):
        rx, ry = polar(1.4 * s, a)
        F.brick(x + rx, y + ry, 11.0 * s, 2.6 * s, 0.6 * s, 0.6 * s, "wood_dark", rot=a, studs=False)


def pixel_tree(F, x, y, s=1.0, look="magenta", top="lilac"):
    F.brick(x, y, 0, 1.6 * s, 1.6 * s, 5 * s, "violet", studs=False)
    F.brick(x, y, 5 * s, 7 * s, 7 * s, 4 * s, look)
    F.brick(x, y, 9 * s, 4.4 * s, 4.4 * s, 2.4 * s, top)


def leaning_tower(F, x, y, lean=10, rot=0.0, h=22, look="violet"):
    """A thin tower leaning more with every block (and somehow not falling)."""
    G = F.sub(x, y, rot)
    off = 0.0
    for k in range(int(h / 2)):
        off += 0.12 * k * lean / 10
        G.brick(off, 0, k * 2, 4.2 - k * 0.05, 4.2 - k * 0.05, 2.0, look if k % 2 else "lilac")  # (studs show on each offset ledge)
        if k % 3 == 1:
            G.brick(off, -2.15, k * 2 + 0.6, 2.2, 0.2, 0.8, "glow_cyan", studs=False, bevel=0.02)
    G.sphere(off, 0, h + 1.2, 1.2, 1.2, 1.2, "glow_magenta", seg=12, rings=8)


# ------------------------------------------------------------------ giant odd objects
def giant_dice(F, x, y, s=4.0, look="white", pip="magenta", rot=0.0):
    F.brick(x, y, 0, s, s, s, look, rot=rot, studs=True, bevel=0.3)
    G = F.sub(x, y, rot)
    for px, pz in ((0, s / 2),):
        G.brick(px, -s / 2 - 0.05, pz, 0.7, 0.2, 0.7, pip, studs=False, bevel=0.1)
    for dx, dz in ((-1, -1), (1, 1)):
        G.brick(-s / 2 - 0.05, dx * s / 4, s / 2 + dz * s / 4, 0.2, 0.7, 0.7, pip, studs=False, bevel=0.1)


def floating_eye(F, x, y, z, r=3.0):
    """A floating eyeball: a studded voxel ball with a sky-blue iris + pupil on its front (-y)."""
    K.voxel_round(F, x, y, z - r, lambda t: r * math.sqrt(max(0, 1 - (2 * t - 1) ** 2)), 2 * r, "white", step=0.5, segs=18)
    F.disc_v(x, y - r - 0.05, z, r * 0.5, 0.3, "sky_blue")
    F.disc_v(x, y - r - 0.25, z, r * 0.24, 0.3, "black")
    F.cyl(x, y, 0.3, 0, z - r, "glass", segs=6)  # (a clear stand: it floats)


def giant_cone(F, x, y, s=1.0):
    F.brick(x, y, 0, 6 * s, 6 * s, 0.8 * s, "orange")
    K.voxel_round(F, x, y, 0.8 * s, lambda t: 2.6 * s - 2.2 * s * t, 8.2 * s, "orange", step=0.8 * s, segs=16,
                  looks=lambda k: "white" if k in (3, 6) else "orange")  # a stepped cone, two white bands


def gelato(F, x, y, s=1.0):
    """A giant gelato cone (the brainrot's 'odd giant food-objects')."""
    K.voxel_round(F, x, y, 0.4 * s, lambda t: 0.6 * s + 2.4 * s * t, 7.6 * s, "wood", step=0.8 * s, segs=16)  # (the cone, point down)
    for k, look in enumerate(("pink", "lilac", "sky_blue")):  # studded voxel scoops
        K.voxel_round(F, x + (k - 1) * 0.6 * s, y, (7.0 + k * 2.6) * s,
                      lambda t: 3.0 * s * math.sqrt(max(0, 1 - (2 * t - 1) ** 2)), 4.8 * s, look, step=0.6, segs=16)
    F.brick(x + 1.0 * s, y, 16.0 * s, 0.6 * s, 0.6 * s, 2.0 * s, "wood_dark", rot=20, studs=False)  # a wafer


def floating_cube(F, x, y, z, s=3.0, look="lilac", rot=20.0):
    F.brick(x, y, z, s, s, s, look, rot=rot, bevel=0.2)
    F.brick(x, y, z - 0.4, s * 0.5, s * 0.5, 0.2, "glow_cyan", rot=rot, studs=False, bevel=0.02)


# ------------------------------------------------------------------ gate, keystone, egg
def glitch_gate(F, width=22):
    """An arch whose blocks are knocked out of line - a 'glitched' gateway."""
    for sx in (-1, 1):
        x = sx * (width / 2 + 2)
        for k in range(7):
            gx = x + rng.uniform(-0.8, 0.8)
            F.brick(gx, rng.uniform(-0.5, 0.5), k * 2.0, 3.4, 3.4, 2.0, ("violet", "magenta", "lilac")[k % 3], rot=rng.uniform(-6, 6), studs=False)
    for k in range(9):
        x = -width / 2 - 2 + k * (width + 4) / 8
        F.brick(x, rng.uniform(-0.6, 0.6), 14 + rng.uniform(-0.4, 0.6), (width + 6) / 8 + 0.4, 3.0, 2.0,
                ("magenta", "violet", "lilac")[k % 3], rot=rng.uniform(-5, 5))
    neon_sign(F, 0, -2.0, 16.6, width - 2, 3.6, "BRAINROT BOULEVARD", size=1.4)
    for sx in (-1, 1):
        F.sphere(sx * (width / 2 + 2), 0, 15.2, 1.2, 1.2, 1.2, "glow_cyan", seg=12, rings=8)


def brain_keystone(F):
    """A pink voxel brain (two lobes, folds as grooves) for the RETURN HOME ring."""
    for sx in (-1, 1):
        K.voxel_round(F, sx * 1.3, 0, 0, lambda t: 2.0 * math.sqrt(max(0, 1 - (2 * t - 1) ** 2)), 3.4, "pink", step=0.4, segs=14, studs=False)
    for k in range(4):
        F.brick(0, -0.2, 0.6 + k * 0.7, 0.3, 3.6, 0.2, "magenta", studs=False, bevel=0.02)


def brainrot_egg_deco(F, x, y, s):
    """Neon zig-zags on a purple egg."""
    for k in range(6):
        a = k * 60
        px, py = polar(1.58 * s, a)
        F.brick(x + px, y + py, (1.4 + (k % 2) * 0.6) * s, 0.5 * s, 0.25 * s, 0.5 * s, "glow_cyan", rot=a + 90, studs=False, bevel=0.06)


def brainrot_egg(F, x, y, golden=False):
    W.egg(F, x, y, 1.0, body="gold" if golden else "violet", bands={4: "glow_magenta", 7: "lilac"} if not golden else {5: "glow_gold"},
          deco=brainrot_egg_deco)


# ------------------------------------------------------------------ boss arena: THE GAVEL PIT (Judge Martello hops + slams)
def gavel_pit(F, R=52, openings=(270, 90)):
    """A neon checkerboard floor (it reads every landing), a cyan ring, a gavel emblem; neon pylons + speakers outside."""
    F.cyl(0, 0, R, 0, 0.35, "night", segs=96)
    n = int(R * 2 / 6)
    for i in range(n):  # checkerboard tiles (6 studs) inside the circle
        for j in range(n):
            x, y = -R + (i + 0.5) * 6, -R + (j + 0.5) * 6
            if math.hypot(x, y) < R - 4:
                F.brick(x, y, 0.35, 6, 6, 0.12, "violet" if (i + j) % 2 else "magenta", studs=True, bevel=0.0)
    F.ring(R - 3.2, R - 2.2, 0.35, 0.5, "glow_cyan", segs=96)
    F.ring(18, 19, 0.47, 0.6, "glow_cyan", segs=64)
    F.brick(0, 0, 0.47, 3, 22, 0.1, "gold", studs=False, bevel=0.02)  # the gavel emblem
    F.brick(0, 9, 0.47, 12, 5, 0.1, "gold", studs=False, bevel=0.02)
    for k in range(32):  # neon pylons round the rim, open where the routes come in
        a = k * 360 / 32
        if any(abs(((a - o + 180) % 360) - 180) < 12 for o in openings):
            continue
        x, y = polar(R + 2, a)
        F.brick(x, y, 0, 1.4, 1.4, 4.0, "night", studs=False)
        F.brick(x, y, 4.0, 1.0, 1.0, 1.6, "glow_magenta" if k % 2 else "glow_cyan", studs=False, bevel=0.1)
    for a in (45, 135, 225, 315):  # giant speakers outside
        x, y = polar(R + 12, a)
        G = F.sub(x, y, a + 90)
        G.brick(0, 0, 0, 7, 6, 12, "night", studs=False)
        for z, r in ((3.2, 2.4), (8.6, 1.6)):
            G.disc_v(0, -3.05, z, r, 0.3, "metal_dark", segs=18)
            G.disc_v(0, -3.25, z, r * 0.45, 0.3, "glow_magenta", segs=12)
        G.brick(0, 0, 12, 7.4, 6.4, 0.6, "glow_cyan", studs=False)
    W.marquee(F, 0, -R - 13, 7.0, 18, 4, "THE GAVEL PIT", size=1.6, post_h=7.0, panel="night", letters="glow_cyan")


def neon_tower(F, w=14, d=14, h=40, body="night", strips=("glow_magenta", "glow_cyan"), crown="magenta", sign=None):
    """A dark neon skyscraper: glowing window strips, a stepped crown, an antenna, a rooftop sign."""
    F.brick(0, 0, 0, w + 4, d + 4, 1.0, "night")
    F.brick(0, 0, 1.0, w, d, h, body, studs=False)
    for k in range(int(h / 3.2)):
        z = 2.4 + k * 3.2
        lk = strips[k % len(strips)]
        for sgn in (-1, 1):
            F.brick(0, sgn * (d / 2 + 0.05), z, w * 0.8, 0.2, 1.0, lk, studs=False, bevel=0.02)
            F.brick(sgn * (w / 2 + 0.05), 0, z, 0.2, d * 0.8, 1.0, lk, studs=False, bevel=0.02)
    F.brick(0, 0, 1 + h, w + 1, d + 1, 1.0, crown)
    F.brick(0, 0, 2 + h, w - 4, d - 4, 3.0, body)
    F.brick(0, 0, 5 + h, w - 8, d - 8, 2.0, crown)
    F.cyl(0, 0, 0.35, 7 + h, 16 + h, "metal", segs=6)
    F.sphere(0, 0, 16.5 + h, 0.7, 0.7, 0.7, "glow_red", seg=8, rings=5)
    if sign:
        neon_sign(F, 0, -d / 2 - 0.6, h - 6, w + 2, 3.4, sign, size=1.3)
