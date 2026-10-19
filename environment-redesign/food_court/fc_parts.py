# environment-redesign/food_court/fc_parts.py - Food Court's models (Stage 5, island 4, 2026-10-19).
# An oversized, colourful food festival (the game's zone: Food Court). Palette: warm oranges, reds, yellows + fresh
# greens / pinks as accents. Local frames: front = local -y. Every round food is a studded VOXEL round (stacked
# rings, studs on each exposed ledge), never a smooth sphere; glowing bulbs are the only smooth balls.
# Static props never use the canopy looks (leaf / leaf_light / leaf_deep / blossom): the ambience wind sways those
# looks' studs island-wide, so a lettuce leaf in "leaf_light" would shed its studs. Greens here are veg_green etc.
import math
import hl_kit as K
import hl_world as W

rng = K.rng
polar = W.polar

K.PAL.update({
    "bun": (230, 152, 62), "bun_dark": (196, 112, 40), "patty": (112, 62, 36), "cheese": (255, 206, 52),
    "cheese_dark": (232, 168, 30), "tomato": (236, 62, 46), "lettuce": (132, 212, 62), "veg_green": (78, 172, 52),
    "broccoli": (58, 142, 56), "fry": (255, 212, 84), "crust": (222, 152, 72), "sauce": (212, 42, 36),
    "pepperoni": (186, 40, 40), "frosting": (255, 140, 192), "choc": (112, 62, 34), "waffle": (216, 152, 72),
    "board_wood": (228, 174, 112), "cracker": (232, 192, 122), "grape": (124, 62, 156), "olive": (96, 126, 44),
    "melon_red": (242, 72, 84), "melon_rind": (62, 162, 62), "cream_soft": (255, 246, 226), "mustard": (255, 202, 32),
    "ketchup": (216, 36, 30), "sausage": (192, 82, 52), "carrot": (255, 132, 30), "apple_red": (222, 40, 42),
    "lemon": (255, 232, 72), "mint": (150, 230, 200), "plum": (150, 40, 90),
})
K.GLASS.update({"soda": (255, 140, 40), "soda_fall": (255, 168, 72), "choco": (106, 58, 30), "choco_fall": (128, 74, 40)})
SPRINKLES = ("pink", "yellow", "sky_blue", "white", "lettuce", "orange")


# ------------------------------------------------------------------ voxel shape helpers
def ball(F, x, y, z0, r, look, squash=1.0, step=None, segs=16, studs=True, looks=None):
    """A studded voxel ball (squash < 1 flattens it) standing on z0."""
    K.voxel_round(F, x, y, z0, lambda t: r * math.sqrt(max(0.0, 1 - (2 * t - 1) ** 2)), 2 * r * squash, look,
                  step=step or max(0.4, r / 5), segs=segs, studs=studs, looks=looks)


def dome(F, x, y, z0, r, h, look, step=None, segs=20, studs=True, looks=None):
    """A studded voxel dome: radius r at z0 rounding to a point at z0 + h."""
    K.voxel_round(F, x, y, z0, lambda t: r * math.sqrt(max(0.0, 1 - t * t)), h, look, step=step or max(0.4, h / 7),
                  segs=segs, studs=studs, looks=looks)


def taper(F, x, y, z0, r0, r1, h, look, step=0.8, segs=16, studs=True, looks=None):
    """A stepped (voxel) cone / cup: radius r0 at the bottom to r1 at the top."""
    K.voxel_round(F, x, y, z0, lambda t: r0 + (r1 - r0) * t, h, look, step=step, segs=segs, studs=studs, looks=looks)


def pixel_rows(F, rows, cell, depth, y=0.0, z0=0.0, rot=0.0):
    """Upright pixel art in the local x-z plane: rows (bottom to top) of [(x0, x1, look)], each `cell` tall."""
    for k, row in enumerate(rows):
        for (x0, x1, look) in row:
            if x1 - x0 > 0.05:
                F.brick((x0 + x1) / 2, y, z0 + k * cell, x1 - x0, depth, cell, look, rot=rot, bevel=0.04)


# ------------------------------------------------------------------ giant foods
def giant_burger(F, x, y, s=1.0):
    """Bun, patty, a cheese slice with corner drips, tomato, a lettuce frill, a studded top bun with sesame seeds."""
    R = 7 * s
    F.cyl(x, y, R * 0.95, 0, 1.6 * s, "bun", segs=28, bevel=0.3)
    F.cyl(x, y, R, 1.6 * s, 3.6 * s, "patty", segs=28, bevel=0.3)
    F.brick(x, y, 3.6 * s, R * 1.5, R * 1.5, 0.5 * s, "cheese", rot=20, studs=False)
    for a in (65, 155, 245, 335):  # cheese drips at the corners
        px, py = polar(R * 1.02, a)
        F.brick(x + px, y + py, 2.4 * s, 1.0 * s, 1.0 * s, 1.7 * s, "cheese", rot=a, studs=False, bevel=0.2)
    F.cyl(x, y, R * 1.02, 4.1 * s, 4.8 * s, "tomato", segs=28)
    for k in range(18):  # the lettuce frill
        px, py = polar(R * 1.04, k * 20)
        F.brick(x + px, y + py, 4.6 * s, 2.6 * s, 0.7 * s, 0.6 * s, "lettuce", rot=k * 20 + 90, studs=False, bevel=0.15)
    dome(F, x, y, 4.8 * s, R, 5.4 * s, "bun", step=0.6 * s, segs=28)
    for k in range(14):  # sesame seeds sitting on the dome's ledges
        r = R * rng.uniform(0.25, 0.85)
        px, py = polar(r, rng.uniform(0, 360))
        z = 4.8 * s + 5.4 * s * math.sqrt(max(0, 1 - (r / R) ** 2))
        F.brick(x + px, y + py, z - 0.2, 0.7 * s, 0.4 * s, 0.35 * s, "cream_soft", rot=rng.uniform(0, 180), studs=False, bevel=0.1)


