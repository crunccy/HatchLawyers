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


# ------------------------------------------------------------------ brainrot lawyers (hatchable, 2026-10-09)
# Parodies of the Italian-brainrot memes, each in lawyer gear. Not humanoid underneath, but every box still sits
# in one of the 6 limb groups (Head / UpperTorso / arms / legs) so Shared.Puppet can walk and animate them.
def eye(ch, x, y, z, size=0.34, pupil=BLACK, white=WHITE, part="Head"):
    """A block eye facing -y at (x, y, z): white, pupil, shine."""
    ch.box(part, (x, y, z), (size, 0.05, size), white)
    ch.box(part, (x * 0.96, y - 0.03, z - 0.02), (size * 0.48, 0.04, size * 0.62), pupil)
    ch.box(part, (x * 0.9, y - 0.05, z + size * 0.15), (size * 0.16, 0.02, size * 0.16), WHITE)


def tie(ch, rgb, z_top=3.82, y=-0.47):
    ch.box("UpperTorso", (0, y - 0.01, z_top), (0.22, 0.05, 0.16), shade(rgb, 0.8))
    ch.box("UpperTorso", (0, y, z_top - 0.45), (0.17, 0.04, 0.78), rgb)


def briefcase(ch, rgb=(130, 80, 40), x=-0.89):
    ch.box("RightUpperArm", (x, -0.05, 1.45), (0.2, 0.85, 0.62), rgb)
    ch.box("RightUpperArm", (x, -0.05, 1.8), (0.08, 0.3, 0.12), shade(rgb, 0.7))
    ch.box("RightUpperArm", (x, -0.05, 1.5), (0.22, 0.08, 0.12), (255, 200, 40))


def tralalero():
    ch = Lawyer("Tralalero")
    shark, belly = (96, 140, 186), (236, 240, 246)
    shoe = (50, 110, 230)
    body(ch, shark, shirt=shark, pants=shark, shoes=shoe, cuff=shade(shark, 0.8))
    for x in (0.34, -0.34):                                               # sneaker swoosh + white soles
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.13, 0.03), (0.45, 0.76, 0.06), WHITE)
        ch.box(f"{side}UpperLeg", (x * 1.02, -0.2, 0.16), (0.46, 0.3, 0.06), WHITE, rot_y=-15)
    ch.box("UpperTorso", (0, -0.46, 2.9), (0.95, 0.04, 1.4), belly)          # white belly
    tie(ch, (220, 40, 50))
    ch.box("UpperTorso", (0, 0.62, 2.35), (0.34, 0.5, 0.4), shark)            # tail + tail fin
    ch.box("UpperTorso", (0, 0.92, 2.55), (0.12, 0.3, 0.8), shade(shark, 0.85), rot_x=20)
    # shark head: block skull, long snout, toothy grin, side eyes, dorsal fin
    ch.box("Head", (0, 0, 4.6), (1.3, 1.2, 1.3), shark)
    ch.box("Head", (0, -0.85, 4.45), (1.0, 0.6, 0.8), shark)
    ch.box("Head", (0, -0.9, 4.1), (0.95, 0.55, 0.12), belly)                # pale chin
    ch.box("Head", (0, -1.16, 4.22), (0.8, 0.05, 0.2), MOUTH)
    for i in range(5):                                                    # teeth
        ch.box("Head", (-0.32 + i * 0.16, -1.19, 4.27), (0.08, 0.03, 0.1), WHITE)
    for x in (0.4, -0.4):
        eye(ch, x, -1.16, 4.7, size=0.26)
    ch.box("Head", (0, 0.1, 5.5), (0.14, 0.8, 0.7), shade(shark, 0.85), rot_x=-25)   # dorsal fin
    for x in (0.7, -0.7):
        ch.box("Head", (x, -0.1, 4.4), (0.06, 0.3, 0.05), shade(shark, 0.7))  # gills
    briefcase(ch, (40, 40, 46))
    return ch


