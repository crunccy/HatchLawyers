--!strict
-- Egg zones, client side (server: Server.ZoneService; tuning: Config.Zones). Shows, doesn't decide:
--   * zone eggs bob and spin, and their prompt + price tag show THIS player's price (EggPrice / <Id>EggPrice
--     attributes, x Golden.PriceMultiplier for a golden one)
--   * a License gate is see-through and walkable on your screen once your License is high enough
--   * the License Office boards / prompts, the hub teleport pads and your incubators say what they'd do for you
--   * the carried-eggs counter (bottom centre, "Bag"; its size is the Briefcase upgrade), a green line home to your incubator while you carry eggs, the zone's name
--     when you walk in, golden-egg alerts, and the server's short notes
-- Map pieces are found by tag (ZoneEgg / LicenseGate / UpgradeBoard / Incubator) because the map streams.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Formulas = require(Shared:WaitForChild("Formulas")) :: any
local UIKit = require(Shared:WaitForChild("UIKit")) :: any
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Zones") :: RemoteEvent

local player = Players.LocalPlayer
local CFG = Config.Zones
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local INK = UIKit.Colors.Ink
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 46)
local GREEN = Color3.fromRGB(98, 205, 48)

local function attr(name: string): any
	return player:GetAttribute(name)
end

local function carried(): { { egg: string, golden: boolean } }
	local list = {}
	local s = attr("Carried")
	if type(s) == "string" and s ~= "" then
		for _, item in string.split(s, ",") do
			local golden = string.sub(item, -1) == "*"
			table.insert(list, { egg = if golden then string.sub(item, 1, -2) else item, golden = golden })
		end
	end
	return list
end

local function eggName(egg: string): string
	return if egg == "Briefcase" then "Briefcase Egg" else egg .. " Egg"
end

local function priceOf(egg: string, golden: boolean): number
	local base = if egg == "Briefcase" then attr("EggPrice") else attr(egg .. "EggPrice")
	if type(base) ~= "number" then
		base = Config.Eggs.Price * (if egg == "Briefcase" then 1 else ((Formulas.themedEgg(egg) or {}).PriceMultiplier or 1))
	end
	return math.floor(base * (if golden then CFG.Golden.PriceMultiplier else 1))
end

------------------------------------------------------------------ sounds (same licensed sounds as StarterPlayerScripts.Sounds)
local sfx = SoundService:WaitForChild("SFX", 5) :: SoundGroup?
local function sound(id: string, volume: number, speed: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.SoundGroup = sfx
	s.Parent = SoundService
	return s
end
local SND = {
	buy = sound("rbxasset://sounds/electronicpingshort.wav", 0.45, 1.4),
	alert = sound("rbxassetid://9045751375", 0.5, 1),
	upgrade = sound("rbxasset://sounds/electronicpingshort.wav", 0.55, 1.8),
	note = sound("rbxasset://sounds/electronicpingshort.wav", 0.3, 0.7),
}

------------------------------------------------------------------ gui
local gui = Instance.new("ScreenGui")
gui.Name = "Zones"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.IgnoreGuiInset = true
gui:SetAttribute("NoSkin", true)
gui.Parent = player:WaitForChild("PlayerGui")

local boards = Instance.new("Folder")
boards.Name = "ZoneBoards"
boards.Parent = player.PlayerGui

local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, stroke: number, anchor: Vector2?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	l.Position = pos
	l.Size = size
	l.FontFace = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	if stroke > 0 then
		local s = Instance.new("UIStroke")
		s.Color = INK
		s.Thickness = stroke
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.Parent = l
	end
	l.Parent = parent
	return l
end

local function pop(obj: GuiObject, hold: number)
	local s = Instance.new("UIScale")
	s.Scale = 0.3
	s.Parent = obj
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(hold, function()
		TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.25)
		obj:Destroy()
	end)
end

local toastY = 0.24
local function toast(text: string, color: Color3?, hold: number?)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.fromScale(0.5, toastY)
	f.Size = UDim2.new(0.56, 0, 0, 56)
	f.BackgroundColor3 = color or Color3.fromRGB(52, 112, 222)
	f.Parent = gui
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(560, 66)
	c.Parent = f
	UIKit.corner(f, 16)
	UIKit.outline(f, 4)
	UIKit.shade(f, 1.05, 0.72)
	label(f, text, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.94, 0.66), WHITE, 2.5)
	pop(f, hold or 2.6)
