--!strict
-- HatchFx (ReplicatedStorage.Shared.HatchFx, client only) - the VFX kit of the egg hatch v5 (2026-10-12, mr.robe:
-- "remake the animations everything to do with the eggs ... and add vfx ... make them 10000x cooler"; "current ladder,
-- maxed", "scale with rarity").
--   springs      an analytic damped spring (the idea behind Fraktality's spr, MIT - our own code): HatchFx.spring
--   camera shake noise shake with fade in / out, summed (the idea behind Sleitnick's RbxCameraShaker / EZ Camera
--                Shake, MIT - our own code): HatchFx.shake(...) adds one, HatchFx.shakeCFrame() is this frame's offset
--   post         bloom / colour correction / blur / depth of field on the camera (local only): postBegin / post / postEnd
--   pieces       shockwave rings (EggModels.FxRing, a Blender torus), god rays + light pillars (Beams), one-shot particle
--                bursts (sparks, confetti, dust, coins, shell bits) and an implosion
--   the ladder   HatchFx.ladder(rarity) -> how big each rarity's hatch is (break take, rings, rays, pillar, slow-mo...)
--   the break    HatchFx.breakApart(hatch, take, root, slow) plays the Blender rigid-body sim on the shell chunks
-- Textures are the game's VFX set (Shared.Effects.TEXTURES). Keep LightEmission low (<= 0.3 on sprites; the floors are
-- bright), Brightness up instead.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Effects = require(script.Parent:WaitForChild("Effects")) :: any
local T = Effects.TEXTURES

local HatchFx = {}
local WHITE = Color3.new(1, 1, 1)

local folder: Instance = workspace
function HatchFx.setFolder(f: Instance)
	folder = f
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
HatchFx.tween = tween

------------------------------------------------------------------ springs
export type Spring = { x: number, v: number, target: number, w: number, z: number }

-- freq in Hz, damping ratio (< 1 wobbles, 1 = no overshoot)
function HatchFx.spring(freq: number, damping: number, x0: number?): Spring
	local x = x0 or 0
	return { x = x, v = 0, target = x, w = freq * 2 * math.pi, z = math.clamp(damping, 0.01, 1) }
end

function HatchFx.stepSpring(s: Spring, dt: number): number
	local w, z = s.w, s.z
	local a = s.x - s.target
	local v = s.v
	if z >= 0.999 then -- critically damped
		local e = math.exp(-w * dt)
		local b = v + w * a
		s.x = s.target + e * (a + b * dt)
		s.v = e * (v - w * b * dt)
	else
		local wd = w * math.sqrt(1 - z * z)
		local e = math.exp(-z * w * dt)
		local c, sn = math.cos(wd * dt), math.sin(wd * dt)
		local b = (v + z * w * a) / wd
		s.x = s.target + e * (a * c + b * sn)
		s.v = e * (v * c - (z * w * b + wd * a) * sn)
	end
	return s.x
end

------------------------------------------------------------------ camera shake
type Shake = { mag: number, rough: number, fadeIn: number, fadeOut: number, hold: number, t0: number, seed: number }
local shakes: { Shake } = {}
local POS_INF, ROT_INF = 0.12, 0.9 -- (studs / degrees per unit of magnitude)

-- magnitude ~1 (a bump) .. 6 (an explosion); roughness = how fast it jitters (~4 slow .. 20 violent)
function HatchFx.shake(mag: number, rough: number?, fadeIn: number?, fadeOut: number?, hold: number?)
	table.insert(shakes, { mag = mag, rough = rough or 12, fadeIn = fadeIn or 0.02, fadeOut = fadeOut or 0.5, hold = hold or 0, t0 = os.clock(), seed = math.random() * 100 })
end

function HatchFx.shakeCFrame(): CFrame
	local now = os.clock()
	local px, py, pz, rx, ry, rz = 0, 0, 0, 0, 0, 0
	for i = #shakes, 1, -1 do
		local s = shakes[i]
		local age = now - s.t0
		local life = s.fadeIn + s.hold + s.fadeOut
		if age >= life then
			table.remove(shakes, i)
			continue
		end
		local amp = if age < s.fadeIn then age / s.fadeIn elseif age < s.fadeIn + s.hold then 1 else 1 - (age - s.fadeIn - s.hold) / s.fadeOut
		amp = amp * amp * s.mag
		local n = age * s.rough
		local nx, ny, nz = math.noise(n, s.seed, 0.5), math.noise(s.seed, n, 1.5), math.noise(2.5, s.seed, n)
		px += nx * amp * POS_INF
		py += ny * amp * POS_INF
		pz += nz * amp * POS_INF
		rx += nx * amp * ROT_INF
		ry += ny * amp * ROT_INF
		rz += nz * amp * ROT_INF
	end
	return CFrame.new(px, py, pz) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
end

function HatchFx.clearShakes()
	table.clear(shakes)
end

------------------------------------------------------------------ post effects (on the camera: this player only)
type Post = { cc: ColorCorrectionEffect, blur: BlurEffect, dof: DepthOfFieldEffect, bloom: BloomEffect, ownBloom: boolean, saved: { [string]: any } }
local post: Post? = nil

function HatchFx.postBegin(): Post
	if post then
		return post
	end
	local cam = workspace.CurrentCamera
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "HatchCC"
	cc.Parent = cam
	local blur = Instance.new("BlurEffect")
	blur.Name = "HatchBlur"
	blur.Size = 0
	blur.Parent = cam
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "HatchDoF"
	dof.FarIntensity = 0
	dof.NearIntensity = 0
	dof.FocusDistance = 10
	dof.InFocusRadius = 6
	dof.Parent = cam
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local own = false
	local saved = {}
	if bloom then
		saved.Intensity, saved.Size, saved.Threshold = bloom.Intensity, bloom.Size, bloom.Threshold
	else
		bloom = Instance.new("BloomEffect")
		bloom.Name = "HatchBloom"
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 1.6
		bloom.Parent = cam
		own = true
		saved.Intensity, saved.Size, saved.Threshold = 0.4, 24, 1.6
	end
	post = { cc = cc, blur = blur, dof = dof, bloom = bloom :: BloomEffect, ownBloom = own, saved = saved }
	return post :: Post
end

-- tween post settings: { cc = {...}, blur = {...}, dof = {...}, bloom = {...} }, over t seconds
function HatchFx.post(settings: { [string]: { [string]: any } }, t: number?)
	local p = post
	if not p then
		return
	end
	for key, props in settings do
		local o = (p :: any)[key]
		if o then
			if (t or 0) <= 0 then
				for k, v in props do
					o[k] = v
				end
			else
				tween(o, t :: number, props)
			end
		end
	end
end

function HatchFx.postBloomBase(): { [string]: any }
	return if post then post.saved else { Intensity = 0.4, Size = 24, Threshold = 1.6 }
end

function HatchFx.postEnd(t: number?)
	local p = post
	if not p then
		return
	end
	post = nil
	local d = t or 0.35
	tween(p.cc, d, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = WHITE })
	tween(p.blur, d, { Size = 0 })
	tween(p.dof, d, { FarIntensity = 0, NearIntensity = 0 })
	tween(p.bloom, d, { Intensity = p.saved.Intensity, Size = p.saved.Size, Threshold = p.saved.Threshold })
	task.delay(d + 0.05, function()
		p.cc:Destroy()
		p.blur:Destroy()
		p.dof:Destroy()
		if p.ownBloom then
			p.bloom:Destroy()
		end
	end)
