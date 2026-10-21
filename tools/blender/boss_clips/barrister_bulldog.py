# tools/blender/boss_clips/barrister_bulldog.py - Barrister Bulldog's OBJECTION BARK clips (docs/BOSS_ANIMATION.md
# section 8). Run through tools/blender/boss_anims.py (boss=BarristerBulldog), which execs this file in its own namespace
# (EASE, ev, ramp, zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService "Ring" + Config.Bosses.List[2]): walk in, windup 1.4 s (the disc warning,
# Radius 34 round him), attack 0.45 s (everyone within 34 is hit at its FIRST frame: the bark), recover 0.6 s, walk off.
# So the bark - jaw wide, the wig blown off his head - is the attack's first frame.
# His legs are rigid blocks on the boss root, so he crouches / lunges / recoils with the TORSO (the leg tops fold into
# the body, hidden), and a splayed leg stands on its paw's corner (feet() lifts the root by exactly that).
# The preview also shows the 2+ player ECHO BARK (the bark's sound wave travels to each other player and goes off round
# them: Disc r 12, landing with the bark).
OUT_DIR = os.path.join(REPO, "art", "bosses", "barrister_bulldog")
BLEND = "barrister_bulldog_bark.blend"
SCENE_NAME = "BulldogBark"
SCALE = 3.5  # Config.Bosses.List[2].Scale
COLOR = (255, 90, 90)  # its Config colour (the warnings)
WINDUP, ATTACK, RECOVER = 1.4, 0.45, 0.6
RING_R = 34.0  # the bark (Config.Bosses.List[2].Radius)
T_WIND = 0.5
T_ATTACK = T_WIND + WINDUP
T_RECOVER = T_ATTACK + ATTACK
T_WALK2 = T_RECOVER + RECOVER
T_END = T_WALK2 + 0.6
ECHO_R, ECHO_LEAVE = 12.0, 0.95  # Echo Bark discs (Config.Bosses.List[2].Crowd.Radius); the waves leave his mouth then
TURN = (0.04, 0.22)  # a quick dog's turn ...
LEAD = ("Head", 0.18)  # ... his head leads it (the legs stand on the root)
FX_CHANNELS = ()
CHECK_SKIP_PARTS = ("Mouth", "Tongue")  # (the inside of the mouth sits inside the head / jaw by design)
CHECK_SKIP_GROUPS = ()
LEGS = ("LegFL", "LegFR", "LegBL", "LegBR")
# folds (hidden by design): the jaw's back swings up into the head as it opens; the jowls hang over the jaw's sides and
# from the snout (cheek flaps); the ears' roots sit under the wig's side rolls; the leg tops inside the body (hips);
# the neck: he has none - the head's back half is buried in the chest, so it folds there as it turns, rears and bows
CHECK_FOLDS = (("Head", "Torso"), ("Jaw", "Head"), ("Jaw", "JowlL"), ("Jaw", "JowlR"), ("JowlL", "Head"), ("JowlR", "Head"),
               ("EarL", "Wig"), ("EarR", "Wig")) + tuple((leg, "Torso") for leg in LEGS)


def elastic(t, t0, amp, freq, decay):
    """A decaying wobble that starts at t0 (secondary motion: the jowls, the bow tie, the wig)."""
    if t < t0:
        return 0.0
    k = t - t0
    return amp * math.exp(-decay * k) * math.sin(2 * math.pi * freq * k)


PAW = (-0.625, 0.925)  # each paw's back / front edge, from its leg's joint (model units); the joint is 1.9 up


def feet(p):
    """A splayed rigid leg stands on its paw's corner: lift the root so the lowest corner is on the floor."""
    drop = 0.0
    for leg in LEGS:
        a = p["g"][leg][0]
        drop = max(drop, max(1.9 - (y * math.sin(a) + 1.9 * math.cos(a)) for y in PAW))
    p["root"][2] += drop
    return p


# ------------------------------------------------------------------ the procedural walk / idle (stays code in the client)
def walk_pose(phase, w, t):  # = POSES.BarristerBulldog's walk, in Blender axes
    p = zero()
    g, r = p["g"], p["root"]
    sw = math.sin(phase)
    r[2] = abs(math.cos(phase)) * 0.18 * w
    r[4] = -sw * 0.045 * w
    g["LegFL"][0], g["LegFR"][0] = sw * 0.45 * w, -sw * 0.45 * w
    g["LegBL"][0], g["LegBR"][0] = -sw * 0.45 * w, sw * 0.45 * w
    g["Head"][0] = math.sin(phase * 2) * 0.04 * w
    g["Head"][2] = math.sin(t * 0.7) * 0.2 * (1 - w)
    g["Tail"][2] = math.sin(t * 12) * 0.55
    return p


