--!strict
-- The core loop, fully server-side. v16 (egg zones): there is no waiting room any more. Whenever a lawyer is
-- free (and at most every Formulas.clientInterval(lawyers) seconds) a client walks in from the street straight to
-- that lawyer's desk (the Manager sends them to the best-earning free lawyer, otherwise the first free one); the
-- case runs on a timer, the server rolls the outcome and pays out, and the client walks out. Remotes.AssignClient
-- only answers that clients find their lawyer by themselves now. Clients only watch attributes:
-- v12: every office is a desk; an office with no lawyer is "Empty" (shows its EmptyOffice pad and
-- Place Lawyer prompt) and gets no clients. The lawyer sitting in an office is dressed as who they are
-- (Shared.SkinLook) and multiplies the payout (Formulas.lawyerEarn); the office level sets the base.
--   desk model: Phase "Empty" | "Idle" | "Walking" | "Case", ClientTier (index into Config.Clients),
--               CaseStart / CaseEnd (workspace:GetServerTimeNow() timestamps)
--   client NPC (tag FirmClient): OwnerUserId, Tier, AssignedDesk, Seated,
--               Walking + WalkPath / WalkStart / WalkSpeed (animated by StarterPlayerScripts.ClientWalk)
-- The LAWYERS panel reads player attributes instead (desk models stream out when the player is far away):
--   Desk<N>Phase / CaseStart / CaseEnd / ClientName / ClientTier / RestUntil / Queued, and WaitingClients (always
--   an empty JSON list now, kept for the LAWYERS panel).
-- Lawyer changes on a busy office are QUEUED (2026-10-09 lawyer-management overhaul): "unseat" or a bench
-- lawyer's uid waits in desk.queued and is applied the moment the case ends (before anything can give that
-- lawyer a new client). After every case the desk RESTS for Config.Case.RestAfterCase seconds, during which the
-- Manager / self-assigning clients leave it alone, so the player can always catch a lawyer free.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local SkinLook = require(ReplicatedStorage.Shared.SkinLook)
local Effects = require(ReplicatedStorage.Shared.Effects)
local PlayerData = require(script.Parent.PlayerData)
local FirmFeatures = require(script.Parent.FirmFeatures) -- bonuses from bought firm areas
local FirmBuilder = require(script.Parent.FirmBuilder)
local DeskLook = require(script.Parent.DeskLook)

local Templates = ServerStorage:WaitForChild("Templates")
local CaseResult = ReplicatedStorage.Remotes.CaseResult :: RemoteEvent
local AssignClient = ReplicatedStorage.Remotes.AssignClient :: RemoteFunction
local OpenLawyerPicker = ReplicatedStorage.Remotes.OpenLawyerPicker :: RemoteEvent

-- Set while the owner is attending court for the current case. CourtService fills it in.
export type Court = { correct: number, deadline: number, answered: boolean, bonus: number }

export type DeskState = {
	index: number,
	model: Model,
	phase: "Empty" | "Idle" | "Walking" | "Case",
	lawyerUid: string?,
	lawyerModel: Model?,
	client: number?,
	endsAt: number,
	tutorial: boolean,
	clientModel: Model?,
	lawyerLabel: TextLabel?,
	court: Court?,
	player: Player,
	clientName: string?, -- who the lawyer is working for (walking in or on the case)
	restUntil: number, -- auto-assign leaves this desk alone until then (manual assigning still works)
	queued: string?, -- "unseat" or a bench lawyer's uid: applied as soon as the current case ends
}

type Session = {
	player: Player,
	desks: { DeskState },
	rng: Random,
	firm: Model,
	waiting: { [number]: any }, -- always empty (no waiting room since v16); mirrored for the LAWYERS panel
	nextId: number,
	nextArrival: number,
}

local TICK = 0.2
local ARRIVAL_RETRY = 1 -- nobody free: look for a free lawyer again this soon

local CaseService = {}

-- Set by LawyerService: applies a queued lawyer change (uid nil = unseat) once the office is free.
-- Returns false if it no longer applies (the lawyer was merged away, moved, ...).
CaseService.applyQueued = nil :: ((Player, number, string?) -> boolean)?

