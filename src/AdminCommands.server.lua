--!strict
-- AdminCommands (ServerScriptService.AdminCommands, 2026-10-13, mr.robe: "create admin commands for us to use (ie. if i
-- want to see a legendary egg hatching i should be able to will it into existence ...)").
-- Chat commands for the two of us (ADMINS) and for anyone in a Studio playtest. Type them in chat, with / or ;
--   /hatch <rarity> [egg] [golden]   PREVIEW a hatch at your incubator: the full animation, nothing is saved and no
--                                    lawyer is added. rarity = common / uncommon / rare / legendary (or 1-4; Epic,
--                                    Mythic, Supreme once they exist), egg = briefcase / pet / brainrot / food /
--                                    ocean / space. e.g. "/hatch legendary space golden"
--   /eggs <count> [egg] [golden]     put real eggs in your arms (up to 30, past your carry limit) to hatch at the
--                                    incubator - normal random odds, real lawyers
--   /coins <amount>                  add coins (1e9, 5m, 2b, 3t, 1qd ... work)
--   /help                            this list
-- Answers show as a note on screen (Remotes.Zones "Note"). Commands are TextChatCommands (so they never show in chat);
-- ";" versions go through Player.Chatted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local Server = ServerScriptService:WaitForChild("Server")
local PlayerData = require(Server:WaitForChild("PlayerData") :: ModuleScript) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggHatched = Remotes:WaitForChild("EggHatched") :: RemoteEvent
local ZonesRemote = Remotes:WaitForChild("Zones") :: RemoteEvent
local PromoControl = Remotes:FindFirstChild("PromoControl") :: RemoteEvent?
if not PromoControl then
	local remote = Instance.new("RemoteEvent")
	remote.Name = "PromoControl"
	remote.Parent = Remotes
	PromoControl = remote
end

local ADMINS = {
	[2234491534] = true, -- crnuch (place owner)
	[11776753629] = true, -- mr_blox174
}
local function isAdmin(player: Player): boolean
	return ADMINS[player.UserId] == true or RunService:IsStudio()
end

local function isPromo(player: Player): boolean
	return PlayerData.isPromo(player)
end

local function note(player: Player, text: string)
	ZonesRemote:FireClient(player, "Note", text)
end

local EGGS = { briefcase = "Briefcase", pet = "Pet", brainrot = "Brainrot", food = "Food", ocean = "Ocean", space = "Space" }

local function rarityIndex(word: string?): number?
	if not word then
		return nil
	end
	local n = tonumber(word)
	if n and Config.Eggs.Skins[n] then
		return n
	end
	for i, tier in Config.Eggs.Skins do
		if string.lower(tier.Id) == string.lower(word) or string.sub(string.lower(tier.Id), 1, #word) == string.lower(word) then
			return i
		end
	end
	return nil
end

local SUFFIX = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qd = 1e15, qn = 1e18, sx = 1e21 }
local function amount(word: string?): number?
	if not word then
		return nil
	end
	local n = tonumber(word)
	if n then
		return n
	end
	local num, suf = string.match(string.lower(word), "^([%d%.]+)(%a+)$")
	if num and SUFFIX[suf] then
		return (tonumber(num) :: number) * SUFFIX[suf]
	end
	return nil
end

-- the incubator a hatch plays at: your own nearest one
local function myIncubator(player: Player): Model?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local best, bestD = nil, math.huge
	for _, m in CollectionService:GetTagged("Incubator") do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			local node: Instance? = m
			local owner = nil
			while node do
				local id = node:GetAttribute("OwnerUserId")
				if type(id) == "number" then
					owner = id
					break
				end
				node = node.Parent
			end
			if owner == player.UserId then
				local d = if root then (m:GetPivot().Position - root.Position).Magnitude else 0
				if d < bestD then
					best, bestD = m, d
				end
			end
		end
	end
	return best
end

local COMMANDS: { [string]: (player: Player, args: { string }) -> () } = {}

COMMANDS.help = function(player)
	note(player, "/hatch <rarity> [egg] [golden] (preview)  |  /eggs <count> [egg] [golden]  |  /coins <amount>")
end

COMMANDS.hatch = function(player, args)
	local r = rarityIndex(args[1])
	if not r then
		local names = {}
		for _, tier in Config.Eggs.Skins do
			table.insert(names, string.lower(tier.Id))
		end
		note(player, "Which rarity? " .. table.concat(names, " / ") .. "   e.g. /hatch legendary space golden")
		return
	end
	local egg, golden = "Briefcase", false
	for i = 2, #args do
		local w = string.lower(args[i])
		if EGGS[w] then
			egg = EGGS[w]
		elseif w == "golden" or w == "gold" then
			golden = true
		end
	end
	local themed = Formulas.themedEgg(egg)
	local skinId = Formulas.rollSkinId(Random.new(), r, if themed then themed.Id else nil)
		or Formulas.rollSkinId(Random.new(), r, nil)
	if not skinId then
		note(player, "No " .. Config.Eggs.Skins[r].Id .. " lawyer for that egg yet")
		return
	end
	local inc = myIncubator(player)
	local at = if inc and inc.PrimaryPart then inc.PrimaryPart.Position + Vector3.new(0, 5, 0) else nil
	-- a fake result: the client plays the whole hatch, nothing is saved (no uid -> the panel offers MY LAWYERS)
	EggHatched:FireClient(player, {
		ok = true,
		preview = true,
		skinId = skinId,
		lawyerId = skinId,
		rarity = r,
		skills = {},
		egg = if themed then themed.Id else nil,
		isNew = false,
		at = at,
		golden = golden,
		chance = nil,
	})
