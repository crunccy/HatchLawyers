--!strict
-- Short-term goals (Config.Goals). Other services call GoalService.track(player, kind, amount) when
-- something happens; finished goals pay coins (minutes of the player's income) and are replaced.
-- Mirrored to the client as the "Goals" attribute: JSON list of { Id, Progress, Target, Text }.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)
local RewardsService = require(script.Parent.RewardsService)

local RewardGranted = ReplicatedStorage.Remotes.RewardGranted :: RemoteEvent

local GoalService = {}

local rng = Random.new()
local defs: { [string]: { [string]: any } } = {}
for _, def in Config.Goals.List do
	defs[def.Id] = def
end

local function describe(def: { [string]: any }): string
	return string.format(def.Text, def.Target)
end

local function sync(player: Player, data: PlayerData.Data)
	local list = {}
	for _, goal in data.Goals.Active do
		local def = defs[goal.Id]
		if def then
			table.insert(list, { Id = goal.Id, Progress = goal.Progress, Target = def.Target, Text = describe(def) })
		end
	end
	player:SetAttribute("Goals", HttpService:JSONEncode(list))
end

-- Fills empty slots with random goals that aren't already active (and drops unknown ids).
local function fill(data: PlayerData.Data, exclude: string?)
	local active = data.Goals.Active
	for i = #active, 1, -1 do
		if not defs[active[i].Id] then
			table.remove(active, i)
		end
	end
	while #active < Config.Goals.Slots do
		local choices = {}
		for _, def in Config.Goals.List do
			local taken = def.Id == exclude
			for _, goal in active do
				if goal.Id == def.Id then
					taken = true
				end
			end
			if not taken then
				table.insert(choices, def.Id)
			end
		end
		if #choices == 0 then
			break
		end
		table.insert(active, { Id = choices[rng:NextInteger(1, #choices)], Progress = 0 })
	end
end

function GoalService.track(player: Player, kind: string, amount: number?)
	local data = PlayerData.get(player)
	if not data or not data.Goals then
		return
	end
	local changed = false
	local finished = {}
	for index, goal in data.Goals.Active do
		local def = defs[goal.Id]
		if def and def.Kind == kind then
			goal.Progress = math.min(goal.Progress + (amount or 1), def.Target)
			changed = true
			if goal.Progress >= def.Target then
				table.insert(finished, index)
			end
		end
	end
	-- pay out and replace finished goals (highest index first so removals don't shift the rest)
	for i = #finished, 1, -1 do
		local goal = table.remove(data.Goals.Active, finished[i]) :: { Id: string, Progress: number }
		local def = defs[goal.Id]
		local coins = math.max(Config.Rewards.MinCoins, math.floor(RewardsService.incomePerMinute(data) * def.Minutes))
		data.Coins += coins
		data.Goals.Completed += 1
		fill(data, goal.Id)
		RewardGranted:FireClient(player, { kind = "Goal", text = "+" .. Formulas.formatCoins(coins) .. " coins", goal = describe(def) })
	end
	if #finished > 0 then
		PlayerData.sync(player)
	end
	if changed then
		sync(player, data)
	end
end

local function onPlayerAdded(player: Player)
	local deadline = os.clock() + 120
	while player.Parent and not PlayerData.get(player) and os.clock() < deadline do
		task.wait(0.5)
	end
	local data = PlayerData.get(player)
	if data then
		data.Goals = data.Goals or { Active = {}, Completed = 0 }
		fill(data)
		sync(player, data)
	end
end

function GoalService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return GoalService
