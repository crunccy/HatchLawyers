# tools/blender/boss_clips/megalodon_preview.py - the Megalodon's preview scene for tools/blender/boss_anims.py: the
# beach, three players (the target dodges the charge, orange dodges its frenzy lane, red stays and is caught), the
# floor warnings, sand sharks, effects, dizzy stars, cameras, the baked timeline and the storyboard frames.
# ------------------------------------------------------------------ the beach, the players, the warnings
ground = block("Sand", (420, 420, 1), (222, 196, 146), loc=(0, 70, -0.5))
for i in range(-10, 11):  # a few darker stud-scale sand bands so speed reads
    block("SandBand", (420, 0.6, 0.02), (204, 178, 128), loc=(0, 70 + i * 20, 0.01))
    block("SandBand", (0.6, 420, 0.02), (204, 178, 128), loc=(i * 20, 70, 0.01))


P1, _ = avatar("Target", (98, 205, 48), 0, 60)  # the boss's target (nearest), dodges sideways
P2, _ = avatar("Crowd2", (255, 160, 24), 45, 85)  # dodges its frenzy lane
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), -30, 40)  # stays put: the sand shark gets them
CROWD = [Vector((45, 85, 0)), Vector((-30, 40, 0))]
P2_SIDE = Vector((-CROWD[0].y, CROWD[0].x, 0)).normalized()  # Crowd2 steps out of its lane this way


def lane_end(target):
    d = Vector((target.x, target.y, 0))
    return d.normalized() * min(CREW_MAX, d.length + 20)


WARN_MAIN = warn_set("WarnMain", LENGTH, 20)
WARN_CROWD = [warn_set("WarnCrowd%d" % i, lane_end(c).length, CREW_W) for i, c in enumerate(CROWD)]

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

# ------------------------------------------------------------------ cameras
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
        for o in GLOW_PARTS:
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
    key_fx()


# camera cuts for the cinematic cut
def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int(T_CHARGE * FPS), CAM_B), (int((T_DIZZY - 0.1) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # storyboard: (preview time, camera, file)
    (T_WIND + 0.02, CAM_A, "01_detect"), (T_WIND + 0.12, CAM_A, "02_turn_hop"), (T_WIND + 0.4, CAM_A, "03_coil_scrape"),
    (T_WIND + 0.7, CAM_A, "04_fin_glow_grin"), (T_WIND + 0.97, CAM_A, "05_final_sink"),
    (T_CHARGE + 0.05, CAM_B, "06_launch"), (T_CHARGE + 0.4, CAM_B, "07_run"), (T_DIZZY - 0.08, CAM_C, "08_brake"),
    (T_DIZZY + 0.1, CAM_C, "09_skid_settle"), (T_DIZZY + 0.25, CAM_C, "10_glasses"), (T_DIZZY + 1.0, CAM_C, "11_dizzy"),
    (T_RECOVER + 0.12, CAM_C, "12_shake_off"), (T_RECOVER + 0.4, CAM_C, "13_glasses_fix"),
    (T_RECOVER + 0.5, CAM_C, "14_gavel_tap"), (T_WIND + 0.7, CAM_GAME, "15_gameplay_warnings"),
    (T_CHARGE + 0.4, CAM_GAME, "16_gameplay_frenzy"),
]
