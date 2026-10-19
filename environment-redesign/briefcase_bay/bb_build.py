# environment-redesign/briefcase_bay/bb_build.py - STAGE 5, island 1: BRIEFCASE BAY (2026-10-18).
# A bright business & legal district on its own floating island. Route (crnuch's call: return portal past the boss):
#   ARRIVAL plaza (south) -> BRIEFCASE BAY gate -> boulevard + cross street through two OFFICE-PARK EGG FIELDS
#   -> PARTNERS' PLAZA (the boss arena: The Senior Partner) -> RETURN HOME portal (north; the way home WITH eggs)
#   Blender -b --python environment-redesign/briefcase_bay/bb_build.py [-- norender | -- only=aerial,layout]
# Writes briefcase_bay.blend, bb_layout.json, renders/*.jpg. 1 stud = 1 m, +Y = north; island origin = its centre.
import bpy, json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(os.path.dirname(HERE), "kit")
sys.path.insert(0, HERE)
sys.path.insert(0, KIT)
import hl_kit as K
import hl_island as HI
import bb_parts as P

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDERS = os.path.join(HERE, "renders")
os.makedirs(RENDERS, exist_ok=True)
K.rng.seed(901)
polar = HI.polar

scene = K.reset(["Briefcase_Bay", "Vegetation", "Shared_Props", "Buildings", "Environmental_Effects", "Lighting", "Presentation"])
C = K.COLS
for n in ("BB_Terrain", "BB_Cliffs", "BB_Streets", "BB_EggFields", "BB_Arena", "BB_Water", "BB_Sky", "BB_Labels", "BB_Gameplay_Markers"):
    K.col(n, "Briefcase_Bay")
I = HI.Island("Briefcase_Bay", rx=150, ry=195, seed=11)
LAYOUT = {"island": "Briefcase Bay", "radius_xy": [150, 195], "places": [], "egg_spots": []}


def face_to(x, y, tx, ty):
    """The Frame rotation that turns a piece at (x, y) so its front (-y) looks at (tx, ty)."""
    return math.degrees(math.atan2(tx - x, -(ty - y)))


def note(name, x, y, what):
    LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})


# ------------------------------------------------------------------ plan
ARRIVAL = (0, -150)
ARENA, ARENA_R = (0, 70), 62
PORTAL = (0, 160)
CROSS_Y = -48
PARKS = {  # name: (cx, cy, sx, sy)
    "West Park South": (-62, -82, 84, 44), "West Park North": (-62, -22, 84, 30),
    "East Park South": (46, -82, 56, 44), "East Park North": (46, -22, 56, 30),
}
HARBOUR = (108, -40)

# ------------------------------------------------------------------ streets + plazas (covers first)
st = K.Mesh("Streets", C["BB_Streets"])
# arrival plaza
st.cyl(*ARRIVAL, 26, 0, 0.35, "stone_warm", segs=64, studs=True)
st.ring(24, 25.2, 0.35, 0.6, "gold", cx=ARRIVAL[0], cy=ARRIVAL[1], segs=64)
I.cover_circle(*ARRIVAL, 27)
# boulevard: arrival -> arena, paving with a gold centre line, lamps + trees in planters
y0, y1 = ARRIVAL[1] + 24, ARENA[1] - ARENA_R + 1
st.brick(0, (y0 + y1) / 2, 0, 20, y1 - y0, 0.4, "stone_warm", studs=True)
st.brick(0, (y0 + y1) / 2, 0.4, 1.0, y1 - y0, 0.08, "gold", studs=False, bevel=0.02)
for sx in (-1, 1):
    st.brick(sx * 10.5, (y0 + y1) / 2, 0, 1.0, y1 - y0, 0.8, "curb", studs=False)
