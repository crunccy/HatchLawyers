-- InstallClients (2026-10-10): rebuilds + installs every v3 client into ServerStorage.Templates.Clients (old ones go
-- to ServerStorage.RetiredClients.<Id>_v2). Run in Studio's command bar (Edit mode) with the repo served locally:
--   cd ~/HatchLawyers && python3 -m http.server 8766 --bind 127.0.0.1
-- Sources: tools/clients/ClientKit.lua (refreshed into ServerStorage.ClientKit), Cast.lua (43 builders),
-- NeighborDave.lua (the benchmark), FaceIds.lua (face decals from tools/client_faces.py).
local Http = game:GetService("HttpService")
local BASE = "http://localhost:8766/tools/clients/"
local was = Http.HttpEnabled
Http.HttpEnabled = true
local ok, err = pcall(function()
	local kit = game.ServerStorage:FindFirstChild("ClientKit") or Instance.new("ModuleScript")
	kit.Name = "ClientKit"
	kit.Source = Http:GetAsync(BASE .. "ClientKit.lua")
	kit.Parent = game.ServerStorage
	local Kit = require(kit:Clone())
	local Cast = assert(loadstring(Http:GetAsync(BASE .. "Cast.lua")))()
	local Faces = assert(loadstring(Http:GetAsync(BASE .. "FaceIds.lua")))()
	local n = 0
	for id, build in Cast do
		local k = Kit.new(id)
		build(k)
		k:face(Faces[id])
		k:finish()
		k:install("v3 cast (tools/clients/Cast.lua)")
		n += 1
	end
	assert(loadstring(Http:GetAsync(BASE .. "NeighborDave.lua")))()
	_G.ClientBuild:install("benchmark")
	local stage = workspace:FindFirstChild("_ClientStage")
	if stage then
		stage:Destroy()
	end
	print(("InstallClients: %d clients installed"):format(n + 1))
end)
Http.HttpEnabled = was
if not ok then
	warn("InstallClients failed:", err)
end
