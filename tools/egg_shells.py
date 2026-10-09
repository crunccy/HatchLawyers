"""Breakable egg shells for the 3D hatch (run inside Blender: exec(open(".../tools/egg_shells.py").read())).

The machine eggs (Hub.<Machine>.Egg.Voxel) are solid stacks of slabs, so they can't come apart. This rebuilds
each one as a HOLLOW two-layer voxel shell with the same silhouette and colours:
  outer layer  the egg's own colours (sampled from the source parts; small gem studs win over slabs)
  inner layer  a pale eggshell lining - the light inside the egg lights it up through the gaps
and fractures it into shards with jagged, noisy Voronoi borders on the sphere of directions (so the cracks run
along the voxel grid, i.e. along the egg's real geometry, and both layers of a shard line up):
  0 bottom cup (stays put), 1-3 lower petals, 4-7 upper petals, 8 top cap.
Each shard's voxels are greedy-merged into boxes (few hundred parts per egg). Per shard we also export the
motion the hatch plays: outward direction, a hinge (pivot + axis at the shard's lower edge) for the petals to
fold open, and the order the cracks appear in.

Input:  tools/egg_data/<Machine>.json (posted from Studio: parts as CFrame components in the egg's bounding-box
        space, Roblox axes).
Output: tools/egg_data/shells.lua  - ModuleScript source for ReplicatedStorage.Shared.HatchShells
        Models - Effects/egg_shell_preview_<egg>.png - Blender renders of the split at several moments.
Axes: Roblox (X, Y, Z) -> Blender (-X, Z, Y).
"""
import json
import math
import os

import bpy
import numpy as np

DATA = "/Users/ryanchen/HatchLawyers/tools/egg_data"
PREVIEW = "/Users/ryanchen/HatchLawyers/Models - Effects"
EGGS = ["EggMachine", "BrainrotEggMachine", "PetEggMachine", "FoodEggMachine", "OceanEggMachine", "SpaceEggMachine"]
VOX = 0.42           # studs per voxel
INNER = (0.97, 0.93, 0.84)  # eggshell lining

# shard seeds: (elevation deg, azimuth deg)
SEEDS = [(-90, 0)] + [(-28, a) for a in (20, 140, 260)] + [(22, a) for a in (65, 155, 245, 335)] + [(72, 0)]
SEED_KIND = ["cup", "lower", "lower", "lower", "upper", "upper", "upper", "upper", "cap"]
CRACK_ORDER = [9, 6, 7, 8, 2, 3, 4, 5, 1]  # cap cracks first, then the upper petals, then the lower ones


def seed_dirs():
    out = []
    for el, az in SEEDS:
        e, a = math.radians(el), math.radians(az)
        out.append(np.array([math.cos(e) * math.sin(a), math.sin(e), math.cos(e) * math.cos(a)]))  # Roblox: +Z front
    return np.array(out)


def noise3(p, seed=3, scale=2.2):
    """smooth-ish value noise on unit vectors (sum of a few random plane waves) -> jagged crack lines"""
    rng = np.random.default_rng(seed)
    total = np.zeros(p.shape[0])
    for k in range(7):
        d = rng.normal(size=3)
        d /= np.linalg.norm(d)
        f = scale * (1.6 ** k)
        total += np.sin(p @ d * f + rng.uniform(0, 6.28)) / (1.5 ** k)
    return total


def load(name):
    return json.load(open(os.path.join(DATA, name + ".json")))


def voxelize(parts):
    lo = np.array([1e9] * 3)
    hi = -lo
    boxes = []
    for p in parts:
        cf = p["cf"]
        pos = np.array(cf[0:3])
        R = np.array(cf[3:12]).reshape(3, 3)
        half = np.array(p["size"]) / 2
        ext = np.abs(R) @ half
        lo, hi = np.minimum(lo, pos - ext), np.maximum(hi, pos + ext)
        boxes.append((pos, R, half, np.array(p["color"]), float(np.prod(p["size"]))))
    lo -= VOX
    hi += VOX
    n = np.ceil((hi - lo) / VOX).astype(int)
    idx = np.stack(np.meshgrid(*[np.arange(k) for k in n], indexing="ij"), -1).reshape(-1, 3)
    centers = lo + (idx + 0.5) * VOX
    occ = np.zeros(len(centers), bool)
    color = np.zeros((len(centers), 3))
    best = np.full(len(centers), np.inf)
    for pos, R, half, col, vol in boxes:
        local = (centers - pos) @ R  # R columns are the part's axes
        inside = np.all(np.abs(local) <= half + 1e-6, axis=1)
        win = inside & (vol < best)  # smaller parts (gem studs) win
        color[win] = col
        best[win] = vol
        occ |= inside
    return lo, n, occ.reshape(n), color.reshape(*n, 3)


