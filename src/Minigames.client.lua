--!strict
-- Hub minigames, client side (server: Server.MinigameService; tuning: Config.Minigames).
--   GAVEL BONK: whack-a-mole on a 3x3 bench. Bonk the robbers, leave the friendly judge alone.
--   LUCKY BRIEFCASE: watch which case holds the star, follow the shuffle, pick one. Every case wins.
-- Also runs the stations themselves: a status board over each one (PLAY! / ready in m:ss, from the player
-- attribute Minigame<Id>Ready) and their idle animation (robbers peeking out of the bench, briefcases
-- sliding about, marquee bulbs blinking). Stations are found by tag (MinigameStation / MinigamePeeker /
-- MinigameCase) because the map streams in and out.
-- Everything is drawn from Frames (no image assets) in the Shared.UIKit style; the ScreenGui is tagged NoSkin
-- so UISkin leaves it alone.

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
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
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

------------------------------------------------------------------ sounds (same licensed sounds as StarterPlayerScripts.Sounds)
local sfxGroup = SoundService:WaitForChild("SFX", 5) :: SoundGroup?
local SOUNDS = {
	bonk = { id = "rbxassetid://9125574353", volume = 0.7, speed = 1.3 },
	oops = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, speed = 0.5 },
	pop = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.12, speed = 2.2 },
	coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, speed = 1.25 },
	go = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, speed = 1.7 },
	win = { id = "rbxassetid://1844278029", volume = 0.5, speed = 1, cut = 2.4 },
	big = { id = "rbxassetid://9045751375", volume = 0.55, speed = 1 },
}
local sounds: { [string]: Sound } = {}
for name, info in SOUNDS do
	local s = Instance.new("Sound")
	s.Name = "Minigame_" .. name
	s.SoundId = info.id
	s.Volume = info.volume
	s.PlaybackSpeed = info.speed
	s.SoundGroup = sfxGroup
	s.Parent = SoundService
	sounds[name] = s
end
local function play(name: string)
	local s = sounds[name]
	local info = (SOUNDS :: any)[name]
	if not s then
		return
	end
	s.TimePosition = 0
	s.Volume = info.volume
	s:Play()
	if info.cut then
		local playing = os.clock()
		s:SetAttribute("PlayedAt", playing)
		task.delay(info.cut, function()
			if s:GetAttribute("PlayedAt") == playing then
				TweenService:Create(s, TweenInfo.new(0.4), { Volume = 0 }):Play()
			end
		end)
	end
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

-- a rounded box (round = corner radius as a share of the smaller side; 0.5 = pill / circle)
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

local function square(f: GuiObject)
	local a = Instance.new("UIAspectRatioConstraint")
	a.AspectRatio = 1
	a.Parent = f
end

local function backdrop(): Frame
	local f = Instance.new("Frame")
	f.Name = "Backdrop"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = 1
	f.Active = true -- taps on the dim area don't fall through to the world
	f.Parent = gui
	tween(f, 0.25, { BackgroundTransparency = 0.45 })
	return f
end

-- the game board: a navy checker panel (Figma "Panel") with a coloured ribbon header
local function gamePanel(parent: Instance, title: string, ribbon: Color3, aspect: number): Frame
	local p = Instance.new("Frame")
	p.Name = "Panel"
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.53)
	p.Size = UDim2.fromScale(0.92, 0.82)
	p.Parent = parent
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = aspect
	ar.Parent = p
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(560, 680)
	sc.Parent = p
	UIKit.skinPanel(p)
	local r = Instance.new("Frame")
	r.Name = "Ribbon"
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.fromScale(0.5, 0)
	r.Size = UDim2.fromScale(0.8, 0.11)
	r.BackgroundColor3 = ribbon
	r.ZIndex = 5
	r.Parent = p
	UIKit.corner(r, 16)
	UIKit.outline(r, 4)
	UIKit.skinColored(r)
	local t = label(r, title, 0.5, 0.5, 0.9, 0.78, WHITE, 3)
	t.ZIndex = 6
	UIKit.popIn(p)
	return p
end

local function popText(parent: Instance, text: string, color: Color3, x: number, y: number, size: number)
	local l = label(parent, text, x, y, size, size * 0.4, color, 3)
	l.ZIndex = 20
	l.Rotation = math.random(-12, 12)
	local s = Instance.new("UIScale")
	s.Scale = 0.4
	s.Parent = l
	tween(s, 0.18, { Scale = 1.15 }, Enum.EasingStyle.Back)
	task.delay(0.35, function()
		tween(l, 0.3, { TextTransparency = 1, Position = UDim2.fromScale(x, y - 0.12) })
		local st = l:FindFirstChildOfClass("UIStroke")
		if st then
			tween(st, 0.3, { Transparency = 1 })
		end
		task.wait(0.32)
		l:Destroy()
	end)
