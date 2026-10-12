--!strict
-- CarryPose (StarterPlayerScripts.CarryPose). How a player carries zone eggs (Server.ZoneService keeps the list; the
-- player attribute "Carried" = "Briefcase,Pet*,..." with * = golden). Nothing here touches gameplay.
-- Remade 2026-10-12 (mr.robe's session; the first version wrote the arm joints every frame and fought the walk
-- animation - "it's bugging"):
--   * THE ARMS are a real animation made in Blender (tools/blender/carry_anim.py: the hands were solved to hold the
--     bottom egg's sides, with a slow hug / breathe loop) -> ReplicatedStorage.Animations.CarryEggs (Action priority,
--     looped; built by tools/zones/BuildCarryAnimation.lua). Each client plays it on its OWN character while carrying
--     and Roblox replicates it to everyone. Walking / jumping keep playing underneath on the legs.
--     Until CarryEggs has a published AnimationId it only plays in Studio (from its Source KeyframeSequence).
--   * THE EGGS: every client draws the pile for every carrying player, welded to the chest (UpperTorso / Torso) so
--     they move with the body: about two thirds of the torso wide, the bottom egg at the belly between the hands, each
--     egg above it nesting into the one below a bit off to one side and tilted, the pile leaning back. It sways a
--     little while walking, more at the top. The numbers match the Blender scene.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any

local localPlayer = Players.LocalPlayer

local FADE = 0.2 -- seconds for the arms to go out / come back
-- the pile (same numbers as tools/blender/carry_anim.py - change both, or the hands miss the egg)
local EGG_WIDTH = 0.68 -- x the torso's width
local EGG_TALL = 1.22 -- x the egg's width
local EGG_DROP = 0.27 -- the bottom egg's centre sits this share of the torso's height below the torso's centre
local NEST = 0.78 -- each egg sits this share of an egg's height above the one below (eggs are round, they nest)
local LEAN_BACK = 0.12 -- studs each egg sits further back toward the chest than the one below
local LEAN_TILT = math.rad(5) -- and the pile tilts back this much more per egg
-- each egg's own "not perfectly placed" offset: { sideways (x egg width), roll (deg), yaw (deg) }
local JITTER = {
	{ 0, 0, 0 },
	{ 0.16, 9, 25 },
	{ -0.14, -11, -40 },
	{ 0.12, 7, 70 },
	{ -0.18, -9, -15 },
	{ 0.1, 12, 50 },
	{ -0.12, -8, -60 },
}

local visuals = Instance.new("Folder")
visuals.Name = "CarryVisuals"
visuals.Parent = workspace

------------------------------------------------------------------ the animation (own character only)
local carryAnim = (function(): Animation?
	local folder = ReplicatedStorage:WaitForChild("Animations", 10)
	local a = folder and folder:FindFirstChild("CarryEggs")
	return if a and a:IsA("Animation") then a else nil
end)()
local studioId: string? = nil

local function animationId(): string?
	if not carryAnim then
		return nil
	end
	if carryAnim.AnimationId ~= "" then
		return carryAnim.AnimationId
	end
	if RunService:IsStudio() then -- not published yet: play the KeyframeSequence (Studio only)
		if not studioId then
			local source = carryAnim:FindFirstChild("Source")
			if source and source:IsA("KeyframeSequence") then
				local ok, id = pcall(function()
					return (game:GetService("KeyframeSequenceProvider") :: any):RegisterKeyframeSequence(source)
				end)
				studioId = if ok then id else nil
			end
		end
		return studioId
	end
	return nil
end

local armTrack: AnimationTrack? = nil
local trackCharacter: Model? = nil

local function setArms(carrying: boolean)
	local character = localPlayer.Character
	if not character then
		return
	end
	if trackCharacter ~= character then
		armTrack, trackCharacter = nil, character
	end
	if carrying and not armTrack then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local id = animationId()
		-- (made for R15; an R6 avatar just carries the eggs without the arm pose)
		if not humanoid or not animator or not id or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
			return
		end
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, t = pcall(function()
			return (animator :: Animator):LoadAnimation(a)
		end)
		if not ok or not t then
			return
		end
		t.Priority = Enum.AnimationPriority.Action
		t.Looped = true
		armTrack = t
	end
	if armTrack then
		if carrying and not armTrack.IsPlaying then
			armTrack:Play(FADE)
		elseif not carrying and armTrack.IsPlaying then
			armTrack:Stop(FADE)
		end
	end
end

