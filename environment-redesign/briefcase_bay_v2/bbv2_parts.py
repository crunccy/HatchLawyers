# environment-redesign/briefcase_bay_v2/bbv2_parts.py - Briefcase Bay v2's pieces (2026-10-19), on the Ocean Shore v2
# benchmark (crnuch's call: classic Roblox studs, NOT LEGO; cohesive shapes from hl_classic.ClassicMesh, studs only on
# broad tops). Briefcase Bay's own identity: a green headland park on a sheltered bay, warm limestone cliffs, the
# office skyline rising behind. Reuses Ocean Shore v2's natural kit (cliff_column, palm2, bush, falls, foam) with the
# rock looks recoloured to limestone for this island (the PAL entries below are only set in Briefcase Bay's build).
import math
import sys
import os
import hl_kit as K
import hl_classic as CL

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "ocean_shore_v2"))
import osv2_parts as OP  # noqa: E402  (Ocean Shore v2's natural pieces, reused)
import osv2_detail as OD  # noqa: E402

rng = OP.rng

# the rock looks the reused cliff / portal pieces ask for, recoloured to Briefcase Bay's warm limestone
K.PAL.update({
    "rock_grey": (204, 186, 152), "rock_grey_dark": (166, 146, 114), "rock_grey_light": (230, 216, 188),
    "rock_warm_grey": (188, 164, 132), "dirt_rim": (156, 112, 70), "dirt_rim_dark": (118, 82, 50),
})
K.PAL.update({
    # the playable Green (studded lawn) + its flush paths
    "lawn": (118, 212, 58), "lawn_light": (150, 228, 88), "lawn_dark": (90, 182, 44), "clover": (74, 164, 52),
    "worn_grass": (190, 196, 112),
    "path_orange": (255, 160, 24), "path_edge": (255, 252, 240), "paving": (238, 226, 200), "paving_dark": (212, 196, 166),
    "gold": (255, 200, 40), "gold_dark": (214, 150, 30), "paper": (250, 250, 244), "paper_line": (150, 170, 210),
    "daisy": (255, 255, 250), "daisy_eye": (255, 206, 50), "flower_blue": (96, 140, 240), "flower_pink": (250, 130, 180),
    # the skyline (classic Roblox glass towers: smooth blocks, white floor bands, studded flat roofs)
    "tower_glass": (84, 146, 226), "tower_glass_dark": (58, 112, 196), "tower_glass_teal": (70, 176, 200),
    "tower_white": (242, 246, 252), "tower_stone": (220, 206, 178), "roof_flat": (150, 156, 170), "roof_unit": (196, 200, 210),
    "door_dark": (40, 48, 70),
    # the harbour, the lighthouse, the ferry, the monuments
    "quay": (214, 198, 166), "lighthouse_white": (248, 248, 244), "lighthouse_red": (226, 60, 56),
    "hull_white": (244, 244, 248), "hull_blue": (52, 110, 230), "hull_red": (200, 56, 50), "deck": (196, 146, 90),
    "leather": (132, 78, 42), "leather_dark": (94, 54, 28), "gavel_wood": (124, 72, 36), "gavel_band": (255, 200, 40),
    "bark": (128, 88, 52), "canopy": (70, 168, 52), "canopy_light": (104, 196, 70), "canopy_dark": (48, 138, 46),
    "blossom": (250, 170, 200), "blossom_light": (255, 206, 222), "lamp_post": (52, 56, 70), "bench_wood": (186, 124, 66),
    "egg_briefcase": (245, 200, 70), "sign_wood": (150, 96, 52), "sign_wood_dark": (110, 68, 36),
})
K.GLASS.update({"bay": (52, 196, 220), "bay_deep": (30, 150, 200)})
K.GLOWS.update({"glow_cyan": ((120, 220, 255), 2.4), "glow_lamp": ((255, 220, 140), 2.6), "glow_beacon": ((255, 236, 170), 3.4),
                "glow_scales": ((255, 214, 90), 1.6)})

