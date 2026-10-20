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
--   * BLENDER CLIPS (2026-10-19, docs/BOSS_ANIMATION.md): a boss with clips in Shared.BossAnims (made by
--     tools/blender/boss_anims.py; Megalodon first) plays them for windup / attack / dizzy / recover instead of its
--     POSES function (cross-faded): squash + stretch, the whip-round turn, the glowing fin, its own effects, and the
--     CROWD add-on (Config.Bosses.List[n].Crowd: sand-shark fins down extra warning lanes at other players).
-- No text anywhere (user's call): no names, no labels, no messages.

local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
-- the bosses' Blender clips (generated); a boss without clips keeps its POSES function
local animsOk, animsLib = pcall(function()
	return require(Shared:WaitForChild("BossAnims", 15) :: ModuleScript)
end)
local ANIMS: { [string]: any } = if animsOk and type(animsLib) == "table" then animsLib else {}
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

local function backOut(a: number): number -- overshoots a little, then settles
	a = math.clamp(a, 0, 1) - 1
	return 1 + 2.70158 * a * a * a + 1.70158 * a * a
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

-- licensed sounds only (Roblox UI pack, Pro Sound Effects, APM - the Shared.Sfx set) (the game's sound rule; rbxasset://sounds/swoosh.wav is NOT approved for this place).
-- { id, volume, speed, stop after (s)? }
local SOUNDS = {
	windup = { "rbxassetid://9045751375", 0.45, 1.5, 1.0 }, -- the Big Case alert, quick and cut short
	slam = { "rbxassetid://9125574353", 1, 0.62 }, -- the gavel knock, low
	bark = { "rbxassetid://9125574353", 1, 0.45 },
	hit = { "rbxassetid://9114753510", 0.8, 1.2, 0.6 }, -- hammer on wood
	boing = { "rbxassetid://15675055424", 0.7, 0.65 }, -- a low cute pop
	charge = { "rbxassetid://15674975792", 0.8, 0.85 }, -- a big whoosh
	sniff = { "rbxassetid://9112872239", 0.35, 0.7 }, -- a low bubble: the Megalodon smells eggs
	scrape = { "rbxassetid://9113959343", 0.35, 0.55, 0.4 }, -- a gritty crack, low and short: a paw scrape
	launch = { "rbxassetid://9119293555", 0.6, 1.25, 0.9 }, -- a quick splash as it explodes forward
	skid = { "rbxassetid://9119293555", 0.55, 0.7, 1.0 }, -- a low splash as it skids to a stop
	shakeoff = { "rbxassetid://9119293555", 0.4, 1.6, 0.5 }, -- the wet-dog shake
	pull = { "rbxassetid://9045751375", 0.4, 0.7, 2.0 },
	land = { "rbxassetid://9114753510", 0.35, 1.6, 0.5 },
	grab = { "rbxassetid://15675024286", 0.55, 1.1 }, -- whoosh
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
type Group = { name: string, joint: CFrame, parent: string, parts: { BasePart }, rest: { CFrame }, sizes: { Vector3 }, depth: number }
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
	warnKind: string?, -- the attack the warning is for
	stars: { BasePart }?, -- dizzy stars over its head
	lastRoll: number, -- how far a roll turned it (Big Cheese), unwound in the recover
	trailAt: number, -- when the last trail puff went out (Line attacks)
	-- Blender clips (ANIMS):
	clipW: number, -- 0 = its POSES function .. 1 = the clip (cross-fade)
	lastClip: any?, -- the last clip pose (faded out of after the recover)
	turnStart: number, -- the windup the whip-round turn is for
	turnFrom: number, -- the yaw it turned from
	glow: { BasePart }, -- parts named FinGlow (lit by the clip's FinGlow channel)
	glowNow: number,
	squashed: boolean, -- its parts are resized (squash / stretch) right now
	fired: { [string]: boolean }, -- one-shot effects already played in this state
	fxAt: number, -- when the last repeating effect went out
	lanes: { Vector3 }, -- this attack's crowd lanes (ends)
	laneFrom: Vector3,
	sharks: { BasePart },
	runFx: BasePart?, -- the charge's trail emitters
}
local bosses: { [Configuration]: Boss } = {}
local ragdolled = false -- (the local player is lying limp: no pulls - see ragdoll below)

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
	local glow = {}
	for _, g in m:GetChildren() do
		if g:IsA("Model") then
			local grp: Group = { name = g.Name, joint = scaled((g:GetAttribute("Joint") :: CFrame?) or CFrame.new()),
				parent = (g:GetAttribute("Parent") :: string?) or "", parts = {}, rest = {}, sizes = {}, depth = 0 }
			for _, p in g:GetDescendants() do
				if p:IsA("BasePart") then
					p.Size *= scale
					table.insert(grp.parts, p)
					table.insert(grp.sizes, p.Size)
					if p.Name == "FinGlow" then
						p.Transparency = 1 -- (lit by the clip)
						table.insert(glow, p)
					end
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
		phase = 0, walk = 0, seenState = (attr(s, "StateStart") :: number?) or 0, warn = nil, warnKind = nil,
		stars = nil, lastRoll = 0, trailAt = 0, clipW = 0, lastClip = nil, turnStart = 0, turnFrom = 0, glow = glow,
		glowNow = 0, squashed = false, fired = {}, fxAt = 0, lanes = {}, laneFrom = Vector3.zero, sharks = {}, runFx = nil }
end

local function remove(s: Instance)
	local b = bosses[s :: Configuration]
	if b then
		b.model:Destroy()
		for _, list in { b.warn or {}, b.stars or {}, b.sharks, { b.runFx } } do
			for _, p in list do
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

-- Judge Martello: every stride is a hop; the Slam is one huge hop onto where you stood, arms up, legs tucked
POSES.JudgeMartello = function(b, state, a, t, idle)
	local w, sw = b.walk, math.sin(b.phase)
	local hop = math.abs(math.sin(b.phase))
	local rootY = hop * 1.0 * w
	local legs = -hop * 0.5 * w
	local arms = math.sin(t * 9) * 0.35 * w
	local torsoX = math.sin(t * 2) * 0.04 * (1 - w)
	if state == "windup" then
		local arc = math.sin(math.pi * math.clamp(a, 0, 1))
		rootY = arc * ((attr(b.state, "HopHeight") :: number?) or 6)
		torsoX = -0.35 * arc
		legs = -0.9 * arc
		arms = 2.6 * arc
	elseif state == "attack" then
		local e = 1 - easeOut(a * 2)
		rootY = -0.35 * e -- (the squash on landing)
		legs = 0.5 * e
		arms = 1.2 * e
	end
	return CFrame.new(0, rootY, 0), {
		LegL = CFrame.Angles(legs + sw * 0.2 * w, 0, 0),
		LegR = CFrame.Angles(legs - sw * 0.2 * w, 0, 0),
		ArmL = CFrame.Angles(arms, 0, -0.3),
		ArmR = CFrame.Angles(arms, 0, 0.3),
		Torso = CFrame.Angles(torsoX, 0, math.sin(b.phase) * 0.06 * w),
	}
end

-- Big Cheese: wobbles along on its edge; to attack it turns side-on, trembles, and ROLLS (it really turns, face and
-- all), then unwinds
POSES.BigCheese = function(b, state, a, t, idle)
	local w = b.walk
	local s = b.state
	local rootOff = CFrame.new(0, math.abs(math.sin(b.phase)) * 0.25 * w, 0)
	local torso = CFrame.Angles(0, 0, math.sin(b.phase) * 0.12 * w + math.sin(t * 1.5) * 0.03)
	local arm = math.sin(t * 3) * 0.2
	if state == "windup" then
		local e = easeOut(a / 0.6)
		torso = CFrame.Angles(0.12 * e, e * math.pi / 2, 0)
		if a > 0.6 then
			rootOff *= CFrame.new(math.sin(t * 60) * 0.05, 0, 0)
		end
		arm = 1.4 * e
	elseif state == "attack" then
		local from = (attr(s, "From") :: Vector3?) or Vector3.zero
		local dist = Vector3.new(posAt(s, now()).X - from.X, 0, posAt(s, now()).Z - from.Z).Magnitude
		b.lastRoll = (dist / (3.2 * ((attr(s, "Scale") :: number?) or 1))) % (math.pi * 2)
		torso = CFrame.Angles(-b.lastRoll, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
		arm = 0
	elseif state == "recover" then
		local e = 1 - ease(a)
		torso = CFrame.Angles(-b.lastRoll * e, 0, 0) * CFrame.Angles(0, math.pi / 2 * e, 0)
	end
	return rootOff, {
		Torso = torso,
		ArmL = CFrame.Angles(arm, 0, -0.2),
		ArmR = CFrame.Angles(arm * 0.6 + 0.3, 0, 0.2),
	}
end

-- Magistrate Megalodon: stalks, tail swishing; crouches with its fins back, CHARGES leaning into it, then is dizzy
POSES.Megalodon = function(b, state, a, t, idle)
	local w, sw = b.walk, math.sin(b.phase)
	local rootOff = CFrame.new(0, math.abs(math.cos(b.phase)) * 0.2 * w, 0)
	local torsoX, torsoY, torsoZ = 0, 0, sw * 0.04 * w
	local fins = sw * 0.3 * w
	local tail = math.sin(t * 4) * 0.35
	local legs = 0.5
	if state == "windup" then
		local e = easeOut(a / 0.6)
		torsoX = -0.35 * e
		rootOff *= CFrame.new(0, -0.3 * e, 0)
		fins = -0.6 * e
		tail = math.sin(t * 20) * 0.5
	elseif state == "attack" then
		torsoX, fins, legs = -0.5, -0.9, 0.8
		tail = math.sin(t * 25) * 0.6
	elseif state == "dizzy" then
		torsoZ = math.sin(t * 5) * 0.18
		torsoY = math.sin(t * 3) * 0.25
		fins = math.sin(t * 7) * 0.5
	elseif state == "recover" then
		torsoX = -0.5 * (1 - ease(a))
	end
	return rootOff, {
		LegL = CFrame.Angles(sw * legs * w, 0, 0),
		LegR = CFrame.Angles(-sw * legs * w, 0, 0),
		Torso = CFrame.Angles(torsoX, torsoY, torsoZ),
		Tail = CFrame.Angles(0, tail, 0),
		ArmL = CFrame.Angles(fins, 0, -0.15),
		ArmR = CFrame.Angles(-fins, 0, 0.15),
		-- (v2 groups: the robe's back panel trails, the lure fish swings)
		Cape = CFrame.Angles(-0.06 * w - 0.05 * math.abs(sw) * w, 0, 0),
		Lure = CFrame.Angles(0.05 + 0.05 * math.abs(math.cos(b.phase)) * w, 0, -0.12 * math.sin(b.phase - 0.6) * w),
	}
end

-- Chief Justice Eclipse: floats, gavels orbiting; Pull = rises with both arms up, then reaches out and drags;
-- Ring = arms out wide while the gavels spin up, then they whip round
POSES.Eclipse = function(b, state, a, t, idle)
	local rootOff = CFrame.new(0, 0.7 + math.sin(t * 1.5) * 0.3, 0)
	local arms, armsOut, spin = math.sin(t * 1.2) * 0.1, 0, t * 1.6
	local headX = math.sin(t * 0.9) * 0.08
	local kind = attr(b.state, "AttackKind")
	if state == "windup" then
		local e = easeOut(a / 0.6)
		if kind == "Pull" then
			arms = 2.9 * e
			rootOff *= CFrame.new(0, 1.2 * e, 0)
		else
			armsOut = 1.3 * e
			spin = t * (1.6 + 10 * e)
		end
		headX = 0.25 * e
	elseif state == "attack" then
		if kind == "Pull" then
			arms = 1.5 + math.sin(t * 30) * 0.08
			rootOff *= CFrame.new(0, 1.2, 0)
		else
			armsOut = 1.3
			spin = t * 14
		end
	end
	return rootOff, {
		ArmL = CFrame.Angles(arms, 0, -armsOut),
		ArmR = CFrame.Angles(arms, 0, armsOut),
		Head = CFrame.Angles(headX, math.sin(t * 0.5) * 0.3, 0),
		Gavels = CFrame.Angles(0, spin, 0),
		Torso = CFrame.Angles(0, 0, math.sin(t * 0.8) * 0.03),
	}
end

------------------------------------------------------------------ Blender clips (Shared.BossAnims, docs/BOSS_ANIMATION.md)
-- A clip frame = each group's rotation (+ offset, model units) at its joint, the root's offset + tilt, its SQUASH
-- (sx, sy, sz around the feet) and fx channels (FinGlow). Walk / idle stay the POSES; the clip states cross-fade in
-- and out over CLIP_FADE s.
local CLIP_FADE = 0.1
type ClipPose = { root: CFrame, scale: Vector3, rots: { [string]: CFrame }, fx: { [string]: number } }

local function clipFrame(ch: any, i: number, sc: number): CFrame
	local px, py, pz = 0, 0, 0
	local P = ch.P
	if P then
		px, py, pz = P[i * 3 + 1] * sc, P[i * 3 + 2] * sc, P[i * 3 + 3] * sc
	end
	local R = ch.R
	if R then
		local k = i * 4
		return CFrame.new(px, py, pz, R[k + 1], R[k + 2], R[k + 3], R[k + 4])
	end
	return CFrame.new(px, py, pz)
end

local function sampleClip(anim: any, name: string, t: number, sc: number): ClipPose?
	local clip = anim.Clips[name]
	if not clip then
		return nil
	end
	local n = clip.Frames
	local f = t * anim.Fps
	f = if clip.Loop then f % (n - 1) else math.clamp(f, 0, n - 1)
	local i0 = math.floor(f)
	local i1 = math.min(i0 + 1, n - 1)
	local a = f - i0
	local rots = {}
	for g, ch in clip.Groups do
		rots[g] = clipFrame(ch, i0, sc):Lerp(clipFrame(ch, i1, sc), a)
	end
	local R = clip.Root
	local k0, k1 = i0 * 10, i1 * 10
	local r0 = CFrame.new(R[k0 + 1], R[k0 + 2], R[k0 + 3], R[k0 + 4], R[k0 + 5], R[k0 + 6], R[k0 + 7])
	local r1 = CFrame.new(R[k1 + 1], R[k1 + 2], R[k1 + 3], R[k1 + 4], R[k1 + 5], R[k1 + 6], R[k1 + 7])
	local s0, s1 = Vector3.new(R[k0 + 8], R[k0 + 9], R[k0 + 10]), Vector3.new(R[k1 + 8], R[k1 + 9], R[k1 + 10])
	local fx = {}
	for name2, v in clip.Fx do
		fx[name2] = v[i0 + 1] + (v[i1 + 1] - v[i0 + 1]) * a
	end
	return { root = r0:Lerp(r1, a), scale = s0:Lerp(s1, a), rots = rots, fx = fx }
end

local function mixPose(x: ClipPose, y: ClipPose, w: number): ClipPose
	local rots = {}
	for g, cf in x.rots do
		rots[g] = cf:Lerp(y.rots[g] or CFrame.identity, w)
	end
	for g, cf in y.rots do
		if not rots[g] then
			rots[g] = CFrame.identity:Lerp(cf, w)
		end
	end
	local fx = {}
	for k, v in x.fx do
		fx[k] = v + ((y.fx[k] or 0) - v) * w
	end
	for k, v in y.fx do
		if fx[k] == nil then
			fx[k] = v * w
		end
	end
	return { root = x.root:Lerp(y.root, w), scale = x.scale:Lerp(y.scale, w), rots = rots, fx = fx }
end

-- the clip pose for a state (nil = not a clip state). A charge = launch (its first 0.2 s), the loop, then the brake
-- (its last 0.2 s); a short charge splits its time between launch and brake.
local function clipPoseFor(anim: any, state: string, e: number, total: number, sc: number): ClipPose?
	if state == "attack" then
		if not anim.Clips.charge_loop then
			return sampleClip(anim, "attack", e, sc)
		end
		local lt = math.min(0.2, total / 2)
		if e < lt then
			return sampleClip(anim, "charge_launch", e, sc)
		end
		local loop = sampleClip(anim, "charge_loop", (e - lt) % anim.Clips.charge_loop.Length, sc) :: ClipPose
		local bt = e - (total - lt)
		if bt > 0 then
			local brake = sampleClip(anim, "charge_brake", bt + (0.2 - lt), sc) :: ClipPose
			return mixPose(loop, brake, math.clamp(bt / 0.06, 0, 1))
		end
		return loop
	elseif state == "windup" or state == "dizzy" or state == "recover" then
		return sampleClip(anim, state, e, sc)
	end
	return nil
end

------------------------------------------------------------------ warnings + attack effects
local function warnKindOf(s: Configuration): string
	return (attr(s, "AttackKind") :: string?) or (attr(s, "Attack") :: string?) or "Ring"
end

local function clearWarn(b: Boss)
	if b.warn then
		for _, p in b.warn do
			p:Destroy()
		end
		b.warn = nil
	end
end

-- The warning on the floor for this attack, in the boss's colour (each piece sized every frame by poseWarn):
-- Cone = a fan; Ring / Slam = a disc with an edge (Slam's at the landing spot); Line = a strip to where it'll stop,
-- with arrows; Pull = a disc, its deadly white middle and a swirl.
local function makeWarn(b: Boss)
	clearWarn(b)
	local s = b.state
	local kind = warnKindOf(s)
	local color = (attr(s, "Color") :: Color3?) or Color3.fromRGB(255, 80, 80)
	local list = {}
	local function add(name: string, props: { [string]: any }, extra: { [string]: any }?)
		props.Color = props.Color or color
		props.Material = Enum.Material.Neon
		local p = part(props)
		p.Name = name
		for k, v in extra or {} do
			p:SetAttribute(k, v)
		end
		table.insert(list, p)
	end
	if kind == "Cone" then
		local angle = math.rad((attr(s, "Angle") :: number?) or 80)
		for i = 0, 16 do
			add("WarnRay", { Size = Vector3.new(1.7, 0.12, 1), Transparency = 0.6 }, { Angle = -angle / 2 + angle * i / 16, Step = angle / 16 })
		end
		for i = 0, 23 do
			add("WarnEdge", { Size = Vector3.new(1.5, 0.16, 0.8), Transparency = 0.3 }, { Angle = -angle / 2 + angle * i / 23, Step = angle / 23 })
		end
	elseif kind == "Line" then
		-- lane 0 = its own charge / roll; 1..CrowdN = the crowd add-on's lanes at other players
		for lane = 0, (attr(s, "CrowdN") :: number?) or 0 do
			add("WarnStrip", { Size = Vector3.new(1, 0.1, 1), Transparency = 0.65 }, { Lane = lane })
			add("WarnSide", { Size = Vector3.new(0.8, 0.16, 1), Transparency = 0.3 }, { Side = -1, Lane = lane })
			add("WarnSide", { Size = Vector3.new(0.8, 0.16, 1), Transparency = 0.3 }, { Side = 1, Lane = lane })
			for i = 1, 3 do
				add("WarnArrow", { Size = Vector3.new(1, 0.14, 1.4), Transparency = 0.25, Color = Color3.new(1, 1, 1) }, { Index = i, Lane = lane })
			end
		end
	else
		add("WarnDisc", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 2, 2), Transparency = 0.65 })
		for i = 0, 35 do
			add("WarnEdge", { Size = Vector3.new(1.6, 0.16, 0.8), Transparency = 0.3 }, { Angle = i / 36 * math.pi * 2, Step = math.pi * 2 / 36 })
		end
		if kind == "Pull" then
			add("WarnInner", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.14, 2, 2), Transparency = 0.35, Color = Color3.new(1, 1, 1) })
			for i = 0, 7 do
				add("WarnSwirl", { Size = Vector3.new(1.2, 0.14, 4), Transparency = 0.35 }, { Angle = i / 8 * math.pi * 2 })
			end
		end
	end
	for _, p in list do
		p.Parent = visuals
	end
	b.warn = list
	b.warnKind = kind
end

-- place the warning on the floor, grown to `grow` of its size, pulsing
local function poseWarn(b: Boss, pos: Vector3, yaw: number, grow: number, t: number)
	if not b.warn then
		return
	end
	local s = b.state
	local kind = b.warnKind
	local floorY = ((attr(s, "FloorY") :: number?) or pos.Y) + 0.09
	local pulse = 0.5 + 0.5 * math.sin(t * 18)
	if kind == "Line" then
		local laneCache = {}
		for _, p in b.warn do
			local lane = (p:GetAttribute("Lane") :: number?) or 0
			local info = laneCache[lane]
			if not info then
				local target = (attr(s, if lane == 0 then "Target" else "Crowd" .. lane) :: Vector3?) or pos
				local d = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
				local dir = if d.Magnitude > 0.1 then d.Unit else Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
				local start = Vector3.new(pos.X, floorY, pos.Z)
				info = { base = CFrame.lookAt(start, start + dir), len = math.max(1, d.Magnitude) * grow,
					width = (attr(s, if lane == 0 then "Width" else "CrowdWidth") :: number?) or 10 }
				laneCache[lane] = info
			end
			local base, len, width = info.base, info.len, info.width
			if p.Name == "WarnStrip" then
				p.Size = Vector3.new(width, 0.1, len)
				p.CFrame = base * CFrame.new(0, 0, -len / 2)
				p.Transparency = 0.6 + 0.2 * pulse
			elseif p.Name == "WarnSide" then
				p.Size = Vector3.new(0.8, 0.16, len)
				p.CFrame = base * CFrame.new(((p:GetAttribute("Side") :: number?) or 1) * width / 2, 0.02, -len / 2)
				p.Transparency = 0.15 + 0.35 * pulse
			else -- arrows marching toward the end
				local i = (p:GetAttribute("Index") :: number?) or 1
				local along = (t * 40 + i * len / 3) % len
				p.Size = Vector3.new(width * 0.45, 0.14, 1.4)
				p.CFrame = base * CFrame.new(0, 0.03, -along)
			end
		end
		return
	end
	local centre = if kind == "Slam" then ((attr(s, "Target") :: Vector3?) or pos) else pos
	local radius = ((if kind == "Ring" then attr(s, "RingRadius") else attr(s, "Radius")) :: number? or 10) * grow
	local inner = (attr(s, "Inner") :: number?) or 0
	local floor = CFrame.new(centre.X, floorY, centre.Z) * CFrame.Angles(0, yaw, 0)
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
		elseif p.Name == "WarnInner" then
			p.Size = Vector3.new(p.Size.X, inner * 2, inner * 2)
			p.CFrame = floor * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.pi / 2)
			p.Transparency = 0.25 + 0.3 * pulse
		elseif p.Name == "WarnSwirl" then
			p.Size = Vector3.new(1.2, 0.14, radius * 0.45)
			p.CFrame = floor * CFrame.Angles(0, a + t * 2.5, 0) * CFrame.new(0, 0.05, -radius * 0.62) * CFrame.Angles(0, 0.7, 0)
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
	local kind = warnKindOf(s)
	local color = (attr(s, "Color") :: Color3?) or Color3.fromRGB(255, 80, 80)
	local radius = (attr(s, "Radius") :: number?) or 10
	local look = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local floorY = (attr(s, "FloorY") :: number?) or origin.Y
	local at = Vector3.new(origin.X, floorY, origin.Z)
	local shakeRadius = radius * 1.6
	if kind == "Cone" then
		local front = at + Vector3.new(0, 1, 0) + look * 4.5 * ((attr(s, "Scale") :: number?) or 1)
		task.delay(0.16, function()
			paperBurst(front + Vector3.new(0, 1, 0), look)
			sparkBurst(front, color, 18)
			shockwave(front, radius * 0.55, color, 0)
			playAt(front, "slam")
		end)
	elseif kind == "Slam" then
		local spot = (attr(s, "Target") :: Vector3?) or origin
		at = Vector3.new(spot.X, floorY, spot.Z)
		shockwave(at, radius, color, 0)
		shockwave(at, radius * 0.7, Color3.new(1, 1, 1), 0.08)
		sparkBurst(at + Vector3.new(0, 2, 0), color, 30)
		playAt(at, "slam")
		shakeRadius = radius * 1.8
	elseif kind == "Line" then
		playAt(at + Vector3.new(0, 4, 0), "charge")
		shakeRadius = ((attr(s, "Width") :: number?) or 10) * 1.5
	elseif kind == "Pull" then
		sparkBurst(at + Vector3.new(0, 6, 0), color, 30)
		playAt(at + Vector3.new(0, 6, 0), "pull")
	else -- Ring
		local r = (attr(s, "RingRadius") :: number?) or radius
		shockwave(at, r, color, 0.05)
		shockwave(at, r * 0.75, Color3.new(1, 1, 1), 0.15)
		playAt(at + Vector3.new(0, 4, 0), if b.kind == "BarristerBulldog" then "bark" else "slam")
		shakeRadius = r * 1.6
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and (root.Position - at).Magnitude < shakeRadius then
		shake(0.25, if kind == "Slam" then 0.9 else 0.35)
	end
