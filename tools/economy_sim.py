"""
Hatch a Lawyer & Get Rich! - offline economy simulator (Python mirror).

The authoritative sim is ServerScriptService.Dev.EconomySim in Studio, which reads the
live ReplicatedStorage.Shared.Config. This file mirrors it so economy work can happen
without Studio (cloud sessions, quick what-ifs). Keep the two in sync - see docs/ECONOMY.md.

Every tunable lives in CONFIG below, named like the Luau Config keys. Each value is tagged:
  SYNCED - matches the live Config (as recorded in docs/ECONOMY.md)
  GUESS  - the real value is only in Studio; replace it with the Config value when known
The run prints every GUESS so results are never mistaken for the real tuning.

Model (expected values, event-driven, greedy player):
  - Clients arrive every Formulas.clientInterval(lawyers) seconds; each lawyer works one
    case at a time; mistrials requeue (extra attempt, no pay). Income = served clients/s
    x average expected pay per client (clients split evenly across lawyers, like the Manager).
  - The player always buys the action with the shortest payback time
    (time to save up + cost / income gained): train the lowest lawyer, expand + hire,
    or roll an egg. AFK baseline: no courtroom bonus, no daily/playtime rewards.

Run:  python3 tools/economy_sim.py [--hours 15] [--seed 1] [--log]
"""

import argparse
import math
import random
from functools import lru_cache

# ----------------------------------------------------------------------------------------
# CONFIG - mirror of ReplicatedStorage.Shared.Config (edit here, then rerun)
# ----------------------------------------------------------------------------------------
CONFIG = {
    "Payout": {"Base": 1200, "Growth": 1.25},            # SYNCED  Base x Growth^L
    "Training": {"Base": 800, "Growth": 1.336},           # SYNCED  cost L -> L+1 = Base x Growth^L
    "StartLevel": 1,                                      # GUESS
    "CaseSeconds": 45,                                    # GUESS   design: 30 s - 3 min
    "Outcomes": {                                         # design-doc values; GUESS if Config differs
        "WinBase": 0.70, "WinPerLevel": 0.003, "WinMin": 0.45, "WinMax": 0.95,
        "NonWinToSettlement": 0.70,                       # rest are mistrials (requeue, no pay)
        "SettlementPayout": 0.50,                         # design: 40-60 %
    },
    "Clients": {   # tier: (spawn weight GUESS, payout multiplier SYNCED, difficulty from design)
        "Common":    (0.60, 1, 0),
        "Uncommon":  (0.28, 3, 10),
        "Rare":      (0.10, 8, 25),
        "Epic":      (0.015, 20, 45),
        "Legendary": (0.005, 50, 70),
    },
    # Formulas.clientInterval(lawyers): seconds between arrivals. GUESS shape and numbers.
    "ClientInterval": {"PerLawyerSeconds": 64, "Min": 0.25},  # interval = max(Min, 64 / lawyers)
    "Firm": {
        "StartSegments": 4,                               # SYNCED  8 starting lawyers
        "SlotsPerSegment": 2,                             # SYNCED
        "MaxSegments": 25,                                # GUESS
        # Config.ExpandCosts[k] = cost of expansion k (k = 1 is the first one bought). GUESS
        "ExpandCostBase": 250_000, "ExpandCostGrowth": 9.0,
        # Config.UnlockCosts = cost to hire a lawyer into a new slot. GUESS (x expand cost)
        "HireCostShare": 0.25,
    },
    "Eggs": {
        "Price": 20_000,                                  # GUESS
        "FreeFirst": True,                                # SYNCED  (Eggs.FreeUsed)
        "FreeFirstRarity": "Uncommon",                    # design rule; GUESS if implemented
        "RushFirstPaid": True,     # player saves for the first paid egg before anything else (hub tutorial step)
        # rarity: (odds, payout bonus, sell value)        SYNCED
        "Skins": {
            "Common":    (0.58,  0.01,    750),
            "Uncommon":  (0.265, 0.02,  1_500),
            "Rare":      (0.13,  0.05,  3_750),
            "Legendary": (0.025, 0.20, 15_000),
        },
        "CopiesPerLawyer": True,   # GUESS: each equipped lawyer needs its own copy (vs one copy for all)
    },
    "Targets": {                                          # SYNCED  pacing targets
        "FirstEggMinutes": 2,
        "IncomeAtFirstEgg": (100, 500),
        "TrillionPerSecHours": 15,
    },
}

