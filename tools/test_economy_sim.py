"""Checks for tools/economy_sim.py. Run: python3 -m unittest discover tools"""

import contextlib
import io
import os
import random
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import economy_sim as sim  # noqa: E402


class Formulas(unittest.TestCase):
    def test_win_chance_clamps(self):
        self.assertAlmostEqual(sim.win_chance(1, 0), 0.703)
        self.assertEqual(sim.win_chance(1000, 0), 0.95)
        self.assertEqual(sim.win_chance(1, 1000), 0.45)

    def test_payout_and_office_cost_match_config(self):
        self.assertAlmostEqual(sim.base_payout(1), 1500)
        lawyer = sim.CONFIG["Lawyer"]
        self.assertEqual(sim.train_cost(0), lawyer["TrainBase"])
        self.assertEqual(sim.train_cost(1), int(lawyer["TrainBase"] * lawyer["TrainGrowth"]))   # floor, like Formulas.trainCost

    def test_client_interval_matches_formulas(self):
        # Formulas.clientInterval = max(MinInterval 1, ClientInterval 3.5 x StartLawyers 8 / n)
        self.assertAlmostEqual(sim.client_interval(1), 28)
        self.assertAlmostEqual(sim.client_interval(8), 3.5)
        self.assertEqual(sim.client_interval(40), 1)
        self.assertAlmostEqual(sim.client_interval(0), 28)   # max(n, 1)

    def test_egg_price_ramps(self):
        eggs = sim.CONFIG["Eggs"]
        self.assertEqual(sim.egg_price(0), eggs["Price"])
        self.assertEqual(sim.egg_price(1), int(eggs["Price"] * eggs["PriceGrowth"]))

    def test_lawyer_power(self):
        self.assertEqual(sim.lawyer_earn("Common", 1), 1)
        self.assertEqual(sim.lawyer_earn("Legendary", 1), 10)
        self.assertEqual(sim.lawyer_earn("Uncommon", 2), 5)

    def test_office_tiers(self):
        self.assertEqual(sim.office_tier_bonus(9), 0)
        self.assertEqual(sim.office_tier_bonus(10), 0.05)
        self.assertEqual(sim.office_tier_bonus(99), 0.20)

    def test_format_coins(self):
        self.assertEqual(sim.format_coins(999), "999")
        self.assertEqual(sim.format_coins(1500), "1.50K")
        self.assertEqual(sim.format_coins(2.5e12), "2.50T")

    def test_client_table_shares_sum_to_one(self):
        rows = sim.client_table(1, 0.0, 0.0)
        self.assertAlmostEqual(sum(r[0] for r in rows), 1.0)
        self.assertTrue(all(r[3] >= dur for r, (_, _, _, _, dur) in zip(rows, sim.CONFIG["Clients"])))

    def test_hatch_rolls_start_skills(self):
        rng = random.Random(4)
        self.assertEqual(len(sim.hatch(rng, "IceJustice", "Legendary").skills) >= 1, True)
        self.assertLessEqual(len(sim.hatch(rng, "InternSuit", "Common").skills), 1)


class Firm(unittest.TestCase):
    def test_starts_with_one_rookie_and_eight_offices(self):
        f = sim.Firm()
        self.assertEqual(len(f.offices), 8)
        self.assertEqual([l.id for l in f.lawyers], ["Rookie"])
        self.assertEqual(max(f.offices), 2)   # the free tutorial upgrade

    def test_income_capped_by_arrivals(self):
        f = sim.Firm()
        f.manager = True
        best = max(sim.base_payout(o) * 50 * 2.5 for o in f.offices)
        self.assertLessEqual(f.income(), best / sim.client_interval(1))

    def test_afk_before_manager_still_earns(self):
        # clients self-assign after Config.Case.SelfAssignAfter: slower than an active player, but not 0
        f = sim.Firm()
        self.assertGreater(f.income(afk=True), 0)
        self.assertLess(f.income(afk=True), f.income())
        undo = sim.apply_scenarios(["no-self-assign"])
        try:
            self.assertEqual(f.income(afk=True), 0)
        finally:
            undo()

    def test_no_merge_while_offices_are_empty(self):
        # 3 working Uncommons (3 x2) beat one Gold (x5): merging only pays once offices are full
        f = sim.Firm()
        f.lawyers += [sim.Lawyer("BowTieBarrister", "Uncommon") for _ in range(3)]
        self.assertEqual(f.merge_all(), 0)

    def test_three_copies_merge_into_gold(self):
        f = sim.Firm()
        f.offices = [5, 5]
        f.lawyers += [sim.Lawyer("BowTieBarrister", "Uncommon") for _ in range(3)]
        f.merge_all()
        golds = [l for l in f.lawyers if l.stars == 2]
        self.assertEqual(len(golds), 1)
        self.assertEqual(golds[0].earn(), 5)

    def test_pity_gives_legendary(self):
        f = sim.Firm()
        rng = random.Random(0)
        f.since_top = sim.CONFIG["Eggs"]["PityTop"] - 1
        saved = sim.CONFIG["Eggs"]["Themed"]
        # an egg that only ever rolls Common: the 50th egg without a Legendary must still be one
        sim.CONFIG["Eggs"]["Themed"] = [{"Id": "x", "PriceMultiplier": 1, "UnlockEarned": None,
                                         "Weights": {"Common": 1}, "Pool": {"Common": ["Rookie"]}}]
        try:
            self.assertEqual(f.open_egg(rng, 1).rarity, "Legendary")
        finally:
            sim.CONFIG["Eggs"]["Themed"] = saved


