--!strict
-- Lawyer skills screen, opened from the SKILLS button in the LAWYERS panel (local ReplicatedStorage.SkillsUI
-- bindable, StarterPlayerScripts.Lawyers; lawyer-management overhaul 2026-10-09) or by clicking your lawyer. Shows the selected
-- lawyer's 3 slots, rolls skills (free rolls first, then coins) with the odds on screen, plays a
-- reveal, and - when the slots are full - asks which skill to replace. The server (SkillService)
-- decides everything; this script reads the Desk<N>... attributes PlayerData mirrors.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollSkill = Remotes:WaitForChild("RollSkill") :: RemoteFunction
local ResolveSkill = Remotes:WaitForChild("ResolveSkill") :: RemoteFunction

local player = Players.LocalPlayer

-- Same cartoon palette as the HUD.
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local INK = Color3.fromRGB(40, 40, 52)
local MUTED = Color3.fromRGB(105, 105, 120)
local GREEN = Color3.fromRGB(98, 205, 48)
local ORANGE = Color3.fromRGB(255, 160, 24)
local RED = Color3.fromRGB(240, 70, 70)
local GOLD = Color3.fromRGB(255, 200, 40)
local GRAY = Color3.fromRGB(170, 170, 182)
local EMPTY = Color3.fromRGB(225, 225, 232)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local BODY = Font.fromEnum(Enum.Font.BuilderSansMedium) -- descriptions / small print (Shared.UIFonts)
local TITLE = Font.fromEnum(Enum.Font.LuckiestGuy) -- big moments (Shared.UIFonts)

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
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.FontFace = props.FontFace or FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or INK
	return make("TextLabel", props, { make("UITextSizeConstraint", { MaxTextSize = maxSize }) })
end

