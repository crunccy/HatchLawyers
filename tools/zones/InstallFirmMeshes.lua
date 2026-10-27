-- tools/zones/InstallFirmMeshes.lua - readies the staged overhaul firm meshes for Server.FirmStages / FirmBuilder
-- (2026-10-26, mr.robe's session). Run once in Studio's command bar / MCP execute_luau, Edit mode.
-- For each model in ServerStorage.Overhaul.Models.firms / .shack / .hall:
--   * WorldPivot = its firm-local origin (from the export's bounds in tools/zones/overhaul/<group>.json: Blender
--     (x, firm z, up)), turned so world +Z = firm +z. The meshes are a MIRROR of firm-local space (Blender's axes swap
--     y and z), so firm x lands at -X: FirmStages builds its Parts mirrored to match (Build.mx, the MirrorX attribute).
--   * attribute FirmOrigin = true (FirmStages.overhaulModel only uses marked models)
--   * collision (found by probing the walk-in route, elevator stops and rooms in a playtest): a joined mesh's convex
--     hulls can fill an opening, so doors / door frames / door bars, the shack's walls + junk (FirmStages adds invisible
--     walls), the HQ roof parapet (same) and plants stop colliding; closed doors go see-through.
-- Safe to run again (it measures the bounds each time, the pivot only moves the pivot).
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local M = game.ServerStorage.Overhaul.Models

-- { group, model, Blender min x, max x, firm z min, height min }
local BOUNDS = {
	{ "firms", "firms_stage2", -25.12, 25.12, -6.0, -1.5 },
	{ "firms", "firms_stage3", -25.12, 25.12, -6.59, -1.5 },
	{ "firms", "firms_stage4", -24.8, 24.8, -8.0, -1.5 },
	{ "firms", "firms_stage5", -25.0, 25.0, -6.0, -1.5 },
	{ "firms", "firms_stage6", -24.8, 24.8, -9.0, -1.5 },
	{ "shack", "DingyShack", -13.44, 13.44, -14.15, -1.75 },
	{ "hall", "hall_segment", -26.19, 26.39, -0.9, -1.95 },
	{ "hall", "hall_desk", -2.9, 4.2, -2.8, 0.0 },
	{ "hall", "hall_lock", -26.2, 26.3, -0.9, -1.98 },
	{ "hall", "hall_back_wall", -26.13, 26.37, -1.71, -1.97 },
}
local NO_COLLIDE = {
	Storefront_Gold = true, -- (the door's brass: a Box hull across the doorway)
	MainStreet_Iron = true,
	CorporateHQ_Parapet = true, -- its hull covered the roof garden: FirmStages adds invisible walls instead
	-- pilasters + the base course, which runs across the doorway 0.8 high (the Part fronts' base course didn't collide)
	Storefront_Trim = true,
	MainStreet_Trim = true,
	GlassOffice_Trim = true,
	CorporateHQ_Trim = true,
	SupremeTower_Trim = true,
}
-- the shack: only floors, porch and steps collide (its plank walls' hulls filled the door and the aisle);
-- FirmStages adds invisible walls (MESH_FRONTS[1])
local SHACK_COLLIDE = { Shack_Floor = true, Shack_FloorBoards = true, Shack_FloorLight = true, Shack_PorchBoards = true, Shack_PorchLight = true, Shack_Steps = true }
-- closed doors the clients walk through: see-through, like the Part fronts' doors
local SEE_THROUGH = { Storefront_Door = true, MainStreetDoor_Leaf = true, MainStreetDoor_Panel = true }

local _, rec = pcall(ChangeHistoryService.TryBeginRecording, ChangeHistoryService, "InstallFirmMeshes")
local report = {}
for _, b in BOUNDS do
	local m = M[b[1]]:FindFirstChild(b[2]) :: Model
	if not m then
		table.insert(report, b[2] .. " MISSING")
		continue
	end
	local cf, size = m:GetBoundingBox()
	local mn = cf.Position - size / 2
	local width = b[4] - b[3]
	m.WorldPivot = CFrame.new(mn.X + b[4], mn.Y - b[6], mn.Z - b[5])
	m:SetAttribute("FirmOrigin", true)
	local off = 0
	for _, p in m:GetDescendants() do
		if not p:IsA("BasePart") then
			continue
		end
		local shackWall = b[2] == "DingyShack" and not SHACK_COLLIDE[p.Name]
		local door = p.Name:find("Door") ~= nil -- doors, frames, door bars: the clients' way in
		if (NO_COLLIDE[p.Name] or shackWall or door or p.Name:find("Leaves") or p.Name:find("Flower")) and p.CanCollide then
			p.CanCollide = false
			off += 1
		end
		if SEE_THROUGH[p.Name] then
			p.Transparency = 0.5
		end
	end
	table.insert(report, string.format("%s: width %.2f vs %.2f, %d stopped colliding", b[2], size.X, width, off))
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
print(table.concat(report, "\n"))
return table.concat(report, "\n")