def bombardiro():
    ch = Lawyer("Bombardiro")
    croc, olive = (90, 150, 70), (110, 120, 70)
    body(ch, croc, shirt=olive, pants=croc, shoes=shade(croc, 0.7), cuff=shade(olive, 0.8), hands=croc)
    for x in (0.34, -0.34):                                               # claws
        side = "Left" if x > 0 else "Right"
        for dx in (-0.12, 0, 0.12):
            ch.box(f"{side}UpperLeg", (x + dx, -0.52, 0.06), (0.08, 0.1, 0.08), WHITE)
    # bomber plane body: wings, propellers, bombs, a star, cockpit
    wing = (140, 150, 90)
    ch.box("UpperTorso", (0, 0.2, 3.65), (4.4, 1.3, 0.2), wing)                  # big bomber wings
    for x in (2.1, -2.1):
        ch.box("UpperTorso", (x, 0.2, 3.65), (0.2, 1.32, 0.22), (200, 40, 40))   # red wingtips
    for x in (1.45, -1.45):
        ch.box("UpperTorso", (x, -0.4, 3.62), (0.4, 0.5, 0.4), (70, 74, 60))     # engine
        ch.box("UpperTorso", (x, -0.68, 3.62), (0.12, 0.06, 0.12), (40, 40, 44))
        ch.box("UpperTorso", (x, -0.7, 3.62), (1.1, 0.04, 0.14), (40, 40, 44))   # propeller
        ch.box("UpperTorso", (x, 0.2, 3.3), (0.24, 0.7, 0.24), (70, 70, 76))     # bomb
        ch.box("UpperTorso", (x, 0.6, 3.3), (0.28, 0.1, 0.28), (200, 40, 40))
    ch.box("UpperTorso", (0, -0.47, 2.7), (0.4, 0.04, 0.4), WHITE)               # star roundel
    ch.box("UpperTorso", (0, -0.49, 2.7), (0.22, 0.04, 0.22), (40, 80, 200))
    ch.box("UpperTorso", (0, 0.55, 3.0), (0.5, 0.3, 1.2), olive)                 # tail
    ch.box("UpperTorso", (0, 0.75, 3.75), (0.1, 0.3, 0.6), olive)
    tie(ch, (230, 200, 60))
    # crocodile head: long snout with teeth, eye bumps on top, flight goggles
    ch.box("Head", (0, 0, 4.4), (1.3, 1.1, 1.0), croc)
    ch.box("Head", (0, -1.05, 4.2), (0.95, 1.2, 0.45), croc)
    ch.box("Head", (0, -1.05, 4.0), (0.9, 1.15, 0.08), MOUTH)
    for i in range(6):
        for x in (0.42, -0.42):
            ch.box("Head", (x, -0.6 - i * 0.18, 4.04), (0.06, 0.08, 0.12), WHITE)
    for x in (0.18, -0.18):
        ch.box("Head", (x, -1.6, 4.45), (0.08, 0.08, 0.05), shade(croc, 0.6))     # nostrils
    for x in (0.35, -0.35):
        ch.box("Head", (x, -0.25, 5.0), (0.42, 0.42, 0.3), croc)                  # eye bumps
        eye(ch, x, -0.47, 5.0, size=0.3, pupil=(30, 30, 30), white=(250, 220, 60))
    ch.box("Head", (0, 0.05, 5.2), (1.34, 1.0, 0.1), (110, 70, 40))               # goggle strap
    for x in (0.35, -0.35):
        ch.box("Head", (x, -0.3, 5.25), (0.4, 0.3, 0.2), (110, 70, 40))
        ch.box("Head", (x, -0.46, 5.25), (0.3, 0.03, 0.12), (150, 210, 255))
    return ch


