--!strict
-- Ambience (StarterPlayerScripts.Ambience, 2026-10-20, crnuch's world-ambience overhaul): the ONE controller for the
-- boss zones' atmosphere - lighting, fog, colour grading and the floating ambient particles. Client only: lighting
-- is per client, so it is never set for everyone from the server; nothing here replicates or is saved.
--   * WHERE: every 0.25 s it finds the zone the player is in - the lane (Config.Zones.List[n].Bounds) or a redesign
--     island (Workspace.IslandWiring.<Id> BoundsMin / BoundsMax) - by zone id, so both maps get the same look.
--   * LOOK: cross-fades Lighting + Atmosphere + its own ColorCorrection / SunRays + the place's Bloom to that zone's
--     preset (Shared.AmbiencePresets); outside every zone it fades back to the place's own lighting (captured at start).
--     It only writes while fading, so it never fights another script in between.
--   * HANDS OFF while TravelFx flies you (player attribute Traveling) or a hatch owns the camera (HatchCC on the
--     camera, or the Mythic / Supreme stage at y 3000): those save + restore the lighting themselves; afterwards this
--     fades from whatever they left back to the zone's look.
--   * PARTICLES: "air" layers in a box that follows the player; the rest on anchors found in the zone's own geometry
--     (trees, water, rocks, landmarks - by name, clustered), only the nearest few within range emit. Emitters carry
--     NoLod (EffectsLod leaves them to this script). Rates dip while the zone's boss winds up / attacks.
--   * QUALITY: High / Low (Low on touch-only devices and graphics level 1-4): fewer anchors, lower rates, smaller
--     air box, no glows / sun rays. Boss warnings, eggs and players are never touched by either.
--   * TEST HOOKS (player attributes): AmbienceOff = true (fade to the place's own look, no particles - for before /
--     after shots), AmbienceQuality = "High" | "Low", AmbienceZone = "<Id>" (force a zone). It sets AmbienceZoneNow.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Presets = require(Shared:WaitForChild("AmbiencePresets") :: ModuleScript) :: any
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local Sfx = require(Shared:WaitForChild("Sfx") :: ModuleScript) :: any

local player = Players.LocalPlayer

local root = Instance.new("Folder")
root.Name = "AmbienceFx"
root.Parent = workspace

------------------------------------------------------------------ the look: what can fade, and the place's own values
local GROUP_KEYS: { [string]: { string } } = {
	Lighting = { "Ambient", "OutdoorAmbient", "Brightness", "ColorShift_Top", "ColorShift_Bottom", "EnvironmentDiffuseScale",
		"EnvironmentSpecularScale", "ExposureCompensation", "ClockTime" },
	Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
	Grade = { "Brightness", "Contrast", "Saturation", "TintColor" },
	Bloom = { "Intensity", "Size", "Threshold" },
	SunRays = { "Intensity", "Spread" },
}

local function own(class: string, name: string, props: { [string]: any }): Instance
	local found = Lighting:FindFirstChild(name)
	if found and found.ClassName == class then
		return found
	end
	local o = Instance.new(class)
	o.Name = name
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = Lighting
	return o
end

-- the place's own effects are used where it has them (only one Atmosphere / Bloom ever counts); ours otherwise
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	or own("Atmosphere", "AmbienceAtmosphere", { Density = 0, Offset = 0, Haze = 0, Glare = 0 }) :: Atmosphere
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	or own("BloomEffect", "AmbienceBloom", { Intensity = 0, Size = 24, Threshold = 2 }) :: BloomEffect
local grade = own("ColorCorrectionEffect", "AmbienceGrade", {}) :: ColorCorrectionEffect
local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	or own("SunRaysEffect", "AmbienceRays", { Intensity = 0, Spread = 0.5 }) :: SunRaysEffect

local TARGETS: { [string]: Instance } = { Lighting = Lighting, Atmosphere = atmosphere, Grade = grade, Bloom = bloom, SunRays = rays }

type Look = { [string]: { [string]: any } }

local function readLook(): Look
	local look: Look = {}
	for group, keys in GROUP_KEYS do
		local t = {}
		local o = TARGETS[group] :: any
		for _, k in keys do
			t[k] = o[k]
		end
		look[group] = t
	end
	return look
end

local BASE: Look = readLook() -- the place's own look (the hub and everything outside the zones)

local quality: string = "High"
local function lookFor(id: string?): Look
	local preset = id and Presets.Zones[id]
	local look: Look = {}
	for group, keys in GROUP_KEYS do
		local t = {}
		local over = preset and preset[group]
		for _, k in keys do
			local v = over and over[k]
			t[k] = if v ~= nil then v else BASE[group][k]
		end
		look[group] = t
	end
	if not Presets.QUALITY[quality].SunRays then
		look.SunRays.Intensity = BASE.SunRays.Intensity
	end
	return look
end

local function lerp(a: any, b: any, t: number): any
	local ta = typeof(a)
	if ta == "number" then
		return a + (b - a) * t
	elseif ta == "Color3" then
		return (a :: Color3):Lerp(b, t)
	end
	return if t < 0.5 then a else b
end

local function writeLook(from: Look, to: Look, t: number)
	for group, keys in GROUP_KEYS do
		local o = TARGETS[group] :: any
		local a, b = from[group], to[group]
		for _, k in keys do
			local va, vb = a[k], b[k]
			if va ~= vb then
				local v
				if k == "ClockTime" then
					-- the short way round the clock (14 -> 0 goes through the evening, not the morning)
					local d = ((vb - va + 12) % 24) - 12
					v = (va + d * t) % 24
				else
					v = lerp(va, vb, t)
				end
				pcall(function()
					o[k] = v
				end)
			end
		end
	end
end

------------------------------------------------------------------ where the player is
local LANE = (Config.Zones and Config.Zones.List) or {}
local ISLAND_MARGIN = 40

local function laneZone(pos: Vector3): string?
	if pos.Y > 120 then
		return nil
	end
	for _, z in LANE do
		local b = z.Bounds
		-- (+6 in z covers half of the 12-stud License gate gap, so the look never flickers back to the hub between zones)
		if b and pos.X >= b[1] - 4 and pos.X <= b[3] + 4 and pos.Z >= b[2] - 6 and pos.Z <= b[4] + 6 then
			return z.Id
		end
	end
	return nil
end

local function islandZone(pos: Vector3): string?
	local wiring = workspace:FindFirstChild("IslandWiring")
	if not wiring then
		return nil
	end
	for _, f in wiring:GetChildren() do
		local lo, hi = f:GetAttribute("BoundsMin"), f:GetAttribute("BoundsMax")
		if typeof(lo) == "Vector3" and typeof(hi) == "Vector3" then
			local m = ISLAND_MARGIN
			if pos.X >= lo.X - m and pos.X <= hi.X + m and pos.Z >= lo.Z - m and pos.Z <= hi.Z + m and pos.Y >= lo.Y - m and pos.Y <= hi.Y + 80 then
				return f.Name
			end
		end
	end
	return nil
end

local function focus(): Vector3?
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		return hrp.Position
	end
	local cam = workspace.CurrentCamera
	return cam and cam.Focus.Position
end

-- the zone's geometry: what to search for anchors, the floor height, and which map it is
local function zoneGeometry(id: string, map: string): (Instance?, number?)
	local folder: Instance? = nil
	local scan: Instance? = nil
	if map == "lane" then
		local zones = workspace:FindFirstChild("Zones")
		folder = zones and zones:FindFirstChild(id)
		scan = folder
	else
		local wiring = workspace:FindFirstChild("IslandWiring")
		folder = wiring and wiring:FindFirstChild(id)
		local name = folder and folder:GetAttribute("Island")
		local world = workspace:FindFirstChild("WorldRedesign")
		scan = if type(name) == "string" and world then world:FindFirstChild(name) else nil
	end
	local arrival = folder and folder:FindFirstChild("Arrival")
	local ground: number? = nil
	if arrival and arrival:IsA("BasePart") then
		ground = arrival.Position.Y - arrival.Size.Y / 2
	elseif arrival and arrival:IsA("Model") then
		ground = arrival:GetPivot().Position.Y
	end
	return scan, ground
end

------------------------------------------------------------------ anchors: clusters of trees / water / rocks / landmarks
type Anchor = {
	key: string, kind: string, centre: Vector3, lo: Vector3, hi: Vector3, weight: number, names: string,
	base: number?, baseSum: number, baseN: number,
}

local function anyIn(hay: string, words: { string }?): boolean
	if not words then
		return false
	end
	for _, w in words do
		if string.find(hay, w, 1, true) then
			return true
		end
	end
	return false
end

-- the zone's own gameplay / structure containers (never anchors, whatever they hold)
local SKIP_TOP: { [string]: boolean } = {
	floor = true, walls = true, path = true, chevrons = true, eggspots = true, arrival = true, oddsboard = true,
	returnhome = true, safezone = true, island_top = true, island_underside = true, floor_plateau = true,
}
-- the redesign islands sort their parts into folders: the folder says what it is
local TOP_KIND: { [string]: string } = {
	vegetation = "vegetation", water = "water", foam_mist = "water", scenery_rocks = "rock", landmarks = "landmark",
}

local function classify(p: BasePart, top: string, find: { [string]: { string } }): (string?, string)
	if SKIP_TOP[top] then
		return nil, ""
	end
	local byFolder = TOP_KIND[top]
	if byFolder then
		local parent = p.Parent
		return byFolder, string.lower(p.Name .. " " .. (if parent then parent.Name else ""))
	end
	local own = string.lower(p.Name)
	if anyIn(own, find.exclude) then
		return nil, own
	end
	local parent = p.Parent
	local grand = parent and parent.Parent
	local hay = own .. " " .. string.lower((if parent then parent.Name else "") .. " " .. (if grand then grand.Name else ""))
	hay = string.gsub(hay, "street", "")
	if p.Material == Enum.Material.Water or anyIn(hay, find.water) then
		return "water", hay
	elseif anyIn(hay, find.vegetation) then
		return "vegetation", hay
	elseif anyIn(hay, find.landmark) then
		return "landmark", hay
	elseif anyIn(hay, find.rock) then
		return "rock", hay
	end
	return nil, hay
end

local CELL = 36

local function findAnchors(id: string, map: string, preset: any): ({ Anchor }, number?)
	local scan, ground = zoneGeometry(id, map)
	if not scan then
		return {}, ground
	end
	local find: { [string]: { string } } = {}
	for kind, words in Presets.FIND do
		local list = table.clone(words)
		local extra = preset.Find and preset.Find[kind]
		if extra then
			for _, w in extra do
				table.insert(list, w)
			end
		end
		find[kind] = list
	end
	local cells: { [string]: Anchor } = {}
	local bottoms: { [Instance]: number } = {} -- each decor model's lowest point (a tree's ground, under its trunk)
	local n = 0
	for _, d in scan:GetDescendants() do
		n += 1
		if n % 1500 == 0 then
			task.wait()
		end
		if d:IsA("BasePart") and d.Transparency < 0.98 then
			local top: Instance = d
			while top.Parent and top.Parent ~= scan do
				top = top.Parent
			end
			local kind, hay = classify(d, string.lower(top.Name), find)
			if kind then
				local half = d.Size / 2
				local pos = d.Position
				local key = kind .. ":" .. math.floor(pos.X / CELL) .. ":" .. math.floor(pos.Z / CELL)
				local a = cells[key]
				local lo, hi = pos - half, pos + half
				if not a then
					a = { key = key, kind = kind, centre = pos, lo = lo, hi = hi, weight = 0, names = "", base = nil, baseSum = 0, baseN = 0 }
					cells[key] = a
				end
				local aa = a :: Anchor
				-- the decor model this part belongs to (the child of the zone's container that holds it)
				local group: Instance = d
				while group.Parent and group.Parent ~= top and group ~= top do
					group = group.Parent
				end
				local bottom = bottoms[group]
				if not bottom then
					if group:IsA("Model") then
						local cf, size = group:GetBoundingBox()
						bottom = cf.Position.Y - size.Y / 2
					else
						bottom = lo.Y
					end
					bottoms[group] = bottom
				end
				aa.baseSum += bottom :: number
				aa.baseN += 1
				aa.lo = aa.lo:Min(lo)
				aa.hi = aa.hi:Max(hi)
				aa.weight += math.min(d.Size.X * d.Size.Z, 200)
				if #aa.names < 300 and not string.find(aa.names, hay, 1, true) then
					aa.names ..= "|" .. hay
				end
			end
		end
	end
	local list: { Anchor } = {}
	for _, a in cells do
		-- keep a cell's box sane (one huge part must not make a 300-stud emitter)
		local c = (a.lo + a.hi) / 2
		local half = ((a.hi - a.lo) / 2):Min(Vector3.new(CELL, 40, CELL))
		a.centre, a.lo, a.hi = c, c - half, c + half
		a.base = if a.baseN > 0 then a.baseSum / a.baseN else nil
		table.insert(list, a)
	end
	table.sort(list, function(x, y)
		return x.weight > y.weight
	end)
	-- at most 40 of a kind are kept (the heaviest); only the nearest few ever emit at once
	local kept: { Anchor } = {}
	local per: { [string]: number } = {}
	for _, a in list do
		per[a.kind] = (per[a.kind] or 0) + 1
		if per[a.kind] <= 40 then
			table.insert(kept, a)
		end
	end
	return kept, ground
end

------------------------------------------------------------------ particle emitters
local function texture(key: string?): string
	key = key or "dot"
	local id = Presets.TEXTURES[key :: string]
	if id then
		return id
	end
	local fallback = Presets.FALLBACK[key :: string] or key
	return Effects.TEXTURES[fallback] or Effects.TEXTURES.dot
end

local function colours(list: { Color3 }): ColorSequence
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local keys = {}
	for i, c in list do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c))
	end
	return ColorSequence.new(keys)