local sessions: { [Player]: Session } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

-- No words over clients' heads (user's call; lawyers DO get name tags, StarterPlayerScripts.LawyerTags):
-- a client only gets a slim progress bar, shown while their case
-- runs (StarterPlayerScripts.DeskProgress fills it). Who they are lives in attributes (ClientName /
-- Situation) for the Assign picker. The bar is tinted by the client's rarity.
local function caseBar(parent: Model, color: Color3)
	local head = parent:FindFirstChild("Head") :: BasePart
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(84, 14)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.9, 0)
	gui.MaxDistance = 60
	gui.AlwaysOnTop = false
	gui.Enabled = false
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
	bar.BorderSizePixel = 0
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local outline = Instance.new("UIStroke")
	outline.Thickness = 2
	outline.Color = Color3.new(0, 0, 0)
	outline.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	fill.Parent = bar
	bar.Parent = gui
	gui.Parent = parent
end

local function showCaseBar(npc: Model?, on: boolean)
	local gui = npc and npc:FindFirstChild("Nameplate")
	if gui and gui:IsA("BillboardGui") then
		gui.Enabled = on
	end
end

-- Stands an NPC with its feet on the bottom of a spot (floor level). The NPC's pivot is its
-- HumanoidRootPart (mid-body), so lift it by how far that pivot sits above its feet.
local function standOn(npc: Model, spot: BasePart)
	local box, size = npc:GetBoundingBox()
	local pivotAboveFeet = npc:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	npc:PivotTo(spot.CFrame * CFrame.new(0, -spot.Size.Y / 2 + pivotAboveFeet, 0))
end

local function rarityColor(id: string?): Color3
	local def = Formulas.getSkin(id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	return (rarity and Config.RarityColors[rarity.Id]) or Color3.new(1, 1, 1)
end

local function rarityId(id: string?): string?
	local def = Formulas.getSkin(id)
	local rarity = def and Config.Eggs.Skins[def.Rarity]
	return rarity and rarity.Id
end

local function lawyerTitle(lawyer: PlayerData.LawyerData, level: number): string
	return string.format("%s%s · Lv %d", Formulas.lawyerName(lawyer.Id, lawyer.Stars), string.rep("★", lawyer.Stars - 1), level)
end

local function setLawyerLevel(desk: DeskState, level: number)
	desk.model:SetAttribute("LawyerLevel", level)
end

-- Mirrors one office's live state onto the player (the LAWYERS panel works anywhere, even with the firm
-- streamed out).
local function mirror(desk: DeskState)
	local p, key = desk.player, "Desk" .. desk.index
	local busy = desk.phase == "Case" or desk.phase == "Walking"
	p:SetAttribute(key .. "Phase", desk.phase)
	p:SetAttribute(key .. "CaseStart", if desk.phase == "Case" then desk.model:GetAttribute("CaseStart") else nil)
	p:SetAttribute(key .. "CaseEnd", if desk.phase == "Case" then desk.endsAt else nil)
	p:SetAttribute(key .. "ClientTier", if busy then desk.client else nil)
	p:SetAttribute(key .. "ClientName", if busy then desk.clientName else nil)
	p:SetAttribute(key .. "RestUntil", if desk.phase == "Idle" and desk.restUntil > now() then desk.restUntil else nil)
	p:SetAttribute(key .. "Queued", desk.queued)
end

