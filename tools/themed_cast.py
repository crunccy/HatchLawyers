"""Themed egg lawyers (Pet / Food / Ocean / Space, 8 each) + 30 more clients, in the same block style as
tools/lawyers_v2.py (which this builds on). Run inside Blender:
    exec(open("/Users/ryanchen/HatchLawyers/tools/themed_cast.py").read()); build_all(); export_rows()

export_rows() writes tools/themed_parts.json in the lawyer_parts.json row format plus a material flag
(0 Plastic, 1 Neon, 2 Glass): { Id: [[part, x, y, z, sx, sy, sz, r00..r22, r, g, b, flag], ...] }.
Lawyers go to ReplicatedStorage.SkinModels; clients to ServerStorage.Templates.Clients (+ invisible root).
Every box is in one of the 6 limb groups so Shared.Puppet animates them.
Coordinates (Blender): front = -y, the character's left = +x; head 3.91-5.31, torso 2.05-3.95, hands z ~2,
right hand x = -0.89 (props go in RightUpperArm), feet at z = 0.
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
import lawyers_v2 as lv  # noqa: E402

importlib.reload(lv)
cv = lv.cv
Lawyer, body, face, hair_cap, shade = lv.Lawyer, lv.body, lv.face, lv.hair_cap, lv.shade
suit_front, glasses, eye, tie, briefcase = lv.suit_front, lv.glasses, lv.eye, lv.tie, lv.briefcase
WHITE, BLACK, MOUTH = lv.WHITE, lv.BLACK, lv.MOUTH
GOLD = (255, 205, 60)


class Char(Lawyer):
    """Adds glass (semi-transparent) colours on top of Lawyer's neon ones."""

    def __init__(self, cid):
        super().__init__(cid)
        self.glassy = set()

    def glass(self, rgb):
        self.glassy.add(cv.col(rgb))
        return rgb


# --------------------------------------------------------------------------------------------- helpers
def H(ch, c, s, rgb, **kw):
    ch.box("Head", c, s, rgb, **kw)


def T(ch, c, s, rgb, **kw):
    ch.box("UpperTorso", c, s, rgb, **kw)


def RA(ch, c, s, rgb, **kw):
    ch.box("RightUpperArm", c, s, rgb, **kw)


def both_legs(ch, fn):
    for x, side in ((0.34, "Left"), (-0.34, "Right")):
        fn(x, f"{side}UpperLeg")


def both_arms(ch, fn):
    for x, side in ((0.89, "Left"), (-0.89, "Right")):
        fn(x, f"{side}UpperArm")


def skull(ch, rgb, size=(1.32, 0.78, 1.4), z=4.61):
    """The head's main block (must be the first Head box)."""
    H(ch, (0, 0, z), size, rgb)


def eyes(ch, y, z=4.7, dx=0.27, size=0.32, **kw):
    for x in (dx, -dx):
        eye(ch, x, y, z, size=size, **kw)


def mouth(ch, y, z=4.2, w=0.4, open_=False):
    H(ch, (0, y, z), (w, 0.04, 0.16 if open_ else 0.1), MOUTH)
    if open_:
        H(ch, (0, y - 0.01, z + 0.04), (w * 0.85, 0.04, 0.06), WHITE)


def ears(ch, rgb, inner=None, x=0.55, z=5.4, size=(0.32, 0.18, 0.45), rot=0):
    for sx in (1, -1):
        H(ch, (x * sx, 0, z), size, rgb, rot_y=-rot * sx)
        if inner:
            H(ch, (x * sx, -0.1, z - 0.02), (size[0] * 0.55, 0.04, size[2] * 0.6), inner, rot_y=-rot * sx)


def cap(ch, rgb, z=5.42, brim=True, logo=None):
    H(ch, (0, 0, z), (1.42, 0.88, 0.26), rgb)
    if brim:
        H(ch, (0, -0.62, z - 0.09), (1.1, 0.5, 0.08), rgb)
    if logo:
        H(ch, (0, -0.45, z + 0.03), (0.36, 0.03, 0.16), logo)


def tophat(ch, rgb, band=(200, 40, 50), z=5.36):
    H(ch, (0, 0, z), (1.7, 1.1, 0.1), rgb)
    H(ch, (0, 0, z + 0.55), (1.05, 0.8, 1.0), rgb)
    H(ch, (0, 0, z + 0.18), (1.07, 0.82, 0.18), band)


def crown(ch, rgb=GOLD, z=5.45, gems=((230, 30, 60),)):
    H(ch, (0, 0, z), (1.4, 0.88, 0.3), rgb)
    for x in (-0.5, 0, 0.5):
        for y in (-0.33, 0.33):
            H(ch, (x, y, z + 0.3), (0.26, 0.18, 0.34), rgb)
    for i, g in enumerate(gems):
        H(ch, (0.3 * (i - (len(gems) - 1) / 2), -0.45, z), (0.16, 0.03, 0.16), ch.glow(g))


def robe(ch, rgb, trim=GOLD):
    """A judge / royal robe over the torso, down past the hips."""
    T(ch, (0, 0, 2.85), (1.6, 1.0, 2.2), rgb)
    T(ch, (0, -0.51, 2.85), (0.12, 0.03, 2.2), trim)
    both_legs(ch, lambda x, leg: ch.box(leg, (x * 1.15, 0, 1.55), (0.66, 0.66, 0.9), rgb))


def legal_pad(ch):
    RA(ch, (-0.89, -0.32, 1.95), (0.06, 0.6, 0.8), (255, 230, 100))
    RA(ch, (-0.89, -0.32, 2.3), (0.08, 0.6, 0.1), (200, 60, 60))


def gavel(ch, head=(150, 95, 50)):
    RA(ch, (-0.89, -0.22, 2.45), (0.12, 0.12, 1.1), (110, 70, 35))
    RA(ch, (-0.89, -0.22, 3.1), (0.36, 0.8, 0.36), head)


def suited(ch, skin, suit, tie_rgb, pants=None, shoes=BLACK, hands=None, shirt=WHITE):
    body(ch, skin, shirt=suit, pants=pants or shade(suit, 0.8), shoes=shoes, cuff=WHITE, hands=hands)
    suit_front(ch, suit, tie_rgb, shirt=shirt)


# =============================================================================================== PET
def pet_pup():
    ch = Char("PawralegalPup")
    fur, white = (190, 130, 70), (245, 240, 230)
    suited(ch, fur, (70, 90, 150), (220, 50, 50), hands=white)
    skull(ch, fur, (1.3, 0.95, 1.25), 4.58)
    H(ch, (0, -0.48, 4.55), (0.7, 0.05, 0.9), white)                      # white blaze
    H(ch, (0, -0.65, 4.25), (0.6, 0.4, 0.4), white)                       # muzzle
    H(ch, (0, -0.87, 4.38), (0.24, 0.05, 0.16), BLACK)                    # nose
    eyes(ch, -0.5, 4.75, 0.3, 0.28)
    mouth(ch, -0.86, 4.15, 0.3)
    for sx in (1, -1):
        H(ch, (0.7 * sx, 0, 4.5), (0.16, 0.5, 0.9), (120, 70, 35))         # floppy ears
    legal_pad(ch)
    return ch


def pet_hamster():
    ch = Char("HamsterHustle")
    fur, belly = (230, 170, 100), (250, 235, 210)
    suited(ch, fur, (160, 60, 60), GOLD, hands=(255, 190, 180))
    skull(ch, fur, (1.45, 1.0, 1.25), 4.58)
    for sx in (1, -1):
        H(ch, (0.55 * sx, -0.48, 4.25), (0.45, 0.1, 0.45), belly)          # chubby cheeks
        H(ch, (0.62 * sx, -0.5, 4.35), (0.18, 0.04, 0.1), (255, 160, 170))
    H(ch, (0, -0.52, 4.35), (0.14, 0.04, 0.1), (255, 140, 160))           # nose
    H(ch, (0, -0.52, 4.18), (0.18, 0.03, 0.12), WHITE)                    # buck teeth
    eyes(ch, -0.5, 4.75, 0.28, 0.26)
    ears(ch, fur, (255, 180, 180), x=0.5, z=5.3, size=(0.34, 0.14, 0.34))
    briefcase(ch, (60, 60, 70))
    return ch


def pet_cat():
    ch = Char("WhiskersEsq")
    fur, stripe = (240, 150, 60), (200, 100, 30)
    suited(ch, fur, (40, 40, 50), (60, 160, 230))
    skull(ch, fur, (1.35, 0.9, 1.25), 4.58)
    for z in (5.0, 5.15):
        H(ch, (0, -0.46, z), (0.12, 0.03, 0.08), stripe)
    H(ch, (0, -0.5, 4.3), (0.6, 0.1, 0.35), (255, 230, 200))
    H(ch, (0, -0.56, 4.42), (0.14, 0.04, 0.1), (255, 130, 150))
    for sx in (1, -1):
        for dz in (0.05, -0.08):
            H(ch, (0.45 * sx, -0.56, 4.33 + dz), (0.4, 0.02, 0.03), WHITE)  # whiskers
    eyes(ch, -0.47, 4.75, 0.28, 0.3, pupil=(40, 120, 40), white=(200, 255, 140))
    ears(ch, fur, (255, 180, 190), x=0.42, z=5.42, size=(0.36, 0.16, 0.4), rot=12)
    RA(ch, (-0.89, -0.35, 2.0), (0.12, 0.7, 0.9), WHITE, rot_x=20)           # papers it's about to knock over
    RA(ch, (-0.95, -0.32, 2.05), (0.04, 0.6, 0.7), (230, 230, 236), rot_x=10)
    return ch


