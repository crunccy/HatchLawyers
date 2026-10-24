--!strict
-- Hub minigames, client side (server: Server.MinigameService; tuning: Config.Minigames).
--   GAVEL BONK: whack-a-mole on a 3x3 bench. Bonk the robbers, leave the friendly judge alone.
--   LUCKY BRIEFCASE: watch which case holds the star, follow the shuffle, pick one. Every case wins.
-- Also runs the stations themselves: a status board over each one (PLAY! / ready in m:ss, from the player
-- attribute Minigame<Id>Ready) and their idle animation (robbers peeking out of the bench, briefcases
-- sliding about, marquee bulbs blinking). Stations are found by tag (MinigameStation / MinigamePeeker /
-- MinigameCase) because the map streams in and out.
-- Active games use MinigameClient cinematic stages and Blender-authored props.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local UIKit = require(Shared:WaitForChild("UIKit")) :: any
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Minigame") :: RemoteEvent

local player = Players.LocalPlayer
local CFG = Config.Minigames
local FONT = Font.fromEnum(Enum.Font.GothamBlack)
local INK = UIKit.Colors.Ink
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 46)
local GREEN = Color3.fromRGB(98, 205, 48)
local RED = Color3.fromRGB(235, 64, 64)
local WOOD = Color3.fromRGB(150, 88, 50)
local WOOD_DARK = Color3.fromRGB(96, 54, 32)

local function now(): number
	return workspace:GetServerTimeNow()
end

------------------------------------------------------------------ gui helpers
local gui = Instance.new("ScreenGui")
gui.Name = "Minigames"
gui.ResetOnSpawn = false
gui.DisplayOrder = 35
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui:SetAttribute("NoSkin", true)
gui.Parent = player:WaitForChild("PlayerGui")

