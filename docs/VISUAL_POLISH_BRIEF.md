# Claude implementation brief: visual polish

Date: 2026-10-22. Status: research and proposed implementation plan; **nothing in this package is installed in Studio**.

## User direction

The user identifies **map detail and UI as the biggest issues**, followed by a **VFX and animation upgrade**. They requested actual video references and asked that the research be made accessible in GitHub for Claude.

Read [VIDEO_REFERENCES.md](VIDEO_REFERENCES.md) for ten sampled video references with timestamped observations. This brief's proposed treatments and timings are design recommendations, not measurements from those games.

## Start here

1. Read current `CLAUDE.md`, `SESSION_LOG.md`, [ART_REMODEL_BRIEF.md](ART_REMODEL_BRIEF.md), [ZONES_REFERENCE.md](ZONES_REFERENCE.md) and [CHARACTER_STYLE.md](CHARACTER_STYLE.md).
2. Check/reconcile active claims. The existing map/model pass is queued behind the Studio bug-fix claim. This document adds presentation guidance; it does not silently release that claim or authorize overwriting concurrent work.
3. Inspect current Studio, then refresh the snapshot before touching scripts. Repo observations may be stale.
4. Capture the same player-level views at desktop and phone size: plaza, one firm, zone threshold, boss attack, lawyer inventory, hatch result.
5. Record the concrete defects visible now; do not assume every proposed improvement is missing.
6. Implement one bounded stage, visually review it, record results and release its claim. No wholesale UI/framework rewrite.

## Priority and definition of done

| Priority | Deliverable | Reference | Acceptance |
| --- | --- | --- | --- |
| P0 | Baseline captures and route/UI audit | V01–V03 | Current issues documented; active claims reconciled; comparable before views |
| P1 | One coherent panel + reusable button/card states | V02, V04, V05 | Clear title/action hierarchy, phone readability, correct interaction blocking |
| P1 | One hub destination with purposeful surrounding detail | V01, V03, V08, V09 | Recognizable from approach; interaction and traversal clear; matches existing palette |
| P2 | One complete reward/hatch presentation pass | V02, V05, V06 | Anticipation/reveal/result form one sequence; reward remains readable; cleanup works |
| P2 | One boss animation/effect pass | V06, V07 | Warning, strike and recovery align with server attack; visible boundaries match damage |
| P3 | Apply approved kit to remaining destinations/panels | Same references | Consistency without new styles per screen; compare crowded/mobile performance |
| P3 | Audio audition and mix pass | V10 | Reviewed by listening in game; useful cues remain audible; independent volume controls |

These priorities do not reorder the detailed map stages already approved in ART_REMODEL_BRIEF. UI work can be scoped independently after checking ownership; map work should follow that brief's composition-first sequence.

## A. Map detail: build in layers

**Recommended composition:** one large landmark, a small group of medium props, then sparse small accents for each destination. Keep the center of the travel/combat route open.

- **Plaza:** retain orange routing. Frame destinations with raised edging, planter/prop clusters and signage. Adjust brightness if pale surfaces lose depth before adding more detail.
- **Travel portal:** strengthen base, side supports and framing silhouette. Let a restrained moving element indicate activity; keep its interaction zone free.
- **License Office / gates:** oversized readable sign, architectural frame, and a concise unlock label at the threshold. Keep the next zone visible.
- **Firms:** a consistent door frame, roof trim, supports, window recesses and one or two work props. Make stage growth visible at normal camera distance. Do not fill desk routes or incubator camera space.
- **Pier/minigames:** follow the shared-district plan in ART_REMODEL_BRIEF so BigCaseBelt, booths, entrance and paths feel connected.
- **Zone perimeter:** group scenery in uneven clusters with gaps; use height changes in background silhouettes. Keep egg spots, boss warnings and escape space readable.

### Model kit proposal

