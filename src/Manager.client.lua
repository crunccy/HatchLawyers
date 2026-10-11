--!strict
-- Manager Office screen. Opens from the "Manager Office" prompt on your firm's filing cabinet
-- (tagged ManagerPrompt by ManagerService). Hire the Manager, then buy the 5 firm-wide upgrades.
-- Reads the ManagerHired / ManagerLevels attributes; the server checks every purchase.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas"))
local Skin = require(ReplicatedStorage.Shared:WaitForChild("Skin")) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HireManager = Remotes:WaitForChild("HireManager") :: RemoteFunction
local BuyManagerUpgrade = Remotes:WaitForChild("BuyManagerUpgrade") :: RemoteFunction
local PrestigeRemote = Remotes:WaitForChild("Prestige") :: RemoteFunction

local player = Players.LocalPlayer

-- Shared.Skin look (2026-10-10 UI pass): gold header strip, dark studded body, dark rows, white outlined text.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = WHITE -- text sits on dark surfaces now
local MUTED = Skin.TextSoft
local ROW = Color3.fromHex("3A3D55")
local ROW_ALT = Color3.fromHex("34374D")
local GREEN = Color3.fromRGB(98, 205, 48)
local RED = Color3.fromRGB(240, 70, 70)
local GOLD = Color3.fromRGB(255, 200, 40)
local GRAY = Color3.fromRGB(170, 170, 182)
local PURPLE = Color3.fromRGB(110, 60, 200)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium) -- descriptions / small print (Shared.UIFonts)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy) -- big moments (Shared.UIFonts)

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(class)
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

local function corner(px: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, px) })
end

local function stroke(thickness: number): UIStroke
	return make("UIStroke", { Color = BLACK, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or INK
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
	if props.FontFace ~= BODY then -- headline text gets the ink outline
		make("UIStroke", { Thickness = math.clamp(math.floor(maxSize / 11), 1, 4), Color = Skin.Ink, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	end
	return l
end

-- chunky Skin-style button: the gradient multiplies BackgroundColor3, so render() can keep recolouring it
local function button(props: { [string]: any }, maxSize: number): TextButton
	props.FontFace = FONT
	props.TextScaled = true
	props.TextColor3 = WHITE
	props.TextStrokeTransparency = 0
	props.TextStrokeColor3 = Skin.Ink
	props.AutoButtonColor = false
	local b = make("TextButton", props, {
		corner(8),
		stroke(3),
		make("UITextSizeConstraint", { MaxTextSize = maxSize }),
		make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 7) }),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, Color3.new(0.94, 0.94, 0.94)), ColorSequenceKeypoint.new(1, Color3.new(0.74, 0.74, 0.74)),
		}) }),
	})
	b:SetAttribute("NoSkin", true)
	Skin.pressable(b)
	return b
end

