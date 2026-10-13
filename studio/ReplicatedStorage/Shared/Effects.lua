--!strict
-- VFX v2: anime-style effects built from the user's 4 reference images. Textures are made in Blender
-- (HatchLawyers/tools/vfx_textures.py) as white + alpha and tinted here; three of them are 4x4 flipbooks.
--   ICE    (Rare)       cyan slash rings swirling round the body, a floor swirl, ice crystals popping out of
--                       the floor, floating light orbs, an icy shockwave flipbook.
--   ENERGY (Epic)       a churning blue-purple energy orb behind the lawyer, spiky spark streaks, dark specks.
--   FIRE   (Legendary)  a fire tornado: stacked gold/orange slash rings spinning up the body, flame tongues,
--                       embers, a scrolling light column, a floor swirl, star glints.
--   INFERNO (Mythic)    the fire tornado in crimson, plus a crimson energy orb with dark specks.
--   CELESTIAL (Supreme) a rainbow fire tornado, rainbow star glints, a rainbow energy orb and a spinning halo.
--   STAR   (merged)     2 stars: gold star glints + a gold ring. 3 stars: rainbow, plus a rainbow energy orb.
-- API (server calls these so every player sees them; particles replicate):
--   Effects.aura(model, rarityId, stars)    lasting aura on a desk lawyer (replaces any earlier one)
--   Effects.rarityBurst(rarityId)           which burst a hatched / placed lawyer of that rarity gets (nil = none)
--   Effects.burst(where, kind, color?)      one-shot: "rare" (ice), "epic" (energy + star burst),
--                                           "legendary" (star burst + fire + coins), "mythic" (crimson inferno),
--                                           "supreme" (rainbow everything, biggest),
--                                           "win" (star burst + coins), "tier" (star burst), "merge" (energy),
--                                           "rainbow" (rainbow energy + star burst)
--   Effects.ambient(parent, theme, color?, scale?)  small looping sparkle set ("star"/"ice"/"fire"/"energy")
--                                           for Neon skins, gold desks, signs and the egg machines. It
--                                           replaces every old plain-sparkle ParticleEmitter.
--   Effects.guiBurst(parent, position, px, color, seconds, z)   (client) star flare + spinning slash rings
--                                           behind a pop-up (Rewards).
-- Effects.TEXTURES is shared with client GUI code (the hatch screen).

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Effects = {}

Effects.TEXTURES = {
	-- v1 (tools/effects_textures.py)
	glow = "rbxassetid://132825432359825",
	flare = "rbxassetid://135820522011353",
	twinkle = "rbxassetid://128888379669288",
	rays = "rbxassetid://134620410097600",
	ring = "rbxassetid://71380376418393",
	wisp = "rbxassetid://106375343597498",
	swirl = "rbxassetid://110019670977633",
	column = "rbxassetid://93546403861691",
	dot = "rbxassetid://115135517607406",
	coin = "rbxassetid://71491566430133",
	-- v2 (tools/vfx_textures.py)
	slashArc = "rbxassetid://73384239239287",
	slashRing = "rbxassetid://135935594597794",
	star = "rbxassetid://90593358027334",
	tendrils = "rbxassetid://125478326457964",
	spark = "rbxassetid://78182597037425",
	streak = "rbxassetid://86651092788757",
	ember = "rbxassetid://105197447339787",
	speck = "rbxassetid://72475474818685",
	crystal = "rbxassetid://76565517005869",
	iceFlip = "rbxassetid://121603839582929", -- 4x4 flipbooks
	flameFlip = "rbxassetid://106510577444044",
	energyFlip = "rbxassetid://78823568074078",
}
local T = Effects.TEXTURES

local function grad(...: Color3): ColorSequence
	local c = { ... }
	local kps = {}
	for i, col in c do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(#c - 1, 1), col))
	end
	if #kps == 1 then
		return ColorSequence.new(c[1])
	end
	return ColorSequence.new(kps)
end

Effects.GOLD = Color3.fromRGB(255, 200, 60)
Effects.BLUE = Color3.fromRGB(80, 170, 255)
Effects.ICE = Color3.fromRGB(40, 200, 255)
Effects.RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 255, 120)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
})
Effects.FIRE = grad(Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 110, 15), Color3.fromRGB(220, 40, 10))
Effects.ENERGY = grad(Color3.fromRGB(120, 190, 255), Color3.fromRGB(90, 80, 255), Color3.fromRGB(160, 40, 255))
Effects.MYTHIC_FIRE = grad(Color3.fromRGB(255, 130, 160), Color3.fromRGB(229, 57, 53), Color3.fromRGB(120, 10, 40))
Effects.MYTHIC_ENERGY = grad(Color3.fromRGB(255, 100, 130), Color3.fromRGB(205, 30, 60), Color3.fromRGB(95, 10, 60))
Effects.MYTHIC = Color3.fromRGB(229, 57, 53)
local STAR_RED = grad(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 80, 60))
local DARK = ColorSequence.new(Color3.fromRGB(25, 10, 30))
local BLOOD = ColorSequence.new(Color3.fromRGB(110, 12, 12))

