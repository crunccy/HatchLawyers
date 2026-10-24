--!strict
-- Travel (StarterPlayerScripts.Travel; 2026-10-13, crnuch's cloud session - written blind, playtest it). The zone
-- travel map, user's pick "A": walk into the Travel Portal at the hub (Workspace.Hub.TravelPortal, from Blender:
-- tools/blender/travel_portal.py) or press the TRAVEL tile, pick a zone (or HOME) and go. Shows, never decides:
-- ServerScriptService.TravelServer checks the license, the eggs you carry and the cooldown (Remotes.Travel).
--   * the map: the six zones as cards in lane order + HOME. Open = the zone's colour + GO; locked = grey with a
--     padlock and the license it needs; "HERE" on the zone you're in. Carrying eggs: every GO is greyed and a strip
--     says to walk them home (Config.Zones.Travel.BlockWhileCarrying).
--   * the trip: the screen closes in a circle of the destination's colour, you move, it opens again.
--   * the portal: its spiral arms spin, particles from Shared.Effects.ambient on the portal face, and its six gems
--     light up for the zones you can travel to (this player's own view).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local TravelFx = require(Shared:WaitForChild("TravelFx") :: ModuleScript) :: any -- (the trip animations, 2026-10-13 mr.robe)
local TravelRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Travel") :: RemoteFunction

local ZONES = Config.Zones.List
local LICENSES = Config.Zones.License or {}
local HOME_COLOR = Color3.fromRGB(98, 205, 48)
local LOCKED = Color3.fromRGB(120, 124, 140)
local W, H = 900, 620

local function make(className: string, props: { [string]: any }, children: { Instance }?): any
	return Skin.make(className, props, children)
end
local function attr(name: string, default: any): any
	local v = player:GetAttribute(name)
	return if v == nil then default else v
end
local function license(): number
	return attr("ZoneLicense", 0)
end
local function carrying(): boolean
	local c = attr("Carried", "")
	return typeof(c) == "string" and c ~= ""
end
local function zoneColor(z: any): Color3
	return z.Color or Color3.fromRGB(104, 152, 236)
end
-- the zone the player is standing in (Config.Zones.List[i].Bounds = { x0, z0, x1, z1 }; on the redesign islands,
-- Workspace.IslandWiring.<Id>'s BoundsMin / BoundsMax, as Ambience + ZoneMusic read them)
local function currentZone(): string?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local p = root.Position
	local wiring = Config.Zones.Islands and Config.Zones.Islands.Enabled and workspace:FindFirstChild("IslandWiring")
	for _, z in ZONES do
		local folder = wiring and wiring:FindFirstChild(z.Id)
		local lo, hi = folder and folder:GetAttribute("BoundsMin"), folder and folder:GetAttribute("BoundsMax")
		if typeof(lo) == "Vector3" and typeof(hi) == "Vector3" then
			if p.X >= lo.X and p.X <= hi.X and p.Z >= lo.Z and p.Z <= hi.Z then
				return z.Id
			end
		else
			local b = z.Bounds
			if b and p.X >= b[1] and p.X <= b[3] and p.Z >= b[2] and p.Z <= b[4] then
				return z.Id
			end
		end
	end
	return nil
end

------------------------------------------------------------------ the tile + the window
-- v3 (2026-10-23, crnuch's travel reference video): a teal striped header with two stat pills (ZONES OPEN n/6 and the
-- license), and the destinations as big PICTURE cards in two columns - the zone's own scene (art/travel/, Blender
-- renders of the v2 islands; ArtAssets.Travel ids once crnuch uploads them, the zone's colour until then), a numbered
-- badge, the name, info pills (its boss + difficulty, its egg's price) and a TRAVEL button; HERE where you stand;
-- locked = darkened with a padlock and the license it needs. HOME (your firm) is the wide card on top.
-- The trip animations (Shared.TravelFx) are unchanged (crnuch's call).
local menuEntry = HudMenu.button({
	name = "Travel", label = "TRAVEL", icon = if HudMenu.Icons.Travel then "Travel" else "Star", color = Color3.fromRGB(79, 182, 238), order = 5,
})
local TEAL = Color3.fromHex("33CFC0")
local win = Skin.window({
	Name = "Travel", Title = "Travel", Color = TEAL, Icon = HudMenu.Icons.Travel or HudMenu.Icons.Star, Size = Vector2.new(W, H), DisplayOrder = 32,
})
local body = win.body :: Frame
local ArtAssets = require(Shared:WaitForChild("ArtAssets") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local PICTURES: { [string]: string } = ArtAssets.Travel or {}

-- the header's stat pills
local function headerPill(x: number, color: Color3): TextLabel
	local p = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 2), Size = UDim2.fromOffset(200, 36),
		BackgroundColor3 = color, ZIndex = 4, Parent = win.header }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(3) })
	Skin.stripes(p, 0.8, 3, 0.08)
	return Skin.text({ Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3), Text = "", ZIndex = 5, Parent = p }, 20, 3)
