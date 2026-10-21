# tools/blender/boss_clips/judge_martello_preview.py - Judge Martello's preview scene for tools/blender/boss_anims.py: a
# Brainrot Boulevard lawn, three players (green = his target: he jumps at where they stood, they walk out of the slam's
# disc; orange dodges its Gavel Rain disc; red stays and a mini gavel bonks them), the floor warnings (the slam disc at
# the landing spot + the rain discs), the mini gavels and their shadows, the strike (shockwave, dust, wood chips), the
# hop back up, cameras, the baked timeline and the storyboard frames.
# ------------------------------------------------------------------ the lawn, the path, the players
block("Grass", (420, 420, 1), (96, 196, 40), loc=(0, 40, -0.5))
block("Path", (34, 420, 0.04), (255, 160, 24), loc=(0, 40, 0.0))
for i in range(-21, 22):  # white dashed edges
    for sx in (-1, 1):
        block("Dash", (1.2, 6, 0.06), (255, 255, 255), loc=(sx * 16.4, 40 + i * 10, 0.02))
for i in range(-10, 11):  # darker stud-scale bands so distances read
    block("GrassBand", (0.6, 420, 0.03), (86, 180, 34), loc=(i * 20 + (10 if i >= 0 else -10), 40, 0.01))

SPOT = Vector((8, 30, 0))  # where the target stood as the windup began: he lands there (the server's Target)
YAW_T = math.atan2(-SPOT.x, SPOT.y)
FWD = Vector((-math.sin(YAW_T), math.cos(YAW_T), 0))
RIGHT = Vector((FWD.y, -FWD.x, 0))
P1, _ = avatar("Target", (98, 205, 48), SPOT.x, SPOT.y)  # his target: walks out of the slam's disc in the windup
P2, _ = avatar("Crowd2", (255, 160, 24), -44, 48)  # sidesteps out of its rain disc
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), 46, 62)  # stays put: a mini gavel bonks them
RAIN = [Vector((-44, 48, 0)), Vector((46, 62, 0))]  # disc centres = where they stood when the windup began
P1_TO = Vector((36, 44, 0))  # out of the slam's disc (31 studs from the spot; the slam reaches 26)
P2_SIDE = Vector((-1, -0.2, 0)).normalized()


# ------------------------------------------------------------------ floor warnings (as Bosses.client draws them)
def disc_mesh(name, r, segs=32):
    pts = [(math.cos(i / segs * 2 * math.pi) * r, math.sin(i / segs * 2 * math.pi) * r, 0) for i in range(segs)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pts, [], [tuple(range(segs))])
    me.update()
    return me


def mesh_obj(name, me, col, mat, glow):
    o = bpy.data.objects.new(name, me)
    o.color = lin(col)
    o["glow"], o["alpha"] = glow, 1.0
    o.data.materials.append(mat)
    SC.collection.objects.link(o)
    return o


