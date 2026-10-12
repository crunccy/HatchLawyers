--[[
[PRE-ALPHA] HATCH A LAWYER & GET RICH! - systems guide (v12 "hatch real lawyers")
Nothing here runs; it's documentation. Updated 2026-10-08 after the v11/v12 redesign.

HOW IT PLAYS NOW
	Clients walk into your firm and sit in the waiting room. You ASSIGN each one to a lawyer in an
	office (or the Manager does it once hired); the case runs, the server rolls Win / Settlement /
	Mistrial and pays out: office level sets the base, the lawyer multiplies it (rarity x merge stars),
	plus desk-tier, skill, Manager, court and prestige bonuses. Eggs hatch real LAWYERS (rising price,
	pity), you place them in offices, merge 3 copies for +1 star, train OFFICES with coins, and
	EXPAND FIRM for 2 more offices. Prestige ("Supreme Empire") resets for a permanent multiplier.

ALL TUNING lives in ReplicatedStorage.Shared.Config. Economy math is in Shared.Formulas (shared by
server, client and the simulator).
	After changing numbers run the v12 simulator and keep every "Pacing check" line OK:
		print(require(game.ServerScriptService.Dev.EconomySimV12).run())
	Targets (Config.Pacing): first PAID egg <= 1:00, first firm expansion 20-30 min, 1T/s in 10-20 h.
	Tuned 2026-10-08: TrainGrowth 1.37, Eggs.Price 1500, Firm.ExpandCosts[5] 7e7.
	(Dev.EconomySim is the legacy pre-v12 sim; ignore it.)

SERVER (ServerScriptService.Server; Main starts everything in order)
	PlayerData      save/load, session lock, autosave, migrations. SCHEMA_VERSION 12.
	                Add a MIGRATIONS entry and bump the version before adding saved fields.
	PlotService     plots; FirmBuilder assembles the building from the Blender kit (rebuild on expand).
	FirmBuilder     entrance -> waiting room -> office segments -> expansion lock -> back wall.
	CaseService     clients walking in, waiting, assignment (AssignClient / Manager auto-assign),
	                cases, outcomes, payouts.
	LawyerService   office training (TrainLawyer), PlaceLawyer, MergeLawyers, hatch() for EggServer.
	DeskService     EXPAND FIRM; DeskLook dresses offices by level tier.
	CourtService    courtroom: evidence question, OBJECTION! surprise events.
	EvidenceCards   courtroom questions, one set per Config.Clients entry (first card = right).
	SkillService    lawyer skills (RollSkill / ResolveSkill), on the lawyer in an office.
	RewardsService  daily streak, playtime gifts, offline earnings, incomePerMinute().
	GoalService     short-term goals; other services call GoalService.track(player, kind).
	LeaderboardService  the 4 hub boards (OrderedDataStores, best-ever scores; falls back to this server).
	ManagerService  the Manager (auto-assigns clients) and its 5 upgrades, Retainer payouts.
	PrestigeService "Supreme Empire" reset; hatched lawyers are kept.
	BadgeAwards     badges from Config.Badges (0 = off until ids are pasted in).
	BigCaseService  Big Case Belt (Config.BigCase): gold VIP clients ride the hub conveyor every 2.5 min;
	                grab one (prompt); grabs within 1.2 s of each other -> showdown minigame (Mash /
	                Snap / Gavel) for the prize, losers get a consolation. Needs Hub.BigCaseBelt with
	                BeltStart / BeltEnd marker parts; scrolls BigCaseBelt.Slats. Model: Blender,
	                belt_blender/make_bigcase_belt.py. Studio test hook: ServerStorage.BigCaseDev:Invoke(
	                "wave", seconds) or ("showdown", "Mash"|"Snap"|"Gavel").
	Eggs/EggServer  egg machine: hatches lawyers, tokens, pity, rising price.
	PlayerSpeedDouble  doubles walk speed.
	Dev/            EconomySim, RunEconomySim, DevCoinPickup (Studio-only 100M/100T coins behind your firm).

SHARED: Config, Formulas, SkinLook (dresses lawyers), Puppet (code animation), Effects (auras/bursts),
	UIFonts.

CLIENT (StarterPlayerScripts)
	Hud, AssignClients, Lawyers (panel + merge), Courtroom, Skills (also: click a lawyer/desk),
	Rewards (DAILY + pop-ups), Goals, Manager, Eggs, SkinInventory, DeskProgress, DeskLife +
	ClientWalk (animation), OwnerPrompts, Guide (tutorial line), Sounds, BigCase (belt + showdowns).

UI STYLE (2026-10-09; design: Figma file "Hatch a Lawyer – UI Kit")
	Shared.UIKit        the kit as code: chunky 3D buttons (gradient, gloss, lip, shine sweep, hover bounce/tilt,
	                    press squish, pulse on CLAIM/HIRE/PLACE/...), navy checker panels, coloured headers, rarity
	                    cards (fill = the card's outline colour), icons from one sprite sheet (UIKit.icon("Gavel")),
	                    popIn / burst helpers. Image assets: UIKit.Assets.
	UISkin (client)     applies UIKit to every ScreenGui automatically as things appear, so screen scripts keep
	                    building plain white panels / coloured buttons and get the new look for free. Opt a
	                    GuiObject (and its children) out with attribute NoSkin = true. EggHatch / Freecam skipped.
	                    Button text is mirrored into a child "UIKitText" label so it draws above the gloss.

KEY PLAYER ATTRIBUTES (server-mirrored; clients only read)
	Coins, Plot, DeskCount, FirmSegments, FirmTier, FirstCaseDone, FreeLevelUps, Lawyers (JSON),
	LawyersOwned, LawyerCount, Desk<N>Lawyer/LawyerUid/Stars/Level/Tier/Skills/PendingSkill/
	SkillRolls/FreeSkillRolls/CasesDone, FreeEgg, EggTokens, RareEggTokens, EggsOpened, EggPrice,
	EggPity, SkinsUnseen, DailyStreak, DailyLastDay, PlaytimeActive, CoinsPerMinute, Goals,
	ManagerHired, ManagerLevels, PrestigeLevel. SelectedDesk is set locally by the HUD.
Desk models: Phase ("Empty" | "Idle" | "Walking" | "Case"), ClientTier, CaseStart, CaseEnd, Tutorial,
	CourtDone, AwaitingCourt, OwnerUserId, LawyerId, LawyerLevel.

REMOTES (ReplicatedStorage.Remotes): Activity, AnswerEvidence, AssignClient, AttendCourt, BigCase, BuyManagerUpgrade, CaseResult, ClaimDaily, CourtEvent, EggHatched, EquipSkin, HireManager, MarkSkinsSeen, MergeLawyers, OpenLawyerPicker, PlaceLawyer, Prestige, ReactCourtEvent, ResolveSkill, RewardGranted, RollSkill, SellSkins, TrainLawyer, UpgradeDesk
HUB LAYOUT (revamp 2026-10-09; previous map kept in ServerStorage.MapBackup_PreRevamp)
	North -> south along one path (Hub.Paths), plots + street still enter the round plaza east/west.
	TOP     Hub.EggTerrace: front row (floor) Brainrot, Pet, EggMachine (starter, centre), Food, Ocean;
	        raised back tier (+3, steps) Space, Pad7/Pad8 (coming soon), EggPads.Pad9_Reserved (empty,
	        for the next egg). Machines face +Z (the plaza). Hub.Gates.EggGate.
	MIDDLE  the round plaza (Hub.Plaza). PLACEHOLDERS ONLY, built by Mr Blox:
	          Hub.ShopSpot          (NW)  ReservedFor = "Shop"
	          Hub.MergeMachineSpot  (NE)  ReservedFor = "MergeMachine" (replaces the UI merge later)
	        Each has an invisible Anchor part on the pad top (LookVector = the pad's front, facing the
	        plaza centre); delete the pad/sign when the real build goes in. Leaderboards: SW + SE quarters.
	BOTTOM  Hub.CaseTerrace: Hub.BigCaseBelt (treadmill + portals, belt along z = 128) and
	        Hub.SpecialSpots.SpecialSpot1/2 (ReservedFor = "SpecialItem"). Hub.Gates.BigCaseGate.
	Assets (gate arch, shop/merge/special pads, lamp post) were modelled in Blender and are rebuilt by
	ServerStorage.HubAssetLibrary: build(name, cframe, parent, labels).

KNOWN LOOSE ENDS
	* 3D-importer leftovers (Lawyer_Idle / _Walk / _Objection pose data, empty LawFirmKit) were moved
	  out of Workspace to ServerStorage.ImporterLeftovers (2026-10-08). Not used by scripts; delete
	  when nobody needs the poses.
	* Prestige was not playtested end-to-end after v12 (needs a fully expanded, fully staffed firm).

BEFORE LAUNCH
	1. DONE 2026-10-08: saving, rejoining, session lock (foreign / stale), v1->v12 migrations and
	   leaderboards tested with API access on. (Offline earnings not yet checked across a real rejoin.)
	2. Set max players to 8 (there are 8 plots).
	3. Run an 8-player local server test (Studio "Server & Clients", 8 clients).
	4. Create badges and paste their ids into Config.Badges (optional).
	5. Small private playtest; watch first payout, first egg, session length, quit points.

FIRM STAGES (Server.FirmStages builds, Server.FirmFeatures runs)
	Stage comes from firm size: Dingy Shack (start) -> Storefront Practice (5 areas) -> Main Street Firm (6)
	-> Glass Office (7) -> Corporate HQ (9) -> Supreme Tower (after any prestige). Offices stay on the
	ground floor so everyone can still see your lawyers from outside; the stage only changes the front
	building and the hall style.
	- ROOMS: green pads on the lawn sell the rooms the current building has (Config.FirmAreas). Bought
	  rooms are saved in data.Firm.Areas and keep their bonus after the firm outgrows them; prestige
	  resets them with the firm.
	- SHOWCASE: your best lawyers stand on the gallery pedestals behind the street windows.
	- HOLOGRAM: Corporate HQ / Supreme Tower roof shows your best lawyer, giant and spinning.
	- ELEVATOR: one call point per floor, each ride goes up a floor (top floor -> lobby).
	- EXEC LOUNGE: standing on the lounge carpet boosts payouts.
	- Stage-up: the front builds itself floor by floor + "FIRM UPGRADED!" banner (StarterPlayerScripts.FirmStageUp).
	Old buildings are kept in ServerStorage.Old_Firms (not used by any script).

HUB MINIGAMES (Server.MinigameService + StarterPlayerScripts.Minigames; tuning: Config.Minigames)
	Two solo, tap-only games on the pads beside the Big Case belt (Workspace.Hub.SpecialSpots, each with a
	Station model and a green PLAY button). No reading needed, made for young players.
	- GAVEL BONK (left pad): 20-second whack-a-mole. Bonk the robbers (+1), not the friendly judge (-3).
	  Pays 0.25-1.25 minutes of the player's own income depending on score (3 stars = full).
	- LUCKY BRIEFCASE (right pad): the cases open to show the star, shuffle, and the player picks one.
	  Star case = 1.5 minutes of income (or a free egg, 20%); the others pay 0.5 minutes. Nobody loses.
	- Cooldowns: 5 min / 6 min per player, saved (data.Minigames, schema v15). A board over each station
	  shows PLAY! or the time left. The server plans every round and checks every tap.
	- The old empty pads are kept in ServerStorage.Old_HubSpots.

EGG ZONES (Server.ZoneService + StarterPlayerScripts.Zones; tuning: Config.Zones; map: Workspace.Zones)
	The firm is the idle part, the zones the active part. Past the west end of the street:
	- BRIEFCASE BAY (zone 1, over the wooden bridge): law-office plaza on blue paving. Sells Briefcase eggs.
	- PET PARK (zone 2, through the License gate): dog park on lime grass. Sells Pet eggs.
	- Eggs keep popping up on each zone's spots; buy one (coins, same price as the old machine), it rides over
	  your head, carry it home and hatch it at one of the 2 INCUBATORS in your firm's lobby. A golden egg (6%)
	  costs 5x, rolls Rare/Legendary 4x as often and alerts the whole server. Carried eggs are saved.
	- LICENSE OFFICE (by the Briefcase Bay entrance): Law License (opens Pet Park; RESET BY PRESTIGE), Bigger Bag
	  (carry 1 / 3 / 5), Faster Shoes (speed 32 / 36 / 40). The gate also sells the License.
	- Hub teleport pads (just west of the plaza) go to any zone you're licensed for. The walk home is the point.
	- The free first egg and reward eggs (daily, Big Case, Shop, minigames) hatch at the incubator too.
	- The hub's Briefcase + Pet machines are archived in ServerStorage.Old_HubEggMachines; the other themed
	  machines still work on the hub until they get zones. The zone builder is ui_art/BuildZones (re-runnable).
	NO WAITING ROOM: clients walk from the street straight to a free lawyer (the Manager picks the best one);
	the lobby's chairs/tables/ropes are gone and the incubators stand there. The LAWYERS panel has no CLIENTS tab.
	Costs in Config.Zones are first guesses: re-run the economy sim before launch.
]]
return nil
