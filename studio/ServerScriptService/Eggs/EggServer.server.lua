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
--
-- v16 (egg zones, Config.Zones): the Briefcase and Pet eggs are no longer sold by hub machines (those machines
-- are archived in ServerStorage.Old_HubEggMachines). They are bought in Briefcase Bay / Pet Park and hatched at
-- an incubator in the player's firm by Server.ZoneService, which calls the ServerStorage.EggApi bindable:
--   EggApi:Invoke("hatch", player, eggId?, golden?, at?)  an egg already paid for (eggId nil = Briefcase);
--                                                         golden multiplies the Rare + Legendary odds
--   EggApi:Invoke("free", player, at?)                     the free first egg / a reward token, if the player has one
--   EggApi:Invoke("price", player, eggId?, ahead?) -> number  what that egg costs this player right now (ahead: eggs
--                                                         already in their bag, each a step further up the ramp)
--   EggApi:Invoke("room", player) -> number                how many more lawyers the player can own
-- "hatch" / "free" return true when an egg hatched (false: lawyer cap, cooldown, nothing to hatch).
-- Themed machines still on the hub keep working exactly as before.

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
-- (2026-10-12) everyone else nearby sees a Legendary+ egg fall onto the incubator it hatched at (StarterPlayerScripts.Eggs)
local HatchShow = Remotes:FindFirstChild("HatchShow") :: RemoteEvent?
if not HatchShow then
	local r = Instance.new("RemoteEvent")
	r.Name = "HatchShow"
	r.Parent = Remotes
	HatchShow = r
end
-- (2026-10-13) a Mythic / Supreme hatch is announced to the whole server (a banner on every other screen)
local HatchAnnounce = Remotes:FindFirstChild("HatchAnnounce") :: RemoteEvent?
if not HatchAnnounce then
	local r = Instance.new("RemoteEvent")
	r.Name = "HatchAnnounce"
	r.Parent = Remotes
	HatchAnnounce = r