end

local function sparkle(parent: Instance, x: number, y: number, color: Color3)
	for i = 1, 5 do
		local d = blob(parent, color, x, y, 0.08, 0.08, 19)
		square(d)
		stroke(d, 1.5)
		local a = (i / 5) * math.pi * 2 + math.random() * 0.6
		tween(d, 0.35, { Position = UDim2.fromScale(x + math.cos(a) * 0.32, y + math.sin(a) * 0.32), BackgroundTransparency = 1 })
		task.delay(0.36, function()
			d:Destroy()
		end)
	end
end

local function shake(obj: GuiObject)
	local base = obj.Position
	task.spawn(function()
		for i = 1, 6 do
			local o = if i % 2 == 0 then 8 else -8
			obj.Position = base + UDim2.fromOffset(o * (1 - i / 7), 0)
			task.wait(0.035)
		end
		obj.Position = base
	end)
end

------------------------------------------------------------------ the characters (drawn from frames)
-- Draws into `holder` (a frame the size of a bench window); the head is centred a bit above the middle.
local function drawRobber(holder: Frame)
	local body = blob(holder, Color3.fromRGB(40, 40, 52), 0.5, 0.98, 0.76, 0.44, 1, 0.3)
	for _, y in { 0.3, 0.62 } do
		local s = Instance.new("Frame")
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Position = UDim2.fromScale(0.5, y)
		s.Size = UDim2.fromScale(0.92, 0.15)
		s.BackgroundColor3 = WHITE
		s.BorderSizePixel = 0
		s.Parent = body
	end
	local head = blob(holder, Color3.fromRGB(255, 204, 77), 0.5, 0.48, 0.62, 0.62, 2)
	square(head)
	stroke(head, 2.5)
	blob(head, Color3.fromRGB(30, 30, 40), 0.5, 0.5, 1.04, 0.28, 3, 0.45) -- the mask
	for _, x in { 0.32, 0.68 } do
		local eye = blob(head, WHITE, x, 0.5, 0.24, 0.24, 4)
		square(eye)
		local pupil = blob(eye, INK, 0.58, 0.55, 0.48, 0.48, 5)
		square(pupil)
	end
	blob(head, Color3.fromRGB(150, 60, 40), 0.5, 0.8, 0.3, 0.08, 3) -- grumpy mouth
	blob(head, Color3.fromRGB(36, 36, 48), 0.5, 0.1, 1.0, 0.46, 6) -- beanie
	blob(head, Color3.fromRGB(60, 60, 76), 0.5, 0.3, 1.08, 0.15, 7, 0.4) -- beanie brim
	local pom = blob(head, RED, 0.5, -0.13, 0.26, 0.26, 7)
	square(pom)
end

local function drawJudge(holder: Frame)
	local robe = blob(holder, Color3.fromRGB(30, 30, 40), 0.5, 0.98, 0.8, 0.44, 1, 0.3)
	blob(robe, WHITE, 0.5, 0.14, 0.34, 0.26, 2, 0.3) -- collar
	local badge = blob(robe, GOLD, 0.5, 0.5, 0.16, 0.16, 2)
	square(badge)
	-- curly white wig behind the head
	for _, x in { 0.23, 0.77 } do
		for _, y in { 0.38, 0.56, 0.74 } do
			local c = blob(holder, WHITE, x, y, 0.22, 0.22, 2)
			square(c)
			stroke(c, 1.5)
		end
	end
	blob(holder, WHITE, 0.5, 0.2, 0.52, 0.22, 2)
	local head = blob(holder, Color3.fromRGB(255, 214, 170), 0.5, 0.5, 0.56, 0.56, 3)
	square(head)
	stroke(head, 2.5)
	for _, x in { 0.33, 0.67 } do
		local e = blob(head, INK, x, 0.44, 0.13, 0.13, 4)
		square(e)
		local cheek = blob(head, Color3.fromRGB(255, 130, 150), x - 0.08 * (if x < 0.5 then 1 else -1), 0.62, 0.16, 0.12, 4)
		cheek.BackgroundTransparency = 0.35
	end
	local smile = blob(head, Color3.fromRGB(255, 214, 170), 0.5, 0.66, 0.42, 0.24, 4)
	stroke(smile, 3, Color3.fromRGB(120, 50, 40))
	local cover = Instance.new("Frame") -- hides the top of the oval: a U-shaped smile
	cover.AnchorPoint = Vector2.new(0.5, 1)
	cover.Position = UDim2.fromScale(0.5, 0.66)
	cover.Size = UDim2.fromScale(0.5, 0.16)
	cover.BackgroundColor3 = Color3.fromRGB(255, 214, 170)
	cover.BorderSizePixel = 0
	cover.ZIndex = 5
	cover.Parent = head
	blob(holder, WHITE, 0.5, 0.17, 0.6, 0.16, 4) -- wig top, over the head
