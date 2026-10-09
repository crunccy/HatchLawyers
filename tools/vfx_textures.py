"""VFX v2 textures (run inside Blender: exec(open(".../tools/vfx_textures.py").read())).

Built from the user's 4 reference images (anime-style Roblox VFX):
  ice burst (cyan slash rings, crystals, orbs) · fire tornado (yellow/orange spiral slashes) ·
  dark-red star burst (4-point flare, smoky ground tendrils, sparks) · blue energy orb (churning core, spiky
  streaks, dark specks).
Every texture is WHITE + alpha (tinted in Roblox) unless it says otherwise. Flipbooks are 4x4 grids of 256 px
frames (1024 px), for ParticleEmitter.FlipbookLayout = Grid4x4. Output: "Models - Effects/vfx_<name>.png" +
a preview sheet on a dark background (vfx_preview.png). Numpy only (no render), so it's fast and repeatable.
"""
import math
import os

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/Models - Effects"
rng = np.random.default_rng(7)


# ------------------------------------------------------------------------------------------------ helpers
def grid(n, m=None):
    m = m or n
    xs = (np.arange(m) + 0.5) / m * 2 - 1
    ys = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(xs, -ys)
    return x, y, np.hypot(x, y), np.arctan2(y, x)


def value_noise(shape, cells, seed):
    """Smooth value noise in 0..1 (bicubic-ish upsampling of a random lattice), tileable in x."""
    g = np.random.default_rng(seed).random((cells[0] + 3, cells[1] + 3))
    h, w = shape
    yy = np.linspace(0, cells[0], h, endpoint=False) + 1
    xx = np.linspace(0, cells[1], w, endpoint=False) + 1
    y0, x0 = np.floor(yy).astype(int), np.floor(xx).astype(int)
    fy, fx = yy - y0, xx - x0
    sy, sx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    a = g[np.ix_(y0, x0)]
    b = g[np.ix_(y0, x0 + 1)]
    c = g[np.ix_(y0 + 1, x0)]
    d = g[np.ix_(y0 + 1, x0 + 1)]
    sx, sy = sx[None, :], sy[:, None]
    return (a * (1 - sx) + b * sx) * (1 - sy) + (c * (1 - sx) + d * sx) * sy


def fbm(shape, base, seed, octaves=4):
    out, amp, tot = np.zeros(shape), 1.0, 0.0
    for o in range(octaves):
        out += amp * value_noise(shape, (base[0] * 2 ** o, base[1] * 2 ** o), seed + o * 17)
        tot += amp
        amp *= 0.5
    return out / tot


def soft_edge(a, r, start=0.9):
    return a * np.clip((1 - r) / (1 - start), 0, 1)


def polar_sample(img, r, t):
    """Sample a (H, W) image whose rows are radius 0..1 and columns are angle -pi..pi."""
    h, w = img.shape
    ri = np.clip((r * (h - 1)).astype(int), 0, h - 1)
    ti = ((t + math.pi) / (2 * math.pi) * w).astype(int) % w
    return img[ri, ti]


# ------------------------------------------------------------------------------------------------ textures
def slash_arc(h=256, w=512):
    """Crescent swoosh made of many fine streaks (the hand-drawn slash lines in the refs): thick bright
    outer edge, thin streaks inside, tapered both ends."""
    x, y, _, _ = grid(h, w)
    X, Y = x * 2, y                                        # square pixel space
    rho = np.hypot(X, Y + 1.6)
    phi = np.arctan2(X, Y + 1.6)                           # -0.95 .. 0.95 across the arc
    u = np.clip((phi + 0.95) / 1.9, 0, 1)
    thick = 0.75 * np.sin(u * math.pi) ** 0.9 * (0.4 + 0.6 * u) + 1e-3
    d = (2.5 - rho) / thick                                # 0 outer edge .. 1 inner edge
    inside = (d >= 0) & (d <= 1)
    wob = value_noise((h, w), (4, 10), 3)
    lines = (0.5 + 0.5 * np.sin(d * 34 + wob * 7)) ** 3
    breakup = np.clip(fbm((h, w), (2, 12), 9) * 1.8 - 0.45, 0, 1)
    edge = np.exp(-(d / 0.12) ** 2)
    a = (lines * np.clip(1 - d, 0, 1) ** 0.7 * breakup * 0.9 + edge * 1.2) * inside
    a *= np.sin(u * math.pi) ** 0.5
    return np.clip(a, 0, 1)


def slash_ring(n=512):
    """Flat ground swirl: several concentric streak arcs with gaps, brightest on one side (like the ice ref's
    floor swirl). Spin it with RotSpeed."""
    _, _, r, t = grid(n)
    a = np.zeros_like(r)
    for i, (rad, width, start, span, bright) in enumerate((
            (0.86, 0.035, 0.0, 1.7, 1.0), (0.78, 0.025, 1.2, 1.4, 0.8), (0.70, 0.03, 2.6, 1.6, 0.9),
            (0.62, 0.02, 4.0, 1.2, 0.7), (0.91, 0.015, 3.3, 1.1, 0.6), (0.55, 0.018, 5.2, 1.0, 0.5))):
        ang = (t - start) % (2 * math.pi)
        along = np.clip(ang / span, 0, 1) * (ang < span)
        head = along ** 1.5 * np.clip((span - ang) / 0.35, 0, 1)   # thin tail -> thick head, rounded tip
        line = np.exp(-((r - rad) / (width * 1.9 * (0.3 + head))) ** 2)
        a = np.maximum(a, line * head * bright)
    jitter = value_noise((n, n), (64, 64), 21)
    a *= 0.75 + 0.25 * jitter
    return soft_edge(np.clip(a * 1.3, 0, 1), r, 0.95)


def star_flare(n=512):
    """4-point star flare with a hot core, long thin cross rays, a softer diagonal cross and fine needles."""
    x, y, r, t = grid(n)
    a = np.exp(-(r / 0.05) ** 2) * 1.5 + np.exp(-(r / 0.16) ** 2) * 0.5
    for ax, ay, length, width, k in ((1, 0, 1.0, 0.012, 1.0), (0, 1, 1.0, 0.012, 1.0),
                                     (0.707, 0.707, 0.55, 0.008, 0.45), (0.707, -0.707, 0.55, 0.008, 0.45)):
        along = np.abs(x * ax + y * ay)
        across = np.abs(-x * ay + y * ax)
        ray = np.exp(-across / (width * (1 + 3 * along))) * np.clip(1 - along / length, 0, 1) ** 1.4
        a = a + ray * k
    needles = (np.cos(t * 23) * 0.5 + 0.5) ** 40 * np.exp(-r / 0.35) * 0.6   # fine radial needles
    a = a + needles
    return soft_edge(np.clip(a, 0, 1), r, 0.92)


def tendrils(n=512):
    """Dark smoky ground tendrils / cracks radiating out (ref 3). Tint it dark red / black."""
    _, _, r, t = grid(n)
    a = np.zeros_like(r)
    for i in range(26):
        ang = rng.uniform(-math.pi, math.pi)
        length = rng.uniform(0.45, 0.98)
        wob = rng.uniform(1.5, 4)
        bend = ang + 0.25 * np.sin(r * wob * 4 + i)
        da = np.abs((t - bend + math.pi) % (2 * math.pi) - math.pi) * r
        width = np.maximum(0.03 * (1 - r / length), 0) + 0.004
        a = np.maximum(a, np.exp(-da / width) * np.clip(1 - r / length, 0, 1) ** 0.7)
    smoke = fbm((n, n), (4, 4), 33)
    blob = np.exp(-(r / 0.35) ** 2) * (0.4 + 0.6 * smoke)
    a = np.clip(a * (0.6 + 0.6 * smoke) + blob, 0, 1)
    return soft_edge(a, r, 0.85)


def spark_streak(h=64, w=256):
    """Long thin spark with a hot head and a fading tail (for flying sparks / streaks)."""
    x, y, _, _ = grid(h, w)
    u = (x + 1) / 2
    width = 0.04 + 0.16 * u ** 3                             # needle thin (fat heads read as arrowheads)
    core = np.exp(-(y / width) ** 2) * u ** 1.5
    head = np.exp(-(((x - 0.85) / 0.1) ** 2 + (y / 0.16) ** 2))
    return np.clip(core + head, 0, 1)


def beam_streak(h=128, w=512):
    """Tileable streaky band for Beams that form the swirl rings (TextureMode Wrap, TextureSpeed scrolls it).
    Built from whole-period sines along x so it wraps seamlessly."""
    x, y, _, _ = grid(h, w)
    u = (x + 1) / 2
    a = np.zeros_like(x)
    lr = np.random.default_rng(41)
    for _ in range(22):
        yc = lr.uniform(-0.8, 0.8)
        width = lr.uniform(0.012, 0.035)
        k = lr.integers(1, 4)
        ph = lr.uniform(0, 2 * math.pi)
        seg = np.clip(np.sin(u * 2 * math.pi * k + ph) * 1.6 - 0.3, 0, 1)   # streak segments with gaps
        a = np.maximum(a, np.exp(-((y - yc) / width) ** 2) * seg * lr.uniform(0.5, 1))
    edge = np.exp(-((y - 0.75) / 0.06) ** 2) * (0.6 + 0.4 * np.sin(u * 4 * math.pi) ** 2)
    return np.clip(a + edge, 0, 1) * np.clip((1 - np.abs(y)) / 0.15, 0, 1)


def ice_ring_flip(n=256, frames=16):
    """Flipbook 4x4: an icy shockwave ring that expands, cracks up and fades."""
    _, _, r, t = grid(n)
    crack = fbm((n, n), (6, 6), 51)
    out = []
    for f in range(frames):
        p = f / (frames - 1)
        rad = 0.15 + 0.75 * p
        ring = np.exp(-((r - rad) / (0.05 + 0.08 * p)) ** 2)
        shards = (np.cos(t * 18 + crack * 6) * 0.5 + 0.5) ** 6 * np.exp(-((r - rad * 0.9) / 0.12) ** 2)
        a = (ring * (0.7 + 0.3 * crack) + shards * 0.7) * (1 - p) ** 1.3 * min(1, p * 6)
        out.append(soft_edge(np.clip(a, 0, 1), r, 0.95))
    return out


def flame_flip(n=256, frames=16):
    """Flipbook 4x4: a flame tongue that licks up and flickers out (rising fire / embers base)."""
    x, y, r, _ = grid(n)
    out = []
    for f in range(frames):
        p = f / (frames - 1)
        yy = (y + 1) / 2
        n1 = fbm((n, n), (3, 3), 60 + f, 3)
        sway = 0.12 * np.sin(yy * 5 + p * 6) + (n1 - 0.5) * 0.25
        width = (0.42 * (1 - yy) ** 0.8 + 0.05) * (1 - 0.3 * p)
        body = np.exp(-((x - sway) / width) ** 2) * np.clip((yy + 0.02) * 6, 0, 1)
        top = 0.55 + 0.45 * (1 - p)                           # the tongue shrinks
        body *= np.clip((top - yy) / 0.25, 0, 1)
        lick = np.clip((n1 - 0.35) * 2, 0, 1)
        a = body * (0.55 + 0.45 * lick) * min(1, p * 8 + 0.3)
        a *= np.clip((1 - np.abs(x)) / 0.3, 0, 1) * np.clip((1 - y) / 0.3, 0, 1)   # keep inside the frame
        out.append(np.clip(a * 1.3, 0, 1))
    return out


def energy_flip(n=256, frames=16):
    """Flipbook 4x4: a churning energy orb — bright core, swirling wispy shell, spiky rays (ref 4)."""
    _, _, r, t = grid(n)
    out = []
    for f in range(frames):
        ph = f / frames * 2 * math.pi
        swirl_t = t + 2.5 * r + ph                          # swirl that turns over the loop
        wisp = (np.cos(swirl_t * 3) * 0.5 + 0.5) ** 3 * np.exp(-((r - 0.45) / 0.18) ** 2)
        wisp2 = (np.cos((t - 1.7 * r - ph * 2) * 5) * 0.5 + 0.5) ** 4 * np.exp(-((r - 0.3) / 0.12) ** 2)
        core = np.exp(-(r / (0.13 + 0.02 * math.sin(ph * 2))) ** 2) * 1.4
        spikes = (np.cos(t * 11 + math.sin(ph) * 2) * 0.5 + 0.5) ** 30 * np.exp(-r / 0.5) * 0.9
        shell = np.exp(-((r - 0.55) / 0.04) ** 2) * (0.4 + 0.6 * (np.cos(t * 7 - ph * 3) * 0.5 + 0.5))
        a = core + wisp * 0.9 + wisp2 * 0.7 + spikes + shell * 0.5
        out.append(soft_edge(np.clip(a, 0, 1), r, 0.9))
    return out


def ember(n=64):
    """Tiny hot ember with a soft halo (crisper than the old dot)."""
    _, _, r, _ = grid(n)
    return soft_edge(np.clip(np.exp(-(r / 0.12) ** 2) * 1.4 + np.exp(-(r / 0.4) ** 2) * 0.35, 0, 1), r)


def speck(n=64):
    """Hard little dark speck (the black particles in the energy ref). Tint it near-black."""
    _, _, r, _ = grid(n)
    return np.clip((0.45 - r) / 0.1, 0, 1)


def crystal_shard(h=256, w=128):
    """Ice shard sprite: a tall faceted spike with a bright edge and inner cracks (for ice bursts)."""
    x, y, _, _ = grid(h, w)
    yy = (y + 1) / 2
    half = 0.85 * (1 - yy) ** 0.9                         # pointed top
    inside = np.clip((half - np.abs(x)) / 0.05, 0, 1)
    facet = np.where(x > 0, 0.85, 0.55)                     # two facets
    edge = np.exp(-((np.abs(x) - half) / 0.04) ** 2) * inside
    cracks = np.clip((fbm((h, w), (8, 4), 77) - 0.55) * 4, 0, 1)
    a = inside * (facet + 0.4 * cracks) * 0.75 + edge * 0.9 + np.exp(-((x) / 0.05) ** 2) * inside * 0.4
    return np.clip(a, 0, 1)