local function seq(points: { { number } }): NumberSequence
	local kps = {}
	for _, p in points do
		table.insert(kps, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(kps)
end

-- fade in, hold, fade out
local FADE = seq({ { 0, 1 }, { 0.15, 0.1 }, { 0.7, 0.2 }, { 1, 1 } })

-- A ParticleEmitter with sane defaults; props override. LightEmission stays LOW everywhere (<= 0.3): the firm
-- floor is bright yellow and additive sprites vanish against it (checked in playtest), so sprites alpha-blend
-- their colour and Brightness > 1 makes them pop instead.
local function emitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.LightEmission = 0.15
	e.LightInfluence = 0
	e.Brightness = 1.6
	e.Rate = 0
	e.Speed = NumberRange.new(0)
	e.Lifetime = NumberRange.new(1)
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- 4x4 flipbook props merged into `props`
local function flip(props: { [string]: any }, mode: Enum.ParticleFlipbookMode, fps: number?): { [string]: any }
	props.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	props.FlipbookMode = mode
	if fps then
		props.FlipbookFramerate = NumberRange.new(fps)
	end
	return props
end

local function colorOf(c: Color3 | ColorSequence): ColorSequence
	return if typeof(c) == "ColorSequence" then c else ColorSequence.new(c)
end

local function firstColor(c: Color3 | ColorSequence): Color3
	return if typeof(c) == "Color3" then c else (c :: ColorSequence).Keypoints[math.ceil(#(c :: ColorSequence).Keypoints / 2)].Value
end

-- An attachment on `part` at `offset` (part space), tagged so clearAura removes it.
local function attach(part: BasePart, name: string, offset: CFrame, tag: string?): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = offset
	if tag then
		a:SetAttribute(tag, true)
	end
	a.Parent = part
	return a
end

-- A flat slash-ring that spins in the attachment's XZ plane (tilt the attachment to tilt the ring).
-- VelocityPerpendicular + a tiny upward speed lays the sprite flat; RotSpeed spins it.
local function spinRing(at: Attachment, name: string, size: number, color: ColorSequence, spin: number, rate: number, life: number, texture: string?): ParticleEmitter
	return emitter(at, name, {
		Texture = texture or T.slashRing, Color = color, Rate = rate, Lifetime = NumberRange.new(life),
		Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0),
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, LockedToPart = true,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(spin),
		Size = seq({ { 0, size * 0.85 }, { 1, size * 1.05 } }), Transparency = FADE, LightEmission = 0.2, Brightness = 2,
	})
end

-- The part an aura hangs on: the lawyer's torso / root.
local function bodyOf(model: Model): BasePart?
	for _, name in { "HumanoidRootPart", "Torso", "UpperTorso", "RootPart" } do
		local p = model:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return model.PrimaryPart
end

function Effects.clearAura(model: Model)
	for _, d in model:GetDescendants() do
		if d:GetAttribute("FxAura") then
			d:Destroy()
		end
	end
end

type Ctx = { body: BasePart, center: Attachment, feet: Attachment, feetY: number, height: number, tag: (Instance) -> () }

-- ---------------------------------------------------------------------------------------------- auras
local function iceAura(c: Ctx)
	local h = c.height
	local ice = grad(Color3.fromRGB(150, 240, 255), Effects.ICE, Color3.fromRGB(30, 110, 255))
	-- floor swirl (two counter-spinning slash rings)
	c.tag(spinRing(c.feet, "IceFloor", h * 1.5, ice, 140, 0.9, 2.2))
	c.tag(spinRing(c.feet, "IceFloor2", h * 1.05, ice, -200, 0.9, 1.8))
	-- tilted slash rings swirling round the body
	for i, tilt in { { 0.42, 30, 0 }, { 0.62, -26, 30 } } do
		local at = attach(c.body, "FxIceRing" .. i, c.center.CFrame * CFrame.new(0, (tilt[1] - 0.5) * h, 0)
			* CFrame.Angles(math.rad(tilt[2]), 0, math.rad(tilt[3])), "FxAura")
		c.tag(spinRing(at, "IceRing", h * 0.95, ice, if i == 1 then 320 else -280, 1.6, 0.9))
	end
	-- quick slash flashes facing the camera
	c.tag(emitter(c.center, "IceSlash", {
		Texture = T.slashArc, Color = ice, Rate = 1.4, Lifetime = NumberRange.new(0.35), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(260), Size = seq({ { 0, h * 0.5 }, { 1, h * 0.95 } }),
		Transparency = seq({ { 0, 1 }, { 0.2, 0 }, { 1, 1 } }), LockedToPart = true, LightEmission = 0.25, Brightness = 2.5,
	}))
	-- ice crystals popping out of the floor
	c.tag(emitter(c.feet, "Crystals", {
		Texture = T.crystal, Color = ColorSequence.new(Color3.fromRGB(190, 245, 255)), Rate = 2.4,
		Lifetime = NumberRange.new(1.4, 2), Speed = NumberRange.new(4, 6), EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(75, 75), Drag = 7, Acceleration = Vector3.new(0, -0.5, 0),
		Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
		Size = seq({ { 0, 0 }, { 0.12, 1.5 }, { 0.8, 1.3 }, { 1, 0 } }), Transparency = seq({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }),
		LightEmission = 0.15,
	}))
	-- floating light orbs
	c.tag(emitter(c.center, "IceOrbs", {
		Texture = T.ember, Color = ColorSequence.new(Effects.ICE), Rate = 7, Lifetime = NumberRange.new(1.4, 2.2),
		Speed = NumberRange.new(0.6, 1.6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 0.8, 0),
		Size = seq({ { 0, 0 }, { 0.2, 0.7 }, { 0.8, 0.5 }, { 1, 0 } }), LightEmission = 0.25, Brightness = 2.5,
	}))
	-- icy shockwave flipbook on the floor
	c.tag(emitter(c.feet, "IceWave", flip({
		Texture = T.iceFlip, Color = ice, Rate = 0.5, Lifetime = NumberRange.new(1.1),
		Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0),
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Size = NumberSequence.new(h * 1.8),
		LightEmission = 0.2, Brightness = 2,
	}, Enum.ParticleFlipbookMode.OneShot)))
end

local function energyAura(c: Ctx, tint: ColorSequence, specks: boolean)
	local h = c.height
	-- the churning orb (looping flipbook) behind the lawyer
	c.tag(emitter(c.center, "EnergyOrb", flip({
		Texture = T.energyFlip, Color = tint, Rate = 0.9, Lifetime = NumberRange.new(2.2),
		Size = NumberSequence.new(h * 1.25), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40),
		Transparency = seq({ { 0, 1 }, { 0.25, 0.15 }, { 0.75, 0.2 }, { 1, 1 } }), LockedToPart = true, ZOffset = -2,
		LightEmission = 0.25, Brightness = 2,
	}, Enum.ParticleFlipbookMode.Loop, 18)))
	-- spiky spark streaks shooting out
	c.tag(emitter(c.center, "EnergySpikes", {
		Texture = T.spark, Color = tint, Rate = 7, Lifetime = NumberRange.new(0.25, 0.4), Speed = NumberRange.new(9, 14),
		SpreadAngle = Vector2.new(180, 180), Drag = 5, Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = seq({ { 0, 1.4 }, { 1, 0.2 } }), LightEmission = 0.25, Brightness = 2.5,
	}))
	-- bright motes drifting round
	c.tag(emitter(c.center, "EnergyMotes", {
		Texture = T.ember, Color = tint, Rate = 9, Lifetime = NumberRange.new(0.9, 1.5), Speed = NumberRange.new(1, 2.5),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.2, 0.45 }, { 1, 0 } }), LightEmission = 0.25, Brightness = 2,
	}))
	if specks then
		-- little dark specks (the black particles in the reference)
		c.tag(emitter(c.center, "EnergySpecks", {
			Texture = T.speck, Color = DARK, Rate = 8, Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(1.5, 3.5),
			SpreadAngle = Vector2.new(180, 180), Drag = 1, Size = seq({ { 0, 0.3 }, { 1, 0 } }), LightEmission = 0, Brightness = 1,
		}))
	end