end
local openPill = headerPill(-96, Color3.fromHex("1F9E92"))
local licensePill = headerPill(-306, Skin.Palette.Orange.base)

-- the strip that explains why TRAVEL is off while you carry eggs (an egg drawn with frames: no emoji)
local scroller = Skin.scroller(body, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 1, -44) })
local notice = make("Frame", {
	Name = "Carrying", Size = UDim2.new(1, -8, 0, 40), BackgroundColor3 = Skin.Palette.Orange.base, LayoutOrder = 0,
	Visible = false, ZIndex = 3, Parent = scroller,
}, { Skin.corner(8), Skin.stroke(3) })
make("Frame", { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(22, 28), BackgroundColor3 = Color3.fromRGB(255, 248, 230), ZIndex = 4, Parent = notice },
	{ make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), Skin.stroke(2) })
Skin.text({ Position = UDim2.fromOffset(44, 4), Size = UDim2.new(1, -56, 1, -8), Text = "Walk your eggs home to hatch them first!",
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = notice }, 24)
local message = Skin.text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -32, 0, 28),
	Text = "", FontFace = Skin.Fonts.Body, TextColor3 = Skin.TextSoft, ZIndex = 3, Parent = body }, 20)

type Card = { id: string, frame: Frame, go: any, lock: Frame, need: TextLabel, color: Color3, zone: any, eggPill: TextLabel? }
local cards: { Card } = {}

local function padlock(parent: GuiObject, z: number): Frame
	local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(46, 54),
		BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(30, 34), BackgroundTransparency = 1,
		ZIndex = z, Parent = f }, { make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), make("UIStroke", { Thickness = 6, Color = Color3.fromRGB(40, 40, 52) }) })
	make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(46, 32),
		BackgroundColor3 = Skin.Palette.Gold.base, ZIndex = z + 1, Parent = f }, { Skin.corner(6), Skin.stroke(3) })
	return f
end

-- a small info pill under a card's name
local DIFFICULTY = { Easy = Skin.Palette.Green.base, Medium = Skin.Palette.Gold.base, Hard = Skin.Palette.Orange.base, Extreme = Skin.Palette.Red.base }
local function infoPill(parent: GuiObject, text: string, color: Color3, order: number, z: number): TextLabel
	local p = make("Frame", { Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = color, LayoutOrder = order, ZIndex = z, Parent = parent },
		{ make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(2), make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	local l = make("TextLabel", { Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = text,
		FontFace = Skin.Fonts.Title, TextSize = 15, TextColor3 = Skin.White, ZIndex = z + 1, Parent = p })
	make("UIStroke", { Thickness = 2, Color = Skin.Ink, Parent = l })
	return l
end

local function card(parent: GuiObject, order: number, id: string, title: string, number: string, color: Color3, zone: any, size: UDim2?): Card
	local f = make("Frame", { Name = id, Size = size or UDim2.fromScale(1, 1), BackgroundColor3 = color, ClipsDescendants = true, LayoutOrder = order, ZIndex = 3, Parent = parent },
		{ Skin.corner(10) })
	make("UIStroke", { Thickness = 5, Color = color:Lerp(Color3.new(1, 1, 1), 0.25), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
	local z = 4
	-- the zone's own scene (or its colour with the v3 bands until the picture is uploaded)
	local pic = PICTURES[id]
	if pic and pic ~= "" then
		make("ImageLabel", { Name = "Picture", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = pic, ScaleType = Enum.ScaleType.Crop,
			ZIndex = z, Parent = f })
	else
		make("UIGradient", { Rotation = 60, Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3), color:Lerp(Color3.new(0, 0, 0), 0.25)), Parent = f })
		Skin.stripes(f, 0.84, 3, 0.1)
	end
	-- a dark fade at the bottom so the name and pills read on any picture
	make("Frame", { Name = "Fade", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.62), BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0, ZIndex = z + 1, Interactable = false, Parent = f },
		{ make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.35) }) })
	-- the numbered badge
	local badge = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = color, ZIndex = z + 2, Parent = f },
		{ make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(3) })
	Skin.text({ Size = UDim2.fromScale(1, 1), Text = if number ~= "" then number else "H", ZIndex = z + 3, Parent = badge }, 22, 3)
	Skin.text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -44), Size = UDim2.new(1, -190, 0, 36), Text = title,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 2, Parent = f }, 32, 4)
	-- info pills: the boss (by difficulty colour) and the egg's price
	local pills = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(1, -190, 0, 26), BackgroundTransparency = 1,
		ZIndex = z + 2, Parent = f }, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local eggPill: TextLabel? = nil
	if zone then
		for _, b in (Config.Bosses and Config.Bosses.List) or {} do
			if b.Zone == id then
				infoPill(pills, string.upper(b.Name), DIFFICULTY[b.Difficulty] or Skin.Palette.Purple.base, 1, z + 2)
			end
		end
		-- the egg's price sits top-right like a price tag (it ran under the TRAVEL button in the row)
		local tag = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(10, 26),
			AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = z + 2, Parent = f },
			{ make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
		eggPill = infoPill(tag, "", Skin.Palette.Sky.dark, 1, z + 2)
	else
		infoPill(pills, "YOUR LAWYERS + INCUBATORS", Skin.Palette.Green.dark, 1, z + 2)
	end
	local lockHolder = make("Frame", { Name = "Lock", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 12, 50), BackgroundTransparency = 0.35,
		Visible = false, ZIndex = z + 4, Parent = f })
	padlock(lockHolder, z + 5)
	local need = Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.58, 0), Size = UDim2.new(1, -40, 0, 26), Text = "",
		ZIndex = z + 5, Parent = lockHolder }, 22, 3)
	local go = Skin.button({ Parent = f, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(160, 54),
		Text = "TRAVEL", Style = TEAL, ZIndex = z + 6, TextSize = 28, Glint = true })
	local c: Card = { id = id, frame = f, go = go, lock = lockHolder, need = need, color = color, zone = zone, eggPill = eggPill }
	table.insert(cards, c)
	return c
