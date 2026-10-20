--!strict
-- ArcadeClient.Kit (ReplicatedStorage.ArcadeClient.Kit; 2026-10-13, mr.robe's session) - the shared pieces of the
-- Arcade Pier's booth games (StarterPlayerScripts.Arcade runs them; one module per game next to this one):
--   window(cfg)              the game's window (Shared.Skin, its colour + name); destroy it with :close()
--   countdown(parent, t)     "3, 2, 1, GO!" until server time t (yields)
--   pop(parent, text, ...)   words that pop in, float up and fade
--   result(win, info)        the result card (title by stars, the line, the reward, OK) - yields until closed
--   sound(name), toast(text), now()
-- Fonts / colours as everywhere (CLAUDE.md): FredokaOne for UI, LuckiestGuy only for the big moments.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local HatchFx = require(Shared:WaitForChild("HatchFx") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any

local player = Players.LocalPlayer
local Kit = {}
Kit.Skin = Skin
Kit.GREEN = Color3.fromRGB(98, 205, 48)
Kit.RED = Color3.fromRGB(240, 70, 70)
Kit.GOLD = Color3.fromRGB(255, 200, 40)
Kit.SKY = Color3.fromRGB(110, 200, 255)
Kit.INK = Color3.fromRGB(40, 40, 52)

function Kit.now(): number
	return workspace:GetServerTimeNow()
end

-- Arcade game actions live on booth props. The booth's existing world screen doubles as the instruction/status panel.
function Kit.boothStatus(station: Instance?, text: string, color: Color3?)
	if not station then return end
	local board = station:FindFirstChild("Board")
	local status = board and board:FindFirstChild("Status", true)
	if status and status:IsA("TextLabel") then
		status.Text = text
		if color then status.TextColor3 = color end
	end
end

function Kit.physicalPrompt(part: BasePart, action: string, object: string, callback: () -> ()): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ArcadeAction"
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = part
	prompt.Triggered:Connect(callback)
	return prompt
end

function Kit.clearPhysicalPrompts(prompts: { ProximityPrompt })
	for _, prompt in prompts do if prompt.Parent then prompt:Destroy() end end
end

-- Match the egg hatch's establishing shot and push in, then restore every local visual when the round ends.
function Kit.enterScene(base: Vector3, front: Vector3, keepGui: LayerCollector?, station: Instance?): any
	local camera = workspace.CurrentCamera
	local playerGui = player:WaitForChild("PlayerGui")
	local state = {
		camera = camera,
		oldType = camera.CameraType,
		oldSubject = camera.CameraSubject,
		oldCFrame = camera.CFrame,
		oldFov = camera.FieldOfView,
		guis = {} :: { [LayerCollector]: boolean },
		parts = {} :: { [Instance]: any },
		stationParts = {} :: { [BasePart]: number },
		stationGuis = {} :: { [LayerCollector]: boolean },
		oldSceneAttribute = player:GetAttribute("MinigameSceneActive"),
	}
	local function hideGui(instance: Instance)
		if instance:IsA("LayerCollector") and instance ~= keepGui and not state.guis[instance] then
			state.guis[instance] = instance.Enabled
			instance.Enabled = false
		end
	end
	for _, instance in playerGui:GetDescendants() do hideGui(instance) end
	state.guiAdded = playerGui.DescendantAdded:Connect(function(instance)
		task.defer(hideGui, instance)
	end)
	if station then
		local function isLocalGameItem(instance: Instance): boolean
			local parent = instance
			while parent and parent ~= station do
				if string.sub(parent.Name, 1, 5) == "Local" then return true end
				parent = parent.Parent
			end
			return false
		end
		-- The booth frame, awning, and old status board cut across the hatch-style camera.
		-- Keep its counter surface and the live physical game model; fade its surrounding shell locally.
		for _, instance in station:GetDescendants() do
			if isLocalGameItem(instance) then continue end
			if instance:IsA("BasePart") and instance.Name ~= "CounterTop" then
				state.stationParts[instance] = instance.LocalTransparencyModifier
				instance.LocalTransparencyModifier = 1
			elseif instance:IsA("LayerCollector") then
				state.stationGuis[instance] = instance.Enabled
				instance.Enabled = false
			end
		end
	end
	local character = player.Character
	if character then
		for _, instance in character:GetDescendants() do
			if instance:IsA("BasePart") then
				state.parts[instance] = { kind = "part", value = instance.LocalTransparencyModifier }
				instance.LocalTransparencyModifier = 1
			elseif instance:IsA("Decal") or instance:IsA("Texture") then
				state.parts[instance] = { kind = "texture", value = instance.Transparency }
				instance.Transparency = 1
			end
		end
	end
	player:SetAttribute("MinigameSceneActive", true)
	local towardPlayer = if front.Magnitude > 0.001 then front.Unit else Vector3.new(0, 0, 1)
	camera.CameraType = Enum.CameraType.Scriptable
	HatchFx.postBegin()
	HatchFx.post({ cc = { Saturation = 0.12, Contrast = 0.06 }, dof = { FarIntensity = 0.35, FocusDistance = 11, InFocusRadius = 5 } }, 0.5)
	local wide = CFrame.lookAt(base + towardPlayer * 11.5 + Vector3.yAxis * 4.6, base + Vector3.yAxis * 2.4)
	local close = CFrame.lookAt(base + towardPlayer * 8.6 + Vector3.yAxis * 4.2, base + Vector3.yAxis * 2.4)
	camera.CFrame = wide
	TweenService:Create(camera, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = close }):Play()
	return state
end

function Kit.leaveScene(state: any)
	local camera = state.camera :: Camera?
	local function restore()
		if state.guiAdded then state.guiAdded:Disconnect() end
		for instance, enabled in state.guis do
			if instance.Parent then instance.Enabled = enabled end
		end
		for instance, saved in state.parts do
			if instance.Parent then
				if saved.kind == "part" and instance:IsA("BasePart") then instance.LocalTransparencyModifier = saved.value
				elseif (instance:IsA("Decal") or instance:IsA("Texture")) then instance.Transparency = saved.value end
			end
		end
		for instance, value in state.stationParts do
			if instance.Parent then instance.LocalTransparencyModifier = value end
		end
		for instance, enabled in state.stationGuis do
			if instance.Parent then instance.Enabled = enabled end
		end
		player:SetAttribute("MinigameSceneActive", state.oldSceneAttribute)
		HatchFx.postEnd(0.35)
	end
	if not camera or not camera.Parent then restore(); return end
	local tween = TweenService:Create(camera, TweenInfo.new(0.48, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		CFrame = state.oldCFrame,
		FieldOfView = state.oldFov,
	})
	tween.Completed:Once(function()
		if camera.Parent then
			camera.CameraType = state.oldType
			if state.oldSubject then camera.CameraSubject = state.oldSubject end
		end
		restore()
	end)
	tween:Play()
end

function Kit.tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

------------------------------------------------------------------ sounds share the game's volume and overlap limits
function Kit.sound(name: string)
	local cue = ({ tick = "click", tap = "pop", good = "clickBright", perfect = "stinger", bad = "error", thud = "bonk", win = "rewardClaim", big = "areaUnlock" })[name]
	if cue then
		Sfx.play(cue, { gap = if name == "tick" then 0.18 else 0.12, volume = if name == "tick" then 0.65 else 1 })
	end
end

------------------------------------------------------------------ the window
export type GameWindow = { win: any, body: Frame, quit: boolean, close: (self: GameWindow) -> () }
function Kit.window(cfg: any): GameWindow
	local win = Skin.window({ Name = "ArcadeGame", Title = cfg.Name, Color = cfg.Color, Size = Vector2.new(920, 600), DisplayOrder = 40 })
	local gw: GameWindow = { win = win, body = win.body, quit = false, close = function() end }
	gw.close = function(self: GameWindow)
		if self.win.gui.Parent then
			self.win.gui:Destroy()
		end
	end
	win.onClose(function()
		gw.quit = true
	end)
	-- a mis-tap beside the panel mustn't close the game (Skin.window's backdrop closes on a tap): the backdrop stops
	-- taking taps and a clear catcher under the panel swallows them; only the X closes it
	local dim = win.gui:FindFirstChild("Dim")
	if dim and dim:IsA("GuiObject") then
		dim.Interactable = false
	end
	Skin.make("TextButton", {
		Name = "Swallow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 0, Parent = win.gui,
	})
	win.open()
	return gw
