"""Shop + egg icons for Hatch a Lawyer, modelled, lit and rendered in Blender (2026-10-10).

Run headless (does not touch the Blender you have open):
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python tools/shop_icons.py -- [names...]
No names = render everything. Output (512 x 512, transparent PNG, dark sticker outline like the reference shop):
    art/shop_icons/<name>.png          the icon (uploaded to Roblox, ids in src/ArtAssets.lua)
    art/shop_icons/blend/<name>.blend  the scene it was rendered from
Style: chunky, glossy, saturated cartoon objects (coat + soft studio light + rim light), a thick ink outline added
after the render, no background. Every model is built from code below - no imported assets.
"""
import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

ROOT = "/Users/ryanchen/HatchLawyers/art/shop_icons"
RES = 512
FONT_PATH = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
INK = (0.075, 0.06, 0.10)
OUTLINE_PX = 10


# ------------------------------------------------------------------ colour + materials
def lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c) + (1.0,)


def mat(name, hexcol, rough=0.38, metal=0.0, coat=0.35, emit=0.0, emit_hex=None, sheen=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")

    def s(k, v):
        if k in b.inputs:
            b.inputs[k].default_value = v

    s("Base Color", lin(hexcol))
    s("Roughness", rough)
    s("Metallic", metal)
    s("Coat Weight", coat)
    s("Coat Roughness", 0.06)
    if sheen:
        s("Sheen Weight", sheen)
    if emit > 0:
        s("Emission Color", lin(emit_hex or hexcol))
        s("Emission Strength", emit)
    return m


M = {}


def materials():
    M.clear()
    M["gold"] = mat("gold", "ffbf2e", rough=0.22, metal=0.85, coat=0.4)
    M["gold_light"] = mat("gold_light", "ffd75a", rough=0.18, metal=0.75, coat=0.5)
    M["gold_dark"] = mat("gold_dark", "e09a12", rough=0.3, metal=0.85, coat=0.3)
    M["bill"] = mat("bill", "33a447", rough=0.5, coat=0.15)
    M["bill_light"] = mat("bill_light", "62cf5f", rough=0.5, coat=0.1)
    M["bill_dark"] = mat("bill_dark", "1d7a30", rough=0.5, coat=0.1)
    M["band"] = mat("band", "f0b72e", rough=0.4, coat=0.25)
    M["ink"] = mat("ink", "1a1622", rough=0.4, coat=0.3)
    M["white"] = mat("white", "f7f7fa", rough=0.3, coat=0.4)
    M["steel"] = mat("steel", "8c93a8", rough=0.32, metal=0.6, coat=0.3)
    M["steel_dark"] = mat("steel_dark", "5b6176", rough=0.35, metal=0.6, coat=0.3)
    M["sparkle"] = mat("sparkle", "fff6c4", rough=0.3, emit=4.0, emit_hex="fff2b0")
    M["sparkle_blue"] = mat("sparkle_blue", "d8f0ff", rough=0.3, emit=4.0, emit_hex="9fd8ff")
    return M


# ------------------------------------------------------------------ scene plumbing
def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.lights, bpy.data.cameras, bpy.data.images):
        for d in list(coll):
            if d.users == 0:
                coll.remove(d)
    materials()


def link(o):
    bpy.context.scene.collection.objects.link(o)
    return o


