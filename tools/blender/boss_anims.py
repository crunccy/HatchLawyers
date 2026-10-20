# tools/blender/boss_anims.py - the bosses' ATTACK ANIMATIONS (docs/BOSS_ANIMATION.md, 2026-10-19 overhaul).
# Megalodon first (the benchmark): rebuilds the boss from tools/zones/bosses.json (exactly what Studio gets) as one
# empty per animation GROUP at its joint, keys every clip at 30 fps from pose keys with per-key easing (back-out
# snaps, expo launches, settles) plus baked trembles / cycles, and plays them on a preview timeline at the SERVER's
# exact timing (Server.BossService "Line" + Config.Bosses: windup 1.0 s, charge 130 studs at 150 studs/s, dizzy 2.0 s,
# recover 0.6 s). The preview also shows the floor warnings, a dodging target and the 2+ player FEEDING FRENZY
# (sand-shark fins down lanes at the other players - docs/BOSS_ANIMATION.md section 4) with its effects.
# Exports:  tools/zones/boss_anims.json  +  src/BossAnims.lua (ReplicatedStorage.Shared.BossAnims, generated)
#           art/bosses/megalodon/megalodon_charge.blend (scrubbable)
# Renders (optional args after --):  stills  -> art/bosses/megalodon/board_*.png (storyboard frames)
#                                    frames  -> <scratch>/frames_<cam>/ (PNG sequence, for tools/blender/encode_preview.py)
# Mac:  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/boss_anims.py -- stills
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
OUT_DIR = os.path.join(REPO, "art", "bosses", "megalodon")
FRAMES_DIR = os.environ.get("BOSS_FRAMES", os.path.join(REPO, "_boss_frames"))
os.makedirs(OUT_DIR, exist_ok=True)
FPS = 30
BOSS = "Megalodon"
SCALE = 3.2  # Config.Bosses.List[5].Scale
COLOR = (90, 190, 255)  # its Config colour (the warnings)
# the server's timeline (BossService): walk in, windup, charge (Length / LineSpeed), dizzy, recover, walk off
WINDUP, LENGTH, SPEED, DIZZY, RECOVER = 1.0, 130.0, 150.0, 2.0, 0.6
CHARGE = max(0.25, LENGTH / SPEED)
T_WIND = 0.5
T_CHARGE = T_WIND + WINDUP
T_DIZZY = T_CHARGE + CHARGE
T_RECOVER = T_DIZZY + DIZZY
T_WALK2 = T_RECOVER + RECOVER
T_END = T_WALK2 + 0.55
CREW_W, CREW_SPEED, CREW_MAX = 12.0, 120.0, 110.0  # Feeding Frenzy lanes (Config.Bosses.List[5].Crowd)

rng = random.Random(7)

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
    # root = [x, y, z, rx, ry, rz, sx, sy, sz] (around the feet); fx = named 0..1 channels
    return {"g": {g: [0.0] * 6 for g in GROUPS}, "root": [0.0] * 6 + [1.0] * 3, "fx": {"FinGlow": 0.0}}


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


# ------------------------------------------------------------------ the procedural walk (stays code in the client)
def walk_pose(phase, w, t):
    p = zero()
    g, r = p["g"], p["root"]
    sw = math.sin(phase)
    r[2] = abs(math.cos(phase)) * 0.2 * w
    g["LegL"][0], g["LegR"][0] = sw * 0.5 * w, -sw * 0.5 * w
    g["Torso"][1] = -sw * 0.04 * w
    g["ArmL"][0], g["ArmL"][1] = sw * 0.3 * w, 0.15
    g["ArmR"][0], g["ArmR"][1] = -sw * 0.3 * w, -0.15
    g["Tail"][2] = math.sin(t * 4) * 0.35
    g["Cape"][0] = -0.06 * w - 0.05 * abs(sw) * w
    g["Lure"][0] = 0.05 + 0.05 * abs(math.cos(phase)) * w
    g["Lure"][1] = 0.12 * math.sin(phase - 0.6) * w
    return p