end

-- big centred banner (zone names, golden alerts)
local function banner(title: string, sub: string, color: Color3, hold: number)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.3)
	f.Size = UDim2.fromScale(0.7, 0.16)
	f.BackgroundTransparency = 1
	f.Parent = gui
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(720, 150)
	c.Parent = f
	label(f, title, UDim2.fromScale(0.5, 0.36), UDim2.fromScale(1, 0.62), color, 5)
	label(f, sub, UDim2.fromScale(0.5, 0.84), UDim2.fromScale(0.9, 0.3), WHITE, 3)
	pop(f, hold)
end

------------------------------------------------------------------ bag counter (bottom centre)
local bag = Instance.new("Frame")
bag.Name = "Bag"
bag.AnchorPoint = Vector2.new(0.5, 1)
bag.Position = UDim2.new(0.5, 0, 1, -18)
bag.Size = UDim2.fromOffset(190, 52)
bag.BackgroundColor3 = Color3.fromRGB(150, 88, 44)
bag.Visible = false
bag.Parent = gui
UIKit.corner(bag, 16)
UIKit.outline(bag, 4)
UIKit.shade(bag, 1.08, 0.72)
local bagIcons = Instance.new("Frame")
bagIcons.BackgroundTransparency = 1
bagIcons.Position = UDim2.fromScale(0.05, 0.12)
bagIcons.Size = UDim2.fromScale(0.55, 0.76)
bagIcons.Parent = bag
local bagLayout = Instance.new("UIListLayout")
bagLayout.FillDirection = Enum.FillDirection.Horizontal
bagLayout.Padding = UDim.new(0, 3)
bagLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bagLayout.Parent = bagIcons
local bagText = label(bag, "0/1", UDim2.fromScale(0.8, 0.5), UDim2.fromScale(0.36, 0.7), WHITE, 2.5)

local function eggColor(egg: string, golden: boolean): Color3
	if golden then
		return CFG.EggColors.Golden
	end
	if CFG.EggColors[egg] then
		return CFG.EggColors[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or WHITE
end

local function refreshBag()
	local list = carried()
	local max = (attr("ZoneCarryMax") :: number?) or 1
	for _, c in bagIcons:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i = 1, max do
		local item = list[i]
		local e = Instance.new("Frame")
		e.Size = UDim2.new(0, 22, 0, 28)
		e.BackgroundColor3 = if item then eggColor(item.egg, item.golden) else Color3.fromRGB(90, 60, 40)
		e.BackgroundTransparency = if item then 0 else 0.3
		e.Parent = bagIcons
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = e
		local s = Instance.new("UIStroke")
		s.Color = INK
		s.Thickness = 2
		s.Parent = e
	end
	bag.Size = UDim2.fromOffset(math.max(150, 70 + max * 25 + 60), 52)
	bagText.Text = #list .. "/" .. max
	bag.Visible = #list > 0 or (attr("ZoneLicense") ~= nil and (attr("ZoneCarry") :: number? or 1) > 1)
	bag.BackgroundColor3 = if #list >= max then Color3.fromRGB(220, 90, 50) else Color3.fromRGB(150, 88, 44)
end
player:GetAttributeChangedSignal("Carried"):Connect(refreshBag)
player:GetAttributeChangedSignal("ZoneCarryMax"):Connect(refreshBag)
refreshBag()

------------------------------------------------------------------ zone eggs: a small 2-line label + this player's price on the prompt
-- (docs/ZONES_REFERENCE.md: name, then rarity in its colour; no loose floating price text - the price is only in
-- the [E] prompt)
type EggView = { model: Model, home: CFrame, phase: number, height: number, tag: TextLabel?, prompt: ProximityPrompt? }
local eggs: { [Model]: EggView } = {}

local function refreshEggText(v: EggView)
	local egg = v.model:GetAttribute("Egg") :: string? or "Briefcase"
	local golden = v.model:GetAttribute("Golden") == true
	local price = Formulas.formatCoins(priceOf(egg, golden))
	if v.prompt then
		v.prompt.ObjectText = (if golden then "Golden " else "") .. eggName(egg) .. "  ·  " .. price
	end
end

local function addEgg(m: Instance)
	if not m:IsA("Model") or eggs[m] then
		return
	end
	local home = m:GetAttribute("Home")
	local shell = m:WaitForChild("Shell", 5) :: BasePart?
	if typeof(home) ~= "CFrame" or not shell or not m.Parent then
		return
	end
	local golden = m:GetAttribute("Golden") == true
	local egg = m:GetAttribute("Egg") :: string? or "Briefcase"
	local rarity = m:GetAttribute("Rarity") :: string? or "Common"
	local bb = Instance.new("BillboardGui")
	bb.Name = "EggLabel"
	bb.Adornee = shell
	bb.Size = UDim2.fromOffset(120, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, shell.Size.Y / 2 + 1.2, 0)
	bb.MaxDistance = 55
	bb.LightInfluence = 0
	bb.Parent = boards
	local tag = label(bb, (if golden then "Golden " else "") .. eggName(egg), UDim2.fromScale(0.5, 0.28), UDim2.fromScale(1, 0.56), WHITE, 2)
	label(bb, rarity, UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.8, 0.44), Config.RarityColors[rarity] or WHITE, 2)
	local v: EggView = { model = m, home = home, phase = math.random() * 6, height = shell.Size.Y, tag = tag, prompt = m:FindFirstChild("BuyPrompt", true) :: ProximityPrompt? }
	eggs[m] = v
	refreshEggText(v)
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) then
			eggs[m] = nil
			bb:Destroy()
		end
	end)
