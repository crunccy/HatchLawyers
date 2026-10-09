"""Client character sheets. Each returns a spec for voxel_builder.build_character.

ASCII art: Head front is 12 wide x 10 tall, UpperTorso / LowerTorso fronts are 13 x 9, read top to bottom,
leftmost column = the character's right side (viewer's left). Row lists ("rows") go bottom -> top.
"""
from voxel_builder import pal

# ------------------------------------------------------------------------------------- shared colors
WHITE = pal("white", (245, 245, 240))
BLACK = pal("black", (25, 25, 30))
EYE_WHITE = pal("eye_white", (250, 250, 250))
MOUTH = pal("mouth", (120, 40, 40))
GOLD = pal("gold", (255, 200, 40))
WOOD = pal("wood", (214, 140, 70))
WOOD_DARK = pal("wood_dark", (122, 70, 34))


def limbs(sleeve_rows_upper, sleeve_rows_lower, hand, leg_upper, leg_lower, foot):
    return {
        "LeftUpperArm": {"rows": sleeve_rows_upper}, "RightUpperArm": {"rows": sleeve_rows_upper},
        "LeftLowerArm": {"rows": sleeve_rows_lower}, "RightLowerArm": {"rows": sleeve_rows_lower},
        "LeftHand": {"base": hand}, "RightHand": {"base": hand},
        "LeftUpperLeg": {"rows": leg_upper}, "RightUpperLeg": {"rows": leg_upper},
        "LeftLowerLeg": {"rows": leg_lower}, "RightLowerLeg": {"rows": leg_lower},
        "LeftFoot": {"rows": foot}, "RightFoot": {"rows": foot},
    }


# --------------------------------------------------------------------------- COMMON: Neighbor Dave
def neighbor_dave():
    skin = pal("skin_tan", (240, 190, 140))
    nose = pal("skin_tan_shade", (215, 160, 115))
    hair = pal("hair_brown", (110, 70, 40))
    brow = pal("brow_brown", (70, 42, 24))
    polo = pal("polo_blue", (70, 140, 230))
    polo_dark = pal("polo_blue_dark", (50, 105, 190))
    khaki = pal("khaki", (205, 175, 115))
    belt = pal("belt_brown", (90, 55, 30))
    sandal = pal("sandal", (140, 90, 50))
    legend = {"h": hair, "s": skin, "b": brow, "w": EYE_WHITE, "k": BLACK, "n": nose, "m": MOUTH,
              "p": polo, "c": WHITE, "u": WHITE, "q": polo_dark, "l": belt, "d": GOLD, "t": khaki}
    parts = {
        "Head": {"base": skin, "top": hair, "back_rows": {9: hair, 8: hair, 7: hair}, "legend": legend, "front": [
            "hhhhhhhhhhhh",
            "hhhhhhhhhhhs",
            "ssssssssssss",
            "sbbbbssbbbbs",
            "swwwwsswwwws",
            "swkkwsswkkws",
            "sssssnnsssss",
            "sshhhhhhhhss",
            "ssssmmmmssss",
            "ssssssssssss",
        ]},
        "UpperTorso": {"base": polo, "legend": legend, "front": [
            "ppppcccccpppp",
            "pppppcucppppp",
            "ppppppuppppqq",
            "ppppppppppqqq",
            "ppppppppppppp",
            "ppppppppppppp",
            "ppppppppppppp",
            "ppppppppppppp",
            "ppppppppppppp",
        ]},
        "LowerTorso": {"rows": [khaki] * 5 + [belt] + [polo] * 3, "legend": legend, "front": [
            "ppppppppppppp",
            "ppppppppppppp",
            "ppppppppppppp",
            "llllllldlllll",
            "ttttttttttttt",
            "tttttt.tttttt",
            "ttttttttttttt",
            "ttttttttttttt",
            "ttttttttttttt",
        ]},
    }
    parts.update(limbs(
        [skin, skin, polo, polo, polo, polo], [skin] * 7, skin,
        [skin, skin, skin, khaki, khaki, khaki, khaki, khaki], [WHITE, WHITE, skin, skin, skin, skin, skin],
        [sandal, sandal, WHITE],
    ))
    return {"parts": parts}


