# tools/blender/eggs_v5.py - the eggs, v5 (2026-10-12, mr.robe: "remake ... everything to do with the eggs through
# blender ... 10000x cooler and more detailed", "recreate the eggs itself", "i dont like the little balls that
# protrude out of the eggs").
#
# Real meshes instead of v4's Parts-and-spheres: every egg shares ONE smooth shell (a lathe, so it has no seam) and
# gets its own PAINTED texture (painted here pixel by pixel from 3D patterns, so nothing stretches or seams), flush
# RELIEF layers that wrap the shell (belt, collar, frosting, wave) and use the same texture, and a few smooth
# freestanding pieces (handle, ears, brain, cream swirl, fin, planet ring). No little balls stuck on anything.
# The hatch uses a high-res copy of the shell that is pre-cut into CHUNKS (a zigzag belt crack + meandering cracks),
# and CRACK ribbons along the cuts in 3 stages (tap 1, 2, 3). tools/blender/egg_break.py simulates the chunks.
#
# Run inside Blender: tools/blender/send.ps1 -File tools/blender/eggs_v5.py
# Writes _egg_export/ (meshes as JSON + textures as PNG; uploaded to Roblox by tools/zones/BuildEggsV5.lua, then
# deleted - not in git) and art/eggs/v5_preview.png. 1 Blender m = 1 stud; Blender (x, y, z) -> Roblox (x, z, -y);
# the egg's front faces +Y (Roblox -Z); it stands on z = 0.
import bpy, math, json, os, random
import numpy as np
from mathutils import Vector, noise

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
OUT = os.path.join(REPO, "_egg_export")
PREVIEW = os.path.join(REPO, "art", "eggs", "v5_preview.png")
os.makedirs(OUT, exist_ok=True)

# ------------------------------------------------------------------ the shell: a lathe, param (theta, t)
H, W, K = 3.8, 3.0, 0.1  # height, width, how much fuller the bottom is
TEX = 1024
V_OUT = 0.94  # texture rows 0..V_OUT = the outside (top of the egg at row 0); below = the inside colour
UV_INSIDE = (0.5, 0.975)
TAU = math.tau


def zt(t):
    return H / 2 * (1 - math.cos(t))


def rt(t):
    return W / 2 * math.sin(t) * (1 + K * math.cos(t))


def t_of_z(z):
    return math.acos(max(-1.0, min(1.0, 1 - 2 * z / H)))


def surf(th, t, out=0.0):
    """Point on the shell at angle th (0 = front, +Y), lathe param t (0 bottom .. pi top), pushed `out` along the
    normal; and the outward normal."""
    r = rt(t)
    dr = W / 2 * (math.cos(t) * (1 + K * math.cos(t)) - K * math.sin(t) ** 2)
    dz = H / 2 * math.sin(t)
    nr, nz = dz, -dr
    L = math.hypot(nr, nz) or 1.0
    nr, nz = nr / L, nz / L
    s, c = math.sin(th), math.cos(th)
    n = Vector((nr * s, nr * c, nz))
    return Vector((r * s, r * c, zt(t))) + n * out, n


def uv_of(th, t):
    return (th / TAU, V_OUT * (1 - t / math.pi))


# ------------------------------------------------------------------ a tiny mesh type (per-corner normal + uv)
class Mesh:
    def __init__(self, name):
        self.name = name
        self.v = []  # positions (Vector)
        self.f = []  # ((vi, n, uv) x 3)

    def vert(self, p):
        self.v.append(Vector(p))
        return len(self.v) - 1

    def tri(self, a, b, c, expect=None):
        """a, b, c = (vi, normal, uv); turned so its face normal agrees with `expect` (default: the corner normals)."""
        pa, pb, pc = self.v[a[0]], self.v[b[0]], self.v[c[0]]
        g = (pb - pa).cross(pc - pa)
        e = expect if expect is not None else (a[1] + b[1] + c[1])
        if g.dot(e) < 0:
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


def lathe_grid(S, R, t_lo, t_hi, out=0.0, th_fn=None):
    """A grid over the shell: S columns (wrapping), R rows from t_lo to t_hi (pole rows collapse to one vertex).
    Returns (mesh, ids[k][j], params[k][j] = (th, t))."""
    m = Mesh("grid")
    ids, params = [], []
    for k in range(R + 1):
        t = t_lo + (t_hi - t_lo) * k / R
        pole = t < 1e-6 or t > math.pi - 1e-6
        row, prow = [], []
        if pole:
            p, n = surf(0, t, out)
            vid = m.vert(p)
            row = [vid] * S
            prow = [(j * TAU / S, t) for j in range(S)]
        else:
            for j in range(S):
                th = j * TAU / S
                p, n = surf(th, t, out)
                row.append(m.vert(p))
                prow.append((th, t))
        ids.append(row)
        params.append(prow)
    return m, ids, params


def corner(m, vi, th, t, out=0.0, wrap=False):
    _, n = surf(th, t, out)
    u, v = uv_of(TAU if wrap else th, t)
    return (vi, n, (u, v))


def grid_quads(R, S):
    """(k, j, k1, j1, wraps) for every quad of a lathe grid."""
    for k in range(R):
        for j in range(S):
            yield k, j, k + 1, (j + 1) % S, j + 1 == S


def fill_grid(m, ids, params, R, S, out=0.0, keep=None):
    for k, j, k1, j1, wraps in grid_quads(R, S):
        if keep and not keep(k, j):
            continue
        A = corner(m, ids[k][j], *params[k][j], out)
        B = corner(m, ids[k][j1], params[k][j1][0], params[k][j1][1], out, wraps)
        C = corner(m, ids[k1][j1], params[k1][j1][0], params[k1][j1][1], out, wraps)
        D = corner(m, ids[k1][j], *params[k1][j], out)
        if ids[k][j] == ids[k][j1]:  # bottom pole fan
            m.tri(A, C, D)
        elif ids[k1][j] == ids[k1][j1]:
            m.tri(A, B, C)
        else:
            m.quad(A, B, C, D)


# ------------------------------------------------------------------ the display shell (zones, carried, idle)
def make_shell(S, R):
    m, ids, params = lathe_grid(S, R, 0.0, math.pi)
    fill_grid(m, ids, params, R, S)
    m.name = "Shell"
    return m


# ------------------------------------------------------------------ the hatch shell: chunks + cracks
HS, HR = 120, 80  # hi-res grid (the hatch shell stays under Roblox's 20k triangles per mesh)
BELT_Z, BELT_AMP, BELT_TEETH = 0.56 * H, 0.26, 8


def belt_z(th):
    x = (th / TAU * BELT_TEETH) % 1.0
    tri = 4 * abs(x - 0.5) - 1  # -1..1 triangle wave
    return BELT_Z + BELT_AMP * tri


