# Home-route cues and clean filming — 2026-10-24

Research specification only. No scripts installed, game published, runtime tests or audio audition.

## Evidence and scope

Current-main source inspected:
- [Zones.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/Zones.client.lua), blob c9505c4f3ab97f89190ae60f8e077c2a020a1fb9.
- [Guide.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/Guide.client.lua), blob cf11c0c036720c99f49ce34d95e69f611960b3e9.
- [PromoAdmin.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/PromoAdmin.client.lua), blob 9bf616e023c47d56ae9e42bcdb0d06acbceea580.
- [OwnerPrompts.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/OwnerPrompts.client.lua), blob 6df6e6c002280ab9bfa24b501582c33645186c21.
- [ZoneService.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ServerScriptService/Server/ZoneService.lua), blob b256332a44a1d71b5cf91bdf88e7534cadbe6eb0.
- [HubMap.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ServerScriptService/Server/HubMap.lua), blob 0380108e8ff235d8c9f0ec524d42f35375e3bd41.

This complements TRAVEL_UI_WAYFINDING and EGG_INTERACTION_CLARITY. Those cover travel panels and carry HUD. This pilot covers the world cues between carrying an egg and reaching an incubator. Preserve current gameplay, tutorial order and approved chunky art.

## V27 additional coverage