end
CollectionService:GetInstanceAddedSignal("ZoneEgg"):Connect(function(m)
	task.spawn(addEgg, m)
end)
for _, m in CollectionService:GetTagged("ZoneEgg") do
	task.spawn(addEgg, m)
end
local function refreshAllEggText()
	for _, v in eggs do
		refreshEggText(v)
	end
end
player:GetAttributeChangedSignal("EggPrice"):Connect(refreshAllEggText)
for _, def in Config.Eggs.Themed do
	player:GetAttributeChangedSignal(def.Id .. "EggPrice"):Connect(refreshAllEggText)
end

------------------------------------------------------------------ License gates (see-through + walkable once licensed)
local function refreshGate(gate: Instance)
	if not gate:IsA("BasePart") then
		return
	end
	local need = gate:GetAttribute("RequiresLicense") :: number? or 1
	local open = ((attr("ZoneLicense") :: number?) or 0) >= need
	gate.CanCollide = not open
	gate.Transparency = if open then 0.88 else 0.45
	gate.Color = if open then GREEN else Color3.fromRGB(255, 140, 40)
	local prompt = gate:FindFirstChild("LicensePrompt") :: ProximityPrompt?
	if prompt then
		prompt.Enabled = not open
		local def = CFG.License[need]
		if def then
			prompt.ActionText = "Buy " .. def.Name
			prompt.ObjectText = Formulas.formatCoins(def.Cost) .. " coins  ·  opens the gate"
		end
	end
end
local function refreshGates()
	for _, g in CollectionService:GetTagged("LicenseGate") do
		refreshGate(g)
	end
end
CollectionService:GetInstanceAddedSignal("LicenseGate"):Connect(refreshGate)
player:GetAttributeChangedSignal("ZoneLicense"):Connect(refreshGates)
refreshGates()

------------------------------------------------------------------ License Office boards + prompts
local UPGRADE = {
	License = { title = "LAW LICENSE", color = GOLD },
	Carry = { title = "BRIEFCASE", color = Color3.fromRGB(255, 140, 40) }, -- (the Carry upgrade, 2026-10-12)
	Speed = { title = "FASTER SHOES", color = Color3.fromRGB(80, 200, 255) },
}

-- (current text, next text or nil when maxed, next cost)
local function upgradeInfo(kind: string): (string, string?, number?)
	if kind == "License" then
		local level = (attr("ZoneLicense") :: number?) or 0
		local cur = if level == 0 then "No license yet" else CFG.License[level].Name
		local nxt = CFG.License[level + 1]
		local opens = nil
		for _, z in CFG.List do
			if z.License == level + 1 then
				opens = z.Name
			end
		end
		return cur, nxt and (nxt.Name .. (if opens then " · opens " .. opens else "")), nxt and nxt.Cost
	elseif kind == "Carry" then
		local level = (attr("ZoneCarry") :: number?) or 1
		local def = CFG.Carry[level] or CFG.Carry[1]
		local cur = (def.Name or "Carry") .. " (" .. def.Max .. " egg" .. (if def.Max > 1 then "s" else "") .. ")"
		local nxt = CFG.Carry[level + 1]
		return cur, nxt and ((nxt.Name or "Carry") .. " (" .. nxt.Max .. " eggs)"), nxt and nxt.Cost
	else
		local level = (attr("ZoneSpeed") :: number?) or 1
		local cur = "Speed " .. CFG.Speed[level].WalkSpeed
		local nxt = CFG.Speed[level + 1]
		return cur, nxt and ("Speed " .. nxt.WalkSpeed), nxt and nxt.Cost
	end
