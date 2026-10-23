--!strict
-- Skin (ReplicatedStorage.Shared.Skin): the game's UI design system, rebuilt 2026-10-10 after the user's reference
-- recording (a polished egg-simulator Shop + Pet Index). The look, element by element:
--   * WINDOW: dark navy body with a faint studded texture, thick ink outline, small corner radius (10).
--   * HEADER: a bright colour strip per screen (Shop = green, Lawyers = sky, Eggs = gold ...) with a top-lit
--     gradient, studs and two glossy diagonal shine bands; a big white Fredoka title with a heavy ink stroke on the
--     left; a red square X tile on the right.
--   * SECTION: "-- PASSES --" in the section's colour with an ink stroke, centred.
--   * CARD: a vivid gradient tile with a soft white glow + sunburst behind the picture, studs, an inner light bevel
--     and the ink outline; the item name sits over the bottom of the picture; a chunky price button underneath.
--   * BUTTON: chunky colour block (gradient + top gloss + dark lip + ink outline), squish on press, grow on hover.
--   * RIBBON: tilted gold tag ("BEST VALUE!") pinned to a card corner.
--   * SIDE TABS: big icon + stroked label, no box, beside the window (jump to a section).
-- Typography: Fredoka One for titles / labels, Luckiest Guy for prices and numbers, Builder Sans Bold for
-- descriptions. White text always gets an ink stroke (2-5 px by size) so it reads on any colour.
-- Build new screens with Skin.window / section / grid / card / button / ribbon / sideTab. (UIKit still auto-skins
-- the older screens until each one is rebuilt with this.)
-- v2 (UI overhaul part 2, 2026-10-18, docs/UI_OVERHAUL.md): hudTile, toast, counter, banner, prompt; the world
-- blurs while any Skin.window is open; ribbons are red by default. Motion numbers for all of them: Skin.Motion.
-- v3 (2026-10-23, crnuch's reference video, docs/UI_STYLE_V3.md): ONE font family everywhere, Gotham Black (titles,
-- buttons, numbers) + Gotham Bold (small print); repeating diagonal stripe bands on headers, cards and buttons
-- (Skin.stripes); a plain charcoal body; brighter cards with visible sunbursts; coloured side tabs with a selected
-- state; red "+66% more" value tags (Skin.tag); reward tiles (Skin.tile); a glint sweep on buy buttons
-- (Skin.glint); button states (Button.setState: default / disabled / pending).

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Skin = {}

-- window open / close sounds (Shared.Sfx), looked up lazily so Skin never waits on it
local function playSfx(name: string)
	local m = script.Parent:FindFirstChild("Sfx")
	if m and m:IsA("ModuleScript") then
		(require(m) :: any).play(name)
	end
end

------------------------------------------------------------------ tokens
-- v3: the reference's UI is one geometric family with flat ends: Gotham Black for everything big, Gotham Bold for
-- small print (crnuch's call 2026-10-23: no more Fredoka / Luckiest Guy / Builder Sans anywhere)
Skin.Fonts = {
	Title = Font.fromEnum(Enum.Font.GothamBlack),
	Number = Font.fromEnum(Enum.Font.GothamBlack),
	Body = Font.fromEnum(Enum.Font.GothamBold),
	Heavy = Font.fromEnum(Enum.Font.GothamBlack),
}
Skin.Assets = {
	Studs = "rbxassetid://114488299634202", -- tools/ui_textures.py
	Rays = "rbxassetid://89557955610458", -- white sunburst
	Glow = "rbxassetid://75348129891036", -- soft radial glow
}
Skin.ROBUX = utf8.char(0xE002) -- the Robux glyph in Roblox's fonts

local function hex(h: string): Color3
	return Color3.fromHex(h)
end
Skin.Ink = hex("15131C")
Skin.White = Color3.new(1, 1, 1)
Skin.Panel = hex("34353D") -- v3: plain charcoal (the reference's body), was navy 2C2E3E
Skin.PanelDeep = hex("25262C")
Skin.TextSoft = hex("C9CCE0")
Skin.Lime = hex("7DFF3C") -- highlighted words, progress fills, the "value" in an info line

-- each colour: base (the fill), light (top of the gradient / glow), dark (bottom, lips, borders)
export type Swatch = { base: Color3, light: Color3, dark: Color3 }
Skin.Palette = {
	Green = { base = hex("4FCB2E"), light = hex("8DEB5E"), dark = hex("2A8A17") },
	Sky = { base = hex("4FB6EE"), light = hex("9EDCFF"), dark = hex("2177B5") },
	Purple = { base = hex("9B4DF0"), light = hex("D29BFF"), dark = hex("5E21A8") },
	Pink = { base = hex("EE5AC0"), light = hex("FF9EDF"), dark = hex("A4247F") },
	Gold = { base = hex("FFBE1F"), light = hex("FFE27A"), dark = hex("C47F00") },
	Orange = { base = hex("FF8A1F"), light = hex("FFC27A"), dark = hex("B85300") },
	Red = { base = hex("E53030"), light = hex("FF7A6E"), dark = hex("9A1515") },
	Grey = { base = hex("8C90A6"), light = hex("C4C7D6"), dark = hex("575A6E") },
	Navy = { base = hex("3A3D55"), light = hex("5A5E80"), dark = hex("23253A") },
} :: { [string]: Swatch }

function Skin.swatch(c: string | Color3 | Swatch): Swatch
	if type(c) == "string" then
		return Skin.Palette[c] or Skin.Palette.Grey
	elseif typeof(c) == "Color3" then
		local h, s, v = c:ToHSV()
		return {
			base = c,
			light = Color3.fromHSV(h, s * 0.55, math.min(1, v * 1.12 + 0.12)),
			dark = Color3.fromHSV(h, math.min(1, s * 1.1), v * 0.6),
		}
	end
	return c :: Swatch
end

------------------------------------------------------------------ primitives
function Skin.make(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	for k, v in props or {} do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end
local make = Skin.make

function Skin.corner(px: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, px) })
end
function Skin.stroke(px: number, color: Color3?, transparency: number?): UIStroke
	return make("UIStroke", {
		Thickness = px, Color = color or Skin.Ink, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round,
	})
end
local corner, stroke = Skin.corner, Skin.stroke

-- v2 motion, one table (the Figma components' motion specs): hover / press scales and tween times
Skin.Motion = {
	Hover = 1.08, Press = 0.9, -- HUD tiles
	PopFrom = 0.4, PopTime = 0.38, -- Skin.pop, counter pop
	ToastIn = 0.32, ToastOut = 0.2, ToastDrop = 26, -- slide-down distance (px)
	BannerIn = 0.55, BannerOut = 0.35, BannerHold = 2.6,
	Blur = 14, BlurTime = 0.25, -- world blur behind an open window
	PromptIn = 0.22,
}

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
Skin.tween = tween

-- a TextScaled label with a size cap and (by default) the ink outline that every white label gets
function Skin.text(props: { [string]: any }, maxSize: number, strokePx: number?): TextLabel
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or Skin.Fonts.Title
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Skin.White
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 8 }) })
	local px = strokePx or math.clamp(math.floor(maxSize / 11), 1, 5)
	if px > 0 then
		make("UIStroke", { Thickness = px, Color = Skin.Ink, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	end
	return l
end
local text = Skin.text

-- the studded texture over a surface (under its children)
function Skin.studs(parent: GuiObject, transparency: number, tint: Color3?, tile: number?)
	local c = parent:FindFirstChildOfClass("UICorner")
	make("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Skin.Assets.Studs,
		ImageTransparency = transparency, ImageColor3 = tint or Skin.White, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(tile or 30, tile or 30), ZIndex = parent.ZIndex, Interactable = false, Parent = parent,
	}, if c then { corner(c.CornerRadius.Offset) } else nil)
end

-- soft white highlight across the top half (the "lit from above" look)
function Skin.gloss(parent: GuiObject, strength: number?)
	local c = parent:FindFirstChildOfClass("UICorner")
	make("Frame", {
		Name = "Gloss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(1, -6, 0.5, -1),
		BackgroundColor3 = Skin.White, BorderSizePixel = 0, ZIndex = parent.ZIndex, Interactable = false, Parent = parent,
	}, {
		make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - (strength or 0.38)), NumberSequenceKeypoint.new(1, 1),
		}) }),
		if c then corner(math.max(0, c.CornerRadius.Offset - 2)) else nil :: any,
	})
end

