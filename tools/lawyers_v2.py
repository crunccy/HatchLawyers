"""Lawyer skins v2: the 7 lawyers that were only recolors of the blocky NPC, rebuilt in mr.robe's block style
(same recipe as tools/clients_v2.py and SkinModels.KaiSueNat). Run inside Blender:
    exec(open("/Users/ryanchen/HatchLawyers/tools/lawyers_v2.py").read()); build_all(); export_rows()

build_all() lays them out in a "LawyersV2" collection for a look; export_rows() writes tools/lawyer_parts.json:
{ Id: [[part, x, y, z, sx, sy, sz, r00..r22 (9), r, g, b, neon], ...] } in ROBLOX space (X = -Blender x,
Y = Blender z, Z = Blender y; feet at Y = 0, facing -Z), which Studio turns into anchored Plastic Parts in
ReplicatedStorage.SkinModels.<Id> (like KaiSueNat). Part names: every box is named after its limb
(Head / UpperTorso / LeftUpperArm / ... ) so Shared.Puppet sorts it; extra head boxes are "HeadDetail" (sorted by
position into the head), and the head's main block is the only "Head".
"""
import importlib
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

TOOLS = "/Users/ryanchen/HatchLawyers/tools"
sys.path.insert(0, TOOLS)
import clients_v2 as cv  # noqa: E402

importlib.reload(cv)
Char, body, face, hair_cap, shade = cv.Char, cv.body, cv.face, cv.hair_cap, cv.shade
WHITE, BLACK, MOUTH = cv.WHITE, cv.BLACK, cv.MOUTH


class Lawyer(Char):
    """A Char that also remembers which colours are Neon in Roblox."""

    def __init__(self, cid):
        super().__init__(cid)
        self.neon = set()

    def glow(self, rgb):
        self.neon.add(cv.col(rgb))
        return rgb


# ------------------------------------------------------------------------------------- shared lawyer bits
def suit_front(ch, suit, tie, shirt=WHITE, bow=False, pocket=None):
    """White shirt V, tie (or bow tie), lapels and buttons on the torso front (front face y = -0.45)."""
    ch.box("UpperTorso", (0, -0.46, 3.5), (0.52, 0.04, 0.8), shirt)
    if bow:
        for x, r in ((0.17, 18), (-0.17, -18)):
            ch.box("UpperTorso", (x, -0.5, 3.78), (0.3, 0.06, 0.22), tie, rot_y=r)
        ch.box("UpperTorso", (0, -0.52, 3.78), (0.12, 0.06, 0.14), shade(tie, 0.8))
    else:
        ch.box("UpperTorso", (0, -0.49, 3.78), (0.22, 0.05, 0.16), shade(tie, 0.8))       # knot
        ch.box("UpperTorso", (0, -0.48, 3.33), (0.17, 0.04, 0.78), tie)
        ch.box("UpperTorso", (0, -0.48, 2.92), (0.11, 0.04, 0.1), tie)                  # tie tip
    lapel = shade(suit, 0.78)
    for x, r in ((0.31, 22), (-0.31, -22)):
        ch.box("UpperTorso", (x, -0.47, 3.45), (0.13, 0.04, 0.9), lapel, rot_y=r)
    for z in (2.85, 2.5):
        ch.box("UpperTorso", (0, -0.47, z), (0.1, 0.04, 0.1), shade(suit, 0.6))
    if pocket:
        ch.box("UpperTorso", (-0.45, -0.47, 3.35), (0.24, 0.04, 0.12), pocket)           # pocket square


def glasses(ch, rgb, lens=None, shades=False):
    f = -0.45
    if shades:
        ch.box("Head", (0, f - 0.12, 4.62), (1.22, 0.05, 0.38), rgb)
        if lens:
            ch.box("Head", (0, f - 0.15, 4.7), (1.1, 0.02, 0.06), lens)                  # shine line
        return
    for x in (0.28, -0.28):
        for dz in (0.24, -0.24):
            ch.box("Head", (x, f - 0.14, 4.6 + dz), (0.52, 0.03, 0.06), rgb)
        for dx in (0.24, -0.24):
            ch.box("Head", (x + dx, f - 0.14, 4.6), (0.06, 0.03, 0.52), rgb)
    ch.box("Head", (0, f - 0.14, 4.66), (0.12, 0.03, 0.05), rgb)


