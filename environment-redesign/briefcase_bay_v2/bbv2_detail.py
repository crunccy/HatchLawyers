# environment-redesign/briefcase_bay_v2/bbv2_detail.py - Briefcase Bay v2's DETAILED pieces (2026-10-19, after crnuch
# approved the layout and said "keep the skyline"). Classic Roblox studs, not LEGO: cohesive smooth shapes, studs only on
# broad tops (bbv2_parts.STUD_LOOKS); glass, water, glow, leaves, flowers and papers stay smooth.
#   tower2 (slab / stepped / round / twin / pyramid / briefcase)   the skyline: six fictional firms, each its own silhouette
#   escape_portal_bb                                               the purple portal, dressed for the bay (gold trim, briefcase keystone)
#   ferry2 / sailboat / buoy / bollard / lifebuoy_stand            the harbour
#   lighthouse2 (+ keeper's cottage, the beam as its own object)   the bay's headland
#   fountain                                                       the welcome fountain by the arrival terrace
#   park_tree (oak / blossom / conifer) / topiary / flower_bed     the ring's planting
#   giant_briefcase2 / giant_gavel2                                the monuments, with stitching, a tag, papers, plaques
import math
import hl_kit as K
import hl_classic as CL
import bbv2_parts as P

OP, OD = P.OP, P.OD
rng = P.rng

K.PAL.update({
    "tower_glass_light": (150, 200, 245), "spandrel": (44, 70, 128), "helipad": (70, 74, 86), "soil": (110, 74, 44),
    "kerb": (226, 212, 184), "lifebuoy": (250, 110, 40), "conifer": (40, 120, 60), "conifer_light": (60, 146, 70),
    "cottage_wall": (246, 238, 220), "cottage_roof": (196, 64, 52), "plaque": (54, 50, 60), "tag": (250, 244, 226),
    "sail": (250, 248, 240), "mast": (150, 110, 70),
})
K.GLOWS.update({"glow_aviation": ((255, 80, 70), 3.0), "glow_heli": ((255, 226, 90), 2.4), "glow_window": ((255, 236, 170), 1.4)})
K.GLASS.update({"beam_light": (255, 246, 200), "fountain_water": (150, 225, 245)})
P.STUD_LOOKS |= {"kerb", "helipad"}


# ------------------------------------------------------------------ the skyline
def _floors(F, w, d, z0, h, glass, band=4.0, round_=False):
    """A glass shaft's floors: a white band + a dark spandrel strip per floor, corner + mid mullions, a few lighter
    'reflection' panels so the faces never read as one flat colour."""
    if round_:
        r = w / 2
        F.cyl(0, 0, r, z0, z0 + h, glass, segs=28)
        z = z0 + band
        while z < z0 + h - 0.5:
            F.cyl(0, 0, r + 0.12, z - 0.9, z - 0.25, "spandrel", segs=28)
            F.cyl(0, 0, r + 0.2, z - 0.25, z + 0.2, "tower_white", segs=28)
            z += band
        for k in range(16):
            a = 2 * math.pi * k / 16
            F.brick(math.cos(a) * (r + 0.1), math.sin(a) * (r + 0.1), z0, 0.35, 0.35, h, "tower_white", rot=math.degrees(a), bevel=0.0)
        return
    F.brick(0, 0, z0, w, d, h, glass, bevel=0.06)
    z = z0 + band
    while z < z0 + h - 0.5:
        F.brick(0, 0, z - 0.9, w + 0.16, d + 0.16, 0.65, "spandrel", bevel=0.0)
        F.brick(0, 0, z - 0.25, w + 0.3, d + 0.3, 0.45, "tower_white", bevel=0.04)
        z += band
    for sx_ in (-1, 1):
        for sy_ in (-1, 1):
            F.brick(sx_ * w / 2, sy_ * d / 2, z0, 0.7, 0.7, h, "tower_white", bevel=0.05)
    nx, ny = max(1, int(w / 5)), max(1, int(d / 5))
    for k in range(1, nx + 1):
        lx = -w / 2 + k * w / (nx + 1)
        for sy_ in (-1, 1):
            F.brick(lx, sy_ * (d / 2 + 0.1), z0, 0.32, 0.3, h, "tower_white", bevel=0.0)
    for k in range(1, ny + 1):
        ly = -d / 2 + k * d / (ny + 1)
        for sx_ in (-1, 1):
            F.brick(sx_ * (w / 2 + 0.1), ly, z0, 0.3, 0.32, h, "tower_white", bevel=0.0)
    floors = int(h / band)
    for k in range(int(h / 6)):  # reflection panels (front + side faces)
        fl = rng.randrange(0, max(1, floors - 1))
        zz = z0 + fl * band + 0.25
        if rng.random() < 0.5:
            col = rng.randrange(0, nx + 1)
            lx = -w / 2 + (col + 0.5) * w / (nx + 1)
            F.brick(lx, -(d / 2 + 0.06), zz, w / (nx + 1) - 0.5, 0.12, band - 1.4, "tower_glass_light", bevel=0.0)
        else:
            col = rng.randrange(0, ny + 1)
            ly = -d / 2 + (col + 0.5) * d / (ny + 1)
            F.brick(-(w / 2 + 0.06), ly, zz, 0.12, d / (ny + 1) - 0.5, band - 1.4, "tower_glass_light", bevel=0.0)


