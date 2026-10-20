--!strict
-- Big Case Belt, client side (server: Server.BigCaseService, tuning: Config.BigCase).
--   * moves the gold VIP clients along the hub conveyor smoothly (the server owns where they are:
--     From + direction * Speed * (serverTime - RideStart), or StopAt once grabbed) and animates them
--   * scrolls the belt's slats (BigCaseBelt.Slats, any parts) and shows the countdown above the belt
--   * the siren banner before a wave, toasts, and the showdown screen with its three minigames:
--     Mash (tap OBJECTION! fastest), Snap (find the evidence card first), Gavel (stop the needle
--     closest to the middle)

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Puppet = require(Shared:WaitForChild("Puppet") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any
local BigCase = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BigCase") :: RemoteEvent

local CFG = Config.BigCase
local player = Players.LocalPlayer
local TAG = "BigCaseClient"

-- Same cartoon palette as the HUD.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local RED = Color3.fromRGB(240, 70, 70)
local GOLD = Color3.fromRGB(255, 200, 40)
local BLUE = Color3.fromRGB(60, 150, 255)
local CREAM = Color3.fromRGB(255, 248, 230)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium)
local RIVAL_COLORS = { ORANGE, BLUE, Color3.fromRGB(190, 90, 255), Color3.fromRGB(255, 90, 160) }

local function now(): number
	return workspace:GetServerTimeNow()
end

---------------------------------------------------------------- sounds (shared balanced catalogue)
local function play(name: string)
	local cue = ({ siren = "courtAlert", win = "caseComplete", gavel = "gavel", tap = "clickBright", wrong = "error" })[name]
	if cue then
		Sfx.play(cue, { gap = if name == "tap" then 0.12 else 0.2, volume = if name == "tap" then 0.7 else 1 })
	end
end

---------------------------------------------------------------- UI helpers
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

local function stroke(thickness: number, color: Color3?): UIStroke
	return make("UIStroke", { Color = color or BLACK, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or INK
	return make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
end

-- White text with a thick black outline (the game's "important text" look).
local function loud(props: { [string]: any }, maxSize: number, outline: number?): TextLabel
	props.TextColor3 = props.TextColor3 or WHITE
	local label = text(props, maxSize)
	make("UIStroke", { Color = BLACK, Thickness = outline or 3, LineJoinMode = Enum.LineJoinMode.Round, Parent = label })
	return label
end

local function pop(object: GuiObject, from: number?)
	local scale = object:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = object })
	scale.Scale = from or 0.5
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local gui = make("ScreenGui", {
	Name = "BigCase",
	ResetOnSpawn = false,
	DisplayOrder = 30,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

---------------------------------------------------------------- siren banner + toasts
local banner = make("Frame", {
	Name = "Banner",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.new(0.9, 0, 0, 62),
	BackgroundColor3 = GOLD,
	Visible = false,
	Parent = gui,
}, { corner(18), stroke(4), make("UISizeConstraint", { MaxSize = Vector2.new(460, 62) }) })
local bannerTitle = loud({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 32), Text = "", FontFace = TITLE, Parent = banner }, 28)
local bannerSub = text({ Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 20), Text = "", FontFace = BODY, Parent = banner }, 18)

local toast = make("Frame", {
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -150),
	Size = UDim2.new(0.9, 0, 0, 54),
	BackgroundColor3 = CREAM,
	Visible = false,
	Parent = gui,
}, { corner(16), stroke(4), make("UISizeConstraint", { MaxSize = Vector2.new(520, 54) }) })
local toastText = text({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 1, -12), Text = "", Parent = toast }, 24)
local toastToken = 0
local function showToast(message: string, color: Color3?, seconds: number?)
	toastToken += 1
	local token = toastToken
	toast.BackgroundColor3 = color or CREAM
	toastText.Text = message
	toast.Visible = true
	pop(toast, 0.7)
	task.delay(seconds or 3, function()
		if toastToken == token then
			toast.Visible = false
		end
	end)
