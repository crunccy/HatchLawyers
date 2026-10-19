# environment-redesign/space_base/sb_parts.py - Space Base's models (Stage 5, island 6, 2026-10-19, mr.robe's session).
# A lunar space base under a starry night (the game's zone: Space Base, the Space egg, Chief Justice Eclipse). Palette:
# lilac-grey moon rock, white + grey hulls, deep purple / navy, with neon cyan / magenta / lime accents and gold trim.
# Local frames: front = local -y. Round things are studded VOXEL rounds (stacked rings, studs on each exposed ledge);
# only glowing bulbs, beacons and hologram parts are smooth.
# Nothing here uses the canopy looks (leaf / leaf_light / leaf_deep / blossom): there are no trees for the wind, and
# alien plants are static (their glow breathes instead).
import math
import hl_kit as K
import hl_world as W

rng = K.rng
polar = W.polar

K.PAL.update({
    "moon": (178, 170, 198), "moon_dark": (134, 126, 158), "moon_light": (208, 202, 224), "crater": (112, 106, 136),
    "rock_violet": (122, 110, 152), "rock_violet_dark": (86, 78, 114), "space_purple": (92, 62, 172), "space_navy": (32, 28, 74),
    "hull_white": (236, 238, 246), "hull_grey": (168, 174, 192), "hull_dark": (78, 84, 104), "panel_blue": (42, 82, 172),
    "rocket_red": (228, 62, 62), "alien_lime": (150, 236, 80), "alien_teal": (42, 206, 186), "alien_pink": (250, 96, 200),
    "alien_purple": (168, 84, 236), "soil_purple": (106, 70, 138), "crystal_cyan": (122, 228, 255), "crystal_pink": (255, 142, 228),
    "crystal_violet": (162, 112, 255), "space_egg": (70, 46, 150),
})
K.GLOWS.update({"glow_pink": ((255, 112, 214), 2.6), "glow_blue": ((92, 142, 255), 2.6)})
K.GLASS.update({"goo_plasma": (92, 222, 255), "goo_plasma_fall": (122, 232, 255), "portal_holo": (120, 222, 255),
                "beam_light": (190, 232, 255)})
NEONS = ("glow_cyan", "glow_magenta", "glow_lime", "glow_purple", "glow_pink", "glow_blue")


# ------------------------------------------------------------------ voxel shape helpers (same as the other islands')
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


def festoon(F, a, b, n=9, sag=1.6, looks=("glow_cyan", "glow_magenta")):
    """Light strings between two points (x, y, z): little neon bulbs along a sagging line."""
    for k in range(n + 1):
        t = k / n
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        z = a[2] + (b[2] - a[2]) * t - sag * 4 * t * (1 - t)
        F.brick(x, y, z, 0.45, 0.45, 0.55, looks[k % len(looks)], studs=False, bevel=0.12)


# ------------------------------------------------------------------ small props
def beacon_lamp(F, x, y, h=8.0, glow="glow_cyan"):
    """The island's lamp post: a grey mast with a ribbed collar, a glowing orb and a small dish."""
    F.cyl(x, y, 1.0, 0, 0.8, "hull_dark", segs=10)
    F.cyl(x, y, 0.35, 0.8, h, "hull_grey", segs=8)
    for z in (2.0, 4.0):
        F.cyl(x, y, 0.5, z, z + 0.3, "hull_dark", segs=8)
    F.cyl(x, y, 0.7, h, h + 0.3, "hull_white", segs=10)
    F.sphere(x, y, h + 1.0, 0.7, 0.7, 0.7, glow, seg=10, rings=6)


def crater(F, x, y, R=6.0):
    """A shallow crater: a darker floor inside a raised, studded rim."""
    F.cyl(x, y, R, 0.0, 0.12, "crater", segs=28)
    F.ring(R, R + 1.6, 0.0, 0.7, "moon_light", cx=x, cy=y, segs=28, studs=True)
    F.ring(R + 1.6, R + 2.6, 0.0, 0.35, "moon", cx=x, cy=y, segs=28)


def moon_rocks(F, x, y, s=1.0):
    K.rocks(F, x, y, s, look=rng.choice(("moon_dark", "rock_violet")))


