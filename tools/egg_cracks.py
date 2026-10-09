"""Egg crack growth sequence for the 3D hatch (run inside Blender: exec(open(".../tools/egg_cracks.py").read())).

Procedural cracks: jagged fissures radiate from an impact point, branch, taper and stay inside an egg-shaped
mask (so on the egg's front face they never hang past the silhouette). Every segment has a "birth time", so the
same crack network is drawn at N growth stages: stage k shows everything born before k/N, the newest segments
part-drawn - played in order, the cracks spread.
Two layers per stage (both white + alpha, tinted in Roblox):
  egg_crack_dark_XX  the fissure itself (tinted near-black brown)
  egg_crack_glow_XX  a thin hot core + soft halo inside the fissure (tinted cream, then the rarity colour)
Output: "Models - Effects/egg_crack_{dark,glow}_01..N.png" (512x640, the egg's 7 x 8.6 front) + preview sheet.
"""
import math
import os

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/Models - Effects"
W, H = 512, 640
N = 10
rng = np.random.default_rng(11)


def inside(x, y):
    """egg-shaped mask (x, y in 0..1, y down): a little narrower at the top, inset from the silhouette"""
    sx = 0.34 * (0.86 + 0.14 * y)
    return ((x - 0.5) / sx) ** 2 + ((y - 0.53) / 0.40) ** 2 < 1


segments = []  # x0, y0, x1, y1, width(px), t0, t1


def grow(x, y, ang, width, t, depth, steps):
    for _ in range(int(steps)):
        seglen = rng.uniform(0.04, 0.075)
        ang += rng.normal(0, 0.55)  # long straight runs with sharp kinks: eggshell, not lightning
        nx, ny = x + math.cos(ang) * seglen, y + math.sin(ang) * seglen
        if not inside(nx, ny):
            break
        dt = seglen * 1.7
        segments.append((x, y, nx, ny, width, t, t + dt))
        if depth < 1 and rng.random() < 0.22:
            grow(nx, ny, ang + rng.choice([-1, 1]) * rng.uniform(0.55, 1.2), width * 0.62, t + dt, depth + 1, steps * 0.45)
        x, y, t = nx, ny, t + dt
        width = max(width * 0.9, 3.8)  # bold: the egg is ~300 px tall on screen


# one big impact a little above centre, then two smaller ones that start later
for cx, cy, arms, w0, t0 in ((0.5, 0.45, 5, 12.0, 0.0), (0.38, 0.68, 3, 8.5, 0.4), (0.63, 0.29, 2, 7.5, 0.6)):
    base = rng.uniform(0, math.tau)
    for k in range(arms):
        grow(cx, cy, base + k * math.tau / arms + rng.normal(0, 0.3), w0, t0 + k * 0.02, 0, rng.integers(5, 9))

tmax = max(s[6] for s in segments)
segments = [(a, b, c, d, w, t0 / tmax, t1 / tmax) for a, b, c, d, w, t0, t1 in segments]

ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)


def render(p):
    dark = np.zeros((H, W), np.float32)
    glow = np.zeros((H, W), np.float32)
    for x0, y0, x1, y1, w, t0, t1 in segments:
        if t0 >= p:
            continue
        f = min(1.0, (p - t0) / max(t1 - t0, 1e-6))
        ax, ay = x0 * W, y0 * H
        bx, by = (x0 + (x1 - x0) * f) * W, (y0 + (y1 - y0) * f) * H
        pad = w * 3 + 4
        lx0, lx1 = int(max(min(ax, bx) - pad, 0)), int(min(max(ax, bx) + pad, W - 1)) + 1
        ly0, ly1 = int(max(min(ay, by) - pad, 0)), int(min(max(ay, by) + pad, H - 1)) + 1
        px, py = xs[ly0:ly1, lx0:lx1], ys[ly0:ly1, lx0:lx1]
        vx, vy = bx - ax, by - ay
        L2 = vx * vx + vy * vy + 1e-6
        u = np.clip(((px - ax) * vx + (py - ay) * vy) / L2, 0, 1)
        d = np.hypot(px - (ax + u * vx), py - (ay + u * vy))
        half = w * 0.5
        dk = np.clip(1 - (d - half - 1.5) / 1.5, 0, 1)                       # crisp fissure, a rim wider than the core
        gl = np.clip(1 - d / max(half * 0.55, 1.0), 0, 1) + 0.5 * np.exp(-d / (w * 1.2))  # hot core + halo
        dark[ly0:ly1, lx0:lx1] = np.maximum(dark[ly0:ly1, lx0:lx1], dk)
        glow[ly0:ly1, lx0:lx1] = np.maximum(glow[ly0:ly1, lx0:lx1], np.clip(gl, 0, 1))
    return dark, glow


def save(name, a):
    rgba = np.ones((H, W, 4), np.float32)
    rgba[..., 3] = a
    img = bpy.data.images.get(name)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, W, H, alpha=True)
    img.pixels = np.flipud(rgba).ravel()
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()


def build():
    sheet = np.zeros((H // 2 * 2, W // 2 * 5, 3), np.float32) + 0.55   # stages 2,4,..,10 over an egg-ish grey
    for k in range(1, N + 1):
        dark, glow = render(k / N)
        save("egg_crack_dark_%02d" % k, dark)
        save("egg_crack_glow_%02d" % k, glow)
        if k % 2 == 0:
            c = (k // 2 - 1)
            d2, g2 = dark[::2, ::2], glow[::2, ::2]
            tile = sheet[0:H // 2, c * W // 2:(c + 1) * W // 2]
            tile[:] = tile * (1 - d2[..., None]) + np.array([0.16, 0.1, 0.08]) * d2[..., None]
            tile[:] = np.clip(tile + g2[..., None] * np.array([1.0, 0.85, 0.4]), 0, 1)
            # bottom row: same stage, rarity-blue glow
            tile2 = sheet[H // 2:, c * W // 2:(c + 1) * W // 2]
            tile2[:] = tile2 * (1 - d2[..., None]) + np.array([0.16, 0.1, 0.08]) * d2[..., None]
            tile2[:] = np.clip(tile2 + g2[..., None] * np.array([0.3, 0.6, 1.0]), 0, 1)
    rgba = np.ones((sheet.shape[0], sheet.shape[1], 4), np.float32)
    rgba[..., :3] = sheet
    img = bpy.data.images.get("egg_crack_preview")
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new("egg_crack_preview", sheet.shape[1], sheet.shape[0], alpha=True)
    img.pixels = np.flipud(rgba).ravel()
    img.filepath_raw = os.path.join(OUT, "egg_crack_preview.png")
    img.file_format = "PNG"
    img.save()
    return "%d segments -> %s" % (len(segments), img.filepath_raw)


print(build())
