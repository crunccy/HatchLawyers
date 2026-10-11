"""Client face textures (2026-10-10 client remodel). Each client's face is a transparent PNG decal on the front of its
head (Roblox-style face, like the classic smile), drawn here with anti-aliased signed-distance shapes so the lines
are clean at any size. Same face language as the lawyers (white eyes with an ink rim, dark pupils with a shine,
thick brows, a maroon mouth with white teeth) plus per-character expressions and extras (blush, freckles,
mustaches, wrinkles, stitches...).

Run headless with Blender's Python (for numpy + PNG writing):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python tools/client_faces.py -- [Ids...]
Output: art/client_faces/<Id>.png (520 x 480 = the 1.3 x 1.2 stud face plate at 400 px/stud).
Specs: FACES below (also read by tools/clients/*.lua only through the uploaded ids in src/ClientArt.lua).
"""
import math
import os
import sys

import bpy
import numpy as np

OUT = "/Users/ryanchen/HatchLawyers/art/client_faces"
PW, PH, PPS = 1.3, 1.2, 400  # plate width / height (studs), pixels per stud
W, H = int(PW * PPS), int(PH * PPS)
PX = 1.0 / PPS
INK = (0.09, 0.07, 0.11)
WHITE = (1.0, 1.0, 1.0)
MOUTH = (0.42, 0.09, 0.13)
TONGUE = (0.92, 0.38, 0.45)
BLUSH = (1.0, 0.45, 0.5)

# plate coordinates (studs): u right, v up, origin at the plate centre
_u = (np.arange(W) + 0.5) / PPS - PW / 2
_v = PH / 2 - (np.arange(H) + 0.5) / PPS
U, V = np.meshgrid(_u, _v)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


# ------------------------------------------------------------------ signed distances (negative inside)
def sd_ellipse(cx, cy, rx, ry, rot=0.0):
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    x, y = (U - cx) * c + (V - cy) * s, -(U - cx) * s + (V - cy) * c
    k = np.sqrt((x / rx) ** 2 + (y / ry) ** 2)
    return (k - 1) * min(rx, ry)


def sd_capsule(ax, ay, bx, by, r):
    px, py = U - ax, V - ay
    dx, dy = bx - ax, by - ay
    h = np.clip((px * dx + py * dy) / (dx * dx + dy * dy + 1e-9), 0, 1)
    return np.hypot(px - dx * h, py - dy * h) - r


def sd_arc(cx, cy, R, a0, a1, th):
    """a stroke along a circle from angle a0 to a1 (degrees, counter-clockwise), round caps"""
    ang = np.degrees(np.arctan2(V - cy, U - cx)) % 360
    lo, span = a0 % 360, (a1 - a0) % 360
    inside = ((ang - lo) % 360) <= span
    ring = np.abs(np.hypot(U - cx, V - cy) - R) - th / 2
    e0 = (cx + R * math.cos(math.radians(a0)), cy + R * math.sin(math.radians(a0)))
    e1 = (cx + R * math.cos(math.radians(a1)), cy + R * math.sin(math.radians(a1)))
    caps = np.minimum(np.hypot(U - e0[0], V - e0[1]), np.hypot(U - e1[0], V - e1[1])) - th / 2
    return np.where(inside, ring, caps)


def sd_halfplane(px, py, nx, ny):
    """inside = the side the normal points away from: distance = (p - p0) . n"""
    l = math.hypot(nx, ny)
    return ((U - px) * nx + (V - py) * ny) / l


def inter(a, b):
    return np.maximum(a, b)


def union(a, b):
    return np.minimum(a, b)


# ------------------------------------------------------------------ painting
class Canvas:
    def __init__(self):
        self.rgb = np.zeros((H, W, 3), np.float32)
        self.a = np.zeros((H, W), np.float32)

    def paint(self, sd, color, alpha=1.0, clip=None):
        cov = np.clip(0.5 - sd / PX, 0, 1) * alpha
        if clip is not None:
            cov = cov * np.clip(0.5 - clip / PX, 0, 1)
        col = np.array(color[:3], np.float32)
        na = cov + self.a * (1 - cov)
        self.rgb = (col * cov[..., None] + self.rgb * (self.a * (1 - cov))[..., None]) / np.maximum(na[..., None], 1e-6)
        self.a = na

    def outlined(self, sd, color, ink=0.022):
        self.paint(sd - ink, INK)
        self.paint(sd, color)

    def save(self, path):
        img = bpy.data.images.new("face", W, H, alpha=True)
        px = np.zeros((H, W, 4), np.float32)
        px[..., :3] = self.rgb
        px[..., 3] = self.a
        img.pixels.foreach_set(px[::-1].ravel())  # Blender images are bottom-up
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        bpy.data.images.remove(img)


