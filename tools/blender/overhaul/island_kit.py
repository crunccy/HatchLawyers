# tools/blender/overhaul/island_kit.py - shared pieces for re-dressing the approved v2 ISLANDS with the overhaul's models
# (crnuch's calls 2026-10-24, CLAUDE.md "MODEL OVERHAUL"; the hub's version is island_hub.py):
#   run_island(script, out) runs an island's v2 build script UNCHANGED in a sandbox: its .blend save is skipped, its JSON
#     writes land in the out dir (never over the committed layout the wiring reads), its own renders are off.
#   generic adapters for the dressing every island uses (trees, palms, bushes, flower tufts, daisies, hedges, topiaries,
#     flower beds, lamp posts, benches, harbour bits) - each draws the overhaul model at the same spot.
#   render_cams(g, out, prefix) renders the island's own CAMS, so its committed v2 renders are the "before".
# The adapters take the v2 kit's (m, x, y, z0, ...) where m is a classic mesh (world coords) or a kit Frame (local).
import bpy, math, os, sys, random, builtins, itertools
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "environment-redesign"))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "kit"))
import ohkit as O
from ohkit import at, box, cyl, lathe, sphere, tube, prism, poly, text
import props as PR
import trees as T
import hl_kit as K

CNT = itertools.count(1)
rng = random.Random(1907)
O.K.PAL.update({"lighthouse_red": (230, 62, 62), "lighthouse_white": (250, 248, 242), "hull_white": (248, 248, 244),
                "hull_blue": (52, 110, 210), "hull_red": (226, 58, 58), "deck_wood": (196, 140, 86), "sail": (252, 250, 240),
                "rope": (214, 180, 120), "lifebuoy": (255, 110, 40), "fern": (60, 150, 60), "palm_leaf": (90, 190, 70),
                "crystal_purple": (170, 100, 255), "limestone": (232, 224, 204), "limestone_dark": (200, 190, 168)})
O.K.GLOWS.update({"portal_glow": ((170, 110, 255), 1.8), "vortex_glow": ((150, 80, 240), 1.3), "beacon_glow": ((255, 230, 150), 2.4)})


def where(m, x, y, rot=0.0, z=0.0):
    if isinstance(m, K.Frame):
        wx, wy = m.p(x, y)
        return wx, wy, m.z + z, m.rot + rot
    return x, y, z, rot


def place(m, x, y, z0=0.0, rot=0.0, s=1.0):
    wx, wy, wz, r = where(m, x, y, rot, z0)
    return at(wx, wy, wz, rz=r, s=s)


# ------------------------------------------------------------------ planting
def tree(m, x, y, z0=0.0, s=1.0, kind="oak"):
    """An overhaul tree at the spot (oak / blossom / conifer / palm); returns about where its crown tops out."""
    wx, wy, wz, _ = where(m, x, y, 0.0, z0)
    i = next(CNT)
    before = set(bpy.data.objects.keys())
    if kind in ("conifer", "pine"):
        T.tree_pine(wx, wy, name="IslPine%d" % i, s=s * 0.78, seed=i)
    elif kind == "blossom":
        T.tree_blossom(wx, wy, name="IslBlossom%d" % i, s=s * 0.62, seed=i)
    elif kind == "palm":
        T.tree_palm(wx, wy, name="IslPalm%d" % i, s=s * 0.8, seed=i)
    else:
        T.tree_oak(wx, wy, name="IslOak%d" % i, s=s * 0.62, seed=i)
    if wz:
        for nm in set(bpy.data.objects.keys()) - before:
            bpy.data.objects[nm].location.z += wz
    return wz + 11 * s


def bush(m, x, y, z0=0.0, s=1.0, look="bush"):
    i = next(CNT)
    with place(m, x, y, z0, rng.uniform(0, 360)):
        return O.leafy("IslBush%d" % i, [((0, 0, 1.0 * s), 1.3 * s), ((0.8 * s, 0.35 * s, 0.8 * s), 0.95 * s), ((-0.75 * s, -0.3 * s, 0.85 * s), 0.95 * s)],
                       look=look, voxel=0.22, faces=420, lumpy=0.2, seed=i)


def flower_bush(m, x, y, z0=0.0, s=1.0, petal="flower_red"):
    obs = bush(m, x, y, z0, s)
    wx, wy, wz, _ = where(m, x, y, 0.0, z0)
    with at(wx, wy, wz):
        O.flowers_on(obs, "IslFlower_" + petal, petal, "IslFlowerMid", "flower_yel",
                     [(math.cos(a) * 0.9 * s, math.sin(a) * 0.9 * s, 6) for a in (0.4, 1.6, 2.8, 4.0, 5.2)] + [(0, 0, 6)], r=0.26 * s)


def flower_tuft(m, x, y, z0=0.0, look=None):
    petal = {"flower_blue": "speed_blue", "flower_pink": "flower_pink", "flower_yellow": "flower_yel", "daisy": "flower_white"}.get(
        look or "", rng.choice(("flower_pink", "flower_yel", "flower_white", "flower_purple")))
    O.K.PAL.setdefault("speed_blue", (64, 150, 255))
    i = next(CNT)
    with place(m, x, y, z0, rng.uniform(0, 360)):
        obs = O.leafy("IslTuft%d" % i, [((0, 0, 0.35), 0.55), ((0.45, 0.2, 0.3), 0.42), ((-0.4, -0.2, 0.3), 0.42)], voxel=0.12, faces=160,
                      lumpy=0.08, seed=i)
        O.flowers_on(obs, "IslFlower_" + petal, petal, "IslFlowerMid", "flower_yel", [(0.0, 0.0, 3), (0.4, 0.15, 3), (-0.35, -0.2, 3)], r=0.2)


def daisies(m, x, y, z0=0.0, n=None):
    wx, wy, wz, _ = where(m, x, y, 0.0, z0)
    for k in range(n or rng.randint(3, 6)):
        a, r = rng.uniform(0, math.tau), rng.uniform(0, 1.8)
        O.flower("IslDaisy", "flower_white", "IslFlowerMid", "flower_yel", (wx + math.cos(a) * r, wy + math.sin(a) * r, wz + 0.12),
                 Vector((0, 0, 1)), r=0.24)


def grass_clump(m, x, y, z0=0.0, s=1.0):
    with place(m, x, y, z0, rng.uniform(0, 360), s):
        O.tuft("IslGrass", "leaf_sun", (0, 0, 0), h=1.0, blades=7, seed=next(CNT))


def fern(m, x, y, z0=0.0, s=1.0):
    """A fern: arching fronds (flat leaflet strips) from a centre."""
    i = next(CNT)
    with place(m, x, y, z0, rng.uniform(0, 360), s):
        for k in range(7):
            a = k / 7 * math.tau + rng.uniform(-0.2, 0.2)
            ca, sa = math.cos(a), math.sin(a)
            pts = [(ca * 0.15 * t * 6, sa * 0.15 * t * 6, 0.25 + 1.2 * math.sin(math.pi * 0.55 * t)) for t in [j / 6 for j in range(7)]]
            for j in range(6):
                p0, p1 = Vector(pts[j]), Vector(pts[j + 1])
                side = Vector((-sa, ca, 0)) * (0.32 * (1 - j / 7))
                poly("IslFern", "fern", [p0 - side, p0 + side, p1 + side * 0.85, p1 - side * 0.85], thick=0.04)