end

local function fireAura(c: Ctx, tint: ColorSequence?)
	local h = c.height
	local fire = tint or Effects.FIRE
	-- the tornado: slash rings stacked up the body, narrower towards the top, all spinning the same way
	for i, row in { { 0.08, 1.35 }, { 0.38, 1.1 }, { 0.68, 0.9 }, { 0.95, 0.7 } } do
		local at = attach(c.body, "FxFireRing" .. i, CFrame.new(0, c.feetY + row[1] * h - c.body.Position.Y, 0)
			* CFrame.Angles(math.rad(24 * (i % 2 * 2 - 1)), 0, math.rad(14)), "FxAura")
		c.tag(spinRing(at, "FireRing", h * row[2], fire, 380 + i * 40, 2.6, 0.75))
	end
	c.tag(spinRing(c.feet, "FireFloor", h * 1.7, fire, -120, 0.8, 2.2))
	-- flame tongues licking up from the floor (flipbook)
	c.tag(emitter(c.feet, "Flames", flip({
		Texture = T.flameFlip, Color = fire, Rate = 9, Lifetime = NumberRange.new(0.7, 1),
		Speed = NumberRange.new(3, 5), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(60, 60), Drag = 3,
		Acceleration = Vector3.new(0, 6, 0), Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
		Size = seq({ { 0, 1.2 }, { 0.5, 2.6 }, { 1, 1.6 } }), Transparency = seq({ { 0, 0.2 }, { 0.8, 0.3 }, { 1, 1 } }),
		LightEmission = 0.25, Brightness = 2.2,
	}, Enum.ParticleFlipbookMode.OneShot)))
	-- embers streaming up
	c.tag(emitter(c.feet, "Embers", {
		Texture = T.ember, Color = fire, Rate = 16, Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(4, 8),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 3, 0),
		Size = seq({ { 0, 0.7 }, { 1, 0 } }), LightEmission = 0.3, Brightness = 2.5,
	}))
	-- star glints popping round the body
	c.tag(emitter(c.center, "Glints", {
		Texture = T.star, Color = ColorSequence.new(Color3.fromRGB(255, 240, 180)), Rate = 2.2, Lifetime = NumberRange.new(0.45),
		Speed = NumberRange.new(2, 3), SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 3 }, { 1, 0 } }),
		LightEmission = 0.3, Brightness = 2.5,
	}))
	-- a scrolling streaky column of light
	local top = attach(c.body, "FxTop", CFrame.new(0, c.feetY + h + 7 - c.body.Position.Y, 0), "FxAura")
	local beam = Instance.new("Beam")
	beam.Name = "FxColumn"
	beam.Attachment0 = c.feet
	beam.Attachment1 = top
	beam.Texture = T.column
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Color = fire
	beam.LightEmission = 0.25
	beam.LightInfluence = 0
	beam.Brightness = 2
	beam.FaceCamera = true
	beam.Width0 = h * 0.9
	beam.Width1 = h * 0.35
	beam.Transparency = seq({ { 0, 0.25 }, { 1, 1 } })
	c.tag(beam)
	beam.Parent = c.body