-- two glossy diagonal shine bands leaning like "/" (the reference's header highlights)
function Skin.shineBands(parent: GuiObject, transparency: number?)
	local t = transparency or 0.72
	make("Frame", {
		Name = "ShineBands", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Skin.White, BorderSizePixel = 0,
		ZIndex = parent.ZIndex, Interactable = false, Parent = parent,
	}, {
		make("UIGradient", { Rotation = 35, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.54, 1), NumberSequenceKeypoint.new(0.545, t),
			NumberSequenceKeypoint.new(0.585, t), NumberSequenceKeypoint.new(0.59, 1), NumberSequenceKeypoint.new(0.61, 1),
			NumberSequenceKeypoint.new(0.615, t + 0.06), NumberSequenceKeypoint.new(0.635, t + 0.06), NumberSequenceKeypoint.new(0.64, 1),
			NumberSequenceKeypoint.new(1, 1),
		}) }),
	})
end

-- v3: the reference's repeating diagonal light bands ("/" leaning), evenly spaced across the whole surface. `bands`
-- 2-4 (a NumberSequence takes 20 keypoints); `width` = each band's share of the width.
function Skin.stripes(parent: GuiObject, transparency: number?, bands: number?, width: number?): Frame
	local t = transparency or 0.8
	local n = math.clamp(bands or 4, 1, 4)
	local w = width or 0.07
	local keys = { NumberSequenceKeypoint.new(0, 1) }
	for i = 0, n - 1 do
		local c = (i + 0.5) / n
		table.insert(keys, NumberSequenceKeypoint.new(c - w / 2 - 0.004, 1))
		table.insert(keys, NumberSequenceKeypoint.new(c - w / 2, t))
		table.insert(keys, NumberSequenceKeypoint.new(c + w / 2, t))
		table.insert(keys, NumberSequenceKeypoint.new(c + w / 2 + 0.004, 1))
	end
	table.insert(keys, NumberSequenceKeypoint.new(1, 1))
	local c = parent:FindFirstChildOfClass("UICorner")
	return make("Frame", {
		Name = "Stripes", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Skin.White, BorderSizePixel = 0,
		ZIndex = parent.ZIndex, Interactable = false, Parent = parent,
	}, {
		make("UIGradient", { Rotation = 30, Transparency = NumberSequence.new(keys) }),
		if c then corner(c.CornerRadius.Offset) else nil :: any,
	})
end

-- v3: a bright glint that sweeps across a button now and then (the reference's "glints on the buttons"). Only for
-- the one action that matters on a screen (buy / claim), never on every button. Stops when the button goes away.
function Skin.glint(gui: GuiObject, period: number?)
	local c = gui:FindFirstChildOfClass("UICorner")
	local holder = make("Frame", {
		Name = "Glint", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = gui.ZIndex + 1, Interactable = false, Parent = gui,
	}, { if c then corner(c.CornerRadius.Offset) else nil :: any })
	-- the reference's glint is a "//" pair: a wide bar and a thin one right behind it
	local bar = make("Frame", {
		Name = "Bar", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.3, 0.5), Size = UDim2.new(0, 46, 2.6, 0),
		Rotation = 24, BackgroundTransparency = 1, ZIndex = gui.ZIndex + 1, Parent = holder,
	})
	for _, b in { { 0, 22, 0.25 }, { 30, 8, 0.4 } } do
		make("Frame", {
			Position = UDim2.new(0, b[1], 0, 0), Size = UDim2.new(0, b[2], 1, 0), BackgroundColor3 = Skin.White,
			BackgroundTransparency = b[3], BorderSizePixel = 0, ZIndex = gui.ZIndex + 1, Parent = bar,
		})
	end
	task.spawn(function()
		task.wait(math.random() * 1.5)
		while holder.Parent do
			local st = gui:GetAttribute("SkinState")
			if gui.Visible and (st == nil or st == "default") and gui:FindFirstAncestorWhichIsA("LayerCollector") then
				bar.Position = UDim2.fromScale(-0.3, 0.5)
				tween(bar, 0.55, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
			task.wait(period or 2.6)
		end
	end)
	return holder
end

------------------------------------------------------------------ motion
-- grow on hover, squish on press, spring back on release. Returns the UIScale it drives.
-- Makes a window panel catch taps on its empty space. A Frame doesn't stop a click, even with Active = true: the
-- click still reaches the full-screen click-to-close backdrop behind it, so a tap between two buttons closed the
-- window (found 2026-10-11). A transparent full-size button under the panel's content catches those taps instead.
function Skin.blockClicks(panel: GuiObject): TextButton
	return make("TextButton", {
		Name = "ClickBlocker", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, Selectable = false, ZIndex = 0, Parent = panel,
	})
end

-- v3: a click sends a white ring out from where you pressed, plus a few sparkle dots (the reference's buy bars)
function Skin.ripple(button: GuiObject, at: Vector2?)
	local abs = button.AbsoluteSize
	local p = if at then at - button.AbsolutePosition else abs / 2
	-- where you pressed, as a fraction of the button (works under any UIScale)
	local fx, fy = math.clamp(p.X / math.max(abs.X, 1), 0, 1), math.clamp(p.Y / math.max(abs.Y, 1), 0, 1)
	local z = button.ZIndex + 6
	local ring = make("Frame", {
		Name = "Ripple", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(fx, fy),
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = z, Interactable = false, Parent = button,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 3, Color = Skin.White, Transparency = 0.1 }) })
	local st = ring:FindFirstChildOfClass("UIStroke") :: UIStroke
	tween(ring, 0.42, { Size = UDim2.fromOffset(70, 70) }, Enum.EasingStyle.Quad)
	tween(st, 0.42, { Transparency = 1 }, Enum.EasingStyle.Quad)
	for i = 1, 3 do
		local dot = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(fx, fy), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Skin.White, BorderSizePixel = 0, ZIndex = z, Interactable = false, Parent = button,
		}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local a = math.rad(i * 120 + math.random(-30, 30))
		tween(dot, 0.4, {
			Position = UDim2.new(fx, math.cos(a) * 34, fy, math.sin(a) * 26), BackgroundTransparency = 1,
			Size = UDim2.fromOffset(2, 2),
		})
		task.delay(0.42, dot.Destroy, dot)
	end
	task.delay(0.44, ring.Destroy, ring)
end

