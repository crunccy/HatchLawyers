# Ocean Shore v2 — DETAILED (2026-10-19) · APPROVED by crnuch 2026-10-19 as the benchmark for the other islands

crnuch's brief: redesign Ocean Shore from the approved concept image (`../references/ocean_shore_concept.webp`) as a
natural tropical wilderness built around the real Megalodon mechanics, in **classic Roblox studs, not LEGO**. The
layout was approved on 2026-10-19 (after one note: the portal frame, now grounded + detailed); this is the detailed
modeling pass. Blender only: nothing in Studio was touched; v1 (`../ocean_shore/`) is untouched as the backup.
```bash
Blender -b --python environment-redesign/ocean_shore_v2/osv2_build.py      # .blend + layout JSON + checks + 7 renders (~1.5 min)
Blender -b --python environment-redesign/ocean_shore_v2/osv2_ambience.py   # + the ambience, saved into the .blend
```

| # | Deliverable (the brief's list) | File |
| --- | --- | --- |
| 1 | Editable .blend (ambience animated: scrub the timeline) | `ocean_shore_v2.blend` (9.0 MB) |
| 2 | Aerial beauty render (the concept's angle) | `renders/osv2_aerial.jpg` |
| 3 | True top-down render | `renders/osv2_topdown.jpg` |
| 4 | Player-level spawn view | `renders/osv2_ground_spawn.jpg` |
| 5 | Player-level egg terrain view | `renders/osv2_ground_eggs.jpg` |
| 6 | Boss-level charge-space view | `renders/osv2_boss_view.jpg` |
| 7 | Escape portal view | `renders/osv2_ground_portal.jpg` |
| 8 | Labelled gameplay diagram | `renders/osv2_gameplay_diagram.jpg` |
| 9 | Asset catalog | §6 below |
| 10 | Roblox integration considerations | §8 below |
| — | Positions (Blender + Roblox x/z), boss box, egg regions + 28 spots, effect points, the checks | `osv2_layout.json` |
| — | Sources | `osv2_build.py`, `osv2_parts.py`, `osv2_detail.py`, `osv2_ambience.py`, `../kit/hl_classic.py` |

Totals: 511k tris + 298k raised studs (one 48-tri Roblox-shaped stud mesh, instanced).

## 1. Audit: what the game actually does (code is the authority)
| What | Value | Source |
| --- | --- | --- |
| Megalodon size | Scale 3.2: **25.6 tall, 14.8 wide, 16.8 deep** | `tools/zones/bosses.json` x `Config.Bosses` |
| Body hitbox (touching = a hit) | 14.1 wide (HalfWidth 2.2), 7.7 back, 5.8 front, 25.6 tall | `Config.Bosses.List` (Hitbox x Scale) |
| Walk | 42 studs/s (players 32, max 40 with Speed upgrades); legs of up to ~2 s | `Config`, `BossService.nextLeg` |
| Targeting | the **nearest living player inside the zone's Bounds** (not only egg carriers - `docs/BOSSES.md` says "smells eggs", the code doesn't); 95% of legs head for them (Chase 0.95), stopping short | `BossService.run / nextLeg` |
| Attack | **Line (Fin Charge)**: Windup 1.0 s with a warning lane, charge **130 studs, 20 wide, at 150 studs/s** (~0.9 s), then **Dizzy 2 s**; every 2.8 s when a target is within **TriggerRange 60** | `Config.Bosses`, `BossService` |
| Where he can go | an axis-aligned box: the zone's `Bounds` shrunk by `Margin` (40 along / 10 across); **every goal is clamped to it** (a charge stops at its edge) | `BossService.clampToArea` |
| Patrol (no one near) | back and forth along the box's long axis inside a **±12-stud band round its middle** (`StayNearMiddle` default) | `BossService.nextLeg` |
| A hit | ragdoll 2.2 s, flung at 75 studs/s, 4 s safe, the boss ignores you 5 s; **all carried eggs drop** | `Config.Bosses`, `ZoneService.dropAll` |
| Dropped eggs | scatter 6-14 studs x (1 + 0.04 x eggs): **up to 20.7** with the 12-egg Diamond Briefcase; clamped 4 inside `Bounds`; land on the zone's `Floor` / `Path` parts (raycast); grabbable after 0.9 s, for 30 s | `ZoneService.dropAll`, `Config.Bosses` |
| Egg spawns | up to **14** at once on the zone's `EggSpots`, one more every 3-7 s; eggs are **bought** (BuyPrompt) | `Config.Zones.List`, `ZoneService` |
| Travel | arrive on the zone's `Arrival`; **no travel while carrying eggs** | `Config.Zones.Travel`, `TravelServer` |
| Safe zone | no script: "safe" = anywhere outside the bosses' boxes (+ their reach) | `BossService`, `Config` comments |
| Today's Ocean Shore | a 72 x 400 lane (`Bounds` -36..36, z -2138..-1738): his box is 52 x 320 | `Config.Zones.List` |

