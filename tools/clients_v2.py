"""Clients v2: rebuilt in mr.robe's block style (the judges + lawyer skins in ReplicatedStorage), run in Blender.
exec(open("/Users/ryanchen/HatchLawyers/tools/clients_v2.py").read()); build_all(); export_all()

Recipe copied from SkinModels.KaiSueNat (feet at z = 0, front = -Y, character's LEFT = +x, RIGHT = -x):
chunky head 1.32 x 0.78 x 1.40 with a face built from flat blocks on the front (white eyes + pupils + shine,
angled brows, cheek line, mouth with teeth), block torso 1.44 wide, thin arms with cuffs + hands, thin legs
with chunky shoes. Flat colors only (Plastic look), sharp boxes, ~5.6 studs tall.

Each body part is ONE mesh named <Id>_<Part> with Part in Head / UpperTorso / LeftUpperArm / RightUpperArm /
LeftUpperLeg / RightUpperLeg, so Shared.Puppet sorts and animates them (held props live in the arm mesh).
"""
import bpy, bmesh, os, math
from mathutils import Vector, Matrix

OUT = "/Users/ryanchen/HatchLawyers/Models - Characters/Clients"
GRID, CELL = 16, 8
COLORS = {}


def col(rgb):
    if rgb not in COLORS:
        COLORS[rgb] = len(COLORS)
    return rgb


def cell_uv(rgb):
    i = COLORS[rgb]
    cx, cy = i % GRID, i // GRID
    return ((cx + 0.5) / GRID, 1 - (cy + 0.5) / GRID)


def palette_material():
    size = GRID * CELL
    px = [1.0] * (size * size * 4)
    for rgb, i in COLORS.items():
        cx, cy = i % GRID, i // GRID
        for y in range(CELL):
            for x in range(CELL):
                row = size - 1 - (cy * CELL + y)
                j = (row * size + cx * CELL + x) * 4
                px[j:j + 4] = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0]
    img = bpy.data.images.get("ClientPalette2")
    if img and img.size[0] != size:
        bpy.data.images.remove(img)
        img = None
    img = img or bpy.data.images.new("ClientPalette2", size, size, alpha=False)
    img.pixels = px
    img.filepath_raw = os.path.join(OUT, "ClientPalette2.png")
    img.file_format = "PNG"
    img.save()
    mat = bpy.data.materials.get("ClientPalette2") or bpy.data.materials.new("ClientPalette2")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    return mat


class Char:
    PARTS = ("Head", "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg")

    def __init__(self, cid):
        self.cid = cid
        self.boxes = {p: [] for p in self.PARTS}

    def box(self, part, c, s, rgb, rot_y=0.0, rot_x=0.0, rot_z=0.0):
        """c = centre (x, y, z), s = size (x, y, z); rot_* in degrees about the box centre."""
        self.boxes[part].append((Vector(c), Vector(s), col(rgb), rot_x, rot_y, rot_z))

    def build(self, coll, mat, offset_x):
        objs = []
        for part, boxes in self.boxes.items():
            if not boxes:
                continue
            bm = bmesh.new()
            uv = bm.loops.layers.uv.new("UVMap")
            for c, s, rgb, rx, ry, rz in boxes:
                geom = bmesh.ops.create_cube(bm, size=1.0)
                m = (Matrix.Translation(c) @ Matrix.Rotation(math.radians(rz), 4, "Z")
                     @ Matrix.Rotation(math.radians(ry), 4, "Y") @ Matrix.Rotation(math.radians(rx), 4, "X")
                     @ Matrix.Diagonal((s.x, s.y, s.z, 1)))
                bmesh.ops.transform(bm, matrix=m, verts=geom["verts"])
                u = cell_uv(rgb)
                for f in {f for v in geom["verts"] for f in v.link_faces}:
                    for loop in f.loops:
                        loop[uv].uv = u
            me = bpy.data.meshes.new(f"{self.cid}_{part}")
            bm.to_mesh(me)
            bm.free()
            me.materials.append(mat)
            o = bpy.data.objects.new(f"{self.cid}_{part}", me)
            o.location = (offset_x, 0, 0)
            coll.objects.link(o)
            objs.append(o)
        return objs


