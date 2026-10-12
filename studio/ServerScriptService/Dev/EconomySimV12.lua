--!strict
-- Economy simulator for the v12 game ("hatch real lawyers"). Dev-only: live code must never require it.
-- Plays a "typical kid" second by second with a fixed seed and reports pacing against Config.Pacing:
--   * tutorial: first client + court (~35s), the free office upgrade, the free egg (~60s, Uncommon)
--   * clients walk in every Formulas.clientInterval(lawyers) s while a waiting seat is free (SEATS);
--     the rarest waiting client goes to the best free lawyer (what the Manager / a busy kid does)
--   * eggs: rising price (Formulas.eggPrice), rarity odds + pity, starting skills; hatched lawyers fill
--     empty offices, then replace the weakest; 3 copies merge into +1 star (Config.Lawyers)
--   * spending: fill empty offices with eggs, ~1 extra egg every 10 min, save for firm expansions when
--     close, otherwise the cheapest of office training / skill rolls / Manager purchases
--   * playtime gifts and goals are paid like the live game (average goal reward every GOAL_EVERY s)
-- Run: print(require(game.ServerScriptService.Dev.EconomySimV12).run())

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- only: run just this profile (faster tuning runs)
export type Options = { seed: number?, Config: any?, Formulas: any?, hours: number?, only: string? }

local SEATS = 10 -- FirmBuilder.SEATS
local WALK = 4 -- seconds a client takes to walk from the waiting room to a desk
local SAVE_HORIZON = 5 * 60
local GOAL_EVERY = 5 * 60
local HOUR = 3600
local SNAPSHOTS = { HOUR, 6 * HOUR, 12 * HOUR, 24 * HOUR }
local DEFAULT_SEED = 20261008

type Lawyer = { id: string, rarity: number, stars: number, skills: { any }, cases: number, freeRolls: number, paidRolls: number }
type Office = { level: number, lawyer: Lawyer?, client: number?, remaining: number, attended: boolean }
type Profile = { name: string, attendRate: number, correctRate: number, rarityWeights: { number }? }

local PROFILES: { Profile } = {
	{ name = "Ordinary", attendRate = 0.3, correctRate = 0.7 },
	{ name = "Lucky", attendRate = 0.3, correctRate = 0.7, rarityWeights = { 40, 32, 22, 6 } },
}

local EconomySim = {}

