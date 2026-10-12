--!strict
-- Optional mini courtroom. While a case runs, "Attend Court" opens a toy courtroom with one
-- evidence question; the right card earns a small bonus, anything else is the normal payout.
-- The server checks the answer and decides the verdict; this script only shows it.
-- Tutorial: the first case (Neighbor Dave) always goes to court. The courtroom opens by itself a moment
-- after that case starts, with a gold coach banner explaining what's happening (Config.Tutorial).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas"))
local Skin = require(ReplicatedStorage.Shared:WaitForChild("Skin")) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CaseResult = Remotes:WaitForChild("CaseResult") :: RemoteEvent
local AttendCourt = Remotes:WaitForChild("AttendCourt") :: RemoteFunction
local AnswerEvidence = Remotes:WaitForChild("AnswerEvidence") :: RemoteFunction

local player = Players.LocalPlayer
local DESK = 1 -- follows the HUD's selected lawyer (SelectedDesk) while court is closed

-- Cartoony palette (team style guide): toy courtroom, bright colors, thick black outlines,
-- FredokaOne everywhere.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local WALL = Color3.fromRGB(255, 248, 230)
local WOOD = Color3.fromRGB(150, 85, 40)
local WOOD_LIGHT = Color3.fromRGB(214, 140, 70)
local PAPER = Color3.fromRGB(255, 252, 240)
local PURPLE = Color3.fromRGB(140, 80, 230)
local RED = Color3.fromRGB(240, 70, 70)
local GOLD = Color3.fromRGB(255, 200, 40)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium) -- descriptions / small print (Shared.UIFonts)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy) -- big moments (Shared.UIFonts)
local GOOD = Color3.fromRGB(67, 181, 92)
local CALM = Color3.fromRGB(110, 160, 220)
local SKIN = Color3.fromRGB(234, 184, 146)
local VERDICT_STYLE = {
	Win = { title = "WIN!", color = GOOD },
	Settlement = { title = "Settled!", color = Color3.fromRGB(255, 160, 40) },
	Mistrial = { title = "Mistrial!", color = CALM },
}
local ARGUMENTS = {
	{ "lawyer", "Your Honor, the facts are clear!" },
	{ "opponent", "Objection!" },
	{ "judge", "Overruled! ...zzz... huh? Continue." },
	{ "lawyer", "My client deserves justice!" },
	{ "opponent", "That's not what happened!" },
	{ "judge", "Order! ORDER!" },
	{ "lawyer", "The evidence speaks for itself!" },
	{ "opponent", "I... need a minute." },
}

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(class)
	for key, value in props do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function round(scale: number?): UICorner
	return make("UICorner", { CornerRadius = if scale then UDim.new(scale, 0) else UDim.new(0, 12) })
end

local function text(props: { [string]: any }, maxSize: number): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextScaled = true
	props.FontFace = props.FontFace or FONT
	props.TextColor3 = props.TextColor3 or INK
	return make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
end

-- Attend button (its own ScreenGui so it stays visible when the courtroom is closed)
local buttonGui = make("ScreenGui", { Name = "AttendCourt", ResetOnSpawn = false })
local attendButton = make("TextButton", {
	Name = "AttendButton",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24), -- (the HUD's office card under it is gone: LAWYERS panel, 2026-10-09)
	Size = UDim2.fromOffset(250, 48),
	BackgroundColor3 = PURPLE,
	FontFace = FONT,
	TextSize = 24,
	TextColor3 = WHITE,
	TextStrokeTransparency = 0,
	Text = "ATTEND COURT",
	Visible = false,
	Parent = buttonGui,
}, { round(), make("UIStroke", { Color = BLACK, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })

-- Courtroom overlay
-- Above the SKINS screen (15), below the egg hatch (20).
local gui = make("ScreenGui", { Name = "Courtroom", ResetOnSpawn = false, Enabled = false, DisplayOrder = 18 })
local dim = make("TextButton", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	AutoButtonColor = false,
	Text = "",
	Parent = gui,
})
local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.94, 0.9),
	BackgroundColor3 = Skin.Panel, -- Shared.Skin look (2026-10-11 UI pass)
	Active = true, -- sinks taps, so a tap between the cards doesn't fall through to the Dim and close the courtroom
	ClipsDescendants = true,
	Parent = gui,
}, { make("UICorner", { CornerRadius = UDim.new(0, 10) }), make("UISizeConstraint", { MaxSize = Vector2.new(660, 470) }), make("UIStroke", { Color = Skin.Ink, Thickness = 5 }) })
panel:SetAttribute("NoSkin", true)
dim:SetAttribute("NoSkin", true)
dim.BackgroundTransparency = 0.35
Skin.studs(panel, 0.93, nil, 30)
local headerSw = Skin.swatch("Purple")
local headerBar = make("Frame", {
	Name = "Header", Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0.105, -4), BackgroundColor3 = WHITE, Parent = panel,
}, {
	make("UICorner", { CornerRadius = UDim.new(0, 7) }),
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, headerSw.light), ColorSequenceKeypoint.new(0.55, headerSw.base), ColorSequenceKeypoint.new(1, headerSw.base:Lerp(headerSw.dark, 0.25)),
	}) }),
	make("UIStroke", { Thickness = 3, Color = headerSw.dark, Transparency = 0.1 }),
})
Skin.studs(headerBar, 0.86, nil, 22)
Skin.shineBands(headerBar, 0.84)
local title = Skin.text({ Position = UDim2.new(0, 14, 0.1, 0), Size = UDim2.new(0.62, 0, 0.8, 0), Text = "Courtroom", FontFace = FONT,
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = headerBar }, 26, 3)
local verdictTimer = Skin.text({
	Position = UDim2.new(0.64, 0, 0.2, 0),
	Size = UDim2.new(0.36, -60, 0.6, 0),
	FontFace = FONT,
	TextColor3 = Skin.Palette.Gold.light,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 2,
	Parent = headerBar,
}, 18, 2)
local closeButton = Skin.closeButton(headerBar, 44, 3)

