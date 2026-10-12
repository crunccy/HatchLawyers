--!strict
-- Egg machine, server side (v12: eggs hatch real LAWYERS). The client never decides anything: pressing
-- the machine's prompt asks the server, which checks coins, rolls a rarity with the Config odds (+ pity),
-- picks a lawyer of that rarity from Config.SkinCatalog (the lawyer catalog), gives it its starting
-- skills (Server.LawyerService.hatch) and tells the client what hatched (Remotes.EggHatched).
-- The player then places it into an empty office (Remotes.PlaceLawyer) from the hatch screen or the
-- LAWYERS panel. The price grows with every egg opened (Formulas.eggPrice).
-- Themed eggs (Config.Eggs.Themed: Brainrot / Pet / Food / Ocean / Space, each workspace.Hub.<Machine>)
-- hatch only their own lawyers (catalog Egg = Id), with their own odds, at PriceMultiplier x the price
-- (never free). Attribute <Id>EggPrice (e.g. PetEggPrice) per themed egg. Egg tiers (2026-10-12): each
-- themed machine refuses to roll (reason "locked") until the player's lifetime Stats.CoinsEarned reaches
-- its UnlockEarned (Formulas.eggUnlocked).
--
-- Saved in PlayerData: Lawyers, Eggs.{Opened, FreeUsed, Seen, FreeTokens, RareTokens, SinceTop}.
-- Mirrored attributes: FreeEgg, EggTokens, RareEggTokens, EggsOpened, EggPity, EggPrice,
-- SkinsUnseen (hatches not yet looked at in the LAWYERS panel; Remotes.MarkSkinsSeen clears it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript)
local Server = ServerScriptService:WaitForChild("Server")
local PlayerData = require(Server:WaitForChild("PlayerData") :: ModuleScript)
local LawyerService = require(Server:WaitForChild("LawyerService") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggHatched = Remotes:WaitForChild("EggHatched") :: RemoteEvent
local MarkSkinsSeen = Remotes:WaitForChild("MarkSkinsSeen") :: RemoteEvent

local machine = workspace:WaitForChild("Hub"):WaitForChild("EggMachine")
local rollPrompt = machine:FindFirstChild("RollPrompt", true) :: ProximityPrompt
-- themed egg Id -> its machine model
local themedMachines: { [string]: Instance } = {}
for _, def in Config.Eggs.Themed do
	local m = workspace.Hub:WaitForChild(def.Machine, 10)
	if m then
		themedMachines[def.Id] = m
	else
		warn("[EggServer] no machine for the", def.Name, "in workspace.Hub")
	end
end

-- Egg particle fix (2026-10-09). Each machine egg is bobbed and spun by the CLIENT (StarterPlayerScripts.Eggs)
-- with Model:PivotTo every frame. The client used to read the egg's home with GetPivot() when it started -
-- but players spawn at their firm, far from the hub, so with StreamingEnabled the egg's parts (and its
-- PrimaryPart, the invisible Shell) usually hadn't streamed in yet and GetPivot() fell back to the map origin.
-- Every frame after, whatever had streamed in (the Shell + FX_Shell / FX_Aura parts that hold the particle
-- emitters) was dragged to the middle of the map, while voxels that arrived later stayed put.
-- Fix: the server (which always has every part) publishes each egg's true home as an attribute, and the egg
-- streams atomically - its shell, effect parts and voxels always arrive together.
for _, m in (themedMachines :: { [string]: Instance }) do
	local egg = m:FindFirstChild("Egg")
	if egg and egg:IsA("Model") then
		egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		egg:SetAttribute("Home", egg:GetPivot())
	end
end
do
	local egg = machine:FindFirstChild("Egg")
	if egg and egg:IsA("Model") then
		egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		egg:SetAttribute("Home", egg:GetPivot())
	end
end

-- Matches the client's hatch animation so rolls can't be spammed faster than they play.
local ROLL_COOLDOWN = 2.5
local DATA_WAIT = 120

local rng = Random.new()
local lastRoll: { [Player]: number } = {}

-- the egg price ramp: eggs opened since the last Supreme, x Config.Eggs.PrestigePriceScale per Supreme level
local function priceCount(data: any): number
	return data.Eggs.RunOpened or data.Eggs.Opened
