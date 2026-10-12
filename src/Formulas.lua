--!strict
-- Pure economy math. No side effects, no Instances: every random roll takes a Random so the
-- server and the simulator get identical behavior (and the sim is reproducible with a seed).

local Config = require(script.Parent.Config)

export type Outcome = "Win" | "Settlement" | "Mistrial"

-- One source of bonuses (a skin, a desk, the courtroom...). All fields are additive.
export type BuffSource = {
	payout: number?,
	winChance: number?,
	caseTime: number?,
	xp: number?,
}

-- A skill a lawyer owns (saved in PlayerData Desks[i].Skills).
export type OwnedSkill = { Id: string, Level: number, Param: number? }

export type Buffs = {
	payoutMultiplier: number,
	winChanceBonus: number,
	caseTimeMultiplier: number,
	xpMultiplier: number,
}

local Formulas = {}

function Formulas.pickWeighted(rng: Random, weights: { number }): number
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = rng:NextNumber() * total
	for index, weight in weights do
		roll -= weight
		if roll < 0 then
			return index
		end
	end
	return #weights
end

function Formulas.clientWeights(): { number }
	local weights = {}
	for index, client in Config.Clients do
		weights[index] = client.Weight
	end
	return weights
end

function Formulas.skinWeights(): { number }
	local weights = {}
	for index, skin in Config.Eggs.Skins do
		weights[index] = skin.Weight
	end
	return weights
end

function Formulas.rollClient(rng: Random, weights: { number }?): number
	return Formulas.pickWeighted(rng, weights or Formulas.clientWeights())
end

function Formulas.rollSkin(rng: Random, weights: { number }?): number
	return Formulas.pickWeighted(rng, weights or Formulas.skinWeights())
end

local skinsById: { [string]: Config.Skin } = {}
for _, skin in Config.SkinCatalog do
	skinsById[skin.Id] = skin
end

function Formulas.getSkin(id: string?): Config.Skin?
	return if id then skinsById[id] else nil
end

-- Picks evenly among the catalog skins of one rarity that this egg hatches (egg nil = the normal egg,
-- which never hatches skins tagged for another egg, e.g. Egg = "Brainrot").
function Formulas.rollSkinId(rng: Random, rarity: number, egg: string?): string
	local pool = {}
	for _, skin in Config.SkinCatalog do
		if skin.Rarity == rarity and skin.Egg == egg then
			table.insert(pool, skin.Id)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- A themed egg's definition (Config.Eggs.Themed) by Id, or nil.
function Formulas.themedEgg(id: string?): any
	for _, def in Config.Eggs.Themed do
		if def.Id == id then
			return def
		end
	end
	return nil
end

-- Egg tiers: a themed egg's machine works once the player's lifetime coins earned (Stats.CoinsEarned) reach its
-- UnlockEarned. The Briefcase Egg (id nil) and eggs without UnlockEarned are always open.
function Formulas.eggUnlocked(id: string?, earned: number?): boolean
	local def = Formulas.themedEgg(id)
	return def == nil or def.UnlockEarned == nil or (earned or 0) >= def.UnlockEarned
end

-- Themed egg price: its PriceMultiplier x the Briefcase Egg's price at the same opened count.
function Formulas.themedEggPrice(id: string, opened: number, prestige: number?): number
	local def = Formulas.themedEgg(id)
	return math.floor(Formulas.eggPrice(opened, prestige) * (if def then def.PriceMultiplier else 1))
end

-- Luck: the Config.Eggs.LuckRarities chances x luck, paid for out of the LuckPaidBy rarities (proportionally) so
-- the total stays the same and every other rarity - Mythic, Supreme - keeps its exact odds. When the payers don't
-- have enough weight, the boost is capped at all of it. luck <= 1 returns the weights unchanged.
function Formulas.luckyWeights(weights: { number }, luck: number?): { number }
	local l = luck or 1
	if l <= 1 then
		return weights
	end
	local boosted, payers = {}, {}
	for _, id in Config.Eggs.LuckRarities or {} do
		boosted[id] = true
	end
	for _, id in Config.Eggs.LuckPaidBy or {} do
		payers[id] = true
	end
	local extra, available = 0, 0
	for index, tier in Config.Eggs.Skins do
		local w = weights[index] or 0
		if boosted[tier.Id] then
			extra += w * (l - 1)
		elseif payers[tier.Id] then
			available += w
		end
	end
	if extra <= 0 or available <= 0 then
		return weights
	end
	local give = math.min(extra, available)
	local out = table.clone(weights)
	for index, tier in Config.Eggs.Skins do
		local w = weights[index] or 0
		if boosted[tier.Id] then
			out[index] = w + w * (l - 1) * (give / extra)
		elseif payers[tier.Id] then
			out[index] = w - w * (give / available)
		end
	end
	return out
