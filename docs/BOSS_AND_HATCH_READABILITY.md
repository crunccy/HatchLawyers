# Boss readability and hatch effects — actionable research batch 6
2026-10-23. Research only; no boss tuning, Studio installation or publishing.

## Evidence and priority
Source observations refer to the October 23 Studio export used in the preceding installation work, specifically `Bosses`, `Server.BossService`, `Shared.HatchFx` and `Eggs`. Re-read current Studio before implementing. The findings below identify code behavior; they do not claim a newly recorded live collision test.

**Implement warning geometry before adding cosmetic effects.** The user previously asked whether larger attack ranges were actually represented visually. This audit finds concrete presentation gaps that deserve an explicit fix and boundary review.

## BOSS-01: show the final danger boundary throughout windup

### Confirmed behavior
In `StarterPlayerScripts.Bosses`:
- `poseWarn` begins around line 789. It multiplies crowd-disc radius, line length and radial/cone extent by `grow`.
- Around line 2325, windup calls it with `0.45 + 0.55 * easeOut(a / 0.4)`.
- `a` is normalized server-state time; easeOut clamps its argument and uses a quadratic curve.
- The displayed extent therefore starts at **45%**, reaches about **86.25% at 20% of windup**, and reaches full size at **40% of windup**. These are calculated source values, not timing measured from video.
- Line width already uses the full configured Width; its **length** grows. Pull Inner is not multiplied by grow.

### Specific change
Separate `boundaryExtent` from `countdownProgress`.
1. Place the outer boundary at full authoritative extent on the first received windup state.
2. Animate interior fill, texture flow or a secondary sweep using progress; the outer edge must remain fixed.
3. Draw a thin dark contrast backing beneath the boss-colored edge. Preview against lime grass, orange path, water-adjacent surfaces and bright VFX before choosing opacity.
4. Keep solid geometry for the critical edge. Optional particles/beam texture can decorate it, but an unloaded texture or lower graphics setting must not remove the warning.
5. If a client receives the state late, compute progress from StateStart/StateEnd; do not restart a full local windup.
6. Preserve actual server timings, radius, speed, target selection and difficulty. This task improves information.

**Acceptance:** capture first received warning, 20%, 40% and final windup. The outer hazardous footprint is unchanged across those captures. Late state reception skips expired presentation phases.

## BOSS-02: match shape semantics, including the easy-to-miss exceptions

| Attack | Actual source behavior | Required visual treatment |
| --- | --- | --- |
| Ring | `hitShape` hits the entire flat disc inside RingRadius/Radius | Fill the full disc; a cosmetic shockwave ring must not imply a safe center |
| Slam | Target is sampled at windup start and clamped to the area; impact hits a disc there | Keep the target disc fixed at the landing location, even while the boss model jumps |
| Line | Server checks distance from a moving center against Width/2 about every 0.05 s | Use a conservative swept-circle/capsule warning: strip plus rounded caps, derived from the replicated start/end and Width |
| Cone | Inside Radius, angular restriction is applied only when distance exceeds 3×boss Scale | Show the fan **plus the close-range full-circle region**, radius min(Radius, 3×Scale); do not falsely imply the boss's back is safe right underneath it |
| Pull | Outer Radius causes pulling; Inner is the server hit disc | Use two meanings: patterned outer influence area and a strongly bounded inner damage area, both visible without relying on color alone |
| Crowd lanes/discs | Separate replicated targets and CrowdWidth/CrowdRadius | Apply the same complete-boundary rules to each; do not accidentally reuse the main attack's dimensions |

The present line warning builds a rectangular WarnStrip and two WarnSide parts; the distance check is circular around the moving center. Rounded endpoint coverage follows from that geometry. Because the server samples movement, the exact sampled hit union depends on timing; a capsule is a conservative warning envelope, not a claim of continuous collision detection.

There is also separate body-contact logic. Keep it documented separately from the attack warning rather than treating every hit as a failure of the windup overlay.

### Review positions for Claude's future playtest
- Just inside/outside each radius at four directions.
- Line side edge, start cap and endpoint cap, with a shortened path near the zone boundary.
- Cone behind the boss, inside and outside its close-range exception.
- Pull outer influence edge versus inner hit edge.
- A main target and a crowd target simultaneously.
- Low/high graphics and a camera looking nearly along the ground.

Document observed agreement. Do not silently change damage to fit a convenient VFX mesh. No such tests were executed in this research batch.

## BOSS-03: improve the anticipation pose without slowing attacks

The existing client already supports BossAnims, per-attack clip names, timed turn/lead, pose fallbacks and FX callbacks. Work inside those paths.

First prototype: **Senior Partner briefcase swing**.
- First pose: readable separation between briefcase arm and torso; avoid the case being hidden behind the body from the usual approach view.
- Anticipation: torso/shoulder rotate with the raised case while feet remain visually grounded.
- Strike: the briefcase arc aligns with the existing hit instant. Keep the cue at the current server transition; do not make an AnimationTrack marker authorize damage.
- Recovery: shoulders and case settle into a distinct lower-energy pose so players can read the escape opportunity.
- Check front, side and elevated gameplay camera silhouettes with particles disabled.
- For current shorter windups, redistribute pose timing within the existing duration. Do not stretch the server interval as part of an art task.

V26's 1:55 sample explicitly shows torso rotation toward a swing; 3:04 discusses keeping the arc coherent. Transfer that body/prop relationship to the existing custom boss joints, not a new sword or humanoid controller.

