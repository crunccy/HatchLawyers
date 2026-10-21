--!strict
-- HubMap (ServerScriptService.Server.HubMap, 2026-10-20, mr.robe's session; user's calls: move the hub's gameplay onto
-- the v2 central hub island behind a NEW switch, everything moves, today's hub stays untouched as the fallback).
--   OFF (Config.Zones.Islands.Hub not true, or the islands switch off): nothing moves - today's hub.
--   ON: at server start (Main calls apply() before any service starts) every marker in Workspace.HubWiring
--       (tools/zones/BuildHubWiring.lua) moves the model its Moves attribute names - a path under Workspace
--       ("Plots.Plot1", "Hub.ShopStall", "Zones.LicenseOffice.Counter_License", "ArcadePier.Booths.LieDetector",
--       "HubSpawn" ...) - so its pivot lands on the marker, shrunk by the marker's Scale if it has one; the minigames'
--       Rest CFrames (world space) move with their stations. The island's look-alikes (tag HubLookalike: its own
--       portal, shop, belt, boards, the fountain, the Arcade Pier ...) are parked in ServerStorage.HubLookalikes. Plots
--       drop today's paint (Decor parked, Base see-through: the island's lot is the ground); HubSpawn goes see-through
--       on the island's spawn pad.
-- Scripts keep finding everything by its old path (Workspace.Hub.*, Workspace.Plots.*, Zones.LicenseOffice ...): only
-- positions change. Start-only: firms are built on the plots, so flipping it needs a server restart.
-- The switch: Config.Zones.Islands.Hub (needs Islands.Enabled too), or in Studio the workspace attribute HubOn (set it
-- in Edit mode, then press Play).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config) :: any
local ZoneMap = require(script.Parent.ZoneMap)

local HubMap = {}

local WORLD_CFRAMES = { "Rest" } -- attributes holding world-space CFrames (Minigames.client: the peekers + cases)

function HubMap.on(): boolean
	if not ZoneMap.islandsOn() then
		return false
	end
	local cfg = Config.Zones and Config.Zones.Islands
	if cfg and cfg.Hub == true then
		return true
	end
	return RunService:IsStudio() and workspace:GetAttribute("HubOn") == true
end

local applied = false
local centre = Vector3.zero

-- the hub's middle: today's plaza is the map's (0, 0); on the island, the island's plaza (HubWiring's Centre)
function HubMap.centre(): Vector3
	return centre
end

local function find(path: string): Instance?
	local node: Instance? = workspace
	for name in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function move(model: PVInstance, target: CFrame, scale: number)
	local old = model:GetPivot()
	model:PivotTo(target)
	if scale ~= 1 and model:IsA("Model") then
		model:ScaleTo(model:GetScale() * scale)
	end
	for _, d in model:GetDescendants() do
		for _, name in WORLD_CFRAMES do
			local cf = d:GetAttribute(name)
			if typeof(cf) == "CFrame" then
				local rel = old:ToObjectSpace(cf)
				d:SetAttribute(name, target * CFrame.new(rel.Position * scale) * rel.Rotation)
			end
		end
	end
end

-- a plot keeps its Base (FirmBuilder.frame reads its size) but not today's paint
local function plainPlot(plot: Instance, park: Folder)
	local decor = plot:FindFirstChild("Decor")
	if decor then
		decor:SetAttribute("HubPlot", plot.Name)
		decor.Parent = park
	end
	local base = plot:FindFirstChild("Base")
	if base and base:IsA("BasePart") then
		base.Transparency = 1
		base.CastShadow = false
		CollectionService:RemoveTag(base, "StudTop")
		for _, d in base:GetDescendants() do
			if d:IsA("Decal") or d:IsA("Texture") then
				d.Transparency = 1
			end
		end
	end
end

function HubMap.apply()
	if applied then
		return
	end
	applied = true
	if not HubMap.on() then
		return
	end
	local wiring = workspace:FindFirstChild("HubWiring")
	if not wiring then
		warn("[HubMap] Workspace.HubWiring not found (tools/zones/BuildHubWiring.lua): the hub stays where it is")
		return
	end
	local park = ServerStorage:FindFirstChild("HubLookalikes") :: Folder?
	if not park then
		park = Instance.new("Folder")
		park.Name = "HubLookalikes"
		park.Parent = ServerStorage
	end
	local parked = 0
	for _, p in CollectionService:GetTagged("HubLookalike") do
		if p:IsDescendantOf(workspace) then
			p.Parent = park
			parked += 1
		end
	end
	local plots = workspace:FindFirstChild("Plots")
	local moved = 0
	for _, marker in wiring:GetChildren() do
		local path = marker:GetAttribute("Moves")
		if not marker:IsA("BasePart") or type(path) ~= "string" then
			continue
		end
		local model = find(path)
		if not model or not model:IsA("PVInstance") then
			warn("[HubMap] nothing at Workspace." .. path)
			continue
		end
		local scale = marker:GetAttribute("Scale")
		move(model, marker.CFrame, if type(scale) == "number" then scale else 1)
		moved += 1
		if plots and model.Parent == plots then
			plainPlot(model, park :: Folder)
		elseif model:IsA("SpawnLocation") then
			model.Transparency = 1
			model.CanCollide = false
			for _, d in model:GetDescendants() do
				if d:IsA("Decal") or d:IsA("Texture") then
					d.Transparency = 1
				end
			end
		end
	end
	local c = wiring:GetAttribute("Centre")
	if typeof(c) == "Vector3" then
		centre = c
	end
	workspace:SetAttribute("HubCentre", centre)
	print(string.format("[HubMap] the hub runs on the v2 island: %d models moved, %d look-alike parts parked", moved, parked))
end

return HubMap