end

COMMANDS.eggs = function(player, args)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local count = math.clamp(math.floor(tonumber(args[1]) or 1), 1, 30)
	local egg, golden = "Briefcase", false
	for i = 2, #args do
		local w = string.lower(args[i])
		if EGGS[w] then
			egg = EGGS[w]
		elseif w == "golden" or w == "gold" then
			golden = true
		end
	end
	data.Zones = data.Zones or { License = 0, Carry = 1, Speed = 1, Carried = {} }
	data.Zones.Carried = data.Zones.Carried or {}
	for _ = 1, count do
		table.insert(data.Zones.Carried, { Egg = egg, Golden = golden or nil })
	end
	local ZoneService = require(Server:WaitForChild("ZoneService") :: ModuleScript) :: any
	ZoneService.sync(player)
	note(player, string.format("+%d %s%s Egg%s in your arms - hatch them at your incubator", count, if golden then "Golden " else "", egg, if count > 1 then "s" else ""))
end

COMMANDS.coins = function(player, args)
	local n = amount(args[1])
	if not n or n <= 0 then
		note(player, "How many? e.g. /coins 5m")
		return
	end
	PlayerData.addCoins(player, n)
	note(player, "+" .. Formulas.formatCoins(n) .. " coins")
end

local function promoNote(player: Player, text: string)
	note(player, "[Promo] " .. text)
end

local function promoOnly(player: Player): any?
	if not isPromo(player) then
		return nil
	end
	return PlayerData.get(player)
end

