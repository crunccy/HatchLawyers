--!strict
-- ArcadeServer (ServerScriptService.ArcadeServer, a Script; games in its Games folder; 2026-10-13, mr.robe's session -
-- user's call: build the minigames in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md). The ARCADE PIER's booth games
-- (Config.Arcade), with the same rules as the hub's Server.MinigameService:
--   * a booth's PlayPrompt (attribute ArcadeGame) starts a round if that game's cooldown is over. The cooldown is saved
--     in data.Minigames[id] (os.time() it's ready again - the map Gavel Bonk uses, so no save change) and mirrored as
--     the player attribute Arcade<Id>Ready (server time) for the booth boards. It starts when the round starts, so
--     walking away mid-round never gives a free retry.
--   * the game module plans the round (start), checks every input against that plan (input), scores it 0..1 (finish);
--     the reward is lerp(MinMinutes, MaxMinutes, score) minutes of the player's own income (RewardsService).
-- A game module (script.Games.<Id>) returns:
--   start(s, cfg, rng) -> payload        the plan the client draws (s.startAt = when play begins, server time)
--   input(s, cfg, kind, data, t) -> (reply?, done?)   t = the input's checked server time (see tapTime)
--   finish(s, cfg) -> (score 0..1, info) info.text = the result line
--   timeout(s, cfg) -> seconds after startAt when the round is over whatever happens
-- and may use s.send(reply) (an "Ack" from a timer) and s.finish() (end the round now).
-- Remotes.Arcade (RemoteEvent)
--   server -> client  ("Start", { game, id, startAt, ...payload })  ("Ack", { id, ...reply })
--                     ("Result", { id, game, score, stars, reward, ...info })  ("Note", { text })
--   client -> server  ("Input", id, kind, data)   data.t = the client's GetServerTimeNow() when it was tapped

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript) :: any
local Server = ServerScriptService:WaitForChild("Server")
local PlayerData = require(Server:WaitForChild("PlayerData") :: ModuleScript) :: any
local RewardsService = require(Server:WaitForChild("RewardsService") :: ModuleScript) :: any

local CFG = Config.Arcade
local SLACK = 0.4 -- seconds a tap's own timestamp may be older than when it arrived (network leeway)
local MAX_INPUTS = 400 -- per round

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Remote = Remotes:FindFirstChild("Arcade") :: RemoteEvent?
if not Remote then
	local r = Instance.new("RemoteEvent")
	r.Name = "Arcade"
	r.Parent = Remotes
	Remote = r
end
local remote = Remote :: RemoteEvent

local GAMES: { [string]: any } = {}
for _, m in script:WaitForChild("Games"):GetChildren() do
	if m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok then
			GAMES[m.Name] = mod
		else
			warn("[Arcade] " .. m.Name .. ": " .. tostring(mod))
		end
	end
end

export type Session = {
	id: number,
	game: string,
	player: Player,
	startAt: number,
	done: boolean,
	state: any,
	inputs: number,
	send: (reply: { [string]: any }) -> (),
	finish: () -> (),
}
local sessions: { [Player]: Session } = {}
local nextId = 0
local rng = Random.new()

local function now(): number
	return workspace:GetServerTimeNow()
end

local function formatWait(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- a tap's time: its own stamp if it's believable (not from the future, at most SLACK old), else when it arrived
local function tapTime(claimed: unknown, received: number): number
	if type(claimed) == "number" and claimed == claimed and claimed >= received - SLACK and claimed <= received + 0.05 then
		return claimed
	end
	return received
end

local function syncCooldowns(player: Player, data: any)
	data.Minigames = data.Minigames or {}
	for id, cfg in CFG do
		if type(cfg) == "table" and cfg.Cooldown then
			local readyAt = data.Minigames[id] or 0
			player:SetAttribute("Arcade" .. id .. "Ready", now() + math.max(0, readyAt - os.time()))
		end
	end
end

local function finish(s: Session)
	if s.done then
		return
	end
	s.done = true
	if sessions[s.player] == s then
		sessions[s.player] = nil
	end
	local cfg = CFG[s.game]
	local ok, score, info = pcall(GAMES[s.game].finish, s, cfg)
	if not ok then
		warn("[Arcade] " .. s.game .. " finish: " .. tostring(score))
		score, info = 0, {}
	end
	local sc = math.clamp(tonumber(score) or 0, 0, 1)
	local minutes = math.floor((cfg.MinMinutes + (cfg.MaxMinutes - cfg.MinMinutes) * sc) * 100 + 0.5) / 100
	local reward = ""
	if s.player.Parent then
		reward = RewardsService.give(s.player, { Kind = "Coins", Minutes = minutes })
	end
	local payload = if type(info) == "table" then info else {}
	payload.id, payload.game, payload.score = s.id, s.game, sc
	payload.stars = if sc >= 0.9 then 3 elseif sc >= 0.6 then 2 elseif sc >= 0.3 then 1 else 0
	payload.reward = reward
	if s.player.Parent then
		remote:FireClient(s.player, "Result", payload)
	end
end

local function startGame(player: Player, gameId: string)
	local cfg, mod = CFG[gameId], GAMES[gameId]
	local data = PlayerData.get(player)
	if type(cfg) ~= "table" or not mod or not data or sessions[player] then
		return
	end
	data.Minigames = data.Minigames or {}
	local readyAt = data.Minigames[gameId] or 0
	if readyAt > os.time() then
		remote:FireClient(player, "Note", { text = cfg.Name .. " is ready again in " .. formatWait(readyAt - os.time()) })
		return
	end
	data.Minigames[gameId] = os.time() + cfg.Cooldown
	syncCooldowns(player, data)
	nextId += 1
	local s: Session = {
		id = nextId, game = gameId, player = player, startAt = now() + CFG.IntroTime, done = false, state = {}, inputs = 0,
		send = function() end, finish = function() end,
	}
	s.send = function(reply: { [string]: any })
		if not s.done and player.Parent then
			reply.id = s.id
			remote:FireClient(player, "Ack", reply)
		end
	end
	s.finish = function()
		finish(s)
	end
	sessions[player] = s
	local ok, payload = pcall(mod.start, s, cfg, rng)
	if not ok then
		warn("[Arcade] " .. gameId .. " start: " .. tostring(payload))
		s.done = true
		sessions[player] = nil
		data.Minigames[gameId] = readyAt -- (give the go back)
		syncCooldowns(player, data)
		return
	end
	local p = if type(payload) == "table" then payload else {}
	p.game, p.id, p.startAt = gameId, s.id, s.startAt
	remote:FireClient(player, "Start", p)
	local limit = 120
	pcall(function()
		limit = mod.timeout(s, cfg)
	end)
	task.delay(CFG.IntroTime + limit, finish, s) -- (a hard stop, whatever happens)
end

local function onInput(player: Player, id: unknown, kind: unknown, data: unknown)
	local s = sessions[player]
	if not s or s.done or s.id ~= id or type(kind) ~= "string" then
		return
	end
	s.inputs += 1
	if s.inputs > MAX_INPUTS then
		return
	end
	local received = now()
	if received < s.startAt - SLACK then
		return
	end
	local d = if type(data) == "table" then data else {}
	local t = tapTime((d :: any).t, received)
	local ok, reply, done = pcall(GAMES[s.game].input, s, CFG[s.game], kind, d, t)
	if not ok then
		warn("[Arcade] " .. s.game .. " input: " .. tostring(reply))
		return
	end
	if type(reply) == "table" then
		s.send(reply)
	end
	if done then
		finish(s)
	end
end

------------------------------------------------------------------ wiring
local hooked: { [Instance]: boolean } = {}
local function hook(prompt: Instance)
	if hooked[prompt] or not prompt:IsA("ProximityPrompt") or prompt.Name ~= "PlayPrompt" then
		return
	end
	local gameId = prompt:GetAttribute("ArcadeGame")
	if type(gameId) ~= "string" then
		return
	end
	hooked[prompt] = true
	prompt.Triggered:Connect(function(player)
		startGame(player, gameId)
	end)
end
local function watch(root: Instance)
	for _, d in root:GetDescendants() do
		hook(d)
	end
	root.DescendantAdded:Connect(hook)
end
local pier = workspace:FindFirstChild("ArcadePier")
if pier then
	watch(pier)
end
workspace.ChildAdded:Connect(function(c)
	if c.Name == "ArcadePier" then
		watch(c)
	end
end)

remote.OnServerEvent:Connect(function(player, kind, id, gameKind, data)
	if kind == "Input" then
		onInput(player, id, gameKind, data)
	end
end)

Players.PlayerAdded:Connect(function(player)
	local deadline = os.clock() + 120
	while player.Parent and not PlayerData.get(player) and os.clock() < deadline do
		task.wait(0.5)
	end
	local data = PlayerData.get(player)
	if data then
		syncCooldowns(player, data)
	end
end)
for _, player in Players:GetPlayers() do
	local data = PlayerData.get(player)
	if data then
		syncCooldowns(player, data)
	end
end
Players.PlayerRemoving:Connect(function(player)
	local s = sessions[player]
	if s then
		s.done = true
		sessions[player] = nil
	end
end)
