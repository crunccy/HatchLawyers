--!strict
-- ClientKit (ServerStorage.ClientKit): builds the client characters, v3 (2026-10-10 client remodel).
-- Style: recognisable Roblox block proportions (R6-like: torso 2 wide-ish, arms + legs half that), every block
-- rounded with real CSG geometry (no hard box edges), clothing built in layers (collars, plackets, pockets, belts,
-- cuffs, socks, soles), CSG hair caps shaped to the head with fringes/buns/spikes, a drawn face decal
-- (tools/client_faces.py) on a face plate, SmoothPlastic everywhere (matte, not shiny).
-- Model space: feet at y = 0, the character faces -Z, +X is the character's LEFT (screen right when facing you).
-- Part names follow Shared.Puppet so ClientWalk / DeskLife / the courtroom can pose them: Head (the head itself,
-- the case bar adorns it), HeadDetail (face, hair, hats), UpperTorso, Left/RightUpperArm, Left/RightUpperLeg,
-- HumanoidRootPart (invisible, the PrimaryPart/pivot). Puppet sorts limbs by position, so a part only has to sit
-- where it belongs.
-- tools/clients/<Id>.lua are the builders: local k = Kit.new("<Id>"); k:body({...}); ...; k:finish()

local Kit = {}
Kit.__index = Kit

local V = Vector3.new
local SMOOTH = Enum.Material.SmoothPlastic

-- standard body (studs). Feet at 0.
Kit.D = {
	legW = 0.8, legD = 0.86, legH = 1.85, legGap = 0.06,
	torsoW = 1.72, torsoH = 1.85, torsoD = 0.98,
	armW = 0.64, armD = 0.76, armH = 1.82, armGap = 0.03,
	headW = 1.42, headH = 1.34, headD = 1.26, neck = 0.04,
}
local D = Kit.D
Kit.hipY = D.legH
Kit.shoulderY = D.legH + D.torsoH
Kit.headY = D.legH + D.torsoH + D.neck + D.headH / 2
Kit.armX = D.torsoW / 2 + D.armGap + D.armW / 2
Kit.legX = (D.legW + D.legGap) / 2

function Kit.hex(h: string): Color3
	return Color3.fromHex(h)
end

function Kit.new(id: string, origin: Vector3?)
	local m = Instance.new("Model")
	m.Name = id
	return setmetatable({ model = m, id = id, origin = origin or V(0, 500, 0), count = 0, temp = {} }, Kit)
end