------------------------------------------------------------------ eggs
local function eggColor(egg: string, golden: boolean): Color3
	local z = Config.Zones
	if golden and z and z.EggColors and z.EggColors.Golden then
		return z.EggColors.Golden
	end
	if z and z.EggColors and z.EggColors[egg] then
		return z.EggColors[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.new(1, 1, 1)
end

local function parseCarried(value: any): { { egg: string, golden: boolean } }
	local list = {}
	if typeof(value) == "string" and value ~= "" then
		for item in string.gmatch(value, "[^,]+") do
			local golden = string.sub(item, -1) == "*"
			table.insert(list, { egg = if golden then string.sub(item, 1, -2) else item, golden = golden })
		end
	end
	return list
end

type Egg = { part: BasePart, weld: Weld }
type Carrier = {
	player: Player,
	character: Model,
	torso: BasePart,
	root: BasePart,
	eggs: { Egg },
	key: string, -- the Carried value the eggs were built for
	phase: number, -- sway clock
}
local carriers: { [Player]: Carrier } = {}

-- where egg i sits on the chest (torso space), with this frame's sway
local function eggOffset(c: Carrier, i: number, moving: number): CFrame
	local size = c.torso.Size
	local w = size.X * EGG_WIDTH
	local h = w * EGG_TALL
	local j = JITTER[((i - 1) % #JITTER) + 1]
	local y = -size.Y * EGG_DROP + (i - 1) * h * NEST
	local z = -(size.Z * 0.5 + w * 0.5 - 0.1) + (i - 1) * LEAN_BACK -- (front is -Z)
	local tilt = (i - 1) * LEAN_TILT
	-- sway: barely while standing, more while walking, more the higher up the pile (the bottom egg is held still)
	local sway = if i == 1 then 0 else math.sin(c.phase + i * 0.9) * math.rad((i - 1) * (1.5 + 3 * moving))
	local x = j[1] * w + math.sin(c.phase * 0.5 + i) * 0.04 * (i - 1) * (0.3 + moving)
	return CFrame.new(x, y, z) * CFrame.Angles(tilt, math.rad(j[3]), math.rad(j[2]) + sway)
end

local function makeEgg(c: Carrier, i: number, color: Color3, golden: boolean): Egg
	local w = c.torso.Size.X * EGG_WIDTH
	local p = Instance.new("Part")
	p.Name = "CarriedEgg"
	p.Size = Vector3.new(w, w * EGG_TALL, w)
	p.Color = color
	p.Material = if golden then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	local weld = Instance.new("Weld")
	weld.Part0 = c.torso
	weld.Part1 = p
	weld.C0 = eggOffset(c, i, 0)
	weld.Parent = p
	p.CFrame = c.torso.CFrame * weld.C0
	p.Parent = visuals
	return { part = p, weld = weld }
end

local function clearEggs(c: Carrier)
	for _, e in c.eggs do
		e.part:Destroy()
	end
	c.eggs = {}
end

local function rebuildEggs(c: Carrier, value: any)
	clearEggs(c)
	c.key = if typeof(value) == "string" then value else ""
	for i, item in parseCarried(value) do
		table.insert(c.eggs, makeEgg(c, i, eggColor(item.egg, item.golden), item.golden))
	end
end

local function drop(player: Player)
	local c = carriers[player]
	if c then
		clearEggs(c)
		carriers[player] = nil
	end
	if player == localPlayer then
		setArms(false)
	end
end

local function track(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not torso or not torso:IsA("BasePart") or not root or not root:IsA("BasePart") then
		drop(player)
		return
	end
	local existing: Carrier? = carriers[player]
	if existing and existing.character ~= character then
		drop(player)
		existing = nil
	end
	local c: Carrier = existing or {
		player = player, character = character, torso = torso :: BasePart, root = root :: BasePart,
		eggs = {}, key = "", phase = 0,
	}
	carriers[player] = c
	local value = player:GetAttribute("Carried")
	if (if typeof(value) == "string" then value else "") ~= c.key then
		rebuildEggs(c, value)
	end
	if player == localPlayer then
		setArms(#c.eggs > 0)
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Carried"):Connect(function()
		track(player)
	end)
	player.CharacterAdded:Connect(function(character)
		drop(player)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Humanoid", 10)
		task.wait() -- (let the rig's parts arrive)
		track(player)
	end)
	if player.Character then
		task.spawn(track, player)
	end
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(drop)
for _, p in Players:GetPlayers() do
	watch(p)
end

------------------------------------------------------------------ the sway (welds move with the body; this only nudges the pile)
RunService.Heartbeat:Connect(function(dt)
	for player, c in carriers do
		if not c.character.Parent or not c.torso.Parent then
			drop(player)
			continue
		end
		if #c.eggs < 2 then
			continue
		end
		local v = c.root.AssemblyLinearVelocity
		local moving = math.clamp(Vector3.new(v.X, 0, v.Z).Magnitude / 16, 0, 1)
		c.phase += dt * (3 + 6 * moving)
		for i, e in c.eggs do
			e.weld.C0 = eggOffset(c, i, moving)
		end
	end
end)
