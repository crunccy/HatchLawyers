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
| Economy numbers + how to retune | [docs/ECONOMY.md](docs/ECONOMY.md), sim: [tools/economy_sim.py](tools/economy_sim.py) (tests: `python3 -m unittest discover tools`) |
| Economy analysis, what needs attention | [docs/ECONOMY_REVIEW.md](docs/ECONOMY_REVIEW.md) |
| Original design manifesto | [docs/DESIGN.md](docs/DESIGN.md) — read its "Status" table; parts are superseded |
| Client roster + bios | [docs/CLIENTS.md](docs/CLIENTS.md) |
| Blender model remake plan | [docs/BLENDER_BRIEF.md](docs/BLENDER_BRIEF.md) |
| Zones map: reference breakdown + rules (lane of zones, walls, decoration, scattered eggs) | [docs/ZONES_REFERENCE.md](docs/ZONES_REFERENCE.md), shots in `references/zones-ref-*.webp` |
| Character style (lawyers, clients, Judge) — brick style, kit, rarity ladder | [docs/CHARACTER_STYLE.md](docs/CHARACTER_STYLE.md), kit: [tools/brick/BrickKit.lua](tools/brick/BrickKit.lua) |
| Blender scripts | `tools/` (`firm_kit.py`, `firm_pieces.py`, `clients_v2.py`, …) — some still untracked |
| Art references, `.fbx` exports | user's local `HatchLawyers` folder — not in git |

