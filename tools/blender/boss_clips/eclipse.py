# tools/blender/boss_clips/eclipse.py - Chief Justice Eclipse's GRAVITY PULL + GAVEL ORBIT clips (docs/BOSS_ANIMATION.md
# section 10). Run through tools/blender/boss_anims.py (boss=Eclipse), which execs this file in its own namespace (EASE,
# ev, ramp, zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService, Config.Bosses.List[6]: Attack = { "Pull", "Ring" }, taking turns):
#   Pull: windup 1.4 s (a disc warning, Radius 44, its deadly middle Inner 12), attack = PullTime 2.0 s (everyone within
#         44 is dragged in at 16 studs/s; the middle is a hit every 0.1 s), recover 0.6 s
#   Ring: windup 1.4 s (a disc warning, RingRadius 38), attack 0.45 s (everyone within 38 is hit at its FIRST frame: the
#         gavels fling out to the ring's edge), recover 0.6 s
# A boss with more than one attack has a clip set per attack: windup_<Kind>, attack_<Kind>, recover_<Kind>.
# The ORBIT is code (Bosses.client spins the Gavels group every frame, like the Senior Partner's papers): the clips' Spin
# channel (0..1) sets how fast. The clips move each gavel on the orbit (Gavel1..3: out, up, tumbling) and turn the
# CORONA round the black disc (each cycle ends on a whole turn, so it fades back to the walk without a jump).
# The preview also shows the 2+ player GAVEL VOLLEY (Ring turns only: the orbiting gavels lock onto other players and
# slam down on them - Disc r 10, landing with the ring).
OUT_DIR = os.path.join(REPO, "art", "bosses", "eclipse")
BLEND = "eclipse_pull_orbit.blend"
SCENE_NAME = "EclipsePullOrbit"
SCALE = 3.2  # Config.Bosses.List[6].Scale
COLOR = (190, 120, 255)  # its Config colour (the warnings)
WINDUP, PULL, RING, RECOVER = 1.4, 2.0, 0.45, 0.6  # Windup, PullTime, BossService's 0.45 s, recover
RADIUS, INNER, RING_R = 44.0, 12.0, 38.0
T_WIND = 0.5  # cycle 1 = the Pull, cycle 2 = the Ring
T_PULL = T_WIND + WINDUP
T_REC1 = T_PULL + PULL
T_WALK2 = T_REC1 + RECOVER
T_WIND2 = T_WALK2 + 0.5
T_RING = T_WIND2 + WINDUP
T_REC2 = T_RING + RING
T_WALK3 = T_REC2 + RECOVER
T_END = T_WALK3 + 0.5
VOLLEY_R, LOCK_ON = 10.0, 0.85  # Gavel Volley discs (Config.Bosses.List[6].Crowd.Radius); the gavels leave the orbit then
TURN = (0.08, 0.35)  # an eerie, gliding turn ...
LEAD = ("Head", 0.4)  # ... the eclipse turns to you first
FX_CHANNELS = ("Spin",)
ORBIT_SPIN = (1.6, 13.0)  # the orbit's rad/s at Spin 0 and 1 (Bosses.client spins it)
HOVER = 0.7  # he floats this high (model units) as he glides (POSES.Eclipse)
CHECK_SKIP_PARTS = ()
CHECK_SKIP_GROUPS = ()
# folds (hidden by design): the corona ring sits round the black disc's rim (its blocks touch the disc's strip ends as it
# turns) and its lowest blocks set behind the collar (as at rest: each block in turn as it goes round); the sleeves'
# tops at the shoulders
CHECK_FOLDS = (("Corona", "Head"), ("Corona", "Torso"), ("ArmL", "Torso"), ("ArmR", "Torso"))
GAVELS = ("Gavel1", "Gavel2", "Gavel3")
GAVEL_ANGLE = {g: k * 2 * math.pi / 3 for k, g in enumerate(GAVELS)}  # each gavel's place on the orbit (bosses.py)
RING_OUT = RING_R / SCALE - 3.2  # how far out (model units) the gavels fly to reach the ring's edge


def elastic(t, t0, amp, freq, decay):
    if t < t0:
        return 0.0
    k = t - t0
    return amp * math.exp(-decay * k) * math.sin(2 * math.pi * freq * k)