def pet_goldfish():
    ch = Char("BubblesGoldfish")
    suited(ch, (240, 200, 170), (60, 140, 200), (255, 140, 40))
    skull(ch, ch.glass((170, 225, 255)), (1.45, 1.45, 1.45), 4.68)       # fishbowl head
    H(ch, (0, 0, 4.0), (1.1, 1.1, 0.12), (80, 160, 230))                   # water line / base
    fish = (255, 130, 30)
    H(ch, (0, -0.2, 4.7), (0.55, 0.3, 0.4), fish)
    H(ch, (0.38, -0.2, 4.7), (0.16, 0.12, 0.36), (255, 90, 30))           # tail
    eye(ch, -0.12, -0.36, 4.75, size=0.16)
    H(ch, (0, 0, 5.44), (1.2, 1.2, 0.08), (120, 200, 240))                 # bowl rim
    for i, (x, z) in enumerate(((0.3, 5.0), (0.15, 5.18), (-0.3, 4.35))):
        H(ch, (x, -0.3, z), (0.1, 0.1, 0.1), WHITE)                        # bubbles
    briefcase(ch, (40, 100, 180))
    return ch


def pet_corgi():
    ch = Char("CorgiCounsel")
    fur, white = (230, 140, 60), (250, 245, 235)
    body(ch, fur, shirt=(250, 245, 235), pants=fur, shoes=white, hands=white, cuff=fur)
    T(ch, (0, -0.47, 3.75), (0.4, 0.06, 0.14), (200, 40, 60))              # bow tie
    T(ch, (0.18, -0.5, 3.75), (0.2, 0.05, 0.24), (220, 50, 70), rot_y=20)
    T(ch, (-0.18, -0.5, 3.75), (0.2, 0.05, 0.24), (220, 50, 70), rot_y=-20)
    T(ch, (0, 0.55, 2.2), (0.4, 0.2, 0.3), white)                          # fluffy butt
    skull(ch, fur, (1.35, 1.0, 1.2), 4.55)
    H(ch, (0, -0.5, 4.45), (0.55, 0.05, 1.0), white)
    H(ch, (0, -0.7, 4.2), (0.62, 0.4, 0.38), white)
    H(ch, (0, -0.92, 4.32), (0.22, 0.05, 0.14), BLACK)
    eyes(ch, -0.52, 4.72, 0.32, 0.26)
    mouth(ch, -0.91, 4.12, 0.3, True)
    H(ch, (0, -0.92, 4.02), (0.14, 0.04, 0.16), (255, 120, 140))           # tongue
    ears(ch, fur, (255, 200, 190), x=0.45, z=5.5, size=(0.42, 0.16, 0.6), rot=10)
    legal_pad(ch)
    return ch


def pet_parrot():
    ch = Char("ParrotProsecutor")
    red, blue, yellow = (230, 40, 40), (40, 110, 230), (255, 210, 40)
    body(ch, red, shirt=red, pants=(60, 60, 70), shoes=(255, 170, 40), sleeves=blue, cuff=yellow, hands=yellow)
    tie(ch, (40, 40, 50))
    for i, c in enumerate((yellow, blue, (60, 190, 90))):                    # tail feathers
        T(ch, (-0.25 + i * 0.25, 0.55, 2.2), (0.2, 0.15, 1.0), c, rot_x=-20)
    for x, side in ((1.05, "Left"), (-1.05, "Right")):
        ch.box(f"{side}UpperArm", (x, 0.05, 2.9), (0.08, 0.45, 1.1), blue)  # wing feathers
    skull(ch, red, (1.25, 1.0, 1.3), 4.6)
    for sx in (1, -1):
        H(ch, (0.32 * sx, -0.51, 4.75), (0.5, 0.04, 0.45), WHITE)
    eyes(ch, -0.54, 4.75, 0.32, 0.22)
    H(ch, (0, -0.75, 4.4), (0.38, 0.5, 0.42), (60, 60, 66))                # hooked beak
    H(ch, (0, -0.98, 4.25), (0.22, 0.12, 0.28), (60, 60, 66))
    for i in range(3):
        H(ch, (0, 0.1 - i * 0.2, 5.38 + i * 0.12), (0.18, 0.18, 0.4), yellow, rot_x=-25)   # crest
    gavel(ch)
    return ch


def pet_royal_cat():
    ch = Char("SirFluffington")
    fur = (250, 250, 252)
    body(ch, fur, shirt=(120, 40, 160), pants=(90, 30, 120), shoes=GOLD, cuff=WHITE, hands=fur)
    robe(ch, (150, 30, 60))
    T(ch, (0, -0.5, 3.75), (1.3, 0.1, 0.3), WHITE)                         # ermine collar
    for x in (-0.4, 0, 0.4):
        T(ch, (x, -0.56, 3.75), (0.08, 0.03, 0.08), BLACK)
    skull(ch, fur, (1.5, 1.0, 1.35), 4.62)
    for sx in (1, -1):
        H(ch, (0.72 * sx, 0, 4.45), (0.2, 0.8, 0.6), fur)                  # fluffy cheeks
    H(ch, (0, -0.52, 4.38), (0.16, 0.04, 0.1), (255, 150, 170))
    eyes(ch, -0.51, 4.72, 0.3, 0.3, pupil=(30, 60, 160), white=(150, 210, 255))
    ears(ch, fur, (255, 190, 200), x=0.45, z=5.42, size=(0.34, 0.16, 0.36), rot=12)
    crown(ch, z=5.55, gems=((230, 30, 60), (40, 160, 255), (230, 30, 60)))
    RA(ch, (-0.89, -0.2, 2.6), (0.12, 0.12, 1.6), GOLD)                    # sceptre
    RA(ch, (-0.89, -0.2, 3.45), (0.3, 0.3, 0.3), ch.glow((255, 80, 120)))
    return ch


def pet_hound():
    ch = Char("HoundOfJustice")
    fur, ear = (170, 110, 60), (110, 65, 30)
    coat = (150, 120, 80)
    body(ch, fur, shirt=coat, pants=(80, 60, 50), shoes=(70, 44, 26), cuff=shade(coat, 0.8), hands=fur)
    T(ch, (0, 0.05, 3.55), (1.6, 1.0, 0.6), shade(coat, 0.9))              # detective cape
    tie(ch, (40, 90, 60))
    skull(ch, fur, (1.3, 1.0, 1.3), 4.58)
    H(ch, (0, -0.68, 4.25), (0.65, 0.45, 0.45), shade(fur, 1.1))
    H(ch, (0, -0.92, 4.38), (0.26, 0.05, 0.16), BLACK)
    for sx in (1, -1):
        H(ch, (0.32 * sx, -0.51, 4.95), (0.38, 0.04, 0.12), ear, rot_y=-8 * sx)   # droopy brows
        H(ch, (0.72 * sx, 0, 4.3), (0.16, 0.5, 1.2), ear)                 # long droopy ears
    eyes(ch, -0.51, 4.72, 0.3, 0.26)
    H(ch, (0, 0, 5.38), (1.4, 0.95, 0.22), (140, 110, 70))                # deerstalker
    for y in (-0.6, 0.6):
        H(ch, (0, y, 5.3), (0.9, 0.35, 0.08), (140, 110, 70))
    RA(ch, (-0.89, -0.25, 2.2), (0.1, 0.1, 0.6), (90, 60, 30))              # magnifying glass
    RA(ch, (-0.89, -0.25, 2.65), (0.08, 0.5, 0.5), GOLD)
    RA(ch, (-0.92, -0.25, 2.65), (0.03, 0.4, 0.4), ch.glass((200, 240, 255)))
    return ch


PET = [pet_pup, pet_hamster, pet_cat, pet_goldfish, pet_corgi, pet_parrot, pet_royal_cat, pet_hound]


# ============================================================================================== FOOD
def food_body(ch, suit, tie_rgb, skin=(240, 200, 170)):
    suited(ch, skin, suit, tie_rgb)


def food_face(ch, y, z=4.65, dx=0.27, size=0.3, smile=True):
    eyes(ch, y, z, dx, size)
    mouth(ch, y - 0.01, z - 0.4, 0.34, open_=smile)


def food_toast():
    ch = Char("ToastAttorney")
    food_body(ch, (90, 120, 80), (230, 160, 60))
    crust, bread = (160, 90, 35), (250, 220, 160)
    skull(ch, crust, (1.6, 0.5, 1.45), 4.66)                              # a slice of toast, on its side
    for x in (-0.45, 0, 0.45):
        H(ch, (x, 0, 5.45), (0.62, 0.5, 0.35), crust)                     # puffy bread top
    H(ch, (0, -0.26, 4.66), (1.38, 0.04, 1.25), bread)
    for x in (-0.45, 0, 0.45):
        H(ch, (x, -0.26, 5.42), (0.5, 0.04, 0.28), bread)
    H(ch, (0.3, -0.3, 5.15), (0.42, 0.06, 0.26), (255, 240, 130))         # butter pat
    food_face(ch, -0.3)
    legal_pad(ch)
    return ch