# ------------------------------------------------------------------ A. ANTICIPATION (windup, 1.4 s)
PUFF = (1.14, 1.0, 1.1)  # the chest puffed up with air (sx, sy, sz round the feet): he swells


def puff(r, k):
    r[6] = 1 + (PUFF[0] - 1) * k
    r[7] = 1 + (PUFF[1] - 1) * k
    r[8] = 1 + (PUFF[2] - 1) * k


def clip_windup(t):
    p = zero()
    g, r = p["g"], p["root"]
    trem = ramp(t, 0.95, 1.2) * (1 - ramp(t, 1.25, 1.3))
    # NOTICE: ears perk, a "huh?" head lift and two sniffs, the tail stops wagging
    perk = ev([(0, 0), (0.08, 0.5, "back"), (0.2, 0.35), (0.3, 0.0, "io")], t)
    flat = ev([(0.22, 0), (0.36, -0.45, "out"), (0.95, -0.5), (1.2, -0.3), (1.32, -0.6, "in")], t)  # then back flat: angry
    g["EarL"][1], g["EarR"][1] = perk, -perk
    g["EarL"][0] = g["EarR"][0] = flat
    g["Head"][0] = ev([(0, 0), (0.07, 0.12, "out"), (0.14, 0.02), (0.2, 0.07), (0.26, -0.02), (0.4, -0.12, "out"),
                       (0.52, -0.1), (0.92, 0.27, "out"), (1.25, 0.28), (1.4, -0.05, "in")], t)
    g["Tail"][0] = ev([(0.1, 0), (0.3, -0.3, "back"), (1.25, -0.35), (1.4, -0.4)], t)  # stiff, sticking up
    g["Tail"][2] = math.sin(t * 12) * 0.55 * (1 - ramp(t, 0.0, 0.18)) + trem * 0.06 * math.sin(t * 70)
    # PLANT: front paws splay forward, the back legs dig in, he sinks into a crouch and GROWLS (a snarl, jowls quiver)
    g["LegFL"][0] = g["LegFR"][0] = ev([(0.12, 0), (0.3, 0.24, "back"), (0.52, 0.24), (0.92, 0.1), (1.25, 0.1), (1.4, 0.18)], t)
    g["LegBL"][0] = g["LegBR"][0] = ev([(0.12, 0), (0.3, -0.16, "back"), (0.52, -0.16), (0.92, -0.06), (1.4, -0.1)], t)
    g["LegFL"][2], g["LegFR"][2] = ev([(0.12, 0), (0.3, -0.1)], t), ev([(0.12, 0), (0.3, 0.1)], t)
    g["Torso"][5] = ev([(0.12, 0), (0.3, -0.22, "out"), (0.52, -0.2), (0.92, 0.0, "out"), (1.25, 0.0), (1.4, -0.08, "in")], t)
    g["Torso"][4] = ev([(1.25, 0), (1.4, 0.14, "in")], t)  # (lunging into the bark)
    snarl = ev([(0.3, 0), (0.42, -0.1, "out"), (0.52, -0.08), (0.7, 0.0), (1.25, -0.03), (1.4, -0.24, "in")], t)
    g["Jaw"][0] = snarl + ramp(t, 0.32, 0.4) * (1 - ramp(t, 0.55, 0.65)) * 0.02 * math.sin(t * 90)
    quiver = ramp(t, 0.32, 0.4) * (1 - ramp(t, 0.55, 0.7)) * 0.05 * math.sin(t * 75)
    # PUFF UP: a huge breath - he swells (the chest puffs), rears his head, the cheeks (jowls) fill with air
    puff(r, ev([(0.42, 0), (0.92, 1, "out"), (1.25, 1.03), (1.4, 0.9, "in")], t))
    g["Torso"][0] = ev([(0.42, 0), (0.92, 0.04, "out"), (1.25, 0.05), (1.4, -0.03, "in")], t)
    cheeks = ev([(0.6, 0), (0.95, 0.18, "out"), (1.25, 0.2), (1.32, 0.24), (1.4, 0.1)], t) + quiver
    g["JowlL"][1], g["JowlR"][1] = cheeks, -cheeks
    g["BowTie"][0] = ev([(0.42, 0), (0.92, -0.16, "out"), (1.25, -0.18), (1.4, 0.0, "in")], t)  # (the chest lifts it: it tips up)
    g["BowTie"][4] = -0.3 * g["BowTie"][0]  # (out off the chest as it tips)
    # HOLD: trembling, the wig quivering on his head
    r[0] = trem * 0.04 * math.sin(t * 73)
    g["Head"][1] = trem * 0.03 * math.sin(t * 61)
    g["Wig"][5] = trem * 0.05 * abs(math.sin(t * 47))
    return feet(p)


