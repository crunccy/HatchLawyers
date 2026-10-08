"""Checks for tools/economy_sim.py. Run: python3 -m unittest discover tools"""

import contextlib
import io
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import economy_sim as sim  # noqa: E402


class Formulas(unittest.TestCase):
    def test_win_chance_clamps(self):
        self.assertAlmostEqual(sim.win_chance(1, 0), 0.703)
        self.assertEqual(sim.win_chance(1000, 0), 0.95)
        self.assertEqual(sim.win_chance(1, 1000), 0.45)

    def test_payout_and_training_match_config(self):
        self.assertAlmostEqual(sim.base_payout(1), 1500)
        self.assertAlmostEqual(sim.train_cost(0), 800)

    def test_format_coins(self):
        self.assertEqual(sim.format_coins(999), "999")
        self.assertEqual(sim.format_coins(1500), "1.50K")
        self.assertEqual(sim.format_coins(2.5e12), "2.50T")

    def test_skin_odds_sum_to_one(self):
        self.assertAlmostEqual(sum(o for o, _, _ in sim.CONFIG["Eggs"]["Skins"].values()), 1.0)

    def test_client_stats_pay_at_least_settlement(self):
        pay, attempts = sim.client_stats(1)
        self.assertGreater(pay, 0)
        self.assertGreaterEqual(attempts, 1)


class Firm(unittest.TestCase):
    def test_starts_with_eight_lawyers(self):
        self.assertEqual(len(sim.Firm().levels), 8)

    def test_income_never_exceeds_arrivals_times_best_pay(self):
        f = sim.Firm()
        best = max(sim.base_payout(l) * sim.client_stats(l)[0] for l in f.levels)
        self.assertLessEqual(f.income(), best / sim.client_interval(len(f.levels)) + 1e-9)

    def test_skin_cascades_to_next_lawyer(self):
        f = sim.Firm()
        f.levels[0] = 10
        f.open_egg("Rare")
        f.open_egg("Legendary")
        self.assertEqual(f.skins[0], "Legendary")
        self.assertIn("Rare", f.skins)


class Simulation(unittest.TestCase):
    def test_deterministic_per_seed(self):
        a = sim.simulate(1, seed=3)
        b = sim.simulate(1, seed=3)
        self.assertEqual(a["rows"], b["rows"])

    def test_income_is_monotonic(self):
        incomes = [r[1] for r in sim.simulate(6)["rows"]]
        self.assertEqual(incomes, sorted(incomes))

    def test_reports_run(self):
        res = sim.simulate(2)
        with contextlib.redirect_stdout(io.StringIO()):
            sim.print_timeline(res)
            sim.print_report(res)
        self.assertEqual(len(sim.pacing_checks(res)), 2)

    def test_runaway_is_detected_not_crashing(self):
        orig = sim.CONFIG["Payout"]["Growth"]
        try:
            sim.CONFIG["Payout"]["Growth"] = 1.5
            sim.client_stats.cache_clear()
            self.assertIsNotNone(sim.simulate(2)["runaway_at"])
        finally:
            sim.CONFIG["Payout"]["Growth"] = orig
            sim.client_stats.cache_clear()


if __name__ == "__main__":
    unittest.main()
