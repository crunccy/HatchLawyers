# environment-redesign/ocean_shore/os_parts.py - Ocean Shore's models (Stage 5, island 5, 2026-10-19, mr.robe's session).
# A sunny tropical beach (the game's zone: Ocean Shore, the Ocean egg, Magistrate Megalodon). Palette: sand + sea blues
# + turquoise, with coral / sunny accents (red-white lighthouse, striped umbrellas, surfboards). Local frames: front =
# local -y. Round things are studded VOXEL rounds (stacked rings, studs on each exposed ledge); only glowing bulbs and
# flames are smooth balls.
# Static props never use the canopy looks (leaf / leaf_light / leaf_deep / blossom): the ambience wind sways those
# looks' studs island-wide. Sea greens here are "kelp" / "seafoam", never "leaf".
import math
import hl_kit as K
import hl_world as W

rng = K.rng
polar = W.polar

K.PAL.update({
    "sand_wet": (222, 198, 146), "sand_pink": (252, 214, 200), "driftwood": (184, 152, 118), "thatch": (226, 184, 98),
    "thatch_dark": (176, 134, 62), "bamboo": (214, 196, 110), "bamboo_dark": (160, 140, 70), "plank": (206, 148, 92),
    "plank_dark": (150, 100, 62), "rope": (220, 192, 136), "coral": (255, 112, 96), "coral_pink": (255, 150, 180),
    "coral_purple": (176, 96, 220), "coral_orange": (255, 160, 60), "coral_yellow": (255, 214, 80), "kelp": (56, 150, 96),
    "seafoam": (130, 226, 204), "shell_pink": (255, 200, 196), "shell_cream": (255, 238, 216), "starfish": (255, 128, 64),
    "crab": (232, 74, 52), "urchin": (84, 48, 110), "whale": (62, 112, 196), "whale_belly": (226, 236, 244),
    "hull_blue": (40, 110, 200), "hull_red": (210, 60, 52), "pastel_mint": (170, 236, 210), "pastel_peach": (255, 206, 170),
    "pastel_blue": (170, 214, 250), "pastel_yellow": (255, 236, 160), "navy": (32, 52, 104), "ocean_egg": (60, 170, 230),
    "fish_orange": (255, 130, 30), "fish_blue": (70, 150, 240), "plum": (150, 40, 90),
})
K.GLASS.update({"lagoon": (60, 206, 222), "rockpool": (70, 178, 214), "spout": (200, 238, 255), "beam_light": (255, 240, 190)})
UMBRELLAS = (("red", "white"), ("sky_blue", "white"), ("yellow", "coral"), ("teal", "white"), ("coral_pink", "white"))
CORALS = ("coral", "coral_pink", "coral_purple", "coral_orange", "coral_yellow")


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


def bamboo(F, x, y, z0, z1, r=0.4):
    """A bamboo pole: segments with darker joints."""
    z = z0
    while z < z1 - 0.05:
        top = min(z1, z + 1.4)
        F.cyl(x, y, r, z, top - 0.15, "bamboo", segs=8)
        F.cyl(x, y, r + 0.08, top - 0.15, top, "bamboo_dark", segs=8)
        z = top


# ------------------------------------------------------------------ beach props
def surfboard(F, x, y, z0=0.0, L=12.0, w=3.4, body="sky_blue", stripe="white", rot=0.0, depth=0.7):
    """An upright surfboard (stuck in the sand / a gate pillar): rounded nose and tail, a stripe down the middle."""
    G = F.sub(x, y, rot)
    n = max(6, int(L / 0.8))
    cell = L / n
    rows = []
    for k in range(n):
        t = (k + 0.5) / n
        hw = max(0.35, w / 2 * max(0.0, 1 - abs(2 * t - 1) ** 2.4) ** 0.5)
        s = min(0.35, hw * 0.4)
        rows.append([(-hw, -s, body), (-s, s, stripe), (s, hw, body)])
    pixel_rows(G, rows, cell, depth, z0=z0)


def surfboard_flat(F, x, y, L=9.0, w=2.6, body="coral", stripe="white", rot=0.0):
    """A surfboard lying on the sand (along local y)."""
    G = F.sub(x, y, rot)
    n = max(6, int(L / 0.8))
    cell = L / n
    for k in range(n):
        t = (k + 0.5) / n
        hw = max(0.3, w / 2 * max(0.0, 1 - abs(2 * t - 1) ** 2.4) ** 0.5)
        ly = -L / 2 + (k + 0.5) * cell
        G.brick(0, ly, 0, 2 * hw, cell, 0.45, body, studs=False, bevel=0.04)
        G.brick(0, ly, 0.45, min(0.6, 2 * hw), cell, 0.06, stripe, studs=False, bevel=0.0)


def umbrella(F, x, y, looks=("red", "white"), h=7.0, R=4.6, towel=True, rot=0.0):
    """A striped beach umbrella (stepped canopy) over a striped towel."""
    G = F.sub(x, y, rot)
    if towel:
        for k in range(5):
            G.brick(1.6, -3 + k * 1.2, 0, 3.2, 1.2, 0.2, looks[k % 2], studs=False, bevel=0.0)
    G.cyl(0, 0, 0.22, 0, h, "white", segs=6)
    taper(G, 0, 0, h - 1.6, R, 0.5, 1.8, looks[0], step=0.45, segs=20,
          looks=lambda k: looks[k % 2])
    G.sphere(0, 0, h + 0.3, 0.35, 0.35, 0.35, looks[0], seg=8, rings=5)


def deck_chair(F, x, y, rot=0.0, look="sky_blue"):
    """A low striped deck chair (seat + a stepped backrest), facing local -y."""
    G = F.sub(x, y, rot)
    for sx in (-1, 1):
        G.brick(sx * 1.2, 0, 0, 0.3, 4.6, 0.6, "white", studs=False)
    for k in range(3):
        G.brick(0, -1.4 + k * 1.1, 0.6, 2.6, 1.1, 0.25, look if k % 2 == 0 else "white", studs=False, bevel=0.03)
    for k in range(4):
        G.brick(0, 2.0 + k * 0.35, 0.85 + k * 0.6, 2.6, 0.45, 0.6, look if k % 2 == 0 else "white", studs=False, bevel=0.03)


def beach_ball(F, x, y, r=1.2):
    ball(F, x, y, 0, r, "red", step=r / 3.5, studs=False, looks=lambda k: ("red", "white", "yellow", "white", "sky_blue", "white", "red")[k % 7])


