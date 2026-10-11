# Tileable normal map of ONE stud per tile for the BrickStuds MaterialVariant (2026-10-11 brick character style).
# Run: Blender -b --factory-startup --python tools/stud_normal.py -- art/materials/stud_normal.png
# A rounded-square stud (like Roblox's own studs) raised from a flat face with a soft bevel; OpenGL normal format
# (+Y up), which is what Roblox expects.
import bpy, sys, numpy as np
out = sys.argv[-1]
N = 256
y, x = np.mgrid[0:N, 0:N].astype(np.float32)
u = (x + 0.5) / N - 0.5
v = (y + 0.5) / N - 0.5
half, r, bevel = 0.30, 0.10, 0.05          # stud half-size, corner radius, bevel width (tile units)
qx = np.maximum(np.abs(u) - (half - r), 0.0)
qy = np.maximum(np.abs(v) - (half - r), 0.0)
d = np.sqrt(qx * qx + qy * qy) - r          # signed distance to the rounded square (negative inside)
t = np.clip(-d / bevel, 0.0, 1.0)
height = t * t * (3 - 2 * t)                 # smoothstep: flat top, soft sides
dx = np.gradient(height, axis=1) * N * 0.06
dy = np.gradient(height, axis=0) * N * 0.06
n = np.stack([-dx, -dy, np.ones_like(dx)], axis=-1)
n /= np.linalg.norm(n, axis=-1, keepdims=True)
rgb = n * 0.5 + 0.5
img = bpy.data.images.new("stud_normal", N, N, alpha=False)
img.colorspace_settings.name = 'Non-Color'
px = np.concatenate([rgb, np.ones((N, N, 1), np.float32)], axis=-1)
img.pixels[:] = px.ravel()
img.filepath_raw = out
img.file_format = 'PNG'
img.save()
print("WROTE", out)
