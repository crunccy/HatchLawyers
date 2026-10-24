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
local menuEntry = HudMenu.button({ name = "Supreme", label = "REBIRTH", icon = "Rebirth", color = Color3.fromRGB(255, 160, 30), order = 4 })

------------------------------------------------------------------ the panel (UI v3, 2026-10-23: docs/UI_STYLE_V3.md)
-- A Skin.window (purple striped header, the Rebirth icon popping out, deep purple body, blur, chat box steps aside):
-- the multiplier now -> next on a gold card with a turning sunburst, two requirement bars (striped green fills), what
-- resets / what you keep, and one big two-tap button (Skin.button: glint when ready, muted purple until then).
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local win = Skin.window({ Name = "Supreme", Title = "Rebirth", Color = "Purple", Icon = HudMenu.Icons.Rebirth, Size = Vector2.new(W, H + 40), DisplayOrder = 32 })
local gui = win.gui
local body = win.body :: Frame

-- multiplier now -> next
local multRow = Skin.card(body, { Name = "Multiplier", Color = "Gold", Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -40, 0, 96), GlowAt = Vector2.new(0.5, 0.45) })
local mz = multRow.ZIndex + 3
local nowLabel = text({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(0.42, -10, 0, 50), Text = "x1", FontFace = TITLE, TextColor3 = WHITE, ZIndex = mz, Parent = multRow }, 44)
local arrow = text({ Position = UDim2.new(0.42, 0, 0, 8), Size = UDim2.new(0.16, 0, 0, 50), Text = "→", FontFace = TITLE, TextColor3 = WHITE, ZIndex = mz, Parent = multRow }, 40)
local nextLabel = text({ Position = UDim2.new(0.58, 0, 0, 8), Size = UDim2.new(0.42, -10, 0, 50), Text = "x2", FontFace = TITLE, TextColor3 = Color3.fromRGB(125, 255, 60), ZIndex = mz, Parent = multRow }, 52)
Skin.breathe(nextLabel, 3, 0.5)
local _ = arrow
local levelLabel = text({ Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 24), FontFace = BODY, Text = "", TextColor3 = WHITE, ZIndex = mz, Parent = multRow }, 18, 2)

-- requirements
local function requirementRow(y: number, title: string): (TextLabel, Frame)
	local row = make("Frame", { Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 56), BackgroundTransparency = 1, ZIndex = 3, Parent = body })
	text({ Size = UDim2.new(0.5, 0, 0, 24), Text = title, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = row }, 20)
	local amount = text({ Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 0, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = row }, 20)
	local track = make("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Skin.PanelDeep, ZIndex = 3, Parent = row }, { corner(11), stroke(3) })
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4, Parent = track }, {
		corner(11), make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(170, 255, 140), Color3.fromRGB(60, 190, 40)) }),
	})
	Skin.stripes(fill, 0.75, 4, 0.06)
	return amount, fill
end
local coinsAmount, coinsFill = requirementRow(118, "Coins")
local officesAmount, officesFill = requirementRow(182, "Offices with a lawyer")
text({ Position = UDim2.fromOffset(20, 246), Size = UDim2.new(1, -40, 0, 44), FontFace = BODY, TextWrapped = true, TextColor3 = SOFT, ZIndex = 3,
	Text = "Starts your firm over: coins, office levels, firm size and the Manager reset. You KEEP every lawyer you own - and payouts stay boosted forever!",
	Parent = body }, 17, 0)
local go = Skin.button({ Parent = body, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(340, 62),
	Style = "Green", Text = "REBIRTH!", TextSize = 32, Glint = true, ZIndex = 4 })
local goButton = go.button

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
	levelLabel.Text = if level > 0 then string.format("Rebirth %d · payouts x%s now", level, tostring(Formulas.prestigeMultiplier(level))) else "Your first rebirth makes every case pay more!"
	coinsAmount.Text = string.format("%s / %s", Formulas.formatCoins(math.min(coins, cost)), Formulas.formatCoins(cost))
	coinsAmount.TextColor3 = if coins >= cost then GREEN else WHITE
	coinsFill.Size = UDim2.fromScale(math.clamp(coins / math.max(cost, 1), 0, 1), 1)
	officesAmount.Text = string.format("%d / %d", math.min(working, offices), offices)
	officesAmount.TextColor3 = if working >= offices then GREEN else WHITE
	officesFill.Size = UDim2.fromScale(math.clamp(working / math.max(offices, 1), 0, 1), 1)
	local armed = os.clock() < armedUntil
	if message then
		go.setText(message)
		go.setState("disabled")
	elseif not ready then
		go.setText(if working < offices then "EXPAND + EQUIP LAWYERS" else "SAVE UP COINS")
		go.setState("disabled", if working < offices then "Equip a lawyer in more offices first!" else "Save up more coins first!")
	else
		go.setText(if armed then "TAP AGAIN TO CONFIRM" else "REBIRTH!")
		go.setStyle(if armed then "Gold" else "Green")
		go.setState("default")
	end
	goButton:SetAttribute("Ready", ready)
end

local function open()
	armedUntil = 0
	message = nil
	win.open()
	render()
end
local function close()
	win.hide()
end

menuEntry.button.Activated:Connect(function()
	if gui.Enabled then
		close()
	else
		open()
	end
end)
goButton.Activated:Connect(function()
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
