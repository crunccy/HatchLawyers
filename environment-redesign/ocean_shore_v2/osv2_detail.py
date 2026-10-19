# environment-redesign/ocean_shore_v2/osv2_detail.py - Ocean Shore v2's DETAILED pieces (2026-10-19, after crnuch
# approved the layout). Classic Roblox studs, not LEGO: cohesive chunky shapes, studs only on broad tops (osv2_parts.
# STUD_LOOKS); palms, leaves, flowers, coral, foam, water, flames stay smooth. Natural tropical wilderness only.
#   cliff_column / moss caps + drips + vines      the concept's tall stacked grey cliffs with green caps
#   palm2 (tall / lean / curve / short / twin)      segmented trunks, leaflet fronds, coconuts, young + dead fronds
#   bush / hibiscus / grass_clump                   broadleaf bushes, flowering bushes, grass on the cliff tops
#   brain_coral / tube_coral / seaweed / conch / sand_dollar
#   foam_outline / waterfall_tall / edge_fall       foam on every shoreline, cascades with foam bands + splash
#   shipwreck2 / barrel / crate / torch / rope      the wreck with its spilled cargo, the dock's torches + rails
import math
import hl_kit as K
import osv2_parts as P

rng = P.rng

K.PAL.update({
    "rock_warm_grey": (134, 128, 128), "moss_light": (132, 212, 82), "leaf_broad": (40, 150, 70), "leaf_broad_light": (92, 192, 92),
    "leaf_dead": (176, 142, 76), "hibiscus_red": (232, 52, 70), "hibiscus_pink": (250, 120, 170), "flower_yellow": (255, 214, 60),
    "seaweed": (56, 140, 82), "sail": (240, 232, 210), "rope": (196, 170, 120), "barrel": (150, 96, 52), "barrel_band": (90, 90, 96),
    "crate": (196, 146, 84), "brain_coral": (240, 150, 100), "tube_coral": (110, 196, 220), "tube_coral_in": (60, 120, 160),
    "conch": (250, 204, 172), "conch_in": (250, 150, 150), "sand_dollar": (236, 226, 200), "torch_wood": (112, 74, 40),
    "root": (120, 82, 50),
})
K.GLOWS.update({"glow_torch": ((255, 150, 60), 3.4), "glow_ember": ((255, 220, 120), 2.6)})
K.GLASS.update({"shallows": (120, 228, 232), "foam_water": (236, 250, 255), "mist": (240, 250, 255)})
P.STUD_LOOKS |= {"moss_light", "rock_warm_grey"}
ROCKS = ("rock_grey", "rock_grey_dark", "rock_grey_light", "rock_warm_grey")


# ------------------------------------------------------------------ cliffs
def cliff_column(m, veg, x, y, z0, h, w, d, yaw, cap=True, plants=True):
    """A stack of big blocky stone (the concept's cliffs): 1-5 chunky blocks, each slightly offset + smaller, a moss cap
    with drooping moss lips, vines down the faces; plants on top. Returns the top z."""
    n = max(1, round(h / 7.5))
    z = z0
    ww, dd = w, d
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    for k in range(n):
        hk = h / n * rng.uniform(0.9, 1.1)
        ox, oy = rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6)
        m.rock(x + ox, y + oy, z, ww, dd, hk + 0.3, rng.choice(ROCKS), rot=yaw + rng.uniform(-6, 6), jitter=0.07, taper=0.05)
        if rng.random() < 0.45 and ww > 6:  # a protruding side ledge
            a = rng.choice((0, 90, 180, 270)) + yaw
            lx, ly = math.cos(math.radians(a)) * ww * 0.45, math.sin(math.radians(a)) * dd * 0.45
            m.rock(x + lx, y + ly, z, ww * 0.42, dd * 0.42, hk * rng.uniform(0.5, 0.85), rng.choice(ROCKS),
                   top="moss" if rng.random() < 0.5 else None, rot=yaw + rng.uniform(-15, 15), jitter=0.1)
        z += hk
        ww *= rng.uniform(0.84, 0.95)
        dd *= rng.uniform(0.84, 0.95)
    if cap:
        m.rock(x, y, z - 0.4, ww + 0.9, dd + 0.9, 1.3, "moss", top=rng.choice(("moss", "moss_light")), rot=yaw, jitter=0.04, taper=0.02)
        for k in range(rng.randint(3, 6)):  # moss dripping over the edges
            a = math.radians(rng.uniform(0, 360))
            ex, ey = x + math.cos(a) * (ww / 2 + 0.3), y + math.sin(a) * (dd / 2 + 0.3)
            m.brick(ex, ey, z - rng.uniform(1.4, 2.4), rng.uniform(1.0, 2.2), 0.5, rng.uniform(1.2, 2.2), "moss_dark",
                    rot=math.degrees(a) + 90, bevel=0.15)
        for k in range(rng.randint(1, 3)):
            a = math.radians(rng.uniform(0, 360))
            P.vine(m, x + math.cos(a) * (ww / 2 + 0.25), y + math.sin(a) * (dd / 2 + 0.25), z - 0.6, rng.uniform(4, min(16, h * 0.8)), math.degrees(a))
        z += 0.9
        if plants and veg is not None:
            roll = rng.random()
            if roll < 0.3 and ww > 5:
                palm2(veg, x + rng.uniform(-1, 1), y + rng.uniform(-1, 1), z, style=rng.choice(("tall", "lean", "short")))
            elif roll < 0.7:
                bush(veg, x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5), z, rng.uniform(0.8, 1.2))
            if rng.random() < 0.6:
                grass_clump(veg, x + rng.uniform(-ww / 3, ww / 3), y + rng.uniform(-dd / 3, dd / 3), z)
    return z


