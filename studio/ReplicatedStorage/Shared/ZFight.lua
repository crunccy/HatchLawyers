--!strict
-- Finds and fixes z-fighting between Part-built pieces (crnuch's bug report 6, 2026-10-16): two block faces that
-- point the same way, lie in the same plane and overlap, with a different colour / material / surface, flicker as
-- the camera moves. Faces in one plane that overlap form a group: the smallest face (the detail) stays where it is
-- and every face that clashes with one already placed moves back a level (PUSH studs a level: that side of the part
-- shrinks, the opposite face stays put), so the details stand proud and no two clashing faces stay level. Shrinking
-- can't make new overlaps (growing a part sideways would: a sliver along its neighbours); a part too thin to shrink
-- grows outward instead. A chain of overlapping pieces (a palm trunk, a row of tiles) needs one level. Only plain
-- block Parts are touched (no MeshParts: the Blender meshes don't have this problem).
--   ZFight.scan(roots, opts?) -> { moves }   (each { part, axis, sign, level }: level < 0 shrinks, > 0 grows)
--   ZFight.fix(roots, opts?) -> number of faces moved
-- opts.only(part) -> boolean: the parts allowed to move (default: any); the others stay level.
-- opts.noYield: never task.wait (for callers that must not yield; keep those to a few thousand parts).
-- Used once in Edit mode on the map + templates, by the Studio builders (tools/zones/Build*.lua, BrickKit) on what
-- they build, by FirmBuilder on every firm (the stage front, the kit pieces and the plot's decor meet there) and by
-- MinigameClient.Scene on each cinematic prop it builds. Lives in Shared so the client can use it;
-- ServerScriptService.Server.ZFight just returns this module (the builders require that path).

local ZFight = {}

ZFight.PUSH = 0.04
local EPS = 0.012 -- faces closer than this are "level"
local MIN_OVERLAP = 0.02
local MIN_KEEP = 0.04 -- a part never shrinks thinner than this (the characters' face plates are ~0.08 thick)

-- (cu, cv) = the face's centre in the plane, (e1u, e1v) / (e2u, e2v) = its half edges: a face turned within the plane
-- (a tilted arm, a part rotated 30 degrees) is tested as the rectangle it is, not its bounding box
type Face = { p: BasePart, d: number, u0: number, u1: number, v0: number, v1: number, axis: number, sign: number, area: number,
	cu: number, cv: number, e1u: number, e1v: number, e2u: number, e2v: number }

local SURFACE = {
	[1] = { [1] = "RightSurface", [-1] = "LeftSurface" },
	[2] = { [1] = "TopSurface", [-1] = "BottomSurface" },
	[3] = { [1] = "BackSurface", [-1] = "FrontSurface" }, -- +Z local is the Back face
}

local function q(x: number, step: number): number
	return math.floor(x / step + 0.5)
end

local function basis(n: Vector3): (Vector3, Vector3)
	local ref = if math.abs(n.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
	local u = n:Cross(ref).Unit
	return u, n:Cross(u)
end

local function eligible(p: Instance): boolean
	return p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 0.95
end

-- faces that would show the same pixels differently. A MaterialVariant (the characters' BrickStuds) differs from
-- plain Plastic of the same colour, and two textured faces flicker even when everything matches: each part tiles
-- its texture from its own position, so the stud grids of two overlapping parts don't line up (2026-10-18).
-- the two face rectangles overlap by more than MIN_OVERLAP (separating axes: u, v and both rectangles' edges)
local function overlaps(a: Face, b: Face): boolean
	local du, dv = b.cu - a.cu, b.cv - a.cv
	for _, n in { { a.e1u, a.e1v }, { a.e2u, a.e2v }, { b.e1u, b.e1v }, { b.e2u, b.e2v } } do
		local len = math.sqrt(n[1] * n[1] + n[2] * n[2])
		if len > 1e-6 then
			local nu, nv = n[1] / len, n[2] / len
			local ra = math.abs(a.e1u * nu + a.e1v * nv) + math.abs(a.e2u * nu + a.e2v * nv)
			local rb = math.abs(b.e1u * nu + b.e1v * nv) + math.abs(b.e2u * nu + b.e2v * nv)
			if ra + rb - math.abs(du * nu + dv * nv) <= MIN_OVERLAP then
				return false
			end
		end
	end
	return true
end

local function differ(a: Face, b: Face): boolean
	local pa, pb = a.p, b.p
	if pa.Color ~= pb.Color or pa.Material ~= pb.Material or math.abs(pa.Transparency - pb.Transparency) > 0.01 then
		return true
	end
	if pa.MaterialVariant ~= pb.MaterialVariant or pa.MaterialVariant ~= "" then
		return true
	end
	local sa = (pa :: any)[SURFACE[a.axis][a.sign]]
	local sb = (pb :: any)[SURFACE[b.axis][b.sign]]
	return sa ~= sb
end

type Opts = { only: ((BasePart) -> boolean)?, noYield: boolean? }

function ZFight.scan(roots: { Instance }, opts: Opts?): { any }
	local only = opts and opts.only
	local yield = not (opts and opts.noYield)
	local byNormal: { [string]: { Face } } = {}
	local count = 0
	for _, root in roots do
		local list = root:GetDescendants()
		if root:IsA("BasePart") then
			table.insert(list, root)
		end
		for _, p in list do
			if not eligible(p) then
				continue
			end
			local part = p :: BasePart
			local cf, half = part.CFrame, part.Size / 2
			local axes = {
				{ cf.RightVector, half.X, cf.UpVector, half.Y, cf.LookVector, half.Z },
				{ cf.UpVector, half.Y, cf.RightVector, half.X, cf.LookVector, half.Z },
				{ -cf.LookVector, half.Z, cf.RightVector, half.X, cf.UpVector, half.Y }, -- +Z local
			}
			for axis, a in axes do
				for _, sign in { 1, -1 } do
					local n = a[1] * sign
					local c = cf.Position + n * a[2]
					local u, v = basis(n)
					local cu, cv = u:Dot(c), v:Dot(c)
					local eu = math.abs(u:Dot(a[3])) * a[4] + math.abs(u:Dot(a[5])) * a[6]
					local ev = math.abs(v:Dot(a[3])) * a[4] + math.abs(v:Dot(a[5])) * a[6]
					local key = q(n.X, 0.01) .. "," .. q(n.Y, 0.01) .. "," .. q(n.Z, 0.01)
					local b = byNormal[key]
					if not b then
						b = {}
						byNormal[key] = b
					end
					local e1, e2 = a[3] * a[4], a[5] * a[6]
					table.insert(b, { p = part, d = n:Dot(c), u0 = cu - eu, u1 = cu + eu, v0 = cv - ev, v1 = cv + ev, axis = axis, sign = sign, area = a[4] * a[6],
						cu = cu, cv = cv, e1u = u:Dot(e1), e1v = v:Dot(e1), e2u = u:Dot(e2), e2v = v:Dot(e2) })
				end
			end
			count += 1
			if yield and count % 4000 == 0 then
				task.wait()
			end
		end
	end

	local pushes = {}
	local shrunk: { [BasePart]: { number } } = {} -- studs already taken off a part along each axis
	local work = 0
	-- one plane at a time: faces of one normal, sorted by distance, split where the gap is bigger than EPS
	local function plane(faces: { Face })
		if #faces < 2 then
			return
		end
		table.sort(faces, function(x, y)
			return x.u0 < y.u0
		end)
		local clash: { [Face]: { Face } } = {}
		local any = false
		for i = 1, #faces do
			local A = faces[i]
			for j = i + 1, #faces do
				local B = faces[j]
				if B.u0 >= A.u1 then
					break
				end
				-- (a group can chain faces further apart than EPS: check each pair)
				if A.p ~= B.p and math.abs(A.d - B.d) < EPS and math.min(A.u1, B.u1) - math.max(A.u0, B.u0) > MIN_OVERLAP
					and math.min(A.v1, B.v1) - math.max(A.v0, B.v0) > MIN_OVERLAP and differ(A, B) and overlaps(A, B) then
					clash[A] = clash[A] or {}
					clash[B] = clash[B] or {}
					table.insert(clash[A], B)
					table.insert(clash[B], A)
					any = true
				end
			end
		end
		if not any then
			return
		end
		-- place the parts that can't move first (they stay level), then the smallest faces; each takes the nearest
		-- level no clashing face already placed has: 0, then back (-1, -2, ...) while the part stays thick enough,
		-- else out (+1, +2, ...)
		local order = {}
		for f in clash do
			table.insert(order, f)
		end
		table.sort(order, function(x, y)
			local fx, fy = not only or only(x.p), not only or only(y.p)
			if fx ~= fy then
				return not fx
			end
			return x.area < y.area
		end)
		local level: { [Face]: number } = {}
		for _, f in order do
			local L = 0
			if not only or only(f.p) then
				local used: { [number]: boolean } = {}
				for _, o in clash[f] do
					if level[o] then
						used[level[o]] = true
					end
				end
				if used[0] then
					local taken = shrunk[f.p] or { 0, 0, 0 }
					shrunk[f.p] = taken
					local size = if f.axis == 1 then f.p.Size.X elseif f.axis == 2 then f.p.Size.Y else f.p.Size.Z
					local room = size - taken[f.axis] - MIN_KEEP
					L = -1
					while used[L] do
						L -= 1
					end
					if -L * ZFight.PUSH > room then
						L = 1
						while used[L] do
							L += 1
						end
					else
						taken[f.axis] -= L * ZFight.PUSH
					end
				end
			end
			level[f] = L
			if L ~= 0 then
				table.insert(pushes, { part = f.p, axis = f.axis, sign = f.sign, level = L })
			end
		end
	end
	for _, faces in byNormal do
		table.sort(faces, function(x, y)
			return x.d < y.d
		end)
		local i = 1
		while i <= #faces do
			local j = i
			while j < #faces and faces[j + 1].d - faces[j].d < EPS do
				j += 1
			end
			if j > i then
				plane(table.move(faces, i, j, 1, {}))
			end
			work += j - i + 1
			if yield and work > 20000 then
				work = 0
				task.wait()
			end
			i = j + 1
		end
	end
	return pushes
end

-- moves one face of the part out by amount (in when negative; axis 1/2/3 = local X/Y/Z, sign +-1), keeping the
-- opposite face put
local function push(p: BasePart, axis: number, sign: number, amount: number)
	local grow = Vector3.new(if axis == 1 then amount else 0, if axis == 2 then amount else 0, if axis == 3 then amount else 0)
	local offset = grow / 2 * sign
	local cf = p.CFrame * CFrame.new(offset)
	p.Size += grow
	p.CFrame = cf
end

function ZFight.fix(roots: { Instance }, opts: Opts?): number
	local pushes = ZFight.scan(roots, opts)
	for _, f in pushes do
		push(f.part, f.axis, f.sign, ZFight.PUSH * f.level)
	end
	return #pushes
end

return ZFight