# ------------------------------------------------------------------ features
def eye(c, cx, cy, e, skin, side):
    style = e.get("style", "open")
    rx, ry = e.get("rx", 0.12), e.get("ry", 0.15)
    lx, ly = e.get("look", (0.0, 0.0))
    if style == "happy":  # closed, smiling ^ arcs
        c.paint(sd_arc(cx, cy - ry * 0.35, rx * 0.95, 20, 160, 0.05), INK)
        return
    if style == "closed":  # calm closed v arcs
        c.paint(sd_arc(cx, cy + ry * 0.3, rx * 0.9, 200, 340, 0.045), INK)
        return
    if style == "dot":  # classic Roblox dot eyes
        c.paint(sd_ellipse(cx, cy, rx * 0.62, ry * 0.85), INK)
        c.paint(sd_ellipse(cx - rx * 0.18, cy + ry * 0.35, rx * 0.2, rx * 0.2), WHITE)
        return
    sclera = sd_ellipse(cx, cy, rx, ry)
    c.outlined(sclera, WHITE, 0.024)
    pr = e.get("pupil", 0.6)
    pc = hexc(e["iris"]) if e.get("iris") else INK
    pupil = sd_ellipse(cx + lx * rx, cy + ly * ry - ry * 0.05, rx * pr, ry * pr * 1.12)
    c.paint(pupil, pc, clip=sclera)
    if e.get("iris"):
        c.paint(sd_ellipse(cx + lx * rx, cy + ly * ry - ry * 0.05, rx * pr * 0.5, ry * pr * 0.56), INK, clip=sclera)
    c.paint(sd_ellipse(cx + lx * rx - rx * 0.22, cy + ly * ry + ry * 0.28, rx * 0.17, rx * 0.17), WHITE, clip=sclera)
    lid = e.get("lid", 0.0)  # 0 = none, 0.5 = half-closed (sleepy / bored)
    tilt = e.get("lidTilt", 0.0) * (1 if side > 0 else -1)  # + = angry (inner end down)
    if lid > 0 or tilt:
        top = cy + ry * (1 - 2 * lid)
        hp = sd_halfplane(cx, top, math.sin(math.radians(tilt)), -math.cos(math.radians(tilt)))
        c.paint(inter(hp, sclera - 0.024), hexc(skin))  # the lid covers the part of the eye ABOVE the lid line
        c.paint(inter(np.abs(hp) - 0.016, sclera - 0.024), INK)
    if e.get("lashes"):
        for k in range(3):
            a = math.radians(90 - side * (34 + k * 20))  # fanning out at the outer corner
            ox, oy = cx + math.cos(a) * rx * 0.97, cy + math.sin(a) * ry * 0.97
            c.paint(sd_capsule(ox, oy, ox + math.cos(a) * 0.05, oy + math.sin(a) * 0.05, 0.012), INK)


def brow(c, cx, cy, b, side, color):
    L, th, tilt = b.get("len", 0.24), b.get("th", 0.05), b.get("tilt", 0.0) * side
    arch = b.get("arch", 0.0)
    a = math.radians(tilt)
    dx, dy = math.cos(a) * L / 2, math.sin(a) * L / 2
    if arch:
        R = L / (2 * math.sin(math.radians(35)))
        mid = math.degrees(a) + 90
        c.outlined(sd_arc(cx - math.sin(a) * (R - arch), cy - math.cos(a) * (R - arch) + arch * 0, R, mid - 35, mid + 35, th), color, 0.016)
    else:
        c.outlined(sd_capsule(cx - dx, cy - dy, cx + dx, cy + dy, th / 2), color, 0.016)