-- Scene: bench and judge at the back, the two sides on the floor
local scene = make("Frame", {
	Name = "Scene",
	Position = UDim2.fromScale(0, 0.11),
	Size = UDim2.fromScale(1, 0.48),
	BackgroundTransparency = 1,
	Parent = panel,
})
-- 3D courtroom: ReplicatedStorage.CourtroomSet (modelled in Blender) inside a ViewportFrame, with the
-- real people standing in it (spawnCast below). Spots/<Name> parts in the set mark where everyone goes.
local courtView = make("ViewportFrame", {
	Name = "CourtView",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(205, 228, 255),
	Ambient = Color3.fromRGB(150, 150, 156),
	LightColor = Color3.fromRGB(255, 248, 235),
	LightDirection = Vector3.new(-0.35, -1, 0.55),
	Parent = scene,
}, { round(0.04) })
local courtCamera = Instance.new("Camera")
courtCamera.FieldOfView = 42
courtCamera.Parent = courtView
courtView.CurrentCamera = courtCamera
local cast = Instance.new("Model")
cast.Name = "Cast"
local spots: { [string]: CFrame } = {}

local function loadSet()
	if cast.Parent then
		return
	end
	local template = ReplicatedStorage:FindFirstChild("CourtroomSet")
	if not template then
		return
	end
	local set = template:Clone()
	local markers = set:FindFirstChild("Spots")
	if markers then
		for _, s in markers:GetChildren() do
			if s:IsA("BasePart") then
				spots[s.Name] = s.CFrame
			end
		end
		markers:Destroy()
	end
	set.Parent = courtView
	cast.Parent = courtView
	local eye = if spots.CameraSpot then spots.CameraSpot.Position else Vector3.new(0, 9.5, -21)
	local target = if spots.CameraTarget then spots.CameraTarget.Position else Vector3.new(0, 3.6, 7)
	courtCamera.CFrame = CFrame.lookAt(eye, target)
end

-- Name tags float over each person's head (positioned every frame from the 3D scene).
local function nameTag(value: string): TextLabel
	return text({
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromScale(0.15, 0.08),
		Text = value,
		TextColor3 = WHITE,
		TextStrokeTransparency = 0.15,
		ZIndex = 3,
		Parent = scene,
	}, 14)
end
local lawyerName = nameTag("Your Lawyer")
local clientName = nameTag("Client")
local opponentName = nameTag("Other side")
local judgeName = nameTag("The Judge")

local bubble = text({
	Name = "Bubble",
	Size = UDim2.fromScale(0.36, 0.22),
	BackgroundTransparency = 0,
	BackgroundColor3 = WHITE,
	FontFace = FONT,
	TextWrapped = true,
	Visible = false,
	Parent = scene,
}, 16)
round(0.25).Parent = bubble
make("UIStroke", { Color = BLACK, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bubble })
make("UIPadding", { PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0), PaddingTop = UDim.new(0.08, 0), PaddingBottom = UDim.new(0.08, 0), Parent = bubble })
bubble.ZIndex = 4

-- Who stands where: role -> { model, head top, name tag, animator }. Animation: Shared.Puppet.
local Puppet = require(ReplicatedStorage.Shared:WaitForChild("Puppet")) :: any
type Actor = { model: Model, top: Vector3, tag: TextLabel, anim: any }
local actors: { [string]: Actor } = {}
local bubbleSpeaker: string? = nil

-- Plays an animation on one person in the courtroom (if they're there).
local function react(role: string, clipName: string)
	local actor = actors[role]
	if actor then
		actor.anim:play(clipName)
	end
end

-- What a speaker does while saying a line.
local function clipFor(speaker: string, line: string): string
	local l = string.lower(line)
	if speaker == "judge" then
		if l:find("zzz") or l:find("yawn") then
			return "doze"
		elseif l:find("order") then
			return "lean"
		elseif l:find("sustained") or l:find("interesting") then
			return "nod"
		elseif l:find("overruled") or l:find("too slow") then
			return "shake"
		elseif l:find("decided") then
			return "pointGavel"
		end
		return "judgeTalk"
	elseif speaker == "lawyer" then
		return if l:find("objection") then "objection" else "talk"
	elseif speaker == "opponent" then
		if l:find("objection") or l:find("not what happened") then
			return "protest"
		elseif l:find("minute") then
			return "sweat"
		end
		return "talk"
	end
	return "talk"
end

-- World point -> 0..1 position inside the court view.
local function project(world: Vector3): Vector2?
	local size = courtView.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return nil
	end
	local p = courtCamera.CFrame:PointToObjectSpace(world)
	if p.Z >= 0 then
		return nil
	end
	local t = math.tan(math.rad(courtCamera.FieldOfView / 2))
	local x = p.X / (-p.Z * t * (size.X / size.Y))
	local y = p.Y / (-p.Z * t)
	return Vector2.new((x + 1) / 2, (1 - y) / 2)
end

-- Challenge area
local question = text({ Position = UDim2.fromScale(0.04, 0.6), Size = UDim2.fromScale(0.92, 0.1), FontFace = Skin.Fonts.Heavy, TextColor3 = WHITE, TextWrapped = true }, 22)
question.Parent = panel
local cardRow = make("Frame", { Name = "Cards", Position = UDim2.fromScale(0.03, 0.71), Size = UDim2.fromScale(0.94, 0.21), BackgroundTransparency = 1, Parent = panel }, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
})
local cardButtons: { TextButton } = {}
for i = 1, 3 do
	local card = make("TextButton", {
		Name = "Card" .. i,
		Size = UDim2.fromScale(0.32, 1),
		BackgroundColor3 = PAPER,
		FontFace = FONT,
		TextScaled = true,
		TextWrapped = true,
		TextColor3 = INK,
		LayoutOrder = i,
		Parent = cardRow,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 8) }),
		make("UIStroke", { Color = Skin.Ink, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		make("UITextSizeConstraint", { MaxTextSize = 18 }),
		make("UIPadding", { PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0), PaddingTop = UDim.new(0.08, 0), PaddingBottom = UDim.new(0.12, 0) }),
		-- evidence paper: a soft top-lit fade + a darker bottom edge (multiplies the colour choose() sets)
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.7, Color3.new(0.97, 0.97, 0.97)), ColorSequenceKeypoint.new(1, Color3.new(0.82, 0.82, 0.82)),
		}) }),
	})
	card:SetAttribute("NoSkin", true)
	Skin.pressable(card, 1.04)
	cardButtons[i] = card
end
local status = Skin.text({ Position = UDim2.fromScale(0.04, 0.72), Size = UDim2.fromScale(0.92, 0.18), FontFace = FONT, TextWrapped = true, Visible = false }, 24, 3)
status.Parent = panel

