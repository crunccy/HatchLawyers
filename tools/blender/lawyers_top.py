# tools/blender/lawyers_top.py - the 18 Epic / Mythic / Supreme lawyers (2026-10-13, mr.robe: "add the supreme, mythic,
# and epic [lawyers] described in the github by crnuch. the mythic and supreme should be significantly cooler than the
# legendary, be more complex in style, and larger in general" + "create these in blender"). Concepts: crnuch's table in
# docs/CHARACTER_STYLE.md ("Epic, Mythic and Supreme"); the brick style + rarity ladder from the same doc.
#   Epic     (1.0x)  purple trim, one big standout feature, a couple of glowing accents
#   Mythic   (1.3x)  crimson + gold trim, a HUGE signature (wings, flame mane, horn, fire breath), Neon accents
#   Supreme  (1.6x)  rainbow trim, glowing eyes, halos / crowns / orbiting pieces, the most detail
# Moving bits carry an "fx" that Shared.Puppet plays on top of the limb (wings flap, tails sway, halos and planets
# turn, clouds bob) - at the desk and in the hatch.
# Built with tools/blender/brickkit.py in Roblox model space; exports tools/zones/lawyers_top.json for
# tools/zones/BuildLawyersTop.lua (-> ReplicatedStorage.SkinModels.<Id>) and renders art/lawyers/top_preview.png.
# Run: tools/blender/send.ps1 -File tools/blender/lawyers_top.py
import bpy, math, json, os, sys, importlib

REPO = r"C:\Users\siddi\OneDrive\Documents\HatchLawyers"
sys.path.insert(0, os.path.join(REPO, "tools", "blender"))
import brickkit
importlib.reload(brickkit)
from brickkit import Kit, C, RAINBOW, D, hexc, V, armX, legX, hipY, shoulderY, headY, headTop, faceZ, arm_name, leg_name, rot_matrix
from mathutils import Matrix, Vector

OUT_JSON = os.path.join(REPO, "tools", "zones", "lawyers_top.json")
OUT_PNG = os.path.join(REPO, "art", "lawyers", "top_preview.png")
H = hexc
EPIC, CRIMSON, GOLD, GOLD_D, WHITE, INK = C["Epic"], C["Crimson"], C["Gold"], C["GoldDark"], C["White"], C["Ink"]
SCALE = {4: 1.0, 6: 1.3, 7: 1.6}
FLAP = lambda side, amp=11, rate=0.65: dict(kind="osc", axis=[0, 0, side], amp=amp, rate=rate)
SWAY = lambda amp=10, rate=0.55, phase=0.0: dict(kind="osc", axis=[0, 1, 0], amp=amp, rate=rate, phase=phase)
SPIN = lambda speed, pivot, axis=(0, 1, 0): dict(kind="rot", axis=list(axis), amp=speed, pivot=list(pivot))
BOB = lambda amp=0.12, rate=0.5, phase=0.0: dict(kind="bob", axis=[0, 1, 0], amp=amp, rate=rate, phase=phase)
FLICK = lambda phase=0.0: dict(kind="osc", axis=[1, 0, 0], amp=9, rate=2.2, phase=phase)

L = {}


def lawyer(id, rarity, egg=""):
    def deco(fn):
        L[id] = (rarity, egg, fn)
        return fn
    return deco


def rainbow_band(k, name, size, y, z=0.0, x0=None, axis="x"):
    """A strip of the six rainbow colours (Supreme trim)."""
    n = len(RAINBOW)
    for i, c in enumerate(RAINBOW):
        if axis == "x":
            w = size[0] / n
            x = -size[0] / 2 + w * (i + 0.5) + (x0 or 0)
            k.glow(name, (w, size[1], size[2]), (x, y, z), c)
        else:
            h = size[1] / n
            k.glow(name, (size[0], h, size[2]), (x0 or 0, y + size[1] / 2 - h * (i + 0.5), z), c)


def suit(k, jacket, pants, shirt=None, lapel=None, tie=None, shoes=None, skin=None, depth=0.85):
    k.body(skin or H("e8b087"), jacket, pants, shoes or INK)
    k.lapels(jacket, shirt or WHITE, depth, lapel)
    if tie:
        k.tie(tie)


def spikes_ring(k, name, centre, radius, n, size, col, out=25, up=0.0, surf="brick"):
    for i in range(n):
        a = 2 * math.pi * i / n
        pos = (centre[0] + math.cos(a) * radius, centre[1] + up, centre[2] + math.sin(a) * radius)
        k.wedge(name, size, pos, col, (0, -math.degrees(a) + 90, 0), surf)


# ===================================================================================== EPIC
@lawyer("ThunderclapCounsel", 4)
def _(k):
    COAT, DARK, BOLT, SKIN, HAIR, CLOUD, CLOUD_D = H("3c3f58"), H("23242f"), H("ffd23c"), H("e8b087"), H("e6ecf5"), H("8a90a6"), H("5c6278")
    k.body(SKIN, COAT, DARK, INK)
    k.lapels(COAT, H("1c1c26"), 0.95, DARK)
    # a lightning-bolt tie (Neon zigzag)
    z = k.front() - 0.1
    for (x, y, h, r) in ((0.0, 2.62, 0.22, 0), (0.06, 2.38, 0.34, 28), (-0.06, 2.1, 0.32, -28), (0.05, 1.84, 0.3, 28)):
        k.glow("UpperTorso", (0.16, h, 0.05), (x, y, z), BOLT, (0, 0, r))
    k.coat(COAT, 0.9, True, 0.35, EPIC, DARK)
    k.armBand(shoulderY - 1.0, 0.1, EPIC)
    for s in (-1, 1):  # storm-collar flaps
        k.wedge("UpperTorso", (0.55, 0.5, 0.35), (s * 0.62, shoulderY + 0.1, -0.2), COAT, (0, 0, s * 12))
    # electric white hair, spikes standing up
    k.hairCap(HAIR, 0.15, 1.0, 0.6)
    for i, x in enumerate((-0.7, -0.35, 0, 0.35, 0.7)):
        k.wedge("HeadDetail", (0.32, 0.65 + (i % 2) * 0.2, 0.5), (x, headTop + 0.42, -0.1 + (i % 2) * 0.3), HAIR, (-10, 0, -x * 25))
    k.eyes(look=(0.0, 0.1))
    k.brows(H("c8ccd6"), tilt=10)
    k.nose()
    k.mouth("smirk", w=0.42)
    # his own little storm cloud overhead, a bolt dripping from it
    cy = headTop + 1.65
    for (x, y, zz, w) in ((0, 0, 0, 1.3), (-0.65, -0.12, 0.05, 0.9), (0.62, -0.1, -0.05, 1.0), (-0.25, 0.32, 0.1, 0.9), (0.3, 0.28, -0.1, 0.8)):
        k.brick("HeadDetail", (w, w * 0.62, w * 0.75), (x, cy + y, zz), CLOUD if y >= 0 else CLOUD_D, fx=BOB(0.1, 0.45))
    for (x, y, h, r) in ((0.1, cy - 0.65, 0.4, 25), (-0.02, cy - 0.98, 0.36, -25), (0.08, cy - 1.26, 0.28, 25)):
        k.glow("HeadDetail", (0.12, h, 0.1), (x, y, 0), BOLT, (0, 0, r), fx=BOB(0.1, 0.45))
    # a briefcase crackling with purple sparks
    k.held(-1, (1.0, 0.75, 0.3), (0, -0.55, -0.1), DARK)
    k.held(-1, (0.4, 0.12, 0.12), (0, -0.12, -0.1), H("3c3f58"))
    for (x, y) in ((-0.35, -0.4), (0.3, -0.7), (0.0, -0.95)):
        k.held(-1, (0.12, 0.3, 0.05), (x, y, -0.27), EPIC, (0, 0, 35), "neon")


@lawyer("WolfWarden", 4, "Pet")
def _(k):
    COAT, COAT_D, FUR, FUR_L, FUR_D, MOON = H("23305a"), H("1c2440"), H("8c8c96"), H("d4d4dc"), H("5a5a66"), H("fff4b4")
    k.body(FUR, COAT, COAT_D, INK, hands=FUR)
    k.coat(COAT, 1.0, True, 0.4, EPIC, COAT_D)
    k.lapels(COAT, H("e6e2d6"), 0.8, COAT_D)
    k.belt(H("3a2a20"), GOLD)
    # the moon badge (a glowing crescent)
    z = k.front() - 0.06
    k.glow("UpperTorso", (0.34, 0.34, 0.05), (0.6, shoulderY - 0.45, z), MOON)
    k.plate("UpperTorso", (0.26, 0.3, 0.05), (0.68, shoulderY - 0.42, z - 0.02), COAT)
    # wolf head: grey with a pale muzzle snout, pointed ears, amber eyes, a fang
    k.plate("HeadDetail", (1.3, 0.75, 0.05), (0, headY - 0.45, faceZ - 0.03), FUR_L)
    k.brick("HeadDetail", (0.95, 0.6, 0.6), (0, headY - 0.45, faceZ - 0.3), FUR_L)
    k.brick("HeadDetail", (0.42, 0.26, 0.2), (0, headY - 0.28, faceZ - 0.62), INK)
    k.plate("HeadDetail", (0.5, 0.08, 0.04), (0, headY - 0.62, faceZ - 0.62), C["Mouth"])
    for s in (-1, 1):
        k.plate("HeadDetail", (0.09, 0.14, 0.04), (s * 0.16, headY - 0.71, faceZ - 0.62), C["Teeth"])
        k.wedge("HeadDetail", (0.6, 0.85, 0.35), (s * 0.68, headTop + 0.35, 0.15), FUR, (0, 0, s * -8))
        k.plate("HeadDetail", (0.3, 0.45, 0.05), (s * 0.68, headTop + 0.3, -0.04), H("e8a0a8"), (0, 0, s * -8))
        k.brick("HeadDetail", (0.18, 0.6, 1.2), (s * 1.08, headY - 0.1, 0.25), FUR_D)  # cheek ruff
    k.brick("HeadDetail", (2.12, 0.22, 2.0), (0, headTop - 0.05, 0.05), FUR_D)
    k.eyes(y=0.18, w=0.46, h=0.42, pupil=H("e6a020"), look=(0, 0.1))
    k.brows(FUR_D, y=0.18, h=0.42, tilt=14)
    # the huge bushy tail, swaying
    root = (0, hipY - 0.1, k.td / 2 + 0.15)
    for i, (y, z, w, c) in enumerate(((0.0, 0.35, 0.7, FUR), (0.35, 0.8, 0.95, FUR), (0.8, 1.15, 1.05, FUR_D), (1.35, 1.35, 0.95, FUR), (1.85, 1.4, 0.75, FUR_L))):
        k.brick("UpperTorso", (w, 0.75, w), (0, root[1] + y, root[2] + z), c, (25 - i * 10, 0, 0), fx=dict(SWAY(14, 0.5), pivot=list(root)))
    # a glowing lantern in his hand (the night watch)
    k.held(1, (0.08, 0.5, 0.08), (0, -0.4, -0.3), INK)
    k.held(1, (0.5, 0.6, 0.5), (0, -0.85, -0.3), H("2a2a32"))
    k.held(1, (0.36, 0.42, 0.36), (0, -0.85, -0.3), EPIC, surf="neon")


