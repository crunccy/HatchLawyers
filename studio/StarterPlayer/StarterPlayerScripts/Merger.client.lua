--!strict
-- Merger (StarterPlayerScripts.Merger): the MUTATION MACHINE menu (Hub.MergeMachine's MergePrompt opens it).
-- v3 2026-10-21 (mr.robe: "fix the mutations, they don't work right now and i want a better 3d looking menu with some
-- real animations when they mutate, similar to the egg hatching"). Rebuilt on Shared.Skin (Skin.window: dark studded
-- purple panel, purple striped header, red X), in a "3D" look: raised pods with a depth lip, each holding its lawyer
-- live in a ViewportFrame on a gold pedestal (SkinLook.showInViewport), piped into the result chamber.
--   LEFT    three pods (tap + to pick, X to take one out), the pipes, the tier ladder (Normal > Shiny 70% > Diamond 45%
--           > Cosmic 25%, the step you're on lit), and the rule line.
--   RIGHT   the EXACT success chance first (big), the lawyer you'd get in its new colours, "Earns x.. (was x..)", and
--           the big MUTATE! button.
--   PICKER  one card per lawyer kind (id + tier) you could mutate: copies, READY / how many more, and how many are on a
--           case. Picking fills every empty pod: bench copies first, then free offices, then the case ending soonest.
-- A lawyer working a case is never pulled out mid-case (CLAUDE.md): the server WAITS for its case to end (the menu
-- shows "finishing their cases" with the time left and a CANCEL). Before 2026-10-21 the server refused every pick in a
-- busy office - and offices are busy almost all the time - which is why mutating "didn't work".
-- The server decides everything (Remotes.MergeSelected, Server.LawyerService.mergeSelected); then the sequence plays
-- (Shared.MutationFx: the lab stage, the pull-in, the charge, the reveal or a soft fizzle) and the menu comes back.
-- The word "lose" never appears; a fizzle is soft blue. The lawyer list comes from the player's "Lawyers" attribute
-- (PlayerData): { Uid, Id, Stars, Office, Locked }; offices' phases from the Desk<N>Phase / CaseEnd / Queued attributes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local MutationFx = require(Shared:WaitForChild("MutationFx") :: ModuleScript) :: any
local MergeSelected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MergeSelected") :: RemoteFunction

local make = Skin.make
local NEED = Config.Lawyers.MergeCount
local MAX_TIER = #Config.Lawyers.StarEarn
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local PANEL = Color3.fromRGB(43, 33, 66) -- the dark studded purple (Shop / LAWYERS panels)
local POD_TOP, POD_BOTTOM = Color3.fromRGB(92, 60, 160), Color3.fromRGB(40, 26, 80)
local GLOW = Effects.TEXTURES.glow -- (Skin.Assets.Glow has no permission in this place: open item)
local TIER_NAMES = { "Normal", "Shiny", "Diamond", "Cosmic" }

local function tierColor(t: number): Color3
	local m = Config.Lawyers.Mutations[t]
	return if m then m.Color else Color3.fromRGB(200, 205, 220)
end
local function pct(stars: number): number
	return math.floor(Formulas.mutateChance(stars) * 100 + 0.5)
end
local function rarityOf(id: string): Color3
	local def = Formulas.getSkin(id)
	local r = def and Config.Eggs.Skins[def.Rarity]
	return if r and Config.RarityColors and Config.RarityColors[r.Id] then Config.RarityColors[r.Id] else Color3.fromRGB(150, 150, 170)
end
local function fmtX(n: number): string
	return if n == math.floor(n) then string.format("%d", n) else string.format("%.1f", n)
end
local function clock(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

------------------------------------------------------------------ the player's lawyers + offices
type Lawyer = { Uid: string, Id: string, Stars: number, Office: number?, Locked: boolean? }
local function lawyers(): { Lawyer }
	local raw = player:GetAttribute("Lawyers")
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and type(list) == "table" then list else {}
end
-- an office's state: busy (walking in / on a case) and the seconds its case has left (nil while walking in)
local function officeState(office: number?): (boolean, number?)
	if not office then
		return false, nil
	end
	local phase = player:GetAttribute("Desk" .. office .. "Phase")
	if phase ~= "Case" and phase ~= "Walking" then
		return false, nil
	end
	local ends = player:GetAttribute("Desk" .. office .. "CaseEnd")
	return true, if typeof(ends) == "number" then ends - workspace:GetServerTimeNow() else nil
end
-- uids waiting to go INTO an office when its case ends (the server refuses those)
local function queuedIn(): { [string]: boolean }
	local set = {}
	for i = 1, Config.Desks.MaxDesks do
		local q = player:GetAttribute("Desk" .. i .. "Queued")
		if typeof(q) == "string" and q ~= "unseat" then
			set[q] = true
		end
	end
	return set
end
-- usable copies first: bench, then free offices, then the case that ends soonest
local function copyRank(l: Lawyer): number
	if not l.Office then
		return 0
	end
	local busy, left = officeState(l.Office)
	if not busy then
		return 1
	end
	return 2 + (left or 600)
end

-- a lawyer model to copy for the 3D previews (the desk lawyers; any firm will do)
local function sourceLawyer(): Model?
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	local mine = plots:FindFirstChild(tostring(player:GetAttribute("Plot")))
	for _, plot in (if mine then { mine } else {}) :: { Instance } do
		local firm = plot:FindFirstChild("Firm")
		for _, d in (if firm then firm:GetChildren() else {}) :: { Instance } do
			local l = if string.match(d.Name, "^Desk%d+$") then d:FindFirstChild("Lawyer") else nil
			if l and l:IsA("Model") then
				return l
			end
		end
	end
	for _, d in plots:GetDescendants() do
		if d.Name == "Lawyer" and d:IsA("Model") and d.Parent and string.match(d.Parent.Name, "^Desk%d+$") then
			return d
		end
	end
	return nil
end

-- a lawyer standing on a little gold pedestal in a ViewportFrame, swaying (the connection is returned)
local function showLawyer(vf: ViewportFrame, id: string, stars: number): RBXScriptConnection?
	vf:ClearAllChildren()
	local source = sourceLawyer()
	if not source then
		return nil
	end
	local conn = SkinLook.showInViewport(vf, source, id, stars)
	local model = vf:FindFirstChildOfClass("Model")
	if model then
		local box, size = model:GetBoundingBox()
		local bottom = box.Position.Y - size.Y / 2
		local d = math.max(size.X, size.Z) * 1.05
		local function disc(dia: number, h: number, y: number, c: Color3, mat: Enum.Material)
			local p = make("Part", {
				Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, dia, dia), Color = c, Material = mat, Anchored = true,
				CFrame = CFrame.new(box.Position.X, y, box.Position.Z) * CFrame.Angles(0, 0, math.pi / 2), Parent = vf,
			})
			return p
		end
		disc(d + 0.35, 0.12, bottom - size.Y * 0.06, Color3.fromRGB(90, 230, 255), Enum.Material.Neon)
		disc(d, size.Y * 0.06, bottom - size.Y * 0.03 - 0.02, Color3.fromRGB(230, 170, 30), Enum.Material.SmoothPlastic)
	end
	return conn
end

------------------------------------------------------------------ the window
local W, H = 1000, 600
local win = Skin.window({ Name = "Merger", Title = "Mutation Machine", Color = "Purple", Icon = HudMenu.Icons.Merge, Size = Vector2.new(W, H), DisplayOrder = 32 })
win.panel.BackgroundColor3 = PANEL
local body = win.body :: Frame
local BODY_H = H - 92

-- a raised "3D" box: a dark depth lip under it, a top-lit gradient, studs, an inner light bevel, the ink outline
local function pod(parent: GuiObject, pos: UDim2, size: UDim2, z: number, top: Color3?, bottom: Color3?): Frame
	make("Frame", {
		Name = "Depth", Position = pos + UDim2.fromOffset(0, 8), Size = size, BackgroundColor3 = Color3.fromRGB(18, 10, 34), ZIndex = z,
		Parent = parent,
	}, { Skin.corner(16), Skin.stroke(4) })
	local f = make("Frame", { Name = "Pod", Position = pos, Size = size, BackgroundColor3 = WHITE, ZIndex = z + 1, Parent = parent }, {
		Skin.corner(16), Skin.stroke(4),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(top or POD_TOP, bottom or POD_BOTTOM) }),
	})
	Skin.studs(f, 0.9, nil, 24)
	make("Frame", { Name = "Bevel", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = z + 1,
		Interactable = false, Parent = f }, { Skin.corner(13), make("UIStroke", { Thickness = 2, Color = Color3.fromRGB(190, 150, 255), Transparency = 0.45 }) })
	Skin.gloss(f, 0.12)
	return f