# ------------------------------------------------------------------ A. ANTICIPATION (windup, 1.0 s)
def clip_windup(t):
    p = zero()
    g, r = p["g"], p["root"]
    trem = ramp(t, 0.45, 0.9)
    # the sniff-hop-turn (the turn itself is the client's yaw), then the coil
    r[2] = ev([(0, 0), (0.05, 0), (0.13, 0.35, "out"), (0.21, 0, "in")], t)
    r[0] = trem * 0.05 * math.sin(t * 70)
    squash(r, ev([(0, 1), (0.05, 0.92, "out"), (0.12, 1.1, "out"), (0.21, 1.0), (0.25, 0.86, "out"), (0.33, 0.98, "out"),
                  (0.5, 0.86), (0.85, 0.86), (0.97, 0.8), (1.0, 0.8)], t))
    g["Torso"][0] = ev([(0, 0), (0.08, 0.1, "out"), (0.22, 0.04), (0.5, -0.3), (0.85, -0.34), (0.97, -0.4), (1, -0.4)], t)
    g["Torso"][2] = trem * 0.03 * math.sin(t * 55)
    g["Head"][0] = ev([(0, 0), (0.06, 0.16, "out"), (0.16, 0.04), (0.45, 0.0), (0.62, 0.2, "back"), (1, 0.22)], t) \
        + (0.035 * math.sin(t * 90) if t < 0.14 else 0)
    g["Fin"][0] = ev([(0.25, 0), (0.6, 0.08, "back"), (1, 0.06)], t)
    g["Fin"][2] = trem * 0.04 * math.sin(t * 61)
    for arm, s in (("ArmL", 1), ("ArmR", -1)):
        g[arm][0] = ev([(0, 0), (0.14, 0.25, "out"), (0.5, -0.8), (1, -0.9)], t)
        g[arm][1] = s * ev([(0, 0.15), (0.5, 0.38), (1, 0.42)], t)
    # two bull-style paw scrapes with the right foot, the left braced
    g["LegR"][0] = ev([(0, 0), (0.3, 0, "lin"), (0.38, -0.55, "out"), (0.47, 0.02, "in"), (0.55, -0.55, "out"),
                       (0.65, 0.02, "in"), (0.8, -0.12), (1, -0.12)], t)
    g["LegL"][0] = ev([(0, 0), (0.5, 0.1), (1, 0.12)], t)
    g["Tail"][0] = ev([(0, 0), (0.5, -0.2), (1, -0.22)], t)
    g["Tail"][2] = 0.08 * math.sin(t * 8) + trem * 0.22 * math.sin(t * 30)
    g["Cape"][0] = ev([(0, -0.02), (0.5, -0.18), (1, -0.22)], t) - 0.02 * abs(math.sin(t * 9))
    g["Lure"][0] = max(0.0, -g["Torso"][0]) * 0.9 + 0.05 + 0.04 * math.sin(t * 9)
    g["Lure"][1] = 0.1 * math.sin(t * 6)
    g["Glasses"][5] = ev([(0.2, 0), (0.25, 0.06, "out"), (0.32, 0)], t)
    glow = ev([(0.25, 0), (0.9, 1, "in"), (1, 1)], t)
    p["fx"]["FinGlow"] = glow * (0.86 + 0.14 * math.sin(t * 47)) if glow > 0.4 else glow
    return p


# ------------------------------------------------------------------ B. ATTACK (charge: launch / loop / brake)
LOOP = 7 / FPS  # one two-stride cycle


def clip_loop(tl):
    p = zero()
    g, r = p["g"], p["root"]
    u = 2 * math.pi * tl / LOOP
    g["Torso"][0] = -0.42 + 0.04 * math.sin(2 * u)
    r[2] = 0.14 * abs(math.sin(u))
    stretch(r, 1.14 + 0.03 * math.sin(2 * u))
    g["LegL"][0] = 0.45 * math.sin(u) - 0.15
    g["LegR"][0] = -0.45 * math.sin(u) - 0.15
    for arm, s in (("ArmL", 1), ("ArmR", -1)):
        g[arm][0] = -1.1 + 0.08 * math.sin(2 * u + s)
        g[arm][1] = s * 0.55
    g["Head"][0] = 0.32 + 0.12 * math.sin(2 * u)
    g["Tail"][0] = -0.32
    g["Tail"][2] = 0.4 * math.sin(u)
    g["Cape"][0] = -0.36 + 0.08 * math.sin(2 * u + 1)
    g["Lure"][0] = 0.42 + 0.1 * math.sin(2 * u)
    g["Lure"][1] = 0.25 * math.sin(u)
    g["Fin"][0] = -0.15  # swept back for speed
    p["fx"]["FinGlow"] = 0.95 + 0.05 * math.sin(4 * u)
    return p


def pose_explode():
    p = clip_loop(0)
    g, r = p["g"], p["root"]
    g["Torso"][0], g["Head"][0] = -0.55, 0.5
    g["ArmL"][0], g["ArmL"][1], g["ArmR"][0], g["ArmR"][1] = -1.25, 0.8, -1.25, -0.8
    g["LegL"][0], g["LegR"][0] = -0.6, 0.1
    g["Tail"][0], g["Cape"][0], g["Fin"][0] = -0.36, -0.4, -0.22
    stretch(r, 1.32)
    r[2] = 0.12
    p["fx"]["FinGlow"] = 1.0
    return p


def clip_launch(t):  # first 0.2 s of the charge: 2 frames to full stretch, then into the run
    w1, x, l0 = clip_windup(WINDUP), pose_explode(), clip_loop(0)
    if t < 0.06:
        return lerp_pose(w1, x, EASE["expo"](t / 0.06))
    return lerp_pose(x, l0, EASE["out"]((t - 0.06) / 0.14))


def pose_brake(final):
    p = clip_loop(0)
    g, r = p["g"], p["root"]
    g["Torso"][0] = 0.36 if final else 0.3
    g["LegL"][0], g["LegR"][0] = (0.55, 0.5) if final else (0.6, 0.45)
    for arm, s in (("ArmL", 1), ("ArmR", -1)):
        g[arm][0], g[arm][1] = 0.6, s * 0.6
    g["Head"][0] = 0.12
    g["Tail"][0], g["Tail"][2], g["Cape"][0] = 0.15, 0.0, -0.35
    g["Lure"][0], g["Lure"][1] = 0.0, 0.0
    g["Fin"][0] = 0.0
    r[0] = r[1] = r[2] = 0.0
    r[6], r[7], r[8] = 1.06, 0.88, 1.06
    p["fx"]["FinGlow"] = 0.85
    return p