def from_bm(name, bm, m=None, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = link(bpy.data.objects.new(name, me))
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    if m:
        me.materials.append(m)
    return o


def bevel(o, w, seg=4):
    b = o.modifiers.new("Bevel", "BEVEL")
    b.width = w
    b.segments = seg
    b.limit_method = "ANGLE"
    b.harden_normals = True
    return b


def subsurf(o, lv=2):
    s = o.modifiers.new("Subsurf", "SUBSURF")
    s.levels = lv
    s.render_levels = lv
    return s


def place(o, loc=(0, 0, 0), rot=(0, 0, 0), scale=None):
    o.location = loc
    o.rotation_euler = tuple(math.radians(a) for a in rot)
    if scale is not None:
        o.scale = scale if isinstance(scale, tuple) else (scale, scale, scale)
    return o


def box(name, size, loc, m, rot=(0, 0, 0), bev=0.06):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    o = from_bm(name, bm, m)
    if bev:
        bevel(o, min(bev, min(size) * 0.45))
    return place(o, loc, rot)


def sphere(name, r, loc, m, scale=(1, 1, 1), seg=48, rings=24):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    return place(from_bm(name, bm, m), loc)


def gem(name, r, loc, m, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=r)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    return place(from_bm(name, bm, m, smooth=False), loc)


def cyl(name, r, depth, loc, m, rot=(0, 0, 0), bev=0.03, verts=48, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    o = from_bm(name, bm, m)
    if bev:
        bevel(o, bev, 3)
    return place(o, loc, rot)


def torus_bm(R, r, nu=96, nv=20, zscale=1.0, wave=None, u0=0.0, u1=2 * math.pi, closed=True):
    bm = bmesh.new()
    rows = []
    count = nu if closed else nu + 1
    for i in range(count):
        u = u0 + (u1 - u0) * i / nu
        row = []
        dz = wave(u) if wave else 0.0
        for j in range(nv):
            v = 2 * math.pi * j / nv
            row.append(bm.verts.new(((R + r * math.cos(v)) * math.cos(u), (R + r * math.cos(v)) * math.sin(u), r * math.sin(v) * zscale + dz)))
        rows.append(row)
    for i in range(nu if closed else nu):
        a, b_ = rows[i], rows[(i + 1) % len(rows)]
        for j in range(nv):
            bm.faces.new((a[j], b_[j], b_[(j + 1) % nv], a[(j + 1) % nv]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def torus(name, R, r, loc, m, rot=(0, 0, 0), **kw):
    return place(from_bm(name, torus_bm(R, r, **kw), m), loc, rot)


def prism(name, pts, depth, m, loc=(0, 0, 0), rot=(90, 0, 0), bev=0.03, sub=0, smooth=True):
    """an extruded 2D outline; with the default rot the outline stands in the XZ plane facing the camera (-Y)"""
    bm = bmesh.new()
    vb = [bm.verts.new((x, y, -depth / 2)) for x, y in pts]
    vt = [bm.verts.new((x, y, depth / 2)) for x, y in pts]
    bm.faces.new(vt)
    bm.faces.new(list(reversed(vb)))
    n = len(pts)
    for i in range(n):
        bm.faces.new((vb[i], vb[(i + 1) % n], vt[(i + 1) % n], vt[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = from_bm(name, bm, m, smooth=smooth)
    if bev:
        bevel(o, bev, 4)
    if sub:
        subsurf(o, sub)
    return place(o, loc, rot)


def star_pts(n=5, R=1.0, r=0.45, rot=90.0):
    out = []
    for i in range(n * 2):
        a = math.radians(rot + i * 180.0 / n)
        rr = R if i % 2 == 0 else r
        out.append((rr * math.cos(a), rr * math.sin(a)))
    return out


def heart_pts(scale=1.0, n=48):
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        out.append((x / 17 * scale, (y + 2) / 17 * scale))
    return out


def text3d(name, body, size, extrude, m, loc, rot=(90, 0, 0), bev=0.035):
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = body
    cu.font = bpy.data.fonts.load(FONT_PATH, check_existing=True)
    cu.size = size
    cu.extrude = extrude
    cu.bevel_depth = bev
    cu.bevel_resolution = 4
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    o = link(bpy.data.objects.new(name, cu))
    o.data.materials.append(m)
    return place(o, loc, rot)


def tube(name, pts, radius, m):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = 6
    cu.use_fill_caps = True
    sp = cu.splines.new("BEZIER")
    sp.bezier_points.add(len(pts) - 1)
    for bp, p in zip(sp.bezier_points, pts):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    o = link(bpy.data.objects.new(name, cu))
    o.data.materials.append(m)
    return o


def group(name, objs, loc=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
    root = link(bpy.data.objects.new(name, None))
    for o in objs:
        o.parent = root
    return place(root, loc, rot, scale)


def sparkle_obj(loc, size, m=None, rot=0):
    o = prism("Sparkle", star_pts(4, 1.0, 0.24, 90 + rot), 0.12, m or M["sparkle"], loc, (90, 0, 0), bev=0.02)
    o.scale = (size, size, size)
    return o


# ------------------------------------------------------------------ the egg shape + sticking things on it
EGG_TOP, EGG_BOT, EGG_TAPER = 1.34, 1.04, 0.15


def egg_map(x, y, z):
    s = 1.0 - EGG_TAPER * (max(z, 0.0) ** 1.25)
    return Vector((s * x, s * y, z * (EGG_TOP if z > 0 else EGG_BOT)))


def egg_pt(lat, lon):
    th, ph = math.radians(90 - lat), math.radians(lon - 90)  # lon 0 = front (-Y), +lon = the camera's right
    return egg_map(math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th))


def egg_frame(lat, lon):
    p = egg_pt(lat, lon)
    e = 0.05
    north = (egg_pt(min(lat + e, 89.9), lon) - egg_pt(max(lat - e, -89.9), lon)).normalized()
    east = (egg_pt(lat, lon + e) - egg_pt(lat, lon - e))
    east = east.normalized() if east.length > 1e-6 else Vector((1, 0, 0))
    n = east.cross(north).normalized()
    return p, n, east, north


def egg_radius_at(lat):
    p = egg_pt(lat, 90)
    return math.hypot(p.x, p.y), p.z


def stick(o, lat, lon, sink=0.0, spin=0.0):
    p, n, east, north = egg_frame(lat, lon)
    x = east
    y = n.cross(x).normalized()
    rot = Matrix((x, y, n)).transposed().to_4x4()
    o.matrix_world = Matrix.Translation(p - n * sink) @ rot @ Matrix.Rotation(math.radians(spin), 4, "Z") @ Matrix.Diagonal(tuple(o.scale) + (1,))
    return o


def egg_body(m, name="EggBody"):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=72, v_segments=48, radius=1.0)
    for v in bm.verts:
        v.co = egg_map(v.co.x, v.co.y, v.co.z)
    o = from_bm(name, bm, m)
    subsurf(o, 1)
    return o


def dome(name, rx, ry, h, m, lat, lon, sink=0.02, spin=0.0):
    o = sphere(name, 1.0, (0, 0, 0), m, scale=(rx, ry, h), seg=32, rings=16)
    return stick(o, lat, lon, sink, spin)


def egg_band(m, lat=0.0, r=0.075, zscale=2.2, wave=None, grow=0.012):
    R, z = egg_radius_at(lat)
    return torus("Band", R + grow, r, (0, 0, z), m, zscale=zscale, wave=wave)


def offset_angles(lat, lon, dx, dy):
    """tangent-plane offsets (units) -> lat/lon degrees on the egg (good for small motifs)"""
    R, _ = egg_radius_at(lat)
    return lat + math.degrees(dy / 1.15), lon + math.degrees(dx / max(R, 0.2))


# ------------------------------------------------------------------ shared props
def coin(loc, rot=(0, 0, 0), r=0.36, t=0.1):
    a = cyl("Coin", r, t, (0, 0, 0), M["gold"], bev=0.03, verts=40)
    b = cyl("CoinFace", r * 0.7, t + 0.025, (0, 0, 0), M["gold_light"], bev=0.012, verts=40)
    return group("CoinG", [a, b], loc, rot)


def coin_stack(x, y, n, z0=0.0, r=0.36, jitter=0.03, seed=1):
    rnd = random.Random(seed)
    out = []
    for i in range(n):
        out.append(coin((x + rnd.uniform(-jitter, jitter), y + rnd.uniform(-jitter, jitter), z0 + 0.05 + i * 0.105), (0, 0, rnd.uniform(0, 90)), r))
    return out


def bill_stack(loc, n=6, rotz=0.0, scale=1.0, seed=2):
    rnd = random.Random(seed)
    objs = []
    for i in range(n):
        z = 0.04 + i * 0.075
        objs.append(box("Bill", (1.9, 0.92, 0.07), (rnd.uniform(-0.03, 0.03), rnd.uniform(-0.03, 0.03), z), M["bill"], (0, 0, rnd.uniform(-4, 4)), bev=0.02))
    top = 0.04 + (n - 1) * 0.075 + 0.04
    objs.append(box("BillFace", (1.62, 0.66, 0.012), (0, 0, top), M["bill_light"], bev=0.006))
    objs.append(cyl("BillSeal", 0.22, 0.02, (0, 0, top + 0.006), M["bill_dark"], (0, 0, 0), bev=0.004))
    for sx in (-0.62, 0.62):
        objs.append(cyl("BillCorner", 0.09, 0.02, (sx, 0, top + 0.006), M["bill_dark"], bev=0.004, verts=24))
    objs.append(box("Strap", (0.34, 0.98, n * 0.075 + 0.05), (0, 0, (top - 0.02) / 2 + 0.01), M["band"], bev=0.015))
    return group("Bills", objs, loc, (0, 0, rotz), scale)


def gold_bar(loc, rotz=0.0, s=1.0):
    pts_b = [(-0.55, -0.27), (0.55, -0.27), (0.55, 0.27), (-0.55, 0.27)]
    bm = bmesh.new()
    vb = [bm.verts.new((x, y, 0)) for x, y in pts_b]
    vt = [bm.verts.new((x * 0.78, y * 0.62, 0.3)) for x, y in pts_b]
    bm.faces.new(vt)
    bm.faces.new(list(reversed(vb)))
    for i in range(4):
        bm.faces.new((vb[i], vb[(i + 1) % 4], vt[(i + 1) % 4], vt[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = from_bm("GoldBar", bm, M["gold"])
    bevel(o, 0.04, 3)
    o.scale = (s, s, s)
    return place(o, loc, (0, 0, rotz), (s, s, s))


def lightning(loc, s, m, rot=(90, 0, 0)):
    pts = [(-0.15, 1.0), (0.45, 1.0), (0.12, 0.22), (0.5, 0.22), (-0.32, -1.05), (-0.03, -0.12), (-0.44, -0.12)]
    o = prism("Bolt", pts, 0.22, m, loc, rot, bev=0.05)
    o.scale = (s, s, s)
    return o


# ------------------------------------------------------------------ EGGS
def egg_briefcase(leather="7a3c16", strap="3e1d0b"):
    LEATHER = mat("leather", leather, rough=0.5, coat=0.18 if leather == "7a3c16" else 0.35)
    STRAP = mat("strap", strap, rough=0.5, coat=0.15)
    STITCH = mat("stitch", "f3dcae", rough=0.5)
    objs = [egg_body(LEATHER)]
    objs.append(egg_band(STRAP, 2.0, r=0.08, zscale=2.4))
    R, z = egg_radius_at(2.0)
    for k in range(36):  # stitching along both edges of the strap
        a = 2 * math.pi * k / 36
        for dz in (-0.13, 0.13):
            rr = R + 0.012 + 0.08 * math.sqrt(1 - (dz / 0.192) ** 2) - 0.004
            objs.append(sphere("Stitch", 0.024, (rr * math.cos(a), rr * math.sin(a), z + dz), STITCH, scale=(1, 1, 1.8), seg=12, rings=8))
    # gold clasp plate + keyhole on the front
    plate = box("Clasp", (0.56, 0.48, 0.12), (0, 0, 0), M["gold"], bev=0.07)
    stick(plate, 2.0, 0, sink=-0.1)
    key = cyl("Keyhole", 0.07, 0.06, (0, 0, 0), M["ink"], bev=0.01, verts=24)
    stick(key, 6.0, 0, sink=-0.18)
    slot = box("KeySlot", (0.06, 0.14, 0.06), (0, 0, 0), M["ink"], bev=0.01)
    stick(slot, -1.5, 0, sink=-0.18)
    objs += [plate, key, slot]
    for dz in (-0.2, 0.2):  # thin gold trims along both edges of the strap
        objs.append(torus("Trim", R + 0.01, 0.022, (0, 0, z + dz), M["gold"], nv=10))
    for lon in (-52, 52):  # side latches
        latch = box("Latch", (0.24, 0.3, 0.1), (0, 0, 0), M["gold"], bev=0.04)
        objs.append(stick(latch, 2.0, lon, sink=-0.1))
    # handle on top: an arch of dark leather on two gold mounts
    top = egg_pt(90, 0).z
    for x in (-0.36, 0.36):
        objs.append(box("Mount", (0.2, 0.2, 0.14), (x, 0, top - 0.12), M["gold"], bev=0.05))
    h = torus("Handle", 0.36, 0.085, (0, 0, top - 0.04), STRAP, (90, 0, 0), u0=0.0, u1=math.pi, closed=False, nu=40, nv=16)
    objs.append(h)
    # gold rivets
    for lat, lon in ((45, -38), (45, 38), (-40, -40), (-40, 40), (40, 110), (-38, 115), (55, 0), (-52, 0)):
        objs.append(dome("Rivet", 0.07, 0.07, 0.05, M["gold"], lat, lon, sink=0.0))
    return group("Egg", objs), {"elev": 12, "yaw": -18}


def egg_brainrot():
    BODY = mat("purple", "a55fff", rough=0.35, coat=0.45)
    SPOT = mat("lime", "86f04e", rough=0.35, coat=0.4)
    BAND = mat("pink", "ff55be", rough=0.32, coat=0.45)
    CYAN = mat("cyan", "3cd7eb", rough=0.15, coat=0.6)
    YEL = mat("yellow", "ffe13c", rough=0.15, coat=0.6)
    objs = [egg_body(BODY)]
    objs.append(egg_band(BAND, -4.0, r=0.07, zscale=2.4, wave=lambda u: 0.07 * math.sin(9 * u)))
    rnd = random.Random(7)
    spots = [(40, -30, 0.26), (58, 25, 0.2), (22, 38, 0.17), (-28, -40, 0.24), (-45, 20, 0.2), (30, -75, 0.18), (-20, 70, 0.2),
             (68, -40, 0.14), (-60, -15, 0.15), (18, -8, 0.12), (-25, 5, 0.1), (45, 75, 0.16), (-35, 110, 0.2), (35, 125, 0.18)]
    for lat, lon, r in spots:
        objs.append(dome("Spot", r, r * rnd.uniform(0.85, 1.05), 0.06, SPOT, lat, lon, sink=0.015, spin=rnd.uniform(0, 90)))
    for lat, lon, m in ((12, -55, CYAN), (-55, 48, YEL), (60, 60, CYAN), (-12, 32, YEL)):
        g = gem("Gem", 0.1, (0, 0, 0), m, scale=(1, 1, 0.7))
        objs.append(stick(g, lat, lon, sink=-0.02))
    return group("Egg", objs), {"elev": 12, "yaw": -12}


def egg_pet():
    BODY = mat("peach", "ff9f4f", rough=0.4, coat=0.35)
    PAW = mat("paw", "8a5230", rough=0.4, coat=0.3)
    COLLAR = mat("collar", "ff6f9a", rough=0.32, coat=0.45)
    objs = [egg_body(BODY)]
    objs.append(egg_band(COLLAR, -6.0, r=0.085, zscale=1.9))
    # gold heart tag hanging off the collar at the front
    R, z = egg_radius_at(-6.0)
    ring = torus("TagRing", 0.08, 0.025, (0, -R - 0.08, z - 0.06), M["gold"], (90, 0, 0), nu=32, nv=10)
    heart = prism("Heart", heart_pts(0.36), 0.1, M["gold"], (0, -R - 0.12, z - 0.33), (90 + 8, 0, 0), bev=0.035)
    objs += [ring, heart]

    def paw(lat, lon, s, spin):
        out = [dome("Pad", 0.2 * s, 0.17 * s, 0.06, PAW, lat, lon, sink=0.02, spin=spin)]
        for dx, dy in ((-0.2, 0.19), (-0.075, 0.28), (0.075, 0.28), (0.2, 0.19)):
            c, sn = math.cos(math.radians(spin)), math.sin(math.radians(spin))
            ox, oy = (dx * c - dy * sn) * s, (dx * sn + dy * c) * s
            la, lo = offset_angles(lat, lon, ox, oy)
            out.append(dome("Toe", 0.075 * s, 0.085 * s, 0.05, PAW, la, lo, sink=0.015, spin=spin))
        return out

    for lat, lon, s, spin in ((34, -18, 1.0, 12), (48, 42, 0.8, -20), (-45, -38, 0.85, 25), (18, 62, 0.75, -35), (64, -55, 0.65, 30), (-48, 42, 0.7, -10)):
        objs += paw(lat, lon, s, spin)
    return group("Egg", objs), {"elev": 12, "yaw": -14}


def egg_food():
    BODY = mat("coral", "ff5a45", rough=0.36, coat=0.4)
    ICING = mat("icing", "ffc824", rough=0.25, coat=0.5)
    CHERRY = mat("cherry", "e8182e", rough=0.12, coat=0.8)
    STEM = mat("stem", "4e8a2a", rough=0.5)
    LEAF = mat("leaf", "5cc43a", rough=0.4, coat=0.3)
    SPR = [mat("s1", "ff4f9a", 0.3, coat=0.5), mat("s2", "3fa9ff", 0.3, coat=0.5), mat("s3", "ffffff", 0.3, coat=0.5),
           mat("s4", "7ae04a", 0.3, coat=0.5), mat("s5", "b26bff", 0.3, coat=0.5)]
    objs = [egg_body(BODY)]

    def thr(ph):
        return 0.22 + 0.1 * math.sin(5 * ph + 0.6) + 0.045 * math.sin(13 * ph)

    # frosting cap: the top of the egg, pushed out, with a wavy lower edge
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=96, v_segments=64, radius=1.0)
    kill = []
    for v in bm.verts:
        x, y, zz = v.co
        ph = math.atan2(y, x)
        t = thr(ph)
        if zz < t - 0.25:
            kill.append(v)
        elif zz < t:
            r = math.sqrt(max(0.0, 1 - t * t))
            k = r / max(math.hypot(x, y), 1e-6)
            v.co = Vector((x * k, y * k, t))
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    for v in bm.verts:
        v.co = egg_map(v.co.x, v.co.y, v.co.z) * 1.03
    fr = from_bm("Frosting", bm, ICING)
    so = fr.modifiers.new("Solid", "SOLIDIFY")
    so.thickness = 0.05
    so.offset = 1
    subsurf(fr, 1)
    objs.append(fr)
    # drips hanging off the edge
    for lon in (-70, -28, 8, 46, 84, 130, 200, 250, 300):
        ph = math.radians(lon - 90)
        lat_edge = math.degrees(math.asin(max(-1.0, min(1.0, thr(ph)))))
        L = 0.16 + 0.12 * ((lon * 37) % 7) / 7
        objs.append(dome("Drip", 0.09, L, 0.065, ICING, lat_edge - math.degrees(L / 1.15) * 0.75, lon, sink=-0.01))
        objs.append(dome("DripEnd", 0.1, 0.1, 0.07, ICING, lat_edge - math.degrees(L / 1.15) * 1.5, lon, sink=-0.01))
    rnd = random.Random(11)
    for i in range(64):  # sprinkles
        lat = rnd.uniform(28, 82)
        lon = rnd.uniform(-180, 180)
        s = cyl("Sprinkle", 0.045, 0.24, (0, 0, 0), SPR[i % len(SPR)], (0, 90, 0), bev=0.042, verts=16)
        bpy.context.view_layer.update()
        s.data.transform(s.matrix_basis)
        s.matrix_basis = Matrix()
        objs.append(stick(s, lat, lon, sink=-0.075, spin=rnd.uniform(0, 180)))
    top = egg_pt(90, 0).z
    objs.append(sphere("Cherry", 0.26, (0, 0, top + 0.27), CHERRY, scale=(1, 1, 0.92)))
    objs.append(sphere("CherryShine", 0.06, (-0.1, -0.2, top + 0.4), M["white"], scale=(1, 0.5, 1.4)))
    objs.append(tube("Stem", [(0, 0, top + 0.48), (0.08, 0.02, top + 0.72), (0.26, 0.05, top + 0.88)], 0.028, STEM))
    lf = sphere("Leaf", 0.16, (0.34, 0.05, top + 0.86), LEAF, scale=(1, 0.45, 0.22))
    lf.rotation_euler = (0, math.radians(-25), math.radians(20))
    objs.append(lf)
    return group("Egg", objs), {"elev": 14, "yaw": -12}


def egg_ocean():
    BODY = mat("ocean", "39a8ec", rough=0.3, coat=0.5)
    FOAM = mat("foam", "ffffff", rough=0.35, coat=0.4)
    STAR = mat("starfish", "ff8c28", rough=0.45, coat=0.25)
    STARDOT = mat("stardot", "ffbf6b", rough=0.45)
    BUB = mat("bubble", "d9f6ff", rough=0.05, coat=0.9)
    TEAL = mat("teal", "3cdcc8", rough=0.15, coat=0.6)
    objs = [egg_body(BODY)]
    objs.append(egg_band(FOAM, 4.0, r=0.075, zscale=2.2, wave=lambda u: 0.11 * math.sin(7 * u)))
    objs.append(egg_band(FOAM, -30.0, r=0.05, zscale=1.8, wave=lambda u: 0.07 * math.sin(7 * u + 1.4), grow=0.006))
    for lat, lon, r in ((42, -30, 0.14), (55, 20, 0.1), (30, 45, 0.12), (65, -60, 0.08), (-50, 55, 0.1), (-12, -70, 0.09), (40, 110, 0.12)):
        objs.append(dome("Bubble", r, r, r * 0.7, BUB, lat, lon, sink=0.0))
    st = prism("Starfish", star_pts(5, 0.42, 0.19, 90), 0.1, STAR, (0, 0, 0), (0, 0, 0), bev=0.04, sub=1)
    objs.append(stick(st, -40, -20, sink=-0.04, spin=12))
    for k in range(5):
        la, lo = offset_angles(-40, -20, 0.2 * math.cos(math.radians(102 + k * 72)), 0.2 * math.sin(math.radians(102 + k * 72)))
        objs.append(dome("StarDot", 0.035, 0.035, 0.03, STARDOT, la, lo, sink=-0.085))
    for lat, lon in ((20, 70), (62, 30)):
        objs.append(stick(gem("Gem", 0.09, (0, 0, 0), TEAL, scale=(1, 1, 0.7)), lat, lon, sink=-0.02))
    # bubbles floating up beside it
    for loc, r in (((1.25, -0.4, 1.2), 0.14), ((1.45, -0.3, 1.65), 0.1), ((1.2, -0.5, 2.0), 0.07)):
        objs.append(sphere("FloatBubble", r, loc, BUB))
    return group("Egg", objs), {"elev": 12, "yaw": -14}


def egg_space():
    BODY = mat("space", "3a2a8a", rough=0.32, coat=0.55)
    STAR = mat("star", "ffe65a", rough=0.3, emit=1.2, emit_hex="ffd84a")
    DOT = mat("dot", "ffffff", rough=0.3, emit=2.0)
    RING = mat("ring", "c39bff", rough=0.25, coat=0.5, emit=0.35, emit_hex="b07aff")
    RING2 = mat("ring2", "7fe3ff", rough=0.25, coat=0.5, emit=0.5)
    MOON = mat("moon", "5adcff", rough=0.35, coat=0.4)
    objs = [egg_body(BODY)]
    for lat, lon, s, spin in ((40, -30, 0.26, 10), (15, 35, 0.2, -15), (-38, -10, 0.22, 30), (60, 25, 0.16, 0), (-15, -62, 0.16, 20),
                              (-55, 40, 0.16, -5), (30, 80, 0.18, 12), (70, -45, 0.12, 0), (-30, 110, 0.18, 0)):
        st = prism("Star", star_pts(5, s, s * 0.46, 90), 0.06, STAR, (0, 0, 0), (0, 0, 0), bev=0.02, sub=1)
        objs.append(stick(st, lat, lon, sink=-0.03, spin=spin))
    rnd = random.Random(5)
    for i in range(18):
        objs.append(dome("Dot", 0.028, 0.028, 0.02, DOT, rnd.uniform(-60, 75), rnd.uniform(-120, 120), sink=0.0))
    rg = [torus("Ring", 1.52, 0.075, (0, 0, -0.05), RING, zscale=0.32, nu=128, nv=16),
          torus("Ring2", 1.72, 0.04, (0, 0, -0.05), RING2, zscale=0.3, nu=128, nv=12)]
    objs += [group("Rings", rg, (0, 0, -0.1), (16, -14, 0))]
    objs.append(sphere("Moon", 0.17, (-1.45, -0.55, 1.15), MOON))
    objs.append(sphere("MoonSpot", 0.05, (-1.5, -0.7, 1.2), mat("moonspot", "2fb3e0", 0.4), scale=(1, 0.5, 1)))
    return group("Egg", objs), {"elev": 12, "yaw": -10}


def egg_rare():
    egg, opts = egg_briefcase("2f86ea", "123f8f")  # the Rare Briefcase Egg (rare = blue), for "RARE EGG!" rewards
    sp = [sparkle_obj(loc, s, M["sparkle_blue"]) for loc, s in (((-1.2, -0.9, 2.3), 0.22), ((1.25, -0.9, 1.9), 0.18), ((1.1, -1.0, -0.6), 0.14))]
    return group("Item", [egg] + sp), opts


EGGS = {
    "egg_rare": egg_rare,
    "egg_briefcase": egg_briefcase,
    "egg_brainrot": egg_brainrot,
    "egg_pet": egg_pet,
    "egg_food": egg_food,
    "egg_ocean": egg_ocean,
    "egg_space": egg_space,
}


# ------------------------------------------------------------------ SHOP ITEMS
def item_cash_x2():
    objs = []
    objs.append(bill_stack((-0.55, 0.75, 0), 8, -10, 1.0, seed=3))
    objs.append(bill_stack((-0.4, 0.8, 0.66), 5, 14, 0.95, seed=4))
    objs += coin_stack(-1.05, -0.3, 8, seed=1)
    objs += coin_stack(-0.3, -0.6, 6, seed=2)
    objs += coin_stack(0.35, -0.2, 11, seed=3)
    for loc, rot in (((0.2, -1.1, 0.34), (70, 0, 20)), ((-0.75, -1.15, 0.05), (0, 0, 0)), ((0.85, -0.75, 0.05), (0, 0, 0))):
        objs.append(coin(loc, rot))
    GREEN = mat("x2", "22c832", rough=0.22, coat=0.7, emit=0.12, emit_hex="3dff4a")
    objs.append(text3d("X2", "x2", 2.5, 0.32, GREEN, (1.25, -1.5, 1.85), (90, 0, -10)))
    objs.append(sparkle_obj((-1.55, -1.0, 2.2), 0.3))
    objs.append(sparkle_obj((2.3, -1.6, 3.0), 0.22))
    return group("Item", objs), {"elev": 18, "yaw": 0}


def item_lucky_eggs():
    objs = []
    GOLDEGG = mat("goldegg", "ffc634", rough=0.18, metal=0.8, coat=0.6)
    e = egg_body(GOLDEGG, "GoldEgg")
    eg = [e]
    for lat, lon in ((40, -30), (45, 30), (-35, -35), (-40, 35), (10, 0), (65, 0)):
        eg.append(dome("Gem", 0.09, 0.09, 0.06, M["gold_light"], lat, lon, sink=-0.01))
    objs.append(group("EggG", eg, (-0.55, 0.4, 1.0), (0, 0, -15), 0.95))
    LEAF = mat("clover", "3edc4c", rough=0.28, coat=0.55)
    VEIN = mat("vein", "a6ff8a", rough=0.35, coat=0.4)
    STEM = mat("stem", "2a9a3a", rough=0.4)
    leaves = []
    for k in range(4):
        a = 45 + k * 90
        rim = prism("LeafRim", heart_pts(0.78), 0.12, M["gold"], (0, 0.03, 0), (90, 0, 0), bev=0.04)
        lf = prism("Leaf", heart_pts(0.66), 0.16, LEAF, (0, -0.02, 0.03), (90, 0, 0), bev=0.05)
        vein = box("Vein", (0.05, 0.03, 0.42), (0, -0.12, 0.2), VEIN, bev=0.015)
        g = group("LeafG", [rim, lf, vein], (0, 0, 0), (0, a - 180, 0))
        # push each leaf out from the centre along its own axis (point of the heart at the centre)
        g.location = (math.sin(math.radians(a - 180)) * -0.02, 0, 0)
        leaves.append(g)
    centre = sphere("Centre", 0.14, (0, -0.1, 0), M["gold_light"], scale=(1, 0.6, 1))
    stem = tube("Stem", [(0.0, 0.0, -0.1), (0.12, 0.0, -0.7), (0.38, 0.0, -1.2)], 0.06, STEM)
    clover = group("Clover", leaves + [centre, stem], (0.7, -1.0, 0.95), (0, 0, 8), 1.45)
    objs.append(clover)
    for loc, s in (((-1.55, -0.6, 2.4), 0.3), ((1.7, -1.0, 2.25), 0.22), ((-1.6, -0.9, 0.5), 0.18), ((0.2, -0.9, 2.7), 0.16)):
        objs.append(sparkle_obj(loc, s))
    return group("Item", objs), {"elev": 10, "yaw": 0}


def item_speedy():
    RED = mat("watchred", "ef3b3b", rough=0.25, coat=0.6)
    FACE = mat("face", "fbfbff", rough=0.3, coat=0.3)
    YEL = mat("bolt", "ffd21f", rough=0.25, coat=0.5, emit=0.6, emit_hex="ffcf1f")
    STREAK = mat("streak", "ffffff", rough=0.3, emit=0.4)
    w = []
    w.append(cyl("Body", 1.0, 0.42, (0, 0, 0), RED, (90, 0, 0), bev=0.12, verts=64))
    w.append(cyl("Face", 0.8, 0.46, (0, -0.02, 0), FACE, (90, 0, 0), bev=0.04, verts=64))
    for k in range(12):
        a = math.radians(k * 30)
        L = 0.16 if k % 3 == 0 else 0.09
        t = box("Tick", (0.05 if k % 3 else 0.07, 0.04, L), (math.sin(a) * 0.64, -0.25, math.cos(a) * 0.64), M["ink"], (0, k * 30, 0), bev=0.01)
        w.append(t)
    w.append(box("HandL", (0.07, 0.04, 0.55), (0.18, -0.27, 0.18), M["ink"], (0, 45, 0), bev=0.02))
    w.append(box("HandS", (0.07, 0.04, 0.36), (-0.13, -0.27, 0.07), M["ink"], (0, -62, 0), bev=0.02))
    w.append(cyl("Pin", 0.08, 0.1, (0, -0.27, 0), M["gold"], (90, 0, 0), bev=0.02, verts=24))
    w.append(cyl("Stem", 0.11, 0.24, (0, 0, 1.08), M["gold"], bev=0.03))
    w.append(cyl("Crown", 0.22, 0.18, (0, 0, 1.27), M["gold"], bev=0.05))
    w.append(cyl("SideBtn", 0.1, 0.22, (0.78, 0, 0.78), M["gold"], (0, 45, 0), bev=0.03))
    watch = group("Watch", w, (0.15, 0, 1.25), (0, 12, 0))
    objs = [watch]
    for z, L, x in ((1.75, 1.3, -1.6), (1.25, 1.7, -1.75), (0.75, 1.15, -1.55)):
        s = cyl("Streak", 0.075, L, (x, 0.2, z), STREAK, (0, 90, 0), bev=0.07, verts=24)
        objs.append(s)
    objs.append(lightning((0.95, -0.7, 0.75), 0.62, YEL, (90, 0, -12)))
    objs.append(sparkle_obj((-0.9, -0.6, 2.55), 0.22))
    return group("Item", objs), {"elev": 10, "yaw": 0}


def lawyer(x, y, suit, tie, hair, s=1.0, case=False, skin="ffcc99"):
    SUIT, TIE, HAIR = mat("suit", suit, 0.45, coat=0.2), mat("tie", tie, 0.35, coat=0.3), mat("hair", hair, 0.5, coat=0.15)
    SKIN = mat("skin", skin, 0.45, coat=0.15)
    PANTS = mat("pants", "26262e", 0.5)
    o = []
    for sx in (-0.21, 0.21):
        o.append(box("Leg", (0.36, 0.42, 0.7), (sx, 0, 0.35), PANTS, bev=0.05))
        o.append(box("Shoe", (0.4, 0.55, 0.18), (sx, -0.06, 0.09), M["ink"], bev=0.05))
    o.append(box("Torso", (1.0, 0.56, 0.95), (0, 0, 1.17), SUIT, bev=0.08))
    o.append(box("Shirt", (0.34, 0.05, 0.55), (0, -0.28, 1.36), M["white"], bev=0.015))
    o.append(box("Tie", (0.13, 0.05, 0.46), (0, -0.31, 1.3), TIE, bev=0.015))
    o.append(box("Knot", (0.17, 0.06, 0.12), (0, -0.31, 1.57), TIE, bev=0.02))
    for sx in (-0.64, 0.64):
        o.append(box("Arm", (0.27, 0.38, 0.85), (sx, 0, 1.2), SUIT, bev=0.06))
        o.append(box("Hand", (0.24, 0.3, 0.2), (sx, 0, 0.7), SKIN, bev=0.05))
    o.append(box("Head", (0.86, 0.76, 0.76), (0, 0, 2.03), SKIN, bev=0.1))
    o.append(box("Hair", (0.92, 0.82, 0.26), (0, 0.02, 2.4), HAIR, bev=0.08))
    o.append(box("HairBack", (0.92, 0.3, 0.5), (0, 0.3, 2.2), HAIR, bev=0.06))
    for sx in (-0.18, 0.18):
        o.append(box("Eye", (0.2, 0.04, 0.22), (sx, -0.39, 2.06), M["white"], bev=0.02))
        o.append(box("Pupil", (0.1, 0.04, 0.13), (sx, -0.41, 2.04), M["ink"], bev=0.015))
    o.append(box("Smile", (0.3, 0.035, 0.07), (0, -0.39, 1.84), mat("mouth", "6a1a22", 0.4), bev=0.02))
    if case:
        CASE = mat("case", "8a4a22", 0.4, coat=0.3)
        o.append(box("Case", (0.62, 0.2, 0.46), (0.66, -0.05, 0.42), CASE, bev=0.06))
        o.append(box("CaseClasp", (0.14, 0.05, 0.08), (0.66, -0.16, 0.5), M["gold"], bev=0.02))
        o.append(torus("CaseHandle", 0.1, 0.03, (0.66, -0.05, 0.68), M["ink"], (90, 0, 0), u0=0.0, u1=math.pi, closed=False, nu=16, nv=8))
    return group("Lawyer", o, (x, y, 0), (0, 0, 0), s)


def item_bigger_firm():
    objs = [
        lawyer(-1.25, 0.55, "8a8fa3", "3f8cff", "3a2416", 0.88),
        lawyer(1.25, 0.55, "8a4fe0", "ffc21a", "d8a040", 0.88),
        lawyer(0, -0.15, "263e7a", "e8303a", "5a3418", 1.0, case=True),
    ]
    PLUS = mat("plus", "4fdc3a", rough=0.25, coat=0.6, emit=0.35, emit_hex="7dff6a")
    objs.append(box("PlusH", (0.95, 0.3, 0.3), (1.65, -0.9, 2.85), PLUS, bev=0.12))
    objs.append(box("PlusV", (0.3, 0.3, 0.95), (1.65, -0.9, 2.85), PLUS, bev=0.12))
    objs.append(sparkle_obj((-1.75, -0.8, 2.85), 0.22))
    return group("Item", objs), {"elev": 12, "yaw": 0}


def item_cash_pile():
    objs = [bill_stack((0.15, 0.35, 0), 6, -14, 1.05, seed=5)]
    objs += coin_stack(-0.75, -0.55, 5, seed=6)
    objs += coin_stack(0.95, -0.45, 3, seed=7)
    objs.append(coin((0.15, -0.9, 0.3), (68, 0, 12)))
    objs.append(coin((-0.15, -0.75, 0.05), (0, 0, 0)))
    return group("Item", objs), {"elev": 22, "yaw": 0}


def item_cash_bag():
    SACK = mat("sack", "c98f4a", rough=0.62, coat=0.12, sheen=0.3)
    SACK_D = mat("sack_dark", "a8743a", rough=0.65, sheen=0.3)
    DOLLAR = mat("dollar", "2fb44a", rough=0.3, coat=0.5)
    o = []
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=64, v_segments=40, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co
        k = 1.0 + 0.12 * (1 - z * z) - (0.35 * max(z, 0) ** 2.5)
        v.co = Vector((x * k * 1.05, y * k, z * 0.95 if z > 0 else z * 0.82))
    bag = from_bm("Bag", bm, SACK)
    subsurf(bag, 1)
    o.append(place(bag, (0, 0, 0.82)))
    o.append(cyl("Neck", 0.36, 0.36, (0, 0, 1.78), SACK, bev=0.08, r2=0.3))
    o.append(torus("Rope", 0.36, 0.075, (0, 0, 1.72), M["gold"], nv=16))
    o.append(torus("Ruffle", 0.42, 0.11, (0, 0, 2.02), SACK_D, wave=lambda u: 0.06 * math.sin(8 * u), zscale=0.8))
    o.append(cyl("Top", 0.42, 0.2, (0, 0, 2.06), SACK, bev=0.06, r2=0.5))
    for x, z, rz in ((-0.18, 2.32, 18), (0.2, 2.36, -14)):  # coins peeking out of the top
        o.append(coin((x, 0.05, z), (80, 0, rz), r=0.3))
    d = text3d("Dollar", "$", 1.35, 0.1, DOLLAR, (0, -1.02, 0.82), (90, 0, 0), bev=0.035)
    o.append(d)
    o += coin_stack(1.15, -0.45, 4, seed=8)
    o += coin_stack(-1.1, -0.3, 3, seed=9)
    o.append(coin((0.55, -1.0, 0.3), (70, 0, 20)))
    o.append(coin((-0.6, -1.05, 0.05)))
    o.append(sparkle_obj((1.3, -0.6, 2.2), 0.24))
    return group("Item", o), {"elev": 14, "yaw": 0}


def item_cash_vault():
    o = []
    o.append(box("Safe", (2.3, 1.9, 2.1), (0, 0, 1.15), M["steel"], bev=0.18))
    o.append(box("Door", (1.85, 0.12, 1.65), (0, -0.98, 1.15), M["steel_dark"], bev=0.1))
    for sx in (-1.05, 1.05):
        for sz in (0.35, 1.95):
            o.append(cyl("Bolt", 0.07, 0.08, (sx, -0.98, sz), M["gold"], (90, 0, 0), bev=0.02, verts=20))
    o.append(cyl("Dial", 0.34, 0.14, (-0.3, -1.08, 1.25), M["gold"], (90, 0, 0), bev=0.04))
    o.append(cyl("DialIn", 0.18, 0.18, (-0.3, -1.1, 1.25), M["gold_dark"], (90, 0, 0), bev=0.03))
    for k in range(3):  # spoke wheel
        o.append(cyl("Spoke", 0.045, 0.62, (0.45, -1.12, 1.15), M["gold"], (0, 30 + k * 60, 0), bev=0.02, verts=16))
    o.append(torus("Wheel", 0.31, 0.05, (0.45, -1.12, 1.15), M["gold"], (90, 0, 0), nv=12))
    o.append(cyl("Hub", 0.09, 0.12, (0.45, -1.16, 1.15), M["gold_dark"], (90, 0, 0), bev=0.02, verts=24))
    for sx in (-0.9, 0.9):
        o.append(box("Foot", (0.35, 0.35, 0.18), (sx, 0, 0.05), M["steel_dark"], bev=0.05))
    # treasure on top
    o.append(bill_stack((-0.55, 0.15, 2.2), 5, 8, 0.82, seed=10))
    o.append(bill_stack((0.5, 0.35, 2.2), 7, -10, 0.82, seed=11))
    o.append(gold_bar((0.1, -0.35, 2.21), 4, 0.9))
    o.append(gold_bar((-0.55, -0.5, 2.21), -10, 0.8))
    o.append(gold_bar((-0.2, -0.45, 2.48), 8, 0.75))
    # spilling at the foot
    o += coin_stack(-1.45, -0.9, 6, seed=12)
    o += coin_stack(1.5, -0.85, 4, seed=13)
    o.append(gold_bar((1.05, -1.45, 0.0), 20, 0.85))
    for loc, rot in (((-0.7, -1.5, 0.3), (70, 0, -15)), ((0.2, -1.55, 0.05), (0, 0, 0)), ((-1.0, -1.65, 0.05), (0, 0, 0)), ((0.5, -1.7, 0.32), (72, 0, 25))):
        o.append(coin(loc, rot))
    o.append(bill_stack((-0.25, -1.55, 0.0), 3, 30, 0.7, seed=14))
    for loc, s in (((-1.55, -1.2, 2.9), 0.3), ((1.6, -1.3, 2.6), 0.24), ((1.85, -1.6, 0.9), 0.18)):
        o.append(sparkle_obj(loc, s))
    return group("Item", o), {"elev": 16, "yaw": -12}


def item_rare_eggs():
    objs = []
    for x, y, z, s, yaw in ((-1.2, 0.5, 1.05, 0.78, 15), (1.2, 0.5, 1.05, 0.78, -15), (0, -0.3, 1.25, 0.95, 0)):
        egg, _ = egg_briefcase("2f86ea", "123f8f")
        egg.location = (x, y, z)
        egg.scale = (s, s, s)
        egg.rotation_euler = (0, 0, math.radians(yaw))
        objs.append(egg)
    for loc, s in (((-1.95, -0.7, 2.6), 0.3), ((1.95, -0.8, 2.3), 0.26), ((0.0, -1.0, 3.05), 0.22), ((-0.6, -1.4, 0.35), 0.18), ((1.2, -1.3, 0.4), 0.16)):
        objs.append(sparkle_obj(loc, s, M["sparkle_blue"]))
    return group("Item", objs), {"elev": 10, "yaw": 0}


def tab_star():
    STAR = mat("starbody", "ffc21a", rough=0.25, coat=0.6)
    BLUSH = mat("blush", "ff8a6e", 0.5)
    o = [prism("Star", star_pts(5, 1.0, 0.5, 90), 0.42, STAR, (0, 0, 0), (90, 0, 0), bev=0.12, sub=2)]
    for sx in (-0.2, 0.2):
        o.append(sphere("Eye", 0.075, (sx, -0.26, 0.08), M["ink"], scale=(1, 0.5, 1.3)))
        o.append(sphere("Glint", 0.025, (sx - 0.02, -0.3, 0.13), M["white"], scale=(1, 0.5, 1)))
        o.append(sphere("Blush", 0.08, (sx * 1.9, -0.24, -0.08), BLUSH, scale=(1, 0.3, 0.55)))
    o.append(torus("Smile", 0.1, 0.022, (0, -0.27, -0.06), M["ink"], (90, 0, 0), u0=math.pi * 1.15, u1=math.pi * 1.85, closed=False, nu=16, nv=8))
    return group("Item", o, (0, 0, 0), (0, 0, -8)), {"elev": 8, "yaw": 0}


def tab_crown():
    VELVET = mat("velvet", "b0122c", rough=0.9, coat=0.0)
    RUBY = mat("ruby", "ff2a4a", rough=0.08, coat=0.8)
    SAPH = mat("sapph", "2f7bff", rough=0.08, coat=0.8)
    EMER = mat("emer", "2fd06a", rough=0.08, coat=0.8)
    o = []
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=64, radius1=1.0, radius2=1.06, depth=0.62)
    ring = from_bm("Band", bm, M["gold"])
    so = ring.modifiers.new("Solid", "SOLIDIFY")
    so.thickness = 0.14
    bevel(ring, 0.04, 3)
    o.append(place(ring, (0, 0, 0.31)))
    o.append(sphere("Velvet", 0.98, (0, 0, 0.55), VELVET, scale=(1, 1, 0.55)))
    for k in range(5):
        a = math.radians(-90 + k * 72)
        x, y = math.cos(a) * 1.0, math.sin(a) * 1.0
        o.append(cyl("Spike", 0.27, 0.78, (x, y, 0.96), M["gold"], (0, 0, 0), bev=0.04, verts=32, r2=0.05))
        o.append(sphere("Pearl", 0.13, (x * 1.0, y * 1.0, 1.4), M["white"]))
    for lon, m, s in ((-90, RUBY, 0.17), (-90 - 50, SAPH, 0.12), (-90 + 50, EMER, 0.12)):
        a = math.radians(lon)
        g = gem("Jewel", s, (math.cos(a) * 1.1, math.sin(a) * 1.1, 0.32), m, scale=(1, 0.6, 1.2))
        g.rotation_euler = (0, 0, a + math.pi / 2)
        o.append(g)
    for k in range(10):
        a = math.radians(k * 36)
        o.append(sphere("Bead", 0.045, (math.cos(a) * 1.08, math.sin(a) * 1.08, 0.08), M["gold_light"]))
    return group("Item", o, (0, 0, 0), (14, 0, 0)), {"elev": 14, "yaw": 0}


ITEMS = {
    "cash_x2": item_cash_x2,
    "lucky_eggs": item_lucky_eggs,
    "speedy_cases": item_speedy,
    "bigger_firm": item_bigger_firm,
    "cash_pile": item_cash_pile,
    "cash_bag": item_cash_bag,
    "cash_vault": item_cash_vault,
    "rare_eggs": item_rare_eggs,
    "tab_star": tab_star,
    "tab_crown": tab_crown,
}
ALL = {**EGGS, **ITEMS}


# ------------------------------------------------------------------ light, camera, render, outline
def setup_render():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    try:
        prefs.compute_device_type = "METAL"
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        sc.cycles.device = "GPU"
    except Exception as e:  # noqa
        print("GPU unavailable, CPU render:", e)
    sc.cycles.samples = 160
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.exposure = -0.22
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    # studio world for reflections: dark floor, bright sky, a bright band at the horizon
    w = bpy.data.worlds.get("Studio") or bpy.data.worlds.new("Studio")
    sc.world = w
    w.use_nodes = True
    nt = w.node_tree
    nt.nodes.clear()
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    bg = nt.nodes.new("ShaderNodeBackground")
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs[2], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], bg.inputs[0])
    nt.links.new(bg.outputs[0], out.inputs[0])
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.42, (0.10, 0.10, 0.13, 1)
    els[1].position, els[1].color = 1.0, (0.95, 0.97, 1.0, 1)
    e = els.new(0.55)
    e.color = (1.0, 1.0, 1.0, 1)
    e2 = els.new(0.6)
    e2.color = (0.55, 0.58, 0.66, 1)
    bg.inputs[1].default_value = 0.55


def mesh_points():
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in bpy.context.scene.objects:
        if o.type not in ("MESH", "CURVE", "FONT"):
            continue
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        mw = o.matrix_world
        pts.extend(mw @ v.co for v in me.vertices)
        ev.to_mesh_clear()
    return pts


def add_light(name, loc, target, power, size, color=(1, 1, 1)):
    ld = bpy.data.lights.new(name, "AREA")
    ld.energy = power
    ld.size = size
    ld.color = color
    lo = link(bpy.data.objects.new(name, ld))
    lo.location = loc
    lo.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return lo


def frame(elev, margin=0.075):
    pts = mesh_points()
    P = np.array([tuple(p) for p in pts])
    lo, hi = P.min(axis=0), P.max(axis=0)
    centre = Vector(((lo + hi) / 2).tolist())
    e = math.radians(elev)
    d = Vector((0, -math.cos(e), math.sin(e)))
    rot = (-d).to_track_quat("-Z", "Y")
    R = np.array(rot.to_matrix())
    local = (P - np.array(centre)) @ R  # columns = camera x, y, z axes
    x0, x1 = local[:, 0].min(), local[:, 0].max()
    y0, y1 = local[:, 1].min(), local[:, 1].max()
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    extent = max(x1 - x0, y1 - y0)
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = extent * (1 + 2 * margin)
    cam_d.clip_end = 500
    cam = link(bpy.data.objects.new("Cam", cam_d))
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = rot
    cam.location = centre + Vector(R @ np.array([cx, cy, 0.0])) + d * 40
    bpy.context.scene.camera = cam
    s = float(extent)
    # three-point lighting scaled to the subject: warm key (upper left), cool fill (right), strong rim (behind)
    add_light("Key", centre + Vector((-1.4, -2.0, 1.9)) * s, centre, 210 * s * s, s * 1.3, (1.0, 0.96, 0.9))
    add_light("Fill", centre + Vector((1.9, -1.5, 0.5)) * s, centre, 90 * s * s, s * 1.4, (0.86, 0.91, 1.0))
    add_light("Rim", centre + Vector((0.9, 1.9, 1.5)) * s, centre, 300 * s * s, s * 0.9, (1, 1, 1))
    add_light("Top", centre + Vector((0, -0.2, 2.4)) * s, centre, 35 * s * s, s * 1.8, (1, 1, 1))


def outline(path, radius=OUTLINE_PX):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    a = px[..., 3]
    src = np.clip((a - 0.08) / 0.5, 0, 1)  # ignore faint edge haze when growing the outline
    pad = np.pad(src, radius + 1)
    dil = np.zeros_like(a)
    for dy in range(-radius - 1, radius + 2):
        for dx in range(-radius - 1, radius + 2):
            dist = math.hypot(dx, dy)
            if dist > radius + 0.5:
                continue
            wgt = 1.0 if dist <= radius - 0.5 else (radius + 0.5 - dist)
            sh = pad[radius + 1 + dy: radius + 1 + dy + h, radius + 1 + dx: radius + 1 + dx + w] * wgt
            np.maximum(dil, sh, out=dil)
    ink = np.array(INK, dtype=np.float32)
    A = a + dil * (1 - a)
    C = px[..., :3] * a[..., None] + ink * (dil * (1 - a))[..., None]
    out = np.zeros_like(px)
    out[..., :3] = C / np.maximum(A[..., None], 1e-5)
    out[..., 3] = A
    img.pixels.foreach_set(out.ravel())
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def render(name):
    reset()
    root, opts = ALL[name]()
    root.rotation_euler.z += math.radians(opts.get("yaw", 0))
    bpy.context.view_layer.update()
    setup_render()
    frame(opts.get("elev", 14))
    os.makedirs(os.path.join(ROOT, "blend"), exist_ok=True)
    path = os.path.join(ROOT, name + ".png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    outline(path)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "blend", name + ".blend"), copy=True)
    print("RENDERED", name, path)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    names = argv or list(ALL)
    for n in names:
        render(n)
