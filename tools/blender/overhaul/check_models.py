# tools/blender/overhaul/check_models.py - builds every MAP MODEL OVERHAUL model on its own and runs ohkit.check_attached
# on it (crnuch 2026-10-25: "detached or overlapping" parts look wrong): every separate piece of a model must touch the
# rest of it (or the ground); a floating piece is listed with its mesh name, centre and size.
#   Blender -b --factory-startup --python tools/blender/overhaul/check_models.py -- [<group> ...] [zfight]
# zfight: report coplanar faces of two colours (they flicker in Roblox) instead of floating pieces.
# clip: report thin decorative pieces (awnings, signs, banners, flags, sails, windows, doors ...) buried 0.3+ inside another
#   solid part of the same model (crnuch 2026-10-25: the Pizza Palace's awning ran into its towers and out of their fronts).
# groups: props hub gameplay minigames firms hall bay pet rot food ocean space kit (default: all)
import bpy, os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ZF = "zfight" in argv  # (check z-fighting instead of floating pieces)
CLIP = "clip" in argv  # (check decorative sheets buried in solids instead)
WANT = set(a for a in argv if not a.startswith("-") and a not in ("zfight", "clip")) or None
SHEETS = ("Awning", "Valance", "Sign", "Banner", "Flag", "Sail", "Cloth", "Shine", "Ribbon", "Bunting", "Poster", "Menu", "Pennant",
          "Win_", "Door_", "DoorFrame")  # (windows / doors are set 0.05 into their wall: deeper means into something else)
CLIP_OK = (("CounterLicense_IconRibbon", "CounterLicense_Icon"),  # (the ribbon wraps the rolled diploma)
           ("Storefront_DoorFrame", "Storefront_Trim"),           # (the frame's foot meets the base course at the threshold)
           ("MainStreetShow_Shine", "MainStreet_Pediment"))       # (the glass shine runs on behind the porch pediment: hidden)
sys.argv = [sys.argv[0], "--", os.path.join(HERE, "renders")]  # (the imported scripts read an out dir from argv)
import ohkit as O
import island_kit as IK
N = IK.O_NONE


class _Beam:
    def beam(self, *a, **k):
        pass


def _space_portal(SB):  # (the Return Home portal in Space Base's dressing)
    saved = dict(IK.PORTAL)
    SB.patch()
    try:
        IK.rock_portal(N, 0, 0, 0.0, 0)
    finally:
        IK.PORTAL.update(saved)


def _island_portal(mod):  # (the Return Home portal in an island's own dressing: its portal_preset)
    saved = dict(IK.PORTAL)
    mod.portal_preset()
    try:
        IK.rock_portal(N, 0, 0, 0.0, 0)
    finally:
        IK.PORTAL.clear()
        IK.PORTAL.update(saved)


