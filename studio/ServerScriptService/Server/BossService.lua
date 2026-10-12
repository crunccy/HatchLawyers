--!strict
-- Zone bosses (docs/BOSSES.md, Config.Bosses; built 2026-10-12): one boss roams each egg zone. It strolls short legs
-- inside its zone (Margin studs inside the zone's Bounds - never the Safe Zone, a gate, firms or incubators), stops
-- now and then (an idle), and when a player comes within TriggerRange (and AttackEvery has passed) it turns to them,
-- WINDS UP (Windup s: the clients show a warning on the floor and play a sound) and ATTACKS:
--   "Cone" = Radius studs in front of it, Angle degrees wide (The Senior Partner's briefcase swing)
--   "Ring" = RingRadius / Radius studs all round (Barrister Bulldog's bark, the Eclipse's gavel orbit)
--   "Slam" = hops onto where the target stood when it jumped, Radius round the landing (Judge Martello)
--   "Line" = rolls / charges Length studs at the target, Width wide, then Dizzy s (Big Cheese, the Megalodon)
--   "Pull" = drags everyone within Radius in for PullTime s; its middle (Inner) is a hit (Chief Justice Eclipse)
-- A boss whose Attack is a list takes turns. State attributes add AttackKind (this attack) and Target (where a
-- Slam lands / a Line ends).
-- Hits are decided HERE, from where everyone stands at that moment (never the client's word). TOUCHING the boss's
-- body (its Hitbox) is a hit too. A hit RAGDOLLS the player (their client, RagdollTime s, flung away) and knocks
-- every egg they carry out of their arms (ZoneService.dropAll: loose eggs anyone can grab); then they can't be hit
-- for SafeAfterHit s and this boss leaves them alone for IgnoreAfterHit s. No text anywhere (user's call).
-- The bosses are DRAWN by every client (StarterPlayerScripts.Bosses) from ReplicatedStorage.BossStates.<Model>
-- (a Configuration whose attributes are the boss's state), so the server never moves any parts:
--   From / To (Vector3), MoveStart / MoveEnd (server time), Yaw (radians, the way it faces),
--   State ("walk" | "idle" | "windup" | "attack" | "dizzy" | "recover"), StateStart / StateEnd, Idle (which idle),
--   plus its fixed settings (Model, Zone, Attack, Radius, Angle, Windup, Color, Scale = how much bigger than the model).
-- Remotes.Bosses, server -> all clients: ("Hit", { userId, from, away, eggs = { { egg, golden, at } }, t, ragdoll })
-- ("Grab", { userId, at, egg, golden }).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config) :: any
local ZoneService = require(script.Parent.ZoneService) :: any

local CFG = Config.Bosses
local BossService = {}

type Boss = {
	def: any,
	bounds: { number }, -- the zone's land: minX, minZ, maxX, maxZ
	area: { number }, -- where the boss may walk: minX, minZ, maxX, maxZ
	floorY: number,
	state: Configuration,
	from: Vector3,
	to: Vector3,
	moveStart: number,
	moveEnd: number,
	yaw: number,
	alongX: boolean, -- the lane runs along X (else along Z)
	areaUV: { number }, -- `area` in lane terms: uMin, vMin, uMax, vMax
	dirX: number, -- which way along the lane it's heading (-1 / 1)
	zig: number, -- the Bulldog's zig-zag side (-1 / 1)
	nextAttack: number,
	ignore: { [Player]: number }, -- players it leaves alone until then (just hit)
	attackIndex: number, -- which of its attacks it used last (a list takes turns)
	airborne: boolean, -- mid-hop (a Slam): its body can't be touched
}

local rng = Random.new()
local Remote: RemoteEvent
local safeUntil: { [Player]: number } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- the facing for a direction: CFrame.Angles(0, yaw, 0) looks along (-sin yaw, 0, -cos yaw)
local function yawOf(dir: Vector3, fallback: number): number
	if dir.Magnitude < 0.05 then
		return fallback
	end
	return math.atan2(-dir.X, -dir.Z)
end

local function posAt(b: Boss, t: number): Vector3
	if b.moveEnd <= b.moveStart then
		return b.to
	end
	local a = math.clamp((t - b.moveStart) / (b.moveEnd - b.moveStart), 0, 1)
	return b.from:Lerp(b.to, a)
end

local function setState(b: Boss, state: string, duration: number)
	local t = now()
	b.state:SetAttribute("State", state)
	b.state:SetAttribute("StateStart", t)
	b.state:SetAttribute("StateEnd", t + duration)
end

local function setMove(b: Boss, from: Vector3, to: Vector3, duration: number)
	local t = now()
	b.from, b.to, b.moveStart, b.moveEnd = from, to, t, t + duration
	b.state:SetAttribute("From", from)
	b.state:SetAttribute("To", to)
	b.state:SetAttribute("MoveStart", t)
	b.state:SetAttribute("MoveEnd", t + duration)
	b.state:SetAttribute("Yaw", b.yaw)
end

local function clampToArea(b: Boss, x: number, z: number): Vector3
	return Vector3.new(math.clamp(x, b.area[1], b.area[3]), b.floorY, math.clamp(z, b.area[2], b.area[4]))
end

-- a point in lane terms: u = along the lane, v = across it (the zone's longer side is "along")
local function uv(b: Boss, p: Vector3): (number, number)
	if b.alongX then
		return p.X, p.Z
	end
	return p.Z, p.X
end

local function fromUV(b: Boss, u: number, v: number): Vector3
	if b.alongX then
		return clampToArea(b, u, v)
	end
	return clampToArea(b, v, u)
end

-- players standing in this boss's zone (alive, with a character)
local function playersInZone(b: Boss): { { player: Player, root: BasePart } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local p = root.Position
			if p.X >= b.bounds[1] and p.X <= b.bounds[3] and p.Z >= b.bounds[2] and p.Z <= b.bounds[4] and p.Y < b.floorY + 30 then
				table.insert(list, { player = player, root = root })
			end
		end
	end
	return list
end

------------------------------------------------------------------ moving
-- the next short leg (at most ~2 s), in the boss's own style
local function nextLeg(b: Boss, here: Vector3, chase: Vector3?): Vector3
	if chase and rng:NextNumber() < (b.def.Chase or 0.45) then
		-- hunt a player in the zone, stopping just short of them (its front a few studs off them; walking INTO a
		-- player is a hit - the touch check below - but it doesn't aim to trample)
		local d = flat(chase - here)
		local front = ((b.def.Hitbox and b.def.Hitbox.Front) or 1) * (b.def.Scale or 1)
		local len = math.min(d.Magnitude - front - 6, b.def.WalkSpeed * 2)
		if len > 1 then
			local p = here + d.Unit * len
			return clampToArea(b, p.X, p.Z)
		end
	end
	-- (u = along the lane, v = across it: the lane may run along X or along Z - it runs south since 2026-10-12)
	local u, v = uv(b, here)
	local uMin, vMin, uMax, vMax = table.unpack(b.areaUV)
	if u <= uMin + 2 then
		b.dirX = 1
	elseif u >= uMax - 2 then
		b.dirX = -1
	elseif rng:NextNumber() < 0.12 then
		b.dirX = -b.dirX
	end
	local step = b.def.WalkSpeed * rng:NextNumber(1.2, 2)
	local mid = (vMin + vMax) / 2
	if b.def.Attack == "Ring" then
		-- the Bulldog waddles in zig-zags across the lane
		b.zig = -b.zig
		return fromUV(b, u + b.dirX * step * 0.8, mid + b.zig * rng:NextNumber(4, math.max(5, (vMax - vMin) / 2)))
	end
	-- the Senior Partner strolls the middle of the lane
	local band = b.def.StayNearMiddle or 12
	return fromUV(b, u + b.dirX * step, math.clamp(v + rng:NextNumber(-4, 4), mid - band, mid + band))
end

local function walkTo(b: Boss, here: Vector3, goal: Vector3): number
	local d = flat(goal - here)
	local duration = d.Magnitude / b.def.WalkSpeed
	b.yaw = yawOf(d, b.yaw)
	setMove(b, here, goal, duration)
	setState(b, "walk", duration)
	return duration
end

local function stand(b: Boss, here: Vector3)
	setMove(b, here, here, 0)
end

------------------------------------------------------------------ attacking
local function hit(b: Boss, player: Player, root: BasePart, from: Vector3, look: Vector3)
	local t = now()
	if (safeUntil[player] or 0) > t then
		return
	end
	safeUntil[player] = t + CFG.SafeAfterHit
	b.ignore[player] = t + (CFG.IgnoreAfterHit or 0)
	local eggs = ZoneService.dropAll(player, b.def.Zone, root.Position)
	local away = flat(root.Position - from)
	away = if away.Magnitude > 0.1 then away.Unit else look
	-- (the hit player's own client ragdolls them for RagdollTime s and flings them away)
	Remote:FireAllClients("Hit", { userId = player.UserId, from = from, away = away, eggs = eggs, t = t, ragdoll = CFG.RagdollTime or 0 })
end

-- Touching the boss's body (Config.Bosses.List[n].Hitbox, in model units x Scale: HalfWidth, Back, Front - the boss
-- faces -Z) is a hit too: running into it, or it walking over you, ragdolls you and knocks your eggs out.
local function touchLoop(b: Boss)
	local hb = b.def.Hitbox
	if not hb then
		return
	end
	local s = b.def.Scale or 1
	while b.state.Parent do
		task.wait(0.1)
		if b.airborne then
			continue -- (mid-hop, high above everyone)
		end
		local pos = posAt(b, now())
		local frame = CFrame.new(pos) * CFrame.Angles(0, b.yaw, 0)
		local look = frame.LookVector
		for _, p in playersInZone(b) do
			local rel = frame:PointToObjectSpace(p.root.Position)
			if math.abs(rel.X) <= hb.HalfWidth * s + 1.5 and rel.Z >= -(hb.Front * s + 1.5) and rel.Z <= hb.Back * s + 1.5
				and rel.Y < (hb.Height or 10) * s then
				hit(b, p.player, p.root, pos, look)
			end
		end
	end
end

-- which attack this time (a boss with a list takes turns)
local function nextAttackKind(b: Boss): string
	local a = b.def.Attack
	if type(a) == "table" then
		b.attackIndex = (b.attackIndex % #a) + 1
		return a[b.attackIndex]
	end
	return a
end

-- everyone standing in a one-moment shape right now: "Cone" (in front) or a circle of `radius` round `centre`
local function hitShape(b: Boss, kind: string, centre: Vector3, radius: number)
	local look = Vector3.new(-math.sin(b.yaw), 0, -math.cos(b.yaw))
	local cosHalf = math.cos(math.rad((b.def.Angle or 360) / 2))
	for _, p in playersInZone(b) do
		local d = flat(p.root.Position - centre)
		local dist = d.Magnitude
		local inside = dist <= radius
		if inside and kind == "Cone" and dist > 3 * (b.def.Scale or 1) then -- (right under it always counts)
			inside = d.Unit:Dot(look) >= cosHalf
		end
		if inside then
			hit(b, p.player, p.root, centre, look)
		end
	end
end

local function attack(b: Boss, here: Vector3, target: BasePart)
	local def = b.def
	local kind = nextAttackKind(b)
	b.yaw = yawOf(flat(target.Position - here), b.yaw)
	b.state:SetAttribute("AttackKind", kind)
	b.state:SetAttribute("Target", here)
	if kind == "Slam" then
		-- jumps at where the target stands NOW and comes down there at the end of the windup (moving dodges it)
		local spot = clampToArea(b, target.Position.X, target.Position.Z)
		b.state:SetAttribute("Target", spot)
		b.airborne = true
		setMove(b, here, spot, def.Windup)
		setState(b, "windup", def.Windup)
		task.wait(def.Windup)
		b.airborne = false
		stand(b, spot)
		setState(b, "attack", 0.45)
		hitShape(b, "Ring", spot, def.Radius)
		task.wait(0.45)
	elseif kind == "Line" then
		-- rolls / charges straight at the target, Length studs (shorter at the zone's edge), Width wide
		local dir = flat(target.Position - here)
		dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(-math.sin(b.yaw), 0, -math.cos(b.yaw))
		local goal = clampToArea(b, here.X + dir.X * def.Length, here.Z + dir.Z * def.Length)
		b.state:SetAttribute("Target", goal)
		stand(b, here)
		setState(b, "windup", def.Windup)
		task.wait(def.Windup)
		local duration = math.max(0.25, flat(goal - here).Magnitude / def.LineSpeed)
		setMove(b, here, goal, duration)
		setState(b, "attack", duration)
		local stop = now() + duration
		while now() < stop do -- the hit sweeps along with it
			local pos = posAt(b, now())
			for _, p in playersInZone(b) do
				if flat(p.root.Position - pos).Magnitude <= def.Width / 2 then
					hit(b, p.player, p.root, pos, dir)
				end
			end
			task.wait(0.05)
		end
		stand(b, goal)
		if def.Dizzy then
			setState(b, "dizzy", def.Dizzy) -- (helpless for a moment: a free window to run past)
			task.wait(def.Dizzy)
		end
	elseif kind == "Pull" then
		-- everyone within Radius is dragged toward it (each client pulls its own character) for PullTime s; the
		-- middle (Inner) is a hit. Walking straight out escapes it.
		stand(b, here)
		setState(b, "windup", def.Windup)
		task.wait(def.Windup)
		setState(b, "attack", def.PullTime)
		local stop = now() + def.PullTime
		while now() < stop do
			hitShape(b, "Ring", here, def.Inner)
			task.wait(0.1)
		end
	else -- "Cone" / "Ring"
		stand(b, here)
		setState(b, "windup", def.Windup)
		task.wait(def.Windup)
		setState(b, "attack", 0.45)
		hitShape(b, kind, here, if kind == "Ring" then (def.RingRadius or def.Radius) else def.Radius)
		task.wait(0.45)
	end
	setState(b, "recover", 0.6)
	task.wait(0.6)
	b.nextAttack = now() + def.AttackEvery
end

local function run(b: Boss)
	while b.state.Parent do
		local here = posAt(b, now())
		local targets = playersInZone(b)
		local nearest: BasePart? = nil
		local nearestD = math.huge
		local t = now()
		for _, p in targets do
			local d = flat(p.root.Position - here).Magnitude
			if d < nearestD and (b.ignore[p.player] or 0) <= t then -- (a player it just hit gets a head start)
				nearest, nearestD = p.root, d
			end
		end
		if nearest and nearestD <= CFG.TriggerRange and now() >= b.nextAttack then
			attack(b, here, nearest)
		elseif (not nearest or nearestD > CFG.TriggerRange * 2) and rng:NextNumber() < 0.16 then
			-- (no dawdling while someone's close)
			-- an idle: the Senior Partner checks his pocket watch; the Bulldog sniffs the ground or sits to scratch
			stand(b, here)
			b.state:SetAttribute("Idle", if b.def.Attack == "Ring" and rng:NextNumber() < 0.5 then "scratch" else "check")
			local dur = rng:NextNumber(1.8, 2.8)
			setState(b, "idle", dur)
			task.wait(dur)
		else
			local dur = walkTo(b, here, nextLeg(b, here, nearest and nearest.Position or nil))
			task.wait(math.max(dur, 0.3))
		end
	end
end

------------------------------------------------------------------ start
function BossService.start()
	if not CFG then
		return
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Bosses") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Bosses"
		Remote.Parent = remotes
	end
	local old = ReplicatedStorage:FindFirstChild("BossStates")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "BossStates"
	folder.Parent = ReplicatedStorage

	ZoneService.onGrab = function(player: Player, at: Vector3, egg: string, golden: boolean)
		Remote:FireAllClients("Grab", { userId = player.UserId, at = at, egg = egg, golden = golden })
	end

	local zonesRoot = workspace:FindFirstChild("Zones")
	for _, def in CFG.List do
		local zoneDef = nil
		for _, z in Config.Zones.List do
			if z.Id == def.Zone then
				zoneDef = z
			end
		end
		local zoneFolder = zonesRoot and zonesRoot:FindFirstChild(def.Zone)
		if not zoneDef or not zoneFolder then
			continue -- (its zone isn't built yet)
		end
		local bb = zoneDef.Bounds
		local bounds = { math.min(bb[1], bb[3]), math.min(bb[2], bb[4]), math.max(bb[1], bb[3]), math.max(bb[2], bb[4]) }
		-- Margin.X keeps it off the zone's ends (along the lane), Margin.Z off the walls (across) - named from when the
		-- lane ran along X; the zone's longer side is "along"
		local alongX = (bounds[3] - bounds[1]) >= (bounds[4] - bounds[2])
		local mAlong, mAcross = CFG.Margin.X, CFG.Margin.Z
		local area = if alongX
			then { bounds[1] + mAlong, bounds[2] + mAcross, bounds[3] - mAlong, bounds[4] - mAcross }
			else { bounds[1] + mAcross, bounds[2] + mAlong, bounds[3] - mAcross, bounds[4] - mAlong }
		local areaUV = if alongX then { area[1], area[2], area[3], area[4] } else { area[2], area[1], area[4], area[3] }
		-- the floor height in the middle of the zone
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { zoneFolder:FindFirstChild("Floor") or zoneFolder }
		local cx, cz = (area[1] + area[3]) / 2, (area[2] + area[4]) / 2
		local ray = workspace:Raycast(Vector3.new(cx, 60, cz), Vector3.new(0, -120, 0), params)
		local floorY = if ray then ray.Position.Y else 0

		local state = Instance.new("Configuration")
		state.Name = def.Model
		local firstAttack = if type(def.Attack) == "table" then def.Attack[1] else def.Attack
		for k, v in { Model = def.Model, Zone = def.Zone, Attack = firstAttack, AttackKind = firstAttack, Radius = def.Radius or 10,
			Angle = def.Angle or 360, Windup = def.Windup, Color = def.Color, FloorY = floorY, Scale = def.Scale or 1,
			RingRadius = def.RingRadius or def.Radius or 10, Length = def.Length or 0, Width = def.Width or 0,
			Inner = def.Inner or 0, PullSpeed = def.PullSpeed or 0, HopHeight = def.HopHeight or 0 } do
			state:SetAttribute(k, v)
		end
		local shift = rng:NextNumber(-40, 40) -- (somewhere along the middle of the lane)
		local start = if alongX then Vector3.new(cx + shift, floorY, cz) else Vector3.new(cx, floorY, cz + shift)
		local b: Boss = {
			def = def, bounds = bounds, area = area, alongX = alongX, areaUV = areaUV, floorY = floorY, state = state,
			from = start, to = start, moveStart = 0, moveEnd = 0, yaw = math.pi / 2, dirX = -1, zig = 1,
			nextAttack = now() + 3, ignore = {}, attackIndex = 0, airborne = false,
		}
		setMove(b, start, start, 0)
		setState(b, "idle", 1)
		state:SetAttribute("Idle", "check")
		state.Parent = folder
		task.spawn(function()
			while state.Parent do
				local ok, err = pcall(touchLoop, b)
				if not ok then
					warn("[BossService] " .. def.Model .. " touch check tripped (restarting):", err)
				end
				task.wait(1)
			end
		end)
		task.spawn(function()
			while state.Parent do
				local ok, err = pcall(run, b)
				if not ok then
					warn("[BossService] " .. def.Model .. " tripped (restarting):", err)
					task.wait(2)
				end
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		safeUntil[player] = nil
	end)
end

return BossService