def _podium(F, w, d, z0, name, col):
    """A limestone podium: a white colonnade along the front, a dark glass lobby, a revolving door, a canopy, the firm's
    name in gold on a dark panel; planters + topiary on its studded roof."""
    W, D, H = w + 4, d + 4, 7.5
    F.brick(0, 0, z0, W, D, H, "tower_stone", bevel=0.15)
    F.brick(0, -D / 2 + 1.0, z0, W - 3, 0.4, H - 2.2, "door_dark", bevel=0.0)  # the lobby glass behind the colonnade
    F.brick(0, 0, z0 - 0.02, W - 1, D - 1, 0.3, "paving", bevel=0.0)
    for k in range(6):  # the colonnade
        lx = -W / 2 + 1.4 + k * (W - 2.8) / 5
        F.cyl(lx, -D / 2 - 0.4, 0.55, z0, z0 + H - 2.0, "tower_white", segs=12)
        F.brick(lx, -D / 2 - 0.4, z0, 1.5, 1.5, 0.5, "tower_white", bevel=0.08)
    F.brick(0, -D / 2 - 0.4, z0 + H - 2.2, W, 2.0, 0.6, "tower_white", bevel=0.08)  # the entablature
    F.cyl(0, -D / 2 + 0.3, 1.3, z0, z0 + 3.4, "tower_glass_light", segs=16)  # the revolving door
    F.cyl(0, -D / 2 + 0.3, 1.45, z0 + 3.4, z0 + 3.8, "tower_white", segs=16)
    F.brick(0, -D / 2 - 0.25, z0 + H - 1.55, min(W - 2, len(name) * 1.25 + 2.5), 0.4, 1.5, "plaque", bevel=0.06)
    F.text(name, 0, -D / 2 - 0.5, z0 + H - 0.8, 1.05, look="gold", extrude=0.08, collection=col)
    F.brick(0, 0, z0 + H, W + 0.4, D + 0.4, 0.4, "roof_flat", bevel=0.05)
    for sx_ in (-1, 1):  # roof planters
        F.brick(sx_ * (W / 2 - 1.6), -D / 2 + 1.6, z0 + H + 0.4, 2.2, 2.2, 0.9, "kerb", bevel=0.1)
        F.sphere(sx_ * (W / 2 - 1.6), -D / 2 + 1.6, z0 + H + 2.0, 1.1, 1.1, 1.0, "canopy", seg=10, rings=6)
    return z0 + H + 0.4


def _aerial(F, lx, ly, z, h):
    F.cyl(lx, ly, 0.22, z, z + h, "tower_white", segs=6)
    F.cyl(lx, ly, 0.4, z + h, z + h + 0.7, "glow_aviation", segs=8)


