# tools/blender/boss_clips/senior_partner_preview.py - The Senior Partner's preview scene for tools/blender/boss_anims.py:
# a Briefcase Bay lawn, three players (green = his target, walks out of the fan; orange dodges its Paper Storm disc;
# red stays and the bundle of case files lands on them), the floor warnings (the fan + the storm discs), the papers
# swirl, the bundles, the impact (dust, papers, ring), cameras, the baked timeline and the storyboard frames.
# ------------------------------------------------------------------ the lawn, the path, the players
block("Grass", (420, 420, 1), (96, 196, 40), loc=(0, 40, -0.5))
block("Path", (34, 420, 0.04), (255, 160, 24), loc=(0, 40, 0.0))
for i in range(-21, 22):  # white dashed edges
    for sx in (-1, 1):
        block("Dash", (1.2, 6, 0.06), (255, 255, 255), loc=(sx * 16.4, 40 + i * 10, 0.02))
for i in range(-10, 11):  # darker stud-scale bands so distances read
    block("GrassBand", (0.6, 420, 0.03), (86, 180, 34), loc=(i * 20 + (10 if i >= 0 else -10), 40, 0.01))

YAW_T = math.atan2(-6, 26)  # the server's Yaw: toward the target where it stood when the windup began
FWD = Vector((-math.sin(YAW_T), math.cos(YAW_T), 0))
P1, _ = avatar("Target", (98, 205, 48), 6, 26)  # his target (nearest): walks out of the fan in the windup
P2, _ = avatar("Crowd2", (255, 160, 24), -40, 50)  # sidesteps out of its storm disc
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), 30, 60)  # stays put: the bundle lands on them
STORM = [Vector((-40, 50, 0)), Vector((30, 60, 0))]  # disc centres = where they stood when the windup began
P1_TO = Vector((30, 6, 0))  # out of the fan (75 deg off his facing; the fan's half-angle is 55)
P2_SIDE = Vector((-1, -0.25, 0)).normalized()


# ------------------------------------------------------------------ floor warnings (as Bosses.client draws them)
def fan_mesh(name, r, half, segs=24):
    pts = [(0, 0, 0)] + [(-math.sin(-half + 2 * half * i / segs) * r, math.cos(-half + 2 * half * i / segs) * r, 0)
                         for i in range(segs + 1)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pts, [], [(0, i + 1, i) for i in range(1, segs + 1)][::-1])
    me.update()
    return me


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


