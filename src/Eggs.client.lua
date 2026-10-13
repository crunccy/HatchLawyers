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
	-- exact odds (required): one decimal at most, none for whole numbers (58/100 * 100 is 58.000000001 in floating
	-- point) - but two under 1% so Mythic / Supreme show as 0.16% / 0.04% instead of rounding to 0
	local pct = weight / total * 100
	local shown = string.format(if pct < 1 then "%.2f" else "%.1f", pct)
	shown = string.gsub(shown, "0+$", "")
	return (string.gsub(shown, "%.$", ""))
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
	local board = tMachine:FindFirstChild("OddsBoard")
	local bGui = board and board:FindFirstChild("SurfaceGui")
	-- egg tiers: locked until lifetime coins earned (player attribute CoinsEarned) reach def.UnlockEarned
	local wasUnlocked: boolean? = nil
	local function drawBoard(unlocked: boolean)
		if not bGui then
			return
		end
		bGui:ClearAllChildren()
		local footer, footerColor = def.Tagline, Color3.fromRGB(150, 255, 110)
		if not unlocked then
			footer, footerColor = "Unlocks at " .. Formulas.formatCoins(def.UnlockEarned) .. " earned", Color3.fromRGB(255, 120, 120)
		elseif def.EarnMultiplier and def.EarnMultiplier ~= 1 then
			footer = def.Id .. " lawyers earn x" .. tostring(def.EarnMultiplier) .. "!" -- e.g. "Pet lawyers earn x1.25!"
		end
		oddsBoard(bGui :: SurfaceGui, string.upper(def.Name) .. " ODDS", def.Weights, footer, footerColor, ArtAssets.Eggs[def.Id])
	end
	local function refreshThemed()
		local earned = (player:GetAttribute("CoinsEarned") :: number?) or 0
		local unlocked = Formulas.eggUnlocked(def.Id, earned)
		if tPrompt then
			if unlocked then
				tPrompt.ActionText = "Hatch a " .. def.Id .. " Lawyer"
				local price = (player:GetAttribute(attr) :: number?) or Config.Eggs.Price * def.PriceMultiplier
				tPrompt.ObjectText = Formulas.formatCoins(price) .. " coins"
			else
				tPrompt.ActionText = "Locked"
				tPrompt.ObjectText = "Earn " .. Formulas.formatCoins(def.UnlockEarned - earned) .. " more coins"
			end
		end
		if unlocked ~= wasUnlocked then
			wasUnlocked = unlocked
			drawBoard(unlocked)
		end
	end
	player:GetAttributeChangedSignal(attr):Connect(refreshThemed)
	player:GetAttributeChangedSignal("CoinsEarned"):Connect(refreshThemed)
	refreshThemed()
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
-- The hatch screen's words, taps and reveal panel. The hatch itself (v5, 2026-10-12) plays at the incubator in the
-- world: see "the hatch, v5" below.
-------------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local EggLook = require(Shared:WaitForChild("EggLook") :: ModuleScript) :: any
local Puppet = require(Shared:WaitForChild("Puppet") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local HatchShow = Remotes:WaitForChild("HatchShow", 15) :: RemoteEvent?

local FANCY = { Legendary = true, Mythic = true, Supreme = true }
local TAP_TEXT = { "Tap to crack!", "Again!", "One more!" }
local TAP_TIMEOUT = 3.5 -- seconds before a crack happens by itself

-- Sound cues for StarterPlayerScripts.Sounds: ("beat", round) on every crack, ("burst", rarity, rarityName) when the
-- egg opens. A client-only BindableEvent, because the timing depends on the player's taps.
local hatchCue: BindableEvent = (ReplicatedStorage:FindFirstChild("HatchCue") :: any) or Instance.new("BindableEvent")
hatchCue.Name = "HatchCue"
hatchCue.Parent = ReplicatedStorage

-- the full-screen 3D stage for the basic hatch (no frame edge anywhere)
local eggView = Instance.new("ViewportFrame")
eggView.AnchorPoint = Vector2.new(0.5, 0.5)
eggView.Position = UDim2.fromScale(0.5, 0.5)
eggView.Size = UDim2.fromScale(1, 1)
eggView.BackgroundTransparency = 1
eggView.ZIndex = 5
eggView.Visible = false
eggView.Parent = gui
local eggCam = Instance.new("Camera")
eggCam.FieldOfView = 34
eggCam.Parent = eggView
eggView.CurrentCamera = eggCam
local EGG_AMBIENT, EGG_LIGHT = Color3.fromRGB(175, 175, 180), Color3.fromRGB(255, 246, 230)

-- taps
local tapWanted, tapped = false, false
UserInputService.InputBegan:Connect(function(input)
	if tapWanted and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		tapped = true
	end
end)
local function waitTap(timeout: number)
	tapped = false
	tapWanted = true
	local t0 = os.clock()
	while not tapped and os.clock() - t0 < timeout do
		RunService.Heartbeat:Wait()
	end
	tapWanted = false
end

local function easeOut(x: number, p: number): number
	return 1 - (1 - math.clamp(x, 0, 1)) ^ p
end
local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

------------------------------------------------------------------ the screen's words
local function bigText(text: string, size: UDim2, pos: UDim2, color: Color3, stroke: number, z: number?): TextLabel
	local l = label(gui, text, size, pos, color, stroke)
	l.Font = UIFonts.Title
	l.ZIndex = z or 8
	l.Visible = false
	return l
end
local eggTitle = bigText("", UDim2.fromOffset(620, 64), UDim2.fromScale(0.5, 0.1), WHITE, 5)
local topName = bigText("", UDim2.fromOffset(640, 70), UDim2.fromScale(0.5, 0.09), WHITE, 6)
local topSub = label(gui, "", UDim2.fromOffset(420, 32), UDim2.fromScale(0.5, 0.165), WHITE, 3)
topSub.ZIndex = 8
topSub.Visible = false
local tapLabel = label(gui, "", UDim2.fromOffset(380, 46), UDim2.fromScale(0.5, 0.8), WHITE, 4)
tapLabel.ZIndex = 8
tapLabel.Visible = false
local tapScale = Instance.new("UIScale")
tapScale.Parent = tapLabel
local continueLabel = label(gui, "Tap to continue", UDim2.fromOffset(360, 40), UDim2.fromScale(0.5, 0.9), WHITE, 4)
continueLabel.ZIndex = 8
continueLabel.Visible = false
local dotsFrame = Instance.new("Frame")
dotsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
dotsFrame.Position = UDim2.fromScale(0.5, 0.86)
dotsFrame.Size = UDim2.fromOffset(84, 20)
dotsFrame.BackgroundTransparency = 1
dotsFrame.ZIndex = 8
dotsFrame.Visible = false
dotsFrame.Parent = gui
local dots: { Frame } = {}
for i = 1, 3 do
	local d = Instance.new("Frame")
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.fromOffset(14 + (i - 1) * 28, 10)
	d.Size = UDim2.fromOffset(16, 16)
	d.BackgroundColor3 = WHITE
	d.ZIndex = 8
	d.Parent = dotsFrame
	corner(d, 0.5)
	outline(d, 2, Enum.ApplyStrokeMode.Border)
	dots[i] = d
end
local function setDots(n: number)
	for i, d in dots do
		d.BackgroundTransparency = if i <= n then 0 else 0.7
	end
end

-- the radial backdrop of the basic hatch: rings in the egg's colour around the egg (like the reference)
local rings: { Frame } = {}
for i = 4, 1, -1 do -- (biggest first: the smaller ones are later siblings, so they draw on top)
	local r = Instance.new("Frame")
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.fromScale(0.5, 0.45)
	r.BorderSizePixel = 0
	r.BackgroundTransparency = 1
	r.ZIndex = 3
	r.Parent = gui
	corner(r, 0.5)
	rings[i] = r
end
local floorBand = Instance.new("Frame")
floorBand.AnchorPoint = Vector2.new(0.5, 1)
floorBand.Position = UDim2.fromScale(0.5, 1)
floorBand.Size = UDim2.fromScale(1, 0.33)
floorBand.BorderSizePixel = 0
floorBand.BackgroundTransparency = 1
floorBand.ZIndex = 4
floorBand.Parent = gui

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = WHITE
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 10
flash.Parent = gui

------------------------------------------------------------------ the reveal panel (after "Tap to continue")
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

local nameLabel = label(reveal, "", UDim2.fromOffset(500, 60), UDim2.fromOffset(260, 30), WHITE, 5)
nameLabel.Font = UIFonts.Title -- the hatched lawyer's name: the big reveal
nameLabel.ZIndex = 6
local nameShimmer = Instance.new("UIGradient") -- Legendary+: a slow sweep through the name (gold / crimson / rainbow)
local function sweep(c: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, c),
		ColorSequenceKeypoint.new(0.45, c),
		ColorSequenceKeypoint.new(0.5, c:Lerp(WHITE, 0.85)),
		ColorSequenceKeypoint.new(0.55, c),
		ColorSequenceKeypoint.new(1, c),
	})