@lawyer("CactusinoAvvocatino", 4, "Brainrot")
def _(k):
    SUIT, PANTS, CACT, CACT_D, CACT_L, SPINE, PETAL, STACHE = H("5a2e96"), H("37235a"), H("4caf50"), H("2f8a3a"), H("7ed36e"), H("f2efe8"), H("ff6eb4"), H("3a2418")
    k.body(CACT, SUIT, PANTS, INK, hands=CACT)
    k.lapels(SUIT, WHITE, 0.8, PANTS)
    k.tie(EPIC)
    k.armBand(shoulderY - 1.0, 0.1, EPIC)
    # the head grows up into a tall cactus (taller than the head block), ridges and spines
    k.brick("HeadDetail", (1.7, 1.4, 1.6), (0, headTop + 0.62, 0), CACT)
    k.brick("HeadDetail", (1.3, 0.4, 1.2), (0, headTop + 1.5, 0), CACT)
    for x in (-0.55, 0.0, 0.55):
        k.plate("HeadDetail", (0.12, 3.0, 0.05), (x, headY + 0.75, faceZ - 0.02), CACT_D)
    for (x, y) in ((-0.8, 3.2), (0.82, 3.5), (-0.3, 4.9), (0.35, 5.3), (-0.75, 5.0), (0.78, 4.6), (0.0, 5.75)):
        k.plate("HeadDetail", (0.06, 0.06, 0.25), (x, y, faceZ - 0.12), SPINE)
    # its own little cactus arms coming out of the head
    for s in (-1, 1):
        k.brick("HeadDetail", (0.6, 0.5, 0.55), (s * 1.25, headY + 0.6, 0), CACT)
        k.brick("HeadDetail", (0.5, 1.0, 0.5), (s * 1.48, headY + 1.05, 0), CACT_L)
        k.plate("HeadDetail", (0.06, 0.06, 0.25), (s * 1.48, headY + 1.25, -0.3), SPINE)
    # a big pink flower on top
    for i in range(6):
        a = i * 60
        k.plate("HeadDetail", (0.45, 0.12, 0.25), (0.36 * math.cos(math.radians(a)), headTop + 1.78, 0.36 * math.sin(math.radians(a))), PETAL, (0, -a, 15))
    k.brick("HeadDetail", (0.3, 0.2, 0.3), (0, headTop + 1.82, 0), GOLD)
    k.eyes(y=0.1, look=(-0.4, 0.3), inward=-0.3)
    k.brows(CACT_D, tilt=-6)
    k.mustache = None
    k.brick("HeadDetail", (0.9, 0.18, 0.12), (0, headY - 0.38, faceZ - 0.08), STACHE)
    for s in (-1, 1):
        k.brick("HeadDetail", (0.22, 0.16, 0.12), (s * 0.55, headY - 0.3, faceZ - 0.08), STACHE, (0, 0, s * 30))
    k.mouth("grin", y=-0.62, w=0.42)
    # a tiny espresso cup
    k.held(1, (0.36, 0.3, 0.36), (0, 0.0, -0.45), WHITE)
    k.held(1, (0.3, 0.06, 0.3), (0, 0.16, -0.45), H("4a2c18"), surf="plate")


@lawyer("ChiliProsecutor", 4, "Food")
def _(k):
    SUIT, PANTS, CHILI, CHILI_D, STEM, ORANGE, SAUCE = H("24242c"), H("1a1a20"), H("e53927"), H("b8281c"), H("3c9a32"), H("ff8c1e"), H("d8281e")
    k.body(CHILI, SUIT, PANTS, INK, hands=H("e8b087"))
    k.lapels(SUIT, ORANGE, 0.9, H("16161c"))
    k.tie(EPIC)
    k.armBand(shoulderY - 1.0, 0.1, EPIC)
    k.badge(ORANGE, -0.6, shoulderY - 0.45, 0.26, 0.14)
    # the chili head: taller, glossy, curving to a point
    k.brick("HeadDetail", (1.9, 0.7, 1.7), (0, headTop + 0.3, 0), CHILI)
    k.plate("HeadDetail", (0.3, 1.7, 0.05), (-0.55, headY + 0.4, faceZ - 0.02), H("ff6e50"))
    k.brick("HeadDetail", (1.5, 0.5, 1.4), (0, headTop + 0.88, 0), CHILI_D)
    k.brick("HeadDetail", (0.9, 0.45, 0.9), (0.2, headTop + 1.25, 0.1), CHILI_D, (0, 0, -15))
    # the curly green stem
    k.brick("HeadDetail", (1.0, 0.25, 1.0), (0, headTop + 0.12, 0), STEM)
    k.brick("HeadDetail", (0.3, 0.6, 0.3), (0.35, headTop + 1.62, 0.1), STEM, (0, 0, -30))
    k.brick("HeadDetail", (0.5, 0.25, 0.25), (0.65, headTop + 1.85, 0.1), STEM, (0, 0, 20))
    # HOT: little Neon flames on the stem's tip
    for i, (x, h, c) in enumerate(((0.85, 0.5, ORANGE), (0.95, 0.35, H("ffd23c")), (0.78, 0.3, H("ff5a1e")))):
        k.glow("HeadDetail", (0.16, h, 0.16), (x, headTop + 2.05 + h / 2, 0.1), c, fx=FLICK(i))
    k.eyes(y=0.05, look=(0, 0.2))
    k.brows(INK, tilt=22, thick=0.17)
    k.mouth("grin", w=0.5)
    k.plate("HeadDetail", (0.18, 0.28, 0.04), (0.85, headY + 0.45, faceZ - 0.03), H("7cc8f0"))  # sweat drop
    # a bottle of hot sauce
    k.held(-1, (0.42, 0.75, 0.42), (0, 0.1, -0.45), SAUCE)
    k.held(-1, (0.3, 0.3, 0.05), (0, 0.15, -0.67), WHITE, surf="plate")
    k.held(-1, (0.22, 0.3, 0.22), (0, 0.62, -0.45), WHITE)
    k.poseArm(-1, (25, 0, 0))


@lawyer("HammerheadAdvocate", 4, "Ocean")
def _(k):
    SUIT, PANTS, SKIN, BELLY, SKIN_D = H("1e2a4a"), H("141c34"), H("7896aa"), H("eef2f5"), H("5a7488")
    k.body(SKIN, SUIT, PANTS, INK, hands=SKIN)
    k.lapels(SUIT, BELLY, 0.9, PANTS)
    k.tie(EPIC)
    k.armBand(shoulderY - 1.0, 0.1, EPIC)
    k.buttons(2, GOLD, 0.0, hipY + 0.55, 0.3)
    # the hammer: a wide flat bar across the head, eyes on the ends
    hy = headY + 0.45
    k.brick("HeadDetail", (4.0, 0.7, 1.3), (0, hy, -0.05), SKIN)
    k.plate("HeadDetail", (4.0, 0.08, 1.3), (0, hy - 0.39, -0.05), BELLY)
    for s in (-1, 1):
        k.brick("HeadDetail", (0.5, 0.5, 0.5), (s * 2.05, hy, -0.1), SKIN_D)
        k.eye(s * 2.0, hy + 0.02, 0.36, 0.4, (0, 0), z=-0.42)
    k.plate("HeadDetail", (1.6, 0.85, 0.05), (0, headY - 0.45, faceZ - 0.02), BELLY)
    k.mouth("grin", y=-0.55, w=1.0, h=0.3)
    for i in range(5):
        k.wedge("HeadDetail", (0.14, 0.14, 0.05), (-0.36 + i * 0.18, headY - 0.47, faceZ - 0.07), C["Teeth"], (0, 0, 180))
    for i in range(3):  # gills
        k.plate("HeadDetail", (0.05, 0.36, 0.05), (1.04, headY - 0.3, -0.35 + i * 0.22), SKIN_D)
    # the dorsal fin
    k.wedge("HeadDetail", (0.18, 1.2, 1.0), (0, headTop + 0.5, 0.55), SKIN_D)
    k.wedge("UpperTorso", (0.14, 0.8, 0.7), (0, shoulderY - 0.4, k.td / 2 + 0.35), SKIN_D)
    # a gavel-shaped... hammer, of course
    k.held(1, (0.12, 0.9, 0.12), (0, 0.35, -0.3), H("2a1e18"))
    k.held(1, (0.36, 0.36, 0.7), (0, 0.85, -0.3), SKIN_D)
    k.held(1, (0.38, 0.38, 0.06), (0, 0.85, -0.1), EPIC, surf="plate")
    k.poseArm(1, (30, 0, 0))