# ------------------------------------------------------------------------------------------- the 7
def rookie():
    ch = Lawyer("Rookie")
    skin, suit = (234, 190, 150), (44, 62, 96)
    body(ch, skin, shirt=suit, pants=(32, 32, 38), shoes=(70, 44, 26), cuff=WHITE)
    suit_front(ch, suit, (200, 40, 50))
    face(ch, skin, brow=(90, 56, 30), brow_tilt=-8)                       # eager, a little nervous
    hair_cap(ch, (110, 68, 36))
    ch.box("Head", (0.3, -0.41, 5.36), (0.5, 0.12, 0.2), (110, 68, 36), rot_y=-15)   # a cowlick
    ch.box("Head", (0.72, -0.2, 4.95), (0.06, 0.08, 0.18), (130, 210, 255))         # sweat drop
    # first-day briefcase
    case = (130, 80, 40)
    ch.box("RightUpperArm", (-0.89, -0.05, 1.45), (0.2, 0.85, 0.62), case)
    ch.box("RightUpperArm", (-0.89, -0.05, 1.8), (0.08, 0.3, 0.12), shade(case, 0.7))
    ch.box("RightUpperArm", (-0.89, -0.05, 1.5), (0.22, 0.12, 0.08), (255, 200, 40))
    return ch


def intern_suit():
    ch = Lawyer("InternSuit")
    skin, suit = (198, 140, 100), (170, 172, 186)
    body(ch, skin, shirt=suit, pants=(70, 72, 86), shoes=(40, 40, 46), cuff=WHITE)
    suit_front(ch, suit, (80, 140, 255))
    face(ch, skin, brow=(30, 22, 18), brow_tilt=-4, mouth="o")
    glasses(ch, (30, 30, 34))
    hair_cap(ch, (30, 24, 20))
    # lanyard + badge
    for x, r in ((0.2, -12), (-0.2, 12)):
        ch.box("UpperTorso", (x, -0.5, 3.5), (0.05, 0.03, 0.75), (60, 120, 230), rot_y=r)
    ch.box("UpperTorso", (0, -0.52, 3.0), (0.36, 0.04, 0.44), WHITE)
    ch.box("UpperTorso", (0, -0.54, 3.12), (0.36, 0.03, 0.12), (60, 120, 230))
    # coffee run
    ch.box("RightUpperArm", (-0.89, -0.25, 1.95), (0.3, 0.3, 0.42), WHITE)
    ch.box("RightUpperArm", (-0.89, -0.25, 1.95), (0.32, 0.32, 0.16), (150, 100, 60))
    ch.box("RightUpperArm", (-0.89, -0.25, 2.2), (0.34, 0.34, 0.08), (60, 60, 66))
    return ch


def casual_friday():
    ch = Lawyer("CasualFriday")
    skin, shirt = (240, 200, 170), (255, 140, 60)
    body(ch, skin, shirt=shirt, pants=(60, 90, 170), shoes=WHITE, cuff=shade(shirt, 0.8))
    for x in (0.34, -0.34):                                               # sneaker stripes
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.13, 0.12), (0.45, 0.5, 0.06), (230, 60, 60))
    # open collar + loosened tie hanging crooked
    ch.box("UpperTorso", (0, -0.46, 3.72), (0.6, 0.04, 0.28), WHITE)
    ch.box("UpperTorso", (0.06, -0.49, 3.62), (0.2, 0.05, 0.14), (230, 190, 60))
    ch.box("UpperTorso", (0.12, -0.48, 3.2), (0.16, 0.04, 0.75), (255, 220, 80), rot_y=-10)
    ch.box("UpperTorso", (-0.45, -0.47, 3.3), (0.3, 0.04, 0.3), shade(shirt, 0.82))   # chest pocket
    face(ch, skin, brow=(110, 70, 36), brow_tilt=-6, mouth="grin")
    hair_cap(ch, (150, 96, 50), fringe=False)
    red = (255, 80, 80)                                                   # baseball cap
    ch.box("Head", (0, 0, 5.42), (1.42, 0.88, 0.26), red)
    ch.box("Head", (0, -0.62, 5.33), (1.1, 0.5, 0.08), red)
    ch.box("Head", (0, -0.45, 5.45), (0.4, 0.03, 0.18), WHITE)
    # a donut, obviously
    ch.box("RightUpperArm", (-0.89, -0.3, 1.9), (0.55, 0.55, 0.16), (220, 160, 90))
    ch.box("RightUpperArm", (-0.89, -0.3, 1.99), (0.5, 0.5, 0.06), (255, 130, 190))
    ch.box("RightUpperArm", (-0.89, -0.3, 2.03), (0.16, 0.16, 0.04), (220, 160, 90))
    for x, y in ((-0.75, -0.18), (-1.0, -0.42), (-0.8, -0.45)):
        ch.box("RightUpperArm", (x, y, 2.03), (0.06, 0.1, 0.03), (90, 200, 255))
    return ch