def sandcastle(F, x, y, s=1.0, look="sand", flag="red"):
    """A chunky sandcastle: two tiers, four corner towers with crenellations, a door, a flag on the keep."""
    G = F.sub(x, y, rng.uniform(0, 90))
    G.brick(0, 0, 0, 8 * s, 8 * s, 2.4 * s, look)
    G.brick(0, 0, 2.4 * s, 5 * s, 5 * s, 2.2 * s, look)
    for sx in (-1, 1):
        for sy in (-1, 1):
            G.cyl(sx * 3.6 * s, sy * 3.6 * s, 1.4 * s, 0, 4.0 * s, look, segs=12)
            for k in range(4):
                a = k * 90 + 45
                px, py = polar(1.1 * s, a)
                G.brick(sx * 3.6 * s + px, sy * 3.6 * s + py, 4.0 * s, 0.7 * s, 0.7 * s, 0.7 * s, look, rot=a, studs=False)
    G.cyl(0, 0, 1.6 * s, 4.6 * s, 7.0 * s, look, segs=14)
    taper(G, 0, 0, 7.0 * s, 1.8 * s, 0.4 * s, 1.8 * s, look, step=0.45 * s, segs=14)
    G.brick(0, -4.05 * s, 0, 1.6 * s, 0.2, 1.8 * s, "sand_wet", studs=False)
    G.cyl(0, 0, 0.12, 8.6 * s, 10.6 * s, "white", segs=6)
    G.brick(0.7, 0, 9.6 * s, 1.2, 0.12, 0.8, flag, studs=False, bevel=0.02)


def bucket(F, x, y, look="red", rot=0.0):
    G = F.sub(x, y, rot)
    taper(G, 0, 0, 0, 0.9, 1.2, 1.8, look, step=0.45, segs=12, studs=False)
    G.ring_v(0, 0, 1.8, 1.0, 1.2, 0.15, "white", segs=8, a0=0, a1=180)
    G.brick(2.0, 0.4, 0, 0.5, 2.2, 0.2, "yellow", rot=30, studs=False)  # the spade
    G.brick(2.6, 1.6, 0, 1.0, 1.0, 0.2, "yellow", rot=30, studs=False)


def life_ring(F, x, y, z, R=1.6, rot=0.0):
    """An upright red-and-white life ring (centre z)."""
    F.ring_v(x, y, z, R * 0.55, R, 0.5, ["red", "white"], rot=rot, segs=8, gap=0.08)


def starfish(F, x, y, z=0.0, s=1.0, look="starfish", rot=None):
    """A starfish lying flat: five tapering arms + a body, little dots on top."""
    rot = rng.uniform(0, 72) if rot is None else rot
    F.cyl(x, y, 0.9 * s, z, z + 0.45 * s, look, segs=10)
    for k in range(5):
        a = rot + k * 72
        for j, (d, w) in enumerate(((1.2, 0.9), (2.2, 0.62))):
            px, py = polar(d * s, a)
            F.brick(x + px, y + py, z, 1.2 * s, w * s, (0.42 - j * 0.08) * s, look, rot=a, studs=False, bevel=0.1 * s)
        dx, dy = polar(1.6 * s, a)
        F.brick(x + dx, y + dy, z + 0.4 * s, 0.25 * s, 0.25 * s, 0.1 * s, "cream", studs=False, bevel=0.03)


def starfish_upright(F, x, y, z0, s=1.0, look="starfish", depth=0.8):
    """A star standing up (pixel rows): the gate's crest."""
    G = F.sub(x, y)
    c = 0.7 * s
    spans = ((-2.6, -1.2, 1.2, 2.6), (-2.1, -0.5, 0.5, 2.1), (-1.6, 1.6), (-4.2, 4.2), (-3.0, 3.0), (-1.4, 1.4), (-0.9, 0.9), (-0.45, 0.45))
    rows = []
    for sp in spans:
        rows.append([(sp[i] * s, sp[i + 1] * s, look) for i in range(0, len(sp), 2)])
    pixel_rows(G, rows, c, depth, z0=z0)


def shell(F, x, y, z0=0.0, R=3.0, looks=("shell_pink", "shell_cream"), rot=0.0, depth=1.2):
    """A giant scallop shell standing on its hinge: a ribbed fan (alternating looks) + the hinge 'ears'."""
    G = F.sub(x, y, rot)
    G.ring_v(0, 0, z0 + 0.6, R * 0.3, R, depth, list(looks), segs=9, gap=0.14, a0=0, a1=180)
    G.ring_v(0, 0, z0 + 0.6, 0.2, R * 0.32, depth * 0.9, looks[1], segs=3, gap=0.05, a0=0, a1=180)
    G.brick(0, 0, z0, R * 0.9, depth * 1.1, 0.8, looks[0], studs=False, bevel=0.15)


def coral_branch(F, x, y, s=1.0, look="coral"):
    """Branching coral: a short trunk forking upward into nubbly tips."""
    G = F.sub(x, y, rng.uniform(0, 90))
    G.brick(0, 0, 0, 1.6 * s, 1.6 * s, 2.0 * s, look, studs=False, bevel=0.3 * s)
    for k in range(5):
        a = k * 72 + rng.uniform(-15, 15)
        lean = rng.uniform(0.6, 1.4)
        h = rng.uniform(3.0, 5.0) * s
        for j in range(3):
            px, py = polar(lean * (j + 1) * 0.6 * s, a)
            G.brick(px, py, (1.6 + j * h / 3) * s, (1.0 - j * 0.18) * s, (1.0 - j * 0.18) * s, h / 3 + 0.4 * s, look, studs=False, bevel=0.25 * s)
        tx, ty = polar(lean * 2.0 * s, a)
        G.sphere(tx, ty, 1.6 * s + h + 0.2 * s, 0.55 * s, 0.55 * s, 0.55 * s, look, seg=8, rings=5)


def coral_fan(F, x, y, R=4.0, look="coral_purple", rot=None):
    """A sea fan: an upright lattice half-disc (gapped ring blocks) on a stub."""
    rot = rng.uniform(0, 180) if rot is None else rot
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, 1.0, 1.0, 1.2, look, studs=False)
    for k, (r0, r1) in enumerate(((0.6, 1.6), (1.9, 2.8), (3.1, R))):
        G.ring_v(0, 0, 1.0, r0, r1, 0.4, look, segs=5 + k * 3, gap=0.35, a0=10, a1=170)


