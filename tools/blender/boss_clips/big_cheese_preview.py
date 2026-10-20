# tools/blender/boss_clips/big_cheese_preview.py - Prosecutor Big Cheese's preview scene for tools/blender/boss_anims.py:
# a Food Court floor, three players (green = his target, steps out of the roll lane; orange steps out of its wedge
# lane; red stays and a tumbling cheese wedge gets them), the floor warnings, the wedges, crumbs + dust, cameras, the
# baked timeline (with the code roll and its bump, as Bosses.client does it) and the storyboard frames.
# ------------------------------------------------------------------ the roll's bump (exported as RollLift)
def roll_lift_table(n=72):
    """How far the block wheel's lowest corner reaches below its round radius, per roll angle (minus the upright one),
    so the client lifts it and the corners never sink into the floor: a blocky wheel bumps as it rolls."""
    pts = []
    for o in GE["Torso"].children:
        if o.type != "MESH":
            continue
        for c in ((x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)):
            w = o.matrix_basis @ Vector(c)  # (the Torso empty sits at the wheel's middle: model units)
            pts.append((w.x, w.z))
    def low(th):
        return max(x * math.sin(th) - z * math.cos(th) for x, z in pts) - WHEEL_R
    base = low(0.0)
    return [low(2 * math.pi * i / n) - base for i in range(n)]


ROLL_LIFT = roll_lift_table()


def lift_at(roll):
    n = len(ROLL_LIFT)
    f = (roll % (2 * math.pi)) / (2 * math.pi) * n
    i = int(f) % n
    return ROLL_LIFT[i] + (ROLL_LIFT[(i + 1) % n] - ROLL_LIFT[i]) * (f - int(f))


# ------------------------------------------------------------------ the Food Court floor, the players, the warnings
block("Floor", (420, 420, 1), (250, 236, 214), loc=(0, 70, -0.5))
for i in range(-10, 11):  # big red / cream tiles so speed reads
    for j in range(-4, 16):
        if (i + j) % 2 == 0:
            block("Tile", (10, 10, 0.03), (240, 84, 74), loc=(i * 10, j * 10, 0.01))

P1, _ = avatar("Target", (98, 205, 48), 0, 60)  # his target (nearest), steps out of the roll lane
P2, _ = avatar("Crowd2", (255, 160, 24), 28, 72)  # steps out of its wedge lane
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), -26, 46)  # stays put: a wedge tumbles into them
CROWD = [Vector((28, 72, 0)), Vector((-26, 46, 0))]
P2_SIDE = Vector((-CROWD[0].y, CROWD[0].x, 0)).normalized()


def lane_end(target):
    d = Vector((target.x, target.y, 0))
    return d.normalized() * min(CREW_MAX, d.length + 20)


WARN_MAIN = warn_set("WarnMain", LENGTH, 22)
WARN_CROWD = [warn_set("WarnCrowd%d" % i, lane_end(c).length, CREW_W) for i, c in enumerate(CROWD)]


# ------------------------------------------------------------------ the Wheel Split wedges (Bosses.client: makeWedge)
def wedge_mesh():
    me = bpy.data.meshes.new("Wedge")  # a wedge of cheese: a triangle 6 long x 3.4 tall, 3.6 thick (point forward)
    v = [(-1.8, -3.0, 0), (1.8, -3.0, 0), (-1.8, 3.0, 0), (1.8, 3.0, 0), (-1.8, -3.0, 3.4), (1.8, -3.0, 3.4)]
    f = [(0, 2, 3, 1), (0, 1, 5, 4), (0, 4, 2), (1, 3, 5), (2, 4, 5, 3)]
    me.from_pydata(v, [], f)
    me.update()
    return me


WEDGE_ME = wedge_mesh()


def wedge(name):
    e = empty(name)
    o = bpy.data.objects.new("Wedge", WEDGE_ME)
    o.color = lin((255, 204, 70))
    o["glow"], o["alpha"] = 0.0, 1.0
    o.data.materials.append(MAT_BLOCK)
    SC.collection.objects.link(o)
    o.parent = e
    o.location = (0, 0, -1.7)
    block("Rind", (3.7, 0.5, 3.5), (232, 168, 40), e, (0, -3.0, 0.0))
    for hx, hz in ((0.6, -0.6), (-0.4, 0.4)):
        block("Hole", (0.1, 0.9, 0.9), (214, 150, 30), e, (1.82, -1.2 + hx, hz))
    return e


