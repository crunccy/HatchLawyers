--!strict
-- TravelServer (ServerScriptService.TravelServer, a Script; 2026-10-13, crnuch's cloud session - written blind,
-- playtest it). Zone travel, user's pick "A": one Travel Portal at the hub (Workspace.Hub.TravelPortal, built by
-- tools/zones/BuildTravelPortal.lua from Blender) and a travel map (StarterPlayerScripts.Travel; the portal or the
-- TRAVEL tile opens it). It replaced the six Hub.ZoneTeleports pads (ZoneService's old TeleportPrompt handler finds
-- no pads any more and does nothing).
--   Remotes.Travel:InvokeServer("Home" | zone Id) -> (ok, reason?)   reason: "carrying" | "license" | "cooldown" | ...
-- The server checks everything: the zone exists, you own its Law License (Zones.License >= the zone's License), you
-- aren't carrying eggs (Config.Zones.Travel.BlockWhileCarrying - the walk home past the bosses is the game) and the
-- cooldown. You land on the zone's Arrival spot facing down the lane (like the old pads), or at your firm's
-- SpawnPoint; the destination streams in first so phones never land on a missing floor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local Server = ServerScriptService:WaitForChild("Server")
local PlayerData = require(Server:WaitForChild("PlayerData") :: ModuleScript) :: any
local PlotService = require(Server:WaitForChild("PlotService") :: ModuleScript) :: any
-- (2026-10-20) the lane or the redesign islands, behind the off switch: Config.Zones.Islands.Enabled / Studio /islands
local ZoneMap = require(Server:WaitForChild("ZoneMap") :: ModuleScript) :: any

local TRAVEL = (Config.Zones and Config.Zones.Travel) or {}
local COOLDOWN = TRAVEL.Cooldown or 3
local BLOCK_WHILE_CARRYING = TRAVEL.BlockWhileCarrying ~= false

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Travel = Remotes:FindFirstChild("Travel") :: RemoteFunction?
if not Travel then
	local r = Instance.new("RemoteFunction")
	r.Name = "Travel"
	r.Parent = Remotes
	Travel = r
end

local lastTrip: { [Player]: number } = {}

local function zoneDef(id: string): any
	for _, z in Config.Zones.List do
		if z.Id == id then
			return z
		end
	end
	return nil
end

-- where a trip ends: a zone's Arrival (facing down the lane, the same turn ZoneService's pads used) or the firm
local function destination(player: Player, target: string): (CFrame?, Color3?)
	if target == "Home" then
		local firm = PlotService.getFirm(player)
		local spawnPoint = firm and firm:FindFirstChild("SpawnPoint") :: BasePart?
		if spawnPoint then
			return spawnPoint.CFrame * CFrame.new(0, 3.5, 0), Color3.fromRGB(98, 205, 48)
		end
		return nil, nil
	end
	local def = zoneDef(target)
	local folder = def and ZoneMap.folder(def.Id) -- (Workspace.Zones.<Id>, or Workspace.IslandWiring.<Id> when on)
	local arrival = folder and folder:FindFirstChild("Arrival") :: BasePart?
	if not arrival then
		return nil, nil
	end
	return CFrame.new(arrival.Position + Vector3.new(0, 3, 0)) * arrival.CFrame.Rotation * CFrame.Angles(0, math.rad(90), 0), def.Color
end

-- stream the destination in first (phones stream a small radius), then move - like PlotService does for firms
local function move(player: Player, character: Model, root: BasePart, cf: CFrame, color: Color3?): (boolean, string?)
	pcall(player.RequestStreamAroundAsync, player, cf.Position, 5)
	if player.Character ~= character or not character.Parent then
		return false, "loading"
	end
	Effects.burst(root.Position, "tier", color) -- a pop where you left, for anyone watching ...
	character:PivotTo(cf)
	task.delay(0.15, Effects.burst, cf.Position - Vector3.new(0, 2, 0), "tier", color) -- ... and where you land
	return true, nil
end

local function travel(player: Player, target: unknown): (boolean, string?)
	if type(target) ~= "string" or #target > 40 then
		return false, "bad"
	end
	local t = os.clock()
	if t - (lastTrip[player] or 0) < COOLDOWN then
		return false, "cooldown"
	end
	local data = PlayerData.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not data or not character or not root then
		return false, "loading"
	end
	local z = data.Zones or {}
	if BLOCK_WHILE_CARRYING and z.Carried and #z.Carried > 0 then
		return false, "carrying"
	end
	if target ~= "Home" then
		local def = zoneDef(target)
		if not def then
			return false, "bad"
		end
		if (z.License or 0) < (def.License or 0) then
			return false, "license"
		end
	end
	local cf, color = destination(player, target)
	if not cf then
		return false, "missing"
	end
	lastTrip[player] = t
	return move(player, character, root, cf, color)
end

(Travel :: RemoteFunction).OnServerInvoke = travel
Players.PlayerRemoving:Connect(function(player)
	lastTrip[player] = nil
end)

-- RETURN HOME (2026-10-20; only while the redesign islands are switched on): each island's portal
-- (Workspace.IslandWiring.<Id>.ReturnHome, built by tools/zones/BuildIslandWiring.lua) sends you to your firm WITH your
-- eggs - the walk past the island's boss is the price (environment-redesign/central_hub/blockout/LAYOUT.md, decision 4).
-- Walk into it or use its prompt. The usual cooldown applies; carrying never blocks it.
local function returnHome(player: Player)
	if not ZoneMap.islandsOn() then
		return
	end
	local t = os.clock()
	if t - (lastTrip[player] or 0) < COOLDOWN then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end
	local cf, color = destination(player, "Home")
	if not cf then
		return
	end
	lastTrip[player] = t
	move(player, character, root, cf, color)
end

local returnPrompts: { ProximityPrompt } = {}
local function hookReturn(part: Instance)
	if not part:IsA("BasePart") or part.Name ~= "ReturnHome" then
		return
	end
	local prompt = part:FindFirstChild("ReturnPrompt") :: ProximityPrompt?
	if prompt then
		prompt.Enabled = ZoneMap.islandsOn()
		prompt.Triggered:Connect(returnHome)
		table.insert(returnPrompts, prompt)
	end
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			returnHome(player)
		end
	end)
end
local wiring = workspace:FindFirstChild("IslandWiring")
if wiring then
	for _, d in wiring:GetDescendants() do
		hookReturn(d)
	end
	wiring.DescendantAdded:Connect(hookReturn)
end
ZoneMap.changed:Connect(function(on: boolean)
	for _, prompt in returnPrompts do
		prompt.Enabled = on
	end
end)
