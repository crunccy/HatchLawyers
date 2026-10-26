-- tools/zones/ApplyOverhaulLooks.lua - after crnuch imports exports/overhaul/<group>.fbx with Studio's Import 3D (each lands
-- in Workspace as a Model named <group>), this puts it right from tools/zones/overhaul/<group>.json:
--   * SCALE: the importer picks its own size per file (2x .. 100x seen 2026-10-26) - the model is scaled back so 1 Blender
--     metre = 1 stud again (checked against the JSON's sizes). It also turns the file 180 degrees: Blender (x, y, z) lands
--     as Roblox (-x, z, y), so a Blender front (-Y) faces Roblox -Z, as the game wants.
--   * LOOKS: Color / Material / Transparency / Reflectance per mesh (Plastic = studded by MaterialService.BrickStuds through
--     the mesh's stud UVs), Anchored, "Foo.001" names back to "Foo".
--   * COLLISION (phone / tablet budget, crnuch 2026-10-26): scattered plants / shells (joined meshes spanning the island)
--     and glow / see-through pieces don't collide or take raycasts (eggs land through them, as on the Part islands); the
--     underside and tiny details (< 2 studs) don't collide; small props (< 12 studs) collide as a box; the rest (ground,
--     buildings, big landmarks) on its real shape (PreciseConvexDecomposition). Ground cover and tiny details cast no
--     shadow. RenderFidelity stays Automatic (Roblox lowers the detail with distance).
-- Run in Edit mode (Studio MCP execute_luau) while `python3 -m http.server 8772` serves tools/zones/overhaul/; set GROUPS.
-- Precise collision is slow: run it in a task.spawn and read the OverhaulLooks attribute, or the MCP call times out.
local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local GROUPS = { "PASTE", "GROUP", "NAMES" }
local URL = "http://localhost:8772/"
local SCATTER = { "Oak", "Blossom", "Hedge", "Pine", "Bush", "Palm", "Tuft", "Topiary", "Tree", "Canopy", "OceanShell", "OceanStar",
	"OceanDrift", "Coral", "Conch", "OceanFan", "OceanBrain", "Fern", "Flower", "Daisy", "Grass", "Lily", "Lotus", "Ivy", "Moss",
	"Seaweed", "Leaf", "Pebble" }
local SOFT_LOOKS = { "water", "foam", "glow", "beam", "glass", "portal_", "mist", "cloud", "neon" }
local GROUND_COVER = { "grass", "flower", "tuft", "daisy", "moss", "ivy", "petal", "clover" }

local function has(s: string, list: { string }): boolean
	for _, k in list do
		if string.find(s, k, 1, true) then
			return true
		end
	end
	return false
end

local function apply(group: string): string
	local root = workspace:FindFirstChild(group) :: Model?
	if not root then
		return group .. ": not in Workspace"
	end
	local info = HttpService:JSONDecode(HttpService:GetAsync(URL .. group .. ".json"))
	local lo, hi = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
	for _, e in info.models do
		for i = 1, 3 do
			lo[i] = math.min(lo[i], e.min[i] + e.origin[i])
			hi[i] = math.max(hi[i], e.max[i] + e.origin[i])
		end
	end
	local want = Vector3.new(hi[1] - lo[1], hi[3] - lo[3], hi[2] - lo[2]) -- (Blender x, z, y extents)
	local got = root:GetExtentsSize()
	local k = math.max(got.X, got.Y, got.Z) / math.max(want.X, want.Y, want.Z)
	if math.abs(k - 1) > 0.002 then
		root:ScaleTo(root:GetScale() / k)
	end
	got = root:GetExtentsSize()
	local byName: { [string]: BasePart } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			byName[d.Name] = d
		end
	end
	local set, missing, n = 0, {}, 0
	for key, model in info.models do
		local scatter = has(key, SCATTER)
		local under = string.find(key, "Underside", 1, true) ~= nil
		for _, m in model.meshes do
			local part = byName[m.fbx_name] or byName[m.name]
			if not part then
				table.insert(missing, m.fbx_name)
				continue
			end
			part.Name = m.name
			part.Color = Color3.fromRGB(m.color[1], m.color[2], m.color[3])
			part.Material = Enum.Material[m.material]
			part.MaterialVariant = ""
			part.Transparency = m.transparency
			part.Reflectance = m.reflectance
			part.Anchored = true
			local soft = m.material == "Neon" or m.transparency > 0 or has(string.lower(m.look), SOFT_LOOKS)
			local size = math.max(part.Size.X, part.Size.Y, part.Size.Z)
			part.CastShadow = not soft and size >= 2 and not has(string.lower(m.look), GROUND_COVER)
			if scatter or soft then
				part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
			elseif under or size < 2 then
				part.CanCollide, part.CanTouch = false, false
			else
				part.CanCollide = true
				local fidelity = if size < 12 then Enum.CollisionFidelity.Box else Enum.CollisionFidelity.PreciseConvexDecomposition
				pcall(function()
					(part :: MeshPart).CollisionFidelity = fidelity
				end)
			end
			set += 1
			n += 1
			if n % 25 == 0 then
				task.wait()
			end
		end
	end
	for _, d in root:GetDescendants() do -- (models: "IslDaisy.001" -> "IslDaisy")
		if d:IsA("Model") then
			d.Name = (string.gsub(d.Name, "%.%d+$", ""))
		end
	end
	for key, e in info.models do -- (a row file: the importer spreads the models further than it scales them - each to its own size)
		local m = if e.origin[1] ~= 0 then root:FindFirstChild((string.gsub(key, "%.%d+$", ""))) else nil
		if m and m:IsA("Model") then
			local w = Vector3.new(e.max[1] - e.min[1], e.max[3] - e.min[3], e.max[2] - e.min[2])
			local g = m:GetExtentsSize()
			local r = math.max(g.X, g.Y, g.Z) / math.max(w.X, w.Y, w.Z)
			if math.abs(r - 1) > 0.002 then
				m:ScaleTo(m:GetScale() / r)
			end
		end
	end
	return ("%s: scaled 1/%.3f -> (%.1f, %.1f, %.1f) want (%.1f, %.1f, %.1f); %d meshes set, %d not found %s"):format(group, k,
		got.X, got.Y, got.Z, want.X, want.Y, want.Z, set, #missing, table.concat(missing, ", ", 1, math.min(#missing, 8)))
end

local rec = ChangeHistoryService:TryBeginRecording("Overhaul imports: scale, looks, collision")
local report = {}
for _, g in GROUPS do
	local ok, msg = pcall(apply, g)
	table.insert(report, if ok then msg else g .. " FAILED: " .. tostring(msg))
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
print(table.concat(report, "\n"))
return table.concat(report, "\n")