end

local subtitle = Skin.text({ Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(624, 40), RichText = true, ZIndex = 3, Parent = body,
	Text = string.format('Bring <font color="#%s">%d</font> of the same lawyer', ORANGE:ToHex(), NEED) }, 32, 4)

------------------------------------------------------------------ the three pods
type Slot = { frame: Frame, vf: ViewportFrame, add: TextButton, remove: TextButton, title: TextLabel, badge: TextLabel, glow: ImageLabel,
	sway: RBXScriptConnection?, uid: string?, id: string?, stars: number?, office: number? }
local slots: { Slot } = {}
local POD_W, POD_H = 196, 262
for i = 1, NEED do
	local x = 16 + (i - 1) * (POD_W + 18)
	local f = pod(body, UDim2.fromOffset(x, 52), UDim2.fromOffset(POD_W, POD_H), 3)
	local glow = make("ImageLabel", { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(240, 240),
		BackgroundTransparency = 1, Image = GLOW, ImageTransparency = 1, ZIndex = 4, Interactable = false, Parent = f })
	local vf = make("ViewportFrame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -54), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 160, 200),
		LightColor = WHITE, LightDirection = Vector3.new(-0.6, -1, -0.8), ZIndex = 5, Parent = f })
	local strip = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -12, 0, 40),
		BackgroundColor3 = Color3.fromRGB(24, 16, 44), BackgroundTransparency = 0.15, ZIndex = 6, Parent = f }, { Skin.corner(10) })
	local title = Skin.text({ Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), Text = "Empty", ZIndex = 7, Parent = strip }, 26, 3)
	local add = make("TextButton", { Name = "Add", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.42, 0), Size = UDim2.fromOffset(104, 104),
		BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, ZIndex = 8, Parent = f }, {
		make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(4),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(141, 235, 94), Color3.fromRGB(42, 138, 23)) }),
	})
	Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.8, 0.8), Text = "+",
		FontFace = Skin.Fonts.Number, ZIndex = 9, Parent = add }, 80, 4)
	Skin.pressable(add, 1.1)
	local remove = Skin.button({ Name = "Remove", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(40, 38),
		Style = "Red", Text = "X", Font = Skin.Fonts.Number, TextSize = 30, Corner = 6, Studs = false, ZIndex = 9, Parent = f }).button
	remove.Visible = false
	local badge = Skin.text({ Name = "Busy", Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(150, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = ORANGE, Visible = false, ZIndex = 9, Parent = f }, 20, 3)
	slots[i] = { frame = f, vf = vf, add = add, remove = remove, title = title, badge = badge, glow = glow }
end

-- the pipes from the pods into the result chamber, with a glowing collar per pod
local collars: { Frame } = {}
local PIPE_Y = 52 + POD_H + 12
make("Frame", { Name = "Pipe", Position = UDim2.fromOffset(16 + POD_W / 2 - 9, PIPE_Y + 18), Size = UDim2.fromOffset(656 - (16 + POD_W / 2 - 9), 18),
	BackgroundColor3 = Color3.fromRGB(70, 44, 130), ZIndex = 2, Parent = body }, { Skin.stroke(3) })
for i = 1, NEED do
	local cx = 16 + (i - 1) * (POD_W + 18) + POD_W / 2
	make("Frame", { Name = "Drop", Position = UDim2.fromOffset(cx - 9, PIPE_Y - 4), Size = UDim2.fromOffset(18, 30), BackgroundColor3 = Color3.fromRGB(70, 44, 130),
		ZIndex = 2, Parent = body }, { Skin.stroke(3) })
	collars[i] = make("Frame", { Name = "Collar", Position = UDim2.fromOffset(cx - 15, PIPE_Y + 2), Size = UDim2.fromOffset(30, 10), BackgroundColor3 = Color3.fromRGB(60, 60, 80),
		ZIndex = 3, Parent = body }, { Skin.corner(3), Skin.stroke(2) })
end

-- the tier ladder: Normal > Shiny > Diamond > Cosmic, with each step's exact chance
local ladderChips: { Frame } = {}
local ladderArrows: { TextLabel } = {}
local LADDER_Y = PIPE_Y + 52
for t = 1, MAX_TIER do
	local x = 16 + (t - 1) * 162
	local c = tierColor(t)
	local chip = make("Frame", { Name = "Tier" .. t, Position = UDim2.fromOffset(x, LADDER_Y), Size = UDim2.fromOffset(118, 46), BackgroundColor3 = WHITE, ZIndex = 3, Parent = body }, {
		Skin.corner(10), Skin.stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(c:Lerp(WHITE, 0.25), c:Lerp(Color3.new(0, 0, 0), 0.35)) }),
	})
	Skin.text({ Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), Text = TIER_NAMES[t] or ("Tier " .. t), ZIndex = 4, Parent = chip }, 26, 3)
	ladderChips[t] = chip
	if t < MAX_TIER then
		local arrow = Skin.text({ Position = UDim2.fromOffset(x + 118, LADDER_Y + 18), Size = UDim2.fromOffset(44, 30), Text = ">", FontFace = Skin.Fonts.Number,
			ZIndex = 4, Parent = body }, 30, 3)
		Skin.text({ Position = UDim2.fromOffset(-8, -22), Size = UDim2.fromOffset(60, 22), Text = pct(t) .. "%", TextColor3 = tierColor(t + 1):Lerp(WHITE, 0.35),
			ZIndex = 4, Parent = arrow }, 20, 2)
		ladderArrows[t] = arrow
	end
