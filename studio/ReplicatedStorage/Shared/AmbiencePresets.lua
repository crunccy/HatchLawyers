--!strict
-- Shared.AmbiencePresets (2026-10-20, crnuch's world-ambience overhaul): the look of each boss zone, read by
-- StarterPlayerScripts.Ambience (the one controller - client only, nothing replicates). Data only.
-- A preset only lists what it changes; everything else stays as the place's own Lighting (captured when the client
-- starts = the "Default" look the hub keeps). Groups:
--   Lighting   Lighting properties (Ambient, OutdoorAmbient, Brightness, ColorShift_Top/Bottom, ExposureCompensation,
--              EnvironmentDiffuseScale / SpecularScale, ClockTime)
--   Atmosphere Lighting.Atmosphere (Density, Offset, Color, Decay, Glare, Haze) - the depth fog
--   Grade      the controller's own ColorCorrectionEffect (Brightness, Contrast, Saturation, TintColor)
--   Bloom      the place's BloomEffect (Intensity, Size, Threshold)
--   SunRays    the controller's own SunRaysEffect (Intensity, Spread)
--   Layers     floating ambient particles. Where:
--                "air"         a box that follows the player (Box = its size) - the motes you always see
--                "vegetation"  "water"  "rock"  "landmark"   boxes on the zone's own geometry, found by name
--                              (Find), clustered into anchors; only the nearest few near the camera emit
--              Above = {lo, hi}: the box spans that far above the anchor's top; Ground = {lo, hi}: above the zone's
--              floor; neither = the anchor's own bounds (a tree canopy). Grow = studs added round the footprint.
--              Rate = particles / s (an anchor's rate grows with its footprint), Low = rate x on the Low profile
--              (0 = off on Low). Size / Speed / Lifetime / RotSpeed = {min, max}. Opacity = peak (0..1).
--              Twinkle = flickers (glints, fireflies). Accel / Drag = drift. Emission <= 0.3 (CLAUDE.md effects rule).
--   Glows      soft PointLights on anchors (High only): Where, Only, Color, Brightness, Range, Lift, Pulse = seconds
--              per slow breath (0 = steady; never a strobe)
--   Find       extra name words for a kind in this zone, e.g. Find = { landmark = { "statictv" } }
--   Sounds     3D loops from Shared.Sfx (ids already licensed there - never new ids) on the nearest anchors of a kind
--   BossDip    particle rates x this while the zone's boss winds up / attacks (warnings always read first)
-- Rules (crnuch's brief): gameplay area crisp, mid-distance soft, far scenery into a themed haze, never washed out;
-- particles drift, never burst; boss warnings, shockwaves, eggs, dropped eggs and players always stand out.

local P = {}

local rgb = Color3.fromRGB

-- new particle textures (tools/ambience_textures.py, uploaded from crnuch's Studio 2026-10-20); a missing one falls
-- back to the named Effects texture
P.TEXTURES = {
	leaf = "rbxassetid://76178310925290",
	petal = "rbxassetid://105223361263918",
	paper = "rbxassetid://94602324300971",
	mist = "rbxassetid://127394798188063",
	square = "rbxassetid://81592498778194",
	bubble = "rbxassetid://126450061639497",
} :: { [string]: string? }
P.FALLBACK = { leaf = "dot", petal = "dot", paper = "dot", mist = "wisp", square = "speck", bubble = "dot" }

-- what each anchor kind is found by (case-insensitive substrings of a part's name or its model's names);
-- Exclude wins. A zone can add its own words with Find = { vegetation = { ... } } in its preset.
P.FIND = {
	vegetation = { "leaf", "leaves", "canopy", "foliage", "bush", "hedge", "tree", "palm", "frond", "blossom", "flower", "fern", "shrub", "vine" },
	water = { "water", "pond", "pool", "puddle", "lake", "fall", "fountain", "stream", "river", "goo", "plasma", "soda", "spray", "ocean", "surf" },
	rock = { "rock", "boulder", "cliff", "stone", "crag", "outcrop" },
	landmark = { "statue", "fountain", "gate", "lamp", "lantern", "monument", "sign", "tower", "crystal", "portal" },
	exclude = { "floor", "chevron", "arrival", "eggspot", "spawn", "oddsboard", "hitbox", "returnhome", "trigger", "egg", "trunk", "stem", "pot" }, -- (a part's own name)
}

-- the two quality profiles (the controller picks Low on phones / low graphics; player attribute AmbienceQuality
-- overrides). Gameplay warnings are never touched by either.
P.QUALITY = {
	High = { Rate = 1, Anchors = 8, Radius = 170, AirBox = 1, Glows = true, SunRays = true },
	Low = { Rate = 0.45, Anchors = 3, Radius = 110, AirBox = 0.75, Glows = false, SunRays = false },
}

P.FADE = 3 -- seconds to cross-fade between two zones' looks
P.RESUME_FADE = 1.2 -- after a travel / hatch stage gave the lighting back

P.Zones = {}

------------------------------------------------------------------ PET PARK (the prototype - crnuch reviews this one first)
-- soft green woodland haze, pollen, fireflies, drifting leaves + petals, mist near water. Don't hide the Bulldog.
P.Zones.PetPark = {
	Lighting = {
		-- (barely greener than the place's own: a green ambient turned the orange path yellow - the green lives in the haze)
		Ambient = rgb(98, 104, 98),
		OutdoorAmbient = rgb(126, 134, 122),
		ColorShift_Top = rgb(255, 232, 196),
	},
	Atmosphere = {
		Density = 0.38,
		Offset = 0.18,
		Color = rgb(196, 226, 156),
		Decay = rgb(104, 150, 84),
		Glare = 0.15,
		Haze = 1.2,
	},
	Grade = { Brightness = 0, Contrast = 0.03, Saturation = 0.03, TintColor = rgb(252, 255, 248) },
	Bloom = { Intensity = 0.45, Size = 28, Threshold = 1.75 },
	SunRays = { Intensity = 0.05, Spread = 0.6 },
	BossDip = 0.35,
	Layers = {
		{ -- pollen: tiny pale motes everywhere, slow
			Name = "Pollen", Where = "air", Box = Vector3.new(96, 30, 96), Texture = "dot",
			Color = { rgb(255, 250, 196), rgb(230, 255, 190) }, Size = { 0.14, 0.3 }, Opacity = 0.75,
			Lifetime = { 9, 15 }, Rate = 16, Speed = { 0.2, 0.7 }, Accel = Vector3.new(0.12, 0.04, 0.06), Drag = 0.4,
			Emission = 0.25, Influence = 0.4,
		},
		{ -- a few leaves drifting through the air (the reference's big soft leaves - kept small and sparse)
			Name = "AirLeaves", Where = "air", Box = Vector3.new(90, 26, 90), Texture = "leaf",
			Color = { rgb(120, 196, 64), rgb(168, 214, 80) }, Size = { 0.5, 0.95 }, Opacity = 0.92,
			Lifetime = { 7, 11 }, Rate = 3.5, Speed = { 0.6, 1.6 }, Accel = Vector3.new(1.1, -0.9, 0.4), Drag = 0.7,
			RotSpeed = { -70, 70 }, Emission = 0, Influence = 0.85, Low = 0.5,
		},
		{ -- leaves falling out of the trees
			Name = "Leaves", Where = "vegetation", Grow = 2, Texture = "leaf",
			Color = { rgb(104, 184, 52), rgb(150, 210, 70), rgb(196, 214, 84) }, Size = { 0.45, 0.85 }, Opacity = 0.95,
			Lifetime = { 6, 9 }, Rate = 2, Speed = { 0.4, 1.2 }, Accel = Vector3.new(0.9, -1.4, 0.3), Drag = 0.8,
			RotSpeed = { -90, 90 }, Emission = 0, Influence = 0.9,
		},
		{ -- blossom petals by the blossom trees / flower beds
			Name = "Petals", Where = "vegetation", Only = { "blossom", "flower", "cherry", "pink" }, Grow = 3, Texture = "petal",
			Color = { rgb(255, 196, 222), rgb(255, 232, 240) }, Size = { 0.3, 0.55 }, Opacity = 0.95,
			Lifetime = { 6, 10 }, Rate = 1.4, Speed = { 0.3, 1 }, Accel = Vector3.new(0.7, -0.8, 0.5), Drag = 0.8,
			RotSpeed = { -120, 120 }, Emission = 0.05, Influence = 0.8,
		},
		{ -- fireflies: warm glints low under the trees, flickering
			Name = "Fireflies", Where = "vegetation", Ground = { 1, 7 }, Grow = 6, Texture = "glow",
			Color = { rgb(236, 255, 140), rgb(255, 236, 120) }, Size = { 0.25, 0.42 }, Opacity = 0.85, Twinkle = true,
			Lifetime = { 4, 7 }, Rate = 1.2, Speed = { 0.3, 0.9 }, Accel = Vector3.new(0, 0.15, 0), Drag = 0.6,
			Emission = 0.3, Influence = 0.1, Low = 0.5,
		},
		{ -- soft mist hanging just over the water
			Name = "WaterMist", Where = "water", Above = { 0.2, 3 }, Grow = 4, Texture = "mist",
			Color = { rgb(232, 248, 236), rgb(214, 238, 222) }, Size = { 6, 11 }, Opacity = 0.22,
			Lifetime = { 7, 11 }, Rate = 0.9, Speed = { 0.2, 0.6 }, Accel = Vector3.new(0.15, 0.05, 0), Drag = 0.3,
			RotSpeed = { -10, 10 }, Emission = 0, Influence = 1, Low = 0.5,
		},
		{ -- glints off the water
			Name = "WaterGlints", Where = "water", Above = { 0.1, 1.2 }, Texture = "twinkle",
			Color = { rgb(255, 255, 255), rgb(220, 250, 255) }, Size = { 0.25, 0.5 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 0.8, 1.6 }, Rate = 1.6, Speed = { 0, 0.1 }, Emission = 0.3, Influence = 0, Low = 0.5,
		},
	},
	Sounds = {
		{ Name = "fountain", Where = "water", Volume = 0.35, Range = 60, Max = 1 },
	},
}

------------------------------------------------------------------ BRIEFCASE BAY (the first world: warm, golden, the clearest air)
P.Zones.BriefcaseBay = {
	Lighting = { Ambient = rgb(98, 96, 100), OutdoorAmbient = rgb(130, 127, 130), ColorShift_Top = rgb(255, 228, 180) },
	Atmosphere = { Density = 0.3, Offset = 0.26, Color = rgb(250, 230, 192), Decay = rgb(214, 172, 112), Glare = 0.25, Haze = 1 },
	Grade = { Brightness = 0, Contrast = 0.03, Saturation = 0.04, TintColor = rgb(255, 251, 242) },
	Bloom = { Intensity = 0.45, Size = 28, Threshold = 1.75 },
	SunRays = { Intensity = 0.07, Spread = 0.5 },
	BossDip = 0.35,
	Find = { landmark = { "paper", "fileboxes", "cabinet", "briefcase", "watercooler", "coffee" } },
	Layers = {
		{ -- warm dust motes in the sun
			Name = "Dust", Where = "air", Box = Vector3.new(96, 28, 96), Texture = "dot",
			Color = { rgb(255, 236, 190), rgb(255, 216, 150) }, Size = { 0.12, 0.26 }, Opacity = 0.7,
			Lifetime = { 9, 14 }, Rate = 14, Speed = { 0.15, 0.5 }, Accel = Vector3.new(0.08, 0.03, 0), Drag = 0.4,
			Emission = 0.25, Influence = 0.45,
		},
		{ -- paper scraps drifting by
			Name = "Papers", Where = "air", Box = Vector3.new(90, 24, 90), Texture = "paper",
			Color = { rgb(255, 252, 242), rgb(246, 238, 214) }, Size = { 0.5, 0.85 }, Opacity = 0.95,
			Lifetime = { 7, 11 }, Rate = 1.6, Speed = { 0.5, 1.4 }, Accel = Vector3.new(1, -0.7, 0.4), Drag = 0.8,
			RotSpeed = { -80, 80 }, Emission = 0, Influence = 0.9, Low = 0.5,
		},
		{ -- gold glints catching the light
			Name = "GoldGlints", Where = "air", Box = Vector3.new(80, 20, 80), Texture = "twinkle",
			Color = { rgb(255, 214, 100), rgb(255, 240, 170) }, Size = { 0.25, 0.45 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 1.5, 3 }, Rate = 2.4, Speed = { 0, 0.2 }, Emission = 0.3, Influence = 0.2, Low = 0.5,
		},
		{ -- papers fluttering up off the file boxes, cabinets and briefcases
			Name = "Flutter", Where = "landmark", Only = { "paper", "fileboxes", "cabinet", "briefcase" }, Above = { 0, 4 }, Grow = 2,
			Texture = "paper", Color = { rgb(255, 252, 242) }, Size = { 0.4, 0.7 }, Opacity = 0.95,
			Lifetime = { 4, 7 }, Rate = 0.8, Speed = { 0.6, 1.4 }, Accel = Vector3.new(0.6, -0.5, 0.3), Drag = 0.9,
			RotSpeed = { -120, 120 }, Emission = 0, Influence = 0.9, Low = 0.5,
		},
		{ -- blossom petals by the blossom trees
			Name = "Petals", Where = "vegetation", Only = { "blossom" }, Grow = 3, Texture = "petal",
			Color = { rgb(255, 196, 222), rgb(255, 232, 240) }, Size = { 0.3, 0.55 }, Opacity = 0.95,
			Lifetime = { 6, 10 }, Rate = 1.2, Speed = { 0.3, 1 }, Accel = Vector3.new(0.7, -0.8, 0.5), Drag = 0.8,
			RotSpeed = { -120, 120 }, Emission = 0.05, Influence = 0.8,
		},
		{ -- glints off the island's water
			Name = "WaterGlints", Where = "water", Above = { 0.1, 1.2 }, Texture = "twinkle",
			Color = { rgb(255, 250, 230) }, Size = { 0.25, 0.5 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 0.8, 1.6 }, Rate = 1.4, Speed = { 0, 0.1 }, Emission = 0.3, Influence = 0, Low = 0.5,
		},
	},
	Sounds = { { Name = "waves", Where = "water", Volume = 0.35, Range = 80, Max = 1 } },
}

------------------------------------------------------------------ BRAINROT BOULEVARD (purple / magenta + cyan, neon motes, glitch specks)
P.Zones.BrainrotBoulevard = {
	Lighting = { Ambient = rgb(100, 94, 108), OutdoorAmbient = rgb(130, 122, 140), ColorShift_Top = rgb(240, 214, 255) },
	Atmosphere = { Density = 0.4, Offset = 0.16, Color = rgb(232, 186, 240), Decay = rgb(112, 118, 222), Glare = 0.1, Haze = 1.7 },
	Grade = { Brightness = 0, Contrast = 0.05, Saturation = 0.07, TintColor = rgb(252, 246, 255) },
	Bloom = { Intensity = 0.55, Size = 28, Threshold = 1.65 },
	BossDip = 0.35,
	Find = { landmark = { "statictv", "mushroom", "jellycubes", "lollipop", "eyestalk", "giantgavel" } },
	Layers = {
		{ -- neon motes, magenta to cyan
			Name = "NeonMotes", Where = "air", Box = Vector3.new(96, 30, 96), Texture = "glow",
			Color = { rgb(255, 120, 230), rgb(150, 140, 255), rgb(110, 236, 255) }, Size = { 0.2, 0.38 }, Opacity = 0.7,
			Lifetime = { 8, 13 }, Rate = 11, Speed = { 0.2, 0.6 }, Drag = 0.4, Emission = 0.3, Influence = 0.2,
		},
		{ -- glitchy square specks that blink in and out
			Name = "Glitch", Where = "air", Box = Vector3.new(80, 22, 80), Texture = "square",
			Color = { rgb(255, 90, 220), rgb(90, 230, 255), rgb(255, 255, 255) }, Size = { 0.18, 0.34 }, Opacity = 0.85, Twinkle = true,
			Lifetime = { 1.5, 3 }, Rate = 3, Speed = { 0, 0.3 }, Emission = 0.2, Influence = 0.3, Low = 0.5,
		},
		{ -- static off the TVs
			Name = "Static", Where = "landmark", Only = { "statictv" }, Grow = 1, Texture = "square",
			Color = { rgb(255, 255, 255), rgb(120, 236, 255) }, Size = { 0.16, 0.3 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 0.6, 1.4 }, Rate = 2.5, Speed = { 0.2, 0.8 }, Emission = 0.3, Influence = 0.1, Low = 0.5,
		},
		{ -- spores drifting up off the mushrooms + jelly
			Name = "Spores", Where = "landmark", Only = { "mushroom", "jelly", "lollipop" }, Above = { -1, 3 }, Grow = 2, Texture = "dot",
			Color = { rgb(255, 150, 236), rgb(190, 160, 255) }, Size = { 0.2, 0.35 }, Opacity = 0.8,
			Lifetime = { 5, 8 }, Rate = 1.2, Speed = { 0.1, 0.4 }, Accel = Vector3.new(0, 0.35, 0), Drag = 0.5, Emission = 0.3, Influence = 0.2,
		},
		{ -- blossom petals (the pink trees)
			Name = "Petals", Where = "vegetation", Only = { "blossom", "weirdtree" }, Grow = 3, Texture = "petal",
			Color = { rgb(255, 160, 230), rgb(236, 200, 255) }, Size = { 0.3, 0.55 }, Opacity = 0.95,
			Lifetime = { 6, 10 }, Rate = 1.2, Speed = { 0.3, 1 }, Accel = Vector3.new(0.7, -0.8, 0.5), Drag = 0.8,
			RotSpeed = { -120, 120 }, Emission = 0.05, Influence = 0.8,
		},
		{ -- goo pools bubble a little (islands)
			Name = "GooMist", Where = "water", Above = { 0.2, 2.5 }, Grow = 3, Texture = "mist",
			Color = { rgb(236, 190, 255), rgb(190, 236, 255) }, Size = { 5, 9 }, Opacity = 0.2,
			Lifetime = { 6, 10 }, Rate = 0.8, Speed = { 0.2, 0.5 }, Accel = Vector3.new(0, 0.08, 0), Drag = 0.3, Emission = 0.1, Influence = 0.8, Low = 0.5,
		},
	},
	-- a soft breathing glow on the weird props (4 s per breath - never a strobe)
	Glows = {
		{ Where = "landmark", Only = { "statictv" }, Color = rgb(120, 230, 255), Brightness = 1.2, Range = 14, Lift = 1, Pulse = 4 },
		{ Where = "landmark", Only = { "mushroom", "jelly" }, Color = rgb(255, 120, 230), Brightness = 1, Range = 12, Lift = 1, Pulse = 5 },
	},
}

------------------------------------------------------------------ FOOD COURT (warm golden-orange, crumbs, steam, sparkles; the roll lane stays clear)
P.Zones.FoodCourt = {
	Lighting = { Ambient = rgb(102, 96, 94), OutdoorAmbient = rgb(134, 126, 122), ColorShift_Top = rgb(255, 222, 176) },
	Atmosphere = { Density = 0.35, Offset = 0.2, Color = rgb(252, 214, 168), Decay = rgb(228, 140, 80), Glare = 0.3, Haze = 1.3 },
	Grade = { Brightness = 0, Contrast = 0.04, Saturation = 0.06, TintColor = rgb(255, 248, 238) },
	Bloom = { Intensity = 0.5, Size = 28, Threshold = 1.7 },
	SunRays = { Intensity = 0.07, Spread = 0.5 },
	BossDip = 0.3,
	-- (only the wall-side food: the floor clutter is Crumb / Fry, so nothing is anchored in Big Cheese's roll lane)
	Find = { landmark = { "burger", "pizza", "fries", "donut", "icecream", "soda", "ketchup" } },
	Layers = {
		{ -- warm dust
			Name = "WarmDust", Where = "air", Box = Vector3.new(96, 28, 96), Texture = "dot",
			Color = { rgb(255, 214, 150), rgb(255, 190, 120) }, Size = { 0.12, 0.26 }, Opacity = 0.65,
			Lifetime = { 9, 14 }, Rate = 12, Speed = { 0.15, 0.5 }, Accel = Vector3.new(0, 0.05, 0), Drag = 0.4, Emission = 0.25, Influence = 0.45,
		},
		{ -- crumbs tumbling down
			Name = "Crumbs", Where = "air", Box = Vector3.new(80, 20, 80), Texture = "square",
			Color = { rgb(226, 170, 96), rgb(246, 210, 140) }, Size = { 0.14, 0.26 }, Opacity = 0.95,
			Lifetime = { 6, 10 }, Rate = 2, Speed = { 0.2, 0.6 }, Accel = Vector3.new(0.3, -0.5, 0), Drag = 0.7, RotSpeed = { -60, 60 },
			Emission = 0, Influence = 0.9, Low = 0.5,
		},
		{ -- sugar sparkles
			Name = "Sparkles", Where = "air", Box = Vector3.new(80, 20, 80), Texture = "twinkle",
			Color = { rgb(255, 236, 170), rgb(255, 255, 230) }, Size = { 0.22, 0.4 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 1.5, 3 }, Rate = 2, Speed = { 0, 0.2 }, Emission = 0.3, Influence = 0.2, Low = 0.5,
		},
		{ -- steam off the hot food
			Name = "Steam", Where = "landmark", Only = { "burger", "pizza", "fries", "donut" }, Above = { 0, 3 }, Texture = "mist",
			Color = { rgb(255, 250, 244) }, Size = { 2.5, 5 }, Opacity = 0.22,
			Lifetime = { 3, 5 }, Rate = 0.9, Speed = { 0.4, 0.9 }, Accel = Vector3.new(0.1, 0.6, 0), Drag = 0.6, RotSpeed = { -20, 20 },
			Emission = 0, Influence = 0.9, Low = 0.5,
		},
		{ -- fizz rising off the sodas
			Name = "Fizz", Where = "landmark", Only = { "soda" }, Above = { -1, 2 }, Texture = "bubble",
			Color = { rgb(255, 255, 255), rgb(255, 230, 200) }, Size = { 0.15, 0.3 }, Opacity = 0.85,
			Lifetime = { 2, 3.5 }, Rate = 2, Speed = { 0.2, 0.5 }, Accel = Vector3.new(0, 1.1, 0), Drag = 0.4, Emission = 0.1, Influence = 0.6, Low = 0.5,
		},
		{ -- warm mist over the soda / chocolate pools (islands)
			Name = "PoolSteam", Where = "water", Above = { 0.2, 2.5 }, Grow = 3, Texture = "mist",
			Color = { rgb(255, 236, 214) }, Size = { 5, 9 }, Opacity = 0.18,
			Lifetime = { 6, 10 }, Rate = 0.8, Speed = { 0.2, 0.5 }, Accel = Vector3.new(0, 0.12, 0), Drag = 0.3, Emission = 0, Influence = 1, Low = 0.5,
		},
	},
}

------------------------------------------------------------------ OCEAN SHORE (bright tropical, turquoise, coastal haze, sea spray)
P.Zones.OceanShore = {
	Lighting = { Ambient = rgb(92, 100, 108), OutdoorAmbient = rgb(120, 134, 142), ColorShift_Top = rgb(240, 248, 255) },
	Atmosphere = { Density = 0.36, Offset = 0.2, Color = rgb(176, 228, 240), Decay = rgb(70, 150, 210), Glare = 0.45, Haze = 1.4 },
	Grade = { Brightness = 0, Contrast = 0.04, Saturation = 0.07, TintColor = rgb(246, 253, 255) },
	Bloom = { Intensity = 0.5, Size = 28, Threshold = 1.7 },
	SunRays = { Intensity = 0.09, Spread = 0.5 },
	BossDip = 0.3,
	Find = { rock = { "coral" }, vegetation = { "palmtree" } },
	Layers = {
		{ -- salt mist motes on the sea breeze
			Name = "SaltMist", Where = "air", Box = Vector3.new(96, 28, 96), Texture = "dot",
			Color = { rgb(236, 252, 255), rgb(200, 240, 250) }, Size = { 0.12, 0.26 }, Opacity = 0.6,
			Lifetime = { 8, 13 }, Rate = 13, Speed = { 0.2, 0.6 }, Accel = Vector3.new(0.25, 0.02, 0), Drag = 0.4, Emission = 0.25, Influence = 0.45,
		},
		{ -- a few sparkles off the sun
			Name = "SunGlints", Where = "air", Box = Vector3.new(80, 18, 80), Texture = "twinkle",
			Color = { rgb(255, 255, 240), rgb(210, 250, 255) }, Size = { 0.22, 0.4 }, Opacity = 0.85, Twinkle = true,
			Lifetime = { 1.2, 2.5 }, Rate = 1.6, Speed = { 0, 0.2 }, Emission = 0.3, Influence = 0.1, Low = 0.5,
		},
		{ -- spray hanging over the water / puddles / falls
			Name = "Spray", Where = "water", Above = { 0.2, 2.5 }, Grow = 3, Texture = "mist",
			Color = { rgb(240, 252, 255) }, Size = { 4, 8 }, Opacity = 0.2,
			Lifetime = { 4, 7 }, Rate = 1, Speed = { 0.3, 0.9 }, Accel = Vector3.new(0.3, 0.1, 0), Drag = 0.3, Emission = 0, Influence = 1, Low = 0.5,
		},
		{ -- glints dancing on the water
			Name = "WaterGlints", Where = "water", Above = { 0.1, 1.2 }, Texture = "twinkle",
			Color = { rgb(255, 255, 255), rgb(200, 245, 255) }, Size = { 0.25, 0.5 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 0.8, 1.6 }, Rate = 1.8, Speed = { 0, 0.1 }, Emission = 0.3, Influence = 0, Low = 0.5,
		},
		{ -- bubbles rising off the coral + rocks
			Name = "Bubbles", Where = "rock", Only = { "coral" }, Above = { -1, 2 }, Grow = 1, Texture = "bubble",
			Color = { rgb(220, 250, 255) }, Size = { 0.2, 0.4 }, Opacity = 0.8,
			Lifetime = { 2.5, 4 }, Rate = 1, Speed = { 0.2, 0.4 }, Accel = Vector3.new(0, 0.9, 0), Drag = 0.4, Emission = 0.1, Influence = 0.6, Low = 0.5,
		},
		{ -- sea spray puffs against the rocks (islands' cliffs)
			Name = "RockSpray", Where = "rock", Above = { -2, 1 }, Grow = 2, Texture = "mist",
			Color = { rgb(240, 252, 255) }, Size = { 3, 6 }, Opacity = 0.16,
			Lifetime = { 3, 5 }, Rate = 0.5, Speed = { 0.3, 0.8 }, Accel = Vector3.new(0.2, 0.2, 0), Drag = 0.4, Emission = 0, Influence = 1, Low = 0,
		},
	},
	Sounds = {
		{ Name = "waves", Where = "water", Volume = 0.55, Range = 90, Max = 2 },
		{ Name = "gulls", Where = "air", Volume = 0.45, Range = 200 },
	},
}

------------------------------------------------------------------ SPACE BASE (deep blue / violet haze, cosmic dust, star motes, slow energy, crystal glow)
P.Zones.SpaceBase = {
	-- (no night ClockTime: the place's skybox is a day sky, so the violet comes from a heavy Atmosphere haze instead)
	Lighting = {
		Brightness = 1.9, Ambient = rgb(94, 92, 114), OutdoorAmbient = rgb(118, 114, 148), ColorShift_Top = rgb(210, 220, 255),
		ExposureCompensation = -0.3,
	},
	Atmosphere = { Density = 0.44, Offset = 0.14, Color = rgb(170, 150, 235), Decay = rgb(78, 58, 170), Glare = 0, Haze = 2.4 },
	Grade = { Brightness = 0, Contrast = 0.06, Saturation = 0.04, TintColor = rgb(242, 242, 255) },
	Bloom = { Intensity = 0.6, Size = 30, Threshold = 1.55 },
	BossDip = 0.3,
	Find = { landmark = { "crystals", "glowpebble", "beacon", "rocket", "satellitedish", "alienplant" } },
	Layers = {
		{ -- cosmic dust
			Name = "CosmicDust", Where = "air", Box = Vector3.new(96, 32, 96), Texture = "dot",
			Color = { rgb(196, 204, 255), rgb(222, 184, 255) }, Size = { 0.12, 0.24 }, Opacity = 0.7,
			Lifetime = { 10, 16 }, Rate = 13, Speed = { 0.1, 0.4 }, Drag = 0.3, Emission = 0.3, Influence = 0.25,
		},
		{ -- star motes twinkling
			Name = "StarMotes", Where = "air", Box = Vector3.new(90, 28, 90), Texture = "star",
			Color = { rgb(200, 240, 255), rgb(255, 255, 255) }, Size = { 0.3, 0.5 }, Opacity = 0.85, Twinkle = true,
			Lifetime = { 2, 4 }, Rate = 2.2, Speed = { 0, 0.15 }, Emission = 0.3, Influence = 0.1, Low = 0.5,
		},
		{ -- slow low-gravity energy motes floating up
			Name = "EnergyMotes", Where = "air", Box = Vector3.new(80, 20, 80), Texture = "glow",
			Color = { rgb(110, 240, 255), rgb(170, 130, 255) }, Size = { 0.32, 0.55 }, Opacity = 0.65,
			Lifetime = { 10, 16 }, Rate = 1.8, Speed = { 0.1, 0.3 }, Accel = Vector3.new(0, 0.12, 0), Drag = 0.5, Emission = 0.3, Influence = 0.1, Low = 0.5,
		},
		{ -- sparkles off the crystals
			Name = "CrystalSparks", Where = "landmark", Only = { "crystal", "glowpebble" }, Grow = 1, Texture = "twinkle",
			Color = { rgb(140, 240, 255), rgb(220, 190, 255) }, Size = { 0.25, 0.45 }, Opacity = 0.9, Twinkle = true,
			Lifetime = { 1, 2 }, Rate = 1.5, Speed = { 0.1, 0.4 }, Accel = Vector3.new(0, 0.3, 0), Emission = 0.3, Influence = 0, Low = 0.5,
		},
		{ -- plasma pools steam violet (islands)
			Name = "PlasmaMist", Where = "water", Above = { 0.2, 2.5 }, Grow = 3, Texture = "mist",
			Color = { rgb(190, 170, 255), rgb(150, 230, 255) }, Size = { 5, 9 }, Opacity = 0.2,
			Lifetime = { 6, 10 }, Rate = 0.8, Speed = { 0.2, 0.5 }, Accel = Vector3.new(0, 0.1, 0), Drag = 0.3, Emission = 0.2, Influence = 0.6, Low = 0.5,
		},
	},
	-- the crystals breathe a slow cyan glow (never a strobe)
	Glows = {
		{ Where = "landmark", Only = { "crystal", "beacon" }, Color = rgb(110, 230, 255), Brightness = 1.3, Range = 16, Lift = 1, Pulse = 4.5 },
		{ Where = "rock", Only = { "crystal" }, Color = rgb(170, 140, 255), Brightness = 1.1, Range = 16, Lift = 1, Pulse = 5 },
	},
}

return P