end

------------------------------------------------------------------ countdown + pops
function Kit.countdown(parent: GuiObject, startAt: number)
	local l = Skin.text({
		Name = "Countdown", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 190),
		Text = "", FontFace = Skin.Fonts.Number, ZIndex = 80, Parent = parent,
	}, 150, 8)
	local last: number? = nil
	while Kit.now() < startAt and parent.Parent do
		local n = math.ceil(startAt - Kit.now())
		if n ~= last then
			last = n
			l.Text = if n <= 3 then tostring(n) else "READY?"
			l.TextColor3 = Skin.White
			Skin.pop(l, 1.7)
			Kit.sound("tick")
		end
		RunService.Heartbeat:Wait()
	end
	l.Text = "GO!"
	l.TextColor3 = Color3.fromRGB(140, 240, 100)
	Skin.pop(l, 1.9)
	Kit.sound("good")
	task.delay(0.45, function()
		Kit.tween(l, 0.25, { TextTransparency = 1 })
		local st = l:FindFirstChildOfClass("UIStroke")
		if st then
			Kit.tween(st, 0.25, { Transparency = 1 })
		end
		task.wait(0.3)
		l:Destroy()
	end)
end

function Kit.pop(parent: GuiObject, text: string, color: Color3, at: UDim2, size: number?, rise: number?)
	local sz = size or 48
	local l = Skin.text({
		AnchorPoint = Vector2.new(0.5, 0.5), Position = at, Size = UDim2.fromOffset(math.max(160, #text * sz * 0.7), sz * 1.3),
		Text = text, TextColor3 = color, FontFace = Skin.Fonts.Number, ZIndex = 70, Parent = parent,
	}, sz, math.max(3, math.floor(sz / 10)))
	Skin.pop(l, 0.3)
	Kit.tween(l, 0.9, { Position = at - UDim2.fromOffset(0, rise or 50) })
	task.delay(0.55, function()
		Kit.tween(l, 0.35, { TextTransparency = 1 })
		local st = l:FindFirstChildOfClass("UIStroke")
		if st then
			Kit.tween(st, 0.35, { Transparency = 1 })
		end
		task.wait(0.4)
		l:Destroy()
	end)
end

------------------------------------------------------------------ toast (a pill at the top of the screen)
local toastGui: ScreenGui? = nil
function Kit.toast(text: string)
	if not toastGui or not toastGui.Parent then
		local g = Instance.new("ScreenGui")
		g.Name = "ArcadeToast"
		g.ResetOnSpawn = false
		g.DisplayOrder = 45
		g.IgnoreGuiInset = true
		g.Parent = player:WaitForChild("PlayerGui")
		toastGui = g
	end
	local pill = Skin.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(560, 46),
		BackgroundColor3 = Skin.Panel, ZIndex = 5, Parent = toastGui,
	}, { Skin.corner(23), Skin.stroke(3) })
	Skin.text({ Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 1, -8), Text = text, ZIndex = 6, Parent = pill }, 26, 3)
	Skin.pop(pill, 0.6)
	task.delay(2.6, function()
		Kit.tween(pill, 0.25, { BackgroundTransparency = 1 })
		task.wait(0.25)
		pill:Destroy()
	end)
