# environment-redesign/kit/hl_classic.py - the CLASSIC ROBLOX build style (crnuch's Ocean Shore v2 brief, 2026-10-19):
# "classic Roblox studs, NOT LEGO" - cohesive meshes with smooth Roblox-Part shapes (blocks, cylinders, balls, wedges,
# rings), big organic terrain slabs and chunky faceted rocks, and studs only on broad terrain / structural tops
# (K.studs_done(only=...)). The voxel K.Mesh (stepped bricks) stays for the islands built with it until crnuch approves
# Ocean Shore v2 as the benchmark.
#   import hl_classic as CL;  m = CL.ClassicMesh("Name", collection)   (a drop-in K.Mesh: K.Frame works on it)
#   m.slab(pts, z0, z1, look, chamfer=0.5, top=None)   an organic polygon slab: one cohesive piece, chamfered top edge
#   m.rock(cx, cy, z0, sx, sy, h, look, top=None)      a chunky faceted boulder (jittered corners), flat-ish studdable top
import math
import random
import bmesh
import hl_kit as K
from hl_kit import rad, TAU, add_studs, grid_in_polygon

rng = random.Random(1907)


class ClassicMesh(K.Mesh):
    """K.Mesh with SMOOTH Roblox-style primitives (the pre-voxel kit's, kept verbatim) + cohesive terrain pieces."""

    def prism(self, pts, z0, z1, look, studs=False, stud_rot=0.0, **_):
        """Vertical prism over a CCW polygon [(x, y)]; studs=True fills its top with the 1-stud grid (inside test)."""
        mi = self._mi(look)
        bot = [self.bm.verts.new((x, y, z0)) for x, y in pts]
        top = [self.bm.verts.new((x, y, z1)) for x, y in pts]
        self._face(top, mi)
        self._face(list(reversed(bot)), mi)
        n = len(pts)
        for i in range(n):
            j = (i + 1) % n
            self._face((bot[i], bot[j], top[j], top[i]), mi)
        if studs:
            add_studs(look, grid_in_polygon(pts, z1), self.name)

    def cyl(self, cx, cy, r, z0, z1, look, segs=24, bevel=0.0, studs=False, **_):
        mi = self._mi(look)
        ring = lambda rr, z: [self.bm.verts.new((cx + rr * math.cos(TAU * i / segs), cy + rr * math.sin(TAU * i / segs), z)) for i in range(segs)]
        b = min(bevel, r / 3, (z1 - z0) / 3)
        bot = ring(r, z0)
        mid = ring(r, z1 - b) if b > 0 else None
        top = ring(r - b, z1) if b > 0 else ring(r, z1)
        self._face(list(reversed(bot)), mi)
        self._face(top, mi)
        rows = [bot] + ([mid] if mid else []) + [top]
        for a, bb in zip(rows, rows[1:]):
            for i in range(segs):
                j = (i + 1) % segs
                self._face((a[i], a[j], bb[j], bb[i]), mi)
        if studs:
            pts = [(cx + (r - 0.5) * math.cos(TAU * i / segs), cy + (r - 0.5) * math.sin(TAU * i / segs)) for i in range(segs)]
            add_studs(look, grid_in_polygon(pts, z1), self.name)

    def ring(self, r0, r1, z0, z1, look, segs=96, a0=0.0, a1=360.0, cx=0.0, cy=0.0, studs=False, **_):
        mi = self._mi(look)
        full = abs(a1 - a0) >= 359.99
        n = segs if full else max(2, int(segs * abs(a1 - a0) / 360) + 1)

        def pt(r, k):
            a = rad(a0 + (a1 - a0) * k / (n if full else n - 1))
            return (cx + r * math.cos(a), cy + r * math.sin(a))

        loops = [[self.bm.verts.new((*pt(r, k), z)) for k in range(n)] for r, z in ((r0, z0), (r1, z0), (r1, z1), (r0, z1))]
        ks = range(n) if full else range(n - 1)
        for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):
            for k in ks:
                j = (k + 1) % n
                self._face((loops[a][k], loops[a][j], loops[b][j], loops[b][k]), mi)
        if not full:
            for k in (0, n - 1):
                self._face((loops[0][k], loops[1][k], loops[2][k], loops[3][k]), mi)
        if studs:
            pts = []
            for r in range(int(r0) + 1, int(r1)):
                cnt = max(1, int(TAU * (r + 0.5) * abs(a1 - a0) / 360))
                for k in range(cnt):
                    a = rad(a0 + (a1 - a0) * (k + 0.5) / cnt)
                    pts.append((cx + (r + 0.5) * math.cos(a), cy + (r + 0.5) * math.sin(a), z1, a))
            add_studs(look, pts, self.name)

    def wedge(self, cx, cy, z0, sx, sy, h, look, rot=0.0, ridge="x"):
        """A gable: ridge along local x (default) at the top middle."""
        mi = self._mi(look)
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        P = lambda x, y, z: self.bm.verts.new((cx + x * c - y * s, cy + x * s + y * c, z))
        hx, hy = sx / 2, sy / 2
        if ridge == "x":
            a, b_, cc, d = P(-hx, -hy, z0), P(hx, -hy, z0), P(hx, hy, z0), P(-hx, hy, z0)
            e, f = P(-hx, 0, z0 + h), P(hx, 0, z0 + h)
            for q in ((a, b_, f, e), (cc, d, e, f), (d, cc, b_, a)):
                self._face(q, mi)
            self._face((a, e, d), mi)
            self._face((b_, cc, f), mi)
        else:
            a, b_, cc, d = P(-hx, -hy, z0), P(hx, -hy, z0), P(hx, hy, z0), P(-hx, hy, z0)
            e, f = P(0, -hy, z0 + h), P(0, hy, z0 + h)
            for q in ((b_, cc, f, e), (d, a, e, f), (d, cc, b_, a)):
                self._face(q, mi)
            self._face((a, b_, e), mi)
            self._face((cc, d, f), mi)

    def pyramid(self, cx, cy, z0, sx, sy, h, look, rot=0.0, top=0.0):
        """Hip roof / pyramid; top > 0 leaves a flat top that wide."""
        mi = self._mi(look)
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        P = lambda x, y, z: self.bm.verts.new((cx + x * c - y * s, cy + x * s + y * c, z))
        hx, hy = sx / 2, sy / 2
        base = [P(-hx, -hy, z0), P(hx, -hy, z0), P(hx, hy, z0), P(-hx, hy, z0)]
        if top > 0:
            t = top / 2
            tp = [P(-t * hx / max(hx, hy), -t * hy / max(hx, hy), z0 + h), P(t * hx / max(hx, hy), -t * hy / max(hx, hy), z0 + h),
                  P(t * hx / max(hx, hy), t * hy / max(hx, hy), z0 + h), P(-t * hx / max(hx, hy), t * hy / max(hx, hy), z0 + h)]
            for i in range(4):
                j = (i + 1) % 4
                self._face((base[i], base[j], tp[j], tp[i]), mi)
            self._face(tp, mi)
        else:
            apex = P(0, 0, z0 + h)
            for i in range(4):
                self._face((base[i], base[(i + 1) % 4], apex), mi)
        self._face(list(reversed(base)), mi)

    def cone(self, cx, cy, r, z0, z1, look, segs=8, r1=0.0, **_):
        mi = self._mi(look)
        base = [self.bm.verts.new((cx + r * math.cos(TAU * i / segs), cy + r * math.sin(TAU * i / segs), z0)) for i in range(segs)]
        if r1 > 0:
            top = [self.bm.verts.new((cx + r1 * math.cos(TAU * i / segs), cy + r1 * math.sin(TAU * i / segs), z1)) for i in range(segs)]
            for i in range(segs):
                j = (i + 1) % segs
                self._face((base[i], base[j], top[j], top[i]), mi)
            self._face(top, mi)
        else:
            tip = self.bm.verts.new((cx, cy, z1))
            for i in range(segs):
                self._face((base[i], base[(i + 1) % segs], tip), mi)
        self._face(list(reversed(base)), mi)

    def sphere(self, cx, cy, cz, rx, ry, rz, look, seg=16, rings=10, **_):
        mi = self._mi(look)
        rows = []
        for k in range(1, rings):
            t = math.pi * k / rings
            rows.append([self.bm.verts.new((cx + rx * math.sin(t) * math.cos(TAU * i / seg), cy + ry * math.sin(t) * math.sin(TAU * i / seg), cz + rz * math.cos(t))) for i in range(seg)])
        top, bot = self.bm.verts.new((cx, cy, cz + rz)), self.bm.verts.new((cx, cy, cz - rz))
        for i in range(seg):
            j = (i + 1) % seg
            self._face((top, rows[0][i], rows[0][j]), mi)
            self._face((bot, rows[-1][j], rows[-1][i]), mi)
        for a, b in zip(rows, rows[1:]):
            for i in range(seg):
                j = (i + 1) % seg
                self._face((a[i], b[i], b[j], a[j]), mi)

    def ring_v(self, cx, cy, cz, r0, r1, depth, looks, rot=0.0, segs=24, gap=0.12, a0=0.0, a1=360.0):
        """An UPRIGHT ring (arch / portal / gear rim) in the local x-z plane, `depth` thick along local y, built from
        `segs` separate chunky blocks (gap between them) - looks is one look or a list cycled per block."""
        looks = looks if isinstance(looks, (list, tuple)) else [looks]
        c, s_ = math.cos(rad(rot)), math.sin(rad(rot))
        span = (a1 - a0) / segs
        for k in range(segs):
            mi = self._mi(looks[k % len(looks)])
            g = math.degrees(gap / max(r1, 0.1))
            aa, ab = rad(a0 + k * span + g / 2), rad(a0 + (k + 1) * span - g / 2)
            vs = []
            for yy in (-depth / 2, depth / 2):
                for (r, a) in ((r0, aa), (r1, aa), (r1, ab), (r0, ab)):
                    lx, lz = r * math.cos(a), r * math.sin(a)
                    vs.append(self.bm.verts.new((cx + lx * c - yy * s_, cy + lx * s_ + yy * c, cz + lz)))
            f, b = vs[:4], vs[4:]
            for q in (f, list(reversed(b)), (f[0], f[1], b[1], b[0]), (f[1], f[2], b[2], b[1]), (f[2], f[3], b[3], b[2]), (f[3], f[0], b[0], b[3])):
                self._face(q, mi)

    def disc_v(self, cx, cy, cz, r, depth, look, rot=0.0, segs=32, **_):
        """An UPRIGHT disc in the local x-z plane (a portal field, a clock face, a round window)."""
        mi = self._mi(look)
        c, s_ = math.cos(rad(rot)), math.sin(rad(rot))
        loops = []
        for yy in (-depth / 2, depth / 2):
            loops.append([self.bm.verts.new((cx + r * math.cos(TAU * i / segs) * c - yy * s_, cy + r * math.cos(TAU * i / segs) * s_ + yy * c,
                                              cz + r * math.sin(TAU * i / segs))) for i in range(segs)])
        self._face(loops[0], mi)
        self._face(list(reversed(loops[1])), mi)
        for i in range(segs):
            j = (i + 1) % segs
            self._face((loops[0][i], loops[0][j], loops[1][j], loops[1][i]), mi)


    # -- cohesive terrain
    def slab(self, pts, z0, z1, look, chamfer=0.5, top=None):
        """One cohesive polygon slab (sand plateau, terrace, rock shelf): vertical sides, a chamfered top edge, the top
        face in `top` (defaults to look). pts = CCW polygon."""
        mi, mt = self._mi(look), self._mi(top or look)
        n = len(pts)
        cx = sum(p[0] for p in pts) / n
        cy = sum(p[1] for p in pts) / n

        def inset(p, d):
            x, y = p
            dx, dy = cx - x, cy - y
            L = math.hypot(dx, dy) or 1.0
            return (x + dx / L * d, y + dy / L * d)

        c = min(chamfer, (z1 - z0) / 2)
        bot = [self.bm.verts.new((x, y, z0)) for x, y in pts]
        mid = [self.bm.verts.new((x, y, z1 - c)) for x, y in pts]
        tp = [self.bm.verts.new((*inset(p, c), z1)) for p in pts]
        self._face(list(reversed(bot)), mi)
        f = self._face(tp, mt)
        for i in range(n):
            j = (i + 1) % n
            self._face((bot[i], bot[j], mid[j], mid[i]), mi)
            self._face((mid[i], mid[j], tp[j], tp[i]), mt)
        return f

    def rock(self, cx, cy, z0, sx, sy, h, look, top=None, rot=0.0, jitter=0.18, taper=0.12):
        """A chunky faceted boulder / cliff block: a box whose corners are jittered (and the top slightly tapered), so
        stacks of them read as natural stylized rock, not bricks. Its top stays level (studs sit on it)."""
        mi, mt = self._mi(look), self._mi(top or look)
        c, s = math.cos(rad(rot)), math.sin(rad(rot))
        hx, hy = sx / 2, sy / 2

        def P(x, y, z):
            return self.bm.verts.new((cx + x * c - y * s, cy + x * s + y * c, z))

        j = lambda v: v * (1 + rng.uniform(-jitter, jitter))
        b = [P(j(-hx), j(-hy), z0), P(j(hx), j(-hy), z0), P(j(hx), j(hy), z0), P(j(-hx), j(hy), z0)]
        tt = 1 - taper
        zt = z0 + h
        t = [P(j(-hx) * tt, j(-hy) * tt, zt), P(j(hx) * tt, j(-hy) * tt, zt), P(j(hx) * tt, j(hy) * tt, zt), P(j(-hx) * tt, j(hy) * tt, zt)]
        self._face(list(reversed(b)), mi)
        self._face(t, mt)
        for i in range(4):
            k = (i + 1) % 4
            self._face((b[i], b[k], t[k], t[i]), mi)

    def beam(self, p0, p1, w, h, look, roll=0.0):
        """A box from point p0 to p1 (3D), w wide and h tall across it: tilted masts, ribs, driftwood, roots."""
        mi = self._mi(look)
        x0, y0, z0 = p0
        x1, y1, z1 = p1
        dx, dy, dz = x1 - x0, y1 - y0, z1 - z0
        L = math.sqrt(dx * dx + dy * dy + dz * dz) or 1e-6
        ax = (dx / L, dy / L, dz / L)
        up = (0.0, 0.0, 1.0) if abs(ax[2]) < 0.95 else (1.0, 0.0, 0.0)
        sd = (ax[1] * up[2] - ax[2] * up[1], ax[2] * up[0] - ax[0] * up[2], ax[0] * up[1] - ax[1] * up[0])
        sl = math.sqrt(sum(v * v for v in sd)) or 1.0
        sd = tuple(v / sl for v in sd)
        tp = (ax[1] * sd[2] - ax[2] * sd[1], ax[2] * sd[0] - ax[0] * sd[2], ax[0] * sd[1] - ax[1] * sd[0])
        cr, sr = math.cos(rad(roll)), math.sin(rad(roll))
        sd, tp = tuple(cr * sd[i] + sr * tp[i] for i in range(3)), tuple(-sr * sd[i] + cr * tp[i] for i in range(3))
        vs = []
        for t, (px, py, pz) in ((0, p0), (1, p1)):
            for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                vs.append(self.bm.verts.new((px + sd[0] * a * w / 2 + tp[0] * b * h / 2, py + sd[1] * a * w / 2 + tp[1] * b * h / 2,
                                             pz + sd[2] * a * w / 2 + tp[2] * b * h / 2)))
        f, b_ = vs[:4], vs[4:]
        for q in (list(reversed(f)), b_, (f[0], f[1], b_[1], b_[0]), (f[1], f[2], b_[2], b_[1]), (f[2], f[3], b_[3], b_[2]), (f[3], f[0], b_[0], b_[3])):
            self._face(q, mi)

    def frond(self, base, yaw, length, width, droop, look, lift=0.35, segs=6, tip=None):
        """A palm frond / leaf: a tapering strip from `base` out along yaw (degrees), rising then drooping, with a
        slight fold down the middle (natural detail: never studded)."""
        mi, mt = self._mi(look), self._mi(tip or look)
        cy, sy = math.cos(rad(yaw)), math.sin(rad(yaw))
        rows = []
        for k in range(segs + 1):
            t = k / segs
            d = length * t
            z = base[2] + length * lift * t - droop * t * t * length
            hw = width / 2 * math.sin(math.pi * min(1.0, 0.15 + t * 0.95)) if t < 1 else 0.02
            cx, cy_ = base[0] + cy * d, base[1] + sy * d
            px, py = -sy, cy
            rows.append((self.bm.verts.new((cx - px * hw, cy_ - py * hw, z - hw * 0.25)), self.bm.verts.new((cx, cy_, z)),
                         self.bm.verts.new((cx + px * hw, cy_ + py * hw, z - hw * 0.25))))
        for k in range(segs):
            m = mt if k >= segs - 2 else mi
            a, b = rows[k], rows[k + 1]
            self._face((a[0], b[0], b[1], a[1]), m)
            self._face((a[1], b[1], b[2], a[2]), m)
            self._face((a[1], a[0], b[0], b[1]), m)  # (two-sided: the underside)
            self._face((a[2], a[1], b[1], b[2]), m)
