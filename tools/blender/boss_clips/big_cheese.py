# tools/blender/boss_clips/big_cheese.py - Prosecutor Big Cheese's CHEESE ROLL clips (docs/BOSS_ANIMATION.md section 7).
# Run through tools/blender/boss_anims.py (boss=BigCheese), which execs this file in its own namespace (EASE, ev, ramp,
# zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService "Line" + Config.Bosses.List[4]): walk in, windup 1.2 s (the warning lane),
# roll 110 studs at 120 studs/s (0.92 s; shorter at a wall), no dizzy, recover 0.6 s, walk off.
# THE ROLL ITSELF IS CODE, not clip: the wheel turns by the distance it has really travelled (Bosses.client: roll =
# distance / (WHEEL_R x Scale), pre-multiplied about the boss's X axis), so it never slips whatever the roll's length. The
# clips do the rest: the tip onto its edge, the burnout, squash + jiggle, the arms tucking in, the hop back upright
# (the Unroll channel: 0 = keep the roll it ended on, 1 = upright again).
# The preview also shows the 2+ player WHEEL SPLIT (cheese wedges tumbling down lanes at the other players).
OUT_DIR = os.path.join(REPO, "art", "bosses", "big_cheese")
BLEND = "big_cheese_roll.blend"
SCENE_NAME = "CheeseRoll"
SCALE = 3.2  # Config.Bosses.List[4].Scale
COLOR = (255, 200, 60)  # its Config colour (the warnings)
WHEEL_R = 3.2  # the wheel's radius (model units: tools/blender/bosses.py)
WINDUP, LENGTH, SPEED, RECOVER = 1.2, 110.0, 120.0, 0.6
CHARGE = max(0.25, LENGTH / SPEED)
T_WIND = 0.5
T_CHARGE = T_WIND + WINDUP
T_RECOVER = T_CHARGE + CHARGE
T_WALK2 = T_RECOVER + RECOVER
T_END = T_WALK2 + 0.55
CREW_W, CREW_SPEED, CREW_MAX = 12.0, 110.0, 100.0  # Wheel Split lanes (Config.Bosses.List[4].Crowd)
WEDGE_OFF = 0.62  # windup t when the two wedges pop off the wheel (as it lands on its edge)
TURN = (0.06, 0.28)  # a deliberate little turn before the tip
# fx channels: Roll = extra roll (radians) the client adds to its code roll (the windup's burnout spin in place);
# Unroll (recover) = 0: the roll it stopped on .. 1: upright again (the client blends its code roll)
FX_CHANNELS = ("Roll", "Unroll")
CHECK_SKIP_PARTS = ()
CHECK_SKIP_GROUPS = ()


def check_fold(ga, gb, state, tl):
    """The arms are pulled INTO the wheel for the roll (hidden): an arm inside the Torso then is by design."""
    if {ga, gb} not in ({"ArmL", "Torso"}, {"ArmR", "Torso"}):
        return False
    return state == "attack" or (state == "windup" and tl >= WEDGE_OFF) or (state == "recover" and tl < 0.3)
TUCK = (0.95, 0.0, -0.35)  # the arms pulled into the wheel for the roll (model units, toward its middle)
SPIN = WHEEL_R * SCALE  # studs rolled per radian


def elastic(t, t0, amp, freq, decay):
    if t < t0:
        return 0.0
    k = t - t0
    return amp * math.exp(-decay * k) * math.sin(2 * math.pi * freq * k)


def tuck(g, side, k):  # the arm slides into the wheel (k 0..1)
    g[side][3] = (-1 if side == "ArmR" else 1) * TUCK[0] * k
    g[side][5] = TUCK[2] * k


# ------------------------------------------------------------------ the procedural walk (stays code in the client)
def walk_pose(phase, w, t):  # = POSES.BigCheese's walk, in Blender axes
    p = zero()
    g, r = p["g"], p["root"]
    r[2] = abs(math.sin(phase)) * 0.25 * w
    g["Torso"][1] = -(math.sin(phase) * 0.12 * w + math.sin(t * 1.5) * 0.03)
    arm = math.sin(t * 3) * 0.2
    g["ArmL"][0], g["ArmL"][1] = arm, 0.2
    g["ArmR"][0], g["ArmR"][1] = arm * 0.6 + 0.3, -0.2
    return p


