--!strict
-- Skin inventory: a SKINS button on the left edge (with a NEW counter) opens a collection screen.
-- Pick a lawyer, pick a skin, then Equip / Unequip, Sell 1, or Sell All Extras. Undiscovered skins
-- show as silhouettes so players can see what's left to collect. Everything is validated on the
-- server (EggServer); this script only reads the player attributes it mirrors:
--   SkinsOwned (JSON skinId -> count), Desk<N>Skin, DeskCount, Plot, SkinsUnseen (saved NEW count).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript)
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquipSkin = Remotes:WaitForChild("EquipSkin") :: RemoteEvent
local SellSkins = Remotes:WaitForChild("SellSkins") :: RemoteFunction
local MarkSkinsSeen = Remotes:WaitForChild("MarkSkinsSeen") :: RemoteEvent

-- Cartoony style (see the team style guide): FredokaOne, bright colors, thick black outlines.
local FONT = Enum.Font.FredokaOne
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local CREAM = Color3.fromRGB(255, 248, 230)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local RED = Color3.fromRGB(240, 70, 70)
local YELLOW = Color3.fromRGB(255, 215, 60)
local TEAL = Color3.fromRGB(40, 170, 220)
local GREY = Color3.fromRGB(150, 150, 160)
local SKIN_TONE = Color3.fromRGB(255, 204, 153)

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function make(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(scale: number, offset: number?): UICorner
	return make("UICorner", { CornerRadius = UDim.new(scale, offset or 0) })
end

local function stroke(thickness: number, border: boolean?): UIStroke
	return make("UIStroke", {
		Thickness = thickness,
		Color = BLACK,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual,
	})
end

local function text(props: { [string]: any }, strokeThickness: number?): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	return make("TextLabel", props, { stroke(strokeThickness or 3) })
end

local function tween(instance: Instance, seconds: number, props: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props):Play()
end

-- Chunky cartoony button: colored, thick outline, bounces on hover and click.
local function button(props: { [string]: any }): TextButton
	props.Font = FONT
	props.TextScaled = true
	props.TextColor3 = WHITE
	props.TextStrokeTransparency = 0
	props.AutoButtonColor = true
	local scale = make("UIScale", {})
	local b = make("TextButton", props, {
		corner(0.25),
		stroke(4, true),
		scale,
		make("UIPadding", { PaddingTop = UDim.new(0.2, 0), PaddingBottom = UDim.new(0.2, 0), PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0) }),
	})
	b.MouseEnter:Connect(function()
		tween(scale, 0.12, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
	end)
	b.Activated:Connect(function()
		scale.Scale = 0.9
		tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	return b
end

local function rarityOf(skin: Config.Skin): (string, Color3)
	local id = Config.Eggs.Skins[skin.Rarity].Id
	return id, Config.RarityColors[id] or WHITE
end

local function lighten(color: Color3, amount: number): Color3
	return color:Lerp(WHITE, amount)
end

-------------------------------------------------------------------------------
-- State (mirrored from server attributes)
-------------------------------------------------------------------------------

local function owned(): { [string]: number }
	local raw = player:GetAttribute("SkinsOwned")
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and typeof(decoded) == "table" then decoded else {}
end

local function deskCount(): number
	local n = player:GetAttribute("DeskCount")
	return if typeof(n) == "number" then math.max(n, 1) else 1
end

local function equippedOn(desk: number): string?
	local id = player:GetAttribute("Desk" .. desk .. "Skin")
	return if typeof(id) == "string" then id else nil
end

local function lawyerModel(desk: number): Model?
	local plotName = player:GetAttribute("Plot")
	local plot = typeof(plotName) == "string" and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local deskModel = firm and (firm:FindFirstChild("Desk" .. desk) or firm:FindFirstChild("Desk1"))
	local lawyer = deskModel and deskModel:FindFirstChild("Lawyer")
	return if lawyer and lawyer:IsA("Model") then lawyer else nil
end

local selectedDesk = 1
local selectedSkin: string? = nil
local unseen = 0

-------------------------------------------------------------------------------
-- Layout
-------------------------------------------------------------------------------

local gui = make("ScreenGui", {
	Name = "SkinInventory",
	ResetOnSpawn = false,
	DisplayOrder = 15,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Left-edge SKINS button, like the Shop / Index stack in popular sims.
local openScale = make("UIScale", {})
local openButton = make("TextButton", {
	Name = "SkinsButton",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(96, 96),
	BackgroundColor3 = TEAL,
	Text = "",
	AutoButtonColor = true,
	Parent = gui,
}, { corner(0.22), stroke(4, true), openScale })
text({ Size = UDim2.fromScale(0.7, 0.55), Position = UDim2.fromScale(0.15, 0.06), Text = "👔", Parent = openButton }, 0)
text({ Size = UDim2.fromScale(0.9, 0.3), Position = UDim2.fromScale(0.05, 0.64), Text = "SKINS", Parent = openButton }, 3)
local badge = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -6, 0, 6),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = RED,
	Visible = false,
	Parent = openButton,
}, { corner(1), stroke(3, true) })
local badgeText = text({ Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "0", Parent = badge }, 2)

-- The panel is laid out at 760x500 and scaled down to fit smaller screens.
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(760, 500),
	BackgroundColor3 = CREAM,
	Visible = false,
	Parent = gui,
}, { corner(0, 26), stroke(6, true), panelScale })