def brain_coral(F, x, y, r=2.6, look="coral_yellow"):
    dome(F, x, y, 0, r, r * 0.9, look, step=0.4, segs=18, looks=lambda k: look if k % 2 == 0 else "coral_orange")


def tube_coral(F, x, y, look="coral_pink"):
    for k in range(6):
        px, py = polar(rng.uniform(0, 1.6), rng.uniform(0, 360))
        h = rng.uniform(1.6, 4.0)
        F.cyl(x + px, y + py, 0.55, 0, h, look, segs=8)
        F.ring(0.3, 0.6, h, h + 0.12, "plum" if look != "coral_purple" else "white", cx=x + px, cy=y + py, segs=8)


def anemone(F, x, y, s=1.0, look="coral_pink"):
    F.cyl(x, y, 1.1 * s, 0, 0.9 * s, "seafoam", segs=12)
    for k in range(12):
        px, py = polar(rng.uniform(0.2, 0.9) * s, k * 30 + rng.uniform(-10, 10))
        F.brick(x + px, y + py, 0.9 * s, 0.25 * s, 0.25 * s, rng.uniform(0.8, 1.6) * s, look, studs=False, bevel=0.08)
        F.sphere(x + px, y + py, 0.9 * s + 1.7 * s, 0.2 * s, 0.2 * s, 0.2 * s, "white", seg=6, rings=4)


def kelp(F, x, y, h=7.0):
    """A kelp stalk: offset studless blocks swaying a little up its height (static; "kelp", never a canopy look)."""
    for k in range(int(h / 1.2)):
        off = math.sin(k * 0.9) * 0.4
        F.brick(x + off, y, k * 1.2, 0.8, 0.5, 1.25, "kelp", rot=k * 12, studs=False, bevel=0.1)
        if k % 2:
            F.brick(x + off + 0.7, y, k * 1.2 + 0.4, 1.2, 0.3, 0.5, "kelp", rot=k * 12 + 30, studs=False, bevel=0.05)


def treasure_chest(F, x, y, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, 4.4, 2.8, 2.2, "wood_dark", studs=False)
    for sx in (-1.6, 0, 1.6):
        G.brick(sx, 0, 0, 0.35, 3.0, 2.3, "gold", studs=False)
    G.brick(0, 0.9, 2.2, 4.4, 1.0, 2.2, "wood_dark", studs=False)  # the lid, tipped open (standing at the back)
    for k in range(9):
        px, py = rng.uniform(-1.8, 1.8), rng.uniform(-1.0, 0.2)
        G.cyl(px, py, 0.45, 2.2, 2.4 + k * 0.05, "gold", segs=8)
    G.brick(0, -1.45, 1.4, 0.7, 0.2, 0.7, "gold", studs=False)


def crab(F, x, y, s=1.0, rot=None):
    """A chunky red crab: a flat body, eyes on stalks, two big claws, legs."""
    rot = rng.uniform(0, 360) if rot is None else rot
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0.5 * s, 3.0 * s, 2.2 * s, 1.0 * s, "crab", studs=False, bevel=0.3 * s)
    G.brick(0, 0, 1.5 * s, 2.0 * s, 1.4 * s, 0.4 * s, "crab", studs=False, bevel=0.15 * s)
    for sx in (-1, 1):
        G.brick(sx * 0.6 * s, -0.9 * s, 1.5 * s, 0.25 * s, 0.25 * s, 0.9 * s, "crab", studs=False)
        G.brick(sx * 0.6 * s, -0.9 * s, 2.4 * s, 0.5 * s, 0.5 * s, 0.5 * s, "white", studs=False, bevel=0.15 * s)
        G.brick(sx * 0.6 * s, -1.12 * s, 2.5 * s, 0.25 * s, 0.1, 0.25 * s, "black", studs=False)
        G.brick(sx * 2.0 * s, -1.4 * s, 0.6 * s, 0.6 * s, 1.4 * s, 0.6 * s, "crab", rot=sx * 30, studs=False)
        G.brick(sx * 2.4 * s, -2.4 * s, 0.4 * s, 1.4 * s, 1.2 * s, 1.0 * s, "crab", rot=sx * 20, studs=False, bevel=0.3 * s)
        for k in range(3):
            G.brick(sx * 1.9 * s, (0.2 + k * 0.6) * s, 0, 1.4 * s, 0.3 * s, 0.5 * s, "crab", rot=sx * (10 - k * 20), studs=False)


def urchin(F, x, y, r=1.0):
    ball(F, x, y, 0, r, "urchin", step=r / 2.5, studs=False)
    for k in range(14):
        a = k * 360 / 14 + rng.uniform(-8, 8)
        z = r * rng.uniform(0.5, 1.5)
        px, py = polar(r * 0.9, a)
        F.brick(x + px, y + py, z, 1.4 * r, 0.12, 0.12, "urchin", rot=a, studs=False, bevel=0.02)


def rock_pool(F, x, y, R=5.0):
    """A tide pool: a ring of chunky rocks round a little pool of clear water with a starfish in it."""
    F.cyl(x, y, R, 0, 0.25, "rockpool", segs=28)
    a = 0.0
    while a < 360:
        w = rng.uniform(1.6, 3.0)
        px, py = polar(R + 0.6, a)
        F.brick(x + px, y + py, 0, rng.uniform(1.4, 2.2), w, rng.uniform(0.8, 1.8), rng.choice(["rock", "rock_dark", "rock_warm"]), rot=a,
                studs=w > 2)
        a += math.degrees(w / (R + 0.6)) * 0.95
    starfish(F, x + rng.uniform(-R * 0.4, R * 0.4), y + rng.uniform(-R * 0.4, R * 0.4), 0.05, 0.6, rng.choice(["starfish", "coral_pink", "coral_yellow"]))


def driftwood(F, x, y, L=6.0, rot=0.0):
    G = F.sub(x, y, rot)
    G.brick(0, 0, 0, L, 1.1, 0.9, "driftwood", studs=False, bevel=0.3)
    G.brick(L * 0.3, 0.6, 0.3, 2.0, 0.5, 0.5, "driftwood", rot=35, studs=False, bevel=0.15)