COMMANDS.promo = function(player, args)
	local action = string.lower(args[1] or "help")
	local data = promoOnly(player)
	if not data then
		return
	end
	if action == "help" then
		promoNote(player, "/promo resources | hatch <rarity> [egg] [golden] | lawyer <id> [golden] | eggs [egg] [count] [golden] | lawyers [search] | firm max | worlds | world <id|home> | gui [hide|show|toggle] | cam [on|off|toggle]")
	elseif action == "resources" then
		data.Coins = 1e30
		data.Eggs.RareTokens = 999
		player:SetAttribute("RareEggTokens", 999)
		player:SetAttribute("FreeEgg", true)
		PlayerData.sync(player)
		promoNote(player, "Sandbox resources topped up. This profile is temporary and never saved.")
	elseif action == "eggs" then
		local egg, count, golden = "Briefcase", 30, false
		for _, word in args do
			local w = string.lower(word)
			if EGGS[w] then egg = EGGS[w]
			elseif tonumber(w) then count = math.clamp(math.floor(tonumber(w) :: number), 1, 30)
			elseif w == "golden" or w == "gold" then golden = true end
		end
		data.Zones.Carried = {}
		for _ = 1, count do
			table.insert(data.Zones.Carried, { Egg = egg, Golden = golden or nil })
		end
		PlayerData.sync(player)
		local ZoneService = require(Server:WaitForChild("ZoneService") :: ModuleScript) :: any
		ZoneService.sync(player)
		promoNote(player, string.format("Added %d %s%s eggs to your temporary profile.", count, if golden then "golden " else "", egg))
	elseif action == "lawyers" then
		local filter = string.lower(args[2] or "")
		local matches = {}
		for _, skin in Config.SkinCatalog do
			if filter == "" or string.find(string.lower(skin.Id .. " " .. skin.Name), filter, 1, true) then
				table.insert(matches, skin.Id)
			end
		end
		table.sort(matches)
		local shown = {}
		for i = 1, math.min(20, #matches) do table.insert(shown, matches[i]) end
		promoNote(player, if #matches == 0 then "No matching lawyer. Search by name or Id." else table.concat(shown, ", ") .. if #matches > #shown then " … narrow with /promo lawyers <search>" else "")
	elseif action == "hatch" then
		local rarity = rarityIndex(args[2])
		if not rarity then
			local names = {}
			for _, tier in Config.Eggs.Skins do table.insert(names, string.lower(tier.Id)) end
			promoNote(player, "Use /promo hatch <" .. table.concat(names, "|") .. "> [egg] [golden].")
			return
		end
		local egg = "Briefcase"
		local golden = false
		for i = 3, #args do
			local word = string.lower(args[i])
			if EGGS[word] then egg = EGGS[word]
			elseif word == "golden" or word == "gold" then golden = true end
		end
		local themed = Formulas.themedEgg(egg)
		local pool = {}
		for _, skin in Config.SkinCatalog do
			if skin.Rarity == rarity and skin.Egg == (if themed then themed.Id else nil) then table.insert(pool, skin.Id) end
		end
		if #pool == 0 then promoNote(player, "No " .. Config.Eggs.Skins[rarity].Id .. " lawyer in that egg yet.") return end
		local skinId = pool[Random.new():NextInteger(1, #pool)]
		local inc = myIncubator(player)
		local at = if inc and inc.PrimaryPart then inc.PrimaryPart.Position + Vector3.new(0, 5, 0) else nil
		EggHatched:FireClient(player, { ok = true, preview = true, skinId = skinId, lawyerId = skinId, rarity = rarity, skills = {}, egg = if themed then themed.Id else nil, isNew = false, at = at, golden = golden, chance = nil })
	elseif action == "lawyer" then
		local skinId = args[2]
		local skin = Formulas.getSkin(skinId)
		if not skin then
			promoNote(player, "Use /promo lawyers [search] to find a lawyer Id.")
			return
		end
		local egg = skin.Egg or "Briefcase"
		local golden = table.find(args, "golden") ~= nil or table.find(args, "gold") ~= nil
		local inc = myIncubator(player)
		local at = if inc and inc.PrimaryPart then inc.PrimaryPart.Position + Vector3.new(0, 5, 0) else nil
		EggHatched:FireClient(player, { ok = true, preview = true, skinId = skin.Id, lawyerId = skin.Id, rarity = skin.Rarity, skills = {}, egg = skin.Egg, isNew = false, at = at, golden = golden, chance = nil })
	elseif action == "firm" and string.lower(args[2] or "") == "max" then
		data.Firm.Segments = Config.Firm.MaxSegments
		data.Prestige.Level = (Config.Prestige and Config.Prestige.TowerLevel) or 1
		for index = #data.Desks + 1, Config.Firm.MaxSegments * 2 do
			table.insert(data.Desks, { Level = Config.Lawyer.MaxLevel })
		end
		for _, desk in data.Desks do desk.Level = Config.Lawyer.MaxLevel end
		PlayerData.sync(player)
		local PlotService = require(Server:WaitForChild("PlotService") :: ModuleScript) :: any
		local DeskService = require(Server:WaitForChild("DeskService") :: ModuleScript) :: any
		PlotService.rebuild(player)
		DeskService.buildDesks(player)
		DeskService.dress(player)
		promoNote(player, "Max firm preview is ready.")
	elseif action == "world" then
		local target = args[2]
		if not target then promoNote(player, "Use /promo world home or an id from /promo worlds.") return end
		local canonical = if string.lower(target) == "home" then "Home" else nil
		for _, zone in Config.Zones.List do
			if string.lower(zone.Id) == string.lower(target) then canonical = zone.Id break end
		end
		if not canonical then
			promoNote(player, "Unknown world. Use /promo worlds to list valid ids.")
			return
		end
		(PromoControl :: RemoteEvent):FireClient(player, "travel", canonical)
	elseif action == "worlds" then
		local ids = { "home" }
		for _, zone in Config.Zones.List do table.insert(ids, string.lower(zone.Id)) end
		promoNote(player, "World ids: " .. table.concat(ids, ", "))
	elseif action == "gui" or action == "cam" or action == "camera" then
		local mode = string.lower(args[2] or "toggle")
		if mode ~= "hide" and mode ~= "show" and mode ~= "on" and mode ~= "off" and mode ~= "toggle" then
			promoNote(player, "Use /promo " .. (action == "gui" and "gui [hide|show|toggle]" or "cam [on|off|toggle]"))
			return
		end
		(PromoControl :: RemoteEvent):FireClient(player, if action == "gui" then "gui" else "cam", mode)
	else
		promoNote(player, "Unknown command. Type /promo help.")
	end
end

local lastRun: { [Player]: number } = {}
local function run(player: Player, text: string)
	if not isAdmin(player) then
		return
	end
	local words = string.split(string.gsub(text, "^%s*[/;]", ""), " ")
	local args = {}
	for _, w in words do
		if w ~= "" then
			table.insert(args, w)
		end
	end
	local name = table.remove(args, 1)
	local fn = name and COMMANDS[string.lower(name)]
	if not fn then
		return
	end
	local t = os.clock()
	if lastRun[player] and t - lastRun[player] < 0.4 then
		return
	end
	lastRun[player] = t
	local ok, err = pcall(fn, player, args)
	if not ok then
		warn("[AdminCommands]", name, err)
		note(player, "That didn't work: " .. tostring(err))
	end
end

-- /commands: TextChatCommands (they never show in chat). Triggered fires here on the server.
local folder = Instance.new("Folder")
folder.Name = "AdminCommands"
folder.Parent = TextChatService
for name in COMMANDS do
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "Admin_" .. name
	cmd.PrimaryAlias = "/" .. name
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source: TextSource, text: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			run(player, text)
		end
	end)
end

-- ;commands through ordinary chat
local function hook(player: Player)
	player.Chatted:Connect(function(message)
		if string.sub(message, 1, 1) == ";" then
			run(player, message)
		end
	end)
end
Players.PlayerAdded:Connect(hook)
for _, p in Players:GetPlayers() do
	hook(p)
end
