# Economy

Single place for how the economy works. **The live numbers are in `ReplicatedStorage.Shared.Config`** —
this file summarizes them, and `tools/economy_sim.py` mirrors them (synced with Studio on 2026-10-08, save schema
v12 "hatch real lawyers"). Overrides docs/DESIGN.md's "Cash System & Scaling" section (that was the original
pitch: XP-based upgrades, `10 × 1.25^L`, `100 × 2^L`).

## The loop in numbers (all synced 2026-10-08)
| Piece | Rule |
| --- | --- |
| Start | 4 segments = 8 offices; 1 **Rookie** lawyer (Common) in office 1; office 1 gets 1 free tutorial level |
| Case payout | `Payout.Base 1200 × 1.25^(office level) × client multiplier × capped buffs × outcome × lawyer power` |
| Lawyer power | rarity Earn **×1 / 2 / 4 / 10** (Common / Uncommon / Rare / Legendary) × StarEarn **×1 / 2.5 / 6** |
| Merging | 3 copies of the same lawyer at the same stars → one with +1 star (max 3 stars); keeps the best skills |
| Office upgrade (L → L+1) | `TrainBase 800 × TrainGrowth 1.336^L` coins (`Config.Lawyer`; the level stays with the office), max L100 |
| Office tiers | +0 / 5 / 10 / 20 % payout at L1 / 10 / 30 / 60 (Basic → Oak → Executive → Partner's Suite; automatic) |
| Buff caps | payout ×2.5, win +12 pp, case time −30 % (`Config.Caps`, enforced in `Formulas.combineBuffs`) |
| Skills | each hatched lawyer rolls 1 (Common/Uncommon) or 2 (Rare/Legendary) skills: Fast Talker −6 % time, Organized +5 %, Charming rare clients +25 %, Specialist +20 % vs one client, Silver Tongue +3 pp win, Shark +12 % (per level, max 3) |
| Win chance | `clamp(0.70 + (L − difficulty) × 0.003 + bonus, 0.45, 0.95)` |
| Non-wins | 70 % settlement (40–60 % pay), 30 % mistrial (the whole case reruns, no pay) |
| Clients | Common ×1 (70, diff 0, 30 s), Uncommon ×3 (25, 10, 60 s), Rare ×8 (5, 25, 120 s), Epic ×20 (1, 45, 180 s), 5 Legendary celebrities ×50 (0.06 each, 70, 240 s) |
| Arrivals | one client every `max(1, 3.5 × 8 / working lawyers)` s while one of the **10** waiting seats is free |
| Assigning | the player clicks ASSIGN TO LAWYER; the **Manager** (5e7) auto-assigns. Nothing else assigns (see review §3) |
| Firm | Expand Firm = +1 segment = 2 **empty** offices: 3e7, 6e8, 3e10, 1.5e12, 8e13, 4e15 (segments 5–10); no hiring |
| Eggs | hatch a lawyer: Common / Uncommon / Rare / Legendary = 58 / 26.5 / 13 / 2.5 %; even among that rarity's lawyers (3 / 3 / 4 / 3 in the catalog) |
| Egg price | `7,500 × 1.15^(eggs opened)`; first egg free and guaranteed Uncommon; pity: 50th egg without a Legendary is one |
| Lawyer cap | 150 owned (merge to make room) |

## Pacing targets (`Config.Pacing`)
- First paid egg within **~2 min**, earning **~100–500 coins/s** then.
- First Expand Firm (the old "next desk") around **20–30 min**.
- **Trillions of coins/s** after **10–20 h** of play.

**Current status (sim, live Config):** first egg 40 s at 188/s — OK; first Expand 16 min — slightly early;
1T/s at **68–88 min — far too fast**, then a hard wall at office level 100 around 4 h.
See [ECONOMY_REVIEW.md](ECONOMY_REVIEW.md) for the analysis and the fixes (TrainBase ~10–12K + new offices not
starting at level 1; pre-Manager auto-assign).

## How to retune
0. **Never change `Payout.Growth` or `Lawyer.TrainGrowth` casually** — their ratio (1.0688) sets the whole curve.
   Retune pace with `Lawyer.TrainBase` / `Payout.Base` and costs.
1. Change numbers in `Config` only (never in scripts).
2. Run the Python mirror: `python3 tools/economy_sim.py --report` (and a few `--seed`s). Studio's
   `Dev.EconomySim` is **stale (pre-v12)** until it's ported — don't trust its output.
3. Copy the changed values into `CONFIG` in `tools/economy_sim.py` (tag them `SYNCED`) and into the table above.

Flags: `--report` (purchases, gaps and prices per window, milestones), `--sweep [factor]` (how much each tunable
moves the targets), `--active 0.2` (courtroom bonus, inside the ×2.5 cap), `--afk` (nobody clicks Assign),
`--scenario busy-lawyers,auto-assign,multi-hatch,egg-ramp-10,egg-ramp-20,egg-tiers` (proposed changes, not live),
`--log` (every purchase), `--hours`, `--seed`. Tests: `python3 -m unittest discover tools`.

### What the Python mirror assumes (not Config values; printed on every run)
- `WalkSeconds 6` (derived: ~70 studs from seat to desk at `WalkSpeed` 11; the desk is busy meanwhile),
  `HatchSeconds 4` (derived: server cooldown 2.5 s + hatch animation), `AssignRate 0.5` clients/s for an active
  player before the Manager, `RushFirstPaid` (the tutorial sends you to the egg first).
- Greedy player: always buys the action with the shortest payback (save-up time + cost ÷ income gained) — upgrade an
  office, roll an egg, Expand (judged as a bundle: expand + fill + level the new offices to the firm's median), or the
  Manager. Merges happen when they raise income. Best lawyers sit in the best offices.
- Not modelled: paid skill rolls, Manager upgrades, daily/playtime/offline rewards, prestige.

## Known inconsistencies (decide, then fix the doc that's wrong)
- DESIGN.md's payout table doesn't match its own formula `10 × 1.25^L`. Moot for the live game (Base 1200).
- DESIGN.md's max modifier stack (≈ ×5.85) exceeds its own ×2.5 cap. Live game: buffs capped at ×2.5, but lawyer
  power (up to ×60) and prestige multiply **outside** the cap by design.
- DESIGN.md's tutorial and rewards text still describe skins / the 1-desk office (eggs now hatch lawyers).
- "Supreme" is both a rarity tier and a Legendary skill name.
- The Specialist skill targets one of 9 `Config.Clients` entries (5 are single Legendary celebrities) — see review D.