# ------------------------------------------------------------------------------------ shared body + face
WHITE = (245, 245, 245)
BLACK = (15, 15, 18)
MOUTH = (90, 20, 25)


def shade(rgb, k):
    return tuple(max(0, min(255, int(v * k))) for v in rgb)


def body(ch, skin, shirt, pants, shoes, cuff=None, sleeves=None, hands=None, legs_skin=False):
    sleeves = sleeves or shirt
    cuff = cuff or shade(sleeves, 0.8)
    hands = hands or skin
    for side, x in (("Left", 0.34), ("Right", -0.34)):
        leg = f"{side}UpperLeg"
        ch.box(leg, (x, -0.12, 0.12), (0.43, 0.74, 0.24), shoes)
        ch.box(leg, (x, 0, 1.25), (0.35, 0.43, 1.94), skin if legs_skin else pants)
    ch.box("UpperTorso", (0, 0, 3.0), (1.44, 0.90, 1.90), shirt)
    ch.box("UpperTorso", (0, 0, 3.92), (1.49, 0.95, 0.07), shade(shirt, 0.85))
    for side, x in (("Left", 0.89), ("Right", -0.89)):
        arm = f"{side}UpperArm"
        ch.box(arm, (x, 0, 3.08), (0.29, 0.31, 1.57), sleeves)
        ch.box(arm, (x, 0, 2.25), (0.29, 0.32, 0.10), cuff)
        ch.box(arm, (x, 0, 2.0), (0.25, 0.27, 0.41), hands)


def face(ch, skin, brow=(30, 18, 10), brow_tilt=8, mouth="smile", pupils=BLACK, head=None,
         head_size=(1.32, 0.78, 1.40), plate=True):
    hs = Vector(head_size)
    ch.box("Head", (0, 0, 3.91 + hs.z / 2), tuple(hs), head or skin)
    f = -hs.y / 2                                                     # front face of the head
    if plate:
        ch.box("Head", (0, f - 0.06, 4.60), (1.18, 0.04, 0.50), shade(skin, 1.12))
    for x, s in ((0.28, 1), (-0.28, -1)):
        ch.box("Head", (x, f - 0.09, 4.60), (0.43, 0.04, 0.41), WHITE)
        ch.box("Head", (x - 0.04 * s, f - 0.11, 4.58), (0.18, 0.04, 0.26), pupils)
        ch.box("Head", (x - 0.08 * s, f - 0.13, 4.66), (0.06, 0.02, 0.06), WHITE)
        if brow:
            ch.box("Head", (x + 0.01 * s, f - 0.11, 4.97), (0.43, 0.05, 0.08), brow, rot_y=-brow_tilt * s)
    ch.box("Head", (0, f - 0.07, 4.29), (0.96, 0.04, 0.10), shade(skin, 0.8))
    if mouth == "smile":
        ch.box("Head", (0, f - 0.07, 4.11), (0.43, 0.04, 0.14), MOUTH)
        ch.box("Head", (0, f - 0.08, 4.14), (0.38, 0.04, 0.06), WHITE)
    elif mouth == "o":
        ch.box("Head", (0, f - 0.07, 4.10), (0.22, 0.04, 0.2), MOUTH)
    elif mouth == "grin":
        ch.box("Head", (0, f - 0.07, 4.11), (0.62, 0.04, 0.16), MOUTH)
        ch.box("Head", (0, f - 0.08, 4.15), (0.56, 0.04, 0.07), WHITE)


def hair_cap(ch, rgb, top=5.31, front=-0.39, depth=0.85, width=1.39, fringe=True):
    ch.box("Head", (0, 0.02, top + 0.09), (width, depth, 0.19), rgb)
    ch.box("Head", (0, 0.42, top - 0.45), (width, 0.12, 1.0), rgb)                # back of the head
    for x in (0.68, -0.68):
        ch.box("Head", (x, 0.1, top - 0.25), (0.08, 0.6, 0.55), rgb)              # sideburns
    if fringe:
        for i, x in enumerate((0.48, 0.16, -0.17, -0.48)):
            ch.box("Head", (x, front - 0.02, top - 0.04 - 0.05 * (i % 2)), (0.29, 0.1, 0.16), rgb)