# ------------------------------------------------------------------ palms
def frond_leaflets(m, base, yaw, length, droop, look, look2, lift=0.32, n=12, rib="palm_trunk_dark"):
    """A palm frond: a rib that rises then droops, with a row of leaflets down each side (triangles, two greens)."""
    mi, mi2 = m._mi(look), m._mi(look2)
    cy_, sy_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def rp(t):
        dd = length * t
        return (base[0] + cy_ * dd, base[1] + sy_ * dd, base[2] + length * lift * t - droop * t * t * length)

    m.beam(base, rp(0.55), 0.22, 0.2, rib)
    m.beam(rp(0.55), rp(1.0), 0.14, 0.12, rib)
    px, py = -sy_, cy_
    for i in range(n):
        t0 = 0.1 + 0.88 * i / n
        t1 = t0 + 0.88 / n * 0.95
        a, b = rp(t0), rp(t1)
        L = length * 0.3 * math.sin(math.pi * min(1.0, 0.18 + t0 * 0.95))
        for sgn in (-1, 1):
            tip = (a[0] + px * sgn * L + cy_ * L * 0.4, a[1] + py * sgn * L + sy_ * L * 0.4, a[2] - L * 0.5)
            v = [m.bm.verts.new(a), m.bm.verts.new(b), m.bm.verts.new(tip)]
            m._face(v, mi if (i + (sgn > 0)) % 2 else mi2)


def palm2(m, x, y, z0, style=None, h=None, lean=None):
    """A palm in five styles: tall (near straight), lean, curve (a strong bow), short (bushy), twin (two trunks)."""
    style = style or rng.choice(("tall", "lean", "lean", "curve", "short", "twin"))
    lean = rng.uniform(0, 360) if lean is None else lean
    if style == "twin":
        palm2(m, x + 0.7, y, z0, "lean", (h or 18) * 1.0, lean + 22)
        palm2(m, x - 0.7, y, z0, "curve", (h or 18) * 0.82, lean - 28)
        return
    h = h or {"tall": rng.uniform(18, 25), "lean": rng.uniform(14, 20), "curve": rng.uniform(13, 18), "short": rng.uniform(7, 10)}[style]
    bend = {"tall": 0.07, "lean": 0.28, "curve": 0.5, "short": 0.12}[style]
    dx, dy = math.cos(math.radians(lean)), math.sin(math.radians(lean))
    segs = max(6, int(h / 1.7))
    r0 = 0.95 if style != "short" else 1.15
    m.beam((x, y, z0 - 0.2), (x, y, z0 + 0.9), r0 * 2.9, r0 * 2.9, "palm_trunk_dark", roll=rng.uniform(0, 45))  # root flare
    prev = (x, y, z0)
    for k in range(1, segs + 1):
        t = k / segs
        off = bend * h * (t ** (1.6 if style == "curve" else 2.0))
        p = (x + dx * off, y + dy * off, z0 + h * t)
        w = r0 * (1 - 0.32 * t) * 2
        m.beam(prev, p, w, w, "palm_trunk" if k % 2 else "palm_trunk_dark", roll=k * 19)
        m.beam(p, (p[0] + dx * 0.05, p[1] + dy * 0.05, p[2] + 0.25), w * 1.12, w * 1.12, "palm_trunk_dark", roll=k * 19 + 10)  # a ring
        prev = p
    top = prev
    for k in range(4):  # coconuts
        a = math.radians(lean + 90 * k + 20)
        m.sphere(top[0] + math.cos(a) * 0.85, top[1] + math.sin(a) * 0.85, top[2] - 0.7, 0.62, 0.62, 0.62, "palm_trunk_dark", seg=8, rings=6)
    n = 10 if style != "short" else 12
    L = (h * 0.44 if style != "short" else h * 0.7)
    for k in range(n):
        yaw = lean * 0.4 + k * 360 / n + rng.uniform(-12, 12)
        frond_leaflets(m, top, yaw, L * rng.uniform(0.85, 1.12), rng.uniform(0.55, 0.9), "palm_leaf", rng.choice(("palm_leaf_dark", "palm_leaf_light")))
    for k in range(3):  # young upright fronds in the middle
        frond_leaflets(m, (top[0], top[1], top[2] + 0.3), lean + k * 120 + 40, L * 0.55, 0.15, "palm_leaf_light", "palm_leaf", lift=1.1, n=8)
    if rng.random() < 0.6:  # a dead brown frond hanging down the trunk
        frond_leaflets(m, (top[0], top[1], top[2] - 0.4), rng.uniform(0, 360), L * 0.6, 2.0, "leaf_dead", "leaf_dead", lift=-0.2, n=8, rib="leaf_dead")
    return top


