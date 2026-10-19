--!strict
-- Studs (StarterPlayerScripts; 2026-10-18, docs/ART_STYLE_STUDS.md): the studded-brick world's RAISED studs, on the
-- client only (nothing replicates, nothing is saved, no collision). Every part tagged "StudTop" gets Roblox-shaped
-- 3D studs on its top face, near the camera:
--   * tiles are the uploaded MeshParts in ReplicatedStorage.Studs.Tiles (tools/zones/BuildStudTiles.lua): 8x8 ...
--     1x1 studs per mesh, "full" detail on PC, "low" on phones / low graphics
--   * a cell gets a stud only if nothing visible and anchored sits in the stud's space (checked against part bounds,
--     not rays: most firm parts have CanQuery off), so no stud pokes out of a wall, a firm floor or a path; when a
--     part appears or goes (a firm built, a room bought), the faces it touches are redone once things settle
--   * the map is cut into chunks; a chunk's tiles exist only within Config.Studs.Radius of the camera (built the
--     first time it comes near, then kept), and the part's flat stud texture is turned Smooth only under raised studs,
--     so far away the old texture still reads as studded
-- Tag a part "StudTop" to stud it (its top face must point up). Decorative only: CanCollide / CanQuery / CanTouch off.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local C = Config.Studs
local tiles = ReplicatedStorage:WaitForChild("Studs"):WaitForChild("Tiles") :: Folder

local function lowDetail(): boolean
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return true -- phones / tablets
	end
	local ok, q = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return ok and q > 0 and q <= C.LowQualityLevel -- (0 = Automatic: keep full)
end
local LOW = lowDetail()
local LOD = if LOW then "low" else "full"
local RADIUS = if LOW then C.RadiusLow else C.Radius
local SIZES = { { 8, 8 }, { 8, 4 }, { 4, 8 }, { 4, 4 }, { 8, 2 }, { 2, 8 }, { 4, 2 }, { 2, 4 }, { 8, 1 }, { 1, 8 },
	{ 2, 2 }, { 4, 1 }, { 1, 4 }, { 2, 1 }, { 1, 2 }, { 1, 1 } }

local root = Instance.new("Folder")
root.Name = "ClientStuds"
root.Parent = workspace

type Chunk = { key: Vector2, centre: Vector3, model: Model, shown: boolean, parts: { [BasePart]: boolean } }
type Entry = { part: BasePart, tiles: { BasePart }, built: boolean, chunks: { [Chunk]: boolean }, oldTop: Enum.SurfaceType }
local chunks: { [string]: Chunk } = {}
local entries: { [BasePart]: Entry } = {}

local function chunkAt(pos: Vector3): Chunk
	local cx, cz = math.floor(pos.X / C.ChunkSize), math.floor(pos.Z / C.ChunkSize)
	local id = cx .. "," .. cz
	local ch = chunks[id]
	if not ch then
		local model = Instance.new("Model")
		model.Name = "Chunk_" .. id
		ch = {
			key = Vector2.new(cx, cz),
			centre = Vector3.new((cx + 0.5) * C.ChunkSize, pos.Y, (cz + 0.5) * C.ChunkSize),
			model = model,
			shown = false,
			parts = {},
		}
		chunks[id] = ch
	end
	return ch
end

-- what can cover a stud: every visible, anchored part, in a coarse XZ grid of world bounds (spatial queries skip
-- CanQuery-off parts, so this index is kept by hand)
local INDEX = 16
type Box = { lo: Vector3, hi: Vector3 }
local boxes: { [BasePart]: Box } = {}
local index: { [string]: { [BasePart]: boolean } } = {}
local big: { [BasePart]: boolean } = {} -- parts spanning too many grid cells (the sea, big floors)

local function bounds(p: BasePart): Box
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local half = Vector3.new(
		math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
		math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
	)
	return { lo = cf.Position - half, hi = cf.Position + half }
end

local function cellsOf(b: Box, f: (string) -> ())
	for x = math.floor(b.lo.X / INDEX), math.floor(b.hi.X / INDEX) do
		for z = math.floor(b.lo.Z / INDEX), math.floor(b.hi.Z / INDEX) do
			f(x .. "," .. z)
		end
	end
end

local function canCover(d: Instance): boolean
	if not d:IsA("BasePart") or d:IsA("Terrain") or d:IsDescendantOf(root) then
		return false -- (Terrain is a BasePart whose box is the whole map)
	end
	local p = d :: BasePart
	if not p.Anchored or p.Transparency >= 0.9 then
		return false
	end
	local m = p:FindFirstAncestorOfClass("Model")
	return not (m and m:FindFirstChildOfClass("Humanoid"))
end

