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
local FirmBuilder = require(script.Parent.FirmBuilder)
local FirmStages = require(script.Parent:WaitForChild("FirmStages"))
local FirmFeatures = require(script.Parent:WaitForChild("FirmFeatures"))

local Templates = ServerStorage:WaitForChild("Templates")
local Plots = workspace:WaitForChild("Plots")

local PlotService = {}

local owners: { [Model]: Player } = {}
local firms: { [Player]: Model } = {}

local function sortedPlots(): { Model }
	local list = {}
	for _, plot in Plots:GetChildren() do
		if plot:IsA("Model") then
			table.insert(list, plot)
		end
	end
	-- Plot1, Plot2, ... in numeric order.
	table.sort(list, function(a, b)
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
			local firm = buildFirm(player, plot)
			firms[player] = firm
			player:SetAttribute("Plot", plot.Name)

			moveToFirm(player)
			player.CharacterAdded:Connect(function()
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
	local firm = firms[player]
	if not firm then
		return
	end
	firms[player] = nil
	owners[firm.Parent :: Model] = nil
	firm:Destroy()
end

return PlotService