end
local rule = Skin.text({ Position = UDim2.fromOffset(16, LADDER_Y + 56), Size = UDim2.fromOffset(624, 34), RichText = true, FontFace = Skin.Fonts.Body, ZIndex = 3, Parent = body,
	Text = "" }, 22, 2)
local RULE_TEXT = string.format('Mutated lawyers earn <font color="#%s">way more</font>... If it fizzles, all %d run off! <font color="#%s">Locked</font> lawyers stay safe.',
	Skin.Lime:ToHex(), NEED, Color3.fromRGB(255, 214, 60):ToHex())
rule.Text = RULE_TEXT

------------------------------------------------------------------ the result chamber (right)
local RX, RW = 660, 324
Skin.text({ Position = UDim2.fromOffset(RX, 0), Size = UDim2.fromOffset(RW, 24), Text = "SUCCESS CHANCE", ZIndex = 3, Parent = body }, 22, 3)
local chanceLabel = Skin.text({ Position = UDim2.fromOffset(RX, 32), Size = UDim2.fromOffset(RW, 62), Text = "--", FontFace = Skin.Fonts.Number, ZIndex = 3, Parent = body }, 66, 5)
local meter = make("Frame", { Position = UDim2.fromOffset(RX + 12, 98), Size = UDim2.fromOffset(RW - 24, 18), BackgroundColor3 = Color3.fromRGB(24, 16, 44), ZIndex = 3, Parent = body },
	{ make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(3) })
local meterFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, ZIndex = 4, Parent = meter },
	{ make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 190, 190)) }) })
local chamber = pod(body, UDim2.fromOffset(RX, 128), UDim2.fromOffset(RW, 214), 3, Color3.fromRGB(70, 46, 130), Color3.fromRGB(26, 16, 54))
local resultGlow = make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 300), BackgroundTransparency = 1,
	Image = GLOW, ImageTransparency = 1, ZIndex = 4, Interactable = false, Parent = chamber })
local resultVf = make("ViewportFrame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 160, 200),
	LightColor = WHITE, LightDirection = Vector3.new(-0.6, -1, -0.8), ZIndex = 5, Parent = chamber })
local resultMystery = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(150, 150), Text = "?",
	FontFace = Skin.Fonts.Number, TextColor3 = Color3.fromRGB(150, 130, 200), ZIndex = 6, Parent = chamber }, 140, 6)
local ribbon: Frame? = nil
local resultName = Skin.text({ Position = UDim2.fromOffset(RX, 352), Size = UDim2.fromOffset(RW, 34), Text = "", ZIndex = 3, Parent = body }, 30, 3)
local resultEarn = Skin.text({ Position = UDim2.fromOffset(RX, 386), Size = UDim2.fromOffset(RW, 26), Text = "", RichText = true, FontFace = Skin.Fonts.Body, ZIndex = 3, Parent = body }, 22, 2)
local mutate = Skin.button({ Name = "Mutate", Position = UDim2.fromOffset(RX, 420), Size = UDim2.fromOffset(RW, 72), Text = "PICK 3 LAWYERS", TextSize = 40, Style = "Grey", ZIndex = 4, Parent = body })
local resultSway: RBXScriptConnection? = nil

------------------------------------------------------------------ the waiting cover (picks finishing their cases)
local cover = make("Frame", { Name = "Waiting", Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -12), BackgroundColor3 = Color3.fromRGB(28, 20, 48),
	BackgroundTransparency = 0.06, Visible = false, ZIndex = 40, Parent = body }, { Skin.corner(12), Skin.stroke(4) })