-- Tutorial coach banner across the top of the scene (first case only)
local coach = make("Frame", {
	Name = "Coach",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.025),
	Size = UDim2.fromScale(0.94, 0.27),
	BackgroundColor3 = GOLD,
	Visible = false,
	ZIndex = 6,
	Parent = scene,
}, {
	round(0.18),
	make("UIStroke", { Color = BLACK, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
text({
	Position = UDim2.fromScale(0.03, 0.06),
	Size = UDim2.fromScale(0.94, 0.42),
	FontFace = TITLE,
	TextColor3 = WHITE,
	TextStrokeTransparency = 0,
	Text = "YOUR FIRST CASE GOES TO COURT!",
	ZIndex = 7,
	Parent = coach,
}, 24)
local coachBody = text({
	Position = UDim2.fromScale(0.03, 0.5),
	Size = UDim2.fromScale(0.94, 0.44),
	FontFace = BODY,
	TextColor3 = INK,
	TextWrapped = true,
	Text = "",
	ZIndex = 7,
	Parent = coach,
}, 18)
local timerBack = make("Frame", { Position = UDim2.fromScale(0.03, 0.94), Size = UDim2.fromScale(0.94, 0.025), BackgroundColor3 = Color3.fromRGB(220, 210, 190), Parent = panel }, { round(1) })
local timerFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = GOLD, Parent = timerBack }, { round(1) })

-- Verdict banner
local verdictTitle = text({ FontFace = TITLE, Size = UDim2.fromScale(1, 0.5), TextColor3 = WHITE, TextStrokeTransparency = 0 }, 60)
local verdictAmount = text({ Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.28), TextColor3 = WHITE, TextStrokeTransparency = 0 }, 32)
local verdictNote = text({ Position = UDim2.fromScale(0, 0.76), Size = UDim2.fromScale(1, 0.2), TextColor3 = WHITE, TextStrokeTransparency = 0, FontFace = FONT }, 18)
local verdictScale = make("UIScale", { Scale = 0 })
local verdict = make("Frame", {
	Name = "Verdict",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.72, 0.42),
	Visible = false,
	ZIndex = 10,
	Parent = panel,
}, { round(0.1), verdictScale, make("UIStroke", { Color = BLACK, Thickness = 5 }), verdictTitle, verdictAmount, verdictNote })
for _, d in verdict:GetDescendants() do
	if d:IsA("GuiObject") then
		d.ZIndex = 11
	end
end

local playerGui = player:WaitForChild("PlayerGui")
buttonGui.Parent = playerGui
gui.Parent = playerGui

-- State
type State = "closed" | "question" | "waiting" | "arguing" | "verdict"
local state: State = "closed"
local attendedStart: number? = nil
local questionStarted = 0
local answerTime = Config.Courtroom.AnswerTime
local argumentIndex = 0
local nextArgument = 0
local session = 0 -- bumps on every open/close so stale delayed callbacks do nothing
local buttonMessage: string? = nil
local tutorialCase = false -- the open case is the tutorial's first case
local autoOpened: number? = nil -- CaseStart of the tutorial case the courtroom already opened for

local function getDesk(): Instance?
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	return firm and firm:FindFirstChild("Desk" .. DESK)
end

local function say(speaker: string, line: string)
	bubbleSpeaker = speaker
	local actor = actors[speaker]
	if actor then
		actor.anim:play(clipFor(speaker, line))
		-- everyone else turns to look at whoever is talking; the speaker addresses the judge
		for role, other in actors do
			if role ~= speaker then
				other.anim.lookAt = actor.top
			end
		end
		local judge = actors.judge
		actor.anim.lookAt = if judge and speaker ~= "judge" then judge.top else nil
	end
	bubble.Text = line
	bubble.Visible = true
	local scale = bubble:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = bubble })
	scale.Scale = 0.6
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- A copy of a person ready for the court view: no nameplates, particles or scripts.
local function prepare(source: Model): Model
	local model = Puppet.cloneAtRest(source) -- desk people are animated (DeskLife): copy them at rest
	for _, d in model:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("ProximityPrompt") or d:IsA("BaseScript") then
			d:Destroy()
		end
	end
	return model
end

-- Stands a model with its feet on a spot, facing the camera (-Z), turned by `turn` radians.
local CLASS = { lawyer = "lawyer", client = "client", opponent = "defendant" }
local function place(role: string, model: Model, spotName: string, fallback: Vector3, turn: number, tag: TextLabel)
	local spot = spots[spotName] or CFrame.new(fallback)
	model:PivotTo(CFrame.new(0, 0, 0))
	local box, size = model:GetBoundingBox()
	local lift = -(box.Position.Y - size.Y / 2)
	local base = CFrame.new(spot.Position + Vector3.new(0, lift, 0)) * CFrame.Angles(0, turn, 0)
	model:PivotTo(base)
	model.Parent = cast
	local b2, s2 = model:GetBoundingBox()
	actors[role] = { model = model, top = b2.Position + Vector3.new(0, s2.Y / 2, 0), tag = tag, anim = Puppet.animator(Puppet.new(model), CLASS[role]) }
end

-- Random look for the other side until real defendant models exist.
local DEFENDANT_SUITS = { Color3.fromRGB(90, 90, 100), Color3.fromRGB(140, 40, 40), Color3.fromRGB(40, 90, 60), Color3.fromRGB(150, 110, 60), Color3.fromRGB(70, 60, 140), Color3.fromRGB(200, 120, 40) }
local SKIN_TONES = { Color3.fromRGB(255, 220, 180), Color3.fromRGB(234, 184, 146), Color3.fromRGB(190, 135, 95), Color3.fromRGB(140, 90, 60), Color3.fromRGB(95, 60, 40) }

