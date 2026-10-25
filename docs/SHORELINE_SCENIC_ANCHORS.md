# Shoreline composition and scenic anchors — 2026-10-25

Source audit and implementation proposal. No Studio changes, builder runs, tests or publication. The initial source-audit batch could not open videos and reused earlier V11 observations. The later follow-up below records new sampled visual coverage after browser access recovered. Library remains 31 sampled videos. No sound was auditioned.

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

Deliver one landing composition sheet and a source-anchor map, then the lifecycle acceptance recordings. The initial source-only audit adds no viewing coverage; see the separately recorded follow-up below.

## Visual follow-up — 2026-10-25, recovered browser access

**Evidence method:** muted playback of V11 at approximately 6:15–6:42 and 18:05–18:20, with paused visual inspection at 6:22, 6:42 and 18:20. This is sampled review, not full viewing. No direct listening. On-screen creator captions are not used to establish game mechanics. The 18:20 view repeats earlier coverage; 6:22/6:42 extend coverage of the same video. Unique-video count remains 31.

| Sample | Visible evidence | Transfer and limit |
| --- | --- | --- |
| [6:22](https://www.youtube.com/watch?v=QkOhdClVIn4&t=382s), also 6:42 | A broad grey sloped/stepped route climbs along the left; tall rock masses enclose the scene on the right. Distant palms break a bright, hazy horizon. Avatar gear occupies much of the foreground. | Study the empty route between large masses. This sample is a rock corridor, not evidence of a sandy dock or a measured camera clearance. |
| [18:20](https://www.youtube.com/watch?v=QkOhdClVIn4&t=1100s), repeated | Wooden planks/posts meet sand. A large glowing pumpkin sits to the right of the landing; orange/purple overhead lights and a side recess with a cauldron, figure and cobweb concentrate decoration. Water remains visible to the left. Character effects and creator subtitles overlay the view. | Put the decorative focus beside the route and retain an open side. Seasonal props, overhead strings and glow intensity are not a proposed asset list for our game. |

### EDGE-04 — turn the landing proposal into a measurable composition sheet

**Exact proposed change:** adjust one active dock-to-beach landing using the existing dock and one rock-cluster grouping. Keep the center traversable, place the dominant rock mass beside the approach, and retain open water on the other side where the current layout permits. Do not add a glowing landmark simply because the reference has one. Our destination landmark must remain the most useful thing to recognize.

**Source constraints rechecked this follow-up:** island_edge.py and BuildHubLandmarks.lua retain the blob hashes listed above. The authored dock has eight 8-stud-wide planks, spaced every 4 studs along local +Z; posts sit at local x ±3.6. The rowboat sits beside the end. These are authoring dimensions, not a measurement of the runtime model after wiring/scaling. The RockCluster is already five boxes with a dominant mass and smaller supports; use its existing hierarchy before adding parts.

**Implementation location:** scoped placement data in tools/blender/island_edge.py and a deliberately limited import through tools/zones/BuildHubLandmarks.lua. Record the active IslandEdge descendant and its world transform first. No changes to HubMap routing, collision policy for the whole kit, WorldLife animation amplitudes or any gameplay destination are needed for this composition task. The generic importer replaces same-named models; do not run the full import merely to move one cluster.

Prepare a before/after sheet with these matched views. Keep the same camera position, FOV, graphics setting, time/lighting and avatar for each pair; include HUD-on views because the game is normally played that way.

| View | Specific decision | Acceptance criterion |
| --- | --- | --- |
| Approach along the dock | Does the shore exit read before the detail? | The walkable exit is visible and distinct from the decorative rock mass; no new prop crosses the existing usable route. |
| Standing at the landing, camera turned toward shore | Does the side grouping frame rather than cover the destination? | Destination silhouette remains visible from the ordinary third-person view; trim/reposition the cluster if it masks it. |
| Turn back toward water | Does the rowboat read as scenery rather than a route? | Dock end, boat and distant islands are separable silhouettes. No decorative path implies an unavailable interaction. |
| Walk both directions with a short camera orbit | Does the composition hold during play? | No new camera pop-in against rocks/posts, avatar snag, floating support or abrupt water/ground seam. Inspect the actual collision geometry before changing it. |
| Compact landscape viewport with normal HUD | Do silhouettes survive screen crowding? | Route/exit still readable without hiding HUD, increasing bloom or adding a floating label. Record viewport dimensions; no mobile-device performance claim from this review. |

Use the dock's actual runtime width as the initial clearance baseline. Do not narrow it to match a screenshot or prescribe a generic stud count before checking player scale. Keep the far-island layer broad; small distant clutter will not solve a blocked landing silhouette.

**Deliverable and stopping point:** one matched composition sheet, one short walk/orbit recording, exact changed transforms and instance delta. Accept the pilot before extending to another shoreline. These are proposed implementation acceptance checks; none were executed in Studio during this research.
