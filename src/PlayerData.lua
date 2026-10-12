--!strict
-- Saved player data. The server owns it; clients only see mirrored attributes.
-- One DataStore key per player holds { Data, Lock }. The lock stops two servers from editing the
-- same player at once: we take it on load, refresh it on every autosave and clear it on release.
-- Bump SCHEMA_VERSION and add a MIGRATIONS entry before adding or renaming any saved field.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)

-- A hatched lawyer (v12). Id: one of Config.SkinCatalog (the lawyer catalog). Stars: merge level.
-- Skills: owned skills. PendingSkill: a rolled skill waiting for the player to pick a slot.
-- CasesDone counts finished cases (for free skill rolls); SkillRolls counts paid rolls (sets the price).
export type LawyerData = {
	Id: string,
	Stars: number,
	Skills: { Formulas.OwnedSkill },
	PendingSkill: Formulas.OwnedSkill?,
	SkillRolls: number,
	FreeSkillRolls: number,
	CasesDone: number,
}
-- An office (v12): its level (office upgrades) and the uid of the lawyer sitting in it, if any.
-- Desks[i] is office i; there is one per office the firm has (Firm.Segments x 2).
export type DeskData = {
	Level: number,
	Lawyer: string?,
}
export type Data = {
	Version: number,
	Coins: number,
	Desks: { DeskData },
	-- Lawyers: every lawyer the player owns, by uid ("L1", "L2", ...). NextLawyer: the next uid number.
	Lawyers: { [string]: LawyerData },
	NextLawyer: number,
	Tutorial: { FirstCaseDone: boolean, FreeLevelUps: number },
	Stats: { Wins: number, Settlements: number, Mistrials: number, CoinsEarned: number, BestPayout: number },
	-- Owned: skinId -> count. Equipped: desk index as a string ("1") -> skinId.
	Skins: { Owned: { [string]: number }, Equipped: { [string]: string } },
	-- Seen: how many hatches the player has looked at in the skin inventory (drives the NEW badge).
	-- SinceTop: eggs since the last top-rarity skin (drives the pity guarantee).
	Eggs: { Opened: number, RunOpened: number, FreeUsed: boolean, Seen: number, FreeTokens: number, RareTokens: number, SinceTop: number },
	-- LastDay: UTC day number (os.time() // 86400) of the last daily claim, -1 = never.
	Daily: { Streak: number, LastDay: number },
	-- Active: seconds of active play banked toward the next playtime gift.
	Playtime: { Active: number, Gifts: number },
	-- os.time() of the last save while online (0 = never); drives offline earnings.
	LastOnline: number,
	-- Active: the current goals ({ Id, Progress }); Completed: how many the player has finished.
	Goals: { Active: { { Id: string, Progress: number } }, Completed: number },
	-- Hired: the Manager is in the firm. Levels: upgrade id -> level bought.
	Manager: { Hired: boolean, Levels: { [string]: number } },
	-- Level: how many times the player has gone Supreme (each adds a permanent payout bonus).
	Prestige: { Level: number },
	-- Segments: office segments the firm building has (2 lawyer offices each; Config.Firm).
	Firm: { Segments: number, Areas: { [string]: boolean }? },
	-- Developer-product receipts already granted: PurchaseId -> os.time(). ShopService checks this before
	-- granting, so a receipt Roblox re-sends is never granted twice. Pruned to the newest 200.
	Purchases: { [string]: number },
	-- Hub minigames: game id -> os.time() it can be played again (MinigameService).
	Minigames: { [string]: number },
	-- Egg zones (ZoneService): License level (0 = none; prestige resets it), Carry / Speed upgrade levels (1 = start),
	-- Carried = eggs bought but not hatched yet ({ Egg = "Briefcase" | themed id, Golden }), hatched at an incubator.
	Zones: { License: number, Carry: number, Speed: number, Carried: { { Egg: string, Golden: boolean? } } },
}

type Session = { data: Data, releasing: boolean }

local SCHEMA_VERSION = 17
local STORE_NAME = "PlayerData"
local AUTOSAVE_INTERVAL = 60
local LOCK_EXPIRY = 5 * 60 -- a lock this old belongs to a crashed server and can be taken over
local LOAD_ATTEMPTS = 6
local LOAD_RETRY_DELAY = 5
local SAVE_ATTEMPTS = 3

-- MIGRATIONS[n] upgrades a version-n record to version n + 1.
local MIGRATIONS: { [number]: (any) -> any } = {
	-- v16: egg zones (Config.Zones). No License, the starting bag and shoes, nothing carried.
	[15] = function(data)
		data.Zones = data.Zones or { License = 0, Carry = 1, Speed = 1, Carried = {} }
		return data
	end,
	-- v15: hub minigames (Config.Minigames). Every game is ready.
	[14] = function(data)
		data.Minigames = data.Minigames or {}
		return data
	end,
	-- v14: firm areas (Config.FirmAreas). Nobody owns any yet.
	[13] = function(data)
		data.Firm = data.Firm or { Segments = Config.Firm.StartSegments }
		data.Firm.Areas = data.Firm.Areas or {}
		return data
	end,
	-- v13: the Robux shop. No receipts granted yet.
	[12] = function(data)
		data.Purchases = data.Purchases or {}
		return data
	end,
	-- v2: egg machine. Players saved before it start with no skins and their free egg unused.
	[1] = function(data)
		data.Skins = { Owned = {}, Equipped = {} }
		data.Eggs = { Opened = 0, FreeUsed = false }
		return data
	end,
	-- v3: NEW badge on the skin inventory. Hatches from before it count as already seen.
	[2] = function(data)
		data.Eggs.Seen = data.Eggs.Opened + (if data.Eggs.FreeUsed then 1 else 0)
		return data
	end,
	-- v11: the big firm (waiting room + offices). Lawyers already hired keep their levels, skills and
	-- desks. (This used to pad everyone to Config.Firm.StartLawyers lawyers; since v12 a new player
	-- starts with one, so old saves no longer get free Rookies - the v12 step pads empty offices.)
	[10] = function(data)
		data.Firm = data.Firm or { Segments = math.max(Config.Firm.StartSegments, math.ceil(#data.Desks / 2)) }
		return data
	end,
	-- v12: hatch real lawyers. Offices and lawyers split: each old desk becomes an office (keeps its
	-- level) holding a lawyer (keeps skills; the skin it wore becomes who it is, else a Rookie).
	-- Owned skins that weren't worn become extra lawyers in the inventory. Offices are padded to
	-- Firm.Segments x 2.
	[11] = function(data)
		data.Lawyers = {}
		data.NextLawyer = 1
		local function add(id: string, from: any?): string
			local uid = "L" .. data.NextLawyer
			data.NextLawyer += 1
			data.Lawyers[uid] = {
				Id = id,
				Stars = 1,
				Skills = if from then from.Skills or {} else {},
				PendingSkill = if from then from.PendingSkill else nil,
				SkillRolls = if from then from.SkillRolls or 0 else 0,
				FreeSkillRolls = if from then from.FreeSkillRolls or 0 else 0,
				CasesDone = if from then from.CasesDone or 0 else 0,
			}
			return uid
		end
		local skins = data.Skins or { Owned = {}, Equipped = {} }
		local left = table.clone(skins.Owned or {})
		local offices = {}
		for index, old in data.Desks do
			local skinId = skins.Equipped and skins.Equipped[tostring(index)]
			if skinId and (left[skinId] or 0) > 0 then
				left[skinId] -= 1
			else
				skinId = nil
			end
			table.insert(offices, { Level = old.Level or 1, Lawyer = add(skinId or Config.Lawyers.StartId, old) })
		end
		for skinId, count in left do
			if Formulas.getSkin(skinId) then
				for _ = 1, count do
					add(skinId, nil)
				end
			end
		end
		local segments = (data.Firm and data.Firm.Segments) or Config.Firm.StartSegments
		while #offices < segments * 2 do
			table.insert(offices, { Level = Config.Lawyer.StartLevel })
		end
		data.Desks = offices
		return data
	end,
	-- v10: egg pity. Everyone starts the count fresh.
	[9] = function(data)
		data.Eggs.SinceTop = data.Eggs.SinceTop or 0
		return data
	end,
	-- v9: prestige. Nobody has prestiged yet.
	[8] = function(data)
		data.Prestige = data.Prestige or { Level = 0 }
		return data
	end,
	-- v8: the Manager. Nobody has hired one yet.
	[7] = function(data)
		data.Manager = data.Manager or { Hired = false, Levels = {} }
		return data
	end,
	-- v7: short-term goals. GoalService fills the slots on load.
	[6] = function(data)
		data.Goals = data.Goals or { Active = {}, Completed = 0 }
		return data
	end,
	-- v6: offline earnings. Unknown last-online time, so no offline payout on the first load.
	[5] = function(data)
		data.LastOnline = data.LastOnline or 0
		return data
	end,
	-- v5: daily streak, playtime gifts and egg tokens (from rewards). Everyone starts fresh.
	[4] = function(data)
		data.Eggs.FreeTokens = data.Eggs.FreeTokens or 0
		data.Eggs.RareTokens = data.Eggs.RareTokens or 0
		data.Daily = data.Daily or { Streak = 0, LastDay = -1 }
		data.Playtime = data.Playtime or { Active = 0, Gifts = 0 }
		return data
	end,
	-- v4: lawyer skills. Every existing lawyer starts with no skills and no rolls used.
	[3] = function(data)
		for _, desk in data.Desks do
			desk.Skills = desk.Skills or {}
			desk.SkillRolls = desk.SkillRolls or 0
			desk.FreeSkillRolls = desk.FreeSkillRolls or 0
			desk.CasesDone = desk.CasesDone or 0
		end
		return data
	end,
	-- v17 (economy pass 2026-10-09; numbered after Studio's v14-v16 when merged 2026-10-12): eggs' price ramp counts
	-- eggs opened since the last Supreme. Existing players keep today's prices (RunOpened = everything opened so far)
	-- until they go Supreme.
	[16] = function(data)
		data.Eggs = data.Eggs or { Opened = 0, FreeUsed = false }
		data.Eggs.RunOpened = data.Eggs.Opened or 0
		return data
	end,
}

local PlayerData = {}

local sessions: { [Player]: Session } = {}
local store: DataStore? = nil
local memoryOnly = false

-- A new, empty office. Use this anywhere an office is added so every field exists.
function PlayerData.newDesk(): DeskData
	return { Level = Config.Lawyer.StartLevel }
end

-- A new lawyer record (not yet owned: pass it to PlayerData.addLawyer).
function PlayerData.newLawyer(id: string, stars: number?, skills: { Formulas.OwnedSkill }?): LawyerData
	return { Id = id, Stars = stars or 1, Skills = skills or {}, SkillRolls = 0, FreeSkillRolls = 0, CasesDone = 0 }
end

-- Gives the player a lawyer; returns its uid.
function PlayerData.addLawyer(data: Data, lawyer: LawyerData): string
	local uid = "L" .. data.NextLawyer
	data.NextLawyer += 1
	data.Lawyers[uid] = lawyer
	return uid
end

-- The lawyer sitting in office `index` (and its uid), or nil if the office is empty.
function PlayerData.lawyerAt(data: Data, index: number): (LawyerData?, string?)
	local office = data.Desks[index]
	local uid = office and office.Lawyer
	local lawyer = uid and data.Lawyers[uid]
	return lawyer, if lawyer then uid else nil
end

-- The office a lawyer sits in, or nil if it's in the inventory.
function PlayerData.officeOf(data: Data, uid: string): number?
	for index, office in data.Desks do
		if office.Lawyer == uid then
			return index
		end
	end
	return nil
end

function PlayerData.lawyerCount(data: Data): number
	local n = 0
	for _ in data.Lawyers do
		n += 1
	end
	return n
end

local function template(): Data
	local desks = {}
	for _ = 1, Config.Firm.StartSegments * 2 do
		table.insert(desks, PlayerData.newDesk())
	end
	desks[1].Lawyer = "L1"
	return {
		Version = SCHEMA_VERSION,
		Coins = 0,
		Desks = desks,
		Lawyers = { L1 = PlayerData.newLawyer(Config.Lawyers.StartId) },
		NextLawyer = 2,
		Tutorial = { FirstCaseDone = false, FreeLevelUps = Config.Tutorial.FreeLevelUps },
		Stats = { Wins = 0, Settlements = 0, Mistrials = 0, CoinsEarned = 0, BestPayout = 0 },
		Skins = { Owned = {}, Equipped = {} },
		Eggs = { Opened = 0, RunOpened = 0, FreeUsed = false, Seen = 0, FreeTokens = 0, RareTokens = 0, SinceTop = 0 },
		Daily = { Streak = 0, LastDay = -1 },
		Playtime = { Active = 0, Gifts = 0 },
		LastOnline = 0,
		Goals = { Active = {}, Completed = 0 },
		Manager = { Hired = false, Levels = {} },
		Prestige = { Level = 0 },
		Firm = { Segments = Config.Firm.StartSegments, Areas = {} },
		Purchases = {},
		Minigames = {},
		Zones = { License = 0, Carry = 1, Speed = 1, Carried = {} },
	}
end

-- Fills in any field the saved record is missing (for example one added in a later version).
local function reconcile(target: { [any]: any }, defaults: { [any]: any })
	for key, value in defaults do
		if target[key] == nil then
			target[key] = value
		-- (never into Lawyers: the template's starter lawyer must not come back after it was merged away)
		elseif type(value) == "table" and type(target[key]) == "table" and #value == 0 and key ~= "Lawyers" then
			reconcile(target[key], value)
		end
	end
end

local function migrate(data: any): Data?
	while data.Version < SCHEMA_VERSION do
		local step = MIGRATIONS[data.Version]
		if not step then
			warn("[PlayerData] no migration from version", data.Version)
			return nil
		end
		data = step(data)
		data.Version += 1
	end
	if data.Version > SCHEMA_VERSION then
		-- Saved by a newer server. Loading it here could drop fields, so refuse.
		return nil
	end
	reconcile(data, template())
	return data
end

local function lockKey(player: Player): string
	return "Player_" .. player.UserId
end

-- The DataStore, or nil. Only STUDIO falls back to memory-only for good (API access off). A live server that can't
-- reach DataStores retries on the next call instead (audit 2026-10-12): giving up there used to hand every player on
-- that server a brand-new firm that never saved, and let saveNow report success for Robux purchases.
local function getStore(): DataStore?
	if store or memoryOnly then
		return store
	end
	local ok, result = pcall(function()
		local candidate = DataStoreService:GetDataStore(STORE_NAME)
		candidate:GetAsync("__probe")
		return candidate
	end)
	if ok then
		store = result
	elseif RunService:IsStudio() then
		memoryOnly = true
		warn("[PlayerData] DataStores unavailable (Studio), progress will NOT be saved:", result)
	else
		warn("[PlayerData] DataStores unavailable right now, will retry:", result)
	end
	return store
end

-- Returns the saved data (or nil for a new player), "locked" if another server holds the lock,
-- or "error" if the request failed.
local function acquire(dataStore: DataStore, key: string): (string, any)
	local status, saved = "error", nil
	local ok, err = pcall(function()
		dataStore:UpdateAsync(key, function(record)
			record = record or {}
			local lock = record.Lock
			local now = os.time()
			if lock and lock.JobId ~= game.JobId and now - lock.Time < LOCK_EXPIRY then
				status = "locked"
				return nil
			end
			record.Lock = { JobId = game.JobId, Time = now }
			status, saved = "ok", record.Data
			return record
		end)
	end)
	if not ok then
		warn("[PlayerData] load failed for", key, err)
		return "error", nil
	end
	return status, saved
end

local function write(player: Player, session: Session, release: boolean): boolean
	local dataStore = getStore()
	if not dataStore then
		-- Studio memory-only: nothing is ever saved, by design. Live: not saved (yet) - say so, so ShopService
		-- doesn't acknowledge a receipt (Roblox retries it) and the next autosave tries again.
		return memoryOnly
	end
	session.data.LastOnline = os.time()
	for attempt = 1, SAVE_ATTEMPTS do
		local ok, err = pcall(function()
			dataStore:UpdateAsync(lockKey(player), function(record)
				record = record or {}
				local lock = record.Lock
				if lock and lock.JobId ~= game.JobId then
					-- Another server took over after our lock expired; its copy wins.
					return nil
				end
				record.Data = session.data
				record.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
				return record
			end)
		end)
		if ok then
			return true
		end
		warn(string.format("[PlayerData] save %d/%d failed for %s: %s", attempt, SAVE_ATTEMPTS, player.Name, tostring(err)))
		if attempt < SAVE_ATTEMPTS then
			task.wait(2 ^ attempt)
		end
	end
	return false
end

local lastLawyersJson: { [Player]: string } = {}

local function syncAttributes(player: Player, data: Data)
	player:SetAttribute("Coins", data.Coins)
	-- lifetime coins earned: egg tiers unlock by it (Formulas.eggUnlocked; StarterPlayerScripts.Eggs shows progress)
	player:SetAttribute("CoinsEarned", if data.Stats then data.Stats.CoinsEarned else 0)
	player:SetAttribute("FreeLevelUps", data.Tutorial.FreeLevelUps)
	player:SetAttribute("FirstCaseDone", data.Tutorial.FirstCaseDone)
	player:SetAttribute("DeskCount", #data.Desks) -- offices
	player:SetAttribute("EggPrice", Formulas.eggPrice(data.Eggs and (data.Eggs.RunOpened or data.Eggs.Opened) or 0, data.Prestige and data.Prestige.Level))
	-- the lawyer inventory, for the LAWYERS panel: { Uid, Id, Stars, Skills, Office }
	local list, placed = {}, 0
	local officeByUid = {}
	for index, office in data.Desks do
		if office.Lawyer then
			officeByUid[office.Lawyer] = index
		end
	end
	for uid, lawyer in data.Lawyers do
		local office = officeByUid[uid]
		if office then
			placed += 1
		end
		table.insert(list, { Uid = uid, Id = lawyer.Id, Stars = lawyer.Stars, Skills = lawyer.Skills, Office = office })
	end
	player:SetAttribute("LawyerCount", placed) -- lawyers working in offices
	player:SetAttribute("LawyersOwned", #list)
	local json = HttpService:JSONEncode(list)
	if lastLawyersJson[player] ~= json then -- only resend the list when it changed
		lastLawyersJson[player] = json
		player:SetAttribute("Lawyers", json)
	end
	player:SetAttribute("FirmSegments", if data.Firm then data.Firm.Segments else Config.Firm.StartSegments)
	player:SetAttribute("PrestigeLevel", if data.Prestige then data.Prestige.Level else 0)
	if data.Manager then
		player:SetAttribute("ManagerHired", data.Manager.Hired)
		player:SetAttribute("ManagerLevels", HttpService:JSONEncode(data.Manager.Levels))
	end
	-- per office: Level / Tier are the office's; the rest mirror the lawyer sitting in it (nil if empty)
	for index, desk in data.Desks do
		local lawyer, uid = PlayerData.lawyerAt(data, index)
		player:SetAttribute("Desk" .. index .. "Level", desk.Level)
		player:SetAttribute("Desk" .. index .. "Tier", Formulas.officeTier(desk.Level))
		player:SetAttribute("Desk" .. index .. "Lawyer", if lawyer then lawyer.Id else nil)
		player:SetAttribute("Desk" .. index .. "LawyerUid", uid)
		player:SetAttribute("Desk" .. index .. "Stars", if lawyer then lawyer.Stars else nil)
		player:SetAttribute("Desk" .. index .. "Skills", if lawyer then HttpService:JSONEncode(lawyer.Skills or {}) else nil)
		player:SetAttribute("Desk" .. index .. "PendingSkill", if lawyer and lawyer.PendingSkill then HttpService:JSONEncode(lawyer.PendingSkill) else nil)
		player:SetAttribute("Desk" .. index .. "SkillRolls", if lawyer then lawyer.SkillRolls or 0 else nil)
		player:SetAttribute("Desk" .. index .. "FreeSkillRolls", if lawyer then lawyer.FreeSkillRolls or 0 else nil)
		player:SetAttribute("Desk" .. index .. "CasesDone", if lawyer then lawyer.CasesDone or 0 else nil)
	end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins") :: StringValue?
	if coins then
		coins.Value = Formulas.formatCoins(data.Coins)
	end
end

-- Yields. Returns nil (and kicks the player) if the data could not be loaded safely.
function PlayerData.load(player: Player): Data?
	local dataStore = getStore()
	-- live server, DataStores down: retry like a failed load, then ask the player to rejoin - never hand them a
	-- fresh firm that would never save (their real save is untouched either way)
	for _ = 2, LOAD_ATTEMPTS do
		if dataStore or memoryOnly or player.Parent == nil then
			break
		end
		task.wait(LOAD_RETRY_DELAY)
		dataStore = getStore()
	end
	if not dataStore and not memoryOnly then
		if player.Parent then
			player:Kick("We couldn't load your law firm. Please rejoin in a minute!")
		end
		return nil
	end
	local data: Data? = nil
	if dataStore then
		local status, saved = "error", nil
		for attempt = 1, LOAD_ATTEMPTS do
			status, saved = acquire(dataStore, lockKey(player))
			if status == "ok" or player.Parent == nil then
				break
			end
			task.wait(LOAD_RETRY_DELAY)
		end
		if status ~= "ok" then
			if player.Parent then
				player:Kick("We couldn't load your law firm. Please rejoin in a minute!")
			end
			return nil
		end
		if saved == nil then
			data = template()
		else
			data = migrate(saved)
		end
		if not data then
			-- Leave the record and lock as they are; the lock expires on its own.
			player:Kick("This server is out of date. Please rejoin!")
			return nil
		end
	else
		data = template()
	end
	local loaded = data :: Data

	local session: Session = { data = loaded, releasing = false }
	sessions[player] = session
	if player.Parent == nil then
		-- Left while we were loading: hand the lock straight back.
		PlayerData.release(player)
		return nil
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	leaderstats.Parent = player
	syncAttributes(player, loaded)
	return loaded
end

function PlayerData.get(player: Player): Data?
	local session = sessions[player]
	return if session and not session.releasing then session.data else nil
end

function PlayerData.addCoins(player: Player, amount: number)
	local data = PlayerData.get(player)
	if not data or amount <= 0 then
		return
	end
	data.Coins += amount
	data.Stats.CoinsEarned += amount
	syncAttributes(player, data)
end

-- Returns false (and changes nothing) if the player can't afford it.
function PlayerData.spendCoins(player: Player, amount: number): boolean
	local data = PlayerData.get(player)
	if not data or amount < 0 or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	syncAttributes(player, data)
	return true
end

-- Call after changing data directly so clients see it.
function PlayerData.sync(player: Player)
	local data = PlayerData.get(player)
	if data then
		syncAttributes(player, data)
	end
end

-- Saves right now and keeps the lock (ShopService: a developer-product grant must be saved before the
-- receipt is acknowledged). True when saved (or when DataStores are off, where nothing is ever saved).
function PlayerData.saveNow(player: Player): boolean
	local session = sessions[player]
	if not session or session.releasing then
		return false
	end
	return write(player, session, false)
end

-- Saves one last time and clears the lock. Safe to call more than once.
function PlayerData.release(player: Player)
	local session = sessions[player]
	if not session or session.releasing then
		return
	end
	session.releasing = true
	write(player, session, true)
	sessions[player] = nil
	lastLawyersJson[player] = nil
end

function PlayerData.start()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, session in sessions do
				if not session.releasing then
					task.spawn(write, player, session, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player in sessions do
			task.spawn(PlayerData.release, player)
		end
		local deadline = os.clock() + 25
		while next(sessions) and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerData
