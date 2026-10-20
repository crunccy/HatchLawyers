"""World-ambience particle textures (2026-10-20, crnuch's ambience overhaul; run headless:
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python tools/ambience_textures.py

Small, soft shapes for the floating ambient particles of Shared.AmbiencePresets (the rest reuse Effects.TEXTURES):
  leaf    a pointed leaf with a centre vein (Pet Park leaves)
  petal   a rounded petal with a notch (Pet Park blossom petals)
  paper   a scrap of paper with a folded corner and faint lines (Briefcase Bay)
  mist    a soft cloud puff (mist over water / rocks, steam)
  square  a voxel mote: a soft-edged square (crumbs, glitch specks, the classic blocky look)
  bubble  a ring with a highlight (sea spray, fizz)
White + alpha, tinted in game; RGB carries a little grey shading (the leaf vein, the paper lines, the petal base) so a
tint still reads as a shape. Output: "Models - Effects/amb_<name>.png" + amb_preview.png (on a dark background).
Numpy only (no render). Upload from crnuch's Studio (the place owner) - ids go in Models - Effects/ASSET_IDS.md and
Shared.AmbiencePresets.TEXTURES.
"""
import math
import os

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/Models - Effects"


def grid(n, m=None):
    m = m or n
    xs = (np.arange(m) + 0.5) / m * 2 - 1
    ys = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(xs, -ys)
    return x, y, np.hypot(x, y), np.arctan2(y, x)


def value_noise(shape, cells, seed):
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


def aa(d, px):
    """signed distance (inside < 0) -> alpha with a px-wide soft edge"""
    return np.clip(0.5 - d / px, 0, 1)


# ------------------------------------------------------------------------------------------------ textures
def leaf(n=128):
    x, y, r, t = grid(n)
    # tilt the leaf 35 degrees so the rotating particle never looks axis-aligned
    c, s = math.cos(0.6), math.sin(0.6)
    u, v = x * c - y * s, x * s + y * c
    # a pointed lens: half-width 0 at both tips (u = -0.85 base, u = 0.9 tip), widest a little behind the middle
    k = np.clip((u + 0.85) / 1.75, 0, 1)
    w = 0.36 * np.sin(k * math.pi) ** 0.9 * (1 - 0.25 * k)
    mid = v - 0.08 * (u * u - 0.4)  # a gentle curl
    d = np.where(w > 0.002, (np.abs(mid) - w) * n / 2, 99.0)
    a = aa(d, 1.4)
    # a short stem past the base
    stem = aa((np.abs(mid) - 0.022) * n / 2, 1.2) * ((u < -0.8) & (u > -1.0))
    a = np.maximum(a, stem)
    vein = np.exp(-(mid / 0.028) ** 2) * (u < 0.8)
    rgb = 1 - 0.3 * vein - 0.14 * np.clip(mid / 0.36, 0, 1)
    return a, rgb


def petal(n=128):
    x, y, r, t = grid(n)
    c, s = math.cos(-0.4), math.sin(-0.4)
    u, v = x * c - y * s, x * s + y * c
    # a teardrop: a round top (circle at v = 0.2, radius 0.52) narrowing to the base point (v = -0.85)
    top = np.hypot(u, v - 0.2) - 0.52
    w = np.clip(v + 0.85, 0, None) * 0.57  # the tangents from the base point to the circle (asin(0.52 / 1.05))
    low = np.where((v < -0.058) & (v > -0.85), (np.abs(u) - w) * 0.87, 99.0)
    d = np.minimum(top, low) * n / 2
    notch = np.hypot(u, v - 0.78) - 0.13
    d = np.maximum(d, -notch * n / 2)
    a = aa(d, 1.4)
    k = np.clip((v + 0.85) / 1.6, 0, 1)
    rgb = 0.8 + 0.2 * k  # a deeper base, a pale tip (the tint reads pink -> white)
    return a, rgb


