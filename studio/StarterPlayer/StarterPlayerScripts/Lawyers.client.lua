--!strict
-- LAWYERS panel v2 (user's lawyer-management overhaul, 2026-10-09): ONE place to run the firm's lawyers.
-- Wording is EQUIP / UNEQUIP everywhere (user's call: easier for kids than seat / unseat / place).
-- Styled like the Shop / Lawyer Merger (purple striped header, dark studded panel, chunky outlined buttons).
--   top     OFFICE SLOTS bar: every office as a card - its lawyer, and a status pill:
--           FREE (green) · ON A CASE m:ss with a progress fill (orange) · CLIENT ARRIVING · LEAVING / SWAP
--           AFTER CASE (purple, a queued change) · EMPTY (grey). Tap a card to select that office.
--   left    the selected office: the lawyer in 3D, rarity, Earns xN, live status, and
--           UPGRADE OFFICE (Remotes.TrainLawyer) · SKILLS (opens StarterPlayerScripts.Skills for this office) ·
--           UNEQUIP (Remotes.PlaceLawyer(office, nil); on a busy office it is QUEUED: "UNEQUIP AFTER CASE",
--           cancel with Remotes.CancelLawyerChange)
--   right   CLIENTS tab: the waiting room (player attribute WaitingClients) - ASSIGN sends a client to the
--           selected office (Remotes.AssignClient). After one assignment the panel closes (user's call: one
--           client per assignment; assigning everyone is the Manager's perk).
--           EQUIP tab (internally "Bench"): every lawyer you own - EQUIP IN OFFICE N / EQUIP AFTER THIS CASE
--           (Remotes.PlaceLawyer, queued for a busy office) and EQUIP BEST (Remotes.PlaceLawyer("best"): the
--           strongest lawyers into every office). No merging here (user's call 2026-10-11): a "3x" tag and the info
--           line send players to the Lawyer Merger machine (StarterPlayerScripts.Merger).
-- Opened by: the LAWYERS button (left edge), an empty office's Place Lawyer prompt (Remotes.OpenLawyerPicker),
-- a waiting client's [E] Assign Client prompt (StarterPlayerScripts.AssignClients), the hatch screen's
-- equip button - all through the local ReplicatedStorage.LawyersUI bindable: Fire(office) or
-- Fire({ office = n?, client = waitingId?, tab = "Clients" | "Bench" }).
-- The server checks everything (Server.CaseService / LawyerService). This only reads mirrored attributes:
--   Lawyers (JSON { Uid, Id, Stars, Skills, Office }), DeskCount, Desk<N>Lawyer / Stars / Level / Phase /
--   CaseStart / CaseEnd / ClientName / ClientTier / Queued / FreeSkillRolls / PendingSkill, WaitingClients.
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
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceLawyer = Remotes:WaitForChild("PlaceLawyer") :: RemoteFunction
local OpenLawyerPicker = Remotes:WaitForChild("OpenLawyerPicker") :: RemoteEvent
local MarkSkinsSeen = Remotes:WaitForChild("MarkSkinsSeen") :: RemoteEvent
local AssignClient = Remotes:WaitForChild("AssignClient") :: RemoteFunction
local TrainLawyer = Remotes:WaitForChild("TrainLawyer") :: RemoteFunction
local CancelLawyerChange = Remotes:WaitForChild("CancelLawyerChange") :: RemoteFunction

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
type Lawyer = { Uid: string, Id: string, Stars: number, Skills: { any }, Office: number? }
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
local function lawyerModel(id: string): Model?
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
	return if cached then (cached :: Model):Clone() else nil
end

-- A ViewportFrame showing that lawyer, framed head to toe, turned a little toward the light. Returns the frame and
-- its model (nil for a lawyer without a 3D model: then the drawn icon is used instead).
local function lawyerViewport(parent: GuiObject, id: string, aspect: number, yaw: number?): (ViewportFrame?, Model?)
	local m = lawyerModel(id)
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

------------------------------------------------------------------ layout
local playerGui = player:WaitForChild("PlayerGui")
local gui = make("ScreenGui", { Name = "Lawyers", ResetOnSpawn = false, DisplayOrder = 32, IgnoreGuiInset = true, Parent = playerGui })
local shade = make("TextButton", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, Parent = gui })
shade:SetAttribute("NoSkin", true)

-- HUD button: the LAWYERS tile in the shared left-edge menu column (Shared.HudMenu, real gavel icon)
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local menuEntry = HudMenu.button({ name = "Lawyers", label = "LAWYERS", icon = "Gavel", color = PURPLE, order = 2 })
local openButton = menuEntry.button

-- the panel
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = PANEL, Visible = false, Active = true, Parent = gui,
}, { corner(10), stroke(6), panelScale })
panel:SetAttribute("NoSkin", true)
Skin.blockClicks(panel) -- (Active = true alone doesn't stop a tap on empty space reaching the Shade and closing it)
studs(panel, 0.9)
-- header in the shared Skin look: top-lit colour strip, studs, two shine bands, gavel icon + title, red X tile
local sw = Skin.swatch("Purple")
make("Frame", { Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Parent = panel },
	{ corner(8), make("UIStroke", { Thickness = 2, Color = Color3.fromHex("4A4D66"), Transparency = 0.2 }) })
local header = make("Frame", { Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = WHITE, ZIndex = 2, Parent = panel }, {
	corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
})
make("Frame", { Position = UDim2.new(0, -4, 1, 0), Size = UDim2.new(1, 8, 0, 4), BackgroundColor3 = Skin.Ink, BorderSizePixel = 0, ZIndex = 3, Parent = header })
Skin.studs(header, 0.86, nil, 26)
Skin.shineBands(header, 0.84)
make("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(58, 58), BackgroundTransparency = 1,
	Image = HudMenu.Icons.Gavel, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = header })
Skin.text({ Position = UDim2.fromOffset(80, 6), Size = UDim2.fromOffset(300, 58), FontFace = Skin.Fonts.Title, Text = "Lawyers",
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header }, 54, 5)
local countLabel = text({ Position = UDim2.fromOffset(330, 22), Size = UDim2.new(1, -440, 0, 32), Text = "", TextColor3 = Color3.fromRGB(255, 230, 120), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = header }, 24)
local closeButton = Skin.closeButton(header, 58, 4)

-- OFFICE SLOTS bar
text({ Position = UDim2.fromOffset(22, 84), Size = UDim2.fromOffset(200, 22), Text = "YOUR OFFICES", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = SOFT, Parent = panel }, 20)
text({ Position = UDim2.fromOffset(200, 84), Size = UDim2.new(1, -460, 0, 22), FontFace = BODY, Text = "Tap an office to manage it", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = SOFT, Parent = panel }, 18, 0)
local slotBar = make("ScrollingFrame", {
	Position = UDim2.fromOffset(20, 110), Size = UDim2.new(1, -40, 0, 138), BackgroundColor3 = SLOT, BorderSizePixel = 0,
	ScrollBarThickness = 6, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.new(), ElasticBehavior = Enum.ElasticBehavior.Never, Parent = panel,
}, {
	corner(8), stroke(4),
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
})

-- UPGRADE ALL: every office with a lawyer, cheapest level first, while coins last (Remotes.TrainLawyer("all"))
local allButton, allLabel = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 78), Size = UDim2.fromOffset(240, 30), BackgroundColor3 = GREEN, Parent = panel }, "UPGRADE ALL OFFICES", 18)

