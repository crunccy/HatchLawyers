--!strict
-- Daily streak rewards and playtime gifts (Config.Rewards).
-- Daily: one claim per UTC day. Claiming the day after your last claim continues the streak;
-- skipping a day restarts it at day 1. The 7 rewards repeat.
-- Playtime: the client pings Remotes.Activity on input; every second a player has been active within
-- Config.Rewards.ActiveWindow banks one second, and every PlaytimeInterval banked seconds pays a gift.
-- Coin rewards are minutes of the player's own expected income, so they scale with progress.
-- Mirrored attributes: DailyStreak, DailyLastDay, PlaytimeActive, CoinsPerMinute.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)

local Remotes = ReplicatedStorage.Remotes
local ClaimDaily = Remotes.ClaimDaily :: RemoteFunction
local Activity = Remotes.Activity :: RemoteEvent
local RewardGranted = Remotes.RewardGranted :: RemoteEvent

local DAY = 86400
local CLAIM_COOLDOWN = 1
local INCOME_REFRESH = 30

local RewardsService = {}

local lastActive: { [Player]: number } = {}
local lastClaim: { [Player]: number } = {}

local function today(): number
	return os.time() // DAY
end

-- Expected coins per minute across every office with a lawyer in it, with every buff that applies to
-- every case (office tier, the lawyer's skills and power, the Manager). Excludes courtroom bonuses,
-- like the economy sim.
function RewardsService.incomePerMinute(data: PlayerData.Data): number
	local total = 0
	for index, desk in data.Desks do
		local lawyer = PlayerData.lawyerAt(data, index)
		if not lawyer then
			continue
		end
		local sources: { Formulas.BuffSource } = {
			{ payout = Config.Desks.Tiers[Formulas.officeTier(desk.Level)].PayoutBonus },
		}
		for _, source in Formulas.skillSources(lawyer.Skills, nil) do
			table.insert(sources, source)
		end
		local levels = data.Manager and data.Manager.Levels
		for _, source in Formulas.managerSources(levels) do
			table.insert(sources, source)
		end
		local weights = Formulas.clientWeightsFor(lawyer.Skills, Formulas.managerValue(levels, "rareClients"))
		total += Formulas.expectedIncomePerSecond(desk.Level, Formulas.combineBuffs(sources), weights)
			* Formulas.lawyerEarn(lawyer.Id, lawyer.Stars)
	end
	return total * 60 * Formulas.prestigeMultiplier(data.Prestige and data.Prestige.Level)
end

local function coinsFor(data: PlayerData.Data, minutes: number): number
	return math.max(Config.Rewards.MinCoins, math.floor(RewardsService.incomePerMinute(data) * minutes))
end

local function sync(player: Player, data: PlayerData.Data)
	player:SetAttribute("DailyStreak", data.Daily.Streak)
	player:SetAttribute("DailyLastDay", data.Daily.LastDay)
	player:SetAttribute("PlaytimeActive", data.Playtime.Active)
	player:SetAttribute("CoinsPerMinute", RewardsService.incomePerMinute(data))
end

-- The highest-level office that has a lawyer in it (nil if none do).
local function bestDesk(data: PlayerData.Data): number?
	local best = nil
	for index, desk in data.Desks do
		if desk.Lawyer and data.Lawyers[desk.Lawyer] and (not best or desk.Level > data.Desks[best].Level) then
			best = index
		end
	end
	return best
end

-- Applies one Config.Rewards entry and returns a short description for the client's pop-up.
local function grant(player: Player, data: PlayerData.Data, reward: { [string]: any }): string
	local text
	if reward.Kind == "Coins" then
		local coins = coinsFor(data, reward.Minutes)
		data.Coins += coins -- not case income, so it stays out of Stats.CoinsEarned
		text = "+" .. Formulas.formatCoins(coins) .. " coins"
	elseif reward.Kind == "Egg" then
		data.Eggs.FreeTokens += reward.Count
		player:SetAttribute("FreeEgg", true)
		player:SetAttribute("EggTokens", data.Eggs.FreeTokens)
		text = if reward.Count > 1 then reward.Count .. " free eggs" else "A free egg"
	elseif reward.Kind == "RareEgg" then
		data.Eggs.RareTokens += reward.Count
		player:SetAttribute("FreeEgg", true)
		player:SetAttribute("RareEggTokens", data.Eggs.RareTokens)
		text = "A guaranteed RARE egg"
	elseif reward.Kind == "SkillRoll" then
		local index = bestDesk(data)
		local lawyer = index and PlayerData.lawyerAt(data, index)
		if lawyer then
			lawyer.FreeSkillRolls = (lawyer.FreeSkillRolls or 0) + reward.Count
			text = string.format("%d free skill roll%s for %s", reward.Count, if reward.Count > 1 then "s" else "", Formulas.lawyerName(lawyer.Id, lawyer.Stars))
		else
			data.Eggs.FreeTokens += 1 -- nobody to give it to: a free egg instead
			text = "A free egg"
		end
	else
		text = ""
	end
	PlayerData.sync(player)
	sync(player, data)
	return text
end

-- Gives a Config.Rewards-style reward ({ Kind, Minutes / Count }) from another service (BigCaseService)
-- and returns the pop-up text.
function RewardsService.give(player: Player, reward: { [string]: any }): string
	local data = PlayerData.get(player)
	if not data then
		return ""
	end
	return grant(player, data, reward)
end

local function claim(player: Player): { [string]: any }
	local t = os.clock()
	if t - (lastClaim[player] or 0) < CLAIM_COOLDOWN then
		return { ok = false, reason = "Slow down!" }
	end
	lastClaim[player] = t
	local data = PlayerData.get(player)
	if not data then
		return { ok = false, reason = "Still loading" }
	end
	local day = today()
	if data.Daily.LastDay >= day then
		return { ok = false, reason = "Come back tomorrow!" }
	end
	local continues = data.Daily.LastDay == day - 1
	local streak = (if continues then data.Daily.Streak else 0) + 1
	local index = ((streak - 1) % #Config.Rewards.Daily) + 1
	data.Daily.Streak = streak
	data.Daily.LastDay = day
	local text = grant(player, data, Config.Rewards.Daily[index])
	return { ok = true, day = index, streak = streak, text = text }
end

local function onPlayerAdded(player: Player)
	lastActive[player] = os.clock() -- joining counts as activity
	local deadline = os.clock() + 120
	while player.Parent and not PlayerData.get(player) and os.clock() < deadline do
		task.wait(0.5)
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	-- offline earnings
	local offline = Config.Rewards.Offline
	local last = data.LastOnline or 0
	local away = os.time() - last
	data.LastOnline = os.time() -- so a quick rejoin can't pay out twice
	if last > 0 and away >= offline.MinMinutes * 60 then
		local seconds = math.min(away, offline.MaxHours * 3600)
		local coins = math.floor(RewardsService.incomePerMinute(data) / 60 * seconds * offline.Efficiency)
		if coins > 0 then
			data.Coins += coins
			PlayerData.sync(player)
			task.delay(4, function() -- after the firm has loaded in
				if player.Parent then
					RewardGranted:FireClient(player, {
						kind = "Offline",
						text = "+" .. Formulas.formatCoins(coins) .. " coins",
						minutes = math.floor(seconds / 60),
					})
				end
			end)
		end
	end
	sync(player, data)
end

function RewardsService.start()
	ClaimDaily.OnServerInvoke = claim
	Activity.OnServerEvent:Connect(function(player)
		lastActive[player] = os.clock()
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		lastActive[player] = nil
		lastClaim[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		local sinceIncome = 0
		while true do
			task.wait(1)
			sinceIncome += 1
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local data = PlayerData.get(player)
				if not data then
					continue
				end
				if now - (lastActive[player] or -math.huge) <= Config.Rewards.ActiveWindow then
					data.Playtime.Active += 1
					if data.Playtime.Active >= Config.Rewards.PlaytimeInterval then
						data.Playtime.Active -= Config.Rewards.PlaytimeInterval
						data.Playtime.Gifts += 1
						local text = grant(player, data, { Kind = "Coins", Minutes = Config.Rewards.PlaytimeMinutes })
						RewardGranted:FireClient(player, { kind = "Playtime", text = text })
					end
					player:SetAttribute("PlaytimeActive", data.Playtime.Active)
				end
				if sinceIncome >= INCOME_REFRESH then
					player:SetAttribute("CoinsPerMinute", RewardsService.incomePerMinute(data))
				end
			end
			if sinceIncome >= INCOME_REFRESH then
				sinceIncome = 0
			end
		end
	end)
end

return RewardsService
