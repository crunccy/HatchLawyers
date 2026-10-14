# tools/blender/floor_rooms.py - the UPSTAIRS ROOMS' sets (2026-10-13; mr.robe's call: the upper-floor ideas in
# docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md, everything but the Rooftop Helipad). Eight rooms, each built out of
# chunky blocks around its own origin (the floor's centre), rendered side by side for review, exported as JSON for
# tools/zones/BuildFloorRooms.lua (-> ServerStorage.Templates.FloorRooms.<Id>; ServerScriptService.FloorRooms stands
# them on the firm building's floors, Config.Floors.Slots).
# Each room fits its slot: about 12 x 10 studs (the courtroom 30 x 14) and under 8 studs tall (the floors are 9 apart).
# Its FRONT faces Blender +Y (= the street, Roblox -Z, once exported). Names the game uses: "Prompt" (invisible; gets
# the RoomPrompt with the "prompt" text), "VIPSeat" (where the VIP client stands), "Guestbook" (its "label" face shows
# the likes), "BoothLight1/2" (Moot Court booths). A block with a "label" gets that text on its "fn" face.
# Run: "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P tools/blender/floor_rooms.py
import bpy, math, json, os

def find_repo():
    env = os.environ.get("HATCH_REPO")
    if env:
        return env
    try:
        here = os.path.dirname(os.path.abspath(__file__))
        return os.path.abspath(os.path.join(here, "..", ".."))
    except NameError:
        return r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"

REPO = find_repo()
OUT_JSON = os.path.join(REPO, "tools", "zones", "floor_rooms.json")
OUT_PNG = os.path.join(REPO, "art", "floors", "rooms.png")

sc = bpy.data.scenes.get("FloorRooms") or bpy.data.scenes.new("FloorRooms")
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
coll = bpy.data.collections.get("FloorRooms") or bpy.data.collections.new("FloorRooms")
if coll.name not in sc.collection.children:
    sc.collection.children.link(coll)
me = bpy.data.meshes.get("FR_Cube")
if me is None:
    me = bpy.data.meshes.new("FR_Cube")
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(v, [], f)
    me.update()

def rgb(r, g, b):
    return (r, g, b)

P = dict(
    wood=rgb(176, 108, 52), woodL=rgb(214, 140, 70), woodD=rgb(122, 70, 34), white=rgb(246, 244, 236), cream=rgb(246, 226, 180),
    red=rgb(229, 57, 53), redD=rgb(160, 30, 40), gold=rgb(255, 200, 40), goldD=rgb(217, 154, 16), ink=rgb(30, 32, 46),
    navy=rgb(44, 52, 96), purple=rgb(150, 70, 210), purpleD=rgb(96, 40, 150), green=rgb(79, 203, 46), greenD=rgb(40, 130, 30),
    blue=rgb(60, 150, 240), sky=rgb(110, 210, 255), grey=rgb(150, 154, 170), black=rgb(40, 40, 48), leaf=rgb(70, 168, 34),
    pot=rgb(200, 100, 90), paper=rgb(250, 248, 236), lamp=rgb(255, 236, 150), screen=rgb(90, 200, 255), pink=rgb(255, 120, 170),
)
CLIENT_COLORS = [rgb(170, 175, 190), rgb(90, 200, 90), rgb(60, 150, 240), rgb(170, 80, 210), rgb(255, 160, 24), rgb(229, 57, 53),
                 rgb(255, 200, 40), rgb(90, 230, 255), rgb(255, 120, 200)]

ROOT = bpy.data.objects.new("FloorRooms", None)
coll.objects.link(ROOT)
OFFSET = {}  # room -> x offset in the preview scene (export subtracts it)

def make_room(room, offset):
    OFFSET[room] = offset
    def box(name, cx, cy, z0, sx, sy, sz, col, tag="", rz=0.0, prompt=None, label=None, fn=None):
        o = bpy.data.objects.new(name, me)
        o.scale = (sx, sy, sz)
        o.location = (cx + offset, cy, z0 + sz / 2)
        o.rotation_euler = (0, 0, math.radians(rz))
        o.color = (col[0] / 255, col[1] / 255, col[2] / 255, 1)
        o["rgb"] = list(col)
        o["tag"] = tag
        o["room"] = room
        o["prompt"] = prompt or ""
        o["label"] = label or ""
        o["fn"] = list(fn) if fn else []
        coll.objects.link(o)
        o.parent = ROOT
        return o
    return box