local function button(props: { [string]: any }, maxSize: number): TextButton
	props.FontFace = FONT
	props.TextScaled = true
	props.TextColor3 = WHITE
	props.TextStrokeTransparency = 0
	props.AutoButtonColor = true
	return make("TextButton", props, {
		corner(14),
		stroke(3),
		make("UITextSizeConstraint", { MaxTextSize = maxSize }),
		make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
end

local function rarityOf(def: Config.SkillDef?): (string, Color3)
	local id = if def then Config.Eggs.Skins[def.Rarity].Id else "Common"
	return id, Config.RarityColors[id] or GRAY
end

local function stars(level: number): string
	return string.rep("★", level) .. string.rep("☆", Config.Skills.MaxLevel - level)
end

---------------------------------------------------------------- state from attributes
local deskIndex = 1

local function attr(name: string): any
	return player:GetAttribute("Desk" .. deskIndex .. name)
end

local function decode(raw: any): any
	if typeof(raw) ~= "string" then
		return nil
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else nil
end

local function ownedSkills(): { Formulas.OwnedSkill }
	return decode(attr("Skills")) or {}
end

local function pendingSkill(): Formulas.OwnedSkill?
	return decode(attr("PendingSkill"))
end

---------------------------------------------------------------- layout (designed at 560x400, scaled to fit)
local gui = make("ScreenGui", { Name = "Skills", ResetOnSpawn = false, DisplayOrder = 17, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local dim = make("TextButton", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false, Parent = gui })
local panelScale = make("UIScale", {})
local panel = make("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 400),
	BackgroundColor3 = WHITE,
	Parent = gui,
}, { corner(24), make("UIStroke", { Color = BLACK, Thickness = 5 }), panelScale })

local title = text({ Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(420, 40), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 34)
local subtitle = text({ FontFace = BODY, Position = UDim2.fromOffset(24, 54), Size = UDim2.fromOffset(500, 22), TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 18)
local closeButton = button({ Name = "Close", Position = UDim2.new(1, -62, 0, 14), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = RED, Text = "X", Parent = panel }, 26)
local closeCorner = closeButton:FindFirstChildOfClass("UICorner") :: UICorner
closeCorner.CornerRadius = UDim.new(1, 0)

type Card = { frame: Frame, gradient: UIGradient, rarity: TextLabel, name: TextLabel, level: TextLabel, effect: TextLabel, replace: TextButton }
local cards: { Card } = {}
for slot = 1, Config.Skills.MaxSlots do
	local frame = make("Frame", {
		Name = "Slot" .. slot,
		Position = UDim2.fromOffset(20 + (slot - 1) * 180, 90),
		Size = UDim2.fromOffset(160, 180),
		BackgroundColor3 = WHITE,
		Parent = panel,
	}, { corner(18), stroke(4) })
	local gradient = make("UIGradient", { Rotation = 90, Parent = frame })
	local card: Card = {
		frame = frame,
		gradient = gradient,
		rarity = text({ Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(140, 20), TextColor3 = WHITE, TextStrokeTransparency = 0, Parent = frame }, 16),
		name = text({ Position = UDim2.fromOffset(8, 30), Size = UDim2.fromOffset(144, 44), TextColor3 = WHITE, TextStrokeTransparency = 0, TextWrapped = true, Parent = frame }, 24),
		level = text({ Position = UDim2.fromOffset(10, 76), Size = UDim2.fromOffset(140, 24), TextColor3 = GOLD, TextStrokeTransparency = 0, Parent = frame }, 24),
		effect = text({ FontFace = BODY,
			Position = UDim2.fromOffset(10, 106),
			Size = UDim2.fromOffset(140, 62),
			BackgroundTransparency = 0,
			BackgroundColor3 = WHITE,
			TextWrapped = true,
			Parent = frame,
		}, 17),
		replace = button({ Name = "Replace", Position = UDim2.fromOffset(20, 164), Size = UDim2.fromOffset(120, 32), BackgroundColor3 = ORANGE, Text = "REPLACE", Visible = false, ZIndex = 3, Parent = frame }, 18),
	}
	corner(10).Parent = card.effect
	make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = card.effect })
	cards[slot] = card
end

local rollButton = button({ Name = "RollButton", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 290), Size = UDim2.fromOffset(320, 60), BackgroundColor3 = GREEN, Parent = panel }, 26)
local odds = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 356), Size = UDim2.fromOffset(500, 22), TextColor3 = MUTED, Parent = panel }, 16)
do
	local total = 0
	for _, w in Config.Skills.RarityWeights do
		total += w
	end
	local parts = {}
	for rarity, w in Config.Skills.RarityWeights do
		table.insert(parts, string.format("%s %d%%", Config.Eggs.Skins[rarity].Id, math.round(w / total * 100)))
	end
	odds.Text = "Skill odds: " .. table.concat(parts, "  ·  ")
end

-- reveal pop-up (inside the panel)
local revealScale = make("UIScale", { Scale = 0 })
local reveal = make("Frame", {
	Name = "Reveal",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(300, 220),
	BackgroundColor3 = WHITE,
	Visible = false,
	ZIndex = 10,
	Parent = panel,
}, { corner(22), make("UIStroke", { Color = BLACK, Thickness = 5 }), revealScale })
local revealGradient = make("UIGradient", { Rotation = 90, Parent = reveal })
local revealHeadline = text({ FontFace = TITLE, Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(280, 44), TextColor3 = WHITE, TextStrokeTransparency = 0, ZIndex = 11, Parent = reveal }, 38)
local revealName = text({ Position = UDim2.fromOffset(10, 62), Size = UDim2.fromOffset(280, 46), TextColor3 = WHITE, TextStrokeTransparency = 0, ZIndex = 11, Parent = reveal }, 34)
local revealStars = text({ Position = UDim2.fromOffset(10, 110), Size = UDim2.fromOffset(280, 30), TextColor3 = GOLD, TextStrokeTransparency = 0, ZIndex = 11, Parent = reveal }, 28)
local revealEffect = text({ Position = UDim2.fromOffset(16, 148), Size = UDim2.fromOffset(268, 56), BackgroundTransparency = 0, BackgroundColor3 = WHITE, TextWrapped = true, ZIndex = 11, Parent = reveal }, 20)
corner(10).Parent = revealEffect

---------------------------------------------------------------- rendering
local busy = false
local message: string? = nil