@lawyer("CometCounsel", 4, "Space")
def _(k):
    SUIT, SUIT_D, ICE, ICE_L, ICE_D, TAIL1, TAIL2 = H("eef0f8"), H("b4b8cc"), H("a8d8ff"), H("dcf0ff"), H("6aa8e6"), H("8ad4ff"), H("e6f6ff")
    k.body(ICE, SUIT, SUIT_D, H("8a90a6"), hands=SUIT_D)
    k.torsoBand(shoulderY - 0.1, 0.16, SUIT_D)  # helmet ring collar
    k.badge(EPIC, 0, shoulderY - 0.65, 0.6, 0.4)
    k.badge(ICE, 0, shoulderY - 0.65, 0.4, 0.22, glow=True)
    k.armBand(shoulderY - 0.45, 0.12, EPIC)
    k.legBand(0.55, 0.12, EPIC)
    k.belt(SUIT_D, EPIC)
    # the comet head: faceted ice with sharp crystals
    for (x, y, z, sx, sy, sz, c, r) in ((0.6, 4.75, 0.2, 0.7, 0.9, 0.7, ICE_L, (10, 20, -25)), (-0.55, 4.7, 0.3, 0.6, 0.75, 0.6, ICE_L, (-5, 10, 30)),
                                       (0.0, 4.85, -0.25, 0.65, 0.8, 0.6, ICE, (15, 0, 5)), (1.0, 3.9, 0.1, 0.4, 0.6, 0.6, ICE_D, (0, 0, -40)),
                                       (-1.0, 4.1, 0.2, 0.4, 0.55, 0.55, ICE_D, (0, 0, 40))):
        k.brick("HeadDetail", (sx, sy, sz), (x, y, z), c, r)
    k.eyes(y=0.05, look=(0, 0.1), white=H("f6fbff"))
    k.brows(ICE_D, tilt=6)
    k.mouth("smile", w=0.46)
    # the comet tail: streaming back and up, fading to white, glowing
    for i in range(7):
        f = i / 6
        k.glow("HeadDetail", (1.4 - f * 0.9, 0.9 - f * 0.55, 0.9), (0.15 * math.sin(i), headY + 0.4 + f * 1.1, 1.1 + i * 0.75), TAIL1 if i % 2 == 0 else TAIL2,
               (-25, 0, 0), fx=dict(SWAY(6, 0.7, i * 0.4), pivot=[0, headY + 0.3, 0.9]))
    # a little glowing star in hand
    k.held(1, (0.4, 0.4, 0.1), (0, -0.05, -0.45), H("fff4a0"), (0, 0, 45), "neon", fx=SPIN(90, tuple(k.hand(1) + V((0, -0.05, -0.45))), (0, 0, 1)))


# ===================================================================================== MYTHIC
def flame_tongue(k, name, base, h, w, cols, phase, lean=(0, 0, 0)):
    for j, (fr, c) in enumerate(zip((1.0, 0.72, 0.45), cols)):
        k.glow(name, (w * fr, h * (0.7 - j * 0.12), w * fr), (base[0], base[1] + h * (0.28 + j * 0.28), base[2]), c, lean,
               fx=dict(FLICK(phase + j * 0.5), pivot=list(base)))


FIRE = (H("ff3c14"), H("ff8c1e"), H("ffd23c"))
CRIMSON_FIRE = (H("b4141e"), H("e53935"), H("ff8c64"))


@lawyer("PhoenixProsecutor", 6)
def _(k):
    SUIT, DARK, ORANGE, SKIN = H("c62828"), H("3a1010"), H("ff8c1e"), H("c68a5e")
    k.body(SKIN, SUIT, DARK, DARK)
    k.lapels(SUIT, H("1a0a0a"), 0.95, DARK)
    k.tie(GOLD, glow=True)
    k.coat(SUIT, 1.05, True, 0.4, GOLD, DARK)
    k.pauldron(DARK, GOLD, True)
    k.belt(DARK, GOLD)
    k.armBand(shoulderY - 1.0, 0.1, GOLD, glow=True)
    for y in (hipY + 0.6, hipY + 0.95):
        k.plate("UpperTorso", (0.12, 0.12, 0.05), (0, y, k.front(0.06)), GOLD)
    # face + glowing ember eyes
    k.eyes(y=0.05, look=(0, 0.1), pupil=ORANGE, glowPupil=True)
    k.brows(DARK, tilt=16, thick=0.16)
    k.nose()
    k.mouth("smirk", w=0.44)
    # the FLAME MANE: tongues of fire all round the head, licking upward (flickering)
    k.hairCap(H("8a1810"), 0.12, 1.3, 0.8)
    i = 0
    for x in (-1.0, -0.5, 0.0, 0.5, 1.0):
        for z in (-0.45, 0.25, 0.85):
            h = 1.1 + 0.5 * math.cos(x * 2 + z) + (0.3 if z > 0 else 0)
            flame_tongue(k, "HeadDetail", (x, headTop + 0.1, z), h, 0.42, FIRE, i * 0.6, (z * -20, 0, -x * 18))
            i += 1
    for s in (-1, 1):
        for y in (headY + 0.4, headY - 0.2):
            flame_tongue(k, "HeadDetail", (s * 1.12, y, 0.4), 0.8, 0.34, FIRE, i * 0.6, (0, 0, -s * 55))
            i += 1
    # BLAZING WINGS: feathered, fire at the tips, flapping
    for s in (-1, 1):
        root = (s * 0.55, shoulderY - 0.15, k.td / 2 + 0.12)
        k.wing(s, root, H("b8281c"), H("ff8c1e"), length=3.8, rows=5, spread=55, fx=FLAP(s, 13, 0.6), glowTips=True)
        for j in range(4):  # trailing fire along the wing's top edge
            p = Vector(root) + Vector((s * (0.9 + j * 0.8), 0.6 + j * 0.55, 0.5 + j * 0.15))
            flame_tongue(k, "UpperTorso", tuple(p), 0.7, 0.3, FIRE, j * 0.7 + s, (0, 0, -s * 30))
    # the FLAMING GAVEL
    k.held(1, (0.14, 1.1, 0.14), (0, 0.4, -0.35), GOLD)
    k.held(1, (0.42, 0.42, 0.8), (0, 1.0, -0.35), DARK)
    for dz in (-0.3, 0.3):
        k.held(1, (0.46, 0.46, 0.08), (0, 1.0, -0.35 + dz), GOLD, surf="plate")
    for j in range(3):
        k.held(1, (0.3 - j * 0.07, 0.55 - j * 0.1, 0.3 - j * 0.07), (0, 1.45 + j * 0.25, -0.35), FIRE[j], surf="neon", fx=FLICK(j))
    k.poseArm(1, (35, 0, -10))
    # embers rising round the feet
    for j in range(6):
        a = j * 60
        k.glow("UpperTorso", (0.14, 0.14, 0.14), (math.cos(math.radians(a)) * 1.3, 0.4 + (j % 3) * 0.5, math.sin(math.radians(a)) * 1.0), FIRE[j % 3],
               fx=BOB(0.25, 0.7, j))


@lawyer("GryphonGuardian", 6, "Pet")
def _(k):
    GOLDA, GOLDA_D, CAPE, WHITEF, BEAK, BROWN, BROWN_D, TAN = H("c8963c"), H("8e6428"), H("e53935"), H("f2efe8"), H("ffb428"), H("7a4a24"), H("5a341a"), H("d8b070")
    k.body(WHITEF, GOLDA, BROWN, BROWN_D, hands=BEAK)
    # gold armour: breastplate, plates, a crimson tabard
    k.torsoBand(shoulderY - 0.2, 0.3, GOLDA_D)
    k.plate("UpperTorso", (1.6, 1.1, 0.08), (0, hipY + 0.75, k.front(0.04)), GOLD)
    k.plate("UpperTorso", (0.9, 1.3, 0.06), (0, hipY + 0.05, k.front(0.1)), CAPE)
    k.glow("UpperTorso", (0.36, 0.36, 0.06), (0, hipY + 0.95, k.front(0.12)), H("ff5050"), (0, 0, 45))
    k.pauldron(GOLD, CRIMSON, True)
    k.boots(BROWN_D, 0.7, GOLD)
    k.cape(CAPE, 2.6, GOLD, GOLDA_D, fx=dict(kind="osc", axis=[1, 0, 0], amp=4, rate=0.4))
    # eagle head: white feathers, a big hooked golden beak, fierce eyes, feather crest
    k.brick("HeadDetail", (2.1, 0.5, 1.9), (0, headTop + 0.1, 0.05), WHITEF)
    k.brick("HeadDetail", (0.75, 0.55, 0.7), (0, headY - 0.3, faceZ - 0.32), BEAK)
    k.brick("HeadDetail", (0.55, 0.4, 0.4), (0, headY - 0.55, faceZ - 0.72), BEAK)
    k.wedge("HeadDetail", (0.4, 0.3, 0.3), (0, headY - 0.82, faceZ - 0.75), GOLDA_D, (180, 0, 0))
    k.eyes(y=0.25, w=0.44, h=0.38, pupil=H("ff3c14"), glowPupil=True)
    k.brows(BROWN_D, y=0.25, h=0.38, tilt=24, thick=0.16)
    for i, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
        k.wedge("HeadDetail", (0.3, 0.9 + (i % 2) * 0.3, 0.6), (x, headTop + 0.6, 0.4), GOLD if i % 2 else WHITEF, (-25, 0, -x * 20))
    # GIANT WINGS (brown + gold feathers), flapping slowly
    for s in (-1, 1):
        root = (s * 0.6, shoulderY - 0.1, k.td / 2 + 0.2)
        k.wing(s, root, BROWN, GOLD, length=4.4, rows=5, spread=50, fx=FLAP(s, 9, 0.45), feather=(0.6, 0.14, 1.2))
    # lion tail with a tuft
    root = (0, hipY - 0.05, k.td / 2 + 0.1)
    for i in range(5):
        k.brick("UpperTorso", (0.28, 0.6, 0.28), (0, root[1] - 0.2 - i * 0.15 + i * i * 0.06, root[2] + 0.25 + i * 0.42), TAN, (60 - i * 18, 0, 0),
                fx=dict(SWAY(16, 0.5), pivot=list(root)))
    k.brick("UpperTorso", (0.55, 0.7, 0.55), (0, root[1] + 0.55, root[2] + 2.2), BROWN_D, fx=dict(SWAY(16, 0.5), pivot=list(root)))
    # a spear with a glowing tip
    k.held(-1, (0.14, 4.2, 0.14), (0, 0.9, -0.35), BROWN_D)
    k.held(-1, (0.3, 0.6, 0.12), (0, 3.15, -0.35), GOLD, (0, 0, 45))
    k.held(-1, (0.18, 0.45, 0.1), (0, 3.15, -0.35), H("ff5050"), (0, 0, 45), "neon")