end

local function drawGavel(parent: Instance): Frame
	local g = Instance.new("Frame")
	g.Name = "Gavel"
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.fromScale(0.68, 0.36)
	g.Size = UDim2.fromScale(0.75, 0.75)
	g.BackgroundTransparency = 1
	g.ZIndex = 15
	g.Visible = false
	g.Parent = parent
	local handle = blob(g, WOOD, 0.62, 0.62, 0.12, 0.66, 15, 0.5)
	handle.Rotation = -45
	stroke(handle, 2)
	local head = blob(g, WOOD_DARK, 0.36, 0.36, 0.56, 0.3, 16, 0.3)
	head.Rotation = -45
	stroke(head, 2.5)
	for _, x in { 0.24, 0.76 } do
		local band = Instance.new("Frame")
		band.AnchorPoint = Vector2.new(0.5, 0.5)
		band.Position = UDim2.fromScale(x, 0.5)
		band.Size = UDim2.fromScale(0.1, 1)
		band.BackgroundColor3 = GOLD
		band.BorderSizePixel = 0
		band.ZIndex = 17
		band.Parent = head
	end
	return g
end

------------------------------------------------------------------ toasts + result screen
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

local overlay: Frame? = nil -- the open minigame (one at a time)

local function closeOverlay()
	if overlay then
		overlay:Destroy()
		overlay = nil
	end
end

local function showResult(title: string, reward: string, stars: number?, extra: string?, bigWin: boolean)
	closeOverlay()
	local root = backdrop()
	overlay = root
	local p = Instance.new("Frame")
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.5)
	p.Size = UDim2.fromScale(0.82, 0.5)
	p.Parent = root
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1.25
	ar.Parent = p
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(480, 384)
	sc.Parent = p
	UIKit.skinPanel(p)
	local burst = UIKit.burst(p, if bigWin then GOLD else Color3.fromRGB(150, 220, 255), 560)
	burst.ZIndex = 0
	label(p, title, 0.5, 0.15, 0.9, 0.2, UIKit.Colors.TextGold, 4)
	if stars then
		for i = 1, 3 do
			local st = label(p, "★", 0.3 + (i - 1) * 0.2, 0.36, 0.2, 0.2, if i <= stars then GOLD else Color3.fromRGB(90, 86, 120), 3)
			local s = Instance.new("UIScale")
			s.Scale = 0
			s.Parent = st
			task.delay(0.15 + i * 0.18, function()
				tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
				if i <= stars then
					play("coin")
				end
			end)
		end
	end
	label(p, reward, 0.5, if stars then 0.56 else 0.45, 0.88, 0.18, WHITE, 3.5)
	if extra then
		label(p, extra, 0.5, if stars then 0.7 else 0.62, 0.8, 0.1, UIKit.Colors.TextSoft, 2)
	end
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.fromScale(0.5, 0.86)
	btn.Size = UDim2.fromScale(0.42, 0.16)
	btn.BackgroundColor3 = GREEN
	btn.FontFace = FONT
	btn.Text = "YAY!"
	btn.TextScaled = true
	btn.TextColor3 = WHITE
	btn.Parent = p
	UIKit.skinButton(btn, "color")
	UIKit.popIn(p)
	play(if bigWin then "big" else "win")
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		if overlay == root then
			closeOverlay()
		end
	end
	btn.Activated:Connect(close)
	task.delay(8, close)
end

------------------------------------------------------------------ GAVEL BONK (3D booth scene; only score + timer remain in the HUD)
type Hole = { hitbox: BasePart, actor: Model, rest: CFrame, current: any, token: number }

local bonk: any = nil

local function moveModel(model: Model, from: CFrame, to: CFrame, duration: number, easing: ((number) -> number)?)
	local started = os.clock()
	while model.Parent do
		local a = math.clamp((os.clock() - started) / duration, 0, 1)
		local alpha = if easing then easing(a) else a
		model:PivotTo(from:Lerp(to, alpha))
		if a >= 1 then break end
		RunService.RenderStepped:Wait()
	end
end

