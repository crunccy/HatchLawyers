--!strict
-- LAWYERS panel v3 (2026-10-23, crnuch: "the lawyer ui is quite confusing to navigate, there's a lot going on").
-- ONE job per tab, in the UI v3 look (docs/UI_STYLE_V3.md: purple striped header, coloured side tabs, rarity cards):
--   OFFICES     every office as a card - its lawyer, level, status (FREE / ON A CASE m:ss / CLIENT ARRIVING / SWAPS
--               AFTER CASE / EMPTY) and ONE button: UPGRADE (Remotes.TrainLawyer) or, empty, EQUIP LAWYER (-> MY
--               LAWYERS aimed at it). Footer: UPGRADE ALL OFFICES + EQUIP BEST. Tap an office's picture for its
--               details pop-up: the lawyer big, UPGRADE + MAX, SKILLS (StarterPlayerScripts.Skills), UNEQUIP (queued on
--               a busy office: "UNEQUIP AFTER CASE", CANCEL CHANGE = Remotes.CancelLawyerChange), SWAP LAWYER.
--   MY LAWYERS  every lawyer you own as a rarity card; tap one and it shows on the right with EQUIP IN OFFICE N (< >
--               picks the office; EQUIP AFTER THIS CASE on a busy one), SELL (Epic and up: tap twice) and LOCK. Footer:
--               SELL ALL... (tick rarities) + EQUIP BEST. A "3x" tag points to the Mutation Machine.
-- Wording is EQUIP / UNEQUIP everywhere (user's call: easier for kids than seat / unseat / place). No CLIENTS tab:
-- clients walk straight to a free lawyer since v16 (the server's WaitingClients list is always empty).
-- Opened by: the LAWYERS HUD tile, an empty office's Place Lawyer prompt (Remotes.OpenLawyerPicker), the hatch
-- screen's equip button - all through the local ReplicatedStorage.LawyersUI bindable: Fire(office) or
-- Fire({ office = n?, tab = "Offices" | "Bench" }) (an empty office opens MY LAWYERS aimed at it).
-- The server checks everything (Server.CaseService / LawyerService). This only reads mirrored attributes:
--   Lawyers (JSON { Uid, Id, Stars, Skills, Office, Locked }), DeskCount, Desk<N>Lawyer / Stars / Level / Phase /
--   CaseStart / CaseEnd / ClientName / Queued / FreeSkillRolls / PendingSkill.
-- Sets the local SelectedDesk attribute (Courtroom and Skills follow it).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceLawyer = Remotes:WaitForChild("PlaceLawyer") :: RemoteFunction
local OpenLawyerPicker = Remotes:WaitForChild("OpenLawyerPicker") :: RemoteEvent
local MarkSkinsSeen = Remotes:WaitForChild("MarkSkinsSeen") :: RemoteEvent
local TrainLawyer = Remotes:WaitForChild("TrainLawyer") :: RemoteFunction
local CancelLawyerChange = Remotes:WaitForChild("CancelLawyerChange") :: RemoteFunction
-- 2026-10-13: selling + locking (Server.LawyerService) and mutation colours (Shared.MutationLook)
local SellLawyers = Remotes:WaitForChild("SellLawyers") :: RemoteFunction
local LockLawyer = Remotes:WaitForChild("LockLawyer") :: RemoteFunction
local MutationLook = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MutationLook") :: ModuleScript) :: any
local Effects = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Effects") :: ModuleScript) :: any

-- local hooks: other scripts open this panel (LawyersUI) and the Skills screen (SkillsUI)
local function bindable(name: string): BindableEvent
	local e = ReplicatedStorage:FindFirstChild(name) :: BindableEvent?
	if not e then
		e = Instance.new("BindableEvent")
		;(e :: BindableEvent).Name = name
		;(e :: BindableEvent).Parent = ReplicatedStorage
	end
	return e :: BindableEvent
end
local openEvent = bindable("LawyersUI")
local skillsEvent = bindable("SkillsUI")

local STUDS = "rbxassetid://114488299634202" -- tools/ui_textures.py
local SHINE = "rbxassetid://101930347288469"
local FONT = UIFonts.PrimaryFace
local TITLE = UIFonts.TitleFace
local BODY = UIFonts.BodyFace
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local PURPLE = Color3.fromRGB(176, 52, 255)
local PURPLE_DARK = Color3.fromRGB(122, 30, 214)
local PANEL = Skin.Panel
local SLOT = Color3.fromRGB(32, 31, 47)
local CARD = Color3.fromRGB(62, 60, 88)
local GREEN = Color3.fromRGB(76, 224, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local GOLD = Color3.fromRGB(255, 200, 40)
local RED = Color3.fromRGB(228, 32, 32)
local GRAY = Color3.fromRGB(120, 120, 135)
local SOFT = Color3.fromRGB(205, 200, 235) -- secondary text on the dark panel
local SKIN_TONE = Color3.fromRGB(255, 204, 153)

local W, H = 920, 600 -- design size; a UIScale fits it to the screen

------------------------------------------------------------------ helpers
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
-- Phone readability (2026-10-12). The panel is laid out at W x H and shrunk with a UIScale (fit(): ~0.58 on a
-- landscape phone), and TextScaled squeezes long strings further, so a long lawyer name or client situation
-- ended up ~5 px on screen. Labels registered with small() switch to COMPACT mode while the panel is drawn below
-- COMPACT_BELOW: a fixed TextSize of at least MIN_SCREEN_PX real pixels (capped by the box's height per line),
-- truncated with "..." or wrapped onto two lines, instead of shrinking. Above it they scale as before.
local COMPACT_BELOW = 0.8
local MIN_SCREEN_PX = 11
local compact, currentScale = false, 1
type SmallInfo = { max: number, wrap: boolean, truncate: Enum.TextTruncate }
local smallLabels: { [TextLabel]: SmallInfo } = setmetatable({}, { __mode = "k" }) :: any
local function applySmall(l: TextLabel, info: SmallInfo)
	l.TextWrapped = info.wrap
	if compact then
		local lines = if info.wrap then 2.3 else 1 -- two lines plus line spacing
		local cap = math.max(math.floor(l.Size.Y.Offset / lines), info.max)
		l.TextScaled = false
		l.TextSize = math.min(math.max(info.max, math.ceil(MIN_SCREEN_PX / currentScale)), cap)
		l.TextTruncate = Enum.TextTruncate.AtEnd
	else
		l.TextScaled = true
		l.TextTruncate = info.truncate
	end
end
local function small(l: TextLabel, wrap: boolean?): TextLabel
	local c = l:FindFirstChildOfClass("UITextSizeConstraint")
	local info = { max = if c then c.MaxTextSize else 14, wrap = wrap == true, truncate = l.TextTruncate }
	smallLabels[l] = info
	applySmall(l, info)
	return l
end
-- called with the panel's target scale whenever it's fitted to the screen
local function setTextMode(scale: number)
	local nowCompact = scale < COMPACT_BELOW
	if nowCompact ~= compact or (nowCompact and scale ~= currentScale) then
		compact, currentScale = nowCompact, scale
		for l, info in smallLabels do
			applySmall(l, info)
		end
	end
	currentScale = scale
end
local function studs(parent: GuiObject, transparency: number)
	local c = parent:FindFirstChildOfClass("UICorner")
	make("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = STUDS, ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(34, 34), ZIndex = parent.ZIndex, Parent = parent,
	}, { make("UICorner", { CornerRadius = if c then c.CornerRadius else UDim.new() }) })
end
local function squish(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = gui })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
-- a chunky button in the shared Skin look (Shared.Skin, 2026-10-10 UI pass): top-lit gradient over its own
-- BackgroundColor3 (so setButton's recolouring still works), inner bevel, dark lip, soft gloss, studs, ink outline,
-- grow on hover / squish on press. Returns the button and its label.
local function button(props: { [string]: any }, label: string, maxSize: number): (TextButton, TextLabel)
	props.Text = ""
	props.AutoButtonColor = false
	local b = make("TextButton", props, { corner(8), stroke(3) })
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.new(0.94, 0.94, 0.94)),
		ColorSequenceKeypoint.new(1, Color3.new(0.74, 0.74, 0.74)),
	}), Parent = b })
	make("Frame", { Name = "Bevel", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1,
		ZIndex = b.ZIndex, Interactable = false, Parent = b }, { corner(6), make("UIStroke", { Thickness = 1.5, Color = WHITE, Transparency = 0.7 }) })
	make("Frame", { Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.14, 0),
		BackgroundColor3 = BLACK, BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = b.ZIndex, Interactable = false, Parent = b }, { corner(8) })
	studs(b, 0.9)
	Skin.gloss(b, 0.12)
	local l = text({ Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -8), Text = label, ZIndex = b.ZIndex + 1, Parent = b }, maxSize)
	Skin.pressable(b)
	return b, l
