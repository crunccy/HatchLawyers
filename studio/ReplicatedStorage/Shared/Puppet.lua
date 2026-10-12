-- Puppet: code-driven animation for the game's blocky characters (desk lawyers and clients, skin
-- models, judges). None of them have skeletons, so Puppet.new sorts a model's parts into torso / head /
-- arms / legs (by name first, then by position), finds the neck, shoulder and hip pivots, and
-- Puppet:apply poses every part from those pivots. Client only: poses are local, nothing replicates.
--
-- Animations are plain functions. A pose is { rootPos, rootRot, head, armL, armR, legL, legR }:
-- rootPos in studs, everything else Euler degrees in the model's own space (it faces -Z).
--   arm X > 0 swings the arm forward, armL Z < 0 / armR Z > 0 lift the arm out to the side
--   head X > 0 looks up, head Y > 0 turns to the character's left (screen right in the court)
--   rootRot X < 0 leans forward

local Puppet = {}
Puppet.__index = Puppet

local V0 = Vector3.zero
local function v(x: number?, y: number?, z: number?): Vector3
	return Vector3.new(x or 0, y or 0, z or 0)
end
local function ang(e: Vector3): CFrame
	return CFrame.Angles(math.rad(e.X), math.rad(e.Y), math.rad(e.Z))
end
local sin, cos, abs, clamp = math.sin, math.cos, math.abs, math.clamp

-- names we can trust; anything else is sorted by where it sits
local NAMED: { [string]: string } = {
	Head = "head",
	Torso = "torso", UpperTorso = "torso", LowerTorso = "torso", HumanoidRootPart = "torso", Robe = "torso",
	["Left Arm"] = "arm", ["Left Hand"] = "arm", LeftUpperArm = "arm", LeftLowerArm = "arm", LeftHand = "arm",
	["Right Arm"] = "arm", ["Right Hand"] = "arm", RightUpperArm = "arm", RightLowerArm = "arm", RightHand = "arm",
	["Left Leg"] = "leg", LeftUpperLeg = "leg", LeftLowerLeg = "leg", LeftFoot = "leg",
	["Right Leg"] = "leg", RightUpperLeg = "leg", RightLowerLeg = "leg", RightFoot = "leg",
}
local GROUPS = { "torso", "head", "armL", "armR", "legL", "legR" }

-- every live puppet by model, so other scripts can copy a model in its rest pose
local registry: { [Model]: any } = setmetatable({}, { __mode = "k" }) :: any

function Puppet.emptyPose()
	return { rootPos = V0, rootRot = V0, head = V0, armL = V0, armR = V0, legL = V0, legR = V0 }
end

-- Builds a puppet from the model as it stands now (that pose becomes the rest pose).
function Puppet.new(model: Model)
	local self = setmetatable({}, Puppet)
	self.model = model
	self.base = model:GetPivot()
	self:_sort()
	registry[model] = self
	return self
end

-- Clones a model as it looks at rest, even if a puppet is currently posing it.
function Puppet.cloneAtRest(model: Model): Model
	local puppet = registry[model]
	if not puppet then
		return model:Clone()
	end
	local saved = {}
	for _, list in puppet.groups do
		for _, e in list do
			saved[e.part] = e.part.CFrame
		end
	end
	puppet:reset()
	local copy = model:Clone()
	for part, cf in saved do
		part.CFrame = cf
	end
	return copy
end