def make_chunks():
    m, ids, params = lathe_grid(HS, HR, 0.0, math.pi)
    rnd = random.Random(5)
    # seeds: 5 in the top cap, 7 in the bottom cup (as directions on the shell), jittered
    seeds = []
    for i in range(5):
        th = i * TAU / 5 + rnd.uniform(-0.3, 0.3)
        seeds.append(("top", surf(th, rnd.uniform(0.68, 0.86) * math.pi)[0]))
    for i in range(7):
        th = i * TAU / 7 + 0.4 + rnd.uniform(-0.25, 0.25)
        seeds.append(("bot", surf(th, rnd.uniform(0.18, 0.42) * math.pi)[0]))
    owner = {}
    for k, j, k1, j1, wraps in grid_quads(HR, HS):
        th = (params[k][j][0] + (TAU / HS) / 2)
        t = (params[k][j][1] + params[k1][j][1]) / 2
        c, _ = surf(th, t)
        top = c.z > belt_z(th)
        best, bi = 1e9, 0
        wob = noise.noise(c * 1.7) * 0.55 + noise.noise(c * 4.3) * 0.2
        for i, (side, s) in enumerate(seeds):
            if (side == "top") != top:
                continue
            d = (c - s).length + wob * (0.6 if i % 2 else -0.6)
            if d < best:
                best, bi = d, i
        owner[(k, j)] = bi
    chunks = []
    for ci in range(len(seeds)):
        cm = Mesh(f"Chunk{ci + 1}")
        cm.top = seeds[ci][0] == "top"
        chunks.append(cm)
    vparam = {}
    for k in range(HR + 1):
        for j in range(HS):
            vparam.setdefault(ids[k][j], params[k][j])

    # 1) the edges between chunks, chained into paths (junction to junction)
    graph = {}
    for k, j, k1, j1, wraps in grid_quads(HR, HS):
        me = owner[(k, j)]
        for (nk, nj, ea, eb) in ((k, j1, (k, j1), (k1, j1)), (k1, j, (k1, j), (k1, j1))):
            if nk >= HR:
                continue
            other = owner[(nk, nj)]
            if other == me:
                continue
            a, b = ids[ea[0]][ea[1]], ids[eb[0]][eb[1]]
            if a == b:
                continue
            belt = chunks[me].top != chunks[other].top
            graph.setdefault(a, {})[b] = belt
            graph.setdefault(b, {})[a] = belt
    used = set()
    paths = []

    def walk(start, nxt):
        path = [start, nxt]
        used.add(frozenset((start, nxt)))
        while len(graph[path[-1]]) == 2:
            cur = path[-1]
            step = [n for n in graph[cur] if frozenset((cur, n)) not in used]
            if not step:
                break
            used.add(frozenset((cur, step[0])))
            path.append(step[0])
        return path

    for node, nbrs in graph.items():
        if len(nbrs) != 2:
            for n in nbrs:
                if frozenset((node, n)) not in used:
                    paths.append(walk(node, n))
    for node, nbrs in graph.items():  # (closed loops with no junction)
        for n in nbrs:
            if frozenset((node, n)) not in used:
                paths.append(walk(node, n))

    # 2) smooth every path (Chaikin, ends kept) and slide its grid vertices onto the smooth curve, so the chunks'
    #    edges follow it too (no grid stairs). Moves are stored as (d_theta, d_t) so UVs stay seam-safe.
    def shell_pt(gv):
        th, t = vparam[gv]
        return surf(th, t)[0]

    smooth_paths = []
    disp = {}
    for path in paths:
        pts = [shell_pt(v) for v in path]
        for _ in range(3):
            if len(pts) < 3:
                break
            new = [pts[0]]
            for i in range(len(pts) - 1):
                new.append(pts[i] * 0.75 + pts[i + 1] * 0.25)
                new.append(pts[i] * 0.25 + pts[i + 1] * 0.75)
            new.append(pts[-1])
            pts = new
        smooth_paths.append((path, pts))
        for v in path[1:-1]:
            th0, t0 = vparam[v]
            if t0 < 1e-6 or t0 > math.pi - 1e-6:
                continue
            p0 = surf(th0, t0)[0]
            best = min(pts, key=lambda q: (q - p0).length_squared)
            th1, t1 = math.atan2(best.x, best.y), t_of_z(best.z)
            dth = math.atan2(math.sin(th1 - th0), math.cos(th1 - th0))
            disp[v] = (dth, t1 - t0)

    def moved(gv, th, t):
        d = disp.get(gv)
        return (th + d[0], t + d[1]) if d else (th, t)

    # 3) each chunk: its outer faces, the inside (offset in), and walls along its edges
    T = 0.11
    for ci, cm in enumerate(chunks):
        remap = {}

        def vid(gv, inner=False):
            key = (gv, inner)
            if key not in remap:
                th, t = moved(gv, *vparam[gv])
                p, n = surf(th, t)
                if inner:
                    p = p - n * T
                remap[key] = cm.vert(p)
            return remap[key]

        edges = {}
        faces = []
        for k, j, k1, j1, wraps in grid_quads(HR, HS):
            if owner[(k, j)] != ci:
                continue
            quad = [(k, j, False), (k, j1, wraps), (k1, j1, wraps), (k1, j, False)]
            ring = []
            for kk, jj, w in quad:
                gv = ids[kk][jj]
                if ring and ring[-1][0] == gv:
                    continue
                ring.append((gv, params[kk][jj], w))
            if ring[0][0] == ring[-1][0]:
                ring.pop()
            faces.append(ring)
            for a in range(len(ring)):
                e = (ring[a][0], ring[(a + 1) % len(ring)][0])
                edges.setdefault(tuple(sorted(e)), []).append((ring[a], ring[(a + 1) % len(ring)]))
        for ring in faces:
            outer, inner = [], []
            for gv, (th, t), w in ring:
                th2, t2 = moved(gv, th, t)
                n = surf(th2, t2)[1]
                d = disp.get(gv, (0.0, 0.0))
                outer.append((vid(gv), n, uv_of((TAU if w else th) + d[0], t2)))
                inner.append((vid(gv, True), -n, UV_INSIDE))
            rn = ring_normal(ring)
            for poly, exp in ((outer, None), (inner, -rn)):
                if len(poly) == 3:
                    cm.tri(poly[0], poly[1], poly[2], exp)
                else:
                    cm.quad(poly[0], poly[1], poly[2], poly[3], exp)
        centre = sum((cm.v[i] for i in range(len(cm.v))), Vector()) / max(len(cm.v), 1)
        for key, uses in edges.items():
            if len(uses) != 1:
                continue
            (ga, _, _), (gb, _, _) = uses[0]
            a, b = vid(ga), vid(gb)
            ai, bi2 = vid(ga, True), vid(gb, True)
            mid = (cm.v[a] + cm.v[b]) / 2
            _, sn = surf(math.atan2(mid.x, mid.y), t_of_z(mid.z))
            wall_n = (cm.v[b] - cm.v[a]).cross(sn).normalized()
            if wall_n.dot(mid - centre) < 0:
                wall_n = -wall_n
            cm.quad((a, wall_n, UV_INSIDE), (b, wall_n, UV_INSIDE), (bi2, wall_n, UV_INSIDE), (ai, wall_n, UV_INSIDE), wall_n)

    # 4) the cracks: the smooth paths, resampled, roughened with a fine jagged jitter, as ribbons in 3 stages
    #    (A = the belt's front, B = the rest of the belt, C = every other crack)
    stage = [Mesh("CrackA"), Mesh("CrackB"), Mesh("CrackC")]
    jit = random.Random(17)
    for path, pts in smooth_paths:
        belt = all(graph[path[i]][path[i + 1]] for i in range(len(path) - 1))
        res = [pts[0]]
        acc = 0.0
        for i in range(1, len(pts)):
            acc += (pts[i] - pts[i - 1]).length
            if acc >= 0.09 or i == len(pts) - 1:
                res.append(pts[i])
                acc = 0.0
        tp = []
        for i, p in enumerate(res):
            th, t = math.atan2(p.x, p.y), t_of_z(p.z)
            if 0 < i < len(res) - 1:
                _, n = surf(th, t)
                side = (res[i + 1] - res[i - 1]).cross(n).normalized()
                p = p + side * jit.uniform(-0.035, 0.035)
                th, t = math.atan2(p.x, p.y), t_of_z(p.z)
            tp.append((th, t))
        mid = tp[len(tp) // 2]
        front = abs(math.atan2(math.sin(mid[0]), math.cos(mid[0]))) < math.radians(65)
        si = 0 if (belt and front) else 1 if belt else 2
        ribbon_strip(stage[si], tp, 0.085 if belt else 0.065, jit)
    return chunks, stage


def ring_normal(ring):
    th, t = ring[0][1]
    return surf(th, t)[1]


def ribbon_strip(m, tp, w, rnd, out=0.02):
    """One continuous ribbon along points (theta, t) on the shell, a little wider in the middle."""
    n_pts = len(tp)
    if n_pts < 2:
        return
    P = [surf(th, t, out) for th, t in tp]
    left, right, norms = [], [], []
    for i, (p, n) in enumerate(P):
        a = P[max(i - 1, 0)][0]
        b = P[min(i + 1, n_pts - 1)][0]
        d = b - a
        if d.length < 1e-6:
            d = Vector((0, 0, 1))
        side = d.cross(n).normalized()
        f = i / (n_pts - 1)
        ww = w * (0.7 + 0.45 * math.sin(f * math.pi)) * rnd.uniform(0.85, 1.15)
        left.append(m.vert(p - side * ww / 2))
        right.append(m.vert(p + side * ww / 2))
        norms.append(n)
    uv = (0.5, 0.5)
    for i in range(n_pts - 1):
        n = (norms[i] + norms[i + 1]).normalized()
        m.quad((left[i], norms[i], uv), (left[i + 1], norms[i + 1], uv), (right[i + 1], norms[i + 1], uv), (right[i], norms[i], uv), n)


# ------------------------------------------------------------------ relief layers: flush bands that hug the shell
def relief_band(name, z_lo_fn, z_hi_fn, d, S=128, R=10, lip=True, top_pole=False):
    """A layer `d` thick over the shell between z_lo(th) and z_hi(th) (top_pole: up to the top pole), with lips
    down to the shell at its edges. UVs follow the shell's mapping, so it wears the egg's texture."""
    m = Mesh(name)
    rows = []
    for k in range(R + 1):
        row = []
        for j in range(S):
            th = j * TAU / S
            tl = t_of_z(z_lo_fn(th))
            thi = math.pi if top_pole else t_of_z(min(z_hi_fn(th), H - 1e-4))
            t = tl + (thi - tl) * k / R
            row.append((th, t))
        rows.append(row)
    vids = [[m.vert(surf(th, t, d)[0]) for th, t in row] for row in rows]
    for k in range(R):
        for j in range(S):
            j1 = (j + 1) % S
            w = j + 1 == S
            def C(kk, jj, wrap):
                th, t = rows[kk][jj]
                return (vids[kk][jj], surf(th, t, d)[1], uv_of(TAU if wrap else th, t))
            m.quad(C(k, j, False), C(k, j1, w), C(k + 1, j1, w), C(k + 1, j, False))
    if lip:
        edges = [0] if top_pole else [0, R]
        for k in edges:
            for j in range(S):
                j1 = (j + 1) % S
                w = j + 1 == S
                tha, ta = rows[k][j]
                thb, tb = rows[k][j1]
                a, b = vids[k][j], vids[k][j1]
                ai = m.vert(surf(tha, ta, -0.01)[0])
                bi = m.vert(surf(thb, tb, -0.01)[0])
                _, n = surf(tha, ta)
                tang = Vector((0, 0, -1 if k == 0 else 1))
                ln = (tang - n * tang.dot(n)).normalized()
                uva, uvb = uv_of(tha, ta), uv_of(TAU if w else thb, tb)
                m.quad((a, ln, uva), (b, ln, uvb), (bi, ln, uvb), (ai, ln, uva), ln)
    return m


# ------------------------------------------------------------------ freestanding pieces
def sweep(name, path, profile, closed_profile=True, caps=True, smooth=True):
    """Sweep a 2D profile [(x, y)...] along path [(point, normal, binormal)...]."""
    m = Mesh(name)
    rings = []
    for p, nx, ny in path:
        rings.append([m.vert(p + nx * x + ny * y) for x, y in profile])
    np_ = len(profile)
    for i in range(len(rings) - 1):
        for a in range(np_ if closed_profile else np_ - 1):
            b = (a + 1) % np_
            r0, r1 = rings[i], rings[i + 1]
            P = [r0[a], r0[b], r1[b], r1[a]]
            cen = (m.v[r0[a]] + m.v[r0[b]] + m.v[r1[a]] + m.v[r1[b]]) / 4
            axis = path[i][0]
            corners = []
            for vi in P:
                n = (m.v[vi] - (path[i][0] if vi in r0 else path[i + 1][0])).normalized()
                corners.append((vi, n, (0.5, 0.5)))
            m.quad(*corners, expect=(cen - axis))
    if caps:
        for i, sign in ((0, -1), (len(rings) - 1, 1)):
            p = path[i][0]
            tangent = (path[min(i + 1, len(path) - 1)][0] - path[max(i - 1, 0)][0]).normalized() * sign
            c = m.vert(p)
            for a in range(np_):
                b = (a + 1) % np_
                m.tri((c, tangent, (0.5, 0.5)), (rings[i][a], tangent, (0.5, 0.5)), (rings[i][b], tangent, (0.5, 0.5)), tangent)
    return m


def frame_along(points):
    """(point, normal, binormal) frames along a polyline (parallel transport)."""
    out = []
    up = Vector((0, 0, 1))
    prev_n = None
    for i, p in enumerate(points):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        tng = (b - a).normalized()
        if prev_n is None:
            ref = up if abs(tng.dot(up)) < 0.9 else Vector((1, 0, 0))
            n = (ref - tng * ref.dot(tng)).normalized()
        else:
            n = (prev_n - tng * prev_n.dot(tng)).normalized()
        prev_n = n
        out.append((p, n, tng.cross(n).normalized()))
    return out


def circle(r, n=14, sx=1.0, sy=1.0):
    return [(math.cos(a * TAU / n) * r * sx, math.sin(a * TAU / n) * r * sy) for a in range(n)]


def rounded_rect(w, h, r, n=4):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def lathe(name, prof, n=24):
    """Lathe a profile [(r, z)...] (bottom to top) around Z."""
    m = Mesh(name)
    rings = []
    for r, z in prof:
        if r < 1e-4:
            rings.append([m.vert((0, 0, z))] * n)
        else:
            rings.append([m.vert((math.sin(a * TAU / n) * r, math.cos(a * TAU / n) * r, z)) for a in range(n)])
    for i in range(len(rings) - 1):
        for a in range(n):
            b = (a + 1) % n
            r0, r1 = rings[i], rings[i + 1]
            def C(vi):
                p = m.v[vi]
                return (vi, None, (0.5, 0.5))
            q = [r0[a], r0[b], r1[b], r1[a]]
            qq = []
            for vi in q:
                qq.append(vi)
            # normals: from the profile slope
            corners = []
            for vi, ii in ((r0[a], i), (r0[b], i), (r1[b], i + 1), (r1[a], i + 1)):
                p = m.v[vi]
                i0, i1 = max(ii - 1, 0), min(ii + 1, len(prof) - 1)
                dr = prof[i1][0] - prof[i0][0]
                dz = prof[i1][1] - prof[i0][1]
                rad = Vector((p.x, p.y, 0))
                rad = rad.normalized() if rad.length > 1e-5 else Vector((0, 0, 0))
                nn = (rad * dz - Vector((0, 0, 1)) * dr)
                nn = nn.normalized() if nn.length > 1e-6 else Vector((0, 0, 1 if ii else -1))
                corners.append((vi, nn, (0.5, 0.5)))
            if r0[a] == r0[b]:
                m.tri(corners[0], corners[2], corners[3])
            elif r1[a] == r1[b]:
                m.tri(corners[0], corners[1], corners[2])
            else:
                m.quad(*corners)
    return m


def transformed(m, fn):
    """Apply fn(p) -> p to the positions and re-derive normals by finite differences of fn."""
    out = Mesh(m.name)
    out.v = [fn(p) for p in m.v]
    eps = 1e-3
    for fa in m.f:
        newc = []
        for vi, n, uv in fa:
            p = m.v[vi]
            if n is None:
                newc.append((vi, n, uv))
                continue
            # transform the normal with the inverse transpose of fn's Jacobian (finite differences)
            J = [(fn(p + Vector(ax) * eps) - fn(p)) / eps for ax in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]
            import mathutils
            M3 = mathutils.Matrix((J[0], J[1], J[2])).transposed()
            try:
                nn = (M3.inverted().transposed() @ n).normalized()
            except ValueError:
                nn = n
            newc.append((vi, nn, uv))
        out.f.append(tuple(newc))
    return out


# per egg: relief layers + freestanding pieces (name, mesh, rgb, material)
DECOR = {}


def decor(name):
    def deco(fn):
        DECOR[name] = fn
        return fn
    return deco


@decor("Briefcase")
def _():
    out = []
    out.append(("Relief", relief_band("Relief", lambda th: 1.5, lambda th: 1.98, 0.075), None, "tex"))
    # the clasp on the belt's front: a rounded gold plate
    p, n = surf(0, t_of_z(1.74), 0.075)
    pts = [p + n * (i * 0.06) for i in range(4)]
    clasp = sweep("Clasp", frame_along(pts), rounded_rect(0.64, 0.56, 0.12))
    out.append(("Clasp", clasp, (255, 200, 50), "metal"))
    # the handle: a rounded arch over the top, on two gold feet
    arch = []
    for i in range(17):
        a = math.pi * i / 16
        arch.append(Vector((math.cos(a) * 0.5, 0, 3.66 + math.sin(a) * 0.48)))
    out.append(("Handle", sweep("Handle", frame_along(arch), rounded_rect(0.2, 0.3, 0.08)), (95, 52, 26), None))
    for sx in (-1, 1):
        foot = lathe("Foot", [(0, 3.58), (0.2, 3.58), (0.2, 3.7), (0.15, 3.78), (0, 3.8)], 16)
        out.append(("HandleFoot", transformed(foot, lambda q, sx=sx: q + Vector((sx * 0.5, 0, 0))), (255, 200, 50), "metal"))
    return out


@decor("Pet")
def _():
    out = []
    out.append(("Relief", relief_band("Relief", lambda th: 0.78, lambda th: 1.12, 0.07), None, "tex"))
    # floppy ears: a teardrop, flattened, hanging off the upper sides
    ear = lathe("Ear", [(0, 0), (0.42, 0.25), (0.5, 0.55), (0.42, 0.85), (0.22, 1.05), (0, 1.12)], 20)
    for sx in (-1, 1):
        def place(q, sx=sx):
            q = Vector((q.x * 0.32, q.y, q.z))  # flatten (thin sideways, flat against the head)
            q = Vector((q.x, q.y, -q.z))  # hang down
            # tilt out and back, then move to the side of the head
            a = math.radians(28) * sx
            x = q.x * math.cos(a) - q.z * math.sin(a)
            z = q.x * math.sin(a) + q.z * math.cos(a)
            q = Vector((x, q.y, z))
            p, n = surf(sx * math.radians(78), t_of_z(3.15), -0.05)
            return q + p
        out.append(("Ear", transformed(ear, place), (196, 124, 66), None))
    # a gold bone tag hanging from the collar's front (a flat bone, no balls)
    p, n = surf(0, t_of_z(0.6), 0.1)
    prof = rounded_rect(0.14, 0.5, 0.06)  # (x runs up the shell, y across: a horizontal bar)
    bar = sweep("Bone", frame_along([p + n * 0.0, p + n * 0.08]), [(x, y) for x, y in prof])
    for sx in (-1, 1):
        for sz in (-1, 1):
            q = p + Vector((sx * 0.25, 0, sz * 0.07))
            disc = sweep("BoneEnd", frame_along([q, q + n * 0.08]), circle(0.09, 12))
            bar.merge(disc)
    out.append(("Tag", bar, (255, 205, 60), "metal"))
    return out


@decor("Brainrot")
def _():
    out = []
    # an exposed pink brain on top: a bumpy cap with wrinkles and a groove down the middle
    S, R = 128, 22
    m = Mesh("Brain")
    t0 = t_of_z(3.0)
    rows = []
    for k in range(R + 1):
        t = t0 + (math.pi - t0) * k / R
        row = []
        for j in range(S if t < math.pi - 1e-6 else 1):
            th = j * TAU / S
            p, n = surf(th, t)
            fold = noise.noise(p * 2.6)
            wr = 0.09 * abs(math.sin(fold * 6.0))
            fiss = math.exp(-((math.sin(th) * rt(t)) / 0.07) ** 2) if t < math.pi - 0.02 else 0
            lift = 0.16 + wr - 0.12 * fiss
            edge = min(1.0, (t - t0) / 0.12)
            row.append(m.vert(p + n * (lift * edge + 0.01)))
        rows.append(row)
    for k in range(R):
        for j in range(S):
            j1 = (j + 1) % S
            a, b = rows[k][j], rows[k][j1]
            if len(rows[k + 1]) == 1:
                c = rows[k + 1][0]
                m.tri((a, None, (0.5, 0.5)), (b, None, (0.5, 0.5)), (c, None, (0.5, 0.5)), Vector(m.v[a]) - Vector((0, 0, 1.6)))
            else:
                c, d = rows[k + 1][j1], rows[k + 1][j]
                m.quad((a, None, (0.5, 0.5)), (b, None, (0.5, 0.5)), (c, None, (0.5, 0.5)), (d, None, (0.5, 0.5)), Vector(m.v[a]) - Vector((0, 0, 1.6)))
    out.append(("Brain", m, (255, 150, 195), "smooth"))
    return out


@decor("Food")
def _():
    out = []
    def drip(th):
        z = 2.5
        for c, depth, width in ((0.3, 0.55, 0.22), (1.25, 0.35, 0.18), (2.1, 0.7, 0.2), (3.05, 0.4, 0.2), (3.9, 0.6, 0.22), (4.8, 0.3, 0.16), (5.6, 0.5, 0.2)):
            d = math.atan2(math.sin(th - c), math.cos(th - c))
            if abs(d) < width:
                z = min(z, 2.5 - depth * math.sqrt(1 - (d / width) ** 2))
        return z + 0.05 * math.sin(th * 9)
    out.append(("Relief", relief_band("Relief", drip, None, 0.09, S=160, R=14, top_pole=True), None, "tex"))
    # a whipped-cream swirl on top
    pts = []
    for i in range(60):
        f = i / 59
        a = f * TAU * 2.4
        r = 0.62 * (1 - f) ** 0.9
        pts.append(Vector((math.cos(a) * r, math.sin(a) * r, 3.86 + f * 0.75)))
    prof = circle(1.0, 12)
    m = Mesh("Swirl")
    fr = frame_along(pts)
    rings = []
    for i, (p, nx, ny) in enumerate(fr):
        rad = 0.24 * (1 - i / 59) ** 0.5 + 0.03
        rings.append([m.vert(p + nx * x * rad + ny * y * rad) for x, y in prof])
    for i in range(len(rings) - 1):
        for a in range(12):
            b = (a + 1) % 12
            q = [rings[i][a], rings[i][b], rings[i + 1][b], rings[i + 1][a]]
            cen = fr[i][0]
            m.quad(*[(vi, (m.v[vi] - (fr[i][0] if vi in rings[i] else fr[i + 1][0])).normalized(), (0.5, 0.5)) for vi in q], expect=(m.v[q[0]] - cen))
    out.append(("Swirl", m, (255, 249, 238), "smooth"))
    # a wafer stick in the swirl
    wp = [Vector((0.22, -0.1, 3.95)), Vector((0.42, -0.18, 4.75))]
    out.append(("Wafer", sweep("Wafer", frame_along(wp), rounded_rect(0.4, 0.12, 0.04)), (238, 196, 132), None))
    return out


@decor("Ocean")
def _():
    out = []
    out.append(("Relief", relief_band("Relief", lambda th: 1.62 + 0.14 * math.sin(th * 5), lambda th: 2.02 + 0.14 * math.sin(th * 5 + 0.6), 0.065, S=160), None, "tex"))
    # a shark fin on top, swept back
    m = Mesh("Fin")
    outline = []
    for i in range(13):
        f = i / 12
        outline.append((-0.55 + 1.0 * f + 0.25 * f * f, 0.0 + 0.95 * math.sin(f * math.pi * 0.5) ** 1.3 * (1 - 0.15 * f)))
    # front edge up to the tip then the back edge curving down (concave)
    back = []
    for i in range(1, 9):
        f = i / 8
        x0, z0 = outline[-1]
        back.append((x0 + (0.55 - x0) * f, z0 * (1 - f) ** 1.6))
    loop = outline + back
    th_max = 0.13
    cz = 3.62
    sides = []
    for sgn in (-1, 1):
        sides.append([m.vert(Vector((0 + sgn * th_max * (1 - z / 1.0) * (1 - abs(x) * 0.4), -x, cz + z))) for x, z in loop])
    cen = Vector((0, 0, cz + 0.4))
    n = len(loop)
    for i in range(n):
        i1 = (i + 1) % n
        a, b = sides[0][i], sides[0][i1]
        c, d = sides[1][i1], sides[1][i]
        nn = (m.v[a] + m.v[c]) / 2 - cen
        nn = Vector((0, nn.y, nn.z)).normalized() if Vector((0, nn.y, nn.z)).length > 1e-4 else Vector((0, 0, 1))
        m.quad((a, nn, (0.5, 0.5)), (b, nn, (0.5, 0.5)), (c, nn, (0.5, 0.5)), (d, nn, (0.5, 0.5)), nn)
    for s, sgn in ((sides[0], -1), (sides[1], 1)):
        cc = m.vert(Vector((sgn * th_max * 0.6, 0.1, cz + 0.35)))
        nside = Vector((sgn, 0, 0))
        for i in range(n):
            i1 = (i + 1) % n
            m.tri((cc, nside, (0.5, 0.5)), (s[i], nside, (0.5, 0.5)), (s[i1], nside, (0.5, 0.5)), nside)
    out.append(("Fin", m, (96, 128, 165), None))
    return out


@decor("Space")
def _():
    out = []
    # a smooth tilted planet ring (glows)
    tilt, roll = math.radians(20), math.radians(14)
    m = Mesh("Ring")
    S2, P2 = 72, 10
    prof = [(math.cos(a * TAU / P2) * 0.2, math.sin(a * TAU / P2) * 0.045) for a in range(P2)]
    def place(q):
        q = Vector((q.x, q.y * math.cos(tilt) - q.z * math.sin(tilt), q.y * math.sin(tilt) + q.z * math.cos(tilt)))
        return Vector((q.x * math.cos(roll) + q.z * math.sin(roll), q.y, -q.x * math.sin(roll) + q.z * math.cos(roll) + 1.95))
    rings, centres = [], []
    for i in range(S2):
        a = i * TAU / S2
        radial = Vector((math.sin(a), math.cos(a), 0))
        rings.append([m.vert(place(radial * (2.12 + x) + Vector((0, 0, y)))) for x, y in prof])
        centres.append(place(radial * 2.12))
    for i in range(S2):
        i1 = (i + 1) % S2
        for k in range(P2):
            k1 = (k + 1) % P2
            q = [(rings[i][k], None, (0.5, 0.5)), (rings[i1][k], None, (0.5, 0.5)), (rings[i1][k1], None, (0.5, 0.5)), (rings[i][k1], None, (0.5, 0.5))]
            m.quad(*q, expect=(m.v[rings[i][k]] - centres[i]))
    out.append(("Ring", m, (110, 235, 255), "neon"))
    return out


# ------------------------------------------------------------------ painting (numpy, per pixel, from 3D points)
Y, X = np.mgrid[0:TEX, 0:TEX].astype(np.float64)
VV = (Y + 0.5) / TEX
UU = (X + 0.5) / TEX
OUTSIDE = VV <= V_OUT
TT = np.pi * (1 - np.clip(VV / V_OUT, 0, 1))
TH = UU * TAU
RR = W / 2 * np.sin(TT) * (1 + K * np.cos(TT))
PX = RR * np.sin(TH)
PY = RR * np.cos(TH)
PZ = H / 2 * (1 - np.cos(TT))
SS = TH * 0  # arc length from the front, along the shell (signed): theta wrapped to -pi..pi times r
THW = np.arctan2(np.sin(TH), np.cos(TH))
SS = THW * RR

_rng = np.random.default_rng(3)
_LAT = _rng.random((48, 48, 48))


def vnoise(x, y, z, f=1.0, seed=0):
    x = x * f + seed * 7.13 + 100
    y = y * f + seed * 3.71 + 100
    z = z * f + seed * 5.37 + 100
    xi, yi, zi = np.floor(x).astype(int), np.floor(y).astype(int), np.floor(z).astype(int)
    xf, yf, zf = x - xi, y - yi, z - zi
    u, v, w = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf), zf * zf * (3 - 2 * zf)
    def L(a, b, c):
        return _LAT[a % 48, b % 48, c % 48]
    c00 = L(xi, yi, zi) * (1 - u) + L(xi + 1, yi, zi) * u
    c10 = L(xi, yi + 1, zi) * (1 - u) + L(xi + 1, yi + 1, zi) * u
    c01 = L(xi, yi, zi + 1) * (1 - u) + L(xi + 1, yi, zi + 1) * u
    c11 = L(xi, yi + 1, zi + 1) * (1 - u) + L(xi + 1, yi + 1, zi + 1) * u
    return (c00 * (1 - v) + c10 * v) * (1 - w) + (c01 * (1 - v) + c11 * v) * w