# ------------------------------------------------------------------ B. ATTACK (0.45 s: the bark is its first frame)
JAW_WIDE = -0.62
WIG_UP, WIG_LAND = 2.7, ATTACK + 0.12  # how high the bark blows the wig (model units); when it lands back on (attack t)
ASKEW = (0.12, 0.0, 0.0, 0.0, -0.3, 0.12)  # the wig lands pushed back and up (tipped back), forehead showing


def wig_flight(T):
    """The wig from the bark (T = time since the attack began) until it lands askew in the recover: straight up, a
    full spin high above his head, then straight down onto it (lined up before its side rolls reach his head)."""
    if T >= WIG_LAND:
        return None
    h = ev([(0, 0.0), (0.18, WIG_UP, "out"), (WIG_LAND, ASKEW[5], "in")], T)
    spin = ev([(0.06, 0), (0.34, 2 * math.pi, "io")], T)  # (only once its side rolls are clear of his head)
    tip = ev([(0.06, 0), (0.12, -0.35, "out"), (0.22, 0.3), (0.34, ASKEW[0], "io")], T)
    return (tip, 0.0, spin, 0.0, ev([(0.18, 0), (0.34, ASKEW[4])], T), h)


def clip_attack(t):
    p = zero()
    g, r = p["g"], p["root"]
    w0 = clip_windup(WINDUP)
    # BARK: jaw wide, head thrust forward and down, the puff let out all at once (he shrinks with a recoil)
    vib = ramp(t, 0.03, 0.06) * (1 - ramp(t, 0.26, 0.32))
    g["Jaw"][0] = ev([(0, w0["g"]["Jaw"][0]), (0.035, JAW_WIDE, "out"), (0.3, JAW_WIDE + 0.04), (0.45, -0.08, "io")], t) \
        + vib * 0.06 * math.sin(t * 160)
    g["Head"][0] = ev([(0, w0["g"]["Head"][0]), (0.04, -0.24, "out"), (0.28, -0.2), (0.45, -0.08, "io")], t)
    g["Head"][4] = ev([(0, 0), (0.04, 0.38, "out"), (0.28, 0.34), (0.45, 0.1, "io")], t)  # (thrust forward, out of the chest)
    g["Head"][1] = vib * 0.035 * math.sin(t * 190)
    g["Torso"][0] = ev([(0, w0["g"]["Torso"][0]), (0.04, -0.05, "out"), (0.3, -0.04), (0.45, 0.0)], t)
    puff(r, ev([(0, 0.9), (0.04, -0.45, "out"), (0.14, 0.12, "out"), (0.24, -0.06), (0.34, 0.03), (0.45, 0.0)], t))
    g["Torso"][4] = ev([(0, w0["g"]["Torso"][4]), (0.05, -0.16, "out"), (0.3, -0.1), (0.45, 0.0, "io")], t)  # the recoil
    g["Torso"][5] = ev([(0, w0["g"]["Torso"][5]), (0.06, -0.12), (0.2, -0.04), (0.45, 0.0)], t)
    for leg in ("LegFL", "LegFR"):
        g[leg][0] = ev([(0, 0.18), (0.05, 0.26, "out"), (0.45, 0.06)], t)
    for leg in ("LegBL", "LegBR"):
        g[leg][0] = ev([(0, -0.1), (0.05, -0.18, "out"), (0.45, -0.04)], t)
    g["LegFL"][2], g["LegFR"][2] = ev([(0, -0.1), (0.45, -0.04)], t), ev([(0, 0.1), (0.45, 0.04)], t)
    # the blast: jowls flap out and wobble, ears blown back, the bow tie flutters, the tail stays rigid
    flap = ev([(0, 0.1), (0.04, 0.55, "out")], t) + elastic(t, 0.04, 0.22, 7, 5)
    g["JowlL"][1], g["JowlR"][1] = flap, -flap
    g["JowlL"][0] = g["JowlR"][0] = elastic(t, 0.02, 0.12, 6, 5)
    g["EarL"][0] = g["EarR"][0] = ev([(0, -0.6), (0.04, -0.8, "out"), (0.3, -0.72), (0.45, -0.4, "io")], t)
    g["EarL"][1], g["EarR"][1] = 0.15 * ramp(t, 0, 0.05), -0.15 * ramp(t, 0, 0.05)
    g["BowTie"][0] = ev([(0, 0.0), (0.04, -0.2, "out"), (0.45, 0.0)], t) + elastic(t, 0.04, 0.14, 9, 6)
    g["BowTie"][4] = 0.35 * abs(g["BowTie"][0])  # (blown out off the chest as it flutters)
    g["Tail"][0] = ev([(0, -0.4), (0.45, -0.25)], t)
    g["Tail"][2] = vib * 0.15 * math.sin(t * 120)
    # the WIG blown clean off his head: up, a full spin, coming down
    g["Wig"] = list(wig_flight(t))
    return feet(p)


