# environment-redesign/kit/hl_v2.py - the V2 ISLAND FRAME (2026-10-20, mr.robe's session; user's call: "do the same for
# the rest of the islands"). crnuch's Ocean Shore v2 (approved 2026-10-19 as THE benchmark: ocean_shore_v2/osv2_build.py)
# turned into a reusable frame, so Pet Park, Brainrot Zone, Food Court and Space Base are redone to it the same way:
#   - classic Roblox studs, not LEGO (hl_classic.ClassicMesh; studs only on broad floor / terrain / structural tops);
#   - ONE continuous flat floor the boss roams (his box), egg regions across it, every spot DROP_MAX clear of the edge;
#   - the spawn dock + pad on one side, the purple escape portal (RETURN HOME, a level walk-in) on the other;
#   - all scenery (cliff massifs, pools, falls, themed landmarks, plants) outside the boss's reach (box + REACH);
#   - every number from the code (Config.Bosses / Config.Zones), the checks measured on the built geometry, a gameplay
#     diagram, a layout JSON in the benchmark's shape (places SPAWN / ESCAPE PORTAL, egg_regions, egg_spots, boss box).
# An island script makes a V2(...), calls body() / patches() / landmarks() / eggs() / scatter() / its own scenery with
# column() / push_out() / ring_plants() / pool(), then sky() / studs() / checks() / diagram() / finish().
# The benchmark's natural pieces (spawn dock + pad, escape portal, torches, ropes, crates, barrels, egg markers) come
# from ../ocean_shore_v2 (osv2_parts / osv2_detail), so every island shares the same spawn + portal language.
import bpy, json, math, os, random, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree

KIT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(KIT), "ocean_shore_v2"))
import hl_kit as K
import hl_classic as CL
import hl_island as HI
import osv2_parts as P
import osv2_detail as D

DROP_MAX = 14 * (1 + 0.04 * 12)  # Config.Bosses.DropScatter max x the 12-egg Diamond Briefcase spread = 20.7 studs
OBST = 2.5  # anything taller than this above the floor blocks an attack lane / a warning lane
K.PAL.update({"diag_red": (235, 50, 60), "diag_blue": (40, 110, 240), "diag_yellow": (250, 190, 30), "diag_purple": (150, 70, 230),
              "diag_charge": (255, 120, 120)})


