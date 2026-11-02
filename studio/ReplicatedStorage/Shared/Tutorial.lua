--!strict
-- The tutorial (2026-11-01, crnuch: "revamp the tutorial to better fit the current game"). One place that says which
-- step a player is on, read by StarterPlayerScripts.Hud (the STEP n/8 hint) and StarterPlayerScripts.Guide (the green
-- line). Worked out from player attributes every time, so nothing new is saved and a player who has hatched a bought
-- egg (EggsOpened >= 1: the free egg isn't counted) never sees it again.
--   1 the first client (Neighbor Dave) walks to your lawyer       5 put the hatched lawyer in the glowing empty office
--   2 Dave's case goes to court: GO TO COURT                       6 TRAVEL to Briefcase Bay for more eggs
--   3 the free office upgrade (LAWYERS > UPGRADE OFFICE)           7 buy an egg there
--   4 hatch the free egg at your incubator                         8 take it home (RETURN HOME) and hatch it
-- Tutorial.current(player) -> step (or nil when there is no tutorial step), the hint text, the part the line points at.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared:WaitForChild("Config")) :: any
local Formulas = require(ReplicatedStorage.Shared:WaitForChild("Formulas")) :: any

local Tutorial = {}

Tutorial.STEPS = Config.Tutorial.Steps
-- away from the hub = on an egg island (the hub's top is ~500 studs across from its centre; the islands sit ~760 out)
local ISLAND_DISTANCE = 520

local function num(player: Player, name: string): number
	return (player:GetAttribute(name) or 0) :: number
end

local function firmOf(player: Player): Instance?
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = typeof(plotName) == "string" and plots and plots:FindFirstChild(plotName)
	return plot and plot:FindFirstChild("Firm")
end

-- The office the tutorial case is in (only asked before the first case is done, when it is the only busy one).
local function tutorialDesk(firm: Instance): Instance?
	for _, d in firm:GetChildren() do
		local phase = d:GetAttribute("Phase")
		if phase == "Walking" or phase == "Case" then
			return d
		end
	end
	return nil
end

local function incubator(firm: Instance?): BasePart?
	local incubators = firm and firm:FindFirstChild("Incubators")
	local inc = incubators and incubators:FindFirstChildWhichIsA("Model")
	local part = inc and inc:FindFirstChild("Base")
	return if part and part:IsA("BasePart") then part else nil
end

local function emptyOffice(player: Player, firm: Instance?): BasePart?
	if not firm then
		return nil
	end
	for i = 1, num(player, "DeskCount") do
		if player:GetAttribute("Desk" .. i .. "Lawyer") == nil then
			local desk = firm:FindFirstChild("Desk" .. i)
			local pad = desk and desk:FindFirstChild("EmptyOffice")
			return if pad and pad:IsA("BasePart") then pad else nil
		end
	end
	return nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- The player's root position, and whether they're out on an egg island.
local function where(player: Player): (Vector3?, boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil, false
	end
	local hub = workspace:GetAttribute("HubCentre")
	local away = typeof(hub) == "Vector3" and (flat(root.Position) - flat(hub)).Magnitude > ISLAND_DISTANCE
	return root.Position, away
end

local function nearest(parts: { BasePart }, from: Vector3?): BasePart?
	local best, bestD = nil, math.huge
	for _, p in parts do
		local d = if from then (p.Position - from).Magnitude else 0
		if d < bestD then
			best, bestD = p, d
		end
	end
	return best
end

local function portal(): BasePart?
	local hub = workspace:FindFirstChild("Hub")
	local tp = hub and hub:FindFirstChild("TravelPortal")
	if not tp then
		return nil
	end
	local part = (tp :: any).PrimaryPart or tp:FindFirstChild("Stage_White") or tp:FindFirstChildWhichIsA("BasePart", true)
	return if part and part:IsA("BasePart") then part else nil
end

local function returnHome(from: Vector3?): BasePart?
	local wiring = workspace:FindFirstChild("IslandWiring")
	local list = {}
	for _, d in (if wiring then wiring:GetDescendants() else {}) do
		if d.Name == "ReturnHome" and d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return nearest(list, from)
end

local function egg(from: Vector3?): BasePart?
	local list = {}
	for _, m in CollectionService:GetTagged("ZoneEgg") do
		if m:GetAttribute("Golden") ~= true then -- the plain egg: golden ones cost 5x
			local part = (m :: any).PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
			if part then
				table.insert(list, part)
			end
		end
	end
	return nearest(list, from)
end

function Tutorial.current(player: Player): (number?, string?, BasePart?)
	if not player:GetAttribute("Desk1Level") then
		return nil, nil, nil
	end
	local firm = firmOf(player)
	-- 1-2: the first case (Neighbor Dave), which always goes to court
	if player:GetAttribute("FirstCaseDone") ~= true then
		local desk = firm and tutorialDesk(firm)
		local phase = desk and desk:GetAttribute("Phase")
		if phase == "Case" and desk and not desk:GetAttribute("CourtDone") then
			return 2, "Dave's case is going to COURT! Tap GO TO COURT", nil
		elseif phase == "Case" then
			return 2, "Your lawyer is wrapping up Dave's case...", nil
		elseif phase == "Walking" then
			return 1, "Neighbor Dave is walking straight to your lawyer!", nil
		end
		return 1, "Your first client is on the way...", nil
	end
	-- 3: the free office upgrade
	if num(player, "FreeLevelUps") > 0 then
		return 3, "You won! Open LAWYERS and tap UPGRADE OFFICE: your first one is FREE", nil
	end
	local owned, working = num(player, "LawyersOwned"), num(player, "LawyerCount")
	-- 4: the free egg
	if player:GetAttribute("FreeEgg") == true and owned <= 1 then
		return 4, "Follow the green line to your INCUBATOR and hatch your FREE egg!", incubator(firm)
	end
	-- 5: equip the new lawyer
	if owned > working and working < num(player, "DeskCount") and owned <= 2 then
		return 5, "Walk to the glowing EMPTY OFFICE to put your new lawyer to work", emptyOffice(player, firm)
	end
	-- 6-8: the loop the game runs on - eggs come from the islands
	if num(player, "EggsOpened") >= 1 then
		return nil, nil, nil
	end
	local pos, away = where(player)
	local carrying = (player:GetAttribute("Carried") or "") ~= ""
	if carrying and away then
		return 8, "Got it! Step into the RETURN HOME portal: it takes you home WITH your egg", returnHome(pos)
	elseif carrying then
		return 8, "Take your egg to your INCUBATOR and hatch it!", incubator(firm)
	elseif away then
		local price = player:GetAttribute("EggPrice")
		local cost = if type(price) == "number" then " (" .. Formulas.formatCoins(price) .. ")" else ""
		return 7, "Walk up to an EGG and tap BUY EGG" .. cost, egg(pos)
	end
	return 6, "More lawyers come from EGGS on the islands! Tap TRAVEL and fly to BRIEFCASE BAY", portal()
end

Tutorial.DONE_TEXT = "Hatch better lawyers, buy a LAW LICENSE for new islands and keep upgrading your offices!"

return Tutorial
