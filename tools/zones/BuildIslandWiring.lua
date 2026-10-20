-- tools/zones/BuildIslandWiring.lua - builds Workspace.IslandWiring: the gameplay markers that let the egg zones run on
-- the redesign islands (Workspace.WorldRedesign) when they're switched on (Server.ZoneMap; Config.Zones.Islands.Enabled,
-- or Studio's admin /islands on). 2026-10-20, mr.robe's session (user's call: wire them "behind an off switch").
-- One folder per zone Id (attributes Zone, Island, BoundsMin / BoundsMax) holding:
--   EggSpots    invisible 3x1x3 Parts on the island's 24 egg spots (where ZoneService grows its eggs)
--   Arrival     where Travel lands you (turned so you face north, up the island's route)
--   ReturnHome  an invisible upright trigger in the RETURN HOME portal's ring + ReturnPrompt (TravelServer sends you
--               to your firm WITH your eggs)
--   OddsBoard   + two posts beside the arrival: tag ZoneOddsBoard, attribute Zone (StarterPlayerScripts.Zones draws the
--               exact odds on its front, which faces the arrival pad)
-- Positions come from each island's layout JSON (environment-redesign/<island>/<x>_layout.json: places + egg_spots in
-- island-local Roblox x/z); heights from a raycast onto the island itself, so markers sit on the real ground.
-- Re-runnable: replaces the folders. Run after BuildRedesignIsland.lua (and again after an island is rebuilt), in Edit
-- mode, with the layout JSONs served flat (tools/studio_sync/serve_files.ps1). Nothing here touches the islands.

local ARGS = (... :: any) or {}
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local URL: string = ARGS.url or "http://localhost:8766/"
local MAP = { -- zone Id (Config.Zones.List) -> island model in Workspace.WorldRedesign, its layout JSON
	{ "BriefcaseBay", "BriefcaseBay", "bb_layout.json" },
	{ "PetPark", "PetPark", "pp_layout.json" },
	{ "BrainrotBoulevard", "BrainrotZone", "br_layout.json" },
	{ "FoodCourt", "FoodCourt", "fc_layout.json" },
	{ "OceanShore", "OceanShore", "os_layout.json" },
	{ "SpaceBase", "SpaceBase", "sb_layout.json" },
}
local INK = Color3.fromRGB(40, 40, 52)
local WOOD_DARK = Color3.fromRGB(122, 70, 34)

local world = workspace:FindFirstChild("WorldRedesign")
assert(world, "Workspace.WorldRedesign not found: build the islands first (tools/zones/BuildRedesignIsland.lua)")
local root = workspace:FindFirstChild("IslandWiring")
if not root then
	root = Instance.new("Folder")
	root.Name = "IslandWiring"
	root.Parent = workspace
end

local function marker(parent: Instance, name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local report = {}
for _, row in MAP do
	local zoneId, islandName, file = row[1], row[2], row[3]
	local island = world:FindFirstChild(islandName) :: Model?
	if not island then
		table.insert(report, zoneId .. ": no island " .. islandName)
		continue
	end
	local ok, layout = pcall(function()
		return HttpService:JSONDecode(HttpService:GetAsync(URL .. file, true))
	end)
	if not ok then
		table.insert(report, zoneId .. ": layout " .. file .. " not served")
		continue
	end
	local origin = (island :: Model):GetPivot()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island }
	params.RespectCanCollide = true
	local function ground(x: number, z: number): Vector3
		local p = origin:PointToWorldSpace(Vector3.new(x, 0, z))
		local hit = workspace:Raycast(p + Vector3.new(0, 80, 0), Vector3.new(0, -200, 0), params)
		return if hit then hit.Position else p
	end
	local function place(prefix: string): { number }?
		for _, pl in layout.places do
			if string.sub(pl.name, 1, #prefix) == prefix then
				return pl.roblox_xz
			end
		end
		return nil
	end

	local old = root:FindFirstChild(zoneId)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = zoneId
	folder:SetAttribute("Zone", zoneId)
	folder:SetAttribute("Island", islandName)
	local boxCf, boxSize = (island :: Model):GetBoundingBox()
	folder:SetAttribute("BoundsMin", boxCf.Position - boxSize / 2)
	folder:SetAttribute("BoundsMax", boxCf.Position + boxSize / 2)

	local spots = Instance.new("Folder")
	spots.Name = "EggSpots"
	spots.Parent = folder
	for i, s in layout.egg_spots do
		local g = ground(s.roblox_xz[1], s.roblox_xz[2])
		local spot = marker(spots, "Spot" .. i, Vector3.new(3, 1, 3), CFrame.new(g + Vector3.new(0, 0.5, 0)))
		spot:SetAttribute("Where", s.where)
	end

	local arr = place("Arrival") or { 0, 0 }
	local a = ground(arr[1], arr[2])
	-- (TravelServer turns the Arrival by +90 degrees about Y, the lane's convention: -90 here = facing north, -Z)
	marker(folder, "Arrival", Vector3.new(4, 1, 4), CFrame.new(a + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, -math.pi / 2, 0))

	local ret = place("RETURN HOME")
	if ret then
		-- the portal's field stands 3 studs north of its centre, its middle 18.8 above the island top (hl_world.return_portal:
		-- platform 4.6 + 14.2); a raycast would hit the ring's own bricks, so this is set from the island's origin
		local r = origin:PointToWorldSpace(Vector3.new(ret[1], 18.8, ret[2] - 3))
		local trigger = marker(folder, "ReturnHome", Vector3.new(20, 22, 2.5), CFrame.new(r))
		trigger.CanTouch = true
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ReturnPrompt"
		prompt.ActionText = "Return Home"
		prompt.ObjectText = "Back to your firm, eggs and all"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false -- (TravelServer turns it on while the islands are switched on)
		prompt.Parent = trigger
	end

	-- the odds board: 13 studs east + 12 north of the arrival pad, facing it
	local bpos = ground(arr[1] + 13, arr[2] - 12) + Vector3.new(0, 7.1, 0)
	local board = Instance.new("Part")
	board.Name = "OddsBoard"
	board.Size = Vector3.new(14, 9, 0.6)
	board.CFrame = CFrame.lookAt(bpos, Vector3.new(a.X, bpos.Y, a.Z))
	board.Anchored = true
	board.Color = INK
	board.Material = Enum.Material.SmoothPlastic
	board.CastShadow = true
	board:SetAttribute("Zone", zoneId)
	board.Parent = folder
	CollectionService:AddTag(board, "ZoneOddsBoard")
	for _, dx in { -5, 5 } do
		local post = Instance.new("Part")
		post.Name = "OddsPost"
		post.Size = Vector3.new(0.8, 2.7, 0.8)
		post.CFrame = board.CFrame * CFrame.new(dx, -4.5 - 1.3, 0)
		post.Anchored = true
		post.Color = WOOD_DARK
		post.Material = Enum.Material.Plastic
		post.MaterialVariant = "BrickStuds"
		post.Parent = folder
	end

	folder.Parent = root
	table.insert(report, ("%s -> %s: %d egg spots, arrival %s"):format(zoneId, islandName, #layout.egg_spots, tostring(a)))
end
return "IslandWiring:\n" .. table.concat(report, "\n")