end
local function mmss(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end
local function serverNow(): number
	return workspace:GetServerTimeNow()
end

------------------------------------------------------------------ state readers (server-mirrored attributes)
type Lawyer = { Uid: string, Id: string, Stars: number, Skills: { any }, Office: number?, Locked: boolean? }
type Client = { Id: number, Tier: number, Name: string?, Situation: string?, Seated: boolean }
type Office = {
	index: number,
	lawyerId: string?,
	uid: string?,
	stars: number,
	level: number,
	phase: string,
	caseStart: number?,
	caseEnd: number?,
	clientName: string?,
	queued: string?,
	skillsReady: boolean,
}

local function decode(name: string): any
	local raw = player:GetAttribute(name)
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok and typeof(value) == "table" then value else {}
end
local function lawyers(): { Lawyer }
	return decode("Lawyers")
end
local function deskCount(): number
	local n = player:GetAttribute("DeskCount")
	return if typeof(n) == "number" then n else 0
end
local function office(i: number): Office
	local key = "Desk" .. i
	local id = player:GetAttribute(key .. "Lawyer") :: string?
	local phase = player:GetAttribute(key .. "Phase") :: string?
	return {
		index = i,
		lawyerId = id,
		uid = player:GetAttribute(key .. "LawyerUid") :: string?,
		stars = (player:GetAttribute(key .. "Stars") :: number?) or 1,
		level = (player:GetAttribute(key .. "Level") :: number?) or 1,
		phase = if not id then "Empty" else (phase or "Idle"),
		caseStart = player:GetAttribute(key .. "CaseStart") :: number?,
		caseEnd = player:GetAttribute(key .. "CaseEnd") :: number?,
		clientName = player:GetAttribute(key .. "ClientName") :: string?,
		queued = player:GetAttribute(key .. "Queued") :: string?,
		skillsReady = ((player:GetAttribute(key .. "FreeSkillRolls") :: number?) or 0) > 0 or player:GetAttribute(key .. "PendingSkill") ~= nil,
	}
end
local function isBusy(o: Office): boolean
	return o.phase == "Case" or o.phase == "Walking"
end
-- waiting-room clients, most valuable first (rarest, then who came first)
local function waitingClients(): { Client }
	local list = decode("WaitingClients") :: { Client }
	table.sort(list, function(a, b)
		if a.Seated ~= b.Seated then
			return a.Seated
		end
		if a.Tier ~= b.Tier then
			return a.Tier > b.Tier
		end
		return a.Id < b.Id
	end)
	return list
end
local function rarityOf(id: string?): (string, Color3)
	local def = id and Formulas.getSkin(id)
	local r = def and Config.Eggs.Skins[def.Rarity]
	local name = if r then r.Id else "Common"
	return name, Config.RarityColors[name] or WHITE
end
local function clientColor(tier: number): Color3
	local def = Config.Clients[tier]
	return (def and Config.RarityColors[def.Id]) or WHITE
end
local function lawyerName(id: string, stars: number): string
	return Formulas.lawyerName(id, stars)
end
-- a lawyer's mutation as a tag: "SHINY" / "DIAMOND" / "COSMIC" in its colour ("" for Normal) - replaced the stars
local function mutationTag(stars: number): (string, Color3)
	local name, color = MutationLook.info(stars)
	return string.upper(name), color or GOLD
end
-- what selling pays - the same as the server's Formulas.sellPrice, from this player's own egg prices
local function sellValue(l: Lawyer): number
	local def = Formulas.getSkin(l.Id)
	if not def then
		return 0
	end
	local egg = Formulas.themedEgg(def.Egg)
	local price = (player:GetAttribute(if egg then egg.Id .. "EggPrice" else "EggPrice") :: number?) or 0
	local share = Config.Lawyers.Sell.Share[def.Rarity] or 0
	local mut = Config.Lawyers.StarEarn[math.clamp(l.Stars, 1, #Config.Lawyers.StarEarn)]
	return math.floor(price * share * mut)
end
local function findLawyer(list: { Lawyer }, uid: string?): Lawyer?
	for _, l in list do
		if l.Uid == uid then
			return l
		end
	end
	return nil
end
local function copiesOf(list: { Lawyer }, l: Lawyer): number
	local n = 0
	for _, o in list do
		if o.Id == l.Id and o.Stars == l.Stars then
			n += 1
		end
	end
	return n
end
local function firstFreeOffice(): number?
	for i = 1, deskCount() do
		if office(i).phase == "Idle" then
			return i
		end
	end
	return nil
end
local function bestFreeOffice(): number?
	local best, bestScore = nil, -1
	for i = 1, deskCount() do
		local o = office(i)
		if o.phase == "Idle" and o.lawyerId then
			local score = Formulas.basePayout(o.level) * Formulas.lawyerEarn(o.lawyerId, o.stars)
			if score > bestScore then
				best, bestScore = i, score
			end
		end
	end
	return best
end

-- status of an office for the slot pill / detail line: label, colour, case progress (0..1 or nil)
local function status(o: Office): (string, Color3, number?)
	if not o.lawyerId then
		return "EMPTY", GRAY, nil
	end
	if isBusy(o) and o.queued then
		return if o.queued == "unseat" then "UNEQUIPS AFTER CASE" else "SWAPS AFTER CASE", PURPLE, nil
	end
	if o.phase == "Case" and o.caseStart and o.caseEnd then
		local left = o.caseEnd - serverNow()
		local total = math.max(o.caseEnd - o.caseStart, 0.1)
		return if left > 0 then "ON A CASE " .. mmss(left) else "WRAPPING UP", ORANGE, math.clamp(1 - left / total, 0, 1)
	end
	if o.phase == "Walking" then
		return "CLIENT ARRIVING", ORANGE, 0
	end
	return "FREE", GREEN, nil
end

-- mini lawyer drawn from frames: only a fallback for a lawyer without a 3D model
local function drawIcon(parent: Instance, id: string, scale: number, y: number)
	local skin = Formulas.getSkin(id) :: any
	if not skin then
		return
	end
	local holder = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.fromOffset(80 * scale, 96 * scale), BackgroundTransparency = 1, ZIndex = (parent :: any).ZIndex or 1, Parent = parent })
	local z = holder.ZIndex
	local function block(x: number, by: number, w: number, h: number, color: Color3, round: number?)
		make("Frame", { Position = UDim2.fromOffset(x * scale, by * scale), Size = UDim2.fromOffset(w * scale, h * scale), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = holder }, if round then { corner(round * scale) } else nil)
	end
	block(23, 18, 34, 32, skin.Head or SKIN_TONE, 6)
	block(14, 52, 52, 32, skin.Suit, 4)
	block(2, 52, 12, 30, skin.Suit, 4)
	block(66, 52, 12, 30, skin.Suit, 4)
	block(36, 52, 8, 26, skin.Tie)
	block(16, 84, 48, 12, skin.Pants, 3)
	local hatColor = skin.HatColor or skin.Suit
	if skin.Hat == "Cap" then
		block(21, 10, 38, 12, hatColor, 6)
		block(40, 18, 24, 5, hatColor)
	elseif skin.Hat == "TopHat" then
		block(16, 16, 48, 5, hatColor)
		block(26, 0, 28, 18, hatColor)
	elseif skin.Hat == "Crown" then
		block(22, 8, 36, 10, hatColor)
		for _, x in { 22, 36, 50 } do
			block(x, 0, 8, 10, hatColor)
		end
	elseif skin.Hat == "Shades" then
		block(22, 26, 36, 8, hatColor)
	end
end

-- THE REAL LAWYER in 3D (user's call 2026-10-09: no 2D cut-outs). Every catalog lawyer is a rigged model in
-- ReplicatedStorage.SkinModels; Shared.SkinLook poses it exactly like the desks do (joints baked, anchored). Built on
-- an invisible stand-in body, so it works anywhere (the firm's desk lawyers stream out at the hub). One posed master
-- per lawyer id, cloned into each ViewportFrame.
local modelCache: { [string]: Model | false } = {}
local function lawyerModel(id: string, stars: number?): Model?
	local cached = modelCache[id]
	if cached == nil then
		cached = false
		local skin = Formulas.getSkin(id)
		if skin and skin.Model then
			local base = Instance.new("Model")
			local body = Instance.new("Part")
			body.Name = "StandIn"
			body.Anchored = true
			body.Transparency = 1
			body.Size = Vector3.new(2, 5, 1)
			body.CFrame = CFrame.new(0, 2.5, 0) -- feet at y = 0, facing -Z like every character
			body.Parent = base
			base.PrimaryPart = body
			SkinLook.dress(base, id)
			if base:FindFirstChild("SkinModel") then
				for _, d in base:GetDescendants() do
					if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") or d:IsA("Sound")
						or d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("Highlight") or d:IsA("Humanoid") then
						d:Destroy()
					end
				end
				base.PrimaryPart = nil
				body:Destroy()
				cached = base
			else
				base:Destroy()
			end
		end
		modelCache[id] = cached
	end
	if not cached then
		return nil
	end
	local m = (cached :: Model):Clone()
	if (stars or 1) > 1 then
		MutationLook.apply(m, stars) -- (the master stays plain; each copy wears its own mutation)
	end
	return m
end

-- A ViewportFrame showing that lawyer, framed head to toe, turned a little toward the light. Returns the frame and
-- its model (nil for a lawyer without a 3D model: then the drawn icon is used instead).
local function lawyerViewport(parent: GuiObject, id: string, aspect: number, yaw: number?, stars: number?): (ViewportFrame?, Model?)
	local m = lawyerModel(id, stars)
	if not m then
		return nil, nil
	end
	local vf = make("ViewportFrame", {
		Name = "Lawyer3D", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = parent.ZIndex,
		Ambient = Color3.fromRGB(165, 165, 175), LightColor = Color3.fromRGB(255, 250, 240), LightDirection = Vector3.new(-0.5, -1, 0.7),
	})
	local box, size = m:GetBoundingBox()
	m:PivotTo(CFrame.new(box.Position) * CFrame.Angles(0, math.rad(yaw or 18), 0) * CFrame.new(box.Position):Inverse() * m:GetPivot())
	box, size = m:GetBoundingBox()
	m.Parent = vf
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- fit the taller of: its height, or its width for this frame's shape
	local half = math.max(size.Y / 2, size.X / 2 / math.max(aspect, 0.2)) * 0.96
	local dist = half / math.tan(math.rad(15)) + size.Z / 2
	camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(0, size.Y * 0.04, -dist), box.Position)
	camera.Parent = vf
	vf.CurrentCamera = camera
	vf.Parent = parent
	return vf, m
end

------------------------------------------------------------------ layout (v3, 2026-10-23: two tabs, one job each)
-- (two tables keep the script under Luau's 200-locals limit: P = the picked lawyer, D = the office details pop-up)
local P: { [string]: any } = {}
local D: { [string]: any } = {}
local playerGui = player:WaitForChild("PlayerGui")
local gui = make("ScreenGui", { Name = "Lawyers", ResetOnSpawn = false, DisplayOrder = 32, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
local shade = make("TextButton", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, Parent = gui })
shade:SetAttribute("NoSkin", true)

-- HUD button: the LAWYERS tile in the shared left-edge menu column (Shared.HudMenu, real gavel icon)
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local menuEntry = HudMenu.button({ name = "Lawyers", label = "LAWYERS", icon = "Lawyers", color = PURPLE, order = 2 })
local openButton = menuEntry.button

local RAIL_W = 186 -- the side tabs float outside the panel's right edge
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = PANEL, Visible = false, Active = true, Parent = gui,
}, { corner(10), stroke(6), panelScale })
panel:SetAttribute("NoSkin", true)
Skin.blockClicks(panel) -- (Active = true alone doesn't stop a tap on empty space reaching the Shade and closing it)
local sw = Skin.swatch("Purple")
make("Frame", { Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = panel },
	{ corner(8), make("UIStroke", { Thickness = 2, Color = Color3.fromHex("6A44A8"), Transparency = 0.2 }) })
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
})
make("Frame", { Position = UDim2.new(0, -4, 1, 0), Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = Skin.Ink, BorderSizePixel = 0, ZIndex = 3, Parent = header })
Skin.studs(header, 0.8, nil, 26)
Skin.stripes(header, 0.74, 4, 0.06)
local headerIcon = make("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, -8), Size = UDim2.fromOffset(88, 88), Rotation = -6, BackgroundTransparency = 1,
	Image = HudMenu.Icons.Lawyers, ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = header })