-- hover: grow (crnuch's call 2026-10-23: no gold hover ring); press: squish + ripple; disabled: a "no" wiggle
function Skin.pressable(button: GuiButton, hoverScale: number?): UIScale
	local scale = button:FindFirstChild("PressScale") :: UIScale?
	if not scale then
		scale = make("UIScale", { Name = "PressScale", Parent = button })
	end
	local s = scale :: UIScale
	local grow = hoverScale or 1.06
	local over = false
	local function disabled(): boolean
		local st = button:GetAttribute("SkinState")
		return st == "disabled" or st == "pending" or st == "owned"
	end
	button.MouseEnter:Connect(function()
		over = true
		if disabled() then
			return
		end
		tween(s, 0.18, { Scale = grow }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		over = false
		tween(s, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	button.MouseButton1Down:Connect(function()
		if disabled() then
			return
		end
		tween(s, 0.06, { Scale = 0.9 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(s, 0.28, { Scale = if over and not disabled() then grow else 1 }, Enum.EasingStyle.Back)
	end)
	button.Activated:Connect(function(input: InputObject?)
		if disabled() then
			-- a "no" wiggle instead of the squish
			for _, r in { -5, 5, -3, 0 } do
				tween(button, 0.05, { Rotation = r })
				task.wait(0.05)
			end
			return
		end
		local at = if input and input.Position then Vector2.new(input.Position.X, input.Position.Y) else nil
		if button:GetAttribute("NoRipple") ~= true then
			Skin.ripple(button, at)
		end
		-- touch / gamepad: no hover events, so give the squish here too
		if not over then
			s.Scale = 0.9
			tween(s, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
	return s
end

-- v3 idle life: hero pictures BREATHE (a slow tilt + a small swell) and sunbursts TURN, like the reference's shop
-- icons. One RenderStepped loop for everything; things on a hidden screen are skipped.
type Living = { gui: GuiObject, kind: string, amp: number, rate: number, phase: number, scale: UIScale?, base: number }
local living: { Living } = {}
local livingConn: RBXScriptConnection? = nil
local function onScreen(g: GuiObject): boolean
	local lc = g:FindFirstAncestorWhichIsA("LayerCollector")
	return g.Visible and lc ~= nil and (not lc:IsA("ScreenGui") or (lc :: ScreenGui).Enabled)
end
local function startLiving()
	if livingConn then
		return
	end
	livingConn = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for i = #living, 1, -1 do
			local l = living[i]
			if not l.gui.Parent then
				table.remove(living, i)
			elseif onScreen(l.gui) then
				if l.kind == "spin" then
					l.gui.Rotation = (t * l.rate + l.phase) % 360
				else
					local w = t * l.rate * math.pi * 2 + l.phase
					l.gui.Rotation = l.base + math.sin(w) * l.amp
					if l.scale then
						l.scale.Scale = 1 + 0.045 * math.sin(w * 2)
					end
				end
			end
		end
	end)
end
-- amp = tilt degrees (5), rate = cycles per second (0.45)
function Skin.breathe(gui: GuiObject, amp: number?, rate: number?)
	local sc = gui:FindFirstChild("BreatheScale") :: UIScale?
	if not sc then
		sc = make("UIScale", { Name = "BreatheScale", Parent = gui })
	end
	table.insert(living, { gui = gui, kind = "breathe", amp = amp or 5, rate = rate or 0.45, phase = math.random() * 6,
		scale = sc, base = gui.Rotation })
	startLiving()
end
-- degPerSec (12)
function Skin.spin(gui: GuiObject, degPerSec: number?)
	table.insert(living, { gui = gui, kind = "spin", amp = 0, rate = degPerSec or 12, phase = math.random() * 360, base = 0 })
	startLiving()
end

-- pop something into view (rewards, new cards)
function Skin.pop(gui: GuiObject, from: number?)
	local s = gui:FindFirstChild("PopScale") :: UIScale?
	if not s then
		s = make("UIScale", { Name = "PopScale", Parent = gui })
	end
	(s :: UIScale).Scale = from or 0.4
	tween(s :: UIScale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- count a label up/down to a number (currency); fmt turns the number into text
function Skin.countTo(label: TextLabel, from: number, to: number, fmt: (number) -> string, duration: number?)
	local token = (label:GetAttribute("CountToken") or 0) + 1
	label:SetAttribute("CountToken", token)
	local d = duration or 0.45
	local t0 = os.clock()
	task.spawn(function()
		while label:GetAttribute("CountToken") == token do
			local a = math.min(1, (os.clock() - t0) / d)
			local e = 1 - (1 - a) ^ 3
			label.Text = fmt(from + (to - from) * e)
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end)
end

------------------------------------------------------------------ buttons
export type Button = {
	button: TextButton,
	label: TextLabel,
	setStyle: (string | Color3 | Swatch) -> (),
	setText: (string) -> (),
	-- v3: "default" | "disabled" (greyed, no bounce, a "no" wiggle on tap; reason shows as a toast) | "pending" (dim, "...")
	-- | "owned" (gold, no bounce, no glint)
	setState: (string, string?) -> (),
}

-- a chunky button: gradient fill, gloss, dark lip, ink outline + a coloured inner border, stroked label
function Skin.button(props: { [string]: any }): Button
	local sw = Skin.swatch(props.Style or "Green")
	local btn = make("TextButton", {
		Name = props.Name or "Button", AnchorPoint = props.AnchorPoint, Position = props.Position, Size = props.Size,
		LayoutOrder = props.LayoutOrder, BackgroundColor3 = Skin.White, AutoButtonColor = false, Text = "",
		ZIndex = props.ZIndex or 2, Parent = props.Parent,
	}, { corner(props.Corner or 8), stroke(props.Outline or 3) })
	local grad = make("UIGradient", { Rotation = 90, Parent = btn })
	local inner = make("Frame", {
		Name = "Bevel", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1,
		ZIndex = btn.ZIndex, Interactable = false, Parent = btn,
	}, { corner(math.max(2, (props.Corner or 8) - 2)) })
	local innerStroke = make("UIStroke", { Thickness = 2, Transparency = 0.15, Parent = inner })
	local lip = make("Frame", {
		Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.16, 0),
		BackgroundColor3 = Skin.Ink, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = btn.ZIndex,
		Interactable = false, Parent = btn,
	}, { corner(props.Corner or 8) })
	if props.Studs ~= false then
		Skin.studs(btn, 0.88, nil, 24)
	end
	Skin.gloss(btn, 0.14) -- (user: "a little too shiny": was 0.32)
	if props.Stripes ~= false then
		Skin.stripes(btn, 0.82, 3, 0.08) -- v3: the reference's diagonal bands on every button
	end
	if props.Glint then
		Skin.glint(btn) -- v3: the screen's one big action (buy / claim)
	end
	local label = text({
		Name = "Label", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(1, -12, 0.78, 0), Text = props.Text or "", FontFace = props.Font or Skin.Fonts.Title,
		ZIndex = btn.ZIndex + 1, Parent = btn,
	}, props.TextSize or 30, props.TextStroke)
	local styleNow: Swatch = sw
	local function paint(s: Swatch)
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, s.light), ColorSequenceKeypoint.new(0.45, s.base), ColorSequenceKeypoint.new(1, s.base:Lerp(s.dark, 0.35)),
		})
		innerStroke.Color = s.dark
		lip.BackgroundColor3 = s.dark
		lip.BackgroundTransparency = 0.25
	end
	local state, reason, textNow = "default", nil :: string?, props.Text or ""
	local function setStyle(style: string | Color3 | Swatch)
		styleNow = Skin.swatch(style)
		if state == "default" then
			paint(styleNow)
		end
	end
	local function setState(st: string, why: string?)
		state, reason = st, why
		btn:SetAttribute("SkinState", st)
		if st == "disabled" then
			paint(Skin.Palette.Grey)
			label.Text = textNow
			label.TextTransparency = 0.15
		elseif st == "owned" then -- earned, not broken: gold, still, no glint
			paint(Skin.Palette.Gold)
			label.Text = textNow
			label.TextTransparency = 0
		elseif st == "pending" then
			paint(styleNow)
			label.Text = "..."
			label.TextTransparency = 0.3
		else
			paint(styleNow)
			label.Text = textNow
			label.TextTransparency = 0
		end
	end
	paint(sw)
	if props.Pressable ~= false then
		Skin.pressable(btn)
	end
	btn.Activated:Connect(function()
		if state == "disabled" and reason then
			Skin.toast({ Text = reason, Hold = 2 })
		end
	end)
	return {
		button = btn,
		label = label,
		setStyle = setStyle,
		setText = function(t: string)
			textNow = t
			if state ~= "pending" then
				label.Text = t
			end
		end,
		setState = setState,
	}
end

-- the red square close tile with a white X
function Skin.closeButton(parent: GuiObject, size: number, z: number): TextButton
	local b = Skin.button({
		Name = "Close", Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(size, size - 6), Style = "Red", Text = "X", Font = Skin.Fonts.Number, TextSize = 52,
		TextStroke = 4, Corner = 6, Outline = 4, ZIndex = z, Studs = false,
	})
	b.label.Position = UDim2.fromScale(0.5, 0.52)
	return b.button
end

------------------------------------------------------------------ window
export type Window = {
	gui: ScreenGui,
	panel: Frame,
	header: Frame,
	body: Frame,
	title: TextLabel,
	close: TextButton,
	open: () -> (),
	hide: () -> (),
	isOpen: () -> boolean,
	onClose: (() -> ()) -> (),
	sideRail: Frame,
}

-- A centred window: dim backdrop, panel (UIScale-fitted to the screen), coloured header with title + X, a body
-- frame below the header, and a side rail outside the panel's right edge for section shortcuts.
function Skin.window(opts: { [string]: any }): Window
	local size: Vector2 = opts.Size or Vector2.new(980, 600)
	local sw = Skin.swatch(opts.Color or "Green")
	local headerH = opts.HeaderHeight or 84
	local player = game:GetService("Players").LocalPlayer
	local gui = make("ScreenGui", {
		Name = opts.Name, ResetOnSpawn = false, DisplayOrder = opts.DisplayOrder or 18, Enabled = false,
		IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui"),
	})
	gui:SetAttribute("SkinBuilt", true) -- StarterPlayerScripts.UISkin (old auto-skin) must leave these screens alone
	local dim = make("TextButton", {
		Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = gui,
	})
	local scale = make("UIScale", { Scale = 1 })
	local panel = make("Frame", {
		Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = Skin.Panel, ZIndex = 1, Parent = gui,
	}, { corner(10), stroke(5), scale })
	Skin.blockClicks(panel) -- a tap on empty window space must not fall through to the dim and close it
	panel:SetAttribute("NoSkin", true) -- opt out of StarterPlayerScripts.UISkin (the old auto-skin)
	dim:SetAttribute("NoSkin", true)
	-- v3: the body is plain charcoal (the reference has no pattern there; v2's rings were busy behind the cards)
	-- inner rim (a thin lighter line inside the outline, like the reference)
	make("Frame", {
		Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = 1, Interactable = false, Parent = panel,
	}, { corner(8), make("UIStroke", { Thickness = 2, Color = hex("4B4C56"), Transparency = 0.2 }) })

	local header = make("Frame", {
		Name = "Header", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, headerH), BackgroundColor3 = Skin.White,
		ZIndex = 2, Parent = panel,
	}, {
		corner(7),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.55, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.25)),
		}) }),
		make("UIStroke", { Thickness = 3, Color = sw.dark, Transparency = 0.1 }),
	})
	Skin.studs(header, 0.8, nil, 26)
	Skin.stripes(header, 0.74, 4, 0.06) -- v3: the reference header's wide diagonal light bands
	-- ink divider under the header
	make("Frame", {
		Name = "Divider", Position = UDim2.new(0, 0, 0, headerH + 4), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Skin.Ink,
		BorderSizePixel = 0, ZIndex = 2, Parent = panel,
	})
	local iconW = 0
	if opts.Icon then
		-- v3: the icon is bigger than the header and pokes out over its top-left corner (the reference's shop bag)
		iconW = headerH + 18
		local ic = make("ImageLabel", {
			Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, -8), Size = UDim2.fromOffset(iconW, iconW),
			Rotation = -6, BackgroundTransparency = 1, Image = opts.Icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = header,
		})
		Skin.breathe(ic, 3, 0.3)
		iconW -= 8
	end
	local title = text({
		Name = "Title", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22 + iconW, 0.5, -1),
		Size = UDim2.new(0.62, 0, 0, headerH - 22), Text = opts.Title or "", TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3, Parent = header,
	}, 54, 5)
	local close = Skin.closeButton(header, headerH - 14, 4)

	local body = make("Frame", {
		Name = "Body", Position = UDim2.fromOffset(0, headerH + 8), Size = UDim2.new(1, 0, 1, -(headerH + 8)),
		BackgroundTransparency = 1, ZIndex = 2, Parent = panel,
	})
	-- shortcut dock beside the window: its own dark studded panel so whatever HUD sits behind it never shows through
	-- v3: the tabs float beside the window as their own coloured blocks (no dock panel), like the reference's
	-- PACKS / PASSES / UPGRADES / CURRENCY
	local sideRail = make("Frame", {
		Name = "SideRail", AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 10, 0, headerH + 14),
		Size = UDim2.fromOffset(176, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Visible = false, ZIndex = 1, Parent = panel,
	})
	make("Frame", {
		Name = "List", Size = UDim2.fromOffset(176, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		ZIndex = 2, Parent = sideRail,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }),
	})

	local function fit(): number
		local cam = workspace.CurrentCamera
		if not cam then
			return 1
		end
		local railRoom = if sideRail.Visible then 300 else 60
		return math.clamp(math.min(cam.ViewportSize.X / (size.X + railRoom), cam.ViewportSize.Y / (size.Y + 90)), 0.38, 1)
	end
	local closeHandlers: { () -> () } = {}
	local busy = false
	local function open()
		if gui.Enabled then
			return
		end
		gui.Enabled = true
		playSfx("open")
		Skin.blurFor(gui)
		dim.BackgroundTransparency = 1
		tween(dim, 0.2, { BackgroundTransparency = 0.35 })
		scale.Scale = 0.7 * fit()
		panel.Rotation = -2
		tween(scale, 0.34, { Scale = fit() }, Enum.EasingStyle.Back)
		tween(panel, 0.34, { Rotation = 0 }, Enum.EasingStyle.Back)
	end
	local function hide()
		if not gui.Enabled or busy then
			return
		end
		busy = true
		playSfx("close")
		tween(dim, 0.14, { BackgroundTransparency = 1 })
		local t = tween(scale, 0.14, { Scale = 0.75 * fit() }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Wait()
		gui.Enabled = false
		busy = false
		for _, h in closeHandlers do
			task.spawn(h)
		end
	end
	close.Activated:Connect(hide)
	dim.Activated:Connect(hide) -- tap outside the window closes it
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if gui.Enabled then
				scale.Scale = fit()
			end
		end)
	end
	return {
		gui = gui, panel = panel, header = header, body = body, title = title, close = close, sideRail = sideRail,
		open = open, hide = hide,
		isOpen = function()
			return gui.Enabled
		end,
		onClose = function(fn)
			table.insert(closeHandlers, fn)
		end,
	}