end
local function prestigeLevel(data: any): number
	return if data.Prestige then data.Prestige.Level else 0
end

local function hatchCount(data: any): number
	return data.Eggs.Opened + (if data.Eggs.FreeUsed then 1 else 0)
end

local function sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("SkinsUnseen", math.max(hatchCount(data) - data.Eggs.Seen, 0))
	-- Egg tokens come from daily rewards (RewardsService); they make the next hatches free too.
	local tokens = (data.Eggs.FreeTokens or 0) + (data.Eggs.RareTokens or 0)
	player:SetAttribute("FreeEgg", (Config.Eggs.FreeFirstEgg and not data.Eggs.FreeUsed) or tokens > 0)
	player:SetAttribute("EggTokens", data.Eggs.FreeTokens or 0)
	player:SetAttribute("RareEggTokens", data.Eggs.RareTokens or 0)
	player:SetAttribute("EggsOpened", data.Eggs.Opened)
	player:SetAttribute("EggPrice", Formulas.eggPrice(priceCount(data), prestigeLevel(data)))
	for _, def in Config.Eggs.Themed do
		player:SetAttribute(def.Id .. "EggPrice", Formulas.themedEggPrice(def.Id, priceCount(data), prestigeLevel(data)))
	end
	if Config.Eggs.PityTop then
		player:SetAttribute("EggPity", math.max(Config.Eggs.PityTop - (data.Eggs.SinceTop or 0), 1)) -- eggs until a guaranteed top lawyer
	end
end

local function firstEmptyOffice(data: any): number?
	for index, office in data.Desks do
		if not office.Lawyer then
			return index
		end
	end
	return nil
end

-- Lucky Eggs (Robux pass, Server.ShopService): the Rare, Epic and Legendary weights are multiplied. Mythic and
-- Supreme are left alone (Supreme stays at most 1 in 2500).
local function luckyWeights(player: Player, weights: { number }?): { number }?
	local ShopService = require(Server.ShopService) :: any
	local luck = ShopService.effect(player, "LuckyEggs", 1)
	if luck == 1 then
		return weights
	end
	local base = weights or Formulas.skinWeights()
	local out = table.clone(base)
	for index, tier in Config.Eggs.Skins do
		if (tier.Id == "Rare" or tier.Id == "Epic" or tier.Id == "Legendary") and out[index] then
			out[index] *= luck
		end
	end
	return out
end