# ----------------------------------------------------------------------- UNCOMMON: Rosa the Baker
def rosa_the_baker():
    skin = pal("skin_warm", (205, 140, 100))
    nose = pal("skin_warm_shade", (180, 115, 80))
    blush = pal("blush", (235, 120, 120))
    hair = pal("hair_black", (40, 30, 30))
    shirt = pal("shirt_red", (220, 60, 60))
    apron = pal("apron", (250, 250, 245))
    pocket = pal("apron_pocket", (215, 215, 210))
    pants = pal("pants_grey", (70, 72, 85))
    shoe = BLACK
    legend = {"h": hair, "s": skin, "b": hair, "w": EYE_WHITE, "k": BLACK, "n": nose, "m": MOUTH,
              "r": blush, "f": WHITE, "R": shirt, "W": apron, "q": pocket, "p": pants}
    parts = {
        "Head": {"base": skin, "top": hair, "back_rows": {k: hair for k in range(4, 10)}, "legend": legend, "front": [
            "hhhhhhhhhhhh",
            "hhhhhhhhhhhh",
            "hhsssssssshh",
            "hsbbbssbbbsh",
            "swwwwsswwwws",
            "swkkwsswkkws",
            "srrssnnssrrs",
            "ssssssssssfs",
            "ssmssssssmss",
            "sssmmmmmmsss",
        ]},
        "UpperTorso": {"base": shirt, "legend": legend, "front": [
            "RRWRRRRRRRWRR",
            "RRWRRRRRRRWRR",
            "RRWWWWWWWWWRR",
            "RRRWWWWWWWRRR",
            "RRRWWWWWWWRRR",
            "RRRWWWWWWWRRR",
            "RRRWWWWWWWRRR",
            "RRRWWWWWWWRRR",
            "RRRWWWWWWWRRR",
        ]},
        "LowerTorso": {"rows": [pants] * 4 + [shirt] * 5, "legend": legend, "front": [
            "RRWWWWWWWWWRR",
            "RRWWWWWWWWWRR",
            "RRWWWqqqWWWRR",
            "RRWWWqqqWWWRR",
            "ppWWWWWWWWWpp",
            "ppWWWWWWWWWpp",
            "ppWWWWWWWWWpp",
            "ppWWWWWWWWWpp",
            "ppWWWWWWWWWpp",
        ]},
    }
    parts.update(limbs(
        [WHITE, shirt, shirt, shirt, shirt, shirt], [skin] * 7, skin,
        [pants] * 8, [pants] * 7, [shoe, shoe, shoe],
    ))
    chef = pal("chef_white", (255, 255, 255))
    chef_shade = pal("chef_shade", (225, 228, 235))
    puff = lambda i, j, k, nx, ny, nz: chef_shade if k == 0 else chef
    pin_wood = pal("rolling_pin", (230, 170, 100))

    def rolling_pin(i, j, k, nx, ny, nz):
        return WOOD_DARK if j in (0, ny - 1) else pin_wood

    extras = {
        "Head": [
            ((-0.5, -0.42, 4.478, 0.5, 0.32, 4.678), chef),            # hat band
            ((-0.6, -0.52, 4.678, 0.6, 0.42, 5.078), puff),            # puffy top
        ],
        "RightHand": [((-0.80, -0.55, 1.55, -0.70, 0.45, 1.65), rolling_pin)],
    }
    return {"parts": parts, "extras": extras}