end

------------------------------------------------------------------ content blocks
-- a vertical scrolling body area (sections stacked, auto canvas)
function Skin.scroller(parent: GuiObject, props: { [string]: any }?): ScrollingFrame
	local p = props or {}
	return make("ScrollingFrame", {
		Name = p.Name or "Scroller", Position = p.Position or UDim2.fromOffset(14, 6), Size = p.Size or UDim2.new(1, -28, 1, -16),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, ScrollBarImageColor3 = hex("8B8FAE"),
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, ZIndex = parent.ZIndex, Parent = parent,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 14), PaddingRight = UDim.new(0, 6) }),
	})
end

-- "~Cash~" section header (v3: the reference's small white title between the card groups; `color` tints its stroke)
function Skin.section(parent: GuiObject, title: string, color: string | Color3 | Swatch, order: number): TextLabel
	local sw = Skin.swatch(color)
	local l = text({
		Name = "Section_" .. title, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = order,
		Text = "~" .. title .. "~", TextColor3 = Skin.White, FontFace = Skin.Fonts.Title,
		ZIndex = parent.ZIndex + 1, Parent = parent,
	}, 34, 4)
	local st = l:FindFirstChildOfClass("UIStroke")
	if st then
		st.Color = sw.dark:Lerp(Skin.Ink, 0.5)
	end
	return l
end

-- a grid row of cards (wraps, grows with content)
function Skin.grid(parent: GuiObject, cell: Vector2, order: number, gap: number?): Frame
	return make("Frame", {
		Name = "Grid", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = order, ZIndex = parent.ZIndex, Parent = parent,
	}, {
		make("UIGridLayout", {
			CellSize = UDim2.fromOffset(cell.X, cell.Y), CellPadding = UDim2.fromOffset(gap or 14, gap or 14),
			HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

-- a colourful card: gradient + glow + sunburst + studs + bevel + ink outline. Children go on top (ZIndex z+2).
function Skin.card(parent: GuiObject, opts: { [string]: any }): Frame
	local sw = Skin.swatch(opts.Color or "Purple")
	local z = opts.ZIndex or (parent.ZIndex + 1)
	local card = make("Frame", {
		Name = opts.Name or "Card", Size = opts.Size or UDim2.fromScale(1, 1), Position = opts.Position,
		LayoutOrder = opts.LayoutOrder, BackgroundColor3 = Skin.White, ClipsDescendants = true, ZIndex = z, Parent = parent,
	}, {
		corner(8), stroke(4),
		-- v3: brighter, lit from the top-left like the reference's cards (was dark at the top and bottom)
		make("UIGradient", { Rotation = 60, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, sw.light:Lerp(sw.base, 0.3)), ColorSequenceKeypoint.new(0.5, sw.base),
			ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.3)),
		}) }),
	})
	local glowAt = opts.GlowAt or Vector2.new(0.5, 0.38)
	local rays = make("ImageLabel", {
		Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(glowAt.X, glowAt.Y),
		Size = UDim2.fromScale(1.6, 1.6), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1,
		Image = Skin.Assets.Rays, ImageColor3 = Skin.White, ImageTransparency = 0.72, ZIndex = z, Interactable = false, Parent = card,
	})
	if opts.Spin ~= false then
		Skin.spin(rays, 10) -- v3: the sunburst turns slowly
	end
	make("ImageLabel", {
		Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(glowAt.X, glowAt.Y),
		Size = UDim2.fromScale(1.05, 1.05), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1,
		Image = Skin.Assets.Glow, ImageColor3 = Skin.White, ImageTransparency = 0.6, ZIndex = z, Interactable = false, Parent = card,
	})
	Skin.studs(card, 0.88, nil, 26)
	Skin.stripes(card, 0.86, 3, 0.1) -- v3: the reference's soft diagonal light bands across every card
	if opts.Twinkle ~= false then
		Skin.sparkle(card, UDim2.fromScale(0.88, 0.14), 16, z + 1, math.random() * 2)
		Skin.sparkle(card, UDim2.fromScale(0.1, 0.8), 12, z + 1, 1 + math.random() * 2)
	end
	make("Frame", {
		Name = "Bevel", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = z + 1, Interactable = false, Parent = card,
	}, { corner(6), make("UIStroke", { Thickness = 2, Color = sw.light, Transparency = 0.35 }) })
	return card
end

-- a tilted tag pinned to a corner ("BEST VALUE!", "NEW!", "OWNED")
function Skin.ribbon(parent: GuiObject, label: string, color: string | Color3 | Swatch?, z: number?): Frame
	local sw = Skin.swatch(color or "Red") -- v2: red is the default (the reference's HOT / BEST VALUE tags)
	local r = make("Frame", {
		Name = "Ribbon", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 8, 0, -6), Size = UDim2.fromOffset(150, 34),
		Rotation = 10, BackgroundColor3 = Skin.White, ZIndex = z or 20, Parent = parent,
	}, {
		corner(5), stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(sw.light, sw.base) }),
	})
	text({ Size = UDim2.new(1, -10, 1, -4), Position = UDim2.fromOffset(5, 2), Text = label, FontFace = Skin.Fonts.Number,
		ZIndex = (z or 20) + 1, Parent = r }, 22, 2)
	return r
