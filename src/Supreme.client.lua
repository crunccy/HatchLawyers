--!strict
-- SUPREME (prestige, "Supreme Empire") - economy pass 2026-10-09: like the Rebirth button in Steal a Brainrot /
-- Pet Sim, it lives in the HUD's menu column (Shared.HudMenu, "!" when you can go) instead of inside the Manager
-- panel. The panel shows the payout multiplier now -> next, both requirements with progress bars (coins, offices
-- with a lawyer in them; Formulas.prestigeRequirement), what resets and what you keep, and a two-tap button.
-- The server checks everything (Server.PrestigeService, Remotes.Prestige); the reward toast is Rewards'.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local PrestigeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Prestige") :: RemoteFunction

local FONT = UIFonts.PrimaryFace
local TITLE = UIFonts.TitleFace
local BODY = UIFonts.BodyFace
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local PURPLE = Color3.fromRGB(176, 52, 255)
local PURPLE_DARK = Color3.fromRGB(122, 30, 214)
local PANEL = Color3.fromRGB(46, 44, 66)
local SLOT = Color3.fromRGB(32, 31, 47)
local GREEN = Color3.fromRGB(76, 224, 48)
local GOLD = Color3.fromRGB(255, 200, 40)
local RED = Color3.fromRGB(228, 32, 32)
local GRAY = Color3.fromRGB(120, 120, 135)
local SOFT = Color3.fromRGB(205, 200, 235)
local W, H = 560, 430

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
local function text(props: { [string]: any }, maxSize: number, outline: number?): TextLabel
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
	local o = outline or math.max(2, math.floor(maxSize / 10))
	if o > 0 then
		make("UIStroke", { Thickness = o, Color = BLACK, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	end
	return l
end
local function studs(parent: GuiObject, transparency: number)
	local c = parent:FindFirstChildOfClass("UICorner")
	make("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = HudMenu.Studs, ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(34, 34), ZIndex = parent.ZIndex, Parent = parent,
	}, { make("UICorner", { CornerRadius = if c then c.CornerRadius else UDim.new() }) })
end
local function squish(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = gui })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

------------------------------------------------------------------ the tile
local menuEntry = HudMenu.button({ name = "Supreme", label = "SUPREME", icon = "Trophy", color = Color3.fromRGB(255, 160, 30), order = 4 })

------------------------------------------------------------------ the panel
local gui = make("ScreenGui", { Name = "Supreme", ResetOnSpawn = false, DisplayOrder = 18, Enabled = false, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
local shade = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, Parent = gui })
shade:SetAttribute("NoSkin", true)
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundColor3 = PANEL, Active = true, Parent = gui,
}, { corner(10), stroke(6), panelScale })
panel:SetAttribute("NoSkin", true)
studs(panel, 0.9)
local header = make("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(10), make("UIGradient", { Color = ColorSequence.new(PURPLE, PURPLE_DARK) }),
})
make("Frame", { Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = PURPLE_DARK, BorderSizePixel = 0, ZIndex = 2, Parent = header })
make("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(58, 58), BackgroundTransparency = 1, Image = HudMenu.Icons.Trophy, ZIndex = 3, Parent = header })
text({ Position = UDim2.fromOffset(76, 8), Size = UDim2.new(1, -170, 0, 54), FontFace = TITLE, Text = "Supreme Empire", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = header }, 44)
local closeButton = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(60, 54), BackgroundColor3 = RED, Text = "", AutoButtonColor = true, ZIndex = 3, Parent = header,
}, { corner(6), stroke(4) })
text({ Size = UDim2.fromScale(1, 1), Text = "X", FontFace = TITLE, ZIndex = 4, Parent = closeButton }, 42)

-- multiplier now -> next
local multRow = make("Frame", { Position = UDim2.fromOffset(20, 84), Size = UDim2.new(1, -40, 0, 86), BackgroundColor3 = SLOT, Parent = panel }, { corner(8), stroke(4) })
local nowLabel = text({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(0.42, -10, 0, 48), Text = "x1", FontFace = TITLE, TextColor3 = SOFT, Parent = multRow }, 44)
text({ Position = UDim2.new(0.42, 0, 0, 6), Size = UDim2.new(0.16, 0, 0, 48), Text = "→", FontFace = TITLE, TextColor3 = GOLD, Parent = multRow }, 40)
local nextLabel = text({ Position = UDim2.new(0.58, 0, 0, 6), Size = UDim2.new(0.42, -10, 0, 48), Text = "x2", FontFace = TITLE, TextColor3 = GREEN, Parent = multRow }, 48)
local levelLabel = text({ Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 24), FontFace = BODY, Text = "", TextColor3 = SOFT, Parent = multRow }, 18, 0)