class EggTiers(unittest.TestCase):
    def egg(self, egg_id):
        return next(i for i, e in enumerate(sim.egg_tiers()) if e["Id"] == egg_id)

    def test_briefcase_always_open_themed_gated(self):
        eggs = sim.egg_tiers()
        self.assertEqual(eggs[0]["Id"], "Briefcase")
        self.assertTrue(sim.egg_unlocked(eggs[0], 0))
        pet = eggs[self.egg("Pet")]
        self.assertFalse(sim.egg_unlocked(pet, pet["UnlockEarned"] - 1))
        self.assertTrue(sim.egg_unlocked(pet, pet["UnlockEarned"]))

    def test_gates_and_power_climb_with_price(self):
        themed = sorted(sim.CONFIG["Eggs"]["Themed"], key=lambda e: e["PriceMultiplier"])
        gates = [e["UnlockEarned"] for e in themed]
        power = [e["EarnMultiplier"] for e in themed]
        self.assertEqual(gates, sorted(gates))
        self.assertEqual(power, sorted(power))

    def test_locked_eggs_are_not_offered(self):
        f = sim.Firm()
        offered = {a[3] for a in f.actions() if a[0] == "egg"}
        self.assertEqual(offered, {0})
        f.earned = 1e30
        offered = {a[3] for a in f.actions() if a[0] == "egg"}
        self.assertEqual(offered, set(range(len(sim.egg_tiers()))))

    def test_themed_egg_hatches_its_own_stronger_lawyers(self):
        space = self.egg("Space")
        egg = sim.egg_tiers()[space]
        f = sim.Firm()
        lawyer = f.open_egg(random.Random(1), space)
        self.assertIn(lawyer.id, egg["Pool"][lawyer.rarity])
        self.assertEqual(lawyer.earn(), sim.lawyer_earn(lawyer.rarity, 1) * egg["EarnMultiplier"])
        self.assertEqual(sim.Lawyer("Rookie", "Common").earn(), 1)

    def test_eggs_share_one_price_ramp(self):
        f = sim.Firm()
        f.open_egg(random.Random(1), self.egg("Pet"))
        base = sim.egg_price(1)
        self.assertEqual(f.next_egg_price(0), base)
        self.assertEqual(f.next_egg_price(self.egg("Space")), base * 16)