Skin.breathe(headerIcon, 3, 0.3)
Skin.text({ Position = UDim2.fromOffset(92, 8), Size = UDim2.fromOffset(300, 54), FontFace = Skin.Fonts.Title, Text = "Lawyers",
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header }, 50, 5)
local countLabel = text({ Position = UDim2.fromOffset(330, 22), Size = UDim2.new(1, -440, 0, 30), Text = "", TextColor3 = Color3.fromRGB(255, 225, 90), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = header }, 22)
local closeButton = Skin.closeButton(header, 58, 4)

-- the two tabs, coloured blocks beside the panel (the Shop's look)
local rail = make("Frame", { Name = "SideRail", Position = UDim2.new(1, 10, 0, 84), Size = UDim2.fromOffset(176, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Parent = panel })
make("Frame", { Name = "List", Size = UDim2.fromOffset(176, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = rail },
	{ make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
local tabButtons: { [string]: TextButton } = {
	Offices = Skin.sideTab(rail, { Label = "Offices", Icon = HudMenu.Icons.Upgrades, Color = "Gold", LayoutOrder = 1 }),
	Bench = Skin.sideTab(rail, { Label = "My lawyers", Icon = HudMenu.Icons.Lawyers, Color = "Purple", LayoutOrder = 2 }),
}
local benchTabLabel = tabButtons.Bench:FindFirstChildWhichIsA("TextLabel") :: TextLabel

-- one line under the header that says what this tab is for (feedback pops over it)
local infoText = text({ Position = UDim2.fromOffset(22, 82), Size = UDim2.new(1, -44, 0, 28), FontFace = BODY, Text = "", RichText = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = SOFT, Parent = panel }, 20, 0)
small(infoText)
local VIEW_Y, FOOT_H = 116, 62

-- OFFICES: every office as a card with ONE button
local officesView = make("Frame", { Name = "Offices", Position = UDim2.fromOffset(20, VIEW_Y), Size = UDim2.new(1, -40, 1, -VIEW_Y - FOOT_H - 16), BackgroundTransparency = 1, Parent = panel })
local slotBar = make("ScrollingFrame", {
	Name = "OfficeGrid", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = officesView,
}, {
	make("UIGridLayout", { CellSize = UDim2.fromOffset(206, 196), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) }),
})

-- MY LAWYERS: the grid on the left, the picked lawyer and its buttons on the right
local benchFrame = make("Frame", { Name = "MyLawyers", Position = UDim2.fromOffset(20, VIEW_Y), Size = UDim2.new(1, -40, 1, -VIEW_Y - FOOT_H - 16), BackgroundTransparency = 1, Visible = false, Parent = panel })
local benchGrid = make("ScrollingFrame", {
	Size = UDim2.new(1, -316, 1, 0), BackgroundColor3 = Skin.PanelDeep, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = benchFrame,
}, {
	corner(8), stroke(4),
	make("UIGridLayout", { CellSize = UDim2.fromOffset(122, 150), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})
local detail = make("Frame", { Name = "Picked", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 304, 1, 0),
	BackgroundColor3 = Skin.PanelDeep, Parent = benchFrame }, { corner(8), stroke(4) })
P.pickPreview = make("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 126), BackgroundColor3 = WHITE, ClipsDescendants = true, Parent = detail }, { corner(6), stroke(3) })
P.pickGradient = make("UIGradient", { Rotation = 90, Parent = P.pickPreview })
P.pickArt = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = P.pickPreview })
P.pickTag = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(110, 22), Text = "", TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = P.pickPreview }, 20)
P.pickName = text({ Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 28), Text = "", TextColor3 = Color3.fromRGB(255, 225, 90), Parent = detail }, 26)
P.pickRarity = make("Frame", { Position = UDim2.fromOffset(10, 172), Size = UDim2.fromOffset(110, 22), BackgroundColor3 = PURPLE, Parent = detail }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
P.pickRarityText = text({ Size = UDim2.fromScale(1, 1), Text = "", Parent = P.pickRarity }, 16)
P.pickEarn = text({ Position = UDim2.fromOffset(128, 172), Size = UDim2.new(1, -138, 0, 22), Text = "", TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Parent = detail }, 20)
P.pickNote = small(text({ Position = UDim2.fromOffset(10, 198), Size = UDim2.new(1, -20, 0, 40), FontFace = BODY, Text = "", RichText = true, TextColor3 = SOFT,
	TextWrapped = true, Parent = detail }, 17, 0), true)
-- which office EQUIP puts it in: < Office N >
P.targetRow = make("Frame", { Position = UDim2.fromOffset(10, 242), Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, Parent = detail })
local prevTarget = button({ Size = UDim2.fromOffset(40, 34), BackgroundColor3 = PURPLE, Parent = P.targetRow }, "<", 22)
local nextTarget = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 34), BackgroundColor3 = PURPLE, Parent = P.targetRow }, ">", 22)
P.targetText = text({ Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -92, 1, 0), Text = "", Parent = P.targetRow }, 20)
local placeButton, placeLabel = button({ Position = UDim2.fromOffset(10, 282), Size = UDim2.new(1, -20, 0, 50), BackgroundColor3 = GREEN, Parent = detail }, "PICK A LAWYER", 22)
placeLabel.TextWrapped = true
Skin.glint(placeButton)
local sellButton, sellLabel = button({ Position = UDim2.fromOffset(10, 340), Size = UDim2.new(0.62, -14, 0, 44), BackgroundColor3 = ORANGE, Parent = detail }, "SELL", 20)
sellLabel.TextWrapped = true
local lockButton, lockLabel = button({ Position = UDim2.new(0.62, 2, 0, 340), Size = UDim2.new(0.38, -12, 0, 44), BackgroundColor3 = Color3.fromRGB(90, 200, 255), Parent = detail }, "LOCK", 20)
P.pickEmpty = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -40, 0, 80), FontFace = BODY,
	Text = "Tap a lawyer to see it here", TextColor3 = SOFT, TextWrapped = true, ZIndex = 5, Parent = detail }, 22, 0)

-- the footer: Offices = UPGRADE ALL + EQUIP BEST, My lawyers = SELL ALL + EQUIP BEST
local footer = make("Frame", { Position = UDim2.new(0, 20, 1, -FOOT_H - 12), Size = UDim2.new(1, -40, 0, FOOT_H), BackgroundTransparency = 1, Parent = panel })
local allButton, allLabel = button({ Size = UDim2.new(0.6, -6, 1, 0), BackgroundColor3 = GREEN, Parent = footer }, "UPGRADE ALL OFFICES", 26)
Skin.glint(allButton)
local sellAllButton, sellAllLabel = button({ Size = UDim2.new(0.6, -6, 1, 0), BackgroundColor3 = RED, Visible = false, Parent = footer }, "SELL ALL...", 26)
local bestButton, bestLabel = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.4, -6, 1, 0), BackgroundColor3 = GOLD, Parent = footer }, "EQUIP BEST", 26)

-- the SELL ALL picker: tick rarities, see what it sells and for how much, SELL
local sellAll = make("Frame", { Name = "SellAll", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, -316, 0, 176),
	BackgroundColor3 = Skin.PanelDeep, Visible = false, ZIndex = 30, Parent = benchFrame }, { corner(8), stroke(4) })
