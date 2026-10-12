--!strict
-- Daily streak calendar, playtime gift countdown and reward pop-ups (server: RewardsService).
-- Also pings Remotes.Activity on input so only active play counts toward playtime gifts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas"))
local ArtAssets = require(ReplicatedStorage.Shared:WaitForChild("ArtAssets")) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimDaily = Remotes:WaitForChild("ClaimDaily") :: RemoteFunction
local Activity = Remotes:WaitForChild("Activity") :: RemoteEvent
local RewardGranted = Remotes:WaitForChild("RewardGranted") :: RemoteEvent

local player = Players.LocalPlayer

-- Same cartoon palette as the HUD.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local MUTED = Color3.fromRGB(105, 105, 120)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local RED = Color3.fromRGB(240, 70, 70)
local GOLD = Color3.fromRGB(255, 200, 40)
local GRAY = Color3.fromRGB(170, 170, 182)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium) -- descriptions / small print (Shared.UIFonts)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy) -- big moments (Shared.UIFonts)
local DAY = 86400

---------------------------------------------------------------- activity pings
local lastPing = 0
local function ping()
	local now = os.clock()
	if now - lastPing >= 20 then
		lastPing = now
		Activity:FireServer()
	end
end
UserInputService.InputBegan:Connect(ping)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		ping()
	end
end)

---------------------------------------------------------------- helpers
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
	return make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
end

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function serverDay(): number
	return workspace:GetServerTimeNow() // DAY
end

-- What the calendar should show: which day is next, how many are ticked, can we claim now.
local function dailyState(): (number, number, boolean)
	local lastDay = player:GetAttribute("DailyLastDay")
	local streak = player:GetAttribute("DailyStreak") or 0
	if typeof(lastDay) ~= "number" then
		return 1, 0, false
	end
	local cycle = #Config.Rewards.Daily
	local today = serverDay()
	if lastDay >= today then
		local ticked = ((streak - 1) % cycle) + 1
		return (ticked % cycle) + 1, ticked, false
	end
	local continues = lastDay == today - 1
	local next = if continues then (streak % cycle) + 1 else 1
	return next, if continues then next - 1 else 0, true
end

local function rewardText(reward: { [string]: any }): string
	if reward.Kind == "Coins" then
		local perMinute = player:GetAttribute("CoinsPerMinute") or 0
		return Formulas.formatCoins(math.max(Config.Rewards.MinCoins, perMinute * reward.Minutes)) .. "\nCOINS"
	elseif reward.Kind == "Egg" then -- (egg days show the egg's picture above one line of text)
		return if reward.Count > 1 then reward.Count .. " EGGS" else "FREE EGG"
	elseif reward.Kind == "RareEgg" then
		return "RARE EGG!"
	elseif reward.Kind == "SkillRoll" then
		return "SKILL\nROLL"
	end
	return ""
end

---------------------------------------------------------------- left-edge DAILY tile
local gui = make("ScreenGui", { Name = "Rewards", ResetOnSpawn = false, DisplayOrder = 40, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") }) -- above BigCase (30) banners and every window (32-33): reward pop-ups show over the Shop
-- the DAILY tile lives in the shared left-edge menu column (Shared.HudMenu): real gift icon, "!" badge when a
-- daily reward is waiting, the playtime-gift countdown in a pill under it (UI pass 2026-10-09)
local HudMenu = require(ReplicatedStorage.Shared:WaitForChild("HudMenu")) :: any
local menuEntry = HudMenu.button({ name = "Daily", label = "DAILY", icon = "Gift", color = ORANGE, order = 1 })
local dailyButton = menuEntry.button

---------------------------------------------------------------- calendar panel (Shared.Skin look, 2026-10-11 UI pass)
-- Reference (user's recording): glossy header strip + red X over a dark studded body; the 7 days are chunky
-- tiles in a row (claimed = green, today = gold and bouncing, later = navy), each with a picture of its reward.
local Skin = require(ReplicatedStorage.Shared:WaitForChild("Skin")) :: any
local Icons = HudMenu.Icons
local PW, PH = 680, 420
local NAVY = Color3.fromHex("3A3D55")
local overlay = make("Frame", { Name = "Calendar", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
overlay:SetAttribute("NoSkin", true)
local dim = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, Parent = overlay })
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(PW, PH),
	BackgroundColor3 = Skin.Panel, Active = true, Parent = overlay, -- Active: taps on the panel don't close it
}, { corner(10), make("UIStroke", { Color = Skin.Ink, Thickness = 5 }), panelScale })
Skin.studs(panel, 0.93, nil, 30)
make("Frame", { Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = panel },
	{ corner(8), make("UIStroke", { Thickness = 2, Color = Color3.fromHex("4A4D66"), Transparency = 0.2 }) })
local sw = Skin.swatch("Orange")
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 66), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
})
make("Frame", { Position = UDim2.new(0, -4, 1, 0), Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = Skin.Ink, BorderSizePixel = 0, ZIndex = 3, Parent = header })
Skin.studs(header, 0.86, nil, 26)
Skin.shineBands(header, 0.84)
make("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1,
	Image = Icons.Gift, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = header })
