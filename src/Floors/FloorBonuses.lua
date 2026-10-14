--!strict
-- FloorBonuses (ServerScriptService.Server.FloorBonuses; 2026-10-13, the upstairs rooms - Config.Floors) - the rooms'
-- lasting effects on cases, kept apart from ServerScriptService.FloorRooms so the core can use them without loops:
--   * Hall of Fame: every egg whose whole set of lawyers you've owned = +Index.SetBonus payouts
--   * Case Files Archive: wins counted by client type (CaseService calls onWin); every milestone = +PerMilestone payouts
--   * Guest Lounge: a visit buff (+Lounge.Buff payouts for a few minutes; FloorRooms sets loungeUntil)
-- FirmFeatures.buffSources adds sources() to the bought areas' bonuses, so CaseService applies them like any area.
-- Saved in data.Floors (PlayerData v18): Index = { [lawyerId] = best mutation tier }, CaseFiles = { ["tier"] = wins }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript) :: any
local CFG = Config.Floors

local FloorBonuses = {}

-- Guest Lounge visit buffs (server memory): player -> os.clock() it ends
FloorBonuses.loungeUntil = {} :: { [Player]: number }

-- the egg sets: egg id ("Briefcase" for the normal egg) -> its lawyer ids, in catalog order
local SETS: { [string]: { string } } = {}
local ORDER: { string } = {}
for _, skin in Config.SkinCatalog do
	local egg = skin.Egg or "Briefcase"
	if not SETS[egg] then
		SETS[egg] = {}
		table.insert(ORDER, egg)
	end
	table.insert(SETS[egg], skin.Id)
end
FloorBonuses.SETS = SETS
FloorBonuses.SET_ORDER = ORDER

local function floors(data: any): any
	return data and data.Floors
end

-- how many lawyers of an egg's set you've owned
function FloorBonuses.setProgress(data: any, egg: string): (number, number)
	local index = (floors(data) and floors(data).Index) or {}
	local ids = SETS[egg] or {}
	local have = 0
	for _, id in ids do
		if index[id] then
			have += 1
		end
	end
	return have, #ids
end

function FloorBonuses.completeSets(data: any): number
	local n = 0
	for egg in SETS do
		local have, total = FloorBonuses.setProgress(data, egg)
		if total > 0 and have >= total then
			n += 1
		end
	end
	return n
end

-- milestones reached for one client type, and in total
function FloorBonuses.milestonesFor(wins: number): number
	local n = 0
	for _, m in CFG.Archive.Milestones do
		if wins >= m then
			n += 1
		end
	end
	return n
end
function FloorBonuses.totalMilestones(data: any): number
	local files = (floors(data) and floors(data).CaseFiles) or {}
	local n = 0
	for _, wins in files do
		n += FloorBonuses.milestonesFor(wins)
	end
	return n
end

-- the rooms' payout bonus right now (a share: 0.1 = +10%)
function FloorBonuses.payoutBonus(player: Player?, data: any): number
	if not floors(data) then
		return 0
	end
	local bonus = FloorBonuses.completeSets(data) * CFG.Index.SetBonus + FloorBonuses.totalMilestones(data) * CFG.Archive.PerMilestone
	if player and (FloorBonuses.loungeUntil[player] or 0) > os.clock() then
		bonus += CFG.Lounge.Buff
	end
	return bonus
end

-- buff sources in Formulas' format, for FirmFeatures.buffSources
function FloorBonuses.sources(player: Player?, data: any): { { [string]: number } }
	local payout = FloorBonuses.payoutBonus(player, data)
	if payout <= 0 then
		return {}
	end
	return { { payout = payout, caseTime = 0, winChance = 0 } }
end

-- CaseService: a case was won against a client of this tier
function FloorBonuses.onWin(data: any, tier: number)
	local f = floors(data)
	if f and type(tier) == "number" then
		f.CaseFiles = f.CaseFiles or {}
		local key = tostring(tier)
		f.CaseFiles[key] = (f.CaseFiles[key] or 0) + 1
	end
end

-- records a lawyer as owned (and its best mutation tier) in the Hall of Fame
function FloorBonuses.record(data: any, id: string?, stars: number?)
	local f = floors(data)
	if f and type(id) == "string" then
		f.Index = f.Index or {}
		f.Index[id] = math.max(f.Index[id] or 0, stars or 1)
	end
end

return FloorBonuses