@lawyer("DraghettoSpaghetto", 6, "Brainrot")
def _(k):
    VEST, VEST_D, SAUCE, PASTA, PASTA_D, MEAT, BASIL = H("2e5a2e"), H("1e3c1e"), H("c8281e"), H("f0d282"), H("d8b45a"), H("8a4a2a"), H("3cb43c")
    k.body(PASTA, VEST, VEST_D, INK, hands=PASTA)
    k.lapels(VEST, PASTA, 0.8, VEST_D)
    k.plate("UpperTorso", (0.6, 0.35, 0.06), (0, shoulderY - 0.25, k.front(0.08)), SAUCE)  # a napkin bib
    k.armBand(shoulderY - 1.0, 0.1, GOLD, glow=True)
    # a dragon's head made of noodles: a long snout, strands hanging, sauce horns, meatball cheeks
    k.brick("HeadDetail", (1.4, 0.8, 1.1), (0, headY - 0.35, faceZ - 0.45), PASTA)
    k.brick("HeadDetail", (1.2, 0.3, 0.6), (0, headY - 0.85, faceZ - 0.55), PASTA_D)
    for s in (-1, 1):
        k.brick("HeadDetail", (0.2, 0.2, 0.15), (s * 0.35, headY - 0.05, faceZ - 1.0), INK)  # nostrils
        k.brick("HeadDetail", (0.6, 0.6, 0.6), (s * 1.05, headY - 0.45, faceZ - 0.05), MEAT)  # meatball cheeks
        k.plate("HeadDetail", (0.15, 0.15, 0.05), (s * 1.0, headY - 0.3, faceZ - 0.36), H("b06a40"))
        for j in range(3):  # sauce horns curving back
            k.brick("HeadDetail", (0.32 - j * 0.07, 0.45, 0.32 - j * 0.07), (s * (0.6 + j * 0.12), headTop + 0.15 + j * 0.38, 0.1 + j * 0.25), SAUCE, (-25 - j * 10, 0, s * -10))
        for j in range(4):  # noodle strands down the sides of the head
            k.plate("HeadDetail", (0.08, 1.2, 0.08), (s * 1.04, headY + 0.1, -0.6 + j * 0.4), PASTA_D, (0, 0, s * 6))
    for j in range(7):  # noodle mane on top
        k.brick("HeadDetail", (0.14, 0.14, 1.9), (-0.84 + j * 0.28, headTop + 0.05, 0.1), PASTA if j % 2 else PASTA_D, (0, 0, 0))
    for (x, z) in ((-0.4, -0.3), (0.3, 0.2), (0.0, 0.5)):
        k.plate("HeadDetail", (0.3, 0.06, 0.2), (x, headTop + 0.14, z), BASIL, (0, 30, 0))
    k.eyes(y=0.35, w=0.44, h=0.48, look=(0.5, 0.2), inward=0.2)
    k.brows(SAUCE, y=0.35, h=0.48, tilt=15)
    k.plate("HeadDetail", (0.8, 0.12, 0.04), (0, headY - 0.75, faceZ - 1.01), C["Mouth"])
    # FIRE BREATH: a cone of flame roaring forward out of the snout
    for j in range(7):
        f = j / 6
        k.glow("HeadDetail", (0.35 + f * 0.9, 0.35 + f * 0.9, 0.5), (0, headY - 0.55 - f * 0.25, faceZ - 1.2 - j * 0.45), FIRE[j % 3],
               (0, 0, j * 15), fx=FLICK(j * 0.4))
    # lasagne wings (wavy pasta sheets) + a noodle tail
    for s in (-1, 1):
        root = (s * 0.5, shoulderY - 0.2, k.td / 2 + 0.1)
        for j in range(4):
            k.brick("UpperTorso", (1.0, 0.1, 0.9), (s * (0.9 + j * 0.85), shoulderY + 0.2 + j * 0.35, k.td / 2 + 0.4 + j * 0.15), PASTA if j % 2 else PASTA_D,
                    (0, 0, s * (20 + j * 6)), fx=dict(FLAP(s, 14, 0.6), pivot=list(root)))
            k.plate("UpperTorso", (1.0, 0.04, 0.12), (s * (0.9 + j * 0.85), shoulderY + 0.26 + j * 0.35, k.td / 2 + 0.05 + j * 0.15), SAUCE,
                    (0, 0, s * (20 + j * 6)), fx=dict(FLAP(s, 14, 0.6), pivot=list(root)))
    root = (0, hipY, k.td / 2 + 0.1)
    for j in range(8):
        k.brick("UpperTorso", (0.2, 0.2, 0.5), (0.25 * math.sin(j * 0.9), hipY - 0.3 + 0.05 * j, k.td / 2 + 0.3 + j * 0.42), PASTA if j % 2 else PASTA_D,
                fx=dict(SWAY(18, 0.6, j * 0.3), pivot=list(root)))
    # a fork twirling spaghetti
    k.held(1, (0.1, 1.3, 0.1), (0, 0.3, -0.35), H("c8ccd6"))
    k.held(1, (0.5, 0.5, 0.5), (0, 1.0, -0.35), PASTA_D, fx=SPIN(120, tuple(k.hand(1) + V((0, 1.0, -0.35)))))
    k.held(1, (0.25, 0.25, 0.25), (0.15, 1.3, -0.4), MEAT)


@lawyer("DragonFruitDuke", 6, "Food")
def _(k):
    COAT, COAT_D, FRUIT, FRUIT_D, SCALEG, FLESH, SEED, LEAF = H("1e5a3c"), H("143c28"), H("ff3c96"), H("d8287a"), H("8ad84a"), H("fbfaf6"), H("1c1c20"), H("3ca050")
    k.body(FRUIT, COAT, COAT_D, INK, hands=H("f2d0b0"))
    k.lapels(COAT, FLESH, 0.9, COAT_D)
    k.tie(CRIMSON)
    k.coat(COAT, 1.1, True, 0.45, GOLD, COAT_D)
    k.pauldron(COAT_D, GOLD, True)
    for y in (hipY + 0.45, hipY + 0.8, hipY + 1.15):
        for s in (-1, 1):
            k.plate("UpperTorso", (0.36, 0.06, 0.05), (s * 0.45, y, k.front(0.08)), GOLD)  # frogging
    k.cape(FLESH, 2.5, CRIMSON, COAT_D, fx=dict(kind="osc", axis=[1, 0, 0], amp=4, rate=0.4))
    for j in range(14):  # the cape is a slice of dragon fruit: white with black seeds
        k.plate("UpperTorso", (0.08, 0.12, 0.04), (-0.95 + (j * 0.37) % 1.9, shoulderY - 0.3 - (j * 0.53) % 2.0, k.td / 2 + 0.2), SEED,
                fx=dict(kind="osc", axis=[1, 0, 0], amp=4, rate=0.4, pivot=[0, shoulderY + 0.05, k.td / 2 + 0.12]))
    # the dragon-fruit head: magenta with green-tipped scale spikes all round, a leaf crown
    k.brick("HeadDetail", (2.1, 0.5, 1.9), (0, headTop + 0.15, 0), FRUIT_D)
    for ring_y, n, r in ((headY - 0.5, 8, 1.05), (headY + 0.2, 8, 1.05), (headTop + 0.3, 7, 0.95)):
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * (ring_y > headY)) / n
            if abs(math.degrees(a) - 270) < 40 and ring_y < headTop:
                continue  # keep the face clear
            pos = (math.cos(a) * r, ring_y, math.sin(a) * r)
            k.wedge("HeadDetail", (0.32, 0.5, 0.5), pos, SCALEG, (0, -math.degrees(a) - 90, 0))
    k.eyes(y=0.05, look=(0, 0.15), lid=0.25, lidColor=FRUIT)
    k.brows(FRUIT_D, tilt=8)
    k.mouth("smirk", w=0.42)
    k.brick("HeadDetail", (0.9, 0.12, 0.1), (0, headY - 0.36, faceZ - 0.07), INK)  # a thin noble moustache
    for s in (-1, 1):
        k.brick("HeadDetail", (0.28, 0.1, 0.1), (s * 0.55, headY - 0.28, faceZ - 0.07), INK, (0, 0, s * 35))
    # the leaf crown + a ducal coronet
    for i in range(7):
        a = i * (360 / 7)
        k.wedge("HeadDetail", (0.35, 1.0, 0.25), (0.55 * math.cos(math.radians(a)), headTop + 0.85, 0.55 * math.sin(math.radians(a))), LEAF, (-20, -a - 90, 0))
    k.crown(GOLD, CRIMSON, lift=0.05, w=1.5, d=1.4, neon_gem=True)
    # the sceptre: gold with a glowing dragon-fruit gem
    k.held(1, (0.14, 2.4, 0.14), (0, 0.6, -0.35), GOLD)
    k.held(1, (0.5, 0.55, 0.5), (0, 1.95, -0.35), FRUIT, surf="neon")
    for s in (-1, 1):
        k.held(1, (0.18, 0.3, 0.18), (s * 0.28, 2.0, -0.35), SCALEG, (0, 0, -s * 40))


