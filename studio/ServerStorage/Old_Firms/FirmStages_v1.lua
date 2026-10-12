--!strict
-- Firm stages (design: "Firm Progression Plan", Blender FirmProgression.blend). The firm is two parts:
--   * a FRONT BUILDING over the lobby / waiting room (firm-local z 0..21) that transforms each stage, and
--   * the OFFICE HALL behind it, which never gets a roof, so everyone can see the lawyers. Its walls are
--     restyled per stage (fence -> brick -> stone -> glass -> deck -> marble & gold).
-- Firm-local coordinates (FirmBuilder.frame): x across, y up from the firm floor, z into the plot
-- (0 = entrance line, -z = the street). Clients walk in at x = 0, so every front keeps a door there and an
-- opening at the back of the lobby (z = 21) into the office aisle.

local ServerStorage = game:GetService("ServerStorage")

local FirmStages = {}

FirmStages.NAMES = { "Dingy Shack", "Storefront Practice", "Main Street Firm", "Glass Office", "Corporate HQ", "Supreme Tower" }

-- stage from the firm's office segments; any prestige unlocks the Supreme Tower for good
function FirmStages.stageFor(segments: number, prestigeLevel: number?): number
	if (prestigeLevel or 0) > 0 then
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

------------------------------------------------------------------ looks
local function rgb(h: string): Color3
	return Color3.fromHex(h)
end
local L: { [string]: { color: Color3, mat: Enum.Material, t: number? } } = {
	brick = { color = rgb("B5543C"), mat = Enum.Material.Brick },
	brickdark = { color = rgb("7E3426"), mat = Enum.Material.Brick },
	cream = { color = rgb("EFE3C8"), mat = Enum.Material.Limestone },
	stone = { color = rgb("C9C3B6"), mat = Enum.Material.Slate },
	white = { color = rgb("F3F3F0"), mat = Enum.Material.SmoothPlastic },
	panel = { color = rgb("D8DCE2"), mat = Enum.Material.SmoothPlastic },
	dark = { color = rgb("2B2F3A"), mat = Enum.Material.SmoothPlastic },
	roof = { color = rgb("4A4F5C"), mat = Enum.Material.Concrete },
	window = { color = rgb("9FD3F2"), mat = Enum.Material.Glass, t = 0.35 },
	clear = { color = rgb("BFE6FF"), mat = Enum.Material.Glass, t = 0.6 },
	glassdeep = { color = rgb("2E5E8C"), mat = Enum.Material.Glass, t = 0.15 },
	gold = { color = rgb("FFC23A"), mat = Enum.Material.Metal },
	wood = { color = rgb("B07A44"), mat = Enum.Material.WoodPlanks },
	woodDark = { color = rgb("6E4C28"), mat = Enum.Material.WoodPlanks },
	awning = { color = rgb("1E7A4A"), mat = Enum.Material.Fabric },
	red = { color = rgb("E04848"), mat = Enum.Material.Fabric },
	carpet = { color = rgb("B3243A"), mat = Enum.Material.Fabric },
	marble = { color = rgb("F2EFEA"), mat = Enum.Material.Marble },
	concrete = { color = rgb("B9BCC2"), mat = Enum.Material.Concrete },
	leaf = { color = rgb("4CBF4A"), mat = Enum.Material.Grass },
	soil = { color = rgb("2E8B3E"), mat = Enum.Material.Grass },
	warm = { color = rgb("FFE2A8"), mat = Enum.Material.Neon },
	egg = { color = rgb("FF8AD8"), mat = Enum.Material.Neon },
	suit = { color = rgb("6B2E8C"), mat = Enum.Material.Fabric },
}

------------------------------------------------------------------ building helpers (firm-local)
local Build = {}
Build.__index = Build

local function newBuild(parent: Instance, frame: CFrame, name: string)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return setmetatable({ model = m, frame = frame }, Build)
end