-- Makes the desk match the saved office: spawns / dresses / removes the lawyer, shows the empty-office
-- pad when nobody sits here, and sets the phase ("Empty" or "Idle"; a busy desk keeps its phase).
local function applyLawyer(desk: DeskState, data: PlayerData.Data)
	local office = data.Desks[desk.index]
	local lawyer, uid = PlayerData.lawyerAt(data, desk.index)
	if uid ~= desk.lawyerUid and desk.lawyerModel then
		desk.lawyerModel:Destroy()
		desk.lawyerModel = nil
		desk.lawyerLabel = nil
	end
	if uid ~= desk.lawyerUid and lawyer then
		-- a lawyer who just sat down gets the same short rest as after a case, so the player can hand them a
		-- client before a self-assigning client / the Manager does
		desk.restUntil = now() + Config.Case.RestAfterCase
	end
	desk.lawyerUid = uid
	if lawyer and not desk.lawyerModel then
		local npc = Templates.NPC:Clone()
		npc.Name = "Lawyer"
		standOn(npc, desk.model:FindFirstChild("LawyerSpot") :: BasePart)
		npc.Parent = desk.model
		SkinLook.dress(npc, lawyer.Id)
		desk.lawyerModel = npc
	end
	if lawyer and desk.lawyerModel then
		SkinLook.dress(desk.lawyerModel, lawyer.Id) -- (re-dress: merging can change nothing visible but stars)
		-- Shared.Effects aura, laddered by rarity and stars (Rare sparkle .. Legendary gold .. Rainbow merge)
		Effects.aura(desk.lawyerModel, rarityId(lawyer.Id), lawyer.Stars)
	end
	if desk.lawyerLabel and lawyer then
		desk.lawyerLabel.Text = lawyerTitle(lawyer, office.Level)
	end
	local pad = desk.model:FindFirstChild("EmptyOffice") :: BasePart?
	if pad then
		-- the lawyer is the focal point of the office: they stand on a glowing pad in their rarity colour
		-- (empty office: the gold "place a lawyer" pad)
		pad.Transparency = if lawyer then 0.25 else 0.15
		pad.Color = if lawyer then rarityColor(lawyer.Id) else Color3.fromRGB(255, 190, 50)
		local glow = pad:FindFirstChild("LawyerGlow") :: PointLight?
		if not glow then
			glow = Instance.new("PointLight")
			glow.Name = "LawyerGlow"
			glow.Range = 9
			glow.Brightness = 1.4
			glow.Shadows = false
			glow.Parent = pad
		end
		local light = glow :: PointLight
		light.Enabled = lawyer ~= nil
		light.Color = pad.Color
		local label = pad:FindFirstChild("EmptyLabel") :: BillboardGui?
		if label then
			label.Enabled = lawyer == nil
		end
		local prompt = pad:FindFirstChild("PlacePrompt") :: ProximityPrompt?
		if prompt then
			prompt.Enabled = lawyer == nil
		end
	end
	desk.model:SetAttribute("LawyerId", if lawyer then lawyer.Id else nil)
	desk.model:SetAttribute("LawyerStars", if lawyer then lawyer.Stars else nil) -- for the overhead name tag (LawyerTags)
	setLawyerLevel(desk, office.Level)
	if not lawyer then
		desk.phase = "Empty"
		desk.model:SetAttribute("Phase", "Empty")
	elseif desk.phase == "Empty" then
		desk.phase = "Idle"
		desk.model:SetAttribute("Phase", "Idle")
	end
	mirror(desk)
	DeskLook.apply(desk.model, Formulas.officeTier(office.Level))
end

local function removeClient(desk: DeskState)
	if desk.clientModel then
		desk.clientModel:Destroy()
		desk.clientModel = nil
	end
end

