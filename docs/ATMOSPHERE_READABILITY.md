# Atmosphere readability: refine the existing controller
2026-10-24 · Focused source audit and V13 follow-up · No implementation

## Evidence and scope
Fresh main snapshots:
- `studio/StarterPlayer/StarterPlayerScripts/Ambience.client.lua` — blob `5914ef8a564acfccbeabe5d403dd51501a52f56c`.
- `studio/ReplicatedStorage/Shared/AmbiencePresets.lua` — blob `f6f7288a27395dc350b5323b35386e2882b2771e`.

These show an extensive atmosphere system already exists: themed lighting/fog/grade, air and geometry-based particles, High/Low profiles, boss rate reduction, travel/hatch suspension and debug attributes. Proposals below refine this controller. No claim that the live game currently looks washed out or has a measured performance problem.

### Additional visual coverage — V13, Develuper
[Make Your Roblox Game Look 10x Better With Lighting, 4:11](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=251s), after muted playback around 4:00–4:11. The avatar stands on layered studded slabs; nearby studs/edges are visible while the flat distant ground blends into a pale horizon under bright sky/clouds. The central pause overlay obscures part of the avatar. Useful comparison: keep foreground shape detail readable while softening distant scenery. This frame does not identify which setting caused the look, demonstrate boss-warning visibility, or justify adopting its palette.

This extends existing V13 coverage; the library remains **29 distinct sampled videos**. No full viewing or direct listening; captions at the endpoint are closing narration and not technical evidence.

## A1 — separate spawn-rate reduction from immediate visual quiet
**Observed:** bossBusy reads windup/attack. Every roughly 0.1 seconds, dip approaches BossDip (usually 0.35) using step×4 smoothing. Both air and anchored emitters multiply Rate by dip. Their Transparency sequences are created once; there is no Clear call in this controller. Pet Park pollen lasts 9–15 seconds, air leaves 7–11, water mist 7–11.

**Meaning:** changing Rate changes new emission; it does not directly remove the population already alive. Long-lived decoration can therefore remain through a short windup even after its spawn rate drops. This is an inference from the code and particle lifecycle, not a captured obstruction bug. Roblox documents Rate as emission per second and Lifetime as particle duration in its [particle guide](https://create.roblox.com/docs/effects/particle-emitters).

**Proposed:** classify layers by visual importance: tiny background motes can keep the current rate dip; broad mist/large leaves near the playable floor need stronger suppression. Prototype an opacity multiplier composed with the existing fadeSeq for those decorative layers, using the same controller and cached base sequences. Verify behavior on existing particles in Studio before relying on it. If a clean suspension requires Clear(), apply it only on state transitions to owned ambience emitters, with gradual re-emission afterward; avoid clearing repeatedly every frame.

**Boundary:** never suppress boss warning geometry, dropped eggs, players or pickup highlights. Do not use hidden LocalTransparencyModifier as a convenient shortcut. Keep NoLod ownership. Do not alter attack timings to wait for decoration to fade.

**Acceptance:** prefill Pet Park ambience for at least its longest lifetime, then inspect first warning frame, mid-windup, attack and recovery from a fixed camera. Repeat High/Low and near water. Warning boundary and loose eggs must remain identifiable. Measure the response rather than treating BossDip=0.35 as “65% fewer visible particles immediately.”

## A2 — art-directed mist placement, not more global fog
**Observed:** anchorBox uses grouped bounds, Above/Ground/Grow; WaterMist has size 6–11 and Grow=4 in Pet Park. Anchor candidates are clustered on a 36-stud grid. Eligibility comes from folder/name classification, not actual boss/route exclusion volumes. The top-folder classification returns before the name-based exclusion check, so adding an excluded name alone inside a recognized folder may not exclude that part.

**Proposed pilot:** inspect Pet Park's actual water anchors. Keep mist close to the water/perimeter; remove or split boxes that extend onto the main route or boss floor. Introduce an explicit optional “no ambient anchor” marker/attribute checked before folder classification if existing art grouping cannot express the exclusion. Apply it to decorative source geometry, not gameplay marker renaming. First deliver an anchor-debug capture showing each selected box and layer name.

**Integration:** Ambience.classify/findAnchors/anchorBox and AmbiencePresets.PetPark; actual WorldRedesign island chosen through IslandWiring. Preserve existing water, Arrival and Bounds data. Avoid another fog script or a second set of emitters placed by hand.

**Acceptance:** selected emitter boxes match their intended trees/water/landmarks after streaming; no route-wide mist caused by a distant outlier in a cluster. Check at normal player height, camera zoomed out and near the shoreline. Use existing AmbienceOff for matching before/after views; don't retune gameplay geometry.

## A3 — understand the real quality budget before adding particles
**Observed:** High has Anchors=8, Low=3. The selection loop counts separately per anchor kind, so these are not whole-zone totals. Air layers are additional. Each selected anchor may create several matching layers; footprint scale is clamped 0.4–2.5. Low rate is global 0.45 multiplied by layer.Low or default 0.45, so an unspecified Low factor yields 20.25% of the High base rate, not 45%.

**Proposed:** add a development-only summary of active anchors by kind, air/spot emitters, summed scheduled Rate and visible layer names. Keep it out of player UI. Review broad transparent sprites separately from counts: Roblox notes that covered screen area and overlapping particles affect rendering cost in its [particle guide](https://create.roblox.com/docs/effects/particle-emitters). Do not call an emitter-count reduction a measured frame-time improvement.

**Acceptance:** record baseline versus proposed pilot for High/Low, standing still and crossing island boundaries; include actual frame-time captures on a target device later. Verify that no new per-frame full-geometry scans or duplicate loops were added. Preserve existing quality behavior until measured evidence supports a change.

## A4 — make suspension actually match the cinematic handoff
**Observed:** suspended() covers Traveling, HatchCC on camera and camera height above 2000. Lighting fades stop while held; afterward a 1.2-second resume fade runs. Particle show becomes zero by Rate, but existing particles are not explicitly cleared; glows are multiplied by show. Zone cleanup waits 16 seconds after fade-out. These are intentional lifecycle pieces, not missing cleanup.

**Proposed:** define a clear local handoff contract: on entry, stop future ambient emission and suppress/clear only the controller's decorative particles if they would be visible in the cinematic; while held, leave cinematic lighting alone; on exit, restore the correct current-zone look and emit gradually. Reuse suspended() and existing ownership, rather than adding a general lighting manager without need.

**Acceptance:** travel from one island to another, hatch inside an island, return from high-altitude stage, respawn and rapid zone crossing. No stale-theme particles in the destination or double lighting fade. Inspect actual overlapping calls before declaring a race. Sound-loop behavior is outside this visual batch and was not listened to.

## Claude's review package
1. Pet Park fixed-camera baseline with AmbienceOff, High and Low.
2. Anchor-box debug view with route/boss area visible.
3. Short warmed-up boss-windup recording showing the proposed suppression.
4. Travel/hatch return recording and active-emitter summary.

Preserve studded Plastic, orange paths, readable silhouettes and existing approved map-work sequence. Change presets only after inspecting the pilot. No Studio changes, installation, publication, audio audition or runtime tests occurred in this research batch.
