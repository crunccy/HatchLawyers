--!strict
-- The Mutation Machine (Hub.MergeMachine, the old Lawyer Merger), styled after the user's "Fuse Machine" reference: purple striped
-- header, dark studded panel, "Bring 3 same Lawyers to Merge", three slots with green + buttons piped into a
-- result window, a big green button at the bottom, and a "3 small = 1 big" help card with OK.
-- MUTATION MACHINE since 2026-10-13 (user's calls; the hub model is still Hub.MergeMachine): MergeCount copies of the
-- same lawyer at the same mutation TRY to become one lawyer of the next tier (Config.Lawyers.Mutations: Shiny ->
-- Diamond -> Cosmic) with Formulas.mutateChance - shown on the button before you press it. If it FIZZLES, all of them
-- are gone (the word "lose" never shows: "fizzled... they ran off"). Mutated lawyers show recoloured (MutationLook).
-- The server decides everything (Remotes.MergeSelected, Server.LawyerService.mergeSelected); this only picks.
-- The lawyer list comes from the player's "Lawyers" attribute (PlayerData): { Uid, Id, Stars, Skills, Office }.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any
local MergeSelected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MergeSelected") :: RemoteFunction

local STUDS = "rbxassetid://114488299634202"
local SHINE = "rbxassetid://101930347288469"
local FONT = UIFonts.PrimaryFace
local TITLE = UIFonts.TitleFace
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local PURPLE = Color3.fromRGB(176, 52, 255)
local PURPLE_DARK = Color3.fromRGB(122, 30, 214)
local PANEL = Skin.Panel
local SLOT = Color3.fromRGB(40, 39, 58)
local PIPE = Color3.fromRGB(34, 34, 40)
local GREEN = Color3.fromRGB(76, 224, 48)
local RED = Color3.fromRGB(228, 32, 32)
local GRAY = Color3.fromRGB(120, 120, 135)
local NEED = Config.Lawyers.MergeCount
local MAX_STARS = #Config.Lawyers.StarEarn

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
local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
	make("UIStroke", { Thickness = math.max(2, math.floor(maxSize / 10)), Color = BLACK, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	return l
end
local function studs(parent: GuiObject, transparency: number)
	make("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = STUDS, ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(34, 34), ZIndex = parent.ZIndex, Parent = parent,
	})
end
local function squish(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = gui })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function rarityOf(id: string): (string, Color3)
	local def = Formulas.getSkin(id)
	local tier = def and Config.Eggs.Skins[def.Rarity]
	local rid = if tier then tier.Id else "Common"
	return rid, Config.RarityColors[rid] or WHITE
end
-- a lawyer's mutation tag ("" for Normal) - replaced the stars
local function starText(stars: number): string
	local m = Config.Lawyers.Mutations[stars]
	return if m then "(" .. m.Id .. ")" else ""
end
local function pct(stars: number): string
	return string.format("%d%%", math.floor(Formulas.mutateChance(stars) * 100 + 0.5))
end

-- A lawyer standing in a ViewportFrame (the same model the desks show: the office-1 lawyer re-dressed).
-- `animate` keeps it swaying (one connection, returned); otherwise it's a still.
local function showLawyer(vf: ViewportFrame, id: string, animate: boolean, stars: number?): RBXScriptConnection?
	vf:ClearAllChildren()
	local plotName = player:GetAttribute("Plot")
	local plot = typeof(plotName) == "string" and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local desk = firm and firm:FindFirstChild("Desk1")
	local source = desk and desk:FindFirstChild("Lawyer")
	if source and source:IsA("Model") then
		local conn = SkinLook.showInViewport(vf, source, id, stars)
		if not animate then
			conn:Disconnect()
			return nil
		end
		return conn
	end
	return nil
end

local playerGui = player:WaitForChild("PlayerGui")
local gui = make("ScreenGui", { Name = "Merger", ResetOnSpawn = false, DisplayOrder = 32, Enabled = false, IgnoreGuiInset = true, Parent = playerGui })
local shade = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui })

------------------------------------------------------------------ panel
local panelScale = make("UIScale", { Scale = 1 })
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.56, 0.52), Size = UDim2.fromOffset(820, 680),
	BackgroundColor3 = PANEL, Parent = gui,
}, { corner(8), stroke(6), panelScale })
studs(panel, 0.88)
-- header in the shared Skin look (2026-10-11 UI pass): purple top-lit strip, studs, shine bands, title, red X tile
local sw = Skin.swatch("Purple")
make("Frame", { Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = panel },
	{ corner(6), make("UIStroke", { Thickness = 2, Color = Color3.fromHex("4A4D66"), Transparency = 0.2 }) })
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
})
make("Frame", { Position = UDim2.new(0, -4, 1, 0), Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = Skin.Ink, BorderSizePixel = 0, ZIndex = 3, Parent = header })
Skin.studs(header, 0.86, nil, 26)
Skin.shineBands(header, 0.84)
Skin.text({ Position = UDim2.fromOffset(24, 8), Size = UDim2.new(0.7, 0, 0, 68), FontFace = Skin.Fonts.Title, Text = "Mutation Machine", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header }, 60, 5)
local closeButton = Skin.closeButton(header, 66, 4)

local line1 = text({ Position = UDim2.fromOffset(20, 112), Size = UDim2.new(1, -40, 0, 50), RichText = true,
	Text = string.format('Bring <font color="#FF3B3B">%d</font> same Lawyers to Mutate', NEED), Parent = panel }, 46)
line1.RichText = true
local line2 = text({ Position = UDim2.fromOffset(20, 162), Size = UDim2.new(1, -40, 0, 38), RichText = true, FontFace = Font.new(TITLE.Family, Enum.FontWeight.Bold, Enum.FontStyle.Italic),
	Text = '<font color="#5CF03C">Mutated lawyers</font> earn <font color="#5CF03C">way more</font>... <font color="#FFB43C">if it works!</font>', Parent = panel }, 34)
line2.RichText = true

------------------------------------------------------------------ slots, pipes, result
type Slot = { frame: Frame, title: TextLabel, add: TextButton, vf: ViewportFrame, remove: TextButton, uid: string?, id: string?, stars: number? }
local slots: { Slot } = {}
local SLOT_W, SLOT_H, SLOT_Y = 236, 150, 214
local resultBox = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 432), Size = UDim2.fromOffset(250, 150),
	BackgroundColor3 = Color3.fromRGB(28, 28, 40), ZIndex = 2, Parent = panel,
}, { corner(6), stroke(4) })
local resultGlow = make("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.6, 1.6), BackgroundTransparency = 1,
	Image = Effects.TEXTURES.glow, ImageTransparency = 1, ZIndex = 2, Parent = resultBox,
})
local resultVf = make("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 205), ZIndex = 3, Parent = resultBox })
local resultMystery = text({ Size = UDim2.fromScale(1, 1), Text = "?", FontFace = TITLE, TextColor3 = Color3.fromRGB(10, 10, 14), ZIndex = 3, Parent = resultBox }, 120)
;(resultMystery:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Color3.fromRGB(70, 70, 90)
local resultName = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(420, 30), Text = "", ZIndex = 4, Parent = resultBox }, 28)
local resultEarn = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.fromOffset(300, 22), Text = "", TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = 4, Parent = resultBox }, 22)
local resultSway: RBXScriptConnection? = nil

-- pipes from each slot down into the result window (dark L-shaped pipes with green neon collars)
local function pipe(x: number, y: number, w: number, h: number)
	make("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = PIPE, BorderSizePixel = 0, ZIndex = 1, Parent = panel }, { stroke(3) })
end
local function collar(cx: number, y: number, horizontal: boolean)
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, y), Size = if horizontal then UDim2.fromOffset(16, 52) else UDim2.fromOffset(70, 14),
		BackgroundColor3 = GREEN, ZIndex = 2, Parent = panel,
	}, { corner(5), stroke(3) })
