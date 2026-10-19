# environment-redesign/kit/hl_world.py - shared, THEMEABLE pieces every egg island uses (2026-10-18), grown out of
# Briefcase Bay's (bb_parts.py keeps its own first versions). Local frames as everywhere: front = local -y.
#   marquee / board / wood_sign             signs (attraction = black + gold + bulbs; wayfinding = wood + white)
#   arrival_pad(F, accent)                  where Travel lands players (the zone's Arrival)
#   return_portal(F, ring, glow, keystone)  RETURN HOME: the way home WITH eggs, past the boss (crnuch's decision 4);
#                                           every island's field is the same green "portal_home" (one look = home)
#   arena_floor(F, R, ...)                  an open, studded boss floor (nothing stands inside R)
#   egg(F, x, y, body, bands, deco)         a themed voxel egg;  egg_spot(F, x, y)  the gold ring an egg appears on
#   path_curve(m, I, pts, w)                a winding studded path (Catmull-Rom) with dashed edges, covered on I
import math
import hl_kit as K


def polar(r, deg):
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


# ------------------------------------------------------------------ signs
def marquee(F, x, y, z, w, h, text, size=None, rot=0.0, post_h=None, panel="black", letters="gold"):
    G = F.sub(x, y, rot)
    if post_h:
        for sgn in (-1, 1):
            G.brick(sgn * (w / 2 - 0.6), 0.4, 0, 0.8, 0.8, post_h, "metal_dark", studs=False)
    G.brick(0, 0, z, w, 0.8, h, panel, studs=False)
    for zz in (z - 0.25, z + h - 0.15):
        G.brick(0, 0, zz, w + 0.6, 1.0, 0.4, "gold", studs=False)
    n = max(3, int(w / 1.6))
    for k in range(n):
        bx = -w / 2 + 0.8 + k * (w - 1.6) / (n - 1)
        for zz in (z + 0.2, z + h - 0.65):
            G.brick(bx, -0.45, zz, 0.45, 0.3, 0.45, "glow_bulb", studs=False, bevel=0.1)
    G.text(text, 0, -0.5, z + h / 2, size or h * 0.46, letters, kind="bold", extrude=0.2)


def board(F, x, y, z, w, h, text, bg="roof_navy", fg="gold", trim="gold", size=None, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, z, w, 0.6, h, bg, studs=False)
    G.brick(0, 0, z - 0.2, w + 0.5, 0.75, 0.35, trim, studs=False)
    G.brick(0, 0, z + h - 0.15, w + 0.5, 0.75, 0.35, trim, studs=False)
    G.text(text, 0, -0.4, z + h / 2, size or h * 0.5, fg, kind="bold", extrude=0.12)


def wood_sign(F, x, y, z, w, h, text, rot=0.0, size=None):
    G = F.sub(x, y, rot)
    G.brick(0, 0.3, 0, 0.8, 0.8, z + h, "wood_dark", studs=False)
    G.brick(0, 0, z, w, 0.5, h, "wood", studs=False)
    for zz in (z - 0.2, z + h - 0.1):
        G.brick(0, 0, zz, w + 0.4, 0.7, 0.3, "wood_dark", studs=False)
    G.text(text, 0, -0.3, z + h / 2, size or h * 0.42, "white", extrude=0.08)


# ------------------------------------------------------------------ arrival + return
def arrival_pad(F, accent="roof_blue", glow="glow_cyan"):
    F.cyl(0, 0, 9.0, 0, 0.5, "stone_dark", segs=40)
    F.cyl(0, 0, 8.0, 0.5, 0.9, "marble", segs=40, studs=True)
    F.ring(6.2, 7.2, 0.9, 1.1, glow, segs=40)
    F.cyl(0, 0, 4.0, 0.9, 1.05, accent, segs=24)
    for k in range(4):
        x, y = polar(8.6, k * 90 + 45)
        F.brick(x, y, 0.5, 1.4, 1.4, 4.5, "white", studs=False)
        F.sphere(x, y, 5.6, 0.8, 0.8, 0.8, glow, seg=10, rings=6)


