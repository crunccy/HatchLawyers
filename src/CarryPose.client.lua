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
--   * THE BRIEFCASE (the Carry upgrade, 2026-10-12): every client hangs each player's briefcase on their back - the
--     model named by Config.Zones.Carry[ZoneCarry].Model (ReplicatedStorage.Briefcases, tools/blender/briefcases.py),
--     slung a little crooked. Level 1 (no briefcase yet) shows nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local EggLook = require(Shared:WaitForChild("EggLook") :: ModuleScript) :: any -- (the detailed eggs, 2026-10-12)

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

-- a carried egg: the detailed egg (Shared.EggLook, "simple" - no tiny bits) whose Shell is welded to the chest; its
-- other parts hang off the Shell. rel = where the Shell sits from the egg's middle.
type Egg = { part: Instance, weld: Weld, rel: CFrame }
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

local function makeEgg(c: Carrier, i: number, egg: string, golden: boolean): Egg
	local w = c.torso.Size.X * EGG_WIDTH
	local h = w * 3.8 / 3 -- (the egg models are 3 wide, 3.8 tall)
	local m = EggLook.build(egg, golden, h, true)
	m.Name = "CarriedEgg"
	local shell = m.PrimaryPart :: BasePart
	local rel = CFrame.new(0, -h / 2, 0) * shell.CFrame -- (built at the origin: the Shell's place from the egg's bottom)
	m:PivotTo(c.torso.CFrame * eggOffset(c, i, 0) * CFrame.new(0, -h / 2, 0))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			if p ~= shell then
				local wc = Instance.new("WeldConstraint")
				wc.Part0 = shell
				wc.Part1 = p
				wc.Parent = p
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Part0 = c.torso
	weld.Part1 = shell
	weld.C0 = eggOffset(c, i, 0) * rel
	weld.Parent = shell
	m.Parent = visuals
	return { part = m, weld = weld, rel = rel }
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
		table.insert(c.eggs, makeEgg(c, i, item.egg, item.golden))
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

------------------------------------------------------------------ the briefcase on the back
local BRIEFCASE_TILT = math.rad(-8) -- slung on a little crooked
local BRIEFCASE_DROP = 0.55 -- its bottom sits this share of its own height below the torso's middle
local briefcases = ReplicatedStorage:WaitForChild("Briefcases", 10)
type Worn = { model: Model, character: Model, name: string }
local worn: { [Player]: Worn } = {}

local function removeBriefcase(player: Player)
	local w = worn[player]
	if w then
		w.model:Destroy()
		worn[player] = nil
	end
end

local function wearBriefcase(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local level = player:GetAttribute("ZoneCarry")
	local def = if typeof(level) == "number" then Config.Zones.Carry[level] else nil
	local name: string = (def and def.Model) or ""
	local w = worn[player]
	if w and w.character == character and w.name == name and w.model.Parent then
		return
	end
	removeBriefcase(player)
	local template = briefcases and name ~= "" and briefcases:FindFirstChild(name)
	if not character or not torso or not torso:IsA("BasePart") or not template then
		return
	end
	local m = (template :: Model):Clone()
	local height = (m:GetAttribute("Height") :: number?) or 1
	-- (the model's origin is the bottom edge of the side that touches the back; the library sits at the origin, so
	-- each part's CFrame is already relative to it)
	local attach = CFrame.new(0, -height * BRIEFCASE_DROP, torso.Size.Z * 0.5) * CFrame.Angles(0, 0, BRIEFCASE_TILT)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = p
			weld.C0 = attach * p.CFrame
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CFrame = torso.CFrame * weld.C0
			weld.Parent = p
		end
	end
	m.Name = "Briefcase_" .. player.Name
	m.Parent = visuals
	worn[player] = { model = m, character = character, name = name }
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Carried"):Connect(function()
		track(player)
	end)
	player:GetAttributeChangedSignal("ZoneCarry"):Connect(function()
		wearBriefcase(player)
	end)
	player.CharacterAdded:Connect(function(character)
		drop(player)
		removeBriefcase(player)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Humanoid", 10)
		task.wait() -- (let the rig's parts arrive)
		track(player)
		wearBriefcase(player)
	end)
	player.CharacterRemoving:Connect(function()
		removeBriefcase(player) -- (its welds would break and it would fall)
	end)
	if player.Character then
		task.spawn(function()
			track(player)
			wearBriefcase(player)
		end)
	end
end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player)
	drop(player)
	removeBriefcase(player)
end)
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
			e.weld.C0 = eggOffset(c, i, moving) * e.rel
		end
	end
end)
