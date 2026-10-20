# Food Court v2 — DETAILED (2026-10-20, mr.robe's session) · waiting for crnuch's approval

Redone to crnuch's **Ocean Shore v2 benchmark** (approved 2026-10-19), user's call on mr.robe's PC ("do the same for
the rest of the islands"). Built on `../kit/hl_v2.py` (the benchmark turned into a shared frame: island body, spawn dock
+ pad, the purple escape portal, egg regions, the scenery-ring helpers, the checks, the diagram, the renders) plus this
island's theme in `fcv2_build.py`. v1 (`../Picnic Corner (W, mid) · Dessert Spot (S, nearest the spawn: safer) · Salad Bowl (E, mid) · Snack Trail (N, on his roll line: high risk) · Sundae Row (NE, by the portal: high risk)/`) is untouched as the backup.
- classic Roblox studs, not LEGO; studs only on broad floor / terrain / structural tops;
- one continuous flat floor the boss roams, egg regions across it;
- spawn dock SW, the escape portal (RETURN HOME, a level walk-in) NE;
- all scenery outside the boss's reach; every gameplay number from `Config.Bosses` / `Config.Zones`.
```bash
Blender -b --python environment-redesign/food_court_v2/fcv2_build.py      # .blend + layout JSON + checks + 7 renders
```

| Deliverable | File |
| --- | --- |
| Editable .blend | `food_court_v2.blend` |
| Aerial, top-down, gameplay diagram | `renders/fcv2_aerial.jpg`, `fcv2_topdown.jpg`, `fcv2_gameplay_diagram.jpg` |
| Player-level views: spawn, egg field, boss, escape portal | `renders/fcv2_ground_spawn.jpg`, `fcv2_ground_eggs.jpg`, `fcv2_boss_view.jpg`, `fcv2_ground_portal.jpg` |
| Positions (Blender + Roblox x/z), the boss box, egg regions + spots, the checks | `fcv2_layout.json` |

## The floor + the boss
**Prosecutor Big Cheese** (Config.Bosses: Line 110 x 22 at 120 studs/s, Windup 1.2 s, every 3.5 s, WalkSpeed 40, Scale 3.2, Hitbox 21 wide, 20.5 tall; Wheel Split lanes for 2+ players). **Floor:** -. His box: **230 x 200** (Blender x0, y0, x1, y1 in the layout JSON); his reach past it: **21.6 studs** (all
scenery stays outside box + reach + 1).

## Egg regions (28 candidate spots; the zone shows at most 14 eggs at once)
-

## Scenery (outside his reach)
one giant picnic tablecloth (cream with big red checks), walk-through crumbs, sprinkles, napkins, grapes, crackers (at most 1 stud tall, collision off)

## Gameplay checks (measured on the built geometry, `fcv2_layout.json` → checks)
layered cake cliffs with pink / cream frosting caps and chocolate drips, fruit trees, cupcakes, lollipops and candy canes on top; chocolate + soda pools with ice cubes and lemon slices (one spilling a soda fall); BURGER BARN, PIZZA PALACE, DONUT DINER, TACO TOWER, a giant burger, giant fries, the soda-cup fountain, a giant ice cream; condiment-bottle lamps on the dock

## Known weaknesses (honest)
- **No ambience pass yet** (no wind / water animation / particles in the .blend) — the benchmark islands have one.
- **Shared pieces:** the spawn dock + pad and the escape portal come from Ocean Shore v2's parts (one look on every
  island, on purpose), and some themed props reuse v1's piece modules drawn with smooth classic primitives.
- **Not reviewed by crnuch** — built to the benchmark's rules and checks, but without his approval passes.
- **In the place as Parts** (`Workspace.WorldRedesign`): organic slabs / rocks / fronds are approximated as boxes
  (`../kit/hl_export.py`, classic section); exact shapes would need MeshParts uploaded by crnuch.