def plant(box, x, y):
    box("Pot", x, y, 0, 1.4, 1.4, 1.2, P["pot"])
    box("Leaves", x, y, 1.2, 1.8, 1.8, 1.6, P["leaf"])
    box("Leaves", x, y, 2.8, 1.1, 1.1, 0.9, P["green"])

def rope_posts(box, xs, y):
    for x in xs:
        box("RopePost", x, y, 0, 0.5, 0.5, 2.6, P["gold"])
        box("RopeCap", x, y, 2.6, 0.8, 0.8, 0.4, P["goldD"])
    for a, b in zip(xs[:-1], xs[1:]):
        box("Rope", (a + b) / 2, y, 2.0, abs(b - a) - 0.4, 0.3, 0.3, P["redD"])

# ------------------------------------------------------------------ 1. MAIL ROOM
b = make_room("MailRoom", 0)
b("Rug", 0, 0, 0, 11, 9, 0.1, P["red"])
b("Cubbies", 0, -4.2, 0, 10, 1.2, 6.4, P["woodL"])  # pigeonhole wall
for i in range(5):
    for k in range(4):
        x, z = -4 + i * 2, 0.8 + k * 1.4
        b("Cubby", x, -3.65, z, 1.6, 0.3, 1.1, P["woodD"])
        if (i + k) % 3 != 1:
            b("Envelope", x, -3.45, z + 0.2, 1.0, 0.2, 0.55, [P["paper"], P["sky"], P["pink"]][(i * 2 + k) % 3])
b("Table", 0, 0.3, 0, 6, 2.6, 2.6, P["wood"])
b("TableTop", 0, 0.3, 2.6, 6.4, 3.0, 0.4, P["woodL"])
for i, (x, h) in enumerate(((-2, 0.8), (-0.8, 0.5), (0.6, 1.1), (2, 0.6))):
    b("Letters", x, 0.3, 3.0, 1.0, 0.7, h, P["paper"] if i % 2 == 0 else P["cream"])
b("Stamp", 2.4, 1.1, 3.0, 0.5, 0.5, 0.7, P["red"])
b("Mailbox", -4.2, 2.6, 0, 1.6, 1.6, 3.4, P["red"])  # the big red mailbox
b("MailboxTop", -4.2, 2.6, 3.4, 1.8, 1.8, 0.6, P["redD"])
b("MailboxSlot", -4.2, 3.42, 2.7, 1.0, 0.1, 0.25, P["ink"])
b("MailboxFlag", -3.2, 2.6, 2.4, 0.2, 0.2, 1.4, P["gold"])
b("MailboxFlagTip", -3.0, 2.6, 3.5, 0.6, 0.15, 0.4, P["gold"])
plant(b, 4.4, 3.4)
b("Sign", 0, -3.5, 6.6, 6, 0.3, 1.3, P["red"], label="MAIL ROOM", fn=(0, 1, 0))
b("Prompt", 0, 2.4, 0, 4, 2.4, 4, P["white"], tag="prompt", prompt="Check Mail")

# ------------------------------------------------------------------ 2. HALL OF FAME
b = make_room("HallOfFame", 16)
b("Carpet", 0, 0.5, 0, 3, 9, 0.12, P["red"])
b("Floor", 0, 0, 0, 12, 10, 0.08, P["cream"])
b("Wall", 0, -4.6, 0, 12, 0.6, 7, P["navy"])
for row in range(3):
    for col in range(5):
        x, z = -4.6 + col * 2.3, 1.2 + row * 1.9
        b("Frame", x, -4.2, z, 1.9, 0.25, 1.6, P["gold"])
        b("Portrait", x, -4.05, z + 0.2, 1.4, 0.1, 1.2, CLIENT_COLORS[(row * 5 + col) % len(CLIENT_COLORS)])
