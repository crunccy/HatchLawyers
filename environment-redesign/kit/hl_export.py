# environment-redesign/kit/hl_export.py - records everything an island build draws as Roblox PARTS (2026-10-19,
# mr.robe's session: "just build them" = put the islands into the game). Import it BEFORE the build runs (see
# export_island.py): it wraps the kit's primitives so every brick / cylinder / ring / prism / wedge / text also lands
# in RECORDS, in Roblox space ((x, y, z) = (bx, bz, -by)), and tools/zones/BuildRedesignIsland.lua makes the Parts.
# The Blender geometry is built as before (the build scripts read objects back), only nothing is saved.
#   box     ["b", group, look, px, py, pz, sx, sy, sz, ry]          a brick turned ry degrees about Y
#   box     ["B", group, look, px, py, pz, sx, sy, sz, r00..r22]    any other turn (upright rings, statues)
#   (since 2026-10-19 the kit is voxel: an island exports as "b" boxes + "B" statue blocks + "t" text only)
#   cyl     ["c", group, look, px, py, pz, h, d]                    an upright cylinder (Roblox Cylinder, axis turned up)
#   cyl     ["C", group, look, px, py, pz, len, d, r00..r22]        a cylinder along the matrix's X (upright discs)
#   wedge   ["w", group, look, px, py, pz, sx, sy, sz, hx, hz]      a WedgePart: sx along the ridge, sz across, its high
#                                                                    side toward (hx, 0, hz)
#   ball    ["s", group, look, px, py, pz, d]
#   text    ["t", group, look, px, py, pz, size, nx, nz, "TEXT"]    standing text facing (nx, 0, nz)
# Studs are not exported: the place lays raised studs on StudTop-tagged parts (StarterPlayerScripts.Studs).
import math
import hl_kit as K
import hl_island as HI

RECORDS = []
GROUPS = []
LOOKS = {}
SKIP_MESHES = {"Label_Plates"}
_gi = {}


def _g(name):
    if name not in _gi:
        _gi[name] = len(GROUPS)
        GROUPS.append(name)
    return _gi[name]


def _look(name):
    if name not in LOOKS:
        if name in K.GLOWS:
            LOOKS[name] = [*K.GLOWS[name][0], "neon"]
        elif name in K.GLASS:
            kind = "field" if name.startswith("portal_") else ("beam" if name.startswith("beam") else
                   ("glass" if name.startswith("glass") else "water"))
            LOOKS[name] = [*K.GLASS[name], kind]
        else:
            LOOKS[name] = [*K.PAL.get(name, (200, 200, 200)), "metal" if name.startswith("metal") else "plastic"]
    return name


def R(v):
    return round(v, 3)


def to_rbx(v):
    return (v[0], v[2], -v[1])


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _matrix(xb, yb):
    """Row-major Roblox rotation from two Blender-space unit axes (the third = X x Y, right-handed)."""
    zb = _cross(xb, yb)
    X, Y, Z = to_rbx(xb), to_rbx(yb), to_rbx(zb)
    return [R(X[0]), R(Y[0]), R(Z[0]), R(X[1]), R(Y[1]), R(Z[1]), R(X[2]), R(Y[2]), R(Z[2])]


def _on(self):
    return self.name not in SKIP_MESHES and not self.name.startswith("Sky_")  # (Sky_* = far Blender-only backdrops)


def _box(self, cx, cy, zc, sx, sy, h, look, rot):
    RECORDS.append(["b", _g(self.name), _look(look), R(cx), R(zc), R(-cy), R(sx), R(h), R(sy), R(rot % 360)])


def _cylv(self, cx, cy, r, z0, z1, look):
    if z1 < z0:
        z0, z1 = z1, z0
    if z1 - z0 < 0.01 or r < 0.02:
        return
    RECORDS.append(["c", _g(self.name), _look(look), R(cx), R((z0 + z1) / 2), R(-cy), R(z1 - z0), R(2 * r)])


_orig = {n: getattr(K.Mesh, n) for n in ("brick", "prism", "cyl", "ring", "wedge", "pyramid", "cone", "sphere", "ring_v", "disc_v")}


def brick(self, cx, cy, z0, sx, sy, h, look, rot=0.0, studs=True, bevel=0.08, stud_look=None):
    if _on(self) and sx > 0.01 and sy > 0.01 and h > 0.01:
        _box(self, cx, cy, z0 + h / 2, sx, sy, h, look, rot)
    return _orig["brick"](self, cx, cy, z0, sx, sy, h, look, rot, studs, bevel, stud_look)


