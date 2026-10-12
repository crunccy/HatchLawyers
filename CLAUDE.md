# Hatch a Lawyer & Get Rich! — Claude's guide

Roblox idle/gacha law-firm tycoon for a young audience.
**Start of every session:** `git pull` on `main`, then read [SESSION_LOG.md](SESSION_LOG.md) (current state, **In progress**,
open items), then this file.
**End of every session:** add a dated entry to SESSION_LOG.md, update anything here that changed, re-export the Studio
snapshot if you touched Studio (below), then commit and push. Small commits; `git pull --rebase` before pushing.

## One team, one brain (2026-10-12)
Two people drive Claude on the same game, and **every Claude session works as one entity whose shared memory is this
repo** — local Claude memory is per machine, so anything the other side should know goes in here, not just in chat.
| Person | GitHub | Roblox | Machine |
| --- | --- | --- | --- |
| **crnuch** | `crunccy` (repo owner) | — | Mac: local Claude Code (Studio MCP + Blender) and cloud sessions |
| **mr.robe** | `ss-rob` | `mr_blox174` | Windows PC: local Claude Code (Studio MCP), repo at `Documents\HatchLawyers` |
- Sign every SESSION_LOG entry with who drove it: `## <date> — <crnuch|mr.robe>, <local|cloud> session: <topic>`.
- **Claim big work before starting it** under SESSION_LOG → **In progress** (who, what, since when) and push the claim,
  so two Claudes never rebuild the same thing (it happened with the egg zones: two different designs on 2026-10-12).
  Remove the claim when done. Both edit the same live Team Create place.
- Decisions either user makes are binding for both sides: write them into this file or the log as "user's call".

### Studio ↔ repo (studio/ snapshot + src/)
- **`studio/` = read-only snapshot of every script in the live place**, by Studio path (`studio/MANIFEST.json` lists
  Studio path, class, Enabled). Refresh it after any Studio edit: run `tools/studio_sync/receive_snapshot.ps1` (Windows) or
  `python3 tools/studio_sync/receive_snapshot.py --fresh` (Mac/Linux; `--port` if 8767 is taken), then `tools/studio_sync/ExportSnapshot.lua` in Studio
  (Edit mode). Never hand-edit `studio/`; it is what's live.
- **`src/` = working copies**: scripts with changes not in Studio yet (cloud sessions write here), plus older mirrors.
  A `src/` file identical to its `studio/` twin is in sync.
- **Pushing `src/` → Studio:** re-export the snapshot first; if the Studio script changed since your `src/` work
  started, 3-way merge (base = the last commit where `src/` matched Studio; `git merge-file`) — never paste over it.
- **Editing Studio directly (local sessions):** re-export the snapshot and copy the new version over any `src/` twin
  that has no pending work; merge into `src/` files that do.

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
| Zone bosses ("Opposing Counsel"): six concepts + the egg-drop rule | [docs/BOSSES.md](docs/BOSSES.md) |
| Eggs v5: Blender eggs, hatch, incubator (pipeline, upload, install) | [docs/EGGS_V5.md](docs/EGGS_V5.md) |
| Character style (lawyers, clients, Judge) — brick style, kit, rarity ladder | [docs/CHARACTER_STYLE.md](docs/CHARACTER_STYLE.md), kit: [tools/brick/BrickKit.lua](tools/brick/BrickKit.lua) |
| Blender scripts | `tools/` (`firm_kit.py`, `firm_pieces.py`, `clients_v2.py`, …) — some still untracked |
| Art references, `.fbx` exports | user's local `HatchLawyers` folder — not in git |
| What's live in Studio right now | `studio/` (read-only snapshot, see "Studio ↔ repo") — export tool in `tools/studio_sync/` |
| Studio's own in-game notes (mr.robe's machine sessions kept these) | `ServerScriptService.README` (snapshot: `studio/ServerScriptService/README.lua`) |