Author reusable pieces in Blender: plinth, corner/edge trim, post/support, sign frame, planter, crate cluster, bench, lamp, roof cap and two or three vegetation silhouettes. Preserve studded Plastic and the existing chunky proportions. V08 is a composition/workflow reference, not a mandate to use smooth trees.

Record pivots, dimensions, material palette and intended placement for each asset. Avoid dozens of tiny pieces that disappear at player distance. Preserve all named anchors/prompts/tags from CLAUDE.md.

### Ambient VFX proposal

A few slow particles near a destination or biome edge can establish mood. Keep the floor around the player clear; background haze should separate distance without hiding eggs or attack edges. Local visual presets must restore on travel/respawn and must not permanently change global Lighting for other players.

## B. UI: one clear visual language

Existing direction already specifies dark studded purple panels, striped headers, outlined lettering, rounded buttons and the HudMenu system. Improve those rather than introducing a competing theme.

### Prototype screen

Use the LAWYERS panel as the representative dense screen after inspecting its current implementation:

- Strong title and close control.
- Clearly selected tab/filter.
- Large lawyer thumbnail and readable name.
- Rarity/mutation distinction with both label and color.
- Secondary details on selection instead of cramming every stat into every card.
- One primary action per selected state.
- Obvious empty, locked, busy, pending and unavailable states.

Keep server actions/results authoritative. A disabled button should explain why it is unavailable. Avoid repeated requests during an animation or pending response.

### Shared button states

V04 demonstrates shape, outline and lower-edge depth. Implement a reusable state treatment: default, focus/hover, pressed, pending, disabled. Suggested initial motion targets to tune in game:

| Motion | Starting target, not a measured benchmark |
| --- | --- |
| Press response | 0.08–0.12 s; slight scale/depth compression |
| Menu entrance | 0.18–0.25 s; one small overshoot |
| Menu exit | 0.12–0.18 s |
| Routine toast | approximately 2 s; aggregate repeats |
| Special claim accent | one short perimeter burst, then stop |

Respect reduced motion; essential state changes must remain obvious without animation. Support touch and gamepad focus as well as mouse.

### Notification hierarchy

- **Routine income:** small aggregated local feedback.
- **Upgrade/unlock:** short nonblocking toast with icon and outcome.
- **Rare hatch:** prominent character/reward presentation, then a clear result.
- **Destructive action:** deliberate confirmation, not an easily clicked celebration button.
- **Combat:** defer unrelated promotional/reward overlays until the warning can be seen.

Keep buttons inside safe areas and away from mobile movement/jump controls. Preserve `Skin.blockClicks` behavior; background clicks must not leak through a panel.

## C. VFX: shape, timing and contrast

Use existing Effects/HatchFx and LOD infrastructure. Audit first for duplicate systems.

An effect specification should name: trigger, origin, scale source, duration, layers, priority, maximum concurrent instances, distance/quality behavior, and cleanup owner.

### Boss pass

The previous tuning increased attack range and speed. Reconfirm the current Studio values and preserve them during presentation work.

- The outer warning boundary should show the final hazardous extent from the beginning of the windup.
- Animate fill, pulse or a countdown inside that boundary rather than making the danger appear smaller until the last moment.
- Strike effect should occur at the actual server attack time, with recovery visually distinct.
- Line attacks need both readable width and endpoint; ring/pull attacks need distinct inner and outer meaning.
- Ambient glow must not share the same visual treatment as a damage warning.
- Scale cues from the same dimensions as server hit detection. Do not infer damage radius from mesh size.
- Optional cosmetic particles can reduce with quality/distance; gameplay-critical warnings must remain clear.

### Hatch/reward pass

Preserve the existing in-world incubator presentation and special high-rarity stages.

Recommended sequence: focus → anticipation → reveal → readable pose/name → short result/action. Give the character time to be seen before filling the frame with particles. Common outcomes should be quick; the strongest accents belong to exceptional outcomes. Do not change odds or invent near-miss outcomes to make the reveal exciting.

