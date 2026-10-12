--!strict
-- LEGACY (pre-v12 hire-a-desk economy; use Dev.EconomySimV12 for the current game).
-- Economy simulator for the MVP loop. Dev-only: live game code must never require this.
-- Plays desk -> client -> case -> payout -> spend forward second by second with a fixed seed
-- and reports pacing against Config.Pacing.
--
-- Run it: enable ServerScriptService.Dev.RunEconomySim and press Run, or from the command bar:
--   print(require(game.ServerScriptService.Dev.EconomySim).run())

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Profile = {
	name: string,
	clientWeights: { number }?,
	skinWeights: { number }?,
	attendRate: number, -- chance the player watches a given case
	correctRate: number, -- chance they pick the right evidence card when watching
	maxed: boolean, -- every buff pinned at its cap
}

type Desk = {
	tier: number,
	level: number,
	client: number?,
	remaining: number,
	tutorialCase: boolean,
	skills: { any },
	paidRolls: number,
	freeRolls: number,
	cases: number,
}

type Result = {
	profile: string,
	startDesks: number,
	duration: number,
	firstEgg: number?,
	incomeAtFirstEgg: number?,
	nextDesk: number?,
	billion: number?,
	trillion: number?,
	snapshots: { [number]: { income: number, level: number, desks: number } },
	topLevel: number,
	endDesks: number,
	eggs: number,
	bestSkin: string,
	skillRolls: number,
	gifts: number,
	wins: number,
	settlements: number,
	mistrials: number,
}

export type Options = {
	seed: number?,
	Config: any?,
	Formulas: any?,
}

local PROFILES: { Profile } = {
	{ name = "Ordinary", attendRate = 0.3, correctRate = 0.7, maxed = false },
	{
		name = "Lucky",
		clientWeights = { 50, 35, 15 },
		skinWeights = { 20, 40, 40 },
		attendRate = 0.3,
		correctRate = 0.7,
		maxed = false,
	},
	{ name = "Max buffs", attendRate = 1, correctRate = 1, maxed = true },
}

local HOUR = 3600
-- desks = 0 means the starting firm (Config.Firm.StartLawyers lawyers).
local SCENARIOS = { { desks = 0, duration = 24 * HOUR } }
-- The waiting room (Config.Firm): seats, how fast an active player assigns clients by hand (the
-- Manager assigns as fast as lawyers free up), and the walk from the seat to the desk.
local SEATS = 10
local MANUAL_ASSIGNS_PER_SECOND = 0.5
local WALK_SECONDS = 6
local SNAPSHOTS = { HOUR, 6 * HOUR, 12 * HOUR, 24 * HOUR }
local DEFAULT_SEED = 20261007
-- The player saves for the next desk once it costs no more than this many seconds of income.
local SAVE_HORIZON = 5 * 60
-- Short-term goals: assume a typical player finishes one every GOAL_EVERY seconds of play, each
-- paying the average Config.Goals reward.
local GOAL_EVERY = 5 * 60

-- Large enough that every cap in Config.Caps binds.
local MAXED_SOURCE = { payout = 100, winChance = 1, caseTime = 1, xp = 100 }

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

