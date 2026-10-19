# Central hub — Stage 2 blockout (2026-10-18) · APPROVED by crnuch 2026-10-18

A dimensionally accurate blockout: colour-coded volumes, no final art and no studs yet. It follows crnuch's approved
reference: a round floating island; the spawn plaza with a statue fountain in the middle; a main avenue up to the
Law License Building; Travel Portal, Egg Incubator, Shop and Upgrades on an inner ring; firms on the outer ring;
waterfalls off the cliffs. It uses the game's real numbers (`../../01_AUDIT.md`).

| File | What |
| --- | --- |
| `hub_blockout.py` | The source: rebuilds the `.blend` and every render (`Blender -b --python hub_blockout.py`) |
| `central_hub_blockout.blend` | Editable Blender file. Collections: `Central_Hub` (Hub_Island / Plaza / Roads / Lots / Firms_DYNAMIC / Services / Landscaping / Water / Labels), the six island collections (empty), `Shared_Props`, `Vegetation`, `Buildings`, `Environmental_Effects`, `Lighting`, `Presentation` |
| `hub_layout.json` | Every position below, in Roblox coordinates |
| `renders/hub_blockout_aerial.jpg` | Aerial, the reference's 3/4 view, every firm at **maximum** size |
| `renders/hub_blockout_ground_plaza.jpg` | From the spawn plaza towards the License Building, player-eye height |
| `renders/hub_blockout_layout_topdown.jpg` | Labelled top-down plan with a 100-stud scale bar and north arrow |

Coordinates: 1 stud = 1 Blender m. **North = up the plan = Roblox −Z.** Roblox (x, z) = (Blender x, −Blender y).
Angles below are counter-clockwise from east.

## Rings (radius from the plaza centre, studs)
| Ring | Radius | What |
| --- | --- | --- |
| Spawn plaza | 0–58 | Statue fountain (basin r 15–18), radial paving, 12 benches, 12 lamps; spawn pad at (0, 36) south of the fountain |
| Inner ring road | 62–74 | Round the plaza; white curbs |
| Services ring | ~74–130 | Buildings on r 102: Portal, Egg Incubator, Shop, Upgrades, Mutation Machine, Big Case belt; 8 orange spoke paths between them |
| Outer ring road | 130–142 | Every firm opens onto it; street lamps, a hedge line |
| Firm lots | 148–293 | 8 lots of **56 × 145**, each centred on its angle and facing the centre |
| Cliff margin | 293–317+ | ≥ 23 studs between any lot corner and the edge (island radius 317–347, irregular) |

Main avenue: 22 wide, north–south through the plaza. North end = the License Building (r 150–192), south end = the
island edge and the bridge to the Arcade Pier.

## The 8 firm lots
Street edge = the lot's front middle (the firm's entrance side). Yaw = the plot model's Y rotation, so its local −Z
(front) faces the hub centre.

| Plot | Angle | Street edge (x, z) | Back edge (x, z) | Yaw |
| --- | --- | --- | --- | --- |
| Plot1 | 60° (NE) | (74.0, −128.2) | (146.5, −253.7) | 150° |
| Plot2 | 20° (E-NE) | (139.1, −50.6) | (275.3, −100.2) | 110° |
| Plot3 | −20° (E-SE) | (139.1, 50.6) | (275.3, 100.2) | 70° |
| Plot4 | −60° (SE) | (74.0, 128.2) | (146.5, 253.7) | 30° |
| Plot5 | 240° (SW) | (−74.0, 128.2) | (−146.5, 253.7) | 330° |
| Plot6 | 200° (W-SW) | (−139.1, 50.6) | (−275.3, 100.2) | 290° |
| Plot7 | 160° (W-NW) | (−139.1, −50.6) | (−275.3, −100.2) | 250° |
| Plot8 | 120° (NW) | (−74.0, −128.2) | (−146.5, −253.7) | 210° |

- **Spacing:** at the street edge, neighbouring lots are 45 studs apart (today: 4). The gap widens outward to
  ~144 at the back.
- **North and south gaps** of 60° are left open for the License Building and the avenue / Arcade bridge.
- **Each lot holds the biggest firm the game builds,** drawn as a blue-grey envelope:
  - porch, lobby podium (48 × 21, 21 tall), office hall (48 × 114, ~10 tall)
  - Supreme Tower (40 × 17 to 129), gold crown (to 135), spire (to 161)
  - The envelope is DYNAMIC: firms stay player-built (FirmBuilder); the final map ships only the lot foundation,
    its edging, the forecourt and the landscaping round it.

