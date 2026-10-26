-- tools/zones/ApplyOverhaulLooks.lua - after crnuch imports an exports/overhaul/<group>.fbx with Studio's 3D importer,
-- this sets every MeshPart's Color / Material / Transparency / Reflectance from tools/zones/overhaul/<group>.json (the
-- .fbx carries the shapes and the stud UVs; the looks live in the JSON). Plastic = studded: MaterialService.BrickStuds
-- (the Plastic override) lays the GaG studs through the mesh's UVs. Anchors everything, renames "Foo.001" back to "Foo".
-- Run in Edit mode (Studio MCP execute_luau or the command bar) with LOOKS = the JSON text, ROOT = the imported model.
-- Prints what it set and any mesh it couldn't find. One undo step.
local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local LOOKS = [[PASTE tools/zones/overhaul/<group>.json HERE]]
local ROOT: Instance = workspace:WaitForChild("PASTE_IMPORTED_MODEL_NAME")

local info = HttpService:JSONDecode(LOOKS)
local rec = ChangeHistoryService:TryBeginRecording("Overhaul looks: " .. tostring(info.group))
local set, missing = 0, {}

local function find(scope: Instance, names: { string }): BasePart?
	for _, n in names do
		local hit = scope:FindFirstChild(n, true)
		if hit and hit:IsA("BasePart") then
			return hit
		end
	end
	return nil
end

for key, model in info.models do
	local scope = ROOT:FindFirstChild(key, true) or ROOT -- (the importer keeps each model's empty as a Model)
	for _, m in model.meshes do
		local alt = string.gsub(m.fbx_name, "%.", "_") -- (in case the importer swapped the dot)
		local part = find(scope, { m.fbx_name, alt, m.name })
		if not part then
			table.insert(missing, key .. "/" .. m.fbx_name)
			continue
		end
		part.Name = m.name
		part.Color = Color3.fromRGB(m.color[1], m.color[2], m.color[3])
		part.Material = Enum.Material[m.material]
		part.MaterialVariant = ""
		part.Transparency = m.transparency
		part.Reflectance = m.reflectance
		part.Anchored = true
		part.CastShadow = m.material ~= "Neon" and m.transparency < 0.5
		set += 1
	end
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
print(("[looks] %s: %d meshes set, %d not found %s"):format(info.group, set, #missing, table.concat(missing, ", ", 1, math.min(#missing, 12))))
