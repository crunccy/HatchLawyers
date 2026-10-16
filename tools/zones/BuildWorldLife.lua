-- tools/zones/BuildWorldLife.lua - ReplicatedStorage.WorldLife (the props StarterPlayerScripts.WorldLife animates) from
-- tools/zones/world_life.json (tools/blender/world_life.py; design pass 2026-10-16). Re-runnable. JSON at JSON_URL.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSON_URL = "http://localhost:8766/world_life.json"
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local old = ReplicatedStorage:FindFirstChild("WorldLife")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "WorldLife"
for _, md in data.models do
	local m = Instance.new("Model")
	m.Name = md.name
	for _, b in md.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
	end
	m.WorldPivot = CFrame.new()
	m.Parent = folder
end
folder.Parent = ReplicatedStorage
return "WorldLife: " .. #data.models .. " models"