b("Pedestal", 0, 1.2, 0, 1.8, 1.8, 2.8, P["white"])
b("PedestalTop", 0, 1.2, 2.8, 2.2, 2.2, 0.3, P["gold"])
b("Cup", 0, 1.2, 3.1, 0.6, 0.6, 0.8, P["gold"])
b("Cup", 0, 1.2, 3.9, 1.4, 1.4, 1.0, P["gold"])
b("CupHandle", -0.95, 1.2, 4.0, 0.3, 0.3, 0.8, P["goldD"])
b("CupHandle", 0.95, 1.2, 4.0, 0.3, 0.3, 0.8, P["goldD"])
rope_posts(b, [-5.5, -3, 3, 5.5], 2.5)
b("Sign", 0, -4.25, 6.4, 7, 0.2, 0.9, P["gold"], label="HALL OF FAME", fn=(0, 1, 0))
b("Prompt", 0, 3.2, 0, 4, 2.4, 4, P["white"], tag="prompt", prompt="View Hall of Fame")

# ------------------------------------------------------------------ 3. VIP LOUNGE
b = make_room("VIPLounge", 32)
b("Rug", 0, 0, 0, 9.5, 9, 0.12, P["purple"])
b("Wall", 0, -4.6, 0, 9.5, 0.5, 6.5, P["purpleD"])
b("VIPSign", 0, -4.3, 3.8, 4, 0.2, 1.8, P["ink"], label="VIP", fn=(0, 1, 0))
b("VIPSignGlow", 0, -4.35, 3.6, 4.4, 0.1, 2.2, P["gold"], tag="neon")
for x in (-2.6, 2.6):
    b("Chair", x, -1.6, 0, 2.6, 2.4, 1.4, P["purple"])
    b("ChairBack", x, -2.6, 1.4, 2.6, 0.6, 2.0, P["purple"])
    b("ChairArm", x - 1.15, -1.6, 1.4, 0.4, 2.4, 0.8, P["purpleD"])
    b("ChairArm", x + 1.15, -1.6, 1.4, 0.4, 2.4, 0.8, P["purpleD"])
    for dx in (-1, 1):
        for dy in (-0.9, 0.9):
            b("ChairLeg", x + dx * 1.0, -1.6 + dy, -0.0, 0.3, 0.3, 0.3, P["gold"])
b("VIPSeat", 2.6, -1.4, 1.4, 1.6, 1.6, 0.2, P["white"], tag="marker")
b("Table", 0, -0.6, 0, 1.6, 1.6, 2.0, P["gold"])
b("TableTop", 0, -0.6, 2.0, 2.2, 2.2, 0.3, P["white"])
b("Bell", 0, -0.6, 2.3, 0.7, 0.7, 0.5, P["gold"])
b("BellKnob", 0, -0.6, 2.8, 0.25, 0.25, 0.25, P["goldD"])
rope_posts(b, [-4.2, -1.6, 1.6, 4.2], 3.4)
b("Prompt", 0, 1.8, 0, 4, 3, 4, P["white"], tag="prompt", prompt="Greet VIP")

# ------------------------------------------------------------------ 4. MOOT COURT
b = make_room("MootCourt", 48)
b("Floor", 0, 0, 0, 12, 10, 0.1, P["woodL"])
b("BenchBase", 0, -3.6, 0, 6, 2, 3, P["woodD"])  # the judge's bench
b("BenchTop", 0, -3.6, 3.0, 6.4, 2.4, 0.4, P["wood"])
b("BenchPanel", 0, -2.55, 0.6, 4, 0.1, 1.8, P["gold"])
b("Gavel", 1.6, -3.4, 3.4, 1.0, 0.35, 0.35, P["woodD"])
b("GavelHead", 2.0, -3.4, 3.4, 0.4, 0.6, 0.6, P["woodD"])
for x in (-2.4, 2.4):  # two lecterns facing the bench
    b("Lectern", x, 0.4, 0, 1.4, 1.2, 3.2, P["wood"])
    b("LecternTop", x, 0.3, 3.2, 1.8, 1.6, 0.3, P["woodL"])
for i, x in enumerate((-5.0, 5.0)):  # practice booths: glass cubicles with a light
    box_y = -1.4
    b("BoothFrame", x, box_y, 0, 2.2, 3.2, 0.3, P["grey"])
    b("BoothGlass", x, box_y + 1.5, 0.3, 2.0, 0.15, 4.4, P["sky"], tag="glass")
    b("BoothGlass", x - 1.0 * (1 if x > 0 else -1), box_y, 0.3, 0.15, 3.0, 4.4, P["sky"], tag="glass")
    b("BoothTop", x, box_y, 4.7, 2.2, 3.2, 0.3, P["grey"])
    b("BoothLight%d" % (i + 1), x, box_y, 4.4, 1.0, 1.0, 0.3, P["lamp"], tag="neon")
    b("BoothStool", x, box_y - 0.4, 0.3, 0.9, 0.9, 1.6, P["red"])
