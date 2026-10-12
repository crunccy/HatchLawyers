--!strict
-- Egg machine, client side: the egg's idle bob, the FREE badge and prompt text, the live odds board,
-- and the cartoony hatch sequence (pop in -> shake -> crack flash -> rarity burst -> LAWYER reveal).
-- v12: eggs hatch real lawyers. The reveal shows the lawyer, its power and skills, and offers to put
-- it straight into an empty office (Remotes.PlaceLawyer) or open the LAWYERS panel. (Merging happens only at the
-- Lawyer Merger machine since 2026-10-11, so there's no MERGE button here.)
-- All results come from the server through Remotes.EggHatched; this script only shows them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript)
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript)
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript)
local ArtAssets = require(Shared:WaitForChild("ArtAssets") :: ModuleScript) :: any
local FX = Effects.TEXTURES
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggHatched = Remotes:WaitForChild("EggHatched") :: RemoteEvent
local PlaceLawyer = Remotes:WaitForChild("PlaceLawyer") :: RemoteFunction

-- v16 (egg zones): the Briefcase Egg is bought in Briefcase Bay and hatched at the firm's incubator, so the hub
-- machine is gone (ServerStorage.Old_HubEggMachines). Unparented stand-ins keep the machine code below harmless;
-- the hatch screen itself doesn't care where an egg hatched.
local machine = workspace:WaitForChild("Hub"):FindFirstChild("EggMachine")
local eggModel = (if machine then machine:WaitForChild("Egg") else Instance.new("Model")) :: Model
local shell = (if machine then eggModel:WaitForChild("Shell") else nil) :: BasePart
local rollPrompt = (if machine then machine:WaitForChild("StandTop"):WaitForChild("RollPrompt") else Instance.new("ProximityPrompt")) :: ProximityPrompt
local oddsGui = (if machine then machine:WaitForChild("OddsBoard"):WaitForChild("SurfaceGui") else Instance.new("SurfaceGui")) :: SurfaceGui
local zoneEggs = {} -- eggs sold in a zone (Config.Zones), not by a hub machine
for _, z in (Config :: any).Zones and (Config :: any).Zones.List or {} do
	zoneEggs[z.Egg] = true
end
-- Themed egg machines (Config.Eggs.Themed: Brainrot / Pet / Food / Ocean / Space). Same hatch screen; the
-- egg there takes the themed egg's Color.
local themedPrompts: { ProximityPrompt } = {}
local BRIEFCASE_GOLD = Color3.fromRGB(245, 200, 70) -- the starter Briefcase Egg (mr.robe's yellow + brown egg)

-- Cartoony style (see the team style guide): FredokaOne, bright colors, thick black outlines.
local FONT = Enum.Font.FredokaOne
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(98, 205, 48)
local BLUE = Color3.fromRGB(60, 150, 255)
local CREAM = Color3.fromRGB(255, 250, 232)
local CONFETTI = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(98, 205, 48),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(200, 90, 255),
	Color3.fromRGB(255, 120, 200),
}

local function rarityInfo(index: number): (string, Color3)
	local id = Config.Eggs.Skins[index].Id
	return id, Config.RarityColors[id] or WHITE
end

local function tween(instance: Instance, seconds: number, props: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local t = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function outline(parent: Instance, thickness: number, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = BLACK
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, stroke: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = text
	outline(l, stroke)
	l.Parent = parent
	return l
end

-------------------------------------------------------------------------------
-- World: idle bob, FREE badge, prompt text, odds board
-------------------------------------------------------------------------------

-- The egg's home comes from the server (EggServer sets the egg's "Home" attribute; it always has every part).
-- Never GetPivot() here: with StreamingEnabled the egg's parts may not have streamed in yet when this runs,
-- and the pivot then reads as the map origin - the bob below would drag the egg's effect parts (FX_Shell /
-- FX_Aura, holding the particles) to the middle of the map. Don't bob until the home is known.
local function eggHomeOf(egg: Model): CFrame?
	local home = egg:GetAttribute("Home")
	return if typeof(home) == "CFrame" then home else nil
end
RunService.RenderStepped:Connect(function()
	local home = eggHomeOf(eggModel)
	if not home or not eggModel.PrimaryPart then
		return -- not streamed in yet: leave it where the server put it
	end
	local t = os.clock()
	eggModel:PivotTo(home * CFrame.new(0, math.sin(t * 2) * 0.35, 0) * CFrame.Angles(0, t * 0.6, math.sin(t * 1.3) * 0.06))
end)

local freeBadge = Instance.new("BillboardGui")
freeBadge.Name = "FreeBadge"
freeBadge.Size = UDim2.fromOffset(170, 60)
freeBadge.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
freeBadge.MaxDistance = 120
freeBadge.Adornee = shell
freeBadge.Enabled = false
local freeText = label(freeBadge, "FREE!", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), GREEN, 4)
freeBadge.Parent = player:WaitForChild("PlayerGui")
RunService.RenderStepped:Connect(function()
	if freeBadge.Enabled then
		local pulse = 1 + math.sin(os.clock() * 5) * 0.08
		freeText.Size = UDim2.fromScale(pulse, pulse)
		freeText.Rotation = math.sin(os.clock() * 3) * 6
	end
end)

local function refreshPrompt()
	local free = player:GetAttribute("FreeEgg") == true
	rollPrompt.ActionText = if free then "Hatch FREE Briefcase Egg!" else "Hatch a Lawyer"
	local price = (player:GetAttribute("EggPrice") :: number?) or Config.Eggs.Price
	rollPrompt.ObjectText = if free then "First one's on us" else Formulas.formatCoins(price) .. " coins"
	freeBadge.Enabled = free
end
player:GetAttributeChangedSignal("FreeEgg"):Connect(refreshPrompt)
player:GetAttributeChangedSignal("EggPrice"):Connect(refreshPrompt)
refreshPrompt()

-- An egg machine's odds sign (6.4 x 5.2 studs, 320 x 260 px): the title across the top, the egg's Blender-rendered
-- picture (Shared.ArtAssets.Eggs, tools/shop_icons.py) on the left, one row per rarity and a footer on the right.
-- Built from Config so it always matches the real odds (players must see the real chances).
local function percentText(weight: number, total: number): string
	-- one decimal at most, and none when it's a whole number (58/100 * 100 is 58.000000001 in floating point)
	local shown = string.format("%.1f", weight / total * 100)
	return (string.gsub(shown, "%.0$", ""))
