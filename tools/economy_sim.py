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

Run:  python3 tools/economy_sim.py [--hours 24] [--seed 1] [--log] [--report] [--active 0.2] [--sweep [2]]
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


def simulate(hours, seed=1, log=False, active_bonus=0.0):
    """Run one player for `hours`. Returns a dict with the timeline, every purchase and milestones.
    active_bonus: extra payout share for a player who attends court (design: +15-30 %); 0 = AFK."""
    rng = random.Random(seed)
    firm = Firm()
    t = 0.0
    end = hours * 3600
    res = {"rows": [], "events": [], "first_egg": None, "trillion_at": None, "skin_first": {},
           "all_legendary_at": None, "runaway_at": None, "hours": hours}
    checkpoints = [m * 60 for m in CHECKPOINTS_MIN if m * 60 <= end]
    mult = 1 + active_bonus

    def income():
        return firm.income() * mult

    def note_skins():
        for s in firm.skins:
            if s and s not in res["skin_first"]:
                res["skin_first"][s] = t
        if res["all_legendary_at"] is None and all(s == "Legendary" for s in firm.skins):
            res["all_legendary_at"] = t

    def snapshot(at):
        res["rows"].append((at, income(), len(firm.levels), sum(firm.levels) / len(firm.levels),
                            max(firm.levels), firm.eggs_paid,
                            max((s for s in firm.skins if s), key=SKIN_BONUS.get, default="-")))

    if CONFIG["Eggs"]["FreeFirst"]:
        firm.open_egg(CONFIG["Eggs"]["FreeFirstRarity"])
        note_skins()

    while t < end:
        inc = income()
        rush = CONFIG["Eggs"]["RushFirstPaid"] and res["first_egg"] is None
        if res["trillion_at"] is None and inc >= 1e12:
            res["trillion_at"] = t
        if inc >= 1e40:                    # payout outgrows costs: the economy has no ceiling
            res["runaway_at"] = t
            break
        # pick the action that pays itself back soonest (including the time to save up)
        best = None
        for name, cost, gain, apply in firm.actions():
            if rush and name != "egg":
                continue
            if gain <= 0 and not rush:
                continue
            gain *= mult
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
            if res["first_egg"] is None:
                res["first_egg"] = (t, inc)
            firm.open_egg(roll_skin(rng))
            note_skins()
        else:
            apply()
        res["events"].append((t, name, cost, inc))   # inc = income while saving up for it
        if log:
            print(f"  {t / 60:8.2f} min  {name:<6} {format_coins(cost):>10}  -> {format_coins(income())}/s")
    for c in checkpoints:
        snapshot(c)
    res["final"] = {"lawyers": len(firm.levels), "segments": firm.segments, "levels": list(firm.levels)}
    return res


def fmt_time(sec):
    if sec is None:
        return "never"
    if sec < 90:
        return f"{sec:.0f}s"
    if sec < 5400:
        return f"{sec / 60:.1f}m"
    return f"{sec / 3600:.1f}h"


def pacing_checks(res):
    """[(ok, text)] for the CONFIG targets."""
    tg = CONFIG["Targets"]
    out = []
    if res["first_egg"]:
        t, inc = res["first_egg"]
        lo, hi = tg["IncomeAtFirstEgg"]
        ok = t <= tg["FirstEggMinutes"] * 60 * 1.5 and lo <= inc <= hi
        out.append((ok, f"first paid egg at {fmt_time(t)}, earning {format_coins(inc)}/s "
                        f"(target ~{tg['FirstEggMinutes']} min, {lo}-{hi}/s)"))
    else:
        out.append((False, "never bought a paid egg"))
    ta = res["trillion_at"]
    ok = ta is not None and ta <= tg["TrillionPerSecHours"] * 3600 * 1.2
    out.append((ok, f"1T coins/s at {fmt_time(ta)} (target ~{tg['TrillionPerSecHours']} h)"))
    return out


# ----------------------------------------------------------------------------------------
# Reports
# ----------------------------------------------------------------------------------------
WINDOWS_H = [(0, 0.25), (0.25, 1), (1, 2), (2, 4), (4, 8), (8, 12), (12, 16), (16, 24)]


def print_timeline(res):
    print(f"\n{'Time':>8} {'Coins/s':>10} {'Lawyers':>8} {'Avg lvl':>8} {'Top lvl':>8} {'Eggs':>6}  Best skin")
    for at, inc, n, avg, top, eggs, skin in res["rows"]:
        label = f"{at / 3600:.0f}h" if at >= 3600 else f"{at / 60:.0f}m"
        print(f"{label:>8} {format_coins(inc):>10} {n:>8} {avg:>8.1f} {top:>8} {eggs:>6}  {skin}")


