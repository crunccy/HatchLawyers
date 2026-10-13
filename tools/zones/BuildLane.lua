-- tools/zones/BuildLane.lua — Edit-time builder for the egg-zone LANE (docs/ZONES_REFERENCE.md). Re-runnable: it
-- archives whatever is in Workspace.Zones (to ServerStorage.Old_Zones) and builds the lane fresh.
-- Run in Studio's Edit mode (Studio MCP execute_luau or the command bar), e.g. by loading this file over HTTP.
--
-- Layout: built along -X from X0 (centred on z = 0), then turned into place by PLACE (see X0): since 2026-10-12 it
-- starts at the plaza's south edge (0, 0, -80) and runs south, between the firms.
--   [hub] | SAFE ZONE (red line) | zone 1 | License gate | zone 2 | gate | ... | zone 6 | end wall
-- Each zone: a sunken floor (its own colour, hard edge) between tall terracotta brick walls; the ground on top of
-- the walls is the zone's colour and packed with its props; an orange path with white dashed edges and a white
-- chevron trail runs down the middle; small clutter on the floor; invisible EggSpots scattered for ZoneService.
-- All six zones are built (2026-10-12). To add one: an entry in ZONES (colours + a theme) + Config.Zones.List + a License.
-- Contracts Server.ZoneService / StarterPlayerScripts.Zones rely on (CLAUDE.md "Never rename"):
--   Workspace.Zones.<Id> (Folder, attribute Zone) > EggSpots (parts) + Arrival (part)
--   a part tagged LicenseGate (attributes RequiresLicense, Zone) with a LicensePrompt (attribute Upgrade = "License")
--   License Office counters: UpgradePrompt (attribute Upgrade) + anchors tagged UpgradeBoard
--   chevrons: models tagged ZoneChevron (the client flips them to point home while you carry eggs)

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Shared.Config:Clone()) -- a fresh clone dodges the command bar's module cache

