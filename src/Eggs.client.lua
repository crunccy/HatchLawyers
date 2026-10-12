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
-- The hatch, v4 (2026-10-12, mr.robe's session; user: "supreme, mythic and legendary hatches should look like the
-- more complicated animation while the other ones can look like the basic animation" - from their reference video).
-- Both kinds:
--   the egg (Shared.EggLook: the same detailed egg as in the zones) -> "Tap to crack!" x3 ("Again!", "One more!":
--   every tap swells, shakes and brightens it; it cracks by itself after a few seconds) -> it bursts into cube
--   shards -> the lawyer appears as a black SILHOUETTE in the rarity's light -> colour: its name + "RARITY · x%
--   chance" -> "Tap to continue" -> its earnings / skills and the PLACE / KEEP buttons.
-- BASIC (Common .. Epic): a full-screen 3D stage - a radial backdrop in the egg's colour, the egg's name across the
--   top, the egg bouncing onto a glowing round pedestal.
-- FANCY (Legendary, Mythic, Supreme), when the server says where it hatched (result.at = the incubator): in the
--   world - the camera looks up into the sky, the egg falls onto the incubator with an impact, it's cracked right
--   there and the lawyer appears there, big. Everyone else nearby sees a shorter version (Remotes.HatchShow).
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
local function standLawyer(m: Model, floor: Vector3, height: number, facing: Vector3): CFrame
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * height / math.max(size.Y, 0.1))
	local box, size2 = m:GetBoundingBox()
	local pivotAboveFeet = m:GetPivot().Position.Y - (box.Position.Y - size2.Y / 2)
	local look = Vector3.new(facing.X, 0, facing.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, 1)
	-- (lawyers face -Z: turn the model's -Z to `look`)
	local cf = CFrame.lookAt(floor + Vector3.new(0, pivotAboveFeet, 0), floor + Vector3.new(0, pivotAboveFeet, 0) + look)
	m:PivotTo(cf)
	return cf
end

------------------------------------------------------------------ the egg: an actor we can squash, shake and brighten
type Actor = { model: Model, colors: { [BasePart]: Color3 }, base: number }
local function newActor(egg: string, golden: boolean, height: number, parent: Instance): Actor
	local m = EggLook.build(egg, golden, height)
	local colors = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			colors[p] = p.Color
			p.CanQuery = false
		end
	end
	m.Parent = parent
	return { model = m, colors = colors, base = m:GetScale() }
end
-- place it (pivot = the middle of its bottom), swollen by `swell`, brightened by `bright` (0..1)
local function actorSet(a: Actor, cf: CFrame, swell: number, bright: number?)
	if math.abs(a.model:GetScale() - a.base * swell) > 1e-3 then
		a.model:ScaleTo(a.base * swell)
	end
	a.model:PivotTo(cf)
	if bright then
		for p, c in a.colors do
			p.Color = c:Lerp(WHITE, bright)
		end
	end
end

-- cube shards bursting out of `centre` (moved by hand: works in a ViewportFrame and in the world alike)
local function shards(parent: Instance, centre: Vector3, colors: { Color3 }, size: number, count: number, speed: number)
	local bits = {}
	for i = 1, count do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		local s = size * (0.5 + math.random() * 0.8)
		p.Size = Vector3.new(s, s, s)
		p.Color = colors[(i - 1) % #colors + 1]
		p.CFrame = CFrame.new(centre)
		p.Parent = parent
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9 + 0.1, math.random() - 0.5)
		dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.yAxis
		table.insert(bits, { part = p, vel = dir * speed * (0.6 + math.random() * 0.7), spin = Vector3.new(math.random(), math.random(), math.random()) * 8 })
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 1.3 do
			local t = os.clock() - t0
			for _, b in bits do
				local pos = centre + b.vel * t + Vector3.new(0, -speed * 1.6 * t * t, 0)
				b.part.CFrame = CFrame.new(pos) * CFrame.Angles(b.spin.X * t, b.spin.Y * t, b.spin.Z * t)
				b.part.Transparency = math.clamp((t - 0.7) / 0.6, 0, 1)
			end
			RunService.Heartbeat:Wait()
		end
		for _, b in bits do
			b.part:Destroy()
		end
	end)
end

local function eggColors(a: Actor): { Color3 }
	local list = {}
	for p, c in a.colors do
		if p.Size.Magnitude > 1 then
			table.insert(list, c)
		end
	end
	if #list == 0 then
		table.insert(list, WHITE)
	end
	return list
