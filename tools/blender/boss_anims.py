# tools/blender/boss_anims.py - the bosses' ATTACK ANIMATIONS (docs/BOSS_ANIMATION.md, 2026-10-19 overhaul): the
# shared ENGINE. Each boss has two files in tools/blender/boss_clips/: <boss>.py (its server timeline, the clips as
# pose keys with per-key easing - back-out snaps, expo launches, settles - plus baked trembles / cycles, and CLIPS) and
# <boss>_preview.py (its preview scene: ground, players, floor warnings, effects, cameras, the baked timeline, BOARD).
# The engine rebuilds the boss from tools/zones/bosses.json (exactly what Studio gets) as one empty per animation
# GROUP at its joint, execs the boss's files in this namespace, bakes the preview at the SERVER's exact timing, and
# exports every boss's clips to tools/zones/boss_anims.json + src/BossAnims.lua (ReplicatedStorage.Shared.BossAnims,
# generated; other bosses' clips already in the JSON are kept as they are).
# Bosses: Megalodon (FIN CHARGE, the benchmark), SeniorPartner (BRIEFCASE SWING), BigCheese (CHEESE ROLL).
# Args after --:  boss=<Model> (default Megalodon)
#                 check   -> per-frame clipping check (every block of a group vs every other group's blocks)
#                 stills  -> <OUT_DIR>/board_*.png (storyboard frames)
#                 frames  -> $BOSS_FRAMES/<cam>/ (PNG sequences, for tools/blender/encode_preview.py); cam=cine|game|...
# Mac:  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/boss_anims.py -- boss=SeniorPartner check stills
# Units: 1 Blender m = 1 stud; boss model units x SCALE in the preview; bosses FACE +Y (= Roblox -Z), Z up.
import bpy, math, json, os, sys, random
from mathutils import Euler, Matrix, Vector


def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    try:
        return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    except NameError:
        return r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"


REPO = find_repo()
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
FRAMES_DIR = os.environ.get("BOSS_FRAMES", os.path.join(REPO, "_boss_frames"))
FPS = 30
BOSS = next((a.split("=", 1)[1] for a in ARGS if a.startswith("boss=")), "Megalodon")
SPECS = {"Megalodon": "megalodon", "SeniorPartner": "senior_partner", "BigCheese": "big_cheese"}  # boss -> its files in tools/blender/boss_clips/
SPEC_DIR = os.path.join(REPO, "tools", "blender", "boss_clips")
TURN = (0.04, 0.2)  # the client's whip-round turn in the windup: hold, then back-out over this long (a spec may change it)
LEAD = ("Torso", 0.35)  # which group leads the turn, and by how much of the angle still to go
FX_CHANNELS = ()
CHECK_SKIP_PARTS, CHECK_SKIP_GROUPS = (), ()  # blocks / groups the clipping check leaves out (they sit inside by design)
CHECK_FOLDS = ()  # (group, group) pairs whose overlap is a joint's fold (a leg top inside the hips): reported apart


def check_fold(ga, gb, state, tl):  # a spec may replace this (a fold only in some states / times)
    return (ga, gb) in CHECK_FOLDS or (gb, ga) in CHECK_FOLDS


ROLL_LIFT = None  # a rolling boss (Big Cheese): how far its block wheel lifts at each roll angle (exported RollLift)

rng = random.Random(7)


def run_spec(suffix):
    path = os.path.join(SPEC_DIR, SPECS[BOSS] + suffix + ".py")
    exec(compile(open(path).read(), path, "exec"), globals())

# ===================================================================================== pose maths
EASE = {
    "lin": lambda a: a,
    "io": lambda a: a * a * (3 - 2 * a),
    "out": lambda a: 1 - (1 - a) ** 3,
    "in": lambda a: a ** 3,
    "back": lambda a: 1 + 2.70158 * (a - 1) ** 3 + 1.70158 * (a - 1) ** 2,
    "expo": lambda a: 1.0 if a >= 1 else 1 - 2 ** (-10 * a),
}