def print_report(res):
    """Where does the pacing feel bad? Purchases per window, longest dry spell, what's being bought."""
    ev = res["events"]
    print("\nPacing by window (purchases = things the player gets to click; long gaps feel like a wall)")
    print(f"{'Window':>11} {'Buys':>6} {'Train':>6} {'Expand':>7} {'Eggs':>6} {'Median gap':>11} {'Longest gap':>12}"
          f" {'Train price':>12} {'Egg price':>10}")
    for a, b in WINDOWS_H:
        if a >= res["hours"]:
            break
        lo, hi = a * 3600, min(b, res["hours"]) * 3600
        inside = [e for e in ev if lo <= e[0] < hi]
        times = [lo] + [e[0] for e in inside] + [hi]
        gaps = sorted(y - x for x, y in zip(times, times[1:]))
        count = lambda n: sum(1 for e in inside if e[1] == n)
        med = gaps[len(gaps) // 2] if gaps else 0

        def price(n):   # median price in seconds of income (DESIGN.md: next upgrade ~10 min of earning)
            p = sorted(e[2] / e[3] for e in inside if e[1] == n)
            return fmt_time(p[len(p) // 2]) if p else "-"
        print(f"{a:>4g}-{b:<4g}h {len(inside):>6} {count('train'):>6} {count('expand'):>7} {count('egg'):>6} "
              f"{fmt_time(med):>11} {fmt_time(max(gaps) if gaps else 0):>12} {price('train'):>12} {price('egg'):>10}")

    print("\nMilestones")
    for r in CONFIG["Eggs"]["Skins"]:
        print(f"  first {r:<10} skin: {fmt_time(res['skin_first'].get(r))}")
    print(f"  every lawyer in Legendary: {fmt_time(res['all_legendary_at'])}"
          "  (after this, eggs no longer raise income)")
    exp = [e for e in ev if e[1] == "expand"]
    print(f"  expansions: {len(exp)} (" + ", ".join(fmt_time(e[0]) for e in exp[:12])
          + (" ..." if len(exp) > 12 else "") + ")")
    late_eggs = sum(1 for e in ev if e[1] == "egg" and res["all_legendary_at"] and e[0] > res["all_legendary_at"])
    if late_eggs:
        print(f"  eggs bought after full Legendary: {late_eggs}")
    lv = res["final"]["levels"]
    print(f"  final levels: min {min(lv)}, max {max(lv)}, lawyers {len(lv)}")


# which CONFIG values the sweep perturbs: (label, path)
SWEEP = [
    ("CaseSeconds", ("CaseSeconds",)),
    ("ClientInterval", ("ClientInterval", "PerLawyerSeconds")),
    ("ExpandCostBase", ("Firm", "ExpandCostBase")),
    ("ExpandCostGrowth", ("Firm", "ExpandCostGrowth")),
    ("HireCostShare", ("Firm", "HireCostShare")),
    ("Eggs.Price", ("Eggs", "Price")),
    ("Payout.Base", ("Payout", "Base")),
    ("Training.Base", ("Training", "Base")),
    ("Payout.Growth", ("Payout", "Growth")),
    ("Training.Growth", ("Training", "Growth")),
]


def _get(path):
    d = CONFIG
    for k in path[:-1]:
        d = d[k]
    return d, path[-1]


def run_sweep(hours, seed, factor):
    """Scale each value by 1/factor and xfactor (growth rates: their excess over 1) and show the targets."""
    def summary(res):
        fe = res["first_egg"]
        runaway = f"  RUNAWAY at {fmt_time(res['runaway_at'])}" if res["runaway_at"] is not None else ""
        return (f"{fmt_time(fe[0]) if fe else 'never':>7} @ {format_coins(fe[1]) if fe else '-':>6}/s  "
                f"1T {fmt_time(res['trillion_at']):>6}{runaway}")

    print(f"\nSensitivity: each value scaled by 1/{factor:g} and x{factor:g} "
          "(growth rates scale their excess over 1)")
    print(f"{'baseline':<18} {summary(simulate(hours, seed))}")
    for label, path in SWEEP:
        d, k = _get(path)
        orig = d[k]
        parts = []
        for f in (1 / factor, factor):
            d[k] = 1 + (orig - 1) * f if "Growth" in k else orig * f
            client_stats.cache_clear()
            parts.append(summary(simulate(hours, seed)))
        d[k] = orig
        client_stats.cache_clear()
        print(f"{label:<18} low:  {parts[0]}\n{'':<18} high: {parts[1]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--hours", type=float, default=24)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--log", action="store_true", help="print every purchase")
    ap.add_argument("--report", action="store_true", help="pacing diagnostics: gaps, purchase mix, milestones")
    ap.add_argument("--active", type=float, default=0.0, metavar="BONUS",
                    help="model an active player with this courtroom payout bonus (e.g. 0.2)")
    ap.add_argument("--sweep", type=float, nargs="?", const=2.0, metavar="FACTOR",
                    help="sensitivity of the targets to each tunable (default factor 2)")
    args = ap.parse_args()

    if args.sweep:
        run_sweep(args.hours, args.seed, args.sweep)
    else:
        res = simulate(args.hours, args.seed, args.log, args.active)
        print_timeline(res)
        if args.report:
            print_report(res)
        print("\nPacing targets")
        for ok, text in pacing_checks(res):
            print(f"  [{'OK' if ok else 'MISS'}] {text}")
        if res["runaway_at"] is not None:
            print(f"  [MISS] income ran away (>1e40/s) at {fmt_time(res['runaway_at'])} - payout outgrows costs")

    print("\nGUESS values (only Studio's Config has the real numbers - sync before trusting results):")
    print("  " + ", ".join(GUESSES))


if __name__ == "__main__":
    main()