def rowboat(F, x, y, rot=0.0, hull="hull_blue", trim="white", L=9.0, Wd=3.6, z=0.0):
    """A little rowboat (along local y): a stepped hull narrowing to the bow, gunwale trim, two seats, oars."""
    G = F.sub(x, y, rot, z=z)
    n = int(L / 1.0)
    for k in range(n):
        t = (k + 0.5) / n
        w = Wd * (1 - max(0.0, (t - 0.55) / 0.45) ** 1.6 * 0.85) * (1 - max(0.0, (0.15 - t) / 0.15) * 0.15)
        ly = -L / 2 + (k + 0.5) * L / n
        G.brick(0, ly, 0, w * 0.75, L / n, 0.6, hull, studs=False, bevel=0.05)
        G.brick(0, ly, 0.6, w, L / n, 1.0, hull, studs=False, bevel=0.05)
        G.brick(0, ly, 1.6, w + 0.2, L / n, 0.25, trim, studs=False, bevel=0.03)
        if w > 1.2:
            G.brick(0, ly, 0.6, w - 0.8, L / n + 0.02, 0.9, "plank", studs=False, bevel=0.0)  # the inside floor
    for ly in (-1.6, 1.2):
        G.brick(0, ly, 1.2, Wd - 0.6, 0.8, 0.25, "plank_dark", studs=False)
    for sx in (-1, 1):
        G.brick(sx * (Wd / 2 + 0.3), 0, 1.7, 0.25, 5.0, 0.2, "wood", rot=sx * 8, studs=False)


def sailboat(F, x, y, rot=0.0, hull="hull_red", sail="white", stripe="sky_blue", z=0.0):
    """A dinghy with a mast and a stepped triangular sail (pixel rows along the boat)."""
    rowboat(F, x, y, rot, hull=hull, L=11.0, Wd=4.2, z=z)
    G = F.sub(x, y, rot + 90, z=z)
    G.cyl(-0.6, 0, 0.22, 0.6, 12.0, "wood_dark", segs=6)
    rows = []
    for k in range(10):
        span = 4.6 * (1 - k / 10)
        rows.append([(-0.4, -0.4 + span, sail if k % 4 != 1 else stripe)])
    pixel_rows(G, rows, 1.0, 0.25, z0=2.0)
    G.brick(1.6, 0, 1.9, 4.4, 0.3, 0.3, "wood_dark", studs=False)  # the boom


def buoy(F, x, y, look="red", z=0.0):
    F.cyl(x, y, 1.0, z, z + 0.9, look, segs=12)
    F.cyl(x, y, 1.05, z + 0.9, z + 1.3, "white", segs=12)
    F.cone(x, y, 0.9, z + 1.3, z + 3.0, look, segs=8)
    F.sphere(x, y, z + 3.3, 0.35, 0.35, 0.35, "glow_warm", seg=8, rings=5)


def bollard(F, x, y, z=0.0):
    F.cyl(x, y, 0.55, z, z + 1.1, "black", segs=10)
    F.cyl(x, y, 0.75, z + 1.1, z + 1.35, "black", segs=10)


def crate(F, x, y, z=0.0, s=1.0, rot=0.0):
    G = F.sub(x, y, rot, z=z)
    G.brick(0, 0, 0, 2.4 * s, 2.4 * s, 2.4 * s, "wood")
    for sgn in (-1, 1):
        G.brick(0, sgn * 1.22 * s, 0.3 * s, 2.2 * s, 0.1, 0.4 * s, "wood_dark", studs=False)
        G.brick(0, sgn * 1.22 * s, 1.7 * s, 2.2 * s, 0.1, 0.4 * s, "wood_dark", studs=False)


def fishing_net(F, x, y, rot=0.0, w=6.0, h=4.0):
    """A net hung to dry on two posts: a grid of thin rope strands, two cork floats."""
    G = F.sub(x, y, rot)
    for sx in (-1, 1):
        G.brick(sx * w / 2, 0, 0, 0.5, 0.5, h + 1.0, "driftwood", studs=False)
    for k in range(int(w / 0.8) + 1):
        G.brick(-w / 2 + k * 0.8, 0, 0.8, 0.08, 0.08, h - 0.4 - 0.4 * math.sin(math.pi * k / (w / 0.8)), "rope", studs=False, bevel=0.0)
    for j in range(int(h / 0.8)):
        G.brick(0, 0, 0.8 + j * 0.8, w, 0.08, 0.08, "rope", studs=False, bevel=0.0)
    for sx in (-1.4, 1.6):
        G.sphere(sx, -0.1, 2.4, 0.4, 0.4, 0.4, "coral_orange", seg=8, rings=5)


def anchor(F, x, y, s=1.0, rot=0.0, z=0.0):
    """A big anchor standing up (pixel rows): shank, ring, stock, curved arms with flukes."""
    G = F.sub(x, y, rot, z=z)
    c = 0.6 * s
    rows = [[(-3.0, -1.8), (1.8, 3.0)], [(-2.8, -1.0), (1.0, 2.8)], [(-1.8, 1.8)], [(-0.4, 0.4)], [(-0.4, 0.4)], [(-0.4, 0.4)],
            [(-0.4, 0.4)], [(-2.0, 2.0)], [(-0.4, 0.4)], [(-0.9, -0.4), (0.4, 0.9)], [(-0.7, 0.7)]]
    pixel_rows(G, [[(a * s, b * s, "metal_dark") for a, b in r] for r in rows], c, 0.7 * s)


def lifeguard_tower(F, x, y, rot=0.0):
    """Stilts, a platform with a red-and-white hut, a ramp, a flag and a life ring."""
    G = F.sub(x, y, rot)
    for sx in (-1, 1):
        for sy in (-1, 1):
            G.brick(sx * 2.6, sy * 2.6, 0, 0.6, 0.6, 6.0, "white", studs=False)
    G.brick(0, 0, 6.0, 7.4, 7.4, 0.6, "plank")
    for k in range(5):
        G.brick(-2.4 + k * 1.2, 0.6, 6.6, 1.2, 4.8, 4.4, "red" if k % 2 == 0 else "white", studs=False)
    G.roof_hip(0, 0.6, 11.0, 6.4, 5.6, 1.8, "red", courses=3, overhang=0.6, trim="white")
    G.brick(0, -3.5, 6.6, 7.4, 0.3, 1.2, "white", studs=False)  # the railing at the front
    for k in range(6):  # the ramp down the front
        G.brick(0, -4.4 - k * 1.2, 5.4 - k * 1.0, 2.4, 1.2, 0.4, "plank", studs=False)
    life_ring(G, 2.2, -3.8, 8.6, R=1.1)
    G.cyl(-3.4, 2.8, 0.15, 6.6, 15.0, "white", segs=6)
    G.brick(-2.4, 2.8, 13.4, 2.0, 0.12, 1.4, "red", studs=False, bevel=0.02)