end

------------------------------------------------------------------ the Megalodon's effects (docs/BOSS_ANIMATION.md)
-- Built-in smoke + the game's uploaded VFX textures (Models - Effects/ASSET_IDS.md). Kept light for phones: short
-- lives, a few dozen particles a second while it runs.
local SAND = Color3.fromRGB(226, 202, 150)
local ELECTRIC = Color3.fromRGB(120, 220, 255)
local TEX = {
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	streak = "rbxassetid://86651092788757", -- vfx_beam_streak
	dot = "rbxassetid://115135517607406", -- fx_dot
	spark = "rbxassetid://78182597037425", -- vfx_spark
	star = "rbxassetid://90593358027334", -- vfx_star_flare
}

local function emitter(props: { [string]: any }): ParticleEmitter
	local em = Instance.new("ParticleEmitter")
	em.Rate = 0
	em.LightEmission = 0
	em.LockedToPart = false
	for k, v in props do
		(em :: any)[k] = v
	end
	return em
end

-- a one-off burst at a frame (EmissionDirection is relative to it: Front = its LookVector)
local function burstAt(cf: CFrame, props: { [string]: any }, count: number)
	local holder = part({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = cf })
	holder.Parent = visuals
	local em = emitter(props)
	em.Parent = holder
	em:Emit(count)
	Debris:AddItem(holder, 2)