## 2. The layout (approved) + the detailed scenery
| Piece | Where (Blender x, y; Roblox z = -y) | Notes |
| --- | --- | --- |
| **Megalodon's box** (the dangerous sand) | x -120..120, y -100..110 (240 x 210) | one continuous, flat, studded sand surface (z 1): colour patches, sparse flat decor; no stairs, bridges, platforms or buildings |
| Sand plateau | ~276 x 246, a rounded organic outline + two lobes | 18 studs of sand past the box on the sides, 7-10 at the corners (all within his 17-stud reach); 8 shallow **shoreline inlets** with foam on the margin (flush, walk-through) |
| **Boss start pad** | (0, 10) | a ring of sunken flat stones flush with the sand |
| **Spawn** | (-169, -159): blue-and-white pad on a boardwalk off the SW lobe | **torches + rope rails**, barrels + crates at the landing; 77 studs out of his reach |
| **Escape portal** | (147, 147), NE lobe | a rock **arch planted on two craggy buttress legs**, a door-shaped purple vortex down to the ground (a level walk-in), runes, moss cap + vines, crystal keystone, crystals, coral, ferns, a studded stone base, stepping stones, two palms leaning over |
| Egg regions (28 candidate spots) | Palm Clearing (-82, 32) · Coral Flats (86, -18) · Shell Beach (4, -66) · Driftwood Dunes (-38, 82) · Shipwreck Shore (74, 76) | on the open sand inside his box; Shell Beach safer, Driftwood Dunes + Shipwreck Shore riskiest |
| **Cliff massifs** | a continuous wall round the outer ring | stacked-stone columns joined by connector blocks, grass-topped terraces in front, boulders at their feet; tallest NW (~40), N + W 27-34, E ~16, low S (~8) so the aerial sees in; moss caps with drips, vines, palms + bushes on top |
| **The high cascade** | (-178, 116), NW | ~38 studs in three steps from a notch in the tallest cliffs into a pool: foam bands, a foam landing, mist |
| Pools (6) | round the ring, in rock pockets | sand banks, foam on the water's edge, coral gardens (staghorn, brain, tube, fan, seaweed), shells, starfish, conches |
| Edge waterfalls (4) | W (175°, out under a small rock arch), E (22°), a **double fall** SE (317° + 326°) | pools spilling over the edge, foam at the lip, spray |
| Sea arch | (-16, 153), N rim | |
| Coastal cave | (-155, -51), W cliffs | a dark arched mouth (scenery: not enterable) |
| **Shipwreck** | (178, 18), E rocks | heeled over: keel, curved ribs (some snapped), hull planks with gaps, a broken deck, a tilted mast with a crow's nest, a **torn sail**, ropes, spilled barrels + crates |
| Vegetation | the ring + cliff tops | ~150 plants: palms (5 styles), broadleaf bushes, hibiscus, ferns, grass |
| Underside | | five big rock tiers, a brown dirt band + hanging roots under the grass rim, craggy faces, hanging rocks, vines |
| Sky | | the sea far below, drifting clouds, 8 floating islets (palm + bush on each) |