local header = make("Frame", {
	Size = UDim2.new(1, 0, 0, 66),
	BackgroundColor3 = GREEN,
	Parent = panel,
}, { corner(0, 26) })
make("Frame", { -- squares off the header's bottom corners
	Position = UDim2.new(0, 0, 1, -26),
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundColor3 = GREEN,
	BorderSizePixel = 0,
	Parent = header,
})
text({ Position = UDim2.fromOffset(24, 8), Size = UDim2.fromOffset(260, 50), Text = "MY SKINS", TextXAlignment = Enum.TextXAlignment.Left, Parent = header }, 5)
local foundLabel = text({
	Position = UDim2.fromOffset(250, 18),
	Size = UDim2.fromOffset(200, 32),
	Text = "",
	TextColor3 = YELLOW,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = header,
}, 3)
local closeButton = button({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(58, 58),
	BackgroundColor3 = RED,
	Text = "X",
	ZIndex = 5,
	Parent = panel,
})
local closeCorner = closeButton:FindFirstChildOfClass("UICorner") :: UICorner
closeCorner.CornerRadius = UDim.new(1, 0)

-- Lawyer picker
text({ Position = UDim2.fromOffset(22, 78), Size = UDim2.fromOffset(80, 30), Text = "Dress:", TextColor3 = Color3.fromRGB(60, 60, 70), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 0)
local deskTabs = make("Frame", {
	Position = UDim2.fromOffset(100, 74),
	Size = UDim2.fromOffset(640, 38),
	BackgroundTransparency = 1,
	Parent = panel,
}, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})

-- Detail column (left)
local previewBack = make("Frame", {
	Position = UDim2.fromOffset(20, 122),
	Size = UDim2.fromOffset(280, 196),
	BackgroundColor3 = Color3.fromRGB(225, 240, 255),
	Parent = panel,
}, { corner(0, 18), stroke(4, true) })
local previewGradient = make("UIGradient", { Rotation = 90, Parent = previewBack })
local viewport = make("ViewportFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(200, 200, 200),
	LightDirection = Vector3.new(-1, -1, -1),
	Parent = previewBack,
})
local detailName = text({ Position = UDim2.fromOffset(20, 324), Size = UDim2.fromOffset(280, 38), Text = "", Parent = panel }, 4)
local detailPill = make("Frame", {
	Position = UDim2.fromOffset(20, 366),
	Size = UDim2.fromOffset(130, 30),
	BackgroundColor3 = GREY,
	Parent = panel,
}, { corner(1), stroke(3, true) })
local detailPillText = text({ Size = UDim2.fromScale(0.86, 0.8), Position = UDim2.fromScale(0.07, 0.1), Text = "", Parent = detailPill }, 2)
local detailInfo = text({
	Position = UDim2.fromOffset(158, 366),
	Size = UDim2.fromOffset(142, 30),
	Text = "",
	TextColor3 = Color3.fromRGB(60, 60, 70),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = panel,
}, 0)
local equipButton = button({ Position = UDim2.fromOffset(20, 404), Size = UDim2.fromOffset(280, 46), BackgroundColor3 = GREEN, Text = "EQUIP", Parent = panel })
local sellOneButton = button({ Position = UDim2.fromOffset(20, 456), Size = UDim2.fromOffset(280, 34), BackgroundColor3 = ORANGE, Text = "SELL 1", Parent = panel })