end
local SHIMMERS = {
	Legendary = sweep(Color3.fromRGB(255, 205, 60)),
	Mythic = sweep(Color3.fromRGB(240, 60, 60)),
	Supreme = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 90)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 255, 120)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 170, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
	}),
}
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
	b.ZIndex = 6
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

-- The hatch screen is laid out for ~700px of height; shrink it on smaller screens (phones).
local function fit(): number
	local camera = workspace.CurrentCamera
	return if camera then math.clamp(camera.ViewportSize.Y / 700, 0.5, 1) else 1
end

local busy = false
local current: { skinId: string, uid: string?, emptyOffice: number?, copies: number? }? = nil

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

------------------------------------------------------------------ the lawyer
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
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	return m
end

-- the lawyer as a black shape; returns a function that brings its colours back
local function silhouette(m: Model): () -> ()
	local saved = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			saved[d] = { d.Color, d.Material, d.Reflectance }
			d.Color = Color3.fromRGB(8, 8, 12)
			d.Material = Enum.Material.SmoothPlastic
			d.Reflectance = 0
		elseif d:IsA("Decal") or d:IsA("Texture") then
			saved[d] = d.Transparency
			d.Transparency = 1
		elseif d:IsA("SurfaceAppearance") then
			saved[d] = d.Parent
			d.Parent = nil
		end
	end
	return function()
		for d, v in saved do
			if d:IsA("BasePart") then
				d.Color, d.Material, d.Reflectance = v[1], v[2], v[3]
			elseif d:IsA("Decal") or d:IsA("Texture") then
				d.Transparency = v
			elseif d:IsA("SurfaceAppearance") then
				d.Parent = v
			end
		end
	end
end

