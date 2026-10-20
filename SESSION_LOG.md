# Session log

Newest first. Each entry: what changed, where, and what's left. Keep the **Open items** list current —
it is the to-do list for the next session. Move finished items into the dated entry that finished them.

## In progress
Claim big work here before starting (who · what · since), push the claim, remove it when done. See CLAUDE.md → "One team".
- **mr.robe (local), since 2026-10-13:** the minigames + upper floors from docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md
  (user's call: everything except the Rooftop Helipad), Phase A first: a new Arcade framework (`Server.ArcadeService`,
  `StarterPlayerScripts.Arcade`, `Config.Arcade`, booths) and the games one by one - progress table in that doc.
  Don't build any of these meanwhile; MinigameService / Gavel Bonk / Lucky Briefcase stay as they are.
- **crnuch (local), since 2026-10-18:** the game-wide UI overhaul - every screen, HUD tile, toast, prompt, world sign
  and minigame screen onto `Shared.Skin` + the glossy PNG icons. Audit + plan: docs/UI_OVERHAUL.md. Figma design
  pass first, then Studio. Visual only (no gameplay / save changes). Don't restyle UI meanwhile.
  Parts 1 (audit, icons, Figma) + 2 (Skin v2 + HUD) done 2026-10-18; part 3 (the remaining R / S rows) next.
