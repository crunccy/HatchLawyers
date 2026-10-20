# tools/blender/boss_clips/senior_partner.py - The Senior Partner's BRIEFCASE SWING clips (docs/BOSS_ANIMATION.md
# section 6). Run through tools/blender/boss_anims.py (boss=SeniorPartner), which execs this file in its own namespace
# (EASE, ev, ramp, zero, lerp_pose, squash, stretch, DATA, GROUPS, FPS are the engine's).
# The server's timeline (Server.BossService "Cone" + Config.Bosses.List[1]): walk in, windup 1.2 s (the fan warning),
# attack 0.45 s (everyone in the cone - Radius 45, Angle 110 - is hit at its FIRST frame), recover 0.6 s, walk off.
# So the case lands on the ground at attack + 0.05 s: the swing starts in the windup's last 0.14 s.
# The preview also shows the 2+ player PAPER STORM (case-file bundles lobbed at the others, Disc r 10, landing with the
# swing).
OUT_DIR = os.path.join(REPO, "art", "bosses", "senior_partner")
BLEND = "senior_partner_swing.blend"
SCENE_NAME = "PartnerSwing"
SCALE = 3.5  # Config.Bosses.List[1].Scale
COLOR = (255, 120, 60)  # its Config colour (the warnings)
WINDUP, ATTACK, RECOVER = 1.2, 0.45, 0.6
RADIUS, ANGLE = 45.0, 110.0  # the cone
T_WIND = 0.5
T_ATTACK = T_WIND + WINDUP
T_RECOVER = T_ATTACK + ATTACK
T_WALK2 = T_RECOVER + RECOVER
T_END = T_WALK2 + 0.6
STORM_R, STORM_OPEN = 10.0, 0.78  # Paper Storm discs (Config.Bosses.List[1].Crowd.Radius); bundles leave the case then
STRIKE = 0.05  # attack t when the case hits the ground
TURN = (0.06, 0.28)  # a heavier, more deliberate turn than the shark's whip-round
LEAD = ("Head", 0.45)  # his HEAD leads the turn (twisting the torso would swing the case into his legs)
FX_CHANNELS = ("Swirl",)  # 0..1: the papers at his ankles whirl faster and rise (the client spins the Papers group)
CHECK_SKIP_PARTS = ("Files", "Folder")  # (the papers inside the case sit inside it by design)
CHECK_SKIP_GROUPS = ("Papers",)  # (loose sheets whirling round his ankles: drawn by code, not the clips)
CHECK_FOLDS = (("LegL", "Torso"), ("LegR", "Torso"))  # hip folds: leg tops inside the hips / jacket (hidden), listed apart


def elastic(t, t0, amp, freq, decay):
    """A decaying wobble that starts at t0 (secondary motion: the case on its handle, the moustache)."""
    if t < t0:
        return 0.0
    k = t - t0
    return amp * math.exp(-decay * k) * math.sin(2 * math.pi * freq * k)


# ------------------------------------------------------------------ the procedural walk / idle (stays code in the client)
def walk_pose(phase, w, t):  # = POSES.SeniorPartner's walk, in Blender axes
    p = zero()
    g, r = p["g"], p["root"]
    sw = math.sin(phase)
    r[2] = abs(math.cos(phase)) * 0.25 * w
    g["LegL"][0], g["LegR"][0] = sw * 0.5 * w, -sw * 0.5 * w
    g["ArmL"][0], g["ArmR"][0] = -sw * 0.35 * w, sw * 0.15 * w
    g["Torso"][1] = -sw * 0.03 * w
    g["Head"][0] = math.sin(t * 1.3) * 0.02
    g["Head"][2] = math.sin(t * 0.45) * 0.18 * (1 - w)
    return p


# ------------------------------------------------------------------ A. ANTICIPATION (windup, 1.2 s)
UP = 3.42  # the arm overhead (a touch past vertical: the case cocked behind his head)


def arm_r_windup(t):
    return ev([(0, 0), (0.4, 0.0), (0.52, -0.5, "out"), (0.84, UP + 0.12, "out"), (0.92, UP, "io"), (1.0, UP + 0.05),
               (1.06, UP + 0.1, "io"), (1.2, UP - 0.95, "in")], t)


