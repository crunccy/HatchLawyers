--!strict
-- WorldLife (StarterPlayerScripts; design pass 2026-10-16): small motion that makes the hub feel alive, all on the
-- client (nothing replicates, nothing is saved):
--   * the Egg Fountain's fish spouts arc brick droplets into the basin
--   * flags, pennants and banners sway (parts named Flag / FlagCloth / PylonFlag / Banner / BannerTail)
--   * the lighthouse at the end of the Arcade Pier sweeps two soft beams
--   * the sailboats out on the water bob and roll (Workspace.IslandEdge.Sailboat)
--   * a few seagulls (ReplicatedStorage.WorldLife.Bird, from Blender) circle the hub, flapping
--   * some clients (ReplicatedStorage.ClientModels) stroll the plaza's walkway ring round the fountain
-- Everything only runs while the player is within HUB_RANGE of the hub; parts that stream out are dropped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local HUB = Vector3.new(0, 0, 40)
local HUB_RANGE = 420

local folder = Instance.new("Folder")
folder.Name = "WorldLife"
folder.Parent = workspace

local function inHub(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - HUB).Magnitude < HUB_RANGE
end

local function clientPart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

------------------------------------------------------------------ swaying flags (found as they stream in)
local SWAY: { [string]: number } = { Flag = 0.16, FlagCloth = 0.2, PylonFlag = 0.22, Banner = 0.06, BannerTail = 0.1 }
local flags: { [BasePart]: { base: CFrame, phase: number, amount: number } } = {}
local function watchFlag(d: Instance)
	if d:IsA("BasePart") and SWAY[d.Name] and not flags[d] and not d:IsDescendantOf(folder) then
		flags[d] = { base = d.CFrame, phase = math.random() * 6.28, amount = SWAY[d.Name] }
	end
end
for _, d in workspace:GetDescendants() do
	watchFlag(d)
end
workspace.DescendantAdded:Connect(watchFlag)
workspace.DescendantRemoving:Connect(function(d)
	if flags[d :: any] then
		flags[d :: any] = nil
	end
end)

------------------------------------------------------------------ fountain droplets
type Drop = { part: Part, from: Vector3, to: Vector3, phase: number }
local drops: { Drop } = {}
local function setupFountain()
	local hub = workspace:FindFirstChild("Hub")
	local fountain = hub and hub:FindFirstChild("EggFountain")
	if not fountain or #drops > 0 then
		return
	end
	local centre = fountain:GetPivot().Position
	for _, spout in fountain:GetChildren() do
		if spout:IsA("BasePart") and spout.Name == "Spout" then
			local from = spout.Position + Vector3.new(0, 0.4, 0)
			local flat = Vector3.new(centre.X - from.X, 0, centre.Z - from.Z)
			local to = Vector3.new(from.X, centre.Y + 2.0, from.Z) + flat * 0.55
			for k = 1, 6 do
				local p = clientPart("Droplet", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(150, 220, 255), Enum.Material.Glass)
				p.Transparency = 0.15
				table.insert(drops, { part = p, from = from, to = to, phase = k / 6 })
			end
		end
	end
end

