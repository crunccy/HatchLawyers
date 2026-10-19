-- tools/zones/BuildStudTiles.lua - uploads the raised-stud tile meshes (2026-10-18, docs/ART_STYLE_STUDS.md).
-- The stud comes from Blender (tools/blender/stud_tiles.py -> tools/zones/stud_tiles.json, stored in the place as the
-- StringValue ServerStorage.StudTileData). This repeats it over every tile grid (8x8 ... 1x1) at both detail levels
-- ("full" near the camera on PC, "low" on phones / low graphics), uploads each grid as a mesh and puts a ready
-- MeshPart per tile in ReplicatedStorage.Studs.Tiles (named "<lod>_<w>x<d>"; attrs W, D, Lift = the centre's height
-- above the face). StarterPlayerScripts.Studs clones them.
-- THE PLACE OWNER (crnuch) MUST RUN IT (the game only loads its owner's uploads). Edit mode, command bar:
--     require(game.ServerStorage.StudTileUpload)()        -- or paste this file's body
-- Safe to run again: uploaded ids are remembered on ServerStorage.StudTileAssets (per uploader); a new stud shape
-- needs that folder deleted first.
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local data = ServerStorage:FindFirstChild("StudTileData") :: StringValue
assert(data, "ServerStorage.StudTileData (tools/zones/stud_tiles.json) is missing")
local D = HttpService:JSONDecode(data.Value)
local LIFT = (D.height - D.sink) / 2 -- the tile mesh is centred: its centre sits this far above the face

local me = game:GetService("StudioService"):GetUserId()
local cache = ServerStorage:FindFirstChild("StudTileAssets")
if cache and cache:GetAttribute("Uploader") ~= me then
	cache:Destroy()
	cache = nil
end
if not cache then
	cache = Instance.new("Folder")
	cache.Name = "StudTileAssets"
	cache:SetAttribute("Uploader", me)
	cache.Parent = ServerStorage
end

local function tileMesh(lod: string, w: number, d: number): EditableMesh
	local s = D.lods[lod]
	local em = AssetService:CreateEditableMesh()
	local N = {}
	for i = 1, #s.n, 3 do
		N[#N + 1] = em:AddNormal(Vector3.new(s.n[i], s.n[i + 1], s.n[i + 2]))
	end
	local k = #s.v // 3
	for gx = 0, w - 1 do
		for gz = 0, d - 1 do
			local ox, oz = (gx - (w - 1) / 2) * D.pitch, (gz - (d - 1) / 2) * D.pitch
			local V = {}
			for i = 0, k - 1 do
				V[i] = em:AddVertex(Vector3.new(s.v[3 * i + 1] + ox, s.v[3 * i + 2] - LIFT, s.v[3 * i + 3] + oz))
			end
			for t = 1, #s.f, 6 do
				local fid = em:AddTriangle(V[s.f[t]], V[s.f[t + 2]], V[s.f[t + 4]])
				em:SetFaceNormals(fid, { N[s.f[t + 1] + 1], N[s.f[t + 3] + 1], N[s.f[t + 5] + 1] })
			end
		end
	end
	return em
end

return function()
	local studs = ReplicatedStorage:FindFirstChild("Studs") or Instance.new("Folder")
	studs.Name = "Studs"
	studs.Parent = ReplicatedStorage
	local built = Instance.new("Folder")
	built.Name = "Tiles_new"
	local failed = {}
	for _, lod in { "full", "low" } do
		for _, wd in D.tiles do
			local w, d = wd[1], wd[2]
			local name = ("%s_%dx%d"):format(lod, w, d)
			local id = cache:GetAttribute(name)
			if typeof(id) ~= "number" then
				local em = tileMesh(lod, w, d)
				local ok, result, value = pcall(function()
					return AssetService:CreateAssetAsync(em, Enum.AssetType.Mesh, {
						Name = "HL_Studs_" .. name,
						Description = "Hatch a Lawyer & Get Rich! - raised stud tile " .. name,
					})
				end)
				em:Destroy()
				if ok and result == Enum.CreateAssetResult.Success and typeof(value) == "number" then
					id = value
					cache:SetAttribute(name, id)
					print("[Studs] uploaded " .. name .. " = " .. id)
				else
					table.insert(failed, name .. ": " .. tostring(if ok then value or result else result))
					continue
				end
			end
			local mp
			for attempt = 1, 4 do
				local ok, res = pcall(function()
					return AssetService:CreateMeshPartAsync(Content.fromAssetId(id), {
						CollisionFidelity = Enum.CollisionFidelity.Box,
						RenderFidelity = Enum.RenderFidelity.Automatic,
					})
				end)
				if ok then
					mp = res
					break
				end
				task.wait(attempt) -- (a fresh upload can take a moment to load)
			end
			if not mp then
				table.insert(failed, name .. ": can't load mesh " .. id)
				continue
			end
			mp.Name = name
			mp.Anchored, mp.CanCollide, mp.CanQuery, mp.CanTouch, mp.CastShadow = true, false, false, false, false
			mp.Material = Enum.Material.Plastic
			mp:SetAttribute("W", w)
			mp:SetAttribute("D", d)
			mp:SetAttribute("Lift", LIFT)
			mp.Parent = built
		end
	end
	if #failed > 0 then
		built:Destroy()
		warn("[Studs] not done (run again): " .. table.concat(failed, "; "))
		return false
	end
	local old = studs:FindFirstChild("Tiles")
	if old then
		old:Destroy()
	end
	built.Name = "Tiles"
	built:SetAttribute("Uploader", me)
	built.Parent = studs
	print("[Studs] DONE: " .. #built:GetChildren() .. " tiles in ReplicatedStorage.Studs.Tiles")
	return true
end
