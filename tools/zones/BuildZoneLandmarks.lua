-- tools/zones/BuildZoneLandmarks.lua - puts the zone threshold statues (tools/zones/zone_landmarks.json, from
-- tools/blender/zone_landmarks.py; art pass stage 5, 2026-10-16) on the License gates: a pair on top of the gate that
-- leads INTO each zone (the previous zone's Zones.<Id>.GateArch), at x = +-PAIR_X, facing back up the lane at the
-- players walking towards it. Built into Workspace.ZoneLandmarks (outside Workspace.Zones: a BuildLane re-run leaves
-- them alone - re-run this after it if the gates move). Re-runnable (replaces the folder).
-- Run in Edit mode with the JSON served at JSON_URL (Mac: python3 -m http.server 8766 --directory tools/zones).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JSON_URL = "http://localhost:8766/zone_landmarks.json"
local SCALE = 1.5 -- the Blender statues are ~11 studs; the gates are 90 wide
local PAIR_X = 24

local Config = require(ReplicatedStorage.Shared.Config:Clone())
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local byName = {}
for _, md in data.models do
	byName[md.name] = md
end
local recording = ChangeHistoryService:TryBeginRecording("BuildZoneLandmarks")
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())

local old = workspace:FindFirstChild("ZoneLandmarks")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "ZoneLandmarks"

local function build(md: any, place: CFrame): Model
	local m = Instance.new("Model")
	m.Name = md.name
	for _, b in md.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3]) * SCALE
		local r = b.r
		p.CFrame = place * CFrame.new(b.p[1] * SCALE, b.p[2] * SCALE, b.p[3] * SCALE, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
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

local report = {}
local zones = workspace:WaitForChild("Zones")
local list = Config.Zones.List
for i = 1, #list - 1 do
	local gate = zones:FindFirstChild(list[i].Id) and zones[list[i].Id]:FindFirstChild("GateArch")
	local md = byName[list[i + 1].Id]
	if gate and md then
		local box = gate:GetBoundingBox()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { gate }
		for _, side in { -1, 1 } do
			local x = box.X + side * PAIR_X
			local hit = workspace:Raycast(Vector3.new(x, box.Y + 80, box.Z), Vector3.new(0, -160, 0), params)
			if hit then
				-- front (model -Z) turned to face +Z: up the lane, towards the players coming down it
				local place = CFrame.new(x, hit.Position.Y, box.Z) * CFrame.Angles(0, math.pi, 0)
				local m = build(md, place)
				m.Name = md.name .. (if side < 0 then "L" else "R")
				m.Parent = folder
			end
		end
		table.insert(report, list[i + 1].Id .. " on " .. list[i].Id .. ".GateArch")
	end
end
folder.Parent = workspace
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return "ZoneLandmarks: " .. table.concat(report, "; ")