I.cover_rect(0, (y0 + y1) / 2, 22, y1 - y0)
# the cross street: a proper road (studded asphalt, dashes, curbs, sidewalks, crosswalk)
XW, XE = -113, 84  # west: the cliff edge; east: it ends at the harbour quay (the road down to the bay)
L, XC = XE - XW, (XE + XW) / 2
st.brick(XC, CROSS_Y, 0, L, 12, 0.3, "road", studs=True)
for k in range(int(L / 6)):
    x = XW + 3 + k * 6
    if abs(x) > 13:
        st.brick(x, CROSS_Y, 0.3, 2.6, 0.5, 0.12, "white", studs=False, bevel=0.03)
for sy in (-1, 1):
    st.brick(XC, CROSS_Y + sy * 6.5, 0, L, 1.0, 0.7, "curb", studs=False)
    st.brick(XC, CROSS_Y + sy * 8.5, 0, L, 3.0, 0.6, "stone_warm", studs=True)
for k in range(7):
    st.brick(-6 + k * 2, CROSS_Y, 0.3, 1.0, 11, 0.1, "white", studs=False, bevel=0.02)
I.cover_rect(XC, CROSS_Y, L, 20)
I.cover_fn(lambda x, y, p: abs(y - CROSS_Y) < 10 + p and not I.inside(x, y, 4))  # (road ends at the cliff)
# arena approach + north exit paving to the portal stairs
st.brick(0, ARENA[1] + ARENA_R + 6, 0, 16, 14, 0.4, "stone_warm", studs=True)
I.cover_rect(0, ARENA[1] + ARENA_R + 6, 16, 14)
st.done()

dress = K.Mesh("Street_Dressing", C["Shared_Props"])
strees = K.Mesh("Street_Trees", C["Vegetation"])  # (own object: the wind sways trees, never the lamp posts)
for y in range(-118, 0, 14):
    if abs(y - CROSS_Y) < 12:
        continue
    for sx in (-1, 1):
        K.planter(dress, sx * 13.5, y, 3.6, 3.6, plant="bush")
        K.tree_round(K.Frame(strees, sx * 13.5, y, 0, z=2.2), 0, 0, 0.75)
        K.lamp(dress, sx * 13.5, y + 7, 11)
strees.done()
for x, y, rot in ((-12, CROSS_Y - 9, 0), (12, CROSS_Y - 9, 0), (-12, CROSS_Y + 9, 180), (12, CROSS_Y + 9, 180)):
    P.traffic_light(K.Frame(dress, 0, 0, 0), x, y, rot)
for k in range(10):
    a = k * 36 + 18
    if abs(HI.angdiff(a, 90)) < 22:
        continue
    x, y = polar(22, a)
    K.bench(dress, ARRIVAL[0] + x, ARRIVAL[1] + y, rot=a - 90)
    lx, ly = polar(25.5, a + 18)
    K.lamp(dress, ARRIVAL[0] + lx, ARRIVAL[1] + ly, 11)
dress.done()

# ------------------------------------------------------------------ landmarks + buildings
bld = K.Mesh("Buildings", C["Buildings"])


def place(fn, x, y, rot, title, what, cover=None, **kw):
    fn(K.Frame(bld, x, y, rot), **kw)
    note(title, x, y, what)
    if cover:
        sx, sy = cover
        I.cover_rect(x, y, sx, sy, rot, pad=1)


place(P.arrival_pad, ARRIVAL[0], ARRIVAL[1] - 6, 0, "Arrival pad", "where Travel lands players (ZoneService Arrival)", (18, 18))
place(P.welcome_gate, 0, ARRIVAL[1] + 28, 0, "BRIEFCASE BAY gate", "welcome arch over the boulevard", (32, 6))
place(P.kiosk, -26, ARRIVAL[1] + 8, 90, "News kiosk", "decor", (7, 6))
place(P.bus_stop, 26, ARRIVAL[1] + 6, -90, "Bus stop", "decor", (10, 5))
place(P.office_tower, -118, 0, 90, "Lexicon Law tower", "office tower (fictional firm)", (26, 28), name="LEXICON LAW", floors=10)
place(P.office_block, -120, -84, 90, "Brief & Co.", "mid-rise offices", (22, 32), name="BRIEF & CO.", floors=4)
place(P.law_library, -108, 64, 90, "Law Library", "classical library", (28, 36))
place(P.office_tower, 124, 8, -90, "Caseworks tower", "office tower (teal glass)", (26, 30), name="CASEWORKS", floors=8, glass="glass", accent="teal", crown="flat")
place(P.office_block, 108, 74, -90, "Notary House", "mid-rise offices", (22, 32), name="NOTARY HOUSE", floors=3, wall="brick_red", shutters="roof_navy")
place(P.coffee_shop, 60, -118, 180, "Coffee Break", "café (steam rises in the ambience)", (24, 22))
for x in (-86, 86):
    rot = face_to(x, 128, *ARENA)
    place(P.office_tower, x, 128, rot, "Amicus Tower" if x < 0 else "Verdict Tower", "tower round the arena", (30, 30),
          name="AMICUS" if x < 0 else "VERDICT", floors=11 if x < 0 else 9, glass="glass_dark" if x < 0 else "glass",
          accent="roof_blue" if x < 0 else "purple")
