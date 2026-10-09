--!strict
-- Overhead UI for desk lawyers (user's spec 2026-10-09, styled after the user's "Steal a Brainrot" reference:
-- no panel, just stacked bold text with thick black outlines). Lawyers only - clients and the Manager stay clean.
--   Name tag (every lawyer in every firm):
--       Gold / Rainbow        merge tier, only for 2-3 star lawyers (Rainbow is an animated rainbow)
--       Tralalero Tralala     the lawyer's name, white
--       Legendary             rarity, in Config.RarityColors (Legendary gets a slow gold shimmer)
--       Earns x10             earning multiplier (Formulas.lawyerEarn), yellow
--     BillboardGuis live in PlayerGui (one per lawyer, Adornee = the lawyer's root) and are sized in studs, so
--     they shrink with distance. A scan of the firms (same pattern as DeskLife) creates / rebuilds / removes
--     them, so a re-dressed, merged or swapped lawyer never ends up with two tags.
--   Case pop-up (your own desks, from the CaseResult remote the server fires at case completion):
--       "+$250" big + "CASE WON!" small rise out of the lawyer's tag, hold, then drift up and fade.
--       Green win, orange settled, blue mistrial (same colours as the Hud coin floaters). Rapid results on one
--       desk stack upward instead of overlapping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Formulas = require(Shared:WaitForChild("Formulas")) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts")) :: any
local CaseResult = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CaseResult") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SCAN_EVERY = 0.5
local MAX_DISTANCE = 95
local TAG_W = 9 -- studs; the tag shrinks with distance like the reference
local LINE_H = 0.8 -- studs per text line
local HEAD_GAP = 0.35 -- studs between the top of the lawyer and the tag

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local YELLOW = Color3.fromRGB(255, 220, 40)
local GOLD = Color3.fromRGB(255, 196, 30)
-- tag colours: Config.RarityColors, nudged brighter where the stock colour is too dark to read on a black outline
local RARITY_TEXT: { [string]: Color3 } = {
	Common = Color3.fromRGB(205, 205, 210),
	Uncommon = Color3.fromRGB(95, 220, 90),
	Rare = Color3.fromRGB(70, 170, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = GOLD,
}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 255, 120)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
})
local SHIMMER = ColorSequence.new({
	ColorSequenceKeypoint.new(0, GOLD),
	ColorSequenceKeypoint.new(0.42, GOLD),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 250, 215)),
	ColorSequenceKeypoint.new(0.58, GOLD),
	ColorSequenceKeypoint.new(1, GOLD),
})
-- same colours as the Hud's coin floaters (Hud RESULT_STYLE), so the tutorial legend still holds
local RESULT = {
	Win = { title = "CASE WON!", color = Color3.fromRGB(110, 230, 90) },
	Settlement = { title = "SETTLED", color = Color3.fromRGB(255, 175, 50) },
	Mistrial = { title = "MISTRIAL", color = Color3.fromRGB(120, 180, 255) },
}

-- One outlined text line, the reference look: bold rounded font, thick black outline, scaled to its row.
local function line(parent: Instance, text: string, color: Color3, order: number, heightScale: number, font: Font?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, heightScale)
	label.LayoutOrder = order
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.FontFace = font or UIFonts.PrimaryFace
	local stroke = Instance.new("UIStroke")
	stroke.Color = BLACK
	stroke.Thickness = 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

-- ---------------------------------------------------------------------------------------------- name tags
type Tag = { gui: BillboardGui, key: string, desk: Instance, root: BasePart, height: number, gradients: { UIGradient } }
local tags: { [Model]: Tag } = {}