-- LEFT: the selected office
local BODY_Y = 262
local left = make("Frame", { Position = UDim2.fromOffset(20, BODY_Y), Size = UDim2.fromOffset(300, H - BODY_Y - 18), BackgroundColor3 = SLOT, Parent = panel }, { corner(8), stroke(4) })
local preview = make("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 116), BackgroundColor3 = WHITE, ClipsDescendants = true, Parent = left }, { corner(6), stroke(3) })
local previewGradient = make("UIGradient", { Rotation = 90, Parent = preview })
local viewport = make("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightDirection = Vector3.new(-1, -1, -1), ZIndex = 2, Parent = preview })
local iconHolder = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = preview })
local emptyPlus = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(90, 90), Text = "+", FontFace = TITLE, ZIndex = 3, Visible = false, Parent = preview }, 90)
local officeTag = text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(150, 22), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = preview }, 20)
local starsLabel = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(90, 26), Text = "", TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4, Parent = preview }, 24)
local nameLabel = text({ Position = UDim2.fromOffset(10, 128), Size = UDim2.new(1, -20, 0, 30), Text = "", Parent = left }, 26)
local rarityPill = make("Frame", { Position = UDim2.fromOffset(10, 162), Size = UDim2.fromOffset(104, 22), BackgroundColor3 = GRAY, Parent = left }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
local rarityText = text({ Size = UDim2.fromScale(1, 1), Text = "", Parent = rarityPill }, 16)
local earnLabel = text({ Position = UDim2.fromOffset(122, 162), Size = UDim2.new(1, -132, 0, 22), Text = "", TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Parent = left }, 20)
local statusLabel = small(text({ Position = UDim2.fromOffset(10, 190), Size = UDim2.new(1, -20, 0, 22), FontFace = BODY, Text = "", TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, Parent = left }, 18, 0))
local statusBar = make("Frame", { Position = UDim2.fromOffset(10, 214), Size = UDim2.new(1, -20, 0, 10), BackgroundColor3 = Color3.fromRGB(20, 20, 30), Visible = false, Parent = left }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
local statusFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, Parent = statusBar }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local upgradeButton, upgradeLabel = button({ Position = UDim2.fromOffset(10, 232), Size = UDim2.new(0.62, -14, 0, 50), BackgroundColor3 = GREEN, Parent = left }, "UPGRADE", 20)
upgradeLabel.TextWrapped = true
-- MAX: as many levels as you can afford for this office (economy pass 2026-10-09: a Supreme resets every office)
local maxButton, maxLabel = button({ Position = UDim2.new(0.62, 2, 0, 232), Size = UDim2.new(0.38, -12, 0, 50), BackgroundColor3 = Color3.fromRGB(40, 170, 30), Parent = left }, "MAX", 20)
maxLabel.TextWrapped = true
local skillsButton, skillsLabel = button({ Position = UDim2.fromOffset(10, 290), Size = UDim2.new(0.5, -14, 0, 44), BackgroundColor3 = GOLD, Parent = left }, "SKILLS", 22)
local skillsBang = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = RED, Visible = false, ZIndex = 4, Parent = skillsButton }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2, WHITE) })
text({ Size = UDim2.fromScale(1, 1), Text = "!", FontFace = TITLE, ZIndex = 5, Parent = skillsBang }, 18)
local unseatButton, unseatLabel = button({ Position = UDim2.new(0.5, 4, 0, 290), Size = UDim2.new(0.5, -14, 0, 44), BackgroundColor3 = ORANGE, Parent = left }, "UNEQUIP", 20)
unseatLabel.TextWrapped = true