def tower2(m, x, y, z0, w, d, h, rot, style, glass, name, col):
    """A classic Roblox glass office tower on a limestone podium; each style its own silhouette. Returns the aviation
    light's world position (for the ambience)."""
    F = K.Frame(m, x, y, rot)
    zs = _podium(F, w, d, z0, name, col)
    top = z0 + h
    shaft = h - (zs - z0)
    if style == "stepped":  # three setbacks with planted terraces, a glowing crown + a spire
        z = zs
        for k, (f, part) in enumerate(((1.0, 0.5), (0.78, 0.3), (0.56, 0.2))):
            hh = shaft * part
            _floors(F, w * f, d * f, z, hh, glass)
            z += hh
            F.brick(0, 0, z, w * f + 0.4, d * f + 0.4, 0.4, "roof_flat", bevel=0.05)
            if k < 2:
                for sx_ in (-1, 1):
                    F.sphere(sx_ * w * f * 0.4, -d * f * 0.4, z + 1.2, 0.9, 0.9, 0.9, "canopy_light", seg=8, rings=5)
        F.brick(0, 0, z - 1.6, w * 0.56 + 0.3, d * 0.56 + 0.3, 0.6, "glow_cyan", bevel=0.05)
        F.cone(0, 0, 1.2, z + 0.4, z + 7, "tower_white", segs=8, r1=0.15)
        return F.p(0, 0) + (z + 7.3,)
    if style == "round":  # a glass cylinder, a dome, a gold spire
        r = w / 2
        _floors(F, w, w, zs, shaft - 4, glass, round_=True)
        zt = zs + shaft - 4
        F.cyl(0, 0, r + 0.4, zt, zt + 0.6, "tower_white", segs=28)
        F.cyl(0, 0, r - 0.2, zt + 0.6, zt + 1.2, "glow_cyan", segs=28)
        F.sphere(0, 0, zt + 1.2, r - 0.4, r - 0.4, r * 0.6, glass, seg=24, rings=12)
        F.cone(0, 0, 0.7, zt + 1.2 + r * 0.55, zt + 1.2 + r * 0.55 + 9, "gold", segs=8, r1=0.1)
        return F.p(0, 0) + (zt + r * 0.55 + 10.5,)
    if style == "twin":  # two shafts joined by a glass skybridge
        ww = w * 0.42
        for sx_ in (-1, 1):
            Fs = K.Frame(m, *F.p(sx_ * w * 0.29, 0), rot)
            hh = shaft - (0 if sx_ < 0 else 8)
            _floors(Fs, ww, d, zs, hh, glass)
            Fs.brick(0, 0, zs + hh, ww + 0.4, d + 0.4, 0.5, "roof_flat", bevel=0.05)
            Fs.brick(0, 0, zs + hh - 1.4, ww + 0.36, d + 0.36, 0.5, "glow_cyan", bevel=0.0)
        zb = zs + shaft * 0.62
        F.brick(0, 0, zb, w * 0.2, d * 0.6, 3.4, "tower_glass_light", bevel=0.05)
        F.brick(0, 0, zb - 0.4, w * 0.22, d * 0.64, 0.4, "tower_white", bevel=0.05)
        F.brick(0, 0, zb + 3.4, w * 0.22, d * 0.64, 0.4, "tower_white", bevel=0.05)
        _aerial(F, -w * 0.29, 0, zs + shaft + 0.5, 6)
        return F.p(-w * 0.29, 0) + (zs + shaft + 7,)
    if style == "pyramid":  # a glass pyramid crown with white edges + a gold finial
        _floors(F, w, d, zs, shaft - w * 0.6, glass)
        zt = zs + shaft - w * 0.6
        F.brick(0, 0, zt, w + 0.5, d + 0.5, 0.6, "tower_white", bevel=0.05)
        F.pyramid(0, 0, zt + 0.6, w, d, w * 0.6, "tower_glass_dark")
        for sx_ in (-1, 1):
            for sy_ in (-1, 1):
                p0 = (*F.p(sx_ * w / 2, sy_ * d / 2), zt + 0.6)
                p1 = (*F.p(0, 0), zt + 0.6 + w * 0.6)
                m.beam(p0, p1, 0.4, 0.4, "tower_white")
        F.cone(0, 0, 0.6, zt + w * 0.6, zt + w * 0.6 + 4, "gold", segs=8, r1=0.08)
        return F.p(0, 0) + (zt + w * 0.6 + 4.5,)
    if style == "briefcase":  # the zone's HQ: a giant gold briefcase on the roof, its seam glowing
        _floors(F, w, d, zs, shaft - 9, glass)
        zt = zs + shaft - 9
        F.brick(0, 0, zt, w + 0.4, d + 0.4, 0.5, "roof_flat", bevel=0.05)
        F.brick(0, 0, zt + 0.5, w * 0.8, d * 0.45, 6.2, "gold", bevel=0.4)
        F.brick(0, 0, zt + 4.0, w * 0.8 + 0.2, d * 0.45 + 0.2, 0.4, "glow_heli", bevel=0.05)
        hx, hy = F.p(0, 0)
        m.ring_v(hx, hy, zt + 6.6, 1.3, 2.2, 0.8, "gold_dark", rot=rot, segs=12, gap=0.0, a0=0, a1=180)
        for sx_ in (-1, 1):
            F.brick(sx_ * w * 0.25, -d * 0.225 - 0.1, zt + 3.0, 1.2, 0.3, 1.2, "gold_dark", bevel=0.1)
        return F.p(0, 0) + (zt + 9.2,)
    # "slab": an open white crown frame + a helipad on the roof
    _floors(F, w, d, zs, shaft - 5, glass)
    zt = zs + shaft - 5
    F.brick(0, 0, zt, w + 0.4, d + 0.4, 0.5, "roof_flat", bevel=0.05)
    for sx_ in (-1, 1):
        for sy_ in (-1, 1):
            F.brick(sx_ * w / 2, sy_ * d / 2, zt + 0.5, 0.7, 0.7, 4.5, "tower_white", bevel=0.05)
    for sy_ in (-1, 1):
        F.brick(0, sy_ * d / 2, zt + 4.4, w + 0.7, 0.7, 0.6, "tower_white", bevel=0.05)
    for sx_ in (-1, 1):
        F.brick(sx_ * w / 2, 0, zt + 4.4, 0.7, d + 0.7, 0.6, "tower_white", bevel=0.05)
    r = min(w, d) * 0.36
    F.cyl(0, 0, r, zt + 0.5, zt + 0.8, "helipad", segs=24)
    F.ring(r - 0.8, r - 0.4, zt + 0.8, zt + 0.86, "tower_white", segs=24)
    for lx in (-1.1, 1.1):
        F.brick(lx, 0, zt + 0.8, 0.5, 2.8, 0.05, "tower_white", bevel=0.0)
    F.brick(0, 0, zt + 0.8, 2.2, 0.5, 0.05, "tower_white", bevel=0.0)
    for k in range(8):
        a = 2 * math.pi * k / 8
        F.cyl(math.cos(a) * (r - 0.2), math.sin(a) * (r - 0.2), 0.2, zt + 0.8, zt + 1.0, "glow_heli", segs=6)
    _aerial(F, w * 0.3, d * 0.3, zt + 0.5, 7)
    return F.p(w * 0.3, d * 0.3) + (zt + 8,)