Skin.text({ Position = UDim2.fromOffset(76, 6), Size = UDim2.fromOffset(400, 54), Text = "Daily Rewards", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header }, 50, 5)
local closeButton = Skin.closeButton(header, 54, 4)
local streakLabel = Skin.text({ Position = UDim2.fromOffset(24, 80), Size = UDim2.new(1, -48, 0, 28), FontFace = Skin.Fonts.Title, TextColor3 = Skin.Palette.Gold.light, Parent = panel }, 24, 2)

type Tile = { frame: Frame, day: TextLabel, reward: TextLabel, check: TextLabel, scale: UIScale, today: Frame }
local tiles: { Tile } = {}
local TW, TG = 86, 8
local x0 = (PW - (#Config.Rewards.Daily * TW + (#Config.Rewards.Daily - 1) * TG)) / 2
for i, reward in Config.Rewards.Daily do
	local scale = make("UIScale", {})
	local frame = make("Frame", {
		Name = "Day" .. i, Position = UDim2.fromOffset(x0 + (i - 1) * (TW + TG), 118), Size = UDim2.fromOffset(TW, 170), BackgroundColor3 = NAVY, Parent = panel,
	}, {
		corner(8), make("UIStroke", { Color = Skin.Ink, Thickness = 3 }), scale,
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, Color3.new(0.92, 0.92, 0.92)), ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7)),
		}) }),
	})
	Skin.studs(frame, 0.88, nil, 22)
	make("Frame", { Name = "Bevel", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, Parent = frame },
		{ corner(6), make("UIStroke", { Thickness = 1.5, Color = WHITE, Transparency = 0.65 }) })
	-- the reward's picture: coins, the egg (Blender render), a star for a skill roll
	local art = if reward.Kind == "RareEgg" then ArtAssets.Eggs.Rare elseif reward.Kind == "Egg" then ArtAssets.Eggs.Briefcase
		elseif reward.Kind == "Coins" then Icons.Coin else Icons.Star
	local count = if reward.Kind == "Egg" then math.min(reward.Count or 1, 2) else 1
	for k = 1, count do
		make("ImageLabel", {
			Name = "Art", BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, if count > 1 then (k - 1.5) * 22 else 0, 0, 80 + (if count > 1 then (k - 1) * 6 else 0)),
			Size = UDim2.fromOffset(if count > 1 then 52 else 66, if count > 1 then 52 else 66), Parent = frame,
		})
	end
	local today = make("Frame", { Name = "Today", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(70, 22),
		BackgroundColor3 = Skin.Palette.Red.base, Visible = false, ZIndex = 5, Parent = frame }, { corner(11), make("UIStroke", { Color = Skin.Ink, Thickness = 2 }) })
	Skin.text({ Size = UDim2.fromScale(1, 1), Text = "TODAY", FontFace = Skin.Fonts.Number, ZIndex = 6, Parent = today }, 16, 2)
	tiles[i] = {
		frame = frame,
		scale = scale,
		today = today,
		day = Skin.text({ Position = UDim2.fromOffset(4, 12), Size = UDim2.new(1, -8, 0, 26), Text = "Day " .. i, ZIndex = 3, Parent = frame }, 22, 3),
		reward = Skin.text({ Position = UDim2.fromOffset(4, 120), Size = UDim2.new(1, -8, 0, 40), Text = "", TextWrapped = true, ZIndex = 3, Parent = frame }, 18, 2),
		check = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(34, 34), Text = "",
			FontFace = Skin.Fonts.Number, TextColor3 = Skin.Palette.Green.light, ZIndex = 6, Parent = frame }, 34, 3),
	}
