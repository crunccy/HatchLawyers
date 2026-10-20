--!strict
-- Every tunable number for Hatch Lawyers & Get Rich lives here.
-- Live server code and the economy simulator (ServerScriptService.Dev.EconomySim) both read it,
-- so tune here and re-run the sim. 7 lawyer rarities since 2026-10-12 (Common .. Legendary, Mythic, Supreme).

export type ClientTier = {
	Id: string,
	Name: string,
	Situation: string,
	Multiplier: number,
	Difficulty: number,
	Weight: number,
	Duration: number, -- seconds per case before buffs
}

export type SkinRarity = {
	Id: string,
	Weight: number,
	PayoutBonus: number, -- (old skin system, unused now)
	SellValue: number, -- (old skin system, unused now)
	Earn: number, -- a hatched lawyer of this rarity earns Earn x the base payout
	StartSkills: number, -- skills a freshly hatched lawyer of this rarity rolls
}

export type Skin = {
	Id: string,
	Name: string,
	Rarity: number, -- index into Config.Eggs.Skins
	Suit: Color3, -- torso and arms
	Pants: Color3,
	Tie: Color3,
	Hat: ("Cap" | "TopHat" | "Crown" | "Shades")?,
	HatColor: Color3?,
	Neon: boolean?, -- glowing tie and sparkles
	-- Model skins: name of a rigged model in ReplicatedStorage.SkinModels that replaces the whole
	-- lawyer. Suit/Pants/Tie/Head are then only used for the inventory icon.
	Model: string?,
	Head: Color3?, -- icon head color (defaults to skin tone)
	Egg: string?, -- which egg hatches it: nil = the Briefcase Egg, else the Id of one of Config.Eggs.Themed
}

