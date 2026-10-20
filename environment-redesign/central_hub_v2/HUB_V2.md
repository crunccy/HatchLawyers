# Central Hub v2 (2026-10-20, mr.robe's session) · waiting for crnuch's approval

The main island redone to the **v2 standard** of the islands (crnuch's Ocean Shore v2 benchmark: classic Roblox studs,
not LEGO), on the user's call on mr.robe's PC ("also change the main island to v2"). crnuch's **approved hub layout is
kept exactly** (`../central_hub/blockout/LAYOUT.md` + his 5 decisions; the Stage 3 build `../central_hub/hub_build.py` and
its buildings in `../central_hub/hub_parts.py`): the spawn plaza + statue fountain, the inner ring road, the services
ring (Travel Portal, Egg Incubator, Shop, Upgrades, Mutation Machine, Big Case Terrace, Leaderboards), the outer ring
street, the 8 firm lots, the Law License Building, the avenue, the gardens, the waterfalls, the Arcade Pier bridge.
v1 (`../central_hub/`) is untouched as the backup.
```bash
Blender -b --python environment-redesign/central_hub_v2/hubv2_build.py      # .blend + layout JSON + renders
```

## What changed from v1 (the v2 standard)
| | v1 (Stage 3) | v2 |
| --- | --- | --- |
| Meshes | voxel kit: every round thing a stack of studded bricks | `hl_classic.ClassicMesh`: real cylinders, balls, wedges (smooth Roblox shapes) |
| Island | a flat top + rows of stacked brick strata | one cohesive grass top (chamfered rim) over a chunky dirt band, layered rock slabs with craggy faces, hanging rocks with gold crystals, vines (the v2 islands' underside) |
| Trees | voxel block trees | classic ball trees (Briefcase Bay v2's `park_tree`: oak / blossom / conifer) |
| Sky | brick clouds | cloud puffs, rock islets with trees, the sea far below |
| Studs | on every exposed top | only broad terrain, paving, decks, roofs + structural tops; leaves, flowers, water, glow, glass stay smooth |

| Deliverable | File |
| --- | --- |
| Editable .blend | `central_hub_v2.blend` |
| Aerials | `renders/hubv2_aerial.jpg`, `hubv2_aerial_close.jpg` |
| Ground views | `renders/hubv2_ground_plaza.jpg`, `hubv2_ground_street.jpg`, `hubv2_ground_portal.jpg` |
| Cliff + waterfall | `renders/hubv2_cliff.jpg` |
| Labelled top-down | `renders/hubv2_layout_topdown.jpg` |
| Service + lot positions | `hubv2_layout.json` |

## In the place
`Workspace.WorldRedesign.CentralHub` (20,229 parts, built 2026-10-20 by `tools/zones/BuildRedesignIsland.lua` from
`tools/zones/redesign/CentralHub.json`); the v1 hub model is kept in `ServerStorage.Old_WorldRedesign_v1`. The example
firms on the lots (`Plot*_Firm_EXAMPLE`, there to show scale) are **not exported** (`kit/hl_export.py`): FirmBuilder
builds the real ones. The hub is not wired to gameplay yet: today's hub still holds the firms, spawn and services.

## Known weaknesses (honest)
- **Same buildings, smoother:** the services and lots are crnuch's Stage 3 pieces drawn with smooth primitives; no new
  modelling pass on them.
- **No ambience pass** (v1 has `../central_hub/hub_ambience.py`).
- **Not reviewed by crnuch.**
- **Parts in the place:** organic slabs / rocks are approximated as boxes (the open parts vs meshes call).
