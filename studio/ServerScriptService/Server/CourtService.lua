--!strict
-- Optional "Attend Court" minigame. A player watching a running case gets one evidence question;
-- the right card adds Config.Courtroom.CorrectAnswerBonus to that case's payout. A wrong card or a
-- timeout just means the normal payout. Skipping court never costs anything.
-- The tutorial's first case (Neighbor Dave) always goes to court (Config.Tutorial.FirstCaseInCourt) and
-- gets TUTORIAL_PROMPT, a question about his actual ticket.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CaseService = require(script.Parent.CaseService)
local EvidenceCards = require(script.Parent.EvidenceCards)
local ClientEvidence = require(script.Parent.ClientEvidence) -- per client character; EvidenceCards = per tier fallback

local Remotes = ReplicatedStorage.Remotes
local AttendCourt = Remotes.AttendCourt :: RemoteFunction
local AnswerEvidence = Remotes.AnswerEvidence :: RemoteFunction
local CourtEvent = Remotes.CourtEvent :: RemoteEvent
local ReactCourtEvent = Remotes.ReactCourtEvent :: RemoteFunction

local EVENTS = { "Surprise witness!", "Hidden evidence found!", "The jury gasps!", "The judge woke up!", "Dramatic plot twist!" }
local EVENT_GRACE = 1 -- extra seconds the server accepts for network lag
-- First card is the right one (shuffled before sending, like EvidenceCards).
local TUTORIAL_PROMPT = {
	Question = "Dave got a ticket for parking in his OWN driveway! Which evidence proves he did nothing wrong?",
	Cards = { "House deed: the driveway belongs to Dave", "Dave's favorite sandwich", "A drawing of a cat" },
}

local CourtService = {}

local rng = Random.new()
-- Last prompt shown per question set (client character or tier), so the same question doesn't come up twice in a row.
local lastPrompt: { [Player]: { [any]: number } } = {}

local function isWholeNumber(value: unknown): boolean
	return type(value) == "number" and value == value // 1
end

local function attend(player: Player, deskIndex: unknown): (any, string?)
	if not isWholeNumber(deskIndex) then
		return nil, "Bad desk"
	end
	local desk = CaseService.getDesk(player, deskIndex :: number)
	if not desk or desk.phase ~= "Case" or not desk.client then
		return nil, "No case right now"
	end
	if desk.tutorial and not Config.Tutorial.FirstCaseInCourt then
		return nil, "Finish your first case first!"
	end
	if desk.court then
		return nil, "Already been to court for this case"
	end

	local tier = desk.client :: number
	-- this client's own case if they have one (ClientEvidence), else their tier's set
	local clientId = desk.clientModel and desk.clientModel:GetAttribute("ClientId")
	local own = typeof(clientId) == "string" and ClientEvidence[clientId] or nil
	local set = own or EvidenceCards[tier]
	local setKey: any = if own then clientId else tier
	local history = lastPrompt[player] or {}
	lastPrompt[player] = history
	local index = rng:NextInteger(1, #set.Prompts)
	if #set.Prompts > 1 and index == history[setKey] then
		index = index % #set.Prompts + 1
	end
	history[setKey] = index
	local prompt = if desk.tutorial then TUTORIAL_PROMPT else set.Prompts[index]

	local order = {}
	for i = 1, #prompt.Cards do
		order[i] = i
	end
	rng:Shuffle(order)
	local cards, correct = {}, 1
	for position, original in order do
		cards[position] = prompt.Cards[original]
		if original == 1 then
			correct = position
		end
	end

	local t = workspace:GetServerTimeNow()
	local courtConfig = Config.Courtroom
	desk.court = {
		correct = correct,
		deadline = t + courtConfig.AnswerTime + courtConfig.AnswerGrace,
		answered = false,
		bonus = 0,
	}
	desk.model:SetAttribute("CourtDone", true)
	CaseService.extendCase(desk, t + courtConfig.AnswerTime + courtConfig.VerdictBuffer)

	return {
		question = prompt.Question,
		cards = cards,
		answerTime = courtConfig.AnswerTime,
		opponent = set.Opponent,
		bonus = courtConfig.CorrectAnswerBonus,
	}
end

local function answer(player: Player, deskIndex: unknown, cardIndex: unknown): any
	if not isWholeNumber(deskIndex) or not isWholeNumber(cardIndex) then
		return nil
	end
	local desk = CaseService.getDesk(player, deskIndex :: number)
	local court = desk and desk.court
	if not court or court.answered then
		return nil
	end
	court.answered = true
	local onTime = workspace:GetServerTimeNow() <= court.deadline
	local correct = onTime and cardIndex == court.correct
	if correct then
		court.bonus = Config.Courtroom.CorrectAnswerBonus
		require(script.Parent.GoalService).track(player, "courtCorrect")
	end

	-- maybe schedule one surprise event for this case
	local cc = Config.Courtroom
	if rng:NextNumber() < cc.EventChance then
		local myDesk = desk :: CaseService.DeskState
		local myCourt = court
		task.delay(rng:NextNumber(cc.EventDelay[1], cc.EventDelay[2]), function()
			local t = workspace:GetServerTimeNow()
			if myDesk.court ~= myCourt or myDesk.phase ~= "Case" or player.Parent == nil then
				return
			end
			(myCourt :: any).event = { deadline = t + cc.EventWindow + EVENT_GRACE, done = false }
			CaseService.extendCase(myDesk, t + cc.EventWindow + 2)
			CourtEvent:FireClient(player, { desk = myDesk.index, text = EVENTS[rng:NextInteger(1, #EVENTS)], window = cc.EventWindow })
		end)
	end
	return { correct = correct, correctIndex = court.correct, late = not onTime }
end

local function react(player: Player, deskIndex: unknown): any
	if not isWholeNumber(deskIndex) then
		return nil
	end
	local desk = CaseService.getDesk(player, deskIndex :: number)
	local court = desk and desk.court
	local event = court and (court :: any).event
	if not court or not event or event.done then
		return { ok = false }
	end
	event.done = true
	if workspace:GetServerTimeNow() > event.deadline then
		return { ok = false, late = true }
	end
	court.bonus += Config.Courtroom.EventBonus -- still capped by Config.Caps in combineBuffs
	require(script.Parent.GoalService).track(player, "objection")
	return { ok = true, bonus = Config.Courtroom.EventBonus }
end

function CourtService.start()
	AttendCourt.OnServerInvoke = attend
	AnswerEvidence.OnServerInvoke = answer
	ReactCourtEvent.OnServerInvoke = react
	Players.PlayerRemoving:Connect(function(player)
		lastPrompt[player] = nil
	end)
end

return CourtService