------------------------------------------------------------------ raw parts
local function raw(shape: Enum.PartType, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	return p
end

function Kit:_world(cf: CFrame): CFrame
	return CFrame.new(self.origin) * cf
end

function Kit:_dress(p: BasePart, name: string, color: Color3): BasePart
	p.Name = name
	p.Color = color
	p.Material = SMOOTH
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if p:IsA("UnionOperation") then
		p.UsePartColor = true
		p.SmoothingAngle = 40
		p.CollisionFidelity = Enum.CollisionFidelity.Box
	end
	p.Parent = self.model
	self.count += 1
	return p
end

local function cfOf(pos: Vector3 | CFrame, rot: Vector3?): CFrame
	local base = if typeof(pos) == "CFrame" then pos else CFrame.new(pos)
	local r = rot or Vector3.zero
	return base * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
end
Kit.cf = cfOf

-- the pieces of a rounded box (3 slabs + 12 edge cylinders + 8 corner balls), in world space
local function roundedPieces(size: Vector3, r: number, cf: CFrame): { Part }
	r = math.min(r, size.X / 2 - 0.005, size.Y / 2 - 0.005, size.Z / 2 - 0.005)
	local sx, sy, sz = size.X, size.Y, size.Z
	local list = {
		raw(Enum.PartType.Block, V(sx, sy - 2 * r, sz - 2 * r), cf),
		raw(Enum.PartType.Block, V(sx - 2 * r, sy, sz - 2 * r), cf),
		raw(Enum.PartType.Block, V(sx - 2 * r, sy - 2 * r, sz), cf),
	}
	local hx, hy, hz = sx / 2 - r, sy / 2 - r, sz / 2 - r
	for _, a in { -1, 1 } do
		for _, b in { -1, 1 } do
			table.insert(list, raw(Enum.PartType.Cylinder, V(sx - 2 * r, 2 * r, 2 * r), cf * CFrame.new(0, a * hy, b * hz)))
			table.insert(list, raw(Enum.PartType.Cylinder, V(sy - 2 * r, 2 * r, 2 * r), cf * CFrame.new(a * hx, 0, b * hz) * CFrame.Angles(0, 0, math.pi / 2)))
			table.insert(list, raw(Enum.PartType.Cylinder, V(sz - 2 * r, 2 * r, 2 * r), cf * CFrame.new(a * hx, b * hy, 0) * CFrame.Angles(0, math.pi / 2, 0)))
			for _, c in { -1, 1 } do
				table.insert(list, raw(Enum.PartType.Ball, V(2 * r, 2 * r, 2 * r), cf * CFrame.new(a * hx, b * hy, c * hz)))
			end
		end
	end
	return list
end

local function unionOf(list: { BasePart }): UnionOperation
	local first = table.remove(list, 1) :: BasePart
	first.Parent = workspace
	for _, p in list do
		p.Parent = workspace
	end
	local u = first:UnionAsync(list)
	first:Destroy()
	for _, p in list do
		p:Destroy()
	end
	return u
end
Kit.unionOf = unionOf

------------------------------------------------------------------ shapes (model space)
-- rounded box. pos = Vector3 or CFrame (model space), rot degrees.
function Kit:rbox(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, r: number?, rot: Vector3?): BasePart
	local cf = self:_world(cfOf(pos, rot))
	local rr = r or 0.12
	if rr < 0.02 then
		return self:_dress(raw(Enum.PartType.Block, size, cf), name, color)
	end
	local u = unionOf(roundedPieces(size, rr, cf))
	return self:_dress(u, name, color)
end

-- a plain block / wedge / cylinder / ball (cylinder axis = X)
function Kit:block(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	return self:_dress(raw(Enum.PartType.Block, size, self:_world(cfOf(pos, rot))), name, color)
end
function Kit:wedge(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	local w = Instance.new("WedgePart")
	w.Size = size
	w.CFrame = self:_world(cfOf(pos, rot))
	return self:_dress(w, name, color)
end
function Kit:cyl(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	return self:_dress(raw(Enum.PartType.Cylinder, size, self:_world(cfOf(pos, rot))), name, color)
end
function Kit:ball(name: string, d: number, pos: Vector3 | CFrame, color: Color3): BasePart
	return self:_dress(raw(Enum.PartType.Ball, V(d, d, d), self:_world(cfOf(pos))), name, color)
end
-- ellipsoid of any size (a CSG ball, resized)
function Kit:ell(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	local cf = self:_world(cfOf(pos, rot))
	local u = unionOf({ raw(Enum.PartType.Ball, V(2, 2, 2), cf), raw(Enum.PartType.Ball, V(1, 1, 1), cf) })
	u.Size = size
	u.CFrame = cf
	return self:_dress(u, name, color)
end
-- the top half of an ellipsoid (domes: caps, hair buns, bellies). size = full ellipsoid size; flat side down
function Kit:dome(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	local cf = self:_world(cfOf(pos, rot))
	local ball = raw(Enum.PartType.Ball, V(2, 2, 2), CFrame.new())
	ball.Parent = workspace
	local cut = raw(Enum.PartType.Block, V(3, 1.5, 3), CFrame.new(0, -0.75, 0))
	cut.Parent = workspace
	local u = ball:SubtractAsync({ cut })
	ball:Destroy()
	cut:Destroy()
	u.Size = V(size.X, size.Y / 2, size.Z)
	u.CFrame = cf * CFrame.new(0, size.Y / 4, 0)
	return self:_dress(u, name, color)
end
-- a rounded box with pieces cut away (cutters: { {size, pos(model space), rot?} }) - V-necks, hair hairlines
function Kit:carve(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, r: number, cutters: { any }, rot: Vector3?): BasePart
	if #cutters == 0 then
		return self:rbox(name, size, pos, color, r, rot)
	end
	local cf = self:_world(cfOf(pos, rot))
	local base = unionOf(roundedPieces(size, r, cf))
	base.Parent = workspace
	local cuts = {}
	for _, c in cutters do
		local p = raw(Enum.PartType.Block, c[1], self:_world(cfOf(c[2], c[3])))
		p.Parent = workspace
		table.insert(cuts, p)
	end
	local u = base:SubtractAsync(cuts)
	base:Destroy()
	for _, p in cuts do
		p:Destroy()
	end
	return self:_dress(u, name, color)
end
-- several shapes fused into one smooth piece. pieces: list of { "rbox"|"ball"|"cyl"|"block"|"wedge", size, pos, rot?, r? }
function Kit:fuse(name: string, color: Color3, pieces: { any }): BasePart
	local list = {}
	for _, pc in pieces do
		local kind, size, pos, rot, r = pc[1], pc[2], pc[3], pc[4], pc[5]
		local cf = self:_world(cfOf(pos, rot))
		if kind == "rbox" then
			local u = unionOf(roundedPieces(size, r or 0.12, cf))
			table.insert(list, u)
		elseif kind == "ball" then
			table.insert(list, raw(Enum.PartType.Ball, size, cf))
		elseif kind == "cyl" then
			table.insert(list, raw(Enum.PartType.Cylinder, size, cf))
		elseif kind == "wedge" then
			local w = Instance.new("WedgePart")
			w.Size = size
			w.CFrame = cf
			w.Anchored = true
			table.insert(list, w)
		else
			table.insert(list, raw(Enum.PartType.Block, size, cf))
		end
	end
	if #list == 1 then
		local only = list[1]
		return self:_dress(only, name, color)
	end
	return self:_dress(unionOf(list), name, color)
end

------------------------------------------------------------------ the body
-- opts: skin, shirt, pants, shoes, sole, sleeves = "long"|"short"|"none", legs = "long"|"shorts"|"skirt",
-- socks (colour, for shorts/skirts), cuff (sleeve cuff colour), hands (glove colour), torsoD (belly depth)
function Kit:body(o: { [string]: any })
	local skin, shirt = o.skin, o.shirt
	local pants, shoes, sole = o.pants or shirt, o.shoes or Kit.hex("2b2b33"), o.sole or Kit.hex("f2f2f2")
	local hands = o.hands or skin
	self.skin = skin
	local hipY, shY = Kit.hipY, Kit.shoulderY
	-- legs + shoes
	for _, s in { -1, 1 } do
		local x = s * Kit.legX
		local leg = if s < 0 then "RightUpperLeg" else "LeftUpperLeg"
		local legsStyle = o.legs or "long"
		if legsStyle == "long" then
			self:rbox(leg, V(D.legW, D.legH - 0.25, D.legD), V(x, 0.25 + (D.legH - 0.25) / 2, 0), pants, 0.14)
		elseif legsStyle == "shorts" or legsStyle == "skirt" then
			local top = if legsStyle == "shorts" then 0.85 else 0.0
			if legsStyle == "shorts" then
				self:rbox(leg, V(D.legW + 0.04, top, D.legD + 0.04), V(x, hipY - top / 2, 0), pants, 0.14)
			end
			local bareTop = hipY - top
			local sockH = o.sockH or (if o.socks then 0.75 else 0)
			if bareTop - 0.3 - sockH > 0.02 then
				self:rbox(leg, V(D.legW - 0.12, bareTop - 0.25 - sockH + 0.05, D.legD - 0.12), V(x, 0.25 + sockH + (bareTop - 0.25 - sockH) / 2, 0), skin, 0.14)
			end
			if o.socks then
				self:rbox(leg, V(D.legW - 0.08, sockH + 0.05, D.legD - 0.08), V(x, 0.25 + sockH / 2, 0), o.socks, 0.12)
			end
		end
		if o.sandals then
			-- sandals: the (socked) foot shows, a thick sole and two straps across it
			self:rbox(leg, V(D.legW - 0.04, 0.3, D.legD + 0.2), V(x, 0.27, -0.12), o.socks or skin, 0.13)
			self:rbox(leg, V(D.legW + 0.06, 0.16, D.legD + 0.3), V(x, 0.08, -0.13), shoes, 0.06)
			for _, z in { -0.42, -0.08 } do
				self:rbox(leg, V(D.legW + 0.0, 0.1, 0.14), V(x, 0.37, z), shoes, 0.04)
			end
		else
			-- shoe: rounded upper + contrasting sole, toe a little forward
			self:rbox(leg, V(D.legW + 0.06, 0.36, D.legD + 0.28), V(x, 0.2, -0.13), shoes, 0.15)
			self:rbox(leg, V(D.legW + 0.1, 0.1, D.legD + 0.32), V(x, 0.05, -0.13), sole, 0.04)
		end
	end
	if o.legs == "skirt" then
		-- a waist layer and a wider hem layer (skirtLen 1.0 = knee, 1.75 = floor-length gown)
		local L, fl = o.skirtLen or 1.05, o.flare or 0.22
		local top = hipY + 0.25
		self:rbox("UpperTorso", V(D.torsoW + 0.12, L * 0.55, D.torsoD + 0.14), V(0, top - L * 0.275, 0), pants, 0.16)
		self:rbox("UpperTorso", V(D.torsoW + 0.12 + fl, L * 0.5, D.torsoD + 0.14 + fl), V(0, top - L * 0.75, 0), pants, 0.18)
	end
	-- torso
	local td = o.torsoD or D.torsoD
	self.td = td
	self.torso = self:rbox("UpperTorso", V(D.torsoW, D.torsoH, td), V(0, hipY + D.torsoH / 2, 0), shirt, 0.22)
	-- arms: sleeve + forearm/hand
	for _, s in { -1, 1 } do
		local x = s * Kit.armX
		local arm = if s < 0 then "RightUpperArm" else "LeftUpperArm"
		local sl = o.sleeves or "long"
		local handH = 0.46
		if sl == "long" then
			self:rbox(arm, V(D.armW, D.armH - handH + 0.06, D.armD), V(x, shY - (D.armH - handH + 0.06) / 2, 0), shirt, 0.16)
			if o.cuff then
				self:rbox(arm, V(D.armW + 0.04, 0.16, D.armD + 0.04), V(x, shY - D.armH + handH + 0.04, 0), o.cuff, 0.06)
			end
		else
			local sleeveH = if sl == "short" then 0.62 else 0.0
			if sleeveH > 0 then
				self:rbox(arm, V(D.armW + 0.06, sleeveH, D.armD + 0.06), V(x, shY - sleeveH / 2, 0), shirt, 0.16)
				if o.cuff then
					self:rbox(arm, V(D.armW + 0.08, 0.12, D.armD + 0.08), V(x, shY - sleeveH + 0.06, 0), o.cuff, 0.05)
				end
			end
			local bare = D.armH - sleeveH - handH + 0.04
			self:rbox(arm, V(D.armW - 0.08, bare, D.armD - 0.08), V(x, shY - sleeveH - bare / 2 + 0.02, 0), skin, 0.14)
		end
		self:rbox(arm, V(D.armW - 0.02, handH, D.armD - 0.04), V(x, shY - D.armH + handH / 2, 0), hands, 0.16)
	end
	-- head
	self.head = self:rbox("Head", V(D.headW, D.headH, D.headD), V(0, Kit.headY, 0), skin, 0.3)
	return self
end

-- the drawn face (tools/client_faces.py): a 1.3 x 1.2 plate just in front of the head
function Kit:face(textureId: string)
	local plate = self:block("HeadDetail", V(1.3, 1.2, 0.04), V(0, Kit.headY - 0.02, -D.headD / 2 - 0.025), Color3.new(1, 1, 1))
	plate.Transparency = 1
	plate.Name = "FacePlate"
	local d = Instance.new("Decal")
	d.Name = "Face"
	d.Texture = textureId
	d.Face = Enum.NormalId.Front
	d.Parent = plate
	return plate
end

-- hair: a shell hugging the head, cut at the hairline (front) and the nape (back). o: color, top (height above
-- the head), front (hairline height above the eyes, studs from the head centre), back (nape height), sides
-- (sideburn length below the hairline), puff (extra size)
function Kit:hair(o: { [string]: any }): BasePart
	local c = o.color
	local puff = o.puff or 0.1
	local top = o.top or 0.22
	if o.hat then -- under a cap / beanie / helmet: keep the hair below the hat line so it can't poke through
		top = math.min(top, -0.1)
		puff = math.min(puff, 0.07)
	end
	local size = V(D.headW + puff * 2, D.headH + top + 0.02, D.headD + puff * 2)
	local cy = Kit.headY + top / 2 + 0.01
	local hairline = Kit.headY + (o.front or 0.36) -- world-ish Y (model space) of the fringe edge
	local nape = Kit.headY + (o.back or -0.35)
	local sides = o.sides or 0.3
	local ear = o.ear or -0.3 -- how far forward (z) the sideburns reach; the front of each side is the cheek
	local cutters = {
		-- face: everything in front of the face plane below the hairline
		{ V(D.headW - 0.14, 3, 1.2), V(0, hairline - 1.5, -D.headD / 2 - 0.5) },
		-- cheeks: the front strip of each side below the hairline (so the hair doesn't wrap the face like a box)
		{ V(D.headW + 1, 3, 1.0), V(0, hairline + 0.02 - 1.5, ear - 0.5) },
		-- below the sideburns
		{ V(D.headW + 1, 3, 1.4), V(0, hairline - sides - 1.5, 0.15 - 0.7) },
		-- the neck/back below the nape
		{ V(D.headW + 1, 3, D.headD + 1), V(0, nape - 1.5, 0.2) },
	}
	return self:carve("Hair", size, V(0, cy, 0.02), c, o.r or 0.36, cutters)
end

------------------------------------------------------------------ outfit pieces (call after body)
-- front surface of the torso (z), and where a hand is: side -1 = the character's right (screen left)
function Kit:frontZ(extra: number?): number
	return -(self.td or D.torsoD) / 2 - (extra or 0)
end
function Kit:hand(side: number): Vector3
	return V(side * Kit.armX, Kit.shoulderY - D.armH + 0.24, 0)
end
local function armName(side: number): string
	return if side < 0 then "RightUpperArm" else "LeftUpperArm"
end
Kit.armName = armName

-- shirt collar: two flaps folded down + a band round the neck
function Kit:collar(color: Color3, spread: number?)
	local sh, z = Kit.shoulderY, self:frontZ()
	local sp = spread or 18
	for _, s in { -1, 1 } do
		self:rbox("UpperTorso", V(0.46, 0.1, 0.34), V(s * 0.22, sh - 0.03, z + 0.12), color, 0.04, V(-25, s * -sp, s * 12))
	end
	self:rbox("UpperTorso", V(0.98, 0.13, 0.86), V(0, sh, 0.04), color, 0.06)
end

-- a V of shirt at the neck of a jacket / cardigan: a shirt panel with two jacket-coloured lapels over it
function Kit:lapels(jacket: Color3, shirt: Color3, opts: { [string]: any }?)
	local o = opts or {}
	local sh, z = Kit.shoulderY, self:frontZ(0.012)
	local dp, wd = o.depth or 0.9, o.width or 0.7
	self:rbox("UpperTorso", V(wd, dp, 0.05), V(0, sh - dp / 2, z), shirt, 0.03)
	local ang = math.deg(math.atan2(wd / 2, dp))
	for _, s in { -1, 1 } do
		-- each lapel covers the outer part of the panel, leaving a V
		self:rbox("UpperTorso", V(0.3, dp + 0.18, 0.07), V(s * (wd / 2 - 0.08), sh - dp / 2 - 0.02, z - 0.02), o.lapel or jacket, 0.03, V(0, 0, s * ang))
	end
end

function Kit:tie(color: Color3, length: number?)
	local sh, z = Kit.shoulderY, self:frontZ(0.06)
	local L = length or 0.78
	self:rbox("UpperTorso", V(0.2, 0.15, 0.08), V(0, sh - 0.12, z), color, 0.04)
	self:rbox("UpperTorso", V(0.17, L, 0.05), V(0, sh - 0.2 - L / 2, z + 0.01), color, 0.04)
	self:rbox("UpperTorso", V(0.13, 0.13, 0.05), V(0, sh - 0.2 - L, z + 0.01), color, 0.03, V(0, 0, 45))
end
function Kit:bowtie(color: Color3, y: number?)
	local yy, z = y or (Kit.shoulderY - 0.12), self:frontZ(0.06)
	for _, s in { -1, 1 } do
		self:fuse("UpperTorso", color, { { "wedge", V(0.06, 0.22, 0.2), V(s * 0.12, yy, z), V(0, s * 90, 0) } })
	end
	self:ell("UpperTorso", V(0.12, 0.12, 0.08), V(0, yy, z - 0.02), color)
end
function Kit:buttons(n: number, color: Color3, x: number?, yTop: number?, dy: number?)
	local y0, z = yTop or (Kit.shoulderY - 0.3), self:frontZ(0.03)
	for i = 0, n - 1 do
		self:cyl("UpperTorso", V(0.05, 0.1, 0.1), V(x or 0, y0 - i * (dy or 0.28), z), color, V(0, 90, 0))
	end
end
function Kit:belt(color: Color3, buckle: Color3?)
	local hip = Kit.hipY
	self:rbox("UpperTorso", V(D.torsoW + 0.05, 0.17, (self.td or D.torsoD) + 0.05), V(0, hip + 0.07, 0), color, 0.07)
	if buckle then
		self:rbox("UpperTorso", V(0.26, 0.2, 0.06), V(0, hip + 0.07, self:frontZ(0.04)), buckle, 0.04)
	end
end
-- apron over the front (bib + skirt), with ties at the back
function Kit:apron(color: Color3, opts: { [string]: any }?)
	local o = opts or {}
	local sh, hip, z = Kit.shoulderY, Kit.hipY, self:frontZ(0.02)
	local bib = o.bib ~= false
	if bib then
		self:rbox("UpperTorso", V(0.95, 0.85, 0.05), V(0, sh - 0.65, z), color, 0.04)
		for _, s in { -1, 1 } do
			self:rbox("UpperTorso", V(0.1, 0.5, 0.05), V(s * 0.42, sh - 0.12, z + 0.01), color, 0.03, V(0, 0, s * 12))
		end
	end
	self:rbox("UpperTorso", V(1.3, o.length or 1.1, 0.05), V(0, hip + 0.2 - (o.length or 1.1) / 2 + 0.25, z), color, 0.05)
	self:rbox("UpperTorso", V(D.torsoW + 0.03, 0.1, (self.td or D.torsoD) + 0.03), V(0, hip + 0.32, 0), o.tie or color, 0.04)
	if o.pocket then
		self:rbox("UpperTorso", V(0.5, 0.3, 0.06), V(0, hip - 0.15, z - 0.03), o.pocket, 0.03)
	end
end
-- coat skirt hanging below the waist (long coats / robes / lab coats). split = open at the front
function Kit:coatSkirt(color: Color3, length: number, split: boolean?, flare: number?)
	local hip = Kit.hipY
	local td = (self.td or D.torsoD)
	local f = flare or 0.08
	if split then
		for _, s in { -1, 1 } do
			self:rbox("UpperTorso", V(D.torsoW / 2 + f, length, td + f * 2), V(s * (D.torsoW / 4 + f / 2 + 0.02), hip - length / 2 + 0.15, 0), color, 0.08)
		end
	else
		self:rbox("UpperTorso", V(D.torsoW + f * 2, length, td + f * 2), V(0, hip - length / 2 + 0.15, 0), color, 0.1)
	end
end
-- a ring (glasses frames, hoops): a cylinder with its middle cut out. Axis = Z (faces the camera)
function Kit:ring(name: string, outer: number, inner: number, thick: number, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	local cf = self:_world(cfOf(pos, rot)) * CFrame.Angles(0, math.pi / 2, 0)
	local base = raw(Enum.PartType.Cylinder, V(thick, outer, outer), cf)
	base.Parent = workspace
	local hole = raw(Enum.PartType.Cylinder, V(thick + 0.1, inner, inner), cf)
	hole.Parent = workspace
	local u = base:SubtractAsync({ hole })
	base:Destroy()
	hole:Destroy()
	return self:_dress(u, name, color)
end
-- glasses over the face plate's eyes: "round" | "square" | "shades"
function Kit:glasses(style: string, color: Color3, lens: Color3?)
	local y, z = Kit.headY - 0.02 + 0.07, -D.headD / 2 - 0.07
	for _, s in { -1, 1 } do
		if style == "round" then
			self:ring("HeadDetail", 0.4, 0.32, 0.05, V(s * 0.29, y, z), color)
		elseif style == "square" then
			self:carve("HeadDetail", V(0.42, 0.36, 0.05), V(s * 0.29, y, z), color, 0.06, { { V(0.33, 0.27, 0.3), V(s * 0.29, y, z) } })
		else
			self:rbox("HeadDetail", V(0.46, 0.3, 0.06), V(s * 0.28, y, z), lens or color, 0.1)
		end
		self:rbox("HeadDetail", V(0.05, 0.05, 0.6), V(s * 0.66, y + 0.04, z + 0.33), color, 0.02) -- arms
	end
	self:rbox("HeadDetail", V(0.16, 0.05, 0.05), V(0, y + 0.04, z), color, 0.02) -- bridge
end
-- beard under the mouth (the face decal's mouth stays visible above it)
function Kit:beard(color: Color3, length: number?, wide: boolean?)
	local L = length or 0.55
	local top = Kit.headY - 0.44
	local w = if wide then D.headW + 0.08 else D.headW - 0.1
	self:rbox("HeadDetail", V(w, L, 0.5), V(0, top - L / 2 + 0.06, -D.headD / 2 + 0.2), color, 0.2)
	for _, s in { -1, 1 } do -- up the jaw to the sideburns
		self:rbox("HeadDetail", V(0.2, 0.6, 0.7), V(s * (D.headW / 2 - 0.04), Kit.headY - 0.3, -0.2), color, 0.08)
	end
end

------------------------------------------------------------------ hair styles
-- style: "short" | "side" | "spiky" | "swoop" | "long" | "bob" | "ponytail" | "bun" | "afro" | "curly" | "tufts" |
-- "mohawk" | "pigtails" | "messy". o = overrides passed to Kit:hair (front, back, sides, top, puff)
function Kit:hairStyle(style: string, color: Color3, o: { [string]: any }?)
	o = o or {}
	local hy, top = Kit.headY, Kit.headY + D.headH / 2
	local function base(extra: { [string]: any })
		local t = { color = color }
		for k2, v in extra do
			t[k2] = v
		end
		for k2, v in o :: any do
			t[k2] = v
		end
		return self:hair(t)
	end
	if style == "short" then
		base({ top = 0.12, front = 0.36, back = -0.38, sides = 0.32 })
	elseif style == "side" then
		base({ top = 0.14, front = 0.34, back = -0.38, sides = 0.3 })
		self:rbox("HeadDetail", V(0.95, 0.26, 0.5), V(0.18, top + 0.06, -0.42), color, 0.12, V(0, 0, -8)) -- side-swept fringe
	elseif style == "spiky" then
		base({ top = 0.1, front = 0.38, back = -0.36, sides = 0.3 })
		for i, sp in { { -0.45, -0.3, 20 }, { -0.15, -0.35, 5 }, { 0.15, -0.35, -5 }, { 0.45, -0.3, -20 }, { -0.3, 0.15, 12 }, { 0.3, 0.15, -12 }, { 0, 0.3, 0 } } do
			self:fuse("HeadDetail", color, { { "wedge", V(0.3, 0.42, 0.4), V(sp[1], top + 0.26, sp[2]), V(0, 0, sp[3]) } })
		end
	elseif style == "swoop" then -- tall pompadour
		base({ top = 0.12, front = 0.38, back = -0.38, sides = 0.3 })
		self:rbox("HeadDetail", V(1.2, 0.42, 0.7), V(0, top + 0.22, -0.3), color, 0.2, V(-18, 0, 0))
	elseif style == "messy" then
		base({ top = 0.16, front = 0.3, back = -0.4, sides = 0.34 })
		for _, sp in { { -0.4, -0.45, 30 }, { -0.05, -0.5, -10 }, { 0.35, -0.45, -30 }, { 0.5, 0.1, -50 }, { -0.5, 0.1, 50 } } do
			self:rbox("HeadDetail", V(0.32, 0.36, 0.3), V(sp[1], top + 0.06, sp[2]), color, 0.12, V(sp[3] * 0.3, 0, sp[3]))
		end
	elseif style == "long" then
		base({ top = 0.14, front = 0.36, back = -1.2, sides = 0.9, puff = 0.1 })
		self:rbox("HeadDetail", V(D.headW + 0.24, 1.15, 0.36), V(0, hy - 0.62, 0.55), color, 0.16) -- hair down the back
	elseif style == "bob" then
		base({ top = 0.14, front = 0.3, back = -0.62, sides = 0.78, puff = 0.12 })
	elseif style == "ponytail" or style == "pigtails" then
		base({ top = 0.12, front = 0.36, back = -0.36, sides = 0.3 })
		local tails = if style == "ponytail" then { V(0, top - 0.1, 0.78) } else { V(-0.82, hy + 0.1, 0.2), V(0.82, hy + 0.1, 0.2) }
		for _, p in tails do
			self:ell("HeadDetail", V(0.2, 0.2, 0.2), p, o.tie or Kit.hex("e04f6a"))
			self:rbox("HeadDetail", V(0.42, 0.95, 0.4), p + V(0, -0.5, if style == "ponytail" then 0.1 else 0), color, 0.18, V(if style == "ponytail" then 10 else 0, 0, 0))
		end
	elseif style == "bun" then
		base({ top = 0.12, front = 0.36, back = -0.36, sides = 0.3 })
		self:ell("HeadDetail", V(0.62, 0.55, 0.62), V(0, top + 0.28, 0.12), color)
	elseif style == "afro" then
		self:fuse("Hair", color, {
			{ "ball", V(2.0, 2.0, 2.0), V(0, top - 0.05, 0.12) },
			{ "ball", V(1.4, 1.4, 1.4), V(-0.62, hy + 0.15, 0.2) },
			{ "ball", V(1.4, 1.4, 1.4), V(0.62, hy + 0.15, 0.2) },
		})
	elseif style == "curly" then
		base({ top = 0.14, front = 0.36, back = -0.4, sides = 0.3 })
		for _, p in { { -0.5, 0.0, -0.3 }, { 0, 0.08, -0.35 }, { 0.5, 0.0, -0.3 }, { -0.62, -0.15, 0.25 }, { 0.62, -0.15, 0.25 }, { 0, 0.05, 0.4 } } do
			self:ell("HeadDetail", V(0.5, 0.42, 0.5), V(p[1], top + p[2], p[3]), color)
		end
	elseif style == "tufts" then -- bald on top, tufts over the ears
		for _, s in { -1, 1 } do
			self:rbox("HeadDetail", V(0.24, 0.5, 0.75), V(s * (D.headW / 2 + 0.06), hy + 0.05, 0.15), color, 0.1)
			self:ell("HeadDetail", V(0.3, 0.3, 0.3), V(s * (D.headW / 2 + 0.12), hy + 0.32, 0.0), color)
		end
		self:rbox("HeadDetail", V(D.headW - 0.1, 0.4, 0.2), V(0, hy - 0.05, D.headD / 2 + 0.06), color, 0.08)
	elseif style == "mohawk" then
		base({ top = -0.25, front = 0.0, back = -0.38, sides = 0.0, puff = 0.03 })
		self:rbox("HeadDetail", V(0.3, 0.55, 1.3), V(0, top + 0.22, 0.05), color, 0.12)
	end
end

------------------------------------------------------------------ hats
local function hatBase(): number
	return Kit.headY + D.headH / 2
end
function Kit:capHat(color: Color3, brim: Color3?, backwards: boolean?)
	local y = hatBase() - 0.3
	local dz = if backwards then -1 else 1
	self:dome("HeadDetail", V(1.64, 1.14, 1.52), V(0, y, 0.03), color)
	self:rbox("HeadDetail", V(1.18, 0.1, 0.72), V(0, y + 0.03, -0.98 * dz), brim or color, 0.045, V(-12 * dz, 0, 0))
	self:ell("HeadDetail", V(0.16, 0.1, 0.16), V(0, y + 0.56, 0.03), brim or color)
end
function Kit:beanie(color: Color3, cuff: Color3?, pom: Color3?)
	local y = hatBase() - 0.36
	self:dome("HeadDetail", V(1.62, 1.3, 1.5), V(0, y, 0.02), color)
	self:rbox("HeadDetail", V(1.62, 0.28, 1.5), V(0, y + 0.08, 0.02), cuff or color, 0.12)
	if pom then
		self:ell("HeadDetail", V(0.36, 0.36, 0.36), V(0, y + 0.72, 0.02), pom)
	end
end
function Kit:topHat(color: Color3, band: Color3?, height: number?)
	local y, h = hatBase() - 0.06, height or 1.0
	self:rbox("HeadDetail", V(1.75, 0.1, 1.6), V(0, y, 0.02), color, 0.05)
	self:rbox("HeadDetail", V(1.12, h, 1.04), V(0, y + h / 2, 0.02), color, 0.1)
	if band then
		self:rbox("HeadDetail", V(1.15, 0.2, 1.07), V(0, y + 0.18, 0.02), band, 0.06)
	end
end
-- wide-brim hats: straw / cowboy / sun hats. crown = the bit on top
function Kit:brimHat(color: Color3, band: Color3?, brimW: number?, crownH: number?, pinch: boolean?)
	local y, bw, ch = hatBase() - 0.12, brimW or 2.3, crownH or 0.6
	self:carve("HeadDetail", V(bw, 0.1, bw * 0.92), V(0, y, 0.02), color, 0.05, {})
	if pinch then -- cowboy: the brim curls up at both sides
		for _, s in { -1, 1 } do
			self:rbox("HeadDetail", V(0.35, 0.1, bw * 0.8), V(s * (bw / 2 - 0.12), y + 0.12, 0.02), color, 0.05, V(0, 0, s * -35))
		end
	end
	self:rbox("HeadDetail", V(1.3, ch, 1.15), V(0, y + ch / 2, 0.02), color, 0.22)
	if pinch then
		self:block("HeadDetail", V(0.12, 0.2, 0.7), V(0, y + ch, 0.02), color) -- crease
	end
	if band then
		self:rbox("HeadDetail", V(1.33, 0.14, 1.18), V(0, y + 0.13, 0.02), band, 0.06)
	end
end
function Kit:chefHat(color: Color3, band: Color3?, height: number?)
	local y, h = hatBase() - 0.1, height or 0.9
	self:rbox("HeadDetail", V(1.5, 0.35, 1.38), V(0, y + 0.1, 0.02), band or color, 0.1)
	self:fuse("HeadDetail", color, {
		{ "rbox", V(1.4, h, 1.3), V(0, y + h / 2 + 0.2, 0.02), nil, 0.3 },
		{ "ball", V(0.85, 0.85, 0.85), V(-0.38, y + h + 0.15, 0.02) },
		{ "ball", V(0.85, 0.85, 0.85), V(0.38, y + h + 0.15, 0.02) },
		{ "ball", V(0.9, 0.9, 0.9), V(0, y + h + 0.25, -0.15) },
	})
end
function Kit:crown(color: Color3, gem: Color3?, points: number?)
	local y = hatBase() - 0.05
	local n = points or 5
	self:carve("HeadDetail", V(1.3, 0.38, 1.2), V(0, y + 0.12, 0.02), color, 0.08, { { V(1.1, 1, 1.0), V(0, y + 0.5, 0.02) } })
	for i = 0, n - 1 do
		local a = math.rad(-90 + i * 360 / n)
		self:fuse("HeadDetail", color, { { "wedge", V(0.12, 0.38, 0.32), V(math.cos(a) * 0.6, y + 0.45, math.sin(a) * 0.55 + 0.02), V(0, -math.deg(a) + 90, 0) } })
		self:ball("HeadDetail", 0.12, V(math.cos(a) * 0.62, y + 0.66, math.sin(a) * 0.57 + 0.02), color)
	end
	if gem then
		self:ell("HeadDetail", V(0.2, 0.2, 0.08), V(0, y + 0.13, -0.62), gem)
	end
end

------------------------------------------------------------------ install
-- Replaces ServerStorage.Templates.Clients.<Id> (the old one goes to ServerStorage.RetiredClients.<Id>_v2).
function Kit:finish(): Model
	local m = self.model
	local hrp = raw(Enum.PartType.Block, V(1.6, 1.6, 0.8), self:_world(CFrame.new(0, Kit.hipY + D.torsoH / 2, 0)))
	hrp.Name = "HumanoidRootPart"
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.CanTouch = false
	hrp.CanQuery = false
	hrp.Anchored = true
	hrp.Parent = m
	m.PrimaryPart = hrp
	m:SetAttribute("Style", "BlockV3")
	m:SetAttribute("ClientId", self.id)
	return m
end

function Kit:install(note: string?): Model
	local m = self.model
	local templates = game:GetService("ServerStorage").Templates.Clients
	local retired = game:GetService("ServerStorage"):FindFirstChild("RetiredClients") or Instance.new("Folder")
	retired.Name = "RetiredClients"
	retired.Parent = game:GetService("ServerStorage")
	local old = templates:FindFirstChild(self.id)
	if old then
		if not retired:FindFirstChild(self.id .. "_v2") then
			old.Name = self.id .. "_v2"
			old.Parent = retired
		else
			old:Destroy()
		end
	end
	m:PivotTo(CFrame.new(0, Kit.hipY + D.torsoH / 2, 0))
	m:SetAttribute("Remade", "2026-10-10 client v3" .. (if note then ": " .. note else ""))
	m.Name = self.id
	m.Parent = templates
	return m
end

-- preview: the new model at the stage origin, the old template beside it (left) for comparison
function Kit:preview(): string
	local stage = workspace:FindFirstChild("_ClientStage") or Instance.new("Folder")
	stage.Name = "_ClientStage"
	stage.Parent = workspace
	for _, ch in stage:GetChildren() do
		if ch.Name ~= "Floor" then
			ch:Destroy()
		end
	end
	if not stage:FindFirstChild("Floor") then
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Anchored = true
		floor.Size = V(40, 1, 20)
		floor.Position = self.origin - V(0, 0.5, 0)
		floor.Color = Color3.fromRGB(225, 228, 235)
		floor.Parent = stage
	end
	self.model.Parent = stage
	local old = game:GetService("ServerStorage").Templates.Clients:FindFirstChild(self.id)
	if old and old ~= self.model then
		local o = old:Clone()
		o.Name = "_Old"
		local cf, sz = o:GetBoundingBox()
		o:PivotTo(o:GetPivot() + (self.origin + V(4.5, sz.Y / 2, 0) - cf.Position))
		o.Parent = stage
	end
	local _, size = self.model:GetBoundingBox()
	return string.format("%d parts, %.2f x %.2f x %.2f", self.count, size.X, size.Y, size.Z)
end

return Kit
