# eggs v5: the live-script installs

These are the live Studio scripts from the `studio/` snapshot at commit `8468c2f` with **only** the eggs v5 changes. They don't include the economy pass, which `src/` also holds. See docs/EGGS_V5.md, "Installing the scripts".

| File | Studio path | v5 change |
| --- | --- | --- |
| `Eggs.client.lua` | `StarterPlayer.StarterPlayerScripts.Eggs` | The hatch v5: everything from "the egg: an actor" up to the reveal panel is replaced. The hatch now plays in the world at the incubator. |
| `EggServer.server.lua` | `ServerScriptService.Eggs.EggServer` | `HatchShow` is fired for every incubator hatch. The server's delayed burst only fires when there's no incubator. |
| `FirmBuilder.lua` | `ServerScriptService.Server.FirmBuilder` | `buildIncubator` clones `ServerStorage.Templates.IncubatorV5`, with its panel facing the aisle. If the template is missing, it builds the old incubator. |

Install them only after the place owner's upload. They need:
- `ReplicatedStorage.EggModels` with the `EggV5` attribute;
- `ReplicatedStorage.IncubatorAnims`;
- `ServerStorage.Templates.IncubatorV5`.

If a live script changed since `8468c2f`, 3-way merge it (base = `studio/` at `8468c2f`).