for (x, y, fn, title, kw, cover) in (
        (-58, 166, P.office_tower, "Habeas Tower", dict(name="HABEAS", floors=7, glass="glass", accent="teal", crown="flat"), (28, 26)),
        (58, 166, P.office_tower, "Docket Tower", dict(name="DOCKET", floors=8, accent="roof_blue"), (28, 26)),
        (-132, -40, P.office_block, "Clause & Co.", dict(name="CLAUSE & CO.", floors=5, wall="stone"), (22, 30)),
        (118, -96, P.office_tower, "Tort Tower", dict(name="TORT TOWER", floors=6, glass="glass_dark", accent="sign_green", crown="flat"), (28, 26)),
        (-80, -142, P.office_block, "Paralegal Place", dict(name="PARALEGAL", floors=3, wall="cream", shutters="sign_green"), (30, 22)),
        (128, 40, P.office_block, "Affidavit House", dict(name="AFFIDAVIT", floors=4, wall="brick_red", shutters="roof_navy"), (22, 30))):
    place(fn, x, y, face_to(x, y, 0, y * 0.4), title, "office building (fictional firm)", cover, **kw)
place(P.giant_gavel, -34, 146, 0, "Giant gavel", "monument by the arena's north exit", (12, 12), s=1.0)
place(P.giant_briefcase, 34, 146, 0, "Giant briefcase", "monument by the arena's north exit", (14, 10), s=1.0)
place(P.return_portal, PORTAL[0], PORTAL[1], 0, "RETURN HOME portal", "the way home WITH eggs, past the boss (crnuch's call)", (42, 50))
bld.done()

# ------------------------------------------------------------------ Partners' Plaza (boss arena) + the boss for scale
ar = K.Mesh("Partners_Plaza", C["BB_Arena"])
P.partners_plaza(K.Frame(ar, *ARENA, 0), R=ARENA_R, openings=(270, 90))
ar.done()
I.cover_circle(*ARENA, ARENA_R + 1)
I.cover_circle(*ARENA, ARENA_R + 20, ground=False)
note("Partners' Plaza (boss arena)", *ARENA, f"open floor r {ARENA_R}: The Senior Partner (45-stud cone, 60-stud trigger) roams it")
HI.boss(C["BB_Arena"], "SeniorPartner", ARENA[0] + 10, ARENA[1] + 6, scale=3.5, facing=200)

# ------------------------------------------------------------------ the bay (harbour) + its waterfall; a second fall west
wat = K.Mesh("Water", C["BB_Water"])
P.harbour(K.Frame(wat, *HARBOUR, -90), R=22)
I.cover_circle(*HARBOUR, 26)
note("The Bay (harbour)", *HARBOUR, "basin, boardwalk, the Bay Ferry; overflows into the east waterfall")
a_bay = math.degrees(math.atan2(HARBOUR[1], HARBOUR[0]))
I.waterfall(wat, a_bay, stream=I.r(a_bay) - math.hypot(*HARBOUR) - 22, pond=False)
I.waterfall(wat, 167, stream=14, pond=False)
wat.done()