end

-- v3: a red value tag straddling a card's top edge ("+66% more", "BEST VALUE!") - tilted a little, white text
function Skin.tag(parent: GuiObject, label: string, opts: { [string]: any }?): Frame
	local o = opts or {}
	local sw = Skin.swatch(o.Color or "Red")
	local z = o.ZIndex or 20
	local t = make("Frame", {
		Name = "Tag", AnchorPoint = o.AnchorPoint or Vector2.new(0.5, 0.5), Position = o.Position or UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(o.Width or 150, o.Height or 32), AutomaticSize = Enum.AutomaticSize.X, Rotation = o.Rotation or -4,
		BackgroundColor3 = Skin.White, ZIndex = z, Parent = parent,
	}, {
		corner(6), stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(sw.light:Lerp(sw.base, 0.4), sw.base) }),
		make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	text({ Size = UDim2.fromScale(1, 1), Text = label, ZIndex = z + 1, Parent = t }, o.TextSize or 22, 3)
	return t
end

-- v3: a square reward tile (what a pack gives): a light tinted square, its picture, and an amount on its foot
-- ("x10k", "+1"). opts: Color, Image, Amount, Size (px), LayoutOrder, ZIndex.
function Skin.tile(parent: GuiObject, opts: { [string]: any }): Frame
	local sw = Skin.swatch(opts.Color or "Gold")
	local px = opts.Size or 96
	local z = opts.ZIndex or (parent.ZIndex + 1)
	local f = make("Frame", {
		Name = opts.Name or "Tile", Size = UDim2.fromOffset(px, px), LayoutOrder = opts.LayoutOrder,
		BackgroundColor3 = Skin.White, ZIndex = z, Parent = parent,
	}, {
		corner(6), stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(sw.light, sw.base) }),
	})
	Skin.stripes(f, 0.84, 2, 0.12)
	local pic = make("ImageLabel", {
		Name = "Picture", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.78, 0.78),
		BackgroundTransparency = 1, Image = opts.Image or "", ScaleType = Enum.ScaleType.Fit, ZIndex = z + 1, Parent = f,
	})
	if opts.Breathe ~= false then
		Skin.breathe(pic, 4, 0.4)
	end
	text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, -6, 0.3, 0),
		Text = opts.Amount or "", ZIndex = z + 2, Parent = f }, math.floor(px * 0.24), 3)
	return f
end

-- a shortcut tab beside the window. v3: its own coloured block (gradient, stripes, ink outline) with a small icon and
-- a stroked label - the reference's PACKS / PASSES / UPGRADES. Skin.selectTab lights one and dims the rest.
function Skin.sideTab(rail: GuiObject, opts: { [string]: any }): TextButton
	rail.Visible = true
	local sw = Skin.swatch(opts.Color or "Orange")
	local b = make("TextButton", {
		Name = "Tab_" .. (opts.Label or ""), Size = UDim2.fromOffset(168, 62), BackgroundColor3 = Skin.White, Text = "",
		AutoButtonColor = false, LayoutOrder = opts.LayoutOrder, ZIndex = 3, Parent = rail:FindFirstChild("List") or rail,
	}, {
		corner(8), stroke(4),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.5, sw.base), ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.35)),
		}) }),
	})
	Skin.stripes(b, 0.78, 3, 0.09)
	make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -6, 0.5, -2), Size = UDim2.fromOffset(60, 60),
		BackgroundTransparency = 1, Image = opts.Icon or "", ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = b,
	})
	text({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 54, 0.5, 0), Size = UDim2.new(1, -60, 0, 34),
		Text = string.upper(opts.Label or ""), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = b }, 24, 3)
	make("Frame", { -- dims the tab when another one is selected
		Name = "Dimmer", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Skin.Ink, BackgroundTransparency = 1,
		ZIndex = 6, Interactable = false, Parent = b,
	}, { corner(8) })
	Skin.pressable(b, 1.06)
	return b
end
function Skin.selectTab(rail: GuiObject, selected: GuiObject?)
	for _, b in (rail:FindFirstChild("List") or rail):GetChildren() do
		local d = b:FindFirstChild("Dimmer")
		if d and d:IsA("Frame") then
			local on = b == selected
			tween(d, 0.15, { BackgroundTransparency = if on then 1 else 0.45 })
		end
	end
end

------------------------------------------------------------------ v2: world blur behind open windows
-- One BlurEffect in (local) Lighting, faded in while any Skin.window is open. Each window's ScreenGui is watched,
-- so a script that closes a window by setting Enabled directly still lets the blur go.
local blurGuis: { [ScreenGui]: boolean } = {}
local blurEffect: BlurEffect? = nil
local function refreshBlur()
	local any = false
	for g in blurGuis do
		if g.Parent and g.Enabled then
			any = true
			break
		end
	end
	if not blurEffect or not blurEffect.Parent then
		blurEffect = make("BlurEffect", { Name = "SkinWindowBlur", Size = 0, Enabled = true, Parent = Lighting })
	end
	tween(blurEffect :: BlurEffect, Skin.Motion.BlurTime, { Size = if any then Skin.Motion.Blur else 0 })
end
function Skin.blurFor(gui: ScreenGui)
	if not blurGuis[gui] then
		blurGuis[gui] = true
		gui:GetPropertyChangedSignal("Enabled"):Connect(refreshBlur)
		gui.AncestryChanged:Connect(function()
			if not gui.Parent then
				blurGuis[gui] = nil
				refreshBlur()
			end
		end)
	end
	refreshBlur()
end

------------------------------------------------------------------ v2: shared bits
-- an icon by HudMenu.Icons key ("Money", "Eggs" ...) or an image id; HudMenu is looked up lazily (it requires Skin)
function Skin.icon(name: string?): string
	if not name or name == "" then
		return ""
	end
	if string.find(name, "://", 1, true) then
		return name
	end
	local m = script.Parent:FindFirstChild("HudMenu")
	if m and m:IsA("ModuleScript") then
		local ok, hm = pcall(require, m)
		if ok and type(hm) == "table" and (hm :: any).Icons and (hm :: any).Icons[name] then
			return (hm :: any).Icons[name]
		end
	end
	return name
end

-- RichText: the phrase (or, with none, every ALL-CAPS word of 2+ letters) in lime; "" = none. Leaves tags alone.
function Skin.highlight(s: string, phrase: string?, color: Color3?): string
	if phrase == "" then
		return s -- "" = no highlighting
	end
	local open = string.format('<font color="#%s">', (color or Skin.Lime):ToHex())
	if phrase then
		local i, j = string.find(s, phrase, 1, true)
		if i then
			return string.sub(s, 1, i - 1) .. open .. phrase .. "</font>" .. string.sub(s, (j :: number) + 1)
		end
		return s
	end
	return (string.gsub(s, "([^<]*)(<?[^>]*>?)", function(plain: string, tag: string)
		return (string.gsub(plain, "(%u%u[%u%d']*!?)", open .. "%1</font>")) .. tag
	end))
end

-- a full-screen overlay ScreenGui shared by the v2 pieces that float above everything (toasts, banners, prompts)
local overlays: { [string]: ScreenGui } = {}
function Skin.overlay(name: string, displayOrder: number): ScreenGui
	local g = overlays[name]
	if g and g.Parent then
		return g
	end
	local player = game:GetService("Players").LocalPlayer
	g = make("ScreenGui", {
		Name = name, ResetOnSpawn = false, DisplayOrder = displayOrder, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui"),
	})
	;(g :: ScreenGui):SetAttribute("SkinBuilt", true)
	overlays[name] = g :: ScreenGui
	return g :: ScreenGui
end

-- a little four-point sparkle (two crossed bars) that twinkles on its own
function Skin.sparkle(parent: GuiObject, pos: UDim2, px: number, z: number, delay: number?): Frame
	local s = make("Frame", {
		Name = "Sparkle", AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = UDim2.fromOffset(px, px),
		BackgroundTransparency = 1, Rotation = 0, ZIndex = z, Interactable = false, Parent = parent,
	})
	for _, sz in { Vector2.new(0.26, 1), Vector2.new(1, 0.26) } do
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(sz.X, sz.Y),
			BackgroundColor3 = Skin.White, BorderSizePixel = 0, ZIndex = z, Interactable = false, Parent = s,
		}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local sc = make("UIScale", { Scale = 0.5, Parent = s })
	task.spawn(function()
		task.wait(delay or 0)
		while s.Parent do
			tween(sc, 0.45, { Scale = 1 }, Enum.EasingStyle.Sine)
			tween(s, 0.9, { Rotation = s.Rotation + 45 }, Enum.EasingStyle.Sine)
			task.wait(0.45)
			tween(sc, 0.45, { Scale = 0.35 }, Enum.EasingStyle.Sine)
			task.wait(1.4 + math.random() * 1.2)
		end
	end)
	return s