def prism(self, pts, z0, z1, look, studs=False, stud_rot=0.0):
    """A vertical prism becomes rows of boxes (even-odd fill): a stepped, brick-like edge."""
    if _on(self) and z1 - z0 > 0.01:
        ys = [p[1] for p in pts]
        y0, y1 = min(ys), max(ys)
        span = y1 - y0
        if span > 0.05:
            bw = max(0.5, min(2.0, span / 60.0))
            n = max(1, int(math.ceil(span / bw)))
            bw = span / n
            m = len(pts)
            for i in range(n):
                yc = y0 + (i + 0.5) * bw
                xi = []
                for k in range(m):
                    (xa, ya), (xb, yb) = pts[k], pts[(k + 1) % m]
                    if (ya <= yc < yb) or (yb <= yc < ya):
                        xi.append(xa + (yc - ya) * (xb - xa) / (yb - ya))
                xi.sort()
                for a, b in zip(xi[0::2], xi[1::2]):
                    if b - a > 0.05:
                        _box(self, (a + b) / 2, yc, (z0 + z1) / 2, b - a, bw + 0.02, z1 - z0, look, 0.0)
    return _orig["prism"](self, pts, z0, z1, look, studs, stud_rot)


def cyl(self, cx, cy, r, z0, z1, look, segs=24, bevel=0.0, studs=False):
    if _on(self):
        _cylv(self, cx, cy, r, z0, z1, look)
    return _orig["cyl"](self, cx, cy, r, z0, z1, look, segs, bevel, studs)


def ring(self, r0, r1, z0, z1, look, segs=96, a0=0.0, a1=360.0, cx=0.0, cy=0.0, studs=False):
    if _on(self) and r1 > r0 and z1 - z0 > 0.01:
        frac = abs(a1 - a0) / 360.0
        n = max(3, min(int(segs * frac), int(2 * math.pi * r1 * frac / 2.0) + 3, 64))
        span = math.radians(a1 - a0) / n
        for k in range(n):
            a = math.radians(a0) + (k + 0.5) * span
            rm = (r0 + r1) / 2
            chord = 2 * r1 * math.sin(abs(span) / 2) + 0.05
            _box(self, cx + rm * math.cos(a), cy + rm * math.sin(a), (z0 + z1) / 2, chord, r1 - r0, z1 - z0, look,
                 math.degrees(a) + 90)
    return _orig["ring"](self, r0, r1, z0, z1, look, segs, a0, a1, cx, cy, studs)


def wedge(self, cx, cy, z0, sx, sy, h, look, rot=0.0, ridge="x"):
    if _on(self) and h > 0.01:
        c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        for sgn in (-1, 1):
            if ridge == "x":  # ridge along local x: two halves across local y, high side toward y = 0
                lx, ly, w, d = 0.0, sgn * sy / 4, sx, sy / 2
                hb = (s * sgn, -c * sgn)  # toward the ridge = local -sgn*y
            else:  # ridge along local y: halves across local x, high side toward x = 0
                lx, ly, w, d = sgn * sx / 4, 0.0, sy, sx / 2
                hb = (-c * sgn, -s * sgn)
            wx, wy = cx + lx * c - ly * s, cy + lx * s + ly * c
            RECORDS.append(["w", _g(self.name), _look(look), R(wx), R(z0 + h / 2), R(-wy), R(w), R(h), R(d), R(hb[0]), R(-hb[1])])
    return _orig["wedge"](self, cx, cy, z0, sx, sy, h, look, rot, ridge)


def pyramid(self, cx, cy, z0, sx, sy, h, look, rot=0.0, top=0.0):
    if _on(self) and h > 0.01:
        tiers = 3
        for k in range(tiers):
            f = 1 - k / tiers * (1 - (top / max(sx, sy) if top > 0 else 0.15))
            _box(self, cx, cy, z0 + (k + 0.5) * h / tiers, sx * f, sy * f, h / tiers, look, rot)
    return _orig["pyramid"](self, cx, cy, z0, sx, sy, h, look, rot, top)


def cone(self, cx, cy, r, z0, z1, look, segs=8, r1=0.0):
    if _on(self):
        n = max(2, min(5, int(abs(z1 - z0) / 2.5)))
        for k in range(n):
            t = (k + 0.5) / n
            za, zb = z0 + (z1 - z0) * k / n, z0 + (z1 - z0) * (k + 1) / n
            _cylv(self, cx, cy, r + (r1 - r) * t, za, zb, look)
    return _orig["cone"](self, cx, cy, r, z0, z1, look, segs, r1)


def sphere(self, cx, cy, cz, rx, ry, rz, look, seg=16, rings=10):
    if _on(self):
        RECORDS.append(["s", _g(self.name), _look(look), R(cx), R(cz), R(-cy), R(2 * (rx + ry + rz) / 3)])
    return _orig["sphere"](self, cx, cy, cz, rx, ry, rz, look, seg, rings)


