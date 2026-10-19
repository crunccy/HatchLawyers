# environment-redesign/pet_park/pp_parts.py - Pet Park's models (Stage 5, island 2, 2026-10-18).
# A lush, cheerful animal park. Palette: bright greens, yellows, pinks, blues. Local frames: front = local -y.
# Animals are cartoon brick sculptures (fictional, no real brands / characters).
import math
import hl_kit as K
import hl_world as W

rng = K.rng
polar = W.polar


# ------------------------------------------------------------------ sculptures
def giant_corgi(F, s=1.0):
    """A sitting corgi sculpture (orange + white), big ears, tongue out, a tail; on a mossy rock plinth."""
    o, w, d = "orange", "white", "black"
    F.cyl(0, 0, 9 * s, 0, 2.2 * s, "rock", segs=14, studs=True)
    F.cyl(0, 0, 8 * s, 2.2 * s, 2.8 * s, "grass", segs=14, studs=True)
    z = 2.8 * s
    for sx in (-1, 1):  # paws + legs (front), haunches (back)
        F.brick(sx * 1.6 * s, -3.2 * s, z, 1.6 * s, 2.0 * s, 0.9 * s, w, studs=False)
        F.brick(sx * 1.6 * s, -2.6 * s, z + 0.9 * s, 1.4 * s, 1.4 * s, 4.0 * s, o, studs=False)
        F.brick(sx * 2.6 * s, 1.8 * s, z, 2.4 * s, 4.4 * s, 3.0 * s, o, studs=False)
    F.brick(0, 0.2 * s, z + 1.0 * s, 5.0 * s, 6.0 * s, 4.4 * s, o, studs=False)  # body
    F.brick(0, -1.6 * s, z + 2.2 * s, 3.2 * s, 2.8 * s, 3.8 * s, w, studs=False)  # chest
    F.brick(0, -1.4 * s, z + 5.4 * s, 4.6 * s, 4.2 * s, 3.4 * s, o, studs=False)  # head
    F.brick(0, -3.6 * s, z + 5.6 * s, 2.6 * s, 1.6 * s, 1.6 * s, w, studs=False)  # muzzle
    F.brick(0, -4.45 * s, z + 6.7 * s, 0.9 * s, 0.4 * s, 0.6 * s, d, studs=False, bevel=0.05)  # nose
    F.brick(0.3 * s, -4.3 * s, z + 5.3 * s, 0.8 * s, 0.4 * s, 0.9 * s, "pink", studs=False, bevel=0.05)  # tongue
    F.brick(0, -3.55 * s, z + 7.0 * s, 1.0 * s, 0.3 * s, 1.6 * s, w, studs=False)  # blaze
    for sx in (-1, 1):
        F.brick(sx * 1.1 * s, -3.55 * s, z + 7.4 * s, 0.6 * s, 0.2 * s, 0.6 * s, d, studs=False, bevel=0.04)  # eyes
        F.brick(sx * 1.6 * s, -1.4 * s, z + 8.8 * s, 1.4 * s, 1.0 * s, 2.6 * s, o, rot=sx * 12, studs=False)  # ears
        F.brick(sx * 1.6 * s, -1.9 * s, z + 9.2 * s, 0.7 * s, 0.2 * s, 1.6 * s, "pink", rot=sx * 12, studs=False)
    F.brick(0, 3.6 * s, z + 2.4 * s, 1.4 * s, 1.4 * s, 1.4 * s, w, studs=False, bevel=0.3 * s)  # tail


