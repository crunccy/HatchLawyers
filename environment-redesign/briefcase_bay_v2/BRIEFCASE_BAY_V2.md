# Briefcase Bay v2 — LAYOUT (2026-10-19) · approved by crnuch 2026-10-19 (keep the skyline); detailed pass in progress

The second island redone to the **Ocean Shore v2 benchmark** (approved by crnuch 2026-10-19):
- classic Roblox studs, not LEGO;
- one continuous flat surface the boss roams;
- spawn and escape portal on opposite sides;
- egg regions across the boss's ground;
- all scenery outside his reach;
- every gameplay number from the code.

This is the **layout for approval**; the detailed modelling pass comes after it, as with Ocean Shore. Blender only: nothing in Studio was touched. v1 (`../briefcase_bay/`, approved 2026-10-18) is untouched as the backup.
```bash
Blender -b --python environment-redesign/briefcase_bay_v2/bbv2_build.py      # .blend + layout JSON + checks + 7 renders (~1.2 min)
```
`-- norender` (checks only, ~15 s) and `-- only=aerial,diagram` work as in Ocean Shore v2.

| Deliverable | File |
| --- | --- |
| Editable .blend | `briefcase_bay_v2.blend` (7.2 MB) |
| Aerial render | `renders/bbv2_aerial.jpg` |
| True top-down | `renders/bbv2_topdown.jpg` |
| Player-level spawn view | `renders/bbv2_ground_spawn.jpg` |
| Player-level egg terrain view | `renders/bbv2_ground_eggs.jpg` |
| Boss-level view (over his shoulder, the lawn he sweeps) | `renders/bbv2_boss_view.jpg` |
| Escape portal view | `renders/bbv2_ground_portal.jpg` |
| Labelled gameplay diagram | `renders/bbv2_gameplay_diagram.jpg` |
| Positions (Blender + Roblox x/z), the boss box, suggested Bounds, egg regions + 27 spots, effect points, the checks | `bbv2_layout.json` |
| Sources | `bbv2_build.py`, `bbv2_parts.py` (+ Ocean Shore v2's `osv2_parts.py` / `osv2_detail.py`, `../kit/hl_classic.py`) |

Totals: 457k tris + 322k raised studs (one 48-tri Roblox-shaped stud mesh, instanced).

## 1. Audit: what the game does (code is the authority)
| What | Value | Source |
| --- | --- | --- |
| The Senior Partner's size | Scale 3.5: **37.8 tall** (model 10.8); body hitbox **23.1 wide** (HalfWidth 3.3), 4.9 back, 6.3 front, 40.3 tall | `tools/zones/bosses.json` x `Config.Bosses` |
| Walk | **38 studs/s** (players 32, max 40 with Speed upgrades); legs of up to ~2 s | `Config`, `BossService.nextLeg` |
| Targeting | the **nearest living player inside the zone's Bounds**; 85% of legs head for them (Chase 0.85), stopping his front + 6 studs short | `BossService.run / nextLeg` |
| Attack | **Cone (Briefcase Swing)**: he turns to the target and stands still for a **1.2 s windup**. Meanwhile a warning fan lies on the floor in his colour (thin parts, `Bosses.client`). Then everyone **within 45 studs and inside ±55° (110° wide)** is hit; anyone within 10.5 studs (3 x Scale) is hit wherever they stand. 0.45 s swing + 0.6 s recover. He attacks every **3.5 s** when a target is within **TriggerRange 60** | `Config.Bosses`, `BossService.attack / hitShape` |
| Where he can go | an axis-aligned box: the zone's `Bounds` shrunk by `Margin` (40 along / 10 across); every goal is clamped to it | `BossService.start / clampToArea` |
| Patrol (no one near) | back and forth along the box's long axis inside a **±14-stud band round its middle** (`StayNearMiddle` 14); a pocket-watch idle now and then (a pause = easy timing) | `BossService.nextLeg / run` |
| A hit | ragdoll 2.2 s, flung at 75 studs/s, 4 s safe, the boss ignores you 5 s; **all carried eggs drop** | `Config.Bosses`, `ZoneService.dropAll` |
| Dropped eggs | scatter 6-14 studs x (1 + 0.04 x eggs): **up to 20.7** with the 12-egg Diamond Briefcase (15.7 with the first Briefcase's 3). Clamped 4 inside `Bounds`, then landed on the zone's `Floor` / `Path` by a raycast; **with no Floor under them they land at y 0**. Grabbable after 0.9 s, for 30 s | `ZoneService.dropAll / floorAt`, `Config.Bosses` |
| Egg spawns | up to **14** at once on the zone's `EggSpots`, one more every 3-7 s; eggs are bought | `Config.Zones.List`, `ZoneService` |
| Who comes here | the **first zone** (License 0): new players with Empty Hands (1) or the Briefcase (3) | `Config.Zones` |
| Travel | arrive on the zone's `Arrival`; **no travel while carrying eggs** | `Config.Zones.Travel`, `TravelServer` |
| Safe zone | no script: "safe" = outside the Bounds or out of his reach | `BossService` |
| Today's Briefcase Bay | a 72 x 400 lane (`Bounds` -36..36, z -490..-90): his box is 52 x 320 | `Config.Zones.List` |

**What the benchmark changes from v1:**
- v1 had a round **arena (Partners' Plaza, r 62)** holding the boss, four **hedged office parks** for the eggs, and the portal past the arena.
- The benchmark rules out exactly that: no small arena confining the boss, no egg ground he can't reach, no mandatory checkpoint.
- So v2 is one open lawn he roams, with the eggs on it.
- crnuch's v1 call "the way home is past the boss" survives: the portal is on the far side, and **every route to it crosses his swing** (check 9).

## 2. The layout
| Piece | Where (Blender x, y; Roblox z = -y) | Notes |
| --- | --- | --- |
| **His box** (the dangerous lawn) | x -100..100, y -85..85 (**200 x 170**) | one continuous, flat, studded lawn (z 1): colour patches, clover meadows, worn patches, flush stepping stones, scattered papers, daisies; no stairs, walls, platforms or buildings |
| **The Green** (the playable lawn) | his box grown by **30-44 studs** all round (an organic outline: the scenery bites in at the bay, the cascade, the grotto and the east pool) | every place on it is **inside his 45-stud swing**: no safe strip and no safe corner. Low clipped hedges + flower beds mark its edge |
| **Boss start pad** | (0, 0) | a round limestone patch flush with the lawn, a gold scales-of-justice inlay |
| **The path** | spawn → his pad → portal, gently curving | the house style: flush orange paving, white dashed edges |
| **Spawn** | (0, -168): the **arrival terrace**, S | a round limestone terrace with the classic blue-and-white spawn pad. Lamp posts and benches; the **BRIEFCASE BAY** arch (brown wood board, white letters) over the way in. 83 studs from his box; the terrace's nearest edge is 63 (his swing reaches 45) |
| **Escape portal** | (0, 167): the **portal plaza**, N | the purple vortex in a limestone arch (Ocean Shore v2's portal, recoloured) on a round plaza, flush with the lawn (a level walk-in); 82 studs from his box |
| Egg regions (27 candidate spots) | Welcome Lawn (-34, -54) · Harbour Green (66, -44) · Cascade Lawn (-68, 32) · Ledger Row (58, 8) · Skyline Lawn (26, 60) | Welcome Lawn (by the spawn) is the safer start. Ledger Row sits on his idle patrol line and Skyline Lawn on the way to the portal: the riskiest |
| **The Bay** (SE) | (160, -108) | a sheltered harbour basin in the ring: a limestone quay with bollards + lamps, a wooden pier, the Bay Ferry, spilling over the edge in a waterfall |
| Lighthouse | (106, -157) | red-and-white, on the bay's headland |
| **The skyline** (N) | six towers round x -100..110, y 140-210 | classic glass towers (white floor bands, mullions, stepped crowns with a cyan glow band, studded roofs, antennas) behind the front cliffs; the tallest flank the portal |
| The cascade (NW) | (-169, 142) | ~38 studs in three steps from the high cliffs into a pool |
| Pools | NW (cascade), W (grotto), E (spills off the edge), SW (a lily pond) | limestone rims, foam, lily pads |
| Grotto, rock arch | W (-162, -59), SW rim | |
| Monuments | the **giant briefcase** by the arrival terrace (-53, -146); the **giant gavel** by the portal (71, 145) | on limestone plinths |
| Cliffs | a continuous limestone wall round the outer ring | tallest at the cascade (~38), N 20-30, E 14-18, low S so the aerial sees in; grass-topped terraces in front, boulders |
| Vegetation | the ring | ball trees (classic Roblox), blossom trees, palms by the water, bushes, hibiscus, ferns, grass |
| Underside + sky | | five limestone tiers, a soil band with roots, hanging rocks, vines; the sea below, clouds, 8 islets |

Walk: spawn → portal along the path is ~320 studs (~10 s at the base speed), all of it across his lawn.

## 3. Gameplay checks (measured on the built geometry with the real numbers; `bbv2_layout.json` → checks)
| # | Check | Result | Status |
| --- | --- | --- | --- |
| 1 | He can cover the whole dangerous area | 2193 / 2193 points of his box (4-stud grid) are open lawn; all four corners on the lawn | **Geometry: yes.** Roblox: his arena box + a wider idle patrol band (code) - **pending** |
| 2 | His attack has room | 1008 sampled swings (45 x 110° fans from a 25-stud grid, 16 facings): 98% of their area lies on the playable lawn | **Geometry: yes** |
| 3 | Warnings stay visible | **0 of 98,148** fan points where a player can stand are covered by anything; the lawn decor is at most 1.2 studs tall (the flower tufts); no tree canopy hangs over the lawn | Geometry yes; his floor fan over the decor needs a playtest - **pending** |
| 4 | Room to dodge | the 1.2 s windup = 38.4 studs at 32 studs/s; the worst spot in his fan needs 20.2 (out of the radius or out of the angle) | **Yes** by the numbers; feel - **pending playtest** |
| 5 | No props block routes | spawn → portal reachable on level ground (flood fill on the walkable lawn + lobes, at head height, so the welcome arch is walked under) | **Yes** |
| 6 | Egg regions reachable | 27 spots on open lawn inside his box, 9+ apart, 22+ from his pad, 6+ off the path | **Yes** |
| 7 | Dropped eggs land on the island | spots are 32-40 studs from the lawn's edge vs the 20.7 max scatter. With **today's code**, eggs from a hit anywhere on the lawn land on it **96.0%** of the time carrying 3 (94.2% carrying 12); the rest come from hits within ~16-21 studs of the edge, land at y 0 in the scenery and are lost | **Partly**: needs the drop fix in §7 (item 4) - **pending** |
| 8 | Spawn + portal work | the spawn is 83 studs from his box (his swing reaches 45); the portal is a level walk-in, its plaza 58+ out | Layout yes; the home-with-eggs rule is not built - **pending** |
| 9 | Safe zone separated | the arrival terrace + the portal plaza are out of reach; **no walkable route avoids his swing** (the lawn's edge is 32-44 from his box all round) | **Yes** |
| 10 | Size fits his body + attack | 200 x 170 vs a 37.8-tall, 23-wide boss with a 45-stud swing | **Yes** |

## 4. Briefcase Bay's identity (a choice for crnuch)
Ocean Shore's brief asked for a natural wilderness with no buildings. Briefcase Bay is the business-and-law zone (the Briefcase egg, the Senior Partner), so v2 does both:
- **The playable ground is natural:** a park lawn with meadows and a flush path, no structures on it.
- **The business identity lives in the scenery ring, out of his reach:**
  - the office skyline rising behind the back cliffs, which matches crnuch's original reference (a dense blue skyline);
  - the harbour with its ferry and lighthouse;
  - the giant briefcase and gavel monuments;
  - the welcome arch.
- Detail otherwise comes from nature: limestone cliffs, the cascade, pools, trees.

If crnuch would rather have it all-natural like Ocean Shore (no towers), the towers come out and the back cliffs grow; the layout stays the same.

## 5. Style: classic Roblox studs, not LEGO (the benchmark's rules)
- **Cohesive pieces:** the lawn is ONE slab, the island ONE body with five big rock tiers, and the cliffs are chunky faceted limestone blocks. Round things (trunks, ball trees, the lighthouse, the eggs) are smooth Roblox-style shapes; the towers are smooth blocks with white bands.
- **Raised Roblox-shaped studs on the broad surfaces only:** the lawn and its patches, the path, the paving, the quay, grass and rock tops, the tower roofs and podiums.
- **Unstudded:** water, foam, falls, the portal's glow and vortex, trees, leaves, flowers, papers, the glass, soil.
- **The rock looks are recoloured to warm limestone** for this island (one `PAL` override in `bbv2_parts.py`), so Ocean Shore v2's cliff and portal pieces are reused without touching them.

## 6. Assets
**Reused from Ocean Shore v2 (unchanged files):**
- `cliff_column`, `palm2`, `bush`, `hibiscus`, `grass_clump`, `fern_bush`;
- `waterfall_tall`, `edge_fall`, `foam_outline`, `rock_arch`, `spawn_pad`, `spawn_dock` (the pier), `escape_portal`, `vine`, `pebbles`.

**New in `bbv2_parts.py`:**

| Piece | Function |
| --- | --- |
| Glass office tower (podium, banded shaft, mullions, stepped crown + glow band, roof plant, antenna) | `tower` |
| Lighthouse (banded, gallery, glowing lantern, cap) | `lighthouse` |
| The Bay Ferry | `ferry` |
| Giant briefcase, giant gavel (on plinths) | `giant_briefcase`, `giant_gavel` |
| BRIEFCASE BAY welcome arch (wayfinding style) | `welcome_sign` |
| Classic ball tree, blossom tree | `round_tree` |
| Lamp post, bench, clipped hedge | `lamp_post`, `bench`, `hedge_run` |
| The flush orange path (white dashed edges) | `path` |
| Boss start pad (gold scales inlay) | `scales_pad` |
| Lawn decor: daisies, flower tufts, papers, flat stepping stones | `daisies`, `flower_tuft`, `paper`, `stepping_stones` |
| Preview Briefcase egg (gold, leather band + handle; preview only) | `egg_preview` |

## 7. Roblox integration considerations (when crnuch says go)
1. **His arena box** (200 x 170) set directly, a per-boss `Arena`, not `Bounds` - `Margin` (as for Ocean Shore v2).
2. **Idle patrol:** widen `StayNearMiddle` (14 today) so he uses the whole box when no one is near.
3. **The zone's `Bounds`** = his box + 44 (the lawn's bounding rectangle, `suggested_bounds_*` in the JSON), so he can target and hit anyone on the lawn. The arrival terrace and the portal plaza stay outside it.
4. **The drop fix (new; Ocean Shore v2 needs it too):** in `ZoneService.dropAll`, if a landing spot has no `Floor` under it, step it back toward the hit player until it does. A few lines; without it ~4-6% of dropped eggs are lost in the scenery (check 7).
5. **Floor:** the lawn, its patches, the path and the two necks in the zone's `Floor` / `Path`.
6. **EggSpots** from `bbv2_layout.json` (27 spots, Roblox x/z given); MaxEggs stays 14.
7. **Arrival** on the spawn pad; **the escape portal** needs the home-with-eggs rule (shared with Ocean Shore v2).
8. **Walls:**
   - An invisible wall along the lawn's edge (on the hedge line), open only at the two necks, so nobody walks into the scenery ring.
   - **Ocean Shore v2 needs the same along its sand edge:** its moss ring is walkable ground today and could let a player walk round outside his reach.
   - An invisible rim where the arrival terrace and the portal plaza meet a drop.
9. **Collision:**
   - **Off** for the lawn decor (daisies, flowers, papers, pebbles, flat stones, patches), leaves, water and foam.
   - **On** for the ground, hedges, rocks, cliffs, towers, the portal frame, the welcome arch's pillars and the lamp posts.
10. **Studs:** the raised-stud tiles (`StarterPlayerScripts.Studs`, tag `StudTop`) on the studded looks only (§5).
11. **Water** as smooth parts with a moving texture, no studs.
12. **Parts vs meshes** is still open (crnuch's call pending); the towers, lighthouse and ball trees suit MeshParts.
13. **Lighting:** a bright daytime preset for the zone (client-side swap).
14. **Streaming + LOD:** towers, cliffs, vegetation, the bay and the falls as separate models; islets and clouds client-only.

## 8. For approval
- **Theme (§4):** keep the skyline + harbour + monuments as Briefcase Bay's identity in the ring, or go all-natural?
- **The Senior Partner's ground:**
  - a 200 x 170 open lawn he roams;
  - every place on the lawn inside his swing;
  - 0 hidden warning points;
  - no safe bypass.
- **Eggs:** five regions, from the safer Welcome Lawn by the spawn to Ledger Row on his patrol line and Skyline Lawn on the way out; 27 spots.
- **Spawn S, portal N**, straight across his lawn (v1's "the way home is past the boss", kept).

## 9. Known weaknesses (honest) + the detailed pass
- **The towers** are plain classic boxes: the detailed pass gives them varied setbacks and crowns, name boards (fictional firms, as v1's), podium gardens, and a cliff terrace for them to stand on.
- **The ring's ground** is still plain grass in places (the S lobe's sides, round the lighthouse): more terraces, flower beds and rocks in the detailed pass.
- **The portal** is Ocean Shore's (coral and shells at its feet): Briefcase Bay's own dressing (gold trim, a briefcase keystone) next.
- **The quay and the ferry** are simple.
- **Ambience and audio** (wind in the trees, the falls, the lighthouse beam, gulls, papers swirling round him; the licence-checked sound list) come with the detailed pass, as for Ocean Shore v2.
- **The lawn's centre** is open on purpose, so his warnings are always visible.
- **Rendering:** EEVEE warned "shadow buffer full" on the ground views, so a few small shadows may be missing; the renders were checked by eye.
- **Not proven in Roblox:** §3's pending rows.
