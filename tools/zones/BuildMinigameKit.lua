-- Build the Blender-authored hub minigame props from tools/zones/minigame_kit.json.
-- Run in Studio Edit mode while tools/studio_sync/serve_files.ps1 serves tools/zones on :8766.
-- The player-local scripts clone these static models, then animate only the live game pieces.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local URL = "http://localhost:8766/minigame_kit.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(URL, true))
local old = ReplicatedStorage:FindFirstChild("MinigameAssets")
if old then
	old:Destroy()
end
local library = Instance.new("Folder")
library.Name = "MinigameAssets"

local materials = {
	[0] = Enum.Material.Plastic, -- BrickStuds MaterialVariant
	[1] = Enum.Material.SmoothPlastic,
	[2] = Enum.Material.Metal,
	[3] = Enum.Material.Neon,
}
local count, modelCount = 0, 0
for modelName, parts in data.models do
	modelCount += 1
	local model = Instance.new("Model")
	model.Name = modelName
	for _, row in parts do
		local p = Instance.new("Part")
		p.Name = row.n
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Size = Vector3.new(row.s[1], row.s[2], row.s[3])
		local r = row.r
		p.CFrame = CFrame.new(row.p[1], row.p[2], row.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(row.c[1], row.c[2], row.c[3])
		p.Material = materials[row.m] or Enum.Material.Plastic
		if row.m == 0 then
			p.MaterialVariant = "BrickStuds"
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CastShadow = p.Size.Magnitude > 1
		p.Parent = model
		count += 1
	end
	if modelName == "LuckyBriefcase" then
		model.PrimaryPart = model:FindFirstChild("Body") :: BasePart
	end
	model.WorldPivot = CFrame.identity
	model.Parent = library
end
for modelName, animation in data.animations do
	local model = library:FindFirstChild(modelName)
	if model then
		for key, value in animation do
			model:SetAttribute(key, value)
		end
	end
end
library.Parent = ReplicatedStorage
return ("MinigameAssets: %d models, %d Blender-authored blocks"):format(modelCount, count)