end
local function oddsBoard(surface: SurfaceGui, title: string, weights: { number }, footer: string, footerColor: Color3, image: string?)
	local root = Instance.new("Frame")
	root.Name = "Odds"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = surface
	label(root, title, UDim2.fromScale(0.94, 0.17), UDim2.fromScale(0.5, 0.11), WHITE, 4)
	if image then
		local img = Instance.new("ImageLabel")
		img.Name = "EggArt"
		img.BackgroundTransparency = 1
		img.Image = image
		img.ScaleType = Enum.ScaleType.Fit
		img.Position = UDim2.fromScale(0.02, 0.22)
		img.Size = UDim2.fromScale(0.38, 0.76)
		img.Parent = root
	end
	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = if image then UDim2.fromScale(0.41, 0.21) else UDim2.fromScale(0.05, 0.21)
	list.Size = if image then UDim2.fromScale(0.57, 0.77) else UDim2.fromScale(0.9, 0.77)
	list.Parent = root
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.03, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local function row(text: string, color: Color3, height: number, order: number)
		local l = label(list, text, UDim2.fromScale(1, height), UDim2.new(), color, 4)
		l.AnchorPoint = Vector2.zero
		l.LayoutOrder = order
	end
	local total = 0
	for _, w in weights do
		total += w
	end
	local shown = 0
	for _, w in weights do
		if w > 0 then
			shown += 1
		end
	end
	local rowHeight = math.min(0.19, 0.74 / math.max(1, shown))
	for index, w in weights do
		if w > 0 then
			local name, color = rarityInfo(index)
			row(string.format("%s  %s%%", name, percentText(w, total)), color, rowHeight, index)
		end
	end
	row(footer, footerColor, 0.15, 99)
end

do -- the Briefcase Egg's board
	local weights = {}
	for i, skin in Config.Eggs.Skins do
		weights[i] = skin.Weight
	end
	oddsBoard(oddsGui, "BRIEFCASE EGG ODDS", weights, "from " .. Formulas.formatCoins(Config.Eggs.Price) .. " coins",
		Color3.fromRGB(255, 215, 60), ArtAssets.Eggs.Briefcase)
end

-- Themed eggs: idle bob, prompt text and their own odds boards
for n, def in Config.Eggs.Themed do
	local tMachine = if zoneEggs[def.Id] then nil else workspace.Hub:WaitForChild(def.Machine, 10)
	if not tMachine then
		continue
	end
	local tPrompt = tMachine:FindFirstChild("RollPrompt", true) :: ProximityPrompt?
	if tPrompt then
		table.insert(themedPrompts, tPrompt)
	end
	local bEgg = tMachine:WaitForChild("Egg") :: Model
	RunService.RenderStepped:Connect(function()
		local home = eggHomeOf(bEgg) -- server-published home, see the Briefcase egg above
		if not home or not bEgg.PrimaryPart then
			return
		end
		local t = os.clock() + 1.7 * n -- out of step with each other
		bEgg:PivotTo(home * CFrame.new(0, math.sin(t * 2) * 0.35, 0) * CFrame.Angles(0, t * 0.6, math.sin(t * 1.3) * 0.06))
	end)
	local attr = def.Id .. "EggPrice"
	local function refreshThemed()
		if tPrompt then
			tPrompt.ActionText = "Hatch a " .. def.Id .. " Lawyer"
			local price = (player:GetAttribute(attr) :: number?) or Config.Eggs.Price * def.PriceMultiplier
			tPrompt.ObjectText = Formulas.formatCoins(price) .. " coins"
		end
	end
	player:GetAttributeChangedSignal(attr):Connect(refreshThemed)
	refreshThemed()
	local board = tMachine:FindFirstChild("OddsBoard")
	local bGui = board and board:FindFirstChild("SurfaceGui")
	if bGui then
		bGui:ClearAllChildren()
		oddsBoard(bGui :: SurfaceGui, string.upper(def.Name) .. " ODDS", def.Weights, def.Tagline, Color3.fromRGB(150, 255, 110), ArtAssets.Eggs[def.Id])
	end
end

-------------------------------------------------------------------------------
-- Hatch screen
-------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "EggHatch"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = BLACK
dim.BackgroundTransparency = 1
dim.BorderSizePixel = 0
dim.Parent = gui

-------------------------------------------------------------------------------
-- Reveal stage, 2D light layers (user 2026-10-09: "redesign the reveal - cohesive background, the character
-- is the star, rarity identity through lighting and composition, no spinning circles / random shapes").
-- Behind the full-screen 3D viewport: a rarity-tinted backdrop gradient + vignette, a soft spotlight glow behind
-- the character and (Rare+) a light shaft falling onto the pedestal. Nothing spins.
-------------------------------------------------------------------------------
local stageBg = Instance.new("Frame")
stageBg.Name = "StageBackdrop"
stageBg.Size = UDim2.fromScale(1, 1)
stageBg.BackgroundColor3 = WHITE
stageBg.BackgroundTransparency = 1
stageBg.BorderSizePixel = 0
stageBg.ZIndex = 2
stageBg.Parent = gui
local stageGrad = Instance.new("UIGradient")
stageGrad.Rotation = 90
stageGrad.Parent = stageBg

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = BLACK
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 2
vignette.Parent = gui
local vignetteGrad = Instance.new("UIGradient")
vignetteGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.1),
	NumberSequenceKeypoint.new(0.28, 1),
	NumberSequenceKeypoint.new(0.72, 1),
	NumberSequenceKeypoint.new(1, 0.1),
})
vignetteGrad.Parent = vignette

local stageGlow = Instance.new("ImageLabel")
stageGlow.Name = "Spotlight"
stageGlow.AnchorPoint = Vector2.new(0.5, 0.5)
stageGlow.BackgroundTransparency = 1
stageGlow.Image = FX.glow
stageGlow.ImageTransparency = 1
stageGlow.ZIndex = 3
stageGlow.Parent = gui

-- the shaft: the soft glow texture stretched into a tall narrow column = a beam of light from above
-- (a CanvasGroup + gradients version never rendered)
local stageShaft = Instance.new("ImageLabel")
stageShaft.Name = "LightShaft"
stageShaft.AnchorPoint = Vector2.new(0.5, 1)
stageShaft.BackgroundTransparency = 1
stageShaft.Image = FX.glow
stageShaft.ImageTransparency = 1
stageShaft.ZIndex = 4 -- layers (global): dim 1, backdrop 2, glow 3, shaft 4, 3D scene 5, text 6+
stageShaft.Parent = gui

