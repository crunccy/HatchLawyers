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
        self.assertEqual(sim.train_cost(0), 800)
        self.assertEqual(sim.train_cost(1), 1068)   # floor(800 x 1.336), like Formulas.trainCost

    def test_client_interval_matches_formulas(self):
        # Formulas.clientInterval = max(MinInterval 1, ClientInterval 3.5 x StartLawyers 8 / n)
        self.assertAlmostEqual(sim.client_interval(1), 28)
        self.assertAlmostEqual(sim.client_interval(8), 3.5)
        self.assertEqual(sim.client_interval(40), 1)
        self.assertAlmostEqual(sim.client_interval(0), 28)   # max(n, 1)

    def test_egg_price_ramps(self):
        self.assertEqual(sim.egg_price(0), 7500)
        self.assertEqual(sim.egg_price(1), 8625)

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

    def test_afk_before_manager_earns_nothing(self):
        f = sim.Firm()
        self.assertEqual(f.income(afk=True), 0)
        self.assertGreater(f.income(afk=True, manager=True), 0)

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
        sim.CONFIG["Eggs"]["Tiers"] = [{"Name": "x", "UnlockIncome": 0, "Price": 1, "Weights": {"Common": 1}}]
        try:
            self.assertEqual(f.open_egg(rng).rarity, "Legendary")
        finally:
            sim.CONFIG["Eggs"]["Tiers"] = None


class Simulation(unittest.TestCase):
    def test_deterministic_per_seed(self):
        a = sim.simulate(1, seed=3)
        b = sim.simulate(1, seed=3)
        self.assertEqual(a["rows"], b["rows"])

    def test_income_is_monotonic(self):
        incomes = [r[1] for r in sim.simulate(4)["rows"]]
        self.assertEqual(incomes, sorted(incomes))

    def test_reports_run(self):
        res = sim.simulate(2)
        with contextlib.redirect_stdout(io.StringIO()):
            sim.print_timeline(res)
            sim.print_report(res)
        self.assertEqual(len(sim.pacing_checks(res)), 3)

    def test_afk_gets_stuck_without_auto_assign(self):
        self.assertIsNotNone(sim.simulate(1, afk=True)["stuck_at"])
        undo = sim.apply_scenarios(["auto-assign"])
        try:
            self.assertIsNone(sim.simulate(1, afk=True)["stuck_at"])
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