def fbm(f=1.0, oct=4, seed=0):
    s, a, tot = 0, 1.0, 0
    for o in range(oct):
        s = s + vnoise(PX, PY, PZ, f * 2 ** o, seed + o) * a
        tot += a
        a *= 0.5
    return s / tot


def col(*c):
    return np.array(c, dtype=np.float64) / 255.0


def fill(c):
    img = np.zeros((TEX, TEX, 3))
    img[:] = col(*c) if not isinstance(c, np.ndarray) else c
    return img


def over(img, mask, c, alpha=1.0):
    m = np.clip(mask, 0, 1)[..., None] * alpha
    cc = col(*c) if not isinstance(c, np.ndarray) else c
    img[:] = img * (1 - m) + cc * m


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


AA = 0.02  # anti-aliasing width in studs


def ellipse(cs, cz, rs, rz):
    d = np.sqrt(((SS - cs) / rs) ** 2 + ((PZ - cz) / rz) ** 2)
    return 1 - ss(1 - AA / min(rs, rz), 1 + AA / min(rs, rz), d)


def front():
    return np.cos(TH) > 0  # (s is only meaningful on the front half)


def shade(img, lo=0.8, hi=1.06):
    k = lo + (hi - lo) * ss(0.0, H, PZ)
    img[:] = np.clip(img * k[..., None], 0, 1)


