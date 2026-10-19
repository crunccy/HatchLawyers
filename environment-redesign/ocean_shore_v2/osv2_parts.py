# environment-redesign/ocean_shore_v2/osv2_parts.py - Ocean Shore v2's natural pieces (2026-10-19, crnuch's brief +
# concept image `../references/ocean_shore_concept.webp`). Classic Roblox studs, NOT LEGO: cohesive shapes from
# hl_classic.ClassicMesh, studs only on broad sand / grass / rock tops (osv2_build's stud filter); fronds, coral, shells,
# water and the portal's energy stay smooth. A natural tropical wilderness: no shops, no buildings.
import math
import random
import hl_kit as K
import hl_classic as CL

rng = random.Random(2026)

K.PAL.update({
    "sand": (240, 214, 150), "sand_light": (250, 230, 178), "sand_dark": (222, 190, 124), "wet_sand": (205, 176, 120),
    "rock_grey": (118, 120, 132), "rock_grey_dark": (86, 88, 102), "rock_grey_light": (150, 152, 162), "moss": (96, 186, 64),
    "moss_dark": (64, 150, 52), "palm_trunk": (170, 120, 70), "palm_trunk_dark": (128, 86, 48), "palm_leaf": (78, 178, 58),
    "palm_leaf_dark": (52, 140, 46), "palm_leaf_light": (128, 210, 80), "coral_pink": (250, 110, 150),
    "coral_orange": (255, 140, 70), "coral_purple": (170, 100, 220), "coral_red": (232, 72, 72), "shell": (252, 236, 220),
    "shell_pink": (250, 190, 190), "starfish": (250, 120, 60), "starfish_red": (232, 70, 60), "driftwood": (176, 150, 116),
    "driftwood_dark": (130, 108, 82), "dock_wood": (176, 112, 62), "dock_wood_dark": (128, 80, 44), "hull_wood": (110, 74, 44),
    "pebble": (180, 176, 168), "spawn_blue": (52, 110, 230), "spawn_white": (240, 246, 255), "vine": (70, 160, 60),
    "dirt_rim": (150, 104, 62), "dirt_rim_dark": (112, 76, 46),
})
K.GLASS.update({"sea": (40, 190, 220), "pool": (60, 205, 220), "pool_deep": (30, 160, 205), "foam_fall": (225, 248, 255),
                "portal_vortex": (150, 70, 255)})
K.GLOWS.update({"glow_portal": ((190, 110, 255), 3.0), "glow_lantern": ((255, 190, 90), 2.6)})

# looks that carry studs (broad terrain + structural tops); everything else stays smooth
STUD_LOOKS = {"sand", "sand_light", "sand_dark", "wet_sand", "moss", "moss_dark", "rock_grey", "rock_grey_dark",
              "rock_grey_light", "dock_wood", "dock_wood_dark", "dirt_rim", "spawn_white"}


# ------------------------------------------------------------------ rock + terrain
def rock_cluster(m, x, y, z0, size, height, grass=True, n=None, rot=None, looks=("rock_grey", "rock_grey_dark", "rock_grey_light")):
    """A natural stack of chunky faceted rock blocks (cliff / outcrop), the biggest at the bottom, grass on the tops."""
    rot = rng.uniform(0, 90) if rot is None else rot
    n = n or max(2, int(height / 5))
    z = z0
    w = size
    for k in range(n):
        h = height / n * rng.uniform(0.85, 1.15)
        top = ("moss" if k == n - 1 else rng.choice(("moss", "moss_dark", None))) if grass else None
        m.rock(x + rng.uniform(-1, 1) * size * 0.08, y + rng.uniform(-1, 1) * size * 0.08, z, w * rng.uniform(0.9, 1.1),
               w * rng.uniform(0.75, 1.0), h, rng.choice(looks), top=top if (grass and (k == n - 1 or rng.random() < 0.35)) else None,
               rot=rot + rng.uniform(-12, 12))
        # a few side chunks so the silhouette is never a plain column
        if w > 6 and rng.random() < 0.7:
            a = math.radians(rng.uniform(0, 360))
            m.rock(x + math.cos(a) * w * 0.45, y + math.sin(a) * w * 0.45, z, w * 0.45, w * 0.4, h * rng.uniform(0.5, 0.9),
                   rng.choice(looks), top="moss" if grass and rng.random() < 0.5 else None, rot=rot + rng.uniform(0, 90))
        z += h * 0.96
        w *= rng.uniform(0.72, 0.86)
    return z


