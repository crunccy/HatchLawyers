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
	elseif reward.Kind == "Egg" then
		return if reward.Count > 1 then reward.Count .. " FREE\nEGGS" else "FREE\nEGG"
	elseif reward.Kind == "RareEgg" then
		return "RARE\nEGG!"
	elseif reward.Kind == "SkillRoll" then
		return "SKILL\nROLL"
	end
	return ""
end

---------------------------------------------------------------- left-edge DAILY tile
local gui = make("ScreenGui", { Name = "Rewards", ResetOnSpawn = false, DisplayOrder = 14, Parent = player:WaitForChild("PlayerGui") })
-- the DAILY tile lives in the shared left-edge menu column (Shared.HudMenu): real gift icon, "!" badge when a
-- daily reward is waiting, the playtime-gift countdown in a pill under it (UI pass 2026-10-09)
local HudMenu = require(ReplicatedStorage.Shared:WaitForChild("HudMenu")) :: any
local menuEntry = HudMenu.button({ name = "Daily", label = "DAILY", icon = "Gift", color = ORANGE, order = 1 })
local dailyButton = menuEntry.button

---------------------------------------------------------------- calendar panel (560x340, scaled to fit)
local overlay = make("Frame", { Name = "Calendar", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
local dim = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Parent = overlay })
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 340),
	BackgroundColor3 = WHITE,
	Parent = overlay,
}, { corner(24), make("UIStroke", { Color = BLACK, Thickness = 5 }), panelScale })
text({ Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(420, 40), Text = "DAILY REWARDS", TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 34)
local streakLabel = text({ Position = UDim2.fromOffset(24, 54), Size = UDim2.fromOffset(460, 22), TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 18)
local closeButton = make("TextButton", {
	Name = "Close",
	Position = UDim2.new(1, -62, 0, 14),
	Size = UDim2.fromOffset(46, 46),
	BackgroundColor3 = RED,
	FontFace = FONT,
	TextSize = 26,
	TextColor3 = WHITE,
	TextStrokeTransparency = 0,
	Text = "X",
	Parent = panel,
}, { corner(23), stroke(3) })

type Tile = { frame: Frame, day: TextLabel, reward: TextLabel, check: TextLabel, scale: UIScale }
local tiles: { Tile } = {}
for i, reward in Config.Rewards.Daily do
	local scale = make("UIScale", {})
	local frame = make("Frame", {
		Name = "Day" .. i,
		Position = UDim2.fromOffset(17 + (i - 1) * 76, 92),
		Size = UDim2.fromOffset(70, 124),
		BackgroundColor3 = WHITE,
		Parent = panel,
	}, { corner(14), stroke(3), scale })
	tiles[i] = {
		frame = frame,
		scale = scale,
		day = text({ Position = UDim2.fromOffset(4, 6), Size = UDim2.fromOffset(62, 22), Text = "DAY " .. i, Parent = frame }, 18),
		reward = text({ Position = UDim2.fromOffset(4, 34), Size = UDim2.fromOffset(62, 60), Text = "", TextWrapped = true, Parent = frame }, 18),
		check = text({ Position = UDim2.fromOffset(4, 92), Size = UDim2.fromOffset(62, 26), Text = "", TextColor3 = WHITE, TextStrokeTransparency = 0, Parent = frame }, 22),
	}
end

local claimButton = make("TextButton", {
	Name = "ClaimButton",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 232),
	Size = UDim2.fromOffset(320, 56),
	BackgroundColor3 = GREEN,
	FontFace = FONT,
	TextScaled = true,
	TextColor3 = WHITE,
	TextStrokeTransparency = 0,
	AutoButtonColor = true,
	Parent = panel,
}, { corner(14), stroke(3), make("UITextSizeConstraint", { MaxTextSize = 26 }), make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
local giftLine = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 296), Size = UDim2.fromOffset(500, 24), TextColor3 = MUTED, Parent = panel }, 18)

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
}, { corner(20), stroke(4), toastScale })
local toastTitle = text({ FontFace = TITLE, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(320, 44), TextColor3 = WHITE, TextStrokeTransparency = 0, ZIndex = 21, Parent = toast }, 36)
local toastBody = text({ Position = UDim2.fromOffset(10, 54), Size = UDim2.fromOffset(320, 36), TextColor3 = WHITE, TextStrokeTransparency = 0, ZIndex = 21, Parent = toast }, 26)
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
		tile.frame.BackgroundColor3 = if done then GREEN elseif isNext then GOLD else WHITE
		tile.day.TextColor3 = if done or isNext then WHITE else INK
		tile.day.TextStrokeTransparency = if done or isNext then 0 else 1
		tile.reward.TextColor3 = if done or isNext then WHITE else INK
		tile.reward.TextStrokeTransparency = if done or isNext then 0 else 1
		tile.check.Text = if done then "✓" elseif isNext and canClaim then "TODAY" else ""
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

RunService.Heartbeat:Connect(render)

local function fit(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 1
	end
	return math.clamp(math.min(camera.ViewportSize.Y / 400, camera.ViewportSize.X / 620), 0.5, 1)
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