# ------------------------------------------------------------------ plants
def bush(m, x, y, z0, s=1.0, look=None):
    """A broadleaf tropical bush: three soft leaf masses + big leaves fanning out round the bottom."""
    look = look or rng.choice(("leaf_broad", "leaf_broad_light", "palm_leaf_dark"))
    for k in range(3):
        a = math.radians(k * 120 + rng.uniform(-20, 20))
        m.sphere(x + math.cos(a) * 0.9 * s, y + math.sin(a) * 0.9 * s, z0 + (1.2 + 0.3 * k) * s, 1.6 * s, 1.4 * s, 1.15 * s, look, seg=9, rings=6)
    for k in range(7):
        m.frond((x, y, z0 + 0.35), k * 51 + rng.uniform(-10, 10), 2.8 * s, 1.7 * s, 0.55, "leaf_broad" if k % 2 else "leaf_broad_light", lift=0.7, segs=4)


def hibiscus(m, x, y, z0, s=1.0):
    bush(m, x, y, z0, s, "leaf_broad")
    for k in range(rng.randint(4, 7)):
        a = math.radians(rng.uniform(0, 360))
        fx, fy, fz = x + math.cos(a) * 1.5 * s, y + math.sin(a) * 1.5 * s, z0 + rng.uniform(1.6, 2.6) * s
        col = rng.choice(("hibiscus_red", "hibiscus_pink", "flower_yellow"))
        for j in range(5):
            b = math.radians(j * 72 + rng.uniform(0, 30))
            m.beam((fx, fy, fz), (fx + math.cos(b) * 0.6 * s, fy + math.sin(b) * 0.6 * s, fz + 0.18), 0.45 * s, 0.1, col)
        m.sphere(fx, fy, fz + 0.12, 0.16 * s, 0.16 * s, 0.16 * s, "flower_yellow", seg=6, rings=4)


def grass_clump(m, x, y, z0, s=1.0):
    for k in range(rng.randint(6, 10)):
        m.frond((x + rng.uniform(-0.6, 0.6), y + rng.uniform(-0.6, 0.6), z0), rng.uniform(0, 360), 1.6 * s * rng.uniform(0.7, 1.3), 0.35 * s,
                rng.uniform(0.15, 0.4), rng.choice(("moss_light", "palm_leaf", "moss")), lift=1.3, segs=3)


# ------------------------------------------------------------------ the sea's details
def brain_coral(m, x, y, z0, r=1.6, look="brain_coral"):
    m.sphere(x, y, z0 + r * 0.45, r, r, r * 0.75, look, seg=12, rings=7)
    for k in range(3):  # grooves
        m.ring(r * (0.35 + 0.22 * k), r * (0.35 + 0.22 * k) + 0.12, z0 + r * (1.05 - 0.22 * k), z0 + r * (1.1 - 0.22 * k), "coral_red", cx=x, cy=y, segs=18)