local function rootOf(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function removeTag(model: Model)
	local tag = tags[model]
	if tag then
		tag.gui:Destroy()
		tags[model] = nil
	end
end

local function buildTag(model: Model, desk: Instance, id: string, stars: number): Tag?
	local root = rootOf(model)
	local def = Formulas.getSkin(id)
	if not root or not def then
		return nil
	end
	local rarity = Config.Eggs.Skins[def.Rarity]
	local rarityId = if rarity then rarity.Id else "Common"
	local tierName = Config.Lawyers.StarNames[stars] or ""

	local rows = if tierName ~= "" then 4 else 3
	local gui = Instance.new("BillboardGui")
	gui.Name = "LawyerTag"
	gui.Adornee = root
	gui.Size = UDim2.new(TAG_W, 0, LINE_H * (rows + 0.35), 0) -- the name row is a bit taller
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = gui

	local unit = 1 / (rows + 0.35)
	local gradients = {}
	if tierName ~= "" then
		local tier = line(gui, tierName, if stars >= 3 then WHITE else GOLD, 1, unit, UIFonts.TitleFace)
		if stars >= 3 then
			local g = Instance.new("UIGradient")
			g.Color = RAINBOW
			g.Parent = tier
			table.insert(gradients, g)
		end
	end
	line(gui, def.Name, WHITE, 2, unit * 1.35)
	local rarityLabel = line(gui, rarityId, RARITY_TEXT[rarityId] or WHITE, 3, unit)
	if rarityId == "Legendary" then
		rarityLabel.TextColor3 = WHITE
		local g = Instance.new("UIGradient")
		g.Color = SHIMMER
		g.Parent = rarityLabel
		table.insert(gradients, g)
	end
	line(gui, "Earns x" .. tostring(Formulas.lawyerEarn(id, stars)), YELLOW, 4, unit)

	-- float the tag just above the lawyer's head (skin models differ in height, so measure)
	local box, size = model:GetBoundingBox()
	local top = box.Position.Y + size.Y / 2
	local height = top - root.Position.Y + HEAD_GAP + gui.Size.Y.Scale / 2
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.Parent = playerGui
	return { gui = gui, key = id .. "|" .. stars, desk = desk, root = root, height = height + gui.Size.Y.Scale / 2, gradients = gradients }
end

local function scan()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	local seen: { [Model]: boolean } = {}
	for _, plot in plots:GetChildren() do
		local firm = plot:FindFirstChild("Firm")
		if firm then
			for _, desk in firm:GetChildren() do
				local lawyer = desk.Name:match("^Desk%d+$") and desk:FindFirstChild("Lawyer")
				local id = desk:GetAttribute("LawyerId")
				if lawyer and lawyer:IsA("Model") and typeof(id) == "string" then
					local stars = desk:GetAttribute("LawyerStars")
					local s = if typeof(stars) == "number" then stars else 1
					seen[lawyer] = true
					local tag = tags[lawyer]
					if tag and (tag.key ~= id .. "|" .. s or not tag.root.Parent) then
						removeTag(lawyer) -- re-dressed / merged: rebuild (never two tags on one lawyer)
						tag = nil
					end
					if not tag then
						local built = buildTag(lawyer, desk, id, s)
						if built then
							tags[lawyer] = built
						end
					end
				end
			end
		end
	end
	for model in tags do
		if not seen[model] or not model.Parent then
			removeTag(model)
		end
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(scan)
		if not ok then
			warn("[LawyerTags]", err)
		end
		task.wait(SCAN_EVERY)
	end
end)

-- Rainbow tiers drift, the Legendary shimmer sweeps across every couple of seconds.
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local sweep = ((t * 0.6) % 1.6) - 0.8
	for _, tag in tags do
		for _, g in tag.gradients do
			if g.Color == RAINBOW then
				g.Offset = Vector2.new(math.sin(t * 1.2) * 0.25, 0)
			else
				g.Offset = Vector2.new(sweep, 0)
			end
		end
	end
end)

-- ---------------------------------------------------------------------------------------------- case pop-ups
local activePops: { [Instance]: number } = {} -- desk -> pop-ups currently on screen (for stacking)

local function fade(label: TextLabel, to: number, info: TweenInfo)
	TweenService:Create(label, info, { TextTransparency = to }):Play()
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, { Transparency = to }):Play()
	end
end

local function popUp(tag: Tag, outcome: string, payout: number)
	local style = RESULT[outcome] or RESULT.Win
	local slot = activePops[tag.desk] or 0
	activePops[tag.desk] = slot + 1

	local gui = Instance.new("BillboardGui")
	gui.Name = "CasePop"
	gui.Adornee = tag.root
	gui.Size = UDim2.new(8, 0, 2.2, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.AlwaysOnTop = false -- (AlwaysOnTop billboards never showed up in Studio captures; kept in the 3D pass like the tags)
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = gui
	local title = line(gui, style.title, WHITE, 1, 0.36, UIFonts.TitleFace)
	local amountText = if payout > 0 then "+$" .. Formulas.formatCoins(payout) else "RETRYING"
	local amount = line(gui, amountText, style.color, 2, 0.64)
	amount:FindFirstChildOfClass("UIStroke").Thickness = 3
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = gui
	for _, l in { title, amount } do
		l.TextTransparency = 1
		l:FindFirstChildOfClass("UIStroke").Transparency = 1
	end

	-- start just above the name tag; a stacked pop-up starts higher and a little to the side
	local base = Vector3.new(if slot % 2 == 1 then 0.8 else 0, tag.height + 1.2 + slot * 1.6, 0)
	gui.StudsOffsetWorldSpace = base
	gui.Parent = playerGui

	-- 1) pop in fast while rising a little  2) hold to read  3) drift up and fade out  4) gone
	local inInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, inInfo, { StudsOffsetWorldSpace = base + Vector3.new(0, 0.6, 0) }):Play()
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	fade(title, 0, inInfo)
	fade(amount, 0, inInfo)
	task.delay(0.18 + 0.8, function()
		local outInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(gui, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = base + Vector3.new(0, 2.6, 0) }):Play()
		fade(title, 1, outInfo)
		fade(amount, 1, outInfo)
		task.wait(0.72)
		gui:Destroy()
		activePops[tag.desk] = math.max((activePops[tag.desk] or 1) - 1, 0)
	end)
end

-- Fired by CaseService the moment a case completes (only to the firm's owner).
CaseResult.OnClientEvent:Connect(function(result: { desk: number, outcome: string, payout: number })
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local desk = firm and firm:FindFirstChild("Desk" .. tostring(result.desk))
	local lawyer = desk and desk:FindFirstChild("Lawyer")
	if not (lawyer and lawyer:IsA("Model")) then
		return
	end
	local tag = tags[lawyer]
	if not tag then
		-- the result can beat the next scan (a lawyer placed this instant): tag it now
		pcall(scan)
		tag = tags[lawyer]
	end
	if tag then
		popUp(tag, result.outcome, result.payout or 0)
	end
end)
