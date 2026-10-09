"""
Hatch a Lawyer & Get Rich! - offline economy simulator (Python mirror).

Mirrors the live game in Roblox Studio (ReplicatedStorage.Shared.Config + Formulas, CaseService queue,
LawyerService offices/merges, EggServer) so economy work can happen without Studio. Keep the two in sync -
see docs/ECONOMY.md. Synced against Studio on 2026-10-08 (save schema v12, "hatch real lawyers").

Every Config value below is named like its Luau key and tagged:
  SYNCED    - copied from the live Config / Formulas (2026-10-08)
  DERIVED   - not a Config value; worked out from the live code (e.g. walking distance / WalkSpeed)
  BEHAVIOR  - an assumption about the player, not a game number
The run prints the DERIVED / BEHAVIOR assumptions so results are read with them in mind.

Model (expected values, event-driven, greedy player):
  - Offices have levels (the coin sink); a lawyer sitting in an office earns
    Payout.Base x Growth^level x client multiplier x capped buffs x lawyer power.
    Lawyer power = rarity Earn x StarEarn[stars]; 3 copies of the same lawyer and stars merge (+1 star).
  - Clients walk in every Formulas.clientInterval(working lawyers) s while a waiting seat is free; each
    lawyer works one case at a time (walk to desk + case; mistrials rerun the same case). Clients go to the
    best-paid free lawyer. Before the Manager is hired, an active player assigns at most BEHAVIOR.AssignRate clients/s; for an AFK
    player (--afk) clients self-assign after Config.Case.SelfAssignAfter s of waiting.
  - The player always buys the action with the shortest payback time (time to save up + cost / income
    gained): upgrade an office, roll an egg, expand the firm (+2 empty offices) or hire the Manager.
    Merges happen as soon as they raise income. Lawyers are placed best-first into the best offices.
  - Not modelled: paid skill rolls, Manager upgrades, daily/playtime/offline rewards, prestige,
    the Charming skill's effect on other lawyers' clients is modelled firm-wide (like CaseService).

Run:  python3 tools/economy_sim.py [--hours 24] [--seed 1] [--log] [--report] [--active 0.2] [--afk]
                                   [--sweep [2]] [--scenario NAMES]
"""

import argparse
import math
import random
from functools import lru_cache

