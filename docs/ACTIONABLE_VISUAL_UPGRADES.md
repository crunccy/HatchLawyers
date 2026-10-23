# Actionable visual improvements — batch 5
2026-10-23 · Research and implementation specifications; no visual changes installed.

**User's direction:** deliberate, specific improvements that apply to Hatch a Lawyer. This document turns the references into bounded tasks. Follow ART_REMODEL_BRIEF for map sequencing and check SESSION_LOG claims before implementation.

## Evidence levels
- **Observed source:** the 138-script Studio export captured on October 23 before the promo installation. The UI, SkinLook, HubMap and FirmBuilder files cited below were not changed by that installation. These are source observations, not screenshots proving a visual defect.
- **New video samples:** V23/V24 below. Selected frames plus a short playback segment; neither video watched end-to-end. Muted, no direct audio audition.
- **Proposed:** dimensions, layouts, timing and acceptance targets below are recommendations to prototype, not measurements copied from successful games.
- Earlier video findings remain in the index. Do not add the same reference as a new video.

## Build order
1. Compact LAWYERS layout and portrait framing, as one UI slice.
2. One destination's trim/prop composition on the actual wired island asset, following the approved map stage.
3. Notification priority and one selected-lawyer motion pass.
4. Apply approved treatments elsewhere only after side-by-side review.

These are scoped deliverables, not a request to rewrite UI, gameplay, map routing or the animation framework.

## Task UI-01 — replace miniature desktop controls with a compact layout

### Confirmed source and consequence
`StarterPlayer.StarterPlayerScripts.Lawyers`:
- line 88 defines a 920×600 design canvas.
- `fit()`, around line 1298, chooses the smaller of (viewport width−24)/920 and (height−24)/600, clamped 0.35–1.
- `allButton`, around line 524, is 240×30 before scaling.
- Close is 58 high; tabs 42 high; bench cells 100×124; selected portrait area 116 high.
- A compact text workaround already exists at lines 122–150 (threshold 0.8, target 11 screen pixels). Preserve its intent; text-only adjustments do not enlarge the actual touch targets.

**Derived example, not a device screenshot:** with a reported viewport of 844×390, fit is 0.61. The 30-high action becomes 18.3 UI units high; close 35.4; a tab 25.6; the portrait only 70.8. At 667×375, fit is 0.585 and the action becomes 17.6. Insets and real device viewport reporting must be checked in Studio.

### Exact proposed change
Below the existing 0.8 fit threshold, switch layout instead of scaling the entire desktop composition:
- Keep a 48-high header with title and close; proposed touch hitboxes at least 44×44 **after** scaling. Treat 44 as a project review target, not a universal Roblox rule.
- Use a short horizontal office selector: office number, occupant portrait and one selected outline. Move instructions and repeated level text out of every tile.
- Show either the roster/bench view or the selected office detail. Tapping an occupied office opens its detail; Back returns to the prior scroll position. Keep the existing office/bench actions and meanings.
- In selected detail, put a large portrait beside name/rarity/mutation, with the primary action in a fixed footer. Secondary actions must remain discoverable without hover.
- Move UPGRADE ALL out of the 30-high strip into a full-height action row or clearly labeled secondary action. Preserve its cheapest-first server behavior.
- Keep header and action footer fixed; scroll only the content between them. Preserve `Skin.blockClicks`, close/back behavior, busy protection and selected office.
- Keep the desktop two-column arrangement when it genuinely fits. Reuse Skin/UIFonts/HudMenu styles.

### Acceptance
At 844×390 and 667×375 viewport examples: no cut-off close button, actionable labels readable without hover, measured final hitbox sizes, no overlap with touch controls, scroll preserved after inspect/back, and no accidental action while scrolling. Test no lawyers, long names, max-level office, unaffordable upgrade and pending request. These checks have **not** been run for this research.