def mouth(c, m, skin):
    style = m.get("style", "grin")
    if style == "none":
        return
    cx, cy, w = m.get("x", 0.0), m.get("y", -0.3), m.get("w", 0.42)
    if style in ("grin", "big"):
        d = m.get("d", 0.17 if style == "grin" else 0.24)
        R = (w * w / 4 + d * d) / (2 * d)  # circle through the corners and the bottom point
        circ = sd_ellipse(cx, cy - d / 2 + R, R, R)
        shape = inter(circ, sd_halfplane(cx, cy + d / 2, 0, 1))
        c.outlined(shape, MOUTH, 0.022)
        c.paint(inter(shape, sd_halfplane(cx, cy + d / 2 - d * 0.3, 0, -1)), WHITE, clip=shape)  # top teeth
        c.paint(sd_ellipse(cx + w * 0.06, cy - d * 0.42, w * 0.22, d * 0.3), TONGUE, clip=shape)
        if m.get("gap"):
            c.paint(sd_capsule(cx, cy + d / 2, cx, cy + d / 2 - d * 0.32, 0.008), INK, clip=shape)
    elif style == "smile":
        R = m.get("R", w * 0.75)
        sweep = math.degrees(math.asin(min(0.99, w / (2 * R))))
        c.paint(sd_arc(cx, cy + R * 0.85, R, 270 - sweep, 270 + sweep, m.get("th", 0.045)), INK)
    elif style == "smirk":
        R = w * 0.8
        c.paint(sd_arc(cx + w * 0.1, cy + R * 0.9, R, 255, 300, 0.045), INK)
    elif style == "flat":
        c.paint(sd_capsule(cx - w / 2, cy, cx + w / 2, cy, 0.022), INK)
    elif style == "frown":
        R = w * 0.75
        c.paint(sd_arc(cx, cy - R * 0.92, R, 62, 118, 0.045), INK)
    elif style == "o":
        c.outlined(sd_ellipse(cx, cy, w * 0.22, w * 0.27), MOUTH, 0.022)
    elif style == "wavy":  # nervous
        pts = [(cx - w / 2 + w * i / 6, cy + (0.025 if i % 2 else -0.025)) for i in range(7)]
        for p0, p1 in zip(pts, pts[1:]):
            c.paint(sd_capsule(p0[0], p0[1], p1[0], p1[1], 0.02), INK)
    elif style == "teeth":  # clenched grimace / determined
        shape = sd_capsule(cx - w / 2 + 0.06, cy, cx + w / 2 - 0.06, cy, 0.07)
        c.outlined(shape, WHITE, 0.022)
        for i in range(1, 5):
            x = cx - w / 2 + 0.06 + (w - 0.12) * i / 5
            c.paint(sd_capsule(x, cy - 0.06, x, cy + 0.06, 0.007), INK, clip=shape)
        c.paint(sd_capsule(cx - w / 2 + 0.03, cy, cx + w / 2 - 0.03, cy, 0.006), INK, clip=shape)


def under(c, f):
    """layers drawn BEHIND the eyes/mouth: monkey muzzle, clown paint"""
    for x in f.get("extras", []):
        k = x[0]
        if k == "muzzle":  # a lighter face patch: around both eyes + a big muzzle
            col = hexc(x[1])
            shape = union(union(sd_ellipse(-0.27, 0.1, 0.24, 0.24), sd_ellipse(0.27, 0.1, 0.24, 0.24)), sd_ellipse(0, -0.28, 0.42, 0.27))
            c.paint(shape, col)
        elif k == "clown":
            for s in (-1, 1):
                d = union(sd_ellipse(s * 0.29, 0.22, 0.06, 0.2), sd_ellipse(s * 0.29, -0.08, 0.06, 0.2))
                c.paint(d, hexc("3a7bff"), alpha=0.9)
                c.paint(sd_ellipse(s * 0.47, -0.16, 0.1, 0.08), hexc("ff4f6a"), alpha=0.8)
            c.paint(sd_ellipse(0, -0.33, 0.33, 0.17), hexc("ff4f6a"), alpha=0.85)