Skin.blockClicks(cover).ZIndex = 40
Skin.studs(cover, 0.92, nil, 26)
Skin.text({ Position = UDim2.fromOffset(20, 26), Size = UDim2.new(1, -40, 0, 54), Text = "Your lawyers are finishing their cases...", ZIndex = 41, Parent = cover }, 46, 5)
Skin.text({ Position = UDim2.fromOffset(20, 84), Size = UDim2.new(1, -40, 0, 32), FontFace = Skin.Fonts.Body, RichText = true, ZIndex = 41, Parent = cover,
	Text = "The machine waits for them - nobody is pulled out of a case. New clients go to other offices." }, 26, 2)
local coverList = Skin.text({ Position = UDim2.fromOffset(20, 140), Size = UDim2.new(1, -40, 0, 190), Text = "", RichText = true, ZIndex = 41, Parent = cover }, 34, 3)
local cancel = Skin.button({ Name = "Cancel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(240, 64), Text = "CANCEL",
	TextSize = 34, Style = "Red", ZIndex = 42, Parent = cover })

------------------------------------------------------------------ the picker
local picker = make("Frame", { Name = "Picker", Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -12), BackgroundColor3 = Color3.fromRGB(32, 24, 54),
	Visible = false, ZIndex = 30, Parent = body }, { Skin.corner(12), Skin.stroke(4) })
Skin.blockClicks(picker).ZIndex = 30
Skin.studs(picker, 0.92, nil, 26)
local pickTitle = Skin.text({ Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -110, 0, 50), Text = "Pick a lawyer to mutate", TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 31, Parent = picker }, 40, 4)
local pickClose = Skin.button({ Name = "PickClose", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(56, 50), Style = "Red",
	Text = "X", Font = Skin.Fonts.Number, TextSize = 40, Corner = 6, Studs = false, ZIndex = 32, Parent = picker }).button
local pickScroll = Skin.scroller(picker, { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 1, -74) })
pickScroll.ZIndex = 31
local pickGrid = Skin.grid(pickScroll, Vector2.new(172, 222), 1, 12)
pickGrid.ZIndex = 31
local pickEmpty = Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -80, 0, 80), Text = "", TextWrapped = true,
	Visible = false, ZIndex = 33, Parent = picker }, 32, 3)
local pickerSways: { RBXScriptConnection } = {}

------------------------------------------------------------------ state
local busy = false -- mutating (or waiting for cases)
local function filledCount(): number
	local n = 0
	for _, s in slots do
		if s.uid then
			n += 1
		end
	end
	return n
end
local function group(): (string?, number?)
	for _, s in slots do
		if s.id then
			return s.id, s.stars
		end
	end
	return nil, nil
end

local function setLadder(stars: number?)
	for t, chip in ladderChips do
		local lit = stars ~= nil and (t == stars or t == stars + 1)
		chip.BackgroundTransparency = if stars == nil or lit then 0 else 0.55
		local s = chip:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = if lit and t == (stars or 0) + 1 then WHITE else Skin.Ink
			s.Thickness = if lit and t == (stars or 0) + 1 then 4 else 3
		end
	end
	for t, a in ladderArrows do
		local dim = if stars == nil or t == stars then 0 else 0.55
		a.TextTransparency = dim
		local label = a:FindFirstChildOfClass("TextLabel")
		if label then
			label.TextTransparency = dim
		end
	end
end

