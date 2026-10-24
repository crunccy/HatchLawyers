--!strict
-- Goals card on the right edge: the player's 3 short-term goals with progress bars
-- (server: GoalService, mirrored in the "Goals" attribute). Tap the header to fold it away.
-- Look (UI overhaul part 2, 2026-10-18): a Skin card - charcoal studded body, purple striped header with the glossy
-- Goals icon over its left end; each goal in white stroked text over a real progress bar (black track, lime fill,
-- "2/5" on the bar; gold + DONE! when finished). Opted out of UISkin (NoSkin).

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
local Icons = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("HudMenu")) :: any).Icons
local Skin = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("Skin")) :: any
PANEL = Skin.Panel
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

local W = 250 -- card width
local HEAD_H = 40
local ROW_H = 58
local gui = make("ScreenGui", { Name = "Goals", ResetOnSpawn = false, DisplayOrder = 13, Parent = player:WaitForChild("PlayerGui") })
gui:SetAttribute("NoSkin", true)
local card = make("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, -20),
	Size = UDim2.fromOffset(W, HEAD_H + 10 + ROWS * ROW_H),
	BackgroundColor3 = PANEL,
	Parent = gui,
}, { corner(10), make("UIStroke", { Color = Skin.Ink, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
card:SetAttribute("NoSkin", true)
Skin.studs(card, 0.92, nil, 28)
-- Phones: shrink the card on short screens so it clears the lawyer panel, and start folded on
-- very short ones (tap GOALS to open).
local cardScale = make("UIScale", { Parent = card })
local function fitCard()
	local camera = workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 720
	if height < 200 then
		height = 720 -- not a real screen size yet (or a broken viewport): assume a normal one
	end
	cardScale.Scale = math.clamp(height / 680, 0.58, 1)
end
fitCard()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCard)
end
local purple = Skin.Palette.Purple
local header = make("TextButton", {
	Name = "Header",
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.new(1, -6, 0, HEAD_H),
	BackgroundColor3 = WHITE,
	Text = "",
	AutoButtonColor = false,
	Parent = card,
}, { corner(8), make("UIStroke", { Color = purple.dark, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({ -- the Skin window-header look
		ColorSequenceKeypoint.new(0, purple.light), ColorSequenceKeypoint.new(0.55, purple.base),
		ColorSequenceKeypoint.new(1, purple.base:Lerp(purple.dark, 0.25)),
	}) }) })
Skin.studs(header, 0.86, nil, 22)
Skin.stripes(header, 0.74, 4, 0.06)
make("Frame", { -- ink divider under the header
	Name = "Divider", Position = UDim2.fromOffset(0, HEAD_H + 4), Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Skin.Ink,
	BorderSizePixel = 0, Parent = card,
})
make("ImageLabel", {
	Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 16, 0.5, -3), Size = UDim2.fromOffset(60, 60),
	BackgroundTransparency = 1, Image = Icons.Goals, ScaleType = Enum.ScaleType.Fit, ZIndex = 4, Parent = header,
})
local headerText = Skin.text({ Name = "Title", Position = UDim2.fromOffset(50, 2), Size = UDim2.new(1, -60, 1, -4), Text = "GOALS",
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = header }, 28, 3)
local fold = Skin.text({ Name = "Fold", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(26, 26),
	Text = "-", ZIndex = 3, Parent = header }, 26, 3)

type Row = { frame: Frame, label: TextLabel, fill: Frame, fillGrad: UIGradient, count: TextLabel, last: number? }
local rows: { Row } = {}
local LIME = { Color3.fromRGB(190, 255, 140), Color3.fromRGB(70, 210, 40) }
local GOLDS = { Color3.fromRGB(255, 236, 140), Color3.fromRGB(240, 170, 20) }
for i = 1, ROWS do
	local frame = make("Frame", { Name = "Goal" .. i, Position = UDim2.fromOffset(12, HEAD_H + 12 + (i - 1) * ROW_H), Size = UDim2.new(1, -24, 0, ROW_H - 6),
		BackgroundTransparency = 1, Parent = card })
	local label = Skin.text({ Name = "Text", FontFace = Skin.Fonts.Body, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame }, 18, 2)
	local track = make("Frame", { Name = "Track", Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = TRACK,
		Parent = frame }, { corner(10), stroke(3) })
	local fill = make("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track }, { corner(10) })
	local fillGrad = make("UIGradient", { Rotation = 90, Color = ColorSequence.new(LIME[1], LIME[2]), Parent = fill })
	make("Frame", { Name = "Shine", Position = UDim2.new(0, 4, 0, 3), Size = UDim2.new(1, -8, 0.32, 0), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = fill }, { corner(4) })
	local count = Skin.text({ Name = "Count", Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 3, Parent = track }, 16, 2)
	rows[i] = { frame = frame, label = label, fill = fill, fillGrad = fillGrad, count = count }
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
			local frac = math.clamp(goal.Progress / math.max(goal.Target, 1), 0, 1)
			local complete = frac >= 1
			row.count.Text = if complete then "DONE!" else string.format("%d/%d", goal.Progress, goal.Target)
			row.fillGrad.Color = if complete then ColorSequence.new(GOLDS[1], GOLDS[2]) else ColorSequence.new(LIME[1], LIME[2])
			TweenService:Create(row.fill, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(frac, 1) }):Play()
			if row.last and goal.Progress > row.last then -- progress made: a little pop on the bar
				Skin.pop(row.fill.Parent :: GuiObject, 0.9)
			end
			row.last = goal.Progress
		end
	end
	card.Size = if folded then UDim2.fromOffset(W, HEAD_H + 6) else UDim2.fromOffset(W, HEAD_H + 10 + ROWS * ROW_H)
	fold.Text = if folded then "+" else "-"
	headerText.Text = "GOALS"
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
