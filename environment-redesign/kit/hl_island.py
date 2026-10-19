# environment-redesign/kit/hl_island.py - the shared FLOATING ISLAND machinery (2026-10-18), used by every egg island.
# (The central hub's hub_build.py has its own copy of these ideas; new islands use this module.)
#   I = Island("Briefcase_Bay", rx=150, ry=190, seed=7)        an irregular oval, 1 stud = 1 m, +Y = north
#   I.cover_circle / cover_rect / cover_fn                       what stands on the ground (no grass studs, no planting)
#   I.build_top(col) / I.build_cliffs(col) / I.waterfall(m, a)   terrain
#   I.groves(m, n, kinds) / I.hills(m, n) / I.clouds(m, n)       landscaping + sky
#   I.grass_studs()                                              the studded grass top (call last, before K.studs_done)
#   boss(col, "SeniorPartner", x, y, scale, facing)              a zone boss from tools/zones/bosses.json (for scale)
#   label(col, text, x, y, size)                                 plan labels
import bpy, bmesh, json, math, os, random
import hl_kit as K

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def polar(r, deg):
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


def angdiff(a, b):
    return (a - b + 180) % 360 - 180


class Island:
    BUCKET = 16

    def __init__(self, name, rx, ry, seed=1, wobble=(9, 6, 3), z_top=0.0):
        self.name, self.rx, self.ry, self.wobble = name, rx, ry, wobble
        self.rng = random.Random(seed)
        self.foot = {}
        self.cover_fns = []
        self.N = 220
        self.tiers = None

    # -- shape
    def r(self, deg):
        a = math.radians(deg)
        base = 1.0 / math.sqrt((math.cos(a) / self.rx) ** 2 + (math.sin(a) / self.ry) ** 2)
        w1, w2, w3 = self.wobble
        return base + w1 * math.sin(3 * a + 1.3) + w2 * math.sin(7 * a + 0.4) + w3 * math.sin(13 * a + 2.0)

    def top_pts(self, f=1.0):
        return [polar(self.r(360 * i / self.N) * f, 360 * i / self.N) for i in range(self.N)]

    def inside(self, x, y, margin=0.0):
        a = math.degrees(math.atan2(y, x))
        return math.hypot(x, y) < self.r(a) - margin

    # -- coverage (spatial hash of circles + arbitrary tests)
    def cover_circle(self, x, y, r, ground=True):
        B = self.BUCKET
        for bx in range(int((x - r - 8) // B), int((x + r + 8) // B) + 1):
            for by in range(int((y - r - 8) // B), int((y + r + 8) // B) + 1):
                self.foot.setdefault((bx, by), []).append((x, y, r, ground))

    def cover_rect(self, cx, cy, sx, sy, rot=0.0, pad=0.0):
        c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))

        def fn(x, y, p):
            dx, dy = x - cx, y - cy
            lx, ly = dx * c + dy * s, -dx * s + dy * c
            return abs(lx) < sx / 2 + p + pad and abs(ly) < sy / 2 + p + pad
        self.cover_fns.append(fn)

    def cover_fn(self, fn):
        self.cover_fns.append(fn)

    def covered(self, x, y, pad=0.0, ground_only=False):
        for fn in self.cover_fns:
            if fn(x, y, pad):
                return True
        for fx, fy, fr, g in self.foot.get((int(x // self.BUCKET), int(y // self.BUCKET)), ()):
            if ground_only and not g:
                continue
            if (x - fx) ** 2 + (y - fy) ** 2 < (fr + pad) ** 2:
                return True
        return False

    # -- terrain
    def build_top(self, col, look="grass"):
        m = K.Mesh(self.name + "_Top", col)
        m.prism(self.top_pts(), -2.0, 0.0, look)
        self.top_look = look
        return m.done()

    def face_r(self, a, f, k):
        return self.r(a) * f * (1 + 0.03 * math.sin(math.radians(5 * a) + k) + 0.02 * math.sin(math.radians(11 * a) + 2 * k))

    def build_cliffs(self, col, tiers=None, earth=("dirt", "dirt_dark", "dirt"), lip=("grass_dark", "grass"), vines="leaf"):
        rng = self.rng
        self.tiers = tiers or ((0.97, -28, -9, ("rock_warm", "dirt", "rock_warm", "dirt_dark", "stone_dark")),
                               (0.87, -52, -28, ("rock", "rock_dark", "rock_warm", "stone_dark")),
                               (0.72, -76, -52, ("rock_dark", "rock", "stone_dark", "rock_warm")),
                               (0.55, -98, -76, ("rock", "rock_warm", "rock_dark")),
                               (0.35, -118, -98, ("rock_dark", "rock")), (0.16, -134, -118, ("rock", "rock_dark")))
        cl = K.Mesh(self.name + "_Cliffs", col)
        cl.prism([(x * 0.998, y * 0.998) for x, y in self.top_pts()], -9, -2, earth[0])

        def strata(z0, z1, f, k, looks, depth=(0.6, 3.4)):
            z, row = z1, 0
            while z > z0 + 0.5:
                h = min(z - z0, rng.uniform(3.5, 8.5))
                a = rng.uniform(0, 4)
                while a < 360:
                    r = self.face_r(a, f, k)
                    w = rng.uniform(3.5, 9)
                    x, y = polar(r + rng.uniform(*depth) - 2.2, a)
                    hh = h * rng.uniform(0.75, 1.0)
                    look = looks[(row + int(a / 9)) % len(looks)] if rng.random() < 0.75 else rng.choice(looks)
                    cl.brick(x, y, z - hh, 4.4, w, hh, look, rot=a, studs=True)
                    a += math.degrees(w * rng.uniform(0.8, 1.0) / r)
                z -= h
                row += 1

        strata(-9, -2, 0.998, 0, earth, depth=(0.2, 1.2))
        for k, (f, z0, z1, looks) in enumerate(self.tiers):
            pts = []
            for i in range(self.N):
                a = 360 * i / self.N
                r = self.face_r(a, f, k)
                pts.append(polar(round(r / 2) * 2, a))
            cl.prism(pts, z0, z1, looks[0])
            strata(z0, z1, f, k, looks)
            if k + 1 < len(self.tiers):
                nf = self.tiers[k + 1][0]
                a = 0.0
                while a < 360:
                    r = self.face_r(a, nf, k + 1)
                    w = rng.uniform(4, 8)
                    x, y = polar(r + 1.0, a)
                    if rng.random() < 0.55:
                        cl.brick(x, y, z0 - 0.2, 3.2, w, 1.2, rng.choice(list(lip) + [vines]), rot=a)
                        if rng.random() < 0.35:
                            vx, vy = polar(r + 2.4, a)
                            cl.brick(vx, vy, z0 - rng.uniform(4, 10), 0.8, 0.8, rng.uniform(4, 10), vines, rot=a, studs=False, bevel=0.1)
                    a += math.degrees(w / r)
            for i in range(int(40 * f)):
                a = rng.uniform(0, 360)
                x, y = polar(self.face_r(a, f, k) - rng.uniform(1, 8), a)
                hh = rng.uniform(3, 9)
                cl.brick(x, y, z0 - hh, rng.uniform(3, 6), rng.uniform(3, 6), hh + 0.5, rng.choice(looks), rot=a, studs=False)
        n = int(math.tau * max(self.rx, self.ry) / 4)
        for i in range(n):  # grass lip + vines
            a = i * 360 / n
            x, y = polar(self.r(a) + 0.6, a)
            cl.brick(x, y, -2.6, 2.4, 4.4, 2.6, lip[i % len(lip)], rot=a, studs=False)
            if rng.random() < 0.25:
                vx, vy = polar(self.r(a) + 1.4, a)
                cl.brick(vx, vy, -2.6 - rng.uniform(3, 12), 0.8, 0.8, rng.uniform(3, 12), vines, rot=a, studs=False, bevel=0.1)
        for i in range(int(0.3 * (self.rx + self.ry))):  # hanging rocks
            a = rng.uniform(0, 360)
            f = rng.uniform(0.15, 0.95)
            x, y = polar(self.r(a) * f, a)
            zt = -9 - (1 - f) * 125
            cl.cone(x, y, rng.uniform(4, 11), zt, zt - rng.uniform(10, 32), rng.choice(["rock", "rock_dark", "rock_warm"]), segs=6)
        return cl.done()

    def waterfall(self, m, a, pond_r=9.0, stream=26.0, look="water_fall", pond_look="water", bank="stone", pond=True):
        """A pond, a stream between banks to the edge, and a wide curtain falling clear of the cliff into mist."""
        rng = self.rng
        er = self.r(a)
        if pond:
            px, py = polar(er - stream - pond_r - 4, a)
            m.cyl(px, py, pond_r, -0.6, 0.15, pond_look, segs=28)
            m.ring(pond_r, pond_r + 1.6, -0.6, 0.9, bank, cx=px, cy=py, segs=28, studs=True)
            self.cover_circle(px, py, pond_r + 2)
        for k in range(int(stream / 2)):
            r = er - stream + k * 2
            sx, sy = polar(r, a)
            m.brick(sx, sy, -0.4, 2.2, 5, 0.5, pond_look, rot=a, studs=False, bevel=0.0)
            for sgn in (-1, 1):
                bx, by = sx - math.sin(math.radians(a)) * sgn * 3.4, sy + math.cos(math.radians(a)) * sgn * 3.4
                m.brick(bx, by, -0.4, 2.2, 1.6, 1.0 + rng.random() * 0.6, bank, rot=a)
            self.cover_circle(sx, sy, 4)
        lip = er + 0.8
        for k in range(4):
            fx, fy = polar(lip + k * 0.9, a)
            m.brick(fx, fy, -0.4 - k * 0.9, 1.2, 5.2, 0.9, look, rot=a, studs=False, bevel=0.2)
        fx, fy = polar(lip + 4.2, a)
        z, k = -3.0, 0
        while z > -130:
            h = rng.uniform(6, 12)
            w = 11.0 + min(5.0, k * 0.45) + rng.uniform(-1.2, 1.2)
            sway = rng.uniform(-0.8, 0.8)
            ox, oy = -math.sin(math.radians(a)) * sway, math.cos(math.radians(a)) * sway
            m.brick(fx + ox, fy + oy, z - h, 1.8, w, h, look, rot=a, studs=False, bevel=0.3)
            for e in (-1, 1):
                ex, ey = -math.sin(math.radians(a)) * e * (w / 2 - 0.4), math.cos(math.radians(a)) * e * (w / 2 - 0.4)
                m.brick(fx + ox + ex + math.cos(math.radians(a)) * 0.6, fy + oy + ey + math.sin(math.radians(a)) * 0.6, z - h, 0.8, 1.2, h,
                        "glow_white", rot=a, studs=False, bevel=0.2)
            z -= h * 0.92
            k += 1
        m.brick(fx, fy, -1.2, 3.0, 7.0, 1.2, "glow_white", rot=a, studs=False, bevel=0.5)
        for j in range(7):
            mx, my = polar(lip + rng.uniform(-4, 14), a + rng.uniform(-3, 3))
            w = rng.uniform(10, 22)
            m.brick(mx, my, -130 + rng.uniform(-6, 8), w, w * 0.8, rng.uniform(5, 10), "white", rot=a + rng.uniform(0, 40))

    # -- landscaping
    def groves(self, m, n, kinds=("round", "round", "pine", "blossom", "mixed"), margin=16, inner=0.0, spacing=30, sizes=(7, 12), area=None):
        rng = self.rng
        centres, tries = [], 0
        while len(centres) < n and tries < 6000:
            tries += 1
            a = rng.uniform(0, 360)
            r = rng.uniform(inner, self.r(a) - margin)
            x, y = polar(r, a)
            if area and not area(x, y):
                continue
            if not self.covered(x, y, 6) and all((x - gx) ** 2 + (y - gy) ** 2 > spacing ** 2 for gx, gy, _ in centres):
                centres.append((x, y, rng.choice(kinds)))
        for gx, gy, kind in centres:
            cnt = rng.randint(*sizes)
            spread = rng.uniform(8, 14)
            for i in range(cnt * 3):
                if cnt <= 0:
                    break
                x, y = gx + rng.gauss(0, spread), gy + rng.gauss(0, spread)
                if self.covered(x, y, 5) or not self.inside(x, y, 6):
                    continue
                s = rng.uniform(0.85, 1.25)
                pick = kind if kind not in ("mixed",) else rng.choice(["round", "pine", "blossom", "round"])
                {"round": K.tree_round, "pine": K.tree_pine, "blossom": K.tree_blossom, "palm": K.tree_palm}[pick](m, x, y, s)
                self.cover_circle(x, y, 4.5 * s, ground=False)
                cnt -= 1
            for j in range(3):
                a = rng.uniform(0, 360)
                x, y = gx + math.cos(math.radians(a)) * spread * 1.6, gy + math.sin(math.radians(a)) * spread * 1.6
                if not self.covered(x, y, 3) and self.inside(x, y, 6):
                    (K.bush if j < 2 else K.rocks)(m, x, y, rng.uniform(0.8, 1.1))
                    self.cover_circle(x, y, 3, ground=False)
        return centres

    def hills(self, m, n, rmin_f=0.55, area=None):
        rng = self.rng
        made = tries = 0
        while made < n and tries < 4000:
            tries += 1
            a = rng.uniform(0, 360)
            r = rng.uniform(self.r(a) * rmin_f, self.r(a) - 24)
            x, y = polar(r, a)
            R = rng.uniform(10, 16)
            if area and not area(x, y):
                continue
            if self.covered(x, y, R + 4):
                continue
            tiers = rng.randint(2, 3)
            for k in range(tiers):
                rr = R * (1 - k / (tiers + 0.6))
                pts = [(x + rr * (1 + 0.12 * math.sin(3 * t + k)) * math.cos(t), y + rr * (1 + 0.12 * math.sin(3 * t + k)) * math.sin(t))
                       for t in [math.tau * i / 18 for i in range(18)]]
                m.prism(pts, k * 1.6, (k + 1) * 1.6 - 0.25, "dirt" if k == 0 else "dirt_dark")
                m.prism([(x + (px - x) * 0.97, y + (py - y) * 0.97) for px, py in pts], (k + 1) * 1.6 - 0.25, (k + 1) * 1.6, self.top_look, studs=True)
            K.rocks(K.Frame(m, x, y, 0, z=tiers * 1.6), 0, 0, 1.2) if rng.random() < 0.5 else K.tree_round(K.Frame(m, x, y, 0, z=tiers * 1.6), 0, 0, 1.1)
            self.cover_circle(x, y, R + 2)
            made += 1

    def clouds(self, m, n=16, rmin=None, rmax=None, islets=8):
        K.STUD_GROUP = m.name  # (the ambience drifts this object: its studs ride on it)
        try:
            self._clouds(m, n, rmin, rmax, islets)
        finally:
            K.STUD_GROUP = None

    def _clouds(self, m, n, rmin, rmax, islets):
        rng = self.rng
        R = max(self.rx, self.ry)
        rmin, rmax = rmin or R + 60, rmax or R + 260
        for i in range(n):
            x, y = polar(rng.uniform(rmin, rmax), rng.uniform(0, 360))
            z = rng.uniform(-170, 30)
            for j in range(rng.randint(4, 8)):
                w = rng.uniform(10, 28)
                m.brick(x + rng.uniform(-24, 24), y + rng.uniform(-14, 14), z + rng.uniform(-3, 6), w, w * rng.uniform(0.6, 1.0), rng.uniform(5, 10), "white", rot=rng.uniform(0, 90))
        for i in range(islets):
            x, y = polar(rng.uniform(rmin, rmax * 0.8), rng.uniform(0, 360))
            z = rng.uniform(-60, 20)
            s = rng.uniform(9, 18)
            m.brick(x, y, z, s * 1.6, s * 1.3, 2.5, self.top_look)
            m.brick(x, y, z - s * 0.4, s * 1.3, s * 1.0, s * 0.4, "dirt", studs=False)
            m.cone(x, y, s * 0.6, z - s * 0.4, z - s * 1.6, "rock", segs=6)
            (K.tree_round if i % 2 == 0 else K.tree_pine)(K.Frame(m, x, y, 0, z=z + 2.5), 0, 0, 0.8)

    def grass_studs(self, look=None, f=0.995):
        look = look or self.top_look
        K.add_studs(look, K.grid_in_polygon(self.top_pts(f), 0.0, keep=lambda x, y: not self.covered(x, y, ground_only=True)))


# ------------------------------------------------------------------ game models from their exported blocks (Roblox space)
def model_from_parts(col, name, parts, x, y, z=0.0, scale=1.0, facing=0.0):
    """Rebuilds a model exported as Roblox-space blocks (p / s / r / c / t, as tools/zones/bosses.json and
    lawyers_top.json store them) into one Blender object: scale x, turned `facing` degrees, feet at (x, y, z)."""
    bm = bmesh.new()
    looks = []
    c, s = math.cos(math.radians(facing)), math.sin(math.radians(facing))
    for p in parts:
        rx, ry, rz = p["p"]
        bxp, byp, bzp = rx, -rz, ry  # Roblox -> Blender
        R = p["r"]
        Rr = [[R[0], R[1], R[2]], [R[3], R[4], R[5]], [R[6], R[7], R[8]]]
        ax = [(Rr[0][j], -Rr[2][j], Rr[1][j]) for j in range(3)]  # each local axis in Blender space
        half = (p["s"][0] / 2, p["s"][1] / 2, p["s"][2] / 2)
        rgb = tuple(p["c"])
        neon = p.get("t") == "neon"
        lk = "model_%d_%d_%d" % rgb + ("_neon" if neon else "")
        if neon and lk not in K.GLOWS:
            K.GLOWS[lk] = (rgb, 2.0)
        elif not neon and lk not in K.PAL:
            K.PAL[lk] = rgb
        if lk not in looks:
            looks.append(lk)
        mi = looks.index(lk)
        vs = []
        for sx_ in (-1, 1):
            for sy_ in (-1, 1):
                for sz_ in (-1, 1):
                    lx = sx_ * half[0] * ax[0][0] + sy_ * half[1] * ax[1][0] + sz_ * half[2] * ax[2][0] + bxp
                    ly = sx_ * half[0] * ax[0][1] + sy_ * half[1] * ax[1][1] + sz_ * half[2] * ax[2][1] + byp
                    lz = sx_ * half[0] * ax[0][2] + sy_ * half[1] * ax[1][2] + sz_ * half[2] * ax[2][2] + bzp
                    lx, ly, lz = lx * scale, ly * scale, lz * scale
                    vs.append(bm.verts.new((x + lx * c - ly * s, y + lx * s + ly * c, z + lz)))
        for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            try:
                f = bm.faces.new([vs[i] for i in q])
                f.material_index = mi
            except ValueError:
                pass
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    for lk in looks:
        me.materials.append(K.mat(lk))
    ob = bpy.data.objects.new(name, me)
    col.objects.link(ob)
    return ob


def boss(col, name, x, y, z=0.0, scale=1.0, facing=0.0):
    """A zone boss from tools/zones/bosses.json - for layout scale + presentation only (in game BossService +
    Bosses.client draw and animate it)."""
    data = json.load(open(os.path.join(REPO, "tools", "zones", "bosses.json")))[name]
    return model_from_parts(col, "Boss_" + name, data["parts"], x, y, z, scale, facing)


def lawyer(col, name, x, y, z=0.0, scale=1.0, facing=0.0):
    """A hatched lawyer from tools/zones/lawyers_top.json (the Epic / Mythic / Supreme cast) - e.g. a giant statue."""
    data = json.load(open(os.path.join(REPO, "tools", "zones", "lawyers_top.json")))[name]
    return model_from_parts(col, "Statue_" + name, data["parts"], x, y, z, scale, facing)


# ------------------------------------------------------------------ plan labels
def label(col, plate_mesh, text, x, y, size=6.0, z=260.0):
    cu = bpy.data.curves.new("Label", "FONT")
    cu.body = text
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.size = size
    cu.font = K.font("rounded")
    ob = bpy.data.objects.new("Label_" + text[:16], cu)
    ob.location = (x, y, z + 1)
    cu.materials.append(K.mat("white"))
    col.objects.link(ob)
    lines = text.split("\n")
    plate_mesh.brick(x, y, z - 0.6, max(len(t) for t in lines) * size * 0.6 + size, len(lines) * size * 1.25 + size * 0.4, 0.5, "ink", studs=False, bevel=0.0)