def tiki_lamp(F, x, y, h=7.5):
    """The island's lamp post: a bamboo tiki torch with a woven cup and a warm flame."""
    bamboo(F, x, y, 0, h, r=0.38)
    taper(F, x, y, h, 0.6, 1.0, 1.0, "thatch_dark", step=0.33, segs=10, studs=False)
    F.sphere(x, y, h + 1.5, 0.6, 0.6, 0.85, "glow_warm", seg=10, rings=6)


def bunting(F, a, b, n=12, sag=1.4, looks=("red", "yellow", "sky_blue", "white", "coral_pink")):
    """Little pennant flags on a sagging line between two points (x, y, z)."""
    rot = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
    for k in range(1, n):
        t = k / n
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        z = a[2] + (b[2] - a[2]) * t - sag * 4 * t * (1 - t)
        F.brick(x, y, z - 0.9, 0.7, 0.08, 0.9, looks[k % len(looks)], rot=rot, studs=False, bevel=0.02)
        F.brick(x, y, z - 1.4, 0.35, 0.08, 0.5, looks[k % len(looks)], rot=rot, studs=False, bevel=0.02)


def fish(F, z0, L=8.0, body="fish_orange", stripe="white", depth=1.2):
    """An upright pixel fish facing local +x (a sign): oval body with stripes, a tail fan, an eye on both faces."""
    c = L / 10
    rows = []
    prof = (0.9, 1.6, 2.0, 2.2, 2.2, 2.0, 1.6, 0.9)
    for k, hh in enumerate(prof):
        x0, x1 = -hh * 1.6 * c, hh * 1.6 * c + 0.6 * c
        tail = (-(hh * 1.6 + 2.8) * c, -(hh * 1.6 + 0.6) * c, body) if k in (0, 1, 6, 7) else None
        row = [(x0, x0 + (x1 - x0) * 0.38, body), (x0 + (x1 - x0) * 0.38, x0 + (x1 - x0) * 0.5, stripe), (x0 + (x1 - x0) * 0.5, x1, body)]
        if tail:
            row.append(tail)
        rows.append(row)
    pixel_rows(F, rows, c, depth, z0=z0)
    for sgn in (-1, 1):
        F.brick(1.9 * c * 1.6, sgn * (depth / 2 + 0.04), z0 + 4.6 * c, 1.2 * c, 0.12, 1.2 * c, "white", studs=False, bevel=0.03)
        F.brick(2.1 * c * 1.6, sgn * (depth / 2 + 0.1), z0 + 4.7 * c, 0.6 * c, 0.12, 0.6 * c, "black", studs=False, bevel=0.02)


# ------------------------------------------------------------------ the plaza: whale fountain + beach shacks
def whale_fountain(F):
    """A round pool with Big Blue swimming through it: a studded voxel back with a white belly line, a smiling face,
    a blowhole spouting a water column (spray in the ambience), and the tail rising from the water behind, dripping."""
    F.cyl(0, 0, 11, 0, 1.4, "stone", segs=40, studs=True)
    F.ring(10.0, 11.2, 1.4, 2.0, "sky_blue", segs=40)
    F.cyl(0, 0, 10.0, 0.8, 1.3, "lagoon", segs=40)
    for (x, r, h) in ((-2.6, 4.2, 4.0), (0.6, 4.8, 5.2), (3.8, 3.8, 4.0)):
        dome(F, x, 0, 1.0, r, h, "whale", step=0.5, segs=22, looks=lambda k: "whale_belly" if k == 0 else "whale")
    for sgn in (-1, 1):  # big eyes + a smile on the head's front (+x), pectoral fins out of the water
        F.brick(6.5, sgn * 1.9, 2.4, 1.3, 1.3, 1.3, "white", rot=sgn * 30, studs=False, bevel=0.12)
        F.brick(7.05, sgn * 2.05, 2.75, 0.6, 0.6, 0.6, "black", rot=sgn * 30, studs=False, bevel=0.05)
        F.brick(2.8, sgn * 5.2, 1.0, 3.4, 2.2, 0.6, "whale", rot=sgn * 28, studs=False, bevel=0.2)
    F.brick(7.2, 0, 1.6, 0.4, 2.6, 0.3, "navy", studs=False, bevel=0.05)
    F.cyl(0.8, 0, 0.6, 6.0, 6.3, "navy", segs=10)  # the blowhole + its spout
    F.cyl(0.8, 0, 0.55, 6.2, 14.0, "spout", segs=12)
    for k in range(8):
        px, py = polar(1.4 + (k % 2) * 0.8, k * 45)
        F.brick(0.8 + px, py, 13.0 - (k % 2) * 1.2, 0.8, 0.8, 0.9, "spout", rot=k * 45, studs=False, bevel=0.2)
    for k in range(7):  # the tail stock curving up out of the water behind (-x)
        F.brick(-6.6 - k * 0.55, 0, 1.0 + k * 1.0, 2.8 - k * 0.22, 2.4 - k * 0.18, 1.05, "whale", studs=False, bevel=0.2)
    G = F.sub(-10.6, 0, 90)  # the flukes (pixel rows across the tail)
    spans = ((-1.2, 1.2), (-2.8, 2.8), (-4.6, -0.5, 0.5, 4.6), (-6.0, -1.4, 1.4, 6.0), (-6.6, -3.4, 3.4, 6.6))
    pixel_rows(G, [[(sp[i], sp[i + 1], "whale") for i in range(0, len(sp), 2)] for sp in spans], 0.9, 1.4, z0=7.6)
    for sgn in (-1, 1):  # drips off the fluke tips into the pool
        G.brick(sgn * 6.2, 0, 1.3, 0.35, 0.35, 10.0, "spout", studs=False, bevel=0.1)


