# Pet Park v2 — DETAILED (2026-10-20, mr.robe's session) · waiting for crnuch's approval

Redone to crnuch's **Ocean Shore v2 benchmark** (approved 2026-10-19), user's call on mr.robe's PC ("do the same for
the rest of the islands"). Built on `../kit/hl_v2.py` (the benchmark turned into a shared frame: island body, spawn dock
+ pad, the purple escape portal, egg regions, the scenery-ring helpers, the checks, the diagram, the renders) plus this
island's theme in `ppv2_build.py`. v1 (`../Fetch Field (W, mid) · Bowl Green (S, nearest the spawn: safer) · Ball Pit Meadow (E, mid) · Agility Lawn (N, high risk) · Bone Garden (NE, by the portal: high risk)/`) is untouched as the backup.
- classic Roblox studs, not LEGO; studs only on broad floor / terrain / structural tops;
- one continuous flat floor the boss roams, egg regions across it;
- spawn dock SW, the escape portal (RETURN HOME, a level walk-in) NE;
- all scenery outside the boss's reach; every gameplay number from `Config.Bosses` / `Config.Zones`.
```bash
Blender -b --python environment-redesign/pet_park_v2/ppv2_build.py      # .blend + layout JSON + checks + 7 renders
```

| Deliverable | File |
| --- | --- |
| Editable .blend | `pet_park_v2.blend` |
| Aerial, top-down, gameplay diagram | `renders/ppv2_aerial.jpg`, `ppv2_topdown.jpg`, `ppv2_gameplay_diagram.jpg` |
| Player-level views: spawn, egg field, boss, escape portal | `renders/ppv2_ground_spawn.jpg`, `ppv2_ground_eggs.jpg`, `ppv2_boss_view.jpg`, `ppv2_ground_portal.jpg` |
| Positions (Blender + Roblox x/z), the boss box, egg regions + spots, the checks | `ppv2_layout.json` |

## The floor + the boss
**Barrister Bulldog** (Config.Bosses: Ring 34 all round, Windup 1.4 s, every 3 s, WalkSpeed 44, Scale 3.5, Hitbox 18 wide, 26.6 tall). **Floor:** -. His box: **200 x 186** (Blender x0, y0, x1, y1 in the layout JSON); his reach past it: **38.5 studs** (all
scenery stays outside box + reach + 1).

## Egg regions (27 candidate spots; the zone shows at most 14 eggs at once)
-

## Scenery (outside his reach)
one mown lawn with light mowing stripes, clover patches, walk-through tennis balls, frisbees, chew bones, daisies, paw-print trails (at most 1.2 studs tall, collision off)

## Gameplay checks (measured on the built geometry, `ppv2_layout.json` → checks)
mossy limestone outcrops with park trees, bushes and grass on top; four duck ponds with lily pads (one with a wooden bridge, one spilling over the edge); the giant corgi + giant cat statues, three dog houses (REX, BELLA, MAX), a cat tower, a rabbit hutch, THE BARKERY + PAW CLINIC, bunny topiaries, bird houses; park trees, flower beds, topiaries, hibiscus

## Known weaknesses (honest)
- **No ambience pass yet** (no wind / water animation / particles in the .blend) — the benchmark islands have one.
- **Shared pieces:** the spawn dock + pad and the escape portal come from Ocean Shore v2's parts (one look on every
  island, on purpose), and some themed props reuse v1's piece modules drawn with smooth classic primitives.
- **Not reviewed by crnuch** — built to the benchmark's rules and checks, but without his approval passes.
- **In the place as Parts** (`Workspace.WorldRedesign`): organic slabs / rocks / fronds are approximated as boxes
  (`../kit/hl_export.py`, classic section); exact shapes would need MeshParts uploaded by crnuch.
