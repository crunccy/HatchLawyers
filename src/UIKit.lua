-- UIKit: the lawyer-themed UI style from the Figma kit ("Hatch a Lawyer – UI Kit"), as Roblox building blocks.
-- 2026-10-09 UI pass (user: "the ui is cooked"): the icon sprite sheet (rbxassetid://76384361895353) belongs to
-- another account and was never shared with this experience, so EVERY sheet icon failed to load (blank close
-- buttons, the DAILY tile's gift, ...). Icons are now single PNGs (Shared.HudMenu.Icons, free Creator Store
-- images); a glyph with no image keeps its text. Panels moved from navy checker to the game's dark studded
-- purple (same as the Shop / Merger / LAWYERS panels); close buttons are a red tile with a real "X".
-- Chunky 3D buttons (gradient + gloss + dark lip + ink outline + shine sweep, bouncy hover / squish press),
-- navy checker panels, colourful header bars, icons from one sprite sheet, pop-in and attention pulses.
-- StarterPlayerScripts.UISkin applies these to every screen automatically; scripts can also call them directly.
-- v3 (2026-10-23, docs/UI_STYLE_V3.md): matches Skin v3 until each old screen is rebuilt on Skin - charcoal panels,
-- diagonal light bands on every coloured button, a "//" double glint, Gotham Black, grow-only hover (no tilt).

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UIKit = {}

UIKit.Assets = {
	Checker = "rbxassetid://114488299634202", -- the studs tile (tools/ui_textures.py), same as the Shop / LAWYERS panels
	Rays = "rbxassetid://89557955610458", -- 512px white sunburst
	Glow = "rbxassetid://75348129891036", -- 256px soft white radial glow
}
UIKit.IconOrder = {
	"Coin", "Gavel", "Briefcase", "Scales", "Lawyer", "Egg",
	"Gift", "Star", "Trophy", "Clipboard", "Lightning", "Merge",
	"Shirt", "Cart", "Lock", "Close", "Plus", "Clock",
}
-- emoji / glyph icons the old UI used -> sheet icons
UIKit.EmojiIcons = {
	["⚖️"] = "Scales", ["⚖"] = "Scales", ["🎁"] = "Gift", ["💼"] = "Briefcase", ["🥚"] = "Egg", ["👔"] = "Shirt",
	["⭐"] = "Star", ["🌟"] = "Star", ["🏆"] = "Trophy", ["📋"] = "Clipboard", ["⚡"] = "Lightning", ["🔒"] = "Lock",
	["💰"] = "Coin", ["🪙"] = "Coin", ["$"] = "Coin", ["⏱️"] = "Clock", ["⏰"] = "Clock", ["🛒"] = "Cart", ["🔨"] = "Gavel",
	["👨‍⚖️"] = "Lawyer", ["🧑‍💼"] = "Lawyer", ["👤"] = "Lawyer",
}

-- one PNG per icon name (names kept from the old sheet); names without an image return nil
local Icons = (require(script.Parent:WaitForChild("HudMenu")) :: any).Icons
UIKit.IconImages = {
	Coin = Icons.Coin, Gavel = Icons.Gavel, Scales = Icons.Scales, Gift = Icons.Gift, Star = Icons.Star,
	Trophy = Icons.Trophy, Cart = Icons.Cart, Clipboard = Icons.Goals,
}

local function hex(h: string): Color3
	return Color3.fromHex(h)
end
UIKit.Colors = {
	Ink = hex("15131C"), -- v3: Skin.Ink
	PanelTop = hex("3A3B43"), -- v3: charcoal like Skin.Panel (was purple-navy)
	PanelBottom = hex("2E2F36"),
	Gold = hex("FFC93C"),
	Text = Color3.new(1, 1, 1),
	TextSoft = hex("D6D2F5"),
	TextGold = hex("FFD84A"),
}
local C = UIKit.Colors

function UIKit.luminance(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end
function UIKit.saturation(c: Color3): number
	local _, s = c:ToHSV()
	return s
end

------------------------------------------------------------------ small helpers
local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
UIKit.tween = tween

local function child(parent: Instance, class: string, name: string): any
	local c = parent:FindFirstChild(name)
	if c and c:IsA(class) then
		return c
	end
	c = Instance.new(class)
	c.Name = name
	c.Parent = parent
	return c
end

function UIKit.corner(obj: GuiObject, radius: number): UICorner
	local c = obj:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = obj
	elseif c.CornerRadius.Scale == 0 and c.CornerRadius.Offset < radius then
		c.CornerRadius = UDim.new(0, radius)
	end
	return c
end

-- the ink outline; Border mode so it outlines the box, not the text
function UIKit.outline(obj: GuiObject, thickness: number): UIStroke
	local s = obj:FindFirstChildOfClass("UIStroke")
	if not s then
		s = Instance.new("UIStroke")
		s.Parent = obj
	end
	s.Color = C.Ink
	s.Thickness = math.max(s.Thickness, thickness)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	return s
end

-- vertical shading; UIGradient multiplies BackgroundColor3, so it follows any colour a script sets later
function UIKit.shade(obj: GuiObject, top: number, bottom: number): UIGradient
	local g = obj:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.new(top, top, top), Color3.new(bottom, bottom, bottom))
	g.Rotation = 90
	g.Parent = obj
	return g
end

-- a decoration layer under the element's own children (ZIndex 0) that never takes input
local function layer(parent: GuiObject, name: string): Frame
	local f = child(parent, "Frame", name)
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = 0
	f.Interactable = false
	return f
end

local function cornerLike(src: GuiObject, dst: GuiObject)
	local c = src:FindFirstChildOfClass("UICorner")
	if c then
		local cc = dst:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
		cc.CornerRadius = c.CornerRadius
		cc.Parent = dst
	end
end

------------------------------------------------------------------ icons
function UIKit.hasIcon(name: string): boolean
	return UIKit.IconImages[name] ~= nil
end

function UIKit.icon(name: string, props: { [string]: any }?): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = "Icon_" .. name
	img.BackgroundTransparency = 1
	img.Image = UIKit.IconImages[name] or ""
	img.ScaleType = Enum.ScaleType.Fit
	for k, v in props or {} do
		(img :: any)[k] = v
	end
	return img
end

-- swap an emoji / glyph TextLabel for the matching sheet icon (keeps the label, hides its text + bubble)
function UIKit.replaceGlyph(label: TextLabel, iconName: string)
	if label:FindFirstChild("UIKitIcon") or not UIKit.hasIcon(iconName) then
		return -- (no picture for it: the glyph stays)
	end
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.BackgroundTransparency = 1
	for _, s in label:GetChildren() do
		if s:IsA("UIStroke") then
			s.Enabled = false
		end
	end
	local img = UIKit.icon(iconName, {
		Name = "UIKitIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.15, 1.15),
		ZIndex = label.ZIndex,
	})
	img.Parent = label
end

------------------------------------------------------------------ text lifting
-- A button's own text always draws under its children, so the gloss / lip / shine would sit on top of it.
-- liftText hides the button's text and mirrors it into a child label drawn above the decorations. Scripts keep
-- using btn.Text / TextColor3 / TextTransparency etc. as before; every change is copied across.
local MIRRORED = {
	"Text", "RichText", "FontFace", "TextColor3", "TextScaled", "TextSize", "TextWrapped", "TextXAlignment",
	"TextYAlignment", "TextTruncate", "LineHeight", "MaxVisibleGraphemes",
}
function UIKit.liftText(btn: TextButton, outlined: boolean)
	if btn:FindFirstChild("UIKitText") then
		return
	end
	local label = Instance.new("TextLabel")
	label.Name = "UIKitText"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = 10
	label.Interactable = false
	label.TextStrokeTransparency = 1
	for _, p in MIRRORED do
		(label :: any)[p] = (btn :: any)[p]
		btn:GetPropertyChangedSignal(p):Connect(function()
			(label :: any)[p] = (btn :: any)[p]
		end)
	end
	-- the button's text stays hidden; a script fading it (TextTransparency) fades the mirror instead
	local guard = false
	label.TextTransparency = btn.TextTransparency
	btn.TextTransparency = 1
	btn:GetPropertyChangedSignal("TextTransparency"):Connect(function()
		if guard then
			return
		end
		label.TextTransparency = btn.TextTransparency
		guard = true
		btn.TextTransparency = 1
		guard = false
	end)
	for _, c in btn:GetChildren() do
		if c:IsA("UITextSizeConstraint") then
			c:Clone().Parent = label
		end
	end
	if outlined then
		local s = Instance.new("UIStroke")
		s.Color = C.Ink
		s.Thickness = if btn.AbsoluteSize.Y < 34 then 1.5 else 2.5
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.Parent = label
		if UIKit.luminance(label.TextColor3) < 0.5 then
			label.TextColor3 = C.Text
		end
	end
	label.Parent = btn
end

------------------------------------------------------------------ buttons
local shineButtons: { [GuiObject]: boolean } = {}
local pulseButtons: { [GuiObject]: { scale: UIScale, base: number } } = {}
local hovered: { [GuiObject]: boolean } = {}

local PRIMARY_WORDS = { "CLAIM", "HIRE", "PLACE", "ROLL", "UPGRADE", "BEST FREE", "ATTEND", "BUY", "HATCH", "COLLECT", "GRAB" }

local function isPrimary(btn: GuiButton): boolean
	if not btn:IsA("TextButton") then
		return false
	end
	local t = string.upper(btn.Text)
	for _, w in PRIMARY_WORDS do
		if string.find(t, w, 1, true) then
			return true
		end
	end
	return false
end

-- glossy chunky button. style: "color" (default), "light" (cards / answer buttons), "close"
function UIKit.skinButton(btn: GuiButton, style: string?)
	if btn:GetAttribute("UIKit") then
		return
	end
	style = style or (if UIKit.luminance(btn.BackgroundColor3) > 0.82 then "light" else "color")
	-- a light card whose outline carries a colour (lawyer rarity etc.) becomes a rarity card filled with it
	local accent = UIKit.accentOf(btn)
	if style == "light" and accent then
		style = "rarity"
	end
	btn:SetAttribute("UIKit", "Button:" .. style)
	btn.AutoButtonColor = false
	if style == "close" then
		btn.BackgroundColor3 = hex("E42020")
		local c = btn:FindFirstChildOfClass("UICorner")
		if c then
			c.CornerRadius = UDim.new(0, 10) -- a red tile like the Shop / LAWYERS close button, not a pill
		end
	end

	local radius = if btn.AbsoluteSize.Y > 0 and btn.AbsoluteSize.Y < 34 then 9 else 14
	UIKit.corner(btn, radius)
	UIKit.outline(btn, if style == "light" then 3 else (if btn.AbsoluteSize.Y < 34 then 3 else 4))
	if style == "light" then
		UIKit.shade(btn, 1, 0.88)
	elseif style == "rarity" and accent then
		UIKit.rarityFill(btn, accent)
	else
		UIKit.shade(btn, 1.0, 0.64)
	end

	-- top gloss
	local gloss = layer(btn, "UIKitGloss")
	gloss.AnchorPoint = Vector2.new(0.5, 0)
	gloss.Position = UDim2.new(0.5, 0, 0, 3)
	gloss.Size = UDim2.new(1, -8, 0.46, -2)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0
	local gg = child(gloss, "UIGradient", "Fade")
	gg.Rotation = 90
	gg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if style == "light" then 0.4 else 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	cornerLike(btn, gloss)

	-- dark lip along the bottom: the "3D underside"
	local lip = layer(btn, "UIKitLip")
	lip.AnchorPoint = Vector2.new(0, 1)
	lip.Position = UDim2.fromScale(0, 1)
	lip.Size = UDim2.new(1, 0, 0, if btn.AbsoluteSize.Y < 34 then 4 else 7)
	lip.BackgroundColor3 = C.Ink
	lip.BackgroundTransparency = if style == "light" then 0.85 else 0.62
	cornerLike(btn, lip)

	-- text rides above the gloss / lip / shine with a chunky ink outline (see liftText)
	if btn:IsA("TextButton") and style ~= "close" then
		UIKit.liftText(btn, style ~= "light")
	end
	if style == "close" and btn:IsA("TextButton") then
		btn.TextTransparency = 1
		btn.TextStrokeTransparency = 1
		local x = Instance.new("TextLabel")
		x.Name = "UIKitIcon"
		x.BackgroundTransparency = 1
		x.AnchorPoint = Vector2.new(0.5, 0.5)
		x.Position = UDim2.fromScale(0.5, 0.47)
		x.Size = UDim2.fromScale(0.8, 0.8)
		x.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
		x.Text = "X"
		x.TextScaled = true
		x.TextColor3 = Color3.new(1, 1, 1)
		x.ZIndex = 10
		local xs = Instance.new("UIStroke")
		xs.Thickness = 3
		xs.Color = C.Ink
		xs.Parent = x
		x.Parent = btn
	end

	-- v3: the reference's diagonal light bands across coloured buttons (Skin.stripes' look)
	if style ~= "light" and style ~= "close" then
		local bands = layer(btn, "UIKitStripes")
		bands.Size = UDim2.fromScale(1, 1)
		bands.BackgroundColor3 = Color3.new(1, 1, 1)
		bands.BackgroundTransparency = 0
		local bg = child(bands, "UIGradient", "Bands")
		bg.Rotation = 30
		local keys = { NumberSequenceKeypoint.new(0, 1) }
		for i = 0, 2 do
			local c = (i + 0.5) / 3
			table.insert(keys, NumberSequenceKeypoint.new(c - 0.044, 1))
			table.insert(keys, NumberSequenceKeypoint.new(c - 0.04, 0.82))
			table.insert(keys, NumberSequenceKeypoint.new(c + 0.04, 0.82))
			table.insert(keys, NumberSequenceKeypoint.new(c + 0.044, 1))
		end
		table.insert(keys, NumberSequenceKeypoint.new(1, 1))
		bg.Transparency = NumberSequence.new(keys)
		cornerLike(btn, bands)
	end

	-- shine sweep (coloured buttons big enough to notice)
	if style ~= "light" and style ~= "rarity" and btn.AbsoluteSize.X >= 60 then
		local shine = layer(btn, "UIKitShine")
		shine.Size = UDim2.fromScale(1, 1)
		shine.BackgroundColor3 = Color3.new(1, 1, 1)
		shine.BackgroundTransparency = 0
		local sg = child(shine, "UIGradient", "Band")
		sg.Rotation = 20
		sg.Transparency = NumberSequence.new({ -- v3: a "//" pair (wide + thin), like the reference's glint
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 1),
			NumberSequenceKeypoint.new(0.405, 0.3),
			NumberSequenceKeypoint.new(0.47, 0.3),
			NumberSequenceKeypoint.new(0.475, 1),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(0.505, 0.45),
			NumberSequenceKeypoint.new(0.525, 0.45),
			NumberSequenceKeypoint.new(0.53, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		sg.Offset = Vector2.new(-1.2, 0)
		cornerLike(btn, shine)
		shineButtons[btn] = true
	end

	-- motion: bounce + tilt on hover, squish on press
	local scale = btn:FindFirstChildOfClass("UIScale")
	local ownScale = scale == nil
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = btn
	end
	local base = scale.Scale
	local function current(): number
		return if ownScale then 1 else base
	end
	btn.MouseEnter:Connect(function()
		hovered[btn] = true
		if not ownScale then
			base = scale.Scale
		end
		tween(scale, 0.22, { Scale = current() * 1.06 }, Enum.EasingStyle.Back) -- v3: grow only (no tilt), like Skin
	end)
	btn.MouseLeave:Connect(function()
		hovered[btn] = nil
		tween(scale, 0.25, { Scale = current() }, Enum.EasingStyle.Back)
		tween(btn, 0.2, { Rotation = 0 })
	end)
	btn.MouseButton1Down:Connect(function()
		hovered[btn] = true
		tween(scale, 0.07, { Scale = current() * 0.9 })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(scale, 0.3, { Scale = current() * (if btn.GuiState == Enum.GuiState.Hover then 1.06 else 1) }, Enum.EasingStyle.Back)
	end)
	btn.Activated:Connect(function(input: InputObject?)
		UIKit.sweep(btn)
		-- v3: the same press ripple as Skin buttons (Skin is looked up lazily; it never requires UIKit)
		local sk = script.Parent:FindFirstChild("Skin")
		if sk and style ~= "close" then
			local at = if input and input.Position then Vector2.new(input.Position.X, input.Position.Y) else nil
			;(require(sk) :: any).ripple(btn, at)
		end
	end)

	if ownScale and style ~= "light" and isPrimary(btn) then
		pulseButtons[btn] = { scale = scale, base = 1 }
	end
	btn.Destroying:Connect(function()
		shineButtons[btn] = nil
		pulseButtons[btn] = nil
		hovered[btn] = nil
	end)
end

-- one shine pass across a button
function UIKit.sweep(btn: GuiObject)
	local shine = btn:FindFirstChild("UIKitShine")
	local band = shine and shine:FindFirstChild("Band") :: UIGradient?
	if band then
		band.Offset = Vector2.new(-1.2, 0)
		tween(band, 0.55, { Offset = Vector2.new(1.2, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end

-- ambient motion: shines every few seconds (staggered), primary buttons breathe
local nextShine: { [GuiObject]: number } = {}
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for btn in shineButtons do
		local due = nextShine[btn]
		if not due then
			nextShine[btn] = now + 1 + math.random() * 4
		elseif now >= due then
			nextShine[btn] = now + 3.5 + math.random() * 3
			if btn.Visible and not hovered[btn] then
				UIKit.sweep(btn)
			end
		end
	end
	for btn, p in pulseButtons do
		if not hovered[btn] and btn.Visible then
			p.scale.Scale = p.base * (1 + 0.035 * math.sin(now * 4.5))
		end
	end
end)

------------------------------------------------------------------ surfaces
-- navy checker panel (the Figma "Panel" body)
function UIKit.skinPanel(frame: GuiObject)
	if frame:GetAttribute("UIKit") then
		return
	end
	frame:SetAttribute("UIKit", "Panel")
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	local g = frame:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new(C.PanelTop, C.PanelBottom)
	g.Rotation = 90
	g.Parent = frame
	UIKit.corner(frame, if frame.AbsoluteSize.Y < 80 then 14 else 20)
	UIKit.outline(frame, if frame.AbsoluteSize.X < 300 then 4 else 5)
	UIKit.checker(frame, 0.97) -- v3: the body pattern is nearly gone (plain charcoal)
end

-- tiled checker overlay under the element's children
function UIKit.checker(frame: GuiObject, transparency: number)
	local ch = frame:FindFirstChild("UIKitChecker") :: ImageLabel?
	if not ch then
		local img = Instance.new("ImageLabel")
		img.Name = "UIKitChecker"
		img.BackgroundTransparency = 1
		img.Image = UIKit.Assets.Checker
		img.ScaleType = Enum.ScaleType.Tile
		img.TileSize = UDim2.fromOffset(34, 34)
		img.Size = UDim2.fromScale(1, 1)
		img.ZIndex = 0
		img.Interactable = false
		img.Parent = frame
		ch = img
	end
	(ch :: ImageLabel).ImageTransparency = transparency
	cornerLike(frame, ch :: ImageLabel)
end

-- coloured bar / banner (headers, ribbons): gradient + checker + gloss
function UIKit.skinColored(frame: GuiObject, squareOff: boolean?)
	if frame:GetAttribute("UIKit") then
		return
	end
	frame:SetAttribute("UIKit", "Colored")
	if squareOff then
		UIKit.shade(frame, 0.82, 0.74) -- continues the parent's gradient below its rounded corners
	else
		UIKit.shade(frame, 1.05, 0.72)
	end
	UIKit.checker(frame, 0.88)
end

-- light inner card (rows, slots, answer cards): keep it light, give it the ink outline + soft shading;
-- a card with a coloured outline (rarity) is filled with that colour instead
function UIKit.skinCard(frame: GuiObject)
	if frame:GetAttribute("UIKit") then
		return
	end
	local accent = UIKit.accentOf(frame)
	frame:SetAttribute("UIKit", if accent then "Rarity" else "Card")
	UIKit.corner(frame, 12)
	if accent then
		UIKit.rarityFill(frame, accent)
	else
		UIKit.shade(frame, 1, 0.9)
	end
	UIKit.outline(frame, 3)
end

-- the colour an element's outline was carrying (rarity / category), if any
function UIKit.accentOf(obj: GuiObject): Color3?
	local s = obj:FindFirstChildOfClass("UIStroke")
	if s and s.Enabled and UIKit.saturation(s.Color) > 0.3 and UIKit.luminance(s.Color) > 0.12 then
		return s.Color
	end
	return nil
end

-- Figma "Item Card" fill: a light-to-deep gradient of the accent colour with the checker over it
function UIKit.rarityFill(obj: GuiObject, accent: Color3)
	local h, s, v = accent:ToHSV()
	local light = Color3.fromHSV(h, s * 0.55, math.min(1, v * 1.15 + 0.1))
	local deep = Color3.fromHSV(h, math.min(1, s * 1.05), v * 0.72)
	obj:SetAttribute("UIKitAccent", accent)
	local g = obj:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new(light, deep)
	g.Rotation = 90
	g.Parent = obj
	UIKit.checker(obj, 0.86)
end

-- text sitting directly on a navy panel: white / soft lavender with an ink outline
function UIKit.textOnDark(label: TextLabel | TextButton | TextBox)
	local l = UIKit.luminance(label.TextColor3)
	if l < 0.3 then
		label.TextColor3 = C.Text
	elseif l < 0.62 then
		label.TextColor3 = C.TextSoft
	end
	-- chunky outline like the Figma kit (a real UIStroke; labels that already have one keep theirs)
	if not label:FindFirstChildOfClass("UIStroke") then
		local s = Instance.new("UIStroke")
		s.Name = "UIKitTextStroke"
		s.Color = C.Ink
		s.Thickness = if label.AbsoluteSize.Y > 28 then 2 else 1.25
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.Parent = label
	end
	label.TextStrokeTransparency = 1
end

------------------------------------------------------------------ moments
-- panel pop-in. Panels whose script already owns a UIScale (fit-to-screen / their own open animation)
-- are left alone, so the two animations never fight.
function UIKit.popIn(obj: GuiObject)
	local s = obj:FindFirstChildOfClass("UIScale")
	if s and s.Name ~= "UIKitScale" then
		return
	end
	if not s then
		s = Instance.new("UIScale")
		s.Name = "UIKitScale"
		s.Parent = obj
	end
	local scale = s :: UIScale
	scale.Scale = 0.72
	tween(scale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- spinning sunburst behind something exciting (rewards, big wins); returns it so callers can remove it
function UIKit.burst(parent: GuiObject, color: Color3?, size: number?): ImageLabel
	local rays = Instance.new("ImageLabel")
	rays.Name = "UIKitBurst"
	rays.BackgroundTransparency = 1
	rays.Image = UIKit.Assets.Rays
	rays.ImageColor3 = color or C.Gold
	rays.ImageTransparency = 0.35
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromOffset(size or 220, size or 220)
	rays.ZIndex = 0
	rays.Interactable = false
	rays.Parent = parent
	task.spawn(function()
		while rays.Parent do
			rays.Rotation = (rays.Rotation + RunService.RenderStepped:Wait() * 40) % 360
		end
	end)
	return rays
end

return UIKit