def ring_v(self, cx, cy, cz, r0, r1, depth, looks, rot=0.0, segs=24, gap=0.12, a0=0.0, a1=360.0):
    if _on(self) and r1 > r0:
        lk = looks if isinstance(looks, (list, tuple)) else [looks]
        c, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        X, Y, U = (c, s_, 0.0), (-s_, c, 0.0), (0.0, 0.0, 1.0)
        span = (a1 - a0) / segs
        for k in range(segs):
            a = math.radians(a0 + (k + 0.5) * span)
            g = gap / max(r1, 0.1)
            chord = max(0.05, 2 * r1 * math.sin(math.radians(abs(span)) / 2) - gap)
            rm = (r0 + r1) / 2
            T = tuple(-math.sin(a) * X[i] + math.cos(a) * U[i] for i in range(3))
            N = tuple(math.cos(a) * X[i] + math.sin(a) * U[i] for i in range(3))
            p = (cx + rm * math.cos(a) * X[0], cy + rm * math.cos(a) * X[1], cz + rm * math.sin(a))
            RECORDS.append(["B", _g(self.name), _look(lk[k % len(lk)]), R(p[0]), R(p[2]), R(-p[1]), R(chord), R(r1 - r0), R(depth), *_matrix(T, N)])
            _ = g
    return _orig["ring_v"](self, cx, cy, cz, r0, r1, depth, looks, rot, segs, gap, a0, a1)


def disc_v(self, cx, cy, cz, r, depth, look, rot=0.0, segs=32):
    if _on(self):
        c, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        D, U = (-s_, c, 0.0), (0.0, 0.0, 1.0)
        RECORDS.append(["C", _g(self.name), _look(look), R(cx), R(cz), R(-cy), R(depth), R(2 * r), *_matrix(D, U)])
    return _orig["disc_v"](self, cx, cy, cz, r, depth, look, rot, segs)


# Since the kit went VOXEL (crnuch's call 2026-10-19, "studded voxel on everything"), every primitive (prism, cyl, ring,
# wedge, pyramid, cone, sphere, ring_v, disc_v) builds itself out of Mesh.brick calls - so recording BRICKS alone gives the
# whole island, stepped exactly as in Blender, with no smooth Cylinder / Ball / WedgePart parts. (The older per-primitive
# recorders above are kept for reference but no longer installed: they would record every round piece twice.)
K.Mesh.brick = brick

_orig_label = K.label3d


def label3d(text, x, y, z, size, look="white", rot=0.0, collection=None, extrude=0.15, font=None, face_rot=(90, 0)):
    a = math.radians(rot + face_rot[1])
    n = (math.sin(a), -math.cos(a))  # the text faces local -y
    RECORDS.append(["t", _g("Signs"), _look(look), R(x), R(z), R(-y), R(size), R(n[0]), R(-n[1]), text])
    return _orig_label(text, x, y, z, size, look, rot, collection, extrude, font, face_rot)


K.label3d = label3d

_orig_mfp = HI.model_from_parts


def model_from_parts(col, name, parts, x, y, z=0.0, scale=1.0, facing=0.0):
    """Statues: the model's own Roblox-space blocks, scaled + turned. Bosses (Boss_*) are skipped: BossService draws them."""
    if not name.startswith("Boss_"):
        g = _g(name)
        c, s = math.cos(math.radians(facing)), math.sin(math.radians(facing))
        ry = [[c, 0, s], [0, 1, 0], [-s, 0, c]]  # Roblox CFrame.Angles(0, facing, 0)
        for p in parts:
            px, py, pz = (v * scale for v in p["p"])
            q = (ry[0][0] * px + ry[0][2] * pz, py, ry[2][0] * px + ry[2][2] * pz)
            Rm = p["r"]
            Rp = [[sum(ry[i][k] * Rm[k * 3 + j] for k in range(3)) for j in range(3)] for i in range(3)]
            rgb = tuple(p["c"])
            lk = "model_%d_%d_%d" % rgb + ("_neon" if p.get("t") == "neon" else "")
            LOOKS.setdefault(lk, [*rgb, "neon" if p.get("t") == "neon" else "plastic"])
            RECORDS.append(["B", g, lk, R(x + q[0]), R(z + q[1]), R(-y + q[2]), R(p["s"][0] * scale), R(p["s"][1] * scale),
                            R(p["s"][2] * scale), *[R(Rp[i][j]) for i in range(3) for j in range(3)]])
    return _orig_mfp(col, name, parts, x, y, z, scale, facing)


HI.model_from_parts = model_from_parts
