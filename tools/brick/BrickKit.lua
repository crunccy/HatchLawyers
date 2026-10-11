--!strict
-- BrickKit (ServerStorage.BrickKit): the brick character style (2026-10-11 redesign, docs/CHARACTER_STYLE.md).
-- ONE kit for lawyers AND clients, so every character shares one body, one face and one surface:
--   * hard-edged Plastic bricks with studs on every face: MaterialService.BrickStuds, a MaterialVariant whose normal
--     map (art/materials/stud_normal.png, tools/stud_normal.py) puts one stud every 0.5 studs - Roblox's own
--     SurfaceType.Studs are 1 stud wide, twice too coarse on a 2-stud head (two big studs read as eye bags). One
--     shared material = nothing added per part. Without the variant the kit falls back to SurfaceType.Studs,
--   * thin details (face, ties, lapels, trims, buttons) as smooth plates so they read cleanly,
--   * square eyes: a white plate in a dark border with a square pupil, no shine; brow plates; a small mouth plate,
--   * no outlines, no gradients, no Metal / Glass / Foil; Neon only for tiny Legendary accents.
-- Frame (studs): legs 0.9 x 1.3, torso 2.0 x 1.5 x 1.1, arms 0.7 x 1.45 (hand block at the end), head 2.0 x 1.8 x
-- 1.8 sitting right on the torso = ~4.6 tall before hair, the head ~38% of it (chibi, readable on a phone).
-- Model space: feet at y = 0, the character faces -Z, +X is the character's LEFT (screen right facing you).
-- Part names follow Shared.Puppet, which sorts parts into head / torso / arms / legs by NAME first, then position:
--   Head = the head block ONLY (Puppet takes the neck height from it), HeadDetail = face, hair, hats (sorted into the
--   head by position), UpperTorso, Left/RightUpperArm, Left/RightUpperLeg. Every extra brick is named after the
--   limb it belongs to. Clients also get an invisible HumanoidRootPart (finishClient).
-- tools/brick/<Id>.lua are the builders: local k = Kit.new("<Id>"); k:body({...}); k:eyes({...}); ...;
-- k:installLawyer(note) or k:finishClient(); k:installClient(note).

local Kit = {}
Kit.__index = Kit

local V = Vector3.new
local STUDS, SMOOTH = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth

function Kit.hex(h: string): Color3
	return Color3.fromHex(h)
end
local H = Kit.hex

-- shared colours (style guide: no pure white / black on bodies so the studs keep their shading)
Kit.C = {
	White = H("f2efe8"), EyeWhite = H("fbfaf6"), Ink = H("24242c"), Border = H("1c1c20"), Pupil = H("0f0f12"),
	Mouth = H("5a1419"), Tongue = H("d84a5a"), Teeth = H("fbfaf6"),
	Gold = H("ffc828"), GoldDark = H("d99a10"), Rare = H("3ca0ff"), Epic = H("b45aff"),
	Skin = { H("ffd3a8"), H("e8b087"), H("c68a5e"), H("8d5a3b"), H("5c3a26") },
}

-- the frame
Kit.D = {
	legW = 0.9, legD = 0.9, legH = 1.3, legGap = 0.1, shoeH = 0.3,
	torsoW = 2.0, torsoH = 1.5, torsoD = 1.1,
	armW = 0.7, armD = 0.8, armH = 1.45, armGap = 0.04, handH = 0.42,
	headW = 2.0, headH = 1.8, headD = 1.8,
}
local D = Kit.D
Kit.hipY = D.legH
Kit.shoulderY = D.legH + D.torsoH
Kit.headY = D.legH + D.torsoH + D.headH / 2
Kit.headTop = D.legH + D.torsoH + D.headH
Kit.faceZ = -D.headD / 2
Kit.armX = D.torsoW / 2 + D.armGap + D.armW / 2
Kit.legX = (D.legW + D.legGap) / 2

function Kit.new(id: string, origin: Vector3?)
	local m = Instance.new("Model")
	m.Name = id
	return setmetatable({ model = m, id = id, origin = origin or V(0, 500, 0), count = 0 }, Kit)