def giant_fries(F, x, y, s=1.0, rot=0.0, box="red", sections=4):
    """A red fries box widening upward (a gold star on the front), fries standing up out of it."""
    G = F.sub(x, y, rot)
    for k in range(sections):
        G.brick(0, 0, k * 2.5 * s, (6 + k * 0.5) * s, (4 + k * 0.3) * s, 2.5 * s, box, studs=False)
    top = sections * 2.5 * s
    G.brick(0, 0, top - 0.6 * s, (6.6 + sections * 0.5) * s, (4.4 + sections * 0.3) * s, 0.6 * s, "white", studs=False)
    G.disc_v(0, -(2 + sections * 0.15) * s - 0.3, top * 0.5, 1.5 * s, 0.3, "yellow", segs=5)  # a star-ish badge
    w, d = (5 + sections * 0.5) * s, (3 + sections * 0.3) * s
    for i in range(int(w / s)):
        for j in range(int(d / s)):
            if rng.random() < 0.85:
                h = rng.uniform(4.0, 8.0) * s
                G.brick(-w / 2 + (i + 0.5) * s, -d / 2 + (j + 0.5) * s, top - 2 * s, 0.9 * s, 0.9 * s, h + 2 * s,
                        "fry", rot=rng.uniform(-8, 8), bevel=0.06)


def lawn_pizza(F, x, y, R=10.0):
    """A whole pizza lying flat as a lawn feature: crust, sauce, studded cheese, pepperoni, olives, basil, cut lines."""
    F.cyl(x, y, R, 0, 0.8, "crust", segs=40, studs=True)
    F.cyl(x, y, R - 1.3, 0.8, 1.0, "sauce", segs=40)
    F.cyl(x, y, R - 1.9, 1.0, 1.25, "cheese", segs=40, studs=True)
    for k in range(9):
        px, py = polar(R * rng.uniform(0.2, 0.7), k * 40 + rng.uniform(-12, 12))
        F.cyl(x + px, y + py, 1.3, 1.25, 1.5, "pepperoni", segs=14)
    for k in range(7):
        px, py = polar(R * rng.uniform(0.15, 0.75), rng.uniform(0, 360))
        F.ring(0.25, 0.6, 1.25, 1.45, "black", cx=x + px, cy=y + py, segs=10)
        qx, qy = polar(R * rng.uniform(0.15, 0.75), rng.uniform(0, 360))
        F.brick(x + qx, y + qy, 1.25, 1.2, 0.7, 0.2, "veg_green", rot=rng.uniform(0, 180), studs=False, bevel=0.1)
    for k in range(3):  # cut lines
        F.brick(x, y, 1.25, 2 * (R - 2.0), 0.18, 0.08, "crust", rot=k * 60, studs=False, bevel=0.0)


def pizza_slice_upright(F, z0=0.0, H=10.0, depth=1.6, rot=0.0):
    """A pizza slice standing on its crust, point up - upright pixel art (rows of studded bricks)."""
    n = int(H)
    W0 = H * 0.9
    rows = [[(-W0 / 2, W0 / 2, "crust")]]
    for k in range(1, n):
        hw = W0 / 2 * (1 - k / n)
        rows.append([(-hw, -hw + 0.6, "sauce"), (-hw + 0.6, hw - 0.6, "cheese"), (hw - 0.6, hw, "sauce")] if hw > 1.4
                    else [(-hw, hw, "cheese")])
    pixel_rows(F, rows, 1.0, depth, z0=z0, rot=rot)
    for (px, pz) in ((-1.4, 2.6), (1.6, 3.4), (0, 5.4), (-0.2, 1.6)):
        for sgn in (-1, 1):
            F.disc_v(px, sgn * (depth / 2 + 0.05), z0 + pz, 0.8, 0.2, "pepperoni", rot=rot, segs=12)


def hot_dog(F, x, y, z, L=12.0, rot=0.0):
    """Lying along local x: a bun with lips, a sausage with rounded ends, a mustard zig-zag."""
    G = F.sub(x, y, rot, z=z)
    G.brick(0, 0, 0, L, 3.2, 1.4, "bun", studs=False, bevel=0.4)
    for sgn in (-1, 1):
        G.brick(0, sgn * 1.25, 1.2, L - 1.0, 0.9, 1.4, "bun", bevel=0.3)
    G.brick(0, 0, 1.6, L + 1.0, 1.6, 1.7, "sausage", studs=False, bevel=0.35)  # (sits proud of the bun lips)
    for sgn in (-1, 1):
        G.brick(sgn * (L / 2 + 0.8), 0, 1.8, 0.8, 1.2, 1.2, "sausage", studs=False, bevel=0.3)
    for k in range(int(L / 1.4)):
        G.brick(-L / 2 + 0.9 + k * 1.4, 0, 3.3, 1.5, 0.4, 0.3, "mustard", rot=40 if k % 2 else -40, studs=False, bevel=0.1)


def donut_flat(F, x, y, z0, R=4.0, a=1.6, frost="frosting"):
    """A voxel torus lying flat: dough below, frosting on top, sprinkles."""
    n = max(4, int(2 * a / 0.4))
    for k in range(n):
        dz = -a + (k + 0.5) * 2 * a / n
        hw = math.sqrt(max(0.0, a * a - dz * dz))
        top = dz > -0.1
        F.ring(R - hw, R + hw, z0 + k * 2 * a / n, z0 + (k + 1) * 2 * a / n, frost if top else "bun", cx=x, cy=y, segs=28,
               studs=top)
    for k in range(16):
        px, py = polar(R + rng.uniform(-a * 0.5, a * 0.5), rng.uniform(0, 360))
        F.brick(x + px, y + py, z0 + 2 * a - 0.05, 0.6, 0.2, 0.2, rng.choice(SPRINKLES), rot=rng.uniform(0, 180), studs=False, bevel=0.05)