References: V15 basic scale/anchor demonstration; V21 visible mobile controls/feedback. Official [size modifiers](https://create.roblox.com/docs/ui/size-modifiers) explain proportional UIScale and size constraints; the layout above is our proposed use of those mechanisms.

## Task UI-02 — one portrait framing policy, with room for movement

### Confirmed source
`Shared.SkinLook.showInViewport` (223–249) computes distance from **height only** (2.6×height), FOV 30, then sways the model.
`Lawyers.lawyerViewport` (445–469) already accounts for width, height and a supplied aspect ratio; do not describe all game portraits as naive or missing. It fits a rotated bounding box with a 0.96 multiplier.
The selected preview calls that helper with 268/116, then rotates about ±0.5 radians and adds upgrade hops/spins (around 775–800). The initial fit is therefore not necessarily the maximum animated silhouette. Current clipping has not been visually proven.

### Exact proposed change
- Consolidate camera fitting as a shared helper used by both callers. Accept actual frame aspect, FOV, padding and an optional art-directed focus point.
- Fit visible geometry after dressing/mutation. Exclude invisible stand-ins and irrelevant helpers. For the selected animated preview, fit the motion envelope (including widest turn and hop) or reduce that motion to fit.
- Use viewport AbsoluteSize for its aspect; handle zero size before layout and recompute on size change, not every frame.
- Prototype 8–12% edge clearance, then tune with the widest Supreme/Rebirth silhouette. This margin is a starting art target.
- Collection tiles: quiet consistent three-quarter view, aligned feet and face position. Selected detail: larger model with restrained motion. Keep name and rarity outside the model's clipping region.
- Apply one portrait lighting preset through ViewportFrame Ambient/LightColor/LightDirection. Judge dark clothing and bright mutation variants on the actual purple card; do not recolor the source model to fix lighting.
- Preserve the cache and existing model cleanup. Do not add Humanoids/WorldModels to every tile just because a tutorial uses them: our cached lawyer previews deliberately strip Humanoids and scripts.

### Acceptance
Contact sheet: smallest ordinary lawyer, widest accessory model, Mythic, Supreme/Rebirth, each mutation, square tile and wide selected frame. Face, feet and identifying prop visible at rest and motion extremes. Resize without re-cloning every portrait; close/reopen without extra animation connections.

Official [viewport guidance](https://create.roblox.com/docs/ui/viewport-frames) documents dedicated camera and lighting controls. V23 supplies a visual example of a small stable portrait becoming much larger during interaction; it does not establish a universal camera-fit formula.

## Task MAP-01 — detail the runtime destination, not its parked look-alike

### Confirmed integration constraint
`Server.HubMap` explains that startup moves gameplay models using `Workspace.HubWiring` markers and parks island look-alikes tagged `HubLookalike` in ServerStorage. `plainPlot` parks plot Decor and makes the old Base invisible. The earlier promo playtest reported 25 models moved and 2363 look-alike parts parked; this is a one-session log, not a performance benchmark.

Before modeling:
1. Resolve the chosen marker's `Moves` path and any Scale.
2. Identify whether the visible edit-time object is the runtime gameplay model or a look-alike.
3. Put reusable trim/props on the correct source model or explicit runtime decoration owner.
4. Compare Edit and Play views. Never remove markers, prompts, tags or stored Rest transforms to make placement easier.

### Concrete destination kit
Use one destination from the approved stage, preferably a shop/license counter once its claim is free:
- **Primary silhouette:** one broad sign or roof cap recognizable from the approach.
- **Structural depth:** a darker recessed window/counter opening, two chunky supports, consistent sill/roof trim thickness.
- **One activity cluster:** 2–3 briefcases, a docket stack or a stamp tray together beside the counter, chosen for that destination's function.
- **One grounding cluster:** planter or low border connecting the facade to the ground, placed at a side rather than across the interaction face.
- **Clear zone:** preserve the front approach and prompt area. Keep dropped-egg locations and boss escape lanes clear.

Use studded Plastic, warm wood, cream walls and existing lime/orange routing. Carry the same thicknesses and palette into the adjacent destination; change the icon/roof silhouette/prop story so they remain distinguishable.

V24 at 11:12 shows offset building heights, projecting roof edges and repeated window/trim language. Translate that *shape hierarchy* into chunky geometry. The reference's painted plaster, green shutters and Valorant-derived imagery are not our material palette and must not be copied/imported.

### Acceptance
Approach view, interaction view and return-route view at player height; same captures in Play after HubMap runs. Main prompt unobstructed, destination recognizable with signs temporarily ignored, details visible at normal distance, no new collision snags. Record added instances per destination and multiplied eight-firm cost before rollout.

## Task MAP-02 — make firm tiers read through architecture

`FirmBuilder.build` delegates the facade to `FirmStages.buildFront`, the hall to `dressHall`, and uses stage-specific INCUBATORS. Decorate those existing stage outputs instead of adding one static facade outside the builder.

Deliver a six-stage silhouette sheet before detailed modeling:
- Early stage: modest sign and simple roof edge.
- Middle stages: deeper doorway, taller sign/supports and more organized window rhythm.
- Late stages: larger facade masses and stronger roof/corner hierarchy, while retaining the game's bright materials.
These are proposed presentation relationships; inspect existing stages first and keep any good progression already present.

Use one consistent trim family. Do not add a new tiny prop to every available surface. Incubator camera volume, oversized lawyer clearance, door approach and desk aisle are exclusion zones. V24 supports architectural massing; V22 supports avatar-relative clearance. Existing known incubator/ceiling bug work remains with its current claimant.

## Task UI-03 — replace interrupting notes with prioritized feedback

`Zones.toast` around 113–121 already keeps **one** toast: it destroys the previous one and calls Skin.toast with a default 2.6-second hold at (0.5,0.34). Thus “add single-toast behavior” would repeat existing work. The real design question is which message is allowed to replace another.

Proposed policy:
- Group repeat messages by an explicit event key, not matching translated text. Repeated “cannot travel while carrying” refreshes one notice.
- A success result should remain readable; a routine notice must not immediately replace it.
- During boss warning/strike, defer nonessential celebration/announcement banners. Errors needed to understand a blocked action still appear near that action.
- Bound pending presentation queue to three, discard stale routine entries, retain current actionable failure. Starting values to tune: 0.5-second duplicate window and 2.6-second ordinary hold.
- Do not change server reward outcomes or delay damage to accommodate the queue.
- Inventory actions should use their local result area rather than routing every result into the center of the world view.

Acceptance scenario: rapid blocked-action taps, reward followed immediately by zone entry, rare announcement during boss windup, and GUI hidden for recording. No unreadable flicker or ever-growing stack. V21's repeated cooldown messages are the cautionary reference; they are not evidence that our current code stacks toasts.

## Task MOTION-01 — spend animation on the selected subject

The selected lawyer already bobs, turns and celebrates upgrades. Improve its pose and framing together; do not add a second RenderStepped loop or global spinning to all bench tiles.
- Quiet tile = stable portrait and persistent selection border.
- Selected detail = small torso/prop gesture where compatible with Puppet; settle into a clear front/three-quarter hold.
- Upgrade = existing kick timed to confirmed outcome, with restrained motion that stays inside the portrait envelope.
- Reduced motion = static selected pose and label/color outcome; skip spin/hop.
- Panel hidden or selection replaced = disconnect/restore through the existing preview lifecycle.

V23's hover-driven spinning example is useful as interaction feedback. Touch needs explicit selection, so essential motion or information cannot depend on MouseEnter. The tutorial's implementation is not a drop-in replacement for our custom brick rigs.

## New video coverage

### V23 — BrawlDev, Viewport Frame - Roblox GUI Tutorial #16 (2025)
[Video](https://www.youtube.com/watch?v=51hHMXf8z5c), displayed runtime 24:41, listed 1 year old.
- [7:24](https://www.youtube.com/watch?v=51hHMXf8z5c&t=444s): editor hierarchy places Camera, LocalScript and a model under ViewportFrame; portrait setup is visible.
- [9:52–10:02](https://www.youtube.com/watch?v=51hHMXf8z5c&t=592s): brief playback inspected. Main avatar is in a simple world; a separate white rectangular portrait stays lower-right. Captions at 10:02 attribute animation capability to a WorldModel. This sample does not prove our custom rig needs that conversion.
- [22:12](https://www.youtube.com/watch?v=51hHMXf8z5c&t=1332s): editor shows MouseEnter/MouseLeave, a tween and a RenderStepped rotation connection.
- [23:34](https://www.youtube.com/watch?v=51hHMXf8z5c&t=1414s): portrait fills much more of the white panel than at 9:52, with the head near its top edge. Captions describe continuous spin. Useful reason to review motion-space clearance; not a measured performance result.

### V24 — DatBoiEle, the ULTIMATE stylized tutorial for ROBLOX studio
[Video](https://www.youtube.com/watch?v=YG-IZoKAaQI), displayed runtime 12:26, listed 10 months old.
- [2:35](https://www.youtube.com/watch?v=YG-IZoKAaQI&t=155s): painting interface with broad, stepped brown tonal shapes; this is texture authoring, not foliage.
- [6:13](https://www.youtube.com/watch?v=YG-IZoKAaQI&t=373s): embedded Valorant footage shows patchy exposed masonry beside a planter. Record as the tutorial's external reference; no asset extraction.
- [8:42](https://www.youtube.com/watch?v=YG-IZoKAaQI&t=522s): Studio view places a small detail against a wall with a broad horizontal trim band.
- [11:12](https://www.youtube.com/watch?v=YG-IZoKAaQI&t=672s): completed building view has staggered heights, projecting roof edges, repeated window forms and large quiet wall areas. This supports our proposed silhouette/trim hierarchy, not importing its textures.

Total library: **24 sampled video references**. No audio evaluation, full-watch claims, performance measurement or new runtime visual implementation in this batch.

## Claude's first review package
Deliver: compact LAWYERS prototype with measured hitboxes; six-model portrait contact sheet; one runtime-wired destination blockout with its source path; before/after captures at matching cameras. Stop for art review before propagating across all panels and destinations. Record actual results against each acceptance criterion rather than reporting only “looks better.”