# ----------------------------------------------------------------------------------------
# CONFIG - mirror of ReplicatedStorage.Shared.Config (edit here, then rerun)
# ----------------------------------------------------------------------------------------
CONFIG = {
    "Payout": {"Base": 1200, "Growth": 1.25,                       # SYNCED  Base x Growth^level
               "SettlementMin": 0.4, "SettlementMax": 0.6},          # SYNCED
    "Outcome": {"BaseWinChance": 0.70, "PerSkillPoint": 0.003,       # SYNCED  win = clamp(0.70 + (L-diff)x0.003)
                "MinWinChance": 0.45, "MaxWinChance": 0.95,
                "SettlementShareOfNonWins": 0.70},                   # SYNCED  rest = mistrial (case reruns)
    # Config.Clients, in order: (Id, Weight, Multiplier, Difficulty, Duration s)          SYNCED
    # (the five Legendary celebrities are separate entries with weight 0.06 each)
    "Clients": [
        ("Common", 70, 1, 0, 30),
        ("Uncommon", 25, 3, 10, 60),
        ("Rare", 5, 8, 25, 120),
        ("Epic", 1, 20, 45, 180),
        ("Legendary", 0.06, 50, 70, 240),
        ("Legendary", 0.06, 50, 70, 240),
        ("Legendary", 0.06, 50, 70, 240),
        ("Legendary", 0.06, 50, 70, 240),
        ("Legendary", 0.06, 50, 70, 240),
    ],
    # Formulas.clientInterval(n) = max(MinInterval, ClientInterval x StartLawyers / max(n, 1)),
    # n = lawyers WORKING in offices (CaseService.workingLawyers)                          SYNCED
    "Firm": {"StartSegments": 4, "MaxSegments": 10,                  # SYNCED  2 offices per segment
             "StartLawyers": 8, "ClientInterval": 3.5, "MinInterval": 1,
             "ExpandCosts": {5: 3e7, 6: 6e8, 7: 3e10, 8: 1.5e12, 9: 8e13, 10: 4e15},  # SYNCED by segment
             "WaitSeats": 10},                                       # SYNCED  FirmBuilder.SEATS
    "Lawyer": {"StartLevel": 1, "MaxLevel": 100,                     # SYNCED  office levels
               "TrainBase": 800, "TrainGrowth": 1.336},              # SYNCED  cost L -> L+1
    "Tutorial": {"FreeLevelUps": 1},                                 # SYNCED
    # Config.Desks.Tiers: office look + payout bonus by office level: (MinLevel, PayoutBonus)  SYNCED
    "OfficeTiers": [(1, 0.0), (10, 0.05), (30, 0.10), (60, 0.20)],
    "Lawyers": {"StartId": "Rookie", "MergeCount": 3, "StarEarn": [1, 2.5, 6], "MaxOwned": 150},  # SYNCED
    "Eggs": {
        "Price": 7500, "PriceGrowth": 1.15,                          # SYNCED  price = 7500 x 1.15^eggs opened
        "FreeFirstEgg": True, "FirstEggRarity": "Uncommon",          # SYNCED  tutorial egg, not counted
        "PityTop": 50,                                               # SYNCED  50th egg without Legendary = Legendary
        # rarity: (Weight %, Earn, StartSkills)                                             SYNCED
        "Rarities": {
            "Common": (58, 1, 1),
            "Uncommon": (26.5, 2, 1),
            "Rare": (13, 4, 2),
            "Legendary": (2.5, 10, 2),
        },
        # lawyer ids per rarity in Config.SkinCatalog (merges need 3 of the SAME id)          SYNCED
        "Catalog": {
            "Common": ["Rookie", "InternSuit", "CasualFriday"],
            # the normal egg's pool; brainrot lawyers (Egg = "Brainrot") only come from the Brainrot Egg,
            # which the sim doesn't model (3x price for 60/32/8 % U/R/L: worse power per coin than the normal egg)
            "Uncommon": ["BowTieBarrister", "NavyPowerSuit", "BensonBond"],
            "Rare": ["GoldenGavel", "NeonLitigator", "KaiSueNat", "KhabyClaim"],
            "Legendary": ["PinstripePartner", "IShowSued", "IceJustice"],
        },
        "Tiers": None,     # scenario "egg-tiers": list of extra egg machines (None = the one live egg)
    },
    # Config.Skills (Effect per level, MaxLevel 3, 3 slots, rarity weights 65/27/8)             SYNCED
    "Skills": {
        "MaxSlots": 3, "MaxLevel": 3, "RarityWeights": [65, 27, 8],
        "Catalog": [   # (Id, rarity 1-3, effect, per level)
            ("FastTalker", 1, "caseTime", 0.06),
            ("Organized", 1, "payout", 0.05),
            ("Charming", 2, "rareClients", 0.25),
            ("Specialist", 2, "specialist", 0.20),   # +payout vs ONE Config.Clients entry (1..9, uniform)
            ("SilverTongue", 3, "winChance", 0.03),
            ("Shark", 3, "payout", 0.12),
        ],
    },
    "Caps": {"PayoutMultiplier": 2.5, "WinChanceBonus": 0.12, "CaseTimeReduction": 0.30},  # SYNCED
    "Manager": {"HireCost": 5e7},                                    # SYNCED  auto-assigns once hired
    # Config.Case.SelfAssignAfter: before the Manager, a client waiting this long walks to a free lawyer
    # by itself (CaseService.autoAssign), so an AFK firm still earns. None = the old behaviour (nobody).
    "Case": {"SelfAssignAfter": 12},                                 # SYNCED
    # Config.Pacing (test targets)                                                          SYNCED
    "Targets": {"FirstEggMinutes": 2, "IncomeAtFirstEgg": (100, 500),
                "FirstExpandMinutes": (20, 30), "TrillionPerSecHours": (10, 20)},
}

ASSUMPTIONS = {
    # seconds a client walks from its seat to the desk; the desk is busy meanwhile (CaseService "Walking").
    # ~70 studs (FirmBuilder.routeSeatToDesk, middle offices) / Firm.WalkSpeed 11
    "WalkSeconds": 6.0,                                              # DERIVED
    # time per egg: server ROLL_COOLDOWN 2.5 s, client hatch animation ~3.3 s + a tap to close
    "HatchSeconds": 4.0,                                             # DERIVED
    "AssignRate": 0.5,       # BEHAVIOR  clients/s an active player assigns before the Manager
    "RushFirstPaid": True,   # BEHAVIOR  saves for the first paid egg first (hub tutorial step)
    "MultiHatch": 1,         # eggs per hatch animation (scenario "multi-hatch")
}

# Proposed changes to try against the live baseline: --scenario name[,name...]
# Each is a patch of (dict, path) -> value. Not in the live game unless docs/ECONOMY.md says so.
SCENARIOS = {
    # clients arrive about as fast as lawyers free up, so every lawyer stays busy (see review §6)
    "busy-lawyers": {("CONFIG", "Firm", "ClientInterval"): 5.6},
    # before 2026-10-08: nothing assigned clients before the Manager (AFK firms earned 0). Now live:
    # Config.Case.SelfAssignAfter. This scenario turns it back off for comparison.
    "no-self-assign": {("CONFIG", "Case", "SelfAssignAfter"): None},
    "multi-hatch": {("ASSUMPTIONS", "MultiHatch"): 3},
    "egg-ramp-10": {("CONFIG", "Eggs", "PriceGrowth"): 1.10},
    "egg-ramp-20": {("CONFIG", "Eggs", "PriceGrowth"): 1.20},
    # hub egg machines unlocked by income, each with its own price ramp and better odds
    "egg-tiers": {("CONFIG", "Eggs", "Tiers"): [
        {"Name": "Starter", "UnlockIncome": 0, "Price": 7500,
         "Weights": {"Common": 58, "Uncommon": 26.5, "Rare": 13, "Legendary": 2.5}},
        {"Name": "Office", "UnlockIncome": 1e5, "Price": 2e7,
         "Weights": {"Common": 30, "Uncommon": 40, "Rare": 24, "Legendary": 6}},
        {"Name": "Courthouse", "UnlockIncome": 1e8, "Price": 2e10,
         "Weights": {"Common": 0, "Uncommon": 45, "Rare": 43, "Legendary": 12}},
    ]},
}