-- A client NPC for this tier: one of the Blender characters for it (Config.ClientCharacters), or the
-- blocky NPC in the tier's colour for tiers without a model yet. forceId picks a specific character.
local function makeClientModel(tier: number, rng: Random, forceId: string?): Model
	local client = Config.Clients[tier]
	local color = Config.RarityColors[client.Id] or Color3.new(1, 1, 1)
	local options = {}
	for _, def in Config.ClientCharacters do
		if def.Tier == tier then
			table.insert(options, def)
		end
	end
	local def = nil
	for _, d in options do
		if d.Id == forceId then
			def = d
		end
	end
	if not def and #options > 0 then
		def = options[rng:NextInteger(1, #options)]
	end
	local folder = Templates:FindFirstChild("Clients")
	local source = def and folder and folder:FindFirstChild(def.Id)
	local npc: Model
	if source and source:IsA("Model") then
		npc = source:Clone()
	else
		npc = Templates.NPC:Clone()
		for _, name in { "Torso", "Left Arm", "Right Arm" } do
			local p = npc:FindFirstChild(name)
			if p and p:IsA("BasePart") then
				p.Color = color
			end
		end
	end
	npc.Name = "Client"
	npc:SetAttribute("Tier", tier)
	npc:SetAttribute("CharacterId", if def then def.Id else nil) -- the courtroom picks a different one for the defendant
	npc:SetAttribute("ClientId", if def then def.Id else nil) -- CourtService picks this character's questions
	npc:SetAttribute("ClientName", if def then def.Name else client.Name)
	npc:SetAttribute("Situation", if def then def.Situation else client.Situation)
	caseBar(npc, color)
	return npc
end

-- Stands an NPC with its feet at a world point, facing a direction.
local function standAt(npc: Model, at: Vector3, look: Vector3)
	local box, size = npc:GetBoundingBox()
	local pivotAboveFeet = npc:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	npc:PivotTo(CFrame.lookAt(at, at + flat) + Vector3.new(0, pivotAboveFeet, 0))
end

-- Walks an NPC along world points. The server parks it at the start, tells every client how to
-- animate the walk (StarterPlayerScripts.ClientWalk reads the Walk* attributes), then moves it to
-- the end when the walk is over and calls onDone.
local function walk(npc: Model, points: { Vector3 }, finalLook: Vector3?, onDone: () -> ())
	local total = 0
	local encoded = {}
	for i, p in points do
		table.insert(encoded, { p.X, p.Y, p.Z })
		if i > 1 then
			total += (p - points[i - 1]).Magnitude
		end
	end
	local speed = Config.Firm.WalkSpeed
	local last = points[#points]
	local look = finalLook or (last - (points[#points - 1] or last))
	standAt(npc, points[1], (points[2] or last) - points[1])
	npc:SetAttribute("Seated", false)
	npc:SetAttribute("WalkPath", HttpService:JSONEncode(encoded))
	npc:SetAttribute("WalkSpeed", speed)
	npc:SetAttribute("WalkStart", now())
	npc:SetAttribute("Walking", true)
	task.delay(total / speed, function()
		if npc.Parent then
			standAt(npc, last, look)
			-- where it really stands now, so ClientWalk can snap its walk-posed parts back (set before Walking)
			npc:SetAttribute("RestPivot", npc:GetPivot())
			npc:SetAttribute("Walking", false)
			onDone()
		end
	end)
end

local function toWorld(session: Session, points: { Vector3 }): { Vector3 }
	local frame = session.firm.WorldPivot
	local out = {}
	for _, p in points do
		table.insert(out, frame:PointToWorldSpace(p))
	end
	return out
end

local function clientsFolder(session: Session): Instance
	return session.firm:FindFirstChild("WaitingClients") or session.firm
end

local function setPhase(desk: DeskState, phase: "Empty" | "Idle" | "Walking" | "Case")
	desk.phase = phase
	desk.model:SetAttribute("Phase", phase)
	mirror(desk)
end

-- The LAWYERS panel's client list: empty since clients walk straight to their lawyer (v16).
local function mirrorWaiting(session: Session)
	session.player:SetAttribute("WaitingClients", HttpService:JSONEncode({}))
end

-- Every bonus source for one desk's case: office tier, the lawyer's skills, the Manager, plus extras.
-- (The lawyer's rarity/stars are not a buff: Formulas.lawyerEarn multiplies the payout after caps.)
local function deskBuffs(data: PlayerData.Data, index: number, clientTier: number?, extra: { Formulas.BuffSource }?): Formulas.Buffs
	local office = data.Desks[index]
	local lawyer = PlayerData.lawyerAt(data, index)
	local sources: { Formulas.BuffSource } = {
		{ payout = Config.Desks.Tiers[Formulas.officeTier(office.Level)].PayoutBonus },
	}
	for _, source in Formulas.skillSources(lawyer and lawyer.Skills, clientTier) do
		table.insert(sources, source)
	end
	for _, source in Formulas.managerSources(data.Manager and data.Manager.Levels) do
		table.insert(sources, source)
	end
	for _, source in FirmFeatures.sourcesFor(data) do -- bought firm areas (Config.FirmAreas)
		table.insert(sources, source)
	end
	for _, source in extra or {} do
		table.insert(sources, source)
	end
	return Formulas.combineBuffs(sources)
end

local function startCase(session: Session, desk: DeskState, tier: number, tutorial: boolean)
	local data = PlayerData.get(session.player)
	if not data then
		return
	end
	local buffs = deskBuffs(data, desk.index, tier)
	local duration = if tutorial then Config.Case.TutorialDuration else Formulas.caseDuration(Config.Clients[tier], buffs)
		* (require(script.Parent.ShopService) :: any).effect(session.player, "SpeedyCases", 1) -- Robux pass

	if not desk.clientModel then
		-- normally the client walked here from the waiting room; this is only a safety net
		local npc = makeClientModel(tier, session.rng)
		standOn(npc, desk.model:FindFirstChild("ClientSpot") :: BasePart)
		npc.Parent = desk.model
		desk.clientModel = npc
	end
	desk.clientName = (desk.clientModel :: Model):GetAttribute("ClientName") :: string?
	desk.client = tier
	desk.tutorial = tutorial
	desk.court = nil
	local start = now()
	desk.endsAt = start + duration
	desk.model:SetAttribute("ClientTier", tier)
	desk.model:SetAttribute("CaseStart", start)
	desk.model:SetAttribute("CaseEnd", desk.endsAt)
	desk.model:SetAttribute("Tutorial", tutorial)
	desk.model:SetAttribute("CourtDone", false)
	showCaseBar(desk.clientModel, true)
	setPhase(desk, "Case")
end

-- The case is over: the client walks out of the firm and the lawyer is free for the next one.
local function releaseDesk(session: Session, desk: DeskState)
	local npc = desk.clientModel
	desk.clientModel = nil
	desk.client = nil
	desk.clientName = nil
	desk.court = nil
	desk.model:SetAttribute("ClientTier", nil)
	desk.restUntil = now() + Config.Case.RestAfterCase
	setPhase(desk, "Idle")
	-- a lawyer change the player asked for during the case happens now, before anyone can book this lawyer again
	local queued = desk.queued
	if queued then
		desk.queued = nil
		local apply = CaseService.applyQueued
		local ok, err = pcall(function()
			return apply and apply(session.player, desk.index, if queued == "unseat" then nil else queued)
		end)
		if not ok then
			warn("[CaseService] queued lawyer change failed:", err)
		end
		mirror(desk)
	end
	showCaseBar(npc, false)
	if npc then
		npc.Parent = clientsFolder(session)
		walk(npc, toWorld(session, FirmBuilder.routeDeskToExit(desk.index)), nil, function()
			npc:Destroy()
		end)
	end
end

local function resolveCase(session: Session, desk: DeskState)
	local player = session.player
	local data = PlayerData.get(player)
	local tier = desk.client
	if not data or not tier then
		return
	end
	local deskData = data.Desks[desk.index]
	local lawyer = PlayerData.lawyerAt(data, desk.index)
	local client = Config.Clients[tier]
	local court = desk.court
	local courtBonus = if court then court.bonus else 0
	local buffs = deskBuffs(data, desk.index, tier, { { payout = courtBonus } })

	local outcome, fraction
	if desk.tutorial then
		outcome, fraction = "Win", 1
		data.Tutorial.FirstCaseDone = true
	else
		local chance = Formulas.winChance(deskData.Level, client.Difficulty, buffs.winChanceBonus)
		outcome, fraction = Formulas.rollOutcome(session.rng, chance)
		-- Manager's Settlement Bot: some mistrials settle instead
		local settle = Formulas.managerValue(data.Manager and data.Manager.Levels, "settle")
		if outcome == "Mistrial" and session.rng:NextNumber() < settle then
			outcome = "Settlement"
			fraction = session.rng:NextNumber(Config.Payout.SettlementMin, Config.Payout.SettlementMax)
		end
	end

	local payout = Formulas.casePayout(deskData.Level, client, buffs, fraction)
	local earn = if lawyer then Formulas.lawyerEarn(lawyer.Id, lawyer.Stars) else 1
	payout = math.floor(payout * earn * Formulas.prestigeMultiplier(data.Prestige and data.Prestige.Level)
		* (require(script.Parent.ShopService) :: any).effect(player, "DoubleCash", 1)) -- Robux pass, after the buff caps
	if outcome == "Win" then
		data.Stats.Wins += 1
	elseif outcome == "Settlement" then
		data.Stats.Settlements += 1
	else
		data.Stats.Mistrials += 1
	end
	data.Stats.BestPayout = math.max(data.Stats.BestPayout, payout)
	if outcome ~= "Mistrial" and lawyer then
		-- every CasesPerFreeRoll finished cases earns this lawyer a free skill roll
		lawyer.CasesDone = (lawyer.CasesDone or 0) + 1
		if lawyer.CasesDone % Config.Skills.CasesPerFreeRoll == 0 then
			lawyer.FreeSkillRolls = (lawyer.FreeSkillRolls or 0) + 1
		end
	end
	PlayerData.addCoins(player, payout) -- also syncs the attributes above
	if outcome == "Win" then
		local Badges = require(script.Parent.BadgeAwards) :: any
		-- (spawned: badge calls yield / can throw, and must never hold up or break the case result)
		task.spawn(Badges.award, player, "FirstWin")
		if client.Id == "Legendary" then
			task.spawn(Badges.award, player, "LegendaryWin")
		end
		if tier >= 4 and not desk.tutorial then
			-- a big win (Epic / Legendary client): coins and gold sparkles burst out of the office
			local spot = desk.model:FindFirstChild("ClientSpot") :: BasePart?
			if spot then
				Effects.burst(spot.Position + Vector3.new(0, 3, 0), "win")
			end
		end
		local GoalService = require(script.Parent.GoalService) :: any
		GoalService.track(player, "win")
		if client.Multiplier >= Config.Clients[3].Multiplier then -- Rare or better
			GoalService.track(player, "rareWin")
		end
	end

	CaseResult:FireClient(player, {
		desk = desk.index,
		outcome = outcome,
		payout = payout,
		clientTier = tier,
		tutorial = desk.tutorial,
		attended = court ~= nil,
		courtBonus = courtBonus,
	})

	if outcome == "Mistrial" and not desk.queued then
		-- Same client, same case, runs again (unless the player is swapping this lawyer out: then the client
		-- leaves - a mistrial pays nothing either way - so the swap isn't stuck behind endless reruns). No coins lost, and a court bonus already earned carries over.
		startCase(session, desk, tier, false)
		if court and court.bonus > 0 then
			desk.court = court
			desk.model:SetAttribute("CourtDone", true)
		end
	else
		releaseDesk(session, desk)
	end
end

------------------------------------------------------------------------------------------- arrivals

-- The skills of the lawyer in the highest-level office (Charming makes rare clients walk in more often).
local function bestSkills(data: PlayerData.Data): { Formulas.OwnedSkill }?
	local best, level = nil, -1
	for index, d in data.Desks do
		local lawyer = PlayerData.lawyerAt(data, index)
		if lawyer and d.Level > level then
			best, level = lawyer.Skills, d.Level
		end
	end
	return best
end

local function workingLawyers(session: Session): number
	local n = 0
	for _, desk in session.desks do
		if desk.phase ~= "Empty" then
			n += 1
		end
	end
	return n
end

-- The free lawyer a new client walks to: with a Manager, the office that earns the most per case (office level and
-- lawyer power); without one, the first free office. A desk that is resting after a case is skipped until `t`
-- passes its restUntil, so the player can always catch a lawyer free to swap them.
local function freeDesk(session: Session, data: PlayerData.Data, t: number): DeskState?
	local managed = data.Manager and data.Manager.Hired
	local best, bestScore = nil, -math.huge
	for _, desk in session.desks do
		local d = data.Desks[desk.index]
		local lawyer = PlayerData.lawyerAt(data, desk.index)
		if desk.phase == "Idle" and d and lawyer and t >= desk.restUntil and desk.model.Parent and desk.model:FindFirstChild("ClientSpot") then
			local score = if managed then Formulas.basePayout(d.Level) * Formulas.lawyerEarn(lawyer.Id, lawyer.Stars) else -desk.index
			if score > bestScore then
				best, bestScore = desk, score
			end
		end
	end
	return best
end

-- A new client walks in from the street straight to a free lawyer's desk. Returns whether one came.
-- The tutorial starts with a single client (Neighbor Dave), who doesn't wait for the new lawyer's rest.
local function spawnArrival(session: Session): boolean
	local data = PlayerData.get(session.player)
	if not data then
		return false
	end
	local tutorial = not data.Tutorial.FirstCaseDone
	if tutorial then
		for _, d in session.desks do
			if d.phase == "Walking" or d.phase == "Case" then
				return false
			end
		end
	end
	local desk = freeDesk(session, data, if tutorial then math.huge else now())
	if not desk then
		return false
	end
	local tier, forceId = 1, "NeighborDave"
	if not tutorial then
		local referral = Formulas.managerValue(data.Manager and data.Manager.Levels, "rareClients") + FirmFeatures.rareClients(data)
		tier = Formulas.rollClient(session.rng, Formulas.clientWeightsFor(bestSkills(data), referral))
		forceId = nil
	end
	session.nextId += 1
	local npc = makeClientModel(tier, session.rng, forceId)
	npc:SetAttribute("OwnerUserId", session.player.UserId)
	npc:SetAttribute("AssignedDesk", desk.index)
	CollectionService:AddTag(npc, "FirmClient")
	npc.Parent = clientsFolder(session)
	desk.client = tier
	desk.clientName = npc:GetAttribute("ClientName") :: string?
	desk.model:SetAttribute("ClientTier", tier)
	setPhase(desk, "Walking")
	local spot = desk.model:FindFirstChild("ClientSpot") :: BasePart
	local tutorialCase = tutorial and Config.Tutorial.FirstCaseGuaranteedWin
	walk(npc, toWorld(session, FirmBuilder.routeToDesk(desk.index)), spot.CFrame.LookVector, function()
		if sessions[session.player] ~= session or not desk.model.Parent or desk.phase ~= "Walking" then
			npc:Destroy()
			return
		end
		npc.Parent = desk.model
		desk.clientModel = npc
		startCase(session, desk, tier, tutorialCase)
	end)
	return true
end

-- Sets up an office's desk model: its lawyer (if any), its look, and the Place Lawyer prompt.
local function setupDesk(session: Session, index: number, model: Model, data: PlayerData.Data)
	local player = session.player
	local desk: DeskState = {
		index = index,
		model = model,
		phase = "Empty",
		client = nil,
		endsAt = 0,
		tutorial = false,
		player = player,
		restUntil = 0,
	}
	model:SetAttribute("OwnerUserId", player.UserId)
	local prompt = model:FindFirstChild("PlacePrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Triggered:Connect(function(who)
			if who == player then
				OpenLawyerPicker:FireClient(player, index) -- the client opens the LAWYERS panel for this office
			end
		end)
	end
	table.insert(session.desks, desk)
	setPhase(desk, "Empty")
	applyLawyer(desk, data)
end

function CaseService.start(player: Player, firm: Model)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local session: Session = {
		player = player,
		desks = {},
		rng = Random.new(),
		firm = firm,
		waiting = {},
		nextId = 0,
		nextArrival = now() + 1.5,
	}
	if not firm:FindFirstChild("WaitingClients") then
		local folder = Instance.new("Folder")
		folder.Name = "WaitingClients"
		folder.Parent = firm
	end
	for index in data.Desks do
		local model = firm:FindFirstChild("Desk" .. index) :: Model?
		if model then
			setupDesk(session, index, model, data)
		end
	end
	sessions[player] = session
	mirrorWaiting(session)
end

-- A desk hired mid-session (DeskService builds the model first).
function CaseService.addDesk(player: Player, index: number, model: Model)
	local session = sessions[player]
	local data = PlayerData.get(player)
	if session and data and data.Desks[index] and not CaseService.getDesk(player, index) then
		setupDesk(session, index, model, data)
	end
end

-- Called by LawyerService after an office's level or lawyer changes: re-applies the lawyer, nameplate,
-- empty-office pad and office look. celebrate = confetti burst on the desk.
function CaseService.refreshDesk(player: Player, index: number, celebrate: boolean?)
	local session = sessions[player]
	local data = PlayerData.get(player)
	if not session or not data then
		return
	end
	for _, desk in session.desks do
		if desk.index == index then
			applyLawyer(desk, data)
			if celebrate then
				DeskLook.celebrate(desk.model)
			end
		end
	end
end

-- A one-shot Shared.Effects burst over an office's lawyer spot (merges, new office tier, legendary placed).
function CaseService.burst(player: Player, index: number, kind: string)
	local desk = CaseService.getDesk(player, index)
	local spot = desk and desk.model:FindFirstChild("LawyerSpot") :: BasePart?
	if spot then
		Effects.burst(spot.Position + Vector3.new(0, 3, 0), kind)
	end
end

function CaseService.getDesk(player: Player, index: number): DeskState?
	local session = sessions[player]
	if not session then
		return nil
	end
	for _, desk in session.desks do
		if desk.index == index then
			return desk
		end
	end
	return nil
end

-- Pushes the verdict back so it can't land while the player is still answering. Never shortens.
function CaseService.extendCase(desk: DeskState, untilTime: number)
	if desk.phase == "Case" and desk.endsAt < untilTime then
		desk.endsAt = untilTime
		desk.model:SetAttribute("CaseEnd", untilTime)
		mirror(desk)
	end
end

-- Queues a lawyer change for a busy office ("unseat" or a bench lawyer's uid); nil cancels. The caller
-- (LawyerService) has validated it. Returns false if the office isn't busy (do it right away instead).
function CaseService.setQueued(player: Player, index: number, change: string?): boolean
	local desk = CaseService.getDesk(player, index)
	if not desk or not (desk.phase == "Case" or desk.phase == "Walking") then
		return false
	end
	desk.queued = change
	mirror(desk)
	return true
end

function CaseService.queuedChange(player: Player, index: number): string?
	local desk = CaseService.getDesk(player, index)
	return desk and desk.queued
end

-- Finishes every running case right now, as if its time were up: it pays out (or settles / mistrials) as usual and
-- any lawyer change queued on it is applied. Firm expansion calls this before rebuilding (audit 2026-10-12: the
-- rebuild used to throw running cases away unpaid, and with auto-assign there's never a moment with none running).
-- Clients still walking in just leave (nothing earned yet). A mistrial reruns as usual and the rebuild then drops it.
function CaseService.finishAll(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	for _, desk in session.desks do
		if desk.phase == "Case" then
			desk.model:SetAttribute("AwaitingCourt", nil)
			local ok, err = pcall(resolveCase, session, desk)
			if not ok then
				warn("[CaseService] finishAll failed:", err)
				releaseDesk(session, desk)
			end
		end
	end
end

function CaseService.stop(player: Player)
	sessions[player] = nil
end

function CaseService.run()
	-- (no waiting room since v16: clients walk straight to a free lawyer)
	AssignClient.OnServerInvoke = function(): (boolean, string?)
		return false, "Clients walk straight to a free lawyer now"
	end
	task.spawn(function()
		while true do
			task.wait(TICK)
			local t = now()
			for _, session in sessions do
				if t >= session.nextArrival then
					local ok, came = pcall(spawnArrival, session)
					if not ok then
						warn("[CaseService] arrival failed:", came)
					end
					-- one client per clientInterval while a lawyer is free; nobody free: check again soon
					session.nextArrival = t + (if ok and came then Formulas.clientInterval(workingLawyers(session)) else ARRIVAL_RETRY)
				end
				for _, desk in session.desks do
					if desk.phase ~= "Case" or t < desk.endsAt then
						continue
					end
					-- the tutorial case is a guaranteed court case: hold the verdict until the player has been
					-- to court (CourtService extends it from there), or Config.Tutorial.CourtWait runs out
					if desk.tutorial and not desk.court and Config.Tutorial.FirstCaseInCourt and t < desk.endsAt + Config.Tutorial.CourtWait then
						desk.model:SetAttribute("AwaitingCourt", true)
						continue
					end
					desk.model:SetAttribute("AwaitingCourt", nil)
					local ok, err = pcall(resolveCase, session, desk)
					if not ok then
						warn("[CaseService] resolve failed:", err)
						releaseDesk(session, desk)
					end
				end
			end
		end
	end)
end

return CaseService