# ------------------------------------------------------------------ D. RECOVERY (0.6 s)
def clip_recover(t):
    p = zero()
    g, r = p["g"], p["root"]
    a1 = clip_attack(ATTACK)
    # the wig drops back on (askew) at 0.12; the HEAD SHAKE (a wet-dog shake) slides it back into place
    wf = wig_flight(ATTACK + t)
    if wf is not None:
        g["Wig"] = list(wf)
    else:
        home = ev([(0.2, 1.0), (0.42, 0.0, "io")], t)
        g["Wig"] = [ASKEW[0] * home, 0.0, 0.0, 0.0, ASKEW[4] * home, ASKEW[5] * home + abs(elastic(t, 0.12, 0.08, 6, 9))]
    shake = ramp(t, 0.15, 0.19) * math.exp(-5 * max(0.0, t - 0.19)) * (1 - ramp(t, 0.42, 0.48))
    g["Head"][2] = shake * 0.22 * math.sin(2 * math.pi * 9 * (t - 0.15))
    g["Head"][1] = shake * 0.1 * math.sin(2 * math.pi * 9 * (t - 0.15) + 0.6)
    g["Head"][0] = ev([(0, a1["g"]["Head"][0]), (0.1, -0.06), (0.14, -0.1, "out"), (0.22, 0.04), (0.45, 0.06), (0.6, 0.0)], t)
    g["Head"][4] = ev([(0, a1["g"]["Head"][4]), (0.2, 0.0, "io")], t)
    g["Jaw"][0] = ev([(0, a1["g"]["Jaw"][0]), (0.1, -0.02), (0.44, 0.0), (0.5, -0.12, "out"), (0.58, 0.0, "io")], t)  # (a huff)
    jl = -shake * 0.35 * math.sin(2 * math.pi * 9 * (t - 0.15)) + ev([(0, a1["g"]["JowlL"][1]), (0.12, 0.0)], t)
    g["JowlL"][1], g["JowlR"][1] = max(0.0, jl), min(0.0, -jl)  # (they swing out, never in)
    g["JowlL"][0] = g["JowlR"][0] = shake * 0.1 * math.sin(2 * math.pi * 9 * (t - 0.15) + 1.2)
    ears = shake * 0.35 * abs(math.sin(2 * math.pi * 9 * (t - 0.15)))
    g["EarL"][1], g["EarR"][1] = ears, -ears
    g["EarL"][0] = g["EarR"][0] = ev([(0, a1["g"]["EarL"][0]), (0.2, 0.0, "out")], t)
    g["BowTie"][0] = ev([(0, a1["g"]["BowTie"][0]), (0.2, 0.0)], t) + elastic(t, 0.2, 0.1, 8, 7)
    g["BowTie"][4] = 0.35 * abs(g["BowTie"][0])
    g["Torso"][0] = ev([(0, a1["g"]["Torso"][0]), (0.45, 0.03, "out"), (0.6, 0.0)], t)
    for leg in LEGS:
        g[leg][0] = ev([(0, a1["g"][leg][0]), (0.4, 0.0)], t)
    g["LegFL"][2] = ev([(0, a1["g"]["LegFL"][2]), (0.4, 0.0)], t)
    g["LegFR"][2] = ev([(0, a1["g"]["LegFR"][2]), (0.4, 0.0)], t)
    g["Tail"][0] = ev([(0, a1["g"]["Tail"][0]), (0.4, 0.0)], t)
    g["Tail"][2] = math.sin(t * 12) * 0.55 * ramp(t, 0.35, 0.6)  # (wagging again: pleased with himself)
    # the wig landing bumps him, then a smug chest puff
    squash(r, ev([(0, 1.0), (0.12, 1.0), (0.15, 0.95, "out"), (0.22, 1.0), (0.46, 1.0), (0.52, 1.04, "out"), (0.6, 1.0)], t))
    return feet(p)


CLIPS = {  # name -> (function, length s, loops)
    "windup": (clip_windup, WINDUP, False),
    "attack": (clip_attack, ATTACK, False),
    "recover": (clip_recover, RECOVER, False),
}