-- the lawyer standing on `floor` at `height` studs tall, facing `facing` (a direction); returns the model + its
-- standing CFrame (pivot)
-- (height nil = keep its own size: the big Mythic / Supreme lawyers)
local function standLawyer(m: Model, floor: Vector3, height: number?, facing: Vector3): CFrame
	if height then
		local _, size = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * height / math.max(size.Y, 0.1))
	end
	local box, size2 = m:GetBoundingBox()
	local pivotAboveFeet = m:GetPivot().Position.Y - (box.Position.Y - size2.Y / 2)
	local look = Vector3.new(facing.X, 0, facing.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, 1)
	-- (lawyers face -Z: turn the model's -Z to `look`)
	local cf = CFrame.lookAt(floor + Vector3.new(0, pivotAboveFeet, 0), floor + Vector3.new(0, pivotAboveFeet, 0) + look)
	m:PivotTo(cf)
	return cf
end

local function chanceText(result: { [string]: any }, rarityName: string): string
	if result.preview then -- (an admin's /hatch preview: nothing was saved)
		return string.upper(rarityName) .. "  ·  PREVIEW"
	end
	local c = result.chance
	if typeof(c) ~= "number" then
		return string.upper(rarityName)
	end
	local shown = string.format(if c < 1 then "%.2f" else "%.1f", c)
	shown = string.gsub(shown, "0+$", "")
	shown = string.gsub(shown, "%.$", "")
	return string.upper(rarityName) .. "  ·  " .. shown .. "% chance"
end

-- the three cracks; `shake(i)` / `settle()` move the egg, the words and dots are shared
local function crackRounds(onTap: (i: number) -> ())
	tapLabel.Visible = true
	dotsFrame.Visible = true
	setDots(0)
	for i = 1, 3 do
		tapLabel.Text = TAP_TEXT[i]
		tapScale.Scale = 0.6
		tween(tapScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		waitTap(TAP_TIMEOUT)
		setDots(i)
		hatchCue:Fire("beat", i)
		onTap(i)
	end
	tapLabel.Visible = false
	dotsFrame.Visible = false
end

------------------------------------------------------------------ the hatch, v5: AT the incubator, in the world
-- (2026-10-12, mr.robe: "remake the animations everything to do with the eggs through blender and add vfx ... make
-- them 10000x cooler"; "scale with rarity"; "last tap reveals"). The egg, the incubator and the shell break are made
-- in Blender (Shared.EggLook, Shared.Incubator, Shared.HatchFx).
--   1. the camera swings to your incubator; its dome opens and the egg floats out of your arms into the cradle
--   2. the dome spins shut and it cooks (Common/Uncommon: a quick spin; Rare/Epic: the heat lamps swing in) - or,
--      Legendary+, it OVERLOADS: alarms, sparks, the dome blows off and the egg rockets into the sky, then crashes back
--   3. the egg floats up out of the cradle and grows: "Tap to crack!" x3 - glowing cracks spread (white; the 3rd tap
--      turns them the rarity's colour), the egg jolts, light leaks out
--   4. build-up (god rays; Epic+ streaks rush in), then the shell bursts (the Blender sim: pop / burst / blast) with
--      the rarity's ladder (Shared.HatchFx.ladder): rings, sparks, confetti, coins, a light pillar, slow motion
--   5. the lawyer rises out of the cradle as a silhouette, then in colour: its name + "RARITY · x% chance"
-- Everyone else near that incubator sees it too, without the camera or the words (Remotes.HatchShow -> playShow).
local HatchFx = require(Shared:WaitForChild("HatchFx") :: ModuleScript) :: any
local Incubator = require(Shared:WaitForChild("Incubator") :: ModuleScript) :: any
local CollectionService = game:GetService("CollectionService")

local fxFolder = Instance.new("Folder")
fxFolder.Name = "HatchFx"
fxFolder.Parent = workspace
HatchFx.setFolder(fxFolder)

local DISPLAY_EGG = 2.5 -- the egg in the cradle (studs tall)
local HATCH_EGG = 3.3 -- the egg you crack
local HOVER = 0.55 -- how far it floats above the cradle while you crack it
local ALARM = Color3.fromRGB(255, 60, 60)
local HEAT = Color3.fromRGB(255, 150, 60)

local function rgbOf(c: any): Color3
	return if typeof(c) == "ColorSequence" then c.Keypoints[1].Value else c
end

local function eggNameOf(eggId: string, golden: boolean): string
	local def = Formulas.themedEgg(eggId)
	return string.upper((if golden then "Golden " else "") .. (if def then def.Name else "Briefcase Egg"))
end

-- where it happens: the incubator the server named (result.at), else your nearest one, else the floor in front of you
type Spot = { inc: Model?, front: Vector3, floor: CFrame }
local function findSpot(at: Vector3?): Spot
	local inc: Model? = nil
	if typeof(at) == "Vector3" then
		inc = Incubator.find(at, 14)
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not inc and root then
		inc = Incubator.find(root.Position, 40)
	end
	if inc and Incubator.isV5(inc) then
		return { inc = inc, front = Incubator.front(inc), floor = Incubator.eggSpot(inc) }
	end
	local origin = if root then root.Position else workspace.CurrentCamera.CFrame.Position
	local look = if root then root.CFrame.LookVector else Vector3.new(0, 0, -1)
	look = Vector3.new(look.X, 0, look.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { fxFolder, character :: Instance }
	local probe = origin + look * 7
	local hit = workspace:Raycast(probe + Vector3.new(0, 6, 0), Vector3.new(0, -24, 0), params)
	local p = Vector3.new(probe.X, if hit then hit.Position.Y else origin.Y - 3, probe.Z)
	return { inc = nil, front = -look, floor = CFrame.lookAt(p, p - look) }
end

local function cradle(sp: Spot): CFrame
	return if sp.inc then Incubator.eggSpot(sp.inc) else sp.floor
end

------------------------------------------------------------------ the camera
local cam = workspace.CurrentCamera
local camSaved: { type: Enum.CameraType, subject: Instance?, fov: number }? = nil
local camGoal, camCur = CFrame.new(), CFrame.new()
local camRate = 6
local camConn: RBXScriptConnection? = nil
-- while a hatch plays, the rest of the HUD and your own character (+ the eggs in your arms) are hidden: they'd sit
-- right in front of the shot
local hiddenGuis: { LayerCollector } = {}
local hiddenParts: { [Instance]: boolean } = {}
local function hideForHatch()
	for _, g in player.PlayerGui:GetDescendants() do
		if (g:IsA("ScreenGui") or g:IsA("BillboardGui")) and g ~= gui and g.Enabled and not g:IsDescendantOf(gui) then
			g.Enabled = false
			table.insert(hiddenGuis, g)
		end
	end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
	if ch then
		for _, d in ch:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				hiddenParts[d] = true
			end
		end
	end
	local carried = workspace:FindFirstChild("CarryVisuals")
	if carried and root then
		for _, d in carried:GetDescendants() do
			if d:IsA("BasePart") and (d.Position - root.Position).Magnitude < 9 then
				hiddenParts[d] = true
			end
		end
	end
end
local function showAfterHatch()
	for _, g in hiddenGuis do
		g.Enabled = true
	end
	table.clear(hiddenGuis)
	for d in hiddenParts do
		if d.Parent then
			(d :: any).LocalTransparencyModifier = 0
		end
	end
	table.clear(hiddenParts)
end

local function camBegin()
	cam = workspace.CurrentCamera
	camSaved = { type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView }
	cam.CameraType = Enum.CameraType.Scriptable
	camCur, camGoal = cam.CFrame, cam.CFrame
	camConn = RunService.RenderStepped:Connect(function(dt)
		camCur = camCur:Lerp(camGoal, 1 - math.exp(-dt * camRate))
		-- (the eggs in your arms are rebuilt when the carried count drops, so they're re-found every frame)
		local carried = workspace:FindFirstChild("CarryVisuals")
		local ch = player.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
		if carried and root then
			for _, d in carried:GetDescendants() do
				if d:IsA("BasePart") and not hiddenParts[d] and (d.Position - root.Position).Magnitude < 9 then
					hiddenParts[d] = true
				end
			end
		end
		for d in hiddenParts do
			(d :: any).LocalTransparencyModifier = 1
		end
		cam.CFrame = camCur * HatchFx.shakeCFrame()
	end)
end
local function camTo(cf: CFrame, rate: number?)
	camGoal = cf
	camRate = rate or 6
end
local function camSnap(cf: CFrame)
	camCur, camGoal = cf, cf
end
local function camEnd()
	if camConn then
		camConn:Disconnect()
		camConn = nil
	end
	HatchFx.clearShakes()
	if camSaved then
		cam.CameraType = camSaved.type
		if camSaved.subject then
			cam.CameraSubject = camSaved.subject
		end
		cam.FieldOfView = camSaved.fov
		camSaved = nil
	end
end
-- looking at the cradle from in front of the incubator: `dist` out, `up` above the cradle, aiming `lookUp` above it
local function shot(sp: Spot, dist: number, up: number, lookUp: number, side: number?): CFrame
	local base = cradle(sp).Position
	local right = sp.front:Cross(Vector3.yAxis)
	return CFrame.lookAt(base + sp.front * dist + Vector3.yAxis * up + right * (side or 0), base + Vector3.yAxis * lookUp)
end

------------------------------------------------------------------ the phases (the owner's hatch and other players' view share them)
-- 1) the egg floats from `from` into the cradle while the dome opens
local function flyIn(sp: Spot, egg: Model, from: CFrame, watch: boolean)
	if sp.inc then
		task.spawn(Incubator.play, sp.inc, "Open", 1.5)
	end
	local t0, DUR = os.clock(), 0.7
	while true do
		local a = math.min((os.clock() - t0) / DUR, 1)
		local e = a * a * (3 - 2 * a)
		local goal = cradle(sp)
		local p0, p2 = from.Position, goal.Position
		local p1 = (p0 + p2) / 2 + Vector3.new(0, 4 + (p0 - p2).Magnitude * 0.3, 0)
		local q = p0 * (1 - e) ^ 2 + p1 * 2 * (1 - e) * e + p2 * e * e
		egg:PivotTo(CFrame.new(q) * goal.Rotation * CFrame.Angles(0, e * math.pi * 2, (1 - e) * 0.7))
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	HatchFx.dust(cradle(sp).Position + Vector3.new(0, 0.3, 0), Color3.new(1, 1, 1), 8)
	if watch then
		hatchCue:Fire("beat", 0)
		HatchFx.shake(0.6, 12, 0.01, 0.25)
	end
end

-- 2) close + cook, or close + overload + launch. Returns the point in the sky the egg reached (fancy), else nil.
local function cookPhase(sp: Spot, egg: Model, tier: any, fxColor: any, watch: boolean, onRocket: ((pos: Vector3) -> ())?): Vector3?
	local inc = sp.inc
	local function follow()
		egg:PivotTo(cradle(sp))
	end
	if inc then
		Incubator.play(inc, "Close", 1.35, follow)
	end
	if not tier.fancy then
		if inc then
			Incubator.glow(inc, HEAT, 0.2)
			local secs = (37 / 30) / tier.cook
			HatchFx.light(cradle(sp).Position + Vector3.new(0, 1.5, 0), HEAT, 10, 0.9, secs + 0.3)
			if watch and tier.cook < 2 then
				HatchFx.shake(0.45, 9, 0.2, 0.3, secs - 0.5)
			end
			task.spawn(function()
				for _ = 1, math.max(1, math.floor(secs / 0.3)) do
					HatchFx.sparks(cradle(sp).Position + Vector3.new(0, 1.2, 0), HEAT, 4, 6, 0.5)
					task.wait(0.3)
				end
			end)
			Incubator.play(inc, "Cook", tier.cook, follow)
			Incubator.glow(inc, nil, 0.3)
			Incubator.play(inc, "Open", 1.25, follow)
		end
		return nil
	end
	-- OVERLOAD: flashing alarm lights, rattling, the dome blows off, the cradle fires the egg into the sky
	local alarm = true
	if inc then
		task.spawn(function()
			local i = 0
			while alarm do
				i += 1
				Incubator.glow(inc, if i % 2 == 0 then ALARM else rgbOf(fxColor))
				task.wait(0.11)
			end
		end)
	end
	if watch then
		HatchFx.shake(1.3, 18, 0.25, 0.25, 0.6)
	end
	local launched = false
	local function launch()
		launched = true
		local at = cradle(sp).Position
		HatchFx.sparks(at + Vector3.new(0, 1, 0), Color3.fromRGB(255, 205, 90), 46, 34, 1.3)
		HatchFx.ring(CFrame.new(at + Vector3.new(0, 0.3, 0)), 10, rgbOf(fxColor), 0.5)
		HatchFx.light(at, rgbOf(fxColor), 20, 1.8, 0.6)
		if watch then
			HatchFx.shake(3.2, 14, 0.01, 0.5)
			hatchCue:Fire("beat", 0)
		end
	end
	if inc then
		Incubator.play(inc, "Overload", 1, function(f)
			if not launched then
				follow()
				if f >= 22 then
					launch()
				end
			end
		end)
	else
		task.wait(0.8)
		launch()
	end
	alarm = false
	if inc then
		Incubator.glow(inc, rgbOf(fxColor), 0.2)
	end
	-- the egg rockets up with a light trail
	local start = cradle(sp).Position
	-- (incubators stand indoors: it rockets up to just under the ceiling, or 46 studs outside)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { fxFolder, egg, inc :: any, player.Character :: any }
	local hit = workspace:Raycast(start + Vector3.new(0, 3, 0), Vector3.new(0, 60, 0), params)
	local rise = if hit then math.max(7, hit.Position.Y - start.Y - 4) else 46
	local top = start + Vector3.new(0, rise, 0)
	local shell = egg.PrimaryPart
	if shell then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0.5, 0, 0)
		a0.Parent = shell
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(-0.5, 0, 0)
		a1.Parent = shell
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = if typeof(fxColor) == "ColorSequence" then fxColor else ColorSequence.new(Color3.new(1, 1, 1), fxColor)
		trail.LightEmission = 0.6
		trail.Lifetime = 0.35
		trail.Transparency = NumberSequence.new(0, 1)
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.FaceCamera = true
		trail.Parent = shell
	end
	local t1, UP = os.clock(), 0.75
	while true do
		local a = math.min((os.clock() - t1) / UP, 1)
		local p = start:Lerp(top, 1 - (1 - a) ^ 2.2)
		egg:PivotTo(CFrame.new(p) * CFrame.Angles(0, a * 14, 0))
		if onRocket then
			onRocket(p)
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	HatchFx.sparks(top, fxColor, 34, 18, 1.5)
	HatchFx.light(top, rgbOf(fxColor), 26, 2.5, 0.7)
	task.wait(0.35)
	return top
end

-- 3a) a fancy egg crashes down from `top` into the cradle
local function crashDown(sp: Spot, h: any, top: Vector3, tier: any, fxColor: any, watch: boolean, onFall: ((pos: Vector3) -> ())?)
	local t0, FALL = os.clock(), 0.55
	while true do
		local a = math.min((os.clock() - t0) / FALL, 1)
		local goal = cradle(sp) * CFrame.new(0, HOVER, 0)
		local p = top:Lerp(goal.Position, a * a)
		h.model:PivotTo(CFrame.new(p) * goal.Rotation * CFrame.Angles(0, (1 - a) * 6, 0))
		if onFall then
			onFall(p)
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	local at = cradle(sp).Position
	HatchFx.ring(CFrame.new(at + Vector3.new(0, 0.25, 0)), 16, rgbOf(fxColor), 0.6, 1.6)
	HatchFx.ring(CFrame.new(at + Vector3.new(0, 0.4, 0)), 9, Color3.new(1, 1, 1), 0.4)
	HatchFx.dust(at + Vector3.new(0, 0.5, 0), Color3.fromRGB(230, 220, 210), 22)
	HatchFx.light(at, rgbOf(fxColor), 18, 1.8, 0.6)
	if watch then
		HatchFx.shake(4.2, 15, 0.01, 0.6)
		hatchCue:Fire("beat", 0)
	end
end

-- 3b) the cradle egg floats up and grows into the egg you crack
local function riseAndGrow(sp: Spot, small: Model, h: any)
	small:Destroy()
	local final = h.scale
	local s0 = DISPLAY_EGG / 3.8
	local t0, DUR = os.clock(), 0.4
	while true do
		local a = math.min((os.clock() - t0) / DUR, 1)
		local e = 1 - (1 - a) ^ 3
		h.model:ScaleTo(s0 + (final - s0) * e)
		h.model:PivotTo(cradle(sp) * CFrame.new(0, HOVER * e, 0) * CFrame.Angles(0, e * math.pi, 0))
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	h.model:ScaleTo(final)
end

-- a live egg: jolts, pulses and hops on springs, wobbles, jitters (during the taps and the build-up)
type Live = { jolt: any, pulse: any, hop: any, wob: number, jitter: number, conn: RBXScriptConnection?, light: PointLight }
local function liveEgg(sp: Spot, h: any): Live
	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Range = 10
	light.Shadows = false
	light.Parent = h.shell
	local live: Live = { jolt = HatchFx.spring(3.2, 0.22), pulse = HatchFx.spring(4.5, 0.3, 1), hop = HatchFx.spring(3.6, 0.45), wob = 0.3, jitter = 0, conn = nil, light = light }
	live.pulse.target = 1
	local base = h.scale
	live.conn = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		local j = HatchFx.stepSpring(live.jolt, dt)
		local s = HatchFx.stepSpring(live.pulse, dt)
		local hop = math.max(0, HatchFx.stepSpring(live.hop, dt))
		local jit = if live.jitter > 0 then CFrame.Angles((math.random() - 0.5) * live.jitter, 0, (math.random() - 0.5) * live.jitter) else CFrame.identity
		local cf = cradle(sp) * CFrame.new(0, HOVER + hop + math.sin(t * 2) * 0.07, 0)
			* CFrame.Angles(0, math.sin(t * 0.8) * 0.35, 0)
			* CFrame.Angles(j * 0.5, 0, j + math.sin(t * 3.1) * 0.05 * live.wob)
			* jit
		if math.abs(h.model:GetScale() - base * s) > 0.003 then
			h.model:ScaleTo(base * s)
		end
		h.model:PivotTo(cf)
	end)
	return live
end

local function stopLive(live: Live, h: any, sp: Spot)
	if live.conn then
		live.conn:Disconnect()
		live.conn = nil
	end
	h.model:ScaleTo(h.scale)
	h.model:PivotTo(cradle(sp) * CFrame.new(0, HOVER, 0))
	live.light:Destroy()
end

-- one crack (i = 1..3): the cracks spread, the egg jolts, dust + sparks fly off, light leaks out
local function crack(h: any, live: Live, i: number, fxColor: any, eggColor: Color3, watch: boolean)
	local col = if i < 3 then Color3.new(1, 1, 1) else rgbOf(fxColor)
	for k = 1, math.min(i, #h.cracks) do
		h.cracks[k].Transparency = 0
		h.cracks[k].Color = col
	end
	local sign = if i % 2 == 1 then 1 else -1
	live.jolt.v += sign * (5 + i * 2.5)
	live.pulse.v += 3 + i * 1.5
	live.hop.v += 6 + i * 2
	live.wob = 0.3 + i * 0.45
	live.light.Color = col
	live.light.Brightness = i * (if i == 3 then 0.5 else 0.3)
	live.light.Range = 8 + i * 2.5
	local pt = if #h.chunks > 0 then h.chunks[math.random(1, #h.chunks)].Position else h.shell.Position
	HatchFx.dust(pt, eggColor, 6 + i * 3)
	HatchFx.sparks(pt, col, 6 + i * 5, 14, 0.6)
	if watch then
		HatchFx.shake(0.8 + i * 0.55, 16, 0.01, 0.35)
		HatchFx.post({ blur = { Size = 5 + i } }, 0)
		HatchFx.post({ blur = { Size = 0 } }, 0.25)
		if i == 3 then
			HatchFx.post({ cc = { TintColor = Color3.new(1, 1, 1):Lerp(col, 0.22) } }, 0.4)
		end
	end
end

-- 4) the build-up after the 3rd crack (god rays, an implosion), then the burst; the break plays on (returns at once)
local function buildUp(h: any, live: Live, tier: any, fxColor: any, watch: boolean)
	local centre = h.shell.Position
	local rays = if tier.rays > 0 then HatchFx.rays(centre, fxColor, tier.rays, 8 + tier.rays * 0.6, tier.build) else nil
	local imp = if tier.implode then HatchFx.implode(centre, fxColor, if tier.blackhole then 13 else 9, if tier.blackhole then 220 else 140) else nil
	if watch then
		HatchFx.post({ cc = { Brightness = if tier.blackhole then -0.3 else -0.12, Contrast = 0.22 }, bloom = { Intensity = 0.4 + tier.bloom * 0.3, Threshold = 1.35 } }, tier.build)
		HatchFx.shake(1.1 + tier.shake * 0.15, 22, tier.build, 0.15)
	end
	-- Epic: purple lightning keeps striking the egg
	local striking = tier.bolts == true
	if striking then
		task.spawn(function()
			while striking do
				local from = centre + Vector3.new((math.random() - 0.5) * 9, 11 + math.random() * 3, (math.random() - 0.5) * 9)
				HatchFx.bolt(from, centre, rgbOf(fxColor), 0.16, 0.28)
				if watch then
					HatchFx.shake(1.1, 20, 0.01, 0.18)
				end
				task.wait(0.22 + math.random() * 0.2)
			end
		end)
	end
	local t0 = os.clock()
	while os.clock() - t0 < tier.build do
		local a = (os.clock() - t0) / tier.build
		live.jitter = 0.05 + a * 0.2
		live.light.Brightness = 1.2 + a * 1.3
		live.pulse.target = 1 + a * 0.08
		RunService.Heartbeat:Wait()
	end
	striking = false
	if tier.bolts then
		for _ = 1, 3 do
			HatchFx.bolt(centre + Vector3.new((math.random() - 0.5) * 4, 14, (math.random() - 0.5) * 4), centre, rgbOf(fxColor), 0.3, 0.45)
		end
	end
	return function()
		if rays then
			rays.stop(0.25)
		end
		if imp then
			imp.stop()
		end
	end
end

local function burst(sp: Spot, h: any, tier: any, fxColor: any, watch: boolean)
	local root = cradle(sp) * CFrame.new(0, HOVER, 0)
	local centre = root.Position + Vector3.new(0, HATCH_EGG * 0.5, 0)
	local floor = CFrame.new(cradle(sp).Position)
	for r = 1, tier.rings do
		local c = if tier.rainbow then HatchFx.RAINBOW.Keypoints[((r - 1) % #HatchFx.RAINBOW.Keypoints) + 1].Value elseif r % 2 == 0 then Color3.new(1, 1, 1) else rgbOf(fxColor)
		task.delay((r - 1) * 0.08, HatchFx.ring, floor * CFrame.new(0, 0.2 + r * 0.18, 0), 8 + r * 4.5, c, 0.55 + r * 0.1, 1 + r * 0.2)
	end
	HatchFx.sparks(centre, fxColor, 30 + tier.rings * 12, 30 + tier.shake * 4, 1 + tier.rings * 0.15)
	HatchFx.confetti(centre, tier.confetti, 1)
	if tier.coins > 0 then
		HatchFx.coins(centre, tier.coins)
	end
	if tier.burst then
		pcall(Effects.burst, centre, tier.burst, fxColor)
	end
	if tier.pillar then
		HatchFx.pillar(cradle(sp).Position, fxColor, 140, 5.5, 3.2)
	end
	HatchFx.light(centre, rgbOf(fxColor), 22, 2.5, 1.3)
	if watch then
		HatchFx.shake(tier.shake, 14, 0.01, 0.9)
	end
	task.spawn(HatchFx.breakApart, h, tier.take, root, tier.slow)
end

-- the dome lifts clear of the lawyer (the Open clip leaves it just above the cradle)
local function liftDome(inc: Model?, dy: number, seconds: number)
	if not inc then
		return
	end
	local parts = {}
	for _, n in { "Dome", "DomeRim", "DomeCap" } do
		local p = inc:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			parts[p] = p.CFrame
		end
	end
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local a = math.min((os.clock() - t0) / seconds, 1)
			local e = 1 - (1 - a) ^ 3
			for p, cf in parts do
				p.CFrame = cf + Vector3.new(0, dy * e, 0)
			end
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

-- 5) the lawyer rises out of the cradle as a silhouette (descend = drops in from above instead); returns (model,
-- bring-the-colours-back, stop, its height). height nil = its own size. Shared.Puppet poses it, so the moving bits of
-- the big lawyers (wings, tails, halos, orbiting planets) move here too.
local function riseLawyer(sp: Spot, skinId: string, height: number?, rarityName: string, descend: boolean?): (Model?, () -> (), () -> (), number)
	local m = makeCharacter(skinId)
	if not m then
		return nil, function() end, function() end, height or 4.6
	end
	local floorPos = cradle(sp).Position
	local stand = standLawyer(m, floorPos, height, sp.front)
	local _, size = m:GetBoundingBox()
	m.Parent = fxFolder
	local restore = silhouette(m)
	local pup = Puppet.new(m)
	local rise = HatchFx.spring(if descend then 1.6 else 2.4, 0.55, if descend then size.Y * 1.6 else -size.Y * 0.7)
	rise.target = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		local y = HatchFx.stepSpring(rise, dt)
		pup:apply(Puppet.emptyPose(), stand * CFrame.new(0, y, 0) * CFrame.Angles(0, math.sin(os.clock() * 0.6) * 0.3, 0))
	end)
	return m, function()
		restore()
		if rarityName ~= "Common" then
			pcall(Effects.aura, m, rarityName)
		end
	end, function()
		conn:Disconnect()
	end, size.Y
end

-- after a hatch: the incubator eases back, closes and rests
local function settleIncubator(inc: Model?)
	if not inc then
		return
	end
	task.spawn(function()
		Incubator.glow(inc, nil, 0.4)
		Incubator.blendTo(inc, "Close", 0, 0.35)
		Incubator.play(inc, "Close", 1.2)
		Incubator.rest(inc)
	end)
end

------------------------------------------------------------------ Mythic / Supreme: a cinematic on a stage of their own (v6, 2026-10-13)
-- (mr.robe: "extreme vfx ... unique animations when hatching"; the idea of cutting away to a scene for the rarest pulls
-- comes from games like Sol's RNG)
--   MYTHIC  "Crimson Arena": after the 3rd crack the floor splits with glowing crimson fissures, a red flash, and the egg
--           is on an obsidian disc under a blood moon - lava ring, fire braziers, embers. Two burning orbs circle and
--           collide in it, it blows apart in a crimson shockwave dome, "MYTHIC!" slams in, the lawyer rises out of fire.
--   SUPREME "Ascension": time stops (the colour drains), rainbow starlight streaks into the egg, the screen cracks white,
--           and the egg floats in a white-gold sanctum under a night of stars and rainbow auroras, rainbow pillars, a
--           giant halo. Six rainbow orbs spiral in, a slow-motion rainbow blast, "SUPREME!", "1 in N", and the lawyer
--           descends from the sky.
local STAGE_HEIGHT = 3000
local Lighting = game:GetService("Lighting")
local lightingSaved: { [string]: any }? = nil
local function setSky(kind: string?)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if kind then
		if not lightingSaved then
			lightingSaved = {
				ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, OutdoorAmbient = Lighting.OutdoorAmbient, Ambient = Lighting.Ambient,
				atm = if atm then { Density = atm.Density, Color = atm.Color, Decay = atm.Decay, Haze = atm.Haze, Glare = atm.Glare } else nil,
			}
		end
		if kind == "mythic" then
			Lighting.ClockTime = 18.3
			Lighting.OutdoorAmbient = Color3.fromRGB(130, 50, 50)
			Lighting.Ambient = Color3.fromRGB(80, 26, 30)
			if atm then
				atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = 0.4, Color3.fromRGB(220, 70, 60), Color3.fromRGB(120, 20, 30), 2.2, 0.6
			end
		else
			Lighting.ClockTime = 0
			Lighting.Brightness = 1.3
			Lighting.OutdoorAmbient = Color3.fromRGB(110, 100, 160)
			Lighting.Ambient = Color3.fromRGB(80, 70, 130)
			if atm then
				atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = 0.1, Color3.fromRGB(120, 110, 200), Color3.fromRGB(40, 30, 90), 0, 0
			end
		end
	elseif lightingSaved then
		local s = lightingSaved :: any
		Lighting.ClockTime, Lighting.Brightness, Lighting.OutdoorAmbient, Lighting.Ambient = s.ClockTime, s.Brightness, s.OutdoorAmbient, s.Ambient
		if atm and s.atm then
			atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = s.atm.Density, s.atm.Color, s.atm.Decay, s.atm.Haze, s.atm.Glare
		end
		lightingSaved = nil
	end
end

-- the big title ("MYTHIC!" / "SUPREME!") and the odds under it
local titleCardLabel = bigText("", UDim2.fromOffset(1000, 170), UDim2.fromScale(0.5, 0.36), WHITE, 9, 12)
local titleCardScale = Instance.new("UIScale")
titleCardScale.Parent = titleCardLabel
local titleCardGrad = Instance.new("UIGradient")
titleCardGrad.Enabled = false
titleCardGrad.Parent = titleCardLabel
local oddsCard = label(gui, "", UDim2.fromOffset(520, 44), UDim2.fromScale(0.5, 0.47), WHITE, 4)
oddsCard.ZIndex = 12
oddsCard.Visible = false
local function oddsText(result: { [string]: any }): string
	local c = result.chance
	if typeof(c) ~= "number" or c <= 0 then
		return ""
	end
	local n = math.floor(100 / c + 0.5)
	local s = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "1 in " .. s
end
local function titleCard(text: string, color: Color3, rainbow: boolean, odds: string)
	titleCardLabel.Text = text
	titleCardLabel.TextColor3 = if rainbow then WHITE else color
	titleCardGrad.Enabled = rainbow
	if rainbow then
		titleCardGrad.Color = HatchFx.RAINBOW
	end
	titleCardLabel.Visible = true
	titleCardScale.Scale = 3
	titleCardLabel.Rotation = -6
	tween(titleCardScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(titleCardLabel, 0.5, { Rotation = 0 }, Enum.EasingStyle.Elastic)
	oddsCard.Text = odds
	oddsCard.TextColor3 = if rainbow then Color3.fromRGB(255, 240, 200) else color:Lerp(WHITE, 0.4)
	oddsCard.Visible = odds ~= ""
	task.spawn(function()
		local t0 = os.clock()
		while titleCardLabel.Visible do
			local t = os.clock() - t0
			if rainbow then
				titleCardGrad.Offset = Vector2.new(math.sin(t * 1.5) * 0.5, 0)
			end
			titleCardScale.Scale = 1 + 0.03 * math.sin(t * 4)
			RunService.Heartbeat:Wait()
		end
	end)
end
local function hideTitleCard()
	titleCardLabel.Visible = false
	oddsCard.Visible = false
end

-- a white crack across the screen (the "breakthrough" hit before the Supreme scene)
local function screenCrack()
	local cam = workspace.CurrentCamera
	local vs = cam.ViewportSize
	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 11
	holder.Parent = gui
	local cx, cy = vs.X * 0.5, vs.Y * 0.45
	for i = 1, 11 do
		local ang = (i - 1) / 11 * math.pi * 2 + math.random() * 0.4
		local x, y = cx, cy
		for s = 1, 5 do
			ang += (math.random() - 0.5) * 0.6
			local len = vs.Y * (0.08 + math.random() * 0.08)
			local x2, y2 = x + math.cos(ang) * len, y + math.sin(ang) * len
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromOffset((x + x2) / 2, (y + y2) / 2)
			f.Size = UDim2.fromOffset(len + 2, math.max(2, 7 - s))
			f.Rotation = math.deg(math.atan2(y2 - y, x2 - x))
			f.BackgroundColor3 = WHITE
			f.BorderSizePixel = 0
			f.ZIndex = 11
			f.Parent = holder
			x, y = x2, y2
		end
	end
	task.delay(0.7, function()
		for _, f in holder:GetChildren() do
			tween(f, 0.3, { BackgroundTransparency = 1 })
		end
		task.wait(0.35)
		holder:Destroy()
	end)
end

-- the scene itself. `h` / `live`: the cracked egg, still at the incubator. Returns (lawyer model, stop, its height).
local function cinema(kind: string, sp: Spot, h: any, live: Live, tier: any, fxColor: any, rarityName: string, result: { [string]: any }, accent: Color3): (Model?, () -> (), number)
	local col = rgbOf(fxColor)
	local floorY = if sp.inc then sp.inc:GetPivot().Position.Y + 0.03 else cradle(sp).Position.Y
	-- 1) at the incubator: the floor splits (Mythic) / time stops and the stars pull in (Supreme)
	if kind == "mythic" then
		live.jitter = 0.22
		local c = cradle(sp).Position
		local fis = HatchFx.fissures(Vector3.new(c.X, floorY, c.Z), col, 9, 10, 1.0)
		HatchFx.shake(2.6, 18, 0.25, 0.3, 0.8)
		HatchFx.post({ cc = { TintColor = Color3.fromRGB(255, 165, 165), Contrast = 0.3 }, bloom = { Intensity = 0.8, Threshold = 1.25 } }, 0.6)
		hatchCue:Fire("beat", 4)
		task.wait(1.15)
		flash.BackgroundColor3 = Color3.fromRGB(200, 20, 30)
		tween(flash, 0.12, { BackgroundTransparency = 0 })
		task.wait(0.14)
		fis.stop(0)
	else
		stopLive(live, h, sp)
		HatchFx.clearShakes()
		HatchFx.post({ cc = { Saturation = -1, Contrast = 0.3 } }, 0.25)
		task.wait(0.4)
		local centre = h.shell.Position
		local imp = HatchFx.implode(centre, HatchFx.RAINBOW, 16, 300)
		local spinT = os.clock()
		local cracking = true
		task.spawn(function() -- the cracks run through the rainbow
			while cracking do
				local k = math.floor((os.clock() - spinT) * 8) % #HatchFx.RAINBOW_LIST + 1
				for _, cr in h.cracks do
					cr.Color = HatchFx.RAINBOW_LIST[k]
				end
				RunService.Heartbeat:Wait()
			end
		end)
		HatchFx.shake(1.2, 25, 1.2, 0.2)
		task.wait(1.5)
		cracking = false
		imp.stop()
		screenCrack()
		hatchCue:Fire("beat", 5)
		task.wait(0.5)
		flash.BackgroundColor3 = WHITE
		tween(flash, 0.12, { BackgroundTransparency = 0 })
		task.wait(0.14)
	end
	stopLive(live, h, sp)
	-- 2) the cut: the stage, far above the map; the egg floats over its centre
	local c0 = cradle(sp).Position
	local base = Vector3.new(c0.X, STAGE_HEIGHT, c0.Z)
	local origin = CFrame.lookAt(base, base + sp.front)
	local st = HatchFx.stage(kind, origin)
	setSky(kind)
	HatchFx.post({ cc = { Saturation = 0.15, Contrast = 0.12, TintColor = WHITE, Brightness = 0 }, dof = { FarIntensity = 0 }, bloom = { Intensity = 0.7, Threshold = 1.3 } }, 0)
	local stageSp: Spot = { inc = nil, front = sp.front, floor = origin * CFrame.new(0, 0.42, 0) }
	local lift = 2.2
	h.model:PivotTo(stageSp.floor * CFrame.new(0, HOVER + lift, 0))
	local spin = RunService.Heartbeat:Connect(st.spin)
	camSnap(shot(stageSp, 24, 9, 4))
	camTo(shot(stageSp, 13, 4.5, HOVER + lift + 1.4), 1.2)
	tween(flash, 0.7, { BackgroundTransparency = 1 })
	hatchCue:Fire("beat", 6)
	-- 3) build-up: the egg throbs; orbs circle and collide in it; god rays
	local liveStage = liveEgg({ inc = nil, front = sp.front, floor = stageSp.floor * CFrame.new(0, lift, 0) }, h)
	liveStage.jitter = 0.08
	for _, cr in h.cracks do
		cr.Transparency = 0
		cr.Color = col
	end
	local centre = (stageSp.floor * CFrame.new(0, HOVER + lift + HATCH_EGG * 0.5, 0)).Position
	local buildT = if kind == "mythic" then 2.4 else 3.0
	local rays = HatchFx.rays(centre, fxColor, if kind == "mythic" then 14 else 20, 16, buildT)
	local orbColors = if kind == "mythic" then { Color3.fromRGB(229, 57, 53), Color3.fromRGB(255, 140, 40) } else HatchFx.RAINBOW_LIST
	task.spawn(HatchFx.orbs, centre, orbColors, if kind == "mythic" then 8 else 11, buildT, 1.5)
	local ringT = task.spawn(function()
		for i = 1, 6 do
			HatchFx.ring(CFrame.new(centre - Vector3.new(0, HATCH_EGG * 0.5 + lift - 0.2, 0)), 6 + i, if kind == "mythic" then col else HatchFx.RAINBOW_LIST[i], 0.6)
			task.wait(buildT / 6)
		end
	end)
	HatchFx.shake(1.0, 22, buildT, 0.2)
	HatchFx.post({ cc = { Brightness = -0.1, Contrast = 0.25 } }, buildT)
	local t0 = os.clock()
	while os.clock() - t0 < buildT do
		local a = (os.clock() - t0) / buildT
		liveStage.jitter = 0.08 + a * 0.25
		liveStage.pulse.target = 1 + a * 0.12
		RunService.Heartbeat:Wait()
	end
	task.cancel(ringT)
	rays.stop(0.2)
	-- 4) the burst
	stopLive(liveStage, h, { inc = nil, front = sp.front, floor = stageSp.floor * CFrame.new(0, lift, 0) })
	hatchCue:Fire("burst", result.rarity or 1, rarityName)
	flash.BackgroundColor3 = accent:Lerp(WHITE, 0.6)
	flash.BackgroundTransparency = 0
	tween(flash, 0.9 + tier.slow, { BackgroundTransparency = 1 })
	HatchFx.post({ cc = { Brightness = 0.3 }, bloom = { Intensity = 1.2 } }, 0)
	HatchFx.post({ cc = { Brightness = 0, Contrast = 0.12 }, bloom = { Intensity = 0.7 } }, 1.2 + tier.slow)
	local floorCF = CFrame.new((stageSp.floor).Position)
	for r = 1, 7 do
		local c = if kind == "mythic" then (if r % 2 == 0 then Color3.fromRGB(255, 140, 40) else col) else HatchFx.RAINBOW_LIST[(r - 1) % 6 + 1]
		task.delay((r - 1) * 0.07, HatchFx.ring, floorCF * CFrame.new(0, 0.3 + r * 0.1, 0), 12 + r * 5, c, 0.8 + r * 0.08, 1.4 + r * 0.2)
	end
	HatchFx.dome(centre, if kind == "mythic" then 22 else 30, col, 1.1)
	HatchFx.sparks(centre, fxColor, 120, 50, 1.8)
	HatchFx.confetti(centre, tier.confetti * 2, 1.4)
	HatchFx.coins(centre, tier.coins * 2)
	pcall(Effects.burst, centre, tier.burst or "legendary", fxColor)
	HatchFx.light(centre, col, 40, 3, 2)
	HatchFx.shake(tier.shake + 1, 13, 0.01, 1.2)
	task.spawn(HatchFx.breakApart, h, tier.take, stageSp.floor * CFrame.new(0, HOVER + lift, 0), tier.slow + 0.3)
	task.wait(0.35)
	titleCard(if kind == "mythic" then "MYTHIC!" else "SUPREME!", col, kind == "supreme", oddsText(result))
	task.wait(0.6 + tier.slow * 0.6)
	-- 5) the lawyer, full size: out of a fire vortex (Mythic) / down from the sky in a beam (Supreme)
	if kind == "mythic" then
		local imp = HatchFx.implode(stageSp.floor.Position + Vector3.new(0, 3, 0), Effects.FIRE, 7, 160)
		task.delay(1.8, imp.stop)
	else
		HatchFx.pillar(stageSp.floor.Position, HatchFx.RAINBOW, 200, 9, 2.5)
	end
	local m, colour, stop, height = riseLawyer(stageSp, result.skinId, nil, rarityName, kind == "supreme")
	camTo(shot(stageSp, height * 1.55 + 6, height * 0.55, height * 0.42), 1.6)
	task.wait(1.1)
	hideTitleCard()
	colour()
	flash.BackgroundColor3 = WHITE
	flash.BackgroundTransparency = 0.15
	tween(flash, 0.5, { BackgroundTransparency = 1 })
	local mid = stageSp.floor.Position + Vector3.new(0, height * 0.5, 0)
	HatchFx.sparks(mid, fxColor, 60, 30, 1.4)
	pcall(Effects.burst, mid, tier.burst or "legendary", fxColor)
	HatchFx.dome(mid, 14, col, 0.8)
	HatchFx.shake(2, 12, 0.01, 0.5)
	return m, function()
		stop()
		spin:Disconnect()
	end, height