def donut_upright(F, cz, R=4.4, r_in=1.8, depth=2.4):
    """An upright donut (a sign that turns): dough ring, pink frosting on both faces, sprinkles."""
    F.ring_v(0, 0, cz, r_in, R, depth, "bun", segs=28)
    for sgn in (-1, 1):
        F.ring_v(0, sgn * (depth / 2 + 0.12), cz, r_in + 0.3, R - 0.25, 0.26, "frosting", segs=28)
        for k in range(12):
            a = math.radians(k * 30 + 9)
            r = (r_in + R) / 2 + (0.6 if k % 2 else -0.5)
            F.brick(r * math.cos(a), sgn * (depth / 2 + 0.3), cz + r * math.sin(a) - 0.1, 0.6, 0.15, 0.22,
                    SPRINKLES[k % len(SPRINKLES)], rot=k * 37, studs=False, bevel=0.03)


def ice_cream(F, x, y, z0=0.0, s=1.0, flavours=("pink", "cream_soft", "choc")):
    """A waffle cone (stepped, point down) with stacked studded scoops."""
    taper(F, x, y, z0, 0.5 * s, 2.6 * s, 7 * s, "waffle", step=0.7 * s, looks=lambda k: "waffle" if k % 2 else "crust")
    for k, lk in enumerate(flavours):
        ball(F, x, y, z0 + (6.0 + k * 3.6) * s, 2.7 * s, lk, squash=0.85, step=0.6 * s)


def cupcake(F, x, y, s=1.0, wrapper="pink", frost="cream_soft"):
    taper(F, x, y, 0, 2.6 * s, 3.4 * s, 3.2 * s, wrapper, step=0.8 * s, studs=False,
          looks=lambda k: wrapper if k % 2 == 0 else "white")
    taper(F, x, y, 3.2 * s, 3.6 * s, 0.6 * s, 4.4 * s, frost, step=0.55 * s)  # the frosting swirl
    ball(F, x, y, 7.4 * s, 0.9 * s, "apple_red", step=0.4 * s, studs=False)
    for k in range(10):
        px, py = polar(rng.uniform(1.2, 3.0) * s, rng.uniform(0, 360))
        F.brick(x + px, y + py, 3.2 * s + (3.6 * s - math.hypot(px, py)) * 1.1, 0.5, 0.18, 0.18, rng.choice(SPRINKLES), rot=rng.uniform(0, 180), studs=False)


def lollipop(F, x, y, h=10.0, r=4.0, looks=("red", "white"), rot=0.0):
    G = F.sub(x, y, rot)
    G.cyl(0, 0, 0.35, 0, h, "white", segs=8)
    edges = [0.0, 0.9] + [0.9 + (k + 1) * (r - 0.9) / 3 for k in range(3)]
    G.disc_v(0, 0, h, edges[1], 1.0, looks[1], segs=16)
    for k in range(3):
        G.ring_v(0, 0, h, edges[k + 1], edges[k + 2], 1.0, looks[k % 2], segs=28, gap=0.0)


def candy_cane(F, x, y, h=12.0, rot=0.0, R=2.5):
    """A pixel candy cane: a striped post and a hook of cubes (stripes alternate every cube)."""
    G = F.sub(x, y, rot)
    k = 0
    z = 0.0
    while z < h:
        G.brick(0, 0, z, 1.2, 1.2, 1.2, "red" if k % 2 == 0 else "white", bevel=0.1)
        z += 1.2
        k += 1
    for j in range(9):
        a = math.radians(180 - j * 22.5)
        G.brick(R + R * math.cos(a), 0, h + R * math.sin(a), 1.2, 1.2, 1.2, "red" if (k + j) % 2 == 0 else "white", bevel=0.1)
    G.brick(2 * R, 0, h - 1.2, 1.2, 1.2, 1.2, "white" if (k + 9) % 2 == 0 else "red", bevel=0.1)


def watermelon_slice(F, x, y, R=6.0, depth=2.0, rot=0.0):
    """An upright half slice standing on its rind (flat red side up): pixel rows, seeds on both faces."""
    G = F.sub(x, y, rot)
    n = int(R / 0.8)
    rows = []
    for k in range(n):
        zc = (k + 0.5) * 0.8
        hw = math.sqrt(max(0.0, R * R - (R - zc) ** 2))
        rows.append([(-hw, hw, "melon_rind")] if k == 0 else
                    [(-hw, -hw + 0.8, "melon_rind"), (-hw + 0.8, -hw + 1.2, "cream_soft"), (-hw + 1.2, hw - 1.2, "melon_red"),
                     (hw - 1.2, hw - 0.8, "cream_soft"), (hw - 0.8, hw, "melon_rind")])
    pixel_rows(G, rows, 0.8, depth)
    for (px, pz) in ((-2.2, 4.0), (0, 3.2), (2.4, 4.4), (-1, 2.2), (1.2, 2.0)):
        for sgn in (-1, 1):
            G.brick(px, sgn * (depth / 2 + 0.05), pz, 0.35, 0.12, 0.55, "black", studs=False, bevel=0.05)


def apple(F, x, y, r=3.0, look="apple_red"):
    ball(F, x, y, 0, r, look, squash=0.9, step=0.5)
    F.brick(x, y, 1.8 * r - 0.3, 0.4, 0.4, 1.4, "wood_dark", studs=False)
    F.brick(x + 0.8, y, 1.8 * r + 0.6, 1.4, 0.5, 0.25, "veg_green", rot=30, studs=False, bevel=0.1)


