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

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Skin = {}

------------------------------------------------------------------ tokens
Skin.Fonts = {
	Title = Font.new("rbxasset://fonts/families/FredokaOne.json"),
	Number = Font.new("rbxasset://fonts/families/LuckiestGuy.json"),
	Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
	Heavy = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy),
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
Skin.Panel = hex("2C2E3E")
Skin.PanelDeep = hex("1D1E2A")
Skin.TextSoft = hex("C9CCE0")

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

------------------------------------------------------------------ motion
-- grow on hover, squish on press, spring back on release. Returns the UIScale it drives.
function Skin.pressable(button: GuiButton, hoverScale: number?): UIScale
	local scale = button:FindFirstChild("PressScale") :: UIScale?
	if not scale then
		scale = make("UIScale", { Name = "PressScale", Parent = button })
	end
	local s = scale :: UIScale
	local grow = hoverScale or 1.06
	local over = false
	button.MouseEnter:Connect(function()
		over = true
		tween(s, 0.18, { Scale = grow }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		over = false
		tween(s, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	button.MouseButton1Down:Connect(function()
		tween(s, 0.06, { Scale = 0.9 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(s, 0.28, { Scale = if over then grow else 1 }, Enum.EasingStyle.Back)
	end)
	button.Activated:Connect(function()
		-- touch / gamepad: no hover events, so give the squish here too
		if not over then
			s.Scale = 0.9
			tween(s, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
	return s
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
export type Button = { button: TextButton, label: TextLabel, setStyle: (string | Color3 | Swatch) -> (), setText: (string) -> () }

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
	Skin.gloss(btn, 0.32)
	local label = text({
		Name = "Label", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(1, -12, 0.78, 0), Text = props.Text or "", FontFace = props.Font or Skin.Fonts.Title,
		ZIndex = btn.ZIndex + 1, Parent = btn,
	}, props.TextSize or 30, props.TextStroke)
	local function setStyle(style: string | Color3 | Swatch)
		local s = Skin.swatch(style)
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, s.light), ColorSequenceKeypoint.new(0.45, s.base), ColorSequenceKeypoint.new(1, s.base:Lerp(s.dark, 0.35)),
		})
		innerStroke.Color = s.dark
		lip.BackgroundColor3 = s.dark
		lip.BackgroundTransparency = 0.25
	end
	setStyle(sw)
	if props.Pressable ~= false then
		Skin.pressable(btn)
	end
	return {
		button = btn,
		label = label,
		setStyle = setStyle,
		setText = function(t: string)
			label.Text = t
		end,
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
	panel:SetAttribute("NoSkin", true) -- opt out of StarterPlayerScripts.UISkin (the old auto-skin)
	dim:SetAttribute("NoSkin", true)
	Skin.studs(panel, 0.93, nil, 30)
	-- inner rim (a thin lighter line inside the outline, like the reference)
	make("Frame", {
		Name = "Rim", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = 1, Interactable = false, Parent = panel,
	}, { corner(8), make("UIStroke", { Thickness = 2, Color = hex("4A4D66"), Transparency = 0.2 }) })

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
	Skin.studs(header, 0.86, nil, 26)
	Skin.shineBands(header, 0.66)
	-- ink divider under the header
	make("Frame", {
		Name = "Divider", Position = UDim2.new(0, 0, 0, headerH + 4), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Skin.Ink,
		BorderSizePixel = 0, ZIndex = 2, Parent = panel,
	})
	local iconW = 0
	if opts.Icon then
		iconW = headerH - 8
		make("ImageLabel", {
			Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(iconW, iconW),
			BackgroundTransparency = 1, Image = opts.Icon, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = header,
		})
		iconW += 10
	end
	local title = text({
		Name = "Title", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 22 + iconW, 0.5, -1),
		Size = UDim2.new(0.62, 0, 0, headerH - 18), Text = opts.Title or "", TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3, Parent = header,
	}, 60, 5)
	local close = Skin.closeButton(header, headerH - 14, 4)

	local body = make("Frame", {
		Name = "Body", Position = UDim2.fromOffset(0, headerH + 8), Size = UDim2.new(1, 0, 1, -(headerH + 8)),
		BackgroundTransparency = 1, ZIndex = 2, Parent = panel,
	})
	-- shortcut dock beside the window: its own dark studded panel so whatever HUD sits behind it never shows through
	local sideRail = make("Frame", {
		Name = "SideRail", AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 12, 0, headerH + 10),
		Size = UDim2.fromOffset(132, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Skin.Panel,
		Visible = false, ZIndex = 1, Parent = panel,
	}, { corner(10), stroke(5) })
	Skin.studs(sideRail, 0.93, nil, 30)
	make("Frame", {
		Name = "List", Size = UDim2.fromOffset(132, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		ZIndex = 2, Parent = sideRail,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
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

-- "-- TITLE --" section header
function Skin.section(parent: GuiObject, title: string, color: string | Color3 | Swatch, order: number): TextLabel
	local sw = Skin.swatch(color)
	local l = text({
		Name = "Section_" .. title, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = order,
		Text = "-- " .. string.upper(title) .. " --", TextColor3 = sw.light:Lerp(sw.base, 0.35), FontFace = Skin.Fonts.Title,
		ZIndex = parent.ZIndex + 1, Parent = parent,
	}, 44, 4)
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
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, sw.base:Lerp(sw.dark, 0.35)), ColorSequenceKeypoint.new(0.45, sw.base),
			ColorSequenceKeypoint.new(1, sw.base:Lerp(sw.dark, 0.45)),
		}) }),
	})
	local glowAt = opts.GlowAt or Vector2.new(0.5, 0.38)
	make("ImageLabel", {
		Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(glowAt.X, glowAt.Y),
		Size = UDim2.fromScale(1.6, 1.6), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1,
		Image = Skin.Assets.Rays, ImageColor3 = sw.light, ImageTransparency = 0.62, ZIndex = z, Interactable = false, Parent = card,
	})
	make("ImageLabel", {
		Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(glowAt.X, glowAt.Y),
		Size = UDim2.fromScale(1.05, 1.05), SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundTransparency = 1,
		Image = Skin.Assets.Glow, ImageColor3 = Skin.White, ImageTransparency = 0.45, ZIndex = z, Interactable = false, Parent = card,
	})
	Skin.studs(card, 0.9, nil, 26)
	make("Frame", {
		Name = "Bevel", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1,
		ZIndex = z + 1, Interactable = false, Parent = card,
	}, { corner(6), make("UIStroke", { Thickness = 2, Color = sw.light, Transparency = 0.35 }) })
	return card
end

-- a tilted tag pinned to a corner ("BEST VALUE!", "NEW!", "OWNED")
function Skin.ribbon(parent: GuiObject, label: string, color: string | Color3 | Swatch?, z: number?): Frame
	local sw = Skin.swatch(color or "Gold")
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

-- a shortcut beside the window: big icon + stroked label, no box (the reference's Stars / Featured / Speed / Money)
function Skin.sideTab(rail: GuiObject, opts: { [string]: any }): TextButton
	rail.Visible = true
	local b = make("TextButton", {
		Name = "Tab_" .. (opts.Label or ""), Size = UDim2.fromOffset(118, 96), BackgroundTransparency = 1, Text = "",
		LayoutOrder = opts.LayoutOrder, ZIndex = 3, Parent = rail:FindFirstChild("List") or rail,
	})
	make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.fromOffset(78, 72),
		BackgroundTransparency = 1, Image = opts.Icon or "", ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = b,
	})
	text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 30),
		Text = opts.Label or "", ZIndex = 4, Parent = b }, 26, 3)
	Skin.pressable(b, 1.1)
	return b
end

return Skin