### What each kind of session can do
- **Local Claude Code (user's PC):** Roblox Studio MCP + blender-mcp → edit the place, build models, playtest.
- **Cloud session (claude.ai/code):** no Studio, no Blender. Can edit docs, run `tools/economy_sim.py`, and
  write Luau / Blender-Python as files for the user to paste or run. Never claim something was changed in Studio.
  Syntax-check every edited Luau file with the Luau CLI (`luau-compile --binary <file> > /dev/null`; download
  `luau-ubuntu.zip` from github.com/luau-lang/luau/releases) — it caught a `Config.lua` that didn't parse.
- **Every session, before pushing:** `python3 tools/checks/run_checks.py --luau-dir <folder with luau>` — compiles
  every Luau file, checks the real Config + Formulas (odds sum to 100, Supreme 1 in 2500, every egg has a lawyer per
  rarity, unique ids, climbing costs, the growth ratio) and runs the sim tests. GitHub runs the same on every push
  (`.github/workflows/checks.yml`): a red X on a commit means fix it before merging. New Config rules → add a
  check to `tools/checks/config_tests.luau`.

### Working efficiently (user's call 2026-10-12: save usage, never at the cost of quality)
- **One task per session.** Finish it, log it, push, stop. Long sessions re-read everything on every message.
- **Read narrowly:** grep / search first, then read only the lines you need. Use `studio/` (the snapshot) to read
  live scripts instead of pulling them through the Studio MCP. Don't re-read a file you just edited.
- **Screenshots only to check something visual** (a build, a UI layout, an effect), at most a few per task. Get UI
  positions from `execute_luau` (AbsolutePosition), not from images. Prefer one batched `execute_luau` that
  checks many things and prints a short summary over many small calls.
- **Plan before big work:** one short plan, then build. Don't build twice: claim it in SESSION_LOG first.
- **Quality is not optional:** still run `tools/checks/run_checks.py`, still playtest what you changed, still 3-way
  merge instead of pasting over Studio. Save tokens on *how* you work, never by skipping a check.
- **Short outputs:** short status messages; the SESSION_LOG entry is the record, not the chat.

## Team & ownership
- Since 2026-10-12 both users drive Claude and want one shared Claude: **any session may work on anything**, UI or
  gameplay. Original authorship, for context: crnuch's sessions built the UI/visuals, the firm redesign and the v12
  hatched-lawyer system; mr.robe wrote the core server gameplay (`ServerScriptService.Server.*`: PlayerData,
  PlotService, CaseService, LawyerService, CourtService, EvidenceCards, Main), and mr.robe's sessions built the firm
  stages, hub minigames, egg zones, incubators and the no-waiting-room flow (2026-10-12 entry).
- Changes to save data (`PlayerData`) or the core loop (`CaseService`) go in the log with a clear heads-up line.
- Both edit live in Team Create: re-read a script right before a big edit, and don't edit one someone is in.
  A multi_edit whose old_string no longer matches means someone changed it.

## Art direction — cartoony, locked in
Bright, chunky, colorful like Pet Simulator X / Steal a Brainrot / Steal an Egg: voxel tropical sim with lime
grass, orange paths with white dashed edges, wood crates, blocky palms. Look at the references before building.
- **Characters (2026-10-11): brick style** — studded bricks (`MaterialService.BrickStuds`), square eyes, chibi frame,
  one kit for lawyers + clients. Rules + rarity ladder: docs/CHARACTER_STYLE.md. Done 2026-10-11 for every lawyer,
  client, judge and the Manager (builders: tools/brick/). New characters: build them on tools/brick/BrickKit.lua and
  run them through tools/brick/Run.lua (it checks the arm rig for Shared.Puppet).
- **Window panels need `Skin.blockClicks(panel)`** (Shared.Skin; Skin.window does it): a Frame doesn't stop a tap,
  even with Active = true, so a tap on empty panel space reached the click-to-close backdrop and closed the window.
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
- `ReplicatedStorage.Shared.UpgradeFx` — the LAWYERS panel's office-upgrade celebrations (1 level small, MAX /
  UPGRADE ALL bigger with the number of levels, max level = whole-panel celebration). The panel passes it hooks.