def paper(n=128):
    x, y, r, t = grid(n)
    c, s = math.cos(0.35), math.sin(0.35)
    u, v = x * c - y * s, x * s + y * c
    hw, hh = 0.5, 0.66
    d = np.maximum(np.abs(u) - hw, np.abs(v) - hh) * n / 2
    a = aa(d, 1.3)
    # folded top-right corner
    fold = (u + v) - (hw + hh - 0.32)
    a = a * aa(fold * n / 2, 1.3)
    flap = (fold < 0) & (fold > -0.32) & (u - v > (hw - hh) - 0.32 + 0.0) & (u > hw - 0.32) & (v > hh - 0.32)
    rgb = np.ones_like(a)
    rgb = np.where(flap, 0.8, rgb)
    for i in range(5):
        ly = 0.42 - i * 0.2
        line = (np.abs(v - ly) < 0.025) & (u > -0.38) & (u < (0.3 if i else 0.1))
        rgb = np.where(line, 0.72, rgb)
    return a, rgb


def mist(n=256):
    x, y, r, t = grid(n)
    noise = fbm((n, n), (3, 3), 11, 5)
    a = np.clip(1 - r / 0.95, 0, 1) ** 1.6
    a = a * (0.45 + 0.75 * noise)
    a = np.clip(a / a.max(), 0, 1) ** 1.2
    return a * 0.9, np.ones_like(a)


def square(n=64):
    x, y, r, t = grid(n)
    q = 0.72
    d = (np.maximum(np.abs(x), np.abs(y)) - q) * n / 2
    a = aa(d, 1.6)
    # a soft top-left light so it reads as a little block, not a flat dot
    rgb = 0.86 + 0.14 * np.clip((y - x) * 0.6 + 0.5, 0, 1)
    return a, rgb


def bubble(n=128):
    x, y, r, t = grid(n)
    ring = aa((np.abs(r - 0.78) - 0.07) * n / 2, 1.5)
    fill = np.clip(1 - r / 0.8, 0, 1) * 0.18
    hl = np.exp(-(((x + 0.32) / 0.14) ** 2 + ((y - 0.34) / 0.1) ** 2)) * 0.95
    a = np.clip(np.maximum(ring, fill) + hl, 0, 1) * (r < 0.9)
    return a, np.ones_like(a)


TEXTURES = {"amb_leaf": leaf, "amb_petal": petal, "amb_paper": paper, "amb_mist": mist,
            "amb_square": square, "amb_bubble": bubble}
TINTS = {"amb_leaf": (0.45, 0.8, 0.25), "amb_petal": (1.0, 0.7, 0.85), "amb_paper": (1.0, 0.97, 0.88),
         "amb_mist": (0.85, 0.95, 0.85), "amb_square": (1.0, 0.75, 0.35), "amb_bubble": (0.6, 0.9, 1.0)}


def save(name, a, rgb):
    h, w = a.shape
    rgba = np.ones((h, w, 4))
    rgba[..., 0] = rgba[..., 1] = rgba[..., 2] = np.clip(rgb, 0, 1)
    rgba[..., 3] = np.clip(a, 0, 1)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = np.flipud(rgba).astype(np.float32).ravel()
    os.makedirs(OUT, exist_ok=True)
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()


def preview(images, cell=256):
    names = list(images)
    cols = 3
    rows = math.ceil(len(names) / cols)
    sheet = np.zeros((rows * cell, cols * cell, 3)) + 0.08
    for i, name in enumerate(names):
        a, rgb = images[name]
        h, w = a.shape
        ys = np.arange(cell) * h // cell
        xs = np.arange(cell) * w // cell
        sa, srgb = a[np.ix_(ys, xs)], rgb[np.ix_(ys, xs)]
        rr, cc = divmod(i, cols)
        col = srgb[..., None] * np.array(TINTS[name])
        cellv = sheet[rr * cell:(rr + 1) * cell, cc * cell:(cc + 1) * cell]
        sheet[rr * cell:(rr + 1) * cell, cc * cell:(cc + 1) * cell] = cellv * (1 - sa[..., None]) + col * sa[..., None]
    rgba = np.ones((sheet.shape[0], sheet.shape[1], 4))
    rgba[..., :3] = np.clip(sheet, 0, 1)
    img = bpy.data.images.new("amb_preview", rgba.shape[1], rgba.shape[0], alpha=True)
    img.pixels = np.flipud(rgba).astype(np.float32).ravel()
    img.filepath_raw = os.path.join(OUT, "amb_preview.png")
    img.file_format = "PNG"
    img.save()
    return img.filepath_raw


def build():
    images = {}
    for name, fn in TEXTURES.items():
        a, rgb = fn()
        images[name] = (a, rgb)
        save(name, a, rgb)
    return preview(images)


print(build())
