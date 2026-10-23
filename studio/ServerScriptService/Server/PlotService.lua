--!strict
-- Hands each player one plot from Workspace.Plots and builds their firm on it.
-- The building is assembled from the Blender kit by FirmBuilder: entrance, waiting room, one office
-- segment per Firm.Segments (2 lawyer offices each), the locked expansion and the back wall.
-- rebuild() rebuilds it after the firm expands or a lawyer is hired.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)
local VIPService = require(script.Parent.VIPService)
local FirmBuilder = require(script.Parent.FirmBuilder)
local FirmStages = require(script.Parent:WaitForChild("FirmStages"))
local FirmFeatures = require(script.Parent:WaitForChild("FirmFeatures"))
local HubMap = require(script.Parent:WaitForChild("HubMap"))

local Templates = ServerStorage:WaitForChild("Templates")
local Plots = workspace:WaitForChild("Plots")

local PlotService = {}

local owners: { [Model]: Player } = {}
local firms: { [Player]: Model } = {}
local respawnHooks: { [Player]: RBXScriptConnection } = {} -- (moveToFirm on every respawn; dropped on release - audit 2026-10-12)

local function sortedPlots(): { Model }
	local list = {}
	for _, plot in Plots:GetChildren() do
		if plot:IsA("Model") then
			table.insert(list, plot)
		end
	end
	-- Nearest the plaza first (design pass 2026-10-16: on a quiet server the firms fill the plots by the hub, not the
	-- far corners), then Plot1, Plot2, ... in numeric order. (The plaza: HubMap.centre(), the v2 hub island's middle
	-- when the hub runs there.)
	local function dist(p: Model): number
		local pos = p:GetPivot().Position - HubMap.centre()
		return math.floor(Vector2.new(pos.X, pos.Z).Magnitude / 10)
	end
	table.sort(list, function(a, b)
		local da, db = dist(a), dist(b)
		if da ~= db then
			return da < db
		end
		return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0)
	end)
	return list
end

local function moveToFirm(player: Player)
	local firm = firms[player]
	local character = player.Character
	local spawnPoint = firm and firm:FindFirstChild("SpawnPoint") :: BasePart?
	if character and spawnPoint then
		local target = spawnPoint.CFrame * CFrame.new(0, 3.5, 0)
		-- Phones can stream a small radius: load the firm on the player's device before moving
		-- them there, so they never land on a floor that hasn't arrived yet.
		task.spawn(function()
			pcall(player.RequestStreamAroundAsync, player, target.Position, 5)
			if player.Character == character and firms[player] == firm then
				character:PivotTo(target)
			end
		end)
	end
end

-- An empty plot shows its LOT SIGN (Plots.PlotN.LotSign, art pass 2026-10-16: tools/zones/BuildLotSigns.lua); it is
-- tucked into ServerStorage.HiddenLotSigns while the plot has a firm and put back when the owner leaves.
local function setLotSign(plot: Model, shown: boolean)
	local hidden = ServerStorage:FindFirstChild("HiddenLotSigns")
	if not hidden then
		hidden = Instance.new("Folder")
		hidden.Name = "HiddenLotSigns"
		hidden.Parent = ServerStorage
	end
	if shown then
		for _, sign in hidden:GetChildren() do
			if sign:GetAttribute("Plot") == plot.Name then
				sign.Parent = plot
			end
		end
	else
		local sign = plot:FindFirstChild("LotSign")
		if sign then
			sign:SetAttribute("Plot", plot.Name)
			sign.Parent = hidden
		end
	end
end

-- The firm tier shown to other scripts: the number of office segments the firm has.
function PlotService.tierOf(player: Player): number
	local data = PlayerData.get(player)
	return if data and data.Firm then data.Firm.Segments else Config.Firm.StartSegments
end

-- The player's firm, freshly assembled on the plot and named "Firm" (client scripts look for plot.Firm).
local function buildFirm(player: Player, plot: Model): Model
	local previousStage = player:GetAttribute("FirmStage") :: number?
	local tier = PlotService.tierOf(player)
	local data = PlayerData.get(player)
	local lawyers = if data then #data.Desks else Config.Firm.StartLawyers
	local prestige = if data and data.Prestige then data.Prestige.Level else 0
	local stage = FirmStages.stageFor(tier, prestige) -- the building grows with expansions; prestige = Supreme Tower
	local firm = FirmBuilder.build(plot, tier, lawyers, Config.Firm.MaxSegments, function(slot)
		return Formulas.formatCoins(Config.Desks.UnlockCosts[slot] or 0) .. " coins"
	end, stage)
	player:SetAttribute("FirmStage", stage)
	local sign = firm:FindFirstChild("Sign")
	local label = sign and sign:FindFirstChild("Label", true) :: TextLabel?
	if label then
		local data = PlayerData.get(player)
		local level = if data and data.Prestige then data.Prestige.Level else 0
		label.Text = player.DisplayName .. "'s Law Firm" .. if level > 0 then " " .. string.rep("★", math.min(level, 5)) else ""
	end
	firm:SetAttribute("OwnerUserId", player.UserId)
	firm:SetAttribute("Tier", tier)
	firm.Parent = plot
	VIPService.decorateFirm(player, firm)
	player:SetAttribute("FirmTier", tier)
	-- area pads, showcase, hologram, elevator, hatch lab, and the stage-up moment (Server.FirmFeatures)
	task.defer(function()
		local ok, err = pcall(FirmFeatures.attach, player, firm, previousStage)
		if not ok then
			warn("[PlotService] FirmFeatures:", err)
		end
	end)
	return firm
end

-- Returns nil if every plot is taken.
function PlotService.assign(player: Player): Model?
	for _, plot in sortedPlots() do
		if not owners[plot] then
			owners[plot] = player
			setLotSign(plot, false)
			local firm = buildFirm(player, plot)
			firms[player] = firm
			player:SetAttribute("Plot", plot.Name)

			moveToFirm(player)
			if respawnHooks[player] then
				respawnHooks[player]:Disconnect()
			end
			respawnHooks[player] = player.CharacterAdded:Connect(function()
				task.defer(moveToFirm, player)
			end)
			return firm
		end
	end
	return nil
end

function PlotService.getFirm(player: Player): Model?
	return firms[player]
end

-- Swaps the player's building for the one matching their current tier (after an upgrade) and
-- moves them to its entrance. Returns the new firm; desks must be rebuilt by the caller.
function PlotService.rebuild(player: Player): Model?
	local old = firms[player]
	local plot = old and old.Parent :: Model?
	if not old or not plot then
		return nil
	end
	local firm = buildFirm(player, plot)
	firms[player] = firm
	old:Destroy()
	moveToFirm(player)
	return firm
end

function PlotService.release(player: Player)
	if respawnHooks[player] then
		respawnHooks[player]:Disconnect()
		respawnHooks[player] = nil
	end
	local firm = firms[player]
	if not firm then
		return
	end
	firms[player] = nil
	local plot = firm.Parent :: Model
	owners[plot] = nil
	firm:Destroy()
	setLotSign(plot, true)
end

return PlotService