local function setActorVisible(model: Model, visible: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.LocalTransparencyModifier = if visible then 0 else 1 end
	end
end

local function hideHole(hole: Hole, fast: boolean?)
	local pop = hole.current
	hole.current = nil
	hole.token += 1
	local token = hole.token
	task.spawn(function()
		local from = hole.actor:GetPivot()
		moveModel(hole.actor, from, hole.rest * CFrame.new(0, -1.25, 0), if fast then 0.08 else 0.13, function(a) return a * a end)
		if hole.token == token then setActorVisible(hole.actor, false) end
	end)
end

local function showPop(hole: Hole, pop: any)
	hole.current = pop
	hole.token += 1
	local token = hole.token
	setActorVisible(hole.actor, true)
	local from = hole.rest * CFrame.new(0, -1.25, 0)
	local to = hole.rest
	hole.actor:PivotTo(from)
	if pop.kind == "Judge" then
		for _, d in hole.actor:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = if d.Name == "Head" then Color3.fromRGB(255, 220, 175) else Color3.fromRGB(55, 65, 110)
			end
		end
	else
		for _, d in hole.actor:GetDescendants() do
			if d:IsA("BasePart") then d.Color = if d.Name == "Head" then Color3.fromRGB(255, 205, 70) else Color3.fromRGB(45, 45, 58) end
		end
	end
	task.spawn(function()
		moveModel(hole.actor, from, to, 0.14, function(a) return 1 - (1 - a) ^ 3 end)
		if hole.token ~= token then return end
	end)
	play("pop")
end

local function onTap(hole: Hole)
	local r = bonk
	if not r or r.over or not hole.current then return end
	local elapsed = now() - r.startAt
	if elapsed < 0 or elapsed > r.duration then return end
	local pop = hole.current
	hole.current = nil
	Remote:FireServer("Bonk", r.id, pop.id)
	local before = hole.actor:GetPivot()
	task.spawn(function()
		local direction = if pop.kind == "Judge" then 1 else -1
		moveModel(hole.actor, before, before * CFrame.new(0, direction * 0.6, 0) * CFrame.Angles(math.rad(16), 0, 0), 0.1)
	end)
	if pop.kind == "Robber" then
		r.localScore += 1
		play("bonk")
	else
		r.localScore = math.max(0, r.localScore - CFG.GavelBonk.JudgePenalty)
		play("oops")
	end
	r.scoreLabel.Text = tostring(r.localScore)
	task.delay(0.12, function()
		if hole.current == nil then hideHole(hole, true) end
	end)
end

local function startBonk(info: any)
	closeOverlay()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local oldCameraType, oldSubject, oldCFrame, oldFov = camera.CameraType, camera.CameraSubject, camera.CFrame, camera.FieldOfView
	local stage = Instance.new("Folder")
	stage.Name = "LocalGavelBonkStage"
	stage.Parent = workspace
	local origin = rootPart.Position + rootPart.CFrame.LookVector * 9
	local face = CFrame.lookAt(origin, rootPart.Position)
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
		p.Parent = stage
		return p
	end
	local deckCF = face * CFrame.new(0, -1.2, 0)
	part("Wooden Bench", Vector3.new(12, 0.5, 6), deckCF, WOOD, Enum.Material.WoodPlanks)
	part("Gold Trim", Vector3.new(12.12, 0.12, 6.12), deckCF * CFrame.new(0, 0.28, 0), GOLD, Enum.Material.Metal)
	local holes: { Hole } = {}
	local hub = workspace:FindFirstChild("Hub")
	local spots = hub and hub:FindFirstChild("SpecialSpots")
	local sourceModel = spots and spots:FindFirstChild("SpecialSpot1")
	local sourceBooth = sourceModel and sourceModel:FindFirstChild("Station")
	local sourceActor = sourceBooth and sourceBooth:FindFirstChild("Peeker1")
	for i = 1, info.holes do
		local row, col = math.floor((i - 1) / 3), (i - 1) % 3
		local localCF = CFrame.new((col - 1) * 3.6, 0.35, (row - 1) * 1.65)
		local holeCF = deckCF * localCF
		local rim = part("Brick Target " .. i, Vector3.new(2.7, 0.45, 1.45), holeCF, Color3.fromRGB(135, 76, 42), Enum.Material.Brick)
		local hitbox = part("Hit " .. i, Vector3.new(2.5, 1.4, 1.25), holeCF * CFrame.new(0, 0.9, 0), Color3.fromRGB(45, 27, 23), Enum.Material.SmoothPlastic)
		hitbox.Transparency = 1
		local actor: Model
		if sourceActor and sourceActor:IsA("Model") then
			actor = sourceActor:Clone()
		else
			actor = Instance.new("Model")
			local head = Instance.new("Part")
			head.Name, head.Shape, head.Size, head.Color = "Head", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1), GOLD
			head.Parent = actor
		end
		actor.Name = "Popper " .. i
		for _, d in actor:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanTouch, d.CanQuery = true, false, false, true end
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then d:Destroy() end
		end
		actor.Parent = stage
		local rest = holeCF * CFrame.new(0, 1.25, 0)
		actor:PivotTo(rest * CFrame.new(0, -1.25, 0))
		setActorVisible(actor, false)
		table.insert(holes, { hitbox = hitbox, actor = actor, rest = rest, current = nil, token = 0 })
		local trim = rim
		trim.TopSurface, trim.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	end
	local scoreHud = Instance.new("ScreenGui")
	scoreHud.Name, scoreHud.IgnoreGuiInset, scoreHud.ResetOnSpawn, scoreHud.DisplayOrder = "BonkStatus", true, false, 36
	scoreHud.Parent = player.PlayerGui
	local scoreLabel = label(scoreHud, "0", 0.5, 0.08, 0.12, 0.07, GOLD, 2.5)
	local timerBack = blob(scoreHud, Color3.fromRGB(30, 26, 52), 0.5, 0.15, 0.34, 0.025, 3, 0.5)
	local timerFill = blob(timerBack, GREEN, 0.5, 0.5, 1, 1, 4, 0.5)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 52
	camera.CFrame = CFrame.lookAt((face * CFrame.new(0, 9, 15)).Position, origin + Vector3.new(0, 1, 0))
	local r = { id = info.id, startAt = info.startAt, duration = info.duration, pops = info.pops, nextPop = 1, over = false, localScore = 0, scoreLabel = scoreLabel, holes = holes, stage = stage, camera = camera, oldCameraType = oldCameraType, oldSubject = oldSubject, oldCFrame = oldCFrame, oldFov = oldFov, gui = scoreHud, timerFill = timerFill }
	bonk = r
	local function tapAt(position: Vector2)
		if bonk ~= r or r.over then return end
		local ray = camera:ScreenPointToRay(position.X, position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { stage }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		if not hit then return end
		for _, hole in holes do
			if hit.Instance == hole.hitbox or hit.Instance:IsDescendantOf(hole.actor) then onTap(hole); return end
		end
	end
	local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then tapAt(Vector2.new(input.Position.X, input.Position.Y)) end
	end)
	r.inputConn = inputConn
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if bonk ~= r or not stage.Parent then conn:Disconnect(); return end
		local elapsed = now() - r.startAt
		local left = math.clamp(1 - elapsed / r.duration, 0, 1)
		timerFill.Size = UDim2.fromScale(left, 1)
		timerFill.BackgroundColor3 = if left > 0.5 then GREEN elseif left > 0.2 then GOLD else RED
		while r.nextPop <= #r.pops and elapsed >= r.pops[r.nextPop].t do
			local pop = r.pops[r.nextPop]; r.nextPop += 1
			local hole = holes[pop.hole]
			if hole then showPop(hole, pop) end
		end
		for _, hole in holes do if hole.current and elapsed >= hole.current.t + hole.current.stay then hideHole(hole) end end
		if elapsed >= r.duration and not r.over then
			r.over = true
			for _, hole in holes do hideHole(hole, true) end
			label(scoreHud, "TIME'S UP!", 0.5, 0.21, 0.36, 0.06, UIKit.Colors.TextGold, 3)
		end
	end)