### What each kind of session can do
- **Local Claude Code (user's PC):** Roblox Studio MCP + blender-mcp → edit the place, build models, playtest.
- **Cloud session (claude.ai/code):** no Studio, no Blender. Can edit docs, run `tools/economy_sim.py`, and
  write Luau / Blender-Python as files for the user to paste or run. Never claim something was changed in Studio.
  Syntax-check every edited Luau file with the Luau CLI (`luau-compile --binary <file> > /dev/null`; download
  `luau-ubuntu.zip` from github.com/luau-lang/luau/releases) — it caught a `Config.lua` that didn't parse.

## Team & ownership
- **User (crnuch) + Claude own ALL UI and visuals:** map, builds, lighting, and the *look* of every GUI —
  including mr.robe's `Hud` and `Courtroom` scripts (colors/fonts only, never their gameplay).
- **Claude also owns the firm redesign end to end, including its gameplay** (user's call, 2026-10-08):
  `FirmBuilder`, `DeskService`, the CaseService client queue, `ClientWalk`, `AssignClients`, and the v12
  hatched-lawyer system the user specified (`LawyerService`, `EggServer`, the `Lawyers` panel).
- **mr.robe** (always "mr.robe"; Roblox account `mr_blox174`) owns the rest of the server gameplay:
  `ServerScriptService.Server.*` (PlayerData, PlotService, CaseService, LawyerService, CourtService,
  EvidenceCards, Main). Edit only with a heads-up, and only for clear bugs/integration.
- Both edit live in Team Create: re-read a script right before a big edit, and don't edit one they're in.
  A multi_edit whose old_string no longer matches means they changed it.

## Art direction — cartoony, locked in
Bright, chunky, colorful like Pet Simulator X / Steal a Brainrot / Steal an Egg: voxel tropical sim with lime
grass, orange paths with white dashed edges, wood crates, blocky palms. Look at the references before building.
- **Characters (2026-10-11): brick style** — studded bricks (`MaterialService.BrickStuds`), square eyes, chibi frame,
  one kit for lawyers + clients. Rules + rarity ladder: docs/CHARACTER_STYLE.md. Being rolled out (Rookie + Neighbor
  Dave done); every other character is still its 2026-10-10 version until rebuilt.
- **Fictional characters only:** no real people's names or likeness (lawyers too — four creator-parody names were
  renamed 2026-10-11).
- **Palette (RGB):** world grass 96,196,40 · plot grass 124,222,52 · leaf 70,168,34 · path orange 255,160,24 ·
  wood light 214,140,70 · wood dark 122,70,34 · floor 222,160,96 · wall cream 246,226,180 · sign green 98,205,48.
  UI: white panels, ink 40,40,52, green 98,205,48, orange 255,160,24, gold 255,200,40, red 240,70,70.
  Rarity colors come from `Config.RarityColors`.
- **Fonts** (`ReplicatedStorage.Shared.UIFonts`): **FredokaOne** for buttons, headings, menus, HUD and money (money
  bigger); **LuckiestGuy** only for big moments (hatch reveal name, NEW!, WIN!, MERGED!, reward pop-ups, verdict);
  **BuilderSansMedium** for descriptions and small print. White text + thick black UIStroke on important text.
  No serif / navy / brass. **No words over the Manager's head** — user's call. Lawyers AND clients get overhead name tags (user's calls
  2026-10-09, `StarterPlayerScripts.LawyerTags`, mirrored in `src/LawyerTags.client.lua`): "Steal a Brainrot" style —
  no panel, stacked bold text with thick black outlines. Lawyers: Gold/Rainbow tier · name · rarity · Earns xN (+ case
  pop-ups). Clients (compact): name · "Rarity · Pays xN". Tags are stud-sized but clamped up close (NEAR_LIMIT).
- **UI:** big rounded buttons, thick black outlines, bouncy Back-eased tweens, scale to fit phones. Panels are dark
  studded purple with purple striped headers (Shop / Merger / LAWYERS; UIKit restyles older ones to match). HUD menu
  tiles ONLY via `Shared.HudMenu.button` (one column, never hand-placed); icons are PNGs in `HudMenu.Icons` - no emoji.
- **Effects** (`ReplicatedStorage.Shared.Effects`, mirrored in `src/Effects.lua`; textures from
  `tools/vfx_textures.py` (v2, anime style from the user's 4 reference images) + `tools/effects_textures.py` (v1);
  ids in `Models - Effects/ASSET_IDS.md`). Ladder: Rare = ICE, Epic = ENERGY orb, Legendary = FIRE tornado,
  2★ gold star layer, 3★ rainbow + energy. Bursts: rare/merge/rainbow/legendary/win/tier. Use
  `Effects.aura / burst / ambient / guiBurst`; don't hand-roll emitters (the old plain sparkles are gone). Keep
  LightEmission ≤ 0.3 (the yellow floor eats additive sprites), burst Brightness ≤ 1.4 (stacks clip to white),
  aura lights dim. Part-parented ambient emitters use Surface/Outward. **Test at a high graphics level**
  (`settings().Rendering.QualityLevel` in the Client) — Studio's Automatic level throttles particles so hard
  that effects look missing. A ViewportFrame skips Transparency = 1 parts *and their decals* (use 0.99).
  Egg machine effects: `require(game.ServerStorage.EggMachineFx:Clone()).apply()`.
- **Builds:** plain Parts, **Plastic with `TopSurface = Studs`** (every part of the map — Ground, Plaza, Trees,
  IslandDecor, EggPads — is built this way; Smooth tops or textured MeshParts look out of place), bright world
  colors (see `tools/firm_pieces.py` "v4" palette), anchored, chunky — every player gets a firm, ×8 per server.
  Studio's command bar caches required modules: after editing a ModuleScript, re-require a fresh clone.
- mr.robe's realistic restyle is **archived, not deleted**: `ServerStorage.Templates.LuxuryFirm` (953 parts →
  future top firm tier) and `ServerStorage.ArchivedVisuals` (skyline, sidewalks/lampposts, planters).

## Studio layout
- `ReplicatedStorage.Shared.Config` — every tunable number. Deep-frozen. Shared by game + sim.
- `ReplicatedStorage.Shared.Formulas` — pure math (winChance, payout, trainCost, clientInterval,
  expectedIncomePerSecond, rollSkin/rollSkinId, skinPayoutBonus, formatCoins). Rolls take a `Random`.
- `ReplicatedStorage.Shared.SkinLook` — dresses an NPC in a skin; `showInViewport` for previews.
- `ReplicatedStorage.SkinModels` — rigged R15 model skins (e.g. `LawyerSkin_Legendary`).
- `ReplicatedStorage.Remotes` — mr.robe: CaseResult, TrainLawyer, UpgradeDesk, AttendCourt, AnswerEvidence.
  Ours: EggHatched, MarkSkinsSeen, AssignClient, PlaceLawyer, MergeLawyers, MergeSelected, CancelLawyerChange,
  OpenLawyerPicker. Local bindables: `LawyersUI` (open the LAWYERS panel), `SkillsUI` (open Skills).
  (TrainLawyer now upgrades an OFFICE; UpgradeDesk just answers "offices upgrade with their level".)
- `ServerScriptService`
  - `Server.*` — mr.robe's gameplay (above) + ours: `FirmBuilder`, `DeskService`.
  - `Eggs.EggServer` — egg rolls, equip, sell duplicates, NEW-badge count.
  - `Dev.EconomySim` (+ disabled `RunEconomySim`) — authoritative 24 h economy sim.
- `StarterPlayerScripts` — ours: `Eggs` (hatch screen, odds board, egg bob), `Lawyers` (THE lawyer screen since
  2026-10-09: office slots bar, office card with upgrade/skills/unseat, CLIENTS tab to assign, BENCH tab to place/
  swap/merge; `SkinInventory` is disabled), `ClientWalk`, `AssignClients` (only the [E] prompts now), `Guide`.
  There is no office card at the bottom of the HUD any more. mr.robe's logic, our styling: `Hud`, `Courtroom`, `DeskProgress`.
- `ServerStorage.Templates` — `FirmKitParts` (the firm as Plastic Parts, preferred), `FirmKit` (old textured
  meshes, fallback), `Clients` (9 block-style clients),
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
- Lawyers on a case are never moved mid-case: unseat/replace requests on a busy office are QUEUED and applied when
  the case ends; after a case (and after placing) auto-assign leaves the office alone `Config.Case.RestAfterCase` s.
- Server-authoritative: payouts, rolls, pity, levels, unlocks. Never trust client-sent amounts or results.
- Save schema is **v12** (`PlayerData`: `Lawyers` by uid, `Desks[i] = { Level, Lawyer }`). Before adding any saved field: bump `SCHEMA_VERSION` and add a
  `MIGRATIONS` entry.
- The word "lose" never appears on screen; mistrials are soft blue, never red. Odds board shows exact odds.
- MVP: no Robux for coins, eggs or power. Fictional clients only — no real people or brands.
- All numbers come from `Config`; never hard-code a tunable in a script. Retune → see docs/ECONOMY.md.
  Never change `Payout.Growth` / `Training.Growth` without running the sim — their ratio sets the whole curve.

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
