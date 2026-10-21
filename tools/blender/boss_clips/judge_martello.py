# tools/blender/boss_clips/judge_martello.py - Judge Martello's GAVEL SLAM clips (docs/BOSS_ANIMATION.md section 9). Run
# through tools/blender/boss_anims.py (boss=JudgeMartello), which execs this file in its own namespace (EASE, ev, ramp,
# zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService "Slam" + Config.Bosses.List[3]): walk in; windup 1.1 s = THE HOP (From = where
# he stood, To = where the target stood when it began, linear; he's airborne: his body can't be touched); he lands as the
# attack begins (everyone within 26 of the spot is hit at its FIRST frame), attack 0.45 s, recover 0.6 s, walk off.
# He is a walking gavel, so the slam is a GAVEL STRIKE: he crouches, launches, tucks his arms in at the top, then swings
# himself like a gavel (a cartwheel about his forward axis) and lands on his END CAP - BONK - right on the spot, the
# handle (his legs) sticking out sideways. He hops back onto his feet in the recover.
# Travel (fx channel, windup): 0..1 how far along From -> To the client draws him (it holds for the crouch, then flies; he
# lands exactly on the server's spot as the windup ends - only the drawn path changes, nothing can touch him meanwhile).
# The preview also shows the 2+ player GAVEL RAIN (a mini gavel flung up at the launch drops on each other player's spot:
# Disc r 12, landing with him).
OUT_DIR = os.path.join(REPO, "art", "bosses", "judge_martello")
BLEND = "judge_martello_slam.blend"
SCENE_NAME = "MartelloSlam"
SCALE = 3.4  # Config.Bosses.List[3].Scale
COLOR = (255, 170, 60)  # its Config colour (the warnings)
WINDUP, ATTACK, RECOVER = 1.1, 0.45, 0.6
RADIUS, HOP = 26.0, 6.0  # the slam (Config.Bosses.List[3].Radius) and HopHeight (model units)
T_WIND = 0.5
T_ATTACK = T_WIND + WINDUP
T_RECOVER = T_ATTACK + ATTACK
T_WALK2 = T_RECOVER + RECOVER
T_END = T_WALK2 + 0.6
RAIN_R, RAIN_THROW = 12.0, 0.3  # Gavel Rain discs (Config.Bosses.List[3].Crowd.Radius); the mini gavels leave his gloves then
TURN = (0.03, 0.18)  # a snappy turn ...
LEAD = ("Torso", 0.2)  # ... the hammer head leads the legs a little
FX_CHANNELS = ("Travel",)
CHECK_SKIP_PARTS = ()
CHECK_SKIP_GROUPS = ()
LAUNCH, APEX, STRIKE_ROLL = 0.3, 0.62, math.pi / 2
C = 4.0  # the middle of his hammer head (model units up): he cartwheels about it
TUCK = 0.66  # the arms slide this far into the hammer head for the strike (model units, toward the middle)
WIDE = 0.1  # ... and stand this far out while they swing (their inner faces hang a hair inside the end caps)


def check_fold(ga, gb, state, tl):
    """Leg tops inside the handle (hips) always; the arms pulled into the hammer head from the top of the hop until
    they pop back out in the recover (the cannonball): hidden by design."""
    pair = {ga, gb}
    if pair in ({"LegL", "Torso"}, {"LegR", "Torso"}):
        return True
    if pair in ({"ArmL", "Torso"}, {"ArmR", "Torso"}):
        return (state == "windup" and tl >= APEX - 0.08) or state == "attack" or (state == "recover" and tl < 0.16)
    return False


def elastic(t, t0, amp, freq, decay):
    if t < t0:
        return 0.0
    k = t - t0
    return amp * math.exp(-decay * k) * math.sin(2 * math.pi * freq * k)


# every corner of the hammer head and the legs (rest): (group, x, y, z) in Blender model units - how low he reaches as he
# rolls (and as his legs swing about their joints, 2.0 up)
def _corners():
    out = []
    for prt in DATA["parts"]:
        if prt["g"] not in ("Torso", "LegL", "LegR"):
            continue
        p, s, r = prt["p"], prt["s"], prt["r"]
        for dx in (-0.5, 0.5):
            for dy in (-0.5, 0.5):
                for dz in (-0.5, 0.5):
                    lx, ly, lz = dx * s[0], dy * s[1], dz * s[2]
                    x = p[0] + r[0] * lx + r[1] * ly + r[2] * lz
                    z = p[1] + r[3] * lx + r[4] * ly + r[5] * lz  # (Roblox Y = Blender z, Roblox -Z = Blender y)
                    y = -(p[2] + r[6] * lx + r[7] * ly + r[8] * lz)
                    out.append((prt["g"], x, y, z))
    return out


CORNERS = _corners()


def clear(phi, sx, sz, legs=0.0):
    """How high his middle must be at roll phi (scaled sx / sz round the feet; the legs swung by `legs` about x) for
    nothing to go below the floor."""
    s, c = math.sin(phi), math.cos(phi)
    sl, cl = math.sin(legs), math.cos(legs)
    best = -1e9
    for g, x, y, z in CORNERS:
        if g != "Torso":
            z = 2.0 + y * sl + (z - 2.0) * cl
        best = max(best, sx * x * s - sz * (z - C) * c)
    return best