def clip_brake(t):  # last 0.2 s: lean back, feet plough forward, squash along the run
    l0, b1, b2 = clip_loop(0), pose_brake(False), pose_brake(True)
    if t < 0.07:
        return lerp_pose(l0, b1, EASE["out"](t / 0.07))
    return lerp_pose(b1, b2, EASE["io"]((t - 0.07) / 0.13))


def clip_charge(t, total):
    """What the client does: launch for 0.2 s, the loop, brake for the last 0.2 s (short charges split it)."""
    lt, bt = min(0.2, total / 2), min(0.2, total / 2)
    if t < lt:
        return clip_launch(t)
    if t > total - bt:
        return clip_brake(t - (total - 0.2))
    return clip_loop((t - lt) % LOOP)


# ------------------------------------------------------------------ D. RECOVERY (dizzy 2.0 s, then recover 0.6 s)
OMEGA = 2 * math.pi * 0.75


def clip_dizzy(t):
    p = zero()
    g, r = p["g"], p["root"]
    b2 = pose_brake(True)
    w = ramp(t, 0.3, 0.6) * (1 - ramp(t, 1.85, 2.0))
    s, c = math.sin(OMEGA * t), math.cos(OMEGA * t)
    # skid settle: overshoots forward, rocks back, squashes on the stop
    r[1] = ev([(0, 0), (0.12, 0.35, "out"), (0.4, 0)], t)
    r[0] = ev([(1.0, 0), (1.15, 0.18), (1.4, 0)], t)
    r[6] = ev([(0, b2["root"][6]), (0.08, 1.1, "out"), (0.2, 0.96), (0.32, 1.01), (0.45, 1)], t)
    r[7] = ev([(0, b2["root"][7]), (0.08, 1.1, "out"), (0.2, 0.96), (0.32, 1.01), (0.45, 1)], t)
    r[8] = ev([(0, b2["root"][8]), (0.08, 0.82, "out"), (0.2, 1.08), (0.32, 0.97), (0.45, 1)], t)
    g["Torso"][0] = ev([(0, 0.36), (0.1, -0.35, "out"), (0.25, 0.15), (0.4, -0.05), (0.6, 0)], t) + 0.1 * (c - 1) * w
    g["Torso"][1] = 0.16 * s * w
    g["LegL"][0] = ev([(0, 0.55), (0.3, 0, "out"), (1.05, 0), (1.15, 0.35, "out"), (1.3, 0)], t)
    g["LegR"][0] = ev([(0, 0.5), (0.3, 0, "out")], t)
    for arm, sd in (("ArmL", 1), ("ArmR", -1)):
        g[arm][0] = ev([(0, 0.6), (0.35, 0.1, "out")], t) + 0.25 * math.sin(2 * OMEGA * t + sd) * w
        g[arm][1] = sd * ev([(0, 0.6), (0.35, 0.15, "out")], t)
    g["Head"][0] = ev([(0, 0.12), (0.1, 0.28, "out"), (0.4, 0.16)], t) + 0.04 * s * w
    g["Head"][1] = -0.06 * math.sin(OMEGA * t + 0.6) * w
    g["Glasses"][5] = ev([(0.08, 0), (0.18, 0.35, "out"), (0.3, 0, "in")], t)
    g["Glasses"][3] = ev([(0.18, 0), (0.3, -0.06, "out")], t)
    g["Glasses"][1] = ev([(0.18, 0), (0.3, -0.26, "back")], t)
    spin = 2 * math.pi * 4 * EASE["io"](max(0.0, min(1.0, (t - 0.3) / 1.65)))
    g["EyeL"][1], g["EyeR"][1] = spin, -spin
    g["Tail"][0] = ev([(0, 0.15), (0.4, 0.08)], t)
    g["Tail"][2] = 0.12 * s * w
    g["Cape"][0] = ev([(0, -0.35), (0.5, -0.08, "out")], t) + 0.05 * s * w
    g["Lure"][0] = 0.12 * (1 + math.sin(OMEGA * 2 * t)) * w
    g["Lure"][1] = 0.35 * math.sin(OMEGA * t - 0.8) * w
    g["Fin"][0] = 0.0
    p["fx"]["FinGlow"] = ev([(0, 0.85), (0.5, 0, "out")], t)
    return p