def clip_windup(t):
    p = zero()
    g, r = p["g"], p["root"]
    trem = ramp(t, 0.86, 1.04) * (1 - ramp(t, 1.06, 1.1))
    # NOTICE + ADJUST GLASSES: chin up ("hm?"), the left hand pushes the glasses up the nose, brows drop to a scowl
    g["Head"][0] = ev([(0, 0), (0.07, 0.1, "out"), (0.2, 0.06), (0.32, 0.06), (0.44, -0.03), (0.6, 0.06), (0.85, 0.08),
                       (1.06, 0.07), (1.2, -0.06, "in")], t)
    g["Head"][2] = ev([(0.08, 0), (0.2, 0.22, "out"), (0.32, 0.22), (0.44, 0.0, "io")], t)
    g["Brows"][5] = ev([(0, 0), (0.07, 0.1, "out"), (0.26, -0.11, "back"), (1.2, -0.1)], t)
    g["Brows"][0] = ev([(0.07, 0), (0.26, -0.12, "back")], t)
    g["Glasses"][5] = ev([(0.16, 0), (0.24, 0.13, "out"), (0.34, 0.05, "io")], t)
    g["Glasses"][1] = ev([(0.16, 0), (0.24, -0.1, "out"), (0.34, 0.0, "io")], t)  # (pushed up from his left: they tilt)
    g["ArmL"][0] = ev([(0, 0), (0.05, 0), (0.17, 2.6, "out"), (0.32, 2.6), (0.37, 2.5), (0.46, 1.2, "io"), (0.52, 0.5, "io"),
                       (0.68, 1.4, "back"), (1.06, 1.45), (1.2, 0.6, "in")], t)
    g["ArmL"][2] = ev([(0.1, 0), (0.2, -0.4, "out"), (0.32, -0.4), (0.37, 0.0, "io"), (0.68, -0.1), (1.2, 0)], t)
    g["ArmL"][1] = ev([(0.08, 0), (0.18, -0.08), (0.32, -0.08), (0.37, 0), (0.48, 0.15), (0.68, 0.0)], t)
    g["Moustache"][0] = ev([(0.2, 0), (0.25, 0.2, "out"), (0.34, 0.0, "io")], t) + trem * 0.06 * (1 + math.sin(t * 80))
    # PLANT THE STANCE: the left foot forward, the right back, a stomp
    g["LegL"][0] = ev([(0.3, 0), (0.42, 0.12, "out")], t)
    g["LegR"][0] = ev([(0.3, 0), (0.37, -0.3, "out"), (0.44, -0.1, "in")], t)
    g["LegL"][1] = ev([(0.3, 0), (0.42, 0.05)], t)
    g["LegR"][1] = ev([(0.3, 0), (0.44, -0.05)], t)
    r[2] = ev([(0.3, 0), (0.37, 0.4, "out"), (0.44, 0.11, "in")], t)  # (the stomp lifts him; the split stance keeps the toe up)
    # RAISE: the case dips back, then swings up over his head; he leans back and twists the right shoulder away
    g["ArmR"][0] = arm_r_windup(t)
    g["ArmR"][1] = ev([(0.52, 0), (0.84, -0.12)], t)
    g["Torso"][0] = ev([(0, 0), (0.24, 0.05, "out"), (0.36, 0), (0.52, -0.06), (0.84, 0.17, "out"), (1.06, 0.2),
                        (1.2, 0.0, "in")], t)
    g["Torso"][2] = ev([(0.4, 0), (0.52, 0.06), (0.84, -0.3, "out"), (1.06, -0.33), (1.2, -0.05, "in")], t)
    g["Torso"][1] = trem * 0.025 * math.sin(t * 66)
    r[0] = trem * 0.05 * math.sin(t * 73)
    # the case trails the arm on its handle (and swings on after it stops)
    g["Case"][0] = ev([(0.4, 0), (0.52, 0.25, "out"), (0.66, -0.55), (0.84, 0.2, "out"), (0.95, -0.06), (1.06, 0),
                       (1.2, 0.35, "in")], t)
    g["Case"][1] = ev([(0.52, 0), (0.84, 0.1), (1.06, 0.06), (1.2, 0.0)], t)
    # PAPERS SWIRL: the lid bursts open at the top, files spill out swirling, the lid snaps shut for the swing
    g["CaseLid"][1] = ev([(0.72, 0), (0.79, 1.25, "back"), (0.88, 0.95), (0.95, 1.1), (1.02, 0, "in")], t)
    p["fx"]["Swirl"] = ev([(0.7, 0), (0.86, 1, "out"), (1.2, 1)], t)
    # squash: a harrumph puff, a squash on the stomp, stretched tall at the top of the raise, loaded for the swing
    squash(r, ev([(0, 1), (0.24, 1.04, "out"), (0.34, 1), (0.42, 0.94, "out"), (0.5, 1.0), (0.84, 1.07, "out"),
                  (1.06, 1.06), (1.2, 0.98, "in")], t))
    return p