end

local function cleanupBonk(r: any)
	if r.inputConn then r.inputConn:Disconnect() end
	if r.stage then r.stage:Destroy() end
	if r.gui then r.gui:Destroy() end
	local camera = r.camera :: Camera?
	if camera and camera.Parent then
		camera.CameraType = r.oldCameraType
		camera.CameraSubject = r.oldSubject
		camera.CFrame = r.oldCFrame
		camera.FieldOfView = r.oldFov
	end
end

------------------------------------------------------------------ LUCKY BRIEFCASE
local SLOT_X = { 0.2, 0.5, 0.8 }
local CASE_Y = 0.6

local brief: any = nil

local function makeCase(parent: Instance, slot: number): Frame
	local c = Instance.new("Frame")
	c.Name = "Case"
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	c.Position = UDim2.fromScale(SLOT_X[slot], CASE_Y)
	c.Size = UDim2.fromScale(0.26, 0.36)
	c.BackgroundTransparency = 1
	c.ZIndex = 5
	c.Parent = parent
	local scale = Instance.new("UIScale")
	scale.Parent = c
	local prize = blob(c, WHITE, 0.5, 0.45, 0.62, 0.48, 3) -- pops up out of the case (behind it)
	prize.Name = "Prize"
	square(prize)
	stroke(prize, 3)
	prize.Visible = false
	local icon = label(prize, "", 0.5, 0.5, 0.8, 0.8, GOLD, 3)
	icon.Name = "Icon"
	icon.ZIndex = 4
	local handle = blob(c, Color3.new(0, 0, 0), 0.5, 0.06, 0.4, 0.22, 4, 0.45)
	handle.BackgroundTransparency = 1
	stroke(handle, 5, Color3.fromRGB(40, 30, 30))
	local body = blob(c, WOOD, 0.5, 0.6, 1, 0.76, 6, 0.14)
	body.Name = "Body"
	stroke(body, 3.5)
	UIKit.shade(body, 1.08, 0.75)
	local seam = Instance.new("Frame")
	seam.AnchorPoint = Vector2.new(0.5, 0.5)
	seam.Position = UDim2.fromScale(0.5, 0.3)
	seam.Size = UDim2.fromScale(1, 0.06)
	seam.BackgroundColor3 = WOOD_DARK
	seam.BorderSizePixel = 0
	seam.ZIndex = 7
	seam.Parent = body
	for _, x in { 0.25, 0.75 } do
		local clasp = blob(body, GOLD, x, 0.3, 0.13, 0.15, 8, 0.25)
		stroke(clasp, 2)
	end
	local btn = Instance.new("TextButton")
	btn.Name = "Pick"
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Size = UDim2.fromScale(1.1, 1.1)
	btn.Position = UDim2.fromScale(-0.05, -0.05)
	btn.ZIndex = 30
	btn.Active = false
	btn.Parent = c
	return c