end

---------------------------------------------------------------- the belt: countdown sign + slats
local function beltModel(): Model?
	local hub = workspace:FindFirstChild("Hub")
	local model = hub and hub:FindFirstChild("BigCaseBelt")
	return if model and model:IsA("Model") then model else nil
end

local function markers(): (BasePart?, BasePart?)
	local model = beltModel()
	local a = model and model:FindFirstChild("BeltStart", true)
	local b = model and model:FindFirstChild("BeltEnd", true)
	if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
		return a, b
	end
	return nil, nil
end

local signGui: BillboardGui? = nil
local signTitle: TextLabel? = nil
local signTime: TextLabel? = nil
local function ensureSign()
	if signGui and signGui.Parent then
		return
	end
	local a, b = markers()
	if not a or not b then
		return
	end
	local anchor = make("Part", {
		Name = "BigCaseSignAnchor",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one,
		Position = (a.Position + b.Position) / 2 + Vector3.new(0, 11, 0),
		Parent = workspace,
	})
	local g = make("BillboardGui", { Size = UDim2.fromOffset(240, 84), AlwaysOnTop = false, MaxDistance = 160, LightInfluence = 0, Parent = anchor })
	local back = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.1, Parent = g }, { corner(16), stroke(4, GOLD) })
	signTitle = loud({ Position = UDim2.fromScale(0.04, 0.06), Size = UDim2.fromScale(0.92, 0.45), Text = "BIG CASES", TextColor3 = GOLD, FontFace = TITLE, Parent = back }, 34)
	signTime = loud({ Position = UDim2.fromScale(0.04, 0.52), Size = UDim2.fromScale(0.92, 0.4), Text = "", Parent = back }, 28)
	signGui = g
end

type Slat = { part: BasePart, offset: number, base: CFrame }
local slats: { Slat } = {}
local slatModel: Model? = nil
local slatCount = -1
local function collectSlats()
	local model = beltModel()
	local folder = model and model:FindFirstChild("Slats")
	-- with streaming, the slats can arrive after the belt model: re-collect whenever their count changes
	local count = if folder then #folder:GetChildren() else -1
	if model == slatModel and count == slatCount then
		return
	end
	slatModel = model
	slatCount = count
	table.clear(slats)
	local a, b = markers()
	if not folder or not a or not b then
		return
	end
	local dir = (b.Position - a.Position).Unit
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") then
			local along = (part.Position - a.Position):Dot(dir)
			table.insert(slats, { part = part, offset = along, base = part.CFrame - dir * along })
		end
	end
end

---------------------------------------------------------------- the VIP clients on the belt
type Rider = { model: Model, anim: any?, lift: number, cheered: boolean, fading: boolean }
local riders: { [Model]: Rider } = {}

local function riderPosition(model: Model): Vector3?
	local stop = model:GetAttribute("StopAt")
	if typeof(stop) == "Vector3" then
		return stop
	end
	local from, to = model:GetAttribute("From"), model:GetAttribute("To")
	local start, speed = model:GetAttribute("RideStart"), model:GetAttribute("Speed")
	if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" or typeof(start) ~= "number" or typeof(speed) ~= "number" then
		return nil
	end
	local offset = to - from
	local travelled = math.clamp((now() - start) * speed, 0, offset.Magnitude)
	return from + offset.Unit * travelled
end

local function addRider(model: Instance)
	if not model:IsA("Model") or riders[model] then
		return
	end
	local rider: Rider = { model = model, anim = nil, lift = model:GetAttribute("Lift") or 0, cheered = false, fading = false }
	local ok, anim = pcall(function()
		return Puppet.animator(Puppet.new(model), "client")
	end)
	if ok then
		rider.anim = anim
		anim:play("cheer")
	end
	riders[model] = rider
end