# ------------------------------------------------------------------------------------------- the 9
def neighbor_dave():
    ch = Char("NeighborDave")
    skin = (234, 184, 146)
    body(ch, skin, shirt=(64, 132, 224), pants=(196, 168, 112), shoes=(120, 76, 40), legs_skin=False)
    # khaki shorts: skin shins + white socks with sandals
    for x in (0.34, -0.34):
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, 0, 0.75), (0.36, 0.44, 0.95), skin)
        ch.box(f"{side}UpperLeg", (x, 0, 0.45), (0.37, 0.45, 0.35), WHITE)
    face(ch, skin, brow=(90, 56, 30))
    ch.box("Head", (0, -0.46, 4.21), (0.6, 0.05, 0.12), (90, 56, 30))            # dad mustache
    hair_cap(ch, (110, 70, 36))
    ch.box("UpperTorso", (0, -0.47, 3.82), (0.6, 0.05, 0.22), WHITE)              # polo collar
    ch.box("UpperTorso", (0, -0.47, 3.55), (0.12, 0.05, 0.4), shade((64, 132, 224), 0.75))
    # BBQ spatula in the right hand
    ch.box("RightUpperArm", (-0.89, -0.25, 1.95), (0.08, 0.6, 0.08), (60, 60, 66))
    ch.box("RightUpperArm", (-0.89, -0.65, 1.95), (0.3, 0.3, 0.04), (170, 176, 190))
    return ch


def grandma_pearl():
    ch = Char("GrandmaPearl")
    skin = (240, 200, 172)
    body(ch, skin, shirt=(180, 140, 220), pants=(232, 120, 170), shoes=(130, 80, 120), cuff=WHITE)
    for x in (0.34, -0.34):                                                       # skirt
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x * 1.15, 0, 1.75), (0.6, 0.62, 0.9), (232, 120, 170))
    face(ch, skin, brow=(200, 200, 205), brow_tilt=-6)
    for x in (0.28, -0.28):                                                       # round-ish glasses
        ch.box("Head", (x, -0.53, 4.84), (0.5, 0.03, 0.05), (200, 160, 40))
        ch.box("Head", (x, -0.53, 4.37), (0.5, 0.03, 0.05), (200, 160, 40))
    ch.box("Head", (0, -0.53, 4.62), (0.12, 0.03, 0.05), (200, 160, 40))
    hair_cap(ch, (232, 232, 238), fringe=False)
    for (x, z, s) in ((0, 5.62, 0.62), (0.3, 5.5, 0.4), (-0.3, 5.5, 0.4), (0, 5.9, 0.38)):   # curly bun
        ch.box("Head", (x, 0.12, z), (s, s, s), (238, 238, 244))
    for i in range(7):                                                            # pearl necklace
        a = (i - 3) * 0.17
        ch.box("UpperTorso", (a, -0.47, 3.82 - 0.05 * abs(i - 3) ** 1.5), (0.12, 0.08, 0.12), WHITE)
    for z in (3.5, 3.1, 2.7):
        ch.box("UpperTorso", (0, -0.47, z), (0.1, 0.04, 0.1), (240, 210, 120))   # cardigan buttons
    # cane
    ch.box("RightUpperArm", (-0.89, -0.05, 1.0), (0.12, 0.12, 2.0), (120, 70, 34))
    ch.box("RightUpperArm", (-0.89, -0.2, 2.02), (0.12, 0.42, 0.12), (120, 70, 34))
    return ch


