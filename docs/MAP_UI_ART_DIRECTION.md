# Map and UI art direction — implementation proposal

2026-10-22. **User's call:** “I want the game to look amazing and the UI.” Prioritize a noticeable, cohesive improvement to the map and interface. This document proposes a concrete art pass; no game changes have been installed.

Read [the reference library](VIDEO_REFERENCES.md), [batch 3](VIDEO_RESEARCH_BATCH_03.md), [existing systems audit](VISUAL_SYSTEMS_AUDIT.md), and the approved [ART_REMODEL_BRIEF](ART_REMODEL_BRIEF.md). Existing task claims and the art brief's sequence still apply.

## 1. Visual identity to strengthen

A playful, prosperous law-firm world: chunky silhouettes, studded Plastic, lime grass, orange routes, warm wood, exaggerated legal props and expressive lawyers. UI remains dark studded purple with striped purple headers, thick ink borders and established fonts.

Use legal motifs consistently: folders for collections, a stamped tab for selected state, a gavel or courthouse shape for destinations, briefcases for carrying. These are proposed original assets built in the game's style. Preserve existing icon meanings and use HudMenu's PNG icon system; no emoji substitution.

**Visual hierarchy:** destination first, usable route second, supporting scenery third. In UI: player task first, selected lawyer/reward second, secondary statistics third. Rarity is an accent and label, not a reason to make every surface glow.

## 2. Map composition by destination

| Place | Main visual change | Supporting detail | Preserve |
| --- | --- | --- | --- |
| Hub / plaza | A recognizable focal destination framed by existing route geometry | Low planted borders, repeated lamp/post family, purposeful seating/notice clusters | Clear route to firms, travel and zone entrance |
| Pier / minigames | Treat pier, minigames and BigCaseBelt as one district with a clear entrance | Layered deck edges, braces/posts, legal cargo crates, repeated warm lamps and signs | Belt operation, minigame bounds and approaches |
| License destination | Strong portal/office silhouette readable before text | Framed gate, simple emblem, grouped waiting-side props | Required level/license information and prompt access |
| Firm exterior | Coherent base silhouette with visible progression additions | Trim, roofline/entrance changes, restrained accessories by tier | Eight-plot footprint, doors, anchors and expansion paths |
| Boss zones | Distinct perimeter silhouette/theme with a calm combat floor | Large boundary forms plus localized particles and restrained atmospheric color | Complete warning footprints, egg visibility and camera sightlines |

V01 supplies route/landmark contrast, V11 grouped threshold detail, V14 modular height and scenery families. These are composition references; avoid copying their entire palettes or seasonal props.

### Composition method

For each destination, work through three views: approach at normal camera height, interaction distance, and wide overview. Pick one large focal shape and two supporting masses. Put small props against those masses rather than distributing them uniformly across the floor.

Use height changes primarily on scenery borders, ledges and landmark bases until navigation is reviewed. Detail should not introduce snagging corners or hide dropped eggs. Keep collision simple; decorative pieces must not silently block existing interactions.

### Detail-kit delivery

Build one approved family in Blender: short/long border, sign/lamp post, bench, noticeboard, two crate/briefcase stacks, three plant silhouettes and a destination plinth. Reuse dimensions, edge thicknesses and attachment points. Vary arrangement and scale moderately, keeping the kit recognizable.

For each asset deliver source, export/build data, intended material/palette, pivot, collision intention and a thumbnail from the game's camera distance. Count geometry/instances before duplicating across eight firms. No fixed universal part budget is claimed by this research.

## 3. UI layout and states

### LAWYERS / collection

Keep the current office/client/bench workflow and existing labels. Inventory the actual current screen before moving any actions.

- Header: title, count/context and a consistent close control.
- Navigation: current tabs, selected state obvious through shape/contrast and label.
- Grid: large consistent lawyer portraits; short name and only the most important card metadata.
- Selected detail: larger character, rarity/mutation labels, useful stats and the contextual action.
- Persistent selected state: border/check/tab that remains visible without particles.
- Locked and unknown: distinct treatments; do not show fake ownership or infer unknown stats.
- Empty/filter-no-results: explain why nothing is shown and offer a relevant reset/navigation action.
- Small display: switch to focused details with a clear return action; preserve grid scroll and selection when returning.

V02/V11 guide reward and collection hierarchy. Do not add filter/search features unless the actual collection size and current implementation justify them.

### Shop / upgrades

One primary action per purchase card, with price adjacent and benefit stated plainly. Distinguish available, unaffordable, locked, owned/maxed and processing states in both label and appearance. Preserve existing purchase confirmations and server authority.

Never let a decorative shine hide a price or turn a disabled button into something that looks claimable. Keep premium purchases visually distinguishable from earned-currency actions according to the current product design.

