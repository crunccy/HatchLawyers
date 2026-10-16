-- tools/zones/BuildTravelPortal.lua - builds Workspace.Hub.TravelPortal from tools/zones/travel_portal.json (made in
-- Blender: tools/blender/travel_portal.py) and retires the six old teleport pads (Hub.ZoneTeleports ->
-- ServerStorage.Old_ZoneTeleports). Re-runnable (replaces the portal). 2026-10-13, crnuch's cloud session (user's
-- pick "A": one portal + a travel map, StarterPlayerScripts.Travel / ServerScriptService.TravelServer).
-- Run in Edit mode with the JSON reachable at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).
-- Where it goes: where the old pads were (their middle, on the ground), its front facing the plaza's centre. Set
-- PLACE_AT to a CFrame to put it somewhere else (the portal's front faces that CFrame's +Z).
-- Every block is a studded Part (MaterialVariant BrickStuds) except tags: "neon" = glowing Neon, no collision;
-- "field" = the ForceField portal face; "trigger" = the invisible walk-in box (Name "Trigger", Touched by the
-- client); shape "cyl" = Cylinder; "a" = Transparency. Names the client looks up: Gem1-6 (attribute Zone = the zone
-- Id, lane order), SwirlArms (a Model, spun), SwirlDisc / SwirlCore (particles), SignPlate (gets "TRAVEL"); v2
-- (2026-10-13 mr.robe, the sci-fi pad from his references): FloatRing1-3 (Models, turned + bobbed), Beam (breathes).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local JSON_URL = "http://localhost:8766/travel_portal.json"
-- nil = where the old pads were, facing the plaza. 2026-10-16 (crnuch: it stood in the middle of the path): right of
-- the lane entrance, across from the License Office, its front (+Z here) facing the path (-X)
local PLACE_AT: CFrame? = CFrame.lookAt(Vector3.new(52, 0.5, -56), Vector3.new(53, 0.5, -56))

local Config = require(ReplicatedStorage.Shared.Config:Clone()) -- (a fresh clone: the command bar caches modules)
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local hub = workspace:WaitForChild("Hub")

local recording = ChangeHistoryService:TryBeginRecording("BuildTravelPortal")

-- where: the old pads' middle, on the ground; facing the plaza's centre
local pads = hub:FindFirstChild("ZoneTeleports")
local spot: Vector3? = nil
if pads then
	local sum, n = Vector3.zero, 0
	for _, d in pads:GetDescendants() do
		if d:IsA("BasePart") then
			sum += d.Position
			n += 1
		end
	end
	if n > 0 then
		spot = sum / n
	end
end
local old = hub:FindFirstChild("TravelPortal")
if not PLACE_AT and not spot and old then
	spot = (old :: Model):GetPivot().Position
end
assert(PLACE_AT or spot, "no Hub.ZoneTeleports pads to replace: set PLACE_AT")
if old then
	old:Destroy()
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { pads or Instance.new("Folder") }
local placeAt: CFrame
if PLACE_AT then
	placeAt = PLACE_AT
else
	local p = spot :: Vector3
	local hit = workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
	local ground = if hit then hit.Position.Y else p.Y
	local plaza = hub:FindFirstChild("Plaza")
	local target = if plaza and plaza:IsA("Model") then plaza:GetPivot().Position elseif plaza and plaza:IsA("BasePart") then plaza.Position else Vector3.new(0, ground, 0)
	local here = Vector3.new(p.X, ground, p.Z)
	local look = Vector3.new(target.X, ground, target.Z)
	-- FRONT: the model's front is its +Z (Blender -Y), so turn lookAt (-Z at the target) round by 180 degrees
	placeAt = CFrame.lookAt(here, look) * CFrame.Angles(0, math.pi, 0)
end

local portal = Instance.new("Model")
portal.Name = "TravelPortal"
portal.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
local arms = Instance.new("Model")
arms.Name = "SwirlArms"
arms.Parent = portal

local zones = Config.Zones.List
local blocks = 0
for _, b in data.parts do
	local p = Instance.new("Part")
	p.Name = b.n
	p.Anchored = true
	p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
	local r = b.r
	p.CFrame = placeAt * CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
	p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if b.shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	if b.t == "neon" then
		p.Material = Enum.Material.Neon
		p.CanCollide = false
		p.CanTouch = false
	elseif b.t == "field" then
		p.Material = Enum.Material.ForceField -- the moving shimmer, see-through by itself
		p.CanCollide = false
		p.CanTouch = false
	elseif b.t == "trigger" then
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = true
		p.CastShadow = false
	else
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "BrickStuds"
	end
	if b.a and b.a > 0 and b.t ~= "trigger" then
		p.Transparency = b.a
	end
	p.CastShadow = p.CastShadow and b.t ~= "neon" and b.t ~= "field" and p.Size.Magnitude > 2
	local gem = string.match(b.n, "^Gem(%d)$")
	if gem and zones[tonumber(gem)] then
		p:SetAttribute("Zone", zones[tonumber(gem)].Id)
	end
	if string.match(b.n, "^FloatRing%d$") then
		-- (v2) each floating ring round the light column is its own model: the client turns + bobs it
		local ring = portal:FindFirstChild(b.n) :: Model?
		if not ring then
			ring = Instance.new("Model")
			;(ring :: Model).Name = b.n
			;(ring :: Model).Parent = portal
		end
		p.Parent = ring
	else
		p.Parent = if b.n == "SwirlArm" then arms else portal
	end
	blocks += 1
end
-- the arms spin round the swirl's centre (the client turns the Model about its pivot's Z): Z = the swirl disc's axis
-- (a Cylinder's axis is its X), so it works for v1's upright portal and v2's flat one
local disc = portal:FindFirstChild("SwirlDisc") :: BasePart?
if disc then
	arms.WorldPivot = CFrame.fromMatrix(disc.Position, disc.CFrame.UpVector, disc.CFrame.LookVector)
end
-- the floating rings turn about their own centres, upright
for _, ring in portal:GetChildren() do
	if ring:IsA("Model") and string.match(ring.Name, "^FloatRing%d$") then
		local box = ring:GetBoundingBox()
		ring.WorldPivot = CFrame.new(box.Position) * placeAt.Rotation
	end
end
-- "TRAVEL" on the sign plate (its front is the model's +Z = NormalId.Back)
local sign = portal:FindFirstChild("SignPlate") :: BasePart?
if sign then
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "TRAVEL"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 214, 60)
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = sign
end
portal.WorldPivot = placeAt
CollectionService:AddTag(portal, "TravelPortal")
portal.Parent = hub

-- the six old pads go to storage (kept, like everything we retire)
if pads then
	local store = ServerStorage:FindFirstChild("Old_ZoneTeleports")
	if store then
		store:Destroy()
	end
	pads.Name = "Old_ZoneTeleports"
	pads.Parent = ServerStorage
end
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return ("TravelPortal: %d blocks at %s; old pads %s"):format(blocks, tostring(placeAt.Position), if pads then "archived" else "not found")