local function spawnJudge()
	local folder = ReplicatedStorage:FindFirstChild("JudgeModels")
	local choices = folder and folder:GetChildren() or {}
	if #choices == 0 then
		judgeName.Text = "The Judge"
		return
	end
	local model = choices[math.random(#choices)]:Clone() :: Model
	judgeName.Text = model:GetAttribute("DisplayName") or "The Judge"
	-- judge models have their pivot at the feet, facing -Z; a little larger and raised so they tower over the bench
	local at = spots.JudgeSpot or CFrame.new(0, 2, 16)
	model:ScaleTo(1.25)
	model:PivotTo(CFrame.new(at.Position + Vector3.new(0, 0.9, 0)))
	model.Parent = cast
	local box, size = model:GetBoundingBox()
	-- the gavel arm (GavelArm) becomes the puppet's right arm, so slams are just another animation
	actors.judge = { model = model, top = box.Position + Vector3.new(0, size.Y / 2, 0), tag = judgeName, anim = Puppet.animator(Puppet.new(model), "judge") }
end

-- Fills the courtroom: your lawyer (wearing their equipped skin), the client at your desk, a random
-- person for the other side and a random judge.
local function spawnCast(desk: Instance)
	loadSet()
	cast:ClearAllChildren()
	table.clear(actors)
	bubbleSpeaker = nil
	local lawyer = desk:FindFirstChild("Lawyer")
	if lawyer and lawyer:IsA("Model") then
		place("lawyer", prepare(lawyer), "LawyerSpot", Vector3.new(8.2, 0, 4.9), 0.25, lawyerName)
	end
	local client = desk:FindFirstChild("Client")
	if client and client:IsA("Model") then
		place("client", prepare(client), "ClientSpot", Vector3.new(4.6, 0, 4.9), 0.2, clientName)
		-- the defendant is always a different person than the client: another client character
		-- (ReplicatedStorage.ClientModels, shared by ShareClientModels), recoloured below if blocky
		local folder = ReplicatedStorage:FindFirstChild("ClientModels")
		local choices = {}
		for _, m in (folder and folder:GetChildren() or {}) do
			if m:IsA("Model") and m.Name ~= client:GetAttribute("CharacterId") then
				table.insert(choices, m)
			end
		end
		local other = prepare(if #choices > 0 then choices[math.random(#choices)] else client)
		local suit = DEFENDANT_SUITS[math.random(#DEFENDANT_SUITS)]
		for _, p in other:GetDescendants() do
			if p:IsA("BasePart") then
				if p.Name == "Torso" or p.Name == "Left Arm" or p.Name == "Right Arm" then
					p.Color = suit
				elseif p.Name == "Left Leg" or p.Name == "Right Leg" then
					p.Color = Color3.fromRGB(45, 45, 55)
				elseif p.Name == "Head" or p.Name:find("Hand") then
					p.Color = SKIN_TONES[math.random(#SKIN_TONES)]
				end
			end
		end
		place("opponent", other, "DefendantSpot", Vector3.new(-6.5, 0, 4.9), -0.25, opponentName)
	end
	spawnJudge()
end

-- The judge brings the gavel down (yields until it lands, like the old version).
local function slamGavel()
	react("judge", "slam")
	task.wait(0.35)
end

-- Every frame while court is open: everyone's animation, and name tags / speech bubble that follow heads.
RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	local t = os.clock()
	for _, actor in actors do
		actor.anim:step(t)
		local at = project(actor.top + Vector3.new(0, 0.5, 0))
		actor.tag.Visible = at ~= nil
		if at then
			actor.tag.Position = UDim2.fromScale(at.X, math.max(at.Y, 0.09)) -- keep it inside the view
		end
	end
	for _, tag in { lawyerName, clientName, opponentName, judgeName } do
		local used = false
		for _, actor in actors do
			used = used or actor.tag == tag
		end
		tag.Visible = used and tag.Visible
	end
	local speaker = bubbleSpeaker and actors[bubbleSpeaker]
	local at = speaker and project(speaker.top + Vector3.new(0, 0.5, 0))
	if at then
		local x = math.clamp(at.X, 0.19, 0.81)
		if bubbleSpeaker == "judge" or at.Y - 0.1 - 0.22 < 0 then
			-- the judge sits high up: put the bubble at the top, beside the head
			bubble.AnchorPoint = Vector2.new(0, 0)
			bubble.Position = UDim2.fromScale(math.min(at.X + 0.06, 0.62), 0.02)
		else
			bubble.AnchorPoint = Vector2.new(0.5, 1)
			bubble.Position = UDim2.fromScale(x, at.Y - 0.1)
		end
	end
end)

-- The chat window and player list sit over the panel's corners, so hide them while in court.
local hiddenCoreGuis: { Enum.CoreGuiType } = {}

local function setCoreGuisHidden(hidden: boolean)
	if hidden then
		hiddenCoreGuis = {}
		for _, coreGui in { Enum.CoreGuiType.Chat, Enum.CoreGuiType.PlayerList } do
			if StarterGui:GetCoreGuiEnabled(coreGui) then
				StarterGui:SetCoreGuiEnabled(coreGui, false)
				table.insert(hiddenCoreGuis, coreGui)
			end
		end
	else
		for _, coreGui in hiddenCoreGuis do
			StarterGui:SetCoreGuiEnabled(coreGui, true)
		end
		hiddenCoreGuis = {}
	end
end

local function close()
	session += 1
	state = "closed"
	gui.Enabled = false
	setCoreGuisHidden(false)
end

local function showStatus(message: string, color: Color3)
	cardRow.Visible = false
	timerBack.Visible = false
	question.Visible = false
	status.Visible = true
	status.Text = message
	status.TextColor3 = color
end

local function startArguing()
	state = "arguing"
	argumentIndex = 0
	nextArgument = os.clock() + 2.5
end

local function choose(index: number)
	if state ~= "question" then
		return
	end
	state = "waiting"
	local mySession = session
	for _, card in cardButtons do
		card.AutoButtonColor = false
	end
	say("lawyer", "Objection! Take a look at THIS!")
	coach.Visible = false
	local result = AnswerEvidence:InvokeServer(DESK, index)
	if mySession ~= session then
		return
	end
	if result then
		local right = cardButtons[result.correctIndex]
		if right then
			right.BackgroundColor3 = Color3.fromRGB(200, 240, 205)
		end
		if not result.correct then
			cardButtons[index].BackgroundColor3 = Color3.fromRGB(205, 225, 245)
		end
	end
	task.wait(0.9)
	if mySession ~= session then
		return
	end
	if result and result.correct then
		say("judge", "Sustained! Very convincing, counselor.")
		showStatus(string.format("Great pick! +%d%% bonus on this case", math.round(Config.Courtroom.CorrectAnswerBonus * 100)), GOOD)
		react("client", "clap")
		react("opponent", "sweat")
		slamGavel()
		react("lawyer", "celebrate")
	elseif tutorialCase then
		say("judge", "Hmm... interesting. Let's keep going.")
		showStatus("Not quite, but don't worry: your first case is a guaranteed win!", CALM)
		react("lawyer", "shrug")
		react("client", "worried")
		react("opponent", "smug")
	else
		say("judge", "Hmm... interesting. Let's keep going.")
		showStatus("Nice try! You still get the normal payout.", CALM)
		react("lawyer", "shrug")
		react("client", "worried")
		react("opponent", "smug")
	end
	startArguing()
end

local function timeUp()
	if state ~= "question" then
		return
	end
	say("judge", "*yawn* ...the court will move on.")
	coach.Visible = false
	showStatus(if tutorialCase
		then "Time's up! Don't worry: your first case is a guaranteed win!"
		else "Time's up! No worries, you still get the normal payout.", CALM)
	react("lawyer", "think")
	react("client", "scratchHead")
	startArguing()
end

local function open()
	if state ~= "closed" then
		return
	end
	local desk = getDesk()
	if not desk then
		return
	end
	local caseStart = desk:GetAttribute("CaseStart")
	attendedStart = caseStart
	local data, reason = AttendCourt:InvokeServer(DESK)
	if not data then
		buttonMessage = reason or "Can't go to court right now"
		task.delay(1.5, function()
			buttonMessage = nil
		end)
		return
	end

	session += 1
	local tier = desk:GetAttribute("ClientTier") :: number?
	local client = tier and Config.Clients[tier]
	-- the real client sitting at the desk (its character's name / situation), else the tier's
	local npc = desk:FindFirstChild("Client")
	local who = npc and npc:GetAttribute("ClientName")
	local why = npc and npc:GetAttribute("Situation")
	clientName.Text = if typeof(who) == "string" then who elseif client then client.Name else "Client"
	lawyerName.Text = "Your Lawyer"
	opponentName.Text = data.opponent
	title.Text = if typeof(why) == "string" then why elseif client then client.Situation else "Courtroom"
	tutorialCase = desk:GetAttribute("Tutorial") == true
	coach.Visible = tutorialCase
	coachBody.Text = string.format("It's a guaranteed win! Pick the right evidence for +%d%% bonus coins.", math.round(Config.Courtroom.CorrectAnswerBonus * 100))

	question.Text = data.question
	question.Visible = true
	for i, card in cardButtons do
		card.Text = data.cards[i] or ""
		card.Visible = data.cards[i] ~= nil
		card.BackgroundColor3 = PAPER
		card.AutoButtonColor = true
	end
	cardRow.Visible = true
	timerBack.Visible = true
	status.Visible = false
	verdict.Visible = false
	answerTime = data.answerTime
	questionStarted = os.clock()
	state = "question"
	spawnCast(desk)
	setCoreGuisHidden(true)
	gui.Enabled = true
	say("judge", "Order in the court! Counselor, show me your evidence.")
	task.spawn(slamGavel)
end

for i, card in cardButtons do
	card.Activated:Connect(function()
		choose(i)
	end)
end
attendButton.Activated:Connect(open)
closeButton.Activated:Connect(close)
dim.Activated:Connect(close)

local nextPick = 0
RunService.Heartbeat:Connect(function()
	if state == "closed" and os.clock() >= nextPick then
		nextPick = os.clock() + 0.25 -- (4x a second is plenty; perf 2026-10-09)
		-- the office picked in the LAWYERS panel; if it has no case to attend, any office that does
		-- (there's no office card on screen any more to pick one with - lawyer-management overhaul 2026-10-09)
		local selected = player:GetAttribute("SelectedDesk")
		DESK = if typeof(selected) == "number" then selected else 1
		local function attendable(index: number): boolean
			local d = player:GetAttribute("Desk" .. index .. "Phase") == "Case" and (function()
				local plotName = player:GetAttribute("Plot")
				local plots = workspace:FindFirstChild("Plots")
				local plot = plotName and plots and plots:FindFirstChild(plotName)
				local firm = plot and plot:FindFirstChild("Firm")
				return firm and firm:FindFirstChild("Desk" .. index)
			end)()
			if not d then
				return false
			end
			local left = ((d:GetAttribute("CaseEnd") or 0) :: number) - workspace:GetServerTimeNow()
			return not d:GetAttribute("CourtDone") and d:GetAttribute("CaseStart") ~= attendedStart
				and (left > 2 or d:GetAttribute("Tutorial") == true)
		end
		if not attendable(DESK) then
			for i = 1, (player:GetAttribute("DeskCount") or 1) :: number do
				if attendable(i) then
					DESK = i
					break
				end
			end
		end
	end
	local desk = getDesk()
	local phase = desk and desk:GetAttribute("Phase")
	local caseStart = desk and desk:GetAttribute("CaseStart")
	local caseEnd = (desk and desk:GetAttribute("CaseEnd") or 0) :: number
	local left = caseEnd - workspace:GetServerTimeNow()

	local isTutorial = desk ~= nil and (desk :: Instance):GetAttribute("Tutorial") == true
	local canAttend = phase == "Case"
		and (not isTutorial or Config.Tutorial.FirstCaseInCourt)
		and not (desk :: Instance):GetAttribute("CourtDone")
		and caseStart ~= attendedStart
		and (left > 2 or isTutorial) -- the tutorial case waits for the player (CaseService)
	-- tutorial: the first case always goes to court, so open the courtroom by itself (once)
	if state == "closed" and canAttend and isTutorial and autoOpened ~= caseStart then
		autoOpened = caseStart
		task.delay(1.2, function()
			if state == "closed" then
				open()
			end
		end)
	end
	attendButton.Visible = state == "closed" and (canAttend or buttonMessage ~= nil)
	attendButton.Text = buttonMessage
		or if isTutorial then "GO TO COURT!" else string.format("ATTEND COURT  +%d%%", math.round(Config.Courtroom.CorrectAnswerBonus * 100))

	if state == "closed" then
		return
	end
	if state ~= "verdict" then
		local seconds = math.ceil(left)
		verdictTimer.Text = if seconds > 0 then string.format("Verdict in %d:%02d", seconds // 60, seconds % 60) else "Verdict!"
	end
	if state == "question" then
		local fraction = 1 - (os.clock() - questionStarted) / answerTime
		timerFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		if fraction <= 0 then
			timeUp()
		end
	elseif state == "arguing" and os.clock() >= nextArgument then
		argumentIndex = argumentIndex % #ARGUMENTS + 1
		local line = ARGUMENTS[argumentIndex]
		say(line[1], line[2])
		nextArgument = os.clock() + 2.4
	end
end)

-- Surprise events (server: CourtService). A big OBJECTION! button pops over the scene; tapping it in
-- time adds Config.Courtroom.EventBonus to this case. Missing it costs nothing.
local CourtEvent = Remotes:WaitForChild("CourtEvent") :: RemoteEvent
local ReactCourtEvent = Remotes:WaitForChild("ReactCourtEvent") :: RemoteFunction
local eventScale = make("UIScale", { Scale = 0 })
local eventLabel = text({ Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.38), TextColor3 = WHITE, TextStrokeTransparency = 0, FontFace = FONT }, 26)
local eventButton = make("TextButton", {
	Name = "ObjectionButton",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromScale(0.5, 0.36),
	BackgroundColor3 = Color3.fromRGB(240, 70, 70),
	FontFace = FONT,
	TextScaled = true,
	TextColor3 = WHITE,
	TextStrokeTransparency = 0,
	Text = "",
	Visible = false,
	ZIndex = 8,
	Parent = panel,
}, {
	round(0.2),
	make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	eventScale,
	eventLabel,
	make("TextLabel", {
		Name = "Call",
		Position = UDim2.fromScale(0.05, 0.38),
		Size = UDim2.fromScale(0.9, 0.55),
		BackgroundTransparency = 1,
		FontFace = FONT,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 220, 60),
		TextStrokeTransparency = 0,
		Text = "OBJECTION!",
		ZIndex = 9,
	}),
})
eventLabel.ZIndex = 9
local eventToken = 0

CourtEvent.OnClientEvent:Connect(function(info: { desk: number, text: string, window: number })
	if state ~= "arguing" or info.desk ~= DESK then
		return
	end
	eventToken += 1
	local token = eventToken
	eventLabel.Text = info.text
	eventButton.Visible = true
	eventScale.Scale = 0.3
	TweenService:Create(eventScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	say("judge", info.text)
	react("client", "worried")
	react("opponent", "glance")
	task.delay(info.window, function()
		if token == eventToken and eventButton.Visible then
			eventButton.Visible = false
			if state == "arguing" then
				say("judge", "Too slow! Moving on...")
				react("opponent", "smug")
			end
		end
	end)
end)

RunService.Heartbeat:Connect(function()
	if eventButton.Visible and state ~= "arguing" then
		eventButton.Visible = false -- verdict landed or court closed
	end
end)

eventButton.Activated:Connect(function()
	if not eventButton.Visible then
		return
	end
	eventButton.Visible = false
	eventToken += 1
	say("lawyer", "OBJECTION!")
	local result = ReactCourtEvent:InvokeServer(DESK)
	if typeof(result) == "table" and result.ok then
		say("judge", "Sustained! Great reflexes!")
		react("opponent", "sweat")
		react("client", "cheer")
		status.Text = string.format("Quick thinking! +%d%% more on this case", math.round((result.bonus or 0) * 100))
		status.TextColor3 = GOOD
	else
		say("judge", "Overruled... but nice try!")
	end
end)

CaseResult.OnClientEvent:Connect(function(result: { desk: number, outcome: string, payout: number, courtBonus: number?, tutorial: boolean? })
	if state == "closed" or result.desk ~= DESK then
		return
	end
	state = "verdict"
	local mySession = session
	local style = VERDICT_STYLE[result.outcome] or VERDICT_STYLE.Win
	cardRow.Visible = false
	timerBack.Visible = false
	question.Visible = false
	status.Visible = false
	verdictTimer.Text = ""
	say("judge", "The court has decided...")
	slamGavel()
	if mySession ~= session then
		return
	end
	verdict.BackgroundColor3 = style.color
	verdictTitle.Text = style.title
	if result.outcome == "Mistrial" then
		verdictAmount.Text = "No coins lost!"
		verdictNote.Text = "The case goes again"
	else
		verdictAmount.Text = "+" .. Formulas.formatCoins(result.payout) .. " coins"
		verdictNote.Text = if result.tutorial
			then "Tip: tap ATTEND COURT during any case for bonus coins!"
			elseif (result.courtBonus or 0) > 0
			then string.format("Includes your +%d%% court bonus!", math.round((result.courtBonus :: number) * 100))
			else ""
	end
	-- everyone reacts to the verdict
	if result.outcome == "Win" then
		react("lawyer", "celebrate")
		react("client", "cheer")
		react("opponent", "despair")
	elseif result.outcome == "Settlement" then
		react("lawyer", "shrug")
		react("client", "nod")
		react("opponent", "shrug")
	else
		react("judge", "shake")
		react("lawyer", "think")
		react("client", "despair")
		react("opponent", "smug")
	end
	verdict.Visible = true
	verdictScale.Scale = 0.3
	TweenService:Create(verdictScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(3.5, function()
		if mySession == session then
			close()
		end
	end)
end)