-- Collection grid (right)
local grid = make("ScrollingFrame", {
	Position = UDim2.fromOffset(316, 122),
	Size = UDim2.fromOffset(424, 316),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = panel,
}, {
	make("UIGridLayout", { CellSize = UDim2.fromOffset(128, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4) }),
})
local sellExtrasButton = button({ Position = UDim2.fromOffset(316, 446), Size = UDim2.fromOffset(424, 44), BackgroundColor3 = ORANGE, Text = "SELL ALL EXTRAS", Parent = panel })

local coinPop = text({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(300, 54), Text = "", TextColor3 = YELLOW, Visible = false, ZIndex = 10, Parent = panel }, 4)

-------------------------------------------------------------------------------
-- Mini lawyer icon drawn from frames (cheap enough for any number of cards)
-------------------------------------------------------------------------------

local function drawIcon(parent: Instance, skin: Config.Skin, isOwned: boolean)
	local holder = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(80, 96),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local function block(x: number, y: number, w: number, h: number, color: Color3, round: number?)
		make("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = if isOwned then color else Color3.fromRGB(40, 40, 50),
			BackgroundTransparency = if isOwned then 0 else 0.2,
			BorderSizePixel = 0,
			Parent = holder,
		}, if round then { corner(0, round) } else nil)
	end
	block(23, 18, 34, 32, skin.Head or SKIN_TONE, 6) -- head
	block(14, 52, 52, 32, skin.Suit, 4) -- torso
	block(2, 52, 12, 30, skin.Suit, 4) -- arms
	block(66, 52, 12, 30, skin.Suit, 4)
	block(36, 52, 8, 26, skin.Tie) -- tie
	block(16, 84, 48, 12, skin.Pants, 3) -- legs
	local hatColor = skin.HatColor or skin.Suit
	if skin.Hat == "Cap" then
		block(21, 10, 38, 12, hatColor, 6)
		block(40, 18, 24, 5, hatColor)
	elseif skin.Hat == "TopHat" then
		block(16, 16, 48, 5, hatColor)
		block(26, 0, 28, 18, hatColor)
		block(26, 12, 28, 4, Color3.fromRGB(255, 80, 170))
	elseif skin.Hat == "Crown" then
		block(22, 8, 36, 10, hatColor)
		for _, x in { 22, 36, 50 } do
			block(x, 0, 8, 10, hatColor)
		end
	elseif skin.Hat == "Shades" then
		block(22, 26, 36, 8, hatColor)
	end
end

-------------------------------------------------------------------------------
-- Rendering
-------------------------------------------------------------------------------

local previewConnection: RBXScriptConnection? = nil
local confirmUntil = 0

local function setButton(b: TextButton, label: string, color: Color3, enabled: boolean)
	b.Text = label
	b.BackgroundColor3 = if enabled then color else GREY
	b.Active = enabled
	b.AutoButtonColor = enabled
end

local function renderPreview(skinId: string?)
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	local source = lawyerModel(selectedDesk)
	if source then
		previewConnection = SkinLook.showInViewport(viewport, source, skinId)
	else
		viewport:ClearAllChildren()
	end
end

local render: () -> ()

