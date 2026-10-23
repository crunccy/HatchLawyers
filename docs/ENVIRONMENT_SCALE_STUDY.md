# Environment scale and reusable asset review — V22

2026-10-23. Supplemental map-building research. Selected frames and captions, not a complete viewing or direct audio audition. No Studio changes, downloaded packs or installed plugins.

## Video evidence

[Top 5 Mistakes Roblox Builders Still Make (And How to Fix Them) — RoBuilder](https://www.youtube.com/watch?v=hMQBjPbZAb0), listed one year old, runtime 9:26.

- [2:49](https://www.youtube.com/watch?v=hMQBjPbZAb0&t=169s): an avatar is shown in an interior with large glazed doors/windows and curtains. The Scale and proportion chapter's captions discuss steps that require manual climbing. The frame supplies a character-to-building scale comparison; it does not prove exact stair dimensions.
- [4:43](https://www.youtube.com/watch?v=hMQBjPbZAb0&t=283s): the Importance of lighting chapter shows an avatar next to a doorway in a strongly blue/purple-lit interior. This provides an example of lighting altering surface color; sampled footage does not establish its final settings.
- [6:36](https://www.youtube.com/watch?v=hMQBjPbZAb0&t=396s): the Project organization chapter displays many separated effects in a dark preview space: columns, beams, rings, a tornado-like form and lightning.
- [7:33](https://www.youtube.com/watch?v=hMQBjPbZAb0&t=453s): the same effect-library view accompanies captions about parts, textures and complex meshes affecting performance. This is general guidance, not a measured performance result.

The realistic interior and bright effects are not a proposed replacement for Hatch a Lawyer's studded art style. The transferable points are avatar-relative scale, controlled preview conditions and organized reusable assets.

## Application: scale is part of polish

Our map pass should look intentional at the player's camera height and remain usable. A destination can look good from an overhead editor view while its doorway, desk, stair or sign is poorly proportioned for an avatar.

Before detailing a destination, place representative character silhouettes beside its rough shapes. Include the game's unusually large lawyers where they actually appear. Review:

- door and route clearance;
- camera clearance beneath roof trim, arches and foliage;
- interaction distance and whether a prompt sits behind a prop;
- visibility of the lawyer's face above a desk or podium;
- room around incubators for the existing hatch presentation;
- foot placement on steps, plinths and uneven edges.

These are proposed reviews, not findings of defects in the current place. Do not change collision or walking routes simply to match a reference's proportions.

Roblox's [greyboxing curriculum](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/greybox-your-environment) recommends simple geometry to discover layout and character-scale problems before polishing. Its example is a laser-tag map; its specific corridor dimensions and three-lane layout are not requirements for our tycoon.

## Application: build an asset contact sheet

The effect-library scene suggests a useful handoff artifact: an internal preview area or contact sheet containing our approved components side by side. This is a proposal for Claude's implementation workflow, not a new player-facing room.

For each reusable map prop show:

| Field | Why it matters |
| --- | --- |
| Asset name and source/export path | Another session can reproduce the asset |
| Front/side silhouette and avatar comparison | Confirms useful scale and recognizability |
| Pivot and placement orientation | Prevents awkward insertion and inconsistent ground contact |
| Approved palette/material | Keeps studded Plastic consistent |
| Collision intention and interaction exclusions | Protects traversal and named prompts |
| Instance/geometry count and duplication context | Makes eight-firm cost visible before rollout |

For effects, show the same effect on grass, orange paving and a dark background. Record the peak frame and settled/decay frame, rather than judging only a dramatic isolated screenshot. The existing Effects brightness rules remain authoritative.

A dark preview background can make a weak effect look strong or conceal bloom problems on the game's bright floor. The comparison surfaces are therefore a practical addition to the tutorial's separated-library approach.

## Performance decisions to defer until measured

Do not assign arbitrary universal particle/part budgets from video appearances. Compare the destination before and after at the same camera, with a representative busy server and target device. Inspect bursts separately from continuous effects because our current LOD treats them differently.

Roblox's [performance guidance](https://create.roblox.com/docs/performance-optimization/improve) discusses unnecessary per-frame work, simulated-object cost and overly precise collision. For this art pass, the practical proposal is to anchor static decoration, keep decorative collision simple, and reuse existing effect/update owners rather than creating a loop for each prop. Specific engine settings still require inspection of the actual implementation.

## Definition of a useful first art deliverable

One approved destination, its reusable component contact sheet, matching before/after player-camera views, and documented scale/interaction observations. After review, extend that kit according to ART_REMODEL_BRIEF. This avoids spending model-building time on details that disappear at player distance or make navigation worse.

No runtime checks were executed during this research. Controller navigation, direct audio audition, continuous boss telegraph timing and physical-device UI ergonomics remain open.