end

------------------------------------------------------------------ rings, rays, pillars
local function lib(): Instance?
	return ReplicatedStorage:FindFirstChild("EggModels")
end

-- a shockwave ring lying flat at `at` (a CFrame: its up vector is the ring's axis), growing to `radius`
function HatchFx.ring(at: CFrame, radius: number, color: Color3, seconds: number, thick: number?)
	local src = lib() and (lib() :: Instance):FindFirstChild("FxRing")
	local p: BasePart
	if src and src:IsA("BasePart") then
		p = src:Clone()
	else
		local c = Instance.new("Part")
		c.Shape = Enum.PartType.Cylinder
		p = c
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	local base = if src then (src :: BasePart).Size else Vector3.new(2.14, 0.14, 2.14)
	local isMesh = src ~= nil
	p.Parent = folder
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local a = math.min((os.clock() - t0) / seconds, 1)
			local e = 1 - (1 - a) ^ 3
			local r = 0.3 + radius * e
			local th = (thick or 1) * (1 - 0.6 * a)
			if isMesh then
				p.Size = Vector3.new(base.X * r, base.Y * th * (1 + r * 0.15), base.Z * r)
				p.CFrame = at
			else
				p.Size = Vector3.new(0.2, r * 2, r * 2)
				p.CFrame = at * CFrame.Angles(0, 0, math.pi / 2)
			end
			p.Transparency = a ^ 1.5
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		p:Destroy()
	end)
end

local function holder(at: Vector3): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(at)
	p.Parent = folder
	return p
end

export type Handle = { stop: (fade: number?) -> () }