end

type Board = { kind: string, line1: TextLabel, line2: TextLabel, line3: TextLabel }
local upgradeBoards: { [Instance]: Board } = {}
local function refreshBoard(b: Board)
	local cur, nxt, cost = upgradeInfo(b.kind)
	b.line2.Text = cur
	b.line3.Text = if nxt then (nxt .. "  ·  " .. Formulas.formatCoins(cost :: number)) else "MAXED OUT!"
	b.line3.TextColor3 = if nxt then GOLD else GREEN
end
local function addBoard(anchor: Instance)
	if not anchor:IsA("BasePart") or upgradeBoards[anchor] then
		return
	end
	local kind = anchor:GetAttribute("Upgrade") :: string?
	local info = kind and UPGRADE[kind]
	if not kind or not info then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Adornee = anchor
	bb.Size = UDim2.fromOffset(230, 96)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = boards
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(30, 26, 52)
	panel.BackgroundTransparency = 0.1
	panel.Parent = bb
	UIKit.corner(panel, 14)
	UIKit.outline(panel, 3)
	local b: Board = {
		kind = kind,
		line1 = label(panel, info.title, UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.9, 0.32), info.color, 2.5),
		line2 = label(panel, "", UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.9, 0.26), WHITE, 2),
		line3 = label(panel, "", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.92, 0.26), GOLD, 2),
	}
	upgradeBoards[anchor] = b
	refreshBoard(b)
	anchor.AncestryChanged:Connect(function()
		if not anchor:IsDescendantOf(workspace) then
			upgradeBoards[anchor] = nil
			bb:Destroy()
		end
	end)
end
CollectionService:GetInstanceAddedSignal("UpgradeBoard"):Connect(addBoard)
for _, a in CollectionService:GetTagged("UpgradeBoard") do
	addBoard(a)
end

local function refreshPrompts()
	for _, b in upgradeBoards do
		refreshBoard(b)
	end
	local root = workspace:FindFirstChild("Zones")
	if root then
		for _, p in root:GetDescendants() do
			if p:IsA("ProximityPrompt") and p.Name == "UpgradePrompt" then
				local kind = p:GetAttribute("Upgrade") :: string?
				if kind and UPGRADE[kind] then
					local _, nxt, cost = upgradeInfo(kind)
					p.Enabled = nxt ~= nil
					p.ActionText = if nxt then "Buy " .. nxt else "Maxed"
					p.ObjectText = if nxt then UPGRADE[kind].title .. "  ·  " .. Formulas.formatCoins(cost :: number) else UPGRADE[kind].title
				end
			end
		end
	end
	local tps = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("ZoneTeleports")
	if tps then
		for _, p in tps:GetDescendants() do
			if p:IsA("ProximityPrompt") and p.Name == "TeleportPrompt" then
				local zoneId = p:GetAttribute("Zone")
				for _, z in CFG.List do
					if z.Id == zoneId then
						local open = ((attr("ZoneLicense") :: number?) or 0) >= z.License
						p.ActionText = if open then "Teleport" else "Locked"
						p.ObjectText = z.Name .. (if open then "" else "  ·  needs a Law License")
					end
				end
			end
		end
	end
end
for _, a in { "ZoneLicense", "ZoneCarry", "ZoneSpeed" } do
	player:GetAttributeChangedSignal(a):Connect(refreshPrompts)
end
task.spawn(function()
	while true do -- prompts stream in and out with the map
		refreshPrompts()
		task.wait(3)
	end
end)