def giant_cat(F, s=1.0):
    g, w = "stone_dark", "white"
    F.brick(0, 0, 0, 7 * s, 7 * s, 1.2 * s, "marble")
    z = 1.2 * s
    F.brick(0, 0.5 * s, z, 4.4 * s, 4.6 * s, 5.0 * s, g, studs=False)
    F.brick(0, -1.6 * s, z + 1.0 * s, 2.6 * s, 1.0 * s, 3.4 * s, w, studs=False)
    for sx in (-1, 1):
        F.brick(sx * 1.2 * s, -2.0 * s, z, 1.3 * s, 1.6 * s, 0.9 * s, w, studs=False)
    F.brick(0, -0.3 * s, z + 5.0 * s, 4.2 * s, 3.8 * s, 3.4 * s, g, studs=False)  # head
    F.brick(0, -2.2 * s, z + 5.6 * s, 2.0 * s, 0.4 * s, 1.2 * s, w, studs=False)
    for sx in (-1, 1):
        F.pyramid(sx * 1.3 * s, -0.4 * s, z + 8.4 * s, 1.4 * s, 1.2 * s, 1.6 * s, g)
        F.brick(sx * 0.9 * s, -2.25 * s, z + 7.0 * s, 0.6 * s, 0.2 * s, 0.7 * s, "sign_green", studs=False, bevel=0.04)
        for k in range(2):  # whiskers
            F.brick(sx * 2.3 * s, -2.3 * s, z + 6.0 * s + k * 0.4 * s, 1.6 * s, 0.1 * s, 0.1 * s, w, studs=False, bevel=0.01)
    F.brick(0, -2.45 * s, z + 6.3 * s, 0.5 * s, 0.2 * s, 0.4 * s, "pink", studs=False, bevel=0.04)
    for k in range(5):  # tail curling up the side
        F.brick(2.6 * s, 1.8 * s - k * 0.3 * s, z + k * 0.9 * s, 0.9 * s, 0.9 * s, 1.0 * s, g, studs=False)


def bunny_topiary(F, s=1.0):
    F.brick(0, 0, 0, 5 * s, 5 * s, 1.6 * s, "brick_red")
    F.brick(0, 0, 1.6 * s, 4.4 * s, 4.4 * s, 0.6 * s, "dirt_dark", studs=False)
    F.brick(0, 0, 2.2 * s, 4.0 * s, 4.6 * s, 3.4 * s, "leaf")  # body
    F.brick(0, -1.4 * s, 5.4 * s, 3.0 * s, 2.8 * s, 2.6 * s, "leaf_light")  # head
    for sx in (-1, 1):
        F.brick(sx * 0.7 * s, -1.4 * s, 8.0 * s, 0.9 * s, 0.8 * s, 3.2 * s, "leaf", rot=sx * 8, studs=False)
    F.brick(0, 2.5 * s, 3.6 * s, 1.4 * s, 1.4 * s, 1.4 * s, "white", studs=False, bevel=0.3 * s)  # cotton tail


# ------------------------------------------------------------------ pet houses + toys
def dog_house(F, body="roof_blue", roof="red", name="REX"):
    F.brick(0, 0, 0, 6.4, 7, 0.5, "wood_dark")
    F.brick(0, 0.3, 0.5, 5.6, 6.0, 4.4, body, studs=False)
    F.brick(0, -2.75, 0.5, 2.6, 0.6, 3.2, "black", studs=False)  # the opening
    F.roof_gable(0, 0.3, 4.9, 6.0, 6.4, 2.6, roof, rot=90, courses=3, overhang=0.6, trim="white")
    F.brick(0, -3.2, 4.2, 3.6, 0.3, 0.9, "white", studs=False)
    F.text(name, 0, -3.4, 4.65, 0.55, "black", kind="bold", extrude=0.04)
    F.cyl(3.6, -3.4, 1.0, 0, 0.6, "red", segs=12)  # food bowl
    F.cyl(3.6, -3.4, 0.8, 0.4, 0.65, "wood", segs=12)


def cat_tower(F):
    F.brick(0, 0, 0, 6, 6, 0.6, "pink")
    for (x, y, h) in ((-1.6, -1.6, 9), (1.8, 1.4, 6), (1.8, -1.6, 12)):
        F.cyl(x, y, 0.6, 0.6, h, "sand", segs=10)
        F.cyl(x, y, 1.9, h, h + 0.6, "purple", segs=14, studs=True)
    F.brick(-0.4, 1.8, 3.0, 3.6, 3.0, 2.6, "pink", studs=True)  # a hidey box
    F.brick(-0.4, 0.25, 3.4, 1.4, 0.2, 1.4, "black", studs=False)
    F.sphere(1.8, -1.6, 13.6, 0.8, 0.8, 0.8, "yellow", seg=10, rings=6)