end

-- claim: a chunky Skin-style button whose gradient multiplies its colour (render() recolours it)
local claimButton = make("TextButton", {
	Name = "ClaimButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 302), Size = UDim2.fromOffset(360, 60),
	BackgroundColor3 = GREEN, FontFace = Skin.Fonts.Title, TextScaled = true, TextColor3 = WHITE, TextStrokeTransparency = 0, TextStrokeColor3 = Skin.Ink,
	AutoButtonColor = false, Parent = panel,
}, {
	corner(8), make("UIStroke", { Color = Skin.Ink, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	make("UITextSizeConstraint", { MaxTextSize = 28 }),
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }),
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.5, Color3.new(0.94, 0.94, 0.94)), ColorSequenceKeypoint.new(1, Color3.new(0.72, 0.72, 0.72)),
	}) }),
})
Skin.pressable(claimButton)
local giftLine = Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 374), Size = UDim2.fromOffset(600, 26), FontFace = Skin.Fonts.Body,
	TextColor3 = Skin.TextSoft, Parent = panel }, 20, 0)

---------------------------------------------------------------- reward pop-up
local toastScale = make("UIScale", { Scale = 0 })
local toast = make("Frame", {
	Name = "RewardToast",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(340, 100),
	BackgroundColor3 = GOLD,
	Visible = false,
	ZIndex = 20,
	Parent = gui,
}, {
	corner(10), make("UIStroke", { Color = Skin.Ink, Thickness = 4 }), toastScale,
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Skin.Palette.Gold.light), ColorSequenceKeypoint.new(0.55, Skin.Palette.Gold.base), ColorSequenceKeypoint.new(1, Skin.Palette.Gold.dark),
	}) }),
})
toast.BackgroundColor3 = WHITE -- (the gradient carries the gold)
toast:SetAttribute("NoSkin", true)
Skin.studs(toast, 0.86, nil, 24)
make("Frame", { Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 20, Parent = toast },
	{ corner(8), make("UIStroke", { Thickness = 2, Color = WHITE, Transparency = 0.5 }) })
local toastTitle = Skin.text({ Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(320, 44), FontFace = Skin.Fonts.Title, ZIndex = 21, Parent = toast }, 38, 4)
local toastBody = Skin.text({ Position = UDim2.fromOffset(10, 54), Size = UDim2.fromOffset(320, 36), FontFace = Skin.Fonts.Title, ZIndex = 21, Parent = toast }, 26, 3)
local toastToken = 0
local Effects = require(ReplicatedStorage.Shared:WaitForChild("Effects")) :: any