def shell_layers(occ):
    pad = np.pad(occ, 1)
    def touches(mask_p):
        t = np.zeros_like(occ)
        for ax in range(3):
            for s in (1, -1):
                t |= np.roll(mask_p, s, axis=ax)[1:-1, 1:-1, 1:-1]
        return t
    outer = occ & touches(~pad)
    inner = occ & ~outer & touches(np.pad(outer, 1))
    return outer, inner


def merge_boxes(mask, colors):
    """greedy merge: runs along X, then stack identical runs along Z"""
    nx, ny, nz = mask.shape
    runs = {}
    for y in range(ny):
        for z in range(nz):
            x = 0
            while x < nx:
                if mask[x, y, z]:
                    c = tuple(np.round(colors[x, y, z], 3))
                    x0 = x
                    while x < nx and mask[x, y, z] and tuple(np.round(colors[x, y, z], 3)) == c:
                        x += 1
                    runs.setdefault((y, x0, x, c), []).append(z)
                else:
                    x += 1
    out = []
    for (y, x0, x1, c), zs in runs.items():
        zs.sort()
        start = prev = zs[0]
        for z in zs[1:] + [None]:
            if z is not None and z == prev + 1:
                prev = z
                continue
            out.append((x0, x1, y, start, prev + 1, c))
            if z is not None:
                start = prev = z
    return out


def build(name):
    d = load(name)
    lo, n, occ, col = voxelize(d["parts"])
    outer, inner = shell_layers(occ)
    idx = np.argwhere(outer | inner)
    centers = lo + (idx + 0.5) * VOX
    c0 = centers.mean(0)
    rel = centers - c0
    # directions on an egg-normalised sphere, so shards are even all round
    span = (centers.max(0) - centers.min(0)) / 2
    u = rel / span
    u /= np.linalg.norm(u, axis=1, keepdims=True) + 1e-9
    seeds = seed_dirs()
    score = u @ seeds.T  # cosine similarity
    jag = noise3(u)[:, None] * 0.11 + noise3(u, seed=9, scale=5.0)[:, None] * 0.04
    shard_of = np.argmax(score + jag * np.array([1, 1, 1, 1, 1, 1, 1, 1, 1]), axis=1)
    sid = np.full(n, -1)
    sid[tuple(idx.T)] = shard_of
    shards = []
    for s in range(len(SEEDS)):
        mask_o = outer & (sid == s)
        mask_i = inner & (sid == s)
        if not (mask_o.any() or mask_i.any()):
            continue
        boxes = []
        for layer, mask, colors in (("o", mask_o, col), ("i", mask_i, np.broadcast_to(np.array(INNER), col.shape))):
            for x0, x1, y, z0, z1, c in merge_boxes(mask, colors):
                cmin = lo + np.array([x0, y, z0]) * VOX
                cmax = lo + np.array([x1, y + 1, z1]) * VOX
                boxes.append(((cmin + cmax) / 2 - c0, cmax - cmin, c, layer))
        pts = lo + (np.argwhere(mask_o | mask_i) + 0.5) * VOX - c0
        dirv = seeds[s]
        kind = SEED_KIND[s]
        # hinge on the shard's lower edge (cap: its lower edge on the far side), axis = tangent to the egg
        up = np.array([0, 1, 0])
        axis = np.cross(up, dirv)
        if np.linalg.norm(axis) < 1e-3:
            axis = np.array([1.0, 0, 0])
        axis /= np.linalg.norm(axis)
        low = pts[pts[:, 1] <= np.percentile(pts[:, 1], 12)].mean(0) if kind != "cup" else pts.mean(0)
        shards.append({
            "id": s, "kind": kind, "dir": dirv, "pivot": low, "axis": axis,
            "order": CRACK_ORDER[s], "center": pts.mean(0), "boxes": boxes,
        })
    return {"name": name, "vox": VOX, "shards": shards, "count": sum(len(s["boxes"]) for s in shards)}