-- Legendary only: a few slow golden motes drifting up through the light (recycled, not a particle burst)
local motes: { ImageLabel } = {}
for i = 1, 10 do
	local m = Instance.new("ImageLabel")
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.BackgroundTransparency = 1
	m.Image = FX.ember
	m.ImageTransparency = 1
	m.ZIndex = 3
	m.Visible = false
	m.Parent = gui
	motes[i] = m
end

-------------------------------------------------------------------------------
-- The 3D egg, v3 (user 2026-10-09: "make the egg physically separate along its cracks, glowing interior in
-- the rarity colour" - remade in Blender). Shared.HatchShells (generated by tools/egg_shells.py) rebuilds each
-- machine egg as a HOLLOW two-layer voxel shell (egg colours outside, pale lining inside) fractured into 9
-- shards with jagged seams along the voxel grid: a bottom cup, 3 lower + 4 upper petals and a top cap.
-- Three values drive it every frame (same maths as shard_pose() in egg_shells.py):
--   crack 0..1  seams open one after another (CRACK order) - hairline gaps, the core's light leaks through
--   open  0..1  petals fold out on their lower-edge hinges, the cap lifts and tips back
--   glow  0..1  the rarity-coloured Neon core inside swells; the lining warms towards the rarity colour
-- The ViewportFrame covers the whole screen (transparent), so there's no square anywhere; the camera FOV sets
-- the egg's size. Tap / click to skip ahead.
-------------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local HatchShells = require(Shared:WaitForChild("HatchShells") :: ModuleScript) :: any

local eggView = Instance.new("ViewportFrame")
eggView.AnchorPoint = Vector2.new(0.5, 0.5)
eggView.Position = UDim2.fromScale(0.5, 0.5)
eggView.Size = UDim2.fromScale(1, 1) -- full screen: no frame edge for the egg or its pieces to hit
eggView.BackgroundTransparency = 1
eggView.Ambient = Color3.fromRGB(175, 175, 180)
eggView.LightColor = Color3.fromRGB(255, 246, 230)
eggView.LightDirection = Vector3.new(-0.6, -1, -0.8)
eggView.ZIndex = 5
eggView.Visible = false
eggView.Parent = gui
local eggCam = Instance.new("Camera")
eggCam.FieldOfView = 35
eggCam.Parent = eggView
eggView.CurrentCamera = eggCam

local eggModel3d: Model? = nil
local eggParts: { BasePart } = {}
type Shard = { def: any, parts: { { part: BasePart, rest: CFrame } }, pivot: Vector3, axis: Vector3, dir: Vector3 }
local shards: { Shard } = {}
local innerParts: { BasePart } = {}
local core: BasePart? = nil
local coreHalo: BasePart? = nil
local eggRarity = Color3.new(1, 1, 1)
local INNER = Color3.fromRGB(247, 237, 214)
local eggFreq = 18
local eggValues: { [string]: NumberValue } = {} -- what the sequence tweens; the driver reads them every frame
for _, k in { "amp", "y", "rumble", "camDist", "punch", "crack", "open", "glow" } do
	eggValues[k] = Instance.new("NumberValue")
end
local EGG_PX = 300 -- the egg's height on screen (px, before fit()) at the resting camera distance
local EGG_REST_DIST = 22
local eggScreenScale = 1
local eggDriver: RBXScriptConnection? = nil
local skipping = false
local eggPhase = false
-- Sound cues for StarterPlayerScripts.Sounds: ("beat", round) on every crack round, ("burst", rarity) when the
-- egg opens. A client-only BindableEvent, because the timing depends on the animation (and on skipping).
local hatchCue: BindableEvent = (ReplicatedStorage:FindFirstChild("HatchCue") :: any) or Instance.new("BindableEvent")
hatchCue.Name = "HatchCue"
hatchCue.Parent = ReplicatedStorage

UserInputService.InputBegan:Connect(function(input)
	if eggPhase and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		skipping = true
	end
end)

-- waits `seconds`, or less once the player taps to skip
local function pause(seconds: number)
	local t0 = os.clock()
	while os.clock() - t0 < seconds and not skipping do
		RunService.RenderStepped:Wait()
	end
end

local function tweenValue(name: string, seconds: number, to: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	tween(eggValues[name], if skipping then 0.05 else seconds, { Value = to }, style, direction)
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

-- Builds the breakable shell of the egg on the machine the player used (Briefcase or a themed egg).
local function buildEgg3d(eggId: string?, rarityColor: Color3)
	if eggModel3d then
		eggModel3d:Destroy()
	end
	eggParts, shards, innerParts = {}, {}, {}
	local def = Formulas.themedEgg(eggId)
	local data = HatchShells[if def then def.Machine else "EggMachine"] or HatchShells.EggMachine
	local model = Instance.new("Model")
	model.Name = "HatchEgg"
	for _, s in data.shards do
		local shard: Shard = { def = s, parts = {}, pivot = vec(s.pivot), axis = vec(s.axis).Unit, dir = vec(s.dir) }
		for _, b in s.boxes do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CastShadow = false
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			p.Size = Vector3.new(b[4], b[5], b[6])
			p.Color = if b[10] == 1 then INNER else Color3.new(b[7], b[8], b[9])
			p.Material = Enum.Material.SmoothPlastic
			local rest = CFrame.new(b[1], b[2], b[3])
			p.CFrame = rest
			p.Parent = model
			table.insert(shard.parts, { part = p, rest = rest })
			table.insert(eggParts, p)
			if b[10] == 1 then
				table.insert(innerParts, p)
			end
		end
		table.insert(shards, shard)
	end
	-- the light inside: a Neon core + a soft halo shell, both in the rarity colour (Viewports don't render
	-- lights, so the glow is real geometry behind the seams, and the lining is tinted to look lit)
	eggRarity = rarityColor
	local function ball(name: string, transparency: number): Part
		local b = Instance.new("Part")
		b.Name = name
		b.Shape = Enum.PartType.Ball
		b.Anchored = true
		b.CanCollide = false
		b.Material = Enum.Material.Neon
		b.Color = rarityColor
		b.Transparency = transparency
		b.Size = Vector3.one * 0.1
		b.Parent = model
		return b
	end
	core = ball("Core", 0)
	coreHalo = ball("Halo", 0.6)
	model.WorldPivot = CFrame.new()
	model.Parent = eggView
	eggModel3d = model
end

local function stopEggDriver()
	if eggDriver then
		eggDriver:Disconnect()
		eggDriver = nil
	end
end

local CRACK_COUNT = 9

-- shard_pose() from tools/egg_shells.py: (offset, hinge angle) for a shard at crack c and open o
local function shardPose(s: Shard, c: number, o: number): (Vector3, number)
	local k = math.clamp(c * CRACK_COUNT - (s.def.order - 1), 0, 1)
	local seam = 0.16 * k -- wide enough to see the glowing lining through
	local ease = o * o * (3 - 2 * o)
	local kind = s.def.kind
	if kind == "cup" then
		return s.dir * seam * 0.5, 0
	elseif kind == "cap" then
		return s.dir * (seam + 1.6 * ease) + Vector3.new(0, 0.9 * ease, 0), math.rad(-35) * ease
	end
	local fold = math.rad(if kind == "upper" then 55 else 30) * ease
	return s.dir * (seam + 0.6 * ease), -fold
end

-- Every frame: wobble, rumble, camera, and the shell pose (crack / open) + the glow.
local function startEggDriver()
	stopEggDriver()
	eggDriver = RunService.RenderStepped:Connect(function()
		local model = eggModel3d
		if not model then
			return
		end
		local t = os.clock()
		local amp, rumble = eggValues.amp.Value, eggValues.rumble.Value
		local roll = amp * math.sin(t * eggFreq) + rumble * (math.random() - 0.5) * 12
		local hop = math.abs(math.sin(t * eggFreq * 0.5)) * amp * 0.015 + rumble * (math.random() - 0.5) * 0.3
		local base = CFrame.new(rumble * (math.random() - 0.5) * 0.5, eggValues.y.Value + hop, 0)
			* CFrame.Angles(0, math.sin(t * 0.8) * 0.25, math.rad(roll))
		local c, o, g = eggValues.crack.Value, eggValues.open.Value, eggValues.glow.Value
		for _, s in shards do
			local offset, angle = shardPose(s, c, o)
			local cf = base * CFrame.new(offset + s.pivot) * CFrame.fromAxisAngle(s.axis, angle) * CFrame.new(-s.pivot)
			for _, e in s.parts do
				e.part.CFrame = cf * e.rest
			end
		end
		-- the core grows and flickers; the lining picks up its colour as the light gets stronger
		local flicker = 1 + 0.06 * math.sin(t * 23) + 0.04 * math.sin(t * 37)
		if core and coreHalo then
			core.CFrame = base * CFrame.new(0, -0.2, 0)
			coreHalo.CFrame = core.CFrame
			core.Size = Vector3.one * (0.4 + 4.2 * g) * flicker
			coreHalo.Size = Vector3.one * (0.6 + 6.6 * g) * flicker
			core.Transparency = if g > 0.01 then 0 else 1
			coreHalo.Transparency = 1 - 0.45 * g
		end
		-- the inner lining IS the light: once the glow starts it turns Neon in the rarity colour, so every seam
		-- shows a bright line and the inner edges of the opening shell blaze (Viewports render no lights)
		local neon = g > 0.02
		local lit = if neon then Color3.new(0, 0, 0):Lerp(eggRarity, math.clamp(0.35 + g, 0, 1)):Lerp(Color3.new(1, 1, 1), math.max(g - 0.75, 0)) else INNER
		for _, p in innerParts do
			p.Color = lit
			p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
		-- camera: the FOV makes the egg EGG_PX tall at rest on any screen; aim a bit low so the egg sits at 42%
		-- of the screen height (where the glow and rays are centred); a heartbeat "punch" nudges it closer
		local screenH = math.max(eggView.AbsoluteSize.Y, 1)
		local visible = 8.6 * screenH / (EGG_PX * eggScreenScale)
		eggCam.FieldOfView = math.deg(2 * math.atan(visible / 2 / EGG_REST_DIST))
		local d = eggValues.camDist.Value - eggValues.punch.Value * 1.4
		local lift = 0.08 * 2 * d * math.tan(math.rad(eggCam.FieldOfView) / 2)
		local rise = 6 * o * (2 - o) -- as it opens, the camera rises to look down into the glowing shell
		eggCam.CFrame = CFrame.lookAt(Vector3.new(0, 1.6 - lift + rise, d), Vector3.new(0, 0.2 - lift, 0))
	end)
end

-- The finale: the open shell blows apart - every piece keeps flying outward from its shard, spinning and
-- fading, while the core flares white-hot.
local function shatter()
	stopEggDriver()
	local model = eggModel3d
	if not model then
		eggView.Visible = false
		return
	end
	local bits = {}
	for _, s in shards do
		local out = s.dir + Vector3.new(0, 0.35, 0)
		for _, e in s.parts do
			table.insert(bits, {
				part = e.part,
				vel = out.Unit * (10 + math.random() * 10) + Vector3.new(0, 4 + math.random() * 6, 5),
				spin = CFrame.Angles((math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.3),
			})
		end
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local u = os.clock() - t0
		for _, b in bits do
			b.vel += Vector3.new(0, -40 * dt, 0)
			b.part.CFrame = (b.part.CFrame + b.vel * dt) * b.spin
			b.part.Transparency = math.clamp((u - 0.12) / 0.33, 0, 1) -- gone fast: the lawyer is rising
		end
		if core and coreHalo then
			core.Size = Vector3.one * (4.6 + u * 14)
			core.Color = eggRarity:Lerp(Color3.new(1, 1, 1), math.clamp(u * 3, 0, 0.7))
			core.Transparency = math.clamp(u / 0.6, 0, 1)
			coreHalo.Size = Vector3.one * (7 + u * 20)
			coreHalo.Transparency = math.clamp(0.55 + u * 2.5, 0, 1)
		end
		if u > 0.8 then
			conn:Disconnect()
			model:Destroy()
			if eggModel3d == model then
				eggModel3d = nil -- (the view stays: the reveal stage lives in it)
			end
		end
	end)
end

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = WHITE
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 10
flash.Parent = gui

-- The reveal's text + buttons sit BELOW the character (it stands at ~36% of the screen height on the pedestal);
-- nothing overlaps it. They animate in one after another (revealText).
local reveal = Instance.new("Frame")
reveal.AnchorPoint = Vector2.new(0.5, 0)
reveal.Position = UDim2.fromScale(0.5, 0.645)
reveal.Size = UDim2.fromOffset(520, 250)
reveal.BackgroundTransparency = 1
reveal.Visible = false
reveal.ZIndex = 5
reveal.Parent = gui
local revealScale = Instance.new("UIScale")
revealScale.Parent = reveal

local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local nameLabel = label(reveal, "", UDim2.fromOffset(500, 60), UDim2.fromOffset(260, 30), WHITE, 5)
nameLabel.Font = UIFonts.Title -- the hatched lawyer's name: the big reveal
nameLabel.ZIndex = 6
local nameShimmer = Instance.new("UIGradient") -- Legendary: a slow gold sweep through the name
nameShimmer.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 205, 60)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 205, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 252, 225)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 205, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 205, 60)),
})
nameShimmer.Enabled = false
nameShimmer.Parent = nameLabel
local newBadge = label(reveal, "NEW!", UDim2.fromOffset(110, 46), UDim2.new(0.5, 215, 0, 6), Color3.fromRGB(255, 215, 60), 4)
newBadge.Rotation = 12
newBadge.Font = UIFonts.Title -- big moment
newBadge.ZIndex = 7

