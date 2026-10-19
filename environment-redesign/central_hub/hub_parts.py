# environment-redesign/central_hub/hub_parts.py - the central hub's buildings and landmarks (Stage 3, 2026-10-18).
# Each function builds one piece in a LOCAL frame (hl_kit.Frame): origin = the piece's centre on the ground,
# front = local -y (the side that faces the plaza). hub_build.py places them; showcase.py renders one alone.
# Style: docs/ART_STYLE_STUDS.md (studded brick, Roblox studs) + CLAUDE.md palette; text uses the attraction style
# (gold on black) or wayfinding (white on brown wood).
import math
import hl_kit as K

rng = K.rng


def polar(r, deg):
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


# ------------------------------------------------------------------ shared details
def scales_of_justice(F, x, y, z, s=1.0, look="gold"):
    """A gold scales sculpture: base, post, beam, two hanging pans."""
    F.brick(x, y, z, 2.4 * s, 2.4 * s, 0.6 * s, look, studs=False)
    F.brick(x, y, z + 0.6 * s, 0.5 * s, 0.5 * s, 4.4 * s, look, studs=False)
    F.brick(x, y, z + 5.0 * s, 5.2 * s, 0.4 * s, 0.4 * s, look, studs=False)
    F.brick(x, y, z + 5.2 * s, 0.9 * s, 0.9 * s, 0.9 * s, look, studs=False, bevel=0.2 * s)
    for sgn in (-1, 1):
        F.brick(x + sgn * 2.4 * s, y, z + 3.4 * s, 0.15 * s, 0.15 * s, 1.6 * s, look, studs=False, bevel=0.02)
        F.cyl(x + sgn * 2.4 * s, y, 1.0 * s, z + 3.0 * s, z + 3.4 * s, look, segs=12)


def attraction_sign(F, x, y, z, w, h, text, post_h=None, size=None, rot=0.0):
    """Black panel + gold text + a row of bulbs (CLAUDE.md attraction sign style), on two posts if post_h."""
    G = F.sub(x, y, rot)
    if post_h:
        for sgn in (-1, 1):
            G.brick(sgn * (w / 2 - 0.6), 0.4, 0, 0.8, 0.8, post_h, "metal_dark", studs=False)
    G.brick(0, 0, z, w, 0.8, h, "black", studs=False)
    G.brick(0, 0, z - 0.25, w + 0.6, 1.0, 0.4, "gold", studs=False)
    G.brick(0, 0, z + h - 0.15, w + 0.6, 1.0, 0.4, "gold", studs=False)
    n = max(3, int(w / 1.6))
    for k in range(n):
        bx = -w / 2 + 0.8 + k * (w - 1.6) / (n - 1)
        G.brick(bx, -0.45, z + 0.2, 0.45, 0.3, 0.45, "glow_warm", studs=False, bevel=0.1)
        G.brick(bx, -0.45, z + h - 0.65, 0.45, 0.3, 0.45, "glow_warm", studs=False, bevel=0.1)
    G.text(text, 0, -0.5, z + h / 2, size or h * 0.48, "gold", kind="bold", extrude=0.2)


def wood_sign(F, x, y, z, w, h, text, rot=0.0, post=True, size=None):
    """Wayfinding: brown wood board + white text."""
    G = F.sub(x, y, rot)
    if post:
        G.brick(0, 0.3, 0, 0.8, 0.8, z + h, "wood_dark", studs=False)
    G.brick(0, 0, z, w, 0.5, h, "wood", studs=False)
    G.brick(0, 0, z - 0.2, w + 0.4, 0.7, 0.3, "wood_dark", studs=False)
    G.brick(0, 0, z + h - 0.1, w + 0.4, 0.7, 0.3, "wood_dark", studs=False)
    G.text(text, 0, -0.3, z + h / 2, size or h * 0.42, "white", extrude=0.08)


# ------------------------------------------------------------------ 1. statue fountain (plaza centre)
def statue_fountain(F):
    F.cyl(0, 0, 20.0, 0, 0.5, "stone_dark", segs=56)
    F.ring(16.2, 19.2, 0.5, 2.8, "marble", segs=56, studs=True)
    F.ring(19.0, 19.7, 2.0, 3.0, "gold", segs=56)
    F.ring(15.9, 16.3, 2.0, 3.0, "gold", segs=56)
    F.cyl(0, 0, 16.3, 0.5, 2.0, "water", segs=56)
    for k in range(8):  # buttresses with glowing orbs
        x, y = polar(19.4, k * 45 + 22.5)
        F.brick(x, y, 0.5, 2.4, 2.4, 3.6, "marble", rot=k * 45 + 22.5)
        F.brick(x, y, 4.1, 1.8, 1.8, 0.5, "gold", rot=k * 45 + 22.5, studs=False)
        F.sphere(x, y, 5.0, 0.7, 0.7, 0.7, "glow_cyan", seg=10, rings=6)
    # middle drum + upper basin with a falling water curtain
    F.cyl(0, 0, 7.6, 2.0, 5.2, "marble", segs=40, bevel=0.3)
    for k in range(16):
        x, y = polar(7.65, k * 22.5)
        F.brick(x, y, 2.0, 0.5, 0.9, 3.0, "gold", rot=k * 22.5, studs=False, bevel=0.04)
    F.ring(7.6, 10.0, 5.2, 6.3, "marble", segs=48, studs=True)
    F.ring(9.6, 10.3, 6.3, 6.7, "gold", segs=48)
    F.cyl(0, 0, 9.6, 5.2, 6.1, "water", segs=48)
    F.ring(10.0, 10.5, 2.0, 6.1, "water", segs=48)
    # eight water jets arcing from the upper rim into the lower basin
    for k in range(8):
        a = k * 45
        prev = None
        for t in range(19):
            u = t / 18
            r = 10.4 + u * 4.8
            z = 6.4 + 2.6 * 4 * u * (1 - u) - u * 4.4
            x, y = polar(r, a)
            F.brick(x, y, z, 0.75, 0.55, 0.75, "water", rot=a, studs=False, bevel=0.2)
        sx, sy = polar(15.2, a)
        F.cyl(sx, sy, 1.1, 2.0, 2.25, "glow_white", segs=10)  # splash ring
    # plinth + plaque
    F.brick(0, 0, 6.1, 6.0, 6.0, 2.6, "marble")
    F.brick(0, 0, 8.7, 6.8, 6.8, 0.6, "gold", studs=False)
    F.brick(0, 0, 9.3, 5.0, 5.0, 1.4, "marble", studs=False)
    F.brick(0, -3.05, 6.7, 3.6, 0.3, 1.4, "gold", studs=False)
    statue_lawyer(F.sub(0, 0, z=10.7), 2.6, "metal_dark", accent="gold")