def food_egg():
    ch = Char("SunnySideSam")
    food_body(ch, (230, 230, 236), (255, 190, 40))
    white, yolk = (252, 252, 248), (255, 190, 40)
    skull(ch, white, (1.6, 0.3, 1.5), 4.66)
    for (x, z, s) in ((0.6, 5.2, 0.5), (-0.65, 4.2, 0.45), (0.55, 4.1, 0.4)):
        H(ch, (x, 0, z), (s, 0.28, s), white)                              # wobbly edge
    H(ch, (0, -0.2, 4.65), (0.95, 0.2, 0.95), yolk)
    food_face(ch, -0.32, 4.7, 0.22, 0.24)
    briefcase(ch, (230, 150, 40))
    return ch


def food_sushi():
    ch = Char("SushiSolicitor")
    food_body(ch, (30, 50, 40), (220, 60, 60))
    nori, rice, salmon = (30, 60, 40), (250, 250, 245), (255, 130, 90)
    skull(ch, nori, (1.35, 1.0, 1.35), 4.62)
    H(ch, (0, -0.51, 4.62), (1.15, 0.04, 1.15), rice)
    H(ch, (0, 0, 5.32), (1.15, 0.9, 0.06), rice)
    H(ch, (0, -0.05, 5.4), (0.75, 0.7, 0.14), salmon)
    for x in (-0.18, 0.18):
        H(ch, (x, -0.43, 5.4), (0.06, 0.03, 0.14), (255, 200, 180))
    food_face(ch, -0.55)
    RA(ch, (-0.89, -0.3, 2.3), (0.06, 0.06, 1.2), (200, 160, 100), rot_x=15)   # chopsticks
    RA(ch, (-0.82, -0.3, 2.3), (0.06, 0.06, 1.2), (200, 160, 100), rot_x=10)
    return ch


def food_taco():
    ch = Char("TacoTribunal")
    food_body(ch, (200, 120, 40), (60, 160, 60))
    shell = (240, 190, 80)
    skull(ch, shell, (1.5, 1.0, 1.0), 4.45)
    for sx in (1, -1):
        H(ch, (0.6 * sx, 0, 5.0), (0.3, 1.0, 0.6), shell)                 # folded shell sides
    H(ch, (0, 0, 5.15), (1.0, 0.9, 0.3), (120, 70, 40))                    # filling
    for x, c in ((-0.35, (80, 190, 70)), (0.05, (230, 50, 40)), (0.35, (255, 220, 80))):
        H(ch, (x, -0.1, 5.35), (0.28, 0.6, 0.18), c)                       # lettuce / tomato / cheese
    food_face(ch, -0.51, 4.5)
    H(ch, (0, -0.52, 4.88), (1.0, 0.04, 0.06), BLACK)                      # angry unibrow, it's a tribunal
    gavel(ch, (240, 190, 80))
    return ch


def food_pizza():
    ch = Char("PizzaProsecutor")
    food_body(ch, (60, 120, 60), (220, 40, 40))
    crust, cheese = (215, 145, 65), (255, 210, 80)
    skull(ch, cheese, (0.7, 0.38, 1.05), 4.45)                             # a slice, point down
    for z, w in ((4.85, 1.5), (4.6, 1.15), (4.35, 0.8), (4.1, 0.45)):
        H(ch, (0, 0, z), (w, 0.36, 0.26), cheese)
    H(ch, (0, 0, 5.12), (1.7, 0.5, 0.32), crust)
    for (x, z) in ((-0.45, 4.85), (0.4, 4.6), (0, 4.2)):
        H(ch, (x, -0.2, z), (0.22, 0.04, 0.2), (200, 40, 40))             # pepperoni
    H(ch, (0.45, -0.2, 4.95), (0.1, 0.04, 0.3), (255, 230, 120))           # cheese drip
    eyes(ch, -0.2, 4.78, 0.24, 0.24)
    mouth(ch, -0.2, 4.45, 0.26, True)
    briefcase(ch, (180, 40, 40))
    return ch


def food_donut():
    ch = Char("DonutDefender")
    food_body(ch, (255, 140, 190), (120, 60, 200))
    dough, icing = (220, 160, 90), (255, 130, 190)
    skull(ch, dough, (1.6, 0.6, 1.6), 4.68)
    H(ch, (0, -0.31, 4.68), (1.5, 0.04, 1.5), icing)
    H(ch, (0, -0.35, 4.68), (0.45, 0.06, 0.45), (40, 40, 50))             # the hole
    for i, (x, z) in enumerate(((-0.5, 5.2), (0.45, 5.25), (0.6, 4.4), (-0.6, 4.3), (0.0, 5.35), (0.3, 4.1))):
        H(ch, (x, -0.35, z), (0.16, 0.03, 0.06), ((255, 255, 255), (80, 200, 255), (255, 230, 60))[i % 3],
          rot_y=30 * (i % 2 * 2 - 1))
    eyes(ch, -0.35, 4.95, 0.42, 0.24)
    mouth(ch, -0.35, 4.3, 0.3, True)
    RA(ch, (-0.89, -0.3, 2.0), (0.4, 0.6, 0.12), (230, 230, 240))         # a shield
    RA(ch, (-0.96, -0.3, 2.0), (0.04, 0.3, 0.3), GOLD)
    return ch


def food_burger():
    ch = Char("BurgerBoss")
    food_body(ch, (30, 30, 36), GOLD)
    bun = (220, 150, 60)
    skull(ch, bun, (1.5, 1.1, 0.5), 4.15)                                  # bottom bun
    H(ch, (0, 0, 4.45), (1.6, 1.2, 0.2), (110, 60, 30))                    # patty
    H(ch, (0, 0, 4.6), (1.7, 1.25, 0.08), (255, 200, 40))                  # cheese
    H(ch, (0, 0, 4.7), (1.75, 1.3, 0.08), (90, 190, 70))                   # lettuce
    H(ch, (0, 0, 5.05), (1.55, 1.15, 0.6), bun)                            # top bun
    for (x, y) in ((-0.4, -0.3), (0.3, 0.1), (0, -0.45), (0.45, -0.2)):
        H(ch, (x, y, 5.37), (0.12, 0.06, 0.04), (250, 240, 200))           # sesame
    eyes(ch, -0.58, 5.05, 0.3, 0.26)
    mouth(ch, -0.61, 4.47, 0.6, True)
    crown(ch, z=5.55)
    RA(ch, (-0.89, -0.3, 2.0), (0.2, 0.6, 0.4), ch.glow(GOLD))            # golden fries box
    for dy in (-0.15, 0, 0.15):
        RA(ch, (-0.89, -0.3 + dy, 2.35), (0.06, 0.06, 0.3), (255, 220, 90))
    return ch


def food_icecream():
    ch = Char("ScoopJudge")
    robe_rgb = (30, 30, 40)
    body(ch, (240, 200, 170), shirt=robe_rgb, pants=robe_rgb, shoes=BLACK, cuff=WHITE)
    robe(ch, robe_rgb, trim=(255, 140, 190))
    cone, waffle = (225, 165, 85), (180, 120, 55)
    skull(ch, (255, 240, 220), (1.4, 1.2, 0.6), 4.62)                     # vanilla scoop with the face
    for z, c in ((5.12, (255, 150, 190)), (5.6, (130, 80, 50))):
        H(ch, (0, 0, z), (1.3, 1.1, 0.5), c)                               # strawberry / chocolate
    for x in (-0.4, 0.4):
        H(ch, (x, -0.56, 5.0), (0.2, 0.04, 0.14), (255, 150, 190))         # drips
    for z, w in ((4.22, 1.1), (4.0, 0.7)):
        H(ch, (0, 0, z), (w, w * 0.85, 0.24), cone)                        # cone into the collar
        H(ch, (0, -w * 0.43, z), (w * 0.9, 0.03, 0.04), waffle)
    H(ch, (0, 0, 5.95), (0.25, 0.25, 0.25), ch.glow((230, 30, 50)))       # the cherry
    eyes(ch, -0.61, 4.72, 0.28, 0.24)
    mouth(ch, -0.61, 4.47, 0.3)
    gavel(ch, (255, 150, 190))
    return ch


FOOD = [food_toast, food_egg, food_sushi, food_taco, food_pizza, food_donut, food_burger, food_icecream]


# ============================================================================================= OCEAN
def ocean_crab():
    ch = Char("CrabCounsel")
    red = (225, 70, 50)
    body(ch, red, shirt=(40, 60, 120), pants=red, shoes=shade(red, 0.7), hands=red, cuff=WHITE)
    tie(ch, GOLD)
    for x, side in ((0.95, "Left"), (-0.95, "Right")):                     # big claws instead of hands
        ch.box(f"{side}UpperArm", (x, -0.1, 1.85), (0.5, 0.5, 0.35), red)
        ch.box(f"{side}UpperArm", (x, -0.1, 2.15), (0.5, 0.25, 0.25), red)
    skull(ch, red, (1.5, 0.95, 1.0), 4.4)
    for sx in (1, -1):
        H(ch, (0.3 * sx, -0.2, 5.1), (0.1, 0.1, 0.5), red)                # eye stalks
        eye(ch, 0.3 * sx, -0.27, 5.45, size=0.3)
    mouth(ch, -0.49, 4.3, 0.5, True)
    return ch


