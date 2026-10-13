--!strict
-- Shared.UpgradeFx - the office upgrade celebrations in the LAWYERS panel (StarterPlayerScripts.Lawyers, 2026-10-13).
-- User: "upgrade animations when the character gets upgraded in the lawyers tab, make it way bigger for the max
-- level or upgrading multiple levels". Scaled by how big the upgrade was:
--   1 level      the lawyer hops and spins on a sunburst, "LEVEL UP!", a star burst, the office card bounces
--   2+ levels    (MAX, UPGRADE ALL) the level counts up with rising pings, more hops and spins, confetti, a big
--                burst, "+N LEVELS!", the panel shakes - all growing with the number of levels (full size at 50+)
--   a new look   (the office's tier changes) at least half that size, plus "NEW LOOK: <name>!"
--   max level    then the whole panel celebrates: the lawyer big on a gold sunburst, rainbow "MAX LEVEL!",
--                bursts and confetti rain (tap to close, or it closes itself)
-- Cosmetic and client-only: the levels come from the server's answer / the mirrored Desk<N>Level attributes. Sounds
-- go through the local HatchCue bindable (Sounds.client: "beat" = a rising ping, "burst" = the sting).
-- UpgradeFx.new(ctx) -> { one(office, fromLevel, toLevel, newLook?), all(levelsBefore, newLook?), close() }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local UIFonts = require(Shared:WaitForChild("UIFonts") :: ModuleScript) :: any

export type Ctx = {
	panel: GuiObject, -- the LAWYERS panel (W x H design pixels, shrunk by a UIScale)
	preview: GuiObject, -- the selected office's 3D lawyer box
	slotBar: GuiObject, -- the office row (UPGRADE ALL celebrates over it)
	officeTag: TextLabel, -- "OFFICE n · Lv x" on the preview
	width: number,
	height: number,
	kick: { t0: number, dur: number, hop: number, spins: number, bounces: number }, -- the preview's hop, read by the panel
	card: (i: number) -> GuiObject?, -- office i's card in the slot bar
	office: (i: number) -> { lawyerId: string?, level: number },
	selected: () -> number,
	deskCount: () -> number,
	setTag: (i: number, level: number) -> (),
	lawyerViewport: (parent: GuiObject, id: string, aspect: number, yaw: number?) -> (ViewportFrame?, Model?),
}

local UpgradeFx = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(255, 200, 40)
local GREEN = Color3.fromRGB(76, 224, 48)
local SKY = Color3.fromRGB(120, 220, 255)
local SOFT = Color3.fromRGB(205, 200, 235)
local CONFETTI = {
	GOLD, GREEN, Color3.fromRGB(60, 160, 255), Color3.fromRGB(176, 52, 255), Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 160, 24),
}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 70)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 230, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
})
local Z = 40 -- over everything else in the panel (its toast is 20)
local FULL_AT = 50 -- levels in one go for the full-size celebration

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function cue(kind: string, value: number)
	local e = ReplicatedStorage:FindFirstChild("HatchCue")
	if e and e:IsA("BindableEvent") then
		e:Fire(kind, value)
	end
end

-- how big an upgrade of `levels` feels, 0..1 (2 levels ~0.18, 10 ~0.6, 50+ = 1)
local function powerOf(levels: number): number
	return math.clamp(math.log(math.max(levels, 1)) / math.log(FULL_AT), 0, 1)
end