# ------------------------------------------------------------------ the escape portal, dressed for the bay
def escape_portal_bb(m, veg, x, y, z, rot=0.0):
    """The ESCAPE portal (front = local -y, toward the island's middle; Ocean Shore v2's design for the bay): a limestone
    ARCH on two buttress legs with gold trim on both faces, the purple vortex down to the ground (a level walk-in), glowing
    runes, a grass cap with flowers, a gold BRIEFCASE keystone with purple crystals, topiary + flower beds + lamps at its
    feet, a purple glow on the paving in front."""
    F = K.Frame(m, x, y, rot)
    W = lambda lx, ly: F.p(lx, ly)
    c, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    m.ring(9.5, 11.5, z + 0.02, z + 0.12, "glow_portal", cx=x, cy=y, segs=40, a0=rot + 200, a1=rot + 340)
    for k, ly in enumerate((-14.5, -18.5)):  # gold inlay bands in the paving leading in
        F.brick(0, ly, z - 0.02, 12 - k * 3, 0.5, 0.1, "gold", bevel=0.0)
    cz = z + 12.6
    A0, A1 = -38.0, 218.0
    F.ring_v(0, 0, cz, 9.8, 13.0, 3.8, ["rock_grey", "rock_grey_light", "rock_grey", "rock_grey_dark"], segs=17, gap=0.3, a0=A0, a1=A1)
    for fy in (-1.95, 1.95):  # gold trim on both faces
        F.ring_v(0, fy, cz, 12.6, 13.1, 0.15, "gold", segs=30, gap=0.0, a0=A0, a1=A1)
        F.ring_v(0, fy, cz, 9.9, 10.3, 0.15, "gold", segs=30, gap=0.0, a0=A0, a1=A1)
    F.ring_v(0, 0, cz, 9.1, 9.9, 4.2, "glow_portal", segs=30, gap=0.04, a0=A0, a1=A1)
    F.ring_v(0, 0, cz, 12.8, 13.8, 3.0, ["moss", "moss_light"], segs=10, gap=0.2, a0=50, a1=130)
    for k in range(9):
        a = math.radians(A0 + 12 + k * (A1 - A0 - 24) / 8)
        for fy in (-2.0, 2.0):
            F.brick(11.4 * math.cos(a), fy, cz + 11.4 * math.sin(a) - 0.55, 1.1, 0.3, 1.1, "glow_portal", bevel=0.1)
    F.ring_v(0, 0, cz, 0.02, 9.2, 0.5, "portal_vortex", segs=24, gap=0.0, a0=0, a1=180)
    F.brick(0, 0, z + 0.05, 2 * 9.2, 0.5, cz - z - 0.05, "portal_vortex", bevel=0.0)
    zb = cz - 9.5 * math.sin(math.radians(38))
    for sgn in (-1, 1):
        F.brick(sgn * 9.55, 0, z + 0.05, 0.7, 4.2, zb - z - 0.05, "glow_portal", bevel=0.05)
    F.disc_v(0, -0.32, cz - 0.5, 2.6, 0.2, "glow_portal", segs=24)
    for r0, a0, a1 in ((4.6, 20, 200), (6.8, 200, 380), (3.4, 110, 290)):
        F.ring_v(0, -0.36, cz - 0.5, r0, r0 + 0.45, 0.16, "glow_portal", segs=12, gap=0.05, a0=a0, a1=a1)
    for sgn in (-1, 1):  # the legs: dressed limestone buttresses with gold bands
        lx = sgn * 11.4
        F.brick(lx, 0, z, 5.6, 5.0, 6.4, "rock_grey_dark", bevel=0.3)
        F.brick(lx, 0, z + 6.4, 6.2, 5.6, 0.6, "gold", bevel=0.1)
        F.brick(lx + sgn * 0.2, 0.2, z + 7.0, 4.8, 4.6, 2.0, "rock_grey", bevel=0.25)
        F.brick(lx + sgn * 4.6, 1.0, z, 4.6, 5.4, 3.4, "rock_grey", bevel=0.3)
        F.brick(lx + sgn * 4.6, 1.0, z + 3.4, 4.9, 5.7, 0.4, "moss", bevel=0.1)
        for k in range(3):  # purple crystals at the feet
            bx, by = W(sgn * (8.2 + k * 1.3), -4.0 - k * 0.8)
            OP._shard(m, (bx, by, z + 0.05), 2.4 + k * 0.8, sgn * 0.5 * c, sgn * 0.5 * s_, 0.75, "glow_portal")
        P.lamp_post(m, *W(sgn * 15.5, -6.0), z, 7.0)
        tx_, ty_ = W(sgn * 18.5, -1.0)
        topiary(veg, tx_, ty_, z, rot)
        flower_bed(m, veg, *W(sgn * 16.5, 4.5), z, 6.0, 3.0, rot + sgn * 15)
    # the keystone: a gold briefcase on the arch's crown, purple crystals round it
    top = W(0, 0)
    F.brick(0, 0, cz + 12.7, 6.6, 2.6, 3.8, "gold", bevel=0.35)
    F.brick(0, 0, cz + 14.3, 6.8, 2.8, 0.3, "gold_dark", bevel=0.05)
    m.ring_v(*top, cz + 16.4, 0.8, 1.4, 0.6, "gold_dark", rot=rot, segs=12, gap=0.0, a0=0, a1=180)
    for sgn in (-1, 1):
        F.brick(sgn * 1.6, -1.4, cz + 14.6, 0.8, 0.3, 0.8, "gold_dark", bevel=0.08)
        bx, by = W(sgn * 4.2, 0.4)
        OP._shard(m, (bx, by, cz + 12.4), 3.2, sgn * 0.8 * c, sgn * 0.8 * s_, 0.8, "glow_portal")
    for k, a in enumerate((62, 78, 102, 118)):  # flowers trailing over the cap
        ar = math.radians(a)
        vx, vy = W(13.3 * math.cos(ar), -1.7)
        OP.vine(m, vx, vy, cz + 13.3 * math.sin(ar), 2.5 + (k % 2) * 1.5, rot - 90)
        P.flower_tuft(veg, *W(13.4 * math.cos(ar), 0), cz + 13.3 * math.sin(ar) + 0.8)


