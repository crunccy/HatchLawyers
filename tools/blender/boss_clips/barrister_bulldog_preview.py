# tools/blender/boss_clips/barrister_bulldog_preview.py - Barrister Bulldog's preview scene for tools/blender/boss_anims.py:
# a Pet Park lawn, three players (green = his target, walks out of the bark's disc; orange dodges its Echo Bark disc;
# red stays and the echo goes off round them), the floor warnings (the disc + the echo discs), the echo waves, the bark
# (shockwave, air ripples, dust, drool), the wig's powder, cameras, the baked timeline and the storyboard frames.
# ------------------------------------------------------------------ the lawn, the path, the players
block("Grass", (420, 420, 1), (96, 196, 40), loc=(0, 40, -0.5))
block("Path", (34, 420, 0.04), (255, 160, 24), loc=(0, 40, 0.0))
for i in range(-21, 22):  # white dashed edges
    for sx in (-1, 1):
        block("Dash", (1.2, 6, 0.06), (255, 255, 255), loc=(sx * 16.4, 40 + i * 10, 0.02))
for i in range(-10, 11):  # darker stud-scale bands so distances read
    block("GrassBand", (0.6, 420, 0.03), (86, 180, 34), loc=(i * 20 + (10 if i >= 0 else -10), 40, 0.01))

YAW_T = math.atan2(-8, 22)  # the server's Yaw: toward the target where it stood when the windup began
FWD = Vector((-math.sin(YAW_T), math.cos(YAW_T), 0))
P1, _ = avatar("Target", (98, 205, 48), 8, 22)  # his target (nearest): walks out of the bark's disc in the windup
P2, _ = avatar("Crowd2", (255, 160, 24), -46, 40)  # sidesteps out of its echo disc
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), 40, 56)  # stays put: the echo goes off round them
ECHO = [Vector((-46, 40, 0)), Vector((40, 56, 0))]  # disc centres = where they stood when the windup began
P1_TO = Vector((30, 34, 0))  # out of the disc (45 studs from him; the bark reaches 34)
P2_SIDE = Vector((-1, -0.3, 0)).normalized()


# ------------------------------------------------------------------ floor warnings (as Bosses.client draws them)
def disc_mesh(name, r, segs=32):
    pts = [(math.cos(i / segs * 2 * math.pi) * r, math.sin(i / segs * 2 * math.pi) * r, 0) for i in range(segs)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pts, [], [tuple(range(segs))])
    me.update()
    return me