end

local function cfOf(pos: Vector3 | CFrame, rot: Vector3?): CFrame
	local base = if typeof(pos) == "CFrame" then pos else CFrame.new(pos)
	local r = rot or Vector3.zero
	return base * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
end
Kit.cf = cfOf

local function surfaces(p: BasePart, s: Enum.SurfaceType)
	p.TopSurface, p.BottomSurface, p.FrontSurface = s, s, s
	p.BackSurface, p.LeftSurface, p.RightSurface = s, s, s
end

Kit.STUD_VARIANT = "BrickStuds"
local hasVariant = game:GetService("MaterialService"):FindFirstChild(Kit.STUD_VARIANT) ~= nil

function Kit:_part(class: string, name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?, studs: boolean): BasePart
	local p = Instance.new(class) :: BasePart
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Plastic
	if studs and hasVariant then
		p.MaterialVariant = Kit.STUD_VARIANT
		surfaces(p, SMOOTH)
	else
		surfaces(p, if studs then STUDS else SMOOTH)
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = size.X * size.Y * size.Z > 0.02 -- face plates and trims don't need shadows
	p.CFrame = CFrame.new(self.origin) * cfOf(pos, rot)
	p.Parent = self.model
	self.count += 1
	return p
end

-- a brick: studs on every face (bodies, limbs, hair, hats, props)
function Kit:brick(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	return self:_part("Part", name, size, pos, color, rot, true)
end
-- a plate: smooth (face bits, ties, lapels, trims, buttons)
function Kit:plate(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	return self:_part("Part", name, size, pos, color, rot, false)
end
-- a wedge (ears, collars, tips): Roblox WedgePart, slope rises toward -Z
function Kit:wedge(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?, studs: boolean?): BasePart
	return self:_part("WedgePart", name, size, pos, color, rot, studs ~= false)
end
-- a tiny Neon accent (Legendary only)
function Kit:glow(name: string, size: Vector3, pos: Vector3 | CFrame, color: Color3, rot: Vector3?): BasePart
	local p = self:plate(name, size, pos, color, rot)
	p.Material = Enum.Material.Neon
	return p
end

function Kit.armName(side: number): string
	return if side < 0 then "RightUpperArm" else "LeftUpperArm"
end
function Kit.legName(side: number): string
	return if side < 0 then "RightUpperLeg" else "LeftUpperLeg"
end
-- where a hand is (model space): side -1 = the character's right (screen left facing you)
function Kit:hand(side: number): Vector3
	return V(side * Kit.armX, Kit.shoulderY - D.armH + D.handH / 2, 0)
end

------------------------------------------------------------------ body
-- o: skin, shirt, pants, shoes, sleeve (sleeve colour, default shirt), sleeves = "long"|"short", hands,
--    legs = "long"|"shorts", socks (colour), sockH, sandals (bool), torsoD
function Kit:body(o: { [string]: any })
	local skin, shirt = o.skin, o.shirt
	local pants, shoes = o.pants or shirt, o.shoes or Kit.C.Ink
	local sleeve, hands = o.sleeve or shirt, o.hands or skin
	self.skin = skin
	local hipY, shY = Kit.hipY, Kit.shoulderY
	for _, s in { -1, 1 } do
		local x, leg = s * Kit.legX, Kit.legName(s)
		local footTop = D.shoeH
		if o.sandals then
			-- a socked (or bare) foot on a thick sole, two straps across it
			local foot = o.socks or skin
			self:brick(leg, V(D.legW, 0.28, D.legD + 0.16), V(x, 0.12 + 0.14, -0.08), foot)
			self:brick(leg, V(D.legW + 0.08, 0.12, D.legD + 0.24), V(x, 0.06, -0.08), shoes)
			for _, z in { -0.38, 0.02 } do
				self:plate(leg, V(D.legW + 0.04, 0.08, 0.14), V(x, 0.3, z), shoes)
			end
			footTop = 0.4
		else
			self:brick(leg, V(D.legW + 0.04, D.shoeH, D.legD + 0.2), V(x, D.shoeH / 2, -0.1), shoes)
		end
		if (o.legs or "long") == "long" then
			self:brick(leg, V(D.legW, hipY - footTop, D.legD), V(x, footTop + (hipY - footTop) / 2, 0), pants)
		else
			local shortsH = 0.55
			self:brick(leg, V(D.legW + 0.04, shortsH, D.legD + 0.04), V(x, hipY - shortsH / 2, 0), pants)
			local sockH = if o.socks then (o.sockH or 0.45) else 0
			local bare = hipY - shortsH - footTop - sockH
			if bare > 0.02 then
				self:brick(leg, V(D.legW - 0.1, bare, D.legD - 0.1), V(x, footTop + sockH + bare / 2, 0), skin)
			end
			if o.socks then
				self:brick(leg, V(D.legW - 0.06, sockH, D.legD - 0.06), V(x, footTop + sockH / 2, 0), o.socks)
			end
		end
	end
	local td = o.torsoD or D.torsoD
	self.td = td
	self.torso = self:brick("UpperTorso", V(D.torsoW, D.torsoH, td), V(0, hipY + D.torsoH / 2, 0), shirt)
	for _, s in { -1, 1 } do
		local x, arm = s * Kit.armX, Kit.armName(s)
		local upper = D.armH - D.handH
		if (o.sleeves or "long") == "long" then
			self:brick(arm, V(D.armW, upper, D.armD), V(x, shY - upper / 2, 0), sleeve)
		else
			local sleeveH = 0.5
			self:brick(arm, V(D.armW + 0.04, sleeveH, D.armD + 0.04), V(x, shY - sleeveH / 2, 0), sleeve)
			self:brick(arm, V(D.armW - 0.08, upper - sleeveH, D.armD - 0.08), V(x, shY - sleeveH - (upper - sleeveH) / 2, 0), skin)
		end
		self:brick(arm, V(D.armW - 0.02, D.handH, D.armD - 0.02), V(x, shY - D.armH + D.handH / 2, 0), hands)
	end
	self.head = self:brick("Head", V(D.headW, D.headH, D.headD), V(0, Kit.headY, 0), skin)
	return self
end

------------------------------------------------------------------ face (all HeadDetail, smooth plates on the -Z face)
-- one square eye at (x, y): a dark border, the white, a square pupil. look = pupil offset (-1..1 each way, x toward
-- the character's left / screen right). lid = 0..1 of the eye covered from the top (sleepy / bored), in lidColor.
function Kit:eye(x: number, y: number, o: { [string]: any }?)
	local opt = o or {}
	local w, h = opt.w or 0.5, opt.h or 0.56
	local z = Kit.faceZ
	local border = opt.border ~= false
	if border then -- a thin dark rim (thicker reads as glasses)
		self:plate("HeadDetail", V(w + 0.06, h + 0.06, 0.04), V(x, y, z - 0.02), Kit.C.Border)
	end
	self:plate("HeadDetail", V(w, h, 0.04), V(x, y, z - 0.045), Kit.C.EyeWhite)
	local pw, ph = w * 0.52, h * 0.6
	local look = opt.look or Vector2.new(0, 0)
	local px = x + look.X * (w - pw) / 2
	local py = y + look.Y * (h - ph) / 2
	self:plate("HeadDetail", V(pw, ph, 0.04), V(px, py, z - 0.07), Kit.C.Pupil)
	local lid = opt.lid or 0
	if lid > 0 then
		local lh = h * lid
		self:plate("HeadDetail", V(w + 0.06, lh + 0.03, 0.04), V(x, y + h / 2 - lh / 2 + 0.015, z - 0.095), opt.lidColor or self.skin)
	end
end

-- both eyes. o: y (offset from head centre), gap (centre to centre), w, h, look (Vector2, both pupils the same way),
-- inward (0..1, pupils toward the nose; negative = apart), lid, lidColor, border
function Kit:eyes(o: { [string]: any }?)
	local opt = o or {}
	local y = Kit.headY + (opt.y or 0.05)
	local gap = opt.gap or 0.92
	local look = opt.look or Vector2.new(0, 0)
	for _, s in { -1, 1 } do
		local e = table.clone(opt)
		e.look = Vector2.new(math.clamp(look.X - s * (opt.inward or 0), -1, 1), look.Y)
		self:eye(s * gap / 2, y, e)
	end
end

-- brow plates above the eyes. tilt (degrees): positive raises the OUTER ends (worried), negative = cross / determined.
-- raise lifts them. o.only = -1 / 1 for one brow; o.tiltL / o.tiltR override per side.
function Kit:brows(color: Color3, o: { [string]: any }?)
	local opt = o or {}
	local y = Kit.headY + (opt.y or 0.05) + (opt.h or 0.56) / 2 + 0.16 + (opt.raise or 0)
	local gap = opt.gap or 0.92
	for _, s in { -1, 1 } do
		if not opt.only or opt.only == s then
			local t = (if s > 0 then opt.tiltL else opt.tiltR) or opt.tilt or 0
			-- +X = the character's left; raising the outer end means rotating toward the outside
			self:plate("HeadDetail", V(opt.w or 0.56, opt.thick or 0.13, 0.05), V(s * gap / 2, y + (opt.lift and opt.lift[s] or 0), Kit.faceZ - 0.04), color, V(0, 0, s * t))
		end
	end
end

-- a blocky nose (skin by default)
function Kit:nose(color: Color3?, o: { [string]: any }?)
	local opt = o or {}
	local size = opt.size or V(0.3, 0.26, 0.18)
	self:plate("HeadDetail", size, V(0, Kit.headY + (opt.y or -0.24), Kit.faceZ - size.Z / 2), color or self.skin)
end

-- a mouth plate. style: "flat" | "smile" | "grin" (open D with a teeth strip) | "open" (shouting, with tongue)
function Kit:mouth(style: string?, o: { [string]: any }?)
	local opt = o or {}
	local y = Kit.headY + (opt.y or -0.56)
	local z = Kit.faceZ - 0.03
	local w = opt.w or 0.5
	local st = style or "flat"
	if st == "flat" then
		self:plate("HeadDetail", V(w, 0.1, 0.04), V(0, y, z), Kit.C.Mouth)
	elseif st == "smile" then
		self:plate("HeadDetail", V(w - 0.12, 0.1, 0.04), V(0, y, z), Kit.C.Mouth)
		for _, s in { -1, 1 } do
			self:plate("HeadDetail", V(0.1, 0.18, 0.04), V(s * (w / 2 - 0.05), y + 0.04, z), Kit.C.Mouth)
		end
	elseif st == "grin" then
		local hgt = opt.h or 0.26
		self:plate("HeadDetail", V(w, hgt, 0.04), V(0, y, z), Kit.C.Mouth)
		self:plate("HeadDetail", V(w - 0.1, 0.08, 0.04), V(0, y + hgt / 2 - 0.07, z - 0.01), Kit.C.Teeth)
		self:plate("HeadDetail", V(w * 0.5, 0.07, 0.04), V(0, y - hgt / 2 + 0.06, z - 0.01), Kit.C.Tongue)
	elseif st == "open" then
		local hgt = opt.h or 0.36
		self:plate("HeadDetail", V(w * 0.8, hgt, 0.04), V(0, y, z), Kit.C.Mouth)
		self:plate("HeadDetail", V(w * 0.55, 0.1, 0.04), V(0, y - hgt / 2 + 0.08, z - 0.01), Kit.C.Tongue)
	end
end

------------------------------------------------------------------ hair & hats (HeadDetail bricks)
-- a brick hair cap: a top slab, a back slab and side slabs, plus an optional fringe across the forehead.
-- o: top (slab height above the head), fringe (how far the fringe comes down the forehead, 0 = none),
--    sideburn (how far the sides come down), back (how far the back comes down), hat (true = stay under a hat line)
function Kit:hairCap(color: Color3, o: { [string]: any }?)
	local opt = o or {}
	local top = if opt.hat then 0 else (opt.top or 0.22)
	local W, Dd = D.headW + 0.12, D.headD + 0.12
	local cover = opt.cover or 0.3 -- how much of the head's top the slab wraps (keep it above the brows)
	local topY = Kit.headTop + top
	if not opt.noTop then -- (noTop: only sides + back, for under a cap)
		self:brick("HeadDetail", V(W, cover + top, Dd), V(0, topY - (cover + top) / 2, 0.0), color)
	end
	local back = opt.back or 1.25
	self:brick("HeadDetail", V(W, back, 0.16), V(0, Kit.headTop - back / 2, D.headD / 2 + 0.08), color)
	local side = opt.sideburn or 0.75
	for _, s in { -1, 1 } do
		self:brick("HeadDetail", V(0.12, side, D.headD * 0.7), V(s * (D.headW / 2 + 0.06), Kit.headTop - side / 2, D.headD * 0.15), color)
	end
	local fringe = opt.fringe or 0
	if fringe > 0 then
		self:brick("HeadDetail", V(W, fringe, 0.16), V(0, Kit.headTop - cover - fringe / 2 + 0.02, Kit.faceZ - 0.08), color)
	end
	return topY
end

-- a cap: crown brick over the head top, a brim plate out front (backwards = brim at the back), a button on top
function Kit:cap(color: Color3, brim: Color3?, o: { [string]: any }?)
	local opt = o or {}
	local crownH = opt.crownH or 0.62
	local W, Dd = D.headW + 0.16, D.headD + 0.16
	local bottom = Kit.headTop - (opt.down or 0.32)
	self:brick("HeadDetail", V(W, crownH, Dd), V(0, bottom + crownH / 2, 0), color)
	local dir = if opt.backwards then 1 else -1
	local brimD = opt.brimD or 0.8
	self:brick("HeadDetail", V(opt.brimW or 1.7, 0.14, brimD), V(0, bottom + 0.07, dir * (Dd / 2 + brimD / 2 - 0.05)), brim or color)
	self:brick("HeadDetail", V(0.32, 0.14, 0.32), V(0, bottom + crownH + 0.07, 0), brim or color)
	return bottom + crownH
end

------------------------------------------------------------------ outfit pieces (call after body; all UpperTorso)
function Kit:frontZ(extra: number?): number
	return -(self.td or D.torsoD) / 2 - (extra or 0)
end

-- jacket lapels around a shirt V: the shirt panel shows in the middle, two lapel plates angle down to it
function Kit:lapels(jacket: Color3, shirt: Color3, o: { [string]: any }?)
	local opt = o or {}
	local shY = Kit.shoulderY
	local z = self:frontZ()
	local depth = opt.depth or 0.85 -- how far down the V goes
	self:plate("UpperTorso", V(opt.panel or 0.62, depth, 0.05), V(0, shY - depth / 2, z - 0.025), shirt)
	local lap = opt.lapel or jacket
	for _, s in { -1, 1 } do
		self:plate("UpperTorso", V(0.3, depth + 0.1, 0.06), V(s * 0.38, shY - depth / 2 - 0.02, z - 0.05), lap, V(0, 0, s * 22))
	end
end

-- a tie: knot + blade + a point
function Kit:tie(color: Color3, length: number?)
	local shY = Kit.shoulderY
	local z = self:frontZ() - 0.09
	local L = length or 0.62
	self:plate("UpperTorso", V(0.26, 0.2, 0.08), V(0, shY - 0.12, z), color)
	self:plate("UpperTorso", V(0.2, L, 0.06), V(0, shY - 0.22 - L / 2, z + 0.01), color)
	self:plate("UpperTorso", V(0.13, 0.13, 0.06), V(0, shY - 0.22 - L - 0.03, z + 0.01), color, V(0, 0, 45))
end

function Kit:belt(color: Color3, buckle: Color3?)
	local y = Kit.hipY + 0.08
	self:brick("UpperTorso", V(D.torsoW + 0.06, 0.18, (self.td or D.torsoD) + 0.06), V(0, y, 0), color)
	if buckle then
		self:plate("UpperTorso", V(0.3, 0.22, 0.06), V(0, y, self:frontZ(0.06)), buckle)
	end
end

function Kit:buttons(n: number, color: Color3, x: number?, yTop: number?, dy: number?)
	for i = 1, n do
		local y = (yTop or Kit.shoulderY - 0.35) - (i - 1) * (dy or 0.28)
		self:plate("UpperTorso", V(0.1, 0.1, 0.05), V(x or 0, y, self:frontZ(0.06)), color)
	end
end

------------------------------------------------------------------ install
local function retire(folderName: string, model: Instance, newName: string)
	local ss = game:GetService("ServerStorage")
	local folder = ss:FindFirstChild(folderName) or Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = ss
	if folder:FindFirstChild(newName) then
		model:Destroy() -- an older copy is already kept
	else
		model.Name = newName
		model.Parent = folder
	end
end

-- a LAWYER: becomes ReplicatedStorage.SkinModels.<Id>, pivot at the feet; the model it replaces is kept as
-- ServerStorage.RetiredSkinModels.<Id>_preBrick (move it back to undo).
function Kit:installLawyer(note: string, sideways: boolean?): Model
	local skins = game:GetService("ReplicatedStorage").SkinModels
	local old = skins:FindFirstChild(self.id)
	if old then
		retire("RetiredSkinModels", old, self.id .. "_preBrick")
	end
	local m = self.model
	m.Name = self.id
	m.WorldPivot = CFrame.new(self.origin)
	m:PivotTo(CFrame.new())
	m:SetAttribute("Style", "Brick")
	m:SetAttribute("Remade", "2026-10-11 brick style: " .. note)
	if sideways then
		m:SetAttribute("Sideways", true)
	end
	m.Parent = skins
	return m
end

-- a CLIENT: adds the invisible HumanoidRootPart (PrimaryPart / pivot, mid-body) first
function Kit:finishClient(): Model
	local m = self.model
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = V(1.6, 1.4, 0.8)
	hrp.CFrame = CFrame.new(self.origin + V(0, Kit.hipY + D.torsoH / 2, 0))
	hrp.Transparency = 1
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.CanTouch = false
	hrp.CanQuery = false
	hrp.Parent = m
	m.PrimaryPart = hrp
	m:SetAttribute("Style", "Brick")
	m:SetAttribute("ClientId", self.id)
	return m
end

-- becomes ServerStorage.Templates.Clients.<Id>; the template it replaces is kept as
-- ServerStorage.RetiredClients.<Id>_v3 (move it back to undo)
function Kit:installClient(note: string?): Model
	local templates = game:GetService("ServerStorage").Templates.Clients
	local old = templates:FindFirstChild(self.id)
	if old then
		retire("RetiredClients", old, self.id .. "_v3")
	end
	local m = self.model
	m:PivotTo(CFrame.new(0, Kit.hipY + D.torsoH / 2, 0))
	m:SetAttribute("Remade", "2026-10-11 brick style" .. (if note then ": " .. note else ""))
	m.Name = self.id
	m.Parent = templates
	return m
end

-- side-by-side check: this model where it was built, `old` (a model to compare with) 3.2 studs to its left
function Kit:preview(old: Model?): string
	local stage = workspace:FindFirstChild("_BrickStage") or Instance.new("Folder")
	stage.Name = "_BrickStage"
	stage.Parent = workspace
	if not stage:FindFirstChild("Floor") then
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Anchored = true
		floor.Size = V(40, 1, 20)
		floor.Position = self.origin - V(0, 0.5, 0)
		floor.Color = Color3.fromRGB(110, 200, 70)
		floor.TopSurface = STUDS
		floor.Parent = stage
	end
	self.model.Parent = stage
	if old then
		local o = old:Clone()
		o.Name = "_Old_" .. self.id
		local cf, sz = o:GetBoundingBox()
		o:PivotTo(o:GetPivot() + (self.origin + V(-3.2, sz.Y / 2, 0) - cf.Position))
		o.Parent = stage
	end
	local _, size = self.model:GetBoundingBox()
	return string.format("%s: %d parts, %.2f x %.2f x %.2f", self.id, self.count, size.X, size.Y, size.Z)
end

return Kit