end

local function setPrize(case: Frame, kind: string)
	local prize = case:FindFirstChild("Prize") :: Frame
	local icon = prize:FindFirstChild("Icon") :: TextLabel
	if kind == "Star" then
		prize.BackgroundColor3 = Color3.fromRGB(255, 236, 150)
		icon.Text = "★"
		icon.TextColor3 = Color3.fromRGB(255, 190, 20)
	elseif kind == "Egg" then
		prize.BackgroundColor3 = Color3.fromRGB(255, 200, 235)
		icon.Text = "🥚"
		icon.TextColor3 = WHITE
	else
		prize.BackgroundColor3 = Color3.fromRGB(200, 240, 190)
		icon.Text = "💰"
		icon.TextColor3 = WHITE
	end
end

local function openCase(case: Frame, kind: string)
	setPrize(case, kind)
	local prize = case:FindFirstChild("Prize") :: Frame
	prize.Visible = true
	prize.Position = UDim2.fromScale(0.5, 0.45)
	tween(prize, 0.3, { Position = UDim2.fromScale(0.5, -0.32) }, Enum.EasingStyle.Back)
	local body = case:FindFirstChild("Body") :: Frame
	body.Rotation = -6
	tween(body, 0.3, { Rotation = 0 }, Enum.EasingStyle.Back)
end