b("AudienceBench", 0, 3.6, 0, 7, 1.2, 1.2, P["woodD"])
b("Sign", 0, -4.65, 4.6, 6, 0.2, 1.1, P["woodD"], label="MOOT COURT", fn=(0, 1, 0))
b("Prompt", 0, 2.0, 0, 4, 2.2, 4, P["white"], tag="prompt", prompt="Practise")

# ------------------------------------------------------------------ 5. CASE FILES ARCHIVE
b = make_room("CaseArchive", 64)
b("Floor", 0, 0, 0, 10, 10, 0.1, P["navy"])
for s, x in enumerate((-3.4, 0, 3.4)):  # three tall shelves of file boxes, a colour per client type
    b("Shelf", x, -3.9, 0, 3.2, 1.4, 6.8, P["woodD"])
    for k in range(4):
        b("ShelfBoard", x, -3.4, 0.4 + k * 1.6, 3.0, 0.5, 0.15, P["wood"])
        for j in range(3):
            b("FileBox", x - 1.0 + j * 1.0, -3.3, 0.55 + k * 1.6, 0.8, 0.6, 1.1, CLIENT_COLORS[(s * 3 + j + k) % len(CLIENT_COLORS)])
b("Ladder", 4.9, -3.0, 0, 0.3, 0.3, 6.5, P["woodL"])
b("Ladder", 4.9, -2.2, 0, 0.3, 0.3, 6.5, P["woodL"])
for k in range(5):
    b("Rung", 4.9, -2.6, 0.8 + k * 1.2, 0.25, 1.0, 0.2, P["woodL"])
b("Desk", -1.2, 1.4, 0, 4, 2, 2.6, P["wood"])
b("DeskTop", -1.2, 1.4, 2.6, 4.4, 2.4, 0.3, P["woodL"])
b("OpenFile", -1.6, 1.4, 2.9, 1.4, 1.0, 0.1, P["paper"])
b("Lamp", 0.3, 1.0, 2.9, 0.3, 0.3, 1.0, P["ink"])
b("LampShade", 0.3, 1.0, 3.8, 1.0, 0.7, 0.5, P["green"], tag="neon")
b("Chair", -1.2, 2.9, 0, 1.4, 1.2, 1.6, P["redD"])
b("Sign", 0, -3.15, 7.1, 6, 0.2, 0.7, P["blue"], label="CASE FILES", fn=(0, 1, 0))
b("Prompt", -1.2, 3.3, 0, 4, 2, 4, P["white"], tag="prompt", prompt="Read the Files")

# ------------------------------------------------------------------ 6. PARTNER'S OFFICE
b = make_room("PartnersOffice", 80)
b("Rug", 0, 0, 0, 9.5, 9, 0.12, P["navy"])
b("Wall", 0, -4.6, 0, 9.5, 0.5, 6.8, P["woodD"])
for i, x in enumerate((-3, 0, 3)):  # the wall of screens
    b("ScreenFrame", x, -4.25, 3.0, 2.6, 0.2, 1.8, P["black"])
    b("Screen", x, -4.13, 3.15, 2.3, 0.1, 1.5, P["screen"], tag="neon")
b("Desk", 0, -1.0, 0, 6, 2.4, 2.6, P["woodD"])
b("DeskTop", 0, -1.0, 2.6, 6.4, 2.8, 0.35, P["wood"])
b("DeskFront", 0, 0.25, 0.4, 5, 0.15, 1.8, P["gold"])
b("Nameplate", 1.6, -0.1, 2.95, 1.4, 0.3, 0.4, P["gold"], label="PARTNER", fn=(0, 1, 0))
b("ChairSeat", 0, -2.8, 0, 1.6, 1.6, 1.6, P["black"])
b("ChairBack", 0, -3.5, 1.6, 1.8, 0.4, 2.4, P["black"])
b("GlobeStand", -4.0, 2.4, 0, 0.4, 0.4, 2.2, P["woodD"])
b("Globe", -4.0, 2.4, 2.2, 1.4, 1.4, 1.4, P["blue"])
b("GlobeLand", -4.0, 2.2, 2.6, 0.8, 1.2, 0.6, P["green"])
plant(b, 4.2, 3.4)
b("Diploma", 3.6, -4.32, 5.2, 1.4, 0.1, 1.0, P["paper"])
b("Prompt", 0, 1.6, 0, 4, 2.4, 4, P["white"], tag="prompt", prompt="Set Rules")