def rrect_sdf(cs, cz, hw, hh, r):
    qx = np.abs(SS - cs) - hw + r
    qz = np.abs(PZ - cz) - hh + r
    return np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qz, 0) ** 2) + np.minimum(np.maximum(qx, qz), 0) - r


def line_mask(dist, w):
    return 1 - ss(w / 2 - AA / 2, w / 2 + AA / 2, np.abs(dist))


PAINT = {}


def paint(name):
    def deco(fn):
        PAINT[name] = fn
        return fn
    return deco


CREAM = (250, 236, 205)


@paint("Briefcase")
def _():
    img = fill((202, 134, 70))
    grain = fbm(7, 4, 1)
    img *= (0.94 + 0.12 * grain)[..., None]
    blotch = ss(0.62, 0.7, fbm(2.2, 3, 2))
    over(img, blotch, (226, 160, 96), 0.55)
    fr = front()
    # front panel: groove + stitches
    sdf = rrect_sdf(0, 2.0, 1.05, 1.35, 0.32)
    over(img, line_mask(sdf, 0.07) * fr, (128, 76, 36))
    dash = (np.mod((SS + PZ) / 0.17, 1.0) < 0.55)
    over(img, line_mask(sdf + 0.13, 0.045) * dash * fr, CREAM)
    over(img, ss(0.0, -0.4, sdf) * fr, (214, 146, 80), 0.35)
    # side seams
    for c in (math.pi / 2, -math.pi / 2):
        d = np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR
        over(img, line_mask(d, 0.06), (128, 76, 36))
        over(img, line_mask(np.abs(d) - 0.12, 0.04) * (np.mod(PZ / 0.17, 1) < 0.55), CREAM)
    # brass corners near the bottom (painted, flush)
    for c in (0.9, 2.25, -0.9, -2.25):
        d = np.sqrt((np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR / 0.32) ** 2 + ((PZ - 0.55) / 0.26) ** 2)
        over(img, 1 - ss(0.95, 1.05, d), (240, 190, 70))
        over(img, (1 - ss(0.95, 1.05, d)) * ss(0.2, 0.8, (PZ - 0.45) / 0.3), (255, 228, 140), 0.5)
    # the belt (the relief layer wears this): dark leather, stitched edges, a highlight
    belt = (PZ > 1.48) & (PZ < 2.0)
    bimg = fill((112, 63, 31)) * (0.92 + 0.15 * grain)[..., None]
    over(bimg, line_mask(PZ - 1.58, 0.035) * (np.mod(SS / 0.15, 1) < 0.55), CREAM)
    over(bimg, line_mask(PZ - 1.9, 0.035) * (np.mod(SS / 0.15, 1) < 0.55), CREAM)
    over(bimg, ss(1.94, 1.99, PZ), (150, 90, 50), 0.8)
    img[belt] = bimg[belt]
    shade(img)
    return img