text({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), Text = "SELL ALL OF THESE RARITIES", ZIndex = 31, Parent = sellAll }, 22)
P.chipRow = make("Frame", { Position = UDim2.fromOffset(10, 38), Size = UDim2.new(1, -20, 0, 36), BackgroundTransparency = 1, ZIndex = 31, Parent = sellAll },
	{ make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
P.sellAllNote = text({ Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 0, 24), FontFace = BODY, Text = "", TextColor3 = SOFT, ZIndex = 31, Parent = sellAll }, 18, 0)
local sellAllGo, sellAllGoLabel = button({ Position = UDim2.new(0, 10, 1, -60), Size = UDim2.new(0.62, -15, 0, 50), BackgroundColor3 = RED, ZIndex = 31, Parent = sellAll }, "SELL", 22)
local sellAllCancel = button({ Position = UDim2.new(0.62, 5, 1, -60), Size = UDim2.new(0.38, -15, 0, 50), BackgroundColor3 = Color3.fromRGB(90, 200, 255), ZIndex = 31, Parent = sellAll }, "CANCEL", 22)
local sellRarities: { [number]: boolean } = { [1] = true, [2] = true } -- Common + Uncommon ticked to start
local chips: { [number]: TextButton } = {}
for i, tier in Config.Eggs.Skins do
	local chip = make("TextButton", { Size = UDim2.fromOffset(62, 34), BackgroundColor3 = Config.RarityColors[tier.Id] or WHITE, Text = "", AutoButtonColor = true, ZIndex = 32, Parent = P.chipRow }, { corner(8), stroke(3) })
	chip:SetAttribute("NoSkin", true)
	small(text({ Size = UDim2.fromScale(1, 1), Text = string.upper(tier.Id), ZIndex = 33, Parent = chip }, 12))
	chips[i] = chip
end

-- OFFICE DETAILS pop-up (tap an office's picture): the lawyer big, UPGRADE / MAX, SKILLS, UNEQUIP, SWAP
D.popupDim = make("TextButton", { Name = "PopupDim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false,
	Visible = false, ZIndex = 40, Parent = panel }, { corner(10) })
D.popupDim:SetAttribute("KeepStyle", true)
local left = make("Frame", { Name = "OfficeDetails", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.fromOffset(330, 448),
	BackgroundColor3 = Skin.PanelDeep, Visible = false, ZIndex = 41, Parent = panel }, { corner(10), stroke(5) })
Skin.blockClicks(left)
D.popupClose = Skin.closeButton(left, 40, 45)
D.popupClose.Position = UDim2.new(1, 10, 0, 6)
local preview = make("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 130), BackgroundColor3 = WHITE, ClipsDescendants = true, ZIndex = 42, Parent = left }, { corner(6), stroke(3) })
D.previewGradient = make("UIGradient", { Rotation = 90, Parent = preview })
D.viewport = make("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightDirection = Vector3.new(-1, -1, -1), ZIndex = 43, Parent = preview })
D.iconHolder = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 43, Parent = preview })
D.emptyPlus = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(90, 90), Text = "+", FontFace = TITLE, ZIndex = 44, Visible = false, Parent = preview }, 90)
local officeTag = text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(170, 22), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 45, Parent = preview }, 20)
D.starsLabel = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(100, 26), Text = "", TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 45, Parent = preview }, 22)
D.nameLabel = text({ Position = UDim2.fromOffset(12, 146), Size = UDim2.new(1, -24, 0, 30), Text = "", TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = 42, Parent = left }, 26)
D.rarityPill = make("Frame", { Position = UDim2.fromOffset(12, 180), Size = UDim2.fromOffset(104, 22), BackgroundColor3 = PURPLE, ZIndex = 42, Parent = left }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
D.rarityText = text({ Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 43, Parent = D.rarityPill }, 16)
D.earnLabel = text({ Position = UDim2.fromOffset(124, 180), Size = UDim2.new(1, -136, 0, 22), Text = "", TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = left }, 20)
D.statusLabel = small(text({ Position = UDim2.fromOffset(12, 208), Size = UDim2.new(1, -24, 0, 22), FontFace = BODY, Text = "", TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, Parent = left }, 18, 0))
D.statusBar = make("Frame", { Position = UDim2.fromOffset(12, 232), Size = UDim2.new(1, -24, 0, 10), BackgroundColor3 = Color3.fromRGB(20, 12, 40), Visible = false, ZIndex = 42, Parent = left }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
D.statusFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, ZIndex = 43, Parent = D.statusBar }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local upgradeButton, upgradeLabel = button({ Position = UDim2.fromOffset(12, 252), Size = UDim2.new(0.62, -16, 0, 54), BackgroundColor3 = GREEN, ZIndex = 42, Parent = left }, "UPGRADE", 20)
upgradeLabel.TextWrapped = true
local maxButton, maxLabel = button({ Position = UDim2.new(0.62, 2, 0, 252), Size = UDim2.new(0.38, -14, 0, 54), BackgroundColor3 = Color3.fromRGB(40, 170, 30), ZIndex = 42, Parent = left }, "MAX", 20)
maxLabel.TextWrapped = true
local skillsButton, skillsLabel = button({ Position = UDim2.fromOffset(12, 314), Size = UDim2.new(0.5, -16, 0, 50), BackgroundColor3 = GOLD, ZIndex = 42, Parent = left }, "SKILLS", 22)
D.skillsBang = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = RED, Visible = false, ZIndex = 46, Parent = skillsButton }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2, WHITE) })
text({ Size = UDim2.fromScale(1, 1), Text = "!", FontFace = TITLE, ZIndex = 47, Parent = D.skillsBang }, 18)
local unseatButton, unseatLabel = button({ Position = UDim2.new(0.5, 4, 0, 314), Size = UDim2.new(0.5, -16, 0, 50), BackgroundColor3 = ORANGE, ZIndex = 42, Parent = left }, "UNEQUIP", 20)
unseatLabel.TextWrapped = true
local swapButton = button({ Position = UDim2.fromOffset(12, 372), Size = UDim2.new(1, -24, 0, 54), BackgroundColor3 = PURPLE, ZIndex = 42, Parent = left }, "SWAP LAWYER", 24)

-- where the upgrade celebrations play: moved over the office being upgraded (Shared.UpgradeFx draws inside it)
-- (parked off the panel when nothing plays: lying over Office 1 it ate that card's taps)
local PARKED = UDim2.fromOffset(-4000, -4000)
local fxAnchor = make("Frame", { Name = "UpgradeFxAnchor", Position = PARKED, Size = UDim2.fromOffset(206, 196), BackgroundTransparency = 1, ZIndex = 50, Interactable = false, Parent = panel })
local fxTag = text({ Size = UDim2.new(1, 0, 0, 22), Text = "", Visible = false, ZIndex = 51, Parent = fxAnchor }, 18)

-- feedback pill over the info line (never covers a button)
local toastPill = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(660, 40), BackgroundColor3 = Color3.fromHex("4FB6EE"), Visible = false, ZIndex = 60, Parent = panel }, { corner(10), stroke(3) })
Skin.stripes(toastPill, 0.72, 4, 0.05)
local toast = text({ Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 1, -8), Text = "", TextColor3 = WHITE, ZIndex = 61, Parent = toastPill }, 26)