def ocean_clownfish():
    ch = Char("ClownfishClerk")
    orange, white = (255, 130, 30), (250, 250, 250)
    body(ch, orange, shirt=orange, pants=(40, 40, 50), shoes=BLACK, hands=orange, cuff=white)
    for z in (2.6, 3.4):
        T(ch, (0, 0, z), (1.47, 0.93, 0.18), white)                       # stripes
    tie(ch, (40, 40, 50))
    skull(ch, orange, (1.35, 1.1, 1.3), 4.6)
    H(ch, (0, 0, 4.8), (1.38, 1.13, 0.2), white)
    H(ch, (0, 0.65, 4.7), (0.12, 0.4, 0.8), orange)                       # dorsal fin
    eyes(ch, -0.56, 4.55, 0.3, 0.3)
    mouth(ch, -0.56, 4.15, 0.28, True)
    legal_pad(ch)
    return ch


def ocean_puffer():
    ch = Char("PufferPartner")
    yel, spot = (240, 210, 90), (190, 150, 60)
    suited(ch, yel, (60, 120, 180), (240, 120, 40), hands=yel)
    skull(ch, yel, (1.7, 1.5, 1.6), 4.75)                                  # puffed up
    for (x, y, z) in ((0.86, 0, 4.8), (-0.86, 0, 4.8), (0, 0, 5.56), (0.6, -0.5, 5.3), (-0.6, -0.5, 5.3),
                      (0.6, 0.5, 5.3), (-0.6, 0.5, 5.3), (0, 0.76, 4.8)):
        H(ch, (x, y, z), (0.12, 0.12, 0.3) if z > 5.2 else (0.3, 0.12, 0.12), (250, 240, 200))   # spikes
    for (x, z) in ((0.5, 5.2), (-0.45, 4.3), (0.55, 4.25)):
        H(ch, (x, -0.76, z), (0.18, 0.03, 0.18), spot)
    eyes(ch, -0.77, 4.95, 0.35, 0.36)
    H(ch, (0, -0.78, 4.4), (0.3, 0.04, 0.3), MOUTH)                        # surprised "o"
    briefcase(ch, (60, 120, 180))
    return ch


def ocean_jelly():
    ch = Char("JellyJuror")
    jelly = (220, 140, 255)
    body(ch, jelly, shirt=(70, 60, 120), pants=jelly, shoes=jelly, hands=jelly, cuff=WHITE)
    tie(ch, (255, 120, 200))
    for x in (-0.55, -0.2, 0.2, 0.55):                                     # trailing tentacles from the hem
        T(ch, (x, 0, 1.75), (0.08, 0.08, 0.8), ch.glass(jelly))
    skull(ch, ch.glass(jelly), (1.6, 1.4, 1.2), 4.75)                      # glowing bell
    H(ch, (0, 0, 4.15), (1.7, 1.5, 0.1), ch.glow((255, 160, 240)))
    H(ch, (0, 0, 4.85), (0.7, 0.6, 0.6), ch.glow((255, 200, 255)))
    eyes(ch, -0.72, 4.75, 0.3, 0.28)
    mouth(ch, -0.72, 4.4, 0.25)
    legal_pad(ch)
    return ch


def ocean_octopus():
    ch = Char("OctoAttorney")
    purple = (170, 80, 190)
    body(ch, purple, shirt=(40, 40, 60), pants=purple, shoes=purple, hands=purple, cuff=WHITE)
    suit_front(ch, (40, 40, 60), (255, 200, 60))
    for i, x in enumerate((-0.7, -0.35, 0.35, 0.7)):                       # extra tentacles... with briefcases
        T(ch, (x * 1.1, -0.1, 1.9), (0.22, 0.22, 0.9), purple, rot_y=25 if x > 0 else -25)
        T(ch, (x * 1.45, -0.15, 1.45), (0.12, 0.5, 0.36), ((130, 80, 40), (40, 40, 46))[i % 2])
    skull(ch, purple, (1.45, 1.3, 1.6), 4.75)
    H(ch, (0, 0.3, 5.5), (1.2, 1.0, 0.5), purple)                          # big head bulge
    for (x, z) in ((0.5, 5.3), (-0.4, 5.6), (0.2, 4.2)):
        H(ch, (x, -0.66, z), (0.16, 0.03, 0.16), (220, 140, 230))
    eyes(ch, -0.66, 4.7, 0.32, 0.34)
    mouth(ch, -0.66, 4.3, 0.3, True)
    briefcase(ch, (130, 80, 40))
    return ch


def ocean_seahorse():
    ch = Char("SeahorseSolicitor")
    teal = (60, 200, 190)
    suited(ch, teal, (230, 120, 60), (60, 60, 160), hands=teal)
    T(ch, (0, 0.55, 2.4), (0.3, 0.3, 0.8), teal)                           # curly tail
    T(ch, (0, 0.65, 1.95), (0.25, 0.3, 0.25), teal)
    skull(ch, teal, (1.0, 1.0, 1.4), 4.65)
    H(ch, (0, -0.75, 4.6), (0.4, 0.6, 0.35), teal)                         # long snout
    H(ch, (0, -1.05, 4.6), (0.3, 0.06, 0.3), shade(teal, 0.7))
    for i in range(4):
        H(ch, (0, 0.3 - i * 0.18, 5.4 + (0.1 if i % 2 else 0)), (0.12, 0.14, 0.35), (255, 180, 80))   # crest
    eyes(ch, -0.51, 4.85, 0.27, 0.26)
    legal_pad(ch)
    return ch


def ocean_whale():
    ch = Char("WhaleJudge")
    blue, belly = (60, 100, 170), (220, 230, 240)
    body(ch, blue, shirt=(30, 30, 40), pants=(30, 30, 40), shoes=BLACK, hands=blue, cuff=WHITE)
    robe(ch, (30, 30, 40), trim=(120, 200, 255))
    skull(ch, blue, (1.7, 1.3, 1.45), 4.68)
    H(ch, (0, -0.66, 4.3), (1.4, 0.04, 0.5), belly)
    for z in (4.18, 4.33, 4.48):
        H(ch, (0, -0.68, z), (1.3, 0.03, 0.03), shade(belly, 0.85))       # throat grooves
    eyes(ch, -0.66, 4.85, 0.45, 0.28)
    mouth(ch, -0.67, 4.6, 0.8)
    for i, (x, h) in enumerate(((-0.25, 0.5), (0, 0.8), (0.25, 0.5))):
        H(ch, (x, 0, 5.4 + h / 2), (0.12, 0.12, h), ch.glow((150, 220, 255)), rot_y=(i - 1) * 25)   # spout
    H(ch, (0, 0, 5.42), (1.5, 1.1, 0.12), (230, 230, 236))                # judge wig band
    for sx in (1, -1):
        H(ch, (0.82 * sx, 0, 4.9), (0.2, 0.9, 0.8), (230, 230, 236))
    gavel(ch, (120, 200, 255))
    return ch


def ocean_kraken():
    ch = Char("KrakenCounsel")
    red, dark = (170, 40, 50), (90, 20, 30)
    body(ch, red, shirt=(20, 20, 26), pants=(20, 20, 26), shoes=dark, hands=red, cuff=GOLD)
    suit_front(ch, (20, 20, 26), (60, 200, 190))
    for i, (x, r) in enumerate(((-0.95, -35), (-0.6, -15), (0.6, 15), (0.95, 35))):
        T(ch, (x, 0.3, 4.2), (0.22, 0.22, 1.2), red, rot_y=r)              # tentacles curling up behind
        T(ch, (x * 1.15, 0.3, 4.85), (0.16, 0.16, 0.3), (255, 180, 170), rot_y=r)
    skull(ch, red, (1.45, 1.2, 1.5), 4.7)
    for (x, z) in ((0.45, 5.2), (-0.5, 5.3), (0.55, 4.3), (-0.4, 4.15)):
        H(ch, (x, -0.61, z), (0.14, 0.03, 0.14), (255, 170, 160))
    eyes(ch, -0.61, 4.75, 0.3, 0.32, pupil=(20, 20, 20), white=(255, 220, 60))
    mouth(ch, -0.62, 4.35, 0.4, True)
    crown(ch, (60, 200, 190), z=5.6, gems=((255, 220, 60),))
    RA(ch, (-0.89, -0.2, 2.6), (0.1, 0.1, 1.8), GOLD)                      # trident
    for dy in (-0.25, 0, 0.25):
        RA(ch, (-0.89, -0.2 + dy, 3.6), (0.08, 0.08, 0.4), GOLD)
    return ch


OCEAN = [ocean_crab, ocean_clownfish, ocean_puffer, ocean_jelly, ocean_octopus, ocean_seahorse, ocean_whale,
         ocean_kraken]


# ============================================================================================= SPACE
def space_moonrock():
    ch = Char("MoonRockRookie")
    rock = (170, 170, 175)
    suited(ch, (240, 200, 170), (60, 70, 100), (230, 200, 60))
    skull(ch, rock, (1.45, 1.1, 1.4), 4.65)
    for (x, z, s) in ((0.45, 5.15, 0.35), (-0.5, 4.3, 0.28), (0.5, 4.2, 0.22), (-0.3, 5.2, 0.2)):
        H(ch, (x, -0.56, z), (s, 0.04, s), shade(rock, 0.75))              # craters
    H(ch, (0.3, 0, 5.4), (0.6, 0.8, 0.2), rock)                            # lumpy top
    eyes(ch, -0.56, 4.75, 0.25, 0.28)
    mouth(ch, -0.57, 4.5, 0.3)
    legal_pad(ch)
    return ch


