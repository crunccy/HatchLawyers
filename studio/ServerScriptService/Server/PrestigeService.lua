--!strict
-- Prestige ("Supreme Empire", Config.Prestige). With a lawyer in every office of a fully expanded firm,
-- a player can reset coins, office levels, the firm size and the Manager for a permanent payout
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
	if working < Config.Prestige.RequiredDesks then
		return false, string.format("Fill %d offices with lawyers first", Config.Prestige.RequiredDesks)
	end

	data.Prestige = data.Prestige or { Level = 0 }
	data.Prestige.Level += 1
	require(script.Parent.BadgeAwards).award(player, "Supreme")
	data.Coins = 0
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
