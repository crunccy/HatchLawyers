--!strict
-- Assembles a player's law firm from the Blender kit (ServerStorage.Templates.FirmKit, each piece
-- tagged with its "Offset" from the kit origin) and adds the working parts the game uses.
--
-- Layout, in firm-local studs (origin = the entrance line on the floor, -Z faces the street):
--   Entrance (portico + steps, z -6..0) -> lobby (the old WaitingRoom piece, z 0..21) -> OfficeSegment x N
--   (one lawyer slot per wall) -> ExpansionLock (if more can be bought) -> BackWall.
-- v16 (egg zones): no more waiting room. Its chairs, coffee tables and queue ropes are stripped from the lobby
-- (floor, walls, rugs and the reception desk stay) and two INCUBATORS stand where the chairs were (tag
-- "Incubator"; Server.ZoneService hatches carried eggs there). Clients walk from the street straight to a free
-- lawyer (routeToDesk).
-- Slots: slot 1 is the first office on the -X wall, slot 2 the one facing it on the +X wall, then
-- the next segment, and so on. Desk<N> models carry Top / LawyerSpot / ClientSpot like the old firm.
-- Every office is a Desk<N> (v12); an empty one shows its EmptyOffice pad + PlacePrompt (CaseService
-- toggles them as lawyers are placed).

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local FirmStages = require(script.Parent:WaitForChild("FirmStages"))

local FirmBuilder = {}

FirmBuilder.WAIT_DEPTH = 21
FirmBuilder.SEG_DEPTH = 11 -- office spacing along a wall (tools/firm_pieces.py SEG; was 8, felt cramped)
FirmBuilder.SLOT_X = 15.5
FirmBuilder.WIDTH = 48
FirmBuilder.FLOOR_H = 1.5 -- the firm floor sits on a stone foundation this high above the plot grass

local SIGN_GREEN = Color3.fromRGB(30, 110, 50) -- mr.robe's courtroom palette
local WOOD_DARK = Color3.fromRGB(92, 48, 22)

-- Kit pieces: Templates.FirmKitParts holds each piece as a Model of plain Plastic Parts (the same
-- build style as the rest of the map; pivot = the piece's origin). Templates.FirmKit (old textured
-- MeshParts with an "Offset" attribute) is only a fallback.
local function kitPiece(name: string): Instance
	local parts = ServerStorage.Templates:FindFirstChild("FirmKitParts")
	return (parts and parts:FindFirstChild(name)) or ServerStorage.Templates.FirmKit:FindFirstChild(name) :: Instance
end

local function place(parent: Instance, name: string, at: CFrame): Instance
	local template = kitPiece(name)
	local p = template:Clone()
	if p:IsA("Model") then
		p:PivotTo(at)
	else
		(p :: BasePart).CFrame = at * CFrame.new(template:GetAttribute("Offset") :: Vector3)
	end
	p.Parent = parent
	return p
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Studs -- studded like the rest of the map
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local INVISIBLE = { Transparency = 1, CanTouch = false, CanQuery = false, CastShadow = false }
local MARKER = { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false }

-- The firm's frame on a plot: the entrance line at the plot's street-side edge, minus the porch,
-- raised onto the foundation (FLOOR_H above the grass).
function FirmBuilder.frame(plot: Model): CFrame
	local base = plot:FindFirstChild("Base") :: BasePart?
	local half = if base then base.Size.Z / 2 else 28
	return plot:GetPivot() * CFrame.new(0, FirmBuilder.FLOOR_H, -(half - 6))
end

function FirmBuilder.slotSide(slot: number): number
	return if slot % 2 == 1 then -1 else 1
end

function FirmBuilder.slotZ(slot: number): number
	local segment = (slot + 1) // 2 - 1
	return FirmBuilder.WAIT_DEPTH + segment * FirmBuilder.SEG_DEPTH + FirmBuilder.SEG_DEPTH / 2
end

-- Frame of one slot's furniture: origin at the slot centre, local +X points at the aisle.
function FirmBuilder.slotFrame(frame: CFrame, slot: number): CFrame
	local side = FirmBuilder.slotSide(slot)
	local cf = frame * CFrame.new(side * FirmBuilder.SLOT_X, 0, FirmBuilder.slotZ(slot))
	return if side == 1 then cf * CFrame.Angles(0, math.pi, 0) else cf
end