end
------------------------------------------------------------------ the owner's hatch
local hatchSpot: Spot? = nil
local disabledPrompts: { ProximityPrompt } = {}

local function playHatch(result: { [string]: any }, skin: any, rarityName: string, rarityColor: Color3, accent: Color3): () -> ()
	local tier = HatchFx.ladder(rarityName)
	local fxColor: any = if tier.rainbow then HatchFx.RAINBOW else rarityColor
	local eggId = (result.egg :: string?) or "Briefcase"
	local golden = result.golden == true
	local eggColor = EggLook.color(eggId, golden)
	local sp = findSpot(result.at)
	hatchSpot = sp
	-- (no second hatch at an incubator while this one plays)
	for _, m in CollectionService:GetTagged("Incubator") do
		local pr = m:FindFirstChild("IncubatorPrompt", true)
		if pr and pr:IsA("ProximityPrompt") and pr.Enabled then
			pr.Enabled = false
			table.insert(disabledPrompts, pr)
		end
	end
	hideForHatch()
	camBegin()
	HatchFx.postBegin()
	HatchFx.post({ cc = { Saturation = 0.12, Contrast = 0.06 }, dof = { FarIntensity = 0.35, FocusDistance = 11, InFocusRadius = 5 } }, 0.5)
	tween(vignette, 0.5, { BackgroundTransparency = 0.3 })
	local wide = shot(sp, 11.5, 4.6, 2.4)
	camTo(wide, 4)
	eggTitle.Text = eggNameOf(eggId, golden)
	eggTitle.TextColor3 = WHITE
	eggTitle.Visible = true
	-- 1) into the incubator
	local small = EggLook.build(eggId, golden, DISPLAY_EGG, true)
	small.Parent = fxFolder
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
	local from = if torso and torso:IsA("BasePart") then torso.CFrame * CFrame.new(0, 0, -1.4) else cradle(sp) * CFrame.new(0, 6, 7)
	flyIn(sp, small, from, true)
	-- 2) cook / overload
	local top = cookPhase(sp, small, tier, fxColor, true, function(p)
		camTo(CFrame.lookAt(wide.Position - Vector3.new(0, 1.5, 0), p), 10)
	end)
	-- 3) the egg you crack
	local h = EggLook.buildHatch(eggId, golden, HATCH_EGG)
	if not h then
		small:Destroy()
		return function() end
	end
	h.model.Parent = fxFolder
	if top then
		small:Destroy()
		crashDown(sp, h, top, tier, fxColor, true, function(p)
			camTo(CFrame.lookAt(wide.Position, p:Lerp(cradle(sp).Position + Vector3.new(0, 2, 0), 0.5)), 12)
		end)
	else
		riseAndGrow(sp, small, h)
	end
	camTo(shot(sp, 8.6, 4.2, HOVER + HATCH_EGG * 0.55), 4)
	local live = liveEgg(sp, h)
	crackRounds(function(i)
		crack(h, live, i, fxColor, eggColor, true)
	end)
	eggTitle.Visible = false
	local m: Model?, stop: () -> (), height: number = nil, function() end, 4.6
	if tier.cinema then
		-- Mythic / Supreme: their own stage (cinema above)
		m, stop, height = cinema(tier.cinema, sp, h, live, tier, fxColor, rarityName, result, accent)
	else
		-- 4) build-up + burst
		camTo(shot(sp, 7.2, 3.9, HOVER + HATCH_EGG * 0.5), 2.5)
		local endBuild = buildUp(h, live, tier, fxColor, true)
		stopLive(live, h, sp)
		endBuild()
		hatchCue:Fire("burst", result.rarity or 1, rarityName)
		flash.BackgroundColor3 = accent:Lerp(WHITE, 0.6)
		flash.BackgroundTransparency = 0.05
		tween(flash, 0.6 + tier.slow, { BackgroundTransparency = 1 })
		HatchFx.post({ cc = { Brightness = 0.25 }, bloom = { Intensity = 0.5 + tier.bloom * 0.4 } }, 0)
		HatchFx.post({ cc = { Brightness = 0, Contrast = 0.08, TintColor = WHITE }, bloom = HatchFx.postBloomBase() }, 0.9 + tier.slow)
		burst(sp, h, tier, fxColor, true)
		liftDome(sp.inc, 4, 0.6)
		camTo(shot(sp, if tier.fancy then 12.5 else 10.5, 4.4, 2.6), if tier.slow > 0 then 1.5 else 3)
		task.wait(0.25 + tier.slow * 0.6)
		-- 5) the lawyer
		height = if tier.fancy then 5.4 else 4.6
		local colour
		m, colour, stop = riseLawyer(sp, result.skinId, height, rarityName)
		camTo(shot(sp, if tier.fancy then 11 else 9.2, 3.6, height * 0.28), 3)
		task.wait(0.9)
		colour()
		flash.BackgroundColor3 = WHITE
		flash.BackgroundTransparency = 0.2
		tween(flash, 0.45, { BackgroundTransparency = 1 })
		if m then
			local mid = cradle(sp).Position + Vector3.new(0, height * 0.5, 0)
			HatchFx.sparks(mid, fxColor, 24, 20)
			if tier.fancy then
				pcall(Effects.burst, mid, "legendary", fxColor)
				HatchFx.shake(1.5, 12, 0.01, 0.4)
			end
		end
	end
	topName.Text = skin.Name
	topName.TextColor3 = WHITE
	topName.Visible = true
	topSub.Text = chanceText(result, rarityName)
	topSub.TextColor3 = rarityColor
	topSub.Visible = true
	continueLabel.Visible = true
	task.wait(0.3)
	waitTap(14)
	continueLabel.Visible = false
	topName.Visible = false
	topSub.Visible = false
	return stop