def robot(c, f):
    """B0-P's screen: a dark rounded display with glowing happy eyes and a smile"""
    scr = inter(sd_ellipse(0, 0, 0.64, 0.58), sd_capsule(-0.3, 0, 0.3, 0, 0.56))
    c.paint(scr - 0.02, INK)
    c.paint(scr, hexc("10202e"))
    glow = hexc(f.get("glow", "4ff0ff"))
    for s in (-1, 1):
        c.paint(sd_arc(s * 0.26, 0.02, 0.13, 20, 160, 0.13), glow, alpha=0.18)
        c.paint(sd_arc(s * 0.26, 0.02, 0.13, 20, 160, 0.06), glow)
    c.paint(sd_arc(0, -0.05, 0.24, 215, 325, 0.12), glow, alpha=0.18)
    c.paint(sd_arc(0, -0.05, 0.24, 215, 325, 0.05), glow)
    for s in (-1, 1):
        c.paint(sd_ellipse(s * 0.47, -0.2, 0.06, 0.035), hexc("ff6fae"), alpha=0.8)


def extras(c, f):
    skin = hexc(f["skin"])
    for x in f.get("extras", []):
        k = x[0]
        if k == "spot":  # (spot, x, y, rx, ry, hex, alpha)
            c.paint(sd_ellipse(x[1], x[2], x[3], x[4]), hexc(x[5]), alpha=x[6] if len(x) > 6 else 1.0)
        elif k == "paint":  # war-paint stripes under the eyes
            for s in (-1, 1):
                for dy in (0.0, -0.06):
                    c.paint(sd_capsule(s * 0.2, -0.1 + dy, s * 0.38, -0.1 + dy, 0.018), hexc(x[1]))
        elif k == "sparkle":
            for (sx, sy, r) in ((0.5, 0.25, 0.05), (0.58, 0.12, 0.03)):
                star = union(sd_capsule(sx - r, sy, sx + r, sy, r * 0.22), sd_capsule(sx, sy - r, sx, sy + r, r * 0.22))
                c.paint(star, hexc(x[1] if len(x) > 1 else "ffffff"))
        if k == "blush":
            for s in (-1, 1):
                c.paint(sd_ellipse(s * 0.44, -0.07, 0.075, 0.042), BLUSH, alpha=0.5)
        elif k == "freckles":
            for s in (-1, 1):
                for dx, dy in ((0.0, 0.0), (0.06, -0.035), (-0.05, -0.04), (0.03, 0.04)):
                    c.paint(sd_ellipse(s * (0.36 + dx), -0.1 + dy, 0.013, 0.013), hexc("b0643c"), alpha=0.85)
        elif k == "mustache":
            col = hexc(x[1])
            shape = union(sd_ellipse(-0.1, -0.16, 0.13, 0.055, -12), sd_ellipse(0.1, -0.16, 0.13, 0.055, 12))
            if len(x) > 2 and x[2] == "curly":
                shape = union(shape, union(sd_arc(-0.22, -0.11, 0.05, 150, 330, 0.035), sd_arc(0.22, -0.11, 0.05, 210, 30, 0.035)))
            c.outlined(shape, col, 0.018)
        elif k == "wrinkles":
            for s in (-1, 1):
                c.paint(sd_arc(s * 0.43, 0.07, 0.06, 90 + s * 70 - 30, 90 + s * 70 + 30, 0.014), INK, alpha=0.6)
            c.paint(sd_arc(0.0, 0.5, 0.18, 250, 290, 0.013), INK, alpha=0.45)
        elif k == "bags":
            for s in (-1, 1):
                c.paint(sd_arc(s * 0.3, -0.02, 0.09, 220, 320, 0.013), INK, alpha=0.5)
        elif k == "stitches":
            c.paint(sd_capsule(0.18, 0.42, 0.42, 0.25, 0.012), INK)
            for t in (0.2, 0.5, 0.8):
                px, py = 0.18 + 0.24 * t, 0.42 - 0.17 * t
                c.paint(sd_capsule(px - 0.03, py - 0.04, px + 0.03, py + 0.04, 0.009), INK)
        elif k == "scar":
            c.paint(sd_capsule(-0.42, 0.28, -0.26, 0.02, 0.016), hexc("c46a6a"))
        elif k == "stubble":
            rng = np.random.default_rng(3)
            for _ in range(70):
                px, py = rng.uniform(-0.33, 0.33), rng.uniform(-0.52, -0.2)
                if (px / 0.36) ** 2 + ((py + 0.3) / 0.3) ** 2 < 1:
                    c.paint(sd_ellipse(px, py, 0.008, 0.008), INK, alpha=0.35)
        elif k == "tear":
            c.outlined(sd_ellipse(0.42, -0.05, 0.03, 0.05), hexc("8fd8ff"), 0.012)
        elif k == "lipstick":
            pass
    return skin


