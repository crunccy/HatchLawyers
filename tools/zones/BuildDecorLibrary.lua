-- tools/zones/BuildDecorLibrary.lua - turns tools/zones/decor_library.json (exported by tools/blender/zone_decor.py)
-- into ServerStorage.ZoneDecorLibrary: one Model per decoration, every block a studded Part (MaterialVariant
-- BrickStuds, the characters' material), origin = the middle of its base on the ground (Model.WorldPivot).
-- tools/zones/BuildLane.lua clones these onto the wall tops and the lane floor. Re-runnable (replaces the library).
-- Run in Edit mode with the JSON reachable at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local JSON_URL = "http://localhost:8766/decor_library.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local old = ServerStorage:FindFirstChild("ZoneDecorLibrary")
if old then
	old:Destroy()
end
local lib = Instance.new("Folder")
lib.Name = "ZoneDecorLibrary"
lib.Parent = ServerStorage

local models, blocks = 0, 0
for name, def in data do
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Theme", def.theme)
	for _, b in def.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "glass" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.35
		elseif b.t == "neon" then
			p.Material = Enum.Material.Neon -- (zones 3-6: crystals, screens, alien bulbs, ...)
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
		end
		if b.t == "nocollide" or b.t == "glass" or b.t == "neon" then
			p.CanCollide = false
			p.CanTouch = false
		end
		p.CastShadow = p.Size.Magnitude > 2 -- tiny bits (flowers, labels) don't need shadows
		p.Parent = m
		blocks += 1
	end
	m.WorldPivot = CFrame.new() -- the base's middle, on the ground
	m.Parent = lib
	models += 1
end
-- z-fighting (bug report 6, 2026-10-16): nudge apart faces this build left level (ServerScriptService.Server.ZFight)
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())
for _, m in lib:GetChildren() do
	for _ = 1, 3 do
		if ZFight.fix({ m }) == 0 then
			break
		end
	end
end

return ("ZoneDecorLibrary: %d models, %d blocks"):format(models, blocks)