end

local function chanceText(result: { [string]: any }, rarityName: string): string
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

------------------------------------------------------------------ BASIC: the 3D stage
local stageParts: { Instance } = {}
local function clearStage()
	for _, o in stageParts do
		o:Destroy()
	end
	stageParts = {}
end
local function stagePart(size: Vector3, cf: CFrame, color: Color3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Shape = Enum.PartType.Cylinder
	p.Size = size
	p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Parent = eggView
	table.insert(stageParts, p)
	return p
end

local function playBasic(result: { [string]: any }, skin: any, rarityName: string, rarityColor: Color3, accent: Color3)
	local eggId = (result.egg :: string?) or "Briefcase"
	local golden = result.golden == true
	local eggCol = EggLook.color(eggId, golden)
	local def = Formulas.themedEgg(eggId)
	local eggName = (if def then def.Name else "Briefcase Egg")
	-- the backdrop: rings in the egg's colour, a floor band, the egg's name
	stageBg.BackgroundTransparency = 0
	stageGrad.Color = ColorSequence.new(eggCol:Lerp(BLACK, 0.35), eggCol:Lerp(BLACK, 0.55))
	for i, r in rings do
		local s = 0.42 + (i - 1) * 0.3
		r.Size = UDim2.fromScale(s * 0.75, s * 0.75)
		r.SizeConstraint = Enum.SizeConstraint.RelativeYY
		r.BackgroundColor3 = eggCol:Lerp(WHITE, 0.3 - i * 0.06):Lerp(BLACK, (i - 1) * 0.12)
		r.BackgroundTransparency = 0
	end
	floorBand.BackgroundColor3 = eggCol:Lerp(Color3.fromRGB(20, 60, 80), 0.6)
	floorBand.BackgroundTransparency = 0
	eggTitle.Text = string.upper((if golden then "Golden " else "") .. eggName)
	eggTitle.TextColor3 = WHITE
	eggTitle.Visible = true
	-- the pedestal: a white top, a glowing rim, a gold base
	clearStage()
	stagePart(Vector3.new(0.7, 7.2, 7.2), CFrame.new(0, -0.35, 0), Color3.fromRGB(245, 245, 255))
	local rim = stagePart(Vector3.new(0.4, 7.7, 7.7), CFrame.new(0, -0.75, 0), Color3.fromRGB(110, 230, 255), true)
	stagePart(Vector3.new(0.7, 8.4, 8.4), CFrame.new(0, -1.2, 0), Color3.fromRGB(255, 205, 60))
	eggView.Ambient = EGG_AMBIENT
	eggView.LightColor = EGG_LIGHT
	eggView.LightDirection = Vector3.new(-0.5, -1, -0.7)
	eggCam.FieldOfView = 34
	local camHome = CFrame.lookAt(Vector3.new(0, 4.2, 19), Vector3.new(0, 2.3, 0))
	eggCam.CFrame = camHome
	eggView.Visible = true
	-- the egg drops in and bounces
	local a = newActor(eggId, golden, 3.8, eggView)
	table.insert(stageParts, a.model)
	local swell, bright, shakeUntil, punch = 1, 0, 0, 0
	local alive = true
	local y = 12
	local t0 = os.clock()
	local driver = RunService.Heartbeat:Connect(function()
		if not alive then
			return
		end
		local t = os.clock() - t0
		local jitter = if os.clock() < shakeUntil then CFrame.Angles((math.random() - 0.5) * 0.25, 0, (math.random() - 0.5) * 0.25) else CFrame.new()
		actorSet(a, CFrame.new(0, y, 0) * CFrame.Angles(0, math.sin(t * 1.3) * 0.35, 0) * jitter, swell, bright)
		rim.Transparency = 0.15 + 0.15 * math.sin(t * 3)
		for i, r in rings do
			local s = (0.42 + (i - 1) * 0.3) * (1 + 0.02 * math.sin(t * 2 + i))
			r.Size = UDim2.fromScale(s * 0.75, s * 0.75)
		end
		eggCam.CFrame = camHome * CFrame.new(0, 0, -punch * 2.5)
		punch = math.max(0, punch - 0.08)
	end)
	local dropStart = os.clock()
	while os.clock() - dropStart < 0.7 do
		local x = (os.clock() - dropStart) / 0.7
		-- a fall with two little bounces
		y = if x < 0.6 then 12 * (1 - (x / 0.6) ^ 2) elseif x < 0.85 then 1.2 * math.sin((x - 0.6) / 0.25 * math.pi) else 0.4 * math.sin((x - 0.85) / 0.15 * math.pi)
		RunService.Heartbeat:Wait()
	end
	y = 0
	-- 3 cracks
	crackRounds(function(i)
		swell = 1 + i * 0.07
		bright = i * 0.18
		shakeUntil = os.clock() + 0.3 + i * 0.08
		punch = 1
	end)
	-- burst
	alive = false
	driver:Disconnect()
	local centre = Vector3.new(0, 1.9 * swell, 0)
	shards(eggView, centre, eggColors(a), 0.55, 40, 16)
	a.model:Destroy()
	hatchCue:Fire("burst", result.rarity or 1, rarityName)
	flash.BackgroundColor3 = accent:Lerp(WHITE, 0.6)
	flash.BackgroundTransparency = 0.1
	tween(flash, 0.6, { BackgroundTransparency = 1 })
	eggTitle.Visible = false
	-- the silhouette, in the rarity's light
	local m = makeCharacter(result.skinId)
	local restore: (() -> ())? = nil
	local turn: RBXScriptConnection? = nil
	if m then
		local stand = standLawyer(m, Vector3.new(0, 0, 0), 4.6, Vector3.new(0, 0, 1))
		m.Parent = eggView
		table.insert(stageParts, m)
		restore = silhouette(m)
		eggView.Ambient = accent:Lerp(BLACK, 0.4)
		stageGrad.Color = ColorSequence.new(accent:Lerp(BLACK, 0.2), accent:Lerp(BLACK, 0.55))
		for i, r in rings do
			r.BackgroundColor3 = accent:Lerp(WHITE, 0.25 - i * 0.05):Lerp(BLACK, (i - 1) * 0.12)
		end
		local camTo = CFrame.lookAt(Vector3.new(0, 3.4, 15), Vector3.new(0, 2.4, 0))
		local tr = os.clock()
		turn = RunService.Heartbeat:Connect(function()
			local u = os.clock() - tr
			local rise = easeOut(u / 0.5, 3)
			m:PivotTo(stand * CFrame.new(0, -1.2 * (1 - rise), 0) * CFrame.Angles(0, math.sin(u * 0.7) * 0.35, 0))
			eggCam.CFrame = camHome:Lerp(camTo, easeOut(u / 0.8, 3))
		end)
		task.wait(0.9)
		-- colour!
		if restore then
			restore()
		end
		eggView.Ambient = accent:Lerp(EGG_AMBIENT, 0.6)
		flash.BackgroundColor3 = WHITE
		flash.BackgroundTransparency = 0.2
		tween(flash, 0.45, { BackgroundTransparency = 1 })
	end
	topName.Text = skin.Name
	topName.TextColor3 = WHITE
	topName.Visible = true
	topSub.Text = chanceText(result, rarityName)
	topSub.TextColor3 = rarityColor
	topSub.Visible = true
	continueLabel.Visible = true
	task.wait(0.3)
	waitTap(12)
	continueLabel.Visible = false
	topName.Visible = false
	topSub.Visible = false
	return function()
		if turn then
			turn:Disconnect()
		end
	end
end

------------------------------------------------------------------ FANCY: in the world, at the incubator
local fxFolder = Instance.new("Folder")
fxFolder.Name = "HatchFx"
fxFolder.Parent = workspace

local function ring(at: Vector3, radius: number, color: Color3, seconds: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(0.3, 1, 1)
	p.Parent = fxFolder
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < seconds do
			local a = (os.clock() - t0) / seconds
			local r = 1 + radius * easeOut(a, 2)
			p.Size = Vector3.new(0.3, r * 2, r * 2)
			p.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			p.Transparency = a
			RunService.Heartbeat:Wait()
		end
		p:Destroy()
	end)
end

local function aura(m: Model, color: Color3): Instance?
	local box = m:GetBoundingBox()
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = box
	holder.Parent = fxFolder
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 22
	light.Brightness = 3
	light.Parent = holder
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color, WHITE)
	e.LightEmission = 0.3
	e.Rate = 40
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = holder
	return holder