-- god rays: `count` beams of light shooting out of `centre` (random directions, upper half favoured)
function HatchFx.rays(centre: Vector3, color: Color3 | ColorSequence, count: number, length: number, grow: number?): Handle
	local h = holder(centre)
	local a0 = Instance.new("Attachment")
	a0.Parent = h
	local beams = {}
	local seqColor = if typeof(color) == "ColorSequence" then color else ColorSequence.new(color :: Color3, WHITE)
	for i = 1, count do
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9 - 0.25, math.random() - 0.5)
		dir = if dir.Magnitude > 0.05 then dir.Unit else Vector3.yAxis
		local a1 = Instance.new("Attachment")
		a1.Position = dir * 0.1
		a1.Parent = h
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Texture = T.column
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureSpeed = 1.5
		b.LightEmission = 0.6
		b.LightInfluence = 0
		b.Brightness = 3
		b.FaceCamera = true
		b.Width0 = 0.15
		b.Width1 = 0.9 + math.random() * 0.8
		b.Color = seqColor
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) })
		b.Segments = 4
		b.Parent = h
		table.insert(beams, { a1 = a1, dir = dir, len = length * (0.6 + math.random() * 0.6), beam = b })
	end
	local alive = true
	task.spawn(function()
		local t0 = os.clock()
		while alive do
			local a = math.min((os.clock() - t0) / (grow or 0.5), 1)
			for i, r in beams do
				local wob = 1 + 0.08 * math.sin(os.clock() * 9 + i)
				r.a1.Position = r.dir * r.len * (1 - (1 - a) ^ 3) * wob
			end
			RunService.Heartbeat:Wait()
		end
	end)
	return {
		stop = function(fade: number?)
			alive = false
			for _, r in beams do
				tween(r.beam, fade or 0.2, { Width0 = 0, Width1 = 0 })
			end
			Debris:AddItem(h, (fade or 0.2) + 0.1)
		end,
	}
end

-- a column of light from `base` up into the sky
function HatchFx.pillar(base: Vector3, color: Color3 | ColorSequence, height: number, width: number, seconds: number)
	local h = holder(base)
	local a0 = Instance.new("Attachment")
	a0.Parent = h
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, height, 0)
	a1.Parent = h
	for i, wmul in { 1, 0.45 } do
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Texture = T.column
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureSpeed = if i == 1 then 0.8 else 1.6
		b.LightEmission = if i == 1 then 0.5 else 1
		b.LightInfluence = 0
		b.Brightness = 4
		b.FaceCamera = true
		b.Width0 = 0
		b.Width1 = 0
		b.Color = if typeof(color) == "ColorSequence" then color else ColorSequence.new(color :: Color3, if i == 1 then color :: Color3 else WHITE)
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.4), NumberSequenceKeypoint.new(1, 1) })
		b.Parent = h
		tween(b, 0.25, { Width0 = width * wmul, Width1 = width * wmul * 1.6 }, Enum.EasingStyle.Back)
		task.delay(seconds, function()
			tween(b, 0.6, { Width0 = 0, Width1 = 0 })
		end)
	end
	Debris:AddItem(h, seconds + 0.8)
end

------------------------------------------------------------------ particles
local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.LightEmission = 0.3
	e.LightInfluence = 0
	e.Brightness = 2
	e.SpreadAngle = Vector2.new(180, 180)
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function burstAt(at: Vector3, life: number, size: Vector3?): Part
	local h = holder(at)
	if size then
		h.Size = size
	end
	Debris:AddItem(h, life + 0.2)
	return h
end

local function seq(...: number): NumberSequence
	local p = { ... }
	local kps = {}
	for i = 1, #p, 2 do
		table.insert(kps, NumberSequenceKeypoint.new(p[i], p[i + 1]))
	end
	return NumberSequence.new(kps)
end

function HatchFx.sparks(at: Vector3, color: Color3 | ColorSequence, count: number, speed: number?, scale: number?)
	local s = scale or 1
	local h = burstAt(at, 1)
	local e = emitter(h, {
		Texture = T.spark,
		Color = if typeof(color) == "ColorSequence" then color else ColorSequence.new(WHITE, color :: Color3),
		Size = seq(0, 0.9 * s, 1, 0),
		Lifetime = NumberRange.new(0.3, 0.7),
		Speed = NumberRange.new((speed or 26) * 0.6, speed or 26),
		Drag = 5,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Squash = seq(0, 1.6, 1, 0.4),
	})
	e:Emit(count)
	local g = emitter(h, {
		Texture = T.star,
		Color = if typeof(color) == "ColorSequence" then color else ColorSequence.new(color :: Color3),
		Size = seq(0, 0.2, 0.15, 1.3 * s, 1, 0),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(4, 12),
		Drag = 3,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-180, 180),
	})
	g:Emit(math.ceil(count / 4))