end

local function starAura(c: Ctx, tint: ColorSequence)
	local h = c.height
	c.tag(emitter(c.center, "StarGlints", {
		Texture = T.star, Color = tint, Rate = 3, Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(1, 2.5),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 2.2 }, { 1, 0 } }), LightEmission = 0.3, Brightness = 2,
	}))
	c.tag(emitter(c.center, "StarDust", {
		Texture = T.ember, Color = tint, Rate = 14, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 1.5, 0), Size = seq({ { 0, 0 }, { 0.3, 0.35 }, { 1, 0 } }),
		LightEmission = 0.25, Brightness = 2,
	}))
	c.tag(spinRing(c.feet, "StarFloor", h * 1.25, tint, 90, 0.6, 2.6))
end

-- Lasting aura, laddered by rarity ("Common".."Supreme") and merge stars (1-3).
local AURA_RARITIES = { Rare = true, Epic = true, Legendary = true, Mythic = true, Supreme = true }
function Effects.aura(model: Model, rarity: string?, stars: number?)
	Effects.clearAura(model)
	local s = stars or 1
	if not (rarity and AURA_RARITIES[rarity]) and s < 2 then
		return
	end
	local body = bodyOf(model)
	if not body then
		return
	end
	local box, size = model:GetBoundingBox()
	local feetY = box.Position.Y - size.Y / 2
	local function tag(i: Instance)
		i:SetAttribute("FxAura", true)
	end
	local center = attach(body, "FxCenter", CFrame.new(), "FxAura")
	local feet = attach(body, "FxFeet", CFrame.new(), "FxAura")
	feet.WorldCFrame = CFrame.new(body.Position.X, feetY + 0.15, body.Position.Z)
	local c: Ctx = { body = body, center = center, feet = feet, feetY = feetY, height = size.Y, tag = tag }

	if rarity == "Rare" then
		iceAura(c)
	elseif rarity == "Epic" then
		energyAura(c, Effects.ENERGY, true)
	elseif rarity == "Legendary" then
		fireAura(c)
	elseif rarity == "Mythic" then
		fireAura(c, Effects.MYTHIC_FIRE)
		energyAura(c, Effects.MYTHIC_ENERGY, true)
	elseif rarity == "Supreme" then
		fireAura(c, Effects.RAINBOW)
		energyAura(c, Effects.RAINBOW, false)
		starAura(c, Effects.RAINBOW)
		-- a halo spinning over the head
		local haloAt = attach(c.body, "FxHalo", CFrame.new(0, c.feetY + c.height + 0.5 - c.body.Position.Y, 0), "FxAura")
		c.tag(spinRing(haloAt, "Halo", c.height * 0.42, grad(Color3.fromRGB(255, 250, 220), Effects.GOLD), 120, 1.4, 1.2))
	end
	if s >= 3 then
		starAura(c, Effects.RAINBOW)
		energyAura(c, Effects.RAINBOW, false)
	elseif s >= 2 then
		starAura(c, grad(Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 130, 10)))
	end

	local light = Instance.new("PointLight")
	light.Name = "FxLight"
	light.Color = if s >= 3 or rarity == "Supreme" then Color3.fromRGB(255, 220, 255) elseif rarity == "Rare" then Effects.ICE
		elseif rarity == "Epic" then Color3.fromRGB(150, 120, 255) elseif rarity == "Mythic" then Effects.MYTHIC else Effects.GOLD
	-- dim on purpose: at high graphics quality bright aura lights wash the whole office out
	local top = rarity == "Legendary" or rarity == "Mythic" or rarity == "Supreme"
	light.Range = if top then 12 else 9
	light.Brightness = if top then 0.8 else 0.6
	light.Shadows = false
	tag(light)
	light.Parent = body