@lawyer("NarwhalMagistrate", 6, "Ocean")
def _(k):
    ROBE, ROBE_D, SKIN, SKIN_L, SPOT, HORN, HORN_G = H("1c1c26"), H("12121a"), H("6e8caa"), H("dce8f2"), H("4a6684"), H("f4f0e0"), H("bff4ff")
    k.body(SKIN, ROBE, ROBE_D, ROBE_D, hands=SKIN)
    k.robe(ROBE, True, CRIMSON, GOLD)
    k.lapels(ROBE, SKIN_L, 0.9, ROBE_D)
    k.plate("UpperTorso", (0.5, 0.5, 0.06), (0, shoulderY - 0.4, k.front(0.1)), WHITE)  # a jabot
    k.torsoBand(hipY + 0.1, 0.16, GOLD)
    k.pauldron(ROBE_D, CRIMSON, True)
    # narwhal head: rounded, longer, spotted, a pale belly
    k.brick("HeadDetail", (2.2, 0.8, 2.3), (0, headTop - 0.1, 0.15), SKIN)
    k.plate("HeadDetail", (1.5, 0.9, 0.05), (0, headY - 0.45, faceZ - 0.03), SKIN_L)
    for (x, y, z) in ((0.7, 4.3, -0.95), (-0.6, 4.4, -0.95), (0.95, 3.9, 0.2), (-0.98, 4.0, 0.4), (0.3, 4.75, 0.5), (-0.35, 4.72, -0.2)):
        k.plate("HeadDetail", (0.22, 0.16, 0.05), (x, y, z), SPOT, (0, 90 if abs(x) > 0.9 else (0 if z < 0 else 90), 0))
    k.eyes(y=0.05, look=(0, 0.1), pupil=H("1e3a5a"))
    k.brows(SPOT, tilt=-6)
    k.mouth("smile", w=0.6)
    # THE GLOWING SPIRAL HORN: a long tapering stack, twisting (spins slowly)
    base = (0, headY + 0.35, faceZ - 0.15)
    axis = Vector((0, 0.55, -1)).normalized()
    for j in range(16):
        f = j / 15
        pos = Vector(base) + axis * (0.2 + j * 0.24)
        w = 0.5 * (1 - f) + 0.08
        Rm = axis.to_track_quat("Y", "Z").to_matrix() @ Matrix.Rotation(math.radians(j * 32), 3, "Y")
        c = HORN_G if j % 3 == 0 else HORN
        k._add("box", "HeadDetail", (w, 0.26, w), tuple(pos), c, surf="neon" if j % 3 == 0 else "brick", R=Rm,
               fx=dict(kind="rot", axis=list(axis), amp=45, pivot=list(base)))
    # fins for flippers on the forearms, a tail fluke behind
    for s in (-1, 1):
        k.wedge(arm_name(s), (0.12, 0.6, 0.6), (s * (armX + 0.42), shoulderY - 0.9, 0.2), SKIN, (0, 0, s * 20))
    root = (0, hipY, k.td / 2 + 0.1)
    for s in (-1, 1):
        k.brick("UpperTorso", (1.2, 0.12, 0.7), (s * 0.55, hipY - 0.35, k.td / 2 + 0.9), SKIN, (0, s * 25, s * 10), fx=dict(SWAY(10, 0.5), pivot=list(root)))
    # bubbles rising and orbiting
    for j in range(5):
        a = j * 72
        k.ball("UpperTorso", 0.22 + (j % 2) * 0.1, (1.6 * math.cos(math.radians(a)), 2.0 + j * 0.45, 1.6 * math.sin(math.radians(a))), HORN_G, "neon",
               fx=SPIN(40, (0, 0, 0)))
    # a coral gavel
    k.held(1, (0.12, 0.9, 0.12), (0, 0.35, -0.3), H("ff7a6a"))
    k.held(1, (0.38, 0.38, 0.7), (0, 0.85, -0.3), H("ff9a8a"))


@lawyer("NebulaArbiter", 6, "Space")
def _(k):
    ROBE, ROBE_D, NEB1, NEB2, NEB3, STAR, RING = H("141432"), H("0c0c22"), H("3c1e6e"), H("b43cc8"), H("3c8cff"), H("fff4c8"), H("ffb4dc")
    k.body(NEB1, ROBE, ROBE_D, ROBE_D, hands=H("6a4ab0"))
    k.robe(ROBE, False, CRIMSON, GOLD)
    k.pauldron(ROBE_D, GOLD, True)
    k.torsoBand(hipY + 0.1, 0.14, CRIMSON)
    # the constellation robe: glowing stars joined by thin lines
    pts = [(-0.7, 2.4), (-0.2, 2.0), (0.4, 2.3), (0.75, 1.7), (0.1, 1.2), (-0.6, 0.7), (0.5, 0.5)]
    z = k.front(0.08)
    for i, (x, y) in enumerate(pts):
        k.glow("UpperTorso", (0.12, 0.12, 0.04), (x, y, z - 0.08), STAR)
        if i:
            x0, y0 = pts[i - 1]
            L = math.hypot(x - x0, y - y0)
            k.plate("UpperTorso", (0.03, L, 0.03), ((x + x0) / 2, (y + y0) / 2, z - 0.06), H("8a8ac8"), (0, 0, -math.degrees(math.atan2(x - x0, y - y0))))
    # the nebula head: swirling purple / pink / blue clouds with star specks, glowing eyes
    for (x, y, zz, s, c) in ((0.5, 4.6, 0.2, 0.9, NEB2), (-0.55, 4.5, -0.1, 0.85, NEB3), (0.0, 4.85, 0.3, 0.8, NEB1), (0.95, 3.8, 0.3, 0.6, NEB2),
                             (-0.95, 3.9, 0.2, 0.65, NEB3), (0.3, 3.1, 0.6, 0.5, NEB2), (-0.4, 4.9, 0.6, 0.6, NEB2)):
        k.brick("HeadDetail", (s, s * 0.8, s), (x, y, zz), c, (s * 20, s * 40, s * 15))
    for j in range(9):
        k.glow("HeadDetail", (0.08, 0.08, 0.08), (-0.9 + (j * 0.43) % 1.8, 3.2 + (j * 0.61) % 1.6, -0.94), STAR)
    k.eyes(y=0.05, white=H("1e1446"), pupil=H("ff8cf0"), glowPupil=True)
    k.mouth("smirk", w=0.4)
    # the tilted planet ring round the head (turning)
    centre = (0, headY + 0.1, 0)
    k.ring("HeadDetail", centre, 1.75, 0.12, 22, RING, tilt=(18, 0, 12), width=0.3, fx=SPIN(30, centre, (0.2, 0.95, 0.3)))
    k.ring("HeadDetail", centre, 2.05, 0.08, 26, NEB2, tilt=(18, 0, 12), width=0.15, fx=SPIN(30, centre, (0.2, 0.95, 0.3)))
    # a gavel of starlight
    k.held(1, (0.12, 0.9, 0.12), (0, 0.35, -0.3), H("8a8ac8"))
    k.held(1, (0.4, 0.4, 0.75), (0, 0.85, -0.3), NEB1)
    k.held(1, (0.24, 0.24, 0.24), (0, 0.85, -0.72), STAR, surf="neon")
    # tiny stars orbiting the body
    for j in range(6):
        a = j * 60
        k.glow("UpperTorso", (0.16, 0.16, 0.16), (2.0 * math.cos(math.radians(a)), 1.4 + (j % 3) * 0.7, 2.0 * math.sin(math.radians(a))), STAR, (45, 45, 0),
               fx=SPIN(35, (0, 0, 0)))


# ===================================================================================== SUPREME
def halo(k, y, r, col=GOLD, speed=40, tilt=(0, 0, 0), thick=0.14):
    centre = (0, y, 0.15)
    k.ring("HeadDetail", centre, r, thick, 24, col, tilt=tilt, width=0.22, fx=SPIN(speed, centre))
    k.ring("HeadDetail", centre, r + 0.18, 0.06, 28, H("fff6c8"), tilt=tilt, width=0.08, fx=SPIN(-speed * 0.6, centre))


def rainbow_hem(k, y):
    rainbow_band(k, "UpperTorso", (D["torsoW"] + 0.2, 0.12, 0.06), y, k.front(0.1))