def hedge_run(m, x0, y0, x1, y1, z0=0.0, h=2.4, w=2.2):
    ax, ay, az, _ = where(m, x0, y0, 0.0, z0)
    bx, by, _, _ = where(m, x1, y1)
    L = math.hypot(bx - ax, by - ay)
    if L < 0.5:
        return
    i = next(CNT)
    with at((ax + bx) / 2, (ay + by) / 2, az, rz=math.degrees(math.atan2(by - ay, bx - ax))):
        n = max(2, int(L / 0.9))
        rr = min(h, w) * 0.36
        blobs = [((-L / 2 + rr + (L - 2 * rr) * k / (n - 1), yy, zz), rr) for k in range(n) for yy in (-w * 0.17, w * 0.17) for zz in (h * 0.36, h * 0.66)]
        O.leafy("IslHedge%d" % i, blobs, look="hedge", voxel=0.3, faces=int(90 * L), lumpy=0.15, seed=i)


def topiary(m, x, y, z0=0.0, rot=0.0):
    """A clipped ball on a stem in a square limestone planter."""
    i = next(CNT)
    with place(m, x, y, z0, rot):
        box("IslTopiary_Planter", "limestone", (0, 0, 0.6), (2.4, 2.4, 1.2), bevel=0.12)
        box("IslTopiary_Rim", "gold", (0, 0, 1.22), (2.6, 2.6, 0.16), bevel=0.05)
        box("IslTopiary_Soil", "soil", (0, 0, 1.2), (2.0, 2.0, 0.12))
        cyl("IslTopiary_Stem", "wood_deep", (0, 0, 1.2), 0.16, 1.4, segs=8)
        O.leafy("IslTopiaryBall%d" % i, [((0, 0, 3.4), 1.25)], look="hedge", voxel=0.14, faces=360, lumpy=0.06, seed=i)


def flower_bed(m, veg, x, y, z0, sx, sy, rot):
    with place(m, x, y, z0, rot + (90 if sy > sx else 0), max(0.55, min(max(sx, sy) / 8.6, min(sx, sy) / 3.6))):
        PR.flower_bed()


# ------------------------------------------------------------------ street + harbour
def lamp_post(m, x, y, z0=0.0, h=7.0):
    with place(m, x, y, z0, 0.0, (h + 2.0) / 11.0):
        PR.lamp()


def bench(m, x, y, z0=0.0, rot=0.0, flip=False):
    with place(m, x, y, z0, rot + (180 if flip else 0)):
        PR.bench()


def bollard(m, x, y, z0=0.0):
    """A harbour mooring bollard (iron, rope round its waist)."""
    with place(m, x, y, z0):
        lathe("IslBollard_Iron", "iron", [(0.62, 0.0), (0.62, 0.15, True), (0.5, 0.25), (0.45, 0.85), (0.72, 1.0), (0.75, 1.18, True), (0.0, 1.2)],
              segs=14)
        tube("IslBollard_Rope", "rope", [(0.5 * math.cos(a / 10 * math.tau), 0.5 * math.sin(a / 10 * math.tau), 0.55) for a in range(11)], 0.09, segs=5,
             cap=False)


def buoy(m, x, y, z0=0.0):
    with place(m, x, y, z0):
        lathe("IslBuoy_Red", "lighthouse_red", [(0.0, -0.4), (0.9, -0.3), (1.15, 0.25, True), (1.15, 0.3, True), (0.0, 0.3)], segs=16)
        cyl("IslBuoy_White", "lighthouse_white", (0, 0, 0.3), 1.0, 0.45, segs=16, r_top=0.8)
        cyl("IslBuoy_Red", "lighthouse_red", (0, 0, 0.75), 0.8, 0.7, segs=16, r_top=0.45)
        cyl("IslBuoy_Iron", "iron", (0, 0, 1.45), 0.12, 1.0, segs=6)
        sphere("IslBuoy_Glow", "beacon_glow", (0, 0, 2.6), 0.32, sub=1)


