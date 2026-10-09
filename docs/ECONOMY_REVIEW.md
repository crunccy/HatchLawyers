# Economy review — 2026-10-08 (re-run after syncing with Studio)

What needs attention, from running `tools/economy_sim.py` after it was synced with the live
`ReplicatedStorage.Shared.Config` / `Formulas` and the server scripts (local session, 2026-10-08).

**The live game changed under the first review.** The first pass (earlier the same day, cloud session) analysed the
v11 loop: 8 starting lawyers trained with coins, Hire into new slots, skins as +1–20 % payout buffs. The live game is
now **save schema v12, "hatch real lawyers"** (built in Studio the same day): 1 Rookie in office 1 and 7 empty
offices; eggs hatch real lawyers (rarity Earn ×1/2/4/10, merge stars ×1/2.5/6, 1–2 random skills); levels belong to
**offices**; Expand Firm adds 2 empty offices (no hiring); the egg price grows ×1.15 per egg. So the sim's core loop
was rewritten to match, not just its numbers — see "What was different" below.

Reproduce: `python3 tools/economy_sim.py --report`, `--sweep 1.25`, `--afk`, `--active 0.2`,
`--scenario <name>` (list: `busy-lawyers`, `auto-assign`, `multi-hatch`, `egg-ramp-10`, `egg-ramp-20`, `egg-tiers`).
Results below are seed 1 unless a range over seeds 1–5 is given.