end

-- Payout bonus a lawyer gets from the skin they wear (0 with no skin). (Old skin system.)
function Formulas.skinPayoutBonus(id: string?): number
	local skin = Formulas.getSkin(id)
	return if skin then Config.Eggs.Skins[skin.Rarity].PayoutBonus else 0
end

-- Hatched lawyers ------------------------------------------------------------------

-- A lawyer's earning power: rarity Earn x star multiplier x the EarnMultiplier of the egg that hatches it (egg
-- tiers: later themed eggs hatch stronger lawyers; Briefcase lawyers x1). Multiplies every case payout.
function Formulas.lawyerEarn(id: string?, stars: number?): number
	local def = Formulas.getSkin(id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	local starEarn = Config.Lawyers.StarEarn[math.clamp(stars or 1, 1, #Config.Lawyers.StarEarn)]
	local egg = def and Formulas.themedEgg(def.Egg)
	local eggEarn = if egg and egg.EarnMultiplier then egg.EarnMultiplier else 1
	return (if rarity then rarity.Earn else 1) * starEarn * eggEarn
end

-- "Gold Bow Tie Barrister" etc.
function Formulas.lawyerName(id: string?, stars: number?): string
	local def = Formulas.getSkin(id)
	local prefix = Config.Lawyers.StarNames[stars or 1] or ""
	local name = if def then def.Name else "Lawyer"
	return if prefix ~= "" then prefix .. " " .. name else name
end

-- Index into Config.Desks.Tiers an office has reached at this level.
function Formulas.officeTier(level: number): number
	local tier = 1
	for index, def in Config.Desks.Tiers do
		if level >= def.MinLevel then
			tier = index
		end
	end
	return tier
end

-- Price of the next egg after `opened` paid eggs.
-- opened = eggs opened since the last Supreme (Eggs.RunOpened); prestige = Supreme level (Config.Eggs.PrestigePriceScale)
function Formulas.eggPrice(opened: number, prestige: number?): number
	return math.floor(Config.Eggs.Price * (Config.Eggs.PriceGrowth or 1) ^ math.max(opened, 0)
		* (Config.Eggs.PrestigePriceScale or 1) ^ (prestige or 0))
end

-- Adds every source together, then clamps to Config.Caps.
function Formulas.combineBuffs(sources: { BuffSource }): Buffs
	local payout, winChance, caseTime, xp = 0, 0, 0, 0
	for _, source in sources do
		payout += source.payout or 0
		winChance += source.winChance or 0
		caseTime += source.caseTime or 0
		xp += source.xp or 0
	end
	local caps = Config.Caps
	return {
		payoutMultiplier = math.min(1 + payout, caps.PayoutMultiplier),
		winChanceBonus = math.min(winChance, caps.WinChanceBonus),
		caseTimeMultiplier = math.max(1 - caseTime, 1 - caps.CaseTimeReduction),
		xpMultiplier = math.min(1 + xp, caps.XpMultiplier),
	}
end

function Formulas.basePayout(level: number): number
	return Config.Payout.Base * Config.Payout.Growth ^ level
end

function Formulas.winChance(level: number, difficulty: number, bonus: number?): number
	local outcome = Config.Outcome
	local chance = outcome.BaseWinChance + (level - difficulty) * outcome.PerSkillPoint + (bonus or 0)
	return math.clamp(chance, outcome.MinWinChance, outcome.MaxWinChance)
end

-- Returns the outcome and the fraction of the full payout it earns.
function Formulas.rollOutcome(rng: Random, winChance: number): (Outcome, number)
	local roll = rng:NextNumber()
	if roll < winChance or winChance >= 1 then
		return "Win", 1
	end
	local nonWinRoll = (roll - winChance) / (1 - winChance)
	if nonWinRoll < Config.Outcome.SettlementShareOfNonWins then
		return "Settlement", rng:NextNumber(Config.Payout.SettlementMin, Config.Payout.SettlementMax)
	end
	return "Mistrial", 0
end

function Formulas.casePayout(level: number, client: Config.ClientTier, buffs: Buffs, fraction: number): number
	return math.floor(Formulas.basePayout(level) * client.Multiplier * buffs.payoutMultiplier * fraction)
end

function Formulas.caseDuration(client: Config.ClientTier, buffs: Buffs): number
	return client.Duration * buffs.caseTimeMultiplier
end

-- Seconds between clients walking into a firm with this many lawyers (bigger firms draw more clients).
function Formulas.clientInterval(lawyers: number): number
	local firm = Config.Firm
	return math.max(firm.MinInterval, firm.ClientInterval * firm.StartLawyers / math.max(lawyers, 1))
end

-- Coins to train a lawyer from `level` to `level + 1`.
function Formulas.trainCost(level: number): number
	return math.floor(Config.Lawyer.TrainBase * Config.Lawyer.TrainGrowth ^ level)
end

-- Average coins per second one lawyer earns, accounting for client odds, outcome odds,
-- settlement size, mistrial reruns and the gap between clients. Excludes courtroom bonuses.
function Formulas.expectedIncomePerSecond(level: number, buffs: Buffs, clientWeights: { number }?): number
	local weights = clientWeights or Formulas.clientWeights()
	local outcome = Config.Outcome
	local averageSettlement = (Config.Payout.SettlementMin + Config.Payout.SettlementMax) / 2
	local coins, seconds = 0, 0
	for index, client in Config.Clients do
		local weight = weights[index]
		local win = Formulas.winChance(level, client.Difficulty, buffs.winChanceBonus)
		local settlement = (1 - win) * outcome.SettlementShareOfNonWins
		local mistrial = 1 - win - settlement
		local payout = Formulas.basePayout(level) * client.Multiplier * buffs.payoutMultiplier
		coins += weight * payout * (win + settlement * averageSettlement)
		seconds += weight * (Formulas.caseDuration(client, buffs) / (1 - mistrial) + Config.Case.ArrivalDelay)
	end
	return coins / seconds
end

-- Lawyer skills -----------------------------------------------------------------

local skillDefs: { [string]: Config.SkillDef } = {}
for _, def in Config.Skills.Catalog do
	skillDefs[def.Id] = def
end

function Formulas.getSkillDef(id: string?): Config.SkillDef?
	return if id then skillDefs[id] else nil
end

function Formulas.skillValue(skill: OwnedSkill): number
	local def = skillDefs[skill.Id]
	return if def then def.PerLevel * math.clamp(skill.Level, 1, Config.Skills.MaxLevel) else 0
end

-- Buff sources from a lawyer's skills for a case with this client tier (nil = no client yet).
function Formulas.skillSources(skills: { OwnedSkill }?, clientTier: number?): { BuffSource }
	local sources = {}
	for _, skill in skills or {} do
		local def = skillDefs[skill.Id]
		local value = Formulas.skillValue(skill)
		if not def then
			continue
		elseif def.Effect == "payout" then
			table.insert(sources, { payout = value })
		elseif def.Effect == "caseTime" then
			table.insert(sources, { caseTime = value })
		elseif def.Effect == "winChance" then
			table.insert(sources, { winChance = value })
		elseif def.Effect == "specialist" and clientTier ~= nil and skill.Param == clientTier then
			table.insert(sources, { payout = value })
		end
	end
	return sources
end

-- Client spawn weights for a lawyer: Charming (and the Manager's Referral Network, passed as
-- extraBoost) boost every client rarer than Common.
function Formulas.clientWeightsFor(skills: { OwnedSkill }?, extraBoost: number?): { number }
	local weights = Formulas.clientWeights()
	local boost = extraBoost or 0
	for _, skill in skills or {} do
		local def = skillDefs[skill.Id]
		if def and def.Effect == "rareClients" then
			boost += Formulas.skillValue(skill)
		end
	end
	for index = 2, #weights do
		weights[index] *= 1 + boost
	end
	return weights
end

function Formulas.skillRollCost(paidRolls: number): number
	return math.floor(Config.Skills.RollBase * Config.Skills.RollGrowth ^ paidRolls)
end

-- One line describing what a skill does at its level, e.g. "+10% case payouts".
function Formulas.describeSkill(skill: OwnedSkill): string
	local def = skillDefs[skill.Id]
	if not def then
		return ""
	end
	local percent = math.round(Formulas.skillValue(skill) * 100)
	if def.Effect == "specialist" then
		local client = Config.Clients[skill.Param or 1]
		return string.format(def.Text, percent, if client then client.Name else "one client")
	end
	return string.format(def.Text, percent)
end

-- Rolls a skill for a lawyer. Skills they already have at max level are left out of the pool, and
-- rarities with nothing left fall away. Returns nil when every skill is maxed.
-- Param is the client tier for Specialist (kept from the owned copy when it's a level-up).
function Formulas.rollSkill(rng: Random, owned: { OwnedSkill }): (string?, number?)
	local ownedById: { [string]: OwnedSkill } = {}
	for _, skill in owned do
		ownedById[skill.Id] = skill
	end
	local pools: { { string } } = {}
	for _, def in Config.Skills.Catalog do
		local have = ownedById[def.Id]
		if not have or have.Level < Config.Skills.MaxLevel then
			pools[def.Rarity] = pools[def.Rarity] or {}
			table.insert(pools[def.Rarity], def.Id)
		end
	end
	local weights = {}
	for rarity, weight in Config.Skills.RarityWeights do
		weights[rarity] = if pools[rarity] then weight else 0
	end
	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		return nil, nil
	end
	local pool = pools[Formulas.pickWeighted(rng, weights)]
	local id = pool[rng:NextInteger(1, #pool)]
	local def = skillDefs[id]
	local param: number? = nil
	if def.Effect == "specialist" then
		param = if ownedById[id] then ownedById[id].Param else rng:NextInteger(1, #Config.Clients)
	end
	return id, param
end

-- Manager upgrades ---------------------------------------------------------------

local managerDefs: { [string]: { [string]: any } } = {}
for _, def in Config.Manager.Upgrades do
	managerDefs[def.Id] = def
end

function Formulas.getManagerUpgrade(id: string): { [string]: any }?
	return managerDefs[id]
end

-- Total effect value of one upgrade kind at the player's levels ({ [id] = level }).
function Formulas.managerValue(levels: { [string]: number }?, effect: string): number
	local total = 0
	for id, level in levels or {} do
		local def = managerDefs[id]
		if def and def.Effect == effect then
			total += def.PerLevel * math.clamp(level, 0, def.MaxLevel)
		end
	end
	return total
end

-- Buff sources from Manager upgrades (apply to every lawyer).
function Formulas.managerSources(levels: { [string]: number }?): { BuffSource }
	return {
		{ caseTime = Formulas.managerValue(levels, "caseTime"), winChance = Formulas.managerValue(levels, "winChance") },
	}
end

function Formulas.managerUpgradeCost(id: string, level: number): number
	local def = managerDefs[id]
	return if def then math.floor(def.Base * def.Growth ^ level) else math.huge
end

-- "Cases finish 8% faster" for an upgrade at a level (level 0 shows the first level's effect).
function Formulas.describeManagerUpgrade(id: string, level: number): string
	local def = managerDefs[id]
	if not def then
		return ""
	end
	local value = def.PerLevel * math.max(level, 1) * 100
	local text = if value % 1 == 0 then string.format("%d%%", value) else string.format("%.1f%%", value)
	return string.format(def.Text, text)
end

-- Prestige: permanent payout multiplier (applied on top of capped buffs).
function Formulas.prestigeMultiplier(level: number?): number
	return 1 + (level or 0) * Config.Prestige.PayoutBonusPerLevel
end

-- What going Supreme from `level` takes: coins (spent) and offices with a lawyer working in them.
function Formulas.prestigeRequirement(level: number?): (number, number)
	local p = Config.Prestige
	local l = level or 0
	local offices = math.min(p.RequiredDesks, (p.OfficesBase or p.RequiredDesks) + (p.OfficesPerLevel or 0) * l)
	return math.floor((p.CostBase or 0) * (p.CostGrowth or 1) ^ l), offices
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Formulas.formatCoins(amount: number): string
	local index = 1
	while math.abs(amount) >= 1000 and index < #SUFFIXES do
		amount /= 1000
		index += 1
	end
	if index == 1 then
		return tostring(math.floor(amount))
	end
	return string.format("%.2f%s", amount, SUFFIXES[index])
end

return Formulas