def gavels(g, out, up, tumble, t, wobble=0.0):
    """Every orbiting gavel `out` model units further from his head, `up` higher, tumbling end over end by `tumble`
    (about its own radial axis), each a little out of step."""
    for k, name in enumerate(GAVELS):
        a = GAVEL_ANGLE[name]
        g[name][3] = math.cos(a) * out
        g[name][4] = math.sin(a) * out
        g[name][5] = up + wobble * math.sin(t * 7 + k * 2.1)
        # tumbling about its own radial axis (its head's long axis: every point keeps its distance from his head)
        e = Matrix.Rotation(tumble, 3, Vector((math.cos(a), math.sin(a), 0))).to_euler("XYZ")
        g[name][0], g[name][1], g[name][2] = e.x, e.y, e.z


# ------------------------------------------------------------------ the procedural glide (stays code in the client)
def walk_pose(phase, w, t):  # = POSES.Eclipse's float, in Blender axes (the orbit is spun by the bake / the client)
    p = zero()
    g, r = p["g"], p["root"]
    r[2] = HOVER + math.sin(t * 1.5) * 0.3
    arms = math.sin(t * 1.2) * 0.1
    g["ArmL"][0] = g["ArmR"][0] = arms
    g["Head"][0] = math.sin(t * 0.9) * 0.08
    g["Head"][2] = math.sin(t * 0.5) * 0.3
    g["Torso"][1] = -math.sin(t * 0.8) * 0.03
    return p


# ------------------------------------------------------------------ the corona's turn (whole turns at the cycle's end)
def corona_pull(T):  # T = time since the Pull's windup began: windup + attack + recover = 4.0 s, 5 whole turns
    return ev([(0.1, 0), (1.4, 2.2 * math.pi, "in"), (3.4, 9.0 * math.pi, "lin"), (4.0, 10.0 * math.pi, "out")], T)


def corona_ring(T):  # windup + attack + recover = 2.45 s, 3 whole turns
    return ev([(0.1, 0), (1.3, 2.0 * math.pi, "in"), (1.52, 4.4 * math.pi, "out"), (2.45, 6.0 * math.pi, "out")], T)


# ------------------------------------------------------------------ GRAVITY PULL
UP_ARMS = (2.25, 0.4)  # the summoning pose: arms raised forward + up (rx), spread (ry)
HALO = -0.95  # while his arms are up the corona slides back behind his shoulders (a halo behind the eclipse)
REACH = (1.6, 0.55)  # the pulling pose: arms out at everyone, spread wide


def arms(g, rx, spread):  # both arms raised forward by rx, then opened out sideways by spread (a turn about the vertical)
    g["ArmL"][0] = g["ArmR"][0] = rx
    g["ArmL"][2], g["ArmR"][2] = spread, -spread


def clip_windup_pull(t):
    p = zero()
    g, r = p["g"], p["root"]
    # NOTICE: the eclipse tilts to you; RISE: up off the floor, the arms come up forward to summon; the gavels lift and
    # spin up above his reach; CHARGE: a slow tremble; WIND BACK then REACH OUT at everyone
    g["Head"][0] = ev([(0, 0), (0.12, 0.12, "out"), (0.5, 0.05), (1.1, 0.12), (1.3, 0.18), (1.4, -0.08, "in")], t)
    r[2] = ev([(0, HOVER), (0.55, HOVER + 1.4, "out"), (1.1, HOVER + 1.5), (1.3, HOVER + 1.75, "out"), (1.4, HOVER + 1.6)], t) \
        + 0.12 * math.sin(t * 3) * ramp(t, 0.5, 0.7)
    rx = ev([(0.1, 0), (0.55, UP_ARMS[0], "out"), (1.1, UP_ARMS[0] + 0.05), (1.3, UP_ARMS[0] + 0.12, "out"), (1.4, REACH[0], "in")], t)
    spread = ev([(0.1, 0), (0.55, UP_ARMS[1], "out"), (1.1, UP_ARMS[1]), (1.3, UP_ARMS[1] + 0.1), (1.4, REACH[1], "in")], t)
    arms(g, rx, spread)
    trem = ramp(t, 0.6, 1.0) * (1 - ramp(t, 1.25, 1.3))
    g["ArmL"][1] = trem * 0.04 * math.sin(t * 61)
    g["ArmR"][1] = -trem * 0.04 * math.sin(t * 57)
    g["Torso"][0] = ev([(1.1, 0), (1.3, 0.1, "out"), (1.4, -0.06, "in")], t)  # (wind back, then lean in)
    gavels(g, ev([(0.1, 0), (0.55, 0.9, "out")], t), ev([(0.1, 0), (0.55, 0.9, "out")], t), 0.0, t, 0.08 * ramp(t, 0.5, 0.7))
    p["fx"]["Spin"] = ev([(0.05, 0), (0.6, 0.7, "out"), (1.4, 1.0)], t)
    g["Corona"][1] = corona_pull(t)
    g["Corona"][4] = ev([(0.08, 0), (0.4, HALO, "out")], t)
    return p