# ------------------------------------------------------------------ A. ANTICIPATION (windup, 1.2 s)
HALF = math.pi / 2


def burnout(t):  # the wheel spins in place before it goes: rocks back, then one revolution, faster and faster
    if t < 0.72:
        return 0.0
    if t < 0.86:
        return ev([(0.72, 0), (0.86, -0.35, "out")], t)
    a = (t - 0.86) / (WINDUP - 0.86)
    return -0.35 + (2 * math.pi + 0.35) * a * a  # (ends on a whole turn: the roll starts from upright)


def clip_windup(t):
    p = zero()
    g, r = p["g"], p["root"]
    # NOTICE: eyes snap wide open, a smug bounce
    g["Lids"][5] = ev([(0, 0), (0.06, 0.16, "out"), (0.2, 0.1), (0.36, -0.05, "io"), (0.7, -0.05), (0.8, 0.14, "out"),
                       (1.2, 0.12)], t)
    r[2] = ev([(0, 0), (0.05, 0.25, "out"), (0.12, 0, "in"), (0.4, 0), (0.52, 1.0, "out"), (0.64, 0, "in")], t)
    # EN GARDE: the cocktail-stick sword up in a salute, the moustache twirled
    g["ArmR"][0] = ev([(0, 0.3), (0.12, 0.3), (0.26, 1.75, "back"), (0.42, 1.7), (0.56, 0.6, "io"), (0.74, 0.0)], t)
    g["ArmR"][2] = ev([(0.12, 0), (0.26, 0.22, "out"), (0.42, 0.22), (0.56, 0.0)], t)
    g["ArmR"][1] = ev([(0, -0.2), (0.12, -0.2), (0.26, 0.0)], t)
    g["ArmL"][0] = ev([(0, 0), (0.14, 0.5, "out"), (0.4, 0.5), (0.5, 1.4, "out"), (0.64, 0.3, "in"), (0.74, 0.0)], t)
    g["ArmL"][1] = ev([(0, 0.2), (0.14, 0.45, "out"), (0.5, 0.6), (0.74, 0.0)], t)
    g["Moustache"][1] = ev([(0.14, 0), (0.22, 0.25, "out"), (0.3, -0.18), (0.38, 0.1), (0.46, 0)], t) \
        + ramp(t, 0.8, 1.0) * 0.08 * math.sin(t * 60)
    # TIP onto its edge: a hop, a quarter turn in the air, a squashy landing that jiggles
    g["Torso"][2] = ev([(0.4, 0), (0.62, HALF, "back")], t)
    # the arms slide into the wheel for the roll
    k = ev([(0.62, 0), (0.78, 1, "back")], t)
    tuck(g, "ArmL", k)
    tuck(g, "ArmR", k)
    # BURNOUT: rocks back, then spins in place (the Roll channel: the client turns the wheel by it, with the bump)
    p["fx"]["Roll"] = burnout(t)
    jig = elastic(t, 0.64, 0.12, 5, 7)
    squash(r, ev([(0, 1), (0.05, 0.94), (0.12, 1.06, "out"), (0.2, 1.0), (0.4, 1.0), (0.46, 0.9, "out"), (0.52, 1.1, "out"),
                  (0.64, 0.8, "in"), (0.74, 1.0), (0.86, 0.92), (1.2, 0.9)], t) + jig)
    return p


# ------------------------------------------------------------------ B. ATTACK (roll: launch / loop / brake; the spin is code)
LOOP = 6 / FPS  # one jiggle cycle


def roll_base():
    p = zero()
    g = p["g"]
    g["Torso"][2] = HALF
    tuck(g, "ArmL", 1)
    tuck(g, "ArmR", 1)
    g["Lids"][5] = 0.14  # eyes wide with speed
    return p


def clip_loop(tl):
    p = roll_base()
    g, r = p["g"], p["root"]
    u = 2 * math.pi * tl / LOOP
    r[2] = 0.1 * abs(math.sin(u))  # a little bounce off the floor
    stretch(r, 1.1 + 0.04 * math.sin(u))
    g["Moustache"][1] = 0.12 * math.sin(2 * u)  # fluttering in the wind (turning in the face's plane: never into it)
    g["Torso"][0] = 0.03 * math.sin(u)  # a slight wobble about the run
    return p


