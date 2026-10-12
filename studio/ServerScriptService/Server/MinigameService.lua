--!strict
-- Hub minigames (Config.Minigames) on the two pads beside the Big Case belt (Workspace.Hub.SpecialSpots):
--   * GAVEL BONK (SpecialSpot1): whack-a-mole. Robbers pop out of the judge's bench; bonk them. Bonking the
--     friendly judge costs points. One round lasts Duration seconds.
--   * LUCKY BRIEFCASE (SpecialSpot2): shell game. The cases open to show which one holds the BIG prize (the
--     star), shuffle, and the player picks one. Every case pays something.
-- Solo, tap-only and no reading needed (made for young players). The server plans each round (pop-up
-- schedule / shuffle), checks every tap against that plan and pays out through RewardsService (minutes of the
-- player's own income, or a free egg token). Each station's PlayPrompt (attribute Minigame) starts a round.
-- Cooldowns are per player and saved (data.Minigames: id -> os.time() it is ready again), mirrored as the
-- player attribute Minigame<Id>Ready (server time, for the station status boards). The cooldown starts when a
-- round starts, so walking away mid-round never gives a free retry.
--
-- Remotes.Minigame (RemoteEvent)
--   server -> client  ("Start", { game, id, startAt, ... })
--                         GavelBonk:      duration, holes, pops = { { id, hole, kind, t, stay } } (t from startAt)
--                         LuckyBriefcase: big (slot 1-3 at the start), swaps = { { a, b } }, showTime,
--                                         closeTime, swapTime, pickAt (server time)
--                     ("Bonked", { id, pop, points, score })   a tap the server accepted
--                     ("Result", { id, game, text, ... })       GavelBonk: score, robbers, robbersHit, judgesHit, stars
--                                                               LuckyBriefcase: slot, finalBig, big, prize
--                     ("Note", { text })
--   client -> server  ("Bonk", id, popId)  ("Pick", id, slot)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local RewardsService = require(script.Parent.RewardsService)

local Remote = ReplicatedStorage.Remotes.Minigame :: RemoteEvent
local CFG = Config.Minigames

local SLACK = 0.45 -- seconds of network leeway on every timing check
local RESULT_DELAY = 0.8 -- after a Gavel Bonk round ends, wait for the last taps in flight

type Pop = { id: number, hole: number, kind: string, t: number, stay: number }
type Session = {
	id: number,
	game: string,
	player: Player,
	startAt: number,
	done: boolean,
	-- Gavel Bonk
	pops: { Pop },
	hit: { [number]: boolean },
	score: number,
	robbers: number,
	robbersHit: number,
	judgesHit: number,
	-- Lucky Briefcase
	finalBig: number,
	pickAt: number,
}

local MinigameService = {}

local sessions: { [Player]: Session } = {}
local nextId = 0
local rng = Random.new()

local function now(): number
	return workspace:GetServerTimeNow()
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function round2(x: number): number
	return math.floor(x * 100 + 0.5) / 100
end

local function formatWait(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- mirrors a saved cooldown as server time, which is what clients can compare against
local function syncCooldowns(player: Player, data: any)
	data.Minigames = data.Minigames or {}
	for id in CFG do
		if type(CFG[id]) == "table" and CFG[id].Cooldown then
			local readyAt = data.Minigames[id] or 0
			player:SetAttribute("Minigame" .. id .. "Ready", now() + math.max(0, readyAt - os.time()))
		end
	end
end

local function pickWeighted(list: { any }): any
	local total = 0
	for _, entry in list do
		total += entry.Weight
	end
	local roll = rng:NextNumber() * total
	for _, entry in list do
		roll -= entry.Weight
		if roll <= 0 then
			return entry
		end
	end
	return list[1]
end

---------------------------------------------------------------- Gavel Bonk
local function planPops(cfg: any): ({ Pop }, number)
	local pops: { Pop } = {}
	local freeAt: { [number]: number } = {}
	local robbers = 0
	local lastKind = ""
	local t = 0.35
	while t < cfg.Duration - 0.5 do
		local f = t / cfg.Duration
		local stay = math.min(lerp(cfg.StayUp[1], cfg.StayUp[2], f), cfg.Duration - t)
		local free = {}
		for hole = 1, cfg.Holes do
			if (freeAt[hole] or 0) <= t then
				table.insert(free, hole)
			end
		end
		if #free > 0 then
			local hole = free[rng:NextInteger(1, #free)]
			-- never two judges in a row: the round should be mostly bonking
			local kind = if lastKind ~= "Judge" and rng:NextNumber() < cfg.JudgeChance then "Judge" else "Robber"
			lastKind = kind
			table.insert(pops, { id = #pops + 1, hole = hole, kind = kind, t = round2(t), stay = round2(stay) })
			freeAt[hole] = t + stay + 0.2
			if kind == "Robber" then
				robbers += 1
			end
		end
		t += lerp(cfg.PopEvery[1], cfg.PopEvery[2], f) * rng:NextNumber(0.8, 1.2)
	end
	return pops, robbers
end

local function finishBonk(s: Session)
	if s.done then
		return
	end
	s.done = true
	if sessions[s.player] == s then
		sessions[s.player] = nil
	end
	if not s.player.Parent then
		return
	end
	local cfg = CFG.GavelBonk
	local ratio = math.clamp(s.score / math.max(1, s.robbers * cfg.FullScore), 0, 1)
	local minutes = lerp(cfg.MinMinutes, cfg.MaxMinutes, ratio)
	local text = RewardsService.give(s.player, { Kind = "Coins", Minutes = minutes })
	Remote:FireClient(s.player, "Result", {
		id = s.id,
		game = "GavelBonk",
		text = text,
		score = s.score,
		robbers = s.robbers,
		robbersHit = s.robbersHit,
		judgesHit = s.judgesHit,
		stars = if ratio >= 1 then 3 elseif ratio >= 0.5 then 2 else 1,
	})
end

local function onBonk(player: Player, id: unknown, popId: unknown)
	local s = sessions[player]
	if not s or s.done or s.game ~= "GavelBonk" or s.id ~= id or type(popId) ~= "number" then
		return
	end
	local pop = s.pops[popId]
	if not pop or s.hit[pop.id] then
		return
	end
	local elapsed = now() - s.startAt
	if elapsed < pop.t - SLACK or elapsed > pop.t + pop.stay + SLACK then
		return -- not up at that moment
	end
	s.hit[pop.id] = true
	local points
	if pop.kind == "Robber" then
		points = 1
		s.robbersHit += 1
	else
		points = -CFG.GavelBonk.JudgePenalty
		s.judgesHit += 1
	end
	s.score = math.max(0, s.score + points)
	Remote:FireClient(player, "Bonked", { id = s.id, pop = pop.id, points = points, score = s.score })
end

---------------------------------------------------------------- Lucky Briefcase
local function finishPick(s: Session, slot: number)
	if s.done then
		return
	end
	s.done = true
	if sessions[s.player] == s then
		sessions[s.player] = nil
	end
	if not s.player.Parent then
		return
	end
	local cfg = CFG.LuckyBriefcase
	local big = slot == s.finalBig
	local prize = if big then pickWeighted(cfg.Big) else cfg.Small
	local text = RewardsService.give(s.player, prize)
	Remote:FireClient(s.player, "Result", {
		id = s.id,
		game = "LuckyBriefcase",
		text = text,
		slot = slot,
		finalBig = s.finalBig,
		big = big,
		prize = prize.Name,
		kind = prize.Kind,
	})
end

local function onPick(player: Player, id: unknown, slot: unknown)
	local s = sessions[player]
	if not s or s.done or s.game ~= "LuckyBriefcase" or s.id ~= id then
		return
	end
	if type(slot) ~= "number" or slot ~= slot // 1 or slot < 1 or slot > 3 then
		return
	end
	if now() < s.pickAt - SLACK then
		return -- still shuffling
	end
	finishPick(s, slot)
end

---------------------------------------------------------------- starting a round
local function newSession(player: Player, gameId: string, startAt: number): Session
	nextId += 1
	return {
		id = nextId,
		game = gameId,
		player = player,
		startAt = startAt,
		done = false,
		pops = {},
		hit = {},
		score = 0,
		robbers = 0,
		robbersHit = 0,
		judgesHit = 0,
		finalBig = 1,
		pickAt = 0,
	}
end

local function startGame(player: Player, gameId: string)
	local cfg = CFG[gameId]
	local data = PlayerData.get(player)
	if not cfg or not data then
		return
	end
	if sessions[player] then
		return -- already playing
	end
	data.Minigames = data.Minigames or {}
	local readyAt = data.Minigames[gameId] or 0
	if readyAt > os.time() then
		Remote:FireClient(player, "Note", { text = cfg.Name .. " is ready again in " .. formatWait(readyAt - os.time()) })
		return
	end
	data.Minigames[gameId] = os.time() + cfg.Cooldown
	syncCooldowns(player, data)

	local startAt = now() + CFG.IntroTime
	local s = newSession(player, gameId, startAt)
	sessions[player] = s
	if gameId == "GavelBonk" then
		s.pops, s.robbers = planPops(cfg)
		Remote:FireClient(player, "Start", {
			game = gameId,
			id = s.id,
			startAt = startAt,
			duration = cfg.Duration,
			holes = cfg.Holes,
			pops = s.pops,
		})
		task.delay(CFG.IntroTime + cfg.Duration + RESULT_DELAY, finishBonk, s)
	elseif gameId == "LuckyBriefcase" then
		local big = rng:NextInteger(1, 3)
		local swaps = {}
		local at = big
		for _ = 1, cfg.Swaps do
			local a = rng:NextInteger(1, 3)
			local b = rng:NextInteger(1, 2)
			if b >= a then
				b += 1
			end
			table.insert(swaps, { a, b })
			if at == a then
				at = b
			elseif at == b then
				at = a
			end
		end
		s.finalBig = at
		s.pickAt = startAt + cfg.ShowTime + cfg.CloseTime + cfg.Swaps * cfg.SwapTime
		Remote:FireClient(player, "Start", {
			game = gameId,
			id = s.id,
			startAt = startAt,
			big = big,
			swaps = swaps,
			showTime = cfg.ShowTime,
			closeTime = cfg.CloseTime,
			swapTime = cfg.SwapTime,
			pickAt = s.pickAt,
		})
		task.delay(s.pickAt - now() + cfg.PickTimeout, function()
			finishPick(s, rng:NextInteger(1, 3))
		end)
	end
end

---------------------------------------------------------------- wiring
local function hookPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") or prompt.Name ~= "PlayPrompt" then
		return
	end
	local gameId = prompt:GetAttribute("Minigame")
	if type(gameId) ~= "string" or not CFG[gameId] then
		return
	end
	prompt.Triggered:Connect(function(player)
		startGame(player, gameId)
	end)
end

function MinigameService.start()
	local hub = workspace:FindFirstChild("Hub")
	local spots = hub and hub:FindFirstChild("SpecialSpots")
	if spots then
		for _, d in spots:GetDescendants() do
			hookPrompt(d)
		end
	else
		warn("[MinigameService] Workspace.Hub.SpecialSpots not found: no minigames")
	end

	Remote.OnServerEvent:Connect(function(player, kind, id, arg)
		if kind == "Bonk" then
			onBonk(player, id, arg)
		elseif kind == "Pick" then
			onPick(player, id, arg)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local s = sessions[player]
		if s then
			s.done = true
			sessions[player] = nil
		end
	end)

	-- mirror saved cooldowns once each player's data has loaded
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("MinigamesSynced") == nil then
					local data = PlayerData.get(player)
					if data then
						syncCooldowns(player, data)
						player:SetAttribute("MinigamesSynced", true)
					end
				end
			end
			task.wait(2)
		end
	end)
end

return MinigameService