# ------------------------------------------------------------------ B. ATTACK (0.45 s: the strike lands at 0.05)
DOWN = 0.95  # the arm at the strike: the case's back corner on the ground in front of him (found by the clipping check)


def clip_attack(t):
    p = zero()
    g, r = p["g"], p["root"]
    w0 = clip_windup(WINDUP)
    shud = elastic(t, STRIKE, 1.0, 22, 9)
    g["ArmR"][0] = ev([(0, UP - 0.95), (STRIKE, DOWN, "in"), (0.3, DOWN - 0.03), (0.34, DOWN + 0.06, "out"),
                       (0.4, DOWN - 0.02, "io"), (0.45, DOWN)], t) + 0.02 * shud
    g["ArmR"][1] = ev([(0, 0), (STRIKE, 0.04, "in")], t)
    g["ArmR"][2] = ev([(0, 0), (STRIKE, 0.06, "in")], t)
    g["Torso"][0] = ev([(0, w0["g"]["Torso"][0]), (STRIKE, -0.37, "in"), (0.3, -0.36), (0.35, -0.29, "out"),
                        (0.42, -0.36, "io"), (0.45, -0.35)], t)
    g["Torso"][2] = ev([(0, w0["g"]["Torso"][2]), (STRIKE, 0.24, "in"), (0.2, 0.2)], t)
    g["Head"][0] = ev([(0, w0["g"]["Head"][0]), (STRIKE, -0.06, "in"), (0.1, -0.12, "out"), (0.24, 0.08, "back"),
                       (0.45, 0.04)], t)
    g["Case"][0] = ev([(0, w0["g"]["Case"][0]), (STRIKE, 0.0, "in")], t) - 0.04 * shud
    g["Case"][1] = 0.08 * shud  # (it judders on its handle)
    g["CaseLid"][1] = ev([(STRIKE, 0), (STRIKE + 0.04, 0.38, "out"), (0.2, 0.12), (0.45, 0.06)], t)
    g["ArmL"][0] = ev([(0, w0["g"]["ArmL"][0]), (STRIKE, -0.45, "in"), (0.2, -0.35, "out"), (0.45, -0.28)], t)
    g["ArmL"][1] = ev([(0, 0), (STRIKE, 0.3, "in"), (0.45, 0.26)], t)
    g["LegL"][0], g["LegR"][0] = w0["g"]["LegL"][0], w0["g"]["LegR"][0]
    g["LegL"][1], g["LegR"][1] = w0["g"]["LegL"][1], w0["g"]["LegR"][1]
    r[2] = w0["root"][2]
    # the impact jolts the face: moustache flaps up, glasses jump down the nose (crooked), brows shoot up
    g["Moustache"][0] = abs(elastic(t, STRIKE, 0.4, 5, 7))  # (it flaps UP, off the face)
    g["Glasses"][5] = ev([(0, 0.05), (STRIKE, 0.05), (STRIKE + 0.05, -0.15, "out")], t)
    g["Glasses"][1] = ev([(STRIKE, 0), (STRIKE + 0.06, 0.2, "back")], t)
    g["Brows"][5] = ev([(0, -0.1), (STRIKE, -0.1), (STRIKE + 0.05, 0.12, "out"), (0.3, 0.02)], t)
    g["Brows"][0] = ev([(0, -0.12), (STRIKE, -0.12), (STRIKE + 0.05, 0.0, "out")], t)
    p["fx"]["Swirl"] = ev([(0, 1), (STRIKE, 1), (0.45, 0.25, "out")], t)
    # IMPACT squash: flattened on the hit, bounces back over a quarter of a second
    squash(r, ev([(0, 0.98), (STRIKE, 0.84, "in"), (0.14, 0.93, "out"), (0.23, 1.03), (0.3, 0.99), (0.36, 1.01),
                  (0.42, 0.99), (0.45, 1.0)], t))
    return p


