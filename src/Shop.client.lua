--!strict
-- Robux shop UI (user 2026-10-09, styled after the user's "Trail Shop" / "Fuse Machine" reference panels:
-- purple striped header with a red X, studded panels, colourful studded cards with a big picture, a dark perk
-- banner and a green price button). Items, ids and prices: Config.Shop. Server: Server.ShopService.
-- This script only PROMPTS purchases (MarketplaceService); the server alone grants anything.
-- Opened by the SHOP tile in the HUD's menu column (Shared.HudMenu) and by the ShopPrompt on Hub.ShopStall.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local HatchShells = require(Shared:WaitForChild("HatchShells") :: ModuleScript) :: any

local STUDS = "rbxassetid://114488299634202" -- tools/ui_textures.py
local SHINE = "rbxassetid://101930347288469"
local FONT = UIFonts.PrimaryFace
local TITLE = UIFonts.TitleFace
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local PURPLE = Color3.fromRGB(176, 52, 255)
local PURPLE_DARK = Color3.fromRGB(122, 30, 214)
local PANEL = Color3.fromRGB(46, 44, 66)
local GREEN = Color3.fromRGB(76, 224, 48)
local GREEN_DARK = Color3.fromRGB(40, 150, 30)
local RED = Color3.fromRGB(228, 32, 32)
local GRAY = Color3.fromRGB(150, 150, 165)

local function make(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end
local function corner(px: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, px) })
end
local function stroke(px: number, color: Color3?): UIStroke
	return make("UIStroke", { Thickness = px, Color = color or BLACK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
	make("UIStroke", { Thickness = math.max(2, math.floor(maxSize / 10)), Color = BLACK, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	return l
end
-- the studded pattern laid over a panel (like the references' backgrounds)
local function studs(parent: GuiObject, transparency: number, z: number?)
	make("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = STUDS, ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(34, 34), ZIndex = z or parent.ZIndex, Parent = parent,
	}, { make("UICorner", { CornerRadius = (parent:FindFirstChildOfClass("UICorner") :: UICorner?) and (parent:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius or UDim.new() }) })
end
local function squish(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = gui })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local playerGui = player:WaitForChild("PlayerGui")
local gui = make("ScreenGui", { Name = "Shop", ResetOnSpawn = false, DisplayOrder = 18, Enabled = false, IgnoreGuiInset = true, Parent = playerGui })
local shade = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui })

------------------------------------------------------------------ panel (reference: "Trail Shop")
local panelScale = make("UIScale", { Scale = 1 })
local panel = make("Frame", {
	Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(940, 560),
	BackgroundColor3 = PANEL, Parent = gui,
}, { corner(10), stroke(6), panelScale })
studs(panel, 0.9)
local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(10),
	make("UIGradient", { Color = ColorSequence.new(PURPLE, PURPLE_DARK), Rotation = 0 }),
})
make("Frame", { Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = PURPLE_DARK, BorderSizePixel = 0, ZIndex = 2, Parent = header })
make("Frame", { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 3, Parent = header })
studs(header, 0.86, 2)
make("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = SHINE, ImageTransparency = 0.7, ZIndex = 3, Parent = header })
text({ Position = UDim2.fromOffset(28, 10), Size = UDim2.new(0.6, 0, 0, 66), FontFace = TITLE, Text = "Robux Shop", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header }, 62)
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(74, 66), BackgroundColor3 = RED,
	Text = "", AutoButtonColor = true, ZIndex = 4, Parent = header,
}, { corner(6), stroke(4) })
text({ Size = UDim2.fromScale(1, 1), Text = "X", FontFace = TITLE, ZIndex = 5, Parent = closeButton }, 54)

-- tabs: Passes (forever) / Boosts (developer products)
local tabs = {}
local function tab(name: string, x: number, color: Color3): TextButton
	local b = make("TextButton", {
		Position = UDim2.fromOffset(x, 108), Size = UDim2.fromOffset(190, 46), BackgroundColor3 = color, Text = "", AutoButtonColor = true, Parent = panel,
	}, { corner(10), stroke(4) })
	text({ Size = UDim2.fromScale(1, 1), Text = name, Parent = b }, 30)
	tabs[name] = b
	return b