# ------------------------------------------------------------------ the harbour
def bollard(m, x, y, z):
    m.cyl(x, y, 0.55, z, z + 1.0, "lamp_post", segs=10)
    m.cyl(x, y, 0.72, z + 0.9, z + 1.2, "lamp_post", segs=10)
    m.ring(0.56, 0.72, z + 0.45, z + 0.65, "rope", cx=x, cy=y, segs=12)


def buoy(m, x, y, z):
    m.cone(x, y, 1.1, z - 0.4, z + 1.4, "lighthouse_red", segs=12, r1=0.5)
    m.cyl(x, y, 1.15, z + 0.3, z + 0.7, "lighthouse_white", segs=12)
    m.cyl(x, y, 0.15, z + 1.4, z + 2.4, "lamp_post", segs=6)
    m.sphere(x, y, z + 2.6, 0.32, 0.32, 0.32, "glow_lamp", seg=8, rings=5)


def lifebuoy_stand(m, x, y, z, rot):
    F = K.Frame(m, x, y, rot)
    F.brick(0, 0, z, 0.4, 0.4, 3.2, "lamp_post", bevel=0.05)
    F.ring_v(0, -0.35, z + 2.4, 0.55, 1.05, 0.35, ["lifebuoy", "lighthouse_white", "lifebuoy", "lighthouse_white"], segs=8, gap=0.02)


