"""UI textures for the Shop / Lawyer Merger panels (run inside Blender: exec(open(".../tools/ui_textures.py").read())).

Matches the user's reference panels ("Trail Shop", "Fuse Machine"):
  ui_studs.png    a tileable Lego-stud pattern (one stud per tile: a soft ring + a highlight arc, white+alpha) -
                  tinted and laid over every panel/card at low opacity, like the references' studded backgrounds
  ui_shine.png    two diagonal light stripes (white+alpha) for the purple header bars
Output: "Models - Effects/ui_*.png".
"""
import math
import os

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/Models - Effects"


def save(name, a):
    h, w = a.shape
    rgba = np.ones((h, w, 4), np.float32)
    rgba[..., 3] = np.clip(a, 0, 1)
    img = bpy.data.images.get(name)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = np.flipud(rgba).ravel()
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()


def studs(n=64):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32) + 0.5
    cx = cy = n / 2
    r = np.hypot(x - cx, y - cy) / (n / 2)
    ring = np.exp(-((r - 0.62) / 0.07) ** 2)  # the stud's rim
    ang = np.arctan2(y - cy, x - cx)
    highlight = np.exp(-((r - 0.5) / 0.08) ** 2) * np.clip(np.cos(ang + math.pi * 0.75), 0, 1)  # top-left gleam
    return np.clip(ring * 0.75 + highlight * 0.6, 0, 1)


def shine(w=512, h=128):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = x + y * 0.9  # diagonal coordinate
    a = np.zeros_like(d)
    for center, width in ((w * 0.62, 34), (w * 0.74, 14)):
        a = np.maximum(a, np.clip(1 - np.abs(d - center) / width, 0, 1) ** 0.6)
    return a


save("ui_studs", studs())
save("ui_shine", shine())
print("ok")