function Puppet:_sort()
	local model, base = self.model, self.base
	-- side-on characters (a shark standing along the desk, 2026-10-10 model remakes): attribute Sideways on the
	-- model or its SkinModel. Their "lean forward" would roll them sideways, so apply turns it into a nose dip.
	local skin = model:FindFirstChild("SkinModel")
	self.sideways = model:GetAttribute("Sideways") == true or (skin ~= nil and skin:GetAttribute("Sideways") == true)
	local gavelArm = model:FindFirstChild("GavelArm")
	local parts = {}
	local y0, headPart, torsoHalf = math.huge, nil, nil
	local legTop = nil
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rest = base:ToObjectSpace(d.CFrame)
			table.insert(parts, { part = d, rest = rest })
			if d.Transparency < 1 then
				y0 = math.min(y0, rest.Position.Y - d.Size.Y / 2)
				local kind = NAMED[d.Name]
				if d.Name == "Head" and (not headPart or headPart.Transparency >= 1) then
					headPart = d
				elseif kind == "torso" and d.Name ~= "HumanoidRootPart" then
					torsoHalf = math.max(torsoHalf or 0, d.Size.X / 2)
				elseif kind == "leg" then
					legTop = math.max(legTop or -math.huge, rest.Position.Y + d.Size.Y / 2)
				end
			end
		end
	end
	if y0 == math.huge then
		y0 = 0
	end
	local neckY
	if headPart then
		neckY = base:ToObjectSpace(headPart.CFrame).Position.Y - headPart.Size.Y / 2
	else
		local _, size = model:GetBoundingBox()
		neckY = y0 + size.Y * 0.72
	end
	torsoHalf = torsoHalf or 0.75
	local hipY = legTop or (y0 + 0.55 * (neckY - y0))
	local armFloor = y0 + 0.15 * (neckY - y0)
	self.groups = {}
	for _, g in GROUPS do
		self.groups[g] = {}
	end
	for _, e in parts do
		local p, c = e.part, e.rest.Position
		local kind = NAMED[p.Name]
		local side = if c.X < 0 then "L" else "R"
		local group
		if gavelArm and p:IsDescendantOf(gavelArm) then
			group = "armR"
		elseif kind == "head" then
			group = "head"
		elseif kind == "torso" then
			group = "torso"
		elseif kind == "arm" then
			group = "arm" .. side
		elseif kind == "leg" then
			group = "leg" .. side
		elseif c.Y > neckY + 0.05 and abs(c.X) <= torsoHalf + 0.3 then
			group = "head"
		elseif abs(c.X) > torsoHalf + 0.03 and c.Y > armFloor then
			group = "arm" .. side
		elseif c.Y < hipY - 0.05 and abs(c.X) > 0.05 then
			group = "leg" .. side
		else
			group = "torso"
		end
		table.insert(self.groups[group], e)
	end
	-- pivots: the joint sits at the top of the HIGHEST VISIBLE part of a limb. (Not the tallest part:
	-- multi-part arms like UpperArm/LowerArm/Hand would pivot at the elbow or wrist, and a model skin's
	-- hidden blocky arm would put the shoulder too high. Either way raised arms came off the body.)
	local function biggest(list)
		local best, bestTop = nil, -math.huge
		for pass = 1, 2 do
			for _, e in list do
				if pass == 2 or e.part.Transparency < 1 then
					local top = e.rest.Position.Y + e.part.Size.Y / 2
					if top > bestTop then
						best, bestTop = e, top
					end
				end
			end
			if best then
				break -- only fall back to hidden parts if the limb has no visible ones
			end
		end
		return best
	end
	self.joints = {}
	local headZ = if headPart then base:ToObjectSpace(headPart.CFrame).Position.Z else 0
	self.joints.head = CFrame.new(0, neckY, headZ)
	for _, s in { "L", "R" } do
		local arm = biggest(self.groups["arm" .. s])
		if arm then
			local c, sz = arm.rest.Position, arm.part.Size
			self.joints["arm" .. s] = CFrame.new(c.X, c.Y + sz.Y / 2 - math.min(sz.X, sz.Z) / 2, c.Z)
		end
		local leg = biggest(self.groups["leg" .. s])
		if leg then
			local c, sz = leg.rest.Position, leg.part.Size
			self.joints["leg" .. s] = CFrame.new(c.X, c.Y + sz.Y / 2 - 0.1, c.Z)
		end
	end
	if gavelArm and gavelArm:IsA("Model") then
		self.joints.armR = CFrame.new(base:ToObjectSpace(gavelArm.WorldPivot).Position)
	end
	self.height = neckY - y0
end