def return_portal(F, ring=("sign_green", "sign_green", "teal"), rim="gold", runes="glow_gold", base_glow="glow_green",
                  keystone=None, sign_text="RETURN HOME", sign_rot=20):
    F.cyl(0, 2, 20, 0, 1.4, "stone_dark", segs=48)
    F.cyl(0, 2, 18, 1.4, 3.2, "stone", segs=48, bevel=0.3)
    F.ring(17.6, 18.4, 3.2, 3.7, rim, cx=0, cy=2, segs=48)
    F.cyl(0, 2, 15, 3.2, 4.6, "marble", segs=48, studs=True)
    F.ring(14.6, 15.4, 4.6, 4.9, base_glow, cx=0, cy=2, segs=48)
    K.stairs(F, 0, -22.4, 0, 12, 6, 0.77, 1.15, 90, look="marble")
    for sgn in (-1, 1):
        F.brick(sgn * 7.0, -19.0, 0, 2.0, 7.6, 5.0, "stone")
        F.brick(sgn * 7.0, -19.0, 5.0, 2.4, 8.0, 0.5, rim, studs=False)
    cz = 4.6 + 14.2
    F.ring_v(0, 3, cz, 11.8, 14.6, 3.4, list(ring), segs=28, gap=0.18)
    F.ring_v(0, 1.1, cz, 14.4, 15.2, 0.6, rim, segs=28, gap=0.1)
    F.ring_v(0, 1.1, cz, 11.1, 11.8, 0.6, rim, segs=28, gap=0.1)
    F.disc_v(0, 3, cz, 11.8, 0.5, "portal_home", segs=40)
    for k in range(8):
        a = math.radians(k * 45 + 22.5)
        F.brick(13.2 * math.cos(a), 1.0, cz + 13.2 * math.sin(a) - 0.6, 1.2, 0.4, 1.2, runes, studs=False, bevel=0.1)
    for sgn in (-1, 1):
        F.brick(sgn * 9.0, 3, 4.6, 6, 6, 3.4, "stone_dark")
        F.brick(sgn * 9.0, 3, 8.0, 5.4, 5.4, 1.4, "stone")
    if keystone:
        keystone(F.sub(0, 3, z=cz + 13.6))
    marquee(F, -15.5, -19.5, 6.0, 12, 3.4, sign_text, size=1.25, post_h=6.0, rot=sign_rot)


# ------------------------------------------------------------------ boss floor
def arena_floor(F, R, field="stone", band="roof_blue", ring="gold", inner=28):
    """The open, studded boss floor: nothing stands inside R (the boss roams all of it)."""
    F.cyl(0, 0, R, 0, 0.4, field, segs=96, studs=True)
    F.ring(R - 8, R - 6.5, 0.4, 0.5, ring, segs=96)
    F.ring(inner, inner + 2, 0.4, 0.5, ring, segs=72)
    F.ring(inner + 2, R - 8, 0.4, 0.45, band, segs=96, studs=True)


# ------------------------------------------------------------------ eggs
def egg_profile(t, R, peak=0.4):
    if t < peak:
        u = (peak - t) / peak
        return R * math.sqrt(max(0.0, 1 - u * u))
    u = (t - peak) / (1 - peak)
    return R * math.sqrt(max(0.0, 1 - u ** 1.7))


def egg(F, x, y, s=1.0, body="eggshell", bands=None, deco=None):
    """A knee-high themed voxel egg (ZONES_REFERENCE: eggs are small and themed). bands: {ring index: look}."""
    bands = bands or {}
    K.voxel_round(F, x, y, 0, lambda t: egg_profile(t, 1.6 * s), 4.2 * s, body, step=0.35 * s, segs=14, studs=False,
                  looks=lambda k: bands.get(k, body))
    if deco:
        deco(F, x, y, s)


def egg_spot(F, x, y):
    F.ring(1.6, 2.2, 0.0, 0.12, "gold", cx=x, cy=y, segs=16)


# ------------------------------------------------------------------ winding paths
def catmull(pts, step=1.6):
    out = []
    P = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        seg = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
        n = max(2, int(seg / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * (2 * p1[j] + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 +
                                    (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in range(2)))
    out.append(pts[-1])
    return out


def path_curve(m, I, pts, w=6.0, look="path", edge="path_edge", closed=False):
    """A winding studded path through pts (smooth), white dashed edges, ground-covered on island I."""
    if closed:
        pts = list(pts) + [pts[0], pts[1]]
    curve = catmull(pts)
    for i in range(len(curve) - 1):
        (x0, y0), (x1, y1) = curve[i], curve[i + 1]
        L = math.hypot(x1 - x0, y1 - y0)
        if L < 0.05:
            continue
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        m.brick(cx, cy, 0, L + 0.9, w, 0.35, look, rot=a, studs=(i % 2 == 0))
        if i % 3 == 0:
            for sgn in (-1, 1):
                ox, oy = -math.sin(math.radians(a)) * sgn * (w / 2 + 0.2), math.cos(math.radians(a)) * sgn * (w / 2 + 0.2)
                m.brick(cx + ox, cy + oy, 0.35, 1.3, 0.45, 0.12, edge, rot=a, studs=False, bevel=0.03)
        I.cover_circle(cx, cy, w / 2 + 0.6)
    return curve
