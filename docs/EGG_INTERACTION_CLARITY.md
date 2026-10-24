# Egg interaction and playable-ground clarity
2026-10-24 · V28 · Research only

## Evidence
- Fresh main-branch source read: `studio/StarterPlayer/StarterPlayerScripts/Zones.client.lua`, blob `4932574d0229dd8d376b1812fce5add067945340`. This confirms bag dimensions/scaling, labels and price-on-prompt behavior below. A repository snapshot is not a live runtime observation.
- Supporting source: October 23 Studio export of `Server/ZoneService.lua`, `Shared/Config.lua` and client scripts. Re-export and reconcile current src before implementation.
- V28 below: muted selected playback and screenshots. Not a full viewing or audio audition. Captions were visible, but recommendations do not rely on narration. No downloaded assets.
- No new in-game screenshot or runtime test was taken. Risks inferred from source remain unverified visually.

## V28 — SkellyPlays, I Got My FIRST $1T/s PET in Steal an Egg
[Original video](https://www.youtube.com/watch?v=5tfzFYsW_og), displayed duration 20:51; page displayed “15h ago” when inspected. This is a recent gameplay example, not proof of any technique's effect on retention.

| Inspected frame | Concrete observation | Transfer |
| --- | --- | --- |
| [2:18](https://www.youtube.com/watch?v=5tfzFYsW_og&t=138s) | Low purple/brown fences divide broad lime-green plots; large open interiors; numerous small green earnings numbers; a giant bright creature occupies the upper-left. | Use low boundary rhythm to organize an area. Keep the active floor sparse; do not copy the amount of floating payout text. |
| [4:14](https://www.youtube.com/watch?v=5tfzFYsW_og&t=254s) | Broad brown studded ground remains mostly open. Halloween building, webs, trees and a lit pumpkin facade cluster at the edges/back. | A rich perimeter can frame a quiet playable center. Preserve our bright law-world palette; this does not recommend a Halloween conversion. |
| [8:36](https://www.youtube.com/watch?v=5tfzFYsW_og&t=516s) | Purple rail borders remain readable, while large white effect shapes obscure much of the upper-left subject. Small green amounts appear across the ground. | Judge floor detail and effects together. Readability can suffer even when each asset looks good separately. |
| [12:41](https://www.youtube.com/watch?v=5tfzFYsW_og&t=761s) | “The mutation failed...” appears above the bottom hotbar; a white outline is visible around parts of the subject at the top. | Put outcome feedback near the relevant action area. This frame does not establish why that subject is outlined or prove a selection algorithm. |

Played selected intervals around 2:05–2:18, 4:10–4:14, 8:20–8:36 and 12:30–12:41. Visual claims are based on inspected endpoint screenshots, not a frame-by-frame review of each interval. Pause overlays and captions obscure parts of the image. No pickup prompt was clearly observed in these samples; do not cite V28 as proof of a particular pickup interaction.

## E1 — readable carry bag at small viewports
**Existing:** Zones.client has 30×40 chips, empty/filled/golden treatments, count, orange full-state rim, and a pop on count increase. fitBag uses min(viewport height/760, half viewport width/bag width), clamped 0.5–1. At 844×390 with width not limiting, a chip becomes approximately 15.4×20.5 screen pixels. These are display chips, not buttons: a touch-hitbox standard is not the correct argument.

**Proposed:** keep the numeric count prominent at small sizes; use one legible egg icon and explicit “FULL — walk home” status when full, with smaller slot detail secondary. Preserve the normal multi-slot strip where it fits. Do not add a new clickable inventory to solve this display problem. Prototype 18px final-size count text and a 28px egg symbol as project review targets. Add a persistent small golden badge/count when golden eggs are carried so identifying them does not depend on a tiny animated sparkle.

**Integration:** Zones.client fitBag/eggChip/refreshBag, existing Skin/UIFonts and Carried/ZoneCarryMax attributes. Keep the current carry-home guide and first-purchase toast teaching. No changes to capacity or hatch order.

**Acceptance:** captures at 844×390, 667×375, 390×844; empty, one, full and mixed golden/ordinary bags. Count and full state readable without animation. No overlap with hotbar, joystick or jump controls. Observe actual maximum configured carry capacity before choosing compact thresholds.

## E2 — one clear egg focus without extra floating prices
**Existing:** zone egg labels are 120×34, two lines, visible to 55 studs. Price lives in BuyPrompt.ObjectText. The audited server creates a 0.25-second hold prompt at 10 studs with line-of-sight disabled. Buy validates availability, license, carry capacity, lawyer room and funds before syncing state and sending Bought. Loose eggs are a different system with existing Bosses.client highlights and automatic pickup; leave them separate.

**Proposed:** prototype a single local focus outline for the purchasable egg whose prompt is actively presented to the player, using occluded rendering and no filled glow. Keep its name/rarity legible and avoid adding a second price label. If multiple prompts are simultaneously eligible, explicitly resolve focus rather than assuming the latest shown event is the selected target. Inspect Roblox prompt exclusivity and current input behavior before implementation.

**Integration:** Zones.client egg registry plus prompt visibility lifecycle; no new buying remote. Prompt hidden, egg removed/streamed out, respawn or GUI-hidden recording mode must clear focus. Reuse a single highlight instead of one permanent highlight per egg. Do not change hold time, range or line-of-sight rules as an art change.

**Acceptance:** nearby overlapping eggs, golden egg, full bag, insufficient funds, another player buying the focused egg, stream-out, touch and keyboard. One focus maximum; a client cue never grants the purchase. No “success” effect until confirmed state/outcome arrives. This recommendation also draws on earlier V21's visible crop outline; V28 alone does not establish selection behavior.

## E3 — detail the perimeter, protect the action floor
**Proposed pilot:** in Briefcase Bay, organize edge dressing into three purposeful clusters: a low timber boundary, one oversized briefcase/document landmark, and a small plant/rock group. Use repeating chunky supports and large silhouettes; leave a continuous open route among egg spawns and the return path. Place detail outside the actual boss attack/play envelope, not an arbitrary assumed island border.

**Integration:** actual island asset resolved by Server.ZoneMap / IslandWiring, current boss and egg spawn markers, approved ART_REMODEL_BRIEF sequence. Keep studded Plastic, lime grass, orange paths, cream and warm wood. Do not move Bounds/Arrival/egg spots or shrink warning geometry to fit decoration. Avoid extra invisible colliders and tall props between the player and eggs.

**Acceptance:** fixed-camera before/after at arrival, closest egg and return route; inspect with boss warnings active and high graphics effects, plus low graphics. All six zones currently have MaxEggs=14 in the dated Config baseline: inspect full spawn occupancy, not an empty art scene. Record added parts and frame-time comparison later; no performance claim is made here.

## E4 — pickup feedback should finish at the bag
**Existing:** Bought plays Sfx.cash (gap 0.35, volume 0.7), displays a toast, and replicated count increases pop the new chip. There is already feedback; no extra sound layer is needed by default.

**Proposed:** coordinate one short bag emphasis with confirmed count increase and a stable full-state label. Keep action failure readable near the action/bag region; apply the earlier toast-priority policy instead of another central banner. If adding icon travel, use a UI copy only and a reduced-motion alternative; never animate a world egg as if purchased before server confirmation. Do not duplicate the existing chip pop with a second celebration.

**Acceptance:** consecutive buys, failed buy then success, full bag, boss drop, automatic loose-egg grab, hatch removal and GUI hidden. No false pickup celebration on a mere price refresh or lost purchase race. Audio changes require separate listening; no sound-quality judgment was made this session.

## Handoff
Build E1 first, then an E2 focus prototype and E3 one-island blockout. E4 is coordination polish, not a new effects framework. Capture source revision and actual runtime results before rollout. This batch updates documentation only; no Studio install, publication, asset import or runtime tests.

Coverage: V01–V28. Future gap: a clean recorded egg-purchase sequence and real phone views of our carry HUD.
