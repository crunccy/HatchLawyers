--!strict
-- Lawyers and offices (v12 "hatch real lawyers"). Clients ask, the server checks and charges.
--   TrainLawyer(office, count?) upgrades an OFFICE (the main coin sink; the level stays with the office when
--                              lawyers swap): 1 level, `count` levels, or "max"; TrainLawyer("all") levels every
--                              office with a lawyer, cheapest first. Free tutorial level-ups are spent first.
--   PlaceLawyer(office, uid?)  puts an owned lawyer in an office (swapping with wherever it was) or,
--                              with uid nil, sends the office's lawyer back to the inventory. If the office is
--                              busy with a case, the change is QUEUED (unseat, or a bench lawyer replacing them)
--                              and happens the moment the case ends (CaseService.releaseDesk). Returns
--                              ok, message, "queued" when it was queued.
--   PlaceLawyer("best")        EQUIP BEST: the strongest lawyers into the offices (see equipBest).
--   CancelLawyerChange(office) drops a queued change.
--   MergeLawyers(uid)          merges that lawyer with Config.Lawyers.MergeCount - 1 copies of the same
--                              lawyer at the same stars into one lawyer with +1 star.
--   MergeSelected({uids})      the Lawyer Merger machine (Hub.MergeMachine): the player picks exactly
--                              MergeCount lawyers. Same rule, but the server merges exactly those, after
--                              checking every one (owned, distinct, same lawyer + stars, not max, not busy).
--                              The first pick (or the one in an office) keeps its uid/office and gets +1 star.
-- LawyerService.hatch() makes a new lawyer for EggServer (rolls its starting skills).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)
local CaseService = require(script.Parent.CaseService)

local Remotes = ReplicatedStorage.Remotes
local TrainLawyer = Remotes.TrainLawyer :: RemoteFunction
local PlaceLawyer = Remotes.PlaceLawyer :: RemoteFunction
local MergeLawyers = Remotes.MergeLawyers :: RemoteFunction
local MergeSelected = Remotes:FindFirstChild("MergeSelected") :: RemoteFunction
local CancelLawyerChange = Remotes:FindFirstChild("CancelLawyerChange") :: RemoteFunction

local COOLDOWN = 0.15

local LawyerService = {}

local rng = Random.new()
local lastRequest: { [Player]: number } = {}

local function throttled(player: Player): boolean
	local t = os.clock()
	if t - (lastRequest[player] or 0) < COOLDOWN then
		return true
	end
	lastRequest[player] = t
	return false
end

local function isIndex(n: unknown): boolean
	return type(n) == "number" and n == n // 1
end

-- An office's lawyer can only move while it isn't walking a client in or working a case.
local function officeFree(player: Player, index: number): boolean
	local desk = CaseService.getDesk(player, index)
	return not desk or desk.phase == "Idle" or desk.phase == "Empty"
end

-- Office upgrades. TrainLawyer(office, count?) buys up to `count` levels for one office (count = a whole number, or
-- "max" = as many as you can afford); TrainLawyer("all") levels every office with a lawyer, cheapest level first,
-- while coins last (economy pass 2026-10-09: a Supreme resets every office to level 1, so the panel needs MAX /
-- UPGRADE ALL instead of hundreds of single clicks). Free tutorial level-ups are spent first. Coins are taken per
-- level as it's bought, synced once at the end. Returns ok, a reason (failure) or the new office look's name, and
-- how many levels were bought.
local MAX_STEPS = 2000 -- levels one request may buy (20 offices x 100 levels)

local function buyLevel(data: PlayerData.Data, index: number): boolean
	local office = data.Desks[index]
	if office.Level >= Config.Lawyer.MaxLevel then
		return false
	end
	if data.Tutorial.FreeLevelUps > 0 then
		data.Tutorial.FreeLevelUps -= 1
	else
		local cost = Formulas.trainCost(office.Level)
		if data.Coins < cost then
			return false
		end
		data.Coins -= cost
	end
	office.Level += 1
	return true
end

