# Travel UI and destination wayfinding
2026-10-24 · Documentation only · V27

## Evidence and scope
Source observations use the October 23 Studio export, before promo installation. The travel scripts were not among that installation's eight changed scripts. Re-export before implementation: this is a dated baseline, not a claim about the current live build's appearance. No runtime visual defect was reproduced in this research.

Video observations are selected muted playback sections and frames, not end-to-end viewing or direct listening. The reference below is older footage, useful for presentation patterns; it is not evidence of today's PS99 UI or commercial effectiveness. No assets copied.

## V27 — world travel in Pet Simulator 99
**GosuNoob, “How to Go Back to World 1 in Pet Simulator 99”**, displayed duration 1:40. [Original video](https://www.youtube.com/watch?v=w4JHR0MgRdU).

| Sample | Visible observation | Application / limit |
| --- | --- | --- |
| [0:06](https://www.youtube.com/watch?v=w4JHR0MgRdU&t=6s) | Large white rocket with red nose and dark circular window dominates the center; fins and nearby supports make its silhouette distinct. | Give a destination one recognizable large shape before adding scattered small props. Do not copy the rocket into unrelated law worlds. |
| [0:15](https://www.youtube.com/watch?v=w4JHR0MgRdU&t=15s) | Dark transition screen retains a small character image and “Teleporting to World 2!” text. | Keep destination identity readable while our existing travel effects play. No loading-duration estimate inferred. |
| [0:29](https://www.youtube.com/watch?v=w4JHR0MgRdU&t=29s) | Teleport panel shows numbered named areas, directional arrows, green available-looking tiles, grey question-mark tiles, search and side icons. Tech Spawn is blue. | Number/name/order work together. Tile colors alone do not prove every state; do not assert blue means current from this frame. Six zones do not justify copying this search system. |
| [0:35](https://www.youtube.com/watch?v=w4JHR0MgRdU&t=35s) | Centered “Teleport to World 1?” dialog with green Yes and red No; explicit destination in the question. | Use explicit destination wording. An extra confirmation for every ordinary trip is not proposed. |

Playback sampled around 0:00–0:06, 0:10–0:15, 0:20–0:29 and 0:30–0:35; screenshots inspected at the linked endpoints. YouTube pause overlay partially covers the center of the frames; observations use visible surrounding content. No captions used for these claims.

## Source audit: what already exists
Repository paths below describe the corresponding Studio snapshot paths; consult current src twins before editing.

- `studio/StarterPlayer/StarterPlayerScripts/Travel.client.lua`: 980×470 Skin window; seven cards in one horizontal row (124×318 each, 10 gap); zone number/name/color; My Firm house icon; license lock; YOU'RE HERE label; carrying strip; GO action and busy guard. Keep these capabilities.
- `studio/ReplicatedStorage/Shared/Skin.lua`, window fit: min(viewport width/(window width + rail allowance), viewport height/(window height + 90)), clamped 0.38–1. At 844×390, this travel window scales to about 0.696; a 52-design-pixel GO becomes about 36.2 screen pixels tall. This is calculated geometry, not a measured phone screenshot. Its 18-pixel requirement text becomes about 12.5 pixels.
- Travel render hides GO for locked cards, greys unavailable actions, and shows a carrying message. Home has no zone object, so the current-zone badge only applies to zone cards. Do not infer “at my firm” merely because currentZone() returns nil; the hub also returns nil.
- `studio/ServerScriptService/TravelServer.server.lua`: validates target type/length/catalog, license, carried eggs, player/character availability and cooldown. Uses ZoneMap Arrival or the owner's firm SpawnPoint. Requests streaming before PivotTo; failures have reason codes.
- `studio/ReplicatedStorage/Shared/TravelFx.lua`: tiered trip animation, camera/controls/lighting restoration and a go callback already exist. Its trip options are index/color/go; no destination-name option. The inspected source has no text label creation. Add readable status within this existing lifecycle; do not introduce another travel controller.

## T1 — compact travel layout (first implementation slice)
**Proposed change:** retain desktop cards when they fit. When resulting action height would fall below the project's proposed 44-screen-pixel target, use a compact layout with a fixed title/close row, pinned carrying/status strip, scrollable two-column destination cards and a My Firm shortcut. Fall back to one column when two cards cannot fit readable names. Derive card count from Config rather than the hardcoded seven-card row width.

Cards: number + short existing zone name, one landmark emblem, then state/action. Keep license requirement visible and wrapped; do not replace locked destinations with unexplained question marks. Use the existing Sky travel accent inside the established Skin styling. Preserve HudMenu registration, Skin.blockClicks and close behavior.

**Integration:** Travel.client card builder/render; a travel-specific content layout inside Skin.window. Check whether Skin.window needs an opt-in compact sizing hook; avoid globally changing every existing window's fit behavior.

**Boundary:** no new remote, unlock costs, teleport target IDs or economy change. Display still follows replicated state; server is authoritative.

**Acceptance for later implementation:** inspect 844×390, 667×375, 390×844 and 1280×720 layouts; final AbsoluteSize of primary actions and close target meets proposed 44px target; long license/name labels remain readable; every destination is reachable by scrolling; scroll gestures do not activate GO or close the panel. Verify all locked/unlocked/current/carrying states and rotation while open. These checks have not been run.

## T2 — matching landmark, card emblem and approach sign
**Proposed change:** pilot one island, using a recognizable feature already in its approved world concept. For Space Base, a chunky satellite-dish silhouette is a candidate only if compatible with the current approved model. Use the same simplified shape on its travel card and approach sign. Keep number + name beside the emblem so recognition does not depend on color.

Create a three-view review sheet: normal arrival camera, approach at player height, and the final-size menu card. Design the sign as cream face, warm wood supports, zone-color accent, dark outlined lettering; broad Plastic shapes with studded tops. Keep orange route surface visually continuous. Group small trim/plants behind or beside the landmark, leaving the route and warning floor quiet.

**Integration:** Config.Zones.List IDs/colors/names; Travel.client; the actual island asset resolved through Server.ZoneMap / Workspace.IslandWiring; approved model builder under ART_REMODEL_BRIEF. Inspect HubMap wiring if the pilot is at the hub. Do not decorate parked lookalikes or move Arrival/Bounds/gameplay prompts to accommodate art.

**Acceptance:** same name/number/emblem visible in menu and world; landmark identifiable at the normal arrival camera without a camera override; no collision/query obstruction from decorative sign pieces; carry route, eggs, prompts and boss warnings stay unobstructed. Review both low and high graphics. Part budget must be measured against the pilot's baseline before replication to other islands, not invented here.

## T3 — explicit travel status and recoverable error copy
**Proposed change:** pass a display-only destination name into TravelFx.trip; show “Traveling to [name]” through charge/jump/arrival, without covering character focus or the main effect. Remove it through the existing cleanup path on success/failure. Keep the existing destination color. This is a status label, not another full-screen animation.

Travel.client currently maps carrying/license/cooldown and otherwise uses a generic error. Add friendly copy for existing loading/missing responses: “Your character is still loading. Try again shortly.” and “This destination isn't ready. Try again shortly.” Avoid promising a retry time or progress percentage. A successful stream request isn't a measured loading percentage. Keep the busy guard until the operation actually resolves; do not retry the remote automatically or allow overlapping trips.

**Acceptance:** destination label uses canonical config name (Home → My Firm), remains readable in the brightest tier, and disappears with the trip's cleanup. Server rejection reopens the existing menu and shows a useful reason. Camera, controls and status restore after animation failure/respawn. Confirm current cleanup and pending-callback handling before adding timeout behavior; a locally cancelled UI alone cannot cancel a server move.

## Suggested handoff order
Implement T1 as one reviewable UI slice, then the T2 single-island identity pilot, then T3 status polish. Capture before/after at the same camera and viewport. Preserve the existing cloud bug-list claim and approved map sequence. This batch adds no Studio changes, gameplay tests, installs or publication.

Coverage now includes V01–V27. Next useful evidence gap: a real phone recording of our compact travel UI, and a current island arrival screenshot showing whether proposed signage actually improves the route.