local function closeCase(case: Frame)
	local prize = case:FindFirstChild("Prize") :: Frame
	tween(prize, 0.2, { Position = UDim2.fromScale(0.5, 0.45) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.21, function()
		prize.Visible = false
	end)
end

local function startBrief(info: any)
	closeOverlay()
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camera = workspace.CurrentCamera
	if not rootPart or not camera then return end
	local oldType, oldSubject, oldCFrame, oldFov = camera.CameraType, camera.CameraSubject, camera.CFrame, camera.FieldOfView
	local stage = Instance.new("Folder")
	stage.Name = "LocalLuckyBriefcaseStage"
	stage.Parent = workspace
	local origin = rootPart.Position + rootPart.CFrame.LookVector * 9
	local face = CFrame.lookAt(origin, rootPart.Position)
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
		p.Parent = stage
		return p
	end
	local tableCF = face * CFrame.new(0, -1.1, 0)
	part("Brick Table", Vector3.new(12, 0.5, 5.4), tableCF, Color3.fromRGB(53, 117, 61), Enum.Material.Brick)
	part("Gold Table Edge", Vector3.new(12.2, 0.18, 5.6), tableCF * CFrame.new(0, 0.32, 0), GOLD, Enum.Material.Metal)
	local cases: { [number]: Model } = {}
	local lids: { [number]: BasePart } = {}
	local bases: { [number]: BasePart } = {}
	local atSlot: { number } = { 1, 2, 3 }
	for i = 1, 3 do
		local rest = tableCF * CFrame.new((i - 2) * 3.6, 1, 0)
		local model = Instance.new("Model")
		model.Name = "Case " .. i
		local body = part("Briefcase Body", Vector3.new(2.5, 1.1, 1.8), rest, Color3.fromRGB(141, 83, 45), Enum.Material.WoodPlanks)
		body.Parent = model
		local lid = part("Briefcase Lid", Vector3.new(2.5, 0.25, 1.8), rest * CFrame.new(0, 0.65, 0), Color3.fromRGB(105, 58, 36), Enum.Material.WoodPlanks)
		lid.Parent = model
		local clasp = part("Gold Clasp", Vector3.new(0.35, 0.28, 0.14), rest * CFrame.new(0, 0.1, -0.94), GOLD, Enum.Material.Metal)
		clasp.Parent = model
		model.PrimaryPart = body
		model.Parent = stage
		model:PivotTo(rest)
		cases[i], lids[i], bases[i] = model, lid, body
	end
	local status = Instance.new("ScreenGui")
	status.Name, status.IgnoreGuiInset, status.ResetOnSpawn, status.DisplayOrder = "BriefcaseStatus", true, false, 36
	status.Parent = player.PlayerGui
	local hint = label(status, "WATCH THE STAR", 0.5, 0.08, 0.38, 0.06, UIKit.Colors.TextGold, 3)
	local r = { id = info.id, picked = false, cases = cases, atSlot = atSlot, big = info.big, hint = hint, pickable = false, stage = stage, gui = status, camera = camera, oldType = oldType, oldSubject = oldSubject, oldCFrame = oldCFrame, oldFov = oldFov, lids = lids, bases = bases, tableCF = tableCF, info = info }
	brief = r
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 50
	camera.CFrame = CFrame.lookAt((face * CFrame.new(0, 8.5, 15)).Position, origin + Vector3.new(0, 1, 0))
	local function showPrize(identity: number, kind: string)
		local color = if kind == "Star" then GOLD else GREEN
		local item = part(if kind == "Star" then "Star Prize" else "Prize Token", Vector3.new(0.8, 0.8, 0.8), cases[identity]:GetPivot() * CFrame.new(0, 1.2, 0), color, Enum.Material.Neon)
		item.Shape = Enum.PartType.Ball
		if kind == "Star" then item.Shape = Enum.PartType.Block; item.Size = Vector3.new(0.8, 0.8, 0.2) end
		local lid = lids[identity]
		local base = bases[identity]
		TweenService:Create(lid, TweenInfo.new(0.2, Enum.EasingStyle.Back), { CFrame = base.CFrame * CFrame.new(0, 0.65, -0.45) * CFrame.Angles(math.rad(-58), 0, 0) }):Play()
	end
	local moves: { any } = {}
	local finalSlots = { 1, 2, 3 }
	local tClose = info.startAt + info.showTime
	local tSwap = tClose + info.closeTime
	for i, pair in info.swaps do
		local a, b = pair[1], pair[2]
		local ca, cb = finalSlots[a], finalSlots[b]
		table.insert(moves, { case = ca, from = a, to = b, start = tSwap + (i - 1) * info.swapTime, dir = -1 })
		table.insert(moves, { case = cb, from = b, to = a, start = tSwap + (i - 1) * info.swapTime, dir = 1 })
		finalSlots[a], finalSlots[b] = cb, ca
	end
	r.finalSlots = finalSlots
	local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or brief ~= r or not r.pickable or r.picked then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { stage }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		if not hit then return end
		for identity, model in cases do
			if hit.Instance:IsDescendantOf(model) then
				local slot = table.find(r.atSlot, identity)
				if slot then
					r.picked, r.pickable = true, false
					play("pop")
					Remote:FireServer("Pick", r.id, slot)
				end
				return
			end
		end
	end)
	r.inputConn = inputConn
	local phase = "wait"
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if brief ~= r or not stage.Parent then conn:Disconnect(); return end
		local t = now()
		if phase == "wait" and t >= info.startAt then
			phase = "show"
			for identity = 1, 3 do showPrize(identity, if identity == info.big then "Star" else "Coins") end
			play("go")
		elseif phase == "show" and t >= tClose then
			phase = "swap"
			for _, item in stage:GetChildren() do if item.Name == "Star Prize" or item.Name == "Prize Token" then item:Destroy() end end
			hint.Text = "FOLLOW THE STAR"
			for i = 1, 3 do TweenService:Create(lids[i], TweenInfo.new(0.12), { CFrame = bases[i].CFrame * CFrame.new(0, 0.65, 0) }):Play() end
		end
		if phase == "swap" then
			for _, m in moves do
				local a = math.clamp((t - m.start) / info.swapTime, 0, 1)
				if t >= m.start and t <= m.start + info.swapTime then
					local e = (1 - math.cos(a * math.pi)) / 2
					local x = (m.from - 2) * 3.6 + (m.to - m.from) * 3.6 * e
					local y = 1 + m.dir * 0.85 * math.sin(a * math.pi)
					cases[m.case]:PivotTo(tableCF * CFrame.new(x, y, 0))
				end
			end
			if t >= info.pickAt then
				phase = "pick"
				r.pickable = true
				hint.Text = "PICK A CASE!"
				play("go")
				for slot = 1, 3 do
					cases[finalSlots[slot]]:PivotTo(tableCF * CFrame.new((slot - 2) * 3.6, 1, 0))
					r.atSlot[slot] = finalSlots[slot]
				end
			end
		end
	end)
