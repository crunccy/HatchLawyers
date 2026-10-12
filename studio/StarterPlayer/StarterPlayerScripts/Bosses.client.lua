--!strict
-- Bosses (StarterPlayerScripts.Bosses, 2026-10-12): draws and animates the zone bosses that Server.BossService runs
-- (docs/BOSSES.md, Config.Bosses). Everything here is a picture - the server decides every move and every hit.
--   * each boss is a local clone of ReplicatedStorage.Bosses.<Model> (made in Blender: tools/blender/bosses.py),
--     posed every frame from ReplicatedStorage.BossStates.<Model>: where it walks, which way it faces, and its
--     state (walk / idle / windup / attack / recover). Its groups (Torso, Head, ArmL, LegL, ...) swing round their
--     joints: the Senior Partner strolls, checks his pocket watch, lifts the briefcase over his head and slams it
--     down; the Bulldog waddles, wags, sniffs or sits to scratch, puffs up and BARKS.
--   * WINDUP: a warning on the floor in the boss's colour (a fan in front for a Cone attack, a disc for a Ring) that
--     grows and pulses, plus a sound - always at least a second to get out of the way.
--   * ATTACK: a paper burst / a shockwave ring, a thump, a small camera shake nearby.
--   * HIT (Remotes.Bosses "Hit" - an attack, or touching the boss's body): a burst on the player; the hit player
--     RAGDOLLS (limp, flung away tumbling, up again after RagdollTime s); their eggs pop out of the
--     pile one by one, arc out, land with a squash, bounce and wait where the server put them (the server's own
--     LooseEgg appears there once it has landed). Nothing carried: a bump and a boing.
--   * LOOSE EGGS (tag "LooseEgg"): bob, spin slowly and glow so they read as "grab me"; blink in their last 5 s.
--   * GRAB ("Grab"): the egg hops into the grabber's arms.
-- No text anywhere (user's call): no names, no labels, no messages.

local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local CFG = Config.Bosses
if not CFG then
	return
end

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bosses", 60) :: RemoteEvent?
local States = ReplicatedStorage:WaitForChild("BossStates", 60)
local Library = ReplicatedStorage:WaitForChild("Bosses", 60)
if not Remote or not States or not Library then
	return
end

local visuals = Instance.new("Folder")
visuals.Name = "BossVisuals"
visuals.Parent = workspace

local DRAW_DISTANCE = 500 -- studs from the camera; further bosses aren't drawn (or posed)

------------------------------------------------------------------ little helpers
local function now(): number
	return workspace:GetServerTimeNow()
end

local function ease(a: number): number -- smooth in / out
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function easeOut(a: number): number
	a = math.clamp(a, 0, 1)
	return 1 - (1 - a) * (1 - a)
end

local function lerpAngle(a: number, b: number, t: number): number
	local d = (b - a + math.pi) % (math.pi * 2) - math.pi
	return a + d * t
end

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- licensed / built-in sounds only (the game's sound rule; rbxasset://sounds/swoosh.wav is NOT approved for this place).
-- { id, volume, speed, stop after (s)? }
local SOUNDS = {
	windup = { "rbxassetid://9045751375", 0.45, 1.5, 1.0 }, -- the Big Case alert, quick and cut short
	slam = { "rbxassetid://9125574353", 1, 0.62 }, -- the gavel knock, low
	bark = { "rbxassetid://9125574353", 1, 0.45 },
	hit = { "rbxassetid://9125574353", 0.8, 1.3 },
	boing = { "rbxasset://sounds/electronicpingshort.wav", 0.5, 0.55 },
	land = { "rbxassetid://9125574353", 0.25, 2.2 },
	grab = { "rbxasset://sounds/electronicpingshort.wav", 0.45, 1.6 },
}
local function playAt(pos: Vector3, kind: string)
	local def = SOUNDS[kind]
	if not def then
		return
	end
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	local s = Instance.new("Sound")
	s.SoundId = def[1]
	s.Volume = def[2]
	s.PlaybackSpeed = def[3]
	s.RollOffMinDistance = 14
	s.RollOffMaxDistance = 160
	s.Parent = a
	s:Play()
	if def[4] then
		task.delay(def[4], function()
			s:Stop()
		end)
	end
	Debris:AddItem(a, 4)
end

-- a short camera shake (Humanoid.CameraOffset jitter)
local shakeUntil, shakePower = 0, 0
local function shake(seconds: number, power: number)
	shakeUntil = math.max(shakeUntil, os.clock() + seconds)
	shakePower = math.max(shakePower, power)
end

local function eggColor(egg: string, golden: boolean): Color3
	local z = Config.Zones
	if golden then
		return z.EggColors.Golden
	end
	if z.EggColors[egg] then
		return z.EggColors[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.new(1, 1, 1)
end

------------------------------------------------------------------ the bosses
type Group = { name: string, joint: CFrame, parent: string, parts: { BasePart }, rest: { CFrame }, depth: number }
type Boss = {
	state: Configuration,
	model: Model,
	kind: string,
	groups: { Group },
	yaw: number,
	phase: number, -- walk cycle
	walk: number, -- 0 standing .. 1 walking (smoothed)
	seenState: number, -- StateStart we last reacted to
	warn: { BasePart }?,
}
local bosses: { [Configuration]: Boss } = {}

local function attr(s: Instance, name: string): any
	return s:GetAttribute(name)
end

local function posAt(s: Configuration, t: number): Vector3
	local from = attr(s, "From") :: Vector3? or Vector3.zero
	local to = attr(s, "To") :: Vector3? or from
	local t0, t1 = attr(s, "MoveStart") :: number? or 0, attr(s, "MoveEnd") :: number? or 0
	if t1 <= t0 then
		return to
	end
	return from:Lerp(to, math.clamp((t - t0) / (t1 - t0), 0, 1))
end

local function build(s: Configuration)
	if bosses[s] then
		return
	end
	local template = Library:FindFirstChild(attr(s, "Model") or "")
	if not template then
		return
	end
	local m = template:Clone()
	-- Config.Bosses.List[n].Scale: the model is built at 1, drawn this much bigger (blocks, offsets and joints)
	local scale = (attr(s, "Scale") :: number?) or 1
	local function scaled(cf: CFrame): CFrame
		return CFrame.new(cf.Position * scale) * cf.Rotation
	end
	local byName: { [string]: Group } = {}
	for _, g in m:GetChildren() do
		if g:IsA("Model") then
			local grp: Group = { name = g.Name, joint = scaled((g:GetAttribute("Joint") :: CFrame?) or CFrame.new()),
				parent = (g:GetAttribute("Parent") :: string?) or "", parts = {}, rest = {}, depth = 0 }
			for _, p in g:GetDescendants() do
				if p:IsA("BasePart") then
					p.Size *= scale
					table.insert(grp.parts, p)
					table.insert(grp.rest, scaled(p.CFrame)) -- (the library sits at the origin: CFrames are in boss space)
				end
			end
			byName[g.Name] = grp
		end
	end
	local list = {}
	for _, grp in byName do
		local node, d = grp, 0
		while node.parent ~= "" and byName[node.parent] and d < 8 do
			node = byName[node.parent]
			d += 1
		end
		grp.depth = d
		table.insert(list, grp)
	end
	table.sort(list, function(a, b)
		return a.depth < b.depth
	end)
	-- (parented only while it's near the camera and posed - see the frame loop)
	bosses[s] = { state = s, model = m, kind = m.Name, groups = list, yaw = (attr(s, "Yaw") :: number?) or 0,
		phase = 0, walk = 0, seenState = (attr(s, "StateStart") :: number?) or 0, warn = nil }
end

local function remove(s: Instance)
	local b = bosses[s :: Configuration]
	if b then
		b.model:Destroy()
		if b.warn then
			for _, p in b.warn do
				p:Destroy()
			end
		end
		bosses[s :: Configuration] = nil
	end
end

------------------------------------------------------------------ poses (group rotations at their joints)
-- Each returns (root offset, { [group] = rotation }). Rotations about X: + swings a hanging limb FORWARD (and tips
-- a torso BACK); bosses face -Z.
type Pose = (b: Boss, state: string, a: number, t: number, idle: string) -> (CFrame, { [string]: CFrame })

local POSES: { [string]: Pose } = {}

POSES.SeniorPartner = function(b, state, a, t, idle)
	local w, sw = b.walk, math.sin(b.phase)
	local rootOff = CFrame.new(0, math.abs(math.cos(b.phase)) * 0.25 * w, 0)
	local armL, armR, torsoX, headX, headY = -sw * 0.35 * w, sw * 0.15 * w, 0, 0, math.sin(t * 0.45) * 0.18 * (1 - w)
	if state == "idle" and idle == "check" then
		-- out comes the pocket watch: arm up to the face, a look down at it
		local e = ease(a * 4) * ease((1 - a) * 4)
		armL += 1.45 * e
		headX = -0.28 * e
		headY *= 1 - e
	elseif state == "windup" then
		-- the briefcase goes up over his head, he leans back, and trembles at the top
		local e = easeOut(a / 0.8)
		armR = 3.45 * e
		torsoX = 0.14 * e
		headX = 0.12 * e
		if a > 0.75 then
			rootOff *= CFrame.new(math.sin(t * 70) * 0.07, 0, 0)
		end
	elseif state == "attack" then
		-- SLAM: down in front of him in a fifth of a second, leaning into it
		local e = easeOut(a * 2.4)
		armR = 3.45 + (1.05 - 3.45) * e
		torsoX = 0.14 + (-0.24 - 0.14) * e
		headX = 0.12 - 0.3 * e
	elseif state == "recover" then
		local e = ease(a)
		armR = 1.05 * (1 - e)
		torsoX = -0.24 * (1 - e)
		headX = -0.18 * (1 - e)
	end
	return rootOff, {
		LegL = CFrame.Angles(sw * 0.5 * w, 0, 0),
		LegR = CFrame.Angles(-sw * 0.5 * w, 0, 0),
		ArmL = CFrame.Angles(armL, 0, 0),
		ArmR = CFrame.Angles(armR, 0, 0),
		Torso = CFrame.Angles(torsoX, 0, math.sin(b.phase) * 0.03 * w),
		Head = CFrame.Angles(headX + math.sin(t * 1.3) * 0.02, headY, 0),
		Papers = CFrame.Angles(0, t * 0.9, 0) * CFrame.new(0, math.sin(t * 2) * 0.15, 0),
	}
end

POSES.BarristerBulldog = function(b, state, a, t, idle)
	local w, sw = b.walk, math.sin(b.phase)
	local rootOff = CFrame.new(0, math.abs(math.cos(b.phase)) * 0.18 * w, 0) * CFrame.Angles(0, 0, sw * 0.045 * w)
	local legA, legB = sw * 0.45 * w, -sw * 0.45 * w
	local backL, backR = legB, legA
	local torsoX, headX, headY = 0, math.sin(b.phase * 2) * 0.04 * w, math.sin(t * 0.7) * 0.2 * (1 - w)
	local wag = math.sin(t * 12) * 0.55
	if state == "idle" and idle == "scratch" then
		-- sits down on its haunches and scratches behind an ear with a back paw
		local e = ease(a * 4) * ease((1 - a) * 4)
		torsoX = 0.32 * e
		rootOff *= CFrame.new(0, -0.35 * e, 0)
		backR = (0.9 + math.sin(t * 26) * 0.35) * e
		headY = 0.25 * e
		wag *= 0.3
	elseif state == "idle" then
		-- sniffs the ground
		local e = ease(a * 4) * ease((1 - a) * 4)
		headX = (-0.38 + math.sin(t * 16) * 0.05) * e
		headY *= 1 - e
	elseif state == "windup" then
		-- plants its feet and puffs up its chest, trembling
		local e = easeOut(a / 0.7)
		torsoX = 0.14 * e
		headX = 0.3 * e
		headY = 0
		rootOff *= CFrame.new(0, 0.35 * e, 0)
		if a > 0.6 then
			rootOff *= CFrame.new(math.sin(t * 80) * 0.06, 0, 0)
		end
		wag = math.sin(t * 30) * 0.3
	elseif state == "attack" then
		-- BARK: head snaps forward and down
		local e = if a < 0.3 then easeOut(a / 0.3) else 1 - ease((a - 0.3) / 0.7) * 0.6
		torsoX = 0.14 - 0.24 * e
		headX = 0.3 - 0.62 * e
		headY = 0
	elseif state == "recover" then
		local e = 1 - ease(a)
		torsoX = -0.04 * e
		headX = -0.06 * e
	end
	return rootOff, {
		LegFL = CFrame.Angles(legA, 0, 0),
		LegBR = CFrame.Angles(backR, 0, 0),
		LegFR = CFrame.Angles(legB, 0, 0),
		LegBL = CFrame.Angles(backL, 0, 0),
		Torso = CFrame.Angles(torsoX, 0, 0),
		Head = CFrame.Angles(headX, headY, 0),
		Tail = CFrame.Angles(0, wag, 0),
	}
end

------------------------------------------------------------------ warnings + attack effects
local function clearWarn(b: Boss)
	if b.warn then
		for _, p in b.warn do
			p:Destroy()
		end
		b.warn = nil
	end
end

local function makeWarn(b: Boss)
	clearWarn(b)
	local s = b.state
	local color = (attr(s, "Color") :: Color3?) or Color3.fromRGB(255, 80, 80)
	local radius = (attr(s, "Radius") :: number?) or 10
	local list = {}
	-- (each piece's width follows the radius in poseWarn - attribute Step = the angle between neighbours - so a
	-- long-range warning has no gaps)
	if attr(s, "Attack") == "Cone" then
		local angle = math.rad((attr(s, "Angle") :: number?) or 80)
		local n = 17
		for i = 0, n - 1 do
			table.insert(list, part({ Name = "WarnRay", Size = Vector3.new(1.7, 0.12, radius), Color = color, Material = Enum.Material.Neon, Transparency = 0.6 }))
			list[#list]:SetAttribute("Angle", -angle / 2 + angle * i / (n - 1))
			list[#list]:SetAttribute("Step", angle / (n - 1))
		end
		for i = 0, 23 do
			table.insert(list, part({ Name = "WarnEdge", Size = Vector3.new(1.5, 0.16, 0.8), Color = color, Material = Enum.Material.Neon, Transparency = 0.3 }))
			list[#list]:SetAttribute("Angle", -angle / 2 + angle * i / 23)
			list[#list]:SetAttribute("Step", angle / 23)
		end
	else
		table.insert(list, part({ Name = "WarnDisc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, radius * 2, radius * 2), Color = color, Material = Enum.Material.Neon, Transparency = 0.65 }))
		for i = 0, 35 do
			table.insert(list, part({ Name = "WarnEdge", Size = Vector3.new(1.6, 0.16, 0.8), Color = color, Material = Enum.Material.Neon, Transparency = 0.3 }))
			list[#list]:SetAttribute("Angle", i / 36 * math.pi * 2)
			list[#list]:SetAttribute("Step", math.pi * 2 / 36)
		end
	end
	for _, p in list do
		p.Parent = visuals
	end
	b.warn = list
end

-- place the warning on the floor, grown to `grow` of its size, pulsing
local function poseWarn(b: Boss, origin: Vector3, yaw: number, grow: number, t: number)
	if not b.warn then
		return
	end
	local s = b.state
	local radius = ((attr(s, "Radius") :: number?) or 10) * grow
	local floor = CFrame.new(origin.X, ((attr(s, "FloorY") :: number?) or origin.Y) + 0.09, origin.Z) * CFrame.Angles(0, yaw, 0)
	local pulse = 0.5 + 0.5 * math.sin(t * 18)
	for _, p in b.warn do
		local a = (p:GetAttribute("Angle") :: number?) or 0
		local step = (p:GetAttribute("Step") :: number?) or 0.1
		if p.Name == "WarnRay" then
			p.Size = Vector3.new(math.max(1.7, radius * step * 0.8), p.Size.Y, radius)
			p.CFrame = floor * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius / 2)
			p.Transparency = 0.55 + 0.2 * pulse
		elseif p.Name == "WarnDisc" then
			p.Size = Vector3.new(p.Size.X, radius * 2, radius * 2)
			p.CFrame = floor * CFrame.Angles(0, 0, math.pi / 2)
			p.Transparency = 0.6 + 0.2 * pulse
		else
			p.Size = Vector3.new(math.max(1.5, radius * step * 1.05), p.Size.Y, p.Size.Z)
			p.CFrame = floor * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.02, -radius)
			p.Transparency = 0.15 + 0.35 * pulse
		end
	end
end

local function shockwave(origin: Vector3, radius: number, color: Color3, delay: number)
	task.delay(delay, function()
		local ring = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2), Color = color, Material = Enum.Material.Neon, Transparency = 0.25 })
		ring.Parent = visuals
		local t0 = os.clock()
		while os.clock() - t0 < 0.38 do
			local a = (os.clock() - t0) / 0.38
			local r = 1 + (radius - 1) * easeOut(a)
			ring.Size = Vector3.new(0.3, r * 2, r * 2)
			ring.CFrame = CFrame.new(origin + Vector3.new(0, 0.6 + a * 0.8, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			ring.Transparency = 0.25 + 0.75 * a
			RunService.Heartbeat:Wait()
		end
		ring:Destroy()
	end)
end

local function paperBurst(at: Vector3, look: Vector3)
	for i = 1, 14 do
		local p = part({ Size = Vector3.new(0.9, 0.05, 1.1), Color = Color3.fromRGB(250, 250, 250), Anchored = false, Massless = true })
		p.CFrame = CFrame.new(at + Vector3.new(math.random() - 0.5, math.random() * 0.5, math.random() - 0.5)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = visuals
		p.AssemblyLinearVelocity = look * (8 + math.random() * 10) + Vector3.new((math.random() - 0.5) * 22, 14 + math.random() * 14, (math.random() - 0.5) * 22)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 14, math.random() * 14, math.random() * 14)
		Debris:AddItem(p, 1.4 + math.random() * 0.4)
	end
end

local function sparkBurst(at: Vector3, color: Color3, count: number)
	local holder = part({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(at) })
	holder.Parent = visuals
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.3
	e.Lifetime = NumberRange.new(0.35, 0.6)
	e.Speed = NumberRange.new(12, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	e.Drag = 4
	e.Rate = 0
	e.Parent = holder
	e:Emit(count)
	Debris:AddItem(holder, 1.2)
end

local function attackEffects(b: Boss, origin: Vector3, yaw: number)
	local s = b.state
	local color = (attr(s, "Color") :: Color3?) or Color3.fromRGB(255, 80, 80)
	local radius = (attr(s, "Radius") :: number?) or 10
	local look = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local floorY = (attr(s, "FloorY") :: number?) or origin.Y
	if attr(s, "Attack") == "Cone" then
		local at = Vector3.new(origin.X, floorY + 1, origin.Z) + look * 4.5 * ((attr(s, "Scale") :: number?) or 1)
		task.delay(0.16, function()
			paperBurst(at + Vector3.new(0, 1, 0), look)
			sparkBurst(at, color, 18)
			shockwave(at, radius * 0.55, color, 0)
			playAt(at, "slam")
		end)
	else
		local at = Vector3.new(origin.X, floorY, origin.Z)
		shockwave(at, radius, color, 0.05)
		shockwave(at, radius * 0.75, Color3.new(1, 1, 1), 0.15)
		playAt(at + Vector3.new(0, 4, 0), "bark")
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and (root.Position - origin).Magnitude < radius * 1.6 then
		shake(0.25, 0.35)
	end
end

------------------------------------------------------------------ the frame
RunService.Heartbeat:Connect(function(dt)
	local t = now()
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	local parts, frames = {}, {}
	for s, b in bosses do
		if not s.Parent then
			remove(s)
			continue
		end
		local pos = posAt(s, t)
		local state = (attr(s, "State") :: string?) or "idle"
		local t0, t1 = (attr(s, "StateStart") :: number?) or 0, (attr(s, "StateEnd") :: number?) or 0
		local a = if t1 > t0 then math.clamp((t - t0) / (t1 - t0), 0, 1) else 1
		local yaw = (attr(s, "Yaw") :: number?) or 0
		-- react to a new state once (warning on windup, effects on attack)
		if t0 ~= b.seenState then
			b.seenState = t0
			if state == "windup" then
				makeWarn(b)
				playAt(pos + Vector3.new(0, 5, 0), "windup")
			elseif state == "attack" then
				clearWarn(b)
				if (pos - camPos).Magnitude < DRAW_DISTANCE then
					attackEffects(b, pos, yaw)
				end
			else
				clearWarn(b)
			end
		end
		if (pos - camPos).Magnitude > DRAW_DISTANCE then
			if b.model.Parent then
				b.model.Parent = nil -- far away: not drawn at all
			end
			continue
		end
		if not b.model.Parent then
			b.model.Parent = visuals
		end
		-- walking: the stride follows the real speed
		local moving = false
		local m0, m1 = (attr(s, "MoveStart") :: number?) or 0, (attr(s, "MoveEnd") :: number?) or 0
		if state == "walk" and t < m1 and m1 > m0 then
			local from, to = attr(s, "From") :: Vector3, attr(s, "To") :: Vector3
			local speed = (to - from).Magnitude / (m1 - m0)
			b.phase += dt * speed / (4 * ((attr(s, "Scale") :: number?) or 1)) * math.pi -- (bigger = longer strides)
			moving = true
		end
		b.walk += ((if moving then 1 else 0) - b.walk) * math.min(1, dt * 6)
		b.yaw = lerpAngle(b.yaw, yaw, math.min(1, dt * (if state == "windup" then 12 else 6)))
		if state == "windup" then
			poseWarn(b, pos, yaw, 0.45 + 0.55 * easeOut(a / 0.4), t)
		end
		local pose = POSES[b.kind]
		local rootOff, rots = CFrame.new(), {}
		if pose then
			rootOff, rots = pose(b, state, a, t, (attr(s, "Idle") :: string?) or "")
		end
		local sc = (attr(s, "Scale") :: number?) or 1 -- (bobs and trembles grow with the boss)
		local root = CFrame.new(pos) * CFrame.Angles(0, b.yaw, 0) * CFrame.new(rootOff.Position * sc) * rootOff.Rotation
		local world: { [string]: CFrame } = {}
		for _, g in b.groups do
			local parentCF = if g.parent ~= "" and world[g.parent] then world[g.parent] else root
			local rot = rots[g.name]
			local w = if rot then parentCF * g.joint * rot * g.joint:Inverse() else parentCF
			world[g.name] = w
			for i, p in g.parts do
				table.insert(parts, p)
				table.insert(frames, w * g.rest[i])
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	-- camera shake
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if os.clock() < shakeUntil then
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5), (math.random() - 0.5), 0) * shakePower
		elseif shakePower > 0 then
			shakePower = 0
			humanoid.CameraOffset = Vector3.zero
		end
	end
end)

for _, s in States:GetChildren() do
	if s:IsA("Configuration") then
		build(s)
	end
end
States.ChildAdded:Connect(function(s)
	if s:IsA("Configuration") then
		task.wait() -- (let its attributes arrive)
		build(s)
	end
end)
States.ChildRemoved:Connect(remove)

------------------------------------------------------------------ hits: knockback, and the eggs flying out
-- RAGDOLL (user's call 2026-10-12): the hit player goes limp, is flung away tumbling, and gets back up after
-- `seconds`. Done by the player's own client (it owns its character's physics; everyone sees it replicate).
-- The game's avatars use the new joints (AnimationConstraint + a BallSocketConstraint per joint): switching the
-- AnimationConstraints off leaves the ball sockets holding the limbs - a ragdoll. Classic Motor6D rigs get a ball
-- socket per joint for the duration. The Root joint stays on, so the HumanoidRootPart stays with the body.
local ragdolled = false

local function ragdoll(away: Vector3, power: number, seconds: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local fling = away * power + Vector3.new(0, 32, 0)
	if ragdolled or seconds <= 0 then
		root.AssemblyLinearVelocity = fling
		return
	end
	ragdolled = true
	local undo: { () -> () } = {}
	for _, d in character:GetDescendants() do
		if d:IsA("AnimationConstraint") and d.Enabled and d.Name ~= "Root" then
			d.Enabled = false
			table.insert(undo, function()
				d.Enabled = true
			end)
		elseif d:IsA("Motor6D") and d.Enabled and d.Part0 and d.Part1 and d.Name ~= "Root" and d.Name ~= "RootJoint" then
			local a0 = Instance.new("Attachment")
			a0.CFrame = d.C0
			a0.Parent = d.Part0
			local a1 = Instance.new("Attachment")
			a1.CFrame = d.C1
			a1.Parent = d.Part1
			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0, socket.Attachment1 = a0, a1
			socket.LimitsEnabled = true
			socket.UpperAngle = 70
			socket.Parent = d.Parent
			d.Enabled = false
			table.insert(undo, function()
				d.Enabled = true
				socket:Destroy()
				a0:Destroy()
				a1:Destroy()
			end)
		elseif d:IsA("BasePart") and d ~= root and not d.CanCollide and d.Parent == character then
			d.CanCollide = true -- (limbs land on the floor instead of sinking through it)
			table.insert(undo, function()
				d.CanCollide = false
			end)
		end
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	root.AssemblyLinearVelocity = fling
	root.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 14
	task.delay(seconds, function()
		for _, f in undo do
			pcall(f)
		end
		ragdolled = false
		if player.Character ~= character or humanoid.Health <= 0 then
			return
		end
		-- back on its feet, upright, facing the way it was flung
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		local p = root.Position
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(p + Vector3.new(0, 1.5, 0), p + Vector3.new(0, 1.5, 0) + Vector3.new(away.X, 0, away.Z) + Vector3.new(0, 0, 0.001))
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

local function looseSize(golden: boolean): Vector3
	return if golden then Vector3.new(2.8, 3.5, 2.8) else Vector3.new(2.3, 2.9, 2.3)
end

-- one egg out of the pile: pops up, arcs out spinning, lands with a squash, bounces twice, then waits for the
-- server's own loose egg to appear in its place
local function flyEgg(start: Vector3, landing: Vector3, egg: string, golden: boolean, holdUntil: number)
	local final = looseSize(golden)
	local p = part({ Size = final * 0.55, Color = eggColor(egg, golden), Material = if golden then Enum.Material.Neon else Enum.Material.SmoothPlastic })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	p.CFrame = CFrame.new(start)
	p.Parent = visuals
	local rest = landing + Vector3.new(0, final.Y / 2, 0)
	local flat = Vector3.new(rest.X - start.X, 0, rest.Z - start.Z)
	local peak = 3.5 + flat.Magnitude * 0.25
	local axis = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	axis = if axis.Magnitude > 0.01 then axis.Unit else Vector3.xAxis
	local FLY, HOP1, HOP2 = 0.45, 0.2, 0.13
	local t0 = os.clock()
	local landed1, landed2, landed3 = false, false, false
	while os.clock() < holdUntil do
		local e = os.clock() - t0
		local size, pos, rot = final, rest, CFrame.new()
		if e < FLY then
			local a = e / FLY
			size = final * (0.55 + 0.45 * a)
			pos = start:Lerp(rest, a) + Vector3.new(0, 4 * peak * a * (1 - a), 0)
			rot = CFrame.fromAxisAngle(axis, a * math.pi * 3)
		elseif e < FLY + HOP1 then
			if not landed1 then
				landed1 = true
				playAt(rest, "land")
			end
			local a = (e - FLY) / HOP1
			pos = rest + Vector3.new(0, 4 * 1.1 * a * (1 - a), 0)
			size = if a < 0.25 then Vector3.new(final.X * 1.15, final.Y * 0.78, final.Z * 1.15) else final
		elseif e < FLY + HOP1 + HOP2 then
			landed2 = true
			local a = (e - FLY - HOP1) / HOP2
			pos = rest + Vector3.new(0, 4 * 0.4 * a * (1 - a), 0)
			size = if a < 0.3 then Vector3.new(final.X * 1.1, final.Y * 0.85, final.Z * 1.1) else final
		else
			if not landed3 then
				landed3 = true
			end
			-- a little wobble to a stop
			local a = e - FLY - HOP1 - HOP2
			rot = CFrame.Angles(math.sin(a * 18) * 0.12 * math.max(0, 1 - a * 2.5), 0, 0)
		end
		p.Size = size
		p.CFrame = CFrame.new(pos - Vector3.new(0, (final.Y - size.Y) / 2, 0)) * rot
		RunService.Heartbeat:Wait()
	end
	p:Destroy()
end

Remote.OnClientEvent:Connect(function(kind: string, info: any)
	if kind == "Hit" then
		local who = Players:GetPlayerByUserId(info.userId)
		local character = who and who.Character
		local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
		local at = if torso then torso.Position else (info.eggs[1] and info.eggs[1].at or info.from)
		sparkBurst(at, Color3.fromRGB(255, 230, 120), 26)
		playAt(at, if #info.eggs > 0 then "hit" else "boing")
		if who == player then
			ragdoll(info.away, CFG.Knockback, info.ragdoll or CFG.RagdollTime or 0)
			shake(0.35, 0.7)
		end
		local base = os.clock()
		for i, e in info.eggs do
			-- out of the pile from the top down
			local start = if torso then (torso.CFrame * CFrame.new(0, -0.4 + (#info.eggs - i) * 1.3, -1.2)).Position else e.at + Vector3.new(0, 3, 0)
			local holdUntil = base + CFG.GrabbableAfter + (i - 1) * CFG.DropStagger + 0.3
			task.delay((i - 1) * CFG.DropStagger, flyEgg, start, e.at, e.egg, e.golden, holdUntil)
		end
	elseif kind == "Grab" then
		local who = Players:GetPlayerByUserId(info.userId)
		local character = who and who.Character
		local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
		playAt(info.at, "grab")
		if not torso then
			return
		end
		local size = looseSize(info.golden)
		local p = part({ Size = size, Color = eggColor(info.egg, info.golden), Material = if info.golden then Enum.Material.Neon else Enum.Material.SmoothPlastic })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = visuals
		local from = info.at + Vector3.new(0, size.Y / 2, 0)
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.25 do
				local a = (os.clock() - t0) / 0.25
				p.Size = size * (1 - 0.5 * a)
				p.CFrame = CFrame.new(from:Lerp(torso.Position, a) + Vector3.new(0, 3 * a * (1 - a) * 4, 0))
				RunService.Heartbeat:Wait()
			end
			p:Destroy()
		end)
	end
end)

------------------------------------------------------------------ loose eggs: bob, spin, glow, blink at the end
type Loose = { model: Model, parts: { BasePart }, base: { CFrame }, home: CFrame, seed: number, glow: Highlight }
local looseEggs: { [Instance]: Loose } = {}

local function addLoose(m: Instance)
	if not m:IsA("Model") or looseEggs[m] then
		return
	end
	local shell = m.PrimaryPart or m:FindFirstChild("Shell") :: BasePart?
	if not shell then
		return
	end
	local home = shell.CFrame
	local parts, base = {}, {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			table.insert(base, home:ToObjectSpace(p.CFrame))
		end
	end
	local glow = Instance.new("Highlight")
	glow.FillColor = Color3.new(1, 1, 1)
	glow.OutlineColor = Color3.new(1, 1, 1)
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.FillTransparency = 1
	glow.OutlineTransparency = 1
	glow.Parent = m
	looseEggs[m] = { model = m, parts = parts, base = base, home = home, seed = math.random() * 6, glow = glow }
end

CollectionService:GetInstanceAddedSignal("LooseEgg"):Connect(addLoose)
CollectionService:GetInstanceRemovedSignal("LooseEgg"):Connect(function(m)
	looseEggs[m] = nil
end)
for _, m in CollectionService:GetTagged("LooseEgg") do
	addLoose(m)
end

RunService.Heartbeat:Connect(function()
	local t = now()
	local clock = os.clock()
	for m, l in looseEggs do
		if not m.Parent then
			looseEggs[m] = nil
			continue
		end
		local grabbable = (m:GetAttribute("GrabbableAt") :: number?) or 0
		if t < grabbable then
			continue
		end
		local expires = (m:GetAttribute("ExpiresAt") :: number?) or (t + 99)
		local left = expires - t
		local bob = CFrame.new(0, 0.25 + math.sin(clock * 3 + l.seed) * 0.25, 0) * CFrame.Angles(0, clock * 0.8 + l.seed, 0)
		local frame = l.home * bob
		for i, p in l.parts do
			p.CFrame = frame * l.base[i]
		end
		-- the glow pulses; in the last 5 s the egg blinks, faster and faster
		local pulse = 0.5 + 0.5 * math.sin(clock * 4 + l.seed)
		l.glow.FillTransparency = 0.55 + 0.35 * pulse
		l.glow.OutlineTransparency = 0.1 + 0.4 * pulse
		local hidden = left < 5 and math.sin(clock * (8 + (5 - left) * 5)) > 0.35
		for _, p in l.parts do
			p.LocalTransparencyModifier = if hidden then 0.75 else 0
		end
	end
end)
