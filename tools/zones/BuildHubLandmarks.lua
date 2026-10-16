-- tools/zones/BuildHubLandmarks.lua - builds the hub landmarks from tools/zones/hub_landmarks.json (made in Blender:
-- tools/blender/hub_landmarks.py; art pass 2026-10-16, docs/ART_REMODEL_BRIEF.md): Hub.ShopStall + Hub.MergeMachine
-- (stage 3: rebuilt on their old spots; "prompt" fields make the ShopPrompt / MergePrompt, "lbl" names a text label - the
-- Mutation Machine's "Mark" - and each model's old "Title" billboard is carried over onto the part its "title" names),
-- Workspace.Hub.BoardwalkGate (the
-- gateway from the plaza to the Big Case terrace + Arcade Pier; it replaces Hub.Gates.BigCaseGate, archived to
-- ServerStorage.Old_HubGates) and Workspace.Hub.EggFountain (the plaza's centre piece).
-- Re-runnable: a model built before goes to ServerStorage.Old_HubLandmarks first. Run in Edit mode with the JSON served
-- at JSON_URL (Mac: python3 -m http.server 8766 --directory tools/zones; Windows: tools/studio_sync/serve_files.ps1).
-- Every block is a studded Part (MaterialVariant BrickStuds); tags: "neon" = Neon, no collision; "water" = glassy
-- water, no collision. A block with "txt" gets a SurfaceGui with that text on the face whose normal matches "fn".

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

-- (other JSON in the same shape - e.g. tools/zones/island_edge.json - by setting _G.LANDMARKS_JSON first; its "parent"
-- names the Workspace folder it goes into, made if missing; default Workspace.Hub)
local JSON_URL = (_G :: any).LANDMARKS_JSON or "http://localhost:8766/hub_landmarks.json"
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local recording = ChangeHistoryService:TryBeginRecording("BuildHubLandmarks")
local hub = workspace:FindFirstChild(data.parent or "Hub")
if not hub then
	hub = Instance.new("Folder")
	hub.Name = data.parent
	hub.Parent = workspace
end

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
-- where a model goes: its one "place", its "copies" list, or "rim" = every Plaza Rim tile that isn't on a walkway
-- (walkways: the N / S / E / W spokes and the diagonals), turned to face the plaza's middle
local function placesFor(md: any): { CFrame }
	local list = {}
	if md.copies == "rim" then
		local plaza = hub:FindFirstChild("Plaza")
		for _, r in (if plaza then plaza:GetChildren() else {}) do
			if r:IsA("BasePart") and r.Name == "Rim" then
				local x, z = r.Position.X, r.Position.Z
				if math.abs(x) > 12 and math.abs(z) > 12 and math.abs(math.abs(x) - math.abs(z)) > 10 then
					local yaw = math.atan2(x, z) -- front (model -Z) toward the middle
					table.insert(list, CFrame.new(x, r.Position.Y + r.Size.Y / 2, z) * CFrame.Angles(0, yaw, 0))
				end
			end
		end
	elseif type(md.copies) == "table" then
		for _, c in md.copies do
			table.insert(list, CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0, math.rad(c[4]), 0))
		end
	elseif md.place then
		table.insert(list, CFrame.new(md.place[1], md.place[2], md.place[3]) * CFrame.Angles(0, math.rad(md.place[4]), 0))
	end
	return list
end

for _, md in data.models do
	local places = placesFor(md)
	local existing = hub:FindFirstChild(md.name)
	local oldTitle = existing and existing:FindFirstChild("Title", true)
	if oldTitle and not oldTitle:IsA("BillboardGui") then
		oldTitle = nil
	end
	if oldTitle then
		oldTitle = oldTitle:Clone()
	end
	if existing then
		archive(existing, "Old_HubLandmarks")
	end
	local holder: Model? = nil
	if md.copies then -- several copies: one Model holding them all
		holder = Instance.new("Model")
		holder.Name = md.name
	end
	for ci, place in places do
	local m = Instance.new("Model")
	m.Name = if holder then md.name .. ci else md.name
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
		elseif b.t == "prompt" then -- an invisible zone that only holds a ProximityPrompt
			p.Transparency = 1
			p.CanCollide = false
			p.CanQuery = false
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
			l.Name = b.lbl or "Text"
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
		if b.prompt then
			local pr = Instance.new("ProximityPrompt")
			pr.Name = b.prompt.name
			pr.ActionText = b.prompt.action
			pr.ObjectText = b.prompt.object
			pr.HoldDuration = 0
			pr.MaxActivationDistance = b.prompt.max or 10
			pr.RequiresLineOfSight = false
			pr.Parent = p
		end
		if b.light then
			local l = Instance.new("PointLight")
			l.Brightness = b.light[1]
			l.Range = b.light[2]
			l.Color = Color3.fromRGB(b.light[3][1], b.light[3][2], b.light[3][3])
			l.Shadows = false
			l.Parent = p
		end
		p.Parent = m
	end
	if md.title and oldTitle then
		local on = m:FindFirstChild(md.title[1])
		if on then
			oldTitle.Adornee = on
			oldTitle.StudsOffsetWorldSpace = Vector3.new(0, md.title[2], 0)
			oldTitle.Parent = on
		end
	end
	m.WorldPivot = place
	for _ = 1, 3 do -- z-fighting (bug report 6): nudge apart faces left level (Server.ZFight)
		if ZFight.fix({ m }) == 0 then
			break
		end
	end
	m.Parent = holder or hub
	end
	if holder then
		holder.Parent = hub
	end
	table.insert(report, ("%s %d blocks x%d"):format(md.name, #md.parts, #places))
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