def vine(m, x, y, z_top, length, yaw):
    """A hanging vine down a cliff face: a few leafy blocks on a thin strand."""
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    m.beam((x, y, z_top), (x + c * 0.2, y + s * 0.2, z_top - length), 0.25, 0.25, "vine")
    for k in range(int(length / 2.2)):
        z = z_top - 1.2 - k * 2.2
        m.brick(x + c * 0.3, y + s * 0.3, z, 0.9, 0.5, 0.9, "moss" if k % 2 else "moss_dark", rot=yaw + k * 40, bevel=0.15)


# ------------------------------------------------------------------ palms + plants
def palm(m, x, y, z0=0.0, h=None, lean=None, kind=None, fronds=None):
    """A palm in three styles (tall leaning / short bushy / twin-curve), a segmented curving trunk, a coconut cluster,
    drooping fronds in two greens."""
    kind = kind or rng.choice(("tall", "tall", "short", "curve"))
    h = h or {"tall": rng.uniform(16, 24), "short": rng.uniform(8, 12), "curve": rng.uniform(14, 19)}[kind]
    lean = rng.uniform(0, 360) if lean is None else lean
    bend = {"tall": 0.22, "short": 0.12, "curve": 0.42}[kind]
    dx, dy = math.cos(math.radians(lean)), math.sin(math.radians(lean))
    segs = max(5, int(h / 2.2))
    prev = (x, y, z0)
    r0 = 0.9 if kind != "short" else 1.1
    for k in range(1, segs + 1):
        t = k / segs
        off = bend * h * t * t
        p = (x + dx * off, y + dy * off, z0 + h * t)
        m.beam(prev, p, r0 * (1 - 0.35 * t) * 2, r0 * (1 - 0.35 * t) * 2, "palm_trunk" if k % 2 else "palm_trunk_dark", roll=k * 23)
        prev = p
    top = prev
    for k in range(3):  # coconuts
        a = math.radians(lean + 120 * k)
        m.sphere(top[0] + math.cos(a) * 0.8, top[1] + math.sin(a) * 0.8, top[2] - 0.6, 0.55, 0.55, 0.55, "palm_trunk_dark", seg=8, rings=5)
    n = fronds or (9 if kind != "short" else 11)
    for k in range(n):
        yaw = lean * 0.3 + k * 360 / n + rng.uniform(-10, 10)
        L = (h * 0.42 if kind != "short" else h * 0.6) * rng.uniform(0.85, 1.1)
        m.frond(top, yaw, L, L * 0.32, rng.uniform(0.55, 0.85), "palm_leaf" if k % 2 else "palm_leaf_dark", lift=0.3, tip="palm_leaf_light")
    return top


def tuft(m, x, y, z0, s=1.0, look=None):
    """A short tropical plant: a fan of small blades (walk-through, unstudded)."""
    look = look or rng.choice(("palm_leaf", "palm_leaf_dark", "palm_leaf_light"))
    for k in range(rng.randint(5, 8)):
        m.frond((x, y, z0), rng.uniform(0, 360), 1.8 * s * rng.uniform(0.7, 1.2), 0.55 * s, rng.uniform(0.2, 0.5), look, lift=1.1, segs=4)


