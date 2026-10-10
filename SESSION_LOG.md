# Session log

Newest first. Each entry: what changed, where, and what's left. Keep the **Open items** list current —
it is the to-do list for the next session. Move finished items into the dated entry that finished them.

## Open items
- [ ] Lawyer panel at phone size: the smallest labels (office-card names, client situations) are tiny at 0.58 scale.
- [ ] Tell mr.robe: the Hud's bottom office card is gone (user's call) and CaseService/LawyerService changed (queued lawyer changes, rest window).
- [ ] **Fill in Config.Shop Ids** (4 passes, 4 products) from the Creator Dashboard; keep Price in sync.
- [ ] Eye-check the Lawyer Merger panel + merge animation in a playtest (window wasn't rendering during the build).
- [ ] Eye-check the 3D egg hatch end to end on a real hatch (shatter frame, Common timing, phone layout).
- [ ] Eye-check a merged lawyer's Gold / Rainbow tag line (LawyerTags).
- [ ] Eye-check the hatch screen's Rare/Legendary VFX (star flare + slash ring) on a real rare roll.
- [ ] Egg-machine floor rings sit under the pedestals. Raise `FxRing` in `ServerStorage.EggMachineFx` or drop it.
- [x] **Pre-Manager auto-assign** — DONE 2026-10-08 (`Case.SelfAssignAfter` 12 s). (review §3, confirmed): AFK players earn 0 and can never afford the Manager.
      Auto-assign a seated client to the best free lawyer after ~10–15 s (CaseService queue is ours).
- [ ] **Slow the economy ~10×** (review A/B/C): `Lawyer.TrainBase` 800 → ~10–12K **together with** new offices
      starting at the firm's lowest office level (`DeskService.upgradeFirm`), or expansions stall. Sim it first.
- [ ] **Upgrade ×10 / Max** in the LAWYERS panel (review §4) — `LawyerService` + `Lawyers`.
- [ ] **Egg tiers** (review §2): stretch the merge chase (first Rainbow at 6 min today). Do after the retune.
- [ ] Specialist skill targets 1 of 9 `Config.Clients` entries (review D) — heads-up to mr.robe.
- [ ] Port this repo's sim model into Studio's `Dev.EconomySim` (stale since v12) or retire it (review E).
- [ ] Late-game sink beyond office level 100: prestige into the sim, or new content (review B).
- [ ] Add a `Config` comment next to `Payout.Growth` / `Lawyer.TrainGrowth`: their ratio sets the whole curve.
- [ ] Update DESIGN.md's tutorial + rewards text for v12 (review §7).
- [ ] **Add the user's local files to this repo:** `references/`, `tools/firm_kit.py`, `tools/firm_pieces.py`,
      `tools/voxel_builder.py`, `tools/clients.py`, `ClientPalette.png`. Decide whether `.fbx` exports go in
      (they're big; maybe Git LFS) or stay local.
- [ ] Eye-check Manager / BigCase / Courtroom panels under the new UIKit colours (2026-10-09 UI pass).
- [ ] Publish the lawyer animations (Animation Editor → import .fbx → publish), play Idle at the desk and
      Objection on a win. `PinstripePartner`'s Idle/Walk/Objection are not published yet (user must do it).
- [ ] More hatchable lawyers: add entries to `Config.SkinCatalog` (now the lawyer catalog; ids are saved).
- [ ] Blender remake queue (docs/BLENDER_BRIEF.md): egg machine, palm, props, desk tiers, courtroom pieces.
- [ ] Enable Studio API access (Game Settings → Security) when ready to test saving.
- [ ] Resolve design-doc inconsistencies (listed in docs/ECONOMY.md → "Known inconsistencies").

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