def bird_house(F, x, y, look="sky_blue", roof="red", h=6.0):
    F.brick(x, y, 0, 0.6, 0.6, h, "wood_dark", studs=False)
    F.brick(x, y, h, 2.0, 2.0, 2.0, look, studs=False)
    F.roof_hip(x, y, h + 2.0, 2.2, 2.2, 1.2, roof, courses=2, overhang=0.2)
    F.brick(x, y - 1.02, h + 0.9, 0.7, 0.1, 0.7, "black", studs=False, bevel=0.02)  # the hole


def rabbit_hutch(F):
    F.brick(0, 0, 0, 10, 5, 0.5, "wood_dark")
    for sx in (-1, 1):
        for sy in (-1, 1):
            F.brick(sx * 4.6, sy * 2.1, 0.5, 0.6, 0.6, 2.4, "wood_dark", studs=False)
    F.brick(0, 0, 2.9, 10, 5, 3.4, "wood", studs=False)
    F.brick(-2.2, -2.55, 3.3, 4.6, 0.2, 2.6, "metal", studs=False, bevel=0.0)  # wire window
    F.brick(2.6, -2.55, 3.3, 3.4, 0.2, 2.6, "wood_dark", studs=False)
    F.roof_gable(0, 0, 6.3, 10.4, 5.4, 1.8, "sign_green", courses=2, overhang=0.4)
    F.brick(4.6, -3.0, 0, 2.6, 1.4, 0.4, "orange", studs=False)  # carrots
    for k in range(3):
        F.brick(3.8 + k * 0.8, -3.0, 0.4, 0.4, 0.4, 0.8, "leaf_light", studs=False, bevel=0.05)


def giant_bone(F, s=1.0, look="white"):
    F.brick(0, 0, 0, 8 * s, 1.8 * s, 1.6 * s, look)
    for sx in (-1, 1):
        for sy in (-1, 1):
            F.cyl(sx * 4.2 * s, sy * 1.0 * s, 1.3 * s, 0, 1.8 * s, look, segs=14, studs=True)


def tennis_ball(F, x, y, r=2.0):
    F.sphere(x, y, r, r, r, r, "yellow", seg=16, rings=10)
    F.ring_v(x, y, r, r * 0.92, r * 1.03, 0.25, "white", rot=30, segs=20, gap=0.0)


def food_bowl(F, R=5.0, water=False):
    F.cyl(0, 0, R, 0, 1.0, "red", segs=24, bevel=0.2)
    F.ring(R * 0.75, R, 1.0, 2.2, "red", segs=24)
    F.cyl(0, 0, R * 0.75, 1.0, 1.7, "water" if water else "wood", segs=24, studs=not water)
    F.brick(0, -R + 0.1, 1.1, 3.0, 0.3, 0.9, "white", studs=False)
    F.text("PET", 0, -R - 0.1, 1.55, 0.6, "red", kind="bold", extrude=0.04)


def yarn_ball(F, x, y, r=1.8, look="pink"):
    F.sphere(x, y, r, r, r, r, look, seg=14, rings=9)
    for k in range(3):
        F.ring_v(x, y, r, r * 0.95, r * 1.04, 0.2, "white", rot=k * 60, segs=18, gap=0.0)
    F.brick(x + r, y, 0.2, 2.6, 0.25, 0.2, look, studs=False, bevel=0.03)


def fire_hydrant(F, x, y):
    F.cyl(x, y, 0.9, 0, 0.4, "red", segs=10)
    F.cyl(x, y, 0.7, 0.4, 2.6, "red", segs=10)
    F.cone(x, y, 0.8, 2.6, 3.3, "red", segs=10)
    for sgn in (-1, 1):
        F.brick(x + sgn * 0.85, y, 1.6, 0.6, 0.6, 0.6, "yellow", studs=False, bevel=0.1)


