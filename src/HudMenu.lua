--!strict
-- HudMenu (ReplicatedStorage.Shared.HudMenu): the HUD's left-edge menu column and its buttons, in one place
-- (user 2026-10-09: "the ui is cooked" - DAILY / LAWYERS / SHOP were three scripts each guessing a position
-- with different GUI insets, so they piled on top of each other). Every menu button is built here, stacked by
-- one UIListLayout in one ScreenGui, so they can never overlap and always share the same look:
-- chunky rounded tile, colour gradient + studs, a real PNG icon (Creator Store images, see Icons), a LuckiestGuy
-- label, a red count badge (top-right), a yellow "!" alert (top-left) and an optional timer pill underneath.
--   local entry = HudMenu.button({ name = "Lawyers", label = "LAWYERS", icon = "Gavel", color = ..., order = 2 })
--   entry.button.Activated:Connect(...); entry.setBadge("3" | nil); entry.setAlert(true); entry.setNote("6:29" | nil)
--   HudMenu.wait("Lawyers") -> entry (yields until another script made it)
-- Icons is also the game's icon set for other screens (UIKit uses it too).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIFonts = require(script.Parent:WaitForChild("UIFonts")) :: any

local HudMenu = {}

-- Free Creator Store images (decals resolved to their image ids with InsertService). Cartoon, transparent PNGs.
HudMenu.Icons = {
	Gavel = "rbxassetid://18523351330", -- "gavel colored"
	Shop = "rbxassetid://97374789643367", -- striped-awning shop stall
	Cart = "rbxassetid://124554934201130", -- red shopping cart
	Gift = "rbxassetid://114994847107226", -- red gift box, gold bow
	GiftPink = "rbxassetid://114440493073627", -- outlined pink gift
	Coin = "rbxassetid://8875273942", -- stack of outlined cartoon coins ("Coins Cartoon1.V45")
	MoneyBag = "rbxassetid://5636506602",
	Goals = "rbxassetid://12600726983", -- target + arrow ("for in-game quest button")
	Star = "rbxassetid://15589354284", -- glossy yellow star
	Trophy = "rbxassetid://114221933505948", -- outlined cartoon trophy
	Scales = "rbxassetid://135009805354492", -- orange scales of justice
	Travel = "rbxassetid://136144875676517", -- the Travel Portal (art/icons/travel.png, Blender; uploaded by crnuch 2026-10-13)
}
HudMenu.Studs = "rbxassetid://114488299634202" -- tools/ui_textures.py

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromHex("15131C")
-- 2026-10-11 UI pass (user's reference recording): wide buttons - icon on the left poking out a little, big outlined
-- label - instead of square tiles; same top-lit gradient / bevel / lip / soft gloss as Shared.Skin buttons.
local BW, BH = 172, 56
local GAP = 14
local TITLE_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

export type Entry = {
	button: TextButton,
	setBadge: (string?) -> (),
	setAlert: (boolean) -> (),
	setNote: (string?) -> (),
}

local entries: { [string]: Entry } = {}
local added = Instance.new("BindableEvent")
local column: Frame? = nil

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

local function outlinedText(props: { [string]: any }, maxSize: number, thickness: number): TextLabel
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	local l = make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
	make("UIStroke", { Thickness = thickness, Color = BLACK, LineJoinMode = Enum.LineJoinMode.Round, Parent = l })
	return l
end

function HudMenu.icon(name: string): string
	return HudMenu.Icons[name] or name
end

local function getColumn(): Frame
	if column and column.Parent then
		return column
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = make("ScreenGui", { Name = "Menu", ResetOnSpawn = false, DisplayOrder = 5, Parent = playerGui })
	local frame = make("Frame", {
		Name = "Column", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(BW + 16, 10),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
	frame:SetAttribute("NoSkin", true)
	-- phones: the whole column shrinks with the screen height
	local scale = make("UIScale", { Parent = frame })
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = if h < 200 then 1 else math.clamp(h / 720, 0.6, 1)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	column = frame
	return frame
end

-- opts: name, label, icon (HudMenu.Icons key or an image id), color, order
function HudMenu.button(opts: { name: string, label: string, icon: string, color: Color3, order: number }): Entry
	local existing = entries[opts.name]
	if existing then
		return existing
	end
	local parent = getColumn()
	local h, s, v = opts.color:ToHSV()
	local light = Color3.fromHSV(h, s * 0.55, math.min(1, v * 1.15 + 0.08))
	local dark = Color3.fromHSV(h, math.min(1, s * 1.1), v * 0.6)
	local holder = make("Frame", { Name = opts.name, Size = UDim2.fromOffset(BW, BH), BackgroundTransparency = 1, LayoutOrder = opts.order, Parent = parent })
	local scale = make("UIScale", {})
	local button = make("TextButton", {
		Name = opts.name .. "Button", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Text = "", AutoButtonColor = false, Parent = holder,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 10) }),
		make("UIStroke", { Thickness = 4, Color = INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, light), ColorSequenceKeypoint.new(0.5, opts.color), ColorSequenceKeypoint.new(1, opts.color:Lerp(dark, 0.35)),
		}) }),
		scale,
	})
	button:SetAttribute("NoSkin", true)
	make("ImageLabel", {
		Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = HudMenu.Studs, ImageTransparency = 0.86,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(24, 24), Parent = button,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	make("Frame", { Name = "Bevel", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, Parent = button },
		{ make("UICorner", { CornerRadius = UDim.new(0, 8) }), make("UIStroke", { Thickness = 2, Color = light, Transparency = 0.25 }) })
	make("Frame", { Name = "Gloss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 3), Size = UDim2.new(1, -8, 0.45, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = button }, {
		make("UICorner", { CornerRadius = UDim.new(0, 7) }),
		make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.84, 1) }),
	})
	-- bottom lip: the chunky "3D" underside
	make("Frame", { Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 9), BackgroundColor3 = dark, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = button }, { make("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local iconImage = make("ImageLabel", {
		Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -8, 0.5, -2), Size = UDim2.fromOffset(62, 62),
		BackgroundTransparency = 1, Image = HudMenu.icon(opts.icon), ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = button,
	})
	local label = outlinedText({ Name = "Label", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 56, 0.5, -2), Size = UDim2.new(1, -62, 0, 36),
		Text = string.upper(string.sub(opts.label, 1, 1)) .. string.lower(string.sub(opts.label, 2)), FontFace = TITLE_FONT,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = button }, 30, 3)
	label.TextScaled = true
	-- badges
	local badge = make("Frame", { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(235, 40, 40), Visible = false, ZIndex = 5, Parent = holder }, {
		make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 3, Color = WHITE }),
	})
	local badgeText = outlinedText({ Size = UDim2.fromScale(1, 1), Text = "", FontFace = TITLE_FONT, ZIndex = 6, Parent = badge }, 20, 2)
	local alert = make("Frame", { Name = "Alert", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Color3.fromRGB(255, 205, 40), Visible = false, ZIndex = 5, Parent = holder }, {
		make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 3, Color = INK }),
	})
	outlinedText({ Size = UDim2.fromScale(1, 1), Text = "!", FontFace = TITLE_FONT, ZIndex = 6, Parent = alert }, 20, 2)
	-- timer pill hanging off the bottom-right corner (the DAILY playtime gift countdown)
	local note = make("Frame", { Name = "Note", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 1, 0), Size = UDim2.fromOffset(66, 22), BackgroundColor3 = Color3.fromRGB(32, 30, 48), Visible = false, ZIndex = 5, Parent = holder }, {
		make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Thickness = 2, Color = INK }),
	})
	local noteText = outlinedText({ Position = UDim2.fromOffset(4, 1), Size = UDim2.new(1, -8, 1, -2), Text = "", FontFace = UIFonts.PrimaryFace, ZIndex = 6, Parent = note }, 16, 1.5)

	-- motion: bob up on hover, squish on press, wiggle now and then while something waits inside
	local function tw(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
		TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end
	button.MouseEnter:Connect(function()
		tw(scale, 0.2, { Scale = 1.08 }, Enum.EasingStyle.Back)
		tw(iconImage, 0.2, { Rotation = -8 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		tw(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		tw(iconImage, 0.2, { Rotation = 0 })
	end)
	button.MouseButton1Down:Connect(function()
		tw(scale, 0.06, { Scale = 0.9 })
	end)
	button.Activated:Connect(function()
		scale.Scale = 0.88
		tw(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end)

	local entry: Entry = {
		button = button,
		setBadge = function(t: string?)
			badge.Visible = t ~= nil
			badgeText.Text = t or ""
		end,
		setAlert = function(on: boolean)
			alert.Visible = on
			alert.Position = if badge.Visible then UDim2.new(1, -34, 0, 4) else UDim2.new(1, -4, 0, 4)
		end,
		setNote = function(t: string?)
			note.Visible = t ~= nil
			noteText.Text = t or ""
		end,
	}
	entries[opts.name] = entry
	added:Fire(opts.name)
	task.spawn(function()
		while holder.Parent do
			task.wait(3.4)
			if (badge.Visible or alert.Visible) and button.GuiState ~= Enum.GuiState.Hover then
				for _, r in { 10, -9, 6, -4, 0 } do
					tw(button, 0.07, { Rotation = r })
					task.wait(0.07)
				end
			end
		end
	end)
	return entry
end

-- the entry another script made (yields until it exists)
function HudMenu.wait(name: string): Entry
	while not entries[name] do
		added.Event:Wait()
	end
	return entries[name]
end

-- (kept for scripts that want a heartbeat-safe check)
function HudMenu.get(name: string): Entry?
	return entries[name]
end

return HudMenu
