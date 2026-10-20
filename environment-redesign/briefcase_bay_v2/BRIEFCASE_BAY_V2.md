# Briefcase Bay v2 — DETAILED (2026-10-19) · layout approved (keep the skyline); detailed pass waiting for approval

The second island redone to the **Ocean Shore v2 benchmark** (approved by crnuch 2026-10-19):
- classic Roblox studs, not LEGO;
- one continuous flat surface the boss roams;
- spawn and escape portal on opposite sides;
- egg regions across the boss's ground;
- all scenery outside his reach;
- every gameplay number from the code.

**Status:**
- crnuch approved the layout on 2026-10-19 ("keep the skyline"); this is the detailed modelling pass.
- The layout, his box, the lawn, the eggs, the spawn and the portal position are unchanged, and every check is still green.
- Blender only: nothing in Studio was touched. v1 (`../briefcase_bay/`, approved 2026-10-18) is untouched as the backup.
```bash
Blender -b --python environment-redesign/briefcase_bay_v2/bbv2_build.py      # .blend + layout JSON + checks + 8 renders (~1.3 min)
Blender -b --python environment-redesign/briefcase_bay_v2/bbv2_ambience.py   # + the ambience, saved into the .blend
```
`-- norender` (checks only, ~15 s) and `-- only=aerial,diagram` work as in Ocean Shore v2.