def clip_recover(t):
    p = zero()
    g, r = p["g"], p["root"]
    d = max(0.0, 1 - t / 0.32) ** 1.5
    shake = math.sin(2 * math.pi * 8 * t)
    g["Torso"][2] = 0.18 * shake * d
    g["Torso"][0] = ev([(0, 0), (0.45, 0), (0.52, 0.1, "out"), (0.6, 0)], t)
    g["Head"][1] = 0.15 * math.sin(2 * math.pi * 8 * t + 1) * d
    g["Head"][0] = ev([(0, 0.16), (0.3, 0.16), (0.38, -0.03, "out"), (0.46, 0)], t)
    g["Lure"][1] = 0.4 * math.sin(2 * math.pi * 8 * t - 1) * max(0.0, 1 - t / 0.45)
    g["Cape"][0] = -0.08 + 0.08 * ramp(t, 0.3, 0.6) - 0.15 * abs(shake) * d
    # the left fin pushes the glasses straight
    g["ArmL"][0] = ev([(0, 0.1), (0.2, 0), (0.36, 2.0, "out"), (0.46, 2.0), (0.58, 0)], t)
    g["ArmL"][2] = ev([(0.2, 0), (0.3, 0.3), (0.36, 0.06, "out"), (0.46, 0.06), (0.52, 0.3), (0.6, 0)], t)
    g["ArmL"][1] = ev([(0, 0.15), (0.2, 0.25), (0.3, 0.25), (0.36, 0.0), (0.46, 0.0), (0.49, 0.25), (0.6, 0.15)], t)
    # chest puff + a gavel tap
    g["ArmR"][0] = ev([(0, 0.1), (0.2, 0), (0.42, 0, "lin"), (0.5, 0.5, "out"), (0.56, 0.15, "in"), (0.6, 0)], t)
    g["ArmR"][1] = -0.15
    g["Glasses"][1] = ev([(0, -0.26), (0.36, -0.26), (0.44, 0, "back")], t)
    g["Glasses"][3] = ev([(0, -0.06), (0.36, -0.06), (0.44, 0, "out")], t)
    g["Tail"][0] = ev([(0, 0.08), (0.4, 0)], t)
    g["Tail"][2] = 0.3 * math.sin(2 * math.pi * 8 * t + 2) * d
    squash(r, ev([(0, 1), (0.45, 1), (0.52, 1.05, "out"), (0.6, 1)], t))
    return p


def cheek(p):
    """The cheek flaps follow HALF the jaw's opening (and roll), so the side of the mouth stays closed."""
    g = p["g"]
    if "Cheek" in g:
        g["Cheek"][0], g["Cheek"][1] = g["Head"][0] * 0.5, g["Head"][1] * 0.5
    return p


CLIPS = {  # name -> (function, length s, loops)
    "windup": (clip_windup, WINDUP, False),
    "charge_launch": (clip_launch, 0.2, False),
    "charge_loop": (clip_loop, LOOP, True),
    "charge_brake": (clip_brake, 0.2, False),
    "dizzy": (clip_dizzy, DIZZY, False),
    "recover": (clip_recover, RECOVER, False),
}

# ===================================================================================== the client's turn (code)
def back_out(a):
    return EASE["back"](max(0.0, min(1.0, a)))


def turn_yaw(y0, y1, t):  # windup t: holds 0.04 s (the sniff), whips round with an overshoot by 0.24 s
    d = (y1 - y0 + math.pi) % (2 * math.pi) - math.pi
    return y0 + d * back_out((t - 0.04) / 0.2)


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
        frames = [cheek(fn(min(length, i / FPS))) for i in range(n)]
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
         "", "local function unpack(s: string): { number }", "\tlocal t = {}", "\tfor _, v in string.split(s, \",\") do",
         "\t\ttable.insert(t, tonumber(v) :: number)", "\tend", "\treturn t", "end", "", "local Anims = {"]
    for boss, d in allc.items():
        L.append("\t%s = {" % boss)
        L.append("\t\tFps = %d," % d["fps"])
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
SC.name = "MegalodonCharge"
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
FIN_GLOW = []
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
        FIN_GLOW.append(o)

# ------------------------------------------------------------------ the beach, the players, the warnings
ground = block("Sand", (420, 420, 1), (222, 196, 146), loc=(0, 70, -0.5))
for i in range(-10, 11):  # a few darker stud-scale sand bands so speed reads
    block("SandBand", (420, 0.6, 0.02), (204, 178, 128), loc=(0, 70 + i * 20, 0.01))
    block("SandBand", (0.6, 420, 0.02), (204, 178, 128), loc=(i * 20, 70, 0.01))


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


P1, _ = avatar("Target", (98, 205, 48), 0, 60)  # the boss's target (nearest), dodges sideways
P2, _ = avatar("Crowd2", (255, 160, 24), 45, 85)  # dodges its frenzy lane
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), -30, 40)  # stays put: the sand shark gets them
CROWD = [Vector((45, 85, 0)), Vector((-30, 40, 0))]
P2_SIDE = Vector((-CROWD[0].y, CROWD[0].x, 0)).normalized()  # Crowd2 steps out of its lane this way


def lane_end(target):
    d = Vector((target.x, target.y, 0))
    return d.normalized() * min(CREW_MAX, d.length + 20)


def warn_set(name, length, width, arrows=3):
    e = empty(name)
    strip = block("Strip", (1, 1, 0.1), COLOR, e, mat=MAT_WARN, glow=0.6)
    sides = [block("Side", (0.8, 1, 0.16), COLOR, e, mat=MAT_WARN, glow=1.0) for _ in (0, 1)]
    arr = [block("Arrow", (1, 1.4, 0.14), (255, 255, 255), e, mat=MAT_WARN, glow=0.8) for _ in range(arrows)]
    return dict(e=e, strip=strip, sides=sides, arrows=arr, length=length, width=width)