def space_alien():
    ch = Char("LittleGreenLawyer")
    green = (110, 220, 90)
    suited(ch, green, (40, 40, 50), (160, 80, 220), hands=green)
    skull(ch, green, (1.5, 1.0, 1.4), 4.66)
    for sx in (1, -1):
        H(ch, (0.32 * sx, -0.51, 4.8), (0.5, 0.05, 0.6), BLACK)            # big alien eyes
        H(ch, (0.25 * sx, -0.54, 4.95), (0.1, 0.03, 0.12), WHITE)
        H(ch, (0.35 * sx, 0, 5.6), (0.06, 0.06, 0.6), green, rot_y=-15 * sx)   # antennae
        H(ch, (0.45 * sx, 0, 5.92), (0.18, 0.18, 0.18), ch.glow((200, 255, 120)))
    mouth(ch, -0.51, 4.25, 0.25)
    briefcase(ch, (160, 80, 220))
    return ch


def space_astronaut():
    ch = Char("AstroAttorney")
    suit = (240, 240, 245)
    body(ch, (240, 200, 170), shirt=suit, pants=suit, shoes=(150, 150, 160), sleeves=suit, cuff=(230, 120, 40),
         hands=(200, 200, 210))
    T(ch, (0, -0.47, 3.2), (0.6, 0.05, 0.5), (60, 70, 100))                # chest panel
    for i, c in enumerate(((230, 60, 60), (60, 200, 90), (60, 140, 230))):
        T(ch, (-0.18 + i * 0.18, -0.5, 3.2), (0.1, 0.04, 0.1), c)
    T(ch, (0, 0.55, 3.1), (1.1, 0.3, 1.3), (200, 200, 210))                # backpack
    tie(ch, (230, 120, 40), z_top=3.75)
    skull(ch, ch.glass((180, 220, 255)), (1.5, 1.4, 1.5), 4.68)            # glass helmet
    H(ch, (0, 0, 4.62), (1.0, 0.8, 1.1), (240, 200, 170))                  # the face inside
    eyes(ch, -0.41, 4.75, 0.22, 0.24)
    mouth(ch, -0.41, 4.4, 0.24, True)
    H(ch, (0, 0, 3.98), (1.4, 1.3, 0.14), suit)                            # neck ring
    RA(ch, (-0.89, -0.3, 2.0), (0.1, 0.5, 0.5), (60, 140, 230))            # flag
    RA(ch, (-0.89, -0.3, 2.7), (0.04, 0.04, 1.0), (180, 180, 190))
    return ch


def space_robot():
    ch = Char("RoboClerk")
    metal, dark = (190, 200, 215), (80, 90, 105)
    body(ch, metal, shirt=metal, pants=metal, shoes=dark, hands=dark, cuff=dark)
    T(ch, (0, -0.47, 3.1), (0.8, 0.05, 0.7), dark)
    T(ch, (0, -0.5, 3.1), (0.5, 0.04, 0.12), ch.glow((80, 220, 255)))
    tie(ch, (230, 60, 60), z_top=3.8)
    skull(ch, metal, (1.4, 0.95, 1.3), 4.62)
    H(ch, (0, -0.48, 4.62), (1.15, 0.04, 0.9), (20, 30, 44))               # screen face
    for sx in (1, -1):
        H(ch, (0.28 * sx, -0.51, 4.75), (0.26, 0.03, 0.26), ch.glow((80, 220, 255)))
        H(ch, (0.74 * sx, 0, 4.62), (0.14, 0.4, 0.4), dark)               # ear bolts
    H(ch, (0, -0.51, 4.38), (0.5, 0.03, 0.08), ch.glow((80, 220, 255)))
    H(ch, (0, 0, 5.55), (0.08, 0.08, 0.5), dark)
    H(ch, (0, 0, 5.85), (0.2, 0.2, 0.2), ch.glow((255, 80, 80)))
    legal_pad(ch)
    return ch


def space_saturn():
    ch = Char("SaturnSolicitor")
    planet, ring = (240, 200, 120), (200, 160, 220)
    suited(ch, (240, 200, 170), (60, 40, 110), (240, 200, 120))
    skull(ch, planet, (1.4, 1.1, 1.4), 4.66)
    for z in (4.35, 4.95):
        H(ch, (0, 0, z), (1.42, 1.12, 0.12), shade(planet, 0.85))         # bands
    H(ch, (0, 0, 4.66), (2.6, 2.0, 0.08), ring, rot_y=-12)                # the ring
    eyes(ch, -0.56, 4.8, 0.27, 0.28)
    mouth(ch, -0.57, 4.42, 0.3, True)
    briefcase(ch, (60, 40, 110))
    return ch


def space_ufo():
    ch = Char("UFOCounsel")
    green = (120, 230, 100)
    suited(ch, green, (90, 90, 110), (120, 230, 100), hands=green)
    skull(ch, green, (1.2, 0.9, 1.2), 4.6)
    for sx in (1, -1):
        H(ch, (0.28 * sx, -0.46, 4.7), (0.42, 0.05, 0.5), BLACK)
    mouth(ch, -0.46, 4.25, 0.24)
    H(ch, (0, 0, 5.35), (2.4, 2.0, 0.2), (180, 185, 200))                  # flying saucer hat
    H(ch, (0, 0, 5.5), (1.4, 1.2, 0.2), (150, 155, 170))
    H(ch, (0, 0, 5.8), (0.9, 0.8, 0.5), ch.glass((160, 230, 255)))         # dome
    for (x, y) in ((1.0, 0), (-1.0, 0), (0, -0.85), (0, 0.85), (0.7, -0.6), (-0.7, -0.6)):
        H(ch, (x, y, 5.25), (0.16, 0.16, 0.08), ch.glow((255, 230, 80)))
    RA(ch, (-0.89, -0.3, 2.0), (0.12, 0.4, 0.5), (60, 60, 70))              # tractor-beam remote
    RA(ch, (-0.89, -0.3, 2.3), (0.14, 0.14, 0.14), ch.glow((120, 255, 120)))
    return ch


def space_star():
    ch = Char("StarJudge")
    star = (255, 225, 80)
    body(ch, (240, 200, 170), shirt=(20, 20, 50), pants=(20, 20, 50), shoes=BLACK, cuff=WHITE)
    robe(ch, (20, 20, 50), trim=star)
    for (x, z) in ((0.4, 3.4), (-0.3, 2.6), (0.2, 2.2), (-0.45, 3.6)):
        T(ch, (x, -0.52, z), (0.1, 0.03, 0.1), ch.glow(WHITE))             # stars on the robe
    skull(ch, ch.glow(star), (1.3, 0.8, 1.3), 4.62)                        # glowing star head
    for (x, z, r) in ((0, 5.5, 0), (0.72, 4.85, 72), (-0.72, 4.85, -72), (0.45, 3.95, 144), (-0.45, 3.95, -144)):
        H(ch, (x, 0, z), (0.5, 0.6, 0.6), ch.glow(star), rot_y=r)          # 5 points
    eyes(ch, -0.42, 4.72, 0.27, 0.28)
    mouth(ch, -0.43, 4.38, 0.3, True)
    gavel(ch, ch.glow(star))
    return ch


def space_blackhole():
    ch = Char("BlackHoleBarrister")
    void, rim = (20, 10, 35), (170, 90, 255)
    body(ch, (200, 160, 230), shirt=(30, 20, 60), pants=(30, 20, 60), shoes=BLACK, cuff=ch.glow(rim))
    suit_front(ch, (30, 20, 60), ch.glow(rim), shirt=(15, 10, 25))
    for (x, z) in ((0.45, 3.5), (-0.4, 2.7), (0.3, 2.4), (-0.5, 3.3)):
        T(ch, (x, -0.47, z), (0.08, 0.03, 0.08), ch.glow(WHITE))
    skull(ch, void, (1.4, 0.9, 1.4), 4.66)
    for w, c in ((2.2, (120, 60, 220)), (1.8, (220, 120, 255)), (1.5, (255, 200, 120))):
        H(ch, (0, 0, 4.66), (w, w * 0.8, 0.06), ch.glow(c), rot_y=-15)    # glowing accretion rings
    eyes(ch, -0.47, 4.8, 0.27, 0.28, pupil=(255, 255, 255), white=(120, 60, 220))
    mouth(ch, -0.47, 4.4, 0.3)
    RA(ch, (-0.89, -0.3, 2.0), (0.4, 0.4, 0.4), ch.glow(rim))              # orb
    return ch


SPACE = [space_moonrock, space_alien, space_astronaut, space_robot, space_saturn, space_ufo, space_star,
         space_blackhole]

# rarity of each lawyer, same order: 2 Common, 2 Uncommon, 2 Rare, 2 Legendary
EGG_RARITY = [1, 1, 2, 2, 3, 3, 4, 4]


# ============================================================================================ CLIENTS
def person(cid, skin, shirt, pants, shoes=(60, 50, 45), hair=(80, 50, 30), mouth_="smile", brow=None,
           sleeves=None, cuff=None, fringe=True, hair_on=True, legs_skin=False, tilt=-5):
    ch = Char(cid)
    body(ch, skin, shirt=shirt, pants=pants, shoes=shoes, sleeves=sleeves, cuff=cuff, legs_skin=legs_skin)
    face(ch, skin, brow=brow or shade(hair, 0.8), brow_tilt=tilt, mouth=mouth_)
    if hair_on:
        hair_cap(ch, hair, fringe=fringe)
    return ch


