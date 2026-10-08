# Economy

Single place for how the economy works. **The live numbers are in `ReplicatedStorage.Shared.Config`** —
this file summarizes them, and `tools/economy_sim.py` mirrors them. Overrides docs/DESIGN.md's
"Cash System & Scaling" section (that was the original pitch: XP-based upgrades, `10 × 1.25^L`, `100 × 2^L`).

## The loop in numbers
| Piece | Rule | Status |
| --- | --- | --- |
| Case payout | `Payout.Base 1200 × 1.25^L × client multiplier × (1 + skin bonus)` | synced |
| Training (level L → L+1) | `TrainBase 800 × TrainGrowth 1.336^L` coins | synced |
| Win chance | `clamp(0.70 + (L − difficulty) × 0.003, 0.45, 0.95)` | design doc — confirm vs Config |
| Non-wins | 70 % settlement (~50 % pay), 30 % mistrial (requeue, no pay) | design doc — confirm |
| Clients | Common ×1 (diff 0), Uncommon ×3 (10), Rare ×8 (25); Epic ×20 (45), Legendary ×50 (70) on fallback NPC | multipliers synced, spawn weights unknown |
| Arrivals | one client every `Formulas.clientInterval(lawyers)` s — more lawyers, faster arrivals; income is capped by arrivals | formula unknown |
| Firm | starts 4 segments × 2 = 8 lawyers; Expand Firm = +1 segment (2 slots), then Hire into each | synced |
| Expand / hire cost | `Config.ExpandCosts`, `Config.UnlockCosts` | values unknown |
| Eggs | Common / Uncommon / Rare / Legendary = 58 / 26.5 / 13 / 2.5 % | synced |
| Skin bonus | +1 / +2 / +5 / +20 % payout | synced |
| Sell duplicate | 750 / 1.5K / 3.75K / 15K, always keeps one copy | synced |
| First egg | free (`Eggs.FreeUsed`) | synced; "guaranteed Uncommon" from design — confirm |
| Egg price | `Config` | unknown |

## Pacing targets
- First egg within **~2 min**, earning **~100–500 coins/s** at that point.
- **Trillions of coins/s** after **~15 h** of play.
- Cases 30 s – 3 min. Design caps (from DESIGN.md §MVP Risk Fixes): total payout multiplier ×2.5,
  win-chance bonus +12 pp, case-time −30 %, XP ×2.0 — enforce server-side.

Latest analysis and what needs attention: [ECONOMY_REVIEW.md](ECONOMY_REVIEW.md).

## How to retune
0. **Never change `Payout.Growth` or `Training.Growth` casually** — their ratio (1.0688) sets the whole curve; a
   0.3 % change moves "1T/s" by ~4 h (see the review). Retune pace with `Training.Base` / `Payout.Base` and costs.
1. Change numbers in `Config` only (never in scripts).
2. Run the Studio sim: `ServerScriptService.Dev.EconomySim` via the disabled `RunEconomySim` (clone `Shared` +
   the sim before requiring, to dodge module caching). Check every pacing target says OK.
3. Copy the changed values into `CONFIG` in `tools/economy_sim.py` (tag them `SYNCED`) and into the table above.

Quick what-ifs without Studio: `python3 tools/economy_sim.py` prints a timeline, the pacing checks and the
`GUESS` values still unsynced. Flags: `--report` (purchases, gaps and prices per window, milestones),
`--sweep [factor]` (how much each tunable moves the targets), `--active 0.2` (courtroom bonus), `--log`
(every purchase), `--hours`, `--seed`. Tests: `python3 -m unittest discover tools`.

### What the Python mirror assumes
- Each client goes to the best-paid free lawyer (player or Manager); each lawyer works one case at a time.
- Greedy player: always buys the action with the shortest payback (save-up time + cost ÷ income gained) —
  train any lawyer, Expand + Hire, or roll an egg. Rushes the first paid egg (hub tutorial step).
- AFK baseline: no courtroom bonus, daily/playtime rewards, desk tiers or lawyer skills.
- Skins: each equipped lawyer needs its own copy (`Eggs.CopiesPerLawyer`; DESIGN.md is ambiguous — confirm).

With the current guesses the mirror hits both targets (first paid egg 0.7 min at 450/s; 1T/s at ~15.8 h),
which agrees with the Studio sim's "all OK" — but treat that as a sanity check until the guesses are synced.

## Known inconsistencies (decide, then fix the doc that's wrong)
- DESIGN.md's payout table doesn't match its own formula `10 × 1.25^L` (e.g. L25 table 2,800 vs formula ~2,650;
  L50 808K vs ~701K). Moot for the live game (Base 1200), but the doc still shows it.
- DESIGN.md's max modifier stack (×1.25 × 1.5 × 1.2 × 1.3 × 2 ≈ ×5.85) exceeds its own ×2.5 cap.
- "Lawyer egg" wording in DESIGN.md's rewards section — eggs roll **skins**, not lawyers.
- "Supreme" is both a rarity tier and a Legendary skill name.
- Skins: "same skin on multiple lawyers" vs "duplicates can be equipped on multiple lawyers" — one copy or one each?
- Skin rarities: live game has 4 (no Epic/Mythic/Supreme yet); DESIGN.md lists 7 with pity at 50/150/300 —
  pity isn't in the live summary; confirm whether it exists.