def skater_kev():
    ch = Char("SkaterKev")
    skin = (198, 140, 100)
    green = (70, 190, 90)
    body(ch, skin, shirt=green, pants=(70, 100, 170), shoes=(235, 235, 235), cuff=shade(green, 0.75))
    ch.box("UpperTorso", (0, -0.47, 2.55), (0.9, 0.05, 0.45), shade(green, 0.8))   # hoodie pocket
    for x in (0.18, -0.18):
        ch.box("UpperTorso", (x, -0.47, 3.6), (0.05, 0.05, 0.45), WHITE)            # hoodie strings
    ch.box("UpperTorso", (0, 0.5, 3.75), (1.2, 0.1, 0.4), shade(green, 0.8))      # hood
    ch.box("UpperTorso", (0.4, -0.47, 3.25), (0.22, 0.04, 0.22), (255, 210, 50))  # sticker
    face(ch, skin, brow=(30, 20, 14), brow_tilt=-4, mouth="grin")
    red = (220, 50, 50)                                                           # backwards cap
    ch.box("Head", (0, 0, 5.42), (1.4, 0.86, 0.26), red)
    ch.box("Head", (0, 0.6, 5.33), (0.9, 0.5, 0.08), red)
    ch.box("Head", (0, 0.0, 5.58), (0.2, 0.2, 0.08), WHITE)
    for i, x in enumerate((0.48, 0.16, -0.17, -0.48)):
        ch.box("Head", (x, -0.41, 5.22 - 0.05 * (i % 2)), (0.29, 0.1, 0.18), (60, 36, 20))
    # skateboard under the left arm
    ch.box("LeftUpperArm", (1.15, 0, 2.4), (0.1, 0.7, 2.1), (240, 140, 40))
    ch.box("LeftUpperArm", (1.21, 0, 2.4), (0.04, 0.5, 1.9), (40, 40, 46))
    for z in (1.6, 3.2):
        ch.box("LeftUpperArm", (1.08, 0, z), (0.08, 0.6, 0.12), (170, 176, 190))
    return ch


def rosa_the_baker():
    ch = Char("RosaTheBaker")
    skin = (214, 160, 120)
    red = (210, 60, 60)
    body(ch, skin, shirt=red, pants=red, shoes=(90, 50, 30), cuff=WHITE)
    for x in (0.34, -0.34):                                                       # dress hem
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x * 1.15, 0, 1.8), (0.62, 0.62, 0.8), red)
    ch.box("UpperTorso", (0, -0.47, 2.6), (1.1, 0.05, 1.5), WHITE)                # apron
    ch.box("UpperTorso", (0, -0.48, 2.6), (0.6, 0.05, 0.3), (250, 220, 160))      # apron pocket (flour)
    face(ch, skin, brow=(40, 20, 14), brow_tilt=10, mouth="grin")
    ch.box("Head", (0.42, -0.45, 4.35), (0.2, 0.03, 0.12), (250, 245, 235))       # flour smudge
    hair_cap(ch, (50, 30, 22), fringe=False)
    # tall chef hat
    ch.box("Head", (0, 0, 5.5), (1.42, 0.88, 0.38), WHITE)
    ch.box("Head", (0, 0, 6.05), (1.2, 0.8, 0.75), WHITE)
    for x in (-0.35, 0, 0.35):
        ch.box("Head", (x, 0, 6.5), (0.45, 0.7, 0.3), (250, 250, 250))
    # rolling pin
    ch.box("RightUpperArm", (-0.89, -0.2, 1.95), (0.22, 1.2, 0.22), (230, 180, 120))
    for y in (0.5, -0.9):
        ch.box("RightUpperArm", (-0.89, y, 1.95), (0.1, 0.25, 0.1), (160, 100, 50))
    return ch


def captain_barnacle():
    ch = Char("CaptainBarnacle")
    skin = (232, 176, 140)
    navy = (36, 52, 110)
    body(ch, skin, shirt=navy, pants=navy, shoes=BLACK, cuff=(255, 200, 40))
    ch.box("UpperTorso", (0, -0.47, 3.0), (0.06, 0.05, 1.8), shade(navy, 0.8))
    for z in (3.5, 3.05, 2.6):
        for x in (0.28, -0.28):
            ch.box("UpperTorso", (x, -0.48, z), (0.12, 0.05, 0.12), (255, 200, 40))   # gold buttons
    face(ch, skin, brow=(240, 240, 240), brow_tilt=-10)
    beard = (244, 244, 248)
    ch.box("Head", (0, -0.43, 4.05), (1.3, 0.12, 0.5), beard)
    ch.box("Head", (0, -0.45, 3.8), (0.9, 0.16, 0.4), beard)
    ch.box("Head", (0, -0.46, 4.25), (0.7, 0.06, 0.1), beard)                    # mustache
    for x in (0.66, -0.66):
        ch.box("Head", (x, 0, 4.4), (0.08, 0.7, 0.8), beard)
    # captain's hat with a gold badge
    ch.box("Head", (0, 0, 5.42), (1.46, 0.9, 0.24), WHITE)
    ch.box("Head", (0, 0, 5.62), (1.56, 0.98, 0.18), WHITE)
    ch.box("Head", (0, -0.5, 5.34), (1.2, 0.3, 0.08), BLACK)                      # peak
    ch.box("Head", (0, -0.46, 5.43), (1.48, 0.05, 0.1), navy)
    ch.box("Head", (0, -0.5, 5.6), (0.26, 0.04, 0.22), (255, 200, 40))
    # fishing rod
    ch.box("RightUpperArm", (-0.89, -0.1, 2.6), (0.08, 0.08, 3.4), (120, 70, 34), rot_x=-25)
    ch.box("RightUpperArm", (-0.89, -0.12, 1.75), (0.16, 0.16, 0.25), (60, 60, 66))
    return ch