def garden_bed(F, x, y, sx, sy, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, sx, sy, 1.4, "wood", studs=False)
    G.brick(0, 0, 1.4, sx - 1.2, sy - 1.2, 0.2, "dirt_dark")
    for sgn in (-1, 1):
        G.brick(0, sgn * (sy / 2 - 0.3), 1.4, sx, 0.6, 0.3, "wood_dark", studs=False)
        G.brick(sgn * (sx / 2 - 0.3), 0, 1.4, 0.6, sy, 0.3, "wood_dark", studs=False)


def carrot(F, x, y, s=1.0):
    """A giant carrot top pushing out of the soil, with a fan of leaves."""
    taper(F, x, y, 1.0, 2.2 * s, 1.8 * s, 1.6 * s, "carrot", step=0.4 * s)
    for k, a in enumerate((0, 72, 144, 216, 288)):
        px, py = polar(0.7 * s, a)
        F.brick(x + px, y + py, 2.6 * s, 0.6 * s, 0.6 * s, (3.6 + (k % 2) * 1.6) * s, "veg_green", rot=a, studs=False, bevel=0.1)


def broccoli(F, x, y, s=1.0):
    F.brick(x, y, 0, 2.2 * s, 2.2 * s, 5.5 * s, "lettuce", studs=False)
    for (dx, dy, dz, r) in ((0, 0, 5.0, 3.0), (2.4, 0.6, 4.2, 2.2), (-2.2, 1.0, 4.4, 2.2), (0.4, -2.4, 4.3, 2.1), (-0.6, 2.4, 4.6, 2.0)):
        ball(F, x + dx * s, y + dy * s, dz * s, r * s, "broccoli", squash=0.9, step=0.55 * s)


def picnic_blanket(F, x, y, n=5, cell=2.0, rot=0.0, look="red"):
    G = F.sub(x, y, rot)
    for i in range(n):
        for j in range(n):
            G.brick((i - (n - 1) / 2) * cell, (j - (n - 1) / 2) * cell, 0, cell, cell, 0.3, look if (i + j) % 2 == 0 else "white", bevel=0.0)


def basket(F, x, y, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0.3, 3.6, 2.4, 1.8, "wood", studs=False)
    G.brick(0, 0, 2.1, 3.8, 2.6, 0.4, "red")
    G.ring_v(0, 0, 2.5, 1.3, 1.7, 0.4, "wood_dark", segs=12, a0=0, a1=180)


def picnic_table(F, x, y, rot=0.0, umbrella="red"):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 2.6, 6.4, 3.2, 0.4, "wood")
    for sgn in (-1, 1):
        G.brick(sgn * 2.4, 0, 0, 0.6, 2.4, 2.6, "wood_dark", studs=False)
        G.brick(0, sgn * 2.8, 1.4, 6.4, 1.0, 0.4, "wood")
        G.brick(0, sgn * 2.8, 0, 0.5, 0.6, 1.4, "wood_dark", studs=False)
    if umbrella:
        G.cyl(0, 0, 0.2, 3.0, 7.4, "white", segs=6)
        taper(G, 0, 0, 6.0, 4.2, 0.5, 1.6, umbrella, step=0.4, segs=20, looks=lambda k: umbrella if k % 2 == 0 else "white")


def condiment_lamp(F, x, y, kind="ketchup"):
    """A giant squeeze bottle (ketchup red or mustard yellow) with a warm bulb at the nozzle: the island's lamp post."""
    look = kind
    F.cyl(x, y, 1.3, 0, 6.0, look, segs=16, bevel=0.2)
    F.cyl(x, y, 1.36, 2.4, 4.0, "white", segs=16)
    taper(F, x, y, 6.0, 1.3, 0.5, 1.2, look, step=0.4, segs=16)
    F.cyl(x, y, 0.3, 7.2, 8.4, "white", segs=8)
    F.sphere(x, y, 9.0, 0.7, 0.7, 0.7, "glow_warm", seg=10, rings=6)


def festoon(F, a, b, n=9, sag=1.6):
    """String lights between two points (x, y, z): little warm bulbs along a sagging line."""
    for k in range(n + 1):
        t = k / n
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        z = a[2] + (b[2] - a[2]) * t - sag * 4 * t * (1 - t)
        F.brick(x, y, z, 0.45, 0.45, 0.55, "glow_bulb" if k % 2 == 0 else "glow_warm", studs=False, bevel=0.12)


# ------------------------------------------------------------------ stalls, trucks, restaurants
def food_stall(F, name, color, prop=None):
    """A market stall facing local -y: counter, back wall with a menu board, striped awning, a sign, a giant food
    on the roof (prop). Steam rises from the roof vent (back corner, clear of the prop + the string lights) in the
    ambience pass (fc_layout.json -> fx.steam)."""
    F.brick(0, 0, 0, 12, 9, 0.6, "stone_warm")
    F.brick(0, -2.6, 0.6, 10, 2.4, 3.2, color, studs=False)
    F.brick(0, -2.6, 3.8, 10.6, 3.0, 0.4, "white")
    F.brick(0, 2.8, 0.6, 10, 1.2, 8.0, "cream", studs=False)
    W.board(F, 0, 2.1, 4.6, 6, 2.6, "MENU", bg="black", fg="white", trim="wood", size=0.8)
    for sx in (-1, 1):
        F.brick(sx * 4.8, -3.4, 4.2, 0.8, 0.8, 4.4, "white", studs=False)
        F.brick(sx * 4.8, 1.0, 0.6, 0.8, 4.0, 8.0, "white", studs=False)
    F.brick(0, -0.2, 8.6, 11.0, 7.6, 0.6, "white")
    for k in range(8):  # the scalloped striped awning
        x = -5.5 + (k + 0.5) * 11 / 8
        for j in range(2):
            F.brick(x, -4.4 - j * 0.8, 8.2 - j * 0.45, 11 / 8, 0.9, 0.5, color if k % 2 == 0 else "awning_white", studs=(j == 0))
    W.board(F, 0, -4.2, 9.4, 9, 2.2, name, bg=color, fg="white", trim="white", size=0.95)
    for k in range(3):  # little pots + plates on the counter
        F.cyl(-3 + k * 3, -2.6, 0.7, 4.2, 4.9, "metal_dark" if k != 1 else "white", segs=10)
    F.cyl(4.2, 2.8, 0.5, 9.2, 10.8, "metal", segs=10)  # the kitchen vent (steam)
    F.cyl(4.2, 2.8, 0.75, 10.8, 11.1, "metal_dark", segs=10)
    if prop:
        prop(F.sub(0, 0.6, z=9.2))