# looks that carry studs: broad terrain + structural tops (the rest stays smooth)
STUD_LOOKS = OP.STUD_LOOKS | {"lawn", "lawn_light", "lawn_dark", "clover", "path_orange", "paving", "paving_dark", "quay", "worn_grass",
                              "roof_flat", "tower_stone", "moss_light", "rock_warm_grey"}


# ------------------------------------------------------------------ the Green's flat decor (walk-through, low)
def daisies(m, x, y, z, n=None):
    """A few daisies flat on the lawn (white petals round a yellow eye, under 0.5 tall)."""
    for k in range(n or rng.randint(3, 7)):
        a, r = rng.uniform(0, 2 * math.pi), rng.uniform(0, 1.8)
        dx, dy = x + math.cos(a) * r, y + math.sin(a) * r
        m.cyl(dx, dy, 0.42, z, z + 0.18, "daisy", segs=8)
        m.cyl(dx, dy, 0.16, z + 0.18, z + 0.26, "daisy_eye", segs=6)


def flower_tuft(m, x, y, z, look=None):
    """A low clump of leaves with a few flower heads (under 1.2 tall)."""
    look = look or rng.choice(("flower_blue", "flower_pink", "flower_yellow", "daisy"))
    for k in range(5):
        a = math.radians(k * 72 + rng.uniform(-15, 15))
        m.beam((x, y, z), (x + math.cos(a) * 0.8, y + math.sin(a) * 0.8, z + 0.6), 0.32, 0.12, "lawn_dark")
    for k in range(3):
        a = math.radians(k * 120 + rng.uniform(-20, 20))
        m.sphere(x + math.cos(a) * 0.45, y + math.sin(a) * 0.45, z + 0.95, 0.32, 0.32, 0.24, look, seg=8, rings=5)


def paper(m, x, y, z, rot=None):
    """A sheet of paper lying flat on the lawn (the Senior Partner's papers), with a couple of ruled lines."""
    rot = rng.uniform(0, 180) if rot is None else rot
    m.brick(x, y, z, 1.7, 2.2, 0.05, "paper", rot=rot, studs=False, bevel=0.0)
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    for k in (-0.4, 0.1, 0.6):
        m.brick(x - s * k, y + c * k, z + 0.05, 1.2, 0.08, 0.02, "paper_line", rot=rot, studs=False, bevel=0.0)


def stepping_stones(m, x0, y0, x1, y1, z):
    """A short trail of flat stones flush with the lawn."""
    L = math.hypot(x1 - x0, y1 - y0)
    for k in range(int(L / 3.2)):
        t = (k + 0.5) / max(1, int(L / 3.2))
        m.rock(x0 + (x1 - x0) * t + rng.uniform(-0.6, 0.6), y0 + (y1 - y0) * t + rng.uniform(-0.6, 0.6), z - 0.25,
               rng.uniform(1.8, 2.6), rng.uniform(1.5, 2.2), 0.33, "paving", rot=rng.uniform(0, 90), jitter=0.12, taper=0.05)