end

card(scroller, 1, "Home", "My Firm", "", HOME_COLOR, nil, UDim2.new(1, -8, 0, 170))
local grid = Skin.grid(scroller, Vector2.new(420, 206), 2, 14)
for i, z in ZONES do
	card(grid, i, z.Id, z.Name, tostring(i), zoneColor(z), z)
end

------------------------------------------------------------------ state
local busy = false
local function render()
	local lic, carry, here = license(), carrying(), currentZone()
	notice.Visible = carry
	local openCount = 0
	for _, z in ZONES do
		if (z.License or 0) <= lic then
			openCount += 1
		end
	end
	openPill.Text = string.format("ZONES OPEN %d / %d", openCount, #ZONES)
	local def = LICENSES[lic]
	licensePill.Text = if def and def.Name then string.upper(def.Name) else "LICENSE " .. lic
	for _, c in cards do
		local open = c.zone == nil or (c.zone.License or 0) <= lic
		local isHere = (c.zone ~= nil and here == c.id) or (c.zone == nil and here == nil and false)
		c.lock.Visible = not open
		local needDef = c.zone and LICENSES[c.zone.License]
		c.need.Text = if not open and needDef then "NEEDS " .. string.upper(needDef.Name) else ""
		local can = open and not carry and not isHere
		if isHere then
			c.go.setText("HERE")
			c.go.setState("disabled", "You're already here!")
		elseif not open then
			c.go.setText("LOCKED")
			c.go.setState("disabled", "Get that zone's Law License first!")
		elseif carry then
			c.go.setText(if c.zone then "TRAVEL" else "GO HOME")
			c.go.setState("disabled", "Walk your eggs home to hatch them first!")
		else
			c.go.setText(if c.zone then "TRAVEL" else "GO HOME")
			c.go.setState("default")
		end
		c.go.button:SetAttribute("Ready", can)
		if c.eggPill and c.zone then
			local egg = Formulas.themedEgg(c.zone.Egg)
			local price = player:GetAttribute(if egg then egg.Id .. "EggPrice" else "EggPrice")
			c.eggPill.Text = if typeof(price) == "number" then "EGG $" .. Formulas.formatCoins(price) else string.upper(c.zone.Egg or "") .. " EGG"
		end
	end
	menuEntry.setAlert(false)
end

------------------------------------------------------------------ the trip (Shared.TravelFx): an animation per destination that
-- grows down the lane - zone 1 a beam-up and a flash ... Space Base a hyperspace flight through a vortex tunnel. HOME
-- is the first step, in green. (2026-10-13 mr.robe; it replaced the circle wipe.)
local REASONS = {
	carrying = "Walk your eggs home to hatch them first!",
	license = "You need that zone's Law License first!",
	cooldown = "One moment...",
}
local flarePortals: (seconds: number) -> () -- (the portal you leave from lights up; defined with the portal below)
local function go(c: Card)
	if busy or not c.go.button:GetAttribute("Ready") then
		return
	end
	-- knocked down by a boss (Bosses.client ragdolls you in the Physics state): get up first
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
		message.Text = "Get back on your feet first!"
		return
	end
	busy = true
	message.Text = ""
	win.hide()
	local index = 1
	for i, z in ZONES do
		if z.Id == c.id then
			index = i
		end
	end
	flarePortals(TravelFx.tier(index).charge + 0.4)
	local ran, ok, reason = pcall(TravelFx.trip, {
		index = index,
		color = c.color,
		go = function()
			return TravelRemote:InvokeServer(c.id)
		end,
	})
	if not ran then -- (an animation error must never leave the map stuck "busy")
		warn("[Travel] " .. tostring(ok))
		ok, reason = false, nil
	end
	busy = false
	if not ok then
		win.open()
		message.Text = REASONS[reason or ""] or "Can't go there right now"
		render()
	end
end
for _, c in cards do
	c.go.button.Activated:Connect(function()
		go(c)
	end)
end

local function openMap()
	if busy then
		return
	end
	message.Text = ""
	render()
	win.open()
end
menuEntry.button.Activated:Connect(function()
	if win.isOpen() then
		win.hide()
	else
		openMap()
	end
end)

------------------------------------------------------------------ the portal (each client draws its own view)
-- (v2 portal, 2026-10-13: FloatRing1-3 turn + bob round the light column, the Beam breathes and flares on a trip)
-- (2026-10-20, mr.robe's call: in the middle of the v2 hub island's plaza - Server.HubMap, workspace attribute
-- HubCentre - the TRAVEL sign sits centred over the portal and spins, text on both sides, so it reads from all round)
type Portal = { model: Model, arms: Model?, home: CFrame?, gems: { BasePart }, rings: { { m: Model, home: CFrame } }, beam: BasePart?, beamBase: number, sign: { { part: BasePart, rel: CFrame } }, signAxis: CFrame? }
local portals: { [Model]: Portal } = {}
local lastTouch = 0

local function lightGems(p: Portal)
	local lic = license()
	for _, gem in p.gems do
		local id = gem:GetAttribute("Zone")
		local need = 0
		for _, z in ZONES do
			if z.Id == id then
				need = z.License or 0
			end
		end
		local base = gem:GetAttribute("BaseColor") :: Color3?
		if not base then
			base = gem.Color
			gem:SetAttribute("BaseColor", base)
		end
		local open = lic >= need
		gem.Material = if open then Enum.Material.Neon else Enum.Material.SmoothPlastic
		gem.Color = if open then base :: Color3 else LOCKED
	end
end

local function track(model: Instance)
	if not model:IsA("Model") or portals[model] then
		return
	end
	local p: Portal = { model = model, gems = {}, rings = {}, beam = nil, beamBase = 0.86, sign = {} }
	portals[model] = p
	task.spawn(function()
		-- (the portal streams in as one piece: wait for it)
		local disc = model:WaitForChild("SwirlDisc", 30) :: BasePart?
		if not disc or not model.Parent then
			return
		end
		local arms = model:FindFirstChild("SwirlArms") :: Model?
		p.arms = arms
		p.home = if arms then arms:GetPivot() else nil
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") and string.match(d.Name, "^Gem%d$") then
				table.insert(p.gems, d)
			elseif d:IsA("Model") and string.match(d.Name, "^FloatRing%d$") then
				table.insert(p.rings, { m = d, home = d:GetPivot() })
			end
		end
		table.sort(p.rings, function(a, b)
			return a.m.Name < b.m.Name
		end)
		local beam = model:FindFirstChild("Beam")
		if beam and beam:IsA("BasePart") then
			p.beam = beam
			p.beamBase = beam.Transparency
		end
		-- the spinning sign (only on the hub island): board, trims, bulbs and posts turn round the portal's axis; the
		-- sign stood 2 studs off it, so it's re-centred and lifted clear of the beacon; a copy of the plate on the back
		if workspace:GetAttribute("HubCentre") ~= nil then
			local pivot = model:GetPivot()
			local own = pivot * CFrame.new(0, 0, 2)
			for _, d in model:GetChildren() do
				if d:IsA("BasePart") and string.match(d.Name, "^Sign") then
					table.insert(p.sign, { part = d, rel = own:ToObjectSpace(d.CFrame) })
				end
			end
			local plate = model:FindFirstChild("SignPlate") :: BasePart?
			local gui = plate and plate:FindFirstChildWhichIsA("SurfaceGui")
			if plate and gui then
				local back = plate:Clone()
				back.Name = "SignPlateBack"
				local backGui = back:FindFirstChildWhichIsA("SurfaceGui") :: SurfaceGui
				backGui.Face = if gui.Face == Enum.NormalId.Back then Enum.NormalId.Front else Enum.NormalId.Back
				local rel = own:ToObjectSpace(plate.CFrame)
				local mirrored = CFrame.new(rel.X, rel.Y, -rel.Z) * rel.Rotation
				back.Parent = model
				table.insert(p.sign, { part = back, rel = mirrored })
			end
			p.signAxis = pivot * CFrame.new(0, 0.6, 0)
		end
		lightGems(p)
		-- particles: the game's own effects kit, in the portal's colours (CLAUDE.md: no hand-rolled emitters)
		Effects.ambient(disc, "energy", ColorSequence.new(Color3.fromRGB(150, 225, 255), Color3.fromRGB(160, 90, 255)), 3)
		local core = model:FindFirstChild("SwirlCore") :: BasePart?
		if core then
			Effects.ambient(core, "ice", Color3.fromRGB(220, 240, 255), 1.2)
		end
		local trigger = model:FindFirstChild("Trigger") :: BasePart?
		if trigger then
			trigger.Touched:Connect(function(hit)
				local character = player.Character
				if character and hit:IsDescendantOf(character) and not win.isOpen() and os.clock() - lastTouch > 2 then
					lastTouch = os.clock()
					openMap()
				end
			end)
		end
	end)
end
CollectionService:GetInstanceAddedSignal("TravelPortal"):Connect(track)
CollectionService:GetInstanceRemovedSignal("TravelPortal"):Connect(function(m)
	portals[m :: Model] = nil
end)
for _, m in CollectionService:GetTagged("TravelPortal") do
	track(m)
end

-- a trip from the pad: the portal you stand on (within 16 studs) flares - brighter beam, faster rings
local flareUntil = 0
flarePortals = function(seconds: number)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for _, p in portals do
		if p.model.Parent and (p.model:GetPivot().Position - root.Position).Magnitude < 16 then
			flareUntil = os.clock() + seconds
		end
	end
end

-- the spiral arms turn, the floating rings turn (alternate ways) and bob, the beam breathes (anchored parts, moved
-- locally every frame; small models)
local spin, ringSpin, signSpin = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
	local flaring = os.clock() < flareUntil
	spin = (spin + dt * (if flaring then 5 else 1.6)) % (math.pi * 2)
	ringSpin = (ringSpin + dt * (if flaring then 3.2 else 0.7)) % (math.pi * 2)
	signSpin = (signSpin + dt * (if flaring then 2.4 else 0.8)) % (math.pi * 2)
	local t = os.clock()
	for _, p in portals do
		if p.arms and p.home and p.arms.Parent then
			p.arms:PivotTo((p.home :: CFrame) * CFrame.Angles(0, 0, -spin))
		end
		for k, r in p.rings do
			if r.m.Parent then
				local dir = if k % 2 == 0 then -1 else 1
				r.m:PivotTo(r.home * CFrame.new(0, math.sin(t * 1.3 + k * 2) * 0.35, 0) * CFrame.Angles(0, ringSpin * dir * (0.8 + k * 0.25), 0))
			end
		end
		if p.beam and p.beam.Parent then
			local base = if flaring then p.beamBase - 0.3 else p.beamBase
			p.beam.Transparency = math.clamp(base + math.sin(t * 2.2) * 0.04, 0, 1)
		end
		if p.signAxis then
			local turn = (p.signAxis :: CFrame) * CFrame.Angles(0, signSpin, 0)
			for _, s in p.sign do
				if s.part.Parent then
					s.part.CFrame = turn * s.rel
				end
			end
		end
	end
end)

player.AttributeChanged:Connect(function(name)
	if name == "ZoneLicense" then
		for _, p in portals do
			lightGems(p)
		end
		if win.isOpen() then
			render()
		end
	elseif name == "Carried" and win.isOpen() then
		render()
	end
end)
render()
