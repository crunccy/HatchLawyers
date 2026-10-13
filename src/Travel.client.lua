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
local TravelRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Travel") :: RemoteFunction

local ZONES = Config.Zones.List
local LICENSES = Config.Zones.License or {}
local HOME_COLOR = Color3.fromRGB(98, 205, 48)
local LOCKED = Color3.fromRGB(120, 124, 140)
local W, H = 980, 470
local CARD_W, CARD_H, GAP = 124, 318, 10

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
-- the zone the player is standing in (Config.Zones.List[i].Bounds = { x0, z0, x1, z1 })
local function currentZone(): string?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local p = root.Position
	for _, z in ZONES do
		local b = z.Bounds
		if b and p.X >= b[1] and p.X <= b[3] and p.Z >= b[2] and p.Z <= b[4] then
			return z.Id
		end
	end
	return nil
end

------------------------------------------------------------------ the tile + the window
local menuEntry = HudMenu.button({
	name = "Travel", label = "TRAVEL", icon = if HudMenu.Icons.Travel then "Travel" else "Star", color = Color3.fromRGB(79, 182, 238), order = 5,
})
local win = Skin.window({
	Name = "Travel", Title = "Travel", Color = "Sky", Icon = HudMenu.Icons.Travel or HudMenu.Icons.Star, Size = Vector2.new(W, H), DisplayOrder = 32,
})
local body = win.body :: Frame

-- the strip that explains why GO is grey while you carry eggs (an egg drawn with frames: no emoji)
local notice = make("Frame", {
	Name = "Carrying", Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -32, 0, 40), BackgroundColor3 = Skin.Palette.Orange.base,
	Visible = false, ZIndex = 3, Parent = body,
}, { Skin.corner(8), Skin.stroke(3) })
make("Frame", { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(22, 28), BackgroundColor3 = Color3.fromRGB(255, 248, 230), ZIndex = 4, Parent = notice },
	{ make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), Skin.stroke(2) })
Skin.text({ Position = UDim2.fromOffset(44, 4), Size = UDim2.new(1, -56, 1, -8), Text = "Walk your eggs home to hatch them first!",
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = notice }, 24)
local message = Skin.text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -32, 0, 28),
	Text = "", FontFace = Skin.Fonts.Body, TextColor3 = Skin.TextSoft, ZIndex = 3, Parent = body }, 20)

local row = make("Frame", {
	Name = "Cards", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(7 * CARD_W + 6 * GAP, CARD_H),
	BackgroundTransparency = 1, ZIndex = 2, Parent = body,
}, { make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }) })

type Card = { id: string, frame: Frame, go: any, lock: Frame, need: TextLabel, here: TextLabel, color: Color3, zone: any }
local cards: { Card } = {}

local function padlock(parent: GuiObject, z: number): Frame
	local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(46, 54),
		BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(30, 34), BackgroundTransparency = 1,
		ZIndex = z, Parent = f }, { make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), make("UIStroke", { Thickness = 6, Color = Color3.fromRGB(40, 40, 52) }) })
	make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(46, 32),
		BackgroundColor3 = Skin.Palette.Gold.base, ZIndex = z + 1, Parent = f }, { Skin.corner(6), Skin.stroke(3) })
	return f
end

local function card(order: number, id: string, title: string, number: string, color: Color3, zone: any): Card
	local f = Skin.card(row, { Name = id, Color = color, Size = UDim2.fromOffset(CARD_W, CARD_H), LayoutOrder = order })
	local z = f.ZIndex + 2
	if number ~= "" then
		Skin.text({ Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 60), Text = number, FontFace = Skin.Fonts.Number, ZIndex = z, Parent = f }, 56, 4)
	else -- HOME: a little house (frames, no emoji)
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(34, 34), Rotation = 45,
			BackgroundColor3 = Skin.Palette.Red.base, ZIndex = z, Parent = f }, { Skin.corner(3), Skin.stroke(3) })
		make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 38), Size = UDim2.fromOffset(40, 28),
			BackgroundColor3 = Color3.fromRGB(246, 226, 180), ZIndex = z + 1, Parent = f }, { Skin.corner(3), Skin.stroke(3) })
		make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(12, 16),
			BackgroundColor3 = Color3.fromRGB(122, 70, 34), ZIndex = z + 2, Parent = f }, { Skin.corner(2) })
	end
	Skin.text({ Position = UDim2.fromOffset(8, 76), Size = UDim2.new(1, -16, 0, 64), Text = title, TextWrapped = true, ZIndex = z, Parent = f }, 26, 3)
	local here = Skin.text({ Position = UDim2.fromOffset(4, 144), Size = UDim2.new(1, -8, 0, 28), Text = "YOU'RE HERE", TextColor3 = Skin.Palette.Gold.light,
		Visible = false, ZIndex = z, Parent = f }, 18, 3)
	local lockHolder = make("Frame", { Position = UDim2.fromOffset(0, 172), Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, ZIndex = z, Parent = f })
	padlock(lockHolder, z)
	local need = Skin.text({ Position = UDim2.fromOffset(4, 246), Size = UDim2.new(1, -8, 0, 22), Text = "", FontFace = Skin.Fonts.Body, ZIndex = z, Parent = f }, 18, 2)
	local go = Skin.button({ Parent = f, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -20, 0, 52),
		Text = "GO", Style = "Green", ZIndex = z, TextSize = 30 })
	local c: Card = { id = id, frame = f, go = go, lock = lockHolder, need = need, here = here, color = color, zone = zone }
	table.insert(cards, c)
	return c