end
-- the share (%) a rarity had in the odds an egg was rolled with (for the reveal's "x% chance")
local function weightShare(weights: { number }?, index: number): number?
	local w = weights or Formulas.skinWeights()
	local total = 0
	for _, v in w do
		total += v
	end
	return if total > 0 then (w[index] or 0) / total * 100 else nil
end
local MarkSkinsSeen = Remotes:WaitForChild("MarkSkinsSeen") :: RemoteEvent

local hub = workspace:WaitForChild("Hub")
-- eggs sold in a zone instead of by a hub machine (Config.Zones)
local zoneEggs: { [string]: boolean } = {}
for _, z in (Config :: any).Zones and (Config :: any).Zones.List or {} do
	zoneEggs[z.Egg] = true
end
local machine = if zoneEggs.Briefcase then hub:FindFirstChild("EggMachine") else hub:WaitForChild("EggMachine")
local rollPrompt = machine and machine:FindFirstChild("RollPrompt", true) :: ProximityPrompt?
-- themed egg Id -> its machine model
local themedMachines: { [string]: Instance } = {}
for _, def in Config.Eggs.Themed do
	local m = if zoneEggs[def.Id] then hub:FindFirstChild(def.Machine) else hub:WaitForChild(def.Machine, 10)
	if m then
		themedMachines[def.Id] = m
	elseif not zoneEggs[def.Id] then
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
	local egg = machine and machine:FindFirstChild("Egg")
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

-- Lucky Eggs (Robux pass, Server.ShopService) and golden zone eggs: luck x the Rare, Epic and Legendary chances,
-- taken from Common / Uncommon (Formulas.luckyWeights), so Mythic keeps its odds and Supreme stays exactly 1 in 2500.
local function luckyWeights(player: Player, weights: { number }?, extraLuck: number?): { number }?
	local ShopService = require(Server.ShopService) :: any
	local luck = ShopService.effect(player, "LuckyEggs", 1) * (extraLuck or 1)
	if luck == 1 then
		return weights
	end
	return Formulas.luckyWeights(weights or Formulas.skinWeights(), luck)
end

local function roomFor(player: Player, data: any): number
	local ShopService = require(Server.ShopService) :: any
	return Config.Lawyers.MaxOwned + ShopService.effect(player, "BigFirm", 0) - PlayerData.lawyerCount(data)
end

-- opts.paid: the egg was already bought (in a zone) - no price, no free egg / token; opts.golden: a golden zone
-- egg (better odds); opts.tokensOnly: only hatch if it's the free first egg or a reward token (never charge);
-- opts.at: where the egg hatched (for the Rare / Legendary burst). Returns whether an egg hatched.
type RollOpts = { paid: boolean?, golden: boolean?, tokensOnly: boolean?, at: Vector3? }
local function onRoll(player: Player, eggId: string?, opts: RollOpts?): boolean
	local o: RollOpts = opts or {}
	local themed = Formulas.themedEgg(eggId)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local t = os.clock()
	if lastRoll[player] and t - lastRoll[player] < ROLL_COOLDOWN then
		return false
	end
	-- egg tiers: a themed machine only works once the player has earned its UnlockEarned (lifetime). A zone egg
	-- that was already bought (o.paid) hatches anyway: its zone's Law License is the gate there (Config.Zones).
	if themed and not o.paid and not Formulas.eggUnlocked(themed.Id, data.Stats and data.Stats.CoinsEarned) then
		EggHatched:FireClient(player, { ok = false, reason = "locked", egg = themed.Id, need = themed.UnlockEarned })
		return false
	end
	if roomFor(player, data) <= 0 then
		EggHatched:FireClient(player, { ok = false, reason = "full" })
		return false
	end

	-- the free egg and reward tokens only work on the Briefcase Egg
	local free = not o.paid and not themed and Config.Eggs.FreeFirstEgg and not data.Eggs.FreeUsed
	-- Reward tokens: a Rare token always hatches Rare; a free token rolls normally. Both skip the price.
	local rareToken = not o.paid and not themed and not free and (data.Eggs.RareTokens or 0) > 0
	local freeToken = not o.paid and not themed and not free and not rareToken and (data.Eggs.FreeTokens or 0) > 0
	if o.tokensOnly and not (free or rareToken or freeToken) then
		return false
	end
	local price = if themed then Formulas.themedEggPrice(themed.Id, priceCount(data), prestigeLevel(data))
		else Formulas.eggPrice(priceCount(data), prestigeLevel(data))
	if not o.paid and not free and not rareToken and not freeToken and not PlayerData.spendCoins(player, price) then
		EggHatched:FireClient(player, { ok = false, reason = "coins", price = price, egg = if themed then themed.Id else nil })
		return false
	end
	lastRoll[player] = t

	local rarity
	local chance: number? = nil -- (the odds this egg had of rolling that rarity)
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
	else
		if freeToken then
			data.Eggs.FreeTokens -= 1
		end
		data.Eggs.Opened += 1
		data.Eggs.RunOpened = (data.Eggs.RunOpened or 0) + 1
		-- a golden zone egg stacks its luck (Config.Zones.Golden.Luck) on top of the Lucky Eggs pass
		local goldenLuck = if o.golden then (((Config :: any).Zones and (Config :: any).Zones.Golden.Luck) or 1) else 1
		local w = luckyWeights(player, if themed then themed.Weights else nil, goldenLuck)
		rarity = Formulas.rollSkin(rng, w)
		chance = weightShare(w, rarity)
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
	-- (spawned: badge calls yield / can throw, and must never stop the hatch after the coins are spent)
	task.spawn(require(Server.BadgeAwards).award, player, "FirstEgg")
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
	local fancy = rarityId == "Legendary" or rarityId == "Mythic" or rarityId == "Supreme"
	if burstKind and not o.at then -- (every incubator hatch has its own show since v5: HatchShow below)
		local from = if themed and themedMachines[themed.Id] then themedMachines[themed.Id] else machine
		task.delay(if rarity >= (Config.Eggs.PityRarity or 5) then 6.5 else 5.1, function()
			local at = o.at -- an incubator passes where the egg hatched; a hub machine bursts over itself
			if not at and from and from.Parent then
				local box, size = (from :: Model):GetBoundingBox()
				at = box.Position + Vector3.new(0, size.Y / 2 + 2, 0)
			end
			if at then
				Effects.burst(at, burstKind)
			end
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
		at = o.at, -- where it hatched (the incubator): a Legendary+ hatch plays out there, in the world
		golden = o.golden == true,
		chance = chance,
	})
	if o.at and HatchShow then -- (v5: everyone near the incubator watches every hatch there, StarterPlayerScripts.Eggs)
		HatchShow:FireAllClients({ userId = player.UserId, at = o.at, egg = if themed then themed.Id else nil, golden = o.golden == true, rarity = rarity, skinId = id })
	end
	if (rarityId == "Mythic" or rarityId == "Supreme") and HatchAnnounce then
		local skin = Formulas.getSkin(id)
		HatchAnnounce:FireAllClients({ userId = player.UserId, name = player.DisplayName, lawyer = if skin then skin.Name else id, rarity = rarity, chance = chance })
	end
	return true
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

if rollPrompt then
	rollPrompt.Triggered:Connect(function(player)
		onRoll(player, nil)
	end)
end
for id, m in themedMachines do
	local prompt = m:FindFirstChild("RollPrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(player)
			onRoll(player, id)
		end)
	end
end
-- the incubators (Server.ZoneService) hatch zone eggs through this
local ServerStorage = game:GetService("ServerStorage")
local api = ServerStorage:FindFirstChild("EggApi") :: BindableFunction?
if not api then
	local b = Instance.new("BindableFunction")
	b.Name = "EggApi"
	b.Parent = ServerStorage
	api = b
end
(api :: BindableFunction).OnInvoke = function(action: string, player: Player, ...): any
	local args = { ... }
	if action == "hatch" then
		local eggId = args[1]
		return onRoll(player, if eggId == "Briefcase" then nil else eggId, { paid = true, golden = args[2] == true, at = args[3] })
	elseif action == "free" then
		return onRoll(player, nil, { tokensOnly = true, at = args[1] })
	elseif action == "price" then
		local data = PlayerData.get(player)
		local eggId = args[1]
		if not data then
			return math.huge
		end
		-- args[2]: eggs already bought but not hatched yet (a zone bag), so each one in a bag costs the next step of
		-- the ramp like the machine would (audit 2026-10-12: a full bag was bought at one price, ~26% off for 5)
		local ahead = if typeof(args[2]) == "number" and args[2] == args[2] then math.clamp(math.floor(args[2]), 0, 100) else 0
		local count = priceCount(data) + ahead
		return if eggId and eggId ~= "Briefcase" then Formulas.themedEggPrice(eggId, count, prestigeLevel(data)) else Formulas.eggPrice(count, prestigeLevel(data))
	elseif action == "room" then
		local data = PlayerData.get(player)
		return if data then roomFor(player, data) else 0
	end
	return nil
end
api:SetAttribute("Ready", true)
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
