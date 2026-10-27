--!strict
-- FloorRooms (ServerScriptService.FloorRooms, a Script; 2026-10-13 - mr.robe's call: the upper-floor ideas in
-- docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md, everything but the Rooftop Helipad). The UPSTAIRS ROOMS (Config.Floors):
--   * stands each room's set (made in Blender: tools/blender/floor_rooms.py -> ServerStorage.Templates.FloorRooms.<Id>)
--     on the firm building's upper floors once the building is big enough (Config.Floors.Rooms[id].Stage, the spot from
--     Config.Floors.Slots[stage]); a stage-up rebuilds the front building and the rooms come back with it.
--   * runs them. Each set's "Prompt" part has a RoomPrompt; triggering it opens that room's panel
--     (StarterPlayerScripts.Floors) through Remotes.FloorsEvent ("Open", room, state); the panel's buttons call
--     Remotes.Floors (RemoteFunction: action, ...) -> (ok, state | message). Everything is checked here.
--       MAIL ROOM        3 letters a day (Mail.Tasks, progress from GoalService.track), claim each for coins (+ an egg)
--       HALL OF FAME     every lawyer you've owned (data.Floors.Index, kept up to date here), sets by egg
--       VIP LOUNGE       a VIP client waits in the room every VIP.Every s; greet them, pick a lawyer, paid at once
--       MOOT COURT       send an office to practise for Moot.Minutes; collect = a free skill roll for its lawyer
--       CASE ARCHIVE     wins by client type (Server.FloorBonuses.onWin), milestones = payout bonus
--       PARTNER'S OFFICE rules the firm follows by itself (auto-upgrade the cheapest office, auto-equip best)
--       GUEST LOUNGE     a visitor who stays in your lounge gives you both a buff; visitors sign the guestbook (likes)
--       PRIVATE COURT    hold court: 3 cases, pick the evidence; paid by how many you got right
-- Saved in data.Floors (PlayerData v18). Bonuses: Server.FloorBonuses (through FirmFeatures.buffSources).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local Server = ServerScriptService:WaitForChild("Server")
local PlayerData = require(Server:WaitForChild("PlayerData") :: ModuleScript) :: any
local PlotService = require(Server:WaitForChild("PlotService") :: ModuleScript) :: any
local FirmBuilder = require(Server:WaitForChild("FirmBuilder") :: ModuleScript) :: any
local RewardsService = require(Server:WaitForChild("RewardsService") :: ModuleScript) :: any
local GoalService = require(Server:WaitForChild("GoalService") :: ModuleScript) :: any
local LawyerService = require(Server:WaitForChild("LawyerService") :: ModuleScript) :: any
local FloorBonuses = require(Server:WaitForChild("FloorBonuses") :: ModuleScript) :: any

local CFG = Config.Floors
local rng = Random.new()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local function remote(class: string, name: string): any
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = Remotes
	end
	return r
end
local Event = remote("RemoteEvent", "FloorsEvent") :: RemoteEvent
local Func = remote("RemoteFunction", "Floors") :: RemoteFunction

local function now(): number
	return os.time()
end
local function today(): number
	return math.floor(os.time() / 86400)
end
local function note(player: Player, text: string)
	Event:FireClient(player, "Note", text)
end
local function fdata(data: any): any
	data.Floors = data.Floors or {}
	local f = data.Floors
	f.Index = f.Index or {}
	f.CaseFiles = f.CaseFiles or {}
	f.Training = f.Training or {}
	f.Mail = f.Mail or { Day = 0, Letters = {} }
	f.Rules = f.Rules or {}
	f.Likes = f.Likes or 0
	f.Court = f.Court or 0
	return f
end

------------------------------------------------------------------ the rooms in the building
local templates = ServerStorage:WaitForChild("Templates"):WaitForChild("FloorRooms", 30)

type Placed = { [string]: Model } -- room id -> its set in this player's firm
local placed: { [Player]: Placed } = {}

local function firmOf(player: Player): Model?
	local ok, firm = pcall(PlotService.getFirm, player)
	return if ok then firm else nil
end