# ------------------------------------------------------------------------------------------------ export
def lua_num(v):
    return ("%.3f" % v).rstrip("0").rstrip(".") if abs(v) > 1e-9 else "0"


def lua_vec(v):
    return "{" + ",".join(lua_num(x) for x in v) + "}"


def to_lua(eggs):
    lines = [
        "-- GENERATED by HatchLawyers/tools/egg_shells.py (Blender) - do not edit by hand.",
        "-- Breakable hollow shells for the 3D hatch: per machine egg, shards of merged voxel boxes",
        "-- { cx, cy, cz, sx, sy, sz, r, g, b, inner(0/1) } in the egg's centred space (Roblox axes, studs),",
        "-- plus each shard's motion: dir (outward), pivot + axis (hinge), order (crack sequence), kind.",
        "return {",
    ]
    for e in eggs:
        lines.append('\t["%s"] = { vox = %s, shards = {' % (e["name"], lua_num(e["vox"])))
        for s in e["shards"]:
            lines.append('\t\t{ id = %d, kind = "%s", order = %d, dir = %s, pivot = %s, axis = %s, center = %s, boxes = {'
                         % (s["id"], s["kind"], s["order"], lua_vec(s["dir"]), lua_vec(s["pivot"]), lua_vec(s["axis"]), lua_vec(s["center"])))
            row = []
            for c, size, colr, layer in s["boxes"]:
                row.append("{%s,%s,%s,%s}" % (",".join(lua_num(x) for x in c), ",".join(lua_num(x) for x in size),
                                               ",".join(lua_num(x) for x in colr), 1 if layer == "i" else 0))
                if len(row) == 6:
                    lines.append("\t\t\t" + ",".join(row) + ",")
                    row = []
            if row:
                lines.append("\t\t\t" + ",".join(row) + ",")
            lines.append("\t\t} },")
        lines.append("\t} },")
    lines.append("}")
    return "\n".join(lines) + "\n"


# ------------------------------------------------------------------------------------------------ preview
def rb(v):
    return (-v[0], v[2], v[1])


