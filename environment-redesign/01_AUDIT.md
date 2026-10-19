# Stage 1 — Repository audit (2026-10-18)

What the world redesign has to respect, checked against the code and the live place. Every number below names
its source. **No Studio, gameplay code or map was changed** for this audit. The live place was only read: Edit-mode
queries, plus one short playtest to measure a real expanded firm. Like any playtest, that one loaded and autosaved
crnuch's normal save.

Live scripts are read from `studio/` (the snapshot of the place); `src/` holds working copies.

## Tools
| Tool | Status |
| --- | --- |
| Blender | **5.2.2 LTS** at `/Applications/Blender.app`, runs headless (`-b --python`). Used for everything here. The blender-mcp add-on wasn't connected this session and wasn't needed. |
| Git LFS | **Not installed.** The blockout `.blend` is 0.5 MB and renders are JPEG (~0.9 MB total), fine in plain git. Before detailed modeling grows a `.blend` past ~20 MB, both machines need `git lfs install` and `git lfs track "*.blend"` (a team decision: mr.robe's clone needs it too). Fallback: keep `.blend`s out of git and regenerate them from the `.py` scripts, which are the source. |
| Reference art | crnuch sent one ChatGPT "Map Layout Overview" image in chat (central hub + six egg-world thumbnails + travel menu). It isn't saved in the repo yet: put it in `environment-redesign/references/`. Older references: `references/*.webp`. |

## 1. Player plots — 8
- `Workspace.Plots.Plot1`–`Plot8` (live, Edit mode), each a `Base` part **56 × 0.96 × 56**.
- Today they're two rows of four along `Hub.Street` (440 × 34 along x at z = 0), x ±94…±210, z ±17…±73, with
  **4-stud gaps** between neighbours. Front / door = the plot's local −Z, facing the street.
- `PlotService.sortedPlots` fills the plots nearest the plaza first.

## 2. Largest possible firm
| | Value | Source |
| --- | --- | --- |
| Width | 48 between walls (cornice ±24.6); **53.0 measured** with outside dressing | `FirmBuilder.WIDTH`, live measurement |
| Depth | porch 6 + lobby 21 + 10 office segments × 11 + 3 = **~140–141 from the street edge** (it hangs ~85 studs past today's 56-deep Base) | `FirmBuilder.WAIT_DEPTH/SEG_DEPTH/depth`, `Config.Firm.MaxSegments = 10`; measured 9 segments + 1 locked = same depth |
| Height | Supreme Tower (stage 6, after Rebirth): crown at 133.6, **spire tip ~161** above the plot | `FirmStages` FRONTS[6] (`T1 = 2F + 0.45 + 108`, spire `T1 + 32.2`, F = 9.6) + `FLOOR_H 1.5` |
| | Corporate HQ (stage 5): **79.5 measured** including the roof hologram | live (crnuch's firm, 9 segments) |
| Uncertain | The Supreme Tower's gold hologram stands on the roof, and its exact top wasn't measured: **reserve 180 studs** of clear sky over each lot. | `FirmFeatures` hologram |

- The 158-deep live measurement included `DevCoin1/2`: Studio-only test pickups behind the firm
  (`ServerScriptService.Dev.DevCoinPickup`). They aren't part of the firm.
- Firm stages: Dingy Shack → Storefront Practice → Main Street Firm → Glass Office → Corporate HQ (by office
  segments 4–9) → Supreme Tower (Rebirth level, `Config.Prestige.TowerLevel`).
- Inside / on each firm (dynamic, built per player):
  - the lobby with **2 incubators**
  - offices with desks, lawyers and clients
  - upstairs rooms (`FloorRooms`)
  - buyable areas sold from pads on the lawn in front (`FirmFeatures`, `AreaPad_*`)
  - showcase pedestals and an elevator
  - the roof hologram (stage 5+)
- **Integration note:** `FirmBuilder.frame` places the firm from `Base.Size.Z / 2`, so a lot made 145 deep must
  keep a 56-deep `Base` at its street edge, or that one line changes.

## 3. The current hub (live bounding boxes, Roblox studs)
| Piece | Where |
| --- | --- |
| `Hub.Plaza` | 160 × 160 at the origin; `EggFountain` (36 across) in the middle; `PlazaPlanter`, `PlazaBench`, `Lamps`, `Trees` |
| `Hub.ShopStall` + `ShopSpot` | x −38…−21, z −38…−21 |
| `Hub.MergeMachine` (Mutation Machine) + spot | x 23…40, z −40…−23 |
| `Hub.Leaderboards` | z 28…45 |
| `Hub.TravelPortal` | x 37…67, z −71…−41 (30 × 30 × 30) |
| `Hub.Gates` | the lane entrance on the plaza's south edge (z −84…−88) |
| `Zones.LicenseOffice` | x −62…−40, z −70…−54: License, Carry and Speed upgrades |
| `Hub.CaseTerrace`, `BigCaseBelt`, `SpecialSpots` | z 88…165: the Big Case belt + Gavel Bonk / Lucky Briefcase pads |
| `Hub.BoardwalkGate`, `Workspace.ArcadePier` | z 82…89; the pier z 160…298 (mr.robe's Arcade, under an active claim) |
| `Ground`, `Shrubbery`, `IslandDecor`, `IslandEdge`, `Baseplate` | 528 × 336 ground, beach and docks, a 2048 baseplate below |

## 4. Spawning
`Workspace.HubSpawn` (12 × 12 at the origin) is where a character first appears. On join `PlotService` gives the
player a plot and moves them to their firm's `SpawnPoint`, on every respawn too. So in practice **players spawn at
their own firm**, and the plaza spawn is only the first frame.

## 5. Egg collection (`Server.ZoneService`, `Config.Zones`)
- Each zone's `EggSpots` hold up to 14 eggs, with a new one 3–7 s after one is bought.
- 6 % are **golden**: 5× the price, luckier, 60 s lifetime, announced to the whole server.
- A `BuyPrompt` costs coins and puts the egg in the player's arms, up to the **Carry** level's max (1 / 3 / 5 / 8 / 12
  by briefcase). Carried eggs are saved.
- Eggs **hatch only in the player's own firm**, at its two incubators (`EggApi "hatch"`).

## 6. Law Licenses
- `Config.Zones.License`: Bronze 5e6, Silver 1e8, Gold 2e9, Platinum 4e10, Diamond 1e12.
- Level n opens every zone with `License ≤ n`. Briefcase Bay is free (License 0).
- Sold at the License Office (`UpgradePrompt`, attribute `Upgrade = "License"`) and at each gate's `LicensePrompt`.
- The server refuses egg sales in an unlicensed zone. Rebirth resets the License.
- **Integration note:** `ZoneService.hookPrompts` only finds Upgrade / License prompts under `Workspace.Zones`, once
  at startup. Moving them into hub buildings needs that folder layout kept, or a small code change.

## 7. Bosses (`Server.BossService`, `Config.Bosses`, docs/BOSSES.md)
| Zone | Boss | Difficulty |
| --- | --- | --- |
| Briefcase Bay | The Senior Partner | Easy |
| Pet Park | Barrister Bulldog | Easy |
| Brainrot | Judge Martello | Medium |
| Food Court | Prosecutor Big Cheese | Medium |
| Ocean Shore | Magistrate Megalodon | Hard |
| Space Base | Chief Justice Eclipse | Extreme |

- Each boss roams its zone's `Bounds` rectangle (Margin 40 / 10) and attacks a player within 60 studs.
- Every attack has a windup warning first: Cone, Ring, Slam, Line or Pull.
- Touching the hitbox is a hit too. A hit ragdolls the player for 2.2 s and **knocks out every carried egg** as loose
  eggs anyone can grab (30 s). A hit player is then safe for 4 s.
- Bosses are drawn on each client from `ReplicatedStorage.BossStates`, so the server never moves parts.
- **Integration note:** each island will need its own `Bounds`.

## 8. Carrying eggs home
- Carried eggs show in the arms (`CarryPose`), with the briefcase on the back.
- **Travel is blocked while carrying** (`Config.Zones.Travel.BlockWhileCarrying`): "the walk home past the bosses is
  the game".
- Today the six zones are 72 × 400 segments of one walled lane south of the plaza. The walk home goes back north
  through every earlier zone (and its boss), through the plaza, to the firm.

## 9. Travel (`TravelServer`, `StarterPlayerScripts.Travel`, `Shared.TravelFx`)
- One portal at the hub plus a travel map: `Remotes.Travel("Home" | zoneId)`.
- The server checks the zone exists, the License, that the player isn't carrying, and a 3 s cooldown.
- The player lands on the zone's `Arrival` spot or the firm's `SpawnPoint`, after streaming the destination in.
- Each destination has its own travel animation.

## 10. Dynamic vs permanent
| Dynamic: built or moved by scripts (keep out of permanent scenery) | Permanent: what the redesign replaces |
| --- | --- |
| firms and everything in them, the `LotSign` on empty plots, eggs on spots, loose eggs, carried eggs / briefcases, bosses (client-drawn), Big Case belt clients, walking clients, the raised-stud layer (`StarterPlayerScripts.Studs`), hub client strollers / gulls (`WorldLife`) | hub ground, plaza, roads, trees and decor, service buildings, zones (floors, walls, decor, gates), island edge, sky |

## 11. Reusable assets (all Blender → JSON → Lua Part pipelines, `tools/`)
| Asset | Script |
| --- | --- |
| Egg fountain, boardwalk gate | `tools/blender/hub_landmarks.py` |
| Travel portal | `tools/blender/travel_portal.py` |
| Zone decor library | `tools/blender/zone_decor.py` |
| Island edge (beach, docks, boats) | `tools/blender/island_edge.py` |
| Arcade pier | `tools/blender/arcade_pier.py` |
| Lane pillars | `tools/blender/lane_pillar.py` |
| Upstairs rooms | `tools/blender/floor_rooms.py` |
| Bosses | `tools/blender/bosses.py` |
| Briefcases | `tools/blender/briefcases.py` |
| Eggs and incubator | `tools/blender/eggs_v5.py` + `incubator.py` |
| Firm kit | `tools/firm_kit.py`, `tools/firm_pieces.py` |
| Character kit | `tools/blender/brickkit.py` |
| **Raised studs** | `tools/blender/stud_tiles.py` |

## 12. Art rules that bind the redesign
- **Studded brick, real raised studs.** 1-stud pitch, shaped like Roblox's own rounded-square stud
  (docs/ART_STYLE_STUDS.md; crnuch's calls 2026-10-18). Blockouts skip studs; final models carry them.
- Palette, fonts and sign styles: CLAUDE.md "Art direction".
- Fictional characters only.
- No words over the Manager's head.
- Everything modeled in Blender.

## Uncertain (provisional until checked)
1. The Supreme Tower hologram's height: 180 studs reserved.
2. Whether the hub **Egg Incubator** in the reference is a landmark or a working hatch spot. Today hatching is
   per-firm, so the blockout treats it as a landmark.
3. Splitting the reference's **Law License Building** (licenses) from **Upgrades** (Carry + Speed): one office today.
4. How the **trip home** works between separate islands while travel is blocked when carrying (see the hub layout
   doc, "Return trip").
5. The Arcade Pier's booth layout belongs to mr.robe's active claim; it's kept as a pier off the hub's edge.
