-- tools/zones/BuildRedesignIsland.lua - builds one world-redesign island (environment-redesign/, made in Blender)
-- as studded Parts in Workspace.WorldRedesign.<Island>. 2026-10-19, mr.robe's session (user's call: "just build
-- them"). The parts come from tools/zones/redesign/<Island>.json, written by environment-redesign/kit/export_island.py
-- (every kit brick / cylinder / ring / prism / wedge / sign text of that island's build script, in Roblox space).
-- Re-runnable: replaces that island. Run in Edit mode with the JSON served (tools/studio_sync/serve_files.ps1 -Root
-- tools/zones/redesign -Port 8766), from the command bar, or wrapped as a function and called with
-- { island = "OceanShore", url = "http://localhost:8766/", at = CFrame }.
-- Where: a floating-island universe EAST of today's map (today's hub, lane and gameplay are untouched and nothing is
-- wired to these islands yet): the hub at (3600, 150, -1200), the egg islands on a ring 760 studs round it, north
-- (-Z) up as in Blender. Every block is Plastic + MaterialVariant BrickStuds except: glow looks = Neon (no collision),
-- water = Glass (wadeable, no collision), glass = Glass, portal fields = ForceField, beams = faint Neon. Small bits
-- (< 1 stud), canopies, clouds and text have no collision. Raised studs (StudTop) are not tagged yet.

local ARGS = (... :: any) or {}
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUB = Vector3.new(3600, 150, -1200)
local RING = 760
local function onRing(deg: number): Vector3
	local a = math.rad(deg)
	return HUB + Vector3.new(RING * math.cos(a), 0, -RING * math.sin(a))
end
local LAYOUT: { [string]: Vector3 } = {
	CentralHub = HUB,
	BriefcaseBay = onRing(60), -- zone 1, then clockwise round the hub
	PetPark = onRing(0),
	BrainrotZone = onRing(-60),
	FoodCourt = onRing(-120),
	OceanShore = onRing(180),
	-- SpaceBase = onRing(120) (not built in Blender yet)
}

local ISLAND: string = ARGS.island or "OceanShore"
local URL: string = ARGS.url or "http://localhost:8766/"
local at: CFrame = ARGS.at or CFrame.new(LAYOUT[ISLAND] or HUB)
local data = HttpService:JSONDecode(HttpService:GetAsync(URL .. ISLAND .. ".json", true))

local root = workspace:FindFirstChild("WorldRedesign")
if not root then
	root = Instance.new("Folder")
	root.Name = "WorldRedesign"
	root.Parent = workspace
end
local old = root:FindFirstChild(ISLAND)
if old then
	old:Destroy()
end
local island = Instance.new("Model")
island.Name = ISLAND
island.WorldPivot = at
island:SetAttribute("Source", "environment-redesign (Blender), tools/zones/redesign/" .. ISLAND .. ".json")
island.Parent = root
CollectionService:AddTag(island, "RedesignIsland")

local groups = {}
for i, name in data.groups do
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = island
	groups[i] = m
end
local looks = {}
for name, l in data.looks do
	looks[name] = { Color3.fromRGB(l[1], l[2], l[3]), l[4] }
end
local CANOPY = { leaf = true, leaf_light = true, leaf_deep = true, blossom = true, blossom_light = true }
local NO_COLLIDE_GROUPS = { Clouds_Islets = true, Signs = true }
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local UP = CFrame.Angles(0, 0, math.pi / 2)