HALF = math.radians(ANGLE / 2)
WARN_FAN = mesh_obj("WarnFan", fan_mesh("Fan", 1.0, HALF), COLOR, MAT_WARN, 0.6)
FAN_EDGE = [block("FanEdge", (1.5, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(24)]
WARN_DISCS = [mesh_obj("WarnDisc", disc_mesh("Disc%d" % i, 1.0), COLOR, MAT_WARN, 0.6) for i in range(len(STORM))]
DISC_EDGE = [[block("DiscEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(24)] for _ in STORM]
SHADOWS = [mesh_obj("BundleShadow", disc_mesh("Shadow%d" % i, 1.0), (30, 30, 40), MAT_FX, 0.0) for i in range(len(STORM))]

# ------------------------------------------------------------------ the Paper Storm bundles + the swirling papers
def bundle(name):
    e = empty(name)
    block("Folder", (4.2, 3.0, 1.3), (236, 206, 130), e)
    block("Pages", (3.8, 2.7, 1.5), (250, 250, 250), e, (0.1, 0.05, 0))
    block("String", (0.35, 3.1, 1.6), (200, 40, 44), e)
    block("String", (4.3, 0.35, 1.6), (200, 40, 44), e)
    e.scale = (0, 0, 0)
    return e


BUNDLES = [bundle("CaseFiles%d" % i) for i in range(len(STORM))]
SHEETS = []
for i in range(14):  # loose sheets whirling round him in the windup (Bosses.client: partnerSwirl)
    SHEETS.append(block("SwirlSheet", (2.2, 2.8, 0.1), (250, 250, 250) if i % 4 else (236, 206, 130), mat=MAT_FX))
RING = mesh_obj("ImpactRing", disc_mesh("Ring", 1.0, 40), COLOR, MAT_FX, 0.9)
GLEAM = block("Gleam", (1, 1, 1), (255, 236, 150), mat=MAT_FX, glow=1.0)

# ------------------------------------------------------------------ cameras
CAM_GAME = camera("Cam_Gameplay", (82, -22, 74), (-4, 32, 4), 26)  # a high player's-eye view: the fan + both discs
CAM_A = camera("Cam_Front", (62, 78, 30), (0, 2, 25), 28)  # front 3/4: glasses, stance, raise, swirl
CAM_B = camera("Cam_Side", (96, 26, 22), (0, 12, 22), 26)  # side: the sweep and the strike
CAM_C = camera("Cam_Recover", (-46, 58, 20), (2, 6, 18), 30)  # the other side: the yank and the tidy-up


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state, local t, position, yaw target)."""
    if T < T_WIND:
        return "walk", T, Vector((-19 + 19 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_ATTACK:
        return "windup", T - T_WIND, Vector((0, 0, 0)), YAW_T
    if T < T_RECOVER:
        return "attack", T - T_ATTACK, Vector((0, 0, 0)), YAW_T
    if T < T_WALK2:
        return "recover", T - T_RECOVER, Vector((0, 0, 0)), YAW_T
    return "walk", T - T_WALK2, Vector((-12 * (T - T_WALK2) / 0.6, 0, 0)), math.pi / 2


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


def world_of(local):  # boss space (model units, his facing) -> world, standing at the origin after the turn
    v = Vector(local) * SCALE
    c, s = math.cos(YAW_T), math.sin(YAW_T)
    return Vector((v.x * c - v.y * s, v.x * s + v.y * c, v.z))


CASE_BLOCKS = []
STRIKE_AT = Vector((0, 0, 0))
OPEN_AT = Vector((0, 0, 0))


def bake():
    global STRIKE_AT, OPEN_AT
    walk_amt, phase, prev_yaw, spin = 1.0, 0.0, -math.pi / 2, 0.0
    swirl_by_frame = {}
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        speed = 38.0 if state == "walk" else 0.0
        phase += (1 / FPS) * speed / (4 * SCALE) * math.pi
        walk_amt += ((1.0 if state == "walk" else 0.0) - walk_amt) * min(1.0, 6 / FPS)
        if state == "windup":
            yaw = turn_yaw(-math.pi / 2, YAW_T, tl)
        else:
            yaw = prev_yaw + ((yaw_t - prev_yaw + math.pi) % (2 * math.pi) - math.pi) * min(1.0, 6 / FPS)
        prev_yaw = yaw
        pose = pose_at(T, phase, walk_amt)
        if state == "windup":  # the head leads the turn (the client does the same: BossAnims Turn.Lead)
            pose["g"][LEAD[0]][2] += LEAD[1] * (YAW_T - yaw)
        swirl = pose["fx"]["Swirl"]
        swirl_by_frame[fr] = swirl
        spin += (PAPER_SPIN[0] + (PAPER_SPIN[1] - PAPER_SPIN[0]) * swirl) / FPS
        pose["g"]["Papers"] = list(papers_pose(spin, swirl, T))
        key_boss(fr, pos, yaw, pose)
    # where the case lands, and where the bundles leave it (measured on the baked boss)
    CASE_BLOCKS[:] = group_blocks("Case") + group_blocks("CaseLid")
    SC.frame_set(int(round((T_ATTACK + STRIKE) * FPS)))
    STRIKE_AT = lowest_point(CASE_BLOCKS).copy()
    SC.frame_set(int(round((T_WIND + STORM_OPEN) * FPS)))
    OPEN_AT = sum((o.matrix_world.translation for o in CASE_BLOCKS), Vector()) / len(CASE_BLOCKS)
    schedule_fx()
    key_world(swirl_by_frame)
    key_fx()


def schedule_fx():
    tw = T_WIND
    foot = world_of((0.85, -0.6, 0))  # the stomp: dust round his right foot
    for i in range(8):
        a = i / 8 * 2 * math.pi
        spawn("puff", tw + 0.42, 0.45, (foot.x + math.cos(a) * 2, foot.y + math.sin(a) * 2, 0.5),
              (math.cos(a) * 10, math.sin(a) * 10, rng.uniform(2, 5)), -10, rng.uniform(1.4, 2.0))
    for i in range(16):  # the lid bursts open: sheets spray out of the case and get caught in the swirl
        spawn("paper", tw + 0.78 + i * 0.01, 0.6, OPEN_AT + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0)),
              (rng.uniform(-14, 14), rng.uniform(-14, 14), rng.uniform(4, 14)), -12, rng.uniform(1.6, 2.2), (250, 250, 250), spin=rng.uniform(6, 12))
    ts = T_ATTACK + STRIKE  # IMPACT: a dust ring, chunks, a fan of paperwork thrown forward, flutter
    hit = Vector((STRIKE_AT.x, STRIKE_AT.y, 0.6))
    for i in range(18):
        a = i / 18 * 2 * math.pi
        spawn("puff", ts, 0.6, hit + Vector((math.cos(a) * 2.5, math.sin(a) * 2.5, 0)),
              (math.cos(a) * 22, math.sin(a) * 22, rng.uniform(3, 8)), -12, rng.uniform(2.2, 3.2))
    for i in range(10):
        spawn("chunk", ts, 0.55, hit + Vector((0, 0, 0.5)), (rng.uniform(-14, 14), rng.uniform(-14, 14), rng.uniform(16, 26)),
              -70, rng.uniform(0.9, 1.5), (150, 110, 70), spin=rng.uniform(8, 14))
    for i in range(26):
        d = FWD * rng.uniform(8, 26) + Vector((-FWD.y, FWD.x, 0)) * rng.uniform(-18, 18)
        spawn("paper", ts + rng.uniform(0, 0.04), rng.uniform(0.9, 1.3), hit + Vector((0, 0, 2)),
              (d.x, d.y, rng.uniform(14, 26)), -22, rng.uniform(1.6, 2.4), (250, 250, 250) if i % 3 else (236, 206, 130),
              spin=rng.uniform(5, 11))
    tr = T_RECOVER + 0.08  # the yank: a puff and a few clods where the case was
    for i in range(8):
        a = i / 8 * 2 * math.pi
        spawn("puff", tr, 0.45, hit + Vector((math.cos(a) * 1.5, math.sin(a) * 1.5, 0)),
              (math.cos(a) * 9, math.sin(a) * 9, rng.uniform(6, 10)), -14, rng.uniform(1.4, 2.0))
    for i in range(5):
        spawn("chunk", tr, 0.5, hit + Vector((0, 0, 0.5)), (rng.uniform(-6, 6), rng.uniform(-6, 6), rng.uniform(12, 18)),
              -70, rng.uniform(0.7, 1.1), (150, 110, 70), spin=rng.uniform(8, 14))
    for c in STORM:  # each bundle bursts where it lands
        for i in range(12):
            a = i / 12 * 2 * math.pi
            spawn("paper", T_ATTACK, rng.uniform(0.7, 1.0), c + Vector((0, 0, 1.5)),
                  (math.cos(a) * rng.uniform(8, 15), math.sin(a) * rng.uniform(8, 15), rng.uniform(10, 18)), -22,
                  rng.uniform(1.4, 2.0), (250, 250, 250) if i % 3 else (236, 206, 130), spin=rng.uniform(5, 11))
        for i in range(10):
            a = i / 10 * 2 * math.pi
            spawn("puff", T_ATTACK, 0.5, c + Vector((math.cos(a) * 2, math.sin(a) * 2, 0.5)),
                  (math.cos(a) * 14, math.sin(a) * 14, rng.uniform(2, 5)), -10, rng.uniform(1.5, 2.2))


P3_HIT = T_ATTACK


def player_pos(T):
    p1 = Vector((6, 26, 0)).lerp(P1_TO, ramp(T, T_WIND + 0.12, T_WIND + 1.08))
    p2 = STORM[0] + P2_SIDE * 14 * ramp(T, T_WIND + 0.35, T_WIND + 0.85)
    return p1, p2


def key_world(swirl_by_frame):
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        wind = state == "windup"
        grow = 0.45 + 0.55 * EASE["out"](min(1.0, tl / 0.4)) if wind else 1.0
        pulse = 0.5 + 0.5 * math.sin(T * 18)
        vis = 1.0 if wind else 0.0
        # the fan
        r = RADIUS * grow
        WARN_FAN.location, WARN_FAN.rotation_euler, WARN_FAN.scale = (0, 0, 0.06), (0, 0, YAW_T), (r, r, 1)
        WARN_FAN["alpha"] = (0.4 - 0.2 * pulse) * vis
        for o in (WARN_FAN,):
            o.keyframe_insert("scale", frame=fr)
            o.keyframe_insert('["alpha"]', frame=fr)
        for i, o in enumerate(FAN_EDGE):
            a = YAW_T - HALF + 2 * HALF * i / 23
            o.location = (-math.sin(a) * r, math.cos(a) * r, 0.08)
            o.rotation_euler = (0, 0, a)
            o.scale = (max(1.5, r * 2 * HALF / 23 * 1.05), 0.8, 0.16)
            o["alpha"] = (0.85 - 0.35 * pulse) * vis
            for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        # the storm discs (only while the windup lasts; the bundles land as the attack starts)
        for d, edges, c in zip(WARN_DISCS, DISC_EDGE, STORM):
            rr = STORM_R * grow
            d.location, d.scale = (c.x, c.y, 0.07), (rr, rr, 1)
            d["alpha"] = (0.4 - 0.2 * pulse) * vis
            d.keyframe_insert("location", frame=fr)
            d.keyframe_insert("scale", frame=fr)
            d.keyframe_insert('["alpha"]', frame=fr)
            for i, o in enumerate(edges):
                a = i / 24 * 2 * math.pi
                o.location = (c.x - math.sin(a) * rr, c.y + math.cos(a) * rr, 0.09)
                o.rotation_euler = (0, 0, a)
                o.scale = (max(1.4, rr * 2 * math.pi / 24 * 1.05), 0.8, 0.16)
                o["alpha"] = (0.85 - 0.35 * pulse) * vis
                for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                    o.keyframe_insert(k, frame=fr)
        # the bundles: out of the open case at STORM_OPEN, a high arc, spinning, down on the disc's centre as the
        # attack starts; a shadow grows under each as it comes
        t0, t1 = T_WIND + STORM_OPEN, T_ATTACK
        for bnd, sh, c in zip(BUNDLES, SHADOWS, STORM):
            k = (T - t0) / (t1 - t0)
            if 0 <= k <= 1:
                p = OPEN_AT.lerp(c + Vector((0, 0, 1.0)), k) + Vector((0, 0, 30 * math.sin(math.pi * k)))
                bnd.location = p
                bnd.rotation_euler = (k * 7, k * 3, k * 2)
                bnd.scale = (1, 1, 1)
            else:
                bnd.scale = (0, 0, 0)
            sh.location = (c.x, c.y, 0.11)
            ss = (1.5 + 3.5 * k) if 0 <= k <= 1 else 0.0
            sh.scale = (ss, ss, 1)
            sh["alpha"] = 0.45 * k if 0 <= k <= 1 else 0.0
            for o in (bnd,):
                for kk in ("location", "rotation_euler", "scale"):
                    o.keyframe_insert(kk, frame=fr)
            sh.keyframe_insert("location", frame=fr)
            sh.keyframe_insert("scale", frame=fr)
            sh.keyframe_insert('["alpha"]', frame=fr)
        # the swirl: loose sheets whirling round him, rising, while the Swirl channel is up; blown forward at the strike
        sw = swirl_by_frame.get(fr, 0.0)
        ts = T_ATTACK + STRIKE
        for i, o in enumerate(SHEETS):
            a = T * (4.2 + (i % 3) * 0.6) + i * 2 * math.pi / len(SHEETS)
            rad = (11 + (i % 4) * 2.2)
            h = 2 + (i * 7.3) % 26 * sw + 2.5 * math.sin(T * 5 + i)
            if T < ts:
                p = Vector((math.cos(a) * rad, math.sin(a) * rad, h))
                sc = 1.0 * min(1.0, sw * 1.5)
            else:  # thrown forward with the strike and gone
                k = T - ts
                p = Vector((math.cos(a) * rad, math.sin(a) * rad, h)) + FWD * 40 * k + Vector((0, 0, 10 * k - 18 * k * k))
                sc = max(0.0, 1 - k / 0.5)
            o.location = p
            o.rotation_euler = (T * 6 + i, T * 4 + i * 0.5, a + math.pi / 2)
            o.scale = (2.2 * sc, 2.8 * sc, 0.1)
            o["alpha"] = 0.95
            for k2 in ("location", "rotation_euler", "scale"):
                o.keyframe_insert(k2, frame=fr)
        # the impact ring (the shockwave at the strike) and the clasp's gleam at the top of the raise
        k = (T - ts) / 0.38
        RING.location = (STRIKE_AT.x, STRIKE_AT.y, 0.3 + 0.6 * max(0.0, k))
        rr = 1 + (RADIUS * 0.55 - 1) * EASE["out"](min(1.0, max(0.0, k)))
        RING.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
        RING["alpha"] = 0.75 * (1 - k) if 0 <= k <= 1 else 0.0
        for kk in ("location", "scale", '["alpha"]'):
            RING.keyframe_insert(kk, frame=fr)
        g = (T - (T_WIND + 0.88)) / 0.22
        clasp = [o for o in CASE_BLOCKS if o.name.startswith("CaseClasp")]
        if 0 <= g <= 1 and clasp:
            SC.frame_set(fr)
            GLEAM.location = clasp[0].matrix_world.translation + Vector((1.5, 0, 0))
            gs = 3.2 * math.sin(math.pi * g)
            GLEAM.scale = (gs, gs * 0.18, gs * 0.18)
            GLEAM.rotation_euler = (0, 0, 0.8 + g * 2)
        else:
            GLEAM.scale = (0, 0, 0)
        for kk in ("location", "scale", "rotation_euler"):
            GLEAM.keyframe_insert(kk, frame=fr)
        # players: green walks out of the fan, orange sidesteps its disc, red stays and is flung by the bundle
        p1, p2 = player_pos(T)
        P1.location, P2.location = p1, p2
        d1 = P1_TO - Vector((6, 26, 0))
        P1.rotation_euler = (0, 0, math.atan2(-d1.x, d1.y) if T_WIND + 0.1 < T < T_WIND + 1.1 else math.atan2(6, -26))
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND + 0.33 < T < T_WIND + 0.87 else math.atan2(-40, -50))
        if T > P3_HIT:
            k = min(1.0, (T - P3_HIT) / 0.7)
            fling = Vector((STORM[1].x, STORM[1].y, 0)).normalized()
            P3.location = STORM[1] + fling * 16 * EASE["out"](k) + Vector((0, 0, 7 * math.sin(math.pi * min(1, k * 1.2))))
            P3.rotation_euler = (0, -math.pi * 0.5 * EASE["out"](k), math.atan2(-fling.x, fling.y))
            for i, egg in enumerate(P3EGGS):
                a = i / 3 * 2 * math.pi + 0.4
                ke = min(1.0, (T - P3_HIT - i * 0.05) / 0.6) if T > P3_HIT + i * 0.05 else 0
                egg.location = Vector((math.cos(a) * 9 * ke, math.sin(a) * 9 * ke, 5.9 + i * 1.5 + 9 * math.sin(math.pi * ke) - (5.9 + i * 1.5 - 0.8) * ke))
                egg.keyframe_insert("location", frame=fr)
        else:
            P3.location = STORM[1]
            P3.rotation_euler = (0, 0, math.atan2(STORM[1].x, -STORM[1].y))
            for i, egg in enumerate(P3EGGS):
                egg.location = (0, 0.2, 5.9 + i * 1.5)
                egg.keyframe_insert("location", frame=fr)
        for o in (P1, P2, P3):
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int((T_WIND + 1.02) * FPS), CAM_B), (int((T_RECOVER + 0.02) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # (preview time, camera, file)
    (T_WIND + 0.07, CAM_A, "01_notice"), (T_WIND + 0.26, CAM_A, "02_glasses"), (T_WIND + 0.43, CAM_A, "03_stomp_stance"),
    (T_WIND + 0.58, CAM_A, "04_dip_back"), (T_WIND + 0.8, CAM_A, "05_lid_bursts_swirl"), (T_WIND + 0.97, CAM_A, "06_hold_objection"),
    (T_WIND + 1.12, CAM_B, "07_downswing"), (T_ATTACK + STRIKE, CAM_B, "08_strike"), (T_ATTACK + 0.12, CAM_B, "09_impact_papers"),
    (T_ATTACK + 0.36, CAM_B, "10_stuck_tug"), (T_RECOVER + 0.14, CAM_C, "11_yank"), (T_RECOVER + 0.33, CAM_C, "12_glasses_fix"),
    (T_RECOVER + 0.5, CAM_C, "13_harrumph"), (T_WIND + 0.9, CAM_GAME, "14_gameplay_warnings"),
    (T_ATTACK + 0.06, CAM_GAME, "15_gameplay_storm_lands"),
]