end

local function sandPuff(sc: number, speed: NumberRange, dirn: Enum.NormalId, spread: Vector2): { [string]: any }
	local k = sc / 3.2
	return { Texture = TEX.smoke, Color = ColorSequence.new(SAND), Lifetime = NumberRange.new(0.35, 0.6), Speed = speed,
		EmissionDirection = dirn, SpreadAngle = spread, Acceleration = Vector3.new(0, -30, 0), Drag = 3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6 * k), NumberSequenceKeypoint.new(1, 3.8 * k) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90) }
end

local function splashDrops(sc: number): { [string]: any }
	local k = sc / 3.2
	return { Texture = TEX.dot, Color = ColorSequence.new(Color3.fromRGB(160, 230, 255)), LightEmission = 0.3,
		Lifetime = NumberRange.new(0.35, 0.55), Speed = NumberRange.new(18, 28), EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -110, 0),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9 * k), NumberSequenceKeypoint.new(1, 0.3 * k) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.8) }) }
end

-- the charge's trail: sand from the feet, speed streaks round the body, water-like spray off the sides, and the
-- brake's plume thrown forward (one holder that rides along with it; emitters switched by state)
local function makeRunFx(sc: number): BasePart
	local holder = part({ Size = Vector3.new(6 * sc, 6 * sc, 2 * sc), Transparency = 1 })
	local k = sc / 3.2
	local trail = emitter(sandPuff(sc, NumberRange.new(10, 18), Enum.NormalId.Back, Vector2.new(25, 25)))
	trail.Name, trail.Rate = "Sand", 45
	trail.Shape = Enum.ParticleEmitterShape.Box
	trail.Parent = holder
	local streaks = emitter({ Texture = TEX.streak, Color = ColorSequence.new(Color3.new(1, 1, 1)), LightEmission = 0.3,
		Lifetime = NumberRange.new(0.1, 0.16), Speed = NumberRange.new(60, 90), EmissionDirection = Enum.NormalId.Back,
		Orientation = Enum.ParticleOrientation.VelocityParallel, Shape = Enum.ParticleEmitterShape.Box,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * k), NumberSequenceKeypoint.new(1, 0.2 * k) }),
		Squash = NumberSequence.new(-1.2),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) })
	streaks.Name, streaks.Rate = "Streaks", 50
	streaks.Parent = holder
	local spray = emitter(splashDrops(sc))
	spray.Name, spray.Rate = "Spray", 40
	spray.SpreadAngle = Vector2.new(80, 20)
	spray.Parent = holder
	local plume = emitter(sandPuff(sc, NumberRange.new(16, 26), Enum.NormalId.Front, Vector2.new(30, 20)))
	plume.Name, plume.Rate = "Plume", 90
	plume.Parent = holder
	for _, em in holder:GetChildren() do
		(em :: ParticleEmitter).Enabled = false
	end
	holder.Parent = visuals
	return holder
