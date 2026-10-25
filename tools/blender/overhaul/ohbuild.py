# tools/blender/overhaul/ohbuild.py - the MAP MODEL OVERHAUL's architecture kit (hub buildings, firm stages): framed
# windows (arched / square, glass with a cartoon shine), panelled double doors with a fanlight, classical columns, hip
# roofs with standing seams and a gold ridge, pediments, balustrades, corner quoins, flags, and the StudTop preview.
# Everything builds in the current ohkit frame (O.at). A wall piece's outward face is local -Y at y = 0; turn it with
# O.at(rz=...) for other walls: +X wall rz=90, -X wall rz=-90, back (+Y) wall rz=180. Names: <prefix>_<Part> per colour, like the rest of the overhaul.
import math
from mathutils import Vector
import ohkit as O
from ohkit import box, cyl, lathe, sphere, tube, prism, poly

TAU = math.tau


# ------------------------------------------------------------------ outlines
def opening(w, h, arch=True, n=10, grow=0.0):
    """An opening's outline [(x, z)] from the bottom-left, counter-clockwise seen from the front: a rectangle, or one
    whose top is a half circle (the same point count either way, so two outlines can be joined into a frame ring).
    grow widens it on the sides and top (a frame's outer edge)."""
    hw = w / 2 + grow
    if arch:
        spring = h - w / 2
        pts = [(-hw, -grow * 0.5), (hw, -grow * 0.5), (hw, spring)]
        pts += [(hw * math.cos(math.pi * i / n), spring + hw * math.sin(math.pi * i / n)) for i in range(1, n)]
        pts += [(-hw, spring)]
    else:
        top = h + grow
        pts = [(-hw, -grow * 0.5), (hw, -grow * 0.5), (hw, top - 0.001)]
        pts += [(hw - 2 * hw * i / n, top) for i in range(1, n)]
        pts += [(-hw, top - 0.001)]
    return pts


def ring(name, look, outer, inner, y0, y1):
    """A frame between two outlines with the same point count, from y0 (front) to y1 (back)."""
    import bmesh
    tmp = bmesh.new()
    of = [tmp.verts.new((x, y0, z)) for x, z in outer]
    inf = [tmp.verts.new((x, y0, z)) for x, z in inner]
    ob = [tmp.verts.new((x, y1, z)) for x, z in outer]
    ib = [tmp.verts.new((x, y1, z)) for x, z in inner]
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        tmp.faces.new((of[i], of[j], inf[j], inf[i]))
        tmp.faces.new((ib[i], ib[j], ob[j], ob[i]))
        tmp.faces.new((ob[i], ob[j], of[j], of[i]))
        tmp.faces.new((inf[i], inf[j], ib[j], ib[i]))
    for f in tmp.faces:
        f.smooth = False
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces[:])
    O._merge(name, look, tmp, O.Matrix.Identity(4))


# ------------------------------------------------------------------ windows + doors
def window(p, x, z, w, h, arch=True, frame="white", glass="glass_blue", sill="marble", keystone="marble_shade",
           mullions=True, shutters=None, depth=0.3):
    """A framed window on the wall at local y = 0 (outward -Y): frame ring, recessed glass + shine, cross mullions,
    sill, keystone (arched) and optional shutters. (x, z) = the bottom centre."""
    fw = max(0.32, w * 0.12)
    with O.at(x, 0, z):
        ring(p + "_Frame", frame, opening(w, h, arch, grow=fw), opening(w, h, arch), -depth, 0.05)
        prism(p + "_Glass", glass, opening(w, h, arch), 0.1, c=(0, -0.08, 0))
        sh = min(w, h) * 0.18  # a cartoon shine: two slanted streaks
        for k, (ox, ln) in enumerate(((-w * 0.18, 0.55), (-w * 0.02, 0.3))):
            cx, cz = ox, h * 0.62 - k * 0.15 * h
            poly(p + "_Shine", "white", [(cx - sh * 0.35, -0.14, cz - h * 0.12 * ln), (cx - sh * 0.1, -0.14, cz - h * 0.12 * ln),
                                         (cx + sh * 0.65, -0.14, cz + h * 0.12 * ln), (cx + sh * 0.4, -0.14, cz + h * 0.12 * ln)])
        if mullions:
            top = h - (w / 2 if arch else 0) * 0.0
            box(p + "_Frame", frame, (0, -0.16, top / 2), (0.16, 0.12, top))
            box(p + "_Frame", frame, (0, -0.16, (h - w / 2) if arch else h * 0.55), (w, 0.12, 0.16))
        if sill:
            box(p + "_Sill", sill, (0, -depth - 0.12, -fw * 0.5 - 0.12), (w + fw * 2 + 0.5, 0.6, 0.26), bevel=0.06)
        if arch and keystone:
            kz = h + fw * 0.5
            prism(p + "_Key", keystone, [(-0.32, kz - 0.5), (0.32, kz - 0.5), (0.45, kz + 0.45), (-0.45, kz + 0.45)], depth + 0.14,
                  c=(0, -(depth + 0.14) / 2 + 0.05, 0))
        if shutters:
            for s in (-1, 1):
                sx = s * (w / 2 + fw + 0.55 * w / 2)
                sh_h = (h - w / 2 * 0.6) if arch else h
                box(p + "_Shutter", shutters, (sx, -0.12, sh_h / 2), (w * 0.52, 0.18, sh_h), bevel=0.04)
                for zz in [sh_h * (i + 1) / 7 for i in range(6)]:
                    box(p + "_Shutter", shutters, (sx, -0.22, zz), (w * 0.44, 0.08, 0.12), rot=(12, 0, 0))