------------------------------------------------------------------ rendering
local selectedOffice = 1
local tab = "Offices"
local benchPick: string? = nil
local busy = false
local previewKey: string? = nil
local previewConn: RBXScriptConnection? = nil
local pickKey: string? = nil
type SlotRefs = { card: Frame, pill: Frame, pillText: TextLabel, fill: Frame, level: TextLabel, up: TextButton, upLabel: TextLabel, key: string? }
local slotRefs: { [number]: SlotRefs } = {}
local previewHome: CFrame? = nil
-- an upgrade's hop + spin for the details' lawyer (set by Shared.UpgradeFx, played by renderPreview's loop)
local kick = { t0 = -math.huge, dur = 0, hop = 0, spins = 0, bounces = 1 }
local render: () -> ()

local function flash(msg: string, color: Color3?)
	toast.Text = msg
	toastPill.BackgroundColor3 = if color == RED then Color3.fromHex("E53030") elseif color == GOLD then Color3.fromHex("FFBE1F") else Color3.fromHex("4FB6EE")
	toastPill.Visible = true
	squish(toastPill)
	task.delay(2.2, function()
		if toast.Text == msg then
			toastPill.Visible = false
		end
	end)
end

-- v3 (crnuch 2026-10-23: no gray): a disabled button is muted purple, not gray
local MUTED = Color3.fromHex("6E5A96")
local function setButton(b: TextButton, l: TextLabel, label: string, color: Color3, enabled: boolean)
	l.Text = label
	b.BackgroundColor3 = if enabled then color else MUTED
	b.AutoButtonColor = enabled
	b:SetAttribute("Enabled", enabled)
end

local function selectOffice(i: number)
	local count = math.max(deskCount(), 1)
	selectedOffice = math.clamp(i, 1, count)
	player:SetAttribute("SelectedDesk", selectedOffice) -- the Courtroom and Skills follow it
end

local function upgradeText(o: Office): (string, boolean)
	local coins = (player:GetAttribute("Coins") :: number?) or 0
	if o.level >= Config.Lawyer.MaxLevel then
		return "MAX LEVEL", false
	end
	if ((player:GetAttribute("FreeLevelUps") :: number?) or 0) > 0 then
		return "UPGRADE · FREE!", true
	end
	local cost = Formulas.trainCost(o.level)
	return "UPGRADE · $" .. Formulas.formatCoins(cost), coins >= cost
end

local function paintSlot(refs: SlotRefs, o: Office)
	local label, color, progress = status(o)
	refs.pillText.Text = label
	refs.pill.BackgroundColor3 = if progress then color:Lerp(BLACK, 0.45) else (if color == GRAY then MUTED else color)
	refs.fill.Visible = progress ~= nil
	refs.fill.Size = UDim2.fromScale(progress or 0, 1)
	refs.fill.BackgroundColor3 = color
	refs.level.Text = string.format("OFFICE %d · Lv %d", o.index, o.level)
	if o.lawyerId then
		local up, can = upgradeText(o)
		setButton(refs.up, refs.upLabel, up, GREEN, can)
	else
		setButton(refs.up, refs.upLabel, "EQUIP LAWYER", PURPLE, true)
	end
end

local upgrade: (any, any, string) -> () -- (defined below)
local openDetails: (number) -> ()

-- an office card: rarity-coloured Skin card, its lawyer (tap for the details), name, status, ONE button.
-- Rebuilt only when the office's lawyer / mutation / skills-ready changes.
local function slotCard(i: number, o: Office): SlotRefs
	local key = string.format("%s|%d|%s", o.lawyerId or "-", o.stars, tostring(o.skillsReady))
	local refs = slotRefs[i]
	if refs and refs.key == key then
		return refs
	end
	if refs then
		refs.card:Destroy()
	end
	local _, rColor = rarityOf(o.lawyerId)
	local card = Skin.card(slotBar, { Name = "Office" .. i, Color = if o.lawyerId then rColor else Skin.Palette.Purple, LayoutOrder = i, GlowAt = Vector2.new(0.5, 0.32) })
	local z = card.ZIndex + 2
	local level = text({ Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 20), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 2, Parent = card }, 17)
	if o.stars > 1 then
		local tag, tagColor = mutationTag(o.stars)
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(80, 20), Text = tag, TextColor3 = tagColor, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = z + 2, Parent = card }, 15)
	end
	-- the picture: tap it for SKILLS / MAX / UNEQUIP / SWAP
	local art = make("Frame", { Name = "Picture", Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 84), BackgroundTransparency = 1, ZIndex = z, Parent = card })
	-- the tap area sits OVER the picture: a ViewportFrame swallows taps meant for a button under it (found 2026-10-23)
	local artHit = make("TextButton", { Name = "Art", Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 84), BackgroundTransparency = 1, Text = "", ZIndex = z + 6, Parent = card })
	artHit:SetAttribute("KeepStyle", true)
	if o.lawyerId then
		if not lawyerViewport(art, o.lawyerId, 194 / 84, nil, o.stars) then
			drawIcon(art, o.lawyerId, 0.75, 2)
		end
	else
		text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(70, 70), Text = "+", FontFace = TITLE, ZIndex = z + 1, Parent = art }, 64)
	end
	if o.skillsReady then
		local bang = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 34), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = RED, ZIndex = z + 3, Parent = card }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2, WHITE) })
		text({ Size = UDim2.fromScale(1, 1), Text = "!", FontFace = TITLE, ZIndex = z + 4, Parent = bang }, 17)
	end
	small(text({ Position = UDim2.fromOffset(6, 108), Size = UDim2.new(1, -12, 0, 22), Text = if o.lawyerId then lawyerName(o.lawyerId, 1) else "Empty office",
		TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = z + 1, Parent = card }, 20))
	local pill = make("Frame", { Position = UDim2.fromOffset(10, 132), Size = UDim2.new(1, -20, 0, 18), BackgroundColor3 = MUTED, ClipsDescendants = true, ZIndex = z + 1, Parent = card }, { corner(5), stroke(2) })
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, ZIndex = z + 1, Parent = pill })
	local pillText = text({ Position = UDim2.fromOffset(3, 1), Size = UDim2.new(1, -6, 1, -2), Text = "", ZIndex = z + 2, Parent = pill }, 13)
	local up, upLabel = button({ Position = UDim2.new(0, 8, 1, -42), Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = GREEN, ZIndex = z + 1, Parent = card }, "UPGRADE", 18)
	Skin.glint(up)
	refs = { card = card, pill = pill, pillText = pillText, fill = fill, level = level, up = up, upLabel = upLabel, key = key }
	slotRefs[i] = refs
	artHit.Activated:Connect(function()
		squish(art)
		selectOffice(i)
		openDetails(i)
	end)
	up.Activated:Connect(function()
		selectOffice(i)
		local oi = office(i)
		if not oi.lawyerId then
			tab = "Bench"
			render()
			return
		end
		if not up:GetAttribute("Enabled") then
			flash(if oi.level >= Config.Lawyer.MaxLevel then "This office is max level!" else "Not enough coins yet", RED)
			return
		end
		upgrade(i, nil, "Office " .. i)
	end)
	return refs
end

local function renderSlots()
	local count = deskCount()
	for i, refs in slotRefs do
		if i > count then
			refs.card:Destroy()
			slotRefs[i] = nil
		end
	end
	for i = 1, count do
		local o = office(i)
		paintSlot(slotCard(i, o), o)
	end
end

-- the details pop-up's big lawyer, gently swaying (and hopping on an upgrade)
local function renderPreview(o: Office)
	local key = if o.lawyerId then o.lawyerId .. "|" .. o.stars else "empty"
	if key == previewKey then
		return
	end
	previewKey = key
	previewHome = nil
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	D.viewport:ClearAllChildren()
	D.iconHolder:ClearAllChildren()
	if not o.lawyerId then
		D.previewGradient.Color = ColorSequence.new(Color3.fromHex("6A44A8"), Color3.fromHex("4A2A85"))
		D.emptyPlus.Visible = true
		return
	end
	D.emptyPlus.Visible = false
	local _, color = rarityOf(o.lawyerId)
	D.previewGradient.Color = ColorSequence.new(color:Lerp(WHITE, 0.7), color:Lerp(WHITE, 0.25))
	local vf, m = lawyerViewport(D.iconHolder, o.lawyerId, 310 / 130, 0, o.stars)
	if vf and m then
		vf.ZIndex = 43
		previewHome = m:GetPivot()
		local box, size = m:GetBoundingBox()
		local center = box.Position
		previewConn = RunService.RenderStepped:Connect(function()
			local t = os.clock()
			local hop, spin = 0, 0
			local k = t - kick.t0
			if k >= 0 and k < kick.dur then
				local u = k / kick.dur
				hop = math.abs(math.sin(u * math.pi * kick.bounces)) * kick.hop * size.Y * (1 - u * 0.4)
				spin = kick.spins * math.pi * 2 * (1 - (1 - u) ^ 3)
			end
			local turn = CFrame.new(center) * CFrame.Angles(0, math.sin(t * 1.2) * 0.5 + spin, 0) * CFrame.new(center):Inverse()
			m:PivotTo(CFrame.new(0, math.sin(t * 2.6) * 0.06 + hop, 0) * turn * (previewHome :: CFrame))
		end)
	else
		drawIcon(D.iconHolder, o.lawyerId, 1.05, 12)
	end
end

-- how many levels MAX would buy right now (same rule as the server: free level-ups first, then coins)
local function affordableLevels(fromLevel: number): number
	local coins = (player:GetAttribute("Coins") :: number?) or 0
	local free = (player:GetAttribute("FreeLevelUps") :: number?) or 0
	local n, level = 0, fromLevel
	while level < Config.Lawyer.MaxLevel and n < 100 do
		if free > 0 then
			free -= 1
		else
			local cost = Formulas.trainCost(level)
			if coins < cost then
				break
			end
			coins -= cost
		end
		level += 1
		n += 1
	end
	return n
end

-- the live parts (pop-up status + buttons, footer) - also run by the 4x/s tick
local function renderLeftLive()
	local anyAffordable = false
	for i = 1, deskCount() do
		local oi = office(i)
		if oi.lawyerId and oi.level < Config.Lawyer.MaxLevel and affordableLevels(oi.level) > 0 then
			anyAffordable = true
			break
		end
	end
	setButton(allButton, allLabel, "UPGRADE ALL OFFICES", GREEN, anyAffordable)
	if not left.Visible then
		return
	end
	local o = office(selectedOffice)
	local label, color, progress = status(o)
	if not o.lawyerId then
		D.statusLabel.Text = "No lawyer here yet - tap SWAP LAWYER to pick one."
	elseif o.queued and isBusy(o) then
		local who = if o.queued == "unseat" then "Gets unequipped" else "Swaps out"
		D.statusLabel.Text = string.format("%s when %s's case ends", who, o.clientName or "this")
	elseif o.phase == "Case" then
		D.statusLabel.Text = string.format("On %s's case · %s", o.clientName or "a", string.lower((label:gsub("ON A CASE ", ""))))
	elseif o.phase == "Walking" then
		D.statusLabel.Text = string.format("%s is walking over...", o.clientName or "A client")
	else
		D.statusLabel.Text = "Free - waiting for the next client."
	end
	D.statusLabel.TextColor3 = if o.lawyerId and o.phase == "Idle" then GREEN elseif color == PURPLE then Color3.fromRGB(215, 160, 255) else SOFT
	D.statusBar.Visible = progress ~= nil and not o.queued
	D.statusFill.Size = UDim2.fromScale(progress or 0, 1)
	local up, canUp = upgradeText(o)
	setButton(upgradeButton, upgradeLabel, if o.lawyerId then up else "UPGRADE", GREEN, canUp and o.lawyerId ~= nil)
	local n = if o.level < Config.Lawyer.MaxLevel then affordableLevels(o.level) else 0
	setButton(maxButton, maxLabel, if n > 0 then string.format("MAX\n+%d", n) else "MAX", Color3.fromRGB(40, 170, 30), n > 1 and o.lawyerId ~= nil)
	setButton(skillsButton, skillsLabel, "SKILLS", GOLD, o.lawyerId ~= nil)
	D.skillsBang.Visible = o.skillsReady
	unseatButton.Visible = o.lawyerId ~= nil
	if o.queued and isBusy(o) then
		setButton(unseatButton, unseatLabel, "CANCEL CHANGE", RED, true)
	elseif isBusy(o) then
		setButton(unseatButton, unseatLabel, "UNEQUIP AFTER CASE", ORANGE, true)
	else
		setButton(unseatButton, unseatLabel, "UNEQUIP", ORANGE, true)
	end
end