| Deliverable | File |
| --- | --- |
| Editable .blend (ambience animated: scrub the timeline) | `briefcase_bay_v2.blend` (8.6 MB) |
| Aerial render | `renders/bbv2_aerial.jpg` |
| The bay (the harbour, the lighthouse, the arrival side) | `renders/bbv2_bay.jpg` |
| True top-down | `renders/bbv2_topdown.jpg` |
| Player-level spawn view | `renders/bbv2_ground_spawn.jpg` |
| Player-level egg terrain view | `renders/bbv2_ground_eggs.jpg` |
| Boss-level view (over his shoulder, the lawn he sweeps) | `renders/bbv2_boss_view.jpg` |
| Escape portal view | `renders/bbv2_ground_portal.jpg` |
| Labelled gameplay diagram | `renders/bbv2_gameplay_diagram.jpg` |
| Asset catalog | §6 |
| Roblox integration considerations | §8 |
| Positions (Blender + Roblox x/z), the boss box, suggested Bounds, egg regions + 27 spots, effect points, the checks | `bbv2_layout.json` |
| Sources | `bbv2_build.py`, `bbv2_parts.py`, `bbv2_detail.py`, `bbv2_ambience.py` (+ Ocean Shore v2's `osv2_parts.py` / `osv2_detail.py`, `../kit/hl_classic.py`) |

Totals: 546k tris + 326k raised studs (one 48-tri Roblox-shaped stud mesh, instanced).

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

## 2. The island (layout approved; detailed)
| Piece | Where (Blender x, y; Roblox z = -y) | Notes |
| --- | --- | --- |
| **His box** (the dangerous lawn) | x -100..100, y -85..85 (**200 x 170**) | one continuous, flat, studded lawn (z 1): colour patches, clover meadows, worn patches, flush stepping stones, scattered papers, daisies; no stairs, walls, platforms or buildings |
| **The Green** (the playable lawn) | his box grown by **30-44 studs** all round (an organic outline: the scenery bites in at the bay, the cascade, the grotto and the east pool) | every place on it is **inside his 45-stud swing**: no safe strip and no safe corner. Low clipped hedges + flower beds mark its edge; lamp posts and benches face it from the ring |
| **Boss start pad** | (0, 0) | a round limestone patch flush with the lawn, a gold scales-of-justice inlay |
| **The path** | spawn → his pad → portal, gently curving | the house style: flush orange paving, white dashed edges |
| **Spawn** | (0, -168): the **arrival terrace**, S | round limestone terrace, the classic blue-and-white spawn pad, lamp posts and benches. The **BRIEFCASE BAY** arch (brown wood board, white letters) over the way in; flower beds, topiary and lamps either side. 83 studs from his box; the terrace's nearest edge is 63 (his swing reaches 45) |
| **Escape portal** | (0, 167): the **portal plaza**, N, in the notch between the two skyline shelves | the purple vortex down to the ground in a **gold-trimmed limestone arch** on dressed buttresses with gold bands. A **gold briefcase keystone** with purple crystals, glowing runes, a grass cap with trailing flowers. Lamps, topiary, flower beds and crystals at its feet; gold bands in the paving leading in. A level walk-in, 82 studs from his box |
| Egg regions (27 candidate spots) | Welcome Lawn (-34, -54) · Harbour Green (66, -44) · Cascade Lawn (-68, 32) · Ledger Row (58, 8) · Skyline Lawn (26, 60) | Welcome Lawn (by the spawn) is the safer start. Ledger Row sits on his idle patrol line and Skyline Lawn on the way to the portal: the riskiest |
| **The skyline** (N) | six towers on two raised limestone **shelves** (30-80° and 100-136°, 11 studs up) | each its own silhouette, every one on a limestone podium with a white colonnade, a revolving door and its name in gold. Planted terraces step down in front of the shelves' craggy faces. The six: **AMICUS** (glass pyramid crown, gold finial), **DOCKET & CO** (a giant gold briefcase on the roof, its seam glowing), **VERDICT** (three setbacks with planted terraces, a spire), **LEXICON LAW** (a 96-stud glass cylinder with a dome + gold spire), **HABEAS** (twin shafts and a glass skybridge), **CASEWORKS** (an open crown frame and a helipad). Fictional firms |
| **The Bay** (SE) | (160, -108) | a sheltered harbour basin with a limestone quay. On the quay: bollards with rope, lamps, lifebuoy stands, crates + barrels. In the water: a pier with bollards, **the Bay Ferry** (blue + red stripes, rails, cabin, wheelhouse, upper-deck benches, lifebuoys, a red funnel, a flag, its name on both sides) moored with a rope, a sailboat with two sails, three buoys with lights. The basin spills over the island edge in a waterfall |
| Lighthouse | (105, -156) | red-and-white on its rocky headland with the **keeper's cottage** (red gable roof, door, windows, chimney); its beam is its own object |
| Welcome fountain | (76, -143), between the arrival terrace and the bay | a kerbed limestone basin, a two-tier pedestal, a gold briefcase on top spouting four arcs of water |
| The cascade (NW) | (-169, 142) | ~38 studs in three steps from the high cliffs into a pool |
| Pools | NW (cascade), W (grotto), E (spills off the edge), SW (a lily pond) | limestone rims, foam, lily pads |
| Grotto, rock arch | W (-162, -59), SW rim (-159, -143) | |
| Monuments | the **giant briefcase** by the arrival terrace (-53, -146); the **giant gavel** by the portal (71, 145) | on limestone plinths with plaques ("BRIEFCASE BAY", "ORDER!") and flower beds either side; the briefcase has stitching, a luggage tag and papers peeking out of its lid |
| Cliffs | a continuous limestone wall round the outer ring (the shelves in the N) | tallest at the cascade (~38), E 14-16, low S so the aerial sees in; grass-topped terraces in front, boulders |
| Vegetation | the ring + the shelves | ~230 plants: classic ball oaks (flared trunks, boughs, canopies in three greens), blossom trees, conifers (mostly on the shelves), palms by the water, bushes, hibiscus, ferns, grass, topiary, kerbed flower beds |
| Underside + sky | | five limestone tiers, a soil band with roots, hanging rocks, vines; the sea below, clouds, 8 islets |

Walk: spawn → portal along the path is ~320 studs (~10 s at the base speed), all of it across his lawn.

## 3. Gameplay checks (measured on the built geometry with the real numbers; `bbv2_layout.json` → checks)
| # | Check | Result | Status |
| --- | --- | --- | --- |
| 1 | He can cover the whole dangerous area | 2193 / 2193 points of his box (4-stud grid) are open lawn; all four corners on the lawn | **Geometry: yes.** Roblox: his arena box + a wider idle patrol band (code) - **pending** |
| 2 | His attack has room | 1008 sampled swings (45 x 110° fans from a 25-stud grid, 16 facings): 98% of their area lies on the playable lawn | **Geometry: yes** |
| 3 | Warnings stay visible | **0 of 98,148** fan points where a player can stand are covered by anything; the lawn decor is at most 1.2 studs tall (the flower tufts); no tree canopy hangs over the lawn. Nothing that moves passes over his lawn but his own papers: gulls circle 4+ studs outside its edge, petals fall from trees 16+ outside it | Geometry yes; his floor fan over the decor needs a playtest - **pending** |
| 4 | Room to dodge | the 1.2 s windup = 38.4 studs at 32 studs/s; the worst spot in his fan needs 20.2 (out of the radius or out of the angle) | **Yes** by the numbers; feel - **pending playtest** |
| 5 | No props block routes | spawn → portal reachable on level ground (flood fill on the walkable lawn + lobes, at head height, so the welcome arch is walked under) | **Yes** |
| 6 | Egg regions reachable | 27 spots on open lawn inside his box, 9+ apart, 22+ from his pad, 6+ off the path | **Yes** |
| 7 | Dropped eggs land on the island | spots are 32-41 studs from the lawn's edge vs the 20.7 max scatter. With **today's code**, eggs from a hit anywhere on the lawn land on it **96.0%** of the time carrying 3 (94.2% carrying 12); the rest come from hits within ~16-21 studs of the edge, land at y 0 in the scenery and are lost | **Partly**: needs the drop fix in §8 (item 4) - **pending** |
| 8 | Spawn + portal work | the spawn is 83 studs from his box (his swing reaches 45); the portal is a level walk-in, its plaza 58+ out | Layout yes; the home-with-eggs rule is not built - **pending** |
| 9 | Safe zone separated | the arrival terrace + the portal plaza are out of reach; **no walkable route avoids his swing** (the lawn's edge is 32-44 from his box all round) | **Yes** |
| 10 | Size fits his body + attack | 200 x 170 vs a 37.8-tall, 23-wide boss with a 45-stud swing | **Yes** |

## 4. Briefcase Bay's identity (crnuch's call: keep the skyline)
- **The playable ground is natural:** a park lawn with meadows and a flush path, no structures on it.
- **The business identity lives in the scenery ring, out of his reach:**
  - the skyline: six fictional firms on limestone shelves;
  - the harbour with its ferry and lighthouse;
  - the giant briefcase and gavel;
  - the welcome arch and fountain;
  - the gold briefcase keystone on the portal.
- Detail otherwise comes from nature: limestone cliffs, the cascade, pools, trees.

## 5. Style: classic Roblox studs, not LEGO (the benchmark's rules)
- **Cohesive pieces:** the lawn is ONE slab, the island ONE body with five big rock tiers, the shelves ONE slab each; the cliffs are chunky faceted limestone blocks. Round things (trunks, ball trees, the lighthouse, the round tower, the eggs) are smooth Roblox-style shapes; the towers are smooth blocks with white bands and dark spandrels.
- **Raised Roblox-shaped studs on the broad surfaces only:** the lawn and its patches, the path, the paving, the quay, kerbs, grass and rock tops, the shelves, the tower roofs and podiums, the helipad.
- **Unstudded:** water, foam, falls, the portal's glow and vortex, glass, trees, leaves, flowers, papers, sails, soil.
- **The rock looks are recoloured to warm limestone** for this island (one `PAL` override in `bbv2_parts.py`), so Ocean Shore v2's cliff and portal pieces are reused without touching them.

## 6. Asset catalog
**Reused from Ocean Shore v2 (unchanged files):**
- `cliff_column`, `palm2`, `bush`, `hibiscus`, `grass_clump`, `fern_bush`;
- `waterfall_tall`, `edge_fall`, `foam_outline`, `rock_arch`, `spawn_pad`, `spawn_dock` (the pier), `vine`, `pebbles`, `crate`, `barrel`, `rope`, `_shard`.

**New in `bbv2_parts.py` (layout pass) + `bbv2_detail.py` (detailed pass):**

| Piece | Function |
| --- | --- |
| Office towers in six styles (slab / stepped / round / twin / pyramid / briefcase), each on a podium with a colonnade, a revolving door and a gold name | `bbv2_detail.tower2` (+ `_floors`, `_podium`, `_aerial`) |
| The escape portal, dressed for the bay | `escape_portal_bb` |
| The Bay Ferry, a sailboat, buoys, bollards with rope, lifebuoy stands | `ferry2`, `sailboat`, `buoy`, `bollard`, `lifebuoy_stand` |
| Lighthouse + keeper's cottage + its beam | `lighthouse2` (on `bbv2_parts.lighthouse`) |
| Welcome fountain | `fountain` |
| Park trees (oak / blossom / conifer), topiary, kerbed flower beds | `park_tree`, `topiary`, `flower_bed` |
| Giant briefcase, giant gavel (detailed) | `giant_briefcase2`, `giant_gavel2` (on `bbv2_parts.giant_briefcase / giant_gavel`) |
| BRIEFCASE BAY welcome arch (wayfinding style) | `bbv2_parts.welcome_sign` |
| Lamp post, bench, clipped hedge | `lamp_post`, `bench`, `hedge_run` |
| The flush orange path (white dashed edges) | `path` |
| Boss start pad (gold scales inlay) | `scales_pad` |
| Lawn decor: daisies, flower tufts, papers, flat stepping stones | `daisies`, `flower_tuft`, `paper`, `stepping_stones` |
| Preview Briefcase egg (gold, leather band + handle; preview only) | `egg_preview` |
| The skyline shelves, the island body, the lawn, the bay basin + quay, underside tiers, islets, clouds | `bbv2_build` + `../kit/hl_classic.ClassicMesh.slab / rock / beam` |

## 7. Ambience + audio
### Visual (in the .blend: scrub the timeline; no preview clips - crnuch's call)
| Effect | How | Clear of his lawn? |
| --- | --- | --- |
| Trees, palms, bushes sway | WindSway on Vegetation | yes: no canopy over the lawn |
| The bay, the pools, the fountain, the falls, foam, the far sea flow | animated water shaders | yes |
| The ferry, the sailboat and the buoys bob | keyframes (the `Boats` object) | yes |
| Splashes + mist at the cascade; spray off the edge falls; splashes where the fountain's arcs land | particles | yes |
| Sun sparkles on the pools + the bay; purple motes at the portal; the portal breathes | particles + emission drivers | yes |
| Tower crowns breathe cyan; aviation lights blink at 0.5 Hz; the helipad + the HQ's briefcase seam glow; the lighthouse lantern breathes | emission drivers (nothing over 3 Hz) | yes |
| The lighthouse beam sweeps ±60° over the sea side (8 s a sweep) | keyframes; hidden in daylight stills | yes: it points out to sea |
| Blossom petals drift down under the 19 blossom trees | particles (tumbling) | yes: 16+ studs outside the lawn |
| Butterflies over the flower beds by the terrace + the portal | `hl_ambience.butterflies` | yes |
| 8 gulls circle the bay, the lighthouse and the E + W edges | parented rings, looped | yes: 4+ studs outside the lawn's edge |
| Papers swirl round the Senior Partner's ankles; he turns slowly on his pad | particles + keyframes | his own (`docs/BOSSES.md`: "paper sheets swirl around his ankles") |
| Clouds drift; the islets bob | keyframes | yes |

### Audio (research only: nothing downloaded or listened to; every licence read on its page, 2026-10-19)
Tier 1 = Roblox's licensed library (the game's `Shared.Sfx` rule); Tier 2 = these CC0 picks.

| Layer | Tier 1 (Creator Store search) | Tier 2 pick (CC0, checked) |
| --- | --- | --- |
| Primary bed: a city park by day | "city park ambience", "park birds" | [leipzig city park autumn atmo with birds wind and cars](https://freesound.org/people/Garuda1982/sounds/608854/) (Garuda1982, 11:12, 48 kHz) as the bed; [Birds 3 (city park)](https://freesound.org/people/giddster/sounds/387964/) (giddster, 0:25) or [park city early morning quiet birds](https://freesound.org/people/kyles/sounds/455819/) (kyles, 0:51, 48 kHz) for birdsong |
| Distant city hum (the skyline) | "city ambience loop", "traffic distant" | [CITY AMBIENCE for CLEAN LOOP](https://freesound.org/people/ListenTonyBoy/sounds/325506/) (ListenTonyBoy, 0:22; checked for v1) |
| Harbour water lapping at the quay (3D) | "water lapping dock", "harbor ambience" | [Water Lapping Dock](https://freesound.org/people/Eakoontz/sounds/151747/) (Eakoontz, 1:01, AIFF 44.1 kHz); [Small Boat Wake… lapping under Wooden Boardwalk](https://freesound.org/people/Alex_hears_things/sounds/758858/) (Alex_hears_things, 1:50, 48 kHz mono) as an alternative |
| A distant ship horn (now and then) | "ship horn", "foghorn" | [Long Distant Foghorn](https://freesound.org/people/Danjocross/sounds/507471/) (Danjocross, 0:08, 48 kHz / 24-bit); [ship horn.wav](https://freesound.org/people/monotraum/sounds/208714/) (monotraum, 0:34) as an alternative |
| Seagulls | "seagulls" | Ocean Shore v2's: [A quiet seaside seagulls distant](https://freesound.org/people/selcukartut/sounds/546565/) (selcukartut) as a far bed, [Seagull Swarm at Port](https://freesound.org/people/Kinoton/sounds/468080/) (Kinoton) to cut single calls |
| The welcome fountain (3D) | "fountain" | [Ambiance_Fountain_Small_Loop_Stereo](https://freesound.org/people/Nox_Sound/sounds/676173/) (Nox_Sound, 0:10 loop, 48 kHz / 24-bit) |
| The cascade + edge falls (3D) | "waterfall" | Ocean Shore v2's: [Waterfall Loop](https://freesound.org/people/kwahmah_02/sounds/274259/) (kwahmah_02), [Ambiance_Waterfall_Loop_04](https://freesound.org/people/Nox_Sound/sounds/511075/) (Nox_Sound) |
| Wind in the trees | "wind trees" | Ocean Shore v2's: [Soft Wind in the Trees](https://freesound.org/people/Borgory/sounds/751473/) (Borgory) |
| The Senior Partner's papers | his own sounds (BossService) first | [paper_rustling_03](https://freesound.org/people/Spaghetto87/sounds/731484/) (Spaghetto87, 0:10) for the swirl; [Paper Rustle](https://freesound.org/people/BenjaminNelan/sounds/353125/) (BenjaminNelan, 0:01) as a swing one-shot |
| Office murmur near the shelves (optional, far + quiet) | "office ambience" | v1's picks (`../briefcase_bay/BRIEFCASE_BAY.md`: Globofonia, SduggySounds, DiArchangeli, all CC0) |

Not implemented in Roblox (the brief: not yet).

## 8. Roblox integration considerations (when crnuch says go)
1. **His arena box** (200 x 170) set directly, a per-boss `Arena`, not `Bounds` - `Margin` (as for Ocean Shore v2).
2. **Idle patrol:** widen `StayNearMiddle` (14 today) so he uses the whole box when no one is near.
3. **The zone's `Bounds`** = his box + 44 (the lawn's bounding rectangle, `suggested_bounds_*` in the JSON), so he can target and hit anyone on the lawn. The arrival terrace and the portal plaza stay outside it.
4. **The drop fix (Ocean Shore v2 needs it too):** in `ZoneService.dropAll`, if a landing spot has no `Floor` under it, step it back toward the hit player until it does. A few lines; without it ~4-6% of dropped eggs are lost in the scenery (check 7).
5. **Floor:** the lawn, its patches, the path and the two necks in the zone's `Floor` / `Path`.
6. **EggSpots** from `bbv2_layout.json` (27 spots, Roblox x/z given); MaxEggs stays 14.
7. **Arrival** on the spawn pad; **the escape portal** needs the home-with-eggs rule (shared with Ocean Shore v2).
8. **Walls:**
   - An invisible wall along the lawn's edge (on the hedge line), open only at the two necks, so nobody walks into the scenery ring.
   - **Ocean Shore v2 needs the same along its sand edge:** its moss ring is walkable ground today and could let a player walk round outside his reach.
   - An invisible rim where the arrival terrace and the portal plaza meet a drop.
9. **Collision:**
   - **Off** for the lawn decor (daisies, flowers, papers, pebbles, flat stones, patches), leaves, sails, water, foam and the beam.
   - **On** for the ground, hedges, rocks, cliffs, shelves, towers, the portal frame, the welcome arch's pillars, lamp posts and the fountain's basin.
10. **Studs:** the raised-stud tiles (`StarterPlayerScripts.Studs`, tag `StudTop`) on the studded looks only (§5).
11. **Water** as smooth parts with a moving texture, no studs; the fountain's arcs as beams or particles.
12. **Parts vs meshes** is still open (crnuch's call pending); the towers, the round tower, the lighthouse, ball trees and boats suit MeshParts.
13. **Lighting:** a bright daytime preset for the zone (client-side swap); the beam, the aviation lights and the lantern matter only if the zone ever gets a night.
14. **Streaming + LOD:** each tower, the shelves, cliffs, vegetation, the bay + boats and the falls as separate models; islets and clouds client-only; the tower glass far away as plain blocks.
15. **Signs:** the firm names, the plaques and the ferry's name are real 3D text in Blender; in Roblox they become SurfaceGui text (FredokaOne, gold on dark panels; the welcome arch stays wayfinding style).
16. **Audio** from §7, as 3D sounds at the fountain, the falls and the quay, and 2D beds.

## 9. For approval (the benchmark's questions)
- **Classic studs:** studs on broad surfaces only, cohesive terrain, no stacked-brick look (§5).
- **Nature + the skyline:**
  - the playable lawn has no structures;
  - the made things (towers, harbour, lighthouse, fountain, monuments, arch) all stand in the ring, out of his reach (crnuch's call: keep the skyline).
- **Interesting, not cluttered:**
  - the richness lives in the ring: six distinct towers, the bay, the lighthouse, the cascade, pools, planting;
  - the lawn has meadows, patches, papers and a path, so it never reads as an empty baseplate, yet nothing over 1.2 studs stands on it.
- **The Senior Partner's ground:**
  - a 200 x 170 open lawn he roams;
  - every place on it inside his swing;
  - 0 hidden warning points;
  - no safe bypass.
- **Eggs:** five regions, from the safer Welcome Lawn by the spawn to Ledger Row on his patrol line and Skyline Lawn on the way out; 27 spots.
- **Still to refine:** §10.

## 10. Known weaknesses (honest)
- **Tower glass** reads as glass boxes with bands: no interiors or lit windows behind it.
- **The ring's ground** still shows plain grass in a few gaps (between the bay and the east pool).
- **The far side of the shelves** (seen only from outside the island) is plain limestone.
- **The boss's papers and his turn** are a Blender stand-in; in the game they are his own effect and idle.
- **The preview eggs** are placeholders (the game draws its own Briefcase eggs).
- **Rendering:** EEVEE warned "shadow buffer full" on the ground views, so a few small shadows may be missing; the renders were checked by eye.
- **Not proven in Roblox:** §3's pending rows.