local function fade(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			TweenService:Create(d, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		end
	end
	local tag = model:FindFirstChild("BigCaseTag", true)
	if tag and tag:IsA("BillboardGui") then
		tag.Enabled = false
	end
	local glow = model:FindFirstChildOfClass("Highlight")
	if glow then
		glow.Enabled = false
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(addRider)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(model)
	riders[model :: Model] = nil
end)
for _, model in CollectionService:GetTagged(TAG) do
	addRider(model)
end

---------------------------------------------------------------- showdown screen
local dim = make("Frame", {
	Name = "Showdown",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = BLACK,
	BackgroundTransparency = 0.45,
	Visible = false,
	Active = true, -- swallow clicks meant for the world
	Parent = gui,
})
local card = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 420),
	BackgroundColor3 = CREAM,
	Parent = dim,
}, { corner(26), stroke(5) })
local cardScale = make("UIScale", { Parent = card })
local function fitCard()
	local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	cardScale.Scale = math.min(1, (view.X - 24) / 560, (view.Y - 24) / 420)
end
fitCard()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCard)
end

local prizeBadge = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(240, 46), BackgroundColor3 = GOLD, Parent = card }, { corner(14), stroke(4) })
local prizeText = loud({ Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 1, -8), Text = "BIG CASE!", FontFace = TITLE, Parent = prizeBadge }, 30)
local vsRow = make("Frame", { Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 92), BackgroundTransparency = 1, Parent = card }, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local stage = make("Frame", { Name = "Stage", Position = UDim2.fromOffset(16, 134), Size = UDim2.new(1, -32, 1, -150), BackgroundTransparency = 1, Parent = card })
local splash = loud({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 130), Text = "OBJECTION!", TextColor3 = RED, FontFace = TITLE, Visible = false, ZIndex = 10, Parent = dim }, 110, 6)

type Active = {
	id: number,
	game: string,
	startAt: number,
	players: { { [string]: any } },
	colors: { [number]: Color3 },
	done: boolean,
	cleanup: { () -> () },
	myTaps: number,
	scores: { [string]: number },
	cards: { number }?,
	revealed: boolean,
	lockedUntil: number,
	pressed: boolean,
	period: number,
	duration: number,
	-- set by the minigame that's running
	redraw: (() -> ())?,
	onReveal: ((number) -> ())?,
	onWrong: ((number) -> ())?,
	onStop: ((number, number) -> ())?,
}
local active: Active? = nil

local ACTION = "BigCaseShowdownAction"
local function bindAction(fn: () -> ())
	ContextActionService:BindActionAtPriority(ACTION, function(_, state)
		if state == Enum.UserInputState.Begin then
			fn()
		end
		return Enum.ContextActionResult.Sink -- so Space doesn't also jump
	end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

local function clearStage()
	for _, child in stage:GetChildren() do
		child:Destroy()
	end
end

local function closeShowdown()
	ContextActionService:UnbindAction(ACTION)
	if active then
		for _, fn in active.cleanup do
			fn()
		end
	end
	active = nil
	dim.Visible = false
	splash.Visible = false
	clearStage()
end

local function playerTile(info: { [string]: any }, color: Color3, order: number)
	local tile = make("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(150, 88), BackgroundColor3 = color, Parent = vsRow }, { corner(16), stroke(3) })
	local face = make("ImageLabel", { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = WHITE, Image = "", Parent = tile }, { corner(28), stroke(2) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(info.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then
			face.Image = image
		end
	end)
	loud({ Position = UDim2.fromOffset(66, 8), Size = UDim2.fromOffset(78, 52), Text = if info.userId == player.UserId then "YOU" else info.name, TextXAlignment = Enum.TextXAlignment.Left, Parent = tile }, 24)
	loud({ Position = UDim2.fromOffset(6, 64), Size = UDim2.fromOffset(138, 20), Text = info.name, FontFace = BODY, Parent = tile }, 14, 2)
end

local function bigButton(label: string, color: Color3, position: UDim2, size: Vector2): TextButton
	local button = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = color,
		Text = "",
		AutoButtonColor = true,
		Parent = stage,
	}, { corner(22), stroke(5) })
	loud({ Size = UDim2.fromScale(1, 1), Text = label, FontFace = TITLE, Parent = button }, 46, 4)
	return button
end

local function squish(object: GuiObject)
	local scale = object:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = object })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end