def path(m, pts, z, width=7.0):
    """A flush orange path (the house style): orange paving with white dashed edges, following a polyline."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, y1 - y0)
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        m.brick((x0 + x1) / 2, (y0 + y1) / 2, z - 0.1, L + width * 0.5, width, 0.16, "path_orange", rot=a, studs=False, bevel=0.0)
        t = 0.0
        while t < L:
            for sgn in (-1, 1):
                px, py = x0 + c * (t + 1.2) - s * sgn * (width / 2 - 0.55), y0 + s * (t + 1.2) + c * sgn * (width / 2 - 0.55)
                m.brick(px, py, z + 0.06, 2.4, 0.5, 0.03, "path_edge", rot=a, studs=False, bevel=0.0)
            t += 4.0
    for x, y in pts[1:-1]:  # round joints
        m.cyl(x, y, width / 2, z - 0.1, z + 0.06, "path_orange", segs=24)


def scales_pad(m, x, y, z):
    """The Senior Partner's start: a round limestone paving patch flush with the lawn, a gold scales-of-justice inlay
    (a landmark, never a wall: he leaves it to hunt)."""
    m.cyl(x, y, 13.0, z - 0.2, z + 0.05, "paving_dark", segs=48)
    m.cyl(x, y, 12.0, z + 0.05, z + 0.1, "paving", segs=48)
    m.ring(10.6, 11.2, z + 0.1, z + 0.14, "gold", cx=x, cy=y, segs=48)
    # the scales: a post, a beam, two pans on chains (all flat inlays)
    m.brick(x, y + 0.5, z + 0.1, 0.9, 12.0, 0.05, "gold", studs=False, bevel=0.0)
    m.brick(x, y + 5.6, z + 0.1, 12.0, 0.8, 0.05, "gold", studs=False, bevel=0.0)
    m.cyl(x, y - 5.6, 2.2, z + 0.1, z + 0.15, "gold", segs=20)
    for sgn in (-1, 1):
        for k in range(2):
            m.brick(x + sgn * (5.6 + (k - 0.5) * 2.2), y + 3.4, z + 0.1, 0.35, 4.4, 0.05, "gold", rot=(1 - 2 * k) * 22 * sgn, studs=False, bevel=0.0)
        m.ring(0.01, 2.8, z + 0.1, z + 0.15, "gold", cx=x + sgn * 5.6, cy=y + 1.0, segs=20, a0=180, a1=360)
    m.cyl(x, y + 6.6, 0.9, z + 0.1, z + 0.16, "glow_scales", segs=16)


def egg_preview(m, x, y, z):
    """A sample Briefcase egg (PREVIEW ONLY - the game spawns its own on EggSpots): a gold egg with a leather band."""
    m.sphere(x, y, z + 1.9, 1.5, 1.5, 1.9, "egg_briefcase", seg=14, rings=10)
    m.ring(1.48, 1.62, z + 1.6, z + 2.0, "leather", cx=x, cy=y, segs=20)
    m.ring_v(x, y, z + 3.95, 0.45, 0.8, 0.3, "leather_dark", segs=10, gap=0.0, a0=0, a1=180)


# ------------------------------------------------------------------ trees + lamps (the ring)
def round_tree(m, x, y, z0, s=1.0, blossom=False):
    """A classic Roblox ball tree: a tapered trunk and a lumpy canopy of overlapping balls."""
    h = 7.5 * s * rng.uniform(0.9, 1.15)
    m.cone(x, y, 0.9 * s, z0, z0 + h, "bark", segs=8, r1=0.55 * s)
    for k in range(2):  # a couple of boughs
        a = math.radians(rng.uniform(0, 360))
        m.beam((x, y, z0 + h * 0.6), (x + math.cos(a) * 2.2 * s, y + math.sin(a) * 2.2 * s, z0 + h * 0.9), 0.5 * s, 0.5 * s, "bark")
    looks = ("blossom", "blossom_light", "blossom") if blossom else ("canopy", "canopy_light", "canopy_dark")
    m.sphere(x, y, z0 + h + 2.2 * s, 4.4 * s, 4.4 * s, 3.6 * s, looks[0], seg=14, rings=9)
    for k in range(rng.randint(3, 5)):
        a = math.radians(k * 360 / 4 + rng.uniform(-30, 30))
        r = rng.uniform(2.4, 3.4) * s
        m.sphere(x + math.cos(a) * r, y + math.sin(a) * r, z0 + h + rng.uniform(0.4, 2.4) * s, 2.9 * s, 2.9 * s, 2.4 * s,
                 rng.choice(looks), seg=12, rings=8)
    return z0 + h + 5.8 * s


def lamp_post(m, x, y, z0, h=7.0):
    """A dark park lamp post with a warm lantern."""
    m.cyl(x, y, 0.55, z0, z0 + 0.6, "lamp_post", segs=10)
    m.cyl(x, y, 0.22, z0 + 0.6, z0 + h, "lamp_post", segs=8)
    m.brick(x, y, z0 + h, 1.0, 1.0, 1.2, "glow_lamp", studs=False, bevel=0.12)
    m.pyramid(x, y, z0 + h + 1.2, 1.4, 1.4, 0.7, "lamp_post")


def bench(m, x, y, z0, rot):
    """A park bench (wood slats on dark legs)."""
    F = K.Frame(m, x, y, rot)
    for k in range(3):
        F.brick(0, -0.5 + k * 0.5, z0 + 1.2, 4.2, 0.4, 0.18, "bench_wood", studs=False, bevel=0.04)
    for k in range(2):
        F.brick(0, 0.85, z0 + 1.7 + k * 0.5, 4.2, 0.18, 0.36, "bench_wood", studs=False, bevel=0.04)
    for sgn in (-1, 1):
        F.brick(sgn * 1.8, 0, z0, 0.3, 1.6, 1.2, "lamp_post", studs=False, bevel=0.03)
        F.brick(sgn * 1.8, 0.85, z0 + 1.2, 0.3, 0.2, 1.4, "lamp_post", studs=False, bevel=0.03)


def hedge_run(m, x0, y0, x1, y1, z0, h=2.4, w=2.2):
    """A clipped hedge (a smooth green block with a rounded top) - ring dressing that marks the Green's edge."""
    L = math.hypot(x1 - x0, y1 - y0)
    a = math.degrees(math.atan2(y1 - y0, x1 - x0))
    m.brick((x0 + x1) / 2, (y0 + y1) / 2, z0, L, w, h - 0.5, "canopy_dark", rot=a, studs=False, bevel=0.3)
    m.brick((x0 + x1) / 2, (y0 + y1) / 2, z0 + h - 0.6, L - 0.3, w - 0.3, 0.6, "canopy", rot=a, studs=False, bevel=0.25)


