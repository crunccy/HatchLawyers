"""Legendary effect textures for Roblox particles / beams (run inside Blender: exec(open(...).read())).

Glowy, magical style (user's pick). Every texture is WHITE with an alpha channel so Roblox tints it per rarity
(ParticleEmitter.Color: gold for Legendary, blue for Rare, a rainbow sequence for Rainbow merges) and adds it on
top of the scene with LightEmission = 1. Only the coin is pre-coloured. Written to
"Models - Effects/<name>.png" and loaded into Blender as images (plus a preview sheet on a dark background).
"""
import math
import os

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/Models - Effects"


def grid(n):
    """Centred coordinates in -1..1 (x right, y up), radius and angle."""
    v = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(v, -v)
    return x, y, np.hypot(x, y), np.arctan2(y, x)


def smooth_edge(a, r, start=0.92):
    """Fade alpha to 0 before the texture's edge (no hard square borders in game)."""
    return a * np.clip((1.0 - r) / (1.0 - start), 0, 1) ** 0.5 if start < 1 else a


def glow(n=256):
    _, _, r, _ = grid(n)
    a = np.exp(-(r / 0.42) ** 2) + 0.35 * np.exp(-(r / 0.12) ** 2)
    return smooth_edge(np.clip(a, 0, 1), r)


def flare4(n=256):
    """4-point lens-flare star: two crossed streaks + a hot core + soft halo."""
    x, y, r, _ = grid(n)
    streak = np.exp(-np.abs(y) / 0.018) * np.exp(-np.abs(x) / 0.55) + np.exp(-np.abs(x) / 0.018) * np.exp(-np.abs(y) / 0.55)
    core = np.exp(-(r / 0.09) ** 2)
    halo = 0.35 * np.exp(-(r / 0.35) ** 2)
    return smooth_edge(np.clip(streak + core + halo, 0, 1), r)


def twinkle8(n=256):
    """8-ray twinkle: long cardinal rays, shorter diagonal ones."""
    x, y, r, t = grid(n)
    a = np.zeros_like(r)
    for k in range(8):
        ang = k * math.pi / 4
        length = 0.9 if k % 2 == 0 else 0.5
        # distance across / along the ray
        along = x * math.cos(ang) + y * math.sin(ang)
        across = -x * math.sin(ang) + y * math.cos(ang)
        ray = np.exp(-np.abs(across) / (0.012 + 0.03 * np.clip(1 - along / length, 0, 1) * 0)) * np.clip(1 - along / length, 0, 1) ** 1.6
        a = np.maximum(a, np.where(along > 0, ray, 0))
    a = a + np.exp(-(r / 0.08) ** 2) + 0.25 * np.exp(-(r / 0.25) ** 2)
    return smooth_edge(np.clip(a, 0, 1), r)


def rays(n=512, count=14):
    """Sunburst: soft-edged god rays fading outward (rotate it behind a legendary)."""
    _, _, r, t = grid(n)
    wave = (np.cos(t * count) * 0.5 + 0.5) ** 3.0
    fade = np.clip(1 - r, 0, 1) ** 1.2 * np.clip(r / 0.12, 0, 1)
    a = wave * fade + 0.5 * np.exp(-(r / 0.2) ** 2)
    return smooth_edge(np.clip(a, 0, 1), r, 0.85)


def ring(n=512):
    """Shockwave: a bright thin ring with a soft inner fill."""
    _, _, r, _ = grid(n)
    band = np.exp(-((r - 0.78) / 0.05) ** 2)
    inner = 0.18 * np.clip(r / 0.78, 0, 1) ** 4 * (r < 0.78)
    return smooth_edge(np.clip(band + inner, 0, 1), r, 0.95)


def wisp(n=256):
    """Rising wisp / flame tongue (for auras drifting upward)."""
    x, y, r, _ = grid(n)
    yy = (y + 1) / 2                                   # 0 bottom .. 1 top
    width = 0.32 * (1 - yy) ** 0.7 + 0.03
    sway = 0.12 * np.sin(yy * 5.5)
    body = np.exp(-((x - sway) / width) ** 2) * np.clip(yy * 3, 0, 1) * (1 - yy) ** 0.6
    return smooth_edge(np.clip(body * 1.2, 0, 1), r, 0.97)


