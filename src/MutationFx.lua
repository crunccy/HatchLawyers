--!strict
-- MutationFx (ReplicatedStorage.Shared.MutationFx, client only) - the MUTATION SEQUENCE (2026-10-21, mr.robe: "a better
-- 3d looking menu with some real animations when they mutate, similar to the egg hatching"). Like the Mythic / Supreme
-- hatch, it cuts away to a stage of its own: ReplicatedStorage.MutationLab (made in Blender, tools/blender/mutation_lab.py)
-- is cloned far above the map (client-only, nobody else sees it), the camera, lighting and HUD are borrowed and given
-- back at the end.
--   1 INTRO     the three lawyers stand on the lab's intake pads, the floor lights up in the tier's colour
--   2 PULL-IN   one by one a beam lifts each lawyer off its pad, it flails, spins and shrinks into the capsule (its
--               pipe lights up), the capsule's light column grows
--   3 CHARGE    the tesla coils arc into the capsule, it shakes harder and harder, the screen rumbles; "70% CHANCE"
--   4 REVEAL    a white flash, the lid lifts, the mutated lawyer rises in its new colours + lasting effects
--               (SkinLook.dress -> MutationLook + Effects.mutationAura) with the tier's own burst: Shiny = gold glints +
--               rays, Diamond = ice crystals + frost rings, Cosmic = an orbit of stars + a dome + a starfield.
--               "SHINY!" / "DIAMOND!" / "COSMIC!", the name, "Earns x.. (was x..)".
--      FIZZLE   the charge sputters out, a soft puff of smoke, the three tumble back out dizzy, shrug and run off.
--               Soft blue, never red; the word "lose" never shows (CLAUDE.md): "FIZZLED!" / "Your lawyers ran off".
-- MutationFx.play(opts) yields until it's over (about 9-11 s; SKIP jumps to the result). The server has already decided
-- everything (Server.LawyerService.mergeSelected): this only shows it.
-- Keep LightEmission low and Brightness moderate (CLAUDE.md effects rules); test at a high graphics level.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local HatchFx = require(Shared:WaitForChild("HatchFx") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local Puppet = require(Shared:WaitForChild("Puppet") :: ModuleScript) :: any
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any

local player = Players.LocalPlayer
local MutationFx = {}

MutationFx.STAGE_HEIGHT = 3400 -- (the hatch stages use 3000; Ambience keeps its hands off above 2000)
local WHITE = Color3.new(1, 1, 1)
local SOFT_BLUE = Color3.fromRGB(140, 180, 255) -- the fizzle's colour (never red)
local TITLES = { [2] = "SHINY!", [3] = "DIAMOND!", [4] = "COSMIC!" }
local CHARGE = { [2] = 2.2, [3] = 2.6, [4] = 3.0 } -- seconds of charging, by the tier it goes for
local REVEAL_SOUND = { [2] = "revealRare", [3] = "revealEpic", [4] = "revealLegendary" }
local PAD_HEIGHT = 6 -- the lawyers on the pads are scaled down to this if taller (the Mythic / Supreme ones are 7-13)
local REVEAL_HEIGHT = 8 -- and the result to this (the capsule is 10.6 tall inside)

export type Opts = {
	id: string, -- the lawyer's catalog id
	tier: number, -- the mutation tier the three go in at (1 Normal .. 3 Diamond)
	success: boolean,
	source: Model, -- a lawyer model to copy (a desk lawyer: SkinLook dresses it)
	name: string?, -- the result's name ("Shiny Rookie")
	earnFrom: number?, -- Formulas.lawyerEarn before / after
	earnTo: number?,
	chance: number?, -- 0..1, shown while it charges
	pauseAt: string?, -- (testing only) "pull" | "charge" | "reveal" | "fizzle": holds there until MutationFx.resume()
}

-- (testing: Studio screenshots take seconds, so a check can freeze the sequence at a phase and look)
local resumed = false
local holding = false -- (the fizzle's runners wait for it too)
function MutationFx.resume()
	resumed = true
end
local function checkpoint(opts: Opts, name: string)
	if opts.pauseAt == name then
		resumed = false
		holding = true
		while not resumed do
			RunService.Heartbeat:Wait()
		end
		holding = false
	end
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function fmtX(n: number?): string
	if not n then
		return "?"
	end
	return if n == math.floor(n) then string.format("%d", n) else string.format("%.1f", n)
end

------------------------------------------------------------------ the overlay (letterbox, flash, chance, title card, buttons)
local gui: ScreenGui? = nil
local ui: { [string]: any } = {}
local function buildGui(): ScreenGui
	if gui and gui.Parent then
		return gui
	end
	local make = Skin.make
	local g = make("ScreenGui", {
		Name = "MutationFx", ResetOnSpawn = false, DisplayOrder = 70, IgnoreGuiInset = true, Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui"),
	})
	g:SetAttribute("SkinBuilt", true)
	-- cinematic bars (a 3D cut-scene feel), a full-screen flash
	ui.barTop = make("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2, Parent = g })
	ui.barBottom = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2, Parent = g })
	ui.flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 20, Parent = g })
	-- everything else sits on a 1280 x 720 canvas scaled to the screen (phones too)
	local canvas = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1280, 720),
		BackgroundTransparency = 1, ZIndex = 5, Parent = g })
	ui.scale = make("UIScale", { Parent = canvas })
	ui.canvas = canvas
	-- the chance pill while it charges
	local pill = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(640, 70), Size = UDim2.fromOffset(330, 64),
		BackgroundColor3 = Color3.fromRGB(40, 26, 70), Visible = false, ZIndex = 6, Parent = canvas }, { Skin.corner(14), Skin.stroke(4) })
	Skin.studs(pill, 0.88, nil, 22)
	ui.pillStroke = make("UIStroke", { Thickness = 3, Color = WHITE, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = make("Frame", {
		Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, ZIndex = 6, Parent = pill }, { Skin.corner(10) }) })
	ui.pillText = Skin.text({ Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), Text = "", RichText = true, ZIndex = 7, Parent = pill }, 40, 4)
	ui.pill = pill
	ui.pillScale = make("UIScale", { Parent = pill })
	-- the title card: big LuckiestGuy word, the name under it, the earn line
	ui.title = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 108), Size = UDim2.fromOffset(980, 136),
		Text = "", FontFace = Skin.Fonts.Number, Visible = false, ZIndex = 8, Parent = canvas }, 140, 7)
	ui.titleScale = make("UIScale", { Parent = ui.title })
	ui.titleGrad = make("UIGradient", { Enabled = false, Parent = ui.title })
	ui.name = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 194), Size = UDim2.fromOffset(820, 50),
		Text = "", Visible = false, ZIndex = 8, Parent = canvas }, 52, 5)
	ui.line = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 236), Size = UDim2.fromOffset(820, 36),
		Text = "", RichText = true, FontFace = Skin.Fonts.Body, Visible = false, ZIndex = 8, Parent = canvas }, 34, 3)
	-- continue + skip
	local ok = Skin.button({ Name = "Continue", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(640, 676), Size = UDim2.fromOffset(300, 84),
		Text = "AWESOME!", TextSize = 46, Style = "Green", ZIndex = 9, Parent = canvas })
	ok.button.Visible = false
	ui.ok = ok
	local skip = Skin.button({ Name = "Skip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromOffset(1250, 690), Size = UDim2.fromOffset(150, 56),
		Text = "SKIP", TextSize = 30, Style = "Navy", ZIndex = 9, Parent = canvas })
	ui.skip = skip
	local function fit()
		local cam = workspace.CurrentCamera
		local vs = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		ui.scale.Scale = math.clamp(math.min(vs.X / 1280, vs.Y / 720), 0.45, 1.4)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	gui = g
	return g
