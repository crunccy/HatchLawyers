--!strict
-- Server entry point: load data -> claim a plot -> start the case loop, and the reverse on leave.

local Players = game:GetService("Players")

-- the hub's map first (Server.HubMap, 2026-10-20): with the hub switch on it moves the plots + hub services onto the
-- v2 hub island before any service looks at them
require(script.Parent.HubMap).apply()

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local CaseService = require(script.Parent.CaseService)
local LawyerService = require(script.Parent.LawyerService)
local CourtService = require(script.Parent.CourtService)
local DeskService = require(script.Parent.DeskService)
local SkillService = require(script.Parent.SkillService)
local RewardsService = require(script.Parent.RewardsService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local GoalService = require(script.Parent.GoalService)
local ManagerService = require(script.Parent.ManagerService)
local PrestigeService = require(script.Parent.PrestigeService)
local BigCaseService = require(script.Parent.BigCaseService)
local ShopService = require(script.Parent.ShopService)
local MinigameService = require(script.Parent.MinigameService)
local ZoneService = require(script.Parent.ZoneService)
local BossService = require(script.Parent.BossService)

local function onPlayerAdded(player: Player)
	local data = PlayerData.load(player)
	if not data or player.Parent == nil then
		return
	end
	ShopService.onDataLoaded(player)
	local firm = PlotService.assign(player)
	if not firm then
		PlayerData.release(player)
		player:Kick("This server is full of law firms! Please join another server.")
		return
	end
	DeskService.buildDesks(player)
	CaseService.start(player, firm)
	DeskService.dress(player)
	ManagerService.setupFirm(player)
end

local function onPlayerRemoving(player: Player)
	CaseService.stop(player)
	PlotService.release(player)
	LeaderboardService.save(player) -- snapshot scores before the data is released
	PlayerData.release(player)
end

PlayerData.start()
LawyerService.start()
CourtService.start()
DeskService.start()
SkillService.start()
RewardsService.start()
LeaderboardService.start()
GoalService.start()
ManagerService.start()
PrestigeService.start()
BigCaseService.start()
ShopService.start()
MinigameService.start()
ZoneService.start()
BossService.start()
CaseService.run()

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