def arc_mesh(name, r0, r1, half, segs=10):
    """A sound-wave arc: a ring sector standing up (in the x-z plane), facing +y."""
    pts = []
    for i in range(segs + 1):
        a = -half + 2 * half * i / segs
        pts += [(math.sin(a) * r0, 0, math.cos(a) * r0), (math.sin(a) * r1, 0, math.cos(a) * r1)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pts, [], [(2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2) for i in range(segs)])
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
ECHO_DISCS = [mesh_obj("EchoDisc", disc_mesh("Echo%d" % i, 1.0), COLOR, MAT_WARN, 0.6) for i in range(len(ECHO))]
ECHO_EDGE = [[block("EchoEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(24)] for _ in ECHO]
WAVES = [[mesh_obj("EchoWave", arc_mesh("Wave%d%d" % (i, k), 0.82, 1.0, math.radians(55)), COLOR, MAT_FX, 1.0)
          for k in range(3)] for i in range(len(ECHO))]
RINGS = [mesh_obj("BarkRing%d" % k, disc_mesh("BarkRingMesh%d" % k, 1.0, 48), c, MAT_FX, 0.9)
         for k, c in enumerate((COLOR, (255, 255, 255), COLOR))]
ECHO_RINGS = [mesh_obj("EchoRing", disc_mesh("EchoRingMesh%d" % i, 1.0, 32), COLOR, MAT_FX, 0.9) for i in range(len(ECHO))]
RIPPLES = [mesh_obj("Ripple%d" % k, arc_mesh("RippleMesh%d" % k, 0.9, 1.0, math.radians(70), 14), (255, 255, 255), MAT_FX, 0.8)
           for k in range(3)]

# ------------------------------------------------------------------ cameras
CAM_GAME = camera("Cam_Gameplay", (70, -74, 104), (-4, 28, 0), 24)  # a high player's-eye view: the disc + both echo discs
CAM_A = camera("Cam_Front", (44, 70, 22), (0, 4, 13), 30)  # front 3/4: notice, growl, the puff-up
CAM_B = camera("Cam_Bark", (34, 50, 9), (1, 7, 15), 30)  # low front 3/4: into the open mouth, the wig's flight
CAM_C = camera("Cam_Recover", (-40, 58, 18), (0, 6, 14), 30)  # the other side: the wig lands, the head shake


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state, local t, position, yaw target)."""
    if T < T_WIND:
        return "walk", T, Vector((-22 + 22 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_ATTACK:
        return "windup", T - T_WIND, Vector((0, 0, 0)), YAW_T
    if T < T_RECOVER:
        return "attack", T - T_ATTACK, Vector((0, 0, 0)), YAW_T
    if T < T_WALK2:
        return "recover", T - T_RECOVER, Vector((0, 0, 0)), YAW_T
    return "walk", T - T_WALK2, Vector((-14 * (T - T_WALK2) / 0.6, 0, 0)), math.pi / 2


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


MOUTH_AT = Vector((0, 0, 0))


def bake():
    global MOUTH_AT
    walk_amt, phase, prev_yaw = 1.0, 0.0, -math.pi / 2
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        speed = 44.0 if state == "walk" else 0.0
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
        key_boss(fr, pos, yaw, pose)
    # where his mouth is when the echo waves leave it (measured on the baked boss)
    SC.frame_set(int(round((T_WIND + ECHO_LEAVE) * FPS)))
    jaw = group_blocks("Jaw")
    MOUTH_AT = sum((o.matrix_world.translation for o in jaw), Vector()) / len(jaw)
    schedule_fx()
    key_world()
    key_fx()


def schedule_fx():
    tw, ta, tr = T_WIND, T_ATTACK, T_RECOVER
    for sx in (-1, 1):  # PLANT: the front paws splay and plant - a puff under each
        paw = world_of((sx * 1.65, 2.2, 0))
        for i in range(5):
            a = i / 5 * 2 * math.pi
            spawn("puff", tw + 0.3, 0.4, (paw.x + math.cos(a), paw.y + math.sin(a), 0.4),
                  (math.cos(a) * 7, math.sin(a) * 7, rng.uniform(2, 4)), -8, rng.uniform(1.0, 1.5))
    for i in range(14):  # the INHALE: air streaks sucked into his mouth
        a = rng.uniform(-1.2, 1.2)
        d = FWD * math.cos(a) + Vector((-FWD.y, FWD.x, 0)) * math.sin(a)
        start = world_of((0, 6.0, 3.6)) + d * rng.uniform(14, 22) + Vector((0, 0, rng.uniform(-3, 5)))
        end = world_of((0, 6.0, 3.6))
        t0 = tw + 0.45 + i * 0.03
        spawn("streak", t0, 0.3, start, (end - start) / 0.3, 0, rng.uniform(2.5, 4), (255, 255, 255), glow=0.6)
    hit = world_of((0, 6.4, 3.6))  # the BARK: drool flies out of the mouth, dust round his feet
    for i in range(16):
        d = FWD * rng.uniform(10, 24) + Vector((-FWD.y, FWD.x, 0)) * rng.uniform(-12, 12)
        spawn("drop", ta + rng.uniform(0, 0.05), rng.uniform(0.5, 0.75), hit, (d.x, d.y, rng.uniform(6, 16)), -60,
              rng.uniform(0.8, 1.3), (230, 240, 255), glow=0.3)
    for i in range(20):
        a = i / 20 * 2 * math.pi
        spawn("puff", ta, 0.6, (math.cos(a) * 6, math.sin(a) * 6, 0.6), (math.cos(a) * 28, math.sin(a) * 28, rng.uniform(2, 6)),
              -10, rng.uniform(2.2, 3.4))
    for c in ECHO:  # each echo goes off round its player: dust thrown out of the disc
        for i in range(12):
            a = i / 12 * 2 * math.pi
            spawn("puff", ta, 0.5, c + Vector((math.cos(a) * 2, math.sin(a) * 2, 0.5)),
                  (math.cos(a) * 16, math.sin(a) * 16, rng.uniform(2, 5)), -10, rng.uniform(1.6, 2.4))
    wig_top = world_of((0, 3.5, 7.0))  # the wig lands: a puff of wig powder
    for i in range(10):
        a = i / 10 * 2 * math.pi
        spawn("puff", tr + 0.12, 0.45, wig_top + Vector((math.cos(a) * 6, math.sin(a) * 6, 1)),
              (math.cos(a) * 10, math.sin(a) * 10, rng.uniform(3, 6)), -6, rng.uniform(0.7, 1.1), (250, 250, 250))
    for i in range(12):  # the head shake flings drool off the jowls
        side = Vector((-FWD.y, FWD.x, 0)) * (1 if i % 2 else -1)
        spawn("drop", tr + 0.18 + i * 0.018, 0.5, world_of((0, 5.6, 3.4)),
              side * rng.uniform(12, 20) + FWD * rng.uniform(-3, 5) + Vector((0, 0, rng.uniform(5, 10))), -60,
              rng.uniform(0.7, 1.1), (230, 240, 255), glow=0.3)


P3_HIT = T_ATTACK


def player_pos(T):
    p1 = Vector((8, 22, 0)).lerp(P1_TO, ramp(T, T_WIND + 0.15, T_WIND + 1.2))
    p2 = ECHO[0] + P2_SIDE * 15 * ramp(T, T_WIND + 0.4, T_WIND + 0.95)
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
        # the bark's disc
        r = RING_R * grow
        WARN_DISC.location, WARN_DISC.scale = (0, 0, 0.06), (r, r, 1)
        WARN_DISC["alpha"] = (0.4 - 0.2 * pulse) * vis
        WARN_DISC.keyframe_insert("scale", frame=fr)
        WARN_DISC.keyframe_insert('["alpha"]', frame=fr)
        for i, o in enumerate(DISC_EDGE):
            a = i / 36 * 2 * math.pi
            o.location = (-math.sin(a) * r, math.cos(a) * r, 0.08)
            o.rotation_euler = (0, 0, a)
            o.scale = (max(1.5, r * 2 * math.pi / 36 * 1.05), 0.8, 0.16)
            o["alpha"] = (0.85 - 0.35 * pulse) * vis
            for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        # the echo discs (the windup only; the echo goes off as the attack starts)
        for d, edges, c in zip(ECHO_DISCS, ECHO_EDGE, ECHO):
            rr = ECHO_R * grow
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
        # the echo waves: three arcs leave his mouth at ECHO_LEAVE, race low over the ground to each disc and arrive as
        # the bark goes off (the attack's first frame), growing as they go
        t0, t1 = T_WIND + ECHO_LEAVE, ta
        for arcs, c in zip(WAVES, ECHO):
            k = (T - t0) / (t1 - t0)
            d = Vector((c.x - MOUTH_AT.x, c.y - MOUTH_AT.y, 0))
            yaw = math.atan2(-d.x, d.y)
            for j, o in enumerate(arcs):
                kj = k - j * 0.08
                if 0 <= kj <= 1:
                    p = MOUTH_AT.lerp(c + Vector((0, 0, 2.5)), EASE["in"](kj) * 0.6 + kj * 0.4)
                    p.z += 4 * math.sin(math.pi * kj)
                    s = 2.5 + 6.5 * kj
                    o.location, o.rotation_euler, o.scale = p, (0, 0, yaw), (s, s, s)
                    o["alpha"] = 0.85
                else:
                    o.scale = (0, 0, 0)
                    o["alpha"] = 0.0
                for kk in ("location", "rotation_euler", "scale", '["alpha"]'):
                    o.keyframe_insert(kk, frame=fr)
        # the bark: its shockwave (+ a white one) to the disc's edge, air ripples (arcs) thrown forward
        for kidx, (o, delay, rmax, alpha) in enumerate(zip(RINGS, (0.0, 0.07, 0.14), (RING_R, RING_R * 0.75, RING_R * 0.5), (0.8, 0.7, 0.5))):
            k = (T - ta - delay) / 0.38
            o.location = (0, 0, 0.4 + 0.8 * max(0.0, k) + kidx * 0.05)
            rr = 1 + (rmax - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = alpha * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        for j, o in enumerate(RIPPLES):
            k = (T - ta - j * 0.05) / 0.32
            if 0 <= k <= 1:
                o.location = world_of((0, 6.5, 3.6)) + FWD * 30 * EASE["out"](k)
                s = 3 + 9 * k
                o.rotation_euler, o.scale = (0, 0, YAW_T), (s, s, s)
                o["alpha"] = 0.8 * (1 - k)
            else:
                o.scale, o["alpha"] = (0, 0, 0), 0.0
            for kk in ("location", "rotation_euler", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        for o, c in zip(ECHO_RINGS, ECHO):  # each echo goes off round its player
            k = (T - ta) / 0.32
            o.location = (c.x, c.y, 0.5 + 0.6 * max(0.0, k))
            rr = 1 + (ECHO_R - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = 0.8 * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        # players: green walks out of the disc, orange sidesteps its echo disc, red stays and is flung by the echo
        p1, p2 = player_pos(T)
        P1.location, P2.location = p1, p2
        d1 = P1_TO - Vector((8, 22, 0))
        P1.rotation_euler = (0, 0, math.atan2(-d1.x, d1.y) if T_WIND + 0.13 < T < T_WIND + 1.22 else math.atan2(8, -22))
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND + 0.38 < T < T_WIND + 0.97 else math.atan2(46, -40))
        if T > P3_HIT:
            k = min(1.0, (T - P3_HIT) / 0.7)
            fling = Vector((ECHO[1].x, ECHO[1].y, 0)).normalized()
            P3.location = ECHO[1] + fling * 16 * EASE["out"](k) + Vector((0, 0, 7 * math.sin(math.pi * min(1, k * 1.2))))
            P3.rotation_euler = (0, -math.pi * 0.5 * EASE["out"](k), math.atan2(-fling.x, fling.y))
            for i, egg in enumerate(P3EGGS):
                a = i / 3 * 2 * math.pi + 0.4
                ke = min(1.0, (T - P3_HIT - i * 0.05) / 0.6) if T > P3_HIT + i * 0.05 else 0
                egg.location = Vector((math.cos(a) * 9 * ke, math.sin(a) * 9 * ke, 5.9 + i * 1.5 + 9 * math.sin(math.pi * ke) - (5.9 + i * 1.5 - 0.8) * ke))
                egg.keyframe_insert("location", frame=fr)
        else:
            P3.location = ECHO[1]
            P3.rotation_euler = (0, 0, math.atan2(ECHO[1].x, -ECHO[1].y))
            for i, egg in enumerate(P3EGGS):
                egg.location = (0, 0.2, 5.9 + i * 1.5)
                egg.keyframe_insert("location", frame=fr)
        for o in (P1, P2, P3):
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int((T_WIND + 1.28) * FPS), CAM_B), (int((T_RECOVER + 0.04) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # (preview time, camera, file)
    (T_WIND + 0.07, CAM_A, "01_notice_ears_perk"), (T_WIND + 0.4, CAM_A, "02_plant_growl"), (T_WIND + 0.7, CAM_A, "03_inhale"),
    (T_WIND + 1.15, CAM_A, "04_puffed_hold"), (T_WIND + 1.37, CAM_B, "05_lunge"), (T_ATTACK + 0.02, CAM_B, "06_BARK"),
    (T_ATTACK + 0.12, CAM_B, "07_wig_blown_off"), (T_ATTACK + 0.3, CAM_B, "08_jaw_hold"),
    (T_RECOVER + 0.13, CAM_C, "09_wig_lands_askew"), (T_RECOVER + 0.27, CAM_C, "10_head_shake"),
    (T_RECOVER + 0.52, CAM_C, "11_smug"), (T_WIND + 1.15, CAM_GAME, "12_gameplay_warnings_echo_waves"),
    (T_ATTACK + 0.05, CAM_GAME, "13_gameplay_bark_and_echoes"),
]