-- axis-aligned box between two corners; solid = collides (structure), otherwise decoration
function Build:box(name: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number, look: string, solid: boolean?): Part
	local s = L[look]
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(math.max(0.05, math.abs(x1 - x0)), math.max(0.05, math.abs(y1 - y0)), math.max(0.05, math.abs(z1 - z0)))
	p.CFrame = self.frame * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Color = s.color
	p.Material = s.mat
	p.Transparency = s.t or 0
	p.CanCollide = solid ~= false
	p.CanQuery = solid ~= false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if s.mat == Enum.Material.Neon or s.mat == Enum.Material.Glass then
		p.CastShadow = false
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

function Build:tree(name: string, x: number, z: number, y: number, s: number)
	self:post(name .. "Trunk", x, z, y, y + 3 * s, 0.35 * s, "woodDark", false)
	local crown = self:box(name .. "Crown", x - 2 * s, y + 2.5 * s, z - 2 * s, x + 2 * s, y + 6 * s, z + 2 * s, "leaf", false)
	crown.Shape = Enum.PartType.Ball
	crown.Size = Vector3.new(4 * s, 4 * s, 4 * s)
end

function Build:planter(name: string, x0: number, z0: number, x1: number, z1: number, y: number, trees: number)
	self:box(name, x0, y, z0, x1, y + 1.2, z1, "concrete", false)
	self:box(name .. "Soil", x0 + 0.3, y + 1.2, z0 + 0.3, x1 - 0.3, y + 1.4, z1 - 0.3, "soil", false)
	for i = 1, trees do
		self:tree(name .. "Tree" .. i, x0 + (x1 - x0) * (i - 0.5) / trees, (z0 + z1) / 2, y + 1.4, 0.7)
	end
end

-- lobby shell shared by stages 2-6: side walls + back wall with the aisle opening, up to height h
local DEPTH = 21
function Build:shell(h: number, look: string)
	for _, s in { -1, 1 } do
		self:box("SideWall" .. s, s * 24 - 0.4, 0, 0, s * 24 + 0.4, h, DEPTH, look)
	end
	-- back wall: opening x -6..6 up to 9 (clients walk through to the offices)
	self:box("BackWallL", -24, 0, DEPTH - 0.6, -6, h, DEPTH, look)
	self:box("BackWallR", 6, 0, DEPTH - 0.6, 24, h, DEPTH, look)
	self:box("BackWallTop", -6, 9, DEPTH - 0.6, 6, h, DEPTH, look)
end

-- a floor slab across the front building (ceiling of the floor below)
function Build:floorPlate(name: string, y: number, look: string?, x: number?, z0: number?)
	local hw = x or 24.4
	self:box(name, -hw, y - 0.45, (z0 or 0) - 0.4, hw, y + 0.45, DEPTH + 0.4, look or "white")
end

-- a glass front between y0 and y1 with a door gap at x -3..3 when y0 is the ground
function Build:glassFront(name: string, y0: number, y1: number, look: string, door: boolean?, z: number?)
	local zz = z or 0
	if door then
		self:box(name .. "L", -24, y0, zz - 0.5, -3, y1, zz, look)
		self:box(name .. "R", 3, y0, zz - 0.5, 24, y1, zz, look)
		self:box(name .. "Top", -3, 7.5, zz - 0.5, 3, y1, zz, look)
	else
		self:box(name, -24, y0, zz - 0.5, 24, y1, zz, look)
	end
end

-- street-facing gallery: pedestals behind the glass (stage 3+). Pedestals are tagged so the Showcase
-- feature can stand the owner's best lawyers on them later.
function Build:showcase(y0: number, y1: number, count: number)
	self:glassFront("ShowcaseGlass", y0, y1, "clear")
	self:box("ShowcaseFloor", -22, y0, 0, 22, y0 + 0.3, 5.2, "marble")
	self:box("ShowcaseBack", -24, y0, 5.2, 24, y1, 5.6, "dark")
	for i = 1, count do
		local x = -22 + 44 * (i - 0.5) / count
		local ped = self:disc("ShowcasePedestal" .. i, x, 2.6, y0 + 0.3, 1.4, 1.4, "white")
		ped:SetAttribute("ShowcaseSlot", i)
		self:box("ShowcaseSpot" .. i, x - 0.5, y1 - 0.4, 2.1, x + 0.5, y1 - 0.1, 3.1, "warm", false)
	end