def preview(egg, rarity=(0.35, 0.65, 1.0)):
    scene = bpy.data.scenes.get("EggShellPreview") or bpy.data.scenes.new("EggShellPreview")
    for o in list(scene.collection.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    mats = {}

    def mat(color, emit=0.0):
        key = (tuple(np.round(color, 3)), emit)
        if key in mats:
            return mats[key]
        m = bpy.data.materials.new("eggprev")
        m.use_nodes = True
        bsdf = next(nd for nd in m.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
        lin = np.where(color <= 0.04045, color / 12.92, ((color + 0.055) / 1.055) ** 2.4)  # Roblox sRGB -> linear
        bsdf.inputs["Base Color"].default_value = (*lin, 1)
        bsdf.inputs["Roughness"].default_value = 0.6
        if emit:
            for k in ("Emission Color", "Emission"):
                if k in bsdf.inputs:
                    bsdf.inputs[k].default_value = (*lin, 1)
            bsdf.inputs["Emission Strength"].default_value = emit
        mats[key] = m
        return m

    shard_objs = []
    for s in egg["shards"]:
        verts, faces, fmats, mlist = [], [], [], []
        for c, size, colr, layer in s["boxes"]:
            m = mat(np.array(colr))
            if m not in mlist:
                mlist.append(m)
            mi = mlist.index(m)
            cx, cy, cz = rb(c)
            sx, sy, sz = size[0], size[2], size[1]
            b = len(verts)
            for dx in (-1, 1):
                for dy in (-1, 1):
                    for dz in (-1, 1):
                        verts.append((cx + dx * sx / 2, cy + dy * sy / 2, cz + dz * sz / 2))
            for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
                faces.append(tuple(b + i for i in f))
                fmats.append(mi)
        me = bpy.data.meshes.new("shard%d" % s["id"])
        me.from_pydata(verts, [], faces)
        for m in mlist:
            me.materials.append(m)
        for poly, mi in zip(me.polygons, fmats):
            poly.material_index = mi
        ob = bpy.data.objects.new("shard%d" % s["id"], me)
        scene.collection.objects.link(ob)
        shard_objs.append((ob, s))
    core = bpy.data.objects.new("core", bpy.data.meshes.new("core"))
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=16, radius=1.6)
    bm.to_mesh(core.data)
    bm.free()
    core.data.materials.append(mat(np.array(rarity), emit=3.0))
    scene.collection.objects.link(core)
    light = bpy.data.objects.new("glow", bpy.data.lights.new("glow", "POINT"))
    light.data.color = rarity
    scene.collection.objects.link(light)
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 2.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = 50
    cam.location = (0, 26, 2.5)
    cam.rotation_euler = (math.radians(90 - 4), 0, math.radians(180))
    scene.collection.objects.link(cam)
    scene.camera = cam
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = next(nd for nd in world.node_tree.nodes if nd.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.05, 0.06, 0.09, 1)
    scene.world = world
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 420, 480
    scene.render.image_settings.file_format = "PNG"
    tiles = []
    # (crack 0..1, open 0..1, light) snapshots of the hatch timeline
    moments = [(0, 0, 0), (0.5, 0, 300), (1, 0, 600), (1, 0.35, 1500), (1, 0.7, 3000), (1, 1.0, 5000)]
    for crack, opn, power in moments:
        for ob, s in shard_objs:
            offset, angle = shard_pose(s, crack, opn)
            # rotate about the hinge pivot (Roblox space), then slide by the offset
            from mathutils import Matrix, Vector
            piv = Vector(rb(s["pivot"]))
            R = Matrix.Rotation(angle, 4, Vector(rb(s["axis"])))
            ob.matrix_world = Matrix.Translation(Vector(rb(offset)) + piv) @ R @ Matrix.Translation(-piv)
        light.data.energy = power * 0.4
        light.data.shadow_soft_size = 0.5
        core.scale = (0.2 + 0.8 * min(1, crack * 0.5 + opn),) * 3
        path = os.path.join(PREVIEW, "_tmp_eggprev.png")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True, scene=scene.name)
        img = bpy.data.images.load(path, check_existing=False)
        w, h = img.size
        tiles.append(np.array(img.pixels[:], np.float32).reshape(h, w, 4))
        bpy.data.images.remove(img)
    sheet = np.concatenate(tiles, axis=1)
    out = bpy.data.images.new("egg_shell_preview", sheet.shape[1], sheet.shape[0])
    out.pixels = sheet.ravel()
    out.filepath_raw = os.path.join(PREVIEW, "egg_shell_preview_%s.png" % egg["name"])
    out.file_format = "PNG"
    out.save()
    saved = out.filepath_raw
    bpy.data.images.remove(out)
    return saved


def shard_pose(s, crack, opn):
    """THE motion (mirrored in StarterPlayerScripts.Eggs): returns (offset, hinge angle) for a shard.
    crack 0..1: seams open in CRACK_ORDER (each shard eases out 0.07 studs - hairline gaps the light leaks through)
    opn 0..1: petals fold open on their lower-edge hinge and drift outward; the cap lifts and tips back."""
    order = s["order"]
    k = min(1, max(0, crack * 9 - (order - 1)) )  # this shard's crack has formed
    seam = 0.07 * k
    d = np.array(s["dir"])
    if s["kind"] == "cup":
        return d * seam * 0.5, 0.0
    ease = opn * opn * (3 - 2 * opn)
    if s["kind"] == "cap":
        return d * (seam + 1.6 * ease) + np.array([0, 0.9 * ease, 0]), math.radians(-35) * ease
    fold = math.radians(55 if s["kind"] == "upper" else 30) * ease
    return d * (seam + 0.6 * ease), -fold


eggs = [build(n) for n in EGGS]
open(os.path.join(DATA, "shells.lua"), "w").write(to_lua(eggs))
print([(e["name"], e["count"], len(e["shards"])) for e in eggs])
print(preview(eggs[0], rarity=(1.0, 0.75, 0.15)))
