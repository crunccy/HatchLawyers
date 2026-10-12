# Hatch a Lawyer & Get Rich!

Roblox idle/gacha law-firm tycoon for a young audience: hatch eggs for lawyer skins, assign clients to your
lawyers, win cases, and grow a one-room office into a legal empire.

The game itself lives in Roblox Studio (Team Create, placeId 94345095795403). This repo holds the design docs,
the working notes for Claude, and offline tools.

| File | What it's for |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Rules, ownership, Studio layout, art direction — read by Claude every session |
| [SESSION_LOG.md](SESSION_LOG.md) | Current state, work in progress, open items, history |
| [studio/](studio/README.md) | Read-only snapshot of every script live in Studio (re-export with `tools/studio_sync/`) |
| `src/` | Working copies of scripts, incl. changes not pushed to Studio yet |
| [docs/DESIGN.md](docs/DESIGN.md) | Original design manifesto (with a status table of what's superseded) |
| [docs/ECONOMY.md](docs/ECONOMY.md) | Economy rules, pacing targets, how to retune |
| [docs/ECONOMY_REVIEW.md](docs/ECONOMY_REVIEW.md) | Sim analysis: what needs attention, ranked |
| [docs/CLIENTS.md](docs/CLIENTS.md) | Client roster and bios |
| [docs/BLENDER_BRIEF.md](docs/BLENDER_BRIEF.md) | Plan for remaking models in Blender |
| [tools/economy_sim.py](tools/economy_sim.py) | Offline economy simulator: `python3 tools/economy_sim.py --report` |
| [tools/test_economy_sim.py](tools/test_economy_sim.py) | Sim tests: `python3 -m unittest discover tools` |
