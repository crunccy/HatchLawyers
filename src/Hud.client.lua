--!strict
-- HUD: coin counter, tutorial hints and the case results. (The office card that sat at the bottom is gone:
-- offices, lawyers and assigning clients all live in the LAWYERS panel now - StarterPlayerScripts.Lawyers,
-- lawyer-management overhaul 2026-10-09, user's call.) Case results show as small coloured numbers
-- drifting beside the coin counter (green WIN / orange SETTLED / blue MISTRIAL; the words say which).
-- Everything shown comes from server-set attributes.
-- 2026-10-12 (mr.robe, user's call): the coin counter sits in the top bar strip (IgnoreGuiInset; Roblox's own
-- buttons are at its left / right ends) and the hints right under it, so they block less of the view; the
-- "Case coins float up by your money" legend is gone.
-- 2026-10-18 UI overhaul part 2 (docs/UI_OVERHAUL.md): the coins are a Skin.counter bottom-left with no panel (the
-- reference's currency), case results float up beside it, and the hint is a Skin.toast top-centre (icon + white
-- stroked text, the key words in lime). This script also installs Skin's custom world prompt (Style = Custom ones).

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

local Skin = require(ReplicatedStorage.Shared:WaitForChild("Skin")) :: any
local gui = make("ScreenGui", { Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
gui:SetAttribute("NoSkin", true)
local COIN_H = 54 -- coin counter height (px)
local COIN_PAD = 18 -- from the screen's left / bottom edge

-- Coin counter: the glossy money icon + a big stroked number, no panel, bottom-left; counts up and pops on a gain
local Icons = (require(ReplicatedStorage.Shared:WaitForChild("HudMenu")) :: any).Icons
local coins = Skin.counter({
	Parent = gui, Name = "Coins", Icon = Icons.Money, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, COIN_PAD, 1, -COIN_PAD), Height = COIN_H, Width = 340,
	Value = player:GetAttribute("Coins") or 0, Format = Formulas.formatCoins,
})
local coinScale = make("UIScale", { Parent = coins.frame }) -- phones: smaller with the screen
local function fitCoins()
	local camera = workspace.CurrentCamera
	local h = if camera then camera.ViewportSize.Y else 720
	coinScale.Scale = if h < 200 then 1 else math.clamp(h / 760, 0.62, 1)
end
fitCoins()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCoins)
end

-- Hint toast (tutorial nudges): top-centre under Roblox's top bar; tutorial hints start with a gold "STEP n/5"
local hint = Skin.toast({ Parent = gui, Name = "Hint", Position = UDim2.new(0.5, 0, 0, 62), TextSize = 24 })

-- Tutorial hint: "STEP 2/5  text" with the step in gold.
local function step(n: number, text: string): string
	return string.format('<font color="#FFD23C">STEP %d/%d</font>   %s', n, Config.Tutorial.Steps, Skin.highlight(text))
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

-- Case results: small labeled numbers that fade in just above the coin counter, drift up and fade out
-- (no big pop-up). Colour = how the case ended.
local RESULT_STYLE = {
	Win = { label = "WIN", color = Color3.fromRGB(110, 230, 90), hex = "#6EE65A" },
	Settlement = { label = "SETTLED", color = Color3.fromRGB(255, 175, 50), hex = "#FFAF32" },
	Mistrial = { label = "MISTRIAL", color = Color3.fromRGB(120, 180, 255), hex = "#78B4FF" },
}
-- A little feed: the newest number starts just above the coin counter and pushes older ones up, so numbers
-- arriving together never overlap. Each fades in, drifts up and fades out (FLOAT_LIFE s).
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
		-- slot i-1 below the newest; ease toward it
		f.offset += ((i - 1) * FLOAT_GAP - f.offset) * math.min(1, dt * 12)
		local alpha = if age < 0.2 then 1 - age / 0.2 elseif age > FLOAT_LIFE - 0.6 then (age - (FLOAT_LIFE - 0.6)) / 0.6 else 0
		f.label.TextTransparency = alpha
		f.stroke.Transparency = alpha
		f.label.Position = UDim2.new(0, COIN_PAD + 8, 1, -(COIN_PAD + COIN_H * coinScale.Scale + 6) - age * 10 - f.offset)
	end
end)