end

-- ---------------------------------------------------------------------------------------------- bursts
local RARITY_BURSTS = { Rare = "rare", Epic = "epic", Legendary = "legendary", Mythic = "mythic", Supreme = "supreme" }
-- The burst a lawyer of this rarity gets when it hatches / is placed (nil: Common and Uncommon get none).
function Effects.rarityBurst(rarity: string?): string?
	return if rarity then RARITY_BURSTS[rarity] else nil
end

-- One-shot burst. `where`: a BasePart (bursts at its centre), or a world position.
function Effects.burst(where: BasePart | Vector3, kind: string, color: (Color3 | ColorSequence)?)
	local pos = if typeof(where) == "Vector3" then where else (where :: BasePart).Position
	local holder = Instance.new("Part")
	holder.Name = "FxBurst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.CFrame = CFrame.new(pos)
	holder.Parent = workspace
	local at = Instance.new("Attachment")
	at.Parent = holder
	-- the floor under the burst, for ground effects (tendrils, shockwaves)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { holder }
	local hit = workspace:Raycast(pos, Vector3.new(0, -14, 0), params)
	local ground = Instance.new("Attachment")
	ground.Parent = holder
	ground.WorldPosition = if hit then hit.Position + Vector3.new(0, 0.2, 0) else pos - Vector3.new(0, 3, 0)

	local fiery = kind == "legendary" or kind == "mythic" or kind == "supreme"
	local big = fiery or kind == "rainbow"
	local scale = if kind == "supreme" then 1.8 elseif big then 1.5 elseif kind == "tier" or kind == "rare" then 0.95 else 1.15
	local function burst(name: string, count: number, props: { [string]: any }, on: Attachment?, delay: number?)
		local e = emitter(on or at, name, props)
		-- bursts stack many sprites in one spot: above ~1.4 the colours clip to white (playtested)
		e.Brightness = math.min(e.Brightness, 1.4)
		task.delay(delay or 0, function()
			e:Emit(count)
		end)
	end
	local function flatRing(name: string, tint: ColorSequence, from: number, to: number, life: number, spin: number, texture: string?, on: Attachment?, delay: number?)
		burst(name, 1, {
			Texture = texture or T.slashRing, Color = tint, Lifetime = NumberRange.new(life), Speed = NumberRange.new(0.01),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(spin), Size = seq({ { 0, from }, { 1, to } }),
			Transparency = seq({ { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }), LightEmission = 0.25, Brightness = 2.5,
		}, on, delay)
	end
	-- the reference-3 star burst: a white-hot 4-point flare, smoky ground tendrils, red-hot sparks
	local function starBurst(tint: ColorSequence, ground_: ColorSequence)
		burst("StarFlare", 1, { Texture = T.star, Color = tint, Lifetime = NumberRange.new(0.7), LightEmission = 0.3, Brightness = 3,
			Size = seq({ { 0, 2 }, { 0.12, 26 * scale }, { 0.4, 16 * scale }, { 1, 0 } }), ZOffset = 2 })
		burst("StarCore", 1, { Texture = T.glow, Color = ColorSequence.new(Color3.new(1, 1, 1)), Lifetime = NumberRange.new(0.45),
			LightEmission = 0.3, Brightness = 2, Size = seq({ { 0, 1 }, { 0.15, 5 * scale }, { 1, 0 } }), ZOffset = 3 })
		burst("Tendrils", 2, { Texture = T.tendrils, Color = ground_, Lifetime = NumberRange.new(1.4, 1.7), LightEmission = 0, Brightness = 1,
			Speed = NumberRange.new(0.01), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Rotation = NumberRange.new(0, 360),
			Size = seq({ { 0, 3 }, { 0.15, 16 * scale }, { 1, 18 * scale } }), Transparency = seq({ { 0, 0.1 }, { 0.6, 0.3 }, { 1, 1 } }) }, ground)
		burst("Sparks", math.floor(34 * scale), { Texture = T.spark, Color = tint, Lifetime = NumberRange.new(0.35, 0.7),
			Speed = NumberRange.new(30, 55), SpreadAngle = Vector2.new(180, 180), Drag = 5, LightEmission = 0.3, Brightness = 2.5,
			Orientation = Enum.ParticleOrientation.VelocityParallel, Size = seq({ { 0, 1.5 * scale }, { 1, 0.2 } }) })
		burst("Embers", math.floor(30 * scale), { Texture = T.ember, Color = tint, Lifetime = NumberRange.new(0.8, 1.4),
			Speed = NumberRange.new(8, 20), SpreadAngle = Vector2.new(180, 180), Drag = 3, Acceleration = Vector3.new(0, 4, 0),
			Size = seq({ { 0, 0.6 }, { 1, 0 } }), LightEmission = 0.3, Brightness = 2.5 })
		flatRing("Shock", tint, 2, 24 * scale, 0.6, 300, T.ring, ground)
	end

	local tint: Color3 | ColorSequence = color or Effects.GOLD
	if kind == "rare" then
		local ice = grad(Color3.fromRGB(150, 240, 255), Effects.ICE, Color3.fromRGB(30, 110, 255))
		burst("IceWave", 1, flip({ Texture = T.iceFlip, Color = ice, Lifetime = NumberRange.new(0.8), Speed = NumberRange.new(0.01),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			Size = NumberSequence.new(18 * scale), LightEmission = 0.1, Brightness = 1.3 }, Enum.ParticleFlipbookMode.OneShot), ground)
		flatRing("IceSwirl", ice, 4, 14 * scale, 0.9, 420, nil, ground)
		for i = 0, 3 do
			burst("IceSlash" .. i, 1, { Texture = T.slashArc, Color = ice, Lifetime = NumberRange.new(0.4), Rotation = NumberRange.new(i * 90 + math.random(-20, 20)),
				RotSpeed = NumberRange.new(300), Size = seq({ { 0, 5 * scale }, { 1, 12 * scale } }), Transparency = seq({ { 0, 0 }, { 1, 1 } }),
				LightEmission = 0.25, Brightness = 3 }, nil, i * 0.07)
		end
		burst("Crystals", 14, { Texture = T.crystal, Color = ColorSequence.new(Color3.fromRGB(200, 245, 255)), Lifetime = NumberRange.new(0.9, 1.3),
			Speed = NumberRange.new(12, 20), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(70, 70), Drag = 4,
			Acceleration = Vector3.new(0, -25, 0), Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
			Size = seq({ { 0, 0 }, { 0.1, 2.2 * scale }, { 0.8, 1.8 * scale }, { 1, 0 } }), LightEmission = 0.15 })
		burst("IceOrbs", 20, { Texture = T.ember, Color = ColorSequence.new(Effects.ICE), Lifetime = NumberRange.new(0.9, 1.6),
			Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Drag = 3, Size = seq({ { 0, 0.9 }, { 1, 0 } }),
			LightEmission = 0.3, Brightness = 3 })
		burst("IceFlare", 1, { Texture = T.star, Color = ice, Lifetime = NumberRange.new(0.5), LightEmission = 0.3, Brightness = 3,
			Size = seq({ { 0, 2 }, { 0.15, 14 * scale }, { 1, 0 } }) })
		tint = Effects.ICE
	elseif kind == "merge" or kind == "rainbow" or kind == "epic" then
		local energy = if kind == "rainbow" then Effects.RAINBOW else (if color then colorOf(color) else Effects.ENERGY)
		burst("EnergyOrb", 1, flip({ Texture = T.energyFlip, Color = energy, Lifetime = NumberRange.new(1), LightEmission = 0.3, Brightness = 2.5,
			Size = seq({ { 0, 2 }, { 0.2, 13 * scale }, { 0.7, 11 * scale }, { 1, 0 } }), RotSpeed = NumberRange.new(120) }, Enum.ParticleFlipbookMode.Loop, 20))
		burst("EnergySpikes", math.floor(28 * scale), { Texture = T.spark, Color = energy, Lifetime = NumberRange.new(0.3, 0.55),
			Speed = NumberRange.new(25, 45), SpreadAngle = Vector2.new(180, 180), Drag = 6, LightEmission = 0.3, Brightness = 3,
			Orientation = Enum.ParticleOrientation.VelocityParallel, Size = seq({ { 0, 2.2 * scale }, { 1, 0.2 } }) })
		burst("EnergySpecks", 30, { Texture = T.speck, Color = DARK, Lifetime = NumberRange.new(0.6, 1.1), LightEmission = 0, Brightness = 1,
			Speed = NumberRange.new(8, 18), SpreadAngle = Vector2.new(180, 180), Drag = 4, Size = seq({ { 0, 0.45 }, { 1, 0 } }) })
		burst("EnergyMotes", 24, { Texture = T.ember, Color = energy, Lifetime = NumberRange.new(0.7, 1.2), LightEmission = 0.3, Brightness = 2.5,
			Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Drag = 3, Size = seq({ { 0, 0.7 }, { 1, 0 } }) })
		flatRing("EnergyRing", energy, 3, 16 * scale, 0.8, -380, nil, ground)
		if kind == "rainbow" then
			starBurst(Effects.RAINBOW, DARK)
		elseif kind == "epic" then
			starBurst(grad(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 90, 255)), DARK)
		end
		tint = if kind == "rainbow" then Effects.RAINBOW else Color3.fromRGB(140, 120, 255)
	else
		-- legendary / mythic / supreme / win / tier: the star burst (gold for good news)
		local hot = if kind == "legendary" then STAR_RED
			elseif kind == "mythic" then grad(Color3.fromRGB(255, 255, 255), Effects.MYTHIC)
			elseif kind == "supreme" then Effects.RAINBOW
			else grad(Color3.fromRGB(255, 255, 230), Effects.GOLD)
		local under = if kind == "legendary" or kind == "mythic" then BLOOD elseif kind == "supreme" then DARK
			else ColorSequence.new(Color3.fromRGB(120, 70, 10))
		starBurst(color and colorOf(color) or hot, under)
		if fiery then
			-- plus the fire tornado ramping up out of the ground (crimson for Mythic, rainbow for Supreme)
			local fire = if kind == "mythic" then Effects.MYTHIC_FIRE elseif kind == "supreme" then Effects.RAINBOW else Effects.FIRE
			for i = 0, 2 do
				local ring = Instance.new("Attachment")
				ring.Parent = holder
				ring.WorldPosition = ground.WorldPosition + Vector3.new(0, 1 + i * 2.2, 0)
				flatRing("FireRing" .. i, fire, (10 - i * 2) * scale, (13 - i * 2) * scale, 0.9, 500 + i * 80, nil, ring, i * 0.08)
			end
			if kind == "supreme" then
				burst("EnergyOrb", 1, flip({ Texture = T.energyFlip, Color = Effects.RAINBOW, Lifetime = NumberRange.new(1.2), LightEmission = 0.3,
					Brightness = 2.5, Size = seq({ { 0, 2 }, { 0.2, 13 * scale }, { 0.7, 11 * scale }, { 1, 0 } }), RotSpeed = NumberRange.new(120) },
					Enum.ParticleFlipbookMode.Loop, 20))
			end
			burst("Flames", 16, flip({ Texture = T.flameFlip, Color = fire, Lifetime = NumberRange.new(0.7, 1), LightEmission = 0.25, Brightness = 2.5,
				Speed = NumberRange.new(8, 14), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(70, 70), Drag = 4,
				Acceleration = Vector3.new(0, 10, 0), Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
				Size = seq({ { 0, 2 }, { 0.5, 4.5 }, { 1, 2 } }) }, Enum.ParticleFlipbookMode.OneShot), ground)
		end
		if kind == "tier" then
			flatRing("TierRing", ColorSequence.new(Effects.GOLD), 4, 18, 1, 260, nil, ground)
		end
	end
	if fiery or kind == "win" then
		-- a shower of gold coins (pre-coloured texture)
		burst("Coins", if kind == "supreme" then 50 elseif fiery then 30 else 22, { Texture = T.coin, Color = ColorSequence.new(Color3.new(1, 1, 1)),
			LightEmission = 0.3, Brightness = 1.2, Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(14, 24),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -45, 0),
			Size = NumberSequence.new(0.9), RotSpeed = NumberRange.new(-200, 200), Rotation = NumberRange.new(0, 360) }, nil, 0.1)
	end
	if kind == "mythic" then
		tint = Effects.MYTHIC
	elseif kind == "supreme" then
		tint = Color3.fromRGB(255, 230, 255)
	end
	local flash = Instance.new("PointLight")
	flash.Color = firstColor(tint)
	flash.Range = 16 * scale
	flash.Brightness = 1.2
	flash.Shadows = false
	flash.Parent = holder
	TweenService:Create(flash, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	Debris:AddItem(holder, 3.5)
end

-- ---------------------------------------------------------------------------------------------- ambient
-- Small looping sparkle set on a part / attachment (part emitters fill the part's volume). `scale` ~ size of
-- the thing it decorates in studs / 4. Every emitter is named Fx* and tagged FxAmbient.
function Effects.ambient(parent: Instance, theme: string, color: (Color3 | ColorSequence)?, scale: number?): { ParticleEmitter }
	local s = scale or 1
	local made = {}
	local function add(name: string, props: { [string]: any })
		local e = emitter(parent, "Fx" .. name, props)
		if parent:IsA("BasePart") then
			-- emit from the part's skin, outwards (from inside an opaque egg shell nothing shows)
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		end
		e:SetAttribute("FxAmbient", true)
		table.insert(made, e)
	end
	local tint = colorOf(color or (if theme == "ice" then Effects.ICE elseif theme == "fire" then Effects.FIRE
		elseif theme == "energy" then Effects.ENERGY else Effects.GOLD))
	-- every theme: 4-point star glints + glowing motes
	add("Glints", { Texture = T.star, Color = tint, Rate = 2.5, Lifetime = NumberRange.new(0.5, 0.8), Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 1.6 * s }, { 1, 0 } }), LightEmission = 0.3, Brightness = 2 })
	add("Motes", { Texture = T.ember, Color = tint, Rate = 5, Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 1, 0), Size = seq({ { 0, 0 }, { 0.25, 0.35 * s }, { 1, 0 } }),
		LightEmission = 0.25, Brightness = 2 })
	if theme == "ice" then
		add("Slash", { Texture = T.slashArc, Color = tint, Rate = 0.8, Lifetime = NumberRange.new(0.35), Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(260), Size = seq({ { 0, 2 * s }, { 1, 4 * s } }), Transparency = seq({ { 0, 1 }, { 0.2, 0 }, { 1, 1 } }),
			LightEmission = 0.25, Brightness = 2.5 })
	elseif theme == "fire" then
		add("Flames", flip({ Texture = T.flameFlip, Color = tint, Rate = 3, Lifetime = NumberRange.new(0.7, 1), Speed = NumberRange.new(1, 2),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 3, 0),
			Orientation = Enum.ParticleOrientation.FacingCameraWorldUp, Size = seq({ { 0, 0.6 * s }, { 0.5, 1.4 * s }, { 1, 0.6 * s } }),
			LightEmission = 0.25, Brightness = 2 }, Enum.ParticleFlipbookMode.OneShot))
	elseif theme == "energy" then
		add("Orb", flip({ Texture = T.energyFlip, Color = tint, Rate = 0.6, Lifetime = NumberRange.new(1.6), Size = NumberSequence.new(2.5 * s),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.4 }, { 0.7, 0.4 }, { 1, 1 } }), LightEmission = 0.25, Brightness = 2 },
			Enum.ParticleFlipbookMode.Loop, 18))
		add("Specks", { Texture = T.speck, Color = DARK, Rate = 4, Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0.25 * s }, { 1, 0 } }), LightEmission = 0, Brightness = 1 })
	end
	return made