def beach_shack(F, name, color, prop=None):
    """A tiki beach shack facing local -y: plank deck, a coloured counter, bamboo posts, a stepped thatch roof with a
    fringe, a sign on the roof's front course, a menu board, and a giant prop on the roof cap (prop)."""
    F.brick(0, 0, 0, 12, 9, 0.6, "plank")
    F.brick(0, -2.6, 0.6, 10, 2.4, 3.2, color, studs=False)
    F.brick(0, -2.6, 3.8, 10.6, 3.0, 0.4, "driftwood")
    F.brick(0, 2.8, 0.6, 10, 1.2, 7.4, "plank_dark", studs=False)
    W.board(F, 0, 2.1, 4.4, 6, 2.6, "MENU", bg="navy", fg="white", trim="driftwood", size=0.8)
    for sx in (-1, 1):
        for sy in (-3.4, 2.2):
            bamboo(F, sx * 4.8, sy, 0.6, 8.0)
    F.roof_hip(0, -0.4, 8.0, 11, 8, 2.6, "thatch", courses=4, trim="thatch_dark", overhang=1.0, cap="thatch_dark")
    for k in range(12):  # the thatch fringe along the front eave
        F.brick(-6 + (k + 0.5), -5.3, 7.3, 1.0, 0.35, 0.8 + (k % 3) * 0.2, "thatch_dark" if k % 2 else "thatch", studs=False, bevel=0.04)
    W.board(F, 0, -4.7, 8.7, 9, 2.0, name, bg=color, fg="white", trim="white", size=0.9)
    for k in range(3):  # cups + coconuts on the counter
        F.cyl(-3 + k * 3, -2.6, 0.6, 4.2, 5.0, ("coral_pink", "white", "sky_blue")[k], segs=10)
    if prop:
        prop(F.sub(0, 0.6, z=11.4))


def shell_keystone(F):
    """A scallop shell on top (the RETURN HOME ring's keystone)."""
    shell(F, 0, 0, -1.0, R=3.4, depth=1.4)


def ocean_egg_deco(F, x, y, s):
    """A little starfish lying on the egg's top."""
    for k in range(5):
        a = k * 72 + 18
        px, py = polar(0.55 * s, a)
        F.brick(x + px, y + py, 4.05 * s, 0.75 * s, 0.32 * s, 0.18 * s, "starfish", rot=a, studs=False, bevel=0.05)


def ocean_egg(F, x, y, golden=False):
    """The Ocean egg: sea blue with a white wave crest + a seafoam band, sandy base, a starfish on top (golden variant)."""
    W.egg(F, x, y, 1.0, body="gold" if golden else "ocean_egg",
          bands={0: "sand", 4: "white", 5: "seafoam", 6: "white"} if not golden else {4: "glow_gold"}, deco=ocean_egg_deco)


# ------------------------------------------------------------------ the gate
def ocean_gate(F, width=26):
    """Two giant surfboards standing in the sand as pillars, a driftwood beam roped across their tops, an OCEAN SHORE
    marquee hanging under it, life rings on the boards and a starfish crest on top."""
    for sx, (body, stripe) in ((-1, ("sky_blue", "white")), (1, ("coral", "yellow"))):
        x = sx * (width / 2 + 2.5)
        F.cyl(x, 0, 3.4, 0, 1.0, "sand_wet", segs=16, studs=True)
        surfboard(F, x, 0, 1.0, L=19, w=4.8, body=body, stripe=stripe, depth=1.0)
        life_ring(F, x, -0.9, 6.6, R=1.8)
        F.brick(x, 0, 15.1, 1.4, 1.6, 2.6, "rope", studs=False, bevel=0.2)
    F.brick(0, 0, 15.6, width + 10, 1.6, 1.6, "driftwood")
    for sx in (-1, 1):
        F.brick(sx * (width / 2 - 4), -1.4, 14.1, 0.25, 0.25, 1.5, "rope", studs=False, bevel=0.0)
    W.marquee(F, 0, -1.4, 10.6, width - 4, 3.6, "OCEAN SHORE", size=1.6, panel="navy", letters="white")
    starfish_upright(F, 0, 0, 17.2, s=1.2)


# ------------------------------------------------------------------ buildings (decor shells)
def _beach_house(F, w, d, h, wall, trim, roof, sign, sign_bg, sign_fg="white", storeys=1, porch=True, shutters="sky_blue"):
    """The shared beach-house shell (front = local -y): a plank base, pastel walls, shuttered windows per storey,
    a door, a porch with posts + a striped awning, a stepped hip roof, a sign board over the porch. Returns the eaves z."""
    F.brick(0, 0, 0, w + 4, d + 6, 0.8, "plank")
    top = 0.8 + h * storeys
    F.brick(0, 1.5, 0.8, w, d, h * storeys, wall, studs=False)
    for s in range(storeys):
        F.brick(0, 1.5, 0.8 + h * (s + 1) - 0.3, w + 0.6, d + 0.6, 0.5, trim, studs=False)
        for k in range(int(w / 7)):
            x = -w / 2 + 3.5 + k * 7
            if s > 0 or abs(x) > 3:
                K.window(F, x, -d / 2 + 1.45, 2.0 + h * s, 3.6, 3.8, 0, frame=trim, mullions=1, shutters=shutters)
    K.door(F, 0, -d / 2 + 1.45, 0.8, 3.4, 6.0, 0, frame=trim, leaf=shutters)
    if porch:
        for sx in (-1, 1):
            F.brick(sx * 4.6, -d / 2 - 2.0, 0.8, 0.6, 0.6, 5.6, trim, studs=False)
        n = 6
        for k in range(n):
            F.brick(-5 + (k + 0.5) * 10 / n, -d / 2 - 1.0, 6.4, 10 / n, 3.6, 0.5, sign_bg if k % 2 == 0 else "awning_white", studs=(k % 2 == 0))
    F.roof_hip(0, 1.5, top, w, d, 4.0, roof, courses=5, trim=trim, overhang=1.0)
    W.board(F, 0, -d / 2 - 0.2, top + 0.3, min(w - 4, 18), 2.6, sign, bg=sign_bg, fg=sign_fg, trim=trim, size=1.3)  # (on the eaves)
    return top