@lawyer("CelestialChiefJustice", 7)
def _(k):
    ROBE, ROBE_D, SKIN, HAIR, SKY, STAR = H("f2efe8"), H("dcd6c8"), H("8d5a3b"), H("fbfaf6"), H("141446"), H("fff4b4")
    k.body(SKIN, ROBE, ROBE_D, GOLD, hands=SKIN)
    k.robe(ROBE, True, GOLD, GOLD, sleeve=ROBE)
    k.lapels(ROBE, GOLD, 1.0, GOLD_D)
    k.pauldron(GOLD, None)
    k.torsoBand(hipY + 0.1, 0.18, GOLD)
    rainbow_hem(k, hipY + 0.32)
    k.plate("UpperTorso", (0.55, 0.55, 0.06), (0, shoulderY - 0.4, k.front(0.1)), GOLD)
    k.glow("UpperTorso", (0.3, 0.3, 0.06), (0, shoulderY - 0.4, k.front(0.14)), H("ff8cf0"), (0, 0, 45))
    # the STARRY CAPE (deep blue, glowing stars, a gold edge) swaying
    k.cape(SKY, 3.1, GOLD, GOLD, width=D["torsoW"] + 0.9, fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35), glowTrim=True)
    for j in range(16):
        k.glow("UpperTorso", (0.1, 0.1, 0.04), (-1.25 + (j * 0.41) % 2.5, shoulderY - 0.3 - (j * 0.67) % 2.6, k.td / 2 + 0.2), STAR,
               fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35, pivot=[0, shoulderY + 0.05, k.td / 2 + 0.12]))
    # face: wise, glowing gold eyes, a white beard + flowing hair
    k.hairCap(HAIR, 0.2, 1.8, 1.2)
    k.eyes(y=0.08, white=H("fff6d8"), pupil=GOLD, glowPupil=True)
    k.brows(HAIR, tilt=-4, thick=0.15)
    k.nose()
    k.brick("HeadDetail", (2.1, 0.9, 0.22), (0, headY - 0.75, faceZ - 0.06), HAIR)
    k.brick("HeadDetail", (1.2, 0.6, 0.2), (0, headY - 1.4, faceZ - 0.06), HAIR)
    k.mouth("flat", y=-0.5, w=0.36)
    # a crown of stars + the HALO
    for i in range(7):
        a = math.radians(i * 360 / 7)
        k.glow("HeadDetail", (0.22, 0.4, 0.22), (0.85 * math.cos(a), headTop + 0.45, 0.85 * math.sin(a)), STAR, (0, i * 20, 45))
    halo(k, headTop + 1.1, 1.05, GOLD, 35, (8, 0, 0))
    # the SCALES OF JUSTICE floating at his side (bobbing), a gold gavel in hand
    sx, sy, sz = 2.1, 3.3, -0.4
    for part in (((0.12, 1.6, 0.12), (sx, sy, sz), GOLD), ((1.6, 0.1, 0.1), (sx, sy + 0.8, sz), GOLD)):
        k.brick("UpperTorso", part[0], part[1], part[2], fx=BOB(0.15, 0.4))
    for s in (-1, 1):
        k.plate("UpperTorso", (0.03, 0.6, 0.03), (sx + s * 0.75, sy + 0.5, sz), GOLD_D, fx=BOB(0.15, 0.4, s))
        k.brick("UpperTorso", (0.55, 0.08, 0.55), (sx + s * 0.75, sy + 0.18, sz), GOLD, fx=BOB(0.15, 0.4, s))
        k.glow("UpperTorso", (0.22, 0.22, 0.22), (sx + s * 0.75, sy + 0.3, sz), STAR if s < 0 else H("8cf0ff"), fx=BOB(0.15, 0.4, s))
    k.held(-1, (0.14, 1.0, 0.14), (0, 0.35, -0.35), GOLD)
    k.held(-1, (0.44, 0.44, 0.8), (0, 0.9, -0.35), ROBE)
    for dz in (-0.3, 0.3):
        k.held(-1, (0.48, 0.48, 0.08), (0, 0.9, -0.35 + dz), GOLD, surf="neon")
    # small feathered wings of light
    for s in (-1, 1):
        k.wing(s, (s * 0.5, shoulderY - 0.1, k.td / 2 + 0.3), H("fff6e0"), GOLD, length=3.0, rows=4, spread=40, fx=FLAP(s, 7, 0.4), glowTips=True,
               feather=(0.45, 0.1, 1.0))
    # stars orbiting
    for j in range(8):
        a = j * 45
        k.glow("UpperTorso", (0.2, 0.2, 0.06), (2.6 * math.cos(math.radians(a)), 2.4 + 0.6 * math.sin(j), 2.6 * math.sin(math.radians(a))), RAINBOW[j % 6],
               (0, 0, 45), fx=SPIN(30, (0, 0, 0)))


@lawyer("CelestialKitsune", 7, "Pet")
def _(k):
    ROBE, ROBE_D, FUR, FUR_D, PINK, MARK, OBI = H("f2efe8"), H("d8d2c8"), H("f8f6f0"), H("e6e0d6"), H("ffb4d2"), H("ff7ab4"), H("ffc828")
    k.body(FUR, ROBE, ROBE_D, H("c8282e"), hands=FUR)
    # a kimono: overlapping front, gold obi, wide sleeves, rainbow hem
    k.robe(ROBE, False, None, None, sleeve=ROBE)
    k.plate("UpperTorso", (0.25, 1.4, 0.05), (0.15, hipY + 0.75, k.front(0.05)), MARK, (0, 0, -20))
    k.torsoBand(hipY + 0.4, 0.4, OBI)
    k.glow("UpperTorso", (0.36, 0.3, 0.06), (0, hipY + 0.4, k.front(0.08)), MARK)
    rainbow_hem(k, 0.25)
    for s in (-1, 1):
        k.brick(arm_name(s), (D["armW"] + 0.35, 0.9, D["armD"] + 0.5), (s * armX, shoulderY - 0.95, 0.15), ROBE)
        rainbow_band(k, arm_name(s), (D["armW"] + 0.38, 0.1, D["armD"] + 0.53), shoulderY - 1.36, 0.15, s * armX)
    # the fox head: white, pointed ears with pink insides, a muzzle, red markings, glowing eyes
    k.brick("HeadDetail", (1.1, 0.55, 0.55), (0, headY - 0.5, faceZ - 0.28), FUR)
    k.brick("HeadDetail", (0.3, 0.2, 0.15), (0, headY - 0.35, faceZ - 0.6), INK)
    for s in (-1, 1):
        k.wedge("HeadDetail", (0.65, 1.1, 0.4), (s * 0.68, headTop + 0.5, 0.1), FUR, (0, 0, s * -10))
        k.plate("HeadDetail", (0.32, 0.65, 0.05), (s * 0.68, headTop + 0.4, -0.12), PINK, (0, 0, s * -10))
        k.plate("HeadDetail", (0.42, 0.12, 0.04), (s * 0.55, headY + 0.42, faceZ - 0.03), MARK, (0, 0, s * 20))
        k.brick("HeadDetail", (0.25, 0.7, 1.4), (s * 1.1, headY - 0.3, 0.1), FUR_D)
    k.glow("HeadDetail", (0.2, 0.3, 0.04), (0, headY + 0.75, faceZ - 0.03), MARK, (0, 0, 45))
    k.eyes(y=0.1, w=0.48, h=0.42, white=H("fff0f8"), pupil=H("ff5ab4"), glowPupil=True)
    k.mouth("smile", y=-0.66, w=0.36)
    # a floating golden ornament crown + halo
    k.crown(GOLD, MARK, lift=0.3, w=1.0, d=0.9, neon_gem=True)
    halo(k, headTop + 1.55, 0.85, H("ffe6f4"), 45, (10, 0, 0), 0.1)
    # NINE TAILS fanned out behind, white with rainbow glowing tips, swaying in a wave
    root = (0, hipY + 0.05, k.td / 2 + 0.15)
    for t in range(9):
        a = math.radians(-80 + t * 20)
        d = Vector((math.sin(a), math.cos(a) * 0.9 + 0.35, 0.55)).normalized()
        for j in range(5):
            f = j / 4
            pos = Vector(root) + d * (0.35 + j * 0.62) + Vector((0, 0.15 * j * j * 0.25, 0))
            w = 0.5 + 0.35 * math.sin(f * math.pi)
            Rm = d.to_track_quat("Y", "Z").to_matrix()
            fx = dict(SWAY(9, 0.45, t * 0.5), pivot=list(root))
            if j == 4:
                k._add("box", "UpperTorso", (w, 0.75, w), tuple(pos), RAINBOW[t % 6], surf="neon", fx=fx, R=Rm)
            else:
                k._add("box", "UpperTorso", (w, 0.7, w), tuple(pos), FUR if j % 2 == 0 else FUR_D, fx=fx, R=Rm)
    # FOXFIRE: floating flames circling her
    for j in range(6):
        a = math.radians(j * 60)
        c = (2.3 * math.cos(a), 2.6 + 0.4 * math.sin(j * 1.7), 2.3 * math.sin(a))
        for m, (fr, col) in enumerate(((1.0, H("8cd8ff")), (0.6, H("e6f6ff")))):
            k.glow("UpperTorso", (0.36 * fr, 0.6 * fr, 0.36 * fr), (c[0], c[1] + m * 0.15, c[2]), col, (0, j * 30, 45), fx=SPIN(28, (0, 0, 0)))
    # a fan
    k.held(1, (0.9, 0.7, 0.06), (0, 0.2, -0.45), MARK, (0, 0, 20))
    k.held(1, (0.9, 0.12, 0.08), (0, -0.1, -0.47), OBI, (0, 0, 20), "plate")
    k.poseArm(1, (25, 0, -5))