def dr_fizz():
    ch = Char("DrFizz")
    skin = (240, 204, 176)
    coat = (246, 246, 250)
    body(ch, skin, shirt=coat, pants=(80, 80, 96), shoes=(40, 40, 46), cuff=coat, sleeves=coat)
    ch.box("UpperTorso", (0, -0.47, 3.55), (0.5, 0.05, 0.7), (110, 200, 120))     # shirt under the coat
    ch.box("UpperTorso", (0, -0.48, 3.6), (0.14, 0.05, 0.6), (220, 60, 60))       # tie
    ch.box("UpperTorso", (0.42, -0.47, 3.4), (0.3, 0.05, 0.35), (230, 230, 236))  # pocket + pens
    ch.box("UpperTorso", (0.36, -0.49, 3.6), (0.05, 0.04, 0.2), (60, 120, 240))
    ch.box("UpperTorso", (0.46, -0.49, 3.6), (0.05, 0.04, 0.2), (220, 60, 60))
    for side, x in (("Left", 0.34), ("Right", -0.34)):                            # coat tails
        ch.box(f"{side}UpperLeg", (x * 1.4, 0.02, 1.75), (0.5, 0.9, 0.7), coat)
    face(ch, skin, brow=None, mouth="o")                                          # eyebrows singed off!
    # wild white hair spikes + goggles pushed up on the forehead
    hair = (236, 236, 240)
    ch.box("Head", (0, 0.05, 5.4), (1.36, 0.86, 0.2), hair)
    for (x, z, sx, sz, r) in ((0.55, 5.6, 0.35, 0.5, -25), (-0.55, 5.6, 0.35, 0.5, 25), (0.2, 5.7, 0.3, 0.6, -10),
                              (-0.2, 5.72, 0.3, 0.6, 12), (0.75, 5.1, 0.4, 0.3, -40), (-0.75, 5.1, 0.4, 0.3, 40)):
        ch.box("Head", (x, 0.1, z), (sx, 0.6, sz), hair, rot_y=r)
    ch.box("Head", (0, -0.42, 5.12), (1.36, 0.08, 0.14), (60, 60, 66))
    for x in (0.3, -0.3):
        ch.box("Head", (x, -0.46, 5.12), (0.38, 0.08, 0.3), (60, 60, 66))
        ch.box("Head", (x, -0.5, 5.12), (0.28, 0.04, 0.2), (120, 220, 255))
    # bubbling green flask
    ch.box("RightUpperArm", (-0.89, -0.3, 1.75), (0.34, 0.34, 0.4), (110, 240, 90))
    ch.box("RightUpperArm", (-0.89, -0.3, 2.05), (0.14, 0.14, 0.3), (200, 240, 255))
    ch.box("RightUpperArm", (-0.89, -0.3, 2.3), (0.12, 0.12, 0.12), (160, 255, 140))
    return ch


