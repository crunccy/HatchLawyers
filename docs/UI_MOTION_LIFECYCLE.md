# UI motion hierarchy and lifecycle — 2026-10-24

Research/specification only. No game scripts edited, Studio installation, publication or runtime tests.

## Start here

Preserve [current UI v3](https://github.com/crunccy/HatchLawyers/blob/main/docs/UI_STYLE_V3.md): Gotham Black/Bold, deep-purple plain bodies, decorated saturated cards, muted-purple inactive states, small pop-ups and no gold hover ring. The UI already has substantial motion. Improve its ownership and state transitions before adding more effects.

Pilot: Daily Rewards plus the shared Skin helpers it uses. This complements [REWARD_STATE_CLARITY.md](REWARD_STATE_CLARITY.md); that document owns timer/copy/pending/receipt proposals.

## Evidence and coverage

Fresh main source read on October 24:
- [Shared/Skin.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ReplicatedStorage/Shared/Skin.lua), blob `64b6a7e9422a72fe4f51de2179fb11234bb2dedb`.
- [Rewards.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/Rewards.client.lua), blob `b8bc766d381b2adc6bef09427e6bca041673778b`.
- UI_STYLE_V3.md blob `e6a66fe5a07256ea333963ff9a1fcc804c08893f`.

Line references below belong to those snapshots. Inspect current source and Studio claims before implementation; snapshot code is not proof of an observed runtime appearance or measured performance problem.

### V17 follow-up — Rileybytes, How To Make Shiny UI Buttons That Pop!

[Original tutorial](https://www.youtube.com/watch?v=8F3oW_Z6ffE), runtime 7:32. This extends an existing reference; library remains **30 unique sampled videos**.

- Playback sampled 0:10–0:18 and 6:50–6:59, muted; paused screenshots inspected at 0:18, 6:59 and, after seeking backward, 6:54. Not watched end-to-end; no direct listening.
- [0:18](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=18s): Studio viewport shows a plain white rectangular button in the center. The purple fast-forward arrows and “model link in desc!” are creator overlays, not game UI. This frame is setup context only.
- [6:54](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=414s): finished lime Rewards button sits to the right of the avatar, with a white outlined label and darker lower edge. Its broad green face is readable against the grey baseplate.
- [6:59](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=419s): same button has a bright narrow highlight toward its right edge; label remains readable. The large Discord graphic and captions are creator overlays. The two screenshots establish different highlight states, not a measured sweep period or exact easing curve.
- Transfer: keep a stable label and button silhouette while decorative shine changes. Our existing Skin.glint already implements this idea; do not import the tutorial model or add a second shine system.

## 1. Make the ready reward the only calendar item asking for attention

### Source evidence

Rewards render (259–290) correctly resets the outer tile scale to 1 when no longer ready. But:
- Ready tile scale is assigned `1 + sin(os.clock() * 5) * 0.05`.
- render runs every 0.25 seconds (306–311). Thus the animated scale gets only four updates per second, although its nominal cycle is about 1.26 seconds. This is a stepped property update by construction; apparent judder still needs a visual recording.
- Each ready picture calls Skin.breathe once, tracked by a boolean map (204, 282–289). That registration is never removed when the item becomes claimed.
- Skin.breathe (391–399) appends a persistent registration and returns no stop handle. The shared loop updates it whenever onScreen allows it, until the picture loses its parent.
- Therefore a previously ready picture remains registered after claiming; it will animate on later openings while still parented. There is no need to hypothesize duplicate registration in this caller: its boolean guard already prevents that.

### Proposed change

Remove the whole-calendar-tile pulse. Keep the tile border, day number, status and amount stationary. Let only the currently claimable picture use the existing 6-degree / 0.5-cycle breathing treatment, with the claim button's existing glint as secondary emphasis. Do not accelerate either.

Add an optional motion handle to Skin.breathe with enable/disable and destroy semantics. Existing callers may ignore the return value. Repeated registration for the same GUI/kind must update or reuse the registration, not append another writer. Cache the original rotation and owned scale; disabling restores those values. Do not reset unrelated PressScale/PopScale or external animation properties.

Rewards retains a handle per image and updates its enabled state from `isNext and canClaim`. Stop on successful state transition, not optimistically on click. Pending state may suspend decorative motion while retaining explicit text. Keep the four-Hz countdown/data render cadence; moving that entire function to RenderStepped is unnecessary.

### Acceptance

In an isolated Studio test state, open a claimable day, claim successfully, close/reopen, and advance the fixture to a different ready day. Only the active day's picture moves. Claimed amount/check/status stay readable; no outer tile stepping. Duplicate handle requests do not add registrations. Do not advance a production save or change server reset rules to stage this review.

## 2. Make closed/hidden UI actually suspend decorative work

### Source evidence

Skin has several different execution paths:
- breathe/spin share one RenderStepped loop (357–404). onScreen checks the object's own Visible and nearest ScreenGui.Enabled. Skin.window.hide disables its ScreenGui (680–689), so **these animations already skip ordinary closed Skin windows**.
- onScreen does not inspect hidden intermediate GuiObjects. A child can pass the helper while its ancestor tab/content frame is hidden.
- glint (around 236–270) uses its own task loop. It checks gui.Visible, SkinState and presence of a LayerCollector, but not ScreenGui.Enabled or ancestor visibility. A parented button in a disabled window can still start shine tweens.
- sparkle (1009–1031) has a separate task loop and starts tweens while parented, without visibility checks.
- The living loop prunes unparented objects but remains connected after its list empties.
- UI_STYLE_V3's statement that everything looping uses one loop and skips closed screens is broader than the implementation. This is a source/documentation discrepancy, not a measured FPS claim.

### Proposed change

Create one effective-visibility policy for decorative UI: owning ScreenGui enabled, relevant GuiObject ancestors visible, and owner still attached. Apply it to breathe/spin/glint/sparkle. Preserve behavior for any BillboardGui/SurfaceGui callers rather than assuming every LayerCollector is a ScreenGui.

Prefer explicit owner lifecycle notifications and cached visibility over walking every ancestor for every effect every frame. Reparenting and ancestor state changes must invalidate the cache. For the pilot, support closed screens and hidden tabs first; scroller clipping is a separate optimization, not part of this promise.

Cancel in-flight decorative tweens on suspension, restore owned properties, and resume a normal cycle on show. Do not replay missed glints/sparkles in a burst. Keep helper return types compatible: glint/sparkle currently return Frames, so do not replace them with handle tables without updating all callers. Add internal ownership/cancellation or an optional separate handle.

Disconnect the shared render connection when no registrations remain; restart on first registration. Do not disconnect for a merely hidden window if registration ownership is retained.

### Acceptance

Instrument active registrations and started decorative tweens in a temporary review build. After close animation completes, a disabled Rewards screen starts no new glint/sparkle tweens. Hiding an ancestor suspends children even if child.Visible stays true. Show restores normal timing. Destroy/recreate twenty times returns counts to baseline. Record actual counts; do not claim a performance gain without profiling.

## 3. Quiet presentation option, without losing interaction information

Skin has no ReducedMotion reference in the inspected module. This is not a claim that no other game system offers a related setting.

Propose a client presentation policy shared by these four helpers: quiet mode disables idle rotation, swell, glint and sparkle; ready state remains explicit via the stable gold tile, check/status labels and readable claim button. Keep pending/result text, input hitboxes, rewards and remote behavior unchanged. A short opacity change may replace a large pop; no cinematic/server timing changes belong in this pilot.

Roblox's current [GuiService reference](https://create.roblox.com/docs/reference/engine/classes/GuiService#ReducedMotionEnabled) lists ReducedMotionEnabled as hidden/read-only. Verify access and change notifications in the target Studio/client before depending on it; documentation presence alone is not runtime proof. If inaccessible, keep a local presentation option with safe defaults. Do not introduce a new saved field or economy migration just for this prototype.

Acceptance: switching quiet mode while open or hidden restores owned transforms and leaves every status understandable. Switching back never duplicates registrations. Test touch and mouse; essential information must not depend on hover.

## Delivery boundary for Claude

1. Work in appropriate src working copies after fresh export/merge review; never hand-edit the read-only studio snapshot.
2. Implement the narrow Daily Rewards motion pilot and compatible Skin lifecycle support.
3. Record ready → pending → claimed, hide/show, hidden ancestor and quiet-mode captures at matching camera/viewport sizes.
4. Review shared consumers (Shop, Travel, HUD tiles) for regressions before wider rollout. Keep their current v3 art and approved motion character.
5. Update the overbroad lifecycle sentence in UI_STYLE_V3 to match actual behavior after implementation.

No reward amounts, eligibility, claims, DataStores, remotes, purchase logic, map assets or boss geometry are part of this task. The reference informs visual restraint; the proposed lifecycle work comes from current project source.


## Follow-up — button states must have different feedback (2026-10-25)

### Additional visual sample

V17 was played muted from 6:30 to 6:41 in the preceding research interval. At [6:41](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=401s), the completed lime Rewards button shows a bright diagonal highlight crossing its face while the white outlined label stays legible. The tutorial's captions describe the shine; they are not game UI. This reinforces stable label/shape hierarchy. **No pending, owned or disabled state was demonstrated in this sample**; the recommendations below derive from our source. Unique video count remains 31. No direct listening, full viewing or new runtime test.

Skin.lua was fetched again on October 25 and still has the audited blob 64b6a7e9422a72fe4f51de2179fb11234bb2dedb.

### Source findings

- Skin.pressable (294–355) groups `disabled`, `pending` and `owned` together. If Activated fires in any of these states, it runs the same four-step rotation sequence: -5, +5, -3, 0 degrees.
- Each activation starts its own yielding sequence. There is no local animation token/debounce in that branch. Rapid activations can therefore leave multiple sequences writing Rotation; this is a code-path finding, not a reproduced visual jitter report.
- Rotation values are absolute and finish at zero. A deliberately tilted button would lose its original tilt if this branch runs.
- Skin.button.setState (496–516) paints the new state and changes text, but does not itself cancel a hover/press tween or settle PressScale. MouseLeave/MouseButton1Up may later settle it; state change alone does not guarantee that.
- A pending button displays “...”; an owned button is gold. The underlying GuiButton remains an input object. Skin's presentation check does **not** cancel other Activated handlers or enforce purchase/reward permissions. Existing caller guards and server validation must remain.

### Proposed behavior table

| State | Label and stable appearance | Feedback on activation |
| --- | --- | --- |
| Default | Existing action and v3 art | Existing squish/ripple; no new gold hover ring |
| Disabled | Muted purple, specific reason available | At most one short restrained refusal cue; retain readable reason |
| Pending | Meaningful short status such as CLAIMING… where space permits | No refusal wiggle and no extra request; keep pending indication stable |
| Owned/claimed | Persistent OWNED/CLAIMED status appropriate to caller | No refusal wiggle; optionally show existing item details if caller already supports it |

Pending is work in progress; owned is a completed state. Neither should visually imply an erroneous action. This is a design recommendation, not a claim about the tutorial.

### Implementation boundary

Keep Skin.button's existing API and normal-state art. In pressable, separate semantic state checks from feedback animation. Use one cancellation token or owned tween sequence per button. Capture the original Rotation before a refusal sequence and apply offsets around it; restore that baseline on completion, cancellation and state change. Do not fight a separate decorative rotation writer: place feedback on an owned wrapper if a caller intentionally animates the same property.

On entry to pending/disabled/owned, cancel owned press/hover tweens and settle PressScale to 1. Observe SkinState changes inside pressable so callers using attributes directly receive the same presentation behavior. Do not modify PopScale, BreatheScale or the layout scale. Destroying the button cancels delayed animation work.

For rapid disabled taps, coalesce the cue while one is active. If a reason toast already exists, update/refresh that one notice rather than creating an additional stack. Preserve the current single-toast policy and its ownership; this task does not require a new global notification manager.

Pilot one daily Claim button and one existing owned Shop pass card. Re-read the actual callers before editing: this research audited the shared Skin implementation, not every screen's purchase handlers. Do not disable the underlying GuiButton in a way that removes the player's access to a useful reason or detail view. Do not infer that cosmetic SkinState is a security boundary.

### Acceptance criteria for implementation

1. Hover/press then transition to pending without moving the pointer: scale settles, pending label stays readable, no success or refusal cue is emitted prematurely.
2. Ten rapid taps on a disabled control: one bounded refusal animation, stable reason, baseline rotation restored.
3. Tap an owned card: no “no” wiggle; intended details behavior, if present, remains.
4. Disable a button whose initial Rotation is -4 degrees: it returns to -4, not zero.
5. Destroy/close during a refusal sequence: no delayed writes to destroyed instances or stale tweens on reopen.
6. Touch and gamepad retain visible activation feedback and access to reasons without hover.
7. Caller debounce and server validation continue to reject duplicate/unauthorized actions; no prices, grants, remotes or permissions change.

These checks are specified for Claude's implementation and have not been run. Keep this follow-up alongside the lifecycle pilot rather than treating it as a new UI restyle.