def food_truck(F, body="sky_blue", trim="white", sign="ICE CREAM", prop=None):
    """A food truck parked with its serving hatch to local -y (long along local x)."""
    F.brick(0, 0, 0.9, 16, 6.4, 1.0, "metal_dark", studs=False)
    F.brick(-1.5, 0, 1.9, 12, 6.4, 7.0, body, studs=False)
    F.brick(-1.5, 0, 8.9, 12.4, 6.8, 0.5, trim)
    F.brick(6.2, 0, 1.9, 3.6, 6.2, 4.6, body, studs=False)  # the cab
    F.brick(6.2, 0, 6.5, 3.2, 5.8, 0.4, trim)
    K.window(F.sub(8.05, 0, rot=90), 0, 0, 3.6, 4.4, 2.2, 0, frame=trim, depth=0.4)
    F.brick(-1.5, -3.25, 4.4, 7.0, 0.2, 3.2, "black", studs=False)  # the hatch
    F.brick(-1.5, -3.5, 4.0, 7.6, 1.2, 0.4, trim)
    for k in range(6):
        F.brick(-5 + (k + 0.5) * 7 / 6, -4.0, 7.9, 7 / 6, 1.6, 0.4, body if k % 2 == 0 else "awning_white", studs=False)
    W.board(F, -1.5, -3.4, 9.4, 8, 1.8, sign, bg=trim, fg="ink", trim=body, size=0.9)
    for (wx, sgn) in ((-5.5, -1), (-5.5, 1), (5.5, -1), (5.5, 1)):
        F.disc_v(wx, sgn * 3.25, 1.6, 1.5, 0.8, "black", segs=16)
        F.disc_v(wx, sgn * 3.7, 1.6, 0.6, 0.2, "metal", segs=10)
    if prop:
        prop(F.sub(-1.5, 0, z=9.4))


def _eatery(F, w, d, h, wall, trim, awning, sign, sign_bg, sign_fg="white", windows=True):
    """The shared restaurant shell (front = local -y): base, walls, windows, door, striped awning, a big sign board.
    Returns the roof height."""
    F.brick(0, 0, 0, w + 4, d + 6, 0.8, "stone_warm")
    F.brick(0, 1.5, 0.8, w, d, h, wall, studs=False)
    F.brick(0, 1.5, 0.8 + h, w + 1, d + 1, 0.8, trim)
    if windows:
        for k in range(int(w / 8)):
            x = -w / 2 + 4 + k * 8
            if abs(x) > 3:
                K.window(F, x, -d / 2 + 1.45, 2.2, 4.6, 4.4, 0, frame=trim, mullions=1)
    K.door(F, 0, -d / 2 + 1.45, 0.8, 3.6, 6.2, 0, frame=trim, leaf=awning)
    n = int(w / 1.8)
    for k in range(n):  # striped awning over the front
        x = -w / 2 + (k + 0.5) * w / n
        for j in range(3):
            F.brick(x, -d / 2 + 0.6 - j * 0.9, 7.6 - j * 0.5, w / n, 1.0, 0.55, awning if k % 2 == 0 else "awning_white", studs=(j == 0))
    W.board(F, 0, -d / 2 + 0.9, 8.6, min(w - 4, 20), 3.0, sign, bg=sign_bg, fg=sign_fg, trim=trim, size=1.5)  # (above the awning)
    return 0.8 + h + 0.8


def burger_barn(F):
    """A red barn diner with a gable roof and a hay-loft window (its spinning burger sign stands beside it)."""
    F.brick(0, 0, 0, 30, 26, 0.8, "stone_warm")
    F.brick(0, 2, 0.8, 26, 18, 11, "brick_red", studs=False)
    for sx in (-1, 1):
        F.brick(sx * 13.1, -6.9, 0.8, 0.8, 0.8, 11, "white", studs=False)
    F.roof_gable(0, 2, 11.8, 26, 18, 7.0, "roof_red", courses=7, overhang=1.0, trim="white")
    F.brick(0, -7.05, 0.8, 8, 0.3, 8, "wood_dark", studs=False)  # barn doors with white frames + braces
    for sx in (-1, 1):
        F.brick(sx * 2, -7.25, 0.8, 0.5, 0.3, 8, "white", studs=False)
        for zz in (0.8, 4.6, 8.4):
            F.brick(sx * 2, -7.25, zz, 4.0, 0.3, 0.4, "white", studs=False)
    K.window(F, 0, -7.05, 13.2, 3.6, 3.0, 0, frame="white", shutters="wood")
    for sx in (-1, 1):
        K.window(F, sx * 9, -7.05, 3.0, 4.0, 4.0, 0, frame="white", mullions=1)
    W.board(F, 0, -7.6, 9.4, 14, 2.6, "BURGER BARN", bg="cream", fg="red", trim="white", size=1.4)
    for (x, y) in ((-9, -12), (0, -13), (9, -12)):
        picnic_table(F, x, y, 0, umbrella="red" if x else "yellow")