def ev(keys, t):
    """Pose keys [(t, value, ease into this key)], held before the first and after the last."""
    if t <= keys[0][0]:
        return keys[0][1]
    for i in range(1, len(keys)):
        t1, v1 = keys[i][0], keys[i][1]
        e = keys[i][2] if len(keys[i]) > 2 else "io"
        t0, v0 = keys[i - 1][0], keys[i - 1][1]
        if t <= t1:
            a = (t - t0) / (t1 - t0) if t1 > t0 else 1.0
            return v0 + (v1 - v0) * EASE[e](max(0.0, min(1.0, a)))
    return keys[-1][1]


def ramp(t, a, b):
    return EASE["io"](max(0.0, min(1.0, (t - a) / (b - a))))


DATA = json.load(open(os.path.join(REPO, "tools", "zones", "bosses.json")))[BOSS]
GROUPS = list(DATA["groups"].keys())

def zero():
    # g[group] = [rx, ry, rz, px, py, pz] (Blender axes, about the joint; p = model units)
    # root = [x, y, z, rx, ry, rz, sx, sy, sz] (around the feet); fx = named 0..1 channels (the boss's FX_CHANNELS)
    return {"g": {g: [0.0] * 6 for g in GROUPS}, "root": [0.0] * 6 + [1.0] * 3, "fx": {k: 0.0 for k in FX_CHANNELS}}


def lerp_pose(a, b, w):
    p = zero()
    for g in GROUPS:
        p["g"][g] = [x + (y - x) * w for x, y in zip(a["g"][g], b["g"][g])]
    p["root"] = [x + (y - x) * w for x, y in zip(a["root"], b["root"])]
    p["fx"] = {k: a["fx"][k] + (b["fx"][k] - a["fx"][k]) * w for k in a["fx"]}
    return p


def squash(r, sz):  # vertical squash, volume kept
    r[6] = r[7] = 1 / math.sqrt(sz)
    r[8] = sz


def stretch(r, sy):  # stretched along the run, volume kept
    r[7] = sy
    r[6] = r[8] = 1 / math.sqrt(sy)


def post(p):  # a spec may replace this: every clip frame passes through it (e.g. the Megalodon's cheek flaps)
    return p


# ===================================================================================== the boss's clips
run_spec("")
os.makedirs(OUT_DIR, exist_ok=True)

# ===================================================================================== the client's turn (code)
def back_out(a):
    return EASE["back"](max(0.0, min(1.0, a)))


def turn_yaw(y0, y1, t):  # windup t: holds TURN[0] s, then turns round with an overshoot over TURN[1] s
    d = (y1 - y0 + math.pi) % (2 * math.pi) - math.pi
    return y0 + d * back_out((t - TURN[0]) / TURN[1])


# ===================================================================================== export (JSON + Luau)
MX = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))  # Blender (x, y, z) -> Roblox (x, z, -y)


def rbx_quat(rx, ry, rz):
    m = MX @ Euler((rx, ry, rz), "XYZ").to_matrix() @ MX.transposed()
    q = m.to_quaternion()
    return [q.x, q.y, q.z, q.w]


def fmt(v):
    s = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def export():
    out = {"fps": FPS, "clips": {}}
    for name, (fn, length, loops) in CLIPS.items():
        n = int(round(length * FPS)) + 1
        frames = [post(fn(min(length, i / FPS))) for i in range(n)]
        groups = {}
        for g in GROUPS:
            rot, pos = [], []
            for f in frames:
                v = f["g"][g]
                rot += rbx_quat(v[0], v[1], v[2])
                pos += [v[3], v[5], -v[4]]
            entry = {}
            if any(abs(x) > 1e-4 for i, x in enumerate(rot) if i % 4 != 3):
                entry["r"] = [round(x, 4) for x in rot]
            if any(abs(x) > 1e-4 for x in pos):
                entry["p"] = [round(x, 4) for x in pos]
            if entry:
                groups[g] = entry
        root = []
        for f in frames:
            v = f["root"]
            root += [v[0], v[2], -v[1]] + rbx_quat(v[3], v[4], v[5]) + [v[6], v[8], v[7]]
        fx = {k: [round(f["fx"][k], 4) for f in frames] for k in frames[0]["fx"]}
        out["clips"][name] = {"length": round(length, 4), "loop": loops, "frames": n, "groups": groups,
                              "root": [round(x, 4) for x in root], "fx": fx}
    if ROLL_LIFT:
        out["rolllift"] = [round(x, 4) for x in ROLL_LIFT]
    if TURN != (0.04, 0.2) or LEAD != ("Torso", 0.35):  # (the client's default turn; a boss that turns differently carries it)
        out["turn"] = [round(TURN[0], 4), round(TURN[1], 4), LEAD[0], round(LEAD[1], 4)]
    path = os.path.join(REPO, "tools", "zones", "boss_anims.json")
    allc = json.load(open(path)) if os.path.exists(path) else {}
    allc[BOSS] = out
    with open(path, "w") as fh:
        json.dump(allc, fh, separators=(",", ":"))
    write_luau(allc)
    return {k: v["frames"] for k, v in out["clips"].items()}