# ------------------------------------------------------------------ office-park egg fields
eg = K.Mesh("Egg_Fields", C["BB_EggFields"])
mk = K.Mesh("Egg_Spots", C["BB_Gameplay_Markers"])
spots = []
for name, (cx, cy, sx, sy) in PARKS.items():
    F = K.Frame(eg, cx, cy, 0)
    # hedge border with gaps on the street sides, an orange path loop (white dashed edges), beds, benches, planters
    for side in (-1, 1):
        for k in range(int(sx / 6)):
            x = -sx / 2 + 3 + k * 6
            if abs(x) > 6:
                K.hedge(F, x, side * sy / 2, 5.4, 0, h=2.2, w=2.0)
        for k in range(int(sy / 6)):
            y = -sy / 2 + 3 + k * 6
            if abs(y) > 5:
                K.hedge(F, side * sx / 2, y, 5.4, 90, h=2.2, w=2.0)
    px, py = sx / 2 - 9, sy / 2 - 8
    for (x0, y0_, x1, y1_) in ((-px, -py, px, -py), (-px, py, px, py), (-px, -py, -px, py), (px, -py, px, py)):
        L_ = math.hypot(x1 - x0, y1_ - y0_) + 4
        rot = math.degrees(math.atan2(y1_ - y0_, x1 - x0))
        F.brick((x0 + x1) / 2, (y0_ + y1_) / 2, 0, L_, 4, 0.35, "path", rot=rot)
        wx, wy = F.p((x0 + x1) / 2, (y0_ + y1_) / 2)
        I.cover_rect(wx, wy, L_ + 1, 5, rot)
    F.brick(0, -sy / 2 + 4, 0, 4, 9, 0.35, "path", rot=90)  # path in from the street
    F.brick(0, sy / 2 - 4, 0, 4, 9, 0.35, "path", rot=90)
    K.flowerbed(F, 0, 0, 10, 5)
    for x in (-px + 4, px - 4):
        K.bench(F, x, 0, rot=90)
        P.filing_planter(F, x, sy / 2 - 3.5, 0)
    P.water_cooler(F, px - 1, -py + 3)
    wx, wy = F.p(0, 0)
    I.cover_circle(wx, wy, 6)
    # egg spots: open lawn inside the hedges, clear of paths / beds / benches, >= 7 studs apart, ~6 per park
    got, tries = 0, 0
    while got < 6 and tries < 400:
        tries += 1
        ex, ey = F.p(K.rng.uniform(-sx / 2 + 4, sx / 2 - 4), K.rng.uniform(-sy / 2 + 4, sy / 2 - 4))
        if I.covered(ex, ey, 2.4) or any((ex - qx) ** 2 + (ey - qy) ** 2 < 49 for qx, qy, _ in spots):
            continue
        spots.append((ex, ey, name))
        got += 1
for a in (30, 150, 210, 330):  # 4 risky bonus spots inside the arena rim
    ex, ey = polar(ARENA_R - 7, a)
    spots.append((ARENA[0] + ex, ARENA[1] + ey, "Partners' Plaza (bonus, inside the boss arena)"))
M = K.Frame(mk, 0, 0, 0)
for i, (x, y, where) in enumerate(spots):
    P.egg_spot(M, x, y)
    if i % 3 == 0:
        P.briefcase_egg(K.Frame(eg, 0, 0, 0), x, y, 1.0, golden=(i % 12 == 0))
    LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "where": where})
eg.done()
mk.done()

# ------------------------------------------------------------------ landscaping, hills, sky
veg = K.Mesh("Vegetation", C["Vegetation"])
I.build_top(C["BB_Terrain"])
I.cover_circle(*PORTAL, 22)
I.groves(veg, 26, kinds=("round", "round", "blossom", "pine", "mixed"), margin=14, spacing=26, sizes=(5, 9))
for k in range(8):  # palms round the bay
    x, y = polar(30 + (k % 3) * 3, k * 40 + 10)
    x, y = HARBOUR[0] + x, HARBOUR[1] + y
    if I.inside(x, y, 6) and not I.covered(x, y, 3):
        K.tree_palm(veg, x, y, 1.0)
        I.cover_circle(x, y, 3, ground=False)