def bow_tie_barrister():
    ch = Lawyer("BowTieBarrister")
    skin, suit = (240, 204, 176), (130, 70, 200)
    body(ch, skin, shirt=suit, pants=(55, 35, 90), shoes=BLACK, cuff=WHITE)
    suit_front(ch, suit, (255, 80, 170), bow=True, pocket=(255, 80, 170))
    face(ch, skin, brow=(200, 200, 205), brow_tilt=-12)                  # smug
    grey = (215, 215, 222)
    hair_cap(ch, grey, fringe=False)
    for x, r in ((0.25, -15), (-0.25, 15)):                               # handlebar mustache
        ch.box("Head", (x, -0.47, 4.27), (0.42, 0.06, 0.12), grey, rot_y=r)
    for x in (0.47, -0.47):
        ch.box("Head", (x, -0.47, 4.36), (0.1, 0.06, 0.14), grey)
    hat = (45, 35, 60)                                                    # top hat with a pink band
    ch.box("Head", (0, 0, 5.36), (1.75, 1.15, 0.1), hat)
    ch.box("Head", (0, 0, 5.95), (1.08, 0.82, 1.1), hat)
    ch.box("Head", (0, 0, 5.55), (1.1, 0.84, 0.2), (255, 80, 170))
    # legal scroll with a red seal
    ch.box("RightUpperArm", (-0.89, -0.3, 1.95), (0.24, 1.0, 0.24), (250, 240, 210))
    ch.box("RightUpperArm", (-0.89, -0.81, 1.95), (0.28, 0.06, 0.28), (210, 190, 150))
    ch.box("RightUpperArm", (-1.03, -0.3, 1.9), (0.04, 0.2, 0.2), (210, 40, 50))
    return ch


def navy_power_suit():
    ch = Lawyer("NavyPowerSuit")
    skin, suit = (160, 110, 80), (40, 75, 170)
    body(ch, skin, shirt=suit, pants=(25, 35, 85), shoes=BLACK, cuff=WHITE)
    suit_front(ch, suit, (235, 45, 60), pocket=(235, 45, 60))
    face(ch, skin, brow=(20, 16, 14), brow_tilt=10, mouth="grin")
    glasses(ch, (20, 20, 24), lens=(120, 130, 150), shades=True)
    hair = (22, 18, 16)                                                   # slicked back, side part
    ch.box("Head", (0, 0.04, 5.38), (1.4, 0.86, 0.16), hair)
    ch.box("Head", (0, 0.42, 4.88), (1.39, 0.12, 0.9), hair)
    for x in (0.68, -0.68):
        ch.box("Head", (x, 0.1, 5.05), (0.08, 0.6, 0.5), hair)
    ch.box("Head", (0.15, -0.3, 5.5), (1.05, 0.3, 0.14), hair, rot_y=-6)
    ch.box("Head", (0.3, -0.36, 5.46), (0.04, 0.3, 0.06), shade(skin, 0.9))     # the part
    ch.box("LeftUpperArm", (0.89, 0, 2.3), (0.31, 0.34, 0.12), (255, 200, 40))  # gold watch
    # phone, always on a call
    ch.box("RightUpperArm", (-0.89, -0.22, 2.0), (0.12, 0.26, 0.48), (20, 20, 24))
    ch.box("RightUpperArm", (-0.95, -0.22, 2.0), (0.02, 0.22, 0.4), (90, 180, 255))
    return ch