## Summary
| # | Finding | Status after sync | Confidence | Owner |
| --- | --- | --- | --- | --- |
| A | **The economy runs ~10× too fast:** 1T coins/s at **1.1–1.5 h** (target 10–20 h) | **new** | solid (synced) | Config (us) |
| B | **Hard wall at office level 100:** every office maxed by ~4.3 h, income flat at ~74T/s after that | **new** (replaces old §5) | solid | Config + design |
| 1 | The curve hangs on `TrainGrowth / Payout.Growth` | **still holds** (same ratio; now also bounded by `MaxLevel`) | solid | Config rule |
| 2 | Eggs are close to free | **changed:** the ×1.15 ramp is live, but eggs still cost ~1 s of income for the first hour | solid | us |
| 3 | AFK before the Manager earns nothing | **confirmed in Studio** — and an AFK player can never afford the Manager | solid (code read) | us (queue) |
| 4 | Early click-spam | **still holds, worse:** 382 purchases in the first 15 min, an office upgrade every ~1 s | solid | us (Hud + LawyerService) |
| 5 | Thin late game | **changed:** now a hard wall (B) instead of slowly growing gaps | solid | design |
| 6 | ~30 % of lawyers idle | **reversed:** lawyers are the bottleneck; the waiting room is always full | solid | — |
| 7 | Tutorial in DESIGN.md is out of date | **still holds** (the in-game hints/guide were updated for v12; the doc wasn't) | solid | us |
| 8 | Sync `CaseSeconds` / `clientInterval` first | **done** — and neither matters much any more (see 6) | — | — |
| C | Retuning office costs alone stalls expansions (new offices start at level 1) | **new** | solid | design |
| D | Specialist skill almost always targets a 0.06 % client | **new** | solid (code read) | mr.robe (SkillService/Formulas) |
| E | Studio's `Dev.EconomySim` is stale (pre-v12) | **new** | solid | next local session |

---

## What was different between the sim and the real game
| Sim assumed (first review) | Real game (synced 2026-10-08) |
| --- | --- |
| 8 trainable lawyers at start; Hire into new slots | 1 Rookie (office 1, +1 free tutorial level); 7 empty offices; **no hiring** — lawyers come from eggs |
| Skins: +1 / 2 / 5 / 20 % payout, one copy per lawyer | Hatched **lawyers**: Earn ×1 / 2 / 4 / 10 by rarity × StarEarn 1 / 2.5 / 6; 3 copies of the same lawyer merge (+1 star); 1–2 random skills |
| Levels on lawyers | Levels on **offices** (`TrainBase 800 × 1.336^L`, max 100); office tiers +0 / 5 / 10 / 20 % at L1 / 10 / 30 / 60 |
| One case length, 45 s | Per client entry: 30 / 60 / 120 / 180 / 240 s; weights 70 / 25 / 5 / 1 / 5 × 0.06; mistrials rerun the whole case |
| `clientInterval = 64 / lawyers` | `max(1, 3.5 × 8 / working lawyers)` = 28 s at 1 lawyer, 3.5 s at 8 |
| Clients assigned instantly | ~6 s walk to the desk (desk busy); before the Manager (5e7) only manual clicks assign |
| `ExpandCosts` guessed (250K × 9^k), 25 segments | 6 expansions: 3e7, 6e8, 3e10, 1.5e12, 8e13, 4e15; max 10 segments = 20 offices |
| Fixed 20K egg, 4 s hatch | 7.5K × 1.15^eggs opened; pity at 50; ~4 s per hatch (server cooldown 2.5 s + animation) |
| Courtroom bonus multiplies on top of everything | It's a buff source inside the ×2.5 payout cap (`CourtService` → `combineBuffs`) |
| Income uncapped (runaway possible) | Office `MaxLevel` 100 bounds income (no runaway; test changed accordingly) |

## Baseline (live Config)
| Time | Coins/s | Working / offices | Avg office lvl | Eggs opened | Best lawyer |
| --- | --- | --- | --- | --- | --- |
| 1 min | 317 | 3 / 8 | 2 | 1 | Uncommon |
| 10 min | 4.66M | 8 / 8 | 31 | 40 | Legendary |
| 30 min | 4.62B | 12 / 12 | 57 | 92 | Rainbow Uncommon (×12) |
| 1 h | 180B | 12 / 12 | 75 | 125 | Rainbow Uncommon |
| 2 h | 3.89T | 12 / 12 | 89 | 152 | Rainbow Uncommon |
| 4 h | 51T | 16 / 16 | 99 | 177 | Rainbow Rare (×24) |
| 8–24 h | 72–74T (flat) | 20 / 20 | 100 | 218–230 | Gold Legendary (×25) |

Pacing targets: first paid egg **40 s at 188/s — OK**; first Expand **16 min** (target 20–30) — close;
1T/s **87 min** (seeds: 68–88 min) — **MISS** by ~10×.

## A. The economy runs ~10× too fast (new, solid)
Lawyer power multiplies income (a firm of Rare/Legendary/merged lawyers earns ×10–25 per case) but not office
costs, and real arrivals are ~2.3× the old guess. Office upgrades cost about **1 s of income for the first hour**,
so a greedy player levels every office to ~75 in an hour.

`--sweep 1.25` (seed 1): `Payout.Base` ±25 % → 1T at 67 min–1.9 h; `TrainBase` ±25 % → 71 min–1.8 h;
`TrainGrowth` / `Payout.Growth` ±25 % of their excess → 8.6 min … never (finding 1); `ClientInterval`, `AssignRate`
and `Manager.HireCost` → **no change at all**; `WalkSeconds` and egg prices → ±5 min.

Retuning `TrainBase` alone (5 seeds):
| TrainBase | 1T coins/s at | First Expand | 24 h income |
| --- | --- | --- | --- |
| 800 (live) | 68–88 min | 16 min | 74T (flat from ~8 h) |
| 8,000 | 9.6–13.1 h | 85 min | 17T, still growing |
| **12,000** | **14.2–19.5 h** | 88 min – never | 2–13T |
| 16,000 | 18.7 h – never | 1.8 h – never | 0.8–3.7T |

**Recommendation:** raise `Lawyer.TrainBase` to **~10,000–12,000** (one Config number; keeps the growth ratio
intact) — but only together with fix C, or expansions stop. Re-check the first-egg target afterwards (unchanged in
the sim: office costs don't touch it).

## B. Hard wall at office level 100 (new, replaces old §5)
With the live numbers every office reaches `MaxLevel` 100 by ~4.3 h and all 6 expansions are bought by 4.3 h. From
8 h to 24 h the player buys **12 things in 16 hours** (eggs only, 39 min – 2.2 h apart), and income is flat at
~74T/s. Fix A pushes the wall past 24 h (no office maxed in the sim's day), so A mostly solves B for a first
session. For longer play the game still needs a late-game sink: prestige exists (`PrestigeService`, needs all
20 offices filled) but isn't in the sim yet; raising `MaxLevel` only helps once A is in (with 1.35 growth and
MaxLevel 150 income reaches 2.4Qa/s by 24 h — no wall, but numbers explode).

## 1. The curve hangs on one ratio (still holds)
Unchanged maths (payback per level × 1.0688 → income ∝ T^3.35), now bounded above by `MaxLevel`. Sweep:
`TrainGrowth` 1.27 → 1T in 8.6 min; 1.42 → never. Keep both growth rates locked; tune with `TrainBase`.

## 2. Eggs (changed)
The live egg now ramps ×1.15 per egg (the first review's "price ramp" proposal, steeper than its 2–3 %). Effect:
- First hour: still **~1 s of income per egg** (income grows faster than 1.15 per egg) — 125 eggs in the first hour.
- Merges arrive fast: **first Gold at 2.5 min, first Rainbow at 6 min** (Rainbow Uncommon = ×12). The collection
  chase is mostly over in the first hour.
- Later, eggs cost 2–40 min of income, but they're bought rarely because extra lawyers only help through merges
  once the 20 offices are full.
- With fix A (TrainBase 8,000) eggs stay at ~5–25 s of income all day: still cheap, but income no longer explodes,
  so Rainbow comes at 22 min and Legendaries at 35 min.
Scenarios: `egg-ramp-10` → 1T at 68 min (more eggs, faster); `egg-ramp-20` → 1.6 h; `egg-tiers` (better-odds eggs
unlocked at 1e5 / 1e8 coins/s) → fewer eggs (135/day), first Rainbow at 66 min instead of 6 — the best lever for
making the chase last, but none of them fixes A. `multi-hatch` changes nothing (QoL only).
**Recommendation:** after A, revisit egg tiers (they stretch the merge chase); keep the ×1.15 ramp.

## 3. AFK before the Manager (confirmed in Studio)
Read from the live code (CaseService, FirmBuilder, RewardsService):
- A client walks in only while one of the **10 waiting seats** is free (`CaseService.spawnArrival` → `freeSeat`).
- Seated clients wait **forever** with the ASSIGN TO LAWYER button. Nothing times out and no client is dropped:
  once the 10 seats are full, arrivals simply stop.
- The only auto-assigner is the Manager (`CaseService.autoAssign` returns unless `Manager.Hired`).
- So an AFK player earns **0** until they buy the Manager — and since they earn 0 they can never afford it (sim:
  `--afk` is stuck at 0 s). Meanwhile **offline earnings** (`RewardsService`) pay 50 % of *expected* income for up to
  2 h as if someone had been assigning — online-AFK earns less than logging off.
- An active player never needs the Manager: arrivals (0.29/s at 8 offices, 0.71/s at 20) stay near the assumed
  0.5 assigns/s, so the sim never buys it (5e7 is ~10 min of income).

**Recommendation:** auto-assign a seated client to the best free lawyer after it has waited **~10–15 s** (manual
assigning stays the faster, active option). The queue is ours. Sim: `--afk --scenario auto-assign` matches the
active baseline. Then re-price the Manager as a convenience/upgrade hub (its upgrades are its value).

## 4. Click-spam (still holds, worse)
Baseline: **382 purchases in the first 15 min**, an office upgrade every ~1 s through the first 4 h. With fix A it's
46 in the first 15 min, then an upgrade every ~5 s for hours (12–20 offices × UPGRADE OFFICE).
**Recommendation:** UPGRADE ×10 / MAX on the office card. `TrainLawyer` is now handled by `LawyerService`, which
Claude rewrote for v12 (office upgrades) — add a server-validated `count` argument.

## 5. Late game — see B.

## 6. Idle lawyers (reversed)
Each lawyer is busy ~54 s per client (case ~44 s average × mistrial reruns + 6 s walk) while clients arrive every
`28 / working` s: **arrivals are ~2× what the lawyers can serve**, so every working lawyer is always busy, the 10
seats stay full and `ClientInterval` has no effect (sweep). The old `busy-lawyers` fix is obsolete (the scenario
is kept, retuned to 5.6 s, and changes nothing). If the full waiting room ever feels bad, lower arrivals instead.

## 7. Tutorial (still holds for DESIGN.md)
The live tutorial is now: Assign Neighbor Dave → scripted 10 s win → free Uncommon egg at the hub → put the new
lawyer in an empty office (Hud hint + Guide beam, updated in Studio). DESIGN.md still describes the 1-desk Closet
Office; update its tutorial section.

## C. New offices start at level 1, so expansions stall (new)
An expansion adds two **level-1** offices next to level-50+ ones; catching them up costs `Σ TrainBase × 1.336^L`.
With live costs that's cheap and the sim expands at 16 / 26 min. With fix A it isn't: at TrainBase 12,000 two of five
seeds never expand in 24 h. (The sim judges Expand as a bundle — expand + fill + level up to the firm's median — since
a one-step greedy player would never buy a lone level-1 office.)
**Recommendation:** new offices start at the firm's **lowest office level** (or ~80 % of the median), so Expand is
worth buying the moment you can afford it. Small change in `DeskService.upgradeFirm` (`PlayerData.newDesk` level).

## D. The Specialist skill is nearly worthless (new)
`Formulas.rollSkill` picks Specialist's client as `rng:NextInteger(1, #Config.Clients)` — `Config.Clients` has 9
entries because the 5 Legendary celebrities are separate entries. So 5 / 9 Specialists boost a single celebrity who
is 0.06 % of arrivals, and 1 / 9 boost Epic (1 %). **Recommendation:** pick by client *tier* (Common … Legendary),
weighted toward common tiers, or show the target on the skill card so players can reroll. mr.robe's code — heads-up.

## E. Studio's `Dev.EconomySim` is stale (new)
`ServerScriptService.Dev.EconomySim` was written for v11 (8 lawyers, hire, skins) and hasn't been updated for v12.
The Python mirror is now the accurate one. Next local session: port this mirror's model to Luau or retire it.

## Not covered
Paid skill rolls, Manager upgrades, daily/playtime/offline rewards, prestige, the courtroom beyond a flat bonus
(`--active 0.2` → 1T at 72 min), and inventory limits beyond the 150 cap. Random luck matters more than before:
1T ranges 68–88 min over seeds 1–5 (which lawyers you hatch decides merges).
