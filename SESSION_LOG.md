# Session log

Newest first. Each entry: what changed, where, and what's left. Keep the **Open items** list current —
it is the to-do list for the next session. Move finished items into the dated entry that finished them.

## Open items
- [ ] Eye-check a merged lawyer's Gold / Rainbow tag line (LawyerTags).
- [ ] Eye-check the hatch screen's Rare/Legendary VFX (star flare + slash ring) on a real rare roll.
- [ ] Egg-machine floor rings sit under the pedestals. Raise `FxRing` in `ServerStorage.EggMachineFx` or drop it.
- [x] **Pre-Manager auto-assign** — DONE 2026-10-08 (`Case.SelfAssignAfter` 12 s). (review §3, confirmed): AFK players earn 0 and can never afford the Manager.
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