def cappuccino_avvocato():
    ch = Lawyer("CappuccinoAvvocato")
    suit, cup, coffee = (28, 28, 34), (248, 246, 240), (130, 80, 45)
    body(ch, (232, 190, 150), shirt=suit, pants=suit, shoes=BLACK, cuff=(200, 30, 40), hands=(30, 30, 34))
    suit_front(ch, suit, (200, 30, 40), shirt=(45, 45, 52))
    ch.box("UpperTorso", (0, 0, 2.75), (1.48, 0.94, 0.14), (200, 30, 40))       # ninja sash
    for y in (0.5,):
        ch.box("UpperTorso", (0.3, y, 3.2), (0.1, 0.1, 1.6), (60, 60, 66), rot_y=-30)   # sheath on the back
    # cup head: white mug, black ninja mask band with eye slit, coffee + foam on top, handle
    ch.box("Head", (0, 0, 4.6), (1.2, 1.2, 1.35), cup)
    ch.box("Head", (0, 0, 3.98), (1.0, 1.0, 0.12), shade(cup, 0.9))
    ch.box("Head", (0, 0, 4.72), (1.24, 1.24, 0.42), (25, 25, 30))
    for x in (0.27, -0.27):
        ch.box("Head", (x, -0.63, 4.72), (0.32, 0.03, 0.14), WHITE)
        ch.box("Head", (x * 0.9, -0.65, 4.72), (0.12, 0.03, 0.1), BLACK)
    for x, r in ((0.27, 12), (-0.27, -12)):
        ch.box("Head", (x, -0.65, 4.86), (0.36, 0.03, 0.06), (200, 30, 40), rot_y=r)   # angry brows
    ch.box("Head", (0, 0, 5.3), (1.1, 1.1, 0.05), coffee)
    ch.box("Head", (0, 0, 5.33), (0.6, 0.6, 0.03), (245, 225, 195))              # foam
    ch.box("Head", (0.75, 0, 4.6), (0.3, 0.12, 0.6), cup)                        # handle
    ch.box("Head", (0, 0.66, 4.72), (0.3, 0.1, 0.5), (25, 25, 30))               # mask knot tails
    # crossed golden gavels
    gold = (255, 205, 60)
    for r in (35, -35):
        ch.box("RightUpperArm", (-0.89, -0.3, 2.3), (0.1, 0.1, 1.1), (90, 60, 30), rot_x=r)
    ch.box("RightUpperArm", (-0.89, -0.62, 2.75), (0.36, 0.36, 0.7), gold)
    ch.box("RightUpperArm", (-0.89, 0.02, 2.75), (0.36, 0.36, 0.7), gold)
    return ch


def ballerina_cappuccina():
    ch = Lawyer("BallerinaCappuccina")
    skin, pink = (244, 206, 180), (255, 150, 200)
    cup, coffee = (250, 248, 244), (140, 90, 55)
    pink = (255, 110, 175)
    body(ch, skin, shirt=pink, pants=skin, shoes=(255, 170, 210), sleeves=skin, cuff=pink)
    for x in (0.34, -0.34):                                               # ribbons up the legs
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.23, 0.55), (0.37, 0.03, 0.05), (255, 120, 180), rot_y=20)
    ch.box("UpperTorso", (0, 0, 2.12), (2.5, 1.7, 0.18), (255, 225, 240))        # fluffy tutu, two layers
    ch.box("UpperTorso", (0, 0, 2.28), (2.1, 1.45, 0.16), (255, 190, 225))
    for x, r in ((0.15, 20), (-0.15, -20)):                               # bow tie, she's a lawyer
        ch.box("UpperTorso", (x, -0.5, 3.78), (0.26, 0.06, 0.18), (60, 40, 120), rot_y=r)
    # cappuccino cup head with a foam heart and a face on the cup
    ch.box("Head", (0, 0, 4.6), (1.3, 1.3, 1.35), cup)
    ch.box("Head", (0, 0, 5.29), (1.2, 1.2, 0.06), coffee)
    for x, y in ((0.12, 0.05), (-0.12, 0.05), (0, -0.12)):
        ch.box("Head", (x, y, 5.33), (0.28, 0.28, 0.03), (250, 235, 215))
    ch.box("Head", (0, 0, 3.98), (1.4, 1.4, 0.1), (230, 230, 236))               # saucer
    ch.box("Head", (0.8, 0, 4.65), (0.3, 0.12, 0.55), cup)
    for x in (0.27, -0.27):
        eye(ch, x, -0.67, 4.7, size=0.34)
        ch.box("Head", (x, -0.68, 4.95), (0.34, 0.03, 0.05), BLACK)              # lashes
        ch.box("Head", (x * 1.6, -0.67, 4.38), (0.18, 0.03, 0.08), (255, 160, 180))
    ch.box("Head", (0, -0.67, 4.3), (0.3, 0.03, 0.1), MOUTH)
    # legal scroll with a pink ribbon
    ch.box("RightUpperArm", (-0.89, -0.3, 1.95), (0.24, 1.0, 0.24), (250, 240, 210))
    ch.box("RightUpperArm", (-0.89, -0.3, 1.95), (0.28, 0.1, 0.28), (255, 120, 180))
    return ch