WEDGES = [wedge("CheeseWedge%d" % i) for i in range(len(CROWD))]

# ------------------------------------------------------------------ cameras
CAM_GAME = camera("Cam_Gameplay", (96, -40, 84), (0, 48, 0), 28)  # a high player's-eye view of the lanes
CAM_A = camera("Cam_Start", (40, 40, 16), (0, 0, 10), 32)  # front 3/4 on the notice, salute, tip and burnout
CAM_B = camera("Cam_Run", (46, -30, 15), (0, 8, 10), 28)  # tracks the roll
CAM_C = camera("Cam_Stop", (-30, 150, 16), (0, 112, 10), 32)  # the stop and the hop back upright


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state, local t, position, yaw target)."""
    start, goal = Vector((0, 0, 0)), Vector((0, LENGTH, 0))
    if T < T_WIND:
        return "walk", T, Vector((-20 + 20 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_CHARGE:
        return "windup", T - T_WIND, start, 0.0
    if T < T_RECOVER:
        return "attack", T - T_CHARGE, start.lerp(goal, (T - T_CHARGE) / CHARGE), 0.0
    if T < T_WALK2:
        return "recover", T - T_RECOVER, goal, 0.0
    return "walk", T - T_WALK2, goal + Vector((14 * (T - T_WALK2) / 0.55, 0, 0)), -math.pi / 2


def wedge_lane(i):
    d = lane_end(CROWD[i])
    return d.normalized(), d.length


def wedge_at(i, T):
    """(position, tumble angle, scale) of wedge i: pops off the wheel's top, lands at the lane's start, waits, tumbles
    down the lane at CREW_SPEED from the attack's start, crumbles at the end."""
    n, ln = wedge_lane(i)
    t0, t1 = T_WIND + WEDGE_OFF, T_WIND + WEDGE_OFF + 0.3
    side = Vector((-n.y, n.x, 0))
    start = Vector((0, 0, 2 * WHEEL_R * SCALE)) + side * (2.5 if i == 0 else -2.5)
    rest = n * 7 + Vector((0, 0, 1.7))
    if T < t0:
        return None
    if T < t1:
        k = (T - t0) / (t1 - t0)
        return start.lerp(rest, k) + Vector((0, 0, 9 * math.sin(math.pi * k))), k * 4.0, 1.0
    if T < T_CHARGE:
        return rest, 0.0, 1.0
    k = T - T_CHARGE
    travel = (ln - 7) / CREW_SPEED
    along = 7 + CREW_SPEED * min(k, travel)
    s = 1.0 - min(1.0, max(0.0, (k - travel) / 0.15))
    return n * along + Vector((0, 0, 1.7 + 1.2 * abs(math.sin(along / 3.0)))), along / 3.0, s


