-- tools/zones/BuildEggs.lua - turns tools/zones/eggs.json (exported by tools/blender/eggs.py) into
-- ReplicatedStorage.EggModels: one Model per egg (Briefcase, Pet, Brainrot, Food, Ocean, Space) + GoldenKit (the
-- extras a golden egg wears). Smooth glossy parts (no studs), anchored, no collisions. Each Model's pivot is the
-- middle of the egg's bottom; PrimaryPart = "Shell" (the lower half of the shell); attribute Height = 3.8 (the shell).
-- Shared.EggLook builds the eggs the game shows from these. Re-runnable (replaces the folder).
-- Run in Edit mode with the JSON reachable at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSON_URL = "http://localhost:8766/eggs.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local old = ReplicatedStorage:FindFirstChild("EggModels")
if old then
	old:Destroy()
end
local lib = Instance.new("Folder")
lib.Name = "EggModels"

local report = {}
for name, def in data do
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Height", def.height)
	for _, b in def.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = b.n == "Shell"
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0.04 -- (a little gloss, like the reference's eggs)
		if b.k == "egg" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		elseif b.k == "ball" then
			p.Shape = Enum.PartType.Ball
		elseif b.k == "cyl" then
			p.Shape = Enum.PartType.Cylinder
		end
		if b.t == "neon" then
			p.Material = Enum.Material.Neon
			p.Reflectance = 0
		elseif b.t == "glass" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.45
		end
		p.CastShadow = p.Size.Magnitude > 1
		p.Parent = m
	end
	m.PrimaryPart = m:FindFirstChild("Shell") :: BasePart?
	m.WorldPivot = CFrame.new()
	if m.PrimaryPart then
		-- the pivot stays at the bottom middle even with a PrimaryPart
		m.PrimaryPart.PivotOffset = m.PrimaryPart.CFrame:Inverse()
	end
	m.Parent = lib
	table.insert(report, ("%s %d"):format(name, #def.parts))
end
lib.Parent = ReplicatedStorage
return "EggModels: " .. table.concat(report, ", ")