def golden_gavel():
    ch = Lawyer("GoldenGavel")
    skin, suit = (234, 184, 146), (255, 200, 40)
    gold = (255, 215, 60)
    body(ch, skin, shirt=suit, pants=(170, 115, 20), shoes=WHITE, cuff=WHITE)
    suit_front(ch, suit, WHITE, pocket=(230, 60, 60))
    for z in (3.0, 2.7):                                                  # gold chain
        ch.box("UpperTorso", (0.3, -0.48, z + 0.1), (0.04, 0.03, 0.2), shade(gold, 0.8))
    face(ch, skin, brow=(150, 90, 30), brow_tilt=-6, mouth="grin")
    hair_cap(ch, (230, 170, 60))
    # crown with ruby gems
    ch.box("Head", (0, 0, 5.5), (1.5, 0.94, 0.36), gold)
    for x in (-0.55, 0, 0.55):
        for y in (-0.36, 0.36):
            ch.box("Head", (x, y, 5.86), (0.28, 0.2, 0.42), gold)
    for x in (-0.4, 0.4):
        ch.box("Head", (x, -0.48, 5.5), (0.18, 0.03, 0.18), ch.glow((230, 30, 60)))
    ch.box("Head", (0, -0.48, 5.52), (0.24, 0.03, 0.24), ch.glow((40, 160, 255)))
    # the golden gavel, held upright with its head pointing forward
    ch.box("RightUpperArm", (-0.89, -0.22, 2.45), (0.14, 0.14, 1.2), (130, 80, 30))
    ch.box("RightUpperArm", (-0.89, -0.22, 3.2), (0.42, 0.95, 0.42), gold)
    for y in (-0.72, 0.28):
        ch.box("RightUpperArm", (-0.89, y, 3.2), (0.46, 0.08, 0.46), shade(gold, 0.8))
    return ch


def neon_litigator():
    ch = Lawyer("NeonLitigator")
    skin, suit = (200, 150, 110), (35, 35, 48)
    neon = ch.glow((0, 255, 200))
    body(ch, skin, shirt=suit, pants=(20, 20, 30), shoes=(25, 25, 32), cuff=neon)
    for x in (0.34, -0.34):                                               # glowing soles
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.12, 0.02), (0.45, 0.76, 0.05), neon)
        ch.box(f"{side}UpperLeg", (x, -0.23, 1.25), (0.05, 0.03, 1.7), neon)    # trouser stripe
    suit_front(ch, suit, neon, shirt=(25, 25, 32))
    for x, r in ((0.38, 22), (-0.38, -22)):
        ch.box("UpperTorso", (x, -0.48, 3.45), (0.04, 0.03, 0.9), neon, rot_y=r)  # lit lapel edges
    ch.box("UpperTorso", (0, 0, 3.94), (1.5, 0.96, 0.05), neon)
    face(ch, skin, brow=(20, 20, 26), brow_tilt=12, mouth="smile")
    glasses(ch, neon, shades=True)
    hair = (20, 20, 28)                                                   # spiky, neon tips
    ch.box("Head", (0, 0.05, 5.4), (1.38, 0.86, 0.2), hair)
    for x, h in ((0.45, 0.36), (0.0, 0.5), (-0.45, 0.36)):
        ch.box("Head", (x, 0.0, 5.5 + h / 2), (0.34, 0.6, h), hair)
        ch.box("Head", (x, 0.0, 5.5 + h + 0.06), (0.3, 0.5, 0.12), neon)
    ch.box("Head", (0, 0.42, 4.88), (1.39, 0.12, 0.9), hair)
    # glowing tablet
    ch.box("RightUpperArm", (-0.89, -0.4, 1.95), (0.08, 0.7, 0.9), (30, 30, 40), rot_x=-15)
    ch.box("RightUpperArm", (-0.94, -0.4, 1.95), (0.02, 0.6, 0.78), neon, rot_x=-15)
    return ch


ROSTER = [rookie, intern_suit, casual_friday, bow_tie_barrister, navy_power_suit, golden_gavel, neon_litigator]


