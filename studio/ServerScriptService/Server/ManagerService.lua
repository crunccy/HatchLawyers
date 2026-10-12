--!strict
-- The Manager (Config.Manager): hired once, then permanent firm-wide upgrades. Case effects are
-- applied in CaseService (deskBuffs, Settlement Bot, Referral client odds); this module handles
-- buying, the Retainer payout loop, the Manager character and the "Manager Office" prompt on the
-- firm's filing cabinet (the Manager screen opens on the client: StarterPlayerScripts.Manager).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local SkinLook = require(ReplicatedStorage.Shared.SkinLook)
local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local RewardsService = require(script.Parent.RewardsService)

local Remotes = ReplicatedStorage.Remotes
local HireManager = Remotes.HireManager :: RemoteFunction
local BuyManagerUpgrade = Remotes.BuyManagerUpgrade :: RemoteFunction
local Templates = ServerStorage:WaitForChild("Templates")

local COOLDOWN = 0.3
local RETAINER_INTERVAL = 60
local SUIT = Color3.fromRGB(110, 60, 200) -- the Manager dresses fancier than the lawyers

local ManagerService = {}

local lastRequest: { [Player]: number } = {}

local function throttled(player: Player): boolean
	local t = os.clock()
	if t - (lastRequest[player] or 0) < COOLDOWN then
		return true
	end
	lastRequest[player] = t
	return false
end

local function manager(data: PlayerData.Data): { Hired: boolean, Levels: { [string]: number } }
	data.Manager = data.Manager or { Hired = false, Levels = {} }
	return data.Manager
end

-- Where the Manager stands: a part named ManagerSpot if the firm tier has one (art can add it),
-- else beside the filing cabinet, else beside the entrance (SpawnPoint). Returns the part and the
-- firm-local sideways offset to stand at.
local function anchorPart(firm: Model): (BasePart?, number)
	for _, name in { "ManagerSpot", "FilingCabinet" } do
		local part = firm:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part, if name == "ManagerSpot" then 0 else 2.6
		end
	end
	local spawn = firm:FindFirstChild("SpawnPoint")
	return if spawn and spawn:IsA("BasePart") then spawn else nil, 5 -- step aside so nobody spawns inside them
end

local function setPromptText(prompt: ProximityPrompt, hired: boolean)
	prompt.ActionText = if hired then "Manager Office" else "Hire a Manager"
	prompt.ObjectText = if hired then "Upgrades" else Formulas.formatCoins(Config.Manager.HireCost) .. " coins"
end

local function spawnManager(firm: Model)
	if firm:FindFirstChild("Manager") then
		return
	end
	local anchor, sideways = anchorPart(firm)
	if not anchor then
		return
	end
	local npc = Templates.NPC:Clone()
	npc.Name = "Manager"
	for _, name in { "Torso", "Left Arm", "Right Arm" } do
		local p = npc:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color = SUIT
		end
	end
	-- stand next to the cabinet, feet on the floor, facing into the firm
	local floorY = anchor.Position.Y - anchor.Size.Y / 2
	local beside = firm:GetPivot():PointToWorldSpace(firm:GetPivot():PointToObjectSpace(anchor.Position) + Vector3.new(sideways, 0, 0))
	local box, size = npc:GetBoundingBox()
	local pivotAboveFeet = npc:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	local facing = firm:GetPivot().Rotation * CFrame.Angles(0, math.pi, 0) -- toward the front door
	npc:PivotTo(CFrame.new(beside.X, floorY + pivotAboveFeet, beside.Z) * facing)
	-- block-style Manager (SkinModels.Manager, tools/lawyers_v2.py) over the hidden blocky body
	SkinLook.wearModel(npc, "Manager")

	-- (no name tag over the Manager: no words over anyone's head; the talk prompt says who it is)
	npc.Parent = firm
	-- talk to the Manager to open the office
	local prompt = firm:FindFirstChild("ManagerPrompt", true)
	local root = npc:FindFirstChild("HumanoidRootPart")
	if prompt and prompt:IsA("ProximityPrompt") and root then
		prompt.Parent = root
		setPromptText(prompt, true)
	end
end

-- Adds the Manager Office prompt (owner only) and the Manager if hired. Call once the firm is up.
function ManagerService.setupFirm(player: Player)
	local firm = PlotService.getFirm(player)
	local data = PlayerData.get(player)
	if not firm or not data then
		return
	end
	local anchor = anchorPart(firm)
	if anchor and not firm:FindFirstChild("ManagerPrompt", true) then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ManagerPrompt"
		setPromptText(prompt, false)
		prompt.KeyboardKeyCode = Enum.KeyCode.F -- E is busy with desks and the hire sign
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		CollectionService:AddTag(prompt, "OwnerOnlyPrompt")
		CollectionService:AddTag(prompt, "ManagerPrompt")
		prompt.Parent = anchor
	end
	if manager(data).Hired then
		spawnManager(firm)
	end
end

local function hire(player: Player): (boolean, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	local mgr = manager(data)
	if mgr.Hired then
		return false, "Already hired!"
	end
	if not PlayerData.spendCoins(player, Config.Manager.HireCost) then
		return false, "Not enough coins"
	end
	mgr.Hired = true
	PlayerData.sync(player)
	require(script.Parent.BadgeAwards).award(player, "HireManager")
	local firm = PlotService.getFirm(player)
	if firm then
		spawnManager(firm)
	end
	require(script.Parent.GoalService).track(player, "manager")
	return true, nil
end

local function buy(player: Player, id: unknown): (boolean, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	local mgr = manager(data)
	if not mgr.Hired then
		return false, "Hire a Manager first"
	end
	if type(id) ~= "string" then
		return false, "Bad upgrade"
	end
	local def = Formulas.getManagerUpgrade(id)
	if not def then
		return false, "Bad upgrade"
	end
	local level = mgr.Levels[id] or 0
	if level >= def.MaxLevel then
		return false, "Maxed!"
	end
	if not PlayerData.spendCoins(player, Formulas.managerUpgradeCost(id, level)) then
		return false, "Not enough coins"
	end
	mgr.Levels[id] = level + 1
	PlayerData.sync(player)
	require(script.Parent.GoalService).track(player, "manager")
	return true, nil
end

function ManagerService.start()
	HireManager.OnServerInvoke = hire
	BuyManagerUpgrade.OnServerInvoke = buy
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
	-- Retainer Clients: a slice of a minute's income every minute
	task.spawn(function()
		while true do
			task.wait(RETAINER_INTERVAL)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function()
					local data = PlayerData.get(player)
					local share = data and Formulas.managerValue(data.Manager and data.Manager.Levels, "retainer") or 0
					if data and share > 0 then
						data.Coins += math.floor(RewardsService.incomePerMinute(data) * share)
						PlayerData.sync(player)
					end
				end)
				if not ok then
					warn("[ManagerService] retainer failed:", err) -- (audit 2026-10-12: one error stopped it for everyone)
				end
			end
		end
	end)
end

return ManagerService