-- Feet-on-floor spot facing a direction (NPCs face their spot's LookVector).
local function spotCF(at: Vector3, toward: Vector3): CFrame
	return CFrame.lookAt(at, Vector3.new(toward.X, at.Y, toward.Z))
end

local function buildDeskModel(firm: Model, frame: CFrame, slot: number, name: string): Model
	local slotCF = FirmBuilder.slotFrame(frame, slot)
	local desk = Instance.new("Model")
	desk.Name = name
	desk:SetAttribute("DeskIndex", slot)
	local mesh = place(desk, "LawyerDesk", slotCF)
	mesh.Name = "DeskMesh"
	-- Top: an invisible stand-in for the desk top (DeskLook dresses tiers relative to it)
	local top = part(desk, "Top", Vector3.new(2.5, 0.4, 5.2), slotCF * CFrame.new(-0.05, 2.45, 0), MARKER)
	local lawyerAt = slotCF:PointToWorldSpace(Vector3.new(-2.3, 0.1, 0))
	local clientAt = slotCF:PointToWorldSpace(Vector3.new(2.6, 0.1, 0))
	part(desk, "LawyerSpot", Vector3.new(1, 0.2, 1), spotCF(lawyerAt, clientAt), MARKER)
	part(desk, "ClientSpot", Vector3.new(1, 0.2, 1), spotCF(clientAt, lawyerAt), MARKER)
	desk.PrimaryPart = top
	desk.Parent = firm
	return desk
end

-- A lawyer's office: Desk<slot>, tagged Desk, with the tutorial's TakeCase prompt on the top, and
-- the empty-office pad / label / Equip Lawyer prompt (shown while no lawyer sits here).
function FirmBuilder.buildDesk(firm: Model, frame: CFrame, slot: number): Model
	local desk = buildDeskModel(firm, frame, slot, "Desk" .. slot)
	CollectionService:AddTag(desk, "Desk")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakeCase"
	prompt.ActionText = "Take Case"
	prompt.ObjectText = "Desk"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = desk:FindFirstChild("Top")

	local spot = desk:FindFirstChild("LawyerSpot") :: BasePart
	local pad = part(desk, "EmptyOffice", Vector3.new(3, 0.2, 3), spot.CFrame * CFrame.new(0, 0.05, 0),
		{ Color = Color3.fromRGB(255, 190, 50), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Transparency = 0.15 })
	local gui = Instance.new("BillboardGui")
	gui.Name = "EmptyLabel"
	gui.Size = UDim2.fromOffset(130, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = 35 -- only up close, so a row of empty offices doesn't fill the screen with words
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "EMPTY OFFICE"
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	gui.Adornee = pad
	gui.Parent = pad
	local place = Instance.new("ProximityPrompt")
	place.Name = "PlacePrompt"
	place.ActionText = "Equip Lawyer" -- (user's call: equip / unequip wording)
	place.ObjectText = "Office " .. slot
	place.HoldDuration = 0
	place.MaxActivationDistance = 10
	place.RequiresLineOfSight = false
	CollectionService:AddTag(place, "OwnerOnlyPrompt")
	place.Parent = pad
	return desk
end

-- An office bought but not hired yet: furniture, a glowing pad and (for the next slot) a hire prompt.
function FirmBuilder.buildHireSlot(firm: Model, frame: CFrame, slot: number, price: string?, isNext: boolean): Model
	local desk = buildDeskModel(firm, frame, slot, "HireSlot" .. slot)
	local spot = desk:FindFirstChild("LawyerSpot") :: BasePart
	local pad = part(desk, "HirePad", Vector3.new(3, 0.2, 3), spot.CFrame * CFrame.new(0, 0.05, 0),
		{ Color = if isNext then Color3.fromRGB(80, 230, 110) else Color3.fromRGB(160, 160, 170), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false })
	local gui = Instance.new("BillboardGui")
	gui.Name = "HireLabel"
	gui.Size = UDim2.fromOffset(170, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 70
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = if isNext then "HIRE LAWYER\n" .. (price or "") else "EMPTY OFFICE"
	label.Parent = gui
	gui.Adornee = pad
	gui.Parent = pad
	if isNext then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HirePrompt"
		prompt.ActionText = "Hire Lawyer"
		prompt.ObjectText = price or ""
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		CollectionService:AddTag(prompt, "OwnerOnlyPrompt")
		prompt.Parent = pad
	end
	return desk
end

-- Incubators, firm-local: on the lobby rugs where the waiting room's chairs and coffee tables were.
FirmBuilder.INCUBATORS = { Vector3.new(-15.7, 0, 8), Vector3.new(15.7, 0, 8) }

-- The waiting room's furniture inside the WaitingRoom kit piece (firm-local positions; floor, walls, rugs, the
-- divider wall and the reception desk are kept).
local function isWaitingFurniture(lp: Vector3): boolean
	local ax, y, z = math.abs(lp.X), lp.Y, lp.Z
	if y < 0.15 or y > 3.4 then
		return false
	end
	return (ax >= 19 and ax <= 22.7 and z >= 2.5 and z <= 13.6) -- bench rows along both walls
		or (ax >= 9 and ax <= 12.5 and z >= 14 and z <= 17) -- the two corner seats
		or (ax >= 13.5 and ax <= 18 and z >= 3.5 and z <= 12.5) -- coffee tables, legs, magazines, mug
		or (lp.X >= 8 and lp.X <= 19 and z >= 16.5 and z <= 20.2) -- the queue-rope stanchions
		or (lp.X >= 21.4 and lp.X <= 23 and z >= 15 and z <= 17) -- water cooler
		or (lp.X <= -21.2 and lp.X >= -23 and z >= 14.4 and z <= 17.8) -- notice board
end

local function stripWaitingRoom(room: Instance, frame: CFrame)
	for _, p in room:GetDescendants() do
		if p:IsA("BasePart") and isWaitingFurniture(frame:PointToObjectSpace(p.Position)) then
			p:Destroy()
		end
	end
end

-- An incubator, v5 (2026-10-12): the Blender-made machine (ServerStorage.Templates.IncubatorV5 from
-- tools/blender/incubator.py + tools/zones/BuildEggsV5.lua: a dome that rises and spins, heat lamps, a halo, a lift
-- cradle), its control panel facing the aisle (x = 0). Clients animate it during a hatch (Shared.Incubator).
-- Without the template: the old one, built from parts below.
local function buildIncubator(parent: Instance, frame: CFrame, index: number, at: Vector3)
	local templates = ServerStorage:FindFirstChild("Templates")
	local template = templates and templates:FindFirstChild("IncubatorV5")
	if template then
		local m = template:Clone() :: Model
		m.Name = "Incubator" .. index
		local yaw = if at.X < 0 then -math.pi / 2 else math.pi / 2 -- (its front is -Z: turned to face the aisle)
		m:PivotTo(frame * CFrame.new(at) * CFrame.Angles(0, yaw, 0))
		local prompt = m:FindFirstChild("IncubatorPrompt", true)
		if prompt then
			CollectionService:AddTag(prompt, "OwnerOnlyPrompt")
		end
		CollectionService:AddTag(m, "Incubator")
		m.Parent = parent
		return
	end	local m = Instance.new("Model")
	m.Name = "Incubator" .. index
	local cf = frame * CFrame.new(at)
	local side = if at.X < 0 then -1 else 1 -- the lamp stands on the wall side
	local function cyl(name: string, d: number, h: number, y: number, props: { [string]: any }): Part
		local p = part(m, name, Vector3.new(h, d, d), cf * CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), props)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	local base = cyl("Base", 5.2, 1.2, 0, { Color = Color3.fromRGB(245, 245, 245) })
	cyl("Trim", 5.5, 0.25, 1.2, { Color = Color3.fromRGB(255, 196, 46), CanCollide = false })
	cyl("HeatRing", 4.4, 0.2, 1.45, { Color = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Neon, CanCollide = false })
	cyl("Nest", 3.8, 0.5, 1.45, { Color = Color3.fromRGB(200, 150, 80), CanCollide = false })
	local egg = part(m, "DisplayEgg", Vector3.new(2.2, 2.8, 2.2), cf * CFrame.new(0, 3.3, 0), { Color = Color3.fromRGB(250, 240, 220), CanCollide = false, CanQuery = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	part(m, "Dome", Vector3.new(4.6, 4.6, 4.6), cf * CFrame.new(0, 2.0, 0), { Shape = Enum.PartType.Ball, Material = Enum.Material.Glass, Transparency = 0.65, Color = Color3.fromRGB(190, 230, 255), CanCollide = false, CanQuery = false })
	local dark = Color3.fromRGB(60, 60, 72)
	part(m, "LampPost", Vector3.new(0.5, 6.5, 0.5), cf * CFrame.new(side * 3.3, 3.25, 0), { Color = dark })
	part(m, "LampArm", Vector3.new(2.6, 0.4, 0.4), cf * CFrame.new(side * 2.2, 6.3, 0), { Color = dark, CanCollide = false })
	local lamp = part(m, "Lamp", Vector3.new(1.4, 0.8, 1.4), cf * CFrame.new(side * 1.0, 5.9, 0), { Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon, CanCollide = false })
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 150, 70)
	glow.Range = 10
	glow.Brightness = 1.2
	glow.Shadows = false
	glow.Parent = lamp
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "IncubatorPrompt"
	prompt.ActionText = "Hatch Egg"
	prompt.ObjectText = "Incubator"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	CollectionService:AddTag(prompt, "OwnerOnlyPrompt")
	prompt.Parent = base
	m.PrimaryPart = base
	CollectionService:AddTag(m, "Incubator")
	m.Parent = parent
end

-- Walking routes (firm-local points), so clients go around the coffee tables and through the arch.
FirmBuilder.STREET = Vector3.new(0, -FirmBuilder.FLOOR_H, -7.5) -- on the grass in front of the steps
FirmBuilder.PORCH = Vector3.new(0, 0, -3.5)
FirmBuilder.DOOR = Vector3.new(0, 0, -0.5)

-- From the street, in through the door and down the aisle (x = 0, between the incubators) to the lawyer's desk.
function FirmBuilder.routeToDesk(slot: number): { Vector3 }
	local z = FirmBuilder.slotZ(slot)
	local clientX = FirmBuilder.slotSide(slot) * (FirmBuilder.SLOT_X - 2.6)
	return { FirmBuilder.STREET, FirmBuilder.PORCH, FirmBuilder.DOOR, Vector3.new(0, 0, 2.0), Vector3.new(0, 0, z), Vector3.new(clientX, 0, z) }
end

function FirmBuilder.routeDeskToExit(slot: number): { Vector3 }
	local z = FirmBuilder.slotZ(slot)
	local clientX = FirmBuilder.slotSide(slot) * (FirmBuilder.SLOT_X - 2.6)
	return { Vector3.new(clientX, 0, z), Vector3.new(0, 0, z), Vector3.new(0, 0, 2.0), FirmBuilder.DOOR, FirmBuilder.PORCH, FirmBuilder.STREET, FirmBuilder.STREET + Vector3.new(0, 0, -4) }
end

function FirmBuilder.depth(segments: number, locked: boolean): number
	return FirmBuilder.WAIT_DEPTH + segments * FirmBuilder.SEG_DEPTH + (if locked then FirmBuilder.SEG_DEPTH else 0) + 3
end

-- Builds the whole firm. segments = offices segments owned; lawyers = lawyers hired (<= segments*2).
-- hirePrice(slot) -> price text for the next empty slot. stage (FirmStages, 1-6) picks the front building
-- and the hall's style; it defaults to the one for this many segments. Returns the model (named "Firm").
function FirmBuilder.build(plot: Model, segments: number, lawyers: number, maxSegments: number, hirePrice: (number) -> string, stage: number?): Model
	local frame = FirmBuilder.frame(plot)
	local firm = Instance.new("Model")
	firm.Name = "Firm"
	firm:SetAttribute("Segments", segments)
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = firm

	-- the old kit Entrance is replaced by the stage's front building (FirmStages), built over the lobby
	stripWaitingRoom(place(shell, "WaitingRoom", frame), frame)
	for s = 0, segments - 1 do
		place(shell, "OfficeSegment", frame * CFrame.new(0, 0, FirmBuilder.WAIT_DEPTH + s * FirmBuilder.SEG_DEPTH))
	end
	local locked = segments < maxSegments
	local zEnd = FirmBuilder.WAIT_DEPTH + segments * FirmBuilder.SEG_DEPTH
	if locked then
		place(shell, "ExpansionLock", frame * CFrame.new(0, 0, zEnd))
		part(firm, "UpgradeSpot", Vector3.new(1, 0.2, 1), frame * CFrame.new(0, 0.1, zEnd + 3.0) * CFrame.Angles(0, math.pi, 0), MARKER)
		zEnd += FirmBuilder.SEG_DEPTH
	end
	place(shell, "BackWall", frame * CFrame.new(0, 0, zEnd))
	local depth = zEnd + 3
	local stageN = stage or FirmStages.stageFor(segments)
	local signCF = FirmStages.buildFront(firm, frame, stageN)
	FirmStages.dressHall(firm, frame, stageN, FirmBuilder.WAIT_DEPTH, zEnd)

	-- invisible colliders (the kit meshes don't collide): the raised floor down to the grass, the porch
	-- landing and two steps (kit: landing z -4.5..0, steps 0.75 deep, tops at -0.5 and -1.0), walls
	local colliders = Instance.new("Folder")
	colliders.Name = "Colliders"
	colliders.Parent = firm
	local w, fh = FirmBuilder.WIDTH, FirmBuilder.FLOOR_H
	part(colliders, "Floor", Vector3.new(w, fh, depth), frame * CFrame.new(0, -fh / 2, depth / 2), INVISIBLE)
	part(colliders, "Porch", Vector3.new(22, fh, 4.5), frame * CFrame.new(0, -fh / 2, -2.25), INVISIBLE)
	part(colliders, "Step1", Vector3.new(22, fh - 0.5, 0.75), frame * CFrame.new(0, -(fh + 0.5) / 2, -4.875), INVISIBLE)
	part(colliders, "Step2", Vector3.new(22, fh - 1.0, 0.75), frame * CFrame.new(0, -(fh + 1.0) / 2, -5.625), INVISIBLE)
	for _, sx in { -1, 1 } do
		part(colliders, "SideWall", Vector3.new(0.8, 6, depth), frame * CFrame.new(sx * (w / 2 - 0.4), 3, depth / 2), INVISIBLE)
		part(colliders, "FrontWall", Vector3.new(14.5, 6, 1), frame * CFrame.new(sx * 16.75, 3, -0.3), INVISIBLE)
	end
	part(colliders, "BackWall", Vector3.new(w, 7, 1), frame * CFrame.new(0, 3.5, depth - 0.4), INVISIBLE)

	-- name sign on the portico (PlotService writes "<Name>'s Law Firm" into Sign > Label)
	part(firm, "SignFrame", Vector3.new(13.6, 1.3, 0.25), signCF * CFrame.new(0, 0, 0.12), { Color = WOOD_DARK, CanCollide = false })
	local sign = part(firm, "Sign", Vector3.new(13, 1.0, 0.3), signCF, { Color = SIGN_GREEN, CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Law Firm"
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label

	-- markers other systems look for
	part(firm, "SpawnPoint", Vector3.new(4, 1, 4), frame * CFrame.new(0, 0.5, 3), MARKER)
	part(firm, "ManagerSpot", Vector3.new(1, 0.2, 1), frame * CFrame.new(-13.5, 0.1, 20.0), MARKER)
	local incubators = Instance.new("Folder")
	incubators.Name = "Incubators"
	incubators.Parent = firm
	for i, at in FirmBuilder.INCUBATORS do
		buildIncubator(incubators, frame, i, at)
	end

	-- every office is a working desk; CaseService shows the empty-office pad where nobody sits
	for slot = 1, segments * 2 do
		FirmBuilder.buildDesk(firm, frame, slot)
	end

	firm.WorldPivot = frame
	FirmBuilder.clearDecor(plot, frame, depth)
	return firm
end

-- Island scenery (Workspace.IslandDecor / Shrubbery trees, bushes, cliffs) that a firm's footprint would
-- grow through is tucked into ServerStorage.HiddenDecor while that firm is that big, and put back when the
-- firm is rebuilt smaller (prestige). Nothing is deleted; each hidden model remembers its folder and plot.
local DECOR_FOLDERS = { "IslandDecor", "Shrubbery" }

function FirmBuilder.clearDecor(plot: Model, frame: CFrame, depth: number)
	local hidden = ServerStorage:FindFirstChild("HiddenDecor")
	if not hidden then
		hidden = Instance.new("Folder")
		hidden.Name = "HiddenDecor"
		hidden.Parent = ServerStorage
	end
	-- put back what this plot hid before, then hide what the new footprint overlaps
	for _, model in hidden:GetChildren() do
		if model:GetAttribute("HiddenBy") == plot.Name then
			local home = workspace:FindFirstChild(model:GetAttribute("DecorFolder") :: string)
			if home then
				model:SetAttribute("HiddenBy", nil)
				model.Parent = home
			end
		end
	end
	local folders = {}
	for _, name in DECOR_FOLDERS do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(folders, f)
		end
	end
	if #folders == 0 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = folders
	-- the firm plus its foundation skirt and the bushes along it, from the steps to the back wall
	local box = frame * CFrame.new(0, 4, (depth - 7) / 2)
	local size = Vector3.new(FirmBuilder.WIDTH + 6, 12, depth + 9)
	for _, hit in workspace:GetPartBoundsInBox(box, size, params) do
		local model: Instance = hit
		while model.Parent and not table.find(folders, model.Parent :: any) do
			model = model.Parent :: Instance
		end
		local folder = model.Parent
		if folder and table.find(folders, folder :: any) then
			model:SetAttribute("DecorFolder", folder.Name)
			model:SetAttribute("HiddenBy", plot.Name)
			model.Parent = hidden
		end
	end
end

return FirmBuilder