# ------------------------------------------------------------------ 7. GUEST LOUNGE
b = make_room("GuestLounge", 96)
b("Rug", 0, 0, 0, 11, 9, 0.12, P["green"])
for y, face in ((-2.8, 1), (2.4, -1)):  # two sofas facing a coffee table
    b("Sofa", -1.5, y, 0, 6, 2.2, 1.4, P["sky"])
    b("SofaBack", -1.5, y - face * 0.9, 1.4, 6, 0.5, 1.6, P["sky"])
    for x in (-4.3, 1.3):
        b("SofaArm", x, y, 1.4, 0.5, 2.2, 0.8, P["blue"])
b("CoffeeTable", -1.5, -0.2, 0, 3, 1.6, 1.4, P["woodL"])
b("Mug", -2.2, -0.2, 1.4, 0.4, 0.4, 0.5, P["white"])
b("Book", -0.8, -0.2, 1.4, 0.9, 0.7, 0.2, P["red"])
b("BookStand", 4.4, 0.6, 0, 0.6, 0.6, 3.0, P["gold"])  # the guestbook on its stand
b("Guestbook", 4.4, 0.6, 3.0, 1.8, 1.4, 0.35, P["redD"], label="♥ 0", fn=(0, 1, 0))
b("FloorLamp", 4.4, -3.6, 0, 0.3, 0.3, 4.6, P["ink"])
b("FloorLampShade", 4.4, -3.6, 4.6, 1.2, 1.2, 0.8, P["lamp"], tag="neon")
plant(b, -5.0, -3.6)
b("Sign", -1.5, -4.4, 5.6, 6, 0.2, 1.0, P["green"], label="GUEST LOUNGE", fn=(0, 1, 0))
b("Prompt", 4.4, 2.2, 0, 2.6, 2.2, 4, P["white"], tag="prompt", prompt="Guestbook")

# ------------------------------------------------------------------ 8. PRIVATE COURTROOM (a whole tower floor)
b = make_room("PrivateCourtroom", 132)
b("Floor", 0, 0, 0, 30, 14, 0.1, P["woodL"])
b("BackWall", 0, -6.7, 0, 30, 0.6, 7.6, P["woodD"])
b("Seal", 0, -6.35, 3.6, 3.4, 0.2, 3.4, P["gold"])
b("SealInner", 0, -6.25, 4.1, 2.4, 0.1, 2.4, P["goldD"])
b("JudgeBase", 0, -5.0, 0, 8, 2.6, 2.2, P["woodD"])  # the judge's high bench (two steps)
b("JudgeBench", 0, -5.0, 2.2, 7, 2.2, 2.0, P["wood"])
b("JudgeTop", 0, -4.9, 4.2, 7.6, 2.6, 0.4, P["woodL"])
b("JudgeChair", 0, -5.9, 4.6, 1.8, 0.6, 2.6, P["redD"])
b("Gavel", 2.0, -4.6, 4.6, 1.0, 0.35, 0.35, P["woodD"])
b("WitnessStand", 7.5, -4.2, 0, 3, 2.4, 2.8, P["wood"])
b("WitnessTop", 7.5, -4.2, 2.8, 3.4, 2.8, 0.3, P["woodL"])
for row in range(2):  # the jury box
    b("JuryBench", -11, -3.8 + row * 2.2, row * 0.6, 6, 1.2, 1.2, P["woodD"])
    b("JuryBack", -11, -4.3 + row * 2.2, 1.2 + row * 0.6, 6, 0.3, 1.2, P["woodD"])
b("JuryRail", -11, -0.8, 0, 6.4, 0.4, 2.2, P["wood"])
for x in (-6, 6):  # the two lawyers' tables
    b("CounselTable", x, 1.8, 0, 6, 2.2, 2.6, P["wood"])
    b("CounselTop", x, 1.8, 2.6, 6.4, 2.6, 0.3, P["woodL"])