end

local function flash(inT: number, hold: number, outT: number, color: Color3?)
	local f = ui.flash :: Frame
	f.BackgroundColor3 = color or WHITE
	tween(f, inT, { BackgroundTransparency = 0 })
	task.delay(inT + hold, function()
		tween(f, outT, { BackgroundTransparency = 1 })
	end)
end

------------------------------------------------------------------ lighting + camera (borrowed, given back)
local saved: { [string]: any }? = nil
local function setLabLighting(col: Color3)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	saved = {
		ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, OutdoorAmbient = Lighting.OutdoorAmbient, Ambient = Lighting.Ambient,
		atm = if atm then { Density = atm.Density, Color = atm.Color, Decay = atm.Decay, Haze = atm.Haze, Glare = atm.Glare } else nil,
	}
	-- a violet evening (a night sky turned the lab's violet bricks blue)
	Lighting.ClockTime = 18.4
	Lighting.Brightness = 1.15
	Lighting.OutdoorAmbient = Color3.fromRGB(190, 140, 215)
	Lighting.Ambient = Color3.fromRGB(140, 105, 170)
	if atm then
		atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = 0.3, Color3.fromRGB(150, 90, 210):Lerp(col, 0.15), Color3.fromRGB(70, 30, 110), 0.8, 0
	end
end
local function restoreLighting()
	local s = saved
	if not s then
		return
	end
	saved = nil
	Lighting.ClockTime, Lighting.Brightness, Lighting.OutdoorAmbient, Lighting.Ambient = s.ClockTime, s.Brightness, s.OutdoorAmbient, s.Ambient
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm and s.atm then
		atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = s.atm.Density, s.atm.Color, s.atm.Decay, s.atm.Haze, s.atm.Glare
	end
end

------------------------------------------------------------------ the lawyers on stage
type Actor = { model: Model, pup: any, anim: any, base: CFrame, active: boolean }

local function makeLawyer(source: Model, id: string, tier: number, maxHeight: number): Model
	local m = Puppet.cloneAtRest(source)
	m.Name = "MutationActor"
	m:PivotTo(CFrame.new())
	SkinLook.dress(m, id, tier)
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ProximityPrompt") or d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	local _, size = m:GetBoundingBox()
	if size.Y > maxHeight then
		m:ScaleTo(m:GetScale() * maxHeight / size.Y)
	end
	return m
end

-- how far the model's pivot sits above its feet (it's upright at this point)
local function lift(m: Model): number
	local box, size = m:GetBoundingBox()
	return m:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
