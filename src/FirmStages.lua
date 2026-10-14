--!strict
-- Firm stages, v2 (design: "Firm Progression Plan"; v1 kept in ServerStorage.Old_Firms.FirmStages_v1).
-- A firm is two parts:
--   * a FRONT BUILDING over the lobby / waiting room (firm-local z 0..21) that transforms each stage, and
--   * the OFFICE HALL behind it, which never gets a roof, so everyone can see the lawyers.
-- Built in the map's own style: studded Plastic in the map palette, Glass only for windows, Neon only for
-- small lights. Firm-local coordinates (FirmBuilder.frame): x across, y up from the firm floor, z into the
-- plot (0 = entrance line, -z = the street). Clients walk in at x = 0 and along lanes at x = +-18.4 (z = 2)
-- and z = 13.4, so every front keeps a door at x = 0, clear lanes, and an opening at the back of the lobby.
--
-- Parts that belong to a buyable area carry an "Area" attribute (Config.FirmAreas); FirmStages.applyAreas
-- shows them once the area is owned. Elevator parts carry "Floor" (index) and the front's "Floors"
-- attribute lists every stop's floor height; FirmFeatures runs both.

local ServerStorage = game:GetService("ServerStorage")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any

local FirmStages = {}

FirmStages.NAMES = { "Dingy Shack", "Storefront Practice", "Main Street Firm", "Glass Office", "Corporate HQ", "Supreme Tower" }

-- stage from the firm's office segments; Supreme level Config.Prestige.TowerLevel unlocks the Supreme Tower for good
-- (economy pass: the first Supreme is ~45 min in now - "any prestige" would skip the other stages every run)
function FirmStages.stageFor(segments: number, prestigeLevel: number?): number
	local towerAt = ((Config :: any).Prestige and (Config :: any).Prestige.TowerLevel) or 1
	if (prestigeLevel or 0) >= towerAt then
		return 6
	elseif segments >= 9 then
		return 5
	elseif segments >= 7 then
		return 4
	elseif segments >= 6 then
		return 3
	elseif segments >= 5 then
		return 2
	end
	return 1
end

------------------------------------------------------------------ looks (the map palette)
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
type LookDef = { color: Color3, mat: Enum.Material?, t: number?, smooth: boolean? }
local L: { [string]: LookDef } = {
	brick = { color = rgb(196, 86, 62) },
	brickdark = { color = rgb(124, 58, 40) },
	cream = { color = rgb(246, 232, 204) },
	sand = { color = rgb(238, 222, 192) },
	stone = { color = rgb(200, 196, 188) },
	white = { color = rgb(250, 250, 245) },
	panel = { color = rgb(232, 232, 226) },
	navy = { color = rgb(46, 58, 120) },
	dark = { color = rgb(58, 62, 74) },
	roof = { color = rgb(118, 118, 126) },
	orange = { color = rgb(255, 152, 32) },
	yellow = { color = rgb(255, 205, 70) },
	pink = { color = rgb(255, 140, 200) },
	green = { color = rgb(98, 205, 48) },
	greendark = { color = rgb(58, 160, 34) },
	leaf = { color = rgb(120, 215, 45) },
	wood = { color = rgb(196, 124, 58) },
	woodDark = { color = rgb(122, 62, 24) },
	red = { color = rgb(240, 70, 70) },
	redDeep = { color = rgb(200, 50, 50) },
	gold = { color = rgb(255, 196, 40), mat = Enum.Material.Metal },
	window = { color = rgb(140, 230, 255), mat = Enum.Material.Glass, t = 0.35, smooth = true },
	clear = { color = rgb(180, 235, 255), mat = Enum.Material.Glass, t = 0.55, smooth = true },
	glassdeep = { color = rgb(60, 150, 255), mat = Enum.Material.Glass, t = 0.2, smooth = true },
	lamp = { color = rgb(255, 226, 150), mat = Enum.Material.Neon, smooth = true },
	egg = { color = rgb(255, 140, 200), mat = Enum.Material.Neon, smooth = true },
	signglow = { color = rgb(255, 205, 70), mat = Enum.Material.Neon, smooth = true },
}

------------------------------------------------------------------ building helpers (firm-local)
local Build = {}
Build.__index = Build

local function newBuild(parent: Instance, frame: CFrame, name: string)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return setmetatable({ model = m, frame = frame, area = nil :: string? }, Build)
end

-- axis-aligned box between two corners; solid = collides (structure), otherwise decoration
function Build:box(name: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number, look: string, solid: boolean?): Part
	local s = L[look] or L.white
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(math.max(0.05, math.abs(x1 - x0)), math.max(0.05, math.abs(y1 - y0)), math.max(0.05, math.abs(z1 - z0)))
	p.CFrame = self.frame * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Color = s.color
	p.Material = s.mat or Enum.Material.Plastic
	p.Transparency = s.t or 0
	p.CanCollide = solid ~= false
	p.CanQuery = solid ~= false
	p.CanTouch = false
	-- studded tops like the rest of the map (not on glass / lights)
	p.TopSurface = if s.smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	if s.mat == Enum.Material.Neon or s.mat == Enum.Material.Glass then
		p.CastShadow = false
	end
	if self.area then
		p:SetAttribute("Area", self.area)
	end
	p.Parent = self.model
	return p
end