def c_mailcarrier():
    ch = person("MailCarrierMo", (200, 140, 100), (90, 120, 190), (60, 80, 140), hair=(30, 22, 18), hair_on=False)
    cap(ch, (60, 80, 140), logo=WHITE)
    T(ch, (0.3, -0.5, 2.6), (0.6, 0.15, 0.6), (140, 90, 50))               # mail bag
    T(ch, (-0.2, -0.47, 3.3), (0.08, 0.04, 1.2), (110, 70, 40), rot_y=-40)
    RA(ch, (-0.89, -0.25, 2.0), (0.06, 0.5, 0.35), WHITE)                  # letter
    return ch


def c_lemonade():
    ch = person("LemonadeLily", (240, 200, 170), (255, 220, 60), (255, 220, 60), shoes=(255, 120, 160),
                hair=(200, 120, 50), legs_skin=True, fringe=False)
    for sx in (1, -1):
        H(ch, (0.72 * sx, 0.1, 4.7), (0.3, 0.3, 0.3), (200, 120, 50))      # pigtails
    both_legs(ch, lambda x, leg: ch.box(leg, (x * 1.15, 0, 1.8), (0.6, 0.6, 0.8), (255, 220, 60)))
    RA(ch, (-0.89, -0.3, 2.0), (0.35, 0.35, 0.5), ch.glass((255, 240, 120)))
    return ch


def c_gamer():
    ch = person("GamerGabe", (180, 120, 85), (60, 60, 70), (50, 70, 120), shoes=WHITE, hair=(30, 22, 18))
    T(ch, (0, -0.47, 3.2), (0.6, 0.04, 0.4), ch.glow((80, 255, 120)))
    H(ch, (0, 0, 5.45), (1.5, 0.2, 0.12), (40, 40, 46))                    # headset
    for sx in (1, -1):
        H(ch, (0.72 * sx, 0, 4.75), (0.18, 0.45, 0.5), (40, 40, 46))
    H(ch, (0.5, -0.45, 4.3), (0.08, 0.3, 0.08), (40, 40, 46), rot_x=30)
    RA(ch, (-0.89, -0.3, 2.0), (0.14, 0.6, 0.3), (40, 40, 46))
    return ch


def c_gardener():
    ch = person("GardenerGus", (230, 180, 140), (200, 70, 60), (70, 110, 60), hair=(150, 150, 150), hair_on=False)
    T(ch, (0, -0.47, 2.8), (1.0, 0.04, 1.4), (70, 110, 60))                # overalls bib
    H(ch, (0, 0, 5.4), (2.0, 1.6, 0.08), (230, 200, 120))                  # straw hat
    H(ch, (0, 0, 5.6), (1.2, 0.9, 0.4), (230, 200, 120))
    H(ch, (0, -0.47, 4.25), (0.7, 0.05, 0.12), (150, 150, 150))            # mustache
    RA(ch, (-0.89, -0.3, 1.9), (0.4, 0.4, 0.4), (255, 140, 30))            # little pumpkin
    RA(ch, (-0.89, -0.3, 2.15), (0.08, 0.08, 0.12), (80, 140, 60))
    return ch


def c_icecream():
    ch = person("IceCreamIvy", (150, 100, 70), (255, 160, 200), (60, 60, 80), hair=(40, 25, 20))
    T(ch, (0, -0.47, 2.7), (1.0, 0.04, 1.2), WHITE)                        # apron
    H(ch, (0, 0, 5.45), (1.4, 0.9, 0.3), WHITE)                            # paper hat
    RA(ch, (-0.89, -0.3, 2.0), (0.2, 0.2, 0.4), (220, 160, 80))
    RA(ch, (-0.89, -0.3, 2.35), (0.3, 0.3, 0.3), (180, 240, 200))
    return ch


def c_barber():
    ch = person("BarberBob", (230, 180, 140), WHITE, (40, 40, 50), hair=(20, 20, 24))
    for i in range(3):
        T(ch, (0, -0.47, 3.4 - i * 0.4), (1.2, 0.04, 0.1), (220, 40, 40))  # barber stripes
    H(ch, (0, 0, 5.5), (1.42, 0.88, 0.16), (20, 20, 24))                   # slick pompadour
    H(ch, (0, -0.35, 5.6), (1.0, 0.4, 0.25), (20, 20, 24))
    RA(ch, (-0.89, -0.3, 2.0), (0.04, 0.4, 0.12), (200, 200, 210))         # comb
    return ch


def c_crossing():
    ch = person("CrossingGuardCarol", (240, 200, 170), (255, 150, 30), (60, 60, 80), hair=(150, 80, 40))
    for z in (2.6, 3.3):
        T(ch, (0, 0, z), (1.47, 0.93, 0.1), (230, 255, 120))              # reflective stripes
    RA(ch, (-0.89, -0.2, 2.8), (0.08, 0.08, 1.6), (180, 180, 190))         # stop sign
    RA(ch, (-0.89, -0.2, 3.7), (0.06, 0.7, 0.7), (220, 40, 40))
    RA(ch, (-0.93, -0.2, 3.7), (0.02, 0.5, 0.14), WHITE)
    return ch


def c_librarian():
    ch = person("LibrarianLou", (230, 190, 160), (120, 90, 60), (80, 70, 60), hair=(200, 200, 205), fringe=False)
    glasses(ch, (60, 40, 30))
    H(ch, (0, 0.3, 5.5), (0.6, 0.5, 0.4), (200, 200, 205))                 # bun
    T(ch, (0, -0.47, 3.4), (0.4, 0.04, 0.8), (240, 230, 210))
    RA(ch, (-0.89, -0.3, 2.0), (0.3, 0.6, 0.8), (60, 90, 170))             # huge overdue book
    RA(ch, (-0.93, -0.3, 2.0), (0.24, 0.62, 0.7), (250, 245, 230))
    return ch


def c_camper():
    ch = person("CamperCam", (210, 160, 120), (90, 130, 70), (150, 120, 70), hair=(120, 70, 30), hair_on=False)
    H(ch, (0, 0, 5.4), (1.8, 1.5, 0.08), (130, 100, 60))                   # ranger hat
    H(ch, (0, 0, 5.6), (1.0, 0.8, 0.4), (130, 100, 60))
    T(ch, (0, 0.6, 3.0), (1.1, 0.4, 1.4), (200, 90, 50))                   # backpack
    T(ch, (0, 0.6, 3.85), (1.2, 0.5, 0.3), (60, 100, 160))                 # bedroll
    T(ch, (0, -0.47, 3.75), (0.5, 0.05, 0.2), (220, 60, 40))               # scarf
    return ch


def c_yoga():
    ch = person("YogaYasmin", (190, 130, 95), (120, 200, 190), (80, 60, 140), shoes=(190, 130, 95),
                hair=(30, 20, 15), fringe=False)
    H(ch, (0, 0.2, 5.6), (0.5, 0.5, 0.5), (30, 20, 15))                    # top knot
    H(ch, (0, -0.4, 5.15), (1.4, 0.06, 0.12), (255, 120, 160))              # headband
    RA(ch, (-0.89, -0.1, 2.2), (0.3, 0.3, 1.4), (160, 100, 220))           # rolled mat
    return ch


def c_firefighter():
    ch = person("FirefighterFaye", (240, 200, 170), (200, 40, 30), (60, 60, 60), hair=(220, 140, 60), hair_on=False)
    for z in (2.4, 3.2):
        T(ch, (0, 0, z), (1.47, 0.93, 0.1), (230, 255, 120))
    H(ch, (0, 0, 5.45), (1.5, 1.0, 0.35), (230, 180, 40))                  # helmet
    H(ch, (0, 0.2, 5.3), (1.7, 1.4, 0.08), (230, 180, 40))
    H(ch, (0, -0.5, 5.4), (0.4, 0.06, 0.3), GOLD)
    RA(ch, (-0.89, -0.3, 2.0), (0.16, 0.7, 0.16), (100, 100, 110))         # hose nozzle
    return ch


def c_magician():
    ch = person("MagicianMarvin", (230, 190, 160), (30, 30, 40), (30, 30, 40), hair=(20, 20, 24), hair_on=False)
    T(ch, (0, 0.5, 2.8), (1.6, 0.1, 2.2), (150, 30, 40))                   # cape
    T(ch, (0, -0.47, 3.75), (0.36, 0.05, 0.14), (150, 30, 40))
    tophat(ch, (30, 30, 40), band=(150, 30, 40))
    H(ch, (0, -0.46, 4.25), (0.6, 0.05, 0.1), (20, 20, 24))                # thin mustache
    RA(ch, (-0.89, -0.3, 2.3), (0.06, 0.06, 0.9), BLACK, rot_x=20)         # wand
    RA(ch, (-0.89, -0.45, 2.7), (0.08, 0.08, 0.15), WHITE, rot_x=20)
    return ch


def c_farmer():
    ch = person("FarmerFrank", (220, 160, 120), (200, 60, 60), (60, 90, 160), hair=(90, 60, 30), hair_on=False)
    T(ch, (0, -0.47, 2.8), (1.0, 0.04, 1.4), (60, 90, 160))
    cap(ch, (90, 140, 60), logo=GOLD)
    RA(ch, (-0.89, -0.2, 2.6), (0.08, 0.08, 1.8), (150, 110, 60))          # hay fork
    for dy in (-0.15, 0, 0.15):
        RA(ch, (-0.89, -0.2 + dy, 3.6), (0.05, 0.05, 0.35), (170, 170, 180))
    return ch


