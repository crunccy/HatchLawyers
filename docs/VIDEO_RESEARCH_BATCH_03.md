# Video research batch 3 — map depth and UI finish

Researched 2026-10-22. Continues [V01–V12](VIDEO_REFERENCES.md). Five additional videos were sampled through playback, frames and visible captions. These are not complete end-to-end viewings. No direct audio audition, downloaded assets, installed tutorial plugins or live-game edits. Videos are visual references; engine recommendations are checked against official documentation separately.

## Quick reference

| ID | Reference | Inspected anchors | Main takeaway |
| --- | --- | --- | --- |
| V13 | [Make Your Roblox Game Look 10x Better With Lighting — Develuper](https://www.youtube.com/watch?v=vkEXLmRAQgs) | 1:23, 2:18, 3:13, 3:31, 3:41 | Atmosphere and color treatment change depth; studded geometry still supplies form |
| V14 | [How To Make a Fisch Style Map In Roblox Studio — Kingkade 3D](https://www.youtube.com/watch?v=wSzIE4NCiSE) | 5:17, about 20:48, 37:04, 47:40, 51:00 | Modular shapes, terrain tiers, paths and repeated fence/tree families |
| V15 | [How to Scale UI for All Devices in Roblox Studio (Easier than You Think) — Code](https://www.youtube.com/watch?v=y2Q9iF1LEfo) | 0:20, 0:53, 1:24 | Phone preview, aspect constraints and anchor placement |
| V16 | [Steal An Egg - DR. SCRAMBLE New Boss Fight & Reward- ROBLOX [4K60FPS] — HorrorJackStar](https://www.youtube.com/watch?v=DHCqP21u6pM) | 2:45, 2:54, 3:06, 3:53, 4:38–4:39 | Persistent phase HUD, open arena floor, danger of effects hiding the subject |
| V17 | [How To Make Shiny UI Buttons That Pop! — Rileybytes](https://www.youtube.com/watch?v=8F3oW_Z6ffE) | 0:20, 1:30, 6:02 | A separate shine band and clear text layering; our kit already has a sweep |

YouTube age labels at inspection: V13 six months; V14 five months; V15 one year; V16 three weeks; V17 one year. These are presentation studies, not a current popularity ranking.

## V13 — Lighting needs a scene to support

**Observed:** [1:23](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=83s) shows atmosphere properties alongside a plain baseplate: the horizon fades into a pale band while foreground studs remain visible. [2:18](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=138s) shows a stylized cloud sky and the color-correction section. [3:13](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=193s) uses a warm orange environment with outlined characters as an example. [3:31](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=211s) shows a blue studded structure with strong recesses, steps and foreground ledges. [3:41](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=221s) returns to a small pile of studded slabs during the texture section.

**Design inference:** Lighting and composition work together: a flat plaza cannot gain useful architectural depth solely from more bloom. The blue structure's setbacks and terraces supply shadows and silhouettes.

**Apply:** Tune a neutral baseline before adding boss-zone mood. Review near/middle/far separation from the actual player camera. Keep lime grass, orange paths and lawyer rarity colors identifiable. Preserve shadow detail under overhangs and firm roofs. Use the existing effect brightness limits; do not copy a tutorial preset indiscriminately.

**Engine check:** Current Roblox documentation describes LightingStyle and PrioritizeLightingQuality; older advice centered on legacy lighting technology settings needs verification. Atmosphere density and offset interact and can conceal too much of the world. See [global lighting](https://create.roblox.com/docs/environment/lighting) and [atmospheric effects](https://create.roblox.com/docs/environment/atmosphere).

## V14 — Build an environment kit with relationships

**Observed:** [5:17](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=317s) shows an irregular faceted rock in Blender. Around [20:48](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=1248s), Studio contains multiple green-topped rock platforms, a pale route and an upright rock being placed along an edge. [37:04](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=2224s) shows a rotated flat terrain/trail piece. [47:40](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=2860s) compares repeated wooden fence sections, with different tree shapes in the distance. The [51:00](https://www.youtube.com/watch?v=wSzIE4NCiSE&t=3060s) frame shows a tall cliff backdrop, smaller terraces, broad-canopy trees and conifers, light path patches, fences and lamps. This last frame was visible while the player briefly buffered; it supports composition observations, not motion claims.

**Apply:** Make reusable large/medium/small assemblies. Use terrain height at perimeter scenery and destination plinths; keep collision and walking lanes deliberately simple. Repeat a family of fence posts, trims and lamp shapes to tie areas together. Vary tree height/orientation and cluster rocks where transitions need framing.

**Adaptation rule:** The game's approved look is studded Plastic/brick. Borrow massing and kit organization, not these textured mesh materials. Author new models through the existing Blender pipeline. Do not assume tutorial geometry budgets are appropriate for eight simultaneous firms.

**Concrete kit:** one short/long border pair; one post with interchangeable sign/lamp top; one bench; two crate/briefcase stacks; three plant silhouettes; one destination plinth; one legal-notice board. Start with the pier district and reuse approved pieces elsewhere. This asset list is a proposal, not something visible in the video.

## V15 — Proportional scaling is only the beginning

**Observed:** [0:20](https://www.youtube.com/watch?v=y2Q9iF1LEfo&t=20s) shows a black panel in a landscape phone emulator. [0:53](https://www.youtube.com/watch?v=y2Q9iF1LEfo&t=53s) introduces UIAspectRatioConstraint during a distortion example. [1:24](https://www.youtube.com/watch?v=y2Q9iF1LEfo&t=84s) demonstrates anchor-point positioning.

**Apply:** Keep card art square and buttons visually consistent, but let the arrangement change with available space. A desktop grid/details split should become a grid followed by a focused details view when the split would make both unreadable. Never require hover for name, price, odds or primary actions.

**Engine check:** Scale and offset are additive positioning/sizing inputs. UIScale scales descendants and appearance modifiers; aspect, size and text constraints solve different problems. AutomaticSize can fit content, while ScrollingFrame uses AutomaticCanvasSize. See [position and size](https://create.roblox.com/docs/ui/position-and-size) and [size modifiers](https://create.roblox.com/docs/ui/size-modifiers).

**Limit:** This simple tutorial does not demonstrate a production inventory, thumb reach, controller navigation or all screen cutouts. Do not treat it as mobile usability validation.

## V16 — Boss presentation: status can stay clear while the world gets noisy

**Observed:** [2:45](https://www.youtube.com/watch?v=DHCqP21u6pM&t=165s) shows a large, relatively open gray arena floor, several red-tinted round objects between player and mech, and a top HUD with boss name, HP and phase 2/3. [2:54](https://www.youtube.com/watch?v=DHCqP21u6pM&t=174s) shows more open floor and a round object with a target-like center. [3:06](https://www.youtube.com/watch?v=DHCqP21u6pM&t=186s) is largely obscured by a white effect, while the top HUD and dialogue remain legible. [3:53](https://www.youtube.com/watch?v=DHCqP21u6pM&t=233s) shows the large mech against bright green lighting; [4:38–4:39](https://www.youtube.com/watch?v=DHCqP21u6pM&t=278s) contains phase/status and player-state changes.

**Limits:** Edited footage and sparse samples do not establish exact warning durations, collision radii, attack order or whether any red object is a damage hitbox. Do not reverse-engineer those from these frames.

**Apply:** Keep combat ground less visually busy than perimeter scenery. Separate the boss's status from transient explosions. Avoid full-white obstruction during a dodge window. Our warning must communicate actual server attack dimensions; that requirement comes from our gameplay, not an inferred implementation in this video.

## V17 — Shiny UI: layers must serve the label

**Observed:** [0:20](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=20s) shows a green rounded button with a darker bottom edge. [1:30](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=90s) constructs a soft diagonal white shine band in an image editor. [6:02](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=362s) shows the green Rewards button with prominent white text, while visible captions discuss the gradient covering content.

**Apply:** Text, price and icon should remain above decorative shine. Trigger a restrained emphasis for a newly claimable reward, then return to rest. Avoid synchronized sweeps on every navigation tile.

**Existing code:** UIKit already implements a gradient shine, gloss, lower lip and motion. Audit its application and stacking before importing any new texture or adding another animation loop. No tutorial model/plugin was installed.

## Research not promoted into a reference

The character-menu tutorial `oMjB671EUrU` was briefly sampled, but the inspected sections were mostly code and did not provide a sufficiently clear final-menu comparison. It is not counted among the five new references. Keeping a count of links is less useful than retaining evidence Claude can actually apply.

## Next action

Read [MAP_UI_ART_DIRECTION.md](MAP_UI_ART_DIRECTION.md) for screen-by-screen and destination-by-destination recommendations grounded in this batch and V01–V12.
