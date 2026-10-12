-- tools/zones/BuildBriefcases.lua - turns tools/zones/briefcases.json (exported by tools/blender/briefcases.py) into
-- ReplicatedStorage.Briefcases: one Model per Carry tier (Config.Zones.Carry[n].Model), every block a studded Part
-- (MaterialVariant BrickStuds) or Neon for the glowing bits. Origin (WorldPivot) = the middle of the bottom edge of the
-- side that touches the player's back; the case goes toward +Z (away from the back). Attribute Height = full height
-- incl. the handle. StarterPlayerScripts.CarryPose clones one onto each player's back; the License Office's Carry
-- counter shows one too. Re-runnable (replaces the folder). Run in Edit mode with the JSON reachable at JSON_URL
-- (tools/studio_sync/serve_files.ps1 -Root tools/zones).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSON_URL = "http://localhost:8766/briefcases.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local old = ReplicatedStorage:FindFirstChild("Briefcases")
if old then
	old:Destroy()
end
local lib = Instance.new("Folder")
lib.Name = "Briefcases"

local models, blocks = 0, 0
for name, def in data do
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Height", def.size[2])
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
			p.Material = Enum.Material.Neon
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
		end
		p.CastShadow = p.Size.Magnitude > 1
		p.Parent = m
		blocks += 1
	end
	m.WorldPivot = CFrame.new()
	m.Parent = lib
	models += 1
end
lib.Parent = ReplicatedStorage
return ("Briefcases: %d models, %d blocks"):format(models, blocks)