def c_nurse():
    ch = person("NurseNina", (200, 140, 100), (120, 200, 220), (120, 200, 220), shoes=WHITE, hair=(40, 25, 20))
    T(ch, (0.4, -0.47, 3.4), (0.2, 0.04, 0.2), (220, 40, 40))
    H(ch, (0, -0.1, 5.45), (0.8, 0.6, 0.2), WHITE)                          # nurse cap
    T(ch, (0, -0.47, 3.6), (0.7, 0.04, 0.06), (60, 60, 70))                # stethoscope
    RA(ch, (-0.89, -0.32, 1.95), (0.06, 0.6, 0.8), (180, 220, 255))        # clipboard
    return ch


def c_mechanic():
    ch = person("MechanicMax", (190, 130, 95), (90, 100, 110), (90, 100, 110), hair=(30, 22, 18))
    T(ch, (-0.3, -0.47, 2.6), (0.3, 0.04, 0.2), (40, 40, 40))              # grease smudge
    H(ch, (0.35, -0.42, 4.35), (0.2, 0.03, 0.1), (40, 40, 40))
    cap(ch, (220, 60, 40))
    RA(ch, (-0.89, -0.2, 2.1), (0.08, 0.08, 0.8), (170, 175, 185))         # wrench
    RA(ch, (-0.89, -0.2, 2.55), (0.12, 0.3, 0.16), (170, 175, 185))
    return ch


def c_artist():
    ch = person("ArtistAria", (240, 200, 170), (240, 240, 245), (60, 60, 80), hair=(20, 20, 24))
    for (x, z, c) in ((0.3, 3.2, (230, 60, 60)), (-0.2, 2.7, (60, 140, 230)), (0.1, 2.4, (255, 210, 40))):
        T(ch, (x, -0.47, z), (0.2, 0.04, 0.2), c)                          # paint splats
    H(ch, (0.15, 0, 5.45), (1.3, 1.0, 0.18), (150, 30, 60), rot_y=-10)     # beret
    RA(ch, (-0.89, -0.3, 2.0), (0.06, 0.8, 0.6), (200, 160, 100))          # palette
    for i, c in enumerate(((230, 60, 60), (60, 140, 230), (255, 210, 40))):
        RA(ch, (-0.93, -0.5 + i * 0.2, 2.1), (0.03, 0.12, 0.12), c)
    return ch


def c_wrestler():
    ch = person("WrestlerRonda", (210, 160, 120), (230, 50, 140), (230, 50, 140), shoes=(40, 40, 50),
                hair=(255, 200, 60), sleeves=(210, 160, 120), cuff=(210, 160, 120), tilt=12)
    H(ch, (0, -0.4, 4.7), (1.36, 0.04, 0.7), (40, 200, 220))               # mask
    T(ch, (0, -0.47, 2.25), (1.5, 0.08, 0.35), GOLD)                       # champion belt
    T(ch, (0, -0.52, 2.25), (0.5, 0.04, 0.4), ch.glow((255, 240, 150)))
    return ch


def c_pilot():
    ch = person("PilotPaige", (240, 200, 170), (40, 50, 80), (40, 50, 80), hair=(200, 120, 50))
    T(ch, (0.4, -0.47, 3.5), (0.4, 0.04, 0.1), GOLD)                       # wings badge
    for z in (2.25,):
        both_arms(ch, lambda x, arm: ch.box(arm, (x, 0, 2.4), (0.3, 0.33, 0.06), GOLD))   # sleeve stripes
    cap(ch, (40, 50, 80), logo=GOLD)
    glasses(ch, (40, 40, 46), shades=True)
    return ch


def c_musician():
    ch = person("MusicianMoe", (180, 120, 85), (230, 120, 40), (60, 60, 80), hair=(30, 22, 18))
    RA(ch, (-0.89, -0.35, 2.4), (0.5, 0.5, 0.8), GOLD)                      # tuba
    RA(ch, (-0.89, -0.35, 3.05), (0.8, 0.8, 0.3), GOLD)
    RA(ch, (-0.89, -0.35, 3.05), (0.6, 0.6, 0.32), (60, 50, 30))
    return ch


def c_pirate():
    ch = person("PiratePatches", (220, 160, 120), (240, 240, 230), (60, 40, 30), shoes=BLACK, hair=(30, 20, 15),
                hair_on=False, tilt=12, mouth_="grin")
    T(ch, (0, 0, 2.3), (1.48, 0.95, 0.2), (200, 40, 40))                   # sash
    H(ch, (0.28, -0.5, 4.6), (0.45, 0.05, 0.42), BLACK)                    # eyepatch
    H(ch, (0, -0.48, 4.1), (0.9, 0.12, 0.35), (60, 40, 25))                # beard
    H(ch, (0, 0, 5.4), (1.8, 1.0, 0.25), (30, 30, 36))                     # tricorn
    H(ch, (0, -0.48, 5.5), (0.24, 0.03, 0.2), WHITE)
    RA(ch, (-0.89, -0.15, 1.9), (0.08, 0.3, 0.3), (180, 180, 190))         # hook
    T(ch, (0.85, 0, 4.15), (0.3, 0.3, 0.4), (60, 200, 80))                 # parrot on the shoulder
    T(ch, (0.85, -0.2, 4.2), (0.1, 0.1, 0.1), GOLD)
    return ch


def c_cowboy():
    ch = person("CowboyCody", (220, 160, 120), (200, 80, 60), (60, 80, 140), shoes=(110, 70, 40),
                hair=(150, 100, 50), hair_on=False)
    T(ch, (0, -0.47, 3.0), (1.2, 0.04, 1.5), (130, 90, 50))                # vest
    T(ch, (0, -0.5, 3.0), (0.4, 0.04, 1.5), (200, 80, 60))
    T(ch, (0, -0.52, 2.3), (0.3, 0.04, 0.2), GOLD)                         # belt buckle
    H(ch, (0, 0, 5.38), (2.0, 1.5, 0.1), (150, 100, 50))                   # cowboy hat
    H(ch, (0, 0, 5.65), (1.1, 0.9, 0.5), (150, 100, 50))
    RA(ch, (-0.89, -0.3, 2.0), (0.1, 0.7, 0.7), (200, 170, 110))            # lasso coil
    return ch


def c_zombie():
    ch = person("ZombieZeke", (140, 190, 120), (100, 110, 140), (70, 70, 80), shoes=(60, 60, 60),
                hair=(60, 70, 50), mouth_="o", brow=(50, 60, 40))
    for (x, z) in ((0.4, 2.6), (-0.3, 3.3), (0.2, 3.6)):
        T(ch, (x, -0.47, z), (0.25, 0.04, 0.18), (140, 190, 120))         # torn holes
    H(ch, (-0.3, -0.42, 4.95), (0.3, 0.03, 0.06), (80, 110, 70))           # stitches
    for dx in (-0.1, 0, 0.1):
        H(ch, (-0.3 + dx, -0.43, 4.95), (0.02, 0.03, 0.15), (60, 60, 60))
    return ch


def c_ninja():
    ch = person("NinjaNoodle", (230, 190, 160), (30, 30, 40), (30, 30, 40), shoes=(30, 30, 40),
                hair=(30, 30, 40), fringe=False)
    H(ch, (0, -0.4, 4.25), (1.36, 0.04, 0.4), (30, 30, 40))                # face wrap
    H(ch, (0, -0.4, 5.15), (1.4, 0.06, 0.18), (220, 40, 40))               # headband
    H(ch, (0, 0.45, 5.1), (0.2, 0.4, 0.15), (220, 40, 40))
    T(ch, (0, 0, 2.5), (1.48, 0.95, 0.15), (220, 40, 40))
    RA(ch, (-0.89, -0.25, 2.0), (0.1, 0.5, 0.06), (200, 200, 210))         # (rubber) throwing star
    RA(ch, (-0.89, -0.25, 2.0), (0.1, 0.06, 0.5), (200, 200, 210))
    return ch


def c_knight():
    steel = (180, 185, 195)
    ch = person("KnightKevin", (230, 190, 160), steel, steel, shoes=shade(steel, 0.7), hair_on=False)
    T(ch, (0, -0.47, 3.0), (0.5, 0.04, 1.6), (40, 80, 200))                # tabard
    H(ch, (0, 0, 4.7), (1.42, 0.9, 1.25), steel)                           # helmet
    H(ch, (0, -0.47, 4.7), (1.0, 0.04, 0.12), BLACK)                       # visor slit
    H(ch, (0, 0, 5.5), (0.15, 0.6, 0.6), (220, 40, 40))                    # plume
    RA(ch, (-0.89, -0.2, 2.6), (0.08, 0.2, 1.6), (230, 230, 240))          # foam sword
    RA(ch, (-0.89, -0.2, 1.85), (0.1, 0.5, 0.1), GOLD)
    return ch


def c_mermaid():
    teal = (60, 190, 170)
    ch = person("MermaidMarina", (240, 200, 170), (180, 120, 220), teal, shoes=teal, hair=(230, 90, 120), fringe=False)
    H(ch, (0, 0.42, 4.5), (1.42, 0.16, 1.7), (230, 90, 120))               # long hair
    T(ch, (0, -0.47, 3.5), (0.9, 0.04, 0.3), (255, 220, 230))              # shell top
    both_legs(ch, lambda x, leg: ch.box(leg, (x * 0.6, 0, 1.0), (0.5, 0.5, 2.0), teal))   # tail
    T(ch, (0, -0.3, 0.1), (1.3, 0.3, 0.2), shade(teal, 0.8))               # tail fin
    crown(ch, (255, 220, 230), z=5.45, gems=((60, 190, 170),))
    return ch