- **crnuch (local), since 2026-10-18:** WORLD REDESIGN in Blender only (floating-island hub + six egg islands),
  deliverables in `environment-redesign/`. Stages 1-2 done + approved 2026-10-18 (decisions in
  `environment-redesign/central_hub/blockout/LAYOUT.md`); Stages 3-4 done 2026-10-18; Stage 5: Briefcase Bay, Pet
  Park + Brainrot Zone approved, Food Court done (waiting for approval); Ocean Shore done 2026-10-19 by mr.robe's
  session (waiting for approval), then redesigned as Ocean Shore v2 by crnuch's session = APPROVED 2026-10-19 as the
  benchmark the other islands get redone to (one at a time, when crnuch asks; Briefcase Bay v2 APPROVED 2026-10-19);
  Space Base done 2026-10-19 by mr.robe's session (waiting for approval): all six
  islands modelled. Stage 7 (into the place) started 2026-10-19 on mr.robe's user's call (entries below).
  Blender only: no Studio, gameplay code or map changes (user's call). Don't start a map redesign meanwhile.

- **crnuch (local), since 2026-10-19:** BOSS ATTACK ANIMATION OVERHAUL (visual only: no damage, targeting, timing,
  range or hit changes). Megalodon first as the benchmark (Blender storyboard + keyframes -> client pose data),
  then the other five once crnuch approves. Don't touch `Bosses.client` poses / bosses.py / BossService meanwhile.
  Megalodon benchmark + its crowd attack APPROVED + LIVE in Studio 2026-10-19; the other five are next (one at a time).
  The Senior Partner (Briefcase Swing + Paper Storm) APPROVED + LIVE 2026-10-20. Next: the other four, one at a time.
  Prosecutor Big Cheese (Cheese Roll + Wheel Split) APPROVED + LIVE 2026-10-20. Next: Bulldog, Martello, Eclipse.
- **crnuch (local), since 2026-10-20:** WORLD AMBIENCE & ATMOSPHERE overhaul of the six boss zones - client-side only
  (ambient particles, fog / Atmosphere, per-zone lighting + colour grading, optional ambient loops from Shared.Sfx).
  No map / model / boss / gameplay changes. One controller (`StarterPlayerScripts.Ambience` + `Shared.AmbiencePresets`)
  owns zone lighting; TravelFx / hatch stages keep their save-restore. Pet Park prototype first, then the other five
  after crnuch approves. Don't add zone lighting / atmosphere scripts meanwhile.

## Open items
- [ ] **Megalodon 3-player playtest (Feeding Frenzy)** - skipped 2026-10-19 (crnuch). Needs Test > Clients and
      Servers > 3 players: the two non-targets get warning lanes + sand sharks; a player who stays in a lane is hit.
- [ ] **Senior Partner 3-player playtest (Paper Storm)** - live 2026-10-20, only played solo. Same setup (Test >
      Clients and Servers > 3 players, in Briefcase Bay): the two non-targets get 10-stud discs, the bundles land as the
      swing hits; a player who stays in a disc is hit.
- [ ] **Big Cheese 3-player playtest (Wheel Split)** - live 2026-10-20, only played solo. In the Food Court with 3
      players: the two non-targets get 12-wide lanes, wedges pop off as he lands on his edge and tumble down them.
- [ ] **Megalodon recover clip: left fin 0.56 studs into the body / 0.48 into the snout** for a couple of frames (the
      glasses push since round 3's fin re-seat). `boss_anims.py -- check` shows it; fix in boss_clips/megalodon.py.
- [ ] **WorldRedesign in the place is pre-voxel** (2026-10-19): `Workspace.WorldRedesign` was built from the old
      exports (smooth Cylinders / Balls / Wedges). Rebuild each island from the voxel JSONs in `tools/zones/redesign/`
      with `BuildRedesignIsland.lua` (about 165k parts vs 108k: check the part budget first, or move to meshes).
      **crnuch's call 2026-10-19: leave the place as it is until we decide parts vs meshes.** Don't rebuild meanwhile.
- [ ] **Redesign islands in the place: eggs / Travel / RETURN HOME wired, switch ON since 2026-10-20** (mr.robe's
      call; `Config.Zones.Islands.Enabled = true` in Studio - players get it at the next PUBLISH). Egg runs have no
      boss danger until the bosses are wired. Still to wire: boss arenas (after crnuch's boss overhaul
      releases BossService), the hub's firm lots, the zone banner + Travel map "you are here" (lane Bounds), raised
      studs (StudTop tags), a space skybox for Space Base; then decide when to flip the switch for real (both users).
      The six islands are the v2 versions since 2026-10-20 (entry below); still to check: buying an egg on a v2
      island with Studio in FRONT (the 2026-10-20 test couldn't: no prompts showed with Studio in the background), the
      four new v2 islands' ambience passes, crnuch's review of them.
      Re-run BuildIslandWiring after any island rebuild (v2 layouts). Check fps / memory on a phone: the place
      went from ~19.5k to ~128k parts (all islands stream; move them to ServerStorage if it hurts).
- [ ] **Studded-brick world (crnuch's call 2026-10-18, docs/ART_STYLE_STUDS.md):** real raised 3D studs map-wide.
      Test patch live (Plaza + Plot1, docs/ART_STYLE_STUDS.md "Status"). Next: check the low tiles at phone
      size + fps with Studio in front, then tag all 8 plots and roll out (claim it first).
- [ ] **UI overhaul part 2 at phone size** (crnuch): Device emulator, landscape - HUD tiles (2 columns), coins
      bottom-left vs the thumbstick, egg bag, Goals (folded), hint toast, zone arrival banner. Only checked by layout
      maths (2026-10-18 entry).
- [ ] **Map + model art pass: eye-check in a real playtest** (built 2026-10-16, entries below; Studio-only screenshots so far) - phone size too.
- [ ] **crnuch's bug report (2026-10-16, from a playtest).** All 7 fixed (entries below). Still to do: crnuch's eye-check
      in Studio of 1 / 3 / 7 (that session's viewport didn't render, so no screenshots). 6 was eye-checked 2026-10-18.
      Leads found in the code, not confirmed:
  1. ~~FIXED~~ **Dingy Shack doesn't house the incubators properly** (`Server.FirmStages` stage 1, the shack is the old
     template cloned + opened up; the two `Firm.Incubators` don't fit inside it).
  2. ~~FIXED~~ **A Legendary+ hatch in a low-tier firm: the egg flies up and out through the ceiling.** `Eggs.client` ~1085:
     `rise = math.max(7, ceiling - start - 4)` - the 7-stud minimum beats a low ceiling (the shack).
  3. ~~FIXED~~ **Some firms with bright lights + white walls look extremely bright** (firm stages' lights / Neon on cream
     walls; check each of the 6 stages).
  4. ~~FIXED~~ **The Travel Portal stands in the middle of the path** - crnuch wants it elsewhere (ask where);
     `Workspace.Hub.TravelPortal`, placed by `tools/zones/BuildTravelPortal.lua`.
  5. ~~FIXED~~ **The rebirth system is called "Supreme"; it should be called "Rebirth"** (user's call). On-screen text only:
     `Supreme.client` (HUD tile "SUPREME", "Supreme Empire", "GO SUPREME!", "Supreme level N") + any toasts / Guide
     text; keep script / remote / save names (Prestige*) and the Supreme RARITY as they are.
  6. ~~FIXED~~ **Studio-built part models flicker when the camera moves: pieces overlap and the colours fight** (z-fighting:
     coplanar or overlapping faces). crnuch: "on the lawyers and other places just in general, not the eggs or the
     bosses" (those are meshes / Blender) - so the Part-built lawyers (BrickKit + BuildLawyersTop) and Part props.
  7. ~~FIXED~~ **Desks overlap their accessories when levelled up** (office tier props from `Config.Desks.Tiers`, placed by
     `Server.DeskService` / FirmBuilder).
- [ ] **Lawyer mutations: golden zone eggs sometimes hatching Shiny** - the last unchecked bit of the mutations
      playtest (everything else eye-checked 2026-10-16, second crnuch entry below). Needs real golden hatches (25%).
- [ ] **LAWYERS panel: the bench grid is too short since the SELL / LOCK / SELL ALL row** (found 2026-10-16): at a
      1429x776 Studio window the grid is 112 px tall but a card is 124 px, so not even one row fits and every card's
      "Earns x" line is cut off (you have to scroll to see it). `Lawyers.client` benchGrid `Size (1, -114)` + the row at
      `-106`. Needs a layout call (smaller cards when short / the row beside EQUIP / a taller right column).
- [ ] **Taste calls from the mutations eye-check (no change made):** Diamond on a mostly-white lawyer (Celestial)
      comes out near-white with blue accents, and with the Supreme aura it glares; the Cosmic orb (size h x 0.75)
      washes a big lawyer's desk lavender. An Epic Diamond sells for ~194K at crnuch's 3 Qa stage (sell price
      follows the Briefcase egg price) - economy review, not a bug.
- [ ] **Re-run `tools/zones/BuildLane.lua` in Studio** (fixed 2026-10-13, crnuch cloud session, not in Studio yet):
      (1) walls + wall tops now continue under every License gate - there was a 12-stud opening on both sides of
      each gate where players walked out of the lane; (2) invisible `ClimbBlock` walls (collide, CanQuery off so the
      camera ignores them, 60 studs tall) on both edges of every wall top, the hub-side ends and the end wall -
      players were jumping from props onto the wall tops and walking past locked gates. Decorations land exactly
      where they are now (seeded rng, untouched). Before re-running: anything hand-edited in Workspace.Zones since
      the last build gets archived to ServerStorage.Old_Zones - check first. Playtest: walk the gate sides, try to
      jump onto walls from the tallest props in every zone, camera close to a wall doesn't snap.
- [ ] **Zone travel: the rest of the playtest** (pushed to Studio 2026-10-13 by mr.robe's session, with the v2
      portal + the per-zone trip animations - entry below). Checked: the map opens from the TRAVEL tile, GO trips to
      zone 1 and 6 land facing down the lane, carrying eggs blocks GO, every animation step plays. Still to check:
      walking onto the pad opens the map; locked zones grey with a padlock; HOME; the gems lit only for your zones;
      the floating rings / swirl / beam motion; another player watching (they see the server's bursts only);
      phone size; zones 2, 4, 5 eye-checks.
- [ ] **Proposal: dynamic Supreme screen crack + mutated eggs (Diamond / Rainbow / Cosmic)** -
      docs/PROPOSAL_SUPREME_CRACK_AND_MUTATIONS.md (crnuch, 2026-10-13; not built, decide + claim first). Note in it:
      Golden's luck x4 is already capped on Food / Ocean / Brainrot / Space eggs (x2.2-3.6), so higher mutations
      use rarity floors instead of more luck.
- [ ] **Eye-check the economy-pass push in a playtest** (pushed 2026-10-13, only "loads with no errors" + hatches
      checked): (1) locked egg prompt "Locked / Earn X more coins", toast, odds board "Unlocks at X earned"; (2) a Pet
      lawyer's "Earns x" includes the x1.25 (hatch screen, LAWYERS panel, name tag); (3) the Supreme screen's cost +
      office count, eggs cheap again after a Supreme; (4) UPGRADE MAX / UPGRADE ALL; (5) LAWYERS panel at phone size
      (Device emulator, landscape) incl. the white Supreme pill; (6) desktop size unchanged.
- [ ] **`Skin.Assets.Rays` / `Skin.Assets.Glow` don't load** (2026-10-13): the output says "The experience doesn't
      have access permission to use asset id 89557955610458 / 75348129891036", so the sunburst + glow behind Skin cards
      (shop, travel map ...) are missing everywhere. crnuch: share them with the experience (Creator Dashboard →
      the asset → permissions) or re-upload from the owner account (tools/ui_textures.py); or point them at Effects'
      `rays` / `glow` textures (those load).
- [ ] **Minigames + upper floors: BUILD** (user's call 2026-10-13: everything in
      docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md except the Rooftop Helipad). Phase A (no save change) is claimed
      above; Phase B (Hall of Fame, Case Files, Moot Court, Partner's Office, Mail Room, Guest Lounge) needs save v19,
      and crnuch's mutations push (v18) is live since 2026-10-16, so it can start.
- [ ] **Eye-check the Mythic / Supreme cinematics in a real window + at phone size**, and a real Mythic / Supreme
      hatch with a second player in the server (the banner was only tested with faked messages). The 10-13 stud
      Supreme lawyers at desks: check name tags, the client standing across the desk, and the Merger / LAWYERS previews.
- [ ] **Eggs v5: eye-check in a real window.** Watch a few real hatches (all rarities, golden), check a phone-sized window, have a second player watch one. Delete `ServerStorage.Old_EggModels_v4` once happy.
- [x] **Audit fixes + carry pose pushed to Studio** — 2026-10-12 (mr.robe's entry below), except the parts tied to
      the economy pass (exact-odds luck 720699e, the 41 lawyer renames in `Config`): they go with that push.
- [ ] **Set Server Size to 8** (Game Settings → Places → Server Size; user only): it's 60 but there are 8 plots, so
      players 9+ get kicked by `Main` and lose their offline earnings (audit, `Main:28`).
- [x] **Carry animation published** — 2026-10-12: crnuch published `Source` from the place owner's account
      (user 2234491534) as **86324090376520**, set in `CarryEggs.AnimationId` and playtested (loads, 2 s looped, legs
      still walk). mr.robe's own upload (85314818445255) can't be used: the place's owner has no access to it.
      **Rule: publish animations (and other assets the game loads) from the place owner's account (crnuch).** If
      the Blender animation changes, re-publish from there and swap the id.
- [ ] Eye-check the carry animation in a real window (hug loop, the pile's sway while walking).
- [ ] **Bosses: eye-check in a real window** (all six: poses, floor warnings, slam / roll / charge / pull, dizzy
      stars, the egg flight + bounce, loose-egg glow and blink) and tune `Config.Bosses` by feel. The bark is a low
      gavel knock - swap in a real licensed bark if one turns up. Boss Cases: parked (user).
- [ ] **Eye-check the new eggs + both hatches in a real window** (only checked by numbers / renders): tap feel,
      the rings / pedestal on a phone, the fancy camera at a few incubators, golden eggs' 126 parts (lattice) - if
      zones feel heavy, make golden zone eggs "simple" too.
- [ ] **Zones 3-6: eye-check in a real window** (renders of each in `art/zones/`), and price them: Silver 1e8, Gold
      2e9, Platinum 4e10, Diamond 1e12 are first guesses - put them in the zones sim run.
- [x] **Hub egg machines decided** - user's call 2026-10-12: the egg store is gone, every egg lives in the zones
      (machines archived in `ServerStorage.Old_HubEggMachines`). Each zone has its own odds board now.
- [ ] `ServerStorage.Old_Zones` holds two archived lanes (islands 05:59, 2-zone lane 22:42) - delete once nobody
      needs them (they're a few thousand parts each in the place file).
- [ ] **Briefcase tiers 4-5 costs are guesses** (Golden 2.5e9 → 8 eggs, Diamond 2.5e11 → 12 eggs; x100 per tier like
      before). Put them in the zones economy sim run (item below) and eye-check the briefcases on a few avatars.
- [x] `PlotService` CharacterAdded leak - fixed 2026-10-12 (entry below).
- [x] **Odds boards for Lucky Eggs owners** - done 2026-10-12: each zone's board shows the boosted odds to pass
      owners (entry below). 7 rarities shipped 2026-10-13: board and EggServer both use `Formulas.luckyWeights`.
- [x] **Egg zones: one design, built** — the walled lane (docs/ZONES_REFERENCE.md), all six zones + bosses, 2026-10-12
      (entries below; user: "make the other 4 zones and their bosses").
- [ ] **Egg tiers vs zones overlap** (decide): the economy pass locks themed eggs by lifetime coins
      (`UnlockEarned`, Pet 1e7) and the zones gate them by Law License (Pet Park, `Config.Zones.License` 5e6 coins).
      Merge rule for now (src/EggServer): a zone egg already bought (`o.paid`) hatches even if its tier is locked, so it
      can't get stuck in the bag; hub machines still check `UnlockEarned`. Probably one gate is enough.
- [ ] **crnuch: set the GitHub default branch back to `main`** (Settings → General → Default branch; it was
      `claude/sharp-dirac-02vssj`, so new cloud sessions may start from that old branch). `ss-rob` isn't an admin.
- [ ] **Re-run the economy sim for the zones** (carry 1/3/5 per trip instead of spamming the machine, golden eggs,
      License/Bag/Shoes costs, minigame rewards — all first guesses in `Config.Zones` / `Config.Minigames`).
- [x] **The 18 Epic / Mythic / Supreme lawyers built, rarity-number audit, `src/` → Studio push (economy pass, egg
      tiers, 7 rarities, schema v17, phone LAWYERS panel, Supreme panel), FirmStages TowerLevel rule** — 2026-10-13
      (entry below). The push's playtest eye-checks are still open (top of this list).
- [x] `GoalService.track(player, "train", count)` - checked 2026-10-12: Studio's GoalService adds `amount or 1`.
- [x] **Brick style rollout** — done 2026-10-11: every lawyer, client, judge and the Manager (entry below).
- [x] Lawyer panel at phone size — in `src/` 2026-10-12 (compact text mode); eye-check after the push (item above).
- [x] Tell mr.robe: the Hud's bottom office card is gone and CaseService/LawyerService changed — mr.robe drives his
      own Claude on this repo now (2026-10-12). CaseService changed again since: no waiting room (entry below).
- [ ] **Fill in Config.Shop Ids** (4 passes, 4 products) from the Creator Dashboard; keep Price in sync.
- [ ] Eye-check the Lawyer Merger panel + merge animation in a playtest (window wasn't rendering during the build).
- [ ] Eye-check the 3D egg hatch end to end on a real hatch (shatter frame, Common timing, phone layout).
- [ ] Eye-check a merged lawyer's Gold / Rainbow tag line (LawyerTags).
- [ ] Eye-check the hatch screen's Rare/Legendary VFX (star flare + slash ring) on a real rare roll.
- [x] Egg-machine floor rings - obsolete 2026-10-12 (the hub egg machines are archived).
- [x] **Pre-Manager auto-assign** — DONE 2026-10-08 (`Case.SelfAssignAfter` 12 s). (review §3, confirmed): AFK players earn 0 and can never afford the Manager.
      Auto-assign a seated client to the best free lawyer after ~10–15 s (CaseService queue is ours).
- [ ] **Slow the economy ~10×** (review A/B/C): `Lawyer.TrainBase` 800 → ~10–12K **together with** new offices
      starting at the firm's lowest office level (`DeskService.upgradeFirm`), or expansions stall. Sim it first.
- [x] **Upgrade ×N / Max / UPGRADE ALL** — in `src/` (economy pass); not in Studio yet (push item above).
- [x] **Egg tiers** — in `src/` 2026-10-12 (unlock milestones + EarnMultiplier); not in Studio yet (push item above).
- [ ] Specialist skill targets 1 of 9 `Config.Clients` entries (review D) — heads-up to mr.robe.
- [ ] Port this repo's sim model into Studio's `Dev.EconomySim` (stale since v12) or retire it (review E).
- [ ] Late-game sink beyond office level 100: prestige into the sim, or new content (review B).
- [ ] Add a `Config` comment next to `Payout.Growth` / `Lawyer.TrainGrowth`: their ratio sets the whole curve.
- [ ] Update DESIGN.md's tutorial + rewards text for v12 (review §7).
- [ ] **Add the user's local files to this repo:** `references/`, `tools/firm_kit.py`, `tools/firm_pieces.py`,
      `tools/voxel_builder.py`, `tools/clients.py`, `ClientPalette.png`. Decide whether `.fbx` exports go in
      (they're big; maybe Git LFS) or stay local.
- [ ] Eye-check Manager / BigCase / Courtroom panels under the new UIKit colours (2026-10-09 UI pass).
- [ ] Ask mr.robe about `ServerStorage.StagePreviews_MovedFromWorkspace` (moved out of Workspace in the perf pass).
- [ ] Publish the lawyer animations (Animation Editor → import .fbx → publish), play Idle at the desk and
      Objection on a win. `PinstripePartner`'s Idle/Walk/Objection are not published yet (user must do it).
- [ ] More hatchable lawyers: add entries to `Config.SkinCatalog` (now the lawyer catalog; ids are saved).
- [ ] Blender remake queue (docs/BLENDER_BRIEF.md): egg machine, palm, props, desk tiers, courtroom pieces.
- [ ] Enable Studio API access (Game Settings → Security) when ready to test saving.
- [ ] Resolve design-doc inconsistencies (listed in docs/ECONOMY.md → "Known inconsistencies").

## 2026-10-20 — mr.robe, local session: the central hub redone to v2 (+ into the place)
- **User's call:** "also change the main island to v2". Backup first: tag `backup-2026-10-20-before-hub-v2` (pushed).
- **`environment-redesign/central_hub_v2/hubv2_build.py`** (doc `HUB_V2.md`): crnuch's approved hub (Stage 3
  `hub_build.py` + `hub_parts.py`, LAYOUT.md + his 5 decisions) kept exactly, rebuilt to the v2 standard: every mesh a
  ClassicMesh (smooth Roblox shapes), one cohesive grass top over a chunky dirt band + the v2 islands' layered rock
  underside (craggy faces, hanging rocks with gold crystals, vines), classic ball trees, cloud puffs + rock islets, studs
  only on broad terrain / paving / decks / roofs. 332k raised studs in the .blend; renders `renders/hubv2_*.jpg`. v1 untouched.
- **`hl_export.py`** skips the hub's example firms (`Plot*_Firm_EXAMPLE`, scale only: FirmBuilder builds the real ones);
  the v1 hub in the place had them as Parts.
- **Into the place:** v1 hub model to `ServerStorage.Old_WorldRedesign_v1` (all seven v1 models now kept there);
  `Workspace.WorldRedesign.CentralHub` = the v2 hub, 20,229 parts (WorldRedesign 112.7k in all). Playtested: `;island hub`
  lands on its south avenue, standing (Running on Plastic). Not wired to gameplay (today's hub still runs firms + spawn).
- **Left:** crnuch's review; an ambience pass; the hub's wiring (firms / spawn / services onto it) is a later step.

## 2026-10-20 — mr.robe, local session: the rest of the islands redone to v2 + all six v2 islands in the place
- **User's call** (mr.robe's PC, after seeing crnuch's Ocean Shore v2 + Briefcase Bay v2): "do the same for the rest of
  the islands and transform them all". Backup first: tag `backup-2026-10-20-before-v2-islands` (pushed).
- **`environment-redesign/kit/hl_v2.py`** = crnuch's Ocean Shore v2 build turned into a shared frame (squircle floor +
  lobes, body + underside, spawn dock + pad and the purple escape portal from osv2's parts, egg regions sized by
  DROP_MAX, scenery-ring helpers keeping everything outside box + reach, the measured checks incl. a radial check for
  Ring / Slam / Pull bosses, the diagram, the 7 renders, the benchmark-shaped layout JSON).
- **Four v2 islands** (Blender, each with doc, .blend, layout JSON, 7 renders; v1 untouched), all checks passing:
  - **Pet Park v2** (`pet_park_v2/`): one striped lawn, Barrister Bulldog's Ring 34 (box 200 x 186, reach 38.5);
    mossy outcrops + park trees, duck ponds + a fall, corgi + cat statues, dog houses, the Barkery + Paw Clinic; 27 spots
  - **Brainrot Zone v2** (`brainrot_zone_v2/`): a lilac checkerboard, Judge Martello's Slam 26 (208 x 190); purple
    crystal cliffs, goo pools + a goo fall, the twisty tower / big screen / melty mall / upside-down house; 27 spots
  - **Food Court v2** (`food_court_v2/`): a giant picnic tablecloth, Big Cheese's 110 x 22 roll (230 x 200, 896/896
    lanes clear); cake cliffs with frosting + chocolate drips, soda / chocolate pools, the restaurants; 28 spots
  - **Space Base v2** (`space_base_v2/`): a cratered moon plate, Eclipse's Pull 44 / Ring 38 (184 x 170, reach 47.8);
    violet moon cliffs with crystals, plasma pools + a fall, the rocket / observatory / domes / factory / dish / UFO; stars; 25 spots
  - honest gaps: no ambience pass on these four yet; not reviewed by crnuch.
- **`hl_export.py`** records crnuch's classic kit now (smooth primitives as real Parts; slabs / rocks / beams / fronds as
  boxes; nothing nested, so nothing doubled) and skips presentation meshes (preview eggs, egg markers, diagram overlays,
  labels - the first export put the diagram 80 studs over each island; fixed before the final build).
- **Into the place:** the six v1 islands moved to `ServerStorage.Old_WorldRedesign_v1`; the six v2 islands built
  (OS v2 25.5k, BB v2 25.9k, PP 12.2k, BR 8.0k, FC 10.6k, SB 10.2k parts; WorldRedesign 120k with the hub);
  `BuildIslandWiring.lua` reads the v2 layouts (Arrival on the spawn pad facing the island, ReturnHome = a walk-in box
  at the portal, set from the floor height (a raycast hit the arch at first), the odds board where the dock meets the floor).
- **Playtested** (switch on): 14 eggs on each v2 island, none on the lane; Travel to Pet Park landed on its spawn pad;
  walking into the escape portal sent the player home. **Buying an egg on a v2 island did not trigger** in this test: no
  ProximityPrompt showed at all with Studio in the background (it worked on v1 the day before with the same code);
  recheck with Studio in front. Probe + test scripts lived only in the playtest; nothing left in the edit place.

## 2026-10-20 — mr.robe, local session: the islands switch turned ON
- **User's call** (mr.robe, after hearing the trade-offs: no bosses on the islands yet, v1 islands, crnuch's "leave
  the place as it is" call, phone fps unchecked): "turn it on". **Heads-up for crnuch:** in Studio the egg zones now
  run on the redesign islands (eggs, Travel, RETURN HOME); the lane keeps its bosses but no eggs. Nothing reaches
  players until someone publishes. To undo: `Config.Zones.Islands.Enabled = false` (src + live).
- Stopped the user's running playtest (they said to), wrote Config (live == snapshot checked first), checked in a
  fresh playtest with no commands: 84 eggs on the islands, 0 on the lane, 6/6 RETURN HOME prompts on. Snapshot
  re-exported. (Studio's `/islands off` can't override the Config switch while it's on.)

## 2026-10-20 — mr.robe, local session: the redesign islands wired into the egg zones, behind an OFF switch
- **User's call** (mr.robe's PC): "wire them up", then, told about crnuch's boss claim + his "leave the place as it
  is" call, picked "behind an off switch" and "make sure the previous version is saved".
- **Saved first:** git tag `backup-2026-10-20-before-island-wiring` (pushed) + `ServerStorage.Backups_2026-10-20`
  (disabled copies of ZoneService, TravelServer, AdminCommands, Config as they were).
- **Heads-up (ZoneService = the egg loop; Config):** new `Server.ZoneMap` (src/ZoneMap.lua) picks the map; ZoneService
  reads its zones through it (`bindZones`, rebinds on a flip; floor raycasts / drop bounds use the island when on);
  TravelServer lands on ZoneMap's Arrival and hooks each island's ReturnHome (home WITH eggs; `move()` shared);
  `Config.Zones.Islands = { Enabled = false }`; AdminCommands `/islands on|off` (Studio only). **With the switch off
  nothing changes** (playtested: 84 eggs on the lane, none on the islands).
- **Live Config had moved** since the snapshot (crnuch's Big Cheese `Crowd` line): 3-way merged (git merge-file, no
  conflicts) - his line kept, only the Islands line added. No boss files touched (his claim), no island rebuilt (his call).
- **`tools/zones/BuildIslandWiring.lua`** → `Workspace.IslandWiring.<ZoneId>` (egg spots, arrival, RETURN HOME trigger
  in the portal ring, odds board), from the v1 layout JSONs. First run put the triggers on top of the portals (the
  raycast hit the ring): now set from the island's origin (y 168.8, the ring's middle).
- **Playtested** (`;islands on`): 14 eggs on each island, lane empty, 6 RETURN HOME prompts on; Travel to Ocean Shore =
  its arrival, facing north; bought an Ocean egg there (real coins); Travel home refused while carrying; the RETURN HOME
  ring sent the player to their firm still carrying it; `;islands off` = back to the lane. The account's carried Space
  egg was set aside for the test and put back (Carried now Space + the Ocean egg bought). No game errors in the output.
- Snapshot re-exported (it also picked up crnuch's live Bosses.client / BossAnims / Config edits from his side session).

## 2026-10-20 — crnuch, local session (side session): Big Cheese's Cheese Roll pushed to Studio
- **crnuch approved** the Cheese Roll + Wheel Split (entry below). Snapshot re-exported first (nothing had changed
  since the Partner push); pushed: `ReplicatedStorage.Bosses` rebuilt (Big Cheese 47 parts / 5 groups, the rest
  unchanged), `Shared.BossAnims`, `StarterPlayerScripts.Bosses`, `Shared.Config` from `src/`. Each replace checked the
  live script still matched the last push first (mr.robe is editing the same place: island wiring).
- **Playtested (1 player):** the whole roll on the clips, no script errors. **Found + fixed:** the wheel dipped 0.35-0.38
  studs into the floor in the burnout and the roll (the client's squash resizes each block along its own axes, which
  overstates a block that's turned AND squashed); a rolling boss is now lifted by whatever its lowest corner would go
  below `FloorY`. After: lowest corner 0.00 throughout, the bump up to 0.65 studs.
- **Heads-up / merge:** mr.robe's session added `Config.Zones.Islands = { Enabled = false }` in Studio right after my
  Config push (on top of it, no conflict); `src/Config.lua` now = live. Snapshot re-exported after: it also carries
  mr.robe's live island-wiring scripts (ZoneMap, ZoneService, TravelServer, AdminCommands, Backups_2026-10-20).
- Open: the 3-player Wheel Split playtest (Open items).

## 2026-10-20 — crnuch, local session (side session): Prosecutor Big Cheese's CHEESE ROLL + WHEEL SPLIT (Blender + src/)
- Third boss of the overhaul (crnuch: "make the food guy next"). docs/BOSS_ANIMATION.md **section 7**: his real timeline
  (Line: windup 1.2, roll up to 110 studs at 120 = 0.92 s, no dizzy, recover 0.6), the storyboard, what was built.
- **Model v2** (`tools/blender/bosses.py`): `Lids` + `Moustache` groups (same 47 blocks). Other five byte-identical.
- **The roll stays code, now exact** (client): distance / (R x Scale) + the clip's `Roll` channel (the burnout), the
  recover's `Unroll` channel stands him upright in a hop (he used to unwind backwards on the spot). New per-boss
  **`RollLift`** in `Shared.BossAnims` (72 values the engine measures from the model): the block wheel's corners used
  to sink up to 1.2 studs into the floor every turn; now it bumps over them. Arms tuck into the wheel for the roll.
- **Engine** (`tools/blender/boss_anims.py`): `check_fold` per boss (state / time aware), `ROLL_LIFT` export; new
  `tools/blender/boss_clips/big_cheese.py` + `_preview.py`. Megalodon + Partner clip data unchanged.
- **Clips** windup 37 / launch 7 / loop 7 / brake 7 / recover 19 frames. Clipping worst 0.27 studs (one frame) on a
  20-stud boss; the floor 0.06 at worst.
- **src/ (NOT in Studio - waits for approval):** `Bosses.client.lua` (roll + RollLift + Unroll, `cheeseFx`: olive
  gleam, landing dust, wedges pop off / wait / tumble / crumble, burnout dust + crumbs, launch ring, roll trail, brake
  plume, stop + hop landing), `Config.lua` (his `Crowd`: Lane, Max 2, Range 90, Width 12, Speed 110, Length 100 - the
  server's existing Lane add-on, no BossService change), `src/BossAnims.lua`.
- **Preview + review page:** `art/bosses/big_cheese/`; https://claude.ai/artifact/7FKSXgNPpwP2Wnt8WHpmW3 (private).
- **Next (after approval):** `tools/zones/BuildBosses.lua` (v2 model), replace `Shared.BossAnims`, `Bosses` (client) and
  `Shared.Config` from `src/` (re-export the snapshot first), playtest (watch the bump and the hop at the zone floor).

## 2026-10-20 — crnuch, local session (side session): The Senior Partner's Briefcase Swing pushed to Studio
- **crnuch approved** the Briefcase Swing + Paper Storm (2026-10-19 entry below). Pushed: `ReplicatedStorage.Bosses`
  rebuilt with `tools/zones/BuildBosses.lua` (Partner 72 parts / 12 groups, the other five unchanged; 126 z-fight
  nudges), `Shared.BossAnims`, `StarterPlayerScripts.Bosses`, `Server.BossService`, `Shared.Config` replaced from `src/`
  (snapshot re-exported first: the live scripts matched the Megalodon push exactly, so no merge was needed). Each is one
  ChangeHistory step. Snapshot re-exported after: only those four scripts changed; `src/` == live for all four.
- **Playtested (1 player):** windup -> attack -> recover -> walk on the clips; the case reaches the zone floor at
  attack +0.09 s; lid opens 78 deg; paper bursts and rings fire; no script errors. **Bug found + fixed** before it
  stayed live: the client looked up `FindFirstChild("CaseLid", true)`, which found the CaseLid GROUP Model, so the lid
  burst and the strike effects errored; now `blockOf(b, name)` searches the boss's parts.
- **Heads-up:** ports 8766 / 8767 on crnuch's Mac are held by old python servers from earlier sessions (Oct 16 / 18);
  this session used 8769 (`receive_snapshot.py --port 8769` + ExportSnapshot with PORT 8769) and 8770 (file server).
- Open: the 3-player Paper Storm playtest (Open items).

## 2026-10-19 — crnuch, local session (side session): The Senior Partner's BRIEFCASE SWING + PAPER STORM (Blender + src/)
- Second boss of the attack-animation overhaul, on the Megalodon benchmark. docs/BOSS_ANIMATION.md **section 6** =
  his real timeline (Cone: windup 1.2, everyone in the fan hit on the attack's FIRST frame, attack 0.45, recover 0.6),
  the frame-by-frame storyboard, the Paper Storm, what was built and checked.
- **Model v2** (`tools/blender/bosses.py`, 68 -> 72 blocks, 12 groups): Brows, Glasses, Moustache, Case (swings on its
  handle) and CaseLid (hinged; files inside). Other five bosses export byte-identical.
- **Engine made generic** (`tools/blender/boss_anims.py` + `tools/blender/boss_clips/<boss>.py` / `<boss>_preview.py`,
  arg `boss=SeniorPartner`): Megalodon's JSON + Luau export byte-identical. New: per-boss `Turn` (exported only when
  not the default), a ground check, hip folds reported apart. `encode_preview.py` takes a 5th arg (boss phases).
- **Clips** windup 37 / attack 15 / recover 19 frames -> `src/BossAnims.lua` (both bosses, 60 KB). The case lands at
  attack + 0.05 s. Clipping worst 0.27 studs on a 38-stud boss (hip folds 0.39, hidden inside the jacket).
- **src/ (NOT in Studio - waits for approval):** `Bosses.client.lua` (`partnerFx`: stomp, paper swirl, lid burst,
  clasp gleam, strike rings / dust / clods / paperwork, yank; the Papers group spun by code from the clip's Swirl
  channel; per-boss turn + lead group; Disc crowd warnings; flying bundles + shadows; the old 0.16 s-late Cone burst is
  skipped for a boss with clips), `BossService.lua` (crowd add-on generic for every attack kind: `releaseCrowd`, Lane
  or **Disc**; new state attrs `CrowdShape`, `CrowdRadius`), `Config.lua` (Partner `Crowd = { Shape = "Disc", Max = 2,
  Range = 90, Radius = 10 }`). config_tests: Disc fairness (smaller than the main attack, walk-out < half the
  windup), Cone attack clip = 0.45 s, the turn inside the windup. All checks green.
- **Heads-up (gameplay, mr.robe's BossService):** with 2+ players in Briefcase Bay, bundles land on up to 2 other
  players' spots (warned 1.2 s). Megalodon's lanes are now released by the same `releaseCrowd` (same behaviour).
- **Preview + review page:** `art/bosses/senior_partner/` (15 storyboard frames, 3 MP4s, the .blend);
  https://claude.ai/artifact/RNpXrekSGvU3QnjdRBuses (private to crnuch; share it for mr.robe).
- **Found in passing (not changed):** the LIVE Megalodon's recover clip has its left fin 0.56 studs into the body /
  0.48 into the snout for a couple of frames (the glasses push after round 3's fin re-seat); `-- check` shows it.
- **Next (after approval):** run `tools/zones/BuildBosses.lua` (v2 Partner model), replace `Shared.BossAnims` with
  `src/BossAnims.lua`, 3-way merge `src/Bosses.client.lua`, `src/BossService.lua`, `src/Config.lua`, playtest with
  1 and 3 players (QualityLevel high for particles); check the case meets the zone floor at the strike.

## 2026-10-19 — crnuch, local session: boss attack animation overhaul — Megalodon benchmark (Blender + src/)
- crnuch's brief: overhaul all six bosses' attacks (anticipation / attack / impact / recovery, squash + stretch,
  secondary motion, effects, sound) with no gameplay change; Megalodon first, the rest after approval. Mid-session,
  crnuch's call: **bosses must threaten every player on the island at once** (1 player = dangerous but manageable,
  3 players = it reaches all three) - a gameplay change, designed for all six, built for Megalodon.
- **Audit + storyboard + crowd design:** docs/BOSS_ANIMATION.md (how bosses really work: Blender block groups posed
  by `POSES` sine functions in Bosses.client, no rigs; Megalodon's real timeline; the frame-by-frame storyboard;
  section 4 = the six crowd add-ons). Note for crnuch: the server targets the NEAREST player, not "the one carrying
  eggs" as the brief says - left as is (a targeting change; say if you want it).
- **Model v2** (`tools/blender/bosses.py`): Megalodon split into 13 groups (jaw hinge, fin + FinGlow, eyes, glasses,
  lure, cape); bosses.py now finds the repo on any machine. Other five bosses export byte-identical.
  `tools/zones/BuildBosses.lua`: new `glow` tag (Neon, hidden until the client lights it).
- **Clips + preview** (`tools/blender/boss_anims.py`, `tools/blender/encode_preview.py`): six clips keyed to the
  server timing, exported to `src/BossAnims.lua` (= `Shared.BossAnims`, generated); a per-frame clipping check (worst
  left 0.33 studs, one frame); storyboard + 3 MP4s + the .blend in `art/bosses/megalodon/`.
- **src/ (NOT in Studio - waits for approval):** `Bosses.client.lua` (generic clip player, squash, glow, whip-round
  turn, frenzy lanes + sand sharks, sand / streak / spray / plume effects, star dizzy), `BossService.lua` (generic
  Crowd add-on, Lane shape: sand-shark fins race at up to 2 other players within 90 studs, 12 wide, 120 studs/s,
  warned from the same 1 s windup), `Config.lua` (Megalodon `Crowd`). Checks: two new config_tests (crowd fairness,
  clip lengths vs Config / BossService); `run_checks.py` bundles BossAnims. All checks green.
- **Heads-up (gameplay):** the Crowd add-on changes `BossService` (mr.robe's core) - only when 2+ players are in a
  boss's zone; nothing else in the boss AI moved.
- **Round 2 (crnuch: "teeth 3D and inside its mouth", "top head still connected to the bottom when it yells"):**
  a real mouth cavity with 3D teeth in gums, and cheek flaps (new `Cheek` group, half the jaw angle) that close the
  sides when it opens. Re-rendered previews + `mouth_*.png` close-ups; checks green.
- **Review page:** https://claude.ai/artifact/1V8cbTiD2YNckxRuVkfGQp (private to crnuch; share it for mr.robe).
- **Round 3 (crnuch: "the shark's fins are detached"):** the side fins tilted top-OUT in the original model, so their
  root floated ~1 stud off the body; now the root sinks into the shoulder and the tip flares out (`ry = -side * 15`).
  The glasses-push path widened to match.
- **APPROVED (crnuch) and pushed to Studio:** `ReplicatedStorage.Bosses` rebuilt (Megalodon 58 blocks / 14 groups,
  other five unchanged), new `ReplicatedStorage.Shared.BossAnims`, and `Bosses` (client) / `Server.BossService` /
  `Shared.Config` replaced from `src/` (live scripts matched the snapshot exactly, so no merge was needed).
  Targeting stays NEAREST player (crnuch's call). Snapshot re-exported (114 scripts; only these four changed).
- **Playtested (1 player):** walk -> windup -> charge -> dizzy -> walk all on the clips (squash to 0.88, fin glow to
  0.41 transparency, jaw to 24 deg), fin roots stay 0.21 studs inside the body all the time, no errors / warnings
  from any script (client + server). **3-player test skipped** (crnuch) - open item above.
- **Next:** the other five bosses one by one, each with its crowd add-on (docs/BOSS_ANIMATION.md section 4).

## 2026-10-19 — crnuch, local session: Briefcase Bay v2 — DETAILED pass (Blender)
- **crnuch's call:** the Briefcase Bay v2 layout approved, keep the skyline; detailed modelling started.
- **New pieces** (`environment-redesign/briefcase_bay_v2/bbv2_detail.py`):
  - the skyline: six towers, each its own silhouette, on a podium with a colonnade, a revolving door and a gold name
    (fictional firms): AMICUS (glass pyramid), DOCKET & CO (a gold briefcase on the roof), VERDICT (setbacks),
    LEXICON LAW (a glass cylinder + dome), HABEAS (twin shafts + skybridge), CASEWORKS (crown frame + helipad);
  - the portal dressed for the bay (gold trim, a gold briefcase keystone, lamps, topiary, flower beds);
  - the harbour: the Bay Ferry (rails, cabin, wheelhouse, lifebuoys, funnel, its name), a sailboat, buoys, bollards
    with rope, lifebuoy stands, cargo; the lighthouse with the keeper's cottage and its beam;
  - the welcome fountain (a gold briefcase spouting four arcs); park trees (oak / blossom / conifer), topiary, kerbed
    flower beds; the monuments with stitching, a luggage tag, papers and plaques.
- **Scenery** (layout, lawn, his box, eggs, spawn + portal unchanged): the towers stand on two raised limestone
  shelves either side of the portal (craggy faces, planted terraces in front); lamp posts + benches face the lawn
  from outside the hedges; flower beds, topiary and lamps round the arrival terrace.
- **Checks** all still green (box 100% open lawn, 0 hidden warning points, no safe bypass, spawn → portal level);
  new: nothing that moves passes over his lawn but his own papers (gulls 4+ studs outside its edge).
- **Ambience** in the .blend (`bbv2_ambience.py`, no clips): wind, water, boats bobbing, cascade splash + mist, edge
  spray, fountain splashes, sparkles, portal motes, tower crowns + aviation lights (0.5 Hz) + lantern, the lighthouse
  beam sweeping the sea side (hidden in stills), blossom petals, butterflies, 8 gulls, papers at his ankles.
- **Audio picks** (CC0, licence read on each freesound page): city-park bed, birds, harbour lapping, a distant
  foghorn, the fountain, paper rustles; gulls, falls and wind reuse Ocean Shore v2's picks.
- 546k tris + 326k studs, 8.6 MB .blend, 8 renders (a new bay view). **Fixed in review:** the lighthouse beam read as a
  solid plank in daylight stills (hidden in renders, kept for the ambience); two gull circles crossed the lawn's edge.
- **crnuch's call: Briefcase Bay v2 APPROVED** (2026-10-19). The other islands follow the benchmark one at a time when
  crnuch asks (not started); the claim is released.

## 2026-10-19 — crnuch, local session: Briefcase Bay v2 — audit + LAYOUT for approval (Blender)
- **crnuch's call:** redo Briefcase Bay on the Ocean Shore v2 benchmark (audit, then a layout for approval).
  v1 (`environment-redesign/briefcase_bay/`) untouched as the backup; v2 in `environment-redesign/briefcase_bay_v2/`.
- **Audit (code):**
  - The Senior Partner: Cone 45 studs x 110 deg, 1.2 s windup, every 3.5 s inside TriggerRange 60.
  - Walk 38 (> players' 32); 37.8 tall, body 23 wide; idle patrol in a +-14 band.
  - Drops: up to 20.7 studs, clamped 4 inside Bounds; **no Floor under a drop = it lands at y 0** (`ZoneService.floorAt`).
  - v1's arena + hedged parks + portal past the arena is exactly what the benchmark rules out.
- **Layout:**
  - one open studded lawn (the Green); his box is 200 x 170, the lawn grows it by 30-44 studs (organic) so every
    place on it is inside his swing;
  - the arrival terrace S (BRIEFCASE BAY arch, spawn pad), the escape portal N (Ocean Shore v2's portal in limestone),
    a flush orange path across, his start pad with a gold scales inlay;
  - 5 egg regions / 27 spots (Welcome Lawn safer ... Ledger Row on his patrol line, Skyline Lawn on the way out);
  - the ring (out of his reach): limestone cliffs, the cascade, 4 pools, a grotto, a rock arch, the bay (quay, pier,
    ferry, an edge fall), a lighthouse, a six-tower glass skyline, the giant briefcase + gavel, ball / blossom
    trees, palms, hedges marking the lawn's edge.
- **Checks** (measured, real numbers):
  - box 2193/2193 open lawn; 1008 sampled swings, 0 of 98k standable fan points covered;
  - dodge: 20.2 studs needed vs 38.4 in the windup; spawn 83 / portal 82 studs out;
  - spawn → portal level; **no safe bypass**.
  - Drops with today's code: 94-96% land on the lawn. **New integration item, Ocean Shore v2 too:** step a drop with no
    Floor under it back toward the player; an invisible wall at the playable edge (OSv2's moss ring is walkable today).
- **For crnuch to decide:** keep the skyline + harbour + monuments as Briefcase Bay's identity in the ring, or go
  all-natural like Ocean Shore (the layout stays either way).
- **crnuch's call:** layout APPROVED, keep the skyline; detailed pass next.
- **Kit:** `bbv2_parts.py` (tower, lighthouse, ferry, giant briefcase / gavel, welcome arch, ball tree, lamp, bench,
  hedge, path, scales pad, lawn decor); Ocean Shore v2's pieces reused unchanged (rock looks recoloured to limestone
  for this island only).
- 457k tris + 322k studs, 7.2 MB .blend. **Fixed in review:**
  - the lawn read as a square baseplate (now an organic edge, bolder patches, clover meadows);
  - the bay's water hid under its quay;
  - a canopy hung over the lawn;
  - the walk check tripped on the overhead sign;
  - the boss-view camera sat in his face.

## 2026-10-19 — mr.robe, local session: world redesign island 6 — Space Base (Blender + into the place)
- **User's call:** "model the space base island" (the one island the redesign hadn't modelled).
- **Space Base** (`environment-redesign/space_base/`; doc `SPACE_BASE.md`), a lunar base under a starry sky:
  - route landing pad → SPACE BASE airlock gate → orange path past the rocket + gantry and statues of the game's Space
    lawyers (Comet, Nebula, Supernova Sovereign) → MISSION CONTROL PLAZA (a turning hologram planet, 8 kiosks, neon
    light strings) → Crater Field / Alien Garden / Crystal Field → THE ECLIPSE RING (round, r 72) → ringed-planet
    RETURN HOME
  - observatory (turning dome), habitat domes, robot factory (radar), solar farm, fuel depot, a big turning dish, a
    UFO landing (fictional); craters, alien plants, crystals; two plasma falls; drifting asteroids; 24 egg spots; the
    Space egg (purple, gold ring band, neon stars)
  - Eclipse check: Pull r 44 / gavel ring r 38 from a 52 × 52 boss area stay on the r 72 floor; nothing outside the
    ring is reachable; crossing the ring is the way home
  - 404k tris + 197k studs, 6.0 MB .blend; 7 renders; ambience in the .blend; CC0 audio picks (hum, beeps, rumble)
  - the sky in Blender: a deep-space background (Light Path: the camera sees dark space, the scene stays lit), 900
    stars, a ringed planet, a moon (`Sky_Backdrop`: hl_export now skips `Sky_*` meshes)
- **Into the place:** exported (13,283 parts) and built in `Workspace.WorldRedesign.SpaceBase` at its NW ring slot
  (3220, 150, -1858) - BuildRedesignIsland's LAYOUT has it now; checked from the landing pad in Studio. `/island space`
  should reach it (the command finds islands by name; not playtested for this island).
- **Left:** crnuch's approval; a space skybox / Lighting for this island when the islands get wired.

## 2026-10-19 — mr.robe, local session: the redesign islands built into the place
- **User's call** (on mr.robe's PC, after Ocean Shore): "just build them" — the islands go into the game now, without
  waiting for approval. Heads-up for crnuch: this is Stage 7 started on that call; today's hub, lane and gameplay are
  untouched, the islands sit beside them, unwired.
- **Pipeline:** `environment-redesign/kit/hl_export.py` records every kit primitive of an island's build script as a
  Roblox part (bricks, cylinders, rings as boxes, prisms as rows of boxes, gables as WedgeParts, upright rings, sign
  text, statues; studs + bosses left out); `kit/export_island.py` runs a build with it (saving nothing to the .blend)
  → `tools/zones/redesign/<Island>.json`; `tools/zones/BuildRedesignIsland.lua` builds `Workspace.WorldRedesign.<Island>`.
- **Live in Studio:** hub 27.6k parts at (3600, 150, -1200); Briefcase Bay 11.5k, Pet Park 13.9k, Brainrot Zone
  10.9k, Food Court 13.9k, Ocean Shore 17.1k on a ring of 760 round it (~95k parts; the place had ~19.5k). Each built
  in 2-6 s, ZFight passes included. Checked: the overview and Ocean Shore's gate match the Blender renders.
- **`/island <name>`** (AdminCommands, src + live, snapshot re-exported): streams the island in and drops you on its
  south side. Playtested: `;island ocean` landed on Ocean Shore's path (Running on Plastic), all 17,138 parts
  streamed, no game errors in the output.
- **Not done:** the wiring (Travel, eggs, bosses, RETURN HOME, firms on the hub), raised studs, Space Base, a phone
  fps check (open items).

## 2026-10-19 — mr.robe, local session: world redesign Stage 5, island 5 — Ocean Shore (Blender)
- **User's call** (on mr.robe's PC): "do what mr blox was doing, save the current version as a new copy and then add
  the island he was working on". The island work in the repo was the world redesign (logged under crnuch), so this
  session built the next island, Ocean Shore, the same way as islands 1-4. **The copy:** git tag
  `backup-2026-10-19-before-ocean-shore` (= 42210b1, pushed) holds the version from before. No Studio, gameplay or
  map change (the redesign stays Blender only).
- **Ocean Shore** (`environment-redesign/ocean_shore/`; doc `OCEAN_SHORE.md`), a sunny tropical beach:
  - route arrival (on the sand) → OCEAN SHORE gate (two giant surfboards + a driftwood beam) → orange path past the
    lighthouse, giant sandcastles and statues of the game's Ocean lawyers (Hammerhead, Narwhal, Tidal Sovereign) →
    SEASIDE PLAZA (Big Blue the whale fountain, 8 tiki shacks, bunting) → Coral Garden / Tide Pools / Sandcastle
    Beach egg fields → THE SHARK DOCK over a turquoise lagoon (Megalodon at 3.2×) → shell-keystone RETURN HOME
  - a sand beach all round a green middle (a wavy shoreline at ~80 % of the radius); SURF CLUB, AQUARIUM, BOAT HOUSE,
    BEACH CAFE, SEASIDE HOTEL, a SHIPWRECK; palms; 87 beach props; two waterfalls; 24 egg spots; the Ocean egg
  - Megalodon check: the dock is 72 × 148, so his 130-stud Fin Charge fits along it (boss area 56 × 132); the
    plaza's north edge is 20 from the area (inside TriggerRange, but charges are clamped to the dock: a scare)
  - 579k tris + 238k studs, 8.6 MB .blend; 7 renders; ambience in the .blend: lighthouse beam sweeping, two turning
    signs, whale-spout spray, tide-pool bubbles, gulls, water, tiki flames, Megalodon's sway, palm wind
  - audio picks (waves, gulls, beach children): CC0, licence read on each freesound page (curl)
- **Kit:** `hl_kit.font()` also finds the Windows fonts (Arial Rounded / Arial Black), so labels + signs match on
  either machine; looks named `beam*` are faint see-through light (the lighthouse beam).
- **Fixed in review:** the whale read as a blue blob from the south (now faces arriving players, big eyes, fins);
  plank seams on the dock showed the water (dark sub-deck); the beam read as a solid plank in stills (fainter);
  sign boards clipped low roofs (now on the eaves); the NE path ran through the lifeguard tower (re-routed).
- **Left:** crnuch's approval of Ocean Shore (and Food Court); Space Base is the last island.
## 2026-10-19 — crnuch, local session: Ocean Shore v2 — DETAILED pass (Blender)
- **crnuch's call:** the Ocean Shore v2 layout approved; detailed modeling started.
- **New pieces** (`environment-redesign/ocean_shore_v2/osv2_detail.py`):
  - landscape: stacked-stone cliff columns (moss caps + drips, vines, plants on top); palms in 5 styles (leaflet
    fronds, coconuts, young + dead fronds); bushes, hibiscus, grass
  - sea life: brain, tube, staghorn and fan coral; seaweed, conches, sand dollars
  - water: foam outlines, a 3-step cascade with a foam landing + mist, edge falls with lip foam + spray
  - the shipwreck (ribs, keel, torn sail, ropes, barrels + crates); dock torches + rope rails
- **Scenery** (the layout, sand, his box, eggs, spawn and portal unchanged):
  - continuous cliff massifs (a smooth height profile, columns joined by connectors, terraces, boulders)
  - the NW high cascade, 6 foam-edged pools with coral gardens, 4 edge falls (W under an arch, E, a double SE)
  - 8 shoreline inlets on the margin, the N sea arch, the W cave, the E wreck, ~150 plants
  - a dirt band + roots under the rim, floating islets, drifting clouds
- **Checks** all still green (his box 100% open sand, 896/896 charges clear, eggs 24.2-68.5 studs from the edge vs
  20.7, spawn → portal level, no safe bypass, scenery 18+ studs out of his reach).
- **Ambience** in the .blend (`osv2_ambience.py`, no clips): wind, water, cascade splashes + mist, edge spray,
  pool sparkles, portal motes + glow, torch flicker (< 3 Hz), clouds, islets, 6 gulls, Megalodon's idle.
- **Audio picks** (CC0, licence read on each page): waves, seagulls, wind, tropical birds, waterfalls, rock
  splashes.
- **Doc** `OCEAN_SHORE_V2.md`: deliverables, audit, checks, asset catalog, 14 Roblox integration considerations,
  answers to the brief's approval questions, weaknesses.
- 511k tris + 298k studs, 9.0 MB .blend. Fixed in review:
  - the cliffs read as separate pillars (now continuous massifs)
  - the studded dirt chunks looked like LEGO (soil stays smooth)
  - an islet was too close to the island
  - the doorway vortex overlapped the round one (now one door shape)
- **crnuch's call: Ocean Shore v2 APPROVED as the benchmark** (2026-10-19). The other five islands get redesigned to
  it one at a time when crnuch asks (not started); the claim is released.

## 2026-10-19 — crnuch, local session: Ocean Shore v2 — audit + LAYOUT for approval (Blender)
- **crnuch's brief** (+ concept image `environment-redesign/references/ocean_shore_concept.webp`): redesign Ocean
  Shore as a natural tropical wilderness in **classic Roblox studs, not LEGO**, around the real Megalodon mechanics;
  layout first, detailed modeling only after approval. Recorded in docs/ART_STYLE_STUDS.md + CLAUDE.md.
- **Audit (code = authority):** Megalodon 25.6 tall / 14.8 wide; hitbox 14 wide; Line 130 x 20 at 150 studs/s,
  Windup 1.0, Dizzy 2, every 2.8 s within 60; walks 42; targets the NEAREST player in the zone (docs/BOSSES.md says egg
  carriers: the code doesn't); goals clamped to Bounds - Margin; idle patrol ±12 round the box's middle; drops scatter
  up to 20.7 studs (12 eggs), clamped to Bounds - 4, raycast onto Floor/Path; 14 eggs max; no travel while carrying.
- **Layout** (`environment-redesign/ocean_shore_v2/`; doc `OCEAN_SHORE_V2.md`): one flat studded sand plateau round
  Megalodon's 240 x 210 box; spawn on a lantern boardwalk SW (77 studs out of reach); a level purple escape portal NE
  in craggy rocks; his start pad = a ring of sunken stones; 5 egg regions / 28 candidate spots on the open sand; cliffs,
  pools, waterfalls, ~50 palms, a sea arch, a cave and a shipwreck all 18+ studs clear of his reach.
- **Measured checks** (the build computes them): his box 100% open sand; 896/896 sampled charges clear (350 full
  130); eggs 26.5-70.8 studs from the edge vs 20.7 scatter; spawn → portal walkable; no route avoids his reach.
  Pending (needs Roblox): his patrol band + arena box (code), warning readability over decor, Floor tagging for drops,
  the portal's home-with-eggs rule.
- **Kit:** `kit/hl_classic.py` (ClassicMesh: the smooth Roblox-Part primitives back + cohesive `slab`, faceted `rock`,
  `beam`, `frond`); `K.studs_done(only=)` filter + world-grid studs on big organic faces.
- Renders: aerial (the concept's angle), top-down, gameplay diagram, spawn / eggs / boss / portal views.
  **Waiting for crnuch's approval: no detailed modeling until then.**
- **crnuch's note on the layout:** "the portal frame looks slightly detached and could use more detail". The ring sat
  above its base with the rocks apart: now a rock arch planted on two buttress legs (its ends gripped, the vortex a
  door shape down to the ground: still a level walk-in), runes, a moss cap + vines, a crystal keystone, crystals,
  coral, ferns, a studded stone base, stepping stones, two palms leaning over. Checks unchanged (all pass).

## 2026-10-19 — crnuch, local session: world redesign — studded voxel on EVERYTHING (kit + all five areas rebuilt)
- **crnuch's call:** "when i say i want studded voxel on everything i genuinely mean everything". Recorded in
  docs/ART_STYLE_STUDS.md ("Everything means everything") + CLAUDE.md: no smooth round or sloped shape on any object,
  studs on every exposed top (bosses, statues, eggs, liquids, clouds included). Exceptions: sign lettering (printed;
  SurfaceGui text in Roblox) and pieces under ~half a stud wide.
- **Kit (`environment-redesign/kit/`):**
  - `hl_kit.Mesh`: cyl / ring / cone / sphere / prism / wedge / pyramid / ring_v / disc_v now build stepped bricks on
    the 1-stud grid, turned with their frame (pixel circles, voxel balls, stepped slopes; big cones use 2-stud cells
    and at most 10 steps so the cliff rocks stay light). `disc_v(look_at=)` colours cells (one disc, no overlapping
    bands)
  - `K.studs_done()` is now THE STUD PASS: raised studs on every exposed top face of every object (BVH rays at each
    stud's centre + corners, coplanar duplicates dropped). Each object owns its instancers (`Studs_<object>_<look>`,
    parented), so wind, drift, turning signs and boss idles carry their studs. The old per-call `studs=` flags,
    `add_studs`, `K.STUD_GROUP`, `Studs_Still_*` and `grass_studs()` are now no-ops
  - `hl_ambience.wind` sways the named objects' own studs; particle motes are little cubes
- **Voxel gotcha (fixed where found):** a band made as a slightly wider cylinder over the same height lands on the same
  cells as the body (z-fighting): stack bands as their own segments. Fixed: Food Court bottles / lamps / chimney / soda
  basin / lollipops, Briefcase Bay's coffee cup + gavel band, the hub's glass-case glow, Pet Park's food bowl.
- **Rebuilt + re-rendered** (build + ambience, no clips): hub 1.34M tris + 1.14M studs (19.0 MB .blend); Briefcase Bay
  656k + 384k (9.2 MB); Pet Park 740k + 365k (10.5 MB); Brainrot 631k + 358k (8.8 MB); Food Court 778k + 410k
  (10.9 MB). Studs cast no shadows (as the Roblox stud tiles: CastShadow = false). Ground views take ~1-4 min each on
  this Mac now. `Island.keep_views_clear(CAMS)` keeps groves out of the ground cameras' foregrounds (a Brainrot grove
  had landed in front of the boulevard camera).
- **Merged with mr.robe's work from the same afternoon** (Ocean Shore, Space Base, the islands built into the place):
  - Ocean Shore (918k tris + 504k studs, 13.0 MB) and Space Base (1.01M + 383k, 13.4 MB) rebuilt + re-rendered voxel
  - `kit/hl_export.py` now records BRICKS only (every voxel primitive is bricks; its old Cylinder / Ball / WedgePart
    recorders would have exported every round piece twice, and crashed on the frames' new `rot` argument)
  - all seven `tools/zones/redesign/*.json` re-exported voxel: 165k parts in all (hub 37.0k, BB 18.2k, PP 19.9k,
    BR 18.2k, FC 21.9k, OS 25.9k, SB 23.4k) vs 108k pre-voxel. **Not rebuilt into the place** (open item)
  - the stud pass skips `Sky_*` backdrops (Space Base's far planet + moon: 1,000+ studs out, as the exporter does)

## 2026-10-19 — crnuch, local session: world redesign Stage 5, island 4 — Food Court (Blender)
- **crnuch's call:** Brainrot Zone approved.
- **Food Court** (`environment-redesign/food_court/`; doc `FOOD_COURT.md`), an oversized food festival:
  - route arrival → ketchup + mustard bottle gate holding a giant hot dog → orange path past a giant burger, a
    fries box, food trucks and statues of the game's Food lawyers (Chili Prosecutor, Dragon Fruit Duke, Grand
    Gâteau) → THE FOOD COURT PLAZA (soda-cup fountain, 8 stalls with giant food on their roofs, seating, string
    lights) → Picnic Park / Dessert Garden / Veggie Patch egg fields → THE CHEESE BOARD (Big Cheese at 3.2×) →
    cherry-keystone RETURN HOME
  - six restaurants (BURGER BARN, PIZZA PALACE, FRY FACTORY, DONUT DINER, TACO TOWER, NOODLE HOUSE), soda +
    chocolate waterfalls (angles picked clear of everything), fruit orchards; 24 egg spots; the Food egg (bun body,
    frosting cap, sprinkles)
  - Big Cheese check: a long 72 × 130 board so his 110-stud roll fits along it; the board ends are computed from the
    portal stairs. Fields are out of his reach (attacks are clamped to his area); crossing the board is the danger
  - 439k tris + 224k studs; 7 renders; ambience in the .blend: steam (stall vents, factory), smoke (oven, grill),
    three turning signs carrying their own studs, soda / chocolate flow, twinkling lights, Big Cheese's wobble,
    orchard wind
  - audio picks (restaurant crowd, kitchen, sizzle, cash register): CC0, licence read on each page (via curl:
    WebFetch couldn't reach freesound.org today)
- **Kit:** `animate_water(..., highlight=)` (soda / chocolate sheen instead of water blue); `pivot_to` moves a
  turning object's own stud instancers too; `choco*` liquids nearly opaque.
- **Found + fixed:** BossService clamps Slam landings and Line rolls to the boss's area (`Bounds` minus `Margin`), so
  Brainrot's Upside-Down Park is a scare, not a hit (doc corrected), and island arenas need their area set directly
  at integration (README → "Notes for Stage 7").
- **Fixed in review:** a peach horizon flooded the aerial (back to blue); the plaza camera sat inside a stall; steam
  from the counters would have hit the stall roofs (now from roof vents); the soda pours read as posts (thinner, foam
  splashes); the hot dog's sausage hid behind its bun; too many bottle lamps at the plaza entrance.

## 2026-10-19 — crnuch, local session: world redesign — hub / Briefcase Bay / Pet Park .blends rebuilt (studs ride their objects)
- **Rebuilt** `central_hub.blend`, `briefcase_bay.blend`, `pet_park.blend` (build `-- norender`, then the ambience with
  no stills / clips). The approved JPG renders are untouched; the layout JSONs came out identical.
- **Hub clouds:** `hub_build.py` built its clouds inline, so it now sets `K.STUD_GROUP` round them like `Island.clouds`.
- **New kit fix, found while verifying:** hedges / planters / rooftop gardens in a canopy look (`leaf`, `leaf_light`)
  on meshes that don't sway put their studs in the swaying `Studs_leaf*`, so those studs swayed off still leaves:
  - worst case the hub's two example firms' roof planters (z 37, up to 0.5 stud); Pet Park buildings up to 0.2
  - `hl_kit.add_studs` now gets the owning mesh's name. A canopy look on a mesh not in `K.SWAYING`
    (Vegetation, Street_Trees) goes to `Studs_Still_<look>`, which the wind never touches.
  - **A new island whose ambience sways another mesh must add that mesh's name to `K.SWAYING`.**
  - Brainrot already passed this check, so its .blend wasn't rebuilt.
- **Verified headless** on all three (+ Brainrot):
  - `Studs_Clouds_Islets_*` exist and are parented to `Clouds_Islets`
  - at frame 240 they sit exactly at the cloud's drift
  - no island-wide stud sits on a cloud face
  - no swaying stud sits on a still object's face above z 4.5
  - `run_checks` passes
- Still open, not fixed: on the hub, 1810 `grass` and 122 `rock` studs on Vegetation pieces above z 4.5 stay put
  while the wind sways them (grass-topped mounds / rocks: at most ~0.13 stud at those heights). Brainrot has a few
  (`violet`, `rock`).

## 2026-10-19 — crnuch, local session: world redesign Stage 5, island 3 — Brainrot Zone (Blender)
- **crnuch's call:** Pet Park approved.
- **Brainrot Zone** (`environment-redesign/brainrot_zone/`; doc `BRAINROT_ZONE.md`), a surreal neon island at dusk:
  - route arrival → glitched gate → zig-zag neon boulevard with giant statues of the game's own brainrot lawyers
    (CactusinoAvvocatino / DraghettoSpaghetto / ImperatorePinguino from `lawyers_top.json`) → Glitch Garden /
    Wobble Square / Upside-Down Park egg fields → THE GAVEL PIT (Judge Martello at 3.4×) → brain-keystone RETURN HOME
  - five neon towers (made-up signs only), Big Screen, Twisty Tower, Melty Mall, goo waterfalls, floating cubes +
    eyeballs, gelato / traffic cones; 24 egg spots; the Brainrot egg design (purple, neon zig-zags)
  - Martello check: open floor r 52 vs Slam r 26; suggested Bounds = the square inside the floor; Upside-Down Park
    is the one field inside his 60-stud trigger (4 eggs, by design)
  - 332k tris + 210k studs; 7 renders; ambience in the .blend (neon breathing, goo, cube bob, Martello's hop, sparkles, wind)
  - audio picks (synth bed, neon hum, glitch, boing): CC0, each licence read on its page
- **Kit:**
  - `hl_island.model_from_parts` (bosses + now `lawyer()` statues from `lawyers_top.json`); neon / goo looks in `hl_kit`
  - **stud groups** (`K.STUD_GROUP`): the drifting `Clouds_Islets` now gets its own stud instancers parented to it.
    Before, its studs sat in the island-wide instancers and stayed put while the clouds drifted (all four .blends;
    nobody saw it because the reviews are static renders). Brainrot has the fix; the hub / Bay / Pet Park .blends
    get it when rebuilt (open item)
- **Fixed in review:**
  - a "SKIBIDI SUITS" sign renamed SIGMA SUITS (fictional names only)
  - the arena camera sat behind the GAVEL PIT marquee
  - smooth eye / gelato / cone / spire shapes made studded voxel; studs added to the leaning towers' ledges
  - the west goo pond sat inside Glitch Garden on an egg spot (the falls are built after the spots): both falls
    moved to angles clear of the fields (225° / 346°)
  - floating cubes kept off towers (they bob)
  - the grove canopies got their own looks so wind sways their studs with them
  - a planned window flicker (~3.7 Hz) slowed to a breath: young players, nothing flashes over 3 Hz

## 2026-10-19 — crnuch, local session: world redesign Stage 5, island 2 — Pet Park (Blender)
- **crnuch's calls:**
  - Briefcase Bay approved; its north parks stay the danger fields near the boss
  - no ambience stills **or** MP4 clips from now on: static renders + the animated .blend only
- **Shared kit** `kit/hl_world.py`: the themeable pieces every island shares (marquee / board / wood sign, arrival
  pad, RETURN HOME portal with an island-themed ring + keystone and the same green home field everywhere, open boss
  floor, themed voxel eggs + spot rings, winding Catmull-Rom paths).
- **Pet Park** (`environment-redesign/pet_park/`; doc `PET_PARK.md`):
  - route arrival → bone gate → winding path → pond with a 23-stud giant corgi + bridge → Dog Meadow / Cat Garden /
    Bunny Hills egg meadows → BARK COURT (Barrister Bulldog at 3.5×) → paw RETURN HOME
  - PAW CLINIC / FLUFF & PUFF / THE BARKERY; 24 egg spots; the Pet egg design (sky blue, paw prints)
  - 416k tris + 236k studs; 7 renders
  - ambience in the .blend: sway, petals + leaves, butterflies with clearances checked per prop, water, glows, boss
    idle
  - audio picks: CC0, checked
- Fixed in review: the corgi too small for a headline landmark (now 1.7×); a blossom canopy filling the pond view
  (an open lawn there now).

## 2026-10-18 — crnuch, local session: world redesign Stage 5, island 1 — Briefcase Bay (Blender)
- crnuch skipped the hub clip re-render ("just begin with the next island"). The hub fixes (arch straddling the belt,
  IN/OUT tunnel hoods, butterfly clearances) are in the scripts and the .blend; the committed hub belt clip predates
  them.
- **Shared kit grew:**
  - `kit/hl_island.py`: oval islands, strata cliffs, waterfalls, coverage, groves, hills, clouds, labels, and
    `boss()`, which rebuilds a zone boss from `tools/zones/bosses.json` for scale
  - `kit/hl_ambience.py`: wind, water, glows / blinks, pivots, idles, butterflies, particles, track cameras, clips
- **Briefcase Bay** (`environment-redesign/briefcase_bay/`; doc `BRIEFCASE_BAY.md`):
  - route arrival → gate → boulevard / cross street → 4 office-park egg fields → Partners' Plaza (The Senior
    Partner at 3.5×) → RETURN HOME portal
  - 12 buildings (fictional firms), the Bay (harbour + ferry + waterfall), 24 egg spots (4 bonus in the arena)
  - 409k tris + 224k studs; renders (aerial, layout, 3 ground, arena aerial, cliff) + 4 ambience clips (steam,
    papers, blinking marquees, boss idle)
  - audio picks: Freesound CC0, checked
- Bugs found in review and fixed: egg spots landing on paths (now sampled clear), a pond under a tower, the cross
  street into the harbour, the harbour with no visible water (a stone disc above it), lamp posts that would have
  swayed with the trees, street lamps that would have blinked with the marquees.
- For crnuch: the north parks are inside the boss's 60-stud trigger when it's on the arena's south rim. Accept it, or
  keep the boss ≥ 60 away (BRIEFCASE_BAY.md).

## 2026-10-18 — crnuch, local session: world redesign Stage 4 (central hub ambience, Blender + audio research)
- **`environment-redesign/central_hub/hub_ambience.py`:** opens the built hub, adds the ambience, saves the animated
  `central_hub.blend`, renders previews. The effects:
  - wind sway on canopies + their studs (Geometry Nodes)
  - flowing waterfalls and rippling water (animated shaders)
  - breathing glows (drivers), the spinning portal swirl and the belt cases (separate FX objects from hub_build)
  - 22 butterflies, floating pollen (baked particles), drifting clouds
  - 5 MP4 clips in `renders/ambience/`
- Render cost: EEVEE here is ~0.6 s per sample per frame with 681k studs (not the effects: profiled), so the
  previews are 8 samples at 960×540.
- **`AUDIO.md`:** Tier 1 = Roblox Creator Store partner audio (the `Shared.Sfx` house rule: licensed partner
  audio, never random uploads; fountain / gulls / waves already exist). Tier 2 = external picks with verified
  licences (Freesound CC0 / CC-BY, Pixabay, Kenney CC0). Nothing downloaded (needs crnuch's OK per file), nothing
  listened to (I can't). Relaxing the house rule is crnuch's call.
- **`AMBIENCE.md`:** what moves, how Blender does it vs how Roblox would, Blender-only effects, the hub ambience
  spec, and the **future WorldAmbience system** design (Config data, world detection, client controller with tags,
  transitions under TravelFx, client-side Lighting, streaming). Not implemented.

## 2026-10-18 — crnuch, local session: world redesign Stage 3 (central hub detailed modeling, Blender)
- crnuch approved the hub layout with 5 decisions (in `environment-redesign/central_hub/blockout/LAYOUT.md`):
  - firms face the centre
  - the hub Egg Incubator is a landmark only
  - License and Upgrades are split
  - each egg island gets a return portal past its boss
  - the Arcade Pier stays off the south edge
- **Shared kit** `environment-redesign/kit/hl_kit.py` (every island uses it):
  - chamfered bricks
  - Roblox-shaped raised studs as Geometry Nodes instances (one stud mesh, a point cloud per colour)
  - stepped studded roofs, upright rings / discs, voxel domes, windows / doors / columns / stairs / railings
  - 4 tree types, street furniture, attraction + wayfinding signs
  - EEVEE lighting with bloom and the Standard view transform (AgX washed out the toy colours)
- **Hub** (`central_hub/hub_parts.py` + `hub_build.py` → `central_hub.blend`, 13 MB, script = source):
  - layered voxel cliffs, 4 waterfalls, hills, groves
  - roads, the plaza with the statue fountain
  - License Building, Travel Portal, Egg Incubator, Shop, Upgrades, Mutation Lab, Big Case terrace, 4 leaderboards
  - 8 lots with example firms (DYNAMIC), the Arcade Pier, clouds / islets
  - 681k studs, 863k other tris
  - 7 renders + per-building showcases; reviewed by eye and fixed (washed colours, blown portal field, buried
    waterfalls, flat cliffs, random tree scatter → groves, bare services ring)
  - Write-up, asset list, Roblox notes and known weaknesses: `central_hub/STAGE3.md`
- Nothing in Studio or gameplay changed.

## 2026-10-18 — crnuch, local session: world redesign Stage 1 (audit) + Stage 2 (central hub blockout)
- crnuch's brief: a floating-island universe (hub + six egg islands), **Blender only** until approved; no Studio,
  gameplay or map changes (user's call). The studded-brick rule (docs/ART_STYLE_STUDS.md) was meant to come with
  this brief and applies to it. The raised-stud test patch from earlier today stays live as it was approved.
- **Audit** (`environment-redesign/01_AUDIT.md`), verified in code + the live place (read-only queries, one
  measuring playtest):
  - 8 plots (56 × 56)
  - max firm 53 wide × ~141 deep from the street edge, Supreme Tower spire ~161 up
  - players spawn at their firm
  - eggs hatch only in firms; travel blocked while carrying; bosses knock carried eggs loose
  - Upgrade prompts must sit under `Workspace.Zones` (`ZoneService.hookPrompts`)
- **Hub blockout** (`environment-redesign/central_hub/blockout/`): `hub_blockout.py` builds the .blend (0.5 MB),
  `hub_layout.json` and 3 JPEG renders (aerial, plaza ground view, labelled top-down). Layout from crnuch's
  ChatGPT reference image, with the real 8 plots (56 × 145 lots at r 148-293, facing the centre), services on an
  r 102 ring, the License Building north, the Arcade Pier bridge south. LAYOUT.md has every position (Roblox
  coords) and 5 decisions for crnuch (firm orientation, hub Egg Incubator, License vs Upgrades split, the return
  trip from separate islands, the Arcade Pier).
- Open: Git LFS isn't installed (fine while files are small); the reference image isn't in the repo yet.

## 2026-10-18 — crnuch, local session: raised studs, test patch (Plaza + one plot)
- **Stud shape = Roblox's own** (crnuch's call: "look like the roblox studs", not round LEGO ones): a low rounded
  square with slanted sides, 1-stud pitch, real geometry. Blender: `tools/blender/stud_tiles.py` ->
  `tools/zones/stud_tiles.json` (+ preview `art/studs/`). crnuch OK'd it from a Studio side-by-side.
- **Uploaded from crnuch's Studio** (CreateAssetAsync): 20 tile meshes -> `ReplicatedStorage.Studs.Tiles`
  (`tools/zones/BuildStudTiles.lua`, kit kept in ServerStorage: StudTileData / StudTileUpload / StudTileAssets).
- **New client script `StarterPlayerScripts.Studs`** (src/Studs.client.lua) + **`Config.Studs`** (merged into live
  Config: it was unchanged since the last snapshot) + a config check. Parts tagged `StudTop` get studs on open cells
  near the camera. Tagged: Plaza (312 bricks) + Plot1 Base / Paths.
- Bugs found in playtest and fixed: rays passed through the firm (CanQuery off) -> switched to a part-bounds index;
  Terrain's box covered the whole map -> skipped.
- Playtested on PC: studs stop cleanly at the firm, 0 overlaps over 2,418 plot studs; fps same with the layer on
  and off (Studio throttled, weak signal). Phone / low tiles not eye-checked. Snapshot re-exported (113 scripts);
  `run_checks.py` ALL PASSED. Claim released.

## 2026-10-18 — crnuch, local session: studded-brick art rule recorded
- crnuch set a **non-negotiable art rule**: the whole map is a studded toy-brick world with real raised 3D studs (not
  textures), one stud scale, Blender-made reusable stud assets, LOD for distance/phones, studs off the collision.
  Written up in **docs/ART_STYLE_STUDS.md** (directive + how it maps onto the game + proposed rollout); CLAUDE.md's
  "Builds" rule now points there (`TopSurface = Studs` is only the far fallback now).
- Nothing built, nothing changed in Studio. Next: pick the stud scale, then a test patch.

## 2026-10-18 — crnuch, local session: UI overhaul, part 2 (Skin v2 + the HUD rebuilt)
- **Skin v2** (`ReplicatedStorage.Shared.Skin`, every old function unchanged): `Skin.Motion` (one table for hover /
  press / pop / toast / banner / blur numbers), `Skin.Lime`, `Skin.hudTile` (88 px square: gradient + studs, white rim,
  ink outline + lip, two twinkling sparkles, the PNG icon over the top edge, the label over the bottom edge, red badge
  + red "!" top-right, hover x1.08 / press x0.9, wiggle while a badge shows), `Skin.toast` (icon + white Fredoka +
  ink stroke over a soft shadow band, ALL-CAPS words in lime via `Skin.highlight`, slide-down + fade; with `Hold` it
  leaves by itself), `Skin.counter` (icon + big stroked number, count-up, pop on a gain), `Skin.banner` (zone
  arrival: a wood plank on two ropes, red NOW ENTERING ribbon with tails, swings in as a damped pendulum, one at a
  time), `Skin.prompt` + `Skin.installPrompts()` (custom ProximityPrompt: white key cap E / X / TAP, a 16-segment
  lime hold ring, object + action on a charcoal plate; touch / click holds it), `Skin.sparkle`, `Skin.overlay`,
  `Skin.icon` (HudMenu.Icons key -> id). **The world blurs behind every `Skin.window`** (`Skin.blurFor`: one local
  `Lighting.SkinWindowBlur`, watches each window's Enabled). `Skin.ribbon` defaults to **red** (Shop still passes Gold).
- **HUD rebuilt on it** (live in Studio): `HudMenu.button` draws `Skin.hudTile`s in 2 columns (same API: setBadge /
  setAlert / setNote / HudMenu.wait; colours by entry in `TILE_COLORS`: Daily pink, Lawyers purple, Shop green,
  Rebirth gold, Travel sky; the DAILY timer shows as the tile's label in lime). `Hud`: coins are a `Skin.counter`
  bottom-left with no panel, case results float up above it (2 at a time on screens < 520 px tall), the hint is a
  `Skin.toast` top-centre with an icon by topic (gavel / eggs / upgrades / lawyers / goals); Hud also calls
  `Skin.installPrompts()`. `Goals`: charcoal card, striped purple header + Goals PNG, white text, real bars (lime,
  gold + DONE! when finished, "n/m" on the bar, a pop on progress). `Zones`: the egg bag is a Skin plate with the
  Eggs PNG, one chip per slot (Empty / Filled in the egg's colour / Golden with a sparkle), the count (orange when
  full), a chip pops when an egg lands; the zone name is `Skin.banner`; Zones' notes are `Skin.toast`.
- **Playtested at 1429x776** (crnuch's account): all 5 tiles clicked with the mouse and open their screens (Shop,
  LAWYERS, Rebirth, Travel, Daily); badges / "!" visible; blur 14 with Shop / Travel open, 0 when closed; coin
  count-up + WIN floater; Goals bars (1/2 = half); bag chips with a Briefcase, golden Food and Pet egg (set locally);
  the real Briefcase Bay arrival banner (teleported in) settles at 126-238 px, under the hint toast (60-108).
  The prompt was checked as a 2D preview (E + TAP, ring lit); a first ring (clipped half gradients) didn't draw and
  was replaced by segments. **Not checked in the world**: no prompt is `Style = Custom` yet (part 3) - and
  BillboardGuis with AlwaysOnTop didn't show in the MCP's screen_capture at all (name tags, AlwaysOnTop = false, do).
- **Phone size: not playtested.** Studio's Device emulator can't be driven from the MCP (no
  StudioDeviceEmulatorService access) and the window can't be resized from here. Checked by layout maths at 844x390
  instead: menu 0.56x (y 95-303), coins 0.62x (y 334-377), bag 0.51x (x 278-566), Goals 0.58x and folded, toast
  fits at ~0.9x, banner 0.75x - no overlaps; the case-result floaters were capped (above). The dynamic thumbstick
  shares the bottom-left with the coins. Needs crnuch's eye-check in the emulator (open item).
- Found: the old `UISkin` auto-skin only honours `NoSkin` on objects *below* the ScreenGui (not on the ScreenGui), so
  it repainted the banner plank charcoal - every v2 root frame sets `NoSkin` now. The MCP's `execute_luau` VM can't
  make visible BillboardGuis (debug billboards it parented never drew), so test world UI through the game's own scripts.
- Pushed with `ScriptEditorService:UpdateSourceAsync` from a localhost file server (python http.server, port 8769),
  after checking each live script still matched the snapshot. src/Skin.lua, HudMenu.lua, Hud.client.lua,
  Goals.client.lua, Zones.client.lua == live; snapshot re-exported on port 8768 (8767 is still taken by the other
  worktree's receiver), only these 5 changed; `run_checks.py` ALL PASSED.
- **Left for part 3** (docs/UI_OVERHAUL.md §3): world prompts (set `Style = Custom` on the 15 prompts + eye-check
  in the world), egg odds boards, License gate / upgrade prompts, Zones' GOLDEN EGG! + upgrade banners, Daily
  Rewards + LAWYERS windows (not `Skin.window`, so no blur yet), Rebirth (Supreme) and FirmStageUp (R), Big Case,
  minigames (Gavel Bonk / Lucky Briefcase), Travel map + trip captions, hatch reveal card, Shop red ribbons, Skills,
  Merger, Floors, Manager, Courtroom, Arcade, Boss UI, desk progress bars, world signs (`Skin.sign`), then retire
  UIKit / UISkin.
- CLAUDE.md still says the HUD tiles are "one column" (Art direction → UI); it's 2 columns now - not edited here
  (this session was limited to the files above), fix it with the next CLAUDE.md change.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-18 — crnuch, local session: UI overhaul, part 1 (reference analysis, audit, icons live, Figma design system)
- **Brief** (crnuch): every interface restyled to the reference recordings (Desktop "Screen Recording 2026-10-18 at
  7.07.09 / 7.07.21") with the glossy PNG icons - look only, no features from the references (no event pass, no
  gifting, no settings / codes / achievements / friends menus). Claim stays up under **In progress**.
- **docs/UI_OVERHAUL.md**: the reference measured element by element, the icon -> use map, the full audit of every
  UI surface (script, trigger, styling layer, R / S action), the plan. Found: StarterGui is empty (all UI is built by
  scripts); 15 world ProximityPrompts on Roblox's default grey style; UISkin/UIKit still auto-restyle the older
  screens (Goals body text, FirmStageUp, Minigames, Zones).
- **Icons live in Studio:** the 12 used PNGs uploaded as 512 px copies from crnuch's Studio (place owner); ids in
  `HudMenu.Icons` (re-pointed Gift / Goals / Coin / Travel / Cart / Shop; new Lawyers, Rebirth, Money, Eggs, Merge,
  Upgrades, VIP, Index). Lawyers + Supreme (Rebirth) tiles and headers switched to the new keys. Playtested: all five
  HUD tiles, the coin counter and the Goals header show the new art (headers of closed panels not opened).
  src/HudMenu.lua, Lawyers.client.lua, Supreme.client.lua == live; snapshot re-exported (111 scripts);
  `run_checks.py` ALL PASSED.
- **Figma** https://www.figma.com/design/PtgoaIbriizMlKEDFVxc8Q - tokens, text + effect styles, icon components,
  15 components and the hub HUD screen (details + known defects in docs/UI_OVERHAUL.md §4). **The Figma MCP is
  capped at 20 calls / month on crnuch's Starter plan View seat - used up today**; Studio work doesn't need it.
- **Heads-up:** a snapshot receiver from another session was still listening on port 8767 (worktree
  `.claude/worktrees/dazzling-kalam-6f4931`, started 18:06) and caught a first export, so that worktree's `studio/`
  now holds today's live scripts. Its process was left running; this session exported on `--port 8768`.
- Left (in order, docs/UI_OVERHAUL.md §3-4): Skin v2 pieces (`hudTile`, `toast`, `prompt`, `banner`, `counter`,
  blur), then the R rows (HUD column as square tiles, coin counter, toast, Goals, egg bag, prompts, zone arrival,
  Big Case, minigames, Rebirth, FirmStageUp), then the S rows; each playtested at desktop + phone size.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-18 — crnuch, local session: glossy HUD icon art
- Added the 16-icon glossy HUD revision under `art/icons/hud_navigation_glossy/`, including transparent PNGs,
  an overview, a browser review page, and a manifest. The latest art incorporates the requested yellow Daily Gift,
  refined Lawyers icon, and quieter effects on Rebirth, Travel, Settings, and Merge.
- Assets are in Git for review; no Roblox Studio import or HUD wiring was done.
- Signed: Codex for crnuch, local session.

## 2026-10-16 — crnuch, local session: the music stings turned down (win, big, fanfare)
- crnuch: two sounds from the first SFX batch were "incredibly loud" next to the rest - the fanfare (Mythic / Supreme
  hatch) and "big" (the "dunnnn dun dunnn": Rare+ hatches, Epic / Legendary client wins, office tier-ups, rebirth),
  then "win" too. Measured in a playtest (PlaybackLoudness at Volume 1): these APM stings stay loud for their whole
  length (average 150-190) while UI sounds are short blips (average < 60). `Shared.Sfx` volumes, picked by ear with
  crnuch over 3 rounds of an on-screen numbered comparison: win 0.5 -> 0.16, big 0.55 -> 0.18, fanfare 0.5 -> 0.18
  (big stays a touch above win). Live in Studio, src/Sfx.lua == live, snapshot re-exported, `run_checks.py` passed.
- Noticed, not changed: the wave loops (`WorldLife`) play with no SoundGroup, so the SFX group's volume doesn't reach
  them (the fountain's does).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-18 — crnuch, local session: bug 6 follow-up (z-fighting: studded faces, client-side scan, minigame props)
- **The detector had two blind spots** (`ZFight`, now `ReplicatedStorage.Shared.ZFight`; `Server.ZFight` is a one-line
  wrapper so FirmBuilder, DeskService and every `tools/zones/Build*.lua` keep their require):
  1. It ignored `MaterialVariant`: a `BrickStuds` face over a plain Plastic face of the same colour still flickers, and
     so do two overlapping BrickStuds faces even with everything equal - each part tiles the stud texture from its own
     position, so the grids don't line up (tested with two parts in Studio: offset grids visibly break up, aligned
     ones don't). `differ` now counts a variant mismatch, and any two textured faces, as a clash.
  2. It compared each face's axis-aligned box in the plane, so a part turned within the plane (an arm Puppet tilts
     30 degrees) gave false hits. The overlap is now exact (separating axes on the two face rectangles). Client scan
     of a running firm: 109 -> ~20 hits.
- **Fixed in place (Edit mode):** storage per model (SkinModels, JudgeModels, Templates.Clients / Firms / ..., the
  decor library, WorldLife, skipping Retired* / *Backup* / StagePreviews* / LuxuryFirm): 835 faces; Workspace outside
  the plots 2758 + 202 + 97 + 14 faces (zone WallDecor, pier rails, far islands, fountain rim, shop stall...) -> 0;
  the 8 plot LotSigns (16). A few thin plates kept chasing each other at 0.04 steps (layers an older pass left exactly
  0.04 apart): one pass at 0.025 settled them. Left: 4 faces on the cast (a 0.045 coat-tail plate on PiratePatches...),
  Workspace 0. **Gotcha:** don't loop `ZFight.fix` more than ~3 passes - oscillating faces walk; and ChangeHistory
  recordings made from the MCP show up as "Assistant N" waypoints, so an Undo from a later call may hit the wrong one.
- **Builders keep it fixed:** the existing ZFight passes pick the new rules up; added one to `BuildWorldLife.lua`.
  `MinigameClient.Scene:asset` (the cinematic minigame props, built client-side from AssetData on every play) runs
  2 passes on each prop (~4 ms for the whole kit): it had 40 clashing faces (ArcadeStage 20) -> 0, checked by building
  ArcadeStage through the real Scene in a playtest.
- **Playtest (QualityLevel 21), crnuch's firm:** client scan ~20 left - SeniorPartner boss head (bosses are out of
  scope), the carried briefcase, the Storefront front floor / area pad / expansion lock (hidden undersides, known from
  the 10-16 entry) and StarJudge's gavel caps (0.012 off the handle at the desk's 1.2x scale - at the threshold, not
  coplanar). Close-ups of a desk lawyer (Starla) + seated client: no speckled / striped faces.
- Snapshot re-exported (111 scripts: + Shared.ZFight; Server.ZFight, MinigameClient.Scene changed). It also picked up
  the SFX pass's live edits that weren't in the snapshot yet (Shared.Sfx + Skin, TravelFx, ArcadeClient.Kit, BigCase,
  Bosses, Merger, Sounds, WorldLife, Zones clients) - not mine, just now recorded.
- `run_checks.py` ALL PASSED.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: design pass (plaza, height, island edge, lane rhythm, life) + pier connected
- **Pier connected:** the Big Case terrace's hedge row closed the pier off. 5 hedge blocks in the middle are archived to
  `ServerStorage.ArchivedVisuals.CaseTerraceHedgeGap` and `arcade_pier.py` adds a landing + two steps from the
  terrace rim (top 0.9) down to the deck, with lamp posts either side.
- **Plaza re-tiled** (colour only, one undo step): the orange checker is now only the walkways - a ring round the fountain
  (radius 15-25) and spokes N / S / E / W + diagonals; calm sand inside, two-tone lawn outside (radius > 40).
- **Height + edges** (`hub_landmarks.py`): the Egg Fountain stands on a two-step gold-edged dais; 8 `PlazaBench`es face it
  at radius 28; 32 `PlazaPlanter`s (hedge + flowers) sit on the plaza's rim tiles, gaps at every walkway.
  `BuildHubLandmarks.lua` learned "copies" (a list, or "rim") and other JSON via `_G.LANDMARKS_JSON` + "parent".
- **Island edge** (`tools/blender/island_edge.py` -> `island_edge.json`, built with BuildHubLandmarks into
  `Workspace.IslandEdge`): a two-step beach all round (gaps for the lane and the pier), 19 rock clusters, 2 docks with
  rowboats beside the pier, 3 sailboats, 3 far islands on the horizon.
- **Lane rhythm** (`tools/blender/lane_pillar.py` -> `tools/zones/BuildLanePillars.lua`): 95 banded pillars with a lamp and
  a hanging banner in the zone's colour against both walls every 45 studs (clear of arrivals and gates, 3 skipped for
  decor) in `Workspace.ZoneLandmarks.Pillars` - re-run after a BuildLane re-run.
- **Life** - new `StarterPlayerScripts.WorldLife` (src/WorldLife.client.lua; client-only, only near the hub): brick water
  droplets arcing from the fountain's fish spouts, flags / pennants / banners swaying, two lighthouse beams sweeping,
  sailboats bobbing, 6 seagulls (`ReplicatedStorage.WorldLife.Bird`, from `tools/blender/world_life.py` via
  `tools/zones/BuildWorldLife.lua`) circling, 4 clients (ReplicatedStorage.ClientModels) strolling the walkway ring.
  No ambient sea sound: the game has no licensed sound id for it yet (CLAUDE.md: unapproved ids don't play).
- **Plots** (`Server.PlotService`, heads-up mr.robe): players get the plots nearest the plaza first (2, 3, 6, 7, then
  1, 4, 5, 8) so a quiet server's firms sit by the hub. **Sign styles:** wayfinding = brown wood board, white text
  (the gate's hanging sign, OPEN LOT, the hub's signposts); attractions = black panel, gold text, bulbs.
- Playtest: no errors; crnuch landed on Plot2 (its LotSign hidden); WorldLife running (6 birds, 24 droplets, 2 beams, 4
  walkers). Save restored afterwards. `run_checks.py` ALL PASSED; snapshot 109 scripts (+ WorldLife; PlotService).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: art pass stages 4 + 5 (lot signs, zone statues) - the plan is done
- **Stage 4 - LOT SIGN** (`tools/blender/lot_sign.py` -> `tools/zones/lot_sign.json` -> `tools/zones/BuildLotSigns.lua`):
  `Plots.PlotN.LotSign` at every plot's entrance (plot-local (0, 0.48, -20)): two banded red / white posts with gold
  caps, a hanging green "OPEN LOT" sign + "A new firm opens here!", traffic cones, a brick pile and a crate. 31 blocks.
  **`Server.PlotService` (heads-up mr.robe: small change):** `setLotSign` tucks a plot's LotSign into
  `ServerStorage.HiddenLotSigns` when `assign` claims the plot and puts it back on `release`. Playtest: Plot1 (crnuch)
  hides its sign, Plots 2-8 show theirs, no errors.
- **Stage 5 - zone statues** (`tools/blender/zone_landmarks.py` -> `tools/zones/zone_landmarks.json` ->
  `tools/zones/BuildZoneLandmarks.lua`): a pair of brick statues (x1.5, gold plinths) on top of every License gate,
  showing the zone it leads into, facing the players walking down the lane: puppies (Pet Park), googly brains
  (Brainrot Boulevard), burgers (Food Court), leaping fish (Ocean Shore), rockets (Space Base). In
  `Workspace.ZoneLandmarks` (outside Workspace.Zones - **re-run BuildZoneLandmarks after a BuildLane re-run if the gates
  move**). Render `art/map/zone_landmarks.png`.
- The stage 1 layout plan is fully built (docs/ART_REMODEL_BRIEF.md status). Claim released. Save restored after
  every playtest (`Backup_Player_2234491534_1792186860`).
- `run_checks.py` ALL PASSED; snapshot re-exported (108 scripts: PlotService changed).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: art pass stage 3 (Travel Portal, Shop, Mutation Machine)
- **Travel Portal** (`tools/blender/travel_portal.py`, rebuilt with `BuildTravelPortal.lua`): animated core kept as it
  was (SwirlDisc / SwirlArms / FloatRing1-3 / Beam / Gem1-6 / Trigger); the pylons are banded navy / white with gold
  caps, finials and pennants in the zone colours, and the TRAVEL sign is bigger, higher (clears the gem crown) and
  framed in cyan / violet / gold bulbs like the BOARDWALK sign. 236 blocks.
- **Shop + Mutation Machine** now in `tools/blender/hub_landmarks.py` -> `BuildHubLandmarks.lua` (which learned
  "prompt" / "lbl" / "light" fields and carries a model's old "Title" billboard over). Same spots, facing the plaza's
  middle; the old ones are in `ServerStorage.Old_HubLandmarks`.
  - `Hub.ShopStall`: a brick storefront - cream walls, banded red / white corner posts, red / white awning over a red
    counter with a till and coins, shelves of what it sells (coin stacks, a golden egg, cash, a winged red boot, a
    mini firm, a briefcase, eggs), purple roof with a lit SHOP sign and a giant gold $ coin. `ShopPrompt` ("Open Shop")
    on an invisible PromptZone in front of the counter; the "SHOP / Passes & Boosts" billboard above the coin. 114 blocks.
  - `Hub.MergeMachine`: a chunkier purple machine on a gold octagon plinth with a glowing ring - the "?/!" window
    (`WindowFrame`, `Screen` with the `Mark` label + light), three gold chutes into a dome on top (three lawyers in),
    an antenna, pink / green bubbling tanks, a console with buttons, screen and a big lever. `MergePrompt` on `Body`,
    the `Title` / `Count` billboard on `Dome`. 56 blocks.
- **Playtested:** the Shop prompt opens the shop, walking onto the portal pad opens the travel map, the Mutation
  Machine opens and its in-world scene plays at the new window ("!" lit). No game errors. Save restored again after.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: art pass stage 1 built (lighting, Arcade Boardwalk, Egg Fountain)
- **Plan approved by crnuch** (docs/ART_REMODEL_BRIEF.md "Stage 1"). Built in order:
- **Lighting:** the hub's grade was flattening the orange plaza into one hot wall. `Lighting.ExposureCompensation`
  -0.10 -> -0.25, `ColorCorrection.Saturation` 0.20 -> 0.05, `Contrast` 0.08 -> 0.12 (place properties, one undo step).
- **Arcade Pier** (`tools/blender/arcade_pier.py` -> `tools/zones/arcade_pier.json` -> `BuildArcadePier.lua`, rebuilt;
  the old one is `ServerStorage.Old_ArcadePier`): booths spread down the deck (Lie Detector z 189 east, Briefcase Stack
  z 215 west, Filing Frenzy z 241 east; three facing slots left free for later games), lamps staggered with the string
  lights zig-zagging over the walkway, and a round end platform with a red / white brick LIGHTHOUSE (z ~287, ~36 tall,
  lit lamp room, benches, life rings) - the district's landmark, framed by the pier arch from the plaza. 464 blocks.
  Playtested: ArcadeServer re-hooks the rebuilt booths, the moved Briefcase Stack prompt starts its round.
- **New `tools/blender/hub_landmarks.py` -> `tools/zones/hub_landmarks.json` -> `tools/zones/BuildHubLandmarks.lua`**
  (re-runnable; older builds go to `ServerStorage.Old_HubLandmarks`): `Workspace.Hub.BoardwalkGate` (z 86, where the
  plaza meets the Big Case terrace: banded red / white legs, gold caps, flags, lit "BOARDWALK" sign both sides, hanging
  "BIG CASES • ARCADE PIER" / "BACK TO THE PLAZA", planters; replaces `Hub.Gates.BigCaseGate`, archived to
  `ServerStorage.Old_HubGates`) and `Workspace.Hub.EggFountain` (plaza centre: octagon basin with water, gold rim and
  fish spouts, tiered pedestal, a giant GOLDEN brick egg with white spots, a golden gavel facing the lane). 84 + 69
  blocks, Blender renders `art/map/hub_landmarks.png`. Cream egg read grey in the hub light -> gold.
- **Moved** the `Hub.Trees` Oak standing on the boardwalk line (0, 148) to (-46, 150): the plaza -> gate -> belt -> pier
  arch -> lighthouse axis is clear now.
- Playtest: no game errors. crnuch's save was restored from `Backup_Player_2234491534_1792186860` again afterwards.
- **Next (stage 3):** Travel Portal, Shop, Mutation Machine one at a time; then plots (4) and lane thresholds (5).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: Codex's minigames + mutation scene finished, playtested
- **Took over Codex's work (user's call: nobody else is on it).** Live Studio was ahead of GitHub: Codex had synced a v2
  (cinematic) version from its own checkout (`~/Documents/Codex/2026-10-16/id-l/HatchLawyers`, branch
  `codex/world-minigames`, uncommitted). Brought onto main: the live scripts (`studio/`), the v2 Blender kit
  (`tools/blender/minigame_kit.py` -> `tools/zones/minigame_kit.json` -> `tools/zones/BuildMinigameKit.lua`, which writes
  `ReplicatedStorage.MinigameClient.AssetData`; `art/minigames/MinigameKit.blend`), `docs/ART_REMODEL_BRIEF.md` and the
  mutation scene (`src/Merger.client.lua`). Its `src/Config.lua` edit only mirrored live (no live Config change).
- **How the five minigames work now:** each round is a client-only stage at y = 4000 (`MinigameClient.Scene`: Blender
  props, scripted camera, HUD hidden, movement frozen, tap / click / SPACE / 1-4). Hub: `MinigameClient.GavelBonk` /
  `LuckyBriefcase` (from `Minigames.client`); pier: `ArcadeClient.LieDetector` / `BriefcaseStack` / `FilingFrenzy`
  (from `Arcade.client`). Servers (`MinigameService`, `ArcadeServer`) unchanged: timing, scoring, rewards.
- **Fixed:** (1) taps missed everything by 58 px: `Scene:hit` used `ScreenPointToRay` on `input.Position`, which is in
  viewport space -> `ViewportPointToRay` (Gavel Bonk robbers, Lucky Briefcase cases, booth buttons / bins). (2) a lost
  server result held the player in the stage for 240 s: `Scene:deadline` ends the round a few seconds after it should
  have ended ("Round over!"). (3) Mutation scene: Codex placed the lawyer and camera along world axes, but the
  Mutation Machine faces diagonally - the shot was side-on with the player in the way and the HUD up. Now staged
  from the machine's front (the lawyer works it from beside the window, camera in front), the HUD and your own
  character hidden for the moment, the floor found by raycast, the lawyer level (it was tilted toward the window),
  runs off facing away on a fizzle, and any seated lawyer is the actor (Desk1 could be empty -> no scene).
- **Playtested (crnuch's save, backed up first as `Backup_Player_2234491534_1792186860` and RESTORED after):** all five
  played to a server result + CONTINUE, camera / movement / HUD / lighting restored after each; mutation x3 via the
  real UI (Intern Suit), the in-world scene plays, the panel shows the result. No game errors.
- **Still for crnuch to judge (taste):** the stages share one plain cream "ArcadeStage" room; a robber ducking
  briefly shows through the gap between Gavel Bonk's bench rows; the mutation shot still sees the lawyer mostly from
  the side. Phone-size check not done.
- `run_checks.py` ALL PASSED; snapshot re-exported (108 scripts).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: bug report 6 fixed (z-fighting everywhere) + the oak inside the Travel Portal
- **New `ServerScriptService.Server.ZFight`** (`scan` / `fix(roots, { only, noYield })`): finds block faces that point
  the same way, lie within 0.012 of the same plane and overlap (> 0.02 both ways) with a different colour / material /
  transparency / surface - the flicker crnuch saw (light-brown on dark-brown etc.). Each plane's overlapping faces get
  "levels": the smallest face (the detail) stays put, each face clashing with one already placed moves back 0.04 a
  level (that side of the part SHRINKS, never thinner than 0.04; too thin -> it grows out instead). Shrinking can't
  make new overlaps - growing sideways did (first try: 0.04 slivers along every neighbour, never converged; undone).
- **Fixed in place (Edit mode, one ChangeHistory step each):** the whole Workspace (3395 face pairs found at the start:
  Shrubbery, every zone's WallDecor, Hub Plaza / CaseTerrace on the Ground, IslandDecor, ArcadePier booths, ...) and
  the templates, model by model: Templates.FirmKitParts / Firms / Clients / FloorRooms / Firm, ZoneDecorLibrary,
  HiddenDecor, ReplicatedStorage.SkinModels / JudgeModels / Briefcases / Bosses / CourtroomSet. ~6400 faces moved
  in 4 passes + a leftovers pass; 1 left (a character face plate). Most moves are 0.04-0.08; clusters of tiny
  decorations (flowers, sprinkles, moss) up to 0.2.
- **Runtime:** `FirmBuilder.build` runs ZFight (up to 3 passes, no yield, ~28 ms with a stage-6 10-segment build)
  on the new firm against the plot's decor - only the firm's parts move, and not against the old firm (PlotService
  builds the new one first). `DeskService` runs it on the EXPAND FIRM sign. Playtest: map outside the plots 0 left,
  crnuch's firm 8 (desks vs the seated clients' legs, a rug, the CafeTerrace area pad - moving / later-added parts),
  no game errors.
- **Builders keep it fixed:** BuildLane, BuildDecorLibrary, BuildTravelPortal, BuildArcadePier, BuildFloorRooms,
  BuildBriefcases, BuildBosses, BuildLawyersTop and tools/brick/Run.lua now end with a ZFight pass on what they built
  (BuildLane's queued re-run - open item - stays fixed).
- **Travel Portal:** the Hub.Trees Oak standing in it is archived to `ServerStorage.ArchivedVisuals.HubTrees` (no free
  spot near the portal for a 16x19 oak); the oak at x 76 grazing its edge moved 2 studs east.
- Not eye-checked (no rendering viewport this session) - crnuch: walk the hub, a zone, your firm.
- `run_checks.py` ALL PASSED; snapshot re-exported (104 scripts: + ZFight; FirmBuilder, DeskService changed).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: bug report 1, 3, 7 fixed (shack incubators, over-bright firms, desk tiers)
- **1 - Dingy Shack incubators:** the shack (the Firm1 template) is only 24 wide (walls at x +-12), but the incubators
  stood at the default x +-15.7, outside it. New `FirmStages.INCUBATORS[stage]` (FirmBuilder uses it, else its own
  `INCUBATORS`): stage 1 = (+-7.8, 0, 14), inside at the back - 0.9 from the walls, 4.6 each side of the aisle, clear of
  the floor cracks. The roof over the right one was open (the egg would rocket 46 studs out of the shack), so FRONTS[1]
  adds a `TarpPatch` (a clone of the shack's tarp). Hatch rise (Eggs.client raycast): 5.1 left, 5.7 right; stages 2-6
  unchanged (4.3-13.3, no overlaps).
- **3 - over-bright firms:** checked all 6 stages' lights + Neon (Lighting: Brightness 2.25, Bloom threshold 1.6).
  Worst: Neon panels of 28x4 / 44x7 / 39x18 studs (stage 4 + 6 canopies, stage 5 LoungeGlow, stage 6 PenthouseGlow)
  and 6-12 overlapping 1.6-brightness ShowcaseSpots over the white showcase floors. Now: big panels use a new `glow` look
  (warmer, darker Neon, 0.3 transparent); ShowcaseSpot 1.6/9 -> 0.7/8; porch lamps 1.4/18 -> 0.9/14; door lanterns
  1.3/14 -> 0.9/12; shack lantern 1.4/16 -> 0.9/12 and the template's CeilingLight 1.4/22 -> 0.8/16; panel lights
  0.9-1.2 / 16-30 -> 0.6 / 14-20; coffee bar 1.2 -> 0.8; elevator arrows 1 -> 0.6; hall sconces 0.8/12 -> 0.6/10;
  `white` 250,250,245 -> 238,236,228; FirmFeatures' hologram beam light 2/26 -> 1/18. No firm light is above 1.0 now.
- **7 - desk tiers overlapping:** `Server.DeskLook` was written for an older desk facing the other way: its side panels
  sliced through the kit desk's pedestals and top, the trophy went through the laptop screen and the desk lamp, the
  plaque through the mug, the lamp base into the laptop. v2 recolours the kit desk's own parts (found by size: top,
  pedestals, modesty panel, front strip, handles, lamp) and adds only: a gold band around the top (T3+, every face 0.05+
  from the desk's), the kit lamp turned into a banker's lamp with a 0.6 light (T3+), the PARTNER plaque on the client
  edge and the trophy in the lawyer's far corner (T4). Checked: no tier piece overlaps a kit part, tier 1 restores
  everything.
- **Checked:** all 6 stages built from fresh clones in Edit mode (removed after), then a playtest: crnuch's firm
  (Storefront Practice, 8 desks at tier 4) builds with the new desk pieces, a stage-1 firm built on an empty plot has
  both incubators inside + the patch + the dimmer lights, no game errors. Nothing saved was touched. The viewport didn't
  render (screen captures came back blank), so **nothing was eye-checked** - crnuch, look at a shack, a Glass Office /
  Corporate HQ / Supreme Tower front and a tier-3/4 desk.
- `run_checks.py` ALL PASSED; snapshot re-exported (103 scripts: DeskLook, FirmBuilder, FirmFeatures, FirmStages
  changed; `src/` FirmStages + FirmFeatures equal to them).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: bug report 2, 4, 5 fixed (egg through the ceiling, portal moved, Rebirth)
- **#2 the hatch egg went through the ceiling** (`Eggs.client` rocket): it always rose at least 7 studs. It now stops
  `HATCH_EGG / 2 + 1` under the ceiling it raycasts (min 1.5). Even crnuch's own firm clipped: the front's Cornice is
  8.2 above the cradle, so the 3.3-stud hatch egg poked 0.45 into it; now the egg peaks at y 8.6 under 11.3.
- **#4 Travel Portal moved** (crnuch's pick: right of the lane entrance, across from the License Office, facing the
  path): pivot (52, 0.5, -56), turned 180°. One oak (`Hub.Trees.Oak`) moved east to (76, -56) to make room.
  `tools/zones/BuildTravelPortal.lua` PLACE_AT set to match. Walking onto the pad opens the Travel map (checked).
- **#5 "Supreme" → "Rebirth" on screen** (user's call): `Config.Prestige.Name` = "Rebirth" (the toast reads REBIRTH ★),
  `Supreme.client` (HUD tile, header, "REBIRTH!", "Rebirth 3 · payouts x..", "Your first rebirth ..."), `Manager.client`
  ("REBIRTH ★", "Can't rebirth yet"). Script / remote / save names (Prestige*, `Supreme.client`), the BadgeAwards id
  "Supreme" and the Supreme RARITY are unchanged. crnuch: the badge's display name lives on the Creator Dashboard.
- **Also:** the Mutation Machine's wooden signpost (`Hub.MergeMachineSpot.Sign`) still said "LAWYER MERGER / 3 same
  lawyers = 1 stronger" - now "MUTATION MACHINE / 3 same = try a mutation" (world edit, not a script).
- 3-way merge: every live script equalled its `src/` base, so the edits went in as small multi_edits. `run_checks.py`
  ALL PASSED; snapshot re-exported (103 scripts): Config, Eggs, Manager, Supreme changed, each equal to `src/`.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: mutations + selling eye-check (the rest of the playtest); Mythic stage fix
- **Save safety:** crnuch's save backed up first as `Backup_Player_2234491534_1792168772` (`PlayerData` store, 150
  lawyers, v18). Test lawyers (uids L223+) were added by temporary Server-datamodel Scripts and all removed at the end;
  the sale proceeds (3.67M) were taken back off. Checked in the DataStore afterwards: 150 lawyers, none locked, none
  L223+, offices as before (9 / 10 empty), lock released. No TEMP_ scripts anywhere (they only lived in the play
  datamodel). The Mac's display slept mid-session (Team Create dropped, Studio closed the place) - after the save.
- **Eye-checked at QualityLevel 21:** Diamond + Cosmic recolours and `Effects.mutationAura` on the Rookie (older
  Studio-built brick) and the Supreme Celestial (1.6x) at desks 9 / 10: everything but the face recoloured, tags read
  DIAMOND / COSMIC with the right Earns x; Diamond ring + crystals, Cosmic tilted orbit + stars. Hatch reveal: Diamond
  Thunderclap (Epic, Blender brick: blue, ring, lightning, "DIAMOND THUNDERCLAP / Earns x36") and Cosmic Phoenix
  (Mythic stage, purple title card). Mutation Machine: "MUTATE! (70%)" + "70% chance · Earns x15 (was x6)", FIZZLED
  (grey puff, "Your lawyers ran off... try again!", no "lose") and SHINY THUNDERCLAP! (gold burst). LAWYERS panel:
  an Epic asks "TAP AGAIN TO SELL" (3 s window) then "Sold Diamond Thunderclap for 194.40K coins!"; LOCK puts a gold
  padlock on the card, SELL turns grey "LOCKED", toast "Locked - safe from selling and mutating"; SELL ALL picker
  (starts with Common + Uncommon ticked) showed "Sells 3 lawyers for 3.48M coins (not locked, not in an office)" -
  it skipped the locked one and the office ones - and sold exactly those 3.
- **Fixed (`Shared.HatchFx`, pushed + playtested):** the Mythic stage's 8 braziers stood on whole 45° steps, so one sat
  on the stage's front axis right between the reveal camera (~20 studs out for a 1.3x Mythic) and the lawyer - every
  Mythic reveal showed a black pillar over the lawyer. Turned half a step; `/hatch mythic` now shows the lawyer
  framed by two braziers. Not a mutation bug (mr.robe's 10-13 cinematics) - heads-up mr.robe.
- **Tip:** `screen_capture` with camera_position works in a playtest, but emitters that were off-screen haven't
  simulated: point the client camera there first, wait ~3 s, then capture.
- **Checks:** `run_checks.py` ALL PASSED (250 Luau files, 39 Config checks, 32 sim tests). Snapshot re-exported
  (103 scripts): only HatchFx changed, equal to `src/HatchFx.lua`. MutationLook / Effects untouched (nothing clearly
  wrong; taste calls in Open items).
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-16 — crnuch, local session: LAWYER MUTATIONS + SELLING live in Studio (save v18)
- **Heads-up mr.robe:** PlayerData, LawyerService, CaseService, EggServer, ZoneService and FirmFeatures changed in Studio
  (the 2026-10-13 mutations work). Save stays v18: its step adds nothing (`Stars` = mutation tier, optional `Locked`).
  Phase B of the minigames (save v19) is unblocked.
- **Pushed** (3-way merged: base = `src/` before 95c1ecd, or the `studio/` snapshot for the new working copies
  SkinLook / FirmFeatures; every merge came out identical to `src/`, no conflicts but one comment block): Config,
  Formulas, SkinLook, Effects, NEW `Shared.MutationLook`, PlayerData, LawyerService, CaseService, EggServer,
  ZoneService, FirmFeatures, clients Lawyers, Merger, Eggs, LawyerTags. Written with ScriptEditorService (Mac: a
  `python3 -m http.server --bind 127.0.0.1` on `src/` + HttpService, guarded by each live script's length). The hub
  machine: sign "Mutation Machine" / "3 same = try a mutation", `MergePrompt` "Mutate" / "Mutation Machine".
- **Playtested** (crnuch's real save, backed up first as `Backup_Player_2234491534_1792168291` in the `PlayerData`
  store): loads with no game errors; the 26 old Gold lawyers show SHINY with the same Earns x (StarEarn 2.5 both before
  and after); remotes: lock / unlock, locked can't be sold or mutated ("Unlock it first"), 2 picks / duplicate uids /
  junk args / uids you don't own all refused, rate limit answers "Slow down!"; a mutation fizzled (all 3 gone) and one
  succeeded (kept uid → Shiny Rookie); a sell paid `Formulas.sellPrice`. Mutation Machine panel + picker: the picker
  hides the locked copy (x16 of 17). A Shiny Donut Dee at Desk 1 at high quality: gold recolour + glints, the name tag
  reads SHINY / Earns x20. All test lawyers removed again (150 lawyers, none locked), saved.
- **Checks:** `run_checks.py` ALL PASSED (249 Luau files, 39 Config checks, 32 sim tests). Snapshot re-exported
  (103 scripts): exactly these 15 changed and each equals its `src/` copy.
- **Note:** a ChangeHistoryService recording from a failed command-bar call (title label lookup) may be left open in
  crnuch's Studio until it restarts - harmless, but the undo history around the sign rename may look odd.
- Still open: the eye-checks in the open item above.
- Signed: Claude (Opus 5.5) for crnuch, local session.

## 2026-10-13 — mr.robe, local session: the UPSTAIRS ROOMS - all 8 floor ideas built (no helipad)
User (angry that the minigames went first): "Add the things on the top floors that WE TALKED ABOUT"; "make it in
blender".
- **HEADS-UP crnuch: save v18 is LIVE and adds `data.Floors`.** It shares v18 with your mutations work in src/: your
  v18 step added nothing (Locked is optional), so the [17] step now creates Floors in both copies and nothing needs
  renumbering. Also changed, in live AND in your src/ copies:
  - `CaseService` (resolveCase: a win calls `FloorBonuses.onWin`);
  - `FirmFeatures.buffSources` (+ FloorBonuses' sources);
  - `LawyerService` (exports `upgradeOffice` + `equipBest`);
  - `FirmStages` (stage 5: a 5F elevator stop; **stage 6: the Supreme Tower is hollow now** - four glass walls, the
    TowerBand slabs are its floors, stops on tower floors 1, 2, 3, 6).
  
  Backup first: `Backup_Player_11776753629_1791948662` (v17).
- **Rooms** (Config.Floors; sets made in Blender: `tools/blender/floor_rooms.py` → `tools/zones/floor_rooms.json` →
  `tools/zones/BuildFloorRooms.lua` → `ServerStorage.Templates.FloorRooms`; render `art/floors/rooms.png`):

  | Stage | Rooms |
  |---|---|
  | 3 | Mail Room, Hall of Fame |
  | 4 | + VIP Lounge, Moot Court, Case Files Archive |
  | 5 | + Partner's Office, Guest Lounge |
  | 6 | all, in the tower + the Private Courtroom |

  Spots per building: `Config.Floors.Slots`, checked for overlaps with every building part on stages 3-6.
- **What they do** (`ServerScriptService.FloorRooms` + panels in `StarterPlayerScripts.Floors`, bonuses in
  `Server.FloorBonuses`):
  - **Mail Room:** 3 letters a day from clients (tasks fed by GoalService.track, which is wrapped), coins; the last
    letter also gives an egg.
  - **Hall of Fame:** every lawyer ever owned, by egg; a whole set = +5% cases.
  - **VIP Lounge:** a VIP waits every 6 min; pick a lawyer; it pays by rarity.
  - **Moot Court:** an office practises 15 min and gets a free skill roll.
  - **Case Files Archive:** wins by client type; milestones give +0.4% each.
  - **Partner's Office:** auto-upgrade the cheapest office at 3x its cost, auto-equip best.
  - **Guest Lounge:** a visitor staying 4 s = +10% for both for 5 min; guestbook likes.
  - **Private Courtroom:** hold court, 3 evidence picks, 10-minute recess.
- **Playtested on mr.robe's stage-5 HQ:**
  - all 7 rooms appeared on the right floors, facing right;
  - every panel opened with real data (a VIP had arrived, the Archive was already counting wins);
  - greetVip paid, Moot Court training started, claiming an unfinished letter is refused;
  - stage 6 built in a test copy: tower floors + 7 elevator stops, all 8 rooms fit;
  - no warnings.
- **Not yet:** the Private Courtroom played for real (stage 6 only), the Partner's rules switched on (left OFF on
  mr.robe's save), a second player for the Guest Lounge buff + likes.

## 2026-10-13 — mr.robe, local session: the ARCADE PIER + its first 3 games (minigames build, part 1)
User's call: build everything in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md except the Rooftop Helipad ("Add 2. and
3. I like these" / "not the rooftop helipad though" / "everything else"). Plan + progress table in that doc.
- **The hub has no free land** (its north edge is z 168, then the sea), so the arcade is a pier over the water:
  `Workspace.ArcadePier`, 70 x 100 studs north of the minigame pads. Built in Blender (`tools/blender/arcade_pier.py`
  → `tools/zones/arcade_pier.json` → `tools/zones/BuildArcadePier.lua`, 390 blocks; renders in `art/arcade/`):
  - a wooden deck with railings, an "ARCADE PIER" arch, lamp posts and string lights;
  - 8 booth slots (3 used now); the far end is kept for the big games.
- **Framework:**
  - `ServerScriptService.ArcadeServer`, with its games in `ArcadeServer.Games`. The server plans each round,
    checks every tap at its timestamp and scores 0..1; the reward is minutes of income.
  - The cooldown goes in `data.Minigames[id]`, so **no save change**.
  - `StarterPlayerScripts.Arcade` + `ReplicatedStorage.ArcadeClient` (`Kit` + one module per game).
  - `Config.Arcade`, merged into live Config without the mutation work.
  - `Remotes.Arcade`. File map: src/Arcade/README.md.
- **Games:** Lie Detector (stop the polygraph needle on the green band, 8 rounds), Briefcase Stack (drop sliding
  cases; the overhang falls off; perfect drops keep the width; 20 levels), Filing Frenzy (tap the bin that matches the
  front paper before the shredder: colours + shapes).
- **Playtested:**
  - The booths, boards and prompts work.
  - Lie Detector ran a full round with no warnings.
  - Briefcase Stack started.
  - Filing Frenzy not played yet: mr.robe was playing in the same session, so I stopped testing.
  - The snapshot (`studio/`) is NOT re-exported yet: Studio was in a playtest.
- **Next:** play Briefcase Stack + Filing Frenzy, export the snapshot, then Evidence Hunt (A4).

## 2026-10-13 — mr.robe, local session: zone travel live, the portal remade from mr.robe's references, a trip animation per zone; ideas doc
User: "Change the teleporters to look way cooler, make the models in blender, also make animations for each one that
progressively get better and better, just like the ones that you made for opening the eggs, Use the reference
images, but also start slow"; "List me some minigames ..."; "ideas of what we could have on the upstairs floors".
- **User's call (mr.robe):** keep crnuch's ONE Travel Portal + map (instead of six pads) and build on it.
- **crnuch's zone travel pushed to Studio:**
  - New `TravelServer` (Script), `StarterPlayerScripts.Travel` and `Shared.TravelFx`.
  - `Shared.HudMenu` (the Travel icon).
  - `Shared.Config`: ONLY the zone `Color`s and `Config.Zones.Travel`. Config's mutation work stays in `src/`, so
    src/Config still differs from live on purpose.
  - The six `Hub.ZoneTeleports` pads are archived in `ServerStorage.Old_ZoneTeleports`.
- **Portal v2** (`tools/blender/travel_portal.py`, crnuch's v1 in git history → `travel_portal.json` →
  `BuildTravelPortal.lua`, 198 blocks; renders `art/travel/portal.png` + `portal_under.png`). The three references:
  - a white tiered stage under a halo: a three-step round platform with glowing stripes;
  - a teleporter pad with an emitter ring above: a dark pad with glowing rings, a translucent light column, and a
    floating HALO with concentric glowing rings underneath, the six zone gems on its rim and two pylons;
  - a green iridescent vortex: a teal / mint swirl lying flat on the pad.

  Plus three floating rings round the column (`FloatRing1-3`: the client turns + bobs them) and "TRAVEL" floating on
  top. The builder now gives the swirl a pivot along the disc's axis (it lies flat).
- **Trip animations** (`Shared.TravelFx`, replaces the circle wipe; the server move happens under the flash / in the
  tunnel):

  | Zone | Trip animation |
  |---|---|
  | 1 Briefcase Bay | floor ring, light column, fade up in sparkles, flash (your normal camera) |
  | 2 Pet Park | + rising rings |
  | 3 Brainrot Blvd | + float, emitter halo overhead, camera push-in |
  | 4 Food Court | + implode, shockwave, a short vortex TUNNEL flight (glowing iridescent Blender rings, `EggModels.FxRing`) |
  | 5 Ocean Shore | + tiered platform rising, the camera circles, a longer tunnel with your avatar flying ahead (trail) |
  | 6 Space Base | + the world drains of colour, orbiting rings, long tunnel with star streaks, white warp exit, god rays + confetti + the sting |

  HOME uses step 1 in green. The portal you leave from flares.
- **Playtested:**
  - real trips to zone 1 and zone 6 (land facing down the lane);
  - steps 3 + 6 replayed client-side with a stand-in server call (charge, tunnel, landing);
  - no warnings except the asset permissions below.
- **Fixed during the playtest:**
  - a `WaitForChild("PlayerModule")` hung the first trip (this place has none): controls now freeze via WalkSpeed
    / Jump;
  - a boss ragdoll mid-charge left you stuck in Physics: `Bosses.client` skips its ragdoll while the local
    `Traveling` attribute is set, and GO waits until you're back on your feet;
  - the tunnel was blown out white (less white in the rings, gentler bloom, star streaks kept off the camera's
    path);
  - the light pillars were too wide.
- **Found:** `Skin.Assets.Rays` / `Glow` fail with "experience doesn't have access permission" (open item updated).
- **Ideas:** docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md (open item).
- Test-tool notes (CLAUDE.md): screen captures take ~10 s to come back, so time a capture with a mouse "wait"
  right before it; start camera-taking client code with `task.delay` so the tool doesn't reset the camera.

## 2026-10-13 — mr.robe, local session: office upgrade animations in the LAWYERS panel
User: "do upgrade animations when the character gets upgraded in the lawyers tab, make it way bigger for the max
level or upgrading multiple levels".
- New `ReplicatedStorage.Shared.UpgradeFx` (src twin `src/UpgradeFx.lua`), used by `StarterPlayerScripts.Lawyers`
  (the panel passes it hooks; its preview loop plays the hop/spin `kick`). Client-only, cosmetic.
  - **1 level:** the lawyer hops + spins on a sunburst, green "LEVEL UP!", a star burst, the office card bounces
    with "+1", the office tag flashes gold.
  - **2+ levels (MAX / UPGRADE ALL) or a new office look:** the level counts up ("Lv 2 → 100") with rising pings
    (HatchCue "beat"), more hops/spins, then a big burst, confetti, panel shake, "+N LEVELS!" (rainbow at 10+-ish,
    full size at 50+), "NEW LOOK: …", the sting. UPGRADE ALL bounces every upgraded office card in turn and
    celebrates over the office row.
  - **Max level (100):** then the whole panel celebrates: the lawyer big and whirling on a gold sunburst, rainbow
    "MAX LEVEL!", "OFFICE n · Lv 100", bursts + confetti rain; tap to close (closes itself after 4.5 s).
- Playtested single / MAX / UPGRADE ALL with no warnings. **mr.robe's save:** every office is level 100 now (the
  test spent ~1.3Qi of test coins); backup first: `Backup_Player_11776753629_1791924818`.
- Found: `Skin.Assets.Rays` / `Glow` don't load (open item above); UpgradeFx uses Effects' textures instead.

## 2026-10-13 — crnuch, cloud session: lawyer MUTATIONS (merging → mutating), selling + locking
- **User's calls:** merging is replaced by mutating (Normal → Shiny → Diamond → Cosmic); it isn't guaranteed and a
  fizzle takes all 3 lawyers; old Gold → Shiny, Rainbow → Diamond; a mutation recolours the whole lawyer (body parts
  must stay distinct), no extra effects; a SELL feature to clear the inventory (price = a share of the egg's
  current price - my pick, approved) + a lock.
- **How:** `Stars` keeps its numbers and now means the mutation tier, so saves aren't rewritten (v18 only adds the
  optional `Locked`). Earn x1 / 2.5 / 6 / 15; machine chances 70% / 45% / 25%; hatch mutation odds 2% / 0.3% / 0.02%
  (golden eggs 25% / 3% / 0.2%); sell shares 10%..1000% by rarity x the mutation. All first guesses; the sim's pacing
  targets all still pass (`tools/economy_sim.py` now mutates with chances + fizzles).
- **Look:** `Shared.MutationLook` (src/MutationLook.lua) + its Blender twin `tools/blender/mutation_preview.py`
  (render `art/mutations/preview.png`, real lawyers from lawyers_top.json).
- **Mutation effects (user's later call: "slightly more frequent and cooler"):** `Effects.mutationAura(model, tier)` /
  `clearMutationAura` (src/Effects.lua), added / cleared by `MutationLook.apply`: Shiny glints + sweep + gold dust,
  Diamond crystals + twinkles + frost + ring, Cosmic tilted orbit + stars + specks + galaxy haze; tagged `FxMutation`.
- **Review fixes (roblox-reviewer):** a locked lawyer can't go into the Mutation Machine (server refuses, the picker
  hides it); the old auto-pick `MergeLawyers(uid)` remote only takes unlocked bench copies now (it used to pull idle
  office lawyers too, which a fizzle would delete) and refuses a locked / office-queued main lawyer.
- **Checks:** 39 Config checks (mutations, hatch odds, selling) + 32 sim tests pass. Nothing pushed to Studio.

## 2026-10-13 — crnuch, cloud session: zone travel (portal + map), lane gaps + wall climbing, Blender in the cloud
- **User's calls:** travel option A (one portal + a map); every model is made in Blender from now on (CLAUDE.md →
  Blender); the portal face slightly see-through, with particles, a full circle; no travel while carrying eggs
  (my default - the walk home past the bosses is the game; `Config.Zones.Travel.BlockWhileCarrying` turns it off).
- **Blender runs in cloud sessions now** (`pip install bpy==5.2.2` + Mesa, recipe in CLAUDE.md): the portal was built
  and rendered here - `tools/blender/travel_portal.py` → `tools/zones/travel_portal.json` (116 blocks), review
  render `art/travel/portal.png`, HUD icon `art/icons/travel.png`.
- **Code:** `tools/zones/BuildTravelPortal.lua`, `src/TravelServer.server.lua` (Remotes.Travel, validated server-side),
  `src/Travel.client.lua` (TRAVEL tile + map + wipe + portal spin / particles / gems), Config zone colours + Travel.
- **Lane fixes** (`tools/zones/BuildLane.lua`): walls under every gate, invisible climb blocks on the wall tops.
- Also: docs/PROPOSAL_SUPREME_CRACK_AND_MUTATIONS.md (a suggestion, not built). Nothing pushed to Studio.

## 2026-10-13 — mr.robe, local session: the 18 Epic / Mythic / Supreme lawyers (Blender), Mythic + Supreme hatch cinematics, the 7-rarity push
User: "add the supreme, mythic, and epic [lawyers] ... described in the github by crnuch. the mythic and supreme should
b significantly cooler than the legendary, be more complex in style, and larger ... extreme vfx ... unique animations
when hatching", "create these in blender also".
- **Heads-up (save data + core economy): the whole `src/` economy pass is LIVE now.** Save **schema v17** (migration
  v17 = `Eggs.RunOpened`), 7 rarities (Epic = 4, Legendary = 5, Mythic = 6, Supreme = 7), egg tiers, Upgrade ×N / MAX /
  ALL, phone LAWYERS panel, the Supreme (prestige) panel (new `StarterPlayerScripts.Supreme`). mr.robe's save was
  backed up first (`Backup_Player_11776753629_1791907691`, v16) and migrated fine.
  - Pushed, each checked against the live source first (none had changed since the 2026-10-12 merge): Config,
    Formulas, Effects, HatchFx, Puppet (Shared); PlayerData, LawyerService, PrestigeService, FirmStages, EggServer
    (server); Eggs, Lawyers, Zones, Supreme (client).
  - FirmStages: the Supreme Tower only from `Config.Prestige.TowerLevel`. Zones: odds boards use
    `Formulas.luckyWeights` like EggServer.
  - Rarity-number audit of the Studio-only scripts: lookups go through `Config.Eggs.Skins[...]` / rarity names;
    Sounds' `value >= 3` still means Rare and up.
- **The 18 lawyers**, built in Blender as brick Parts (pipeline + sizes: CLAUDE.md → SkinModels,
  docs/CHARACTER_STYLE.md → "Epic, Mythic and Supreme"):
  - Epic: normal size, 43-62 parts. Mythic: 1.3×, 77-187 parts. Supreme: 1.6×, 93-186 parts, 10-13 studs tall.
  - Moving bits via Puppet Fx attributes: Phoenix's wings, the Kitsune's nine tails, Supernova's orbiting planets,
    halos, Thunderclap's storm cloud.
  - Earlier models with the same ids are in `ServerStorage.RetiredSkinModels`.
- **Hatch VFX** (HatchFx + Eggs; ideas from Sol's RNG cutscenes: a stage of its own, orbs that collide, ground cracks,
  a screen "breakthrough"):
  - **Epic:** lightning around the egg, 3 final bolts.
  - **Mythic:** crimson fissures and a red flash, then a cut to the Crimson Arena: an obsidian disc with glowing
    rings, 8 fire braziers, a blood moon, embers and a dusk sky. Orbs spiral in, burst, "MYTHIC!" + "1 in N", and the
    lawyer rises out of a fire implode.
  - **Supreme:** time stops (colour drains), a rainbow implode, the screen cracks white, then a cut to the Celestial
    Sanctum: marble, rainbow rings and pillars, a giant turning halo, stars and aurora under a night sky.
    "SUPREME!", then the lawyer descends through a rainbow pillar.
  - Lighting is restored after either one.
- **Server banner:** `Remotes.HatchAnnounce`. A Mythic / Supreme hatch slides a banner onto everyone else's screen
  ("X hatched a SUPREME Celestial Kitsune!" + the odds, rainbow for Supreme). Banners queue, at DisplayOrder 50, over
  every window.
- **Playtested** with `/hatch epic|mythic|supreme` previews. All three play end to end with no client warnings;
  132/132 moving parts animate in the reveal; sky and camera come back; desks animate the Fx too (DeskLife). The
  biggest Supreme (Grand Gâteau, 13 studs) fits his desk lane.
  - Fixed during the test: the stage "rings" were solid neon discs, so the floors were a sheet of red / rainbow →
    real rings.
  - Supreme marble read purple → brighter ambient.
  - The blood moon sat on the lawyer's head → moved aside.
  - The banner hid behind the Daily window → DisplayOrder 50.
  - A malformed banner message jammed the queue → pcall + rarity check.
- Test-tool notes (added to CLAUDE.md): a Client `execute_luau` that is running when the game changes CameraType gets
  it reset by the tool (the "stuck camera" after a hatch was that, not the game). Studio must be the front window
  or RenderStepped pauses (a white hatch screen).
- Next: the two eye-check items at the top of Open items.

## 2026-10-13 — mr.robe, local session: admin commands, lawyer rename, zone floor flicker, carried eggs hidden in the hatch
- **Admin commands** (user: "if i want to see a legendary egg hatching i should be able to will it into existence"):
  - `ServerScriptService.AdminCommands` (src twin `src/AdminCommands.server.lua`), for crnuch + mr_blox174 and anyone in a Studio playtest. Type in chat with `/` (TextChatCommands, hidden from chat) or `;` (Player.Chatted).
  - `/hatch <rarity> [egg] [golden]`: a **preview** hatch at your incubator (full animation, nothing saved, labelled "RARITY · PREVIEW").
  - `/eggs <count> [egg] [golden]`: real eggs in your arms (up to 30, past the carry limit).
  - `/coins <amount>` (5m / 2b / 1qd ...), `/help`.
  - Tested in a playtest: `;hatch legendary space golden`, `;eggs`.
- **Lawyer rename:** the Legendary `PinstripePartner` is now **"Bonk Bonk Timber"** (was "Tung Tung Tung Sahur", a real meme name; user's call). The id and model are unchanged. Config live + `src/`.
- **Zone floor flicker** (user: "the floor is glitching at the beginning of the zones"): z-fighting.
  - The lane floors sit at y = 0 on the world grass, and the License Office floor sat on the plaza floor.
  - The lower one of each coplanar pair with different colours dropped 0.03 (11 grass tiles, 6 gate-arch pieces, the License Office floor).
  - `tools/zones/BuildLane.lua` now does this pass itself at the end of a rebuild.
- **Carried eggs hidden during a hatch** (user): the hatch re-hides the eggs in your arms every frame (CarryPose rebuilds the pile when the count drops, which brought them back). Tested with a rebuild mid-hatch: 24/24 parts hidden.
## 2026-10-13 — mr.robe, local session: eggs v5 INSTALLED (crnuch uploaded)
- crnuch ran `ServerStorage.EggV5Upload` from his Studio: 12 textures + 56 meshes uploaded from the owner's account (ids: `tools/zones/egg_assets.json`, live in `ServerStorage.EggV5Assets`). The build was complete.
- **Installed:**
  - the built pieces: `ReplicatedStorage.EggModels` (v5; v4 kept as `ServerStorage.Old_EggModels_v4`), `ReplicatedStorage.IncubatorAnims`, `ServerStorage.Templates.IncubatorV5`;
  - `Shared.EggLook` v5 and the new `Shared.HatchFx` and `Shared.Incubator`;
  - `StarterPlayerScripts.Eggs` (the hatch at the incubator), `Eggs.EggServer` (HatchShow for every incubator hatch), `Server.FirmBuilder` (clones the v5 incubator, facing the aisle).
  - No live script had changed since `8468c2f`, so these were straight installs.
- **Removed** the upload data from the place (`EggV5Data`, `EggV5Upload`, about 11 MB). To regenerate, see docs/EGGS_V5.md.
- **Playtested** with results sent client-side (no saves touched):
  - Common, Rare and Legendary golden hatches; another player's view (HatchShow); KEEP closes it and restores the camera, HUD, character, post effects and prompts, and the incubator settles.
- **Fixes after the first playtest:**
  - your character, the eggs in your arms, the HUD and billboards (the "INCUBATOR" sign) are hidden during the hatch;
  - lights and bloom toned down (the white lobby washed out);
  - the dome lifts clear of the lawyer;
  - the reveal is framed above the panel;
  - the Legendary launch stops under the lobby ceiling (raycast) instead of flying through it.
## 2026-10-12 — crnuch, local session: step 0 (setup) — main + claude branch merged, snapshot re-exported
- **main:** rebased the 2 local-only commits (Skin.blockClicks fix for Supreme + notes; the "push to Studio every session"
  rule) onto origin/main. Conflicts in SESSION_LOG / CLAUDE.md resolved by keeping both sides.
- **claude/sharp-dirac-02vssj → main:** merged on branch `merge/sharp-dirac-into-main` (11 commits: CI checks, audit
  fixes, bosses, carry pose, working-efficiently rules). Only conflict: CLAUDE.md, kept both rule blocks.
- **Snapshot re-exported** (77 scripts + MANIFEST): identical to the committed `studio/` — Studio hasn't changed since
  a989131. New Mac/Linux receiver `tools/studio_sync/receive_snapshot.py` (`--fresh`, `--port`; port 8767 was held by a
  stale Oct 10 receiver on this Mac, so the export ran on 8768 with ExportSnapshot's PORT swapped at load).
- **Checks:** `run_checks.py` ALL PASSED (184 Luau files compile, 36 config checks, 31 sim tests). Luau CLI from the
  official luau-macos.zip release, kept outside the repo.
- **Not done here:** pushing to GitHub and opening/merging the PR need crnuch's OK (Claude Code's auto mode blocked the
  push; `gh` isn't installed on this Mac). Nothing pushed to Studio this session: no src/ or Studio changes were made.
- Signed: Claude (Opus 5.5) for crnuch, local session.
- **2026-10-16 follow-up (step 1):** nothing to push. Every audit fix was already live from mr.robe's 2026-10-12
  push. The fresh export (102 scripts) matches the committed `studio/`. What's left between `src/` and `studio/` in
  those files is the lawyer-mutations work (v18, open item above), not the audit. Still untested by anyone: buying a
  zone egg with [E] (the prompts need a rendered viewport). PR #4 closed: crnuch merged the branch directly.

## 2026-10-12 — mr.robe, local session: eggs v5 - eggs, hatch + incubator remade in Blender (waiting for crnuch's upload)
- **The user's asks:**
  - "remake the animations everything to do with the eggs through blender and add vfx, use examples in github and make them 10000x cooler and more detailled ask me details";
  - "recreate the eggs itself also", "make the eggs cooler";
  - "i dont like the little balls that protrude out of the eggs".
- **The user's answers:**
  - scope = the hatch (crack + reveal) + the incubator (+ the eggs);
  - VFX = the current ladder, maxed;
  - GitHub = learn from open repos, write our own (spr springs + RbxCameraShaker noise shake, both MIT);
  - effects scale with rarity;
  - the last tap reveals the rarity colour;
  - incubator: every egg floats in + dome spins shut, Rare+ cook, Legendary+ overload + launch;
  - meshes via the CreateAssetAsync Beta Feature.
- **Built** (full write-up in docs/EGGS_V5.md):
  - `tools/blender/eggs_v5.py`: one lathe shell; 12 painted 1024² textures (6 eggs + golden, painted per pixel from 3D patterns); flush relief layers; smooth pieces with no beads; the hatch shell cut into 12 chunks + 3 crack stages.
  - `tools/blender/incubator.py`: a 22-part machine + 4 keyframed clips: Open, Close, Cook, Overload.
  - `tools/blender/egg_break.py`: a Blender rigid-body sim of the chunks, three takes: pop, burst, blast.
  - `tools/blender/meshkit.py`: the shared mesh helpers.
  - `tools/zones/BuildEggsV5.lua`: EditableMesh -> CreateAssetAsync -> MeshParts -> `ReplicatedStorage.EggModels` (v5), `IncubatorAnims`, `ServerStorage.Templates.IncubatorV5`.
  - Runtime: `src/EggLook.lua` (v5, same `build()` API + `buildHatch`), `src/HatchFx.lua` (springs, shake, post FX, rings, god rays, pillars, bursts, the rarity ladder, the break player), `src/Incubator.lua` (the clip player).
  - The hatch v5 in the Eggs client (`src/` + `tools/zones/eggs_v5_live/`): it plays in the world at the incubator. Other players watch every incubator hatch (EggServer change). FirmBuilder clones the v5 incubator.
- **Checked in Studio Edit mode:**
  - local, unsaved EditableMesh parts: all six eggs + golden, the incubator, the Overload clip, the cracked egg, the blast break;
  - every edited script compiles.
- **BLOCKER: the game only loads assets its OWNER uploaded.**
  - Verified: crnuch's texture renders; mr_blox174's 12 textures and 56 meshes (uploaded fine) don't load: "Failed to load mesh asset".
  - So crnuch uploads (user's call). The mesh data is stored IN the place (`ServerStorage.EggV5Data`, 6.5 MB, chunked JSON) so his Studio needs no files. Textures: `art/eggs/textures/`. The builder refuses to build until his texture ids are set, and uploads in ~90 s slices.
- **Nothing live changed yet:**
  - no scripts installed; `studio/` is unchanged;
  - added `ServerStorage.EggV5Data` and `ServerStorage.EggV5Assets` (upload cache, per uploader).
- **Heads-up:** when installed, the hatch moves from the full-screen stage into the world at the incubator. The old ViewportFrame stage objects stay in the GUI, unused.
- **Later the same night:** crnuch's Claude is out of usage this week, so the upload no longer needs it:
  - the 12 textures are stored in the place too (base64 PNG; `tools/zones/PngDecode.lua`, a Luau inflate + PNG decoder);
  - the uploader is installed as `ServerStorage.EggV5Upload`;
  - crnuch's whole job is one Beta Feature + one command-bar line;
  - its output goes to `ServerStorage.EggV5Built` (not live) for the install.
  - Tested from here: the dry run (all 68 decode) and the local build (complete). A real image upload via EditableImage also works.

## 2026-10-12 — mr.robe, local session: odds board in every zone (exact + Lucky Eggs odds), PlotService leak
- User: "keep going add some more features that mr.blox wanted". Picked from the open items.
- **Zone odds boards:** the hub machines' odds boards left with the egg store, so each zone now has one beside its
  arrival spot (part `Zones.<Id>.OddsBoard`, tag `ZoneOddsBoard`, attribute `Zone`, on two posts; built by
  `tools/zones/BuildLane.lua`, and placed in the live lane at the same spot without a rebuild). Drawn by
  `StarterPlayerScripts.Zones` (new section at the end): "<EGG> ODDS", EGG and GOLDEN columns for every
  `Config.Eggs.Skins` tier, exact odds with EggServer's maths (golden = Rare + Legendary x `Zones.Golden.Luck`).
  **Lucky Eggs owners** (player attribute `PassLuckyEggs`, set by ShopService) see THEIR boosted odds (Rare +
  Legendary x `Config.Shop.Effects.LuckyEggs`) and a green "LUCKY EGGS ... (yours!)" footer; it redraws when the
  pass is bought. Playtested: Briefcase Egg 58 / 26.5 / 13 / 2.5 %, golden 39.6 / 18.1 / 35.5 / 6.8 %; with the
  pass 50.2 / 22.9 / 22.5 / 4.3 %. Pity isn't shown (it's a guarantee, not odds).
- **PlotService:** the per-visit `CharacterAdded` hook (teleport to your firm on respawn) is kept in
  `respawnHooks[player]`, replaced on re-assign and disconnected in `release` (audit leak).
- Tidied open items: hub machines decided, floor rings obsolete, GoalService count checked.
- No Python / Luau CLI on this PC: checks ran on GitHub CI only.
## 2026-10-12 — mr.robe, local session: detailed eggs + a new hatch (basic / fancy) from the user's video
- User (with a screen recording of a reference game): eggs "more detailed, like the video, keeping the cartoonish
  look"; "supreme, mythic and legendary hatches should look like the more complicated animation while the other
  ones can look like the basic animation". Their calls: 3 taps to crack; the fancy hatch falls onto YOUR INCUBATOR;
  keep the stats / PLACE / KEEP after the reveal; Claude designs the eggs.
- **The eggs** (Blender, `tools/blender/eggs.py`, render `art/eggs/preview.png` → `tools/zones/BuildEggs.lua` →
  `ReplicatedStorage.EggModels`): smooth glossy shapes (no studs), an egg-shaped shell of two ellipsoids. Briefcase =
  leather, stitched belt, gold clasp, handle on top; Pet = cream with calico patches, a paw print, red collar + gold
  tag; Brainrot = purple, neon-pink blobs, googly eyes, antenna; Food = biscuit + pink frosting with drips,
  sprinkles and a cherry; Ocean = deep blue / sky blue, foam wave, starfish, bubbles; Space = starry dark shell,
  glowing nebula, tilted neon ring, a moon. Golden = gold shell + the GoldenKit (Fabergé lattice, jewelled band, gold
  base ring, crown with a spire).
- **`Shared.EggLook`** (new, src + live) builds them: `EggLook.build(egg, golden, height, simple)`; unknown eggs get
  the Briefcase shape in their colour. Used by **ZoneService** (zone eggs 3.4 tall, golden 4.0; loose eggs keep
  their glass bubbles see-through) and **CarryPose** (the "simple" egg - no tiny bits - its Shell welded to the
  chest, the rest hanging off the Shell, so the sway is one weld per egg).
- **The hatch v4** (`StarterPlayerScripts.Eggs`, live + src - the same new section in both, src keeps its economy-pass
  bits): "Tap to crack!" / "Again!" / "One more!" (3 dots; each tap swells, shakes and brightens the egg; cracks by
  itself after 3.5 s) → cube-shard burst → the lawyer as a black silhouette in the rarity's light → colour: name +
  "RARITY · x% chance" → "Tap to continue" → the old panel (Earns xN, skills, PLACE / KEEP).
  BASIC (Common-Epic): a full-screen 3D stage - rings in the egg's colour, the egg's name on top, a glowing round
  pedestal. FANCY (Legendary / Mythic / Supreme, when the hatch came from an incubator): in the world - the camera
  looks up, the egg falls from the sky onto the incubator, impact rings, cracked there, a big lawyer appears there in
  an aura; the camera comes back on close. Nearby players see a short version (`Remotes.HatchShow`). The old voxel
  shell (Shared.HatchShells) is no longer used by the hatch. The section's loops run on Heartbeat (RenderStepped
  doesn't tick in a background Studio, so it couldn't be tested otherwise).
- **EggServer** (live + src): the hatch result adds `at` (the incubator), `golden`, `chance` (the % that rarity had
  in the odds it was rolled with, luck included); `Remotes.HatchShow` (new) fires for Legendary+ from an incubator;
  the old delayed burst stays for Rare (and for Legendary+ without an incubator).
- **Playtested** (results sent straight to the client, so no save changed): basic Common hatch → shards, silhouette,
  "COMMON · 61.5% chance", Tap to continue, the panel; fancy golden Legendary → scripted camera, "LEGENDARY EGG",
  the egg fell y 94 → 4 onto the incubator, impact, the three cracks, 48 shards, the lawyer, "LEGENDARY · 0.8%
  chance", the panel; a HatchShow from "another player" played nearby; zone eggs built in all six zones; no errors.

## 2026-10-12 — mr.robe, local session: the egg store is gone; the lane starts there and runs south
- User's calls: "remove the egg zone [the hub's egg store] and move the lane to where the egg store currently is so
  it's centered between the 2 sides of the firm"; License Office beside the new entrance.
- **Removed (kept in `ServerStorage.Old_HubEggMachines`):** Hub.EggTerrace, Hub.EggPads, the Brainrot / Food / Ocean /
  Space machines, Hub.ZoneSigns (old signposts that would stand in Briefcase Bay), 1 tree, and the grass tile under
  the lane's start (same height as the lane floor: it flickered). Every egg is sold in a zone now, so the egg
  scripts already treat a missing machine as normal. The hub's south gate stays as the lane's entrance arch (its
  sign "EGGS" → "EGG ZONES").
- **The lane** (`tools/zones/BuildLane.lua`): still built along -X, then turned into place by `PLACE` - it starts at
  the plaza's south edge (0, 0, -80) and runs south to z -2554, between the two halves of the south row of firms.
  The License Office is on the plaza west of the entrance, facing the lane. Scenery an earlier lane had hidden comes
  back first (HiddenDecor, HiddenBy = "ZoneLane"). The duplicate archive of the old position was dropped.
- **Config.Zones.List Bounds** (live + src) now {-36, z0, 36, z1} per zone (Briefcase Bay -490..-90 ... Space Base
  -2550..-2150). **BossService** works in lane terms (u along / v across, from the zone's longer side), so bosses walk
  either way; **ZoneService** teleports face down the lane (from the Arrival part's turn).
- **Playtested:** bosses walk at their new spots (Senior Partner z -130 ... Eclipse z -2287), arrivals face (0,0,-1),
  License Office prompts there, the walk from the plaza into the lane is clear, no errors. Render:
  `art/zones/Entrance.png`.

## 2026-10-12 — mr.robe, local session: zones 3-6 + their bosses - the whole lane is built
- User: "make the other 4 zones and their bosses" (this also closes the lane review: the lane design stands).
- **The lane** (`tools/zones/BuildLane.lua`, rebuilt; the old 2-zone lane is archived in `ServerStorage.Old_Zones`):
  Safe Zone + six 400-stud zones + gates + an end wall, x -264 → -2738. New: **Brainrot Boulevard** (purple, License 2
  Silver), **Food Court** (red-and-white picnic checkerboard, 12-stud tiles, License 3 Gold), **Ocean Shore** (sand,
  stone walls, License 4 Platinum), **Space Base** (dark floor, metal walls, License 5 Diamond). Each sells its themed
  egg (14 at a time). Zones can now set their own wall colours and floor tile size; gate badges take the license's
  colour (bronze → diamond). Fixed: the floor's two shades never alternated (always the second colour).
- **Decorations** (Blender, `tools/blender/zone_decor.py`, 24 new models, "neon" blocks supported):
  Brainrot - lollipops, spotted mushrooms, eyeball stalks, jelly cubes, a static TV, a giant gavel; Food - donuts,
  burgers, ice creams, fries, pizza slices, sodas (drawn 1.7x); Ocean - palms, beach umbrellas, sand castles, starfish,
  coral, life rings; Space - crystals, satellite dishes, rockets, alien plants, moon rocks, beacons. New floor clutter
  per theme (sprinkles, crumbs, ketchup, fries, shells, puddles, pebbles, glow pebbles).
- **Config.Zones** (live + src): four List entries (Bounds match the builder) and licenses Silver 1e8, Gold 2e9,
  Platinum 4e10, Diamond 1e12 (guesses). **Hub:** four more teleport pads (x -67 / -51, z ±8), in the zones' colours.
- **Bosses** (Blender, `tools/blender/bosses.py`; `Config.Bosses`):
  **Judge Martello** (a walking gavel with a face; hops; "Slam": jumps at where you stood, lands, 26-stud ring),
  **Prosecutor Big Cheese** (a cheese wheel with a moustache and an olive sword; "Line": turns side-on and ROLLS 110
  studs, 22 wide), **Magistrate Megalodon** (an upright shark in a robe with a lantern fish; "Line" charge 130 studs,
  then 2 s dizzy with stars), **Chief Justice Eclipse** (floating, eclipse face with a gold corona, orbiting gavels;
  takes turns: "Pull" drags everyone within 44 studs in at 16 studs/s for 2 s - the white middle is a hit - and "Ring"
  38 studs). `BossService` got the new attack kinds (+ AttackKind / Target state, airborne bosses can't be touched);
  the client got poses, warnings (landing disc, strip with arrows, swirl with a deadly middle), trails and stars.
- **Fixed after the first test:** the Pull and the dizzy stars only ran within 500 studs of the CAMERA - they now
  run for the player's character too (Studio's background camera never followed the test character).
- **Playtested:** all six bosses walk their zones, eggs in all six zones, six teleports, the License board offers
  "Silver License · opens Brainrot Boulevard · 100M"; Martello flew ~30 studs onto the test spot → hit; Big Cheese
  rolled 110 studs → hit; Megalodon charged → hit → dizzy (3 stars); Eclipse Pull dragged 30 → 20 studs in 0.6 s, then
  used Ring next; no errors. mr_blox174's two carried Pet eggs were set aside for the tests and restored.

## 2026-10-12 — mr.robe, local session: boss hits RAGDOLL, touching a boss is a hit, bosses outrun players
- User: "they should ragdoll the player as well, and if the player collides with the hitbox of the boss it also
  ragdolls them. They should also be faster than the player."
- **Ragdoll** (`StarterPlayerScripts.Bosses`, the hit player's own client): Physics state, every AnimationConstraint
  but Root switched off so the rig's BallSocketConstraints hold the limbs (Motor6D rigs get temporary ball sockets),
  limbs collide, flung away (Knockback 75 + up) tumbling; after `RagdollTime` 2.2 s everything is switched back and
  the player gets up facing the way they flew.
- **Touch hits** (`Server.BossService.touchLoop`, every 0.1 s): `Config.Bosses.List[n].Hitbox` (model units x Scale:
  HalfWidth / Back / Front / Height) - standing in it is a hit (ragdoll + all eggs out), same as an attack.
- **Faster than players:** Partner walks 38, Bulldog 44 (players 32, max 40 with shoes). User's call - overrides
  docs/BOSSES.md's "you can always outrun it". Kept fair with: windups unchanged (a player at base speed can still
  leave the warning), `SafeAfterHit` 4 s (was 3) and new `IgnoreAfterHit` 5 s (the boss that hit you won't chase or
  target you), and the chase stops with its front ~6 studs short of the player instead of trampling.
- **Playtested:** walking into the Bulldog → Hit, Physics state, 14/15 joints off, torso tumbling (69°), back up and
  Running after 2.2 s with every joint back on; the Partner's slam → ragdoll → up; walk legs measured 38 / 44
  studs/s; no errors.

## 2026-10-12 — mr.robe, local session: bosses made MUCH bigger, longer range, faster (user's calls)
- User: "make the attacks more frequent, make the models bigger, and make them faster and more dangerous", then
  "the range should be MUCH longer and they should be MUCH larger". `Config.Bosses` (live + src) now:
  TriggerRange 60, Knockback 75, DropScatter 6-14, Margin X 40 / Z 10; **Partner** Scale 3.5 (45 studs tall with the
  briefcase up), walk 18, Chase 0.85, every 3.5 s, windup 1.2, Cone **45 studs / 110°**; **Bulldog** Scale 3.5 (26 tall),
  walk 22, Chase 0.9, every 3 s, windup 1.4, Ring **34** (nearly the lane's width).
- Kept the fairness floor (docs/BOSSES.md): every windup still lets a player at base speed 32 get out of the warning
  (the 34-stud ring got the longer 1.4 s windup), 3 s safe after a hit, bosses slower than 32.
- New knobs: `Scale` (the client draws the Blender model that much bigger: blocks, offsets, joints, strides, bobs),
  `Chase` (how often a walk heads for a player in the zone; no idling while one is near). Floor warnings size their
  pieces to the radius (no gaps at 45 studs); bosses are drawn up to 500 studs away; "right under it" counts as a
  cone hit at 3 x Scale.
- Playtested: the Partner's slam hit at 39 studs, the Bulldog's bark at 29; no errors.

## 2026-10-12 — mr.robe, local session: zone bosses - The Senior Partner + Barrister Bulldog are live
- User's call: "yeah do the bosses" (before the lane review). Built the two whose zones exist, per docs/BOSSES.md.
- **Models (Blender, `tools/blender/bosses.py`, render `art/bosses/preview.png`):** brick blocks in animation groups
  with joints. The Senior Partner, 2x a player: charcoal three-piece suit, red tie, gold watch chain, white walrus
  moustache, half-moon glasses, grey comb-over, grumpy brows, a huge battered briefcase in one hand, pocket watch in
  the other, papers swirling round his ankles (68 blocks). Barrister Bulldog: squat fawn bulldog, black robe, curly
  white wig, barrister's bands + red bow tie, jowls, underbite, drool (77 blocks). → `tools/zones/BuildBosses.lua` →
  `ReplicatedStorage.Bosses`.
- **`Config.Bosses`** (live + src): shared SafeAfterHit 3, DroppedEggLifetime 30, DropScatter 4-10, DropStagger 0.05,
  GrabbableAfter 0.9, GrabRadius 4, TriggerRange 26, Knockback 38, Margin X 24 / Z 8; Partner: walk 7, every 8 s,
  windup 1.2, Cone 15 studs / 80°; Bulldog: walk 8, every 8 s, windup 1.0, Ring 13.
- **`Server.BossService`** (new, started from Main): each boss walks short legs inside its zone (Partner strolls the
  middle, Bulldog zig-zags; never the Safe Zone / gates), idles (watch check / sniff / sit-and-scratch), and attacks
  the nearest player in range: windup, then the hit is decided on the server from where everyone stands. Hit = every
  carried egg knocked out (`ZoneService.dropAll`) + 3 s safe; carrying nothing = a bump. The server moves no parts:
  `ReplicatedStorage.BossStates.<Model>` attributes (From/To/MoveStart/MoveEnd/Yaw/State/StateStart/StateEnd/Idle);
  `Remotes.Bosses` ("Hit", "Grab").
- **`Server.ZoneService`:** the egg model is shared (`eggModel`) so loose eggs look like zone eggs. `dropAll` lands
  each egg around the player inside the zone (hidden until it has landed); a loop shows them, lets anyone who walks
  into one take it free through the normal carry checks (arms full / lawyer room), and removes them after 30 s.
- **`StarterPlayerScripts.Bosses`** (new): draws each boss near the camera (≤340 studs; further ones are hidden) and
  poses its groups every frame: walk cycles, watch check, briefcase lifted overhead with a tremble then slammed in
  front; waddle, wag, sniff, sit-and-scratch, puff-up then bark. Windup = a pulsing warning on the floor in the boss's
  colour (a fan for the cone, a disc for the ring) + the alert sound cut short; attack = paper burst / shockwave rings
  + a gavel thump + camera shake nearby; hit = sparks, knockback, the eggs pop out top-down, arc, squash, bounce twice;
  loose eggs bob, spin, glow (Highlight) and blink in their last 5 s; grab = the egg hops into the grabber's arms.
  No text anywhere.
- **Playtested:** both bosses spawn and walk; Partner: windup 1.2 s with the floor warning + briefcase above his head
  (y 11.9 vs head 9.1) → slam → Hit, 3 eggs out; loose eggs landed on the floor (golden kept), shown after landing,
  grabbed by walking into them; a second hit 8 s later. Bulldog: windup disc → bark shockwave → Hit, player thrown
  ~6 studs. No errors (after swapping rbxasset swoosh.wav, "not approved for this place", for the alert sound).
  mr_blox174's two carried Briefcase eggs were knocked out during testing and restored.

## 2026-10-12 — mr.robe, local session: HUD moved up; the Carry upgrade is BRIEFCASES now
- **HUD** (user: "get rid of the 'case coins float up by your money' … move up the money and the text below"):
  `Hud` ScreenGui uses IgnoreGuiInset; the coin pill sits 4 px from the top inside Roblox's top-bar strip (checked:
  the strip's free area is x 260..1255 on a 1255-wide window, the pill x 507..747), hint banners right under it
  (66 px). The "Case coins float up by your money: GREEN = WIN …" legend is gone. The small "+1.72K WIN" numbers
  still appear right of the pill but drift DOWN now (they'd leave the screen going up).
- **Briefcases** (user's call: "an upgrade that means you can carry more eggs, like a briefcase"): the License
  Office's Carry upgrade got names, models and two more tiers - `Config.Zones.Carry` (live + src):
  Empty Hands 1 · Briefcase 3 (2.5e5) · Big Briefcase 5 (2.5e7) · **Golden Briefcase 8 (2.5e9)** ·
  **Diamond Briefcase 12 (2.5e11)**. Same save field (`Zones.Carry` = level), no schema change.
  - Models made in Blender (`tools/blender/briefcases.py`, render `art/briefcases/preview.png`): brown leather → red
    with gold corners → gold with a glowing star → sky-blue with a glowing diamond; studded blocks →
    `tools/zones/BuildBriefcases.lua` → `ReplicatedStorage.Briefcases`.
  - `CarryPose` hangs your tier's briefcase on every player's back (welded, slightly crooked, every client draws it;
    removed on respawn). The License Office's Carry counter shows a Big Briefcase instead of the orange ball
    (BuildLane does it too). Board / prompt: "BRIEFCASE · Big Briefcase (5 eggs) · 25.00M".
  - Wording: "bag" → arms / carrying ("Your arms are full!", "Carrying 2/3", "Big Briefcase! You can carry 5 eggs").
- **Playtested:** levels 1-5 swap the model live (none / 8 / 12 / 14 / 13 parts, all welded, neon on 4-5), it sits
  centred on the back and stays put while walking; board + prompt texts right; HUD pill at the top, legend gone, a
  real case result showed beside the pill; no errors. (Measuring note: a welded Model's GetBoundingBox / GetPivot
  don't follow physics moves - measure a part.)

## 2026-10-12 — mr.robe, local session: the egg-carry pose is a real animation now (made in Blender)
- User: the carry pose "is bugging". The first CarryPose wrote the arm joints every frame on top of the Animator, and
  moved anchored eggs in RenderStepped. Now:
- **Blender** (`tools/blender/carry_anim.py`): Roblox's default R15 rig rebuilt from Studio's joint data
  (`tools/blender/r15_rig.json`; each bone's rest = its joint frame, so a bone's local rotation IS the Roblox Transform).
  A solver puts the hands on the bottom egg's sides (shoulder 24° forward / 24° in, elbow 36°, waist leans back 5°),
  then a 2 s hug / breathe loop, keyed every 6 frames. Renders: `art/carry/carry_{front,side,three_quarter}.png`.
  Exported as joint Transforms: `tools/blender/carry_anim.json`.
- **Studio:** `tools/zones/BuildCarryAnimation.lua` → `ReplicatedStorage.Animations.CarryEggs` (Animation; child
  `Source` = KeyframeSequence, Action priority, looped; HumanoidRootPart / LowerTorso are Weight-0 pass-throughs, so
  the walk keeps the legs and hips). **Not published yet** (Open items): until then it plays only in Studio.
- **CarryPose rewritten:** each client plays CarryEggs on its own character while carrying (replicates to everyone);
  every client welds the egg pile to each carrier's chest (massless, no collisions) and only nudges the welds for
  the sway. Eggs are smaller (0.68 x torso width) and sit at the belly, so the pile covers less of the face. R6
  avatars carry the eggs without the arm pose.
- **Playtested:** Action track plays; while walking the hips swing 6–72° and the shoulders stay at 31–37° (hug);
  the eggs stay put on the chest through the walk; emptying the bag stops the track and removes the eggs; no errors.
  On mr_blox174's avatar (shorter arms than the default rig) the hands hold the bottom egg ~0.3 higher than in
  Blender - still on its sides.

## 2026-10-12 — mr.robe, local session: crnuch's audit fixes + the egg-carry pose are live in Studio
- **Pushed** (3-way merged commit by commit onto the live scripts, so nothing of the economy pass came along):
  `PlayerData` (Studio-only memory fallback, live retries / kick, `write` reports failure, rejoin waits for the
  release, NaN coins refused), `CaseService` (`finishAll`, badges spawned), `DeskService` (expansion pays out running
  cases first), `BigCaseService` (Gavel NaN, backdating ≤ ping), `LawyerService` (place goal once per lawyer,
  `mergeSelected` uses picks 1..N), `PrestigeService` + `EggServer` (badges spawned; EggApi `price` takes `ahead`),
  `Config` (Stage 6 rooms 5e15 / 5e16), `ZoneService` (no eggs over the head, bag price passes `#z.Carried`).
- **Live-only fixes from the audit list:** `PlayerSpeedDouble` deleted; `ZoneService` incubator throttle 2.5 s like
  EggServer + "Still hatching..." toast; `RewardsService` playtime counts only while the character really moves
  (> 2 studs in the activity window) + the free-egg fallback updates `FreeEgg` / `EggTokens`; the `while true`
  loops in `RewardsService`, `ManagerService`, `LeaderboardService` are pcall'd per iteration.
- **CarryPose fix:** Studio now gives R15 avatars the new joints (AnimationConstraint + BallSocketConstraint, **no
  Motor6Ds**), so the arms never moved. `armsOf` now takes either; an AnimationConstraint's attachments stand in for
  C0 / C1. Checked: both arms come up to ~72° with the hands in front of the chest, 3 eggs built (golden = neon),
  pile math puts the bottom egg against the chest between the hands, no errors.
- **Playtested:** no errors on join / in play; expanding the firm with a case running paid it out (5,175 coins),
  the firm rebuilt and a new client walked in; EggApi price 3990 → 4588 one egg ahead, NaN ahead ignored.
  Not testable here: pressing E on a zone egg (ProximityPrompts only show while the viewport renders).
- **Not pushed:** exact-odds luck (needs `Formulas.luckyWeights` from the economy pass), the lawyer renames
  (`src/Config`), economy pass, 7 rarities. `src/ZoneService.lua` = live now; `studio/` re-exported.
- **MaxPlayers is 60** with 8 plots: Open items.

## 2026-10-12 — crnuch, cloud session: zone boss concepts, lawyer names simplified
- **Egg-carry pose** (user's ask): eggs are carried in outstretched arms instead of over the head - oversized eggs
  that pile up "not perfectly" (each nests into the one below, a bit off to the side and tilted, the pile leaning back
  against the chest, swaying more at the top while walking). Procedural (arm Motor6D.Transform after the animations),
  so no Animation asset has to be made or published; every client draws it for every carrying player. Files above.
- **User's calls:** (1) legal titles (Counsel, Partner, Prosecutor, Attorney, Barrister, Solicitor, Litigator,
  Advocate, Judge, Justice, Magistrate, Arbiter) are for **bosses only**; lawyers get short fun names. (2) Any boss hit
  drops ALL your eggs, animated (they fly out of your arms, bounce, wobble), with **no on-screen text** (no boss name or difficulty tag either), and **a
  dropped egg is free game** for anyone. (3) Boss Cases: parked for later.
- **41 lawyers renamed** (display `Name` only; Ids unchanged, so saves are fine), e.g. Corgi Counsel → Corgi Cooper,
  Sushi Solicitor → Sushi Sue, Star Judge → Starla, Kraken Counsel → Inky the Kraken. Rule + table in
  docs/CHARACTER_STYLE.md; `src/Config.lua` changed, comments in `tools/skins`, `tools/brick` follow.
- **docs/BOSSES.md:** The Senior Partner (Briefcase Bay), Barrister Bulldog (Pet Park), Judge Martello (Brainrot),
  Prosecutor Big Cheese (Food), Magistrate Megalodon (Ocean), Chief Justice Eclipse (Space): look, moves, one
  telegraphed attack each, lines, build notes, Config numbers, how it plugs into ZoneService.
- Open: push `Config` to Studio for the names (with the audit push); build the bosses (local session, Senior Partner
  first) once the lane review is in.

## 2026-10-12 — crnuch, cloud session: CI checks, bug / exploit audit (src + live scripts), exact-odds luck
- **CI** (`.github/workflows/checks.yml`, `tools/checks/run_checks.py`): every push compiles every Luau file (src/,
  studio/, tools/), runs 35 checks on the real Config + Formulas (odds, Supreme 1 in 2500 in every egg and under
  luck, every egg has a lawyer per rarity, ids, climbing costs incl. firm areas, growth ratio) and the sim tests.
  All runs green on GitHub.
- **Audit** (docs/AUDIT_2026-10-12.md): `src/` and, after the snapshot landed, every live server script. Biggest
  fixes: a live DataStore blip made the whole server memory-only (fresh never-saving firms, Robux receipts
  acknowledged unsaved); expanding the firm threw running cases away unpaid (now they finish and pay first - waiting
  for no cases isn't possible with auto-assign, user); a NaN Gavel press won every Big Case Gavel round; zone bags
  bought at one price (~26% off); badge calls that could leave a prestige half done; Stage 6 rooms priced 5e8.
  New `src/` working copies: `BigCaseService`, `DeskService` (only lived in Studio).
- **Luck keeps Supreme exact:** Lucky Eggs and golden zone eggs multiplied Rare/Epic/Legendary without taking the
  chance from anywhere, so Supreme fell to ~1 in 3850 on a golden egg (~1 in 5650 with the pass).
  `Formulas.luckyWeights` takes it from Common/Uncommon instead (`Config.Eggs.LuckRarities / LuckPaidBy`).
- **Dropped:** a blind zones system written before this session saw mr.robe's live zones + claim (it duplicated
  ZoneService). Nothing of it was kept but the luck formula. Lesson recorded in CLAUDE.md already: `git pull` first.
- Nothing pushed to Studio.

## 2026-10-12 — mr.robe, local session: egg zones rebuilt as the walled lane (rough, 2 zones) + Blender decorations
**User's call:** the lane design from docs/ZONES_REFERENCE.md replaces the two islands (archived:
`ServerStorage.Old_Zones`). Only Briefcase Bay + Pet Park, rough, for review; no bosses.
- **Build tools (re-runnable, in the repo):** `tools/zones/BuildLane.lua` (the lane) and
  `tools/zones/BuildDecorLibrary.lua` (decorations). Run them in Studio's Edit mode with
  `tools/studio_sync/serve_files.ps1 -Root tools/zones` serving the files; the library goes first.
- **Layout:** the lane runs west from the end of the street (x = -264, z = 0). It has a 10-stud Safe Zone (red neon
  line + "SAFE ZONE" lettering), then Briefcase Bay (x -274..-674), a Bronze License gate arch (badge + "PET PARK ·
  Bronze License · 5M", barrier tagged `LicenseGate`), Pet Park (x -686..-1086), a closed "BRAINROT · Silver License ·
  COMING SOON" gate with 70 studs of purple teaser, and an end wall.
  - **Floor and walls:** 72 studs wide (40 felt narrow; user), between terracotta walls 14 tall. Each wall top is
    30 studs of the zone's ground colour. Everything uses `MaterialVariant = BrickStuds`, the characters'
    material, so it's studded on every face.
  - **Floor colours:** Briefcase Bay is cornflower-blue carpet; Pet Park is lime. Each zone starts with a darker
    border strip.
  - **Path:** orange, 8 wide, with white dashed edges. White chevrons every 16 studs, tagged `ZoneChevron`; the
    client turns them gold and flips them to point home while you carry eggs.
  - **Eggs:** 40 invisible EggSpots per zone, `MaxEggs` 14.
  - **License Office:** moved to the lane entrance (x ≈ -246, z 19–35, beside the street).
  - **Config:** `Config.Zones.List` bounds were moved to the lane, in Studio and in `src/`.
  - **Size:** about 5,500 parts in total, roughly 2,300 for Briefcase Bay and 2,700 for Pet Park.
- **Blender decorations (user: "use blender ... more lively, same art style"):** `tools/blender/zone_decor.py` builds
  19 block models: forked brick trees in 4 sizes plus a blossom tree, bushes, flower beds, rocks and grass tufts, an
  office plant, leaning file boxes, a water cooler, a park bench, a flower hedge, a dog house, a bone pile, a toy
  pile and a hydrant. It exports them to `tools/zones/decor_library.json`, which becomes
  `ServerStorage.ZoneDecorLibrary`: studded Parts, no mesh imports. Preview: `art/zone_decor/preview.png`.
  - **No MCP needed:** the blender MCP server timed out at session start, so `tools/blender/send.ps1` talks to the
    BlenderMCP add-on's socket (port 9876) directly. It needs Blender open with the add-on's server started.
  - **Gotcha:** objects made through the API in a scene that's never evaluated keep an identity `matrix_local`, so
    read `location` / `rotation_euler` instead. The first export put every block at the origin.
- **Gameplay changes (live in Studio; see `studio/`):** zone eggs are knee-high and sit on the floor with a small
  wobble, never floating. Each has a 2-line label, the egg's name then its rarity in its colour (normal = Common,
  golden = Rare). The price only appears in the [E] prompt. A "YOUR FIRM" marker floats over your own firm.
  Playtested: buying works and the chevrons flip home.
- **Review shots:** Studio's viewport can't be captured while its window is in the background, so the real lane
  geometry was exported (Edit `execute_luau` → local receiver) and rendered in Blender (`tools/blender/lane_preview.py`)
  next to each reference shot: `art/zone_decor/compare_{safezone,lane,gate,base}.png`. Blender's light is flatter
  than Roblox's.
- **Open after review:** the zones may want to be shorter or denser (the reference packs more eggs and props per
  stretch), plus more floor props, the remaining four zones, the bosses, and the hub teleport pads' arrival points
  (they use each zone's `Arrival`, so nothing to change).

## 2026-10-12 — mr.robe, local session: repo becomes the shared brain; Studio snapshot; src merged with live Studio
- GitHub connected on mr.robe's PC (Git + GitHub CLI via winget, signed in as `ss-rob`, push access); repo cloned to
  `Documents\HatchLawyers`. **PR #1 merged** (economy pass fix, egg tiers, 7 rarities, phone panel).
- **`studio/`**: first read-only snapshot of all 77 scripts in the live place + `MANIFEST.json`, exported with the new
  `tools/studio_sync/` (receiver + `ExportSnapshot.lua`). Scripts that only ever lived in Studio (FirmBuilder,
  FirmStages, FirmFeatures, ZoneService, MinigameService, BigCaseService, PlotService, Main, ...) are now visible here.
- **`src/` merged with live Studio** (3-way, base = each file's last pre-WIP commit): Config, EggServer, Eggs,
  Lawyers, LawyerService, PlayerData, Effects. Conflicts resolved: PlayerData schema → **v17** (the economy pass's
  RunOpened migration renumbered 13 → 16, because live saves are already at v16); Config keeps the economy pass
  values + the two Legendary renumbers; EggServer combines the egg tiers / price ramp / rarity bursts with the
  incubator API (zone eggs skip the tier lock, golden eggs boost Rare/Epic/Legendary only). Studio was newer and
  `src/` had nothing pending for CaseService, Hud, Skin (+ `Skin.blockClicks` users Courtroom, Manager, Skills,
  Rewards) → copied from Studio. PrestigeService: economy-pass ladder + Studio's License reset. All 16 changed
  files compile (Studio `loadstring`). Lesson: Windows PowerShell 5.1 reads files/`git show` output as ANSI and
  garbles ★ · — — read and write with explicit UTF-8 (`[IO.File]::ReadAllText(p, [Text.Encoding]::UTF8)`).
- CLAUDE.md: "One team, one brain" (who's who, claim-before-big-work, Studio ↔ repo rules), team/ownership,
  layout, schema, MCP gotchas updated. **Nothing was pushed to Studio in this step.**

## 2026-10-09 → 10-12 — mr.robe, local sessions (Studio only until now; summarised here when the repo was connected)
All of this is live in Studio (see `studio/`); details of each system are also in `ServerScriptService.README`.
- **Hub:** Big Case conveyor rebuilt as a ground-level treadmill in the plaza centre with glowing in/out portals (spawn
  pad removed); hub revamp: egg terrace at the top, Shop + Lawyer Merger spots in the middle, Big Case belt and two
  SpecialSpots at the bottom.
- **UI:** a Figma UI kit ("Hatch a Lawyer – UI Kit") turned into `Shared.UIKit` + `StarterPlayerScripts.UISkin`
  (auto-skins older screens: chunky glossy buttons, panels, pop-ins).
- **Firm stages** (`Server.FirmStages` + `Server.FirmFeatures`): six front buildings by firm size — Dingy Shack (kept),
  Storefront Practice, Main Street Firm, Glass Office, Corporate HQ, Supreme Tower (prestige) — with a floor-by-floor
  build animation + "FIRM UPGRADED!" banner (`FirmStageUp`). Rooms (`Config.FirmAreas`: café, library, conference,
  lounge, roof garden, ...) give bonuses (CaseService `deskBuffs` / rare clients) and are sold by ONE lawn pad that
  offers the cheapest room left (user: "simplify the upgrades"). Showcase gallery of your best lawyers behind the
  street windows, rooftop hologram (HQ/Tower), elevators between floors, Executive Lounge bonus while you stand in it.
  Removed at the user's request: the pergola "fencing" over the hall and the Hatch Lab egg. Old buildings kept in
  `ServerStorage.Old_Firms`.
- **Hub minigames** (`Server.MinigameService`, `StarterPlayerScripts.Minigames`, `Config.Minigames`, schema v15): Gavel
  Bonk (20 s whack-a-mole: bonk robbers, not the judge) and Lucky Briefcase (shell game, every case pays) on the
  SpecialSpots; 5 / 6 min per-player saved cooldowns; rewards = minutes of the player's own income.
- **Egg zones** (`Server.ZoneService`, `StarterPlayerScripts.Zones`, `Config.Zones`, schema v16): Briefcase Bay (zone 1,
  over a bridge past the west end of the street; law-office theme on royal-blue paving) and Pet Park (zone 2, behind a
  License gate; dog-park theme on lime grass). 7 eggs per zone on EggSpots, golden eggs (6 %, 5x price, 4x
  Rare/Legendary, server alert), buy → carry over your head (saved) → hatch at one of two **incubators** in the firm
  lobby. License Office: Law License (opens Pet Park, **reset by prestige** — user's call), Bigger Bag 1/3/5, Faster
  Shoes 32/36/40 (replaces the old `PlayerSpeedDouble` script, now disabled). Hub teleport pads west of the plaza.
  The hub's Briefcase + Pet machines are archived (`ServerStorage.Old_HubEggMachines`). Playtested end to end.
- **No waiting room** (user's call): clients walk from the street straight to a free lawyer (Manager picks the best);
  the lobby furniture is stripped and the incubators stand there; the LAWYERS panel's CLIENTS tab is hidden; tutorial
  step 1 is automatic and step 4 points at the incubator. CaseService's main loop is now guarded so one bad tick can't
  stop it for every player.
- Test save of `mr_blox174` reset to a fresh player with 90 Qi coins (old save backed up as
  `Backup_Player_11776753629_<time>`).

## 2026-10-12 — cloud session: Epic, Mythic and Supreme rarities (in `src/`, not Studio; models still to build)
- `Config.Eggs.Skins`: 7 rarities (Epic inserted at 4 between Rare and Legendary; Mythic 6, Supreme 7). Earn
  1 / 2 / 4 / 6 / 10 / 25 / 60, StartSkills 1 / 1 / 2 / 2 / 2 / 3 / 3. **Supreme 0.04 % = 1 in 2500 in every egg**;
  Mythic 0.16 % (Briefcase) rising to 0.96 % (Space); odds tables in docs/ECONOMY.md. All Legendaries moved 4 → 5.
  Saves store Ids, not rarity numbers, so nothing saved changes.
- `Config.Eggs.PityRarity = 5`: pity (50 eggs) guarantees Legendary, never Mythic / Supreme; Legendary+ resets it
  (EggServer; the old rule "the rarest tier" would have made Supreme a pity drop). Lucky Eggs: Rare / Epic /
  Legendary only.
- 18 catalog entries (one Epic / Mythic / Supreme per egg) with names + UI swatch colours; **no models** (user's call:
  the local session builds them — an attempt here was dropped). Concepts in docs/CHARACTER_STYLE.md.
- `Shared.Effects`: Mythic aura (crimson inferno) and Supreme aura (rainbow fire + stars + energy + halo); bursts
  `epic` / `mythic` / `supreme`; `Effects.rarityBurst(id)` (EggServer and LawyerService use it).
- Hatch screen: Mythic / Supreme reveal looks (crimson / rainbow name shimmer), Legendary+ gets the long build-up
  (5 shake rounds Mythic, 6 Supreme), odds boards show two decimals under 1 % (0.04 %), HatchCue also sends the name.
- Sim mirrors it (31 tests). Seeds 1–5: targets hold except one seed that hatched a Supreme lawyer in minute 2
  (first prestige at 20 min) — the jackpot. **User's call: keep Supreme at ×60**, early luck included.

## 2026-10-12 — cloud session: economy pass finished, egg tiers, phone LAWYERS panel (all in `src/`, not Studio)
Branch `claude/sharp-dirac-02vssj` from `main`. Nothing was changed in Studio; see the push item in Open items.
- **Bug fix:** `src/Config.lua` (WIP economy pass) didn't parse — a comment written mid-line in
  `Config.Firm.ExpandCosts` swallowed segments 7–10 and the closing brace. Found with `luau-compile`. Tip for
  cloud sessions: download the Luau CLI (`github.com/luau-lang/luau/releases`, `luau-ubuntu.zip`) and run
  `luau-compile --binary src/<file>.lua > /dev/null` on every edited file — it catches syntax errors (not types).
- **Egg tiers:** `Config.Eggs.Themed[*].UnlockEarned` (lifetime coins earned: Pet 1e7, Brainrot 1e9, Food 1e11,
  Ocean 1e15, Space 1e18) and `EarnMultiplier` (×1.25 / 1.5 / 2 / 3 / 4). `Formulas.eggUnlocked`;
  `Formulas.lawyerEarn` includes the egg's multiplier (so payouts, EQUIP BEST, the Manager and every "Earns x"
  label follow). `EggServer.onRoll` refuses a locked machine (`reason = "locked"`, `need`); `PlayerData` mirrors
  `CoinsEarned` (no new saved field, no schema bump); `Eggs` client: locked prompt text + progress, odds-board
  footer ("Unlocks at X earned" / "Lawyers earn xN!"), locked toast. `Prestige.CostGrowth` 5 → 7.
- **Sim:** models the real themed eggs (own lawyer pools, shared ramp + pity, unlocks, EarnMultiplier) instead of
  the old hypothetical `egg-tiers` scenario; new scenarios `pre-egg-tiers`, `briefcase-only`; 5 new tests (26 total).
  Results (seeds 1–5): first Supreme 40–70 min, 12–13 Supremes/day, eggs keep selling all day; tables in
  docs/ECONOMY.md and docs/ECONOMY_REVIEW.md. Found: themed eggs at 2–16× price never beat the Briefcase Egg per coin
  (that's why each tier needs stronger lawyers, not just better odds).
- **Phone LAWYERS panel** (`src/Lawyers.client.lua`): below panel scale 0.8, office-card names, bench names, client
  situations and the status line stop shrinking (`TextScaled` made long strings ~5 px on a phone): fixed size of
  at least 11 real px (capped by the box), truncated with "..." or wrapped (situations, 2 lines; client rows 64 → 76
  tall). Office-card art 64 → 58 tall to give the name 20 px. Desktop size unchanged. Not eye-checked.
- **Docs:** ECONOMY.md updated to the economy pass (TrainBase 2000 × 1.37, egg ramp per run, Supreme ladder,
  pacing targets) + an egg-tier table.

## 2026-10-11 — local session: brick style for the whole cast; windows no longer close on a stray tap
- **Checked first** (user's condition): a brick lawyer on the egg hatch screen (a fake Rookie hatch, nothing saved) and
  brick lawyer + client in the courtroom (answering, OBJECTION pose) - 0 errors - so the rollout went ahead.
- **Every character is brick now** (docs/CHARACTER_STYLE.md):
  - 9 people lawyers rebuilt on BrickKit (`tools/brick/Lawyers.lua`); Rookie was the benchmark.
  - 43 creature lawyers converted in place (`tools/brick/ConvertLawyers.lua`: studs material, Metal -> Plastic, shine
    dots off, eye rims) - they keep their own body plans. The Manager model was converted the same way.
  - 44 clients (`tools/brick/Clients.lua` + NeighborDave.lua), 5 judges with a GavelArm (`tools/brick/Judges.lua`).
  - Old models kept: ServerStorage.RetiredSkinModels.<Id>_preBrick, RetiredClients.<Id>_v3, RetiredJudges.<Id>_preBrick.
  - `tools/brick/Run.lua` builds/installs batches and checks the arm rig: Shared.Puppet puts a shoulder at the top of
    the arm's highest part (Size.Y, ignoring rotation), so a prop held high would move the joint. Caught and fixed on
    Selfie Counsel and Livestream Litigator.
- **Bug fix: windows closed when you tapped empty space inside them** (Shop, Skills, Manager, Daily, Courtroom,
  Lawyers; Supreme in the repo only). A Frame doesn't stop a click even with Active = true; the click reached the
  full-screen close backdrop. New `Skin.blockClicks(panel)` puts a transparent button under the content. Verified in a
  playtest: empty space inside the Shop keeps it open, outside closes it.
- **Studio changed under this repo:** the place reloaded as "Hatch a Lawyer!" with v16 egg zones (see Open items).
  Pushes this session were checked line by line; Studio's Lawyers script got only the one-line fix patched in.
- Playtest on v16 with the brick cast: 15 desks on cases, 21 brick clients, all-brick courtroom; 0 errors either side.

## 2026-10-11 — local session: brick character style (benchmark), four lawyers renamed
- **Character redesign** from the user's new reference recording (a "steal an egg"-style pet game; characters only,
  style only). Style guide, rules, rarity ladder and example sheets: **docs/CHARACTER_STYLE.md** (user approved
  the examples; animal/food lawyers stay human-shaped (our call); mouths kept; studs on every face).
- **`tools/brick/BrickKit.lua`** (Studio: `ServerStorage.BrickKit`): one kit for lawyers + clients. Chibi frame (head
  ~38%), hard Plastic bricks, square rimmed eyes, brick hair/hats, `installLawyer` / `installClient` keep the old
  model (`RetiredSkinModels.<Id>_preBrick`, `RetiredClients.<Id>_v3`).
- **Studs:** Roblox's SurfaceType.Studs are 1 stud wide, so a 2-stud head got two big cheek studs ("eye bags").
  Fixed with a MaterialVariant `MaterialService.BrickStuds` (normal map `art/materials/stud_normal.png` from
  `tools/stud_normal.py`, asset 90354792169791, StudsPerTile 0.5): finer studs, nothing added per part.
- **Built + installed:** Rookie Lawyer (`tools/brick/Rookie.lua`, 40 parts) and Neighbor Dave
  (`tools/brick/NeighborDave.lua`, 66 parts). Playtested: Rookie works at Desk 2 (equipped via PlaceLawyer), Dave
  arrived, walked in and sat at Desk 1 at the right height; the Lawyers panel draws the new Rookie; 0 warnings or
  errors on client and server.
- **Renamed** (display names only, Ids are saved data): IShowSued → Livestream Litigator, Kai Sue-nat → Selfie
  Counsel, Khaby Claim → Obvious Advocate, Benson Bond → Mic Drop Attorney. Studio's Config was patched in place
  (it's still pre-economy-pass, so the repo file wasn't pushed whole).
- **Not checked:** Dave's walk cycle frame by frame (only that he got from the door to the chair), the hatch screen
  with a brick lawyer, the courtroom with a brick client.

## 2026-10-11 — local session: EQUIP BEST, merging only at the Merger
- **EQUIP BEST** (user's ask): the gold button in the LAWYERS panel's EQUIP tab, where MERGE was. Server:
  `LawyerService.equipBest`, reached as `Remotes.PlaceLawyer("best")` (no new Remote). Strongest lawyers
  (`Formulas.lawyerEarn`, then skill levels) go into the free offices, strongest in the highest-level office.
  Lawyers on a case stay; a stronger bench lawyer is queued to replace the weakest busy ones after the case
  (the existing queue). Equal-strength lawyers keep their seat, so a second press changes nothing.
- **No merging in the LAWYERS panel** (user: "players should go to the merge machine"). MERGE button and its
  `Remotes.MergeLawyers` call removed. The "3x" tag stays; tapping such a lawyer says "Merge them at the Lawyer
  Merger". The hatch screen's "MERGE 3!" button is now always "MY LAWYERS"; the inventory-full toast points
  at the Merger. `Remotes.MergeLawyers` still exists server-side but no client calls it.
- **Studio:** `Lawyers` and `Eggs` pushed whole. `LawyerService` was PATCHED (equipBest + the PlaceLawyer
  router only), because Studio's copy is still pre-economy-pass (no TrainLawyer "all"/"max").
- **Tested in a playtest** (68 lawyers, 18 offices, most busy): EQUIP BEST filled the 5 empty offices
  strongest-first and queued x4 lawyers for the two x2 offices on a case. One of those cases ended during the
  test and the swap happened. A second press made no changes. The merge hint shows. No errors.
- **Not tested:** the hatch screen's new wording (it needs a hatch with no empty office).

## 2026-10-11 — local session: client remodel v3, less shine, UI restyle continues
**Clients.** All 44 clients rebuilt (`tools/clients/`): `ClientKit.lua` builds R6-proportioned characters from
CSG-rounded blocks (Union/Subtract at build time), layered clothing (collars, lapels, ties, belts, aprons, coat
tails, pockets, boots), 12 hair styles, caps/beanies/brim hats/top hats/chef hats/crowns, and a drawn face decal per
character (`tools/client_faces.py` -> `art/client_faces/`, 44 expressions; ids in `tools/clients/FaceIds.lua`).
`NeighborDave.lua` is the benchmark; `Cast.lua` has the other 43, each with its own prop (spatula, STOP sign,
tuba, parrot, trident...). `InstallClients.lua` reinstalls them all; old models in `ServerStorage.RetiredClients
.<Id>_v2`. Puppet part names unchanged, so walking / desks / courtroom work as before (verified in a playtest; no
console errors; `ReplicatedStorage.ClientModels` has all 44).
**Less shine** (user: "everything is a little too shiny"): `tools/shop_icons.py` SHINE = 0.3, all 17 icons
re-rendered + re-uploaded (new ids in `Shared.ArtAssets`); `Skin` button gloss / header bands / card glow toned down.
**UI.** LAWYERS panel and Manager Office moved onto the `Skin` look (glossy colour header + icon + red X, dark
studded body, Skin buttons whose gradient multiplies their own colour so state recolouring still works). Checked
in a playtest with live data.
Later the same day (user: "some of the clients with the hat on, the top of their head protrudes through the hat"):
`Kit:hatCrown` (head-fitting crown + low dome) for caps / beanie / helmet / headscarf, wider brim-hat crowns, a
velvet cap inside the King's crown; all 44 reinstalled. Then the rest of the UI ("continue with the ui"):
- HUD menu (`Shared.HudMenu`): wide reference-style buttons (icon poking out left, big outlined label) instead of
  square tiles; badge / "!" / timer pill kept.
- Daily Rewards calendar + reward pop-up, Skills, Merger header, Goals header, Courtroom: all on the `Skin` look.
- Layering: modal windows at DisplayOrder 32 (Skills 33, opens from LAWYERS), Daily / reward pop-ups 40, so the
  BigCase "BIG CASES INCOMING" banner (30) no longer draws over them.
Checked in playtests: Daily opens + X closes, LAWYERS Equip tab, Manager with live costs, Skills with live skills,
Courtroom answer -> OBJECTION + result line. Supreme screen not touched in Studio (part of the unpushed economy work).
Left: the egg hatch screen (cinematic, own look) and the in-world egg models.

## 2026-10-10 — local session: lawyer model remakes, UI design system, Blender shop + egg art
**Lawyer models.** All 52 hatchable lawyers rebuilt in the block style with their own shapes (was one shared
2.1 x 5.5 x 1.1 frame). Builders: `tools/skins/<Id>.lua` on `tools/skins/SkinKit.lua`; `tools/skins/InstallAll.lua`
reinstalls them all. Legendaries are 1.15-1.45x with gold/Neon trims; Rares get small Neon accents; Commons stay
simple. Lawyers no longer animate: they float + bob (DeskLife), win = a hop. Models may set `Hover` (SkinLook lifts
them) and `Sideways` (Puppet). Old models: `ServerStorage.RetiredSkinModels`. Generic, no-likeness versions of the
real-person parodies (IShowSued, KaiSueNat, KhabyClaim, BensonBond).
**UI.** New design system `Shared.Skin` (`src/Skin.lua`) after the user's reference recording (an egg-sim Shop):
glossy colour header + red X, dark studded window, dim backdrop (click to close), sunburst cards, chunky buttons with
squish/hover, ribbons, a shortcut dock. Skin windows opt out of the old `UISkin` auto-skin (`NoSkin`).
`Shop.client.lua` rebuilt on it (Featured / Game Passes / Cash / Eggs sections, dock shortcuts). Verified in a
playtest: open, scroll, shortcuts, X, click-outside close, Robux glyph. Purchases not testable (all Shop Ids are 0).
**Blender art.** `tools/shop_icons.py` models, lights (3-point + studio world) and renders 17 icons headless in
Cycles with an ink sticker outline: 7 eggs (Briefcase, Brainrot, Pet, Food, Ocean, Space, Rare), 8 shop items,
2 dock icons. PNGs + .blend scenes in `art/shop_icons/`; uploaded; ids in `Shared.ArtAssets` (`src/ArtAssets.lua`).
Used by the Shop cards + dock, the six egg-machine odds boards (egg picture on the left; also fixed "58.0%"), and
the Daily calendar's egg days. `tools/icon_sheet.py` makes a contact sheet.
Left: the in-world eggs are still the voxel models (the renders are smoother) - remake them only if the user
wants; the LAWYERS panel and the other screens are not on `Skin` yet.

## 2026-10-09 — local session: performance pass ("just optimize the game")
Measured first (playtest, client + server Stats): server heartbeat 0.08 ms, physics 0.12 ms, 22 moving parts, ~13
attribute changes/s, ~2 KB/s -> the server and network are fine. A full Puppet pose is 0.012 ms of Lua (BulkMoveTo
measured no faster), and the shell templates are already greedy-merged (769 -> 767), so neither was worth changing.
The ~66 ms client frames in Studio were Studio throttling its unfocused window (render stats read 0).
What was changed:
- **CanTouch off** on 6,181 static map parts + 7,226 template parts (ServerStorage/ReplicatedStorage). Only
  Dev.DevCoinPickup uses Touched (left alone); there are no Seats. Touch detection was running on ~6k parts for nothing.
- **Lighting**: 7 Sky objects -> 1 (Roblox picks an undefined one when there are several; kept the cartoon-cloud
  sky that renders today, checked by screenshot with only it present).
- **EffectsLod** (new LocalScript, `src/EffectsLod.client.lua`): continuous particle emitters > 150 studs from the
  camera pause, resume inside 130. Tested: at the firm 86 far emitters paused, 0 far ones running, every near one
  on; at the egg machine all 10 near ones on.
- **DeskProgress**: was a recursive FindFirstChild into every client on every firm, every frame -> cached per desk,
  only visible bars updated. Verified bars fill (0.92 -> 0.97 over 1.5 s).
- **LawyerTags**: tags past their MaxDistance (not drawn) no longer get size/gradient writes every frame.
- **DeskLife**: off-screen lawyers aren't re-posed (on-screen + 220 px margin, as before within 110 studs).
- **Hud** hints 5x/s, **Rewards** timers 4x/s, **Courtroom** attend-office pick 4x/s (all were every frame).
- Gotcha for testing: when the Studio window isn't focused, RenderStepped stops - per-frame UI looks frozen.
- **Biggest find: `Workspace.PREVIEW_Stage1..6`** (firm-stage preview builds "Dingy Shack" .. "Supreme Tower",
  attrs Stage/StageName/Segments): ~9,100 instances (8,400 parts, all visible, some collidable) that every player
  loaded, sitting ON the real plots (Stage1 overlapped Plot1's firm). No script references them; not ours (probably
  mr.robe's WIP). **Moved, untouched, to `ServerStorage.StagePreviews_MovedFromWorkspace`** (folder has a Note
  attribute) - drag back if they're needed in Workspace. Client workspace instances 19,953 -> ~10,900.
- Exploit audit (all 26 remotes): every one has a server handler except EquipSkin / SellSkins (retired skin
  inventory - unanswered, harmless). Spot-read Rewards (activity can't speed playtime; daily is per UTC day), Skills
  (throttle, pay before roll), Court (type checks, one answer, server deadline) - nothing to fix.
- Save system reviewed: session lock, UpdateAsync, retries with backoff, 60 s autosave, BindToClose - fine.
- Workspace also holds 4 inert post effects (Bloom / Blur / ColorCorrection / SunRays) - effects only work in
  Lighting or a Camera; the live ones are in Lighting. Harmless, left alone.

## 2026-10-09 — local session: HUD / UI pass ("the ui is cooked") + real PNG icons
- **Why it looked broken**: (1) UIKit's icon sprite sheet `rbxassetid://76384361895353` belongs to another account
  and isn't shared with this experience ("doesn't have access permission" in the output) -> every UIKit icon was
  blank: close buttons were empty red circles, the DAILY tile's title had been swapped for a gift that never loaded.
  (2) DAILY / LAWYERS / SHOP were placed by three scripts with different GUI insets -> they piled on top of each
  other. (3) UIKit painted everything navy, clashing with the purple studded Shop / Merger / LAWYERS panels.
- **New `ReplicatedStorage.Shared.HudMenu`** (`src/HudMenu.lua`): one left-edge column (UIListLayout, scales with
  screen height) that builds every menu tile the same way - gradient + studs, real PNG icon, LuckiestGuy label,
  red count badge, yellow "!" alert, optional timer pill. DAILY (Rewards), LAWYERS (Lawyers), SHOP (Shop) use it;
  Skills sets the LAWYERS "!" through it. Also holds `HudMenu.Icons`, the game's icon set.
- **Icons** (user: "find pngs online"): free Creator Store images, decal ids resolved to image ids with
  InsertService: gavel, shop stall, cart, gift (x2), coin stack, money bag, target (goals), star, trophy, scales.
  Skipped a "Coin From PSX" (ripped from Pet Sim X) and stock-photo uploads. Emojis gone from the HUD / Merger.
- **UIKit retheme** (`src/UIKit.lua`): icons from HudMenu.Icons (a glyph with no image keeps its text), panels dark
  studded purple instead of navy checker, close buttons a red tile with a real LuckiestGuy "X". Rewards calendar,
  Skills, Manager, hint banner etc. all follow automatically.
- **Coin counter** (Hud): coin-stack image, dark purple pill with a gold rim, big outlined money. **Goals card**: dark
  studded panel, purple header with the target icon, green bars on dark tracks.
- Screenshot-checked in a playtest: HUD, Daily calendar, Skills panel. Not yet eye-checked: Manager panel, BigCase,
  Courtroom overlay under the new UIKit colours.

## 2026-10-09 — local session: LAWYERS panel shows real 3D lawyers; EQUIP / UNEQUIP wording
- **3D lawyers everywhere in the panel** (user: "not a 2D cutout"): office cards, EQUIP-tab cards and the big preview
  now show each lawyer's real rigged model (`ReplicatedStorage.SkinModels`, posed by `SkinLook.dress` on an
  invisible stand-in body, so it works even when the firm is streamed out). One posed master per lawyer id, cloned
  into each ViewportFrame. Cards are now persistent (keyed by office / uid): a model is built once and only text,
  outlines and pills update, so office state changes don't rebuild ~60 viewports. Tested: 67 viewports kept across
  10 office state changes; frame time identical with the panel open or closed. The drawn icon is only a fallback.
- **Wording** (user: easier for kids): seat / unseat / place / bench -> EQUIP / UNEQUIP. Buttons UNEQUIP,
  UNEQUIP AFTER CASE, EQUIP LAWYER, EQUIP IN OFFICE N, EQUIP AFTER THIS CASE; tab EQUIP (n); pill UNEQUIPS AFTER
  CASE / SWAPS AFTER CASE; server messages "... gets (un)equipped after this case"; HUD hints; the empty office's
  world prompt now says "Equip Lawyer" (`FirmBuilder`; the prompt is still named `PlacePrompt`). Screenshot-checked.

## 2026-10-09 — local session: lawyer management overhaul (unseat fix + one LAWYERS panel)
User spec: lawyers could never be unseated ("busy with a case" forever), and the lawyer UI + the bottom office card
were confusing. Wanted: a slots bar, client assigning inside the Lawyer tab, clear statuses, working unseat/replace.
- **Root cause**: nothing ever let a lawyer be free long enough. `CaseService.autoAssign` re-booked any Idle lawyer
  within a tick (Manager every 0.8 s; without a Manager, any client seated 12 s self-assigns), a Mistrial re-runs the
  same case, and `PlaceLawyer` simply refused while busy. So "wait until the case is finished" never had a window.
- **Fix (server)**: (1) lawyer changes on a busy office are QUEUED: `PlaceLawyer(office, nil)` -> "leaves after this
  case", `PlaceLawyer(office, benchUid)` -> "takes over after this case" (swapping in a lawyer from ANOTHER office
  still needs both free - clear message). `CaseService.releaseDesk` applies the queued change the instant the case
  ends (after the payout), before anything can book the lawyer again; re-validated (`LawyerService.applyQueued`).
  New `Remotes.CancelLawyerChange`. A queued office skips Mistrial re-runs (client leaves; mistrials pay 0 anyway).
  (2) `Config.Case.RestAfterCase = 5`: after every case, and when a lawyer is newly placed, auto-assign (Manager and
  self-assign) leaves the office alone for 5 s; manual assigning works immediately. (3) Live office state is mirrored
  on the PLAYER (`Desk<N>Phase/CaseStart/CaseEnd/ClientName/ClientTier/RestUntil/Queued`, `WaitingClients` JSON),
  so the panel works anywhere (desk models stream out at the hub).
- **UI (`StarterPlayerScripts.Lawyers`, rewritten)**: Shop/Merger style. Top: YOUR OFFICES slot bar (lawyer, status
  pill FREE / ON A CASE m:ss with progress / CLIENT ARRIVING / LEAVING or SWAP AFTER CASE / EMPTY, skills "!").
  Left: selected office (3D lawyer, rarity, Earns xN, live status, UPGRADE OFFICE, SKILLS, UNSEAT / UNSEAT AFTER
  CASE / CANCEL CHANGE). Right: CLIENTS tab (waiting room, win % for this office, ASSIGN; info bar says why an office
  can't take one + which are free) and BENCH tab (all lawyers, PUT IN / SWAP INTO / REPLACE AFTER THIS CASE, MERGE).
  Assigning still closes the panel (earlier user call). Feedback pill for every refusal.
- **Removed**: the HUD's bottom office card (`Hud.LawyerPanel`: < >, UPGRADE OFFICE, SWAP LAWYER, SKILLS) - mr.robe's
  Hud script, user asked for it; hints now say "Open LAWYERS". The old AssignPicker panel: the [E] Assign Client
  prompt now opens the LAWYERS panel on CLIENTS with that client highlighted and the best free office selected.
  `Skills` opens via the new local `ReplicatedStorage.SkillsUI` bindable (its "!" moved onto the LAWYERS button);
  `Courtroom`'s ATTEND COURT button moved down and now finds any office with a case to attend.
- **Tested in a playtest** (real remotes, real UI clicks): ASSIGN click -> client walks to that office, panel closes;
  UNSEAT AFTER CASE -> purple LEAVING pill -> case finished (Win +18K paid) -> lawyer on bench, office Empty; Bench ->
  PUT IN OFFICE 4 works; REPLACE AFTER THIS CASE -> Settlement +29.9K paid -> new lawyer in, old one benched; office
  stayed Idle the whole 5 s rest with 10 clients waiting; manual assign during rest -> true; second full replace
  cycle (Win +187.5K) also correct; queue/cancel/garbage-input refusals return clear messages. Phone scale (0.585)
  screenshot: fits, buttons readable.
- **Not verified**: the Mistrial + queued path (couldn't force a mistrial); a UI ASSIGN click inside the 5 s rest
  window (tool latency is longer than the window - verified with the same remote instead).

## 2026-10-09 — local session: Robux Shop, Lawyer Merger machine, egg particle fix
User spec: a Shop (Robux passes + products, real MarketplaceService), a Lawyer Merger (reference: "Fuse Machine"),
and fix egg particles stuck in the middle of the map. References: "Steal an Egg" Trail Shop / Fuse Machine.
- **Egg particles - root cause**: the Eggs client script bobbed each machine egg with `PivotTo(home * ...)`,
  reading `home = egg:GetPivot()` ONCE at startup. Players spawn at their firm, far from the hub, so with
  StreamingEnabled the egg (PrimaryPart = invisible Shell) hadn't streamed in -> home read as the map origin ->
  every frame, whatever had streamed in (Shell + FX_Shell / FX_Aura, which hold the emitters) was dragged to
  the middle of the map. Fix: EggServer publishes each egg's true pivot as attribute `Home` and sets the egg
  `ModelStreamingMode = Atomic`; the client bobs from `Home` only, and only once the egg's PrimaryPart exists.
  Tested (numbers - see below): moved egg -> fx follow (0.0 studs); second egg elsewhere keeps its own fx;
  destroyed egg leaves 0 emitters; 0 emitters near the map origin.
- **Shop**: `Config.Shop` (4 passes: 2x Cash, Lucky Eggs, Speedy Cases, Bigger Firm; 4 products: 10 min / 1 h /
  6 h of income, 3 Rare Eggs). **All Ids = 0 -> fill in from the Creator Dashboard** (cards say COMING SOON,
  nothing prompts or grants until then). `Server.ShopService`: passes via UserOwnsGamePassAsync on join +
  PromptGamePassPurchaseFinished(purchased); products ONLY via ProcessReceipt, deduped by PurchaseId in the new
  `PlayerData.Purchases` (schema v13 + migration) and saved (`PlayerData.saveNow`) before PurchaseGranted.
  Effects: CaseService (DoubleCash payout, SpeedyCases time), EggServer (LuckyEggs Rare/Legendary weights x2,
  BigFirm +100 storage). `StarterPlayerScripts.Shop`: purple striped studded panel, Passes / Boosts tabs,
  coloured studded cards with spinning 3D icons, dark perk banner, green price button (real price from
  GetProductInfo), "..." while prompting, OWNED ✓. SHOP button under LAWYERS in the HUD column. World:
  `Hub.ShopStall` (striped awning stall on Mr Blox's ShopSpot pad, ShopPrompt). UI textures: tools/ui_textures.py.
- **Lawyer Merger**: `Hub.MergeMachine` on MergeMachineSpot (blue machine, dome, pipes, "?" window that turns
  "!" + sign "N merges ready!" when you can merge). `StarterPlayerScripts.Merger`: Fuse-Machine layout - 3 slots
  with green + piped into a result window, "N Lawyers Left" / MERGE!, help card (3 small ≈ 1 big, OK!), a
  picker that groups lawyers by kind with copy counts and auto-fills the other slots, preview of the result
  (name, stars, Earns x old -> new), flash + burst reveal. Rule = the game's existing one (3 same lawyer + stars ->
  +1 star, Config.Lawyers). Server: `Remotes.MergeSelected` -> LawyerService.mergeSelected (validates count,
  distinct, owned, same id+stars, not max, not busy; no yields between check and consume; shares mergeInto()
  with the old MergeLawyers so skills / free rolls / office handling are identical).
- Streaming gotcha (both new UIs): the hub can stream in late or re-stream as NEW instances, so prompts are
  handled through ProximityPromptService.PromptTriggered by name, and the sign is looked up fresh.
- Verified: Shop opens, both tabs render, OWNED state; receipts via a Studio-only test hook through the real
  handler (grant, same receipt again = no double grant, unknown player / product -> NotProcessedYet); pass
  effect only from server ownership. Merger server via the real remote: 5 invalid requests rejected, valid
  merge consumed exactly 2 and starred the kept one, re-use rejected, concurrent duplicate rejected.
  NOT verified on screen: the Merger panel opening + its animation - the Studio window stopped rendering
  (0 render fps) mid-test, so prompts/screenshots couldn't run. Test data: 3 Brr Brr Patapim were added to the
  Studio test save and two test merges were made.

## 2026-10-09 — local session: reveal redesign - one continuous 3D stage
User: the reveal (spinning sunburst, slash ring, star, confetti, coin rain, little 2D preview box) looked
generic; wants a cohesive scene where the character is the star, rarity identity via lighting / composition /
timing, polished text, a continuous flow from the egg opening.
- All of those effects are REMOVED. `StarterPlayerScripts.Eggs` (full copy now in src/Eggs.client.lua) builds one
  scene in the full-screen egg viewport:
  - a blocky studded pedestal (map style: Plastic + Studs, stepped round slab, glowing trim band, Neon light
    pool) that the egg already sits on when it drops in;
  - at the burst: a controlled flash in the rarity light, the stage lights up (trim + pool + viewport
    Ambient/LightColor in the rarity colour, lit from the front-top-left), and the REAL lawyer (office-1 lawyer
    re-dressed in the new skin, like the desks) rises out of the light onto the pedestal - scale 0.25 -> overshoot
    -> settle - then idles via Shared.Puppet ("celebrate" for Rare+, "nod" otherwise) with a slow turn while
    the camera glides to a hero framing (character 36% of screen height, centred at 32%) and drifts in;
  - 2D light layers behind it: rarity-tinted backdrop gradient + vignette, a breathing soft spotlight, and for
    Rare+ a light shaft from above (stretched glow texture - a CanvasGroup version never rendered).
  - Legendary extra: camera impact on landing, brighter shaft, 10 slow gold motes, gold shimmer through the name.
  - Text below the character (never over it): name rises in (Back), rarity pill pops, earnings fade, NEW! stamps
    just past the end of the name, buttons slide up.
- Gotchas: the EggHatch ScreenGui uses GLOBAL ZIndex - layers are dim 1, backdrop 2, glow 3, shaft 4, 3D 5,
  text/buttons 6+ (buttons were hidden under the backdrop at z 1). Shell shards now fade in ~0.45 s so the rising
  lawyer reads clean.
- Verified in playtest: Legendary (Briefcase/Tralalero, Brainrot/Bombardiro), Rare (Space/Star Judge,
  Pet/Corgi Counsel); KEEP closes cleanly (viewport emptied, egg prompt back), no console errors.
  Not checked on screen: Common / Uncommon reveal, phone layout.

## 2026-10-09 — local session: hatch v3 - the egg physically splits open (Blender)
User: crack textures failed; remake in Blender so the shell really separates along its cracks, a glowing
interior in the rarity colour, then the lawyer reveal (reference: a pet-sim egg opening, screen recording).
- `tools/egg_shells.py` (Blender + numpy): each machine egg's Voxel parts (posted from Studio into
  tools/egg_data/<Machine>.json) are re-voxelized (0.42 studs) into a HOLLOW 2-layer shell - egg colours outside,
  pale lining inside - and fractured into 9 shards (bottom cup, 3 lower + 4 upper petals, top cap) by noisy
  Voronoi on the sphere of directions, so the seams are jagged and follow the voxel grid. Greedy-merged into
  ~500 boxes per egg. Per shard: outward dir, hinge pivot + axis (lower edge), crack order. Renders a preview
  strip (Models - Effects/egg_shell_preview_EggMachine.png) and writes src/HatchShells.lua
  -> ReplicatedStorage.Shared.HatchShells (generated; regenerate, don't hand-edit).
- `StarterPlayerScripts.Eggs` egg block replaced (copy: src/HatchEgg.lua). Values crack / open / glow drive
  shardPose() (same maths as shard_pose() in the tool): seams split one by one with real 0.16-stud gaps; the
  inner lining turns Neon in the rarity colour (Common = soft white) so every gap and inner edge glows; a Neon
  core + halo swell inside; petals fold out on their hinges, the cap lifts off, the camera rises to look in;
  then the pieces blow outward and the core flares into the existing reveal. Old crack decals/textures gone
  (the egg_crack_* assets are unused now). Full-screen viewport kept (no square).
- Sequence: drop/bounce -> 3-4 shake rounds (seams opening, light leaking) -> Rare+ fake-out (light dims to an
  ember) -> peel open with rumble -> burst. Measured: Uncommon 4.3 s, Rare 5.1 s, Legendary 6.5 s; EggServer's
  world burst synced.
- Verified in playtest: Briefcase/Legendary (gold), Ocean/Uncommon (green), Space/Rare - seams, glow, opening,
  reveal; no console errors.

## 2026-10-09 — local session: hatch v2 - no visible square, Blender-made animated cracks
User: the hatch was visibly confined to a square, and the cracks looked bad; wants seamless + natural, animated
cracks, made in Blender or Figma (whichever is better).
- **No square**: the egg ViewportFrame now covers the full screen (transparent background). The egg's on-screen
  size comes from the camera FOV (EGG_PX = 300 px x fit() at rest, any resolution), the camera aims low so the
  egg sits at 42% height (on the glow / rays). Nothing (egg, rumble, shards) can hit a frame edge any more.
  The heartbeat is now a camera "punch" (scaling a full-screen frame would bring edges back).
- **Cracks (Blender)**: `tools/egg_cracks.py` (numpy in Blender, picked over Figma because cracks need to be
  procedural and *grow* - Figma is static vector UI). Jagged eggshell fissures radiate from an impact point
  (+2 later impacts), branch once, taper, and stay inside an egg-shaped mask. Every segment has a birth time ->
  10 growth stages x 2 layers: `egg_crack_dark_XX` (fissure, tinted dark brown) + `egg_crack_glow_XX` (hot core
  + halo; cream, then the rarity colour on the last round). IDs in ASSET_IDS.md. v2 = bolder widths.
- **Applied**: a crack card on the egg's front face carries the two decals; the `crack` value tweens through
  the stages while each round shakes (85% by the last round, the rest during the final rumble); the glow
  breathes; decals fade in the burst flash. Egg sway reduced to 0.12 rad so the card stays flush. The old Neon
  stick cracks are gone.
- Gotcha (CLAUDE.md-worthy): a ViewportFrame skips parts with Transparency = 1, *including their decals* - the
  card is 0.99.
- Verified in playtest: Briefcase (Legendary, gold cracks) and Space (Rare, blue cracks) - cracks render and
  spread, no square, no console errors.

## 2026-10-09 — local session: suspenseful 3D egg hatch
User: "make the hatching animation super cool and use the 3D model of the eggs and make it suspenseful".
- `StarterPlayerScripts.Eggs`: the flat 2D egg is replaced by a copy of the real machine egg
  (Hub.<Machine>.Egg.Voxel, Briefcase or themed) in a ViewportFrame. Sequence: drop-in bounce -> 3 shake rounds
  (4 for Legendary), each harder/faster, camera creeping in, heartbeat pulse, room darkening, glow behind the egg
  flickering through rarity colours (last flicker = real rarity), glowing Neon cracks spreading -> Rare+ fake-out
  (dead still + dark) -> rumble + camera rush -> voxels shatter out at the camera -> existing reveal.
  Tap/click skips ahead. Measured burst: Common ~3.9 s, Rare ~5.0 s, Legendary ~6.8 s.
- `HatchCue` (client BindableEvent in ReplicatedStorage): "beat" per crack round, "burst" at the shatter.
  Sounds plays a rising ping per beat and the sting at the burst (was a fixed 2.1 s delay).
- EggServer world burst over the machine now waits 5.0 s (Rare) / 6.8 s (Legendary) to match.
- Verified with fake EggHatched results (Briefcase, Space, Ocean, Food, Brainrot, Pet): egg, cracks, glow,
  fake-out and reveal all render; no console errors. Not captured on screen: the shatter frame itself (it lasts
  under a second), and a real paid hatch / a Common run end-to-end.

## 2026-10-09 — local session: Tung Tung Sahur client removed
User: remove the client "Tung Tung Sahur" (clashed with the lawyer just renamed "Tung Tung Tung Sahur").
- `Config.ClientCharacters`: `TungTungSahur` entry deleted. The Rare pool is now 9 characters (Baron von Banana,
  Beep, Pirate Patches, Cowboy Cody, Zombie Zeke, Ninja Noodle, Knight Kevin, Mermaid Marina, Chuckles), all
  with their own ClientEvidence sets.
- `Config.Clients[3]` (Rare tier) fallback name "Tung Tung Sahur" -> "A mysterious stranger".
- `EvidenceCards` Rare fallback set rewritten without Tung Tung ("your client"); `ClientEvidence` header comment.
- Template model moved (not deleted) to `ServerStorage.RetiredClients.TungTungSahur`. docs/CLIENTS.md and
  docs/DESIGN.md marked. tools/clients*.py still build it (harmless).
- Verified in playtest: Config loads, Rare pool has no Tung Tung, no console errors.

## 2026-10-09 — local session: Pinstripe Partner fix + two renames
- **Bug** (user screenshot: the lawyer lay on the floor under its tag): `PinstripePartner` wears mr.robe's rig
  `SkinModels.LawyerSkin_Legendary`, the only skin with unanchored parts on 16 Motor6Ds (+ 8 Bones). Physics
  toppled it and it fought Shared.Puppet. `SkinLook.putOnModel` now, for every model skin: records each joint
  (Part0, Part1, C0, C1), destroys the joints, anchors every part (CanCollide off), then places each Part1 at
  Part0 * C0 * C1^-1 (8 passes down the tree). The rig's stored part CFrames are stale; its real pose lives in
  the joints (anchoring alone left it upside down in the floor). Bones kept for the skinned meshes. Other skins
  have no joints, so they're unaffected. Verified: upright at Desk 9, 0 unanchored parts, tag above the head.
- **Renames** (user's calls; ids/models unchanged so saves still work): `PinstripePartner` is now shown as
  "Tung Tung Tung Sahur"; `CappuccinoAvvocato` is now "Cappuccino Assassino". Verified on the name tags.
  Note: the Rare *client* "Tung Tung Sahur" (Config.Clients[3]) is a different character with a similar name.

## 2026-10-09 — local session: picker closes after one assignment
User: after assigning one client the picker stayed open and jumped to the next client; they want it to close so
the Manager (auto-assign) feels more rewarding.
- `AssignClients.send`: on success, `close()` (removed the "straight on to the next waiting client" step).
- Refresh loop: if the open client stops waiting (self-assign / left), close instead of retargeting another.
- Verified in playtest: E on Camper Cam -> BEST FREE LAWYER -> Camper Cam went to Desk1, picker closed, the
  other 4 waiting clients untouched. No console errors.

## 2026-10-09 — local session: [E] Assign Client proximity prompts
User spec: replace the bottom-of-screen ASSIGN CLIENT button with Roblox's built-in ProximityPrompt; keep the
existing assignment picker exactly as it is.
- `StarterPlayerScripts.AssignClients` (lives in Studio only): the HUD button + count badge are gone. Each of
  YOUR waiting clients (tag FirmClient, OwnerUserId = you) gets one client-side `ProximityPrompt` "AssignPrompt"
  on its HumanoidRootPart: ActionText "Assign Client", ObjectText = client's name, KeyCode E, HoldDuration 0,
  MaxActivationDistance 8, RequiresLineOfSight false (couch backs), Exclusivity OnePerButton (crowded sofas
  show only the nearest). Enabled only while `Waiting` and no Manager is hired; follows attribute changes.
  Triggered -> the existing `open(model)`, so the picker opens for that exact client (gold outline, lawyer
  cards, BEST FREE LAWYER) - picker code untouched.
  No duplicates: one prompt per model in a table, an old "AssignPrompt" is replaced, connections are cleaned up
  when the client's tag is removed / it leaves workspace; a 0.5 s safety net tracks late-replicated clients.
  Other players never get prompts for your clients (created locally, owner-checked).
- Hud tutorial step 1 now reads "Walk up to Dave and press E to Assign Client" (the Guide beam already points
  at the waiting client).
- Verified in playtest: prompts on my waiting clients only (enabled when seated, off while walking / once
  assigned); PromptShown "Barber Bob / Assign Client key=E"; pressing E opened "Assign Barber Bob" with the
  outline on that client. Could not click through an assignment (all 11 lawyers busy at the time), but that
  path (`send` -> Remotes.AssignClient) is unchanged. No console errors.
- Heads-up: the pre-Manager self-assign (12 s) can send a client off just as you walk up; the prompt then hides.

## 2026-10-09 — local session: client name tags
User: "give names to all of the clients too, using the same method you just did".
- `LawyerTags` now tags every client in every firm (walking in, on the waiting-room sofas, at a desk) with the
  same outlined style, compact: name (ClientName attribute) + one rich-text line "Rare · Pays x8" (tier rarity
  colour + Config.Clients[Tier].Multiplier). Shared `makeTag` builder so lawyers and clients always match.
- Clients are followed by events (Plots.DescendantAdded / AncestryChanged), not by desk, since they move from
  `WaitingClients` to a desk. Tags float above the case progress bar (CLIENT_GAP), are a bit smaller than lawyer
  tags, draw to 60 studs, and every other waiting client (WaitingId parity) sits higher so sofa neighbours
  don't collide.
- Fix for all tags: stud-sized tags got huge right next to the camera (BillboardGui.DistanceLowerLimit did not
  help with scale sizes), so inside NEAR_LIMIT = 22 studs the tag is resized each frame to keep its on-screen
  size, anchored at its bottom so it stays just above the head.
- Note: several clients can share a character (e.g. two "Barber Bob"s) - that's the tier pool, not a tag bug.
- Verified in playtest (waiting room close-up + firm), no console errors. CLAUDE.md rule updated (Manager only).

## 2026-10-09 — local session: lawyer name tags + case pop-ups
User spec (overhead UI for lawyers) + a "Steal a Brainrot" screenshot as the style reference. The user chose to
override the "no words over heads" rule **for lawyers only** (clients / Manager unchanged; CLAUDE.md updated).
- New client script `StarterPlayerScripts.LawyerTags` (copy in `src/LawyerTags.client.lua`):
  - **Name tag** on every lawyer in every firm: stacked outlined text, no panel — `Gold`/`Rainbow` merge tier
    (rainbow animated) · name (white, biggest) · rarity in its colour (Legendary has a sweeping gold shimmer) ·
    `Earns xN` in yellow (Formulas.lawyerEarn). BillboardGuis in PlayerGui, sized in studs (shrink with distance),
    MaxDistance 95, measured to float just above each skin's head. A 0.5 s firm scan (DeskLife pattern) builds,
    rebuilds on re-dress/merge (key = id|stars) and removes them — no duplicates.
  - **Case pop-up** from the real `CaseResult` remote (fired at case completion): "CASE WON!" + big green
    "+$250", pop in (Back scale + 0.18 s rise/fade-in) → 0.8 s hold → 0.7 s drift up + fade → destroyed.
    Orange SETTLED, blue MISTRIAL ("RETRYING"); same colours as the Hud coin floaters. Rapid results on one desk
    stack upward and alternate slightly sideways.
- Server: `CaseService.applyLawyer` now also sets desk attribute `LawyerStars` (for the tier line). Nothing else
  in gameplay changed.
- Verified in playtest: 11 tags on the firm, correct names/rarities/earn; stacked win + settled pop-ups over the
  right lawyers, no console errors. Note: `AlwaysOnTop` billboards never appear in Studio captures, so pop-ups
  use `AlwaysOnTop = false` (a wall can hide one).
- Not yet seen on screen: a Gold / Rainbow (merged) tag — no merged lawyer in the test save.

## 2026-10-09 — local session: VFX v2 (anime effects from 4 reference images)
User sent 4 reference images (ice crystal burst, fire tornado, dark-red star explosion, blue energy orb) and asked
for detailed VFX made in Blender to replace the old sparkles.
- **Blender textures** `tools/vfx_textures.py` (numpy, white+alpha, `ALPHA_GAMMA` boost): slash arc, slash ring,
  4-point star flare, smoky tendrils, spark needle, beam streak, ember, speck, ice crystal shard, and three 4x4
  flipbooks (ice shockwave, flame tongue, churning energy orb). Uploaded; ids in `Models - Effects/ASSET_IDS.md`.
- **Shared.Effects rewritten** (copy in `src/Effects.lua`):
  - Auras: Rare = ice (counter-spinning floor swirls, tilted slash rings round the body, slash flashes, crystals
    popping from the floor, light orbs, ice shockwave flipbook). Epic (had nothing before) = energy orb flipbook
    + spark spikes + motes + dark specks. Legendary = fire tornado (4 stacked spinning rings, flame flipbook,
    embers, star glints, light column). 2★ = gold star glints + dust + ring; 3★ = rainbow + rainbow energy.
  - Bursts: rare = ice; merge = energy; rainbow = energy + star burst; legendary = star burst (white-hot flare,
    dark-red ground tendrils, sparks, embers, shockwave) + fire rings + flames + coins; win/tier = gold star burst.
  - New `Effects.ambient(parent, theme, color, scale)` replaced every old plain sparkle emitter: Neon skins
    (SkinLook), the gold desk tier (DeskLook), the EXPAND FIRM sign (DeskService) and the 6 hub egg machines.
    The machines are themed (Briefcase/Pet star, Brainrot/Space energy, Food fire, Ocean ice) with a spinning
    ring, built by the dev tool `ServerStorage.EggMachineFx`. Pads 7/8 (mr.robe's coming-soon eggs) untouched.
  - `guiBurst` (reward pop-ups) and the hatch screen (Eggs) now use a star flare + spinning slash ring + star/slash
    twinkles.
- **Lessons** (now in CLAUDE.md): Studio's Automatic graphics level throttles particles until effects look
  missing, so test at Level 16-21. Additive sprites vanish on the yellow floor. Stacked bright bursts clip to
  white. Ambient emitters inside an opaque egg shell need Surface/Outward.
- Verified in playtest: every aura and burst kind on a test stage; the real firm (ice + fire auras on desks); egg
  machines; a real Space hatch (Common roll, no errors). **Not yet seen on screen:** the hatch screen's Rare /
  Legendary star flare, because no rare roll came up.
- Note: old v1 textures `dot` and `swirl` no longer load (moderated?). v2 doesn't use them.

## 2026-10-09 — local session: case results as small floating numbers
- Hud: the big result pop-up (WIN! / Settled! / Mistrial card + big-win sunburst) is gone. Every `CaseResult` now
  spawns a small labeled number right of the coin counter — "+1.50K WIN" green, "+820 SETTLED" orange,
  "MISTRIAL - case reruns" blue (bigger for Epic/Legendary clients). It fades in, drifts up and fades out (2.2 s);
  numbers stack like a feed (newest pushes older ones up, max 6), so busy firms never overlap. Coin pill still pulses.
- Tutorial: a legend strip under the STEP banner for the whole tutorial — "Case coins float up by your money:
  GREEN = WIN · ORANGE = SETTLED · BLUE = MISTRIAL" in those colours.
- Unchanged: the courtroom's own verdict banner, the in-world coin burst for big wins, reward pop-ups (daily gifts).
- Tested with a stream of 3 results/s (clean stack, colours right) and a reset tutorial (legend shows, readable).

## 2026-10-09 — local session: per-character court questions
- New `Server.ClientEvidence` (ModuleScript): an opponent + 3 evidence questions (first card right, server shuffles)
  for each of the 36 clients whose tier set in `Server.EvidenceCards` was written for someone else (Grandma Pearl,
  Skater Kev, Captain Barnacle, Dr. Fizz, Baron von Banana, Beep + the 30 new clients). Dave, Rosa, Tung Tung, the
  CEO and the 5 celebrities keep their tier sets (written for them).
- `CaseService.makeClientModel` sets attr `ClientId`; `CourtService.attend` uses `ClientEvidence[ClientId]`, falling
  back to `EvidenceCards[tier]`; the no-repeat history is keyed per set.
- Checked: all 45 ClientCharacters covered (36 own sets + 9 tier owners), every set 3 prompts × 3 cards. Playtest: real
  clients sent to court got their own case (Lemonade Lily vs Inspector Sourpuss, Camper Cam vs Mayor Marigold,
  Farmer Frank vs Pie Contest Judge Penny). Heads-up mr.robe (EvidenceCards is theirs; it's untouched).

## 2026-10-09 — local session: Pet / Food / Ocean / Space eggs + 30 more clients
- `tools/themed_cast.py` (Blender, on top of lawyers_v2.py): 32 themed lawyers (8 per egg: 2 C / 2 U / 2 R / 2 L)
  + 30 clients (10 Common, 9 Uncommon, 7 Rare, 4 Epic), exported to `tools/themed_parts.json` (adds a Glass flag).
  Built in Studio with the new dev module `ServerStorage.BlockCharacterBuilder` (compact rows, see its header):
  lawyers → `ReplicatedStorage.SkinModels`, clients → `ServerStorage.Templates.Clients` (+ invisible root).
- `Config.Eggs.Themed` replaces `Config.Eggs.Brainrot`: Brainrot ×3 (0/60/32/8), Pet ×2 (55/28/14/3), Food ×4
  (45/32/18/5), Ocean ×8 (35/35/22/8), Space ×16 (25/35/28/12); each has Machine, Color (hatch-screen egg), Tagline.
  Catalog: 32 lawyers added by a compact loop at the bottom of Config (Egg = theme; Legendary = Neon).
  `Formulas.themedEgg(id)`, `Formulas.themedEggPrice(id, opened)`; EggServer `onRoll(player, eggId)` for every
  machine, attrs `<Id>EggPrice`; client Eggs loops over all themed machines (bob, prompt, odds board).
- Machines: `Hub.PetEggMachine` Pad3, `FoodEggMachine` Pad4, `OceanEggMachine` Pad5, `SpaceEggMachine` Pad6 (clones of
  the Brainrot machine, recoloured, rotated around the plaza). mr.robe's Money / Gold / Diamond / Courtroom
  "Coming Soon" placeholders saved in `ServerStorage.ComingSoonEggs.Pad3_MoneyEgg`..`Pad6_CourtroomEgg`.
  Shadow (Pad7) and Lava (Pad8) placeholders untouched.
- `Config.ClientCharacters`: +30 (tiers 1-4). Odds boards now round "28.0%" → "28%".
- Tested: 3,000 rolls per egg — every pool only its own 8 (Briefcase 13), splits match the weights; every catalog
  Model and client template exists (53 lawyers, 45 clients); real E press at the Space Egg hatched UFO Counsel
  (hatch screen OK); no console errors.
- (fixed right after — see the next entry: per-character court questions)

## 2026-10-09 — local session: starter egg = Briefcase Egg
- The starter machine (`Hub.EggMachine`, Pad2) is now the **Briefcase Egg**: mr.robe's yellow/brown Briefcase egg
  voxels (from `ServerStorage.ComingSoonEggs.Pad1_BriefcaseEgg`, rotated Pad1→Pad2) replace the generic shell
  (backup: `ComingSoonEggs.EggMachine_GenericVoxel`); sign BRIEFCASE EGG, odds board "BRIEFCASE EGG ODDS", gold light,
  gold egg on the hatch screen, prompt "Hatch FREE Briefcase Egg!", tutorial step 4 "...hatch your FREE Briefcase
  Egg!". `Config.Eggs.Name = "Briefcase Egg"`. It still hatches the 13 regular lawyers, gives the free first egg
  and takes reward tokens — no gameplay change.
- Playtested: E at the machine hatched Khaby Claim (normal pool), no errors; screenshot checked.
- Remaining "Coming Soon" pads: Money, Gold, Diamond, Courtroom, Shadow, Lava (no egg decided yet).

## 2026-10-09 — local session: Brainrot Egg
- New machine `workspace.Hub.BrainrotEggMachine` on **Pad1** (a clone of EggMachine rotated 45° around the plaza,
  recoloured purple / lime / pink / cyan, sign BRAINROT EGG, own odds board). mr.robe's "Briefcase Egg - Coming
  Soon" placeholder from Pad1 is saved in `ServerStorage.ComingSoonEggs.Pad1_BriefcaseEgg` (dirt left in place).
- `Config.Eggs.Brainrot` { PriceMultiplier 3, Weights U/R/L 60/32/8 }; catalog skins tagged `Egg = "Brainrot"`
  (the 8 brainrot lawyers) only hatch there; `Formulas.rollSkinId(rng, rarity, egg)` filters by egg;
  `Formulas.brainrotEggPrice`. EggServer: `onRoll(player, brainrot)`; free egg + reward tokens only on the normal
  egg; shares Eggs.Opened and pity; payload `egg = "Brainrot"`; attr `BrainrotEggPrice`. Client Eggs: bob, prompt
  text, odds board, purple egg on the hatch screen.
- Playtested with a real E press at the machine: charged 3x, hatched Brr Brr Patapim, hatch screen fine, no errors.
  4,000 test rolls: brainrot pool = exactly the 8, normal pool = the other 13, split 61/31/8 %.
- Sim catalog back to the normal egg's pool (3/3/4/3); Brainrot Egg not modelled (worse power per coin).

## 2026-10-09 — local session: 8 brainrot lawyers (hatchable)
- `tools/lawyers_v2.py` BRAINROT (Blender, same block recipe, each in lawyer gear) → `ReplicatedStorage.SkinModels`
  (attr Brainrot) + `Config.SkinCatalog`:
  Uncommon: Chimpanzini Bananini, Boneca Ambalabu · Rare: Ballerina Cappuccina, Brr Brr Patapim, Lirilì Larilà ·
  Legendary (Neon): Tralalero Tralala, Bombardiro Crocodilo, Cappuccino Avvocato.
- Catalog per rarity is now 3 / 5 / 7 / 6 (rarity odds unchanged; each lawyer is rarer within its rarity, so
  merges come slower). Sim synced: 1T/s moves from ~1.3–1.5 h to ~1.6 h (pacing fix still open). 20 tests pass.
- Playtested: all 8 load in offices with feet on the floor, auras by rarity (Legendary 11 fx, Rare 6), the hatch
  preview viewport works, no errors. (Studio screenshots timed out this session; looks checked in Blender.)

## 2026-10-09 — local session: tutorial rewrite + first case always goes to court
- `Config.Tutorial`: `FirstCaseInCourt = true`, `CourtWait = 90`, `Steps = 5`.
- Server: CourtService allows court on the tutorial case and gives it a fixed question about Dave's actual ticket
  (parking in his own driveway; right card = the house deed). CaseService holds the tutorial verdict until the
  player has been to court (or CourtWait runs out; desk attr `AwaitingCourt`). The case is still a guaranteed win.
- Courtroom: opens by itself 1.2 s after Dave's case starts; gold coach banner "YOUR FIRST CASE GOES TO COURT!" /
  "It's a guaranteed win! Pick the right evidence for +15% bonus coins."; tutorial-specific lines for a wrong
  card / time-up ("...your first case is a guaranteed win!"); verdict tip "Tip: tap ATTEND COURT during any case
  for bonus coins!"; button reads GO TO COURT! on the tutorial case; court shows the real client's name/situation.
- HUD hint banner: RichText "STEP n/5" in gold, shrinks to fit (no more overflow). Steps:
  1 "Neighbor Dave needs a lawyer! Tap ASSIGN CLIENT" → "Nice! Dave is walking to your lawyer's office..."
  2 "Dave's case is going to COURT! Tap GO TO COURT" → "Your lawyer is wrapping up Dave's case..."
  3 "You won! Tap UPGRADE OFFICE: your first one is FREE"
  4 "Follow the green line and hatch your FREE egg!"
  5 "Walk to a glowing EMPTY OFFICE to place your new lawyer" → 7 s "TUTORIAL COMPLETE! Win cases, upgrade
  offices and hatch lawyers!". Guide beam now waits for step 3 before pointing at the egg. Case status shows the
  real client name; "1 client waiting" plural fixed; Manager hint "Walk to your firm's door and press F".
- Playtested end to end (both the right-card and time-up paths): court opened by itself, Dave won (1.5K, 1.72K
  with the bonus), every step showed in order, beam targets correct, no errors.
- NOTE: Studio disconnected right after testing — check the place was saved (these edits are Studio-only).

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

## 2026-10-16 — crnuch, local session: more SFX (in progress, NOT playtested)
- New `ReplicatedStorage.Shared.Sfx` (src/Sfx.lua): a catalogue of 29 licensed sounds (Roblox UI pack, Pro Sound
  Effects, APM). It has `play` (2D), `at` (3D) and `loop` (ambience).
- **Wired in Studio (live):**
  - Sounds.client:
    - a click on every GuiButton
    - egg-crack beats with rising pitch
    - a pop when the shell bursts
    - a fanfare for Mythic and Supreme
    - a stinger on level-ups
  - Skin.window: open and close sounds.
  - ArcadeClient.Kit: tick, tap, good, perfect, bad and thud swapped from the old ping and gavel.
  - Bosses: hit, boing, charge, land and grab.
  - BigCase: tap and wrong.
  - Zones: buy (cash register), upgrade and note.
  - Merger: gears at the machine, goodbye on a fizzle, a hit sting on success.
  - TravelFx:
    - charge pings now go out as a new "charge" cue, so egg cracks don't play during travel
    - a whoosh as you vanish
  - WorldLife: wave loops round the beach, gulls over the hub, the fountain splashing.
- **Still to do:**
  - playtest: check each id loads (TimeLength > 0) and the volumes sound right
  - re-export the snapshot
  - run `run_checks.py`