-- the button + the rule line (also ticked while open: a pick's case time counts down)
local function renderStatus()
	local _, stars = group()
	local n = filledCount()
	if busy then
		mutate.setText("MUTATING...")
		mutate.setStyle("Grey")
	elseif n == NEED and stars then
		mutate.setText(string.format("MUTATE! %d%%", pct(stars)))
		mutate.setStyle("Green")
	else
		mutate.setText(if n == 0 then string.format("PICK %d LAWYERS", NEED) else string.format("ADD %d MORE", NEED - n))
		mutate.setStyle("Orange")
	end
	-- a pick that's on a case: the machine will wait for it
	local waits = {}
	for _, s in slots do
		local b, left = officeState(s.office)
		if s.uid and b then
			table.insert(waits, if left then clock(left) else "walking in")
		end
	end
	rule.Text = if #waits > 0 then string.format('<font color="#%s">%d on a case (%s)</font>: the machine waits for them to finish.', ORANGE:ToHex(), #waits, table.concat(waits, ", "))
		else RULE_TEXT
end

-- the chance, the result lawyer, the ladder, the pipes (when the picks change)
local function render()
	local id, stars = group()
	for i, s in slots do
		collars[i].BackgroundColor3 = if s.uid then GREEN else Color3.fromRGB(60, 60, 80)
	end
	setLadder(stars)
	if resultSway then
		resultSway:Disconnect()
		resultSway = nil
	end
	if ribbon then
		ribbon:Destroy()
		ribbon = nil
	end
	if id and stars then
		local nextStars = stars + 1
		local c = tierColor(nextStars)
		local p = pct(stars)
		chanceLabel.Text = p .. "%"
		chanceLabel.TextColor3 = c:Lerp(WHITE, 0.25)
		Skin.tween(meterFill, 0.4, { Size = UDim2.fromScale(p / 100, 1), BackgroundColor3 = c }, Enum.EasingStyle.Back)
		resultMystery.Visible = false
		resultSway = showLawyer(resultVf, id, nextStars)
		resultGlow.ImageColor3 = c
		Skin.tween(resultGlow, 0.4, { ImageTransparency = 0.35 })
		resultName.Text = Formulas.lawyerName(id, nextStars)
		resultName.TextColor3 = c:Lerp(WHITE, 0.5)
		resultEarn.Text = string.format('Earns <font color="#%s">x%s</font> (was x%s)', Skin.Lime:ToHex(), fmtX(Formulas.lawyerEarn(id, nextStars)), fmtX(Formulas.lawyerEarn(id, stars)))
		ribbon = Skin.ribbon(chamber, string.upper(TIER_NAMES[nextStars] or ""), c, 12)
	else
		chanceLabel.Text = "--"
		chanceLabel.TextColor3 = WHITE
		Skin.tween(meterFill, 0.3, { Size = UDim2.fromScale(0, 1) })
		resultMystery.Visible = true
		resultVf:ClearAllChildren()
		Skin.tween(resultGlow, 0.2, { ImageTransparency = 1 }) -- (a tween: a running fade-in would win over a plain set)
		resultName.Text = if id then "Mutate into ?" else ""
		resultEarn.Text = ""
	end
	renderStatus()
end

local function setSlot(i: number, l: Lawyer?)
	local s = slots[i]
	if s.sway then
		s.sway:Disconnect()
		s.sway = nil
	end
	s.uid, s.id, s.stars, s.office = if l then l.Uid else nil, if l then l.Id else nil, if l then l.Stars else nil, if l then l.Office else nil
	s.add.Visible = l == nil
	s.remove.Visible = l ~= nil
	if l then
		local c = rarityOf(l.Id)
		s.title.Text = Formulas.lawyerName(l.Id, l.Stars)
		s.title.TextColor3 = (if l.Stars > 1 then tierColor(l.Stars) else c):Lerp(WHITE, 0.4)
		s.sway = showLawyer(s.vf, l.Id, l.Stars)
		s.glow.ImageColor3 = c
		s.glow.ImageTransparency = 0.45
		local sc = s.vf:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = s.vf })
		sc.Scale = 0.3
		Skin.tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		s.title.Text = "Empty"
		s.title.TextColor3 = WHITE
		s.vf:ClearAllChildren()
		s.glow.ImageTransparency = 1
	end
	render()
end

local function clearSlots()
	for i = 1, NEED do
		setSlot(i, nil)
	end
end

-- the busy badges tick down while the window is open
task.spawn(function()
	while true do
		task.wait(0.25)
		if win.isOpen() then
			for _, s in slots do
				local b, left = officeState(s.office)
				s.badge.Visible = s.uid ~= nil and b
				s.badge.Text = if left then "ON A CASE " .. clock(left) else "WALKING IN"
			end
			if not busy and filledCount() > 0 then
				renderStatus()
			end
		end
	end
end)

------------------------------------------------------------------ picking
type Kind = { id: string, stars: number, copies: { Lawyer }, onCase: number }
local function kinds(): { Kind }
	local id, stars = group()
	local taken = {}
	for _, s in slots do
		if s.uid then
			taken[s.uid] = true
		end
	end
	local q = queuedIn()
	local byKey: { [string]: Kind } = {}
	for _, l in lawyers() do
		if l.Stars < MAX_TIER and not l.Locked and not q[l.Uid] and not taken[l.Uid] and (not id or (l.Id == id and l.Stars == stars)) then
			local key = l.Id .. "|" .. l.Stars
			local k = byKey[key] or { id = l.Id, stars = l.Stars, copies = {}, onCase = 0 }
			byKey[key] = k
			table.insert(k.copies, l)
			if officeState(l.Office) then
				k.onCase += 1
			end
		end
	end
	local list = {}
	for _, k in byKey do
		table.sort(k.copies, function(a, b)
			return copyRank(a) < copyRank(b)
		end)
		table.insert(list, k)
	end
	local filled = filledCount()
	table.sort(list, function(a, b)
		local ra, rb = #a.copies + filled >= NEED, #b.copies + filled >= NEED
		if ra ~= rb then
			return ra
		end
		local da, db = (Formulas.getSkin(a.id) or {}).Rarity or 0, (Formulas.getSkin(b.id) or {}).Rarity or 0
		if da ~= db then
			return da > db
		end
		if a.stars ~= b.stars then
			return a.stars > b.stars
		end
		return a.id < b.id
	end)
	return list