def ferry2(m, x, y, z, rot, col):
    """The Bay Ferry: a white hull with blue + red stripes, a deck with rails, a wheelhouse with windows, an upper deck
    with benches, lifebuoys, a red funnel with a black band, a flag at the stern, its name on both sides."""
    F = K.Frame(m, x, y, rot)
    L, W = 24.0, 8.6
    hull = [(-L / 2, -W / 2), (L / 2 - 5, -W / 2), (L / 2, -0.6), (L / 2, 0.6), (L / 2 - 5, W / 2), (-L / 2, W / 2)]
    F.prism(hull, z - 1.8, z + 1.2, "hull_white")
    F.prism([(px * 1.004, py * 1.02) for px, py in hull], z + 0.25, z + 0.75, "hull_blue")
    F.prism([(px * 1.004, py * 1.02) for px, py in hull], z - 0.6, z - 0.3, "hull_red")
    deck = [(px * 0.95, py * 0.88) for px, py in hull]
    F.prism(deck, z + 1.2, z + 1.4, "deck")
    for sgn in (-1, 1):  # deck rails
        F.brick(1.5, sgn * (W / 2 - 0.55), z + 2.3, L - 9, 0.14, 0.14, "tower_white", bevel=0.0)
        for k in range(8):
            F.brick(-L / 2 + 3.5 + k * 2.0, sgn * (W / 2 - 0.55), z + 1.4, 0.14, 0.14, 0.95, "tower_white", bevel=0.0)
    F.brick(-3, 0, z + 1.4, 10, 6.0, 3.2, "hull_white", bevel=0.15)  # the cabin
    for k in range(4):
        for sgn in (-1, 1):
            F.brick(-6.6 + k * 2.4, sgn * 3.05, z + 2.4, 1.6, 0.15, 1.3, "tower_glass", bevel=0.0)
    F.brick(-3, 0, z + 4.6, 10.6, 6.6, 0.4, "hull_blue", bevel=0.08)  # the upper deck
    F.brick(-0.5, 0, z + 5.0, 3.6, 4.4, 2.4, "hull_white", bevel=0.12)  # the wheelhouse
    F.brick(1.35, 0, z + 5.9, 0.12, 3.6, 1.2, "tower_glass", bevel=0.0)
    for sgn in (-1, 1):
        F.brick(-5.5, sgn * 1.6, z + 5.0, 2.6, 0.6, 0.5, "bench_wood", bevel=0.05)
        F.ring_v(-3, sgn * 3.12, z + 3.0, 0.45, 0.85, 0.3, ["lifebuoy", "lighthouse_white", "lifebuoy", "lighthouse_white"], rot=0, segs=8, gap=0.02)
    fx, fy = F.p(-6.2, 0)
    m.cyl(fx, fy, 1.1, z + 5.0, z + 8.0, "hull_red", segs=14)
    m.cyl(fx, fy, 1.18, z + 7.2, z + 7.8, "lamp_post", segs=14)
    sx, sy = F.p(-L / 2 + 0.8, 0)
    m.cyl(sx, sy, 0.12, z + 1.4, z + 6.5, "lamp_post", segs=6)
    F.brick(-L / 2 + 0.2, 0, z + 5.3, 1.6, 0.08, 1.0, "hull_blue", bevel=0.0)  # the flag
    for sgn in (-1, 1):
        tx_, ty_ = F.p(3.5, sgn * (W / 2 + 0.05))
        K.label3d("BAY FERRY", tx_, ty_, z - 0.05, 1.1, look="hull_blue", rot=rot + (0 if sgn < 0 else 180), collection=col, extrude=0.06)


def sailboat(m, x, y, z, rot):
    """A small moored sailboat: a white hull, a wooden mast, two white sails, a red stripe."""
    F = K.Frame(m, x, y, rot)
    L, W = 9.0, 3.4
    hull = [(-L / 2, -W / 2), (L / 2 - 2, -W / 2), (L / 2, 0), (L / 2 - 2, W / 2), (-L / 2, W / 2)]
    F.prism(hull, z - 0.8, z + 0.7, "hull_white")
    F.prism([(px * 1.01, py * 1.04) for px, py in hull], z + 0.1, z + 0.35, "lighthouse_red")
    F.prism([(px * 0.92, py * 0.82) for px, py in hull], z + 0.7, z + 0.82, "deck")
    mx, my = F.p(0.6, 0)
    m.cyl(mx, my, 0.16, z + 0.8, z + 11.0, "mast", segs=6)
    F.wedge(-1.5, 0, z + 1.6, 4.2, 0.08, 9.0, "sail", ridge="y")  # the mainsail
    F.wedge(2.2, 0, z + 1.2, 2.6, 0.08, 7.4, "sail", ridge="y")  # the jib
    m.beam((*F.p(-3.6, 0), z + 1.6), (mx, my, z + 1.6), 0.2, 0.2, "mast")  # the boom


# ------------------------------------------------------------------ the lighthouse
def lighthouse2(m, beam_m, x, y, z0, h, sea_deg):
    """The lighthouse on its headland: P.lighthouse + a rock base with steps, the keeper's cottage, and the beam (its own
    object, swept by the ambience). Returns the lantern's position."""
    m.cyl(x, y, 7.4, z0 - 0.4, z0 + 0.6, "rock_grey_dark", segs=24)
    P.lighthouse(m, x, y, z0 + 0.6, h)
    c, s = math.cos(math.radians(sea_deg + 140)), math.sin(math.radians(sea_deg + 140))
    hx, hy = x + c * 11.5, y + s * 11.5
    yaw = sea_deg + 140 + 90
    m.brick(hx, hy, z0 - 0.2, 8.0, 6.0, 4.4, "cottage_wall", rot=yaw, bevel=0.15)
    m.wedge(hx, hy, z0 + 4.2, 9.0, 7.0, 3.0, "cottage_roof", rot=yaw)
    F = K.Frame(m, hx, hy, yaw)
    F.brick(0, -3.05, z0 - 0.2, 1.6, 0.2, 2.8, "door_dark", bevel=0.0)
    for sgn in (-1, 1):
        F.brick(sgn * 2.6, -3.05, z0 + 1.4, 1.4, 0.2, 1.3, "tower_glass", bevel=0.0)
        F.brick(sgn * 2.6, -3.1, z0 + 1.3, 1.7, 0.2, 0.2, "lighthouse_white", bevel=0.0)
    F.brick(2.4, 1.6, z0 + 5.0, 1.0, 1.0, 2.4, "rock_grey", bevel=0.1)  # the chimney
    lz = z0 + 0.6 + h + 2.1
    a = math.radians(sea_deg)
    for w, L, look in ((1.6, 46, "beam_light"), (3.4, 38, "beam_light")):
        beam_m.beam((x, y, lz), (x + math.cos(a) * L, y + math.sin(a) * L, lz - 2.5), w, w, look)
    return (x, y, lz)