WARN_MAIN = warn_set("WarnMain", LENGTH, 20)
WARN_CROWD = [warn_set("WarnCrowd%d" % i, lane_end(c).length, CREW_W) for i, c in enumerate(CROWD)]


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
    shape = {"puff": (1, 1, 1), "spark": (0.35, 0.35, 0.35), "drop": (0.5, 0.5, 0.7), "streak": (0.22, 1, 0.22)}[kind]
    o = block("fx_" + kind, (0.001,) * 3, col, glow=glow, mat=MAT_FX)
    o["alpha"] = 0.95 if kind != "streak" else 0.85
    FX.append(dict(o=o, t0=t0, life=life, p0=Vector(p0), vel=Vector(vel), grav=grav, size=size, shape=shape,
                   kind=kind, spin=spin, rot=(rng.random() * 6, rng.random() * 6, rng.random() * 6)))


def fx_scale(f, a):
    if f["kind"] == "streak":  # appears full length, shrinks to nothing along its length
        k = 1 - a
        return (f["shape"][0], f["size"] * k, f["shape"][2])
    k = (a / 0.15) if a < 0.15 else (1 - (a - 0.15) / 0.85) ** 0.7
    k *= f["size"] * (0.7 + 0.6 * a if f["kind"] == "puff" else 1)
    return tuple(s * k for s in f["shape"])


# ------------------------------------------------------------------ the shark fins of the Feeding Frenzy
def sand_shark(name):
    e = empty(name)
    block("Fin", (0.9, 4.2, 4.2), (90, 110, 140), e, (0, 0, 1.0)).rotation_euler = (math.radians(-35), 0, 0)
    block("Edge", (1.1, 1.0, 1.0), (120, 220, 255), e, (0, -1.6, 3.4), glow=1.0)
    return e


SHARKS = [sand_shark("SandShark%d" % i) for i in range(len(CROWD))]

# ------------------------------------------------------------------ dizzy stars
STAR_ME = bpy.data.meshes.new("Star")
pts = [(math.cos(math.pi / 2 + i * math.pi / 5) * (1.0 if i % 2 == 0 else 0.45),
        math.sin(math.pi / 2 + i * math.pi / 5) * (1.0 if i % 2 == 0 else 0.45)) for i in range(10)]
verts = [(x, y, z) for z in (-0.18, 0.18) for (x, y) in pts] + [(0, 0, -0.25), (0, 0, 0.25)]
faces = [(i, (i + 1) % 10, 20) for i in range(10)][::-1] + [(10 + i, 10 + (i + 1) % 10, 21) for i in range(10)]
faces += [(i, (i + 1) % 10, 10 + (i + 1) % 10, 10 + i) for i in range(10)]
STAR_ME.from_pydata(verts, [], faces)
STAR_ME.update()
STARS = []
for i in range(3):
    s = bpy.data.objects.new("DizzyStar", STAR_ME)
    s.color = lin((255, 224, 70))
    s["glow"] = 0.35
    s["alpha"] = 1.0
    set_mat(s, MAT_BLOCK)
    SC.collection.objects.link(s)
    STARS.append(s)

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