end

function Build:steps(look: string)
	-- visible porch + steps over FirmBuilder's invisible colliders (porch z -4.5..0, steps to -6)
	self:box("Porch", -11, -1.5, -4.5, 11, 0, 0, look)
	self:box("Step1", -11, -1.5, -5.25, 11, -0.5, -4.5, look)
	self:box("Step2", -11, -1.5, -6, 11, -1.0, -5.25, look)
end

------------------------------------------------------------------ the six fronts
-- each returns the CFrame (firm-local) for the name sign
local FRONTS: { [number]: (any) -> CFrame } = {}

-- 1. Dingy Shack: the game's own template, opened up so clients can walk through it
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
				-- back-wall planks in the middle come out: the aisle to the offices runs through here
				if l.Z > 11 and math.abs(l.X) < 3 and p.Size.Y > 4 then
					p:Destroy()
				-- side doorways (frame z 0.5..3.5): clients walk out to the benches along the waiting-room walls
				elseif math.abs(l.X) > 11 and l.Z > -9.2 and l.Z < -5.8 and p.Size.Y > 4 then
					p:Destroy()
				-- the shack's furniture in the middle of the floor would block the walk-in route
				elseif math.abs(l.X) < 5 and l.Z > -2 and l.Z < 8 and l.Y < 5 then
					p:Destroy()
				else
					p.CanCollide = p.Size.Y > 4 -- walls block, clutter doesn't
				end
			end
		end
		shack.Parent = b.model
	end
	b:steps("woodDark")
	return CFrame.new(0, 9.2, -3.4)
end

-- 2. Storefront Practice: one storey of brick, shop windows, awning, rooftop café
FRONTS[2] = function(b)
	local H = 9
	b:steps("stone")
	b:shell(H, "brick")
	for _, s in { -1, 1 } do
		local x0, x1 = 5 * s, 21 * s
		b:box("Sill" .. s, x0, 0, -0.5, x1, 0.7, 0, "brick")
		b:box("Shop" .. s, x0, 0.7, -0.4, x1, 6.7, 0, "window")
		b:box("ShopTop" .. s, x0, 6.7, -0.5, x1, H, 0, "brick")
		b:box("Pier" .. s, 21 * s, 0, -0.5, 24 * s, H, 0, "brick")
		b:box("DoorPier" .. s, 3 * s, 0, -0.5, 5 * s, H, 0, "brick")
	end
	b:box("DoorTop", -3, 7, -0.5, 3, H, 0, "brick")
	b:box("Cornice", -24.6, H - 0.2, -0.6, 24.6, H + 0.6, DEPTH + 0.6, "white")
	b:box("Roof", -24, H, 0, 24, H + 0.3, DEPTH, "roof")
	local awning = b:box("Awning", -23, 0, -2.5, 23, 0.35, 2.5, "awning", false)
	awning.CFrame = b.frame * CFrame.new(0, 7.8, -2.4) * CFrame.Angles(math.rad(18), 0, 0)
	for i, x in { -14, 0, 14 } do
		b:disc("CafeTable" .. i, x, 10, H + 0.6, 1.2, 0.2, "white", false)
		b:post("CafePole" .. i, x, 10, H + 0.6, H + 3.6, 0.1, "dark", false)
		b:disc("CafeUmbrella" .. i, x, 10, H + 3.6, 2.6, 0.3, "red", false)
	end
	return CFrame.new(0, 8.1, -0.75)
end