def picket_fence(F, x0, y0, x1, y1, look="white", h=2.4):
    L = math.hypot(x1 - x0, y1 - y0)
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    n = max(2, int(L / 1.2))
    for k in range(n + 1):
        t = k / n
        F.brick(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, 0, 0.6, 0.25, h, look, rot=a, studs=False, bevel=0.05)
        F.pyramid(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, h, 0.6, 0.25, 0.4, look, rot=a)
    for z in (0.6, h - 0.7):
        F.brick((x0 + x1) / 2, (y0 + y1) / 2, z, L, 0.2, 0.3, look, rot=a, studs=False, bevel=0.03)


def wood_bridge(F, L=16, w=6):
    for k in range(int(L / 1.2)):
        x = -L / 2 + 0.6 + k * 1.2
        z = 0.9 + 1.4 * math.sin(math.pi * (k + 0.5) / (L / 1.2))
        F.brick(x, 0, z, 1.15, w, 0.4, "wood" if k % 2 else "wood_dark")
    for sgn in (-1, 1):
        for k in range(5):
            x = -L / 2 + k * L / 4
            z = 0.9 + 1.4 * math.sin(math.pi * (k / 4))
            F.brick(x, sgn * (w / 2 - 0.2), z, 0.4, 0.4, 2.6, "wood_dark", studs=False)
        for k in range(4):
            xa, xb = -L / 2 + k * L / 4, -L / 2 + (k + 1) * L / 4
            za = 0.9 + 1.4 * math.sin(math.pi * k / 4) + 2.4
            zb = 0.9 + 1.4 * math.sin(math.pi * (k + 1) / 4) + 2.4
            F.brick((xa + xb) / 2, sgn * (w / 2 - 0.2), (za + zb) / 2 - 0.15, L / 4 + 0.3, 0.3, 0.3, "wood", studs=False)


# ------------------------------------------------------------------ buildings
def _pet_shop(F, wall, roof, awning, sign, sign_bg, fg="white", prop=None):
    F.brick(0, 0, 0, 24, 18, 0.8, "stone_warm")
    F.brick(0, 2, 0.8, 20, 12, 9, wall, studs=False)
    F.brick(0, 2, 9.8, 21, 13, 0.8, "white", studs=False)
    F.roof_gable(0, 2, 10.6, 20, 12, 5.0, roof, courses=5, overhang=0.8, trim="white")
    for sx in (-1, 1):
        K.window(F, sx * 6, -4.05, 2.4, 4.2, 4.2, 0, frame="white", mullions=1, shutters=awning)
        K.window(F.sub(sx * 10.05, 2, rot=90 * sx), 0, 0, 2.6, 3.6, 4.0, 0, frame="white", depth=0.5)
    K.door(F, 0, -4.05, 0.8, 3.4, 6.2, 0, frame="white", leaf=awning, arch=True)
    for k in range(12):
        x = -10 + (k + 0.5) * 20 / 12
        for j in range(3):
            F.brick(x, -4.6 - j * 0.9, 7.6 - j * 0.5, 20 / 12, 1.0, 0.55, awning if k % 2 == 0 else "awning_white", studs=(j == 0))
    W.board(F, 0, -4.4, 10.8, 13, 2.6, sign, bg=sign_bg, fg=fg, trim="white", size=1.2)
    for k, x in enumerate((-8.6, 8.6)):  # flower boxes + paw prints on the path
        F.brick(x, -6.4, 0.8, 4, 1.4, 1.0, "wood")
        for j in range(4):
            F.brick(x - 1.5 + j, -6.4, 1.8, 0.8, 0.8, 0.6, ["pink", "yellow", "sky_blue", "purple"][j], studs=False)
    for k in range(4):
        paw(F, -2 + (k % 2) * 4, -8.5 - k * 2.4, 0.81)
    if prop:
        prop(F)