def fern_bush(m, x, y, z0, s=1.0):
    for k in range(10):
        m.frond((x, y, z0 + 0.3), k * 36 + rng.uniform(-8, 8), 3.4 * s, 1.3 * s, 0.55, "palm_leaf_dark" if k % 2 else "moss", lift=0.6, segs=5)


# ------------------------------------------------------------------ coral, shells, starfish, pebbles, driftwood
def coral(m, x, y, z0, s=1.0, look=None):
    """A branching coral: a stub with forked arms and round tips (natural detail, unstudded)."""
    look = look or rng.choice(("coral_pink", "coral_orange", "coral_purple", "coral_red"))
    for k in range(rng.randint(3, 5)):
        a = math.radians(rng.uniform(0, 360))
        el = rng.uniform(0.9, 1.4) * s
        p1 = (x + math.cos(a) * 0.6 * el, y + math.sin(a) * 0.6 * el, z0 + 1.4 * el)
        m.beam((x, y, z0), p1, 0.45 * s, 0.45 * s, look)
        for j in (-1, 1):
            b = a + j * 0.6
            p2 = (p1[0] + math.cos(b) * 0.7 * el, p1[1] + math.sin(b) * 0.7 * el, p1[2] + 1.0 * el)
            m.beam(p1, p2, 0.35 * s, 0.35 * s, look)
            m.sphere(*p2, 0.32 * s, 0.32 * s, 0.32 * s, look, seg=8, rings=5)


def fan_coral(m, x, y, z0, s=1.0, look="coral_purple", rot=None):
    rot = rng.uniform(0, 180) if rot is None else rot
    m.disc_v(x, y, z0 + 1.6 * s, 1.6 * s, 0.25, look, rot=rot, segs=18)
    m.beam((x, y, z0), (x, y, z0 + 0.6 * s), 0.3, 0.3, look)


def shell(m, x, y, z0, s=1.0):
    look = rng.choice(("shell", "shell_pink"))
    m.cone(x, y, 0.45 * s, z0, z0 + 0.7 * s, look, segs=8, r1=0.0)
    m.cyl(x, y, 0.55 * s, z0, z0 + 0.12 * s, look, segs=10)


def starfish(m, x, y, z0, s=1.0):
    look = rng.choice(("starfish", "starfish_red"))
    rot = rng.uniform(0, 72)
    for k in range(5):
        a = math.radians(rot + k * 72)
        m.beam((x, y, z0 + 0.1), (x + math.cos(a) * 0.9 * s, y + math.sin(a) * 0.9 * s, z0 + 0.08), 0.42 * s, 0.16 * s, look)
    m.cyl(x, y, 0.32 * s, z0, z0 + 0.2 * s, look, segs=10)


def pebbles(m, x, y, z0, n=4):
    for k in range(n):
        s = rng.uniform(0.5, 1.2)
        m.rock(x + rng.uniform(-1.6, 1.6), y + rng.uniform(-1.6, 1.6), z0, s, s * 0.8, s * 0.6, rng.choice(("pebble", "rock_grey_light")),
               rot=rng.uniform(0, 90), jitter=0.25)


def driftwood(m, x, y, z0, L=None, rot=None):
    """A sun-bleached log lying FLAT on the sand (a stub branch, never tall)."""
    L = L or rng.uniform(6, 11)
    rot = rng.uniform(0, 180) if rot is None else rot
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    p0, p1 = (x - c * L / 2, y - s * L / 2, z0 + 0.4), (x + c * L / 2, y + s * L / 2, z0 + 0.35)
    m.beam(p0, p1, 0.9, 0.8, "driftwood", roll=rng.uniform(0, 30))
    mx, my = x + c * L * 0.15, y + s * L * 0.15
    m.beam((mx, my, z0 + 0.5), (mx - s * 1.8 + c * 0.8, my + c * 1.8 + s * 0.8, z0 + 0.3), 0.4, 0.4, "driftwood_dark")