local function paintCard(card: Card, skill: Formulas.OwnedSkill?)
	local def = skill and Formulas.getSkillDef(skill.Id)
	if not skill or not def then
		card.frame.BackgroundColor3 = EMPTY
		card.gradient.Enabled = false
		card.rarity.Text = ""
		card.name.Text = "EMPTY SLOT"
		card.name.TextColor3 = MUTED
		card.name.TextStrokeTransparency = 1
		card.level.Text = ""
		card.effect.Text = "Roll to learn a skill!"
		return
	end
	local rarityName, color = rarityOf(def)
	card.frame.BackgroundColor3 = color
	card.gradient.Enabled = true
	card.gradient.Color = ColorSequence.new(color:Lerp(WHITE, 0.45), color)
	card.rarity.Text = string.upper(rarityName)
	card.name.Text = def.Name
	card.name.TextColor3 = WHITE
	card.name.TextStrokeTransparency = 0
	card.level.Text = stars(skill.Level)
	card.effect.Text = Formulas.describeSkill(skill)
end

local function render()
	if not gui.Enabled then
		return
	end
	local level = attr("Level") or 1
	local deskCount = player:GetAttribute("DeskCount") or 1
	local lawyerId = attr("Lawyer")
	local stars = attr("Stars") or 1
	title.Text = if lawyerId then string.upper(Formulas.lawyerName(lawyerId, stars)) .. " · SKILLS" else string.format("OFFICE %d IS EMPTY", deskIndex)
	local cases = attr("CasesDone") or 0
	local per = Config.Skills.CasesPerFreeRoll
	subtitle.Text = if lawyerId then string.format("Office Lv %d  ·  %d / %d cases to the next free roll", level, cases % per, per) else "Put a lawyer here to learn skills"

	local skills = ownedSkills()
	local pending = pendingSkill()
	for slot, card in cards do
		paintCard(card, skills[slot])
		card.replace.Visible = pending ~= nil and skills[slot] ~= nil
	end

	local free = attr("FreeSkillRolls") or 0
	local cost = Formulas.skillRollCost(attr("SkillRolls") or 0)
	local coins = player:GetAttribute("Coins") or 0
	local nothingLeft = Formulas.rollSkill(Random.new(1), skills) == nil
	local canRoll = false
	if message then
		rollButton.Text = message
	elseif pending then
		local def = Formulas.getSkillDef(pending.Id)
		rollButton.Text = "KEEP MY SKILLS"
		subtitle.Text = string.format("New skill: %s! Pick a skill to replace, or keep yours.", if def then def.Name else "?")
		canRoll = true
	elseif nothingLeft then
		rollButton.Text = "ALL SKILLS MAXED!"
	elseif free > 0 then
		rollButton.Text = if free > 1 then string.format("FREE ROLL! (x%d)", free) else "FREE ROLL!"
		canRoll = true
	else
		rollButton.Text = "ROLL SKILL · " .. Formulas.formatCoins(cost)
		canRoll = coins >= cost
	end
	rollButton.BackgroundColor3 = if pending then ORANGE elseif canRoll then GREEN else GRAY
end

-- yellow "!" on the HUD's LAWYERS tile (Shared.HudMenu) while any lawyer has a free roll or a skill waiting
local lawyersTile = (require(ReplicatedStorage.Shared:WaitForChild("HudMenu")) :: any).wait("Lawyers")

local function refreshBadge()
	local count = player:GetAttribute("DeskCount") or 1
	local any = false
	for i = 1, count do
		if (player:GetAttribute("Desk" .. i .. "FreeSkillRolls") or 0) > 0 or player:GetAttribute("Desk" .. i .. "PendingSkill") ~= nil then
			any = true
		end
	end
	lawyersTile.setAlert(any)
end

player.AttributeChanged:Connect(function(name)
	if name:match("^Desk%d+") or name == "Coins" or name == "DeskCount" then
		refreshBadge()
		if not busy then
			render()
		end
	end
end)
refreshBadge()

---------------------------------------------------------------- open / close
local function fit(): number
	local camera = workspace.CurrentCamera
	if not camera then
		return 1
	end
	return math.clamp(math.min(camera.ViewportSize.Y / 460, camera.ViewportSize.X / 620), 0.5, 1)
