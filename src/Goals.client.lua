--!strict
-- Goals card on the right edge: the player's 3 short-term goals with progress bars
-- (server: GoalService, mirrored in the "Goals" attribute). Tap the header to fold it away.
-- Look (UI pass 2026-10-09): the game's dark studded panel + purple header with the target icon, like the Shop /
-- LAWYERS panels; opted out of UISkin (NoSkin) so it keeps it.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local GREEN = Color3.fromRGB(98, 205, 48)
local TRACK = Color3.fromRGB(24, 22, 36)
local PURPLE = Color3.fromRGB(176, 52, 255)
local PANEL = Color3.fromRGB(46, 44, 66)
local SOFT = Color3.fromRGB(225, 220, 250)
local Icons = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HudMenu")) :: any).Icons
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium) -- descriptions / small print (Shared.UIFonts)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy) -- big moments (Shared.UIFonts)
local ROWS = 3

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(class)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(px: number): UICorner
	return make("UICorner", { CornerRadius = UDim.new(0, px) })
end

local function stroke(thickness: number): UIStroke
	return make("UIStroke", { Color = BLACK, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	return make("TextLabel", props, {
		make("UITextSizeConstraint", { MaxTextSize = maxSize }),
		make("UIStroke", { Color = BLACK, Thickness = if maxSize >= 20 then 2.5 else 1.5, LineJoinMode = Enum.LineJoinMode.Round }),
	})
end

local gui = make("ScreenGui", { Name = "Goals", ResetOnSpawn = false, DisplayOrder = 13, Parent = player:WaitForChild("PlayerGui") })
local card = make("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, -20),
	Size = UDim2.fromOffset(220, 40 + ROWS * 52),
	BackgroundColor3 = PANEL,
	Parent = gui,
}, { corner(14), stroke(4) })
card:SetAttribute("NoSkin", true)
make("ImageLabel", {
	Name = "Studs", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://114488299634202", -- studs (tools/ui_textures.py)
	ImageTransparency = 0.9, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(30, 30), Parent = card,
}, { corner(14) })
-- Phones: shrink the card on short screens so it clears the lawyer panel, and start folded on
-- very short ones (tap GOALS to open).
local cardScale = make("UIScale", { Parent = card })
local function fitCard()
	local camera = workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 720
	if height < 200 then
		height = 720 -- not a real screen size yet (or a broken viewport): assume a normal one
	end
	cardScale.Scale = math.clamp(height / 640, 0.6, 1)
end
fitCard()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCard)
end
local header = make("TextButton", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = WHITE,
	Text = "",
	AutoButtonColor = true,
	Parent = card,
}, { corner(14), stroke(3), make("UIGradient", { Color = ColorSequence.new(PURPLE, Color3.fromRGB(122, 30, 214)) }) })
make("ImageLabel", {
	Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -6, 0.5, -2), Size = UDim2.fromOffset(46, 46),
	BackgroundTransparency = 1, Image = Icons.Goals, ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = header,
})
local headerText = text({ Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -44, 1, 0), FontFace = TITLE, Text = "GOALS", ZIndex = 3, Parent = header }, 24)

type Row = { frame: Frame, label: TextLabel, fill: Frame, count: TextLabel }
local rows: { Row } = {}
for i = 1, ROWS do
	local frame = make("Frame", { Name = "Goal" .. i, Position = UDim2.fromOffset(10, 40 + (i - 1) * 52), Size = UDim2.new(1, -20, 0, 46), BackgroundTransparency = 1, Parent = card })
	local label = text({ FontFace = BODY, Size = UDim2.new(1, 0, 0, 22), TextColor3 = SOFT, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = frame }, 16)
	local track = make("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, -46, 0, 14), BackgroundColor3 = TRACK, Parent = frame }, { corner(7), stroke(2) })
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(92, 240, 60), Parent = track }, {
		corner(7), make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(170, 255, 140), Color3.fromRGB(60, 190, 40)) }),
	})
	local count = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 22), Size = UDim2.fromOffset(42, 22), TextXAlignment = Enum.TextXAlignment.Right, Parent = frame }, 16)
	rows[i] = { frame = frame, label = label, fill = fill, count = count }
end

local folded = false
local function render()
	local raw = player:GetAttribute("Goals")
	local ok, goals = pcall(function()
		return if typeof(raw) == "string" then HttpService:JSONDecode(raw) else {}
	end)
	goals = if ok then goals else {}
	card.Visible = #goals > 0
	for i, row in rows do
		local goal = goals[i]
		row.frame.Visible = goal ~= nil and not folded
		if goal then
			row.label.Text = goal.Text
			row.count.Text = string.format("%d/%d", goal.Progress, goal.Target)
			TweenService:Create(row.fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(math.clamp(goal.Progress / math.max(goal.Target, 1), 0, 1), 1) }):Play()
		end
	end
	card.Size = if folded then UDim2.fromOffset(220, 34) else UDim2.fromOffset(220, 40 + ROWS * 52)
	headerText.Text = if folded then "GOALS +" else "GOALS"
end

header.Activated:Connect(function()
	folded = not folded
	render()
end)
player:GetAttributeChangedSignal("Goals"):Connect(render)
render()
-- the viewport size isn't reliable on the very first frame, so decide about folding a moment later
task.delay(1, function()
	local camera = workspace.CurrentCamera
	if camera and camera.ViewportSize.Y >= 200 and camera.ViewportSize.Y < 420 then
		folded = true
		render()
	end
	fitCard()
end)