end

local function cleanupBrief(r: any)
	if r.inputConn then r.inputConn:Disconnect() end
	if r.stage then r.stage:Destroy() end
	if r.gui then r.gui:Destroy() end
	local camera = r.camera :: Camera?
	if camera and camera.Parent then
		camera.CameraType, camera.CameraSubject, camera.CFrame, camera.FieldOfView = r.oldType, r.oldSubject, r.oldCFrame, r.oldFov
	end
end

local function briefResult(info: any)
	local r = brief
	if not r or r.id ~= info.id then
		showResult(if info.big then "BIG PRIZE!" else "YOU WON!", info.text, nil, nil, info.big)
		return
	end
	r.pickable, r.picked = false, true
	local pickedIdentity = r.atSlot[info.slot]
	local starIdentity = r.finalSlots[info.finalBig]
	local pickedModel = r.cases[pickedIdentity]
	local lid = r.lids[pickedIdentity]
	local function openLid(partToMove: BasePart)
		local from = partToMove.CFrame
		local goal = from * CFrame.new(0, 0.5, -0.75) * CFrame.Angles(math.rad(-72), 0, 0)
		TweenService:Create(partToMove, TweenInfo.new(0.24, Enum.EasingStyle.Back), { CFrame = goal }):Play()
	end
	if lid then openLid(lid) end
	local item = Instance.new("Part")
	item.Name = if info.big then "Big Prize" else "Prize"
	item.Shape = Enum.PartType.Ball
	item.Size = Vector3.new(0.9, 0.9, 0.9)
	item.Material = Enum.Material.Neon
	item.Color = if info.big then GOLD else GREEN
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
	item.CFrame = pickedModel:GetPivot() * CFrame.new(0, 1.4, 0)
	item.Parent = r.stage
	if info.big then
		item.Shape = Enum.PartType.Block
		item.Size = Vector3.new(0.85, 0.85, 0.2)
	end
	TweenService:Create(item, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = item.Position + Vector3.new(0, 0.8, 0) }):Play()
	play(if info.big then "coin" else "pop")
	if info.big then sparkle(r.gui, 0.5, 0.25, GOLD) end
	r.hint.Text = if info.big then "YOU FOUND THE STAR!" else "NICE PICK!"
	task.delay(0.8, function()
		if brief ~= r then return end
		local finalModel = r.cases[starIdentity]
		if finalModel and starIdentity ~= pickedIdentity then
			local reveal = Instance.new("Part")
			reveal.Name = "The Star"
			reveal.Shape = Enum.PartType.Block
			reveal.Size = Vector3.new(0.85, 0.85, 0.2)
			reveal.Color = GOLD
			reveal.Material = Enum.Material.Neon
			reveal.Anchored, reveal.CanCollide, reveal.CanTouch, reveal.CanQuery = true, false, false, false
			reveal.CFrame = finalModel:GetPivot() * CFrame.new(0, 1.4, 0)
			reveal.Parent = r.stage
			local starLid = r.lids[starIdentity]
			if starLid then openLid(starLid) end
		end
	end)
	task.delay(2.2, function()
		if brief == r then
			brief = nil
			cleanupBrief(r)
			local title = if info.kind == "Egg" then "FREE EGG!" elseif info.big then "BIG PRIZE!" else "YOU WON!"
			showResult(title, info.text, nil, if info.big then nil else "Follow the star next time!", info.big)
		end
	end)
end

------------------------------------------------------------------ server messages
Remote.OnClientEvent:Connect(function(kind: string, info: any)
	if kind == "Start" then
		if info.game == "GavelBonk" then
			startBonk(info)
		elseif info.game == "LuckyBriefcase" then
			startBrief(info)
		end
	elseif kind == "Bonked" then
		local r = bonk
		if r and r.id == info.id then
			r.localScore = info.score
			r.scoreLabel.Text = tostring(info.score)
		end
	elseif kind == "Result" then
		if info.game == "GavelBonk" then
			local r = bonk
			bonk = nil
			if r then cleanupBonk(r) end
			local title = if info.stars >= 3 then "AMAZING!" elseif info.stars == 2 then "GREAT JOB!" else "NICE TRY!"
			local extra = "🔨 " .. info.robbersHit .. " robbers bonked"
			task.delay(if r then 0.6 else 0, function()
				showResult(title, info.text, info.stars, extra, info.stars >= 3)
			end)
		else
			briefResult(info)
		end
	elseif kind == "Note" then
		toast(info.text)
	end
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