local hookPrompt: (prompt: ProximityPrompt, owner: Player, room: string) -> ()

local function placeRooms(player: Player, firm: Model)
	local front = firm:FindFirstChild("Front")
	local stage = firm:GetAttribute("Stage")
	if not front or type(stage) ~= "number" or not templates or front:FindFirstChild("FloorRooms") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "FloorRooms"
	folder.Parent = front
	local rooms: Placed = {}
	placed[player] = rooms
	local slots = CFG.Slots[stage]
	if not slots then
		return
	end
	local plot = firm.Parent :: Model
	local frame = FirmBuilder.frame(plot)
	local mx = (front:GetAttribute("MirrorX") :: number?) or 1 -- the overhaul mesh fronts are mirrored (FirmStages)
	for id, s in slots do
		local def = CFG.Rooms[id]
		local tpl = templates:FindFirstChild(id)
		if def and tpl and stage >= def.Stage then
			local m = (tpl :: Model):Clone()
			m:PivotTo(frame * CFrame.new(s[1] * mx, s[2], s[3]) * CFrame.Angles(0, math.rad(s[4] or 0), 0))
			m:SetAttribute("Owner", player.UserId)
			m.Parent = folder
			rooms[id] = m
			local prompt = m:FindFirstChild("RoomPrompt", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				hookPrompt(prompt, player, id)
			end
		end
	end
end

------------------------------------------------------------------ Hall of Fame: keep the index up to date
local function recordAll(data: any)
	for _, l in data.Lawyers or {} do
		FloorBonuses.record(data, l.Id, l.Stars)
	end
end

------------------------------------------------------------------ Mail Room
local function freshMail(f: any)
	if f.Mail.Day == today() and #f.Mail.Letters > 0 then
		return
	end
	local tasks = table.clone(CFG.Mail.Tasks)
	local letters = {}
	local clients = Config.Clients
	for i = 1, #CFG.Mail.Minutes do
		if #tasks == 0 then
			break
		end
		local t = table.remove(tasks, rng:NextInteger(1, #tasks))
		local from = clients[rng:NextInteger(1, #clients)]
		table.insert(letters, { Kind = t.Kind, Target = t.Target, Progress = 0, Claimed = false, From = from.Name or "A client", Text = string.format(t.Text, t.Target) })
		local _ = i
	end
	f.Mail = { Day = today(), Letters = letters }
end
-- every GoalService.track also fills the letters (wrapped once, here)
local originalTrack = GoalService.track
GoalService.track = function(player: Player, kind: string, amount: number?)
	originalTrack(player, kind, amount)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local f = fdata(data)
	if f.Mail.Day ~= today() then
		return
	end
	for _, l in f.Mail.Letters do
		if l.Kind == kind and not l.Claimed then
			l.Progress = math.min(l.Target, l.Progress + (amount or 1))
		end
	end
end

------------------------------------------------------------------ VIP Lounge (memory: one VIP at a time per firm)
type VIP = { model: Model?, leavesAt: number, name: string, tier: number }
local vips: { [Player]: VIP } = {}
local nextVip: { [Player]: number } = {}

local function despawnVip(player: Player, celebrate: boolean)
	local v = vips[player]
	vips[player] = nil
	nextVip[player] = now() + CFG.VIP.Every
	if v and v.model and v.model.Parent then
		local pos = v.model:GetPivot().Position
		if celebrate then
			Effects.burst(pos, "win")
		end
		v.model:Destroy()
	end
end
local function spawnVip(player: Player, room: Model)
	local seat = room:FindFirstChild("VIPSeat", true) :: BasePart?
	local clientsFolder = ServerStorage.Templates:FindFirstChild("Clients")
	local tier = rng:NextInteger(3, math.min(6, #Config.Clients))
	local client = Config.Clients[tier]
	local model: Model? = nil
	if seat and clientsFolder and #clientsFolder:GetChildren() > 0 then
		local list = clientsFolder:GetChildren()
		local src = list[math.clamp(tier, 1, #list)] :: Instance
		if src:IsA("Model") then
			local m = src:Clone()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				elseif d:IsA("Script") or d:IsA("LocalScript") then
					d:Destroy()
				end
			end
			local _, size = m:GetBoundingBox()
			m:PivotTo((seat :: BasePart).CFrame * CFrame.new(0, size.Y / 2 - (seat :: BasePart).Size.Y / 2, 0))
			local glow = Instance.new("Highlight")
			glow.FillTransparency = 1
			glow.OutlineColor = Color3.fromRGB(255, 200, 40)
			glow.Parent = m
			m.Parent = room
			model = m
		end
	end
	vips[player] = { model = model, leavesAt = now() + CFG.VIP.Wait, name = (client and client.Name or "A VIP"), tier = tier }
	note(player, "A VIP is waiting in your VIP Lounge!")
end

------------------------------------------------------------------ Guest Lounge (memory)
local pairUntil: { [string]: number } = {} -- "owner:visitor" -> os.clock() the next buff is allowed
local liked: { [string]: number } = {} -- "owner:visitor" -> day liked
local visitors: { [Player]: { string } } = {} -- owner -> recent visitor names
local stayStart: { [string]: number } = {}

local function updateGuestbook(player: Player)
	local room = placed[player] and placed[player].GuestLounge
	local book = room and room:FindFirstChild("Guestbook", true)
	local data = PlayerData.get(player)
	local label = book and book:FindFirstChild("Likes", true)
	if label and label:IsA("TextLabel") and data then
		label.Text = "♥ " .. tostring(fdata(data).Likes)
	end
end

------------------------------------------------------------------ Private Courtroom (memory: the trial in progress)
type Trial = { cases: { any }, round: number, correct: number }
local trials: { [Player]: Trial } = {}

------------------------------------------------------------------ state for the panels
local function lawyerList(data: any, limit: number): { any }
	local list = {}
	for uid, l in data.Lawyers or {} do
		local skin = Formulas.getSkin(l.Id)
		table.insert(list, { uid = uid, id = l.Id, name = skin and skin.Name or l.Id, rarity = skin and skin.Rarity or 1, stars = l.Stars or 1, earn = Formulas.lawyerEarn(l.Id, l.Stars) })
	end
	table.sort(list, function(a, b)
		return a.earn > b.earn
	end)
	while #list > limit do
		table.remove(list)
	end
	return list
end

local function stateFor(player: Player, room: string, viewer: Player?): any
	local data = PlayerData.get(player)
	if not data then
		return {}
	end
	local f = fdata(data)
	if room == "MailRoom" then
		freshMail(f)
		local out = {}
		for i, l in f.Mail.Letters do
			table.insert(out, { from = l.From, text = l.Text, progress = l.Progress, target = l.Target, claimed = l.Claimed,
				minutes = CFG.Mail.Minutes[i] or 1, egg = CFG.Mail.EggOnLast and i == #f.Mail.Letters })
		end
		return { letters = out }
	elseif room == "HallOfFame" then
		recordAll(data)
		local sets = {}
		for _, egg in FloorBonuses.SET_ORDER do
			local def = Formulas.themedEgg(egg)
			local entry = { egg = egg, name = if def then def.Name else "Briefcase Egg", lawyers = {} }
			for _, id in FloorBonuses.SETS[egg] do
				local skin = Formulas.getSkin(id)
				table.insert(entry.lawyers, { id = id, name = skin and skin.Name or id, rarity = skin and skin.Rarity or 1, stars = f.Index[id] or 0 })
			end
			entry.have, entry.total = FloorBonuses.setProgress(data, egg)
			table.insert(sets, entry)
		end
		return { sets = sets, bonus = FloorBonuses.completeSets(data) * CFG.Index.SetBonus }
	elseif room == "VIPLounge" then
		local v = vips[player]
		return {
			vip = if v then { name = v.name, tier = v.tier, leavesIn = v.leavesAt - now() } else nil,
			nextIn = math.max(0, (nextVip[player] or now()) - now()),
			lawyers = lawyerList(data, 12),
		}
	elseif room == "MootCourt" then
		local booths = {}
		for b = 1, CFG.Moot.Booths do
			local t = f.Training[tostring(b)]
			booths[b] = if t then { desk = t.Desk, left = math.max(0, t.Until - now()) } else { desk = nil }
		end
		local offices = {}
		for i, desk in data.Desks do
			local l = desk.Lawyer and data.Lawyers[desk.Lawyer]
			if l then
				local skin = Formulas.getSkin(l.Id)
				table.insert(offices, { index = i, name = skin and skin.Name or l.Id, rolls = l.FreeSkillRolls or 0 })
			end
		end
		return { booths = booths, offices = offices, minutes = CFG.Moot.Minutes }
	elseif room == "CaseArchive" then
		local shelves = {}
		for tier, client in Config.Clients do
			local wins = f.CaseFiles[tostring(tier)] or 0
			local reached = FloorBonuses.milestonesFor(wins)
			table.insert(shelves, { tier = tier, name = client.Name or client.Id, wins = wins, reached = reached, next = CFG.Archive.Milestones[reached + 1] })
		end
		return { shelves = shelves, bonus = FloorBonuses.totalMilestones(data) * CFG.Archive.PerMilestone }
	elseif room == "PartnersOffice" then
		local rules = {}
		for _, r in CFG.Partner.Rules do
			table.insert(rules, { id = r.Id, name = r.Name, text = r.Text, on = f.Rules[r.Id] == true })
		end
		return { rules = rules }
	elseif room == "GuestLounge" then
		return { likes = f.Likes, visitors = visitors[player] or {}, owner = viewer == nil or viewer == player, ownerName = player.DisplayName }
	elseif room == "PrivateCourtroom" then
		return { readyIn = math.max(0, f.Court - now()), playing = trials[player] ~= nil }
	end
	return {}
end

------------------------------------------------------------------ prompts
hookPrompt = function(prompt: ProximityPrompt, owner: Player, room: string)
	prompt.Triggered:Connect(function(who)
		if room == "GuestLounge" and who ~= owner then
			-- a visitor at the guestbook: like this firm (once a day)
			local key = owner.UserId .. ":" .. who.UserId
			local data = PlayerData.get(owner)
			if not data then
				return
			end
			if liked[key] == today() then
				note(who, "You've already signed " .. owner.DisplayName .. "'s guestbook today!")
				return
			end
			liked[key] = today()
			local f = fdata(data)
			f.Likes += 1
			updateGuestbook(owner)
			note(who, "You signed " .. owner.DisplayName .. "'s guestbook! ♥")
			note(owner, who.DisplayName .. " signed your guestbook! ♥")
			return
		end
		if who ~= owner then
			note(who, "This is " .. owner.DisplayName .. "'s " .. CFG.Rooms[room].Name)
			return
		end
		Event:FireClient(who, "Open", room, stateFor(owner, room, who))
	end)
end

------------------------------------------------------------------ actions (the panels' buttons)
local lastAction: { [Player]: number } = {}
local function act(player: Player, action: unknown, a: unknown, b: unknown): (boolean, any)
	if type(action) ~= "string" then
		return false, "bad"
	end
	local t = os.clock()
	if t - (lastAction[player] or 0) < 0.25 then
		return false, "Slow down!"
	end
	lastAction[player] = t
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	local f = fdata(data)
	local rooms = placed[player] or {}

	if action == "claimMail" then
		if not rooms.MailRoom then
			return false, "No Mail Room yet"
		end
		freshMail(f)
		local i = tonumber(a)
		local l = i and f.Mail.Letters[i]
		if not l or l.Claimed or l.Progress < l.Target then
			return false, "Not done yet"
		end
		l.Claimed = true
		local text = RewardsService.give(player, { Kind = "Coins", Minutes = CFG.Mail.Minutes[i] or 1 })
		if CFG.Mail.EggOnLast and i == #f.Mail.Letters then
			RewardsService.give(player, { Kind = "Egg", Count = 1 })
			text ..= " + a free egg!"
		end
		note(player, text)
		return true, stateFor(player, "MailRoom")

	elseif action == "greetVip" then
		local v = vips[player]
		if not rooms.VIPLounge or not v then
			return false, "No VIP is waiting"
		end
		local l = type(a) == "string" and data.Lawyers[a]
		if not l then
			return false, "Pick a lawyer"
		end
		local skin = Formulas.getSkin(l.Id)
		local rarity = skin and skin.Rarity or 1
		local minutes = CFG.VIP.Minutes * (1 + CFG.VIP.RarityBonus * (rarity - 1))
		local text = RewardsService.give(player, { Kind = "Coins", Minutes = math.floor(minutes * 100 + 0.5) / 100 })
		despawnVip(player, true)
		note(player, (skin and skin.Name or "Your lawyer") .. " won the VIP case! " .. text)
		return true, stateFor(player, "VIPLounge")

	elseif action == "train" then
		if not rooms.MootCourt then
			return false, "No Moot Court yet"
		end
		local booth, desk = tonumber(a), tonumber(b)
		if not booth or booth < 1 or booth > CFG.Moot.Booths or f.Training[tostring(booth)] then
			return false, "That booth is busy"
		end
		local d = desk and data.Desks[desk]
		if not d or not d.Lawyer then
			return false, "Pick an office with a lawyer"
		end
		for _, tr in f.Training do
			if tr.Desk == desk then
				return false, "That office is already practising"
			end
		end
		f.Training[tostring(booth)] = { Desk = desk, Until = now() + CFG.Moot.Minutes * 60 }
		return true, stateFor(player, "MootCourt")

	elseif action == "collect" then
		local booth = tonumber(a)
		local tr = booth and f.Training[tostring(booth)]
		if not tr or tr.Until > now() then
			return false, "Not done yet"
		end
		f.Training[tostring(booth)] = nil
		local d = data.Desks[tr.Desk]
		local l = d and d.Lawyer and data.Lawyers[d.Lawyer]
		if not l then
			return false, "That office has no lawyer now - practice lost"
		end
		l.FreeSkillRolls = (l.FreeSkillRolls or 0) + 1
		PlayerData.sync(player)
		note(player, string.format("Office %d practised: +1 free skill roll!", tr.Desk))
		return true, stateFor(player, "MootCourt")

	elseif action == "setRule" then
		if not rooms.PartnersOffice then
			return false, "No Partner's Office yet"
		end
		local ok = false
		for _, r in CFG.Partner.Rules do
			if r.Id == a then
				ok = true
			end
		end
		if not ok then
			return false, "bad"
		end
		f.Rules[a :: string] = b == true
		return true, stateFor(player, "PartnersOffice")

	elseif action == "courtStart" then
		if not rooms.PrivateCourtroom then
			return false, "No Private Courtroom yet"
		end
		if f.Court > now() then
			return false, "Court is in recess - back soon"
		end
		f.Court = now() + CFG.Court.Cooldown
		local pool = table.clone(CFG.Court.Cases)
		local cases = {}
		for _ = 1, 3 do
			table.insert(cases, table.remove(pool, rng:NextInteger(1, #pool)))
		end
		trials[player] = { cases = cases, round = 1, correct = 0 }
		local shown = {}
		for _, c in cases do
			table.insert(shown, { case = c.Case, cards = c.Cards })
		end
		return true, { rounds = shown }

	elseif action == "courtAnswer" then
		local tr = trials[player]
		local round, pick = tonumber(a), tonumber(b)
		if not tr or round ~= tr.round or not pick then
			return false, "bad"
		end
		local c = tr.cases[round]
		local right = pick == c.Answer
		if right then
			tr.correct += 1
			GoalService.track(player, "courtCorrect")
		end
		tr.round += 1
		local result: any = { correct = right, answer = c.Answer }
		if tr.round > #tr.cases then
			trials[player] = nil
			local share = tr.correct / #tr.cases
			local minutes = CFG.Court.MinMinutes + (CFG.Court.MaxMinutes - CFG.Court.MinMinutes) * share
			result.done = true
			result.score = tr.correct
			result.reward = RewardsService.give(player, { Kind = "Coins", Minutes = math.floor(minutes * 100 + 0.5) / 100 })
		end
		return true, result
	end
	return false, "bad"
end
Func.OnServerInvoke = act

------------------------------------------------------------------ the loops
-- rooms into firms, the index, VIP comings and goings, the Partner's rules (every 2 s)
local ruleTick: { [Player]: number } = {}
task.spawn(function()
	while true do
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			local firm = firmOf(player)
			if data and firm then
				local ok, err = pcall(function()
					placeRooms(player, firm)
					local f = fdata(data)
					recordAll(data)
					local rooms = placed[player] or {}
					if rooms.MailRoom then
						freshMail(f) -- (today's letters exist from the start, so progress counts before you open them)
					end
					-- VIP
					local v = vips[player]
					if v and (now() >= v.leavesAt or not rooms.VIPLounge or (v.model and not v.model.Parent)) then
						if now() >= v.leavesAt then
							note(player, "The VIP got tired of waiting and left.")
						end
						despawnVip(player, false)
					elseif not v and rooms.VIPLounge and now() >= (nextVip[player] or 0) then
						if nextVip[player] == nil then
							nextVip[player] = now() + 60 -- (the first one a minute after the room appears)
						else
							spawnVip(player, rooms.VIPLounge)
						end
					end
					-- the Partner's rules
					if rooms.PartnersOffice and os.clock() - (ruleTick[player] or 0) >= CFG.Partner.Every then
						ruleTick[player] = os.clock()
						if f.Rules.AutoUpgrade and LawyerService.upgradeOffice then
							local best, cost = nil, math.huge
							for i, desk in data.Desks do
								if desk.Lawyer and desk.Level < Config.Lawyer.MaxLevel then
									local c = Formulas.trainCost(desk.Level)
									if c < cost then
										best, cost = i, c
									end
								end
							end
							if best and data.Coins >= cost * CFG.Partner.UpgradeReserve then
								LawyerService.upgradeOffice(player, best, nil)
							end
						end
						if f.Rules.AutoEquip and LawyerService.equipBest then
							LawyerService.equipBest(player)
						end
					end
					updateGuestbook(player)
				end)
				if not ok then
					warn("[FloorRooms] " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
		task.wait(2)
	end
end)

-- Guest Lounge visits (every second): another player standing in your lounge for Lounge.Stay s = a buff for you both
task.spawn(function()
	while true do
		for _, owner in Players:GetPlayers() do
			local room = placed[owner] and placed[owner].GuestLounge
			if room and room.Parent then
				local centre = room:GetPivot().Position
				for _, visitor in Players:GetPlayers() do
					local root = visitor ~= owner and visitor.Character and visitor.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local key = owner.UserId .. ":" .. visitor.UserId
					if root and (root.Position - centre).Magnitude <= CFG.Lounge.Radius then
						stayStart[key] = stayStart[key] or os.clock()
						if os.clock() - stayStart[key] >= CFG.Lounge.Stay and os.clock() >= (pairUntil[key] or 0) then
							pairUntil[key] = os.clock() + CFG.Lounge.Cooldown
							local untilT = os.clock() + CFG.Lounge.Minutes * 60
							FloorBonuses.loungeUntil[owner] = math.max(FloorBonuses.loungeUntil[owner] or 0, untilT)
							FloorBonuses.loungeUntil[visitor] = math.max(FloorBonuses.loungeUntil[visitor] or 0, untilT)
							local list = visitors[owner] or {}
							table.insert(list, 1, visitor.DisplayName)
							while #list > 8 do
								table.remove(list)
							end
							visitors[owner] = list
							local pct = math.floor(CFG.Lounge.Buff * 100 + 0.5)
							note(owner, string.format("%s is visiting your Guest Lounge: +%d%% cases for you both!", visitor.DisplayName, pct))
							note(visitor, string.format("Visiting %s's Guest Lounge: +%d%% cases for you both!", owner.DisplayName, pct))
						end
					else
						stayStart[key] = nil
					end
				end
			end
		end
		task.wait(1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	despawnVip(player, false)
	placed[player] = nil
	vips[player] = nil
	nextVip[player] = nil
	trials[player] = nil
	lastAction[player] = nil
	ruleTick[player] = nil
	visitors[player] = nil
	FloorBonuses.loungeUntil[player] = nil
end)
