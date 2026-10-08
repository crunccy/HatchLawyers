# Economy review — 2026-10-08

What needs attention, from running `tools/economy_sim.py` (timeline, `--report`, `--sweep`, `--active`).
Findings are ranked. Each says whether it is **solid** (it follows from synced Config values or from the
structure of the game) or **depends on guesses** (re-check after syncing the `GUESS` values with Studio).

Reproduce: `python3 tools/economy_sim.py --report`, `--sweep 1.25`, `--sweep 2`, `--active 0.2`.

## Summary
| # | Finding | Confidence | Suggested owner |
| --- | --- | --- | --- |
| 1 | The whole 15 h curve hangs on `Training.Growth / Payout.Growth`; a 0.3 % change moves "1T/s" by 4 h | solid | Config rule (anyone retuning) |
| 2 | A single fixed-price egg is free within minutes; hundreds of eggs per hour | solid | us (eggs are ours) |
| 3 | Pre-Manager AFK income may be zero: clients wait for a manual "Assign" | verify in Studio | us (queue is ours) |
| 4 | Early game is click-spam: a purchase every ~2.5 s, training costs ~5 s of income | solid | mr.robe (TrainLawyer) + us (UI) |
| 5 | After ~7 h there's only "train" left; gaps between purchases grow to 4–6 min | depends on guesses | design decision |
| 6 | ~30 % of lawyers sit idle and are never worth training | depends on guesses | us (clientInterval) |
| 7 | The tutorial in DESIGN.md describes the old 1-desk closet office | solid | us |
| 8 | Sync priority: `CaseSeconds` and `clientInterval` move results most | solid | next local session |

---

## 1. The curve hangs on one ratio (solid)
Per lawyer, a level multiplies payout by `Payout.Growth` (1.25) and the next level costs `Training.Growth` (1.336)
times more. So the payback time of each level grows by **1.336 / 1.25 = 1.0688 per level** (it doubles every
~10.4 levels). That makes income grow like a power of play time, **income ∝ T^k with
k = ln 1.25 / ln 1.0688 ≈ 3.35**. Because k sits on a small difference, tiny changes swing it:

| Training.Growth | k | 1T coins/s at |
| --- | --- | --- |
| 1.30 | 5.7 | 2.4 h |
| 1.33 | 3.6 | 11.4 h |
| **1.336 (live)** | **3.35** | **15.8 h** |
| 1.34 | 3.2 | 19.8 h |
| 1.37 | 2.4 | never in 24 h |

If the ratio gets close to 1 there is no ceiling at all: with `Training.Growth` 1.27 or `Payout.Growth` 1.31 the sim
reaches 1T/s in ~30 min, and at 1.5 payout growth income passes 1e40/s within 2 minutes.
By contrast the **base values move things gently**: `Training.Base` ±25 % → 12.7–19.8 h, `Payout.Base` ±25 % →
11.9–21.1 h.

**Recommendation**
- Treat both growth rates as locked. Retune pacing with `Training.Base` / `Payout.Base` (and costs), not growths.
- Put a comment next to them in `Config`: *"ratio sets the whole curve — run EconomySim before changing either"*.
- Optional: store it as `Training.Growth = Payout.Growth * 1.0688` so nobody changes one without the other.

## 2. The egg goes free (solid)
There's one egg at a fixed price, but income grows ~10⁹× over a session. With the guessed 20K price the sim buys
**207 eggs in the first 15 min** and ~760 in a day; after the first minutes an egg costs **under 1 s of income**.
That's true for any fixed price — ×1000 just delays it by about an hour. Two consequences:
- The hatch animation, not coins, becomes the limit. 200 hatches in 15 min isn't playable, so in practice
  players will stop rolling — and **skins are a real lever** (turning skin bonuses off pushes 1T/s from 15.8 h to
  19.9 h; ×5 bonuses pull it to 8.3 h).
- Eggs stop feeling like a goal you save for, which removes the gacha's pull.