def swirl(n=512, arms=3):
    """Magic swirl: soft spiral arms around a bright centre."""
    _, _, r, t = grid(n)
    spiral = (np.cos(arms * (t - 3.2 * np.log(r + 0.05))) * 0.5 + 0.5) ** 4
    a = spiral * np.exp(-(r / 0.6) ** 2) + np.exp(-(r / 0.1) ** 2)
    return smooth_edge(np.clip(a, 0, 1), r, 0.9)


def column(n=256):
    """Beam texture: a bright vertical column, soft at the sides (Beam texture runs along U)."""
    x, y, _, _ = grid(n)
    across = np.exp(-(y / 0.35) ** 2)             # Roblox beam width runs along the texture's V
    along = np.clip(1 - np.abs(x), 0, 1) ** 0.25
    return np.clip(across * along, 0, 1)


def dot(n=128):
    """Tiny hot dot for dense sparkle dust."""
    _, _, r, _ = grid(n)
    return smooth_edge(np.clip(np.exp(-(r / 0.22) ** 2) * 1.2, 0, 1), r)


def coin(n=256):
    """Gold coin (pre-coloured): rim, face, star emboss and a shine."""
    x, y, r, t = grid(n)
    rgba = np.zeros((n, n, 4))
    face = r < 0.82
    rim = (r >= 0.82) & (r < 0.95)
    gold_lo = np.array([0.85, 0.55, 0.05])
    gold_hi = np.array([1.0, 0.86, 0.25])
    shade = np.clip(0.5 + 0.5 * (y - x) / 1.4, 0, 1)[..., None]
    col = gold_lo + (gold_hi - gold_lo) * shade
    rgba[..., :3] = col
    rgba[rim, :3] = gold_lo * 0.9
    # 5-point star emboss
    star_r = 0.42 * (0.55 + 0.45 * (np.cos(5 * (t - math.pi / 2)) * 0.5 + 0.5) ** 0.6)
    star = (r < star_r) & face
    rgba[star, :3] = np.clip(gold_hi * 1.08, 0, 1)
    # shine
    shine = np.exp(-(((x + 0.35) / 0.18) ** 2 + ((y - 0.35) / 0.32) ** 2))
    rgba[..., :3] = np.clip(rgba[..., :3] + shine[..., None] * 0.5, 0, 1)
    edge = np.clip((0.95 - r) / 0.03, 0, 1)
    rgba[..., 3] = edge
    return rgba


TEXTURES = {
    "fx_glow": glow, "fx_flare": flare4, "fx_twinkle": twinkle8, "fx_rays": rays, "fx_ring": ring,
    "fx_wisp": wisp, "fx_swirl": swirl, "fx_column": column, "fx_dot": dot, "fx_coin": coin,
}


def save(name, data):
    if data.ndim == 2:                         # white + alpha
        n = data.shape[0]
        rgba = np.ones((n, n, 4))
        rgba[..., 3] = data
    else:
        rgba = data
    h, w = rgba.shape[0], rgba.shape[1]
    img = bpy.data.images.get(name)
    if img and (img.size[0] != w or img.size[1] != h):
        bpy.data.images.remove(img)
        img = None
    img = img or bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = np.flipud(rgba).astype(np.float32).ravel()   # Blender rows go bottom-up
    os.makedirs(OUT, exist_ok=True)
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()
    return img


def preview_sheet(images, cell=256):
    """All textures side by side on a dark background, tinted gold, for checking in Blender."""
    names = list(images)
    sheet = np.zeros((cell, cell * len(names), 4))
    sheet[..., :3] = 0.08
    sheet[..., 3] = 1
    gold = np.array([1.0, 0.8, 0.3])
    for i, name in enumerate(names):
        data = TEXTURES[name]()
        n = data.shape[0]
        idx = (np.arange(cell) * n // cell)
        d = data[np.ix_(idx, idx)]
        if d.ndim == 2:
            rgb = gold * d[..., None]
        else:
            rgb = d[..., :3] * d[..., 3:4]
        sheet[:, i * cell:(i + 1) * cell, :3] = np.clip(sheet[:, i * cell:(i + 1) * cell, :3] + rgb, 0, 1)
    save("fx_preview_sheet", sheet[:, :, :])
    return os.path.join(OUT, "fx_preview_sheet.png")


def build():
    for name, fn in TEXTURES.items():
        save(name, fn())
    return preview_sheet(TEXTURES)


print(build())