GUESSES = [
    "StartLevel", "CaseSeconds", "Outcomes (if Config differs from design)", "Clients spawn weights",
    "ClientInterval", "Firm.MaxSegments", "Firm.ExpandCost*", "Firm.HireCostShare", "Eggs.Price",
    "Eggs.FreeFirstRarity", "Eggs.RushFirstPaid", "Eggs.CopiesPerLawyer",
]

# ----------------------------------------------------------------------------------------
# Formulas - mirror of ReplicatedStorage.Shared.Formulas
# ----------------------------------------------------------------------------------------
SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


def format_coins(n):
    if n < 1000:
        return f"{n:.0f}"
    i = min(int(math.log10(n) // 3), len(SUFFIXES) - 1)
    return f"{n / 1000 ** i:.2f}{SUFFIXES[i]}"


def win_chance(level, difficulty):
    o = CONFIG["Outcomes"]
    return min(o["WinMax"], max(o["WinMin"], o["WinBase"] + (level - difficulty) * o["WinPerLevel"]))


def base_payout(level):
    p = CONFIG["Payout"]
    return p["Base"] * p["Growth"] ** level


def train_cost(level):
    t = CONFIG["Training"]
    return t["Base"] * t["Growth"] ** level


@lru_cache(maxsize=None)
def client_stats(level):
    """(expected pay per client / base payout, expected case attempts per client)."""
    o = CONFIG["Outcomes"]
    total_w = sum(w for w, _, _ in CONFIG["Clients"].values())
    pay = attempts = 0.0
    for w, mult, diff in CONFIG["Clients"].values():
        win = win_chance(level, diff)
        settle = (1 - win) * o["NonWinToSettlement"]
        mistrial = 1 - win - settle
        tries = 1 / (1 - mistrial)
        pay += w / total_w * mult * (win + settle * o["SettlementPayout"]) * tries
        attempts += w / total_w * tries
    return pay, attempts


def client_interval(lawyers):
    c = CONFIG["ClientInterval"]
    return max(c["Min"], c["PerLawyerSeconds"] / lawyers)


def expand_cost(k):
    f = CONFIG["Firm"]
    return f["ExpandCostBase"] * f["ExpandCostGrowth"] ** (k - 1)


def hire_cost(k):
    return expand_cost(k) * CONFIG["Firm"]["HireCostShare"]


SKIN_BONUS = {r: b for r, (_, b, _) in CONFIG["Eggs"]["Skins"].items()}


def roll_skin(rng):
    x, acc = rng.random(), 0.0
    for rarity, (odds, _, _) in CONFIG["Eggs"]["Skins"].items():
        acc += odds
        if x < acc:
            return rarity
    return rarity


# ----------------------------------------------------------------------------------------
# Firm state
# ----------------------------------------------------------------------------------------
class Firm:
    def __init__(self):
        f = CONFIG["Firm"]
        n = f["StartSegments"] * f["SlotsPerSegment"]
        self.levels = [CONFIG["StartLevel"]] * n
        self.skins = [None] * n
        self.segments = f["StartSegments"]
        self.expansions = 0
        self.coins = 0.0
        self.eggs_paid = 0
        self.kept = set()          # rarities with a spare copy kept in the collection

    def income(self, levels=None, skins=None):
        """Coins/s when each client goes to the best-paid free lawyer (player or Manager)."""
        levels = levels or self.levels
        skins = skins or self.skins
        desks = []
        for lvl, skin in zip(levels, skins):
            p, tries = client_stats(lvl)
            pay = base_payout(lvl) * p * (1 + (SKIN_BONUS[skin] if skin else 0))
            desks.append((pay, 1 / (CONFIG["CaseSeconds"] * tries)))   # (pay per client, clients/s)
        left = 1 / client_interval(len(levels))
        total = 0.0
        for pay, rate in sorted(desks, reverse=True):
            take = min(left, rate)
            total += take * pay
            left -= take
            if left <= 0:
                break
        return total

    def _place(self, skins, rarity):
        """Equip `rarity` on the best lawyer it improves, cascading the displaced skin down.
        Returns the skin left over (None if it filled an empty slot)."""
        order = sorted(range(len(skins)), key=lambda j: -self.levels[j])
        for j in order:
            if SKIN_BONUS[rarity] > SKIN_BONUS.get(skins[j], 0):
                rarity, skins[j] = skins[j], rarity
                if rarity is None:
                    return None
        return rarity

    # each action: (name, cost, income gain, apply())
    def actions(self):
        inc = self.income()
        out = []

        seen = set()
        for i, lvl in enumerate(self.levels):        # one candidate per distinct level
            if lvl in seen:
                continue
            seen.add(lvl)
            lv = list(self.levels)
            lv[i] += 1
            out.append(("train", train_cost(lvl), self.income(levels=lv) - inc,
                        lambda i=i: self._train(i)))

        if self.segments < CONFIG["Firm"]["MaxSegments"]:
            k = self.expansions + 1
            slots = CONFIG["Firm"]["SlotsPerSegment"]
            cost = expand_cost(k) + slots * hire_cost(k)
            gain = self.income(levels=self.levels + [CONFIG["StartLevel"]] * slots,
                               skins=self.skins + [None] * slots) - inc
            out.append(("expand", cost, gain, self._expand))

        gain = 0.0
        for rarity, (odds, _, _) in CONFIG["Eggs"]["Skins"].items():
            sk = list(self.skins)
            if CONFIG["Eggs"]["CopiesPerLawyer"]:
                self._place(sk, rarity)
            elif SKIN_BONUS[rarity] > SKIN_BONUS.get(sk[0], 0):
                sk = [rarity] * len(sk)
            gain += odds * (self.income(skins=sk) - inc)
        out.append(("egg", CONFIG["Eggs"]["Price"], gain, None))
        return out

    def _train(self, i):
        self.levels[i] += 1

    def _expand(self):
        slots = CONFIG["Firm"]["SlotsPerSegment"]
        self.expansions += 1
        self.segments += 1
        self.levels += [CONFIG["StartLevel"]] * slots
        self.skins += [None] * slots

    def open_egg(self, rarity):
        if not CONFIG["Eggs"]["CopiesPerLawyer"]:
            # one copy dresses every lawyer: equip the best owned rarity everywhere
            self.kept.add(rarity)
            best = max(self.kept, key=SKIN_BONUS.get)
            self.skins = [best] * len(self.skins)
            return
        spare = self._place(self.skins, rarity)
        if spare is None:
            return
        if spare in self.kept or spare in self.skins:   # always keep one copy, sell the rest
            self.coins += CONFIG["Eggs"]["Skins"][spare][2]
        else:
            self.kept.add(spare)


# ----------------------------------------------------------------------------------------
# Simulation
# ----------------------------------------------------------------------------------------
CHECKPOINTS_MIN = [1, 2, 5, 10, 20, 30, 60, 120, 240, 480, 720, 900, 1200, 1440]


def simulate(hours, seed, log):
    rng = random.Random(seed)
    firm = Firm()
    t = 0.0
    end = hours * 3600
    first_egg = None
    trillion_at = None
    rows = []
    checkpoints = [m * 60 for m in CHECKPOINTS_MIN if m * 60 <= end]

    if CONFIG["Eggs"]["FreeFirst"]:
        firm.open_egg(CONFIG["Eggs"]["FreeFirstRarity"])

    def snapshot(at):
        rows.append((at, firm.income(), len(firm.levels), sum(firm.levels) / len(firm.levels),
                     max(firm.levels), firm.eggs_paid,
                     max((s for s in firm.skins if s), key=SKIN_BONUS.get, default="-")))

    while t < end:
        inc = firm.income()
        rush = CONFIG["Eggs"]["RushFirstPaid"] and first_egg is None
        if trillion_at is None and inc >= 1e12:
            trillion_at = t
        # pick the action that pays itself back soonest (including the time to save up)
        best = None
        for name, cost, gain, apply in firm.actions():
            if rush and name != "egg":
                continue
            if gain <= 0 and not rush:
                continue
            wait = max(0.0, cost - firm.coins) / inc
            score = wait + (cost / gain if gain > 0 else 0)
            if best is None or score < best[0]:
                best = (score, wait, name, cost, apply)
        if best is None:
            break
        _, wait, name, cost, apply = best
        # pass checkpoints while saving up
        while checkpoints and checkpoints[0] <= t + wait:
            firm.coins += inc * (checkpoints[0] - t)
            wait -= checkpoints[0] - t
            t = checkpoints.pop(0)
            snapshot(t)
        t += wait
        if t >= end:
            break
        firm.coins = max(0.0, firm.coins + inc * wait - cost)
        if name == "egg":
            firm.eggs_paid += 1
            if first_egg is None:
                first_egg = (t, inc)
            firm.open_egg(roll_skin(rng))
        else:
            apply()
        if log:
            print(f"  {t / 60:8.2f} min  {name:<6} {format_coins(cost):>10}  -> {format_coins(firm.income())}/s")
    for c in checkpoints:
        snapshot(c)
    return rows, first_egg, trillion_at


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--hours", type=float, default=24)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--log", action="store_true", help="print every purchase")
    args = ap.parse_args()

    rows, first_egg, trillion_at = simulate(args.hours, args.seed, args.log)

    print(f"\n{'Time':>8} {'Coins/s':>10} {'Lawyers':>8} {'Avg lvl':>8} {'Top lvl':>8} {'Eggs':>6}  Best skin")
    for at, inc, n, avg, top, eggs, skin in rows:
        label = f"{at / 3600:.0f}h" if at >= 3600 else f"{at / 60:.0f}m"
        print(f"{label:>8} {format_coins(inc):>10} {n:>8} {avg:>8.1f} {top:>8} {eggs:>6}  {skin}")

    tg = CONFIG["Targets"]
    print("\nPacing targets")
    if first_egg:
        t, inc = first_egg
        lo, hi = tg["IncomeAtFirstEgg"]
        ok = t <= tg["FirstEggMinutes"] * 60 * 1.5 and lo <= inc <= hi
        print(f"  [{'OK' if ok else 'MISS'}] first paid egg at {t / 60:.1f} min, earning {format_coins(inc)}/s "
              f"(target ~{tg['FirstEggMinutes']} min, {lo}-{hi}/s)")
    else:
        print("  [MISS] never bought a paid egg")
    if trillion_at is not None:
        ok = trillion_at <= tg["TrillionPerSecHours"] * 3600 * 1.2
        print(f"  [{'OK' if ok else 'MISS'}] 1T coins/s at {trillion_at / 3600:.1f} h "
              f"(target ~{tg['TrillionPerSecHours']} h)")
    else:
        print(f"  [MISS] never reached 1T coins/s in {args.hours:g} h (target ~{tg['TrillionPerSecHours']} h)")

    print("\nGUESS values (only Studio's Config has the real numbers - sync before trusting results):")
    print("  " + ", ".join(GUESSES))


if __name__ == "__main__":
    main()
