--!strict
-- SkinKit (ServerStorage.SkinKit): builds lawyer skin models in the game's block style (2026-10-10 model remakes).
-- Every SkinModel is Plastic blocks with smooth surfaces and a face made of flat blocks (white eye + black pupil +
-- shine, brow bar, dark mouth with a row of little teeth) - the remakes keep that style but give every character
-- its OWN shape and proportions (they used to share one 2.1 x 5.5 x 1.1 humanoid frame).
-- Model space: feet at y = 0, front (toward the client) = -Z, character's left = +X.
-- Part names follow Shared.Puppet: Head / UpperTorso / LeftUpperArm / RightUpperArm / LeftUpperLeg / RightUpperLeg
-- (+ "HeadDetail" for face bits; anything else is sorted by position). Side-on characters set Sideways = true.
-- tools/skins/<Id>.lua are the builders (run in Studio's command bar / MCP).

local Kit = {}
Kit.__index = Kit

Kit.C = {
	White = Color3.fromHex("f5f5f5"), Pupil = Color3.fromHex("0f0f12"), Line = Color3.fromHex("1c1c20"),
	Mouth = Color3.fromHex("5a1419"), Tongue = Color3.fromHex("d84a5a"), Gold = Color3.fromHex("ffc828"),
	GoldDark = Color3.fromHex("d99a10"), Skin = Color3.fromHex("ffcc99"),
}

export type Builder = typeof(setmetatable({} :: { model: Model, origin: Vector3, count: number }, Kit))

function Kit.new(name: string, origin: Vector3?): Builder
	local m = Instance.new("Model")
	m.Name = name
	return setmetatable({ model = m, origin = origin or Vector3.new(0, 500, 0), count = 0 }, Kit)
end

-- a block. rot in degrees (x, y, z), applied in that order. material / shape optional.
function Kit.B(self: Builder, name: string, size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	local r = rot or Vector3.zero
	p.CFrame = CFrame.new(self.origin + pos) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
	p.Parent = self.model
	self.count += 1
	return p
end

-- a block placed relative to another CFrame (for things hanging off rotated parts)
function Kit.BAt(self: Builder, name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material?): Part
	local p = self:B(name, size, Vector3.zero, color, nil, material)
	p.CFrame = CFrame.new(self.origin) * at
	return p
end

-- a wedge (for fins, ears, beaks, roofs): Roblox WedgePart, slope rises toward -Z by default
function Kit.W(self: Builder, name: string, size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = size
	p.Color = color
	local r = rot or Vector3.zero
	p.CFrame = CFrame.new(self.origin + pos) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
	p.Parent = self.model
	self.count += 1
	return p
end

-- the standard cartoon eye on a face plane. `normal` = the face's outward axis (Vector3.new(0,0,-1) for a front face).
-- size = eye width; look = pupil offset in the face plane (x right, y up), in eye widths.
function Kit.eye(self: Builder, center: Vector3, size: number, normal: Vector3, look: Vector2?, pupilColor: Color3?)
	local n = normal.Unit
	local right = Vector3.yAxis:Cross(n).Unit * -1 -- face-plane right (for a -Z face that's +X)
	if right.Magnitude ~= right.Magnitude then
		right = Vector3.xAxis
	end
	local up = n:Cross(right) * -1
	local l = look or Vector2.new(0, 0)
	local function at(offset: Vector3, depth: number): CFrame
		local pos = self.origin + center + offset + n * depth
		return CFrame.fromMatrix(pos, right, up, -n)
	end
	local e = self:BAt("HeadDetail", Vector3.new(size, size, 0.05), at(Vector3.zero, 0.0) - self.origin, Kit.C.White)
	local pupilOff = right * (l.X * size) + up * (l.Y * size)
	self:BAt("HeadDetail", Vector3.new(size * 0.48, size * 0.62, 0.04), at(pupilOff, 0.025) - self.origin, pupilColor or Kit.C.Pupil)
	self:BAt("HeadDetail", Vector3.new(size * 0.16, size * 0.16, 0.02), at(pupilOff + right * size * 0.1 + up * size * 0.16, 0.045) - self.origin, Kit.C.White)
	return e
end

-- a brow bar over an eye (tilt in degrees; positive raises the outer end)
function Kit.brow(self: Builder, center: Vector3, width: number, normal: Vector3, tilt: number, color: Color3?)
	local n = normal.Unit
	local right = Vector3.yAxis:Cross(n).Unit * -1
	local up = n:Cross(right) * -1
	local cf = CFrame.fromMatrix(self.origin + center, right, up, -n) * CFrame.Angles(0, 0, math.rad(tilt))
	return self:BAt("HeadDetail", Vector3.new(width, width * 0.2, 0.05), cf - self.origin, color or Kit.C.Line)
end

-- a mouth: dark bar with a row of little white teeth along its top edge (teeth = 0 for none); smile bends the ends up
function Kit.mouth(self: Builder, center: Vector3, width: number, height: number, normal: Vector3, teeth: number?, smile: number?)
	local n = normal.Unit
	local right = Vector3.yAxis:Cross(n).Unit * -1
	local up = n:Cross(right) * -1
	local base = CFrame.fromMatrix(self.origin + center, right, up, -n)
	self:BAt("HeadDetail", Vector3.new(width, height, 0.05), base - self.origin, Kit.C.Mouth)
	local s = smile or 0
	if s ~= 0 then
		for _, side in { -1, 1 } do
			local cf = base * CFrame.new(side * (width / 2 + height * 0.35), height * 0.35, 0) * CFrame.Angles(0, 0, math.rad(side * s))
			self:BAt("HeadDetail", Vector3.new(height * 1.2, height * 0.8, 0.05), cf - self.origin, Kit.C.Mouth)
		end
	end
	local t = teeth or 0
	for i = 1, t do
		local x = -width / 2 + width * (i - 0.5) / t
		local cf = base * CFrame.new(x, height / 2 - height * 0.28, -0.03)
		self:BAt("HeadDetail", Vector3.new(math.min(width / t * 0.6, 0.12), height * 0.5, 0.03), cf - self.origin, Kit.C.White)
	end
end

-- install as ReplicatedStorage.SkinModels.<Id>: the old model is kept in ServerStorage.RetiredSkinModels.<Id>_v1,
-- the new one gets its pivot at the feet (origin) and an attribute saying what it is.
function Kit.install(self: Builder, id: string, note: string, sideways: boolean?)
	local skins = game:GetService("ReplicatedStorage").SkinModels
	local retired = game:GetService("ServerStorage"):FindFirstChild("RetiredSkinModels") or Instance.new("Folder")
	retired.Name = "RetiredSkinModels"
	retired.Parent = game:GetService("ServerStorage")
	local old = skins:FindFirstChild(id)
	if old then
		if not retired:FindFirstChild(id .. "_v1") then
			old.Name = id .. "_v1"
			old.Parent = retired
		else
			old:Destroy()
		end
	end
	local m = self.model
	m.Name = id
	local box, size = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0))
	m:PivotTo(CFrame.new())
	m:SetAttribute("Remade", "2026-10-10 block remake: " .. note)
	if sideways then
		m:SetAttribute("Sideways", true)
	end
	if (self :: any).hover then
		m:SetAttribute("Hover", (self :: any).hover) -- SkinLook lifts flying lawyers this far off the floor
	end
	m.Parent = skins
	return m
end

-- a preview stage: the model at the stage origin on a light floor, plus the Rookie (a standard person) for scale
function Kit.preview(self: Builder)
	local stage = workspace:FindFirstChild("_ModelStage") or Instance.new("Folder")
	stage.Name = "_ModelStage"
	stage.Parent = workspace
	stage:ClearAllChildren()
	self.model.Parent = stage
	local floor = Instance.new("Part")
	floor.Anchored = true
	floor.Size = Vector3.new(24, 1, 16)
	floor.Position = self.origin - Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(225, 228, 235)
	floor.Parent = stage
	local rookie = game:GetService("ReplicatedStorage").SkinModels:FindFirstChild("Rookie")
	if rookie then
		local r = rookie:Clone()
		r.Name = "_ScaleRef"
		local b, s = r:GetBoundingBox()
		r:PivotTo(r:GetPivot() + (self.origin + Vector3.new(-5, s.Y / 2, 2.5) - b.Position))
		r.Parent = stage
	end
	local _, size = self.model:GetBoundingBox()
	return string.format("%d parts, size %.2f x %.2f x %.2f", self.count, size.X, size.Y, size.Z)
end

return Kit