-- Poses every part. `base` (optional) moves the whole puppet.
function Puppet:apply(pose, base: CFrame?)
	if base then
		self.base = base
	end
	local rot = pose.rootRot
	if self.sideways then
		-- lean forward (x) -> dip the nose (+x end) down; keep only a little of the turn and none of the roll
		rot = Vector3.new(0, rot.Y * 0.3, rot.X * 0.6)
	end
	local root = self.base * CFrame.new(pose.rootPos) * ang(rot)
	for group, list in self.groups do
		local joint = self.joints[group]
		local g = root
		if joint and group ~= "torso" then
			g = root * joint * ang(pose[group]) * joint:Inverse()
		end
		for _, e in list do
			e.part.CFrame = g * e.rest
		end
	end
end

function Puppet:reset()
	self:apply(Puppet.emptyPose())
end

-- Re-sorts after parts were added or removed (a skin change), keeping the current base.
function Puppet:rebuild()
	self:reset()
	self:_sort()
end

----------------------------------------------------------------------------------------------------
-- Animation library
----------------------------------------------------------------------------------------------------

local function copy(p)
	return table.clone(p)
end

-- Idle loops per class. t = seconds, ph = per-character random phase.
local IDLE = {}
function IDLE.base(t: number, ph: number, speed: number?)
	local s = speed or 1
	local breathe = sin(t * 2.1 * s + ph)
	return {
		rootPos = v(0, 0.035 * breathe, 0),
		rootRot = v(0, 3 * sin(t * 0.5 * s + ph), 1.5 * sin(t * 0.7 * s + ph)),
		head = v(2 * sin(t * 0.9 * s + ph) + 1.5 * breathe, 8 * sin(t * 0.37 * s + ph * 2), 2 * sin(t * 0.6 + ph)),
		armL = v(4 * sin(t * 1.1 * s + ph), 0, -4 - 2 * breathe),
		armR = v(4 * sin(t * 1.1 * s + ph + 1), 0, 4 + 2 * breathe),
		legL = v(0, 0, -1.5 * sin(t * 0.7 * s + ph)),
		legR = v(0, 0, -1.5 * sin(t * 0.7 * s + ph)),
	}
end
function IDLE.lawyer(t, ph)
	local p = IDLE.base(t, ph)
	p.head = p.head + v(5, 0, 0) -- chin up, confident
	p.armR = v(18 + 4 * sin(t * 1.3 + ph), 0, -6) -- hand resting in front, like holding a lapel
	return p
end
function IDLE.client(t, ph)
	local p = IDLE.base(t, ph, 1.6) -- fidgety
	local shift = sin(t * 1.4 + ph)
	p.rootPos = p.rootPos + v(0.06 * shift, 0, 0)
	p.rootRot = p.rootRot + v(0, 0, 3 * shift)
	p.head = p.head + v(-3, 10 * sin(t * 1.3 + ph), 0)
	p.armL = v(32 + 6 * sin(t * 5 + ph), 0, 18) -- hands clasped nervously
	p.armR = v(32 + 6 * sin(t * 5 + ph + 1), 0, -18)
	return p
end
function IDLE.defendant(t, ph)
	local p = IDLE.base(t, ph, 0.9)
	p.head = p.head + v(8, 0, 4) -- smug chin-up tilt
	p.armL = v(78, 0, 48 + 3 * sin(t * 2 + ph)) -- arms crossed
	p.armR = v(84, 0, -48 - 3 * sin(t * 2 + ph))
	p.rootRot = p.rootRot + v(3, 0, 2)
	return p
end
function IDLE.judge(t, ph)
	local p = IDLE.base(t, ph, 0.6) -- slow and dignified
	p.head = v(1.5 * sin(t * 1.2), 18 * sin(t * 0.28 + ph), 0) -- looks over the room
	p.armL = v(38 + 2 * sin(t * 1.3), 0, 10) -- hand resting on the bench
	p.armR = v(40 + 3 * sin(t * 1.1 + 1), 0, 0) -- holding the gavel
	return p
end
function IDLE.working(t, ph)
	-- a desk lawyer at work: typing, glancing at the screen and the client
	local p = IDLE.base(t, ph)
	local tap = sin(t * 14 + ph)
	p.armL = v(58 + 5 * tap, 0, 14)
	p.armR = v(58 - 5 * tap, 0, -14)
	p.head = v(-14 + 3 * sin(t * 0.8), 10 * sin(t * 0.25 + ph), 0)
	p.rootRot = p.rootRot + v(-5, 0, 0)
	return p
