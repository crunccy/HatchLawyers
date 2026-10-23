# Video research batch 4 — inventory clarity and animation cues

2026-10-23. Three additional sampled video references, V18–V20; twenty total across the library. Visual frames/playback and captions only, not complete viewings or direct audio listening. No assets/plugins installed and no game changes.

## V18 — Make inventory modes unmistakable

[How to Lock or Unlock Pets and Items in Inventory in Pet Simulator 99 Roblox — Rondoblox](https://www.youtube.com/watch?v=RB5V9Dzt5G0), listed six months old at inspection.

**Observed**
- [0:30](https://www.youtube.com/watch?v=RB5V9Dzt5G0&t=30s): white inventory panel, category icons at left, a compact lock/grid/trash toolbar above the content, search field, and a large contrasting close button. A cursor tooltip reads Toggle Grid Mode. Pet portraits and power values form a regular grid.
- [0:43](https://www.youtube.com/watch?v=RB5V9Dzt5G0&t=43s): the lock icon is blue, item pictures fill the panel, and a TNT Crate tooltip overlays the grid. Captions discuss locking by clicking. These are UI observations, not verification of persistent item protection.
- The inspected 0:55 frame is a dark transition, so it does not support an additional layout finding.

**Application to LAWYERS:** Whenever the same card click can mean inspect, place, swap, merge or sell, make the current action explicit in the panel. A persistent action label and clear cancel/back control are safer than relying on a small colored icon alone. Keep the selected count and intended result visible during multi-selection if that mode exists. Prevent a decorative highlight from looking like confirmation.

**Do not copy:** Icon-only lock/delete operations as the entire explanation. This desktop cursor/tooltip footage does not demonstrate a usable touch alternative. Preserve our purple panel style and current server rules; adding item-lock functionality would be a separate gameplay feature, not an automatic part of visual polish.

## V19 — Current PS99 collections: regular cards help, tiny overlays accumulate

[I Grinded 72 Hours DIAMOND MOUNTAIN Titanic, & Huge Pets in Pet Simulator 99 (Roblox) — Elkonn](https://www.youtube.com/watch?v=V4p2QVsfjiY), listed one day old on inspection.

**Observed**
- [3:34](https://www.youtube.com/watch?v=V4p2QVsfjiY&t=214s): a Pets panel has a consistent thumbnail grid, top action toolbar, search, category rail and Team 60/60 label. Small lock symbols appear on some cards; power/question-mark text is repeated under thumbnails. Quest/reward UI remains visible beside the panel.
- [5:57](https://www.youtube.com/watch?v=V4p2QVsfjiY&t=357s): the same grid contains many portraits with small lock icons, while surrounding currencies, category badges and Rewards remain visible.
- The 2:24 sample is a creator interlude, and 9:32 is an external-service promotion. Neither is treated as game-design evidence.

**Interpretation:** Repeated card geometry makes scanning possible, but many badges, numbers and surrounding notifications compete with the portraits. This is a useful comparison for our dense collection screen, not proof of retention or usability.

**Apply:** Choose a minimum information set per lawyer card: portrait, identity, essential owned/selected state. Put lengthy stats and action consequences in a focused detail area. Keep grid position stable when information updates. Use counts/badges deliberately rather than marking every category as urgent. Design the panel with the actual surrounding HUD visible, not only on a blank mockup.

**Limits:** This is recent footage but not verified mobile input. It does not establish touch target size, device performance or exact underlying implementation.

## V20 — Synchronize effects with authored action moments

[Make Your Animations 10x Better with Animation Events — Develuper](https://www.youtube.com/watch?v=d5GGIJJyMpg), listed seven months old.

**Observed**
- [2:00](https://www.youtube.com/watch?v=d5GGIJJyMpg&t=120s): the video shows an animation-priority table.
- [3:13](https://www.youtube.com/watch?v=d5GGIJJyMpg&t=193s): a posed rig and timeline are shown in a Parameters chapter; captions discuss reusing an event with changed parameters.
- [4:50](https://www.youtube.com/watch?v=d5GGIJJyMpg&t=290s): the animation-event dialog visibly has an Impact event and a Light parameter, during the SFX/VFX section.
- [6:27](https://www.youtube.com/watch?v=d5GGIJJyMpg&t=387s): a physical debris section discusses collision groups in visible captions. This is not a measured performance result or an endorsement of physical debris for our game.

**Engine verification:** Roblox documents timeline event markers and AnimationTrack.GetMarkerReachedSignal, including an optional string parameter. [Official animation-event documentation](https://create.roblox.com/docs/animation/events).

**Apply carefully:** For actual AnimationTrack-based clips, attach presentation cues to deliberate moments such as contact, crack, reveal or recovery. Our procedural Puppet/boss and Incubator systems need their own existing phase/timeline integration; do not assume every rig uses AnimationTrack or replace them to fit this tutorial.

## Proposed cue contract for implementation

This is an original recommendation, not extracted tutorial code:

| Cue | Visual responsibility | Authority / lifetime |
| --- | --- | --- |
| Preparation | Anticipation pose; accurate warning boundary | Existing server attack state determines timing/dimensions |
| Contact | Local impact layer and optional licensed sound | Cosmetic cue only; never client-authoritative damage |
| Reveal | Present the already-authorized lawyer result | Never rolls rarity or grants inventory from animation markers |
| Recovery/end | Fade remaining layers and restore presentation state | Cleanup also runs on interruption, respawn, travel and replacement |

For each effect record its owner, allowed parameters, attachment origin, cleanup path and behavior when a cue is missed or arrives late. Deduplicate repeated presentation events. If a client receives the attack after its warning period, it should render the correct current phase rather than replay an obsolete full warning.

Animation speed changes require cue review. Free-running delays can drift from the pose; marker/phase synchronization should be preferred where the current architecture supports it. This does not authorize changing the user's boss difficulty.

## New implementation review cases

1. Switch from inspecting a lawyer into an existing merge/sell/place mode: is the changed click meaning obvious?
2. Close/reopen the panel: are stale action mode, selected state and scroll position handled intentionally?
3. Inspect an oversized or heavily decorated lawyer: is its identifying feature still visible in the card?
4. Interrupt a hatch/attack effect: are camera, lighting, particles and callbacks cleaned up by their existing owner?
5. Disable nonessential effects: does the warning/result remain understandable?

These are proposed checks, not tests performed during research.

## Coverage and gaps

The search for PS99 mobile gameplay surfaced mostly desktop footage and creator videos. Neither V18 nor V19 is labeled mobile evidence. Do not repeat the same broad YouTube queries expecting them to validate touch behavior. A future pass should inspect a source that visibly shows touch controls or use authorized device captures of our own UI.

Direct audio audition and continuous boss-telegraph timing remain open. The evidence supports inventory hierarchy and cue-authoring recommendations only.