end

local CONFETTI = {
	Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 240, 90),
	Color3.fromRGB(100, 230, 120), Color3.fromRGB(80, 170, 255), Color3.fromRGB(190, 110, 255),
}
function HatchFx.confetti(at: Vector3, count: number, power: number?)
	local h = burstAt(at, 3)
	local per = math.ceil(count / #CONFETTI)
	for _, c in CONFETTI do
		local e = emitter(h, {
			Texture = T.dot,
			Color = ColorSequence.new(c),
			Brightness = 1.4,
			LightEmission = 0,
			Size = seq(0, 0.32, 1, 0.22),
			Squash = seq(0, -0.6, 0.5, 0.6, 1, -0.6),
			Lifetime = NumberRange.new(1.4, 2.4),
			Speed = NumberRange.new(14 * (power or 1), 30 * (power or 1)),
			SpreadAngle = Vector2.new(55, 55),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -34, 0),
			Drag = 1.6,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-400, 400),
		})
		e:Emit(per)
	end
end

function HatchFx.dust(at: Vector3, color: Color3, count: number?)
	local h = burstAt(at, 1)
	local e = emitter(h, {
		Texture = T.glow,
		Color = ColorSequence.new(color:Lerp(WHITE, 0.5)),
		Brightness = 1,
		LightEmission = 0,
		Transparency = seq(0, 0.3, 1, 1),
		Size = seq(0, 0.4, 1, 1.4),
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(2, 6),
		Drag = 4,
	})
	e:Emit(count or 8)
	local bits = emitter(h, {
		Texture = T.dot,
		Color = ColorSequence.new(color),
		Brightness = 1.2,
		LightEmission = 0,
		Size = seq(0, 0.18, 1, 0.1),
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(5, 11),
		Acceleration = Vector3.new(0, -40, 0),
	})
	bits:Emit(math.ceil((count or 8) * 0.8))
end

function HatchFx.coins(at: Vector3, count: number)
	local h = burstAt(at, 2.5)
	local e = emitter(h, {
		Texture = T.coin,
		Color = ColorSequence.new(WHITE),
		Brightness = 1.3,
		LightEmission = 0,
		Size = seq(0, 0.7, 1, 0.55),
		Lifetime = NumberRange.new(1.2, 2),
		Speed = NumberRange.new(16, 30),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -45, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-300, 300),
	})
	e:Emit(count)
end

-- streaks rushing INTO `at` from a sphere around it (before a big burst); returns a handle to stop it
function HatchFx.implode(at: Vector3, color: Color3 | ColorSequence, radius: number, rate: number?): Handle
	local h = holder(at)
	h.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	local e = emitter(h, {
		Texture = T.streak,
		Color = if typeof(color) == "ColorSequence" then color else ColorSequence.new(WHITE, color :: Color3),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = seq(0, 0.1, 0.3, 0.6, 1, 0),
		Squash = seq(0, 2, 1, 2),
		Lifetime = NumberRange.new(0.5, 0.5),
		Speed = NumberRange.new(radius / 0.5, radius / 0.5),
		Rate = rate or 120,
	})
	e.Enabled = true
	return {
		stop = function()
			e.Enabled = false
			Debris:AddItem(h, 0.7)
		end,
	}
end

