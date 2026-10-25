# Shoreline composition and scenic anchors — 2026-10-25

Source audit and implementation proposal. No Studio changes, builder runs, tests or publication. Attempts to open new video samples failed because browser control was unavailable. This batch reuses previously recorded V11 observations explicitly; it adds **no new visual coverage**. Library remains 31 sampled videos. No sound was auditioned.

## Existing reference evidence

Previously inspected V11, Carbon Meister Plays, [Fischfright 3](https://www.youtube.com/watch?v=QkOhdClVIn4):
- [6:06](https://www.youtube.com/watch?v=QkOhdClVIn4&t=366s): sand, small stones, larger rock mass, tree trunk and short rail, separated from distant water/haze.
- [18:20](https://www.youtube.com/watch?v=QkOhdClVIn4&t=1100s): dock posts/decking lead to sand; overhead lights and a concentrated prop recess mark the transition.

These are the earlier sampled observations in VIDEO_REFERENCES.md, not newly watched footage. Transfer the hierarchy of foreground, landing and distant silhouette. Do not copy seasonal props, texture assets or Fisch's material palette.

## Source audit

Fresh main:
- [island_edge.py](https://github.com/crunccy/HatchLawyers/blob/main/tools/blender/island_edge.py), blob 0c9dc17091b39d574d6a7fa9ceae48841095b177.
- [BuildHubLandmarks.lua](https://github.com/crunccy/HatchLawyers/blob/main/tools/zones/BuildHubLandmarks.lua), blob 3ffccc6f4b097db0cd93c4374c14fde9f7119a6a.
- [WorldLife.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/WorldLife.client.lua), blob 16fbcaf89916f1f1c2465609a1e13eb446518f95.
- [HubMap.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ServerScriptService/Server/HubMap.lua), blob 0380108e8ff235d8c9f0ec524d42f35375e3bd41.

Already authored: dry/wet beach steps, a five-block rock cluster, dock/rowboat, three sailboats and three far islands. The beach leaves gaps for the original pier/lane. Placement is seeded. Do not propose these assets as missing.

The generator uses original island coordinates (grass x ±256, z ±160; sea top -1.4), and emits absolute placement lists under IslandEdge. BuildHubLandmarks transforms local part rows by each placement, preserves WorldPivot, creates Plastic+BrickStuds for ordinary pieces and archives existing same-named models. Its generic ordinary-part branch does not explicitly turn collisions/query/touch off. Re-running it is a replacement operation, not an additive detail brush.

WorldLife already adds flag sway, boat bob/roll, birds, walkers, fountain droplets, lighthouse beams and spatial sound loops. It throttles updates to roughly 30 Hz and gates visual work by player distance to a hard-coded HUB=(0,0,40), range 420. Eight wave emitters use original beach coordinates. Bird orbits use HUB; walker positions orbit the world origin and assume a plaza top of y=0.5.

HubMap can relocate/scale models and publishes workspace.HubCentre from the active wiring. WorldLife does not read that attribute in the inspected source. Therefore parts of scenic presentation are tied to old coordinates even though the hub has a runtime relocation mechanism. **A current visible offset or audible mismatch was not demonstrated**; the concern matters when active placement differs.

## EDGE-01 — one landing composition, using existing assets

Choose the actual runtime pier-to-shore transition after wiring, not a parked look-alike. Capture a player-height approach view before changing anything.

Proposed arrangement:
1. Keep one unobstructed landing and clear view of the destination.
2. Group existing RockCluster copies at one side of the landing; leave the opposite side quieter. Use one dominant mass with smaller supports rather than evenly spaced pebbles.
3. Preserve dry/wet color separation and broad silhouette. Check step height/contact against the real water surface; do not reuse -1.4 as an unverified runtime water height.
4. Use the existing dock/rowboat as the medium focal object only if it is present and belongs to this location. Avoid a second decorative dock that implies a usable travel destination.
5. Keep distant islands as broad silhouettes with open water between them. Do not spend new part density on far-away tiny details.
6. Keep overhead elements out of the normal camera path, and ground each rock cluster after rotation/scale.

Initial scope: reposition or adapt one existing composition, no new model family. New geometry, if actually needed, follows the established Blender pipeline. Preserve studs, bright wood/sand/grass colors and existing access lanes.

Acceptance: matched approach, landing and distant views in Play; destination readable at each distance; no new camera obstruction, collision snag or misleading interaction. Record added/removed instances. No full shoreline replacement or whole-map rebuild.

## EDGE-02 — bind scenic motion to the active environment

Introduce explicit client-readable presentation anchors under the runtime-wired environment. Reuse HubCentre for broad hub activation where appropriate; it is insufficient by itself to locate shoreline edges or a scaled/rotated plaza walking ring.

- Hub activity anchor: center and appropriate range for the active layout.
- Wave anchors: positions along the actual shoreline, not eight fixed world coordinates.
- Walk ring: a local transform/radius/ground reference attached to the actual plaza; do not just add HubCentre to old coordinates and assume rotation/scale are irrelevant.
- Fountain/lighthouse: retain existing object discovery but record the source object's identity and current transform.
- Boats: retain current low-amplitude bob/roll rather than adding more motion. Recompute rest transforms when a source is intentionally relocated; never capture an already-bobbed pose as the new rest.

Provide explicit fallback behavior for the old hub. Keep this client presentation only; no server movement, map switch changes or gameplay routing.

Acceptance: old layout and active island layout, moved/rotated/scaled test fixture, near/far activation. Birds/walkers stay over intended areas, wave anchors follow shore, and a boat's motion centers on its intended rest pose. Actual sound roll-off and mix require a later listening pass; no claim of current sound quality is supported by this audit.

## EDGE-03 — stream-out and return must rebuild the right effect

WorldLife discovers flags as descendants appear and removes them as descendants leave. Boats are removed when unparented. Fountain droplets and lighthouse beams are different: setup exits once arrays are nonempty, retaining captured positions. The shown implementation has no source-identity invalidation for those generated arrays; fountainSound is also a one-time flag.

Proposal: each generated effect owns a reference to its source and a cleanup function. Source removal suspends/removes its generated objects and sound emitter; a new source instance rebuilds once. Rebind on a deliberate transform change. Avoid rescanning/rebuilding the entire scene every frame.

Keep scenic motion out of other systems' objects: flags are currently found by common names across workspace. Prefer an explicit tag or scoped owner for future scenery so an unrelated Banner does not gain a second transform writer. Migrate known intended flags deliberately; do not strip existing animation indiscriminately.

Acceptance: remove/re-add fountain and lighthouse fixtures; stream away/back; replace a boat; enter/leave hub. One effect set per source, no ghost droplets/light beams at old positions, no accumulating emitters. Compare counts before/after. This is a specified check, not a measured leak.

## Implementation boundaries

Do not change gameplay collisions globally. For the landing, explicitly distinguish walkable structural dock/deck pieces from unreachable scenery; inspect raycast/camera needs before disabling CanQuery. Existing importer archive behavior can replace an earlier backup of the same name, so preserve the required baseline separately before a scoped authorized installation.

Work in src and scoped modeling/import files after fresh export/merge review. The active cloud incubator/ceiling claim is untouched. Current main marks the old map art stages complete; this is focused polish and runtime integration, not a request to redo them.

Deliver one landing composition sheet and a source-anchor map, then the lifecycle acceptance recordings. Revisit fresh video samples when browser access returns; do not count this source-only batch as new viewing.