def meteorite(F, x, y, s=1.0):
    """A dark meteorite sitting in a little crater, glowing cracks."""
    crater(F, x, y, 3.0 * s)
    ball(F, x, y, 0, 1.9 * s, "rock_violet_dark", step=0.45 * s, studs=False)
    for k in range(4):
        a = k * 90 + 20
        px, py = polar(1.7 * s, a)
        F.brick(x + px, y + py, 1.0 * s, 0.25 * s, 1.2 * s, 1.4 * s, "glow_magenta", rot=a, studs=False, bevel=0.05)


def flag(F, x, y, look="glow_cyan"):
    """A planted base flag: a white pole and a stepped navy flag with a neon star."""
    F.cyl(x, y, 0.2, 0, 7.5, "hull_white", segs=6)
    F.brick(x + 1.6, y, 5.0, 3.0, 0.15, 2.2, "space_navy", studs=False, bevel=0.02)
    F.brick(x + 1.6, y - 0.1, 5.7, 0.8, 0.12, 0.8, look, rot=45, studs=False, bevel=0.02)


def rover(F, x, y, rot=0.0):
    """A little moon rover: a white body, six chunky wheels, a solar panel, a camera mast, a neon headlight."""
    G = F.sub(x, y, rot)
    for sx in (-1, 1):
        for ly in (-2.2, 0, 2.2):
            G.disc_v(sx * 2.2, ly, 0.9, 0.9, 0.7, "hull_dark", rot=90, segs=12)
    G.brick(0, 0, 1.0, 3.6, 6.0, 1.4, "hull_white")
    G.brick(0, 0.6, 2.4, 3.2, 3.4, 0.2, "panel_blue", studs=False)
    G.brick(0, -2.4, 2.4, 0.4, 0.4, 2.6, "hull_grey", studs=False)
    G.brick(0, -2.4, 5.0, 1.0, 0.8, 0.7, "hull_white", studs=False)
    G.brick(0, -3.05, 1.5, 1.4, 0.2, 0.5, "glow_cyan", studs=False)


def alien_mushroom(F, x, y, s=1.0, cap="alien_pink", glow="glow_pink"):
    F.cyl(x, y, 0.6 * s, 0, 3.4 * s, "moon_light", segs=10)
    dome(F, x, y, 3.2 * s, 2.4 * s, 1.8 * s, cap, step=0.45 * s, segs=16)
    for k in range(5):
        px, py = polar(1.5 * s, k * 72 + 10)
        F.sphere(x + px, y + py, 3.2 * s + 1.0 * s, 0.32 * s, 0.32 * s, 0.32 * s, glow, seg=8, rings=5)


def tentacle_plant(F, x, y, s=1.0, look="alien_teal", glow="glow_lime"):
    """Curling tentacle fronds (offset studless blocks) with glowing tips."""
    F.cyl(x, y, 1.2 * s, 0, 0.8 * s, "soil_purple", segs=10)
    for k in range(5):
        a = k * 72 + rng.uniform(-12, 12)
        px, py = x, y
        for j in range(5):
            dx, dy = polar((0.6 + j * 0.35) * s, a)
            px, py = px + dx * 0.55, py + dy * 0.55
            F.brick(px, py, (0.8 + j * 0.9) * s, 0.6 * s, 0.6 * s, 1.0 * s, look, rot=a, studs=False, bevel=0.12)
        F.sphere(px, py, (0.8 + 5 * 0.9) * s + 0.2 * s, 0.4 * s, 0.4 * s, 0.4 * s, glow, seg=8, rings=5)


def bulb_plant(F, x, y, s=1.0, glow="glow_cyan"):
    for k in range(3):
        px, py = polar(rng.uniform(0.2, 1.2) * s, k * 120 + rng.uniform(0, 40))
        h = rng.uniform(2.6, 4.6) * s
        F.brick(x + px, y + py, 0, 0.35 * s, 0.35 * s, h, "alien_lime", studs=False, bevel=0.05)
        F.sphere(x + px, y + py, h + 0.5 * s, 0.6 * s, 0.6 * s, 0.6 * s, glow, seg=10, rings=6)