def statue_lawyer(F, s, look, accent="gold"):
    """A heroic brick lawyer (fictional), gavel raised, briefcase in hand - the game's character frame x s."""
    for sgn in (-1, 1):
        F.brick(sgn * 0.5 * s, -0.15 * s, 0, 0.95 * s, 1.25 * s, 0.32 * s, look, studs=False)  # shoes
        F.brick(sgn * 0.5 * s, 0, 0.3 * s, 0.9 * s, 0.9 * s, 1.3 * s, look, studs=False)  # legs
    F.brick(0, 0, 1.6 * s, 2.0 * s, 1.1 * s, 1.5 * s, look, studs=False)  # torso
    F.brick(0, -0.56 * s, 2.0 * s, 0.7 * s, 0.1 * s, 1.1 * s, accent, studs=False)  # shirt + tie
    F.brick(0, -0.6 * s, 2.0 * s, 0.25 * s, 0.1 * s, 1.0 * s, look, studs=False)
    F.brick(-1.35 * s, 0, 1.75 * s, 0.7 * s, 0.8 * s, 1.45 * s, look, studs=False)  # left arm down
    F.brick(-1.35 * s, -0.1 * s, 0.75 * s, 1.4 * s, 0.5 * s, 1.0 * s, accent, studs=False)  # briefcase
    F.brick(-1.35 * s, -0.1 * s, 1.75 * s, 0.5 * s, 0.2 * s, 0.25 * s, accent, studs=False)
    F.brick(1.35 * s, 0, 3.1 * s, 0.7 * s, 0.8 * s, 1.5 * s, look, studs=False)  # right arm raised
    F.brick(1.35 * s, 0, 4.6 * s, 0.25 * s, 0.25 * s, 1.5 * s, "wood_dark", studs=False)  # gavel handle
    F.brick(1.35 * s, 0, 6.0 * s, 1.6 * s, 0.7 * s, 0.7 * s, accent, studs=False, bevel=0.1 * s)  # gavel head
    for sgn in (-1, 1):  # lapels, cuffs, belt: a bit of tailoring
        F.brick(sgn * 0.5 * s, -0.57 * s, 2.3 * s, 0.25 * s, 0.1 * s, 0.8 * s, accent, studs=False, bevel=0.02)
    F.brick(0, 0, 1.55 * s, 2.05 * s, 1.15 * s, 0.18 * s, accent, studs=False, bevel=0.02)
    F.brick(0, 0, 3.0 * s, 1.0 * s, 1.0 * s, 0.15 * s, accent, studs=False, bevel=0.02)  # collar
    F.brick(0, 0, 3.1 * s, 2.0 * s, 1.8 * s, 1.8 * s, look, studs=False)  # head
    F.brick(0, 0.1 * s, 4.75 * s, 2.15 * s, 1.95 * s, 0.45 * s, look, studs=False)  # hair
    for sgn in (-1, 1):
        F.brick(sgn * 0.45 * s, -0.92 * s, 3.9 * s, 0.35 * s, 0.1 * s, 0.4 * s, accent, studs=False, bevel=0.02)  # square eyes
    F.brick(0, -0.92 * s, 3.45 * s, 0.8 * s, 0.1 * s, 0.15 * s, accent, studs=False, bevel=0.02)  # smile
    for sgn in (-1, 1):
        F.brick(sgn * 0.35 * s, -0.92 * s, 3.55 * s, 0.15 * s, 0.1 * s, 0.15 * s, accent, studs=False, bevel=0.02)
    for k in range(3):  # stepped hair
        F.brick(0, 0.2 * s + k * 0.1 * s, 4.75 * s + k * 0.3 * s, (2.15 - k * 0.4) * s, (1.95 - k * 0.3) * s, 0.35 * s, look, studs=False)


def spawn_pad(F):
    F.cyl(0, 0, 7.2, 0, 0.35, "marble", segs=40)
    F.ring(5.4, 6.4, 0.35, 0.6, "glow_cyan", segs=40)
    F.cyl(0, 0, 5.4, 0.35, 0.5, "stone_warm", segs=40, studs=True)
    for k in range(4):  # gold arrows pointing at the fountain (north)
        F.brick(0, -2.6 + k * 1.6, 0.5, 2.4 - k * 0.5, 0.8, 0.2, "gold", studs=False, bevel=0.05)


# ------------------------------------------------------------------ 2. Law License Building (north end of the avenue)
def license_building(F):
    # podium + grand stairs with a red carpet
    F.brick(0, 4, 0, 62, 38, 4, "stone")
    F.brick(0, 4, 3.6, 62.6, 38.6, 0.4, "marble", studs=False)
    K.stairs(F, 0, -27.2, 0, 34, 8, 0.5, 1.4, 90, look="marble")
    for k in range(8):
        F.brick(0, -27.2 + 1.4 * (k + 0.5), 0.5 * (k + 1), 8, 1.4, 0.06, "red", studs=False, bevel=0.01)
    F.brick(0, -11, 4.0, 8, 8, 0.08, "red", studs=False, bevel=0.01)
    for sgn in (-1, 1):  # stair cheek blocks with the scales sculptures
        F.brick(sgn * 19.5, -21, 0, 5, 12, 4.6, "marble")
        F.brick(sgn * 19.5, -21, 4.6, 5.6, 12.6, 0.6, "gold", studs=False)
        scales_of_justice(F, sgn * 19.5, -23, 5.2, 0.9)
        K.lamp(F, sgn * 19.5, -16.5, 5.2 + 7, rot=0)
    # central hall
    F.brick(0, 6, 4, 36, 26, 19, "cream", studs=False)
    for x in (-15, -9, -3, 3, 9, 15):
        K.column(F, x, -10, 4, 18, 2.2)
    F.brick(0, -10, 22, 40, 4.4, 2.4, "marble", studs=False)  # entablature
    F.brick(0, -12.25, 22.2, 30, 0.3, 2.0, "roof_navy", studs=False)
    F.brick(0, -12.3, 22.0, 30.6, 0.3, 0.3, "gold", studs=False)
    F.brick(0, -12.3, 24.1, 30.6, 0.3, 0.3, "gold", studs=False)
    F.text("LAW LICENSES", 0, -12.5, 23.2, 1.75, "gold", kind="bold", extrude=0.12)
    for k in range(6):  # stepped pediment
        w = 41 - k * 7.0
        F.brick(0, -9.6, 24.4 + k * 1.05, w, 5.2, 1.05, "marble", studs=True)
    F.brick(0, -12.3, 25.4, 9, 0.3, 3.2, "gold_dark", studs=False)
    scales_of_justice(F.sub(0, -12.6), 0, 0, 25.0, 0.55, "gold")
    # portico ceiling + floor + doors + round window
    F.brick(0, -9.6, 21.4, 37, 5, 0.6, "white", studs=False)
    K.door(F, 0, -7.05, 4, 7, 11, 0, frame="gold", leaf="wood_dark", arch=True, depth=0.9)
    for sgn in (-1, 1):
        K.door(F, sgn * 9, -7.05, 4, 3.6, 7, 0, frame="white", leaf="wood_dark", depth=0.7)
        K.window(F, sgn * 9, -7.05, 13, 3.6, 5, 0, frame="white", mullions=1)
    F.ring_v(0, -7.3, 19.0, 1.7, 2.5, 0.6, "gold", segs=16, gap=0.05)
    F.disc_v(0, -7.1, 19.0, 1.8, 0.2, "glass", segs=20)
    # side walls: pilasters + tall windows
    for sx in (-1, 1):
        for k in range(4):
            y = -3 + k * 6.5
            F.brick(sx * 18.2, y - 3.25, 4, 0.8, 1.4, 18, "white", studs=False)
            K.window(F.sub(sx * 18.05, y, rot=90 * sx), 0, 0, 8, 3.2, 8, 0, frame="white", mullions=1, depth=0.5)
    F.brick(0, 6, 23, 37.2, 27.2, 1.4, "white", studs=False)  # cornice
    F.brick(0, 6, 24.4, 36.4, 26.4, 0.5, "gold", studs=False)
    F.brick(0, 6, 24.9, 35, 25, 0.6, "stone_warm")  # studded roof deck
    # the dome: drum with windows, gold voxel dome, lantern, flag
    F.cyl(0, 8, 9.6, 25.5, 27.0, "white", segs=40, bevel=0.2)
    F.cyl(0, 8, 8.8, 27.0, 33.0, "cream", segs=40)
    for k in range(12):
        a = k * 30
        x, y = polar(8.85, a)
        F.brick(x, 8 + y, 27.0, 0.9, 1.0, 6.0, "white", rot=a, studs=False)
        x2, y2 = polar(8.9, a + 15)
        F.brick(x2, 8 + y2, 28.2, 0.3, 1.6, 3.4, "glass_dark", rot=a + 15, studs=False, bevel=0.0)
    F.cyl(0, 8, 9.4, 33.0, 33.8, "gold", segs=40)
    K.voxel_round(F, 0, 8, 33.8, lambda t: 9.0 * math.sqrt(max(0.0, 1 - t * t)), 9.0, "gold", step=1.0, segs=40)
    F.cyl(0, 8, 1.8, 42.5, 45.5, "white", segs=12)
    F.cone(0, 8, 2.2, 45.5, 47.5, "gold", segs=12)
    K.flag(F, 0, 8, 47.5, 6, "purple")
    # wings: lower blocks with navy stepped hip roofs, windows on two floors, banners
    for sx in (-1, 1):
        cx = sx * 25
        F.brick(cx, 4, 4, 14, 26, 13, "cream", studs=False)
        F.brick(cx, 4, 17, 15, 27, 1.0, "white", studs=False)
        F.roof_hip(cx, 4, 18, 14, 26, 5, "roof_navy", trim="gold", cap="gold", overhang=0.8)
        for fl in (0, 1):
            for x in (cx - 3.5, cx + 3.5):
                K.window(F, x, -9.05, 6 + fl * 6, 3, 4, 0, frame="white", shutters="roof_navy" if fl == 0 else None)
        K.banner(F, cx, -9.4, 9, 7, 2.4, "purple", rot=0)
        K.flag(F, cx + sx * 6, 15, 23, 6, "red")
        for k in range(3):
            K.window(F.sub(cx + sx * 7.05, -3 + k * 7, rot=90 * sx), 0, 0, 7, 3, 5, 0, frame="white", depth=0.5)
    # forecourt planters + hedges on the podium
    for sgn in (-1, 1):
        K.planter(F.sub(0, 0, z=4), sgn * 27.5, -12, 5, 3, plant="bush")
        K.flowerbed(F.sub(0, 0, z=4), sgn * 13, -15.5, 6, 3)