end

local function open()
	local selected = player:GetAttribute("SelectedDesk")
	deskIndex = if typeof(selected) == "number" then selected else 1
	message = nil
	reveal.Visible = false
	gui.Enabled = true
	panelScale.Scale = 0
	TweenService:Create(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit() }):Play()
	render()
end

local function close()
	if busy then
		return
	end
	gui.Enabled = false
end

-- Click / tap one of your own lawyers (or their desk) to open their skills (design doc: "Lawyer UI").
local UserInputService = game:GetService("UserInputService")
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed or gui.Enabled then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	-- clicks pass through your own character and the clients standing at the desks
	local ignore: { Instance } = { player.Character :: Instance }
	for _, d in workspace:WaitForChild("Plots"):GetDescendants() do
		if d:IsA("Model") and d.Name == "Client" then
			table.insert(ignore, d)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	-- the lawyer or anything on their desk counts (the lawyer lives inside the Desk<N> model)
	local desk: Instance? = hit and hit.Instance
	while desk and not desk.Name:match("^Desk%d+$") do
		desk = desk.Parent
	end
	local index = desk and tonumber(desk.Name:match("^Desk(%d+)$"))
	if index and desk:GetAttribute("OwnerUserId") == player.UserId then
		player:SetAttribute("SelectedDesk", index)
		open()
	end
end)

local skillsEvent = ReplicatedStorage:FindFirstChild("SkillsUI") :: BindableEvent?
if not skillsEvent then
	skillsEvent = Instance.new("BindableEvent")
	;(skillsEvent :: BindableEvent).Name = "SkillsUI"
	;(skillsEvent :: BindableEvent).Parent = ReplicatedStorage
end
;(skillsEvent :: BindableEvent).Event:Connect(function(index: number?)
	if typeof(index) == "number" then
		player:SetAttribute("SelectedDesk", index)
	end
	open()
end)
closeButton.Activated:Connect(close)
dim.Activated:Connect(close)

---------------------------------------------------------------- rolling
local function flash(text: string)
	message = text
	render()
	task.delay(1.2, function()
		if message == text then
			message = nil
			render()
		end
	end)
end

local function showReveal(skill: Formulas.OwnedSkill, headline: string)
	local def = Formulas.getSkillDef(skill.Id)
	local _, color = rarityOf(def)
	revealGradient.Color = ColorSequence.new(color:Lerp(WHITE, 0.45), color)
	reveal.BackgroundColor3 = color
	revealHeadline.Text = headline
	revealName.Text = if def then def.Name else "?"
	revealStars.Text = stars(skill.Level)
	revealEffect.Text = Formulas.describeSkill(skill)
	reveal.Visible = true
	revealScale.Scale = 0.2
	TweenService:Create(revealScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.wait(1.6)
	TweenService:Create(revealScale, TweenInfo.new(0.15), { Scale = 0 }):Play()
	task.wait(0.15)
	reveal.Visible = false
end

rollButton.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	if pendingSkill() then
		-- "Keep my skills": throw the new one away
		ResolveSkill:InvokeServer(deskIndex, 0)
		busy = false
		render()
		return
	end
	local result = RollSkill:InvokeServer(deskIndex)
	if typeof(result) == "table" and result.ok and result.skill then
		local headline = if result.result == "levelUp" then "LEVEL UP!" elseif result.result == "pending" then "NEW SKILL!" else "NEW SKILL!"
		showReveal(result.skill, headline)
	elseif typeof(result) == "table" then
		flash(string.upper(result.reason or "Can't roll"))
	end
	busy = false
	render()
end)

for slot, card in cards do
	card.replace.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		ResolveSkill:InvokeServer(deskIndex, slot)
		busy = false
		render()
	end)
end

-- keep the case counter fresh while open
local sinceRender = 0
RunService.Heartbeat:Connect(function(dt)
	sinceRender += dt
	if sinceRender >= 0.5 and gui.Enabled and not busy then
		sinceRender = 0
		render()
	end
end)
