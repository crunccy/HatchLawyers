-- tools/zones/BuildFloorRooms.lua - builds ServerStorage.Templates.FloorRooms.<Id> from tools/zones/floor_rooms.json
-- (made in Blender: tools/blender/floor_rooms.py). 2026-10-13 - the upstairs rooms (Config.Floors). Re-runnable:
-- replaces the templates (firms pick the new ones up when their building is rebuilt / on the next server).
-- Run in Edit mode with the JSON served at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).
-- Each template's pivot is the room's floor centre, its front facing -Z (ServerScriptService.FloorRooms turns it).
-- Blocks are studded Parts (MaterialVariant BrickStuds) except tags: "neon" = Neon, no collision; "glass" = see-through
-- glass; "prompt" = invisible, gets the RoomPrompt (ActionText from the JSON); "marker" = invisible spot (VIPSeat).
-- A block with a "label" gets that text on its "fn" face (the Guestbook's label is named "Likes": FloorRooms updates it).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local JSON_URL = "http://localhost:8766/floor_rooms.json"
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local Config = require(ReplicatedStorage.Shared.Config:Clone())
local names = (Config.Floors and Config.Floors.Rooms) or {}

local recording = ChangeHistoryService:TryBeginRecording("BuildFloorRooms")
local templates = ServerStorage:WaitForChild("Templates")
local old = templates:FindFirstChild("FloorRooms")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "FloorRooms"

local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function faceFor(p: BasePart, fn: { number }): Enum.NormalId
	local want = Vector3.new(fn[1], fn[2], fn[3]).Unit
	local best, bestDot = Enum.NormalId.Front, -2
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(want)
		if d > bestDot then
			best, bestDot = id, d
		end
	end
	return best
end

local report = {}
for id, parts in data.rooms do
	local m = Instance.new("Model")
	m.Name = id
	for _, b in parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "neon" then
			p.Material = Enum.Material.Neon
			p.CanCollide = false
			p.CastShadow = false
		elseif b.t == "glass" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.55
			p.CastShadow = false
		elseif b.t == "prompt" or b.t == "marker" then
			p.Transparency = 1
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			if b.t == "prompt" then
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "RoomPrompt"
				prompt.ActionText = b.prompt or "Open"
				prompt.ObjectText = (names[id] and names[id].Name) or id
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = 9
				prompt.RequiresLineOfSight = false
				prompt.Parent = p
			end
		else
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
			p.CastShadow = p.Size.Magnitude > 2
		end
		p.Parent = m
		if b.label and b.fn then
			local gui = Instance.new("SurfaceGui")
			gui.Name = "Label"
			gui.Face = faceFor(p, b.fn)
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 50
			gui.LightInfluence = 0
			gui.Parent = p
			local l = Instance.new("TextLabel")
			l.Name = if b.n == "Guestbook" then "Likes" else "Text"
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(0.94, 0.86)
			l.Position = UDim2.fromScale(0.03, 0.07)
			l.Text = b.label
			l.TextScaled = true
			l.TextColor3 = Color3.fromRGB(255, 240, 200)
			l.FontFace = FREDOKA
			local s = Instance.new("UIStroke")
			s.Thickness = 3
			s.Color = Color3.new(0, 0, 0)
			s.Parent = l
			l.Parent = gui
		end
	end
	m.WorldPivot = CFrame.new()
	m.Parent = folder
	table.insert(report, ("%s %d"):format(id, #parts))
end
folder.Parent = templates
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
table.sort(report)
return "FloorRooms templates: " .. table.concat(report, ", ")