end

local function closePicker()
	picker.Visible = false
	for _, c in pickerSways do
		c:Disconnect()
	end
	table.clear(pickerSways)
end

local function openPicker()
	closePicker()
	for _, c in pickGrid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local id, stars = group()
	local list = kinds()
	local filled = filledCount()
	pickTitle.Text = if id and stars then "Add another " .. Formulas.lawyerName(id, stars) else "Pick a lawyer to mutate"
	pickEmpty.Visible = #list == 0
	pickEmpty.Text = if id then "You don't have another one. Hatch more from the eggs!" else "No lawyers to mutate yet. Hatch some eggs!"
	for order, k in list do
		local ready = #k.copies + filled >= NEED
		local card = Skin.card(pickGrid, { Name = "Kind", Color = rarityOf(k.id), LayoutOrder = order, ZIndex = 32 })
		local vf = make("ViewportFrame", { Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 132), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 160, 200),
			LightColor = WHITE, LightDirection = Vector3.new(-0.6, -1, -0.8), ZIndex = 35, Parent = card })
		local conn = showLawyer(vf, k.id, k.stars)
		if conn then
			table.insert(pickerSways, conn)
		end
		Skin.text({ Position = UDim2.fromOffset(6, 136), Size = UDim2.new(1, -12, 0, 26), Text = Formulas.lawyerName(k.id, k.stars), ZIndex = 36, Parent = card }, 22, 3)
		Skin.text({ Position = UDim2.fromOffset(6, 160), Size = UDim2.new(1, -12, 0, 24), Text = "x" .. #k.copies .. (if k.onCase > 0 then string.format("  (%d on a case)", k.onCase) else ""),
			TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = 36, Parent = card }, 20, 2)
		local chip = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -16, 0, 28),
			BackgroundColor3 = if ready then GREEN else Color3.fromRGB(70, 70, 90), ZIndex = 36, Parent = card }, { Skin.corner(8), Skin.stroke(2) })
		Skin.text({ Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 2), ZIndex = 37, Parent = chip,
			Text = if ready then "READY!" else string.format("NEED %d MORE", NEED - filled - #k.copies) }, 20, 2)
		local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 38, Parent = card })
		hit.Activated:Connect(function()
			closePicker()
			-- fill every empty pod, best copies first
			local nxt = 1
			for i = 1, NEED do
				if not slots[i].uid and k.copies[nxt] then
					setSlot(i, k.copies[nxt])
					nxt += 1
				end
			end
			Sfx.play("lawyerEquip", { volume = 0.6 })
		end)
	end
	picker.Visible = true
	Skin.pop(picker, 0.85)
end
pickClose.Activated:Connect(closePicker)

for i, s in slots do
	s.add.Activated:Connect(function()
		if not busy then
			openPicker()
		end
	end)
	s.remove.Activated:Connect(function()
		if not busy then
			setSlot(i, nil)
		end
	end)
end

------------------------------------------------------------------ mutate
local function toast(msg: string)
	Skin.toast({ Text = msg, Highlight = "", Hold = 2.4, Parent = win.gui, Position = UDim2.new(0.5, 0, 0, 40), TextSize = 28 })
end

