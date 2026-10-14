# src/Arcade - the Arcade Pier's booth games (2026-10-13, mr.robe's session)

User's call: build the minigames in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md (progress table there).

| File | Goes in Studio as |
|---|---|
| `ArcadeServer.server.lua` | `ServerScriptService.ArcadeServer` (Script) |
| `Games/<Id>.lua` | `ServerScriptService.ArcadeServer.Games.<Id>` (ModuleScripts in a Folder) |
| `Arcade.client.lua` | `StarterPlayer.StarterPlayerScripts.Arcade` (LocalScript) |
| `Client/Kit.lua`, `Client/<Id>.lua` | `ReplicatedStorage.ArcadeClient.Kit` / `.<Id>` (ModuleScripts in a Folder) |
| `ConfigArcade.lua` | the `Config.Arcade` block in `Shared.Config` (already merged into `src/Config.lua`) |
| (map) | `Workspace.ArcadePier`, built by `tools/zones/BuildArcadePier.lua` from `tools/zones/arcade_pier.json` (Blender: `tools/blender/arcade_pier.py`) |

Adding a game:
1. a `Config.Arcade.<Id>` entry (Name, Color, Cooldown, MinMinutes, MaxMinutes + its own numbers);
2. `Games/<Id>.lua` (start / input / finish / timeout - see the header of `ArcadeServer.server.lua`);
3. `Client/<Id>.lua` (`play(info, api)` - see `Arcade.client.lua` and `Client/Kit.lua`);
4. a booth: add it to `BOOTHS` in `tools/blender/arcade_pier.py` (it takes the next free slot), run Blender,
   re-run the builder.

No save change: cooldowns go in `data.Minigames[<Id>]`, the map Gavel Bonk already uses.