end
Puppet.Idle = IDLE

-- One-shot clips: { dur = seconds, fn = function(u, idlePose) -> pose }
local CLIPS = {}
local function clip(name, dur, fn)
	CLIPS[name] = { dur = dur, fn = fn }
end
local function hop(u, freq, height)
	return abs(sin(u * freq)) * height
end

clip("talk", 1.6, function(u, p)
	p = copy(p)
	p.armR = v(55 + 25 * sin(u * 9), 0, 14 + 10 * sin(u * 5))
	p.armL = p.armL + v(10 * sin(u * 7 + 1), 0, -6)
	p.head = p.head + v(6 * sin(u * 10), 6 * sin(u * 3), 0)
	p.rootPos = p.rootPos + v(0, hop(u, 6, 0.08), 0)
	return p
end)
clip("judgeTalk", 1.6, function(u, p)
	p = copy(p)
	p.armL = v(70 + 20 * sin(u * 8), 0, -10)
	p.head = p.head + v(5 * sin(u * 9), 0, 4)
	p.rootRot = p.rootRot + v(-4, 0, 0)
	return p
end)
clip("objection", 1.5, function(u, p)
	p = copy(p)
	local snap = clamp(u / 0.15, 0, 1)
	p.armL = v(85 * snap, 0, -70 * snap) -- point across the room
	p.armR = v(10, 0, 12)
	p.head = v(-2, 28 * snap, 0)
	p.rootRot = v(-12 * snap, 18 * snap, 0)
	p.rootPos = v(0, if u < 0.25 then hop(u, 12, 0.35) else 0, 0)
	p.legL = v(-20 * snap, 0, 0)
	return p
end)
clip("think", 2.2, function(u, p)
	p = copy(p)
	p.armR = v(135 + 4 * sin(u * 6), 0, -38) -- hand on chin
	p.armL = v(40, 0, 30)
	p.head = v(10, -12, 9)
	p.rootRot = p.rootRot + v(0, 0, 3)
	return p
end)
clip("celebrate", 2.2, function(u, p)
	p = copy(p)
	local pump = sin(u * 12)
	p.rootPos = v(0, hop(u, 6, 0.7), 0)
	p.armL = v(10, 0, -150 - 15 * pump)
	p.armR = v(10, 0, 150 + 15 * pump)
	p.head = v(18, 10 * sin(u * 6), 0)
	p.legL = v(20 * abs(sin(u * 6)), 0, 0)
	p.legR = v(20 * abs(sin(u * 6 + 1)), 0, 0)
	return p
end)
clip("cheer", 2.0, function(u, p)
	p = copy(p)
	p.rootPos = v(0, hop(u, 7, 0.45), 0)
	p.armL = v(160 + 15 * sin(u * 14), 0, -20)
	p.armR = v(160 + 15 * sin(u * 14 + 2), 0, 20)
	p.head = v(15, 0, 0)
	return p
end)
clip("clap", 1.6, function(u, p)
	p = copy(p)
	local c = abs(sin(u * 11))
	p.armL = v(62, 0, 8 + 22 * c)
	p.armR = v(62, 0, -8 - 22 * c)
	p.rootPos = p.rootPos + v(0, hop(u, 5.5, 0.12), 0)
	p.head = p.head + v(8, 0, 0)
	return p
end)
clip("slump", 2.4, function(u, p)
	p = copy(p)
	local k = clamp(u / 0.5, 0, 1)
	p.rootPos = v(0, -0.15 * k, 0)
	p.rootRot = v(-9 * k, 0, 0)
	p.head = v(-28 * k, 6 * sin(u * 2), 0)
	p.armL = v(4, 0, 2)
	p.armR = v(4, 0, -2)
	return p
end)
clip("despair", 2.6, function(u, p)
	p = copy(p)
	p.armL = v(150, 0, 42) -- hands on head
	p.armR = v(150, 0, -42)
	p.head = v(-16, 12 * sin(u * 8), 0)
	p.rootPos = v(0, -0.12, 0)
	p.rootRot = v(-6, 0, 3 * sin(u * 4))
	return p
end)
clip("worried", 1.9, function(u, p)
	p = copy(p)
	p.armL = v(118, 0, 24) -- hands up to the face
	p.armR = v(118, 0, -24)
	p.head = v(-6, 9 * sin(u * 9), 0)
	p.rootPos = v(0.04 * sin(u * 30), 0, 0)
	return p
end)
clip("nod", 1.2, function(u, p)
	p = copy(p)
	p.head = p.head + v(-16 * abs(sin(u * 7)), 0, 0)
	return p
end)
clip("shake", 1.2, function(u, p)
	p = copy(p)
	p.head = v(-4, 20 * sin(u * 11), 0)
	return p
end)
clip("protest", 1.9, function(u, p)
	p = copy(p)
	p.armL = v(105 + 45 * sin(u * 10), 0, -30)
	p.armR = v(105 + 45 * sin(u * 10 + 3), 0, 30)
	p.rootPos = v(0, hop(u, 10, 0.25), 0)
	p.head = v(5, 15 * sin(u * 5), 0)
	return p
end)
clip("shrug", 1.5, function(u, p)
	p = copy(p)
	local k = sin(clamp(u / 1.3, 0, 1) * math.pi)
	p.armL = v(25 * k, 0, -38 * k)
	p.armR = v(25 * k, 0, 38 * k)
	p.head = v(4, 0, 14 * k)
	p.rootPos = v(0, 0.1 * k, 0)
	return p
end)
clip("sweat", 2.0, function(u, p)
	p = copy(p)
	p.rootPos = v(0.05 * sin(u * 40), 0, 0)
	p.head = v(-4, 24 * sin(u * 6), 0)
	p.armL = v(22, 0, 12)
	p.armR = v(22, 0, -12)
	return p
end)
clip("smug", 1.8, function(u, p)
	p = copy(p)
	p.head = p.head + v(10, -8, 10)
	p.rootRot = p.rootRot + v(5, 0, 0)
	p.rootPos = p.rootPos + v(0, 0.06 * sin(u * 4), 0)
	return p
end)
clip("glance", 1.4, function(u, p)
	p = copy(p)
	p.head = p.head + v(0, 32 * sin(u * 2.3), 0)
	return p
end)
clip("checkWatch", 1.9, function(u, p)
	p = copy(p)
	p.armL = v(92, 0, 42)
	p.head = v(-22, -14, 0)
	return p
end)
clip("scratchHead", 1.9, function(u, p)
	p = copy(p)
	p.armR = v(158 + 6 * sin(u * 22), 0, -26)
	p.head = v(-4, 0, -10)
	return p
end)
clip("lean", 1.4, function(u, p)
	p = copy(p)
	local k = sin(clamp(u / 1.3, 0, 1) * math.pi)
	p.rootRot = v(-14 * k, 0, 0)
	p.head = v(-6 * k, 0, 0)
	return p
end)
clip("doze", 2.8, function(u, p)
	p = copy(p)
	if u < 2.1 then
		local k = clamp(u / 1.6, 0, 1)
		p.head = v(-34 * k + 3 * sin(u * 3), 0, 8 * k)
		p.rootPos = v(0, -0.08 * k, 0)
		p.armL = v(20, 0, 6)
	else
		p.head = v(12, 14 * sin(u * 30), 0) -- snaps awake
		p.rootPos = v(0, 0.1, 0)
	end
	return p
end)
clip("slam", 0.8, function(u, p)
	p = copy(p)
	local a
	if u < 0.2 then
		a = 40 + 110 * (u / 0.2)
	elseif u < 0.3 then
		a = 150 - 72 * ((u - 0.2) / 0.1)
	else
		a = 78 - 38 * clamp((u - 0.38) / 0.4, 0, 1)
	end
	p.armR = v(a, 0, 0)
	local impact = if u > 0.28 and u < 0.45 then 1 else 0
	p.rootRot = v(-6 * impact, 0, 0)
	p.head = v(-8 * impact, 0, 0)
	return p
end)
clip("pointGavel", 1.5, function(u, p)
	p = copy(p)
	p.armR = v(95, 0, -10 + 6 * sin(u * 8))
	p.head = v(-4, 0, 0)
	p.rootRot = v(-6, 0, 0)
	return p
end)
clip("type", 2.0, function(u, p)
	p = copy(p)
	local tap = sin(u * 18)
	p.armL = v(60 + 7 * tap, 0, 14)
	p.armR = v(60 - 7 * tap, 0, -14)
	p.head = v(-16, 0, 0)
	return p
end)
Puppet.Clips = CLIPS