def spike_plant(F, x, y, s=1.0):
    taper(F, x, y, 0, 1.4 * s, 0.3 * s, 4.0 * s, "alien_purple", step=0.5 * s, segs=8, studs=False)
    for k in range(6):
        a = k * 60
        px, py = polar(1.0 * s, a)
        F.brick(x + px, y + py, (1.0 + (k % 3) * 0.8) * s, 1.4 * s, 0.25 * s, 0.25 * s, "alien_pink", rot=a, studs=False, bevel=0.03)


def crystal(F, x, y, h=6.0, r=1.0, look="crystal_cyan", core="glow_cyan"):
    """One studded crystal: a six-sided column narrowing to a point, a glowing core showing at its base."""
    n = max(3, int(h / 0.8))
    for k in range(n):
        t = k / n
        rr = r * (1.0 if t < 0.7 else (1 - (t - 0.7) / 0.3 * 0.85))
        F.cyl(x, y, rr, k * h / n, (k + 1) * h / n, look, segs=6)
    F.cyl(x, y, r * 0.55, 0.0, h * 0.35, core, segs=6)


def crystal_cluster(F, x, y, s=1.0, looks=("crystal_cyan", "glow_cyan")):
    crystal(F, x, y, 7.0 * s, 1.2 * s, *looks)
    for k in range(5):
        px, py = polar(rng.uniform(1.6, 2.6) * s, k * 72 + rng.uniform(-20, 20))
        crystal(F, x + px, y + py, rng.uniform(2.4, 4.6) * s, rng.uniform(0.5, 0.8) * s, *looks)


def telescope(F, x, y, rot=0.0):
    """A tripod telescope: three legs, a white tube pointing up and out (stepped blocks), an eyepiece."""
    G = F.sub(x, y, rot)
    for k in range(3):
        px, py = polar(1.4, k * 120 + 90)
        G.brick(px, py, 0, 0.3, 0.3, 3.4, "hull_dark", studs=False)
    G.brick(0, 0, 3.2, 0.8, 0.8, 0.6, "hull_dark", studs=False)
    for k in range(4):  # the tube climbing away from the viewer
        G.brick(0, 0.7 * k, 3.6 + 0.7 * k, 1.2, 1.4, 1.0, "hull_white" if k < 3 else "gold", studs=False, bevel=0.1)
    G.brick(0, -0.9, 3.5, 0.5, 0.6, 0.5, "space_navy", studs=False)


def star_chart(F, x, y, rot=0.0):
    """A wayfinding-style board showing a constellation in neon dots."""
    G = F.sub(x, y, rot)
    G.brick(0, 0.3, 0, 0.6, 0.6, 5.4, "hull_grey", studs=False)
    G.brick(0, 0, 2.6, 4.6, 0.3, 3.0, "space_navy", studs=False)
    pts = ((-1.6, 3.2), (-0.6, 4.4), (0.4, 3.8), (1.5, 4.9), (1.2, 3.0))
    for (px, pz) in pts:
        G.brick(px, -0.2, pz, 0.3, 0.12, 0.3, "glow_white", studs=False, bevel=0.0)
    for (a, b) in zip(pts, pts[1:]):
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        G.brick(mx, -0.18, mz, math.hypot(b[0] - a[0], b[1] - a[1]) * 0.8, 0.08, 0.06, "gold", studs=False, bevel=0.0)


def space_egg_deco(F, x, y, s):
    """Little neon stars on the egg's shell."""
    for k in range(7):
        a = k * 51 + 13
        px, py = polar(1.5 * s, a)
        F.brick(x + px, y + py, (1.0 + (k % 4) * 0.7) * s, 0.22 * s, 0.22 * s, 0.22 * s, "glow_white", rot=a, studs=False, bevel=0.03)


def space_egg(F, x, y, golden=False):
    """The Space egg: deep purple with a gold planet-ring band and neon stars (golden variant)."""
    W.egg(F, x, y, 1.0, body="gold" if golden else "space_egg",
          bands={4: "gold", 5: "glow_cyan", 9: "space_purple"} if not golden else {4: "glow_gold"}, deco=space_egg_deco)


