# tools/blender/brickkit.py - the brick character kit for Blender (2026-10-13). A Python twin of the game's
# tools/brick/BrickKit.lua (same frame, same face, same naming), so characters designed in Blender match the cast:
# studded bricks, smooth plates for face / trims, square eyes, Neon only where it shines. Parts are authored in
# ROBLOX model space (y up, the character faces -Z, +X = the character's LEFT, feet at y = 0) and exported as JSON
# Parts for tools/zones/BuildLawyersTop.lua; Blender is the preview (see to_blender).
# Part names follow Shared.Puppet: Head (the head block only), HeadDetail, UpperTorso, Left/RightUpperArm,
# Left/RightUpperLeg. Parts can carry an "fx" (Shared.Puppet animates them on top of their limb):
#   rot  = keep turning   (axis through pivot, amp deg/s)          halos, orbiting planets, foxfire
#   osc  = swing          (axis through pivot, amp deg, rate Hz)   wings, tails, capes, flames
#   bob  = float up/down  (along axis, amp studs, rate Hz)         floating crowns, orbs
import math, json
from mathutils import Matrix, Vector

V = Vector


def hexc(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


C = dict(
    White=hexc("f2efe8"), EyeWhite=hexc("fbfaf6"), Ink=hexc("24242c"), Border=hexc("1c1c20"), Pupil=hexc("0f0f12"),
    Mouth=hexc("5a1419"), Tongue=hexc("d84a5a"), Teeth=hexc("fbfaf6"),
    Gold=hexc("ffc828"), GoldDark=hexc("d99a10"), Rare=hexc("3ca0ff"), Epic=hexc("b45aff"), Crimson=hexc("e53935"),
)
RAINBOW = [hexc(h) for h in ("ff5050", "ffaa3c", "ffe650", "5ae66e", "50aaff", "a064ff")]

D = dict(legW=0.9, legD=0.9, legH=1.3, legGap=0.1, shoeH=0.3, torsoW=2.0, torsoH=1.5, torsoD=1.1,
         armW=0.7, armD=0.8, armH=1.45, armGap=0.04, handH=0.42, headW=2.0, headH=1.8, headD=1.8)
hipY = D["legH"]
shoulderY = D["legH"] + D["torsoH"]
headY = D["legH"] + D["torsoH"] + D["headH"] / 2
headTop = D["legH"] + D["torsoH"] + D["headH"]
faceZ = -D["headD"] / 2
armX = D["torsoW"] / 2 + D["armGap"] + D["armW"] / 2
legX = (D["legW"] + D["legGap"]) / 2


def rot_matrix(r):
    """Euler degrees -> 3x3, the same as Roblox CFrame.Angles(rx, ry, rz) (= Rx * Ry * Rz)."""
    rx, ry, rz = (math.radians(a) for a in r)
    return Matrix.Rotation(rx, 3, "X") @ Matrix.Rotation(ry, 3, "Y") @ Matrix.Rotation(rz, 3, "Z")


def arm_name(side):
    return "RightUpperArm" if side < 0 else "LeftUpperArm"


def leg_name(side):
    return "RightUpperLeg" if side < 0 else "LeftUpperLeg"


class Kit:
    def __init__(self, id, rarity, scale=1.0, egg=""):
        self.id, self.rarity, self.scale, self.egg = id, rarity, scale, egg
        self.parts = []
        self.td = D["torsoD"]
        self.skin = C["White"]

    # ------------------------------------------------------------------ primitives
    def _add(self, kind, name, size, pos, col, rot=(0, 0, 0), surf="brick", fx=None, R=None):
        R = R if R is not None else rot_matrix(rot)
        p = dict(n=name, k=kind, s=list(size), p=list(pos), R=R.copy(), c=tuple(col), t=surf, fx=fx)
        self.parts.append(p)
        return p

    def brick(self, name, size, pos, col, rot=(0, 0, 0), fx=None, R=None):
        return self._add("box", name, size, pos, col, rot, "brick", fx, R)

    def plate(self, name, size, pos, col, rot=(0, 0, 0), fx=None, R=None):
        return self._add("box", name, size, pos, col, rot, "plate", fx, R)

    def glow(self, name, size, pos, col, rot=(0, 0, 0), fx=None, R=None):
        return self._add("box", name, size, pos, col, rot, "neon", fx, R)

    def wedge(self, name, size, pos, col, rot=(0, 0, 0), surf="brick", fx=None, R=None):
        """Roblox WedgePart: the top rises toward +Z (full height at the back face)."""
        return self._add("wedge", name, size, pos, col, rot, surf, fx, R)

    def cyl(self, name, size, pos, col, rot=(0, 0, 0), surf="plate", fx=None, R=None):
        """Roblox cylinder: the axis runs along the part's X."""
        return self._add("cyl", name, size, pos, col, rot, surf, fx, R)

    def ball(self, name, d, pos, col, surf="plate", fx=None):
        return self._add("ball", name, (d, d, d), pos, col, (0, 0, 0), surf, fx)

    # ------------------------------------------------------------------ body (same as BrickKit:body)
    def body(self, skin, shirt, pants=None, shoes=None, sleeve=None, hands=None, sleeves="long", legs="long",
             torsoD=None, sole=None, tights=None, skirtLen=0.8, flare=0.2):
        pants = pants or shirt
        shoes = shoes or C["Ink"]
        sleeve = sleeve or shirt
        hands = hands or skin
        self.skin = skin
        for s in (-1, 1):
            x, leg = s * legX, leg_name(s)
            self.brick(leg, (D["legW"] + 0.04, D["shoeH"], D["legD"] + 0.2), (x, D["shoeH"] / 2, -0.1), shoes)
            if sole:
                self.plate(leg, (D["legW"] + 0.08, 0.08, D["legD"] + 0.24), (x, 0.04, -0.1), sole)
            top = D["shoeH"]
            if legs == "skirt":
                self.brick(leg, (D["legW"] - 0.08, hipY - top, D["legD"] - 0.08), (x, top + (hipY - top) / 2, 0), tights or skin)
            else:
                self.brick(leg, (D["legW"], hipY - top, D["legD"]), (x, top + (hipY - top) / 2, 0), pants)
        td = torsoD or D["torsoD"]
        self.td = td
        self.brick("UpperTorso", (D["torsoW"], D["torsoH"], td), (0, hipY + D["torsoH"] / 2, 0), shirt)
        if legs == "skirt":
            self.brick("UpperTorso", (D["torsoW"] + 0.12 + flare, skirtLen, td + 0.12 + flare), (0, hipY - skirtLen / 2 + 0.02, 0), pants)
        for s in (-1, 1):
            x, arm = s * armX, arm_name(s)
            upper = D["armH"] - D["handH"]
            if sleeves == "long":
                self.brick(arm, (D["armW"], upper, D["armD"]), (x, shoulderY - upper / 2, 0), sleeve)
            else:
                self.brick(arm, (D["armW"] - 0.06, upper, D["armD"] - 0.06), (x, shoulderY - upper / 2, 0), skin)
            self.brick(arm, (D["armW"] - 0.02, D["handH"], D["armD"] - 0.02), (x, shoulderY - D["armH"] + D["handH"] / 2, 0), hands)
        self.head = self.brick("Head", (D["headW"], D["headH"], D["headD"]), (0, headY, 0), skin)
        return self

    def front(self, extra=0.0):
        return -self.td / 2 - extra

    def hand(self, side):
        return V((side * armX, shoulderY - D["armH"] + D["handH"] / 2, 0))

    # ------------------------------------------------------------------ face
    def eye(self, x, y, w=0.5, h=0.56, look=(0, 0), lid=0.0, lidColor=None, border=True, z=None, white=None, pupil=None, glowPupil=False):
        z = faceZ if z is None else z
        if border:
            self.plate("HeadDetail", (w + 0.06, h + 0.06, 0.04), (x, y, z - 0.02), C["Border"])
        self.plate("HeadDetail", (w, h, 0.04), (x, y, z - 0.045), white or C["EyeWhite"])
        pw, ph = w * 0.52, h * 0.6
        px, py = x + look[0] * (w - pw) / 2, y + look[1] * (h - ph) / 2
        if glowPupil:
            self.glow("HeadDetail", (pw, ph, 0.04), (px, py, z - 0.07), pupil or C["Pupil"])
        else:
            self.plate("HeadDetail", (pw, ph, 0.04), (px, py, z - 0.07), pupil or C["Pupil"])
        if lid > 0:
            lh = h * lid
            self.plate("HeadDetail", (w + 0.06, lh + 0.03, 0.04), (x, y + h / 2 - lh / 2 + 0.015, z - 0.095), lidColor or self.skin)

    def eyes(self, y=0.05, gap=0.92, w=0.5, h=0.56, look=(0, 0), inward=0.0, lid=0.0, lidColor=None, z=None, white=None, pupil=None, glowPupil=False):
        for s in (-1, 1):
            lx = max(-1, min(1, look[0] - s * inward))
            self.eye(s * gap / 2, headY + y, w, h, (lx, look[1]), lid, lidColor, True, z, white, pupil, glowPupil)

    def brows(self, col, y=0.05, h=0.56, gap=0.92, tilt=0, raise_=0.0, w=0.56, thick=0.13, z=None):
        yy = headY + y + h / 2 + 0.16 + raise_
        z = faceZ if z is None else z
        for s in (-1, 1):
            self.plate("HeadDetail", (w, thick, 0.05), (s * gap / 2, yy, z - 0.04), col, (0, 0, s * tilt))

    def nose(self, col=None, y=-0.24, size=(0.3, 0.26, 0.18)):
        self.plate("HeadDetail", size, (0, headY + y, faceZ - size[2] / 2), col or self.skin)

    def mouth(self, style="flat", y=-0.56, w=0.5, h=None, z=None):
        yy = headY + y
        z = (faceZ if z is None else z) - 0.03
        if style == "flat":
            self.plate("HeadDetail", (w, 0.1, 0.04), (0, yy, z), C["Mouth"])
        elif style == "smile":
            self.plate("HeadDetail", (w - 0.12, 0.1, 0.04), (0, yy, z), C["Mouth"])
            for s in (-1, 1):
                self.plate("HeadDetail", (0.1, 0.18, 0.04), (s * (w / 2 - 0.05), yy + 0.04, z), C["Mouth"])
        elif style == "grin":
            hh = h or 0.26
            self.plate("HeadDetail", (w, hh, 0.04), (0, yy, z), C["Mouth"])
            self.plate("HeadDetail", (w - 0.1, 0.08, 0.04), (0, yy + hh / 2 - 0.07, z - 0.01), C["Teeth"])
            self.plate("HeadDetail", (w * 0.5, 0.07, 0.04), (0, yy - hh / 2 + 0.06, z - 0.01), C["Tongue"])
        elif style == "smirk":
            self.plate("HeadDetail", (w, 0.1, 0.04), (0, yy, z), C["Mouth"])
            self.plate("HeadDetail", (0.1, 0.18, 0.04), (w / 2 - 0.05, yy + 0.05, z), C["Mouth"])

    # ------------------------------------------------------------------ hair / hats
    def hairCap(self, col, top=0.22, back=1.25, sideburn=0.75, fringe=0.0, cover=0.3):
        W, Dd = D["headW"] + 0.12, D["headD"] + 0.12
        topY = headTop + top
        self.brick("HeadDetail", (W, cover + top, Dd), (0, topY - (cover + top) / 2, 0), col)
        self.brick("HeadDetail", (W, back, 0.16), (0, headTop - back / 2, D["headD"] / 2 + 0.08), col)
        for s in (-1, 1):
            self.brick("HeadDetail", (0.12, sideburn, D["headD"] * 0.7), (s * (D["headW"] / 2 + 0.06), headTop - sideburn / 2, D["headD"] * 0.15), col)
        if fringe > 0:
            self.brick("HeadDetail", (W, fringe, 0.16), (0, headTop - cover - fringe / 2 + 0.02, faceZ - 0.08), col)
        return topY

    def crown(self, col, gem=None, lift=0.0, w=None, d=None, neon_gem=False, points=3):
        HT = headTop + lift
        w = w or D["headW"] - 0.2
        d = d or D["headD"] - 0.2
        self.brick("HeadDetail", (w, 0.36, d), (0, HT + 0.18, 0), col)
        xs = [(-w / 2 + 0.15) + i * (w - 0.3) / (points - 1) for i in range(points)]
        for x in xs:
            for z in (-d / 2 + 0.07, d / 2 - 0.07):
                self.brick("HeadDetail", (0.3, 0.38, 0.14), (x, HT + 0.55, z), col)
        for s in (-1, 1):
            self.brick("HeadDetail", (0.14, 0.38, 0.3), (s * (w / 2 - 0.07), HT + 0.55, 0), col)
        if gem:
            (self.glow if neon_gem else self.plate)("HeadDetail", (0.26, 0.22, 0.05), (0, HT + 0.18, -d / 2 - 0.03), gem)
        return HT + 0.74

    # ------------------------------------------------------------------ outfit (UpperTorso)
    def lapels(self, jacket, shirt, depth=0.85, lapel=None, panel=0.62):
        z = self.front()
        self.plate("UpperTorso", (panel, depth, 0.05), (0, shoulderY - depth / 2, z - 0.025), shirt)
        for s in (-1, 1):
            self.plate("UpperTorso", (0.3, depth + 0.1, 0.06), (s * 0.38, shoulderY - depth / 2 - 0.02, z - 0.05), lapel or jacket, (0, 0, s * 22))

    def tie(self, col, length=0.62, glow=False):
        z = self.front() - 0.09
        f = self.glow if glow else self.plate
        f("UpperTorso", (0.26, 0.2, 0.08), (0, shoulderY - 0.12, z), col)
        f("UpperTorso", (0.2, length, 0.06), (0, shoulderY - 0.22 - length / 2, z + 0.01), col)
        f("UpperTorso", (0.13, 0.13, 0.06), (0, shoulderY - 0.22 - length - 0.03, z + 0.01), col, (0, 0, 45))

    def belt(self, col, buckle=None):
        y = hipY + 0.08
        self.brick("UpperTorso", (D["torsoW"] + 0.06, 0.18, self.td + 0.06), (0, y, 0), col)
        if buckle:
            self.plate("UpperTorso", (0.3, 0.22, 0.06), (0, y, self.front(0.06)), buckle)

    def buttons(self, n, col, x=0.0, yTop=None, dy=0.28):
        yTop = shoulderY - 0.35 if yTop is None else yTop
        for i in range(n):
            self.plate("UpperTorso", (0.1, 0.1, 0.05), (x, yTop - i * dy, self.front(0.06)), col)

    def badge(self, col, x, y, w=0.3, h=0.3, glow=False):
        return (self.glow if glow else self.plate)("UpperTorso", (w, h, 0.05), (x, y, self.front() - 0.04), col)

    def torsoBand(self, y, h, col):
        self.plate("UpperTorso", (D["torsoW"] + 0.04, h, self.td + 0.04), (0, y, 0), col)

    def armBand(self, y, h, col, glow=False):
        for s in (-1, 1):
            (self.glow if glow else self.plate)(arm_name(s), (D["armW"] + 0.04, h, D["armD"] + 0.04), (s * armX, y, 0), col)

    def legBand(self, y, h, col):
        for s in (-1, 1):
            self.plate(leg_name(s), (D["legW"] + 0.04, h, D["legD"] + 0.04), (s * legX, y, 0), col)

    def coat(self, col, length, open_=False, gap=0.3, trim=None, hem=None):
        td = self.td
        W = D["torsoW"] + 0.12
        top = hipY + 0.15
        bottom = max(0.05, hipY - length)
        h = top - bottom
        cy = (top + bottom) / 2
        g = gap if open_ else 0
        fw = (W - g) / 2
        for s in (-1, 1):
            self.brick("UpperTorso", (fw, h, 0.12), (s * (g / 2 + fw / 2), cy, -td / 2 - 0.06), col)
            self.brick("UpperTorso", (0.12, h, td + 0.12), (s * (W / 2 - 0.06), cy, 0), col)
            if trim:
                self.plate("UpperTorso", (0.12, h, 0.04), (s * (g / 2 + 0.06), cy, -td / 2 - 0.13), trim)
        self.brick("UpperTorso", (W, h, 0.12), (0, cy, td / 2 + 0.06), col)
        if hem:
            self.plate("UpperTorso", (W + 0.04, 0.14, td + 0.28), (0, bottom + 0.07, 0), hem)

    def robe(self, col, open_=False, trim=None, hem=None, sleeve=None):
        self.coat(col, hipY - 0.08, open_, 0.4, trim, hem)
        for s in (-1, 1):
            self.brick(arm_name(s), (D["armW"] + 0.2, 0.5, D["armD"] + 0.2), (s * armX, shoulderY - D["armH"] + D["handH"] + 0.2, 0), sleeve or col)

    def cape(self, col, length=2.4, trim=None, collar=None, width=None, fx=None, glowTrim=False):
        td = self.td
        W = width or D["torsoW"] + 0.5
        pivot = (0, shoulderY + 0.05, td / 2 + 0.12)
        f = fx and dict(fx, pivot=pivot)
        self.brick("UpperTorso", (W, length, 0.12), (0, shoulderY - length / 2 + 0.05, td / 2 + 0.12), col, fx=f)
        if trim:
            (self.glow if glowTrim else self.plate)("UpperTorso", (W + 0.04, 0.16, 0.16), (0, shoulderY - length + 0.12, td / 2 + 0.12), trim, fx=f)
        if collar:
            self.brick("UpperTorso", (D["torsoW"] + 0.3, 0.45, 0.14), (0, shoulderY + 0.15, td / 2 + 0.05), collar, (-15, 0, 0))

    def boots(self, col, h=0.75, cuff=None):
        for s in (-1, 1):
            self.brick(leg_name(s), (D["legW"] + 0.06, h, D["legD"] + 0.06), (s * legX, D["shoeH"] + h / 2 - 0.02, 0), col)
            if cuff:
                self.plate(leg_name(s), (D["legW"] + 0.12, 0.14, D["legD"] + 0.12), (s * legX, D["shoeH"] + h - 0.05, 0), cuff)

    def pauldron(self, col, trim=None, glowTrim=False):
        for s in (-1, 1):
            a = arm_name(s)
            self.brick(a, (D["armW"] + 0.34, 0.3, D["armD"] + 0.3), (s * (armX + 0.06), shoulderY + 0.06, 0), col)
            self.brick(a, (D["armW"] + 0.2, 0.22, D["armD"] + 0.2), (s * (armX + 0.1), shoulderY - 0.18, 0), col)
            if trim:
                (self.glow if glowTrim else self.plate)(a, (D["armW"] + 0.38, 0.07, D["armD"] + 0.34), (s * (armX + 0.06), shoulderY - 0.06, 0), trim)

    # ------------------------------------------------------------------ props & poses
    def held(self, side, size, offset, col, rot=(0, 0, 0), surf="brick", kind="box", fx=None):
        at = self.hand(side) + V(offset)
        return self._add(kind, arm_name(side), size, tuple(at), col, rot, surf, fx)

    def poseArm(self, side, rot):
        """Rotate every part of that arm (call last) about the shoulder, like BrickKit:poseArm."""
        name = arm_name(side)
        pivot = V((side * armX, shoulderY - D["armW"] / 2, 0))
        R = rot_matrix(rot)
        for p in self.parts:
            if p["n"] == name:
                pos = V(p["p"])
                p["p"] = list(pivot + R @ (pos - pivot))
                p["R"] = R @ p["R"]
                if p["fx"] and "pivot" in p["fx"]:
                    pv = V(p["fx"]["pivot"])
                    p["fx"]["pivot"] = list(pivot + R @ (pv - pivot))
                    if "axis" in p["fx"]:
                        p["fx"]["axis"] = list(R @ V(p["fx"]["axis"]))

    # ------------------------------------------------------------------ shapes
    def ring(self, name, centre, radius, thick, n, col, tilt=(0, 0, 0), surf="neon", width=None, fx=None, start=0.0, arc=360.0):
        """A ring of n blocks (halos, planet rings, rims). tilt rotates the ring (degrees) about its centre."""
        c = V(centre)
        T = rot_matrix(tilt)
        seg = 2 * math.pi * radius * (arc / 360.0) / n * 1.08
        out = []
        for i in range(n):
            a = math.radians(start + arc * (i + 0.5) / n)
            local = V((math.cos(a) * radius, 0, math.sin(a) * radius))
            R = T @ Matrix.Rotation(-a, 3, "Y")
            pos = c + T @ local
            out.append(self._add("box", name, (width or thick, thick, seg), tuple(pos), col, surf=surf, fx=fx and dict(fx), R=R))
        return out

    def wing(self, side, root, col, tip, length=3.2, rows=4, spread=40, fx=None, glowTips=False, feather=(0.55, 0.12, 1.1), droop=0.0):
        """A feathered wing: fanned rows of long feather bricks from a shoulder-blade root. side = which side."""
        r = V(root)
        out = []
        for row in range(rows):
            n = 5 - (row // 2)
            ang0 = 15 + row * (spread / rows)
            for i in range(n):
                f = i / max(1, n - 1)
                L = length * (1.0 - row * 0.16) * (0.6 + 0.4 * f)
                a = math.radians(min(78.0, ang0 - 30 + f * 55 - droop))  # (never past straight up: it would cross to the other side)
                # feathers fan up-and-out from the root, angled back
                d = V((side * math.cos(a), math.sin(a), 0.35 + row * 0.12)).normalized()
                pos = r + d * (L / 2 + row * 0.28)
                up = V((0, 0, 1))
                Rm = d.to_track_quat("Y", "Z").to_matrix()
                colr = tip if (row == 0 and glowTips) else (tip if f > 0.75 else col)
                surf = "neon" if (glowTips and f > 0.75) else "brick"
                out.append(self._add("box", "UpperTorso", (feather[0] * (1 - row * 0.1), L, feather[1]), tuple(pos), colr, surf=surf,
                                     fx=fx and dict(fx, pivot=list(r)), R=Rm))
        return out

    def flames(self, name, base, n, height, radius, cols, fx=None, surf="neon", tilt=0.0):
        """A ring of flame tongues (stacked tapering blocks) rising from base."""
        b = V(base)
        out = []
        for i in range(n):
            a = 2 * math.pi * i / n
            h = height * (0.65 + 0.35 * ((i * 7) % 5) / 4)
            for j, (fr, col) in enumerate(zip((1.0, 0.7, 0.42), cols)):
                pos = b + V((math.cos(a) * radius * (1 - j * 0.15), h * (0.25 + j * 0.3), math.sin(a) * radius * (1 - j * 0.15)))
                out.append(self._add("box", name, (0.32 * fr, h * (0.55 - j * 0.12), 0.32 * fr), tuple(pos), col,
                                     rot=(math.degrees(math.sin(a)) * 0.2 + tilt, 0, -math.degrees(math.cos(a)) * 0.2), surf=surf,
                                     fx=fx and dict(fx, phase=i * 0.7)))
        return out

    # ------------------------------------------------------------------ export
    def export(self):
        s = self.scale
        parts = []
        for p in self.parts:
            R = p["R"]
            fx = None
            if p["fx"]:
                fx = dict(p["fx"])
                if "pivot" in fx:
                    fx["pivot"] = [round(v * s, 4) for v in fx["pivot"]]
                if fx.get("kind") == "bob":
                    fx["amp"] = round(fx["amp"] * s, 4)
            parts.append(dict(n=p["n"], k=p["k"], s=[round(v * s, 4) for v in p["s"]], p=[round(v * s, 4) for v in p["p"]],
                              r=[round(R[i][j], 5) for i in range(3) for j in range(3)], c=list(p["c"]), t=p["t"], fx=fx))
        return dict(id=self.id, rarity=self.rarity, scale=s, egg=self.egg, parts=parts)


# ------------------------------------------------------------------ Blender preview (Roblox space -> Blender)
M = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox (x, y, z) -> Blender (x, -z, y)


def mesh_for(bpy, kind):
    import bmesh
    name = "BK_" + kind
    me = bpy.data.meshes.get(name)
    if me:
        return me
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    if kind == "box":
        bmesh.ops.create_cube(bm, size=1.0)
    elif kind == "ball":
        bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.5)
    elif kind == "cyl":  # axis along Roblox X = Blender X
        bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.5, radius2=0.5, depth=1.0)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
    elif kind == "wedge":  # Roblox wedge (local): full height at +Z; in Blender local terms (x, -z, y)
        vs = [(-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5)]
        # Roblox local points (x, y, z) -> Blender (x, -z, y)
        bv = [bm.verts.new((x, -z, y)) for (x, y, z) in vs]
        for f in ((0, 1, 3, 2), (0, 2, 4), (1, 5, 3), (2, 3, 5, 4), (0, 4, 5, 1)):
            bm.faces.new([bv[i] for i in f])
    bm.to_mesh(me)
    bm.free()
    return me


