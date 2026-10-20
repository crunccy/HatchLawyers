# Brainrot Zone v2 — DETAILED (2026-10-20, mr.robe's session) · waiting for crnuch's approval

Redone to crnuch's **Ocean Shore v2 benchmark** (approved 2026-10-19), user's call on mr.robe's PC ("do the same for
the rest of the islands"). Built on `../kit/hl_v2.py` (the benchmark turned into a shared frame: island body, spawn dock
+ pad, the purple escape portal, egg regions, the scenery-ring helpers, the checks, the diagram, the renders) plus this
island's theme in `brv2_build.py`. v1 (`../Dice Plaza (W, mid) · Meme Meadow (S, nearest the spawn: safer) · Glitch Garden (E, mid) · Upside Lane (N, high risk) · Neon Nook (NE, by the portal: high risk)/`) is untouched as the backup.
- classic Roblox studs, not LEGO; studs only on broad floor / terrain / structural tops;
- one continuous flat floor the boss roams, egg regions across it;
- spawn dock SW, the escape portal (RETURN HOME, a level walk-in) NE;
- all scenery outside the boss's reach; every gameplay number from `Config.Bosses` / `Config.Zones`.
```bash
Blender -b --python environment-redesign/brainrot_zone_v2/brv2_build.py      # .blend + layout JSON + checks + 7 renders
```

| Deliverable | File |
| --- | --- |
| Editable .blend | `brainrot_zone_v2.blend` |
| Aerial, top-down, gameplay diagram | `renders/brv2_aerial.jpg`, `brv2_topdown.jpg`, `brv2_gameplay_diagram.jpg` |
| Player-level views: spawn, egg field, boss, escape portal | `renders/brv2_ground_spawn.jpg`, `brv2_ground_eggs.jpg`, `brv2_boss_view.jpg`, `brv2_ground_portal.jpg` |
| Positions (Blender + Roblox x/z), the boss box, egg regions + spots, the checks | `brv2_layout.json` |

## The floor + the boss
**Judge Martello** (Config.Bosses: Slam radius 26 where you stood, Windup 1.1 s, every 3 s, WalkSpeed 40, Scale 3.4, Hitbox 22 wide, 19 tall). **Floor:** -. His box: **208 x 190** (Blender x0, y0, x1, y1 in the layout JSON); his reach past it: **31.6 studs** (all
scenery stays outside box + reach + 1).

## Egg regions (27 candidate spots; the zone shows at most 14 eggs at once)
-

## Scenery (outside his reach)
one lilac floor with a big purple checkerboard, walk-through glitch squares, little dice, pixel flowers, tiny eyeballs (at most 1.5 studs tall, collision off)

## Gameplay checks (measured on the built geometry, `brv2_layout.json` → checks)
purple crystal-rock cliffs with teal grass, pixel trees, glowing crystals and mushrooms on top; four goo pools (one spilling a goo fall over the edge); the twisty tower, the big screen, the melty mall, the upside-down house, the leaning tower, giant dice, a neon tower; floating cubes + eyes over the ring; a dusk sky

## Known weaknesses (honest)
- **No ambience pass yet** (no wind / water animation / particles in the .blend) — the benchmark islands have one.
- **Shared pieces:** the spawn dock + pad and the escape portal come from Ocean Shore v2's parts (one look on every
  island, on purpose), and some themed props reuse v1's piece modules drawn with smooth classic primitives.
- **Not reviewed by crnuch** — built to the benchmark's rules and checks, but without his approval passes.
- **In the place as Parts** (`Workspace.WorldRedesign`): organic slabs / rocks / fronds are approximated as boxes
  (`../kit/hl_export.py`, classic section); exact shapes would need MeshParts uploaded by crnuch.