def planet_keystone(F):
    """A little ringed planet on top (the RETURN HOME ring's keystone)."""
    ball(F, 0, 0, -0.4, 2.0, "space_purple", step=0.45, studs=False, looks=lambda k: "space_purple" if k % 3 else "alien_pink")
    F.ring(2.4, 3.4, 1.5, 1.75, "gold", segs=24)


# ------------------------------------------------------------------ gate + plaza
def airlock_gate(F, width=26):
    """Two chunky white pylons with hazard-striped feet and neon strips, a beam with a SPACE BASE marquee, the airlock
    doors slid open into the pylons, red beacons and an antenna on top."""
    for sx in (-1, 1):
        x = sx * (width / 2 + 3.0)
        F.brick(x, 0, 0, 6.0, 6.0, 1.2, "hull_dark")
        for k in range(4):
            F.brick(x, 0, 1.2 + k * 0.8, 5.4, 5.4, 0.8, "hazard" if k % 2 == 0 else "black", studs=False)
        F.brick(x, 0, 4.4, 5.0, 5.0, 12.0, "hull_white")
        F.brick(x - sx * 2.55, 0, 5.4, 0.2, 2.0, 10.0, "glow_cyan", studs=False)
        F.brick(x, -2.55, 6.0, 1.0, 0.2, 8.0, "glow_magenta", studs=False)
        F.brick(x - sx * 3.6, 0, 1.2, 2.2, 1.6, 14.0, "hull_grey", studs=False)  # the open door slab, slid aside
        F.sphere(x, 0, 17.2, 0.9, 0.9, 0.9, "glow_red", seg=10, rings=6)
    F.brick(0, 0, 16.4, width + 12, 4.0, 2.4, "hull_white")
    F.brick(0, -2.05, 16.8, width + 10, 0.2, 0.5, "glow_cyan", studs=False)
    W.marquee(F, 0, -2.4, 11.6, width - 4, 3.6, "SPACE BASE", size=1.6, panel="space_navy", letters="gold")
    for sx in (-1, 1):
        F.brick(sx * (width / 2 - 4), -2.4, 15.2, 0.25, 0.25, 1.2, "hull_grey", studs=False, bevel=0.0)
    F.cyl(0, 0, 0.25, 18.8, 24.0, "hull_grey", segs=6)
    F.sphere(0, 0, 24.4, 0.5, 0.5, 0.5, "glow_red", seg=8, rings=5)


def hologram_fountain(F):
    """Mission control's centrepiece: a stepped white pedestal with neon rings, a projector, a faint light column and a
    floating hologram planet (built as its own turning object in sb_build: Spin_HoloPlanet)."""
    F.cyl(0, 0, 11, 0, 1.2, "hull_grey", segs=40, studs=True)
    F.ring(10.2, 11.2, 1.2, 1.5, "glow_cyan", segs=40)
    F.cyl(0, 0, 8, 1.2, 2.6, "hull_white", segs=36, studs=True)
    F.ring(7.4, 8.1, 2.6, 2.85, "glow_magenta", segs=36)
    F.cyl(0, 0, 4.6, 2.6, 4.0, "space_navy", segs=24)
    F.cyl(0, 0, 3.2, 4.0, 4.3, "glow_cyan", segs=24)
    F.cyl(0, 0, 2.8, 4.3, 16.0, "beam_light", segs=16)
    for k in range(6):  # little console desks round the pedestal
        x, y = polar(9.5, k * 60 + 30)
        F.brick(x, y, 1.2, 2.2, 1.2, 1.4, "hull_dark", rot=k * 60 + 30 + 90, studs=False)
        F.brick(x, y, 2.6, 2.0, 1.0, 0.15, NEONS[k % len(NEONS)], rot=k * 60 + 30 + 90, studs=False)


def holo_planet(F):
    """The hologram (see-through, glowing): a planet with bands, a flat ring and two small moons; it turns."""
    ball(F, 0, 0, -4.2, 4.2, "portal_holo", step=0.6, studs=False)
    F.ring(5.6, 7.4, -0.1, 0.1, "portal_holo", segs=40)
    for a in (40, 220):
        px, py = polar(9.5, a)
        F.sphere(px, py, 0.6, 0.8, 0.8, 0.8, "glow_cyan", seg=10, rings=6)


