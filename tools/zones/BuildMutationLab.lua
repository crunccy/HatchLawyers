-- tools/zones/BuildMutationLab.lua - builds ReplicatedStorage.MutationLab from tools/zones/mutation_lab.json (made in
-- Blender: tools/blender/mutation_lab.py). The stage of the mutation sequence (Shared.MutationFx): the client clones it
-- far above the map for the length of a mutation, like the Mythic / Supreme hatch stages. Re-runnable (replaces it).
-- 2026-10-21, mr.robe's session (the Mutation Machine rebuilt). Run in Edit mode with the JSON reachable at JSON_URL
-- (tools/studio_sync/serve_files.ps1 -Root tools/zones).
-- The model's pivot is the middle of the floor top (y = 0), its FRONT faces +Z. Every block is a studded Part
-- (MaterialVariant BrickStuds) except tags: "neon" = Neon, "glass" = see-through SmoothPlastic, "marker" = invisible; shape "cyl" =
-- Cylinder, "ball" = Ball; "a" = Transparency. Nothing collides (the player never stands on it). Names the client
-- looks up: Pad1-3, PipeGlow<p>_<k>, CapsuleCore, CapsuleCentre, CoilTop1-2, FloorGlow, Bulb, Screen, SignPlate, and
-- the Model "Lid" (every Lid* block: glass, ribs, cap - lifted to open the capsule).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JSON_URL = "http://localhost:8766/mutation_lab.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local recording = ChangeHistoryService:TryBeginRecording("BuildMutationLab")

local old = ReplicatedStorage:FindFirstChild("MutationLab")
if old then
	old:Destroy()
end
local lab = Instance.new("Model")
lab.Name = "MutationLab"
local lid = Instance.new("Model")
lid.Name = "Lid"
lid.Parent = lab

local blocks = 0
for _, b in data.parts do
	local p = Instance.new("Part")
	p.Name = b.n
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
	local r = b.r
	p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
	p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if b.shape == "cyl" then
		p.Shape = Enum.PartType.Cylinder
	elseif b.shape == "ball" then
		p.Shape = Enum.PartType.Ball
	end
	if b.t == "neon" then
		p.Material = Enum.Material.Neon
	elseif b.t == "glass" then
		-- (not Material.Glass: Roblox doesn't draw see-through parts behind Glass, so the capsule's light column vanished)
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0.2
	elseif b.t == "marker" then
		p.Transparency = 1
	else
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "BrickStuds"
	end
	if b.a and b.a > 0 and b.t ~= "marker" then
		p.Transparency = b.a
	end
	p.CastShadow = b.t == "" and p.Size.Magnitude > 2
	p.Parent = if string.sub(b.n, 1, 3) == "Lid" then lid else lab
	blocks += 1
end
lid.WorldPivot = CFrame.new()
lab.WorldPivot = CFrame.new()

-- "MUTATION MACHINE" on the sign plate (its front is the model's +Z = NormalId.Back)
local sign = lab:FindFirstChild("SignPlate") :: BasePart?
if sign then
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "MUTATION MACHINE"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 214, 60)
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack) -- (the game's big-text font, CLAUDE.md)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = sign
end

-- z-fighting (bug report 6, 2026-10-16): nudge apart faces this build left level (ServerScriptService.Server.ZFight)
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())
for _ = 1, 3 do
	if ZFight.fix({ lab }) == 0 then
		break
	end
end
lab.Parent = ReplicatedStorage
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return ("MutationLab: %d blocks (%d in the Lid) -> ReplicatedStorage.MutationLab"):format(blocks, #lid:GetChildren())