# ------------------------------------------------------------------ landmarks (all natural or seafaring - no buildings)
def shipwreck(m, x, y, z0, rot=0.0):
    """The broken half of an old ship beached on the rocks: a tilted hull with snapped ribs, a leaning mast."""
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))

    def P(lx, ly, lz):
        return (x + lx * c - ly * s, y + lx * s + ly * c, z0 + lz)

    for k in range(7):  # hull planks (a tilted, broken half-hull)
        lz = 0.6 + k * 1.2
        half = 4.6 - abs(k - 2.5) * 0.4
        m.beam(P(-14 + k * 0.6, -half, lz), P(10 - k * 1.1, -half - 0.4, lz + 0.5), 1.0, 1.2, "hull_wood" if k % 2 else "driftwood_dark")
    for k in range(8):  # ribs, some snapped short
        lx = -12 + k * 3.0
        top = 9.5 if k % 3 else 5.0
        m.beam(P(lx, -4.4, 0.6), P(lx + 0.6, -5.4, top), 0.8, 0.8, "hull_wood")
        if k % 2 == 0:
            m.beam(P(lx, 4.4, 0.6), P(lx + 0.4, 5.6, top * 0.8), 0.8, 0.8, "hull_wood")
    m.beam(P(-6, 0, 0.6), P(-2, 1.5, 18), 1.0, 1.0, "driftwood_dark")  # the leaning mast
    m.beam(P(-3.6, 0.9, 11), P(-0.4, 4.6, 11.5), 0.5, 0.5, "driftwood_dark")  # a broken yard
    m.brick(*P(4, 0, 0)[:2], z0, 10, 7, 0.8, "dock_wood_dark", rot=rot)  # the deck stub


def rock_arch(m, x, y, z0, span=20, h=22, rot=0.0):
    """A natural sea arch: two craggy legs and a lintel of fused rock blocks, moss and a palm on top."""
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    for sgn in (-1, 1):
        lx = sgn * span / 2
        rock_cluster(m, x + lx * c, y + lx * s, z0, 9, h, grass=False, n=4, rot=rot)
    for k in range(5):
        t = (k + 0.5) / 5 - 0.5
        lx = t * (span + 6)
        sag = 1.6 * math.cos(t * math.pi)
        m.rock(x + lx * c, y + lx * s, z0 + h - 1 + sag * 0.4, 7.5, 7, 6 + sag, rng.choice(("rock_grey", "rock_grey_dark")), top="moss", rot=rot + rng.uniform(-8, 8))
    palm(m, x + 3 * c, y + 3 * s, z0 + h + 5, h=10, kind="short")


def waterfall(m, x, y, z_top, z_bot, yaw, width=8.0, look="foam_fall"):
    """A smooth curtain spilling over the island edge (falls outward along yaw), a lip and mist blocks at the top."""
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    steps = 6
    for k in range(steps):
        t0, t1 = k / steps, (k + 1) / steps
        o0, o1 = 1.0 + 6 * t0 * t0, 1.0 + 6 * t1 * t1
        za, zb = z_top - (z_top - z_bot) * t0, z_top - (z_top - z_bot) * t1
        m.beam((x + c * o0, y + s * o0, za), (x + c * o1, y + s * o1, zb), width * (1 + 0.15 * t1), 1.2, look if k % 2 else "pool")
    m.beam((x - c * 2, y - s * 2, z_top + 0.2), (x + c * 1.2, y + s * 1.2, z_top + 0.1), width, 0.6, "pool")


