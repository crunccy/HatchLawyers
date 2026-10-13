-- tools/zones/BuildEggsV5.lua - builds the eggs v5 + the new incubator in the open place (2026-10-12, mr.robe's
-- session; docs/EGGS_V5.md). Run in EDIT mode (Studio MCP execute_luau: put the source in a ModuleScript as
-- "return function() <source> end" and require + call it; or paste into the command bar). Needs Studio's beta feature
-- "CreateAssetAsync Luau API" (File > Beta Features): each Blender mesh is rebuilt as an EditableMesh and uploaded as
-- a Mesh asset. THE PLACE OWNER (crnuch) MUST RUN IT: the game only loads assets its owner uploaded (mr_blox174's
-- uploads of these meshes and textures don't load - same as the carry animation).
-- Data: ServerStorage.EggV5Data (the JSON exported by tools/blender/eggs_v5.py -> incubator.py -> egg_break.py, stored
-- in the place as chunked StringValues), else a local file server on :8766 serving _egg_export/. Textures: set
-- ServerStorage.EggV5Data attributes Texture_<Egg> / Golden_<Egg> to the owner's uploaded image ids first.
-- Uploads stop after ~90 s per run (ids are kept on ServerStorage.EggV5Assets, per uploader): run it until it stops
-- saying "run this again"; the last run builds:
--   ReplicatedStorage.EggModels      Shell, HatchShell, Chunks/*, Cracks/*, FxRing, <Egg>/* pieces (attrs Texture,
--                                    GoldenTexture), BreakAnims (ModuleScript). The old v4 library -> ServerStorage.Old_EggModels_v4
--   ReplicatedStorage.IncubatorAnims (ModuleScript: rest centres + the Open / Close / Cook / Overload clips)
--   ServerStorage.Templates.IncubatorV5 (Model; Server.FirmBuilder clones it into every firm)
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local BASE = "http://localhost:8766/"
-- LOCAL_TEST: no uploads - every mesh is an unsaved EditableMesh part, and everything goes into workspace._EggV5Lib (to
-- try the animations in Edit mode before the real upload; the parts don't survive a reload)
local LOCAL_TEST = false
local TEXTURES = { -- (tools/blender/eggs_v5.py paints them; uploaded 2026-10-12 with the Studio MCP's upload_image)
	Briefcase = { "rbxassetid://97351967797334", "rbxassetid://140143464414856" },
	Pet = { "rbxassetid://77571622617847", "rbxassetid://73935368120776" },
	Brainrot = { "rbxassetid://114929850759979", "rbxassetid://120498420443381" },
	Food = { "rbxassetid://81397707159207", "rbxassetid://134618248217931" },
	Ocean = { "rbxassetid://125149307131596", "rbxassetid://138887934157174" },
	Space = { "rbxassetid://92250233347467", "rbxassetid://76187503293624" },
}

-- The data: from ServerStorage.EggV5Data when it's there (the exported JSON files stored IN the place as chunked
-- StringValues, so the place owner can run this from his own Studio without the files - assets must be uploaded by
-- the place owner, crnuch, or the game can't load them), else from the local file server.
local dataFolder = ServerStorage:FindFirstChild("EggV5Data")
local function getJson(name: string): any
	if dataFolder then
		local f = dataFolder:FindFirstChild(name)
		if not f then
			error("ServerStorage.EggV5Data has no " .. name)
		end
		local parts = {}
		for i = 1, #f:GetChildren() do
			table.insert(parts, (f:FindFirstChild(tostring(i)) :: StringValue).Value)
		end
		return HttpService:JSONDecode(table.concat(parts))
	end
	return HttpService:JSONDecode(HttpService:GetAsync(BASE .. name, true))
end

local manifest = getJson("manifest.json")
if dataFolder and not LOCAL_TEST then -- the owner's texture ids must be set first (a texture the game can't load makes the shell invisible)
	for egg in TEXTURES do
		if typeof(dataFolder:GetAttribute("Texture_" .. egg)) ~= "string" or typeof(dataFolder:GetAttribute("Golden_" .. egg)) ~= "string" then
			return "set ServerStorage.EggV5Data attributes Texture_" .. egg .. " / Golden_" .. egg .. " (the place owner's uploaded image ids, 'rbxassetid://...') first"
		end
	end
end
if dataFolder then -- (texture ids uploaded by the place owner, set as attributes Texture_<Egg> / Golden_<Egg>)
	for egg, pair in TEXTURES do
		pair[1] = (dataFolder:GetAttribute("Texture_" .. egg) :: string?) or pair[1]
		pair[2] = (dataFolder:GetAttribute("Golden_" .. egg) :: string?) or pair[2]
	end
end

-- uploaded ids are remembered per uploader (a mesh someone else uploaded is no use: the game only loads its owner's)
local me = game:GetService("StudioService"):GetUserId()
local cache = ServerStorage:FindFirstChild("EggV5Assets")
if cache and cache:GetAttribute("Uploader") ~= me then
	cache:Destroy()
	cache = nil
end
if not cache then
	cache = Instance.new("Folder")
	cache.Name = "EggV5Assets"
	cache:SetAttribute("Uploader", me)
	cache.Parent = ServerStorage
end

local function buildEditable(d: any): EditableMesh
	local em = AssetService:CreateEditableMesh()
	local V, N, U = {}, {}, {}
	for i = 1, #d.v, 3 do
		V[#V + 1] = em:AddVertex(Vector3.new(d.v[i], d.v[i + 1], d.v[i + 2]))
	end
	for i = 1, #d.n, 3 do
		N[#N + 1] = em:AddNormal(Vector3.new(d.n[i], d.n[i + 1], d.n[i + 2]))
	end
	for i = 1, #d.uv, 2 do
		U[#U + 1] = em:AddUV(Vector2.new(d.uv[i], d.uv[i + 1]))
	end
	local f = d.f
	for i = 1, #f, 9 do
		local fid = em:AddTriangle(V[f[i] + 1], V[f[i + 3] + 1], V[f[i + 6] + 1])
		em:SetFaceNormals(fid, { N[f[i + 1] + 1], N[f[i + 4] + 1], N[f[i + 7] + 1] })
		em:SetFaceUVs(fid, { U[f[i + 2] + 1], U[f[i + 5] + 1], U[f[i + 8] + 1] })
	end
	return em
end

local uploaded, reused, failed, pending = 0, 0, {}, 0
local BUDGET, started = 90, os.clock() -- (uploads stop after ~90 s so a call never times out; run it again to go on)
-- the mesh asset for `name` (uploads it once); returns the asset id and the JSON's box (lo, hi)
local function meshAsset(name: string): (number?, any)
	local info = manifest.meshes[name]
	local id = cache:GetAttribute(name)
	if typeof(id) == "number" then
		reused += 1
		return id, info
	end
	if os.clock() - started > BUDGET then
		pending += 1
		return nil, info
	end
	local d = getJson(info.file)
	local em = buildEditable(d)
	local ok, result, value = pcall(function()
		return AssetService:CreateAssetAsync(em, Enum.AssetType.Mesh, { Name = "HL_" .. name, Description = "Hatch a Lawyer & Get Rich! - " .. name })
	end)
	em:Destroy()
	if ok and result == Enum.CreateAssetResult.Success and typeof(value) == "number" then
		cache:SetAttribute(name, value)
		uploaded += 1
		return value, info
	end
	table.insert(failed, name .. ": " .. tostring(if ok then value else result))
	return nil, info
end

local function meshPart(name: string, props: { [string]: any }?): MeshPart?
	local mp: MeshPart? = nil
	local id, info
	if LOCAL_TEST then
		info = manifest.meshes[name]
		mp = AssetService:CreateMeshPartAsync(Content.fromObject(buildEditable(getJson(info.file))))
		id = 0
	else
		id, info = meshAsset(name)
	end
	if not id then
		return nil
	end
	for attempt = 1, if mp then 0 else 2 do
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
		task.wait(attempt) -- (a fresh upload can take a moment to be loadable)
	end
	if not mp then
		table.insert(failed, name .. ": CreateMeshPartAsync failed")
		return nil
	end
	local m = mp :: MeshPart
	local lo, hi = info.lo, info.hi
	m.Name = name
	m.Anchored = true
	m.CanCollide = false
	m.CanTouch = false
	m.CanQuery = false
	m.CastShadow = true
	m.Material = Enum.Material.SmoothPlastic
	m.TopSurface = Enum.SurfaceType.Smooth
	m.BottomSurface = Enum.SurfaceType.Smooth
	m.CFrame = CFrame.new((lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2, (lo[3] + hi[3]) / 2)
	for k, v in props or {} do
		(m :: any)[k] = v
	end
	return m
end

local function rgb(c: { number }?): Color3
	return if c then Color3.fromRGB(c[1], c[2], c[3]) else Color3.new(1, 1, 1)
end

local function style(p: BasePart, mat: string?)
	if mat == "neon" then
		p.Material = Enum.Material.Neon
	elseif mat == "metal" then
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0.22
	elseif mat == "glass" then
		p.Material = Enum.Material.Glass
		p.Transparency = 0.6
		p.CastShadow = false
	end
end

-- a ModuleScript whose source returns `data` as a Luau table literal (numbers rounded as exported)
local function dataModule(name: string, parent: Instance, header: string, data: any): ModuleScript
	local parts = {}
	local function emit(v: any)
		local t = typeof(v)
		if t == "table" then
			if #v > 0 or next(v) == nil then
				table.insert(parts, "{")
				for i, x in v do
					if i > 1 then
						table.insert(parts, ",")
					end
					emit(x)
				end
				table.insert(parts, "}")
			else
				table.insert(parts, "{")
				local keys = {}
				for k in v do
					table.insert(keys, k)
				end
				table.sort(keys)
				for _, k in keys do
					table.insert(parts, string.format("[%q]=", k))
					emit(v[k])
					table.insert(parts, ",")
				end
				table.insert(parts, "}")
			end
		elseif t == "number" then
			table.insert(parts, if v == math.floor(v) then tostring(v) else string.format("%.4g", v))
		elseif t == "string" then
			table.insert(parts, string.format("%q", v))
		elseif t == "boolean" then
			table.insert(parts, tostring(v))
		end
	end
	emit(data)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local ms = Instance.new("ModuleScript")
	ms.Name = name
	ms.Source = header .. "\nreturn " .. table.concat(parts) .. "\n"
	ms.Parent = parent
	return ms
end

if not LOCAL_TEST then -- upload pass: every mesh first (resumable), building only once they're all up
	for name in manifest.meshes do
		meshAsset(name)
	end
	if pending > 0 or #failed > 0 then
		return string.format("uploaded %d (already %d); %d still to upload - run this again%s", uploaded, reused, pending, if #failed > 0 then " | failed: " .. table.concat(failed, "; ") else "")
	end
	uploaded, reused = 0, 0
end

local rec = ChangeHistoryService:TryBeginRecording("Eggs v5 + incubator v5")
local testOut: Folder? = nil
if LOCAL_TEST then
	local o = workspace:FindFirstChild("_EggV5Lib")
	if o then
		o:Destroy()
	end
	testOut = Instance.new("Folder")
	;(testOut :: Folder).Name = "_EggV5Lib"
	;(testOut :: Folder).Parent = workspace
end

------------------------------------------------------------------ EggModels v5
local lib = Instance.new("Folder")
lib.Name = "EggModels_v5"
local shell = meshPart("Shell")
if shell then
	shell.Parent = lib
end
local hatchShell = meshPart("HatchShell")
if hatchShell then
	hatchShell.Parent = lib
end
local chunks = Instance.new("Folder")
chunks.Name = "Chunks"
chunks.Parent = lib
for _, name in manifest.chunks do
	local p = meshPart(name)
	if p then
		p:SetAttribute("Top", manifest.meshes[name].top == true)
		p.Parent = chunks
	end
end
local cracks = Instance.new("Folder")
cracks.Name = "Cracks"
cracks.Parent = lib
for _, name in manifest.cracks do
	local p = meshPart(name, { Material = Enum.Material.Neon, Color = Color3.new(1, 1, 1), CastShadow = false })
	if p then
		p.Parent = cracks
	end
end
local ring = meshPart("FxRing", { Material = Enum.Material.Neon, CastShadow = false })
if ring then
	ring.Parent = lib
end
for egg, def in manifest.eggs do
	local folder = Instance.new("Folder")
	folder.Name = egg
	local tex = TEXTURES[egg]
	if tex then
		folder:SetAttribute("Texture", tex[1])
		folder:SetAttribute("GoldenTexture", tex[2])
	end
	for _, piece in def.pieces or {} do
		local p = meshPart(piece.mesh)
		if p then
			p.Name = piece.name
			if piece.mat == "tex" then
				p:SetAttribute("UsesTexture", true)
				p.TextureID = if tex then tex[1] else ""
			else
				p.Color = rgb(piece.rgb)
				style(p, piece.mat)
			end
			p.Parent = folder
		end
	end
	folder.Parent = lib
end
dataModule("BreakAnims", lib, "-- generated by tools/zones/BuildEggsV5.lua from tools/blender/egg_break.py (Blender rigid-body sim):\n-- takes[take][chunk] = 7 numbers per frame (centre x y z in egg space at height 3.8, quaternion x y z w), 30 fps.", getJson("egg_break.json"))

------------------------------------------------------------------ the incubator
local inc = manifest.incubator
local clips = getJson("incubator.json")
local model = Instance.new("Model")
model.Name = "IncubatorV5"
local SOLID = { Base = true, Arch = true, Tubes = true, Panel = true }
for name, def in inc.parts do
	local p = meshPart(def.mesh)
	if p then
		p.Name = name
		p.Color = rgb(def.rgb)
		style(p, def.mat)
		if SOLID[name] then
			p.CanCollide = true
			p.CanQuery = true
			p.CollisionFidelity = if name == "Base" then Enum.CollisionFidelity.Hull else Enum.CollisionFidelity.Box
		end
		local c = clips.parts[name]
		p:SetAttribute("Rest", CFrame.new(c[1], c[2], c[3]))
		p.Parent = model
	end
end
local base = model:FindFirstChild("Base") :: BasePart?
if base then
	model.PrimaryPart = base
	base.PivotOffset = base.CFrame:Inverse() -- pivot = the floor under the middle (the template stands on the origin)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "IncubatorPrompt"
	prompt.ActionText = "Hatch Egg"
	prompt.ObjectText = "Incubator"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
end
local pad = model:FindFirstChild("CradlePad") :: BasePart?
if pad then
	local a = Instance.new("Attachment")
	a.Name = "EggSpot"
	a.Position = pad.CFrame:PointToObjectSpace(Vector3.new(inc.eggSpot[1], inc.eggSpot[2], inc.eggSpot[3]))
	a.Parent = pad
end
model:SetAttribute("EggV5", true)
local incComplete = #model:GetChildren() >= 22 and base ~= nil
local templates = testOut or ServerStorage:FindFirstChild("Templates") or ServerStorage
if incComplete then
	local oldTemplate = templates:FindFirstChild("IncubatorV5")
	if oldTemplate then
		oldTemplate:Destroy()
	end
	model.Parent = templates
else
	model:Destroy() -- (Server.FirmBuilder keeps building the old incubator until the template is complete)
end
dataModule("IncubatorAnims", testOut or ReplicatedStorage, "-- generated by tools/zones/BuildEggsV5.lua from tools/blender/incubator.py (keyframed in Blender):\n-- parts[name] = rest centre (incubator space: the floor under its middle, front = -Z); clips[clip].parts[name] =\n-- 7 numbers per frame (centre x y z, quaternion x y z w), 30 fps.", clips)

------------------------------------------------------------------ swap the egg library in (only if every egg mesh made it)
local complete = shell ~= nil and hatchShell ~= nil and #chunks:GetChildren() == #manifest.chunks and #cracks:GetChildren() == #manifest.cracks
if testOut then
	lib.Name = "EggModels"
	lib.Parent = testOut
elseif complete then
	local old = ReplicatedStorage:FindFirstChild("EggModels")
	if old then
		local keep = old:GetAttribute("EggV5") and nil or ServerStorage:FindFirstChild("Old_EggModels_v4")
		if old:GetAttribute("EggV5") then
			old:Destroy()
		elseif not keep then
			old.Name = "Old_EggModels_v4"
			old.Parent = ServerStorage
		else
			old:Destroy()
		end
	end
	lib.Name = "EggModels"
	lib:SetAttribute("EggV5", true)
	lib.Parent = ReplicatedStorage
else
	lib.Parent = ServerStorage -- (kept aside as EggModels_v5 until every mesh uploads)
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
local ids = {}
for k, v in cache:GetAttributes() do
	table.insert(ids, k .. "=" .. tostring(v))
end
table.sort(ids)
return string.format("uploaded %d, reused %d, failed %d%s | library %s | incubator %s | ids: %s", uploaded, reused, #failed,
	if #failed > 0 then " (" .. table.concat(failed, "; ") .. ")" else "", if complete then "swapped in" else "kept aside", if incComplete then "template ready" else "not built", table.concat(ids, ","))