local pill = Instance.new("Frame")
pill.AnchorPoint = Vector2.new(0.5, 0.5)
pill.Position = UDim2.fromOffset(260, 84)
pill.Size = UDim2.fromOffset(180, 38)
pill.ZIndex = 6
pill.Parent = reveal
corner(pill, 0.5)
outline(pill, 4, Enum.ApplyStrokeMode.Border)
local pillText = label(pill, "", UDim2.fromScale(0.9, 0.8), UDim2.fromScale(0.5, 0.5), WHITE, 3)
pillText.ZIndex = 7
local buffLabel = label(reveal, "", UDim2.fromOffset(420, 30), UDim2.fromOffset(260, 124), Color3.fromRGB(255, 225, 90), 3)
buffLabel.ZIndex = 6

local function button(text: string, color: Color3, x: number): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromOffset(x, 196)
	b.ZIndex = 6 -- (this ScreenGui layers globally: above the backdrop's light layers)
	b.Size = UDim2.fromOffset(190, 66)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Font = FONT
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.TextStrokeTransparency = 0
	b.Text = text
	b.Parent = reveal
	corner(b, 0.3)
	outline(b, 5, Enum.ApplyStrokeMode.Border)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b
	b.MouseEnter:Connect(function()
		tween(scale, 0.12, { Scale = 1.08 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
	end)
	return b
end
local equipButton = button("PLACE", GREEN, 150)
local niceButton = button("KEEP", BLUE, 370)

local toast = label(gui, "", UDim2.fromOffset(460, 56), UDim2.fromScale(0.5, 0.6), Color3.fromRGB(255, 110, 110), 4)
toast.Visible = false
toast.ZIndex = 20

-------------------------------------------------------------------------------
-- Hatch sequence
-------------------------------------------------------------------------------

-- The hatch screen is laid out for ~700px of height; shrink it on smaller screens (phones).
local function fit(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / 700, 0.5, 1) else 1
end

local busy = false
local current: { skinId: string, uid: string?, emptyOffice: number?, copies: number? }? = nil
local spin: RBXScriptConnection? = nil

local function showToast(text: string)
	toast.Text = text
	toast.Visible = true
	toast.Size = UDim2.fromOffset(0, 0)
	tween(toast, 0.3, { Size = UDim2.fromOffset(460, 56) }, Enum.EasingStyle.Back)
	task.delay(1.8, function()
		if not busy then
			gui.Enabled = false
		end
		toast.Visible = false
	end)
end

-------------------------------------------------------------------------------
-- Reveal stage, 3D. One continuous scene in the full-screen egg viewport: the egg sits on a blocky studded
-- pedestal (the map's own Plastic + Studs style) from the moment it drops in; when it bursts, the real lawyer
-- rises out of the light onto the same pedestal (scale up, overshoot, settle), then idles with Shared.Puppet and
-- a slow turn while the camera glides to a low hero angle. The viewport light takes the rarity colour, so the
-- character is lit by it. Rarity changes the light, the entrance and the camera - never the layout.
-------------------------------------------------------------------------------
local Puppet = require(Shared:WaitForChild("Puppet") :: ModuleScript) :: any

local CHAR_H = 0.36 -- the character's height as a share of the screen
local CHAR_Y = 0.32 -- its centre, from the top of the screen (pedestal + text fit below)
local ENTER = 0.8 -- seconds of the entrance (rise + overshoot + settle)
local EGG_AMBIENT, EGG_LIGHT = Color3.fromRGB(175, 175, 180), Color3.fromRGB(255, 246, 230)
local LOOKS = {
	Common = { glow = 0.62, glowSize = 1.5, shaft = nil, overshoot = 1.05, clip = "nod", flash = 0.45 },
	Uncommon = { glow = 0.5, glowSize = 1.7, shaft = nil, overshoot = 1.08, clip = "nod", flash = 0.5 },
	Rare = { glow = 0.38, glowSize = 1.9, shaft = 0.3, overshoot = 1.11, clip = "celebrate", flash = 0.6 },
	Epic = { glow = 0.3, glowSize = 2.0, shaft = 0.22, overshoot = 1.12, clip = "celebrate", flash = 0.7 },
	Legendary = { glow = 0.2, glowSize = 2.2, shaft = 0.1, overshoot = 1.15, clip = "celebrate", flash = 0.85, impact = true, motes = true, shimmer = true },
}

local stageModel: Model? = nil
local trimParts: { BasePart } = {}
local pool: BasePart? = nil
local pedTop = -4.3
local revealChar: Model? = nil
local revealDriver: RBXScriptConnection? = nil

local function stagePart(model: Model, size: Vector3, cf: CFrame, color: Color3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.Plastic
	p.TopSurface = if neon then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- the pedestal under the egg (and later the lawyer): a stepped round slab, a glowing trim band, a light pool
local function buildStage()
	if stageModel then
		stageModel:Destroy()
	end
	trimParts = {}
	local model = Instance.new("Model")
	model.Name = "Stage"
	if eggModel3d then
		local box, size = eggModel3d:GetBoundingBox()
		pedTop = box.Position.Y - size.Y / 2
	end
	local top, side = Color3.fromRGB(62, 58, 80), Color3.fromRGB(44, 41, 58)
	for _, s in { Vector3.new(7.6, 0.7, 4.2), Vector3.new(4.2, 0.7, 7.6), Vector3.new(6.4, 0.7, 6.4) } do
		stagePart(model, s, CFrame.new(0, pedTop - 0.35, 0), top)
		table.insert(trimParts, stagePart(model, s + Vector3.new(0.3, -0.52, 0.3), CFrame.new(0, pedTop - 0.79, 0), EGG_LIGHT, true))
		stagePart(model, s + Vector3.new(0.9, 0.2, 0.9), CFrame.new(0, pedTop - 1.33, 0), side)
	end
	local disc = stagePart(model, Vector3.new(0.06, 5.2, 5.2), CFrame.new(0, pedTop + 0.04, 0) * CFrame.Angles(0, 0, math.pi / 2), WHITE, true)
	disc.Shape = Enum.PartType.Cylinder
	disc.Transparency = 1
	pool = disc
	model.Parent = eggView
	stageModel = model
end

-- The real hatched lawyer: this player's office-1 lawyer re-dressed in the new skin (the same model the desks
-- show), stripped of anything that isn't geometry. Fallback: the bare skin model.
local function makeCharacter(skinId: string): Model?
	local plotName = player:GetAttribute("Plot")
	local plot = typeof(plotName) == "string" and workspace.Plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local desk = firm and firm:FindFirstChild("Desk1")
	local source = desk and desk:FindFirstChild("Lawyer")
	local m: Model? = nil
	if source and source:IsA("Model") then
		m = Puppet.cloneAtRest(source)
		SkinLook.dress(m :: Model, skinId)
	else
		local skin = Formulas.getSkin(skinId)
		local folder = ReplicatedStorage:FindFirstChild("SkinModels")
		local t = skin and skin.Model and folder and folder:FindFirstChild(skin.Model)
		if t then
			m = t:Clone()
		end
	end
	if not m then
		return nil
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") or d:IsA("Sound")
			or d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("Highlight") or d:IsA("Humanoid") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	return m
end

local function stopReveal()
	if revealDriver then
		revealDriver:Disconnect()
		revealDriver = nil
	end
	if revealChar then
		revealChar:Destroy()
		revealChar = nil
	end
	if stageModel then
		stageModel:Destroy()
		stageModel = nil
	end
	for _, m in motes do
		m.Visible = false
	end
end

local function resetStage()
	stopReveal()
	stageBg.BackgroundTransparency = 1
	vignette.BackgroundTransparency = 1
	stageGlow.ImageTransparency = 1
	stageShaft.ImageTransparency = 1
	nameShimmer.Enabled = false
	eggView.Ambient = EGG_AMBIENT
	eggView.LightColor = EGG_LIGHT
	eggView.LightDirection = Vector3.new(-0.6, -1, -0.8)
end

local function easeOut(x: number, p: number): number
	return 1 - (1 - math.clamp(x, 0, 1)) ^ p
end
local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Text + buttons come in one after another: name rises in, rarity pill pops, earnings fade, NEW! stamps, buttons
-- slide up. (Home positions are where layout put them.)
local HOME: { [GuiObject]: UDim2 } = {}
local function remember(o: GuiObject)
	if not HOME[o] then
		HOME[o] = o.Position
	end
end
local function fadeText(l: TextLabel | TextButton, to: number, t: number)
	tween(l, t, { TextTransparency = to })
	local s = l:FindFirstChildOfClass("UIStroke")
	if s then
		tween(s, t, { Transparency = to })
	end
end
local function revealText(buttons: { TextButton })
	for _, o in { nameLabel, pill, buffLabel, newBadge, table.unpack(buttons) } do
		remember(o)
	end
	nameLabel.Position = HOME[nameLabel] + UDim2.fromOffset(0, 26)
	nameLabel.TextTransparency = 1
	nameLabel:FindFirstChildOfClass("UIStroke").Transparency = 1
	tween(nameLabel, 0.5, { Position = HOME[nameLabel] }, Enum.EasingStyle.Back)
	fadeText(nameLabel, 0, 0.35)
	pill.Size = UDim2.fromOffset(0, 38)
	task.delay(0.2, function()
		tween(pill, 0.35, { Size = UDim2.fromOffset(180, 38) }, Enum.EasingStyle.Back)
	end)
	buffLabel.TextTransparency = 1
	buffLabel:FindFirstChildOfClass("UIStroke").Transparency = 1
	buffLabel.Position = HOME[buffLabel] + UDim2.fromOffset(0, 10)
	task.delay(0.35, function()
		tween(buffLabel, 0.35, { Position = HOME[buffLabel] })
		fadeText(buffLabel, 0, 0.35)
	end)
	task.defer(function() -- NEW! sits just past the end of the name, however long it is
		newBadge.Position = UDim2.new(0.5, math.min(nameLabel.TextBounds.X / 2 + 40, 250), 0, -4)
	end)
	local badgeScale = newBadge:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	badgeScale.Parent = newBadge
	badgeScale.Scale = 0
	task.delay(0.55, function()
		tween(badgeScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	for i, b in buttons do
		b.Position = HOME[b] + UDim2.fromOffset(0, 40)
		b.BackgroundTransparency = 1
		fadeText(b, 1, 0)
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 1
		end
		task.delay(0.6 + i * 0.08, function()
			tween(b, 0.4, { Position = HOME[b], BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
			fadeText(b, 0, 0.3)
		end)
	end
end

-- The camera's hero framing for a character of this height: low angle, character centred at CHAR_Y.
local function heroFraming(height: number): (CFrame, number)
	local fov = 30
	local visible = height / CHAR_H
	local dist = visible / 2 / math.tan(math.rad(fov / 2))
	local target = Vector3.new(0, pedTop + height / 2 - (0.5 - CHAR_Y) * visible, 0)
	return CFrame.lookAt(target + Vector3.new(0, 0.05 * visible, dist), target), fov -- a touch above: the studded pedestal top reads
end

-- Starts the reveal the moment the egg bursts: the stage lights up in the rarity colour, the lawyer rises out of
-- the light, the camera glides to the hero framing.
local function startReveal(skinId: string, rarityName: string, accent: Color3)
	local look = LOOKS[rarityName] or LOOKS.Common
	local screen = gui.AbsoluteSize
	-- light the scene in the rarity colour
	tween(eggView, 0.6, {
		Ambient = accent:Lerp(Color3.fromRGB(140, 140, 150), 0.55),
		LightColor = WHITE:Lerp(accent, 0.3),
	})
	eggView.LightDirection = Vector3.new(-0.45, -0.55, -1) -- from the front-top-left: lights the face
	for _, p in trimParts do
		p.Color = accent
	end
	if pool then
		pool.Color = accent
		pool.Transparency = 1
		tween(pool, 0.6, { Transparency = 0.55 })
	end
	-- the 2D light layers
	stageGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent:Lerp(BLACK, 0.6)),
		ColorSequenceKeypoint.new(0.55, accent:Lerp(BLACK, 0.82)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
	})
	tween(stageBg, 0.5, { BackgroundTransparency = 0.05 })
	tween(vignette, 0.5, { BackgroundTransparency = 0 })
	local charPx = screen.Y * CHAR_H
	stageGlow.ImageColor3 = accent
	stageGlow.Position = UDim2.fromOffset(screen.X / 2, screen.Y * CHAR_Y)
	stageGlow.Size = UDim2.fromOffset(0, 0)
	stageGlow.ImageTransparency = look.glow
	tween(stageGlow, 0.7, { Size = UDim2.fromOffset(charPx * look.glowSize, charPx * look.glowSize) }, Enum.EasingStyle.Quint)
	if look.shaft then
		stageShaft.ImageColor3 = WHITE:Lerp(accent, 0.35)
		stageShaft.Position = UDim2.fromOffset(screen.X / 2, screen.Y * (CHAR_Y + CHAR_H / 2 + 0.03))
		stageShaft.Size = UDim2.fromOffset(charPx * 0.8, screen.Y * (CHAR_Y + CHAR_H / 2 + 0.03) * 1.7) -- the glow's soft top fades out above the screen
		stageShaft.ImageTransparency = 1
		tween(stageShaft, 0.9, { ImageTransparency = look.shaft })
	end
	nameShimmer.Enabled = look.shimmer == true
	-- the character
	local m = makeCharacter(skinId)
	if not m then
		return
	end
	m:PivotTo(CFrame.Angles(0, math.pi, 0)) -- lawyers face -Z, the camera looks from +Z
	local box, size = m:GetBoundingBox()
	local height = size.Y
	local pivotAboveFeet = m:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	local function stand(s: number, rise: number): CFrame
		return CFrame.new(0, pedTop + pivotAboveFeet * s + rise, 0) * CFrame.Angles(0, math.pi, 0)
	end
	m:ScaleTo(0.25)
	m:PivotTo(stand(0.25, -0.6))
	m.Parent = eggView
	revealChar = m
	local camFrom, fovFrom = eggCam.CFrame, eggCam.FieldOfView
	local camTo, fovTo = heroFraming(height)
	local anim: any = nil
	local restBase: CFrame? = nil
	local t0 = os.clock()
	local moteSeed = {}
	for i = 1, #motes do
		moteSeed[i] = { x = (math.random() - 0.5) * charPx * 1.4, speed = 18 + math.random() * 22, phase = math.random() * 10, size = 6 + math.random() * 8 }
	end
	revealDriver = RunService.RenderStepped:Connect(function()
		local u = os.clock() - t0
		-- camera: glide from the egg shot to the hero framing, then a slow drift in
		local a = easeOut(u / 1.1, 4)
		local drift = CFrame.new(0, 0, -math.min(u / 10, 1) * 0.04 * (camTo.Position - Vector3.new(0, camTo.Position.Y, 0)).Magnitude)
		local cam = camFrom:Lerp(camTo * drift, a)
		if look.impact and u > 0.45 and u < 0.75 then -- Legendary: the landing hits
			local k = 1 - (u - 0.45) / 0.3
			cam = cam * CFrame.new((math.random() - 0.5) * 0.25 * k, (math.random() - 0.5) * 0.25 * k, 0)
		end
		eggCam.CFrame = cam
		eggCam.FieldOfView = fovFrom + (fovTo - fovFrom) * a
		-- character: rise out of the light with an overshoot, settle, then idle with a slow turn
		if u < ENTER then
			local x = u / ENTER
			local s, rise
			if x < 0.6 then
				local e = easeOut(x / 0.6, 3)
				s = 0.25 + (look.overshoot - 0.25) * e
				rise = -0.6 + 1.1 * e
			else
				local e = smooth((x - 0.6) / 0.4)
				s = look.overshoot + (1 - look.overshoot) * e
				rise = 0.5 * (1 - e)
			end
			m:ScaleTo(s)
			m:PivotTo(stand(s, rise))
		else
			-- lawyers aren't limb-animated (every model has its own shape, 2026-10-10): it floats and turns slowly
			if not restBase then
				m:ScaleTo(1)
				m:PivotTo(stand(1, 0))
				restBase = m:GetPivot()
			end
			if restBase then
				local t = u - ENTER
				m:PivotTo(restBase * CFrame.new(0, 0.12 + math.sin(t * 2.2) * 0.12, 0) * CFrame.Angles(0, math.sin(t * 0.55) * 0.4, 0))
			end
		end
		-- the light breathes
		stageGlow.ImageTransparency = look.glow + 0.06 * math.sin(u * 2.2)
		if pool then
			pool.Transparency = 0.55 + 0.1 * math.sin(u * 2.2)
		end
		if look.shimmer then
			nameShimmer.Offset = Vector2.new(((u * 0.5) % 1.6) - 0.8, 0)
		end
		if look.motes then
			for i, mote in motes do
				local sd = moteSeed[i]
				local life = ((u * sd.speed + sd.phase * 40) % (charPx * 1.2)) / (charPx * 1.2)
				mote.Visible = true
				mote.ImageColor3 = accent:Lerp(WHITE, 0.3)
				mote.Size = UDim2.fromOffset(sd.size, sd.size)
				mote.Position = UDim2.fromOffset(screen.X / 2 + sd.x + math.sin(u + sd.phase) * 10, screen.Y * (CHAR_Y + CHAR_H / 2) - life * charPx * 1.2)
				mote.ImageTransparency = 0.25 + 0.75 * math.abs(life * 2 - 1) ^ 2
			end
		end
	end)
end

local function close()
	tween(revealScale, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	for _, o in { stageBg, vignette, dim } do
		tween(o, 0.25, { BackgroundTransparency = 1 })
	end
	tween(stageGlow, 0.25, { ImageTransparency = 1 })
	tween(stageShaft, 0.25, { ImageTransparency = 1 })
	task.wait(0.25)
	gui.Enabled = false
	reveal.Visible = false
	current = nil
	eggPhase = false
	stopEggDriver()
	resetStage()
	if eggModel3d then
		eggModel3d:Destroy()
		eggModel3d = nil
	end
	eggView.Visible = false
	busy = false
	rollPrompt.Enabled = true
	for _, p in themedPrompts do
		p.Enabled = true
	end
end

local function play(result: { [string]: any })
	busy = true
	rollPrompt.Enabled = false
	local skin = Formulas.getSkin(result.skinId)
	if not skin then
		busy = false
		rollPrompt.Enabled = true
		return
	end
	local rarityName, rarityColor = rarityInfo(result.rarity)
	current = { skinId = result.skinId, uid = result.uid, emptyOffice = result.emptyOffice, copies = result.copies }
	for _, p in themedPrompts do
		p.Enabled = false
	end

	-- reset
	gui.Enabled = true
	toast.Visible = false
	reveal.Visible = false
	resetStage()
	local legendary = rarityName == "Legendary"
	local rare = rarityName == "Rare"
	local fancy = legendary or rare
	flash.BackgroundTransparency = 1
	local scale = fit()
	skipping = false
	eggPhase = true

	-- 1) the real egg drops in from above and bounces (a breakable copy: Shared.HatchShells)
	buildEgg3d(result.egg, if rarityName == "Common" then Color3.fromRGB(235, 235, 245) else rarityColor)
	for _, k in { "amp", "rumble", "punch", "crack", "open", "glow" } do
		eggValues[k].Value = 0
	end
	eggValues.y.Value = 14
	eggValues.camDist.Value = EGG_REST_DIST
	eggFreq = 18
	eggScreenScale = scale
	buildStage() -- the pedestal the egg sits on (and the lawyer will stand on)
	eggView.Visible = true
	startEggDriver()
	tween(dim, 0.3, { BackgroundTransparency = 0.25 })
	tweenValue("y", 0.75, 0, Enum.EasingStyle.Bounce)
	pause(0.95)

	-- 2) shake rounds, each harder and faster: with every round more seams split open (real gaps in the shell)
	--    and the light inside gets stronger, leaking out through them; camera creeps in, heartbeat, room darkens
	local rounds = if legendary then 4 else 3
	for i = 1, rounds do
		eggFreq = 18 + i * 7
		tweenValue("amp", 0.1, 5 + i * 5)
		tweenValue("camDist", 0.5, EGG_REST_DIST - i * 1.6, Enum.EasingStyle.Back)
		tweenValue("crack", 0.36 + i * 0.04, i / rounds, Enum.EasingStyle.Sine)
		tweenValue("glow", 0.4, 0.06 + 0.1 * i, Enum.EasingStyle.Quad)
		pause(0.34 + i * 0.04)
		tweenValue("amp", 0.15, 0)
		hatchCue:Fire("beat", i)
		eggValues.punch.Value = 1 -- heartbeat: the camera jolts in and eases back
		tweenValue("punch", 0.3, 0, Enum.EasingStyle.Quad)
		tween(dim, 0.4, { BackgroundTransparency = math.max(0.25 - i * 0.04, 0.1) })
		pause(math.max(0.42 - i * 0.08, 0.16))
	end

	-- 3) Rare+: the fake-out. Everything goes still, the light inside dims to an ember...
	if fancy then
		tween(dim, 0.3, { BackgroundTransparency = 0.05 })
		tweenValue("glow", 0.3, 0.08)
		pause(if legendary then 0.75 else 0.45)
	end
	-- 4) ...then the shell peels open: petals start folding back on their hinges, the cap lifts, the light
	--    swells and floods the inner shell while the egg rumbles and the camera pushes in
	local build = if legendary then 1.25 else if rare then 0.9 else 0.6
	tweenValue("rumble", build, 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenValue("camDist", build, 15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenValue("open", build, 0.4, Enum.EasingStyle.Sine)
	tweenValue("glow", build, 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	pause(build)
	-- 5) it bursts fully open (fast), a beat with the light blazing, then the pieces blow away into the reveal
	tweenValue("rumble", 0.15, 0)
	tweenValue("open", 0.35, 1, Enum.EasingStyle.Back)
	tweenValue("glow", 0.3, 1)
	pause(0.45)
	eggPhase = false
	shatter()
	hatchCue:Fire("burst", result.rarity or 1)
	-- 6) one continuous beat: a controlled flash in the rarity light, the stage lights up, the lawyer rises out
	--    of the light onto the pedestal, then name / rarity / buttons come in below it
	local accent = if rarityName == "Common" then Color3.fromRGB(235, 235, 245) else rarityColor
	local look = LOOKS[rarityName] or LOOKS.Common
	flash.BackgroundColor3 = accent:Lerp(WHITE, 0.6)
	flash.BackgroundTransparency = 0.1
	tween(flash, look.flash, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	startReveal(result.skinId, rarityName, accent)

	nameLabel.Text = skin.Name
	pill.BackgroundColor3 = rarityColor
	pillText.Text = string.upper(rarityName)
	local skillNames = {}
	for _, s in result.skills or {} do
		local def = Formulas.getSkillDef(s.Id)
		if def then
			table.insert(skillNames, def.Name)
		end
	end
	buffLabel.Text = string.format("Earns x%s%s", tostring(Formulas.lawyerEarn(result.skinId, 1)), if #skillNames > 0 then "  ·  " .. table.concat(skillNames, ", ") else "")
	if result.emptyOffice then
		equipButton.Text = "PUT IN OFFICE " .. result.emptyOffice
		equipButton.BackgroundColor3 = GREEN
	else
		equipButton.Text = "MY LAWYERS"
		equipButton.BackgroundColor3 = Color3.fromRGB(150, 90, 230)
	end
	niceButton.Text = "KEEP"
	newBadge.Visible = result.isNew == true
	task.wait(0.45) -- the character is mid-rise when the name arrives
	if current == nil then
		return
	end
	revealScale.Scale = scale
	reveal.Visible = true
	revealText({ equipButton, niceButton })
end

RunService.RenderStepped:Connect(function()
	if newBadge.Visible and reveal.Visible then
		newBadge.Rotation = 12 + math.sin(os.clock() * 5) * 5
	end
end)

equipButton.Activated:Connect(function()
	if not current then
		return
	end
	local pick = current
	if pick.emptyOffice and pick.uid then
		PlaceLawyer:InvokeServer(pick.emptyOffice, pick.uid)
		close()
	else
		close()
		local open = ReplicatedStorage:FindFirstChild("LawyersUI") :: BindableEvent?
		if open then
			open:Fire(nil)
		end
	end
end)
niceButton.Activated:Connect(function()
	if current then
		close()
	end
end)

EggHatched.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then
		return
	end
	if not result.ok then
		if not busy then
			gui.Enabled = true
			if result.reason == "full" then
				showToast("Too many lawyers! Merge some at the Lawyer Merger")
			else
				showToast("Need " .. Formulas.formatCoins(result.price or Config.Eggs.Price) .. " coins!")
			end
		end
		return
	end
	if busy then
		return
	end
	task.spawn(play, result)
end)