# ------------------------------------------------------------------ the skyline
def tower(m, x, y, z0, w, d, h, rot=0.0, glass="tower_glass", crown=True, band=4.0):
    """A classic Roblox glass office tower: a limestone podium with a dark entrance, one smooth glass shaft with white
    floor bands + corner / mid mullions, a stepped crown with a glowing band, a studded flat roof with a plant room and
    an antenna. Returns the roof z."""
    F = K.Frame(m, x, y, rot)
    pod = min(7.0, h * 0.14)
    F.brick(0, 0, z0, w + 2.4, d + 2.4, pod, "tower_stone", studs=False, bevel=0.15)
    F.brick(0, -(d + 2.4) / 2 - 0.05, z0, w * 0.4, 0.3, pod * 0.7, "door_dark", studs=False, bevel=0.0)
    F.brick(0, -(d + 2.4) / 2 - 0.9, z0 + pod * 0.72, w * 0.6, 1.8, 0.35, "tower_white", studs=False, bevel=0.05)  # canopy
    F.brick(0, 0, z0 + pod - 0.3, w + 2.6, d + 2.6, 0.5, "tower_white", studs=False, bevel=0.1)
    zs = z0 + pod
    shaft = h - pod - (6.0 if crown else 0.0)
    F.brick(0, 0, zs, w, d, shaft, glass, studs=False, bevel=0.06)
    z = zs + band
    while z < zs + shaft - 0.5:  # the floor bands
        F.brick(0, 0, z - 0.25, w + 0.3, d + 0.3, 0.5, "tower_white", studs=False, bevel=0.04)
        z += band
    for sx_ in (-1, 1):  # the corner mullions
        for sy_ in (-1, 1):
            F.brick(sx_ * w / 2, sy_ * d / 2, zs, 0.7, 0.7, shaft, "tower_white", studs=False, bevel=0.05)
    for k in range(1, int(w / 6) + 1):  # mid mullions on the long faces
        lx = -w / 2 + k * w / (int(w / 6) + 1)
        for sy_ in (-1, 1):
            F.brick(lx, sy_ * (d / 2 + 0.08), zs, 0.35, 0.3, shaft, "tower_white", studs=False, bevel=0.0)
    for k in range(1, int(d / 6) + 1):
        ly = -d / 2 + k * d / (int(d / 6) + 1)
        for sx_ in (-1, 1):
            F.brick(sx_ * (w / 2 + 0.08), ly, zs, 0.3, 0.35, shaft, "tower_white", studs=False, bevel=0.0)
    zt = zs + shaft
    if crown:
        F.brick(0, 0, zt, w * 0.86, d * 0.86, 3.0, "tower_glass_dark", studs=False, bevel=0.08)
        F.brick(0, 0, zt + 1.2, w * 0.86 + 0.3, d * 0.86 + 0.3, 0.6, "glow_cyan", studs=False, bevel=0.05)
        F.brick(0, 0, zt + 3.0, w * 0.66, d * 0.66, 3.0, glass, studs=False, bevel=0.08)
        zt += 6.0
        F.brick(0, 0, zt, w * 0.7, d * 0.7, 0.5, "roof_flat", bevel=0.05)
    else:
        F.brick(0, 0, zt, w + 0.4, d + 0.4, 0.5, "roof_flat", bevel=0.05)
    zt += 0.5
    F.brick(w * 0.12, d * 0.1, zt, w * 0.3, d * 0.28, 2.2, "roof_unit", studs=False, bevel=0.1)
    ax, ay = F.p(-w * 0.15, -d * 0.12)
    m.cyl(ax, ay, 0.25, zt, zt + h * 0.12, "tower_white", segs=6)
    m.cyl(ax, ay, 0.45, zt + h * 0.12, zt + h * 0.12 + 0.8, "glow_lamp", segs=8)
    return zt


