# Hatch a Lawyer & Get Rich! — Claude's guide

Roblox idle/gacha law-firm tycoon for a young audience.
**Start of every session:** read [SESSION_LOG.md](SESSION_LOG.md) (current state, open items), then this file.
**End of every session:** add a dated entry to SESSION_LOG.md and update anything here that changed.

## Where things live
| What | Where |
| --- | --- |
| The game | Roblox Studio, Team Create — place "Hatch a Lawyer & Get Rich!", **placeId 94345095795403** |
| Rules, layout, gotchas | this file |
| Current state, open items, history | [SESSION_LOG.md](SESSION_LOG.md) |
| Economy numbers + how to retune | [docs/ECONOMY.md](docs/ECONOMY.md), sim: [tools/economy_sim.py](tools/economy_sim.py) |
| Original design manifesto | [docs/DESIGN.md](docs/DESIGN.md) — read its "Status" table; parts are superseded |
| Client roster + bios | [docs/CLIENTS.md](docs/CLIENTS.md) |
| Blender model remake plan | [docs/BLENDER_BRIEF.md](docs/BLENDER_BRIEF.md) |
| Art references, Blender scripts (`tools/firm_kit.py`, `voxel_builder.py`, `clients.py`…), `.fbx` exports | user's local `HatchLawyers` folder — **not in this repo yet** |

