--!strict
-- EggLook (ReplicatedStorage.Shared.EggLook) - builds every egg the game shows: on the zone floors, loose after a
-- boss hit, in a player's arms, in the incubator and in the hatch.
-- v5 (2026-10-12, mr.robe: "remake ... everything to do with the eggs through blender", "recreate the eggs itself",
-- "i dont like the little balls that protrude out of the eggs"): real meshes made in Blender (tools/blender/eggs_v5.py
-- -> tools/zones/BuildEggsV5.lua -> ReplicatedStorage.EggModels). Every egg shares one smooth shell and wears its own
-- painted texture; flush relief layers (belt, collar, frosting, wave) use the same texture; a few smooth pieces
-- (handle, ears, brain, cream swirl, fin, planet ring) stick out. Golden eggs: the golden texture (gold, a flush
-- lattice + jewelled band), the pieces warmed to gold.
--   EggLook.build(egg, golden?, height?, simple?) -> Model
--     egg     "Briefcase" | "Pet" | "Brainrot" | "Food" | "Ocean" | "Space" (anything else: the Briefcase egg)
--     height  the shell's height in studs (default 3.8)
--     simple  no relief layer (the texture already paints it) - for eggs carried in the arms
--     The model is anchored, without collisions; its pivot is the middle of the egg's bottom; PrimaryPart = "Shell".
--   EggLook.buildHatch(egg, golden?, height?) -> Hatch   the hatch's egg: a finer shell, the 3 crack stages (hidden),
--     the 12 shell chunks (hidden; tools/blender/egg_break.py simulated how they fly) and the pieces, each piece
--     stuck to the chunk it sits on. Shared.HatchFx drives it.
--   EggLook.color(egg, golden?) -> Color3   the egg's main colour (trails, sparks)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(script.Parent:WaitForChild("Formulas")) :: any

local EggLook = {}