end
local passesTab = tab("Passes", 24, GREEN)
local boostsTab = tab("Boosts", 226, Color3.fromRGB(60, 160, 255))
local tabHint = text({ Position = UDim2.fromOffset(436, 112), Size = UDim2.new(1, -460, 0, 38), FontFace = UIFonts.BodyFace, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(220, 215, 255), Parent = panel }, 22)

-- the card row (scrolls sideways like the reference)
local row = make("ScrollingFrame", {
	Position = UDim2.fromOffset(20, 168), Size = UDim2.new(1, -40, 1, -184), BackgroundColor3 = Color3.fromRGB(32, 31, 47),
	BorderSizePixel = 0, ScrollBarThickness = 8, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.new(), Parent = panel,
}, {
	corner(8), stroke(4),
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
})

------------------------------------------------------------------ 3D item icons (little voxel builds, spinning)
local spinners: { { model: Model, base: CFrame } } = {}
local function box(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = model
end
local ICONS: { [string]: (Model) -> number } = {
	cash = function(m) -- a fanned stack of bills and a pile of gold coins; returns its size
		for k = 0, 4 do
			box(m, Vector3.new(4.2, 0.45, 2.2), CFrame.new(-0.6, -1.2 + k * 0.47, 0) * CFrame.Angles(0, math.rad(k * 9 - 18), 0), Color3.fromRGB(70, 185, 75))
			box(m, Vector3.new(1.3, 0.47, 1.0), CFrame.new(-0.6, -1.2 + k * 0.47, 0) * CFrame.Angles(0, math.rad(k * 9 - 18), 0), Color3.fromRGB(45, 140, 55))
		end
		for k = 0, 5 do
			box(m, Vector3.new(0.4, 1.5, 1.5), CFrame.new(1.7 + (k % 2) * 0.5, -1.2 + k * 0.42, 1.2) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 196, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
		return 6
	end,
	egg = function(m) -- the real Briefcase egg (Shared.HatchShells, outer layer only)
		for _, s in HatchShells.EggMachine.shards do
			for _, b in s.boxes do
				if b[10] == 0 then
					box(m, Vector3.new(b[4], b[5], b[6]), CFrame.new(b[1], b[2], b[3]), Color3.new(b[7], b[8], b[9]))
				end
			end
		end
		return 9.5
	end,
	clock = function(m) -- a stopwatch
		box(m, Vector3.new(0.9, 5, 5), CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(235, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		box(m, Vector3.new(0.3, 4, 4), CFrame.new(0, 0, -0.35) * CFrame.Angles(0, math.pi / 2, 0), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		box(m, Vector3.new(0.25, 1.6, 0.12), CFrame.new(0, 0.7, -0.55), Color3.fromRGB(40, 40, 50))
		box(m, Vector3.new(1.2, 0.25, 0.12), CFrame.new(0.5, 0, -0.55), Color3.fromRGB(40, 40, 50))
		box(m, Vector3.new(0.9, 0.8, 0.9), CFrame.new(0, 2.9, 0), Color3.fromRGB(90, 90, 110))
		box(m, Vector3.new(1.5, 0.5, 0.9), CFrame.new(0, 3.4, 0), Color3.fromRGB(235, 60, 60))
		return 6.5
	end,
	briefcase = function(m) -- a lawyer's briefcase
		box(m, Vector3.new(5, 3.4, 1.4), CFrame.new(0, -0.4, 0), Color3.fromRGB(120, 72, 40))
		box(m, Vector3.new(5.1, 0.35, 1.5), CFrame.new(0, 0.5, 0), Color3.fromRGB(90, 52, 28))
		box(m, Vector3.new(0.7, 0.6, 1.6), CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 200, 40))
		box(m, Vector3.new(2, 0.4, 0.5), CFrame.new(0, 1.9, 0), Color3.fromRGB(70, 42, 22))
		box(m, Vector3.new(0.4, 0.8, 0.5), CFrame.new(-0.8, 1.5, 0), Color3.fromRGB(70, 42, 22))
		box(m, Vector3.new(0.4, 0.8, 0.5), CFrame.new(0.8, 1.5, 0), Color3.fromRGB(70, 42, 22))
		return 6
	end,
}
local function icon(parent: GuiObject, kind: string)
	local vf = make("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 195), LightDirection = Vector3.new(-0.5, -1, -0.6), ZIndex = parent.ZIndex + 1, Parent = parent,
	})
	local m = Instance.new("Model")
	local size = (ICONS[kind] or ICONS.cash)(m)
	m.Parent = vf
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size * 0.35, -size * 2.3), Vector3.new(0, 0, 0))
	cam.Parent = vf
	vf.CurrentCamera = cam
	table.insert(spinners, { model = m, base = m:GetPivot() })
end

------------------------------------------------------------------ cards
type Card = { item: any, kind: string, button: TextButton, label: TextLabel, frame: Frame }
local cards: { Card } = {}
local prices: { [string]: number } = {}
local pending: { [string]: boolean } = {}

local function owns(item: any): boolean
	return player:GetAttribute("Pass" .. item.Key) == true
end

local function refreshCard(c: Card)
	local item = c.item
	local label, button = c.label, c.button
	if c.kind == "pass" and owns(item) then
		label.Text = "OWNED ✓"
		button.BackgroundColor3 = GRAY
	elseif item.Id == 0 then
		label.Text = "COMING SOON"
		button.BackgroundColor3 = GRAY
	elseif pending[item.Key] then
		label.Text = "..."
		button.BackgroundColor3 = GREEN_DARK
	else
		label.Text = "R$ " .. tostring(prices[item.Key] or item.Price)
		button.BackgroundColor3 = GREEN
	end
end

local function buildCard(item: any, kind: string, order: number): Card
	local light = item.Color:Lerp(WHITE, 0.45)
	local frame = make("Frame", {
		Size = UDim2.fromOffset(268, 350), BackgroundColor3 = WHITE, LayoutOrder = order, Parent = row,
	}, {
		corner(8), stroke(5),
		make("UIGradient", { Color = ColorSequence.new(light, item.Color), Rotation = 90 }),
	})
	studs(frame, 0.82)
	text({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 40), Text = item.Name, ZIndex = 2, Parent = frame }, 34)
	text({ Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 22), Text = if kind == "pass" then "Game Pass · forever" else "Boost", ZIndex = 2, Parent = frame }, 20)
	local art = make("Frame", { Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 0, 140), BackgroundTransparency = 1, ZIndex = 2, Parent = frame })
	icon(art, item.Icon)
	-- the perk banner (dark strip, the number in green like the reference's "x1.5 Speed")
	local banner = make("Frame", {
		Position = UDim2.fromOffset(12, 212), Size = UDim2.new(1, -24, 0, 46), BackgroundColor3 = Color3.fromRGB(40, 40, 52),
		BackgroundTransparency = 0.15, ZIndex = 3, Parent = frame,
	}, { corner(6), stroke(3) })
	local first, rest = string.match(item.Banner, "^(%S+)%s*(.*)$")
	local bannerText = text({ Size = UDim2.fromScale(1, 1), RichText = true, ZIndex = 4, Parent = banner,
		Text = string.format('<font color="#5CF03C">%s</font> %s', first or item.Banner, rest or "") }, 32)
	bannerText.RichText = true
	text({ Position = UDim2.fromOffset(12, 262), Size = UDim2.new(1, -24, 0, 30), FontFace = UIFonts.BodyFace, Text = item.Text, TextWrapped = true, ZIndex = 3, Parent = frame }, 18)
	local button = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 298), Size = UDim2.new(1, -40, 0, 42), BackgroundColor3 = GREEN,
		Text = "", AutoButtonColor = true, ZIndex = 3, Parent = frame,
	}, { corner(6), stroke(4) })
	studs(button, 0.85, 3)
	local label = text({ Size = UDim2.fromScale(1, 1), Text = "", FontFace = TITLE, ZIndex = 4, Parent = button }, 34)
	local card: Card = { item = item, kind = kind, button = button, label = label, frame = frame }
	button.Activated:Connect(function()
		squish(button)
		if item.Id == 0 or pending[item.Key] or (kind == "pass" and owns(item)) then
			return
		end
		pending[item.Key] = true
		refreshCard(card)
		if kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
		task.delay(20, function() -- safety: never leave a card stuck on "..."
			pending[item.Key] = nil
			refreshCard(card)
		end)
	end)
	refreshCard(card)
	return card