local function renderDetail()
	local counts = owned()
	local skin = Formulas.getSkin(selectedSkin)
	local wearing = equippedOn(selectedDesk)
	if not skin then
		-- Nothing picked: show what the selected lawyer is wearing now.
		local current = Formulas.getSkin(wearing)
		detailName.Text = if current then current.Name else "Default Suit"
		detailPill.BackgroundColor3 = GREY
		detailPillText.Text = if current then "WEARING" else "NO SKIN"
		detailInfo.Text = "Pick a skin!"
		previewGradient.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255), Color3.fromRGB(200, 220, 240))
		setButton(equipButton, "EQUIP", GREEN, false)
		setButton(sellOneButton, "SELL 1", ORANGE, false)
		renderPreview(wearing)
		return
	end

	local count = counts[skin.Id] or 0
	local rarityName, rarityColor = rarityOf(skin)
	previewGradient.Color = ColorSequence.new(lighten(rarityColor, 0.75), lighten(rarityColor, 0.35))
	if count == 0 then
		detailName.Text = "???"
		detailPill.BackgroundColor3 = rarityColor
		detailPillText.Text = string.upper(rarityName)
		detailInfo.Text = "Hatch to find!"
		setButton(equipButton, "LOCKED", GREEN, false)
		setButton(sellOneButton, "SELL 1", ORANGE, false)
		viewport:ClearAllChildren()
		if previewConnection then
			previewConnection:Disconnect()
			previewConnection = nil
		end
		return
	end

	detailName.Text = skin.Name
	detailPill.BackgroundColor3 = rarityColor
	detailPillText.Text = string.upper(rarityName)
	detailInfo.Text = string.format("+%d%%  ·  x%d", math.round(Formulas.skinPayoutBonus(skin.Id) * 100), count)
	if wearing == skin.Id then
		setButton(equipButton, "UNEQUIP", ORANGE, true)
	else
		setButton(equipButton, "EQUIP", GREEN, true)
	end
	local value = Config.Eggs.Skins[skin.Rarity].SellValue
	if count > 1 then
		setButton(sellOneButton, "SELL 1  +" .. Formulas.formatCoins(value), ORANGE, true)
	else
		setButton(sellOneButton, "YOUR LAST ONE - KEEP IT!", ORANGE, false)
	end
	renderPreview(skin.Id)
end

local function renderTabs()
	for _, child in deskTabs:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if selectedDesk > deskCount() then
		selectedDesk = 1
	end
	for desk = 1, deskCount() do
		local tab = button({
			Size = UDim2.fromOffset(120, 36),
			BackgroundColor3 = if desk == selectedDesk then YELLOW else WHITE,
			Text = "Lawyer " .. desk,
			LayoutOrder = desk,
			Parent = deskTabs,
		})
		tab.TextColor3 = if desk == selectedDesk then WHITE else Color3.fromRGB(60, 60, 70)
		tab.TextStrokeTransparency = if desk == selectedDesk then 0 else 1
		tab.Activated:Connect(function()
			selectedDesk = desk
			render()
		end)
	end
end