end
for i = 1, NEED do
	local x = 30 + (i - 1) * (SLOT_W + 20)
	local cx = x + SLOT_W / 2
	if i == 2 then
		pipe(cx - 14, SLOT_Y + SLOT_H, 28, 432 - SLOT_Y - SLOT_H)
		collar(cx, SLOT_Y + SLOT_H + 8, false)
		collar(cx, 424, false)
	else
		local toward = if i == 1 then 1 else -1
		pipe(cx - 14, SLOT_Y + SLOT_H, 28, 130)
		local px = if toward == 1 then cx - 14 else 410 + 125
		local pw = if toward == 1 then (410 - 125) - (cx - 14) else (cx + 14) - (410 + 125)
		pipe(px, SLOT_Y + SLOT_H + 116, pw, 28)
		collar(cx, SLOT_Y + SLOT_H + 8, false)
		collar(if toward == 1 then 410 - 125 - 8 else 410 + 125 + 8, SLOT_Y + SLOT_H + 130, true)
	end
	local frame = make("Frame", {
		Position = UDim2.fromOffset(x, SLOT_Y), Size = UDim2.fromOffset(SLOT_W, SLOT_H), BackgroundColor3 = SLOT, ZIndex = 2, Parent = panel,
	}, { corner(6), stroke(4) })
	local title = text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 40), Text = "Empty", ZIndex = 3, Parent = frame }, 36)
	local add = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(176, 70), BackgroundColor3 = GREEN,
		Text = "", AutoButtonColor = true, ZIndex = 3, Parent = frame,
	}, { corner(4), stroke(3) })
	studs(add, 0.85)
	text({ Size = UDim2.fromScale(1, 1), Text = "+", FontFace = TITLE, ZIndex = 4, Parent = add }, 64)
	local vf = make("ViewportFrame", { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 205), Visible = false, ZIndex = 3, Parent = frame })
	local remove = make("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = RED,
		Text = "", Visible = false, ZIndex = 5, Parent = frame,
	}, { corner(6), stroke(3) })
	text({ Size = UDim2.fromScale(1, 1), Text = "X", FontFace = TITLE, ZIndex = 6, Parent = remove }, 26)
	slots[i] = { frame = frame, title = title, add = add, vf = vf, remove = remove }
end
local mergeButton = make("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 604), Size = UDim2.fromOffset(340, 60), BackgroundColor3 = GREEN,
	Text = "", AutoButtonColor = true, ZIndex = 2, Parent = panel,
}, { corner(6), stroke(4) })
studs(mergeButton, 0.85)
local mergeLabel = text({ Size = UDim2.fromScale(1, 1), Text = "", FontFace = TITLE, ZIndex = 3, Parent = mergeButton }, 44)
local toast = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 200), Size = UDim2.fromOffset(640, 40), Text = "", TextColor3 = Color3.fromRGB(255, 110, 110), Visible = false, ZIndex = 20, Parent = panel }, 34)

------------------------------------------------------------------ help card (reference: "3 small pets ≈ 1 big pet" + OK)
local help = make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, -18, 0.62, 0), Size = UDim2.fromOffset(330, 230), BackgroundColor3 = PANEL, ZIndex = 10, Visible = false, Parent = panel,
}, { corner(8), stroke(5) })
studs(help, 0.88)
local helpSmall = {}
for k = 1, 3 do
	helpSmall[k] = make("ViewportFrame", {
		Position = UDim2.fromOffset(8 + (k - 1) * 38, 30 + (k % 2) * 26), Size = UDim2.fromOffset(78, 100), BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 205), ZIndex = 11, Parent = help,
	})
end
text({ Position = UDim2.fromOffset(150, 64), Size = UDim2.fromOffset(40, 50), Text = "≈", FontFace = TITLE, ZIndex = 11, Parent = help }, 48)
local helpBig = make("ViewportFrame", { Position = UDim2.fromOffset(186, 8), Size = UDim2.fromOffset(136, 160), BackgroundTransparency = 1, Ambient = Color3.fromRGB(220, 200, 120), ZIndex = 11, Parent = help })
local helpOk = make("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(170, 50), BackgroundColor3 = GREEN, Text = "", ZIndex = 11, Parent = help,
}, { corner(4), stroke(3) })
studs(helpOk, 0.85)
text({ Size = UDim2.fromScale(1, 1), Text = "OK!", FontFace = TITLE, ZIndex = 12, Parent = helpOk }, 40)
helpOk.Activated:Connect(function()
	squish(helpOk)
	tween(help, 0.2, { Position = UDim2.new(0, -18, 0.62, 40) })
	task.delay(0.2, function()
		help.Visible = false
	end)
end)

------------------------------------------------------------------ picker (grouped: each lawyer kind once, with how many you have)
local picker = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(760, 520), BackgroundColor3 = PANEL,
	ZIndex = 30, Visible = false, Parent = panel,
}, { corner(8), stroke(6) })
studs(picker, 0.88)
local pickTitle = text({ Position = UDim2.fromOffset(20, 12), Size = UDim2.new(1, -110, 0, 46), Text = "Pick a lawyer", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = picker }, 40)
local pickClose = make("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(56, 50), BackgroundColor3 = RED, Text = "", ZIndex = 31, Parent = picker }, { corner(6), stroke(3) })
text({ Size = UDim2.fromScale(1, 1), Text = "X", FontFace = TITLE, ZIndex = 32, Parent = pickClose }, 40)
local grid = make("ScrollingFrame", {
	Position = UDim2.fromOffset(16, 68), Size = UDim2.new(1, -32, 1, -84), BackgroundColor3 = SLOT, BorderSizePixel = 0, ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 31, Parent = picker,
}, {
	corner(6), stroke(3),
	make("UIGridLayout", { CellSize = UDim2.fromOffset(166, 196), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10) }),
})
local pickEmpty = text({ Position = UDim2.fromOffset(40, 220), Size = UDim2.new(1, -80, 0, 80), Text = "", TextWrapped = true, ZIndex = 32, Visible = false, Parent = picker }, 30)