-- 3. Main Street Firm: cream stone ground floor, brick upper floor whose glass front is the Showcase (3)
FRONTS[3] = function(b)
	local G, H = 9, 18
	b:steps("stone")
	b:shell(H, "cream")
	for _, s in { -1, 1 } do
		b:box("GroundL" .. s, 3 * s, 0, -0.5, 24 * s, G, 0, "cream")
		for i, x in { 9, 15, 21 } do
			b:box(("Win%d_%d"):format(s, i), (x - 1.5) * s, 2, -0.7, (x + 1.5) * s, 7, -0.4, "window", false)
		end
		b:box("UpperSide" .. s, 24 * s, G, 0, (24 - 0.8) * s, H, DEPTH, "brick")
	end
	b:box("DoorTop", -3, 7.5, -0.5, 3, G, 0, "cream")
	b:floorPlate("Floor2", G, "white")
	b:showcase(G + 0.45, H, 3)
	b:box("UpperBand", -24, H - 1, -0.6, 24, H, 0, "brick")
	b:box("Cornice", -24.6, H - 0.2, -0.6, 24.6, H + 0.6, DEPTH + 0.6, "white")
	b:box("Roof", -24, H, 0, 24, H + 0.3, DEPTH, "roof")
	-- classic porch: four columns and an entablature with the sign
	for i, x in { -8, -3, 3, 8 } do
		b:post("Column" .. i, x, -4.5, 0, 9, 0.8, "white")
	end
	b:box("Entablature", -10, 9, -6, 10, 10.5, 0, "white")
	return CFrame.new(0, 9.75, -6.1)
end

-- 4. Glass Office: four glass floors — lobby, Showcase (6), Hatch Lab, Law Library
FRONTS[4] = function(b)
	local F = 9 -- floor height
	b:steps("concrete")
	b:shell(4 * F, "panel")
	b:glassFront("LobbyGlass", 0, F, "clear", true)
	b:box("ReceptionDesk", -18, 0, 17.5, -9, 3, 19.5, "wood") -- back corner, clear of the walk-in lanes
	b:floorPlate("Floor2", F)
	b:showcase(F + 0.45, 2 * F, 6)
	b:floorPlate("Floor3", 2 * F)
	b:glassFront("LabGlass", 2 * F + 0.45, 3 * F, "clear")
	b:disc("EggBase", 0, 9, 2 * F + 0.45, 4.5, 1.6, "panel")
	local egg = b:box("HatchLabEgg", -3, 2 * F + 2, 6, 3, 2 * F + 9.5, 12, "egg", false)
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(6.5, 6.5, 6.5)
	for i, x in { -16, 16 } do
		b:box("LabBench" .. i, x - 4, 2 * F + 0.45, 12, x + 4, 2 * F + 3.5, 16, "white")
	end
	b:floorPlate("Floor4", 3 * F)
	b:glassFront("LibraryGlass", 3 * F + 0.45, 4 * F, "clear")
	for i = 0, 5 do
		b:box("Shelf" .. i, -22 + i * 7.6, 3 * F + 0.45, 16, -17 + i * 7.6, 4 * F - 1, 20, "wood")
	end
	b:box("ConferenceTable", -8, 3 * F + 0.45, 6, 8, 3 * F + 2.5, 10, "wood")
	b:floorPlate("Roof", 4 * F, "roof")
	for _, s in { -1, 1 } do
		b:box("Fin" .. s, 24.6 * s, 0, -1.2, 24 * s, 4 * F + 1.5, 3, "white")
	end
	b:box("Canopy", -16, 8.5, -8, 16, 9.3, 0, "white")
	for _, s in { -1, 1 } do
		b:post("CanopyPost" .. s, 14 * s, -7, 0, 8.5, 0.35, "dark")
	end
	return CFrame.new(0, 4 * F + 1.5, -0.3)
end