------------------------------------------------------------------ incubators: what pressing E would do, + a sign over yours
local function myFirm(): Instance?
	local plotName = attr("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = type(plotName) == "string" and plots and plots:FindFirstChild(plotName)
	return plot and plot:FindFirstChild("Firm")
end

type IncView = { model: Model, gui: BillboardGui, line: TextLabel }
local incubators: { [Instance]: IncView } = {}
local function refreshIncubator(v: IncView)
	local list = carried()
	local prompt = v.model:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?
	local free = attr("FreeEgg") == true
	local text
	if #list > 0 then
		text = "HATCH! (" .. #list .. ")"
		if prompt then
			prompt.ActionText = "Hatch " .. (if list[1].golden then "GOLDEN " else "") .. eggName(list[1].egg)
			prompt.ObjectText = "Carrying " .. #list .. " egg" .. (if #list > 1 then "s" else "")
		end
	elseif free then
		text = "FREE EGG!"
		if prompt then
			prompt.ActionText = "Hatch FREE Egg!"
			prompt.ObjectText = "Incubator"
		end
	else
		text = "INCUBATOR"
		if prompt then
			prompt.ActionText = "Hatch Egg"
			prompt.ObjectText = "Bring eggs from Briefcase Bay"
		end
	end
	v.line.Text = text
	v.line.TextColor3 = if #list > 0 or free then GREEN else WHITE
end
local function addIncubator(m: Instance)
	if not m:IsA("Model") or incubators[m] then
		return
	end
	local base = m:WaitForChild("Base", 5) :: BasePart?
	if not base or not m.Parent then
		return
	end
	local owner: Instance? = m
	while owner and owner:GetAttribute("OwnerUserId") == nil do
		owner = owner.Parent
	end
	if not owner or owner:GetAttribute("OwnerUserId") ~= player.UserId then
		return -- only your own incubators get a sign
	end
	local bb = Instance.new("BillboardGui")
	bb.Adornee = base
	bb.Size = UDim2.fromOffset(160, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 6.6, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = boards
	local v: IncView = { model = m, gui = bb, line = label(bb, "", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), WHITE, 3) }
	incubators[m] = v
	refreshIncubator(v)
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) then
			incubators[m] = nil
			bb:Destroy()
		end
	end)
end
CollectionService:GetInstanceAddedSignal("Incubator"):Connect(function(m)
	task.defer(addIncubator, m) -- the firm's OwnerUserId is set as it's parented
end)
for _, m in CollectionService:GetTagged("Incubator") do
	task.spawn(addIncubator, m)
end
local function refreshIncubators()
	for _, v in incubators do
		refreshIncubator(v)
	end
end
player:GetAttributeChangedSignal("Carried"):Connect(refreshIncubators)
player:GetAttributeChangedSignal("FreeEgg"):Connect(refreshIncubators)

------------------------------------------------------------------ green line home while carrying eggs
local beam = Instance.new("Beam")
beam.Name = "CarryHomeGuide"
beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90))
beam.LightEmission = 1
beam.LightInfluence = 0
beam.FaceCamera = true
beam.Width0 = 0.7
beam.Width1 = 0.4
beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(1, 0.25) })
beam.Enabled = false
local fromA = Instance.new("Attachment")
fromA.Name = "CarryFrom"
fromA.Position = Vector3.new(0, -1.5, 0)
local toA = Instance.new("Attachment")
toA.Name = "CarryTo"

local insideZone: string? = nil
task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- the line home: only while carrying, and only until you're at the incubator
		local target: BasePart? = nil
		if root and #carried() > 0 then
			local firm = myFirm()
			local folder = firm and firm:FindFirstChild("Incubators")
			local inc = folder and folder:FindFirstChildWhichIsA("Model")
			local base = inc and inc:FindFirstChild("Base") :: BasePart?
			if base and (base.Position - root.Position).Magnitude > 14 then
				target = base
			end
		end
		if root and target then
			fromA.Parent = root
			toA.Parent = target
			beam.Attachment0 = fromA
			beam.Attachment1 = toA
			beam.Parent = root
			beam.Enabled = true
		else
			beam.Enabled = false
		end
		-- zone name when you walk in
		local now: string? = nil
		if root then
			for _, z in CFG.List do
				local b = z.Bounds
				if b and root.Position.X >= b[1] and root.Position.X <= b[3] and root.Position.Z >= b[2] and root.Position.Z <= b[4] then
					now = z.Id
					if insideZone ~= z.Id then
						banner(string.upper(z.Name), "Buy " .. eggName(z.Egg) .. "s and carry them home!", if z.Egg == "Briefcase" then GOLD else Color3.fromRGB(255, 170, 110), 2.6)
					end
				end
			end
		end
		insideZone = now
	end
end)

