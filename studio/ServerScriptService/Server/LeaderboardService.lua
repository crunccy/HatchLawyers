--!strict
-- Global leaderboards on the four boards in Workspace.Hub.Leaderboards (Richest firms by all-time
-- coins earned, most cases won, top lawyer level, biggest single payout).
-- Scores go to OrderedDataStores every SAVE_INTERVAL and when a player leaves; the top 10 are read
-- every REFRESH_INTERVAL. OrderedDataStores only hold integers below 2^63, and late-game coin totals
-- can pass that, so coin boards store log10(value) * 1e6 and decode it for display.
-- If data stores are unavailable (Studio without API access, or an outage) the boards rank the
-- players in this server instead, so they're never empty.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)

local SAVE_INTERVAL = 120
local REFRESH_INTERVAL = 60
local TOP = 10
local LOG_SCALE = 1e6

type BoardDef = {
	id: string,
	store: string,
	logScale: boolean,
	value: (data: PlayerData.Data) -> number,
	format: (value: number) -> string,
}

local function coins(value: number): string
	return Formulas.formatCoins(value)
end

local BOARDS: { BoardDef } = {
	{ id = "Richest", store = "LB_CoinsEarned_v1", logScale = true, value = function(d) return d.Stats.CoinsEarned end, format = coins },
	{ id = "Wins", store = "LB_Wins_v1", logScale = false, value = function(d) return d.Stats.Wins end, format = function(v) return tostring(math.floor(v)) .. " wins" end },
	{
		id = "TopLawyer",
		store = "LB_TopLawyer_v1",
		logScale = false,
		value = function(d)
			local best = 0
			for _, desk in d.Desks do -- best office level (v12: levels belong to offices)
				best = math.max(best, desk.Level)
			end
			return best
		end,
		format = function(v) return "Lv " .. math.floor(v) end,
	},
	{ id = "BestPayout", store = "LB_BestPayout_v1", logScale = true, value = function(d) return d.Stats.BestPayout end, format = coins },
}

local LeaderboardService = {}

local stores: { [string]: OrderedDataStore } = {}
local storesOk = true
local names: { [number]: string } = {}

local function encode(def: BoardDef, value: number): number
	if def.logScale then
		return if value >= 1 then math.floor(math.log10(value) * LOG_SCALE) else 0
	end
	return math.floor(value)
end

local function decode(def: BoardDef, stored: number): number
	return if def.logScale then 10 ^ (stored / LOG_SCALE) else stored
end

local function nameFor(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then name else "Player"
	return names[userId]
end

local function storeFor(def: BoardDef): OrderedDataStore?
	if not storesOk then
		return nil
	end
	if not stores[def.id] then
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, def.store)
		if not ok then
			storesOk = false
			return nil
		end
		stores[def.id] = store
	end
	return stores[def.id]
end

-- Reads the scores right away (no yielding), then writes them in the background. Main calls this
-- on leave *before* PlayerData.release, which stops handing out the player's data.
function LeaderboardService.save(player: Player)
	local data = PlayerData.get(player)
	if not data or not storesOk then
		return
	end
	local key = "u" .. player.UserId
	local snapshot = {}
	for _, def in BOARDS do
		snapshot[def] = encode(def, def.value(data))
	end
	task.spawn(function()
		for def, value in snapshot do
			local store = storeFor(def)
			if not store then
				return
			end
			-- keep the best score ever (prestige resets lawyer levels, but the board shouldn't drop)
			local ok, err = pcall(store.UpdateAsync, store, key, function(current)
				return math.max(if type(current) == "number" then current else 0, value)
			end)
			if not ok then
				warn("[Leaderboards] save failed:", err)
				if tostring(err):find("Studio", 1, true) or tostring(err):find("403", 1, true) then
					storesOk = false -- no API access here; use this server's players instead
					return
				end
			end
		end
	end)
end
local save = LeaderboardService.save

type Entry = { name: string, value: number }

local function topGlobal(def: BoardDef): { Entry }?
	local store = storeFor(def)
	if not store then
		return nil
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, TOP)
	if not ok then
		local err = tostring(pages)
		if err:find("Studio", 1, true) or err:find("403", 1, true) then
			storesOk = false -- no API access here: stop retrying and rank this server's players
		end
		return nil
	end
	local entries = {}
	for _, item in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(string.sub(item.key, 2))
		if userId then
			table.insert(entries, { name = nameFor(userId), value = decode(def, item.value) })
		end
	end
	return entries
end

local function topLocal(def: BoardDef): { Entry }
	local entries = {}
	for _, player in Players:GetPlayers() do
		local data = PlayerData.get(player)
		if data then
			table.insert(entries, { name = player.DisplayName, value = def.value(data) })
		end
	end
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)
	return entries
end

local function paint(def: BoardDef, entries: { Entry }, global: boolean)
	local boards = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("Leaderboards")
	local board = boards and boards:FindFirstChild(def.id)
	local list = board and board:FindFirstChild("List", true)
	if not list then
		return
	end
	for rank = 1, TOP do
		local row = list:FindFirstChild("Row" .. rank)
		if row then
			local entry = entries[rank]
			local nameLabel = row:FindFirstChild("PlayerName") :: TextLabel
			local valueLabel = row:FindFirstChild("Value") :: TextLabel
			nameLabel.Text = if entry then entry.name else "---"
			valueLabel.Text = if entry then def.format(entry.value) else ""
		end
	end
	local footer = list:FindFirstChild("Footer") :: TextLabel?
	if footer then
		footer.Text = if global then "All players · updates every minute" else "Players in this server"
	end
end

local function refresh()
	for _, def in BOARDS do
		local entries = topGlobal(def)
		if entries then
			paint(def, entries, true)
		else
			paint(def, topLocal(def), false)
		end
	end
end

function LeaderboardService.start()
	task.spawn(function()
		local sinceSave = 0
		while true do
			local ok, err = pcall(refresh)
			if not ok then
				warn("[LeaderboardService] refresh failed:", err) -- (audit 2026-10-12: one error stopped the boards and saves)
			end
			task.wait(REFRESH_INTERVAL)
			sinceSave += REFRESH_INTERVAL
			if sinceSave >= SAVE_INTERVAL then
				sinceSave = 0
				for _, player in Players:GetPlayers() do
					local okSave, errSave = pcall(save, player)
					if not okSave then
						warn("[LeaderboardService] save failed:", errSave)
					end
				end
			end
		end
	end)
	-- first boards shortly after someone joins, so they aren't stuck on "Loading..."
	Players.PlayerAdded:Connect(function()
		task.delay(8, refresh)
	end)
end

return LeaderboardService
