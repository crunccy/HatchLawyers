-- tools/zones/BuildBosses.lua - turns tools/zones/bosses.json (exported by tools/blender/bosses.py) into
-- ReplicatedStorage.Bosses: one Model per boss (Config.Bosses.List[n].Model). Inside it one Model per animated GROUP
-- (Torso, Head, ArmL, LegL, ..., attributes Joint = the joint's CFrame in boss space and Parent = the group it hangs
-- off, "" = the boss root); every block a studded Part (MaterialVariant BrickStuds), anchored, no collisions (the
-- bosses are drawn by each client - StarterPlayerScripts.Bosses - from Server.BossService's state). Boss origin =
-- between its feet on the ground, facing -Z. Re-runnable (replaces the folder).
-- Run in Edit mode with the JSON reachable at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSON_URL = "http://localhost:8766/bosses.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local old = ReplicatedStorage:FindFirstChild("Bosses")
if old then
	old:Destroy()
end
local lib = Instance.new("Folder")
lib.Name = "Bosses"

local report = {}
for name, def in data do
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Height", def.height)
	local groups = {}
	for g, info in def.groups do
		local gm = Instance.new("Model")
		gm.Name = g
		gm:SetAttribute("Joint", CFrame.new(info.joint[1], info.joint[2], info.joint[3]))
		gm:SetAttribute("Parent", info.parent)
		gm.Parent = m
		groups[g] = gm
	end
	for _, b in def.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "neon" then
			p.Material = Enum.Material.Neon -- (glowing bits: the Eclipse's corona, the shark's lantern fish)
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
		end
		p.CastShadow = p.Size.Magnitude > 1.2
		p.Parent = groups[b.g] or m
	end
	m.WorldPivot = CFrame.new()
	m.Parent = lib
	table.insert(report, ("%s %d parts"):format(name, #def.parts))
end
lib.Parent = ReplicatedStorage
return "Bosses: " .. table.concat(report, ", ")