WARN_DISC = mesh_obj("WarnDisc", disc_mesh("Disc", 1.0, 48), COLOR, MAT_WARN, 0.6)
DISC_EDGE = [block("DiscEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(36)]
RAIN_DISCS = [mesh_obj("RainDisc", disc_mesh("Rain%d" % i, 1.0), COLOR, MAT_WARN, 0.6) for i in range(len(RAIN))]
RAIN_EDGE = [[block("RainEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(24)] for _ in RAIN]
SHADOWS = [mesh_obj("GavelShadow", disc_mesh("Shadow%d" % i, 1.0), (30, 30, 40), MAT_FX, 0.0) for i in range(len(RAIN) + 1)]
RINGS = [mesh_obj("SlamRing%d" % k, disc_mesh("SlamRingMesh%d" % k, 1.0, 48), c, MAT_FX, 0.9)
         for k, c in enumerate((COLOR, (255, 255, 255)))]
RAIN_RINGS = [mesh_obj("RainRing", disc_mesh("RainRingMesh%d" % i, 1.0, 32), COLOR, MAT_FX, 0.9) for i in range(len(RAIN))]


# ------------------------------------------------------------------ the Gavel Rain's mini gavels (Bosses.client: makeMiniGavel)
def mini_gavel(name):
    e = empty(name)
    block("Handle", (0.9, 0.9, 5.0), (122, 70, 34), e, (0, 0, -2.6))
    block("Head", (6.0, 2.6, 2.6), (196, 126, 62), e)
    for sx in (-1, 1):
        block("Band", (0.9, 2.7, 2.7), (232, 190, 60), e, (sx * 2.0, 0, 0))
    e.scale = (0, 0, 0)
    return e


GAVELS = [mini_gavel("MiniGavel%d" % i) for i in range(len(RAIN))]

# ------------------------------------------------------------------ cameras
CAM_GAME = camera("Cam_Gameplay", (74, -60, 104), (0, 36, 0), 24)  # a high player's-eye view: the slam disc + both rain discs
CAM_A = camera("Cam_Front", (52, 46, 16), (2, 8, 13), 30)  # front 3/4 at the start: the scowl, crouch, launch
CAM_B = camera("Cam_Strike", tuple(SPOT + FWD * 58 + Vector((0, 0, 14))), tuple(SPOT + Vector((0, 0, 14))), 30)  # ahead of him: the cartwheel strike
CAM_C = camera("Cam_Recover", tuple(SPOT + FWD * 58 - RIGHT * 36 + Vector((0, 0, 15))), tuple(SPOT + Vector((0, 0, 13))), 30)


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state, local t, position, yaw target). The windup draws him along From -> To by
    the clip's Travel channel (as Bosses.client does)."""
    if T < T_WIND:
        return "walk", T, Vector((-20 + 20 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_ATTACK:
        tl = T - T_WIND
        return "windup", tl, Vector((0, 0, 0)).lerp(SPOT, clip_windup(tl)["fx"]["Travel"]), YAW_T
    if T < T_RECOVER:
        return "attack", T - T_ATTACK, SPOT.copy(), YAW_T
    if T < T_WALK2:
        return "recover", T - T_RECOVER, SPOT.copy(), YAW_T
    return "walk", T - T_WALK2, SPOT + Vector((-12 * (T - T_WALK2) / 0.6, 0, 0)), math.pi / 2


def pose_at(T, phase, walk_amt):
    state, tl, pos, yaw_t = boss_state(T)
    if state == "walk":
        pose = walk_pose(phase, walk_amt, T)
        if T >= T_WALK2:
            pose = lerp_pose(clip_recover(RECOVER), pose, ramp(tl, 0, 0.1))
    else:
        pose = {"windup": clip_windup, "attack": clip_attack, "recover": clip_recover}[state](tl)
        if state == "windup" and tl < 0.1:
            pose = lerp_pose(walk_pose(phase, walk_amt, T), pose, ramp(tl, 0, 0.1))
    return post(pose)


GLOVES = []  # where the mini gavels leave his gloves (measured on the baked boss)
CAP_AT = Vector((0, 0, 0))  # where the end cap strikes


def bake():
    global CAP_AT
    walk_amt, phase, prev_yaw = 1.0, 0.0, -math.pi / 2
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        speed = 40.0 if state == "walk" else 0.0
        phase += (1 / FPS) * speed / (4 * SCALE) * math.pi
        walk_amt += ((1.0 if state == "walk" else 0.0) - walk_amt) * min(1.0, 6 / FPS)
        if state == "windup":
            yaw = turn_yaw(-math.pi / 2, YAW_T, tl)
        else:
            yaw = prev_yaw + ((yaw_t - prev_yaw + math.pi) % (2 * math.pi) - math.pi) * min(1.0, 6 / FPS)
        prev_yaw = yaw
        pose = pose_at(T, phase, walk_amt)
        if state == "windup":  # the hammer head leads the turn (the client does the same: BossAnims Turn.Lead)
            pose["g"][LEAD[0]][2] += LEAD[1] * (YAW_T - yaw)
        key_boss(fr, pos, yaw, pose)
    SC.frame_set(int(round((T_WIND + RAIN_THROW + 0.03) * FPS)))
    GLOVES[:] = [o.matrix_world.translation.copy() for g in ("ArmL", "ArmR") for o in group_blocks(g) if o.name.startswith("Glove")]
    SC.frame_set(int(round(T_ATTACK * FPS)))
    CAP_AT = lowest_point(group_blocks("Torso")).copy()
    schedule_fx()
    key_world()
    key_fx()


def schedule_fx():
    tw, ta, tr = T_WIND, T_ATTACK, T_RECOVER
    for i in range(10):  # the LAUNCH: a dust ring where he pushed off
        a = i / 10 * 2 * math.pi
        spawn("puff", tw + LAUNCH, 0.45, (math.cos(a) * 3, math.sin(a) * 3, 0.5), (math.cos(a) * 14, math.sin(a) * 14, rng.uniform(2, 5)),
              -10, rng.uniform(1.6, 2.4))
    hit = Vector((CAP_AT.x, CAP_AT.y, 0.6))  # THE STRIKE: a dust ring, wood chips, sparks of gold
    for i in range(20):
        a = i / 20 * 2 * math.pi
        spawn("puff", ta, 0.6, hit + Vector((math.cos(a) * 3, math.sin(a) * 3, 0)), (math.cos(a) * 30, math.sin(a) * 30, rng.uniform(3, 7)),
              -10, rng.uniform(2.4, 3.6))
    for i in range(14):
        spawn("chunk", ta, 0.6, hit + Vector((0, 0, 1)), (rng.uniform(-18, 18), rng.uniform(-18, 18), rng.uniform(18, 30)), -80,
              rng.uniform(0.8, 1.4), (150, 92, 46) if i % 2 else (196, 126, 62), spin=rng.uniform(8, 16))
    for i in range(10):
        spawn("spark", ta, 0.35, hit + Vector((0, 0, 2)), (rng.uniform(-24, 24), rng.uniform(-24, 24), rng.uniform(10, 24)), -30,
              rng.uniform(1.2, 1.8), (255, 220, 90), glow=1.0)
    for c in RAIN:  # each mini gavel bonks its disc
        for i in range(10):
            a = i / 10 * 2 * math.pi
            spawn("puff", ta, 0.5, c + Vector((math.cos(a) * 2, math.sin(a) * 2, 0.5)), (math.cos(a) * 15, math.sin(a) * 15, rng.uniform(2, 5)),
                  -10, rng.uniform(1.5, 2.2))
        for i in range(6):
            spawn("chunk", ta, 0.5, c + Vector((0, 0, 1)), (rng.uniform(-10, 10), rng.uniform(-10, 10), rng.uniform(12, 20)), -80,
                  rng.uniform(0.6, 1.0), (196, 126, 62), spin=rng.uniform(8, 16))
    land = SPOT + Vector((0, 0, 0.5))  # the hop back onto his feet
    for i in range(10):
        a = i / 10 * 2 * math.pi
        spawn("puff", tr + 0.38, 0.45, land + Vector((math.cos(a) * 3, math.sin(a) * 3, 0)), (math.cos(a) * 12, math.sin(a) * 12, rng.uniform(2, 4)),
              -10, rng.uniform(1.4, 2.0))


P3_HIT = T_ATTACK


def gavel_at(i, T):
    """A mini gavel (a = 0 leaves his glove at the launch .. 1 lands on the disc's centre as he lands): a high arc,
    tumbling, swinging into a strike (head end down) for its last stretch. Returns (location, rotation) or None."""
    t0, t1 = T_WIND + RAIN_THROW, T_ATTACK
    a = (T - t0) / (t1 - t0)
    if a < 0 or a > 1:
        return None
    c = RAIN[i]
    start = GLOVES[i] if i < len(GLOVES) else Vector((0, 0, 20))
    p = start.lerp(c + Vector((0, 0, 4.0)), a) + Vector((0, 0, 46 * math.sin(math.pi * a)))
    d = c - start
    yaw = math.atan2(-d.x, d.y)
    swing = ev([(0.8, 0), (1.0, math.pi / 2, "in")], a)  # (end over end, then the strike)
    return p, (4 * math.pi * a / 0.8 if a < 0.8 else 0.0, swing, yaw)  # (two whole turns, then the strike)


def player_pos(T):
    p1 = SPOT.lerp(P1_TO, ramp(T, T_WIND + 0.12, T_WIND + 1.05))
    p2 = RAIN[0] + P2_SIDE * 15 * ramp(T, T_WIND + 0.3, T_WIND + 0.85)
    return p1, p2


def key_world():
    ta = T_ATTACK
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        wind = state == "windup"
        grow = 0.45 + 0.55 * EASE["out"](min(1.0, tl / 0.4)) if wind else 1.0
        pulse = 0.5 + 0.5 * math.sin(T * 18)
        vis = 1.0 if wind else 0.0
        # the slam's disc at the landing spot
        r = RADIUS * grow
        WARN_DISC.location, WARN_DISC.scale = (SPOT.x, SPOT.y, 0.06), (r, r, 1)
        WARN_DISC["alpha"] = (0.4 - 0.2 * pulse) * vis
        for k in ("location", "scale", '["alpha"]'):
            WARN_DISC.keyframe_insert(k, frame=fr)
        for i, o in enumerate(DISC_EDGE):
            a = i / 36 * 2 * math.pi
            o.location = (SPOT.x - math.sin(a) * r, SPOT.y + math.cos(a) * r, 0.08)
            o.rotation_euler = (0, 0, a)
            o.scale = (max(1.5, r * 2 * math.pi / 36 * 1.05), 0.8, 0.16)
            o["alpha"] = (0.85 - 0.35 * pulse) * vis
            for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        # the rain discs
        for d, edges, c in zip(RAIN_DISCS, RAIN_EDGE, RAIN):
            rr = RAIN_R * grow
            d.location, d.scale = (c.x, c.y, 0.07), (rr, rr, 1)
            d["alpha"] = (0.4 - 0.2 * pulse) * vis
            for k in ("location", "scale", '["alpha"]'):
                d.keyframe_insert(k, frame=fr)
            for i, o in enumerate(edges):
                a = i / 24 * 2 * math.pi
                o.location = (c.x - math.sin(a) * rr, c.y + math.cos(a) * rr, 0.09)
                o.rotation_euler = (0, 0, a)
                o.scale = (max(1.4, rr * 2 * math.pi / 24 * 1.05), 0.8, 0.16)
                o["alpha"] = (0.85 - 0.35 * pulse) * vis
                for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                    o.keyframe_insert(k, frame=fr)
        # the mini gavels + their shadows; the last shadow is his own, growing on the spot as he comes down
        for i, (gv, sh) in enumerate(zip(GAVELS, SHADOWS)):
            g = gavel_at(i, T)
            if g:
                gv.location, gv.rotation_euler, gv.scale = g[0], g[1], (1, 1, 1)
                a = (T - T_WIND - RAIN_THROW) / (WINDUP - RAIN_THROW)
                ss = 1.5 + 4 * a
                sh.location, sh.scale, sh["alpha"] = (RAIN[i].x, RAIN[i].y, 0.11), (ss, ss, 1), 0.45 * a
            else:
                gv.scale = (0, 0, 0)
                sh.scale, sh["alpha"] = (0, 0, 0), 0.0
            for kk in ("location", "rotation_euler", "scale"):
                gv.keyframe_insert(kk, frame=fr)
            for kk in ("location", "scale", '["alpha"]'):
                sh.keyframe_insert(kk, frame=fr)
        own = SHADOWS[-1]
        if wind and tl > LAUNCH:
            a = (tl - LAUNCH) / (WINDUP - LAUNCH)
            ss = 4 + 8 * a
            own.location, own.scale, own["alpha"] = (SPOT.x, SPOT.y, 0.12), (ss, ss, 1), 0.4 * a
        else:
            own.scale, own["alpha"] = (0, 0, 0), 0.0
        for kk in ("location", "scale", '["alpha"]'):
            own.keyframe_insert(kk, frame=fr)
        # the strike's shockwave (+ a white one), and each mini gavel's ring
        for kidx, (o, delay, rmax, alpha) in enumerate(zip(RINGS, (0.0, 0.08), (RADIUS, RADIUS * 0.7), (0.8, 0.7))):
            k = (T - ta - delay) / 0.38
            o.location = (SPOT.x, SPOT.y, 0.4 + 0.8 * max(0.0, k) + kidx * 0.05)
            rr = 1 + (rmax - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = alpha * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        for o, c in zip(RAIN_RINGS, RAIN):
            k = (T - ta) / 0.32
            o.location = (c.x, c.y, 0.5 + 0.6 * max(0.0, k))
            rr = 1 + (RAIN_R - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = 0.8 * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        # players: green walks out of the slam's disc, orange sidesteps its rain disc, red stays and is bonked
        p1, p2 = player_pos(T)
        P1.location, P2.location = p1, p2
        d1 = P1_TO - SPOT
        P1.rotation_euler = (0, 0, math.atan2(-d1.x, d1.y) if T_WIND + 0.1 < T < T_WIND + 1.07 else math.atan2(SPOT.x, -SPOT.y))
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND + 0.28 < T < T_WIND + 0.87 else math.atan2(44, -48))
        if T > P3_HIT:
            k = min(1.0, (T - P3_HIT) / 0.7)
            fling = Vector((RAIN[1].x, RAIN[1].y, 0)).normalized()
            P3.location = RAIN[1] + fling * 16 * EASE["out"](k) + Vector((0, 0, 7 * math.sin(math.pi * min(1, k * 1.2))))
            P3.rotation_euler = (0, -math.pi * 0.5 * EASE["out"](k), math.atan2(-fling.x, fling.y))
            for i, egg in enumerate(P3EGGS):
                a = i / 3 * 2 * math.pi + 0.4
                ke = min(1.0, (T - P3_HIT - i * 0.05) / 0.6) if T > P3_HIT + i * 0.05 else 0
                egg.location = Vector((math.cos(a) * 9 * ke, math.sin(a) * 9 * ke, 5.9 + i * 1.5 + 9 * math.sin(math.pi * ke) - (5.9 + i * 1.5 - 0.8) * ke))
                egg.keyframe_insert("location", frame=fr)
        else:
            P3.location = RAIN[1]
            P3.rotation_euler = (0, 0, math.atan2(RAIN[1].x, -RAIN[1].y))
            for i, egg in enumerate(P3EGGS):
                egg.location = (0, 0.2, 5.9 + i * 1.5)
                egg.keyframe_insert("location", frame=fr)
        for o in (P1, P2, P3):
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int((T_WIND + 0.5) * FPS), CAM_B), (int((T_RECOVER + 0.08) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # (preview time, camera, file)
    (T_WIND + 0.05, CAM_A, "01_scowl"), (T_WIND + 0.24, CAM_A, "02_crouch"), (T_WIND + 0.36, CAM_A, "03_launch_gavels_flung"),
    (T_WIND + 0.6, CAM_B, "04_apex_tuck_cock_back"), (T_WIND + 0.92, CAM_B, "05_the_swing"),
    (T_ATTACK + 0.02, CAM_B, "06_BONK_end_cap"), (T_ATTACK + 0.16, CAM_B, "07_ringing_kicking"),
    (T_RECOVER + 0.08, CAM_C, "08_arms_pop_out"), (T_RECOVER + 0.24, CAM_C, "09_hop_upright"),
    (T_RECOVER + 0.4, CAM_C, "10_landing_squash"), (T_RECOVER + 0.55, CAM_C, "11_smug"),
    (T_WIND + 0.75, CAM_GAME, "12_gameplay_warnings_rain"), (T_ATTACK + 0.04, CAM_GAME, "13_gameplay_strike_and_rain"),
]