end

------------------------------------------------------------------ v2: HUD tile
-- The reference's square HUD tile: gradient + studs, white inner rim, ink outline + lip, sparkle glints, the PNG
-- icon overflowing the top, the label overlapping the bottom edge, a red badge top-right. Hover x1.08, press x0.9.
-- opts: Name, Parent, Label, Icon (HudMenu.Icons key or id), Color (swatch / name / Color3), Size (px, 88),
-- LayoutOrder, Position, AnchorPoint.
export type HudTile = {
	holder: Frame,
	button: TextButton,
	icon: ImageLabel,
	label: TextLabel,
	setBadge: (string?) -> (),
	setAlert: (boolean) -> (),
	setNote: (string?) -> (),
	setLabel: (string) -> (),
}
function Skin.hudTile(opts: { [string]: any }): HudTile
	local px = opts.Size or 88
	local sw = Skin.swatch(opts.Color or "Sky")
	local name = opts.Name or "Tile"
	local holder = make("Frame", {
		Name = name, Size = UDim2.fromOffset(px, px), Position = opts.Position, AnchorPoint = opts.AnchorPoint,
		BackgroundTransparency = 1, LayoutOrder = opts.LayoutOrder, Parent = opts.Parent,
	})
	holder:SetAttribute("NoSkin", true)
	local button = make("TextButton", {
		Name = name .. "Button", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Skin.White, AutoButtonColor = false,
		Text = "", ZIndex = 2, Parent = holder,
	}, {
		corner(14), stroke(4),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, sw.light), ColorSequenceKeypoint.new(0.5, sw.base),
			ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.5)),
		}) }),
	})
	button:SetAttribute("NoSkin", true)
	Skin.studs(button, 0.84, nil, 22)
	Skin.gloss(button, 0.3)
	make("Frame", { -- the dark underside
		Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, math.floor(px * 0.13)),
		BackgroundColor3 = sw.dark, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 2, Interactable = false, Parent = button,
	}, { corner(14) })
	make("Frame", { -- white inner rim
		Name = "Rim", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1,
		ZIndex = 3, Interactable = false, Parent = button,
	}, { corner(10), make("UIStroke", { Thickness = 2.5, Color = Skin.White, Transparency = 0.12 }) })
	Skin.sparkle(button, UDim2.fromScale(0.2, 0.22), math.floor(px * 0.17), 3, 0)
	Skin.sparkle(button, UDim2.fromScale(0.84, 0.6), math.floor(px * 0.11), 3, 1.1)
	local icon = make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromScale(1.08, 1.08),
		BackgroundTransparency = 1, Image = Skin.icon(opts.Icon), ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Interactable = false, Parent = button,
	})
	local labelText = opts.Label or ""
	local label = text({
		Name = "Label", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, 18, 0, math.floor(px * 0.34)),
		Text = labelText, ZIndex = 6, Parent = button,
	}, math.floor(px * 0.3), 3)
	-- red badge (a count or "!") top-right; the alert is the same red "!" (beside the badge if both show)
	local function redDot(dotName: string): (Frame, TextLabel)
		local d = make("Frame", {
			Name = dotName, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = Skin.White, Visible = false, ZIndex = 8, Parent = button,
		}, {
			make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(3),
			make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Skin.Palette.Red.light, Skin.Palette.Red.base) }),
		})
		local t = text({ Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2), Text = "", ZIndex = 9, Parent = d }, 20, 2)
		return d, t
	end
	local badge, badgeText = redDot("Badge")
	local alert, alertText = redDot("Alert")
	alertText.Text = "!"

	local scale = Skin.pressable(button, Skin.Motion.Hover)
	button.MouseEnter:Connect(function()
		tween(icon, 0.2, { Rotation = -8 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		tween(icon, 0.2, { Rotation = 0 })
	end)
	-- wiggle now and then while something waits inside
	task.spawn(function()
		while holder.Parent do
			task.wait(3.4)
			if (badge.Visible or alert.Visible) and button.GuiState ~= Enum.GuiState.Hover then
				for _, r in { 10, -9, 6, -4, 0 } do
					tween(button, 0.07, { Rotation = r })
					task.wait(0.07)
				end
			end
		end
	end)
	local function placeDots()
		alert.Position = if badge.Visible then UDim2.new(1, -36, 0, 6) else UDim2.new(1, -6, 0, 6)
	end
	local _ = scale -- (pressable drives it)
	return {
		holder = holder, button = button, icon = icon, label = label,
		setBadge = function(t: string?)
			local was = badge.Visible
			badge.Visible = t ~= nil
			badgeText.Text = t or ""
			if t and not was then
				Skin.pop(badge, 0.3)
			end
			placeDots()
		end,
		setAlert = function(on: boolean)
			local was = alert.Visible
			alert.Visible = on
			if on and not was then
				Skin.pop(alert, 0.3)
			end
			placeDots()
		end,
		-- a timer / short note shows as the label, in lime (the reference's gift countdown); nil = the label again
		setNote = function(t: string?)
			label.Text = t or labelText
			label.TextColor3 = if t then Skin.Lime else Skin.White
		end,
		setLabel = function(t: string)
			labelText = t
			label.Text = t
		end,
	}
end

------------------------------------------------------------------ v2: toast
-- An info line: icon + white Fredoka with an ink stroke, a word in lime, over a soft shadow band (no panel).
-- Slides down + fades in; with Hold it leaves by itself, without it the caller drives set / show / hide.
-- opts: Text, Highlight (phrase; default = the ALL-CAPS words), Icon, Parent (ScreenGui/GuiObject; default a shared
-- overlay), Position (top-centre), TextSize (24), Hold (s), Name.
export type Toast = {
	frame: Frame,
	set: (string, string?, string?) -> (),
	show: () -> (),
	hide: () -> (),
	destroy: () -> (),
	isShown: () -> boolean,
}
function Skin.toast(opts: { [string]: any }): Toast
	local parent = opts.Parent or Skin.overlay("SkinToasts", 22)
	local home: UDim2 = opts.Position or UDim2.new(0.5, 0, 0, 64)
	local size = opts.TextSize or 24
	local frame = make("Frame", {
		Name = opts.Name or "Toast", AnchorPoint = Vector2.new(0.5, 0), Position = home, Size = UDim2.fromOffset(10, size + 20),
		BackgroundTransparency = 1, Visible = false, ZIndex = 30, Parent = parent,
	})
	frame:SetAttribute("NoSkin", true)
	local fit = make("UIScale", { Parent = frame })
	-- v3: the reference's announcement pill - sky gradient, ink outline, white rim, diagonal light bands
	local pillSw = Skin.swatch(opts.Color or "Sky")
	local band = make("Frame", {
		Name = "Band", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(200, size + 24),
		BackgroundColor3 = Skin.White, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30, Interactable = false, Parent = frame,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 10) }),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(pillSw.light, pillSw.base) }),
	})
	local bandStroke = make("UIStroke", { Thickness = 3, Color = pillSw.dark:Lerp(Skin.Ink, 0.4), Transparency = 1, Parent = band })
	local bandStripes = Skin.stripes(band, 0.72, 4, 0.05)
	bandStripes.BackgroundTransparency = 1
	local row = make("Frame", {
		Name = "Row", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 31, Parent = frame,
	}, {
		make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local icon = make("ImageLabel", {
		Name = "Icon", Size = UDim2.fromOffset(size + 22, size + 22), BackgroundTransparency = 1, Image = Skin.icon(opts.Icon),
		Visible = opts.Icon ~= nil, ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1, ZIndex = 32, Parent = row,
	})
	local label = make("TextLabel", {
		Name = "Label", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
		FontFace = Skin.Fonts.Title, TextSize = size, TextColor3 = Skin.White, RichText = true, Text = "", LayoutOrder = 2,
		ZIndex = 32, Parent = row,
	})
	local labelStroke = make("UIStroke", { Thickness = 3, Color = pillSw.dark:Lerp(Skin.Ink, 0.55), LineJoinMode = Enum.LineJoinMode.Round, Parent = label })
	local pulse = make("UIScale", { Parent = row })

	local alpha = make("NumberValue", { Value = 1 })
	local function applyAlpha(a: number)
		label.TextTransparency = a
		labelStroke.Transparency = a
		icon.ImageTransparency = a
		band.BackgroundTransparency = a
		bandStroke.Transparency = a
		bandStripes.BackgroundTransparency = a
	end
	alpha.Changed:Connect(applyAlpha)
	applyAlpha(1)
	-- phones: shrink to fit the screen width
	local function refit()
		local cam = workspace.CurrentCamera
		local vw = if cam then cam.ViewportSize.X else 1280
		local natural = row.AbsoluteSize.X / math.max(fit.Scale * pulse.Scale, 0.01)
		band.Size = UDim2.fromOffset(natural + 48, size + 22)
		fit.Scale = math.clamp((vw * 0.94) / math.max(natural + 40, 1), 0.45, 1)
	end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refit)
	end)

	local shown = false
	local token = 0
	local function show()
		if shown then
			return
		end
		shown = true
		token += 1
		frame.Visible = true
		frame.Position = home - UDim2.fromOffset(0, Skin.Motion.ToastDrop)
		tween(frame, Skin.Motion.ToastIn, { Position = home }, Enum.EasingStyle.Back)
		tween(alpha, Skin.Motion.ToastIn * 0.8, { Value = 0 })
	end
	local function hide()
		if not shown then
			return
		end
		shown = false
		token += 1
		local my = token
		tween(frame, Skin.Motion.ToastOut, { Position = home - UDim2.fromOffset(0, 12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(alpha, Skin.Motion.ToastOut, { Value = 1 })
		task.delay(Skin.Motion.ToastOut, function()
			if token == my then
				frame.Visible = false
			end
		end)
	end
	local current = ""
	local function set(s: string, phrase: string?, iconName: string?)
		local rich = Skin.highlight(s, phrase)
		if iconName ~= nil then
			icon.Image = Skin.icon(iconName)
			icon.Visible = iconName ~= ""
		end
		if rich ~= current then
			current = rich
			label.Text = rich
			if shown then
				pulse.Scale = 1.07
				tween(pulse, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
	end
	local handle: Toast = {
		frame = frame, set = set, show = show, hide = hide,
		destroy = function()
			frame:Destroy()
			alpha:Destroy()
		end,
		isShown = function()
			return shown
		end,
	}
	if opts.Text then
		set(opts.Text, opts.Highlight)
	end
	if opts.Hold then
		show()
		task.delay(opts.Hold, function()
			hide()
			task.wait(Skin.Motion.ToastOut + 0.05)
			handle.destroy()
		end)
	end
	return handle
end

------------------------------------------------------------------ v2: counter
-- A currency counter with no panel: big glossy icon + a big stroked number that counts up, popping on a gain.
-- opts: Parent, Name, Icon, Position, AnchorPoint, Height (52), Width (300), Value, Format (number -> string),
-- TextColor, ZIndex.
export type Counter = { frame: Frame, label: TextLabel, icon: ImageLabel, set: (number) -> (), pop: () -> (), value: () -> number }
function Skin.counter(opts: { [string]: any }): Counter
	local h = opts.Height or 52
	local fmt = opts.Format or function(n: number): string
		return tostring(math.floor(n))
	end
	local z = opts.ZIndex or 3
	local frame = make("Frame", {
		Name = opts.Name or "Counter", AnchorPoint = opts.AnchorPoint, Position = opts.Position,
		Size = UDim2.fromOffset(opts.Width or 300, h), BackgroundTransparency = 1, ZIndex = z, Parent = opts.Parent,
	})
	frame:SetAttribute("NoSkin", true)
	local popScale = make("UIScale", { Parent = frame })
	local icon = make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, math.floor(h * 0.6), 0.5, 0),
		Size = UDim2.fromOffset(math.floor(h * 1.3), math.floor(h * 1.3)), BackgroundTransparency = 1, Image = Skin.icon(opts.Icon),
		ScaleType = Enum.ScaleType.Fit, ZIndex = z + 1, Parent = frame,
	})
	local label = text({
		Name = "Amount", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, math.floor(h * 1.25), 0.5, 0),
		Size = UDim2.new(1, -math.floor(h * 1.25), 1, 0), Text = fmt(opts.Value or 0), TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = opts.TextColor or Skin.White, ZIndex = z + 1, Parent = frame,
	}, math.floor(h * 0.86), math.max(3, math.floor(h / 12)))
	local current = opts.Value or 0
	local function pop()
		popScale.Scale = 1.16
		tween(popScale, Skin.Motion.PopTime, { Scale = 1 }, Enum.EasingStyle.Back)
		icon.Rotation = -14
		tween(icon, 0.4, { Rotation = 0 }, Enum.EasingStyle.Back)
	end
	return {
		frame = frame, label = label, icon = icon, pop = pop,
		set = function(v: number)
			if v == current then
				return
			end
			local from = current
			current = v
			Skin.countTo(label, from, v, fmt, 0.6)
			if v > from then
				pop()
			end
		end,
		value = function()
			return current
		end,
	}
