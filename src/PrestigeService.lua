--!strict
-- Prestige ("Supreme Empire", Config.Prestige). A ladder (economy pass 2026-10-09): going Supreme from level N
-- takes Formulas.prestigeRequirement(N) - a coin cost and a number of offices with a lawyer in them. It resets
-- coins, office levels, the firm size, the Manager and the egg price ramp (Eggs.RunOpened) for a permanent payout
-- multiplier (Formulas.prestigeMultiplier, applied in CaseService and RewardsService). Their hatched
-- LAWYERS are kept (lawyers in offices that go away return to the inventory), as are eggs, streaks,
-- goals and stats.
-- The firm is rebuilt exactly like a firm upgrade does (DeskService.upgradeFirm).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local CaseService = require(script.Parent.CaseService)
local DeskService = require(script.Parent.DeskService)
local ManagerService = require(script.Parent.ManagerService)

local PrestigeRemote = ReplicatedStorage.Remotes.Prestige :: RemoteFunction
local RewardGranted = ReplicatedStorage.Remotes.RewardGranted :: RemoteEvent

local COOLDOWN = 2

local PrestigeService = {}

local lastRequest: { [Player]: number } = {}

local function prestige(player: Player): (boolean, string?)
	local t = os.clock()
	if t - (lastRequest[player] or 0) < COOLDOWN then
		return false, "Slow down!"
	end
	lastRequest[player] = t
	local data = PlayerData.get(player)
	if not data or not PlotService.getFirm(player) then
		return false, "Still loading"
	end
	local working = 0
	for _, office in data.Desks do
		if office.Lawyer then
			working += 1
		end
	end
	data.Prestige = data.Prestige or { Level = 0 }
	local cost, offices = Formulas.prestigeRequirement(data.Prestige.Level)
	if working < offices then
		return false, string.format("Put lawyers in %d offices first", offices)
	end
	if data.Coins < cost then
		return false, string.format("You need %s coins", Formulas.formatCoins(cost))
	end

	data.Prestige.Level += 1
	-- (spawned: badge calls yield / can throw - a throw here used to leave the new level without the reset)
	task.spawn(require(script.Parent.BadgeAwards).award, player, "Supreme")
	data.Coins = 0
	data.Eggs.RunOpened = 0 -- eggs start cheap again (x Config.Eggs.PrestigePriceScale per level)
	-- back to the starting firm: its offices at level 1; the lawyers in them stay put
	local keep = Config.Firm.StartSegments * 2
	local offices = {}
	for index = 1, keep do
		local office = PlayerData.newDesk()
		office.Lawyer = data.Desks[index] and data.Desks[index].Lawyer
		table.insert(offices, office)
	end
	data.Desks = offices
	data.Firm = { Segments = Config.Firm.StartSegments }
	data.Manager = { Hired = false, Levels = {} }
	-- the Law License goes with the firm (user's call); the bag, the shoes and any carried eggs stay
	if data.Zones then
		data.Zones.License = 0
	end
	PlayerData.sync(player)
	require(script.Parent.ZoneService).sync(player)

	CaseService.stop(player)
	local firm = PlotService.rebuild(player)
	if firm then
		DeskService.buildDesks(player)
		CaseService.start(player, firm)
		DeskService.dress(player)
		ManagerService.setupFirm(player)
	end
	RewardGranted:FireClient(player, {
		kind = "Prestige",
		text = string.format("Payouts x%s forever!", tostring(Formulas.prestigeMultiplier(data.Prestige.Level))),
		level = data.Prestige.Level,
	})
	return true, nil
end

function PrestigeService.start()
	PrestigeRemote.OnServerInvoke = prestige
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return PrestigeService
