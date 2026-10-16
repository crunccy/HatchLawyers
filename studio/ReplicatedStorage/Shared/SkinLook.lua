--!strict
-- Dresses a blocky NPC (the ServerStorage.Templates.NPC shape) in a skin from Config.SkinCatalog.
-- The server uses it on desk lawyers and the client on the hatch preview, so both always match.
-- Calling it again swaps the skin; passing nil puts the default outfit back.
-- Mutations (2026-10-13): dress(model, skinId, stars) - a mutated lawyer (Stars 2-4: Shiny / Diamond / Cosmic) is
-- recoloured by Shared.MutationLook after dressing; showInViewport takes the same `stars`.
-- Two kinds of skin: recolor skins (suit/pants/tie/hat on the blocky body) and model skins
-- (skin.Model names a rigged model in ReplicatedStorage.SkinModels that stands in for the body).

local Formulas = require(script.Parent.Formulas)

local SkinLook = {}

local DRESSABLE: { [string]: "Suit" | "Pants" } = {
	Torso = "Suit",
	["Left Arm"] = "Suit",
	["Right Arm"] = "Suit",
	["Left Leg"] = "Pants",
	["Right Leg"] = "Pants",
}

local function piece(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p:SetAttribute("SkinPart", true)
	p.Parent = model
	return p
end

-- Neon skins: Shared.Effects star glints + motes (VFX v2; replaced the old plain sparkle emitter)
local function addSparkles(part: BasePart, color: Color3)
	for _, e in require(script.Parent.Effects).ambient(part, "star", color, 0.7) do
		e:SetAttribute("SkinPart", true)
	end
end

-- Model skins: hide the blocky body and stand the rigged skin model where it was.
-- (skin = a Config.SkinCatalog entry, or just { Model = name } - the Manager wears SkinModels.Manager this way)
local function putOnModel(model: Model, skin: any)
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("SkinModels")
	local template = folder and folder:FindFirstChild(skin.Model)
	if not (template and template:IsA("Model")) then
		warn("[SkinLook] missing skin model:", skin.Model)
		return
	end
	-- Measure the body's feet and facing before hiding it.
	local box, size = model:GetBoundingBox()
	local feet = CFrame.new(box.Position - Vector3.new(0, size.Y / 2, 0)) * model:GetPivot().Rotation
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			local visual = d :: any
			if visual.Transparency < 1 then
				d:SetAttribute("BaseTransparency", visual.Transparency)
				visual.Transparency = 1
			end
		end
	end
	local clone = template:Clone()
	clone.Name = "SkinModel"
	clone:SetAttribute("SkinPart", true)
	-- Rigged skins (mr.robe's LawyerSkin_Legendary: unanchored parts on 16 Motor6Ds) toppled over under
	-- physics and fought Shared.Puppet, which poses every part itself. Their real pose lives in the joints
	-- (the stored part CFrames are stale), so first place every part where its joint puts it, then anchor
	-- and drop the joints. Bones stay so skinned meshes still render.
	local joints = {}
	for _, d in clone:GetDescendants() do
		if d:IsA("JointInstance") then
			local j = d :: any
			if j.Part0 and j.Part1 then
				table.insert(joints, { p0 = j.Part0, p1 = j.Part1, c0 = j.C0, c1 = j.C1 })
			end
		end
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("JointInstance") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	for _ = 1, 8 do -- walk the joint tree outward from the root (8 passes covers any limb chain)
		for _, j in joints do
			j.p1.CFrame = j.p0.CFrame * j.c0 * j.c1:Inverse()
		end
	end
	local skinBox, skinSize = clone:GetBoundingBox()
	local pivotAboveFeet = clone:GetPivot().Position.Y - (skinBox.Position.Y - skinSize.Y / 2)
	-- Hover (attribute on the skin model, studs): flying lawyers (a bomber plane...) float above the floor
	-- instead of standing on it (2026-10-10 model remakes)
	local hover = template:GetAttribute("Hover")
	clone:PivotTo(feet * CFrame.new(0, pivotAboveFeet + (if typeof(hover) == "number" then hover else 0), 0))
	clone.Parent = model
	local torso = clone:FindFirstChild("UpperTorso")
	if skin.Neon and torso and torso:IsA("BasePart") then
		addSparkles(torso, Color3.fromRGB(255, 215, 60))
	end
end

local function addHat(model: Model, head: BasePart, kind: string, color: Color3, neon: boolean?)
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)
	local w = head.Size.X
	if kind == "Cap" then
		piece(model, "Cap", Vector3.new(w + 0.1, 0.5, w + 0.1), top * CFrame.new(0, 0.25, 0), color)
		piece(model, "CapBrim", Vector3.new(w + 0.1, 0.15, 0.8), top * CFrame.new(0, 0.08, -w / 2 - 0.35), color)
	elseif kind == "TopHat" then
		piece(model, "HatBrim", Vector3.new(w + 0.6, 0.15, w + 0.6), top * CFrame.new(0, 0.08, 0), color)
		piece(model, "HatTop", Vector3.new(w - 0.1, 1.4, w - 0.1), top * CFrame.new(0, 0.85, 0), color)
		piece(model, "HatBand", Vector3.new(w, 0.25, w), top * CFrame.new(0, 0.3, 0), Color3.fromRGB(255, 80, 170))
	elseif kind == "Crown" then
		piece(model, "CrownBand", Vector3.new(w + 0.2, 0.5, w + 0.2), top * CFrame.new(0, 0.25, 0), color, neon)
		for _, x in { -0.5, 0, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				piece(model, "CrownSpike", Vector3.new(0.35, 0.5, 0.35), top * CFrame.new(x * w, 0.7, z * w), color, neon)
			end
		end
	elseif kind == "Shades" then
		piece(model, "Shades", Vector3.new(w + 0.1, 0.35, 0.15), head.CFrame * CFrame.new(0, 0.15, -head.Size.Z / 2 - 0.05), color, neon)
	end
end

-- (Shared.MutationLook, if it's in the place: the mutation recolour)
local mutationModule = script.Parent:FindFirstChild("MutationLook")
local MutationLook = if mutationModule then (require(mutationModule :: ModuleScript) :: any) else nil

local function finish(model: Model, stars: number?)
	if MutationLook then
		MutationLook.apply(model, stars)
	end
end

function SkinLook.dress(model: Model, skinId: string?, stars: number?)
	-- an earlier mutation recolour comes off first, and its saved originals are forgotten (the dress below sets
	-- fresh colours; the recolour at the end reads them again)
	if MutationLook then
		MutationLook.apply(model, 1)
		for _, d in model:GetDescendants() do
			if d:GetAttribute("MutBase") ~= nil then
				d:SetAttribute("MutBase", nil)
			end
		end
	end
	for _, d in model:GetDescendants() do
		if d:GetAttribute("SkinPart") then
			d:Destroy()
		end
	end

	-- Remember the default outfit the first time, and restore it before applying a new skin.
	for name in DRESSABLE do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local base = p:GetAttribute("BaseColor")
			if typeof(base) == "Color3" then
				p.Color = base
			else
				p:SetAttribute("BaseColor", p.Color)
			end
		end
	end

	-- Un-hide the blocky body if a model skin hid it.
	for _, d in model:GetDescendants() do
		local base = d:GetAttribute("BaseTransparency")
		if typeof(base) == "number" then
			(d :: any).Transparency = base
			d:SetAttribute("BaseTransparency", nil)
		end
	end

	local skin = Formulas.getSkin(skinId)
	if not skin then
		finish(model, stars)
		return
	end
	if skin.Model then
		putOnModel(model, skin)
		finish(model, stars)
		return
	end

	for name, field in DRESSABLE do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color = skin[field]
		end
	end

	-- NPCs face their LookVector (-Z), so the tie goes on the torso's -Z face.
	local torso = model:FindFirstChild("Torso") :: BasePart?
	if torso then
		local front = -torso.Size.Z / 2
		piece(model, "Collar", Vector3.new(1.3, 0.3, 0.12), torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - 0.15, front - 0.03), Color3.new(1, 1, 1))
		piece(model, "Tie", Vector3.new(0.45, 1.3, 0.12), torso.CFrame * CFrame.new(0, 0.1, front - 0.05), skin.Tie, skin.Neon)
		if skin.Neon then
			addSparkles(torso, skin.Tie)
		end
	end

	local head = model:FindFirstChild("Head") :: BasePart?
	if head and skin.Hat then
		addHat(model, head, skin.Hat, skin.HatColor or skin.Suit, skin.Neon)
	end
	finish(model, stars)
end

-- Puts a model from ReplicatedStorage.SkinModels on a blocky NPC that isn't a catalog lawyer (the Manager).
function SkinLook.wearModel(model: Model, modelName: string)
	putOnModel(model, { Model = modelName })
end

-- Client only: shows a copy of `source` (a lawyer model) wearing `skinId` inside a ViewportFrame,
-- gently swaying. Returns the RenderStepped connection; disconnect it when the preview closes.
function SkinLook.showInViewport(viewport: ViewportFrame, source: Model, skinId: string?, stars: number?): RBXScriptConnection
	viewport:ClearAllChildren()
	-- the desk lawyer may be mid-animation (Shared.Puppet); preview it standing at rest
	local model = require(script.Parent.Puppet).cloneAtRest(source)
	model:PivotTo(CFrame.new())
	SkinLook.dress(model, skinId, stars)
	for _, d in model:GetDescendants() do
		-- Nameplates and particles don't belong in (or render in) a viewport.
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	model.Parent = viewport

	local center, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(center.Position + Vector3.new(0, size.Y * 0.15, -size.Y * 2.6), center.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local home = model:GetPivot()
	return game:GetService("RunService").RenderStepped:Connect(function()
		local t = os.clock()
		model:PivotTo(home * CFrame.new(0, math.sin(t * 3) * 0.1, 0) * CFrame.Angles(0, math.sin(t * 1.5) * 0.6, 0))
	end)
end

return SkinLook