local function indexAdd(p: BasePart): Box
	local b = bounds(p)
	boxes[p] = b
	local n = (math.floor(b.hi.X / INDEX) - math.floor(b.lo.X / INDEX) + 1) * (math.floor(b.hi.Z / INDEX) - math.floor(b.lo.Z / INDEX) + 1)
	if n > 64 then
		big[p] = true
	else
		cellsOf(b, function(k)
			local set = index[k]
			if not set then
				set = {}
				index[k] = set
			end
			set[p] = true
		end)
	end
	return b
end

local function indexRemove(p: BasePart): Box?
	local b = boxes[p]
	if not b then
		return nil
	end
	boxes[p] = nil
	big[p] = nil
	cellsOf(b, function(k)
		local set = index[k]
		if set then
			set[p] = nil
		end
	end)
	return b
end

-- does this box reach into the stud layer of this face (from just above the face to the studs' tops)?
local function touchesLayer(b: Box, face: Box): boolean
	local y = face.hi.Y
	return b.lo.Y < y + C.Height + 0.02 and b.hi.Y > y + 0.01
		and b.lo.X < face.hi.X and b.hi.X > face.lo.X and b.lo.Z < face.hi.Z and b.hi.Z > face.lo.Z
end

local function clear(e: Entry)
	for _, t in e.tiles do
		t:Destroy()
	end
	table.clear(e.tiles)
	e.built = false
end

local function build(e: Entry)
	clear(e)
	e.built = true
	local part = e.part
	local cf = part.CFrame
	if cf.UpVector.Y < 0.99 then
		return -- only faces that point up
	end
	local nx, nz = math.floor(part.Size.X + 0.01), math.floor(part.Size.Z + 0.01)
	if nx < 1 or nz < 1 then
		return
	end
	local top = part.Size.Y / 2
	local x0, z0 = -nx / 2, -nz / 2 -- the grid is centred on the face
	local face = boxes[part] or bounds(part)
	local free: { { boolean } } = {}
	for i = 1, nx do
		free[i] = table.create(nz, true)
	end
	local seen: { [BasePart]: boolean } = { [part] = true }
	local foot = C.Foot
	local function cover(p: BasePart)
		if seen[p] then
			return
		end
		seen[p] = true
		local b = boxes[p]
		if not b or not touchesLayer(b, face) then
			return
		end
		-- its footprint in the face's grid (corners into the face's space; faces are turned in 90s at most)
		local mnx, mxx, mnz, mxz = math.huge, -math.huge, math.huge, -math.huge
		for _, c in { Vector3.new(b.lo.X, 0, b.lo.Z), Vector3.new(b.hi.X, 0, b.lo.Z), Vector3.new(b.lo.X, 0, b.hi.Z), Vector3.new(b.hi.X, 0, b.hi.Z) } do
			local l = cf:PointToObjectSpace(Vector3.new(c.X, cf.Position.Y, c.Z))
			mnx, mxx = math.min(mnx, l.X), math.max(mxx, l.X)
			mnz, mxz = math.min(mnz, l.Z), math.max(mxz, l.Z)
		end
		-- cell i's stud spans x0 + i - 0.5 +- foot
		for i = math.max(1, math.ceil(mnx - x0 + 0.5 - foot)), math.min(nx, math.floor(mxx - x0 + 0.5 + foot)) do
			local cx = x0 + i - 0.5
			if cx + foot > mnx and cx - foot < mxx then
				for j = math.max(1, math.ceil(mnz - z0 + 0.5 - foot)), math.min(nz, math.floor(mxz - z0 + 0.5 + foot)) do
					local cz = z0 + j - 0.5
					if cz + foot > mnz and cz - foot < mxz then
						free[i][j] = false
					end
				end
			end
		end
	end
	cellsOf(face, function(k)
		local set = index[k]
		if set then
			for p in set do
				cover(p)
			end
		end
	end)
	for p in big do
		cover(p)
	end
	local function fits(i: number, j: number, w: number, d: number): boolean
		if i + w - 1 > nx or j + d - 1 > nz then
			return false
		end
		for a = i, i + w - 1 do
			for b = j, j + d - 1 do
				if not free[a][b] then
					return false
				end
			end
		end
		return true
	end
	for _, s in SIZES do
		local w, d = s[1], s[2]
		local rotated = w < d
		local template = tiles:FindFirstChild(("%s_%dx%d"):format(LOD, math.max(w, d), math.min(w, d))) :: BasePart?
		if template then
			for i = 1, nx do
				for j = 1, nz do
					if fits(i, j, w, d) then
						for a = i, i + w - 1 do
							for b = j, j + d - 1 do
								free[a][b] = false
							end
						end
						local t = template:Clone()
						local lx, lz = x0 + i - 1 + w / 2, z0 + j - 1 + d / 2
						t.CFrame = cf * CFrame.new(lx, top + (t:GetAttribute("Lift") :: number), lz)
							* (if rotated then CFrame.Angles(0, math.pi / 2, 0) else CFrame.identity)
						t.Color = part.Color
						t.Material = part.Material
						t.MaterialVariant = part.MaterialVariant
						t.Transparency = part.Transparency
						t.Parent = chunkAt(t.Position).model
						table.insert(e.tiles, t)
					end
				end
			end
		end
	end