## 3. Gameplay checks (measured on the built geometry with the real numbers; `osv2_layout.json` → checks)
| # | Check | Result | Status |
| --- | --- | --- | --- |
| 1 | He can cover the whole dangerous area | 3233 / 3233 points of his box (4-stud grid) are open sand; all four corners on sand | **Geometry: yes.** Roblox: needs his arena box set + a wider idle patrol band (code) - **pending** |
| 2 | Charges have room | 896 / 896 sampled charges (16 directions from a 30-stud grid, 20-wide lanes, the real clamped path) run clear; 350 get the full 130, the rest stop at the box edge like the game | **Geometry: yes** |
| 3 | Warning lanes stay visible | nothing taller than 2.5 studs inside his box (the sand decor is at most 2.1); no particles or gulls over it | Geometry yes; the floor warning over the decor needs a playtest - **pending** |
| 4 | Room to dodge | 240 x 210; a 1.0 s windup lets a player at 32 studs/s move 32, 17 are needed | **Geometry: yes**; feel - **pending playtest** |
| 5 | No props block routes | spawn → portal reachable on level ground (flood fill on walkable cells); all scenery 18+ studs clear of his reach | **Yes** |
| 6 | Egg regions reachable | all 28 spots on open sand inside his box, 9+ apart, 22+ from his pad | **Yes** |
| 7 | Dropped eggs land on the island | spots are 24.2-68.5 studs from the sand edge vs the 20.7 max scatter | **Geometry: yes**; the sand must be `Floor` in Roblox - **pending** |
| 8 | Spawn + portal work | spawn 77 studs out of reach; the portal is a level walk-in | Layout yes; the home-with-eggs rule is not built - **pending** |
| 9 | Safe zone separated | the boardwalk + pad are out of reach; **no walkable route avoids his reach** | **Yes** |
| 10 | Size fits his body + attacks | 240 x 210 vs a 25.6-tall, 14-wide boss and a 130-stud charge | **Yes** |

## 4. Against the concept image
Same composition and the same ingredients: the boardwalk spawn with torches bottom-left, the purple portal in rocks
top-right, Megalodon centre on open studded sand, eggs in clusters across it, grey stacked-stone cliffs with green
caps, vines and palms all round (tallest at the back), a waterfall pouring from the high cliffs into a pool, more falls
off the edges (a double one front-right), turquoise pools with coral, an arch at the top, a wrecked ship on the right,
shoreline foam, a layered rock underside, the sea far below, floating islets and clouds. On purpose different: the
sand is bigger and flatter (his charges need it), the portal is level (no stairs), and the concept's water patches
inside the sand are shallow inlets on the margin (no hiding spots).

## 5. Style: classic Roblox studs, not LEGO
- Cohesive pieces: the sand is ONE slab, the island ONE body with five big rock tiers; cliffs are chunky faceted stone
  blocks in big stacks (no stacks of thin bricks, no thick seams); round things (trunks, rings, coral, eggs) are smooth
  Roblox-style shapes.
- Raised Roblox-shaped studs on the broad surfaces only: sand, sand patches, grass + moss tops, rock tops, the
  boardwalk, the spawn pad's white, the portal's stone base. **Unstudded:** water, foam, mist, falls, the portal's glow +
  vortex, palms, leaves, flowers, coral, shells, starfish, driftwood, natural soil (the dirt band).
- Detail comes from nature: no shops or buildings.