- `ReplicatedStorage.SkinModels` — rigged R15 model skins (e.g. `LawyerSkin_Legendary`). The 18 Epic / Mythic /
  Supreme lawyers (2026-10-13) are brick Parts built in Blender: `tools/blender/lawyers_top.py` (on
  `tools/blender/brickkit.py`, a Python twin of BrickKit) → `tools/zones/lawyers_top.json` →
  `tools/zones/BuildLawyersTop.lua` (plain Parts, so any Studio can run it). **Mythic is built 1.3× and Supreme 1.6×**
  (user's call: bigger than Legendary; 7-13 studs tall, at desks too). Moving bits (wings, tails, orbiting planets,
  halos) carry `FxKind` (rot / osc / bob) + `FxAxis` / `FxPivot` / `FxAmp` / `FxRate` / `FxPhase` / `FxSize`
  attributes; `Shared.Puppet:apply` plays them (the hatch reveal, desks via `DeskLife`).
- `ReplicatedStorage.Animations.CarryEggs` — the egg-carry arm pose (made in Blender: `tools/blender/carry_anim.py`
  → `tools/zones/BuildCarryAnimation.lua`; child `Source` = the KeyframeSequence). Played by
  `StarterPlayerScripts.CarryPose`. Published by crnuch as `rbxassetid://86324090376520`. **Animations must be
  published from the place owner's account (crnuch, user 2234491534)** — an upload from mr_blox174 fails to load.
  **The same goes for meshes and images (checked 2026-10-12):** anything the game loads must be uploaded by crnuch.
- `ReplicatedStorage.Bosses` — the zone boss models (animation groups with Joint / Parent attributes; Blender:
  `tools/blender/bosses.py` → `tools/zones/BuildBosses.lua`). `Server.BossService` runs them (state in
  `ReplicatedStorage.BossStates`, `Remotes.Bosses`), `StarterPlayerScripts.Bosses` draws them; `Config.Bosses`.
  Sounds: `rbxasset://sounds/swoosh.wav` is NOT approved for this place - use the game's licensed ids.
