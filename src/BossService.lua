--!strict
-- Zone bosses (docs/BOSSES.md, Config.Bosses; built 2026-10-12): one boss roams each egg zone. It strolls short legs
-- inside its zone (Margin studs inside the zone's Bounds - never the Safe Zone, a gate, firms or incubators), stops
-- now and then (an idle), and when a player comes within TriggerRange (and AttackEvery has passed) it turns to them,
-- WINDS UP (Windup s: the clients show a warning on the floor and play a sound) and ATTACKS:
--   "Cone" = Radius studs in front of it, Angle degrees wide (The Senior Partner's briefcase swing)
--   "Ring" = Radius studs all round (Barrister Bulldog's bark).
-- Hits are decided HERE, from where everyone stands at that moment (never the client's word). A hit knocks every
-- egg the player carries out of their arms (ZoneService.dropAll: loose eggs anyone can grab), then the player can't be
-- hit for SafeAfterHit s. A player carrying nothing just gets bumped. No text anywhere (user's call).
-- The bosses are DRAWN by every client (StarterPlayerScripts.Bosses) from ReplicatedStorage.BossStates.<Model>
-- (a Configuration whose attributes are the boss's state), so the server never moves any parts:
--   From / To (Vector3), MoveStart / MoveEnd (server time), Yaw (radians, the way it faces),
--   State ("walk" | "idle" | "windup" | "attack" | "recover"), StateStart / StateEnd, Idle (which idle),
--   plus its fixed settings (Model, Zone, Attack, Radius, Angle, Windup, Color, Scale = how much bigger than the model).
-- Remotes.Bosses, server -> all clients: ("Hit", { userId, from, away, eggs = { { egg, golden, at } }, t })
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
	dirX: number, -- which way along the lane it's heading (-1 / 1)
	zig: number, -- the Bulldog's zig-zag side (-1 / 1)
	nextAttack: number,
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
		-- hunt a player in the zone, stopping just short of them
		local d = flat(chase - here)
		local len = math.min(d.Magnitude - 4 * (b.def.Scale or 1), b.def.WalkSpeed * 2)
		if len > 1 then
			local p = here + d.Unit * len
			return clampToArea(b, p.X, p.Z)
		end
	end
	if here.X <= b.area[1] + 2 then
		b.dirX = 1
	elseif here.X >= b.area[3] - 2 then
		b.dirX = -1
	elseif rng:NextNumber() < 0.12 then
		b.dirX = -b.dirX
	end
	local step = b.def.WalkSpeed * rng:NextNumber(1.2, 2)
	if b.def.Attack == "Ring" then
		-- the Bulldog waddles in zig-zags across the lane
		b.zig = -b.zig
		local zz = b.zig * rng:NextNumber(4, math.max(5, (b.area[4] - b.area[2]) / 2))
		return clampToArea(b, here.X + b.dirX * step * 0.8, (b.area[2] + b.area[4]) / 2 + zz)
	end
	-- the Senior Partner strolls the middle of the lane
	local mid = (b.area[2] + b.area[4]) / 2
	local band = b.def.StayNearMiddle or 12
	local zz = math.clamp(here.Z + rng:NextNumber(-4, 4), mid - band, mid + band)
	return clampToArea(b, here.X + b.dirX * step, zz)
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
	local eggs = ZoneService.dropAll(player, b.def.Zone, root.Position)
	local away = flat(root.Position - from)
	away = if away.Magnitude > 0.1 then away.Unit else look
	Remote:FireAllClients("Hit", { userId = player.UserId, from = from, away = away, eggs = eggs, t = t })
end

local function attack(b: Boss, here: Vector3, target: BasePart)
	b.yaw = yawOf(flat(target.Position - here), b.yaw)
	stand(b, here)
	setState(b, "windup", b.def.Windup)
	task.wait(b.def.Windup)
	setState(b, "attack", 0.45)
	local look = Vector3.new(-math.sin(b.yaw), 0, -math.cos(b.yaw))
	local cosHalf = math.cos(math.rad((b.def.Angle or 360) / 2))
	for _, p in playersInZone(b) do
		local d = flat(p.root.Position - here)
		local dist = d.Magnitude
		local inside = dist <= b.def.Radius
		if inside and b.def.Attack == "Cone" and dist > 3 * (b.def.Scale or 1) then -- (right under it always counts)
			inside = d.Unit:Dot(look) >= cosHalf
		end
		if inside then
			hit(b, p.player, p.root, here, look)
		end
	end
	task.wait(0.45)
	setState(b, "recover", 0.6)
	task.wait(0.6)
	b.nextAttack = now() + b.def.AttackEvery
end

local function run(b: Boss)
	while b.state.Parent do
		local here = posAt(b, now())
		local targets = playersInZone(b)
		local nearest: BasePart? = nil
		local nearestD = math.huge
		for _, p in targets do
			local d = flat(p.root.Position - here).Magnitude
			if d < nearestD then
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
		local area = { bounds[1] + CFG.Margin.X, bounds[2] + CFG.Margin.Z, bounds[3] - CFG.Margin.X, bounds[4] - CFG.Margin.Z }
		-- the floor height in the middle of the zone
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { zoneFolder:FindFirstChild("Floor") or zoneFolder }
		local cx, cz = (area[1] + area[3]) / 2, (area[2] + area[4]) / 2
		local ray = workspace:Raycast(Vector3.new(cx, 60, cz), Vector3.new(0, -120, 0), params)
		local floorY = if ray then ray.Position.Y else 0

		local state = Instance.new("Configuration")
		state.Name = def.Model
		for k, v in { Model = def.Model, Zone = def.Zone, Attack = def.Attack, Radius = def.Radius, Angle = def.Angle or 360,
			Windup = def.Windup, Color = def.Color, FloorY = floorY, Scale = def.Scale or 1 } do
			state:SetAttribute(k, v)
		end
		local start = Vector3.new(cx + rng:NextNumber(-40, 40), floorY, cz)
		local b: Boss = {
			def = def, bounds = bounds, area = area, floorY = floorY, state = state,
			from = start, to = start, moveStart = 0, moveEnd = 0, yaw = math.pi / 2, dirX = -1, zig = 1,
			nextAttack = now() + 3,
		}
		setMove(b, start, start, 0)
		setState(b, "idle", 1)
		state:SetAttribute("Idle", "check")
		state.Parent = folder
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