def brr_brr_patapim():
    ch = Lawyer("BrrBrrPatapim")
    wood, bark, leaf = (150, 100, 60), (110, 70, 40), (90, 170, 60)
    body(ch, wood, shirt=wood, pants=wood, shoes=bark, cuff=bark)
    for x in (0.34, -0.34):                                               # HUGE feet
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x * 1.1, -0.45, 0.14), (0.62, 1.5, 0.28), bark)
        for dx in (-0.18, 0, 0.18):
            ch.box(f"{side}UpperLeg", (x * 1.1 + dx, -1.22, 0.14), (0.16, 0.08, 0.2), shade(bark, 0.8))
    for z in (2.4, 3.1, 3.7):
        ch.box("UpperTorso", (0, 0, z), (1.47, 0.93, 0.05), bark)                 # bark rings
    tie(ch, (220, 40, 50))
    ch.box("UpperTorso", (0.3, -0.47, 3.3), (0.2, 0.05, 0.3), leaf)            # sprouting twig
    # monkey face on a log, long nose, leafy hair
    ch.box("Head", (0, 0, 4.6), (1.32, 0.9, 1.35), wood)
    ch.box("Head", (0, -0.47, 4.45), (0.95, 0.06, 0.8), (225, 180, 130))       # face patch
    for x in (0.25, -0.25):
        eye(ch, x, -0.52, 4.68, size=0.3)
    ch.box("Head", (0, -0.8, 4.4), (0.2, 0.6, 0.2), (200, 140, 90))             # long nose
    ch.box("Head", (0, -0.5, 4.13), (0.4, 0.03, 0.1), MOUTH)
    for x in (0.74, -0.74):
        ch.box("Head", (x, 0, 4.6), (0.18, 0.3, 0.4), (225, 180, 130))         # ears
    for (x, y, z, s) in ((0, 0, 5.45, 1.0), (0.45, 0.1, 5.6, 0.6), (-0.45, 0.1, 5.6, 0.6), (0, -0.2, 5.8, 0.6),
                         (0.2, 0.25, 5.9, 0.45)):
        ch.box("Head", (x, y, z), (s * 1.3, s, s * 0.6), leaf)
    # legal pad
    ch.box("RightUpperArm", (-0.89, -0.32, 1.95), (0.06, 0.6, 0.8), (255, 230, 100))
    ch.box("RightUpperArm", (-0.89, -0.32, 2.3), (0.08, 0.6, 0.1), (200, 60, 60))
    return ch