# ------------------------------------------------------------------ the welcome fountain
def fountain(m, wat, foam, x, y, z):
    """A round limestone fountain: a kerbed basin, a two-tier pedestal, a gold briefcase on top spouting four arcs of
    water into the basin. Returns the arcs' landing points (for the ambience's splashes)."""
    m.ring(9.0, 10.2, z, z + 1.4, "kerb", cx=x, cy=y, segs=40)
    m.ring(9.6, 10.6, z + 1.4, z + 1.7, "rock_grey_light", cx=x, cy=y, segs=40)
    wat.cyl(x, y, 9.1, z - 0.2, z + 1.0, "fountain_water", segs=40)
    OD.foam_outline(foam, [(x + 9.0 * math.cos(t), y + 9.0 * math.sin(t)) for t in [2 * math.pi * i / 30 for i in range(30)]], z + 1.0, step=1.5)
    m.cyl(x, y, 2.4, z, z + 3.2, "rock_grey_light", segs=20)
    m.cyl(x, y, 4.6, z + 3.2, z + 3.8, "kerb", segs=24)
    wat.cyl(x, y, 4.2, z + 3.6, z + 3.9, "fountain_water", segs=24)
    m.cyl(x, y, 1.2, z + 3.8, z + 6.4, "rock_grey_light", segs=16)
    m.brick(x, y, z + 6.4, 3.4, 1.6, 2.4, "gold", bevel=0.25)
    m.ring_v(x, y, z + 8.8, 0.45, 0.8, 0.3, "gold_dark", segs=10, gap=0.0, a0=0, a1=180)
    lands = []
    for k in range(4):
        a = math.radians(45 + k * 90)
        p0 = (x + math.cos(a) * 1.4, y + math.sin(a) * 1.4, z + 8.0)
        p1 = (x + math.cos(a) * 4.0, y + math.sin(a) * 4.0, z + 9.2)
        p2 = (x + math.cos(a) * 6.4, y + math.sin(a) * 6.4, z + 5.0)
        p3 = (x + math.cos(a) * 7.2, y + math.sin(a) * 7.2, z + 1.0)
        for q0, q1 in ((p0, p1), (p1, p2), (p2, p3)):
            wat.beam(q0, q1, 0.5, 0.5, "foam_fall")
        lands.append([round(p3[0], 1), round(p3[1], 1), z + 1.0])
    return lands


# ------------------------------------------------------------------ planting
def park_tree(m, x, y, z0, s=1.0, kind="oak"):
    """The ring's trees (classic Roblox ball trees, with more shape): oak (a flared trunk, boughs, a canopy of balls in
    three greens with a darker under-ball), blossom (pinks), conifer (stacked cones). Returns the canopy's top z."""
    if kind == "conifer":
        h = 13 * s * rng.uniform(0.9, 1.15)
        m.cone(x, y, 0.7 * s, z0, z0 + 3.2 * s, "bark", segs=8, r1=0.5 * s)
        for k in range(4):
            r = (4.2 - k * 0.9) * s
            zb = z0 + 2.4 * s + k * (h - 3) / 4
            m.cone(x, y, r, zb, zb + (h - 3) / 4 + 1.6 * s, "conifer" if k % 2 == 0 else "conifer_light", segs=10, r1=0.0)
        return z0 + h
    h = 6.5 * s * rng.uniform(0.9, 1.15)
    m.cone(x, y, 1.25 * s, z0, z0 + 1.2 * s, "bark", segs=10, r1=0.75 * s)
    m.cone(x, y, 0.75 * s, z0 + 1.2 * s, z0 + h, "bark", segs=10, r1=0.5 * s)
    for k in range(3):
        a = math.radians(k * 120 + rng.uniform(-25, 25))
        m.beam((x, y, z0 + h * 0.55), (x + math.cos(a) * 2.6 * s, y + math.sin(a) * 2.6 * s, z0 + h * 0.95), 0.5 * s, 0.5 * s, "bark")
    looks = ("blossom", "blossom_light", "flower_pink") if kind == "blossom" else ("canopy", "canopy_light", "canopy_dark")
    m.sphere(x, y, z0 + h + 1.0 * s, 4.2 * s, 4.2 * s, 2.4 * s, "canopy_dark" if kind != "blossom" else "blossom", seg=14, rings=8)
    m.sphere(x, y, z0 + h + 2.6 * s, 4.0 * s, 4.0 * s, 3.4 * s, looks[0], seg=14, rings=9)
    for k in range(rng.randint(4, 6)):
        a = math.radians(k * 360 / 5 + rng.uniform(-25, 25))
        r = rng.uniform(2.6, 3.6) * s
        m.sphere(x + math.cos(a) * r, y + math.sin(a) * r, z0 + h + rng.uniform(1.2, 3.4) * s, 2.6 * s, 2.6 * s, 2.2 * s,
                 rng.choice(looks), seg=12, rings=8)
    m.sphere(x + rng.uniform(-1, 1) * s, y + rng.uniform(-1, 1) * s, z0 + h + 5.2 * s, 2.4 * s, 2.4 * s, 2.0 * s, looks[1], seg=12, rings=8)
    return z0 + h + 7.2 * s