I.hills(veg, 6, rmin_f=0.7)
veg.done()
I.build_cliffs(C["BB_Cliffs"])
sk = K.Mesh("Clouds_Islets", C["BB_Sky"])
I.clouds(sk, n=16, islets=7)
sk.done()
I.grass_studs()
K.studs_done(C["Briefcase_Bay"])

# ------------------------------------------------------------------ labels (layout render)
lab = K.Mesh("Label_Plates", C["BB_Labels"])
for text, x, y in (("ARRIVAL", 0, -150), ("BRIEFCASE BAY GATE", 0, -116), ("EGG FIELD\nWest Park S", -62, -82), ("EGG FIELD\nWest Park N", -62, -22),
                   ("EGG FIELD\nEast Park S", 46, -82), ("EGG FIELD\nEast Park N", 46, -22), ("THE BAY\n(harbour + waterfall)", 108, -40),
                   ("PARTNERS' PLAZA\nboss arena", 0, 70), ("RETURN HOME\nportal", 0, 166), ("CROSS STREET", -96, CROSS_Y),
                   ("LEXICON LAW", -118, 0), ("BRIEF & CO.", -120, -84), ("LAW LIBRARY", -108, 64), ("CASEWORKS", 124, 8),
                   ("NOTARY HOUSE", 108, 74), ("COFFEE", 60, -118), ("AMICUS", -86, 128), ("VERDICT", 86, 128), ("N", 0, 222),
                   ("HABEAS", -58, 166), ("DOCKET", 58, 166), ("CLAUSE & CO.", -132, -40), ("TORT TOWER", 118, -96),
                   ("PARALEGAL", -80, -142), ("AFFIDAVIT", 128, 40)):
    HI.label(C["BB_Labels"], lab, text, x, y, 5.5)
lab.done()

# ------------------------------------------------------------------ light, save, render
world, sun = K.sky_and_sun(scene, sun_energy=3.8, sun_rot=(52, 6, -40))
C["Lighting"].objects.link(sun)
K.setup_eevee(scene, samples=32)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "briefcase_bay.blend"), compress=True)
with open(os.path.join(HERE, "bb_layout.json"), "w") as fh:
    json.dump(LAYOUT, fh, indent=1)
print(f"[bb] saved; {len(spots)} egg spots")

CAMS = {
    "aerial": (("Cam_Aerial", (-250, -560, 400), (0, 0, -25), 34), 2400, 1350),
    "aerial_arena": (("Cam_Aerial_Arena", (-120, -40, 120), (0, 90, 5), 30), 2400, 1350),
    "ground_arrival": (("Cam_Ground_Arrival", (0, -172, 9), (0, -60, 14), 24), 1920, 1080),
    "ground_arena": (("Cam_Ground_Arena", (8, 0, 9), (0, 120, 20), 24), 1920, 1080),
    "ground_bay": (("Cam_Ground_Bay", (82, -60, 21), (114, -34, 2), 26), 1920, 1080),
    "cliff": (("Cam_Cliff", (330, -60, -40), (150, -40, -40), 30), 1920, 1080),
}
only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
if "norender" not in argv:
    for key, ((name, loc, look, lens), w, h) in CAMS.items():
        if only and key not in only:
            continue
        cam = K.camera(name, loc, look, lens=lens, collection=C["Presentation"])
        K.render(scene, cam, os.path.join(RENDERS, f"bb_{key}.jpg"), w, h, hide=("BB_Labels",))
    if not only or "layout" in only:
        cam = K.camera("Cam_TopDown_Layout", (0, 6, 1200), (0, 6, 0), ortho=520, collection=C["Presentation"])
        cam.rotation_euler = (0, 0, 0)
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
        world.color = (0.62, 0.78, 0.95)
        C["BB_Sky"].hide_render = True
        K.render(scene, cam, os.path.join(RENDERS, "bb_layout_topdown.jpg"), 1900, 2300)