### Travel

Make the destination image or emblem prominent, with name and availability below. Keep locked requirement text readable. Explain existing restrictions, including carrying eggs, at the action that cannot proceed. Do not silently change travel rules to fit a new panel.

### Pop-ups and notifications

| Event | Proposed presentation | Dismissal / lifetime |
| --- | --- | --- |
| Routine earnings | Small, aggregated feedback near its established location | Short decay; no modal |
| Upgrade success | Brief local confirmation and one accent | Ends without requiring an extra click |
| New lawyer | Existing reveal plus clear reward identity and useful next action | Let player inspect; keep closing/skipping behavior consistent |
| Major rarity | Existing special stage, controlled peak then a clear character hold | Preserve rarity stage behavior; restore camera/lighting afterward |
| Failure / unavailable action | Readable reason next to relevant control | Long enough to read; no celebratory effect |
| System-wide rare announcement | Compact banner that avoids interaction controls | Queue/rate-limit presentation without losing essential information |

This table is proposed behavior for review, not a claim that current notifications lack these properties.

## 4. UI art and motion rules

Reuse Skin/UIKit/HudMenu and the established font roles. First fix layout and contrast; then tune decoration.

- Keep textures faint behind reading areas. Reserve stronger stripes for the header.
- Use consistent padding and card spacing across panels. A proposed starting spacing family is 8/12/16/24 pixels at the chosen design resolution; adapt after device review rather than treating these as proven values.
- Make portrait framing consistent across small and oversized lawyers. A large model should not crop its face merely to share the same camera distance.
- Keep the panel's silhouette stable during selection. Avoid moving buttons under the player's finger.
- Existing button hover/press motion already exists. Do not stack another scale tween on it.
- Distinguish hover, keyboard/controller focus, pressed, selected and disabled. Touch must expose all essential information without hover.
- Limit recurring shine to meaningful attention requests. Use one controlled transition for a panel, then let it rest.
- Reduced-motion treatment should retain state changes through opacity, outline and text while avoiding bounce, tilt and camera shake.

Official [UI appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers) support gradients, borders, rounding and padding. Advanced gradient features shown in current docs may be beta; do not make release visuals depend on them without checking availability.

## 5. Lighting, VFX and animation finish

Separate three jobs: ambient mood, action readability and celebration.

**Ambient mood:** sparse drift/particles near scenery, gentle depth haze, coherent sunlight and shadow. Compare the same camera with effects disabled so the map still works on its own. Review both roof interiors and open orange/green surfaces.

**Action readability:** warning boundary must reflect authoritative dimensions and remain readable at lower visual quality. Decorative sparks must not be the only warning. Keep optional flash and debris away from the most important escape information.

**Celebration:** one short peak, then a quieter inspection phase. V12 and V16 demonstrate why overbright layers need restraint. Use existing Effects/HatchFx, rarity colors and brightness limits.

**Animation:** improve key silhouettes and transitions within existing Puppet/Incubator/Boss systems. Prioritize the moments players repeatedly see: working, case result, selection preview, hatch reveal and boss preparation/recovery. Vary phase offsets for background idles so a full firm does not look synchronized. Do not add constant large movement to every lawyer.

**Lighting ownership:** special hatch stages already change local lighting and camera state. Any new ambience controller must cooperate with that owner and restore state on cancellation/respawn/exit; avoid two scripts continuously fighting over Lighting.

## 6. Concrete first slice and acceptance board

Implement one bounded stage from the approved art brief; do not start several map rebuilds at once. For UI, polish one representative collection/result flow before spreading it to every menu.

Provide before/after views at the same camera/viewport:

1. Hub or pier approach: destination identifiable without reading a large paragraph.
2. Interaction view: main prompt, character and route unobscured.
3. Collection desktop and small landscape phone: names/actions readable, no accidental overlap.
4. Selected/disabled/empty/processing UI states: distinct without relying solely on color.
5. Peak VFX and quiet reward hold: lawyer face/outfit/name remain identifiable.
6. Busy eight-firm scene: retained readability and measured performance on target devices.

These are review criteria for future implementation, not checks already run. Do not claim a performance improvement without measurements, and do not change economy or boss difficulty as part of the art pass.

## 7. What remains to research

- Real mobile gameplay and controller focus flows; V15 only covers basic scaling.
- Direct SFX audition and mix comparisons; current audio notes are not listening findings.
- Longer continuous boss-warning sequences; V16 is useful for status/arena presentation but does not establish telegraph timing.
- The current installed game from fixed comparison cameras before deciding which proposed defects are real.

The first implementation decision should come from those current-game captures plus this evidence, not from adding effects simply because another game uses them.
