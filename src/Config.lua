--!strict
-- Every tunable number for Hatch Lawyers & Get Rich lives here.
-- Live server code and the economy simulator (ServerScriptService.Dev.EconomySim) both read it,
-- so tune here and re-run the sim. Values are MVP (v0.3) scope: 3 client tiers, 4 skin rarities.

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
	ExpandCosts = { [5] = 7e7, [6] = 6e8, [7] = 3e10, [8] = 1.5e12, [9] = 8e13, [10] = 4e15 },
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
Config.Lawyers = {
	StartId = "Rookie",
	MergeCount = 3,
	StarEarn = { 1, 2.5, 6 },
	StarNames = { "", "Gold", "Rainbow" },
	MaxOwned = 150, -- inventory cap (merge or wait for space)
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
	Skins = {
		-- SellValue: coins for selling one duplicate (10% / 20% / 50% / 200% of the egg price).
		{ Id = "Common", Weight = 58, PayoutBonus = 0.01, SellValue = 750, Earn = 1, StartSkills = 1 },
		{ Id = "Uncommon", Weight = 26.5, PayoutBonus = 0.02, SellValue = 1500, Earn = 2, StartSkills = 1 },
		{ Id = "Rare", Weight = 13, PayoutBonus = 0.05, SellValue = 3750, Earn = 4, StartSkills = 2 },
		{ Id = "Legendary", Weight = 2.5, PayoutBonus = 0.20, SellValue = 15000, Earn = 10, StartSkills = 2 },
	} :: { SkinRarity },
	-- Themed eggs (workspace.Hub.<Machine>, on the plaza's egg pads): each hatches ONLY the catalog lawyers
	-- whose Egg = its Id, with its own rarity Weights (by rarity index), at PriceMultiplier x the Briefcase
	-- Egg's current price. They share the opened count (all prices climb together) and the pity counter, and
	-- are never free (the free egg and reward tokens are for the Briefcase Egg). Color = the hatch-screen egg.
	Themed = {
		{ Id = "Brainrot", Name = "Brainrot Egg", Machine = "BrainrotEggMachine", PriceMultiplier = 3, Weights = { 0, 60, 32, 8 }, Color = Color3.fromRGB(165, 95, 255), Tagline = "Brainrot lawyers only!" },
		{ Id = "Pet", Name = "Pet Egg", Machine = "PetEggMachine", PriceMultiplier = 2, Weights = { 55, 28, 14, 3 }, Color = Color3.fromRGB(255, 180, 110), Tagline = "Pet lawyers only!" },
		{ Id = "Food", Name = "Food Egg", Machine = "FoodEggMachine", PriceMultiplier = 4, Weights = { 45, 32, 18, 5 }, Color = Color3.fromRGB(255, 120, 100), Tagline = "Food lawyers only!" },
		{ Id = "Ocean", Name = "Ocean Egg", Machine = "OceanEggMachine", PriceMultiplier = 8, Weights = { 35, 35, 22, 8 }, Color = Color3.fromRGB(60, 170, 230), Tagline = "Ocean lawyers only!" },
		{ Id = "Space", Name = "Space Egg", Machine = "SpaceEggMachine", PriceMultiplier = 16, Weights = { 25, 35, 28, 12 }, Color = Color3.fromRGB(110, 70, 220), Tagline = "Space lawyers only!" },
	},
}

-- Every skin an egg can hatch. An egg first rolls a rarity (Config.Eggs.Skins weights), then picks
-- evenly among the skins of that rarity. Add skins here; ids are saved, so never rename one.
-- Every lawyer has a block-style model in ReplicatedStorage.SkinModels (Model = ...); the first 7 are built by
-- HatchLawyers/tools/lawyers_v2.py. Suit/Pants/Tie/Hat only colour the old blocky fallback and UI swatches.
Config.SkinCatalog = {
	{
		Id = "Rookie", -- the starting lawyer (also hatchable)
		Name = "Rookie Lawyer",
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
		Name = "Bow Tie Barrister",
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
		Name = "Tung Tung Tung Sahur",
		Rarity = 4,
		Model = "LawyerSkin_Legendary",
		Suit = Color3.fromRGB(35, 45, 95),
		Pants = Color3.fromRGB(30, 38, 80),
		Tie = Color3.fromRGB(220, 40, 50),
		Head = Color3.fromRGB(235, 125, 40),
		Neon = true,
	},
	{
		Id = "NeonLitigator",
		Name = "Neon Litigator",
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
		Name = "IShowSued",
		Rarity = 4,
		Model = "IShowSued",
		Suit = Color3.fromRGB(200, 18, 40),
		Pants = Color3.fromRGB(30, 30, 34),
		Tie = Color3.fromRGB(20, 140, 70),
		Head = Color3.fromRGB(120, 78, 54),
		Neon = true,
	},
	{
		Id = "IceJustice",
		Name = "Ice Justice",
		Rarity = 4,
		Model = "IceJustice",
		Suit = Color3.fromRGB(170, 216, 245),
		Pants = Color3.fromRGB(240, 248, 255),
		Tie = Color3.fromRGB(200, 245, 255),
		Head = Color3.fromRGB(186, 128, 92),
		Neon = true,
	},
	{
		Id = "KaiSueNat",
		Name = "Kai Sue-nat",
		Rarity = 3,
		Model = "KaiSueNat",
		Suit = Color3.fromRGB(25, 25, 30),
		Pants = Color3.fromRGB(25, 25, 30),
		Tie = Color3.fromRGB(210, 30, 40),
		Head = Color3.fromRGB(116, 76, 52),
	},
	{
		Id = "KhabyClaim",
		Name = "Khaby Claim",
		Rarity = 3,
		Model = "KhabyClaim",
		Suit = Color3.fromRGB(120, 124, 132),
		Pants = Color3.fromRGB(60, 62, 70),
		Tie = Color3.fromRGB(30, 30, 34),
		Head = Color3.fromRGB(108, 70, 48),
	},
	{
		Id = "BensonBond",
		Name = "Benson Bond",
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
		Rarity = 4,
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
		Rarity = 4,
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
		Rarity = 4,
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
		{ Id = "Merge", Kind = "merge", Target = 1, Minutes = 1.5, Text = "Merge 3 lawyers into a star lawyer" },
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
	Name = "Supreme Empire",
	RequiredDesks = 20, -- a fully expanded firm with a lawyer in every office
	PayoutBonusPerLevel = 0.5,
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
	{ "CorgiCounsel", "Corgi Counsel", 3, "Pet", "faf5eb", "e68c3c", "faf5eb", "e68c3c" },
	{ "ParrotProsecutor", "Parrot Prosecutor", 3, "Pet", "e62828", "3c3c46", "286ee6", "e62828" },
	{ "SirFluffington", "Sir Fluffington", 4, "Pet", "7828a0", "5a1e78", "7828a0", "fafafc" },
	{ "HoundOfJustice", "Hound of Justice", 4, "Pet", "967850", "503c32", "967850", "aa6e3c" },
	{ "ToastAttorney", "Toast Attorney", 1, "Food", "5a7850", "486040", "5a7850", "a05a23" },
	{ "SunnySideSam", "Sunny-Side Sam", 1, "Food", "e6e6ec", "b8b8bc", "e6e6ec", "fcfcf8" },
	{ "SushiSolicitor", "Sushi Solicitor", 2, "Food", "1e3228", "182820", "1e3228", "1e3c28" },
	{ "TacoTribunal", "Taco Tribunal", 2, "Food", "c87828", "a06020", "c87828", "f0be50" },
	{ "PizzaProsecutor", "Pizza Prosecutor", 3, "Food", "3c783c", "306030", "3c783c", "ffd250" },
	{ "DonutDefender", "Donut Defender", 3, "Food", "ff8cbe", "cc7098", "ff8cbe", "dca05a" },
	{ "BurgerBoss", "Burger Boss", 4, "Food", "1e1e24", "18181c", "1e1e24", "dc963c" },
	{ "ScoopJudge", "Judge Scoop", 4, "Food", "1e1e28", "1e1e28", "1e1e28", "fff0dc" },
	{ "CrabCounsel", "Crab Counsel", 1, "Ocean", "283c78", "e14632", "283c78", "e14632" },
	{ "ClownfishClerk", "Clownfish Clerk", 1, "Ocean", "ff821e", "282832", "ff821e", "ff821e" },
	{ "PufferPartner", "Puffer Partner", 2, "Ocean", "3c78b4", "306090", "3c78b4", "f0d25a" },
	{ "JellyJuror", "Jelly Juror", 2, "Ocean", "463c78", "dc8cff", "463c78", "dc8cff" },
	{ "OctoAttorney", "Octo-Attorney", 3, "Ocean", "28283c", "aa50be", "28283c", "aa50be" },
	{ "SeahorseSolicitor", "Seahorse Solicitor", 3, "Ocean", "e6783c", "b86030", "e6783c", "3cc8be" },
	{ "WhaleJudge", "Whale Judge", 4, "Ocean", "1e1e28", "1e1e28", "1e1e28", "3c64aa" },
	{ "KrakenCounsel", "Kraken Counsel", 4, "Ocean", "14141a", "14141a", "14141a", "aa2832" },
	{ "MoonRockRookie", "Moon Rock Rookie", 1, "Space", "3c4664", "303850", "3c4664", "aaaaaf" },
	{ "LittleGreenLawyer", "Little Green Lawyer", 1, "Space", "282832", "202028", "282832", "6edc5a" },
	{ "AstroAttorney", "Astro-Attorney", 2, "Space", "f0f0f5", "f0f0f5", "f0f0f5", "b4dcff" },
	{ "RoboClerk", "Robo-Clerk", 2, "Space", "bec8d7", "bec8d7", "bec8d7", "bec8d7" },
	{ "SaturnSolicitor", "Saturn Solicitor", 3, "Space", "3c286e", "302058", "3c286e", "f0c878" },
	{ "UFOCounsel", "UFO Counsel", 3, "Space", "5a5a6e", "484858", "5a5a6e", "78e664" },
	{ "StarJudge", "Star Judge", 4, "Space", "141432", "141432", "141432", "ffe150" },
	{ "BlackHoleBarrister", "Black Hole Barrister", 4, "Space", "1e143c", "1e143c", "1e143c", "140a23" },
} do
	table.insert(Config.SkinCatalog, {
		Id = r[1],
		Name = r[2],
		Rarity = r[3],
		Egg = r[4],
		Model = r[1],
		Suit = Color3.fromHex(r[5]),
		Pants = Color3.fromHex(r[6]),
		Tie = Color3.fromHex(r[7]),
		Head = Color3.fromHex(r[8]),
		Neon = r[3] == 4 or nil,
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
		{ Key = "LuckyEggs", Id = 0, Price = 299, Name = "Lucky Eggs", Text = "2x chance of Rare + Legendary lawyers", Banner = "x2 Luck", Color = Color3.fromRGB(255, 190, 30), Icon = "egg" },
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