def door(p, x, z, w, h, frame="gold", leaf="wood_deep", panel="wood_warm", glass="glass_blue", handle="gold", depth=0.5):
    """An arched double door: frame ring, two panelled leaves, gold handles, a fanlight with radiating glazing bars."""
    fw = max(0.4, w * 0.09)
    spring = h - w / 2
    with O.at(x, 0, z):
        ring(p + "_DoorFrame", frame, opening(w, h, True, grow=fw), opening(w, h, True), -depth, 0.05)
        for s in (-1, 1):
            cx = s * w / 4
            box(p + "_Leaf", leaf, (cx, -0.12, spring / 2), (w / 2 - 0.06, 0.2, spring), bevel=0.04)
            for zz, hh in ((spring * 0.27, spring * 0.36), (spring * 0.72, spring * 0.42)):
                box(p + "_Panel", panel, (cx, -0.24, zz), (w / 2 - 0.7, 0.08, hh), bevel=0.05)
            sphere(p + "_Handle", handle, (s * 0.32, -0.36, spring * 0.5), 0.17, sub=1)
            box(p + "_Handle", handle, (s * 0.32, -0.24, spring * 0.5), (0.26, 0.1, 0.6), bevel=0.04)
        fan = [(w / 2 * math.cos(math.pi * i / 12), spring + w / 2 * math.sin(math.pi * i / 12)) for i in range(13)]
        prism(p + "_Glass", glass, [(w / 2, spring)] + fan[1:-1] + [(-w / 2, spring)], 0.1, c=(0, -0.1, 0))
        box(p + "_DoorFrame", frame, (0, -0.2, spring), (w, 0.2, 0.22))
        for i in range(1, 6):
            a = math.pi * i / 6
            tube(p + "_DoorFrame", frame, [(0, -0.18, spring), (w / 2 * 0.95 * math.cos(a), -0.18, spring + w / 2 * 0.95 * math.sin(a))],
                 0.07, segs=4)
        box(p + "_Step", "marble", (0, -depth - 0.6, -0.12), (w + fw * 2 + 0.6, 1.4, 0.24), bevel=0.05)


# ------------------------------------------------------------------ columns, cornices, quoins, balustrades
def column(p, x, y, z, h, r=1.0, look="marble", trim="gold"):
    """A Tuscan column (square plinth, torus base, swelling shaft, gold necking ring, echinus, square abacus)."""
    with O.at(x, y, z):
        box(p + "_Column", look, (0, 0, 0.25), (r * 2.5, r * 2.5, 0.5), bevel=0.06)
        lathe(p + "_Column", look, [(r * 1.18, 0.5, True), (r * 1.22, 0.62), (r * 1.18, 0.8), (r * 1.05, 0.92, True),
                                    (r * 1.0, 1.0), (r * 1.02, h * 0.33), (r * 0.9, h - 1.3), (r * 0.9, h - 1.1, True)], segs=20)
        cyl(p + "_Trim", trim, (0, 0, h - 1.1), r * 0.98, 0.22, segs=20)
        lathe(p + "_Column", look, [(r * 0.9, h - 0.88, True), (r * 1.05, h - 0.72), (r * 1.22, h - 0.5, True), (0.0, h - 0.5)],
              segs=20)
        box(p + "_Column", look, (0, 0, h - 0.25), (r * 2.6, r * 2.6, 0.5), bevel=0.06)