@lawyer("ImperatorePinguino", 7, "Brainrot")
def _(k):
    BLACK, BELLY, NECK, BEAK, CAPE, CAPE_D, CONE = H("1c1c24"), H("f6f4ee"), H("ffb428"), H("ff8c1e"), H("6a1e8a"), H("4a1262"), H("d8a05a")
    SCOOPS = (H("ff9ac8"), H("8ef0c0"), H("8a5030"))
    k.body(BLACK, BLACK, BLACK, BEAK, hands=BLACK)
    k.plate("UpperTorso", (1.5, 1.4, 0.06), (0, hipY + 0.72, k.front(0.03)), BELLY)
    for s in (-1, 1):  # flippers
        k.brick(arm_name(s), (0.3, 1.5, 0.75), (s * (armX + 0.1), shoulderY - 0.75, 0), BLACK, (0, 0, s * 8))
    # the penguin head: black with a white face mask, golden neck patches, an orange beak
    k.plate("HeadDetail", (1.6, 1.2, 0.05), (0, headY - 0.15, faceZ - 0.03), BELLY)
    for s in (-1, 1):
        k.plate("HeadDetail", (0.06, 0.9, 0.7), (s * 1.03, headY - 0.45, -0.1), NECK)
        k.plate("UpperTorso", (0.4, 0.5, 0.06), (s * 0.55, shoulderY - 0.2, k.front(0.05)), NECK)
    k.brick("HeadDetail", (0.55, 0.3, 0.6), (0, headY - 0.35, faceZ - 0.3), BEAK)
    k.brick("HeadDetail", (0.45, 0.18, 0.5), (0, headY - 0.55, faceZ - 0.25), H("e06a10"))
    k.eyes(y=0.2, w=0.42, h=0.46, white=H("fffbe8"), pupil=H("ff50aa"), glowPupil=True, look=(0, 0.1))
    k.brows(BLACK, y=0.2, h=0.46, tilt=12)
    # ROYAL CAPE (purple, ermine trim, rainbow lining edge)
    k.cape(CAPE, 3.0, H("fbfaf6"), H("fbfaf6"), width=D["torsoW"] + 1.0, fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35))
    for j in range(10):
        k.plate("UpperTorso", (0.12, 0.16, 0.05), (-1.3 + j * 0.29, shoulderY - 2.85, k.td / 2 + 0.2), BLACK,
                fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35, pivot=[0, shoulderY + 0.05, k.td / 2 + 0.12]))
    rainbow_band(k, "UpperTorso", (0.12, 2.8, 0.14), shoulderY - 1.5, k.td / 2 + 0.15, -1.48, "y")
    rainbow_band(k, "UpperTorso", (0.12, 2.8, 0.14), shoulderY - 1.5, k.td / 2 + 0.15, 1.48, "y")
    # the THREE-SCOOP GELATO CROWN: a gold crown band, three scoops stacked, drips, a cherry (glowing), floating a little
    k.crown(GOLD, H("ff50aa"), lift=0.0, neon_gem=True)
    for i, c in enumerate(SCOOPS):
        y = headTop + 1.0 + i * 0.62
        w = 1.25 - i * 0.18
        k.brick("HeadDetail", (w, 0.6, w), (0, y, 0.05), c, fx=BOB(0.06, 0.6))
        for s in (-1, 1):
            k.brick("HeadDetail", (0.18, 0.3, 0.18), (s * w / 2.6, y - 0.32, -w / 2 + 0.05), c, fx=BOB(0.06, 0.6))
    k.glow("HeadDetail", (0.32, 0.32, 0.32), (0, headTop + 2.85, 0.05), H("ff1e3c"), fx=BOB(0.06, 0.6))
    for j in range(8):  # rainbow sprinkles
        k.glow("HeadDetail", (0.06, 0.18, 0.06), (0.5 * math.cos(j), headTop + 1.1 + (j % 3) * 0.6, -0.55 + 0.1 * (j % 2)), RAINBOW[j % 6], (0, 0, j * 40),
               fx=BOB(0.06, 0.6))
    # the sceptre: a waffle cone topped with a glowing scoop
    k.held(1, (0.16, 2.0, 0.16), (0, 0.3, -0.4), GOLD)
    k.held(1, (0.5, 0.8, 0.5), (0, 1.6, -0.4), CONE)
    for j in range(3):
        k.held(1, (0.52, 0.05, 0.52), (0, 1.35 + j * 0.25, -0.4), H("b07838"), (0, 45, 0), "plate")
    k.held(1, (0.6, 0.5, 0.6), (0, 2.2, -0.4), SCOOPS[0], surf="neon")
    # orbiting mini-scoops
    for j in range(6):
        a = math.radians(j * 60)
        k.brick("UpperTorso", (0.35, 0.35, 0.35), (2.4 * math.cos(a), 2.3 + 0.3 * math.sin(j), 2.4 * math.sin(a)), SCOOPS[j % 3], fx=SPIN(30, (0, 0, 0)))


@lawyer("GrandGateauJustice", 7, "Food")
def _(k):
    ROBE, ROBE_D, SKIN, CAKE1, CAKE2, CAKE3, ICING, CANDLE = H("ffc828"), H("d99a10"), H("f6d8a8"), H("fff4e6"), H("ff9ac8"), H("fff4e6"), H("ffd6ea"), H("8ad8ff")
    k.body(SKIN, ROBE, ROBE_D, H("8a4a20"), hands=SKIN)
    k.robe(ROBE, True, H("fbfaf6"), H("fbfaf6"), sleeve=ROBE)
    k.lapels(ROBE, H("fbfaf6"), 0.9, ROBE_D)
    k.pauldron(ROBE_D, None)
    rainbow_hem(k, hipY + 0.25)
    k.cape(H("ff9ac8"), 2.9, GOLD, GOLD, width=D["torsoW"] + 0.9, fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35), glowTrim=True)
    # face on the bottom tier: a friendly baker-judge with rosy cheeks, glowing eyes
    k.eyes(y=0.0, white=H("fffbe8"), pupil=H("ff5ab4"), glowPupil=True)
    k.brows(H("8a4a20"), tilt=-4)
    k.nose()
    k.mouth("grin", w=0.5)
    for s in (-1, 1):
        k.plate("HeadDetail", (0.32, 0.14, 0.03), (s * 0.66, headY - 0.34, faceZ - 0.02), H("ff9aa8"))
    # the THREE-TIER CAKE head: tiers, frosting drips, a band of pearls, candles with flames, a halo above
    tiers = ((2.3, 0.7, CAKE1), (1.8, 0.7, CAKE2), (1.3, 0.65, CAKE3))
    y = headTop - 0.2
    for i, (w, h, c) in enumerate(tiers):
        k.brick("HeadDetail", (w, h, w), (0, y + h / 2, 0), c)
        k.brick("HeadDetail", (w + 0.08, 0.14, w + 0.08), (0, y + h - 0.04, 0), ICING)
        n = 8
        for j in range(n):
            a = 2 * math.pi * j / n
            r = w / 2 + 0.04
            k.plate("HeadDetail", (0.18, 0.3 + (j % 2) * 0.15, 0.05), (r * math.cos(a), y + h - 0.25, r * math.sin(a)), ICING, (0, -math.degrees(a) - 90, 0))
        for j in range(6):
            a = 2 * math.pi * (j + 0.5) / 6
            r = w / 2 + 0.03
            k.glow("HeadDetail", (0.08, 0.08, 0.08), (r * math.cos(a), y + 0.25, r * math.sin(a)), RAINBOW[(j + i) % 6])
        y += h
    for j in range(5):
        a = 2 * math.pi * j / 5
        cx, cz = 0.42 * math.cos(a), 0.42 * math.sin(a)
        k.brick("HeadDetail", (0.14, 0.55, 0.14), (cx, y + 0.27, cz), CANDLE if j % 2 else H("ffe68a"))
        k.glow("HeadDetail", (0.14, 0.24, 0.14), (cx, y + 0.68, cz), H("ffc83c"), fx=FLICK(j))
        k.glow("HeadDetail", (0.08, 0.14, 0.08), (cx, y + 0.84, cz), H("fff4c8"), fx=FLICK(j + 0.5))
    halo(k, y + 1.4, 1.0, GOLD, 35, (6, 0, 0))
    # the cake-server sceptre + a floating cherry
    k.held(1, (0.14, 1.6, 0.14), (0, 0.4, -0.35), GOLD)
    k.held(1, (0.5, 0.75, 0.08), (0, 1.5, -0.35), H("e6ecf5"))
    k.held(1, (0.36, 0.36, 0.36), (0, 2.1, -0.35), H("ff1e3c"), surf="neon", fx=BOB(0.1, 0.6))
    # orbiting macarons (rainbow)
    for j in range(6):
        a = math.radians(j * 60)
        c = (2.5 * math.cos(a), 2.6 + 0.3 * math.sin(j), 2.5 * math.sin(a))
        k.cyl("UpperTorso", (0.25, 0.45, 0.45), (c[0], c[1] + 0.12, c[2]), RAINBOW[j], (0, 0, 90), "neon", fx=SPIN(32, (0, 0, 0)))
        k.cyl("UpperTorso", (0.12, 0.42, 0.42), c, H("fbfaf6"), (0, 0, 90), "plate", fx=SPIN(32, (0, 0, 0)))