def pizza_palace(F, slice_sign=True):
    """Cream walls, a red-and-white awning, a crenellated 'palace' parapet with corner turrets, a pizza-slice sign on
    the roof and a brick oven chimney (smoke)."""
    top = _eatery(F, 28, 18, 10, "cream", "white", "red", "PIZZA PALACE", "red")
    for k in range(9):
        if k % 2 == 0:
            F.brick(-14 + k * 3.5, -7.2, top, 2.4, 1.2, 1.6, "brick_red")
    for sx in (-1, 1):
        F.cyl(sx * 14, -7.5, 2.6, 0.8, top + 4, "brick_red", segs=12)
        taper(F, sx * 14, -7.5, top + 4, 3.0, 0.6, 3.2, "roof_red", step=0.5)
    if slice_sign:  # (fc_build builds it as its own turning object instead)
        pizza_slice_upright(F.sub(0, 4, z=top), H=11, depth=1.6)
    F.brick(9, 6, top, 3.0, 3.0, 7.0, "brick_red", studs=False)  # the oven chimney (smoke)
    F.brick(9, 6, top + 7, 3.6, 3.6, 0.6, "stone_dark")


def fry_factory(F):
    """A yellow factory with a sawtooth roof, a chimney (steam), and a giant fries box on the roof."""
    F.brick(0, 0, 0, 34, 24, 0.8, "stone_warm")
    F.brick(0, 2, 0.8, 30, 18, 9, "yellow", studs=False)
    F.brick(0, 2, 9.8, 31, 19, 0.6, "white")
    for k in range(4):  # sawtooth roof
        F.wedge(-11.25 + k * 7.5, 2, 10.4, 7.5, 18, 4.0, "roof_red" if k % 2 == 0 else "orange", ridge="y")
    for k in range(3):
        K.window(F, -10 + k * 10, -7.05, 2.4, 5.0, 4.4, 0, frame="white", mullions=2)
    K.door(F, 13, -7.05, 0.8, 3.4, 6.0, 0, frame="white", leaf="red")
    W.board(F, -2, -7.4, 7.2, 16, 2.2, "FRY FACTORY", bg="red", fg="yellow", trim="white", size=1.2)
    F.cyl(12, 7, 1.8, 10.4, 22, "brick_red", segs=12)
    F.cyl(12, 7, 2.1, 21, 22.4, "stone_dark", segs=12)
    giant_fries(F.sub(-6, 6, z=14.4), 0, 0, 0.8, sections=3)


def donut_diner(F):
    """A retro diner: pink walls, a chrome band, big windows, a checkered step (its donut sign spins on a pole)."""
    top = _eatery(F, 26, 16, 9, "frosting", "white", "sky_blue", "DONUT DINER", "sky_blue")
    F.brick(0, -6.55, 6.7, 26.2, 0.3, 0.6, "metal", studs=False)  # the chrome band (between windows + awning)
    for k in range(13):
        F.brick(-12 + k * 2, -9.6, 0.8, 2, 2, 0.2, "white" if k % 2 else "black", studs=False, bevel=0.0)
    for k in range(3):
        donut_flat(F, -8 + k * 8, 3, top, R=2.2, a=0.9, frost=("frosting", "choc", "cream_soft")[k])


def taco_tower(F):
    """Three stacked, shrinking blocks with balconies; a giant taco on top."""
    z = 0.8
    F.brick(0, 0, 0, 24, 24, 0.8, "stone_warm")
    for k, (w, h, look) in enumerate(((20, 10, "orange"), (16, 9, "yellow"), (12, 8, "red"))):
        F.brick(0, 0, z, w, w, h, look, studs=False)
        F.brick(0, 0, z + h, w + 1.2, w + 1.2, 0.6, "white")
        for sx in (-1, 1):
            K.window(F, sx * w / 4, -w / 2 - 0.05, z + 2, 3.0, h - 5, 0, frame="white", mullions=1)
        z += h + 0.6
    K.door(F, 0, -10.05, 0.8, 3.4, 6.0, 0, frame="white", leaf="veg_green")
    W.board(F, 0, -10.4, 8.1, 12, 2.2, "TACO TOWER", bg="veg_green", fg="white", trim="white", size=1.2)
    # the taco: an upright half-moon shell with lettuce, tomato and cheese poking out of the top
    G = F.sub(0, 0, z=z)
    R, n = 6.0, 7
    rows = []
    for k in range(n):
        zc = (k + 0.5) * R / n
        hw = math.sqrt(max(0.0, R * R - (R - zc) ** 2))
        rows.append([(-hw, hw, "waffle")])
    pixel_rows(G, rows, R / n, 3.0)
    for k in range(9):
        x = -5 + k * 1.25
        G.brick(x, 0, R - 0.2 + (k % 2) * 0.3, 1.1, 2.2, 1.0, ("lettuce", "tomato", "cheese")[k % 3], studs=False, bevel=0.15)


def noodle_house(F):
    """Red walls, two stacked stepped hip roofs, glowing lanterns, a giant noodle bowl with chopsticks."""
    top = _eatery(F, 24, 16, 9, "red", "gold", "red", "NOODLE HOUSE", "black", sign_fg="gold")
    F.roof_hip(0, 1.5, top, 26, 18, 4.0, "roof_teal", courses=4, overhang=1.2, trim="gold")
    F.brick(0, 1.5, top, 14, 9, 8.0, "red", studs=False)  # the upper storey rises through the lower roof
    for sx in (-1, 1):
        K.window(F, sx * 3.5, 1.5 - 4.55, top + 4.2, 2.6, 2.6, 0, frame="gold", depth=0.4)
    F.roof_hip(0, 1.5, top + 8.0, 16, 11, 3.4, "roof_teal", courses=4, overhang=1.0, trim="gold")
    for sx in (-1, 1):  # paper lanterns on posts at the front corners
        F.brick(sx * 13.6, -8.4, 0.8, 0.5, 0.5, 4.6, "wood_dark", studs=False)
        F.brick(sx * 13.6, -8.4, 5.4, 1.8, 1.8, 2.2, "glow_red", studs=False, bevel=0.4)
        F.brick(sx * 13.6, -8.4, 7.6, 0.9, 0.9, 0.4, "gold", studs=False)
    G = F.sub(-19, -8, z=0)  # the noodle bowl on a plinth beside the building
    G.brick(0, 0, 0, 7, 7, 2.0, "stone_dark")
    taper(G, 0, 0, 2.0, 1.8, 3.6, 3.0, "white", step=0.5, studs=False, looks=lambda k: "white" if k != 3 else "sky_blue")
    G.cyl(0, 0, 3.4, 4.6, 4.9, "lemon")
    for k in range(6):
        G.brick(rng.uniform(-1.8, 1.8), rng.uniform(-1.8, 1.8), 4.9, 2.6, 0.35, 0.3, "fry", rot=rng.uniform(0, 180), studs=False)
    for dx in (-0.5, 0.5):
        G.brick(dx, 1.4, 4.4, 0.3, 0.3, 6.0, "wood_dark", rot=0, studs=False)


