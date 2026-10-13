-- tools/zones/BuildEggsV5.lua - uploads + builds the eggs v5 and the new incubator (2026-10-12, mr.robe's session;
-- docs/EGGS_V5.md). Installed in the place as ServerStorage.EggV5Upload: a ModuleScript whose source is
-- "return function(RUN_ARG) <this file> end", with tools/zones/PngDecode.lua as its child "PngDecode".
--
-- THE PLACE OWNER (crnuch) MUST RUN IT: the game only loads assets its owner uploaded (mr_blox174's uploads of these
-- meshes and textures don't load - same as the carry animation). In his Studio, Edit mode, with the beta feature
-- "CreateAssetAsync Luau API" on (File > Beta Features, then restart Studio), paste into the command bar:
--     require(game.ServerStorage.EggV5Upload)()
-- It uploads the 12 textures and 56 meshes (a few minutes; progress in the Output window), then builds everything
-- into ServerStorage.EggV5Built (nothing live changes until a session installs it - docs/EGGS_V5.md). Safe to run
-- again: what's uploaded is remembered on ServerStorage.EggV5Assets (per uploader).
--   RUN_ARG nil      everything, however long it takes (the command bar)
--   RUN_ARG number   stop uploading after that many seconds and say "run this again" (Studio MCP calls time out)
--   RUN_ARG "dry"    decode every mesh + texture from the data, upload nothing
--   RUN_ARG "local"  no uploads at all: unsaved EditableMesh parts in workspace._EggV5Lib (to try the animations)
-- Data: ServerStorage.EggV5Data - the files tools/blender/eggs_v5.py -> incubator.py -> egg_break.py export, stored IN
-- the place as chunked StringValues (JSON meshes + clips, base64 PNG textures "tex_<Egg>[_Golden].txt").
-- Builds (in ServerStorage.EggV5Built, or workspace._EggV5Lib for "local"):
--   EggModels       Shell, HatchShell, Chunks/*, Cracks/*, FxRing, <Egg>/* pieces (attrs Texture, GoldenTexture),
--                   BreakAnims (ModuleScript)                         -> goes to ReplicatedStorage.EggModels
--   IncubatorAnims  (ModuleScript: rest centres + the Open / Close / Cook / Overload clips) -> ReplicatedStorage
--   IncubatorV5     (Model)                                          -> ServerStorage.Templates (Server.FirmBuilder)
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local ARG: any = RUN_ARG
local LOCAL_TEST = ARG == "local"
local DRY = ARG == "dry"
local BUDGET = if type(ARG) == "number" then ARG else math.huge
local EGGS = { "Briefcase", "Pet", "Brainrot", "Food", "Ocean", "Space" }
local BASE = "http://localhost:8766/" -- (only without ServerStorage.EggV5Data: a local server on _egg_export/)

local function say(msg: string)
	print("[EggsV5] " .. msg)
end

local dataFolder = ServerStorage:FindFirstChild("EggV5Data")
local function getText(name: string): string
	if dataFolder then
		local f = dataFolder:FindFirstChild(name)
		if not f then
			error("ServerStorage.EggV5Data has no " .. name)
		end
		local parts = {}
		for i = 1, #f:GetChildren() do
			table.insert(parts, (f:FindFirstChild(tostring(i)) :: StringValue).Value)
		end
		return table.concat(parts)
	end
	return HttpService:GetAsync(BASE .. name, true)
end
local function getJson(name: string): any
	return HttpService:JSONDecode(getText(name))
end

local manifest = getJson("manifest.json")

-- uploaded ids are remembered per uploader (someone else's upload is no use: the game only loads its owner's)
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

local uploaded, reused, failed, pending, checked = 0, 0, {}, 0, 0
local started = os.clock()

-- the mesh asset for `name` (uploaded once); returns the asset id and its box (lo, hi)
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
	local em = buildEditable(getJson(info.file))
	if DRY then
		em:Destroy()
		checked += 1
		return nil, info
	end
	local ok, result, value = pcall(function()
		return AssetService:CreateAssetAsync(em, Enum.AssetType.Mesh, { Name = "HL_" .. name, Description = "Hatch a Lawyer & Get Rich! - " .. name })
	end)
	em:Destroy()
	if ok and result == Enum.CreateAssetResult.Success and typeof(value) == "number" then
		cache:SetAttribute(name, value)
		uploaded += 1
		say("uploaded mesh " .. name .. " (" .. uploaded .. ")")
		return value, info
	end
	table.insert(failed, name .. ": " .. tostring(if ok then value else result))
	return nil, info
end

-- a texture ("Brainrot" or "Brainrot_Golden"), decoded from the data and uploaded once -> "rbxassetid://..."
local decoder: any = nil
local function textureAsset(file: string): string?
	local key = "Tex_" .. file
	local id = cache:GetAttribute(key)
	if typeof(id) == "number" then
		reused += 1
		return "rbxassetid://" .. id
	end
	if LOCAL_TEST then
		return "" -- (an untextured shell; a texture the game can't load would hide it)
	end
	if os.clock() - started > BUDGET then
		pending += 1
		return nil
	end
	if not decoder then
		local m = (script and script:FindFirstChild("PngDecode")) or (dataFolder and dataFolder:FindFirstChild("PngDecode"))
		assert(m, "PngDecode module missing (ServerStorage.EggV5Upload.PngDecode)")
		decoder = require(m :: ModuleScript)
	end
	local w, h, px = decoder.fromBase64(getText("tex_" .. file .. ".txt"))
	if DRY then
		checked += 1
		return nil
	end
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), px)
	local ok, result, value = pcall(function()
		return AssetService:CreateAssetAsync(img, Enum.AssetType.Image, { Name = "HL_EggTex_" .. file, Description = "Hatch a Lawyer & Get Rich! - egg texture " .. file })
	end)
	img:Destroy()
	if ok and result == Enum.CreateAssetResult.Success and typeof(value) == "number" then
		cache:SetAttribute(key, value)
		uploaded += 1
		say("uploaded texture " .. file .. " (" .. uploaded .. ")")
		return "rbxassetid://" .. value
	end
	table.insert(failed, file .. ": " .. tostring(if ok then value else result))
	return nil
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
	for attempt = 1, if mp then 0 else 3 do
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
		table.insert(failed, name .. ": can't load the uploaded mesh")
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
			table.insert(parts, "{")
			if #v > 0 or next(v) == nil then
				for i, x in v do
					if i > 1 then
						table.insert(parts, ",")
					end
					emit(x)
				end
			else
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
			end
			table.insert(parts, "}")
		elseif t == "number" then
			table.insert(parts, if v == math.floor(v) then tostring(v) else string.format("%.4g", v))
		elseif t == "string" then
			table.insert(parts, string.format("%q", v))
		elseif t == "boolean" then
			table.insert(parts, tostring(v))
		end
	end
	emit(data)
	local ms = Instance.new("ModuleScript")
	ms.Name = name
	ms.Source = header .. "\nreturn " .. table.concat(parts) .. "\n"
	ms.Parent = parent
	return ms
end

------------------------------------------------------------------ 1) uploads (resumable)
if not LOCAL_TEST then
	say(if DRY then "dry run: decoding every texture + mesh" else "uploading textures + meshes (a few minutes)...")
	for _, egg in EGGS do
		textureAsset(egg)
		textureAsset(egg .. "_Golden")
	end
	for name in manifest.meshes do
		meshAsset(name)
	end
	if DRY then
		local msg = string.format("dry run OK: %d textures + meshes decode (%d already uploaded), %d failed", checked, reused, #failed)
		say(msg)
		return msg
	end
	if pending > 0 or #failed > 0 then
		local msg = string.format("uploaded %d (already %d); %d still to upload - run this again%s", uploaded, reused, pending, if #failed > 0 then " | failed: " .. table.concat(failed, "; ") else "")
		say(msg)
		return msg
	end
	say("all uploaded; building...")
	uploaded, reused = 0, 0
end
local TEXTURES = {}
for _, egg in EGGS do
	TEXTURES[egg] = { textureAsset(egg) or "", textureAsset(egg .. "_Golden") or "" }
end

------------------------------------------------------------------ 2) build
local rec = ChangeHistoryService:TryBeginRecording("Eggs v5 + incubator v5")
local outName = if LOCAL_TEST then "_EggV5Lib" else "EggV5Built"
local outParent = if LOCAL_TEST then workspace else ServerStorage
local oldOut = outParent:FindFirstChild(outName)
if oldOut then
	oldOut:Destroy()
end
local out = Instance.new("Folder")
out.Name = outName

local lib = Instance.new("Folder")
lib.Name = "EggModels"
lib:SetAttribute("EggV5", true)
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
local pieces, piecesMade = 0, 0
for egg, def in manifest.eggs do
	local folder = Instance.new("Folder")
	folder.Name = egg
	local tex = TEXTURES[egg] or { "", "" }
	folder:SetAttribute("Texture", tex[1])
	folder:SetAttribute("GoldenTexture", tex[2])
	for _, piece in def.pieces or {} do
		pieces += 1
		local p = meshPart(piece.mesh)
		if p then
			piecesMade += 1
			p.Name = piece.name
			if piece.mat == "tex" then
				p:SetAttribute("UsesTexture", true)
				p.TextureID = tex[1]
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
lib.Parent = out

local inc = manifest.incubator
local clips = getJson("incubator.json")
local model = Instance.new("Model")
model.Name = "IncubatorV5"
local SOLID = { Base = true, Arch = true, Tubes = true, Panel = true }
local incParts, incMade = 0, 0
for name, def in inc.parts do
	incParts += 1
	local p = meshPart(def.mesh)
	if p then
		incMade += 1
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
model.Parent = out
dataModule("IncubatorAnims", out, "-- generated by tools/zones/BuildEggsV5.lua from tools/blender/incubator.py (keyframed in Blender):\n-- parts[name] = rest centre (incubator space: the floor under its middle, front = -Z); clips[clip].parts[name] =\n-- 7 numbers per frame (centre x y z, quaternion x y z w), 30 fps.", clips)

local complete = shell ~= nil and hatchShell ~= nil and #chunks:GetChildren() == #manifest.chunks
	and #cracks:GetChildren() == #manifest.cracks and ring ~= nil and piecesMade == pieces and incMade == incParts and base ~= nil
out:SetAttribute("Complete", complete)
out:SetAttribute("Uploader", me)
out:SetAttribute("Built", os.date("!%Y-%m-%d %H:%M UTC"))
out.Parent = outParent
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
local msg = if complete
	then "DONE - everything uploaded and built in " .. out:GetFullName() .. ". Tell mr.robe (his Claude installs it)."
	else string.format("built with problems: %d failed (%s)", #failed, table.concat(failed, "; "))
say(msg)
return msg
