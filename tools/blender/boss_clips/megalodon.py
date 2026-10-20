# tools/blender/boss_clips/megalodon.py - Magistrate Megalodon's FIN CHARGE clips (docs/BOSS_ANIMATION.md sections 3
# + 5, the benchmark). Run through tools/blender/boss_anims.py (boss=Megalodon, the default), which execs this file
# in its own namespace (EASE, ev, ramp, zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService "Line" + Config.Bosses.List[5]): walk in, windup 1.0 s, charge 130 studs
# at 150 studs/s, dizzy 2.0 s, recover 0.6 s, walk off. The preview also shows the 2+ player FEEDING FRENZY.
OUT_DIR = os.path.join(REPO, "art", "bosses", "megalodon")
BLEND = "megalodon_charge.blend"
SCENE_NAME = "MegalodonCharge"
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

FX_CHANNELS = ("FinGlow",)  # clip fx channels (0..1): the dorsal fin's glow
CHECK_SKIP_PARTS, CHECK_SKIP_GROUPS = ("FinGlow",), ("Cheek",)  # (the glow shell and the cheek flaps sit inside by design)

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
    g["ArmL"][2] = ev([(0.2, 0), (0.3, 0.3), (0.36, 0.16, "out"), (0.46, 0.16), (0.52, 0.3), (0.6, 0)], t)
    g["ArmL"][1] = ev([(0, 0.15), (0.2, 0.3), (0.3, 0.3), (0.36, -0.2), (0.46, -0.2), (0.49, 0.3), (0.6, 0.15)], t)
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

def post(p):  # every clip frame goes through this before it's exported / previewed
    return cheek(p)