## 6. Asset catalog (all made in Blender scripts; new for v2)
| Piece | Function | Notes |
| --- | --- | --- |
| Cliff column (stacked stone, side ledges, moss cap + drips, vines, plants on top) | `osv2_detail.cliff_column` | the building block of every cliff, terrace, connector, pool rim and boulder |
| Palms: tall / lean / curve / short / twin | `osv2_detail.palm2` (+ `frond_leaflets`) | segmented ringed trunks, root flare, coconuts, leaflet fronds in two greens, young upright fronds, a dead hanging frond |
| Broadleaf bush, hibiscus, grass clump | `bush`, `hibiscus`, `grass_clump` | + `osv2_parts.fern_bush`, `tuft` |
| Coral: staghorn, fan, brain, tube; seaweed | `osv2_parts.coral / fan_coral`, `osv2_detail.brain_coral / tube_coral / seaweed` | |
| Shells, conch, starfish, sand dollar, pebbles, flat driftwood | `osv2_parts.shell / starfish / pebbles / driftwood`, `osv2_detail.conch / sand_dollar` | the sand's walk-through decor |
| Water: pools, shallows, foam outlines, cascade, edge falls | `osv2_detail.foam_outline / waterfall_tall / edge_fall`, `osv2_parts.waterfall` | smooth, animated in the ambience |
| Shipwreck + cargo | `osv2_detail.shipwreck2`, `barrel`, `crate`, `rope` | |
| Rock arch, cave mouth | `osv2_parts.rock_arch` + the build | |
| Spawn boardwalk, spawn pad, torches | `osv2_parts.spawn_dock / spawn_pad`, `osv2_detail.torch` | |
| Escape portal | `osv2_parts.escape_portal` | arch on buttresses, door-shaped vortex, runes, keystone, crystals |
| Boss start pad, egg spot markers, preview eggs | `osv2_parts.boss_pad / egg_marker / preview_egg` | eggs are previews only |
| Island body, sand plateau, underside tiers, dirt band + roots, islets, clouds | `osv2_build` + `../kit/hl_classic.ClassicMesh.slab / rock / beam / frond` | |
| Gulls | `osv2_ambience` | circling high round the edges |

## 7. Ambience + audio
### Visual (in the .blend: scrub the timeline; no preview clips - crnuch's call)
| Effect | How | Clear of his lanes? |
| --- | --- | --- |
| Palms, bushes, grass sway | WindSway on Vegetation | yes: all outside his reach |
| Pools, shallows, falls, foam, the far sea flow / ripple | animated water shaders (foam-white highlights) | the shallows are on the margin |
| Splashes + mist at the cascade landing; spray off the four edge falls | particles (small white cubes, soft mist) | yes |
| Sun sparkles over the six pools | particles | yes |
| Purple motes rising at the portal; the portal breathes | particles + emission driver | yes |
| Torches flicker (~1.35 Hz: nothing over 3 Hz) | emission driver | yes |
| Clouds drift; the islets bob | keyframes | yes |
| 6 gulls circle high round the edges | parented rings, looped | the rings sit round the edge, high up |
| Megalodon sways on his pad | keyframes (pivot at his feet) | his own idle |

### Audio (research only: nothing downloaded or listened to; every licence read on its page, 2026-10-19)
Tier 1 = Roblox's licensed library (the game's `Shared.Sfx` rule); Tier 2 = these CC0 picks.