def models():
    import props as PR, hub_license as HL, hub_services as HS, hub_gameplay as HG, hub_minigames as HM, firm_stages as FS, firm_hall as FH
    import island_hub as IH, island_briefcase_bay as BB, island_pet_park as PP, island_brainrot as BR
    out = []
    for nm in ("lamp", "lamp_double", "bench", "bin_", "bollard", "hydrant", "cafe_table", "railing", "fence", "planter_square", "planter_round",
               "flower_bed", "hedge", "rocks", "sign_post", "notice_board", "attraction_sign", "gavel_statue", "briefcase_stack", "file_boxes", "crate"):
        out.append(("props", nm, getattr(PR, nm), ()))
    out += [("hub", "license", HL.building, ()), ("hub", "upgrades", HS.upgrades, ()), ("hub", "incubator", HS.incubator, ()),
            ("hub", "fountain", IH.fountain, ())]
    out += [("gameplay", "shop_stall", HG.shop_stall, ()), ("gameplay", "leaderboard", HG.leaderboard, ()), ("gameplay", "case_belt", HG.case_belt, ())]
    out += [("gameplay", "counter_" + k, HG.counter, (k,)) for k in ("License", "Carry", "Speed")]
    out += [("minigames", "gavel_bonk", HM.gavel_bonk, ()), ("minigames", "lucky_briefcase", HM.lucky_briefcase, ())]
    out += [("minigames", "booth_" + g, HM.arcade_booth, (g,)) for g in ("FilingFrenzy", "BriefcaseStack", "LieDetector")]
    out += [("firms", "stage%d" % k, FS.STAGES[k], ()) for k in (2, 3, 4, 5, 6)]
    out += [("hall", "segment", FH.office_segment, ()), ("hall", "desk", FH.lawyer_desk, ()), ("hall", "lock", FH.expansion_lock, ()),
            ("hall", "back_wall", FH.back_wall, ())]
    out += [("bay", "briefcase", BB.giant_briefcase, (N, N, 0, 0, 0.0, 0, None)), ("bay", "gavel", BB.giant_gavel, (N, N, 0, 0, 0.0, 0, None)),
            ("bay", "fountain", BB.fountain, (N, N, N, 0, 0, 0.0)), ("bay", "lighthouse", BB.lighthouse, (N, _Beam(), 0, 0, 0.0, 28, 0)),
            ("bay", "ferry", BB.ferry, (N, 0, 0, 1.8, 0, None)), ("bay", "sailboat", BB.sailboat, (N, 0, 0, 0.8, 0)),
            ("bay", "welcome", BB.welcome_sign, (N, 0, 0, 0.0, 0, None)), ("bay", "portal", BB.escape_portal, (N, N, 0, 0, 0.0, 0))]
    out += [("kit", "rock_portal", IK.rock_portal, (N, 0, 0, 0.0, 0)), ("kit", "topiary", IK.topiary, (N, 0, 0, 0.0, 0)),
            ("kit", "lifebuoy_stand", IK.lifebuoy_stand, (N, 0, 0, 0.0, 0)), ("kit", "buoy", IK.buoy, (N, 0, 0, 0.0)),
            ("kit", "bollard", IK.bollard, (N, 0, 0, 0.0)), ("kit", "barrel", IK.barrel, (N, 0, 0, 0.0)), ("kit", "torch", IK.torch, (N, 0, 0, 0.0))]
    out += [("pet", nm, getattr(PP, nm), a) for nm, a in (("giant_corgi", (N, 1.6)), ("giant_cat", (N, 1.4)), ("dog_house", (N,)), ("cat_tower", (N,)),
                                                           ("rabbit_hutch", (N,)), ("bunny_topiary", (N,)), ("wood_bridge", (N,)), ("barkery", (N,)),
                                                           ("paw_clinic", (N,)), ("bird_house", (N, 0, 0)))]
    out.append(("pet", "portal", _island_portal, (PP,)))
    out += [("rot", nm, getattr(BR, nm), a) for nm, a in (("wobble_lamp", (N, 0, 0)), ("pixel_tree", (N, 0, 0)), ("upside_down_tree", (N, 0, 0)),
                                                           ("twisty_tower", (N, 14, 9)), ("big_screen", (N, 24, 12, 24)), ("melty_mall", (N, 26, 16, 10)),
                                                           ("upside_down_house", (N,)), ("leaning_tower", (N, 0, 0)), ("giant_dice", (N, 0, 0, 5.0)),
                                                           ("neon_tower", (N, 12, 12, 32)))]
    out.append(("rot", "portal", _island_portal, (BR,)))
    try:
        import island_food_court as FC
        out += [("food", nm, getattr(FC, nm), a) for nm, a in (("condiment_lamp", (N, 0, 0)), ("fruit_tree", (N, 0, 0)), ("cupcake", (N, 0, 0)),
                                                               ("lollipop", (N, 0, 0)), ("candy_cane", (N, 0, 0)), ("watermelon_slice", (N, 0, 0)),
                                                               ("burger_barn", (N,)), ("pizza_palace", (N,)), ("donut_diner", (N,)), ("taco_tower", (N,)),
                                                               ("giant_burger", (N, 0, 0)), ("giant_fries", (N, 0, 0)), ("ice_cream", (N, 0, 0)),
                                                               ("soda_fountain", (N,)))]
        out.append(("food", "portal", _island_portal, (FC,)))
    except Exception as e:
        print("[check] food court skipped:", e)
    try:
        import island_ocean_shore as OS
        out += [("ocean", nm, getattr(OS, nm), a) for nm, a in (("coral", (N, 0, 0, 0.0, 1.0, "coral_pink")), ("fan_coral", (N, 0, 0, 0.0)),
                                                                ("brain_coral", (N, 0, 0, 0.0)), ("tube_coral", (N, 0, 0, 0.0)), ("seaweed", (N, 0, 0, 0.0)),
                                                                ("shell", (N, 0, 0, 0.0)), ("starfish", (N, 0, 0, 0.0)), ("conch", (N, 0, 0, 0.0)),
                                                                ("sand_dollar", (N, 0, 0, 0.0)), ("driftwood", (N, 0, 0, 0.0)),
                                                                ("shipwreck2", (N, 0, 0, 0.0)))]
    except Exception as e:
        print("[check] ocean shore skipped:", e)
    try:
        import island_space_base as SB
        out += [("space", nm, getattr(SB, nm), a) for nm, a in (("beacon_lamp", (N, 0, 0)), ("alien_mushroom", (N, 0, 0)), ("tentacle_plant", (N, 0, 0)),
                                                                ("bulb_plant", (N, 0, 0)), ("spike_plant", (N, 0, 0)), ("crystal", (N, 0, 0)),
                                                                ("crystal_cluster", (N, 0, 0)), ("moon_rocks", (N, 0, 0)), ("rocket", (N,)),
                                                                ("observatory", (N,)), ("habitat_domes", (N,)), ("robot_factory", (N,)),
                                                                ("solar_farm", (N,)), ("sat_dish", (N,)), ("fuel_depot", (N,)), ("ufo", (N,)))]
        out.append(("space", "portal", _space_portal, (SB,)))
    except Exception as e:
        print("[check] space base skipped:", e)
    return out