local BASE_HEIGHT = 3.8
local GOLD = Color3.fromRGB(255, 200, 40)
local WARM = Color3.fromRGB(255, 232, 150)
local MAIN = { -- (the shell textures' main colours)
	Briefcase = Color3.fromRGB(202, 134, 70),
	Pet = Color3.fromRGB(255, 239, 218),
	Brainrot = Color3.fromRGB(150, 80, 230),
	Food = Color3.fromRGB(255, 152, 198),
	Ocean = Color3.fromRGB(40, 138, 214),
	Space = Color3.fromRGB(90, 60, 200),
}

local lib: Folder? = nil
local function library(): Folder?
	if not lib then
		lib = ReplicatedStorage:WaitForChild("EggModels", 10) :: Folder?
	end
	return lib
end

local function quiet(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
end

local function eggDef(folder: Folder, egg: string): Instance?
	return folder:FindFirstChild(egg) or folder:FindFirstChild("Briefcase")
end

-- the egg's pieces into `m`; returns the texture id and the clones (relief, pieces)
local function dress(m: Model, folder: Folder, egg: string, golden: boolean?, withRelief: boolean): (string, { BasePart }, { BasePart })
	local def = eggDef(folder, egg)
	local tex = ""
	local relief, pieces = {}, {}
	if not def then
		return tex, relief, pieces
	end
	tex = (def:GetAttribute(if golden then "GoldenTexture" else "Texture") :: string?) or ""
	for _, src in def:GetChildren() do
		if not src:IsA("BasePart") then
			continue
		end
		local textured = src:GetAttribute("UsesTexture") == true
		if textured and not withRelief then
			continue
		end
		local c = src:Clone()
		quiet(c)
		if textured and c:IsA("MeshPart") then
			c.TextureID = tex
			table.insert(relief, c)
		else
			if golden and c.Material ~= Enum.Material.Neon then
				c.Color = c.Color:Lerp(WARM, 0.55)
				c.Reflectance = math.max(c.Reflectance, 0.14)
			end
			table.insert(pieces, c)
		end
		c.Parent = m
	end
	return tex, relief, pieces
end

local function fallback(m: Model, egg: string, golden: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = "Shell"
	p.Size = Vector3.new(3, BASE_HEIGHT, 3)
	p.CFrame = CFrame.new(0, BASE_HEIGHT / 2, 0)
	p.Color = EggLook.color(egg, golden)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	quiet(p)
	p.Parent = m
	return p
end

local function finish(m: Model, shell: BasePart, height: number?)
	m.PrimaryPart = shell
	shell.PivotOffset = shell.CFrame:Inverse() -- pivot = the egg's bottom middle (the library stands eggs on the origin)
	local h = height or BASE_HEIGHT
	if math.abs(h - BASE_HEIGHT) > 1e-3 then
		m:ScaleTo(h / BASE_HEIGHT)
	end
end

function EggLook.build(egg: string, golden: boolean?, height: number?, simple: boolean?): Model
	local m = Instance.new("Model")
	m.Name = "Egg"
	local folder = library()
	local src = folder and folder:FindFirstChild("Shell")
	if not folder or not src then
		finish(m, fallback(m, egg, golden), height)
		return m
	end
	local shell = (src :: BasePart):Clone()
	shell.Name = "Shell"
	quiet(shell)
	shell.Parent = m
	local tex = dress(m, folder :: Folder, egg, golden, not simple)
	if shell:IsA("MeshPart") then
		shell.TextureID = tex
	end
	if golden then
		shell.Reflectance = 0.16
	end
	finish(m, shell, height)
	return m
end

export type Hatch = {
	model: Model,
	shell: BasePart,
	relief: { BasePart },
	pieces: { BasePart },
	cracks: { BasePart }, -- A, B, C
	chunks: { BasePart },
	rest: { [BasePart]: CFrame }, -- each chunk's resting CFrame in egg space (unscaled)
	stuck: { [BasePart]: { chunk: BasePart, offset: CFrame } }, -- pieces riding on chunks (offsets unscaled)
	scale: number,
	egg: string,
	golden: boolean,
}

function EggLook.buildHatch(egg: string, golden: boolean?, height: number?): Hatch?
	local folder = library()
	local src = folder and folder:FindFirstChild("HatchShell")
	if not folder or not src then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = "HatchEgg"
	local shell = (src :: BasePart):Clone()
	shell.Name = "Shell"
	quiet(shell)
	shell.Parent = m
	local tex, relief, pieces = dress(m, folder :: Folder, egg, golden, true)
	if shell:IsA("MeshPart") then
		shell.TextureID = tex
	end
	if golden then
		shell.Reflectance = 0.16
	end
	local cracks = {}
	local crackFolder = (folder :: Folder):FindFirstChild("Cracks")
	for _, n in { "CrackA", "CrackB", "CrackC" } do
		local c = crackFolder and crackFolder:FindFirstChild(n)
		if c and c:IsA("BasePart") then
			local cc = c:Clone()
			quiet(cc)
			cc.Transparency = 1
			cc.CastShadow = false
			cc.Parent = m
			table.insert(cracks, cc)
		end
	end
	local chunks, rest = {}, {}
	local chunkFolder = (folder :: Folder):FindFirstChild("Chunks")
	if chunkFolder then
		local list = chunkFolder:GetChildren()
		table.sort(list, function(a, b)
			return (tonumber(string.match(a.Name, "%d+")) or 0) < (tonumber(string.match(b.Name, "%d+")) or 0)
		end)
		for _, c in list do
			if c:IsA("BasePart") then
				local cc = c:Clone()
				quiet(cc)
				cc.Transparency = 1
				if cc:IsA("MeshPart") then
					cc.TextureID = tex
				end
				if golden then
					cc.Reflectance = 0.16
				end
				cc.Parent = m
				table.insert(chunks, cc)
				rest[cc] = cc.CFrame
			end
		end
	end
	-- each piece rides on the nearest chunk when the shell breaks
	local stuck = {}
	for _, p in pieces do
		local best, bestD = nil, math.huge
		for _, c in chunks do
			local d = (c.Position - p.Position).Magnitude
			if d < bestD then
				best, bestD = c, d
			end
		end
		if best then
			stuck[p] = { chunk = best, offset = best.CFrame:ToObjectSpace(p.CFrame) }
		end
	end
	local h = height or BASE_HEIGHT
	finish(m, shell, h)
	return {
		model = m,
		shell = shell,
		relief = relief,
		pieces = pieces,
		cracks = cracks,
		chunks = chunks,
		rest = rest,
		stuck = stuck,
		scale = h / BASE_HEIGHT,
		egg = egg,
		golden = golden == true,
	}
end

function EggLook.color(egg: string, golden: boolean?): Color3
	if golden then
		return GOLD
	end
	if MAIN[egg] then
		return MAIN[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.fromRGB(245, 200, 70)
end

return EggLook