def lifebuoy(n, c, r=0.8, face=(0, -1, 0)):
    """An orange-and-white lifebuoy ring standing at c, facing `face`."""
    M = Matrix.Translation(Vector(c)) @ Vector(face).to_track_quat("Z", "Y").to_matrix().to_4x4()
    for q in range(4):
        pts = [tuple(M @ Vector((r * math.cos(a), r * math.sin(a), 0))) for a in [(q + t / 6) * math.pi / 2 for t in range(7)]]
        tube(n + ("_Orange" if q % 2 == 0 else "_White"), "lifebuoy" if q % 2 == 0 else "lighthouse_white", pts, r * 0.32, segs=8, cap=False)


def lifebuoy_stand(m, x, y, z0=0.0, rot=0.0):
    with place(m, x, y, z0, rot):
        box("IslLifebuoy_Post", "wood_deep", (0, 0, 1.6), (0.4, 0.4, 3.2), bevel=0.05)
        box("IslLifebuoy_Post", "wood_deep", (0, 0, 3.25), (0.6, 0.6, 0.2), bevel=0.05)
        lifebuoy("IslLifebuoy", (0, -0.42, 2.3), r=0.72)


# ------------------------------------------------------------------ the sandbox
CAPTURED = []  # (camera name, the path it would have rendered, w, h) when run_island(capture_cams=True)


def render_captured(out, prefix):
    """Render the cameras a capture_cams run recorded, named <prefix><key>.jpg (key = the original file's suffix)."""
    keys = []
    sc = bpy.context.scene
    for cam_name, path, w, h in CAPTURED:
        key = os.path.basename(path).rsplit(".", 1)[0].split("_", 1)[1]
        sc.camera = bpy.data.objects[cam_name]
        sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
        sc.render.filepath = os.path.join(out, prefix + key + ".jpg")
        bpy.ops.render.render(write_still=True)
        print("rendered", sc.render.filepath)
        keys.append(key)
    return keys


class _NoSave:
    def __init__(self, wm):
        self._wm = wm

    def __getattr__(self, n):
        return getattr(self._wm, n)

    def save_as_mainfile(self, *a, **k):
        print("[island] (skipped saving the island's .blend)")
        return {"FINISHED"}


CURRENT = {"g": None}  # (the globals of the island script run_island is running / ran last)


def running(name, default=None):
    """A global of the island script being run (its REGIONS, PORTAL, SPAWN, I ...), or default outside a run."""
    g = CURRENT["g"]
    return g.get(name, default) if g else default


def in_egg_area(x, y, pad=3.0):
    """True if (x, y) is inside one of the running island's egg regions (REGIONS: name -> ((cx, cy), R, why)) + pad:
    floor clutter that looks like an egg (round, saturated, egg-sized) stays out of there (audit N2)."""
    return any(math.hypot(x - cx, y - cy) < R + pad for (cx, cy), R, _ in running("REGIONS", {}).values())


def run_island(script, out, overrides=None, argv=("norender",), capture_cams=False):
    """Run an island's v2 build script unchanged: no .blend save, its JSON writes into out, no renders of its own.
    overrides = {name: fn} swaps functions the script defines itself (their defs are renamed in the source text it
    runs; the file is untouched). capture_cams: let the script's own render loop run with K.render recording each
    camera instead of rendering (the v2 frame builds its cameras inside finish())."""
    script_dir = os.path.dirname(script)
    real_open = builtins.open

    def safe_open(path, mode="r", *a, **k):
        if "w" in mode and os.path.abspath(str(path)).startswith(script_dir):
            path = os.path.join(out, "sandbox_" + os.path.basename(str(path)))
        return real_open(path, mode, *a, **k)

    wm = bpy.ops.wm
    bpy.ops.wm = _NoSave(wm)
    old_argv, old_open = sys.argv, builtins.open
    sys.argv = [script, "--", *argv]
    builtins.open = safe_open  # (helper modules write too)
    g = {"__name__": "__main__", "__file__": script, "open": safe_open}
    g.update(overrides or {})
    CURRENT["g"] = g  # (adapters read the running script's globals through running())
    src = override_source(real_open(script).read(), list((overrides or {}).keys()))
    real_render = K.render
    CAPTURED.clear()
    if capture_cams:
        K.render = lambda scene, cam, path, w, h, hide=(): CAPTURED.append((cam.name, path, w, h))
    try:
        exec(compile(src, script, "exec"), g)
    finally:
        bpy.ops.wm = wm
        sys.argv = old_argv
        builtins.open = old_open
        K.render = real_render
    for f in os.listdir(out):
        if f.startswith("sandbox_"):
            os.remove(os.path.join(out, f))
    return g