end

local function hatchCleanup()
	camEnd()
	showAfterHatch()
	setSky(nil)
	hideTitleCard()
	HatchFx.postEnd(0.35)
	tween(vignette, 0.3, { BackgroundTransparency = 1 })
	fxFolder:ClearAllChildren()
	for _, pr in disabledPrompts do
		pr.Enabled = true
	end
	table.clear(disabledPrompts)
	if hatchSpot then
		settleIncubator(hatchSpot.inc)
		hatchSpot = nil
	end
end

------------------------------------------------------------------ the server-wide banner for a Mythic / Supreme (v6, 2026-10-13)
-- Eggs.EggServer fires Remotes.HatchAnnounce to everyone when someone hatches a Mythic or Supreme: a banner slides
-- down from the top ("mr_blox174 hatched a SUPREME Celestial!", the odds under it; rainbow for Supreme).
local HatchAnnounce = Remotes:WaitForChild("HatchAnnounce", 15) :: RemoteEvent?
local bannerGui = Instance.new("ScreenGui")
bannerGui.Name = "HatchBanner"
bannerGui.ResetOnSpawn = false
bannerGui.IgnoreGuiInset = true
bannerGui.DisplayOrder = 30
bannerGui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, -140)
banner.Size = UDim2.fromOffset(760, 104)
banner.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
banner.BackgroundTransparency = 0.12
banner.Parent = bannerGui
corner(banner, 0.25)
local bannerStroke = Instance.new("UIStroke")
bannerStroke.Thickness = 5
bannerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bannerStroke.Parent = banner
local bannerStrokeGrad = Instance.new("UIGradient")
bannerStrokeGrad.Parent = bannerStroke
local bannerText = label(banner, "", UDim2.new(1, -30, 0, 54), UDim2.new(0.5, 0, 0, 34), WHITE, 4)
bannerText.Font = UIFonts.Title
local bannerTextGrad = Instance.new("UIGradient")
bannerTextGrad.Parent = bannerText
local bannerOdds = label(banner, "", UDim2.new(1, -30, 0, 28), UDim2.new(0.5, 0, 0, 80), Color3.fromRGB(255, 240, 200), 3)
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner
local bannerQueue: { any } = {}
local bannerBusy = false
local function showBanner(info: any)
	table.insert(bannerQueue, info)
	if bannerBusy then
		return
	end
	bannerBusy = true
	while #bannerQueue > 0 do
		local i = table.remove(bannerQueue, 1)
		local rarityName, rarityColor = rarityInfo(i.rarity or 1)
		local supreme = rarityName == "Supreme"
		bannerText.Text = string.format("%s hatched a %s %s!", tostring(i.name or "Someone"), string.upper(rarityName), tostring(i.lawyer or "lawyer"))
		bannerText.TextColor3 = if supreme then WHITE else rarityColor
		bannerTextGrad.Enabled = supreme
		bannerTextGrad.Color = HatchFx.RAINBOW
		bannerStrokeGrad.Color = if supreme then HatchFx.RAINBOW else ColorSequence.new(rarityColor)
		bannerOdds.Text = oddsText(i)
		bannerScale.Scale = math.clamp(workspace.CurrentCamera.ViewportSize.X / 900, 0.55, 1)
		tween(banner, 0.45, { Position = UDim2.new(0.5, 0, 0, 18) }, Enum.EasingStyle.Back)
		hatchCue:Fire("burst", i.rarity or 1, rarityName)
		local t0 = os.clock()
		while os.clock() - t0 < 4.6 do
			local t = os.clock() - t0
			bannerTextGrad.Offset = Vector2.new(math.sin(t * 1.4) * 0.5, 0)
			bannerStrokeGrad.Rotation = (t * 90) % 360
			RunService.Heartbeat:Wait()
		end
		tween(banner, 0.35, { Position = UDim2.new(0.5, 0, 0, -140) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.4)
	end
	bannerBusy = false
end
if HatchAnnounce then
	HatchAnnounce.OnClientEvent:Connect(function(info)
		if typeof(info) == "table" and info.userId ~= player.UserId then
			task.spawn(showBanner, info)
		end
	end)
end
------------------------------------------------------------------ everyone else's view (no camera, no words)
local showing: { [Model]: boolean } = {}
local function playShow(info: { [string]: any })
	if typeof(info.at) ~= "Vector3" then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - info.at).Magnitude > 160 then
		return
	end
	local inc = Incubator.find(info.at, 14)
	if not inc or not Incubator.isV5(inc) or showing[inc] or (hatchSpot and hatchSpot.inc == inc) then
		return
	end
	showing[inc] = true
	local ok, err = pcall(function()
		local rarityName, rarityColor = rarityInfo(info.rarity or 1)
		local tier = HatchFx.ladder(rarityName)
		local fxColor: any = if tier.rainbow then HatchFx.RAINBOW else rarityColor
		local sp: Spot = { inc = inc, front = Incubator.front(inc), floor = Incubator.eggSpot(inc) }
		local eggId = info.egg or "Briefcase"
		local golden = info.golden == true
		local small = EggLook.build(eggId, golden, DISPLAY_EGG, true)
		small.Parent = fxFolder
		small:PivotTo(cradle(sp))
		local top = cookPhase(sp, small, tier, fxColor, false, nil)
		local h = EggLook.buildHatch(eggId, golden, HATCH_EGG)
		if not h then
			small:Destroy()
			return
		end
		h.model.Parent = fxFolder
		if top then
			small:Destroy()
			crashDown(sp, h, top, tier, fxColor, false, nil)
		else
			riseAndGrow(sp, small, h)
		end
		local live = liveEgg(sp, h)
		for i = 1, 3 do
			task.wait(0.5)
			crack(h, live, i, fxColor, EggLook.color(eggId, golden), false)
		end
		local endBuild = buildUp(h, live, tier, fxColor, false)
		stopLive(live, h, sp)
		endBuild()
		burst(sp, h, tier, fxColor, false)
		liftDome(sp.inc, 4, 0.6)
		task.wait(0.3 + tier.slow * 0.6)
		local m, colour, stop = riseLawyer(sp, info.skinId or "", if tier.fancy then 5.4 else 4.6, rarityName)
		task.wait(0.9)
		colour()
		task.wait(2.5)
		stop()
		if m then
			m:Destroy()
		end
		if h.model.Parent then
			h.model:Destroy()
		end
	end)
	if not ok then
		warn("[Eggs] hatch show:", err)
	end
	settleIncubator(inc)
	task.delay(1.8, function()
		showing[inc] = nil
	end)