local function renderLeft()
	if not left.Visible then
		return
	end
	local o = office(selectedOffice)
	renderPreview(o)
	officeTag.Text = string.format("OFFICE %d · Lv %d", o.index, o.level)
	if o.lawyerId then
		local rName, rColor = rarityOf(o.lawyerId)
		D.nameLabel.Text = lawyerName(o.lawyerId, o.stars)
		local tag, tagColor = mutationTag(o.stars)
		D.starsLabel.Text = tag
		D.starsLabel.TextColor3 = tagColor
		D.rarityPill.Visible = true
		D.rarityPill.BackgroundColor3 = rColor
		D.rarityText.Text = string.upper(rName)
		D.earnLabel.Text = string.format("Earns x%s", tostring(Formulas.lawyerEarn(o.lawyerId, o.stars)))
	else
		D.nameLabel.Text = "Empty office"
		D.starsLabel.Text = ""
		D.rarityPill.Visible = false
		D.earnLabel.Text = ""
	end
	renderLeftLive()
end

openDetails = function(i: number)
	selectOffice(i)
	previewKey = nil
	left.Visible = true
	D.popupDim.Visible = true
	Skin.pop(left, 0.6)
	renderLeft()
end
local function closeDetails()
	left.Visible = false
	D.popupDim.Visible = false
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	previewKey = nil
end

-- the upgrade celebrations (Shared.UpgradeFx, 2026-10-13): bigger for MAX / UPGRADE ALL, biggest at max level.
-- v3: they play over the office card being upgraded (or the pop-up's lawyer when it's open).
local upgradeFx = (require(Shared:WaitForChild("UpgradeFx") :: ModuleScript) :: any).new({
	panel = panel, preview = fxAnchor, slotBar = slotBar, officeTag = fxTag, width = W, height = H, kick = kick,
	card = function(i: number): GuiObject?
		local refs = slotRefs[i]
		return if refs then refs.card else nil
	end,
	office = office,
	selected = function(): number
		return selectedOffice
	end,
	deskCount = deskCount,
	setTag = function(i: number, level: number)
		local refs = slotRefs[i]
		if refs then
			refs.level.Text = string.format("OFFICE %d · Lv %d", i, level)
		end
		if i == selectedOffice then
			officeTag.Text = string.format("OFFICE %d · Lv %d", i, level)
		end
	end,
	lawyerViewport = lawyerViewport,
})
local fxToken = 0
local function aimFx(i: number)
	local refs = slotRefs[i]
	local target: GuiObject? = if left.Visible then preview elseif refs then refs.card else nil
	if not target then
		return
	end
	local s = math.max(panelScale.Scale, 0.01)
	local rel = (target.AbsolutePosition - panel.AbsolutePosition) / s
	fxAnchor.Position = UDim2.fromOffset(rel.X, rel.Y)
	fxAnchor.Size = UDim2.fromOffset(target.AbsoluteSize.X / s, target.AbsoluteSize.Y / s)
	fxToken += 1
	local my = fxToken
	task.delay(9, function() -- the longest celebration (max level) is over by then
		if fxToken == my then
			fxAnchor.Position = PARKED
		end
	end)
end

local function placeAction(o: Office, l: Lawyer?): (string, boolean, Color3)
	if not l then
		return "PICK A LAWYER", false, GREEN
	end
	if l.Office == o.index then
		return "ALREADY IN THIS OFFICE", false, GREEN
	end
	if l.Office and isBusy(office(l.Office)) then
		return string.format("ON A CASE IN OFFICE %d", l.Office), false, GREEN
	end
	if o.lawyerId and isBusy(o) then
		if l.Office then
			return string.format("OFFICE %d IS ON A CASE", o.index), false, GREEN
		end
		return "EQUIP AFTER THIS CASE", true, PURPLE
	end
	return string.format("EQUIP IN OFFICE %d", o.index), true, GREEN
end

------------------------------------------------------------------ selling (2026-10-13)
local sellArmed: string? = nil -- the uid whose SELL was tapped once (Epic and up ask twice)
local sellArmedUntil = 0
local function rarityIndex(id: string): number
	local def = Formulas.getSkin(id)
	return if def then def.Rarity else 1
end
local function sellable(l: Lawyer): boolean
	return l.Office == nil and not l.Locked
end
-- the lawyers SELL ALL would sell with the ticked rarities (never your last lawyer: the server keeps one too)
local function sellAllPicks(list: { Lawyer }): ({ string }, number)
	local uids, total = {}, 0
	for _, l in list do
		if sellable(l) and sellRarities[rarityIndex(l.Id)] then
			table.insert(uids, l.Uid)
			total += sellValue(l)
		end
	end
	if #uids >= #list then -- keep at least one
		table.remove(uids)
	end
	return uids, total
end
local function renderSell(list: { Lawyer }, pick: Lawyer?)
	if pick then
		if pick.Office then
			setButton(sellButton, sellLabel, "IN AN OFFICE", ORANGE, false)
		elseif pick.Locked then
			setButton(sellButton, sellLabel, "LOCKED", ORANGE, false)
		elseif #list <= 1 then
			setButton(sellButton, sellLabel, "LAST LAWYER", ORANGE, false)
		elseif sellArmed == pick.Uid and os.clock() < sellArmedUntil then
			setButton(sellButton, sellLabel, "TAP AGAIN TO SELL", RED, true)
		else
			setButton(sellButton, sellLabel, "SELL · " .. Formulas.formatCoins(sellValue(pick)), ORANGE, true)
		end
		setButton(lockButton, lockLabel, if pick.Locked then "UNLOCK" else "LOCK", Color3.fromRGB(90, 200, 255), true)
	end
	local any = false
	for _, l in list do
		any = any or sellable(l)
	end
	setButton(sellAllButton, sellAllLabel, "SELL ALL...", RED, any and #list > 1)
	if sellAll.Visible then
		for i, chip in chips do
			local s = chip:FindFirstChildOfClass("UIStroke") :: UIStroke
			s.Thickness = if sellRarities[i] then 4 else 2
			s.Color = if sellRarities[i] then WHITE else BLACK
			chip.BackgroundTransparency = if sellRarities[i] then 0 else 0.6
		end
		local uids, total = sellAllPicks(list)
		P.sellAllNote.Text = if #uids > 0 then string.format("Sells %d lawyer%s for %s coins (not locked, not in an office)", #uids, if #uids == 1 then "" else "s", Formulas.formatCoins(total))
			else "Nothing to sell with these rarities"
		setButton(sellAllGo, sellAllGoLabel, if #uids > 0 then "SELL " .. #uids else "SELL", RED, #uids > 0)
	end
end

type BenchCard = { card: Frame, overlay: Frame, stroke: UIStroke, key: string?, stars: number }
local benchCards: { [string]: BenchCard } = {}

-- a lawyer card in the grid: rarity-coloured Skin card (no sunburst spin - there can be 150 of them), 3D lawyer, name,
-- mutation + earn, and tags (which office, locked, 3x for the Mutation Machine). Tap = pick it.
local function benchCard(l: Lawyer): BenchCard
	local entry = benchCards[l.Uid]
	if entry and entry.stars == l.Stars then
		return entry
	elseif entry then -- it mutated: a new picture
		entry.card:Destroy()
		benchCards[l.Uid] = nil
	end
	local _, rColor = rarityOf(l.Id)
	local card = Skin.card(benchGrid, { Name = l.Uid, Color = rColor, Spin = false, Twinkle = false, GlowAt = Vector2.new(0.5, 0.32) })
	local s = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	local z = card.ZIndex + 2
	local hit = make("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = z + 5, Parent = card })
	hit:SetAttribute("KeepStyle", true)
	local art = make("Frame", { Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 84), BackgroundTransparency = 1, ZIndex = z, Parent = card })
	if not lawyerViewport(art, l.Id, 114 / 84, nil, l.Stars) then
		drawIcon(art, l.Id, 0.6, 6)
	end
	local overlay = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z + 1, Parent = card })
	entry = { card = card, overlay = overlay, stroke = s, stars = l.Stars }
	benchCards[l.Uid] = entry
	hit.Activated:Connect(function()
		squish(card)
		benchPick = l.Uid
		sellArmed = nil
		render()
	end)
	return entry
end

-- equip target: an empty office first, else the selected one
local function defaultTarget(): number
	local o = office(selectedOffice)
	if o.lawyerId then
		for i = 1, deskCount() do
			if not office(i).lawyerId then
				return i
			end
		end
	end
	return selectedOffice
end

local function renderPick(list: { Lawyer }, pick: Lawyer?)
	local o = office(selectedOffice)
	for _, g in { P.pickPreview, P.pickName, P.pickRarity, P.pickEarn, P.pickNote, P.targetRow, placeButton, sellButton, lockButton } do
		(g :: GuiObject).Visible = pick ~= nil
	end
	P.pickEmpty.Visible = pick == nil
	local tOffice = office(selectedOffice)
	local tLabel, tColor = status(tOffice)
	P.targetText.Text = string.format("Office %d · %s", selectedOffice, if tOffice.lawyerId then string.lower(tLabel) else "empty")
	P.targetText.TextColor3 = if tOffice.lawyerId then (if tColor == GREEN then GREEN else Color3.fromRGB(255, 200, 120)) else WHITE
	if not pick then
		pickKey = nil
		renderSell(list, nil)
		return
	end
	local key = pick.Uid .. "|" .. pick.Stars
	if key ~= pickKey then
		pickKey = key
		P.pickArt:ClearAllChildren()
		local rName, rColor = rarityOf(pick.Id)
		P.pickGradient.Color = ColorSequence.new(rColor:Lerp(WHITE, 0.7), rColor:Lerp(WHITE, 0.25))
		if not lawyerViewport(P.pickArt, pick.Id, 288 / 126, 0, pick.Stars) then
			drawIcon(P.pickArt, pick.Id, 1, 8)
		end
		P.pickRarity.BackgroundColor3 = rColor
		P.pickRarityText.Text = string.upper(rName)
	end
	P.pickName.Text = lawyerName(pick.Id, pick.Stars)
	local tag, tagColor = mutationTag(pick.Stars)
	P.pickTag.Text = tag
	P.pickTag.TextColor3 = tagColor
	P.pickEarn.Text = "Earns x" .. tostring(Formulas.lawyerEarn(pick.Id, pick.Stars))
	local PCOL = "#D7A0FF"
	if pick.Stars < #Config.Lawyers.StarEarn and copiesOf(list, pick) >= Config.Lawyers.MergeCount then
		P.pickNote.Text = string.format('You have %d! <font color="%s">Mutation Machine</font>: %d%% for a %s one.', copiesOf(list, pick), PCOL,
			math.floor(Formulas.mutateChance(pick.Stars) * 100 + 0.5), (MutationLook.info(pick.Stars + 1)))
	elseif pick.Office then
		P.pickNote.Text = string.format("Working in Office %d%s", pick.Office, if pick.Locked then " · locked" else "")
	elseif pick.Locked then
		P.pickNote.Text = "Locked: safe from selling and mutating"
	else
		P.pickNote.Text = "Not in an office yet"
	end
	local label, enabled, color = placeAction(o, pick)
	setButton(placeButton, placeLabel, label, color, enabled)
	renderSell(list, pick)
