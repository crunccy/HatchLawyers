-- tools/zones/BuildHubLandmarks.lua - builds the hub landmarks from tools/zones/hub_landmarks.json (made in Blender:
-- tools/blender/hub_landmarks.py; art pass 2026-10-16, docs/ART_REMODEL_BRIEF.md): Workspace.Hub.BoardwalkGate (the
-- gateway from the plaza to the Big Case terrace + Arcade Pier; it replaces Hub.Gates.BigCaseGate, archived to
-- ServerStorage.Old_HubGates) and Workspace.Hub.EggFountain (the plaza's centre piece).
-- Re-runnable: a model built before goes to ServerStorage.Old_HubLandmarks first. Run in Edit mode with the JSON served
-- at JSON_URL (Mac: python3 -m http.server 8766 --directory tools/zones; Windows: tools/studio_sync/serve_files.ps1).
-- Every block is a studded Part (MaterialVariant BrickStuds); tags: "neon" = Neon, no collision; "water" = glassy
-- water, no collision. A block with "txt" gets a SurfaceGui with that text on the face whose normal matches "fn".

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local JSON_URL = "http://localhost:8766/hub_landmarks.json"
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local recording = ChangeHistoryService:TryBeginRecording("BuildHubLandmarks")
local hub = workspace:WaitForChild("Hub")

local function archive(inst: Instance, folderName: string)
	local store = ServerStorage:FindFirstChild(folderName)
	if not store then
		store = Instance.new("Folder")
		store.Name = folderName
		store.Parent = ServerStorage
	end
	local old = store:FindFirstChild(inst.Name)
	if old then
		old:Destroy()
	end
	inst.Parent = store
end

local LUCKIEST = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function faceFor(p: BasePart, want: Vector3): Enum.NormalId
	local best, bestDot = Enum.NormalId.Front, -2
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(want)
		if d > bestDot then
			best, bestDot = id, d
		end
	end
	return best
end

local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())
local report = {}
for _, md in data.models do
	local place = CFrame.new(md.place[1], md.place[2], md.place[3]) * CFrame.Angles(0, math.rad(md.place[4]), 0)
	local existing = hub:FindFirstChild(md.name)
	if existing then
		archive(existing, "Old_HubLandmarks")
	end
	local m = Instance.new("Model")
	m.Name = md.name
	for _, b in md.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = place * CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "neon" then
			p.Material = Enum.Material.Neon
			p.CanCollide = false
			p.CanTouch = false
			p.CastShadow = false
		elseif b.t == "water" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.25
			p.CanCollide = false
			p.CanTouch = false
			p.CastShadow = false
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
			p.CastShadow = p.Size.Magnitude > 2
		end
		if b.txt then
			local gui = Instance.new("SurfaceGui")
			gui.Name = "Sign"
			gui.Face = faceFor(p, place:VectorToWorldSpace(Vector3.new(b.fn[1], b.fn[2], b.fn[3]).Unit))
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 40
			gui.LightInfluence = 0
			local big = p.Size.Y > 4
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0.04, 0.1)
			l.Size = UDim2.fromScale(0.92, 0.8)
			l.Text = b.txt
			l.TextScaled = true
			l.TextColor3 = if big then Color3.fromRGB(255, 220, 90) else Color3.new(1, 1, 1)
			l.FontFace = if big then LUCKIEST else FREDOKA
			local st = Instance.new("UIStroke")
			st.Thickness = if big then 5 else 3
			st.Color = Color3.new(0, 0, 0)
			st.Parent = l
			l.Parent = gui
			gui.Parent = p
		end
		p.Parent = m
	end
	m.WorldPivot = place
	for _ = 1, 3 do -- z-fighting (bug report 6): nudge apart faces left level (Server.ZFight)
		if ZFight.fix({ m }) == 0 then
			break
		end
	end
	m.Parent = hub
	table.insert(report, ("%s %d blocks at %s"):format(md.name, #md.parts, tostring(place.Position)))
end

-- the Boardwalk gateway takes the old Big Case gate's place
local gates = hub:FindFirstChild("Gates")
local oldGate = gates and gates:FindFirstChild("BigCaseGate")
if oldGate and hub:FindFirstChild("BoardwalkGate") then
	archive(oldGate, "Old_HubGates")
	table.insert(report, "BigCaseGate archived to ServerStorage.Old_HubGates")
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return "HubLandmarks: " .. table.concat(report, "; ")