# ------------------------------------------------------- everyone else who was still the blocky NPC
# The Manager (ServerStorage.Templates.Manager) and the Epic / Legendary clients (ServerStorage.Templates.Clients,
# Config.ClientCharacters tiers 4..9). Same recipe; exported to the same JSON.
def manager():
    ch = Lawyer("Manager")
    skin, vest = (226, 176, 136), (40, 120, 80)
    body(ch, skin, shirt=WHITE, pants=(60, 62, 74), shoes=(70, 44, 26), sleeves=WHITE, cuff=(225, 225, 230))
    ch.box("UpperTorso", (0, 0, 2.95), (1.48, 0.94, 1.6), vest)              # vest over a white shirt
    ch.box("UpperTorso", (0, -0.48, 3.45), (0.5, 0.04, 0.6), WHITE)
    ch.box("UpperTorso", (0, -0.5, 3.75), (0.2, 0.05, 0.14), (160, 30, 40))
    ch.box("UpperTorso", (0, -0.5, 3.35), (0.15, 0.04, 0.65), (200, 40, 50))
    for z in (3.0, 2.7, 2.4):
        ch.box("UpperTorso", (0, -0.49, z), (0.1, 0.04, 0.1), (255, 200, 40))
    for x in (0.89, -0.89):                                               # rolled-up sleeves
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperArm", (x, 0, 2.55), (0.31, 0.33, 0.18), (225, 225, 230))
        ch.box(f"{side}UpperArm", (x, 0, 2.3), (0.27, 0.29, 0.3), skin)
    face(ch, skin, brow=(110, 110, 116), brow_tilt=-4, mouth="grin")
    glasses(ch, (120, 70, 30))
    hair_cap(ch, (90, 90, 96), fringe=False)
    for x in (0.66, -0.66):
        ch.box("Head", (x, 0.05, 5.05), (0.1, 0.7, 0.6), (190, 190, 196))   # grey temples
    # clipboard
    ch.box("RightUpperArm", (-0.89, -0.32, 1.95), (0.06, 0.62, 0.8), (150, 100, 50))
    ch.box("RightUpperArm", (-0.93, -0.32, 1.92), (0.02, 0.52, 0.62), WHITE)
    ch.box("RightUpperArm", (-0.93, -0.32, 2.3), (0.04, 0.22, 0.08), (170, 176, 190))
    return ch


def retired_ceo():
    ch = Lawyer("RetiredCEO")
    skin, jacket = (236, 196, 166), (120, 30, 50)
    gold = (255, 200, 40)
    body(ch, skin, shirt=jacket, pants=(40, 34, 40), shoes=BLACK, cuff=gold)
    ch.box("UpperTorso", (0, -0.46, 3.5), (0.5, 0.04, 0.75), WHITE)
    ch.box("UpperTorso", (0, -0.49, 3.75), (0.36, 0.06, 0.14), gold)          # gold cravat
    ch.box("UpperTorso", (0, -0.49, 3.55), (0.18, 0.05, 0.3), gold)
    for x, r in ((0.31, 22), (-0.31, -22)):
        ch.box("UpperTorso", (x, -0.47, 3.4), (0.16, 0.04, 1.0), shade(jacket, 0.7), rot_y=r)   # velvet lapels
    for z in (2.9, 2.55):
        for x in (0.22, -0.22):
            ch.box("UpperTorso", (x, -0.48, z), (0.1, 0.04, 0.1), gold)
    ch.box("UpperTorso", (-0.42, -0.48, 2.75), (0.3, 0.04, 0.04), gold)       # watch chain
    face(ch, skin, brow=(240, 240, 244), brow_tilt=-10)
    white = (244, 244, 248)
    ch.box("Head", (0, 0, 5.33), (1.33, 0.79, 0.04), shade(skin, 1.05))       # shiny bald top
    for x in (0.68, -0.68):
        ch.box("Head", (x, 0.1, 4.95), (0.14, 0.62, 0.6), white)              # side tufts
    ch.box("Head", (0, 0.42, 4.85), (1.39, 0.12, 0.6), white)
    for x, r in ((0.24, -12), (-0.24, 12)):                               # walrus mustache
        ch.box("Head", (x, -0.47, 4.22), (0.46, 0.08, 0.2), white, rot_y=r)
    # gold-topped cane
    ch.box("RightUpperArm", (-0.89, -0.05, 1.0), (0.12, 0.12, 2.0), (40, 30, 30))
    ch.box("RightUpperArm", (-0.89, -0.05, 2.08), (0.22, 0.22, 0.22), gold)
    return ch