def render_cams(g, out, prefix, skip=("topdown", "diagram", "layout"), only=None, before_dir=None, before_prefix=None):
    """Render the island's own CAMS (the same shots as its committed v2 renders)."""
    for c in bpy.data.collections:
        if any(k in c.name for k in ("Label", "Diagram", "Gameplay_Markers")):
            c.hide_render = True
    done = []
    for key, ((name, loc, look, lens), w, h) in g["CAMS"].items():
        if key in skip or (only and key not in only):
            continue
        O.render(out, prefix + key, loc, look, lens=lens, res=(1920, 1080))
        done.append(key)
    return done


def before_after(out, prefix, keys, before_dir, before_prefix):
    """Side-by-side TODAY / NEW images (PIL from the scratch venv if bpy's Python has none)."""
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("[island] (no PIL here: compose the before / afters outside Blender)")
        return
    f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Black.ttf", 40)
    for key in keys:
        bp = os.path.join(before_dir, before_prefix + key + ".jpg")
        if not os.path.exists(bp):
            continue
        b, a = Image.open(bp).convert("RGB"), Image.open(os.path.join(out, prefix + key + ".jpg")).convert("RGB")
        b.thumbnail((1000, 563)); a.thumbnail((1000, 563))
        o = Image.new("RGB", (2000, 563)); o.paste(b, (0, 0)); o.paste(a, (1000, 0))
        d = ImageDraw.Draw(o)
        for x, t in ((24, "TODAY"), (1024, "NEW")):
            d.text((x, 18), t, font=f, fill="white", stroke_width=5, stroke_fill="black")
        o.save(os.path.join(out, prefix + key + "_before_after.jpg"), quality=88)


# ------------------------------------------------------------------ dock cargo + torches (the v2 frame's dock dressing)
def barrel(m, x, y, z0=0.0, lying=False, yaw=0.0):
    with place(m, x, y, z0, yaw):
        if lying:
            with at(0, 0, 1.0):
                lathe("IslBarrel_Wood", "wood_warm", [(0.0, -1.2), (0.85, -1.2, True), (1.0, -0.6), (1.05, 0.0), (1.0, 0.6), (0.85, 1.2, True), (0.0, 1.2)],
                      segs=16, rot=(0, 90, 0))
                for xx in (-0.75, 0.75):
                    cyl("IslBarrel_Hoop", "iron", (xx - 0.08, 0, 0), 1.04, 0.16, segs=16, rot=(0, 90, 0))
        else:
            lathe("IslBarrel_Wood", "wood_warm", [(0.0, 0.0), (0.85, 0.0, True), (1.0, 0.6), (1.05, 1.2), (1.0, 1.8), (0.85, 2.4, True), (0.0, 2.4)], segs=16)
            for zz in (0.45, 1.95):
                cyl("IslBarrel_Hoop", "iron", (0, 0, zz - 0.08), 1.04, 0.16, segs=16)


def crate(m, x, y, z0=0.0, s=1.8, yaw=0.0):
    with place(m, x, y, z0, yaw, s / 2.2):
        PR.crate()


def torch(m, x, y, z0=0.0, h=5.0):
    """A dock lantern post (wood post, iron arm, a hanging lantern)."""
    with place(m, x, y, z0):
        box("IslTorch_Post", "wood_deep", (0, 0, h / 2), (0.4, 0.4, h), bevel=0.06)
        tube("IslTorch_Iron", "iron", [(0, 0, h - 0.2), (0.6, 0, h + 0.1), (1.0, 0, h - 0.1)], 0.06, segs=5)
        PR.lantern("IslTorch", (1.0, 0, h - 1.6), 0.55)