# ------------------------------------------------------------------ the harbour
def lighthouse(m, x, y, z0, h=30.0):
    """A stout lighthouse on a limestone base: white with red bands, a gallery, a glowing lantern room, a red cap."""
    m.cyl(x, y, 6.0, z0, z0 + 2.0, "rock_grey", segs=24)
    r0, r1 = 4.2, 3.0
    n = 5
    for k in range(n):
        za, zb = z0 + 2 + (h - 2) * k / n, z0 + 2 + (h - 2) * (k + 1) / n
        ra, rb = r0 + (r1 - r0) * k / n, r0 + (r1 - r0) * (k + 1) / n
        m.cone(x, y, ra, za, zb, "lighthouse_red" if k % 2 else "lighthouse_white", segs=20, r1=rb)
    zt = z0 + h
    m.cyl(x, y, 4.4, zt, zt + 0.6, "lighthouse_red", segs=24)  # the gallery
    for k in range(16):
        a = 2 * math.pi * k / 16
        m.cyl(x + math.cos(a) * 4.1, y + math.sin(a) * 4.1, 0.12, zt + 0.6, zt + 1.8, "lamp_post", segs=6)
    m.ring(3.95, 4.3, zt + 1.7, zt + 1.9, "lamp_post", cx=x, cy=y, segs=24)
    m.cyl(x, y, 2.4, zt + 0.6, zt + 3.6, "glow_beacon", segs=16)
    for k in range(6):
        a = 2 * math.pi * k / 6
        m.cyl(x + math.cos(a) * 2.45, y + math.sin(a) * 2.45, 0.14, zt + 0.6, zt + 3.6, "lamp_post", segs=6)
    m.cone(x, y, 3.2, zt + 3.6, zt + 6.0, "lighthouse_red", segs=16, r1=0.4)
    m.cyl(x, y, 0.3, zt + 6.0, zt + 7.2, "lamp_post", segs=6)
    m.brick(x, y - 4.2, z0 + 2, 1.8, 0.4, 3.2, "door_dark", studs=False, bevel=0.0)