------------------------------------------------------------------ lighthouse beams
local beams: { Part } = {}
local beamCentre: Vector3? = nil
local function setupLighthouse()
	local pier = workspace:FindFirstChild("ArcadePier")
	local lamp = pier and pier:FindFirstChild("LampRoom", true) :: BasePart?
	if not lamp or #beams > 0 then
		return
	end
	beamCentre = lamp.Position
	for _ = 1, 2 do
		local b = clientPart("LighthouseBeam", Vector3.new(1.6, 2.6, 46), Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
		b.Transparency = 0.72
		table.insert(beams, b)
	end
end

------------------------------------------------------------------ sailboats
local boats: { [Model]: { base: CFrame, phase: number } } = {}
local function setupBoats()
	local edge = workspace:FindFirstChild("IslandEdge")
	local holder = edge and edge:FindFirstChild("Sailboat")
	if not holder then
		return
	end
	for _, m in holder:GetChildren() do
		if m:IsA("Model") and not boats[m] then
			boats[m] = { base = m:GetPivot(), phase = math.random() * 6.28 }
		end
	end
end

------------------------------------------------------------------ seagulls
type Bird = { model: Model, wingL: BasePart?, wingR: BasePart?, radius: number, height: number, speed: number, phase: number }
local birds: { Bird } = {}
local function setupBirds()
	local lib = ReplicatedStorage:FindFirstChild("WorldLife")
	local template = lib and lib:FindFirstChild("Bird")
	if not template or #birds > 0 then
		return
	end
	for i = 1, 6 do
		local m = template:Clone() :: Model
		m.Parent = folder
		table.insert(birds, {
			model = m,
			wingL = m:FindFirstChild("WingL") :: BasePart?,
			wingR = m:FindFirstChild("WingR") :: BasePart?,
			radius = 60 + i * 14,
			height = 38 + (i % 3) * 7,
			speed = (0.11 + i * 0.012) * (if i % 2 == 0 then 1 else -1),
			phase = i * 1.1,
		})
	end
end

------------------------------------------------------------------ strolling clients
type Walker = { model: Model, angle: number, speed: number, radius: number, y: number, offset: CFrame }
local walkers: { Walker } = {}
local function setupWalkers()
	local lib = ReplicatedStorage:FindFirstChild("ClientModels")
	if not lib or #walkers > 0 then
		return
	end
	local pool = lib:GetChildren()
	if #pool == 0 then
		return
	end
	for i = 1, 4 do
		local m = pool[math.random(1, #pool)]:Clone() :: Model
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("BillboardGui") then
				d:Destroy()
			end
		end
		local box, size = m:GetBoundingBox()
		m.Parent = folder
		table.insert(walkers, {
			model = m,
			angle = i * math.pi / 2,
			speed = (0.075 + i * 0.01) * (if i % 2 == 0 then 1 else -1),
			radius = 20,
			y = size.Y / 2 + 0.5, -- (the plaza's top is y 0.5)
			offset = box:ToObjectSpace(m:GetPivot()), -- (a client model's pivot isn't its middle)
		})
	end
end

------------------------------------------------------------------ one loop for all of it (30 Hz is plenty)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then
		return
	end
	local step = acc
	acc = 0
	local active = inHub()
	folder.Parent = if active then workspace else nil
	if not active then
		return
	end
	setupFountain()
	setupLighthouse()
	setupBoats()
	setupBirds()
	setupWalkers()
	local t = os.clock()

	for part, f in flags do
		if part.Parent then
			part.CFrame = f.base * CFrame.Angles(0, math.sin(t * 2.2 + f.phase) * f.amount, math.sin(t * 1.7 + f.phase) * f.amount * 0.3)
		else
			flags[part] = nil
		end
	end

	for _, d in drops do
		local u = (t * 0.9 + d.phase) % 1
		local pos = d.from:Lerp(d.to, u) + Vector3.new(0, math.sin(u * math.pi) * 3.2, 0)
		d.part.CFrame = CFrame.new(pos)
		d.part.Transparency = 0.15 + u * 0.6
	end

	if beamCentre then
		for i, b in beams do
			local a = t * 0.7 + i * math.pi
			b.CFrame = CFrame.new(beamCentre) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -23.5)
		end
	end

	for m, b in boats do
		if m.Parent then
			m:PivotTo(b.base * CFrame.new(0, math.sin(t * 1.1 + b.phase) * 0.35, 0) * CFrame.Angles(math.sin(t * 0.8 + b.phase) * 0.03, 0, math.sin(t * 0.9 + b.phase) * 0.05))
		else
			boats[m] = nil
		end
	end

	for _, b in birds do
		local a = t * b.speed + b.phase
		local pos = HUB + Vector3.new(math.cos(a) * b.radius, b.height + math.sin(t * 0.7 + b.phase) * 2, math.sin(a) * b.radius)
		local ahead = HUB + Vector3.new(math.cos(a + 0.05 * math.sign(b.speed)) * b.radius, b.height, math.sin(a + 0.05 * math.sign(b.speed)) * b.radius)
		local cf = CFrame.lookAt(pos, Vector3.new(ahead.X, pos.Y, ahead.Z)) * CFrame.Angles(0, 0, -0.25 * math.sign(b.speed))
		b.model:PivotTo(cf)
		local flap = math.sin(t * 9 + b.phase) * 0.6
		if b.wingL then
			b.wingL.CFrame = cf * CFrame.new(-0.5, 0.2, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-1.1, 0, 0)
		end
		if b.wingR then
			b.wingR.CFrame = cf * CFrame.new(0.5, 0.2, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(1.1, 0, 0)
		end
	end

	for _, w in walkers do
		w.angle += w.speed * step * 6
		local pos = Vector3.new(math.sin(w.angle) * w.radius, w.y + math.abs(math.sin(t * 7 + w.angle)) * 0.25, math.cos(w.angle) * w.radius)
		local dir = Vector3.new(math.cos(w.angle), 0, -math.sin(w.angle)) * math.sign(w.speed)
		w.model:PivotTo(CFrame.lookAt(pos, pos + dir) * w.offset)
	end
end)

