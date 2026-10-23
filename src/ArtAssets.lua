--!strict
-- ArtAssets (ReplicatedStorage.Shared.ArtAssets): the game's rendered artwork (2026-10-10). Every image here was
-- modelled, lit and rendered in Blender by tools/shop_icons.py (512 x 512 transparent PNG with an ink outline;
-- sources in art/shop_icons/, scenes in art/shop_icons/blend/) and uploaded to Roblox.
-- To change one: edit its builder in tools/shop_icons.py, re-render (`Blender -b --factory-startup --python
-- tools/shop_icons.py -- <name>`), upload the PNG, paste the new id below.

local ArtAssets = {}

-- one per egg type, keyed like Config.Eggs.Themed ids ("Briefcase" = the starter egg, "Rare" = a Rare Briefcase Egg)
ArtAssets.Eggs = {
	Briefcase = "rbxassetid://76432403189938", -- egg_briefcase
	Brainrot = "rbxassetid://129245891197874", -- egg_brainrot
	Pet = "rbxassetid://129444637400530", -- egg_pet
	Food = "rbxassetid://129449844056930", -- egg_food
	Ocean = "rbxassetid://140096443884946", -- egg_ocean
	Space = "rbxassetid://107654052588256", -- egg_space
	Rare = "rbxassetid://76731595172597", -- egg_rare
}

-- one per Config.Shop item, keyed by its Key
ArtAssets.Shop = {
	DoubleCash = "rbxassetid://79774407997348", -- cash_x2
	LuckyEggs = "rbxassetid://126520572387984", -- lucky_eggs
	SpeedyCases = "rbxassetid://72311295235687", -- speedy_cases
	BigFirm = "rbxassetid://80539935648207", -- bigger_firm
	CashSmall = "rbxassetid://99291637751308", -- cash_pile
	CashMedium = "rbxassetid://136787201572075", -- cash_bag
	CashLarge = "rbxassetid://101254224498081", -- cash_vault
	RareEggs = "rbxassetid://123775632424724", -- rare_eggs
}

-- the Shop's section shortcuts
ArtAssets.Tabs = {
	Featured = "rbxassetid://123639581250966", -- tab_star
	Passes = "rbxassetid://133639116623916", -- tab_crown
	Cash = "rbxassetid://99291637751308", -- cash_pile
	Eggs = "rbxassetid://76432403189938", -- egg_briefcase
}

-- the Travel menu's picture cards (2026-10-23, art/travel/ - crops of the v2 islands' ground renders; uploaded by
-- crnuch's Studio)
ArtAssets.Travel = {
	Home = "rbxassetid://117539978811046", -- the hub island from above (crnuch: "a pic of the island itself")
	BriefcaseBay = "rbxassetid://92015247659036",
	PetPark = "rbxassetid://95030000841761",
	BrainrotBoulevard = "rbxassetid://99916639620400",
	FoodCourt = "rbxassetid://79095597985925",
	OceanShore = "rbxassetid://131220690883461",
	SpaceBase = "rbxassetid://119502654637372",
}

return ArtAssets