def clip_attack_pull(t):
    p = zero()
    g, r = p["g"], p["root"]
    # THE PULL: hovering high, arms out at everyone, heaving them in - three hauls - the body tremoring, the corona racing
    heave = sum(ev([(t0, 0), (t0 + 0.18, 1, "out"), (t0 + 0.55, 0, "io")], t) for t0 in (0.05, 0.7, 1.35))
    arms(g, REACH[0] - 0.45 * heave, REACH[1] - 0.3 * heave)
    g["Torso"][0] = -0.06 + 0.1 * heave
    g["Head"][0] = -0.08 + 0.05 * heave
    r[2] = HOVER + 1.6 + 0.1 * math.sin(t * 4) + 0.15 * heave
    r[0] = 0.03 * math.sin(t * 53)
    g["ArmL"][1] = 0.04 * math.sin(t * 61)
    g["ArmR"][1] = -0.04 * math.sin(t * 57)
    gavels(g, 0.9, 0.9, 0.0, t, 0.08)
    p["fx"]["Spin"] = 1.0
    g["Corona"][1] = corona_pull(WINDUP + t)
    g["Corona"][4] = HALO
    squash(r, 1 + 0.03 * heave)
    return p


def clip_recover_pull(t):
    p = zero()
    g, r = p["g"], p["root"]
    a1 = clip_attack_pull(PULL)
    # lets go: arms drop, he sinks back to his glide (overshoots a touch), the gavels come back down, the orbit slows
    k = ev([(0, 0), (0.45, 1, "io")], t)
    arms(g, REACH[0] * (1 - k), REACH[1] * (1 - k))
    g["Torso"][0] = a1["g"]["Torso"][0] * (1 - k)
    g["Head"][0] = ev([(0, a1["g"]["Head"][0]), (0.4, 0.04), (0.6, 0.0)], t)
    r[2] = ev([(0, a1["root"][2]), (0.4, HOVER - 0.2, "io"), (0.6, HOVER, "io")], t)
    gavels(g, 0.9 * (1 - k), 0.9 * (1 - k) + elastic(t, 0.4, 0.12, 4, 6), 0.0, t)
    p["fx"]["Spin"] = ev([(0, 1.0), (0.6, 0.0, "io")], t)
    g["Corona"][1] = corona_pull(WINDUP + PULL + t)
    g["Corona"][4] = ev([(0.15, HALO), (0.5, 0.0, "io")], t)
    return p


# ------------------------------------------------------------------ GAVEL ORBIT
WIDE = 1.35  # arms out to the sides


def clip_windup_ring(t):
    p = zero()
    g, r = p["g"], p["root"]
    # NOTICE; SPREAD: arms out wide, the gavels spin up, widen and start tumbling; CHARGE: rising, trembling; GATHER: arms
    # pulled in, the body crunched, the gavels drawn in tight - loaded
    g["Head"][0] = ev([(0, 0), (0.12, 0.12, "out"), (0.6, 0.06), (1.1, 0.1), (1.3, -0.06), (1.4, 0.0)], t)
    side = ev([(0.1, 0), (0.6, WIDE, "back"), (1.1, WIDE + 0.08), (1.3, 0.2, "out"), (1.4, 0.15)], t)
    g["ArmL"][1], g["ArmR"][1] = side, -side
    g["ArmL"][0] = g["ArmR"][0] = ev([(1.1, 0), (1.3, 0.55, "out"), (1.4, 0.6)], t)
    trem = ramp(t, 0.7, 1.05) * (1 - ramp(t, 1.1, 1.15))
    r[2] = ev([(0, HOVER), (0.6, HOVER + 0.5, "out"), (1.1, HOVER + 0.7), (1.4, HOVER + 0.5, "in")], t) + trem * 0.04 * math.sin(t * 70)
    squash(r, ev([(0, 1.0), (1.1, 1.0), (1.3, 0.88, "out"), (1.4, 0.86)], t))
    out = ev([(0.1, 0), (0.6, 0.6, "out"), (1.1, 0.75), (1.3, -0.25, "out"), (1.4, -0.3)], t)
    gavels(g, out, ev([(0.1, 0), (0.6, 0.3), (1.3, 0.0)], t), ev([(0.3, 0), (1.4, 5 * math.pi, "in")], t), t, 0.06 * trem)
    p["fx"]["Spin"] = ev([(0.05, 0), (0.6, 0.5, "out"), (1.1, 0.9), (1.4, 1.0)], t)
    g["Corona"][1] = corona_ring(t)
    return p


