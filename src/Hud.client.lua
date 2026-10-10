--!strict
-- HUD: coin counter, tutorial hints and the case results. (The office card that sat at the bottom is gone:
-- offices, lawyers and assigning clients all live in the LAWYERS panel now - StarterPlayerScripts.Lawyers,
-- lawyer-management overhaul 2026-10-09, user's call.) Case results show as small coloured numbers
-- floating up beside the coin counter (green WIN / orange SETTLED / blue MISTRIAL; a legend explains them
-- during the tutorial). Everything shown comes from server-set attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CaseResult = Remotes:WaitForChild("CaseResult") :: RemoteEvent

local player = Players.LocalPlayer

-- Cartoony palette (team style guide): white panels with thick black outlines, bright buttons,
-- FredokaOne everywhere.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local MUTED = Color3.fromRGB(105, 105, 120)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local GOLD = Color3.fromRGB(255, 200, 40)
local GRAY = Color3.fromRGB(170, 170, 182)
local UIFonts = require(ReplicatedStorage.Shared:WaitForChild("UIFonts")) :: any
local FONT = UIFonts.PrimaryFace -- buttons, headings, money
local TITLE_FONT = UIFonts.TitleFace -- big moments (WIN!)
local BODY_FONT = UIFonts.BodyFace -- small print

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(class)
	for key, value in props do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function corner(radius: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local gui = make("ScreenGui", { Name = "Hud", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

-- Coin counter
local coinLabel = make("TextLabel", {
	Position = UDim2.fromOffset(56, 0),
	Size = UDim2.new(1, -66, 1, 0),
	BackgroundTransparency = 1,
	FontFace = FONT,
	TextSize = 34, -- money stands out
	TextColor3 = INK,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "0",
})
local coinPill = make("Frame", {
	Name = "Coins",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(230, 54),
	BackgroundColor3 = WHITE,
	Parent = gui,
}, {
	corner(27),
	make("UIStroke", { Color = BLACK, Thickness = 3 }),
	make("TextLabel", {
		Position = UDim2.fromOffset(8, 7),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = GOLD,
		FontFace = FONT,
		TextSize = 26,
		TextColor3 = WHITE,
		TextStrokeTransparency = 0,
		Text = "$",
	}, { corner(20), make("UIStroke", { Color = BLACK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) }),
	coinLabel,
})

-- Hint banner (tutorial nudges)
-- (RichText: tutorial hints start with a gold "STEP n/5"; long hints shrink to fit instead of spilling out)
local hint = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 74),
	Size = UDim2.new(0.92, 0, 0, 44),
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.1,
	FontFace = FONT,
	TextScaled = true,
	TextWrapped = true,
	RichText = true,
	TextColor3 = WHITE,
	Visible = false,
	Parent = gui,
}, {
	corner(12),
	make("UIStroke", { Color = BLACK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	make("UISizeConstraint", { MaxSize = Vector2.new(560, 44) }),
	make("UITextSizeConstraint", { MaxTextSize = 19 }),
	make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
})

-- Tutorial hint: "STEP 2/5  text" with the step in gold.
local function step(n: number, text: string): string
	return string.format('<font color="#FFD23C">STEP %d/%d</font>   %s', n, Config.Tutorial.Steps, text)
end

-- The office the tutorial case is in (it isn't always the selected one). Only asked before the first case
-- is done, when the only busy office is the tutorial's (its Tutorial attribute is set once the case starts).
local function tutorialDesk(firm: Instance?): Instance?
	if not firm then
		return nil
	end
	for _, d in firm:GetChildren() do
		if d:GetAttribute("Phase") == "Walking" or d:GetAttribute("Phase") == "Case" then
			return d
		end
	end
	return nil
end

-- Case results: small labeled numbers that fade in, float up beside the coin counter and fade out
-- (no big pop-up). Colour = how the case ended; the tutorial shows a legend for the colours.
local RESULT_STYLE = {
	Win = { label = "WIN", color = Color3.fromRGB(110, 230, 90), hex = "#6EE65A" },
	Settlement = { label = "SETTLED", color = Color3.fromRGB(255, 175, 50), hex = "#FFAF32" },
	Mistrial = { label = "MISTRIAL", color = Color3.fromRGB(120, 180, 255), hex = "#78B4FF" },
}
-- A little feed: the newest number starts level with the coin pill (right of it) and pushes older ones up,
-- so numbers arriving together never overlap. Each fades in, drifts up and fades out (FLOAT_LIFE s).
local FLOAT_LIFE, FLOAT_GAP, FLOAT_MAX = 2.2, 26, 6
type Floater = { label: TextLabel, stroke: UIStroke, born: number, offset: number }
local floaters: { Floater } = {}

RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	for i = #floaters, 1, -1 do
		local f = floaters[i]
		local age = now - f.born
		if age >= FLOAT_LIFE then
			f.label:Destroy()
			table.remove(floaters, i)
			continue
		end
		-- slot i-1 above the newest; ease toward it
		f.offset += ((i - 1) * FLOAT_GAP - f.offset) * math.min(1, dt * 12)
		local alpha = if age < 0.2 then 1 - age / 0.2 elseif age > FLOAT_LIFE - 0.6 then (age - (FLOAT_LIFE - 0.6)) / 0.6 else 0
		f.label.TextTransparency = alpha
		f.stroke.Transparency = alpha
		f.label.Position = UDim2.new(0.5, 126, 0, 50 - age * 14 - f.offset)
	end
end)

local function floatResult(outcome: string, payout: number, big: boolean)
	local style = RESULT_STYLE[outcome] or RESULT_STYLE.Win
	local text = if payout > 0 then string.format("+%s  %s", Formulas.formatCoins(payout), style.label) else style.label .. " - case reruns"
	local l = make("TextLabel", {
		Name = "ResultNumber",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, 126, 0, 50), -- right of the coin pill, level with it
		Size = UDim2.fromOffset(260, if big then 30 else 24),
		BackgroundTransparency = 1,
		FontFace = FONT,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = style.color,
		TextTransparency = 1,
		Text = text,
		ZIndex = 6,
		Parent = gui,
	}, { make("UIStroke", { Color = BLACK, Thickness = 2, Transparency = 1 }) })
	local stroke = l:FindFirstChildOfClass("UIStroke") :: UIStroke
	table.insert(floaters, 1, { label = l, stroke = stroke, born = os.clock(), offset = -FLOAT_GAP })
	while #floaters > FLOAT_MAX do
		local oldest = table.remove(floaters) :: Floater
		oldest.label:Destroy()
	end
end

-- Tutorial legend for those colours, under the STEP banner while the tutorial runs
local legend = make("TextLabel", {
	Name = "ResultLegend",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 122),
	Size = UDim2.new(0.92, 0, 0, 32),
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.1,
	FontFace = FONT,
	TextScaled = true,
	RichText = true,
	TextColor3 = WHITE,
	Text = string.format(
		'Case coins float up by your money:  <font color="%s">GREEN = WIN</font>  <font color="%s">ORANGE = SETTLED</font>  <font color="%s">BLUE = MISTRIAL</font>',
		RESULT_STYLE.Win.hex,
		RESULT_STYLE.Settlement.hex,
		RESULT_STYLE.Mistrial.hex
	),
	Visible = false,
	Parent = gui,
}, {
	corner(10),
	make("UISizeConstraint", { MaxSize = Vector2.new(560, 32) }),
	make("UITextSizeConstraint", { MaxTextSize = 18 }),
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
})

gui.Parent = player:WaitForChild("PlayerGui")

-- Coin counter rolls up instead of jumping.
local shownCoins = make("NumberValue", { Value = player:GetAttribute("Coins") or 0 })
shownCoins.Changed:Connect(function(value: number)
	coinLabel.Text = Formulas.formatCoins(value)
end)
coinLabel.Text = Formulas.formatCoins(shownCoins.Value)
player:GetAttributeChangedSignal("Coins"):Connect(function()
	local target = player:GetAttribute("Coins") or 0
	TweenService:Create(shownCoins, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Value = target }):Play()
end)

local function getFirm(): Instance?
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	return plot and plot:FindFirstChild("Firm")
end

local onLastStep = false -- showing STEP 5/5 right now
local tutorialDoneUntil = 0 -- show the "tutorial complete" line until this os.clock()

local function refresh()
	if not player:GetAttribute("Desk1Level") then
		hint.Visible = false
		legend.Visible = false
		return
	end
	local coins = player:GetAttribute("Coins") or 0
	local free = (player:GetAttribute("FreeLevelUps") or 0) > 0
	local deskCount = (player:GetAttribute("DeskCount") or 1) :: number
	local hintText: string? = nil
	-- clients waiting in your waiting room for a lawyer
	local waiting = 0
	local firmModel = getFirm()
	local room = firmModel and firmModel:FindFirstChild("WaitingClients")
	if room then
		for _, c in room:GetChildren() do
			if c:GetAttribute("Waiting") == true then
				waiting += 1
			end
		end
	end
	-- TUTORIAL (STEP 1-5). Every step names exactly what to tap / where to go.
	local firstDone = player:GetAttribute("FirstCaseDone") == true
	if not firstDone and firmModel then
		local tDesk = tutorialDesk(firmModel)
		local tPhase = tDesk and tDesk:GetAttribute("Phase")
		if tPhase == "Case" and tDesk and not tDesk:GetAttribute("CourtDone") then
			hintText = step(2, "Dave's case is going to COURT! Tap GO TO COURT")
		elseif tPhase == "Case" then
			hintText = step(2, "Your lawyer is wrapping up Dave's case...")
		elseif tPhase == "Walking" then
			hintText = step(1, "Nice! Dave is walking to your lawyer's office...")
		elseif waiting > 0 then
			hintText = step(1, "Neighbor Dave needs a lawyer! Walk up to Dave and press E to Assign Client")
		else
			hintText = step(1, "Your first client is on the way...")
		end
	end
	if not hintText and free and firstDone then
		hintText = step(3, "You won! Open LAWYERS and tap UPGRADE OFFICE: your first one is FREE")
	end
	-- tutorial, continued: hatch the free egg, then put the new lawyer in an empty office
	local owned = (player:GetAttribute("LawyersOwned") or 0) :: number
	local working = (player:GetAttribute("LawyerCount") or 0) :: number
	local hasEmpty = working < deskCount
	if not hintText and firstDone and player:GetAttribute("FreeEgg") == true and owned <= 1 then
		hintText = step(4, "Follow the green line and hatch your FREE Briefcase Egg!")
	elseif not hintText and owned > working and hasEmpty and owned <= 2 then
		hintText = step(5, "Walk to a glowing EMPTY OFFICE to place your new lawyer")
		onLastStep = true
	elseif not hintText and owned > working and hasEmpty then
		hintText = "A lawyer is waiting for a desk! Open LAWYERS to place them"
	elseif not hintText and hasEmpty and coins >= ((player:GetAttribute("EggPrice") or math.huge) :: number) then
		hintText = "Hatch an egg at the hub to fill your empty offices!"
	end
	local segments = (player:GetAttribute("FirmSegments") :: number?) or Config.Firm.StartSegments
	local expandCost = Config.Firm.ExpandCosts[segments + 1]
	if not hintText and expandCost and not hasEmpty and coins >= expandCost then
		hintText = "You can expand your firm! Find the EXPAND FIRM sign at the back"
	end
	if not hintText and player:GetAttribute("ManagerHired") == false and coins >= Config.Manager.HireCost then
		hintText = "You can hire a Manager! Walk to your firm's door and press F"
	end
	-- STEP 5 just finished: a few seconds of "you're done"
	if onLastStep and not (hintText and string.find(hintText, "STEP ", 1, true)) then
		onLastStep = false
		tutorialDoneUntil = os.clock() + 7
	end
	if os.clock() < tutorialDoneUntil then
		hintText = '<font color="#FFD23C">TUTORIAL COMPLETE!</font>   Win cases, upgrade offices and hatch lawyers!'
	end
	hint.Text = hintText or ""
	hint.Visible = hintText ~= nil
	legend.Visible = hintText ~= nil and string.find(hintText, "STEP ", 1, true) ~= nil
end

RunService.Heartbeat:Connect(refresh)

CaseResult.OnClientEvent:Connect(function(result: { outcome: string, payout: number, tutorial: boolean, clientTier: number? })
	-- a small coloured number beside the coin counter (bigger for Epic / Legendary clients)
	floatResult(result.outcome, result.payout, (result.clientTier or 0) >= 4)
	if result.payout > 0 then
		local pulse = TweenService:Create(coinPill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			Size = UDim2.fromOffset(250, 60),
		})
		pulse:Play()
	end
end)
