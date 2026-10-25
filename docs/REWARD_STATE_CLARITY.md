# Rewards: clear timers, pending claims and readable outcomes
2026-10-24 · V30 · Documentation only

## Current style takes precedence
Freshly read [UI_STYLE_V3.md on main](https://github.com/crunccy/HatchLawyers/blob/main/docs/UI_STYLE_V3.md): Gotham Black for titles/buttons/numbers, Gotham Bold for small text; plain deep-purple window bodies, saturated decorated cards, muted-purple unavailable states, no gold hover ring, and deliberately small pop-ups. This supersedes older research suggestions about Fredoka/LuckiestGuy/BuilderSans, patterned window bodies or grey inactive surfaces. Keep the chunky studded world style.

The current Rewards client already uses Skin.window/Skin.button and a smaller 300×78 reward toast at vertical position 0.42. Do not rebuild the old calendar from the October 23 pre-install export: current main differs.

## Evidence
Fresh main snapshots:
- `studio/StarterPlayer/StarterPlayerScripts/Rewards.client.lua`: `b8bc766d381b2adc6bef09427e6bca041673778b`.
- `studio/ServerScriptService/Server/RewardsService.lua`: `7bb8306f34e3de0e57e5836e000298bcdc8d8d08`.
- Current style document above. Repository evidence does not prove the live game's rendered appearance.

### V30 — Elkonn, Everything You Need To Know PSX CLASSIC in Pet Simulator 99 (Roblox)
[Video](https://www.youtube.com/watch?v=mrOwwHhgGOI), displayed runtime 12:38. Listed as uploaded within the preceding hour when sampled; do not treat the listing as verification of every feature described by the creator.

- [4:02](https://www.youtube.com/watch?v=mrOwwHhgGOI&t=242s), after playback around 3:47–4:02: Season Pass panel has a labeled refresh timer at top, reward pictures with currency amounts, green upper row, lower row with lock and explicit unlock requirement, and a separate Top Prize panel. Transfer clear separation of timer, requirement and reward. Do not copy the pass economy, purchase prompts or scarcity.
- [5:12](https://www.youtube.com/watch?v=mrOwwHhgGOI&t=312s), after playback around 5:03–5:12: Exclusive Shop's large purple offer includes “for 7 days” inside the offer, with explanatory text above. Transfer placing an important condition beside its content. This is a shop sample, not a daily-claim calendar.
- Muted selected playback, inspected endpoint frames only. Pause overlay/captions cover parts of each panel. No direct audio, full-video review, mobile usability measurement or causal popularity claim.

## R1 — distinguish the two timers
**Existing:** DAILY menu tile shows ! for daily claimability, but its note is the playtime countdown. The open calendar's disabled claim button counts down to the next server-day reset; the footer describes active-playtime gift time. The underlying systems intentionally differ.

**Proposed:** label the menu note “Play gift: [time]”; label the calendar reset “Next daily reward: [time]”. Keep active-play explanation in the playtime row. Retain ! only when the daily claim is available. Do not imply the playtime timer unlocks today's daily reward. The server requires both recent activity and recent movement before incrementing active seconds; do not locally decrement through AFK time.

**Integration:** Rewards.render, HudMenu.setNote, dailyState and existing PlaytimeActive attribute. No changes to reset timezone, streak rules, rewards or activity enforcement.

**Acceptance:** daily available/playtime not ready; daily claimed/playtime progressing; AFK; streak reset; last calendar day; server-day boundary while open. Text tells which reward the countdown belongs to. Use replicated progress, not a new local earning timer.

## R2 — add explicit loading and pending presentation
**Existing:** dailyState returns not claimable when DailyLastDay is absent. render then uses the next-reset message, potentially presenting a loading state as a time lock. A claiming flag blocks duplicate handler entry, but render does not display that flag; it can continue showing CLAIM until replicated state changes. The direct InvokeServer call has no local protected-call recovery.

**Proposed:** order states as loading → pending → actionable failure → claimable → next reset. Loading says “Loading rewards...” and pending says “Claiming...”, both with the existing disabled button treatment. Keep the 0.25-second renderer. On transport exception, clear only the local pending presentation safely and reconcile server attributes; do not automatically retry or show a reward that was not confirmed.

**Boundary:** server claim checks and grants remain authoritative. A timeout/exception may occur after a successful grant; never tell the player the reward is definitely unclaimed solely because the response failed.

**Acceptance:** delayed initial attributes, slow reply, valid rejection, transport failure, double taps and successful reply. Exactly one request per accepted action; no permanent pending state, false success or misleading day-reset text during initial loading. Future tests, not executed in this research.

## R3 — preserve small pop-ups while retaining reward meaning
**Existing:** one reusable reward toast with token checks protects against old delayed callbacks hiding a newer toast. Each call replaces title/body. Events include playtime, goal, prestige, shop and offline earnings. Thus the issue is possible replacement of unread information, not an ever-growing pile of panels. Server rewards have already been granted independently of display.

**Proposed:** integrate this producer with the earlier bounded notification-priority policy. Keep the current small footprint and 0.42 slot. A successful daily claim should also leave a quiet inline receipt inside the open calendar (“Day N claimed — [server result text]”) until close/next action, so it survives an unrelated toast. Do not increase pop-up size or create another full-screen celebration.

Wrap the receipt across short lines when needed; avoid shrinking long skill-roll/offline text into unreadability. If an event is coalesced, preserve its amount/kind rather than replacing it with “Rewards received”. Do not sum text strings or infer currency amounts from formatted values.

**Acceptance:** daily claim followed by a goal/playtime event; offline earnings on join while the calendar auto-opens; long lawyer names; duplicate events; GUI hidden for filming. No loss of receipt information, oversized overlays or additional reward grants. This does not assert any current reward was lost.

## R4 — mark calendar states with text as well as color
**Existing:** done tiles use a check, available next day has TODAY, later tiles use purple. A next-but-not-claimable tile can still be gold, without TODAY. Preserve the illustrated tiles and current v3 art.

**Proposed:** explicit small labels: CLAIMED, READY, NEXT. NEXT means next in sequence, not available now. Keep the amount/icon larger than status text; use the exact Config reward description. On compact viewports, show the selected/next tile prominently with a horizontally scrollable sequence if necessary, without moving the claim button offscreen. Prototype only after measuring the actual Skin scale; no current clipping has been demonstrated.

**Acceptance:** complete cycle and day rollover, readable status without relying on gold/green, long amount text, portrait/landscape, stable scroll position. Preserve Skin.blockClicks and existing reward images/ownership.

## Handoff
Implement R1/R2 first, then inline receipt and status labels within the current calendar. Review against current main and UI_STYLE_V3 before touching any older src twin. Source/rules remain authoritative; V30 supplies hierarchy examples, not a replacement design. No Studio edits, installs, publication or runtime tests performed. Coverage now V01–V30.
