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
--   /islands on|off                  (Studio only) run the egg zones on the redesign islands instead of the lane, for
--                                    this playtest (Server.ZoneMap; the real switch is Config.Zones.Islands.Enabled)
--   /island [name]                   visit a world-redesign island (Workspace.WorldRedesign, built 2026-10-19 from
--                                    environment-redesign/; nothing is wired there yet). Reset to come back.
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

local ADMINS = {
	[2234491534] = true, -- crnuch (place owner)
	[11776753629] = true, -- mr_blox174
}
local function isAdmin(player: Player): boolean
	return ADMINS[player.UserId] == true or RunService:IsStudio()
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
	note(player, "/hatch <rarity> [egg] [golden] (preview)  |  /eggs <count> [egg] [golden]  |  /coins <amount>  |  /island [name]  |  /islands on|off")
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

-- /island [name]: the redesign islands (Workspace.WorldRedesign). Lands on the island's south side (its arrival side),
-- 150 studs south of its centre, on whatever the ground is there; streams the spot in first.
COMMANDS.island = function(player, args)
	local world = workspace:FindFirstChild("WorldRedesign")
	if not world then
		note(player, "No redesign islands in this place yet")
		return
	end
	local want = args[1] and string.lower(args[1])
	local names, target = {}, nil
	for _, m in world:GetChildren() do
		if m:IsA("Model") then
			table.insert(names, string.lower(m.Name))
			if want and not target and string.find(string.lower(m.Name), want, 1, true) then
				target = m
			end
		end
	end
	table.sort(names)
	if not target then
		note(player, "Which island? " .. table.concat(names, " / ") .. "   e.g. /island ocean")
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local above = (target :: Model):GetPivot() * CFrame.new(0, 300, 150)
	pcall(function()
		player:RequestStreamAroundAsync(above.Position - Vector3.new(0, 300, 0), 10)
	end)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { target }
	params.RespectCanCollide = true -- (land on the ground, not a tree top or a cloud)
	local hit = workspace:Raycast(above.Position, Vector3.new(0, -600, 0), params)
	local ground = if hit then hit.Position else above.Position - Vector3.new(0, 300, 0)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(ground + Vector3.new(0, 5, 0))
	note(player, "Welcome to " .. target.Name .. " (reset to go back)")
end

-- /islands on|off (Studio only): the egg zones on the redesign islands for this playtest (Server.ZoneMap reads the
-- workspace attribute IslandsOn; ZoneService + TravelServer rebind). Live servers only follow Config.Zones.Islands.
COMMANDS.islands = function(player, args)
	if not RunService:IsStudio() then
		note(player, "Only in Studio. The live switch is Config.Zones.Islands.Enabled")
		return
	end
	local word = args[1] and string.lower(args[1])
	if word ~= "on" and word ~= "off" then
		note(player, "Islands are " .. (if workspace:GetAttribute("IslandsOn") then "ON" else "OFF") .. ".  /islands on  or  /islands off")
		return
	end
	workspace:SetAttribute("IslandsOn", word == "on")
	note(player, if word == "on" then "Egg zones now on the islands: TRAVEL to one, RETURN HOME with your eggs" else "Egg zones back on the lane")
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
