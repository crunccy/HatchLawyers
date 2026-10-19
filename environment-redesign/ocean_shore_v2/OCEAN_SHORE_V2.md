# Ocean Shore v2 — LAYOUT for approval (2026-10-19)

crnuch's brief: redesign Ocean Shore from the approved concept image (`../references/ocean_shore_concept.webp`) as a
natural tropical wilderness built around the real Megalodon mechanics, in **classic Roblox studs, not LEGO**. This is
the first checkpoint: the **audit + a revised layout**, rendered for approval **before** the detailed modeling. Nothing
in Studio was touched. v1 (`../ocean_shore/`, mr.robe's build) is untouched as the backup.
```bash
Blender -b --python environment-redesign/ocean_shore_v2/osv2_build.py              # .blend + layout JSON + checks + renders
Blender -b --python environment-redesign/ocean_shore_v2/osv2_build.py -- norender  # .blend + JSON + checks only (~12 s)
```

| Deliverable (layout stage) | File |
| --- | --- |
| Editable .blend (layout blockout, studded) | `ocean_shore_v2.blend` |
| Aerial beauty render (the concept's angle) | `renders/osv2_aerial.jpg` |
| True top-down render | `renders/osv2_topdown.jpg` |
| Labelled gameplay diagram | `renders/osv2_gameplay_diagram.jpg` |
| Player-level spawn view | `renders/osv2_ground_spawn.jpg` |
| Player-level egg terrain view | `renders/osv2_ground_eggs.jpg` |
| Boss-level charge-space view | `renders/osv2_boss_view.jpg` |
| Escape portal view | `renders/osv2_ground_portal.jpg` |
| Positions (Blender + Roblox x/z), boss box, egg regions + 28 candidate spots, the checks | `osv2_layout.json` |
| Sources | `osv2_build.py` (layout + checks), `osv2_parts.py` (pieces), `../kit/hl_classic.py` (classic-Roblox shapes) |

## 1. Audit: what the game actually does (code is the authority)
| What | Value | Source |
| --- | --- | --- |
| Megalodon size | Scale 3.2: **25.6 tall, 14.8 wide, 16.8 deep** | `tools/zones/bosses.json` x `Config.Bosses` |
| Body hitbox (touching = a hit) | 14.1 wide (HalfWidth 2.2), 7.7 back, 5.8 front, 25.6 tall | `Config.Bosses.List` (Hitbox x Scale) |
| Walk | 42 studs/s (players 32, max 40 with Speed upgrades); legs of up to ~2 s | `Config`, `BossService.nextLeg` |
| Targeting | the **nearest living player inside the zone's Bounds** (not only egg carriers - `docs/BOSSES.md` says "smells eggs", the code doesn't); 95% of legs head for them (Chase 0.95), stopping short | `BossService.run / nextLeg` |
| Attack | **Line (Fin Charge)**: Windup 1.0 s with a warning lane, charge **130 studs, 20 wide, at 150 studs/s** (~0.9 s), then **Dizzy 2 s**; every 2.8 s when a target is within **TriggerRange 60** | `Config.Bosses`, `BossService` |
| Where he can go | an axis-aligned box: the zone's `Bounds` shrunk by `Margin` (40 along / 10 across). **Every goal is clamped to it** (a charge stops at its edge) | `BossService.clampToArea` |
| Patrol (no one near) | back and forth along the box's long axis inside a **±12-stud band round its middle** (`StayNearMiddle` default) | `BossService.nextLeg` |
| A hit | ragdoll 2.2 s, flung at 75 studs/s, 4 s safe, the boss ignores you 5 s; **all carried eggs drop** | `Config.Bosses`, `ZoneService.dropAll` |
| Dropped eggs | scatter 6-14 studs x (1 + 0.04 x eggs): **up to 20.7 studs** with the 12-egg Diamond Briefcase; clamped 4 studs inside `Bounds`; land on the zone's `Floor` / `Path` parts (raycast); grabbable after 0.9 s, for 30 s | `ZoneService.dropAll`, `Config.Bosses` |
| Egg spawns | up to **14** at once on the zone's `EggSpots` parts, one more every 3-7 s; eggs are **bought** (BuyPrompt) | `Config.Zones.List`, `ZoneService` |
| Travel | arrive on the zone's `Arrival`; **no travel while carrying eggs** (the walk home past the boss is the game) | `Config.Zones.Travel`, `TravelServer` |
| Safe zone | no script: "safe" = anywhere outside the bosses' boxes (+ their reach) | `BossService`, `Config` comments |
| Today's Ocean Shore | a 72 x 400 lane (`Bounds` -36..36, z -2138..-1738): his box is 52 x 320 | `Config.Zones.List` |
| v1 island (mr.robe, earlier today) | a beach town: plaza, shops, hotel, lighthouse, a 72 x 148 dock arena | `../ocean_shore/OCEAN_SHORE.md` |

**Integration facts this layout depends on** (Stage 7, code changes later, not now):
- his box must be set directly for the island (a per-boss arena), not derived from `Bounds` - `Margin`;
- his idle patrol band (`StayNearMiddle` 12) is made for a lane: on a 240 x 210 island it should be widened (he
  still chases anyone near 95% of the time, so this only affects idle wandering);
- all walkable sand must be `Floor` (dropped eggs raycast onto Floor / Path only);
- "home WITH eggs" through the escape portal is a new rule (today travel is blocked while carrying).

## 2. The layout (diagram: `renders/osv2_gameplay_diagram.jpg`)
```
SPAWN (SW, on the boardwalk) ──> the open sand (Megalodon's box, 240 x 210) ──> ESCAPE PORTAL (NE, level)
   egg regions all over the sand · cliffs / pools / waterfalls / palms / arch / cave / shipwreck all round it
```
| Piece | Where (Blender x, y; Roblox z = -y) | Notes |
| --- | --- | --- |
| **Megalodon's box** (the dangerous sand) | x -120..120, y -100..110 (240 x 210) | one continuous, flat, studded sand surface (z 1); no stairs, bridges, platforms or buildings in it |
| Sand plateau | ~276 x 246, a rounded organic outline + two lobes | 18 studs of sand past the box on the sides, 7-10 at the corners: all within his reach (17 = half the lane + half his body), so no comfortable sideline |
| **Boss start pad** | (0, 10) | a subtle ring of sunken flat stones flush with the sand: a landmark, not an arena |
| **Spawn** | (-169, -159): a blue-and-white pad on a lantern-lit boardwalk off the SW lobe | 77 studs outside the box: out of reach; the walk from it goes straight onto the sand |
| **Escape portal** | (147, 147): NE lobe, a natural rock ARCH planted on two craggy buttress legs (revised after crnuch's note: "the portal frame looks slightly detached"), a purple vortex down to the ground, glowing runes, a moss cap with vines, a crystal keystone, crystals + coral + ferns at its feet, a studded stone base with stepping stones, two palms leaning over | flush with the sand (no stairs); 45 studs outside the box - the last ~15 studs of the walk are inside his 60-stud trigger, so the escape is threatened but never camped |
| Egg regions (28 candidate spots) | Palm Clearing (-82, 32) · Coral Flats (86, -18) · Shell Beach (4, -66) · Driftwood Dunes (-38, 82) · Shipwreck Shore (74, 76) | all on the open sand inside his box; Shell Beach (near spawn) is the safer start, Driftwood Dunes (his patrol line) + Shipwreck Shore (on the way out) the riskiest |
| Scenery ring (not playable) | between the sand and the rim, 18+ studs clear of his reach everywhere | chunky studded rock cliffs (taller N + W), five turquoise rock pools, four waterfalls off the edge, a sea arch (N), a coastal cave (W), a beached shipwreck (E), ~50 palms in three shapes, ferns, coral |
| Underside | five big cohesive rock tiers, hanging rocks, craggy rim faces, vines | |

## 3. Gameplay checks (measured on the built geometry with the real numbers; `osv2_layout.json` → checks)
| # | Check | Result | Status |
| --- | --- | --- | --- |
| 1 | He can cover the whole dangerous area | 3233 / 3233 points of his box (4-stud grid) are open sand; all four corners on sand | **Geometry: yes.** Roblox: needs his arena box set + a wider idle patrol band (code) - **pending** |
| 2 | Charges have room | 896 / 896 sampled charges (16 directions from a 30-stud grid, 20-wide lanes, the real clamped path) run clear; 350 get the full 130 studs, the rest stop at the box edge like the game does | **Geometry: yes** |
| 3 | Warning lanes stay visible | nothing taller than 2.5 studs inside his box; the sand decor is at most 2.1 tall, sparse, walk-through | Geometry yes; how the client's floor warning reads over the decor needs a playtest - **pending** |
| 4 | Room to dodge | the box is 240 x 210; a windup (1.0 s) lets a player at 32 studs/s move 32 studs, 17 are needed to leave the lane + body | **Geometry: yes**; feel - **pending playtest** |
| 5 | No props block routes | spawn → portal reachable on level ground (flood fill on walkable cells) | **Yes** |
| 6 | Egg regions reachable | all 28 spots on open sand inside his box, 9+ studs apart, 22+ from his start pad | **Yes** |
| 7 | Dropped eggs land on the island | spots are 26.5-70.8 studs from the sand edge vs the 20.7-stud max scatter | **Geometry: yes**; in Roblox the sand must be `Floor` - **pending** |
| 8 | Spawn + portal work | spawn out of reach (77 > 17); portal reachable, level | Layout yes; the portal's home-with-eggs rule is not built - **pending** |
| 9 | Safe zone separated | spawn boardwalk + pad outside his reach; **no walkable route avoids his reach** (flood fill outside box + 17 finds no way to the portal) | **Yes** |
| 10 | Size fits his body + attacks | 240 x 210 box vs a 25.6-tall, 14-wide boss and a 130-stud charge | **Yes** |

Not provable in Blender (marked pending above): his real wandering on a box this shape, the warning decal's
readability, the drop raycasts, the portal rule, phone performance.

## 4. Against the concept image
Same composition: spawn on a boardwalk bottom-left, the portal top-right in rocks, Megalodon centre on open studded
sand, three-plus egg clusters on the sand, grey stacked-rock cliffs with green tops and palms round the edge,
waterfalls spilling off the sides, turquoise pools, an arch at the top, a shipwreck on the right, a layered rock
underside, the sea far below. Differences: the playable sand is bigger and flatter than the picture's (the boss
needs it); the concept's portal stairs are gone (the walk-in is level); its shallow water patches inside the sand are
flush colour patches here (no hidden safe spots).

## 5. Style: classic Roblox studs, not LEGO
- The sand is ONE cohesive slab (a chamfered organic outline), the island ONE body with five big rock tiers; cliffs
  are chunky faceted rock blocks (jittered corners), not stacks of thin bricks; no thick seams.
- Raised Roblox-shaped studs (the stud pass) on the broad surfaces only: sand, sand patches, grass and moss tops, rock
  tops, the boardwalk, the spawn pad's white. **Unstudded:** water, waterfalls, the portal's glow + vortex, palm
  fronds, ferns, coral, shells, starfish, driftwood.
- Detail comes from nature: rocks, palms, pools, waterfalls, coral, shells, driftwood. No shops or buildings.

## 6. After approval: the detailed pass (not started)
- Models: better palms (more variants, frond detail, coconuts), sculpted cliff faces + terraces, coral clusters,
  shells / starfish variety, a detailed shipwreck, the cave interior mouth, waterfalls with foam + spray, island
  underside detail, the portal's rock frame.
- Ambience (in the .blend, no clips): waves on the far sea, waterfall flow, palm sway, drifting clouds, splashes,
  mist, sun sparkle, particles - none over the warning lanes.
- Audio research (licence-checked; ocean waves, gulls, wind, tropical birds, waterfalls, splashes).
- The asset catalog + the Roblox integration list (preliminary list: §1's integration facts; the sand as Floor;
  decor CanCollide off; studs as StudTop tiles on the studded looks; water as smooth parts; a low invisible rim on
  the sand edge where it meets a drop; EggSpots from `osv2_layout.json`; parts vs meshes per crnuch's decision).

## 7. Known weaknesses (layout stage)
- Blockout-level models: palms, rocks and the wreck are first-pass shapes; the detail comes after approval.
- The sand centre is deliberately open (his charges need it); its interest is colour patches, flush stones and sparse
  small decor - more variation is a detailed-pass item.
- His idle patrol on a box this wide needs the code change in §1 to use the whole sand when no one is near.