end

local function range(r: { number }?, default: number): NumberRange
	if not r then
		return NumberRange.new(default)
	end
	return NumberRange.new(r[1], r[2] or r[1])
end

local function sizeSeq(r: { number }): NumberSequence
	local mid = (r[1] + (r[2] or r[1])) / 2
	local env = ((r[2] or r[1]) - r[1]) / 2
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, mid * 0.7, env * 0.7),
		NumberSequenceKeypoint.new(0.2, mid, env),
		NumberSequenceKeypoint.new(0.8, mid, env),
		NumberSequenceKeypoint.new(1, mid * 0.8, env * 0.8),
	})
end

local function fadeSeq(opacity: number, twinkle: boolean?): NumberSequence
	local t = 1 - math.clamp(opacity, 0, 1)
	if twinkle then
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.12, t),
			NumberSequenceKeypoint.new(0.3, 1 - (1 - t) * 0.25),
			NumberSequenceKeypoint.new(0.5, t),
			NumberSequenceKeypoint.new(0.7, 1 - (1 - t) * 0.3),
			NumberSequenceKeypoint.new(0.85, t),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, t),
		NumberSequenceKeypoint.new(0.78, t),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function holder(name: string, cf: CFrame, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.CFrame = cf
	p.Parent = root
	return p
end

local function emitter(layer: any, parent: BasePart): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = layer.Name
	e:SetAttribute("NoLod", true) -- (EffectsLod leaves it to this script)
	e.Texture = texture(layer.Texture)
	e.Color = colours(layer.Color)
	e.Size = sizeSeq(layer.Size)
	e.Transparency = fadeSeq(layer.Opacity or 0.8, layer.Twinkle)
	e.Lifetime = range(layer.Lifetime, 8)
	e.Speed = range(layer.Speed, 0.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = layer.Accel or Vector3.zero
	e.Drag = layer.Drag or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = range(layer.RotSpeed, 0)
	e.LightEmission = math.min(layer.Emission or 0.1, 0.3)
	e.LightInfluence = layer.Influence or 0.6
	e.Orientation = Enum.ParticleOrientation.FacingCamera
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.ZOffset = -0.5
	e.LockedToPart = false
	e.Rate = 0
	e.Parent = parent
	return e
end

------------------------------------------------------------------ one zone's live ambience (fades in, fades out, cleans up)
type Live = {
	part: Part, emitter: ParticleEmitter, base: number, layer: any, anchor: Anchor?, active: boolean,
}
type ZoneFx = {
	id: string, map: string, preset: any, fade: number, target: number, gone: number?, ground: number?,
	anchors: { Anchor }?, air: { Live }, spots: { [Anchor]: { Live } }, glows: { [Anchor]: PointLight },
	sounds: { [Anchor]: { Sound } }, scanning: boolean, lastScan: number,
}
local zones: { ZoneFx } = {}

local function liveFor(fx: ZoneFx, layer: any): number
	local q = Presets.QUALITY[quality]
	return (layer.Rate or 1) * q.Rate * (if quality == "Low" then (layer.Low or 0.45) else 1)
end

local function buildAir(fx: ZoneFx)
	local q = Presets.QUALITY[quality]
	for _, layer in fx.preset.Layers or {} do
		if layer.Where == "air" and liveFor(fx, layer) > 0 then
			local box = (layer.Box or Vector3.new(90, 28, 90)) * q.AirBox
			local p = holder("Air_" .. layer.Name, CFrame.new(), box)
			table.insert(fx.air, { part = p, emitter = emitter(layer, p), base = liveFor(fx, layer), layer = layer, anchor = nil, active = true })
		end
	end
end

-- the box a layer emits from on an anchor
local function anchorBox(layer: any, a: Anchor, ground: number?): (CFrame, Vector3)
	-- (Ground = above the anchor's own ground - the foot of its trees - or the zone floor)
	local grow = layer.Grow or 0
	local lo, hi = a.lo - Vector3.new(grow, 0, grow), a.hi + Vector3.new(grow, 0, grow)
	local y0, y1 = lo.Y, hi.Y
	if layer.Above then
		y0, y1 = hi.Y + layer.Above[1], hi.Y + layer.Above[2]
	elseif layer.Ground then
		local g = a.base or ground or lo.Y
		y0, y1 = g + layer.Ground[1], g + layer.Ground[2]
	end
	local size = Vector3.new(math.max(hi.X - lo.X, 4), math.max(y1 - y0, 0.5), math.max(hi.Z - lo.Z, 4))
	return CFrame.new((lo.X + hi.X) / 2, (y0 + y1) / 2, (lo.Z + hi.Z) / 2), size
end

local function wants(layer: any, a: Anchor): boolean
	if layer.Where ~= a.kind then
		return false
	end
	return layer.Only == nil or anyIn(a.names, layer.Only)
end

local function buildSpot(fx: ZoneFx, a: Anchor)
	local list: { Live } = {}
	for _, layer in fx.preset.Layers or {} do
		if wants(layer, a) and liveFor(fx, layer) > 0 then
			local cf, size = anchorBox(layer, a, fx.ground)
			local p = holder(a.kind .. "_" .. layer.Name, cf, size)
			-- a bigger patch emits more (an anchor's rate grows with its footprint, within reason)
			local scale = math.clamp(size.X * size.Z / 900, 0.4, 2.5)
			table.insert(list, { part = p, emitter = emitter(layer, p), base = liveFor(fx, layer) * scale, layer = layer, anchor = a, active = false })
		end
	end
	fx.spots[a] = list
	if Presets.QUALITY[quality].Glows then
		for _, g in fx.preset.Glows or {} do
			if g.Where == a.kind and (g.Only == nil or anyIn(a.names, g.Only)) and not fx.glows[a] then
				local p = holder("Glow_" .. a.kind, CFrame.new(a.centre.X, a.hi.Y + (g.Lift or 2), a.centre.Z), Vector3.new(1, 1, 1))
				local light = Instance.new("PointLight")
				light.Color = g.Color or Color3.new(1, 1, 1)
				light.Range = g.Range or 18
				light.Brightness = 0
				light.Shadows = false
				light:SetAttribute("Base", g.Brightness or 1)
				light:SetAttribute("Pulse", g.Pulse or 0)
				light.Parent = p
				fx.glows[a] = light
			end
		end
	end
end

local function destroyZone(fx: ZoneFx)
	for _, l in fx.air do
		l.part:Destroy()
	end
	for _, list in fx.spots do
		for _, l in list do
			l.part:Destroy()
		end
	end
	for _, light in fx.glows do
		if light.Parent then
			(light.Parent :: Instance):Destroy()
		end
	end
	for _, list in fx.sounds do
		for _, s in list do
			s:Destroy()
		end
	end
	table.clear(fx.air)
	table.clear(fx.spots)
	table.clear(fx.glows)
	table.clear(fx.sounds)
end

local function rescan(fx: ZoneFx)
	if fx.scanning then
		return
	end
	fx.scanning = true
	fx.lastScan = os.clock()
	task.spawn(function()
		local ok, anchors, ground = pcall(findAnchors, fx.id, fx.map, fx.preset)
		fx.scanning = false
		if ok then
			-- keep the anchors we already have (their emitters are keyed by them); add the newly streamed-in ones
			local old: { [string]: Anchor } = {}
			for _, a in fx.anchors or {} do
				old[a.key] = a
			end
			local merged: { Anchor } = {}
			for _, a in anchors do
				table.insert(merged, old[a.key] or a)
				old[a.key] = nil
			end
			for _, a in old do
				table.insert(merged, a)
			end
			fx.anchors = merged
			fx.ground = ground or fx.ground
		end
	end)
end

local function startZone(id: string, map: string): ZoneFx?
	local preset = Presets.Zones[id]
	if not preset then
		return nil
	end
	local fx: ZoneFx = {
		id = id, map = map, preset = preset, fade = 0, target = 1, gone = nil, ground = nil, anchors = nil,
		air = {}, spots = {}, glows = {}, sounds = {}, scanning = false, lastScan = 0,
	}
	buildAir(fx)
	rescan(fx)
	table.insert(zones, fx)
	return fx
end

------------------------------------------------------------------ the zone boss: warnings always read first
local BOSS_OF: { [string]: string } = {}
for _, b in (Config.Bosses and Config.Bosses.List) or {} do
	if b.Zone and b.Model then
		BOSS_OF[b.Zone] = b.Model
	end
end
local function bossBusy(id: string): boolean
	local model = BOSS_OF[id]
	local states = model and ReplicatedStorage:FindFirstChild("BossStates")
	local s = states and states:FindFirstChild(model :: string)
	local state = s and s:GetAttribute("State")
	return state == "windup" or state == "attack"
end

------------------------------------------------------------------ quality
local function pickQuality(): string
	local forced = player:GetAttribute("AmbienceQuality")
	if forced == "High" or forced == "Low" then
		return forced
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Low"
	end
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if ok and level and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 4 then
		return "Low"
	end
	return "High"
end
quality = pickQuality()

------------------------------------------------------------------ the loop
local currentId: string? = nil -- the zone whose look is showing (nil = the place's own)
local fadeFrom: Look = readLook()
local fadeTo: Look = BASE
local fadeStart = 0
local fadeTime = 0
local fading = false
local wasSuspended = false
local dip = 1

local function beginFade(to: Look, seconds: number)
	fadeFrom = readLook()
	fadeTo = to
	fadeStart = os.clock()
	fadeTime = math.max(seconds, 0.05)
	fading = true
end

local function suspended(): boolean
	if player:GetAttribute("Traveling") then
		return true
	end
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam:FindFirstChild("HatchCC") ~= nil or cam.CFrame.Position.Y > 2000)
end

local currentMap: string? = nil
local function setZone(id: string?, map: string?)
	if id == currentId and (id == nil or map == currentMap) then
		return
	end
	-- (the same zone on the other map - lane <-> island - keeps its look but needs its own anchors)
	local sameLook = id == currentId
	currentId, currentMap = id, map
	player:SetAttribute("AmbienceZoneNow", id)
	for _, fx in zones do
		fx.target = if fx.id == id and fx.map == map then 1 else 0
	end
	if id and map then
		local have = false
		for _, fx in zones do
			if fx.id == id and fx.map == map then
				have = true
			end
		end
		if not have then
			startZone(id, map)
		end
	end
	if not sameLook and not suspended() then
		beginFade(lookFor(id), Presets.FADE)
	end
end

local zoneTimer = 0
local rateTimer = 0
local qualityTimer = 0
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	local off = player:GetAttribute("AmbienceOff") == true
	local hold = suspended()

	-- which zone (4 Hz)
	zoneTimer += dt
	if zoneTimer >= 0.25 then
		zoneTimer = 0
		local pos = focus()
		local id: string?, map: string? = nil, nil
		local forced = player:GetAttribute("AmbienceZone")
		if off then
			id = nil
		elseif type(forced) == "string" and Presets.Zones[forced] then
			id, map = forced, if laneZone(pos or Vector3.zero) == forced then "lane" else "island"
		elseif pos then
			local lane = laneZone(pos)
			if lane then
				id, map = lane, "lane"
			else
				local island = islandZone(pos)
				if island then
					id, map = island, "island"
				end
			end
		end
		if id and not Presets.Zones[id] then
			id = nil
		end
		setZone(id, map)
	end

	-- the lighting: hands off while travel / a hatch stage owns it; fade back in afterwards
	if hold then
		fading = false
		wasSuspended = true
	elseif wasSuspended then
		wasSuspended = false
		beginFade(lookFor(currentId), Presets.RESUME_FADE)
	end
	if fading then
		local a = math.clamp((now - fadeStart) / fadeTime, 0, 1)
		writeLook(fadeFrom, fadeTo, a * a * (3 - 2 * a))
		if a >= 1 then
			fading = false
		end
	end

	-- the air boxes follow the player
	local pos = focus()
	local cam = workspace.CurrentCamera
	for _, fx in zones do
		for _, l in fx.air do
			if pos then
				-- (sits on the player, a little up: the box's floor a couple of studs under their feet)
				l.part.CFrame = CFrame.new(pos + Vector3.new(0, l.part.Size.Y / 2 - 5, 0))
			end
		end
	end

	-- zone fades, rates, anchors (10 Hz)
	rateTimer += dt
	if rateTimer < 0.1 then
		return
	end
	local step = rateTimer
	rateTimer = 0

	qualityTimer += step
	if qualityTimer > 5 then
		qualityTimer = 0
		local q = pickQuality()
		if q ~= quality then
			-- rebuild every zone on the new profile (rare: a graphics change)
			quality = q
			for _, fx in zones do
				destroyZone(fx)
				buildAir(fx)
			end
			if not hold and not fading then
				beginFade(lookFor(currentId), 0.5)
			end
		end
	end

	local busy = currentId ~= nil and bossBusy(currentId)
	local dipTarget = 1
	if busy then
		local preset = Presets.Zones[currentId :: string]
		dipTarget = (preset and preset.BossDip) or 0.35
	end
	dip += (dipTarget - dip) * math.min(step * 4, 1)

	local q = Presets.QUALITY[quality]
	local camPos = if cam then cam.CFrame.Position else (pos or Vector3.zero)
	for i = #zones, 1, -1 do
		local fx = zones[i]
		local speed = step / Presets.FADE
		fx.fade = if fx.target > fx.fade then math.min(fx.fade + speed, 1) else math.max(fx.fade - speed, 0)
		local show = if hold then 0 else fx.fade

		-- streaming: the zone's far parts arrive later, so look again now and then while you're in it
		-- (soon after you arrive the zone has barely streamed in: look again within seconds until it has)
		local every = if fx.anchors and #fx.anchors < 6 then 4 else 20
		if fx.target == 1 and fx.anchors and not fx.scanning and workspace.StreamingEnabled and os.clock() - fx.lastScan > every then
			rescan(fx)
		end

		-- the nearest anchors within range emit; the rest are idle
		local near: { [Anchor]: boolean } = {}
		if fx.anchors and fx.target == 1 then
			local ranked = {}
			for _, a in fx.anchors do
				local d = (a.centre - camPos).Magnitude
				if d < q.Radius then
					table.insert(ranked, { a = a, d = d })
				end
			end
			table.sort(ranked, function(x, y)
				return x.d < y.d
			end)
			local count: { [string]: number } = {}
			for _, r in ranked do
				count[r.a.kind] = (count[r.a.kind] or 0) + 1
				if count[r.a.kind] <= q.Anchors then
					near[r.a] = true
					if not fx.spots[r.a] then
						buildSpot(fx, r.a)
					end
				end
			end
		end

		for _, l in fx.air do
			l.emitter.Rate = l.base * show * dip
		end
		for a, list in fx.spots do
			local on = near[a] == true
			for _, l in list do
				l.emitter.Rate = if on then l.base * show * dip else 0
			end
		end

		-- glows breathe gently (never strobe: one slow sine)
		for a, light in fx.glows do
			local base = light:GetAttribute("Base") :: number? or 1
			local pulse = light:GetAttribute("Pulse") :: number? or 0
			local breath = if pulse > 0 then 0.75 + 0.25 * math.sin(now * math.pi * 2 / pulse + a.centre.X * 0.1) else 1
			light.Enabled = near[a] == true
			light.Brightness = base * breath * show
		end

		-- ambient loops on the nearest anchors of a kind (ids from Shared.Sfx only)
		for _, def in fx.preset.Sounds or {} do
			if def.Where ~= "air" and fx.anchors then
				local placed = 0
				for a in near do
					if a.kind == def.Where and placed < (def.Max or 1) then
						placed += 1
						if not fx.sounds[a] then
							local list = {}
							local spot = fx.spots[a] and fx.spots[a][1]
							local carrier = if spot then spot.part else nil
							if carrier then
								local s = Sfx.loop(def.Name, carrier, { volume = 0, range = def.Range })
								if s then
									s:SetAttribute("Want", def.Volume or 0.5)
									table.insert(list, s)
								end
							end
							fx.sounds[a] = list
						end
					end
				end
			elseif def.Where == "air" and not fx.sounds[def :: any] then
				local p = fx.air[1] and fx.air[1].part
				local s = p and Sfx.loop(def.Name, p, { volume = 0, range = def.Range })
				if s then
					s:SetAttribute("Want", def.Volume or 0.5)
					fx.sounds[def :: any] = { s }
				end
			end
		end
		for _, list in fx.sounds do
			for _, s in list do
				local def = Sfx.LIST[string.gsub(s.Name, "^Sfx_", "")]
				local want = (s:GetAttribute("Want") :: number? or 0.5) * (if def then def.volume else 0.3)
				s.Volume = want * show
			end
		end

		-- gone: everything has faded out (wait out the longest particle life, then clean up)
		if fx.target == 0 and fx.fade <= 0 then
			fx.gone = fx.gone or now
			if now - (fx.gone :: number) > 16 then
				destroyZone(fx)
				table.remove(zones, i)
			end
		else
			fx.gone = nil
		end
	end
end)