local function onRoll(player: Player, eggId: string?)
	local themed = Formulas.themedEgg(eggId)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local t = os.clock()
	if lastRoll[player] and t - lastRoll[player] < ROLL_COOLDOWN then
		return
	end
	-- egg tiers: a themed machine only works once the player has earned its UnlockEarned (lifetime)
	if themed and not Formulas.eggUnlocked(themed.Id, data.Stats and data.Stats.CoinsEarned) then
		EggHatched:FireClient(player, { ok = false, reason = "locked", egg = themed.Id, need = themed.UnlockEarned })
		return
	end
	local ShopService = require(Server.ShopService) :: any
	if PlayerData.lawyerCount(data) >= Config.Lawyers.MaxOwned + ShopService.effect(player, "BigFirm", 0) then
		EggHatched:FireClient(player, { ok = false, reason = "full" })
		return
	end

	-- the free egg and reward tokens only work on the Briefcase Egg
	local free = not themed and Config.Eggs.FreeFirstEgg and not data.Eggs.FreeUsed
	-- Reward tokens: a Rare token always hatches Rare; a free token rolls normally. Both skip the price.
	local rareToken = not themed and not free and (data.Eggs.RareTokens or 0) > 0
	local freeToken = not themed and not free and not rareToken and (data.Eggs.FreeTokens or 0) > 0
	local price = if themed then Formulas.themedEggPrice(themed.Id, priceCount(data), prestigeLevel(data))
		else Formulas.eggPrice(priceCount(data), prestigeLevel(data))
	if not free and not rareToken and not freeToken and not PlayerData.spendCoins(player, price) then
		EggHatched:FireClient(player, { ok = false, reason = "coins", price = price, egg = if themed then themed.Id else nil })
		return
	end
	lastRoll[player] = t

	local rarity
	if free then
		-- The tutorial egg is scripted and doesn't count as a roll.
		data.Eggs.FreeUsed = true
		rarity = Config.Eggs.FirstEggRarity
	elseif rareToken then
		data.Eggs.RareTokens -= 1
		data.Eggs.Opened += 1
		data.Eggs.RunOpened = (data.Eggs.RunOpened or 0) + 1
		rarity = 3
		for index, tier in Config.Eggs.Skins do
			if tier.Id == "Rare" then
				rarity = index
			end
		end
	elseif themed then
		data.Eggs.Opened += 1
		data.Eggs.RunOpened = (data.Eggs.RunOpened or 0) + 1
		rarity = Formulas.rollSkin(rng, luckyWeights(player, themed.Weights))
	else
		if freeToken then
			data.Eggs.FreeTokens -= 1
		end
		data.Eggs.Opened += 1
		data.Eggs.RunOpened = (data.Eggs.RunOpened or 0) + 1
		rarity = Formulas.rollSkin(rng, luckyWeights(player, nil))
	end
	-- pity: every egg but the tutorial one counts; Config.Eggs.PityRarity (Legendary) or better resets it, and
	-- hitting the limit upgrades this egg to exactly that rarity - never to Mythic / Supreme (Config.Eggs.PityTop)
	if not free and Config.Eggs.PityTop then
		local top = Config.Eggs.PityRarity or #Config.Eggs.Skins
		data.Eggs.SinceTop = (data.Eggs.SinceTop or 0) + 1
		if rarity < top and data.Eggs.SinceTop >= Config.Eggs.PityTop then
			rarity = top
		end
		if rarity >= top then
			data.Eggs.SinceTop = 0
		end
	end
	require(Server.BadgeAwards).award(player, "FirstEgg")
	local id = Formulas.rollSkinId(rng, rarity, if themed then themed.Id else nil)
	local isNew = true
	for _, lawyer in data.Lawyers do
		if lawyer.Id == id then
			isNew = false
		end
	end
	local uid, lawyer = LawyerService.hatch(data, id)
	-- how many copies (same lawyer, 1 star) the player now has, for the "merge ready" hint
	local copies = 0
	for _, other in data.Lawyers do
		if other.Id == id and other.Stars == 1 then
			copies += 1
		end
	end
	PlayerData.sync(player)
	sync(player)
	require(Server.GoalService).track(player, "hatch") -- short-term goals
	-- everyone near the machine sees a Rare or better come out, timed with the client's 3D egg shattering
	-- (StarterPlayerScripts.Eggs, measured in playtest: ~5.1 s for Rare, ~6.5 s for Legendary, unskipped; the
	-- Legendary+ hatch has the longer build-up)
	local rarityId = Config.Eggs.Skins[rarity] and Config.Eggs.Skins[rarity].Id
	local burstKind = Effects.rarityBurst(rarityId)
	if burstKind then
		local from = if themed and themedMachines[themed.Id] then themedMachines[themed.Id] else machine
		task.delay(if rarity >= (Config.Eggs.PityRarity or 5) then 6.5 else 5.1, function()
			local box, size = (from :: Model):GetBoundingBox()
			Effects.burst(box.Position + Vector3.new(0, size.Y / 2 + 2, 0), burstKind)
		end)
	end

	EggHatched:FireClient(player, {
		ok = true,
		uid = uid,
		lawyerId = id,
		skinId = id, -- (old name, kept for older client code)
		rarity = rarity,
		skills = lawyer.Skills,
		free = free or rareToken or freeToken,
		egg = if themed then themed.Id else nil,
		isNew = isNew,
		copies = copies,
		emptyOffice = firstEmptyOffice(data),
	})
end

local function onPlayerAdded(player: Player)
	local deadline = os.clock() + DATA_WAIT
	while player.Parent and not PlayerData.get(player) and os.clock() < deadline do
		task.wait(0.5)
	end
	if PlayerData.get(player) then
		sync(player)
	end
end

rollPrompt.Triggered:Connect(function(player)
	onRoll(player, nil)
end)
for id, m in themedMachines do
	local prompt = m:FindFirstChild("RollPrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(player)
			onRoll(player, id)
		end)
	end
end
MarkSkinsSeen.OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if data then
		data.Eggs.Seen = hatchCount(data)
		sync(player)
	end
end)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