end

-- ---------------------------------------------------------------------------------------------- GUI
-- GUI version for pop-ups: everything is parented to `parent` (a ScreenGui) at `position`, drawn at ZIndex `z`
-- (keep it under the pop-up's own ZIndex) and cleaned up after `seconds`.
function Effects.guiBurst(parent: Instance, position: UDim2, px: number, color: Color3, seconds: number, z: number)
	local holder = Instance.new("Frame")
	holder.Name = "FxBurst"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = position
	holder.Size = UDim2.fromOffset(px, px)
	holder.ZIndex = z
	holder.Parent = parent
	local function image(texture: string, tint: Color3, transparency: number, scale: number, time: number?): ImageLabel
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.Size = UDim2.fromScale(0, 0)
		img.Image = texture
		img.ImageColor3 = tint
		img.ImageTransparency = transparency
		img.ZIndex = z
		img.Parent = holder
		TweenService:Create(img, TweenInfo.new(time or 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(scale, scale) }):Play()
		return img
	end
	local glow = image(T.glow, color, 0.3, 0.8)
	local ring = image(T.slashRing, color, 0.05, 1)
	local ring2 = image(T.slashRing, Color3.new(1, 1, 1), 0.35, 0.72)
	local star = image(T.star, Color3.new(1, 1, 1), 0, 1.25, 0.25)
	task.delay(0.3, function()
		TweenService:Create(star, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(0.7, 0.7), ImageColor3 = color }):Play()
	end)
	local t0 = os.clock()
	local spin = RunService.RenderStepped:Connect(function(dt)
		ring.Rotation += dt * 160
		ring2.Rotation -= dt * 230
		star.Rotation = math.sin((os.clock() - t0) * 2) * 6
	end)
	for i = 1, 12 do
		task.delay(i / 12 * seconds * 0.7, function()
			if not holder.Parent then
				return
			end
			local s = image(if i % 3 == 0 then T.slashArc else T.star, color, 0, 0, 0.2)
			local angle = math.random() * math.pi * 2
			local r = 0.22 + math.random() * 0.22
			s.Position = UDim2.fromScale(0.5 + math.cos(angle) * r, 0.5 + math.sin(angle) * r)
			s.Rotation = if i % 3 == 0 then math.deg(angle) + 90 else 0
			local size = if i % 3 == 0 then 0.3 else 0.14 + math.random() * 0.08
			TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromScale(size, size) }):Play()
			task.delay(0.3, function()
				TweenService:Create(s, TweenInfo.new(0.3), { Size = UDim2.fromScale(0, 0), ImageTransparency = 1 }):Play()
			end)
		end)
	end
	task.delay(seconds, function()
		for _, img in { glow, ring, ring2, star } do
			TweenService:Create(img, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
		end
		task.wait(0.35)
		spin:Disconnect()
		holder:Destroy()
	end)
end

return Effects