def tube_coral(m, x, y, z0, s=1.0):
    for k in range(rng.randint(4, 7)):
        a = math.radians(rng.uniform(0, 360))
        r = rng.uniform(0.2, 1.1) * s
        h = rng.uniform(1.0, 2.6) * s
        tx, ty = x + math.cos(a) * r, y + math.sin(a) * r
        m.cyl(tx, ty, 0.34 * s, z0, z0 + h, "tube_coral", segs=10)
        m.cyl(tx, ty, 0.22 * s, z0 + h - 0.05, z0 + h + 0.02, "tube_coral_in", segs=8)


def seaweed(m, x, y, z0, h=3.0):
    p = (x, y, z0)
    for k in range(4):
        q = (p[0] + rng.uniform(-0.4, 0.4), p[1] + rng.uniform(-0.4, 0.4), p[2] + h / 4)
        m.beam(p, q, 0.5, 0.12, "seaweed", roll=rng.uniform(0, 90))
        p = q


def conch(m, x, y, z0, s=1.0, yaw=None):
    yaw = rng.uniform(0, 360) if yaw is None else yaw
    c, si = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    for k in range(4):  # a spiral of shrinking whorls
        r = (1.0 - 0.2 * k) * s
        m.sphere(x + c * k * 0.55 * s, y + si * k * 0.55 * s, z0 + 0.45 * s + k * 0.12 * s, r * 0.75, r * 0.6, r * 0.5, "conch", seg=10, rings=6)
    m.disc_v(x - c * 0.5 * s, y - si * 0.5 * s, z0 + 0.5 * s, 0.45 * s, 0.1, "conch_in", rot=yaw + 90, segs=12)


def sand_dollar(m, x, y, z0):
    m.cyl(x, y, 0.7, z0, z0 + 0.1, "sand_dollar", segs=14)
    for k in range(5):
        a = math.radians(k * 72)
        m.beam((x + math.cos(a) * 0.15, y + math.sin(a) * 0.15, z0 + 0.12), (x + math.cos(a) * 0.45, y + math.sin(a) * 0.45, z0 + 0.12), 0.12, 0.02, "shell_pink")


