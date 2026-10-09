--!strict
-- Overhead UI for lawyers AND clients (user's spec 2026-10-09, styled after the user's "Steal a Brainrot"
-- reference: no panel, just stacked bold text with thick black outlines). The Manager stays clean.
--   Client tag (every client in every firm - walking in, waiting on the sofas, at a desk), compact:
--       Lemonade Lily         the client's name (ClientName attribute), white
--       Rare · Pays x8        tier rarity (Config.Clients[Tier].Id, coloured like the lawyers') + payout multiplier
--     It floats above the client's case progress bar (CaseService.caseBar); every other waiting client sits a
--     bit higher so neighbours on the sofas don't collide; shorter draw distance than lawyer tags.
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
local NEAR_LIMIT = 22 -- studs: closer than this, tags shrink with the distance (keeps their on-screen size,
-- instead of a stud-sized tag filling the screen; BillboardGui.DistanceLowerLimit didn't do it for scale sizes)

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
	Mythic = Color3.fromRGB(255, 70, 70),
	Supreme = WHITE, -- + rainbow gradient
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

type Row = { text: string, color: Color3, font: Font?, size: number?, gradient: ColorSequence?, rich: boolean? }

-- A stacked outlined tag over `model` (rows top to bottom; the name row passes size 1.35), floating `gap`
-- studs above the model's top. Used for lawyers and clients alike so they always match.
local function makeTag(model: Model, root: BasePart, name: string, rows: { Row }, gap: number, width: number?, lineH: number?, maxDistance: number?): (BillboardGui, number, { UIGradient })
	local units = 0
	for _, row in rows do
		units += row.size or 1
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = root
	gui.Size = UDim2.new(width or TAG_W, 0, (lineH or LINE_H) * units, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = gui
	local gradients = {}
	for i, row in rows do
		local label = line(gui, row.text, row.color, i, (row.size or 1) / units, row.font)
		label.RichText = row.rich == true
		if row.gradient then
			label.TextColor3 = WHITE
			local g = Instance.new("UIGradient")
			g.Color = row.gradient
			g.Parent = label
			table.insert(gradients, g)
		end
	end
	-- measure: skin / client models differ in height
	local box, size = model:GetBoundingBox()
	local top = box.Position.Y + size.Y / 2
	local center = top - root.Position.Y + gap + gui.Size.Y.Scale / 2
	gui.StudsOffsetWorldSpace = Vector3.new(0, center, 0)
	gui:SetAttribute("BaseW", gui.Size.X.Scale)
	gui:SetAttribute("BaseH", gui.Size.Y.Scale)
	gui:SetAttribute("Bottom", center - gui.Size.Y.Scale / 2) -- shrinking keeps the tag sitting on this line
	gui.Parent = playerGui
	return gui, center + gui.Size.Y.Scale / 2, gradients
end

local function rarityRow(rarityId: string): Row
	return {
		text = rarityId,
		color = RARITY_TEXT[rarityId] or WHITE,
		gradient = if rarityId == "Legendary" then SHIMMER elseif rarityId == "Supreme" then RAINBOW else nil,
	}
end

local function buildTag(model: Model, desk: Instance, id: string, stars: number): Tag?
	local root = rootOf(model)
	local def = Formulas.getSkin(id)
	if not root or not def then
		return nil
	end
	local rarity = Config.Eggs.Skins[def.Rarity]
	local tierName = Config.Lawyers.StarNames[stars] or ""
	local rows: { Row } = {}
	if tierName ~= "" then
		table.insert(rows, { text = tierName, color = GOLD, font = UIFonts.TitleFace, gradient = if stars >= 3 then RAINBOW else nil })
	end
	table.insert(rows, { text = def.Name, color = WHITE, size = 1.35 })
	table.insert(rows, rarityRow(if rarity then rarity.Id else "Common"))
	table.insert(rows, { text = "Earns x" .. tostring(Formulas.lawyerEarn(id, stars)), color = YELLOW })
	local gui, height, gradients = makeTag(model, root, "LawyerTag", rows, HEAD_GAP)
	return { gui = gui, key = id .. "|" .. stars, desk = desk, root = root, height = height, gradients = gradients }
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

-- ---------------------------------------------------------------------------------------------- client tags
-- Clients are created by CaseService.makeClientModel (Model "Client" with Tier / ClientName attributes) in the
-- firm's waiting-room folder and later re-parented to a desk, so follow them by events, not by desk.
local CLIENT_GAP = 2.3 -- clears the case progress bar that floats over a client's head
local CLIENT_W = 6 -- studs: a little smaller than lawyer tags (lawyers are the stars of the firm)
local CLIENT_LINE_H = 0.6
local CLIENT_STAGGER = 1.4 -- extra height for every other waiting client
local CLIENT_DISTANCE = 60
local clientTags: { [Model]: { gui: BillboardGui, root: BasePart, gradients: { UIGradient } } } = {}

local function untagClient(model: Model)
	local tag = clientTags[model]
	if tag then
		tag.gui:Destroy()
		clientTags[model] = nil
	end
end

local function tagClient(model: Instance)
	if not (model:IsA("Model") and model.Name == "Client") or clientTags[model] then
		return
	end
	local tier = model:GetAttribute("Tier")
	local def = typeof(tier) == "number" and Config.Clients[tier]
	local root = rootOf(model)
	if not def or not root then
		return
	end
	local name = model:GetAttribute("ClientName")
	-- compact (clients crowd the waiting-room sofas): name, then "Rare · Pays x8" on one line
	local rarityHex = (RARITY_TEXT[def.Id] or WHITE):ToHex()
	local rows: { Row } = {
		{ text = if typeof(name) == "string" then name else def.Name, color = WHITE, size = 1.3 },
		{ text = string.format('<font color="#%s">%s</font> · Pays x%s', rarityHex, def.Id, tostring(def.Multiplier)), color = YELLOW, rich = true },
	}
	-- neighbours on the sofas alternate heights so their names don't collide
	local waitingId = model:GetAttribute("WaitingId")
	local stagger = if typeof(waitingId) == "number" and waitingId % 2 == 1 then CLIENT_STAGGER else 0
	local gui, _, gradients = makeTag(model, root, "ClientTag", rows, CLIENT_GAP + stagger, CLIENT_W, CLIENT_LINE_H, CLIENT_DISTANCE)
	clientTags[model] = { gui = gui, root = root, gradients = gradients }
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			untagClient(model) -- client left (case done) or streamed out
		end
	end)
end

task.spawn(function()
	local plots = workspace:WaitForChild("Plots")
	plots.DescendantAdded:Connect(function(d)
		if d:IsA("Model") and d.Name == "Client" then
			task.defer(tagClient, d) -- let its parts finish replicating before measuring
		end
	end)
	for _, d in plots:GetDescendants() do
		tagClient(d)
	end
	-- safety net: drop tags whose client vanished without an AncestryChanged we saw
	while true do
		task.wait(2)
		for model in clientTags do
			if not model:IsDescendantOf(workspace) then
				untagClient(model)
			end
		end
	end
end)

-- Rainbow tiers drift, the Legendary shimmer sweeps across every couple of seconds.
local function clampNear(gui: BillboardGui, root: BasePart, eye: Vector3)
	local f = math.clamp((root.Position - eye).Magnitude / NEAR_LIMIT, 0.2, 1)
	local w = (gui:GetAttribute("BaseW") :: number) * f
	if math.abs(gui.Size.X.Scale - w) > 0.02 then
		local h = (gui:GetAttribute("BaseH") :: number) * f
		gui.Size = UDim2.new(w, 0, h, 0)
		gui.StudsOffsetWorldSpace = Vector3.new(0, (gui:GetAttribute("Bottom") :: number) + h / 2, 0)
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local sweep = ((t * 0.6) % 1.6) - 0.8
	local camera = workspace.CurrentCamera
	if camera then
		local eye = camera.CFrame.Position
		for _, tag in tags do
			clampNear(tag.gui, tag.root, eye)
		end
		for _, tag in clientTags do
			clampNear(tag.gui, tag.root, eye)
		end
	end
	for _, tag in clientTags do
		for _, g in tag.gradients do
			g.Offset = if g.Color == RAINBOW then Vector2.new(math.sin(t * 1.2) * 0.25, 0) else Vector2.new(sweep, 0)
		end
	end
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