end

local function chunksOf(part: BasePart): { Chunk }
	-- every chunk the part's top face overlaps (big parts span several)
	local out = {}
	local half = part.Size / 2
	local seen = {}
	local step = C.ChunkSize / 2
	for x = -half.X, half.X + 0.01, math.max(step, 1) do
		for z = -half.Z, half.Z + 0.01, math.max(step, 1) do
			local ch = chunkAt(part.CFrame:PointToWorldSpace(Vector3.new(math.min(x, half.X), half.Y, math.min(z, half.Z))))
			if not seen[ch] then
				seen[ch] = true
				table.insert(out, ch)
			end
		end
	end
	return out
end

local function add(inst: Instance)
	if not inst:IsA("BasePart") or entries[inst] then
		return
	end
	local part = inst :: BasePart
	if not boxes[part] then
		indexAdd(part)
	end
	local e: Entry = { part = part, tiles = {}, built = false, chunks = {}, oldTop = part.TopSurface }
	entries[part] = e
	for _, ch in chunksOf(part) do
		ch.parts[part] = true
		e.chunks[ch] = true
	end
end

local function remove(inst: Instance)
	local e = entries[inst :: BasePart]
	if not e then
		return
	end
	clear(e)
	for ch in e.chunks do
		ch.parts[e.part] = nil
	end
	entries[e.part] = nil
end

-- the flat texture goes only while a raised layer covers this part
local function refreshTop(e: Entry)
	local anyShown = false
	for c in e.chunks do
		anyShown = anyShown or c.shown
	end
	e.part.TopSurface = if anyShown and #e.tiles > 0 then Enum.SurfaceType.Smooth else e.oldTop
end

local function setShown(ch: Chunk, on: boolean)
	ch.shown = on
	for part in ch.parts do
		local e = entries[part]
		if e then
			if on and not e.built then
				build(e)
			end
			refreshTop(e)
		end
	end
	ch.model.Parent = if on then root else nil
end

-- a part appearing or going can open or cover cells: redo the faces it touches (once things settle)
local dirty: { [Entry]: boolean } = {}
local dirtyAt = 0
local function touched(b: Box?)
	if not b then
		return
	end
	for _, e in entries do
		local face = boxes[e.part]
		if face and e.built and touchesLayer(b, face) then
			dirty[e] = true
			dirtyAt = os.clock()
		end
	end
end

workspace.DescendantAdded:Connect(function(d)
	if canCover(d) then
		touched(indexAdd(d :: BasePart))
	end
end)
workspace.DescendantRemoving:Connect(function(d)
	if d:IsA("BasePart") and boxes[d :: BasePart] then
		touched(indexRemove(d :: BasePart))
	end
end)

-- (connected first: the scan below yields, and parts added meanwhile must not be missed)
for i, d in workspace:GetDescendants() do
	if canCover(d) then
		indexAdd(d :: BasePart)
	end
	if i % 4000 == 0 then
		task.wait() -- (a big map: don't freeze the first frames)
	end
end
for _, p in CollectionService:GetTagged(C.Tag) do
	add(p)
end
CollectionService:GetInstanceAddedSignal(C.Tag):Connect(add)
CollectionService:GetInstanceRemovedSignal(C.Tag):Connect(remove)

while true do
	task.wait(C.CheckEvery)
	if next(dirty) and os.clock() - dirtyAt > C.RebuildDelay then
		for e in dirty do
			if entries[e.part] == e then
				build(e)
				refreshTop(e)
			end
		end
		table.clear(dirty)
	end
	local cam = workspace.CurrentCamera
	if cam then
		local at = cam.Focus.Position
		local n = 0
		for _, ch in chunks do
			local d = Vector2.new(ch.centre.X - at.X, ch.centre.Z - at.Z).Magnitude
			local near = d < RADIUS
			local far = d > RADIUS + C.Hysteresis
			if near and not ch.shown then
				setShown(ch, true)
				n += 1
			elseif far and ch.shown then
				setShown(ch, false)
			end
			if n >= C.BuildPerStep then
				break -- spread a big reveal over a few steps
			end
		end
	end
end