def tung_tung_sahur():
    ch = Char("TungTungSahur")
    wood = (176, 118, 68)
    dark = (124, 78, 40)
    # a living log: legs and arms are wood, the torso and head are one tall trunk
    for side, x in (("Left", 0.34), ("Right", -0.34)):
        leg = f"{side}UpperLeg"
        ch.box(leg, (x, -0.06, 0.12), (0.43, 0.6, 0.24), dark)
        ch.box(leg, (x, 0, 1.2), (0.35, 0.43, 1.9), wood)
    ch.box("UpperTorso", (0, 0, 3.0), (1.44, 0.95, 1.9), wood)
    for z in (2.3, 3.0, 3.7):
        ch.box("UpperTorso", (0, 0, z), (1.47, 0.98, 0.06), dark)                # bark rings
    for side, x in (("Left", 0.89), ("Right", -0.89)):
        arm = f"{side}UpperArm"
        ch.box(arm, (x, 0, 3.05), (0.29, 0.31, 1.6), wood)
        ch.box(arm, (x, 0, 2.05), (0.25, 0.27, 0.4), dark)
    face(ch, wood, brow=(60, 34, 16), brow_tilt=14, mouth="grin", head=wood, head_size=(1.44, 0.95, 1.6), plate=False)
    ch.box("Head", (0, 0, 5.56), (1.5, 1.0, 0.1), dark)                          # cut log top
    ch.box("Head", (0, 0, 5.6), (1.0, 0.7, 0.06), (220, 170, 110))
    # baseball bat
    ch.box("RightUpperArm", (-0.89, -0.15, 2.75), (0.16, 0.16, 1.6), (230, 196, 140), rot_x=-15)
    ch.box("RightUpperArm", (-0.89, -0.34, 3.5), (0.28, 0.28, 0.9), (230, 196, 140), rot_x=-15)
    return ch


def baron_von_banana():
    ch = Char("BaronVonBanana")
    fur = (120, 76, 44)
    muzzle = (230, 196, 150)
    purple = (110, 50, 160)
    body(ch, fur, shirt=purple, pants=BLACK, shoes=BLACK, cuff=WHITE, hands=muzzle)
    ch.box("UpperTorso", (0, -0.47, 3.45), (0.5, 0.05, 0.9), WHITE)               # shirt front
    ch.box("UpperTorso", (0, -0.49, 3.75), (0.4, 0.05, 0.14), BLACK)              # bow tie
    for z in (3.2, 2.85, 2.5):
        ch.box("UpperTorso", (0, -0.49, z), (0.1, 0.04, 0.1), (255, 200, 40))
    face(ch, muzzle, brow=(70, 40, 20), brow_tilt=-12, head=fur)
    ch.box("Head", (0, -0.45, 4.25), (0.9, 0.12, 0.55), muzzle)                  # monkey muzzle
    for x in (0.12, -0.12):
        ch.box("Head", (x, -0.52, 4.38), (0.08, 0.03, 0.08), (60, 36, 20))       # nostrils
    ch.box("Head", (0, -0.52, 4.13), (0.4, 0.03, 0.08), MOUTH)
    for x in (0.78, -0.78):                                                       # ears
        ch.box("Head", (x, 0, 4.65), (0.26, 0.2, 0.5), fur)
        ch.box("Head", (x * 1.03, -0.05, 4.65), (0.2, 0.12, 0.34), muzzle)
    # monocle on his left eye + top hat
    gold = (255, 200, 40)
    for (dx, dz, sx, sz) in ((0, 0.24, 0.52, 0.05), (0, -0.24, 0.52, 0.05), (0.24, 0, 0.05, 0.52), (-0.24, 0, 0.05, 0.52)):
        ch.box("Head", (0.28 + dx, -0.52, 4.6 + dz), (sx, 0.03, sz), gold)
    ch.box("Head", (0.5, -0.5, 4.1), (0.03, 0.03, 0.7), gold)
    ch.box("Head", (0, 0, 5.36), (1.7, 1.1, 0.1), BLACK)
    ch.box("Head", (0, 0, 5.9), (1.05, 0.8, 1.0), BLACK)
    ch.box("Head", (0, 0, 5.52), (1.07, 0.82, 0.18), purple)
    # banana
    for i, (y, z, r) in enumerate(((-0.25, 1.85, 30), (-0.5, 2.05, 10), (-0.65, 2.3, -15))):
        ch.box("RightUpperArm", (-0.89, y, z), (0.2, 0.24, 0.34), (255, 220, 60), rot_x=r)
    ch.box("RightUpperArm", (-0.89, -0.7, 2.5), (0.08, 0.08, 0.1), (100, 70, 30))
    return ch