---------------------------------------------------------------- minigame: Objection Mash
local function buildMash(sd: Active)
	local timer = loud({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(200, 34), Text = "", Parent = stage }, 30)
	local bars: { [string]: { fill: Frame, count: TextLabel } } = {}
	local rows = make("Frame", { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, Parent = stage }, {
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, info in sd.players do
		local row = make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = WHITE, Parent = rows }, { corner(10), stroke(3) })
		local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = sd.colors[info.userId], Parent = row }, { corner(10) })
		loud({ Position = UDim2.fromOffset(10, 3), Size = UDim2.new(0.6, 0, 1, -6), Text = if info.userId == player.UserId then "YOU" else info.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = row }, 20, 2)
		local count = loud({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 3), Size = UDim2.fromOffset(80, 24), Text = "0", TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2, Parent = row }, 20, 2)
		bars[tostring(info.userId)] = { fill = fill, count = count }
	end
	local button = bigButton("OBJECTION!", RED, UDim2.new(0.5, 0, 1, -50), Vector2.new(300, 90))
	button:SetAttribute("NoClick", true) -- the timed tap has its own short cue
	text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(300, 16), Text = "TAP! (or mash SPACE)", FontFace = BODY, ZIndex = 2, Parent = stage }, 14)

	local function redraw()
		local top = 1
		for _, n in sd.scores do
			top = math.max(top, n)
		end
		top = math.max(top, sd.myTaps)
		for key, bar in bars do
			local n = sd.scores[key] or 0
			if key == tostring(player.UserId) then
				n = math.max(n, sd.myTaps)
			end
			bar.count.Text = tostring(n)
			bar.fill:TweenSize(UDim2.fromScale(math.clamp(n / top, 0, 1), 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.12, true)
		end
	end
	local function tap()
		local t = now()
		if sd.done or t < sd.startAt or t > sd.startAt + sd.duration then
			return
		end
		sd.myTaps += 1
		BigCase:FireServer("Tap", sd.id)
		squish(button)
		play("tap")
		redraw()
	end
	button.Activated:Connect(tap)
	bindAction(tap)
	local conn = RunService.RenderStepped:Connect(function()
		local left = sd.startAt + sd.duration - now()
		timer.Text = if left > 0 then clock(left) else "TIME!"
	end)
	table.insert(sd.cleanup, function()
		conn:Disconnect()
	end)
	sd.redraw = redraw
end

---------------------------------------------------------------- minigame: Evidence Snap
local function buildSnap(sd: Active)
	local deck = CFG.Snap.Deck
	local prompt = loud({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, 0, 0, 40), Text = "GET READY...", Parent = stage }, 32)
	local grid = make("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1, Parent = stage }, {
		make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0.5, -6), CellPadding = UDim2.fromOffset(10, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local lockLabel = loud({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(320, 60), Text = "", TextColor3 = RED, FontFace = TITLE, Visible = false, ZIndex = 5, Parent = stage }, 44, 4)
	local buttons: { TextButton } = {}
	for index, cardId in sd.cards or {} do
		local info = deck[cardId]
		local b = make("TextButton", { LayoutOrder = index, BackgroundColor3 = WHITE, Text = "", AutoButtonColor = true, Parent = grid }, { corner(14), stroke(4) })
		text({ Position = UDim2.fromScale(0, 0.04), Size = UDim2.fromScale(1, 0.62), Text = info.Icon, Parent = b }, 54)
		text({ Position = UDim2.fromScale(0.05, 0.66), Size = UDim2.fromScale(0.9, 0.28), Text = info.Name, Parent = b }, 20)
		b.Activated:Connect(function()
			if sd.done or now() < sd.lockedUntil then
				return
			end
			squish(b)
			BigCase:FireServer("Snap", sd.id, index)
		end)
		buttons[index] = b
	end
	sd.onReveal = function(target: number)
		local info = deck[target]
		prompt.Text = "FIND: " .. info.Icon .. " " .. info.Name .. "!"
		prompt.TextColor3 = GOLD
		pop(prompt, 0.6)
		play("gavel")
	end
	sd.onWrong = function(untilTime: number)
		sd.lockedUntil = untilTime
		play("wrong")
		lockLabel.Text = if sd.revealed then "WRONG!" else "TOO EARLY!"
		lockLabel.Visible = true
		pop(lockLabel, 0.6)
		for _, b in buttons do
			b.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
		end
		task.delay(math.max(0, untilTime - now()), function()
			lockLabel.Visible = false
			for _, b in buttons do
				b.BackgroundColor3 = WHITE
			end
		end)
	end
	local conn = RunService.RenderStepped:Connect(function()
		if not sd.revealed and now() >= sd.startAt then
			prompt.Text = "WAIT FOR IT..."
		end
	end)
	table.insert(sd.cleanup, function()
		conn:Disconnect()
	end)
end

---------------------------------------------------------------- minigame: Gavel Timing
local function gavelPos(sd: Active, t: number): number
	local u = ((t - sd.startAt) / sd.period) % 1
	return 1 - 2 * math.abs(2 * u - 1)
end

local function buildGavel(sd: Active)
	local info = loud({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, 0, 0, 34), Text = "STOP THE GAVEL IN THE GREEN!", Parent = stage }, 26)
	local meter = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.new(1, -20, 0, 54), BackgroundColor3 = WHITE, Parent = stage }, { corner(14), stroke(4) })
	-- red at the edges, then yellow, and a thin green bullseye in the middle
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, RED),
			ColorSequenceKeypoint.new(0.3, GOLD),
			ColorSequenceKeypoint.new(0.44, GOLD),
			ColorSequenceKeypoint.new(0.45, GREEN),
			ColorSequenceKeypoint.new(0.55, GREEN),
			ColorSequenceKeypoint.new(0.56, GOLD),
			ColorSequenceKeypoint.new(0.7, GOLD),
			ColorSequenceKeypoint.new(1, RED),
		}),
		Parent = meter,
	})
	local function needle(color: Color3, width: number): Frame
		return make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, width, 1, 18), BackgroundColor3 = color, ZIndex = 3, Parent = meter }, { corner(4), stroke(2) })
	end
	local mine = needle(WHITE, 10)
	local markers: { [number]: Frame } = {}
	local button = bigButton("STOP!", GREEN, UDim2.new(0.5, 0, 1, -50), Vector2.new(260, 86))
	local function press()
		if sd.done or sd.pressed or now() < sd.startAt then
			return
		end
		sd.pressed = true
		local t = now()
		BigCase:FireServer("Gavel", sd.id, t)
		play("gavel")
		squish(button)
		mine.Position = UDim2.fromScale((gavelPos(sd, t) + 1) / 2, 0.5)
		info.Text = "WAITING FOR THE OTHERS..."
		button.BackgroundColor3 = Color3.fromRGB(170, 170, 182)
	end
	button.Activated:Connect(press)
	bindAction(press)
	sd.onStop = function(userId: number, pos: number)
		if userId == player.UserId then
			mine.Position = UDim2.fromScale((pos + 1) / 2, 0.5)
			return
		end
		local mark = markers[userId] or needle(sd.colors[userId] or ORANGE, 8)
		markers[userId] = mark
		mark.Position = UDim2.fromScale((pos + 1) / 2, 0.5)
	end
	local conn = RunService.RenderStepped:Connect(function()
		local t = now()
		if not sd.pressed then
			mine.Position = UDim2.fromScale((if t >= sd.startAt then gavelPos(sd, t) else -1) * 0.5 + 0.5, 0.5)
		end
	end)
	table.insert(sd.cleanup, function()
		conn:Disconnect()
	end)