# ------------------------------------------------------------------ the v2 islands' Return Home portal (Ocean Shore's design)
def crystal(name, look, c, h, lean=(0, 0)):
    """A six-sided crystal shard with a pointed tip."""
    with at(*c):
        cyl(name, look, (0, 0, 0), h * 0.16, h * 0.7, segs=6, rot=(lean[0], lean[1], 0), smooth=False, r_top=h * 0.18)
        tip = O.xform((0, 0, 0), (lean[0], lean[1], 0)) @ Vector((0, 0, h * 0.7))
        cyl(name, look, tuple(tip), h * 0.18, h * 0.3, segs=6, rot=(lean[0], lean[1], 0), smooth=False, r_top=0.0)


# the Return Home portal's dressing, per island (Space Base: moon rock, alien moss, alien plants instead of palms; Pet Park,
# Brainrot, Food Court: their island scripts' portal_preset, audit N1). side(sgn) draws what stands beside it (default palms).
PORTAL = {"rock": "rock", "top": "rock_top", "moss": "moss", "flowers": ("flower_pink", "flower_yel"), "fern": True, "side": None}


def rock_portal(m, x, y, z, rot=0.0):
    """The escape / Return Home portal (front = local -y): a natural rock arch on craggy legs, a purple vortex down to
    the ground (a level walk-in), glowing runes, a moss cap with flowers, a purple crystal keystone, crystals + ferns at
    its feet, a flat stone base with stepping stones leading in, two palms leaning over it."""
    import ohbuild as B
    n = "IslPortal"
    with place(m, x, y, z, rot):
        r = random.Random(77)
        base = [(17 * (1 + 0.12 * math.sin(3 * a + 1.3)) * math.cos(a), 12 * (1 + 0.12 * math.sin(3 * a + 1.3)) * math.sin(a) + 1.5)
                for a in [math.tau * i / 20 for i in range(20)]]
        import bmesh
        tmp = bmesh.new()
        top = [tmp.verts.new((bx, by, 0.15)) for bx, by in base]
        bot = [tmp.verts.new((bx * 1.03, by * 1.03, -0.5)) for bx, by in base]
        tmp.faces.new(top)
        tmp.faces.new(list(reversed(bot)))
        for i in range(20):
            j = (i + 1) % 20
            tmp.faces.new((bot[i], bot[j], top[j], top[i]))
        bmesh.ops.triangulate(tmp, faces=[f for f in tmp.faces if len(f.verts) > 4])
        O._merge(n + "_Base", PORTAL["top"], tmp, Matrix.Identity(4))
        for k, ly in enumerate((-15.5, -20.5, -25.5, -30.5)):
            O.rock(n + "_Step", n + "_StepTop", ((k % 2) * 1.6 - 0.8, ly, -0.25), 2.1, seed=k + 40, squash=0.2, look=PORTAL["rock"], top=PORTAL["top"])
        W, Hs = 19.6, 22.4
        B.ring(n + "_Arch", PORTAL["rock"], B.opening(W, Hs, True, n=16, grow=3.2), B.opening(W, Hs, True, n=16), -1.9, 1.9)
        for k in range(12):  # craggy rocks along the arch so it reads as natural stone, not a ring
            a = math.radians(-30 + k * 240 / 11)
            O.rock(n + "_Arch", n + "_ArchTop", (11.4 * math.cos(a), r.uniform(-0.8, 0.8), 12.6 + 11.4 * math.sin(a)), r.uniform(2.0, 2.8),
                   seed=k, squash=0.85, look=PORTAL["rock"], top=PORTAL["top"], top_at=0.75)
        prism(n + "_Vortex", "vortex_glow", B.opening(W, Hs, True, n=16), 0.4)
        for r0, a0, a1 in ((4.6, 20, 200), (6.8, 200, 380), (3.4, 110, 290)):
            tube(n + "_Swirl", "portal_glow", [(r0 * math.cos(math.radians(a)), -0.3, 12.1 + r0 * math.sin(math.radians(a))) for a in range(a0, a1 + 1, 15)],
                 0.18, segs=6)
        cyl(n + "_Swirl", "portal_glow", (0, -0.25, 12.1), 2.4, 0.1, segs=24, rot=(90, 0, 0))
        for k in range(9):
            a = math.radians(-20 + 12 + k * 196 / 8)
            for fy in (-1.93, 1.93):
                box(n + "_Rune", "portal_glow", (11.4 * math.cos(a), fy, 12.6 + 11.4 * math.sin(a)), (0.9, 0.16, 0.9), rot=(0, -math.degrees(a), 0),
                    bevel=0.08)
        for sgn in (-1, 1):
            for (lx, ly, rr, sq) in ((11.4, 0, 3.4, 0.9), (16.0, 1.0, 3.2, 0.7), (19.2, 3.2, 2.2, 0.6), (11.0, -3.6, 1.6, 0.7)):
                O.rock(n + "_Leg", n + "_LegMoss", (sgn * lx, ly, 0.3), rr, seed=int(lx * 10) + sgn, squash=sq, look=PORTAL["rock"], top=PORTAL["moss"],
                       top_at=0.6)
            for k in range(3):
                crystal(n + "_Crystal", "crystal_purple", (sgn * (8.2 + k * 1.3), -4.2 - k * 0.8, 0.1), 2.6 + k * 0.9, lean=(12, sgn * 16))
            if PORTAL["fern"]:
                fern(O_NONE, sgn * 18.5, 2.5, 0.1, 1.1)
        obs = O.leafy(n + "Cap", [((math.cos(math.radians(a)) * 13.4, 0, 12.6 + math.sin(math.radians(a)) * 13.4), 1.5) for a in range(50, 131, 12)],
                      look=PORTAL["moss"], voxel=0.22, faces=520, lumpy=0.14, seed=31)
        if PORTAL["flowers"]:
            O.flowers_on(obs, n + "_Flower", PORTAL["flowers"][0], n + "_FlowerMid", PORTAL["flowers"][1],
                         [(math.cos(math.radians(a)) * 13.0, r.uniform(-1.0, 1.0), 40) for a in range(58, 126, 9)], r=0.3)
        for k, (lx, h, lean) in enumerate(((0, 5.0, 0), (-1.4, 3.6, -16), (1.4, 3.8, 16), (-0.6, 2.6, -8), (0.8, 2.8, 8))):
            crystal(n + "_Crystal", "crystal_purple", (lx, 0.2 * (k % 2), 25.6), h, lean=(0, lean))
        lathe(n + "_Glow", "portal_glow", [(9.5, 0.17), (11.5, 0.17), (11.5, 0.24), (9.5, 0.24)], segs=40)
    for sgn in (-1, 1):
        wx, wy, wz, rr_ = where(m, x, y, rot, z)
        c, s_ = math.cos(math.radians(rr_)), math.sin(math.radians(rr_))
        lx, ly = sgn * 13.5, 7.5
        if PORTAL["side"]:  # (side_local: the side's axes turn with the portal, +x outward for sgn 1, -y toward its front)
            with at(wx + lx * c - ly * s_, wy + lx * s_ + ly * c, wz + 0.1, rz=rr_ if PORTAL.get("side_local") else 0.0):
                PORTAL["side"](sgn)
        else:
            tree(O_NONE, wx + lx * c - ly * s_, wy + lx * s_ + ly * c, wz + 0.1, 1.9, "palm")