def paw(F, x, y, z, s=0.6, look="white"):
    F.cyl(x, y, 0.9 * s, z, z + 0.1, look, segs=10)
    for k, (dx, dy) in enumerate(((-1.0, 1.1), (-0.35, 1.5), (0.35, 1.5), (1.0, 1.1))):
        F.cyl(x + dx * s, y + dy * s, 0.35 * s, z, z + 0.1, look, segs=8)


def paw_clinic(F):
    def cross(F):
        F.brick(0, 2, 15.6, 3.6, 1.0, 1.2, "white", studs=False)
        F.brick(0, 2, 14.4, 1.2, 1.0, 3.6, "white", studs=False)
        F.disc_v(0, 1.3, 16.2, 2.8, 0.3, "sign_green", segs=20)
    _pet_shop(F, "white", "sky_blue", "sky_blue", "PAW CLINIC", "sky_blue", prop=None)
    F.disc_v(0, -4.3, 16.6, 2.6, 0.4, "white", segs=20)  # a paw medallion in the gable
    F.disc_v(0, -4.55, 16.3, 1.0, 0.2, "pink", segs=14)
    for k, (dx, dz) in enumerate(((-1.1, 1.0), (-0.4, 1.5), (0.4, 1.5), (1.1, 1.0))):
        F.disc_v(dx, -4.55, 16.3 + dz, 0.4, 0.2, "pink", segs=10)


def fluff_and_puff(F):
    def bubbles(F):
        for k in range(9):
            x, z = rng.uniform(-9, 9), rng.uniform(15.5, 20)
            F.sphere(x, 2 + rng.uniform(-3, 3), z, 0.7, 0.7, 0.7, "glass", seg=10, rings=6)
    _pet_shop(F, "pink", "purple", "purple", "FLUFF & PUFF", "purple", prop=bubbles)


def barkery(F):
    def treats(F):
        giant_bone(F.sub(0, 2, z=16.0), 0.55, "wood")
    _pet_shop(F, "cream", "red", "red", "THE BARKERY", "red", prop=treats)
    for k, (x, y) in enumerate(((-7, -11), (7, -11))):  # tables with umbrellas
        F.cyl(x, y, 1.2, 0.8, 2.8, "white", segs=10)
        F.cyl(x, y, 0.2, 2.8, 5.6, "metal_dark", segs=6)
        F.cone(x, y, 3.0, 5.4, 6.6, "red" if k else "yellow", segs=8)


# ------------------------------------------------------------------ gate, portal keystone, egg
def pet_gate(F, width=20):
    for sx in (-1, 1):
        x = sx * (width / 2 + 2)
        F.brick(x, 0, 0, 4, 4, 1.2, "stone")
        F.brick(x, 0, 1.2, 3, 3, 11, "sky_blue", studs=False)
        F.disc_v(x, -1.6, 7.5, 1.0, 0.2, "white", segs=14)
        for k, (dx, dz) in enumerate(((-1.0, 1.1), (-0.35, 1.5), (0.35, 1.5), (1.0, 1.1))):
            F.disc_v(x + dx * 0.9, -1.6, 7.5 + dz * 0.9, 0.38, 0.2, "white", segs=10)
    giant_bone(F.sub(0, 0, z=12.2), 1.6, "white")  # the bone across the top
    W.marquee(F, 0, -1.8, 15.4, width - 4, 3.6, "PET PARK", size=1.9)


def paw_keystone(F):
    F.brick(0, 0, 0, 5, 4, 3, "pink")
    F.disc_v(0, -2.1, 1.3, 1.0, 0.2, "white", segs=14)
    for dx, dz in ((-1.0, 1.0), (-0.35, 1.45), (0.35, 1.45), (1.0, 1.0)):
        F.disc_v(dx * 0.9, -2.1, 1.3 + dz * 0.8, 0.36, 0.2, "white", segs=10)