end
if HatchShow then
	HatchShow.OnClientEvent:Connect(function(info)
		if typeof(info) == "table" and info.userId ~= player.UserId then
			task.spawn(playShow, info)
		end
	end)
end

------------------------------------------------------------------ open / close
local finish: (() -> ())? = nil

local function close()
	tween(revealScale, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	for _, o in { stageBg, dim, floorBand } do
		tween(o, 0.25, { BackgroundTransparency = 1 })
	end
	for _, r in rings do
		tween(r, 0.25, { BackgroundTransparency = 1 })
	end
	tween(stageGlow, 0.25, { ImageTransparency = 1 })
	task.wait(0.25)
	if finish then
		finish()
		finish = nil
	end
	gui.Enabled = false
	reveal.Visible = false
	eggView.Visible = false
	nameShimmer.Enabled = false
	hatchCleanup()
	current = nil
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
	gui.Enabled = true
	toast.Visible = false
	reveal.Visible = false
	flash.BackgroundTransparency = 1
	stageBg.BackgroundTransparency = 1
	vignette.BackgroundTransparency = 1
	stageGlow.ImageTransparency = 1
	stageShaft.ImageTransparency = 1
	floorBand.BackgroundTransparency = 1
	for _, r in rings do
		r.BackgroundTransparency = 1
	end
	local accent = if rarityName == "Common" then Color3.fromRGB(235, 235, 245) else rarityColor
	local ok, err = pcall(function()
		finish = playHatch(result, skin, rarityName, rarityColor, accent)
	end)
	if not ok then
		warn("[Eggs] hatch animation:", err) -- (the lawyer is hatched anyway: show the panel)
	end
	-- the reveal panel: name, rarity, earnings + skills, PLACE / KEEP
	nameLabel.Text = skin.Name
	nameShimmer.Enabled = SHIMMERS[rarityName] ~= nil
	if SHIMMERS[rarityName] then
		nameShimmer.Color = SHIMMERS[rarityName]
	end
	pill.BackgroundColor3 = rarityColor
	pillText.Text = string.upper(rarityName)
	local skillNames = {}
	for _, s in result.skills or {} do
		local sdef = Formulas.getSkillDef(s.Id)
		if sdef then
			table.insert(skillNames, sdef.Name)
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
	if current == nil then
		return
	end
	revealScale.Scale = fit()
	reveal.Visible = true
	revealText({ equipButton, niceButton })
	-- (Legendary+: the name sweeps)
	task.spawn(function()
		local t0 = os.clock()
		while reveal.Visible and nameShimmer.Enabled do
			nameShimmer.Offset = Vector2.new((((os.clock() - t0) * 0.5) % 1.6) - 0.8, 0)
			RunService.Heartbeat:Wait()
		end
	end)
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
			elseif result.reason == "locked" then
				local def = Formulas.themedEgg(result.egg)
				local earned = (player:GetAttribute("CoinsEarned") :: number?) or 0
				local need = (result.need or (def and def.UnlockEarned) or 0) - earned
				showToast("Earn " .. Formulas.formatCoins(math.max(need, 0)) .. " more coins to unlock!") -- short: one scaled line
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