def pivot(r, phi, cx, cz):
    """Roll him by phi about his middle and put the middle at (cx, cz) (model units, his own x / up)."""
    r[4] = phi
    r[0] = cx - C * r[8] * math.sin(phi)
    r[2] = cz - C * r[8] * math.cos(phi)


def tuck(g, k, wide=1.0):
    """The arms slide into the hammer head (k 0..1); out of it, they swing `wide` of WIDE clear of the end caps."""
    g["ArmL"][3] = TUCK * k - WIDE * wide * (1 - k)
    g["ArmR"][3] = -TUCK * k + WIDE * wide * (1 - k)


# ------------------------------------------------------------------ the procedural walk (stays code in the client)
def walk_pose(phase, w, t):  # = POSES.JudgeMartello's walk (every stride a hop), in Blender axes
    p = zero()
    g, r = p["g"], p["root"]
    sw = math.sin(phase)
    hop = abs(math.sin(phase))
    r[2] = hop * 1.0 * w
    legs = -hop * 0.5 * w
    arms = math.sin(t * 9) * 0.35 * w
    g["LegL"][0], g["LegR"][0] = legs + sw * 0.2 * w, legs - sw * 0.2 * w
    g["ArmL"][0], g["ArmL"][1] = arms, 0.3
    g["ArmR"][0], g["ArmR"][1] = arms, -0.3
    g["Torso"][0] = math.sin(t * 2) * 0.04 * (1 - w)
    g["Torso"][1] = -math.sin(phase) * 0.06 * w
    return p


# ------------------------------------------------------------------ A. ANTICIPATION + THE HOP (windup, 1.1 s)
def roll_at(t):  # cocks back at the top, then swings over into the strike (accelerating: a gavel's swing)
    return ev([(APEX - 0.12, 0), (APEX, -0.38, "out"), (WINDUP, STRIKE_ROLL, "in")], t)


def hop_height(t):
    """The middle's height (model units): from the crouch up to HOP above standing at the apex, then falling (it reaches
    the floor as the windup ends; clear() keeps him on it - the end cap lands)."""
    return ev([(LAUNCH, C * 0.7), (APEX, C + HOP, "out"), (WINDUP, 0.0, "in")], t)


def clip_windup(t):
    p = zero()
    g, r = p["g"], p["root"]
    # NOTICE: the brows slam down into a scowl, the jabot puffs
    g["Brows"][5] = ev([(0, 0), (0.05, -0.12, "out"), (0.62, -0.12), (0.8, 0.05), (WINDUP, 0.12, "in")], t)
    g["Jabot"][0] = ev([(0, 0), (0.06, 0.25, "out"), (0.16, 0.0)], t) + ramp(t, LAUNCH, LAUNCH + 0.06) * 0.5 \
        - ramp(t, APEX, WINDUP) * 0.3
    # CROUCH: squashed flat, arms swing back - then LAUNCH: stretched tall, arms flung up (two mini gavels fly out of
    # the gloves: the Gavel Rain), up he goes
    sq = ev([(0, 1.0), (0.04, 1.06, "out"), (0.24, 0.72, "out"), (LAUNCH, 0.7), (LAUNCH + 0.05, 1.3, "expo"),
             (APEX - 0.1, 1.06), (APEX, 0.94, "out"), (APEX + 0.12, 1.0), (WINDUP - 0.08, 1.12, "in"), (WINDUP, 1.08)], t)
    squash(r, sq)
    arms = ev([(0, 0), (0.24, -0.7, "out"), (LAUNCH, -0.75), (LAUNCH + 0.06, 2.9, "expo"), (APEX - 0.1, 2.7),
               (APEX, 0.0, "io")], t)
    g["ArmL"][0] = g["ArmR"][0] = arms
    g["ArmL"][1], g["ArmR"][1] = ev([(0, 0.3), (0.24, 0.1), (APEX, 0.0)], t), ev([(0, -0.3), (0.24, -0.1), (APEX, 0.0)], t)
    tuck(g, ev([(APEX - 0.08, 0), (APEX + 0.04, 1, "back")], t), ramp(t, 0, 0.1))  # the cannonball: arms in for the strike
    # the legs: braced in the crouch, kick straight at the launch, pull together under him in the air
    legs = ev([(0, 0), (0.24, 0.2), (LAUNCH, 0.22), (LAUNCH + 0.06, -0.15, "out"), (APEX, 0.0)], t)
    g["LegL"][0], g["LegR"][0] = legs, legs
    g["LegL"][1], g["LegR"][1] = ev([(APEX - 0.1, 0), (APEX + 0.1, -0.04)], t), ev([(APEX - 0.1, 0), (APEX + 0.1, 0.04)], t)
    # THE HOP: up off the floor at the launch, a cock back at the top, then the swing over onto his end cap
    phi = roll_at(t)
    pivot(r, phi, 0.0, max(hop_height(t), clear(phi, r[6], r[8], legs)))
    # Travel: holds for the crouch, then a straight ballistic line to the spot (lands as the windup ends)
    p["fx"]["Travel"] = ev([(LAUNCH, 0.0), (WINDUP, 1.0, "lin")], t)
    return p


