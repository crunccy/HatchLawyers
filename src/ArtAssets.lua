--!strict
-- ArtAssets (ReplicatedStorage.Shared.ArtAssets): the game's rendered artwork (2026-10-10). Every image here was
-- modelled, lit and rendered in Blender by tools/shop_icons.py (512 x 512 transparent PNG with an ink outline;
-- sources in art/shop_icons/, scenes in art/shop_icons/blend/) and uploaded to Roblox.
-- To change one: edit its builder in tools/shop_icons.py, re-render (`Blender -b --factory-startup --python
-- tools/shop_icons.py -- <name>`), upload the PNG, paste the new id below.

local ArtAssets = {}

-- one per egg type, keyed like Config.Eggs.Themed ids ("Briefcase" = the starter egg, "Rare" = a Rare Briefcase Egg)
ArtAssets.Eggs = {
	Briefcase = "rbxassetid://100860948095033", -- egg_briefcase
	Brainrot = "rbxassetid://108732736882059", -- egg_brainrot
	Pet = "rbxassetid://76328699168902", -- egg_pet
	Food = "rbxassetid://83275782484449", -- egg_food
	Ocean = "rbxassetid://110117780165981", -- egg_ocean
	Space = "rbxassetid://96736267223887", -- egg_space
	Rare = "rbxassetid://133816622949382", -- egg_rare
}

-- one per Config.Shop item, keyed by its Key
ArtAssets.Shop = {
	DoubleCash = "rbxassetid://97764496999698", -- cash_x2
	LuckyEggs = "rbxassetid://127926789534396", -- lucky_eggs
	SpeedyCases = "rbxassetid://118786267373869", -- speedy_cases
	BigFirm = "rbxassetid://136526931692404", -- bigger_firm
	CashSmall = "rbxassetid://124427182416928", -- cash_pile
	CashMedium = "rbxassetid://85207660166385", -- cash_bag
	CashLarge = "rbxassetid://72465101907552", -- cash_vault
	RareEggs = "rbxassetid://135582083351087", -- rare_eggs
}

-- the Shop's section shortcuts
ArtAssets.Tabs = {
	Featured = "rbxassetid://104571186521828", -- tab_star
	Passes = "rbxassetid://112799166656073", -- tab_crown
	Cash = "rbxassetid://124427182416928", -- cash_pile
	Eggs = "rbxassetid://100860948095033", -- egg_briefcase
}

return ArtAssets
