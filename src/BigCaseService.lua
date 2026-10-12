--!strict
-- Big Case Belt (Config.BigCase): every WaveInterval seconds a wave of gold VIP clients rides the hub
-- conveyor (Workspace.Hub.BigCaseBelt, from its BeltStart part to its BeltEnd part). Anyone can grab
-- one with its prompt. Every grab of the same client within TieWindow seconds joins in; two or more
-- grabbers play a showdown minigame (Mash / Snap / Gavel, picked at random). The winner gets the
-- client's prize, everyone else the consolation prize. A player wins at most WinsPerWave a wave.
--
-- The server owns where a client is: while riding, From + direction * BeltSpeed * (now - RideStart),
-- in server time. StarterPlayerScripts.BigCase moves the models locally so the ride is smooth, and
-- holds them at StopAt once grabbed. The belt's look (the Blender model) doesn't matter here, only
-- the two marker parts.
--
-- Remotes.BigCase (RemoteEvent; its NextWave attribute is the server time the next wave arrives)
--   server -> client  ("Wave", { at, warn })              siren: a wave arrives at `at` (everyone)
--                     ("Note", { text })                  a short message for this player
--                     ("Won", { text, prize })            uncontested grab paid out
--                     ("Start", { id, game, players, prize, startAt, ...setup })   to contenders
--                     ("Mash", { id, scores })            live tap counts ({ [userId]: taps })
--                     ("SnapReveal", { id, target })      the card to find
--                     ("SnapWrong", { id, until })        your wrong card (locked out until)
--                     ("GavelStop", { id, userId, pos })  a contender stopped their needle
--                     ("Result", { id, winner, winnerName, text, consolation })
--   client -> server  ("Tap", id) ("Snap", id, cardIndex) ("Gavel", id, pressServerTime)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local RewardsService = require(script.Parent.RewardsService)

local BigCase = ReplicatedStorage.Remotes.BigCase :: RemoteEvent
local CFG = Config.BigCase
local TAG = "BigCaseClient"

type Entry = {
	model: Model,
	prompt: ProximityPrompt,
	prize: { [string]: any },
	from: Vector3,
	dir: Vector3,
	length: number,
	rideStart: number,
	state: "Ride" | "Window" | "Showdown" | "Done",
	stopAt: Vector3?,
	grabbers: { Player },
}

type Showdown = {
	id: number,
	game: string,
	players: { Player },
	startAt: number, -- server time the minigame starts (after the intro)
	winner: Player?,
	-- Mash
	taps: { [Player]: number },
	tapWindow: { [Player]: { start: number, count: number } },
	-- Snap
	layouts: { [Player]: { number } },
	target: number,
	revealAt: number,
	locked: { [Player]: number },
	-- Gavel
	stops: { [Player]: number },
}

local BigCaseService = {}

local entries: { Entry } = {}
local showdowns: { [number]: Showdown } = {}
local busy: { [Player]: number } = {} -- player -> showdown id they're in
local winsThisWave: { [Player]: number } = {}
local nextShowdown = 0
local nextWaveAt = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local function belt(): (Vector3?, Vector3?)
	local hub = workspace:FindFirstChild("Hub")
	local model = hub and hub:FindFirstChild("BigCaseBelt")
	local a = model and model:FindFirstChild("BeltStart", true)
	local b = model and model:FindFirstChild("BeltEnd", true)
	if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
		return a.Position, b.Position
	end
	return nil, nil
end

local function positionOf(entry: Entry): Vector3
	if entry.stopAt then
		return entry.stopAt
	end
	local travelled = math.clamp((now() - entry.rideStart) * CFG.BeltSpeed, 0, entry.length)
	return entry.from + entry.dir * travelled
end

local function pickPrize(): { [string]: any }
	local total = 0
	for _, prize in CFG.Prizes do
		total += prize.Weight
	end
	local roll = math.random() * total
	for _, prize in CFG.Prizes do
		roll -= prize.Weight
		if roll <= 0 then
			return prize
		end
	end
	return CFG.Prizes[1]