@paint("Pet")
def _():
    img = fill((255, 239, 218))
    fr_area = front() & (np.abs(SS) < 0.95) & (PZ > 1.4) & (PZ < 3.2)
    p1 = ss(0.58, 0.62, fbm(1.3, 3, 4))
    p1 = p1 * (1 - fr_area)
    over(img, p1, (233, 152, 80))
    p2 = ss(0.66, 0.7, fbm(2.4, 3, 9)) * (1 - fr_area)
    over(img, p2, (120, 78, 48))
    fr = front()
    pink, dark = (255, 146, 172), (226, 104, 136)
    pad = ellipse(0, 2.02, 0.42, 0.34) * fr
    over(img, ellipse(0, 2.02, 0.47, 0.39) * fr, dark)
    over(img, pad, pink)
    for cs, cz in ((-0.5, 2.6), (-0.18, 2.84), (0.18, 2.84), (0.5, 2.6)):
        over(img, ellipse(cs, cz, 0.18, 0.21) * fr, dark)
        over(img, ellipse(cs, cz, 0.14, 0.17) * fr, pink)
        over(img, ellipse(cs - 0.04, cz + 0.06, 0.04, 0.05) * fr, (255, 210, 222))
    over(img, ellipse(-0.12, 2.14, 0.12, 0.08) * fr, (255, 205, 218))
    # collar (relief): red with a light top edge and painted gold studs
    collar = (PZ > 0.76) & (PZ < 1.14)
    cimg = fill((222, 40, 52))
    over(cimg, ss(1.05, 1.1, PZ), (250, 110, 110))
    over(cimg, 1 - ss(0.8, 0.84, PZ), (160, 20, 35), 0.6)
    stud = np.zeros_like(PZ)
    for i in range(12):
        c = i * TAU / 12 + 0.26
        d = np.sqrt((np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR / 0.06) ** 2 + ((PZ - 0.95) / 0.06) ** 2)
        stud = np.maximum(stud, 1 - ss(0.85, 1.15, d))
    over(cimg, stud, (255, 210, 70))
    img[collar] = cimg[collar]
    shade(img)
    return img