def clip_attack_ring(t):
    p = zero()
    g, r = p["g"], p["root"]
    w1 = clip_windup_ring(WINDUP)
    # BURST: arms flung out, stretched tall, the gavels fly OUT to the ring's edge (the hit is this first frame), hang
    # there tumbling, then start back
    side = ev([(0, w1["g"]["ArmL"][1]), (0.06, WIDE + 0.2, "expo"), (0.3, WIDE + 0.1), (0.45, WIDE)], t)
    g["ArmL"][1], g["ArmR"][1] = side, -side
    g["ArmL"][0] = g["ArmR"][0] = ev([(0, 0.6), (0.06, -0.15, "out"), (0.45, 0.0)], t)
    g["Head"][0] = ev([(0, 0), (0.05, 0.16, "out"), (0.45, 0.04)], t)
    r[2] = ev([(0, w1["root"][2]), (0.08, HOVER + 0.9, "out"), (0.45, HOVER + 0.6)], t)
    squash(r, ev([(0, 0.86), (0.05, 1.14, "expo"), (0.16, 0.97), (0.26, 1.02), (0.45, 1.0)], t))
    out = ev([(0, -0.3), (0.1, RING_OUT, "expo"), (0.24, RING_OUT - 0.3), (0.45, RING_OUT * 0.45, "io")], t)
    gavels(g, out, ev([(0, 0), (0.1, -1.2, "out"), (0.45, -0.6)], t), 5 * math.pi + 9 * t, t)
    p["fx"]["Spin"] = 1.0
    g["Corona"][1] = corona_ring(WINDUP + t)
    return p


def clip_recover_ring(t):
    p = zero()
    g, r = p["g"], p["root"]
    a1 = clip_attack_ring(RING)
    # the gavels come home and settle into their orbit (a little overshoot), arms down, the orbit slows
    out = ev([(0, RING_OUT * 0.45), (0.35, -0.2, "out"), (0.5, 0.0)], t)
    tumble = ev([(0, 5 * math.pi + 9 * RING), (0.4, 10 * math.pi, "out")], t)  # (ends on whole turns: upright again)
    gavels(g, out, ev([(0, -0.6), (0.35, 0.1), (0.5, 0.0)], t), tumble, t)
    side = ev([(0, a1["g"]["ArmL"][1]), (0.5, 0.0, "io")], t)
    g["ArmL"][1], g["ArmR"][1] = side, -side
    r[2] = ev([(0, a1["root"][2]), (0.45, HOVER - 0.15, "io"), (0.6, HOVER)], t)
    g["Head"][0] = ev([(0, a1["g"]["Head"][0]), (0.5, 0.0)], t)
    p["fx"]["Spin"] = ev([(0, 1.0), (0.6, 0.0, "io")], t)
    g["Corona"][1] = corona_ring(WINDUP + RING + t)
    return p


CLIPS = {  # name -> (function, length s, loops)
    "windup_Pull": (clip_windup_pull, WINDUP, False),
    "attack_Pull": (clip_attack_pull, PULL, False),
    "recover_Pull": (clip_recover_pull, RECOVER, False),
    "windup_Ring": (clip_windup_ring, WINDUP, False),
    "attack_Ring": (clip_attack_ring, RING, False),
    "recover_Ring": (clip_recover_ring, RECOVER, False),
}