end

-- a Feeding Frenzy sand shark: a dorsal fin cutting the sand with a glowing edge (one part + an edge, moved as one)
local function makeShark(color: Color3): BasePart
	local fin = part({ Size = Vector3.new(0.9, 4.2, 4.2), Color = Color3.fromRGB(90, 110, 140), Material = Enum.Material.SmoothPlastic })
	local edge = part({ Size = Vector3.new(1.1, 1, 1), Color = color, Material = Enum.Material.Neon })
	edge.Name = "Edge"
	edge.Parent = fin
	fin.Parent = visuals
	return fin
end

local function poseShark(fin: BasePart, at: Vector3, dir: Vector3, sink: number, t: number)
	local base = CFrame.lookAt(at, at + dir) * CFrame.Angles(0, 0, math.sin(t * 22) * 0.15)
	fin.CFrame = base * CFrame.new(0, 1 - sink, 0) * CFrame.Angles(math.rad(-35), 0, 0)
	local edge = fin:FindFirstChild("Edge") :: BasePart?
	if edge then
		edge.CFrame = base * CFrame.new(0, 3.4 - sink, 1.6)
	end
end

-- the Megalodon's one-shot and repeating effects, by state and time into it (e); timings match its Blender clips
local function megalodonFx(b: Boss, state: string, e: number, total: number, pos: Vector3, sc: number, t: number)
	local s = b.state
	local look = Vector3.new(-math.sin(b.yaw), 0, -math.cos(b.yaw))
	local right = Vector3.new(-look.Z, 0, look.X)
	local floorY = (attr(s, "FloorY") :: number?) or pos.Y
	local ground = Vector3.new(pos.X, floorY + 0.5, pos.Z)
	local function once(key: string): boolean
		if b.fired[key] then
			return false
		end
		b.fired[key] = true
		return true
	end
	local speed = (attr(s, "CrowdSpeed") :: number?) or 120
	-- the sand sharks (crowd lanes)
	local function sharkAt(i: number, along: number): (Vector3, Vector3)
		local d = Vector3.new(b.lanes[i].X - b.laneFrom.X, 0, b.lanes[i].Z - b.laneFrom.Z)
		local dir = if d.Magnitude > 0.1 then d.Unit else look
		return Vector3.new(b.laneFrom.X, floorY, b.laneFrom.Z) + dir * along, dir
	end
	if state == "windup" then
		if once("sniff") then
			playAt(pos + Vector3.new(0, 7 * sc, 0), "sniff")
			b.lanes, b.laneFrom = {}, pos
			for i = 1, (attr(s, "CrowdN") :: number?) or 0 do
				local lane = attr(s, "Crowd" .. i) :: Vector3?
				if lane then
					table.insert(b.lanes, lane)
				end
			end
		end
		for i, at in { 0.4, 0.57 } do -- two paw scrapes: sand kicked out BEHIND it, low (never over the warning)
			if e >= at and once("scrape" .. i) then
				local foot = ground + right * 0.85 * sc - look * 1.0 * sc
				burstAt(CFrame.lookAt(foot, foot - look + Vector3.new(0, 0.4, 0)), sandPuff(sc, NumberRange.new(9, 16), Enum.NormalId.Front, Vector2.new(25, 20)), 6)
				playAt(foot, "scrape")
			end
		end
		if e >= 0.6 and os.clock() - b.fxAt > 0.05 and b.glow[1] then -- electric crackle off the glowing fin
			b.fxAt = os.clock()
			burstAt(b.glow[1].CFrame, { Texture = TEX.spark, Color = ColorSequence.new(ELECTRIC), LightEmission = 0.3,
				Lifetime = NumberRange.new(0.12, 0.22), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9 * sc / 3.2), NumberSequenceKeypoint.new(1, 0) }) }, 2)
		end
		if e >= 0.45 and #b.lanes > 0 then -- the sand sharks burst out of the sand at its feet and wait
			if once("sharks") then
				for i = 1, #b.lanes do
					local at = sharkAt(i, 7)
					burstAt(CFrame.lookAt(at, at + Vector3.new(0, 1, 0)), sandPuff(sc, NumberRange.new(8, 15), Enum.NormalId.Front, Vector2.new(40, 40)), 7)
					table.insert(b.sharks, makeShark(ELECTRIC))
				end
			end
			for i, fin in b.sharks do
				local at, dir = sharkAt(i, 7)
				poseShark(fin, at, dir, 5 - 5 * backOut((e - 0.45) / 0.18), t)
			end
		end
	elseif state == "attack" then
		if once("launch") then
			shockwave(ground, 18, ELECTRIC, 0)
			burstAt(CFrame.lookAt(ground, ground + Vector3.new(0, 1, 0)), sandPuff(sc, NumberRange.new(14, 22), Enum.NormalId.Front, Vector2.new(80, 80)), 14)
			playAt(ground, "launch")
			b.runFx = b.runFx or makeRunFx(sc)
		end
		local fx = b.runFx
		if fx then
			fx.CFrame = CFrame.lookAt(ground + Vector3.new(0, 3 * sc, 0), ground + Vector3.new(0, 3 * sc, 0) + look)
			local braking = e > total - 0.2
			for _, em in fx:GetChildren() do
				local on = if em.Name == "Plume" then braking else not braking
				;(em :: ParticleEmitter).Enabled = on
			end
		end
		for i, fin in b.sharks do -- racing down the lanes, a wake of sand behind each
			local d = Vector3.new(b.lanes[i].X - b.laneFrom.X, 0, b.lanes[i].Z - b.laneFrom.Z).Magnitude
			local travel = math.max(0, (d - 7) / speed)
			local at, dir = sharkAt(i, 7 + speed * math.min(e, travel))
			poseShark(fin, at, dir, 5 * math.clamp((e - travel) / 0.2, 0, 1) ^ 3, t)
			if e < travel and os.clock() - b.fxAt > 0.06 then
				burstAt(CFrame.lookAt(at, at - dir + Vector3.new(0, 0.6, 0)), sandPuff(sc * 0.7, NumberRange.new(6, 11), Enum.NormalId.Front, Vector2.new(50, 15)), 2)
			end
		end
		if os.clock() - b.fxAt > 0.06 then
			b.fxAt = os.clock()
		end
	else
		if b.runFx then
			for _, em in b.runFx:GetChildren() do
				(em :: ParticleEmitter).Enabled = false
			end
		end
		if state == "dizzy" and once("stop") then -- the skid stops: a small ring + dust thrown forward
			shockwave(ground, 10, SAND, 0)
			burstAt(CFrame.lookAt(ground + look * sc, ground + look * 2 * sc + Vector3.new(0, 0.5, 0)), sandPuff(sc, NumberRange.new(10, 18), Enum.NormalId.Front, Vector2.new(60, 25)), 10)
			playAt(ground, "skid")
			local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if me and (me.Position - ground).Magnitude < 30 then
				shake(0.2, 0.3)
			end
		elseif state == "recover" and e >= 0.05 and once("shakeoff") then -- the wet-dog shake flings drops
			local head = ground + Vector3.new(0, 6 * sc, 0)
			burstAt(CFrame.lookAt(head, head + Vector3.new(0, 1, 0)), splashDrops(sc), 10)
			playAt(head, "shakeoff")
		end
		if #b.sharks > 0 and state ~= "windup" then
			for _, fin in b.sharks do
				fin:Destroy()
			end
			b.sharks = {}
		end
	end