def spawn_dock(m, x0, y0, x1, y1, z, width=12.0):
    """The arrival boardwalk: planks across, posts with warm lanterns, rope rails, ending in the round spawn pad."""
    L = math.hypot(x1 - x0, y1 - y0)
    yaw = math.degrees(math.atan2(y1 - y0, x1 - x0))
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    n = int(L / 1.6)
    for k in range(n):
        t = (k + 0.5) / n
        px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        m.brick(px, py, z - 0.6, 1.5, width, 0.6, "dock_wood" if k % 2 else "dock_wood_dark", rot=yaw, bevel=0.08)
    for k in range(0, n + 1, 5):
        t = k / n
        px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        for sgn in (-1, 1):
            qx, qy = px - s * sgn * (width / 2 + 0.3), py + c * sgn * (width / 2 + 0.3)
            m.brick(qx, qy, z - 14, 1.0, 1.0, 17, "dock_wood_dark", rot=yaw, bevel=0.1)  # post down into the cliff / water
            if k % 10 == 0:
                m.brick(qx, qy, z + 3.0, 0.9, 0.9, 1.0, "glow_lantern", rot=yaw, bevel=0.15)


def spawn_pad(m, x, y, z):
    """The SPAWN: a round blue-and-white pad (classic Roblox spawn look) on the end of the dock."""
    m.cyl(x, y, 10.5, z - 0.6, z, "dock_wood_dark", segs=40)
    m.cyl(x, y, 9.0, z, z + 0.3, "spawn_white", segs=40)
    m.ring(6.6, 8.2, z + 0.3, z + 0.45, "spawn_blue", cx=x, cy=y, segs=40)
    m.cyl(x, y, 4.6, z + 0.3, z + 0.5, "spawn_blue", segs=32)
    m.cyl(x, y, 2.4, z + 0.5, z + 0.6, "spawn_white", segs=24)


def escape_portal(m, x, y, z, rot=0.0):
    """The ESCAPE portal: a tall ring of craggy rock blocks wrapped in glowing purple, a swirling vortex, glowing
    rune stones, flush with the sand (no stairs: the walk-in is level)."""
    m.cyl(x, y, 13, z - 0.4, z + 0.3, "rock_grey_dark", segs=40)
    m.ring(10, 12.6, z + 0.3, z + 0.45, "glow_portal", cx=x, cy=y, segs=40)
    cz = z + 13.5
    m.ring_v(x, y, cz, 9.5, 12.5, 3.2, ["rock_grey", "rock_grey_dark", "rock_grey_light"], rot=rot, segs=20, gap=0.25)
    m.ring_v(x, y, cz, 9.0, 9.6, 3.6, "glow_portal", rot=rot, segs=28, gap=0.05)
    m.disc_v(x, y, cz, 9.0, 0.6, "portal_vortex", rot=rot, segs=40)
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    for sgn in (-1, 1):  # framing boulders + glowing rune stones at its feet
        bx, by = x + c * sgn * 15, y + s * sgn * 15
        rock_cluster(m, bx, by, z, 7, 9, grass=True, n=2, rot=rot)
        m.brick(x + c * sgn * 11, y + s * sgn * 11, z + 0.3, 1.6, 1.6, 2.6, "glow_portal", rot=rot + 15, bevel=0.3)


def boss_pad(m, x, y, z):
    """Megalodon's start: a subtle ring of flat, sunken stones flush with the sand (a landmark, never a wall)."""
    for k in range(14):
        a = math.radians(k * 360 / 14 + rng.uniform(-6, 6))
        r = 12 + rng.uniform(-1, 1)
        m.rock(x + math.cos(a) * r, y + math.sin(a) * r, z - 0.3, rng.uniform(2.8, 4.2), rng.uniform(2.2, 3.2), 0.45,
               rng.choice(("rock_grey", "rock_grey_light")), rot=math.degrees(a), jitter=0.12, taper=0.05)
    m.cyl(x, y, 9, z - 0.2, z + 0.04, "wet_sand", segs=40)


def egg_marker(m, x, y, z):
    """A candidate egg spot (layout only): a flat gold ring on the sand."""
    m.ring(1.6, 2.3, z, z + 0.08, "gold", cx=x, cy=y, segs=20)


def preview_egg(m, x, y, z, look):
    """A sample egg (PREVIEW ONLY - the game spawns its own on EggSpots)."""
    m.sphere(x, y, z + 1.9, 1.5, 1.5, 1.9, look, seg=14, rings=10)