@paint("Brainrot")
def _():
    top, bot = col(178, 112, 248), col(104, 48, 186)
    k = ss(0.2, H, PZ)[..., None]
    img = bot * (1 - k) + top * k
    fr = front()
    blobs = ss(0.6, 0.63, fbm(1.8, 3, 12)) * (1 - (fr & (np.abs(SS) < 1.0) & (PZ > 1.3)))
    over(img, blobs, (255, 92, 205))
    over(img, ss(0.68, 0.7, fbm(1.8, 3, 12)) * (1 - (fr & (np.abs(SS) < 1.0) & (PZ > 1.3))), (255, 170, 230), 0.6)
    # a lime zigzag band low down
    zz = 0.75 + 0.12 * (4 * np.abs(np.mod(TH / TAU * 10, 1) - 0.5) - 1)
    over(img, line_mask(PZ - zz, 0.2), (40, 20, 60))
    over(img, line_mask(PZ - zz, 0.13), (160, 255, 90))
    # the face: big eyes looking two ways, a goofy grin
    for cs, ps, pz in ((-0.5, -0.62, 2.72), (0.5, 0.58, 2.4)):
        over(img, ellipse(cs, 2.55, 0.38, 0.44) * fr, (35, 15, 55))
        over(img, ellipse(cs, 2.55, 0.33, 0.39) * fr, (255, 255, 255))
        over(img, ellipse(ps, pz, 0.15, 0.17) * fr, (30, 15, 45))
        over(img, ellipse(ps - 0.05, pz + 0.07, 0.05, 0.055) * fr, (255, 255, 255))
    mouth = ellipse(0, 1.86, 0.62, 0.36) * (1 - ellipse(0, 2.02, 0.7, 0.34)) * fr
    over(img, mouth, (55, 18, 60))
    over(img, ellipse(0.12, 1.6, 0.2, 0.12) * mouth, (255, 120, 150))
    over(img, (1 - ss(0.0, 0.02, np.abs(SS + 0.18) - 0.09)) * (PZ > 1.68) * (PZ < 1.8) * fr * mouth, (255, 255, 255))
    shade(img, 0.85, 1.05)
    return img


@paint("Food")
def _():
    img = fill((232, 172, 92))
    g1 = np.mod((SS + PZ) / 0.42, 1.0)
    g2 = np.mod((SS - PZ) / 0.42, 1.0)
    groove = np.maximum(line_mask(g1 - 0.5, 0.12), line_mask(g2 - 0.5, 0.12))
    over(img, groove, (186, 120, 52))
    hl = np.maximum(line_mask(g1 - 0.62, 0.08), line_mask(g2 - 0.62, 0.08))
    over(img, hl * (1 - groove), (248, 200, 125), 0.6)
    # the frosting (relief): pink with sprinkles (3D cells, so they don't stretch near the top)
    frost_mask = PZ > 1.6
    fimg = fill((255, 152, 198))
    over(fimg, ss(0.55, 0.75, fbm(3, 3, 21)), (255, 178, 214), 0.5)
    cell = 0.34
    cx, cy, cz = np.floor(PX / cell), np.floor(PY / cell), np.floor(PZ / cell)
    h = (cx * 73856093 + cy * 19349663 + cz * 83492791).astype(np.int64)
    rng = lambda s: ((np.abs(h * (s * 2654435761 + 1)) % 10007) / 10007.0)
    ox, oy, oz = (cx + 0.3 + 0.4 * rng(1)) * cell, (cy + 0.3 + 0.4 * rng(2)) * cell, (cz + 0.3 + 0.4 * rng(3)) * cell
    ang = rng(4) * math.pi
    dx, dy, dz = PX - ox, PY - oy, PZ - oz
    along = dx * np.cos(ang) + dz * np.sin(ang) * 0.7 + dy * np.sin(ang) * 0.7
    dist2 = dx * dx + dy * dy + dz * dz - along * along
    seg = np.clip(np.abs(along) - 0.09, 0, None)
    d = np.sqrt(np.maximum(dist2, 0) + seg * seg)
    spr = 1 - ss(0.035, 0.05, d)
    pal = np.array([col(255, 228, 60), col(90, 205, 255), col(140, 240, 92), col(255, 255, 255), col(182, 112, 255)])
    pick = pal[(rng(5) * 5).astype(int) % 5]
    keep = rng(6) > 0.25
    m = (spr * keep)[..., None]
    fimg = fimg * (1 - m) + pick * m
    img[frost_mask] = fimg[frost_mask]
    shade(img)
    return img