-- Effect: "payout" | "caseTime" | "winChance" add to Formulas.combineBuffs (so Config.Caps apply);
-- "rareClients" boosts the spawn weight of non-Common clients; "specialist" is payout vs one client
-- tier, picked when the skill is first rolled (saved as the skill's Param).
export type SkillDef = {
	Id: string,
	Name: string,
	Rarity: number, -- index into Config.Eggs.Skins (same Common / Uncommon / Rare colours)
	Effect: "payout" | "caseTime" | "winChance" | "rareClients" | "specialist",
	PerLevel: number,
	Text: string, -- %d = percent at the current level; Specialist also gets %s = client name
}

export type DeskTier = {
	Name: string,
	Cost: number, -- (old desk purchases, unused now)
	PayoutBonus: number,
	MinLevel: number, -- the office reaches this look at this office level
}

local Config = {}

Config.Version = 1

Config.RarityColors = {
	Common = Color3.fromRGB(158, 158, 158),
	Uncommon = Color3.fromRGB(76, 175, 80),
	Rare = Color3.fromRGB(33, 150, 243),
	Epic = Color3.fromRGB(156, 39, 176),
	Legendary = Color3.fromRGB(255, 193, 7),
	Mythic = Color3.fromRGB(229, 57, 53),
	Supreme = Color3.fromRGB(255, 255, 255), -- rendered as a rainbow gradient in UI
}

-- Ordered lowest to highest rarity. Weight is relative spawn chance.
Config.Clients = {
	{
		Id = "Common",
		Name = "Your neighbor Dave",
		Situation = "Disputes a parking ticket",
		Multiplier = 1,
		Difficulty = 0,
		Weight = 70,
		Duration = 30,
	},
	{
		Id = "Uncommon",
		Name = "A local bakery owner",
		Situation = "Suing a supplier for a broken contract",
		Multiplier = 3,
		Difficulty = 10,
		Weight = 25,
		Duration = 60,
	},
	{
		Id = "Rare",
		Name = "A mysterious stranger", -- tier fallback name (was Tung Tung Sahur, removed by the user 2026-10-09)
		Situation = "Accused of property damage after a midnight rampage",
		Multiplier = 8,
		Difficulty = 25,
		Weight = 5,
		Duration = 120,
	},
	{
		Id = "Epic",
		Name = "A retired CEO",
		Situation = "Inheritance dispute with 12 family members",
		Multiplier = 20,
		Difficulty = 45,
		Weight = 1,
		Duration = 180,
	},
	-- Legendary: five fictional celebrities sharing the Legendary rarity, each rare on its own.
	{
		Id = "Legendary",
		Name = "Chef Mega",
		Situation = "Sued over a cooking contest people say was rigged",
		Multiplier = 50,
		Difficulty = 70,
		Weight = 0.06,
		Duration = 240,
	},
	{
		Id = "Legendary",
		Name = "Rocket Baron Rex",
		Situation = "Sued for launching a rocket over a pool party",
		Multiplier = 50,
		Difficulty = 70,
		Weight = 0.06,
		Duration = 240,
	},
	{
		Id = "Legendary",
		Name = "Milo Vex",
		Situation = "Breach of contract with a fashion label",
		Multiplier = 50,
		Difficulty = 70,
		Weight = 0.06,
		Duration = 240,
	},
	{
		Id = "Legendary",
		Name = "DJ Beatbox",
		Situation = "Copyright fight over a chart-topping song",
		Multiplier = 50,
		Difficulty = 70,
		Weight = 0.06,
		Duration = 240,
	},
	{
		Id = "Legendary",
		Name = "Kiki Glow",
		Situation = "Trademark battle over a sparkly beauty brand",
		Multiplier = 50,
		Difficulty = 70,
		Weight = 0.06,
		Duration = 240,
	},
} :: { ClientTier }

-- Payout = Base * Growth ^ SkillLevel * ClientMultiplier * BuffMultiplier * OutcomeFraction
Config.Payout = {
	Base = 1200, -- tuned for 8 starting lawyers fed by the waiting room (was 3000 with 1 lawyer)
	Growth = 1.25,
	SettlementMin = 0.4,
	SettlementMax = 0.6,
}

-- Win = clamp(Base + (Skill - Difficulty) * PerSkillPoint + bonus, Min, Max)
Config.Outcome = {
	BaseWinChance = 0.70,
	PerSkillPoint = 0.003,
	MinWinChance = 0.45,
	MaxWinChance = 0.95,
	SettlementShareOfNonWins = 0.70, -- the rest are mistrials (case requeues, no coins)
}

-- Law firm tiers. The tier is the number of lawyers the player has: every firm upgrade
-- (cost: Config.Desks.UnlockCosts) unlocks one more lawyer and swaps in a bigger building.
-- Template names a model in ServerStorage.Templates.Firms.
Config.Firms = {
	{ Name = "Dingy Shack", Template = "Firm1" },
	{ Name = "Classic Firm", Template = "Firm2" },
	{ Name = "Established Offices", Template = "Firm3" },
	{ Name = "Luxury Courthouse", Template = "Firm4" },
	{ Name = "Ultra-Modern Tower", Template = "Firm5" },
}

-- The firm building (assembled from the Blender kit by Server.FirmBuilder): entrance -> waiting room
-- -> office segments (2 lawyer slots each, one per wall) -> back wall. Players start with
-- StartSegments segments and StartLawyers lawyers; EXPAND FIRM buys segment N for ExpandCosts[N]
-- (the plot gets longer and 2 empty offices appear), then lawyers are hired into the empty offices
-- for Config.Desks.UnlockCosts[N]. Clients walk in every ClientInterval seconds while a waiting-room
-- seat is free and wait until the player (or the Manager) assigns them to a free lawyer.
Config.Firm = {
	StartSegments = 4, -- 8 offices; only office 1 starts with a lawyer (Config.Lawyers.StartId)
	MaxSegments = 10,
	StartLawyers = 8, -- clientInterval reference size (a firm of this many lawyers gets ClientInterval)
	-- [5] was 7e7: the first Supreme needs 10 offices (economy pass 2026-10-09)
	ExpandCosts = { [5] = 2e7, [6] = 6e8, [7] = 3e10, [8] = 1.5e12, [9] = 8e13, [10] = 4e15 },
	-- Seconds between clients walking in for a firm of StartLawyers lawyers. A bigger firm draws
	-- more clients: the gap shrinks in proportion to the lawyer count (never below MinInterval).
	ClientInterval = 3.5,
	MinInterval = 1,
	WalkSpeed = 11, -- studs per second
}

-- The client characters (ServerStorage.Templates.Clients, modelled in Blender). Tier = index into
-- Config.Clients (payout multiplier, difficulty, case length). Tiers 1-3: tools/clients_v2.py (meshes);
-- Epic (4) and the five Legendary celebrities (5-9, one tier each): tools/lawyers_v2.py (Parts). Bios: HatchLawyers/CLIENTS.md.
Config.ClientCharacters = {
	{ Id = "NeighborDave", Tier = 1, Name = "Neighbor Dave", Situation = "Ticketed for parking in his own driveway" },
	{ Id = "GrandmaPearl", Tier = 1, Name = "Grandma Pearl", Situation = "Caught going 4 mph over in the park" },
	{ Id = "SkaterKev", Tier = 1, Name = "Skater Kev", Situation = "Accused of scuffing the town statue" },
	{ Id = "RosaTheBaker", Tier = 2, Name = "Rosa the Baker", Situation = "Ordered 100 bags of flour, got 10" },
	{ Id = "CaptainBarnacle", Tier = 2, Name = "Captain Barnacle", Situation = "Feuding with a seagull over his fishing spot" },
	{ Id = "DrFizz", Tier = 2, Name = "Dr. Fizz", Situation = "His soda volcano slimed the science fair" },
	{ Id = "BaronVonBanana", Tier = 3, Name = "Baron von Banana", Situation = "Accused of buying every banana in town" },
	{ Id = "BeepBot", Tier = 3, Name = "B0-P \"Beep\"", Situation = "Delivered 300 pizzas to the wrong planet" },
	{ Id = "RetiredCEO", Tier = 4, Name = "A retired CEO", Situation = "Inheritance dispute with 12 family members" },
	{ Id = "ChefMega", Tier = 5, Name = "Chef Mega", Situation = "Sued over a cooking contest people say was rigged" },
	{ Id = "RocketBaronRex", Tier = 6, Name = "Rocket Baron Rex", Situation = "Sued for launching a rocket over a pool party" },
	{ Id = "MiloVex", Tier = 7, Name = "Milo Vex", Situation = "Breach of contract with a fashion label" },
	{ Id = "DJBeatbox", Tier = 8, Name = "DJ Beatbox", Situation = "Copyright fight over a chart-topping song" },
	{ Id = "KikiGlow", Tier = 9, Name = "Kiki Glow", Situation = "Trademark battle over a sparkly beauty brand" },
	-- 30 more (tools/themed_cast.py CLIENTS)
	{ Id = "MailCarrierMo", Tier = 1, Name = "Mail Carrier Mo", Situation = "Bitten by a very small, very angry dog" },
	{ Id = "LemonadeLily", Tier = 1, Name = "Lemonade Lily", Situation = "Her lemonade stand got shut down for 'too much lemon'" },
	{ Id = "GamerGabe", Tier = 1, Name = "Gamer Gabe", Situation = "Banned from the arcade for winning too much" },
	{ Id = "GardenerGus", Tier = 1, Name = "Gardener Gus", Situation = "His prize pumpkin rolled into the neighbor's pool" },
	{ Id = "IceCreamIvy", Tier = 1, Name = "Ice Cream Ivy", Situation = "Her truck's jingle is 'too catchy'" },
	{ Id = "BarberBob", Tier = 1, Name = "Barber Bob", Situation = "Gave a customer a haircut that was 'too stylish'" },
	{ Id = "CrossingGuardCarol", Tier = 1, Name = "Crossing Guard Carol", Situation = "Stopped traffic for a duck family. For 3 hours." },
	{ Id = "LibrarianLou", Tier = 1, Name = "Librarian Lou", Situation = "Charged a $9,000 late fee for one book" },
	{ Id = "CamperCam", Tier = 1, Name = "Camper Cam", Situation = "His tent blew into the mayor's garden" },
	{ Id = "YogaYasmin", Tier = 1, Name = "Yoga Yasmin", Situation = "A goat at goat yoga ate her mat" },
	{ Id = "FirefighterFaye", Tier = 2, Name = "Firefighter Faye", Situation = "Rescued a cat that did NOT want to be rescued" },
	{ Id = "MagicianMarvin", Tier = 2, Name = "Magician Marvin", Situation = "His rabbit disappeared and never came back" },
	{ Id = "FarmerFrank", Tier = 2, Name = "Farmer Frank", Situation = "His cow keeps winning the county pie contest" },
	{ Id = "NurseNina", Tier = 2, Name = "Nurse Nina", Situation = "Prescribed 'more naps' and her boss objected" },
	{ Id = "MechanicMax", Tier = 2, Name = "Mechanic Max", Situation = "Fixed a car so well it drives itself now" },
	{ Id = "ArtistAria", Tier = 2, Name = "Artist Aria", Situation = "Painted the mayor's portrait... upside down" },
	{ Id = "WrestlerRonda", Tier = 2, Name = "Wrestler Ronda", Situation = "Body-slammed a vending machine that stole her dollar" },
	{ Id = "PilotPaige", Tier = 2, Name = "Pilot Paige", Situation = "Landed on the wrong island (it was nicer)" },
	{ Id = "MusicianMoe", Tier = 2, Name = "Musician Moe", Situation = "Neighbors sued over 4am tuba practice" },
	{ Id = "PiratePatches", Tier = 3, Name = "Pirate Patches", Situation = "Buried treasure in a public park" },
	{ Id = "CowboyCody", Tier = 3, Name = "Cowboy Cody", Situation = "His horse got a speeding ticket" },
	{ Id = "ZombieZeke", Tier = 3, Name = "Zombie Zeke", Situation = "Showed up to work 'a little too undead'" },
	{ Id = "NinjaNoodle", Tier = 3, Name = "Ninja Noodle", Situation = "Was too sneaky at a surprise party" },
	{ Id = "KnightKevin", Tier = 3, Name = "Knight Kevin", Situation = "Jousted a shopping cart" },
	{ Id = "MermaidMarina", Tier = 3, Name = "Mermaid Marina", Situation = "Her concert flooded the town square" },
	{ Id = "ClownChuckles", Tier = 3, Name = "Chuckles the Clown", Situation = "Fit 40 people in one tiny car" },
	{ Id = "TechTed", Tier = 4, Name = "Tech Billionaire Ted", Situation = "His robot vacuums formed a union" },
	{ Id = "MovieStarMaya", Tier = 4, Name = "Movie Star Maya", Situation = "Her stunt double wants the credit" },
	{ Id = "KingReginald", Tier = 4, Name = "King Reginald", Situation = "His crown is stuck. Who's liable?" },
	{ Id = "AstronautAce", Tier = 4, Name = "Astronaut Ace", Situation = "Left a footprint on the moon without a permit" },
}

Config.Case = {
	ArrivalDelay = 3, -- seconds between a case ending and the next client sitting down
	-- Before the Manager is hired, a client left waiting this long walks to a free lawyer by themselves, so
	-- the firm keeps earning while the player is away (the Manager assigns instantly and picks the best
	-- lawyer). Not during the tutorial's first case.
	SelfAssignAfter = 12,
	-- After every case a lawyer rests this long: the Manager and self-assigning clients leave them alone, so the
	-- player can always catch them free to unseat or swap (manual assigning still works right away).
	RestAfterCase = 5,
	TutorialDuration = 10,
}

-- OFFICES level up with coins (the main coin sink): the level belongs to the office, not the lawyer,
-- so swapping a lawyer in keeps it. Going from level L to L+1 costs TrainBase * TrainGrowth ^ L.
-- (Kept under Config.Lawyer so older code/sim names still work.) Every office level also raises the
-- base payout (Config.Payout.Growth) and the win chance; Config.Desks.Tiers sets the office's look.
Config.Lawyer = {
	StartLevel = 1,
	MaxLevel = 100,
	TrainBase = 800,
	TrainGrowth = 1.37, -- v12 tune (EconomySimV12): 1T/s around 12-15 h
}

-- HATCHED LAWYERS. Eggs give real lawyers (one of Config.SkinCatalog, which is now the lawyer
-- catalog). A lawyer's power = rarity Earn (Config.Eggs.Skins) x StarEarn[stars]. MergeCount copies
-- of the same lawyer at the same stars merge into one with +1 star (up to #StarEarn). New players
-- start with one StartId lawyer in office 1; every other office starts empty.
-- MUTATIONS (2026-10-13, user's calls): merging became MUTATING. A lawyer's saved `Stars` (1-4) is its mutation tier:
-- 1 Normal, 2 Shiny, 3 Diamond, 4 Cosmic (old Gold lawyers are Shiny now, Rainbow ones Diamond - same power).
-- The Mutation Machine (the old Lawyer Merger) takes MergeCount copies of the same lawyer at the same tier and TRIES
-- to make one of the next tier: Mutations[next].Chance; if it fizzles, ALL of them are gone (user's call - the odds are
-- always shown first). A mutated lawyer is recoloured along its Ramp (Shared.MutationLook, previewed with
-- tools/blender/mutation_preview.py) instead of extra effects. Hatches can roll a mutation too (HatchMutation).
Config.Lawyers = {
	StartId = "Rookie",
	MergeCount = 3,
	StarEarn = { 1, 2.5, 6, 15 }, -- earn x by mutation tier (Normal, Shiny, Diamond, Cosmic)
	StarNames = { "", "Shiny", "Diamond", "Cosmic" },
	MaxOwned = 150, -- inventory cap (sell, mutate, or wait for space)
	Mutations = {
		-- [tier] = what reaching it takes and how it looks. Chance: the Mutation Machine's success chance from the tier
		-- below. Ramp: dark -> light colours the lawyer is recoloured along. Color: its name tag / UI colour.
		[2] = { Id = "Shiny", Chance = 0.7, Color = Color3.fromRGB(255, 200, 40),
			Ramp = { Color3.fromRGB(110, 62, 8), Color3.fromRGB(205, 135, 18), Color3.fromRGB(250, 188, 36), Color3.fromRGB(255, 222, 88), Color3.fromRGB(255, 248, 200) } },
		[3] = { Id = "Diamond", Chance = 0.45, Color = Color3.fromRGB(120, 210, 255),
			Ramp = { Color3.fromRGB(18, 40, 95), Color3.fromRGB(40, 110, 200), Color3.fromRGB(90, 180, 240), Color3.fromRGB(170, 230, 255), Color3.fromRGB(240, 252, 255) } },
		[4] = { Id = "Cosmic", Chance = 0.25, Color = Color3.fromRGB(190, 110, 255),
			Ramp = { Color3.fromRGB(18, 8, 40), Color3.fromRGB(70, 25, 130), Color3.fromRGB(140, 60, 220), Color3.fromRGB(210, 120, 255), Color3.fromRGB(255, 200, 250) } },
	},
	-- the chance a hatch comes out already mutated, by tier (2 Shiny, 3 Diamond, 4 Cosmic): a normal egg and a golden
	-- zone egg. Rolled on its own, after the rarity - the rarity odds (Supreme 1 in 2500) never change. First guesses.
	HatchMutation = {
		Normal = { [2] = 0.02, [3] = 0.003, [4] = 0.0002 },
		Golden = { [2] = 0.25, [3] = 0.03, [4] = 0.002 },
	},
	-- SELLING lawyers (LAWYERS panel): price = the lawyer's egg's current price (the player's own ramp) x Share[rarity]
	-- x the mutation's StarEarn. Never a lawyer in an office, a locked one, or your last one. ConfirmFrom: rarities from
	-- this index (Epic) ask "Are you sure?" first.
	Sell = {
		Share = { 0.1, 0.2, 0.4, 0.8, 1.5, 4, 10 }, -- Common .. Supreme (Config.Eggs.Skins order)
		ConfirmFrom = 4,
	},
}

Config.Desks = {
	MaxDesks = 20, -- Config.Firm.MaxSegments x 2 offices
	-- Cost to hire lawyer N into an empty office. The first Config.Firm.StartLawyers are free (start).
	UnlockCosts = { 0, 0, 0, 0, 0, 0, 0, 0, 2e6, 4e6, 8e7, 1.6e8, 4e9, 8e9, 2e11, 4e11, 1e13, 2e13, 5e14, 1e15 },
	-- The office's look + bonus, reached automatically by office level (no separate purchase).
	Tiers = {
		{ Name = "Basic Office", Cost = 0, PayoutBonus = 0, MinLevel = 1 },
		{ Name = "Oak Office", Cost = 0, PayoutBonus = 0.05, MinLevel = 10 },
		{ Name = "Executive Office", Cost = 0, PayoutBonus = 0.10, MinLevel = 30 },
		{ Name = "Partner's Suite", Cost = 0, PayoutBonus = 0.20, MinLevel = 60 },
	} :: { DeskTier },
}

-- Egg: 4 rarities (the design doc's 7-tier table, trimmed), no pity yet.
Config.Eggs = {
	-- The starter egg (workspace.Hub.EggMachine, Pad2): the Briefcase Egg. Hatches every catalog lawyer without
	-- an Egg tag (the 13 regular lawyers); gives the free tutorial egg and takes reward egg tokens.
	Name = "Briefcase Egg",
	Price = 1500, -- the first paid egg (= the tutorial case's payout, so it's affordable ~1 min in); each egg opened after that costs PriceGrowth x more
	PriceGrowth = 1.15,
	FreeFirstEgg = true,
	FirstEggRarity = 2, -- index into Skins: guaranteed Uncommon, does not touch pity
	-- Pity: after this many eggs in a row without the rarest skin, the next one is guaranteed it.
	-- Counts every egg except the free tutorial one (reward tokens count). Shown via EggPity.
	PityTop = 50,
	-- the rarity pity guarantees (index into Skins): Legendary. Mythic and Supreme are never guaranteed (Supreme
	-- stays 1 in 2500); rolling Legendary or better resets the count.
	PityRarity = 5,
	-- Economy pass 2026-10-09: the x PriceGrowth ramp counts eggs opened since your last Supreme (Eggs.RunOpened),
	-- and every Supreme level makes eggs PrestigePriceScale x pricier - eggs stay a real choice every run instead of
	-- costing a lifetime-count price right after a reset (Formulas.eggPrice).
	PrestigePriceScale = 3,
	-- Luck (Lucky Eggs pass, golden zone eggs): these rarities' chances are multiplied, paid for out of the LuckPaidBy
	-- rarities, so the total stays 100 and Mythic / Supreme keep their exact odds (Formulas.luckyWeights; Supreme stays
	-- exactly 1 in 2500 - before 2026-10-12 luck just multiplied, which pushed Supreme to ~1 in 3850 on a golden egg).
	LuckRarities = { "Rare", "Epic", "Legendary" },
	LuckPaidBy = { "Common", "Uncommon" },
	Skins = {
		-- The Briefcase Egg's odds (Weight, %); themed eggs have their own Weights by these indices.
		-- 2026-10-12: Epic (between Rare and Legendary), Mythic and Supreme (one and two past Legendary).
		-- Supreme is exactly 1 in 2500 (0.04 %) in EVERY egg; Mythic rises with the egg tier.
		-- Saves store lawyer Ids, never rarity numbers, so inserting Epic at 4 moved nothing saved.
		-- SellValue / PayoutBonus: the old skin system (unused).
		{ Id = "Common", Weight = 55.8, PayoutBonus = 0.01, SellValue = 750, Earn = 1, StartSkills = 1 },
		{ Id = "Uncommon", Weight = 26, PayoutBonus = 0.02, SellValue = 1500, Earn = 2, StartSkills = 1 },
		{ Id = "Rare", Weight = 11, PayoutBonus = 0.05, SellValue = 3750, Earn = 4, StartSkills = 2 },
		{ Id = "Epic", Weight = 4.5, PayoutBonus = 0.10, SellValue = 7500, Earn = 6, StartSkills = 2 },
		{ Id = "Legendary", Weight = 2.5, PayoutBonus = 0.20, SellValue = 15000, Earn = 10, StartSkills = 2 },
		{ Id = "Mythic", Weight = 0.16, PayoutBonus = 0.35, SellValue = 37500, Earn = 25, StartSkills = 3 },
		{ Id = "Supreme", Weight = 0.04, PayoutBonus = 0.50, SellValue = 150000, Earn = 60, StartSkills = 3 },
	} :: { SkinRarity },
	-- Themed eggs (workspace.Hub.<Machine>, on the plaza's egg pads): each hatches ONLY the catalog lawyers
	-- whose Egg = its Id, with its own rarity Weights (by rarity index), at PriceMultiplier x the Briefcase
	-- Egg's current price. They share the opened count (all prices climb together) and the pity counter, and
	-- are never free (the free egg and reward tokens are for the Briefcase Egg). Color = the hatch-screen egg.
	-- EGG TIERS (2026-10-12): each themed machine opens once the player has EARNED UnlockEarned coins in their
	-- lifetime (Stats.CoinsEarned - kept through Supremes, so an egg never locks again), and its lawyers earn
	-- EarnMultiplier x more (Formulas.lawyerEarn), so every new machine hatches stronger lawyers than the last.
	-- Opens (tools/economy_sim.py, 5 seeds): Pet 11-16 min, Brainrot 22-43 min, Food 64-96 min, Ocean 3.3-3.8 h, Space 7-8 h.
	Themed = {
		{ Id = "Brainrot", Name = "Brainrot Egg", Machine = "BrainrotEggMachine", PriceMultiplier = 3, UnlockEarned = 1e9, EarnMultiplier = 1.5, Weights = { 0, 54.6, 28, 9, 8, 0.36, 0.04 }, Color = Color3.fromRGB(165, 95, 255), Tagline = "Brainrot lawyers only!" },
		{ Id = "Pet", Name = "Pet Egg", Machine = "PetEggMachine", PriceMultiplier = 2, UnlockEarned = 1e7, EarnMultiplier = 1.25, Weights = { 52.7, 26, 12, 6, 3, 0.26, 0.04 }, Color = Color3.fromRGB(255, 180, 110), Tagline = "Pet lawyers only!" },
		{ Id = "Food", Name = "Food Egg", Machine = "FoodEggMachine", PriceMultiplier = 4, UnlockEarned = 1e11, EarnMultiplier = 2, Weights = { 42.5, 29, 16, 7, 5, 0.46, 0.04 }, Color = Color3.fromRGB(255, 120, 100), Tagline = "Food lawyers only!" },
		{ Id = "Ocean", Name = "Ocean Egg", Machine = "OceanEggMachine", PriceMultiplier = 8, UnlockEarned = 1e15, EarnMultiplier = 3, Weights = { 33.3, 32, 19, 7, 8, 0.66, 0.04 }, Color = Color3.fromRGB(60, 170, 230), Tagline = "Ocean lawyers only!" },
		{ Id = "Space", Name = "Space Egg", Machine = "SpaceEggMachine", PriceMultiplier = 16, UnlockEarned = 1e18, EarnMultiplier = 4, Weights = { 23, 32, 23, 9, 12, 0.96, 0.04 }, Color = Color3.fromRGB(110, 70, 220), Tagline = "Space lawyers only!" },
	},
}

-- Every skin an egg can hatch. An egg first rolls a rarity (Config.Eggs.Skins weights), then picks
-- evenly among the skins of that rarity. Add skins here; ids are saved, so never rename one.
-- Every lawyer has a block-style model in ReplicatedStorage.SkinModels (Model = ...); the first 7 are built by
-- HatchLawyers/tools/lawyers_v2.py. Suit/Pants/Tie/Hat only colour the old blocky fallback and UI swatches.
Config.SkinCatalog = {
	{
		Id = "Rookie", -- the starting lawyer (also hatchable)
		Name = "Rookie",
		Rarity = 1,
		Model = "Rookie",
		Suit = Color3.fromRGB(44, 62, 96),
		Pants = Color3.fromRGB(32, 32, 38),
		Tie = Color3.fromRGB(200, 40, 50),
	},
	{
		Id = "InternSuit",
		Name = "Intern Suit",
		Rarity = 1,
		Model = "InternSuit",
		Suit = Color3.fromRGB(170, 172, 186),
		Pants = Color3.fromRGB(70, 72, 86),
		Tie = Color3.fromRGB(80, 140, 255),
	},
	{
		Id = "CasualFriday",
		Name = "Casual Friday",
		Rarity = 1,
		Model = "CasualFriday",
		Suit = Color3.fromRGB(255, 140, 60),
		Pants = Color3.fromRGB(60, 90, 170),
		Tie = Color3.fromRGB(255, 220, 80),
		Hat = "Cap",
		HatColor = Color3.fromRGB(255, 80, 80),
	},
	{
		Id = "BowTieBarrister",
		Name = "Bow Tie Benny",
		Rarity = 2,
		Model = "BowTieBarrister",
		Suit = Color3.fromRGB(130, 70, 200),
		Pants = Color3.fromRGB(55, 35, 90),
		Tie = Color3.fromRGB(255, 80, 170),
		Hat = "TopHat",
		HatColor = Color3.fromRGB(45, 35, 60),
	},
	{
		Id = "NavyPowerSuit",
		Name = "Navy Power Suit",
		Rarity = 2,
		Model = "NavyPowerSuit",
		Suit = Color3.fromRGB(40, 75, 170),
		Pants = Color3.fromRGB(25, 35, 85),
		Tie = Color3.fromRGB(235, 45, 60),
		Hat = "Shades",
		HatColor = Color3.fromRGB(20, 20, 24),
	},
	{
		Id = "GoldenGavel",
		Name = "Golden Gavel",
		Rarity = 3,
		Model = "GoldenGavel",
		Suit = Color3.fromRGB(255, 200, 40),
		Pants = Color3.fromRGB(170, 115, 20),
		Tie = Color3.fromRGB(255, 255, 255),
		Hat = "Crown",
		HatColor = Color3.fromRGB(255, 215, 60),
		Neon = true,
	},
	{
		Id = "PinstripePartner", -- id kept (saves reference it); renamed by the user 2026-10-09
		Name = "Bonk Bonk Timber", -- (was "Tung Tung Tung Sahur", a real meme name: renamed 2026-10-13, user's call; id + model unchanged)
		Rarity = 5,
		Model = "TungTungSahur", -- block remake 2026-10-10 (mr.robe's mesh LawyerSkin_Legendary is kept in SkinModels)
		Suit = Color3.fromRGB(35, 45, 95),
		Pants = Color3.fromRGB(30, 38, 80),
		Tie = Color3.fromRGB(220, 40, 50),
		Head = Color3.fromRGB(235, 125, 40),
		Neon = true,
	},
	{
		Id = "NeonLitigator",
		Name = "Neon Nate",
		Rarity = 3,
		Model = "NeonLitigator",
		Suit = Color3.fromRGB(35, 35, 48),
		Pants = Color3.fromRGB(20, 20, 30),
		Tie = Color3.fromRGB(0, 255, 200),
		Hat = "Shades",
		HatColor = Color3.fromRGB(0, 255, 200),
		Neon = true,
	},
	-- Parody model skins (ReplicatedStorage.SkinModels)
	{
		Id = "IShowSued",
		Name = "Livestreamer", -- renamed 2026-10-11 (was a real-creator parody; Id kept: saved)
		Rarity = 5,
		Model = "IShowSued",
		Suit = Color3.fromRGB(200, 18, 40),
		Pants = Color3.fromRGB(30, 30, 34),
		Tie = Color3.fromRGB(20, 140, 70),
		Head = Color3.fromRGB(120, 78, 54),
		Neon = true,
	},
	{
		Id = "IceJustice",
		Name = "Ice Cold",
		Rarity = 5,
		Model = "IceJustice",
		Suit = Color3.fromRGB(170, 216, 245),
		Pants = Color3.fromRGB(240, 248, 255),
		Tie = Color3.fromRGB(200, 245, 255),
		Head = Color3.fromRGB(186, 128, 92),
		Neon = true,
	},
	{
		Id = "KaiSueNat",
		Name = "Selfie Star", -- renamed 2026-10-11 (was a real-creator parody; Id kept: saved)
		Rarity = 3,
		Model = "KaiSueNat",
		Suit = Color3.fromRGB(25, 25, 30),
		Pants = Color3.fromRGB(25, 25, 30),
		Tie = Color3.fromRGB(210, 30, 40),
		Head = Color3.fromRGB(116, 76, 52),
	},
	{
		Id = "KhabyClaim",
		Name = "Obvious Ollie", -- renamed 2026-10-11 (was a real-creator parody; Id kept: saved)
		Rarity = 3,
		Model = "KhabyClaim",
		Suit = Color3.fromRGB(120, 124, 132),
		Pants = Color3.fromRGB(60, 62, 70),
		Tie = Color3.fromRGB(30, 30, 34),
		Head = Color3.fromRGB(108, 70, 48),
	},
	{
		Id = "BensonBond",
		Name = "Mic Drop", -- renamed 2026-10-11 (was a real-creator parody; Id kept: saved)
		Rarity = 2,
		Model = "BensonBond",
		Suit = Color3.fromRGB(250, 248, 240),
		Pants = Color3.fromRGB(250, 248, 240),
		Tie = Color3.fromRGB(255, 205, 120),
		Head = Color3.fromRGB(240, 196, 168),
	},
	-- Brainrot lawyers (block-style parodies of the Italian-brainrot memes; tools/lawyers_v2.py BRAINROT).
	-- Egg = "Brainrot": only the Brainrot Egg hatches them.
	{
		Id = "ChimpanziniBananini",
		Name = "Chimpanzini Bananini",
		Rarity = 2,
		Model = "ChimpanziniBananini",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(255, 220, 60),
		Pants = Color3.fromRGB(255, 220, 60),
		Tie = Color3.fromRGB(200, 40, 50),
		Head = Color3.fromRGB(110, 70, 40),
	},
	{
		Id = "BonecaAmbalabu",
		Name = "Boneca Ambalabu",
		Rarity = 2,
		Model = "BonecaAmbalabu",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(32, 32, 36),
		Pants = Color3.fromRGB(60, 70, 140),
		Tie = Color3.fromRGB(220, 40, 50),
		Head = Color3.fromRGB(110, 190, 80),
	},
	{
		Id = "BallerinaCappuccina",
		Name = "Ballerina Cappuccina",
		Rarity = 3,
		Model = "BallerinaCappuccina",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(255, 110, 175),
		Pants = Color3.fromRGB(244, 206, 180),
		Tie = Color3.fromRGB(60, 40, 120),
		Head = Color3.fromRGB(250, 248, 244),
	},
	{
		Id = "BrrBrrPatapim",
		Name = "Brr Brr Patapim",
		Rarity = 3,
		Model = "BrrBrrPatapim",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(150, 100, 60),
		Pants = Color3.fromRGB(150, 100, 60),
		Tie = Color3.fromRGB(220, 40, 50),
		Head = Color3.fromRGB(90, 170, 60),
	},
	{
		Id = "LiriliLarila",
		Name = "Lirilì Larilà",
		Rarity = 3,
		Model = "LiriliLarila",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(90, 170, 80),
		Pants = Color3.fromRGB(150, 152, 160),
		Tie = Color3.fromRGB(60, 100, 220),
		Head = Color3.fromRGB(150, 152, 160),
	},
	{
		Id = "Tralalero",
		Name = "Tralalero Tralala",
		Rarity = 5,
		Model = "Tralalero",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(96, 140, 186),
		Pants = Color3.fromRGB(96, 140, 186),
		Tie = Color3.fromRGB(220, 40, 50),
		Head = Color3.fromRGB(96, 140, 186),
		Neon = true,
	},
	{
		Id = "Bombardiro",
		Name = "Bombardiro Crocodilo",
		Rarity = 5,
		Model = "Bombardiro",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(110, 120, 70),
		Pants = Color3.fromRGB(90, 150, 70),
		Tie = Color3.fromRGB(230, 200, 60),
		Head = Color3.fromRGB(90, 150, 70),
		Neon = true,
	},
	{
		Id = "CappuccinoAvvocato", -- id/model kept (saves reference it); renamed by the user 2026-10-09
		Name = "Cappuccino Assassino",
		Rarity = 5,
		Model = "CappuccinoAvvocato",
		Egg = "Brainrot",
		Suit = Color3.fromRGB(28, 28, 34),
		Pants = Color3.fromRGB(28, 28, 34),
		Tie = Color3.fromRGB(200, 30, 40),
		Head = Color3.fromRGB(248, 246, 240),
		Neon = true,
	},
} :: { Skin }

-- Lawyer skills: each lawyer holds up to MaxSlots skills. Rolling one they already have levels it
-- up (to MaxLevel); a new skill with no free slot waits for the player to pick a slot to replace.
-- Every CasesPerFreeRoll finished cases (wins + settlements) a lawyer earns a free roll.
-- Paid rolls cost RollBase * RollGrowth ^ (paid rolls that lawyer has had).
Config.Skills = {
	MaxSlots = 3,
	MaxLevel = 3,
	CasesPerFreeRoll = 40,
	RollBase = 20000,
	RollGrowth = 2.5,
	RarityWeights = { 65, 27, 8 }, -- Common, Uncommon, Rare
	Catalog = {
		{ Id = "FastTalker", Name = "Fast Talker", Rarity = 1, Effect = "caseTime", PerLevel = 0.06, Text = "Cases finish %d%% faster" },
		{ Id = "Organized", Name = "Organized", Rarity = 1, Effect = "payout", PerLevel = 0.05, Text = "+%d%% case payouts" },
		{ Id = "Charming", Name = "Charming", Rarity = 2, Effect = "rareClients", PerLevel = 0.25, Text = "Rare clients visit %d%% more" },
		{ Id = "Specialist", Name = "Specialist", Rarity = 2, Effect = "specialist", PerLevel = 0.2, Text = "+%d%% payout from %s" },
		{ Id = "SilverTongue", Name = "Silver Tongue", Rarity = 3, Effect = "winChance", PerLevel = 0.03, Text = "+%d%% chance to win" },
		{ Id = "Shark", Name = "Shark", Rarity = 3, Effect = "payout", PerLevel = 0.12, Text = "+%d%% case payouts" },
	} :: { SkillDef },
}

-- Daily streak (7-day cycle; missing a day restarts at day 1) and playtime gifts.
-- Coin rewards are "Minutes" of the player's current expected income (all desks, all buffs), never
-- less than MinCoins, so they stay worth it from level 1 to the late game.
-- Kinds: "Coins" (Minutes), "Egg" (free egg tokens), "RareEgg" (egg tokens that always hatch Rare),
-- "SkillRoll" (free skill rolls for the highest-level lawyer).
Config.Rewards = {
	MinCoins = 2000,
	Daily = {
		{ Kind = "Coins", Minutes = 5 },
		{ Kind = "Egg", Count = 1 },
		{ Kind = "Coins", Minutes = 8 },
		{ Kind = "SkillRoll", Count = 1 },
		{ Kind = "Coins", Minutes = 12 },
		{ Kind = "Egg", Count = 2 },
		{ Kind = "RareEgg", Count = 1 },
	},
	PlaytimeInterval = 20 * 60, -- seconds of active play per gift
	PlaytimeMinutes = 2, -- each gift is worth this many minutes of income (~10% on top of play)
	ActiveWindow = 90, -- a player counts as active for this long after their last input
	-- Offline earnings: on rejoin, pay Efficiency x expected income for the time away, capped at
	-- MaxHours, only if away at least MinMinutes. No rolls happen offline.
	Offline = { MaxHours = 2, Efficiency = 0.5, MinMinutes = 5 },
}

-- Short-term goals: Slots goals are active at once; finishing one pays Minutes of the player's
-- expected income (like Config.Rewards) and draws a new goal that isn't already active.
-- Kind is what GoalService.track counts: "win", "rareWin", "train", "courtCorrect", "objection",
-- "hatch", "skillRoll", "deskUpgrade". Text gets the target via %d.
Config.Goals = {
	Slots = 3,
	List = {
		{ Id = "WinCases", Kind = "win", Target = 8, Minutes = 0.5, Text = "Win %d cases" },
		{ Id = "WinMore", Kind = "win", Target = 25, Minutes = 1.25, Text = "Win %d cases" },
		{ Id = "RareWin", Kind = "rareWin", Target = 1, Minutes = 1.25, Text = "Win a case for a Rare or better client" },
		{ Id = "Train", Kind = "train", Target = 3, Minutes = 0.5, Text = "Upgrade your offices %d times" },
		{ Id = "Merge", Kind = "merge", Target = 1, Minutes = 1.5, Text = "Try a mutation at the Mutation Machine" }, -- (Id kept: it's saved)
		{ Id = "Place", Kind = "place", Target = 1, Minutes = 0.5, Text = "Put a new lawyer in an office" },
		{ Id = "Evidence", Kind = "courtCorrect", Target = 2, Minutes = 1, Text = "Pick the right evidence %d times" },
		{ Id = "Objection", Kind = "objection", Target = 1, Minutes = 1, Text = "Shout OBJECTION! in court" },
		{ Id = "Hatch", Kind = "hatch", Target = 2, Minutes = 1, Text = "Hatch %d eggs" },
		{ Id = "Skill", Kind = "skillRoll", Target = 1, Minutes = 0.5, Text = "Roll a lawyer skill" },
		{ Id = "Manager", Kind = "manager", Target = 1, Minutes = 1, Text = "Hire a Manager or buy an upgrade" },
		{ Id = "Desk", Kind = "deskUpgrade", Target = 1, Minutes = 1.25, Text = "Reach a new office tier" },
	},
}

-- Manager: hired once (HireCost), then permanent firm-wide upgrades for every lawyer.
-- Effects: "caseTime" / "winChance" add to Formulas.combineBuffs (Config.Caps still apply);
-- "rareClients" boosts non-Common client odds like the Charming skill; "retainer" pays
-- PerLevel x (one minute of income) every minute; "settle" turns that share of mistrials into
-- settlements. Level L -> L+1 costs Base * Growth ^ L. Text: %s = the effect at a level.
Config.Manager = {
	HireCost = 5e7,
	Upgrades = {
		{ Id = "Paralegal", Name = "Paralegal Staff", Effect = "caseTime", PerLevel = 0.03, MaxLevel = 5, Base = 2e8, Growth = 14, Text = "Cases finish %s faster" },
		{ Id = "Research", Name = "Case Research", Effect = "winChance", PerLevel = 0.015, MaxLevel = 4, Base = 5e8, Growth = 14, Text = "%s more wins" },
		{ Id = "Referral", Name = "Referral Network", Effect = "rareClients", PerLevel = 0.1, MaxLevel = 5, Base = 1e9, Growth = 14, Text = "Rare clients %s more often" },
		{ Id = "Retainer", Name = "Retainer Clients", Effect = "retainer", PerLevel = 0.02, MaxLevel = 5, Base = 3e8, Growth = 14, Text = "Bonus %s of income every minute" },
		{ Id = "SettlementBot", Name = "Settlement Bot", Effect = "settle", PerLevel = 0.25, MaxLevel = 3, Base = 2e9, Growth = 20, Text = "%s of mistrials settle instead" },
	},
}

-- Prestige ("Supreme Empire"): once the firm has RequiredDesks lawyers (the top firm tier), the
-- player can reset coins, lawyers, desks and the Manager for a permanent payout multiplier of
-- 1 + PayoutBonusPerLevel x prestige level. It multiplies case payouts AFTER Config.Caps (it's a
-- reward for starting over, not a stacking buff). Skins, eggs, streaks, goals and stats are kept.
Config.Prestige = {
	Name = "Rebirth", -- shown on screen (user's call 2026-10-16: "Rebirth", not "Supreme" - that is a rarity)
	-- Economy pass 2026-10-09 (user: "fit how other games similar to this one operate"): a rebirth LADDER like
	-- Steal a Brainrot / Pet Sim - the first one ~45 min in, each later one costs more and pays more. Going Supreme
	-- from level N costs CostBase x CostGrowth^N coins and needs min(20, OfficesBase + OfficesPerLevel x N) offices
	-- with a lawyer in them (Formulas.prestigeRequirement). Tuned with tools/economy_sim.py (docs/ECONOMY.md).
	CostBase = 1e10, -- the first Supreme: ~40-70 min in (sim, 5 seeds, with egg tiers)
	CostGrowth = 7, -- each next one costs 7x more; ~12-13 Supremes in the first 24 h (was 5 before egg tiers made lawyers stronger)
	OfficesBase = 10,
	OfficesPerLevel = 2,
	RequiredDesks = 20, -- the most offices any level asks for (a fully expanded firm)
	PayoutBonusPerLevel = 1.0, -- payouts x(1 + this x level), on top of everything
	-- the firm's front building (Server.FirmStages) normally grows with expansions; the Supreme Tower is the reward
	-- for reaching this Supreme level (it used to come with the FIRST one - now that's ~45 min in, that would skip
	-- the other 5 stages every run)
	TowerLevel = 5,
}

-- Badges: create them on the Creator Dashboard, then paste each badge id here. 0 = off.
Config.Badges = {
	FirstWin = 0, -- first case won
	FirstEgg = 0, -- first egg hatched
	SecondLawyer = 0, -- first firm upgrade (2 lawyers)
	LegendaryWin = 0, -- won a case for a Legendary client
	HireManager = 0, -- hired the Manager
	Supreme = 0, -- first prestige
}

Config.Courtroom = {
	CorrectAnswerBonus = 0.15, -- wrong answer or timeout = normal payout, never a penalty
	AnswerTime = 8, -- seconds to pick an evidence card
	AnswerGrace = 1.5, -- extra seconds the server accepts for network lag
	VerdictBuffer = 4, -- the verdict never lands sooner than this after the answer window closes
	-- Surprise events while watching: tap OBJECTION! within EventWindow seconds for EventBonus more.
	EventChance = 0.6, -- chance an attended case gets one event
	EventDelay = { 3, 10 }, -- seconds after the evidence answer before it pops
	EventWindow = 3,
	EventBonus = 0.07,
}

-- Hard limits on stacked buffs, enforced server-side by Formulas.combineBuffs.
Config.Caps = {
	PayoutMultiplier = 2.5,
	WinChanceBonus = 0.12,
	CaseTimeReduction = 0.30,
	XpMultiplier = 2.0, -- reserved for post-MVP skill drops
}

Config.Tutorial = {
	FirstCaseGuaranteedWin = true,
	-- The first client's case always goes to court: the courtroom opens by itself when it starts
	-- (StarterPlayerScripts.Courtroom) with a fixed question about Dave's ticket (Server.CourtService),
	-- and the case waits up to CourtWait extra seconds for the player before it resolves anyway.
	FirstCaseInCourt = true,
	CourtWait = 90,
	FreeLevelUps = 1, -- free office upgrades
	Steps = 5, -- the numbered hints in the HUD (STEP 1/5 .. 5/5)
}

-- Test targets (seconds) the simulator checks against. Not promises to players.
-- v12 targets are checked by Dev.EconomySimV12 (FirstEgg = first PAID egg, after the free tutorial one).
-- NextDesk is only used by the legacy pre-v12 sim (Dev.EconomySim).
Config.Pacing = {
	FirstEgg = { 0, 60 },
	FirstExpand = { 20 * 60, 30 * 60 },
	IncomeAtFirstEgg = { 100, 500 }, -- coins per second
	NextDesk = { 20 * 60, 30 * 60 },
	TrillionPerSecond = { 10 * 3600, 20 * 3600 },
}

-- Themed egg lawyers (Pet / Food / Ocean / Space; models built by tools/themed_cast.py into ReplicatedStorage.
-- SkinModels). { Id, Name, Rarity, Egg, suit, pants, tie, head (hex, for UI swatches) }; Legendary ones glow.
for _, r in {
	{ "PawralegalPup", "Paw-ralegal Pup", 1, "Pet", "465a96", "384878", "465a96", "be8246" },
	{ "HamsterHustle", "Hamster Hustle", 1, "Pet", "a03c3c", "803030", "a03c3c", "e6aa64" },
	{ "WhiskersEsq", "Whiskers, Esq.", 2, "Pet", "282832", "202028", "282832", "f0963c" },
	{ "BubblesGoldfish", "Bubbles the Goldfish", 2, "Pet", "3c8cc8", "3070a0", "3c8cc8", "aae1ff" },
	{ "CorgiCounsel", "Corgi Cooper", 3, "Pet", "faf5eb", "e68c3c", "faf5eb", "e68c3c" },
	{ "ParrotProsecutor", "Polly Parrot", 3, "Pet", "e62828", "3c3c46", "286ee6", "e62828" },
	{ "SirFluffington", "Sir Fluffington", 5, "Pet", "7828a0", "5a1e78", "7828a0", "fafafc" },
	{ "HoundOfJustice", "Thunder Hound", 5, "Pet", "967850", "503c32", "967850", "aa6e3c" },
	{ "ToastAttorney", "Toasty", 1, "Food", "5a7850", "486040", "5a7850", "a05a23" },
	{ "SunnySideSam", "Sunny-Side Sam", 1, "Food", "e6e6ec", "b8b8bc", "e6e6ec", "fcfcf8" },
	{ "SushiSolicitor", "Sushi Sue", 2, "Food", "1e3228", "182820", "1e3228", "1e3c28" },
	{ "TacoTribunal", "Taco Tico", 2, "Food", "c87828", "a06020", "c87828", "f0be50" },
	{ "PizzaProsecutor", "Pizza Pete", 3, "Food", "3c783c", "306030", "3c783c", "ffd250" },
	{ "DonutDefender", "Donut Dee", 3, "Food", "ff8cbe", "cc7098", "ff8cbe", "dca05a" },
	{ "BurgerBoss", "Burger Boss", 5, "Food", "1e1e24", "18181c", "1e1e24", "dc963c" },
	{ "ScoopJudge", "Scoops", 5, "Food", "1e1e28", "1e1e28", "1e1e28", "fff0dc" },
	{ "CrabCounsel", "Crabby", 1, "Ocean", "283c78", "e14632", "283c78", "e14632" },
	{ "ClownfishClerk", "Coco Clownfish", 1, "Ocean", "ff821e", "282832", "ff821e", "ff821e" },
	{ "PufferPartner", "Puffy", 2, "Ocean", "3c78b4", "306090", "3c78b4", "f0d25a" },
	{ "JellyJuror", "Wobbly Jelly", 2, "Ocean", "463c78", "dc8cff", "463c78", "dc8cff" },
	{ "OctoAttorney", "Octo Otto", 3, "Ocean", "28283c", "aa50be", "28283c", "aa50be" },
	{ "SeahorseSolicitor", "Sandy Seahorse", 3, "Ocean", "e6783c", "b86030", "e6783c", "3cc8be" },
	{ "WhaleJudge", "Big Blue", 5, "Ocean", "1e1e28", "1e1e28", "1e1e28", "3c64aa" },
	{ "KrakenCounsel", "Inky the Kraken", 5, "Ocean", "14141a", "14141a", "14141a", "aa2832" },
	{ "MoonRockRookie", "Moon Rock Rookie", 1, "Space", "3c4664", "303850", "3c4664", "aaaaaf" },
	{ "LittleGreenLawyer", "Little Green Zip", 1, "Space", "282832", "202028", "282832", "6edc5a" },
	{ "AstroAttorney", "Astro", 2, "Space", "f0f0f5", "f0f0f5", "f0f0f5", "b4dcff" },
	{ "RoboClerk", "Robo Rex", 2, "Space", "bec8d7", "bec8d7", "bec8d7", "bec8d7" },
	{ "SaturnSolicitor", "Saturn Sam", 3, "Space", "3c286e", "302058", "3c286e", "f0c878" },
	{ "UFOCounsel", "Ziggy UFO", 3, "Space", "5a5a6e", "484858", "5a5a6e", "78e664" },
	{ "StarJudge", "Starla", 5, "Space", "141432", "141432", "141432", "ffe150" },
	{ "BlackHoleBarrister", "Black Hole Bo", 5, "Space", "1e143c", "1e143c", "1e143c", "140a23" },
	-- Epic (4) / Mythic (6) / Supreme (7) for every egg (2026-10-12). Their SkinModels are still to be built
	-- (local session; concepts in docs/CHARACTER_STYLE.md "Epic, Mythic and Supreme"). Until a model exists the
	-- lawyer shows the blocky fallback in these colours.
	{ "ThunderclapCounsel", "Thunderclap", 4, "", "3c3f58", "23242f", "ffd23c", "e8b087" },
	{ "PhoenixProsecutor", "Phoenix", 6, "", "c62828", "3a1010", "ff8c1e", "c68a5e" },
	{ "CelestialChiefJustice", "Celestial", 7, "", "f2efe8", "dcd6c8", "ffc828", "8d5a3b" },
	{ "WolfWarden", "Wolf Warden", 4, "Pet", "23305a", "1c2440", "b45aff", "8c8c96" },
	{ "GryphonGuardian", "Gryphon Guardian", 6, "Pet", "c8963c", "8e6428", "e53935", "f2efe8" },
	{ "CelestialKitsune", "Celestial Kitsune", 7, "Pet", "f2efe8", "d8d2c8", "ff7ab4", "f8f6f0" },
	{ "CactusinoAvvocatino", "Cactusino Avvocatino", 4, "Brainrot", "5a2e96", "37235a", "b45aff", "4caf50" },
	{ "DraghettoSpaghetto", "Draghetto Spaghetto", 6, "Brainrot", "2e5a2e", "1e3c1e", "c8281e", "f0d282" },
	{ "ImperatorePinguino", "Imperatore Pinguino Gelato", 7, "Brainrot", "1c1c24", "1c1c24", "ff50aa", "1c1c24" },
	{ "ChiliProsecutor", "Chili Pepper", 4, "Food", "24242c", "1a1a20", "ff8c1e", "e53927" },
	{ "DragonFruitDuke", "Dragon Fruit Duke", 6, "Food", "1e5a3c", "143c28", "e53935", "ff3c96" },
	{ "GrandGateauJustice", "Grand Gâteau", 7, "Food", "ffc828", "d99a10", "ff9ac8", "f6d8a8" },
	{ "HammerheadAdvocate", "Hammerhead", 4, "Ocean", "1e2a4a", "141c34", "b45aff", "7896aa" },
	{ "NarwhalMagistrate", "Narwhal", 6, "Ocean", "1c1c26", "1c1c26", "e53935", "6e8caa" },
	{ "TidalSovereign", "Tidal Sovereign", 7, "Ocean", "1e64c8", "164a96", "ffc828", "5ac8be" },
	{ "CometCounsel", "Comet", 4, "Space", "eef0f8", "b4b8cc", "b45aff", "a8d8ff" },
	{ "NebulaArbiter", "Nebula", 6, "Space", "141432", "141432", "e53935", "3c1e6e" },
	{ "SupernovaSovereign", "Supernova Sovereign", 7, "Space", "ffc828", "d99a10", "ff50aa", "ffd23c" },
} do
	table.insert(Config.SkinCatalog, {
		Id = r[1],
		Name = r[2],
		Rarity = r[3],
		Egg = if r[4] == "" then nil else r[4], -- "" = the Briefcase Egg
		Model = r[1],
		Suit = Color3.fromHex(r[5]),
		Pants = Color3.fromHex(r[6]),
		Tie = Color3.fromHex(r[7]),
		Head = Color3.fromHex(r[8]),
		Neon = r[3] >= 5 or nil, -- Legendary and up
	})
end

-- Big Case Belt (Server.BigCaseService, StarterPlayerScripts.BigCase): every WaveInterval seconds a wave
-- of gold VIP clients rides the hub conveyor. Walk up and grab one; if two or more players grab the same
-- client within TieWindow seconds, a showdown minigame decides who gets it and everyone else gets the
-- Consolation prize. Coin prizes are minutes of the player's own income (like Config.Rewards).
Config.BigCase = {
	FirstWave = 45, -- seconds after the server starts
	WaveInterval = 150, -- seconds between waves
	WarnTime = 12, -- siren + banner this long before a wave
	WaveSize = 3, -- VIP clients per wave
	Spacing = 3.5, -- seconds between them
	BeltSpeed = 5, -- studs per second
	GrabRange = 14, -- studs (server check; the prompt itself is 12)
	TieWindow = 1.2, -- grabs of the same client this close together start a showdown
	WinsPerWave = 1, -- a player can win this many VIPs per wave (fairness for new players)
	MinTier = 4, -- VIPs are client characters of this tier or higher
	Prizes = { -- weighted; Kind/Minutes/Count as in Config.Rewards
		{ Name = "BIG CASE", Weight = 70, Kind = "Coins", Minutes = 8, Color = Color3.fromRGB(255, 200, 40) },
		{ Name = "HUGE CASE", Weight = 25, Kind = "Coins", Minutes = 20, Color = Color3.fromRGB(255, 130, 40) },
		{ Name = "MEGA CASE", Weight = 5, Kind = "RareEgg", Count = 1, Color = Color3.fromRGB(190, 90, 255) },
	},
	Consolation = { Kind = "Coins", Minutes = 2 },
	Games = { "Mash", "Snap", "Gavel" }, -- showdown minigames, one picked at random
	IntroTime = 2.5, -- "OBJECTION!" splash before the minigame starts
	ResultTime = 3, -- the result screen stays up this long
	Mash = { Duration = 6, MaxTapsPerSecond = 16 },
	Snap = {
		Cards = 6, -- cards on the table (from Deck)
		RevealMin = 1.5, -- seconds after the start before the card to find is called
		RevealMax = 3.5,
		Timeout = 5, -- nobody found it: random winner
		WrongLockout = 1, -- seconds locked out after a wrong (or too early) card
		Deck = {
			{ Icon = "📄", Name = "CONTRACT" },
			{ Icon = "📸", Name = "PHOTO" },
			{ Icon = "🔍", Name = "CLUE" },
			{ Icon = "📼", Name = "TAPE" },
			{ Icon = "🧾", Name = "RECEIPT" },
			{ Icon = "🔑", Name = "KEY" },
			{ Icon = "✉️", Name = "LETTER" },
			{ Icon = "👟", Name = "SHOE PRINT" },
		},
	},
	Gavel = { Period = 1.4, Timeout = 6 }, -- seconds for the needle to swing across and back
}


-- SHOP (StarterPlayerScripts.Shop + Server.ShopService). Robux items. Every Id comes from the Creator Dashboard
-- (Creations > this experience > Monetization > Passes / Developer Products) and MUST be filled in by hand:
-- Id = 0 means "not set up yet" - the card shows COMING SOON, nothing is prompted and nothing is granted.
-- Price is only what the card shows until the real price loads from MarketplaceService (keep them in sync).
-- Passes are permanent (owned check on join + PromptGamePassPurchaseFinished). Products can be bought again
-- and again and are granted ONLY by ProcessReceipt, once per receipt (PlayerData.Purchases).
Config.Shop = {
	Passes = {
		{ Key = "DoubleCash", Id = 0, Price = 199, Name = "2x Cash", Text = "Every case pays double. Forever!", Banner = "x2 Cash", Color = Color3.fromRGB(70, 210, 60), Icon = "cash" },
		{ Key = "LuckyEggs", Id = 0, Price = 299, Name = "Lucky Eggs", Text = "2x chance of Rare, Epic + Legendary lawyers", Banner = "x2 Luck", Color = Color3.fromRGB(255, 190, 30), Icon = "egg" },
		{ Key = "SpeedyCases", Id = 0, Price = 149, Name = "Speedy Cases", Text = "Every case finishes 25% faster", Banner = "-25% Time", Color = Color3.fromRGB(60, 160, 255), Icon = "clock" },
		{ Key = "BigFirm", Id = 0, Price = 99, Name = "Bigger Firm", Text = "Keep 100 more lawyers", Banner = "+100 Lawyers", Color = Color3.fromRGB(175, 90, 255), Icon = "briefcase" },
	},
	Products = {
		{ Key = "CashSmall", Id = 0, Price = 25, Name = "Pile of Cash", Text = "10 minutes of your income", Banner = "+10 min", Color = Color3.fromRGB(170, 175, 190), Icon = "cash", Minutes = 10 },
		{ Key = "CashMedium", Id = 0, Price = 99, Name = "Bag of Cash", Text = "1 hour of your income", Banner = "+1 hour", Color = Color3.fromRGB(70, 210, 60), Icon = "cash", Minutes = 60 },
		{ Key = "CashLarge", Id = 0, Price = 349, Name = "Vault of Cash", Text = "6 hours of your income", Banner = "+6 hours", Color = Color3.fromRGB(60, 160, 255), Icon = "cash", Minutes = 360 },
		{ Key = "RareEggs", Id = 0, Price = 149, Name = "3 Rare Eggs", Text = "3 Briefcase Eggs that always hatch Rare", Banner = "3x Rare", Color = Color3.fromRGB(255, 120, 40), Icon = "egg", RareTokens = 3 },
	},
	Effects = { DoubleCash = 2, SpeedyCases = 0.75, LuckyEggs = 2, BigFirm = 100 },
}

-- Firm areas (Server.FirmFeatures, building: Server.FirmStages). Rooms bought from the glowing pads in front of
-- the firm once it has reached Stage (1 Dingy Shack .. 6 Supreme Tower); the room then appears in the building.
-- Effect: "payout" | "caseTime" | "winChance" add to Formulas.combineBuffs (Config.Caps still apply);
-- "rareClients" adds to the Manager's Referral boost; "lounge" adds Value to payouts while the owner stands in
-- the Executive Lounge. Bought areas reset on prestige (like the firm). Costs are first guesses: tune with
-- Dev.EconomySimV12 if areas are added to the simulated player. (Stage 6 was 5e8 / 5e9, a typo cheaper than Stage 2's
-- room; 5e15 / 5e16 since the 2026-10-12 audit - a guess just above Stage 5, tune it.)
Config.FirmAreas = {
	{ Id = "CafeTerrace", Name = "Rooftop Café", Stage = 2, Cost = 1.5e8, Effect = "payout", Value = 0.05, Text = "+5% case payouts" },
	{ Id = "CoffeeBreak", Name = "Coffee Break Room", Stage = 3, Cost = 1.2e9, Effect = "caseTime", Value = 0.05, Text = "Cases finish 5% faster" },
	{ Id = "LawLibrary", Name = "Law Library", Stage = 4, Cost = 6e10, Effect = "winChance", Value = 0.02, Text = "+2% chance to win" },
	{ Id = "ConferenceRoom", Name = "Conference Room", Stage = 4, Cost = 1.2e11, Effect = "rareClients", Value = 0.15, Text = "Rare clients visit 15% more often" },
	{ Id = "AtriumCafe", Name = "Atrium Coffee Bar", Stage = 5, Cost = 2e14, Effect = "caseTime", Value = 0.08, Text = "Cases finish 8% faster" },
	{ Id = "RoofGarden", Name = "Rooftop Garden", Stage = 5, Cost = 4e14, Effect = "payout", Value = 0.10, Text = "+10% case payouts" },
	{ Id = "ExecLounge", Name = "Executive Lounge", Stage = 5, Cost = 8e14, Effect = "lounge", Value = 0.5, Text = "x1.5 payouts while you're in the lounge" },
	{ Id = "PartnerSuite", Name = "Penthouse Suite", Stage = 6, Cost = 5e15, Effect = "payout", Value = 0.15, Text = "+15% case payouts" },
	{ Id = "PrivateCourt", Name = "Private Courtroom", Stage = 6, Cost = 5e16, Effect = "winChance", Value = 0.03, Text = "+3% chance to win" },
}

-- HUB MINIGAMES (Server.MinigameService + StarterPlayerScripts.Minigames) on the two pads beside the Big Case
-- belt (Workspace.Hub.SpecialSpots). Solo, tap-only, no reading needed (made for young players). Rewards are
-- minutes of the player's own income (Kind/Minutes/Count as in Config.Rewards); Cooldown is per player and saved.
-- Pacing: played every time they're ready, both together add roughly 20-25% on top of idle income.
Config.Minigames = {
	IntroTime = 2.2, -- "READY... GO!" before a round
	GavelBonk = {
		Name = "Gavel Bonk",
		Cooldown = 5 * 60, -- seconds
		Duration = 20, -- seconds a round
		Holes = 9, -- 3 x 3
		PopEvery = { 0.8, 0.45 }, -- seconds between pop-ups at the start / end of the round
		StayUp = { 1.4, 0.85 }, -- how long one stays up at the start / end of the round
		JudgeChance = 0.16, -- the friendly judge pops up instead of a robber
		JudgePenalty = 3, -- points lost for bonking the judge (the score never goes below 0)
		FullScore = 0.75, -- bonking this share of the robbers earns the full reward
		MinMinutes = 0.25, -- reward at 0 points ...
		MaxMinutes = 1.25, -- ... and at FullScore or better
	},
	LuckyBriefcase = {
		Name = "Lucky Briefcase",
		Cooldown = 6 * 60,
		ShowTime = 2.2, -- the cases open to show which one holds the BIG prize
		CloseTime = 0.5,
		Swaps = 6, -- shuffle moves
		SwapTime = 0.6, -- seconds per move
		PickTimeout = 15, -- no pick by then: a random case is opened (still a prize)
		Small = { Name = "COINS", Kind = "Coins", Minutes = 0.5 },
		Big = { -- the star case; weighted
			{ Name = "BIG PRIZE", Weight = 80, Kind = "Coins", Minutes = 1.5 },
			{ Name = "FREE EGG", Weight = 20, Kind = "Egg", Count = 1 },
		},
	},
}

-- ARCADE PIER (2026-10-13, mr.robe's session; user's call: build the minigames in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md).
-- Booth games on the pier north of the hub (Workspace.ArcadePier, tools/blender/arcade_pier.py), run by
-- ServerScriptService.ArcadeServer (one module per game) + StarterPlayerScripts.Arcade. Like Config.Minigames: solo,
-- tap-only, a saved per-player Cooldown (seconds, kept in data.Minigames[id]) and a reward in minutes of the player's
-- own income: MinMinutes at a score of 0 .. MaxMinutes at a perfect score. All first guesses (put them in the zones sim).
Config.Arcade = {
	IntroTime = 2.6, -- "3, 2, 1, GO!" before a round
	LieDetector = {
		Name = "Lie Detector", Color = Color3.fromRGB(70, 200, 120), Cooldown = 4 * 60, MinMinutes = 0.2, MaxMinutes = 1,
		Rounds = 8, RoundTime = 2.6, Gap = 0.7, -- each round the needle swings for RoundTime s and you get one tap
		Period = { 1.6, 0.75 }, -- seconds per full swing, first round .. last
		Band = { 0.26, 0.11 }, -- half-width of the green TRUTH band (the meter runs -1 .. 1), first round .. last
		Perfect = 0.35, -- inside this share of the band = PERFECT
	},
	BriefcaseStack = {
		Name = "Briefcase Stack", Color = Color3.fromRGB(255, 160, 24), Cooldown = 5 * 60, MinMinutes = 0.2, MaxMinutes = 1.25,
		Levels = 20, -- a full tower
		Width = 6, -- the first briefcase's width (units; the slide runs -Travel .. Travel)
		Travel = 7,
		Period = { 2.4, 1 }, -- seconds per full slide, level 1 .. level Levels
		Perfect = 0.3, -- within this many units of the case below = PERFECT (no width lost)
		MinWidth = 0.45, -- a thinner overlap falls off: game over
		Settle = 0.4, -- seconds between a drop and the next case sliding
		MaxWait = 10, -- no tap by then: it drops by itself
	},
	FilingFrenzy = {
		Name = "Filing Frenzy", Color = Color3.fromRGB(60, 160, 255), Cooldown = 5 * 60, MinMinutes = 0.2, MaxMinutes = 1.25,
		Papers = 34,
		Colors = 3, -- bins: red, green, blue (4 adds yellow)
		Gap = { 1.15, 0.45 }, -- seconds between papers, first .. last
		Travel = { 4.4, 2.5 }, -- seconds a paper takes down the belt to the shredder, first .. last
		Misses = 3, -- this many shredded / wrong papers ends the round
	},
}

-- UPSTAIRS ROOMS (2026-10-13; mr.robe's call: build the upper-floor ideas in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md,
-- everything but the Rooftop Helipad). ServerScriptService.FloorRooms stands the rooms (Blender sets:
-- tools/blender/floor_rooms.py -> ServerStorage.Templates.FloorRooms) on the firm building's upper floors as the firm
-- grows (Stage = Server.FirmStages' front building) and runs them; StarterPlayerScripts.Floors draws their panels.
-- Saved in data.Floors (PlayerData v18). Bonuses reach cases through FirmFeatures.buffSources. All numbers first guesses.
Config.Floors = {
	Rooms = {
		MailRoom = { Name = "Mail Room", Stage = 3, Color = Color3.fromRGB(229, 57, 53) },
		HallOfFame = { Name = "Hall of Fame", Stage = 3, Color = Color3.fromRGB(255, 190, 31) },
		VIPLounge = { Name = "VIP Lounge", Stage = 4, Color = Color3.fromRGB(170, 80, 210) },
		MootCourt = { Name = "Moot Court", Stage = 4, Color = Color3.fromRGB(150, 90, 50) },
		CaseArchive = { Name = "Case Files Archive", Stage = 4, Color = Color3.fromRGB(60, 150, 240) },
		PartnersOffice = { Name = "Partner's Office", Stage = 5, Color = Color3.fromRGB(58, 61, 85) },
		GuestLounge = { Name = "Guest Lounge", Stage = 5, Color = Color3.fromRGB(79, 203, 46) },
		PrivateCourtroom = { Name = "Private Courtroom", Stage = 6, Color = Color3.fromRGB(122, 70, 34) },
	},
	-- where each room stands in each building: firm-local { x, floor top y, z, turn in degrees } (0 = the room's front
	-- faces the street). Measured against Server.FirmStages' fronts: clear of the Showcase strip (z < 5.6), the bought
	-- areas' furniture and the elevator stop (back-right corner).
	Slots = {
		[3] = {
			MailRoom = { -12, 9.45, 13, 0 }, HallOfFame = { 3, 9.45, 12, 0 },
		},
		[4] = {
			MailRoom = { -12, 9.45, 13, 0 }, HallOfFame = { 3, 9.45, 12, 0 },
			VIPLounge = { -12, 18.45, 10, 0 }, MootCourt = { 3, 18.45, 10, 0 },
			CaseArchive = { -16.5, 27.45, 9, 0 },
		},
		[5] = {
			MailRoom = { -12, 18.45, 13, 0 }, HallOfFame = { 3, 18.45, 12, 0 },
			VIPLounge = { -15, 36.45, 12, 0 }, MootCourt = { -3, 36.45, 12, 0 }, PartnersOffice = { 8.5, 36.45, 11, 0 },
			CaseArchive = { -13, 45.45, 12, 0 }, GuestLounge = { 2, 45.45, 12, 0 },
		},
		[6] = { -- the tower's floors (FirmStages opened them up for these rooms)
			MailRoom = { -13.6, 20.0, 9, 0 }, HallOfFame = { -2, 20.0, 9, 0 }, VIPLounge = { 9, 20.0, 8, 0 },
			MootCourt = { -13, 29.0, 9, 0 }, CaseArchive = { 0, 29.0, 9, 0 }, PartnersOffice = { 10, 29.0, 8, 0 },
			GuestLounge = { -4, 38.0, 10, 0 },
			PrivateCourtroom = { -3, 65.0, 10, 0 },
		},
	},
	-- MAIL ROOM: three letters from clients every day, each a small task; the last one also holds a free egg
	Mail = {
		Minutes = { 2, 3, 5 }, -- minutes of income per letter
		EggOnLast = true,
		Tasks = { -- kinds GoalService.track sends; Target = how many
			{ Kind = "win", Target = 15, Text = "Win %d cases for me!" },
			{ Kind = "rareWin", Target = 3, Text = "Win %d Rare (or better) cases" },
			{ Kind = "train", Target = 10, Text = "Upgrade your offices %d times" },
			{ Kind = "courtCorrect", Target = 3, Text = "Pick the right evidence %d times" },
			{ Kind = "hatch", Target = 5, Text = "Hatch %d eggs" },
			{ Kind = "place", Target = 2, Text = "Put %d lawyers in offices" },
		},
	},
	-- HALL OF FAME: every lawyer you've ever owned gets a frame; a whole egg's set = a payout bonus for good
	Index = { SetBonus = 0.05 },
	-- VIP LOUNGE: a VIP client waits upstairs; greet them, pick one of your lawyers, the case pays at once
	VIP = {
		Every = 6 * 60, -- seconds between VIPs (one at a time)
		Wait = 3 * 60, -- they leave if nobody greets them
		Minutes = 3, -- minutes of income ...
		RarityBonus = 0.35, -- ... x (1 + RarityBonus x (the lawyer's rarity - 1))
	},
	-- MOOT COURT: send an office to practise; when it's done, that office gets a free skill roll
	Moot = { Booths = 2, Minutes = 15 },
	-- CASE FILES ARCHIVE: wins by client type; each milestone reached = a small payout bonus for good
	Archive = { Milestones = { 10, 50, 250, 1000 }, PerMilestone = 0.004 },
	-- PARTNER'S OFFICE: rules the firm follows on its own (checked every Every seconds)
	Partner = {
		Every = 20,
		Rules = {
			{ Id = "AutoUpgrade", Name = "Auto-upgrade", Text = "Upgrade the cheapest office when you have 3x its cost" },
			{ Id = "AutoEquip", Name = "Auto-equip best", Text = "Put your strongest lawyers in the offices" },
		},
		UpgradeReserve = 3, -- AutoUpgrade only spends when coins >= this x the cost
	},
	-- GUEST LOUNGE: a visitor who stays in your lounge gives you both a payout buff; visitors can like your firm
	Lounge = { Buff = 0.1, Minutes = 5, Stay = 4, Cooldown = 30 * 60, Radius = 9 },
	-- PRIVATE COURTROOM: hold court - three cases, pick the evidence that proves each one
	Court = {
		Cooldown = 10 * 60,
		MinMinutes = 1,
		MaxMinutes = 6,
		Cases = {
			{ Case = "Who ate the Judge's donut?", Cards = { "Sprinkles on the dog's nose", "A muddy boot", "A rainbow umbrella" }, Answer = 1 },
			{ Case = "Who painted the mayor's cat blue?", Cards = { "A banana peel", "Blue paw prints on the stairs", "A lost sock" }, Answer = 2 },
			{ Case = "Who took the trophy?", Cards = { "A toy car", "An empty pizza box", "Glitter on the thief's gloves" }, Answer = 3 },
			{ Case = "Who flooded the bakery?", Cards = { "A wet snorkel by the sink", "A birthday card", "A pair of sunglasses" }, Answer = 1 },
			{ Case = "Who let the goats into the park?", Cards = { "A gold coin", "An open gate key with goat hair", "A paper plane" }, Answer = 2 },
			{ Case = "Who switched the school bells?", Cards = { "A sandwich", "A comic book", "The bell tower's ladder with fresh paint" }, Answer = 3 },
			{ Case = "Who hid the rubber ducks?", Cards = { "Duck feathers in the laundry basket", "A tennis racket", "A broken pencil" }, Answer = 1 },
			{ Case = "Who ate all the cookies?", Cards = { "A clean plate", "Crumbs on the robot's chin", "A soccer ball" }, Answer = 2 },
		},
	},
}

-- EGG ZONES (Server.ZoneService + StarterPlayerScripts.Zones; map: Workspace.Zones, built by the zone builder).
-- The firm is the idle part of the game, the zones the active part: eggs keep popping up on spots around each
-- zone; the player buys one with coins, carries it home in their arms and hatches it at an incubator in their
-- firm (the free first egg and reward eggs hatch there too). Each zone sells one egg. A Law License opens the
-- next zone's gate; prestige takes the License away (the briefcase and shoes stay). Egg prices are the old machine
-- prices (Formulas.eggPrice / themedEggPrice); a golden egg costs more and rolls Rare / Legendary more often.
-- The License Office by the Briefcase Bay entrance sells all three upgrades. Bounds = the zone's land (x0, z0, x1, z1).
Config.Zones = {
	List = {
		-- one lane running south from the plaza's south edge (tools/zones/BuildLane.lua): Safe Zone, then each zone, a gate between
		{ Id = "BriefcaseBay", Name = "Briefcase Bay", Color = Color3.fromRGB(104, 152, 236), Egg = "Briefcase", License = 0, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -490, 36, -90 } },
		{ Id = "PetPark", Name = "Pet Park", Color = Color3.fromRGB(120, 196, 50), Egg = "Pet", License = 1, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -902, 36, -502 } },
		-- zones 3-6 (2026-10-12, user: "make the other 4 zones and their bosses"); each sells its themed egg
		{ Id = "BrainrotBoulevard", Name = "Brainrot Boulevard", Color = Color3.fromRGB(170, 80, 210), Egg = "Brainrot", License = 2, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -1314, 36, -914 } },
		{ Id = "FoodCourt", Name = "Food Court", Color = Color3.fromRGB(240, 84, 74), Egg = "Food", License = 3, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -1726, 36, -1326 } },
		{ Id = "OceanShore", Name = "Ocean Shore", Color = Color3.fromRGB(70, 160, 225), Egg = "Ocean", License = 4, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -2138, 36, -1738 } },
		{ Id = "SpaceBase", Name = "Space Base", Color = Color3.fromRGB(80, 70, 160), Egg = "Space", License = 5, MaxEggs = 14, Respawn = { 3, 7 }, Bounds = { -36, -2550, 36, -2150 } },
	},
	Golden = { Chance = 0.06, PriceMultiplier = 5, Luck = 4, Lifetime = 60 }, -- Luck multiplies the Rare + Legendary odds
	License = { -- level n opens every zone whose License is n or less
		{ Name = "Bronze License", Cost = 5e6 },
		{ Name = "Silver License", Cost = 1e8 }, -- (2-5: first guesses, 2026-10-12 - put them in the zones sim run)
		{ Name = "Gold License", Cost = 2e9 },
		{ Name = "Platinum License", Cost = 4e10 },
		{ Name = "Diamond License", Cost = 1e12 },
	},
	-- the Carry upgrade = BRIEFCASES (2026-10-12, user's call): eggs you can carry home per trip. Model = the briefcase
	-- worn on your back (ReplicatedStorage.Briefcases, from tools/blender/briefcases.py; drawn by CarryPose).
	Carry = {
		{ Max = 1, Name = "Empty Hands" },
		{ Max = 3, Cost = 2.5e5, Name = "Briefcase", Model = "Briefcase" },
		{ Max = 5, Cost = 2.5e7, Name = "Big Briefcase", Model = "BigBriefcase" },
		{ Max = 8, Cost = 2.5e9, Name = "Golden Briefcase", Model = "GoldenBriefcase" },
		{ Max = 12, Cost = 2.5e11, Name = "Diamond Briefcase", Model = "DiamondBriefcase" },
	},
	Speed = { { WalkSpeed = 32 }, { WalkSpeed = 36, Cost = 1e6 }, { WalkSpeed = 40, Cost = 1e8 } }, -- (32 = the game's base speed)
	EggColors = { Briefcase = Color3.fromRGB(245, 200, 70), Golden = Color3.fromRGB(255, 205, 40) },
	-- TRAVEL (2026-10-13, user's pick: one Travel Portal at the hub + a travel map, ServerScriptService.TravelServer /
	-- StarterPlayerScripts.Travel; replaced the six hub teleport pads). Cooldown: seconds between trips.
	-- BlockWhileCarrying: no travel (zones or home) while you carry eggs - the walk home past the bosses is the game.
	Travel = { Cooldown = 3, BlockWhileCarrying = true },
}

-- Zone bosses (docs/BOSSES.md; Server.BossService, StarterPlayerScripts.Bosses; models ReplicatedStorage.Bosses from
-- tools/blender/bosses.py). One boss roams each zone; it winds up (a warning on the floor + a sound, at least 1 s) and
-- attacks. A hit knocks ALL your carried eggs out around you; a loose egg is free for anyone to grab (walk into it)
-- until it vanishes. No on-screen text for any of it (user's call). Bosses stay Margin studs inside their zone's
-- Bounds, so they never reach the Safe Zone, a gate, the firms or the incubators.
-- Attack = "Cone" (Radius studs in front, Angle degrees wide) | "Ring" (Radius studs all round).
-- Difficulty is for design only - never shown.
Config.Bosses = {
	-- (2026-10-12, user: "make the attacks more frequent, make the models bigger, and make them faster and more
	-- dangerous", "the range should be MUCH longer and they should be MUCH larger", then "they should ragdoll the
	-- player, touching the boss's hitbox ragdolls them too, and they should be faster than the player" - so they
	-- outrun players now (base speed 32, max 40). Still fair: every windup lets a player at base speed get out of the
	-- warning, and a player who was just hit is safe for SafeAfterHit s and left alone by that boss for IgnoreAfterHit s.)
	SafeAfterHit = 4, -- seconds a hit player can't be hit again (they're ragdolled for RagdollTime of it)
	IgnoreAfterHit = 5, -- seconds the boss that hit you won't chase or target you
	RagdollTime = 2.2, -- seconds a hit player lies limp before getting up
	DroppedEggLifetime = 30, -- seconds a loose egg stays (it blinks in its last 5 s)
	DropScatter = { 6, 14 }, -- studs from the player the eggs land
	DropStagger = 0.05, -- seconds between eggs leaving the pile
	GrabbableAfter = 0.9, -- seconds before a loose egg can be grabbed (it's still flying / bouncing)
	GrabRadius = 4, -- studs (flat) from a loose egg's middle that grab it
	TriggerRange = 60, -- a player this close (flat studs) makes the boss attack, once AttackEvery has passed
	Knockback = 75, -- studs/s the hit player is flung away
	Margin = { X = 40, Z = 10 }, -- studs the boss keeps inside its zone's Bounds
	-- Scale = drawn this much bigger than the Blender model; Chase = how often a walk heads for a player in the zone;
	-- Hitbox = its body, in MODEL units (x Scale): HalfWidth, Back, Front (it faces -Z), Height - touching it is a hit.
	-- Attack (one, or a list it takes turns with):
	--   "Cone"  Radius studs in front, Angle degrees wide          "Ring"  RingRadius (or Radius) studs all round
	--   "Slam"  hops onto where the target stood when it jumped (HopHeight model units high) and lands: Radius round it
	--   "Line"  rolls / charges Length studs at the target at LineSpeed: Width studs wide; Dizzy s helpless after
	--   "Pull"  drags everyone within Radius toward it at PullSpeed for PullTime s; the middle (Inner) is a hit
	-- Crowd (optional; crnuch's call 2026-10-19, docs/BOSS_ANIMATION.md section 4): with 2+ players in its zone, each
	-- attack also aims a ranged add-on at up to Max OTHER players within Range studs (warned from the same windup,
	-- aimed where they stood when it began). One player in the zone: nothing changes.
	--   Shape "Lane": Width studs wide, from the boss toward them (+20 past, at most Length), travelling at Speed
	--   Shape "Disc": Radius studs round where they stood, landing as the windup ends (with the main attack)
	List = {
		{ Zone = "BriefcaseBay", Model = "SeniorPartner", Name = "The Senior Partner", Difficulty = "Easy",
			Scale = 3.5, WalkSpeed = 38, Chase = 0.85, AttackEvery = 3.5, Windup = 1.2,
			Attack = "Cone", Radius = 45, Angle = 110, StayNearMiddle = 14, Color = Color3.fromRGB(255, 120, 60),
			Hitbox = { HalfWidth = 3.3, Back = 1.4, Front = 1.8, Height = 11.5 },
			-- PAPER STORM (2+ players): a bundle of case files lobbed onto up to Max other players' spots
			Crowd = { Shape = "Disc", Max = 2, Range = 90, Radius = 10 } },
		{ Zone = "PetPark", Model = "BarristerBulldog", Name = "Barrister Bulldog", Difficulty = "Easy",
			Scale = 3.5, WalkSpeed = 44, Chase = 0.9, AttackEvery = 3, Windup = 1.4,
			Attack = "Ring", Radius = 34, Color = Color3.fromRGB(255, 90, 90),
			Hitbox = { HalfWidth = 2.6, Back = 3.9, Front = 6.2, Height = 7.6 } },
		{ Zone = "BrainrotBoulevard", Model = "JudgeMartello", Name = "Judge Martello", Difficulty = "Medium",
			Scale = 3.4, WalkSpeed = 40, Chase = 0.9, AttackEvery = 3, Windup = 1.1,
			Attack = "Slam", Radius = 26, HopHeight = 6, Color = Color3.fromRGB(255, 170, 60),
			Hitbox = { HalfWidth = 3.3, Back = 1.6, Front = 1.7, Height = 5.6 } },
		{ Zone = "FoodCourt", Model = "BigCheese", Name = "Prosecutor Big Cheese", Difficulty = "Medium",
			Scale = 3.2, WalkSpeed = 40, Chase = 0.85, AttackEvery = 3.5, Windup = 1.2,
			Attack = "Line", Length = 110, Width = 22, LineSpeed = 120, Color = Color3.fromRGB(255, 200, 60),
			Hitbox = { HalfWidth = 3.3, Back = 1.2, Front = 1.2, Height = 6.4 } },
		{ Zone = "OceanShore", Model = "Megalodon", Name = "Magistrate Megalodon", Difficulty = "Hard",
			Scale = 3.2, WalkSpeed = 42, Chase = 0.95, AttackEvery = 2.8, Windup = 1.0,
			Attack = "Line", Length = 130, Width = 20, LineSpeed = 150, Dizzy = 2, Color = Color3.fromRGB(90, 190, 255),
			Hitbox = { HalfWidth = 2.2, Back = 2.4, Front = 1.8, Height = 8 },
			-- FEEDING FRENZY (2+ players): sand-shark fins race down a Lane at up to Max other players
			Crowd = { Shape = "Lane", Max = 2, Range = 90, Width = 12, Speed = 120, Length = 110 } },
		{ Zone = "SpaceBase", Model = "Eclipse", Name = "Chief Justice Eclipse", Difficulty = "Extreme",
			Scale = 3.2, WalkSpeed = 44, Chase = 0.95, AttackEvery = 2.5, Windup = 1.4,
			Attack = { "Pull", "Ring" }, Radius = 44, Inner = 12, PullTime = 2, PullSpeed = 16, RingRadius = 38,
			Color = Color3.fromRGB(190, 120, 255), Hitbox = { HalfWidth = 2.4, Back = 1.8, Front = 1.8, Height = 10.3 } },
	},
}

-- Raised studs (docs/ART_STYLE_STUDS.md; StarterPlayerScripts.Studs, client only). Parts tagged Tag get Roblox-shaped
-- 3D studs on their top face near the camera; past the radius the flat stud texture stays.
Config.Studs = {
	Tag = "StudTop",
	Radius = 140, -- studs from the camera's focus: chunks inside show raised studs (PC)
	RadiusLow = 80, -- phones / low graphics (they also get the 8-sided "low" tiles)
	Hysteresis = 16, -- a shown chunk hides only past Radius + this (no flicker at the edge)
	LowQualityLevel = 3, -- a saved graphics level at or below this counts as low (Automatic doesn't)
	ChunkSize = 32, -- studs per side of a show / hide chunk
	CheckEvery = 0.3, -- seconds between distance checks
	BuildPerStep = 6, -- chunks revealed per check at most (spreads the first build)
	Foot = 0.3, -- half a stud's foot width, and Height its height above the face (tools/blender/stud_tiles.py):
	Height = 0.1, -- a cell gets no stud if a visible anchored part reaches into that space
	RebuildDelay = 1.5, -- seconds things must settle after parts appear / go before the faces they touch are redone
}

local function deepFreeze(t: { [any]: any })
	for _, v in t do
		if type(v) == "table" and not table.isfrozen(v) then
			deepFreeze(v)
		end
	end
	table.freeze(t)
end

deepFreeze(Config)

return Config