-- RIGHT: tabs
local RX = 336
local right = make("Frame", { Position = UDim2.fromOffset(RX, BODY_Y), Size = UDim2.fromOffset(W - RX - 20, H - BODY_Y - 18), BackgroundTransparency = 1, Parent = panel })
local tabButtons: { [string]: TextButton } = {}
local tabLabels: { [string]: TextLabel } = {}
for i, name in { "Clients", "Bench" } do
	local b, l = button({ Position = UDim2.fromOffset((i - 1) * 186, 0), Size = UDim2.fromOffset(176, 42), BackgroundColor3 = if name == "Clients" then Color3.fromRGB(60, 160, 255) else PURPLE, Parent = right }, string.upper(name), 24)
	tabButtons[name] = b
	tabLabels[name] = l
end
if tabButtons.Clients then
	tabButtons.Clients.Visible = false
end
if tabButtons.Bench then
	tabButtons.Bench.Position = UDim2.fromOffset(0, 0)
end
local infoBar = make("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = CARD, Parent = right }, { corner(6), stroke(3) })
local infoText = text({ Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -20, 1, -6), FontFace = BODY, Text = "", RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = infoBar }, 18, 0)
local CONTENT_Y = 94
local clientList = make("ScrollingFrame", {
	Position = UDim2.fromOffset(0, CONTENT_Y), Size = UDim2.new(1, 0, 1, -CONTENT_Y), BackgroundColor3 = SLOT, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = right,
}, {
	corner(8), stroke(4),
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 14) }),
})
local benchFrame = make("Frame", { Position = UDim2.fromOffset(0, CONTENT_Y), Size = UDim2.new(1, 0, 1, -CONTENT_Y), BackgroundTransparency = 1, Visible = false, Parent = right })
local benchGrid = make("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -58), BackgroundColor3 = SLOT, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = benchFrame,
}, {
	corner(8), stroke(4),
	make("UIGridLayout", { CellSize = UDim2.fromOffset(100, 124), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})
local placeButton, placeLabel = button({ Position = UDim2.new(0, 0, 1, -50), Size = UDim2.new(0.66, -6, 0, 50), BackgroundColor3 = GREEN, Parent = benchFrame }, "PICK A LAWYER", 22)
placeLabel.TextWrapped = true
local bestButton, bestLabel = button({ Position = UDim2.new(0.66, 6, 1, -50), Size = UDim2.new(0.34, -6, 0, 50), BackgroundColor3 = GOLD, Parent = benchFrame }, "EQUIP BEST", 22)

-- feedback pill over the "YOUR OFFICES" row (never covers a button)
local toastPill = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 95), Size = UDim2.fromOffset(660, 40), BackgroundColor3 = Color3.fromRGB(24, 22, 36), Visible = false, ZIndex = 20, Parent = panel }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(3) })
local toast = text({ Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 1, -8), Text = "", TextColor3 = GOLD, ZIndex = 21, Parent = toastPill }, 26)

