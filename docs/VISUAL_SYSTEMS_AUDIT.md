# Existing presentation systems: implementation guardrails

Static source review, 2026-10-22. Local checkout HEAD: `d0a282431fc553a49a32b1eb49ad9dfeff9a5ba4`. This is a dated source snapshot, not verification of the currently installed Studio version. Re-read current files before editing. Research does not establish that a visual issue exists in every screen.

## Improve what exists

| System | Evidence in source | Next useful work |
| --- | --- | --- |
| `src/UIKit.lua`, `skinButton` | Rounded border, shading, top gloss, dark bottom lip, lifted text and shine layer. Hover scales to 1.08 with a small tilt; press scales to 0.9; release uses Back easing. | Inventory which important controls actually use this kit. Fix hierarchy, spacing, disabled/focus states and excessive simultaneous motion. Do not add a second generic bounce/shine controller. |
| `src/HudMenu.lua` | Centralized menu construction and interactions, badges/alerts/notes. | Preserve centralized positioning. Rank actions by player task, keep persistent navigation stable, and check narrow screens before adding icons. |
| `src/Puppet.lua` | Specialized lawyer/client/defendant/judge/working idles plus existing reaction and action clips. | Audit clip selection, pose strength, phase offsets and timing in actual scenes. Reuse the rig/clip system. Do not describe the game as lacking animations or install a replacement humanoid controller by default. |
| `src/EffectsLod.client.lua` | Continuous enabled emitters pause beyond 150 studs and resume inside 130; 150 entries checked per step at 0.4-second intervals. Rate-zero burst emitters are not distance-managed by this code. | Keep the existing LOD owner. Budget new bursts and their cleanup separately. Profile on target devices before increasing density; these values are implementation facts, not recommended universal budgets. |

## Concrete review board for Claude

1. **Pier approach:** before/after at the same camera. Add one coherent destination cluster using V11, keeping paths and prompts usable.
2. **One major collection screen:** compare owned, selected, locked and unknown cards. Use V02/V11 for information hierarchy; secondary stats should not crowd every thumbnail.
3. **One reward:** show peak burst, clear character hold and confirmation separately. Use V12 as both a reference and a warning about overexposure.
4. **One busy firm:** review idle/action variety from the player's usual distance. Existing clips should help communicate work, success and reaction without synchronous movement.
5. **One boss:** review preparation, danger boundary, strike and recovery. Verify the complete attack boundary is understandable before impact and remains visible at low effect settings.

These are proposed visual checks for implementation, not tests already performed. Preserve authoritative damage dimensions and the user's difficulty tuning. Any visual timing changes must not silently alter attack logic.

## First implementation slice

Keep the slice small enough to compare: one map destination, one collection/result screen, and one rare reveal. Capture the current Studio state, follow the existing snapshot/merge workflow, then review readability and style together. Extend approved components afterward. Follow `ART_REMODEL_BRIEF.md` and current ownership claims; new model work stays in Blender.

## Next research gaps

- Direct audio audition is still outstanding; the current sound section is caption/visual evidence only.
- Need stronger mobile/controller footage to validate navigation patterns, text size and focus treatment.
- Sampled frames cannot establish exact tween durations, frame pacing or effect cost. Measure our own implementation.
- Need broader boss-telegraph footage before proposing specific changes beyond accurate geometry and readable phases.

See [VIDEO_REFERENCES.md](VIDEO_REFERENCES.md) for source observations and [VISUAL_POLISH_BRIEF.md](VISUAL_POLISH_BRIEF.md) for the full brief.