------------------------------------------------------------------ state
type Lawyer = { Uid: string, Id: string, Stars: number, Office: number?, Locked: boolean? }
local function lawyers(): { Lawyer }
	local raw = player:GetAttribute("Lawyers")
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and type(list) == "table" then list else {}
end
local function chosenUids(): { [string]: boolean }
	local set = {}
	for _, s in slots do
		if s.uid then
			set[s.uid] = true
		end
	end
	return set
end
local function group(): (string?, number?)
	for _, s in slots do
		if s.id then
			return s.id, s.stars
		end
	end
	return nil, nil
end
local filled = 0
local busy = false

local function showToast(msg: string)
	toast.Text = msg
	toast.Visible = true
	toast.Size = UDim2.fromOffset(0, 40)
	tween(toast, 0.25, { Size = UDim2.fromOffset(640, 40) }, Enum.EasingStyle.Back)
	task.delay(2, function()
		if toast.Text == msg then
			toast.Visible = false
		end
	end)
end

local function renderResult()
	if resultSway then
		resultSway:Disconnect()
		resultSway = nil
	end
	local id, stars = group()
	if filled == NEED and id and stars then
		local nextStars = stars + 1
		local name = Formulas.lawyerName(id, nextStars)
		resultMystery.Visible = false
		resultVf.Visible = true
		resultSway = showLawyer(resultVf, id, true, nextStars)
		resultName.Text = name
		resultEarn.Text = string.format("%s chance · Earns x%s (was x%s)", pct(stars), tostring(Formulas.lawyerEarn(id, nextStars)), tostring(Formulas.lawyerEarn(id, stars)))
		local m = Config.Lawyers.Mutations[nextStars]
		resultGlow.ImageColor3 = if m then m.Color else Color3.fromRGB(255, 205, 60)
		tween(resultGlow, 0.4, { ImageTransparency = 0.25 })
	else
		resultMystery.Visible = true
		resultVf.Visible = false
		resultVf:ClearAllChildren()
		resultName.Text = if id then "Mutate into ?" else ""
		resultEarn.Text = ""
		resultGlow.ImageTransparency = 1
	end
	if busy then
		mergeLabel.Text = "Mutating..."
		mergeButton.BackgroundColor3 = GRAY
	elseif filled == NEED then
		mergeLabel.Text = "MUTATE! (" .. pct(stars or 1) .. ")"
		mergeButton.BackgroundColor3 = GREEN
	else
		local left = NEED - filled
		mergeLabel.Text = string.format("%d Lawyer%s Left", left, if left == 1 then "" else "s")
		mergeButton.BackgroundColor3 = Color3.fromRGB(70, 170, 50)
	end
end

local function setSlot(i: number, l: Lawyer?)
	local s = slots[i]
	s.uid, s.id, s.stars = if l then l.Uid else nil, if l then l.Id else nil, if l then l.Stars else nil
	s.add.Visible = l == nil
	s.vf.Visible = l ~= nil
	s.remove.Visible = l ~= nil
	if l then
		local _, color = rarityOf(l.Id)
		s.title.Text = Formulas.lawyerName(l.Id, l.Stars) .. " " .. starText(l.Stars)
		s.title.TextColor3 = color:Lerp(WHITE, 0.35)
		showLawyer(s.vf, l.Id, false, l.Stars)
		s.vf.Size = UDim2.new(0.4, 0, 0.3, -12)
		s.vf.Position = UDim2.new(0.3, 0, 0, 70)
		tween(s.vf, 0.3, { Size = UDim2.new(1, 0, 1, -40), Position = UDim2.fromOffset(0, 40) }, Enum.EasingStyle.Back)
	else
		s.title.Text = "Empty"
		s.title.TextColor3 = WHITE
		s.vf:ClearAllChildren()
	end
	filled = 0
	for _, o in slots do
		if o.uid then
			filled += 1
		end
	end
	renderResult()
end

local function clearSlots()
	for i = 1, NEED do
		setSlot(i, nil)
	end
end