def draw(f):
    c = Canvas()
    if f.get("robot"):
        robot(c, f)
        return c
    under(c, f)
    hair = hexc(f.get("brow", "3a2416"))
    e = f.get("eyes", {})
    sep, ey = e.get("sep", 0.29), e.get("y", 0.07)
    for side in (-1, 1):
        eye(c, side * sep, ey, e, f["skin"], side)
    b = f.get("brows", {})
    if b is not None and b.get("style") != "none":
        for side in (-1, 1):
            brow(c, side * (sep + b.get("dx", 0.0)), ey + b.get("dy", 0.26), b, side, hair)
    extras(c, f)
    mouth(c, f.get("mouth", {}), f["skin"])
    return c


# ------------------------------------------------------------------ the cast (skin + expression per client)
S1, S2, S3, S4, S5, S6 = "f6d2b0", "f1c49a", "e0a87a", "c98b5f", "a86a42", "7a4a2c"
FACES = {
    "NeighborDave": {
        "skin": "f1c49a", "brow": "6b4226",
        "eyes": {"style": "open", "rx": 0.115, "ry": 0.14, "look": (0.0, 0.05)},
        "brows": {"len": 0.25, "th": 0.06, "tilt": -10, "dy": 0.25},
        "mouth": {"style": "grin", "y": -0.33, "w": 0.4, "d": 0.16},
        "extras": [("mustache", "6b4226"), ("blush",)],
    },
    # ---- Common
    "GrandmaPearl": {"skin": S1, "brow": "b9b9c4", "eyes": {"rx": 0.1, "ry": 0.12, "lashes": True, "look": (0, 0.1)},
                     "brows": {"len": 0.2, "th": 0.035, "tilt": 8}, "mouth": {"style": "smile", "w": 0.34, "y": -0.3},
                     "extras": [("blush",), ("wrinkles",)]},
    "SkaterKev": {"skin": S3, "brow": "4a2a14", "eyes": {"lid": 0.38, "look": (0.25, 0.0)}, "brows": {"tilt": -6, "dy": 0.22},
                  "mouth": {"style": "smirk", "w": 0.4, "y": -0.3}, "extras": [("spot", -0.42, -0.1, 0.06, 0.035, "f2f2f2", 1.0)]},
    "MailCarrierMo": {"skin": S5, "brow": "1e1410", "eyes": {"rx": 0.12, "ry": 0.165, "look": (0, -0.05)}, "brows": {"tilt": -16, "dy": 0.28},
                      "mouth": {"style": "wavy", "w": 0.36, "y": -0.32}, "extras": [("tear",)]},
    "LemonadeLily": {"skin": S1, "brow": "c05a28", "eyes": {"rx": 0.12, "ry": 0.165, "lashes": True, "look": (0, 0.05)}, "brows": {"len": 0.22, "th": 0.04, "tilt": 6},
                     "mouth": {"style": "big", "w": 0.4, "y": -0.32}, "extras": [("freckles",), ("blush",)]},
    "GamerGabe": {"skin": S4, "brow": "1a1a1a", "eyes": {"lid": 0.18, "look": (0.15, 0.1)}, "brows": {"tilt": 10, "dy": 0.24},
                  "mouth": {"style": "teeth", "w": 0.42, "y": -0.32}, "extras": [("bags",)]},
    "GardenerGus": {"skin": S3, "brow": "e8e8e8", "eyes": {"style": "happy"}, "brows": {"len": 0.27, "th": 0.075, "tilt": -6, "dy": 0.27},
                    "mouth": {"style": "smile", "w": 0.36, "y": -0.3}, "extras": [("blush",), ("wrinkles",)]},
    "IceCreamIvy": {"skin": S6, "brow": "2a1810", "eyes": {"style": "happy"}, "brows": {"len": 0.22, "th": 0.045, "tilt": 6},
                    "mouth": {"style": "big", "w": 0.42, "y": -0.32}, "extras": [("blush",)]},
    "BarberBob": {"skin": S2, "brow": "1c1c1c", "eyes": {"look": (-0.15, 0.05)}, "brows": {"len": 0.24, "th": 0.05, "tilt": 8, "dy": 0.29},
                  "mouth": {"style": "smile", "w": 0.4, "y": -0.36}, "extras": [("mustache", "1c1c1c", "curly")]},
    "CrossingGuardCarol": {"skin": S5, "brow": "2a1810", "eyes": {"lidTilt": 16, "lashes": True}, "brows": {"tilt": 16, "dy": 0.25},
                           "mouth": {"style": "flat", "w": 0.3, "y": -0.32}, "extras": []},
    "LibrarianLou": {"skin": S4, "brow": "dcdcdc", "eyes": {"lid": 0.45, "rx": 0.11}, "brows": {"len": 0.25, "th": 0.06, "tilt": 12, "dy": 0.25},
                     "mouth": {"style": "o", "w": 0.34, "y": -0.32}, "extras": [("wrinkles",)]},
    "CamperCam": {"skin": S2, "brow": "7a4422", "eyes": {"look": (0, 0.05)}, "brows": {"th": 0.06, "tilt": -4},
                  "mouth": {"style": "grin", "w": 0.4, "y": -0.28}, "extras": [("blush",)]},
    "YogaYasmin": {"skin": S4, "brow": "1a1410", "eyes": {"style": "closed"}, "brows": {"len": 0.22, "th": 0.04, "tilt": 4},
                   "mouth": {"style": "smile", "w": 0.32, "y": -0.3}, "extras": [("blush",), ("spot", 0.0, 0.33, 0.035, 0.035, "e05a8a", 1.0)]},
    # ---- Uncommon
    "RosaTheBaker": {"skin": S3, "brow": "1a1410", "eyes": {"lashes": True, "look": (0, 0.05)}, "brows": {"tilt": 12},
                     "mouth": {"style": "big", "w": 0.44, "y": -0.32}, "extras": [("blush",), ("spot", 0.42, 0.22, 0.07, 0.04, "ffffff", 0.9)]},
    "CaptainBarnacle": {"skin": S3, "brow": "f0f0f0", "eyes": {"lid": 0.28, "look": (0.1, 0)}, "brows": {"len": 0.3, "th": 0.08, "tilt": -6, "dy": 0.27},
                        "mouth": {"style": "grin", "w": 0.36, "y": -0.27, "d": 0.12}, "extras": [("wrinkles",)]},
    "DrFizz": {"skin": S1, "brow": "ffffff", "eyes": {"rx": 0.13, "ry": 0.17, "iris": "3fc04a", "pupil": 0.55}, "brows": {"style": "none"},
               "mouth": {"style": "big", "w": 0.44, "y": -0.33, "gap": True}, "extras": [("spot", -0.4, 0.3, 0.09, 0.05, "6a6a6a", 0.5), ("spot", 0.35, -0.15, 0.06, 0.04, "6a6a6a", 0.45)]},
    "FirefighterFaye": {"skin": S5, "brow": "3a1a10", "eyes": {"lashes": True}, "brows": {"tilt": 6},
                        "mouth": {"style": "grin", "w": 0.4, "y": -0.32}, "extras": [("spot", -0.4, -0.12, 0.08, 0.045, "3a3a3a", 0.45)]},
    "MagicianMarvin": {"skin": S2, "brow": "1a1a1a", "eyes": {"look": (0.2, 0.1), "lidTilt": 10}, "brows": {"len": 0.26, "th": 0.045, "tilt": 14, "dy": 0.28},
                       "mouth": {"style": "smirk", "w": 0.4, "y": -0.34}, "extras": [("mustache", "1a1a1a", "curly")]},
    "FarmerFrank": {"skin": S3, "brow": "6b3a1e", "eyes": {"style": "happy"}, "brows": {"len": 0.27, "th": 0.07, "tilt": -6},
                    "mouth": {"style": "big", "w": 0.42, "y": -0.28}, "extras": [("blush",)]},
    "NurseNina": {"skin": S6, "brow": "1a1410", "eyes": {"lid": 0.45, "lashes": True}, "brows": {"len": 0.22, "th": 0.04, "tilt": 2},
                  "mouth": {"style": "smile", "w": 0.34, "y": -0.3}, "extras": [("blush",)]},
    "MechanicMax": {"skin": S4, "brow": "1a1a1a", "eyes": {"look": (-0.1, 0.05)}, "brows": {"th": 0.065, "tilt": 4},
                    "mouth": {"style": "grin", "w": 0.4, "y": -0.32}, "extras": [("stubble",), ("spot", 0.38, 0.28, 0.07, 0.04, "2a2a2a", 0.6)]},
    "ArtistAria": {"skin": S1, "brow": "1a1410", "eyes": {"lashes": True, "look": (0.1, 0.25)}, "brows": {"len": 0.22, "th": 0.04, "tilt": -4},
                   "mouth": {"style": "smile", "w": 0.32, "y": -0.3}, "extras": [("blush",), ("spot", -0.4, 0.28, 0.04, 0.04, "3a8bff", 1.0), ("spot", 0.43, -0.2, 0.035, 0.035, "ff4fa0", 1.0)]},
    "WrestlerRonda": {"skin": S3, "brow": "5a2a14", "eyes": {"lidTilt": 22}, "brows": {"th": 0.07, "tilt": 22, "dy": 0.23},
                      "mouth": {"style": "teeth", "w": 0.44, "y": -0.32}, "extras": [("paint", "1a1a1a")]},
    "PilotPaige": {"skin": S2, "brow": "c89a40", "eyes": {"lashes": True, "look": (0, 0.05)}, "brows": {"len": 0.22, "th": 0.045, "tilt": 6},
                   "mouth": {"style": "smile", "w": 0.36, "y": -0.3}, "extras": [("freckles",)]},
    "MusicianMoe": {"skin": S6, "brow": "1a1410", "eyes": {"style": "closed"}, "brows": {"tilt": -8, "dy": 0.27},
                    "mouth": {"style": "o", "w": 0.36, "y": -0.32}, "extras": [("spot", -0.42, -0.2, 0.13, 0.1, "ff8a8a", 0.45), ("spot", 0.42, -0.2, 0.13, 0.1, "ff8a8a", 0.45)]},
    # ---- Rare
    "BaronVonBanana": {"skin": "7a4a2a", "brow": "3a2010", "eyes": {"lidTilt": 8, "look": (0.1, 0)}, "brows": {"th": 0.05, "tilt": 10},
                       "mouth": {"style": "smirk", "w": 0.4, "y": -0.3}, "extras": [("muzzle", "e2bf92")]},
    "BeepBot": {"skin": "ffffff", "robot": True, "glow": "4ff0ff"},
    "PiratePatches": {"skin": S3, "brow": "1a1a1a", "eyes": {"lidTilt": 10}, "brows": {"th": 0.065, "tilt": 16},
                      "mouth": {"style": "grin", "w": 0.42, "y": -0.32, "gap": True}, "extras": [("scar",)]},
    "CowboyCody": {"skin": S3, "brow": "6b3a1e", "eyes": {"lid": 0.32, "look": (0.1, 0)}, "brows": {"th": 0.055, "tilt": 6},
                   "mouth": {"style": "smirk", "w": 0.38, "y": -0.34}, "extras": [("mustache", "6b3a1e")]},
    "ZombieZeke": {"skin": "98c880", "brow": "3a4a2a", "eyes": {"pupil": 0.35, "lid": 0.2, "look": (0.2, -0.1)}, "brows": {"th": 0.05, "tilt": -10},
                   "mouth": {"style": "wavy", "w": 0.4, "y": -0.32}, "extras": [("stitches",), ("bags",)]},
    "NinjaNoodle": {"skin": S4, "brow": "1a1a1a", "eyes": {"lidTilt": 16}, "brows": {"th": 0.06, "tilt": 20, "dy": 0.22},
                    "mouth": {"style": "none"}, "extras": []},
    "KnightKevin": {"skin": S2, "brow": "c8862c", "eyes": {"rx": 0.12, "ry": 0.16, "look": (0, 0.08)}, "brows": {"th": 0.06, "tilt": 10},
                    "mouth": {"style": "grin", "w": 0.38, "y": -0.32}, "extras": []},
    "MermaidMarina": {"skin": S1, "brow": "b0283a", "eyes": {"lashes": True, "iris": "2fb0d0", "rx": 0.12, "ry": 0.16}, "brows": {"len": 0.22, "th": 0.04, "tilt": 4},
                      "mouth": {"style": "big", "w": 0.38, "y": -0.32}, "extras": [("blush",)]},
    "ClownChuckles": {"skin": "fff3e6", "brow": "d0202a", "eyes": {"rx": 0.12, "ry": 0.15}, "brows": {"th": 0.05, "tilt": -12, "dy": 0.3},
                      "mouth": {"style": "big", "w": 0.46, "y": -0.33}, "extras": [("clown",)]},
    # ---- Epic and up
    "RetiredCEO": {"skin": S1, "brow": "f0f0f0", "eyes": {"lid": 0.35, "lidTilt": 6}, "brows": {"len": 0.28, "th": 0.075, "tilt": 6},
                   "mouth": {"style": "flat", "w": 0.26, "y": -0.36}, "extras": [("wrinkles",), ("mustache", "f2f2f2")]},
    "TechTed": {"skin": S4, "brow": "1a1a1a", "eyes": {"look": (0.15, 0.05)}, "brows": {"th": 0.05, "tilt": 4},
                "mouth": {"style": "smile", "w": 0.38, "y": -0.3}, "extras": []},
    "MovieStarMaya": {"skin": S5, "brow": "1a1410", "eyes": {"lashes": True, "iris": "8a4a20", "lid": 0.15}, "brows": {"len": 0.22, "th": 0.04, "tilt": 8},
                      "mouth": {"style": "smile", "w": 0.36, "y": -0.3}, "extras": [("blush",), ("spot", 0.3, -0.18, 0.018, 0.018, "2a1810", 1.0)]},
    "KingReginald": {"skin": S2, "brow": "f0f0f0", "eyes": {"rx": 0.12, "ry": 0.15, "look": (0, 0.2)}, "brows": {"len": 0.27, "th": 0.07, "tilt": -16, "dy": 0.28},
                     "mouth": {"style": "wavy", "w": 0.34, "y": -0.28}, "extras": [("blush",)]},
    "AstronautAce": {"skin": S5, "brow": "1a1410", "eyes": {"rx": 0.12, "ry": 0.16, "look": (0, 0.1)}, "brows": {"tilt": -4},
                     "mouth": {"style": "big", "w": 0.42, "y": -0.32}, "extras": []},
    "ChefMega": {"skin": S2, "brow": "1a1a1a", "eyes": {"style": "happy"}, "brows": {"th": 0.06, "tilt": -4, "dy": 0.27},
                 "mouth": {"style": "grin", "w": 0.4, "y": -0.36}, "extras": [("mustache", "1a1a1a", "curly"), ("blush",)]},
    "RocketBaronRex": {"skin": S3, "brow": "6b3a1e", "eyes": {"lidTilt": 6, "look": (0.1, 0.1)}, "brows": {"th": 0.06, "tilt": 10},
                       "mouth": {"style": "grin", "w": 0.4, "y": -0.32}, "extras": [("freckles",)]},
    "MiloVex": {"skin": S1, "brow": "e0c060", "eyes": {"lid": 0.2}, "brows": {"len": 0.22, "th": 0.045, "tilt": 10},
                "mouth": {"style": "smirk", "w": 0.38, "y": -0.32}, "extras": []},
    "DJBeatbox": {"skin": S6, "brow": "1a1a1a", "eyes": {"style": "closed"}, "brows": {"th": 0.06, "tilt": 4},
                  "mouth": {"style": "big", "w": 0.44, "y": -0.32}, "extras": []},
    "KikiGlow": {"skin": S1, "brow": "e070b0", "eyes": {"lashes": True, "iris": "b060e0", "rx": 0.12, "ry": 0.16}, "brows": {"len": 0.22, "th": 0.04, "tilt": 6},
                 "mouth": {"style": "smile", "w": 0.34, "y": -0.3}, "extras": [("blush",), ("sparkle", "ffffff")]},
}


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    os.makedirs(OUT, exist_ok=True)
    for cid in argv or list(FACES):
        draw(FACES[cid]).save(os.path.join(OUT, cid + ".png"))
        print("FACE", cid)