end

for i, z in ZONES do
	card(i, z.Id, z.Name, tostring(i), zoneColor(z), z)
end
card(#ZONES + 1, "Home", "My Firm", "", HOME_COLOR, nil)

------------------------------------------------------------------ state
local busy = false
local function render()
	local lic, carry, here = license(), carrying(), currentZone()
	notice.Visible = carry
	for _, c in cards do
		local open = c.zone == nil or (c.zone.License or 0) <= lic
		local isHere = c.zone ~= nil and here == c.id
		c.lock.Visible = not open
		c.here.Visible = isHere
		local def = c.zone and LICENSES[c.zone.License]
		c.need.Text = if not open and def then string.upper((string.gsub(def.Name, " License", ""))) else ""
		local can = open and not carry and not isHere
		c.go.setStyle(if can then "Green" else "Grey")
		c.go.button:SetAttribute("Ready", can)
		c.go.button.Visible = open
		local grad = c.frame:FindFirstChildOfClass("UIGradient")
		if grad then
			local base = if open then c.color else LOCKED
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, base:Lerp(Color3.new(0, 0, 0), 0.25)), ColorSequenceKeypoint.new(0.45, base),
				ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0, 0, 0), 0.3)),
			})
		end
	end
	menuEntry.setAlert(false)
end

------------------------------------------------------------------ the trip: a circle wipe in the destination's colour
local wipeGui = make("ScreenGui", { Name = "TravelWipe", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60, Enabled = false,
	Parent = player:WaitForChild("PlayerGui") })
local wipe = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
	BackgroundColor3 = HOME_COLOR, Parent = wipeGui }, { make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), Skin.stroke(8) })
Skin.studs(wipe, 0.85)

local function cover(color: Color3, closing: boolean): Tween
	local cam = workspace.CurrentCamera
	local vs = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local big = math.ceil(vs.Magnitude * 1.15)
	wipe.BackgroundColor3 = color
	wipeGui.Enabled = true
	local t = TweenService:Create(wipe, TweenInfo.new(if closing then 0.3 else 0.4, Enum.EasingStyle.Quad,
		if closing then Enum.EasingDirection.In else Enum.EasingDirection.Out), { Size = if closing then UDim2.fromOffset(big, big) else UDim2.fromOffset(0, 0) })
	if closing then
		wipe.Size = UDim2.fromOffset(0, 0)
	end
	t:Play()
	return t
end

local REASONS = {
	carrying = "Walk your eggs home to hatch them first!",
	license = "You need that zone's Law License first!",
	cooldown = "One moment...",
}
local function go(c: Card)
	if busy or not c.go.button:GetAttribute("Ready") then
		return
	end
	busy = true
	message.Text = ""
	cover(c.color, true).Completed:Wait()
	win.hide()
	local ok, reason = TravelRemote:InvokeServer(c.id)
	task.wait(0.1)
	cover(c.color, false).Completed:Wait()
	wipeGui.Enabled = false
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
type Portal = { model: Model, arms: Model?, home: CFrame?, gems: { BasePart } }
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
	local p: Portal = { model = model, gems = {} }
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
			end
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

-- the spiral arms turn (anchored parts, moved locally every frame; one small model)
local spin = 0
RunService.RenderStepped:Connect(function(dt)
	spin = (spin + dt * 1.6) % (math.pi * 2)
	for _, p in portals do
		if p.arms and p.home and p.arms.Parent then
			p.arms:PivotTo((p.home :: CFrame) * CFrame.Angles(0, 0, -spin))
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