---------------------------------------------------------------- layout (560x400, scaled to fit)
local gui = make("ScreenGui", { Name = "Manager", ResetOnSpawn = false, DisplayOrder = 16, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local dim = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, Parent = gui })
dim:SetAttribute("NoSkin", true)
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 470),
	BackgroundColor3 = Skin.Panel,
	Parent = gui,
}, { corner(10), make("UIStroke", { Color = Skin.Ink, Thickness = 5 }), panelScale })
panel:SetAttribute("NoSkin", true)
Skin.studs(panel, 0.93, nil, 30)
local sw = Skin.swatch("Gold")
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = WHITE, ZIndex = 1, Parent = panel }, {
	corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
})
make("Frame", { Position = UDim2.new(0, -4, 1, 0), Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = Skin.Ink, BorderSizePixel = 0, Parent = header })
Skin.studs(header, 0.86, nil, 26)
Skin.shineBands(header, 0.84)
Skin.text({ Position = UDim2.fromOffset(18, 6), Size = UDim2.fromOffset(300, 52), Text = "Manager Office", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = header }, 44, 4)
-- Prestige: only shows once the firm is at the top tier
local supremeButton = button({ Name = "SupremeButton", Position = UDim2.fromOffset(318, 13), Size = UDim2.fromOffset(160, 42), BackgroundColor3 = GOLD, Visible = false, ZIndex = 3, Parent = panel }, 20)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 210, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 255)),
	}),
	Parent = supremeButton,
})
local supremeArmedUntil = 0
local subtitle = text({ FontFace = BODY, Position = UDim2.fromOffset(24, 80), Size = UDim2.fromOffset(500, 20), TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 17)
local closeButton = Skin.closeButton(header, 52, 3)

-- not hired yet
local hireCard = make("Frame", { Name = "HireCard", Position = UDim2.fromOffset(40, 118), Size = UDim2.fromOffset(480, 300), BackgroundColor3 = ROW, Parent = panel }, { corner(10), stroke(3) })
text({ Position = UDim2.fromOffset(20, 18), Size = UDim2.fromOffset(440, 44), Text = "Hire a Manager!", Parent = hireCard }, 36)
text({
	Position = UDim2.fromOffset(20, 66),
	Size = UDim2.fromOffset(440, 96),
	TextWrapped = true,
	TextColor3 = MUTED,
	Text = "A smart Manager runs your firm better. Unlock 5 upgrades that help ALL your lawyers forever: faster cases, more wins, rarer clients and more!",
	Parent = hireCard,
}, 20)
local hireButton = button({ Name = "HireButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 180), Size = UDim2.fromOffset(300, 64), BackgroundColor3 = GREEN, Parent = hireCard }, 28)

-- hired: one row per upgrade
type Row = { frame: Frame, name: TextLabel, effect: TextLabel, pips: TextLabel, buy: TextButton, id: string }
local rows: { Row } = {}
local list = make("Frame", { Name = "Upgrades", Position = UDim2.fromOffset(20, 108), Size = UDim2.fromOffset(520, 340), BackgroundTransparency = 1, Parent = panel })
for i, def in Config.Manager.Upgrades do
	local frame = make("Frame", { Name = def.Id, Position = UDim2.fromOffset(0, (i - 1) * 68), Size = UDim2.fromOffset(520, 60), BackgroundColor3 = if i % 2 == 0 then ROW_ALT else ROW, Parent = list }, { corner(8), stroke(3) })
	make("Frame", { Name = "Bevel", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, Parent = frame },
		{ corner(6), make("UIStroke", { Thickness = 1.5, Color = Color3.fromHex("5A5E80"), Transparency = 0.3 }) })
	rows[i] = {
		id = def.Id,
		frame = frame,
		name = text({ Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(220, 24), TextXAlignment = Enum.TextXAlignment.Left, Text = def.Name, Parent = frame }, 20),
		effect = text({ FontFace = BODY, Position = UDim2.fromOffset(12, 28), Size = UDim2.fromOffset(250, 20), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = MUTED, Parent = frame }, 15),
		pips = text({ Position = UDim2.fromOffset(268, 14), Size = UDim2.fromOffset(110, 30), TextColor3 = Color3.fromHex("D29BFF"), Parent = frame }, 22),
		buy = button({ Name = "Buy", Position = UDim2.fromOffset(388, 8), Size = UDim2.fromOffset(122, 44), BackgroundColor3 = GREEN, Parent = frame }, 20),
	}
end

---------------------------------------------------------------- rendering
local message: { [string]: string } = {}

local function levels(): { [string]: number }
	local raw = player:GetAttribute("ManagerLevels")
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and typeof(decoded) == "table" then decoded else {}
end

local function render()
	if not gui.Enabled then
		return
	end
	local hired = player:GetAttribute("ManagerHired") == true
	local coins = player:GetAttribute("Coins") or 0
	-- going Supreme moved to its own SUPREME tile in the HUD menu (StarterPlayerScripts.Supreme, economy pass
	-- 2026-10-09): this button stays hidden
	local eligible = false
	local armed = os.clock() < supremeArmedUntil
	supremeButton.Visible = eligible
	supremeButton.Text = if armed then "TAP AGAIN!" else "GO SUPREME ★"
	hireCard.Visible = not hired
	list.Visible = hired
	if not hired then
		subtitle.Text = "Your firm needs a boss!"
		local cost = Config.Manager.HireCost
		hireButton.Text = message.hire or ("HIRE · " .. Formulas.formatCoins(cost))
		hireButton.BackgroundColor3 = if message.hire then GRAY elseif coins >= cost then GREEN else GRAY
		return
	end
	subtitle.Text = if armed
		then string.format("Resets coins, offices & Manager. Keeps your lawyers. x%s payouts forever!", tostring(Formulas.prestigeMultiplier((player:GetAttribute("PrestigeLevel") or 0) + 1)))
		else "Upgrades help every lawyer in your firm, forever."
	local current = levels()
	for _, row in rows do
		local def = Formulas.getManagerUpgrade(row.id) :: { [string]: any }
		local level = current[row.id] or 0
		row.pips.Text = string.rep("●", level) .. string.rep("○", def.MaxLevel - level)
		if level >= def.MaxLevel then
			row.effect.Text = Formulas.describeManagerUpgrade(row.id, level)
			row.buy.Text = message[row.id] or "MAX"
			row.buy.BackgroundColor3 = GOLD
		else
			local cost = Formulas.managerUpgradeCost(row.id, level)
			row.effect.Text = if level == 0
				then "Next: " .. Formulas.describeManagerUpgrade(row.id, 1)
				else Formulas.describeManagerUpgrade(row.id, level) .. "  →  " .. Formulas.describeManagerUpgrade(row.id, level + 1):match("%d+%.?%d*%%")
			row.buy.Text = message[row.id] or Formulas.formatCoins(cost)
			row.buy.BackgroundColor3 = if message[row.id] then GRAY elseif coins >= cost then GREEN else GRAY
		end
	end
end

local function flash(key: string, textValue: string)
	message[key] = textValue
	render()
	task.delay(1.2, function()
		if message[key] == textValue then
			message[key] = nil
			render()
		end
	end)
end

local function fit(): number
	local camera = workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	if size.Y < 200 then
		return 1
	end
	return math.clamp(math.min(size.Y / 540, size.X / 620), 0.5, 1)
end

local function open()
	gui.Enabled = true
	panelScale.Scale = 0
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit() }):Play()
	render()
end

local function close()
	gui.Enabled = false
end

supremeButton.Activated:Connect(function()
	if os.clock() >= supremeArmedUntil then
		supremeArmedUntil = os.clock() + 4 -- first tap arms it, a second tap within 4s confirms
		render()
		task.delay(4.05, render)
		return
	end
	supremeArmedUntil = 0
	local ok, reason = PrestigeRemote:InvokeServer()
	if ok then
		close()
	else
		subtitle.Text = reason or "Can't go Supreme yet"
	end
end)

closeButton.Activated:Connect(close)
dim.Activated:Connect(close)

hireButton.Activated:Connect(function()
	local ok, reason = HireManager:InvokeServer()
	if ok then
		flash("hire", "HIRED!")
	else
		flash("hire", string.upper(reason or "Can't hire"))
	end
end)

for _, row in rows do
	row.buy.Activated:Connect(function()
		local ok, reason = BuyManagerUpgrade:InvokeServer(row.id)
		flash(row.id, if ok then "BOUGHT!" else string.upper(reason or "Can't buy"))
	end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if CollectionService:HasTag(prompt, "ManagerPrompt") then
		open()
	end
end)

player.AttributeChanged:Connect(function(name)
	if name == "Coins" or name == "ManagerHired" or name == "ManagerLevels" then
		render()
	end
end)