### What each kind of session can do
- **Local Claude Code (user's PC):** Roblox Studio MCP + blender-mcp → edit the place, build models, playtest.
- **Cloud session (claude.ai/code):** no Studio, no Blender. Can edit docs, run `tools/economy_sim.py`, and
  write Luau / Blender-Python as files for the user to paste or run. Never claim something was changed in Studio.

## Team & ownership
- **User (crnuch) + Claude own ALL UI and visuals:** map, builds, lighting, and the *look* of every GUI —
  including mr.robe's `Hud` and `Courtroom` scripts (colors/fonts only, never their gameplay).
- **Claude also owns the firm redesign end to end, including its gameplay** (user's call, 2026-10-08):
  `FirmBuilder`, `DeskService`, the CaseService client queue, `ClientWalk`, `AssignClients`.
- **mr.robe** (always "mr.robe"; Roblox account `mr_blox174`) owns the rest of the server gameplay:
  `ServerScriptService.Server.*` (PlayerData, PlotService, CaseService, LawyerService, CourtService,
  EvidenceCards, Main). Edit only with a heads-up, and only for clear bugs/integration.
- Both edit live in Team Create: re-read a script right before a big edit, and don't edit one they're in.
  A multi_edit whose old_string no longer matches means they changed it.

## Art direction — cartoony, locked in
Bright, chunky, colorful like Pet Simulator X / Steal a Brainrot / Steal an Egg: voxel tropical sim with lime
grass, orange paths with white dashed edges, wood crates, blocky palms. Look at the references before building.
- **Palette (RGB):** world grass 96,196,40 · plot grass 124,222,52 · leaf 70,168,34 · path orange 255,160,24 ·
  wood light 214,140,70 · wood dark 122,70,34 · floor 222,160,96 · wall cream 246,226,180 · sign green 98,205,48.
  UI: white panels, ink 40,40,52, green 98,205,48, orange 255,160,24, gold 255,200,40, red 240,70,70.
  Rarity colors come from `Config.RarityColors`.
- **Fonts:** FredokaOne only. White text + thick black UIStroke. No serif / navy / brass.
- **UI:** big rounded buttons, thick black outlines, bouncy Back-eased tweens, scale to fit phones.
- **Builds:** Plastic (WoodPlanks for crates/floors), anchored, chunky, low part count — every player gets a
  firm, ×8 per server. Mesh budgets are in docs/BLENDER_BRIEF.md.
- mr.robe's realistic restyle is **archived, not deleted**: `ServerStorage.Templates.LuxuryFirm` (953 parts →
  future top firm tier) and `ServerStorage.ArchivedVisuals` (skyline, sidewalks/lampposts, planters).

## Studio layout
- `ReplicatedStorage.Shared.Config` — every tunable number. Deep-frozen. Shared by game + sim.
- `ReplicatedStorage.Shared.Formulas` — pure math (winChance, payout, trainCost, clientInterval,
  expectedIncomePerSecond, rollSkin/rollSkinId, skinPayoutBonus, formatCoins). Rolls take a `Random`.
- `ReplicatedStorage.Shared.SkinLook` — dresses an NPC in a skin; `showInViewport` for previews.
- `ReplicatedStorage.SkinModels` — rigged R15 model skins (e.g. `LawyerSkin_Legendary`).
- `ReplicatedStorage.Remotes` — mr.robe: CaseResult, TrainLawyer, UpgradeDesk, AttendCourt, AnswerEvidence.
  Ours: EggHatched, EquipSkin, SellSkins, MarkSkinsSeen, AssignClient.
- `ServerScriptService`
  - `Server.*` — mr.robe's gameplay (above) + ours: `FirmBuilder`, `DeskService`.
  - `Eggs.EggServer` — egg rolls, equip, sell duplicates, NEW-badge count.
  - `Dev.EconomySim` (+ disabled `RunEconomySim`) — authoritative 24 h economy sim.
- `StarterPlayerScripts` — ours: `Eggs` (hatch screen, odds board, egg bob), `SkinInventory`, `ClientWalk`,
  `AssignClients`. mr.robe's logic, our styling: `Hud`, `Courtroom`, `DeskProgress`.
- `ServerStorage.Templates` — `FirmKit` (Blender kit pieces, attr `Offset`), `Clients` (9 Blender clients),
  `NPC` (blocky fallback for Epic/Legendary clients), `LuxuryFirm` (archived). `Firm` (old closet office) is unused.
- `Workspace.Hub` — Street, Plaza, EggMachine (persistent streaming), Palms. `Workspace.Plots.Plot1–8`.
  Front/door = local −Z; plots are rotated to face the street.

### Never rename (scripts look these up)
`Firm`, `SpawnPoint`, `Sign` › `Label`, `DeskN` (tag `Desk`, attr `DeskIndex`), `HireSlotN`, `LawyerSpot`,
`ClientSpot` (NPCs stand on the spot's bottom face), `WaitSeats`, `ManagerSpot`, `UpgradeSpot`, `TakeCase` prompt,
`Hub.EggMachine.StandTop.RollPrompt`, `Egg`/`Shell`, `Sign` (egg machine), `OddsBoard.SurfaceGui`,
character parts `Head`/`Torso`/`Left Arm`/`Right Arm`/`Left Leg`/`Right Leg`/`HumanoidRootPart`,
client ids in `Config` (see docs/CLIENTS.md), skin model names in `SkinModels`.

## Game rules that code must respect
- Server-authoritative: payouts, rolls, pity, levels, unlocks. Never trust client-sent amounts or results.
- Save schema is **v11** (`PlayerData`). Before adding any saved field: bump `SCHEMA_VERSION` and add a
  `MIGRATIONS` entry.
- The word "lose" never appears on screen; mistrials are soft blue, never red. Odds board shows exact odds.
- MVP: no Robux for coins, eggs or power. Fictional clients only — no real people or brands.
- All numbers come from `Config`; never hard-code a tunable in a script. Retune → see docs/ECONOMY.md.

## Studio MCP gotchas
- Edits only work in **Edit mode**. A playtest (anyone's) blocks edits and hides server scripts — ask to stop it.
- Keep screenshots few; heavy screenshot timeouts have dropped the MCP connection.
- Screenshots are upscaled (~1920×1000 vs real ~1274×664): get click targets from `AbsolutePosition` via
  client `execute_luau`, not from the image.
- DataStores are off in Studio ("Studio access to APIs") — saving can't be tested there; expected warning.
- Test coins/skins: during play, parent a temporary Script in the *Server* datamodel (it shares PlayerData).
  Never leave test scripts in the edit place.
- Wrap world edits in ChangeHistoryService recordings so they're one undo step.
- Luau: a line starting with `(` right after a call is parsed as a call — assign to a local first.
- Requiring `Shared` modules in the sim: clone `Shared` + sim first to dodge module caching.

## Blender
blender-mcp: `claude mcp add blender -s user -- ~/.local/bin/uvx blender-mcp` (Blender 5.2 + BlenderMCP add-on;
the user clicks "Connect to Claude" in the N-panel). Use it for smooth/organic meshes. Export `.fbx`; **the user
imports** into Studio (Studio MCP can't upload local files), then Claude swaps parts into templates.
1 Blender m = 1 stud, transforms applied, characters face −Z. Full rules: docs/BLENDER_BRIEF.md.