end

------------------------------------------------------------------ v2: arrival banner
-- The zone-arrival sign: a wooden plank hanging on two ropes with a red NOW ENTERING ribbon; it swings in from
-- above, hangs, and swings back up. One at a time (a new one replaces the old).
-- opts: Title, Sub, Ribbon ("NOW ENTERING"), Icon (default Travel), Color (title colour), Hold (s).
local currentBanner: Frame? = nil
function Skin.banner(opts: { [string]: any }): Frame
	local gui = Skin.overlay("SkinBanners", 21)
	if currentBanner then
		currentBanner:Destroy()
	end
	local W, H = 540, 112
	local wood = { light = hex("D68C46"), base = hex("B8743A"), dark = hex("7A4622") }
	-- the pivot's centre is the plank's top edge, so rotating it swings the plank like a hanging sign
	local pivot = make("Frame", {
		Name = "ArrivalBanner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, -H * 1.6),
		Size = UDim2.fromOffset(W, H * 2), BackgroundTransparency = 1, ZIndex = 40, Parent = gui,
	})
	pivot:SetAttribute("NoSkin", true) -- StarterPlayerScripts.UISkin (old auto-skin) must leave it alone
	currentBanner = pivot
	local fitScale = make("UIScale", { Parent = pivot })
	local cam = workspace.CurrentCamera
	if cam then
		fitScale.Scale = math.clamp(math.min(cam.ViewportSize.X / (W + 120), cam.ViewportSize.Y / 520), 0.5, 1)
	end
	for _, x in { 0.18, 0.82 } do -- ropes up off the top of the screen
		make("Frame", {
			Name = "Rope", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(x, 0, 0.5, 6), Size = UDim2.new(0, 6, 0.5, 400),
			BackgroundColor3 = hex("5A3A1E"), BorderSizePixel = 0, ZIndex = 40, Parent = pivot,
		}, { stroke(2) })
	end
	local plank = make("Frame", {
		Name = "Plank", Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = Skin.White,
		ZIndex = 41, Parent = pivot,
	}, {
		corner(12), stroke(5),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, wood.light), ColorSequenceKeypoint.new(0.6, wood.base), ColorSequenceKeypoint.new(1, wood.base:Lerp(wood.dark, 0.5)),
		}) }),
	})
	Skin.studs(plank, 0.86, nil, 26)
	for i, y in { 0.36, 0.7 } do -- plank seams
		make("Frame", {
			Name = "Seam" .. i, Position = UDim2.new(0, 10, y, 0), Size = UDim2.new(1, -20, 0, 3), BackgroundColor3 = wood.dark,
			BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 41, Parent = plank,
		})
	end
	make("Frame", {
		Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = wood.dark, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 41, Parent = plank,
	}, { corner(12) })
	for _, x in { 0.18, 0.82 } do -- nails
		make("Frame", {
			Name = "Nail", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, 0, 14), Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = hex("C9CCE0"), ZIndex = 42, Parent = plank,
		}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(2) })
	end
	make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 6, 0.55, 0), Size = UDim2.fromOffset(96, 96),
		BackgroundTransparency = 1, Image = Skin.icon(opts.Icon or "Travel"), ScaleType = Enum.ScaleType.Fit, ZIndex = 44, Parent = plank,
	})
	text({
		Name = "Title", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 10, 0.5, if opts.Sub then -6 else 4),
		Size = UDim2.new(1, -120, 0, 58), Text = opts.Title or "", TextColor3 = opts.Color or Skin.White, ZIndex = 43, Parent = plank,
	}, 54, 5)
	if opts.Sub then
		text({
			Name = "Sub", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 10, 1, -14), Size = UDim2.new(1, -130, 0, 24),
			Text = opts.Sub, FontFace = Skin.Fonts.Body, ZIndex = 43, Parent = plank,
		}, 22, 2)
	end
	-- red ribbon pinned over the top edge, with folded tails
	local ribbon = make("Frame", {
		Name = "Ribbon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.fromOffset(250, 38),
		Rotation = -3, BackgroundColor3 = Skin.White, ZIndex = 46, Parent = plank,
	}, {
		corner(5), stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Skin.Palette.Red.light, Skin.Palette.Red.base) }),
	})
	for _, side in { -1, 1 } do
		make("Frame", {
			Name = "Tail", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5 + side * 0.52, 0, 0.62, 0), Size = UDim2.fromOffset(34, 28),
			Rotation = side * 8, BackgroundColor3 = Skin.Palette.Red.dark, ZIndex = 45, Parent = ribbon,
		}, { corner(4), stroke(3) })
	end
	text({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = opts.Ribbon or "NOW ENTERING", ZIndex = 47, Parent = ribbon }, 24, 3)

	-- swing in: drop from above, then a damped pendulum
	local y = UDim2.new(0.5, 0, 0, 126) -- plank top (+ its ribbon) under the HUD hint toast
	pivot.Rotation = -16
	tween(pivot, Skin.Motion.BannerIn, { Position = y }, Enum.EasingStyle.Back)
	task.spawn(function()
		for _, r in { 9, -5, 3, -1.5, 0 } do
			if currentBanner ~= pivot then
				return
			end
			tween(pivot, 0.3, { Rotation = r }, Enum.EasingStyle.Sine)
			task.wait(0.3)
		end
	end)
	task.delay(opts.Hold or Skin.Motion.BannerHold, function()
		if currentBanner ~= pivot then
			return
		end
		tween(pivot, Skin.Motion.BannerOut, { Position = UDim2.new(0.5, 0, 0, -H * 1.6), Rotation = 8 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(Skin.Motion.BannerOut + 0.05)
		if currentBanner == pivot then
			currentBanner = nil
		end
		pivot:Destroy()
	end)
	return pivot
end

------------------------------------------------------------------ v2: world prompt
-- The custom ProximityPrompt look (for prompts with Style = Custom): a white key cap (E / X / TAP) with a lime
-- hold ring, the action in white Fredoka + stroke, the object name small above it, on a charcoal studded plate.
-- Skin.installPrompts() draws every Custom prompt for this player (call once from a client script). The hold ring is
-- 16 segments round the cap lighting up clockwise (a clipped-gradient ring didn't draw in Roblox, 2026-10-18).
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		local n = prompt.GamepadKeyCode.Name
		return (string.gsub(n, "^Button", ""))
	end
	local k = prompt.KeyboardKeyCode
	local s = UserInputService:GetStringForKeyCode(k)
	return if s and s ~= "" then string.upper(s) else k.Name
end

function Skin.prompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, parent: Instance?): () -> ()
	local K = 58 -- key cap
	local RING = K + 18
	local bb = make("BillboardGui", {
		Name = "SkinPrompt", AlwaysOnTop = true, Size = UDim2.fromOffset(300, RING + 8),
		SizeOffset = Vector2.new(prompt.UIOffset.X / 300, prompt.UIOffset.Y / (RING + 8)), LightInfluence = 0, ResetOnSpawn = false,
		Active = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Adornee = prompt.Parent :: any,
		Parent = parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
	})
	local root = make("Frame", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bb })
	local rootScale = make("UIScale", { Scale = 0.6, Parent = root })
	-- plate behind the text (fixed layout: the object name small on top, the action big under it)
	local plate = make("Frame", {
		Name = "Plate", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, RING / 2 + 4, 0.5, 0), Size = UDim2.fromOffset(236, K - 4),
		BackgroundColor3 = Skin.Panel, ZIndex = 1, Parent = root,
	}, { corner(10), stroke(4) })
	Skin.studs(plate, 0.92, nil, 24)
	local textX = RING / 2 + 8
	local object = text({
		Name = "Object", Position = UDim2.fromOffset(textX, 5), Size = UDim2.new(1, -textX - 10, 0, 16), Text = prompt.ObjectText,
		FontFace = Skin.Fonts.Body, TextColor3 = Skin.TextSoft, TextXAlignment = Enum.TextXAlignment.Left,
		Visible = prompt.ObjectText ~= "", ZIndex = 2, Parent = plate,
	}, 16, 0)
	local action = text({
		Name = "Action", Position = UDim2.fromOffset(textX, if prompt.ObjectText ~= "" then 20 else 11), Size = UDim2.new(1, -textX - 10, 0, 28),
		Text = prompt.ActionText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = plate,
	}, 26, 3)
	-- key cap + ring
	local keyHolder = make("Frame", {
		Name = "Key", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, RING / 2 + 4, 0.5, 0), Size = UDim2.fromOffset(RING, RING),
		BackgroundTransparency = 1, ZIndex = 3, Parent = root,
	})
	local keyScale = make("UIScale", { Parent = keyHolder })
	make("Frame", { -- dark ring track
		Name = "Track", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1, ZIndex = 3, Parent = keyHolder,
	}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 7, Color = Skin.Ink, Transparency = 0.25 }) })
	-- the hold ring: 16 segments around the cap that light up lime, clockwise from the top
	local SEGMENTS = 16
	local segs: { Frame } = {}
	local radius = RING / 2 - 6
	for i = 1, SEGMENTS do
		local a = math.rad((i - 0.5) / SEGMENTS * 360)
		segs[i] = make("Frame", {
			Name = "Seg" .. i, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(a) * radius, 0.5, -math.cos(a) * radius), Size = UDim2.fromOffset(7, 11),
			Rotation = math.deg(a), BackgroundColor3 = Skin.Lime, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Parent = keyHolder,
		}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local function setProgress(p: number)
		local lit = math.floor(math.clamp(p, 0, 1) * SEGMENTS + 0.5)
		for i, seg in segs do
			seg.BackgroundTransparency = if i <= lit then 0 else 1
		end
	end
	setProgress(0)
	local cap = make("TextButton", {
		Name = "Cap", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(K - 14, K - 14),
		BackgroundColor3 = Skin.White, AutoButtonColor = false, Text = "", ZIndex = 5, Parent = keyHolder,
	}, {
		corner(10), stroke(3),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Skin.White, hex("D9DCEA")) }),
	})
	make("Frame", {
		Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = hex("9A9EB8"), BorderSizePixel = 0, ZIndex = 5, Parent = cap,
	}, { corner(10) })
	local key = keyText(prompt, inputType)
	make("TextLabel", {
		Name = "KeyText", Size = UDim2.new(1, -6, 1, -8), Position = UDim2.fromOffset(3, 1), BackgroundTransparency = 1,
		FontFace = Skin.Fonts.Title, TextScaled = true, TextColor3 = Skin.Ink, Text = key, ZIndex = 6, Parent = cap,
	}, { make("UITextSizeConstraint", { MaxTextSize = if #key > 1 then 18 else 30 }) })

	local conns: { RBXScriptConnection } = {}
	local holdTween: Tween? = nil
	local progress = make("NumberValue", { Value = 0 })
	table.insert(conns, progress.Changed:Connect(setProgress))
	table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
		if holdTween then
			holdTween:Cancel()
		end
		tween(keyScale, 0.08, { Scale = 0.9 })
		if prompt.HoldDuration > 0 then
			progress.Value = 0
			holdTween = TweenService:Create(progress, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Value = 1 })
			;(holdTween :: Tween):Play()
		end
	end))
	table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
		if holdTween then
			holdTween:Cancel()
		end
		tween(keyScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(progress, 0.15, { Value = 0 })
	end))
	table.insert(conns, prompt.Triggered:Connect(function()
		keyScale.Scale = 1.2
		tween(keyScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end))
	table.insert(conns, prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
		action.Text = prompt.ActionText
	end))
	table.insert(conns, prompt:GetPropertyChangedSignal("ObjectText"):Connect(function()
		object.Text = prompt.ObjectText
		object.Visible = prompt.ObjectText ~= ""
		action.Position = UDim2.fromOffset(textX, if prompt.ObjectText ~= "" then 20 else 11)
	end))
	-- touch / click: hold the cap (or the plate) to hold the prompt
	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local hit = make("TextButton", {
			Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 9, Parent = root,
		})
		local holding = false
		table.insert(conns, hit.InputBegan:Connect(function(input: InputObject)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)
				and input.UserInputState ~= Enum.UserInputState.Change then
				holding = true
				prompt:InputHoldBegin()
			end
		end))
		table.insert(conns, hit.InputEnded:Connect(function(input: InputObject)
			if holding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
				holding = false
				prompt:InputHoldEnd()
			end
		end))
	end
	tween(rootScale, Skin.Motion.PromptIn, { Scale = 1 }, Enum.EasingStyle.Back)
	return function()
		for _, c in conns do
			c:Disconnect()
		end
		if holdTween then
			holdTween:Cancel()
		end
		progress:Destroy()
		local t = tween(rootScale, 0.12, { Scale = 0.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Once(function()
			bb:Destroy()
		end)
	end
end

local promptsInstalled = false
function Skin.installPrompts()
	if promptsInstalled then
		return
	end
	promptsInstalled = true
	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		local cleanup = Skin.prompt(prompt, inputType)
		prompt.PromptHidden:Wait()
		cleanup()
	end)
end

return Skin
