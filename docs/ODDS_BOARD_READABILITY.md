# World odds-board readability — 2026-10-24

Documentation only. Pilot one Briefcase Bay board, preserving the chunky studded world and UI v3. No Studio changes or tests were performed.

## Evidence

Fresh current-main snapshots:
- [Zones.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/Zones.client.lua), blob `c9505c4f3ab97f89190ae60f8e077c2a020a1fb9`.
- [BuildLane.lua](https://github.com/crunccy/HatchLawyers/blob/main/tools/zones/BuildLane.lua), blob `d72978279eeec2284b5d7b30797dae7d24987307`.
- [Formulas.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ReplicatedStorage/Shared/Formulas.lua), blob `52fed6ce07758c67b7835091b40f77bf8d834e93`.
- [Config.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ReplicatedStorage/Shared/Config.lua), blob `e763a6f0bd94fd4af2ce46aecc38ec22dd28879c`.
- [EggServer.server.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ServerScriptService/Eggs/EggServer.server.lua), blob `dde09ae2fd9378150aa16e83826c47bfe3c65b00`.

These are source observations. Builder coordinates are not proof of the current runtime island placement; existing HubMap wiring may move models. Inspect the actual tagged runtime board before changing its model or orientation.

## V31 — current gameplay composition reference

AlphaPS99, [BEST Way To Progress FAST in Pet Simulator X Classic (Pet Simulator 99)](https://www.youtube.com/watch?v=9Ry6rSvB9Fo), runtime 7:19; page displayed “4h ago” during this review. The title identifies the experience; no popularity or causal success claim is made.

Playback samples: 0:25–0:36, 1:00–1:13, 2:00–2:04, 2:25–2:40. Paused screenshots inspected at the end of each interval. Muted; no direct listening or full viewing. Captions are secondary evidence and not game labels.

| Timestamp | Visible observation | Transfer to our game |
| --- | --- | --- |
| [0:36](https://www.youtube.com/watch?v=9Ry6rSvB9Fo&t=36s) | Broad lime playfield, repeated tall colored facades along the sides, distant egg display across the end; small coins/crates occupy the floor. Currency HUD stays at the right edge. | Use a large recognizable destination silhouette, then make detailed information available close up. Do not fill our dodge lanes with the reference's breakables. |
| [1:13](https://www.youtube.com/watch?v=9Ry6rSvB9Fo&t=73s) | A blue “Self Improvement / Completed!” pill at the top; world remains visible, numerical HUD remains at right. | Keep brief status separate from a readable detail panel; do not cover the odds table with celebration particles. |
| [2:04](https://www.youtube.com/watch?v=9Ry6rSvB9Fo&t=124s) | Large red-and-gold chest with “Rank Rewards / Redeem!” text near it; behind, repeated egg pedestals have floating green currency symbols. | Name plus action beside a recognizable object provides hierarchy. For our board, egg name plus “VIEW ODDS” can identify purpose before the numbers are readable. |
| [2:40](https://www.youtube.com/watch?v=9Ry6rSvB9Fo&t=160s) | Teal area with repeated edge buildings and scattered breakables; currency HUD retains its location and shape. | Maintain a consistent information layout across zones, while scenery/palette changes identify the destination. |

**Limit:** no exact probability panel or readable egg odds was captured in these samples. The detailed odds design below comes from our source audit and is a proposal, not a copied PS99 interface. Creator subtitles about rewards/health are not independently verified mechanics.

Also extended V12 at [0:09](https://www.youtube.com/watch?v=TeFsGfVab6Q&t=9s), after playback from 0:05: right-edge Soccer Goals pairs reward icons with progress fractions. This is goal-progress UI, not hatch probabilities; do not use those numbers as odds evidence.

Library now **31 unique sampled videos**; V12 is not counted twice.

## 1. Keep the world sign; add a readable inspection view

### Existing implementation

Zones 720–837 already registers ZoneOddsBoard tags, resolves the Zone attribute, draws seven rarity rows and normal/golden columns, and redraws when PassLuckyEggs changes. It creates a SurfaceGui facing Front, PixelsPerStud 40, LightInfluence 0, MaxDistance 120. No board interaction is created by this section.

BuildLane 656–660 constructs a 14×9×0.6 board with two wood posts, set beside the route after Arrival. Do not rerun the entire lane builder for this polish.

With that template size, the face canvas is 560×360. Seven rows share half its height; each label uses 80% of its row: about **20.6 canvas pixels**, corresponding to **0.514 stud** in height. This is layout-box height, not glyph height or final screen pixels. Raising PixelsPerStud changes texture resolution, not the physical angular size of the text. Roblox exposes these controls in its [SurfaceGui reference](https://create.roblox.com/docs/reference/engine/classes/SurfaceGui).

A purely illustrative front-facing projection at vertical FOV 70°, viewport height 390 and distance 40 studs gives about 3.6 screen pixels for that 0.514-stud label box. At 15 studs, about 9.5 pixels. This is a geometric estimate, not an in-game measurement: actual part scale, camera FOV, distance and angle must be recorded.

### Proposed change

- Preserve the sign's existing full two-column table; do not hide odds behind a purchase or replace rows with mystery question marks.
- Give it a strong egg-name header and a clearly associated **VIEW ODDS** interaction. Use the existing custom prompt style for keyboard, touch and gamepad. Opening is a local presentation action, never a hatch or purchase request.
- Add one reusable Skin.window detail view: egg name, “Base rarity chances”, NORMAL / GOLDEN column headings, seven stable rows and a short explanation area. Keep the current font family, plain deep-purple body and muted-purple inactive states.
- Share one computed data model and formatter between sign and detail view. Build from Config/Formulas, not copied strings.
- On compact screens, keep close/header fixed; scroll only table/help content if needed. Proposed initial row height 28–32 screen pixels with readable 16–18-pixel labels. These are prototype targets, not Roblox mandates. Close/prompt targets should meet the project's 44×44 final-screen target. Static table rows are not tap targets.
- Opening must not move the player or force a camera. Clear access path and a side-mounted prompt should avoid collision with egg pickup interactions. Resolve competing prompts through the existing prompt system; no new global E-key listener.
- Scope prompt availability to a nearby board and close/disable its reference when the board streams out or is destroyed. Preserve current AncestryChanged cleanup and add equivalent cleanup for prompt connections and detail ownership.

### Acceptance

Capture Edit and Play board placement at avatar eye height, front and 30° off-axis, near interaction distance and path approach distance. Record actual part dimensions, camera FOV and measured screen text size. At 844×390 and 667×375, all seven rows must be accessible, close visible, text uncut, normal/golden clearly distinct, and no tap passed through Skin.blockClicks. Opening does not buy, hatch or change carried eggs. Stream removal/re-add creates one prompt and one board, with no stale detail view.

## 2. Clarify what the numbers mean

### Source evidence

- drawOdds calls Formulas.luckyWeights for normal and golden, combining pass and golden factors. The shared function caps boosts to the available Common/Uncommon weight. Do not replace this with naive renormalization.
- Header currently says EGG / GOLDEN. Footer reports selected boosted rarity names and a multiplier. With capped boosts, that configured multiplier is not necessarily each rarity's realized increase; the actual computed table remains the authoritative display.
- pct uses one decimal for percentages >=1 and two below 1, then removes trailing zeroes. It does not print arbitrary full precision. Current Supreme weight is 0.04% for these standard pools and displays correctly; **no current zero-rounding bug is established**.
- EggServer first selects ordinary rarity, then its pity rule upgrades a below-Legendary result when the threshold is reached (248–258). Mythic and Supreme results remain intact. Tutorial and Rare-token paths also differ from ordinary rolls. The world board does not read EggPity, so calling it an exact forecast of the next hatch would be misleading.
- The rows are rarity-level probabilities. Formulas.rollSkinId selects evenly from eligible catalog entries of that rarity, so a rarity chance is not automatically the chance of each pictured lawyer.

### Proposed copy and boundaries

- Table title: **BASE RARITY CHANCES**. Column names: **NORMAL** and **GOLDEN**.
- Status: **Lucky Eggs applied** when owned; otherwise **Standard chances**. Explain golden comparison separately. Keep exact calculated values visible rather than promising every boosted row gets the nominal multiplier.
- Footnote: **Guarantees can change a hatch's result. These are base rarity chances.**
- In the detail help area, describe the actual Config-driven pity tier/threshold and scripted tutorial/token exceptions. Do not say the pity hatch is exactly 100% Legendary: higher results survive the server rule.
- Do not label a rarity number as an individual lawyer's odds. If character thumbnails are later added, label them as examples or show the computed per-character probability with its eligible pool.
- Keep Supreme rarity distinct from Rebirth progression; use the current project's names rather than blindly replacing the rarity label.
- Where values are rounded, state that the table is rounded for display. Do not “fix” a displayed sum by altering a row's actual weight. Adaptive precision for future tiny nonzero values is a defensive formatter enhancement, not a reported present defect.

Acceptance fixtures: normal/golden × pass/no pass for all six egg types; zero-weight rarity; capped boost; current 0.04% Supreme; and pity-boundary explanation. Compare displayed values with the same shared calculation used by the server. No random sampling or economy retune is needed to verify presentation. Runtime fixture checks remain for implementation; none were run in this research.

## 3. Art treatment and delivery

For the pilot, retain the existing board/post silhouette and add restrained trim or an existing egg icon only if the approach view needs stronger recognition. Keep decorations outside the text face, prompt zone, travel arrival and boss escape routes. No swirling particles, rays or animated number scales on a probability table.

Any new geometry follows the established Blender-to-import pipeline and is scoped to the correct runtime-wired source object. Do not rebuild the map or change tags/Zone IDs. Stage-1 map work is already marked complete in current main.

Implement in src working copies after fresh Studio export/merge review. Deliver before/after approach captures plus a compact detail-view recording and probability-display comparison. This task changes presentation only: no prices, weights, pity behavior, pass ownership, saves, rewards or server authorization.