def write_luau(allc):
    L = ["--!strict", "-- ReplicatedStorage.Shared.BossAnims - GENERATED by tools/blender/boss_anims.py from the Blender clips",
         "-- (docs/BOSS_ANIMATION.md). Do not edit by hand: change the Blender script and re-run it.",
         "-- Boss -> { Fps, Clips = { name -> { Length, Loop, Frames, Groups = { group -> { R = quats xyzw, P? = offsets",
         "-- (model units, Roblox axes) } }, Root = per frame px py pz qx qy qz qw sx sy sz, Fx = { channel -> values } } } }.",
         "-- Channels are stored as comma strings (a few thousand numbers) and unpacked once on require.",
         "-- Turn? = { Hold, Time, Lead, LeadBy }: the windup's turn (hold, then back-out over Time; group Lead leads it by",
         "-- LeadBy of the angle left). Without it: 0.04 / 0.2, the Torso by 0.35 (the Megalodon's whip-round).",
         "-- RollLift? = a rolling boss's lift (model units) at evenly spaced roll angles over a turn: its block wheel bumps.",
         "", "local function unpack(s: string): { number }", "\tlocal t = {}", "\tfor _, v in string.split(s, \",\") do",
         "\t\ttable.insert(t, tonumber(v) :: number)", "\tend", "\treturn t", "end", "", "local Anims = {"]
    for boss, d in allc.items():
        L.append("\t%s = {" % boss)
        L.append("\t\tFps = %d," % d["fps"])
        if "rolllift" in d:
            L.append('\t\tRollLift = unpack("%s"),' % ",".join(fmt(x) for x in d["rolllift"]))
        if "turn" in d:
            L.append('\t\tTurn = { Hold = %s, Time = %s, Lead = "%s", LeadBy = %s },' % (fmt(d["turn"][0]), fmt(d["turn"][1]), d["turn"][2], fmt(d["turn"][3])))
        L.append("\t\tClips = {")
        for name, c in d["clips"].items():
            L.append("\t\t\t%s = {" % name)
            L.append("\t\t\t\tLength = %s, Loop = %s, Frames = %d," % (fmt(c["length"]), "true" if c["loop"] else "false", c["frames"]))
            L.append("\t\t\t\tGroups = {")
            for g, e in c["groups"].items():
                parts = ['R = unpack("%s")' % ",".join(fmt(x) for x in e["r"])] if "r" in e else []
                if "p" in e:
                    parts.append('P = unpack("%s")' % ",".join(fmt(x) for x in e["p"]))
                L.append("\t\t\t\t\t%s = { %s }," % (g, ", ".join(parts)))
            L.append("\t\t\t\t},")
            L.append('\t\t\t\tRoot = unpack("%s"),' % ",".join(fmt(x) for x in c["root"]))
            L.append("\t\t\t\tFx = { %s }," % ", ".join('%s = unpack("%s")' % (k, ",".join(fmt(x) for x in v)) for k, v in c["fx"].items()))
            L.append("\t\t\t},")
        L.append("\t\t},")
        L.append("\t},")
    L += ["}", "", "return Anims", ""]
    with open(os.path.join(REPO, "src", "BossAnims.lua"), "w") as fh:
        fh.write("\n".join(L))


# ===================================================================================== the preview scene
def clear_scene():
    sc = bpy.context.scene
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    return sc


SC = clear_scene()
SC.name = SCENE_NAME
SC.render.fps = FPS
SC.frame_start, SC.frame_end = 0, int(round(T_END * FPS))
for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try:
        SC.render.engine = eng
        break
    except TypeError:
        pass