-- vertical cylinder standing at (x, z) from y0 to y1
function Build:post(name: string, x: number, z: number, y0: number, y1: number, r: number, look: string, solid: boolean?): Part
	local p = self:box(name, -r, y0, -r, r, y1, r, look, solid)
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(y1 - y0, r * 2, r * 2)
	p.CFrame = self.frame * CFrame.new(x, (y0 + y1) / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	return p
end

-- flat disc lying on y (pedestals, café tables, helipad)
function Build:disc(name: string, x: number, z: number, y: number, r: number, h: number, look: string, solid: boolean?): Part
	return self:post(name, x, z, y, y + h, r, look, solid)
end

function Build:light(p: BasePart, range: number, brightness: number?, color: Color3?)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness or 1.2
	l.Color = color or Color3.fromRGB(255, 220, 160)
	l.Shadows = false
	l.Parent = p
end

-- a chunky voxel tree (trunk + two leaf blocks), like the hub's trees
function Build:tree(name: string, x: number, z: number, y: number, s: number)
	self:box(name .. "Trunk", x - 0.5 * s, y, z - 0.5 * s, x + 0.5 * s, y + 3 * s, z + 0.5 * s, "woodDark", false)
	self:box(name .. "Leaves", x - 2 * s, y + 2.6 * s, z - 2 * s, x + 2 * s, y + 5.2 * s, z + 2 * s, "leaf", false)
	self:box(name .. "Top", x - 1.2 * s, y + 5.2 * s, z - 1.2 * s, x + 1.2 * s, y + 6.4 * s, z + 1.2 * s, "green", false)
end

function Build:planter(name: string, x0: number, z0: number, x1: number, z1: number, y: number, trees: number, look: string?)
	self:box(name, x0, y, z0, x1, y + 1.2, z1, look or "wood", false)
	self:box(name .. "Soil", x0 + 0.3, y + 1.2, z0 + 0.3, x1 - 0.3, y + 1.4, z1 - 0.3, "greendark", false)
	for i = 1, trees do
		self:tree(name .. "Tree" .. i, x0 + (x1 - x0) * (i - 0.5) / trees, (z0 + z1) / 2, y + 1.4, 0.6)
	end
end

-- flower box under a window: box + a row of blossoms
function Build:flowerBox(name: string, x0: number, x1: number, y: number, z: number)
	self:box(name, x0, y - 0.8, z - 1.2, x1, y, z, "woodDark", false)
	self:box(name .. "Leaves", x0 + 0.2, y, z - 1.0, x1 - 0.2, y + 0.4, z - 0.2, "green", false)
	local n = math.max(2, math.floor((x1 - x0) / 1.4))
	for i = 1, n do
		local x = x0 + (x1 - x0) * (i - 0.5) / n
		self:box(name .. "Bloom" .. i, x - 0.3, y + 0.3, z - 0.9, x + 0.3, y + 0.8, z - 0.3, if i % 2 == 0 then "pink" else "yellow", false)
	end
end

-- wall lantern with a real light
function Build:lantern(name: string, x: number, y: number, z: number)
	self:box(name .. "Arm", x - 0.15, y + 0.6, z - 0.9, x + 0.15, y + 0.9, z, "dark", false)
	local glow = self:box(name, x - 0.45, y - 0.4, z - 1.35, x + 0.45, y + 0.6, z - 0.45, "lamp", false)
	self:box(name .. "Cap", x - 0.6, y + 0.6, z - 1.5, x + 0.6, y + 0.9, z - 0.3, "dark", false)
	self:light(glow, 14, 1.3)
end

-- street lamp post with a real light
function Build:lampPost(name: string, x: number, z: number, y: number)
	self:box(name .. "Base", x - 0.7, y, z - 0.7, x + 0.7, y + 0.5, z + 0.7, "dark", false)
	self:box(name .. "Pole", x - 0.25, y + 0.5, z - 0.25, x + 0.25, y + 8, z + 0.25, "dark", false)
	local glow = self:box(name .. "Lamp", x - 0.7, y + 8, z - 0.7, x + 0.7, y + 9.4, z + 0.7, "lamp", false)
	self:box(name .. "Cap", x - 0.9, y + 9.4, z - 0.9, x + 0.9, y + 9.8, z + 0.9, "dark", false)
	self:light(glow, 18, 1.4)
end

-- a framed window: frame, glass, mullion, sill (on a front face at z, facing the street)
function Build:window(name: string, x0: number, x1: number, y0: number, y1: number, z: number, frame: string?)
	local f = frame or "white"
	self:box(name .. "Frame", x0 - 0.35, y0 - 0.35, z - 0.25, x1 + 0.35, y1 + 0.35, z + 0.05, f, false)
	self:box(name .. "Glass", x0, y0, z - 0.35, x1, y1, z + 0.02, "window", false)
	self:box(name .. "Mullion", (x0 + x1) / 2 - 0.12, y0, z - 0.45, (x0 + x1) / 2 + 0.12, y1, z - 0.2, f, false)
	self:box(name .. "Sill", x0 - 0.6, y0 - 0.55, z - 0.7, x1 + 0.6, y0 - 0.25, z, f, false)
end

-- lobby shell shared by stages 2-6: side walls + back wall with the aisle opening, up to height h
local DEPTH = 21
function Build:shell(h: number, look: string, trim: string?)
	for _, s in { -1, 1 } do
		self:box("SideWall" .. s, s * 24 - 0.4, 0, 0, s * 24 + 0.4, h, DEPTH, look)
		-- corner pilasters at the street end
		self:box("Pilaster" .. s, s * 24 - 0.8, 0, -0.9, s * 24 + 0.8, h + 0.3, 0.6, trim or "white")
	end
	-- back wall: opening x -6..6 up to 9 (clients walk through to the offices)
	self:box("BackWallL", -24, 0, DEPTH - 0.6, -6, h, DEPTH, look)
	self:box("BackWallR", 6, 0, DEPTH - 0.6, 24, h, DEPTH, look)
	self:box("BackWallTop", -6, 9, DEPTH - 0.6, 6, h, DEPTH, look)
	-- base course along the street front
	self:box("BaseCourse", -24.4, 0, -0.9, 24.4, 0.8, -0.3, trim or "white", false)
end

-- a floor slab across the front building (ceiling of the floor below)
function Build:floorPlate(name: string, y: number, look: string?)
	self:box(name, -24.4, y - 0.45, -0.4, 24.4, y + 0.45, DEPTH + 0.4, look or "white")
end

-- roof edge: parapet + coping all round
function Build:parapet(y: number, look: string, x: number?, z0: number?)
	local hw = x or 24.4
	local zz = z0 or -0.4
	self:box("ParapetFront", -hw, y, zz, hw, y + 1.2, zz + 0.6, look)
	self:box("ParapetBack", -hw, y, DEPTH - 0.2, hw, y + 1.2, DEPTH + 0.4, look)
	for _, s in { -1, 1 } do
		self:box("ParapetSide" .. s, s * hw - 0.6 * s, y, zz, s * hw, y + 1.2, DEPTH + 0.4, look)
	end
end

-- a glass front between y0 and y1 (door gap at x -3..3 for a ground floor) with mullions every 6 studs
function Build:glassFront(name: string, y0: number, y1: number, look: string, door: boolean?, mullion: string?)
	local m = mullion or "white"
	if door then
		self:box(name .. "L", -24, y0, -0.5, -3, y1, 0, look)
		self:box(name .. "R", 3, y0, -0.5, 24, y1, 0, look)
		self:box(name .. "Top", -3, 7.5, -0.5, 3, y1, 0, look)
		for _, s in { -1, 1 } do
			self:box(name .. "DoorFrame" .. s, s * 3 - 0.3, y0, -0.8, s * 3 + 0.3, 7.8, 0, m, false)
		end
		self:box(name .. "DoorHead", -3.3, 7.5, -0.8, 3.3, 7.9, 0, m, false)
	else
		self:box(name, -24, y0, -0.5, 24, y1, 0, look)
	end
	for x = -18, 18, 6 do
		if not (door and math.abs(x) < 4) then
			self:box(name .. "Mullion", x - 0.18, y0, -0.75, x + 0.18, y1, -0.4, m, false)
		end
	end
	self:box(name .. "Head", -24.2, y1 - 0.35, -0.75, 24.2, y1 + 0.05, -0.3, m, false)
end

-- street-facing gallery: pedestals behind the glass (stage 3+). FirmFeatures stands the owner's best lawyers on
-- the pedestals ("ShowcaseSlot" attribute) so passers-by see them.
function Build:showcase(y0: number, y1: number, count: number)
	self:glassFront("ShowcaseGlass", y0, y1, "clear", false, "gold")
	self:box("ShowcaseFloor", -22, y0, 0, 22, y0 + 0.3, 5.2, "white")
	self:box("ShowcaseBack", -24, y0, 5.2, 24, y1, 5.6, "navy")
	for i = 1, count do
		local x = -22 + 44 * (i - 0.5) / count
		local ped = self:disc("ShowcasePedestal" .. i, x, 2.6, y0 + 0.3, 1.4, 1.4, "white")
		ped:SetAttribute("ShowcaseSlot", i)
		self:disc("ShowcaseRing" .. i, x, 2.6, y0 + 1.7, 1.5, 0.08, "gold", false)
		local spot = self:box("ShowcaseSpot" .. i, x - 0.5, y1 - 0.4, 2.1, x + 0.5, y1 - 0.1, 3.1, "lamp", false)
		self:light(spot, 9, 1.6)
	end
	-- a label strip under the glass
	self:box("ShowcaseBand", -24.2, y0 - 0.1, -0.85, 24.2, y0 + 0.5, -0.3, "gold", false)
end

-- porch + steps over FirmBuilder's invisible colliders (porch z -4.5..0, steps to -6), a doormat and two
-- planters with lamp posts on the lawn either side
function Build:entry(look: string, lamps: boolean?)
	self:box("Porch", -11, -1.5, -4.5, 11, 0, 0, look)
	self:box("Step1", -11, -1.5, -5.25, 11, -0.5, -4.5, look)
	self:box("Step2", -11, -1.5, -6, 11, -1.0, -5.25, look)
	self:box("Doormat", -2.2, 0, -3.2, 2.2, 0.08, -0.8, "redDeep", false)
	if lamps then
		for _, s in { -1, 1 } do
			self:lampPost("PorchLamp" .. s, 9.5 * s, -5.3, 0)
		end
	end
end

-- elevator to the upper floors: one call point per floor (the lobby + each stop), at the back-right corner
-- of the lobby, clear of the client lanes. FirmFeatures adds the prompts.
-- A stop is a floor height, or { y, x, z, face } to place it elsewhere (face = which side riders step out:
-- -1 toward the street, 1 away from it). Each door carries "Floor" (its index) and "Arrive" (firm-local
-- spot riders are put down at); the front carries "Floors" (how many stops).
function Build:elevator(stops: { any })
	local all: { any } = { { y = 0 } }
	for _, s in stops do
		table.insert(all, if type(s) == "number" then { y = s } else s)
	end
	self.model:SetAttribute("Floors", #all)
	for i, s in all do
		local y, cx, cz, face = s.y, s.x or 17.5, s.z or 20.35, s.face or -1
		self:box("ElevatorFrame" .. i, cx - 2.9, y, cz - 0.45, cx + 2.9, y + 8, cz + 0.45, "gold", false)
		local d0, d1 = cz + face * 0.45, cz + face * 0.75
		local door = self:box("Elevator", cx - 2.3, y + 0.1, math.min(d0, d1), cx + 2.3, y + 7.4, math.max(d0, d1), "navy", false)
		door:SetAttribute("Floor", i)
		door:SetAttribute("Arrive", Vector3.new(cx, y + 3, cz + face * 3.5))
		local l0, l1 = cz + face * 0.75, cz + face * 0.95
		local arrow = self:box("ElevatorLight" .. i, cx - 0.6, y + 7.5, math.min(l0, l1), cx + 0.6, y + 7.9, math.max(l0, l1), "lamp", false)
		self:light(arrow, 8, 1)
	end
end

------------------------------------------------------------------ the six fronts
-- each returns the CFrame (firm-local) for the name sign
local FRONTS: { [number]: (any) -> CFrame } = {}

-- 1. Dingy Shack: the game's own template, opened up so clients can walk through it, with a hanging
-- lantern and a tidier porch
FRONTS[1] = function(b)
	local template = ServerStorage.Templates:FindFirstChild("Firms") and ServerStorage.Templates.Firms:FindFirstChild("Firm1")
	if template then
		local shack = template:Clone()
		shack.Name = "DingyShack"
		for _, name in { "Desk1", "DeskSlots", "SpawnPoint", "UpgradeSpot", "Sign" } do
			local c = shack:FindFirstChild(name)
			if c then
				c:Destroy()
			end
		end
		shack:PivotTo(b.frame * CFrame.new(0, 0, 9))
		local piv = shack:GetPivot()
		for _, p in shack:GetDescendants() do
			if p:IsA("BasePart") then
				local l = piv:PointToObjectSpace(p.Position)
				if l.Z > 11 and math.abs(l.X) < 3 and p.Size.Y > 4 then
					p:Destroy() -- back-wall planks in the middle: the aisle to the offices runs through here
				elseif math.abs(l.X) > 11 and l.Z > -9.2 and l.Z < -5.8 and p.Size.Y > 4 then
					p:Destroy() -- side doorways (frame z 0.5..3.5): clients walk out to the benches
				elseif math.abs(l.X) < 5 and l.Z > -2 and l.Z < 8 and l.Y < 5 then
					p:Destroy() -- furniture in the middle of the floor would block the walk-in route
				else
					p.CanCollide = p.Size.Y > 4 -- walls block, clutter doesn't
					if p.Size.Y > 0.3 and p.Size.X > 0.3 and p.Size.Z > 0.3 then
						p.TopSurface = Enum.SurfaceType.Studs
					end
				end
			end
		end
		shack.Parent = b.model
	end
	b:entry("woodDark")
	-- a hanging lantern over the door and a crooked "OPEN" sign: still dingy, just loved
	local lamp = b:box("ShackLantern", -0.5, 7.2, -4.4, 0.5, 8.3, -3.4, "lamp", false)
	b:light(lamp, 16, 1.4)
	b:box("ShackLanternChain", -0.08, 8.3, -3.98, 0.08, 9.6, -3.82, "dark", false)
	local open = b:box("OpenSign", 6, 5.6, -3.9, 10, 7, -3.7, "yellow", false)
	open.CFrame = open.CFrame * CFrame.Angles(0, 0, math.rad(6))
	return CFrame.new(0, 9.2, -3.4)
end

-- 2. Storefront Practice: one storey of brick, framed shop windows with flower boxes, a striped awning,
-- lanterns either side of the door and a rooftop café (area: CafeTerrace)
FRONTS[2] = function(b)
	local H = 9
	b:entry("stone", true)
	b:shell(H, "brick", "white")
	for _, s in { -1, 1 } do
		local x0, x1 = 5 * s, 21 * s
		local lo, hi = math.min(x0, x1), math.max(x0, x1)
		b:box("Sill" .. s, lo, 0, -0.5, hi, 0.9, 0, "brick")
		b:box("Shop" .. s, lo, 0.9, -0.4, hi, 6.6, 0, "window")
		b:box("ShopMullion" .. s, (lo + hi) / 2 - 0.2, 0.9, -0.6, (lo + hi) / 2 + 0.2, 6.6, -0.3, "white", false)
		b:box("ShopFrame" .. s, lo - 0.3, 6.6, -0.7, hi + 0.3, 7.0, -0.2, "white", false)
		b:box("ShopTop" .. s, lo, 6.6, -0.5, hi, H, 0, "brick")
		b:box("Pier" .. s, math.min(21 * s, 24 * s), 0, -0.5, math.max(21 * s, 24 * s), H, 0, "brick")
		b:box("DoorPier" .. s, math.min(3 * s, 5 * s), 0, -0.5, math.max(3 * s, 5 * s), H, 0, "brick")
		b:flowerBox("FlowerBox" .. s, lo + 0.5, hi - 0.5, 0.9, -0.5)
		b:lantern("DoorLantern" .. s, 4 * s, 5.2, -0.5)
	end
	b:box("DoorTop", -3, 7, -0.5, 3, H, 0, "brick")
	b:box("Door", -3, 0, -0.3, 3, 7, -0.1, "woodDark", false).Transparency = 0.5
	b:box("Cornice", -24.6, H - 0.2, -1.0, 24.6, H + 0.6, DEPTH + 0.6, "white")
	b:box("Roof", -24, H, 0, 24, H + 0.3, DEPTH, "roof")
	b:parapet(H + 0.6, "white")
	-- striped awning (green / white), sloping out over the windows
	for i = 0, 11 do
		local x0 = -23 + i * (46 / 12)
		local stripe = b:box("Awning" .. i, x0, 0, -2.5, x0 + 46 / 12, 0.3, 2.5, if i % 2 == 0 then "greendark" else "white", false)
		stripe.CFrame = b.frame * CFrame.new(x0 + 23 / 12, 7.9, -2.4) * CFrame.Angles(math.rad(18), 0, 0)
	end
	b:box("AwningValance", -23, 6.9, -4.95, 23, 7.4, -4.75, "greendark", false)
	-- rooftop café (bought area)
	b.area = "CafeTerrace"
	for i, x in { -14, 0, 14 } do
		b:disc("CafeTable" .. i, x, 10, H + 0.9, 1.2, 0.2, "white", false)
		b:post("CafePole" .. i, x, 10, H + 0.9, H + 3.9, 0.1, "dark", false)
		b:disc("CafeUmbrella" .. i, x, 10, H + 3.9, 2.6, 0.3, if i == 2 then "orange" else "red", false)
		for _, d in { -1.8, 1.8 } do
			b:box("CafeChair" .. i .. d, x + d - 0.5, H + 0.9, 9.5, x + d + 0.5, H + 1.9, 10.5, "yellow", false)
		end
	end
	b:planter("CafePlanter", -20, 16, -12, 19, H + 0.9, 1)
	b.area = nil
	b:elevator({ H + 0.3 })
	return CFrame.new(0, 8.1, -0.75)
end

-- 3. Main Street Firm: sand-stone ground floor with framed windows and a classic porch, brick upper floor
-- whose glass front is the Showcase (3); coffee counter in the lobby (area: CoffeeBreak)
FRONTS[3] = function(b)
	local G, H = 9, 18
	b:entry("stone", true)
	b:shell(H, "sand", "white")
	for _, s in { -1, 1 } do
		b:box("Ground" .. s, math.min(3 * s, 24 * s), 0, -0.5, math.max(3 * s, 24 * s), G, 0, "sand")
		for i, x in { 9, 15, 21 } do
			local lo, hi = math.min((x - 1.6) * s, (x + 1.6) * s), math.max((x - 1.6) * s, (x + 1.6) * s)
			b:window(("Win%d_%d"):format(s, i), lo, hi, 2.2, 7, -0.5)
		end
		b:flowerBox("FlowerBox" .. s, math.min(7 * s, 23 * s), math.max(7 * s, 23 * s), 1.5, -0.9)
		b:box("UpperSide" .. s, math.min(24 * s, (24 - 0.8) * s), G, 0, math.max(24 * s, (24 - 0.8) * s), H, DEPTH, "brick")
	end
	b:box("DoorTop", -3, 7.5, -0.5, 3, G, 0, "sand")
	b:box("Door", -3, 0, -0.3, 3, 7.5, -0.1, "woodDark", false).Transparency = 0.5
	b:floorPlate("Floor2", G, "white")
	b:box("BeltCourse", -24.4, G - 0.2, -0.9, 24.4, G + 0.5, -0.3, "white", false)
	b:showcase(G + 0.45, H, 3)
	b:box("UpperBand", -24, H - 1, -0.6, 24, H, 0, "brick")
	b:box("Cornice", -24.6, H - 0.2, -1.0, 24.6, H + 0.6, DEPTH + 0.6, "white")
	b:box("Roof", -24, H, 0, 24, H + 0.3, DEPTH, "roof")
	b:parapet(H + 0.6, "white")
	-- classic porch: four columns with bases and capitals, an entablature with the sign, a pediment block
	for i, x in { -8, -3, 3, 8 } do
		b:box("ColumnBase" .. i, x - 1.1, 0, -5.6, x + 1.1, 0.6, -3.4, "white")
		b:post("Column" .. i, x, -4.5, 0.6, 8.4, 0.75, "white")
		b:box("ColumnCap" .. i, x - 1.1, 8.4, -5.6, x + 1.1, 9, -3.4, "white")
	end
	b:box("Entablature", -10, 9, -6, 10, 10.5, 0, "white")
	b:box("PedimentStep1", -9, 10.5, -6, 9, 11.4, -0.5, "white")
	b:box("PedimentStep2", -6, 11.4, -6, 6, 12.3, -0.5, "white")
	b:box("PedimentStep3", -3, 12.3, -6, 3, 13.2, -0.5, "white")
	for _, s in { -1, 1 } do
		b:lantern("DoorLantern" .. s, 4.2 * s, 5.4, -0.5)
	end
	-- coffee counter in the lobby's back-left corner (bought area)
	b.area = "CoffeeBreak"
	b:box("CoffeeCounter", -18, 0, 17.5, -9, 3.2, 20, "wood")
	b:box("CoffeeCounterTop", -18.3, 3.2, 17.2, -8.7, 3.6, 20.3, "white")
	b:box("CoffeeMachine", -16.5, 3.6, 18.6, -14.5, 5.6, 19.8, "dark", false)
	local light = b:box("CoffeeLight", -15.9, 4.8, 18.4, -15.1, 5.2, 18.6, "lamp", false)
	b:light(light, 8, 1)
	b.area = nil
	b:elevator({ G + 0.45, H + 0.3 })
	return CFrame.new(0, 9.75, -6.1)
end

-- 4. Glass Office: four glass floors with white mullions — lobby, Showcase (6), an open floor, Law Library +
-- Conference Room (areas: LawLibrary, ConferenceRoom)
FRONTS[4] = function(b)
	local F = 9 -- floor height
	b:entry("stone", true)
	b:shell(4 * F, "panel", "white")
	b:glassFront("LobbyGlass", 0, F, "clear", true)
	b:box("ReceptionDesk", -18, 0, 17.5, -9, 3, 19.5, "navy") -- back corner, clear of the walk-in lanes
	b:box("ReceptionTop", -18.3, 3, 17.2, -8.7, 3.4, 19.8, "white")
	b:floorPlate("Floor2", F)
	b:showcase(F + 0.45, 2 * F, 6)
	b:floorPlate("Floor3", 2 * F)
	-- (the Hatch Lab that was on this floor was removed: user, "remove the lab in the tower")
	b:glassFront("Floor3Glass", 2 * F + 0.45, 3 * F, "clear")
	b:planter("Floor3PlanterL", -20, 16, -14, 19, 2 * F + 0.45, 1)
	b:planter("Floor3PlanterR", 6, 16, 12, 19, 2 * F + 0.45, 1) -- clear of the elevator stop at x 17.5
	b:floorPlate("Floor4", 3 * F)
	b:glassFront("LibraryGlass", 3 * F + 0.45, 4 * F, "clear")
	b.area = "LawLibrary"
	for i = 0, 4 do -- five shelves: the right-hand end stays clear for the elevator stop (x 17.5)
		local x0 = -22 + i * 7.6
		b:box("Shelf" .. i, x0, 3 * F + 0.45, 16, x0 + 5, 4 * F - 1, 20, "woodDark")
		for k = 0, 3 do
			b:box(("Books%d_%d"):format(i, k), x0 + 0.3, 3 * F + 1.2 + k * 1.7, 15.8, x0 + 4.7, 3 * F + 2.4 + k * 1.7, 16.1, ({ "red", "navy", "green", "yellow" })[(i + k) % 4 + 1], false)
		end
	end
	b.area = "ConferenceRoom"
	b:box("ConferenceTable", -8, 3 * F + 0.45, 6, 8, 3 * F + 2.5, 10, "wood")
	for i, x in { -6, -2, 2, 6 } do
		for _, z in { 4.8, 11.2 } do
			b:box(("ConfChair%d_%d"):format(i, z), x - 0.6, 3 * F + 0.45, z - 0.6, x + 0.6, 3 * F + 1.8, z + 0.6, "navy", false)
		end
	end
	b.area = nil
	b:floorPlate("Roof", 4 * F, "roof")
	b:parapet(4 * F + 0.45, "white")
	for _, s in { -1, 1 } do
		b:box("Fin" .. s, math.min(24.6 * s, 24 * s), 0, -1.2, math.max(24.6 * s, 24 * s), 4 * F + 1.5, 3, "white")
	end
	b:box("Canopy", -16, 8.5, -8, 16, 9.3, 0, "white")
	local under = b:box("CanopyLight", -14, 8.3, -6, 14, 8.5, -2, "lamp", false)
	b:light(under, 16, 0.9)
	for _, s in { -1, 1 } do
		b:post("CanopyPost" .. s, 14 * s, -7, 0, 8.5, 0.35, "dark")
	end
	b:planter("LobbyPlanter", 6, 17.5, 12, 20, 0, 1)
	b:elevator({ F + 0.45, 2 * F + 0.45, 3 * F + 0.45, 4 * F + 0.45 })
	return CFrame.new(0, 4 * F + 1.5, -0.3)
end

-- 5. Corporate HQ: atrium behind two white Vs, Showcase (9), Executive Lounge, stepped terraces, a roof
-- garden with the Rooftop Hologram (areas: AtriumCafe, ExecLounge, RoofGarden)
FRONTS[5] = function(b)
	local F = 9
	b:entry("stone", true)
	b:shell(4 * F, "white", "panel")
	b:glassFront("AtriumGlass", 0, 2 * F, "clear", true)
	-- two white Vs standing just in front of the atrium glass (decoration: nobody bumps into them)
	for i, beam in { { -12, -17 }, { -12, -7 }, { 12, 17 }, { 12, 7 } } do
		local bottom = b.frame * CFrame.new(beam[1], 0, -1.2)
		local top = b.frame * CFrame.new(beam[2], 2 * F, -1.2)
		local mid = bottom.Position:Lerp(top.Position, 0.5)
		local p = b:box("VBeam" .. i, 0, 0, 0, 1.4, 1, 1.4, "white", false)
		p.Size = Vector3.new(1.4, (top.Position - bottom.Position).Magnitude, 1.4)
		p.CFrame = CFrame.lookAt(mid, top.Position) * CFrame.Angles(math.rad(90), 0, 0)
	end
	for _, x in { -12, 12 } do
		b:box("VFoot" .. x, x - 1.2, 0, -2.2, x + 1.2, 0.8, -0.2, "panel", false)
	end
	b:box("BeamCap", -25, 2 * F - 0.6, -2, 25, 2 * F + 0.6, 0, "white")
	b.area = "AtriumCafe"
	b:box("CoffeeBar", -18, 0, 16.5, -8, 3.3, 19.5, "white")
	b:box("CoffeeBarTop", -18.4, 3.3, 16.1, -7.6, 3.7, 19.9, "wood")
	for i, x in { -16, -12.5, -9.5 } do
		b:box("BarStool" .. i, x - 0.5, 0, 15, x + 0.5, 2.2, 16, "orange", false)
	end
	local bl = b:box("CoffeeBarLight", -14, 7, 17.5, -12, 7.4, 18.5, "lamp", false)
	b:light(bl, 12, 1.2)
	b.area = nil
	b:floorPlate("Floor3", 2 * F)
	b:showcase(2 * F + 0.45, 3 * F, 9)
	b:floorPlate("Floor4", 3 * F)
	b:glassFront("LoungeGlass", 3 * F + 0.45, 4 * F, "clear")
	b.area = "ExecLounge"
	local carpet = b:box("LoungeCarpet", -23, 3 * F + 0.45, 0.5, 23, 3 * F + 0.6, DEPTH - 1, "redDeep", false)
	carpet:SetAttribute("LoungeFloor", true)
	for i, x in { -16, 0, 16 } do
		b:box("Sofa" .. i, x - 5, 3 * F + 0.6, 10, x + 5, 3 * F + 2.3, 13, "navy", false)
		b:box("SofaBack" .. i, x - 5, 3 * F + 2.3, 12.4, x + 5, 3 * F + 3.9, 13, "navy", false)
		b:box("SofaTable" .. i, x - 2, 3 * F + 0.6, 6.5, x + 2, 3 * F + 1.6, 8.5, "wood", false)
	end
	local glow = b:box("LoungeGlow", -22, 3 * F + 1, 19.5, 22, 4 * F - 1, 20.3, "lamp", false)
	b:light(glow, 20, 1)
	b.area = nil
	b:floorPlate("Floor5", 4 * F)
	-- floors 5-6 step back 6 from the street; planted terrace in front
	b:box("UpperGlassFront", -21, 4 * F, 6, 21, 6 * F, 6.5, "glassdeep")
	for x = -18, 18, 6 do
		b:box("UpperMullion" .. x, x - 0.18, 4 * F, 5.75, x + 0.18, 6 * F, 6.1, "white", false)
	end
	for _, s in { -1, 1 } do
		b:box("UpperSide" .. s, math.min(21 * s, (21 - 0.6) * s), 4 * F, 6, math.max(21 * s, (21 - 0.6) * s), 6 * F, DEPTH, "glassdeep")
	end
	b:box("UpperBand", -21.3, 5 * F - 0.45, 5.6, 21.3, 5 * F + 0.45, DEPTH, "white")
	b:box("UpperRoof", -21.3, 6 * F - 0.45, 5.6, 21.3, 6 * F + 0.45, DEPTH, "white")
	b:box("TerraceDeck", -24, 4 * F + 0.45, 0, 24, 4 * F + 0.8, 6, "wood")
	b:box("TerraceRail", -24, 4 * F + 0.8, -0.2, 24, 4 * F + 2.2, 0.2, "clear")
	b:box("TerraceRailTop", -24, 4 * F + 2.2, -0.3, 24, 4 * F + 2.5, 0.3, "white", false)
	for i, x in { -22, -8, 6 } do
		b:planter("TerracePlanter" .. i, x, 0.8, x + 12, 4.4, 4 * F + 0.8, 2)
	end
	b.area = "RoofGarden"
	b:box("RoofLawn", -20, 6 * F + 0.45, 7, 20, 6 * F + 0.7, 20, "green", false)
	for i, x in { -16, 16 } do
		b:tree("RoofTree" .. i, x, 13, 6 * F + 0.7, 1)
	end
	for i, x in { -9, 9 } do
		b:box("RoofBench" .. i, x - 2, 6 * F + 0.7, 18, x + 2, 6 * F + 1.6, 19, "wood", false)
	end
	b.area = nil
	b:parapet(6 * F + 0.45, "white", 21.3, 5.6)
	local pad = b:disc("HologramPad", 0, 13.5, 6 * F + 0.45, 4.5, 0.6, "white")
	pad:SetAttribute("Hologram", "Blue")
	b:disc("HologramRing", 0, 13.5, 6 * F + 1.05, 4.7, 0.15, "glassdeep", false)
	b:box("HQSign", -14, 3 * F - 2.6, -0.6, 14, 3 * F - 0.4, -0.2, "gold", false)
	-- (2026-10-13, upstairs rooms: a stop on 5F too - UpperBand is the slab between the glass box's two floors, and the
	-- rooms of Config.Floors.Slots[5] stand on both)
	b:elevator({ 2 * F + 0.45, 3 * F + 0.45, 4 * F + 0.45, 5 * F + 0.45, 6 * F + 0.45 })
	return CFrame.new(0, 3 * F - 1.5, -0.75)
end

-- 6. Supreme Tower (prestige): glass podium with Showcase (12), a 12-storey tower with gold bands, the
-- private-courtroom floor and the lit penthouse (areas: PrivateCourt, PartnerSuite), a gold crown with a
-- helipad and the gold Hologram
FRONTS[6] = function(b)
	local F = 9.6
	b:entry("white", true)
	b:shell(2 * F, "stone", "gold")
	b:glassFront("LobbyGlass", 0, F, "clear", true, "gold")
	b:box("LobbyFloor", -24, 0, 0, 24, 0.15, DEPTH, "white")
	b:floorPlate("Floor2", F, "gold")
	b:showcase(F + 0.45, 2 * F, 12)
	b:floorPlate("PodiumRoof", 2 * F, "gold")
	b:box("Canopy", -14, 8.6, -9, 14, 9.6, 0, "gold")
	local under = b:box("CanopyLight", -12, 8.4, -8, 12, 8.6, -2, "lamp", false)
	b:light(under, 18, 1)
	for _, s in { -1, 1 } do
		b:post("CanopyColumn" .. s, 12 * s, -8, 0, 8.6, 0.6, "gold")
	end
	local T0, T1 = 2 * F + 0.45, 2 * F + 0.45 + 108
	-- (2026-10-13, upstairs rooms: the tower is hollow - four glass walls - so its storeys hold the rooms of
	-- Config.Floors.Slots[6]; the TowerBand slabs below are its floors, one every 9 studs. It was one solid glass block.)
	b:box("TowerFront", -20, T0, 2, 20, T1, 2.6, "glassdeep")
	b:box("TowerBack", -20, T0, 18.4, 20, T1, 19, "glassdeep")
	b:box("TowerSideL", -20, T0, 2.6, -19.4, T1, 18.4, "glassdeep")
	b:box("TowerSideR", 19.4, T0, 2.6, 20, T1, 18.4, "glassdeep")
	for k = 0, 12 do
		local y = T0 + (T1 - T0) * k / 12
		b:box("TowerBand" .. k, -20.4, y - 0.35, 1.6, 20.4, y + 0.35, 19.4, if k % 3 == 0 then "gold" else "navy")
	end
	for i = 0, 10 do
		local x = -20 + i * 4
		b:box("TowerMullion" .. i, x - 0.15, T0, 1.6, x + 0.15, T1, 2.1, "navy", false)
	end
	b.area = "PrivateCourt"
	b:box("CourtroomFloor", -19.6, T0 + 45, 1.7, 19.6, T0 + 54, 2.2, "wood", false)
	b.area = "PartnerSuite"
	local pent = b:box("PenthouseGlow", -19.6, T1 - 18, 1.7, 19.6, T1 - 0.4, 2.2, "lamp", false)
	b:light(pent, 30, 1.2)
	b.area = nil
	b:box("Crown", -18, T1, 3, 18, T1 + 5, 18, "gold")
	b:box("CrownRail", -18, T1 + 5, 3, 18, T1 + 6, 3.4, "gold", false)
	b:disc("Helipad", 9, 10.5, T1 + 5, 6.8, 0.8, "dark")
	b:disc("HelipadRing", 9, 10.5, T1 + 5.8, 5.6, 0.2, "yellow", false)
	b:box("HelipadH1", 7.8, T1 + 5.9, 8.5, 8.4, T1 + 6, 12.5, "white", false)
	b:box("HelipadH2", 9.6, T1 + 5.9, 8.5, 10.2, T1 + 6, 12.5, "white", false)
	b:box("HelipadH3", 8.4, T1 + 5.9, 10.2, 9.6, T1 + 6, 10.8, "white", false)
	local pad = b:disc("HologramPad", -9, 10.5, T1 + 5, 4.5, 0.6, "gold")
	pad:SetAttribute("Hologram", "Gold")
	local beacon = b:post("Spire", -15, 15, T1 + 5, T1 + 31, 0.5, "gold", false)
	local tip = b:box("SpireTip", -15.6, T1 + 31, 14.4, -14.4, T1 + 32.2, 15.6, "red", false)
	tip.Material = Enum.Material.Neon
	b:light(beacon, 10, 1)
	-- the tower's room floors (bands k = 0, 1, 2, 5: their tops are T0 + 9k + 0.35), stops by the back wall; then the crown
	local function towerStop(k: number): any
		return { y = T0 + 9 * k + 0.35, x = 15, z = 17.4, face = -1 }
	end
	b:elevator({ F + 0.45, towerStop(0), towerStop(1), towerStop(2), towerStop(5), { y = T1 + 5, x = 0, z = 4.5, face = 1 } }) -- top stop on the crown, between pad and helipad
	return CFrame.new(0, 2 * F - 1.8, -0.75)
end

------------------------------------------------------------------ the open office hall, restyled per stage
-- (stage 5's pergola beams over the hall were removed: user, "remove the fencing above the plot")
type HallStyle = { wall: string, cap: string, post: string, rug: string, carpet: boolean? }
local HALL: { HallStyle } = {
	{ wall = "wood", cap = "woodDark", post = "woodDark", rug = "redDeep" },
	{ wall = "brick", cap = "white", post = "brickdark", rug = "greendark" },
	{ wall = "sand", cap = "white", post = "white", rug = "navy" },
	{ wall = "clear", cap = "white", post = "white", rug = "navy" },
	{ wall = "clear", cap = "wood", post = "white", rug = "orange" },
	{ wall = "clear", cap = "gold", post = "gold", rug = "redDeep", carpet = true },
}

local function paint(p: BasePart, look: string)
	local s = L[look]
	p.Color = s.color
	p.Material = s.mat or Enum.Material.Plastic
	p.Transparency = s.t or 0
end

-- Restyle the kit's office-hall walls (picked out by shape: the 5-stud side panels, their cap rail and the
-- posts between segments), and dress every segment: a rug under each office, a plant by the wall and a
-- sconce with a real light on every other post. The hall never gets a roof.
function FirmStages.dressHall(firm: Model, frame: CFrame, stage: number, hallStart: number, hallEnd: number)
	local style = HALL[stage] or HALL[1]
	local shell = firm:FindFirstChild("Shell")
	if shell then
		for _, piece in shell:GetChildren() do
			if piece.Name == "OfficeSegment" or piece.Name == "WaitingRoom" or piece.Name == "ExpansionLock" or piece.Name == "BackWall" then
				for _, p in piece:GetDescendants() do
					if p:IsA("BasePart") then
						local l = frame:PointToObjectSpace(p.Position)
						local edge = math.abs(math.abs(l.X) - 23.6) < 0.6
						if edge and p.Size.X < 1 and p.Size.Y > 4 and p.Size.Y < 5.5 then
							paint(p, style.wall) -- the wall panel
						elseif edge and p.Size.Y <= 0.6 and p.Size.X >= 1.2 and p.Size.X <= 1.6 and l.Y > 4.5 then
							paint(p, style.cap) -- the cap rail
						elseif math.abs(math.abs(l.X) - 23.5) < 0.6 and p.Size.Y > 6 and p.Size.X > 1.4 then
							paint(p, style.post) -- posts between segments
						end
					end
				end
			end
		end
	end
	local b = newBuild(firm, frame, "HallDressing")
	local seg = 0
	local z = hallStart
	while z + 11 <= hallEnd + 0.01 do
		local zc = z + 5.5
		for _, s in { -1, 1 } do
			-- rug under the office (lawyer + client spots), plant in the corner by the wall
			b:box("OfficeRug", math.min(s * 12, s * 19.5), 0.02, zc - 3.2, math.max(s * 12, s * 19.5), 0.12, zc + 3.2, style.rug, false)
			b:box("OfficePlantPot", s * 21.6 - 0.6, 0, z + 1.2, s * 21.6 + 0.6, 1.1, z + 2.4, "woodDark", false)
			b:box("OfficePlant", s * 21.6 - 0.9, 1.1, z + 0.9, s * 21.6 + 0.9, 2.9, z + 2.7, "leaf", false)
			if seg % 2 == 0 then
				local sconce = b:box("Sconce", s * 23.2 - 0.3, 4.2, z - 0.4, s * 23.2 + 0.3, 4.9, z + 0.4, "lamp", false)
				b:light(sconce, 12, 0.8)
			end
		end
		seg += 1
		z += 11
	end
	if style.carpet then
		b:box("RedCarpet", -2.5, 0.02, hallStart, 2.5, 0.14, hallEnd - 1, "redDeep", false)
		b:box("RedCarpetTrimL", -2.8, 0.02, hallStart, -2.5, 0.16, hallEnd - 1, "gold", false)
		b:box("RedCarpetTrimR", 2.5, 0.02, hallStart, 2.8, 0.16, hallEnd - 1, "gold", false)
	end
end

-- Shows the parts of the areas the player owns and hides the rest (they appear when bought).
function FirmStages.applyAreas(firm: Model, owned: { [string]: boolean })
	local front = firm:FindFirstChild("Front")
	if not front then
		return
	end
	for _, p in front:GetDescendants() do
		if p:IsA("BasePart") then
			local area = p:GetAttribute("Area")
			if area then
				if p:GetAttribute("AreaT") == nil then
					p:SetAttribute("AreaT", p.Transparency)
					p:SetAttribute("AreaC", p.CanCollide)
				end
				local has = owned[area] == true
				p.Transparency = if has then p:GetAttribute("AreaT") :: number else 1
				p.CanCollide = has and (p:GetAttribute("AreaC") :: boolean)
				for _, l in p:GetChildren() do
					if l:IsA("Light") then
						l.Enabled = has
					end
				end
			end
		end
	end
end

-- Builds the stage's front building into the firm; returns the sign's CFrame (world)
function FirmStages.buildFront(firm: Model, frame: CFrame, stage: number): CFrame
	local b = newBuild(firm, frame, "Front")
	firm:SetAttribute("Stage", stage)
	firm:SetAttribute("StageName", FirmStages.NAMES[stage])
	local signLocal = (FRONTS[stage] or FRONTS[1])(b)
	return frame * signLocal
end

return FirmStages