class _NoFrame:
    pass


O_NONE = _NoFrame()


def override_source(src, names):
    """Rename the script's own `def name(` so a global of that name (an overhaul adapter) is used instead."""
    for nm in names:
        assert ("def %s(" % nm) in src, nm
        src = src.replace("def %s(" % nm, "def _v2_%s(" % nm)
    return src


def render_places(I, out, prefix, names, dist=36.0, height=12.0, look_up=6.0, lens=28):
    """Close-up renders of named landmarks (the v2 frame's LAYOUT["places"]): a camera between the island's middle and the
    landmark, looking at it (they face the middle). A name can be (name, dist, height, look_up) for a tall landmark."""
    places = {p["name"]: p["blender_xy"] for p in I.LAYOUT["places"]}
    cx, cy = I.center
    done = []
    d0, h0, u0 = dist, height, look_up
    for nm in names:
        nm, dist, height, look_up = nm if isinstance(nm, tuple) else (nm, d0, h0, u0)
        if nm not in places:
            print("[island] no place", nm)
            continue
        x, y = places[nm]
        d = Vector((cx - x, cy - y, 0)).normalized()
        side = Vector((-d.y, d.x, 0)) * dist * 0.35
        cam = (x + d.x * dist + side.x, y + d.y * dist + side.y, I.Z + height)
        key = "place_" + "".join(ch for ch in nm.lower() if ch.isalnum())
        O.render(out, prefix + key, cam, (x, y, I.Z + look_up), lens=lens, res=(1600, 900))
        done.append(key)
    return done