def crossings(t, p, v, n=0):
    """How many faces a ray from p along v crosses (odd = p is inside a closed mesh)."""
    o = p.copy()
    for _ in range(64):
        hit = t.ray_cast(o, v, 500.0)
        if hit[0] is None:
            return n
        n, o = n + 1, hit[0] + v * 1e-4
    return n


def clips(objs, depth=0.3):
    """Thin decorative pieces (SHEETS in their name) with points more than `depth` inside another object of the model
    (the nearest face's normal points away from the point): [(sheet, depth, other, (x, y, z))]."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    global DIRS
    DIRS = (Vector((0.0, 0.0, 1.0)), Vector((0.577, -0.577, 0.577)), Vector((-0.6, 0.0, -0.8)))  # (all three must say inside)
    dg = bpy.context.evaluated_depsgraph_get()
    solid = [(ob, BVHTree.FromObject(ob, dg)) for ob in objs if not any(k in ob.name for k in SHEETS)]
    out = []
    for sh in objs:
        if not any(k in sh.name for k in SHEETS):
            continue
        me, mw = sh.data, sh.matrix_world
        pts = [mw @ v.co for v in me.vertices] + [mw @ p.center for p in me.polygons]
        for ob, t in solid:
            worst = (0.0, None)
            for p in pts:
                hit = t.find_nearest(p, 3.0)
                if hit[0] is None:
                    continue
                q, n, d = hit[0], hit[1], hit[3]
                if d > worst[0] and (p - q).dot(n) < 0 and all(crossings(t, p, v) % 2 == 1 for v in DIRS):
                    worst = (d, p)
            if worst[0] > depth and (sh.name, ob.name) not in CLIP_OK:
                c = worst[1]
                out.append((sh.name, worst[0], ob.name, (round(c.x, 1), round(c.y, 1), round(c.z, 1))))
    return out


def main():
    O.reset()
    report = []
    for i, (group, name, fn, args) in enumerate(models()):
        if WANT and group not in WANT:
            continue
        before = set(bpy.data.objects.keys())
        with O.at(i * 400.0, 0, 0):
            try:
                fn(*args)
            except Exception as e:
                print(f"[check] {group}.{name} FAILED to build: {e!r}")
                continue
        O.finish()
        objs = [bpy.data.objects[n] for n in sorted(set(bpy.data.objects.keys()) - before)  # (sorted: the same report every run)
                if bpy.data.objects[n].type == "MESH" and not n.startswith(("Preview", "Studs"))]
        if not objs:
            continue
        if CLIP:  # (decorative sheets buried in another part instead)
            for b in clips(objs):
                report.append(f"{group}.{name}: {b[0]} {b[1]:.2f} deep in {b[2]} at {b[3]}")
            for ob in objs:
                bpy.data.objects.remove(ob)
            continue
        if ZF:  # (z-fighting instead: coplanar faces of two colours)
            for b in O.check_zfight(objs, label=f"{group}.{name}"):
                report.append(f"{group}.{name}: {b[0]} / {b[1]} at {b[2]} overlap {b[3]}")
            for ob in objs:
                bpy.data.objects.remove(ob)
            continue
        floors = (0.0,) if group in ("firms", "hall") else ()  # (a firm stands on FirmBuilder's floor at y 0)
        bad = O.check_attached(objs, ground=0.0, label=f"{group}.{name}", grounds=floors,
                               allow=tuple(a for a in ("Incubator_Halo", "CounterLicense_Icon", "CounterCarry_Icon", "CounterSpeed_Icon",
                                                       "RotEye", "RotCube", "CorporateHQ_HoloRing") if True))
        for b in bad:
            report.append(f"{group}.{name}: {b[0]} at {b[1]} size {b[2]}")
        for ob in objs:  # (keep the scene small)
            bpy.data.objects.remove(ob)
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"), "attach_report.txt")
    with open(path, "w") as fh:
        fh.write("\n".join(report))
    print(f"[check] {len(report)} {'clipping sheets' if CLIP else 'z-fighting pairs' if ZF else 'floating pieces'}; report: {path}")


if __name__ == "__main__":
    main()