------------------------------------------------------------------ eggs wobble on the floor (local only; they never leave the ground)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local cam = workspace.CurrentCamera
	for m, v in eggs do
		if m.PrimaryPart and (v.home.Position - cam.CFrame.Position).Magnitude < 150 then
			local tilt = math.sin(t * 2.2 + v.phase) * 0.07
			local base = v.home * CFrame.new(0, -v.height / 2, 0) -- rock around the bottom of the egg
			m:PivotTo(base * CFrame.Angles(tilt, 0, tilt * 0.6) * CFrame.new(0, v.height / 2, 0))
		end
	end
end)

------------------------------------------------------------------ chevrons: down the lane normally, back home while you carry eggs
local HOME_COLOR = Color3.fromRGB(255, 220, 90)
local function pointChevrons()
	local home = #carried() > 0
	for _, c in CollectionService:GetTagged("ZoneChevron") do
		local tip = c:GetAttribute("Home")
		if c:IsA("Model") and typeof(tip) == "CFrame" then
			-- the chevron is built pointing -X (to the next zone); flip it around its own centre to point home
			local centre = tip * CFrame.new(1.3, 0, 0)
			c:PivotTo(if home then centre * CFrame.Angles(0, math.pi, 0) * CFrame.new(-1.3, 0, 0) else tip)
			for _, p in c:GetChildren() do
				if p:IsA("BasePart") then
					p.Color = if home then HOME_COLOR else Color3.fromRGB(248, 248, 248)
				end
			end
		end
	end
end
player:GetAttributeChangedSignal("Carried"):Connect(pointChevrons)
CollectionService:GetInstanceAddedSignal("ZoneChevron"):Connect(function()
	task.defer(pointChevrons)
end)
task.defer(pointChevrons)

------------------------------------------------------------------ "YOUR FIRM" marker over your own firm (seen from the lane)
do
	local marker = Instance.new("BillboardGui")
	marker.Name = "YourFirmMarker"
	marker.Size = UDim2.fromOffset(110, 92)
	marker.AlwaysOnTop = true
	marker.MaxDistance = 2000
	marker.LightInfluence = 0
	marker.StudsOffsetWorldSpace = Vector3.new(0, 26, 0)
	marker.Parent = boards
	local roof = Instance.new("Frame")
	roof.AnchorPoint = Vector2.new(0.5, 0.5)
	roof.Position = UDim2.fromScale(0.5, 0.3)
	roof.Size = UDim2.fromOffset(40, 40)
	roof.Rotation = 45
	roof.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
	roof.Parent = marker
	local body = Instance.new("Frame")
	body.AnchorPoint = Vector2.new(0.5, 0)
	body.Position = UDim2.fromScale(0.5, 0.3)
	body.Size = UDim2.fromOffset(40, 26)
	body.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
	body.BorderSizePixel = 0
	body.Parent = marker
	for _, f in { roof, body } do
		local s = Instance.new("UIStroke")
		s.Color = INK
		s.Thickness = 3
		s.Parent = f
	end
	label(marker, "YOUR FIRM", UDim2.fromScale(0.5, 0.86), UDim2.fromScale(1, 0.26), WHITE, 2.5)
	task.spawn(function()
		while true do
			local firm = myFirm()
			local spawnPart = firm and firm:FindFirstChild("SpawnPoint")
			marker.Adornee = if spawnPart and spawnPart:IsA("BasePart") then spawnPart else nil
			marker.Enabled = marker.Adornee ~= nil
			task.wait(2)
		end
	end)
end

------------------------------------------------------------------ server messages
local boughtCount = 0
Remote.OnClientEvent:Connect(function(kind: string, info: any)
	if kind == "Note" then
		SND.note:Play()
		toast(info, Color3.fromRGB(120, 80, 220))
	elseif kind == "Alert" then
		SND.alert:Play()
		banner("GOLDEN EGG!", info.text, GOLD, 4)
	elseif kind == "Bought" then
		SND.buy:Play()
		boughtCount += 1
		local full = info.count >= info.max
		local text = if full then "Arms full! Take your eggs home to your INCUBATOR" elseif boughtCount <= 3 then "Got an egg! Carry it home to your INCUBATOR" else "Carrying " .. info.count .. "/" .. info.max
		toast(text, if info.golden then Color3.fromRGB(230, 170, 20) else GREEN, if boughtCount <= 3 or full then 3 else 1.4)
	elseif kind == "Upgraded" then
		SND.upgrade:Play()
		banner(string.upper(UPGRADE[info.kind] and UPGRADE[info.kind].title or "UPGRADE"), info.text, GREEN, 3)
	end
end)
