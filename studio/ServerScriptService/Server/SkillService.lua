--!strict
-- Lawyer skills. RollSkill spends a free roll (earned every Config.Skills.CasesPerFreeRoll cases) or
-- coins, then either levels up a skill the lawyer has, fills an empty slot, or - when all slots are
-- full - parks the new skill as PendingSkill until ResolveSkill says which slot to replace (0 = keep
-- the old skills). The pending skill is saved, so leaving the game never loses a paid roll.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)

local Remotes = ReplicatedStorage.Remotes
local RollSkill = Remotes.RollSkill :: RemoteFunction
local ResolveSkill = Remotes.ResolveSkill :: RemoteFunction

local COOLDOWN = 0.4

local SkillService = {}

local rng = Random.new()
local lastRequest: { [Player]: number } = {}

export type RollResult = {
	ok: boolean,
	reason: string?,
	skill: Formulas.OwnedSkill?, -- what was rolled (its level after the roll)
	result: ("new" | "levelUp" | "pending")?,
}

local function throttled(player: Player): boolean
	local t = os.clock()
	if t - (lastRequest[player] or 0) < COOLDOWN then
		return true
	end
	lastRequest[player] = t
	return false
end

-- The LAWYER sitting in that office (skills belong to lawyers since v12); nil for an empty office.
local function getDesk(player: Player, deskIndex: unknown): PlayerData.LawyerData?
	local data = PlayerData.get(player)
	if not data or type(deskIndex) ~= "number" or deskIndex ~= deskIndex // 1 then
		return nil
	end
	local desk = PlayerData.lawyerAt(data, deskIndex)
	if desk then
		desk.Skills = desk.Skills or {}
		desk.SkillRolls = desk.SkillRolls or 0
		desk.FreeSkillRolls = desk.FreeSkillRolls or 0
	end
	return desk
end

local function roll(player: Player, deskIndex: unknown): RollResult
	if throttled(player) then
		return { ok = false, reason = "Slow down!" }
	end
	local desk = getDesk(player, deskIndex)
	if not desk then
		return { ok = false, reason = "Bad lawyer" }
	end
	if desk.PendingSkill then
		return { ok = false, reason = "Pick a slot first!", skill = desk.PendingSkill, result = "pending" }
	end
	local id, param = Formulas.rollSkill(rng, desk.Skills)
	if not id then
		return { ok = false, reason = "All skills maxed!" }
	end

	-- pay: a free roll if there is one, otherwise coins
	if desk.FreeSkillRolls > 0 then
		desk.FreeSkillRolls -= 1
	elseif PlayerData.spendCoins(player, Formulas.skillRollCost(desk.SkillRolls)) then
		desk.SkillRolls += 1
	else
		return { ok = false, reason = "Not enough coins" }
	end

	local outcome: RollResult
	local owned: Formulas.OwnedSkill? = nil
	for _, skill in desk.Skills do
		if skill.Id == id then
			owned = skill
		end
	end
	if owned then
		owned.Level = math.min(owned.Level + 1, Config.Skills.MaxLevel)
		outcome = { ok = true, skill = owned, result = "levelUp" }
	elseif #desk.Skills < Config.Skills.MaxSlots then
		local skill = { Id = id, Level = 1, Param = param }
		table.insert(desk.Skills, skill)
		outcome = { ok = true, skill = skill, result = "new" }
	else
		desk.PendingSkill = { Id = id, Level = 1, Param = param }
		outcome = { ok = true, skill = desk.PendingSkill, result = "pending" }
	end
	PlayerData.sync(player)
	require(script.Parent.GoalService).track(player, "skillRoll")
	return outcome
end

-- slot 1..MaxSlots replaces that skill with the pending one; 0 throws the pending skill away.
local function resolve(player: Player, deskIndex: unknown, slot: unknown): RollResult
	if throttled(player) then
		return { ok = false, reason = "Slow down!" }
	end
	local desk = getDesk(player, deskIndex)
	if not desk or not desk.PendingSkill then
		return { ok = false, reason = "Nothing to place" }
	end
	if type(slot) ~= "number" or slot ~= slot // 1 or slot < 0 or slot > #desk.Skills then
		return { ok = false, reason = "Bad slot" }
	end
	local pending = desk.PendingSkill :: Formulas.OwnedSkill
	desk.PendingSkill = nil
	if slot > 0 then
		desk.Skills[slot] = pending
	end
	PlayerData.sync(player)
	return { ok = true, skill = pending, result = "new" }
end

function SkillService.start()
	RollSkill.OnServerInvoke = roll
	ResolveSkill.OnServerInvoke = resolve
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return SkillService