end

local function showTab(name: string)
	for _, c in row:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	table.clear(cards)
	table.clear(spinners)
	local list = if name == "Passes" then Config.Shop.Passes else Config.Shop.Products
	for i, item in list do
		table.insert(cards, buildCard(item, if name == "Passes" then "pass" else "product", i))
	end
	tabHint.Text = if name == "Passes" then "Buy once, keep forever!" else "Instant boosts - buy as many as you like!"
	for n, b in tabs do
		local s = b:FindFirstChildOfClass("UIStroke") :: UIStroke
		s.Thickness = if n == name then 5 else 3
		s.Color = if n == name then WHITE else BLACK
	end
	-- real prices for set-up items (Creator Dashboard is the source of truth)
	for _, c in cards do
		local item = c.item
		if item.Id ~= 0 and not prices[item.Key] then
			task.spawn(function()
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, item.Id,
					if c.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
				if ok and info and info.PriceInRobux then
					prices[item.Key] = info.PriceInRobux
					refreshCard(c)
				end
			end)
		end
	end
end

local function clearPending(key: string?)
	for _, c in cards do
		if key == nil or c.item.Key == key then
			pending[c.item.Key] = nil
			refreshCard(c)
		end
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId)
	if who == player then
		for _, p in Config.Shop.Passes do
			if p.Id == passId then
				clearPending(p.Key)
			end
		end
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId)
	if userId == player.UserId then
		for _, p in Config.Shop.Products do
			if p.Id == productId then
				clearPending(p.Key)
			end
		end
	end