------------------------------------------------------------------ rendering
local selectedOffice = 1
local tab = "Bench" -- (v16: no waiting room, so the CLIENTS tab is hidden)
local benchPick: string? = nil
local focusClient: number? = nil -- highlighted after an [E] Assign Client prompt
local busy = false
local previewKey: string? = nil
local previewConn: RBXScriptConnection? = nil
type SlotRefs = { card: TextButton, pill: Frame, pillText: TextLabel, fill: Frame, stroke: UIStroke, content: Frame, key: string? }
local slotRefs: { [number]: SlotRefs } = {}
local previewSpin: Model? = nil
local previewHome: CFrame? = nil
-- an upgrade's hop + spin for the preview's lawyer (set by Shared.UpgradeFx, played by renderPreview's loop)
local kick = { t0 = -math.huge, dur = 0, hop = 0, spins = 0, bounces = 1 }
local render: () -> ()

local function flash(msg: string, color: Color3?)
	toast.Text = msg
	toast.TextColor3 = color or GOLD
	toastPill.Visible = true
	squish(toastPill)
	task.delay(2.2, function()
		if toast.Text == msg then
			toastPill.Visible = false
		end
	end)
end

local function setButton(b: TextButton, l: TextLabel, label: string, color: Color3, enabled: boolean)
	l.Text = label
	b.BackgroundColor3 = if enabled then color else GRAY
	b.AutoButtonColor = enabled
	b:SetAttribute("Enabled", enabled)
end

local function selectOffice(i: number)
	local count = math.max(deskCount(), 1)
	selectedOffice = math.clamp(i, 1, count)
	player:SetAttribute("SelectedDesk", selectedOffice) -- the Courtroom and Skills follow it
	benchPick = nil
end

local function paintSlot(refs: SlotRefs, o: Office)
	local label, color, progress = status(o)
	refs.pillText.Text = label
	refs.pill.BackgroundColor3 = if progress then color:Lerp(BLACK, 0.45) else color
	refs.fill.Visible = progress ~= nil
	refs.fill.Size = UDim2.fromScale(progress or 0, 1)
	refs.fill.BackgroundColor3 = color
end

-- the office cards are kept between renders (their 3D lawyers are only rebuilt when the office's lawyer changes)
local function slotCard(i: number): SlotRefs
	local refs = slotRefs[i]
	if refs then
		return refs
	end
	local card = make("TextButton", { Size = UDim2.fromOffset(112, 118), BackgroundColor3 = SLOT, Text = "", AutoButtonColor = true, LayoutOrder = i, Parent = slotBar }, { corner(8) })
	local s = stroke(3)
	s.Parent = card
	local content = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = card })
	text({ Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 0, 18), Text = "OFFICE " .. i, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = card }, 15)
	local pill = make("Frame", { Position = UDim2.new(0, 5, 1, -24), Size = UDim2.new(1, -10, 0, 20), BackgroundColor3 = GRAY, ClipsDescendants = true, ZIndex = 3, Parent = card }, { corner(5), stroke(2) })
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, ZIndex = 3, Parent = pill })
	local pillText = text({ Position = UDim2.fromOffset(3, 1), Size = UDim2.new(1, -6, 1, -2), Text = "", ZIndex = 4, Parent = pill }, 14)
	refs = { card = card, pill = pill, pillText = pillText, fill = fill, stroke = s, content = content }
	slotRefs[i] = refs
	card.Activated:Connect(function()
		squish(card)
		if selectedOffice ~= i then
			selectOffice(i)
			-- an empty office wants a lawyer; anyone else: keep the tab the player is on
			if not office(i).lawyerId then
				tab = "Bench"
			end
			render()
		end
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
		local refs = slotCard(i)
		local selected = i == selectedOffice
		refs.stroke.Thickness = if selected then 5 else 3
		refs.stroke.Color = if selected then GOLD else BLACK
		local key = string.format("%s|%d|%s", o.lawyerId or "-", o.stars, tostring(o.skillsReady))
		if refs.key ~= key then
			refs.key = key
			local content = refs.content
			content:ClearAllChildren()
			local card = refs.card
			card.BackgroundColor3 = if o.lawyerId then CARD else SLOT
			local old = card:FindFirstChildOfClass("UIGradient")
			if old then
				old:Destroy()
			end
			if o.lawyerId then
				local _, rColor = rarityOf(o.lawyerId)
				make("UIGradient", { Rotation = 90, Color = ColorSequence.new(rColor:Lerp(CARD, 0.35), CARD), Parent = card })
				-- (art 58 tall, name 20: room for a readable name at phone size, see small())
				local art = make("Frame", { Position = UDim2.fromOffset(4, 14), Size = UDim2.new(1, -8, 0, 58), BackgroundTransparency = 1, Parent = content })
				if not lawyerViewport(art, o.lawyerId, 104 / 58) then
					drawIcon(content, o.lawyerId, 0.52, 18)
				end
				small(text({ Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 0, 20), Text = lawyerName(o.lawyerId, 1), ZIndex = 2, Parent = content }, 15))
				if o.stars > 1 then
					text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 3), Size = UDim2.fromOffset(40, 18), Text = string.rep("★", o.stars - 1), TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = content }, 15)
				end
			else
				text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.fromOffset(60, 52), Text = "+", FontFace = TITLE, TextColor3 = GRAY, Parent = content }, 52)
				small(text({ Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 0, 20), Text = "Equip a lawyer", TextColor3 = SOFT, Parent = content }, 14))
			end
			if o.skillsReady then
				local bang = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 26), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = RED, ZIndex = 5, Parent = content }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2, WHITE) })
				text({ Size = UDim2.fromScale(1, 1), Text = "!", FontFace = TITLE, ZIndex = 6, Parent = bang }, 15)
			end
		end
		paintSlot(refs, o)
	end
end

