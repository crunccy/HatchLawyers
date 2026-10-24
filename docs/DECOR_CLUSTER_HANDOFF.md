# Reusable decor clusters: grounding, silhouette and collision
2026-10-24 · V14 extended coverage · Documentation only

## Current state before proposing more art
Fresh main [ART_REMODEL_BRIEF](https://github.com/crunccy/HatchLawyers/blob/main/docs/ART_REMODEL_BRIEF.md) says the approved stage-1 plan is completed: boardwalk/fountain, portal/shop/mutation machine, lot signs and gate statues were built. Treat earlier research language about “waiting for the approved stages” as historical. Inspect current claims and the live asset before proposing another rebuild; new work is focused polish.

Fresh main source:
- `tools/blender/zone_decor.py`: `4e49b1328a63893d56741152a481026a09d5a5d1`.
- `tools/zones/BuildDecorLibrary.lua`: `e3a47f12f14a589872471b7ea2d0dd3c38f4bb9e`.
- `tools/zones/BuildLane.lua`: `d72978279eeec2284b5d7b30797dae7d24987307`.

The library already includes TreeS/M/L/XL, TreeBlossom, Bush, BushFlowers, FlowerBed, Rocks, GrassTuft, OfficePlant, FileBoxes, WaterCooler and ParkBench, plus themed props. Trees already use seeded branching, multiple canopy clumps and darker/lighter greens. Do not commission a second generic foliage pack.

## V14 — additional samples
Kingkade 3D, [How To Make a Fisch Style Map In Roblox Studio](https://www.youtube.com/watch?v=wSzIE4NCiSE), displayed 52:58.
- [30:12](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=1812s), after muted playback from 30:00: separate tree and low bush assets sit on a working surface with island terrain in the distance. The tree uses a visible branching trunk and chunky canopy; bushes are much lower. This is an asset-building view, not proof of finished route composition.
- [34:11](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=2051s), after playback from 34:00: a selected trunk is framed close to the grassy ledge, with its bottom visibly above the surface in the inspected frame. Captions discuss accidentally placing trees above ground. This motivates a grounding review; it does not establish a defect in our game.
- Endpoint screenshots only support the visual claims; pause overlays obscure the center. No full viewing, direct listening or asset extraction. This expands V14, so coverage stays at 30 distinct videos.

## D1 — compose one cluster from existing pieces
**Proposed pilot:** one Briefcase Bay perimeter patch, outside the return route and boss/egg area:
- One TreeM as the tall backdrop.
- One Bush as a lower side mass.
- One Rocks group grounding the other side.
- One FileBoxes group nearest the office-themed destination, separated enough to read as an intentional activity prop.
- Leave a visible gap around the trunk and a clear opening toward the destination; avoid filling every gap with GrassTuft.

These are starting asset choices, not mandatory additions to an already well-dressed location. First compare against the actual current island. Use one cluster only; no island-wide random scatter.

**Integration:** clone existing library assets into the correct runtime island owner resolved through ZoneMap/IslandWiring. BuildLane is evidence of the library pipeline, not automatically the right installer for redesigned islands. Its decorate() uses random choice, rotation and scale; a deliberately arranged pilot needs explicit transforms in the owning island builder instead of tuning global random weights.

**Acceptance:** fixed player-height approach, interaction and return views; distinguish tree/bush/rock silhouettes and the main destination; no obstruction of warning edges, eggs, prompts or escape movement. Record exact source paths and transforms so the composition can be reproduced.

## D2 — make ground contact part of the handoff
**Observed:** Blender models are authored around a base origin, converted from Z-up to Roblox Y-up, and BuildDecorLibrary sets WorldPivot to origin. BuildLane scales a clone and pivots it onto the requested position. Those conventions are useful; placing at a supplied height is not proof of contact with sloped/uneven ground.

**Proposed:** store the intended support point and ground normal with the pilot transform. Inspect the actual lowest visible trunk/root/rock faces after scale and rotation; do not use an invisible helper's bounding box as proof. Prefer a level local patch or authored root contact rather than burying an entire model arbitrarily. A small deliberate root overlap may hide seams, but must not turn into a broad clipping fix.

**Acceptance:** close side views from two directions and normal camera view; no floating trunk gap, exposed underside or swallowed root silhouette. Check scaled instances, not only the library original. Do not move island floor/Arrival/Bounds or egg spots to fit decoration.

## D3 — specify collision and query intent per component
**Observed:** the library importer makes all parts anchored. nocollide/glass/neon tags disable CanCollide and CanTouch; CanQuery is not explicitly configured in this importer. Untagged trunk/rock blocks retain default collision settings. BuildLane clones retain these settings. This does not prove a runtime camera or raycast bug.

**Proposed:** include a small component-policy table in the pilot handoff:
- Decorative leaves, flowers and paper: no player collision or touch; query participation explicitly reviewed.
- Trunk/large rock: collision only if deliberately intended as a physical obstacle outside the route.
- Any separate gameplay trigger or interaction target: retain its existing behavior; never inherit a blanket decor policy.

Inspect consumers before changing query flags; verify in Studio with actual camera/pickup behavior. Do not apply a global “all props non-query” pass.

**Acceptance:** walk around all sides, zoom camera through the cluster and interact with nearby egg/prompt; no snagging or unintended blocking. Preserve intentional obstacles. Record final flags on the installed clone as well as source template.

## D4 — preserve material/export conventions and avoid whole-library replacement
**Observed:** this importer uses Plastic plus MaterialVariant BrickStuds for ordinary blocks while TopSurface is Smooth; glass/neon are explicit exceptions. Preserve that working studded recipe rather than forcing TopSurface=Studs on top of it. The builder deletes/replaces ZoneDecorLibrary; the Blender script uses its own ZoneDecor scene and a hardcoded Windows repository path.

**Proposed:** if a shape edit is genuinely needed, export/review only the chosen asset first and prepare a scoped installer. Resolve the correct project path for the current machine; do not run the complete builder as a harmless preview. Keep the existing export coordinate conversion and ZFight pass. Review part count and shadows per cluster before copying it elsewhere.

**Acceptance:** preview matches Roblox orientation/palette/stud treatment; no unrelated library models replaced; existing instances and wiring preserved; part count and camera captures recorded. No performance improvement claimed without measurement.

## Review package
One before/after patch, four named reusable models, explicit transforms/support points, component flags, actual added-part count, and player-height captures with active boss warnings. Follow current UI_STYLE_V3 for any labels and existing chunky world art. No new implementation, Studio install, publication or runtime tests in this research batch.