local function style(p: BasePart, look: string, group: string)
	local l = looks[look] or { Color3.new(0.8, 0.8, 0.8), "plastic" }
	p.Color = l[1]
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	local kind = l[2]
	local solid = true
	if kind == "neon" then
		p.Material = Enum.Material.Neon
		solid = false
	elseif kind == "water" then
		p.Material = Enum.Material.Glass
		p.Transparency = 0.35
		solid = false
	elseif kind == "glass" then
		p.Material = Enum.Material.Glass
		p.Transparency = 0.45
	elseif kind == "field" then
		p.Material = Enum.Material.ForceField
		solid = false
	elseif kind == "beam" then
		p.Material = Enum.Material.Neon
		p.Transparency = 0.8
		solid = false
	else
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "BrickStuds"
	end
	local big = math.max(p.Size.X, p.Size.Y, p.Size.Z)
	if CANOPY[look] or NO_COLLIDE_GROUPS[group] or big < 1 then
		solid = false
	end
	p.CanCollide = solid
	if not solid then
		p.CanQuery = kind ~= "water" and big >= 1
	end
	p.CastShadow = kind ~= "neon" and kind ~= "water" and kind ~= "beam" and p.Size.Magnitude > 2
end

local count = 0
for i, r in data.parts do
	local k, g, look = r[1], groups[r[2] + 1], r[3]
	local pos = Vector3.new(r[4], r[5], r[6])
	local p: BasePart
	if k == "b" then
		p = Instance.new("Part")
		p.Size = Vector3.new(r[7], r[8], r[9])
		p.CFrame = at * CFrame.new(pos) * CFrame.Angles(0, math.rad(r[10]), 0)
	elseif k == "B" then
		p = Instance.new("Part")
		p.Size = Vector3.new(r[7], r[8], r[9])
		p.CFrame = at * CFrame.new(r[4], r[5], r[6], r[10], r[11], r[12], r[13], r[14], r[15], r[16], r[17], r[18])
	elseif k == "c" then
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(r[7], r[8], r[8])
		p.CFrame = at * CFrame.new(pos) * UP
	elseif k == "C" then
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(r[7], r[8], r[8])
		p.CFrame = at * CFrame.new(r[4], r[5], r[6], r[9], r[10], r[11], r[12], r[13], r[14], r[15], r[16], r[17])
	elseif k == "w" then
		p = Instance.new("WedgePart") -- (a WedgePart's tall side is its +Z)
		p.Size = Vector3.new(r[7], r[8], r[9])
		local h = Vector3.new(r[10], 0, r[11]).Unit
		p.CFrame = at * CFrame.fromMatrix(pos, Vector3.yAxis:Cross(h), Vector3.yAxis, h)
	elseif k == "s" then
		p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(r[7], r[7], r[7])
		p.CFrame = at * CFrame.new(pos)
	elseif k == "t" then
		local size, text = r[7], r[10]
		local lines = string.split(text, "\n")
		local longest = 0
		for _, line in lines do
			longest = math.max(longest, #line)
		end
		p = Instance.new("Part")
		p.Size = Vector3.new(longest * size * 0.62 + size * 0.4, #lines * size * 1.25, 0.05)
		p.CFrame = at * CFrame.lookAt(pos, pos + Vector3.new(r[8], 0, r[9]))
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.TextColor3 = (looks[look] or { Color3.new(1, 1, 1) })[1]
		label.FontFace = FREDOKA
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = p
		p.Transparency = 1
	end
	if p then
		p.Name = g.Name
		style(p, look, g.Name)
		if k == "t" then
			p.Transparency = 1
			p.CastShadow = false
		end
		p.Parent = g
		count += 1
	end
	if i % 800 == 0 then
		task.wait()
	end
end

-- z-fighting (bug report 6): nudge apart faces this build left level (Shared.ZFight; yields as it goes)
local fixed = 0
local ok, err = pcall(function()
	local ZFight = require(ReplicatedStorage.Shared.ZFight:Clone())
	for _ = 1, 2 do
		local n = ZFight.fix({ island })
		fixed += n
		if n == 0 then
			break
		end
	end
end)
return ("%s: %d parts at %s; z-fight fixes %d%s"):format(ISLAND, count, tostring(at.Position), fixed, ok and "" or (" (ZFight failed: " .. tostring(err) .. ")"))