def chef_mega():
    ch = Lawyer("ChefMega")
    skin, whites = (214, 160, 120), (246, 246, 250)
    body(ch, skin, shirt=whites, pants=(40, 40, 46), shoes=BLACK, cuff=whites, sleeves=whites)
    for z in (3.4, 3.0, 2.6):
        for x in (0.25, -0.25):
            ch.box("UpperTorso", (x, -0.47, z), (0.11, 0.04, 0.11), (40, 40, 46))     # double-breasted
    ch.box("UpperTorso", (0, -0.47, 3.8), (0.7, 0.06, 0.2), (220, 40, 40))           # neckerchief
    ch.box("UpperTorso", (0, -0.48, 3.62), (0.24, 0.05, 0.24), (220, 40, 40))
    ch.box("UpperTorso", (0.45, -0.47, 3.35), (0.24, 0.04, 0.24), ch.glow((255, 210, 40)))  # star badge
    face(ch, skin, brow=(30, 20, 14), brow_tilt=12, mouth="grin")
    for x, r in ((0.27, -18), (-0.27, 18)):                               # big curled mustache
        ch.box("Head", (x, -0.47, 4.26), (0.5, 0.08, 0.16), (30, 20, 14), rot_y=r)
    hair_cap(ch, (30, 20, 14), fringe=False)
    ch.box("Head", (0, 0, 5.5), (1.44, 0.9, 0.36), whites)                # MEGA chef hat with a gold band
    ch.box("Head", (0, 0, 5.56), (1.46, 0.92, 0.12), (255, 200, 40))
    ch.box("Head", (0, 0, 6.25), (1.3, 0.86, 1.1), whites)
    for x in (-0.42, 0, 0.42):
        ch.box("Head", (x, 0, 6.88), (0.55, 0.8, 0.36), (252, 252, 255))
    # giant golden ladle
    ch.box("RightUpperArm", (-0.89, -0.2, 2.5), (0.1, 0.1, 1.3), (200, 205, 215))
    ch.box("RightUpperArm", (-0.89, -0.3, 3.2), (0.42, 0.42, 0.24), (255, 200, 40))
    return ch


def rocket_baron_rex():
    ch = Lawyer("RocketBaronRex")
    skin, suit = (230, 186, 150), (205, 210, 222)
    orange = (255, 130, 30)
    body(ch, skin, shirt=suit, pants=suit, shoes=(60, 64, 76), cuff=orange)
    ch.box("UpperTorso", (0, -0.47, 3.0), (0.08, 0.04, 1.8), (120, 126, 140))       # zip
    for x in (0.34, -0.34):
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.23, 1.3), (0.06, 0.03, 1.8), orange)        # racing stripes
    ch.box("UpperTorso", (0.42, -0.47, 3.4), (0.3, 0.04, 0.3), (40, 80, 200))       # mission patch
    ch.box("UpperTorso", (0.42, -0.49, 3.4), (0.14, 0.03, 0.14), ch.glow(orange))
    ch.box("UpperTorso", (0, -0.47, 3.85), (0.9, 0.06, 0.16), orange)                # collar ring
    face(ch, skin, brow=(60, 40, 24), brow_tilt=10, mouth="grin")
    hair = (60, 40, 24)
    ch.box("Head", (0, 0.04, 5.38), (1.4, 0.86, 0.16), hair)
    ch.box("Head", (0, 0.42, 4.88), (1.39, 0.12, 0.9), hair)
    ch.box("Head", (0, -0.25, 5.52), (1.2, 0.4, 0.2), hair, rot_x=-10)            # big swoosh
    ch.box("Head", (0, -0.43, 5.12), (1.36, 0.06, 0.16), (60, 60, 66))             # goggles on the forehead
    for x in (0.3, -0.3):
        ch.box("Head", (x, -0.46, 5.12), (0.4, 0.06, 0.3), (60, 60, 66))
        ch.box("Head", (x, -0.5, 5.12), (0.3, 0.03, 0.2), (255, 170, 60))
    # toy rocket
    ch.box("RightUpperArm", (-0.89, -0.25, 2.35), (0.28, 0.28, 0.9), WHITE)
    ch.box("RightUpperArm", (-0.89, -0.25, 2.88), (0.18, 0.18, 0.18), (230, 50, 50))
    ch.box("RightUpperArm", (-0.89, -0.25, 1.85), (0.4, 0.12, 0.18), (230, 50, 50))
    ch.box("RightUpperArm", (-0.89, -0.25, 1.7), (0.16, 0.16, 0.16), ch.glow(orange))
    return ch