def ferry(m, x, y, z, rot=0.0):
    """The Bay Ferry: a white hull with a blue stripe, a deck, a cabin with windows, a red funnel."""
    F = K.Frame(m, x, y, rot)
    L, W = 22.0, 8.0
    hull = [F.p(-L / 2, -W / 2), F.p(L / 2 - 4, -W / 2), F.p(L / 2, 0), F.p(L / 2 - 4, W / 2), F.p(-L / 2, W / 2)]
    m.prism(hull, z - 1.6, z + 1.0, "hull_white")
    m.prism(hull, z + 0.2, z + 0.7, "hull_blue")
    deck = [F.p(-L / 2 + 0.5, -W / 2 + 0.5), F.p(L / 2 - 4.2, -W / 2 + 0.5), F.p(L / 2 - 1, 0), F.p(L / 2 - 4.2, W / 2 - 0.5), F.p(-L / 2 + 0.5, W / 2 - 0.5)]
    m.prism(deck, z + 1.0, z + 1.2, "deck")
    F.brick(-2, 0, z + 1.2, 9, 5.6, 3.2, "hull_white", studs=False, bevel=0.15)
    for k in range(4):
        for sgn in (-1, 1):
            F.brick(-5.5 + k * 2.3, sgn * 2.85, z + 2.4, 1.4, 0.15, 1.2, "tower_glass", studs=False, bevel=0.0)
    F.brick(-2, 0, z + 4.4, 9.6, 6.2, 0.4, "hull_blue", studs=False, bevel=0.08)
    fx, fy = F.p(-4.5, 0)
    m.cyl(fx, fy, 1.1, z + 4.8, z + 7.4, "hull_red", segs=14)
    m.cyl(fx, fy, 1.2, z + 7.0, z + 7.6, "lamp_post", segs=14)
    for sgn in (-1, 1):
        F.brick(4.5, sgn * (W / 2 - 0.7), z + 1.9, 7.0, 0.12, 0.12, "tower_white", studs=False, bevel=0.0)


def pier(m, x0, y0, x1, y1, z, width=6.0):
    """A wooden pier on posts into the bay, lamp posts at its end."""
    OP.spawn_dock(m, x0, y0, x1, y1, z, width=width)


# ------------------------------------------------------------------ the monuments
def giant_briefcase(m, x, y, z0, rot=0.0, s=1.0):
    """A giant leather briefcase standing on a limestone plinth: gold corners, a clasp, a handle (the zone's emblem)."""
    F = K.Frame(m, x, y, rot)
    F.brick(0, 0, z0, 22 * s, 11 * s, 2.0, "paving_dark", studs=False, bevel=0.15)
    F.brick(0, 0, z0 + 2.0, 20 * s, 9.6 * s, 0.4, "paving", bevel=0.05)
    zb = z0 + 2.4
    W, D, H = 17 * s, 6 * s, 12 * s
    F.brick(0, 0, zb, W, D, H, "leather", studs=False, bevel=0.6)
    F.brick(0, 0, zb + H * 0.62, W + 0.2, D + 0.2, 0.5, "leather_dark", studs=False, bevel=0.1)  # the lid seam
    for sx_ in (-1, 1):
        for sz in (0, 1):
            F.brick(sx_ * (W / 2 - 0.9), 0, zb + sz * (H - 1.8), 1.9, D + 0.3, 1.8, "gold", studs=False, bevel=0.2)
    for sx_ in (-1, 1):  # the clasps
        F.brick(sx_ * 3.2 * s, -D / 2 - 0.15, zb + H * 0.55, 1.6, 0.4, 1.6, "gold", studs=False, bevel=0.15)
    hx, hy = F.p(0, 0)
    F.brick(0, 0, zb + H, 7 * s, 1.6, 0.5, "leather_dark", studs=False, bevel=0.1)
    m.ring_v(hx, hy, zb + H + 0.4, 2.4 * s, 3.6 * s, 1.4, "leather_dark", rot=rot, segs=14, gap=0.0, a0=0, a1=180)
    for sgn in (-1, 1):
        F.brick(sgn * 3.0 * s, 0, zb + H, 1.0, 1.6, 0.9, "gold", studs=False, bevel=0.1)