@lawyer("TidalSovereign", 7, "Ocean")
def _(k):
    ROBE, ROBE_D, SKIN, BEARD, CORAL1, CORAL2, PEARL, WAVE1, WAVE2, FOAM = H("1e64c8"), H("164a96"), H("5ac8be"), H("2a8a8a"), H("ff7a6a"), H("ffb43c"), H("fffbf0"), H("1e8ce6"), H("50c8ff"), H("e6faff")
    k.body(SKIN, ROBE, ROBE_D, GOLD, hands=SKIN)
    k.robe(ROBE, True, GOLD, GOLD, sleeve=ROBE_D)
    k.lapels(ROBE, H("e6faff"), 1.0, GOLD)
    k.pauldron(GOLD, H("50c8ff"), True)
    rainbow_hem(k, hipY + 0.25)
    for j in range(4):  # scale armour on the chest
        k.plate("UpperTorso", (0.5, 0.2, 0.05), (-0.45 + (j % 2) * 0.9, shoulderY - 0.85 - (j // 2) * 0.3, k.front(0.09)), GOLD_D)
    # sea-king face: glowing cyan eyes, a seaweed beard
    k.eyes(y=0.1, white=H("e6ffff"), pupil=H("00e6ff"), glowPupil=True)
    k.brows(BEARD, tilt=12, thick=0.16)
    k.nose()
    k.brick("HeadDetail", (2.1, 0.8, 0.22), (0, headY - 0.7, faceZ - 0.06), BEARD)
    for j in range(6):
        k.brick("HeadDetail", (0.22, 0.9 + (j % 3) * 0.3, 0.2), (-0.75 + j * 0.3, headY - 1.4 - (j % 3) * 0.15, faceZ - 0.06), BEARD if j % 2 else H("1e6e6e"),
                fx=dict(SWAY(6, 0.5, j), pivot=[0, headY - 1.0, faceZ]))
    k.mouth("flat", y=-0.42, w=0.4)
    k.hairCap(BEARD, 0.2, 1.6, 1.1)
    # the CORAL CROWN with pearls (glowing)
    k.brick("HeadDetail", (2.0, 0.35, 1.8), (0, headTop + 0.35, 0), GOLD)
    for i in range(7):
        a = math.radians(i * 360 / 7)
        r = 0.85
        h = 0.9 + (i % 3) * 0.35
        k.brick("HeadDetail", (0.2, h, 0.2), (r * math.cos(a), headTop + 0.5 + h / 2, r * math.sin(a)), CORAL1 if i % 2 else CORAL2, (math.sin(a) * 15, 0, -math.cos(a) * 15))
        k.brick("HeadDetail", (0.32, 0.14, 0.14), (r * math.cos(a) * 1.1, headTop + 0.5 + h * 0.65, r * math.sin(a) * 1.1), CORAL1 if i % 2 else CORAL2, (0, -math.degrees(a), 35))
        k.ball("HeadDetail", 0.22, (r * math.cos(a) * 1.05, headTop + 0.55 + h, r * math.sin(a) * 1.05), PEARL, "neon")
    # the TRIDENT (gold, glowing tines)
    k.held(1, (0.16, 4.4, 0.16), (0, 0.9, -0.4), GOLD)
    k.held(1, (1.0, 0.16, 0.16), (0, 3.1, -0.4), GOLD)
    for x in (-0.45, 0, 0.45):
        k.held(1, (0.14, 0.75, 0.14), (x, 3.55, -0.4), H("8cf0ff"), surf="neon")
        k.held(1, (0.22, 0.22, 0.14), (x, 3.95, -0.4), H("e6ffff"), (0, 0, 45), "neon")
    # the WAVE CAPE: layered curling waves with foam crests, rolling
    piv = [0, shoulderY + 0.05, k.td / 2 + 0.12]
    for row in range(5):
        y = shoulderY - 0.3 - row * 0.6
        for j in range(5):
            x = -1.3 + j * 0.65
            c = WAVE1 if (row + j) % 2 else WAVE2
            k.brick("UpperTorso", (0.75, 0.6, 0.18), (x, y, k.td / 2 + 0.2 + row * 0.06), c, (row * 4, 0, 0), fx=dict(kind="osc", axis=[1, 0, 0], amp=6, rate=0.4, phase=row * 0.5, pivot=piv))
            if row % 2 == 0:
                k.glow("UpperTorso", (0.5, 0.14, 0.22), (x + 0.1, y + 0.32, k.td / 2 + 0.25 + row * 0.06), FOAM, fx=dict(kind="osc", axis=[1, 0, 0], amp=6, rate=0.4, phase=row * 0.5, pivot=piv))
    # water orbs orbiting
    for j in range(6):
        a = math.radians(j * 60)
        k.ball("UpperTorso", 0.4, (2.4 * math.cos(a), 2.5 + 0.4 * math.sin(j * 2), 2.4 * math.sin(a)), H("50dcff"), "neon", fx=SPIN(36, (0, 0, 0)))


@lawyer("SupernovaSovereign", 7, "Space")
def _(k):
    ARM, ARM_D, CORE, CORE2, RAY, CAPE = H("ffc828"), H("d99a10"), H("fffbe6"), H("ffe650"), H("ff8c1e"), H("1a1240")
    k.body(H("ffd23c"), ARM, ARM_D, ARM_D, hands=ARM_D)
    # gold armour: chest plates, a glowing core, shoulder spikes, armoured legs
    k.plate("UpperTorso", (1.7, 1.2, 0.08), (0, hipY + 0.78, k.front(0.04)), ARM_D)
    k.glow("UpperTorso", (0.5, 0.5, 0.08), (0, hipY + 0.9, k.front(0.1)), H("ff50aa"), (0, 0, 45))
    k.pauldron(ARM_D, H("ff50aa"), True)
    for s in (-1, 1):
        k.wedge(arm_name(s), (0.3, 0.6, 0.6), (s * (armX + 0.2), shoulderY + 0.45, 0), ARM, (0, 0, -s * 20))
    k.boots(ARM_D, 0.8, H("ff50aa"))
    rainbow_hem(k, hipY + 0.25)
    k.cape(CAPE, 3.2, GOLD, ARM_D, width=D["torsoW"] + 1.0, fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35), glowTrim=True)
    for j in range(18):  # a galaxy on the cape
        k.glow("UpperTorso", (0.1, 0.1, 0.04), (-1.3 + (j * 0.37) % 2.6, shoulderY - 0.3 - (j * 0.71) % 2.8, k.td / 2 + 0.2), RAINBOW[j % 6],
               fx=dict(kind="osc", axis=[1, 0, 0], amp=5, rate=0.35, pivot=[0, shoulderY + 0.05, k.td / 2 + 0.12]))
    # THE BLAZING STAR HEAD: a white-hot core, a yellow shell, corona rays all around (turning), glowing eyes
    k.glow("HeadDetail", (2.2, 2.0, 2.0), (0, headY, 0.05), CORE2)
    k.glow("HeadDetail", (1.7, 1.6, 1.6), (0, headY + 0.05, -0.08), CORE)
    k.eye(-0.46, headY + 0.05, 0.5, 0.5, (0, 0), z=-1.0, white=H("1c1240"), pupil=H("fffbe6"), glowPupil=True)
    k.eye(0.46, headY + 0.05, 0.5, 0.5, (0, 0), z=-1.0, white=H("1c1240"), pupil=H("fffbe6"), glowPupil=True)
    k.plate("HeadDetail", (0.5, 0.1, 0.04), (0, headY - 0.5, -1.1), H("1c1240"))
    centre = (0, headY, 0.05)
    for ring, (n, r, L, col, sp) in enumerate(((12, 1.55, 1.1, RAY, 25), (12, 1.45, 0.8, H("ffe650"), -35))):
        for i in range(n):
            a = 2 * math.pi * (i + ring * 0.5) / n
            d = Vector((math.cos(a), math.sin(a), 0))
            pos = Vector(centre) + d * (r + L / 2)
            Rm = d.to_track_quat("Y", "Z").to_matrix()
            k._add("wedge", "HeadDetail", (0.36, L, 0.3), tuple(pos), col, surf="neon", R=Rm, fx=SPIN(sp, centre, (0, 0, 1)))
    # ORBITING PLANETS on tilted paths, each with its own ring
    planets = ((3.0, 0.65, H("ff5050"), 0, 30), (3.6, 0.5, H("50aaff"), 120, 22), (2.6, 0.45, H("5ae66e"), 240, 40), (4.2, 0.8, H("a064ff"), 60, 16))
    for (r, s, col, a0, sp) in planets:
        a = math.radians(a0)
        pos = (r * math.cos(a), 3.2 + 0.6 * math.sin(a), r * math.sin(a))
        k.ball("UpperTorso", s, pos, col, "brick" if s > 0.6 else "plate", fx=SPIN(sp, (0, 0, 0)))
        if s >= 0.6:
            k.ring("UpperTorso", pos, s * 0.85, 0.05, 14, H("ffe6b4"), tilt=(25, 0, 10), width=0.12, fx=SPIN(sp, (0, 0, 0)))
    # a crown of light over it all + a sceptre-star
    halo(k, headTop + 1.3, 1.3, H("ffe650"), 50, (0, 0, 0), 0.12)
    k.held(1, (0.16, 2.2, 0.16), (0, 0.5, -0.4), ARM_D)
    for j in range(4):
        k.held(1, (0.6, 0.6, 0.12), (0, 1.9, -0.4), RAINBOW[j], (0, 0, 22.5 * j), "neon", fx=SPIN(80, tuple(k.hand(1) + V((0, 1.9, -0.4))), (0, 0, 1)))


# ===================================================================================== build, export, preview
kits = {}
for id, (rarity, egg, fn) in L.items():
    k = Kit(id, rarity, SCALE[rarity], egg)
    fn(k)
    kits[id] = k
data = {id: k.export() for id, k in kits.items()}
with open(OUT_JSON, "w") as fh:
    json.dump(data, fh, separators=(",", ":"))

sc = bpy.data.scenes.get("TopLawyers") or bpy.data.scenes.new("TopLawyers")
for o in list(sc.collection.all_objects):
    bpy.data.objects.remove(o, do_unlink=True)
win = bpy.context.window
prev = win.scene
win.scene = sc
mats = {}
EGGS = ["", "Pet", "Brainrot", "Food", "Ocean", "Space"]
tier_objs = {4: [], 6: [], 7: []}
for id, k in kits.items():
    col = EGGS.index(k.egg)
    before = set(sc.collection.objects)
    brickkit.to_blender(bpy, sc, k, Vector((col * 7.5 * k.scale, 0, 0)), mats)
    tier_objs[k.rarity].extend(o for o in sc.collection.objects if o not in before)
cam_d = bpy.data.cameras.get("TL_Cam") or bpy.data.cameras.new("TL_Cam")
cam = bpy.data.objects.new("TL_Cam", cam_d)
sc.collection.objects.link(cam)
cam_d.lens = 30
sc.camera = cam
sun_d = bpy.data.lights.get("TL_Sun") or bpy.data.lights.new("TL_Sun", "SUN")
sun_d.energy = 3.2
sun = bpy.data.objects.new("TL_Sun", sun_d)
sun.rotation_euler = (math.radians(55), math.radians(-5), math.radians(160))
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.get("V5_World") or bpy.data.worlds.new("V5_World")
for eng in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        sc.render.engine = eng
        break
    except TypeError:
        pass
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x, sc.render.resolution_y = 2400, 900
os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
for tier, objs in tier_objs.items():
    s = SCALE[tier]
    for t2, o2 in tier_objs.items():
        for o in o2:
            o.hide_render = t2 != tier
    cx = 2.5 * 7.5 * s
    target = Vector((cx, 0, 3.0 * s))
    cam.location = (cx + 4 * s, 40 * s, 10 * s)  # in front (+Y in Blender = the characters' front)
    cam.rotation_euler = (target - Vector(cam.location)).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = OUT_PNG.replace(".png", "_%s.png" % {4: "epic", 6: "mythic", 7: "supreme"}[tier])
    bpy.ops.render.render(write_still=True, scene=sc.name)
win.scene = prev
print("lawyers:", ", ".join(f"{id} {len(k.parts)}" for id, k in kits.items()))