def milo_vex():
    ch = Lawyer("MiloVex")
    skin, blazer = (150, 100, 70), (255, 80, 160)
    body(ch, skin, shirt=blazer, pants=(110, 60, 190), shoes=WHITE, cuff=(255, 220, 240))
    ch.box("UpperTorso", (0, -0.46, 3.45), (0.56, 0.04, 0.9), BLACK)               # black tee
    for x, r in ((0.32, 22), (-0.32, -22)):
        ch.box("UpperTorso", (x, -0.47, 3.4), (0.15, 0.04, 1.0), shade(blazer, 0.78), rot_y=r)
    ch.box("UpperTorso", (0, -0.49, 3.3), (0.36, 0.03, 0.36), ch.glow((255, 220, 60)))   # logo
    face(ch, skin, brow=(30, 20, 14), brow_tilt=6, mouth="smile")
    glasses(ch, (255, 80, 160), shades=True)
    for x in (0.28, -0.28):
        ch.box("Head", (x, -0.61, 4.62), (0.48, 0.02, 0.28), (40, 40, 60))         # tinted lenses
    blond = (255, 225, 120)                                               # tall swoopy hair
    ch.box("Head", (0, 0.04, 5.38), (1.4, 0.86, 0.16), blond)
    ch.box("Head", (0, 0.42, 4.95), (1.39, 0.12, 0.8), blond)
    ch.box("Head", (0.1, -0.1, 5.65), (1.2, 0.7, 0.4), blond, rot_y=-8)
    ch.box("Head", (0.35, -0.3, 5.9), (0.7, 0.5, 0.3), blond, rot_y=-20)
    # shopping bags
    for y, c in ((-0.15, (255, 210, 60)), (0.2, (60, 200, 255))):
        ch.box("RightUpperArm", (-0.95, y, 1.45), (0.18, 0.38, 0.55), c)
        ch.box("RightUpperArm", (-0.95, y, 1.78), (0.04, 0.24, 0.12), BLACK)
    return ch


def dj_beatbox():
    ch = Lawyer("DJBeatbox")
    skin, hoodie = (110, 74, 52), (30, 30, 40)
    neon = ch.glow((255, 60, 220))
    body(ch, skin, shirt=hoodie, pants=(40, 40, 52), shoes=WHITE, cuff=neon)
    ch.box("UpperTorso", (0, -0.47, 2.55), (0.9, 0.05, 0.45), shade(hoodie, 1.3))    # pocket
    for z in (3.4, 3.0):
        ch.box("UpperTorso", (0, -0.47, z), (1.2, 0.04, 0.06), neon)                 # glowing stripes
    ch.box("UpperTorso", (0, 0.5, 3.75), (1.2, 0.1, 0.4), shade(hoodie, 1.3))
    for i in range(5):                                                    # gold chain + record medallion
        a = (i - 2) * 0.17
        ch.box("UpperTorso", (a, -0.48, 3.75 - 0.06 * abs(i - 2) ** 1.5), (0.12, 0.06, 0.08), (255, 200, 40))
    ch.box("UpperTorso", (0, -0.5, 3.35), (0.3, 0.04, 0.3), (255, 200, 40))
    face(ch, skin, brow=(20, 16, 14), brow_tilt=-6, mouth="grin")
    cap = (20, 20, 26)
    ch.box("Head", (0, 0, 5.42), (1.42, 0.88, 0.26), cap)
    ch.box("Head", (0, -0.62, 5.33), (1.1, 0.5, 0.08), cap)
    ch.box("Head", (0, -0.45, 5.45), (0.4, 0.03, 0.18), neon)
    # big headphones
    ch.box("Head", (0, 0, 5.6), (1.6, 0.2, 0.12), (60, 60, 70))
    for x in (0.74, -0.74):
        ch.box("Head", (x, 0, 4.75), (0.2, 0.5, 0.6), (60, 60, 70))
        ch.box("Head", (x * 1.05, 0, 4.75), (0.14, 0.36, 0.44), neon)
        ch.box("Head", (x, 0, 5.2), (0.12, 0.12, 0.5), (60, 60, 70))
    # vinyl record
    ch.box("RightUpperArm", (-0.89, -0.35, 1.95), (0.06, 0.8, 0.8), (20, 20, 24))
    ch.box("RightUpperArm", (-0.93, -0.35, 1.95), (0.02, 0.26, 0.26), neon)
    return ch