-- 5. Corporate HQ: atrium with V-beams and a coffee bar, Showcase (9), Executive Lounge, stepped terraces,
-- roof garden with the Rooftop Hologram pad
FRONTS[5] = function(b)
	local F = 9
	b:steps("concrete")
	b:shell(4 * F, "white")
	b:glassFront("AtriumGlass", 0, 2 * F, "clear", true)
	-- coffee bar in the back corner, clear of the walk-in lanes
	b:box("CoffeeBar", -18, 0, 16.5, -8, 3.3, 19.5, "marble")
	b:box("CoffeeBarTop", -18.4, 3.3, 16.1, -7.6, 3.7, 19.9, "wood")
	-- two white Vs standing just in front of the atrium glass (decoration: nobody bumps into them)
	for i, beam in { { -12, -17 }, { -12, -7 }, { 12, 17 }, { 12, 7 } } do
		local bottom = b.frame * CFrame.new(beam[1], 0, -1.2)
		local top = b.frame * CFrame.new(beam[2], 2 * F, -1.2)
		local mid = bottom.Position:Lerp(top.Position, 0.5)
		local p = b:box("VBeam" .. i, 0, 0, 0, 1.4, 1, 1.4, "white", false)
		p.Size = Vector3.new(1.4, (top.Position - bottom.Position).Magnitude, 1.4)
		p.CFrame = CFrame.lookAt(mid, top.Position) * CFrame.Angles(math.rad(90), 0, 0)
	end
	b:box("BeamCap", -25, 2 * F - 0.6, -2, 25, 2 * F + 0.6, 0, "white")
	b:floorPlate("Floor3", 2 * F)
	b:showcase(2 * F + 0.45, 3 * F, 9)
	b:floorPlate("Floor4", 3 * F)
	b:glassFront("LoungeGlass", 3 * F + 0.45, 4 * F, "clear")
	b:box("LoungeCarpet", -24, 3 * F + 0.45, 0, 24, 3 * F + 0.6, DEPTH, "carpet")
	for i, x in { -16, 0, 16 } do
		b:box("Sofa" .. i, x - 5, 3 * F + 0.6, 10, x + 5, 3 * F + 2.3, 13, "suit")
		b:box("SofaBack" .. i, x - 5, 3 * F + 2.3, 12.4, x + 5, 3 * F + 3.9, 13, "suit")
	end
	b:box("LoungeGlow", -22, 3 * F + 1, 19.5, 22, 4 * F - 1, 20.3, "warm", false)
	b:floorPlate("Floor5", 4 * F)
	-- floors 5-6 step back 6 from the street; planted terrace in front
	b:box("UpperGlassFront", -21, 4 * F, 6, 21, 6 * F, 6.5, "glassdeep")
	for _, s in { -1, 1 } do
		b:box("UpperSide" .. s, 21 * s, 4 * F, 6, (21 - 0.6) * s, 6 * F, DEPTH, "glassdeep")
	end
	b:box("UpperBand", -21.3, 5 * F - 0.45, 5.6, 21.3, 5 * F + 0.45, DEPTH, "white")
	b:box("UpperRoof", -21.3, 6 * F - 0.45, 5.6, 21.3, 6 * F + 0.45, DEPTH, "wood")
	b:box("TerraceDeck", -24, 4 * F + 0.45, 0, 24, 4 * F + 0.8, 6, "wood")
	b:box("TerraceRail", -24, 4 * F + 0.8, -0.2, 24, 4 * F + 2.2, 0.2, "clear")
	for i, x in { -22, -8, 6 } do
		b:planter("TerracePlanter" .. i, x, 0.8, x + 12, 4.4, 4 * F + 0.8, 2)
	end
	for i, x in { -16, 16 } do
		b:tree("RoofTree" .. i, x, 13, 6 * F + 0.45, 1)
	end
	local pad = b:disc("HologramPad", 0, 13.5, 6 * F + 0.45, 4.5, 0.6, "white")
	pad:SetAttribute("Hologram", "Blue")
	b:box("HQSign", -14, 3 * F - 2.6, -0.6, 14, 3 * F - 0.4, -0.2, "gold", false)
	return CFrame.new(0, 3 * F - 1.5, -0.75)
end