def flip_sheet(frames):
    n = frames[0].shape[0]
    sheet = np.zeros((n * 4, n * 4))
    for i, fr in enumerate(frames):
        rr, cc = divmod(i, 4)
        sheet[rr * n:(rr + 1) * n, cc * n:(cc + 1) * n] = fr
    return sheet


TEXTURES = {
    "vfx_slash_arc": slash_arc, "vfx_slash_ring": slash_ring, "vfx_star_flare": star_flare,
    "vfx_tendrils": tendrils, "vfx_spark": spark_streak, "vfx_beam_streak": beam_streak,
    "vfx_ember": ember, "vfx_speck": speck, "vfx_crystal": crystal_shard,
    "vfx_ice_ring_flip": lambda: flip_sheet(ice_ring_flip()),
    "vfx_flame_flip": lambda: flip_sheet(flame_flip()),
    "vfx_energy_flip": lambda: flip_sheet(energy_flip()),
}


# Alpha boost (a ** gamma): the firm floor is bright, so effects alpha-blend (low LightEmission) and need
# solid alpha to read at gameplay distance. (Found in playtest - the first upload was too faint.)
ALPHA_GAMMA = {"vfx_slash_ring": 0.45, "vfx_slash_arc": 0.5, "vfx_flame_flip": 0.45, "vfx_energy_flip": 0.55,
               "vfx_ice_ring_flip": 0.5, "vfx_tendrils": 0.7, "vfx_ember": 0.6, "vfx_star_flare": 0.7, "vfx_spark": 0.6}


def save(name, a):
    a = np.clip(a, 0, 1) ** ALPHA_GAMMA.get(name, 1.0)
    h, w = a.shape
    rgba = np.ones((h, w, 4))
    rgba[..., 3] = np.clip(a, 0, 1)
    img = bpy.data.images.get(name)
    if img and (img.size[0] != w or img.size[1] != h):
        bpy.data.images.remove(img)
        img = None
    img = img or bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = np.flipud(rgba).astype(np.float32).ravel()
    os.makedirs(OUT, exist_ok=True)
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()


TINTS = {"vfx_slash_arc": (0.4, 0.95, 1.0), "vfx_slash_ring": (0.4, 0.95, 1.0), "vfx_ice_ring_flip": (0.5, 0.95, 1.0),
         "vfx_crystal": (0.75, 0.95, 1.0), "vfx_flame_flip": (1.0, 0.7, 0.2), "vfx_beam_streak": (1.0, 0.85, 0.3),
         "vfx_star_flare": (1.0, 0.35, 0.3), "vfx_tendrils": (0.6, 0.05, 0.05), "vfx_energy_flip": (0.5, 0.45, 1.0),
         "vfx_spark": (1.0, 0.8, 0.4), "vfx_ember": (1.0, 0.75, 0.3), "vfx_speck": (0.9, 0.9, 0.9)}


def preview(images, cell=320):
    names = list(images)
    cols = 4
    rows = math.ceil(len(names) / cols)
    sheet = np.zeros((rows * cell, cols * cell, 3)) + 0.06
    for i, name in enumerate(names):
        a = np.clip(images[name], 0, 1) ** ALPHA_GAMMA.get(name, 1.0)
        h, w = a.shape
        ys = (np.arange(cell) * h // cell)
        xs = (np.arange(cell) * w // cell)
        small = a[np.ix_(ys, xs)]
        rr, cc = divmod(i, cols)
        tint = np.array(TINTS.get(name, (1, 1, 1)))
        sheet[rr * cell:(rr + 1) * cell, cc * cell:(cc + 1) * cell] += small[..., None] * tint
    sheet = np.clip(sheet, 0, 1)
    rgba = np.ones((sheet.shape[0], sheet.shape[1], 4))
    rgba[..., :3] = sheet
    img = bpy.data.images.get("vfx_preview")
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new("vfx_preview", rgba.shape[1], rgba.shape[0], alpha=True)
    img.pixels = np.flipud(rgba).astype(np.float32).ravel()
    img.filepath_raw = os.path.join(OUT, "vfx_preview.png")
    img.file_format = "PNG"
    img.save()
    return img.filepath_raw


def build():
    images = {}
    for name, fn in TEXTURES.items():
        a = fn()
        images[name] = a
        save(name, a)
    return preview(images)


print(build())
