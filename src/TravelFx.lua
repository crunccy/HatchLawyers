--!strict
-- Shared.TravelFx (client only) - the trip animations of zone travel (StarterPlayerScripts.Travel). 2026-10-13, mr.robe:
-- "make animations for each one that progressively get better and better, just like the ones that you made for opening
-- the eggs ... start slow because you don't want them to be too cool at the beginning". References: a white tiered
-- stage under a glowing halo, an iridescent vortex tunnel, a teleporter pad with an emitter ring above it.
-- The ladder, by the destination's place in the lane (HOME = step 1, in green):
--   1 Briefcase Bay     a glowing ring under your feet, a column of light, you fade out upwards in sparkles, a flash
--   2 Pet Park          + rings rise round you, a ring burst where you land
--   3 Brainrot Blvd     + you float up, an emitter halo appears over you and beams you up; the camera pushes in
--   4 Food Court        + particles pull in, a shockwave, and a short flight through a glowing vortex tunnel
--   5 Ocean Shore       + a tiered platform rises under you, the camera circles, a longer tunnel with your avatar
--                         flying ahead of the camera, god rays where you land
--   6 Space Base        + the world drains of colour, the rings orbit faster and faster, a hyperspace launch into a long
--                         tunnel full of star streaks, a white warp exit, a huge landing with confetti and the sting
-- TravelFx.trip({ index, color, go }) plays a whole trip and calls go() - the server's Remotes.Travel, which checks and
-- moves you - at the moment you vanish; returns what go() returned. Everything here is this player's own view; the
-- server pops Effects bursts at both ends for everyone else. The tunnel is built far above the map (y = 4000).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Shared = script.Parent
local HatchFx = require(Shared:WaitForChild("HatchFx") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any

local player = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local MINT = Color3.fromRGB(110, 255, 200)
local CYAN = Color3.fromRGB(90, 230, 255)
local VIOLET = Color3.fromRGB(170, 110, 255)
local TUNNEL_AT = CFrame.new(0, 4000, 0)

local TravelFx = {}

export type Tier = {
	charge: number, -- seconds of build-up before you vanish
	rings: number, -- rings rising round you
	orbit: boolean, -- the rings orbit you (tilted) instead of just rising
	float: number, -- studs you float up
	halo: boolean, -- an emitter halo over you beaming you up
	platform: boolean, -- a tiered platform rises under you
	implode: boolean, -- particles pull in
	tunnel: number, -- seconds in the vortex tunnel (0 = a flash cut)
	chase: boolean, -- your avatar flies ahead of the camera in the tunnel
	stars: boolean, -- star streaks in the tunnel
	drain: boolean, -- the world drains of colour before the jump
	camera: string?, -- nil = your normal camera; "push" = pushes in; "orbit" = circles you
	shake: number,
	land: number, -- 1..3: how big the landing is
	sting: number, -- HatchCue "burst" value on landing (0 = none; Sounds: < 3 a win jingle, >= 3 the big sting)
}

local LADDER: { Tier } = {
	{ charge = 0.75, rings = 0, orbit = false, float = 0, halo = false, platform = false, implode = false, tunnel = 0, chase = false, stars = false, drain = false, camera = nil, shake = 0, land = 1, sting = 0 },
	{ charge = 1.05, rings = 2, orbit = false, float = 0, halo = false, platform = false, implode = false, tunnel = 0, chase = false, stars = false, drain = false, camera = nil, shake = 0, land = 1, sting = 0 },
	{ charge = 1.45, rings = 3, orbit = false, float = 2.5, halo = true, platform = false, implode = false, tunnel = 0, chase = false, stars = false, drain = false, camera = "push", shake = 0.8, land = 2, sting = 0 },
	{ charge = 1.6, rings = 3, orbit = false, float = 3, halo = true, platform = false, implode = true, tunnel = 1.3, chase = false, stars = false, drain = false, camera = "push", shake = 1.6, land = 2, sting = 2 },
	{ charge = 1.9, rings = 4, orbit = true, float = 3.5, halo = true, platform = true, implode = true, tunnel = 1.9, chase = true, stars = false, drain = false, camera = "orbit", shake = 2.6, land = 3, sting = 2 },
	{ charge = 2.4, rings = 6, orbit = true, float = 4.5, halo = true, platform = true, implode = true, tunnel = 2.7, chase = true, stars = true, drain = true, camera = "orbit", shake = 4, land = 3, sting = 5 },
}

function TravelFx.tier(index: number): Tier
	return LADDER[math.clamp(math.floor(index), 1, #LADDER)]
end

------------------------------------------------------------------ helpers
local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function cue(kind: string, value: number)
	local e = ReplicatedStorage:FindFirstChild("HatchCue")
	if e and e:IsA("BindableEvent") then
		e:Fire(kind, value)
	end
end

local fxFolder: Folder? = nil
local function folder(): Folder
	if not fxFolder or not fxFolder.Parent then
		local f = Instance.new("Folder")
		f.Name = "TravelFxLocal"
		f.Parent = workspace
		fxFolder = f
	end
	return fxFolder :: Folder
end

local function part(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder()
	return p
end

-- a flat torus (EggModels.FxRing, the Blender ring the hatch uses) of radius r round `cf`'s up axis
local ringSrc: BasePart? = nil
local function torus(cf: CFrame, r: number, thick: number, color: Color3, material: Enum.Material?): BasePart
	if ringSrc == nil then
		local lib = ReplicatedStorage:FindFirstChild("EggModels")
		local s = lib and lib:FindFirstChild("FxRing")
		ringSrc = if s and s:IsA("BasePart") then s else nil
	end
	local p: BasePart
	if ringSrc then
		p = (ringSrc :: BasePart):Clone()
		local base = (ringSrc :: BasePart).Size
		p.Size = Vector3.new(base.X * r, base.Y * thick, base.Z * r)
		p.CFrame = cf
	else -- (a flat disc if the ring mesh is missing)
		p = part(Vector3.new(0.2 * thick, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.pi / 2), color, nil, Enum.PartType.Cylinder)
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	p.Parent = folder()
	return p
end

-- this player's character, ready to animate
type Rig = { character: Model, root: BasePart, humanoid: Humanoid, parts: { Instance } }
local function rig(): Rig?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local parts = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(parts, d)
		end
	end
	return { character = character, root = root, humanoid = humanoid, parts = parts }
end
local function fade(r: Rig, v: number)
	for _, d in r.parts do
		if d.Parent then
			(d :: any).LocalTransparencyModifier = v
		end
	end
end
local function feet(r: Rig): Vector3
	return r.root.Position - Vector3.new(0, r.root.Size.Y / 2 + r.humanoid.HipHeight, 0)
end

-- your controls off for the trip: the PlayerModule's if there is one (never waited for - this place has none, a
-- WaitForChild hung the first trip), else walk speed + jump to 0 and back
local frozen: { humanoid: Humanoid, speed: number, jump: number, jumpHeight: number }? = nil
local function controls(on: boolean, humanoid: Humanoid?)
	local scripts = player:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if module and module:IsA("ModuleScript") then
		pcall(function()
			local c = (require(module) :: any):GetControls()
			if on then
				c:Enable()
			else
				c:Disable()
			end
		end)
	end
	if not on and humanoid and not frozen then
		frozen = { humanoid = humanoid, speed = humanoid.WalkSpeed, jump = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight }
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	elseif on and frozen then
		local f = frozen :: any
		if f.humanoid.Parent then
			f.humanoid.WalkSpeed, f.humanoid.JumpPower, f.humanoid.JumpHeight = f.speed, f.jump, f.jumpHeight
		end
		frozen = nil
	end
end

-- a full-screen flash (one per trip)
local flashGui: ScreenGui? = nil
local function flashFrame(): Frame
	if not flashGui or not flashGui.Parent then
		local g = Instance.new("ScreenGui")
		g.Name = "TravelFlash"
		g.IgnoreGuiInset = true
		g.ResetOnSpawn = false
		g.DisplayOrder = 70
		g.Parent = player:WaitForChild("PlayerGui")
		local f = Instance.new("Frame")
		f.Name = "Flash"
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = WHITE
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.Parent = g
		flashGui = g
	end
	return (flashGui :: ScreenGui):FindFirstChild("Flash") :: Frame
end
local function flashTo(color: Color3, transparency: number, t: number): Tween
	local f = flashFrame()
	f.BackgroundColor3 = color
	return tween(f, t, { BackgroundTransparency = transparency })
end

------------------------------------------------------------------ pieces
-- a ring that rises from your feet past your head, spinning a little (or, orbit = tilted, circling you)
local function risingRing(base: Vector3, r: number, color: Color3, rise: number, seconds: number, orbit: boolean, k: number)
	local p = torus(CFrame.new(base), r, 1.6, color)
	p.Transparency = 1
	task.spawn(function()
		local t0 = os.clock()
		local tilt = (k % 2 == 0 and 1 or -1) * math.rad(18 + k * 4)
		while p.Parent do
			local a = math.min((os.clock() - t0) / seconds, 1)
			local e = 1 - (1 - a) ^ 2
			local cf = CFrame.new(base + Vector3.new(0, rise * e, 0))
			if orbit then
				cf *= CFrame.Angles(0, (os.clock() - t0) * (3 + k), 0) * CFrame.Angles(tilt, 0, 0)
			else
				cf *= CFrame.Angles(math.sin(os.clock() * 3 + k) * 0.12, 0, math.cos(os.clock() * 3 + k) * 0.12)
			end
			p.CFrame = cf
			p.Transparency = if a < 0.15 then 1 - a / 0.15 * 0.85 else 0.15 + 0.85 * math.max(0, (a - 0.7) / 0.3)
			if a >= 1 and not orbit then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if p.Parent then
			p:Destroy()
		end
	end)
	return p
end

-- an emitter halo over you (concentric glowing rings + a shimmering disc), like the travel portal's
local function halo(at: Vector3, color: Color3): { BasePart }
	local list: { BasePart } = {}
	local cf = CFrame.new(at)
	local disc = part(Vector3.new(0.2, 7, 7), cf * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.ForceField, Enum.PartType.Cylinder)
	table.insert(list, disc)
	table.insert(list, torus(cf, 3.6, 2.2, WHITE))
	table.insert(list, torus(cf, 2.4, 1.4, color))
	table.insert(list, part(Vector3.new(0.25, 1.6, 1.6), cf * CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), WHITE, nil, Enum.PartType.Cylinder))
	for _, p in list do
		local s = p.Size
		p.Size = s * 0.1
		tween(p, 0.35, { Size = s }, Enum.EasingStyle.Back)
	end
	return list
end

-- a tiered round platform rising under you (white steps with glowing rims)
local function platform(at: Vector3, color: Color3): { BasePart }
	local list: { BasePart } = {}
	for i, d in { 11, 8, 5 } do
		local y = (i - 1) * 0.45
		local step = part(Vector3.new(0.45, d, d), CFrame.new(at + Vector3.new(0, y - 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(236, 240, 250), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		local rim = part(Vector3.new(0.18, d + 0.35, d + 0.35), CFrame.new(at + Vector3.new(0, y - 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), if i % 2 == 1 then CYAN else color, nil, Enum.PartType.Cylinder)
		for _, p in { step, rim } do
			local goal = p.CFrame
			p.CFrame = goal * CFrame.new(-2.5, 0, 0) -- (from below: the cylinder's X is up)
			p.Transparency = 1
			task.delay(i * 0.08, function()
				tween(p, 0.4, { CFrame = goal, Transparency = 0 }, Enum.EasingStyle.Back)
			end)
			table.insert(list, p)
		end
	end
	return list
end

local function clear(list: { BasePart }, t: number)
	for _, p in list do
		if p.Parent then
			tween(p, t, { Transparency = 1, Size = p.Size * 0.6 })
			task.delay(t + 0.05, function()
				p:Destroy()
			end)
		end
	end
end

------------------------------------------------------------------ the vortex tunnel (ref 2: glowing iridescent rings)
-- (each ring wobbles about the tunnel's axis - spinning a round ring about its own axis wouldn't show)
type Tunnel = { model: Folder, length: number, spin: { { p: BasePart, centre: CFrame, ax: number, az: number, rate: number } }, glow: BasePart }
local function buildTunnel(tier: Tier, color: Color3): Tunnel
	local f = Instance.new("Folder")
	f.Name = "Tunnel"
	f.Parent = folder()
	local length = 70 + tier.tunnel * 110
	local n = math.floor(length / 7)
	local h, s, _ = color:ToHSV()
	local spin = {}
	for i = 0, n do
		local z = -i * 7
		local wob = Vector3.new(math.sin(i * 0.45) * 2.2, math.cos(i * 0.37) * 1.8, 0)
		-- iridescent: the zone's colour drifting towards mint / cyan / violet, every third ring brighter
		local mixes = { MINT, CYAN, VIOLET, color }
		-- (saturated: near-white rings + bloom blew the first playtest out to white)
		local c = Color3.fromHSV((h + i * 0.03) % 1, math.max(0.55, s), 0.95):Lerp(mixes[i % #mixes + 1], 0.5)
		if i % 4 == 0 then
			c = c:Lerp(WHITE, 0.25)
		end
		local centre = TUNNEL_AT * CFrame.new(wob.X, wob.Y, z) * CFrame.Angles(math.pi / 2, 0, 0)
		local ax, az = 0.15 + (i % 4) * 0.05, 0.12 + ((i + 2) % 4) * 0.05
		local base = centre * CFrame.Angles(ax, 0, az)
		local r = 8.5 + math.sin(i * 0.8) * 1.2
		local ring = torus(base, r, 2.2, c)
		ring.Transparency = 0.3
		ring.Parent = f
		local shell = torus(base, r + 1.3, 3.4, c:Lerp(MINT, 0.3), Enum.Material.ForceField)
		shell.Parent = f
		table.insert(spin, { p = ring, centre = centre, ax = ax, az = az, rate = (if i % 2 == 0 then 1 else -1) * (1.2 + (i % 3) * 0.5) })
		table.insert(spin, { p = shell, centre = centre, ax = -az, az = ax, rate = (if i % 2 == 0 then -1 else 1) * 0.9 })
	end
	if tier.stars then -- star streaks along the walls: the flight's speed turns them into lines
		for _ = 1, 140 do
			local a = math.random() * math.pi * 2
			local rr = 4.5 + math.random() * 3.5 -- (clear of the camera's path: close ones read as huge white bars)
			local z = -math.random() * length
			local sp = part(Vector3.new(0.14, 0.14, 4 + math.random() * 6), TUNNEL_AT * CFrame.new(math.cos(a) * rr, math.sin(a) * rr, z), Color3.fromRGB(220, 235, 255))
			sp.Parent = f
		end
	end
	local glow = part(Vector3.new(30, 30, 30), TUNNEL_AT * CFrame.new(0, 0, -length - 22), color:Lerp(WHITE, 0.6), nil, Enum.PartType.Ball)
	glow.Parent = f
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 60
	light.Brightness = 3
	light.Parent = glow
	return { model = f, length = length, spin = spin, glow = glow }
end

-- the sky while you're in the tunnel: a dark void tinted with the zone's colour (saved + restored)
local saved: { [string]: any }? = nil
local function setSky(color: Color3?)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if color then
		if not saved then
			saved = {
				ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
				atm = if atm then { Density = atm.Density, Color = atm.Color, Decay = atm.Decay, Haze = atm.Haze, Glare = atm.Glare } else nil,
			}
		end
		Lighting.ClockTime = 0
		Lighting.Brightness = 1
		Lighting.Ambient = color:Lerp(Color3.new(0, 0, 0), 0.5)
		Lighting.OutdoorAmbient = color:Lerp(Color3.new(0, 0, 0), 0.4)
		if atm then
			atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = 0.5, color:Lerp(Color3.new(0, 0, 0), 0.55), color:Lerp(Color3.new(0, 0, 0), 0.8), 2, 0
		end
	elseif saved then
		local s = saved :: any
		Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = s.ClockTime, s.Brightness, s.Ambient, s.OutdoorAmbient
		if atm and s.atm then
			atm.Density, atm.Color, atm.Decay, atm.Haze, atm.Glare = s.atm.Density, s.atm.Color, s.atm.Decay, s.atm.Haze, s.atm.Glare
		end
		saved = nil
	end
end

-- a stand-in of your avatar to fly through the tunnel (anchored, lying flat, a trail behind it)
local function flyer(r: Rig, color: Color3): Model?
	local was = r.character.Archivable
	r.character.Archivable = true
	local ok, copy = pcall(function()
		return r.character:Clone()
	end)
	r.character.Archivable = was
	if not ok or not copy then
		return nil
	end
	local m = copy :: Model
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ForceField") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.LocalTransparencyModifier = 0
		end
	end
	local root = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1.2, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.2, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(color:Lerp(WHITE, 0.5), color)
		trail.Transparency = NumberSequence.new(0.1, 1)
		trail.Lifetime = 0.35
		trail.LightEmission = 0.6
		trail.FaceCamera = true
		trail.Parent = root
	end
	m.Parent = folder()
	return m
end

------------------------------------------------------------------ the trip
-- opts: index (1..6, the destination's place in the lane), color (the zone's colour), go (calls the server: ok, reason)
function TravelFx.trip(opts: { index: number, color: Color3, go: () -> (boolean, string?) }): (boolean, string?)
	local tier = TravelFx.tier(opts.index)
	local color = opts.color
	local r = rig()
	if not r then
		return opts.go()
	end
	local rr = r :: Rig
	local cam = workspace.CurrentCamera
	local savedCam = { type = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView }
	local camConn: RBXScriptConnection? = nil
	local camGoal: CFrame = cam.CFrame
	local camCur: CFrame = cam.CFrame
	local camRate = 5
	local pieces: { BasePart } = {}
	local stops: { () -> () } = {}
	local tunnel: Tunnel? = nil
	local flyerModel: Model? = nil
	local postOn = false

	local function takeCamera()
		if camConn then
			return
		end
		cam.CameraType = Enum.CameraType.Scriptable
		camCur, camGoal = cam.CFrame, cam.CFrame
		camConn = RunService.RenderStepped:Connect(function(dt)
			camCur = camCur:Lerp(camGoal, 1 - math.exp(-dt * camRate))
			cam.CFrame = camCur * HatchFx.shakeCFrame()
		end)
	end
	local function giveCameraBack()
		if camConn then
			camConn:Disconnect()
			camConn = nil
		end
		HatchFx.clearShakes()
		cam.CameraType = savedCam.type
		if savedCam.subject and savedCam.subject.Parent then
			cam.CameraSubject = savedCam.subject
		else
			cam.CameraSubject = rr.humanoid
		end
		cam.FieldOfView = savedCam.fov
	end
	local function cleanup()
		for _, s in stops do
			pcall(s)
		end
		table.clear(stops)
		clear(pieces, 0.25)
		if tunnel then
			(tunnel :: Tunnel).model:Destroy()
			tunnel = nil
		end
		if flyerModel then
			(flyerModel :: Model):Destroy()
			flyerModel = nil
		end
		setSky(nil)
		if postOn then
			HatchFx.postEnd(0.4)
			postOn = false
		end
		rr.root.Anchored = false
		giveCameraBack()
		controls(true)
		player:SetAttribute("Traveling", nil)
	end

	controls(false, rr.humanoid)
	player:SetAttribute("Traveling", true) -- (local only: Bosses.client skips its ragdoll while you travel)
	rr.root.Anchored = true -- (locally: you stay put while it charges; unanchored before the server moves you)
	local home = rr.root.CFrame
	local base = feet(rr)
	local centre = rr.root.Position

	------------------------------------------------ 1) charge
	local ok, result, reason = pcall(function()
		-- the glowing ring under your feet + a column of light
		local floorRing = torus(CFrame.new(base + Vector3.new(0, 0.15, 0)), 0.4, 1.4, color)
		tween(floorRing, 0.3, { Size = floorRing.Size * 7 }, Enum.EasingStyle.Back)
		table.insert(pieces, floorRing)
		HatchFx.pillar(base, color, 14 + opts.index * 5, 1.6 + opts.index * 0.25, tier.charge + 0.35) -- (thin: it's bright)
		if tier.platform then
			for _, p in platform(base, color) do
				table.insert(pieces, p)
			end
		end
		local haloAt = base + Vector3.new(0, 9 + tier.float, 0)
		if tier.halo then
			task.delay(0.15, function()
				for _, p in halo(haloAt, color) do
					table.insert(pieces, p)
				end
				HatchFx.pillar(base, CYAN, 9 + tier.float, 1.3, tier.charge)
			end)
		end
		if tier.implode then
			local imp = HatchFx.implode(centre, color, 9 + opts.index, 40 + opts.index * 10)
			table.insert(stops, function()
				imp.stop(0.2)
			end)
		end
		if tier.drain then
			HatchFx.postBegin()
			postOn = true
			HatchFx.post({ cc = { Saturation = -0.85, Contrast = 0.15, TintColor = Color3.fromRGB(215, 225, 255) }, bloom = { Intensity = 1.2, Threshold = 1.1 } }, tier.charge * 0.6)
		end
		-- the camera
		if tier.camera then
			takeCamera()
			camRate = if tier.camera == "orbit" then 3 else 4
			local look = rr.root.CFrame.LookVector
			local start = os.clock()
			local camLoop = RunService.Heartbeat:Connect(function()
				local t = os.clock() - start
				local at = rr.root.Position
				if tier.camera == "orbit" then
					local a = math.atan2(-look.X, -look.Z) + t * (0.9 + opts.index * 0.15)
					local dist = 14 - t * 1.5
					camGoal = CFrame.lookAt(at + Vector3.new(math.sin(a) * dist, 3 + t * 1.2, math.cos(a) * dist), at + Vector3.new(0, 1.5, 0))
				else
					camGoal = CFrame.lookAt(at + look * (11 - t * 2) + Vector3.new(0, 2.5 + t, 0), at + Vector3.new(0, 1.5, 0))
				end
			end)
			table.insert(stops, function()
				camLoop:Disconnect()
			end)
			if tier.shake > 0 then
				HatchFx.shake(tier.shake * 0.5, 10, tier.charge * 0.8, 0.3, 0.1)
			end
		end
		-- rings, sparkles, pings - spread over the charge; you float up
		local steps = math.max(tier.rings, 2)
		for k = 1, steps do
			task.delay(tier.charge * (k - 1) / steps, function()
				cue("beat", math.min(k + opts.index - 1, 8))
				HatchFx.sparks(rr.root.Position, color, 8 + opts.index * 3, 14, 0.8)
				if k <= tier.rings then
					local ring = risingRing(base, 2.6 + (k % 2) * 0.6, if k % 2 == 0 then color else WHITE, 5.5 + tier.float, if tier.orbit then 99 else 0.9, tier.orbit, k)
					table.insert(pieces, ring)
				end
			end)
		end
		if tier.float > 0 then
			local t0 = os.clock()
			while os.clock() - t0 < tier.charge do
				local a = (os.clock() - t0) / tier.charge
				rr.root.CFrame = home * CFrame.new(0, tier.float * (1 - (1 - a) ^ 2) + math.sin(os.clock() * 6) * 0.08, 0) * CFrame.Angles(0, a * a * math.pi * 2 * (opts.index - 2), 0)
				RunService.Heartbeat:Wait()
			end
		else
			task.wait(tier.charge)
		end

		------------------------------------------------ 2) vanish
		HatchFx.sparks(rr.root.Position, color, 30 + opts.index * 8, 26)
		if opts.index >= 4 then
			HatchFx.ring(CFrame.new(base + Vector3.new(0, 0.3, 0)), 10 + opts.index * 2, color, 0.5, 1.6)
			HatchFx.shake(tier.shake, 14, 0.02, 0.4)
		end
		local t0 = os.clock()
		while os.clock() - t0 < 0.22 do -- you stretch up into the light
			local a = (os.clock() - t0) / 0.22
			fade(rr, a)
			RunService.Heartbeat:Wait()
		end
		fade(rr, 1)
		for _, s in stops do
			pcall(s)
		end
		table.clear(stops)
		if tier.tunnel > 0 then
			tunnel = buildTunnel(tier, color)
		end
		flashTo(color:Lerp(WHITE, 0.75), 0, 0.14).Completed:Wait()
		clear(pieces, 0.1)
		table.clear(pieces)
		rr.root.CFrame = home
		rr.root.Anchored = false

		------------------------------------------------ 3) the jump: the server checks + moves you (in the tunnel, or under the flash)
		local answer: { any }? = nil
		task.spawn(function()
			answer = { opts.go() }
		end)
		if tunnel then
			local tn = tunnel :: Tunnel
			takeCamera()
			camRate = 30
			setSky(color)
			if not postOn then
				HatchFx.postBegin()
				postOn = true
			end
			HatchFx.post({ cc = { Saturation = 0.35, Contrast = 0.12, TintColor = WHITE }, bloom = { Intensity = 0.7, Threshold = 1.4 }, blur = { Size = 0 } }, 0.2)
			if tier.chase then
				flyerModel = flyer(rr, color)
			end
			local L = tn.length
			local function camAt(s: number, roll: number): CFrame
				local wob = Vector3.new(math.sin(-s / 7 * 0.45) * 1.2, math.cos(-s / 7 * 0.37) * 0.9, 0)
				return TUNNEL_AT * CFrame.new(wob.X, wob.Y, 14 - s) * CFrame.Angles(0, 0, roll)
			end
			camCur = camAt(0, 0)
			camGoal = camCur
			cam.CFrame = camCur
			flashTo(color:Lerp(WHITE, 0.75), 1, 0.25)
			local start = os.clock()
			local dur = tier.tunnel
			local done = false
			while not done do
				local t = os.clock() - start
				local u = math.min(t / dur, 1)
				local e = u * u * (3 - 2 * u)
				local s = e * L
				local roll = t * (0.8 + opts.index * 0.25)
				camGoal = camAt(s, roll)
				cam.FieldOfView = savedCam.fov + 30 * math.sin(math.min(u, 0.9) / 0.9 * math.pi * 0.5)
				for _, sp in tn.spin do
					local w = t * sp.rate
					sp.p.CFrame = sp.centre * CFrame.Angles(sp.ax * math.cos(w), 0, sp.az * math.sin(w))
				end
				if flyerModel then
					local ahead = camAt(s + 10, 0) * CFrame.new(0, -1.2, 0)
					;(flyerModel :: Model):PivotTo(ahead * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, t * 4, 0))
				end
				if u >= 1 then
					-- hold at the end glow until the server has answered (it streams the destination in first)
					if answer or t > dur + 4 then
						done = true
					end
				end
				RunService.RenderStepped:Wait()
			end
			cue("beat", 8)
			flashTo(WHITE, 0, 0.16).Completed:Wait()
			setSky(nil)
			tn.model:Destroy()
			tunnel = nil
			if flyerModel then
				(flyerModel :: Model):Destroy()
				flyerModel = nil
			end
			cam.FieldOfView = savedCam.fov
		else
			local t1 = os.clock()
			while not answer and os.clock() - t1 < 5 do
				RunService.Heartbeat:Wait()
			end
		end
		local got = answer or { false, "timeout" }
		return got[1], got[2]
	end)

	if not ok then
		warn("[TravelFx] " .. tostring(result))
		flashTo(WHITE, 1, 0.3)
		fade(rr, 0)
		cleanup()
		return false, "error"
	end
	local moved = result == true

	------------------------------------------------ 4) land (or, if the server said no, come back where you were)
	local landOk = pcall(function()
		local r2 = rig() or rr
		local at = feet(r2)
		if tier.camera then
			takeCamera()
			camRate = 6
			local look = r2.root.CFrame.LookVector
			-- start high in front, swoop down behind you
			camCur = CFrame.lookAt(r2.root.Position + look * 10 + Vector3.new(0, 7 + opts.index, 0), r2.root.Position)
			cam.CFrame = camCur
			camGoal = CFrame.lookAt(r2.root.Position - look * 11 + Vector3.new(0, 4, 0), r2.root.Position + Vector3.new(0, 1.5, 0))
		end
		flashTo(if moved then color:Lerp(WHITE, 0.6) else Color3.fromRGB(150, 150, 165), 1, if moved then 0.35 else 0.25)
		if moved then
			HatchFx.pillar(at, color, 16 + opts.index * 6, 1.8 + opts.index * 0.3, 0.5 + tier.land * 0.25)
			HatchFx.ring(CFrame.new(at + Vector3.new(0, 0.3, 0)), 5 + tier.land * 4, color, 0.6, 1.2 + tier.land * 0.3)
			if tier.land >= 2 then
				task.delay(0.12, HatchFx.ring, CFrame.new(at + Vector3.new(0, 0.3, 0)), 8 + tier.land * 5, WHITE, 0.7, 1)
			end
			HatchFx.sparks(r2.root.Position, color, 20 + opts.index * 10, 24)
			if tier.land >= 3 then
				local rays = HatchFx.rays(at + Vector3.new(0, 1.5, 0), color, 10 + opts.index * 2, 10 + opts.index * 2, 0.3)
				task.delay(0.9, rays.stop, 0.4)
				Effects.burst(at, "tier", color)
			end
			if opts.index >= 6 then
				HatchFx.confetti(at + Vector3.new(0, 2, 0), 90, 1.2)
				HatchFx.shake(3, 12, 0.02, 0.6)
			end
			if tier.sting > 0 then
				cue("burst", tier.sting)
			end
		else
			HatchFx.dust(at, Color3.fromRGB(180, 180, 195), 18)
		end
		local t0 = os.clock()
		while os.clock() - t0 < 0.35 do
			fade(r2, 1 - (os.clock() - t0) / 0.35)
			RunService.Heartbeat:Wait()
		end
		fade(r2, 0)
		if camConn then
			task.wait(if tier.camera then 0.9 else 0.5)
		end
	end)
	if not landOk then
		fade(rr, 0)
	end
	cleanup()
	return moved, if moved then nil else (reason :: any)
end

return TravelFx