@paint("Ocean")
def _():
    deep, mid, sky = col(22, 80, 168), col(40, 138, 214), col(134, 214, 255)
    k1 = ss(0.0, 1.9, PZ)[..., None]
    k2 = ss(1.9, 3.6, PZ)[..., None]
    img = deep * (1 - k1) + mid * k1
    img = img * (1 - k2) + sky * k2
    caust = np.abs(np.sin(PX * 5 + fbm(2, 2, 30) * 6) * np.sin(PY * 5 + PZ * 3))
    over(img, (caust > 0.9) * (PZ < 1.7), (90, 175, 235), 0.5)
    # foam wave (relief)
    lo = 1.62 + 0.14 * np.sin(TH * 5)
    hi = 2.02 + 0.14 * np.sin(TH * 5 + 0.6)
    band = (PZ > lo - 0.02) & (PZ < hi + 0.02)
    wimg = fill((246, 252, 255))
    over(wimg, line_mask(PZ - (lo + 0.12), 0.05), (150, 210, 245))
    over(wimg, ss(hi - 0.08, hi, PZ), (205, 236, 255), 0.7)
    img[band] = wimg[band]
    # a starfish (flush) on the front, low
    fr = front()
    ang = np.arctan2(PZ - 0.95, SS - 0.35)
    rad = np.sqrt((SS - 0.35) ** 2 + (PZ - 0.95) ** 2)
    star_r = 0.17 + 0.17 * (0.5 + 0.5 * np.cos(5 * (ang - 0.3)))
    over(img, (1 - ss(star_r, star_r + 0.03, rad)) * fr, (255, 132, 84))
    over(img, (1 - ss(star_r * 0.55, star_r * 0.55 + 0.03, rad)) * fr, (255, 172, 120))
    # bubbles (flush rings with a highlight)
    for c, cz, r in ((0.9, 2.75, 0.17), (1.15, 3.15, 0.11), (-0.8, 2.55, 0.14), (-1.3, 3.05, 0.09), (2.4, 2.6, 0.13), (-2.6, 2.9, 0.12)):
        d = np.sqrt((np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR) ** 2 + (PZ - cz) ** 2)
        over(img, line_mask(d - r, 0.035), (235, 250, 255), 0.85)
        dd = np.sqrt((np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR + r * 0.4) ** 2 + (PZ - cz - r * 0.4) ** 2)
        over(img, 1 - ss(r * 0.18, r * 0.25, dd), (255, 255, 255))
    shade(img, 0.85, 1.05)
    return img


@paint("Space")
def _():
    img = fill((28, 22, 78))
    over(img, ss(0.2, H, PZ), (46, 36, 120), 0.8)
    n1 = fbm(1.4, 5, 40)
    n2 = fbm(1.9, 5, 50)
    over(img, ss(0.5, 0.75, n1), (190, 80, 255), 0.75)
    over(img, ss(0.55, 0.8, n2), (60, 200, 255), 0.6)
    over(img, ss(0.68, 0.85, n1), (255, 150, 240), 0.5)
    # stars: hashed 3D cells; bigger ones get a 4-point sparkle
    cell = 0.28
    cx, cy, cz = np.floor(PX / cell), np.floor(PY / cell), np.floor(PZ / cell)
    h = (cx * 73856093 + cy * 19349663 + cz * 83492791).astype(np.int64)
    rng = lambda s: ((np.abs(h * (s * 2654435761 + 1)) % 10007) / 10007.0)
    ox, oy, oz = (cx + 0.25 + 0.5 * rng(1)) * cell, (cy + 0.25 + 0.5 * rng(2)) * cell, (cz + 0.25 + 0.5 * rng(3)) * cell
    d = np.sqrt((PX - ox) ** 2 + (PY - oy) ** 2 + (PZ - oz) ** 2)
    big = rng(4) > 0.85
    r = np.where(big, 0.045, 0.022)
    starm = (1 - ss(r * 0.6, r, d)) * (rng(5) > 0.35)
    over(img, starm, (255, 250, 210))
    spark = big * (rng(5) > 0.35) * np.maximum(
        (1 - ss(0.004, 0.012, np.abs(PZ - oz))) * (1 - ss(0.02, 0.11, np.abs(np.sqrt((PX - ox) ** 2 + (PY - oy) ** 2)))),
        (1 - ss(0.004, 0.012, np.sqrt((PX - ox) ** 2 + (PY - oy) ** 2))) * (1 - ss(0.02, 0.11, np.abs(PZ - oz))))
    over(img, spark, (255, 255, 235))
    # a little painted planet on the back
    c = math.pi
    dd = np.sqrt((np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR) ** 2 + (PZ - 2.6) ** 2)
    over(img, 1 - ss(0.3, 0.33, dd), (255, 150, 90))
    over(img, (1 - ss(0.3, 0.33, dd)) * ss(2.5, 2.9, PZ), (255, 200, 140), 0.6)
    return img


def goldify(img):
    lum = img @ np.array([0.3, 0.59, 0.11])
    lo, midc, hi = col(150, 92, 12), col(255, 196, 40), col(255, 246, 190)
    k = lum[..., None]
    g = np.where(k < 0.5, lo + (midc - lo) * (k / 0.5), midc + (hi - midc) * ((k - 0.5) / 0.5))
    g = g * 0.55 + col(255, 200, 45) * 0.45
    # a Faberge lattice and a jewelled band, all flush
    a = np.mod(TH / TAU * 12 + PZ * 0.9, 1.0)
    b = np.mod(TH / TAU * 12 - PZ * 0.9, 1.0)
    lat = np.maximum(line_mask(a - 0.5, 0.06 / max(1e-3, 1)), line_mask(b - 0.5, 0.06))
    over(g, lat * (PZ > 0.25) * (PZ < 3.55), (255, 248, 200))
    over(g, line_mask(PZ - 1.74, 0.3), (250, 250, 255))
    gem = np.zeros_like(PZ)
    gems = [col(70, 210, 255), col(255, 80, 190), col(120, 255, 140)]
    for i in range(12):
        c = i * TAU / 12
        dth = np.arctan2(np.sin(TH - c), np.cos(TH - c)) * RR
        dia = np.abs(dth) / 0.13 + np.abs(PZ - 1.74) / 0.13
        m = 1 - ss(0.9, 1.1, dia)
        cc = gems[i % 3]
        g = g * (1 - m[..., None]) + cc * m[..., None]
        hl = 1 - ss(0.2, 0.45, np.abs(dth + 0.04) / 0.13 + np.abs(PZ - 1.78) / 0.13)
        g = g * (1 - (hl * m)[..., None] * 0.7) + col(255, 255, 255) * (hl * m)[..., None] * 0.7
    shade(g, 0.86, 1.04)
    return np.clip(g, 0, 1)


def inside(img, c=(255, 250, 238)):
    img[~OUTSIDE] = col(*c)