-- Looping poses for moving characters (used by StarterPlayerScripts.ClientWalk).
-- walk: a bouncy cartoon stride. sit: on a couch (hips bent, knees forward, hands on the lap).
function Puppet.walkPose(t: number)
	local s = sin(t * 9)
	return {
		rootPos = v(0, abs(sin(t * 9)) * 0.16, 0),
		rootRot = v(-4, 4 * s, 0),
		head = v(0, -4 * s, 0),
		armL = v(-32 * s, 0, -6),
		armR = v(32 * s, 0, 6),
		legL = v(38 * s, 0, 0),
		legR = v(-38 * s, 0, 0),
	}
end

function Puppet.sitPose(t: number, height: number?, seatHeight: number?)
	-- drop the hips (about 0.42 of the height up) onto the cushion (FirmKit couches: ~1.75) and swing the legs forward
	local drop = math.min(0, (seatHeight or 1.8) - (height or 4.5) * 0.42)
	return {
		rootPos = v(0, drop, 0.15),
		rootRot = v(0, 0, 0),
		head = v(-4 + 3 * sin(t * 0.7), 8 * sin(t * 0.3), 0),
		armL = v(38, 0, 4),
		armR = v(38, 0, -4),
		legL = v(88, 0, 2),
		legR = v(88, 0, -2),
	}