def space_module(F, name, color, prop=None):
    """A plaza kiosk facing local -y: a rounded white pod (stepped dome roof), a coloured band, a wide counter opening,
    neon strips, a sign on the roof edge, an antenna, and a prop on top (prop)."""
    F.brick(0, 0, 0, 12, 9, 0.6, "hull_grey")
    F.brick(0, 0.8, 0.6, 11, 7, 7.4, "hull_white", studs=False)
    F.brick(0, -2.8, 0.6, 9, 1.6, 3.4, color, studs=False)
    F.brick(0, -2.8, 4.0, 9.6, 2.2, 0.4, "hull_grey")
    F.brick(0, -2.75, 4.4, 8.0, 0.2, 2.8, "space_navy", studs=False)  # the dark window behind the counter
    F.brick(0, -2.75, 7.4, 11.2, 1.8, 0.6, color, studs=False)
    for sx in (-1, 1):
        F.brick(sx * 5.55, -2.8, 0.8, 0.2, 0.4, 6.4, "glow_cyan", studs=False)
    dome(F, 0, 0.8, 8.0, 5.2, 3.2, "hull_white", step=0.5, segs=20)
    W.board(F, 0, -3.95, 8.1, 9, 2.0, name, bg=color, fg="white", trim="hull_white", size=0.9)
    F.cyl(3.6, 2.2, 0.15, 10.0, 13.4, "hull_grey", segs=6)
    F.sphere(3.6, 2.2, 13.6, 0.35, 0.35, 0.35, "glow_red", seg=8, rings=5)
    for k in range(3):
        F.cyl(-3 + k * 3, -2.8, 0.5, 4.4, 5.2, ("alien_pink", "hull_white", "crystal_cyan")[k], segs=10)
    if prop:
        prop(F.sub(0, 0.8, z=11.2))


# ------------------------------------------------------------------ landmarks + buildings
def rocket(F):
    """The landmark: an octagon launch pad with hazard rings, a red-and-white rocket (stacked bands, portholes, fins,
    a stepped nose cone, engine bells) and a lattice gantry with two arms (exhaust steam in the ambience)."""
    F.cyl(0, 0, 14, 0, 1.2, "hull_dark", segs=8, studs=True)
    F.ring(12.6, 13.6, 1.2, 1.35, "hazard", segs=8)
    F.cyl(0, 0, 9, 1.2, 2.0, "hull_grey", segs=24, studs=True)
    for k in range(4):  # engine bells hanging under the body
        px, py = polar(1.9, k * 90 + 45)
        taper(F, px, py, 2.0, 1.2, 0.7, 2.4, "hull_dark", step=0.4, segs=12, studs=False)
    for k in range(9):  # the body: bands
        F.cyl(0, 0, 3.6, 4.4 + k * 3.0, 7.4 + k * 3.0, "rocket_red" if k in (0, 4, 8) else "hull_white", segs=24)
    for z in (15.0, 26.0):  # portholes on four sides
        for a in (0, 90, 180, 270):
            px, py = polar(3.65, a)
            F.disc_v(px, py, z, 0.8, 0.2, "glass_dark", rot=a + 90, segs=12)
            F.ring_v(px, py, z, 0.8, 1.05, 0.25, "hull_grey", rot=a + 90, segs=10, gap=0.02)
    taper(F, 0, 0, 31.4, 3.6, 0.4, 7.0, "rocket_red", step=0.7, segs=24, looks=lambda k: "rocket_red" if k < 7 else "hull_white")
    for a in (45, 135, 225, 315):  # fins
        px, py = polar(4.6, a)
        F.brick(px, py, 4.4, 2.4, 0.5, 5.0, "rocket_red", rot=a, studs=False)
        qx, qy = polar(5.4, a)
        F.brick(qx, qy, 4.4, 1.0, 0.5, 2.6, "rocket_red", rot=a, studs=False)
    G = F.sub(10, 0)  # the gantry: four posts, cross braces every 4 studs, two arms to the rocket
    for sx in (-1.8, 1.8):
        for sy in (-1.8, 1.8):
            G.brick(sx, sy, 1.2, 0.6, 0.6, 36.0, "hull_grey", studs=False)
    for k in range(9):
        z = 3.0 + k * 4.0
        G.brick(0, -1.8, z, 4.2, 0.4, 0.4, "rocket_red", studs=False)
        G.brick(0, 1.8, z, 4.2, 0.4, 0.4, "rocket_red", studs=False)
        G.brick(-1.8, 0, z, 0.4, 4.2, 0.4, "rocket_red", studs=False)
        G.brick(1.8, 0, z, 0.4, 4.2, 0.4, "rocket_red", studs=False)
    for z in (14.0, 26.0):
        G.brick(-4.0, 0, z, 4.6, 1.4, 0.8, "hull_grey", studs=False)
    G.brick(0, 0, 37.2, 4.6, 4.6, 0.6, "hull_dark")
    G.sphere(0, 0, 38.4, 0.6, 0.6, 0.6, "glow_red", seg=8, rings=5)