local function renderGrid()
	for _, child in grid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local counts = owned()
	local wearing = equippedOn(selectedDesk)
	local found, extras, extrasValue = 0, 0, 0
	for index, skin in Config.SkinCatalog do
		local count = counts[skin.Id] or 0
		local isOwned = count > 0
		if isOwned then
			found += 1
			extras += count - 1
			extrasValue += (count - 1) * Config.Eggs.Skins[skin.Rarity].SellValue
		end
		local _, rarityColor = rarityOf(skin)
		local card = make("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = if isOwned then rarityColor else Color3.fromRGB(205, 205, 215),
			LayoutOrder = skin.Rarity * 100 + index,
			Parent = grid,
		}, { corner(0, 16) })
		local cardStroke = stroke(if skin.Id == selectedSkin then 5 else 3, true)
		cardStroke.Color = if skin.Id == selectedSkin then WHITE else BLACK
		cardStroke.Parent = card
		if isOwned then
			make("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(lighten(rarityColor, 0.45), rarityColor),
				Parent = card,
			})
		end
		drawIcon(card, skin, isOwned)
		text({
			Position = UDim2.new(0.05, 0, 1, -40),
			Size = UDim2.new(0.9, 0, 0, 32),
			Text = if isOwned then skin.Name else "???",
			Parent = card,
		}, 2)
		if count > 1 then
			local tag = make("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.fromOffset(40, 24),
				BackgroundColor3 = YELLOW,
				Parent = card,
			}, { corner(1), stroke(2, true) })
			text({ Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "x" .. count, Parent = tag }, 2)
		end
		if wearing == skin.Id then
			local check = make("Frame", {
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.fromOffset(28, 28),
				BackgroundColor3 = GREEN,
				Parent = card,
			}, { corner(1), stroke(2, true) })
			text({ Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = "✓", Parent = check }, 2)
		end
		card.Activated:Connect(function()
			selectedSkin = skin.Id
			render()
		end)
	end
	foundLabel.Text = string.format("%d / %d found", found, #Config.SkinCatalog)
	if os.clock() < confirmUntil and extras > 0 then
		setButton(sellExtrasButton, "TAP AGAIN TO SELL " .. extras .. "!", RED, true)
	else
		setButton(
			sellExtrasButton,
			if extras > 0 then string.format("SELL %d EXTRAS  +%s", extras, Formulas.formatCoins(extrasValue)) else "NO EXTRAS TO SELL",
			ORANGE,
			extras > 0
		)
	end
end

function render()
	if not panel.Visible then
		return
	end
	renderTabs()
	renderGrid()
	renderDetail()
end

local function popCoins(amount: number, from: GuiObject)
	coinPop.Text = "+" .. Formulas.formatCoins(amount) .. " coins!"
	coinPop.Position = UDim2.fromOffset(from.Position.X.Offset + from.Size.X.Offset / 2, from.Position.Y.Offset)
	coinPop.TextTransparency = 0
	coinPop.Visible = true
	tween(coinPop, 0.9, { Position = coinPop.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
	task.delay(0.9, function()
		coinPop.Visible = false
	end)
end

-------------------------------------------------------------------------------
-- Open / close and actions
-------------------------------------------------------------------------------

local function refreshBadge()
	badge.Visible = unseen > 0
	badgeText.Text = if unseen > 9 then "9+" else tostring(unseen)
end

local function open()
	local camera = workspace.CurrentCamera
	local fit = if camera then math.min(1, camera.ViewportSize.Y / 560, camera.ViewportSize.X / 820) else 1
	unseen = 0
	refreshBadge()
	MarkSkinsSeen:FireServer()
	selectedSkin = nil
	panel.Visible = true
	panelScale.Scale = 0
	-- Always fit on screen, even in tiny windows; a too-small panel beats one hanging off the edges.
	tween(panelScale, 0.35, { Scale = math.max(fit, 0.3) }, Enum.EasingStyle.Back)
	render()
end

local function close()
	tween(panelScale, 0.15, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(0.15, function()
		panel.Visible = false
		if previewConnection then
			previewConnection:Disconnect()
			previewConnection = nil
		end
		viewport:ClearAllChildren()
	end)
end

openButton.Activated:Connect(function()
	openScale.Scale = 0.88
	tween(openScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	if panel.Visible then
		close()
	else
		open()
	end
end)
closeButton.Activated:Connect(close)

equipButton.Activated:Connect(function()
	local skin = Formulas.getSkin(selectedSkin)
	if not skin or not equipButton.Active then
		return
	end
	if equippedOn(selectedDesk) == skin.Id then
		EquipSkin:FireServer(nil, selectedDesk)
	else
		EquipSkin:FireServer(skin.Id, selectedDesk)
	end
end)

sellOneButton.Activated:Connect(function()
	if not selectedSkin or not sellOneButton.Active then
		return
	end
	local earned = SellSkins:InvokeServer("one", selectedSkin)
	if typeof(earned) == "number" and earned > 0 then
		popCoins(earned, sellOneButton)
	end
end)

sellExtrasButton.Activated:Connect(function()
	if not sellExtrasButton.Active then
		return
	end
	if os.clock() >= confirmUntil then
		-- First tap arms it; a second tap within 3 seconds sells.
		confirmUntil = os.clock() + 3
		renderGrid()
		task.delay(3.05, function()
			if panel.Visible then
				renderGrid()
			end
		end)
		return
	end
	confirmUntil = 0
	local earned = SellSkins:InvokeServer("extras")
	if typeof(earned) == "number" and earned > 0 then
		popCoins(earned, sellExtrasButton)
	end
	renderGrid()
end)

-- Re-render when the server changes anything we show. The NEW count is saved server-side, so
-- it survives rejoining; while the panel is open, new hatches count as seen straight away.
local function onUnseenChanged()
	local value = player:GetAttribute("SkinsUnseen")
	unseen = if typeof(value) == "number" then value else 0
	if panel.Visible and unseen > 0 then
		unseen = 0
		MarkSkinsSeen:FireServer()
	end
	refreshBadge()
end
player:GetAttributeChangedSignal("SkinsUnseen"):Connect(onUnseenChanged)
onUnseenChanged()
player:GetAttributeChangedSignal("SkinsOwned"):Connect(render)
player:GetAttributeChangedSignal("DeskCount"):Connect(render)
player.AttributeChanged:Connect(function(name)
	if name:match("^Desk%d+Skin$") then
		render()
	end
end)
-- Gentle wiggle on the SKINS button while there's something new to look at.
RunService.RenderStepped:Connect(function()
	if unseen > 0 and not panel.Visible then
		openButton.Rotation = math.sin(os.clock() * 8) * 5
	else
		openButton.Rotation = 0
	end
end)