def topiary(m, x, y, z0, rot=0.0):
    """A clipped ball on a stem in a square limestone planter."""
    m.brick(x, y, z0, 2.4, 2.4, 1.2, "kerb", rot=rot, bevel=0.1)
    m.brick(x, y, z0 + 1.2, 2.0, 2.0, 0.1, "soil", rot=rot, bevel=0.0)
    m.cyl(x, y, 0.22, z0 + 1.2, z0 + 3.0, "bark", segs=6)
    m.sphere(x, y, z0 + 3.9, 1.5, 1.5, 1.5, "canopy", seg=12, rings=8)
    m.sphere(x, y, z0 + 5.6, 0.9, 0.9, 0.9, "canopy_light", seg=10, rings=6)


def flower_bed(m, veg, x, y, z0, sx, sy, rot):
    """A kerbed limestone flower bed with rows of flowers."""
    F = K.Frame(m, x, y, rot)
    for sgn in (-1, 1):
        F.brick(0, sgn * (sy / 2), z0, sx + 0.6, 0.6, 0.7, "kerb", bevel=0.08)
        F.brick(sgn * (sx / 2), 0, z0, 0.6, sy, 0.7, "kerb", bevel=0.08)
    F.brick(0, 0, z0, sx - 0.4, sy - 0.4, 0.55, "soil", bevel=0.0)
    look = rng.choice(("flower_blue", "flower_pink", "flower_yellow", "daisy", "hibiscus_red"))
    nx, ny = max(1, int(sx / 1.6)), max(1, int(sy / 1.6))
    for i in range(nx):
        for j in range(ny):
            px, py = F.p(-sx / 2 + (i + 0.5) * sx / nx, -sy / 2 + (j + 0.5) * sy / ny)
            P.flower_tuft(veg, px, py, z0 + 0.55, look if (i + j) % 3 else "daisy")


# ------------------------------------------------------------------ the monuments
def giant_briefcase2(m, veg, x, y, z0, rot, col):
    """P.giant_briefcase + stitching along the lid + the base, a luggage tag on the handle, papers peeking out of the
    seam, a bronze plaque on the plinth, flower beds either side."""
    P.giant_briefcase(m, x, y, z0, rot)
    F = K.Frame(m, x, y, rot)
    zb = z0 + 2.4
    W, D, H = 17, 6, 12
    for zz in (0.5, H * 0.62 + 0.75, H - 0.5):  # stitching (dashed)
        for k in range(14):
            F.brick(-W / 2 + 1.6 + k * (W - 3.2) / 13, -D / 2 - 0.05, zb + zz, 0.6, 0.12, 0.14, "paper", bevel=0.0)
    for k in range(3):  # papers peeking out of the lid seam
        F.brick(-4.5 + k * 3.6, -D / 2 - 0.2, zb + H * 0.62 + 0.1, 2.6, 0.12, 1.6, "paper", rot=rng.uniform(-14, 14), bevel=0.0)
    tx_, ty_ = F.p(3.2, -1.0)
    m.beam((*F.p(2.2, 0), zb + H + 1.6), (tx_, ty_, zb + H - 0.2), 0.12, 0.12, "lighthouse_red")
    F.brick(3.2, -1.0, zb + H - 2.6, 1.8, 0.15, 2.4, "tag", rot=8, bevel=0.05)
    F.brick(0, -5.6, z0 + 0.3, 6.0, 0.3, 1.4, "plaque", bevel=0.05)
    F.text("BRIEFCASE BAY", 0, -5.8, z0 + 1.0, 0.65, look="gold", extrude=0.05, collection=col)
    for sgn in (-1, 1):
        fx, fy = F.p(sgn * 14.5, 0)
        flower_bed(m, veg, fx, fy, z0, 5.0, 9.0, rot)


def giant_gavel2(m, veg, x, y, z0, rot, col):
    P.giant_gavel(m, x, y, z0, rot)
    F = K.Frame(m, x, y, rot)
    F.brick(0, -6.1, z0 + 0.3, 6.0, 0.3, 1.4, "plaque", bevel=0.05)
    F.text("ORDER!", 0, -6.3, z0 + 1.0, 0.75, look="gold", extrude=0.05, collection=col)
    for sgn in (-1, 1):
        fx, fy = F.p(sgn * 13.5, 0)
        flower_bed(m, veg, fx, fy, z0, 5.0, 9.0, rot)