def giant_gavel(m, x, y, z0, rot=0.0, s=1.0):
    """A giant gavel lying across its sound block on a limestone plinth (the court's emblem)."""
    F = K.Frame(m, x, y, rot)
    F.brick(0, 0, z0, 20 * s, 12 * s, 2.0, "paving_dark", studs=False, bevel=0.15)
    F.brick(0, 0, z0 + 2.0, 18 * s, 10.6 * s, 0.4, "paving", bevel=0.05)
    zb = z0 + 2.4
    m.cyl(*F.p(4 * s, 0), 4.2 * s, zb, zb + 1.8 * s, "gavel_wood", segs=24)  # the sound block
    m.cyl(*F.p(4 * s, 0), 4.4 * s, zb + 0.6 * s, zb + 1.0 * s, "gavel_band", segs=24)
    hx, hy = F.p(4 * s, 0)
    zc = zb + 1.8 * s + 2.4 * s
    m.disc_v(hx, hy, zc, 2.4 * s, 9 * s, "gavel_wood", rot=rot, segs=20)  # the head, lying across the block
    for sgn in (-1, 1):
        bx, by = F.p(4 * s, sgn * 2.9 * s)
        m.disc_v(bx, by, zc, 2.55 * s, 0.7 * s, "gavel_band", rot=rot, segs=20)
    p0 = (*F.p(4 * s, 0), zc)
    p1 = (*F.p(-9 * s, 0), zb + 0.8 * s)
    m.beam(p0, p1, 1.3 * s, 1.3 * s, "gavel_wood")
    m.beam(p1, (*F.p(-9.8 * s, 0), zb + 0.5 * s), 1.6 * s, 1.6 * s, "gavel_band")


def welcome_sign(m, x, y, z0, rot, col, span=16.0):
    """The BRIEFCASE BAY welcome arch over the arrival path (wayfinding style: a brown wood board, white letters) on two
    limestone pillars with gold caps."""
    F = K.Frame(m, x, y, rot)
    for sgn in (-1, 1):
        F.brick(sgn * span / 2, 0, z0, 2.4, 2.4, 11.0, "rock_grey", studs=False, bevel=0.2)
        F.brick(sgn * span / 2, 0, z0 + 11.0, 2.9, 2.9, 0.8, "gold", studs=False, bevel=0.15)
        m.sphere(*F.p(sgn * span / 2, 0), z0 + 12.5, 0.9, 0.9, 0.9, "gold", seg=10, rings=6)
    F.brick(0, 0, z0 + 8.0, span + 2, 0.8, 3.4, "sign_wood", studs=False, bevel=0.12)
    F.brick(0, 0, z0 + 7.7, span + 2.6, 1.0, 0.4, "sign_wood_dark", studs=False, bevel=0.06)
    F.brick(0, 0, z0 + 11.4, span + 2.6, 1.0, 0.4, "sign_wood_dark", studs=False, bevel=0.06)
    tx, ty = F.p(0, -0.45)
    K.label3d("BRIEFCASE BAY", tx, ty, z0 + 9.7, 1.9, look="white", rot=rot, collection=col, extrude=0.12)
    tx, ty = F.p(0, 0.45)
    K.label3d("BRIEFCASE BAY", tx, ty, z0 + 9.7, 1.9, look="white", rot=rot + 180, collection=col, extrude=0.12)