end

local INSTRUCTIONS = {
	Mash = "TAP AS FAST AS YOU CAN!",
	Snap = "FIND THE EVIDENCE FIRST!",
	Gavel = "STOP THE GAVEL IN THE MIDDLE!",
}
local GAME_NAMES = { Mash = "OBJECTION MASH", Snap = "EVIDENCE SNAP", Gavel = "GAVEL TIMING" }

local function openShowdown(payload: { [string]: any })
	closeShowdown()
	local sd: Active = {
		id = payload.id,
		game = payload.game,
		startAt = payload.startAt,
		players = payload.players,
		colors = {},
		done = false,
		cleanup = {},
		myTaps = 0,
		scores = {},
		cards = payload.cards,
		revealed = false,
		lockedUntil = 0,
		pressed = false,
		period = payload.period or 1.4,
		duration = payload.duration or 6,
		redraw = nil,
		onReveal = nil,
		onWrong = nil,
		onStop = nil,
	}
	active = sd
	local rival = 0
	for _, info in sd.players do
		if info.userId == player.UserId then
			sd.colors[info.userId] = GREEN
		else
			rival += 1
			sd.colors[info.userId] = RIVAL_COLORS[((rival - 1) % #RIVAL_COLORS) + 1]
		end
	end
	for _, child in vsRow:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, info in sd.players do
		if i > 1 then
			loud({ LayoutOrder = i * 2 - 1, Size = UDim2.fromOffset(44, 60), Text = "VS", FontFace = TITLE, TextColor3 = RED, Parent = vsRow }, 40, 3)
		end
		playerTile(info, sd.colors[info.userId], i * 2)
	end
	prizeBadge.BackgroundColor3 = payload.prize and payload.prize.color or GOLD
	prizeText.Text = (payload.prize and payload.prize.name or "BIG CASE") .. "!"
	clearStage()
	dim.Visible = true
	pop(card, 0.6)

	-- intro: OBJECTION! then the game's name and how to play
	splash.Text = "OBJECTION!"
	splash.TextColor3 = RED
	splash.Visible = true
	pop(splash, 0.3)
	play("gavel")
	local intro = loud({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.new(1, 0, 0, 54), Text = GAME_NAMES[sd.game] or "", TextColor3 = GOLD, FontFace = TITLE, Parent = stage }, 48, 4)
	text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.65), Size = UDim2.new(1, 0, 0, 34), Text = INSTRUCTIONS[sd.game] or "", Parent = stage }, 28)
	task.delay(0.9, function()
		if active == sd then
			splash.Visible = false
			pop(intro, 0.6)
		end
	end)
	task.delay(math.max(0, sd.startAt - now() - 0.1), function()
		if active ~= sd then
			return
		end
		clearStage()
		if sd.game == "Mash" then
			buildMash(sd)
		elseif sd.game == "Snap" then
			buildSnap(sd)
		elseif sd.game == "Gavel" then
			buildGavel(sd)
		end
	end)
