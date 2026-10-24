# Mutation decision and result clarity
2026-10-24 · UI-first implementation brief · V29 plus V28 follow-up

## Evidence limits
Fresh main-branch files read:
- `studio/StarterPlayer/StarterPlayerScripts/Merger.client.lua`, blob `97f8744b6cd7902f60662e1f803b651d4f5924e5`.
- `studio/ServerScriptService/Server/LawyerService.lua`, blob `4183158e76d7834f963aa7119034fb692bd33734`.

These are repository snapshots, not proof of current live appearance. Re-export/merge before implementation. No game changes, runtime tests or direct audio listening in this batch.

## Video coverage
### V29 — angel xiao, “#roblox #Ps99x #Combine-O-Matic #Combine a amazing!?”
[Video](https://www.youtube.com/watch?v=frpOHcCqbyU), displayed duration 5:47.

**Identity caution:** the title says Ps99x and footage includes an ADMIN icon. The exact experience and its relationship to official Pet Simulator 99 were not verified. Treat this as a secondary visual reference, not official PS99 gameplay or evidence of popularity.

- [0:07](https://www.youtube.com/watch?v=frpOHcCqbyU&t=7s): machine sits at the end of a broad stair approach; large “Combine-O-Matic / Create GALACTIC Pets!” header; a separate “Combos Left: 21” label. Repeated columns frame the machine. Transfer the focal hierarchy, not the text, limited-stock mechanic or admin features.
- [0:22](https://www.youtube.com/watch?v=frpOHcCqbyU&t=22s): closer machine view shows central luminous oval, flanking structures, a small colored control panel and raised floor strips. Central white glow obscures some detail. A large “our first chroma” overlay is creator-added commentary, not proven game UI.
- [0:45](https://www.youtube.com/watch?v=frpOHcCqbyU&t=45s) and [1:53](https://www.youtube.com/watch?v=frpOHcCqbyU&t=113s): high views dominated by a luminous oval and oversized characters; these are useful cautions about competing silhouettes. The footage does not establish a readable result-card design.

Muted playback samples around 0:00–0:07, 0:08–0:22, 0:34–0:45 and 1:40–1:53; visual observations from endpoint screenshots. Pause overlays obscure the center. No selection/confirmation UI was clearly observed, so the UI proposals below are source-grounded design recommendations, not copied video behavior.

### V28 follow-up
[12:12](https://www.youtube.com/watch?v=5tfzFYsW_og&t=732s), after playback from 12:00: foreground purple fence and large white effects compete with the central subject. Captions mention a supposed glitch; that statement was not verified and is not used. Earlier V28 12:41 shows a mutation-failure message near the bottom; see EGG_INTERACTION_CLARITY. This follow-up does not count as a new video.

## M1 — make the consequence as readable as the reward
**Already present:** exact success percentage on MUTATE and in the result preview; current/next earn multipliers; three input portraits, output portrait, add/remove controls and a help card. Do not replace these with a generic mystery box.

**Source gap:** inspected pre-action copy says “if it works!”; the help card illustrates three-to-one. The explicit “Your lawyers ran off...” text occurs after a fizzle. The server removes all selected lawyers on fizzle, while success retains one upgraded lawyer and consumes the others. It also refuses an attempt that could leave the player with no lawyers.

**Proposed:** keep a short consequence block adjacent to the primary action:
- “Success: 1 [next mutation] lawyer.”
- “Fizzle: all [MergeCount] selected lawyers run off.”
- “[chance]% success” from Formulas.mutateChance, not a separately maintained number.

Use the project's wording; the banned word “lose” is unnecessary. Keep the next-result portrait labeled “Possible result” until success is confirmed. Add the same two outcomes to the existing help card, within the panel on compact screens rather than an offscreen side extension. No extra confirmation modal is required by this proposal.

**Integration:** Merger.renderResult, help card and compact layout; Config.Lawyers.MergeCount and Formulas remain the source of truth. Do not alter odds, consumption or guarantees.

**Acceptance:** before submission, a reader can identify inputs, chance, successful output and fizzle consequence without opening help. Inspect long lawyer names and all mutation tiers at 844×390 and 390×844. Screen copy agrees with server semantics.

## M2 — distinguish selection readiness from eligibility
**Existing:** picker groups by lawyer ID/stars, excludes locked/already-picked/max-tier lawyers, prioritizes groups with enough copies, prefers bench copies and automatically fills spare slots. “CAN MUTATE!” reflects copy count. Server additionally rejects busy/queued lawyers and enforces ownership, distinct IDs and keep-another-lawyer protection.

**Proposed:** change the count-only badge to “ENOUGH COPIES”. Keep selected input portraits persistent, with bench/office location labels when available. When auto-fill includes an office lawyer, make that location visible before submit; do not silently change which copies are chosen. A local prerequisite hint may show known blockers, but must not promise acceptance.

**Boundary:** server still validates every attempt. Do not remove its checks or alter automatic selection priorities as an art task. Preserve lock protection. Identify the exact chosen UIDs and their locations in implementation review, not just a group count.

**Acceptance:** three copies but no spare lawyer; locked copy; busy office copy; queued copy; a bench-first autofill; inventory changed after selection. No “ready” wording that implies server approval from copy count alone.

## M3 — separate pending, rejected, fizzled and succeeded presentation
**Existing:** busy guard, “Mutating...”, input travel animation before InvokeServer; rejected response resets inputs and shows reason; fizzle has grey puff/run-off treatment and 2.4-second result hold; success has flash/burst and 2.2-second hold. worldMutationMoment already exists. This is not a missing-animation feature.

**Proposed state presentation:**
1. Selected: inputs visible, possible result + consequence.
2. Pending: lock action; label “Checking mutation...” or “Mutating...” without showing a successful output.
3. Rejected: “Couldn’t start” with server reason. No run-off/fizzle celebration.
4. Fizzled: “FIZZLED — selected lawyers ran off.” Keep outcome visible until player dismisses or starts a fresh selection.
5. Success: confirmed result name/portrait + next earnings, then a quiet inspection state. Hold until dismiss/new selection rather than relying solely on a short timeout.

The current handler directly invokes the remote without a local protected-call wrapper. Transport exceptions should be handled separately from valid rejected/fizzled responses. An ambiguous transport failure is not proof the attempt failed: do not automatically retry or promise inputs were preserved. Reconcile replicated inventory and give an honest status before allowing another attempt.

**Integration:** Merger.merge/renderResult/clearSlots/worldMutationMoment; existing Effects and Sfx. Preserve authoritative result enum and UID; no new random roll, automatic retry, save-data change or sound layer. Keep transient VFX cleanup independent of the persistent result card.

**Acceptance:** rejection, confirmed fizzle, success, exception, respawn, close/reopen, fast repeated taps and server inventory updates during the animation. One submission per action; no false success; no leftover camera/lighting state. These are future checks, not executed results.

## M4 — frame the existing machine rather than enlarging its glow
V29 supports a readable approach and central machine silhouette, while also showing how strong glow hides detail.

**Proposed pilot:** keep the current MergeMachine gameplay model and animation anchors. Add paired low chunky supports and one broad studded header frame; use a cream sign with dark outlined text and purple accent consistent with the UI. Keep the center and character staging space clear. Place detail on the sides, and verify the existing worldMutationMoment actor path before adding props.

**Integration:** HubMap runtime wiring, approved model builder and Merger worldMutationMoment. Preserve prompt locations, machine model path and gameplay footprint. No imported columns, textures or limited-stock mechanic.

**Acceptance:** arrival/interaction/result views at matching cameras; sign and input/result subjects readable with effects on; no props crossing animation paths. Apply only after the existing cloud bug claim and approved art sequence permit it.

## Handoff
Prioritize M1/M2 (copy and input clarity), then M3 persistent result state, then M4 single-machine blockout. This research adds one distinct sampled video: library now V01–V29. V29 is explicitly secondary/unverified-experience footage; do not cite all 29 as official popular-game examples.