-- picker: one card per lawyer kind (id + stars) you could still add, with how many spare copies you have
local function openPicker(slotIndex: number)
	for _, c in grid:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local id, stars = group()
	local taken = chosenUids()
	local kinds: { [string]: { id: string, stars: number, copies: { Lawyer } } } = {}
	for _, l in lawyers() do
		if l.Stars < MAX_STARS and not l.Locked and not taken[l.Uid] and (not id or (l.Id == id and l.Stars == stars)) then
			local key = l.Id .. "|" .. l.Stars
			kinds[key] = kinds[key] or { id = l.Id, stars = l.Stars, copies = {} }
			table.insert(kinds[key].copies, l)
		end
	end
	local list = {}
	for _, k in kinds do
		table.insert(list, k)
	end
	-- the ones you can finish a merge with first, then by rarity
	table.sort(list, function(a, b)
		local fa, fb = #a.copies + filled >= NEED, #b.copies + filled >= NEED
		if fa ~= fb then
			return fa
		end
		local ra = (Formulas.getSkin(a.id) or {}).Rarity or 0
		local rb = (Formulas.getSkin(b.id) or {}).Rarity or 0
		if ra ~= rb then
			return ra > rb
		end
		return a.id < b.id
	end)
	pickTitle.Text = if id then "Add another " .. Formulas.lawyerName(id, stars) else "Pick a lawyer to mutate"
	pickEmpty.Visible = #list == 0
	pickEmpty.Text = if id then "You don't have another one. Hatch more from the eggs!" else "No lawyers to mutate yet. Hatch some eggs!"
	for order, k in list do
		local _, color = rarityOf(k.id)
		local ready = #k.copies + filled >= NEED
		local card = make("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = color:Lerp(Color3.fromRGB(40, 40, 60), 0.55), LayoutOrder = order, ZIndex = 32, Parent = grid }, { corner(6), stroke(3, if ready then GREEN else BLACK) })
		local vf = make("ViewportFrame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 120), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 205), ZIndex = 33, Parent = card })
		showLawyer(vf, k.id, false, k.stars)
		text({ Position = UDim2.fromOffset(6, 126), Size = UDim2.new(1, -12, 0, 26), Text = Formulas.lawyerName(k.id, k.stars), ZIndex = 34, Parent = card }, 22)
		text({ Position = UDim2.fromOffset(6, 152), Size = UDim2.new(1, -12, 0, 22), Text = starText(k.stars) .. "   x" .. #k.copies, TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = 34, Parent = card }, 20)
		if ready then
			text({ Position = UDim2.fromOffset(6, 172), Size = UDim2.new(1, -12, 0, 18), Text = "CAN MUTATE!", TextColor3 = GREEN, ZIndex = 34, Parent = card }, 16)
		end
		card.Activated:Connect(function()
			-- inventory copies before ones working in an office
			table.sort(k.copies, function(a, b)
				return (a.Office == nil) and (b.Office ~= nil)
			end)
			picker.Visible = false
			setSlot(slotIndex, k.copies[1])
			-- fill the other empty slots with spare copies straight away (kids just want to press MERGE)
			local spare = 2
			for i = 1, NEED do
				if not slots[i].uid and k.copies[spare] then
					setSlot(i, k.copies[spare])
					spare += 1
				end
			end
		end)
	end
	picker.Visible = true
	picker.Size = UDim2.fromOffset(700, 480)
	tween(picker, 0.25, { Size = UDim2.fromOffset(760, 520) }, Enum.EasingStyle.Back)
end
pickClose.Activated:Connect(function()
	picker.Visible = false
end)
for i, s in slots do
	s.add.Activated:Connect(function()
		if busy then
			return
		end
		squish(s.add)
		openPicker(i)
	end)
	s.remove.Activated:Connect(function()
		if busy then
			return
		end
		setSlot(i, nil)
	end)
end

------------------------------------------------------------------ in-world mutation moment
-- The picker is for choosing; the result plays beside the actual Mutation Machine so mutation feels like
-- something the lawyer does, not another results screen. The machine/result remains server-authoritative.
local RunService = game:GetService("RunService")

local function worldMutationMoment(id: string, stars: number, succeeded: boolean)
	local plots = workspace:FindFirstChild("Plots")
	local plotName = player:GetAttribute("Plot")
	local plot = plots and typeof(plotName) == "string" and plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	-- any seated lawyer will do as the actor (it is redressed as the mutating lawyer); Desk1 can be empty
	local source: Instance? = nil
	for _, desk in (if firm then firm:GetChildren() else {}) do
		local npc = if desk.Name:match("^Desk%d+$") then desk:FindFirstChild("Lawyer") else nil
		if npc then
			source = npc
			break
		end
	end
	local hub = workspace:FindFirstChild("Hub")
	local machine = hub and hub:FindFirstChild("MergeMachine")
	if not (source and source:IsA("Model") and machine and machine:IsA("Model")) then
		return false
	end
	local okClone, actor = pcall(function()
		return (source :: Model):Clone()
	end)
	if not okClone or not actor then
		return false
	end
	actor.Name = "MutationMomentLawyer"
	Sfx.at("gears", machine:GetPivot().Position)
	SkinLook.dress(actor, id, stars)
	for _, item in actor:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
		elseif item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
			item:Destroy()
		end
	end
	actor.Parent = workspace
	local camera = workspace.CurrentCamera
	local oldCameraType = camera and camera.CameraType
	local oldSubject = camera and camera.CameraSubject
	local oldCameraCFrame = camera and camera.CFrame
	local oldFov = camera and camera.FieldOfView
	local homeGuiEnabled = gui.Enabled
	-- the rest of the HUD and the player's own character step aside for the moment (put back below)
	local hiddenGuis: { [LayerCollector]: boolean } = {}
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("LayerCollector") and g ~= gui and g.Enabled then
			hiddenGuis[g] = true
			g.Enabled = false
		end
	end
	local hiddenParts: { BasePart } = {}
	if player.Character then
		for _, p in player.Character:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(hiddenParts, p)
				p.LocalTransparencyModifier = 1
			end
		end
	end
	local success, err = pcall(function()
		-- staged in front of the machine's window (the model faces its pivot's LookVector, diagonally on the plaza)
		local pivot = (machine :: Model):GetPivot()
		local window = machine:FindFirstChild("WindowFrame", true)
		local focus = if window and window:IsA("BasePart") then window.Position else pivot.Position
		local front = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z).Unit
		local right = front:Cross(Vector3.yAxis)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { actor, player.Character :: any, machine }
		local function ground(at: Vector3): Vector3
			local hit = workspace:Raycast(at + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
			return Vector3.new(at.X, if hit then hit.Position.Y else focus.Y - 5, at.Z)
		end
		-- the lawyer works the machine from beside its window, so the camera (front, a little to the other side)
		-- sees its face and the window at once
		local workSpot = ground(focus + front * 3 + right * 3)
		local approach = ground(workSpot + front * 2 + right * 4)
		local away = ground(workSpot + right * 6 + front * 3)
		local faceAt = Vector3.new(focus.X, workSpot.Y, focus.Z) -- (level: looking up at the window tilted the model)
		local box, size = actor:GetBoundingBox()
		local footOffset = actor:GetPivot().Position - (box.Position - Vector3.new(0, size.Y / 2, 0))
		local function pivotAt(ground: Vector3, facing: Vector3)
			local target = CFrame.lookAt(ground + footOffset, facing + footOffset)
			actor:PivotTo(target)
		end
		local function travel(from: CFrame, to: CFrame, duration: number)
			local started = os.clock()
			repeat
				local t = math.clamp((os.clock() - started) / duration, 0, 1)
				actor:PivotTo(from:Lerp(to, t))
				RunService.RenderStepped:Wait()
			until not actor.Parent or os.clock() - started >= duration
		end
		pivotAt(approach, faceAt)
		if camera then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 48
			local mid = (workSpot + focus) / 2 + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(mid + front * 13 - right * 3 + Vector3.new(0, 3, 0), mid)
		end
		gui.Enabled = false
		travel(actor:GetPivot(), CFrame.lookAt(workSpot + footOffset, faceAt + footOffset), 0.85)
		-- A little nervous anticipation: two bouncy checks at the controls.
		local rest = actor:GetPivot()
		for _ = 1, 2 do
			travel(rest, rest + Vector3.new(0, 0.55, 0), 0.16)
			travel(actor:GetPivot(), rest, 0.18)
			task.wait(0.12)
		end
		-- The machine lights up while the lawyer is transformed.
		local effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
		local mutationTier = if succeeded then math.min(stars + 1, MAX_STARS) else stars
		local mutation = Config.Lawyers.Mutations[mutationTier]
		local tint = if succeeded and mutation then mutation.Color else Color3.fromRGB(145, 145, 160)
		effects.burst(focus, "tier", tint)
		for _, part in machine:GetDescendants() do
			if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
				local originalColor = part.Color
				part.Color = tint
				task.delay(0.65, function()
					if part.Parent then part.Color = originalColor end
				end)
			end
		end
		if succeeded then
			SkinLook.dress(actor, id, mutationTier)
			travel(actor:GetPivot(), actor:GetPivot() * CFrame.new(0, 0.7, 0), 0.2)
			travel(actor:GetPivot(), CFrame.lookAt(workSpot + footOffset, faceAt + footOffset) * CFrame.Angles(0, math.rad(24), 0), 0.2)
			task.wait(0.65)
		else
			-- the lawyer turns tail and runs off (facing where it runs)
			local run = (away - workSpot).Unit
			travel(actor:GetPivot(), CFrame.lookAt(workSpot + footOffset, workSpot + run + footOffset), 0.15)
			travel(actor:GetPivot(), CFrame.lookAt(away + footOffset, away + run + footOffset), 0.35)
			travel(actor:GetPivot(), CFrame.lookAt(away + run * 3 + footOffset, away + run * 4 + footOffset), 0.4)
		end
	end)
	if camera and oldCameraType and oldSubject and oldCameraCFrame and oldFov then
		camera.CameraType = oldCameraType
		camera.CameraSubject = oldSubject
		camera.CFrame = oldCameraCFrame
		camera.FieldOfView = oldFov
	end
	gui.Enabled = homeGuiEnabled
	for g in hiddenGuis do
		if g.Parent then
			g.Enabled = true
		end
	end
	for _, p in hiddenParts do
		p.LocalTransparencyModifier = 0
	end
	actor:Destroy()
	if not success then
		warn("[Merger] world mutation moment failed:", err)
	end
	return success
end

------------------------------------------------------------------ merge + animation
local function merge()
	if busy then
		return
	end
	if filled < NEED then
		showToast(string.format("Pick %d of the same lawyer first!", NEED))
		return
	end
	local picks = {}
	for _, s in slots do
		table.insert(picks, s.uid)
	end
	busy = true
	renderResult()
	-- the three fly down the pipes into the window
	for _, s in slots do
		tween(s.vf, 0.45, { Position = UDim2.fromOffset(0, 300), Size = UDim2.fromOffset(SLOT_W, 40) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(s.title, 0.3, { TextTransparency = 1 })
	end
	task.wait(0.4)
	local ok, nameOrReason, _, result = MergeSelected:InvokeServer(picks)
	if not ok then
		busy = false
		for i = 1, NEED do
			slots[i].title.TextTransparency = 0
			setSlot(i, nil)
		end
		showToast(tostring(nameOrReason or "Couldn't mutate"))
		return
	end
	local mutationId, mutationStars = group()
	if mutationId and mutationStars then
		worldMutationMoment(mutationId, mutationStars, result ~= "fizzled")
	end
	if result == "fizzled" then
		-- FIZZLED: the window shakes, a grey puff, and the lawyers run off (no "lose" on screen - CLAUDE.md)
		Sfx.play("goodbye")
		local resultScale0 = resultBox:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = resultBox })
		local home = resultBox.Position
		for k = 1, 8 do
			resultBox.Position = home + UDim2.fromOffset(if k % 2 == 0 then -8 else 8, 0)
			task.wait(0.04)
		end
		resultBox.Position = home
		Effects.guiBurst(gui, UDim2.fromOffset(resultBox.AbsolutePosition.X + resultBox.AbsoluteSize.X / 2, resultBox.AbsolutePosition.Y + resultBox.AbsoluteSize.Y / 2), 360, Color3.fromRGB(150, 150, 165), 1.4, 3)
		resultVf.Visible = false
		resultVf:ClearAllChildren()
		resultMystery.Visible = true
		resultMystery.Text = "?"
		resultGlow.ImageTransparency = 1
		resultScale0.Scale = 0.85
		tween(resultScale0, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		resultName.Text = "FIZZLED!"
		resultEarn.Text = "Your lawyers ran off... try again!"
		task.wait(2.4)
		for _, s in slots do
			s.title.TextTransparency = 0
		end
		busy = false
		clearSlots()
		return
	end
	-- flash + reveal in the window
	local _, stars = group()
	resultMystery.Visible = false
	resultVf.Visible = true
	local flash = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 8, Parent = resultBox }, { corner(6) })
	tween(flash, 0.6, { BackgroundTransparency = 1 })
	task.delay(0.6, flash.Destroy, flash)
	local nextStars = (stars or 1) + 1
	local mut = Config.Lawyers.Mutations[nextStars]
	local burstColor = if mut then mut.Color else Color3.fromRGB(255, 205, 60) -- (the window already shows the mutated lawyer)
	Sfx.play("hit")
	Effects.guiBurst(gui, UDim2.fromOffset(resultBox.AbsolutePosition.X + resultBox.AbsoluteSize.X / 2, resultBox.AbsolutePosition.Y + resultBox.AbsoluteSize.Y / 2), 420, burstColor, 1.8, 3)
	local resultScale = resultBox:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = resultBox })
	resultScale.Scale = 1.25
	tween(resultScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	resultName.Text = string.upper(tostring(nameOrReason)) .. "!"
	task.wait(2.2)
	for _, s in slots do
		s.title.TextTransparency = 0
	end
	busy = false
	clearSlots()
end
mergeButton.Activated:Connect(function()
	squish(mergeButton)
	merge()
end)

------------------------------------------------------------------ open / close
local seenHelp = false
local function fit(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 1
	end
	return math.clamp(math.min(camera.ViewportSize.X / 1250, camera.ViewportSize.Y / 760), 0.42, 1)
end
local function open()
	if gui.Enabled then
		return
	end
	clearSlots()
	picker.Visible = false
	toast.Visible = false
	gui.Enabled = true
	shade.BackgroundTransparency = 1
	tween(shade, 0.2, { BackgroundTransparency = 0.35 })
	panelScale.Scale = 0.6 * fit()
	tween(panelScale, 0.3, { Scale = fit() }, Enum.EasingStyle.Back)
	if not seenHelp then
		seenHelp = true
		local first = lawyers()[1]
		local showId = if first then first.Id else Config.Lawyers.StartId
		for _, vf in helpSmall do
			showLawyer(vf, showId, false)
		end
		showLawyer(helpBig, showId, false)
		help.Visible = true
		help.Position = UDim2.new(0, -18, 0.62, 40)
		tween(help, 0.3, { Position = UDim2.new(0, -18, 0.62, 0) }, Enum.EasingStyle.Back)
	end
end
local function close()
	if busy then
		return
	end
	local t = tween(panelScale, 0.15, { Scale = 0.6 * fit() }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(shade, 0.15, { BackgroundTransparency = 1 })
	t.Completed:Wait()
	gui.Enabled = false
	if resultSway then
		resultSway:Disconnect()
		resultSway = nil
	end
end
closeButton.Activated:Connect(close)

-- keep the slots honest if the lawyer list changes while it's open (a lawyer merged elsewhere, etc.)
player:GetAttributeChangedSignal("Lawyers"):Connect(function()
	if not gui.Enabled or busy then
		return
	end
	local have = {}
	for _, l in lawyers() do
		have[l.Uid] = true
	end
	for i, s in slots do
		if s.uid and not have[s.uid] then
			setSlot(i, nil)
		end
	end
end)

------------------------------------------------------------------ the machine in the hub
local function readyCount(): number
	local counts = {}
	for _, l in lawyers() do
		if l.Stars < MAX_STARS and not l.Locked then
			local k = l.Id .. "|" .. l.Stars
			counts[k] = (counts[k] or 0) + 1
		end
	end
	local n = 0
	for _, c in counts do
		n += c // NEED
	end
	return n
end
-- The hub streams in late (players spawn at their firm) and can stream out and back in as NEW instances, so
-- never hold on to the machine's parts: prompts go through ProximityPromptService, the sign is looked up fresh.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	if prompt.Name == "MergePrompt" then
		open()
	end
end)
local function refreshSign()
	local hub = workspace:FindFirstChild("Hub")
	local machine = hub and hub:FindFirstChild("MergeMachine")
	if not machine then
		return
	end
	local n = readyCount()
	local title = machine:FindFirstChild("Title", true)
	local count = title and title:FindFirstChild("Count") :: TextLabel?
	local mark = machine:FindFirstChild("Mark", true) :: TextLabel?
	if count then
		count.Text = if n > 0 then string.format("%d mutation%s ready!", n, if n == 1 then "" else "s") else "3 same = try to mutate"
		count.TextColor3 = if n > 0 then Color3.fromRGB(110, 255, 90) else WHITE
	end
	if mark then
		mark.Text = if n > 0 then "!" else "?"
		mark.Rotation = if n > 0 then math.sin(os.clock() * 6) * 8 else 0
	end
end
player:GetAttributeChangedSignal("Lawyers"):Connect(refreshSign)
task.spawn(function()
	while true do
		refreshSign() -- also catches the machine streaming in
		task.wait(0.1)
	end
end)
