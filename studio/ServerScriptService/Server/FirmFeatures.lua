--!strict
-- Firm features (design: "Firm Progression Plan"; building: Server.FirmStages). Everything that makes the
-- bigger firm worth climbing to, wired to one firm at a time by PlotService (FirmFeatures.attach):
--   * AREAS: one glowing pad on the lawn in front of the firm sells the next (cheapest) room in
--     Config.FirmAreas that the building has. A bought room appears in the building and gives its bonus for
--     good (until prestige resets the firm). CaseService asks for the bonuses: buffSources() / rareClients().
--   * SHOWCASE: the owner's best lawyers stand on the gallery pedestals behind the street windows.
--   * HOLOGRAM: a giant, slowly turning copy of the owner's best lawyer on the roof (Corporate HQ, Tower).
--   * ELEVATOR: one call point per floor; each ride goes to the next floor (top -> back to the lobby).
--   (The Hatch Lab egg inside the buildings was removed at the user's request; eggs hatch at the hub.)
--   * EXECUTIVE LOUNGE: while the owner stands in it, payouts get its bonus.
--   * STAGE-UP: when the firm reaches a new stage the front builds itself up floor by floor and the owner
--     gets a banner (Remotes.FirmStageUp, StarterPlayerScripts.FirmStageUp).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local SkinLook = require(ReplicatedStorage.Shared.SkinLook) :: any
local Effects = require(ReplicatedStorage.Shared.Effects) :: any
local PlayerData = require(script.Parent.PlayerData)
local FirmStages = require(script.Parent.FirmStages)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StageUp = Remotes:WaitForChild("FirmStageUp") :: RemoteEvent

local FirmFeatures = {}

local AREA: { [string]: { [string]: any } } = {}
for _, def in Config.FirmAreas do
	AREA[def.Id] = def
end

local firms: { [Player]: Model } = {}

------------------------------------------------------------------ helpers
local function ownedAreas(data: any): { [string]: boolean }
	return (data and data.Firm and data.Firm.Areas) or {}
end

local function rarityOf(id: string?): (string, Color3)
	local def = Formulas.getSkin(id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	local rid = (rarity and rarity.Id) or "Common"
	return rid, Config.RarityColors[rid] or Color3.new(1, 1, 1)
end

-- the owner's lawyers, best first (by what they earn)
local function bestLawyers(data: any, count: number): { { uid: string, lawyer: any } }
	local list = {}
	for uid, lawyer in data.Lawyers or {} do
		table.insert(list, { uid = uid, lawyer = lawyer, earn = Formulas.lawyerEarn(lawyer.Id, lawyer.Stars) })
	end
	table.sort(list, function(a, b)
		if a.earn ~= b.earn then
			return a.earn > b.earn
		end
		return a.uid < b.uid
	end)
	local out = {}
	for i = 1, math.min(count, #list) do
		out[i] = list[i]
	end
	return out
end

local function frontOf(firm: Model): Instance?
	return firm:FindFirstChild("Front")
end

local function descendantsWith(root: Instance, attr: string): { BasePart }
	local out = {}
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute(attr) ~= nil then
			table.insert(out, p)
		end
	end
	return out
end

-- a lawyer model like the ones at the desks (Templates.NPC dressed by SkinLook), anchored and inert
local function lawyerModel(id: string): Model
	local npc = ServerStorage.Templates.NPC:Clone() :: Model
	npc.Name = "ShowLawyer"
	SkinLook.dress(npc, id)
	for _, d in npc:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	return npc
end

-- feet on a point, facing a direction
local function standAt(npc: Model, feet: Vector3, facing: Vector3)
	npc:PivotTo(CFrame.lookAt(feet, feet + Vector3.new(facing.X, 0, facing.Z)))
	local box, size = npc:GetBoundingBox()
	local lift = feet.Y - (box.Position.Y - size.Y / 2)
	npc:PivotTo(npc:GetPivot() + Vector3.new(0, lift, 0))
end

local function nameTag(npc: Model, text: string, color: Color3, distance: number)
	local head = npc:FindFirstChild("Head") or npc.PrimaryPart
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShowTag"
	gui.Size = UDim2.fromOffset(160, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = distance
	gui.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = Color3.fromRGB(30, 22, 51)
	s.Parent = l
	l.Parent = gui
	gui.Parent = head
end

------------------------------------------------------------------ bonuses (CaseService)
local function inLounge(player: Player?): boolean
	if not player then
		return false
	end
	local firm = firms[player]
	local front = firm and frontOf(firm)
	local carpet = front and front:FindFirstChild("LoungeCarpet", true) :: BasePart?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not carpet or not root or carpet.Transparency >= 1 then
		return false
	end
	local rel = carpet.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) <= carpet.Size.X / 2 and math.abs(rel.Z) <= carpet.Size.Z / 2 and rel.Y > 0 and rel.Y < 9
end

-- Buff sources from the player's bought areas (one combined source).
function FirmFeatures.buffSources(player: Player?, data: any): { { [string]: number } }
	local source = { payout = 0, caseTime = 0, winChance = 0 }
	for id, has in ownedAreas(data) do
		local def = AREA[id]
		if has and def then
			if def.Effect == "payout" or def.Effect == "caseTime" or def.Effect == "winChance" then
				source[def.Effect] += def.Value
			elseif def.Effect == "lounge" and inLounge(player) then
				source.payout += def.Value
			end
		end
	end
	return { source }
end

-- Same, when only the save data is at hand (CaseService.deskBuffs): finds the owner for the lounge check.
function FirmFeatures.sourcesFor(data: any): { { [string]: number } }
	local owner: Player? = nil
	for p in firms do
		if PlayerData.get(p) == data then
			owner = p
			break
		end
	end
	return FirmFeatures.buffSources(owner, data)
end

-- Extra rare-client boost from bought areas (adds to the Manager's Referral Network).
function FirmFeatures.rareClients(data: any): number
	local total = 0
	for id, has in ownedAreas(data) do
		local def = AREA[id]
		if has and def and def.Effect == "rareClients" then
			total += def.Value
		end
	end
	return total
end

------------------------------------------------------------------ area pads
local PAD_SPOTS = { Vector3.new(-14, -1.5, -3) } -- one "next room" pad on the lawn, left of the walk-in path

local buildPads -- forward

local function popIn(parts: { BasePart })
	for _, p in parts do
		local target = p.CFrame
		local t = p.Transparency
		p.CFrame = target * CFrame.new(0, -2, 0)
		p.Transparency = 1
		TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = target, Transparency = t }):Play()
	end
end

local function buy(player: Player, id: string)
	local firm = firms[player]
	local data = PlayerData.get(player)
	local def = AREA[id]
	if not firm or not data or not def then
		return
	end
	local owned = ownedAreas(data)
	if owned[id] then
		return
	end
	if (firm:GetAttribute("Stage") :: number? or 1) < def.Stage then
		StageUp:FireClient(player, { kind = "Need", text = "Grow your firm to unlock " .. def.Name })
		return
	end
	if not PlayerData.spendCoins(player, def.Cost) then
		StageUp:FireClient(player, { kind = "Need", text = "Need " .. Formulas.formatCoins(def.Cost) .. " coins for " .. def.Name })
		return
	end
	data.Firm.Areas = data.Firm.Areas or {}
	data.Firm.Areas[id] = true
	PlayerData.sync(player)
	FirmStages.applyAreas(firm, data.Firm.Areas)
	local front = frontOf(firm)
	if front then
		local parts = {}
		for _, p in front:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("Area") == id then
				table.insert(parts, p)
			end
		end
		popIn(parts)
	end
	buildPads(player, firm)
	StageUp:FireClient(player, { kind = "Area", name = def.Name, text = def.Text })
end

buildPads = function(player: Player, firm: Model)
	local old = firm:FindFirstChild("AreaPads")
	if old then
		old:Destroy()
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local stage = firm:GetAttribute("Stage") :: number? or 1
	local owned = ownedAreas(data)
	-- Only sell rooms this building actually has (each stage's front carries its own rooms); rooms bought at
	-- an earlier stage keep their bonus after the firm outgrows them.
	local built: { [string]: boolean } = {}
	local front = frontOf(firm)
	if front then
		for _, p in front:GetDescendants() do
			local area = p:GetAttribute("Area")
			if type(area) == "string" then
				built[area] = true
			end
		end
	end
	-- One pad, not one per room (user: "simplify the upgrades around the towers"): it always sells the
	-- cheapest room left in this building, and the sign says how many are left after it.
	local left: { { [string]: any } } = {}
	for _, def in Config.FirmAreas do
		if def.Stage <= stage and built[def.Id] and not owned[def.Id] then
			table.insert(left, def)
		end
	end
	table.sort(left, function(a, b)
		return a.Cost < b.Cost
	end)
	local folder = Instance.new("Folder")
	folder.Name = "AreaPads"
	for slot, def in left do
		if slot > 1 then
			break
		end
		do
			local pad = Instance.new("Part")
			pad.Name = "AreaPad_" .. def.Id
			pad.Anchored = true
			pad.CanCollide = false
			pad.Size = Vector3.new(5, 0.4, 5)
			pad.CFrame = firm.WorldPivot * CFrame.new(PAD_SPOTS[1] + Vector3.new(0, 0.2, 0))
			pad.Material = Enum.Material.Neon
			pad.Color = Color3.fromRGB(98, 205, 48)
			pad.Transparency = 0.15
			pad.TopSurface = Enum.SurfaceType.Smooth
			local light = Instance.new("PointLight")
			light.Color = pad.Color
			light.Range = 10
			light.Brightness = 1
			light.Parent = pad
			local gui = Instance.new("BillboardGui")
			gui.Name = "AreaLabel"
			gui.Size = UDim2.fromOffset(190, 74)
			gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
			gui.MaxDistance = 70
			gui.LightInfluence = 0
			local function line(text: string, y: number, h: number, color: Color3)
				local l = Instance.new("TextLabel")
				l.BackgroundTransparency = 1
				l.Position = UDim2.fromScale(0, y)
				l.Size = UDim2.fromScale(1, h)
				l.Font = Enum.Font.FredokaOne
				l.TextScaled = true
				l.Text = text
				l.TextColor3 = color
				local s = Instance.new("UIStroke")
				s.Thickness = 2.5
				s.Color = Color3.fromRGB(30, 22, 51)
				s.Parent = l
				l.Parent = gui
			end
			line("NEW ROOM: " .. string.upper(def.Name), 0, 0.4, Color3.new(1, 1, 1))
			line(def.Text .. (if #left > 1 then "  (" .. (#left - 1) .. " more after)" else ""), 0.4, 0.3, Color3.fromRGB(214, 210, 245))
			line(Formulas.formatCoins(def.Cost) .. " coins", 0.7, 0.3, Color3.fromRGB(255, 216, 74))
			gui.Parent = pad
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuildPrompt"
			prompt.ActionText = "Build"
			prompt.ObjectText = def.Name
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			CollectionService:AddTag(prompt, "OwnerOnlyPrompt")
			prompt.Parent = pad
			local id = def.Id
			prompt.Triggered:Connect(function(who)
				if who == player then
					buy(player, id)
				end
			end)
			pad.Parent = folder
		end
	end
	folder.Parent = firm
end

------------------------------------------------------------------ showcase + hologram
local function refreshShowcase(player: Player, firm: Model)
	local data = PlayerData.get(player)
	local front = frontOf(firm)
	if not data or not front then
		return
	end
	local pedestals = descendantsWith(front, "ShowcaseSlot")
	if #pedestals == 0 then
		return
	end
	table.sort(pedestals, function(a, b)
		return (a:GetAttribute("ShowcaseSlot") :: number) < (b:GetAttribute("ShowcaseSlot") :: number)
	end)
	local best = bestLawyers(data, #pedestals)
	local sig = {}
	for _, e in best do
		table.insert(sig, e.uid .. ":" .. e.lawyer.Id .. ":" .. e.lawyer.Stars)
	end
	local signature = table.concat(sig, ",")
	if firm:GetAttribute("ShowcaseSig") == signature then
		return
	end
	firm:SetAttribute("ShowcaseSig", signature)
	local old = firm:FindFirstChild("Showcase")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Showcase"
	-- centre pedestals first, so a firm with few lawyers fills the middle of the window
	local order = {}
	for i = 1, #pedestals do
		order[i] = pedestals[i]
	end
	local mid = (#pedestals + 1) / 2
	table.sort(order, function(a, b)
		local da = math.abs((a:GetAttribute("ShowcaseSlot") :: number) - mid)
		local db = math.abs((b:GetAttribute("ShowcaseSlot") :: number) - mid)
		return da < db
	end)
	for i, entry in best do
		local ped = order[i]
		local npc = lawyerModel(entry.lawyer.Id)
		local top = ped.Position + Vector3.new(0, ped.Size.X / 2, 0)
		standAt(npc, top, firm.WorldPivot.LookVector)
		local rid, color = rarityOf(entry.lawyer.Id)
		npc.Parent = folder
		pcall(Effects.aura, npc, rid, entry.lawyer.Stars)
		nameTag(npc, Formulas.lawyerName(entry.lawyer.Id, entry.lawyer.Stars), color, 90)
	end
	folder.Parent = firm
end

local holograms: { [Model]: { model: Model, centre: Vector3, feet: number } } = {}

local function refreshHologram(player: Player, firm: Model)
	local data = PlayerData.get(player)
	local front = frontOf(firm)
	if not data or not front then
		return
	end
	local pads = descendantsWith(front, "Hologram")
	local pad = pads[1]
	if not pad then
		return
	end
	local best = bestLawyers(data, 1)[1]
	local signature = if best then best.lawyer.Id .. ":" .. best.lawyer.Stars else ""
	if firm:GetAttribute("HologramSig") == signature then
		return
	end
	firm:SetAttribute("HologramSig", signature)
	local old = firm:FindFirstChild("Hologram")
	if old then
		holograms[old :: Model] = nil
		old:Destroy()
	end
	if not best then
		return
	end
	local gold = pad:GetAttribute("Hologram") == "Gold"
	local holo = Instance.new("Model")
	holo.Name = "Hologram"
	local npc = lawyerModel(best.lawyer.Id)
	npc:ScaleTo(3.2)
	for _, p in npc:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			p.Transparency = math.max(p.Transparency, 0.18)
			p.CastShadow = false
		end
	end
	local top = pad.Position + Vector3.new(0, pad.Size.X / 2, 0)
	standAt(npc, top, firm.WorldPivot.LookVector)
	npc.Parent = holo
	-- the projector beam
	local _, size = npc:GetBoundingBox()
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = if gold then Color3.fromRGB(255, 205, 70) else Color3.fromRGB(120, 210, 255)
	beam.Transparency = 0.82
	beam.CastShadow = false
	beam.Size = Vector3.new(size.Y + 1, 9, 9)
	beam.CFrame = CFrame.new(top + Vector3.new(0, (size.Y + 1) / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local light = Instance.new("PointLight")
	light.Color = beam.Color
	light.Range = 26
	light.Brightness = 2
	light.Parent = beam
	beam.Parent = holo
	local rid, color = rarityOf(best.lawyer.Id)
	pcall(Effects.aura, npc, rid, best.lawyer.Stars)
	nameTag(npc, Formulas.lawyerName(best.lawyer.Id, best.lawyer.Stars), color, 400)
	holo.Parent = firm
	holograms[holo] = { model = npc, centre = top, feet = top.Y }
end

-- slow spin for every hologram (server-side, a few updates a second is plenty at this size)
task.spawn(function()
	while true do
		local dt = task.wait(0.1)
		for holo, h in holograms do
			if not holo.Parent then
				holograms[holo] = nil
			else
				local piv = h.model:GetPivot()
				h.model:PivotTo(CFrame.new(h.centre.X, piv.Position.Y, h.centre.Z) * CFrame.Angles(0, math.rad(25) * dt, 0) * piv.Rotation)
			end
		end
	end
end)

------------------------------------------------------------------ elevator + hatch lab
local function setupElevator(firm: Model)
	local front = frontOf(firm)
	local count = front and (front:GetAttribute("Floors") :: number?)
	if not front or not count or count < 2 then
		return
	end
	local doors: { [number]: BasePart } = {}
	for _, p in front:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Elevator" and p:GetAttribute("Floor") then
			doors[p:GetAttribute("Floor") :: number] = p
		end
	end
	for floor, door in doors do
		local nextFloor = floor % count + 1
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ElevatorPrompt"
		prompt.ActionText = if nextFloor == 1 then "Down to lobby" else "Up a floor"
		prompt.ObjectText = "Elevator"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = door
		prompt.Triggered:Connect(function(who)
			local target = doors[nextFloor]
			local char = who.Character
			local arrive = target and target:GetAttribute("Arrive") :: Vector3?
			if not char or not arrive then
				return
			end
			-- step out in front of the target door, facing away from it
			local world = firm.WorldPivot:PointToWorldSpace(arrive)
			local doorPos = Vector3.new((target :: BasePart).Position.X, world.Y, (target :: BasePart).Position.Z)
			char:PivotTo(CFrame.lookAt(world, world + (world - doorPos)))
		end)
	end
end

------------------------------------------------------------------ stage-up moment
local function playConstruction(firm: Model)
	local front = frontOf(firm)
	if not front then
		return
	end
	local parts = {}
	local minY, maxY = math.huge, -math.huge
	for _, p in front:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			table.insert(parts, p)
			minY = math.min(minY, p.Position.Y)
			maxY = math.max(maxY, p.Position.Y)
		end
	end
	local span = math.max(1, maxY - minY)
	for _, p in parts do
		local target, t = p.CFrame, p.Transparency
		p.CFrame = target * CFrame.new(0, -5, 0)
		p.Transparency = 1
		local delay = (p.Position.Y + 5 - minY) / span * 2.4
		task.delay(delay, function()
			if p.Parent then
				TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = target, Transparency = t }):Play()
			end
		end)
	end
	-- confetti over the door once it's built
	task.delay(2.6, function()
		if not firm.Parent then
			return
		end
		local emitterPart = Instance.new("Part")
		emitterPart.Name = "Confetti"
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.CanQuery = false
		emitterPart.Transparency = 1
		emitterPart.Size = Vector3.new(30, 1, 6)
		emitterPart.CFrame = firm.WorldPivot * CFrame.new(0, math.min(span, 30), -4)
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 205, 70)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 210, 255)),
		})
		pe.Size = NumberSequence.new(1.2, 0.2)
		pe.Lifetime = NumberRange.new(1.5, 2.5)
		pe.Speed = NumberRange.new(8, 16)
		pe.SpreadAngle = Vector2.new(60, 60)
		pe.Acceleration = Vector3.new(0, -12, 0)
		pe.Rate = 0
		pe.LightEmission = 1
		pe.Parent = emitterPart
		emitterPart.Parent = firm
		pe:Emit(160)
		task.delay(4, function()
			emitterPart:Destroy()
		end)
	end)
end

------------------------------------------------------------------ attach / detach
-- Called by PlotService whenever it builds a firm. previousStage = the stage the firm had before (nil on join).
function FirmFeatures.attach(player: Player, firm: Model, previousStage: number?)
	firms[player] = firm
	local data = PlayerData.get(player)
	FirmStages.applyAreas(firm, ownedAreas(data))
	buildPads(player, firm)
	setupElevator(firm)
	firm:SetAttribute("ShowcaseSig", nil)
	firm:SetAttribute("HologramSig", nil)
	refreshShowcase(player, firm)
	refreshHologram(player, firm)
	local stage = firm:GetAttribute("Stage") :: number? or 1
	if previousStage and stage > previousStage then
		playConstruction(firm)
		StageUp:FireClient(player, { kind = "Stage", stage = stage, name = FirmStages.NAMES[stage] })
	end
end

-- Re-checks the Showcase and the Hologram (cheap when nothing changed). Called on a timer.
function FirmFeatures.refresh(player: Player)
	local firm = firms[player]
	if firm and firm.Parent then
		refreshShowcase(player, firm)
		refreshHologram(player, firm)
	end
end

if RunService:IsServer() and RunService:IsRunning() then
	task.spawn(function()
		while true do
			task.wait(6)
			for player in firms do
				local ok, err = pcall(FirmFeatures.refresh, player)
				if not ok then
					warn("[FirmFeatures]", err)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		firms[player] = nil
	end)
end

return FirmFeatures