SC.render.resolution_x, SC.render.resolution_y = 1280, 720
SC.view_settings.view_transform = "Standard"
try:
    SC.eevee.taa_render_samples = 24
except AttributeError:
    pass
world = bpy.data.worlds.new("Sky")
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (0.52, 0.74, 1.0, 1)
bg.inputs[1].default_value = 0.75
SC.world = world

cube_me = bpy.data.meshes.new("BA_Cube")
cube_me.from_pydata([(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)], [],
                    [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
cube_me.update()


def material(name, emit=0.0, alpha_attr=None, rough=0.55):
    """Base colour = the object's colour; emission strength = emit x the object's "glow" property; optional alpha."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    info = nt.nodes.new("ShaderNodeObjectInfo")
    nt.links.new(info.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(info.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Roughness"].default_value = rough
    glow = nt.nodes.new("ShaderNodeAttribute")
    glow.attribute_type = "OBJECT"
    glow.attribute_name = "glow"
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = emit
    nt.links.new(glow.outputs["Fac"], mul.inputs[0])
    nt.links.new(mul.outputs[0], bsdf.inputs["Emission Strength"])
    if alpha_attr:
        al = nt.nodes.new("ShaderNodeAttribute")
        al.attribute_type = "OBJECT"
        al.attribute_name = alpha_attr
        nt.links.new(al.outputs["Fac"], bsdf.inputs["Alpha"])
        try:
            m.surface_render_method = "BLENDED"
        except (AttributeError, TypeError):
            m.blend_method = "BLEND"
    return m


MAT_BLOCK = material("Block", emit=4.0)
MAT_FX = material("Fx", emit=3.0, alpha_attr="alpha")
MAT_WARN = material("Warn", emit=2.2, alpha_attr="alpha", rough=1.0)


def set_mat(o, mat):
    """Every block shares one mesh, so the material is linked to the OBJECT (not the mesh)."""
    if not o.data.materials:
        o.data.materials.append(MAT_BLOCK)
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = mat


def lin(col):  # the game's sRGB colour -> the linear colour the shader wants
    return tuple(((c / 255) ** 2.2) for c in col) + (1,)


def block(name, size, col, parent=None, loc=(0, 0, 0), mat=MAT_BLOCK, glow=0.0):
    o = bpy.data.objects.new(name, cube_me)
    o.scale = size
    o.location = loc
    o.color = lin(col)
    o["glow"] = glow
    o["alpha"] = 1.0
    set_mat(o, mat)
    SC.collection.objects.link(o)
    if parent:
        o.parent = parent
    return o


def empty(name, parent=None, loc=(0, 0, 0)):
    o = bpy.data.objects.new(name, None)
    o.empty_display_size = 0.3
    o.location = loc
    SC.collection.objects.link(o)
    if parent:
        o.parent = parent
    return o


def rbx2bl(v):
    return Vector((v[0], -v[2], v[1]))


# ------------------------------------------------------------------ the boss, from bosses.json
BOSS_E = empty("Boss")
BOSS_E.scale = (SCALE,) * 3
ROOT_E = empty("Root", BOSS_E)
JOINT = {g: rbx2bl(d["joint"]) for g, d in DATA["groups"].items()}
GE, REST = {}, {}


def make_group(g):
    if g in GE:
        return GE[g]
    par = DATA["groups"][g]["parent"]
    pe = make_group(par) if par else ROOT_E
    rest = JOINT[g] - (JOINT[par] if par else Vector((0, 0, 0)))
    e = empty("G_" + g, pe, rest)
    e.rotation_mode = "XYZ"
    GE[g], REST[g] = e, rest
    return e


for g in GROUPS:
    make_group(g)
GLOW_PARTS = []  # blocks tagged "glow" (lit by an fx channel, e.g. the FinGlow)
for prt in DATA["parts"]:
    g = prt["g"]
    r = prt["r"]
    R = MX.transposed() @ Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8]))) @ MX
    o = bpy.data.objects.new(prt["n"], cube_me)
    SC.collection.objects.link(o)
    o.parent = GE[g]
    loc = rbx2bl(prt["p"]) - JOINT[g]
    o.matrix_basis = Matrix.Translation(loc) @ R.to_4x4() @ Matrix.Diagonal((prt["s"][0], prt["s"][2], prt["s"][1], 1))
    c = prt["c"]
    o.color = lin(c)
    o["glow"] = 1.0 if prt["t"] == "neon" else 0.0
    o["alpha"] = 1.0
    set_mat(o, MAT_BLOCK)
    if prt["t"] == "glow":
        set_mat(o, MAT_FX)
        o["alpha"] = 0.0
        GLOW_PARTS.append(o)


def avatar(name, col, x, y):
    e = empty(name, loc=(x, y, 0))
    block("Legs", (2, 1, 2), (40, 50, 90), e, (0, 0, 1))
    block("Torso", (2, 1, 2), col, e, (0, 0, 3))
    block("Head", (1.2, 1.2, 1.2), (250, 210, 160), e, (0, 0, 4.6))
    for sx in (-1, 1):
        block("Arm", (0.9, 0.9, 1.9), col, e, (sx * 1.45, 0, 3.05))
    eggs = []
    for i, ec in enumerate(((255, 230, 120), (140, 220, 255), (255, 150, 200))):
        eggs.append(block("Egg", (1.3, 1.3, 1.6), ec, e, (0, 0.2, 5.9 + i * 1.5), glow=0.0))
    return e, eggs


def warn_set(name, length, width, arrows=3):
    e = empty(name)
    strip = block("Strip", (1, 1, 0.1), COLOR, e, mat=MAT_WARN, glow=0.6)
    sides = [block("Side", (0.8, 1, 0.16), COLOR, e, mat=MAT_WARN, glow=1.0) for _ in (0, 1)]
    arr = [block("Arrow", (1, 1.4, 0.14), (255, 255, 255), e, mat=MAT_WARN, glow=0.8) for _ in range(arrows)]
    return dict(e=e, strip=strip, sides=sides, arrows=arr, length=length, width=width)


def pose_warn(w, start, direction, grow, t, visible):
    yaw = math.atan2(-direction.x, direction.y)
    w["e"].location = (start.x, start.y, 0.06)
    w["e"].rotation_euler = (0, 0, yaw)
    ln = max(1.0, w["length"] * grow)
    pulse = 0.5 + 0.5 * math.sin(t * 18)
    vis = 1.0 if visible else 0.0
    w["strip"].scale = (w["width"], ln, 0.1)
    w["strip"].location = (0, ln / 2, 0)
    w["strip"]["alpha"] = (0.4 - 0.2 * pulse) * vis
    for i, s in enumerate(w["sides"]):
        s.scale = (0.8, ln, 0.16)
        s.location = ((-1 if i == 0 else 1) * w["width"] / 2, ln / 2, 0.02)
        s["alpha"] = (0.85 - 0.35 * pulse) * vis
    for i, a in enumerate(w["arrows"]):
        along = (t * 40 + (i + 1) * ln / len(w["arrows"])) % ln
        a.scale = (w["width"] * 0.45, 1.4, 0.14)
        a.location = (0, along, 0.03)
        a["alpha"] = 0.75 * vis


# ------------------------------------------------------------------ effects (cartoon puffs, streaks, sparks)
FX = []  # (obj, t0, life, p0, vel, grav, size curve keys, base scale, spin)
MAT_SAND = MAT_BLOCK


def spawn(kind, t0, life, p0, vel, grav=0.0, size=1.0, col=(240, 222, 180), glow=0.0, stretch_axis=None, spin=0.0):
    shape = {"puff": (1, 1, 1), "spark": (0.35, 0.35, 0.35), "drop": (0.5, 0.5, 0.7), "streak": (0.22, 1, 0.22),
             "paper": (1.0, 1.3, 0.05), "chunk": (0.6, 0.6, 0.6)}[kind]
    o = block("fx_" + kind, (0.001,) * 3, col, glow=glow, mat=MAT_FX)
    o["alpha"] = 0.95 if kind != "streak" else 0.85
    FX.append(dict(o=o, t0=t0, life=life, p0=Vector(p0), vel=Vector(vel), grav=grav, size=size, shape=shape,
                   kind=kind, spin=spin, rot=(rng.random() * 6, rng.random() * 6, rng.random() * 6)))


def fx_scale(f, a):
    if f["kind"] == "streak":  # appears full length, shrinks to nothing along its length
        k = 1 - a
        return (f["shape"][0], f["size"] * k, f["shape"][2])
    if f["kind"] in ("paper", "chunk"):  # full size from the start, gone over its last fifth
        return tuple(s * f["size"] * min(1.0, a / 0.06) * (1.0 if a < 0.8 else (1 - a) / 0.2) for s in f["shape"])
    k = (a / 0.15) if a < 0.15 else (1 - (a - 0.15) / 0.85) ** 0.7
    k *= f["size"] * (0.7 + 0.6 * a if f["kind"] == "puff" else 1)
    return tuple(s * k for s in f["shape"])


# ------------------------------------------------------------------ lights + cameras
sun_d = bpy.data.lights.new("Sun", "SUN")
sun_d.energy = 2.3
sun_d.angle = math.radians(8)
sun = bpy.data.objects.new("Sun", sun_d)
sun.rotation_euler = (math.radians(50), 0, math.radians(35))
SC.collection.objects.link(sun)


def camera(name, loc, target, lens):
    cd = bpy.data.cameras.new(name)
    cd.lens = lens
    cd.clip_end = 2000
    c = bpy.data.objects.new(name, cd)
    SC.collection.objects.link(c)
    c.location = loc
    d = Vector(target) - Vector(loc)
    c.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return c


def key_boss(fr, pos, yaw, pose):
    """Key the boss at frame fr: where it stands, its facing, the root (offset / tilt / squash) and every group."""
    BOSS_E.location = pos
    BOSS_E.rotation_euler = (0, 0, yaw)
    r = pose["root"]
    ROOT_E.location = (r[0], r[1], r[2])
    ROOT_E.rotation_euler = (r[3], r[4], r[5])
    ROOT_E.scale = (r[6], r[7], r[8])
    for o in (BOSS_E, ROOT_E):
        for k in ("location", "rotation_euler", "scale"):
            o.keyframe_insert(k, frame=fr)
    for g in GROUPS:
        v = pose["g"][g]
        e = GE[g]
        e.rotation_euler = (v[0], v[1], v[2])
        e.location = REST[g] + Vector((v[3], v[4], v[5]))
        e.keyframe_insert("rotation_euler", frame=fr)
        e.keyframe_insert("location", frame=fr)


def group_blocks(g):
    return [o for o in GE[g].children if o.type == "MESH"]


def lowest_point(objs):
    """The lowest world corner of these blocks (at the current frame)."""
    best = None
    for o in objs:
        for c in ((x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)):
            w = o.matrix_world @ Vector(c)
            if best is None or w.z < best.z:
                best = w
    return best


def key_fx():
    """Each scheduled puff / spark / streak keyed over its life."""
    for f in FX:
        o = f["o"]
        f0 = int(math.floor(f["t0"] * FPS))
        f1 = int(math.ceil((f["t0"] + f["life"]) * FPS))
        o.scale = (0, 0, 0)
        o.keyframe_insert("scale", frame=max(SC.frame_start, f0 - 1))
        for fr in range(f0, f1 + 1):
            k = (fr / FPS - f["t0"])
            a = max(0.0, min(1.0, k / f["life"]))
            p = f["p0"] + f["vel"] * k + Vector((0, 0, 0.5 * f["grav"] * k * k))
            p.z = max(0.2, p.z)
            o.location = p
            o.scale = fx_scale(f, a) if fr < f1 else (0, 0, 0)
            o.rotation_euler = (0, 0, 0) if f["kind"] == "streak" else tuple(x + f["spin"] * k * (1 + 0.4 * i) for i, x in enumerate(f["rot"]))
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("scale", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


# ===================================================================================== clipping check
def clip_check():
    """Max depth (studs) any block of one group goes into another group's block, per state, beyond the rest pose's own
    overlap (joints overlap at rest by design). Prints the worst offenders."""
    parts = [o for o in bpy.data.objects if o.parent and o.parent.name.startswith("G_") and o.type == "MESH"
             and o.name.split(".")[0] not in CHECK_SKIP_PARTS and o.parent.name[2:] not in CHECK_SKIP_GROUPS]
    pts = [Vector((x, y, z)) for x in (-0.5, 0, 0.5) for y in (-0.5, 0, 0.5) for z in (-0.5, 0, 0.5)]

    hinge = 0.6 * SCALE  # (points this close to either group's joint are the hinge's own overlap)

    def depth(a, b):  # how deep a's sample points go inside box b (world studs)
        inv = b.matrix_world.inverted()
        sc_b = b.matrix_world.to_scale()
        ja, jb = a.parent.matrix_world.translation, b.parent.matrix_world.translation
        best = 0.0
        for p in pts:
            w = a.matrix_world @ p
            if (w - ja).length < hinge or (w - jb).length < hinge:
                continue
            l = inv @ w
            if abs(l.x) < 0.5 and abs(l.y) < 0.5 and abs(l.z) < 0.5:
                best = max(best, min((0.5 - abs(l.x)) * sc_b.x, (0.5 - abs(l.y)) * sc_b.y, (0.5 - abs(l.z)) * sc_b.z))
        return best

    pairs = [(a, b) for a in parts for b in parts if a.parent != b.parent]
    SC.frame_set(0)
    base = {}
    for f0 in (0, 3, 6, 9, 12):  # rest = the walk (its own overlaps are the model's)
        SC.frame_set(f0)
        for a, b in pairs:
            base[(a.name, b.name)] = max(base.get((a.name, b.name), 0.0), depth(a, b))
    worst, folds = {}, {}
    for fr in range(SC.frame_start, SC.frame_end + 1):
        SC.frame_set(fr)
        st, tl = boss_state(fr / FPS)[0:2]
        for a, b in pairs:
            d = depth(a, b) - base[(a.name, b.name)]
            if d > 0.25:
                key = (a.parent.name, a.name, b.parent.name, b.name)
                into = folds if check_fold(key[0][2:], key[2][2:], st, tl) else worst
                if d > into.get(key, (0, 0, ""))[0]:
                    into[key] = (d, fr, st)
    sink = (0.0, 0, "", "")  # the deepest any block goes into the ground (the floor is z = 0) in the clips
    for fr in range(SC.frame_start, SC.frame_end + 1):
        if boss_state(fr / FPS)[0] == "walk":
            continue  # (the walk is the game's own procedural walk, not a clip)
        SC.frame_set(fr)
        for o in parts:
            z = lowest_point([o]).z
            if -z > sink[0]:
                sink = (-z, fr, boss_state(fr / FPS)[0], o.parent.name + "/" + o.name)
    print("ground: deepest %.2f studs below the floor, frame %d (%s) %s" % sink)
    for k, (d, fr, st) in sorted(worst.items(), key=lambda kv: -kv[1][0])[:25]:
        print("CLIP %.2f studs  frame %d (%s)  %s/%s into %s/%s" % (d, fr, st, k[0], k[1], k[2], k[3]))
    print("clip check: %d pairs over 0.25 studs" % len(worst))
    if folds:
        k, (d, fr, st) = max(folds.items(), key=lambda kv: kv[1][0])
        print("folds (hidden by design: a joint's fold, a tucked limb): deepest %.2f studs, frame %d (%s) %s/%s into %s/%s"
              % (d, fr, st, k[0], k[1], k[2], k[3]))


# ===================================================================================== run
run_spec("_preview")  # the boss's preview scene (ground, players, warnings, effects, cameras, bake, BOARD)
bake()
print("clips:", export())
cine_cuts()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, BLEND), compress=True)
if "check" in ARGS:
    clip_check()

if "stills" in ARGS:
    SC.timeline_markers.clear()  # (camera markers would override the board's cameras)
    SC.render.resolution_x, SC.render.resolution_y = 960, 540
    SC.render.image_settings.file_format = "PNG"
    for T, cam, name in BOARD:
        SC.frame_set(int(round(T * FPS)))
        SC.camera = cam
        SC.render.filepath = os.path.join(OUT_DIR, "board_%s.png" % name)
        bpy.ops.render.render(write_still=True)
if "frames" in ARGS:
    SC.render.resolution_x, SC.render.resolution_y = 1280, 720
    SC.render.image_settings.file_format = "PNG"
    for cam_name in [a.split("=")[1] for a in ARGS if a.startswith("cam=")] or ["cine", "game"]:
        if cam_name == "game":
            SC.timeline_markers.clear()
            SC.camera = CAM_GAME
        else:
            cine_cuts()
        SC.render.filepath = os.path.join(FRAMES_DIR, cam_name, "f_")
        bpy.ops.render.render(animation=True)
print("done")