end)
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 4) == "Pass" then
		clearPending(nil)
	end
end)

------------------------------------------------------------------ open / close
local current = "Passes"
local function fit(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 1
	end
	return math.clamp(math.min(camera.ViewportSize.X / 1000, camera.ViewportSize.Y / 640), 0.45, 1)
end

local function open()
	if gui.Enabled then
		return
	end
	showTab(current)
	gui.Enabled = true
	shade.BackgroundTransparency = 1
	TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
	panelScale.Scale = 0.6 * fit()
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit() }):Play()
end
local function close()
	local t = TweenService:Create(panelScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.6 * fit() })
	t:Play()
	TweenService:Create(shade, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
	t.Completed:Wait()
	gui.Enabled = false
	table.clear(spinners)
end
closeButton.Activated:Connect(close)
passesTab.Activated:Connect(function()
	squish(passesTab)
	current = "Passes"
	showTab(current)
end)
boostsTab.Activated:Connect(function()
	squish(boostsTab)
	current = "Boosts"
	showTab(current)
end)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		local t = os.clock()
		for i, s in spinners do
			s.model:PivotTo(s.base * CFrame.Angles(0, t * 0.8 + i, 0))
		end
	end
end)

------------------------------------------------------------------ the HUD button: SHOP tile in the shared menu column
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local menuEntry = HudMenu.button({ name = "Shop", label = "SHOP", icon = "Shop", color = Color3.fromRGB(70, 200, 40), order = 3 })
menuEntry.setAlert(true) -- "come look" until the first visit
menuEntry.button.Activated:Connect(function()
	menuEntry.setAlert(false)
	if gui.Enabled then
		close()
	else
		open()
	end
end)

-- the stall in the hub (streams in late / re-streams as new instances: listen by prompt name)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	if prompt.Name == "ShopPrompt" then
		open()
	end
end)