# ----------------------------------------------------------------------- RARE: Baron von Banana
def baron_von_banana():
    fur = pal("fur_brown", (120, 72, 40))
    tan = pal("monkey_tan", (230, 185, 135))
    nostril = pal("monkey_nostril", (150, 95, 60))
    suit = pal("suit_purple", (125, 65, 185))
    suit_dark = pal("suit_purple_dark", (85, 40, 135))
    tie = pal("banana_yellow", (255, 220, 50))
    glove = WHITE
    legend = {"f": fur, "t": tan, "b": BLACK, "w": EYE_WHITE, "k": BLACK, "g": GOLD, "n": nostril, "m": MOUTH,
              "W": WHITE, "p": suit, "d": suit_dark, "y": tie, "o": GOLD}
    parts = {
        "Head": {"base": fur, "top": fur, "legend": legend, "front": [
            "ffffffffffff",
            "ffffffffffff",
            "ffbbbffbbbff",
            "fgggtttttttf",
            "fgwgttttwwtf",
            "fgkgttttwktf",
            "fgggtttttttf",
            "fttttnnttttf",
            "ftmWWWWWWmtf",
            "fftmmmmmmtff",
        ]},
        "UpperTorso": {"base": suit, "legend": legend, "front": [
            "ppppWyyyWpppp",
            "pppppWyWppppp",
            "ppppppWpppppp",
            "ppppppopppppp",
            "ppppppppppppp",
            "ppppppopppppp",
            "ppppppppppppp",
            "ppppppopppppp",
            "ppppppppppppp",
        ]},
        "LowerTorso": {"rows": [suit_dark] * 5 + [suit] * 4, "legend": legend, "front": [
            "pppppp.pppppp",
            "pppppp.pppppp",
            "pppppp.pppppp",
            "pppppdddppppp",
            "ddddddddddddd",
            "ddddddddddddd",
            "ddddddddddddd",
            "ddddddddddddd",
            "ddddddddddddd",
        ]},
    }
    parts.update(limbs(
        [suit] * 6, [WHITE] + [suit] * 6, glove,
        [suit_dark] * 8, [suit_dark] * 7, [BLACK, BLACK, BLACK],
    ))
    hat = lambda i, j, k, nx, ny, nz: tie if k == 0 else BLACK

    def ear(i, j, k, nx, ny, nz):
        inner = 0 < j < ny - 1 and 0 < k < nz - 1
        return tan if inner else fur

    extras = {
        "Head": [
            ((-0.56, -0.48, 4.478, 0.56, 0.36, 4.578), BLACK),          # hat brim
            ((-0.38, -0.30, 4.578, 0.38, 0.22, 5.178), hat),            # hat crown, banana-yellow band
            ((0.578, -0.25, 3.80, 0.778, 0.05, 4.20), ear),             # left ear
            ((-0.778, -0.25, 3.80, -0.578, 0.05, 4.20), ear),           # right ear
        ],
        "LowerTorso": [
            ((-0.05, 0.403, 1.95, 0.05, 0.603, 2.05), fur),             # tail base
            ((-0.05, 0.603, 1.95, 0.05, 0.703, 2.55), fur),             # tail curling up
            ((-0.05, 0.503, 2.45, 0.05, 0.603, 2.65), fur),
        ],
    }
    return {"parts": parts, "extras": extras}


# --------------------------------------------------------------------------- COMMON: Grandma Pearl
def grandma_pearl():
    skin = pal("skin_pale", (250, 212, 182))
    nose = pal("skin_pale_shade", (225, 185, 155))
    hair = pal("hair_grey", (205, 205, 212))
    frame = pal("glasses_frame", (90, 60, 120))
    blush = pal("blush", (235, 120, 120))
    cardigan = pal("cardigan_pink", (240, 130, 170))
    skirt = pal("skirt_lavender", (180, 150, 220))
    sole = pal("sole_grey", (150, 150, 160))
    legend = {"h": hair, "s": skin, "b": hair, "g": frame, "w": EYE_WHITE, "k": BLACK, "n": nose, "m": MOUTH,
              "r": blush, "c": cardigan, "W": WHITE, "o": WHITE, "u": GOLD}
    parts = {
        "Head": {"base": skin, "top": hair, "back_rows": {k: hair for k in range(6, 10)}, "legend": legend, "front": [
            "hhhhhhhhhhhh",
            "hhhhhhhhhhhh",
            "hssssssssssh",
            "sbbbssssbbbs",
            "sggggssggggs",
            "sgwkgssgkwgs",
            "sggggnnggggs",
            "ssrssssssrss",
            "sssmssssmsss",
            "ssssmmmmssss",
        ]},
        "UpperTorso": {"base": cardigan, "legend": legend, "front": [
            "ccccoWWWocccc",
            "cccccoWoccccc",
            "ccccuWWWucccc",
            "ccccWWWWWcccc",
            "cccuWWWWWuccc",
            "ccccWWWWWcccc",
            "cccuWWWWWuccc",
            "ccccWWWWWcccc",
            "ccccWWWWWcccc",
        ]},
        "LowerTorso": {"base": skirt},
    }
    parts.update(limbs(
        [cardigan] * 6, [WHITE] + [cardigan] * 6, skin,
        [skin, skin] + [skirt] * 6, [WHITE, WHITE] + [skin] * 5, [sole, WHITE, WHITE],
    ))
    cane = lambda i, j, k, nx, ny, nz: GOLD if k == nz - 1 else WOOD_DARK
    extras = {
        "Head": [((-0.25, 0.0, 4.478, 0.25, 0.35, 4.778), hair)],          # bun
        "RightHand": [((-0.80, -0.30, 0.0, -0.70, -0.20, 1.60), cane)],     # walking cane
    }
    return {"parts": parts, "extras": extras}