# ------------------------------------------------------------------ the plaza's soda fountain, the gate, the portal
def soda_fountain(F):
    """A giant striped soda cup with a lid and a bendy straw in a round basin; soda pours from four spouts."""
    F.cyl(0, 0, 10, 0, 1.4, "white", segs=40, studs=True)
    F.ring(9.0, 10.2, 1.4, 2.0, "red", segs=40)
    F.cyl(0, 0, 9.0, 0.8, 1.3, "soda", segs=40)
    taper(F, 0, 0, 1.3, 3.4, 4.4, 11.6, "red", step=0.8, studs=False, looks=lambda k: "red" if (k // 2) % 2 == 0 else "white")
    F.cyl(0, 0, 4.7, 12.9, 13.7, "white", segs=24, studs=True)
    for k in range(8):  # the straw: striped, with a bend
        F.cyl(1.4, 0.8, 0.6, 13.7 + k * 0.9, 14.6 + k * 0.9, "red" if k % 2 else "white", segs=10)
    F.brick(2.4, 0.8, 20.6, 2.6, 1.2, 1.2, "red", studs=False, bevel=0.3)
    for a in (45, 135, 225, 315):  # little nozzles + thin pours of soda with a foam splash where they land
        sx, sy = polar(4.9, a)
        F.brick(sx, sy, 9.6, 1.8, 0.7, 0.6, "white", rot=a, studs=False, bevel=0.2)
        fx, fy = polar(5.8, a)
        F.brick(fx, fy, 1.3, 0.5, 0.9, 8.5, "soda_fall", rot=a + 90, studs=False, bevel=0.15)
        for k in range(5):
            ox, oy = polar(rng.uniform(0.5, 1.3), rng.uniform(0, 360))
            F.brick(fx + ox, fy + oy, 1.3, 0.6, 0.6, rng.uniform(0.25, 0.5), "cream_soft", rot=rng.uniform(0, 90), studs=False, bevel=0.15)


def big_bottle(F, x, y, look, H=14.0, R=3.2):
    """A giant squeeze bottle (a gate pillar): body, white label band, stepped shoulders, nozzle."""
    F.cyl(x, y, R + 0.6, 0, 1.0, "white", segs=20)
    F.cyl(x, y, R, 1.0, H, look, segs=20, bevel=0.3)
    F.cyl(x, y, R + 0.08, H * 0.35, H * 0.62, "white", segs=20)
    taper(F, x, y, H, R, 0.9, 2.4, look, step=0.6, segs=20)
    taper(F, x, y, H + 2.4, 0.9, 0.4, 1.6, "white", step=0.4, segs=10)


def food_gate(F, width=26):
    """A ketchup bottle and a mustard bottle holding a giant hot dog on their nozzles, a FOOD COURT marquee below."""
    for sx, look in ((-1, "ketchup"), (1, "mustard")):
        big_bottle(F, sx * (width / 2 + 3), 0, look)
    hot_dog(F, 0, 0, 17.6, L=width + 4)
    W.marquee(F, 0, -2.2, 11.4, width - 4, 3.4, "FOOD COURT", size=1.6, panel="red", letters="white")


def cherry_keystone(F):
    """A cherry on top (the RETURN HOME ring's keystone)."""
    ball(F, 0, 0, 0, 2.2, "apple_red", step=0.45, studs=False)
    for k in range(3):
        F.brick(0.4 + k * 0.5, 0, 4.0 + k * 0.9, 0.4, 0.4, 1.0, "wood_dark", studs=False)
    F.brick(2.2, 0, 6.6, 1.8, 0.5, 0.3, "veg_green", rot=25, studs=False, bevel=0.1)


def food_egg_deco(F, x, y, s):
    """Rainbow sprinkles on the egg's frosting cap."""
    for k in range(10):
        a = k * 36 + 7
        px, py = polar(1.15 * s, a)
        F.brick(x + px, y + py, (3.0 + (k % 3) * 0.25) * s, 0.45 * s, 0.16 * s, 0.16 * s, SPRINKLES[k % len(SPRINKLES)], rot=a + 60, studs=False)


def food_egg(F, x, y, golden=False):
    """The Food egg: a golden-brown bun egg with a pink frosting cap and sprinkles (golden variant)."""
    W.egg(F, x, y, 1.0, body="gold" if golden else "bun",
          bands={8: "frosting", 9: "frosting", 10: "frosting", 11: "frosting"} if not golden else {5: "glow_gold"}, deco=food_egg_deco)


# ------------------------------------------------------------------ boss arena: THE CHEESE BOARD (Big Cheese rolls)
def cheese_board(F, L=130.0, Wd=72.0, corner=14.0, gap=18.0):
    """A giant wooden cutting board: studded planks along the roll axis (local y), rounded corners, a low dark rim
    open at both ends, a cheese-wedge inlay and a hanging handle on the west side. Nothing stands on it: the boss
    rolls the full length (Line, 110 studs)."""
    plank = 6.0
    n = int(Wd / plank)
    for i in range(n):
        x = -Wd / 2 + (i + 0.5) * plank
        ex = abs(x) - (Wd / 2 - corner)
        cut = corner - math.sqrt(max(0.0, corner * corner - ex * ex)) if ex > 0 else 0.0
        F.brick(x, 0, 0, plank - 0.1, L - 2 * cut, 1.2, "board_wood" if i % 2 else "wood", bevel=0.05)
    # the rim: dark strips along the long sides + short rim pieces at the ends beside the openings
    seg = Wd / 2 - corner - gap / 2
    for sx in (-1, 1):
        F.brick(sx * (Wd / 2 + 0.8), 0, 0, 1.6, L - 2 * corner, 2.0, "wood_dark")
        for sy in (-1, 1):
            F.brick(sx * (gap / 2 + seg / 2), sy * (L / 2 + 0.8), 0, seg, 1.6, 2.0, "wood_dark")
            a0 = {(1, 1): 0, (-1, 1): 90, (-1, -1): 180, (1, -1): 270}[(sx, sy)]
            F.ring(corner, corner + 1.6, 0, 2.0, "wood_dark", cx=sx * (Wd / 2 - corner), cy=sy * (L / 2 - corner),
                   a0=a0, a1=a0 + 90, segs=24, studs=True)
    F.prism([(-9, -6), (9, -6), (-9, 8)], 1.2, 1.35, "cheese", studs=True)  # cheese-wedge inlay
    for (hx, hy, r) in ((-5, -3, 1.4), (-6.5, 3.5, 1.0), (-1.5, -1, 0.8)):
        F.cyl(hx, hy, r, 1.35, 1.4, "cheese_dark", segs=12)
    G = F.sub(-Wd / 2 - 8, 0)  # the handle, with its hanging hole (a dark ring inlay)
    G.brick(0, 0, 0, 16, 14, 1.2, "board_wood")
    G.ring(2.0, 3.2, 1.2, 1.3, "wood_dark", cx=-3, cy=0, segs=20)


def cracker(F, x, y, s=1.0, rot=0.0):
    F.brick(x, y, 0, 5 * s, 5 * s, 0.9 * s, "cracker", rot=rot, bevel=0.15)


def grapes(F, x, y, s=1.0):
    k = 0
    for layer, (n, r, z) in enumerate(((6, 2.0, 0.0), (5, 1.6, 1.6), (3, 1.0, 3.0), (1, 0.0, 4.2))):
        for j in range(n):
            px, py = polar(r * s, j * 360 / max(1, n) + layer * 20)
            ball(F, x + px, y + py, z * s, 1.0 * s, "grape", step=0.4 * s, segs=12)
            k += 1
    F.brick(x, y, 6.2 * s, 0.4 * s, 0.4 * s, 1.4 * s, "wood_dark", studs=False)


def olive_pick(F, x, y, s=1.0):
    """A giant cocktail stick planted in the ground, an olive skewered halfway up, a red frill on top."""
    F.cyl(x, y, 0.2 * s, 0, 10.0 * s, "wood", segs=6)
    ball(F, x, y, 4.6 * s, 1.6 * s, "olive", step=0.4 * s)
    F.cyl(x, y, 0.55 * s, 6.1 * s, 6.5 * s, "red", segs=10)  # the pimento
    F.brick(x, y, 10.0 * s, 1.4 * s, 0.6 * s, 0.6 * s, "red", studs=False, bevel=0.2)


def cheese_wedge(F, x, y, s=1.0, rot=0.0):
    """A giant studded cheese wedge with holes on its faces."""
    G = F.sub(x, y, rot)
    G.prism([(-5 * s, -3 * s), (5 * s, -3 * s), (5 * s, 3 * s)], 0, 6 * s, "cheese", studs=True)
    for (hx, hz, r) in ((-1.5, 2.0, 0.9), (2.5, 4.0, 0.7), (3.2, 1.6, 1.0)):
        G.disc_v(hx * s, -3 * s - 0.05, hz * s, r * s, 0.2, "cheese_dark", segs=12)


def butter_knife(F, x, y, L=34.0, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(-L * 0.18, 0, 0, L * 0.64, 4.0, 0.6, "metal", studs=False, bevel=0.2)
    G.brick(-L * 0.52, 0, 0, 3.0, 3.0, 0.6, "metal", rot=45, studs=False, bevel=0.2)  # a rounded tip
    G.brick(L * 0.33, 0, 0, L * 0.34, 3.0, 1.6, "wood_dark", bevel=0.3)
    for k in range(3):
        G.cyl(L * 0.24 + k * L * 0.09, 0, 0.35, 1.6, 1.7, "metal", segs=8)


def fruit_tree(m, x, y, s=1.0, fruit="orange"):
    """A chunky orchard tree for the groves (canopy in the leaf looks so the wind sways it, fruit studless so it
    rides along)."""
    rot = rng.uniform(0, 90)
    m.brick(x, y, 0, 1.8 * s, 1.8 * s, 6.5 * s, "wood", rot, studs=False)
    m.brick(x, y, 5.4 * s, 8.4 * s, 8.4 * s, 3.6 * s, "leaf", rot)
    m.brick(x, y, 9.0 * s, 5.6 * s, 5.6 * s, 2.4 * s, "leaf_light", rot + 15)
    for k in range(6):
        a = rot + k * 60 + 20
        px, py = 4.25 * s * math.cos(math.radians(a)), 4.25 * s * math.sin(math.radians(a))
        m.brick(x + px, y + py, (6.2 + (k % 2) * 1.2) * s, 1.1 * s, 1.1 * s, 1.1 * s, fruit, a, studs=False, bevel=0.25)