b("GalleryRail", 0, 4.6, 0, 26, 0.4, 2.4, P["wood"])
for x in range(-12, 13, 4):
    b("RailPost", x, 4.6, 0, 0.6, 0.6, 2.8, P["woodD"])
for x, col in ((-13.5, P["blue"]), (13.5, P["red"])):  # flags
    b("FlagPole", x, -6.0, 0, 0.3, 0.3, 7.4, P["gold"])
    b("Flag", x + (0.9 if x < 0 else -0.9), -6.0, 4.8, 1.6, 0.1, 2.2, col)
b("Sign", 0, -6.35, 6.6, 9, 0.2, 0.8, P["gold"], label="PRIVATE COURTROOM", fn=(0, 1, 0))
b("Prompt", 0, 5.8, 0, 6, 2.4, 4, P["white"], tag="prompt", prompt="Hold Court")

# ------------------------------------------------------------------ export (Roblox: Y up, -Z forward; offsets removed)
def to_rbx_vec(v):
    return [round(v[0], 3), round(v[2], 3), round(-v[1], 3)]

Mx = [[1, 0, 0], [0, 0, 1], [0, -1, 0]]
rooms = {}
for o in ROOT.children:
    room = o["room"]
    loc = o.location.copy()
    loc.x -= OFFSET[room]
    rot = o.rotation_euler.to_matrix()
    R3 = [[rot[i][j] for j in range(3)] for i in range(3)]
    MR = [[sum(Mx[i][k] * R3[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    Rr = [[sum(MR[i][k] * Mx[j][k] for k in range(3)) for j in range(3)] for i in range(3)]
    s = o.scale
    fn = list(o["fn"])
    rooms.setdefault(room, []).append(dict(
        n=o.name.split(".")[0], p=to_rbx_vec(loc), s=[round(abs(s[0]), 3), round(abs(s[2]), 3), round(abs(s[1]), 3)],
        r=[round(Rr[i][j], 5) for i in range(3) for j in range(3)], c=list(o["rgb"]), t=o["tag"],
        prompt=o["prompt"] or None, label=o["label"] or None, fn=to_rbx_vec(fn) if fn else None))
os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, "w") as fh:
    json.dump(dict(rooms=rooms), fh, separators=(",", ":"))

# ------------------------------------------------------------------ review render: all eight in a row
mats = {}
def material_for(o):
    key = (tuple(o["rgb"]), o["tag"])
    if key in mats:
        return mats[key]
    m = bpy.data.materials.new("FR_%d" % len(mats))
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = (o["rgb"][0] / 255, o["rgb"][1] / 255, o["rgb"][2] / 255, 1)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = 0.55
    if o["tag"] == "neon":
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = 1.5
    if o["tag"] == "glass":
        bsdf.inputs["Alpha"].default_value = 0.4
        m.surface_render_method = "BLENDED"
    mats[key] = m
    return m
if not me.materials:
    me.materials.append(None)
for o in ROOT.children:
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = material_for(o)
    if o["tag"] in ("prompt", "marker"):
        o.hide_render = True
sc.view_settings.view_transform = "Standard"
sc.render.engine = "BLENDER_EEVEE"
sc.eevee.taa_render_samples = 24
world = sc.world or bpy.data.worlds.new("FR_World")
sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.4, 0.42, 0.5, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
sun_data = bpy.data.lights.get("FR_Sun") or bpy.data.lights.new("FR_Sun", "SUN")
sun_data.energy = 2.6
sun = bpy.data.objects.new("FR_Sun", sun_data)
sun.rotation_euler = (math.radians(45), math.radians(10), math.radians(20))
coll.objects.link(sun)
cam_data = bpy.data.cameras.get("FR_Cam") or bpy.data.cameras.new("FR_Cam")
cam = bpy.data.objects.new("FR_Cam", cam_data)
coll.objects.link(cam)
sc.camera = cam
cam_data.type = "ORTHO"
cam_data.ortho_scale = 160
cam.location = (70, 70, 70)
cam.rotation_euler = (math.radians(55), 0, math.radians(180))
sc.render.resolution_x, sc.render.resolution_y = 2400, 900
sc.render.filepath = OUT_PNG
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.ops.render.render(write_still=True, scene=sc.name)
print("FloorRooms: %d rooms -> %s; render %s" % (len(rooms), OUT_JSON, OUT_PNG))