-- the big preview: the selected office's lawyer in 3D, gently swaying
local function renderPreview(o: Office)
	local key = if o.lawyerId then o.lawyerId else "empty"
	if key == previewKey then
		return
	end
	previewKey = key
	previewSpin, previewHome = nil, nil
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	viewport:ClearAllChildren()
	iconHolder:ClearAllChildren()
	if not o.lawyerId then
		previewGradient.Color = ColorSequence.new(Color3.fromRGB(90, 88, 120), Color3.fromRGB(60, 58, 84))
		emptyPlus.Visible = true
		return
	end
	emptyPlus.Visible = false
	local _, color = rarityOf(o.lawyerId)
	previewGradient.Color = ColorSequence.new(color:Lerp(WHITE, 0.7), color:Lerp(WHITE, 0.25))
	local vf, m = lawyerViewport(iconHolder, o.lawyerId, 268 / 116, 0)
	if vf and m then
		previewSpin, previewHome = m, m:GetPivot()
		local box, size = m:GetBoundingBox()
		local center = box.Position
		previewConn = RunService.RenderStepped:Connect(function()
			local t = os.clock()
			-- an upgrade's hops + spins (kick), eased out
			local hop, spin = 0, 0
			local k = t - kick.t0
			if k >= 0 and k < kick.dur then
				local u = k / kick.dur
				hop = math.abs(math.sin(u * math.pi * kick.bounces)) * kick.hop * size.Y * (1 - u * 0.4)
				spin = kick.spins * math.pi * 2 * (1 - (1 - u) ^ 3)
			end
			-- turn about its own centre, with a little idle bob
			local turn = CFrame.new(center) * CFrame.Angles(0, math.sin(t * 1.2) * 0.5 + spin, 0) * CFrame.new(center):Inverse()
			m:PivotTo(CFrame.new(0, math.sin(t * 2.6) * 0.06 + hop, 0) * turn * (previewHome :: CFrame))
		end)
	else
		drawIcon(iconHolder, o.lawyerId, 1.05, 12)
	end
end


local function upgradeText(o: Office): (string, boolean)
	local coins = (player:GetAttribute("Coins") :: number?) or 0
	if o.level >= Config.Lawyer.MaxLevel then
		return "MAX LEVEL", false
	end
	if ((player:GetAttribute("FreeLevelUps") :: number?) or 0) > 0 then
		return string.format("UPGRADE Lv %d→%d\nFREE!", o.level, o.level + 1), true
	end
	local cost = Formulas.trainCost(o.level)
	return string.format("UPGRADE Lv %d→%d\n$%s", o.level, o.level + 1, Formulas.formatCoins(cost)), coins >= cost
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

-- the live parts of the left card (status line, progress, buttons) - also run by the 4x/s tick
local function renderLeftLive()
	local o = office(selectedOffice)
	local label, color, progress = status(o)
	if not o.lawyerId then
		statusLabel.Text = "No lawyer equipped. Pick one in the EQUIP tab."
	elseif o.queued and isBusy(o) then
		local who = if o.queued == "unseat" then "Gets unequipped" else "Swaps out"
		statusLabel.Text = string.format("%s when %s's case ends", who, o.clientName or "this")
	elseif o.phase == "Case" then
		statusLabel.Text = string.format("On %s's case · %s", o.clientName or "a", string.lower((label:gsub("ON A CASE ", ""))))
	elseif o.phase == "Walking" then
		statusLabel.Text = string.format("%s is walking over...", o.clientName or "A client")
	else
		statusLabel.Text = "Free! Assign a client, or unequip / swap now."
	end
	statusLabel.TextColor3 = if o.lawyerId and o.phase == "Idle" then GREEN elseif color == PURPLE then Color3.fromRGB(215, 160, 255) else SOFT
	statusBar.Visible = progress ~= nil and not o.queued
	statusFill.Size = UDim2.fromScale(progress or 0, 1)
	-- buttons
	local up, canUp = upgradeText(o)
	setButton(upgradeButton, upgradeLabel, up, GREEN, canUp)
	local n = if o.level < Config.Lawyer.MaxLevel then affordableLevels(o.level) else 0
	setButton(maxButton, maxLabel, if n > 0 then string.format("MAX\n+%d", n) else "MAX", Color3.fromRGB(40, 170, 30), n > 1)
	-- UPGRADE ALL: any office with a lawyer that can take a level right now
	local anyAffordable = false
	for i = 1, deskCount() do
		local oi = office(i)
		if oi.lawyerId and oi.level < Config.Lawyer.MaxLevel and affordableLevels(oi.level) > 0 then
			anyAffordable = true
			break
		end
	end
	setButton(allButton, allLabel, "UPGRADE ALL OFFICES", GREEN, anyAffordable)
	setButton(skillsButton, skillsLabel, "SKILLS", GOLD, o.lawyerId ~= nil)
	skillsBang.Visible = o.skillsReady
	unseatButton.Visible = true
	if not o.lawyerId then
		setButton(unseatButton, unseatLabel, "EQUIP LAWYER", PURPLE, true)
	elseif o.queued and isBusy(o) then
		setButton(unseatButton, unseatLabel, "CANCEL CHANGE", RED, true)
	elseif isBusy(o) then
		setButton(unseatButton, unseatLabel, "UNEQUIP AFTER CASE", ORANGE, true)
	else
		setButton(unseatButton, unseatLabel, "UNEQUIP", ORANGE, true)
	end
end

local function renderLeft()
	local o = office(selectedOffice)
	renderPreview(o)
	officeTag.Text = string.format("OFFICE %d · Lv %d", o.index, o.level)
	if o.lawyerId then
		local rName, rColor = rarityOf(o.lawyerId)
		nameLabel.Text = lawyerName(o.lawyerId, o.stars)
		starsLabel.Text = string.rep("★", o.stars)
		rarityPill.Visible = true
		rarityPill.BackgroundColor3 = rColor
		rarityText.Text = string.upper(rName)
		earnLabel.Text = string.format("Earns x%s", tostring(Formulas.lawyerEarn(o.lawyerId, o.stars)))
	else
		nameLabel.Text = "Empty Office"
		starsLabel.Text = ""
		rarityPill.Visible = false
		earnLabel.Text = ""
	end
	renderLeftLive()