end

local function standAt(m: Model, floor: Vector3, lookAt: Vector3): CFrame
	local up = lift(m)
	local at = floor + Vector3.new(0, up, 0)
	return CFrame.lookAt(at, Vector3.new(lookAt.X, at.Y, lookAt.Z))
end

local function newActor(m: Model, cf: CFrame, parent: Instance): Actor
	m:PivotTo(cf)
	m.Parent = parent
	local pup = Puppet.new(m)
	local anim = Puppet.animator(pup, "lawyer")
	anim.fidgets = false
	return { model = m, pup = pup, anim = anim, base = cf, active = true }
end

-- arms up, a little lean back: being pulled
local V = Vector3.new
local PULLED = { rootPos = V(0, 0, 0), rootRot = V(8, 0, 0), head = V(18, 0, 0), armL = V(165, 0, -22), armR = V(165, 0, 22), legL = V(-18, 0, 0), legR = V(22, 0, 0) }
local DIZZY = function(t: number)
	return { rootPos = V(0, 0, 0), rootRot = V(0, 0, math.sin(t * 7) * 8), head = V(0, math.sin(t * 9) * 25, math.sin(t * 7) * 12),
		armL = V(20, 0, -35), armR = V(20, 0, 35), legL = V(0, 0, -6), legR = V(0, 0, 6) }
end

local function bezier(a: Vector3, b: Vector3, c: Vector3, t: number): Vector3
	local u = 1 - t
	return a * u * u + b * 2 * u * t + c * t * t
end

------------------------------------------------------------------ the sequence
local playing = false

function MutationFx.isPlaying(): boolean
	return playing
end