def pet_egg_deco(F, x, y, s):
    """Pink paw prints on a sky-blue egg."""
    for a in (0, 120, 240):
        px, py = polar(1.55 * s, a)
        F.brick(x + px, y + py, 1.6 * s, 0.7 * s, 0.25 * s, 0.6 * s, "pink", rot=a + 90, studs=False, bevel=0.08)
        for dz, dx in ((0.75, -0.35), (0.85, 0.0), (0.75, 0.35)):
            qx, qy = polar(1.5 * s, a)
            ox, oy = -math.sin(math.radians(a)) * dx * s, math.cos(math.radians(a)) * dx * s
            F.brick(x + qx + ox, y + qy + oy, (1.6 + dz) * s, 0.25 * s, 0.2 * s, 0.25 * s, "pink", rot=a + 90, studs=False, bevel=0.04)


def pet_egg(F, x, y, golden=False):
    W.egg(F, x, y, 1.0, body="gold" if golden else "sky_blue", bands={5: "white", 6: "white"} if not golden else {5: "glow_gold"},
          deco=pet_egg_deco)


# ------------------------------------------------------------------ boss arena: BARK COURT (an agility-course dog run)
def bark_court(F, R=54, openings=(270, 90)):
    W.arena_floor(F, R, field="grass_dark", band="sign_green", ring="white", inner=24)
    F.brick(0, 0, 0.4, 14, 3, 0.12, "white", studs=False, bevel=0.02)  # a bone emblem, flat in the floor
    for sx in (-1, 1):
        for sy in (-1, 1):
            F.cyl(sx * 7.5, sy * 1.6, 2.2, 0.4, 0.52, "white", segs=16)
    # rim: a white picket fence, open where the routes come in, with paw-print gateposts
    n = 40
    for k in range(n):
        a0, a1 = k * 360 / n, (k + 1) * 360 / n
        mid = (a0 + a1) / 2
        if any(abs(((mid - o + 180) % 360) - 180) < 12 for o in openings):
            continue
        (x0, y0), (x1, y1) = polar(R + 1.5, a0), polar(R + 1.5, a1)
        picket_fence(F, x0, y0, x1, y1)
    for o in openings:
        for sgn in (-1, 1):
            x, y = polar(R + 1.5, o + sgn * 12)
            F.brick(x, y, 0, 2.2, 2.2, 4.4, "pink")
            F.sphere(x, y, 5.3, 0.9, 0.9, 0.9, "yellow", seg=10, rings=6)
    # agility course OUTSIDE the fence: hurdles, a tunnel, weave poles, a judging stand
    for k, a in enumerate((35, 145, 215, 325)):
        x, y = polar(R + 10, a)
        G = F.sub(x, y, a + 90)
        if k % 2 == 0:  # hurdle
            for sx in (-1, 1):
                G.brick(sx * 2.6, 0, 0, 0.6, 0.6, 3.4, "white", studs=False)
            for z in (1.4, 2.6):
                G.brick(0, 0, z, 5.4, 0.4, 0.4, "red" if z < 2 else "yellow", studs=False)
        else:  # tunnel
            G.ring_v(0, 0, 1.8, 1.6, 2.2, 6.0, ["sky_blue", "yellow"], rot=90, segs=12, gap=0.05)
    for k in range(6):  # weave poles
        x, y = polar(R + 9, 270 + 22 + k * 2.2)
        F.cyl(x, y, 0.25, 0, 3.6, "red" if k % 2 else "white", segs=8)
    x, y = polar(R + 12, 248)
    G = F.sub(x, y, 248 + 90)  # the judge's stand: a little courtroom bench for a dog barrister
    G.brick(0, 0, 0, 8, 4, 3.6, "wood_dark", studs=False)
    G.brick(0, 0, 3.6, 8.6, 4.6, 0.5, "wood")
    G.brick(0, 1.4, 4.1, 8, 1.2, 3.0, "wood_dark", studs=False)
    G.brick(0, -2.1, 1.0, 5, 0.3, 1.6, "gold", studs=False)
    G.text("BARK COURT", 0, -2.3, 1.8, 0.7, "black", kind="bold", extrude=0.05)
    W.marquee(F, 0, -R - 13, 7.0, 18, 4, "BARK COURT", size=1.7, post_h=7.0)