end

-- the upgrade celebrations (Shared.UpgradeFx, 2026-10-13): bigger for MAX / UPGRADE ALL, biggest at max level
local upgradeFx = (require(Shared:WaitForChild("UpgradeFx") :: ModuleScript) :: any).new({
	panel = panel, preview = preview, slotBar = slotBar, officeTag = officeTag, width = W, height = H, kick = kick,
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
		officeTag.Text = string.format("OFFICE %d · Lv %d", i, level)
	end,
	lawyerViewport = lawyerViewport,
})

-- why the selected office can't take a client right now (nil = it can)
local function assignBlocker(o: Office): string?
	if not o.lawyerId then
		return string.format("Office %d has no lawyer yet", o.index)
	elseif o.queued and isBusy(o) then
		return string.format("Office %d's lawyer is being swapped out", o.index)
	elseif o.phase ~= "Idle" then
		return string.format("Office %d is busy - pick a FREE office above", o.index)
	end
	return nil
end

local closePanel: () -> () -- (defined below)

local function doAssign(c: Client)
	if busy then
		return
	end
	local o = office(selectedOffice)
	local blocker = assignBlocker(o)
	if blocker then
		flash(blocker, RED)
		return
	end
	if not c.Seated then
		flash((c.Name or "That client") .. " is still finding a seat", RED)
		return
	end
	busy = true
	local ok, reason = AssignClient:InvokeServer(c.Id, selectedOffice)
	busy = false
	if ok then
		flash(string.format("%s → Office %d!", c.Name or "Client", selectedOffice), GREEN)
		focusClient = nil
		-- one client per assignment (user's call): close, the Manager is the one who assigns everyone
		task.delay(0.7, closePanel)
	else
		flash(reason or "Can't assign right now", RED)
	end
	render()
end

local function renderClients(o: Office)
	for _, c in clientList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local list = waitingClients()
	local blocker = assignBlocker(o)
	if #list == 0 then
		text({ Size = UDim2.new(1, 0, 0, 60), FontFace = BODY, Text = "No clients waiting right now.\nNew ones walk into your firm every few seconds!", TextColor3 = SOFT, TextWrapped = true, Parent = clientList }, 20, 0)
	end
	local focusRow: GuiObject? = nil
	for order, c in list do
		local def = Config.Clients[c.Tier]
		local color = clientColor(c.Tier)
		local focused = c.Id == focusClient
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = CARD, LayoutOrder = order, Parent = clientList }, { corner(6) })
		stroke(if focused then 4 else 3, if focused then GOLD else BLACK).Parent = row
		make("Frame", { Size = UDim2.new(0, 10, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, Parent = row }, { corner(6) })
		text({ Position = UDim2.fromOffset(20, 6), Size = UDim2.new(1, -250, 0, 26), Text = c.Name or (def and def.Name) or "Client", TextXAlignment = Enum.TextXAlignment.Left, Parent = row }, 22)
		-- the situation wraps onto two lines (it used to shrink to fit one); small() keeps it readable on phones
		small(text({ Position = UDim2.fromOffset(20, 32), Size = UDim2.new(1, -250, 0, 40), FontFace = BODY, Text = c.Situation or "", TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row }, 16, 0), true)
		-- rarity + what the selected lawyer's chances look like
		local chip = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -128, 0, 8), Size = UDim2.fromOffset(100, 22), BackgroundColor3 = color, Parent = row }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
		text({ Size = UDim2.fromScale(1, 1), Text = string.upper(def and def.Id or "Client"), Parent = chip }, 14)
		local chance = if o.lawyerId then Formulas.winChance(o.level, def and def.Difficulty or 0, 0) else nil
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -128, 0, 34), Size = UDim2.fromOffset(100, 22), Text = if chance then string.format("%d%% win", math.round(chance * 100)) else "", TextColor3 = GREEN, Parent = row }, 17)
		local can = blocker == nil and c.Seated
		local b, l = button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(110, 46), BackgroundColor3 = GREEN, Parent = row }, "ASSIGN", 22)
		setButton(b, l, if c.Seated then "ASSIGN" else "ARRIVING", GREEN, can)
		b.Activated:Connect(function()
			doAssign(c)
		end)
		if focused then
			focusRow = row
		end
	end
	if focusRow then
		task.defer(function()
			clientList.CanvasPosition = Vector2.new(0, math.max(0, (focusRow :: GuiObject).AbsolutePosition.Y - clientList.AbsolutePosition.Y + clientList.CanvasPosition.Y - 8))
		end)
	end
end

local function placeAction(o: Office, l: Lawyer?): (string, boolean, Color3)
	if not l then
		return if o.lawyerId then "PICK A LAWYER TO SWAP IN" else "PICK A LAWYER TO EQUIP", false, GREEN
	end
	if l.Office == o.index then
		return "ALREADY EQUIPPED HERE", false, GREEN
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
	if o.lawyerId then
		return string.format("EQUIP IN OFFICE %d", o.index), true, GREEN
	end
	return string.format("EQUIP IN OFFICE %d", o.index), true, GREEN
end

