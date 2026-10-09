# Session log

Newest first. Each entry: what changed, where, and what's left. Keep the **Open items** list current —
it is the to-do list for the next session. Move finished items into the dated entry that finished them.

## Open items
- [ ] **Pre-Manager auto-assign** (review §3, confirmed): AFK players earn 0 and can never afford the Manager.
      Auto-assign a seated client to the best free lawyer after ~10–15 s (CaseService queue is ours).
- [ ] **Slow the economy ~10×** (review A/B/C): `Lawyer.TrainBase` 800 → ~10–12K **together with** new offices
      starting at the firm's lowest office level (`DeskService.upgradeFirm`), or expansions stall. Sim it first.
- [ ] **Upgrade ×10 / Max** on the office card (review §4) — `LawyerService` (ours since v12) + Hud.
- [ ] **Egg tiers** (review §2): stretch the merge chase (first Rainbow at 6 min today). Do after the retune.
- [ ] Specialist skill targets 1 of 9 `Config.Clients` entries (review D) — heads-up to mr.robe.
- [ ] Port this repo's sim model into Studio's `Dev.EconomySim` (stale since v12) or retire it (review E).
- [ ] Late-game sink beyond office level 100: prestige into the sim, or new content (review B).
- [ ] Add a `Config` comment next to `Payout.Growth` / `Lawyer.TrainGrowth`: their ratio sets the whole curve.
- [ ] Update DESIGN.md's tutorial + rewards text for v12 (review §7).
- [ ] **Add the user's local files to this repo:** `references/`, `tools/firm_kit.py`, `tools/firm_pieces.py`,
      `tools/voxel_builder.py`, `tools/clients.py`, `ClientPalette.png`. Decide whether `.fbx` exports go in
      (they're big; maybe Git LFS) or stay local.
- [ ] Responsive HUD pass: on narrow/phone screens the left-edge buttons (mr.robe's DAILY gift + our LAWYERS)
      overlap the coin counter and the office card.
- [ ] Publish the lawyer animations (Animation Editor → import .fbx → publish), play Idle at the desk and
      Objection on a win. `PinstripePartner`'s Idle/Walk/Objection are not published yet (user must do it).
- [ ] More hatchable lawyers: add entries to `Config.SkinCatalog` (now the lawyer catalog; ids are saved).
- [ ] Blender remake queue (docs/BLENDER_BRIEF.md): egg machine, palm, props, desk tiers, courtroom pieces.
- [ ] Enable Studio API access (Game Settings → Security) when ready to test saving.
- [ ] Resolve design-doc inconsistencies (listed in docs/ECONOMY.md → "Known inconsistencies").

## 2026-10-08 — local session: pre-Manager self-assign (review §3 fix #1)
- `Config.Case.SelfAssignAfter = 12`: before the Manager is hired, a client seated that long walks to the first
  free lawyer by itself (`CaseService.autoAssign`; longest wait first, ≤1 per 0.8 s; never before the tutorial's
  first case). The Manager still assigns instantly and picks the best-paying lawyer.
- Playtested with nobody clicking: the client walked over after 12 s, finished and paid (1,500 coins).
- Sim synced (`CONFIG.Case.SelfAssignAfter`; scenario `auto-assign` replaced by `no-self-assign`); 20 tests pass.
  Starting firm: AFK ~53/s vs active ~64/s (was 0 AFK). Retune the delay if AFK should earn less.

## 2026-10-08 — local session: nobody is blocky any more (lawyers, Manager, Epic/Legendary clients)
- `tools/lawyers_v2.py` (Blender; reuses the `clients_v2.py` recipe) designs 14 block-style characters and exports
  `tools/lawyer_parts.json` (Roblox-space boxes). Studio builds them as anchored Plastic Parts, like mr.robe's
  KaiSueNat (names = limb so Shared.Puppet sorts them; extra head boxes are `HeadDetail`; Neon only where it glows).
- Lawyers → `ReplicatedStorage.SkinModels`: Rookie, InternSuit, CasualFriday, BowTieBarrister, NavyPowerSuit,
  GoldenGavel, NeonLitigator; `Config.SkinCatalog` now gives every lawyer a `Model`.
- Manager → `SkinModels.Manager`, worn via new `SkinLook.wearModel(npc, name)` in ManagerService.spawnManager.
- Clients → `ServerStorage.Templates.Clients` (+ invisible HumanoidRootPart): RetiredCEO (tier 4), ChefMega,
  RocketBaronRex, MiloVex, DJBeatbox, KikiGlow (tiers 5–9); added to `Config.ClientCharacters`. Bios: docs/CLIENTS.md.
- Playtested: all 7 lawyers + Manager wear their models, every client tier resolves to a character, no errors.
- To change a design: edit lawyers_v2.py → `build_all(); export_rows()` in Blender → rebuild the Parts in Studio
  from lawyer_parts.json (the builder snippet is in this session's transcript; same row format as the file).

## 2026-10-08 — local session: legendary effects (Blender textures + Studio)
- `tools/effects_textures.py` (run in Blender) makes 10 white+alpha textures (glow, flare, twinkle, rays, ring, wisp,
  swirl, column, dot) + a coloured coin → `Models - Effects/`; uploaded, ids in `Models - Effects/ASSET_IDS.md`.
- New `ReplicatedStorage.Shared.Effects`: `aura(model, rarity, stars)` (Rare: blue twinkles + glow; Legendary: gold
  light column, turning sunburst, rising wisps, flare stars, floor shockwave, light; 2★ gold dust; 3★ rainbow +
  feet swirl), `burst(where, kind)` (legendary / rare / merge / rainbow / win / tier), `guiBurst(...)` for pop-ups.
- Hooks: CaseService.applyLawyer → aura; `CaseService.burst(player, office, kind)`; LawyerService: new office tier
  → "tier", placing a Rare/Legendary → "rare"/"legendary", merge → "merge" (3★ "rainbow"); CaseService win vs
  Epic/Legendary client → "win" coins; EggServer Rare/Legendary hatch → burst over the machine (2.2 s, timed to
  the crack). Client: Eggs hatch screen (suspense glow on shakes, gold flash, double sunburst, twinkles, coin
  rain for Legendary), Hud big-win pop-up and Rewards pop-ups get `guiBurst`.
- Playtested: no errors; auras attach (Legendary 11 instances); hatch screen verified by screenshot. The MCP
  3D capture showed a frozen frame, so in-world particles still need an eyeball check in a real playtest.

## 2026-10-08 — local session: no overhead words, one ASSIGN button, typography pass
- No text over anyone's head: lawyer nameplates removed (CaseService), Manager name tag removed (ManagerService),
  clients get a slim wordless progress bar tinted by rarity, shown only during their case (name/situation now in
  attributes `ClientName` / `Situation`). Empty-office tag shortened to "EMPTY OFFICE", visible within 35 studs.
- `AssignClients` rewritten: one **ASSIGN CLIENT** HUD button (count badge) instead of a button per client; opens
  the picker for the most valuable waiting client (rarest, then first come), gold outline on that client, and
  moves straight on to the next one after each assignment. Hud hint updated.
- Typography (user's spec): new `Shared.UIFonts` (Primary FredokaOne / Title LuckiestGuy / Body BuilderSansMedium,
  all verified to exist). Title: hatch reveal name + NEW!, Hud WIN toast, skill reveal, reward pop-up, verdict,
  MERGED message. Body: case status, skill + Manager upgrade descriptions, goal text, menu subtitles, courtroom
  question, picker details, Expand sign sub-line. Money (coin counter) bigger. Playtest: no errors; every visible
  text uses the three fonts.

## 2026-10-08 — local session: open offices, lawyers as the focal point
- User: floor too harsh, laptops faced away from the lawyer, make the lawyers the focal point (desk only, no
  bookshelves, no walls between lawyers).
- `tools/firm_pieces.py`: waiting-room floor = soft cream (246,232,204 / 238,222,192) instead of the white/orange
  checker; `office_segment` has no partitions; `lawyer_desk` is just the desk (+ client rug) with the laptop screen
  facing the lawyer (verified in a playtest on both sides). Backup: `tools/firm_pieces_v4_cubicles.py`.
- `tools/export_parts.py` now keeps existing palette indices (only appends), so unchanged pieces stay valid in
  Studio; re-sent OfficeSegment + LawyerDesk, recoloured the WaitingRoom floor in place.
- `CaseService.applyLawyer`: the lawyer stands on a glowing pad in their rarity colour (+ a PointLight); empty
  offices keep the gold pad. No errors in play.

## 2026-10-08 — local session: firm matches the world (studs + world palette)
- User: the firm looked too smooth, no stud texture, not the same style as the world / lawyers / eggs.
  Cause (measured in Studio): every map part uses Plastic with **TopSurface = Studs**; the firm's 824 parts were
  Smooth, and used mr.robe's muted courtroom palette instead of the world's bright one.
- Fix: all `FirmKitParts` templates + `FirmKitParts.Build`, `FirmBuilder.part`, `DeskService.cartoonPart` and
  `DeskLook.piece` now make studded Plastic. `tools/firm_pieces.py` palette "v4" = world colors (plaza white /
  orange checker floor, hub greens, gold 255,205,70, red 240,70,70, egg-pad wood 122,62,24); all 6 pieces re-sent.
  Playtest: 1,535 firm parts studded, 0 smooth, no errors.

## 2026-10-08 — local session: roomier offices, no overhead arch (Studio + Blender)
- User: more room between lawyers, drop the overhead arches. `tools/firm_pieces.py`: `SEG = 11` (offices 11 deep,
  was 8; filing cabinet added to each office), divider posts cut to 2.9 studs with no beam/plaque. Backup of the
  8-deep version: `tools/firm_pieces_v3_seg8.py`.
- New `tools/export_parts.py` (run in Blender): records the kit's boxes and writes `firm_parts_<Piece>.txt` +
  `firm_parts_palette.txt` for `ServerStorage.Templates.FirmKitParts.Build(name, rows)` in Studio. Palette order
  unchanged, so only WaitingRoom / OfficeSegment / LawyerDesk / ExpansionLock were re-sent.
- `FirmBuilder.SEG_DEPTH = 11`; full firm is now 134 studs deep (reaches z ±157). New `FirmBuilder.clearDecor`:
  island decor (IslandDecor / Shrubbery models) inside a firm's footprint moves to `ServerStorage.HiddenDecor`
  and comes back when that plot's firm is rebuilt smaller. Playtested: start firm hides 4 models, a fully
  expanded firm (20 offices, 2,743 parts) hides 6; no errors.
- Economy note: the walk from seat to desk is a bit longer now (`WalkSeconds` ~6 → ~7 in the sim; effect is small).

## 2026-10-08 — local session: economy sim synced with Studio (read-only in Studio)
- Read the live `Config`, `Formulas` (incl. `clientInterval`), `CaseService`, `FirmBuilder`, `RewardsService`.
  The live game is v12 (below), so `tools/economy_sim.py`'s **model** was rewritten, not just its numbers: hatched
  lawyers (rarity Earn × merge stars, skills), office levels + tiers, per-tier case lengths, `max(1, 28 / working)`
  arrivals, 10 waiting seats, ~6 s walk, Manager / AFK assigning, egg ×1.15 ramp + pity, real ExpandCosts, buffs
  capped like `combineBuffs`. Every GUESS is gone (SYNCED / DERIVED / BEHAVIOR tags). Tests rewritten: 20 pass.
- Results (docs/ECONOMY_REVIEW.md rewritten, docs/ECONOMY.md updated): first egg OK (40 s at 188/s); **1T/s at
  68–88 min** (target 10–20 h); **hard wall at office level 100 ~4 h**; AFK before the Manager earns 0 forever
  (confirmed in code); lawyers (not arrivals) are the bottleneck, so `ClientInterval` doesn't matter.
  `TrainBase` ~10–12K puts 1T at 10–20 h but needs new offices to stop starting at level 1.
- Nothing changed in Studio in this step.

## 2026-10-08 — local session: v12 "hatch real lawyers", block-style clients, firm as Parts (Studio)
- **Lawyer system (user's spec):** start with 1 Rookie; eggs hatch real lawyers (rarity Earn ×1/2/4/10, 1–2 skills);
  3 copies merge (+1 star, ×2.5 / ×6); place/swap into offices; office levels replace training (tiers by level).
  PlayerData **v12** (`Lawyers`, `NextLawyer`, `Desks[i] = { Level, Lawyer = uid }`, migration from v11).
  Server: `LawyerService` rewritten (TrainLawyer = office upgrade, PlaceLawyer, MergeLawyers, hatch), `EggServer`
  rewritten (price `7500 × 1.15^opened`, cap 150), `CaseService` (empty offices, lawyer power, dressing),
  `DeskService` (no hiring; expand adds empty offices), Skill/Rewards/Prestige/Leaderboard updated. New remotes
  PlaceLawyer, MergeLawyers, OpenLawyerPicker. Client: new `Lawyers` panel (replaces disabled `SkinInventory`),
  Hud office card (UPGRADE OFFICE / PLACE-SWAP LAWYER), hatch screen (PUT IN OFFICE N), AssignClients, Guide,
  Skills title, Manager prestige check. Playtested: tutorial case, free egg → place → merge → unplace all work.
- **Clients** rebuilt in mr.robe's block style (`tools/clients_v2.py` → ClientsV2.fbx): 6 meshes per client named
  for Puppet + Part HRP; old voxel clients in `ServerStorage.Clients_v1`. Fixed sit-facing bug in `ClientWalk`
  (CaseService sets `RestPivot`).
- **Firm** now built from plain Plastic Parts like the rest of the map (`ServerStorage.Templates.FirmKitParts`,
  803 parts, courtroom palette, no palms), generated from `tools/firm_pieces.py` → `firm_parts_*.txt`;
  FirmBuilder prefers it over the textured `FirmKit`. Floor raised 1.5 studs (`FirmBuilder.FLOOR_H`), upright
  Expand Firm billboard.

## 2026-10-08 — cloud session: economy analysis
- `tools/economy_sim.py`: added `--report` (purchases, gaps, prices per window, milestones), `--sweep`
  (sensitivity of the targets to each tunable), `--active` (courtroom bonus), runaway detection; prices are
  tracked in seconds of income. Added `tools/test_economy_sim.py` (12 tests).
- Wrote docs/ECONOMY_REVIEW.md. Key results: the curve hangs on `Training.Growth / Payout.Growth` (income ∝ T^3.35;
  TrainGrowth 1.33 → 1T at 11.4 h, 1.34 → 19.8 h); a fixed-price egg is free within minutes; pre-Manager AFK
  income may be zero; early game is ~1 purchase per 2.5 s; late game is training-only.
- Prototyped fixes as `--scenario`s (egg tiers, per-roll egg price ramp, multi-hatch, busy lawyers) and added a
  hatch-time cost per egg. Best combo: egg tiers + ~2–3 % price ramp + `clientInterval` tied to case length
  (results table in the review).
- New open items above. Nothing was changed in Studio.

## 2026-10-08 — cloud session: repo set up
- Created this repo's layout: `CLAUDE.md` (rules only), this log, `docs/` (DESIGN, ECONOMY, CLIENTS,
  BLENDER_BRIEF), `tools/economy_sim.py`.
- Rewrote the Python economy sim to mirror the live game (training with coins, Payout.Base 1200 × 1.25^L,
  client arrivals scaling with lawyers, Expand + Hire, eggs/skins, pacing-target checks). Values not known
  outside Studio are tagged `GUESS` and printed on every run — sync them (open item above).

## 2026-10-08 — firm redesign built & tested (local session, Studio)
Layout (inspired by `references/layout-fishing-*.webp`, structure only): Entrance (courthouse portico) →
Waiting room → lawyer offices along both walls with a red-carpet aisle → expansions → back library wall.
- Kit: `tools/firm_kit.py` + `tools/firm_pieces.py` → `Models - Environment/LawFirmKit.fbx` (Entrance,
  WaitingRoom, OfficeSegment, LawyerDesk [right side; rotate 180° for left], BackWall, ExpansionLock).
  Plot width 48, waiting room 21 deep, segments 8 deep, back wall 3. Pieces in `Templates.FirmKit` (attr Offset).
- Clients: voxel characters on the lawyer's R15 rig (`tools/voxel_builder.py` + `tools/clients.py`, shared
  `ClientPalette.png`), in `Templates.Clients`. Roster: docs/CLIENTS.md.
- `Server.FirmBuilder` assembles the kit onto `Workspace.Plots.PlotN` (colliders, sign, WaitSeats, ManagerSpot,
  UpgradeSpot, Desk<N>/HireSlot<N>).
- PlayerData v11 (`Firm.Segments`, 8 starting lawyers). Start = 4 segments × 2 sides = 8 slots.
- `CaseService` queue: arrivals → waiting seats → `Remotes.AssignClient` → walk to desk → case → walk out;
  Manager auto-assigns. Arrivals scale with lawyers (`Formulas.clientInterval`).
- `DeskService`: Expand Firm (+1 segment, 2 slots) and Hire Lawyer, both in place.
- Client scripts: `ClientWalk` (Puppet walk/sit), `AssignClients` (ASSIGN TO LAWYER button + lawyer picker).
- Economy retuned in the Studio sim: Payout.Base 1200, TrainGrowth 1.336, ExpandCosts/UnlockCosts in Config —
  all pacing targets OK.
- Puppet fix: limb pivots use the highest VISIBLE part (fixed arms detaching in the courtroom cheer).

## Earlier
- First model skin `PinstripePartner` (Legendary) = `SkinModels.LawyerSkin_Legendary`, from
  `Models - Characters/LawyerSkin_Legendary.fbx`. Root `RootPart` anchored, limbs on Motor6Ds,
  CanCollide/Query/Touch off, faces −Z, feet at y=0.
- Art direction locked to cartoony voxel; mr.robe's realistic restyle archived (see CLAUDE.md).
- Economy scale decided: big simulator numbers, coin-based training (overrides DESIGN.md's XP/upgrade curve).