# ------------------------------------------------------------------ B. ATTACK (0.45 s: the strike is its first frame)
def strike_pose(t):
    """On his end cap, the handle (legs) out sideways: BONK - squashed along his length, ringing like a struck tuning
    fork, the legs whipping and kicking."""
    p = zero()
    g, r = p["g"], p["root"]
    tuck(g, 1)
    long = ev([(0, 1.08), (0.03, 0.76, "out"), (0.12, 1.08, "out"), (0.2, 0.97), (0.28, 1.02), (0.45, 1.0)], t)
    r[6], r[7], r[8] = long, 1 / math.sqrt(long), 1 / math.sqrt(long)  # (along his length = his own x)
    phi = STRIKE_ROLL + elastic(t, 0.03, 0.05, 7, 6)  # the ring of the strike
    pivot(r, phi, 0.0, clear(phi, r[6], r[8]))
    whip = elastic(t, 0.0, 0.35, 5, 5)  # the handle whips (both legs together, in his own x-z plane)
    kick = ramp(t, 0.12, 0.18) * 0.35 * math.sin(t * 2 * math.pi * 4)  # then they kick, bicycle style
    g["LegL"][1], g["LegR"][1] = -0.04 + whip, 0.04 + whip
    g["LegL"][0], g["LegR"][0] = kick, -kick
    g["Brows"][5] = ev([(0, 0.12), (0.04, 0.22, "out"), (0.45, 0.16)], t)  # (dazed surprise)
    g["Jabot"][0] = ev([(0, -0.3), (0.03, 0.9, "out"), (0.45, 0.3)], t) + elastic(t, 0.03, 0.2, 6, 5)
    return p


def clip_attack(t):
    return strike_pose(t)


# ------------------------------------------------------------------ D. RECOVERY (0.6 s)
def clip_recover(t):
    p = zero()
    g, r = p["g"], p["root"]
    a1 = strike_pose(ATTACK)
    # ARMS POP OUT (ta-da), a little squash to push off, then HOPS back up onto his feet, a squashy landing, dusts off
    tuck(g, ev([(0.14, 1), (0.24, 0, "back")], t), 1 - ramp(t, 0.4, 0.6))  # (out once he's off the floor and upright)
    arms = ev([(0.2, 0), (0.3, 1.4, "out"), (0.38, 0.5), (0.46, 0.7), (0.52, 0.2), (0.6, 0.0)], t)
    g["ArmL"][0] = g["ArmR"][0] = arms
    g["ArmL"][1] = ev([(0.3, 0), (0.46, 0.25), (0.6, 0.3)], t)
    g["ArmR"][1] = ev([(0.3, 0), (0.46, -0.25), (0.6, -0.3)], t)
    sq = ev([(0, 1.0), (0.1, 0.9), (0.16, 1.1, "out"), (0.3, 1.04), (0.38, 0.8, "in"), (0.46, 1.06, "out"), (0.52, 0.97),
             (0.6, 1.0)], t)
    phi = ev([(0.1, STRIKE_ROLL), (0.34, -0.08, "back"), (0.42, 0.0)], t)
    w = min(1.0, abs(math.sin(phi)))  # (on his end: squashed along his length; upright: squashed down - blended as he rolls)
    k = 1 / math.sqrt(sq)
    r[6], r[7], r[8] = sq * w + k * (1 - w), k, k * w + sq * (1 - w)
    h = ev([(0.1, 0), (0.24, 2.2, "out"), (0.38, 0.0, "in")], t)
    pivot(r, phi, 0.0, clear(phi, r[6], r[8], ev([(0.3, -0.2), (0.38, 0.0)], t) if t > 0.3 else 0.0) + h)
    g["LegL"][1] = ev([(0, a1["g"]["LegL"][1]), (0.3, 0.0)], t)
    g["LegR"][1] = ev([(0, a1["g"]["LegR"][1]), (0.3, 0.0)], t)
    g["LegL"][0] = ev([(0, a1["g"]["LegL"][0]), (0.3, -0.2), (0.38, 0.0)], t)
    g["LegR"][0] = ev([(0, a1["g"]["LegR"][0]), (0.3, -0.2), (0.38, 0.0)], t)
    g["Brows"][5] = ev([(0, 0.16), (0.3, 0.0), (0.48, -0.1, "out"), (0.6, -0.06)], t)  # (back to his scowl, smug)
    g["Jabot"][0] = ev([(0, a1["g"]["Jabot"][0]), (0.3, 0.0)], t) + elastic(t, 0.38, 0.35, 5, 6)
    return p


CLIPS = {  # name -> (function, length s, loops)
    "windup": (clip_windup, WINDUP, False),
    "attack": (clip_attack, ATTACK, False),
    "recover": (clip_recover, RECOVER, False),
}