def observatory(F):
    """A round white observatory with a gold band and a door; its dome (with the telescope slit) turns slowly: the dome
    is built in sb_build as Spin_ObservatoryDome on top of this drum (drum top z 9.8)."""
    F.cyl(0, 0, 12, 0, 0.8, "hull_grey", segs=36, studs=True)
    F.cyl(0, 0, 10, 0.8, 9.0, "hull_white", segs=36)
    F.cyl(0, 0, 10.15, 7.6, 8.4, "gold", segs=36)
    F.cyl(0, 0, 10.4, 9.0, 9.8, "hull_grey", segs=36, studs=True)
    F.brick(0, -10.0, 0.8, 3.2, 0.6, 5.6, "space_navy", studs=False)
    F.brick(0, -10.25, 6.4, 4.2, 0.8, 0.6, "hull_grey", studs=False)
    W.board(F, 0, -10.6, 6.9, 12, 2.2, "OBSERVATORY", bg="space_navy", fg="gold", trim="gold", size=1.1)


def observatory_dome(F):
    """The turning dome: a studded white dome with a dark slit and a telescope poking out of it."""
    dome(F, 0, 0, 0, 10.0, 8.0, "hull_white", step=0.8, segs=32)
    for k in range(8):  # the slit: dark blocks up the -y side
        F.brick(0, -9.2 + k * 1.15, 0.2 + k * 1.0, 2.2, 1.2, 1.2, "space_navy", studs=False, bevel=0.05)
    for k in range(4):
        F.brick(0, -6.0 - k * 1.1, 5.0 + k * 1.0, 1.6, 1.6, 1.2, "hull_grey" if k < 3 else "gold", studs=False, bevel=0.1)


def habitat_domes(F):
    """Three glass habitat domes on studded rings, joined by white tubes, little alien gardens inside."""
    spots = ((0, 0, 9.0), (-15, -8, 6.5), (14, -9, 6.0))
    for (x, y, r) in spots:
        F.cyl(x, y, r + 1.0, 0, 1.2, "hull_white", segs=32, studs=True)
        F.ring(r + 0.2, r + 1.0, 1.2, 1.5, "glow_cyan", cx=x, cy=y, segs=32)
        F.cyl(x, y, r * 0.6, 1.2, 1.6, "soil_purple", segs=20)
        bulb_plant(F.sub(x, y, z=1.6), 0, 0, 0.8, "glow_lime")
        dome(F, x, y, 1.2, r, r * 0.85, "glass", step=0.6, segs=28, studs=False)
    for (a, b) in ((0, 1), (0, 2)):
        (x0, y0, r0), (x1, y1, r1) = spots[a], spots[b]
        L = math.hypot(x1 - x0, y1 - y0) - r0 - r1
        ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
        ux, uy = (x1 - x0) / math.hypot(x1 - x0, y1 - y0), (y1 - y0) / math.hypot(x1 - x0, y1 - y0)
        mx, my = x0 + ux * (r0 + L / 2), y0 + uy * (r0 + L / 2)
        F.brick(mx, my, 1.2, L + 1.0, 2.6, 2.6, "hull_white", rot=ang)
        F.brick(mx, my, 2.0, L + 1.2, 2.7, 0.3, "glow_cyan", rot=ang, studs=False)
    W.board(F, 0, -10.4, 1.4, 10, 2.0, "HABITAT", bg="space_purple", fg="white", trim="hull_white", size=1.0)