class V2:
    def __init__(self, here, pfx, title, boss, box, *, center=(0.0, 5.0), A=138.0, B=123.0, nexp=8.0, portal=44.0, spawn=224.0,
                 floor_z=1.0, ring=50.0, seed=2020, portal_lobe=54.0, spawn_lobe=20.0, boss_pad=(0.0, 10.0)):
        self.here, self.pfx, self.title = here, pfx, title
        self.rng = random.Random(seed)
        K.rng.seed(seed)
        self.boss = boss
        kind = boss["Attack"] if isinstance(boss["Attack"], str) else boss["Attack"][0]
        self.kind = kind
        body = boss.get("HitboxWidth", 8.0) / 2
        # how far past the box edge an attack / his body can hit (the scenery keeps out of box + REACH + 1)
        self.reach = (boss["Width"] / 2 + body) if kind == "Line" else boss.get("Radius", 30) + body * 0.5
        self.center, self.box = center, box
        self.A, self.B, self.nexp = A, B, nexp
        self.NE, self.SW = portal, spawn
        self.portal_lobe, self.spawn_lobe = portal_lobe, spawn_lobe
        self.Z, self.ringw = floor_z, ring
        self.pad = boss_pad
        self.renders = os.path.join(here, "renders")
        os.makedirs(self.renders, exist_ok=True)
        self.scene = K.reset([title, "Vegetation", "Environmental_Effects", "Lighting", "Presentation"])
        self.C = K.COLS
        for n in ("Terrain", "Underside", "Scenery", "Water", "Play_Decor", "Landmarks", "Sky", "Labels", "Diagram",
                  "Gameplay_Markers", "Preview_Eggs"):
            K.col(f"{pfx}_{n}", title)
        self.used = []
        self.spots = []
        self.regions = {}
        self.LAYOUT = {"island": title, "places": [], "egg_regions": [], "egg_spots": [], "checks": {},
                       "boss": {"box_blender": list(box), "box_roblox_xz": [box[0], -box[3], box[2], -box[1]], "reach": round(self.reach, 1), **boss},
                       "fx": {"edge_lips": [], "pools": [], "gull_rings": [], "spinners": [], "steam": [], "motes": []}}

    def col(self, n):
        return self.C[f"{self.pfx}_{n}"]

    # ---------------------------------------------------------------- shape (the benchmark's squircle + lobes)
    def squircle(self, deg):
        a = math.radians(deg)
        return (abs(math.cos(a) / self.A) ** self.nexp + abs(math.sin(a) / self.B) ** self.nexp) ** (-1 / self.nexp)

    @staticmethod
    def lobe(deg, at, amp, sig):
        d = (deg - at + 180) % 360 - 180
        return amp * math.exp(-0.5 * (d / sig) ** 2)

    def r_sand(self, deg):
        a = math.radians(deg)
        return (self.squircle(deg) * (1 + 0.018 * math.sin(5 * a) + 0.01 * math.sin(11 * a + 1)) +
                self.lobe(deg, self.NE, self.portal_lobe, 8) + self.lobe(deg, self.SW, self.spawn_lobe, 9))

    def ring_w(self, deg):
        a = math.radians(deg)
        w = self.ringw + 14 * math.sin(3 * a + 0.7) + 7 * math.sin(7 * a)
        w -= self.lobe(deg, self.SW, self.ringw - 6, 9)  # (the spawn lobe meets the edge: the dock juts out over the drop)
        w -= self.lobe(deg, self.NE, 18, 10)
        return max(6.0, w)

    def r_isl(self, deg):
        return self.r_sand(deg) + self.ring_w(deg)

    def polar(self, r, deg, c=None):
        c = c or self.center
        return (c[0] + r * math.cos(math.radians(deg)), c[1] + r * math.sin(math.radians(deg)))

    def outline(self, fn, f=1.0, n=240):
        return [self.polar(fn(360 * i / n) * f, 360 * i / n) for i in range(n)]

    def ang(self, x, y):
        return math.degrees(math.atan2(y - self.center[1], x - self.center[0]))

    def in_sand(self, x, y, pad=0.0):
        return math.hypot(x - self.center[0], y - self.center[1]) < self.r_sand(self.ang(x, y)) - pad

    def in_box(self, x, y, pad=0.0):
        b = self.box
        return b[0] - pad <= x <= b[2] + pad and b[1] - pad <= y <= b[3] + pad

    def box_dist(self, x, y):
        b = self.box
        return math.hypot(max(b[0] - x, 0, x - b[2]), max(b[1] - y, 0, y - b[3]))

    def clear_of_reach(self, x, y, r=0.0):
        return not self.in_box(x, y, self.reach + 1 + r)

    def ring_pt(self, deg, f):
        return self.polar(self.r_sand(deg) + 5 + (self.ring_w(deg) - 9) * f, deg)

    def push_out(self, deg, f, r):
        x, y = self.ring_pt(deg, f)
        while not self.clear_of_reach(x, y, r) and f < 1.3:
            f += 0.04
            x, y = self.ring_pt(deg, f)
        return x, y, f

    def free(self, x, y, r):
        return not any(math.hypot(x - ux, y - uy) < ur + r for ux, uy, ur in self.used)

    def note(self, name, x, y, what):
        self.LAYOUT["places"].append({"name": name, "blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "what": what})

    @staticmethod
    def blob(cx, cy, r, n=14, seed=0.0):
        return [(cx + r * (1 + 0.25 * math.sin(3 * a + cx + seed)) * math.cos(a), cy + r * 0.8 * (1 + 0.2 * math.cos(2 * a + cy)) * math.sin(a))
                for a in [2 * math.pi * i / n for i in range(n)]]

    # ---------------------------------------------------------------- the island body: one cohesive piece + layered underside
    def body(self, rim="dirt_rim", rim_top="moss", floor="sand_dark", floor_top="sand", under=("rock_grey", "rock_grey_dark"),
             crags=("rock_grey", "rock_grey_dark", "rock_grey_light"), crag_top="moss", band=("dirt_rim", "dirt_rim_dark"),
             hang=None, vine=("vine", "moss", "moss_dark"), root="root"):
        rng = self.rng
        ter = CL.ClassicMesh("Island_Top", self.col("Terrain"))
        ter.slab(self.outline(self.r_isl), -10, 0.6, rim, chamfer=0.4, top=rim_top)
        fl = CL.ClassicMesh("Floor_Plateau", self.col("Terrain"))
        fl.slab(self.outline(self.r_sand, n=300), -0.2, self.Z, floor, chamfer=0.35, top=floor_top)
        und = CL.ClassicMesh("Island_Underside", self.col("Underside"))
        for k, (f, z0, z1) in enumerate(((0.93, -26, -10), (0.8, -44, -26), (0.62, -62, -44), (0.42, -78, -62), (0.22, -90, -78))):
            und.slab(self.outline(lambda d, f=f: self.r_isl(d) * f * (1 + 0.03 * math.sin(math.radians(9 * d) + f * 7))), z0, z1,
                     under[k % len(under)], chamfer=1.5)
        for k in range(150):  # craggy rock faces round the rim
            d = rng.uniform(0, 360)
            t = rng.random()
            f = 0.99 if t < 0.55 else (0.92 if t < 0.85 else 0.79)
            z0 = -10 - rng.uniform(0, 14) if f > 0.95 else (-28 if f > 0.9 else -46)
            x, y = self.polar(self.r_isl(d) * f - 1.5, d)
            s = rng.uniform(6, 13)
            und.rock(x, y, z0, s, s * 0.8, rng.uniform(6, 14), rng.choice(crags),
                     top=crag_top if crag_top and f > 0.95 and rng.random() < 0.6 else None, rot=d + rng.uniform(-20, 20))
        for k in range(60):  # hanging rocks
            d = rng.uniform(0, 360)
            f = rng.uniform(0.2, 0.85)
            x, y = self.polar(self.r_isl(d) * f, d)
            zt = -90 if f < 0.3 else (-62 - (0.62 - f) * 40 if f < 0.62 else -44)
            h = rng.uniform(8, 22)
            und.rock(x, y, zt - h, rng.uniform(5, 10), rng.uniform(4, 9), h, rng.choice(hang or under), rot=rng.uniform(0, 90), taper=-0.3)
        if vine:
            for k in range(40):
                d = rng.uniform(0, 360)
                x, y = self.polar(self.r_isl(d) + 0.3, d)
                L = rng.uniform(6, 18)
                c, s = math.cos(math.radians(d)), math.sin(math.radians(d))
                und.beam((x, y, 0.2), (x + c * 0.2, y + s * 0.2, 0.2 - L), 0.25, 0.25, vine[0])
                for j in range(int(L / 2.2)):
                    und.brick(x + c * 0.3, y + s * 0.3, -1.0 - j * 2.2, 0.9, 0.5, 0.9, vine[1 + j % 2], rot=d + j * 40, bevel=0.15)
        for k in range(220):  # the band right under the rim, chunky + uneven
            d = k * 360 / 220 + rng.uniform(-0.6, 0.6)
            x, y = self.polar(self.r_isl(d) - 0.6 + rng.uniform(-0.3, 0.6), d)
            und.rock(x, y, -9.5 + rng.uniform(-1.5, 1.5), rng.uniform(4, 7), rng.uniform(3, 5), rng.uniform(4, 8), rng.choice(band),
                     rot=d + 90 + rng.uniform(-8, 8), jitter=0.12, taper=0.0)
        if root:
            for k in range(70):
                d = rng.uniform(0, 360)
                x, y = self.polar(self.r_isl(d) + 0.4, d)
                p0 = (x, y, rng.uniform(-6, -2))
                for j in range(3):
                    p1 = (p0[0] + rng.uniform(-0.6, 0.6), p0[1] + rng.uniform(-0.6, 0.6), p0[2] - rng.uniform(1.5, 3.2))
                    und.beam(p0, p1, 0.3, 0.3, root)
                    p0 = p1
        ter.done()
        fl.done()
        und.done()

    def patches(self, looks, n=34, rmin=6, rmax=16):
        """Colour variation on the floor: flat, flush slabs (walk-through)."""
        rng = self.rng
        self.dec = CL.ClassicMesh("Floor_Decor", self.col("Play_Decor"))
        made = 0
        b = self.box
        while made < n:
            x, y = rng.uniform(b[0], b[2]), rng.uniform(b[1], b[3])
            if not self.in_sand(x, y, 14) or math.hypot(x - self.pad[0], y - self.pad[1]) < 20:
                continue
            self.dec.slab(self.blob(x, y, rng.uniform(rmin, rmax)), self.Z - 0.05, self.Z + 0.06, looks[made % len(looks)], chamfer=0.03)
            made += 1

    # ---------------------------------------------------------------- landmarks: spawn dock + pad, escape portal, the boss
    def landmarks(self, lamp=None, cargo=True, boss_facing=135.0, pad_fn=None, portal_fn=None, spawn_name="classic blue-and-white spawn pad at the end of a lit boardwalk"):
        rng = self.rng
        lm = CL.ClassicMesh("Landmarks", self.col("Landmarks"))
        self.lm = lm
        Z = self.Z
        tip = self.polar(self.r_sand(self.SW) - 4, self.SW)
        dock_end = self.polar(self.r_isl(self.SW) + 26, self.SW)
        self.SPAWN = self.polar(self.r_isl(self.SW) + 36, self.SW)
        self.tip, self.dock_end = tip, dock_end
        P.spawn_dock(lm, tip[0], tip[1], dock_end[0], dock_end[1], Z, width=12)
        P.spawn_pad(lm, *self.SPAWN, Z)
        dyaw = math.atan2(dock_end[1] - tip[1], dock_end[0] - tip[0])
        dlen = math.hypot(dock_end[0] - tip[0], dock_end[1] - tip[1])
        prev = {}
        for k in range(int(dlen / 8) + 1):
            t = min(1.0, k * 8 / dlen)
            px, py = tip[0] + (dock_end[0] - tip[0]) * t, tip[1] + (dock_end[1] - tip[1]) * t
            for sgn in (-1, 1):
                qx, qy = px - math.sin(dyaw) * sgn * 6.6, py + math.cos(dyaw) * sgn * 6.6
                (lamp or (lambda m, x, y, z: D.torch(m, x, y, z, 4.6)))(lm, qx, qy, Z)
                if sgn in prev:
                    D.rope(lm, (*prev[sgn], Z + 3.4), (qx, qy, Z + 3.4), 0.5)
                prev[sgn] = (qx, qy)
        if cargo:
            for k, (dl, dw) in enumerate(((6, -9), (9, 8), (12, -8.5))):
                cx, cy = tip[0] - math.cos(dyaw) * dl - math.sin(dyaw) * dw, tip[1] - math.sin(dyaw) * dl + math.cos(dyaw) * dw
                (D.crate if k % 2 else D.barrel)(lm, cx, cy, Z)
        self.note("SPAWN (arrival pad, safe zone)", *self.SPAWN, spawn_name)
        self.PORTAL = self.polar(self.r_sand(self.NE) - 16, self.NE)
        (portal_fn or P.escape_portal)(lm, *self.PORTAL, Z, rot=self.NE - 90)
        self.note("ESCAPE PORTAL (RETURN HOME)", *self.PORTAL, "purple vortex in a ring of craggy rock, flush with the floor (no stairs)")
        (pad_fn or P.boss_pad)(self.dec, *self.pad, self.Z + 0.06)
        self.note(f"{self.boss['Name']}'s start pad", *self.pad, "a subtle ring of sunken flat stones flush with the floor")
        lm.done()
        HI.boss(self.col("Landmarks"), self.boss["Model"], self.pad[0], self.pad[1], z=self.Z, scale=self.boss["Scale"], facing=boss_facing)
        self.used += [(self.PORTAL[0], self.PORTAL[1], 20), (self.SPAWN[0], self.SPAWN[1], 12)]

    # ---------------------------------------------------------------- egg regions (candidate EggSpots)
    def eggs(self, regions, preview_looks=("gold",), preview_fn=None):
        rng = self.rng
        self.regions = regions
        mk = CL.ClassicMesh("Egg_Spot_Markers", self.col("Gameplay_Markers"))
        pe = CL.ClassicMesh("Preview_Eggs", self.col("Preview_Eggs"))
        for name, ((cx, cy), R, why) in regions.items():
            self.LAYOUT["egg_regions"].append({"name": name, "blender_xy": [cx, cy], "roblox_xz": [cx, -cy], "radius": R, "risk": why})
            want = 6 if R >= 24 else 5
            tries = got = 0
            while got < want and tries < 3000:
                tries += 1
                a, f = rng.uniform(0, 2 * math.pi), math.sqrt(rng.uniform(0.05, 1))
                x, y = cx + R * f * math.cos(a), cy + R * f * math.sin(a)
                if not self.in_sand(x, y, DROP_MAX + 2) or not self.in_box(x, y, -4) or math.hypot(x - self.pad[0], y - self.pad[1]) < 22:
                    continue
                if any((x - qx) ** 2 + (y - qy) ** 2 < 81 for qx, qy, _ in self.spots):
                    continue
                self.spots.append((x, y, name))
                got += 1
        for i, (x, y, name) in enumerate(self.spots):
            P.egg_marker(mk, x, y, self.Z + 0.06)
            if i % 2 == 0:
                (preview_fn or (lambda m, x, y, z, i: P.preview_egg(m, x, y, z, preview_looks[i % len(preview_looks)])))(pe, x, y, self.Z, i)
            self.LAYOUT["egg_spots"].append({"blender_xy": [round(x, 1), round(y, 1)], "roblox_xz": [round(x, 1), round(-y, 1)], "region": name})
        mk.done()
        pe.done()

    def scatter(self, fn, n=260):
        """Small flat decor on the floor (walk-through, under OBST studs, never on an egg spot or the boss pad):
        fn(m, x, y, z, edge, roll) draws one piece (edge = near the floor's edge: richer decor there)."""
        rng = self.rng
        keep = [(x, y) for x, y, _ in self.spots]
        b = self.box
        for k in range(n):
            x, y = rng.uniform(b[0] - 14, b[2] + 14), rng.uniform(b[1] - 14, b[3] + 14)
            if not self.in_sand(x, y, 3) or math.hypot(x - self.pad[0], y - self.pad[1]) < 16 or any((x - a) ** 2 + (y - c) ** 2 < 25 for a, c in keep):
                continue
            fn(self.dec, x, y, self.Z, not self.in_sand(x, y, 22), rng.random())
        self.dec.done()

    # ---------------------------------------------------------------- the scenery ring
    def scenery_meshes(self):
        self.sc = CL.ClassicMesh("Scenery_Rocks", self.col("Scenery"))
        self.wat = CL.ClassicMesh("Water", self.col("Water"))
        self.foam = CL.ClassicMesh("Foam_Mist", self.col("Water"))
        self.veg = CL.ClassicMesh("Vegetation", self.C["Vegetation"])
        return self.sc, self.wat, self.foam, self.veg

    def column(self, m, x, y, z0, h, w, d, yaw, rocks, cap=None, cap_top=None, drip=None, top_fn=None):
        """A stack of big blocky stone (the benchmark's cliffs), recoloured per island: 1-5 chunky blocks, each offset +
        smaller, a cap (cap / cap_top) with drips, then top_fn(z) for plants / props on top. Returns the top z."""
        rng = self.rng
        n = max(1, round(h / 7.5))
        z = z0
        ww, dd = w, d
        for k in range(n):
            hk = h / n * rng.uniform(0.9, 1.1)
            m.rock(x + rng.uniform(-0.6, 0.6), y + rng.uniform(-0.6, 0.6), z, ww, dd, hk + 0.3, rng.choice(rocks), rot=yaw + rng.uniform(-6, 6), jitter=0.07, taper=0.05)
            if rng.random() < 0.45 and ww > 6:
                a = rng.choice((0, 90, 180, 270)) + yaw
                m.rock(x + math.cos(math.radians(a)) * ww * 0.45, y + math.sin(math.radians(a)) * dd * 0.45, z, ww * 0.42, dd * 0.42,
                       hk * rng.uniform(0.5, 0.85), rng.choice(rocks), top=cap_top if cap_top and rng.random() < 0.5 else None,
                       rot=yaw + rng.uniform(-15, 15), jitter=0.1)
            z += hk
            ww *= rng.uniform(0.84, 0.95)
            dd *= rng.uniform(0.84, 0.95)
        if cap:
            m.rock(x, y, z - 0.4, ww + 0.9, dd + 0.9, 1.3, cap, top=cap_top or cap, rot=yaw, jitter=0.04, taper=0.02)
            for k in range(rng.randint(2, 5) if drip else 0):
                a = math.radians(rng.uniform(0, 360))
                m.brick(x + math.cos(a) * (ww / 2 + 0.3), y + math.sin(a) * (dd / 2 + 0.3), z - rng.uniform(1.4, 2.4), rng.uniform(1.0, 2.2), 0.5,
                        rng.uniform(1.2, 2.2), drip, rot=math.degrees(a) + 90, bevel=0.15)
            z += 0.9
        if top_fn:
            top_fn(x, y, z, ww, dd)
        return z

    def massifs(self, anchors, colfn, step=3.4, terraces=True, boulders=70):
        """One continuous wall of stacked stone round the outer ring (heights interpolated round the compass from anchors
        [(deg, h)]; 0 = open), columns joined by lower connectors, a front row of terraces, boulders at their feet.
        colfn(x, y, h, w, d, yaw, kind) draws one column (kind = 'back' / 'link' / 'terrace' / 'boulder')."""
        rng = self.rng

        def H(deg):
            d = deg % 360
            for (a0, h0), (a1, h1) in zip(anchors, anchors[1:]):
                if a0 <= d <= a1:
                    t = (d - a0) / max(1e-6, a1 - a0)
                    t = t * t * (3 - 2 * t)
                    h = h0 + (h1 - h0) * t
                    return max(0.0, h + 2.4 * math.sin(math.radians(7 * d)) + 1.6 * math.sin(math.radians(13 * d) + 1)) if h > 0.5 else 0.0
            return 0.0
        self.massif_h = H
        back = []
        deg = 0.0
        while deg < 360:
            h0 = H(deg)
            if h0 > 0.5:
                x, y = self.ring_pt(deg, 0.76 + 0.07 * math.sin(math.radians(5 * deg)))
                w = rng.uniform(15, 20)
                if self.clear_of_reach(x, y, w / 2 + 2) and self.free(x, y, 0):
                    h = h0 * rng.uniform(0.92, 1.08)
                    colfn(x, y, h, w, w * rng.uniform(0.75, 0.9), deg + 90 + rng.uniform(-6, 6), "back")
                    if back and math.hypot(x - back[-1][0], y - back[-1][1]) < 26:
                        bx, by, bh = back[-1]
                        colfn((x + bx) / 2, (y + by) / 2, min(h, bh) * rng.uniform(0.55, 0.72), math.hypot(x - bx, y - by) + 5, w * 0.7,
                              math.degrees(math.atan2(y - by, x - bx)), "link")
                    back.append((x, y, h))
            deg += step
        if terraces:
            for k in range(0, 360, 7):
                deg = k + rng.uniform(-2, 2)
                h0 = H(deg)
                if h0 <= 0.5:
                    continue
                x, y = self.ring_pt(deg, rng.uniform(0.38, 0.5))
                w = rng.uniform(10, 15)
                if not self.clear_of_reach(x, y, w / 2 + 2) or not self.free(x, y, 0):
                    continue
                colfn(x, y, h0 * rng.uniform(0.38, 0.55), w, w * rng.uniform(0.75, 0.95), deg + 90 + rng.uniform(-10, 10), "terrace")
                self.used.append((x, y, w * 0.5))
        for k in range(boulders):
            deg = rng.uniform(0, 360)
            if H(deg) <= 0.5:
                continue
            x, y = self.ring_pt(deg, rng.uniform(0.02, 0.2))
            if self.clear_of_reach(x, y, 3) and self.free(x, y, 0):
                colfn(x, y, rng.uniform(2, 4.5), rng.uniform(3, 5.5), rng.uniform(2.5, 4.5), rng.uniform(0, 90), "boulder")

    def ring_plants(self, fn, n=150):
        """Plants / props on the ring's grass: fn(m, x, y, z, roll, lean_in) draws one; returns its footprint radius."""
        rng = self.rng
        placed = tries = 0
        while placed < n and tries < 6000:
            tries += 1
            deg = rng.uniform(0, 360)
            x, y = self.ring_pt(deg, rng.uniform(-0.04, 0.95))
            if abs((deg - self.SW + 180) % 360 - 180) < 9 or not self.clear_of_reach(x, y, 9) or not self.free(x, y, -1):
                continue
            r = fn(self.veg, x, y, 0.6, rng.random(), self.ang(x, y) + 180 + rng.uniform(-50, 50))
            if r:
                self.used.append((x, y, r))
            placed += 1

    def pool(self, deg, R, f, water, deep, bank, bank_top, rim_fn=None, garden_fn=None, fall=None, fall_look=None):
        """A pool in a pocket of the ring (bank, water, foam edge), rim_fn(x, y, a) for its rim, garden_fn(x, y) inside,
        and optionally a stream + a fall off the island edge (fall = its width)."""
        rng = self.rng
        px, py, f = self.push_out(deg, f, R + 4)
        pts = [(px + R * (1 + 0.18 * math.sin(3 * a + deg)) * math.cos(a), py + R * 0.8 * (1 + 0.15 * math.cos(2 * a + deg)) * math.sin(a))
               for a in [2 * math.pi * i / 22 for i in range(22)]]
        self.sc.slab([(px + (x - px) * 1.18, py + (y - py) * 1.18) for x, y in pts], 0.3, 0.68, bank, chamfer=0.1, top=bank_top)
        self.wat.slab(pts, 0.0, 0.8, deep, chamfer=0.08, top=water)
        D.foam_outline(self.foam, pts, 0.8)
        self.used.append((px, py, R + 4))
        self.LAYOUT["fx"]["pools"].append([round(px, 1), round(py, 1), R])
        if rim_fn:
            for k in range(12):
                a = math.radians(k * 30 + rng.uniform(-8, 8))
                rx_, ry_ = px + math.cos(a) * (R + 3.5), py + math.sin(a) * (R * 0.8 + 3.5)
                if self.clear_of_reach(rx_, ry_, 4) and math.hypot(rx_ - self.center[0], ry_ - self.center[1]) > math.hypot(px - self.center[0], py - self.center[1]) - R * 0.3:
                    rim_fn(rx_, ry_, math.degrees(a))
        if garden_fn:
            for k in range(rng.randint(5, 8)):
                a, rr = math.radians(rng.uniform(0, 360)), rng.uniform(0.15, 0.6) * R
                garden_fn(px + math.cos(a) * rr, py + math.sin(a) * rr * 0.8)
        if fall:
            ex, ey = self.polar(self.r_isl(deg) - 0.5, deg)
            self.wat.beam((px, py, 0.75), (ex, ey, 0.7), fall * 0.85, 0.3, water)
            self.edge_fall(ex, ey, deg, fall, fall_look or water)
            self.note(f"Fall off the edge ({deg} deg)", ex, ey, "a pool spilling over the island edge")
        return px, py

    def edge_fall(self, x, y, deg, width, look):
        """A fall over the island edge: a lip, a curtain of stepped slabs dropping clear of the cliff, mist below."""
        rng = self.rng
        c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
        self.wat.brick(x + c * 0.6, y + s * 0.6, 0.0, 1.6, width, 0.8, look, rot=deg, bevel=0.2)
        z, k = -0.2, 0
        while z > -84:
            h = rng.uniform(7, 12)
            out = 2.2 + k * 0.5
            self.wat.brick(x + c * out, y + s * out, z - h, 1.6, width + min(5, k * 0.5), h, look, rot=deg, bevel=0.3)
            z -= h * 0.92
            k += 1
        for j in range(6):
            mx, my = x + c * rng.uniform(6, 14) + rng.uniform(-4, 4), y + s * rng.uniform(6, 14) + rng.uniform(-4, 4)
            r = rng.uniform(6, 11)
            self.foam.sphere(mx, my, -86 + rng.uniform(-4, 4), r, r * 0.8, r * 0.55, "mist", seg=12, rings=8)
        self.LAYOUT["fx"]["edge_lips"].append([round(x, 1), round(y, 1), 0.6, deg])

    def done_scenery(self):
        for m in (self.sc, self.wat, self.foam, self.veg):
            m.done()

    # ---------------------------------------------------------------- the sky
    def sky(self, kind="day", sea="sea", cloud="white", islet=None, islet_top=("dirt_rim", "moss"), islet_rock=("rock_grey", "rock_grey_dark")):
        rng = self.rng
        if kind == "space":
            st = K.Mesh("Sky_Backdrop", self.col("Sky"))
            for k in range(900):
                az, el = rng.uniform(0, 360), rng.uniform(-70, 80)
                dd = rng.uniform(1700, 2100)
                x, y = self.polar(dd * math.cos(math.radians(el)), az, (0, 0))
                st.brick(x, y, dd * math.sin(math.radians(el)), *([rng.uniform(1.4, 3.6)] * 3), "glow_white" if k % 5 else rng.choice(("glow_cyan", "glow_pink", "glow_gold")),
                         rot=rng.uniform(0, 90), studs=False, bevel=0.0)
            st.done()
        else:
            sea_m = CL.ClassicMesh("Sky_Sea", self.col("Sky"))
            sea_m.cyl(0, 0, 4000, -330, -320, sea, segs=64)
            sea_m.done()
            cl = CL.ClassicMesh("Sky_Clouds", self.col("Sky"))
            for k in range(18):
                x, y = self.polar(rng.uniform(330, 720), rng.uniform(0, 360), (0, 0))
                z = rng.uniform(-140, 70)
                for j in range(rng.randint(6, 10)):
                    r = rng.uniform(9, 22)
                    cl.sphere(x + rng.uniform(-28, 28), y + rng.uniform(-16, 16), z + rng.uniform(-3, 9), r, r * 0.8, r * 0.55, cloud, seg=14, rings=8)
            cl.done()
        isl = CL.ClassicMesh("Sky_Islets", self.col("Sky"))
        for k in range(8):
            d = rng.uniform(0, 360)
            x, y = self.polar(rng.uniform(390, 620), d, (0, 0))
            z = rng.uniform(-60, 40)
            s_ = rng.uniform(12, 24)
            isl.slab(self.blob(x, y, s_, 12), z - 3, z, islet_top[0], chamfer=0.4, top=islet_top[1])
            for j in range(3):
                isl.rock(x, y, z - 3 - (j + 1) * s_ * 0.4, s_ * (1.2 - j * 0.3), s_ * (1.0 - j * 0.25), s_ * 0.42, rng.choice(islet_rock), rot=d + j * 20, taper=-0.3)
            if islet:
                islet(isl, x, y, z)
        isl.done()

    def studs(self, looks):
        K.studs_done(self.C[self.title], only=lambda o, look: look in looks and not o.name.startswith(("Sky_", "Preview", "Egg_Spot", "Label", "Diagram")))

    # ---------------------------------------------------------------- gameplay checks (measured on the built geometry)
    def checks(self):
        L = self.LAYOUT["checks"]
        b, Z, boss = self.box, self.Z, self.boss
        objs = [o for o in self.scene.objects if o.type == "MESH" and not o.name.startswith(("Studs_", "StudSource_", "Sky_", "Preview", "Egg_Spot", "Boss_", "Floor_Decor", "Label", "Diagram"))]
        dec = bpy.data.objects.get("Floor_Decor")
        if dec and len(dec.data.vertices):
            L["floor_decor"] = f"small walk-through decor on the floor: at most {max(v.co.z for v in dec.data.vertices) - Z:.1f} studs tall, collision off in Roblox"
        verts, polys, owner = [], [], []
        for o in objs:
            mw = o.matrix_world
            base = len(verts)
            verts.extend(mw @ v.co for v in o.data.vertices)
            polys.extend([[base + i for i in p.vertices] for p in o.data.polygons])
            owner.extend([o.name] * len(o.data.polygons))
        bvh = BVHTree.FromPolygons(verts, polys)
        down = Vector((0, 0, -1))
        why = {}

        def ground(x, y):
            hit = bvh.ray_cast(Vector((x, y, 300)), down, 600)
            return hit[0].z if hit[0] is not None else None

        def blocked(x, y):
            hit = bvh.ray_cast(Vector((x, y, 300)), down, 600)
            z = hit[0].z if hit[0] is not None else None
            bad = z is None or z > Z + OBST or z < Z - 0.6
            if bad:
                k = "off the island" if z is None else owner[hit[2]]
                why[k] = why.get(k, 0) + 1
            return bad
        cells = bad = 0
        y = b[1]
        while y <= b[3]:
            x = b[0]
            while x <= b[2]:
                cells += 1
                bad += blocked(x, y) or not self.in_sand(x, y)
                x += 4
            y += 4
        L["box_open_floor"] = f"{cells - bad}/{cells} sample points (4-stud grid) in the boss's box are open floor"
        if self.kind == "Line":
            lanes = clear = full = 0
            Lw = boss["Length"]
            for sx in range(int(b[0]) + 10, int(b[2]), 30):
                for sy in range(int(b[1]) + 10, int(b[3]), 30):
                    for k in range(16):
                        a = math.radians(k * 22.5)
                        ex, ey = min(max(sx + math.cos(a) * Lw, b[0]), b[2]), min(max(sy + math.sin(a) * Lw, b[1]), b[3])
                        L2 = math.hypot(ex - sx, ey - sy)
                        lanes += 1
                        full += L2 >= Lw - 0.5
                        dx, dy = ((ex - sx) / L2, (ey - sy) / L2) if L2 > 0.1 else (1, 0)
                        ok, t = True, 0.0
                        while t <= L2 and ok:
                            for off in (-boss["Width"] / 2, -boss["Width"] / 4, 0, boss["Width"] / 4, boss["Width"] / 2):
                                if blocked(sx + dx * t - dy * off, sy + dy * t + dx * off):
                                    ok = False
                                    break
                            t += 4
                        clear += ok
            L["attack_lanes"] = f"{clear}/{lanes} sampled {boss['Attack']} lanes ({boss['Width']} wide) run clear; {full} reach the full {Lw} studs (the rest stop at the box edge)"
        else:
            R = boss.get("Radius", 30)
            pts = ok = 0
            for sx in range(int(b[0]), int(b[2]) + 1, 20):
                for sy in range(int(b[1]), int(b[3]) + 1, 20):
                    for rr in (R * 0.5, R):
                        for k in range(16):
                            a = math.radians(k * 22.5)
                            pts += 1
                            ok += not blocked(sx + rr * math.cos(a), sy + rr * math.sin(a))
            L["attack_area"] = (f"{ok}/{pts} points of his {self.kind} (r {R}) cast from a 20-stud grid over the box are clear "
                                f"(nothing tall in his reach; points off the floor still count as open air / grass)")
        print(f"[{self.pfx}] blockers:", sorted(((k, v) for k, v in why.items()), key=lambda kv: -kv[1])[:6])
        mins = {}
        for x, y, name in self.spots:
            edge = self.r_sand(self.ang(x, y)) - math.hypot(x - self.center[0], y - self.center[1])
            mins[name] = round(min(mins.get(name, 1e9), edge), 1)
        L["egg_edge_clearance"] = {k: f"{v} studs to the floor edge (drops scatter at most {DROP_MAX:.1f})" for k, v in mins.items()}
        L["spawn_safe"] = f"spawn pad {self.box_dist(*self.SPAWN):.0f} studs outside the box (his reach past it: {self.reach:.1f})"
        L["portal_threat"] = (f"portal {self.box_dist(*self.PORTAL):.0f} studs outside the box: the last ~{max(0.0, 60 - self.box_dist(*self.PORTAL)):.0f} "
                              f"studs of the approach are inside his 60-stud trigger")

        def walk_ok(x, y, avoid):
            on = (self.in_sand(x, y, 1) or math.hypot(x - self.SPAWN[0], y - self.SPAWN[1]) < 10 or
                  (abs((self.ang(x, y) - self.SW + 180) % 360 - 180) < 3 and math.hypot(x - self.center[0], y - self.center[1]) < self.r_isl(self.SW) + 40) or
                  math.hypot(x - self.PORTAL[0], y - self.PORTAL[1]) < 12)
            if not on or (avoid and self.in_box(x, y, self.reach)):
                return False
            z = ground(x, y)
            return z is not None and z < Z + OBST

        def bfs(avoid):
            step = 3.0
            start = (round(self.SPAWN[0] / step), round(self.SPAWN[1] / step))
            goal = (round(self.PORTAL[0] / step), round(self.PORTAL[1] / step))
            seen, todo = {start}, [start]
            while todo:
                cx, cy = todo.pop()
                if abs(cx - goal[0]) <= 3 and abs(cy - goal[1]) <= 3:
                    return True
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if (nx, ny) not in seen and walk_ok(nx * step, ny * step, avoid):
                        seen.add((nx, ny))
                        todo.append((nx, ny))
            return False
        L["spawn_to_portal"] = "reachable on level ground" if bfs(False) else "NOT reachable - fix"
        L["no_safe_bypass"] = "no walkable route avoids his reach (every route crosses his box)" if not bfs(True) else "a route AVOIDS him - fix"
        corners = all(self.in_sand(x, y, 2) for x in (b[0], b[2]) for y in (b[1], b[3]))
        L["box_on_floor"] = "all four box corners are on the floor" if corners else "a box corner is off the floor - fix"
        L["egg_spots"] = f"{len(self.spots)} candidate spots in {len(self.regions)} regions (the zone shows at most 14 eggs at once)"
        print(f"[{self.pfx}] checks:", json.dumps(L, indent=1))

    # ---------------------------------------------------------------- the gameplay diagram overlays (diagram render only)
    def diagram(self, labels):
        dg = CL.ClassicMesh("Diagram_Overlays", self.col("Diagram"))
        ZD = 80.0
        b = self.box

        def dash(x0, y0, x1, y1, look, w=1.4, d=6.0, g=3.0):
            L = math.hypot(x1 - x0, y1 - y0)
            a = math.degrees(math.atan2(y1 - y0, x1 - x0))
            t = 0.0
            while t < L:
                t1 = min(L, t + d)
                m = (t + t1) / 2 / L
                dg.brick(x0 + (x1 - x0) * m, y0 + (y1 - y0) * m, ZD, t1 - t, w, 0.3, look, rot=a, bevel=0.0)
                t += d + g
        for (x0, y0, x1, y1) in ((b[0], b[1], b[2], b[1]), (b[2], b[1], b[2], b[3]), (b[2], b[3], b[0], b[3]), (b[0], b[3], b[0], b[1])):
            dash(x0, y0, x1, y1, "diag_red", w=2.0)
        for name, ((cx, cy), R, why) in self.regions.items():
            dg.ring(R - 1.0, R + 0.6, ZD, ZD + 0.3, "diag_yellow", cx=cx, cy=cy, segs=48)
        dg.ring(14, 16, ZD, ZD + 0.3, "diag_blue", cx=self.SPAWN[0], cy=self.SPAWN[1], segs=40)
        dg.ring(14, 16, ZD, ZD + 0.3, "diag_purple", cx=self.PORTAL[0], cy=self.PORTAL[1], segs=40)
        if self.kind == "Line":
            Lw = self.boss["Length"]
            for (sx, sy), (tx, ty) in ((self.pad, self.spots[0][:2]), ((b[0] * 0.5, b[3] * 0.5), self.PORTAL), ((b[2] * 0.5, b[1] * 0.5), self.SPAWN)):
                a = math.atan2(ty - sy, tx - sx)
                ex, ey = min(max(sx + math.cos(a) * Lw, b[0]), b[2]), min(max(sy + math.sin(a) * Lw, b[1]), b[3])
                L = math.hypot(ex - sx, ey - sy)
                for off in (-self.boss["Width"] / 2, self.boss["Width"] / 2):
                    dg.brick((sx + ex) / 2 - math.sin(a) * off, (sy + ey) / 2 + math.cos(a) * off, ZD + 0.5, L, 1.0, 0.3, "diag_charge", rot=math.degrees(a), bevel=0.0)
                dg.brick((sx + ex) / 2, (sy + ey) / 2, ZD + 0.5, L, 2.0, 0.3, "diag_red", rot=math.degrees(a), bevel=0.0)
                dg.cyl(sx, sy, 3.2, ZD + 0.5, ZD + 0.8, "diag_red", segs=16)
        else:
            R = self.boss.get("Radius", 30)
            for (sx, sy) in (self.pad, (b[0] + R * 0.4, b[3] - R * 0.4), (b[2] - R * 0.4, b[1] + R * 0.4)):
                dg.ring(R - 1.0, R + 1.0, ZD + 0.5, ZD + 0.8, "diag_charge", cx=sx, cy=sy, segs=56)
                dg.cyl(sx, sy, 3.2, ZD + 0.5, ZD + 0.8, "diag_red", segs=16)
        dg.done()
        lab = K.Mesh("Label_Plates", self.col("Labels"))
        for text, x, y in labels:
            HI.label(self.col("Labels"), lab, text, x, y, 6.5, z=ZD + 30)
        lab.done()

    # ---------------------------------------------------------------- light, save, renders
    def finish(self, file, sun=(4.0, (48, 8, -28)), sky=(0.2, 0.5, 0.98), horizon=(0.66, 0.85, 1.0), space=False, argv=(), eggs_cam=None, boss_cam=None):
        scene = self.scene
        world, sunob = K.sky_and_sun(scene, sun_energy=sun[0], sun_rot=sun[1], sky=sky, horizon=horizon)
        if space:  # the camera sees deep space; the scene stays lit by the lifted sky (Light Path: Is Camera Ray)
            nt = world.node_tree
            bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
            bg.inputs["Strength"].default_value = 1.6
            out = next(n for n in nt.nodes if n.type == "OUTPUT_WORLD")
            dark = nt.nodes.new("ShaderNodeBackground")
            dark.inputs["Color"].default_value = (0.008, 0.005, 0.03, 1)
            lp = nt.nodes.new("ShaderNodeLightPath")
            mix = nt.nodes.new("ShaderNodeMixShader")
            nt.links.new(lp.outputs["Is Camera Ray"], mix.inputs["Fac"])
            nt.links.new(bg.outputs["Background"], mix.inputs[1])
            nt.links.new(dark.outputs["Background"], mix.inputs[2])
            nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
        self.C["Lighting"].objects.link(sunob)
        K.setup_eevee(scene, samples=24)
        for n in ("Diagram", "Labels", "Gameplay_Markers"):
            self.col(n).hide_render = True
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(self.here, file + ".blend"), compress=True)
        with open(os.path.join(self.here, self.pfx.lower() + "_layout.json"), "w") as fh:
            json.dump(self.LAYOUT, fh, indent=1)
        print(f"[{self.pfx}] saved; {len(self.spots)} egg spots")
        sp, po = self.SPAWN, self.PORTAL
        reg = list(self.regions.values())[0][0]
        cams = {
            "aerial": (("Cam_Aerial", (70, -505, 365), (0, 18, -18), 34), 2400, 1350),
            "ground_spawn": (("Cam_Ground_Spawn", (sp[0] - 9, sp[1] - 9, self.Z + 9), (self.center[0], self.center[1] + 25, self.Z + 6), 24), 1920, 1080),
            "ground_eggs": (eggs_cam or ("Cam_Ground_Eggs", (reg[0] - 40, reg[1] - 26, self.Z + 8), (reg[0] + 40, reg[1] + 20, self.Z + 3), 24), 1920, 1080),
            "boss_view": (boss_cam or ("Cam_Boss_View", (self.pad[0] - 34, self.pad[1] - 40, self.Z + 30), (self.pad[0] + 70, self.pad[1] + 75, self.Z), 22), 1920, 1080),
            "ground_portal": (("Cam_Ground_Portal", (po[0] - 52, po[1] - 46, self.Z + 9), (po[0], po[1], self.Z + 12), 26), 1920, 1080),
        }
        only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("only=")), None)
        tag = self.pfx.lower()
        if "norender" in argv:
            return
        for key, ((name, loc, look, lens), w, h) in cams.items():
            if only and key not in only:
                continue
            cam = K.camera(name, loc, look, lens=lens, collection=self.C["Presentation"])
            scene.eevee.taa_render_samples = 32 if key == "aerial" else 24
            K.render(scene, cam, os.path.join(self.renders, f"{tag}_{key}.jpg"), w, h)
        if not only or "topdown" in only:
            cam = K.camera("Cam_TopDown", (0, 20, 1500), (0, 20, 0), ortho=560, collection=self.C["Presentation"])
            cam.rotation_euler = (0, 0, 0)
            scene.eevee.taa_render_samples = 16
            K.render(scene, cam, os.path.join(self.renders, f"{tag}_topdown.jpg"), 2000, 2000)
        if not only or "diagram" in only:
            cam = bpy.data.objects.get("Cam_TopDown") or K.camera("Cam_TopDown", (0, 20, 1500), (0, 20, 0), ortho=560, collection=self.C["Presentation"])
            cam.rotation_euler = (0, 0, 0)
            for n in ("Diagram", "Labels", "Gameplay_Markers"):
                self.col(n).hide_render = False
            self.col("Preview_Eggs").hide_render = True
            self.col("Sky").hide_render = True
            scene.render.engine = "BLENDER_WORKBENCH"
            sh = scene.display.shading
            sh.light, sh.color_type, sh.show_cavity, sh.show_shadows = "STUDIO", "MATERIAL", True, False
            world.color = (0.62, 0.78, 0.95)
            K.render(scene, cam, os.path.join(self.renders, f"{tag}_gameplay_diagram.jpg"), 2000, 2000)