class TopRarities(unittest.TestCase):
    """Epic / Mythic / Supreme (2026-10-12)."""

    def test_supreme_is_one_in_2500_in_every_egg(self):
        for egg in sim.egg_tiers():
            w = egg["Weights"]
            self.assertAlmostEqual(sum(w.values()), 100, places=6, msg=egg["Id"])
            self.assertAlmostEqual(w["Supreme"] / sum(w.values()), 1 / 2500, msg=egg["Id"])

    def test_every_rollable_rarity_has_a_lawyer(self):
        for egg in sim.egg_tiers():
            for rarity, w in egg["Weights"].items():
                if w > 0:
                    self.assertTrue(egg["Pool"].get(rarity), f"{egg['Id']} has no {rarity} lawyer")

    def test_power_climbs_with_rarity(self):
        earns = [sim.lawyer_earn(r, 1) for r in sim.RARITIES]
        self.assertEqual(earns, sorted(earns))
        self.assertEqual(len(set(earns)), len(earns))

    def test_pity_never_gives_mythic_or_supreme(self):
        f = sim.Firm()
        rng = random.Random(0)
        saved = sim.CONFIG["Eggs"]["Themed"]
        sim.CONFIG["Eggs"]["Themed"] = [{"Id": "x", "PriceMultiplier": 1, "UnlockEarned": None,
                                         "Weights": {"Common": 1}, "Pool": {"Common": ["Rookie"]}}]
        try:
            for _ in range(3):
                f.since_top = sim.CONFIG["Eggs"]["PityTop"] - 1
                self.assertEqual(f.open_egg(rng, 1).rarity, sim.CONFIG["Eggs"]["PityRarity"])
                self.assertEqual(f.since_top, 0)
        finally:
            sim.CONFIG["Eggs"]["Themed"] = saved

    def test_mythic_resets_pity(self):
        f = sim.Firm()
        f.since_top = 10
        saved = sim.CONFIG["Eggs"]["Themed"]
        sim.CONFIG["Eggs"]["Themed"] = [{"Id": "x", "PriceMultiplier": 1, "UnlockEarned": None,
                                         "Weights": {"Mythic": 1}, "Pool": {"Mythic": ["PhoenixProsecutor"]}}]
        try:
            self.assertEqual(f.open_egg(random.Random(0), 1).rarity, "Mythic")
            self.assertEqual(f.since_top, 0)
        finally:
            sim.CONFIG["Eggs"]["Themed"] = saved


class Simulation(unittest.TestCase):
    def test_deterministic_per_seed(self):
        a = sim.simulate(1, seed=3)
        b = sim.simulate(1, seed=3)
        self.assertEqual(a["rows"], b["rows"])

    def test_income_is_monotonic_within_a_run(self):
        # a Supreme resets income by design, so check one run with prestige out of reach
        saved = dict(sim.CONFIG["Prestige"])
        sim.CONFIG["Prestige"].update({"CostBase": 1e300})
        try:
            incomes = [r[1] for r in sim.simulate(4)["rows"]]
        finally:
            sim.CONFIG["Prestige"].clear()
            sim.CONFIG["Prestige"].update(saved)
        self.assertEqual(incomes, sorted(incomes))

    def test_prestige_resets_firm_keeps_lawyers(self):
        f = sim.Firm()
        f.lawyers += [sim.Lawyer("GoldenGavel", "Rare")] * 3
        f.offices = [50] * 12
        f.segments = 6
        f.coins = 1e15
        before = len(f.lawyers)
        f.do_prestige()
        self.assertEqual(f.prestige, 1)
        self.assertEqual(f.coins, 0)
        self.assertEqual(len(f.offices), sim.CONFIG["Firm"]["StartSegments"] * 2)
        self.assertEqual(max(f.offices), sim.CONFIG["Lawyer"]["StartLevel"])
        self.assertEqual(len(f.lawyers), before)
        cost, offices = sim.prestige_requirement(1)
        self.assertEqual(cost, sim.CONFIG["Prestige"]["CostBase"] * sim.CONFIG["Prestige"]["CostGrowth"])
        self.assertEqual(offices, 12)

    def test_reports_run(self):
        res = sim.simulate(2)
        with contextlib.redirect_stdout(io.StringIO()):
            sim.print_timeline(res)
            sim.print_report(res)
        self.assertEqual(len(sim.pacing_checks(res)), 3)

    def test_afk_only_gets_stuck_without_self_assign(self):
        self.assertIsNone(sim.simulate(1, afk=True)["stuck_at"])
        undo = sim.apply_scenarios(["no-self-assign"])
        try:
            self.assertIsNotNone(sim.simulate(1, afk=True)["stuck_at"])
        finally:
            undo()

    def test_faster_payout_growth_reaches_trillion_sooner(self):
        # office levels cap at Lawyer.MaxLevel 100, so income can't run away like the old sim's could
        orig = sim.CONFIG["Payout"]["Growth"]
        try:
            sim.CONFIG["Payout"]["Growth"] = 1.4
            sim.clear_caches()
            res = sim.simulate(6)
            self.assertIsNone(res["runaway_at"])
            self.assertIsNotNone(res["trillion_at"])
        finally:
            sim.CONFIG["Payout"]["Growth"] = orig
            sim.clear_caches()


if __name__ == "__main__":
    unittest.main()