# ----------------------------------------------------------------------------- COMMON: Skater Kev
def skater_kev():
    skin = pal("skin_brown", (190, 130, 90))
    nose = pal("skin_brown_shade", (165, 108, 72))
    hair = pal("hair_ginger", (200, 110, 50))
    cap = pal("cap_red", (220, 50, 50))
    hoodie = pal("hoodie_green", (70, 180, 90))
    hood = pal("hoodie_green_dark", (50, 140, 70))
    jeans = pal("jeans", (70, 110, 190))
    board = pal("board_purple", (150, 80, 220))
    legend = {"r": cap, "h": hair, "s": skin, "b": hair, "w": EYE_WHITE, "k": BLACK, "n": nose, "m": MOUTH,
              "g": hoodie, "G": hood, "W": WHITE, "j": jeans}
    parts = {
        "Head": {"base": skin, "top": cap, "back_rows": {9: cap, 8: cap, 7: hair, 6: hair}, "legend": legend, "front": [
            "rrrrrrrrrrrr",
            "rrrrrrrrrrrr",
            "hhhhsssshhhh",
            "hbbbssssbbbh",
            "swwwwsswwwws",
            "swwkwsswkwws",
            "sssssnnsssss",
            "ssssssssssss",
            "ssssssmmmsss",
            "ssssssssssss",
        ]},
        "UpperTorso": {"base": hoodie, "back_rows": {8: hood, 7: hood}, "legend": legend, "front": [
            "GGGGGgggGGGGG",
            "gggggWgWggggg",
            "gggggWgWggggg",
            "ggggggggggggg",
            "ggggggggggggg",
            "ggggGGGGGgggg",
            "ggggGGGGGgggg",
            "ggggggggggggg",
            "ggggggggggggg",
        ]},
        "LowerTorso": {"rows": [jeans] * 6 + [hoodie] * 3, "legend": legend, "front": [
            "ggggggggggggg",
            "ggggggggggggg",
            "GGGGGGGGGGGGG",
            "jjjjjjjjjjjjj",
            "jjjjjjjjjjjjj",
            "jjjjjj.jjjjjj",
            "jjjjjjjjjjjjj",
            "jjjjjjjjjjjjj",
            "jjjjjjjjjjjjj",
        ]},
    }
    parts.update(limbs(
        [hoodie] * 6, [hood] + [hoodie] * 6, skin,
        [jeans] * 8, [jeans, jeans, skin, jeans, jeans, jeans, jeans], [WHITE, BLACK, BLACK],
    ))
    deck = lambda i, j, k, nx, ny, nz: BLACK if (k == 0 and j in (1, ny - 2)) else board
    extras = {
        "Head": [((-0.4, 0.353, 4.33, 0.4, 0.653, 4.43), cap)],             # backwards cap brim
        "LeftHand": [((0.892, -0.75, 1.30, 0.992, 0.75, 1.62), deck)],      # skateboard under the arm
    }
    return {"parts": parts, "extras": extras}


