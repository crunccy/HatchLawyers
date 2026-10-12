# Economy

Single place for how the economy works. **The live numbers are in `ReplicatedStorage.Shared.Config`** —
this file summarizes them, and `tools/economy_sim.py` mirrors them (synced with Studio on 2026-10-08, save schema
v12 "hatch real lawyers"). Overrides docs/DESIGN.md's "Cash System & Scaling" section (that was the original
pitch: XP-based upgrades, `10 × 1.25^L`, `100 × 2^L`).

## The loop in numbers (synced 2026-10-08; economy pass 2026-10-09 + egg tiers 2026-10-12 are in `src/`, not yet in Studio)
| Piece | Rule |
| --- | --- |
| Start | 4 segments = 8 offices; 1 **Rookie** lawyer (Common) in office 1; office 1 gets 1 free tutorial level |
| Case payout | `Payout.Base 1200 × 1.25^(office level) × client multiplier × capped buffs × outcome × lawyer power` |
| Lawyer power | rarity Earn **×1 / 2 / 4 / 6 / 10 / 25 / 60** (Common / Uncommon / Rare / Epic / Legendary / Mythic / Supreme) × StarEarn **×1 / 2.5 / 6** × the egg's EarnMultiplier (egg tiers, below) |
| Merging | 3 copies of the same lawyer at the same stars → one with +1 star (max 3 stars); keeps the best skills |
| Office upgrade (L → L+1) | `TrainBase 2000 × TrainGrowth 1.37^L` coins (`Config.Lawyer`; the level stays with the office), max L100. UPGRADE ×N / MAX / UPGRADE ALL in the LAWYERS panel (`TrainLawyer(office, count | "max")`, `TrainLawyer("all")`) |
| Office tiers | +0 / 5 / 10 / 20 % payout at L1 / 10 / 30 / 60 (Basic → Oak → Executive → Partner's Suite; automatic) |
| Buff caps | payout ×2.5, win +12 pp, case time −30 % (`Config.Caps`, enforced in `Formulas.combineBuffs`) |
| Skills | each hatched lawyer rolls 1 (Common/Uncommon) or 2 (Rare/Legendary) skills: Fast Talker −6 % time, Organized +5 %, Charming rare clients +25 %, Specialist +20 % vs one client, Silver Tongue +3 pp win, Shark +12 % (per level, max 3) |
| Win chance | `clamp(0.70 + (L − difficulty) × 0.003 + bonus, 0.45, 0.95)` |
| Non-wins | 70 % settlement (40–60 % pay), 30 % mistrial (the whole case reruns, no pay) |
| Clients | Common ×1 (70, diff 0, 30 s), Uncommon ×3 (25, 10, 60 s), Rare ×8 (5, 25, 120 s), Epic ×20 (1, 45, 180 s), 5 Legendary celebrities ×50 (0.06 each, 70, 240 s) |
| Arrivals | one client every `max(1, 3.5 × 8 / working lawyers)` s while one of the **10** waiting seats is free |
| Assigning | the player clicks ASSIGN CLIENT; the **Manager** (5e7) auto-assigns instantly to the best lawyer; before it, a client waiting **12 s** (`Case.SelfAssignAfter`) walks to the first free lawyer by itself (not in the tutorial) |
| Firm | Expand Firm = +1 segment = 2 **empty** offices: 2e7, 6e8, 3e10, 1.5e12, 8e13, 4e15 (segments 5–10); no hiring |
| Eggs | **Briefcase Egg** (starter, Pad2) hatches a lawyer: Common / Uncommon / Rare / Epic / Legendary / Mythic / Supreme = 55.8 / 26 / 11 / 4.5 / 2.5 / 0.16 / 0.04 %; even among that rarity's lawyers in that egg. **Supreme is 1 in 2500 in every egg**; pity (50 eggs) guarantees Legendary, never Mythic / Supreme; Lucky Eggs doubles Rare / Epic / Legendary only |
| Themed eggs = **egg tiers** | `Config.Eggs.Themed`, each only its own lawyers, × the Briefcase price; share the opened count and pity; never free. Each machine **unlocks at a lifetime coins earned** milestone (`UnlockEarned`, `Stats.CoinsEarned`: never resets) and its lawyers earn **`EarnMultiplier`** more — see the table below. In the sim since 2026-10-12 |
| Egg price | `8,000 × 1.22^(eggs opened since your last Supreme) × 3^(Supreme level)` (`Formulas.eggPrice`); first egg free and guaranteed Uncommon; pity: 50th egg without a Legendary is one |
| Supreme (prestige) | a ladder: Supreme N costs `1e10 × 7^N` coins and `min(20, 10 + 2N)` offices with a lawyer; payouts × (1 + N) forever; resets coins, offices, firm size, Manager and the egg ramp (keeps lawyers) |
| Lawyer cap | 150 owned (merge to make room) |

### Egg tiers (2026-10-12)
| Egg | Price × | Odds C / U / R / E / L / M / S % | Unlocks at (lifetime earned) | Lawyers earn × | Opens in the sim (5 seeds) |
| --- | --- | --- | --- | --- | --- |
| Briefcase | 1 | 55.8 / 26 / 11 / 4.5 / 2.5 / 0.16 / 0.04 | start | 1 | — |
| Pet | 2 | 52.7 / 26 / 12 / 6 / 3 / 0.26 / 0.04 | 10M | 1.25 | 11–16 min |
| Brainrot | 3 | 0 / 54.6 / 28 / 9 / 8 / 0.36 / 0.04 | 1B | 1.5 | 22–43 min |
| Food | 4 | 42.5 / 29 / 16 / 7 / 5 / 0.46 / 0.04 | 100B | 2 | 64–96 min |
| Ocean | 8 | 33.3 / 32 / 19 / 7 / 8 / 0.66 / 0.04 | 1Qa | 3 | 3.3–3.8 h |
| Space | 16 | 23 / 32 / 23 / 9 / 12 / 0.96 / 0.04 | 1Qi | 4 | 7.2–8.0 h |

**Epic / Mythic / Supreme (2026-10-12), sim seeds 1–5:** first Epic 14–28 min, first Mythic 14 min–2.8 h, a Supreme
lawyer in 3 of 5 runs (1.7 min, 4.7 h, 7.3 h); first Supreme (prestige) 40–60 min on four seeds, **20 min on the
seed that hatched a Supreme lawyer in minute 2** (the jackpot: ×60 power — kept on purpose, user's call 2026-10-12: don't retune it away); 10 Supremes a day (target 8–14).

Why power and not just odds: per coin, a pricier egg's better odds never beat the Briefcase Egg (a Space Legendary
earned exactly what a Briefcase Legendary did), so the sim player bought only Brainrot eggs and nobody had a reason to
use Food / Ocean / Space. With `EarnMultiplier` each machine hatches lawyers better than the ones already in your
offices, and the unlocks spread new goals across a day. Because lawyers get stronger, `Prestige.CostGrowth` went
5 → 7 to keep ~12–13 Supremes a day.