end

-- dizzy stars circling over its head (the Megalodon after a charge)
local function poseStars(b: Boss, pos: Vector3, on: boolean, t: number)
	if not on then
		if b.stars then
			for _, p in b.stars do
				p:Destroy()
			end
			b.stars = nil
		end
		return
	end
	local s = b.state
	local sc = (attr(s, "Scale") :: number?) or 1
	if not b.stars then
		b.stars = {}
		for _ = 1, 3 do
			-- a spinning gold cartoon star (the uploaded star flare on a billboard; the part only carries it)
			local p = part({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1 })
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromScale(sc * 1.1, sc * 1.1)
			gui.LightInfluence = 0
			gui.Parent = p
			local img = Instance.new("ImageLabel")
			img.Name = "Star"
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromScale(1, 1)
			img.Image = TEX.star
			img.ImageColor3 = Color3.fromRGB(255, 220, 70)
			img.Parent = gui
			p.Parent = visuals
			table.insert(b.stars :: { BasePart }, p)
		end
	end
	local top = pos + Vector3.new(0, ((b.model:GetAttribute("Height") :: number?) or 8) * sc + sc, 0)
	for i, p in b.stars :: { BasePart } do
		local a = t * 5 + i * math.pi * 2 / 3
		p.CFrame = CFrame.new(top + Vector3.new(math.cos(a), 0.2 * math.sin(t * 7 + i), math.sin(a)) * sc * 1.3)
		local img = p:FindFirstChild("Star", true) :: ImageLabel?
		if img then
			img.Rotation = (t * 220 + i * 40) % 360
		end
	end