# -------------------------------------------------------------------- UNCOMMON: Captain Barnacle
def captain_barnacle():
    skin = pal("skin_sun", (235, 180, 140))
    nose = pal("skin_sun_shade", (210, 150, 115))
    beard = pal("beard_white", (240, 240, 245))
    navy = pal("captain_navy", (35, 50, 100))
    coat = pal("raincoat_yellow", (250, 200, 40))
    coat_dark = pal("raincoat_yellow_dark", (215, 165, 25))
    boots = BLACK
    legend = {"h": beard, "s": skin, "w": EYE_WHITE, "k": BLACK, "n": nose, "m": MOUTH,
              "y": coat, "Y": coat_dark, "o": BLACK}
    parts = {
        "Head": {"base": skin, "top": beard, "back_rows": {k: beard for k in range(6, 10)}, "legend": legend, "front": [
            "hhhhhhhhhhhh",
            "hssssssssssh",
            "shhhhsshhhhs",
            "swwwwsswwwws",
            "swkwwsswwkws",
            "sssssnnsssss",
            "shhhhhhhhhhs",
            "hhhmmmmmmhhh",
            "hhhhhhhhhhhh",
            "shhhhhhhhhhs",
        ]},
        "UpperTorso": {"base": coat, "legend": legend, "front": [
            "YYYYYyyyYYYYY",
            "yyyyyyyyyyyyy",
            "yyyyyyoyyyyyy",
            "yyyyyyyyyyyyy",
            "yyyyyyoyyyyyy",
            "yyyyyyyyyyyyy",
            "yyyyyyoyyyyyy",
            "yyyyyyyyyyyyy",
            "yyyyyyyyyyyyy",
        ]},
        "LowerTorso": {"rows": [navy] * 4 + [coat] * 5, "legend": legend},
    }
    parts.update(limbs(
        [coat] * 6, [coat_dark] + [coat] * 6, skin,
        [navy] * 8, [boots, boots, boots, navy, navy, navy, navy], [boots, boots, boots],
    ))

    def band(i, j, k, nx, ny, nz):
        return GOLD if (j == 0 and nx // 2 - 1 <= i <= nx // 2 and k == 1) else navy

    extras = {
        "Head": [
            ((-0.62, -0.52, 4.478, 0.62, 0.40, 4.678), band),               # cap band with gold anchor
            ((-0.70, -0.62, 4.678, 0.70, 0.50, 4.878), WHITE),              # white crown
            ((-0.50, -0.78, 4.43, 0.50, -0.473, 4.53), BLACK),              # visor
            ((-0.40, -0.573, 3.43, 0.40, -0.473, 3.73), beard),             # bushy beard sticking out
        ],
    }
    return {"parts": parts, "extras": extras}


# ----------------------------------------------------------------------------- UNCOMMON: Dr. Fizz
def dr_fizz():
    skin = pal("skin_pale", (250, 212, 182))
    nose = pal("skin_pale_shade", (225, 185, 155))
    hair = pal("hair_white", (248, 248, 252))
    lens = pal("goggle_lens", (90, 220, 240))
    shirt = pal("shirt_purple", (140, 80, 200))
    tie = pal("tie_green", (80, 200, 90))
    coat = pal("labcoat", (250, 250, 252))
    pocket = pal("labcoat_pocket", (220, 222, 230))
    pants = pal("pants_purple", (95, 55, 140))
    shoe = pal("shoe_brown", (110, 70, 40))
    goo = pal("goo_green", (120, 255, 120))
    legend = {"h": hair, "s": skin, "b": hair, "k": BLACK, "c": lens, "w": EYE_WHITE, "n": nose, "m": MOUTH,
              "W": coat, "p": shirt, "g": tie, "q": pocket, "o": BLACK}
    parts = {
        "Head": {"base": skin, "top": hair, "back_rows": {k: hair for k in range(5, 10)}, "legend": legend, "front": [
            "hhhhhhhhhhhh",
            "kccckkkkccck",
            "kccckkkkccck",
            "sbbbbssbbbbs",
            "swwwwsswwwws",
            "swwkwsswkwws",
            "sssssnnsssss",
            "ssssssssssss",
            "ssmwwwwwwmss",
            "sssmmmmmmsss",
        ]},
        "UpperTorso": {"base": coat, "legend": legend, "front": [
            "WWWWWpppWWWWW",
            "WWWWWpgpWWWWW",
            "WWWWWpgpWWWWW",
            "WWWWWpgpWWWWW",
            "WWWWWpgpWqqWW",
            "WWWWWpppWqqWW",
            "WWWWWWoWWWWWW",
            "WWWWWWWWWWWWW",
            "WWWWWWoWWWWWW",
        ]},
        "LowerTorso": {"rows": [pants] * 4 + [coat] * 5, "legend": legend},
    }
    parts.update(limbs(
        [coat] * 6, [coat] * 7, skin,
        [pants] * 8, [pants] * 7, [shoe, shoe, shoe],
    ))
    wild = lambda i, j, k, nx, ny, nz: None if (i + j + k) % 4 == 0 and k == nz - 1 else hair
    extras = {
        "Head": [
            ((0.578, -0.30, 3.90, 0.828, 0.35, 4.60), wild),               # wild hair, left
            ((-0.828, -0.30, 3.90, -0.578, 0.35, 4.60), wild),             # wild hair, right
            ((-0.45, -0.20, 4.478, 0.45, 0.35, 4.778), wild),              # wild hair, top
        ],
        "RightHand": [((-0.83, -0.40, 1.55, -0.67, -0.16, 1.90), goo)],    # bubbling beaker
    }
    return {"parts": parts, "extras": extras}


# ---------------------------------------------------------------------------- RARE: Tung Tung Sahur
def tung_tung_sahur():
    log = pal("log_light", (205, 150, 95))
    grain = pal("log_grain", (160, 105, 60))
    end = pal("log_end", (232, 195, 140))
    bat = pal("bat_dark", (110, 65, 35))
    legend = {"l": log, "L": grain, "b": BLACK, "w": EYE_WHITE, "k": BLACK, "m": MOUTH, "W": WHITE}
    grain_front = ["lLllllLlllLll"] * 9
    parts = {
        "Head": {"base": log, "top": end, "legend": legend, "front": [
            "llllllllllll",
            "lLlllLllllLl",
            "lbbbllllbbbl",
            "lwwwwllwwwwl",
            "lwkkwllwkkwl",
            "lwkkwllwkkwl",
            "lwwwwllwwwwl",
            "llllllllllll",
            "lmWWWWWWWWml",
            "llmmmmmmmmll",
        ]},
        "UpperTorso": {"base": log, "legend": legend, "front": grain_front},
        "LowerTorso": {"base": log, "legend": legend, "front": grain_front},
    }
    parts.update(limbs(
        [log, grain, log, log, grain, log], [log, grain, log, log, log, grain, log], log,
        [log, grain, log, log, log, grain, log, log], [grain, log, log, log, grain, log, log], [grain, grain, grain],
    ))
    extras = {
        "RightHand": [
            ((-0.80, -0.30, 1.10, -0.70, -0.20, 1.90), bat),               # bat handle
            ((-0.86, -0.36, 0.40, -0.64, -0.14, 1.10), bat),               # bat barrel
        ],
    }
    return {"parts": parts, "extras": extras}


# --------------------------------------------------------------------------- RARE: B0-P "Beep"
def beep_bot():
    metal = pal("robot_metal", (185, 192, 205))
    joint = pal("robot_joint", (90, 95, 110))
    screen = pal("robot_screen", (20, 30, 45))
    glow = pal("robot_glow", (60, 230, 255))
    red = pal("light_red", (240, 60, 60))
    green = pal("light_green", (80, 230, 100))
    yellow = pal("light_yellow", (255, 220, 60))
    pizza = pal("pizza_orange", (255, 150, 40))
    box = pal("pizza_box", (205, 165, 115))
    legend = {"m": metal, "M": joint, "d": screen, "c": glow, "r": red, "g": green, "y": yellow, "P": pizza}
    parts = {
        "Head": {"base": metal, "legend": legend, "front": [
            "mmmmmmmmmmmm",
            "mddddddddddm",
            "mddddddddddm",
            "mddccddccddm",
            "mddccddccddm",
            "mddddddddddm",
            "mdcddddddcdm",
            "mddccccccddm",
            "mddddddddddm",
            "mmmmmmmmmmmm",
        ]},
        "UpperTorso": {"base": metal, "legend": legend, "front": [
            "mmmmmmmmmmmmm",
            "mMMMMMMMMMMMm",
            "mMrMgMyMdddMm",
            "mMMMMMMMMMMMm",
            "mmmmmmmmmmmmm",
            "mmmmmPPPmmmmm",
            "mmmmPPPPPmmmm",
            "mmmmmPPPmmmmm",
            "mmmmmmmmmmmmm",
        ]},
        "LowerTorso": {"rows": [metal, metal, metal, metal, joint, metal, metal, metal, metal]},
    }
    parts.update(limbs(
        [metal, metal, joint, metal, metal, joint], [metal, metal, metal, joint, metal, metal, metal], joint,
        [metal, metal, joint, metal, metal, metal, metal, joint], [metal, metal, metal, joint, metal, metal, metal],
        [joint, joint, joint],
    ))
    extras = {
        "Head": [
            ((-0.05, -0.05, 4.478, 0.05, 0.05, 4.878), joint),             # antenna
            ((-0.10, -0.10, 4.878, 0.10, 0.10, 5.078), red),               # blinking tip
            ((0.578, -0.15, 3.85, 0.678, 0.15, 4.05), joint),              # ear bolts
            ((-0.678, -0.15, 3.85, -0.578, 0.15, 4.05), joint),
        ],
        "LeftHand": [((0.45, -0.75, 1.85, 1.05, -0.15, 1.97), box)],      # pizza box delivery
    }
    return {"parts": parts, "extras": extras}


# Order: Common, Uncommon, Rare. Ids are saved/referenced in Config, so never rename one.
ROSTER = {
    "NeighborDave": neighbor_dave,
    "GrandmaPearl": grandma_pearl,
    "SkaterKev": skater_kev,
    "RosaTheBaker": rosa_the_baker,
    "CaptainBarnacle": captain_barnacle,
    "DrFizz": dr_fizz,
    "TungTungSahur": tung_tung_sahur,
    "BaronVonBanana": baron_von_banana,
    "BeepBot": beep_bot,
}
