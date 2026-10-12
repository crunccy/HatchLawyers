--!strict
-- Egg zones (Config.Zones; map: Workspace.Zones; client: StarterPlayerScripts.Zones). The firm earns while the
-- player is away; the zones are where they go to get lawyers:
--   * EGGS keep popping up on each zone's EggSpots (up to MaxEggs at once, one more every Respawn seconds after
--     one is bought). Now and then one is GOLDEN (costs PriceMultiplier x, rolls Rare / Legendary more often,
--     disappears after Lifetime seconds) and the whole server gets an alert.
--   * BUYING one (its BuyPrompt) costs the egg's price (EggApi "price") and puts it in the player's bag (up to the
--     Carry level's Max). Carried eggs ride over the player's head and are saved (data.Zones.Carried).
--   * INCUBATORS in the player's own firm (tag "Incubator", built by FirmBuilder) hatch carried eggs one by one
--     (EggApi "hatch": the normal hatch screen), or the free first egg / a reward token when the bag is empty.
--   * UPGRADES at the License Office (UpgradePrompt, attribute Upgrade = "License" | "Carry" | "Speed") and the
--     gate's LicensePrompt. The License opens the next zone (its gate turns see-through on that player's screen;
--     the server also refuses to sell eggs in a zone the player has no License for). Prestige resets the License.
--   * TELEPORT pads at the hub (TeleportPrompt, attribute Zone) go to a zone's Arrival spot (if licensed).
--   * WALK SPEED comes from the Speed level (Config.Zones.Speed, base 32 = the game's doubled speed).
-- Mirrored player attributes: ZoneLicense, ZoneCarry, ZoneCarryMax, ZoneSpeed, Carried ("Briefcase,Pet*,..."
-- where * = golden). Remotes.Zones (RemoteEvent), server -> client: ("Note", text) ("Alert", { text, zone })
-- ("Bought", { egg, golden, count, max }) ("Upgraded", { kind, level, text }) ("Hatched", { left }).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config) :: any
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)

local Remote = ReplicatedStorage.Remotes:WaitForChild("Zones") :: RemoteEvent
local CFG = Config.Zones

local ZoneService = {}

type Zone = { def: any, folder: Instance, spots: { BasePart }, eggs: { [BasePart]: Model }, nextSpawn: number }
local zones: { Zone } = {}
local zoneById: { [string]: Zone } = {}
local rng = Random.new()
local api: BindableFunction? = nil
local lastHatch: { [Player]: number } = {}

local function eggApi(...): any
	if not api then
		api = ServerStorage:WaitForChild("EggApi", 30) :: BindableFunction?
	end
	if not api then
		return nil
	end
	local ok, result = pcall((api :: BindableFunction).Invoke, api :: BindableFunction, ...)
	if not ok then
		warn("[ZoneService] EggApi failed:", result)
		return nil
	end
	return result
end

local function zonesData(data: any): any
	data.Zones = data.Zones or { License = 0, Carry = 1, Speed = 1, Carried = {} }
	data.Zones.Carried = data.Zones.Carried or {}
	return data.Zones
end

local function carryMax(z: any): number
	local level = CFG.Carry[z.Carry] or CFG.Carry[1]
	return level.Max
end

local function eggName(egg: string): string
	return if egg == "Briefcase" then "Briefcase Egg" else egg .. " Egg"
end

local function note(player: Player, text: string)
	Remote:FireClient(player, "Note", text)
end

---------------------------------------------------------------- carried eggs over the head
local function eggColor(egg: string, golden: boolean?): Color3
	if golden then
		return CFG.EggColors.Golden
	end
	if CFG.EggColors[egg] then
		return CFG.EggColors[egg]
	end
	local def = Formulas.themedEgg(egg)
	return (def and def.Color) or Color3.new(1, 1, 1)
end