-- requirements
local function requirementRow(y: number, title: string): (TextLabel, Frame)
	local row = make("Frame", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 56), BackgroundTransparency = 1, Parent = panel })
	text({ Size = UDim2.new(0.5, 0, 0, 24), Text = title, TextXAlignment = Enum.TextXAlignment.Left, Parent = row }, 20)
	local amount = text({ Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 0, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Right, Parent = row }, 20)
	local track = make("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Color3.fromRGB(24, 22, 36), Parent = row }, { corner(10), stroke(3) })
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, {
		corner(10), make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(170, 255, 140), Color3.fromRGB(60, 190, 40)) }),
	})
	return amount, fill
end
local coinsAmount, coinsFill = requirementRow(184, "Coins")
local officesAmount, officesFill = requirementRow(246, "Offices with a lawyer")
text({ Position = UDim2.fromOffset(20, 308), Size = UDim2.new(1, -40, 0, 40), FontFace = BODY, TextWrapped = true, TextColor3 = SOFT,
	Text = "Starts your firm over: coins, office levels, firm size and the Manager reset. You KEEP every lawyer you own - and payouts stay boosted forever!",
	Parent = panel }, 17, 0)
local goButton = make("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(300, 58), BackgroundColor3 = GREEN, Text = "", AutoButtonColor = true, Parent = panel,
}, { corner(10), stroke(4) })
studs(goButton, 0.86)
local goLabel = text({ Size = UDim2.fromScale(1, 1), Text = "GO SUPREME!", FontFace = TITLE, ZIndex = 2, Parent = goButton }, 34)

------------------------------------------------------------------ state
local armedUntil = 0
local busy = false
local message: string? = nil

local function state(): (number, number, number, number, number)
	local level = (player:GetAttribute("PrestigeLevel") :: number?) or 0
	local cost, offices = Formulas.prestigeRequirement(level)
	local coins = (player:GetAttribute("Coins") :: number?) or 0
	local working = (player:GetAttribute("LawyerCount") :: number?) or 0
	return level, cost, offices, coins, working
end

local function render()
	local level, cost, offices, coins, working = state()
	local ready = coins >= cost and working >= offices
	menuEntry.setAlert(ready)
	if not gui.Enabled then
		return
	end
	nowLabel.Text = "x" .. tostring(Formulas.prestigeMultiplier(level))
	nextLabel.Text = "x" .. tostring(Formulas.prestigeMultiplier(level + 1))
	levelLabel.Text = if level > 0 then string.format("Supreme level %d · payouts x%s now", level, tostring(Formulas.prestigeMultiplier(level))) else "Your first Supreme makes every case pay more!"
	coinsAmount.Text = string.format("%s / %s", Formulas.formatCoins(math.min(coins, cost)), Formulas.formatCoins(cost))
	coinsAmount.TextColor3 = if coins >= cost then GREEN else WHITE
	coinsFill.Size = UDim2.fromScale(math.clamp(coins / math.max(cost, 1), 0, 1), 1)
	officesAmount.Text = string.format("%d / %d", math.min(working, offices), offices)
	officesAmount.TextColor3 = if working >= offices then GREEN else WHITE
	officesFill.Size = UDim2.fromScale(math.clamp(working / math.max(offices, 1), 0, 1), 1)
	local armed = os.clock() < armedUntil
	if message then
		goLabel.Text = message
	elseif not ready then
		goLabel.Text = if working < offices then "EXPAND + EQUIP LAWYERS" else "SAVE UP COINS"
	else
		goLabel.Text = if armed then "TAP AGAIN TO CONFIRM" else "GO SUPREME!"
	end
	goButton.BackgroundColor3 = if ready then (if armed then GOLD else GREEN) else GRAY
	goButton:SetAttribute("Ready", ready)
end

local function fit(): number
	local camera = workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return math.clamp(math.min((view.X - 24) / W, (view.Y - 24) / H), 0.4, 1)
end

local function open()
	gui.Enabled = true
	armedUntil = 0
	message = nil
	local s = fit()
	panelScale.Scale = s * 0.6
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = s }):Play()
	render()
end
local function close()
	gui.Enabled = false
end

menuEntry.button.Activated:Connect(function()
	if gui.Enabled then
		close()
	else
		open()
	end
end)
closeButton.Activated:Connect(function()
	squish(closeButton)
	close()
end)
shade.Activated:Connect(close)

goButton.Activated:Connect(function()
	squish(goButton)
	if busy or not goButton:GetAttribute("Ready") then
		return
	end
	if os.clock() >= armedUntil then
		armedUntil = os.clock() + 4 -- first tap arms it, a second tap within 4 s confirms
		render()
		task.delay(4.05, render)
		return
	end
	armedUntil = 0
	busy = true
	local ok, reason = PrestigeRemote:InvokeServer()
	busy = false
	if ok then
		close()
	else
		message = string.upper(reason or "Not yet!")
		render()
		task.delay(2, function()
			message = nil
			render()
		end)
	end
end)

player.AttributeChanged:Connect(function(name)
	if name == "Coins" or name == "LawyerCount" or name == "PrestigeLevel" then
		render()
	end
end)
render()
