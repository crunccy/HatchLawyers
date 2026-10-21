# tools/blender/boss_clips/eclipse_preview.py - Chief Justice Eclipse's preview scene for tools/blender/boss_anims.py: a
# Space Base deck at dusk, two attacks back to back (the GRAVITY PULL, then the GAVEL ORBIT with its 2+ player GAVEL
# VOLLEY), three players (green = his target both times: walks out of the pull's disc, stays out of the ring; orange
# dodges its volley disc; red stays and a gavel slams down on them), the floor warnings, the vortex, the ring burst, the
# volley gavels (the model's own gavels leave the orbit: hidden there, flown here), cameras, the baked timeline and
# the storyboard frames.
# ------------------------------------------------------------------ the deck, the path, the players
bg.inputs[0].default_value = (0.2, 0.15, 0.36, 1)  # (a dusky space sky)
block("Deck", (420, 420, 1), (150, 156, 178), loc=(0, 40, -0.5))
block("Path", (34, 420, 0.04), (110, 86, 170), loc=(0, 40, 0.0))
for i in range(-21, 22):  # white dashed edges
    for sx in (-1, 1):
        block("Dash", (1.2, 6, 0.06), (255, 255, 255), loc=(sx * 16.4, 40 + i * 10, 0.02))
for i in range(-10, 11):  # deck plating seams so distances read
    block("Seam", (0.6, 420, 0.03), (128, 134, 158), loc=(i * 20 + (10 if i >= 0 else -10), 40, 0.01))