local function showToast(title: string, body: string)
	toastToken += 1
	local token = toastToken
	toastTitle.Text = title
	toastBody.Text = body
	toast.Visible = true
	toastScale.Scale = 0.3
	TweenService:Create(toastScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	-- every reward is a big moment: gold sunburst + twinkles behind the pop-up (Shared.Effects)
	Effects.guiBurst(toast.Parent, toast.Position, 420, Effects.GOLD, 2.4, 19)
	task.delay(2.6, function()
		if token == toastToken then
			local out = TweenService:Create(toastScale, TweenInfo.new(0.2), { Scale = 0 })
			out:Play()
			out.Completed:Wait()
			if token == toastToken then
				toast.Visible = false
			end
		end
	end)
end

---------------------------------------------------------------- rendering
local claiming = false
local claimMessage: string? = nil

local function render()
	local nextIndex, ticked, canClaim = dailyState()
	menuEntry.setBadge(if canClaim then "!" else nil)

	local active = player:GetAttribute("PlaytimeActive") or 0
	local left = Config.Rewards.PlaytimeInterval - active
	menuEntry.setNote(clock(left))

	if not overlay.Visible then
		return
	end
	local streak = player:GetAttribute("DailyStreak") or 0
	streakLabel.Text = if streak > 0
		then string.format("Streak: %d day%s! Miss a day and it starts over.", streak, if streak == 1 then "" else "s")
		else "Come back every day for bigger rewards!"
	for i, tile in tiles do
		local done = i <= ticked
		local isNext = i == nextIndex
		tile.reward.Text = rewardText(Config.Rewards.Daily[i])
		tile.frame.BackgroundColor3 = if done then Skin.Palette.Green.base elseif isNext then Skin.Palette.Gold.base else NAVY
		tile.check.Text = if done then "✓" else ""
		tile.today.Visible = isNext and canClaim
		tile.scale.Scale = if isNext and canClaim then 1 + math.sin(os.clock() * 5) * 0.05 else 1
	end
	if claimMessage then
		claimButton.Text = claimMessage
		claimButton.BackgroundColor3 = GRAY
	elseif canClaim then
		claimButton.Text = "CLAIM DAY " .. nextIndex .. "!"
		claimButton.BackgroundColor3 = GREEN
	else
		local untilReset = (serverDay() + 1) * DAY - workspace:GetServerTimeNow()
		claimButton.Text = "NEXT REWARD IN " .. clock(untilReset)
		claimButton.BackgroundColor3 = GRAY
	end
	giftLine.Text = string.format("Playtime gift in %s (keep playing, AFK doesn't count)", clock(left))
end

-- countdowns tick in whole seconds: 4 refreshes a second are plenty (was every frame; perf 2026-10-09)
task.spawn(function()
	while true do
		render()
		task.wait(0.25)
	end
end)

local function fit(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 1
	end
	return math.clamp(math.min(camera.ViewportSize.Y / (PH + 60), camera.ViewportSize.X / (PW + 60)), 0.45, 1)
end

local function open()
	overlay.Visible = true
	panelScale.Scale = 0
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit() }):Play()
end

local function close()
	overlay.Visible = false
end

dailyButton.Activated:Connect(function()
	if overlay.Visible then
		close()
	else
		open()
	end
end)
closeButton.Activated:Connect(close)
dim.Activated:Connect(close)

claimButton.Activated:Connect(function()
	local _, _, canClaim = dailyState()
	if claiming or not canClaim then
		return
	end
	claiming = true
	local result = ClaimDaily:InvokeServer()
	if typeof(result) == "table" and result.ok then
		showToast("DAY " .. result.day .. " REWARD!", result.text)
	elseif typeof(result) == "table" then
		claimMessage = string.upper(result.reason or "Try again")
		task.delay(1.2, function()
			claimMessage = nil
		end)
	end
	claiming = false
end)

RewardGranted.OnClientEvent:Connect(function(info)
	if typeof(info) == "table" and info.kind == "Playtime" then
		showToast("PLAYTIME GIFT!", info.text or "")
	elseif typeof(info) == "table" and info.kind == "Prestige" then
		showToast(string.upper(Config.Prestige.Name) .. " " .. string.rep("★", math.min(info.level or 1, 5)), info.text or "")
	elseif typeof(info) == "table" and info.kind == "Goal" then
		showToast("GOAL COMPLETE!", info.text or "")
	elseif typeof(info) == "table" and info.kind == "Shop" then -- Server.ShopService: a Robux purchase went through
		showToast(string.upper(info.title or "THANK YOU!"), info.text or "")
	elseif typeof(info) == "table" and info.kind == "Offline" then
		local minutes = info.minutes or 0
		local away = if minutes >= 60 then string.format("%dh %dm", minutes // 60, minutes % 60) else minutes .. " min"
		showToast("WELCOME BACK!", string.format("Lawyers earned %s (%s)", info.text or "", away))
	end
end)

-- Returning players see the calendar when a reward is waiting (new players just get the ! badge).
task.spawn(function()
	local deadline = os.clock() + 30
	while player:GetAttribute("DailyLastDay") == nil and os.clock() < deadline do
		task.wait(0.5)
	end
	task.wait(3)
	local lastDay = player:GetAttribute("DailyLastDay")
	local _, _, canClaim = dailyState()
	if typeof(lastDay) == "number" and lastDay >= 0 and canClaim then
		open()
	end
end)
