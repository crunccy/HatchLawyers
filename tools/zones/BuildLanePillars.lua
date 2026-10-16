-- tools/zones/BuildLanePillars.lua - stands the LANE PILLAR (tools/zones/lane_pillar.json, from tools/blender/lane_pillar.py;
-- design pass 2026-10-16) against both walls of every zone, every SPACING studs, painted the zone's colour
-- (Config.Zones.List[i].Color on the "BandA" bands and the "Banner"); clear of the zone's arrival and its License gate,
-- and skipped wherever wall decoration already stands. Into Workspace.ZoneLandmarks.Pillars (outside Workspace.Zones:
-- a BuildLane re-run leaves them - re-run this after it). Re-runnable. JSON served at JSON_URL (python3 -m http.server).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JSON_URL = "http://localhost:8766/lane_pillar.json"
local SPACING = 45
local Config = require(ReplicatedStorage.Shared.Config:Clone())
local md = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true)).models[1]
local recording = ChangeHistoryService:TryBeginRecording("BuildLanePillars")
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())

local landmarks = workspace:FindFirstChild("ZoneLandmarks")
if not landmarks then
	landmarks = Instance.new("Folder")
	landmarks.Name = "ZoneLandmarks"
	landmarks.Parent = workspace
end
local old = landmarks:FindFirstChild("Pillars")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "Pillars"

local function bounds(inst: Instance): (Vector3, Vector3)
	local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			mn = mn:Min(d.Position - d.Size / 2)
			mx = mx:Max(d.Position + d.Size / 2)
		end
	end
	return mn, mx
end

local function build(place: CFrame, color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "LanePillar"
	for _, b in md.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		p.CFrame = place * CFrame.new(b.p[1], b.p[2], b.p[3])
		p.Color = if b.n == "BandA" or b.n == "Banner" or b.n == "BannerTail" then color else Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "neon" then
			p.Material = Enum.Material.Neon
			p.CanCollide = false
			p.CastShadow = false
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
		end
		p.Parent = m
	end
	m.WorldPivot = place
	for _ = 1, 3 do
		if ZFight.fix({ m }) == 0 then
			break
		end
	end
	return m
end

local n, skipped = 0, 0
for _, zd in Config.Zones.List do
	local zone = workspace.Zones:FindFirstChild(zd.Id)
	local walls = zone and zone:FindFirstChild("Walls")
	local floor = zone and zone:FindFirstChild("Floor")
	if walls and floor then
		local fmn, fmx = bounds(floor)
		local gate = zone:FindFirstChild("GateArch")
		local gmn, gmx = Vector3.zero, Vector3.zero
		if gate then
			gmn, gmx = bounds(gate) -- (an if-expression would keep only the first of the two values)
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { walls }
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Include
		overlap.FilterDescendantsInstances = { zone:FindFirstChild("WallDecor") or zone, zone:FindFirstChild("FloorClutter") or zone }
		local z = fmx.Z - 40 -- (the arrival end is the zone's +Z end)
		while z > fmn.Z + 20 do
			if not (gate and z > gmn.Z - 8 and z < gmx.Z + 8) then
				for _, side in { -1, 1 } do
					local hit = workspace:Raycast(Vector3.new(0, 5, z), Vector3.new(side * 90, 0, 0), params)
					if hit then
						local x = hit.Position.X - side * 1.4 -- back against the wall
						local place = CFrame.new(x, fmx.Y, z) * CFrame.Angles(0, side * math.pi / 2, 0) -- front (-Z) to the lane
						local blocked = #workspace:GetPartBoundsInBox(place * CFrame.new(0, 7.5, 0), Vector3.new(3.8, 14, 3.2), overlap) > 0
						if blocked then
							skipped += 1
						else
							build(place, zd.Color).Parent = folder
							n += 1
						end
					end
				end
			end
			z -= SPACING
		end
	end
end
folder.Parent = landmarks
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return ("LanePillars: %d placed, %d skipped (decor in the way)"):format(n, skipped)