local function upgradeOffice(player: Player, index: unknown, count: unknown): (boolean, string?, number?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	local targets: { number } = {}
	if index == "all" then
		for i, office in data.Desks do
			if office.Lawyer then
				table.insert(targets, i)
			end
		end
		if #targets == 0 then
			return false, "Equip a lawyer first"
		end
	elseif isIndex(index) and data.Desks[index :: number] then
		table.insert(targets, index :: number)
	else
		return false, "Bad office"
	end
	local limit = 1
	if index == "all" or count == "max" then
		limit = MAX_STEPS
	elseif isIndex(count) and (count :: number) >= 1 then
		limit = math.min(count :: number, MAX_STEPS)
	elseif count ~= nil then
		return false, "Bad count"
	end
	local before: { [number]: number } = {}
	for _, i in targets do
		before[i] = Formulas.officeTier(data.Desks[i].Level)
	end
	local bought = 0
	while bought < limit do
		-- the cheapest next level among the targets (one office: just that one)
		local pick, cheapest = nil, math.huge
		for _, i in targets do
			local level = data.Desks[i].Level
			if level < Config.Lawyer.MaxLevel and Formulas.trainCost(level) < cheapest then
				pick, cheapest = i, Formulas.trainCost(level)
			end
		end
		if not pick or not buyLevel(data, pick) then
			break
		end
		bought += 1
	end
	if bought == 0 then
		local maxed = true
		for _, i in targets do
			if data.Desks[i].Level < Config.Lawyer.MaxLevel then
				maxed = false
			end
		end
		return false, if maxed then "Max level!" else "Not enough coins", 0
	end
	PlayerData.sync(player)
	local GoalService = require(script.Parent.GoalService) :: any
	GoalService.track(player, "train", bought)
	local newLook: string? = nil
	for _, i in targets do
		local tier = Formulas.officeTier(data.Desks[i].Level)
		local tierUp = tier > before[i]
		if tierUp then
			GoalService.track(player, "deskUpgrade")
			newLook = Config.Desks.Tiers[tier].Name
		end
		CaseService.refreshDesk(player, i, tierUp)
		if tierUp then
			CaseService.burst(player, i, "tier")
		end
	end
	return true, newLook, bought
end

-- The move itself (office free, everything validated by the caller). uid nil = back to the inventory.
local function doPlace(player: Player, data: PlayerData.Data, target: number, uid: string?)
	local office = data.Desks[target]
	if uid == nil then
		office.Lawyer = nil
		PlayerData.sync(player)
		CaseService.refreshDesk(player, target)
		return
	end
	local from = PlayerData.officeOf(data, uid)
	local wasEmpty = office.Lawyer == nil
	if from then
		-- swap: whoever sat here moves to the lawyer's old office
		data.Desks[from].Lawyer = office.Lawyer
	end
	office.Lawyer = uid
	PlayerData.sync(player)
	CaseService.refreshDesk(player, target, true)
	if from then
		CaseService.refreshDesk(player, from)
	end
	if wasEmpty and not from then
		require(script.Parent.GoalService).track(player, "place")
	end
	local def = Formulas.getSkin(data.Lawyers[uid].Id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	if rarity and (rarity.Id == "Legendary" or rarity.Id == "Rare") then
		CaseService.burst(player, target, if rarity.Id == "Legendary" then "legendary" else "rare")
	end
end

local function lawyerLabel(data: PlayerData.Data, uid: string): string
	local l = data.Lawyers[uid]
	return if l then Formulas.lawyerName(l.Id, l.Stars) else "That lawyer"
end

-- Returns ok, a message for the player, and "queued" when the change waits for the current case to end.
local function place(player: Player, index: unknown, uid: unknown): (boolean, string?, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	if not isIndex(index) or not data.Desks[index :: number] then
		return false, "Bad office"
	end
	local target = index :: number
	local office = data.Desks[target]
	if uid == nil then
		-- back to the inventory
		if not office.Lawyer then
			return false, "That office is already empty"
		end
		if not officeFree(player, target) then
			CaseService.setQueued(player, target, "unseat")
			return true, lawyerLabel(data, office.Lawyer) .. " gets unequipped after this case", "queued"
		end
		doPlace(player, data, target, nil)
		return true, nil
	end
	if type(uid) ~= "string" or not data.Lawyers[uid] then
		return false, "You don't have that lawyer"
	end
	if office.Lawyer == uid then
		return false, "Already equipped here"
	end
	local from = PlayerData.officeOf(data, uid)
	if from and not officeFree(player, from) then
		return false, string.format("%s is on a case in Office %d", lawyerLabel(data, uid), from)
	end
	if not officeFree(player, target) then
		if from then
			-- a swap between two offices needs both free; only bench lawyers can wait in line
			return false, string.format("Office %d is on a case. Wait for it, or pick an unequipped lawyer", target)
		end
		CaseService.setQueued(player, target, uid)
		return true, lawyerLabel(data, uid) .. " gets equipped after this case", "queued"
	end
	doPlace(player, data, target, uid)
	return true, nil
end

-- A queued change, now that the office's case is over (CaseService.releaseDesk). Re-validated: the bench
-- lawyer may have been merged away or placed elsewhere since.
local function applyQueued(player: Player, target: number, uid: string?): boolean
	local data = PlayerData.get(player)
	local office = data and data.Desks[target]
	if not data or not office or not office.Lawyer or not officeFree(player, target) then
		return false
	end
	if uid ~= nil and (not data.Lawyers[uid] or PlayerData.officeOf(data, uid) ~= nil) then
		return false
	end
	doPlace(player, data, target, uid)
	return true
end

local function cancelChange(player: Player, index: unknown): (boolean, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	if not isIndex(index) then
		return false, "Bad office"
	end
	if not CaseService.queuedChange(player, index :: number) then
		return false, "Nothing to cancel"
	end
	CaseService.setQueued(player, index :: number, nil)
	return true, "Change cancelled"
end

-- Total skill levels, to keep the best skill set when merging.
local function skillScore(lawyer: PlayerData.LawyerData): number
	local n = 0
	for _, skill in lawyer.Skills do
		n += skill.Level
	end
	return n
end

-- EQUIP BEST (PlaceLawyer("best"), 2026-10-11): your strongest lawyers (Formulas.lawyerEarn, then skill levels) go
-- into your free offices, the strongest in the highest-level office (a case pays office level x lawyer earn). A
-- lawyer on a case stays put; a stronger unequipped lawyer left over is queued to take their place after the case.
-- Lawyers just as strong as the pick for their office keep their seat, so a second press changes nothing.
local function equipBest(player: Player): (boolean, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	if next(data.Lawyers) == nil then
		return false, "No lawyers yet - hatch some eggs!"
	end
	local function earn(uid: string): number
		local l = data.Lawyers[uid]
		return Formulas.lawyerEarn(l.Id, l.Stars)
	end
	local free, busy = {}, {}
	local locked: { [string]: boolean } = {}
	for i, office in data.Desks do
		if officeFree(player, i) then
			table.insert(free, i)
		else
			table.insert(busy, i)
			if office.Lawyer then
				locked[office.Lawyer] = true
			end
		end
	end
	local pool = {}
	for uid in data.Lawyers do
		if not locked[uid] then
			table.insert(pool, uid)
		end
	end
	table.sort(pool, function(a, b)
		local ea, eb = earn(a), earn(b)
		if ea ~= eb then
			return ea > eb
		end
		local sa, sb = skillScore(data.Lawyers[a]), skillScore(data.Lawyers[b])
		if sa ~= sb then
			return sa > sb
		end
		return a < b
	end)
	table.sort(free, function(a, b)
		local la, lb = data.Desks[a].Level, data.Desks[b].Level
		if la ~= lb then
			return la > lb
		end
		return a < b
	end)
	-- pool[k] is the pick for free[k]; whoever already sits there keeps the seat if they're picked and as strong
	for k, i in free do
		local current = data.Desks[i].Lawyer
		local pick = pool[k]
		if current and pick and current ~= pick and earn(current) == earn(pick) then
			local j = table.find(pool, current)
			if j and j <= #free then
				pool[j], pool[k] = pick, current
			end
		end
	end
	local queued = 0
	local changed = {}
	for k, i in free do
		local uid = pool[k]
		local office = data.Desks[i]
		if office.Lawyer ~= uid then
			if uid and office.Lawyer == nil and PlayerData.officeOf(data, uid) == nil then
				require(script.Parent.GoalService).track(player, "place")
			end
			table.insert(changed, i)
		end
	end
	for k, i in free do
		data.Desks[i].Lawyer = pool[k]
	end
	-- the rest of the pool is now unequipped; the strongest of them queue for the weakest busy offices
	local spare = {}
	for k = #free + 1, #pool do
		table.insert(spare, pool[k])
	end
	table.sort(busy, function(a, b)
		local la, lb = data.Desks[a].Lawyer, data.Desks[b].Lawyer
		local ea, eb = if la then earn(la) else 0, if lb then earn(lb) else 0
		if ea ~= eb then
			return ea < eb
		end
		return a < b
	end)
	for _, i in busy do
		local current = data.Desks[i].Lawyer
		local swap = spare[1]
		if swap and (not current or earn(swap) > earn(current)) then
			if CaseService.setQueued(player, i, swap) then
				table.remove(spare, 1)
				queued += 1
			end
		elseif CaseService.queuedChange(player, i) then
			CaseService.setQueued(player, i, nil) -- an old unequip / swap would undo the best line-up
		end
	end
	if #changed > 0 then
		PlayerData.sync(player)
		for _, i in changed do
			CaseService.refreshDesk(player, i, data.Desks[i].Lawyer ~= nil)
		end
	end
	if #changed == 0 and queued == 0 then
		return true, "Your best lawyers are already equipped!"
	end
	local msg = if #changed > 0 then "Equipped your best lawyers!" else "Your best lawyers are lined up!"
	if queued > 0 then
		msg ..= if queued == 1 then " 1 more joins after a case" else string.format(" %d more join after their cases", queued)
	end
	return true, msg
end

local mergeInto: (Player, PlayerData.Data, string, { string }) -> (boolean, string?)

local function merge(player: Player, uid: unknown): (boolean, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	if type(uid) ~= "string" or not data.Lawyers[uid] then
		return false, "You don't have that lawyer"
	end
	local base = data.Lawyers[uid]
	if base.Stars >= #Config.Lawyers.StarEarn then
		return false, "Already max stars!"
	end
	-- the copies to use up: inventory ones first, then ones in offices that aren't busy
	local spare, working = {}, {}
	for otherUid, other in data.Lawyers do
		if otherUid ~= uid and other.Id == base.Id and other.Stars == base.Stars then
			local at = PlayerData.officeOf(data, otherUid)
			if not at then
				table.insert(spare, otherUid)
			elseif officeFree(player, at) then
				table.insert(working, otherUid)
			end
		end
	end
	local need = Config.Lawyers.MergeCount - 1
	local used = {}
	for _, list in { spare, working } do
		for _, otherUid in list do
			if #used < need then
				table.insert(used, otherUid)
			end
		end
	end
	if #used < need then
		return false, string.format("Need %d of this lawyer", Config.Lawyers.MergeCount)
	end
	local at = PlayerData.officeOf(data, uid)
	if at and not officeFree(player, at) then
		return false, "Busy with a case!"
	end
	return mergeInto(player, data, uid, used)
end

-- The merge itself, shared by MergeLawyers and MergeSelected. Everything is already validated; nothing in
-- here yields, so two requests can never interleave and consume the same lawyers.
function mergeInto(player: Player, data: PlayerData.Data, uid: string, used: { string }): (boolean, string?)
	local base = data.Lawyers[uid]
	local at = PlayerData.officeOf(data, uid)
	-- the merged lawyer keeps the best skills of the three and every free roll / case count
	local best = base
	local refresh = {}
	for _, otherUid in used do
		local other = data.Lawyers[otherUid]
		if skillScore(other) > skillScore(best) then
			best = other
		end
		base.FreeSkillRolls += other.FreeSkillRolls or 0
		base.CasesDone += other.CasesDone or 0
		local otherAt = PlayerData.officeOf(data, otherUid)
		if otherAt then
			data.Desks[otherAt].Lawyer = nil
			table.insert(refresh, otherAt)
		end
		data.Lawyers[otherUid] = nil
	end
	if best ~= base then
		base.Skills = table.clone(best.Skills)
		base.PendingSkill = nil
	end
	base.Stars += 1
	PlayerData.sync(player)
	for _, i in refresh do
		CaseService.refreshDesk(player, i)
	end
	if at then
		CaseService.refreshDesk(player, at, true)
		CaseService.burst(player, at, if base.Stars >= 3 then "rainbow" else "merge")
	end
	require(script.Parent.GoalService).track(player, "merge")
	return true, Formulas.lawyerName(base.Id, base.Stars)
end

-- The Lawyer Merger: exactly the lawyers the player picked. Returns ok, the merged lawyer's name (or the
-- reason it failed) and its uid.
local function mergeSelected(player: Player, picks: unknown): (boolean, string?, string?)
	if throttled(player) then
		return false, "Slow down!"
	end
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading"
	end
	local need = Config.Lawyers.MergeCount
	if type(picks) ~= "table" or #(picks :: { any }) ~= need then
		return false, string.format("Pick %d lawyers", need)
	end
	local uids = picks :: { any }
	local seen: { [string]: boolean } = {}
	local first: PlayerData.LawyerData? = nil
	for _, u in uids do
		if type(u) ~= "string" or not data.Lawyers[u] then
			return false, "You don't have that lawyer"
		end
		if seen[u] then
			return false, "Pick 3 different lawyers"
		end
		seen[u] = true
		local lawyer = data.Lawyers[u]
		if first and (lawyer.Id ~= first.Id or lawyer.Stars ~= first.Stars) then
			return false, "They must be the same lawyer"
		end
		first = first or lawyer
		local at = PlayerData.officeOf(data, u)
		if at and not officeFree(player, at) then
			return false, "One of them is busy with a case!"
		end
	end
	if (first :: PlayerData.LawyerData).Stars >= #Config.Lawyers.StarEarn then
		return false, "Already max stars!"
	end
	-- keep the one sitting in an office (it stays at its desk), else the first pick
	local keep = uids[1] :: string
	for _, u in uids do
		if PlayerData.officeOf(data, u :: string) then
			keep = u :: string
			break
		end
	end
	local used = {}
	for _, u in uids do
		if u ~= keep then
			table.insert(used, u :: string)
		end
	end
	local ok, name = mergeInto(player, data, keep, used)
	if ok then
		local machine = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("MergeMachine")
		if machine and machine:IsA("Model") then -- everyone near the machine sees it go off
			local Effects = require(ReplicatedStorage.Shared.Effects) :: any
			local box, size = machine:GetBoundingBox()
			task.delay(1.2, Effects.burst, box.Position + Vector3.new(0, size.Y / 2, 0), if data.Lawyers[keep].Stars >= 3 then "rainbow" else "merge")
		end
	end
	return ok, name, if ok then keep else nil
end

-- A freshly hatched lawyer of this catalog id: rolls its starting skills (Config.Eggs.Skins
-- StartSkills) and adds it to the player's lawyers. Returns its uid and record.
function LawyerService.hatch(data: PlayerData.Data, id: string): (string, PlayerData.LawyerData)
	local def = Formulas.getSkin(id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	local lawyer = PlayerData.newLawyer(id, 1)
	for _ = 1, if rarity then rarity.StartSkills else 1 do
		local skillId, param = Formulas.rollSkill(rng, lawyer.Skills)
		if not skillId then
			break
		end
		local owned = nil
		for _, s in lawyer.Skills do
			if s.Id == skillId then
				owned = s
			end
		end
		if owned then
			owned.Level = math.min(owned.Level + 1, Config.Skills.MaxLevel)
		else
			table.insert(lawyer.Skills, { Id = skillId, Level = 1, Param = param })
		end
	end
	return PlayerData.addLawyer(data, lawyer), lawyer
end

function LawyerService.start()
	TrainLawyer.OnServerInvoke = upgradeOffice
	PlaceLawyer.OnServerInvoke = function(player: Player, index: unknown, uid: unknown): (boolean, string?, string?)
		if index == "best" then
			return equipBest(player)
		end
		return place(player, index, uid)
	end
	CaseService.applyQueued = applyQueued
	if CancelLawyerChange then
		CancelLawyerChange.OnServerInvoke = cancelChange
	end
	MergeLawyers.OnServerInvoke = merge
	if MergeSelected then
		MergeSelected.OnServerInvoke = mergeSelected
	end
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return LawyerService