def save_png(img, path):
    name = os.path.basename(path)
    im = bpy.data.images.get(name)
    if im:
        bpy.data.images.remove(im)
    im = bpy.data.images.new(name, TEX, TEX, alpha=False)
    rgba = np.ones((TEX, TEX, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(img, 0, 1)
    rgba = rgba[::-1]  # Blender stores the bottom row first
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = path
    im.file_format = "PNG"
    im.save()
    return im


# ------------------------------------------------------------------ export
def to_rbx(v):
    return (v.x, v.z, -v.y)


def export_mesh(m, path):
    vs, ns, uvs, fs = [], [], [], []
    nidx, uidx = {}, {}
    for p in m.v:
        r = to_rbx(p)
        vs.extend(round(c, 4) for c in r)
    for fa in m.f:
        for vi, n, uv in fa:
            if n is None:
                n = Vector((0, 0, 1))
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
    return dict(file=os.path.basename(path), tris=len(m.f), lo=lo, hi=hi)


def smooth_normals(m):
    """For pieces built with normal=None: average face normals per vertex."""
    acc = [Vector() for _ in m.v]
    for fa in m.f:
        a, b, c = (m.v[x[0]] for x in fa)
        g = (b - a).cross(c - a)
        for x in fa:
            acc[x[0]] += g
    out = Mesh(m.name)
    out.v = m.v
    out.f = [tuple((vi, (n if n is not None else acc[vi].normalized()), uv) for vi, n, uv in fa) for fa in m.f]
    return out


manifest = dict(height=H, width=W, belt=BELT_Z, meshes={}, eggs={}, chunks=[], cracks=[])
shell = make_shell(48, 32)
manifest["meshes"]["Shell"] = export_mesh(shell, os.path.join(OUT, "Shell.json"))
hshell = make_shell(HS, HR)
manifest["meshes"]["HatchShell"] = export_mesh(hshell, os.path.join(OUT, "HatchShell.json"))
chunks, cracks = make_chunks()
for cm in chunks:
    info = export_mesh(cm, os.path.join(OUT, cm.name + ".json"))
    info["top"] = cm.top
    manifest["meshes"][cm.name] = info
    manifest["chunks"].append(cm.name)
for cr in cracks:
    manifest["meshes"][cr.name] = export_mesh(cr, os.path.join(OUT, cr.name + ".json"))
    manifest["cracks"].append(cr.name)

previews = {}
for egg, fn in DECOR.items():
    pieces = []
    for pname, pm, rgb, mat in fn():
        pm = smooth_normals(pm)
        key = f"{egg}_{pname}"
        n = 2
        while key in manifest["meshes"]:
            key = f"{egg}_{pname}{n}"
            n += 1
        manifest["meshes"][key] = export_mesh(pm, os.path.join(OUT, key + ".json"))
        pieces.append(dict(mesh=key, name=pname, rgb=rgb, mat=mat))
        previews.setdefault(egg, []).append((pm, rgb, mat))
    manifest["eggs"][egg] = dict(pieces=pieces)
for egg, fn in PAINT.items():
    img = fn()
    inside(img)
    save_png(img, os.path.join(OUT, f"{egg}.png"))
    g = goldify(img.copy())
    inside(g, (255, 244, 205))
    save_png(g, os.path.join(OUT, f"{egg}_Golden.png"))
    manifest["eggs"].setdefault(egg, dict(pieces=[]))
    manifest["eggs"][egg]["texture"] = f"{egg}.png"
    manifest["eggs"][egg]["golden"] = f"{egg}_Golden.png"
with open(os.path.join(OUT, "manifest.json"), "w") as fh:
    json.dump(manifest, fh, indent=1)

# ------------------------------------------------------------------ preview (EEVEE): the six eggs + golden + a cracked one
sc = bpy.data.scenes.get("EggsV5") or bpy.data.scenes.new("EggsV5")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)


def to_object(m, name, loc, mat):
    me = bpy.data.meshes.new(name)
    verts = [tuple(v) for v in m.v]
    faces = [tuple(c[0] for c in fa) for fa in m.f]
    me.from_pydata(verts, [], faces)
    uvl = me.uv_layers.new(name="UV")
    li = 0
    for fi, fa in enumerate(m.f):
        for c in fa:
            uvl.data[li].uv = (c[2][0], 1 - c[2][1])
            li += 1
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(mat)
    o = bpy.data.objects.new(name, me)
    o.location = loc
    sc.collection.objects.link(o)
    return o


def tex_mat(path):
    name = "M_" + os.path.basename(path)
    mt = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mt.use_nodes = True
    nt = mt.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bs = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tx = nt.nodes.new("ShaderNodeTexImage")
    tx.image = bpy.data.images.load(path, check_existing=False)
    nt.links.new(tx.outputs["Color"], bs.inputs["Base Color"])
    bs.inputs["Roughness"].default_value = 0.45
    nt.links.new(bs.outputs["BSDF"], out.inputs["Surface"])
    return mt


def col_mat(rgb, mat):
    name = f"MC_{rgb}_{mat}"
    mt = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mt.use_nodes = True
    bs = mt.node_tree.nodes.get("Principled BSDF")
    c = tuple((x / 255) ** 2.2 for x in rgb) + (1,)
    bs.inputs["Base Color"].default_value = c
    bs.inputs["Roughness"].default_value = 0.35 if mat == "metal" else 0.5
    if mat == "metal":
        bs.inputs["Metallic"].default_value = 0.8
    if mat == "neon":
        bs.inputs["Emission Color"].default_value = c
        bs.inputs["Emission Strength"].default_value = 3.0
    return mt


order = ["Briefcase", "Pet", "Brainrot", "Food", "Ocean", "Space"]
for i, egg in enumerate(order):
    for row, golden in ((0, False), (1, True)):
        loc = Vector((i * 5.2, -row * 6.5, 0))
        tm = tex_mat(os.path.join(OUT, f"{egg}{'_Golden' if golden else ''}.png"))
        to_object(shell if not golden else shell, f"{egg}_shell_{row}", loc, tm)
        for pm, rgb, mat in previews.get(egg, []):
            if mat == "tex":
                to_object(pm, f"{egg}_relief_{row}", loc, tm)
            else:
                c = rgb
                if golden and mat != "neon":
                    c = tuple(int(a + (b - a) * 0.5) for a, b in zip(rgb, (255, 232, 150)))
                to_object(pm, f"{egg}_{pm.name}_{row}", loc, col_mat(c, mat))
# a cracked hatch egg, chunks pulled apart a little, with its cracks
loc = Vector((-6.5, 0, 0))
tm = tex_mat(os.path.join(OUT, "Brainrot.png"))
for cm in chunks:
    c = sum((cm.v[i] for i in range(len(cm.v))), Vector()) / len(cm.v)
    off = Vector((c.x, c.y, c.z - 1.9)).normalized() * 0.35
    to_object(cm, cm.name, loc + Vector((-6, 0, 0)) + off, tm)
for i, cr in enumerate(cracks):
    to_object(cr, cr.name, loc, col_mat((255, 255, 255), "neon"))
    to_object(hshell, "HatchShell", loc, tm) if i == 0 else None

cam_data = bpy.data.cameras.get("V5_Cam") or bpy.data.cameras.new("V5_Cam")
cam = bpy.data.objects.new("V5_Cam", cam_data)
sc.collection.objects.link(cam)
target = Vector((6.5, -2.5, 2.0))
cam.location = (6.5, 34, 14)
cam.rotation_euler = (target - Vector(cam.location)).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 30
sc.camera = cam
sun_d = bpy.data.lights.get("V5_Sun") or bpy.data.lights.new("V5_Sun", "SUN")
sun_d.energy = 3.5
sun = bpy.data.objects.new("V5_Sun", sun_d)
sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.get("V5_World") or bpy.data.worlds.new("V5_World")
sc.world.use_nodes = True
bg = sc.world.node_tree.nodes.get("Background")
bg.inputs["Color"].default_value = (0.22, 0.22, 0.26, 1)
bg.inputs["Strength"].default_value = 1.0
for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        sc.render.engine = eng
        break
    except TypeError:
        pass
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x, sc.render.resolution_y = 2000, 900
sc.render.filepath = PREVIEW
os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print("eggs v5:", len(manifest["meshes"]), "meshes;", ", ".join(f"{k} {v['tris']}" for k, v in manifest["meshes"].items()))
