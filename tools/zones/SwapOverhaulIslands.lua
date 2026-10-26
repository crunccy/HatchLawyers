-- tools/zones/SwapOverhaulIslands.lua - puts imported overhaul islands (after ApplyOverhaulLooks.lua) into the world in
-- place of what's there now (crnuch 2026-10-26). Each import in Workspace (island_<x>[_phone]) is lined up on the island it
-- replaces by their Island_Top (same size), then turned 180 degrees about that centre (Studio's importer turns files 180:
-- every egg island's portal then lands on its IslandWiring ReturnHome, ~4 studs). The replaced island goes to
-- ServerStorage (nothing deleted). Top-level folders get the names Ambience reads (Island_Top, Island_Underside,
-- Vegetation). The hub: its copies of the pieces Server.HubMap moves onto it (portal, shop, boards, belt, minigames, booths,
-- fountain, lots) get the HubLookalike tag, so HubMap parks them at server start exactly as it parks the Part hub's.
-- Run in Edit mode (Studio MCP execute_luau). One undo step. Prints each island's portal-to-ReturnHome distance.
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerStorage = game:GetService("ServerStorage")

local SUFFIX = "_phone" -- (the imports' names: island_pet_phone ...)
local ARCHIVE = "Old_Overhaul_FullDetail" -- (where a replaced mesh island goes; a replaced Part island goes to Old_WorldRedesign_Parts)
local MAP = { island_bay = "BriefcaseBay", island_pet = "PetPark", island_rot = "BrainrotZone", island_food = "FoodCourt",
	island_ocean = "OceanShore", island_space = "SpaceBase", island_hub = "CentralHub" }
local WIRE = { BriefcaseBay = "BriefcaseBay", PetPark = "PetPark", BrainrotZone = "BrainrotBoulevard", FoodCourt = "FoodCourt",
	OceanShore = "OceanShore", SpaceBase = "SpaceBase" }
local PLANTS = { "Oak", "Blossom", "Hedge", "Pine", "Bush", "Palm", "Tuft", "Topiary", "Tree", "Canopy", "Fern", "Flower", "Daisy",
	"Grass", "Lily", "Lotus", "Ivy", "Seaweed" }
local HUB_LOOKALIKES = { "Arch", "Beam", "FloatRing1", "FloatRing2", "FloatRing3", "Gem1", "Gem2", "Gem3", "Gem4", "Gem5", "Gem6", "Halo",
	"HaloCore", "Pad", "Pylon", "Sign", "SignPlate", "Stage", "SwirlArm1", "SwirlArm2", "SwirlArm3", "SwirlArm4", "SwirlCore", "SwirlDisc",
	"ShopStall", "ShopStallBoot", "Leaderboard", "BigCaseBelt", "HubTerrace", "GavelBonk", "LuckyBriefcase", "LuckyBriefcaseBulb",
	"LuckyBriefcaseCase", "BoothBriefcaseStack", "BoothFilingFrenzy", "BoothLieDetector", "Fountain", "FountainStatue", "Hub_Lots" }

local function aabb(list: { BasePart }): (Vector3, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in list do
		local cf, h = p.CFrame, p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = cf:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
					lo, hi = lo:Min(w), hi:Max(w)
				end
			end
		end
	end
	return lo, hi
end

local function tops(root: Instance): { BasePart }
	local t = {}
	for _, d in root:GetDescendants() do -- (a mesh island: its Island_Top meshes)
		if d:IsA("BasePart") and string.sub(d.Name, 1, 10) == "Island_Top" then
			table.insert(t, d)
		end
	end
	local folder = root:FindFirstChild("Island_Top")
	if #t == 0 and folder then -- (a Part island: everything in its Island_Top model)
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(t, d)
			end
		end
	end
	return t
end

local function has(n: string, list: { string }): boolean
	for _, k in list do
		if string.find(n, k, 1, true) then
			return true
		end
	end
	return false
end

local rec = ChangeHistoryService:TryBeginRecording("Swap in the overhaul islands")
local archive = ServerStorage:FindFirstChild(ARCHIVE) or Instance.new("Folder")
archive.Name = ARCHIVE
archive.Parent = ServerStorage
local out = {}
for g, twinName in MAP do
	local mesh = workspace:FindFirstChild(g .. SUFFIX) :: Model?
	local twin = workspace.WorldRedesign:FindFirstChild(twinName) :: Model?
	if not (mesh and twin) then
		table.insert(out, g .. ": missing " .. (if mesh then twinName else g .. SUFFIX))
		continue
	end
	local mlo, mhi = aabb(tops(mesh))
	local tlo, thi = aabb(tops(twin))
	local c = (thi + tlo) / 2
	local moved = CFrame.new(c - (mhi + mlo) / 2) * mesh:GetPivot()
	mesh:PivotTo(CFrame.new(c) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-c) * moved)
	local sizeOff = ((mhi - mlo) - (thi - tlo)).Magnitude
	for _, m in mesh:GetChildren() do
		if m.Name == "Terrain" then
			m.Name = "Island_Top"
		elseif m.Name == "Underside" then
			m.Name = "Island_Underside"
		end
	end
	local veg = Instance.new("Model")
	veg.Name = "Vegetation"
	for _, m in mesh:GetChildren() do
		if m:IsA("Model") and has(m.Name, PLANTS) then
			m.Parent = veg
		end
	end
	veg.Parent = mesh
	local check = ""
	if WIRE[twinName] then
		local portal
		for _, m in mesh:GetChildren() do
			if m:IsA("Model") and string.find(m.Name, "Portal") and not has(m.Name, { "Moss", "Cap", "Bulb" }) then
				portal = m
				break
			end
		end
		local rh = workspace.IslandWiring[WIRE[twinName]].ReturnHome.Position
		local pc = portal and portal:GetBoundingBox().Position
		check = if pc then ("portal %.1f studs from ReturnHome"):format(Vector2.new(pc.X - rh.X, pc.Z - rh.Z).Magnitude) else "no portal found"
	else
		local tagged = 0
		for _, m in mesh:GetChildren() do
			if table.find(HUB_LOOKALIKES, m.Name) then
				CollectionService:AddTag(m, "HubLookalike")
				tagged += 1
			end
		end
		local old = twin:FindFirstChild("Travel Portal")
		local arch = mesh:FindFirstChild("Arch")
		local d = if old and arch then (old:GetBoundingBox().Position - arch:GetBoundingBox().Position) * Vector3.new(1, 0, 1) else nil
		check = ("%d look-alikes tagged; arch %s studs from the Part hub's portal"):format(tagged, if d then string.format("%.1f", d.Magnitude) else "?")
	end
	mesh:SetAttribute("Overhaul", "2026-10-26 phone / tablet meshes (" .. g .. SUFFIX .. ".fbx)")
	if twin:GetAttribute("Overhaul") then
		twin.Parent = archive
	else
		local parts = ServerStorage:FindFirstChild("Old_WorldRedesign_Parts") or Instance.new("Folder")
		parts.Name = "Old_WorldRedesign_Parts"
		parts.Parent = ServerStorage
		twin.Parent = parts
	end
	mesh.Name = twinName
	mesh.Parent = workspace.WorldRedesign
	table.insert(out, ("%s -> WorldRedesign.%s (top size off %.2f); %s"):format(g .. SUFFIX, twinName, sizeOff, check))
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
print(table.concat(out, "\n"))
return table.concat(out, "\n")
