# tools/blender/meshkit.py - small mesh helpers for the Blender scripts that export meshes to Roblox as JSON
# (eggs v5 incubator, ...). A Mesh keeps positions plus per-corner normals and UVs; export_mesh writes the JSON that
# tools/zones/BuildEggsV5.lua turns into EditableMesh -> uploaded Mesh assets. Blender (x, y, z) -> Roblox (x, z, -y).
# Import from a script run by tools/blender/send.ps1:  sys.path.insert(0, <repo>/tools/blender); from meshkit import *
import json, math
from mathutils import Vector

TAU = math.tau
UV0 = (0.5, 0.5)


class Mesh:
    def __init__(self, name):
        self.name = name
        self.v = []
        self.f = []  # ((vi, normal or None, uv) x 3)

    def vert(self, p):
        self.v.append(Vector(p))
        return len(self.v) - 1

    def tri(self, a, b, c, expect=None):
        pa, pb, pc = self.v[a[0]], self.v[b[0]], self.v[c[0]]
        g = (pb - pa).cross(pc - pa)
        if expect is None:
            ns = [x[1] for x in (a, b, c) if x[1] is not None]
            expect = sum(ns, Vector()) if ns else None
        if expect is not None and g.dot(expect) < 0:
            b, c = c, b
        self.f.append((a, b, c))

    def quad(self, a, b, c, d, expect=None):
        self.tri(a, b, c, expect)
        self.tri(a, c, d, expect)

    def merge(self, other):
        off = len(self.v)
        self.v.extend(other.v)
        for fa in other.f:
            self.f.append(tuple((vi + off, n, uv) for vi, n, uv in fa))
        return self

    def moved(self, fn):
        """A copy with every position mapped by fn (normals re-derived later by smooth())."""
        out = Mesh(self.name)
        out.v = [fn(p) for p in self.v]
        out.f = [tuple((vi, None, uv) for vi, n, uv in fa) for fa in self.f]
        out.flat = getattr(self, "flat", False)
        return out


def smooth(m, crease_deg=None):
    """Fill missing normals with area-weighted vertex normals (or face normals when m.flat)."""
    acc = [Vector() for _ in m.v]
    fn = []
    for fa in m.f:
        a, b, c = (m.v[x[0]] for x in fa)
        g = (b - a).cross(c - a)
        fn.append(g)
        for x in fa:
            acc[x[0]] += g
    out = Mesh(m.name)
    out.v = m.v
    flat = getattr(m, "flat", False)
    out.f = []
    for fa, g in zip(m.f, fn):
        gn = g.normalized() if g.length > 1e-12 else Vector((0, 0, 1))
        cs = []
        for vi, n, uv in fa:
            if n is None:
                n = gn if flat else (acc[vi].normalized() if acc[vi].length > 1e-12 else gn)
            cs.append((vi, n, uv))
        out.f.append(tuple(cs))
    return out


def lathe(name, prof, n=32, centre=(0, 0, 0), close_ends=True):
    """Lathe a profile [(r, z)...] around Z (r = 0 -> one pole vertex)."""
    m = Mesh(name)
    cx, cy, cz = centre
    rings = []
    for r, z in prof:
        if r < 1e-5:
            rings.append([m.vert((cx, cy, cz + z))] * n)
        else:
            rings.append([m.vert((cx + math.sin(a * TAU / n) * r, cy + math.cos(a * TAU / n) * r, cz + z)) for a in range(n)])
    axis = Vector((cx, cy, 0))
    for i in range(len(rings) - 1):
        for a in range(n):
            b = (a + 1) % n
            r0, r1 = rings[i], rings[i + 1]
            pm = (m.v[r0[a]] + m.v[r1[b]]) / 2
            dr = prof[i + 1][0] - prof[i][0]
            dz = prof[i + 1][1] - prof[i][1]
            rad = Vector((pm.x - cx, pm.y - cy, 0))
            rad = rad.normalized() if rad.length > 1e-6 else Vector((0, 0, 0))
            exp = rad * dz - Vector((0, 0, 1)) * dr
            if exp.length < 1e-9:
                exp = None
            C = lambda vi: (vi, None, UV0)
            if r0[a] == r0[b]:
                m.tri(C(r0[a]), C(r1[b]), C(r1[a]), exp)
            elif r1[a] == r1[b]:
                m.tri(C(r0[a]), C(r0[b]), C(r1[a]), exp)
            else:
                m.quad(C(r0[a]), C(r0[b]), C(r1[b]), C(r1[a]), exp)
    return m


def frame_along(points):
    out = []
    up = Vector((0, 0, 1))
    prev = None
    for i, p in enumerate(points):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        t = (b - a).normalized()
        if prev is None:
            ref = up if abs(t.dot(up)) < 0.9 else Vector((1, 0, 0))
            n = (ref - t * ref.dot(t)).normalized()
        else:
            n = (prev - t * prev.dot(t)).normalized()
        prev = n
        out.append((p, n, t.cross(n).normalized()))
    return out


