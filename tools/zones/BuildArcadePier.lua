-- tools/zones/BuildArcadePier.lua - builds Workspace.ArcadePier from tools/zones/arcade_pier.json (made in Blender:
-- tools/blender/arcade_pier.py). 2026-10-13, mr.robe's session (user's call: the minigames in
-- docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md). Re-runnable: the old pier goes to ServerStorage.Old_ArcadePier.
-- Run in Edit mode with the JSON served at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/zones).
-- Where: the hub's land ends at z = 168 (north); the pier starts there and runs north (PLACE_AT turns the Blender
-- model, which runs along its local -Z, round to +Z). Deck top = y 0 = the hub's ground.
-- Every block is a studded Part (MaterialVariant BrickStuds) except tags: "neon" = Neon, no collision; "prompt" =
-- the invisible PlayZone that gets the PlayPrompt. Groups: "pier" -> Model Pier; "booth:<Id>" -> Booths.<Id> (tag
-- ArcadeStation, attribute ArcadeGame = Id). Text: Screen -> SurfaceGui "Board" (Title + Status, the status is written
-- by StarterPlayerScripts.Arcade), Marquee -> the game's name, ArchSign -> "ARCADE PIER". Each text face is the one
-- whose normal matches the JSON's "fn".

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local JSON_URL = "http://localhost:8766/arcade_pier.json"
local PLACE_AT = CFrame.new(0, 0, 167) * CFrame.Angles(0, math.pi, 0)

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local recording = ChangeHistoryService:TryBeginRecording("BuildArcadePier")

local old = workspace:FindFirstChild("ArcadePier")
if old then
	local store = ServerStorage:FindFirstChild("Old_ArcadePier")
	if store then
		store:Destroy()
	end
	old.Name = "Old_ArcadePier"
	old.Parent = ServerStorage
end

local pier = Instance.new("Model")
pier.Name = "ArcadePier"
local deck = Instance.new("Model")
deck.Name = "Pier"
deck.Parent = pier
local boothsFolder = Instance.new("Folder")
boothsFolder.Name = "Booths"
boothsFolder.Parent = pier
local names: { [string]: string } = {}
for _, b in data.booths do
	names[b.id] = b.name
end
local booths: { [string]: Model } = {}
local function groupModel(g: string): Instance
	local id = string.match(g, "^booth:(.+)$")
	if not id then
		return deck
	end
	local m = booths[id]
	if not m then
		m = Instance.new("Model")
		m.Name = id
		m:SetAttribute("ArcadeGame", id)
		m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		m.Parent = boothsFolder
		booths[id] = m
	end
	return m :: Model
end

local function faceFor(p: BasePart, fn: { number }): Enum.NormalId
	local want = PLACE_AT:VectorToWorldSpace(Vector3.new(fn[1], fn[2], fn[3]).Unit)
	local best, bestDot = Enum.NormalId.Front, -2
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(want)
		if d > bestDot then
			best, bestDot = id, d
		end
	end
	return best
end
local function surfaceText(p: BasePart, face: Enum.NormalId, name: string, ppsu: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = ppsu
	gui.LightInfluence = 0
	gui.Parent = p
	return gui
end
local function label(parent: Instance, text: string, pos: UDim2, size: UDim2, color: Color3, font: Font, strokePx: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.TextColor3 = color
	l.FontFace = font
	local s = Instance.new("UIStroke")
	s.Thickness = strokePx
	s.Color = Color3.new(0, 0, 0)
	s.Parent = l
	l.Parent = parent
	return l
end
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local LUCKIEST = Font.new("rbxasset://fonts/families/LuckiestGuy.json")

local count = 0
for _, b in data.parts do
	local p = Instance.new("Part")
	p.Name = b.n
	p.Anchored = true
	p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
	local r = b.r
	p.CFrame = PLACE_AT * CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
	p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local parent = groupModel(b.g or "pier")
	if b.t == "neon" then
		p.Material = Enum.Material.Neon
		p.CanCollide = false
		p.CanTouch = false
		p.CastShadow = false
	elseif b.t == "prompt" then
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		local id = parent:GetAttribute("ArcadeGame")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PlayPrompt"
		prompt.ActionText = "Play"
		prompt.ObjectText = names[id] or tostring(id)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("ArcadeGame", id)
		prompt.Parent = p
	else
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "BrickStuds"
		p.CastShadow = p.Size.Magnitude > 2
	end
	p.Parent = parent
	count += 1
	-- text faces
	if b.fn then
		local face = faceFor(p, b.fn)
		if b.n == "Screen" then
			local id = parent:GetAttribute("ArcadeGame")
			local gui = surfaceText(p, face, "Board", 50)
			label(gui, names[id] or "", UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.42), Color3.new(1, 1, 1), LUCKIEST, 4)
			local status = label(gui, "PLAY!", UDim2.fromScale(0.05, 0.55), UDim2.fromScale(0.9, 0.36), Color3.fromRGB(140, 240, 100), FREDOKA, 3)
			status.Name = "Status"
		elseif b.n == "Marquee" then
			local id = parent:GetAttribute("ArcadeGame")
			local gui = surfaceText(p, face, "Sign", 40)
			label(gui, string.upper(names[id] or ""), UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8), Color3.fromRGB(255, 220, 90), LUCKIEST, 4)
		elseif b.n == "ArchSign" then
			local gui = surfaceText(p, face, "Sign", 40)
			label(gui, "ARCADE PIER", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8), Color3.fromRGB(255, 220, 90), LUCKIEST, 5)
		end
	end
end
for id, m in booths do
	CollectionService:AddTag(m, "ArcadeStation")
	local _ = id
end
pier.WorldPivot = PLACE_AT
-- z-fighting (bug report 6, 2026-10-16): nudge apart faces this build left level (ServerScriptService.Server.ZFight)
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())
for _ = 1, 3 do
	if ZFight.fix({ pier, workspace:FindFirstChild("Ground") or pier }, { only = function(p)
		return p:IsDescendantOf(pier)
	end }) == 0 then
		break
	end
end
pier.Parent = workspace
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
local n = 0
for _ in booths do
	n += 1
end
return ("ArcadePier: %d blocks, %d booths at %s"):format(count, n, tostring(PLACE_AT.Position))