def robot_factory(F):
    """A boxy grey factory with a hazard-striped door, neon windows, two vent stacks with glowing caps and a radar on
    the roof (the radar turns: built in sb_build as Spin_Radar)."""
    F.brick(0, 0, 0, 30, 24, 0.8, "hull_dark")
    F.brick(0, 2, 0.8, 26, 18, 11, "hull_grey", studs=False)
    F.brick(0, 2, 11.8, 27, 19, 0.8, "hull_white")
    for k in range(5):
        F.brick(-10 + k * 5, -7.05, 6.0, 3.0, 0.2, 2.4, "glow_cyan", studs=False)
    F.brick(0, -7.1, 0.8, 8, 0.3, 6.0, "hull_dark", studs=False)
    for k in range(6):
        F.brick(-3.5 + k * 1.4, -7.3, 6.8, 1.4, 0.3, 0.8, "hazard" if k % 2 == 0 else "black", studs=False)
    for sx in (-8, 8):
        F.cyl(sx, 6, 2.0, 12.6, 19.0, "hull_dark", segs=16)
        F.cyl(sx, 6, 2.2, 19.0, 19.6, "glow_magenta", segs=16)
    W.board(F, 0, -7.6, 8.4, 16, 2.4, "ROBOT FACTORY", bg="space_navy", fg="white", trim="hull_white", size=1.2)


def radar(F):
    """The roof radar: a mast and a curved dish (stepped blocks), a neon tip."""
    F.cyl(0, 0, 0.5, 0, 3.0, "hull_grey", segs=8)
    for k in range(5):
        F.brick(0, -0.2 - abs(k - 2) * 0.4, 3.4 + k * 0.7, 5.0 - abs(k - 2) * 1.0, 0.4, 0.7, "hull_white", studs=False)
    F.sphere(0, -1.6, 4.8, 0.3, 0.3, 0.3, "glow_red", seg=8, rings=5)


def solar_farm(F, cols=4, rows=3):
    """Rows of solar panels on posts (blue cells in a grey frame), a little control box."""
    for i in range(cols):
        for j in range(rows):
            x, y = (i - (cols - 1) / 2) * 7.0, (j - (rows - 1) / 2) * 6.0
            F.brick(x, y, 0, 0.5, 0.5, 2.2, "hull_grey", studs=False)
            F.brick(x, y, 2.2, 6.2, 4.4, 0.25, "hull_grey", studs=False)
            for ci in range(3):
                for cj in range(2):
                    F.brick(x - 2.0 + ci * 2.0, y - 1.0 + cj * 2.0, 2.45, 1.8, 1.8, 0.1, "panel_blue", studs=False, bevel=0.0)
    F.brick((cols / 2) * 7.0 + 1.5, 0, 0, 2.4, 2.0, 2.4, "hull_white")
    F.brick((cols / 2) * 7.0 + 1.5, -1.05, 1.4, 1.2, 0.1, 0.4, "glow_lime", studs=False)


def sat_dish(F):
    """The big satellite dish (built as its own turning object, Spin_SatDish): a stepped bowl facing up and out on a
    tilting yoke, a feed arm with a glowing tip."""
    F.cyl(0, 0, 1.6, 0, 1.4, "hull_grey", segs=16)
    F.brick(0, 0, 1.4, 1.6, 1.6, 4.0, "hull_white", studs=False)
    for k in range(5):  # the bowl, stepped, tipped toward -y
        r = 3.0 + k * 1.2
        F.cyl(0, -k * 0.5, r, 5.4 + k * 0.8, 6.2 + k * 0.8, "hull_white" if k % 2 == 0 else "moon_light", segs=24)
    F.brick(0, -2.0, 8.6, 0.4, 0.4, 5.0, "hull_grey", studs=False)
    F.sphere(0, -2.0, 13.8, 0.6, 0.6, 0.6, "glow_cyan", seg=10, rings=6)