def lighthouse(F):
    """The landmark: a red-and-white striped studded tower on a rock plinth, a gallery with railings, a glass lamp
    room with a warm lamp (its beam turns in the ambience: Spin_LighthouseBeam), a red dome, and a keeper's cottage."""
    F.cyl(0, 0, 9.5, 0, 1.0, "stone_dark", segs=32, studs=True)
    F.cyl(0, 0, 8.0, 1.0, 2.0, "stone", segs=32, studs=True)
    taper(F, 0, 0, 2.0, 5.8, 3.8, 30, "white", step=1.0, segs=24, looks=lambda k: "red" if (k // 4) % 2 == 0 else "white")
    F.cyl(0, 0, 5.4, 32.0, 32.8, "navy", segs=28, studs=True)
    for k in range(18):
        px, py = polar(5.1, k * 20)
        F.brick(px, py, 32.8, 0.3, 0.3, 1.6, "white", studs=False, bevel=0.0)
    F.ring(4.9, 5.3, 34.3, 34.6, "white", segs=36)
    F.cyl(0, 0, 3.0, 32.8, 37.2, "glass", segs=16)
    F.cyl(0, 0, 1.5, 33.4, 36.4, "glow_warm", segs=12)
    for k in range(8):
        px, py = polar(3.05, k * 45)
        F.brick(px, py, 32.8, 0.3, 0.3, 4.4, "navy", rot=k * 45, studs=False, bevel=0.0)
    F.cyl(0, 0, 3.7, 37.2, 37.8, "red", segs=20)
    dome(F, 0, 0, 37.8, 3.4, 3.0, "red", step=0.5, segs=20)
    F.cyl(0, 0, 0.25, 40.6, 42.4, "metal_dark", segs=6)
    F.sphere(0, 0, 42.6, 0.4, 0.4, 0.4, "gold", seg=8, rings=5)
    F.brick(0, -5.7, 2.0, 2.6, 1.0, 4.4, "navy", studs=False)  # the door + frame
    F.brick(0, -5.9, 6.4, 3.4, 1.2, 0.6, "white", studs=False)
    for z, r in ((11.0, 5.0), (18.5, 4.5), (25.5, 4.1)):
        F.brick(0, -r + 0.1, z, 1.4, 0.8, 2.2, "glass_dark", studs=False, bevel=0.0)
        F.brick(0, -r - 0.1, z - 0.3, 1.8, 0.6, 0.4, "white", studs=False)
    G = F.sub(16, 3)  # the keeper's cottage
    G.brick(0, 0, 0, 12, 10, 0.8, "stone")
    G.brick(0, 0, 0.8, 10, 8, 6.0, "white", studs=False)
    G.roof_gable(0, 0, 6.8, 10, 8, 3.2, "red", courses=4, overhang=0.8, trim="white")
    K.door(G, -2.4, -4.0, 0.8, 2.6, 4.6, 0, frame="navy", leaf="navy")
    K.window(G, 2.4, -4.0, 2.4, 2.8, 2.6, 0, frame="navy", shutters="sky_blue")
    G.brick(3, 2, 6.8, 1.6, 1.6, 5.0, "stone", studs=False)  # chimney


def surf_club(F):
    """A two-storey pastel-blue beach house with a red roof and surfboards leaning along its front (its turning
    surfboard sign stands beside it on a pole, built in os_build)."""
    _beach_house(F, 26, 16, 6.2, "pastel_blue", "white", "roof_red", "SURF CLUB", "coral", storeys=2, shutters="coral")
    for k, (body, stripe) in enumerate(UMBRELLAS):
        x = -11 + k * 2.2 if k < 3 else 6 + (k - 3) * 2.2
        surfboard(F, x, -8.6, 0.8, L=8.0, w=1.9, body=body, stripe=stripe, depth=0.45)


def aquarium(F):
    """A round mint aquarium with a band of fish windows, a big glass dome and an entrance arch with its board
    (its turning fish sign stands on the dome, built in os_build)."""
    F.cyl(0, 0, 15, 0, 0.8, "plank", segs=40, studs=True)
    F.cyl(0, 0, 13, 0.8, 9.8, "pastel_mint", segs=40)
    F.cyl(0, 0, 13.15, 3.0, 6.4, "glass_dark", segs=40)
    F.cyl(0, 0, 13.4, 9.8, 10.6, "white", segs=40, studs=True)
    dome(F, 0, 0, 10.6, 11.6, 9.0, "glass", step=0.75, segs=32, studs=False)
    for k in range(8):  # little fish in the window band
        a = 270 + (k - 3.5) * 14
        px, py = polar(13.3, a)
        F.brick(px, py, 4.2 + (k % 2) * 0.8, 1.6, 0.3, 0.9, ("fish_orange", "coral_yellow", "fish_blue")[k % 3], rot=a + 90, studs=False, bevel=0.1)
    G = F.sub(0, -13.4)
    G.brick(0, -1.2, 0.8, 10, 3.0, 8.4, "white", studs=False)
    G.brick(0, -2.8, 0.8, 4.4, 0.4, 5.8, "navy", studs=False)
    W.board(G, 0, -2.9, 6.8, 9, 2.4, "AQUARIUM", bg="fish_blue", fg="white", trim="white", size=1.2)


def boat_house(F):
    """A plank boathouse with a navy gable roof and a big open door, a sailboat on the slipway in front."""
    F.brick(0, -2, 0, 26, 28, 0.8, "plank")
    F.brick(0, 3, 0.8, 22, 16, 9.0, "plank_dark", studs=False)
    for k in range(11):
        F.brick(-10 + k * 2, -5.05, 0.8, 0.3, 0.3, 9.0, "plank", studs=False)
    F.roof_gable(0, 3, 9.8, 22, 16, 6.0, "navy", courses=6, overhang=1.0, trim="white")
    F.brick(0, -5.1, 0.8, 9, 0.3, 7.0, "black", studs=False)
    F.brick(0, -5.3, 7.8, 10.4, 0.6, 0.8, "white", studs=False)
    for sx in (-1, 1):
        F.brick(sx * 5.0, -5.3, 0.8, 0.8, 0.6, 7.4, "white", studs=False)
    W.board(F, 0, -5.6, 12.0, 14, 2.4, "BOAT HOUSE", bg="navy", fg="white", trim="white", size=1.2)
    for sx in (-1.6, 1.6):  # the slipway rails
        F.brick(sx, -9.4, 0.8, 0.6, 8.0, 0.3, "plank_dark", studs=False)
    sailboat(F, 0, -8.6, 0, hull="hull_red", z=1.1)
    life_ring(F, 8.4, -5.4, 4.0, R=1.2)
    crate(F, -8.6, -8.0, 0.8, 0.9, 15)
    crate(F, -10.4, -7.2, 0.8, 0.8, -10)


def beach_cafe(F):
    """A white cafe with a teal striped awning, umbrella tables out front."""
    _beach_house(F, 24, 14, 7.0, "white", "teal", "roof_teal", "BEACH CAFE", "teal", shutters="teal")
    for (x, y, lk) in ((-8, -12, UMBRELLAS[1]), (0, -13, UMBRELLAS[3]), (8, -12, UMBRELLAS[0])):
        G = F.sub(x, y)
        G.cyl(0, 0, 1.6, 2.4, 2.8, "white", segs=14)
        G.cyl(0, 0, 0.25, 0, 2.4, "white", segs=6)
        umbrella(G, 0, 0, lk, h=6.6, R=3.6, towel=False)
        for sx in (-1, 1):
            G.brick(sx * 2.4, 0, 0, 1.4, 1.4, 1.5, "coral" if sx > 0 else "sky_blue", studs=False)


def seaside_hotel(F):
    """A three-storey peach hotel with white balconies on every upper window and a teal roof."""
    top = _beach_house(F, 30, 16, 5.6, "pastel_peach", "white", "roof_teal", "SEASIDE HOTEL", "navy", storeys=3, shutters="teal")
    for s in (1, 2):
        for k in range(int(30 / 7)):
            x = -15 + 3.5 + k * 7
            F.brick(x, -7.6, 0.8 + 5.6 * s - 0.2, 5.0, 2.0, 0.4, "white")
            F.brick(x, -8.5, 0.8 + 5.6 * s + 0.2, 5.0, 0.2, 1.2, "white", studs=False)
    return top


def shipwreck(F, L=30.0, Wd=11.0):
    """A wrecked ship stuck in the sand (along local y, bow +y): stepped plank sides with broken gaps, a raised bow,
    a stern cabin, a snapped mast with a tattered sail, the fallen top of the mast, barrels and a spilled chest."""
    n = int(L / 1.5)
    for k in range(n):
        t = (k + 0.5) / n
        w = Wd * (1 - max(0.0, (t - 0.6) / 0.4) ** 1.6 * 0.8)
        ly = -L / 2 + (k + 0.5) * L / n
        h = 4.2 + max(0.0, (t - 0.75) / 0.25) * 3.2
        for sx in (-1, 1):
            hh = h * (0.35 if (k in (4, 5, 10) and sx > 0) or (k == 7 and sx < 0) else 1.0)
            F.brick(sx * (w / 2 - 0.4), ly, 0, 0.8, L / n + 0.02, hh, "plank_dark" if k % 2 else "plank", bevel=0.05)
            if hh == h:
                F.brick(sx * (w / 2 - 0.35), ly, hh - 0.6, 0.95, L / n + 0.02, 0.3, "teal", studs=False, bevel=0.0)
        F.brick(0, ly, 0, max(0.5, w - 1.6), L / n, 1.0, "sand_wet", studs=False, bevel=0.0)
    F.brick(0, -L / 2 + 4, 0, Wd - 1.6, 6, 6.8, "plank_dark", studs=False)  # the stern cabin
    F.brick(0, -L / 2 + 4, 6.8, Wd - 1.0, 6.6, 0.5, "plank")
    for sx in (-2.2, 0, 2.2):
        F.brick(sx, -L / 2 + 0.95, 3.4, 1.4, 0.3, 1.6, "glass_dark", studs=False, bevel=0.0)
    F.cyl(0, 2, 0.6, 0, 10.0, "wood_dark", segs=10)  # the snapped mast + its yard and sail rags
    F.brick(0, 2, 8.6, 8.0, 0.5, 0.5, "wood_dark", studs=False)
    for k, (x0, x1, drop) in enumerate(((-3.6, -1.8, 4.0), (-1.6, 0.2, 5.2), (0.5, 1.8, 3.0), (2.0, 3.6, 4.4))):
        F.brick((x0 + x1) / 2, 2.3, 8.6 - drop, x1 - x0, 0.15, drop, "shell_cream" if k % 2 else "white", studs=False, bevel=0.0)
    F.brick(Wd / 2 + 6, 3, 0, 1.2, 15, 1.2, "wood_dark", rot=24, studs=False)  # the fallen top
    for (bx, by) in ((-Wd / 2 - 3, 6), (-Wd / 2 - 4.4, 8.4), (Wd / 2 + 2.6, -8)):
        F.cyl(bx, by, 1.1, 0, 2.6, "wood", segs=12)
        for zz in (0.5, 1.9):
            F.cyl(bx, by, 1.15, zz, zz + 0.25, "metal_dark", segs=12)
    treasure_chest(F, -Wd / 2 - 4, -2, rot=70)
    for k in range(10):
        F.cyl(-Wd / 2 - 6 + rng.uniform(-2, 2), -2 + rng.uniform(-2.5, 2.5), 0.45, 0, 0.15, "gold", segs=8)


# ------------------------------------------------------------------ boss arena: THE SHARK DOCK (Megalodon charges)
def shark_dock(F, L=148.0, Wd=72.0):
    """A wide wooden dock over the lagoon: studded planks along the charge (local y), dark edge beams, pilings that
    poke up as posts along both long sides with a low rope between them (open at both ends), and a navy compass-rose
    inlay. Nothing stands on it: Megalodon's Fin Charge runs the full length (Line, 130 studs)."""
    F.brick(0, 0, 0.1, Wd - 0.2, L - 0.2, 1.0, "plank_dark", studs=False, bevel=0.0)  # (the sub-deck behind the plank seams)
    plank = 6.0
    n = int(Wd / plank)
    for i in range(n):
        x = -Wd / 2 + (i + 0.5) * plank
        F.brick(x, 0, 0, plank - 0.12, L, 1.2, "plank" if i % 2 else "wood", bevel=0.05)
    for sx in (-1, 1):
        F.brick(sx * (Wd / 2 + 0.6), 0, -0.4, 1.2, L, 1.5, "plank_dark")
        k = 0
        y = -L / 2 + 4
        while y <= L / 2 - 4 + 0.01:
            F.cyl(sx * (Wd / 2 + 0.6), y, 0.75, -0.6, 2.6, "plank_dark", segs=10)
            F.cyl(sx * (Wd / 2 + 0.6), y, 0.85, 2.6, 2.8, "rope", segs=10)
            if y + 10 <= L / 2 - 4 + 0.01:
                F.brick(sx * (Wd / 2 + 0.6), y + 5, 2.0, 0.3, 9.2, 0.3, "rope", studs=False, bevel=0.0)
            y += 10
            k += 1
    F.cyl(0, 0, 10, 1.2, 1.32, "navy", segs=40)  # the compass rose
    F.ring(8.6, 9.4, 1.32, 1.4, "gold", segs=40)
    for k in range(8):
        px, py = polar(4.6 if k % 2 == 0 else 3.2, k * 45)
        F.brick(px, py, 1.32, 7.6 if k % 2 == 0 else 4.6, 1.4, 0.1, "white" if k % 2 == 0 else "gold", rot=k * 45, studs=False, bevel=0.0)