local function refreshCarryVisual(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not character or not head then
		return
	end
	local old = character:FindFirstChild("CarriedEggs")
	if old then
		old:Destroy()
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local z = zonesData(data)
	if #z.Carried == 0 then
		return
	end
	local m = Instance.new("Model")
	m.Name = "CarriedEggs"
	for i, item in z.Carried do
		local p = Instance.new("Part")
		p.Name = "Egg" .. i
		p.Size = Vector3.new(1.5, 1.9, 1.5)
		p.Color = eggColor(item.Egg, item.Golden)
		p.Material = if item.Golden then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.CFrame = head.CFrame * CFrame.new(0, 1.6 + i * 1.75, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = p
		weld.Parent = p
		p.Parent = m
	end
	m.Parent = character
end

-- player attributes the client reads (prompt texts, HUD, gates)
function ZoneService.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local z = zonesData(data)
	player:SetAttribute("ZoneLicense", z.License)
	player:SetAttribute("ZoneCarry", z.Carry)
	player:SetAttribute("ZoneCarryMax", carryMax(z))
	player:SetAttribute("ZoneSpeed", z.Speed)
	local list = {}
	for _, item in z.Carried do
		table.insert(list, item.Egg .. (if item.Golden then "*" else ""))
	end
	player:SetAttribute("Carried", table.concat(list, ","))
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = (CFG.Speed[z.Speed] or CFG.Speed[1]).WalkSpeed
	end
	refreshCarryVisual(player)
end

---------------------------------------------------------------- zone eggs
local function buildEgg(zone: Zone, spot: BasePart, golden: boolean): Model
	local egg = zone.def.Egg
	local m = Instance.new("Model")
	m.Name = "ZoneEgg"
	m:SetAttribute("Zone", zone.def.Id)
	m:SetAttribute("Egg", egg)
	m:SetAttribute("Golden", golden)
	-- the label's second line (StarterPlayerScripts.Zones shows "<egg name>" then this, in its rarity colour)
	m:SetAttribute("Rarity", if golden then "Rare" else "Common")
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- knee-high and sitting ON the lane floor (docs/ZONES_REFERENCE.md: nothing floats)
	local size = if golden then Vector3.new(2.8, 3.5, 2.8) else Vector3.new(2.3, 2.9, 2.3)
	local floorY = spot.Position.Y - spot.Size.Y / 2
	local home = CFrame.new(spot.Position.X, floorY + size.Y / 2, spot.Position.Z)
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Anchored = true
	shell.CanCollide = false
	shell.Size = size
	shell.CFrame = home
	shell.Color = eggColor(egg, golden)
	shell.Material = if golden then Enum.Material.Neon else Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell
	shell.Parent = m
	-- the egg's own markings: a leather band on the Briefcase egg, brown spots on the Pet egg
	local function deco(name: string, size: Vector3, offset: CFrame, color: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size
		p.CFrame = home * offset
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		local mm = Instance.new("SpecialMesh")
		mm.MeshType = Enum.MeshType.Sphere
		mm.Parent = p
		p.Parent = m
	end
	local s = size.X / 3 -- the markings were drawn for a 3-wide egg
	if egg == "Briefcase" then
		deco("Band", Vector3.new(3.08, 0.7, 3.08) * s, CFrame.new(0, -0.2 * s, 0), if golden then Color3.fromRGB(200, 140, 20) else Color3.fromRGB(150, 88, 44))
	else
		for i, o in { { 1.3, 0.3, 0.5 }, { -1.2, 0.8, -0.6 }, { 0.2, -0.6, -1.35 } } do
			deco("Spot" .. i, Vector3.new(0.8, 0.8, 0.8) * s, CFrame.new(o[1] * s, o[2] * s, o[3] * s), if golden then Color3.fromRGB(200, 140, 20) else Color3.fromRGB(110, 70, 40))
		end
	end
	if golden then
		local light = Instance.new("PointLight")
		light.Color = CFG.EggColors.Golden
		light.Range = 16
		light.Brightness = 2
		light.Parent = shell
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(CFG.EggColors.Golden)
		sparkle.Rate = 12
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(2, 4)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(0.6, 0)
		sparkle.Parent = shell
	end
	m.PrimaryPart = shell
	m:SetAttribute("Home", home)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy Egg"
	prompt.ObjectText = eggName(egg) -- the client writes this player's price in
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = shell
	CollectionService:AddTag(m, "ZoneEgg")
	m.Parent = zone.folder
	return m
end

local function spawnEgg(zone: Zone)
	local free = {}
	for _, spot in zone.spots do
		if not zone.eggs[spot] then
			table.insert(free, spot)
		end
	end
	if #free == 0 then
		return
	end
	local spot = free[rng:NextInteger(1, #free)]
	local hasGolden = false
	for _, m in zone.eggs do
		if m:GetAttribute("Golden") then
			hasGolden = true
		end
	end
	local golden = not hasGolden and rng:NextNumber() < CFG.Golden.Chance
	local m = buildEgg(zone, spot, golden)
	zone.eggs[spot] = m
	if golden then
		Remote:FireAllClients("Alert", { text = "A GOLDEN EGG appeared in " .. zone.def.Name .. "!", zone = zone.def.Id })
		task.delay(CFG.Golden.Lifetime, function()
			if zone.eggs[spot] == m then
				zone.eggs[spot] = nil
				m:Destroy()
			end
		end)
	end
end

local function hasLicenseFor(data: any, zone: Zone): boolean
	return zonesData(data).License >= (zone.def.License or 0)
end

local function buy(player: Player, zone: Zone, spot: BasePart, m: Model)
	if zone.eggs[spot] ~= m then
		return -- someone else got it first
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local z = zonesData(data)
	if not hasLicenseFor(data, zone) then
		note(player, zone.def.Name .. " needs a Law License!")
		return
	end
	if #z.Carried >= carryMax(z) then
		note(player, "Your bag is full! Take your eggs home to your INCUBATOR")
		return
	end
	local room = (eggApi("room", player) :: number?) or 0
	if room - #z.Carried <= 0 then
		note(player, "Too many lawyers! Merge some at the Lawyer Merger first")
		return
	end
	local golden = m:GetAttribute("Golden") == true
	local price = ((eggApi("price", player, zone.def.Egg) :: number?) or math.huge) * (if golden then CFG.Golden.PriceMultiplier else 1)
	price = math.floor(price)
	if not PlayerData.spendCoins(player, price) then
		note(player, "Need " .. Formulas.formatCoins(price) .. " coins for this egg")
		return
	end
	zone.eggs[spot] = nil
	m:Destroy()
	zone.nextSpawn = math.max(zone.nextSpawn, os.clock() + rng:NextNumber(zone.def.Respawn[1], zone.def.Respawn[2]))
	table.insert(z.Carried, { Egg = zone.def.Egg, Golden = golden })
	PlayerData.sync(player)
	ZoneService.sync(player)
	Remote:FireClient(player, "Bought", { egg = zone.def.Egg, golden = golden, count = #z.Carried, max = carryMax(z) })
end

---------------------------------------------------------------- incubators
local function ownerOf(inst: Instance): number?
	local node: Instance? = inst
	while node do
		local id = node:GetAttribute("OwnerUserId")
		if type(id) == "number" then
			return id
		end
		node = node.Parent
	end
	return nil
end

local function hatchAt(player: Player, incubator: Model)
	local t = os.clock()
	if lastHatch[player] and t - lastHatch[player] < 1 then
		return
	end
	lastHatch[player] = t
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local z = zonesData(data)
	local at = (incubator.PrimaryPart and incubator.PrimaryPart.Position or incubator:GetPivot().Position) + Vector3.new(0, 5, 0)
	if #z.Carried > 0 then
		local item = table.remove(z.Carried, 1)
		local ok = eggApi("hatch", player, item.Egg, item.Golden == true, at)
		if not ok then
			table.insert(z.Carried, 1, item) -- lawyer cap or still hatching: keep the egg
		end
		ZoneService.sync(player)
		if ok then
			Remote:FireClient(player, "Hatched", { left = #z.Carried })
		end
		return
	end
	if player:GetAttribute("FreeEgg") == true and eggApi("free", player, at) then
		return
	end
	note(player, "Your bag is empty! Buy eggs in Briefcase Bay and bring them here")
end

local function hookIncubator(incubator: Instance)
	if not incubator:IsA("Model") then
		return
	end
	local prompt = incubator:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?
	if not prompt or prompt:GetAttribute("Hooked") then
		return
	end
	prompt:SetAttribute("Hooked", true)
	prompt.Triggered:Connect(function(who)
		if ownerOf(incubator) == who.UserId then
			hatchAt(who, incubator)
		end
	end)
end

---------------------------------------------------------------- upgrades
local function nextLevel(kind: string, z: any): (any, number)
	if kind == "License" then
		return CFG.License[z.License + 1], z.License + 1
	elseif kind == "Carry" then
		return CFG.Carry[z.Carry + 1], z.Carry + 1
	elseif kind == "Speed" then
		return CFG.Speed[z.Speed + 1], z.Speed + 1
	end
	return nil, 0
end

local function buyUpgrade(player: Player, kind: string)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local z = zonesData(data)
	local def, level = nextLevel(kind, z)
	if not def then
		note(player, "Already maxed out!")
		return
	end
	if not PlayerData.spendCoins(player, def.Cost) then
		note(player, "Need " .. Formulas.formatCoins(def.Cost) .. " coins")
		return
	end
	local text
	if kind == "License" then
		z.License = level
		local opened = {}
		for _, zone in zones do
			if (zone.def.License or 0) == level then
				table.insert(opened, zone.def.Name)
			end
		end
		text = def.Name .. "! " .. (if #opened > 0 then table.concat(opened, ", ") .. " is open!" else "")
	elseif kind == "Carry" then
		z.Carry = level
		text = "Bigger bag! You can carry " .. def.Max .. " eggs"
	else
		z.Speed = level
		text = "Faster shoes! Speed " .. def.WalkSpeed
	end
	PlayerData.sync(player)
	ZoneService.sync(player)
	Remote:FireClient(player, "Upgraded", { kind = kind, level = level, text = text })
end

---------------------------------------------------------------- wiring
local function hookPrompts()
	local root = workspace:FindFirstChild("Zones")
	if root then
		for _, p in root:GetDescendants() do
			if p:IsA("ProximityPrompt") and (p.Name == "UpgradePrompt" or p.Name == "LicensePrompt") then
				local kind = p:GetAttribute("Upgrade")
				p.Triggered:Connect(function(player)
					if type(kind) == "string" then
						buyUpgrade(player, kind)
					end
				end)
			end
		end
	end
	local tps = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("ZoneTeleports")
	if tps then
		for _, p in tps:GetDescendants() do
			if p:IsA("ProximityPrompt") and p.Name == "TeleportPrompt" then
				local zoneId = p:GetAttribute("Zone")
				p.Triggered:Connect(function(player)
					local zone = type(zoneId) == "string" and zoneById[zoneId]
					local data = PlayerData.get(player)
					local character = player.Character
					if not zone or not data or not character then
						return
					end
					if not hasLicenseFor(data, zone) then
						note(player, zone.def.Name .. " needs a Law License! Buy one at the License Office in Briefcase Bay")
						return
					end
					local arrival = zone.folder:FindFirstChild("Arrival") :: BasePart?
					if arrival then
						character:PivotTo(CFrame.new(arrival.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(-90), 0))
					end
				end)
			end
		end
	end
end

function ZoneService.start()
	local root = workspace:FindFirstChild("Zones")
	if not root then
		warn("[ZoneService] Workspace.Zones not found: no egg zones")
	end
	for _, def in CFG.List do
		local folder = root and root:FindFirstChild(def.Id)
		local spotsFolder = folder and folder:FindFirstChild("EggSpots")
		if folder and spotsFolder then
			local spots = {}
			for _, s in spotsFolder:GetChildren() do
				if s:IsA("BasePart") then
					table.insert(spots, s)
				end
			end
			local zone: Zone = { def = def, folder = folder, spots = spots, eggs = {}, nextSpawn = 0 }
			table.insert(zones, zone)
			zoneById[def.Id] = zone
		end
	end
	hookPrompts()

	-- buying: one prompt per egg, found through the tag so eggs spawned later are covered too
	CollectionService:GetInstanceAddedSignal("ZoneEgg"):Connect(function(m)
		local prompt = m:FindFirstChild("BuyPrompt", true) :: ProximityPrompt?
		local zone = zoneById[m:GetAttribute("Zone") :: string]
		if not prompt or not zone then
			return
		end
		local spot: BasePart? = nil
		for s, egg in zone.eggs do
			if egg == m then
				spot = s
			end
		end
		prompt.Triggered:Connect(function(player)
			local s = spot
			if not s then
				for sp, egg in zone.eggs do
					if egg == m then
						s = sp
					end
				end
			end
			if s then
				buy(player, zone, s, m :: Model)
			end
		end)
	end)

	CollectionService:GetInstanceAddedSignal("Incubator"):Connect(hookIncubator)
	for _, inc in CollectionService:GetTagged("Incubator") do
		hookIncubator(inc)
	end

	-- fill every zone right away, then keep topping them up
	for _, zone in zones do
		for _ = 1, zone.def.MaxEggs do
			spawnEgg(zone)
		end
	end
	task.spawn(function()
		while true do
			task.wait(1)
			local t = os.clock()
			for _, zone in zones do
				local count = 0
				for _ in zone.eggs do
					count += 1
				end
				if count < zone.def.MaxEggs and t >= zone.nextSpawn then
					spawnEgg(zone)
					zone.nextSpawn = t + rng:NextNumber(zone.def.Respawn[1], zone.def.Respawn[2]) * 0.5
				end
			end
		end
	end)

	local function onCharacter(player: Player, character: Model)
		character:WaitForChild("Humanoid", 10)
		character:WaitForChild("Head", 10)
		ZoneService.sync(player)
	end
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastHatch[player] = nil
	end)
	-- mirror each player's zone data once it has loaded (and their character's speed + carried eggs)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("ZoneLicense") == nil and PlayerData.get(player) then
					ZoneService.sync(player)
				end
			end
			task.wait(1)
		end
	end)
end

return ZoneService