def c_clown():
    ch = person("ClownChuckles", (250, 240, 235), (255, 200, 40), (60, 120, 230), shoes=(230, 40, 40),
                hair=(255, 90, 40), mouth_="grin", hair_on=False)
    for (x, c) in ((-0.35, (230, 40, 40)), (0.35, (60, 200, 90))):
        T(ch, (x, -0.47, 3.0), (0.25, 0.04, 0.25), c)                     # polka dots
    both_legs(ch, lambda x, leg: ch.box(leg, (x, -0.35, 0.14), (0.5, 1.2, 0.28), (230, 40, 40)))   # big shoes
    H(ch, (0, -0.48, 4.45), (0.26, 0.2, 0.26), (230, 30, 40))              # red nose
    for sx in (1, -1):
        H(ch, (0.68 * sx, 0, 5.1), (0.4, 0.6, 0.5), (255, 90, 40))        # rainbow wig puffs
        H(ch, (0.6 * sx, 0, 5.45), (0.3, 0.5, 0.3), (60, 120, 230))
    return ch


def c_techbillionaire():
    ch = person("TechTed", (230, 190, 160), (30, 30, 34), (60, 70, 90), shoes=WHITE, hair=(120, 90, 60))
    glasses(ch, (40, 40, 46))
    RA(ch, (-0.89, -0.22, 2.0), (0.12, 0.26, 0.5), (40, 40, 46))           # phone
    RA(ch, (-0.95, -0.22, 2.0), (0.02, 0.22, 0.42), ch.glow((120, 200, 255)))
    return ch


def c_moviestar():
    ch = person("MovieStarMaya", (200, 140, 100), (200, 30, 60), (200, 30, 60), shoes=GOLD, hair=(30, 20, 15),
                fringe=False)
    H(ch, (0, 0.42, 4.6), (1.42, 0.16, 1.5), (30, 20, 15))
    glasses(ch, (40, 40, 46), shades=True)
    both_legs(ch, lambda x, leg: ch.box(leg, (x * 1.1, 0, 1.0), (0.66, 0.66, 2.0), (200, 30, 60)))   # gown
    T(ch, (0, -0.5, 3.75), (0.8, 0.06, 0.12), ch.glow(WHITE))              # diamond necklace
    RA(ch, (-0.89, -0.3, 2.3), (0.06, 0.5, 0.5), ch.glow(GOLD))            # her star
    return ch


def c_king():
    ch = person("KingReginald", (230, 190, 160), (150, 30, 60), (150, 30, 60), shoes=GOLD, hair=(200, 200, 205),
                fringe=False)
    robe(ch, (150, 30, 60))
    T(ch, (0, -0.5, 3.75), (1.3, 0.1, 0.3), WHITE)
    H(ch, (0, -0.48, 4.05), (0.9, 0.12, 0.4), (200, 200, 205))             # royal beard
    crown(ch, z=5.48, gems=((230, 30, 60), (40, 160, 255), (60, 200, 90)))
    RA(ch, (-0.89, -0.2, 2.6), (0.12, 0.12, 1.6), GOLD)                    # sceptre
    RA(ch, (-0.89, -0.2, 3.45), (0.3, 0.3, 0.3), ch.glow((40, 160, 255)))
    return ch


def c_astronaut():
    suit = (240, 240, 245)
    ch = person("AstronautAce", (180, 120, 85), suit, suit, shoes=(150, 150, 160), sleeves=suit,
                cuff=(60, 120, 230), hair_on=False)
    T(ch, (0, 0.55, 3.1), (1.1, 0.3, 1.3), (200, 200, 210))
    T(ch, (0.4, -0.47, 3.4), (0.3, 0.04, 0.2), (60, 120, 230))
    H(ch, (0, 0, 4.7), (1.5, 1.3, 1.5), ch.glass((180, 220, 255)))
    H(ch, (0, 0, 3.98), (1.4, 1.3, 0.14), suit)
    RA(ch, (-0.89, -0.3, 2.0), (0.4, 0.4, 0.3), (170, 170, 175))           # moon rock souvenir
    return ch


# (id, tier, name, situation, builder) - tiers index Config.Clients (1 Common .. 4 Epic)
CLIENTS = [
    ("MailCarrierMo", 1, "Mail Carrier Mo", "Bitten by a very small, very angry dog", c_mailcarrier),
    ("LemonadeLily", 1, "Lemonade Lily", "Her lemonade stand got shut down for 'too much lemon'", c_lemonade),
    ("GamerGabe", 1, "Gamer Gabe", "Banned from the arcade for winning too much", c_gamer),
    ("GardenerGus", 1, "Gardener Gus", "His prize pumpkin rolled into the neighbor's pool", c_gardener),
    ("IceCreamIvy", 1, "Ice Cream Ivy", "Her truck's jingle is 'too catchy'", c_icecream),
    ("BarberBob", 1, "Barber Bob", "Gave a customer a haircut that was 'too stylish'", c_barber),
    ("CrossingGuardCarol", 1, "Crossing Guard Carol", "Stopped traffic for a duck family. For 3 hours.", c_crossing),
    ("LibrarianLou", 1, "Librarian Lou", "Charged a $9,000 late fee for one book", c_librarian),
    ("CamperCam", 1, "Camper Cam", "His tent blew into the mayor's garden", c_camper),
    ("YogaYasmin", 1, "Yoga Yasmin", "A goat at goat yoga ate her mat", c_yoga),
    ("FirefighterFaye", 2, "Firefighter Faye", "Rescued a cat that did NOT want to be rescued", c_firefighter),
    ("MagicianMarvin", 2, "Magician Marvin", "His rabbit disappeared and never came back", c_magician),
    ("FarmerFrank", 2, "Farmer Frank", "His cow keeps winning the county pie contest", c_farmer),
    ("NurseNina", 2, "Nurse Nina", "Prescribed 'more naps' and her boss objected", c_nurse),
    ("MechanicMax", 2, "Mechanic Max", "Fixed a car so well it drives itself now", c_mechanic),
    ("ArtistAria", 2, "Artist Aria", "Painted the mayor's portrait... upside down", c_artist),
    ("WrestlerRonda", 2, "Wrestler Ronda", "Body-slammed a vending machine that stole her dollar", c_wrestler),
    ("PilotPaige", 2, "Pilot Paige", "Landed on the wrong island (it was nicer)", c_pilot),
    ("MusicianMoe", 2, "Musician Moe", "Neighbors sued over 4am tuba practice", c_musician),
    ("PiratePatches", 3, "Pirate Patches", "Buried treasure in a public park", c_pirate),
    ("CowboyCody", 3, "Cowboy Cody", "His horse got a speeding ticket", c_cowboy),
    ("ZombieZeke", 3, "Zombie Zeke", "Showed up to work 'a little too undead'", c_zombie),
    ("NinjaNoodle", 3, "Ninja Noodle", "Was too sneaky at a surprise party", c_ninja),
    ("KnightKevin", 3, "Knight Kevin", "Jousted a shopping cart", c_knight),
    ("MermaidMarina", 3, "Mermaid Marina", "Her concert flooded the town square", c_mermaid),
    ("ClownChuckles", 3, "Chuckles the Clown", "Fit 40 people in one tiny car", c_clown),
    ("TechTed", 4, "Tech Billionaire Ted", "His robot vacuums formed a union", c_techbillionaire),
    ("MovieStarMaya", 4, "Movie Star Maya", "Her stunt double wants the credit", c_moviestar),
    ("KingReginald", 4, "King Reginald", "His crown is stuck. Who's liable?", c_king),
    ("AstronautAce", 4, "Astronaut Ace", "Left a footprint on the moon without a permit", c_astronaut),
]

EGGS = {"Pet": PET, "Food": FOOD, "Ocean": OCEAN, "Space": SPACE}


def all_builders():
    out = []
    for fns in EGGS.values():
        out += fns
    out += [c[4] for c in CLIENTS]
    return out


def build_all(show=None):
    coll = bpy.data.collections.get("ThemedCast")
    if coll:
        for o in list(coll.objects):
            bpy.data.objects.remove(o, do_unlink=True)
    else:
        coll = bpy.data.collections.new("ThemedCast")
        bpy.context.scene.collection.children.link(coll)
    chars = [fn() for fn in all_builders()]
    mat = lv.preview_material()
    for i, ch in enumerate(chars):
        row, col = divmod(i, 8)
        objs = ch.build(coll, mat, (col - 3.5) * 3.2)
        for o in objs:
            o.location.y = 6 + row * 5
            o.hide_viewport = bool(show) and not any(o.name.startswith(n + "_") for n in show)
    return coll


M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def export_rows():
    out = {}
    for fn in all_builders():
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
                    name = "Head" if not head_done else "HeadDetail"
                    head_done = True
                flag = 1 if rgb in ch.neon else 2 if rgb in ch.glassy else 0
                rows.append([name, round(pos.x, 4), round(pos.y, 4), round(pos.z, 4),
                             round(s.x, 4), round(s.z, 4), round(s.y, 4)]
                            + [round(rot_r[i][j], 5) for i in range(3) for j in range(3)] + list(rgb) + [flag])
        out[ch.cid] = rows
    with open(os.path.join(TOOLS, "themed_parts.json"), "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return {k: len(v) for k, v in out.items()}
