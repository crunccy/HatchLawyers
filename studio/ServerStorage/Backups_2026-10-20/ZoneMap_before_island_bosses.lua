--!strict
-- ZoneMap (ServerScriptService.Server.ZoneMap, 2026-10-20, mr.robe's session; user's call: wire the redesign islands
-- in "behind an off switch"). Which map runs the egg zones:
--   OFF (the default, the live game): today's lane, Workspace.Zones.<Id> - nothing changes.
--   ON: the redesign islands, Workspace.IslandWiring.<Id> = the gameplay markers built beside each island of
--       Workspace.WorldRedesign by tools/zones/BuildIslandWiring.lua: EggSpots (Parts), Arrival (Part), ReturnHome
--       (Part + ReturnPrompt; TravelServer sends you home WITH your eggs), OddsBoard (tag ZoneOddsBoard). Each folder
--       carries attributes Island (the island model's name), BoundsMin / BoundsMax (Vector3, the island's box).
-- The switch: Config.Zones.Islands.Enabled (the real one) or, in Studio only, workspace attribute IslandsOn (the admin
-- /islands on|off, for testing in a playtest). ZoneService (eggs) and TravelServer (trips) read their folders here and
-- rebind when the mode flips (ZoneMap.changed). Bosses stay on the lane either way (BossService is untouched).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config) :: any

local ZoneMap = {}

local changedEvent = Instance.new("BindableEvent")
ZoneMap.changed = changedEvent.Event -- (on: boolean)

function ZoneMap.islandsOn(): boolean
	local cfg = Config.Zones and Config.Zones.Islands
	if cfg and cfg.Enabled == true then
		return true
	end
	return RunService:IsStudio() and workspace:GetAttribute("IslandsOn") == true
end

-- the folder that holds a zone's EggSpots / Arrival in the current mode
function ZoneMap.folder(id: string): Instance?
	local root = workspace:FindFirstChild(if ZoneMap.islandsOn() then "IslandWiring" else "Zones")
	return root and root:FindFirstChild(id)
end

-- what eggs may land on / be raycast against for a zone folder: the island model in island mode, nil on the lane
function ZoneMap.ground(folder: Instance): Instance?
	local island = folder:GetAttribute("Island")
	local world = workspace:FindFirstChild("WorldRedesign")
	return if type(island) == "string" and world then world:FindFirstChild(island) else nil
end

local last = ZoneMap.islandsOn()
workspace:GetAttributeChangedSignal("IslandsOn"):Connect(function()
	local now = ZoneMap.islandsOn()
	if now ~= last then
		last = now
		changedEvent:Fire(now)
	end
end)

return ZoneMap