**Recommendation** (pick one, then sim it):
- **Egg tiers in the hub** (Pet Sim style): e.g. Starter / Office / Courthouse / Supreme eggs, each unlocked by a
  firm milestone and priced at a few minutes of income at unlock, with better odds or bigger bonuses. The
  odds board shows each egg's exact odds (still required).
- **Multi-hatch** (×3, then ×8) unlocked by progress, free — so rolling keeps up with income without spam.
- The DESIGN.md caps (total payout ×2.5) limit how big later-egg bonuses can get: decide whether the cap applies
  to skins alone or to the whole stack before adding bigger bonuses.

## 3. AFK before the Manager (verify in Studio)
Clients wait in the waiting room until the player clicks **ASSIGN TO LAWYER** and picks a lawyer; the Manager
auto-assigns later. Unless something else assigns them, **an AFK player earns nothing before buying the Manager**,
which breaks a core design pillar ("AFK earns full base rate"). Also, arrivals come every ~8 s at 8 lawyers
(guess), so an active player clicks Assign + picks a lawyer every few seconds.

**Check in Studio:** what happens when nobody assigns — does the queue fill `WaitSeats` and then drop clients?
**Recommendation:** auto-assign a client to the best free lawyer after it has waited ~10–15 s (manual assigning
stays the faster, active option; the Manager then adds Case Filter / Priority Queue). Or make the Manager cheap
enough to buy in the first ~5 min.

## 4. Early click-spam (solid)
In the first 15 min the sim makes **360 purchases** — one every ~2.5 s — and a training level costs ~5 s of
income. DESIGN.md's balance rule is "next upgrade ≈ 10 min of active earning". Simulator games do allow cheap
early clicks, but 8 lawyers × separate Train buttons is a lot of tapping on a phone.

**Recommendation:** add **Train ×10 / Train Max** to the lawyer card (UI is ours; the `TrainLawyer` remote is
mr.robe's — needs a heads-up for a `count` argument, server-validated). Doesn't change the economy, only the taps.

## 5. A thin late game (depends on guesses)
After ~7 h the sim stops expanding; from 8 h to 24 h every purchase is "train", and the gap between purchases
grows from ~2 min to ~6 min (it grows ∝ play time, from finding 1). Expansion costs barely matter in the sweep
(×2 either way moves 1T by < 1 h), so Expand + Hire is a weak lever compared with training.

**Recommendation:** give hours 6–15 something new to buy: the planned desk tiers (Oak → Executive → Mahogany,
model swap is an open item), rooms from DESIGN.md (Library / Break Room), and mr.robe's prestige. Each one needs a
`Config` entry and a line in the sim so its pacing can be checked.

## 6. Idle lawyers (depends on guesses)
With best-lawyer assignment, the share of lawyers that are busy is `CaseSeconds × attempts / clientInterval per
lawyer` — ~70 % with the guesses (45 s case, 64 s per lawyer). The bottom ~30 % never get clients, so they're
never worth training (sim ends with levels 1…98 in the same firm). Hiring then buys *arrivals*, not workers.

**Recommendation:** after syncing, aim for ~90–100 % busy (so every lawyer matters), e.g. tie
`clientInterval` to case length: `interval = CaseSeconds / lawyers × 1.05`.

## 7. Tutorial is out of date (solid)
DESIGN.md's tutorial starts in a 1-desk Closet Office with an auto-assigned client. The live firm starts with
8 lawyers, a waiting room and the Assign button, so the first two minutes need rewriting: walk to the waiting
room → ASSIGN the first client → watch the scripted win → free egg at the hub. The rules stay (guaranteed first
win, free Uncommon egg, no walls of text).

## 8. What to sync first
In the sweep, the guessed `CaseSeconds` and `clientInterval` move results most (×2 on case time: 1T at 8 h vs
never). Egg price, expansion and hire costs barely move it. Sync `Config` in that order.

## Not covered
Courtroom/evidence bonus (only as a flat `--active` bonus: +15 % → 1T at 13.3 h, +30 % → 11.4 h), lawyer skills,
desk tiers, daily/playtime rewards and prestige — none are in the mirror yet. Random skin luck barely matters
(seeds 1–5 all give 15.8 h).