function MutationFx.play(opts: Opts)
	if playing then
		return
	end
	local template = ReplicatedStorage:FindFirstChild("MutationLab")
	if not (template and template:IsA("Model")) then
		warn("[MutationFx] ReplicatedStorage.MutationLab is missing (tools/zones/BuildMutationLab.lua)")
		return
	end
	playing = true
	local g = buildGui()
	local goal = math.min(opts.tier + 1, #Config.Lawyers.StarEarn)
	local mut = Config.Lawyers.Mutations[goal]
	local col: Color3 = if opts.success and mut then mut.Color else SOFT_BLUE
	local tierCol: Color3 = if mut then mut.Color else WHITE -- (the charge glows in the colour it goes for, either way)
	local skipped = false
	local conns: { RBXScriptConnection } = {}
	local actors: { Actor } = {}
	local handles: { any } = {}

	-- everything that has to be given back, whatever happens
	local cam = workspace.CurrentCamera
	local camSaved = { type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView, cf = cam.CFrame }
	local hidden: { LayerCollector } = {}
	for _, x in player.PlayerGui:GetChildren() do
		if x:IsA("LayerCollector") and x ~= g and x.Enabled then
			x.Enabled = false
			table.insert(hidden, x)
		end
	end

	-- the stage, far above wherever the player stands
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local here = if root then root.Position else Vector3.zero
	local origin = CFrame.new(here.X, MutationFx.STAGE_HEIGHT, here.Z)
	local stage = Instance.new("Folder")
	stage.Name = "MutationStage"
	local lab = template:Clone()
	lab:PivotTo(origin)
	lab.Parent = stage
	stage.Parent = workspace
	local lid = lab:FindFirstChild("Lid") :: Model?
	local lidHome = if lid then lid:GetPivot() else origin
	local core = lab:FindFirstChild("CapsuleCore") :: BasePart?
	local centreMarker = lab:FindFirstChild("CapsuleCentre") :: BasePart?
	local centre = if centreMarker then centreMarker.Position else origin.Position + Vector3.new(0, 7, 0)
	local capsuleFloor = origin.Position + Vector3.new(0, 2.05, 0)
	local coils = {}
	for i = 1, 2 do
		local c = lab:FindFirstChild("CoilTop" .. i)
		if c and c:IsA("BasePart") then
			table.insert(coils, c)
		end
	end
	local glows, bulbs = {}, {}
	for _, p in lab:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "FloorGlow" then
				table.insert(glows, p)
			elseif p.Name == "Bulb" or p.Name == "LidBulb" then
				table.insert(bulbs, p)
			end
		end
	end
	local function padTop(i: number): Vector3
		local p = lab:FindFirstChild("Pad" .. i) :: BasePart?
		if not p then
			return origin.Position + Vector3.new((i - 2) * 9, 0.8, 12)
		end
		return Vector3.new(p.Position.X, p.Position.Y + math.min(p.Size.X, p.Size.Y, p.Size.Z) / 2, p.Position.Z)
	end
	local function at(x: number, y: number, z: number): Vector3
		return (origin * CFrame.new(x, y, z)).Position
	end

	-- camera: eased toward a goal every frame, plus HatchFx's shake
	local camGoal = CFrame.lookAt(at(12, 12, 44), at(0, 5, 0))
	local camCur = camGoal
	local camRate = 4
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = 50
	cam.CFrame = camCur
	local function camTo(cf: CFrame, rate: number?)
		camGoal = cf
		camRate = rate or 4
	end
	setLabLighting(tierCol)
	HatchFx.postBegin()
	HatchFx.post({ bloom = { Intensity = 0.5, Size = 24, Threshold = 1.45 }, cc = { Saturation = 0.1, Contrast = 0.04 } }, 0)
	local t0 = os.clock()
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		camCur = camCur:Lerp(camGoal, 1 - math.exp(-dt * camRate))
		cam.CFrame = camCur * HatchFx.shakeCFrame()
		local t = os.clock() - t0
		for _, a in actors do
			if a.active then
				a.pup.base = a.base
				a.anim:step(os.clock())
			end
		end
		-- chase lights
		for i, b in bulbs do
			b.Transparency = if math.floor(t * 8 + i) % 3 == 0 then 0.55 else 0
		end
	end))

	local function sleep(t: number)
		local untilT = os.clock() + t
		while os.clock() < untilT and not skipped do
			RunService.Heartbeat:Wait()
		end
	end

	-- the overlay
	g.Enabled = true
	ui.title.Visible, ui.name.Visible, ui.line.Visible, ui.pill.Visible = false, false, false, false
	ui.ok.button.Visible = false
	ui.skip.button.Visible = true
	tween(ui.barTop, 0.4, { Size = UDim2.new(1, 0, 0.085, 0) })
	tween(ui.barBottom, 0.4, { Size = UDim2.new(1, 0, 0.085, 0) })
	ui.flash.BackgroundTransparency = 0
	ui.flash.BackgroundColor3 = Color3.fromRGB(230, 210, 255)
	tween(ui.flash, 0.45, { BackgroundTransparency = 1 })
	table.insert(conns, ui.skip.button.Activated:Connect(function()
		skipped = true
		ui.skip.button.Visible = false
	end))
	Sfx.play("whooshBig", { volume = 0.6 })

	local function setGlow(c: Color3, t: number?)
		for _, p in glows do
			if (t or 0) > 0 then
				tween(p, t :: number, { Color = c })
			else
				p.Color = c
			end
		end
	end

	local ok, err = pcall(function()
		------------------------------------------------ 1) INTRO: the three on their pads
		setGlow(tierCol, 0.8)
		if core then
			core.Color = tierCol
			core.Transparency = 0.9
		end
		for i = 1, 3 do
			local m = makeLawyer(opts.source, opts.id, opts.tier, PAD_HEIGHT)
			local cf = standAt(m, padTop(i), at(0, 0, 40)) -- (facing the camera first)
			local a = newActor(m, cf, stage)
			a.anim.phase = i * 1.7
			table.insert(actors, a)
			HatchFx.sparks(padTop(i) + Vector3.new(0, 1, 0), tierCol, 14, 10, 0.8)
		end
		camTo(CFrame.lookAt(at(7, 9, 34), at(0, 5, 2)), 1.6)
		sleep(0.9)
		if not skipped then
			for i, a in actors do
				task.delay(i * 0.12, function()
					if a.active then
						a.anim:play("worried")
						a.anim.lookAt = centre
					end
				end)
			end
			sleep(0.8)
		end

		------------------------------------------------ 2) PULL-IN: one by one into the capsule
		camTo(CFrame.lookAt(at(0, 11, 31), at(0, 6, 0)), 2.5)
		local entry = centre + Vector3.new(0, 4.5, 0)
		local function pull(i: number, a: Actor)
			local pad = padTop(i)
			-- the pad's beam: a light column up from the pad, and its pipe lights up toward the capsule
			local beam = HatchFx.pillar(pad, tierCol, 14, 3.2, 1.0)
			table.insert(handles, beam)
			for k = 1, 3 do
				local c = lab:FindFirstChild(string.format("PipeGlow%d_%d", i, k)) :: BasePart?
				if c then
					task.delay(0.12 * k, function()
						local home = c.Color
						c.Color = WHITE
						tween(c, 0.5, { Color = tierCol })
						task.delay(1.4, function()
							if c.Parent then
								tween(c, 0.6, { Color = home })
							end
						end)
					end)
				end
			end
			a.active = false
			a.pup:apply(PULLED)
			local m = a.model
			local start = m:GetPivot()
			local s0 = m:GetScale()
			local p0 = start.Position
			local p1 = (p0 + entry) / 2 + Vector3.new(0, 10, 0)
			Sfx.play("whoosh", { volume = 0.7, speed = 0.9 + i * 0.1 })
			local d = 0.75
			local ts = os.clock()
			while true do
				local u = math.min((os.clock() - ts) / d, 1)
				local e = u * u * (3 - 2 * u)
				m:ScaleTo(s0 * (1 - 0.82 * e))
				m:PivotTo(CFrame.new(bezier(p0, p1, entry, e)) * CFrame.Angles(0, e * math.pi * 5, 0) * start.Rotation)
				if u >= 1 or skipped then
					break
				end
				if i == 2 and u > 0.45 then
					checkpoint(opts, "pull")
				end
				RunService.RenderStepped:Wait()
			end
			m:Destroy()
			HatchFx.sparks(entry, tierCol, 18, 12, 0.7)
			HatchFx.ring(CFrame.new(entry), 4, tierCol, 0.45, 0.6)
			Sfx.play("pop", { volume = 0.7 })
			if core then
				tween(core, 0.3, { Transparency = 0.82 - 0.14 * i })
			end
		end
		for i, a in actors do
			if skipped then
				break
			end
			pull(i, a)
			sleep(0.15)
		end
		for _, a in actors do
			if a.model.Parent then
				a.model:Destroy()
			end
		end
		table.clear(actors)

		------------------------------------------------ 3) CHARGE: arcs from the coils, the capsule shakes
		if not skipped then
			local chargeT = CHARGE[goal] or 2.4
			ui.pill.Visible = true
			ui.pillText.Text = string.format('<font color="#%s">%d%%</font> CHANCE', tierCol:Lerp(WHITE, 0.25):ToHex(),
				math.floor((opts.chance or 0) * 100 + 0.5))
			ui.pillStroke.Color = tierCol
			ui.pillScale.Scale = 0.4
			tween(ui.pillScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			camTo(CFrame.lookAt(at(0, 8.5, 18), at(0, 7, 0)), 0.9)
			HatchFx.post({ bloom = { Intensity = 0.75, Threshold = 1.35 }, cc = { Contrast = 0.1, TintColor = WHITE:Lerp(tierCol, 0.1) } }, chargeT)
			local implode = HatchFx.implode(centre, tierCol, 9, 90)
			table.insert(handles, implode)
			HatchFx.shake(0.5, 9, 0.3, 0.4, chargeT)
			Sfx.play("gears", { volume = 0.5 })
			local ts = os.clock()
			local nextBolt, nextRattle = 0, 0
			local sputter = not opts.success
			while not skipped do
				local u = (os.clock() - ts) / chargeT
				if u >= 1 then
					break
				end
				local now = os.clock()
				local fade = sputter and u > 0.72 -- (a fizzle: it stutters and dies in the last stretch)
				local j = 0.04 + 0.32 * u
				if lid then
					lid:PivotTo(lidHome * CFrame.new((math.random() - 0.5) * j, (math.random() - 0.5) * j * 0.4, (math.random() - 0.5) * j)
						* CFrame.Angles(0, 0, (math.random() - 0.5) * j * 0.06))
				end
				if core then
					core.Transparency = if fade then 0.35 + math.random() * 0.6 else math.clamp(0.42 - 0.3 * u + math.sin(now * 28) * 0.06, 0.05, 0.9)
				end
				if now > nextBolt and not (fade and math.random() < 0.6) then
					for _, c in coils do
						local tgt = centre + Vector3.new((math.random() - 0.5) * 2.4, (math.random() - 0.5) * 6, (math.random() - 0.5) * 2.4)
						HatchFx.bolt(c.Position, tgt, if fade then SOFT_BLUE else tierCol, 0.1, 0.22 + 0.25 * u)
					end
					nextBolt = now + 0.3 - 0.2 * u
				end
				if now > nextRattle then
					Sfx.play("eggShake", { volume = 0.35 + 0.4 * u, speed = 0.9 + 0.5 * u, gap = 0.05 })
					nextRattle = now + 0.45 - 0.25 * u
				end
				if u > 0.55 and not fade then
					HatchFx.shake(0.25 + u, 14, 0.02, 0.15, 0)
				end
				if u > 0.8 then
					checkpoint(opts, "charge")
				end
				RunService.Heartbeat:Wait()
			end
			implode.stop()
			if lid then
				lid:PivotTo(lidHome)
			end
			ui.pill.Visible = false
		end
		ui.skip.button.Visible = false

		------------------------------------------------ 4) THE RESULT
		HatchFx.clearShakes()
		if opts.success then
			-- REVEAL: a white flash, the lid lifts, the mutated lawyer rises out of the light
			flash(0.06, 0.12, 0.6)
			Sfx.play(REVEAL_SOUND[goal] or "revealRare", { volume = 0.9 })
			HatchFx.shake(2.4 + goal * 0.5, 16, 0.02, 0.6, 0.1)
			HatchFx.post({ bloom = { Intensity = 0.9, Threshold = 1.25 }, cc = { Brightness = 0, Saturation = 0.18, TintColor = WHITE } }, 0.3)
			if lid then
				local lifted = lidHome * CFrame.new(0, 9, 0)
				task.spawn(function()
					local ts = os.clock()
					while true do
						local u = math.min((os.clock() - ts) / 0.7, 1)
						local e = 1 - (1 - u) ^ 3
						lid:PivotTo(lidHome:Lerp(lifted, e))
						if u >= 1 then
							break
						end
						RunService.Heartbeat:Wait()
					end
				end)
			end
			if core then
				tween(core, 0.5, { Transparency = 1 })
			end
			setGlow(col, 0.3)
			for i = 1, 3 do
				HatchFx.ring(CFrame.new(capsuleFloor + Vector3.new(0, 0.2, 0)), 10 + i * 6, col, 0.6 + i * 0.25, 1.4)
			end
			HatchFx.light(centre, col, 40, 4, 1.6)
			-- the tier's own burst
			if goal == 2 then -- SHINY: gold glints + rays
				table.insert(handles, HatchFx.rays(centre, col, 10, 22, 0.5))
				Effects.burst(centre, "tier", col)
				HatchFx.sparks(centre, ColorSequence.new(WHITE, col), 50, 22, 1.1)
			elseif goal == 3 then -- DIAMOND: ice crystals + frost rings
				table.insert(handles, HatchFx.rays(centre, ColorSequence.new(WHITE, col), 12, 24, 0.5))
				Effects.burst(centre, "rare")
				HatchFx.sparks(centre, ColorSequence.new(WHITE, col), 60, 24, 1.1)
				HatchFx.dust(capsuleFloor, Color3.fromRGB(220, 245, 255), 30)
				for i = 1, 3 do
					task.delay(0.15 * i, HatchFx.ring, CFrame.new(centre + Vector3.new(0, (i - 2) * 2.5, 0)), 7 + i * 2, Color3.fromRGB(200, 240, 255), 0.7, 0.8)
				end
			else -- COSMIC: an orbit of stars + a dome + a starfield
				HatchFx.dome(centre, 18, col, 1.1)
				table.insert(handles, HatchFx.rays(centre, ColorSequence.new(Color3.fromRGB(255, 200, 250), col), 16, 28, 0.6))
				Effects.burst(centre, "epic", col)
				HatchFx.starfield(origin.Position, 180, 160, stage)
				task.spawn(HatchFx.orbs, centre, { col, Color3.fromRGB(255, 200, 250), Color3.fromRGB(120, 200, 255), col, Color3.fromRGB(255, 240, 180) }, 9, 1.2, 2)
			end
			HatchFx.confetti(centre + Vector3.new(0, 4, 0), 90, 1)
			-- the lawyer, in its new colours (SkinLook.dress -> MutationLook + Effects.mutationAura)
			local m = makeLawyer(opts.source, opts.id, goal, REVEAL_HEIGHT)
			local stand = standAt(m, capsuleFloor, at(0, 0, 40))
			local a = newActor(m, stand, stage)
			table.insert(actors, a)
			local _, size = m:GetBoundingBox()
			local rise = HatchFx.spring(2.2, 0.5, -size.Y * 0.9)
			rise.target = 0
			table.insert(conns, RunService.Heartbeat:Connect(function(dt)
				local y = HatchFx.stepSpring(rise, dt)
				a.base = stand * CFrame.new(0, y, 0) * CFrame.Angles(0, math.sin(os.clock() * 0.8) * 0.25, 0)
			end))
			task.delay(0.35, function()
				if a.active then
					a.anim:play("celebrate")
				end
			end)
			-- the camera comes in close and slowly circles
			local look = capsuleFloor + Vector3.new(0, size.Y * 0.9, 0) -- (looking at the head: the lawyer sits low, under the title)
			local dist = math.max(15, size.Y * 2.5)
			camTo(CFrame.lookAt(look + (origin.LookVector * -1) * dist + Vector3.new(0, size.Y * 0.1, 0), look), 3)
			table.insert(conns, RunService.Heartbeat:Connect(function()
				local ang = math.sin((os.clock() - t0) * 0.35) * 0.35
				local off = (origin * CFrame.Angles(0, ang, 0)).LookVector * -dist
				camTo(CFrame.lookAt(look + off + Vector3.new(0, size.Y * 0.1, 0), look), 2.2)
			end))
			-- the title card
			task.wait(0.35)
			ui.title.Text = TITLES[goal] or "MUTATED!"
			ui.title.TextColor3 = if goal == 4 then WHITE else col
			ui.titleGrad.Enabled = goal == 4
			if goal == 4 then
				ui.titleGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 240)), ColorSequenceKeypoint.new(0.5, col),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
				})
			end
			ui.title.Visible = true
			ui.titleScale.Scale = 3
			ui.title.Rotation = -7
			tween(ui.titleScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(ui.title, 0.6, { Rotation = 0 }, Enum.EasingStyle.Elastic)
			Effects.guiBurst(ui.canvas, UDim2.fromOffset(640, 108), 520, col, 1.6, 7)
			task.delay(0.3, function()
				ui.name.Text = opts.name or ""
				ui.name.TextColor3 = col:Lerp(WHITE, 0.55)
				ui.name.Visible = true
				Skin.pop(ui.name, 0.5)
				if opts.earnTo then
					ui.line.Text = string.format('Earns <font color="#%s">x%s</font> (was x%s)', Skin.Lime:ToHex(), fmtX(opts.earnTo), fmtX(opts.earnFrom))
					ui.line.Visible = true
				end
			end)
			if goal == 4 then
				task.delay(0.5, Sfx.play, "fanfare", { volume = 0.7 })
			end
			ui.ok.setText("AWESOME!")
			ui.ok.setStyle("Green")
			task.wait(1.2)
			checkpoint(opts, "reveal")
		else
			-- FIZZLE: a soft puff, the three tumble back out dizzy, shrug and run off
			flash(0.08, 0.05, 0.5, Color3.fromRGB(220, 230, 255))
			Sfx.play("bonk", { volume = 0.6, speed = 0.8 })
			HatchFx.shake(1.2, 6, 0.02, 0.5, 0.1)
			HatchFx.post({ bloom = { Intensity = 0.6, Threshold = 1.4 }, cc = { Saturation = -0.25, TintColor = Color3.fromRGB(225, 232, 255) } }, 0.5)
			setGlow(SOFT_BLUE, 0.4)
			if core then
				tween(core, 0.3, { Transparency = 1 })
			end
			HatchFx.dust(capsuleFloor, Color3.fromRGB(200, 200, 225), 40)
			HatchFx.dust(centre, Color3.fromRGB(185, 190, 215), 30)
			HatchFx.ring(CFrame.new(capsuleFloor + Vector3.new(0, 0.3, 0)), 12, SOFT_BLUE, 0.7, 0.8)
			if lid then -- the lid pops up a little, crooked, and drops back
				task.spawn(function()
					local up = lidHome * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(8))
					local ts = os.clock()
					while true do
						local u = math.min((os.clock() - ts) / 0.9, 1)
						local h = math.sin(u * math.pi)
						lid:PivotTo(lidHome:Lerp(up, h))
						if u >= 1 then
							break
						end
						RunService.Heartbeat:Wait()
					end
				end)
			end
			-- the three come flying back out to the front, land dizzy, shrug, and run off
			local spots = { at(-4.5, 0, 9), at(0, 0, 11), at(4.5, 0, 9) }
			local runTo = { at(-30, 0, 22), at(9, 0, 40), at(30, 0, 22) }
			camTo(CFrame.lookAt(at(0, 8, 30), at(0, 4, 6)), 3)
			for i = 1, 3 do
				local m = makeLawyer(opts.source, opts.id, opts.tier, PAD_HEIGHT)
				local land = standAt(m, spots[i], at(0, 0, 40))
				local a = newActor(m, land, stage)
				a.active = false
				table.insert(actors, a)
				local from = centre + Vector3.new(0, 3, 0)
				local p1 = (from + land.Position) / 2 + Vector3.new(0, 7, 0)
				task.spawn(function()
					task.wait(0.08 * i)
					local ts = os.clock()
					while a.model.Parent do
						local u = math.min((os.clock() - ts) / 0.55, 1)
						a.pup:apply(DIZZY(os.clock()), CFrame.new(bezier(from, p1, land.Position, u)) * land.Rotation * CFrame.Angles(u * math.pi * 2, 0, 0))
						if u >= 1 then
							break
						end
						RunService.Heartbeat:Wait()
					end
					HatchFx.dust(spots[i], Color3.fromRGB(210, 210, 230), 8)
					-- dizzy for a moment, then a shrug
					local tsd = os.clock()
					while a.model.Parent and os.clock() - tsd < 0.9 do
						a.pup:apply(DIZZY(os.clock()), land)
						RunService.Heartbeat:Wait()
					end
					a.base = land
					a.active = true
					a.anim:play("shrug")
					task.wait(1.1 + 0.15 * i)
					while holding do
						RunService.Heartbeat:Wait()
					end
					-- run off the stage (facing where it runs), fading out at the edge
					a.active = false
					local dir = CFrame.lookAt(land.Position, Vector3.new(runTo[i].X, land.Position.Y, runTo[i].Z))
					local goalCf = dir + (Vector3.new(runTo[i].X, land.Position.Y, runTo[i].Z) - land.Position)
					local tr = os.clock()
					while a.model.Parent do
						local u = math.min((os.clock() - tr) / 1.3, 1)
						a.pup:apply(Puppet.walkPose(os.clock() * 1.6), dir:Lerp(goalCf, u))
						if u >= 1 then
							break
						end
						RunService.Heartbeat:Wait()
					end
					if a.model.Parent then
						a.model:Destroy()
					end
				end)
			end
			task.delay(0.6, Sfx.play, "goodbye", { volume = 0.7 })
			task.wait(0.4)
			ui.title.Text = "FIZZLED!"
			ui.title.TextColor3 = SOFT_BLUE
			ui.titleGrad.Enabled = false
			ui.title.Visible = true
			ui.titleScale.Scale = 1.8
			ui.title.Rotation = 4
			tween(ui.titleScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(ui.title, 0.6, { Rotation = 0 }, Enum.EasingStyle.Elastic)
			ui.name.Text = "Your lawyers ran off..."
			ui.name.TextColor3 = WHITE
			ui.name.Visible = true
			ui.line.Text = string.format("It was a %d%% chance. Try again!", math.floor((opts.chance or 0) * 100 + 0.5))
			ui.line.Visible = true
			ui.ok.setText("OK")
			ui.ok.setStyle("Sky")
			task.wait(1.0)
			checkpoint(opts, "fizzle")
		end

		------------------------------------------------ 5) wait for the player (or a few seconds), then back to the world
		task.wait(0.6)
		ui.ok.button.Visible = true
		Skin.pop(ui.ok.button, 0.5)
		local done = false
		local c = ui.ok.button.Activated:Connect(function()
			done = true
		end)
		local untilT = os.clock() + (if opts.success then 7 else 5)
		while not done and os.clock() < untilT do
			RunService.Heartbeat:Wait()
		end
		c:Disconnect()
	end)
	if not ok then
		warn("[MutationFx] sequence failed:", err)
	end

	-- back to the world (a quick flash hides the cut)
	ui.flash.BackgroundColor3 = WHITE
	local fin = tween(ui.flash, 0.18, { BackgroundTransparency = 0 })
	fin.Completed:Wait()
	for _, c in conns do
		c:Disconnect()
	end
	for _, h in handles do
		pcall(function()
			h.stop()
		end)
	end
	stage:Destroy()
	HatchFx.clearShakes()
	HatchFx.postEnd(0.2)
	restoreLighting()
	cam.CameraType = camSaved.type
	if camSaved.subject then
		cam.CameraSubject = camSaved.subject
	end
	cam.FieldOfView = camSaved.fov
	cam.CFrame = camSaved.cf
	for _, x in hidden do
		if x.Parent then
			x.Enabled = true
		end
	end
	ui.title.Visible, ui.name.Visible, ui.line.Visible, ui.pill.Visible = false, false, false, false
	ui.ok.button.Visible = false
	ui.barTop.Size = UDim2.new(1, 0, 0, 0)
	ui.barBottom.Size = UDim2.new(1, 0, 0, 0)
	tween(ui.flash, 0.4, { BackgroundTransparency = 1 }).Completed:Wait()
	g.Enabled = false
	playing = false
end

return MutationFx