def foam_outline(m, pts, z, step=1.6, look="foam_water"):
    """Soft white foam along a shoreline polygon (pools, inlets): little irregular flat foam pieces, smooth."""
    n = len(pts)
    for i in range(n):
        (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
        L = math.hypot(x1 - x0, y1 - y0)
        a = math.degrees(math.atan2(y1 - y0, x1 - x0))
        k = 0.0
        while k < L:
            t = k / max(L, 1e-6)
            m.brick(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, z, rng.uniform(1.2, 2.6), rng.uniform(0.5, 1.2), 0.12, look, rot=a + rng.uniform(-15, 15), bevel=0.05)
            k += step * rng.uniform(0.7, 1.3)


def waterfall_tall(wat, foam, top, bottom_z, yaw, width=7.0, ledges=2):
    """A cascade from a cliff top (top = x, y, z on the cliff's front edge) falling toward yaw: a stream on the top,
    curtains stepping down over ledges with foam bands, a foam ring + mist + splash rocks where it lands."""
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    x, y, z = top
    wat.beam((x - c * 7, y - s * 7, z + 0.35), (x + c * 0.4, y + s * 0.4, z + 0.3), width * 0.85, 0.45, "pool")  # the stream on top
    drops = ledges + 1
    zz, off = z, 0.6
    for k in range(drops):
        z1 = z - (z - bottom_z) * (k + 1) / drops
        o1 = off + 1.2 + (z - z1) * 0.02
        wat.beam((x + c * off, y + s * off, zz + 0.3), (x + c * o1, y + s * o1, z1 + 0.2), width * (1 + 0.08 * k), 1.1, "foam_fall" if k % 2 == 0 else "pool")
        foam.beam((x + c * (off - 0.3), y + s * (off - 0.3), zz + 0.5), (x + c * (off + 0.6), y + s * (off + 0.6), zz + 0.2), width * 1.05, 0.5, "foam_water")
        if k < drops - 1:  # a little ledge the water runs over
            wat.beam((x + c * o1, y + s * o1, z1 + 0.2), (x + c * (o1 + 1.4), y + s * (o1 + 1.4), z1 + 0.1), width, 0.5, "pool")
            off = o1 + 1.4
        zz = z1
    bx, by = x + c * (off + 2.4), y + s * (off + 2.4)
    for k in range(14):  # the landing: foam + mist
        a = math.radians(rng.uniform(0, 360))
        r = rng.uniform(0.5, width * 0.7)
        foam.brick(bx + math.cos(a) * r, by + math.sin(a) * r, bottom_z + 0.25, rng.uniform(1, 2.2), rng.uniform(1, 2.2), 0.3, "foam_water", rot=rng.uniform(0, 90), bevel=0.1)
    for k in range(5):
        foam.sphere(bx + rng.uniform(-2, 2), by + rng.uniform(-2, 2), bottom_z + rng.uniform(1.5, 4), rng.uniform(1.5, 2.6), rng.uniform(1.5, 2.6), rng.uniform(1.2, 2), "mist", seg=10, rings=6)
    return (bx, by)


def edge_fall(wat, foam, x, y, z_top, z_bot, yaw, width=8.0):
    """A pool spilling over the island's edge: the curtain arcs out and down, foam at the lip, spray on the way."""
    P.waterfall(wat, x, y, z_top, z_bot, yaw, width=width)
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    foam.beam((x - c * 1.0, y - s * 1.0, z_top + 0.4), (x + c * 1.6, y + s * 1.6, z_top + 0.1), width * 1.1, 0.5, "foam_water")
    for k in range(6):
        t = rng.uniform(0.05, 0.5)
        o = 1.0 + 6 * t * t
        foam.sphere(x + c * (o + 1.5), y + s * (o + 1.5), z_top - (z_top - z_bot) * t, rng.uniform(1.0, 2.0), rng.uniform(1.0, 2.0), rng.uniform(0.8, 1.5), "mist", seg=8, rings=5)


# ------------------------------------------------------------------ the wreck, cargo, the dock's torches
def barrel(m, x, y, z0, lying=False, yaw=0.0):
    if lying:
        c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        m.beam((x - c * 1.2, y - s * 1.2, z0 + 0.9), (x + c * 1.2, y + s * 1.2, z0 + 0.9), 1.8, 1.8, "barrel", roll=22.5)
        for t in (-0.75, 0.75):
            m.beam((x + c * (t - 0.12), y + s * (t - 0.12), z0 + 0.9), (x + c * (t + 0.12), y + s * (t + 0.12), z0 + 0.9), 1.95, 1.95, "barrel_band", roll=22.5)
        return
    m.cyl(x, y, 0.95, z0, z0 + 2.4, "barrel", segs=12)
    for zz in (0.5, 1.8):
        m.cyl(x, y, 1.02, z0 + zz, z0 + zz + 0.18, "barrel_band", segs=12)


def crate(m, x, y, z0, s=1.8, yaw=0.0):
    m.brick(x, y, z0, s, s, s, "crate", rot=yaw, bevel=0.1)
    c, si = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    for sgn in (-1, 1):  # the slats
        m.brick(x - si * sgn * (s / 2 + 0.02), y + c * sgn * (s / 2 + 0.02), z0 + 0.2, s * 0.95, 0.1, 0.3, "dock_wood_dark", rot=yaw, studs=False, bevel=0.02)
        m.brick(x - si * sgn * (s / 2 + 0.02), y + c * sgn * (s / 2 + 0.02), z0 + s - 0.5, s * 0.95, 0.1, 0.3, "dock_wood_dark", rot=yaw, studs=False, bevel=0.02)


def shipwreck2(m, x, y, z0, rot=0.0):
    """A wrecked ship heeled over on the rocks: a keel, curved ribs (some snapped), hull planks with gaps, a broken
    deck, a tilted mast with a crow's nest and a torn sail, ropes, spilled barrels + crates."""
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))

    def Pt(lx, ly, lz):
        return (x + lx * c - ly * s, y + lx * s + ly * c, z0 + lz)

    heel = 0.35  # the hull lies tilted toward +ly

    m.beam(Pt(-18, 0, 0.8), Pt(16, 0.6, 1.2), 1.4, 1.4, "hull_wood")  # keel
    m.beam(Pt(16, 0.6, 1.2), Pt(19, 0.8, 6.0), 1.2, 1.2, "hull_wood")  # stem
    for k in range(10):  # ribs
        lx = -15 + k * 3.3
        snapped = k in (2, 5, 8)
        for sgn in (-1, 1):
            pts = []
            for j in range(4):
                a = j / 3
                ly = sgn * (2.0 + 4.6 * math.sin(a * math.pi / 2)) + heel * a * 6
                lz = 1.0 + 7.5 * a - (heel * 4 if sgn < 0 else -heel * 2) * a
                pts.append(Pt(lx, ly, lz))
            stop = 2 if (snapped and sgn > 0) else 3
            for j in range(stop):
                m.beam(pts[j], pts[j + 1], 0.75, 0.75, "hull_wood")
    for row in range(5):  # hull planks on the low (+) side, with gaps
        a = (row + 0.5) / 5
        ly = 2.0 + 4.6 * math.sin(a * math.pi / 2) + heel * a * 6
        lz = 1.0 + 7.5 * a + heel * 2 * a
        x0, x1 = -15 + rng.uniform(0, 4), 13 - rng.uniform(0, 6)
        if row != 2:
            m.beam(Pt(x0, ly + 0.3, lz), Pt(x1, ly + 0.3, lz + 0.2), 1.3, 0.35, "dock_wood_dark" if row % 2 else "hull_wood", roll=-20)
    for k in range(6):  # the broken deck
        lx = -10 + k * 3.4
        m.beam(Pt(lx, -3.5, 6.0 + heel * 2), Pt(lx + 0.4, 4.5, 7.5 + heel * 3), 2.6, 0.35, "dock_wood" if k % 2 else "dock_wood_dark", roll=8)
    mast_base, mast_top = Pt(-2, 0.5, 6.5), Pt(4, 9.0, 24.0)
    m.beam(mast_base, mast_top, 1.0, 1.0, "driftwood_dark")
    nest = Pt(3.0, 7.6, 21.0)
    m.cyl(nest[0], nest[1], 1.3, nest[2], nest[2] + 1.0, "hull_wood", segs=10)
    yard0, yard1 = Pt(-2.5, 4.0, 17.5), Pt(7.5, 7.0, 18.8)
    m.beam(yard0, yard1, 0.5, 0.5, "driftwood_dark")
    mi = m._mi("sail")
    vs = []  # the torn sail hanging from the yard (a cloth sheet with a ragged bottom)
    for i in range(6):
        t = i / 5
        top = (yard0[0] + (yard1[0] - yard0[0]) * t, yard0[1] + (yard1[1] - yard0[1]) * t, yard0[2] + (yard1[2] - yard0[2]) * t)
        drop = 7.0 + rng.uniform(-2.5, 1.5) if 0 < i < 5 else 4.0
        billow = 1.2 * math.sin(math.pi * t)
        bot = (top[0] + c * billow * 0.3 - s * billow, top[1] + s * billow * 0.3 + c * billow, top[2] - drop)
        vs.append((m.bm.verts.new(top), m.bm.verts.new(bot)))
    for i in range(5):
        (a, b), (cc, d) = vs[i], vs[i + 1]
        m._face((a, cc, d, b), mi)
        m._face((b, d, cc, a), mi)
    for (p0, p1) in ((mast_top, Pt(18, 0.8, 6.0)), (mast_top, Pt(-14, -2.0, 7.0)), (nest, Pt(8, -5, 1.0))):  # ropes
        mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, (p0[2] + p1[2]) / 2 - 1.2)
        m.beam(p0, mid, 0.18, 0.18, "rope")
        m.beam(mid, p1, 0.18, 0.18, "rope")
    for k, (lx, ly) in enumerate(((-20, -8), (-23, -3), (21, -6), (-17, -12), (12, -11))):  # spilled cargo on the rocks
        px, py, pz = Pt(lx, ly, 0)
        if k % 2:
            crate(m, px, py, z0, rng.uniform(1.6, 2.2), rot + rng.uniform(0, 60))
        else:
            barrel(m, px, py, z0, lying=k == 2, yaw=rot + rng.uniform(0, 180))


def torch(m, x, y, z0, h=5.0):
    """A dock torch: a wooden post, a bracket, a flame (smooth, glowing)."""
    m.brick(x, y, z0, 0.6, 0.6, h, "torch_wood", bevel=0.08)
    m.brick(x, y, z0 + h, 0.95, 0.95, 0.5, "dock_wood_dark", bevel=0.1)
    m.sphere(x, y, z0 + h + 1.0, 0.55, 0.55, 0.85, "glow_torch", seg=8, rings=6)
    m.sphere(x, y, z0 + h + 0.85, 0.3, 0.3, 0.45, "glow_ember", seg=6, rings=4)


def rope(m, p0, p1, sag=0.6):
    mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, (p0[2] + p1[2]) / 2 - sag)
    m.beam(p0, mid, 0.16, 0.16, "rope")
    m.beam(mid, p1, 0.16, 0.16, "rope")