GosuNoob, [How to Go Back to World 1 in Pet Simulator 99](https://www.youtube.com/watch?v=w4JHR0MgRdU), 1:40 runtime, page listed two years old. Useful established presentation reference, not evidence of current popularity.

Played selected intervals 1:00–1:13 and 1:13–1:25, muted. Paused screenshot at [1:13](https://www.youtube.com/watch?v=w4JHR0MgRdU&t=73s) shows the Teleport panel: numbered green destination tiles connected by thick black arrows, with small activity icons. A visible Rainbow Road tooltip names “Rebirth Shrine” under “In Area”. The panel communicates progression order and a destination's function in separate layers. It does not establish a walkable world route.

At 1:25 the screenshot is the creator's end card, excluded from game-design evidence. No arrival landmark was verified in that frame. No direct audio listening or full-watch claim. This extends V27; total remains **31 distinct sampled videos**.

**Transfer:** separate “where home is” from “which nearby object completes this action”. Do not add the reference's entire numbered progression map to our existing travel UI.

## Confirmed existing behavior

1. Zones 552–595 creates CarryHomeGuide, a gold beam (despite an older “green” comment), from the player's feet to the Base of the first Model under their firm's Incubators. It runs while carrying and farther than 14 studs from that Base; target reevaluation every 0.5 seconds. No path/obstacle calculation occurs here.
2. Zones 633–655 already turns tagged ZoneChevron models 180 degrees while carrying, using their Home CFrame, and recolors them gold. This is an orientation flip, not a calculation of the actual route across an arbitrary island.
3. Zones 657–697 already provides YOUR FIRM: a 110×92 BillboardGui, AlwaysOnTop, up to 2000 studs, 26 studs above SpawnPoint. Its target refreshes every two seconds.
4. Guide.client creates a separate green TutorialGuide. Its incubator choice also uses the first child Model's Base. It can additionally target a waiting client or an empty office based on attributes. Do not replace its conditions with comments describing an older tutorial.
5. ZoneService hooks IncubatorPrompt under tagged incubators and checks owner ancestry before hatching. OwnerPrompts controls tagged owner-only prompts locally. A visual guide must not bypass either.
6. HubMap can move and scale source models at startup, including plots. Source paths remain the same but world locations change. Old lane geometry cannot be assumed to describe the active island route.

These observations establish limitations in target selection and cue coordination, not a proven live collision, inaccessible incubator or navigation failure.

## Task HOME-01 — hand off from destination marker to nearby action

### Proposed change

Keep YOUR FIRM as a distant orientation cue. At the firm, use one selected incubator's existing prompt and a restrained local focus cue. Stop the long home line when that selected prompt becomes usable for the local player; do not equate “within 14 studs of Base” with actual prompt reach.

Define a shared presentation-only incubator resolver for Guide and Zones:
- Resolve the current own firm from the replicated Plot assignment.
- Consider existing incubator Models with an actual IncubatorPrompt and valid spatial anchor. Read prompt.Enabled and range as presentation hints; never treat those as server authority.
- Choose the nearest eligible candidate, with a stable tie-breaker; retain the current candidate while it remains valid to avoid flicker between two nearby machines.
- Anchor near the actual prompt/interaction face, using existing Attachment or BasePart placement where available. Inspect the template before inventing a new anchor.
- If none is currently available, keep the firm destination cue and omit the final beam. Do not point at a missing Base, another player's machine or claim “ready” merely because a model exists.
- Switching to the local prompt does not trigger it, start a hatch, move the player or consume an egg.

**Near-target stability proposal:** use separate enter/exit thresholds around the prompt range, with a small configurable margin, and require stable selection for a short interval before changing. Tune with two-incubator and camera tests; these are design choices, not measured reference values.

### Acceptance

Test both incubators, reversed child order, one missing/unparented machine, disabled prompt, wrong owner, full lawyer inventory, firm rebuilt and Plot changed. The cue remains stable and refers to the intended own-firm interaction; server rejection still behaves unchanged. During cooldown/full inventory, do not add a new success animation or falsely signal that a hatch succeeded.

## Task HOME-02 — review the route before adding more arrows

A straight endpoint beam can indicate direction without guaranteeing a walkable route. Inspect one actual return journey from Briefcase Bay after HubMap/ZoneMap initialization. Capture the bridge/exit, hub entry and own-firm approach at avatar height.

If the direct line crosses an obstacle or empty space in that reviewed route:
- First prefer a clearly named nearby exit/bridge marker, then the firm destination, then incubator. Use the existing wiring's actual traversable route.
- Author only the necessary route anchors for this pilot, attached to runtime-wired source models and transformed with them. Keep a safe fallback to destination-only guidance if route anchors are unavailable.
- Do not calculate every arrow by simply reversing the old lane Home CFrame on new islands. Retain existing lane behavior when the lane mode is active.
- Do not automatically add PathfindingService, a minimap or global route graph. A larger routing system needs its own measured need and implementation scope.

Art: preserve current gold home direction and green tutorial distinction, but use a short label/icon to avoid relying only on color. Prefer existing path contrast and one destination landmark over an additional arrow at every step. Keep beams thin and restrained against the bright floor; tune LightEmission/opacity from matching screenshots rather than assuming more glow improves contrast.

The Roblox [Beam reference](https://create.roblox.com/docs/reference/engine/classes/Beam) exposes attachment, width, transparency and light-emission controls; these do not supply route semantics.

Acceptance: lane and island mode, at least two plot orientations, carrying versus empty-handed. Record which route segments were reviewed. No invented “all worlds verified” claim from one route.

## Task HOME-03 — explicit visibility ownership for clean recordings

### Source evidence

PromoAdmin setGui (15–40) saves/disables direct PlayerGui ScreenGui children and handles new ScreenGui children. The YOUR FIRM BillboardGui lives under the ZoneBoards Folder; the two guide Beams live under the character. Those objects are outside that function's type/path scope. Thus “hide GUI” does not itself disable these three cues. This is a concrete scope gap, not a screenshot proving a recording was spoiled.

Guide/CarryHomeGuide update their own Enabled state repeatedly. A one-time toggle from another script would be overwritten. Do not recursively disable every Beam in the game: boss warnings, hatches and effects have different owners.

### Proposed change

Add a client-only presentation visibility signal consumed by the owners of these specific navigation cues. Authorized promo GUI hide sets it; show clears it. Guide and Zones compose it with their normal gameplay visibility rather than overwriting one another's Enabled state.

While hidden: suppress these owned navigation beams and YOUR FIRM only. Continue updating their intended target/state. On show: recompute current eligibility and target, not a stale saved Enabled value. If the player consumed eggs or respawned while hidden, old guidance must not reappear.

Keep any hatch-cinematic suppression as an integration point: inspect the current cinematic owner before wiring it. This batch did not audit the full Eggs cinematic lifecycle and does not claim it currently fails. Use separate reasons/tokens so ending one suppression cannot override another.

Preserve existing PromoPolicy authorization, GUI restoration and camera controls. No new remote, role, UserId entry or production-economy capability is necessary for local navigation visibility.

### Acceptance

While carrying: hide → move → consume egg → show. Repeat with tutorial progress, respawn, firm rebuild and newly created marker. No stale line; normal gameplay cues resume only when needed. Boss attack geometry and warnings remain untouched. Other players' views remain unchanged. Compare a recording frame with hide on/off; no gameplay test or capture was performed for this research.

## Claude delivery

Implement only after fresh export/merge review, in src working copies; do not hand-edit studio snapshots. Coordinate around the existing incubator/ceiling claim—this proposal changes cue selection, not the machine geometry. Deliver one route recording, one two-incubator handoff recording and one hide/show sequence, noting exact tested states. Update the index/log after implementation rather than treating this research as a completed fix.