local function floatResult(outcome: string, payout: number, big: boolean)
	local style = RESULT_STYLE[outcome] or RESULT_STYLE.Win
	local text = if payout > 0 then string.format("+%s  %s", Formulas.formatCoins(payout), style.label) else style.label .. " - case reruns"
	local l = make("TextLabel", {
		Name = "ResultNumber",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, COIN_PAD + 8, 1, -(COIN_PAD + COIN_H + 6)), -- just above the coin counter
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
	}, { make("UIStroke", { Color = BLACK, Thickness = 2.5, Transparency = 1, LineJoinMode = Enum.LineJoinMode.Round }) })
	local stroke = l:FindFirstChildOfClass("UIStroke") :: UIStroke
	table.insert(floaters, 1, { label = l, stroke = stroke, born = os.clock(), offset = -FLOAT_GAP })
	-- short (phone) screens: fewer at once so the stack never climbs into the menu tiles above the coins
	local camera = workspace.CurrentCamera
	local maxShown = if camera and camera.ViewportSize.Y >= 200 and camera.ViewportSize.Y < 520 then 2 else FLOAT_MAX
	while #floaters > maxShown do
		local oldest = table.remove(floaters) :: Floater
		oldest.label:Destroy()
	end
end

gui.Parent = player:WaitForChild("PlayerGui")

-- Coin counter counts up instead of jumping (Skin.counter).
player:GetAttributeChangedSignal("Coins"):Connect(function()
	coins.set(player:GetAttribute("Coins") or 0)
end)
Skin.installPrompts() -- the custom world prompt for every Style = Custom ProximityPrompt (UI overhaul part 3 flips them)

local function getFirm(): Instance?
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	return plot and plot:FindFirstChild("Firm")
end

-- the toast's icon, by what the hint is about
local function hintIcon(s: string): string
	local l = string.lower(s)
	if string.find(l, "court", 1, true) or string.find(l, "case", 1, true) then
		return Icons.Gavel
	elseif string.find(l, "egg", 1, true) or string.find(l, "incubator", 1, true) then
		return Icons.Eggs
	elseif string.find(l, "upgrade", 1, true) or string.find(l, "expand", 1, true) then
		return Icons.Upgrades
	elseif string.find(l, "lawyer", 1, true) or string.find(l, "office", 1, true) or string.find(l, "manager", 1, true)
		or string.find(l, "client", 1, true) then
		return Icons.Lawyers
	end
	return Icons.Goals
end

local onLastStep = false -- showing STEP 5/5 right now
local tutorialDoneUntil = 0 -- show the "tutorial complete" line until this os.clock()

local function refresh()
	if not player:GetAttribute("Desk1Level") then
		hint.hide()
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
			hintText = step(1, "Neighbor Dave is walking straight to your lawyer!")
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
		hintText = step(4, "Follow the green line to your INCUBATOR and hatch your FREE egg!")
	elseif not hintText and owned > working and hasEmpty and owned <= 2 then
		hintText = step(5, "Walk to a glowing EMPTY OFFICE to equip your new lawyer")
		onLastStep = true
	elseif not hintText and owned > working and hasEmpty then
		hintText = "A lawyer is waiting for a desk! Open LAWYERS to equip them"
	elseif not hintText and hasEmpty and coins >= ((player:GetAttribute("EggPrice") or math.huge) :: number) then
		hintText = "Buy eggs in Briefcase Bay (west) and hatch them at your incubator!"
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
	if hintText then
		-- tutorial lines carry their own tags (gold STEP, lime words); plain hints get their CAPS words in lime
		hint.set(hintText, if string.find(hintText, "<font", 1, true) then "" else nil, hintIcon(hintText))
		hint.show()
	else
		hint.hide()
	end
end

-- hints only change a few times a second: no need to rebuild them every frame (perf 2026-10-09)
task.spawn(function()
	while true do
		refresh()
		task.wait(0.2)
	end
end)

CaseResult.OnClientEvent:Connect(function(result: { outcome: string, payout: number, tutorial: boolean, clientTier: number? })
	-- a small coloured number beside the coin counter (bigger for Epic / Legendary clients)
	floatResult(result.outcome, result.payout, (result.clientTier or 0) >= 4)
	if result.payout > 0 then
		coins.pop()
	end
end)