Deliver three still silhouettes plus a short continuous capture aligned with server state changes. Confirm the case/hand arc does not advertise a narrower reach than the floor warning.

## HATCH-01: make the character survive the peak effect

### Source observations
- `HatchFx.rays` uses Beam Brightness 3, LightEmission 0.6 and a color-to-white sequence.
- `HatchFx.pillar` stacks two beams, Brightness 4, with emission 0.5/1 and different widths/speeds.
- The helper for particles defaults to Brightness 2, although several individual bursts override it lower.
- `Eggs` adds brief color-correction Brightness peaks (e.g. 0.25/0.3) and bloom changes during reveals.
These numeric settings are **not interchangeable across effect classes**, nor do they prove every reveal is washed out. They identify the layers to isolate first when comparing brightness against the existing effect rules.

### Specific treatment
Split one high-rarity reveal into three visual jobs:
1. **Anticipation:** controlled light/particle movement around the egg; keep the incubator silhouette.
2. **Peak:** one brief directional burst. Avoid simultaneously maximizing rays, pillar core, particles and full-screen brightness.
3. **Inspection hold:** lower bloom/flash, thin the foreground particle layer, retain a colored silhouette accent behind the lawyer. The face, outfit, name and rarity must read together.

Use the existing HatchFx handles and cleanup. Start with the current ray and pillar layers:
- Compare rays alone, pillar alone, particles alone, then combined on the same reveal.
- Keep the narrow core and wider color layer visually distinct instead of both becoming white.
- Bias decorative rays away from the face/name region; do not fill the camera center just because the world-space burst is spherical.
- Tune emission, opacity and bloom as a combined result. Preserve the established particle guidelines; do not mechanically apply one Beam number to a ParticleEmitter.
- Use V25's separated beam/start-particle layers as a composition reference. Its dark showroom is insufficient evidence for our bright map.

**Acceptance contact sheet:** same lawyer at peak and inspection hold, over bright world and special stage, high/low graphics, ordinary and reduced-flash presentation. Review identity readability, not only effect spectacle. No brightness measurements have been performed yet.

## HATCH-02: prevent overlapping presentation owners

`HatchFx.postBegin` reuses module-level post state and may borrow a Lighting BloomEffect. `postEnd` clears that state, tweens restoration and performs delayed cleanup. Existing restoration is present; do not describe it as absent.

Audit the transition when another effect begins before the previous fade ends:
- A sequence token/owner should prevent an old restoration tween from modifying the new sequence's borrowed bloom.
- Track and cancel the old tweens when superseded.
- Restore the original values once when the current owner releases.
- On respawn, travel, camera replacement or skipped reveal, release camera/input/post-effects through the existing sequence cleanup.
- Coordinate future biome ambience with this owner; avoid another script writing Lighting every frame.

This is a concurrency risk identified from code structure, **not a reproduced bug**. First determine whether Eggs currently serializes all entry points, including previews, before adding infrastructure.

## Beam implementation facts
Official [Beam documentation](https://create.roblox.com/docs/reference/engine/classes/Beam) describes camera-facing ribbons and endpoint widths. [Laser-beam guidance](https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/laser-traps-with-beams) demonstrates those properties as visual controls. Beam texture motion is decoration; it does not define this game's damage.
Official [post-processing guidance](https://create.roblox.com/docs/environment/post-processing-effects) explains bloom and color correction. [PostEffect documentation](https://create.roblox.com/docs/reference/engine/classes/PostEffect) notes quality-level differences. Therefore gameplay-critical boundaries must remain readable without relying on bloom.

## New reference coverage

### V25 — Jam Pro, Roblox VFX Beams Tutorial
[Video](https://www.youtube.com/watch?v=exWx1kYy0P0), displayed runtime 9:31; listed 3 years old.
- [1:57](https://www.youtube.com/watch?v=exWx1kYy0P0&t=117s): dark Studio demonstration area, parallel colored beam examples and a narrow beam extending from a sphere-like source.
- [5:01](https://www.youtube.com/watch?v=exWx1kYy0P0&t=301s): after brief playback from 4:45, a blue beam is accompanied by a distinct particle cluster near its origin; emitter properties selected.
- [7:37](https://www.youtube.com/watch?v=exWx1kYy0P0&t=457s): larger blue/cyan source burst sits around the beam origin, with the long ribbon still visible. This suggests separately controlling source burst and sustained line.
- The immediately-seeked 4:45 screenshot resembled an earlier frame; do not treat it as distinct reliable visual evidence. 5:01 was captured after playback.

### V26 — distovi, How to make an Attack Animation in 4 Minutes [Roblox Blender Tutorial]
[Video](https://www.youtube.com/watch?v=bzS9B3-iVH0), displayed runtime 3:50; listed 2 years old.
- [0:50](https://www.youtube.com/watch?v=bzS9B3-iVH0&t=50s): Blender pose work on a block rig with raised sword/arm, angled torso and visible timeline.
- [1:55](https://www.youtube.com/watch?v=bzS9B3-iVH0&t=115s): top view of a twisted body pose; captions describe rotating toward the swing direction.
- [3:04](https://www.youtube.com/watch?v=bzS9B3-iVH0&t=184s): wide-legged, leaned pose with sword extended diagonally; captions discuss the swing arc.
No full-video watch, exact timing measurement, audio listening or imported assets. V26 is a different video from the earlier V07 combo reference.

Library now contains **26 sampled videos**. This batch's most actionable finding is source-derived: full-size warning boundaries and correctly represented shape exceptions should precede extra VFX.