## Services
| Service | Centre (x, z) | Ring / angle | Today |
| --- | --- | --- | --- |
| Law License Building | (0, −172) | r 172 / 90° (N) | `Zones.LicenseOffice` (License upgrades) |
| Travel Portal | (−72.1, −72.1) | r 102 / 135° (NW) | `Hub.TravelPortal` |
| Egg Incubator (landmark) | (72.1, −72.1) | r 102 / 45° (NE) | none (eggs hatch in firms) |
| Shop | (−72.1, 72.1) | r 102 / 225° (SW) | `Hub.ShopStall` |
| Upgrades (Carry + Speed) | (72.1, 72.1) | r 102 / 315° (SE) | at the License Office today |
| Mutation Machine | (−102, 0) | r 102 / 180° (W) | `Hub.MergeMachine` |
| Big Case belt + 2 minigame pads | (102, 0) | r 102 / 0° (E) | `Hub.BigCaseBelt` + `SpecialSpots` |
| Leaderboards (2 boards) | (±22, 88) | flanking the south avenue | `Hub.Leaderboards` |
| Arcade Pier | (0, ~473) | bridge off the south edge | `Workspace.ArcadePier` (mr.robe's claim) |

Travel Portal blockout: a 38-wide raised platform with steps facing the plaza, an upright ring (r 13) and a glowing
field. It is the brightest object on the island by design.

## What the renders show (honest read)
1. **Eight maxed Supreme Towers form a ring of 161-stud skyscrapers** round the services. From the aerial angle
   they hide part of the plaza; from the plaza they fill the sky behind the License Building. This only happens
   on a full server of Rebirth players, but it's the worst case the hub must survive. Most firms are 10–80 studs
   tall.
2. The **wedges between lots are large** and filled with blockout trees (random placement). In detailed modeling
   they become designed spaces: gardens, ponds, the waterfall sources, small plazas, benches. Stage 3 work.
3. The island is ~664 across (today's ground is 528 × 336). From the plaza centre to the farthest firm door is
   ~150 studs, ~5 s at the base walk speed of 32.
4. Not in the blockout:
   - final architecture
   - studs
   - detailed cliffs (the five rock tiers + hanging spikes are placeholders)
   - lighting design
   - ambience

## Decisions needed before Stage 3
1. **Firm orientation.** (a) as built: entrances face the centre, as in the reference, and the towers ring the
   services. (b) Flipped: entrances face a road along the cliff edge, so the towers form a skyline at the rim and
   the middle opens up, but the walk from the plaza to your firm gets longer and it departs from the reference.
   **Recommend (a).**
2. **Egg Incubator:** a hub landmark only (recommended: hatching stays per-firm), or a working hatch spot (a
   gameplay change for later)?
3. **License vs Upgrades:** split as in the reference (License Building = licenses; Upgrades = Carry + Speed)?
   Recommended; at integration it's either a folder move or a small `ZoneService.hookPrompts` change.
4. **Return trip.** Today you can't travel while carrying eggs, and separate islands have no road home.
   Proposal for the egg islands (Stage 5, nothing coded):
   - each island has an **arrival pad** at one end and a **return portal** past its egg fields
   - the route from the fields to the return portal crosses the **boss arena**, so carrying eggs out still means
     getting past the boss
   - the return portal sends a carrying player home to their firm
   - code change later: allow "Home" from a return portal while carrying
5. **Arcade Pier:** keep it as a bridge-linked pier off the south edge (mr.robe's booths go on it)?
6. Please save the reference image(s) into `environment-redesign/references/`.

## crnuch's decisions (2026-10-18, binding)
1. Firms face the centre (layout as built).
2. The hub Egg Incubator is a **landmark only**: hatching stays in each firm's two incubators.
3. License and Upgrades are **split** as in the reference: the Law License Building sells licenses; Upgrades sells
   Carry + Speed.
4. Each egg island gets a **return portal past its boss**: carrying eggs out still means getting past the boss.
5. The Arcade Pier stays a bridge-linked pier off the south edge.