local function clock(seconds: number?): string
	if not seconds then
		return "--"
	end
	if seconds >= HOUR then
		return string.format("%dh%02dm", seconds // HOUR, (seconds % HOUR) // 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function simulate(Config: any, Formulas: any, profile: Profile, seed: number, duration: number)
	local rng = Random.new(seed)
	local clients = Config.Clients
	local rarities = Config.Eggs.Skins
	local top = #rarities

	-- catalog by rarity
	local byRarity: { { string } } = {}
	for _, def in Config.SkinCatalog do
		byRarity[def.Rarity] = byRarity[def.Rarity] or {}
		table.insert(byRarity[def.Rarity], def.Id)
	end

	local coins = 0
	local eggsOpened, sinceTop, merges = 0, 0, 0
	local segments = Config.Firm.StartSegments
	local managerHired = false
	local managerLevels: { [string]: number } = {}
	local firstEgg: number?, incomeAtFirstEgg: number?, secondLawyer: number?, firstExpand: number?
	local billion: number?, trillion: number? = nil, nil
	local wins, settlements, mistrials = 0, 0, 0
	local snapshots = {}
	local inventory: { Lawyer } = {}
	local offices: { Office } = {}
	local waiting: { number } = {} -- client tiers
	local nextArrival = 8 -- the first client walks in a few seconds after the player arrives
	local tutorialDone = false
	local freeEggAt = 60

	local function rarityOf(id: string): number
		local def = Formulas.getSkin(id)
		return if def then def.Rarity else 1
	end

	local function newLawyer(id: string, startSkills: boolean): Lawyer
		local l: Lawyer = { id = id, rarity = rarityOf(id), stars = 1, skills = {}, cases = 0, freeRolls = 0, paidRolls = 0 }
		if startSkills then
			for _ = 1, rarities[l.rarity].StartSkills or 1 do
				local sid, param = Formulas.rollSkill(rng, l.skills)
				if not sid then
					break
				end
				local owned = nil
				for _, s in l.skills do
					if s.Id == sid then
						owned = s
					end
				end
				if owned then
					owned.Level = math.min(owned.Level + 1, Config.Skills.MaxLevel)
				else
					table.insert(l.skills, { Id = sid, Level = 1, Param = param })
				end
			end
		end
		return l
	end

	local function earn(l: Lawyer?): number
		return if l then Formulas.lawyerEarn(l.id, l.stars) else 0
	end

	local function addOffices(n: number)
		for _ = 1, n do
			table.insert(offices, { level = Config.Lawyer.StartLevel, lawyer = nil, client = nil, remaining = 0, attended = false })
		end
	end
	addOffices(segments * 2)
	offices[1].lawyer = newLawyer(Config.Lawyers.StartId, false)

	local function working(): number
		local n = 0
		for _, o in offices do
			if o.lawyer then
				n += 1
			end
		end
		return n
	end

	local function sources(o: Office, clientTier: number?, extra: number?): { any }
		local list: { any } = { { payout = Config.Desks.Tiers[Formulas.officeTier(o.level)].PayoutBonus } }
		for _, s in Formulas.skillSources(o.lawyer and o.lawyer.skills, clientTier) do
			table.insert(list, s)
		end
		for _, s in Formulas.managerSources(managerLevels) do
			table.insert(list, s)
		end
		if extra then
			table.insert(list, { payout = extra })
		end
		return list
	end

	-- expected coins/second if every lawyer stays busy (used for gifts, goals, retainer and reporting)
	local function income(): number
		local total = 0
		local referral = Formulas.managerValue(managerLevels, "rareClients")
		for _, o in offices do
			if o.lawyer then
				local weights = Formulas.clientWeightsFor(o.lawyer.skills, referral)
				total += Formulas.expectedIncomePerSecond(o.level, Formulas.combineBuffs(sources(o)), weights) * earn(o.lawyer)
			end
		end
		return total
	end

	-- best placement: strongest lawyers in the offices (inventory holds the rest), then merges
	local function reorganize()
		-- merge 3 copies of the same lawyer at the same stars
		local all: { Lawyer } = {}
		for _, o in offices do
			if o.lawyer and not o.client then -- lawyers mid-case merge after the case
				table.insert(all, o.lawyer)
			end
		end
		for _, l in inventory do
			table.insert(all, l)
		end
		local groups: { [string]: { Lawyer } } = {}
		for _, l in all do
			local key = l.id .. "*" .. l.stars
			groups[key] = groups[key] or {}
			table.insert(groups[key], l)
		end
		local merged = false
		for _, group in groups do
			while #group >= Config.Lawyers.MergeCount and group[1].stars < #Config.Lawyers.StarEarn do
				local keep = table.remove(group, 1) :: Lawyer
				for _ = 2, Config.Lawyers.MergeCount do
					local gone = table.remove(group, 1) :: Lawyer
					for _, o in offices do
						if o.lawyer == gone then
							o.lawyer = nil
						end
					end
					local i = table.find(inventory, gone)
					if i then
						table.remove(inventory, i)
					end
				end
				keep.stars += 1
				merges += 1
				merged = true
			end
		end
		-- fill / upgrade offices: strongest earners into offices (busy offices keep their lawyer)
		table.sort(inventory, function(a, b)
			return earn(a) > earn(b)
		end)
		for _, o in offices do
			if not o.lawyer and #inventory > 0 then
				o.lawyer = table.remove(inventory, 1)
			end
		end
		local changed = true
		while changed and #inventory > 0 do
			changed = false
			local weakest: Office? = nil
			for _, o in offices do
				if o.lawyer and not o.client and (not weakest or earn(o.lawyer) < earn(weakest.lawyer)) then
					weakest = o
				end
			end
			if weakest and earn(inventory[1]) > earn(weakest.lawyer) then
				local better = table.remove(inventory, 1) :: Lawyer
				table.insert(inventory, weakest.lawyer :: Lawyer)
				weakest.lawyer = better
				table.sort(inventory, function(a, b)
					return earn(a) > earn(b)
				end)
				changed = true
			end
		end
		if merged then
			reorganize()
		end
	end

	local function hatch(t: number, forcedRarity: number?, paid: boolean)
		local rarity = forcedRarity
		if not rarity then
			local weights = {}
			for i, r in rarities do
				weights[i] = if profile.rarityWeights then profile.rarityWeights[i] or r.Weight else r.Weight
			end
			rarity = Formulas.pickWeighted(rng, weights)
		end
		if paid then
			sinceTop += 1
			if rarity ~= top and Config.Eggs.PityTop and sinceTop >= Config.Eggs.PityTop then
				rarity = top
			end
			if rarity == top then
				sinceTop = 0
			end
		end
		local pool = byRarity[rarity :: number] or byRarity[1]
		local l = newLawyer(pool[rng:NextInteger(1, #pool)], true)
		table.insert(inventory, l)
		reorganize()
		if not secondLawyer and working() >= 2 then
			secondLawyer = t
		end
	end

	local function buyEgg(t: number): boolean
		local price = Formulas.eggPrice(eggsOpened)
		if coins < price or #inventory + working() >= Config.Lawyers.MaxOwned then
			return false
		end
		coins -= price
		eggsOpened += 1
		hatch(t, nil, true)
		if not firstEgg then
			firstEgg = t
			incomeAtFirstEgg = income()
		end
		return true
	end

	local function rollSkill(l: Lawyer)
		local id, param = Formulas.rollSkill(rng, l.skills)
		if not id then
			return
		end
		for _, s in l.skills do
			if s.Id == id then
				s.Level = math.min(s.Level + 1, Config.Skills.MaxLevel)
				return
			end
		end
		local new = { Id = id, Level = 1, Param = param }
		if #l.skills < Config.Skills.MaxSlots then
			table.insert(l.skills, new)
			return
		end
		local weakest, weakestScore = 1, math.huge
		for i, s in l.skills do
			local score = Formulas.getSkillDef(s.Id).Rarity * 10 + s.Level
			if score < weakestScore then
				weakest, weakestScore = i, score
			end
		end
		if Formulas.getSkillDef(id).Rarity * 10 + 1 > weakestScore then
			l.skills[weakest] = new
		end
	end

	local function cheapestManager(): (string?, number)
		if not managerHired then
			return "hire", Config.Manager.HireCost
		end
		local best, bestCost = nil, math.huge
		for _, def in Config.Manager.Upgrades do
			local level = managerLevels[def.Id] or 0
			if level < def.MaxLevel then
				local cost = Formulas.managerUpgradeCost(def.Id, level)
				if cost < bestCost then
					best, bestCost = def.Id, cost
				end
			end
		end
		return best, bestCost
	end

	local function spend(t: number)
		for _, o in offices do
			if o.lawyer then
				while o.lawyer.freeRolls > 0 do
					o.lawyer.freeRolls -= 1
					rollSkill(o.lawyer)
				end
			end
		end
		if t < freeEggAt then
			return -- still in the tutorial
		end
		-- fill empty offices first (that's what the hints push), plus about one extra egg every 10 min
		local empty = working() < #offices
		if (empty or eggsOpened < t // 600) and buyEgg(t) then
			return spend(t)
		end
		if empty then
			return -- saving for the next egg
		end
		-- firm expansion
		local expandCost = if segments < Config.Firm.MaxSegments then Config.Firm.ExpandCosts[segments + 1] else nil
		if expandCost and coins >= expandCost then
			coins -= expandCost
			segments += 1
			addOffices(2)
			firstExpand = firstExpand or t
			return spend(t)
		end
		if expandCost and expandCost <= income() * SAVE_HORIZON then
			return
		end
		-- cheapest of: office training, a skill roll, a Manager purchase
		local bestCost, action = math.huge, nil :: (() -> ())?
		for _, o in offices do
			if o.lawyer and o.level < Config.Lawyer.MaxLevel then
				local cost = Formulas.trainCost(o.level)
				if cost < bestCost then
					bestCost, action = cost, function()
						o.level += 1
					end
				end
				local l = o.lawyer :: Lawyer
				local cost2 = Formulas.skillRollCost(l.paidRolls)
				if cost2 < bestCost and (#l.skills < Config.Skills.MaxSlots or true) then
					bestCost, action = cost2, function()
						l.paidRolls += 1
						rollSkill(l)
					end
				end
			end
		end
		local mid, mcost = cheapestManager()
		if mid and mcost < bestCost then
			bestCost, action = mcost, function()
				if mid == "hire" then
					managerHired = true
				else
					managerLevels[mid] = (managerLevels[mid] or 0) + 1
				end
			end
		end
		if action and coins >= bestCost then
			coins -= bestCost
			action()
			return spend(t)
		end
	end

	local function startCase(o: Office, tier: number)
		o.client = tier
		o.attended = rng:NextNumber() < profile.attendRate
		o.remaining = WALK + Formulas.caseDuration(clients[tier], Formulas.combineBuffs(sources(o, tier)))
	end

	local function resolve(o: Office)
		local tier = o.client :: number
		local client = clients[tier]
		local extra = if o.attended and rng:NextNumber() < profile.correctRate then Config.Courtroom.CorrectAnswerBonus else nil
		local buffs = Formulas.combineBuffs(sources(o, tier, extra))
		local outcome, fraction
		if not tutorialDone then
			outcome, fraction = "Win", 1
			tutorialDone = true
		else
			outcome, fraction = Formulas.rollOutcome(rng, Formulas.winChance(o.level, client.Difficulty, buffs.winChanceBonus))
			if outcome == "Mistrial" and rng:NextNumber() < Formulas.managerValue(managerLevels, "settle") then
				outcome, fraction = "Settlement", rng:NextNumber(Config.Payout.SettlementMin, Config.Payout.SettlementMax)
			end
		end
		coins += Formulas.casePayout(o.level, client, buffs, fraction) * earn(o.lawyer)
		local l = o.lawyer
		if not l then
			o.client = nil
			return
		end
		if outcome == "Win" then
			wins += 1
		elseif outcome == "Settlement" then
			settlements += 1
		else
			mistrials += 1
		end
		if outcome ~= "Mistrial" then
			l.cases += 1
			if l.cases % Config.Skills.CasesPerFreeRoll == 0 then
				l.freeRolls += 1
			end
			o.client = nil
		else
			o.remaining = Formulas.caseDuration(client, buffs) -- same client, case runs again
		end
	end

	for t = 1, duration do
		-- tutorial beats
		if t == 35 then
			offices[1].level += Config.Tutorial.FreeLevelUps
		end
		if t == freeEggAt and Config.Eggs.FreeFirstEgg then
			hatch(t, Config.Eggs.FirstEggRarity, false)
		end
		-- clients walk in
		nextArrival -= 1
		if nextArrival <= 0 then
			if #waiting < SEATS then
				local best = nil
				local bestLevel = -1
				for _, o in offices do
					if o.lawyer and o.level > bestLevel then
						best, bestLevel = o.lawyer, o.level
					end
				end
				local weights = Formulas.clientWeightsFor(best and best.skills, Formulas.managerValue(managerLevels, "rareClients"))
				table.insert(waiting, if t < 20 then 1 else Formulas.rollClient(rng, weights))
			end
			nextArrival = Formulas.clientInterval(math.max(working(), 1))
		end
		-- rarest waiting client to the best free lawyer
		while #waiting > 0 do
			local freeOffice: Office? = nil
			for _, o in offices do
				if o.lawyer and not o.client and (not freeOffice or earn(o.lawyer) * o.level > earn(freeOffice.lawyer) * freeOffice.level) then
					freeOffice = o
				end
			end
			if not freeOffice then
				break
			end
			local bestIndex = 1
			for i, tier in waiting do
				if tier > waiting[bestIndex] then
					bestIndex = i
				end
			end
			startCase(freeOffice, table.remove(waiting, bestIndex) :: number)
		end
		-- cases tick
		for _, o in offices do
			if o.client then
				o.remaining -= 1
				if o.remaining <= 0 then
					resolve(o)
				end
			end
		end
		-- passive income sources
		if t % 60 == 0 then
			local share = Formulas.managerValue(managerLevels, "retainer")
			if share > 0 then
				coins += income() * 60 * share
			end
		end
		if t % GOAL_EVERY == 0 and Config.Goals then
			local total = 0
			for _, goal in Config.Goals.List do
				total += goal.Minutes
			end
			coins += math.max(Config.Rewards.MinCoins, income() * 60 * total / #Config.Goals.List)
		end
		if t % Config.Rewards.PlaytimeInterval == 0 then
			coins += math.max(Config.Rewards.MinCoins, income() * 60 * Config.Rewards.PlaytimeMinutes)
		end
		spend(t)

		if t % 60 == 0 or table.find(SNAPSHOTS, t) then
			local rate = income()
			billion = billion or (if rate >= 1e9 then t else nil)
			trillion = trillion or (if rate >= 1e12 then t else nil)
			if table.find(SNAPSHOTS, t) then
				local topLevel, bestEarn = 0, 0
				for _, o in offices do
					topLevel = math.max(topLevel, o.level)
					bestEarn = math.max(bestEarn, earn(o.lawyer))
				end
				snapshots[t] = { income = rate, level = topLevel, offices = #offices, lawyers = working(), eggs = eggsOpened, bestEarn = bestEarn }
			end
		end
	end

	return {
		profile = profile.name,
		firstEgg = firstEgg,
		incomeAtFirstEgg = incomeAtFirstEgg,
		secondLawyer = secondLawyer,
		firstExpand = firstExpand,
		billion = billion,
		trillion = trillion,
		snapshots = snapshots,
		eggs = eggsOpened,
		merges = merges,
		wins = wins,
		settlements = settlements,
		mistrials = mistrials,
		managerHired = managerHired,
		segments = segments,
	}
end

function EconomySim.run(options: Options?): string
	local opts: Options = options or {}
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Config = opts.Config or require(Shared:WaitForChild("Config") :: ModuleScript)
	local Formulas = opts.Formulas or require(Shared:WaitForChild("Formulas") :: ModuleScript)
	local seed = opts.seed or DEFAULT_SEED
	local duration = math.floor((opts.hours or 24) * HOUR)
	local fmt = Formulas.formatCoins
	local function perSecond(rate: number?): string
		return if rate then fmt(rate) .. "/s" else "--"
	end

	local lines = { string.format("=== Hatch Lawyers v12 economy sim, seed %d ===", seed) }
	local results = {}
	for _, profile in PROFILES do
		if not opts.only or opts.only == profile.name then
			table.insert(results, simulate(Config, Formulas, profile, seed, duration))
		end
	end
	table.insert(lines, string.format("%-9s %7s %9s %8s %8s %7s %7s %5s %6s", "Profile", "1stEgg", "$/s@egg", "2ndLaw", "1stExp", "1B/s", "1T/s", "Eggs", "Merges"))
	for _, r in results do
		table.insert(lines, string.format("%-9s %7s %9s %8s %8s %7s %7s %5d %6d", r.profile, clock(r.firstEgg), perSecond(r.incomeAtFirstEgg), clock(r.secondLawyer), clock(r.firstExpand), clock(r.billion), clock(r.trillion), r.eggs, r.merges))
	end
	table.insert(lines, "")
	table.insert(lines, "Snapshots (income, top office level, lawyers/offices, eggs, best lawyer earn x):")
	for _, r in results do
		local cells = {}
		for _, t in SNAPSHOTS do
			local s = r.snapshots[t]
			if s then
				table.insert(cells, string.format("%dh %s L%d %d/%d e%d x%s", t // HOUR, perSecond(s.income), s.level, s.lawyers, s.offices, s.eggs, tostring(s.bestEarn)))
			end
		end
		table.insert(lines, r.profile .. ": " .. table.concat(cells, " | "))
	end

	local base = results[1]
	local pacing = Config.Pacing
	local function status(actual: number?, target: { number }?): string
		if not target then
			return "(no target)"
		elseif actual == nil then
			return "MISS (never)"
		elseif actual < target[1] then
			return "FAST"
		elseif actual > target[2] then
			return "SLOW"
		end
		return "OK"
	end
	table.insert(lines, "")
	table.insert(lines, "Pacing check (Ordinary) vs Config.Pacing:")
	table.insert(lines, string.format("  %-18s %8s  %s", "First paid egg", clock(base.firstEgg), status(base.firstEgg, pacing.FirstEgg)))
	table.insert(lines, string.format("  %-18s %8s  %s", "$/s at first egg", perSecond(base.incomeAtFirstEgg), status(base.incomeAtFirstEgg, pacing.IncomeAtFirstEgg)))
	table.insert(lines, string.format("  %-18s %8s  %s", "First expansion", clock(base.firstExpand), status(base.firstExpand, pacing.FirstExpand)))
	table.insert(lines, string.format("  %-18s %8s  %s", "1T/s income", clock(base.trillion), status(base.trillion, pacing.TrillionPerSecond)))
	return table.concat(lines, "\n")
end

return EconomySim