end

-- where the egg lands: the top of whatever is under `at` (the incubator)
local function landingSpot(at: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { fxFolder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), params)
	return if hit then hit.Position else at - Vector3.new(0, 5, 0)
end

-- the egg falls from the sky onto `land` (1.2 s), with a landing ring; `onFrame(y)` per frame
local FALL = 1.2
local function fall(a: Actor, land: Vector3, onFrame: ((pos: Vector3) -> ())?)
	local t0 = os.clock()
	while true do
		local x = math.min((os.clock() - t0) / FALL, 1)
		local h = 90 * (1 - x * x)
		local pos = land + Vector3.new(0, h, 0)
		actorSet(a, CFrame.new(pos) * CFrame.Angles(0, x * 6, 0), 1)
		if onFrame then
			onFrame(pos)
		end
		if x >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

local fancyCamera: { type: Enum.CameraType, subject: Instance? }? = nil

local function playFancy(result: { [string]: any }, skin: any, rarityName: string, rarityColor: Color3, accent: Color3)
	local eggId = (result.egg :: string?) or "Briefcase"
	local golden = result.golden == true
	local land = landingSpot(result.at)
	local cam = workspace.CurrentCamera
	fancyCamera = { type = cam.CameraType, subject = cam.CameraSubject }
	cam.CameraType = Enum.CameraType.Scriptable
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local side = if root then Vector3.new(root.Position.X - land.X, 0, root.Position.Z - land.Z) else Vector3.new(0, 0, 1)
	side = if side.Magnitude > 1 then side.Unit else Vector3.new(0, 0, 1)
	local eye = land + side * 22 + Vector3.new(0, 5, 0)
	local close = land + side * 13 + Vector3.new(0, 5, 0)
	-- 1) the sky: the title, the camera looking up, the egg a dot high above, then it falls and the camera follows
	dim.BackgroundTransparency = 1
	eggTitle.Text = string.upper(rarityName) .. " EGG"
	eggTitle.TextColor3 = rarityColor
	eggTitle.Visible = true
	local a = newActor(eggId, golden, 5.2, fxFolder)
	actorSet(a, CFrame.new(land + Vector3.new(0, 90, 0)), 1)
	cam.CFrame = CFrame.lookAt(eye, land + Vector3.new(0, 90, 0))
	task.wait(0.6)
	fall(a, land, function(pos)
		cam.CFrame = CFrame.lookAt(eye, pos + Vector3.new(0, 2.6, 0))
	end)
	-- 2) the impact
	ring(land, 18, rarityColor, 0.6)
	ring(land, 11, WHITE, 0.4)
	hatchCue:Fire("beat", 0)
	local shakeEnd = os.clock() + 0.45
	while os.clock() < shakeEnd do
		cam.CFrame = CFrame.lookAt(eye, land + Vector3.new(0, 2.6, 0)) * CFrame.new((math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8, 0)
		RunService.Heartbeat:Wait()
	end
	-- 3) the camera moves in; 3 cracks
	local from, t0 = cam.CFrame, os.clock()
	while os.clock() - t0 < 0.5 do
		cam.CFrame = from:Lerp(CFrame.lookAt(close, land + Vector3.new(0, 2.8, 0)), easeOut((os.clock() - t0) / 0.5, 3))
		RunService.Heartbeat:Wait()
	end
	local camHome = CFrame.lookAt(close, land + Vector3.new(0, 2.8, 0))
	local swell, bright, shakeUntil, punch = 1, 0, 0, 0
	local alive = true
	local tb = os.clock()
	local driver = RunService.Heartbeat:Connect(function()
		if not alive then
			return
		end
		local t = os.clock() - tb
		local jitter = if os.clock() < shakeUntil then CFrame.Angles((math.random() - 0.5) * 0.3, 0, (math.random() - 0.5) * 0.3) else CFrame.new()
		actorSet(a, CFrame.new(land) * CFrame.Angles(0, math.sin(t * 1.3) * 0.3, 0) * jitter, swell, bright)
		cam.CFrame = camHome * CFrame.new(0, 0, -punch * 2)
		punch = math.max(0, punch - 0.08)
	end)
	crackRounds(function(i)
		swell = 1 + i * 0.08
		bright = i * 0.2
		shakeUntil = os.clock() + 0.35 + i * 0.1
		punch = 1
	end)
	-- 4) burst
	alive = false
	driver:Disconnect()
	local centre = land + Vector3.new(0, 2.6 * swell, 0)
	shards(fxFolder, centre, eggColors(a), 0.8, 46, 22)
	a.model:Destroy()
	pcall(Effects.burst, centre, "legendary", rarityColor)
	ring(land, 24, rarityColor, 0.7)
	hatchCue:Fire("burst", result.rarity or 1, rarityName)
	flash.BackgroundColor3 = accent:Lerp(WHITE, 0.6)
	flash.BackgroundTransparency = 0.05
	tween(flash, 0.7, { BackgroundTransparency = 1 })
	eggTitle.Visible = false
	-- 5) the silhouette, big, in an aura of the rarity's colour; then colour
	local m = makeCharacter(result.skinId)
	local turn: RBXScriptConnection? = nil
	if m then
		local stand = standLawyer(m, land, 8.5, side)
		m.Parent = fxFolder
		local restore = silhouette(m)
		aura(m, rarityColor)
		local camTo = CFrame.lookAt(land + side * 17 + Vector3.new(0, 5.5, 0), land + Vector3.new(0, 4.5, 0))
		local tr = os.clock()
		turn = RunService.Heartbeat:Connect(function()
			local u = os.clock() - tr
			local rise = easeOut(u / 0.6, 3)
			m:PivotTo(stand * CFrame.new(0, -2.5 * (1 - rise), 0) * CFrame.Angles(0, math.sin(u * 0.6) * 0.3, 0))
			cam.CFrame = camHome:Lerp(camTo, easeOut(u / 0.9, 3))
		end)
		task.wait(1.1)
		restore()
		flash.BackgroundColor3 = WHITE
		flash.BackgroundTransparency = 0.15
		tween(flash, 0.5, { BackgroundTransparency = 1 })
		pcall(Effects.burst, land + Vector3.new(0, 4, 0), "legendary", rarityColor)
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
	tween(dim, 0.3, { BackgroundTransparency = 0.45 })
	return function()
		if turn then
			turn:Disconnect()
		end
	end
end

-- Everyone else's view of a fancy hatch nearby: the egg falls onto that incubator, shakes three times, bursts, and
-- the lawyer appears (silhouette, then colour) for a moment. No camera moves, no words.
local function playShow(info: { [string]: any })
	if typeof(info.at) ~= "Vector3" then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - info.at).Magnitude > 220 then
		return
	end
	local _, rarityColor = rarityInfo(info.rarity or 1)
	local land = landingSpot(info.at)
	local a = newActor(info.egg or "Briefcase", info.golden == true, 5.2, fxFolder)
	fall(a, land, nil)
	ring(land, 18, rarityColor, 0.6)
	for i = 1, 3 do
		local t0 = os.clock()
		while os.clock() - t0 < 0.55 do
			local jitter = if os.clock() - t0 < 0.3 then CFrame.Angles((math.random() - 0.5) * 0.3, 0, (math.random() - 0.5) * 0.3) else CFrame.new()
			actorSet(a, CFrame.new(land) * jitter, 1 + i * 0.08, i * 0.2)
			RunService.Heartbeat:Wait()
		end
	end
	local centre = land + Vector3.new(0, 2.8, 0)
	shards(fxFolder, centre, eggColors(a), 0.8, 30, 22)
	a.model:Destroy()
	pcall(Effects.burst, centre, "legendary", rarityColor)
	local m = makeCharacter(info.skinId or "")
	if m then
		local look = Vector3.new(root.Position.X - land.X, 0, root.Position.Z - land.Z)
		standLawyer(m, land, 8.5, look)
		m.Parent = fxFolder
		local restore = silhouette(m)
		local glow = aura(m, rarityColor)
		task.wait(1)
		restore()
		task.wait(2.5)
		m:Destroy()
		if glow then
			glow:Destroy()
		end
	end
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
	for _, o in { stageBg, vignette, dim, floorBand } do
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
	clearStage()
	fxFolder:ClearAllChildren()
	if fancyCamera then
		local cam = workspace.CurrentCamera
		cam.CameraType = fancyCamera.type
		if fancyCamera.subject then
			cam.CameraSubject = fancyCamera.subject
		end
		fancyCamera = nil
	end
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
		if FANCY[rarityName] and typeof(result.at) == "Vector3" then
			finish = playFancy(result, skin, rarityName, rarityColor, accent)
		else
			finish = playBasic(result, skin, rarityName, rarityColor, accent)
		end
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