-- a light that lives for `seconds`
function HatchFx.light(at: Vector3, color: Color3, range: number, brightness: number, seconds: number)
	local h = holder(at)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = h
	tween(l, seconds, { Brightness = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(h, seconds + 0.1)
end

------------------------------------------------------------------ the ladder: how big each rarity's hatch is
export type Tier = {
	take: string, -- break take (tools/blender/egg_break.py): pop / burst / blast
	rings: number,
	shake: number,
	rays: number,
	burst: string?, -- Shared.Effects.burst kind
	pillar: boolean,
	implode: boolean,
	blackhole: boolean,
	rainbow: boolean,
	slow: number, -- seconds of slow motion at the break
	coins: number,
	confetti: number,
	build: number, -- seconds of build-up after the 3rd crack
	fancy: boolean, -- the incubator overloads and launches the egg into the sky
	cook: number, -- incubator cook speed (higher = shorter)
	bloom: number,
}
local LADDER: { [string]: Tier } = {
	Common = { take = "pop", rings = 1, shake = 1.3, rays = 0, pillar = false, implode = false, blackhole = false, rainbow = false, slow = 0, coins = 0, confetti = 36, build = 0.2, fancy = false, cook = 2.6, bloom = 0.6 },
	Uncommon = { take = "pop", rings = 2, shake = 1.7, rays = 5, pillar = false, implode = false, blackhole = false, rainbow = false, slow = 0, coins = 0, confetti = 54, build = 0.3, fancy = false, cook = 2.2, bloom = 0.8 },
	Rare = { take = "burst", rings = 2, shake = 2.6, rays = 8, burst = "rare", pillar = false, implode = false, blackhole = false, rainbow = false, slow = 0, coins = 0, confetti = 70, build = 0.55, fancy = false, cook = 1, bloom = 1.1 },
	Epic = { take = "burst", rings = 3, shake = 3.2, rays = 10, burst = "merge", pillar = false, implode = true, blackhole = false, rainbow = false, slow = 0.2, coins = 12, confetti = 84, build = 0.7, fancy = false, cook = 0.9, bloom = 1.3 },
	Legendary = { take = "blast", rings = 3, shake = 4.6, rays = 12, burst = "legendary", pillar = true, implode = true, blackhole = false, rainbow = false, slow = 0.45, coins = 30, confetti = 110, build = 0.9, fancy = true, cook = 1, bloom = 1.6 },
	Mythic = { take = "blast", rings = 4, shake = 5.2, rays = 14, burst = "legendary", pillar = true, implode = true, blackhole = true, rainbow = false, slow = 0.6, coins = 40, confetti = 130, build = 1.1, fancy = true, cook = 1, bloom = 1.8 },
	Supreme = { take = "blast", rings = 5, shake = 6, rays = 16, burst = "rainbow", pillar = true, implode = true, blackhole = true, rainbow = true, slow = 0.8, coins = 60, confetti = 170, build = 1.3, fancy = true, cook = 1, bloom = 2 },
}
function HatchFx.ladder(rarity: string): Tier
	return LADDER[rarity] or LADDER.Common
end
HatchFx.RAINBOW = Effects.RAINBOW

------------------------------------------------------------------ the break: the Blender sim on the shell chunks
local anims: any = nil
local function breakAnims(): any
	if anims == nil then
		local m = lib() and (lib() :: Instance):FindFirstChild("BreakAnims")
		anims = if m and m:IsA("ModuleScript") then require(m) :: any else false
	end
	return anims
end

-- Plays `take` on hatch `h` (from Shared.EggLook.buildHatch), the egg's bottom middle at `root`. The intact shell,
-- relief and cracks vanish, the chunks take over (pieces ride on theirs). `slow` = seconds of slow motion first.
-- Returns when it's done (chunks fade out at the end).
function HatchFx.breakApart(h: any, take: string, root: CFrame, slow: number?)
	local data = breakAnims()
	h.shell.Transparency = 1
	for _, p in h.relief do
		p.Transparency = 1
	end
	for _, c in h.cracks do
		c.Transparency = 1
	end
	if not data or not data.takes[take] then
		for _, p in h.pieces do
			p.Transparency = 1
		end
		return
	end
	local frames = data.takes[take]
	local fps, n = data.fps, data.frames
	local s = h.scale
	for _, c in h.chunks do
		c.Transparency = 0
	end
	local SLOW_RATE = 0.28
	local t0 = os.clock()
	local dur = (n - 1) / fps
	while true do
		local real = os.clock() - t0
		local sl = slow or 0
		local simT = if real < sl then real * SLOW_RATE else sl * SLOW_RATE + (real - sl)
		local f = math.min(simT * fps, n - 1.001)
		local i = math.floor(f)
		local a = f - i
		local fade = math.clamp((simT - (dur - 0.55)) / 0.55, 0, 1)
		for _, c in h.chunks do
			local d = frames[c.Name]
			if d then
				local k0, k1 = i * 7, (i + 1) * 7
				local c0 = CFrame.new(d[k0 + 1] * s, d[k0 + 2] * s, d[k0 + 3] * s, d[k0 + 4], d[k0 + 5], d[k0 + 6], d[k0 + 7])
				local c1 = CFrame.new(d[k1 + 1] * s, d[k1 + 2] * s, d[k1 + 3] * s, d[k1 + 4], d[k1 + 5], d[k1 + 6], d[k1 + 7])
				c.CFrame = root * c0:Lerp(c1, a)
				c.Transparency = fade
			end
		end
		for p, st in h.stuck do
			local o = st.offset
			p.CFrame = st.chunk.CFrame * CFrame.new(o.Position * s) * o.Rotation
			p.Transparency = fade
		end
		if simT >= dur then
			break
		end
		RunService.Heartbeat:Wait()
	end
	for _, c in h.chunks do
		c.Transparency = 1
	end
	for _, p in h.pieces do
		p.Transparency = 1
	end
end

return HatchFx