end

local function renderBench()
	local list = lawyers()
	if benchPick and not findLawyer(list, benchPick) then
		benchPick = nil
	end
	-- not-equipped lawyers first (strongest first), then the ones already working
	table.sort(list, function(a, b)
		if (a.Office == nil) ~= (b.Office == nil) then
			return a.Office == nil
		end
		local ea, eb = Formulas.lawyerEarn(a.Id, a.Stars), Formulas.lawyerEarn(b.Id, b.Stars)
		if ea ~= eb then
			return ea > eb
		end
		if a.Id ~= b.Id then
			return a.Id < b.Id
		end
		return a.Uid < b.Uid
	end)
	local alive = {}
	for _, l in list do
		alive[l.Uid] = true
	end
	for uid, entry in benchCards do
		if not alive[uid] then
			entry.card:Destroy()
			benchCards[uid] = nil
		end
	end
	local empty = benchGrid:FindFirstChild("EmptyNote")
	if #list == 0 and not empty then
		text({ Name = "EmptyNote", Size = UDim2.fromOffset(300, 60), FontFace = BODY, Text = "No lawyers yet - hatch eggs in the zones!", TextColor3 = SOFT, TextWrapped = true, Parent = benchGrid }, 20, 0)
	elseif #list > 0 and empty then
		empty:Destroy()
	end
	for order, l in list do
		local entry = benchCard(l)
		local picked = l.Uid == benchPick
		entry.card.LayoutOrder = order
		entry.stroke.Thickness = if picked then 6 else 4
		entry.stroke.Color = if picked then WHITE else Skin.Ink
		local busyHere = l.Office ~= nil and isBusy(office(l.Office))
		local mergeable = l.Stars < #Config.Lawyers.StarEarn and copiesOf(list, l) >= Config.Lawyers.MergeCount
		local key = string.format("%d|%s|%s|%s|%s", l.Stars, tostring(l.Office), tostring(busyHere), tostring(mergeable), tostring(l.Locked))
		if entry.key ~= key then
			entry.key = key
			local overlay = entry.overlay
			local z = overlay.ZIndex
			overlay:ClearAllChildren()
			small(text({ Position = UDim2.fromOffset(4, 92), Size = UDim2.new(1, -8, 0, 20), Text = lawyerName(l.Id, 1), TextColor3 = Color3.fromRGB(255, 225, 90), ZIndex = z, Parent = overlay }, 16))
			local tag, tagColor = mutationTag(l.Stars)
			text({ Position = UDim2.fromOffset(6, 116), Size = UDim2.new(0.55, -6, 0, 22), Text = tag, TextColor3 = tagColor, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z, Parent = overlay }, 14)
			text({ Position = UDim2.new(0.45, 0, 0, 116), Size = UDim2.new(0.55, -6, 0, 22), Text = "x" .. tostring(Formulas.lawyerEarn(l.Id, l.Stars)), TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = z, Parent = overlay }, 18)
			if l.Locked then -- a little gold padlock tag (frames, no emoji)
				local lk = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 0, 88), Size = UDim2.fromOffset(16, 13), BackgroundColor3 = GOLD, ZIndex = z + 1, Parent = overlay }, { corner(3), stroke(2) })
				make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 1), Size = UDim2.fromOffset(10, 9), BackgroundTransparency = 1, ZIndex = z + 1, Parent = lk },
					{ make("UICorner", { CornerRadius = UDim.new(0.5, 0) }), make("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(40, 40, 52) }) })
			end
			if l.Office then -- equipped: which office (orange while it's on a case)
				local t = make("Frame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(66, 18), BackgroundColor3 = if busyHere then ORANGE else GREEN, ZIndex = z + 1, Parent = overlay }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
				text({ Size = UDim2.fromScale(1, 1), Text = "OFFICE " .. l.Office, ZIndex = z + 2, Parent = t }, 12)
			end
			if mergeable then
				local m = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(30, 18), BackgroundColor3 = PURPLE, ZIndex = z + 1, Parent = overlay }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
				text({ Size = UDim2.fromScale(1, 1), Text = "3x", ZIndex = z + 2, Parent = m }, 12) -- (3 copies: one try at the Mutation Machine)
			end
		end
	end
	setButton(bestButton, bestLabel, "EQUIP BEST", GOLD, #list > 0)
	renderPick(list, findLawyer(list, benchPick))
end

local function renderInfo()
	local G = "#5CF03C"
	if tab == "Offices" then
		infoText.Text = string.format('Upgrade your offices to earn more. <font color="%s">Tap a lawyer\'s picture</font> for Skills, Max and Unequip.', G)
	else
		infoText.Text = string.format('Tap a lawyer, then <font color="%s">EQUIP</font> it in an office. Use &lt; &gt; to choose which office.', G)
	end
end

local function renderTabs()
	local list = lawyers()
	local bench = 0
	for _, l in list do
		if not l.Office then
			bench += 1
		end
	end
	benchTabLabel.Text = if bench > 0 then string.format("MY LAWYERS (%d)", bench) else "MY LAWYERS"
	Skin.selectTab(rail, tabButtons[tab])
	officesView.Visible = tab == "Offices"
	benchFrame.Visible = tab == "Bench"
	allButton.Visible = tab == "Offices"
	sellAllButton.Visible = tab == "Bench"
	if tab ~= "Bench" then
		sellAll.Visible = false
	end
	countLabel.Text = string.format("%d / %d lawyers · %d offices", #list, Config.Lawyers.MaxOwned, deskCount())
end

render = function()
	if deskCount() > 0 and selectedOffice > deskCount() then
		selectOffice(deskCount())
	end
	renderTabs()
	renderInfo()
	if tab == "Offices" then
		renderSlots()
	else
		renderBench()
	end
	renderLeft()
	renderLeftLive()
end

-- coalesce bursts of attribute changes into one render
local renderQueued = false
local function queueRender()
	if renderQueued or not panel.Visible then
		return
	end
	renderQueued = true
	task.defer(function()
		renderQueued = false
		if panel.Visible and not busy then
			render()
		end
	end)
end

------------------------------------------------------------------ open / close
local function fit(): number
	local camera = workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return math.clamp(math.min((view.X - 24) / (W + RAIL_W), (view.Y - 24) / H), 0.35, 1)
end
local function place(s: number)
	panelScale.Scale = s
	panel.Position = UDim2.new(0.5, -math.floor(RAIL_W / 2 * s), 0.52, 0) -- leave room for the tabs on the right
end

local function open(opts: any)
	local o = opts or {}
	if o.office then
		selectOffice(o.office)
	else
		local selected = player:GetAttribute("SelectedDesk")
		selectOffice(if typeof(selected) == "number" then selected else selectedOffice)
	end
	if o.tab == "Bench" then
		tab = "Bench"
		if not o.office then
			selectOffice(defaultTarget())
		end
	elseif o.tab == "Offices" or not panel.Visible then
		tab = o.tab or "Offices"
		if tab == "Clients" then
			tab = "Offices" -- (no waiting room since v16)
		end
	end
	closeDetails()
	setTextMode(fit()) -- before render(), so new labels start in the right text mode
	toastPill.Visible = false
	render()
	if not panel.Visible then
		panel.Visible = true
		shade.Visible = true
		shade.BackgroundTransparency = 1
		tween(shade, 0.2, { BackgroundTransparency = 0.35 })
		local s = fit()
		place(s)
		panelScale.Scale = s * 0.6
		tween(panelScale, 0.3, { Scale = s }, Enum.EasingStyle.Back)
		Skin.holdChat(gui, true) -- the chat box would eat taps on the top-left office cards
		MarkSkinsSeen:FireServer()
	end
end

local closePanel: () -> ()
closePanel = function()
	if not panel.Visible then
		return
	end
	local s = panelScale.Scale
	TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = s * 0.6 }):Play()
	tween(shade, 0.14, { BackgroundTransparency = 1 })
	upgradeFx.close()
	task.wait(0.14)
	panel.Visible = false
	shade.Visible = false
	Skin.holdChat(gui, false)
	closeDetails()
end

------------------------------------------------------------------ actions
openButton.Activated:Connect(function()
	if panel.Visible then
		closePanel()
	else
		open(nil)
	end
end)
closeButton.Activated:Connect(function()
	squish(closeButton)
	closePanel()
end)
shade.Activated:Connect(closePanel)
D.popupDim.Activated:Connect(closeDetails)
D.popupClose.Activated:Connect(closeDetails)

tabButtons.Offices.Activated:Connect(function()
	tab = "Offices"
	render()
end)
tabButtons.Bench.Activated:Connect(function()
	if tab ~= "Bench" then
		tab = "Bench"
		selectOffice(defaultTarget())
	end
	closeDetails()
	render()
end)

upgrade = function(target: any, count: any, label: string)
	if busy then
		return
	end
	busy = true
	local before: { [number]: number } = {}
	for i = 1, deskCount() do
		before[i] = office(i).level
	end
	local ok, reason, bought = TrainLawyer:InvokeServer(target, count)
	busy = false
	if ok then
		if reason then
			flash("NEW LOOK: " .. string.upper(reason) .. "!", GREEN)
		else
			flash(string.format("%s +%d level%s!", label, bought or 1, if (bought or 1) == 1 then "" else "s"), GREEN)
		end
	else
		flash(reason or "Can't upgrade", RED)
	end
	render()
	if ok then
		aimFx(if typeof(target) == "number" then target else selectedOffice)
		if target == "all" then
			task.spawn(upgradeFx.all, before, reason)
		elseif typeof(target) == "number" and before[target] then
			upgradeFx.one(target, before[target], before[target] + (bought or 1), reason)
		end
	end
end

maxButton.Activated:Connect(function()
	if not maxButton:GetAttribute("Enabled") then
		flash(if office(selectedOffice).level >= Config.Lawyer.MaxLevel then "This office is max level!" else "Not enough coins for 2+ levels yet", RED)
		return
	end
	upgrade(selectedOffice, "max", "Office " .. selectedOffice)
end)

allButton.Activated:Connect(function()
	if not allButton:GetAttribute("Enabled") then
		flash("Not enough coins for any office yet", RED)
		return
	end
	upgrade("all", nil, "All offices")
end)

upgradeButton.Activated:Connect(function()
	if busy then
		return
	end
	if not upgradeButton:GetAttribute("Enabled") then
		local o = office(selectedOffice)
		flash(if o.level >= Config.Lawyer.MaxLevel then "This office is max level!" else "Not enough coins yet", RED)
		return
	end
	upgrade(selectedOffice, nil, "Office " .. selectedOffice)
end)

skillsButton.Activated:Connect(function()
	if not office(selectedOffice).lawyerId then
		flash("Equip a lawyer in this office first", RED)
		return
	end
	player:SetAttribute("SelectedDesk", selectedOffice)
	skillsEvent:Fire(selectedOffice) -- StarterPlayerScripts.Skills opens over this panel
end)

swapButton.Activated:Connect(function()
	closeDetails()
	tab = "Bench"
	render()
end)

unseatButton.Activated:Connect(function()
	if busy then
		return
	end
	local o = office(selectedOffice)
	if not o.lawyerId then
		return
	end
	busy = true
	local ok, msg
	if o.queued and isBusy(o) then
		ok, msg = CancelLawyerChange:InvokeServer(selectedOffice)
	else
		ok, msg = PlaceLawyer:InvokeServer(selectedOffice, nil)
		if ok and not msg then
			msg = lawyerName(o.lawyerId, o.stars) .. " unequipped"
		end
	end
	busy = false
	if ok then
		Sfx.play(if o.queued and isBusy(o) then "notify" else "lawyerUnequip", { gap = 0.3 })
	end
	flash(msg or (if ok then "Done!" else "Can't do that"), if ok then GREEN else RED)
	previewKey = nil
	render()
end)

local function cycleTarget(step: number)
	local n = math.max(deskCount(), 1)
	selectOffice(((selectedOffice - 1 + step) % n) + 1)
	render()
end
prevTarget.Activated:Connect(function()
	cycleTarget(-1)
end)
nextTarget.Activated:Connect(function()
	cycleTarget(1)
end)

placeButton.Activated:Connect(function()
	if busy then
		return
	end
	local list = lawyers()
	local pick = findLawyer(list, benchPick)
	local o = office(selectedOffice)
	local label, enabled = placeAction(o, pick)
	if not pick then
		flash("Tap a lawyer first", RED)
		return
	end
	if not enabled then
		flash(label:sub(1, 1) .. string.lower(label:sub(2)), RED)
		return
	end
	busy = true
	local ok, msg, queued = PlaceLawyer:InvokeServer(selectedOffice, pick.Uid)
	busy = false
	if ok then
		Sfx.play(if queued then "notify" else "lawyerEquip", { gap = 0.3 })
		flash(msg or string.format("%s → Office %d!", lawyerName(pick.Id, pick.Stars), selectedOffice), if queued then PURPLE else GREEN)
		benchPick = nil
	else
		flash(msg or "Can't do that", RED)
	end
	render()
end)

bestButton.Activated:Connect(function()
	if busy then
		return
	end
	if not bestButton:GetAttribute("Enabled") then
		flash("No lawyers yet - hatch some eggs!", RED)
		return
	end
	busy = true
	local ok, msg = PlaceLawyer:InvokeServer("best")
	busy = false
	flash(msg or (if ok then "Done!" else "Can't do that"), if ok then GREEN else RED)
	if ok then
		Sfx.play("lawyerEquip", { gap = 0.3 })
		benchPick = nil
	end
	render()
end)

-- SELL / LOCK / SELL ALL (2026-10-13; the server checks it all: Server.LawyerService.sell / lock)
local function doSell(uids: { string }, label: string)
	busy = true
	local ok, coins, count = SellLawyers:InvokeServer(uids)
	busy = false
	if ok then
		Sfx.play("coins", { gap = 0.4 })
		flash(string.format("Sold %s for %s coins!", label, Formulas.formatCoins(coins :: number)), GOLD)
		Effects.guiBurst(gui, UDim2.fromOffset(sellButton.AbsolutePosition.X + sellButton.AbsoluteSize.X / 2, sellButton.AbsolutePosition.Y), 260, GOLD, 1.2, 25)
		benchPick = nil
	else
		flash(tostring(coins or "Can't sell that"), RED)
	end
	local _ = count
	render()
end
sellButton.Activated:Connect(function()
	if busy or not sellButton:GetAttribute("Enabled") then
		return
	end
	local pick = findLawyer(lawyers(), benchPick)
	if not pick then
		return
	end
	if rarityIndex(pick.Id) >= Config.Lawyers.Sell.ConfirmFrom and not (sellArmed == pick.Uid and os.clock() < sellArmedUntil) then
		sellArmed, sellArmedUntil = pick.Uid, os.clock() + 3 -- Epic and up: tap twice
		render()
		task.delay(3.05, render)
		return
	end
	sellArmed = nil
	doSell({ pick.Uid }, lawyerName(pick.Id, pick.Stars))
end)
lockButton.Activated:Connect(function()
	if busy or not lockButton:GetAttribute("Enabled") then
		return
	end
	local pick = findLawyer(lawyers(), benchPick)
	if not pick then
		return
	end
	busy = true
	local ok, msg = LockLawyer:InvokeServer(pick.Uid, not pick.Locked)
	busy = false
	if ok then
		flash(if pick.Locked then "Unlocked" else "Locked - safe from selling and mutating", GOLD)
	else
		flash(msg or "Can't do that", RED)
	end
	render()
end)
sellAllButton.Activated:Connect(function()
	if not sellAllButton:GetAttribute("Enabled") then
		return
	end
	sellAll.Visible = not sellAll.Visible
	render()
end)
for i, chip in chips do
	chip.Activated:Connect(function()
		sellRarities[i] = not sellRarities[i] or nil
		render()
	end)
end
sellAllCancel.Activated:Connect(function()
	sellAll.Visible = false
end)
sellAllGo.Activated:Connect(function()
	if busy or not sellAllGo:GetAttribute("Enabled") then
		return
	end
	local uids = sellAllPicks(lawyers())
	sellAll.Visible = false
	doSell(uids, string.format("%d lawyer%s", #uids, if #uids == 1 then "" else "s"))
end)

------------------------------------------------------------------ wiring
-- other scripts: Fire(office) or Fire({ office, client, tab }) - an empty office opens MY LAWYERS aimed at it
openEvent.Event:Connect(function(arg: any)
	if typeof(arg) == "number" then
		open({ office = arg, tab = if office(arg).lawyerId then "Offices" else "Bench" })
	elseif typeof(arg) == "table" then
		if arg.tab == "Bench" or (arg.office and not office(arg.office).lawyerId) then
			open({ office = arg.office, tab = "Bench" })
		else
			open({ office = arg.office, tab = "Offices" })
		end
	else
		open({ tab = "Bench" })
	end
end)
OpenLawyerPicker.OnClientEvent:Connect(function(index: number)
	open({ office = index, tab = "Bench" })
end)

player.AttributeChanged:Connect(function(name)
	if name == "Coins" then
		if panel.Visible and not busy then
			renderLeftLive()
			if tab == "Offices" then
				for i, refs in slotRefs do
					paintSlot(refs, office(i))
				end
			end
		end
	elseif name == "Lawyers" or name == "DeskCount" or name == "FreeLevelUps" or string.match(name, "^Desk%d+") then
		queueRender()
	end
end)

local function updateBadge()
	local unseen = player:GetAttribute("SkinsUnseen")
	local n = if typeof(unseen) == "number" then unseen else 0
	menuEntry.setBadge(if n > 9 then "9+" elseif n > 0 then tostring(n) else nil)
end
player:GetAttributeChangedSignal("SkinsUnseen"):Connect(updateBadge)
updateBadge()

-- live timers / progress, 4x a second while open (no rebuilds)
task.spawn(function()
	while true do
		task.wait(0.25)
		if panel.Visible and not busy then
			if tab == "Offices" then
				for i, refs in slotRefs do
					paintSlot(refs, office(i))
				end
			end
			renderLeftLive()
		end
	end
end)

-- keep the panel fitted when the window / phone rotates
local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if panel.Visible then
				place(fit())
				setTextMode(panelScale.Scale)
			end
		end)
	end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
