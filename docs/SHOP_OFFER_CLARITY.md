# Shop offer clarity and compact layout — 2026-10-25

Documentation-only research. Preserve UI v3: Gotham Black/Bold, deep purple body, saturated decorated cards, small pop-ups, no gold hover ring. This is a refinement of the existing shop, not new monetization.

## Evidence

Fresh main snapshots:
- [Shop.client.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/StarterPlayer/StarterPlayerScripts/Shop.client.lua), blob 599730ad81756fedf000be8bce8c5085453dfd76.
- [ShopService.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ServerScriptService/Server/ShopService.lua), blob 8b57bcc420eb47f8f2dfd72ea0948c4298a64c48.
- [Config.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ReplicatedStorage/Shared/Config.lua), blob e763a6f0bd94fd4af2ce46aecc38ec22dd28879c.
- [Skin.lua](https://github.com/crunccy/HatchLawyers/blob/main/studio/ReplicatedStorage/Shared/Skin.lua), blob 64b6a7e9422a72fe4f51de2179fb11234bb2dedb.

Code confirms the shop already has live price fetching, claim prerequisites, owned/pending states, colored side tabs, art, glints and server-side grants. No claim that these features are missing. Actual device screenshots and purchase tests were not performed.

### V30 extended coverage

Elkonn, [Everything You Need To Know PSX CLASSIC in Pet Simulator 99](https://www.youtube.com/watch?v=mrOwwHhgGOI), 12:38. Playback sampled 5:20–5:53, then revisited 5:23–5:32; screenshot inspected at 5:53 and 5:23. Muted, no listening; no full-watch claim.

At [5:53](https://www.youtube.com/watch?v=mrOwwHhgGOI&t=353s), egg models sit on individual pedestals, each with a white price pill and coin symbol; blue cards above show possible pet portraits and percentages. Nearby interaction has an E cue and a separate Auto Hatch control. This supplies a concrete hierarchy: identify object, see price, inspect contents, then act. Tiny displayed probabilities were not transcribed or independently validated.

At [5:23](https://www.youtube.com/watch?v=mrOwwHhgGOI&t=323s), an orange world sign asks “Add Halloween event?” with large voting icons. This is a world poll, not a purchase panel; exclude it from evidence about shop conversion or price labels.

Earlier V30 5:12 shop-card review remains in REWARD_STATE_CLARITY. This batch adds the price/content hierarchy observation, not evidence about live price-loading behavior. Count stays **31 unique videos**.

## SHOP-01 — price and value badge must use the same data

### Source

valueTag computes coins-per-Robux relative to CashJourney's first pass using cached price or Config.Price. It creates a static “+N% more” tag during build. Only afterward does build start GetProductInfo tasks. Successful price fetch updates prices and calls refreshCard, which updates the price button, not the value tag.

Thus a live price differing from Config can update the button while its badge still reflects an earlier comparison. No live price mismatch was measured. This is a conditional inconsistency visible in the implementation.

Cash100K appears both as Featured and in CashJourney. Multiple card instances may represent the same item. Refreshing only the callback's captured card is not a general item-wide refresh policy.

### Proposed change

- Track each item's price as loading/ready/unavailable rather than silently treating an estimate as verified.
- Keep comparison tags hidden until both the item and baseline have usable current prices. A pending price should show “Checking price…” rather than a confident savings claim.
- Store the tag handle and recompute all dependent comparison tags when either price changes. Use the same price record for every card instance of a key.
- Make the comparison basis explicit in a short detail line: “More coins per Robux than 100K pack.” It is not a discount from that item's prior price. Do not include conditional free rewards in this formula unless a separately reviewed calculation explains them.
- If the calculated comparison falls below the existing threshold, remove/hide the tag; if a needed price becomes unavailable, remove the claim.
- Use a build-generation token for asynchronous callbacks so an older shop build cannot update destroyed/replaced cards. Cache data by key separately from presentation instances.
- Native purchase confirmation remains authoritative. Do not change product IDs, regional pricing, Config amounts, Marketplace prompting or server grants.

Acceptance fixtures: item price loads before baseline; baseline before item; one fetch fails; close/reopen during fetch; duplicate Featured/Cash card; later refresh changes the comparison. At every state, displayed price and badge agree. These are presentation fixtures, not instructions to make real purchases.

## SHOP-02 — explain the claim chain before the tap

### Source

Config.CashJourney interleaves one-time paid cash passes and conditional free claims. Existing cash-pack description explicitly says “once per player”; preserve it. FreeRewards has real prerequisites, checked by ShopService.claimFree, and the client correctly blocks locked actions.

However valueTag puts FREE! on free cards whether unlocked or locked. Locked feedback says only “Claim the one before it first!” The nearby predecessor may be a paid purchase, and a three-column wrapping layout can make “before” ambiguous.

### Proposed change

- Keep FREE as a reward cost label but pair it with a visible condition: “Unlocks after [prerequisite display name]”. For a paid prerequisite, use “Requires [pack name] purchase”; for a free predecessor, use “Claim [reward name] first.”
- Give the CashJourney cards persistent small step numbers generated from their order. Avoid animated arrows connecting across a wrapping grid.
- Add a clear section subtitle: “One-time packs and bonus claims.” Retain “once per player” on each paid pack; don't bury it in hover text.
- Locked action area shows LOCKED plus its specific dependency. Available free reward shows CLAIM FREE. Confirmed claim shows CLAIMED. Do not change eligibility or award optimistically.
- A “Show required item” action may scroll to the prerequisite card. It must not open a purchase prompt or auto-claim.
- Distinguish permanent effect passes from one-time coin grants in their descriptions. Keep existing product types and server ownership logic.

Acceptance: new player; first cash pack owned; first free claim available; partially completed chain; all claimed. Read the prerequisite without clicking. Follow a prerequisite link without triggering a transaction. Repeat on touch without hover. Never duplicate the server's grants in client code.

## SHOP-03 — compact cards and honest section shortcuts

### Source and derived sizing

Shop's design canvas is 1000×620. Small cards are 296×300 with a 52-high price button and Info text capped at 19; wide-card price is 64 high. Skin.window fits against height+90 and width plus rail room, clamped 0.38–1.

For an illustrative 844×390 viewport, height fit is 390/710 ≈0.549; width is not tighter even with the 300-wide rail allowance. Small price button becomes about **28.6 screen units** high, wide one **35.2**, and Info cap about **10.4**. These are derived values, not device measurements; actual insets/viewport and rendering need Studio review.

Tabs are created unconditionally for Featured/Passes/Cash/Eggs. The Eggs section exists only when a non-Minutes product with nonzero Id is present. All current Config.Shop.Products IDs are zero, so this snapshot creates no Eggs section, while its tab remains and jumpTo returns without action.

### Proposed change

- Below the existing desktop fit range, reflow into a compact list or two columns only when each card retains readable content and at least a 44-high final-screen primary target. Do not keep shrinking a three-column desktop grid.
- Keep art, item name, effect/quantity, condition and action in that order. Reduce decorative empty space before reducing text. Place the one-time condition adjacent to the quantity.
- Replace the side rail with compact section controls in the narrow layout; header/close remain fixed, content scrolls. Preserve Skin.blockClicks and native purchase confirmation.
- Build shortcuts from actual sections. Omit Eggs while it has no visible content; don't enable zero-ID products to give the tab something to open.
- Recompute active-section styling after layout changes, not solely CanvasPosition changes. Preserve the current section and scroll position during resize where possible.
- Reuse existing art and shared button states. UI_MOTION_LIFECYCLE owns the pending/owned animation fixes; don't create a second button system.

Acceptance: 844×390, 667×375 and a portrait phone viewport; measure final hitboxes and text, inspect long item names and conditional-free labels. Every displayed shortcut reaches content. Closing remains accessible. Scrolling does not accidentally purchase. Inactive/unconfigured items remain inactive. Test reflow without changing purchase state or replaying card animations on every resize.

## Delivery

Start with one CashJourney group and its Featured duplicate. Deliver loading/ready/failure price-state captures, a before/after compact view, and a claim-chain walkthrough using isolated fixtures. Current src working copies must be merged against fresh Studio export before installation; do not hand-edit studio snapshots.

This batch does not change prices, grant amounts, prerequisites, save data, permissions or gameplay. No Studio installation, runtime tests, asset copying, audio audition or publication occurred.
