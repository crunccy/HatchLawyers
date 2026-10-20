# Space Base v2 — DETAILED (2026-10-20, mr.robe's session) · waiting for crnuch's approval

Redone to crnuch's **Ocean Shore v2 benchmark** (approved 2026-10-19), user's call on mr.robe's PC ("do the same for
the rest of the islands"). Built on `../kit/hl_v2.py` (the benchmark turned into a shared frame: island body, spawn dock
+ pad, the purple escape portal, egg regions, the scenery-ring helpers, the checks, the diagram, the renders) plus this
island's theme in `sbv2_build.py`. v1 (`../Crater Rim (W, mid) · Landing Lawn (S, nearest the spawn: safer) · Crystal Flats (E, mid) · Orbit Walk (N, inside his pull: high risk) · Nebula Patch (NE, by the portal: high risk)/`) is untouched as the backup.
- classic Roblox studs, not LEGO; studs only on broad floor / terrain / structural tops;
- one continuous flat floor the boss roams, egg regions across it;
- spawn dock SW, the escape portal (RETURN HOME, a level walk-in) NE;
- all scenery outside the boss's reach; every gameplay number from `Config.Bosses` / `Config.Zones`.
```bash
Blender -b --python environment-redesign/space_base_v2/sbv2_build.py      # .blend + layout JSON + checks + 7 renders
```

| Deliverable | File |
| --- | --- |
| Editable .blend | `space_base_v2.blend` |
| Aerial, top-down, gameplay diagram | `renders/sbv2_aerial.jpg`, `sbv2_topdown.jpg`, `sbv2_gameplay_diagram.jpg` |
| Player-level views: spawn, egg field, boss, escape portal | `renders/sbv2_ground_spawn.jpg`, `sbv2_ground_eggs.jpg`, `sbv2_boss_view.jpg`, `sbv2_ground_portal.jpg` |
| Positions (Blender + Roblox x/z), the boss box, egg regions + spots, the checks | `sbv2_layout.json` |

## The floor + the boss
**Chief Justice Eclipse** (Config.Bosses: Pull radius 44 (inner 12, 2 s at 16) and Ring 38, Windup 1.4 s, every 2.5 s, WalkSpeed 44, Scale 3.2, Hitbox 15 wide, 33 tall). **Floor:** -. His box: **184 x 170** (Blender x0, y0, x1, y1 in the layout JSON); his reach past it: **47.8 studs** (all
scenery stays outside box + reach + 1).

## Egg regions (25 candidate spots; the zone shows at most 14 eggs at once)
-

## Scenery (outside his reach)
one moon plate with flush craters, a gold constellation inlay with glowing stars, walk-through pebbles, tiny crystals, floor lights, alien sprouts (at most 2.1 studs tall, collision off)

## Gameplay checks (measured on the built geometry, `sbv2_layout.json` → checks)
violet moon-rock cliffs with crystal clusters, alien mushrooms and bulb plants on top; four plasma pools (one spilling a plasma fall); the rocket + gantry, the observatory, the habitat domes, the robot factory, the solar farm, the fuel depot, the satellite dish, a parked UFO (fictional); beacon lamps on the dock; stars all round, a ringed planet + a moon (Blender only), the camera sees deep space

## Known weaknesses (honest)
- **No ambience pass yet** (no wind / water animation / particles in the .blend) — the benchmark islands have one.
- **Shared pieces:** the spawn dock + pad and the escape portal come from Ocean Shore v2's parts (one look on every
  island, on purpose), and some themed props reuse v1's piece modules drawn with smooth classic primitives.
- **Not reviewed by crnuch** — built to the benchmark's rules and checks, but without his approval passes.
- **In the place as Parts** (`Workspace.WorldRedesign`): organic slabs / rocks / fronds are approximated as boxes
  (`../kit/hl_export.py`, classic section); exact shapes would need MeshParts uploaded by crnuch.