def to_blender(bpy, sc, kit, offset, mats):
    """Instantiate a kit's parts in Blender at `offset` (Blender coords) for the preview."""
    s = kit.scale
    dummy = bpy.data.materials.get("BK_dummy") or bpy.data.materials.new("BK_dummy")
    for p in kit.parts:
        me = mesh_for(bpy, p["k"])
        if len(me.materials) == 0:
            me.materials.append(dummy)
        o = bpy.data.objects.new(kit.id + "_" + p["n"], me)
        R = M @ p["R"] @ M.transposed()
        pos = M @ (V(p["p"]) * s)
        sz = p["s"]
        o.matrix_world = Matrix.Translation(pos + V(offset)) @ R.to_4x4() @ Matrix.Diagonal((sz[0] * s, sz[2] * s, sz[1] * s, 1))
        key = (p["c"], p["t"])
        if key not in mats:
            mt = bpy.data.materials.new("BK_mat")
            mt.use_nodes = True
            bs = mt.node_tree.nodes.get("Principled BSDF")
            col = tuple((v / 255) ** 2.2 for v in p["c"]) + (1,)
            bs.inputs["Base Color"].default_value = col
            bs.inputs["Roughness"].default_value = 0.6 if p["t"] == "brick" else 0.4
            if p["t"] == "neon":
                bs.inputs["Emission Color"].default_value = col
                bs.inputs["Emission Strength"].default_value = 2.5
            mats[key] = mt
        sc.collection.objects.link(o)
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = mats[key]