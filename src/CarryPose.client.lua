--!strict
-- CarryPose (StarterPlayerScripts.CarryPose, 2026-10-12, written blind in a cloud session: playtest it). How a player
-- carries zone eggs (Server.ZoneService keeps the list; the player attribute "Carried" = "Briefcase,Pet*,..." with *
-- = golden). Every client draws this for EVERY carrying player, so everyone sees it - nothing here touches gameplay.
--   * the arms go out in front, hugging the bottom egg (Motor6D.Transform set after the animations each frame, so
--     walking / jumping still play underneath; R6 and R15 both). It blends in and out over POSE_BLEND seconds.
--   * the eggs are oversized (about as wide as the torso) and stack the way you'd pile big eggs in your arms: each
--     one sits a little into the one below, a bit off to one side and tilted, and the pile leans back against the
--     chest as it grows. While walking the pile sways - more at the top.
-- (Replaces ZoneService's eggs-over-the-head; its refreshCarryVisual now only clears the old model.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any

local POSE_BLEND = 0.2 -- seconds for the arms to go out / come back
local ARM_PITCH = math.rad(72) -- how far the arms swing forward (90 = straight out)
local ARM_INWARD = math.rad(12) -- how far each arm turns in toward the egg
local EGG_WIDTH = 0.95 -- x the torso's width
local EGG_TALL = 1.22 -- x the egg's width
local NEST = 0.8 -- each egg sits this share of an egg's height above the one below (eggs are round, they nest)
local LEAN_BACK = 0.14 -- studs each egg sits further back toward the chest than the one below
local LEAN_TILT = math.rad(5) -- and the pile tilts back this much more per egg
-- each egg's own "not perfectly placed" offset: { sideways (x egg width), roll (deg), yaw (deg) }
local JITTER = {
	{ 0, 0, 0 },
	{ 0.16, 9, 25 },
	{ -0.14, -11, -40 },
	{ 0.12, 7, 70 },
	{ -0.18, -9, -15 },
	{ 0.1, 12, 50 },
	{ -0.12, -8, -60 },
}

local visuals = Instance.new("Folder")
visuals.Name = "CarryVisuals"
visuals.Parent = workspace

------------------------------------------------------------------ eggs
local function eggColor(egg: string, golden: boolean): Color3
	local z = Config.Zones
	if golden and z and z.EggColors and z.EggColors.Golden then
		return z.EggColors.Golden
	end
	if z and z.EggColors and z.EggColors[egg] then
		return z.EggColors[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.new(1, 1, 1)
end

local function parseCarried(value: any): { { egg: string, golden: boolean } }
	local list = {}
	if typeof(value) == "string" and value ~= "" then
		for item in string.gmatch(value, "[^,]+") do
			local golden = string.sub(item, -1) == "*"
			table.insert(list, { egg = if golden then string.sub(item, 1, -2) else item, golden = golden })
		end
	end
	return list
end

local function makeEgg(color: Color3, golden: boolean, size: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "CarriedEgg"
	p.Size = size
	p.Color = color
	p.Material = if golden then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	p.Parent = visuals
	return p
end

------------------------------------------------------------------ per character
type Arm = { motor: Motor6D, side: number } -- side: 1 = right, -1 = left
type Carrier = {
	player: Player,
	character: Model,
	torso: BasePart,
	root: BasePart,
	arms: { Arm },
	eggs: { BasePart },
	key: string, -- the Carried value the eggs were built for
	blend: number, -- 0 = arms down .. 1 = carrying pose
	phase: number, -- sway clock
}
local carriers: { [Player]: Carrier } = {}

local function armsOf(character: Model): { Arm }
	local arms = {}
	local specs: { { part: string, joint: string, side: number } } = {
		{ part = "Torso", joint = "Right Shoulder", side = 1 }, { part = "Torso", joint = "Left Shoulder", side = -1 }, -- R6
		{ part = "RightUpperArm", joint = "RightShoulder", side = 1 }, { part = "LeftUpperArm", joint = "LeftShoulder", side = -1 }, -- R15
	}
	for _, spec in specs do
		local part = character:FindFirstChild(spec.part)
		local motor = part and part:FindFirstChild(spec.joint)
		if motor and motor:IsA("Motor6D") then
			table.insert(arms, { motor = motor, side = spec.side })
		end
	end
	return arms
end

local function clearEggs(c: Carrier)
	for _, e in c.eggs do
		e:Destroy()
	end
	c.eggs = {}
end

local function rebuildEggs(c: Carrier, value: any)
	clearEggs(c)
	c.key = if typeof(value) == "string" then value else ""
	local w = c.torso.Size.X * EGG_WIDTH
	local size = Vector3.new(w, w * EGG_TALL, w)
	for _, item in parseCarried(value) do
		table.insert(c.eggs, makeEgg(eggColor(item.egg, item.golden), item.golden, size))
	end
end

local function drop(player: Player)
	local c = carriers[player]
	if c then
		clearEggs(c)
		for _, arm in c.arms do
			if arm.motor.Parent then
				arm.motor.Transform = CFrame.identity
			end
		end
		carriers[player] = nil
	end
end

local function track(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not torso or not torso:IsA("BasePart") or not root or not root:IsA("BasePart") then
		drop(player)
		return
	end
	local existing: Carrier? = carriers[player]
	if existing and existing.character ~= character then
		drop(player)
		existing = nil
	end
	local c: Carrier = existing or {
		player = player, character = character, torso = torso :: BasePart, root = root :: BasePart,
		arms = armsOf(character), eggs = {}, key = "", blend = 0, phase = 0,
	}
	carriers[player] = c
	local value = player:GetAttribute("Carried")
	if (if typeof(value) == "string" then value else "") ~= c.key then
		rebuildEggs(c, value)
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Carried"):Connect(function()
		track(player)
	end)
	player.CharacterAdded:Connect(function(character)
		drop(player)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait() -- (let the rig's joints arrive)
		track(player)
	end)
	if player.Character then
		task.spawn(track, player)
	end
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(drop)
for _, p in Players:GetPlayers() do
	watch(p)
end

------------------------------------------------------------------ the arms (after the animations, every frame)
-- The arm's pose is solved from the joint itself: rotate the arm about the shoulder point, in the torso's space, then
-- turn that into the motor's Transform (Part1 = Part0 * C0 * Transform * C1:Inverse()). Works whatever the rig.
local function armTransform(motor: Motor6D, side: number, blend: number): CFrame
	local rest = motor.C0 * motor.C1:Inverse() -- the arm hanging down, in Part0's space
	local pivot = CFrame.new(motor.C0.Position)
	local turn = CFrame.Angles(0, side * ARM_INWARD * blend, 0) * CFrame.Angles(ARM_PITCH * blend, 0, 0)
	local wanted = pivot * turn * pivot:Inverse() * rest
	return motor.C0:Inverse() * wanted * motor.C1
end

RunService.Stepped:Connect(function(_, dt)
	for player, c in carriers do
		if not c.character.Parent then
			drop(player)
			continue
		end
		local target = if #c.eggs > 0 then 1 else 0
		c.blend = if target > c.blend then math.min(c.blend + dt / POSE_BLEND, 1) else math.max(c.blend - dt / POSE_BLEND, 0)
		if c.blend > 0 then
			for _, arm in c.arms do
				if arm.motor.Parent then
					arm.motor.Transform = armTransform(arm.motor, arm.side, c.blend)
				end
			end
		end
	end
end)

------------------------------------------------------------------ the egg pile (every rendered frame)
RunService.RenderStepped:Connect(function(dt)
	local parts, frames = {}, {}
	for _, c in carriers do
		if #c.eggs == 0 or not c.torso.Parent then
			continue
		end
		local speed = Vector3.new(c.root.AssemblyLinearVelocity.X, 0, c.root.AssemblyLinearVelocity.Z).Magnitude
		local moving = math.clamp(speed / 16, 0, 1)
		c.phase += dt * (3 + 6 * moving)
		local w = c.torso.Size.X * EGG_WIDTH
		local h = w * EGG_TALL
		-- the bottom egg sits in the arms, just in front of the chest, a little below the shoulders
		local y = c.torso.Size.Y * 0.5 - h * 0.62
		local z = -(c.torso.Size.Z * 0.5 + w * 0.5 - 0.1) -- (front is -Z)
		local x = 0
		local cf = c.torso.CFrame
		local tilt = 0
		for i, egg in c.eggs do
			local j = JITTER[((i - 1) % #JITTER) + 1]
			if i > 1 then
				y += h * NEST
				z += LEAN_BACK
				tilt += LEAN_TILT
			end
			-- sway: barely while standing, more while walking, more the higher up the pile
			local sway = math.sin(c.phase + i * 0.9) * math.rad(1 + (i - 1) * (1.5 + 3 * moving))
			x = j[1] * w + math.sin(c.phase * 0.5 + i) * 0.04 * (i - 1) * (0.3 + moving)
			table.insert(parts, egg)
			table.insert(frames, cf * CFrame.new(x, y, z)
				* CFrame.Angles(tilt, math.rad(j[3]), math.rad(j[2]) + sway))
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