end

local function prizeInfo(prize: { [string]: any }): { [string]: any }
	return { name = prize.Name, color = prize.Color }
end

local function give(player: Player, reward: { [string]: any }): string
	if not player.Parent or not PlayerData.get(player) then
		return ""
	end
	return RewardsService.give(player, reward)
end

---------------------------------------------------------------- the VIP client models
local function makeVip(prize: { [string]: any }, from: Vector3): (Model?, ProximityPrompt?)
	local templates = ServerStorage:FindFirstChild("Templates")
	local folder = templates and templates:FindFirstChild("Clients")
	local defs = {}
	for _, def in Config.ClientCharacters do
		local source = folder and folder:FindFirstChild(def.Id)
		if def.Tier >= CFG.MinTier and source and source:IsA("Model") then
			table.insert(defs, def)
		end
	end
	if #defs == 0 or not folder then
		return nil, nil
	end
	local def = defs[math.random(#defs)]
	local model = (folder :: any)[def.Id]:Clone() :: Model
	model.Name = "BigCase_" .. def.Id
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		elseif d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	-- feet on the belt, facing -Z (the models' front) toward the hub's centre
	model:PivotTo(CFrame.new(0, 0, 0))
	local box, size = model:GetBoundingBox()
	local lift = -(box.Position.Y - size.Y / 2)
	model:PivotTo(CFrame.new(from + Vector3.new(0, lift, 0)))
	model:SetAttribute("Lift", lift) -- pivot height above the feet (StarterPlayerScripts.BigCase uses it too)
	local root = model.PrimaryPart or model:FindFirstChild("Torso", true) or model:FindFirstChildWhichIsA("BasePart", true)

	local glow = Instance.new("Highlight")
	glow.FillColor = prize.Color
	glow.FillTransparency = 0.7
	glow.OutlineColor = prize.Color
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = model

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(prize.Color)
	sparkle.Rate = 6
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.Size = NumberSequence.new(0.5, 0)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = root

	local tag = Instance.new("BillboardGui")
	tag.Name = "BigCaseTag"
	tag.Size = UDim2.fromOffset(160, 54)
	tag.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 1.6, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 90
	tag.Parent = root
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.Text = prize.Name .. "!"
	title.TextColor3 = prize.Color
	title.TextScaled = true
	title.Font = Enum.Font.LuckiestGuy
	title.TextStrokeTransparency = 0
	title.Parent = tag
	local who = Instance.new("TextLabel")
	who.Name = "Who"
	who.BackgroundTransparency = 1
	who.Position = UDim2.fromScale(0, 0.6)
	who.Size = UDim2.new(1, 0, 0.4, 0)
	who.Text = def.Name
	who.TextColor3 = Color3.new(1, 1, 1)
	who.TextScaled = true
	who.Font = Enum.Font.FredokaOne
	who.TextStrokeTransparency = 0
	who.Parent = tag

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GrabPrompt"
	prompt.ActionText = "GRAB!"
	prompt.ObjectText = prize.Name
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model:SetAttribute("Prize", prize.Name)
	return model, prompt
end

local function finish(entry: Entry, delaySeconds: number)
	entry.state = "Done"
	entry.prompt.Enabled = false
	entry.model:SetAttribute("State", "Done")
	task.delay(delaySeconds, function()
		entry.model:Destroy()
		local index = table.find(entries, entry)
		if index then
			table.remove(entries, index)
		end
	end)
end

---------------------------------------------------------------- showdowns
local function playerList(sd: Showdown): { { [string]: any } }
	local list = {}
	for _, p in sd.players do
		table.insert(list, { userId = p.UserId, name = p.DisplayName })
	end
	return list
end

local function fireAll(sd: Showdown, kind: string, payload: { [string]: any })
	for _, p in sd.players do
		if p.Parent then
			BigCase:FireClient(p, kind, payload)
		end
	end
end

local function present(sd: Showdown): { Player }
	local list = {}
	for _, p in sd.players do
		if p.Parent then
			table.insert(list, p)
		end
	end
	return list
end

-- Still worth playing: 2+ contenders left (or a 1-player dev test).
local function contested(sd: Showdown): boolean
	return #present(sd) > 1 or #sd.players == 1
end

-- Best score wins (ties broken at random). score(p) -> number or nil (nil = didn't play).
local function best(sd: Showdown, score: (Player) -> number?, lowerIsBetter: boolean): Player?
	local top, topScore, ties = nil, nil, 0
	for _, p in present(sd) do
		local s = score(p)
		if s == nil then
			continue
		end
		local better = topScore == nil or (if lowerIsBetter then s < topScore else s > topScore)
		if better then
			top, topScore, ties = p, s, 1
		elseif s == topScore then
			ties += 1
			if math.random(ties) == 1 then
				top = p
			end
		end
	end
	return top
end

local function runMash(sd: Showdown)
	local endAt = sd.startAt + CFG.Mash.Duration
	while now() < endAt and contested(sd) do
		local scores = {}
		for p, n in sd.taps do
			scores[tostring(p.UserId)] = n
		end
		fireAll(sd, "Mash", { id = sd.id, scores = scores })
		task.wait(0.15)
	end
	local scores = {}
	for p, n in sd.taps do
		scores[tostring(p.UserId)] = n
	end
	fireAll(sd, "Mash", { id = sd.id, scores = scores })
	sd.winner = best(sd, function(p)
		return sd.taps[p] or 0
	end, false)
end

local function runSnap(sd: Showdown)
	task.wait(math.max(0, sd.revealAt - now()))
	fireAll(sd, "SnapReveal", { id = sd.id, target = sd.target })
	local deadline = sd.revealAt + CFG.Snap.Timeout
	while not sd.winner and now() < deadline and contested(sd) do
		task.wait(0.05)
	end
	if not sd.winner then
		local list = present(sd)
		sd.winner = list[math.random(math.max(#list, 1))]
	end
end

-- Needle position at server time t: starts at the left edge (-1), swings to +1 and back every Period.
local function gavelPos(sd: Showdown, t: number): number
	local u = ((t - sd.startAt) / CFG.Gavel.Period) % 1
	return 1 - 2 * math.abs(2 * u - 1) -- -1 at u=0, +1 at u=0.5, -1 at u=1
end

local function runGavel(sd: Showdown)
	local deadline = sd.startAt + CFG.Gavel.Timeout
	while now() < deadline and contested(sd) do
		local all = true
		for _, p in present(sd) do
			all = all and sd.stops[p] ~= nil
		end
		if all then
			break
		end
		task.wait(0.05)
	end
	sd.winner = best(sd, function(p)
		local stop = sd.stops[p]
		return if stop then math.abs(gavelPos(sd, stop)) else 9
	end, true)
end

local GAMES: { [string]: (Showdown) -> () } = { Mash = runMash, Snap = runSnap, Gavel = runGavel }

local function startShowdown(entry: Entry)
	entry.state = "Showdown"
	entry.model:SetAttribute("State", "Showdown")
	nextShowdown += 1
	local games = CFG.Games
	local forced = BigCase:GetAttribute("ForceGame") -- dev / tests: always this minigame
	local sd: Showdown = {
		id = nextShowdown,
		game = if typeof(forced) == "string" and GAMES[forced] then forced else games[math.random(#games)],
		players = table.clone(entry.grabbers),
		startAt = now() + CFG.IntroTime,
		winner = nil,
		taps = {},
		tapWindow = {},
		layouts = {},
		target = 0,
		revealAt = 0,
		locked = {},
		stops = {},
	}
	showdowns[sd.id] = sd
	for _, p in sd.players do
		busy[p] = sd.id
		sd.taps[p] = 0
	end

	local base = {
		id = sd.id,
		game = sd.game,
		players = playerList(sd),
		prize = prizeInfo(entry.prize),
		startAt = sd.startAt,
	}
	if sd.game == "Snap" then
		local deck = {}
		for i = 1, #CFG.Snap.Deck do
			table.insert(deck, i)
		end
		-- the same cards for everyone, shuffled per player so nobody can copy a position
		local hand = {}
		for _ = 1, math.min(CFG.Snap.Cards, #deck) do
			table.insert(hand, table.remove(deck, math.random(#deck)))
		end
		sd.target = hand[math.random(#hand)]
		sd.revealAt = sd.startAt + CFG.Snap.RevealMin + math.random() * (CFG.Snap.RevealMax - CFG.Snap.RevealMin)
		for _, p in sd.players do
			local layout = table.clone(hand)
			for i = #layout, 2, -1 do
				local j = math.random(i)
				layout[i], layout[j] = layout[j], layout[i]
			end
			sd.layouts[p] = layout
		end
		for _, p in sd.players do
			local payload = table.clone(base)
			payload.cards = sd.layouts[p]
			BigCase:FireClient(p, "Start", payload)
		end
	else
		if sd.game == "Gavel" then
			base.period = CFG.Gavel.Period
		elseif sd.game == "Mash" then
			base.duration = CFG.Mash.Duration
		end
		fireAll(sd, "Start", base)
	end

	task.spawn(function()
		task.wait(math.max(0, sd.startAt - now()))
		GAMES[sd.game](sd)
		local winner = sd.winner
		local winnerText = ""
		if winner then
			winsThisWave[winner] = (winsThisWave[winner] or 0) + 1
			winnerText = give(winner, entry.prize)
		end
		for _, p in present(sd) do
			local consolation = nil
			if p ~= winner then
				consolation = give(p, CFG.Consolation)
			end
			BigCase:FireClient(p, "Result", {
				id = sd.id,
				winner = winner and winner.UserId,
				winnerName = winner and winner.DisplayName,
				text = winnerText,
				consolation = consolation,
			})
		end
		for _, p in sd.players do
			if busy[p] == sd.id then
				busy[p] = nil
			end
		end
		showdowns[sd.id] = nil
		if winner then
			entry.model:SetAttribute("WinnerName", winner.DisplayName)
		end
		finish(entry, CFG.ResultTime)
	end)
end

local function closeWindow(entry: Entry)
	if entry.state ~= "Window" then
		return
	end
	local grabbers = {}
	for _, p in entry.grabbers do
		-- (someone who grabbed two clients at once only keeps the first: they're busy or already won)
		if p.Parent and not busy[p] and (winsThisWave[p] or 0) < CFG.WinsPerWave then
			table.insert(grabbers, p)
		end
	end
	entry.grabbers = grabbers
	entry.prompt.Enabled = false
	if #grabbers == 0 then
		finish(entry, 0.5)
	elseif #grabbers == 1 then
		local p = grabbers[1]
		winsThisWave[p] = (winsThisWave[p] or 0) + 1
		local text = give(p, entry.prize)
		BigCase:FireClient(p, "Won", { text = text, prize = prizeInfo(entry.prize) })
		entry.model:SetAttribute("WinnerName", p.DisplayName)
		finish(entry, 1.5)
	else
		startShowdown(entry)
	end
end

local function onGrab(entry: Entry, player: Player)
	if entry.state ~= "Ride" and entry.state ~= "Window" then
		return
	end
	if busy[player] then
		return
	end
	if (winsThisWave[player] or 0) >= CFG.WinsPerWave then
		BigCase:FireClient(player, "Note", { text = "You already won a Big Case this wave! Let someone else have one." })
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - positionOf(entry)).Magnitude > CFG.GrabRange then
		return
	end
	if entry.state == "Ride" then
		entry.stopAt = positionOf(entry)
		entry.state = "Window"
		entry.grabbers = { player }
		entry.model:SetAttribute("StopAt", entry.stopAt)
		entry.model:PivotTo(CFrame.new((entry.stopAt :: Vector3) + Vector3.new(0, entry.model:GetAttribute("Lift") or 0, 0)))
		entry.model:SetAttribute("State", "Window")
		entry.prompt.ActionText = "OBJECTION!" -- latecomers can still contest it for a moment
		entry.prompt.ObjectText = player.DisplayName .. " grabbed it!"
		BigCase:FireClient(player, "Note", { text = "Grabbed! Watch out for rival lawyers..." })
		task.delay(CFG.TieWindow, closeWindow, entry)
	elseif not table.find(entry.grabbers, player) then
		table.insert(entry.grabbers, player)
	end
end

---------------------------------------------------------------- waves
local function spawnClient(from: Vector3, to: Vector3)
	local prize = pickPrize()
	local model, prompt = makeVip(prize, from)
	if not model or not prompt then
		return
	end
	local offset = to - from
	local entry: Entry = {
		model = model,
		prompt = prompt,
		prize = prize,
		from = from,
		dir = offset.Unit,
		length = offset.Magnitude,
		rideStart = now(),
		state = "Ride",
		stopAt = nil,
		grabbers = {},
	}
	model:SetAttribute("From", from)
	model:SetAttribute("To", to)
	model:SetAttribute("RideStart", entry.rideStart)
	model:SetAttribute("Speed", CFG.BeltSpeed)
	model:SetAttribute("State", "Ride")
	CollectionService:AddTag(model, TAG)
	model.Parent = workspace.Hub:FindFirstChild("BigCaseBelt") or workspace
	table.insert(entries, entry)
	prompt.Triggered:Connect(function(player)
		onGrab(entry, player)
	end)
	-- rode off the end of the belt without anyone grabbing it
	task.delay(entry.length / CFG.BeltSpeed + 0.3, function()
		if entry.state == "Ride" then
			finish(entry, 0)
		end
	end)
end

local function runWave()
	local from, to = belt()
	if not from or not to then
		warn("[BigCaseService] Workspace.Hub.BigCaseBelt needs BeltStart and BeltEnd parts")
		return
	end
	table.clear(winsThisWave)
	for i = 1, CFG.WaveSize do
		spawnClient(from :: Vector3, to :: Vector3)
		if i < CFG.WaveSize then
			task.wait(CFG.Spacing)
		end
	end
end

---------------------------------------------------------------- client input
local function onClientEvent(player: Player, kind: any, id: any, value: any)
	if typeof(id) ~= "number" then
		return
	end
	local sd = showdowns[id]
	if not sd or busy[player] ~= id or sd.winner then
		return
	end
	local t = now()
	if kind == "Tap" and sd.game == "Mash" then
		if t < sd.startAt or t > sd.startAt + CFG.Mash.Duration then
			return
		end
		-- at most MaxTapsPerSecond taps count in any one second
		local w = sd.tapWindow[player]
		if not w or t - w.start >= 1 then
			w = { start = t, count = 0 }
			sd.tapWindow[player] = w
		end
		if w.count >= CFG.Mash.MaxTapsPerSecond then
			return
		end
		w.count += 1
		sd.taps[player] = (sd.taps[player] or 0) + 1
	elseif kind == "Snap" and sd.game == "Snap" then
		if typeof(value) ~= "number" or (sd.locked[player] or 0) > t then
			return
		end
		local layout = sd.layouts[player]
		local card = layout and layout[value]
		if t >= sd.revealAt and card == sd.target then
			sd.winner = player
		else
			-- too early or the wrong card: locked out for a moment
			sd.locked[player] = t + CFG.Snap.WrongLockout
			BigCase:FireClient(player, "SnapWrong", { id = id, ["until"] = sd.locked[player] })
		end
	elseif kind == "Gavel" and sd.game == "Gavel" then
		if sd.stops[player] or t < sd.startAt then
			return
		end
		-- trust the client's press time a little (it hides their ping), never from the future or long ago
		-- (audit 2026-10-12: a NaN press passed every check and then beat every score; and 0.6 s of backdating let a
		-- script pick a perfect press. NaN is now refused and the backdating is limited to the player's real ping.)
		local press = if typeof(value) == "number" and value == value then value else t
		local lag = math.min(0.3, player:GetNetworkPing() + 0.1)
		if press > t or press < sd.startAt or t - press > lag then
			press = t
		end
		sd.stops[player] = press
		fireAll(sd, "GavelStop", { id = id, userId = player.UserId, pos = gavelPos(sd, press) })
	end
end

function BigCaseService.start()
	BigCase.OnServerEvent:Connect(onClientEvent)
	if game:GetService("RunService"):IsStudio() then
		-- Studio only: ServerStorage.BigCaseDev:Invoke("wave", seconds) / ("showdown", gameName) for testing
		local dev = Instance.new("BindableFunction")
		dev.Name = "BigCaseDev"
		dev.OnInvoke = function(kind: string, arg: any)
			if kind == "wave" then
				BigCaseService.waveIn(arg or 3)
			elseif kind == "showdown" then
				BigCaseService._testShowdown(Players:GetPlayers(), arg)
			end
			return true
		end
		dev.Parent = ServerStorage
	end
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
		winsThisWave[player] = nil
	end)
	-- keep the real models near where they are, so the server's prompt range check agrees with what
	-- players see (the smooth ride itself is drawn by each client)
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, entry in entries do
				if entry.state == "Ride" and entry.model.Parent then
					local lift = entry.model:GetAttribute("Lift") or 0
					entry.model:PivotTo(CFrame.new(positionOf(entry) + Vector3.new(0, lift, 0)))
				end
			end
		end
	end)
	task.spawn(function()
		nextWaveAt = now() + CFG.FirstWave
		while true do
			BigCase:SetAttribute("NextWave", nextWaveAt)
			while now() < nextWaveAt - CFG.WarnTime do -- polled so waveIn() can bring it forward
				task.wait(0.5)
			end
			BigCase:FireAllClients("Wave", { at = nextWaveAt, warn = CFG.WarnTime })
			task.wait(math.max(0, nextWaveAt - now()))
			nextWaveAt = now() + CFG.WaveInterval
			BigCase:SetAttribute("NextWave", nextWaveAt)
			BigCase:SetAttribute("WaveEnds", now() + (CFG.WaveSize - 1) * CFG.Spacing + 14) -- roughly when the belt is empty
			local ok, err = pcall(runWave)
			if not ok then
				warn("[BigCaseService] wave failed:", err)
			end
		end
	end)
end

-- Dev / tests: a VIP stopped at the middle of the belt and a showdown for `players` right away.
function BigCaseService._testShowdown(players: { Player }, game: string?)
	local from, to = belt()
	if not from or not to then
		return
	end
	local prize = CFG.Prizes[1]
	local model, prompt = makeVip(prize, (from + to) / 2)
	if not model or not prompt then
		return
	end
	local entry: Entry = {
		model = model, prompt = prompt, prize = prize, from = from, dir = (to - from).Unit,
		length = (to - from).Magnitude, rideStart = now(), state = "Window", stopAt = (from + to) / 2, grabbers = players,
	}
	model:SetAttribute("StopAt", entry.stopAt)
	model:SetAttribute("State", "Window")
	CollectionService:AddTag(model, TAG)
	model.Parent = workspace.Hub:FindFirstChild("BigCaseBelt") or workspace
	table.insert(entries, entry)
	if game then
		BigCase:SetAttribute("ForceGame", game)
	end
	startShowdown(entry)
	BigCase:SetAttribute("ForceGame", nil)
end

-- Dev / tests: bring the next wave forward to `seconds` from now.
function BigCaseService.waveIn(seconds: number)
	nextWaveAt = now() + seconds
	BigCase:SetAttribute("NextWave", nextWaveAt)
end

return BigCaseService