def fuel_depot(F):
    """Two big round tanks on legs, pipes between them, hazard bands and a sign."""
    for sx in (-7, 7):
        for k in range(4):
            px, py = polar(3.4, k * 90 + 45)
            F.brick(sx + px, py, 0, 0.6, 0.6, 4.0, "hull_dark", studs=False)
        ball(F, sx, 0, 3.6, 5.0, "hull_white", step=0.6, looks=lambda k: "hazard" if k == 8 else "hull_white")
    F.brick(0, 0, 7.6, 6.0, 0.9, 0.9, "hull_grey", studs=False)
    F.brick(0, 0, 4.0, 6.0, 0.9, 0.9, "hull_grey", studs=False)
    W.board(F, 0, -5.6, 1.0, 10, 2.0, "FUEL DEPOT", bg="hazard", fg="black", trim="hull_dark", size=1.0)


def ufo(F):
    """A parked flying saucer (fictional) on a landing ring: a wide grey disc, a glass dome, a neon rim, landing legs."""
    F.cyl(0, 0, 13, 0, 0.6, "hull_dark", segs=40, studs=True)
    F.ring(11.6, 12.6, 0.6, 0.75, "glow_lime", segs=40)
    for k in range(4):
        px, py = polar(6.0, k * 90 + 45)
        F.brick(px, py, 0.6, 0.6, 0.6, 3.0, "hull_grey", studs=False)
        F.cyl(px, py, 0.8, 0.6, 0.9, "hull_grey", segs=10)
    F.cyl(0, 0, 9.0, 3.6, 4.6, "hull_grey", segs=36)
    F.cyl(0, 0, 10.0, 4.6, 5.4, "hull_white", segs=36, studs=True)
    F.ring(9.6, 10.1, 4.7, 5.3, "glow_lime", segs=36)
    F.cyl(0, 0, 7.0, 5.4, 6.2, "hull_grey", segs=32)
    dome(F, 0, 0, 6.2, 5.0, 4.2, "glass", step=0.6, segs=24, studs=False)
    F.cyl(0, 0, 3.0, 2.8, 3.6, "glow_lime", segs=20)


# ------------------------------------------------------------------ the boss arena: THE ECLIPSE RING
def eclipse_ring(F, R=72.0):
    """A round, open, studded observation floor (deep navy with purple bands and gold rings), a constellation of neon
    dots and gold lines inlaid, low rim blocks round the edge with gaps at south + north, and an eclipse emblem in the
    middle. Nothing stands inside R: Chief Justice Eclipse pulls (r 44) and throws his gavel ring (r 38) anywhere on it."""
    W.arena_floor(F, R, field="space_navy", band="space_purple", ring="gold", inner=28)
    F.cyl(0, 0, 10, 0.4, 0.55, "black", segs=40)  # the eclipse emblem: a black disc in a gold corona
    F.ring(10, 12.4, 0.4, 0.6, "gold", segs=40)
    for k in range(16):
        px, py = polar(13.6, k * 22.5)
        F.brick(px, py, 0.4, 2.4, 0.6, 0.2, "glow_gold", rot=k * 22.5, studs=False)
    rng_l = K.rng
    pts = [polar(rng_l.uniform(34, R - 12), a) for a in (20, 55, 95, 140, 165, 200, 250, 300, 330)]
    for (x, y) in pts:
        F.cyl(x, y, 0.5, 0.45, 0.56, "glow_white", segs=8)
    for (a, b) in zip(pts, pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L < 40:
            F.brick((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, 0.45, L, 0.25, 0.06, "gold", rot=math.degrees(math.atan2(b[1] - a[1], b[0] - a[0])), studs=False, bevel=0.0)
    n = 36
    for k in range(n):  # the rim: low blocks, gaps at north + south (the way through)
        a = k * 360 / n
        if min(abs(a - 90), abs(a - 270)) < 14:
            continue
        px, py = polar(R + 1.0, a)
        F.brick(px, py, 0, 2.0, 2 * math.pi * (R + 1) / n - 0.6, 1.4, "hull_grey" if k % 2 else "hull_white", rot=a)
        if k % 3 == 0:
            F.brick(px, py, 1.4, 0.6, 0.6, 0.3, "glow_purple", rot=a, studs=False)