end

------------------------------------------------------------------ the frame
RunService.Heartbeat:Connect(function(dt)
	local t = now()
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- how far a point is from what the player sees: the camera, or their character (whichever is nearer)
	local function near(p: Vector3): number
		local d = (p - camPos).Magnitude
		return if me then math.min(d, (p - me.Position).Magnitude) else d
	end
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
			b.fired = {}
			if state == "windup" then
				makeWarn(b)
				playAt(pos + Vector3.new(0, 5, 0), "windup")
			elseif state == "attack" then
				if b.warnKind ~= "Pull" then -- (a Pull's warning stays while it drags)
					clearWarn(b)
				end
				if near(pos) < DRAW_DISTANCE then
					attackEffects(b, pos, yaw)
				end
			else
				clearWarn(b)
			end
		end
		local kind = warnKindOf(s)
		-- a Pull drags the local player in (walking straight out escapes: it's slower than walking)
		if state == "attack" and kind == "Pull" and not ragdolled then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local d = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
				if d.Magnitude <= ((attr(s, "Radius") :: number?) or 0) and d.Magnitude > 0.5 then
					root.CFrame += d.Unit * ((attr(s, "PullSpeed") :: number?) or 0) * dt
				end
			end
		end
		if near(pos) > DRAW_DISTANCE then
			if b.model.Parent then
				b.model.Parent = nil -- far away: not drawn at all
			end
			continue
		end
		if not b.model.Parent then
			b.model.Parent = visuals
		end
		-- moving (walking, charging, rolling): the stride follows the real speed
		local moving = false
		local m0, m1 = (attr(s, "MoveStart") :: number?) or 0, (attr(s, "MoveEnd") :: number?) or 0
		if t < m1 and m1 > m0 and state ~= "windup" then
			local from, to = attr(s, "From") :: Vector3, attr(s, "To") :: Vector3
			local speed = (to - from).Magnitude / (m1 - m0)
			b.phase += dt * speed / (4 * ((attr(s, "Scale") :: number?) or 1)) * math.pi -- (bigger = longer strides)
			moving = true
		end
		b.walk += ((if moving then 1 else 0) - b.walk) * math.min(1, dt * 6)
		local anim = ANIMS[b.kind]
		local lead = 0
		if anim and state == "windup" then
			-- the whip-round: holds a beat (the sniff), then turns to its target with an overshoot; the head leads
			if b.turnStart ~= t0 then
				b.turnStart, b.turnFrom = t0, b.yaw
			end
			local d = (yaw - b.turnFrom + math.pi) % (math.pi * 2) - math.pi
			b.yaw = b.turnFrom + d * backOut((t - t0 - 0.04) / 0.2)
			lead = 0.35 * ((yaw - b.yaw + math.pi) % (math.pi * 2) - math.pi)
		else
			b.yaw = lerpAngle(b.yaw, yaw, math.min(1, dt * (if state == "windup" then 12 else 6)))
		end
		if state == "windup" then
			poseWarn(b, pos, yaw, 0.45 + 0.55 * easeOut(a / 0.4), t)
		elseif state == "attack" and b.warnKind == "Pull" then
			poseWarn(b, pos, yaw, 1, t)
		end
		-- a roll / charge leaves a trail of puffs in its colour
		if state == "attack" and kind == "Line" and moving and not anim and os.clock() - b.trailAt > 0.07 then
			b.trailAt = os.clock()
			sparkBurst(pos + Vector3.new(0, 1.5, 0), (attr(s, "Color") :: Color3?) or Color3.new(1, 1, 1), 5)
		end
		poseStars(b, pos, state == "dizzy", t)
		local pose = POSES[b.kind]
		local rootOff, rots = CFrame.new(), {}
		if pose then
			rootOff, rots = pose(b, state, a, t, (attr(s, "Idle") :: string?) or "")
		end
		local sc = (attr(s, "Scale") :: number?) or 1 -- (bobs and trembles grow with the boss)
		local squash = Vector3.one
		if anim then
			-- the Blender clip for this state, cross-faded with the POSES above
			local clipPose = clipPoseFor(anim, state, t - t0, t1 - t0, sc)
			if clipPose then
				b.lastClip = clipPose
			end
			b.clipW = math.clamp(b.clipW + (if clipPose then dt else -dt) / CLIP_FADE, 0, 1)
			local cp = clipPose or b.lastClip
			local glow = 0
			if cp and b.clipW > 0 then
				local mixed = mixPose({ root = rootOff, scale = Vector3.one, rots = rots, fx = {} }, cp, ease(b.clipW))
				rootOff, rots, squash, glow = mixed.root, mixed.rots, mixed.scale, mixed.fx.FinGlow or 0
			end
			if lead ~= 0 then
				rots.Torso = (rots.Torso or CFrame.identity) * CFrame.Angles(0, lead, 0)
			end
			if math.abs(glow - b.glowNow) > 0.01 then
				b.glowNow = glow
				for _, p in b.glow do
					p.Transparency = 1 - 0.6 * glow
				end
			end
			if b.kind == "Megalodon" then
				megalodonFx(b, state, t - t0, t1 - t0, pos, sc, t)
			end
		end
		local root = CFrame.new(pos) * CFrame.Angles(0, b.yaw, 0) * CFrame.new(rootOff.Position * sc) * rootOff.Rotation
		-- squash / stretch (clips): part positions and sizes scaled round its feet in its own axes
		local squashed = math.abs(squash.X - 1) + math.abs(squash.Y - 1) + math.abs(squash.Z - 1) > 0.006
		local world: { [string]: CFrame } = {}
		for _, g in b.groups do
			local parentCF = if g.parent ~= "" and world[g.parent] then world[g.parent] else CFrame.identity
			local rot = rots[g.name]
			local w = if rot then parentCF * g.joint * rot * g.joint:Inverse() else parentCF
			world[g.name] = w
			for i, p in g.parts do
				local l = w * g.rest[i]
				table.insert(parts, p)
				if squashed then
					table.insert(frames, root * CFrame.new(l.Position * squash) * l.Rotation)
					local size = g.sizes[i]
					p.Size = Vector3.new(size.X * (l.XVector * squash).Magnitude, size.Y * (l.YVector * squash).Magnitude,
						size.Z * (l.ZVector * squash).Magnitude)
				else
					table.insert(frames, root * l)
				end
			end
		end
		if b.squashed and not squashed then -- back to its real size
			for _, g in b.groups do
				for i, p in g.parts do
					p.Size = g.sizes[i]
				end
			end
		end
		b.squashed = squashed
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
-- (`ragdolled` is declared with the bosses, above.)

local function ragdoll(away: Vector3, power: number, seconds: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	-- mid-trip (Shared.TravelFx anchors you and plays its animation): no fling, no ragdoll - its get-up step would run
	-- while you're anchored and leave you stuck in Physics (2026-10-13 playtest)
	if player:GetAttribute("Traveling") then
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