def beep_bot():
    ch = Char("BeepBot")
    metal = (210, 216, 228)
    dark = (90, 96, 110)
    teal = (40, 200, 220)
    for side, x in (("Left", 0.34), ("Right", -0.34)):
        leg = f"{side}UpperLeg"
        ch.box(leg, (x, -0.05, 0.18), (0.5, 0.8, 0.36), dark)                    # treads
        ch.box(leg, (x, 0, 1.2), (0.36, 0.44, 1.7), metal)
        ch.box(leg, (x, -0.23, 1.2), (0.3, 0.04, 0.2), teal)
    ch.box("UpperTorso", (0, 0, 3.0), (1.5, 0.95, 1.9), metal)
    ch.box("UpperTorso", (0, -0.49, 3.1), (0.9, 0.05, 0.7), dark)                 # chest panel
    for i, c in enumerate(((240, 70, 70), (255, 210, 60), (80, 220, 110))):
        ch.box("UpperTorso", (-0.25 + i * 0.25, -0.52, 3.1), (0.15, 0.04, 0.15), c)
    ch.box("UpperTorso", (0, -0.49, 2.4), (1.0, 0.05, 0.12), (255, 160, 30))      # delivery stripe
    for side, x in (("Left", 0.89), ("Right", -0.89)):
        arm = f"{side}UpperArm"
        ch.box(arm, (x, 0, 3.05), (0.29, 0.31, 1.6), metal)
        ch.box(arm, (x, 0, 3.6), (0.36, 0.38, 0.36), dark)                        # shoulder joint
        ch.box(arm, (x, 0, 2.05), (0.3, 0.3, 0.4), dark)                          # claw hand
    # boxy head with a screen face: glowing eyes and a happy mouth, antenna with a red light
    ch.box("Head", (0, 0, 4.65), (1.4, 0.85, 1.4), metal)
    ch.box("Head", (0, -0.43, 4.62), (1.18, 0.04, 0.95), (20, 30, 44))
    for x in (0.28, -0.28):
        ch.box("Head", (x, -0.46, 4.75), (0.26, 0.03, 0.3), teal)
    ch.box("Head", (0, -0.46, 4.36), (0.5, 0.03, 0.08), teal)
    for x in (0.27, -0.27):
        ch.box("Head", (x * 1.0, -0.46, 4.42), (0.08, 0.03, 0.08), teal)
    for x in (0.74, -0.74):
        ch.box("Head", (x, 0, 4.65), (0.12, 0.4, 0.4), dark)                      # ear bolts
    ch.box("Head", (0, 0, 5.6), (0.08, 0.08, 0.5), dark)
    ch.box("Head", (0, 0, 5.9), (0.2, 0.2, 0.2), (240, 60, 60))
    # pizza box
    ch.box("RightUpperArm", (-0.89, -0.65, 1.95), (0.9, 0.9, 0.16), (220, 180, 120))
    ch.box("RightUpperArm", (-0.89, -0.65, 2.04), (0.5, 0.5, 0.02), (220, 60, 50))
    return ch


ROSTER = [neighbor_dave, grandma_pearl, skater_kev, rosa_the_baker, captain_barnacle, dr_fizz,
          tung_tung_sahur, baron_von_banana, beep_bot]


def build_all():
    coll = bpy.data.collections.get("ClientsV2")
    if coll:
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new("ClientsV2")
        bpy.context.scene.collection.children.link(coll)
    chars = [fn() for fn in ROSTER]          # register every color first
    mat = palette_material()
    for i, ch in enumerate(chars):
        ch.build(coll, mat, (i - 4) * 3.0)
    return coll


def export_all():
    coll = bpy.data.collections["ClientsV2"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in coll.objects:
        o.select_set(True)
    path = os.path.join(OUT, "ClientsV2.fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"},
                             path_mode="COPY", embed_textures=True, apply_scale_options="FBX_SCALE_ALL")
    return path