def lirili_larila():
    ch = Lawyer("LiriliLarila")
    grey, cactus = (150, 152, 160), (90, 170, 80)
    body(ch, grey, shirt=cactus, pants=grey, shoes=(160, 110, 60), sleeves=cactus, cuff=shade(cactus, 0.8))
    for x in (0.34, -0.34):                                               # sandals: straps over grey toes
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.12, 0.3), (0.45, 0.6, 0.08), (120, 80, 40))
        ch.box(f"{side}UpperLeg", (x, -0.4, 0.2), (0.4, 0.2, 0.12), grey)
    for (x, z) in ((0.5, 3.6), (-0.4, 3.3), (0.3, 2.6), (-0.55, 2.5), (0.1, 3.0), (0.62, 2.95), (-0.15, 2.3)):
        ch.box("UpperTorso", (x, -0.47, z), (0.04, 0.12, 0.04), (250, 245, 200))   # cactus spines
    for x in (0.95, -0.95):
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperArm", (x, -0.18, 3.3), (0.04, 0.1, 0.04), (250, 245, 200))
    ch.box("UpperTorso", (0, 0, 4.02), (0.5, 0.5, 0.2), (255, 120, 170))          # cactus flower at the neck
    tie(ch, (60, 100, 220), z_top=3.7)
    # elephant head: big floppy ears, trunk, tusks
    ch.box("Head", (0, 0, 4.6), (1.3, 1.0, 1.3), grey)
    for x in (0.85, -0.85):
        ch.box("Head", (x, 0.1, 4.6), (0.5, 0.14, 1.1), shade(grey, 0.9))
        ch.box("Head", (x * 1.01, 0.03, 4.6), (0.36, 0.04, 0.8), (225, 170, 175))
    for x in (0.27, -0.27):
        eye(ch, x, -0.53, 4.8, size=0.3)
    ch.box("Head", (0, -0.65, 4.3), (0.32, 0.3, 0.5), grey)                     # trunk
    ch.box("Head", (0, -0.85, 3.95), (0.28, 0.28, 0.5), grey)
    ch.box("Head", (0, -0.95, 3.68), (0.26, 0.26, 0.16), shade(grey, 0.85))
    for x in (0.28, -0.28):
        ch.box("Head", (x, -0.65, 4.05), (0.1, 0.4, 0.1), WHITE, rot_x=30)       # tusks
    # a big pocket clock
    ch.box("RightUpperArm", (-0.89, -0.32, 1.95), (0.1, 0.6, 0.6), (255, 200, 40))
    ch.box("RightUpperArm", (-0.95, -0.32, 1.95), (0.02, 0.48, 0.48), WHITE)
    ch.box("RightUpperArm", (-0.97, -0.32, 2.03), (0.02, 0.04, 0.18), BLACK)
    ch.box("RightUpperArm", (-0.97, -0.24, 1.95), (0.02, 0.16, 0.04), BLACK)
    return ch


def chimpanzini_bananini():
    ch = Lawyer("ChimpanziniBananini")
    fur, muzzle, banana = (110, 70, 40), (220, 180, 140), (255, 220, 60)
    body(ch, fur, shirt=banana, pants=banana, shoes=(120, 90, 30), sleeves=fur, cuff=banana, hands=muzzle)
    for x in (0.34, -0.34):                                               # banana tip feet
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.1, 0.12), (0.36, 0.6, 0.24), (110, 80, 30))
    peel = (255, 235, 110)
    for x, r in ((0.78, -28), (-0.78, 28)):                               # opened peel flaps around the head
        ch.box("UpperTorso", (x, 0, 4.35), (0.34, 0.8, 1.1), peel, rot_y=r)
        ch.box("UpperTorso", (x * 1.22, 0, 4.88), (0.2, 0.5, 0.18), (120, 90, 30), rot_y=r)
    ch.box("UpperTorso", (0, 0.62, 4.35), (1.0, 0.3, 1.1), peel, rot_x=20)
    ch.box("UpperTorso", (0, -0.47, 2.2), (1.0, 0.05, 0.12), (120, 90, 30))      # banana spots
    for z in (2.6, 3.3):
        ch.box("UpperTorso", (0, 0, z), (1.47, 0.93, 0.04), shade(banana, 0.85))     # banana ridges
    ch.box("UpperTorso", (0, 0, 3.98), (1.6, 1.05, 0.18), (250, 230, 120))     # peeled rim
    tie(ch, (200, 40, 50), z_top=3.75)
    # chimp head
    ch.box("Head", (0, 0, 4.6), (1.25, 0.95, 1.25), fur)
    ch.box("Head", (0, -0.48, 4.6), (0.95, 0.04, 0.6), muzzle)                 # face
    ch.box("Head", (0, -0.55, 4.28), (0.7, 0.2, 0.4), muzzle)                  # snout
    for x in (0.22, -0.22):
        eye(ch, x, -0.52, 4.72, size=0.28)
        ch.box("Head", (x * 0.4, -0.66, 4.38), (0.06, 0.03, 0.06), (60, 36, 20))
    ch.box("Head", (0, -0.66, 4.2), (0.36, 0.03, 0.08), MOUTH)
    for x in (0.7, -0.7):
        ch.box("Head", (x, 0, 4.65), (0.2, 0.2, 0.42), muzzle)
    ch.box("Head", (0, 0, 5.28), (0.5, 0.5, 0.12), fur)
    # banana-phone
    ch.box("RightUpperArm", (-0.89, -0.25, 2.0), (0.18, 0.6, 0.18), banana, rot_x=15)
    return ch