def _roots():
    return {"CONFIG": CONFIG, "ASSUMPTIONS": ASSUMPTIONS}


def apply_scenarios(names):
    """Patch CONFIG / ASSUMPTIONS in place; returns a function that undoes it."""
    undo = []
    for name in names:
        for path, value in SCENARIOS[name].items():
            d = _roots()[path[0]]
            for k in path[1:-1]:
                d = d[k]
            undo.append((d, path[-1], d.get(path[-1], None), path[-1] in d))
            d[path[-1]] = value
    clear_caches()

    def restore():
        for d, k, v, had in reversed(undo):
            if had:
                d[k] = v
            else:
                d.pop(k, None)
        clear_caches()
    return restore


# ----------------------------------------------------------------------------------------
# Formulas - mirror of ReplicatedStorage.Shared.Formulas
# ----------------------------------------------------------------------------------------
SUFFIXES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


def format_coins(n):
    if n < 1000:
        return f"{n:.0f}"
    i = min(int(math.log10(n) // 3), len(SUFFIXES) - 1)
    return f"{n / 1000 ** i:.2f}{SUFFIXES[i]}"


def win_chance(level, difficulty, bonus=0.0):
    o = CONFIG["Outcome"]
    return min(o["MaxWinChance"], max(o["MinWinChance"],
               o["BaseWinChance"] + (level - difficulty) * o["PerSkillPoint"] + bonus))


def base_payout(level):
    p = CONFIG["Payout"]
    return p["Base"] * p["Growth"] ** level


def train_cost(level):
    t = CONFIG["Lawyer"]
    return math.floor(t["TrainBase"] * t["TrainGrowth"] ** level)


def client_interval(lawyers):
    f = CONFIG["Firm"]
    return max(f["MinInterval"], f["ClientInterval"] * f["StartLawyers"] / max(lawyers, 1))


def office_tier_bonus(level):
    bonus = 0.0
    for min_level, b in CONFIG["OfficeTiers"]:
        if level >= min_level:
            bonus = b
    return bonus


def expand_cost(segment):
    return CONFIG["Firm"]["ExpandCosts"].get(segment, math.inf)


def egg_price(opened, base=None):
    e = CONFIG["Eggs"]
    return math.floor((base or e["Price"]) * e["PriceGrowth"] ** max(opened, 0))


def lawyer_earn(rarity, stars):
    return CONFIG["Eggs"]["Rarities"][rarity][1] * CONFIG["Lawyers"]["StarEarn"][stars - 1]


@lru_cache(maxsize=None)
def client_table(level, win_bonus, rare_boost):
    """Per Config.Clients entry: (share of arrivals, multiplier, expected pay fraction per client incl.
    reruns, expected busy seconds per client before case-time buffs). Mirrors Formulas.rollOutcome and
    CaseService (mistrials rerun the whole case)."""
    o, p = CONFIG["Outcome"], CONFIG["Payout"]
    settle_frac = (p["SettlementMin"] + p["SettlementMax"]) / 2
    weights = [w * (1 + rare_boost if i > 0 else 1) for i, (_, w, _, _, _) in enumerate(CONFIG["Clients"])]
    total = sum(weights)
    rows = []
    for w, (_, _, mult, diff, dur) in zip(weights, CONFIG["Clients"]):
        win = win_chance(level, diff, win_bonus)
        settle = (1 - win) * o["SettlementShareOfNonWins"]
        mistrial = 1 - win - settle
        tries = 1 / (1 - mistrial)
        rows.append((w / total, mult, (win + settle * settle_frac) * tries, dur * tries))
    return tuple(rows)


def clear_caches():
    client_table.cache_clear()


# ----------------------------------------------------------------------------------------
# Lawyers and skills
# ----------------------------------------------------------------------------------------
class Lawyer:
    __slots__ = ("id", "rarity", "stars", "skills")

    def __init__(self, lawyer_id, rarity, stars=1, skills=()):
        self.id, self.rarity, self.stars, self.skills = lawyer_id, rarity, stars, list(skills)

    def earn(self):
        return lawyer_earn(self.rarity, self.stars)

    def buffs(self):
        """(payout, caseTime, winChance, rareClients, specialist (entry index, value) or None) - uncapped."""
        pay = time = win = rare = 0.0
        spec = None
        for skill_id, level, param in self.skills:
            _, _, effect, per = SKILL_DEFS[skill_id]
            v = per * min(level, CONFIG["Skills"]["MaxLevel"])
            if effect == "payout":
                pay += v
            elif effect == "caseTime":
                time += v
            elif effect == "winChance":
                win += v
            elif effect == "rareClients":
                rare += v
            elif effect == "specialist":
                spec = (param, v)
        return pay, time, win, rare, spec

    def value(self):
        """Rough per-case worth, for placing the best lawyers in the best offices."""
        pay, time, win, _, _ = self.buffs()
        return self.earn() * (1 + pay) / (1 - min(time, CONFIG["Caps"]["CaseTimeReduction"]))


SKILL_DEFS = {s[0]: s for s in CONFIG["Skills"]["Catalog"]}


def roll_skill(rng, skills):
    """Formulas.rollSkill: rarity by RarityWeights among skills not yet maxed, then even within it.
    Returns (id, param) or None."""
    owned = {s[0]: s for s in skills}
    pools = {}
    for skill_id, rarity, _, _ in CONFIG["Skills"]["Catalog"]:
        have = owned.get(skill_id)
        if not have or have[1] < CONFIG["Skills"]["MaxLevel"]:
            pools.setdefault(rarity, []).append(skill_id)
    weights = [(r, w) for r, w in enumerate(CONFIG["Skills"]["RarityWeights"], 1) if r in pools]
    if not weights:
        return None
    x, acc = rng.random() * sum(w for _, w in weights), 0.0
    for r, w in weights:
        acc += w
        if x < acc:
            break
    skill_id = rng.choice(pools[r])
    param = None
    if SKILL_DEFS[skill_id][2] == "specialist":
        param = owned[skill_id][2] if skill_id in owned else rng.randrange(len(CONFIG["Clients"]))
    return skill_id, param


def hatch(rng, lawyer_id, rarity):
    """LawyerService.hatch: StartSkills rolls (a repeat levels the skill up)."""
    skills = []
    for _ in range(CONFIG["Eggs"]["Rarities"][rarity][2]):
        rolled = roll_skill(rng, skills)
        if not rolled:
            break
        sid, param = rolled
        for i, (s, lvl, p) in enumerate(skills):
            if s == sid:
                skills[i] = (s, min(lvl + 1, CONFIG["Skills"]["MaxLevel"]), p)
                break
        else:
            if len(skills) < CONFIG["Skills"]["MaxSlots"]:
                skills.append((sid, 1, param))
    return Lawyer(lawyer_id, rarity, 1, skills)


def egg_tiers():
    e = CONFIG["Eggs"]
    if e["Tiers"]:
        return e["Tiers"]
    return [{"Name": "Egg", "UnlockIncome": 0, "Price": e["Price"],
             "Weights": {r: v[0] for r, v in e["Rarities"].items()}}]


def roll_rarity(rng, weights):
    x, acc = rng.random() * sum(weights.values()), 0.0
    for rarity, w in weights.items():
        acc += w
        if x < acc:
            return rarity
    return rarity


# ----------------------------------------------------------------------------------------
# Firm state
# ----------------------------------------------------------------------------------------
class Firm:
    def __init__(self):
        f = CONFIG["Firm"]
        self.segments = f["StartSegments"]
        self.offices = [CONFIG["Lawyer"]["StartLevel"]] * (self.segments * 2)
        self.offices[0] += CONFIG["Tutorial"]["FreeLevelUps"]      # the free tutorial upgrade
        start = CONFIG["Lawyers"]["StartId"]
        self.lawyers = [Lawyer(start, self._rarity_of(start))]     # the Rookie
        self.coins = 0.0
        self.eggs_opened = {}      # egg tier -> eggs opened (price ramp)
        self.since_top = 0         # pity counter
        self.manager = False
        self.merges = 0

    @staticmethod
    def _rarity_of(lawyer_id):
        for rarity, ids in CONFIG["Eggs"]["Catalog"].items():
            if lawyer_id in ids:
                return rarity
        return "Common"

    # --- placement + income -------------------------------------------------------------
    def placed(self, lawyers=None, offices=None):
        """Best lawyers in the best offices: [(office level, lawyer)]."""
        lawyers = self.lawyers if lawyers is None else lawyers
        offices = self.offices if offices is None else offices
        best = sorted(lawyers, key=lambda l: -l.value())
        return list(zip(sorted(offices, reverse=True), best))

    def income(self, lawyers=None, offices=None, manager=None, court=0.0, afk=False):
        pairs = self.placed(lawyers, offices)
        if not pairs:
            return 0.0
        caps = CONFIG["Caps"]
        # CaseService.bestSkills: the lawyer in the highest-level office sets Charming for the firm
        rare = min(pairs[0][1].buffs()[3], 10)
        desks = []
        for level, lawyer in pairs:
            pay_b, time_b, win_b, _, spec = lawyer.buffs()
            win_b = min(win_b, caps["WinChanceBonus"])
            time_mult = max(1 - time_b, 1 - caps["CaseTimeReduction"])
            base = pay_b + office_tier_bonus(level) + court
            pay = busy = 0.0
            for i, (share, mult, frac, secs) in enumerate(client_table(level, win_b, rare)):
                b = base + (spec[1] if spec and spec[0] == i else 0)
                pay += share * mult * frac * min(1 + b, caps["PayoutMultiplier"])
                busy += share * secs * time_mult
            pay *= base_payout(level) * lawyer.earn()
            desks.append((pay, busy + ASSUMPTIONS["WalkSeconds"]))
        left = 1 / client_interval(len(pairs))
        hired = self.manager if manager is None else manager
        wait = 0.0
        if not hired:
            if afk:
                wait = CONFIG["Case"]["SelfAssignAfter"]
                if wait is None:
                    return 0.0  # nobody clicks Assign and nothing else assigns
            else:
                left = min(left, ASSUMPTIONS["AssignRate"])
        # an AFK firm's clients sit SelfAssignAfter seconds before walking over: the lawyer idles meanwhile
        desks = [(pay, 1 / (cycle + wait)) for pay, cycle in desks]
        total = 0.0
        for pay, rate in sorted(desks, reverse=True):
            take = min(left, rate)
            total += take * pay
            left -= take
            if left <= 0:
                break
        return total

    # --- merging --------------------------------------------------------------------------
    def merge_all(self, **kw):
        """Merge groups of MergeCount identical lawyers while that raises income (LawyerService.merge
        keeps the best skill set). Returns the number of merges."""
        n = 0
        need = CONFIG["Lawyers"]["MergeCount"]
        while True:
            groups = {}
            for l in self.lawyers:
                if l.stars < len(CONFIG["Lawyers"]["StarEarn"]):
                    groups.setdefault((l.id, l.stars), []).append(l)
            done = False
            for (_, stars), group in groups.items():
                if len(group) < need:
                    continue
                group.sort(key=lambda l: -sum(s[1] for s in l.skills))
                used = group[:need]
                merged = Lawyer(used[0].id, used[0].rarity, stars + 1, used[0].skills)
                after = [l for l in self.lawyers if l not in used] + [merged]
                # merge when it doesn't lower income, or when the inventory is past the office count
                if self.income(lawyers=after, **kw) >= self.income(**kw) or len(self.lawyers) > len(self.offices):
                    self.lawyers = after
                    n += 1
                    done = True
                    break
            if not done:
                self.merges += n
                return n

    # --- actions: (name, cost, income gain, apply) ----------------------------------------
    def egg_tier(self, inc):
        return max(i for i, t in enumerate(egg_tiers()) if t["UnlockIncome"] <= inc)

    def next_egg_price(self, tier):
        return egg_price(self.eggs_opened.get(tier, 0), egg_tiers()[tier]["Price"])

    def actions(self, **kw):
        inc = self.income(**kw)
        out = []
        working = min(len(self.lawyers), len(self.offices))
        # office upgrades (only offices with a lawyer earn; one candidate per distinct level)
        levels = sorted(self.offices, reverse=True)
        for level in sorted(set(levels[:working])):
            if level >= CONFIG["Lawyer"]["MaxLevel"]:
                continue
            offices = list(self.offices)
            offices[offices.index(level)] += 1
            out.append(("office", train_cost(level), self.income(offices=offices, **kw) - inc,
                        lambda level=level: self._upgrade(level)))
        # egg: expected gain of one new lawyer (+ the chance it completes a merge)
        tier = self.egg_tier(inc)
        weights = egg_tiers()[tier]["Weights"]
        total_w = sum(weights.values())
        gain = 0.0
        counts = {}
        for l in self.lawyers:
            counts[(l.id, l.stars)] = counts.get((l.id, l.stars), 0) + 1
        for rarity, w in weights.items():
            if w <= 0:
                continue
            avg = Lawyer("?", rarity, 1, [])
            g = self.income(lawyers=self.lawyers + [avg], **kw) - inc
            ids = CONFIG["Eggs"]["Catalog"][rarity]
            for lid in ids:
                if counts.get((lid, 1), 0) == CONFIG["Lawyers"]["MergeCount"] - 1:
                    star = Lawyer(lid, rarity, 2, [])
                    rest = [l for l in self.lawyers if not (l.id == lid and l.stars == 1)]
                    g = max(g, (self.income(lawyers=rest + [star], **kw) - inc) / len(ids)
                            + g * (len(ids) - 1) / len(ids))
            gain += w / total_w * max(g, 0)
        if len(self.lawyers) < CONFIG["Lawyers"]["MaxOwned"]:
            out.append(("egg", self.next_egg_price(tier), gain, tier))
        # expand: judged as a bundle - 2 more offices, filled by spare lawyers or (expected) new ones from
        # eggs, and upgraded to the firm's median office level (a level-1 office next to level-50 ones is
        # worth ~nothing, so a one-step greedy player would otherwise never expand)
        nxt = self.segments + 1
        if nxt <= CONFIG["Firm"]["MaxSegments"]:
            spare = max(0, len(self.lawyers) - len(self.offices))
            need = max(0, 2 - spare)
            cost = expand_cost(nxt)
            extra = []
            if need:
                e = self.next_egg_price(tier)
                for i in range(need):
                    cost += e * CONFIG["Eggs"]["PriceGrowth"] ** i
                avg_r = max(weights, key=lambda r: weights[r])
                extra = [Lawyer("?", avg_r, 1, [])] * need
            target = sorted(levels[:working])[working // 2] if working else 1
            start = CONFIG["Lawyer"]["StartLevel"]
            cost += 2 * sum(train_cost(l) for l in range(start, target))
            g = self.income(lawyers=self.lawyers + extra, offices=self.offices + [target, target], **kw) - inc
            out.append(("expand", cost, g, self._expand))
        if not self.manager:
            g = self.income(manager=True, **kw) - inc
            out.append(("manager", CONFIG["Manager"]["HireCost"], g, self._hire_manager))
        return out

    def _upgrade(self, level):
        self.offices[self.offices.index(level)] += 1

    def _expand(self):
        self.segments += 1
        self.offices += [CONFIG["Lawyer"]["StartLevel"]] * 2

    def _hire_manager(self):
        self.manager = True

    def open_egg(self, rng, tier=0, forced=None):
        """EggServer.onRoll: rarity by the egg's weights (+ pity), id even within the rarity, then hatch."""
        weights = egg_tiers()[tier]["Weights"]
        rarity = forced or roll_rarity(rng, weights)
        if not forced:
            top = list(CONFIG["Eggs"]["Rarities"])[-1]
            self.since_top += 1
            if rarity != top and self.since_top >= CONFIG["Eggs"]["PityTop"]:
                rarity = top
            if rarity == top:
                self.since_top = 0
            self.eggs_opened[tier] = self.eggs_opened.get(tier, 0) + 1
        lawyer = hatch(rng, rng.choice(CONFIG["Eggs"]["Catalog"][rarity]), rarity)
        self.lawyers.append(lawyer)
        return lawyer


# ----------------------------------------------------------------------------------------
# Simulation
# ----------------------------------------------------------------------------------------
CHECKPOINTS_MIN = [1, 2, 5, 10, 20, 30, 60, 120, 240, 480, 720, 900, 1200, 1440]
RARITIES = ["Common", "Uncommon", "Rare", "Legendary"]


def simulate(hours, seed=1, log=False, active_bonus=0.0, afk=False):
    """Run one player for `hours`. Returns a dict with the timeline, every purchase and milestones.
    active_bonus: courtroom payout bonus (inside the x2.5 cap, like CourtService); afk: nobody assigns."""
    rng = random.Random(seed)
    firm = Firm()
    kw = {"court": active_bonus, "afk": afk}
    t = 0.0
    end = hours * 3600
    res = {"rows": [], "events": [], "first_egg": None, "trillion_at": None, "rarity_first": {},
           "stars_first": {}, "manager_at": None, "first_expand": None, "full_at": None,
           "runaway_at": None, "hours": hours, "stuck_at": None}
    checkpoints = [m * 60 for m in CHECKPOINTS_MIN if m * 60 <= end]

    def note():
        for l in firm.lawyers:
            res["rarity_first"].setdefault(l.rarity, t)
            if l.stars > 1:
                res["stars_first"].setdefault(l.stars, t)

    def snapshot(at):
        pairs = firm.placed()
        best = max(firm.lawyers, key=lambda l: l.earn())
        res["rows"].append((at, firm.income(**kw), len(pairs), len(firm.offices),
                            sum(o for o, _ in pairs) / max(len(pairs), 1), max(firm.offices),
                            sum(firm.eggs_opened.values()), f"{best.rarity}{'*' * (best.stars - 1)}"))

    note()
    if CONFIG["Eggs"]["FreeFirstEgg"]:
        firm.open_egg(rng, forced=CONFIG["Eggs"]["FirstEggRarity"])
        note()

    while t < end:
        inc = firm.income(**kw)
        rush = ASSUMPTIONS["RushFirstPaid"] and res["first_egg"] is None
        if res["trillion_at"] is None and inc >= 1e12:
            res["trillion_at"] = t
        if inc >= 1e40:
            res["runaway_at"] = t
            break
        if inc <= 0:
            res["stuck_at"] = t     # e.g. AFK before the Manager: no income, nothing to buy
            break
        best = None
        for name, cost, gain, apply in firm.actions(**kw):
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
            if res["first_egg"] is None:
                res["first_egg"] = (t, inc)
            firm.open_egg(rng, apply)
            dt = ASSUMPTIONS["HatchSeconds"] / ASSUMPTIONS["MultiHatch"]
            firm.coins += inc * dt
            t += dt
        else:
            apply()
            if name == "manager":
                res["manager_at"] = t
            if name == "expand" and res["first_expand"] is None:
                res["first_expand"] = t
            if name == "expand" and firm.segments == CONFIG["Firm"]["MaxSegments"]:
                res["full_at"] = t
        merged = firm.merge_all(**kw)
        note()
        res["events"].append((t, name, cost, inc))
        for _ in range(merged):
            res["events"].append((t, "merge", 0.0, inc))
        if log:
            print(f"  {t / 60:8.2f} min  {name:<7} {format_coins(cost):>10}  -> {format_coins(firm.income(**kw))}/s"
                  + (f"  (+{merged} merge)" if merged else ""))
    for c in checkpoints:
        snapshot(c)
    res["final"] = {"offices": list(firm.offices), "lawyers": len(firm.lawyers),
                    "working": len(firm.placed()), "merges": firm.merges,
                    "eggs": sum(firm.eggs_opened.values()),
                    "power": sorted((l.earn() for l in firm.lawyers), reverse=True)[:len(firm.offices)]}
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
    """[(ok, text)] for Config.Pacing."""
    tg = CONFIG["Targets"]
    out = []
    if res["first_egg"]:
        t, inc = res["first_egg"]
        lo, hi = tg["IncomeAtFirstEgg"]
        ok = t <= tg["FirstEggMinutes"] * 60 and lo <= inc <= hi
        out.append((ok, f"first paid egg at {fmt_time(t)}, earning {format_coins(inc)}/s "
                        f"(target <= {tg['FirstEggMinutes']} min, {lo}-{hi}/s)"))
    else:
        out.append((False, "never bought a paid egg"))
    lo, hi = tg["FirstExpandMinutes"]
    fx = res["first_expand"]
    out.append((fx is not None and lo * 60 <= fx <= hi * 60,
                f"first Expand Firm at {fmt_time(fx)} (target {lo}-{hi} min)"))
    lo, hi = tg["TrillionPerSecHours"]
    ta = res["trillion_at"]
    out.append((ta is not None and lo * 3600 <= ta <= hi * 3600,
                f"1T coins/s at {fmt_time(ta)} (target {lo}-{hi} h)"))
    return out


# ----------------------------------------------------------------------------------------
# Reports
# ----------------------------------------------------------------------------------------
WINDOWS_H = [(0, 0.25), (0.25, 1), (1, 2), (2, 4), (4, 8), (8, 12), (12, 16), (16, 24)]


def print_timeline(res):
    print(f"\n{'Time':>8} {'Coins/s':>10} {'Working':>8} {'Offices':>8} {'Avg lvl':>8} {'Top lvl':>8}"
          f" {'Eggs':>6}  Best lawyer")
    for at, inc, n, offices, avg, top, eggs, best in res["rows"]:
        label = f"{at / 3600:.0f}h" if at >= 3600 else f"{at / 60:.0f}m"
        print(f"{label:>8} {format_coins(inc):>10} {n:>8} {offices:>8} {avg:>8.1f} {top:>8} {eggs:>6}  {best}")


def print_report(res):
    """Where does the pacing feel bad? Purchases per window, longest dry spell, what's being bought."""
    ev = res["events"]
    print("\nPacing by window (purchases = things the player gets to click; long gaps feel like a wall)")
    print(f"{'Window':>11} {'Buys':>6} {'Office':>7} {'Expand':>7} {'Eggs':>6} {'Merges':>7} {'Median gap':>11}"
          f" {'Longest gap':>12} {'Office price':>13} {'Egg price':>10}")
    for a, b in WINDOWS_H:
        if a >= res["hours"]:
            break
        lo, hi = a * 3600, min(b, res["hours"]) * 3600
        inside = [e for e in ev if lo <= e[0] < hi and e[1] != "merge"]
        times = [lo] + [e[0] for e in inside] + [hi]
        gaps = sorted(y - x for x, y in zip(times, times[1:]))
        count = lambda n: sum(1 for e in ev if lo <= e[0] < hi and e[1] == n)
        med = gaps[len(gaps) // 2] if gaps else 0

        def price(n):   # median price in seconds of income (DESIGN.md: next upgrade ~10 min of earning)
            p = sorted(e[2] / e[3] for e in inside if e[1] == n and e[3] > 0)
            return fmt_time(p[len(p) // 2]) if p else "-"
        print(f"{a:>4g}-{b:<4g}h {len(inside):>6} {count('office'):>7} {count('expand'):>7} {count('egg'):>6} "
              f"{count('merge'):>7} {fmt_time(med):>11} {fmt_time(max(gaps) if gaps else 0):>12} "
              f"{price('office'):>13} {price('egg'):>10}")

    print("\nMilestones")
    for r in RARITIES:
        print(f"  first {r:<10} lawyer: {fmt_time(res['rarity_first'].get(r))}")
    for s, name in ((2, "Gold"), (3, "Rainbow")):
        print(f"  first {name:<9} (merged) lawyer: {fmt_time(res['stars_first'].get(s))}")
    print(f"  Manager hired: {fmt_time(res['manager_at'])}   (auto-assign; before it only clicks assign)")
    exp = [e for e in ev if e[1] == "expand"]
    print(f"  expansions: {len(exp)} (" + ", ".join(fmt_time(e[0]) for e in exp) + ")"
          + (f"; all 20 offices at {fmt_time(res['full_at'])}" if res["full_at"] else ""))
    f = res["final"]
    print(f"  final: {f['eggs']} eggs opened, {f['lawyers']} lawyers owned, {f['working']} working, "
          f"{f['merges']} merges; office levels min {min(f['offices'])} max {max(f['offices'])}")
    print(f"  final lawyer power in offices: {', '.join(f'{p:g}' for p in f['power'])}")
    if res["stuck_at"] is not None:
        print(f"  STUCK at {fmt_time(res['stuck_at'])}: income 0 with nothing affordable")


# which values the sweep perturbs: (label, root, path)
SWEEP = [
    ("Firm.ClientInterval", ("CONFIG", "Firm", "ClientInterval")),
    ("WalkSeconds", ("ASSUMPTIONS", "WalkSeconds")),
    ("Eggs.Price", ("CONFIG", "Eggs", "Price")),
    ("Eggs.PriceGrowth", ("CONFIG", "Eggs", "PriceGrowth")),
    ("Manager.HireCost", ("CONFIG", "Manager", "HireCost")),
    ("Payout.Base", ("CONFIG", "Payout", "Base")),
    ("Lawyer.TrainBase", ("CONFIG", "Lawyer", "TrainBase")),
    ("Payout.Growth", ("CONFIG", "Payout", "Growth")),
    ("Lawyer.TrainGrowth", ("CONFIG", "Lawyer", "TrainGrowth")),
    ("AssignRate", ("ASSUMPTIONS", "AssignRate")),
]


def _get(path):
    d = _roots()[path[0]]
    for k in path[1:-1]:
        d = d[k]
    return d, path[-1]


def summary(res):
    fe, fx = res["first_egg"], res["first_expand"]
    runaway = f"  RUNAWAY {fmt_time(res['runaway_at'])}" if res["runaway_at"] is not None else ""
    return (f"egg {fmt_time(fe[0]) if fe else 'never':>6} @ {format_coins(fe[1]) if fe else '-':>6}/s  "
            f"expand {fmt_time(fx):>6}  1T {fmt_time(res['trillion_at']):>6}{runaway}")


def run_sweep(hours, seed, factor, **kw):
    """Scale each value by 1/factor and xfactor (growth rates: their excess over 1) and show the targets."""
    print(f"\nSensitivity: each value scaled by 1/{factor:g} and x{factor:g} "
          "(growth rates scale their excess over 1)")
    print(f"{'baseline':<20} {summary(simulate(hours, seed, **kw))}")
    for label, path in SWEEP:
        d, k = _get(path)
        orig = d[k]
        parts = []
        for f in (1 / factor, factor):
            d[k] = 1 + (orig - 1) * f if "Growth" in k else orig * f
            clear_caches()
            parts.append(summary(simulate(hours, seed, **kw)))
        d[k] = orig
        clear_caches()
        print(f"{label:<20} low:  {parts[0]}\n{'':<20} high: {parts[1]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("--hours", type=float, default=24)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--log", action="store_true", help="print every purchase")
    ap.add_argument("--report", action="store_true", help="pacing diagnostics: gaps, purchase mix, milestones")
    ap.add_argument("--active", type=float, default=0.0, metavar="BONUS",
                    help="courtroom payout bonus of an active player (e.g. 0.2; inside the x2.5 cap)")
    ap.add_argument("--afk", action="store_true", help="nobody clicks Assign (clients self-assign after SelfAssignAfter s; the Manager instantly)")
    ap.add_argument("--sweep", type=float, nargs="?", const=2.0, metavar="FACTOR",
                    help="sensitivity of the targets to each tunable (default factor 2)")
    ap.add_argument("--scenario", default="", metavar="NAMES",
                    help="comma-separated proposed changes to apply: " + ", ".join(SCENARIOS))
    args = ap.parse_args()

    names = [n for n in args.scenario.split(",") if n]
    unknown = [n for n in names if n not in SCENARIOS]
    if unknown:
        ap.error(f"unknown scenario {unknown}; choose from {list(SCENARIOS)}")
    if names:
        apply_scenarios(names)
        print(f"Scenario: {', '.join(names)} (proposed - not the live game)")
    kw = {"active_bonus": args.active, "afk": args.afk}

    if args.sweep:
        run_sweep(args.hours, args.seed, args.sweep, **kw)
    else:
        res = simulate(args.hours, args.seed, args.log, **kw)
        print_timeline(res)
        if args.report:
            print_report(res)
        print("\nPacing targets")
        for ok, text in pacing_checks(res):
            print(f"  [{'OK' if ok else 'MISS'}] {text}")
        if res["runaway_at"] is not None:
            print(f"  [MISS] income ran away (>1e40/s) at {fmt_time(res['runaway_at'])} - payout outgrows costs")
        if res["stuck_at"] is not None:
            print(f"  [MISS] stuck at {fmt_time(res['stuck_at'])}: no income (AFK before the Manager?)")

    print("\nAssumptions (not Config values): " + ", ".join(f"{k}={v}" for k, v in ASSUMPTIONS.items()))


if __name__ == "__main__":
    main()