end

local function showResult(payload: { [string]: any })
	local sd = active
	if not sd or sd.id ~= payload.id then
		return
	end
	sd.done = true
	ContextActionService:UnbindAction(ACTION)
	local won = payload.winner == player.UserId
	clearStage()
	splash.Text = if won then "YOU WIN!" elseif payload.winnerName then (string.upper(payload.winnerName) .. " WINS!") else "NO WINNER"
	splash.TextColor3 = if won then GOLD else RED
	splash.Visible = true
	pop(splash, 0.3)
	loud({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(1, 0, 0, 44),
		Text = if won then payload.text else ("You still got " .. (payload.consolation or "a tip") .. " for trying!"),
		TextColor3 = if won then GOLD else WHITE,
		Parent = stage,
	}, 34)
	play(if won then "win" else "wrong")
	task.delay(CFG.ResultTime, function()
		if active == sd then
			closeShowdown()
		end
	end)
end

---------------------------------------------------------------- remote events
local waveToken = 0
BigCase.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
	if kind == "Wave" then
		waveToken += 1
		local token = waveToken
		play("siren")
		banner.Visible = true
		pop(banner, 0.6)
		task.spawn(function()
			while waveToken == token do
				local left = payload.at - now()
				if left > 0 then
					bannerTitle.Text = "BIG CASES INCOMING!"
					bannerSub.Text = "Run to the Big Cases belt at the bottom of the hub! " .. clock(left)
				elseif left > -16 then
					bannerTitle.Text = "BIG CASES ON THE BELT!"
					bannerSub.Text = "Grab a gold client before someone else does!"
				else
					break
				end
				task.wait(0.2)
			end
			if waveToken == token then
				banner.Visible = false
			end
		end)
	elseif kind == "Note" then
		showToast(payload.text)
	elseif kind == "Won" then
		play("win")
		showToast("YOU WON THE " .. (payload.prize and payload.prize.name or "BIG CASE") .. "!  " .. payload.text, GOLD, 4)
	elseif kind == "Start" then
		openShowdown(payload)
	elseif kind == "Mash" then
		if active and active.id == payload.id then
			active.scores = payload.scores
			if active.redraw then
				active.redraw()
			end
		end
	elseif kind == "SnapReveal" then
		if active and active.id == payload.id then
			active.revealed = true
			if active.onReveal then
				active.onReveal(payload.target)
			end
		end
	elseif kind == "SnapWrong" then
		if active and active.id == payload.id and active.onWrong then
			active.onWrong(payload["until"])
		end
	elseif kind == "GavelStop" then
		if active and active.id == payload.id and active.onStop then
			active.onStop(payload.userId, payload.pos)
		end
	elseif kind == "Result" then
		showResult(payload)
	end