def schedule_fx():
    tw = T_WIND
    crumb = (255, 214, 90)
    for i in range(12):  # the tip lands on its edge: a dust ring
        a = i / 12 * 2 * math.pi
        spawn("puff", tw + 0.64, 0.5, (math.cos(a) * 6, math.sin(a) * 6, 0.5), (math.cos(a) * 16, math.sin(a) * 16, rng.uniform(2, 6)), -10, rng.uniform(1.6, 2.4))
    for i in range(len(CROWD)):  # the wedges pop off the top: a crumb burst each
        for _ in range(8):
            spawn("chunk", tw + WEDGE_OFF, 0.5, (0, 0, 2 * WHEEL_R * SCALE), (rng.uniform(-10, 10), rng.uniform(-10, 10), rng.uniform(6, 16)), -60, rng.uniform(0.6, 1.0), crumb, spin=10)
    t = tw + 0.86
    while t < T_CHARGE:  # BURNOUT: crumbs + dust flung out BEHIND the spinning wheel
        k = (t - tw - 0.86) / (WINDUP - 0.86)
        for _ in range(2):
            spawn("puff", t, 0.45, (rng.uniform(-3, 3), -4, 0.6), (rng.uniform(-5, 5), -rng.uniform(14, 24) * (0.5 + k), rng.uniform(4, 10)), -20, rng.uniform(1.4, 2.2))
        spawn("chunk", t, 0.4, (rng.uniform(-3, 3), -3, 0.6), (rng.uniform(-4, 4), -rng.uniform(18, 30), rng.uniform(8, 16)), -70, rng.uniform(0.6, 1.0), crumb, spin=12)
        t += 0.03
    for i in range(16):  # launch: a ring of dust
        a = i / 16 * 2 * math.pi
        spawn("puff", T_CHARGE, 0.55, (math.cos(a) * 4, math.sin(a) * 4, 0.6), (math.cos(a) * 20, math.sin(a) * 20, rng.uniform(3, 7)), -10, rng.uniform(1.8, 2.6))
    f = 0
    while T_CHARGE + f / FPS < T_RECOVER - 1e-6:  # the roll: crumbs and dust behind the contact, speed streaks
        tt = T_CHARGE + f / FPS
        y = LENGTH * (tt - T_CHARGE) / CHARGE
        braking = tt > T_RECOVER - 0.2
        if braking:
            for _ in range(3):
                spawn("puff", tt, 0.5, (rng.uniform(-3, 3), y + 4, 0.6), (rng.uniform(-8, 8), rng.uniform(14, 24), rng.uniform(6, 12)), -30, rng.uniform(1.6, 2.6))
        else:
            spawn("puff", tt, 0.4, (rng.uniform(-3, 3), y - 3, 0.6), (rng.uniform(-5, 5), rng.uniform(-12, -5), rng.uniform(5, 10)), -40, rng.uniform(1.2, 2.0))
            spawn("chunk", tt, 0.45, (rng.uniform(-3, 3), y - 2, 0.6), (rng.uniform(-8, 8), rng.uniform(-10, -2), rng.uniform(10, 18)), -70, rng.uniform(0.5, 0.9), crumb, spin=12)
            for _ in range(2):
                spawn("streak", tt, 0.13, (rng.uniform(-8, 8), y + rng.uniform(-8, 2), rng.uniform(3, 20)), (0, 0, 0), 0, rng.uniform(8, 13), (255, 255, 255), 0.6)
        f += 1
    for i in range(12):  # the stop, and the hop's landing
        a = i / 12 * 2 * math.pi
        for t0 in (T_RECOVER, T_RECOVER + 0.42):
            spawn("puff", t0, 0.5, (math.cos(a) * 5, LENGTH + math.sin(a) * 5, 0.5), (math.cos(a) * 14, math.sin(a) * 14, rng.uniform(2, 6)), -10, rng.uniform(1.5, 2.2))
    for i in range(len(CROWD)):  # each wedge: crumbs as it tumbles, a crumble at the end
        n, ln = wedge_lane(i)
        travel = (ln - 7) / CREW_SPEED
        f = 0
        while f / FPS < travel:
            tt = T_CHARGE + f / FPS
            pos = n * (7 + CREW_SPEED * f / FPS)
            spawn("chunk", tt, 0.4, (pos.x, pos.y, 1.0), (rng.uniform(-6, 6) - n.x * 5, rng.uniform(-6, 6) - n.y * 5, rng.uniform(8, 14)), -70, rng.uniform(0.5, 0.8), crumb, spin=12)
            f += 2
        end = n * ln
        for _ in range(12):
            spawn("chunk", T_CHARGE + travel, 0.55, (end.x, end.y, 1.5), (rng.uniform(-12, 12), rng.uniform(-12, 12), rng.uniform(8, 18)), -70, rng.uniform(0.7, 1.2), crumb, spin=12)


P3_HIT = T_CHARGE + (CROWD[1].length - 7) / CREW_SPEED


def player_pos(T):
    p1 = Vector((0, 60, 0)).lerp(Vector((17, 62, 0)), ramp(T, T_WIND + 0.2, T_WIND + 0.8))
    p2 = CROWD[0] + P2_SIDE * 12 * ramp(T, T_WIND + 0.35, T_WIND + 0.8)
    return p1, p2