local function simulate(Config: any, Formulas: any, profile: Profile, startDesks: number, duration: number, seed: number): Result
	local rng = Random.new(seed)
	if startDesks == 0 then
		startDesks = if Config.Firm then Config.Firm.StartLawyers else 1
	end
	local segments = if Config.Firm then Config.Firm.StartSegments else math.huge
	local queue: { number } = {} -- waiting clients' tiers
	local arrivalCredit, assignCredit = 0, 0
	local clients = Config.Clients
	-- A profile's custom client odds may predate newer clients: pad with 2x the normal weight
	-- (the Lucky profile is meant to see rarer clients more often).
	if profile.clientWeights and #profile.clientWeights < #clients then
		local padded = table.clone(profile.clientWeights)
		for i = #padded + 1, #clients do
			padded[i] = clients[i].Weight * 2
		end
		profile = table.clone(profile)
		profile.clientWeights = padded
	end
	local deskTiers = Config.Desks.Tiers
	local skins = Config.Eggs.Skins
	local eggPrice = Config.Eggs.Price

	local coins = 0
	local wins, settlements, mistrials = 0, 0, 0
	local eggsBought = 0
	local bestSkin = if Config.Eggs.FreeFirstEgg then Config.Eggs.FirstEggRarity else 1
	local firstEgg: number?, incomeAtFirstEgg: number?, nextDesk: number? = nil, nil, nil
	local billion: number?, trillion: number? = nil, nil
	local snapshots = {}

	local skillRolls, gifts = 0, 0
	local managerHired = false
	local managerLevels: { [string]: number } = {}
	local desks: { Desk } = {}
	local function addDesk(level: number)
		table.insert(desks, {
			tier = 1,
			level = level,
			client = nil,
			remaining = Config.Case.ArrivalDelay,
			tutorialCase = false,
			skills = {},
			paidRolls = 0,
			freeRolls = 0,
			cases = 0,
		})
	end
	for i = 1, startDesks do
		addDesk(Config.Lawyer.StartLevel + if i == 1 then Config.Tutorial.FreeLevelUps else 0)
	end
	if Config.Tutorial.FirstCaseGuaranteedWin then
		desks[1].client = 1
		desks[1].remaining = Config.Case.TutorialDuration
		desks[1].tutorialCase = true
	end

	local function clientWeightsFor(desk: Desk): { number }
		if profile.clientWeights then
			return profile.clientWeights
		end
		local referral = if Formulas.managerValue then Formulas.managerValue(managerLevels, "rareClients") else 0
		return if Formulas.clientWeightsFor then Formulas.clientWeightsFor(desk.skills, referral) else Formulas.clientWeights()
	end

	local function baseSources(desk: Desk, clientTier: number?): { any }
		local sources: { any } = {
			{ payout = skins[bestSkin].PayoutBonus },
			{ payout = deskTiers[desk.tier].PayoutBonus },
		}
		if Formulas.skillSources then
			for _, source in Formulas.skillSources(desk.skills, clientTier) do
				table.insert(sources, source)
			end
		end
		if Formulas.managerSources then
			for _, source in Formulas.managerSources(managerLevels) do
				table.insert(sources, source)
			end
		end
		if profile.maxed then
			table.insert(sources, MAXED_SOURCE)
		end
		return sources
	end

	-- Expected coins per second. With the waiting room, lawyers can't work faster than clients walk in
	-- (and, without a Manager, than the player assigns them), so the total is capped by that rate.
	local function income(): number
		local total, capacity = 0, 0
		for _, desk in desks do
			local buffs = Formulas.combineBuffs(baseSources(desk))
			local weights = clientWeightsFor(desk)
			total += Formulas.expectedIncomePerSecond(desk.level, buffs, weights)
			local w, secs = 0, 0
			for i, client in clients do
				w += weights[i]
				secs += weights[i] * (Formulas.caseDuration(client, buffs) + Config.Case.ArrivalDelay + WALK_SECONDS)
			end
			capacity += if secs > 0 then w / secs else 0
		end
		if Config.Firm and capacity > 0 then
			local rate = 1 / Formulas.clientInterval(#desks)
			if not managerHired then
				rate = math.min(rate, MANUAL_ASSIGNS_PER_SECOND)
			end
			if capacity > rate then
				total *= rate / capacity
			end
		end
		return total
	end

	local function bestDesk(): Desk
		local best = desks[1]
		for _, desk in desks do
			if desk.level > best.level then
				best = desk
			end
		end
		return best
	end

	local function resolveCase(desk: Desk)
		local client = clients[desk.client :: number]
		local sources = baseSources(desk, desk.client)
		if rng:NextNumber() < profile.attendRate and rng:NextNumber() < profile.correctRate then
			table.insert(sources, { payout = Config.Courtroom.CorrectAnswerBonus })
		end
		local buffs = Formulas.combineBuffs(sources)

		local outcome, fraction
		if desk.tutorialCase then
			outcome, fraction = "Win", 1
			desk.tutorialCase = false
		else
			local chance = Formulas.winChance(desk.level, client.Difficulty, buffs.winChanceBonus)
			outcome, fraction = Formulas.rollOutcome(rng, chance)
		end

		if outcome == "Mistrial" and Formulas.managerValue and rng:NextNumber() < Formulas.managerValue(managerLevels, "settle") then
			outcome, fraction = "Settlement", rng:NextNumber(Config.Payout.SettlementMin, Config.Payout.SettlementMax)
		end
		if outcome == "Win" then
			wins += 1
		elseif outcome == "Settlement" then
			settlements += 1
		else
			mistrials += 1
		end

		coins += Formulas.casePayout(desk.level, client, buffs, fraction)
		if outcome ~= "Mistrial" and Config.Skills then
			desk.cases += 1
			if desk.cases % Config.Skills.CasesPerFreeRoll == 0 then
				desk.freeRolls += 1
			end
		end

		if outcome == "Mistrial" then
			-- Same client requeues and the case runs again.
			desk.remaining = Formulas.caseDuration(client, Formulas.combineBuffs(baseSources(desk, desk.client)))
		else
			desk.client = nil
			desk.remaining = Config.Case.ArrivalDelay
		end
	end

	local function buyEgg(t: number)
		coins -= eggPrice
		eggsBought += 1
		bestSkin = math.max(bestSkin, Formulas.rollSkin(rng, profile.skinWeights))
		if not firstEgg then
			firstEgg = t
			incomeAtFirstEgg = income()
		end
	end

	-- A roll a typical kid makes: level-ups and empty slots are taken; with full slots a new skill
	-- replaces the weakest one (lowest rarity, then level) only if it's rarer.
	local function rollSkill(desk: Desk)
		if not Formulas.rollSkill then
			return
		end
		local id, param = Formulas.rollSkill(rng, desk.skills)
		if not id then
			return
		end
		skillRolls += 1
		for _, skill in desk.skills do
			if skill.Id == id then
				skill.Level = math.min(skill.Level + 1, Config.Skills.MaxLevel)
				return
			end
		end
		local new = { Id = id, Level = 1, Param = param }
		if #desk.skills < Config.Skills.MaxSlots then
			table.insert(desk.skills, new)
			return
		end
		local weakest, weakestScore = 1, math.huge
		for i, skill in desk.skills do
			local score = Formulas.getSkillDef(skill.Id).Rarity * 10 + skill.Level
			if score < weakestScore then
				weakest, weakestScore = i, score
			end
		end
		if Formulas.getSkillDef(id).Rarity * 10 + 1 > weakestScore then
			desk.skills[weakest] = new
		end
	end

	local function skillRollAvailable(desk: Desk): boolean
		if not Formulas.rollSkill then
			return false
		end
		if #desk.skills < Config.Skills.MaxSlots then
			return true
		end
		for _, skill in desk.skills do
			if skill.Level < Config.Skills.MaxLevel then
				return true
			end
		end
		return false
	end

	-- Cheapest Manager purchase (hire first), or nil.
	local function cheapestManager(): (string?, number)
		if not Config.Manager then
			return nil, math.huge
		end
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

	-- Cheapest thing to buy for an existing desk: a training level or a desk tier.
	local function cheapestUpgrade(): (Desk?, string, number)
		local best: Desk?, kind, bestCost = nil, "", math.huge
		for _, desk in desks do
			if desk.level < Config.Lawyer.MaxLevel then
				local cost = Formulas.trainCost(desk.level)
				if cost < bestCost then
					best, kind, bestCost = desk, "train", cost
				end
			end
			local nextTier = deskTiers[desk.tier + 1]
			if nextTier and nextTier.Cost < bestCost then
				best, kind, bestCost = desk, "tier", nextTier.Cost
			end
			if skillRollAvailable(desk) then
				local cost = Formulas.skillRollCost(desk.paidRolls)
				if cost < bestCost then
					best, kind, bestCost = desk, "skill", cost
				end
			end
		end
		return best, kind, bestCost
	end

	-- A "typical kid" policy: rush the first egg, then always buy the cheapest upgrade, except
	-- when the next desk is within SAVE_HORIZON of income, then save for it. About one egg
	-- every 10 minutes on top.
	local function spend(t: number)
		for _, desk in desks do
			while desk.freeRolls > 0 do
				desk.freeRolls -= 1
				rollSkill(desk)
			end
		end
		if not firstEgg then
			if coins >= eggPrice then
				buyEgg(t)
			end
			return
		end
		if eggsBought < 1 + t // 600 and coins >= eggPrice then
			buyEgg(t)
		end
		while true do
			-- next firm purchase: hire into an empty office, else expand the firm (Config.Firm)
			local deskCost, isExpand = nil, false
			if Config.Firm then
				if #desks < segments * 2 then
					deskCost = Config.Desks.UnlockCosts[#desks + 1]
				elseif segments < Config.Firm.MaxSegments then
					deskCost, isExpand = Config.Firm.ExpandCosts[segments + 1], true
				end
			elseif #desks < Config.Desks.MaxDesks then
				deskCost = Config.Desks.UnlockCosts[#desks + 1]
			end
			if deskCost and coins >= deskCost then
				coins -= deskCost
				if isExpand then
					segments += 1
				else
					addDesk(Config.Lawyer.StartLevel)
				end
				nextDesk = nextDesk or t
				continue
			end
			if deskCost and deskCost <= income() * SAVE_HORIZON then
				return
			end
			local desk, kind, cost = cheapestUpgrade()
			local managerId, managerCost = cheapestManager()
			if managerId and managerCost < cost then
				if coins < managerCost then
					return
				end
				coins -= managerCost
				if managerId == "hire" then
					managerHired = true
				else
					managerLevels[managerId] = (managerLevels[managerId] or 0) + 1
				end
				continue
			end
			if not desk or coins < cost then
				return
			end
			coins -= cost
			if kind == "train" then
				desk.level += 1
			elseif kind == "skill" then
				desk.paidRolls += 1
				rollSkill(desk)
			else
				desk.tier += 1
			end
		end
	end

	for t = 1, duration do
		if Config.Firm then
			-- clients walk into the waiting room while seats are free
			arrivalCredit += 1 / Formulas.clientInterval(#desks)
			while arrivalCredit >= 1 do
				arrivalCredit -= 1
				if #queue < SEATS then
					table.insert(queue, Formulas.rollClient(rng, clientWeightsFor(bestDesk())))
				end
			end
			assignCredit = math.min(assignCredit + (if managerHired then SEATS else MANUAL_ASSIGNS_PER_SECOND), SEATS)
		end
		for _, desk in desks do
			desk.remaining -= 1
			if desk.remaining <= 0 then
				if desk.client then
					resolveCase(desk)
				elseif not Config.Firm then
					desk.client = Formulas.rollClient(rng, profile.clientWeights)
					local client = clients[desk.client :: number]
					desk.remaining = Formulas.caseDuration(client, Formulas.combineBuffs(baseSources(desk)))
				elseif #queue > 0 and assignCredit >= 1 then
					-- the player (or the Manager) sends the next waiting client over
					assignCredit -= 1
					desk.client = table.remove(queue, 1)
					local client = clients[desk.client :: number]
					desk.remaining = WALK_SECONDS + Formulas.caseDuration(client, Formulas.combineBuffs(baseSources(desk)))
				end
			end
		end
		if Formulas.managerValue and t % 60 == 0 then
			local share = Formulas.managerValue(managerLevels, "retainer")
			if share > 0 then
				coins += income() * 60 * share
			end
		end
		if Config.Goals and t % GOAL_EVERY == 0 then
			local total = 0
			for _, goal in Config.Goals.List do
				total += goal.Minutes
			end
			coins += math.max(Config.Rewards.MinCoins, income() * 60 * total / #Config.Goals.List)
		end
		if Config.Rewards and t % Config.Rewards.PlaytimeInterval == 0 then
			gifts += 1
			coins += math.max(Config.Rewards.MinCoins, income() * 60 * Config.Rewards.PlaytimeMinutes)
		end
		spend(t)

		if t % 60 == 0 or table.find(SNAPSHOTS, t) then
			local rate = income()
			billion = billion or (if rate >= 1e9 then t else nil)
			trillion = trillion or (if rate >= 1e12 then t else nil)
			if table.find(SNAPSHOTS, t) then
				local top = 0
				for _, desk in desks do
					top = math.max(top, desk.level)
				end
				snapshots[t] = { income = rate, level = top, desks = #desks }
			end
		end
	end

	local topLevel = 0
	for _, desk in desks do
		topLevel = math.max(topLevel, desk.level)
	end

	return {
		profile = profile.name,
		startDesks = startDesks,
		duration = duration,
		firstEgg = firstEgg,
		incomeAtFirstEgg = incomeAtFirstEgg,
		nextDesk = nextDesk,
		billion = billion,
		trillion = trillion,
		snapshots = snapshots,
		topLevel = topLevel,
		endDesks = #desks,
		eggs = eggsBought,
		bestSkin = skins[bestSkin].Id,
		skillRolls = skillRolls,
		gifts = gifts,
		wins = wins,
		settlements = settlements,
		mistrials = mistrials,
	}
end

function EconomySim.run(options: Options?): string
	local opts: Options = options or {}
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Config = opts.Config or require(Shared:WaitForChild("Config") :: ModuleScript)
	local Formulas = opts.Formulas or require(Shared:WaitForChild("Formulas") :: ModuleScript)
	local seed = opts.seed or DEFAULT_SEED
	local fmt = Formulas.formatCoins

	local function perSecond(rate: number?): string
		return if rate then fmt(rate) .. "/s" else "--"
	end

	local lines = { string.format("=== Hatch Lawyers economy sim, seed %d ===", seed) }

	local samples = {}
	for _, level in { 1, 10, 25, 50, 75, 100 } do
		table.insert(samples, string.format("L%d %s", level, fmt(Formulas.basePayout(level))))
	end
	table.insert(lines, "Base payout per case: " .. table.concat(samples, " | "))
	samples = {}
	for _, level in { 1, 10, 25, 50, 75, 99 } do
		table.insert(samples, string.format("L%d %s", level, fmt(Formulas.trainCost(level))))
	end
	table.insert(lines, "Train cost (L -> L+1): " .. table.concat(samples, " | "))

	local results: { Result } = {}
	for _, profile in PROFILES do
		for _, scenario in SCENARIOS do
			table.insert(results, simulate(Config, Formulas, profile, scenario.desks, scenario.duration, seed))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "First hour")
	table.insert(
		lines,
		string.format(
			"%-10s %5s %8s %11s %8s %11s %4s %5s",
			"Profile", "Desks", "1st egg", "$ at egg", "+1 desk", "$ at 1h", "Lvl", "Desks"
		)
	)
	for _, r in results do
		local hour = r.snapshots[HOUR]
		table.insert(
			lines,
			string.format(
				"%-10s %5d %8s %11s %8s %11s %4d %5d",
				r.profile,
				r.startDesks,
				clock(r.firstEgg),
				perSecond(r.incomeAtFirstEgg),
				clock(r.nextDesk),
				perSecond(hour and hour.income),
				hour and hour.level or 0,
				hour and hour.desks or 0
			)
		)
	end

	table.insert(lines, "")
	table.insert(lines, "Long run (starting with 1 desk), income and top lawyer level")
	table.insert(
		lines,
		string.format(
			"%-10s %16s %16s %16s %16s %8s %8s %13s %-9s %s",
			"Profile", "1h", "6h", "12h", "24h", "1B/s", "1T/s", "Win/Set/Mis %", "Skin", "Rolls/Gifts"
		)
	)
	for _, r in results do
		if r.duration > HOUR then
			local cells = {}
			for _, t in SNAPSHOTS do
				local snap = r.snapshots[t]
				table.insert(cells, if snap then string.format("%s L%d", perSecond(snap.income), snap.level) else "--")
			end
			local cases = math.max(r.wins + r.settlements + r.mistrials, 1)
			table.insert(
				lines,
				string.format(
					"%-10s %16s %16s %16s %16s %8s %8s %13s %-9s %s",
					r.profile,
					cells[1],
					cells[2],
					cells[3],
					cells[4],
					clock(r.billion),
					clock(r.trillion),
					string.format(
						"%d/%d/%d",
						math.round(r.wins / cases * 100),
						math.round(r.settlements / cases * 100),
						math.round(r.mistrials / cases * 100)
					),
					r.bestSkin,
					string.format("%d/%d", r.skillRolls, r.gifts)
				)
			)
		end
	end

	local baseline = results[1] -- Ordinary, 1 desk
	local pacing = Config.Pacing
	local function status(actual: number?, target: { number }): string
		if actual == nil then
			return "MISS (never)"
		elseif actual < target[1] then
			return "FAST"
		elseif actual > target[2] then
			return "SLOW"
		end
		return "OK"
	end
	table.insert(lines, "")
	table.insert(lines, "Pacing check (Ordinary, 1 desk) vs Config.Pacing:")
	table.insert(lines, string.format("  %-16s %10s  target <= %s  %s", "First egg", clock(baseline.firstEgg), clock(pacing.FirstEgg[2]), status(baseline.firstEgg, pacing.FirstEgg)))
	table.insert(
		lines,
		string.format(
			"  %-16s %10s  target %s-%s/s  %s",
			"$ at first egg",
			perSecond(baseline.incomeAtFirstEgg),
			fmt(pacing.IncomeAtFirstEgg[1]),
			fmt(pacing.IncomeAtFirstEgg[2]),
			status(baseline.incomeAtFirstEgg, pacing.IncomeAtFirstEgg)
		)
	)
	table.insert(lines, string.format("  %-16s %10s  target %s-%s  %s", "Next desk", clock(baseline.nextDesk), clock(pacing.NextDesk[1]), clock(pacing.NextDesk[2]), status(baseline.nextDesk, pacing.NextDesk)))
	table.insert(lines, string.format("  %-16s %10s  target %s-%s  %s", "1T/s income", clock(baseline.trillion), clock(pacing.TrillionPerSecond[1]), clock(pacing.TrillionPerSecond[2]), status(baseline.trillion, pacing.TrillionPerSecond)))

	return table.concat(lines, "\n")
end

return EconomySim