type BenchCard = { card: TextButton, overlay: Frame, stroke: UIStroke, key: string? }
local benchCards: { [string]: BenchCard } = {}

local function benchCard(l: Lawyer): BenchCard
	local entry = benchCards[l.Uid]
	if entry then
		return entry
	end
	local _, rColor = rarityOf(l.Id)
	local card = make("TextButton", { Text = "", BackgroundColor3 = CARD, AutoButtonColor = true, Parent = benchGrid }, { corner(8) })
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(rColor:Lerp(CARD, 0.3), CARD), Parent = card })
	local s = stroke(3)
	s.Parent = card
	local art = make("Frame", { Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 74), BackgroundTransparency = 1, Parent = card })
	if not lawyerViewport(art, l.Id, 92 / 74) then
		drawIcon(card, l.Id, 0.6, 18)
	end
	local overlay = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card })
	entry = { card = card, overlay = overlay, stroke = s }
	benchCards[l.Uid] = entry
	card.Activated:Connect(function()
		squish(card)
		benchPick = l.Uid
		render()
	end)
	return entry
end

local function renderBench(o: Office)
	local list = lawyers()
	if benchPick and not findLawyer(list, benchPick) then
		benchPick = nil
	end
	-- bench lawyers first (strongest first), then the ones already working
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
	-- merged-away / gone lawyers lose their cards
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
		text({ Name = "EmptyNote", Size = UDim2.fromOffset(300, 60), FontFace = BODY, Text = "No lawyers yet - hatch eggs at the hub!", TextColor3 = SOFT, TextWrapped = true, Parent = benchGrid }, 20, 0)
	elseif #list > 0 and empty then
		empty:Destroy()
	end
	for order, l in list do
		local entry = benchCard(l)
		local picked = l.Uid == benchPick
		local _, rColor = rarityOf(l.Id)
		entry.card.LayoutOrder = order
		entry.stroke.Thickness = if picked then 5 else 3
		entry.stroke.Color = if picked then GOLD else rColor:Lerp(BLACK, 0.35)
		local busyHere = l.Office ~= nil and isBusy(office(l.Office))
		local mergeable = l.Stars < #Config.Lawyers.StarEarn and copiesOf(list, l) >= Config.Lawyers.MergeCount
		local key = string.format("%d|%s|%s|%s", l.Stars, tostring(l.Office), tostring(busyHere), tostring(mergeable))
		if entry.key ~= key then
			entry.key = key
			local overlay = entry.overlay
			overlay:ClearAllChildren()
			small(text({ Position = UDim2.fromOffset(4, 78), Size = UDim2.new(1, -8, 0, 18), Text = lawyerName(l.Id, 1), ZIndex = 2, Parent = overlay }, 15))
			text({ Position = UDim2.fromOffset(4, 98), Size = UDim2.new(0.5, -4, 0, 20), Text = string.rep("★", l.Stars), TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = overlay }, 16)
			text({ Position = UDim2.new(0.5, 0, 0, 98), Size = UDim2.new(0.5, -4, 0, 20), Text = "x" .. tostring(Formulas.lawyerEarn(l.Id, l.Stars)), TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2, Parent = overlay }, 16)
			if l.Office then -- equipped: which office (orange while it's on a case)
				local tag = make("Frame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(62, 18), BackgroundColor3 = if busyHere then ORANGE else GREEN, ZIndex = 3, Parent = overlay }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
				text({ Size = UDim2.fromScale(1, 1), Text = "OFFICE " .. l.Office, ZIndex = 4, Parent = tag }, 12)
			end
			if mergeable then
				local m = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(30, 18), BackgroundColor3 = PURPLE, ZIndex = 3, Parent = overlay }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
				text({ Size = UDim2.fromScale(1, 1), Text = "3x", ZIndex = 4, Parent = m }, 12)
			end
		end
	end
	local pick = findLawyer(list, benchPick)
	local label, enabled, color = placeAction(o, pick)
	setButton(placeButton, placeLabel, label, color, enabled)
	setButton(bestButton, bestLabel, "EQUIP BEST", GOLD, #list > 0)
end


local function renderInfo(o: Office)
	local G, O, P = "#5CF03C", "#FFB43C", "#D7A0FF"
	local msg
	if tab == "Clients" then
		local free = {}
		for i = 1, deskCount() do
			if i ~= o.index and office(i).phase == "Idle" then
				table.insert(free, tostring(i))
			end
		end
		local alsoFree = if #free > 0 then "  Free now: Office " .. table.concat(free, ", ") else ""
		if not o.lawyerId then
			msg = string.format('<font color="%s">Office %d has no lawyer.</font> Equip one in the EQUIP tab.', O, o.index)
		elseif o.queued and isBusy(o) then
			msg = string.format('<font color="%s">Office %d is being swapped out.</font>%s', P, o.index, alsoFree)
		elseif o.phase ~= "Idle" then
			local label = status(o)
			msg = string.format('<font color="%s">Office %d is busy (%s).</font>%s', O, o.index, string.lower(label), alsoFree)
		else
			msg = string.format('<font color="%s">Office %d is free!</font> Pick a client to send to %s.', G, o.index, lawyerName(o.lawyerId :: string, o.stars))
		end
	else
		local list = lawyers()
		local pick = findLawyer(list, benchPick)
		if pick and pick.Stars < #Config.Lawyers.StarEarn and copiesOf(list, pick) >= Config.Lawyers.MergeCount then
			msg = string.format('You have %d of these! <font color="%s">Merge them at the Lawyer Merger</font> for +1 star.', copiesOf(list, pick), P)
		elseif o.lawyerId and isBusy(o) then
			msg = string.format('<font color="%s">Office %d is on a case.</font> Your pick gets equipped the moment it ends.', O, o.index)
		elseif o.lawyerId then
			msg = string.format('Pick a lawyer to equip in <font color="%s">Office %d</font>.', G, o.index)
		else
			msg = string.format('Pick a lawyer to equip in <font color="%s">Office %d</font>.', G, o.index)
		end
	end
	infoText.Text = msg
end

local function renderTabs()
	local waiting = 0
	for _, c in waitingClients() do
		if c.Seated then
			waiting += 1
		end
	end
	local list = lawyers()
	local bench = 0
	for _, l in list do
		if not l.Office then
			bench += 1
		end
	end
	tabLabels.Clients.Text = string.format("CLIENTS (%d)", waiting)
	tabLabels.Bench.Text = string.format("EQUIP (%d)", bench)
	for name, b in tabButtons do
		local s = b:FindFirstChildOfClass("UIStroke") :: UIStroke
		s.Thickness = if name == tab then 5 else 3
		s.Color = if name == tab then WHITE else BLACK
		b.BackgroundTransparency = if name == tab then 0 else 0.35
	end
	clientList.Visible = tab == "Clients"
	benchFrame.Visible = tab == "Bench"
	countLabel.Text = string.format("%d / %d lawyers · %d offices", #list, Config.Lawyers.MaxOwned, deskCount())
end

render = function()
	if deskCount() > 0 and selectedOffice > deskCount() then
		selectOffice(deskCount())
	end
	local o = office(selectedOffice)
	renderSlots()
	renderLeft()
	renderTabs()
	renderInfo(o)
	if tab == "Clients" then
		renderClients(o)
	else
		renderBench(o)
	end
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
	return math.clamp(math.min((view.X - 24) / W, (view.Y - 24) / H), 0.35, 1)
end

local function open(opts: any)
	local o = opts or {}
	focusClient = o.client
	if o.office then
		selectOffice(o.office)
	elseif o.client then
		-- from a waiting client: the best free lawyer is preselected, ready to take them
		selectOffice(bestFreeOffice() or selectedOffice)
	else
		local selected = player:GetAttribute("SelectedDesk")
		selectOffice(if typeof(selected) == "number" then selected else selectedOffice)
	end
	tab = o.tab or (if o.client then "Clients" elseif not office(selectedOffice).lawyerId then "Bench" else tab)
	if tab == "Clients" then
		tab = "Bench" -- (no waiting room since v16)
	end
	setTextMode(fit()) -- before render(), so new labels start in the right text mode
	previewKey = nil
	toastPill.Visible = false
	render()
	if not panel.Visible then
		panel.Visible = true
		shade.Visible = true
		shade.BackgroundTransparency = 1
		tween(shade, 0.2, { BackgroundTransparency = 0.35 })
		local s = fit()
		panelScale.Scale = s * 0.6
		tween(panelScale, 0.3, { Scale = s }, Enum.EasingStyle.Back)
		MarkSkinsSeen:FireServer()
	end
end

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
	focusClient = nil
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	previewKey = nil
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

for name, b in tabButtons do
	b.Activated:Connect(function()
		tab = name
		render()
	end)
end

local function upgrade(target: any, count: any, label: string)
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

unseatButton.Activated:Connect(function()
	if busy then
		return
	end
	local o = office(selectedOffice)
	if not o.lawyerId then
		tab = "Bench"
		render()
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
	flash(msg or (if ok then "Done!" else "Can't do that"), if ok then GREEN else RED)
	render()
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
		flash("Tap a lawyer below first", RED)
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
		flash(msg or string.format("%s → Office %d!", lawyerName(pick.Id, pick.Stars), selectedOffice), if queued then Color3.fromRGB(215, 160, 255) else GREEN)
		benchPick = nil
		if not queued then
			previewKey = nil
		end
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
		benchPick = nil
		previewKey = nil
	end
	render()
end)

------------------------------------------------------------------ wiring
-- other scripts: Fire(office) or Fire({ office, client, tab })
openEvent.Event:Connect(function(arg: any)
	if typeof(arg) == "number" then
		open({ office = arg, tab = if office(arg).lawyerId then nil else "Bench" })
	elseif typeof(arg) == "table" then
		open(arg)
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
		end
	elseif name == "Lawyers" or name == "WaitingClients" or name == "DeskCount" or name == "FreeLevelUps" or string.match(name, "^Desk%d+") then
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
			for i, refs in slotRefs do
				paintSlot(refs, office(i))
			end
			renderLeftLive()
			if tab == "Clients" then
				renderInfo(office(selectedOffice))
			end
		end
	end
end)

-- keep the panel fitted when the window / phone rotates
local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if panel.Visible then
				panelScale.Scale = fit()
				setTextMode(panelScale.Scale)
			end
		end)
	end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