def sweep(name, path, profile, caps=True, scale_fn=None):
    """Sweep a closed 2D profile along frames [(point, n, b)...]; scale_fn(i) scales the profile per ring."""
    m = Mesh(name)
    rings = []
    for i, (p, nx, ny) in enumerate(path):
        s = scale_fn(i) if scale_fn else 1.0
        rings.append([m.vert(p + nx * x * s + ny * y * s) for x, y in profile])
    k = len(profile)
    for i in range(len(rings) - 1):
        for a in range(k):
            b = (a + 1) % k
            q = [rings[i][a], rings[i][b], rings[i + 1][b], rings[i + 1][a]]
            cen = (path[i][0] + path[i + 1][0]) / 2
            mid = sum((m.v[x] for x in q), Vector()) / 4
            m.quad(*[(x, None, UV0) for x in q], expect=mid - cen)
    if caps:
        for i, sgn in ((0, -1), (len(rings) - 1, 1)):
            p = path[i][0]
            t = (path[min(i + 1, len(path) - 1)][0] - path[max(i - 1, 0)][0]).normalized() * sgn
            c = m.vert(p)
            for a in range(k):
                b = (a + 1) % k
                m.tri((c, t, UV0), (rings[i][a], t, UV0), (rings[i][b], t, UV0), t)
    return m


def circle(r, n=16, sx=1.0, sy=1.0):
    return [(math.cos(a * TAU / n) * r * sx, math.sin(a * TAU / n) * r * sy) for a in range(n)]


def rounded_rect(w, h, r, n=4):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def torus(name, R, r, n=48, k=12, centre=(0, 0, 0), sx=1.0):
    path = [Vector((math.sin(a * TAU / n) * R, math.cos(a * TAU / n) * R, 0)) for a in range(n + 1)]
    m = Mesh(name)
    rings = []
    for i in range(n):
        a = i * TAU / n
        radial = Vector((math.sin(a), math.cos(a), 0))
        rings.append([m.vert(Vector(centre) + radial * (R + math.cos(b * TAU / k) * r * sx) + Vector((0, 0, math.sin(b * TAU / k) * r))) for b in range(k)])
    for i in range(n):
        i1 = (i + 1) % n
        a = i * TAU / n
        cen = Vector(centre) + Vector((math.sin(a), math.cos(a), 0)) * R
        for b in range(k):
            b1 = (b + 1) % k
            q = [rings[i][b], rings[i1][b], rings[i1][b1], rings[i][b1]]
            m.quad(*[(x, None, UV0) for x in q], expect=m.v[q[0]] - cen)
    return m


def box(name, size, centre=(0, 0, 0), bevel=0.0):
    """A box; with bevel > 0 a rounded box (profile swept along z)."""
    sx, sy, sz = size
    cx, cy, cz = centre
    if bevel <= 0:
        m = Mesh(name)
        m.flat = True
        V = [m.vert((cx + x * sx / 2, cy + y * sy / 2, cz + z * sz / 2)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
        def idx(x, y, z):
            return ((x > 0) * 4) + ((y > 0) * 2) + (z > 0)
        for axis in range(3):
            for s in (-1, 1):
                corners = []
                for u in (-1, 1):
                    for v in (-1, 1):
                        c = [0, 0, 0]
                        c[axis] = s
                        c[(axis + 1) % 3] = u
                        c[(axis + 2) % 3] = v
                        corners.append(V[idx(*c)])
                n = Vector([s if i == axis else 0 for i in range(3)])
                a, b, c2, d = corners[0], corners[1], corners[3], corners[2]
                m.quad((a, n, UV0), (b, n, UV0), (c2, n, UV0), (d, n, UV0), n)
        return m
    prof = rounded_rect(sx, sy, min(bevel, sx / 2 - 1e-3, sy / 2 - 1e-3), 4)
    pts = [Vector((cx, cy, cz - sz / 2)), Vector((cx, cy, cz + sz / 2))]
    fr = [(pts[0], Vector((1, 0, 0)), Vector((0, 1, 0))), (pts[1], Vector((1, 0, 0)), Vector((0, 1, 0)))]
    return sweep(name, fr, prof)


def to_rbx(v):
    return (v[0], v[2], -v[1])


def export_mesh(m, path):
    m = smooth(m)
    vs, ns, uvs, fs = [], [], [], []
    nidx, uidx = {}, {}
    for p in m.v:
        vs.extend(round(c, 4) for c in to_rbx(p))
    for fa in m.f:
        for vi, n, uv in fa:
            rn = tuple(round(c, 3) for c in to_rbx(n))
            if rn not in nidx:
                nidx[rn] = len(nidx)
                ns.extend(rn)
            ru = (round(uv[0], 4), round(uv[1], 4))
            if ru not in uidx:
                uidx[ru] = len(uidx)
                uvs.extend(ru)
            fs.extend((vi, nidx[rn], uidx[ru]))
    lo = [min(vs[i::3]) for i in range(3)]
    hi = [max(vs[i::3]) for i in range(3)]
    mid = [(lo[i] + hi[i]) / 2 for i in range(3)]  # (centred: a MeshPart draws its mesh around the part's CFrame)
    vs = [round(c - mid[i % 3], 4) for i, c in enumerate(vs)]
    with open(path, "w") as fh:
        json.dump(dict(v=vs, n=ns, uv=uvs, f=fs, lo=lo, hi=hi), fh, separators=(",", ":"))
    return dict(file=path.replace("\\", "/").split("/")[-1], tris=len(m.f), lo=lo, hi=hi)


def to_object(bpy, sc, m, name, mat, loc=(0, 0, 0)):
    m = smooth(m)
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in m.v], [], [tuple(c[0] for c in fa) for fa in m.f])
    for p in me.polygons:
        p.use_smooth = not getattr(m, "flat", False)
    if mat:
        me.materials.append(mat)
    o = bpy.data.objects.new(name, me)
    o.location = loc
    sc.collection.objects.link(o)
    return o