-- 6. Supreme Tower (prestige): glass podium with Showcase (12), a 12-storey tower with gold bands,
-- a private-courtroom floor, the lit penthouse, a gold crown with a helipad and the gold Hologram pad
FRONTS[6] = function(b)
	local F = 9.6
	b:steps("marble")
	b:shell(2 * F, "stone")
	b:glassFront("LobbyGlass", 0, F, "clear", true)
	b:box("LobbyFloor", -24, 0, 0, 24, 0.15, DEPTH, "marble")
	b:floorPlate("Floor2", F, "gold")
	b:showcase(F + 0.45, 2 * F, 12)
	b:floorPlate("PodiumRoof", 2 * F, "gold")
	b:box("Canopy", -14, 8.6, -9, 14, 9.6, 0, "gold")
	for _, s in { -1, 1 } do
		b:post("CanopyColumn" .. s, 12 * s, -8, 0, 8.6, 0.6, "gold")
	end
	local T0, T1 = 2 * F + 0.45, 2 * F + 0.45 + 108
	b:box("Tower", -20, T0, 2, 20, T1, 19, "glassdeep")
	for k = 0, 12 do
		local y = T0 + (T1 - T0) * k / 12
		b:box("TowerBand" .. k, -20.4, y - 0.35, 1.6, 20.4, y + 0.35, 19.4, if k % 3 == 0 then "gold" else "dark")
	end
	for i = 0, 10 do
		local x = -20 + i * 4
		b:box("TowerMullion" .. i, x - 0.15, T0, 1.6, x + 0.15, T1, 2.1, "dark", false)
	end
	b:box("CourtroomFloor", -19.6, T0 + 45, 1.7, 19.6, T0 + 54, 2.2, "wood", false)
	b:box("PenthouseGlow", -19.6, T1 - 18, 1.7, 19.6, T1 - 0.4, 2.2, "warm", false)
	b:box("Crown", -18, T1, 3, 18, T1 + 5, 18, "gold")
	b:disc("Helipad", 9, 10.5, T1 + 5, 6.8, 0.8, "concrete")
	b:disc("HelipadRing", 9, 10.5, T1 + 5.8, 5.6, 0.2, "gold", false)
	local pad = b:disc("HologramPad", -9, 10.5, T1 + 5, 4.5, 0.6, "gold")
	pad:SetAttribute("Hologram", "Gold")
	b:post("Spire", -15, 15, T1 + 5, T1 + 31, 0.5, "gold", false)
	return CFrame.new(0, 2 * F - 1.8, -0.75)
end

------------------------------------------------------------------ the open office hall, restyled per stage
type HallStyle = { wall: string, cap: string, post: string, glass: boolean?, beams: boolean?, carpet: boolean? }
local HALL: { HallStyle } = {
	{ wall = "wood", cap = "woodDark", post = "woodDark" },
	{ wall = "brick", cap = "white", post = "brickdark" },
	{ wall = "cream", cap = "white", post = "white" },
	{ wall = "clear", cap = "white", post = "white", glass = true },
	{ wall = "clear", cap = "wood", post = "white", glass = true, beams = true },
	{ wall = "clear", cap = "gold", post = "gold", glass = true, carpet = true },
}

local function paint(p: BasePart, look: string)
	local s = L[look]
	p.Color = s.color
	p.Material = s.mat
	p.Transparency = s.t or 0
end

-- Restyle the kit's office-hall walls (picked out by shape: the 5-stud side panels, their cap rail and the
-- posts between segments) and add the stage's extras. The hall never gets a roof.
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
	if style.beams then
		-- open pergola beams across the hall: decoration only, nothing blocks the view from above
		local z = hallStart + 5.5
		while z < hallEnd - 2 do
			b:box("PergolaBeam", -24, 11.5, z - 0.3, 24, 12, z + 0.3, "white", false)
			for _, s in { -1, 1 } do
				b:post("PergolaPost", 24 * s, z, 5.5, 11.5, 0.3, "white", false)
			end
			z += 11
		end
	end
	if style.carpet then
		b:box("RedCarpet", -2.5, 0.02, hallStart, 2.5, 0.1, hallEnd - 1, "carpet", false)
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