def kiki_glow():
    ch = Lawyer("KikiGlow")
    skin, dress = (240, 200, 172), (190, 140, 250)
    body(ch, skin, shirt=dress, pants=skin, shoes=(255, 120, 200), cuff=(255, 200, 240))
    for x in (0.34, -0.34):                                               # sparkly dress
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x * 1.15, 0, 1.75), (0.62, 0.64, 0.9), dress)
    for (x, z) in ((0.3, 3.4), (-0.4, 3.0), (0.1, 2.6), (-0.15, 3.6), (0.45, 2.85)):
        ch.box("UpperTorso", (x, -0.47, z), (0.1, 0.03, 0.1), ch.glow((255, 250, 255)))
    face(ch, skin, brow=(200, 80, 140), brow_tilt=-4, mouth="smile")
    for x in (0.28, -0.28):                                               # lashes + blush
        ch.box("Head", (x, -0.53, 4.84), (0.46, 0.03, 0.06), BLACK)
        ch.box("Head", (x * 1.6, -0.48, 4.32), (0.2, 0.03, 0.1), (255, 150, 170))
    pink = (255, 120, 190)                                                # long pink hair
    hair_cap(ch, pink, fringe=True)
    ch.box("Head", (0, 0.42, 4.4), (1.42, 0.16, 1.9), pink)
    for x in (0.7, -0.7):
        ch.box("Head", (x, 0.05, 4.4), (0.12, 0.7, 1.6), pink)
    for x in (-0.4, 0, 0.4):                                              # tiara
        ch.box("Head", (x, -0.3, 5.5 + (0.1 if x == 0 else 0)), (0.16, 0.06, 0.3), ch.glow((180, 240, 255)))
    ch.box("Head", (0, -0.3, 5.4), (1.0, 0.06, 0.08), (230, 230, 240))
    # hand mirror
    ch.box("RightUpperArm", (-0.89, -0.3, 2.25), (0.06, 0.5, 0.6), (255, 200, 40))
    ch.box("RightUpperArm", (-0.93, -0.3, 2.25), (0.02, 0.4, 0.5), (200, 240, 255))
    ch.box("RightUpperArm", (-0.89, -0.3, 1.8), (0.08, 0.1, 0.4), (255, 200, 40))
    return ch


OTHERS = [manager, retired_ceo, chef_mega, rocket_baron_rex, milo_vex, dj_beatbox, kiki_glow]


def preview_material():
    """Palette texture for the Blender preview only (Roblox gets plain coloured Parts, no texture). Kept apart
    from the clients' ClientPalette2 so their exported texture never changes."""
    size = cv.GRID * cv.CELL
    px = [1.0] * (size * size * 4)
    for rgb, i in cv.COLORS.items():
        cx, cy = i % cv.GRID, i // cv.GRID
        for y in range(cv.CELL):
            for x in range(cv.CELL):
                row = size - 1 - (cy * cv.CELL + y)
                j = (row * size + cx * cv.CELL + x) * 4
                px[j:j + 4] = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0]
    img = bpy.data.images.get("LawyerPalette2") or bpy.data.images.new("LawyerPalette2", size, size, alpha=False)
    img.pixels = px
    mat = bpy.data.materials.get("LawyerPalette2") or bpy.data.materials.new("LawyerPalette2")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    return mat


def build_all():
    coll = bpy.data.collections.get("LawyersV2")
    if coll:
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new("LawyersV2")
        bpy.context.scene.collection.children.link(coll)
    chars = [fn() for fn in ROSTER + OTHERS]
    mat = preview_material()
    for i, ch in enumerate(chars):
        ch.build(coll, mat, (i - 7) * 3.0)
    return coll


# Roblox space = M @ Blender space, M maps (x, y, z) -> (-x, z, y) (det +1, a proper rotation)
M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def export_rows():
    out = {}
    for fn in ROSTER + OTHERS:
        ch = fn()
        rows, head_done = [], False
        for part, boxes in ch.boxes.items():
            for c, s, rgb, rx, ry, rz in boxes:
                rot_b = (Matrix.Rotation(math.radians(rz), 3, "Z") @ Matrix.Rotation(math.radians(ry), 3, "Y")
                         @ Matrix.Rotation(math.radians(rx), 3, "X"))
                rot_r = M @ rot_b @ M.transposed()
                pos = M @ Vector(c)
                name = part
                if part == "Head":
                    name = "Head" if not head_done else "HeadDetail"   # the first head box is the skull
                    head_done = True
                rows.append([name, round(pos.x, 4), round(pos.y, 4), round(pos.z, 4),
                             round(s.x, 4), round(s.z, 4), round(s.y, 4)]
                            + [round(rot_r[i][j], 5) for i in range(3) for j in range(3)]
                            + list(rgb) + [1 if rgb in ch.neon else 0])
        out[ch.cid] = rows
    path = os.path.join(TOOLS, "lawyer_parts.json")
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return {k: len(v) for k, v in out.items()}