YAW_T = math.atan2(-10, 26)  # the server's Yaw: toward the target where it stood when each windup began
FWD = Vector((-math.sin(YAW_T), math.cos(YAW_T), 0))
P1, _ = avatar("Target", (98, 205, 48), 10, 26)  # his target: walks straight out of the pull's disc, stays out of the ring
P2, _ = avatar("Crowd2", (255, 160, 24), -48, 58)  # sidesteps out of its volley disc
P3, P3EGGS = avatar("Crowd3", (240, 70, 70), 52, 66)  # stays put: a gavel slams down on them
P1_OUT = Vector((18, 46, 0))  # out of the pull's disc (49 studs from him; it reaches 44) and of the ring (38)
VOLLEY = [Vector((-48, 58, 0)), Vector((52, 66, 0))]  # Ring turn: disc centres = where they stood when the windup began
P2_SIDE = Vector((-1, -0.3, 0)).normalized()


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
WARN_INNER = mesh_obj("WarnInner", disc_mesh("Inner", 1.0, 32), (255, 255, 255), MAT_WARN, 0.8)
DISC_EDGE = [block("DiscEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(36)]
SWIRL = [block("WarnSwirl", (1.2, 4, 0.14), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(8)]
VOLLEY_DISCS = [mesh_obj("VolleyDisc", disc_mesh("Volley%d" % i, 1.0), COLOR, MAT_WARN, 0.6) for i in range(len(VOLLEY))]
VOLLEY_EDGE = [[block("VolleyEdge", (1.6, 0.8, 0.16), COLOR, mat=MAT_WARN, glow=1.0) for _ in range(24)] for _ in VOLLEY]
RINGS = [mesh_obj("BurstRing%d" % k, disc_mesh("BurstRingMesh%d" % k, 1.0, 48), c, MAT_FX, 0.9)
         for k, c in enumerate((COLOR, (255, 255, 255), (255, 200, 60)))]
VOLLEY_RINGS = [mesh_obj("VolleyRing", disc_mesh("VolleyRingMesh%d" % i, 1.0, 32), COLOR, MAT_FX, 0.9) for i in range(len(VOLLEY))]
SHADOWS = [mesh_obj("GavelShadow", disc_mesh("Shadow%d" % i, 1.0), (30, 30, 40), MAT_FX, 0.0) for i in range(len(VOLLEY))]


def volley_gavel(name):  # a copy of an orbiting gavel (Bosses.client clones the model's own parts)
    e = empty(name)
    block("Handle", (0.22, 0.22, 1.2), (122, 70, 34), e, (0, 0, -0.3))
    block("Head", (1.3, 0.65, 0.65), (150, 92, 46), e, (0, 0, 0.625))
    block("Band", (0.3, 0.7, 0.7), (255, 200, 60), e, (0, 0, 0.625), glow=1.0)
    e.scale = (0, 0, 0)
    return e


COPIES = [volley_gavel("VolleyGavel%d" % i) for i in range(len(VOLLEY))]

# ------------------------------------------------------------------ cameras
CAM_GAME = camera("Cam_Gameplay", (74, -64, 110), (0, 36, 0), 24)  # a high player's-eye view
CAM_A = camera("Cam_Front", (40, 64, 18), (0, 2, 20), 30)  # front 3/4: the summon, the pull
CAM_B = camera("Cam_Low", (-30, 58, 8), (0, 4, 22), 30)  # low, the other side: the ring burst
CAM_C = camera("Cam_Wide", (66, 92, 40), (0, 20, 12), 26)  # wide: the volley


# ===================================================================================== bake the timeline
def boss_state(T):
    """Server state at preview time T: (state + "_" + kind, local t, position, yaw target)."""
    o = Vector((0, 0, 0))
    if T < T_WIND:
        return "walk", T, Vector((-20 + 20 * T / T_WIND, 0, 0)), -math.pi / 2
    if T < T_PULL:
        return "windup_Pull", T - T_WIND, o, YAW_T
    if T < T_REC1:
        return "attack_Pull", T - T_PULL, o, YAW_T
    if T < T_WALK2:
        return "recover_Pull", T - T_REC1, o, YAW_T
    if T < T_WIND2:
        return "walk", T - T_WALK2, o, YAW_T
    if T < T_RING:
        return "windup_Ring", T - T_WIND2, o, YAW_T
    if T < T_REC2:
        return "attack_Ring", T - T_RING, o, YAW_T
    if T < T_WALK3:
        return "recover_Ring", T - T_REC2, o, YAW_T
    return "walk", T - T_WALK3, Vector((-12 * (T - T_WALK3) / 0.5, 0, 0)), math.pi / 2


def pose_at(T, walk_amt):
    state, tl, pos, yaw_t = boss_state(T)
    if state == "walk":
        pose = walk_pose(0.0, walk_amt, T)
        if T >= T_WALK3:
            pose = lerp_pose(clip_recover_ring(RECOVER), pose, ramp(tl, 0, 0.1))
        elif T >= T_WALK2:
            pose = lerp_pose(clip_recover_pull(RECOVER), pose, ramp(tl, 0, 0.1))
    else:
        pose = CLIPS[state][0](tl)
        if state.startswith("windup") and tl < 0.1:
            pose = lerp_pose(walk_pose(0.0, walk_amt, T), pose, ramp(tl, 0, 0.1))
    return post(pose)


SLOT = {}  # frame -> [the volley gavels' orbit slots (world matrix of G_Gavel1 / 2, turned so the head runs along x)]


def bake():
    walk_amt, prev_yaw, spin = 1.0, -math.pi / 2, 0.0
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        walk_amt += ((1.0 if state == "walk" else 0.0) - walk_amt) * min(1.0, 6 / FPS)
        if state.startswith("windup"):
            y0 = -math.pi / 2 if T < T_WALK2 else YAW_T
            yaw = turn_yaw(y0, YAW_T, tl)
        else:
            yaw = prev_yaw + ((yaw_t - prev_yaw + math.pi) % (2 * math.pi) - math.pi) * min(1.0, 6 / FPS)
        prev_yaw = yaw
        pose = pose_at(T, walk_amt)
        if state.startswith("windup"):  # the eclipse turns to you first (the client does the same: BossAnims Turn.Lead)
            pose["g"][LEAD[0]][2] += LEAD[1] * (YAW_T - yaw)
        spin += (ORBIT_SPIN[0] + (ORBIT_SPIN[1] - ORBIT_SPIN[0]) * pose["fx"].get("Spin", 0.0)) / FPS
        pose["g"]["Gavels"] = [0.0, 0.0, spin, 0.0, 0.0, 0.0]
        key_boss(fr, pos, yaw, pose)
    # the volley gavels' slots, frame by frame (where each copy leaves from and flies home to)
    t0, t1 = int((T_WIND2 + LOCK_ON) * FPS) - 1, int((T_WALK3 + 0.05) * FPS)
    for fr in range(t0, t1 + 1):
        SC.frame_set(fr)
        SLOT[fr] = [bpy.data.objects["G_" + GAVELS[i]].matrix_world @ Matrix.Rotation(GAVEL_ANGLE[GAVELS[i]], 4, "Z")
                    for i in range(len(VOLLEY))]
    schedule_fx()
    key_world()
    key_fx()


def schedule_fx():
    tw, tp, tr = T_WIND, T_PULL, T_RING
    for i in range(70):  # the VORTEX: motes and sparks spiral in from the disc's edge all through the pull
        t0 = tp + i * PULL / 70
        a = rng.uniform(0, 2 * math.pi)
        rr = rng.uniform(26, RADIUS)
        start = Vector((math.cos(a) * rr, math.sin(a) * rr, rng.uniform(1, 10)))
        inward = -start.normalized() * rng.uniform(28, 40)
        swirl = Vector((-math.sin(a), math.cos(a), 0)) * rng.uniform(14, 22)
        spawn("spark" if i % 3 else "puff", t0, rng.uniform(0.5, 0.8), start, (inward + swirl).to_tuple(), 6,
              rng.uniform(1.0, 1.8), COLOR if i % 2 else (255, 255, 255), glow=0.8)
    for i in range(12):  # the summon: a ring of sparks rising round him
        a = i / 12 * 2 * math.pi
        spawn("spark", tw + 0.4, 0.6, (math.cos(a) * 8, math.sin(a) * 8, 1), (math.cos(a) * 4, math.sin(a) * 4, 22), 0,
              1.4, (255, 200, 60), glow=1.0)
    for i in range(28):  # the RING BURST: star sparks flung out with the gavels
        a = i / 28 * 2 * math.pi
        spawn("spark", tr, 0.5, (math.cos(a) * 6, math.sin(a) * 6, 24), (math.cos(a) * 70, math.sin(a) * 70, rng.uniform(-8, 8)), 0,
              rng.uniform(1.2, 2.0), COLOR if i % 2 else (255, 230, 140), glow=1.0)
    for c in VOLLEY:  # each volley gavel slams down: dust and stars
        for i in range(12):
            a = i / 12 * 2 * math.pi
            spawn("puff", tr, 0.5, c + Vector((math.cos(a) * 2, math.sin(a) * 2, 0.5)), (math.cos(a) * 16, math.sin(a) * 16, rng.uniform(2, 5)),
                  -10, rng.uniform(1.5, 2.2), (200, 190, 230))
        for i in range(8):
            spawn("spark", tr, 0.4, c + Vector((0, 0, 1)), (rng.uniform(-14, 14), rng.uniform(-14, 14), rng.uniform(10, 22)), -30,
                  rng.uniform(1.0, 1.5), (255, 220, 120), glow=1.0)


P3_HIT = T_RING


def copy_at(i, fr):
    """A volley gavel copy at frame fr: (world matrix, visible). Leaves its slot at LOCK_ON, flips head-down rising to
    hover over its disc, slams down as the ring goes off, bounces, then flies home to its (moving) slot."""
    T = fr / FPS
    a0, hover, slam, home = T_WIND2 + LOCK_ON, T_RING - 0.16, T_RING, T_REC2 + 0.5
    if T < a0 or T >= home:
        return None
    c = VOLLEY[i]
    s_mat = SLOT.get(fr, SLOT[min(SLOT)])[i]
    loc0, rot0 = SLOT[min(SLOT)][i].to_translation(), SLOT[min(SLOT)][i].to_quaternion()
    down = Euler((math.pi, 0, math.atan2(-c.x, c.y)), "XYZ").to_quaternion()  # handle up, head down
    over = c + Vector((0, 0, 30))
    floor = c + Vector((0, 0, 0.95 * SCALE))  # (the head's face on the floor)
    if T < hover:
        k = (T - a0) / (hover - a0)
        loc = loc0.lerp(over, EASE["io"](k)) + Vector((0, 0, 14 * math.sin(math.pi * k)))
        rot = rot0.slerp(down, EASE["io"](k))
    elif T < slam:
        k = (T - hover) / (slam - hover)
        loc = over + Vector((0, 0, 4 * math.sin(math.pi * min(1, k * 1.6)))) if k < 0.6 else over.lerp(floor, EASE["in"]((k - 0.6) / 0.4))
        rot = down
    else:
        k = (T - slam) / (home - slam)
        back = s_mat.to_translation()
        loc = floor.lerp(back, EASE["io"](k)) + Vector((0, 0, 12 * math.sin(math.pi * k)))
        rot = down.slerp(s_mat.to_quaternion(), EASE["io"](k))
    return Matrix.Translation(loc) @ rot.to_matrix().to_4x4() @ Matrix.Diagonal((SCALE, SCALE, SCALE, 1))


def key_world():
    for fr in range(SC.frame_start, SC.frame_end + 1):
        T = fr / FPS
        state, tl, pos, yaw_t = boss_state(T)
        pulse = 0.5 + 0.5 * math.sin(T * 18)
        wind = state.startswith("windup")
        pull = state == "attack_Pull" or state == "windup_Pull"
        ring = state == "windup_Ring"
        grow = 0.45 + 0.55 * EASE["out"](min(1.0, tl / 0.4)) if wind else 1.0
        # the main disc: the pull's (with its deadly middle + swirl, kept while it drags) or the ring's
        vis = 1.0 if (pull or ring) else 0.0
        r = (RADIUS if pull else RING_R) * grow
        WARN_DISC.location, WARN_DISC.scale = (0, 0, 0.06), (r, r, 1)
        WARN_DISC["alpha"] = (0.4 - 0.2 * pulse) * vis
        WARN_INNER.location, WARN_INNER.scale = (0, 0, 0.09), (INNER, INNER, 1)
        WARN_INNER["alpha"] = (0.55 - 0.25 * pulse) * (1.0 if pull else 0.0)
        for o in (WARN_DISC, WARN_INNER):
            for k in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        for i, o in enumerate(DISC_EDGE):
            a = i / 36 * 2 * math.pi
            o.location = (-math.sin(a) * r, math.cos(a) * r, 0.08)
            o.rotation_euler = (0, 0, a)
            o.scale = (max(1.5, r * 2 * math.pi / 36 * 1.05), 0.8, 0.16)
            o["alpha"] = (0.85 - 0.35 * pulse) * vis
            for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        for i, o in enumerate(SWIRL):
            a = i / 8 * 2 * math.pi + T * 2.5
            o.location = (-math.sin(a) * r * 0.62, math.cos(a) * r * 0.62, 0.1)
            o.rotation_euler = (0, 0, a + 0.7)
            o.scale = (1.2, r * 0.45, 0.14)
            o["alpha"] = 0.75 * (1.0 if pull else 0.0)
            for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                o.keyframe_insert(k, frame=fr)
        # the volley discs (the Ring's windup only)
        for d, edges, c in zip(VOLLEY_DISCS, VOLLEY_EDGE, VOLLEY):
            rr = VOLLEY_R * grow
            v = 1.0 if ring else 0.0
            d.location, d.scale = (c.x, c.y, 0.07), (rr, rr, 1)
            d["alpha"] = (0.4 - 0.2 * pulse) * v
            for k in ("location", "scale", '["alpha"]'):
                d.keyframe_insert(k, frame=fr)
            for i, o in enumerate(edges):
                a = i / 24 * 2 * math.pi
                o.location = (c.x - math.sin(a) * rr, c.y + math.cos(a) * rr, 0.09)
                o.rotation_euler = (0, 0, a)
                o.scale = (max(1.4, rr * 2 * math.pi / 24 * 1.05), 0.8, 0.16)
                o["alpha"] = (0.85 - 0.35 * pulse) * v
                for k in ("location", "scale", "rotation_euler", '["alpha"]'):
                    o.keyframe_insert(k, frame=fr)
        # the ring burst (+ a white one, + a gold one): out to the ring's edge as the gavels fly
        for kidx, (o, delay, rmax, alpha) in enumerate(zip(RINGS, (0.0, 0.06, 0.12), (RING_R, RING_R * 0.8, RING_R * 0.55), (0.8, 0.7, 0.6))):
            k = (T - T_RING - delay) / 0.38
            o.location = (0, 0, 0.5 + 0.8 * max(0.0, k) + kidx * 0.05)
            rr = 1 + (rmax - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = alpha * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        for o, c in zip(VOLLEY_RINGS, VOLLEY):
            k = (T - T_RING) / 0.32
            o.location = (c.x, c.y, 0.5 + 0.6 * max(0.0, k))
            rr = 1 + (VOLLEY_R - 1) * EASE["out"](min(1.0, max(0.0, k)))
            o.scale = (rr, rr, 1) if 0 <= k <= 1 else (0, 0, 0)
            o["alpha"] = 0.8 * (1 - k) if 0 <= k <= 1 else 0.0
            for kk in ("location", "scale", '["alpha"]'):
                o.keyframe_insert(kk, frame=fr)
        # the volley: each copy flies, the model's gavel it left is hidden meanwhile; a shadow grows on its disc
        for i, (cp, sh) in enumerate(zip(COPIES, SHADOWS)):
            m = copy_at(i, fr) if SLOT else None
            for o in group_blocks(GAVELS[i]):  # (hidden from the render only: the clipping check still sees them)
                o.hide_render = m is not None
                o.keyframe_insert("hide_render", frame=fr)
            if m is not None:
                cp.matrix_world = m
            else:
                cp.scale = (0, 0, 0)
            for kk in ("location", "rotation_euler", "scale"):
                cp.keyframe_insert(kk, frame=fr)
            c = VOLLEY[i]
            k = (T - T_WIND2 - LOCK_ON) / (WINDUP - LOCK_ON)
            if 0 <= k <= 1:
                ss = 1.5 + 4 * k
                sh.location, sh.scale, sh["alpha"] = (c.x, c.y, 0.11), (ss, ss, 1), 0.45 * k
            else:
                sh.scale, sh["alpha"] = (0, 0, 0), 0.0
            for kk in ("location", "scale", '["alpha"]'):
                sh.keyframe_insert(kk, frame=fr)
        # players: green walks straight out of the pull and stays out; orange sidesteps its volley disc; red is slammed
        p1 = Vector((10, 26, 0)).lerp(P1_OUT, ramp(T, T_WIND + 0.15, T_WIND + 1.2))
        p2 = VOLLEY[0] + P2_SIDE * 14 * ramp(T, T_WIND2 + 0.4, T_WIND2 + 0.9)
        P1.location, P2.location = p1, p2
        d1 = P1_OUT - Vector((10, 26, 0))
        P1.rotation_euler = (0, 0, math.atan2(-d1.x, d1.y) if T_WIND + 0.13 < T < T_WIND + 1.22 else math.atan2(10, -26))
        P2.rotation_euler = (0, 0, math.atan2(-P2_SIDE.x, P2_SIDE.y) if T_WIND2 + 0.38 < T < T_WIND2 + 0.92 else math.atan2(48, -58))
        if T > P3_HIT:
            k = min(1.0, (T - P3_HIT) / 0.7)
            fling = Vector((VOLLEY[1].x, VOLLEY[1].y, 0)).normalized()
            P3.location = VOLLEY[1] + fling * 16 * EASE["out"](k) + Vector((0, 0, 7 * math.sin(math.pi * min(1, k * 1.2))))
            P3.rotation_euler = (0, -math.pi * 0.5 * EASE["out"](k), math.atan2(-fling.x, fling.y))
            for i, egg in enumerate(P3EGGS):
                a = i / 3 * 2 * math.pi + 0.4
                ke = min(1.0, (T - P3_HIT - i * 0.05) / 0.6) if T > P3_HIT + i * 0.05 else 0
                egg.location = Vector((math.cos(a) * 9 * ke, math.sin(a) * 9 * ke, 5.9 + i * 1.5 + 9 * math.sin(math.pi * ke) - (5.9 + i * 1.5 - 0.8) * ke))
                egg.keyframe_insert("location", frame=fr)
        else:
            P3.location = VOLLEY[1]
            P3.rotation_euler = (0, 0, math.atan2(VOLLEY[1].x, -VOLLEY[1].y))
            for i, egg in enumerate(P3EGGS):
                egg.location = (0, 0.2, 5.9 + i * 1.5)
                egg.keyframe_insert("location", frame=fr)
        for o in (P1, P2, P3):
            o.keyframe_insert("location", frame=fr)
            o.keyframe_insert("rotation_euler", frame=fr)


def cine_cuts():
    SC.timeline_markers.clear()
    for fr, cam in ((0, CAM_A), (int((T_WIND2 + 1.0) * FPS), CAM_B), (int((T_REC2 + 0.05) * FPS), CAM_C)):
        m = SC.timeline_markers.new(cam.name, frame=fr)
        m.camera = cam
    SC.camera = CAM_A


# ------------------------------------------------------------------ storyboard frames ("-- stills")
BOARD = [  # (preview time, camera, file)
    (T_WIND + 0.1, CAM_A, "01_pull_notice"), (T_WIND + 0.6, CAM_A, "02_pull_summon_rise"), (T_WIND + 1.3, CAM_A, "03_pull_wind_back"),
    (T_PULL + 0.25, CAM_A, "04_PULL_heave"), (T_PULL + 1.0, CAM_GAME, "05_gameplay_pull_vortex"),
    (T_REC1 + 0.3, CAM_A, "06_pull_let_go"), (T_WIND2 + 0.6, CAM_A, "07_ring_spread_spin_up"),
    (T_WIND2 + 1.05, CAM_C, "08_volley_lock_on"), (T_WIND2 + 1.32, CAM_B, "09_ring_gather"),
    (T_RING + 0.06, CAM_B, "10_RING_burst"), (T_RING + 0.02, CAM_GAME, "11_gameplay_ring_and_volley"),
    (T_REC2 + 0.25, CAM_C, "12_gavels_home"),
]