-- same look as Formulas.formatCoins (which can't be required from a detached clone)
local function formatCoins(n: number): string
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while math.abs(n) >= 1000 and i < #suffixes do
		n /= 1000
		i += 1
	end
	return if i == 1 then tostring(math.floor(n)) else (string.format("%.2f", n):gsub("%.?0+$", "") .. suffixes[i])
end

------------------------------------------------------------------ the lane's measurements (studs)
local X0 = -264 -- where the lane begins, in the BUILD frame (everything below is built along -X from here) ...
-- ... and where it really sits: PLACE turns and moves the finished lane. 2026-10-12 (user's call): it starts at the
-- plaza's south edge, where the egg store was, and runs SOUTH between the two halves of the south row of firms.
-- PLACE maps the build frame's (X0, 0, 0) to LANE_START and its -X (down the lane) to -Z; the build frame's +Z
-- side ends up west.
local LANE_START = Vector3.new(0, 0, -80)
local PLACE = CFrame.new(LANE_START) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(-X0, 0, 0)
local HALF = 36 -- half the floor width: 72 wide, like the reference's roomy lane (40 felt narrow - mr.robe)
local WALL_H = 14 -- wall height (about 3 characters)
local TOP_W = 30 -- width of the decorated ground on top of each wall
local SAFE = 10 -- the Safe Zone strip at the start
local ZONE_LEN = 400 -- one zone, start to gate (~12 s at speed 32, ~25 s at 16)
local GATE = 12 -- the License gate arch between zones
local TOP_Y = WALL_H + 0.4

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local C = {
	terracotta = rgb(200, 100, 90), terracotta2 = rgb(188, 92, 84), path = rgb(255, 160, 24), white = rgb(248, 248, 248),
	red = rgb(230, 40, 40), ink = rgb(40, 40, 52), wood = rgb(214, 140, 70), woodDark = rgb(122, 70, 34),
	leaf = rgb(70, 168, 34), leaf2 = rgb(96, 196, 40), leaf3 = rgb(50, 140, 30), gold = rgb(255, 200, 40),
	bronze = rgb(205, 127, 50), cardboard = rgb(200, 160, 100), cardboard2 = rgb(170, 130, 80), steel = rgb(160, 165, 175),
	steelDark = rgb(110, 115, 125), paper = rgb(250, 248, 240), leather = rgb(150, 88, 44), navy = rgb(40, 60, 120),
	blueWater = rgb(120, 190, 255), pink = rgb(255, 120, 190), purple = rgb(150, 80, 230), tennis = rgb(206, 240, 60),
	bone = rgb(245, 240, 225), dirt = rgb(170, 120, 70), peach = rgb(255, 180, 110), sky = rgb(120, 200, 255),
	yellow = rgb(255, 214, 60), orange = rgb(255, 140, 40),
}

-- Each zone: floor colours (two shades - two very different ones make a checkerboard), the wall-top ground colour,
-- the walls' colours (default terracotta) and its theme for props + clutter. All six built 2026-10-12.
local ZONES = {
	{ Id = "BriefcaseBay", Name = "Briefcase Bay", License = 0, floor = { rgb(104, 152, 236), rgb(94, 142, 226) },
		edge = rgb(60, 100, 180), top = { rgb(96, 196, 40), rgb(88, 184, 36) }, theme = "office" },
	{ Id = "PetPark", Name = "Pet Park", License = 1, floor = { rgb(156, 214, 64), rgb(146, 204, 58) },
		edge = rgb(104, 160, 40), top = { rgb(124, 200, 52), rgb(116, 190, 48) }, theme = "pets" },
	{ Id = "BrainrotBoulevard", Name = "Brainrot Boulevard", License = 2, floor = { rgb(170, 80, 210), rgb(160, 72, 200) },
		edge = rgb(110, 50, 150), top = { rgb(190, 90, 220), rgb(178, 82, 208) }, walls = { rgb(120, 62, 170), rgb(108, 54, 156) },
		theme = "brainrot" },
	{ Id = "FoodCourt", Name = "Food Court", License = 3, floor = { rgb(240, 84, 74), rgb(250, 244, 232) }, -- a picnic cloth
		edge = rgb(190, 60, 50), top = { rgb(255, 214, 120), rgb(250, 204, 108) }, walls = { rgb(214, 140, 70), rgb(200, 128, 62) },
		theme = "food", tile = 12 },
	{ Id = "OceanShore", Name = "Ocean Shore", License = 4, floor = { rgb(240, 220, 160), rgb(232, 210, 150) },
		edge = rgb(90, 170, 230), top = { rgb(250, 232, 180), rgb(244, 224, 170) }, walls = { rgb(200, 190, 170), rgb(186, 176, 156) },
		theme = "ocean" },
	{ Id = "SpaceBase", Name = "Space Base", License = 5, floor = { rgb(64, 62, 86), rgb(56, 54, 78) },
		edge = rgb(90, 240, 255), top = { rgb(150, 150, 165), rgb(138, 138, 152) }, walls = { rgb(84, 86, 104), rgb(74, 76, 94) },
		theme = "space" },
}
-- the License badge on each gate's arch, by license level
local BADGE = { rgb(205, 127, 50), rgb(200, 205, 215), rgb(255, 200, 40), rgb(180, 235, 245), rgb(120, 220, 255) }

------------------------------------------------------------------ building blocks
local rng = Random.new(20261012)
local parts = 0
local function P(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, o: { [string]: any }?): BasePart
	o = o or {}
	local p = Instance.new(o.wedge and "WedgePart" or "Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = o.mat or Enum.Material.Plastic
	if not o.mat and not o.smooth then
		p.MaterialVariant = "BrickStuds" -- studs on every face, like the characters (docs/CHARACTER_STYLE.md)
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.shape then
		(p :: Part).Shape = o.shape
	end
	if o.nocollide then
		p.CanCollide = false
		p.CanTouch = false
	end
	if o.t then
		p.Transparency = o.t
	end
	if o.invisible then
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	end
	p.Parent = parent
	parts += 1
	return p
end
-- box from two corners
local function box(parent, name, x0, y0, z0, x1, y1, z1, color, o)
	return P(parent, name, Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
		CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, o)
end
local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function text(part: BasePart, face: Enum.NormalId, lines: { any }, pps: number?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps or 25
	sg.LightInfluence = 0
	sg.Parent = part
	local y = 0
	for _, l in lines do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.03, y)
		t.Size = UDim2.fromScale(0.94, l[3] or 0.5)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = l[1]
		t.TextColor3 = l[2] or C.white
		local s = Instance.new("UIStroke")
		s.Color = C.ink
		s.Thickness = l[4] or 5
		s.LineJoinMode = Enum.LineJoinMode.Round
		s.Parent = t
		t.Parent = sg
		y += l[3] or 0.5
	end
end
-- lane coordinate s (distance west of X0) -> world x
local function sx(s: number): number
	return X0 - s
end
-- a CFrame on a surface at height y, turned by deg around Y
local function at(x, y, z, deg)
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(deg or 0), 0)
end

------------------------------------------------------------------ props (everything stands on its base, nothing floats)
-- y = the surface it stands on; s = scale
local PROPS = {}
function PROPS.tree(m, x, y, z, s, leaf)
	local h = 5 * s
	P(m, "Trunk", Vector3.new(1.6 * s, h, 1.6 * s), at(x, y + h / 2, z), C.woodDark)
	local c = leaf or C.leaf
	P(m, "Leaves", Vector3.new(7 * s, 3 * s, 7 * s), at(x, y + h + 1.5 * s, z, rng:NextInteger(0, 45)), c)
	P(m, "Leaves2", Vector3.new(5 * s, 2.4 * s, 5 * s), at(x, y + h + 4.2 * s, z, rng:NextInteger(0, 45)), c:Lerp(Color3.new(1, 1, 1), 0.08))
	P(m, "Leaves3", Vector3.new(3 * s, 1.6 * s, 3 * s), at(x, y + h + 6.2 * s, z, rng:NextInteger(0, 45)), c:Lerp(Color3.new(1, 1, 1), 0.15))
end
function PROPS.hedge(m, x, y, z, s)
	local len = rng:NextNumber(6, 11)
	P(m, "Hedge", Vector3.new(len, 3 * s, 3 * s), at(x, y + 1.5 * s, z, rng:NextInteger(-10, 10)), C.leaf3)
	P(m, "HedgeTop", Vector3.new(len - 0.6, 0.6, 2.4 * s), at(x, y + 3 * s + 0.3, z, 0), C.leaf2)
end
function PROPS.fileBoxes(m, x, y, z, s)
	local n = rng:NextInteger(2, 4)
	local yy = y
	for i = 1, n do
		local h = 2.6 * s
		local cf = at(x + rng:NextNumber(-0.4, 0.4), yy + h / 2, z + rng:NextNumber(-0.4, 0.4), rng:NextInteger(-12, 12))
		P(m, "FileBox", Vector3.new(4.2 * s, h, 3.2 * s), cf, if i % 2 == 0 then C.cardboard else C.cardboard2)
		P(m, "Lid", Vector3.new(4.4 * s, 0.5, 3.4 * s), cf * CFrame.new(0, h / 2 - 0.25, 0), C.cardboard2:Lerp(C.ink, 0.15))
		yy += h
	end
end
function PROPS.waterCooler(m, x, y, z, s)
	P(m, "CoolerBase", Vector3.new(2.4 * s, 4 * s, 2.4 * s), at(x, y + 2 * s, z), C.white)
	P(m, "CoolerTap", Vector3.new(0.6, 0.6, 0.4), at(x, y + 3 * s, z) * CFrame.new(0, 0, -1.3 * s), C.red)
	P(m, "Jug", Vector3.new(2 * s, 2.6 * s, 2 * s), at(x, y + 5.3 * s, z), C.blueWater, { t = 0.25 })
end
function PROPS.briefcase(m, x, y, z, s)
	local cf = at(x, y, z, rng:NextInteger(0, 180))
	P(m, "Case", Vector3.new(7 * s, 5 * s, 2.4 * s), cf * CFrame.new(0, 2.5 * s, 0), C.leather)
	P(m, "Seam", Vector3.new(7.1 * s, 0.4, 2.5 * s), cf * CFrame.new(0, 3.6 * s, 0), C.woodDark)
	P(m, "Clasp", Vector3.new(0.8 * s, 0.8 * s, 0.3), cf * CFrame.new(-2 * s, 3.6 * s, -1.25 * s), C.gold)
	P(m, "Clasp", Vector3.new(0.8 * s, 0.8 * s, 0.3), cf * CFrame.new(2 * s, 3.6 * s, -1.25 * s), C.gold)
	P(m, "Handle", Vector3.new(3 * s, 0.5, 0.6), cf * CFrame.new(0, 6 * s, 0), C.ink)
	P(m, "HandleL", Vector3.new(0.5, 1, 0.6), cf * CFrame.new(-1.25 * s, 5.4 * s, 0), C.ink)
	P(m, "HandleR", Vector3.new(0.5, 1, 0.6), cf * CFrame.new(1.25 * s, 5.4 * s, 0), C.ink)
end
function PROPS.cabinet(m, x, y, z, s)
	local cf = at(x, y, z, rng:NextInteger(-20, 20))
	P(m, "Cabinet", Vector3.new(3.6 * s, 7.5 * s, 4 * s), cf * CFrame.new(0, 3.75 * s, 0), C.steel)
	for i = 0, 2 do
		P(m, "Drawer", Vector3.new(3 * s, 2 * s, 0.3), cf * CFrame.new(0, (1.4 + i * 2.4) * s, -2 * s), C.steelDark)
	end
end
function PROPS.books(m, x, y, z, s)
	local cols = { C.red, C.navy, C.leaf3, C.purple, C.woodDark }
	local yy = y
	for i = 1, rng:NextInteger(3, 5) do
		local h = 1.2 * s
		P(m, "Book", Vector3.new(5 * s, h, 3.6 * s), at(x, yy + h / 2, z, rng:NextInteger(-20, 20)), cols[(i - 1) % #cols + 1])
		yy += h
	end
end
function PROPS.lamp(m, x, y, z, s)
	P(m, "LampPost", Vector3.new(0.8, 9 * s, 0.8), at(x, y + 4.5 * s, z), C.ink)
	local g = P(m, "LampHead", Vector3.new(2, 1.4, 2), at(x, y + 9 * s + 0.7, z), C.yellow, { mat = Enum.Material.Neon, nocollide = true })
	local l = Instance.new("PointLight")
	l.Range = 14
	l.Brightness = 0.8
	l.Color = C.yellow
	l.Parent = g
end
function PROPS.doghouse(m, x, y, z, s)
	local cf = at(x, y, z, rng:NextInteger(0, 360))
	local walls = ({ C.sky, C.yellow, C.pink, C.white })[rng:NextInteger(1, 4)]
	P(m, "Walls", Vector3.new(6 * s, 4.6 * s, 6 * s), cf * CFrame.new(0, 2.3 * s, 0), walls)
	P(m, "Door", Vector3.new(2.4 * s, 3 * s, 0.3), cf * CFrame.new(0, 1.5 * s, -3 * s), C.ink, { smooth = true })
	P(m, "Roof", Vector3.new(7 * s, 1.2 * s, 7 * s), cf * CFrame.new(0, 5.2 * s, 0), C.red)
	P(m, "Roof2", Vector3.new(5 * s, 1.2 * s, 5 * s), cf * CFrame.new(0, 6.4 * s, 0), C.red)
	P(m, "Roof3", Vector3.new(3 * s, 1.2 * s, 3 * s), cf * CFrame.new(0, 7.6 * s, 0), C.red)
end
function PROPS.bigBone(m, x, y, z, s)
	local cf = at(x, y, z, rng:NextInteger(0, 180))
	P(m, "Shaft", Vector3.new(6 * s, 1.6 * s, 1.6 * s), cf * CFrame.new(0, 1.2 * s, 0), C.bone)
	for _, a in { -3.2, 3.2 } do
		for _, b in { -0.8, 0.8 } do
			P(m, "Knob", Vector3.new(2 * s, 2.2 * s, 2 * s), cf * CFrame.new(a * s, 1.1 * s, b * s), C.bone)
		end
	end
end
function PROPS.ballPile(m, x, y, z, s)
	local cols = { C.tennis, C.red, C.sky, C.pink, C.yellow }
	for i = 1, rng:NextInteger(4, 7) do
		local d = rng:NextNumber(1.6, 2.6) * s
		local ox, oz = rng:NextNumber(-2, 2) * s, rng:NextNumber(-2, 2) * s
		P(m, "Ball", Vector3.new(d, d, d), at(x + ox, y + d / 2 + (if i > 4 then d * 0.6 else 0), z + oz), cols[(i - 1) % #cols + 1], { shape = Enum.PartType.Ball })
	end
end
function PROPS.hydrant(m, x, y, z, s)
	P(m, "Body", Vector3.new(2 * s, 3.4 * s, 2 * s), at(x, y + 1.7 * s, z), C.red)
	P(m, "Cap", Vector3.new(2.6 * s, 0.6, 2.6 * s), at(x, y + 3.4 * s + 0.3, z), C.red:Lerp(C.ink, 0.2))
	P(m, "Top", Vector3.new(1.2 * s, 1 * s, 1.2 * s), at(x, y + 3.4 * s + 1.1, z), C.red)
	P(m, "Nozzle", Vector3.new(3.2 * s, 0.8, 0.8), at(x, y + 2.4 * s, z), C.gold)
end
function PROPS.foodBowl(m, x, y, z, s)
	local col = ({ C.sky, C.red, C.yellow })[rng:NextInteger(1, 3)]
	P(m, "Bowl", Vector3.new(4 * s, 1.2 * s, 4 * s), at(x, y + 0.6 * s, z), col)
	P(m, "Kibble", Vector3.new(3.2 * s, 0.3, 3.2 * s), at(x, y + 1.2 * s + 0.15, z), C.dirt)
end
function PROPS.weirdTree(m, x, y, z, s)
	PROPS.tree(m, x, y, z, s, ({ C.purple, C.pink, rgb(120, 220, 200) })[rng:NextInteger(1, 3)])
end

-- small floor clutter (no collision, so it never snags anyone)
local CLUTTER = {}
function CLUTTER.paper(m, x, y, z)
	P(m, "Paper", Vector3.new(1.8, 0.3, 2.4), at(x, y + 0.15, z, rng:NextInteger(0, 90)), C.paper, { nocollide = true })
end
function CLUTTER.box(m, x, y, z)
	P(m, "SmallBox", Vector3.new(1.6, 1.2, 1.6), at(x, y + 0.6, z, rng:NextInteger(0, 90)), C.cardboard, { nocollide = true })
end
function CLUTTER.cup(m, x, y, z)
	P(m, "Cup", Vector3.new(0.9, 1.1, 0.9), at(x, y + 0.55, z), C.white, { nocollide = true })
	P(m, "Coffee", Vector3.new(0.7, 0.1, 0.7), at(x, y + 1.12, z), C.woodDark, { nocollide = true })
end
function CLUTTER.pencil(m, x, y, z)
	P(m, "Pencil", Vector3.new(3, 0.4, 0.4), at(x, y + 0.2, z, rng:NextInteger(0, 180)), C.yellow, { nocollide = true })
end
function CLUTTER.smallBone(m, x, y, z)
	local cf = at(x, y, z, rng:NextInteger(0, 180))
	P(m, "Bone", Vector3.new(2, 0.5, 0.5), cf * CFrame.new(0, 0.25, 0), C.bone, { nocollide = true })
	P(m, "BoneEnd", Vector3.new(0.6, 0.6, 1), cf * CFrame.new(-1, 0.3, 0), C.bone, { nocollide = true })
	P(m, "BoneEnd", Vector3.new(0.6, 0.6, 1), cf * CFrame.new(1, 0.3, 0), C.bone, { nocollide = true })
end
function CLUTTER.tennisBall(m, x, y, z)
	P(m, "Ball", Vector3.new(1, 1, 1), at(x, y + 0.5, z), C.tennis, { shape = Enum.PartType.Ball, nocollide = true })
end
function CLUTTER.dirt(m, x, y, z)
	P(m, "Dirt", Vector3.new(rng:NextNumber(2, 4), 0.12, rng:NextNumber(2, 4)), at(x, y + 0.06, z, rng:NextInteger(0, 90)), C.dirt, { nocollide = true })
end
function CLUTTER.tuft(m, x, y, z)
	P(m, "Tuft", Vector3.new(0.8, 0.8, 0.8), at(x, y + 0.4, z, rng:NextInteger(0, 90)), C.leaf3, { nocollide = true })
end
-- (zones 3-6)
function CLUTTER.sprinkle(m, x, y, z)
	local col = ({ rgb(255, 90, 200), rgb(90, 240, 255), rgb(150, 255, 90), rgb(255, 214, 60) })[rng:NextInteger(1, 4)]
	P(m, "Sprinkle", Vector3.new(1.4, 0.3, 0.4), at(x, y + 0.15, z, rng:NextInteger(0, 180)), col, { mat = Enum.Material.Neon, nocollide = true })
end
function CLUTTER.crumb(m, x, y, z)
	P(m, "Crumb", Vector3.new(0.7, 0.5, 0.6), at(x, y + 0.25, z, rng:NextInteger(0, 90)), rgb(220, 160, 90), { nocollide = true })
end
function CLUTTER.ketchup(m, x, y, z)
	P(m, "Ketchup", Vector3.new(rng:NextNumber(1.6, 2.6), 0.1, rng:NextNumber(1.2, 2)), at(x, y + 0.05, z, rng:NextInteger(0, 90)), rgb(210, 40, 40), { nocollide = true, smooth = true })
end
function CLUTTER.fry(m, x, y, z)
	P(m, "Fry", Vector3.new(2, 0.4, 0.4), at(x, y + 0.2, z, rng:NextInteger(0, 180)), rgb(255, 210, 80), { nocollide = true })
end
function CLUTTER.shell(m, x, y, z)
	local col = ({ C.white, rgb(255, 200, 210), rgb(255, 230, 200) })[rng:NextInteger(1, 3)]
	P(m, "Shell", Vector3.new(0.9, 0.5, 0.7), at(x, y + 0.25, z, rng:NextInteger(0, 90)), col, { nocollide = true })
end
function CLUTTER.puddle(m, x, y, z)
	P(m, "Puddle", Vector3.new(rng:NextNumber(2.5, 4.5), 0.08, rng:NextNumber(2, 3.5)), at(x, y + 0.04, z, rng:NextInteger(0, 90)), C.blueWater, { nocollide = true, smooth = true, t = 0.2 })
end
function CLUTTER.pebble(m, x, y, z)
	P(m, "Pebble", Vector3.new(0.9, 0.6, 0.8), at(x, y + 0.3, z, rng:NextInteger(0, 90)), rgb(130, 130, 148), { nocollide = true })
end
function CLUTTER.glowPebble(m, x, y, z)
	P(m, "GlowPebble", Vector3.new(0.5, 0.5, 0.5), at(x, y + 0.25, z, rng:NextInteger(0, 90)), rgb(90, 240, 255), { mat = Enum.Material.Neon, nocollide = true })
end

-- "lib:<Name>" = a Blender-made model from ServerStorage.ZoneDecorLibrary (tools/blender/zone_decor.py ->
-- tools/zones/BuildDecorLibrary.lua); plain names = the procedural props above. Repeats = weight.
local THEMES = {
	office = { props = { "lib:TreeS", "lib:TreeM", "lib:TreeL", "lib:TreeXL", "lib:TreeBlossom", "lib:Bush", "lib:BushFlowers",
		"lib:BushFlowers", "lib:FlowerHedge", "lib:FlowerHedge", "lib:OfficePlant", "lib:OfficePlant", "lib:FileBoxes",
		"lib:FileBoxes", "lib:WaterCooler", "lib:ParkBench", "lib:FlowerBed", "lib:Rocks", "briefcase", "cabinet", "lamp" },
		clutter = { "paper", "paper", "box", "cup", "pencil", "lib:GrassTuft" } },
	pets = { props = { "lib:TreeS", "lib:TreeM", "lib:TreeL", "lib:TreeXL", "lib:TreeBlossom", "lib:Bush", "lib:BushFlowers",
		"lib:BushFlowers", "lib:FlowerBed", "lib:DogHouse", "lib:DogHouse", "lib:BonePile", "lib:BonePile", "lib:ToyPile",
		"lib:ToyPile", "lib:Hydrant", "lib:Rocks" },
		clutter = { "smallBone", "tennisBall", "dirt", "dirt", "lib:GrassTuft", "lib:GrassTuft" } },
	-- (zones 3-6; scale = how much bigger their props are drawn - giant food, giant crystals)
	brainrot = { props = { "lib:Lollipop", "lib:Lollipop", "lib:Mushroom", "lib:Mushroom", "lib:EyeStalk", "lib:JellyCubes",
		"lib:StaticTV", "lib:GiantGavel", "lib:TreeBlossom", "weirdTree" },
		clutter = { "sprinkle", "sprinkle", "sprinkle", "tuft" }, scale = 1.5 },
	food = { props = { "lib:Donut", "lib:Donut", "lib:Burger", "lib:IceCream", "lib:IceCream", "lib:Fries", "lib:PizzaSlice",
		"lib:Soda" },
		clutter = { "crumb", "crumb", "ketchup", "fry", "fry" }, scale = 1.7 },
	ocean = { props = { "lib:PalmTree", "lib:PalmTree", "lib:PalmTree", "lib:BeachUmbrella", "lib:SandCastle", "lib:Starfish",
		"lib:Coral", "lib:Coral", "lib:LifeRing", "lib:Rocks" },
		clutter = { "shell", "shell", "puddle", "shell" }, scale = 1.4 },
	space = { props = { "lib:Crystals", "lib:Crystals", "lib:SatelliteDish", "lib:Rocket", "lib:AlienPlant", "lib:AlienPlant",
		"lib:MoonRock", "lib:MoonRock", "lib:Beacon" },
		clutter = { "pebble", "pebble", "glowPebble" }, scale = 1.5 },
}

-- places a prop: a clone of a library model (scaled, turned) or a procedural one
local LIB = ServerStorage:FindFirstChild("ZoneDecorLibrary")
local function placeProp(parent: Instance, kind: string, x: number, y: number, z: number, s: number)
	local libName = string.match(kind, "^lib:(.+)$")
	if libName then
		local src = LIB and LIB:FindFirstChild(libName)
		if not src then
			return
		end
		local m = src:Clone()
		if math.abs(s - 1) > 0.01 then
			(m :: Model):ScaleTo(s)
		end
		(m :: Model):PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 359)), 0))
		m.Parent = parent
		parts += #m:GetChildren()
	else
		local m = model(parent, kind)
		PROPS[kind](m, x, y, z, s)
	end
end

------------------------------------------------------------------ archive the old zones, start fresh
local oldStore = ServerStorage:FindFirstChild("Old_Zones") or folder(ServerStorage, "Old_Zones")
local existing = workspace:FindFirstChild("Zones")
if existing then
	existing.Name = "Zones_" .. os.date("!%Y%m%d_%H%M%S")
	existing.Parent = oldStore
end
local zonesRoot = folder(workspace, "Zones")

-- scenery an earlier lane tucked away comes back first (clearArea below hides whatever is in THIS lane's way)
do
	local hiddenStore = ServerStorage:FindFirstChild("HiddenDecor")
	if hiddenStore then
		for _, m in hiddenStore:GetChildren() do
			local home = workspace:FindFirstChild((m:GetAttribute("DecorFolder") :: string?) or "")
			if m:GetAttribute("HiddenBy") == "ZoneLane" and home then
				m:SetAttribute("HiddenBy", nil)
				m.Parent = home
			end
		end
	end
end

-- island scenery in the way of the lane / office is tucked away (kept), like FirmBuilder.clearDecor does
local hidden = ServerStorage:FindFirstChild("HiddenDecor") or folder(ServerStorage, "HiddenDecor")
local function clearArea(cf: CFrame, size: Vector3)
	cf = PLACE * cf -- (given in the build frame, like everything else)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local folders = {}
	for _, n in { "IslandDecor", "Shrubbery" } do
		local f = workspace:FindFirstChild(n)
		if f then
			table.insert(folders, f)
		end
	end
	params.FilterDescendantsInstances = folders
	for _, hit in workspace:GetPartBoundsInBox(cf, size, params) do
		local mdl: Instance = hit
		while mdl.Parent and not table.find(folders, mdl.Parent :: any) do
			mdl = mdl.Parent :: Instance
		end
		if mdl.Parent and table.find(folders, mdl.Parent :: any) then
			mdl:SetAttribute("DecorFolder", mdl.Parent.Name)
			mdl:SetAttribute("HiddenBy", "ZoneLane")
			mdl.Parent = hidden
		end
	end
end

------------------------------------------------------------------ one stretch of lane: floor, walls, wall-top ground
local function laneStretch(parent: Instance, s0: number, s1: number, floor: { Color3 }, edge: Color3?, top: { Color3 }, walls: { Color3 }?, tile: number?)
	local f = model(parent, "Floor")
	-- tiles in a checkerboard of the two floor colours: 20 x half-the-width by default (two close shades), or `tile`
	-- square (Food Court's picnic cloth). (Before 2026-10-12 the index always picked the second colour.)
	local along = tile or 20
	local across = tile or HALF
	local row = 0
	for s = s0, s1 - 1, along do
		local len = math.min(along, s1 - s)
		row += 1
		local col = 0
		local zz = -HALF
		while zz < HALF - 0.01 do
			col += 1
			local z1 = math.min(zz + across, HALF)
			box(f, "Ground", sx(s), -1, zz, sx(s + len), 0, z1, floor[(row + col) % 2 + 1])
			zz = z1
		end
	end
	if edge then -- the hard border: a darker strip where this colour starts
		box(f, "Border", sx(s0), -1, -HALF, sx(s0 + 2), 0.05, HALF, edge)
	end
	local w = model(parent, "Walls")
	local k = 0
	for s = s0, s1 - 1, 40 do
		local len = math.min(40, s1 - s)
		k += 1
		for _, side in { -1, 1 } do
			-- terracotta wall (inner face, outer face to the sea) under a slab of the zone's ground
			local wc = walls or { C.terracotta, C.terracotta2 }
			box(w, "Wall", sx(s), -1, side * HALF, sx(s + len), WALL_H - 0.4, side * (HALF + TOP_W), if k % 2 == 0 then wc[1] else wc[2])
			box(w, "WallTop", sx(s), WALL_H - 0.4, side * HALF, sx(s + len), TOP_Y, side * (HALF + TOP_W), top[k % 2 + 1])
		end
	end
end

-- orange path with white dashed edges + white chevrons pointing down the lane (-X)
local function pathStretch(parent: Instance, s0: number, s1: number)
	local m = model(parent, "Path")
	box(m, "Path", sx(s0), 0, -4, sx(s1), 0.1, 4, C.path)
	for s = s0 + 2, s1 - 4, 7 do
		for _, side in { -1, 1 } do
			box(m, "Dash", sx(s), 0, side * 4.1, sx(s + 3.5), 0.14, side * 4.7, C.white, { nocollide = true })
		end
	end
	local chev = model(parent, "Chevrons")
	for s = s0 + 8, s1 - 8, 16 do
		local c = model(chev, "Chevron")
		local tip = Vector3.new(sx(s), 0.18, 0)
		for _, side in { -1, 1 } do
			-- two bars meeting at the tip, opening back toward the hub
			local mid = tip + Vector3.new(1.3, 0, side * 1.15)
			P(c, "Bar", Vector3.new(3.4, 0.16, 0.9), CFrame.lookAt(mid, tip) * CFrame.Angles(0, math.rad(90), 0), C.white, { smooth = true, nocollide = true })
		end
		c:SetAttribute("Home", CFrame.new(tip))
		CollectionService:AddTag(c, "ZoneChevron")
	end
end

local function decorate(parent: Instance, s0: number, s1: number, themeName: string)
	local theme = THEMES[themeName]
	local props = model(parent, "WallDecor")
	props.ModelStreamingMode = Enum.ModelStreamingMode.Default
	-- two bands per wall top: one along the lane's edge (what you see from the floor), one further back
	for s = s0 + 4, s1 - 4, 12 do
		for _, side in { -1, 1 } do
			for band, range in { { HALF + 4, HALF + 12, 0.9 }, { HALF + 15, HALF + TOP_W - 4, 0.5 } } do
				if rng:NextNumber() < range[3] then
					local kind = theme.props[rng:NextInteger(1, #theme.props)]
					local scale = (if string.find(kind, "Tree") then rng:NextNumber(0.9, 1.3) else rng:NextNumber(0.9, 1.25)) * (theme.scale or 1)
					placeProp(props, kind, sx(s) + rng:NextNumber(-2.5, 2.5) + (band - 1) * 4, TOP_Y, side * rng:NextNumber(range[1], range[2]), scale)
				end
			end
		end
	end
	-- props down in the lane too, along both walls (trees included, like the reference; never on the path)
	for s = s0 + 20, s1 - 20, 22 do
		for _, side in { -1, 1 } do
			if rng:NextNumber() < 0.6 then
				local kind = theme.props[rng:NextInteger(1, #theme.props)]
				if kind ~= "lamp" then
					placeProp(props, kind, sx(s) + rng:NextNumber(-4, 4), 0, side * rng:NextNumber(HALF - 9, HALF - 4), rng:NextNumber(0.8, 1.05) * (theme.scale or 1))
				end
			end
		end
	end
	return props
end

-- invisible egg spots across the floor (ZoneService spawns eggs on them), then clutter around them
local function spotsAndClutter(zoneFolder: Instance, s0: number, s1: number, themeName: string, count: number)
	local spots = folder(zoneFolder, "EggSpots")
	local placed = {}
	local tries = 0
	while #placed < count and tries < 2000 do
		tries += 1
		local p = Vector3.new(sx(rng:NextNumber(s0 + 10, s1 - 10)), 0, rng:NextNumber(-HALF + 3, HALF - 3))
		local ok = true
		for _, q in placed do
			if (q - p).Magnitude < 9 then
				ok = false
				break
			end
		end
		if ok then
			table.insert(placed, p)
			P(spots, "EggSpot" .. #placed, Vector3.new(2, 1, 2), CFrame.new(p + Vector3.new(0, 0.5, 0)), C.white, { invisible = true })
		end
	end
	local theme = THEMES[themeName]
	local clutter = model(zoneFolder, "FloorClutter")
	local n = 0
	tries = 0
	while n < math.floor((s1 - s0) / 9 * HALF / 20) and tries < 4000 do -- clutter scales with the floor's area
		tries += 1
		local p = Vector3.new(sx(rng:NextNumber(s0 + 4, s1 - 4)), 0, rng:NextNumber(-HALF + 1.5, HALF - 1.5))
		local ok = math.abs(p.Z) > 5.5 -- keep the path clear
		for _, q in placed do
			if (q - p).Magnitude < 4.5 then
				ok = false
			end
		end
		if ok then
			n += 1
			local kind = theme.clutter[rng:NextInteger(1, #theme.clutter)]
			if string.match(kind, "^lib:") then
				placeProp(clutter, kind, p.X, 0, p.Z, rng:NextNumber(0.8, 1.3))
			else
				CLUTTER[kind](clutter, p.X, 0, p.Z)
			end
		end
	end
end

------------------------------------------------------------------ gates
local function gateArch(parent: Instance, s: number, title: string, sub: string, badge: string, badgeColor: Color3)
	local g = model(parent, "GateArch")
	local x0, x1 = sx(s), sx(s + GATE)
	for _, side in { -1, 1 } do
		box(g, "Pillar", x0, TOP_Y, side * (HALF - 1), x1, TOP_Y + 12, side * (HALF + 6), C.terracotta2)
		box(g, "PillarCap", x0 + 0.5, TOP_Y + 12, side * (HALF - 1.5), x1 - 0.5, TOP_Y + 13, side * (HALF + 6.5), C.gold)
	end
	local beam = box(g, "Beam", x0, TOP_Y + 6, -(HALF + 6), x1, TOP_Y + 12, HALF + 6, C.terracotta)
	-- the sign on both faces of the beam, reading toward whoever walks up to it
	local plateE = box(g, "SignEast", x0 + 0.05, TOP_Y + 6.6, -16, x0 + 0.35, TOP_Y + 11.4, 16, C.ink, { smooth = true })
	text(plateE, Enum.NormalId.Right, { { title, C.yellow, 0.58, 6 }, { sub, C.white, 0.42, 4 } }, 20)
	local plateW = box(g, "SignWest", x1 - 0.35, TOP_Y + 6.6, -16, x1 - 0.05, TOP_Y + 11.4, 16, C.ink, { smooth = true })
	text(plateW, Enum.NormalId.Left, { { title, C.yellow, 0.58, 6 }, { sub, C.white, 0.42, 4 } }, 20)
	-- the license badge on top of the arch
	local disc = P(g, "Badge", Vector3.new(1.2, 9, 9), CFrame.new((x0 + x1) / 2, TOP_Y + 18, 0), badgeColor, { shape = Enum.PartType.Cylinder })
	local face = P(g, "BadgeFace", Vector3.new(0.2, 6.6, 6.6), CFrame.new((x0 + x1) / 2 + 0.7, TOP_Y + 18, 0), badgeColor:Lerp(Color3.new(1, 1, 1), 0.2), { shape = Enum.PartType.Cylinder, smooth = true })
	local tag = box(g, "BadgeText", (x0 + x1) / 2 + 0.75, TOP_Y + 16.4, -3, (x0 + x1) / 2 + 0.85, TOP_Y + 19.6, 3, C.ink, { smooth = true, t = 1, nocollide = true })
	tag.CanQuery = false
	text(tag, Enum.NormalId.Right, { { badge, C.white, 1, 5 } }, 25)
	local _ = disc
	local _2 = face
	-- the lane floor under the arch
	box(g, "GateFloor", x0, -1, -HALF, x1, 0, HALF, C.terracotta2)
	return g
end

------------------------------------------------------------------ build it
local s = 0
-- Safe Zone strip at the hub end: hub-grass floor, red line, big floor lettering
do
	local safe = model(zonesRoot, "SafeZone")
	laneStretch(safe, 0, SAFE, { rgb(96, 196, 40), rgb(96, 196, 40) }, nil, { rgb(96, 196, 40), rgb(96, 196, 40) })
	box(safe, "SafeLine", sx(SAFE - 1.2), 0, -HALF, sx(SAFE), 0.16, HALF, C.red, { mat = Enum.Material.Neon, nocollide = true })
	local letters = P(safe, "SafeZoneText", Vector3.new(30, 0.12, 7), CFrame.lookAt(Vector3.new(sx(4.5), 0.08, 0), Vector3.new(sx(4.5) - 1, 0.08, 0)), C.white, { t = 1, nocollide = true, smooth = true })
	letters.CanQuery = false
	-- (rotated so the text reads correctly for someone walking into the lane)
	text(letters, Enum.NormalId.Top, { { "SAFE ZONE", C.white, 1, 8 } }, 18)
	-- everything west of the hub's edge, across the lane's full width and length
	local total = SAFE + #ZONES * ZONE_LEN + (#ZONES - 1) * GATE + 10
	clearArea(CFrame.new(X0 - total / 2, 6, 0), Vector3.new(total, 40, 2 * (HALF + TOP_W) + 10))
end
s = SAFE

for i, z in ZONES do
	local zf = folder(zonesRoot, z.Id)
	zf:SetAttribute("Zone", z.Id)
	local s0, s1 = s, s + ZONE_LEN
	laneStretch(zf, s0, s1, z.floor, z.edge, z.top, z.walls, z.tile)
	pathStretch(zf, s0, s1)
	decorate(zf, s0, s1, z.theme)
	spotsAndClutter(zf, s0, s1, z.theme, 40)
	P(zf, "Arrival", Vector3.new(4, 1, 4), CFrame.new(sx(s0 + 14), 0.5, 0), C.white, { invisible = true })
	-- the zone's odds board (StarterPlayerScripts.Zones draws the exact odds on its front, which faces the path):
	-- at the side, just past the arrival spot. (2026-10-12: the egg machines and their boards left the hub.)
	local odds = P(zf, "OddsBoard", Vector3.new(14, 9, 0.6), CFrame.new(sx(s0 + 22), 6.5, HALF - 6), C.ink, { smooth = true })
	odds:SetAttribute("Zone", z.Id)
	CollectionService:AddTag(odds, "ZoneOddsBoard")
	for _, dx in { -5, 5 } do
		P(zf, "OddsPost", Vector3.new(0.8, 2.2, 0.8), CFrame.new(sx(s0 + 22) + dx, 1.1, HALF - 6), C.woodDark)
	end
	s = s1
	-- the gate into the NEXT zone
	local nextZone = ZONES[i + 1]
	local gateParent = zf
	if nextZone then
		local lic = Config.Zones.License[nextZone.License]
		local price = if lic then formatCoins(lic.Cost) else ""
		gateArch(gateParent, s, string.upper(nextZone.Name), (if lic then lic.Name else "License") .. "  ·  " .. price, string.upper((lic and lic.Name or "LICENSE"):gsub(" License", "")), BADGE[nextZone.License] or C.bronze)
		local barrier = box(gateParent, "LicenseGate", sx(s + GATE / 2 - 0.4), 0, -HALF, sx(s + GATE / 2 + 0.4), TOP_Y + 6, HALF, C.orange, { mat = Enum.Material.Neon, t = 0.45 })
		barrier:SetAttribute("RequiresLicense", nextZone.License)
		barrier:SetAttribute("Zone", nextZone.Id)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "LicensePrompt"
		prompt.ActionText = "Buy " .. (if lic then lic.Name else "License")
		prompt.ObjectText = "Opens " .. nextZone.Name
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Upgrade", "License")
		prompt.Parent = barrier
		CollectionService:AddTag(barrier, "LicenseGate")
		s += GATE
	end
end

-- the end of the lane, after the last zone (all six are built: no teaser any more)
do
	local t = model(zonesRoot, "LaneEnd")
	local last = ZONES[#ZONES]
	box(t, "EndWall", sx(s), -1, -(HALF + TOP_W), sx(s + 4), TOP_Y + 4, HALF + TOP_W, (last.walls and last.walls[1]) or C.terracotta)
end

------------------------------------------------------------------ the License Office, at the lane entrance (hub side)
do
	local office = model(zonesRoot, "LicenseOffice")
	office.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local ox = -246 -- (build frame) 18 studs back from the lane's start, toward the hub ...
	local z0 = 42 -- ... and off to the side (after PLACE: on the plaza, west of the entrance, facing the lane's axis)
	clearArea(CFrame.new(ox, 6, z0 + 9), Vector3.new(26, 20, 22))
	box(office, "Floor", ox - 10, 0, z0, ox + 10, 0.5, z0 + 16, C.white)
	box(office, "BackWall", ox - 10, 0.5, z0 + 14, ox + 10, 10, z0 + 16, C.terracotta)
	box(office, "SideWallW", ox - 10, 0.5, z0 + 3, ox - 8, 10, z0 + 14, C.terracotta2)
	box(office, "SideWallE", ox + 8, 0.5, z0 + 3, ox + 10, 10, z0 + 14, C.terracotta2)
	box(office, "Roof", ox - 11, 10, z0 + 1.5, ox + 11, 11, z0 + 17, C.navy)
	local sign = box(office, "Sign", ox - 7, 11, z0 + 1.6, ox + 7, 14.4, z0 + 2.2, C.ink, { smooth = true })
	text(sign, Enum.NormalId.Front, { { "LICENSE OFFICE", C.yellow, 1, 6 } }, 25)
	for i = 0, 10 do
		box(office, "Awning", ox - 11 + i * 2, 9, z0 + 0.5, ox - 9 + i * 2, 9.6, z0 + 3, if i % 2 == 0 then C.white else C.path, { nocollide = true })
	end
	local counters = {
		{ id = "License", dx = -5, color = C.gold, title = "LAW LICENSE" },
		{ id = "Carry", dx = 0, color = C.orange, title = "BRIEFCASE" },
		{ id = "Speed", dx = 5, color = C.sky, title = "FASTER SHOES" },
	}
	for _, k in counters do
		local m = model(office, "Counter_" .. k.id)
		local x = ox + k.dx
		box(m, "Desk", x - 2, 0.5, z0 + 6, x + 2, 3.6, z0 + 8.5, C.white)
		box(m, "DeskFront", x - 2.05, 0.7, z0 + 5.9, x + 2.05, 3.4, z0 + 6.0, k.color, { smooth = true, nocollide = true })
		local top = box(m, "DeskTop", x - 2.2, 3.6, z0 + 5.8, x + 2.2, 3.9, z0 + 8.7, C.ink)
		-- the Briefcase counter shows a Big Briefcase (ReplicatedStorage.Briefcases, tools/zones/BuildBriefcases.lua),
		-- clasps toward the customer; the others a glowing ball
		local briefcases = game:GetService("ReplicatedStorage"):FindFirstChild("Briefcases")
		local caseTemplate = k.id == "Carry" and briefcases and briefcases:FindFirstChild("BigBriefcase")
		if caseTemplate then
			local case = caseTemplate:Clone()
			case.Name = "Icon"
			case:ScaleTo(1.6)
			case:PivotTo(CFrame.new(x, 3.9, z0 + 7.6) * CFrame.Angles(0, math.pi, 0))
			case.Parent = m
		else
			local icon = P(m, "Icon", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 4.6, z0 + 7.2), k.color, { mat = Enum.Material.Neon, shape = Enum.PartType.Ball, nocollide = true })
			local l = Instance.new("PointLight")
			l.Range = 8
			l.Brightness = 0.8
			l.Color = k.color
			l.Parent = icon
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UpgradePrompt"
		prompt.ActionText = "Buy"
		prompt.ObjectText = k.title
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Upgrade", k.id)
		prompt.Parent = top
		local anchor = P(m, "BoardAnchor", Vector3.new(1, 1, 1), CFrame.new(x, 8.2, z0 + 6), C.white, { invisible = true })
		anchor:SetAttribute("Upgrade", k.id)
		CollectionService:AddTag(anchor, "UpgradeBoard")
	end
end

------------------------------------------------------------------ put it where it really goes (PLACE, see the top)
for _, d in zonesRoot:GetDescendants() do
	if d:IsA("BasePart") then
		d.CFrame = PLACE * d.CFrame
	elseif d:IsA("Model") and not d.PrimaryPart then
		d.WorldPivot = PLACE * d.WorldPivot
	end
	local home = d:GetAttribute("Home") -- (chevrons remember where they point)
	if typeof(home) == "CFrame" then
		d:SetAttribute("Home", PLACE * home)
	end
end

------------------------------------------------------------------ no z-fighting (2026-10-13: the floor flickered at the start)
-- The lane's floors sit at y = 0 like the world grass and the plaza: wherever two differently coloured flat tops meet
-- at the same height, the lower-ranked one drops 0.03 (grass under the lane, the lane under the plaza, floors under
-- paths, earlier zones under later ones).
do
	local function aligned(p: BasePart): boolean
		local r = p.CFrame.Rotation
		return (math.abs(r.XVector.X) > 0.999 or math.abs(r.XVector.Z) > 0.999) and math.abs(r.YVector.Y) > 0.999
	end
	local function box(p: BasePart): (Vector3, Vector3)
		local r, sz, c = p.CFrame.Rotation, p.Size, p.Position
		local sx = if math.abs(r.XVector.X) > 0.999 then sz.X else sz.Z
		local sw = if math.abs(r.XVector.X) > 0.999 then sz.Z else sz.X
		return Vector3.new(c.X - sx / 2, c.Y - sz.Y / 2, c.Z - sw / 2), Vector3.new(c.X + sx / 2, c.Y + sz.Y / 2, c.Z + sw / 2)
	end
	local order: { [string]: number } = { SafeZone = 0 }
	for i, z in ZONES do
		order[z.id or z.Id or ""] = i
	end
	local function rank(p: BasePart): number
		if not p:IsDescendantOf(zonesRoot) then
			return if p:IsDescendantOf(workspace:FindFirstChild("Hub") or zonesRoot) then 100 else 0
		end
		local zone: Instance = p
		while zone.Parent and zone.Parent ~= zonesRoot do
			zone = zone.Parent
		end
		local base = if p.Parent and p.Parent.Name == "Floor" then 10 elseif p.Parent and p.Parent.Name == "Path" then 30 else 50
		return base + (order[zone.Name] or 9)
	end
	local cand: { BasePart } = {}
	for _, root in { zonesRoot, workspace:FindFirstChild("Ground"), workspace:FindFirstChild("Hub") } do
		if root then
			for _, p in root:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 and aligned(p) and p.Size.X * p.Size.Z > 1 then
					table.insert(cand, p)
				end
			end
		end
	end
	local moved = {}
	for i = 1, #cand do
		local a = cand[i]
		local alo, ahi = box(a)
		for j = i + 1, #cand do
			local b = cand[j]
			if (a.Color == b.Color and a.Material == b.Material) or not (a:IsDescendantOf(zonesRoot) or b:IsDescendantOf(zonesRoot)) then
				continue
			end
			local blo, bhi = box(b)
			if math.abs(ahi.Y - bhi.Y) < 0.01 and math.min(ahi.X, bhi.X) - math.max(alo.X, blo.X) > 0.05 and math.min(ahi.Z, bhi.Z) - math.max(alo.Z, blo.Z) > 0.05 then
				local victim = if rank(a) <= rank(b) then a else b
				if not moved[victim] then
					moved[victim] = true
					victim.CFrame -= Vector3.new(0, 0.03, 0)
				end
			end
		end
	end
end

return ("built the lane: %d parts, %d studs long (Safe Zone + %d zones), starting at %s"):format(parts, s, #ZONES, tostring(LANE_START))