- `ReplicatedStorage.EggModels` (v5 meshes) + `Shared.EggLook` — every egg the game shows (zones, loose, carried, the hatch)
  comes from `EggLook.build(egg, golden, height, simple)` / `EggLook.buildHatch`. The hatch (StarterPlayerScripts.Eggs, v5) plays in the
  world at the incubator for every rarity (`Shared.HatchFx` = the VFX kit + rarity ladder, `Shared.Incubator` = the
  incubator's Blender clips from `ReplicatedStorage.IncubatorAnims`; `Remotes.HatchShow` lets others watch). Firms clone
  `ServerStorage.Templates.IncubatorV5`. Made in Blender, uploaded by crnuch: docs/EGGS_V5.md.
  Epic adds lightning. **Mythic and Supreme cut to a stage of their own** (`HatchFx.stage`, built client-only at
  y = 3000, with the local Lighting changed and restored): Mythic = crimson arena (fissures, braziers, blood moon),
  Supreme = celestial sanctum (time-stop, screen crack, rainbow pillars, a giant halo, stars + aurora), then a
  "MYTHIC!" / "SUPREME!" title card with the odds. `Remotes.HatchAnnounce` (EggServer) puts a banner on everyone
  else's screen for a Mythic / Supreme. Preview any of it with the admin `/hatch mythic food` etc.
- `Workspace.Hub.TravelPortal` (tag `TravelPortal`, from Blender: `tools/blender/travel_portal.py` →
  `tools/zones/BuildTravelPortal.lua`) + `ServerScriptService.TravelServer` (`Remotes.Travel`) + `StarterPlayerScripts.Travel`
  (the TRAVEL tile + travel map): zone travel since 2026-10-13; replaced the six `Hub.ZoneTeleports` pads (archived in
  `ServerStorage.Old_ZoneTeleports`). No travel while carrying eggs (`Config.Zones.Travel`). Portal v2 (mr.robe's
  references): a sci-fi pad + light column + floating halo (FloatRing1-3 turned by the client). The trip itself is
  `Shared.TravelFx`: one animation per destination, growing down the lane (zone 1 a beam-up ... Space Base a hyperspace
  tunnel flight); it sets a local `Traveling` attribute (Bosses.client skips its ragdoll meanwhile).
- `ReplicatedStorage.Briefcases` — the Carry upgrade's briefcase models (`Config.Zones.Carry[n].Model`), worn on the
  back via CarryPose. Made in Blender: `tools/blender/briefcases.py` → `tools/zones/BuildBriefcases.lua`.
- `ReplicatedStorage.Remotes` — mr.robe: CaseResult, TrainLawyer, UpgradeDesk, AttendCourt, AnswerEvidence.
  Ours: EggHatched, MarkSkinsSeen, AssignClient, PlaceLawyer, MergeLawyers, MergeSelected, CancelLawyerChange,
  OpenLawyerPicker, HatchShow, HatchAnnounce. Local bindables: `LawyersUI` (open the LAWYERS panel), `SkillsUI` (open Skills).
  (TrainLawyer now upgrades an OFFICE; UpgradeDesk just answers "offices upgrade with their level".)
- `ServerScriptService`
  - `Server.*` — mr.robe's gameplay (above) + ours: `FirmBuilder`, `DeskService`.
  - `Eggs.EggServer` — egg rolls, equip, sell duplicates, NEW-badge count.
  - `Dev.EconomySim` (+ disabled `RunEconomySim`) — authoritative 24 h economy sim.
  - `AdminCommands` — chat commands for crnuch + mr_blox174 (and anyone in a Studio playtest): `/hatch <rarity> [egg] [golden]`
    (a preview hatch, nothing saved), `/eggs <count> [egg] [golden]`, `/coins <amount>`, `/help` (`;` works too).
- `StarterPlayerScripts` — ours: `Eggs` (hatch screen, odds board, egg bob), `Lawyers` (THE lawyer screen since
  2026-10-09: office slots bar, office card with upgrade/skills/unseat, CLIENTS tab to assign, BENCH tab to place/
  swap/merge; `SkinInventory` is disabled), `ClientWalk`, `AssignClients` (only the [E] prompts now), `Guide`.
  There is no office card at the bottom of the HUD any more. mr.robe's logic, our styling: `Hud`, `Courtroom`, `DeskProgress`.
- `ServerStorage.Templates` — `FirmKitParts` (the firm as Plastic Parts, preferred), `FirmKit` (old textured
  meshes, fallback), `Clients` (9 block-style clients),
  `NPC` (blocky fallback for Epic/Legendary clients), `LuxuryFirm` (archived). `Firm` (old closet office) is unused.
- `Workspace.Hub` — Street, Plaza (the lane's entrance on its south edge), no egg machines any more (all six eggs
  are sold in the zones; the machines + egg terrace are in `ServerStorage.Old_HubEggMachines`), BigCaseBelt, SpecialSpots (the
  Gavel Bonk / Lucky Briefcase minigames), ZoneTeleports, Palms. `Workspace.Plots.Plot1–8`.
  Front/door = local −Z; plots are rotated to face the street (two rows facing the street along x, z = 0).
- `Workspace.Zones` (2026-10-12, the lane from docs/ZONES_REFERENCE.md): one walled lane starting at the plaza's
  south edge (0, 0, -80) and running south to z -2554, between the halves of the south row of firms (it replaced the
  hub's egg store; BuildLane builds along -X and turns it into place with `PLACE`). It holds SafeZone, the six zones BriefcaseBay, PetPark, BrainrotBoulevard,
  FoodCourt, OceanShore, SpaceBase (each with Floor / Walls / Path / Chevrons / WallDecor / FloorClutter / EggSpots /
  Arrival, + the License gate into the next zone), LaneEnd and LicenseOffice. Hub teleports: `Hub.ZoneTeleports`
  (one pad per zone). Renders of zones 3-6: `art/zones/` (tools/blender/zone_render.py).
  - **Build:** `tools/zones/BuildLane.lua`; decorations come from `ServerStorage.ZoneDecorLibrary`, which is built
    from Blender (`tools/blender/zone_decor.py` → `tools/zones/BuildDecorLibrary.lua`). Add a zone by adding to
    `ZONES` in the builder and to `Config.Zones.List`.
  - **Runtime:** `Server.ZoneService` + `StarterPlayerScripts.Zones`. Each zone's `OddsBoard` (tag `ZoneOddsBoard`, attr `Zone`) is drawn by the Zones client: exact odds, golden odds, and the Lucky Eggs odds for pass owners. The old islands are archived in
    `ServerStorage.Old_Zones`.
- UPSTAIRS ROOMS (2026-10-13, `Config.Floors`): `ServerScriptService.FloorRooms` stands 8 Blender room sets
  (`ServerStorage.Templates.FloorRooms`, from `tools/blender/floor_rooms.py`) on the front building's upper floors by
  stage (`Config.Floors.Slots`) and runs them; panels `StarterPlayerScripts.Floors`; lasting bonuses
  `Server.FloorBonuses` (through `FirmFeatures.buffSources`). The Supreme Tower is hollow (its bands are floors).
  New building fronts must keep the rooms' slots clear (or move the slots).
- ARCADE PIER (2026-10-13): `Workspace.ArcadePier` north of the hub (the land ends at z 168), booth games run by
  `ServerScriptService.ArcadeServer` (+ `Games`), `StarterPlayerScripts.Arcade`, `ReplicatedStorage.ArcadeClient`,
  `Config.Arcade`. Map from Blender (`tools/blender/arcade_pier.py`). See src/Arcade/README.md.
- Firm: `Server.FirmStages` (6 front buildings by size/prestige, rooms sold on the lawn by `Server.FirmFeatures`),
  two incubators per firm (`Firm.Incubators`, tag `Incubator`) where the waiting room was; **no waiting room** —
  clients walk from the street straight to a free lawyer (`FirmBuilder.routeToDesk`).

### Never rename (scripts look these up)
`Firm`, `SpawnPoint`, `Sign` › `Label`, `DeskN` (tag `Desk`, attr `DeskIndex`), `HireSlotN`, `LawyerSpot`,
`ClientSpot` (NPCs stand on the spot's bottom face), `ManagerSpot`, `UpgradeSpot`, `TakeCase` prompt,
`Incubators` / `IncubatorPrompt`, `Zones.<Id>.EggSpots` / `Arrival`, `LicenseGate`, `UpgradePrompt`, `TeleportPrompt`,
`<Machine>.StandTop.RollPrompt`, `Egg`/`Shell`, `Sign` (egg machine), `OddsBoard.SurfaceGui`,
character parts `Head`/`Torso`/`Left Arm`/`Right Arm`/`Left Leg`/`Right Leg`/`HumanoidRootPart`,
client ids in `Config` (see docs/CLIENTS.md), skin model names in `SkinModels`.

## Game rules that code must respect
- Lawyers on a case are never moved mid-case: unseat/replace requests on a busy office are QUEUED and applied when
  the case ends; after a case (and after placing) auto-assign leaves the office alone `Config.Case.RestAfterCase` s.
- Server-authoritative: payouts, rolls, pity, levels, unlocks. Never trust client-sent amounts or results.
- Save schema: **v18 live** (2026-10-13: its step adds `data.Floors`, the upstairs rooms). `src/`'s v18 also carries
  the lawyer mutations + selling (not pushed yet; that step adds nothing - `Stars` now means the MUTATION tier, 1 Normal
  / 2 Shiny / 3 Diamond / 4 Cosmic, nothing rewritten; new optional `Lawyers[uid].Locked`), so both ship as v18.
  (v14 firm areas, v15 minigames, v16 egg zones, v17 the economy pass's `Eggs.RunOpened`.) Never reuse a
  migration number that has shipped. `PlayerData`: `Lawyers` by uid, `Desks[i] = { Level, Lawyer }`,
  `Zones = { License, Carry, Speed, Carried }`. Before adding any saved field: bump `SCHEMA_VERSION` and add a
  `MIGRATIONS` entry.
- **Mutations replaced merging (user's calls 2026-10-13):** the Mutation Machine (`Hub.MergeMachine`, the old Lawyer
  Merger; `Remotes.MergeSelected`) takes 3 of the same lawyer + tier and TRIES for the next tier
  (`Config.Lawyers.Mutations[t].Chance`, shown first); a fizzle takes all 3 (never leaves you with no lawyers).
  Hatches can roll a mutation (`HatchMutation`, golden eggs more). A mutation is shown by RECOLOURING the whole lawyer
  (`Shared.MutationLook`, called by `SkinLook.dress(model, id, stars)`; preview: `tools/blender/mutation_preview.py`),
  plus a lasting effect layer per tier (`Effects.mutationAura`, tag `FxMutation`: Shiny = gold glints + a sweep,
  Diamond = crystals + frost + a ring, Cosmic = a tilted orbit + stars + a dark-matter haze). Selling + locking:
  `Remotes.SellLawyers` / `LockLawyer`, `Config.Lawyers.Sell`; a locked lawyer can't be sold OR mutated.
- DataStores ARE reachable from Studio on this place now (saves persisted between playtests on 2026-10-11/12).
- The word "lose" never appears on screen; mistrials are soft blue, never red. Odds board shows exact odds.
- Robux (user's call 2026-10-12, keeps the `Config.Shop` products): passes (2x Cash, Lucky Eggs, Speedy Cases,
  Bigger Firm) and products (coin packs, 3 Rare Eggs) are allowed. Anything paid that's random must show its exact
  odds (Lucky Eggs: the boosted odds). Fictional clients only — no real people or brands.
- All numbers come from `Config`; never hard-code a tunable in a script. Retune → see docs/ECONOMY.md.
  Never change `Payout.Growth` / `Training.Growth` without running the sim — their ratio sets the whole curve.

## Studio MCP gotchas
- Edits only work in **Edit mode**. A playtest (anyone's) blocks edits and hides server scripts — ask to stop it.
- Keep screenshots few; heavy screenshot timeouts have dropped the MCP connection.
- Screenshots are upscaled (~1920×1000 vs real ~1274×664): get click targets from `AbsolutePosition` via
  client `execute_luau`, not from the image.
- DataStores: Studio API access is ON for this place (2026-10-12) — playtests read and write REAL saves of the
  test accounts. Back up a save before resetting it (mr.robe's was backed up as `Backup_Player_11776753629_<time>`).
- Edit-session `require` caches failures; test module changes in a playtest or require a fresh clone.
- The Studio MCP's own `execute_luau` runs in a separate VM: during a playtest, `require(PlayerData).get(player)` from
  it returns nil. Parent a temporary Script in the Server datamodel instead (it shares the game's modules).
- Stopping a playtest from MCP sometimes doesn't take; ask the user to press Stop.
- A Client `execute_luau` that is still running when anything changes `CameraType` gets it reset by the tool
  ("Resetting from Custom back to Scriptable"), so a cutscene's camera breaks or stays stuck. Keep client calls short
  (trigger, return) and wait in a *Server* call; to move the camera yourself, do it in `task.delay` after the call returns.
- `screen_capture` takes ~10 s to return and shoots when it starts: to catch a moment, put a mouse-input `wait` of
  the right length just before it (and don't think between the calls). Client code that takes the camera: start it
  with `task.delay` from execute_luau so the call has returned first.
- Studio must be the front window during a playtest you watch: in the background RenderStepped pauses (hatch
  cameras freeze, the screen goes white). Chat commands: `TextChatService.TextChannels.RBXGeneral:SendAsync(";hatch …")`.
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
- **Every model is made in Blender** (user's call 2026-10-13): props, buildings, characters, portals, icons' art —
  no more hand-placed Studio parts or procedural Luau builders for new models. Pipeline: a `tools/blender/*.py`
  script builds it (brick blocks) → JSON in `tools/zones/` → a `tools/zones/Build*.lua` makes studded Parts in
  Studio (or `.fbx` / meshes uploaded by crnuch). Cloud sessions can run Blender too: `pip install bpy==5.2.2` in a
  venv (Python 3.13) + `apt-get install libegl1 libgl1 libegl-mesa0 libgl1-mesa-dri libgbm1`, then render with
  `EGL_PLATFORM=surfaceless` (Workbench, Cycles and EEVEE all work headless).