CAM_GAME = camera("Cam_Gameplay", (92, -14, 58), (0, 58, 2), 30)  # a high player's-eye view of the whole lane
CAM_A = camera("Cam_Start", (40, 36, 16), (0, 0, 11), 32)  # front 3/4 on the turn + coil
CAM_B = camera("Cam_Run", (46, -30, 15), (0, 8, 10), 28)  # the charge
CAM_C = camera("Cam_Stop", (16, 176, 17), (0, 131, 15), 30)  # skid, dizzy, recover


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state, local t, position, yaw target)."""
    start, goal = Vector((0, 0, 0)), Vector((0, LENGTH, 0))
    if T < T_WIND:
        return "walk", T, Vector((-21 + 21 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_CHARGE:
        return "windup", T - T_WIND, start, 0.0
    if T < T_DIZZY:
        return "attack", T - T_CHARGE, start.lerp(goal, (T - T_CHARGE) / CHARGE), 0.0
    if T < T_RECOVER:
        return "dizzy", T - T_DIZZY, goal, 0.0
    if T < T_WALK2:
        return "recover", T - T_RECOVER, goal, 0.0
    return "walk", T - T_WALK2, goal + Vector((14 * (T - T_WALK2) / 0.55, 0, 0)), -math.pi / 2


def schedule_fx():
    tw = T_WIND
    for k, ts in enumerate((0.4, 0.57)):  # paw scrapes: sand kicked BEHIND him
        for _ in range(6):
            spawn("puff", tw + ts, 0.45, (2.7 + rng.uniform(-1, 1), -3.5, 0.8),
                  (rng.uniform(-3, 3), rng.uniform(-16, -9), rng.uniform(4, 9)), -22, rng.uniform(1.0, 1.6))
    t = tw + 0.6
    while t < T_CHARGE:  # electric crackle off the fin
        spawn("spark", t, 0.2, (rng.uniform(-1, 1), -4.6 + rng.uniform(-1, 1), 18 + rng.uniform(-2, 3)),
              (rng.uniform(-9, 9), rng.uniform(-9, 3), rng.uniform(0, 9)), 0, 1.3, (140, 230, 255), 1.0)
        t += 0.045
    for c in CROWD:  # frenzy: sand bursts where the sand sharks surface
        d = lane_end(c).normalized()
        for _ in range(7):
            spawn("puff", tw + 0.45, 0.5, (d.x * 7, d.y * 7, 0.5),
                  (rng.uniform(-6, 6), rng.uniform(-6, 6), rng.uniform(8, 15)), -30, rng.uniform(1.0, 1.7))
    for i in range(14):  # launch: dust ring
        a = i / 14 * 2 * math.pi
        spawn("puff", T_CHARGE, 0.55, (math.cos(a) * 3, math.sin(a) * 3 - 2, 0.6),
              (math.cos(a) * 18, math.sin(a) * 18 - 6, rng.uniform(3, 7)), -10, rng.uniform(1.6, 2.4))
    f = 0
    while T_CHARGE + f / FPS < T_DIZZY - 1e-6:  # the run
        tt = T_CHARGE + f / FPS
        y = LENGTH * (tt - T_CHARGE) / CHARGE
        braking = tt > T_DIZZY - 0.2
        for sx in (-1, 1):
            if braking:  # plough: sand thrown FORWARD
                for _ in range(2):
                    spawn("puff", tt, 0.5, (sx * 2.7, y + 3, 0.6), (sx * rng.uniform(2, 9), rng.uniform(14, 24), rng.uniform(6, 13)), -30, rng.uniform(1.4, 2.4))
            else:
                spawn("puff", tt, 0.4, (sx * 2.7, y - 2, 0.6), (sx * rng.uniform(1, 6), rng.uniform(-12, -5), rng.uniform(6, 12)), -40, rng.uniform(1.0, 1.8))
        if not braking:
            for _ in range(2):
                spawn("streak", tt, 0.13, (rng.uniform(-9, 9), y + rng.uniform(-6, 2), rng.uniform(3, 23)), (0, 0, 0), 0,
                      rng.uniform(8, 13), (255, 255, 255), 0.6)
            if f % 2 == 0:
                for sx in (-1, 1):
                    for _ in range(2):
                        spawn("drop", tt, 0.5, (sx * 5.5, y - 1, 2.5), (sx * rng.uniform(10, 18), rng.uniform(-4, 6), rng.uniform(12, 20)),
                              -60, rng.uniform(0.9, 1.3), (150, 225, 255), 0.5)
        f += 1
    for i in range(10):  # the stop
        a = i / 10 * 2 * math.pi
        spawn("puff", T_DIZZY, 0.5, (math.cos(a) * 3, LENGTH + math.sin(a) * 3 + 3, 0.5),
              (math.cos(a) * 12, math.sin(a) * 12 + 6, rng.uniform(2, 6)), -10, rng.uniform(1.5, 2.2))
    for i in range(8):  # the wet-dog shake flings drops off his head
        spawn("drop", T_RECOVER + 0.05 + i * 0.025, 0.45, (rng.uniform(-3, 3), LENGTH + rng.uniform(-2, 3), 19),
              (rng.uniform(-18, 18), rng.uniform(-8, 12), rng.uniform(4, 14)), -60, 1.0, (150, 225, 255), 0.5)
    # frenzy sand sharks: a wake behind each fin while it races
    for c in CROWD:
        d = lane_end(c)
        n = d.normalized()
        travel = (d.length - 7) / CREW_SPEED
        f = 0
        while f / FPS < travel:
            tt = T_CHARGE + f / FPS
            pos = n * (7 + CREW_SPEED * f / FPS)
            for sx in (-1, 1):
                side = Vector((-n.y, n.x, 0)) * sx
                spawn("puff", tt, 0.4, (pos.x + side.x, pos.y + side.y, 0.4),
                      (side.x * rng.uniform(5, 10) - n.x * 4, side.y * rng.uniform(5, 10) - n.y * 4, rng.uniform(5, 10)), -35, rng.uniform(0.9, 1.4))
            f += 1


schedule_fx()
P3_HIT = T_CHARGE + (CROWD[1].length - 7) / CREW_SPEED


def player_pos(T):
    p1 = Vector((0, 60, 0)).lerp(Vector((17, 62, 0)), ramp(T, T_WIND + 0.15, T_WIND + 0.68))
    p2 = CROWD[0] + P2_SIDE * 14 * ramp(T, T_WIND + 0.3, T_WIND + 0.75)
    return p1, p2


def bake():
    walk_amt, phase, prev_yaw = 1.0, 0.0, -math.pi / 2
    clip_w = 0.0
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        moving = state == "walk" or state == "attack"
        speed = 42.0 if state == "walk" else (SPEED if state == "attack" else 0)
        phase += (1 / FPS) * speed / (4 * SCALE) * math.pi
        walk_amt += ((1.0 if state == "walk" else 0.0) - walk_amt) * min(1.0, 6 / FPS)
        # the yaw: the authored whip-round in the windup; otherwise the client's smooth turn
        if state == "windup":
            yaw = turn_yaw(-math.pi / 2, 0.0, tl)
        else:
            yaw = prev_yaw + ((yaw_t - prev_yaw + math.pi) % (2 * math.pi) - math.pi) * min(1.0, 6 / FPS)
        prev_yaw = yaw
        # the pose: procedural walk, clips for the attack, cross-faded over 0.1 s like the client
        if state == "walk":
            pose = walk_pose(phase, walk_amt, T)
            if T >= T_WALK2:
                pose = lerp_pose(clip_recover(RECOVER), pose, ramp(tl, 0, 0.1))
        else:
            fn = {"windup": lambda x: clip_windup(x), "attack": lambda x: clip_charge(x, CHARGE),
                  "dizzy": clip_dizzy, "recover": clip_recover}[state]
            pose = fn(tl)
            if state == "windup" and tl < 0.1:
                pose = lerp_pose(walk_pose(phase, walk_amt, T), pose, ramp(tl, 0, 0.1))
        cheek(pose)
        if state == "windup":  # the head leads the turn
            pose["g"]["Torso"][2] += 0.35 * (0.0 - yaw)
        BOSS_E.location = pos
        if T_CHARGE - 0.05 <= T <= T_DIZZY + 0.1:  # the run camera tracks alongside him
            CAM_B.location = (46, pos.y - 30, 15)
            CAM_B.rotation_euler = (Vector((0, pos.y + 8, 10)) - CAM_B.location).to_track_quat("-Z", "Y").to_euler()
            CAM_B.keyframe_insert("location", frame=fr)
            CAM_B.keyframe_insert("rotation_euler", frame=fr)
        BOSS_E.rotation_euler = (0, 0, yaw)
        r = pose["root"]
        ROOT_E.location = (r[0], r[1], r[2])
        ROOT_E.rotation_euler = (r[3], r[4], r[5])
        ROOT_E.scale = (r[6], r[7], r[8])
        for objs in (BOSS_E, ROOT_E):
            objs.keyframe_insert("location", frame=fr)
            objs.keyframe_insert("rotation_euler", frame=fr)
            objs.keyframe_insert("scale", frame=fr)
        for g in GROUPS:
            v = pose["g"][g]
            e = GE[g]
            e.rotation_euler = (v[0], v[1], v[2])
            e.location = REST[g] + Vector((v[3], v[4], v[5]))
            e.keyframe_insert("rotation_euler", frame=fr)
            e.keyframe_insert("location", frame=fr)
        glow = pose["fx"]["FinGlow"]
        for o in FIN_GLOW:
            o["alpha"] = 0.45 * glow
            o["glow"] = 0.7 * glow
            o.keyframe_insert('["alpha"]', frame=fr)
            o.keyframe_insert('["glow"]', frame=fr)
        # warnings: drawn through the windup only (as today), grown over 0.4 s
        wind = state == "windup"
        grow = 0.45 + 0.55 * EASE["out"](min(1.0, tl / 0.4)) if wind else 1.0
        pose_warn(WARN_MAIN, Vector((0, 0, 0)), Vector((0, 1, 0)), grow, T, wind)
        for w, c in zip(WARN_CROWD, CROWD):
            pose_warn(w, Vector((0, 0, 0)), lane_end(c).normalized(), grow, T, wind)
        for w in [WARN_MAIN] + WARN_CROWD:
            for o in [w["strip"]] + w["sides"] + w["arrows"]:
                o.keyframe_insert("location", frame=fr)
                o.keyframe_insert("scale", frame=fr)
                o.keyframe_insert('["alpha"]', frame=fr)
            w["e"].keyframe_insert("location", frame=fr)
            w["e"].keyframe_insert("rotation_euler", frame=fr)
        # sand sharks: surface at windup 0.45, wait, race at the charge, dive at the lane's end
        for shark, c in zip(SHARKS, CROWD):
            d = lane_end(c)
            n = d.normalized()
            travel = (d.length - 7) / CREW_SPEED
            if T < T_WIND + 0.45:
                z, along = -5.0, 7.0
            elif T < T_CHARGE:
                z, along = -5 + 5 * EASE["back"](min(1.0, (T - T_WIND - 0.45) / 0.18)), 7.0
            else:
                k = T - T_CHARGE
                along = 7 + CREW_SPEED * min(k, travel)
                z = -5 * EASE["in"](min(1.0, max(0.0, (k - travel) / 0.2)))
            wob = math.sin(T * 22) * 0.15
            shark.location = (n.x * along, n.y * along, z)
            shark.rotation_euler = (0, wob, math.atan2(-n.x, n.y))
            shark.keyframe_insert("location", frame=fr)
            shark.keyframe_insert("rotation_euler", frame=fr)
        # players: the target and Crowd2 step out of their warnings; Crowd3 doesn't, and the sand shark gets them
        p1, p2 = player_pos(T)
        P1.location, P2.location = p1, p2
        P1.rotation_euler = (0, 0, -math.pi / 2 if T_WIND + 0.12 < T < T_WIND + 0.7 else math.pi)
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND + 0.28 < T < T_WIND + 0.77 else math.atan2(CROWD[0].x, -CROWD[0].y))
        if T > P3_HIT:
            k = min(1.0, (T - P3_HIT) / 0.7)
            fling = CROWD[1].normalized()
            P3.location = CROWD[1] + fling * 16 * EASE["out"](k) + Vector((0, 0, 7 * math.sin(math.pi * min(1, k * 1.2))))
            P3.rotation_euler = (0, -math.pi * 0.5 * EASE["out"](k), math.atan2(-fling.x, fling.y))
            for i, egg in enumerate(P3EGGS):
                a = i / 3 * 2 * math.pi + 0.4
                ke = min(1.0, (T - P3_HIT - i * 0.05) / 0.6) if T > P3_HIT + i * 0.05 else 0
                egg.location = Vector((math.cos(a) * 9 * ke, math.sin(a) * 9 * ke, 5.9 + i * 1.5 + 9 * math.sin(math.pi * ke) - (5.9 + i * 1.5 - 0.8) * ke))
                egg.keyframe_insert("location", frame=fr)
        else:
            P3.location = CROWD[1]
            P3.rotation_euler = (0, 0, math.atan2(CROWD[1].x, -CROWD[1].y))
            for i, egg in enumerate(P3EGGS):
                egg.location = (0, 0.2, 5.9 + i * 1.5)
                egg.keyframe_insert("location", frame=fr)
        for o in (P1, P2, P3):
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)
        # dizzy stars: three gold stars orbiting over his head
        on = ramp(T, T_DIZZY + 0.25, T_DIZZY + 0.45) * (1 - ramp(T, T_RECOVER - 0.05, T_RECOVER + 0.12))
        top = Vector((0, LENGTH, 8 * SCALE + 3.2))
        for i, s in enumerate(STARS):
            a = T * 5 + i * 2 * math.pi / 3
            s.location = top + Vector((math.cos(a) * 4.2, math.sin(a) * 4.2, 0.6 * math.sin(T * 7 + i)))
            s.rotation_euler = (math.pi / 2, 0, a + T * 6)
            s.scale = (1.3 * on,) * 3
            for k in ("location", "rotation_euler", "scale"):
                s.keyframe_insert(k, frame=fr)
    # effects: each puff / spark / streak keyed over its life
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
            o.rotation_euler = f["rot"] if f["kind"] != "streak" else (0, 0, 0)
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("scale", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


bake()
print("clips:", export())

# camera cuts for the cinematic cut
def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int(T_CHARGE * FPS), CAM_B), (int((T_DIZZY - 0.1) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


cine_cuts()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "megalodon_charge.blend"), compress=True)

# ===================================================================================== clipping check
def clip_check():
    """Max depth (studs) any block of one group goes into another group's block, per state, beyond the rest pose's own
    overlap (joints overlap at rest by design). Prints the worst offenders."""
    parts = [o for o in bpy.data.objects if o.parent and o.parent.name.startswith("G_") and o.type == "MESH"
             and o.name.split(".")[0] != "FinGlow" and o.parent.name != "G_Cheek"]  # (cheek flaps sit inside by design)
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
    worst = {}
    for fr in range(SC.frame_start, SC.frame_end + 1):
        SC.frame_set(fr)
        st = boss_state(fr / FPS)[0]
        for a, b in pairs:
            d = depth(a, b) - base[(a.name, b.name)]
            if d > 0.25:
                key = (a.parent.name, a.name, b.parent.name, b.name)
                if d > worst.get(key, (0, 0, ""))[0]:
                    worst[key] = (d, fr, st)
    for k, (d, fr, st) in sorted(worst.items(), key=lambda kv: -kv[1][0])[:25]:
        print("CLIP %.2f studs  frame %d (%s)  %s/%s into %s/%s" % (d, fr, st, k[0], k[1], k[2], k[3]))
    print("clip check: %d pairs over 0.25 studs" % len(worst))


if "check" in ARGS:
    clip_check()

# ===================================================================================== renders
BOARD = [  # storyboard: (preview time, camera, file)
    (T_WIND + 0.02, CAM_A, "01_detect"), (T_WIND + 0.12, CAM_A, "02_turn_hop"), (T_WIND + 0.4, CAM_A, "03_coil_scrape"),
    (T_WIND + 0.7, CAM_A, "04_fin_glow_grin"), (T_WIND + 0.97, CAM_A, "05_final_sink"),
    (T_CHARGE + 0.05, CAM_B, "06_launch"), (T_CHARGE + 0.4, CAM_B, "07_run"), (T_DIZZY - 0.08, CAM_C, "08_brake"),
    (T_DIZZY + 0.1, CAM_C, "09_skid_settle"), (T_DIZZY + 0.25, CAM_C, "10_glasses"), (T_DIZZY + 1.0, CAM_C, "11_dizzy"),
    (T_RECOVER + 0.12, CAM_C, "12_shake_off"), (T_RECOVER + 0.4, CAM_C, "13_glasses_fix"),
    (T_RECOVER + 0.5, CAM_C, "14_gavel_tap"), (T_WIND + 0.7, CAM_GAME, "15_gameplay_warnings"),
    (T_CHARGE + 0.4, CAM_GAME, "16_gameplay_frenzy"),
]
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
