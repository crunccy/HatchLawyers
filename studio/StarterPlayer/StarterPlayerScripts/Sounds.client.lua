--!strict
-- Sound effects, driven only by events other scripts already send (no other script plays these).
-- Sources: Roblox built-in ping (coins, level-ups), Pro Sound Effects gavel, APM Music stings, all
-- licensed for Roblox use. Background cases only get a quiet coin ping so 5 lawyers don't spam
-- stings; the big sounds are for court verdicts and special moments. Volume: the SFX SoundGroup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local group = SoundService:FindFirstChild("SFX") :: SoundGroup?
if not group then
	local g = Instance.new("SoundGroup")
	g.Name = "SFX"
	g.Volume = 0.6
	g.Parent = SoundService
	group = g
end

local SOUNDS = {
	coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, speed = 1.25 },
	levelUp = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, speed = 1.7 },
	gavel = { id = "rbxassetid://9125574353", volume = 0.8, speed = 1 },
	win = { id = "rbxassetid://1844278029", volume = 0.5, speed = 1, cut = 2.4 }, -- 5.4s long: fade early
	big = { id = "rbxassetid://9045751375", volume = 0.55, speed = 1 },
}

local sounds: { [string]: Sound } = {}
for name, info in SOUNDS do
	local s = Instance.new("Sound")
	s.Name = "Sfx_" .. name
	s.SoundId = info.id
	s.Volume = info.volume
	s.PlaybackSpeed = info.speed
	s.SoundGroup = group
	s.Parent = SoundService
	sounds[name] = s
end

local lastPlayed: { [string]: number } = {}
local function play(name: string, minGap: number?)
	local s = sounds[name]
	local now = os.clock()
	if not s or now - (lastPlayed[name] or 0) < (minGap or 0.15) then
		return
	end
	lastPlayed[name] = now
	s.TimePosition = 0
	s.Volume = SOUNDS[name].volume
	s:Play()
	local cut = (SOUNDS[name] :: any).cut
	if cut then
		task.delay(cut, function()
			if lastPlayed[name] == now then
				TweenService:Create(s, TweenInfo.new(0.4), { Volume = 0 }):Play()
			end
		end)
	end
end

local function courtOpen(): boolean
	local court = player.PlayerGui:FindFirstChild("Courtroom") :: ScreenGui?
	return court ~= nil and court.Enabled
end

-- case results
local CaseResult = Remotes:WaitForChild("CaseResult") :: RemoteEvent
CaseResult.OnClientEvent:Connect(function(result: { [string]: any })
	local client = Config.Clients[result.clientTier or 1]
	local special = client and client.Multiplier >= 20 -- Epic and Legendary
	if courtOpen() and result.desk == player:GetAttribute("SelectedDesk") then
		play("gavel")
		if result.outcome == "Win" then
			task.delay(0.5, play, if special then "big" else "win")
		end
	elseif result.outcome == "Win" and special then
		play("big", 2)
	elseif (result.payout or 0) > 0 then
		play("coin", 0.4)
	end
end)

-- courtroom surprise events
local CourtEvent = Remotes:WaitForChild("CourtEvent") :: RemoteEvent
CourtEvent.OnClientEvent:Connect(function()
	play("gavel")
end)

-- rewards, goals, prestige
local RewardGranted = Remotes:WaitForChild("RewardGranted") :: RemoteEvent
RewardGranted.OnClientEvent:Connect(function(info: { [string]: any })
	play(if info.kind == "Prestige" then "big" else "win", 1)
end)

-- egg hatches: the Eggs script cues us (HatchCue) - a rising ping on every crack round of the 3D egg, and the
-- sting the moment it shatters (the animation's length varies with rarity and the player can skip it)
local hatchPing = sounds.levelUp:Clone()
hatchPing.Name = "Sfx_hatchPing"
hatchPing.Parent = SoundService
task.spawn(function()
	local cue = ReplicatedStorage:WaitForChild("HatchCue") :: BindableEvent
	cue.Event:Connect(function(kind: string, value: number)
		if kind == "beat" then
			hatchPing.PlaybackSpeed = 1.1 + value * 0.22
			hatchPing.Volume = 0.35 + value * 0.08
			hatchPing.TimePosition = 0
			hatchPing:Play()
		elseif kind == "burst" then
			play(if value >= 3 then "big" else "win")
		end
	end)
end)

-- training, desk upgrades, more lawyers (watched through the attributes PlayerData mirrors)
local known: { [string]: number } = {}
player.AttributeChanged:Connect(function(name)
	local value = player:GetAttribute(name)
	if typeof(value) ~= "number" then
		return
	end
	local before = known[name]
	known[name] = value
	if before == nil or value <= before then
		return
	end
	if name:match("^Desk%d+Level$") then
		play("levelUp")
	elseif name:match("^Desk%d+Tier$") or name == "DeskCount" then
		play("big", 1)
	end
end)
for name, value in player:GetAttributes() do
	if typeof(value) == "number" then
		known[name] = value
	end
end