local function mutateNow()
	if busy then
		return
	end
	local n = filledCount()
	local id, stars = group()
	if n < NEED or not id or not stars then
		openPicker()
		return
	end
	local picks = {}
	local waitFor = {}
	for _, s in slots do
		table.insert(picks, s.uid)
		if officeState(s.office) then
			table.insert(waitFor, s)
		end
	end
	busy = true
	render()
	-- the pods glow and their lawyers zip down the pipes
	for i, s in slots do
		Skin.tween(s.glow, 0.25, { ImageTransparency = 0.1, ImageColor3 = tierColor(stars + 1) })
		collars[i].BackgroundColor3 = WHITE
	end
	Sfx.play("gears", { volume = 0.5 })
	-- picks on a case: the server waits; show it (with the time left and a CANCEL)
	local watching = #waitFor > 0
	if watching then
		cover.Visible = true
		Skin.pop(cover, 0.9)
		task.spawn(function()
			while watching do
				local lines = {}
				for _, s in waitFor do
					local b, left = officeState(s.office)
					table.insert(lines, string.format("%s  <font color=\"#%s\">%s</font>", Formulas.lawyerName(s.id :: string, s.stars :: number),
						(if b then ORANGE else GREEN):ToHex(), if not b then "ready!" elseif left then clock(left) else "walking in"))
				end
				coverList.Text = table.concat(lines, "\n")
				task.wait(0.2)
			end
		end)
	end
	local ok, nameOrReason, _, result = MergeSelected:InvokeServer(picks)
	watching = false
	cover.Visible = false
	if not ok then
		busy = false
		for i, s in slots do
			s.glow.ImageTransparency = if s.uid then 0.45 else 1
			s.glow.ImageColor3 = if s.id then rarityOf(s.id) else WHITE
			collars[i].BackgroundColor3 = if s.uid then GREEN else Color3.fromRGB(60, 60, 80)
		end
		-- drop picks that are gone (sold, mutated elsewhere ...)
		local have = {}
		for _, l in lawyers() do
			have[l.Uid] = true
		end
		for i, s in slots do
			if s.uid and not have[s.uid] then
				setSlot(i, nil)
			end
		end
		render()
		if nameOrReason ~= "Cancelled" then
			Sfx.play("error", { volume = 0.6 })
			toast(tostring(nameOrReason or "Couldn't mutate"))
		end
		return
	end
	-- the sequence: the window steps aside, the lab plays it out, then the window comes back (empty pods)
	local success = result == "mutated"
	local source = sourceLawyer()
	win.gui.Enabled = false
	if source then
		MutationFx.play({
			id = id, tier = stars, success = success, source = source, name = tostring(nameOrReason),
			earnFrom = Formulas.lawyerEarn(id, stars), earnTo = Formulas.lawyerEarn(id, stars + 1), chance = Formulas.mutateChance(stars),
		})
	end
	busy = false
	clearSlots()
	win.gui.Enabled = true
	subtitle.Text = if success then string.format('<font color="#%s">%s!</font> Bring 3 more to go again', tierColor(stars + 1):Lerp(WHITE, 0.3):ToHex(), tostring(nameOrReason))
		else "It fizzled... bring 3 more and try again!"
	task.delay(6, function()
		if not busy then
			subtitle.Text = string.format('Bring <font color="#%s">%d</font> of the same lawyer', ORANGE:ToHex(), NEED)
		end
	end)
end
mutate.button.Activated:Connect(mutateNow)
cancel.button.Activated:Connect(function()
	task.spawn(function()
		MergeSelected:InvokeServer("cancel")
	end)
end)

------------------------------------------------------------------ open / close
local function open()
	if win.isOpen() or MutationFx.isPlaying() then
		return
	end
	busy = false
	clearSlots()
	closePicker()
	cover.Visible = false
	win.open()
end
win.onClose(function()
	if busy then -- (closing while it waits for cases stops the wait; the lawyers stay as they are)
		task.spawn(function()
			MergeSelected:InvokeServer("cancel")
		end)
	end
	closePicker()
	for i = 1, NEED do
		local s = slots[i]
		if s.sway then
			s.sway:Disconnect()
			s.sway = nil
		end
	end
	if resultSway then
		resultSway:Disconnect()
		resultSway = nil
	end
end)

-- keep the pods honest if the lawyer list changes while it's open (sold, locked, moved elsewhere ...)
player:GetAttributeChangedSignal("Lawyers"):Connect(function()
	if not win.isOpen() or busy then
		return
	end
	local have: { [string]: Lawyer } = {}
	for _, l in lawyers() do
		have[l.Uid] = l
	end
	for i, s in slots do
		local l = s.uid and have[s.uid]
		if s.uid and (not l or l.Locked or l.Stars ~= s.stars) then
			setSlot(i, nil)
		elseif l then
			s.office = l.Office
		end
	end
end)

------------------------------------------------------------------ the machine in the hub
local function readyCount(): number
	local counts = {}
	local q = queuedIn()
	for _, l in lawyers() do
		if l.Stars < MAX_TIER and not l.Locked and not q[l.Uid] then
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
ProximityPromptService.PromptTriggered:Connect(function(prompt)
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
		refreshSign() -- also catches the machine streaming in (and wiggles the "!")
		task.wait(0.1)
	end
end)
render()