# ------------------------------------------------------------------ 3. Travel Portal (inner ring NW)
def travel_portal(F, fx=None):
    """fx: an optional second frame for the moving parts (the light swirl spins in the ambience pass)."""
    fx = fx or F
    F.cyl(0, 2, 21, 0, 1.4, "stone_dark", segs=48)
    F.cyl(0, 2, 19, 1.4, 3.2, "stone", segs=48, bevel=0.3)
    F.ring(18.6, 19.4, 3.2, 3.7, "gold", cx=0, cy=2, segs=48)
    F.cyl(0, 2, 16, 3.2, 4.6, "marble", segs=48, studs=True)
    F.ring(15.6, 16.4, 4.6, 4.9, "glow_cyan", cx=0, cy=2, segs=48)
    K.stairs(F, 0, -23.5, 0, 12, 6, 0.77, 1.15, 90, look="marble")
    for sgn in (-1, 1):
        F.brick(sgn * 7.0, -20.0, 0, 2.0, 7.6, 5.0, "stone")
        F.brick(sgn * 7.0, -20.0, 5.0, 2.4, 8.0, 0.5, "gold", studs=False)
        F.sphere(sgn * 7.0, -23.0, 6.3, 0.8, 0.8, 0.8, "glow_cyan", seg=10, rings=6)
    # railing round the top (open at the front)
    pts = [polar(15.2, a) for a in range(-60, 241, 20)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        K.railing(F, x0, y0 + 2, x1, y1 + 2, 4.6, 2.2, "white", post_every=4)
    # four obelisks with floating crystals
    for a in (35, 145, 215, 325):
        x, y = polar(12.6, a)
        F.brick(x, y + 2, 4.6, 2.6, 2.6, 1.0, "stone_dark", rot=a)
        F.brick(x, y + 2, 5.6, 1.8, 1.8, 8.0, "stone", rot=a, studs=False)
        F.brick(x, y + 2, 13.6, 2.4, 2.4, 0.6, "gold", rot=a, studs=False)
        F.cone(x, y + 2, 1.2, 15.0, 17.6, "glow_purple", segs=4)
        F.cone(x, y + 2, 1.2, 15.0, 13.8, "glow_purple", segs=4)
    # the gateway: chunky stone/gold ring, glowing field, swirl, runes, keystone, feet
    cz = 4.6 + 15.2
    F.ring_v(0, 3, cz, 12.6, 15.6, 3.6, ["roof_navy", "roof_navy", "purple_dark"], segs=30, gap=0.18)
    F.ring_v(0, 3, cz, 15.6, 16.8, 2.4, "stone", segs=30, gap=0.25)
    F.ring_v(0, 1.0, cz, 15.4, 16.2, 0.6, "gold", segs=30, gap=0.1)
    F.ring_v(0, 1.1, cz, 11.9, 12.6, 0.6, "gold", segs=30, gap=0.1)
    F.disc_v(0, 3, cz, 12.6, 0.5, "portal_field", segs=40)
    for k in range(46):  # swirl of light
        t = k / 46
        r = 1.0 + 10.8 * t
        a = math.radians(t * 720)
        fx.brick(r * math.cos(a), 2.6, cz + r * math.sin(a) - 0.35, 0.8, 0.5, 0.7, "glow_white" if k % 3 == 0 else "glow_cyan", studs=False, bevel=0.12)
    for k in range(8):
        a = math.radians(k * 45 + 22.5)
        F.brick(14.1 * math.cos(a), 1.0, cz + 14.1 * math.sin(a) - 0.6, 1.2, 0.4, 1.2, "glow_purple", studs=False, bevel=0.1)
    F.brick(0, 3, cz + 15.0, 5.0, 4.6, 3.2, "gold")  # keystone
    F.sphere(0, 0.6, cz + 16.6, 1.0, 0.6, 1.0, "glow_cyan", seg=12, rings=8)
    for sgn in (-1, 1):
        F.brick(sgn * 9.6, 3, 4.6, 6.4, 6.4, 3.4, "stone_dark")
        F.brick(sgn * 9.6, 3, 8.0, 5.6, 5.6, 1.6, "stone")
        F.brick(sgn * 9.6, 3, 9.6, 6.0, 6.0, 0.5, "gold", studs=False)
    attraction_sign(F, -15.5, -21.5, 6.0, 11, 3.4, "TRAVEL", post_h=6.0, rot=20)


# ------------------------------------------------------------------ 4. Egg Incubator landmark (inner ring NE)
def egg_profile(t, R=8.2, peak=0.4):
    """An egg's radius at height fraction t (fatter low, pointier on top)."""
    if t < peak:
        u = (peak - t) / peak
        return R * math.sqrt(max(0.0, 1 - u * u))
    u = (t - peak) / (1 - peak)
    return R * math.sqrt(max(0.0, 1 - u ** 1.7))


def egg_incubator(F):
    F.cyl(0, 0, 16, 0, 1.2, "stone_dark", segs=48)
    F.cyl(0, 0, 14.5, 1.2, 3.0, "marble", segs=48, studs=True, bevel=0.3)
    F.ring(14.1, 14.9, 3.0, 3.4, "gold", segs=48)
    K.stairs(F, 0, -19.2, 0, 10, 3, 1.0, 1.4, 90, look="marble")
    # cradle base + glowing heat ring
    F.cyl(0, 0, 9.0, 3.0, 4.2, "metal_dark", segs=36, bevel=0.2)
    F.ring(8.6, 9.6, 4.2, 4.7, "glow_gold", segs=36)
    eggz, eggh = 4.2, 22
    K.voxel_round(F, 0, 0, eggz, lambda t: egg_profile(t), eggh, "eggshell", step=1.0, segs=40,
                  looks=lambda k: {6: "orange", 7: "gold", 12: "sky_blue", 13: "orange", 17: "gold"}.get(k, "eggshell"))
    for k in range(26):  # orange + gold spots stuck on the shell
        t = rng.uniform(0.12, 0.85)
        a = rng.uniform(0, 360)
        r = egg_profile(t) + 0.15
        x, y = polar(r, a)
        F.brick(x, y, eggz + t * eggh - 0.6, 1.6, 0.5, 1.2, rng.choice(["orange", "gold", "orange"]), rot=a + 90, studs=False, bevel=0.15)
    # four cradle arms hugging the egg
    for a in (45, 135, 225, 315):
        for k in range(9):
            t = k / 9 * 0.62
            r = egg_profile(t + 0.03) + 0.9
            x, y = polar(r, a)
            F.brick(x, y, eggz + t * eggh, 1.8, 1.8, eggh * 0.62 / 9 + 0.05, "gold" if k % 2 == 0 else "gold_dark", rot=a, studs=False)
        x, y = polar(egg_profile(0.62) + 1.4, a)
        F.sphere(x, y, eggz + 0.64 * eggh, 0.9, 0.9, 0.9, "glow_gold", seg=10, rings=6)
    # halo rings of light round the egg
    for zt, rr in ((0.3, 1.8), (0.55, 1.6)):
        R = egg_profile(zt) + rr
        F.ring(R - 0.25, R + 0.25, eggz + zt * eggh, eggz + zt * eggh + 0.3, "glow_cyan", segs=48)
    # heat lamps + a boiler with a gauge and pipes at the back
    for sgn in (-1, 1):
        x = sgn * 11.5
        F.brick(x, 4, 3.0, 1.0, 1.0, 13, "metal_dark", studs=False)
        F.brick(x - sgn * 1.6, 4, 15.6, 4.2, 1.0, 1.0, "metal_dark", studs=False)
        F.cone(x - sgn * 3.2, 4, 1.6, 15.2, 13.4, "metal", segs=8)
        F.cyl(x - sgn * 3.2, 4, 1.0, 13.0, 13.4, "glow_red", segs=8)
    F.cyl(0, 11.5, 3.0, 3.0, 10, "metal", segs=20, bevel=0.3)
    F.cyl(0, 11.5, 3.2, 10, 10.6, "gold", segs=20)
    F.disc_v(0, 8.4, 7.6, 1.2, 0.3, "white", segs=16)
    F.ring_v(0, 8.3, 7.6, 1.2, 1.5, 0.35, "gold", segs=12, gap=0.02)
    F.brick(0.4, 8.2, 7.6, 1.0, 0.1, 0.15, "red", studs=False, bevel=0.01)
    for sgn in (-1, 1):
        F.brick(sgn * 3.4, 9.5, 4.0, 4.4, 1.0, 1.0, "metal", rot=sgn * 30, studs=False)
    attraction_sign(F, 14.5, -13.5, 6.5, 13, 3.4, "EGG INCUBATOR", post_h=6.5, size=1.25, rot=-35)


# ------------------------------------------------------------------ 5. Shop (inner ring SW): red/white awning storefront
def shop(F):
    W, D = 28, 20
    F.brick(0, 2, 0, W + 4, D + 6, 0.8, "stone_warm")
    F.brick(0, 4, 0.8, W, D, 9, "cream", studs=False)  # ground floor
    F.brick(0, 4, 9.8, W + 0.8, D + 0.8, 0.8, "white")  # studded terrace round the upper floor
    F.brick(0, 5, 10.6, W - 4, D - 4, 8, "brick_red", studs=False)  # upper floor
    for x in (-8, 0, 8):
        K.window(F, x, -3.05, 12.6, 3.4, 4, 0, frame="white", shutters="roof_navy")
        F.brick(x, -3.7, 11.6, 4.6, 1.2, 0.8, "wood_dark", studs=False)  # flower box
        for k in range(4):
            F.brick(x - 1.5 + k, -3.7, 12.4, 0.8, 0.8, 0.6, rng.choice(["pink", "yellow", "red"]), studs=False)
    for sx in (-1, 1):  # side windows, both floors
        for k in range(2):
            K.window(F.sub(sx * (W / 2 + 0.05), -0.5 + k * 9, rot=90 * sx), 0, 0, 3, 3.4, 4.4, 0, frame="white", depth=0.5)
            K.window(F.sub(sx * ((W - 4) / 2 + 0.05), 1 + k * 8, rot=90 * sx), 0, 0, 12.6, 3, 4, 0, frame="white", shutters="roof_navy", depth=0.5)
    F.roof_hip(0, 5, 18.6, W - 4, D - 4, 6, "roof_red", trim="white", cap="gold")
    F.brick(8, 9, 19, 2.4, 2.4, 9, "brick_dark", studs=True)  # chimney
    # display windows with goods + a central door
    for sgn in (-1, 1):
        cx = sgn * 8.5
        K.window(F, cx, -6.05, 2.2, 9, 5.8, 0, frame="white", mullions=2, sill=True)
        F.brick(cx, -5.0, 1.2, 9, 2.0, 1.0, "wood", studs=False)
        for k in range(3):
            ex = cx - 3 + k * 3
            K.voxel_round(F, ex, -5.0, 2.2, lambda t: 0.9 * egg_profile(t, 1.0), 2.4, rng.choice(["eggshell", "sky_blue", "pink"]), step=0.4, studs=False, segs=12)
    K.door(F, 0, -6.05, 0.8, 4.2, 7.4, 0, frame="white", leaf="roof_red", depth=0.8)
    # striped scalloped awning over the front
    n = 14
    for k in range(n):
        x = -W / 2 + (k + 0.5) * W / n
        look = "awning_red" if k % 2 == 0 else "awning_white"
        for j in range(4):  # 4 steps sloping out
            F.brick(x, -6.6 - j * 0.9, 9.0 - j * 0.55, W / n, 1.0, 0.6, look, studs=(j == 0))
        F.brick(x, -10.0, 6.6, W / n - 0.1, 0.5, 0.9, look, studs=False, bevel=0.2)  # scallop
    # SHOP board: red board, gold frame, white letters, a gold coin
    F.brick(0, -6.4, 10.4, 16, 0.8, 4.6, "awning_red", studs=False)
    F.brick(0, -6.5, 10.1, 16.8, 0.9, 0.5, "gold", studs=False)
    F.brick(0, -6.5, 14.8, 16.8, 0.9, 0.5, "gold", studs=False)
    F.text("SHOP", 1.4, -6.95, 12.7, 3.1, "white", kind="bold", extrude=0.25)
    F.disc_v(-5.6, -6.95, 12.6, 1.5, 0.5, "gold", segs=20)
    F.disc_v(-5.6, -7.25, 12.6, 1.0, 0.2, "gold_dark", segs=20)
    # crates, barrels, a cart of eggs, lamps
    for k, (x, y) in enumerate(((-15.5, -8), (-15.5, -5.5), (-13.2, -8.4))):
        F.brick(x, y, 0.8, 2.2, 2.2, 2.0 if k < 2 else 1.6, "wood", rot=k * 7)
        F.brick(x, y, 0.8 + (2.0 if k < 2 else 1.6) * 0.5 - 0.15, 2.3, 2.3, 0.3, "wood_dark", rot=k * 7, studs=False)
    for k, x in enumerate((14.8, 12.6)):
        F.cyl(x, -8, 1.1, 0.8, 3.0, "wood", segs=12, bevel=0.2, studs=True)
        F.ring(1.05, 1.2, 1.4, 1.7, "metal_dark", cx=x, cy=-8, segs=12)
    K.lamp(F, -17.5, -11.5, 11)
    K.lamp(F, 17.5, -11.5, 11)


# ------------------------------------------------------------------ 6. Upgrades (inner ring SE): Carry + Speed
def gear(F, x, y, z, r, look="gold", rot=0.0, depth=0.8, teeth=12):
    F.ring_v(x, y, z, r * 0.45, r * 0.82, depth, look, rot=rot, segs=teeth * 2, gap=0.05)
    for k in range(teeth):
        a = math.radians(k * 360 / teeth)
        F.brick(x + r * 0.9 * math.cos(a) * math.cos(math.radians(rot)), y + r * 0.9 * math.cos(a) * math.sin(math.radians(rot)),
                z + r * 0.9 * math.sin(a) - r * 0.11, r * 0.24, depth, r * 0.22, look, rot=rot, studs=False, bevel=0.05)
    F.disc_v(x, y, z, r * 0.3, depth * 1.2, "metal_dark", rot=rot, segs=12)


def upgrades(F):
    W, D = 28, 20
    F.brick(0, 2, 0, W + 4, D + 6, 0.8, "stone_warm")
    F.brick(0, 4, 0.8, W, D, 16, "stone", studs=False)
    for x in (-W / 2 + 0.4, W / 2 - 0.4):  # corner quoins
        for k in range(8):
            F.brick(x, -5.6, 0.8 + k * 2, 1.4 if k % 2 else 2.2, 1.4, 1.9, "stone_dark", studs=False, bevel=0.06)
    F.brick(0, 4, 16.8, W + 1, D + 1, 1.0, "white", studs=False)
    F.roof_hip(0, 4, 17.8, W, D, 6, "roof_navy", trim="gold", cap="gold")
    for fl in (0, 1):
        for x in (-9, 9):
            K.window(F, x, -6.05, 3 + fl * 7, 4, 4.4, 0, frame="white", mullions=1, shutters="roof_blue" if fl else None)
    K.door(F, 0, -6.05, 0.8, 5, 8, 0, frame="gold", leaf="roof_navy", arch=True)
    for sx in (-1, 1):
        for fl in (0, 1):
            for k in range(2):
                K.window(F.sub(sx * (W / 2 + 0.05), -0.5 + k * 9, rot=90 * sx), 0, 0, 3 + fl * 7, 3.4, 4.4, 0, frame="white", depth=0.5)
    # UPGRADES board + big gold gear
    F.brick(0, -6.4, 11.0, 15, 0.8, 3.2, "roof_navy", studs=False)
    F.brick(0, -6.5, 10.7, 15.8, 0.9, 0.4, "gold", studs=False)
    F.brick(0, -6.5, 14.0, 15.8, 0.9, 0.4, "gold", studs=False)
    F.text("UPGRADES", 0, -6.95, 12.6, 1.9, "gold", kind="bold", extrude=0.2)
    gear(F, 0, -6.6, 18.4, 3.6, "gold")
    # Carry: a giant briefcase on a pedestal (left); Speed: a winged boot (right)
    F.brick(-14, -10, 0.8, 5, 5, 2.4, "marble")
    F.brick(-14, -10, 3.2, 5.6, 2.2, 3.8, "wood_dark", studs=False)
    F.brick(-14, -10, 3.2, 5.8, 2.4, 0.4, "gold", studs=False)
    F.brick(-14, -10, 6.2, 5.8, 2.4, 0.3, "gold", studs=False)
    F.brick(-14, -11.25, 5.0, 1.0, 0.2, 0.7, "gold", studs=False)
    for sgn in (-1, 1):
        F.brick(-14 + sgn * 1.0, -10, 7.0, 0.4, 0.5, 1.0, "gold", studs=False)
    F.brick(-14, -10, 7.9, 2.4, 0.5, 0.4, "gold", studs=False)
    F.brick(14, -10, 0.8, 5, 5, 2.4, "marble")
    F.brick(14.6, -10, 3.2, 2.4, 2.2, 4.0, "red", studs=False)  # boot shaft
    F.brick(13.4, -10, 3.2, 4.8, 2.2, 1.4, "red", studs=False)  # foot
    F.brick(13.4, -10, 3.2, 5.0, 2.4, 0.4, "white", studs=False)  # sole
    F.brick(14.6, -10, 6.8, 2.6, 2.4, 0.5, "white", studs=False)
    for sgn in (-1, 1):  # gold wings
        for k in range(3):
            F.brick(15.9 + k * 0.7, -10 + sgn * 1.4, 5.2 + k * 0.6, 1.6, 0.3, 0.6, "gold", rot=sgn * 10, studs=False)
    K.lamp(F, -17.5, -6, 11)
    K.lamp(F, 17.5, -6, 11)
    K.planter(F, -6.5, -8.5, 3, 2, plant="flowers")
    K.planter(F, 6.5, -8.5, 3, 2, plant="flowers")


# ------------------------------------------------------------------ 7. Mutation Machine (inner ring W)
def hazard_ring(F, r, z, n=36):
    for k in range(n):
        x, y = polar(r, k * 360 / n)
        F.brick(x, y, z, 2 * math.pi * r / n - 0.1, 1.0, 0.4, "hazard" if k % 2 == 0 else "black", rot=k * 360 / n + 90, studs=False, bevel=0.05)


def mutation_machine(F):
    F.cyl(0, 0, 14, 0, 1.0, "stone_dark", segs=48)
    F.cyl(0, 0, 12.6, 1.0, 2.0, "metal_dark", segs=48, studs=True)
    hazard_ring(F, 12.2, 2.0)
    K.stairs(F, 0, -16.6, 0, 8, 2, 1.0, 1.4, 90, look="metal")
    # three input pods (the 3 lawyers) + pipes into the chamber
    for a in (150, 90, 30):
        x, y = polar(7.8, a)
        F.cyl(x, y, 2.6, 2.0, 3.0, "metal", segs=20, bevel=0.2)
        F.cyl(x, y, 1.4, 3.0, 3.3, "glow_purple", segs=20)  # (inside the glass, not on its cells)
        F.cyl(x, y, 2.1, 3.0, 9.0, "glass", segs=20)
        F.cyl(x, y, 2.6, 9.0, 10.0, "metal", segs=20, bevel=0.2)
        F.cone(x, y, 1.8, 10.0, 11.2, "purple", segs=8)
        mx, my = polar(4.6, a)
        F.brick(mx, my, 6.2, 4.0, 1.2, 1.2, "metal_dark", rot=a, studs=False)
        F.brick(mx, my, 6.0, 1.4, 1.4, 1.6, "gold", rot=a, studs=False)
    # central chamber: tall glass tube, swirling glow, gold bands, a crowned top with an orb
    F.cyl(0, 0, 4.6, 2.0, 4.0, "metal", segs=28, bevel=0.3)
    F.cyl(0, 0, 3.8, 4.0, 16.0, "glass", segs=28)
    for k in range(40):
        t = k / 40
        a = math.radians(t * 1080)
        F.brick(2.2 * math.cos(a), 2.2 * math.sin(a), 4.4 + t * 11, 0.8, 0.8, 0.8, "glow_purple" if k % 4 else "glow_green", studs=False, bevel=0.2)
    F.cyl(0, 0, 1.3, 4.0, 16.0, "glow_purple", segs=12)
    for z in (7.5, 11.5):
        F.ring(3.8, 4.4, z, z + 0.6, "gold", segs=28)
    F.cyl(0, 0, 4.6, 16.0, 17.4, "metal", segs=28, bevel=0.3)
    F.cyl(0, 0, 3.6, 17.4, 18.4, "gold", segs=28, studs=True)
    for a in range(0, 360, 60):
        x, y = polar(3.0, a)
        F.brick(x, y, 18.4, 0.9, 0.9, 1.4, "gold", rot=a, studs=False)
    F.sphere(0, 0, 20.6, 1.6, 1.6, 1.6, "glow_green", seg=14, rings=8)
    # tesla coils
    for sgn in (-1, 1):
        x = sgn * 9.6
        for k in range(5):
            F.cyl(x, -4, 1.4 - k * 0.15, 2.0 + k * 1.6, 3.2 + k * 1.6, "metal" if k % 2 else "gold_dark", segs=14)
        F.sphere(x, -4, 11.5, 1.2, 1.2, 1.2, "glow_cyan", seg=12, rings=8)
    # console in front
    F.brick(0, -8.4, 2.0, 7, 2.4, 2.6, "metal_dark", studs=False)
    F.wedge(0, -8.4, 4.6, 7, 2.4, 0.9, "metal", ridge="x")
    for k, lk in enumerate(("glow_red", "glow_green", "glow_cyan", "glow_gold")):
        F.brick(-2.4 + k * 1.6, -9.0, 4.55, 0.8, 0.6, 0.5, lk, studs=False, bevel=0.15)
    F.brick(0, -7.4, 4.6, 5, 0.4, 3.2, "glow_cyan", studs=False, bevel=0.05)  # screen
    F.brick(0, -7.2, 4.4, 5.6, 0.5, 3.6, "metal_dark", studs=False)
    attraction_sign(F, -14.5, -11.5, 7.2, 13, 3.4, "MUTATION LAB", post_h=7.2, size=1.35, rot=35)


# ------------------------------------------------------------------ 8. Big Case belt + minigame booths (inner ring E)
def booth(F, x, y, title, canopy, prop):
    G = F.sub(x, y)
    G.brick(0, 0, 0, 12, 8, 1.0, "stone_warm")
    G.brick(0, 1.5, 1.0, 10, 2.0, 3.2, "wood", studs=False)  # counter
    G.brick(0, 1.5, 4.2, 10.6, 2.6, 0.5, "wood_dark")
    for sx in (-1, 1):
        for sy in (-1, 1):
            G.brick(sx * 5.2, sy * 3.4, 1.0, 0.6, 0.6, 7.6, "white", studs=False)
    n = 8  # striped canopy
    for k in range(n):
        lx = -6 + (k + 0.5) * 12 / n
        G.brick(lx, 0, 8.6, 12 / n, 8.4, 0.5, canopy if k % 2 == 0 else "awning_white", studs=False)
        G.brick(lx, -4.4, 7.9, 12 / n - 0.1, 0.5, 0.8, canopy if k % 2 == 0 else "awning_white", studs=False, bevel=0.2)
    G.roof_hip(0, 0, 9.1, 11, 7.6, 2.4, canopy, cap="gold", overhang=0.2, courses=3)
    attraction_sign(G, 0, -4.8, 10.6, 10, 2.6, title, size=1.1)
    prop(G)


def _gavel_prop(G):
    G.brick(3.5, 1.5, 4.7, 0.6, 0.6, 3.6, "wood_dark", rot=25, studs=False)
    G.brick(3.9, 1.5, 7.8, 3.4, 1.6, 1.6, "wood", rot=25, studs=False, bevel=0.3)
    G.brick(3.9, 1.5, 7.8, 0.4, 1.7, 1.7, "gold", rot=25, studs=False)
    for k in range(3):
        G.cyl(-3 + k * 2.2, 1.5, 0.8, 4.7, 5.1, "red" if k != 1 else "yellow", segs=12)


def _briefcase_prop(G):
    for k, lk in enumerate(("wood_dark", "gold", "wood_dark")):
        x = -3 + k * 3
        G.brick(x, 1.5, 4.7, 2.4, 1.0, 1.8, lk, studs=False)
        G.brick(x, 1.5, 6.5, 1.0, 0.4, 0.4, "gold" if lk != "gold" else "wood_dark", studs=False)
        G.text("?", x, 0.9, 5.6, 1.0, "white", kind="bold", extrude=0.05)


def bigcase_terrace(F, fx=None):
    """fx: an optional second frame for the moving parts (the cases ride the belt in the ambience pass)."""
    fx = fx or F
    F.brick(0, 0, 0, 66, 34, 1.2, "stone_warm")
    for sgn in (-1, 1):
        F.brick(0, sgn * 17.1, 0, 66.6, 0.6, 1.5, "gold", studs=False)
        F.brick(sgn * 33.1, 0, 0, 0.6, 34.6, 1.5, "gold", studs=False)
    for x, y in ((-30, -14), (30, -14), (-30, 14), (30, 14)):
        K.planter(F.sub(0, 0, z=1.2), x, y, 4, 4, plant="flowers" if y < 0 else "bush")
    for sgn in (-1, 1):  # flags on the back posts, clear of the belt
        K.flag(F, sgn * 11, 11.0, 13, 6, "gold" if sgn < 0 else "red")
    # the belt along local x
    F.brick(0, 6, 1.2, 58, 6.6, 2.4, "metal_dark", studs=False)
    F.brick(0, 6, 3.6, 56, 5.2, 0.3, "black", studs=False)
    for k in range(28):  # belt slats
        F.brick(-27 + k * 2, 6, 3.9, 0.4, 5.0, 0.15, "metal", studs=False, bevel=0.02)
    for sgn in (-1, 1):
        F.brick(0, 6 + sgn * 3.1, 3.6, 58, 0.5, 1.0, "hazard", studs=False)
        F.disc_v(sgn * 28.6, 6, 2.6, 1.6, 6.0, "metal", rot=90, segs=16)
    # tunnel hoods at both ends (in / out, like a luggage belt): cases come out of one and go into the other,
    # so the looping ride never shows a case appearing or leaving the belt's end
    for sgn in (-1, 1):
        cx = sgn * 27.0
        for sy in (-1, 1):
            F.brick(cx, 6 + sy * 3.9, 1.2, 14, 0.8, 8.0, "roof_navy", studs=False)
        F.brick(cx, 6, 9.2, 14.4, 8.8, 1.2, "roof_navy")
        F.brick(cx, 6, 9.0, 14.8, 9.2, 0.4, "gold", studs=False)
        F.brick(sgn * 33.6, 6, 1.2, 0.8, 8.6, 9.2, "roof_navy", studs=False)  # closed back
        for k in range(7):  # rubber flaps at the mouth
            F.brick(sgn * 20.2, 3.0 + k * 1.0, 4.1, 0.2, 0.85, 5.1, "black", studs=False, bevel=0.03)
        F.text("IN" if sgn < 0 else "OUT", sgn * 19.85, 6, 10.4, 1.2, "gold", rot=90 * sgn, kind="bold", extrude=0.08)
    for k in range(7):  # big cases riding the belt
        x = -24 + k * 8
        fx.brick(x, 6, 4.0, 3.0, 1.4, 2.2, "wood_dark" if k % 3 else "gold", studs=False)
        fx.brick(x, 6, 6.2, 1.2, 0.4, 0.5, "gold" if k % 3 else "wood_dark", studs=False)
    # arch over the belt with the BIG CASES marquee
    # two goalpost frames STRADDLING the belt (posts beside it, a crossbeam over it), joined by the top beam:
    # the cases ride underneath (belt y 2.7..9.3, case tops at z 6.7, beams from z 12.2)
    for sx in (-1, 1):
        for sy in (-1, 1):
            F.brick(sx * 11, 6 + sy * 5.0, 1.2, 1.8, 1.8, 11, "roof_navy", studs=False)
            F.brick(sx * 11, 6 + sy * 5.0, 12.2, 2.4, 2.4, 0.8, "gold", studs=False)
        F.brick(sx * 11, 6, 12.2, 2.0, 12.4, 1.4, "roof_navy", studs=False)
    F.brick(0, 6, 13.0, 25, 2.6, 1.2, "roof_navy", studs=False)
    attraction_sign(F, 0, 4.4, 14.2, 18, 3.6, "BIG CASES!", size=1.8)
    booth(F, -21, -9, "GAVEL BONK", "red", _gavel_prop)
    booth(F, 21, -9, "LUCKY CASE", "roof_blue", _briefcase_prop)
    for x in (-8, 8):
        K.bench(F.sub(0, 0, z=1.2), x, -12, rot=0)
        K.lamp(F.sub(0, 0, z=1.2), x * 1.6, -14, 11)


# ------------------------------------------------------------------ 9. Leaderboard (x4: two each side of the avenue)
def leaderboard(F, title):
    F.brick(0, 0, 0, 12, 4, 2.0, "stone")
    F.brick(0, 0, 2.0, 12.6, 4.6, 0.4, "gold", studs=False)
    for sgn in (-1, 1):
        F.brick(sgn * 5.4, 0, 2.4, 1.2, 1.6, 14, "gold_dark", studs=False)
    F.brick(0, 0.2, 3.0, 10, 0.8, 12.6, "roof_navy", studs=False)
    F.brick(0, -0.2, 14.6, 11.4, 1.6, 2.4, "gold", studs=False)
    F.text(title, 0, -1.05, 15.8, 0.95, "roof_navy", kind="bold", extrude=0.08)
    for k in range(10):  # ten glowing rows (names come from LeaderboardService)
        w = 8 - (0.4 if k > 2 else 0)
        F.brick(0, -0.25, 3.6 + k * 1.05, w, 0.2, 0.55, "glow_gold" if k == 9 else ("glow_white" if k > 6 else "glow_cyan"), studs=False, bevel=0.03)
    for sgn in (-1, 0, 1):  # crown
        F.brick(sgn * 1.6, 0, 17.0, 1.0, 1.0, 1.6 if sgn else 2.4, "gold", studs=False)
    F.brick(0, 0, 16.9, 4.4, 1.2, 0.8, "gold", studs=False)
    F.sphere(0, -0.4, 19.6, 0.5, 0.5, 0.5, "glow_red", seg=8, rings=6)


def leaderboard_row(F):
    """Showcase helper: the two boards of one side."""
    leaderboard(F.sub(-8, 0), "RICHEST FIRMS")
    leaderboard(F.sub(8, 0), "MOST CASES WON")


# ------------------------------------------------------------------ 10. example firms (DYNAMIC: the game builds the real ones)
# Lot frame: local y = 0 is the lot's street edge, the lot runs to +y; front = -y. Like FirmBuilder: porch y 0..6,
# lobby (the stage's front building) y 6..27, then the open-roof office hall, 11 studs per segment, + a 3-stud back.
def _hall(F, segments, wall, trim, floor="floor"):
    y0, y1 = 27, 27 + 11 * segments + 3
    F.brick(0, (y0 + y1) / 2, 1.5, 48, y1 - y0, 0.4, floor)
    for sx in (-1, 1):
        F.brick(sx * 23.6, (y0 + y1) / 2, 1.5, 0.8, y1 - y0, 7.5, wall, studs=False)
        F.brick(sx * 23.6, (y0 + y1) / 2, 9.0, 1.2, y1 - y0 + 0.4, 0.6, trim)
        for k in range(segments):
            yy = y0 + 5.5 + k * 11
            K.window(F.sub(sx * 24.05, yy, rot=90 * sx), 0, 0, 4.0, 5, 3.6, 0, frame=trim, depth=0.5)
    F.brick(0, y1 - 0.4, 1.5, 48, 0.8, 7.5, wall, studs=False)
    F.brick(0, y1 - 0.4, 9.0, 48.4, 1.2, 0.6, trim)
    for k in range(segments):  # two offices per segment, desks facing the aisle (x = 0)
        yy = y0 + 5.5 + k * 11
        for sx in (-1, 1):
            x = sx * 15.5
            F.brick(x, yy, 1.9, 6, 3, 2.2, "wood", studs=False)
            F.brick(x, yy, 4.1, 6.4, 3.4, 0.4, "wood_dark")
            F.brick(x + sx * 0.6, yy + 0.6, 4.5, 2.2, 0.3, 1.6, "black", studs=False)
            F.brick(x + sx * 0.6, yy + 0.45, 4.6, 1.9, 0.1, 1.3, "glow_cyan", studs=False, bevel=0.01)
            F.brick(x + sx * 3.4, yy, 1.9, 1.6, 1.6, 2.6, "roof_navy", studs=False)  # chair
            F.brick(sx * 9.5, yy - 5.5, 1.9, 0.6, 9, 2.8, "glass", studs=False, bevel=0.0)  # divider
            K.planter(F.sub(0, 0, z=1.9), sx * 21.5, yy + 4, 1.6, 1.6)
    F.brick(0, (y0 + y1) / 2, 1.9, 4, y1 - y0 - 2, 0.06, "red", studs=False, bevel=0.01)  # aisle carpet


def _porch(F, look="stone"):
    F.brick(0, 3, 0, 52, 6, 0.4, look)
    K.stairs(F, 0, 0.2, 0, 14, 3, 0.5, 1.6, 90, look="white")


def firm_main_street(F, segments=6, name="YOUR FIRM"):
    """Stage 3 'Main Street Firm': red brick, three storeys, white trim, columns, a studded roof terrace."""
    F.brick(0, 4 + 11 * segments / 2 + 13, 0, 50, 27 + 11 * segments + 1, 1.5, "stone")
    _porch(F)
    F.brick(0, 16.5, 1.5, 48, 21, 20, "brick_red", studs=False)
    for z in (8.2, 14.6):
        F.brick(0, 16.5, z, 48.6, 21.6, 0.6, "white", studs=False)
    F.brick(0, 16.5, 21.5, 49.4, 22.4, 1.0, "white", studs=False)
    F.brick(0, 16.5, 22.5, 47, 20, 0.5, "stone_warm")  # roof terrace
    for x in (-23, 23):
        F.brick(x, 6, 22.5, 1.0, 1.0, 1.6, "white", studs=False)
    K.railing(F, -23, 6.2, 23, 6.2, 22.5, 1.6, "white", post_every=4)
    for fl in range(3):
        for x in (-18, -10.5, 10.5, 18):
            K.window(F, x, 5.95, 3.4 + fl * 6.4, 3.6, 4.0, 0, frame="white", shutters="roof_navy" if fl else None)
    for x in (-5, 5):
        K.column(F, x, 4.2, 1.5, 9, 1.4)
    F.brick(0, 4.2, 10.5, 13, 3.2, 0.8, "white", studs=False)
    K.door(F, 0, 5.95, 1.5, 5, 7.4, 0, frame="gold", leaf="wood_dark", arch=True)
    F.brick(0, 5.6, 15.4, 22, 0.6, 3.6, "roof_navy", studs=False)
    F.brick(0, 5.5, 15.1, 22.6, 0.7, 0.4, "gold", studs=False)
    F.brick(0, 5.5, 18.9, 22.6, 0.7, 0.4, "gold", studs=False)
    F.text(name, 0, 5.15, 17.2, 2.0, "gold", kind="bold", extrude=0.12)
    for x in (-14, 14):
        K.lamp(F, x, 1.2, 9)
    _hall(F, segments, "brick_red", "white")


def firm_glass_office(F, segments=8, name="YOUR FIRM"):
    """Stage 4 'Glass Office': four storeys of blue glass in a white grid, a canopy, a roof garden."""
    F.brick(0, 4 + 11 * segments / 2 + 13, 0, 50, 27 + 11 * segments + 1, 1.5, "stone")
    _porch(F, "marble")
    H = 32
    F.brick(0, 16.5, 1.5, 47, 20, H, "glass_dark", studs=False, bevel=0.0)
    for k in range(5):  # white floor bands
        F.brick(0, 16.5, 1.5 + k * 7.8, 48.2, 21.2, 0.7, "white", studs=False)
    for k in range(13):  # mullions on the front + sides
        x = -24 + k * 4
        F.brick(x, 6.2, 1.5, 0.5, 0.6, H, "white", studs=False)
    for sx in (-1, 1):
        for k in range(6):
            F.brick(sx * 23.9, 7 + k * 3.8, 1.5, 0.6, 0.5, H, "white", studs=False)
    F.brick(0, 16.5, 1.5 + H, 48.6, 21.6, 1.0, "white", studs=False)
    F.brick(0, 16.5, 2.5 + H, 46, 19, 0.6, "grass")  # roof garden
    for x in (-16, -6, 6, 16):
        K.bush(F.sub(0, 0, z=3.1 + H), x, 16 + (x % 3), 0.8)
    F.brick(0, 3.0, 8.2, 18, 6, 0.6, "white", studs=False)  # canopy
    for x in (-8, 8):
        F.brick(x, 0.6, 1.5, 0.6, 0.6, 6.7, "metal", studs=False)
    K.door(F, 0, 6.0, 1.5, 6, 6.5, 0, frame="metal", leaf="glass", depth=0.6)
    F.brick(0, 5.7, 26.5, 26, 0.6, 3.6, "white", studs=False)
    F.text(name, 0, 5.3, 28.3, 2.2, "roof_blue", kind="bold", extrude=0.12)
    _hall(F, segments, "white", "roof_blue")


def firm_supreme_tower(F, segments=10, name="YOUR FIRM"):
    """Stage 6 'Supreme Tower' (after Rebirth): glass podium + a 12-storey tower with gold bands, crown, spire."""
    F.brick(0, 4 + 11 * segments / 2 + 13, 0, 50, 27 + 11 * segments + 1, 1.5, "stone")
    _porch(F, "marble")
    Fl = 9.6
    F.brick(0, 16.5, 1.5, 48, 21, 2 * Fl, "glass", studs=False, bevel=0.0)
    for k in range(3):
        F.brick(0, 16.5, 1.5 + k * Fl, 48.8, 21.8, 0.8, "gold" if k else "marble", studs=False)
    for k in range(9):
        F.brick(-24 + k * 6, 6.2, 1.5, 0.8, 0.8, 2 * Fl, "white", studs=False)
    F.brick(0, 16.5, 1.5 + 2 * Fl + 0.8, 47, 20, 0.5, "marble")
    T0, T1 = 1.5 + 2 * Fl + 0.45, 1.5 + 2 * Fl + 0.45 + 108
    F.brick(0, 17.0, T0, 40, 17, T1 - T0, "glass_dark", studs=False, bevel=0.0)
    for k in range(13):
        F.brick(0, 17.0, T0 + (T1 - T0) * k / 12 - 0.4, 40.8, 17.8, 0.8, "gold", studs=False)
    for k in range(11):
        F.brick(-20 + k * 4, 8.4, T0, 0.5, 0.6, T1 - T0, "roof_navy", studs=False)
    F.brick(0, 9.0, T1 - 18, 39, 0.4, 17.6, "glow_warm", studs=False, bevel=0.0)  # lit penthouse
    F.brick(0, 17.0, T1, 36, 15, 5, "gold")
    F.cyl(9, 17.5, 6.8, T1 + 5, T1 + 5.8, "black", segs=24)
    F.ring(5.0, 5.6, T1 + 5.8, T1 + 6.0, "yellow", cx=9, cy=17.5, segs=24)
    F.cyl(-15, 21, 0.5, T1 + 5, T1 + 31, "gold", segs=8)
    F.sphere(-15, 21, T1 + 31.6, 0.9, 0.9, 0.9, "glow_red", seg=10, rings=6)
    F.brick(0, 3.2, 9.6, 28, 6.4, 1.0, "gold", studs=False)  # canopy
    K.door(F, 0, 6.0, 1.5, 8, 7.4, 0, frame="gold", leaf="glass", depth=0.7)
    F.brick(0, 5.7, 12.0, 30, 0.6, 3.8, "black", studs=False)
    F.text(name, 0, 5.3, 13.9, 2.4, "gold", kind="bold", extrude=0.12)
    _hall(F, segments, "marble", "gold")


def lot_sign(F):
    """An empty lot (the game's LotSign shows on unclaimed plots)."""
    wood_sign(F, 0, 14, 4.0, 12, 3.4, "EMPTY LOT", size=1.6)
    for sgn in (-1, 1):
        F.brick(sgn * 5.6, 14.3, 0, 0.8, 0.8, 7.4, "wood_dark", studs=False)
    for k in range(5):
        F.brick(-8 + k * 4, 22, 0, 2.0, 2.0, 2.0, "wood", rot=k * 11)