def quoins(p, x, y, z0, z1, look="stone_mid", dir=(1, 1), size=1.0):
    """Alternating corner stones up a building corner at (x, y); dir = which way the two faces point (+/-1, +/-1)."""
    k, z = 0, z0
    while z + size * 0.9 < z1:
        long = k % 2 == 0
        lx, ly = (1.8 if long else 1.1) * size, (1.1 if long else 1.8) * size
        box(p + "_Quoin", look, (x - dir[0] * (lx / 2 - 0.12), y - dir[1] * (ly / 2 - 0.12), z + size * 0.45),
            (lx, ly, size * 0.86), bevel=0.06)
        z += size
        k += 1


def balustrade(p, x0, y0, x1, y1, z, h=1.6, look="marble", rail=None, every=0.9, posts=6.0):
    """A run of turned balusters between a base and a hand rail, with square posts every `posts` studs."""
    rail = rail or look
    L = math.hypot(x1 - x0, y1 - y0)
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    with O.at((x0 + x1) / 2, (y0 + y1) / 2, z, rz=ang):
        box(p + "_Rail", rail, (0, 0, 0.12), (L, 0.7, 0.24), bevel=0.04)
        box(p + "_Rail", rail, (0, 0, h - 0.13), (L + 0.2, 0.8, 0.26), bevel=0.06)
        n = max(1, int(L / every))
        for i in range(n):
            x = -L / 2 + (i + 0.5) * L / n
            lathe(p + "_Baluster", look, [(0.22, 0.24, True), (0.15, 0.5), (0.27, 0.82), (0.15, h - 0.45), (0.22, h - 0.26, True)],
                  segs=6, c=(x, 0, 0))
        m = max(1, int(L / posts))
        for i in range(m + 1):
            x = -L / 2 + i * L / m
            box(p + "_Rail", rail, (x, 0, h / 2), (0.6, 0.6, h), bevel=0.05)
            box(p + "_Rail", rail, (x, 0, h + 0.1), (0.75, 0.75, 0.2), bevel=0.05)


def cornice(p, x, y, z, sx, sy, look="marble", trim=None, depth=0.8):
    """A stepped cornice band around a block's top (three stacked chamfered slabs, the middle one a gold fillet)."""
    box(p + "_Cornice", look, (x, y, z + 0.2), (sx + 0.3, sy + 0.3, 0.4), bevel=0.06)
    box(p + "_" + ("Trim" if trim else "Cornice"), trim or look, (x, y, z + 0.5), (sx + depth * 0.6, sy + depth * 0.6, 0.2), bevel=0.04)
    box(p + "_Cornice", look, (x, y, z + 0.85), (sx + depth * 1.5, sy + depth * 1.5, 0.5), bevel=0.1)


