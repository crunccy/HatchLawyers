-- Checks on the REAL Shared.Config + Shared.Formulas (src/), run by tools/checks/run_checks.py under the Luau CLI.
-- They guard the rules that are easy to break by hand-editing Config: exact odds, every egg can hatch every
-- rarity it rolls, ids are unique, costs climb, Supreme stays 1 in 2500, the growth ratio stays put.
-- `Config` and `Formulas` are set up by the runner before this file.

local failures, passed = {}, 0
local function check(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		table.insert(failures, name .. ": " .. tostring(err))
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-9)
end
local function sum(t: { number }): number
	local s = 0
	for _, v in t do
		s += v
	end
	return s
end

local Skins = Config.Eggs.Skins
local function rarityIndex(id: string): number?
	for i, s in Skins do
		if s.Id == id then
			return i
		end
	end
	return nil
end
local baseWeights = {}
for i, s in Skins do
	baseWeights[i] = s.Weight
end
-- every egg: nil = the Briefcase Egg, then the themed ones
local eggs = { { id = nil :: string?, name = "Briefcase", weights = baseWeights } }
for _, def in Config.Eggs.Themed do
	table.insert(eggs, { id = def.Id, name = def.Id, weights = def.Weights })
end

------------------------------------------------------------------ rarities and odds
check("rarities are the 7 tiers in order", function()
	local want = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Supreme" }
	assert(#Skins == #want, "expected " .. #want .. " rarities, got " .. #Skins)
	for i, id in want do
		assert(Skins[i].Id == id, "rarity " .. i .. " should be " .. id .. ", is " .. tostring(Skins[i].Id))
	end
end)

check("lawyer power climbs with rarity", function()
	for i = 2, #Skins do
		assert(Skins[i].Earn > Skins[i - 1].Earn, Skins[i].Id .. " must earn more than " .. Skins[i - 1].Id)
	end
end)

check("every rarity has a colour", function()
	for _, s in Skins do
		assert(Config.RarityColors[s.Id], "Config.RarityColors." .. s.Id .. " missing")
	end
end)

for _, egg in eggs do
	check(egg.name .. " egg: one weight per rarity, summing to 100%", function()
		assert(#egg.weights == #Skins, "has " .. #egg.weights .. " weights for " .. #Skins .. " rarities")
		assert(near(sum(egg.weights), 100, 1e-6), "weights sum to " .. sum(egg.weights))
	end)
	check(egg.name .. " egg: Supreme is exactly 1 in 2500", function()
		local s = rarityIndex("Supreme") :: number
		assert(near(egg.weights[s] / sum(egg.weights), 1 / 2500, 1e-9), "Supreme share " .. egg.weights[s] / sum(egg.weights))
	end)
	check(egg.name .. " egg: a lawyer exists for every rarity it can roll", function()
		for r, w in egg.weights do
			if w > 0 then
				local id = Formulas.rollSkinId(Random.new(1), r, egg.id)
				assert(id ~= nil, "no " .. Skins[r].Id .. " lawyer (rolling one would error in EggServer)")
				local def = Formulas.getSkin(id)
				assert(def and def.Rarity == r and def.Egg == egg.id, "rolled " .. tostring(id) .. " from the wrong pool")
			end
		end
	end)
end

check("pity guarantees Legendary, never Mythic / Supreme", function()
	assert(Config.Eggs.PityRarity == rarityIndex("Legendary"), "PityRarity should be Legendary's index")
	assert(Config.Eggs.PityTop and Config.Eggs.PityTop > 0, "PityTop missing")
end)

check("the free first egg is a real rarity", function()
	assert(Skins[Config.Eggs.FirstEggRarity], "FirstEggRarity out of range")
end)

check("rolling 200k eggs gives Supreme ~1 in 2500", function()
	local rng = Random.new(12345)
	local supreme, s = 0, rarityIndex("Supreme")
	for _ = 1, 200000 do
		if Formulas.rollSkin(rng) == s then
			supreme += 1
		end
	end
	-- expected 80; 40..130 is far outside chance for a correct roller
	assert(supreme >= 40 and supreme <= 130, "got " .. supreme .. " Supremes in 200000 rolls (expected ~80)")
end)

check("luck (Lucky Eggs, golden eggs) keeps each egg's total and Mythic / Supreme exact", function()
	local mythic, supreme, legendary = rarityIndex("Mythic") :: number, rarityIndex("Supreme") :: number, rarityIndex("Legendary") :: number
	for _, egg in eggs do
		for _, luck in { 1, 2, 4, 8, 16 } do
			local w = Formulas.luckyWeights(egg.weights, luck)
			assert(near(sum(w), sum(egg.weights), 1e-6), egg.name .. " x" .. luck .. ": total changed to " .. sum(w))
			assert(near(w[supreme], egg.weights[supreme]) and near(w[mythic], egg.weights[mythic]), egg.name .. " x" .. luck .. ": Mythic / Supreme moved")
			assert(w[legendary] >= egg.weights[legendary] - 1e-9, egg.name .. " x" .. luck .. ": Legendary went down")
			for i, v in w do
				assert(v >= -1e-9, egg.name .. " x" .. luck .. ": negative weight at " .. i)
			end
		end
	end
	-- the Briefcase Egg has plenty of Common / Uncommon to pay for x2: exactly double
	local rare = rarityIndex("Rare") :: number
	assert(near(Formulas.luckyWeights(baseWeights, 2)[rare], baseWeights[rare] * 2, 1e-6), "x2 luck should double Rare")
end)

------------------------------------------------------------------ the lawyer catalog
check("catalog ids are unique, rarities and eggs valid, every lawyer has a model name", function()
	local seen = {}
	local themed = {}
	for _, def in Config.Eggs.Themed do
		themed[def.Id] = true
	end
	for _, skin in Config.SkinCatalog do
		assert(not seen[skin.Id], "duplicate lawyer id " .. skin.Id)
		seen[skin.Id] = true
		assert(Skins[skin.Rarity], skin.Id .. " has rarity " .. tostring(skin.Rarity))
		assert(skin.Egg == nil or themed[skin.Egg], skin.Id .. " has unknown Egg " .. tostring(skin.Egg))
		assert(type(skin.Model) == "string" and skin.Model ~= "", skin.Id .. " has no Model")
		assert(type(skin.Name) == "string" and skin.Name ~= "", skin.Id .. " has no Name")
	end
	assert(seen[Config.Lawyers.StartId], "the starting lawyer " .. tostring(Config.Lawyers.StartId) .. " isn't in the catalog")
end)

check("lawyer names don't use boss titles (docs/CHARACTER_STYLE.md: Naming rule)", function()
	local titles = { "Counsel", "Partner", "Prosecutor", "Attorney", "Barrister", "Solicitor", "Litigator", "Advocate",
		"Judge", "Justice", "Magistrate", "Arbiter" }
	for _, skin in Config.SkinCatalog do
		for _, title in titles do
			assert(not string.find(skin.Name, title, 1, true), skin.Id .. ' is called "' .. skin.Name .. '" - ' .. title .. " is a boss title")
		end
	end
end)

------------------------------------------------------------------ mutations + selling (2026-10-13)
check("mutations: one per tier past Normal, names match, power climbs, chances valid, ramps dark -> light", function()
	local L = Config.Lawyers
	assert(#L.StarEarn == #L.StarNames, "StarEarn and StarNames need one entry per tier")
	assert(L.StarNames[1] == "" and L.StarEarn[1] == 1, "tier 1 is plain Normal (x1, no name)")
	for t = 2, #L.StarEarn do
		assert(L.StarEarn[t] > L.StarEarn[t - 1], "tier " .. t .. " must earn more than tier " .. (t - 1))
		local m = L.Mutations[t]
		assert(m, "Config.Lawyers.Mutations[" .. t .. "] missing")
		assert(m.Id == L.StarNames[t], "Mutations[" .. t .. "].Id should be " .. L.StarNames[t])
		assert(m.Chance > 0 and m.Chance <= 1, m.Id .. ".Chance must be in (0, 1]")
		assert(near(Formulas.mutateChance(t - 1), m.Chance), "mutateChance(" .. (t - 1) .. ")")
		assert(#m.Ramp >= 2, m.Id .. " needs a ramp of 2+ colours")
		local function lum(c)
			return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
		end
		for i = 2, #m.Ramp do
			assert(lum(m.Ramp[i]) > lum(m.Ramp[i - 1]), m.Id .. " ramp must go dark -> light (stop " .. i .. ")")
		end
	end
	assert(Formulas.mutateChance(#L.StarEarn) == 0, "the top tier can't mutate further")
end)

check("hatch mutations: odds add up to less than 1, golden eggs at least as lucky, rolls stay in range", function()
	local H = Config.Lawyers.HatchMutation
	for _, kind in { "Normal", "Golden" } do
		local total = 0
		for t = 2, #Config.Lawyers.StarEarn do
			total += H[kind][t] or 0
		end
		assert(total < 1, kind .. " hatch mutation odds add up to " .. total)
	end
	for t = 2, #Config.Lawyers.StarEarn do
		assert((H.Golden[t] or 0) >= (H.Normal[t] or 0), "a golden egg should mutate at least as often (tier " .. t .. ")")
	end
	local rng, shiny = Random.new(7), 0
	for _ = 1, 20000 do
		local tier = Formulas.rollHatchMutation(rng, true)
		assert(tier >= 1 and tier <= #Config.Lawyers.StarEarn, "rolled tier " .. tier)
		if tier == 2 then
			shiny += 1
		end
	end
	local want = H.Golden[2] * 20000
	assert(math.abs(shiny - want) < want * 0.15, "golden Shiny rolls " .. shiny .. ", expected ~" .. want)
end)

check("selling: a share per rarity, climbing; a normal Common sells for less than its egg", function()
	local S = Config.Lawyers.Sell
	assert(#S.Share == #Skins, "Sell.Share needs one entry per rarity")
	for i = 2, #S.Share do
		assert(S.Share[i] > S.Share[i - 1], "Sell.Share must climb with rarity (" .. i .. ")")
	end
	assert(S.Share[1] < 1, "selling a fresh Common must pay less than the egg cost")
	assert(Skins[S.ConfirmFrom], "Sell.ConfirmFrom must be a rarity index")
	local price = Formulas.eggPrice(10, 0)
	assert(Formulas.sellPrice(Config.Lawyers.StartId, 1, 10, 0) == math.floor(price * S.Share[1]), "sellPrice of a Common")
	assert(Formulas.sellPrice(Config.Lawyers.StartId, 2, 10, 0) == math.floor(price * S.Share[1] * Config.Lawyers.StarEarn[2]), "sellPrice x mutation")
end)

------------------------------------------------------------------ egg tiers
check("themed eggs: unlock milestones and power climb with price", function()
	local list = table.clone(Config.Eggs.Themed)
	table.sort(list, function(a, b)
		return a.PriceMultiplier < b.PriceMultiplier
	end)
	for i = 2, #list do
		local a, b = list[i - 1], list[i]
		assert((b.UnlockEarned or 0) > (a.UnlockEarned or 0), b.Id .. " should unlock later than " .. a.Id)
		assert((b.EarnMultiplier or 1) > (a.EarnMultiplier or 1), b.Id .. " lawyers should earn more than " .. a.Id .. "'s")
	end
	local machines = {}
	for _, def in Config.Eggs.Themed do
		assert(not machines[def.Machine], "two eggs share machine " .. def.Machine)
		machines[def.Machine] = true
	end
end)

check("eggUnlocked: locked below the milestone, open at it; Briefcase always open", function()
	local pet = Formulas.themedEgg("Pet")
	assert(pet and pet.UnlockEarned, "Pet egg has no UnlockEarned")
	assert(not Formulas.eggUnlocked("Pet", pet.UnlockEarned - 1), "Pet open too early")
	assert(Formulas.eggUnlocked("Pet", pet.UnlockEarned), "Pet still locked at its milestone")
	assert(Formulas.eggUnlocked(nil, 0), "the Briefcase Egg must always be open")
end)

check("lawyerEarn includes rarity, stars and the egg's power", function()
	assert(Formulas.lawyerEarn(Config.Lawyers.StartId, 1) == Skins[1].Earn, "the Rookie should earn the Common rate")
	for _, skin in Config.SkinCatalog do
		local egg = Formulas.themedEgg(skin.Egg)
		local want = Skins[skin.Rarity].Earn * Config.Lawyers.StarEarn[2] * (if egg and egg.EarnMultiplier then egg.EarnMultiplier else 1)
		assert(near(Formulas.lawyerEarn(skin.Id, 2), want), skin.Id .. ": lawyerEarn " .. Formulas.lawyerEarn(skin.Id, 2) .. " ~= " .. want)
	end
end)

------------------------------------------------------------------ prices and costs
check("egg prices: the ramp climbs and themed = floor(base x multiplier)", function()
	assert(Formulas.eggPrice(0) == Config.Eggs.Price, "first egg price")
	for n = 0, 40 do
		assert(Formulas.eggPrice(n + 1) >= Formulas.eggPrice(n), "egg price fell at " .. n)
	end
	for _, def in Config.Eggs.Themed do
		assert(Formulas.themedEggPrice(def.Id, 5, 1) == math.floor(Formulas.eggPrice(5, 1) * def.PriceMultiplier), def.Id .. " price")
	end
end)

check("Expand Firm has a cost for every segment, climbing", function()
	local f = Config.Firm
	local last = 0
	for seg = f.StartSegments + 1, f.MaxSegments do
		local cost = f.ExpandCosts[seg]
		assert(type(cost) == "number", "ExpandCosts[" .. seg .. "] missing")
		assert(cost > last, "ExpandCosts[" .. seg .. "] isn't more than the one before")
		last = cost
	end
end)

check("office upgrades and the Supreme ladder climb", function()
	for l = 1, Config.Lawyer.MaxLevel - 1 do
		assert(Formulas.trainCost(l + 1) > Formulas.trainCost(l), "trainCost fell at level " .. l)
	end
	local lastCost, lastOffices = 0, 0
	for p = 0, 20 do
		local cost, offices = Formulas.prestigeRequirement(p)
		assert(cost > lastCost and offices >= lastOffices, "Supreme " .. p .. " requirement doesn't climb")
		assert(offices <= Config.Firm.MaxSegments * 2, "Supreme " .. p .. " asks for more offices than exist")
		lastCost, lastOffices = cost, offices
	end
end)

check("TrainGrowth / Payout.Growth ratio is where the sim tuned it (CLAUDE.md: run the sim before changing)", function()
	local ratio = Config.Lawyer.TrainGrowth / Config.Payout.Growth
	assert(ratio > 1.05 and ratio < 1.12, string.format("ratio %.4f: rerun tools/economy_sim.py and update this range", ratio))
end)

check("firm areas: every room of a stage costs more than every room of the stage before", function()
	local byStage: { [number]: { min: number, max: number } } = {}
	for _, area in Config.FirmAreas or {} do
		local s = byStage[area.Stage] or { min = math.huge, max = 0 }
		s.min, s.max = math.min(s.min, area.Cost), math.max(s.max, area.Cost)
		byStage[area.Stage] = s
	end
	local lastMax, lastStage = 0, 0
	for stage = 1, 10 do
		local s = byStage[stage]
		if s then
			assert(s.min > lastMax, string.format("a Stage %d room (%g) is cheaper than a Stage %d room (%g)", stage, s.min, lastStage, lastMax))
			lastMax, lastStage = s.max, stage
		end
	end
end)

check("client tiers have positive weights and case lengths", function()
	for i, c in Config.Clients do
		assert(c.Weight > 0 and c.Duration > 0 and c.Multiplier > 0, "Config.Clients[" .. i .. "]")
	end
end)

------------------------------------------------------------------ report
print(string.format("%d checks passed, %d failed", passed, #failures))
for _, f in failures do
	print("FAIL " .. f)
end
if #failures > 0 then
	error(#failures .. " config check(s) failed")
end