end)

---------------------------------------------------------------- every frame
RunService.RenderStepped:Connect(function()
	local t = now()
	-- the VIPs
	for model, rider in riders do
		if not model.Parent then
			riders[model] = nil
			continue
		end
		local pos = riderPosition(model)
		if pos and rider.anim then
			rider.anim.puppet.base = CFrame.new(pos + Vector3.new(0, rider.lift, 0))
			rider.anim:step(os.clock())
		end
		local state = model:GetAttribute("State")
		if state == "Done" and not rider.cheered then
			rider.cheered = true
			if rider.anim and model:GetAttribute("WinnerName") then
				rider.anim:play("celebrate")
			end
		end
		-- rode into the exit arch, or nobody won it: fade away
		local to = model:GetAttribute("To")
		local ending = state == "Done" and not model:GetAttribute("WinnerName")
		if not ending and state == "Ride" and typeof(to) == "Vector3" and pos then
			ending = (to - pos).Magnitude < 1.5
		end
		if ending and not rider.fading then
			rider.fading = true
			fade(model)
		end
	end
	-- the belt
	collectSlats()
	local a, b = markers()
	if a and b and #slats > 0 then
		local offset = b.Position - a.Position
		local length, dir = offset.Magnitude, offset.Unit
		for _, slat in slats do
			slat.part.CFrame = slat.base + dir * ((slat.offset + t * CFG.BeltSpeed) % length)
		end
	end
	-- the countdown sign
	ensureSign()
	if signTime and signTitle then
		local nextWave = BigCase:GetAttribute("NextWave")
		local waveEnds = BigCase:GetAttribute("WaveEnds")
		if typeof(waveEnds) == "number" and t < waveEnds then
			signTitle.Text = "BIG CASES"
			signTime.Text = "GRAB ONE NOW!"
			signTime.TextColor3 = GOLD
		elseif typeof(nextWave) == "number" then
			signTitle.Text = "NEXT BIG CASES"
			signTime.Text = clock(nextWave - t)
			signTime.TextColor3 = WHITE
		end
	end
end)