# ------------------------------------------------------------------ roofs
def hip_roof(p, look, x, y, z, sx, sy, h, over=0.8, seam="navy_seam", ridge="gold", fascia="marble", seams=1.4):
    """A hip roof over a sx x sy block (ridge along the longer side), with an eave fascia, standing seams on every
    slope and a gold ridge + hip caps with finial balls."""
    import bmesh
    ex, ey = sx / 2 + over, sy / 2 + over
    along_x = sx >= sy
    r = abs(ex - ey)
    with O.at(x, y, z):
        box(p + "_Fascia", fascia, (0, 0, -0.2), (ex * 2 + 0.1, ey * 2 + 0.1, 0.45), bevel=0.06)
        tmp = bmesh.new()
        e = [tmp.verts.new(v) for v in ((-ex, -ey, 0), (ex, -ey, 0), (ex, ey, 0), (-ex, ey, 0))]
        if along_x:
            a, b = tmp.verts.new((-r, 0, h)), tmp.verts.new((r, 0, h))
            faces = [(e[0], e[1], b, a), (e[2], e[3], a, b), (e[1], e[2], b), (e[3], e[0], a)]
        else:
            a, b = tmp.verts.new((0, -r, h)), tmp.verts.new((0, r, h))
            faces = [(e[1], e[2], b, a), (e[3], e[0], a, b), (e[0], e[1], a), (e[2], e[3], b)]
        for f in faces:
            tmp.faces.new(f).smooth = False
        tmp.faces.new((e[3], e[2], e[1], e[0])).smooth = False
        O._merge(p + "_Roof", look, tmp, O.Matrix.Identity(4))
        ridge_a, ridge_b = (Vector((-r, 0, h)), Vector((r, 0, h))) if along_x else (Vector((0, -r, h)), Vector((0, r, h)))
        corners = [Vector((-ex, -ey, 0)), Vector((ex, -ey, 0)), Vector((ex, ey, 0)), Vector((-ex, ey, 0))]
        # standing seams: on each slope, up the fall line from the eave until a hip (or the ridge). Every slope runs in
        # m = the short half-width and rises h; a hip is 45 degrees in plan.
        m, lift = min(ex, ey), 0.06
        if seam:
            for axis, sign in (("x", -1), ("x", 1), ("y", -1), ("y", 1)):
                E = ex if axis == "x" else ey
                kmax = int((E - 0.3) / seams)
                for k in range(-kmax, kmax + 1):
                    u = k * seams
                    t = min(m, E - abs(u))
                    if t < 0.4:
                        continue
                    if axis == "x":
                        base, n_in = Vector((u, sign * ey, 0)), Vector((0, -sign, 0))
                    else:
                        base, n_in = Vector((sign * ex, u, 0)), Vector((-sign, 0, 0))
                    top = base + n_in * t + Vector((0, 0, h * t / m))
                    nrm = (-n_in * h + Vector((0, 0, m))).normalized()
                    tube(p + "_Seam", seam, [tuple(base + nrm * lift), tuple(top + nrm * lift)], 0.07, segs=4, cap=False)
        if ridge:
            if r > 0.01:
                tube(p + "_Ridge", ridge, [tuple(ridge_a + Vector((0, 0, 0.05))), tuple(ridge_b + Vector((0, 0, 0.05)))], 0.2, segs=8)
            ends = (ridge_a, ridge_b) if r > 0.01 else (ridge_a,)
            for c, ra in zip(corners, (ridge_a, ridge_b, ridge_b, ridge_a) if along_x else (ridge_a, ridge_a, ridge_b, ridge_b)):
                tube(p + "_Ridge", ridge, [tuple(c + Vector((0, 0, 0.08))), tuple(ra + Vector((0, 0, 0.05)))], 0.16, segs=6)
            for e2 in ends:
                sphere(p + "_Ridge", ridge, tuple(e2 + Vector((0, 0, 0.35))), 0.38, sub=2)


def gable(p, look, x, y, z, w, h, depth, trim="marble", tympanum=None, over=0.7):
    """A triangular pediment (front at local -Y) with raking + base cornices and an optional recessed tympanum."""
    with O.at(x, y, z):
        prism(p + "_Pediment", look, [(-w / 2, 0), (w / 2, 0), (0, h)], depth, c=(0, 0, 0))
        if tympanum:
            prism(p + "_Tympanum", tympanum, [(-w / 2 + 1.6, 0.55), (w / 2 - 1.6, 0.55), (0, h - 0.9)], 0.1, c=(0, -depth / 2 - 0.03, 0))
        slope = math.degrees(math.atan2(h, w / 2))
        L = math.hypot(w / 2, h) + over
        for s in (-1, 1):
            box(p + "_Raking", trim, (s * w / 4, -0.1, h / 2 + 0.28), (L, depth + over * 1.4, 0.56), rot=(0, s * slope, 0), bevel=0.08)
        box(p + "_Raking", trim, (0, -0.1, -0.05), (w + over * 2, depth + over * 1.4, 0.5), bevel=0.08)


def flag(p, x, y, z, h, look="flag_purple", pole="white", w=3.6, fh=2.2, seed=0):
    """A flagpole with a gold ball and a waving cloth (thin strip, both sides)."""
    with O.at(x, y, z):
        cyl(p + "_Pole", pole, (0, 0, 0), 0.14, h, segs=8)
        sphere(p + "_Pole", "gold", (0, 0, h + 0.2), 0.3, sub=1)
        n = 8
        pts_top = [(0.15 + w * i / n, 0.35 * math.sin(i / n * 5.0 + seed) * (i / n), h - 0.2) for i in range(n + 1)]
        for i in range(n):
            a, b = pts_top[i], pts_top[i + 1]
            poly(p + "_Flag", look, [(a[0], a[1], a[2] - fh), (b[0], b[1], b[2] - fh - 0.1 * (i + 1) / n), (b[0], b[1], b[2]),
                                     (a[0], a[1], a[2])], thick=0.06)


def studtop(model, look, x0, x1, y0, y1, z, skip=None):
    """PREVIEW studs on a broad top (podium, roof deck, plaza): in the game the Studs system lays them on a StudTop
    surface, so they are rendered here but are not part of the model's meshes."""
    O.studs_rect("Studs_" + model + "_" + look, look, x0, x1, y0, y1, z, skip)