def clip_launch(t):  # first 0.2 s: pops forward (stretched along the run), lands on the run
    w1, l0 = clip_windup(WINDUP), clip_loop(0)
    w1["fx"]["Roll"] = 0.0  # (the burnout ended on a whole turn; the code roll takes over from upright)
    x = roll_base()
    stretch(x["root"], 1.28)
    x["root"][2] = 0.35
    x["g"]["Moustache"][1] = 0.22
    if t < 0.06:
        return lerp_pose(w1, x, EASE["expo"](t / 0.06))
    return lerp_pose(x, l0, EASE["out"]((t - 0.06) / 0.14))


def pose_brake(k):
    p = roll_base()
    g, r = p["g"], p["root"]
    r[6], r[7], r[8] = 1.0 + 0.08 * k, 1.0 - 0.18 * k, 1.0 + 0.06 * k  # squashed against the stop
    g["Moustache"][1] = -0.2 * k
    g["Lids"][5] = 0.14 + 0.04 * k
    return p


def clip_brake(t):  # last 0.2 s: squashes along the run as it digs in
    l0 = clip_loop(0)
    if t < 0.07:
        return lerp_pose(l0, pose_brake(0.6), EASE["out"](t / 0.07))
    return lerp_pose(pose_brake(0.6), pose_brake(1.0), EASE["io"]((t - 0.07) / 0.13))


def clip_charge(t, total):
    lt = min(0.2, total / 2)
    if t < lt:
        return clip_launch(t)
    if t > total - lt:
        return clip_brake(t - (total - 0.2))
    return clip_loop((t - lt) % LOOP)


# ------------------------------------------------------------------ D. RECOVERY (0.6 s)
def clip_recover(t):
    p = roll_base()
    g, r = p["g"], p["root"]
    b2 = pose_brake(1.0)
    # SETTLE: a coin-wobble about the run as it stops, the squash springs back
    g["Torso"][0] = elastic(t, 0.0, 0.16, 4.5, 6) * (1 - ramp(t, 0.12, 0.2))
    # HOP back upright: up, a quarter turn back to face the front, the roll undone in the air (Unroll), a jiggly landing
    r[2] = ev([(0.12, 0), (0.28, 1.2, "out"), (0.42, 0, "in")], t)
    g["Torso"][2] = ev([(0.14, HALF), (0.4, 0, "io")], t)
    p["fx"]["Unroll"] = ev([(0.14, 0), (0.4, 1, "io")], t)
    k = ev([(0.18, 1), (0.34, 0, "back")], t)  # the arms pop back out
    tuck(g, "ArmL", k)
    tuck(g, "ArmR", k)
    g["ArmR"][0] = ev([(0.3, 0), (0.44, 0.5, "out"), (0.6, 0.3)], t)
    g["ArmR"][1] = ev([(0.3, 0), (0.5, -0.2)], t)
    g["ArmL"][1] = ev([(0.3, 0), (0.5, 0.2)], t)
    g["Lids"][5] = ev([(0, 0.18), (0.3, 0.1), (0.48, -0.05, "out"), (0.6, 0)], t)
    # a smug moustache twirl to finish
    g["Moustache"][1] = ev([(0, -0.2), (0.15, 0, "out"), (0.44, 0), (0.5, 0.25, "out"), (0.55, -0.12), (0.6, 0)], t)
    sq = ev([(0, 1.0), (0.1, 0.97), (0.14, 1.04), (0.28, 1.06), (0.42, 0.8, "in"), (0.5, 1.07, "out"), (0.56, 0.97), (0.6, 1)], t)
    squash(r, sq)
    if t < 0.1:  # (out of the brake's squash)
        a = t / 0.1
        for i in (6, 7, 8):
            r[i] = b2["root"][i] + (r[i] - b2["root"][i]) * EASE["out"](a)
    return p


CLIPS = {  # name -> (function, length s, loops)
    "windup": (clip_windup, WINDUP, False),
    "charge_launch": (clip_launch, 0.2, False),
    "charge_loop": (clip_loop, LOOP, True),
    "charge_brake": (clip_brake, 0.2, False),
    "recover": (clip_recover, RECOVER, False),
}


# the code roll (what Bosses.client does): radians rolled after travelling `dist` studs; recover blends to upright
def roll_after(dist):
    return dist / SPIN


def unroll_target(roll):
    return 2 * math.pi * round(roll / (2 * math.pi))
