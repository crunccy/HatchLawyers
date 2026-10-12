--!strict
-- EggLook (ReplicatedStorage.Shared.EggLook, 2026-10-12): builds the eggs the game shows - on the zone floors, loose
-- after a boss hit, in a player's arms, in the hatch - from ReplicatedStorage.EggModels (made in Blender:
-- tools/blender/eggs.py -> tools/zones/BuildEggs.lua). User: "make the eggs look different and more detailed, like
-- the reference video, keeping the cartoonish look".
--   EggLook.build(egg, golden?, height?, simple?) -> Model
--     egg     the egg id ("Briefcase", "Pet", "Brainrot", "Food", "Ocean", "Space"); anything else gets the
--             Briefcase shape in that egg's colour (Formulas.themedEgg)
--     golden  a gold shell, its decorations warmed to gold, plus the GoldenKit (lattice, jewelled band, crown)
--     height  the shell's height in studs (default 3.8; the crown / antenna / cherry stick out above it)
--     simple  leave out the tiny bits (stitches, sprinkles, the lattice...) - for eggs carried in the arms
-- The model is at the origin, anchored, no collisions; its pivot is the middle of the egg's bottom; PrimaryPart =
-- "Shell" (the lower half of the shell; ZoneService and the hatch look for it by name).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(script.Parent:WaitForChild("Formulas")) :: any

local EggLook = {}

local GOLD = Color3.fromRGB(255, 200, 40)
local WARM = Color3.fromRGB(255, 232, 150)
local BASE_HEIGHT = 3.8
local TINY = 0.36 -- (simple) parts smaller than this (largest side, at BASE_HEIGHT) are left out

local lib: Folder? = nil
local function library(): Folder?
	if not lib then
		lib = ReplicatedStorage:WaitForChild("EggModels", 10) :: Folder?
	end
	return lib
end

function EggLook.build(egg: string, golden: boolean?, height: number?, simple: boolean?): Model
	local folder = library()
	local src = folder and (folder:FindFirstChild(egg) or folder:FindFirstChild("Briefcase"))
	local m: Model
	if src then
		m = (src :: Model):Clone()
	else -- (no library yet: a plain egg so nothing breaks)
		m = Instance.new("Model")
		local p = Instance.new("Part")
		p.Name = "Shell"
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(3, BASE_HEIGHT, 3)
		p.CFrame = CFrame.new(0, BASE_HEIGHT / 2, 0)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = m
		m.PrimaryPart = p
		p.PivotOffset = p.CFrame:Inverse()
	end
	m.Name = "Egg"
	-- an egg without its own model: the Briefcase shape, in its own colour
	if src and src.Name ~= egg then
		local def = Formulas.themedEgg(egg)
		if def and def.Color then
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and (p.Name == "Shell" or p.Name == "ShellTop") then
					p.Color = def.Color
				end
			end
		end
	end
	if golden then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				if p.Name == "Shell" or p.Name == "ShellTop" or p.Name == "Frosting" then
					p.Color = GOLD
					p.Reflectance = 0.18
				elseif p.Material ~= Enum.Material.Neon and p.Material ~= Enum.Material.Glass then
					p.Color = p.Color:Lerp(WARM, 0.5)
				end
			end
		end
		local kit = folder and folder:FindFirstChild("GoldenKit")
		if kit then
			for _, p in kit:GetChildren() do
				if p:IsA("BasePart") and not (simple and p.Name == "Lattice") then
					p:Clone().Parent = m
				end
			end
		end
	end
	if simple then
		for _, p in m:GetChildren() do
			if p:IsA("BasePart") and p ~= m.PrimaryPart and p.Name ~= "ShellTop" and math.max(p.Size.X, p.Size.Y, p.Size.Z) < TINY then
				p:Destroy()
			end
		end
	end
	local h = height or BASE_HEIGHT
	if math.abs(h - BASE_HEIGHT) > 1e-3 then
		m:ScaleTo(h / BASE_HEIGHT)
	end
	return m
end

-- the main colour of an egg (for things drawn without a model: trails, flying bits)
function EggLook.color(egg: string, golden: boolean?): Color3
	if golden then
		return GOLD
	end
	local folder = library()
	local src = folder and folder:FindFirstChild(egg)
	local shell = src and src:FindFirstChild("ShellTop")
	if shell and shell:IsA("BasePart") then
		return shell.Color
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.fromRGB(245, 200, 70)
end

return EggLook