def boneca_ambalabu():
    ch = Lawyer("BonecaAmbalabu")
    frog, belly, skin = (110, 190, 80), (230, 240, 170), (232, 180, 140)
    tire, hub = (32, 32, 36), (150, 150, 158)
    body(ch, skin, shirt=tire, pants=skin, shoes=(240, 240, 240), sleeves=frog, cuff=shade(frog, 0.8), hands=frog)
    for x in (0.34, -0.34):                                               # sneakers with red laces
        side = "Left" if x > 0 else "Right"
        ch.box(f"{side}UpperLeg", (x, -0.4, 0.26), (0.3, 0.1, 0.05), (220, 50, 50))
        ch.box(f"{side}UpperLeg", (x, 0, 2.05), (0.4, 0.48, 0.25), (60, 70, 140))   # little shorts
    # the tire torso: tread blocks + a silver hub where the belly would be
    ch.box("UpperTorso", (0, -0.47, 3.0), (0.9, 0.05, 0.9), hub)
    ch.box("UpperTorso", (0, -0.5, 3.0), (0.4, 0.04, 0.4), shade(hub, 0.7))
    for z in (2.2, 2.6, 3.4, 3.8):
        ch.box("UpperTorso", (0, 0, z), (1.52, 0.98, 0.1), (20, 20, 22))
    ch.box("UpperTorso", (0.48, -0.5, 3.6), (0.2, 0.04, 0.36), (220, 40, 50))   # tiny tie on the tire
    # frog head: wide, eyes on top, big grin
    ch.box("Head", (0, 0, 4.5), (1.5, 1.1, 1.1), frog)
    ch.box("Head", (0, -0.4, 4.2), (1.3, 0.3, 0.45), belly)
    ch.box("Head", (0, -0.57, 4.38), (1.1, 0.05, 0.1), MOUTH)
    for x in (0.4, -0.4):
        ch.box("Head", (x, -0.15, 5.15), (0.5, 0.5, 0.4), frog)
        eye(ch, x, -0.42, 5.18, size=0.38)
        ch.box("Head", (x * 0.4, -0.57, 4.62), (0.06, 0.03, 0.06), shade(frog, 0.6))
    for (x, z) in ((0.55, 4.7), (-0.6, 4.3), (0.2, 4.95)):
        ch.box("Head", (x, -0.56, z), (0.12, 0.03, 0.12), shade(frog, 0.8))   # spots
    briefcase(ch, (180, 40, 40))
    return ch


BRAINROT = [tralalero, bombardiro, cappuccino_avvocato, ballerina_cappuccina, brr_brr_patapim, lirili_larila,
            chimpanzini_bananini, boneca_ambalabu]


def preview_material():
    """Palette texture for the Blender preview only (Roblox gets plain coloured Parts, no texture). Kept apart
    from the clients' ClientPalette2 so their exported texture never changes."""
    cv.GRID = 32                                   # >256 colours with the brainrot cast (preview only)
    size = cv.GRID * cv.CELL
    px = [1.0] * (size * size * 4)
    for rgb, i in cv.COLORS.items():
        cx, cy = i % cv.GRID, i // cv.GRID
        for y in range(cv.CELL):
            for x in range(cv.CELL):
                row = size - 1 - (cy * cv.CELL + y)
                j = (row * size + cx * cv.CELL + x) * 4
                px[j:j + 4] = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0]
    img = bpy.data.images.get("LawyerPalette2")
    if img and img.size[0] != size:
        bpy.data.images.remove(img)
        img = None
    img = img or bpy.data.images.new("LawyerPalette2", size, size, alpha=False)
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
    chars = [fn() for fn in ROSTER + OTHERS + BRAINROT]
    mat = preview_material()
    for i, ch in enumerate(chars):
        ch.build(coll, mat, (i - 7) * 3.0 if i < 14 else (i - 18) * 3.2)
        if i >= 14:
            for o in coll.objects:
                if o.name.startswith(ch.cid + "_"):
                    o.location.y = 8
    return coll


# Roblox space = M @ Blender space, M maps (x, y, z) -> (-x, z, y) (det +1, a proper rotation)
M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def export_rows():
    out = {}
    for fn in ROSTER + OTHERS + BRAINROT:
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