-- outlined words (LuckiestGuy unless `font` says otherwise)
local function words(parent: Instance, msg: string, color: Color3, at: UDim2, size: number, z: number, font: Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = at
	l.Size = UDim2.fromOffset(math.max(100, #msg * size * 0.72 + 30), size * 1.3)
	l.BackgroundTransparency = 1
	l.FontFace = font or UIFonts.TitleFace
	l.Text = msg
	l.TextSize = size
	l.TextColor3 = color
	l.ZIndex = z
	local s = Instance.new("UIStroke")
	s.Thickness = math.max(3, math.floor(size / 9))
	s.Color = BLACK
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- keeps a line of `size` text centred at x inside 0..width
local function clampX(x: number, msg: string, size: number, width: number): number
	local half = #msg * size * 0.34 + 12
	return math.clamp(x, half, math.max(half, width - half))
end

local function popIn(g: GuiObject, from: number, t: number?): UIScale
	local sc = g:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	sc.Scale = from
	sc.Parent = g
	tween(sc, t or 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	return sc
end

local function fadeOut(l: TextLabel, t: number)
	tween(l, t, { TextTransparency = 1 })
	local s = l:FindFirstChildOfClass("UIStroke")
	if s then
		tween(s, t, { Transparency = 1 })
	end
end

-- words that pop in, float up `rise` px and fade over `life` seconds
local function floatWords(parent: Instance, msg: string, color: Color3, at: Vector2, size: number, rise: number, life: number, z: number): TextLabel
	local l = words(parent, msg, color, UDim2.fromOffset(at.X, at.Y), size, z)
	popIn(l, 0.25, 0.4)
	tween(l, life, { Position = UDim2.fromOffset(at.X, at.Y - rise) })
	task.delay(life * 0.7, fadeOut, l, life * 0.3)
	task.delay(life + 0.05, function()
		l:Destroy()
	end)
	return l
end

-- a scrolling rainbow over a label's text
local function rainbow(l: TextLabel)
	local g = Instance.new("UIGradient")
	g.Color = RAINBOW
	g.Parent = l
	l.TextColor3 = WHITE
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not l.Parent then
			conn:Disconnect()
			return
		end
		g.Offset = Vector2.new(math.sin(os.clock() * 2.2) * 0.4, 0)
	end)
end

function UpgradeFx.new(ctx: Ctx)
	local panel = ctx.panel
	local home = panel.Position
	local shakeId = 0
	local closeMax: (() -> ())? = nil

	-- a box's centre in the panel's design pixels
	local function panelPoint(g: GuiObject): Vector2
		local s = math.max(panel.AbsoluteSize.X / ctx.width, 0.05)
		return (g.AbsolutePosition + g.AbsoluteSize * 0.5 - panel.AbsolutePosition) / s
	end

	local function shake(amp: number, seconds: number)
		shakeId += 1
		local id = shakeId
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local age = os.clock() - t0
			if id ~= shakeId then
				conn:Disconnect()
				return
			end
			if age >= seconds or not panel.Visible then
				conn:Disconnect()
				panel.Position = home
				return
			end
			local k = amp * (1 - age / seconds)
			panel.Position = home + UDim2.fromOffset((math.random() * 2 - 1) * k, (math.random() * 2 - 1) * k)
		end)
	end

	-- paper confetti: a burst out of `from`, or (from = nil) rain over the whole panel
	local function confetti(from: Vector2?, n: number, speed: number, z: number, parent: GuiObject?)
		local host = parent or panel
		local rain = from == nil
		local pieces = {}
		for i = 1, n do
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Size = UDim2.fromOffset(math.random(8, 15), math.random(5, 9))
			f.BackgroundColor3 = CONFETTI[math.random(#CONFETTI)]
			f.BorderSizePixel = 0
			f.ZIndex = z
			f.Parent = host
			local p: Vector2, v: Vector2
			if from then
				local a = math.random() * math.pi * 2
				local s = speed * (0.35 + math.random() * 0.75)
				p = from
				v = Vector2.new(math.cos(a) * s, math.sin(a) * s * 0.7 - speed * 0.7)
			else
				p = Vector2.new(math.random() * ctx.width, -10 - math.random() * ctx.height * 0.8)
				v = Vector2.new((math.random() - 0.5) * 80, 120 + math.random() * 140)
			end
			pieces[i] = { f = f, p = p, v = v, r = math.random() * 360, vr = (math.random() - 0.5) * 900, w = math.random() * 6 }
		end
		local life = if rain then 3.6 else 1.5
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function(dt)
			local age = os.clock() - t0
			local fade = math.clamp((age - life * 0.7) / (life * 0.3), 0, 1)
			for _, c in pieces do
				if rain then
					c.p += (c.v + Vector2.new(math.sin(age * 3 + c.w) * 50, 0)) * dt
				else
					c.v += Vector2.new(0, 700 * dt)
					c.v *= 1 - math.min(dt * 1.6, 0.5)
					c.p += c.v * dt
				end
				c.r += c.vr * dt
				c.f.Position = UDim2.fromOffset(c.p.X, c.p.Y)
				c.f.Rotation = c.r
				c.f.BackgroundTransparency = fade
			end
			if age >= life or not host.Parent then
				conn:Disconnect()
				for _, c in pieces do
					c.f:Destroy()
				end
			end
		end)
	end

	-- a turning sunburst over a soft glow (Effects' textures: Skin.Assets.Rays / Glow don't load, checked 2026-10-13);
	-- returns stop(fade)
	local function sunburst(parent: GuiObject, at: UDim2, px: number, color: Color3, transparency: number, z: number): (number?) -> ()
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = at
		holder.Size = UDim2.fromOffset(px, px)
		holder.BackgroundTransparency = 1
		holder.ZIndex = z
		holder.Parent = parent
		local function img(image: string, tint: Color3, scale: number): ImageLabel
			local i = Instance.new("ImageLabel")
			i.AnchorPoint = Vector2.new(0.5, 0.5)
			i.Position = UDim2.fromScale(0.5, 0.5)
			i.Size = UDim2.fromScale(scale, scale)
			i.BackgroundTransparency = 1
			i.Image = image
			i.ImageColor3 = tint
			i.ImageTransparency = 1
			i.ZIndex = z
			i.Parent = holder
			return i
		end
		local glow = img(Effects.TEXTURES.glow, color, 0.8)
		local r1 = img(Effects.TEXTURES.rays, color, 1)
		local r2 = img(Effects.TEXTURES.rays, WHITE, 0.75)
		tween(glow, 0.25, { ImageTransparency = math.min(1, transparency + 0.15) })
		tween(r1, 0.25, { ImageTransparency = transparency })
		tween(r2, 0.25, { ImageTransparency = math.min(1, transparency + 0.3) })
		popIn(holder, 0.3, 0.45)
		local conn = RunService.RenderStepped:Connect(function(dt)
			r1.Rotation += dt * 30
			r2.Rotation -= dt * 45
		end)
		local stopped = false
		return function(fade: number?)
			if stopped then
				return
			end
			stopped = true
			local f = fade or 0.4
			for _, i in { glow, r1, r2 } do
				tween(i, f, { ImageTransparency = 1 })
			end
			task.delay(f + 0.05, function()
				conn:Disconnect()
				holder:Destroy()
			end)
		end
	end

	-- the preview's lawyer hops `bounces` times and spins `spins` turns (the panel's preview loop reads ctx.kick)
	local function hop(bounces: number, spins: number, seconds: number, height: number)
		local k = ctx.kick
		k.t0, k.dur, k.bounces, k.spins, k.hop = os.clock(), seconds, bounces, spins, height
	end

	local function tagPop()
		local tag = ctx.officeTag
		tag.TextColor3 = GOLD
		popIn(tag, 1.35, 0.35)
		task.delay(0.8, function()
			tag.TextColor3 = WHITE
		end)
	end

	-- an office card in the slot bar bounces, flashes and shows "+N" (or "MAX!")
	local function popCard(i: number, gained: number, maxed: boolean)
		local card = ctx.card(i)
		if not card then
			return
		end
		local sc = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		sc.Parent = card
		sc.Scale = 1.14
		tween(sc, 0.7, { Scale = 1 }, Enum.EasingStyle.Elastic)
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = if maxed then WHITE else GOLD
		flash.BackgroundTransparency = 0.2
		flash.ZIndex = 8
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = flash
		flash.Parent = card
		tween(flash, 0.5, { BackgroundTransparency = 1 })
		local l = words(card, if maxed then "MAX!" else "+" .. gained, if maxed then GOLD else GREEN, UDim2.fromScale(0.5, 0.45), 34, 9)
		popIn(l, 0.3, 0.3)
		tween(l, 0.9, { Position = UDim2.fromScale(0.5, 0.2) })
		task.delay(0.6, fadeOut, l, 0.35)
		task.delay(1, function()
			flash:Destroy()
			l:Destroy()
		end)
	end

	-- the big "Lv x" under the preview rolls from `from` to `to` with rising pings, then slams
	local function countUp(i: number, from: number, to: number, seconds: number, at: Vector2)
		local l = words(panel, "Lv " .. from, WHITE, UDim2.fromOffset(at.X, at.Y + 34), 46, Z + 3)
		local sc = popIn(l, 0.4, 0.25)
		local steps = math.clamp(to - from, 1, 10)
		for k = 1, steps do
			task.delay(seconds * (k - 0.5) / steps, cue, "beat", math.min(k, 8))
		end
		local t0 = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local u = math.clamp((os.clock() - t0) / seconds, 0, 1)
			local lv = from + math.floor((to - from) * (1 - (1 - u) ^ 2) + 0.5)
			l.Text = "Lv " .. lv
			if i == ctx.selected() then
				ctx.setTag(i, lv)
			end
			if u >= 1 then
				conn:Disconnect()
				l.TextColor3 = GOLD
				sc.Scale = 1.5
				tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
				task.delay(0.9, fadeOut, l, 0.3)
				task.delay(1.25, function()
					l:Destroy()
				end)
			end
		end)
	end

	-- the whole panel celebrates office i reaching max level
	local function maxLevel(i: number)
		if closeMax then
			closeMax()
		end
		if not panel.Visible then
			return
		end
		local W, H = ctx.width, ctx.height
		local o = ctx.office(i)
		local ov = Instance.new("TextButton")
		ov.Name = "MaxLevelFx"
		ov.Size = UDim2.fromScale(1, 1)
		ov.BackgroundColor3 = Color3.fromRGB(22, 12, 44)
		ov.BackgroundTransparency = 1
		ov.Text = ""
		ov.AutoButtonColor = false
		ov.ZIndex = Z + 10
		ov:SetAttribute("NoSkin", true)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = ov
		ov.Parent = panel
		tween(ov, 0.25, { BackgroundTransparency = 0.12 })
		local centre = Vector2.new(W / 2, H / 2 + 6)
		local at = UDim2.fromOffset(centre.X, centre.Y)
		local stopRays = sunburst(ov, at, 820, GOLD, 0.2, Z + 11)
		local stopRays2 = sunburst(ov, at, 520, Color3.fromRGB(255, 120, 220), 0.45, Z + 11)
		-- the lawyer, big: a fast whirl that settles into a turn, bouncing
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = at
		holder.Size = UDim2.fromOffset(300, 300)
		holder.BackgroundTransparency = 1
		holder.ZIndex = Z + 12
		holder.Parent = ov
		local holderScale = popIn(holder, 0.2, 0.55)
		local spinConn: RBXScriptConnection? = nil
		if o.lawyerId then
			local _, m = ctx.lawyerViewport(holder, o.lawyerId, 1, 0)
			if m then
				local rest = m:GetPivot()
				local box, size = m:GetBoundingBox()
				local c = box.Position
				local t0 = os.clock()
				spinConn = RunService.RenderStepped:Connect(function()
					local t = os.clock() - t0
					local spin = t * 2.4 + (1 - math.exp(-t * 3)) * math.pi * 4
					local bob = math.abs(math.sin(t * 3.2)) * size.Y * 0.06
					m:PivotTo(CFrame.new(0, bob, 0) * CFrame.new(c) * CFrame.Angles(0, spin, 0) * CFrame.new(c):Inverse() * rest)
				end)
			end
		end
		local title = words(ov, "MAX LEVEL!", WHITE, UDim2.fromOffset(centre.X, 78), 78, Z + 14)
		rainbow(title)
		popIn(title, 0.2, 0.5)
		local sub = words(ov, string.format("OFFICE %d  ·  Lv %d", i, Config.Lawyer.MaxLevel), GOLD, UDim2.fromOffset(centre.X, H - 104), 34, Z + 14, UIFonts.PrimaryFace)
		popIn(sub, 0.3, 0.45)
		local hint = words(ov, "Tap to continue", SOFT, UDim2.fromOffset(centre.X, H - 54), 20, Z + 14, UIFonts.BodyFace)
		hint.TextTransparency = 1
		task.delay(1.2, function()
			if hint.Parent then
				tween(hint, 0.3, { TextTransparency = 0 })
			end
		end)
		-- bursts all over, confetti, the sting
		Effects.guiBurst(ov, at, 460, GOLD, 1.8, Z + 13)
		for k, p in { Vector2.new(0.18, 0.3), Vector2.new(0.82, 0.32), Vector2.new(0.22, 0.74), Vector2.new(0.8, 0.72) } do
			task.delay(0.2 + k * 0.22, function()
				if ov.Parent then
					Effects.guiBurst(ov, UDim2.fromOffset(p.X * W, p.Y * H), 200, CONFETTI[k + 1], 1, Z + 13)
				end
			end)
		end
		confetti(centre, 90, 900, Z + 15, ov)
		task.delay(0.15, function()
			if ov.Parent then
				confetti(nil, 140, 0, Z + 15, ov)
			end
		end)
		cue("burst", 5)
		shake(12, 0.7)
		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			if closeMax == close then
				closeMax = nil
			end
			stopRays(0.25)
			stopRays2(0.25)
			if spinConn then
				spinConn:Disconnect()
			end
			tween(ov, 0.25, { BackgroundTransparency = 1 })
			for _, d in ov:GetDescendants() do
				if d:IsA("TextLabel") then
					fadeOut(d, 0.2)
				end
			end
			tween(holderScale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			task.delay(0.3, function()
				ov:Destroy()
			end)
		end
		closeMax = close
		ov.Activated:Connect(close)
		task.delay(4.5, close)
	end

	-- the big moment over the preview (or `at`): burst, confetti, shake, "+N LEVELS!", NEW LOOK, the sting
	local function slam(at: Vector2, levels: number, power: number, newLook: string?)
		Effects.guiBurst(panel, UDim2.fromOffset(at.X, at.Y), math.floor(230 + power * 170), GOLD, 0.8 + power * 0.7, Z)
		confetti(at, math.floor(30 + power * 70), 420 + power * 300, Z + 2)
		shake(3 + power * 7, 0.3 + power * 0.3)
		local msg = if levels == 1 then "LEVEL UP!" else string.format("+%d LEVELS!", levels)
		local size = math.floor(36 + power * 22)
		local l = floatWords(panel, msg, GOLD, Vector2.new(clampX(at.X, msg, size, ctx.width), at.Y - 40), size, 56, 1.6, Z + 4)
		if power >= 0.6 then
			rainbow(l)
		end
		if newLook then
			local look = "NEW LOOK: " .. string.upper(newLook) .. "!"
			floatWords(panel, look, SKY, Vector2.new(clampX(at.X, look, 26, ctx.width), at.Y + 4), 26, 40, 1.8, Z + 4)
		end
		cue("burst", if power >= 0.6 or newLook then 5 else 2)
	end

	-- one office went from level `from` to `to` (the UPGRADE / MAX buttons)
	local function one(i: number, from: number, to: number, newLook: string?)
		local gained = to - from
		if gained <= 0 then
			return
		end
		local maxed = to >= Config.Lawyer.MaxLevel
		popCard(i, gained, maxed)
		local after = 0.4
		if i == ctx.selected() and ctx.office(i).lawyerId then
			local at = panelPoint(ctx.preview)
			if gained == 1 and not newLook then
				hop(1, 1, 0.65, 0.07)
				task.delay(0.75, sunburst(ctx.preview, UDim2.fromScale(0.5, 0.55), 300, GOLD, 0.4, 1))
				Effects.guiBurst(panel, UDim2.fromOffset(at.X, at.Y), 170, GOLD, 0.6, Z)
				floatWords(panel, "LEVEL UP!", GREEN, Vector2.new(at.X, at.Y - 36), 34, 44, 1, Z + 4)
				tagPop()
			else
				local power = powerOf(gained)
				if newLook then
					power = math.max(power, 0.5)
				end
				local roll = 0.45 + power * 0.85
				hop(2 + math.floor(power * 3 + 0.5), 1 + math.floor(power * 2 + 0.5), roll + 0.45, 0.08 + power * 0.04)
				local stop = sunburst(ctx.preview, UDim2.fromScale(0.5, 0.55), 320 + power * 140, GOLD, 0.32 - power * 0.12, 1)
				countUp(i, from, to, roll, at)
				task.delay(roll, function()
					slam(at, gained, power, newLook)
					tagPop()
					task.delay(0.7, stop)
				end)
				after = roll + 0.6
			end
		end
		if maxed then
			task.delay(after, maxLevel, i)
		end
	end

	-- UPGRADE ALL: `before` = every office's level before it; the mirrored levels may land a moment after the answer
	local function all(before: { [number]: number }, newLook: string?)
		local function gains(): ({ [number]: number }, number, number?)
			local g: { [number]: number } = {}
			local total, firstMax = 0, nil
			for i = 1, ctx.deskCount() do
				local now = ctx.office(i).level
				local was = before[i] or now
				if now > was then
					g[i] = now - was
					total += now - was
					if now >= Config.Lawyer.MaxLevel and not firstMax then
						firstMax = i
					end
				end
			end
			return g, total, firstMax
		end
		local deadline = os.clock() + 1
		local g, total, firstMax = gains()
		while total == 0 and os.clock() < deadline do
			task.wait(0.05)
			g, total, firstMax = gains()
		end
		if total == 0 then
			return
		end
		task.wait(0.08) -- (the rest of the offices' levels arrive with it)
		g, total, firstMax = gains()
		local k = 0
		for i = 1, ctx.deskCount() do
			if g[i] then
				task.delay(k * 0.08, popCard, i, g[i], ctx.office(i).level >= Config.Lawyer.MaxLevel)
				k += 1
			end
		end
		local power = powerOf(total)
		if newLook then
			power = math.max(power, 0.5)
		end
		local roll = math.max(0.45 + power * 0.85, k * 0.08)
		local sel = ctx.selected()
		if g[sel] and ctx.office(sel).lawyerId then
			local to = ctx.office(sel).level
			hop(2 + math.floor(power * 3 + 0.5), 1 + math.floor(power * 2 + 0.5), roll + 0.45, 0.08 + power * 0.04)
			task.delay(roll + 0.7, sunburst(ctx.preview, UDim2.fromScale(0.5, 0.55), 320 + power * 140, GOLD, 0.32 - power * 0.12, 1))
			countUp(sel, to - g[sel], to, roll, panelPoint(ctx.preview))
		else
			for b = 1, math.clamp(total, 1, 10) do
				task.delay(roll * (b - 0.5) / math.clamp(total, 1, 10), cue, "beat", math.min(b, 8))
			end
		end
		-- the summary over the office row
		task.delay(roll, slam, panelPoint(ctx.slotBar), total, power, newLook)
		if firstMax then
			task.delay(roll + 0.7, maxLevel, firstMax)
		end
	end

	return {
		one = one,
		all = all,
		close = function()
			if closeMax then
				closeMax()
			end
		end,
	}
end

return UpgradeFx