## Pacing targets (`Config.Pacing`, economy pass 2026-10-09)
- First paid egg within **~2 min**, earning **~100–500 coins/s** then.
- First Expand Firm around **12–30 min**.
- First **Supreme** at **40–80 min**, then **8–14 Supremes** in the first 24 h (rebirth-game norms; replaced
  "1T coins/s at 10–20 h").

**Current status (sim, `src/Config.lua` with egg tiers, seeds 1–5):** first paid egg 43 s at 188/s — OK; first
Expand ~19 min — OK; first Supreme **40–70 min** — OK; **12–13 Supremes** a day — OK; eggs keep selling all day
(44–90 eggs in hours 8–24; before egg tiers 0–2 on four of five seeds). The live Studio game is still the pre-pass
economy (1T/s at ~1.1–1.5 h, then a wall at office level 100 — see [ECONOMY_REVIEW.md](ECONOMY_REVIEW.md)) until
`src/` is pushed. Pre-Manager self-assign is live since 2026-10-08.

## How to retune
0. **Never change `Payout.Growth` or `Lawyer.TrainGrowth` casually** — their ratio (1.0688) sets the whole curve.
   Retune pace with `Lawyer.TrainBase` / `Payout.Base` and costs.
1. Change numbers in `Config` only (never in scripts).
2. Run the Python mirror: `python3 tools/economy_sim.py --report` (and a few `--seed`s). Studio's
   `Dev.EconomySim` is **stale (pre-v12)** until it's ported — don't trust its output.
3. Copy the changed values into `CONFIG` in `tools/economy_sim.py` (tag them `SYNCED`) and into the table above.

Flags: `--report` (purchases, gaps and prices per window, milestones), `--sweep [factor]` (how much each tunable
moves the targets), `--active 0.2` (courtroom bonus, inside the ×2.5 cap), `--afk` (nobody clicks Assign; clients self-assign),
`--scenario busy-lawyers,no-self-assign,multi-hatch,egg-ramp-10,egg-ramp-20,pre-egg-tiers,briefcase-only`
(comparisons, not live),
`--log` (every purchase), `--hours`, `--seed`. Tests: `python3 -m unittest discover tools`.

### What the Python mirror assumes (not Config values; printed on every run)
- `WalkSeconds 6` (derived: ~70 studs from seat to desk at `WalkSpeed` 11; the desk is busy meanwhile),
  `HatchSeconds 4` (derived: server cooldown 2.5 s + hatch animation), `AssignRate 0.5` clients/s for an active
  player before the Manager, `RushFirstPaid` (the tutorial sends you to the egg first).
- Greedy player: always buys the action with the shortest payback (save-up time + cost ÷ income gained) — upgrade an
  office, roll an egg, Expand (judged as a bundle: expand + fill + level the new offices to the firm's median), or the
  Manager. Merges happen when they raise income. Best lawyers sit in the best offices.
- The player only buys an egg when that one hatch raises income right away (plus the chance it completes a
  merge). Real players roll for the collection and for merges several copies away, so the sim **undercounts late
  eggs** — read its egg numbers as a floor.
- Not modelled: paid skill rolls, Manager upgrades, daily/playtime/offline rewards.

## Known inconsistencies (decide, then fix the doc that's wrong)
- DESIGN.md's payout table doesn't match its own formula `10 × 1.25^L`. Moot for the live game (Base 1200).
- DESIGN.md's max modifier stack (≈ ×5.85) exceeds its own ×2.5 cap. Live game: buffs capped at ×2.5, but lawyer
  power (up to ×60) and prestige multiply **outside** the cap by design.
- DESIGN.md's tutorial and rewards text still describe skins / the 1-desk office (eggs now hatch lawyers).
- "Supreme" is now a live lawyer rarity (2026-10-12) **and** the prestige ("go Supreme", Supreme level) **and** a
  Legendary skill name in DESIGN.md. Players may mix up "a Supreme lawyer" and "going Supreme" — consider renaming
  the prestige (e.g. "Supreme Empire" → "Empire") or the rarity.
- The Specialist skill targets one of 9 `Config.Clients` entries (5 are single Legendary celebrities) — see review D.