| Layer | Tier 1 (Creator Store search) | Tier 2 pick (CC0, checked) |
| --- | --- | --- |
| Primary bed: gentle waves | "ocean waves", "beach ambience" | [Gentle Waves - Quiet Beach](https://freesound.org/people/amholma/sounds/376795/) (amholma, 1:41, 48 kHz stereo) |
| Seagulls | "seagulls" | [A quiet seaside seagulls distant](https://freesound.org/people/selcukartut/sounds/546565/) (selcukartut, 4:00) as a far bed; [Seagull Swarm at Port](https://freesound.org/people/Kinoton/sounds/468080/) (Kinoton, 1:50) to cut single calls |
| Gentle wind | "wind palm trees", "coastal wind" | [Soft Wind in the Trees](https://freesound.org/people/Borgory/sounds/751473/) (Borgory, 2:27) |
| Tropical birds | "tropical birds" | [Jungle Sounds Background Ambience 1](https://freesound.org/people/paulprit/sounds/724054/) (paulprit, 0:41: has insects + monkeys, keep low or trim to the birds) |
| Waterfalls (3D) | "waterfall" | [Waterfall Loop](https://freesound.org/people/kwahmah_02/sounds/274259/) (kwahmah_02, 1:10) for the cascade; [Ambiance_Waterfall_Loop_04](https://freesound.org/people/Nox_Sound/sounds/511075/) (Nox_Sound, 0:26) for the edge falls |
| Shoreline splashes | "waves rocks splash" | [Crashing Waves into Rocks 1](https://freesound.org/people/amholma/sounds/376799/) (amholma, 0:24) one-shots at the rocks; [Beach Waves Close](https://freesound.org/people/DylanTheFish/sounds/463249/) (DylanTheFish, 3:02) by the inlets |
| Megalodon | his own sounds (BossService) | - |

Not implemented in Roblox (the brief: not yet).

## 8. Roblox integration considerations (when crnuch says go)
1. **His arena box** must be set directly (a per-boss `Arena`), not derived from `Bounds` - `Margin` (README → Notes for Stage 7).
2. **Idle patrol:** widen `StayNearMiddle` (or a new island patrol) so he uses the whole 240 x 210 when no one is near.
3. **The zone's `Bounds`** (targeting + drop clamping) should cover the sand but not the spawn boardwalk.
4. **Floor:** every walkable sand piece (plateau, patches, the inlets' floor) in the zone's `Floor` folder, or dropped eggs land at y 0.
5. **EggSpots** from `osv2_layout.json` (28 candidate spots, Roblox x/z given); MaxEggs stays 14.
6. **Arrival** on the spawn pad; **the escape portal** needs the new home-with-eggs rule (today travel is blocked while carrying).
7. **Collision off** for decor (shells, starfish, pebbles, tufts, coral, driftwood, foam, mist, fronds, flowers); on for
   the ground, rocks, cliffs, the wreck's hull, the boardwalk, the portal frame.
8. **An invisible rim** where the sand meets a drop (the spawn lobe, the portal lobe) so players don't walk off.
9. **Studs:** the raised-stud tiles (`StarterPlayerScripts.Studs`, tag `StudTop`) on the studded looks only (§5).
10. **Water** as smooth parts (glass-like, a moving texture), no studs; foam + mist as decals / particles.
11. **Parts vs meshes** is still open (crnuch's call pending): `hl_export` records bricks; this island's smooth shapes
    (cylinders, balls, angled beams, fronds) suit MeshParts better.
12. **Lighting:** a bright tropical Lighting preset for the zone (a client-side swap, as the other islands' notes say).
13. **Streaming + LOD:** cliffs, vegetation, the wreck and the falls as separate models; far islets + clouds client-only.
14. **Audio** from §7, as 3D sounds at the falls / rocks and 2D beds.

## 9. For approval (the brief's questions)
- **How close to the concept:** same composition and the same features (§4); the bigger, flatter sand and the level
  portal are deliberate gameplay changes.
- **Classic studs:** studs on broad surfaces only, cohesive terrain, no stacked-brick look (§5).
- **Nature instead of buildings:** the only made things are the boardwalk, the torches, the portal and the wreck.
- **Interesting, not cluttered:** the richness lives in the ring (cliffs, pools, falls, wreck, palms); the sand has
  colour patches, inlets and sparse flat decor, so it never reads as an empty baseplate, yet nothing blocks a charge.
- **Megalodon's movement:** a 240 x 210 open box, 896/896 charges clear, no obstacle over 2.5 studs, scenery 18+ studs
  out of reach, no safe bypass (§3).
- **Eggs:** five regions across the box from safer (Shell Beach) to risky (Driftwood Dunes, Shipwreck Shore), 28 spots;
  drops always land on sand.
- **Still to refine:** §10.

## 10. Known weaknesses (honest)
- The cliff blocks are faceted boxes: the concept's rock faces have more chiselled detail (cracks, chips).
- The sand centre is open on purpose; more variety there would risk his lanes.
- The vortex's half-disc shows faint radial seams up close.
- The preview eggs are placeholders (the game draws its own Ocean eggs).
- Not proven in Roblox: §3's pending rows.