end

-- Background fidgets each class picks from now and then.
local AMBIENT = {
	lawyer = { "glance", "checkWatch", "think", "nod" },
	client = { "glance", "worried", "scratchHead", "nod" },
	defendant = { "glance", "smug", "shrug", "scratchHead" },
	judge = { "glance", "nod", "lean", "glance", "doze" },
	working = { "glance", "type", "nod", "think", "checkWatch" },
}

----------------------------------------------------------------------------------------------------
-- Animator: idle loop + one action at a time + random fidgets + looking at things
----------------------------------------------------------------------------------------------------

local Animator = {}
Animator.__index = Animator

local function lerpPose(a, b, w)
	local out = {}
	for key, value in a do
		out[key] = value:Lerp(b[key] or value, w)
	end
	return out
end

function Puppet.animator(puppet, class: string)
	return setmetatable({
		puppet = puppet,
		class = class,
		phase = math.random() * 6,
		action = nil,
		nextFidget = os.clock() + 2 + math.random() * 4,
		lookAt = nil,
		fidgets = true,
	}, Animator)
end

-- Plays a clip now (replacing any running one).
function Animator:play(name: string)
	local c = CLIPS[name]
	if c then
		self.action = { clip = c, start = os.clock(), name = name }
		self.nextFidget = os.clock() + c.dur + 2 + math.random() * 4
	end
end

function Animator:isBusy(): boolean
	return self.action ~= nil
end

function Animator:step(t: number)
	local idleFn = IDLE[self.class] or IDLE.base
	local pose = idleFn(t, self.phase)
	if self.action then
		local c = self.action.clip
		local u = t - self.action.start
		if u >= c.dur then
			self.action = nil
		else
			local w = math.min(1, u / 0.15, (c.dur - u) / 0.25)
			pose = lerpPose(pose, c.fn(u, pose), w)
		end
	elseif self.fidgets and t > self.nextFidget then
		local list = AMBIENT[self.class]
		if list then
			self:play(list[math.random(#list)])
		end
	end
	-- turn the head toward whatever we're looking at (on top of the animation)
	if self.lookAt then
		local neck = self.puppet.base * self.puppet.joints.head
		local d = neck:PointToObjectSpace(self.lookAt)
		local yaw = math.deg(math.atan2(-d.X, -d.Z))
		pose.head = pose.head + v(0, clamp(yaw, -50, 50) * 0.8, 0)
	end
	self.puppet:apply(pose)
end

return Puppet