local boards = Instance.new("Folder")
boards.Name = "MinigameBoards"
boards.Parent = player.PlayerGui

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function stroke(obj: GuiObject, thickness: number, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Color = color or INK
	s.Thickness = thickness
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = obj
	return s
end

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, color: Color3?, outline: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(x, y)
	l.Size = UDim2.fromScale(w, h)
	l.FontFace = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color or WHITE
	if outline and outline > 0 then
		local s = stroke(l, outline)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end
	l.Parent = parent
	return l
end

local function blob(parent: Instance, color: Color3, x: number, y: number, w: number, h: number, z: number?, round: number?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(round or 0.5, 0)
	c.Parent = f
	f.Parent = parent
	return f
end

local function toast(text: string)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.fromScale(0.5, 0.16)
	f.Size = UDim2.new(0.5, 0, 0, 58)
	f.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
	f.Parent = gui
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(520, 70)
	c.Parent = f
	UIKit.corner(f, 16)
	UIKit.outline(f, 4)
	UIKit.shade(f, 1.05, 0.72)
	label(f, text, 0.5, 0.5, 0.92, 0.66, WHITE, 2.5)
	local s = Instance.new("UIScale")
	s.Scale = 0.3
	s.Parent = f
	tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.4, function()
		tween(s, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.25)
		f:Destroy()
	end)
end

------------------------------------------------------------------ server messages
-- Only the cinematic modules own active gameplay; idle map displays are separate.
local Cinema = ReplicatedStorage:WaitForChild("MinigameClient")
local activeGame
Remote.OnClientEvent:Connect(function(kind, info)
 if kind == "Start" then
  local module = Cinema:FindFirstChild(info.game)
  if module then
   local ok, result = pcall(function() return require(module).start(info, function(...) Remote:FireServer(...) end) end)
   if ok then activeGame=result else require(Cinema.Scene).cancel(); warn(result) end
  end
 elseif kind == "Bonked" then
  if activeGame and activeGame.id==info.id and activeGame.ack then activeGame.ack(info) end
 elseif kind == "Result" then
  if activeGame and activeGame.id==info.id then activeGame.result(info) end
 elseif kind == "Note" then toast(info.text) end
end)

------------------------------------------------------------------ station status boards
local function formatWait(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

type Board = { station: Model, id: string, gui: BillboardGui, status: TextLabel, pill: Frame }
local stationBoards: { [Model]: Board } = {}

local function addStation(station: Instance)
	if not station:IsA("Model") or stationBoards[station] then
		return
	end
	local id = station:GetAttribute("Minigame")
	local anchor = station:WaitForChild("StatusAnchor", 10)
	if type(id) ~= "string" or not anchor or not CFG[id] or not station.Parent then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Board_" .. id
	bb.Adornee = anchor :: BasePart
	bb.Size = UDim2.fromOffset(230, 96)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = boards
	local name = label(bb, string.upper(CFG[id].Name), 0.5, 0.25, 1, 0.42, UIKit.Colors.TextGold, 3)
	name.ZIndex = 2
	local pill = blob(bb, GREEN, 0.5, 0.72, 0.62, 0.44, 1, 0.5)
	stroke(pill, 3)
	UIKit.shade(pill, 1.05, 0.75)
	local status = label(pill, "PLAY!", 0.5, 0.5, 0.86, 0.8, WHITE, 2.5)
	status.ZIndex = 3
	stationBoards[station] = { station = station, id = id, gui = bb, status = status, pill = pill }
end

local function removeStation(station: Instance)
	local b = stationBoards[station :: Model]
	if b then
		b.gui:Destroy()
		stationBoards[station :: Model] = nil
	end
end

CollectionService:GetInstanceAddedSignal("MinigameStation"):Connect(function(s)
	task.spawn(addStation, s)
end)
CollectionService:GetInstanceRemovedSignal("MinigameStation"):Connect(removeStation)
for _, s in CollectionService:GetTagged("MinigameStation") do
	task.spawn(addStation, s)
end

task.spawn(function()
	while true do
		for _, b in stationBoards do
			local readyAt = player:GetAttribute("Minigame" .. b.id .. "Ready")
			local left = if type(readyAt) == "number" then readyAt - now() else 0
			if left > 0.5 then
				b.status.Text = "⏱ " .. formatWait(left)
				b.pill.BackgroundColor3 = Color3.fromRGB(110, 104, 140)
			else
				b.status.Text = "PLAY!"
				b.pill.BackgroundColor3 = GREEN
			end
		end
		task.wait(0.25)
	end
end)

------------------------------------------------------------------ idle animation of the stations (local only)
local camera = workspace.CurrentCamera
local function near(model: Model): boolean
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	return ok and (pivot.Position - camera.CFrame.Position).Magnitude < 160
end

-- robbers peek out of the bench windows now and then
type Peeker = { model: Model, rest: CFrame, alpha: number, up: boolean, nextAt: number }
local peekers: { [Model]: Peeker } = {}
local HIDE_DROP = 2.4
local function addPeeker(m: Instance)
	if not m:IsA("Model") then
		return
	end
	local rest = m:GetAttribute("Rest")
	if typeof(rest) ~= "CFrame" then
		return
	end
	peekers[m] = { model = m, rest = rest, alpha = 0, up = false, nextAt = os.clock() + math.random() * 3 }
	m:PivotTo(rest * CFrame.new(0, -HIDE_DROP, 0))
end
CollectionService:GetInstanceAddedSignal("MinigamePeeker"):Connect(addPeeker)
CollectionService:GetInstanceRemovedSignal("MinigamePeeker"):Connect(function(m)
	peekers[m :: Model] = nil
end)
for _, m in CollectionService:GetTagged("MinigamePeeker") do
	addPeeker(m)
end

-- briefcases slide around the table, swapping places
type CaseModel = { model: Model, slot: number, from: CFrame, to: CFrame, start: number, lift: number }
local caseModels: { [Model]: CaseModel } = {}
local slotRest: { [Instance]: { [number]: CFrame } } = {} -- station -> slot -> rest pivot
local function addCase(m: Instance)
	if not m:IsA("Model") then
		return
	end
	local rest, slot = m:GetAttribute("Rest"), m:GetAttribute("Slot")
	if typeof(rest) ~= "CFrame" or type(slot) ~= "number" then
		return
	end
	local station = m.Parent :: Instance
	slotRest[station] = slotRest[station] or {}
	slotRest[station][slot] = rest
	caseModels[m] = { model = m, slot = slot, from = rest, to = rest, start = 0, lift = 0 }
end
CollectionService:GetInstanceAddedSignal("MinigameCase"):Connect(addCase)
CollectionService:GetInstanceRemovedSignal("MinigameCase"):Connect(function(m)
	caseModels[m :: Model] = nil
end)
for _, m in CollectionService:GetTagged("MinigameCase") do
	addCase(m)
end

local nextShuffle = os.clock() + 2
local SHUFFLE_TIME = 0.7
local bulbTick = 0
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for m, p in peekers do
		if not m.Parent then
			peekers[m] = nil
			continue
		end
		if t >= p.nextAt then
			p.up = not p.up
			p.nextAt = t + (if p.up then 0.9 + math.random() * 0.8 else 1.2 + math.random() * 3)
		end
		local target = if p.up then 1 else 0
		if p.alpha ~= target and near(m) then
			p.alpha = if target > p.alpha then math.min(1, p.alpha + dt * 7) else math.max(0, p.alpha - dt * 7)
			m:PivotTo(p.rest * CFrame.new(0, -HIDE_DROP * (1 - p.alpha), 0))
		end
	end

	-- every few seconds two briefcases on each table swap places with a little hop
	if t >= nextShuffle then
		nextShuffle = t + 2.5 + math.random() * 1.5
		local byStation: { [Instance]: { CaseModel } } = {}
		for m, c in caseModels do
			if m.Parent and near(m) then
				byStation[m.Parent :: Instance] = byStation[m.Parent :: Instance] or {}
				table.insert(byStation[m.Parent :: Instance], c)
			end
		end
		for station, list in byStation do
			local rests = slotRest[station]
			if #list >= 2 and rests then
				local i = math.random(1, #list)
				local j = math.random(1, #list - 1)
				if j >= i then
					j += 1
				end
				local a, b = list[i], list[j]
				a.slot, b.slot = b.slot, a.slot
				for _, c in { a, b } do
					c.from = c.model:GetPivot()
					c.to = rests[c.slot] or c.from
					c.start = t
				end
				a.lift, b.lift = 1.2, 0
			end
		end
	end
	for m, c in caseModels do
		local a = (t - c.start) / SHUFFLE_TIME
		if a >= 0 and a <= 1 and m.Parent then
			local e = (1 - math.cos(a * math.pi)) / 2
			m:PivotTo(c.from:Lerp(c.to, e) * CFrame.new(0, c.lift * math.sin(a * math.pi), 0))
		elseif a > 1 and a < 1.5 and m.Parent then
			m:PivotTo(c.to)
		end
	end

	-- marquee bulbs chase
	bulbTick += dt
	if bulbTick >= 0.45 then
		bulbTick = 0
		for _, station in CollectionService:GetTagged("MinigameStation") do
			for _, b in station:GetChildren() do
				if b:IsA("BasePart") and b:GetAttribute("Bulb") then
					b.Color = if b.Color.R > 0.99 and b.Color.G < 0.6 then GOLD else Color3.fromRGB(255, 120, 190)
				end
			end
		end
	end
end)