end

------------------------------------------------------------------ the result card
local TITLES = { [0] = "GOOD TRY!", [1] = "NICE!", [2] = "GREAT!", [3] = "AMAZING!" }
function Kit.result(gw: GameWindow, info: any?)
	if not info then
		gw:close()
		return
	end
	if gw.quit or not gw.win.gui.Parent then -- (closed early: just say what it paid)
		if info.reward and info.reward ~= "" then
			Kit.toast(info.reward)
		end
		gw:close()
		return
	end
	local body = gw.body
	local cover = Skin.make("Frame", {
		Name = "Result", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Skin.PanelDeep, BackgroundTransparency = 0.08, ZIndex = 90, Parent = body,
	}, { Skin.corner(8) })
	local stars = info.stars or 0
	local title = Skin.text({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.fromOffset(640, 100),
		Text = TITLES[stars] or "NICE!", FontFace = Skin.Fonts.Number, TextColor3 = if stars >= 3 then Kit.GOLD else Skin.White,
		ZIndex = 92, Parent = cover,
	}, 90, 6)
	Skin.pop(title, 0.4)
	for k = 1, 3 do
		local lit = k <= stars
		local s = Skin.text({
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, (k - 2) * 120, 0, 190), Size = UDim2.fromOffset(110, 110),
			Text = "★", TextColor3 = if lit then Kit.GOLD else Color3.fromRGB(70, 72, 92), ZIndex = 92, Parent = cover,
		}, 110, 5)
		s.Visible = false
		task.delay(0.25 + k * 0.22, function()
			s.Visible = true
			Skin.pop(s, 0.2)
			if lit then
				Kit.sound(if k == 3 then "perfect" else "good")
			end
		end)
	end
	Skin.text({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 260), Size = UDim2.fromOffset(720, 46),
		Text = info.text or "", ZIndex = 92, Parent = cover,
	}, 36, 3)
	local reward = Skin.text({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 312), Size = UDim2.fromOffset(720, 56),
		Text = info.reward or "", TextColor3 = Color3.fromRGB(140, 240, 100), FontFace = Skin.Fonts.Number, ZIndex = 92, Parent = cover,
	}, 48, 4)
	reward.Visible = false
	task.delay(1.05, function()
		reward.Visible = true
		Skin.pop(reward, 0.3)
		Kit.sound(if stars >= 3 then "big" else "win")
		if stars >= 3 then
			Effects.guiBurst(cover, UDim2.new(0.5, 0, 0, 190), 420, Kit.GOLD, 1.4, 91)
		end
	end)
	local ok = Skin.button({
		Parent = cover, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(260, 74),
		Text = "OK", Style = "Green", ZIndex = 93, TextSize = 44,
	})
	local done = false
	ok.button.Activated:Connect(function()
		done = true
	end)
	gw.win.onClose(function()
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < 20 and gw.win.gui.Parent do
		task.wait(0.1)
	end
	gw:close()
end

return Kit