def patch_v2_common():
    """The swaps every island on the shared v2 frame (hl_v2) needs: Briefcase Bay v2's park trees / topiaries / flower
    beds, Ocean Shore v2's bushes / hibiscus / grass / palms / dock torches / cargo, and the Return Home rock portal."""
    import importlib
    for p in (os.path.join(ROOT, "briefcase_bay_v2"), os.path.join(ROOT, "ocean_shore_v2")):
        if p not in sys.path:
            sys.path.insert(0, p)
    OD = importlib.import_module("osv2_detail")  # (the v2 frame's own palette - hl_v2 builds on Ocean Shore's)
    OP = importlib.import_module("osv2_parts")
    keep = {d: dict(getattr(K, d)) for d in ("PAL", "GLOWS", "GLASS")}
    BD = importlib.import_module("bbv2_detail")  # (its palette re-tints shared names like rock_grey / dirt_rim: undo that)
    for d, vals in keep.items():
        getattr(K, d).update(vals)
    BD.park_tree = lambda m, x, y, z0, s=1.0, kind="oak": tree(m, x, y, z0, s, kind)
    BD.topiary = lambda m, x, y, z0, rot=0.0: topiary(m, x, y, z0, rot)
    BD.flower_bed = lambda m, veg, x, y, z0, sx, sy, rot: flower_bed(m, veg, x, y, z0, sx, sy, rot)
    OD.bush = lambda m, x, y, z0, s=1.0, look=None: bush(m, x, y, z0, s)
    OD.hibiscus = lambda m, x, y, z0, s=1.0: flower_bush(m, x, y, z0, s * 0.8, "flower_red")
    OD.grass_clump = lambda m, x, y, z0, s=1.0: grass_clump(m, x, y, z0, s)
    OD.palm2 = lambda m, x, y, z0, style=None, h=None, lean=None: tree(m, x, y, z0, (h or 10.0) / 10.0, "palm")
    OD.torch = lambda m, x, y, z0, h=5.0: torch(m, x, y, z0, h)
    OD.crate = lambda m, x, y, z0, s=1.8, yaw=0.0: crate(m, x, y, z0, s, yaw)
    OD.barrel = lambda m, x, y, z0, lying=False, yaw=0.0: barrel(m, x, y, z0, lying, yaw)
    OP.escape_portal = lambda m, x, y, z, rot=0.0: rock_portal(m, x, y, z, rot)
    return BD, OD, OP