V06's final aura shows useful separate layers, but its near-white intensity is excessive for our routine gameplay. Retain the repo's LightEmission/Brightness guidance and inspect at high and low graphics quality.

### Mutation pass

Follow the existing approved 3D mutation brief: character reaction/approach, machine anticipation, visible transformation or fizzle, then clear outcome feedback. V02 informs the outcome's reading order; it does not replace the scene with another full-screen modal. Preserve existing success/fizzle rules.

## D. Animation: readable poses and coordinated beats

- Bosses: distinct preparation silhouette, decisive action, visible recovery. Use torso/body/prop motion together as in V07.
- Lawyers: small writing/stamping/thinking loops; short celebrations and reactions. Phase-offset idles to avoid synchronized office rows.
- Machine/portal: one or two intentional moving components; avoid animating every component.
- UI: shared timings and easing; overlapping tweens should cancel cleanly.

Synchronize cosmetic sounds/effects through animation markers or shared sequence timing where appropriate, while the server owns outcomes and attack timing. Client markers must never authorize damage or rewards. Existing custom boss joint groups/Puppet behavior may need bespoke clips rather than humanoid AnimationTracks.

On cancellation, respawn, travel or destroyed models, restore camera/input/lighting and disconnect callbacks. Do not make a rare reveal permanently trap the player's camera.

## E. Sound: audition, do not assume

Sound-video research was visual/caption based. Claude should listen to the game and reference before making mix claims. Proposed categories: UI, rewards, world ambience, combat and music.

Try a brief mechanical/wooden transient for legal props, a modest low layer for large impacts, and a short sparkle/chime for rewards. Avoid constant overlapping income sounds. Boss danger should have a visible equivalent for muted play. Use licensed/approved assets; verify current ownership and audio loading in the published experience.

## Integration map: inspect before editing

These are existing paths in the local working copies/docs, not a guarantee of the latest Studio versions.

| Area | Candidate files / systems |
| --- | --- |
| Shared UI | src/UIKit.lua, src/HudMenu.lua; Shared.Skin and Shared.UIFonts in Studio |
| Dense panels / HUD | src/Lawyers.client.lua, src/Hud.client.lua, src/Travel.client.lua |
| Effects | src/Effects.lua, src/EffectsLod.client.lua; Shared.HatchFx |
| Hatch | src/Eggs.client.lua; Shared.Incubator and IncubatorAnims |
| Characters | src/Puppet.lua; DeskLife and SkinLook |
| Bosses | src/Bosses.client.lua, src/BossService.lua, Config.Bosses |
| Assets / zones | tools/blender/, tools/zones/, ZoneDecorLibrary |
| Scope / existing captures | docs/ART_REMODEL_BRIEF.md, docs/ZONES_REFERENCE.md, references/ |

## Review checklist for implementation

- Before/after from the same camera position, lighting and screen size.
- Mobile and desktop: readable labels, correct clipping, no click-through, usable focus states.
- Boss: actual damage boundary matches visible warning; effects do not hide escape routes.
- Crowded firm: face/name readability with several auras, clients and UI notifications.
- Hatches: ordinary and special rarities; interruption/respawn restores state.
- Performance: record comparable frame time and memory on a representative phone before and after. Choose budgets from measurement, not universal particle/part numbers.
- Preserve server validation, saved IDs, economy, named model anchors and active concurrent work.
- Document installed/not-installed status precisely; refresh snapshots after Studio edits.
- Publish only under the user's applicable authorization.

## Suggested first handoff task

Inspect the current LAWYERS panel and the hub's approach to the Travel Portal. Propose one annotated UI layout and one small map-detail treatment using the existing kit. Reference V02/V04 for UI hierarchy and V01/V08 for landmark/detail composition. Reconcile claims, then implement one bounded approved stage at a time with before/after evidence. Do not begin with a full map or UI rewrite.