def bake():
    walk_amt, phase, prev_yaw = 1.0, 0.0, -math.pi / 2
    prev_eul = None
    last_roll = 0.0
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        speed = 40.0 if state == "walk" else 0.0
        phase += (1 / FPS) * speed / (4 * SCALE) * math.pi
        walk_amt += ((1.0 if state == "walk" else 0.0) - walk_amt) * min(1.0, 6 / FPS)
        if state == "windup":
            yaw = turn_yaw(-math.pi / 2, 0.0, tl)
        else:
            yaw = prev_yaw + ((yaw_t - prev_yaw + math.pi) % (2 * math.pi) - math.pi) * min(1.0, 6 / FPS)
        prev_yaw = yaw
        if state == "walk":
            pose = walk_pose(phase, walk_amt, T)
            if T >= T_WALK2:
                pose = lerp_pose(clip_recover(RECOVER), pose, ramp(tl, 0, 0.1))
        else:
            fn = {"windup": clip_windup, "attack": lambda x: clip_charge(x, CHARGE), "recover": clip_recover}[state]
            pose = fn(tl)
            if state == "windup" and tl < 0.1:
                pose = lerp_pose(walk_pose(phase, walk_amt, T), pose, ramp(tl, 0, 0.1))
        post(pose)
        if state == "windup":  # the wheel leads the turn
            pose["g"]["Torso"][2] += LEAD[1] * (0.0 - yaw)
        # THE CODE ROLL (as Bosses.client): distance / (WHEEL_R x Scale) while rolling, plus the clip's Roll; the recover
        # blends to upright with Unroll; the block wheel's bump lifts the root
        if state == "attack":
            roll = roll_after((pos - Vector((0, 0, 0))).length)
            last_roll = roll
        elif state == "recover":
            u = pose["fx"]["Unroll"]
            roll = last_roll + (unroll_target(last_roll) - last_roll) * u
        else:
            roll = pose["fx"]["Roll"]
        tg = pose["g"]["Torso"]
        m = Matrix.Rotation(-roll, 3, "X") @ Euler((tg[0], tg[1], tg[2]), "XYZ").to_matrix()
        eul = m.to_euler("XYZ", prev_eul) if prev_eul else m.to_euler("XYZ")
        prev_eul = eul
        tg[0], tg[1], tg[2] = eul.x, eul.y, eul.z
        pose["root"][2] += lift_at(roll)
        key_boss(fr, pos, yaw, pose)
        # warnings: drawn through the windup only, grown over 0.4 s
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
        # the wedges
        for i, we in enumerate(WEDGES):
            st = wedge_at(i, T)
            n, _ = wedge_lane(i)
            if st is None:
                we.scale = (0, 0, 0)
            else:
                p, ang, s = st
                we.location = p
                we.rotation_euler = (-ang, 0, math.atan2(-n.x, n.y))
                we.scale = (s, s, s)
            for k in ("location", "rotation_euler", "scale"):
                we.keyframe_insert(k, frame=fr)
        # the players
        p1, p2 = player_pos(T)
        P1.location, P2.location = p1, p2
        P1.rotation_euler = (0, 0, -math.pi / 2 if T_WIND + 0.18 < T < T_WIND + 0.82 else math.pi)
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND + 0.33 < T < T_WIND + 0.82 else math.atan2(CROWD[0].x, -CROWD[0].y))
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
        if T_CHARGE - 0.05 <= T <= T_RECOVER + 0.1:  # the run camera tracks alongside him
            CAM_B.location = (46, pos.y - 30, 15)
            CAM_B.rotation_euler = (Vector((0, pos.y + 8, 10)) - CAM_B.location).to_track_quat("-Z", "Y").to_euler()
            CAM_B.keyframe_insert("location", frame=fr)
            CAM_B.keyframe_insert("rotation_euler", frame=fr)
    schedule_fx()
    key_fx()


def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int(T_CHARGE * FPS), CAM_B), (int((T_RECOVER - 0.1) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # (preview time, camera, file)
    (T_WIND + 0.06, CAM_A, "01_notice"), (T_WIND + 0.3, CAM_A, "02_en_garde"), (T_WIND + 0.52, CAM_A, "03_tip_hop"),
    (T_WIND + 0.66, CAM_A, "04_lands_on_edge_wedges"), (T_WIND + 0.84, CAM_A, "05_rock_back"),
    (T_WIND + 1.12, CAM_A, "06_burnout"), (T_CHARGE + 0.05, CAM_B, "07_launch"), (T_CHARGE + 0.45, CAM_B, "08_roll"),
    (T_RECOVER - 0.08, CAM_C, "09_brake"), (T_RECOVER + 0.06, CAM_C, "10_wobble"), (T_RECOVER + 0.28, CAM_C, "11_hop_upright"),
    (T_RECOVER + 0.5, CAM_C, "12_landing_twirl"), (T_WIND + 0.9, CAM_GAME, "13_gameplay_warnings"),
    (T_CHARGE + 0.4, CAM_GAME, "14_gameplay_wheel_split"),
]