# ------------------------------------------------------------------ D. RECOVERY (0.6 s)
def clip_recover(t):
    p = zero()
    g, r = p["g"], p["root"]
    a1 = clip_attack(ATTACK)
    # YANK: a heave back that pops the case out of the ground, which swings on its handle
    g["Torso"][0] = ev([(0, a1["g"]["Torso"][0]), (0.06, -0.34), (0.16, 0.12, "out"), (0.3, -0.03), (0.42, 0.05),
                        (0.6, 0, "io")], t)
    g["Torso"][2] = ev([(0, a1["g"]["Torso"][2]), (0.16, 0.0, "out")], t)
    g["ArmR"][0] = ev([(0, a1["g"]["ArmR"][0]), (0.06, DOWN + 0.04), (0.16, 0.45, "out"), (0.32, 0.28), (0.46, 0.1),
                       (0.6, 0)], t)
    g["ArmR"][2] = ev([(0, a1["g"]["ArmR"][2]), (0.16, 0.0, "out")], t)
    g["ArmR"][1] = ev([(0, a1["g"]["ArmR"][1]), (0.16, 0.0, "out")], t)
    g["Case"][0] = ev([(0, a1["g"]["Case"][0]), (0.08, -0.12), (0.16, 0.1, "out"), (0.4, 0)], t)
    g["Case"][1] = ev([(0, a1["g"]["Case"][1]), (0.1, 0.0)], t) + elastic(t, 0.12, 0.26, 2.2, 5)  # (it swings on its handle)
    g["CaseLid"][1] = ev([(0, a1["g"]["CaseLid"][1]), (0.05, 0.0, "in")], t)
    g["Head"][0] = ev([(0, a1["g"]["Head"][0]), (0.16, 0.1, "out"), (0.32, 0.0), (0.42, 0.06), (0.6, 0)], t)
    # TIDY UP: the left hand pushes the glasses back up and they settle straight; brows and moustache settle
    g["ArmL"][0] = ev([(0, a1["g"]["ArmL"][0]), (0.14, 0.2), (0.27, 2.6, "out"), (0.38, 2.6), (0.43, 2.5), (0.52, 0.8, "io"),
                       (0.6, 0)], t)
    g["ArmL"][2] = ev([(0.24, 0), (0.3, -0.4, "out"), (0.38, -0.4), (0.43, 0.0, "io")], t)
    g["Head"][2] = ev([(0.18, 0), (0.29, 0.22, "out"), (0.38, 0.22), (0.5, 0.0, "io")], t)
    g["ArmL"][1] = ev([(0, a1["g"]["ArmL"][1]), (0.14, 0.0), (0.26, -0.08), (0.38, -0.08), (0.43, 0.0)], t)
    g["Glasses"][5] = ev([(0, a1["g"]["Glasses"][5]), (0.3, -0.15), (0.36, 0.04, "out"), (0.5, 0.0)], t)
    g["Glasses"][1] = ev([(0, a1["g"]["Glasses"][1]), (0.3, 0.2), (0.36, 0.0, "back")], t)
    g["Brows"][5] = ev([(0, a1["g"]["Brows"][5]), (0.3, -0.06), (0.6, 0)], t)
    g["Moustache"][0] = ev([(0, a1["g"]["Moustache"][0]), (0.1, 0.0), (0.42, 0), (0.47, 0.16, "out"), (0.56, 0.0, "io")], t)
    g["LegL"][0] = ev([(0, a1["g"]["LegL"][0]), (0.1, 0.24), (0.45, 0.0)], t)
    g["LegR"][0] = ev([(0, a1["g"]["LegR"][0]), (0.1, -0.22), (0.45, 0.0)], t)
    g["LegL"][1] = ev([(0, a1["g"]["LegL"][1]), (0.45, 0.0)], t)
    g["LegR"][1] = ev([(0, a1["g"]["LegR"][1]), (0.45, 0.0)], t)
    r[2] = ev([(0, a1["root"][2]), (0.1, 0.2), (0.45, 0.0)], t)  # (the wider stance: hips up so the toe / heel stay out of the ground)
    r[1] = ev([(0, 0), (0.16, -0.25, "out"), (0.45, 0, "io")], t)  # (a half step back with the heave)
    p["fx"]["Swirl"] = ev([(0, a1["fx"]["Swirl"]), (0.4, 0, "out")], t)
    # a last harrumph: chest puff and settle
    squash(r, ev([(0, 1), (0.1, 0.95), (0.18, 1.06, "out"), (0.3, 0.99), (0.44, 1.0), (0.5, 1.03, "out"), (0.6, 1)], t))
    return p


CLIPS = {  # name -> (function, length s, loops)
    "windup": (clip_windup, WINDUP, False),
    "attack": (clip_attack, ATTACK, False),
    "recover": (clip_recover, RECOVER, False),
}


# the Papers group (drawn by the client: Bosses.client partnerPapers): spin rate and rise follow the Swirl channel
def papers_pose(spin, swirl, t):
    return (0.0, 0.0, spin, 0.0, 0.0, math.sin(t * 2) * 0.15 + 1.1 * swirl)


PAPER_SPIN = (0.9, 7.0)  # rad/s at Swirl 0 and 1
