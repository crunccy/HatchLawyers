--!strict
-- Sound effects, driven by events other scripts already send. Every sound comes from Shared.Sfx (the licensed
-- catalogue: Roblox UI pack, Pro Sound Effects, APM Music - 2026-10-16, replaced the one built-in ping).
-- Background cases only get a quiet coin toss so 5 lawyers don't spam stings; the big sounds are for court
-- verdicts and special moments. Also here: a click on every button tap. Volume: the SFX SoundGroup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

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

local Sfx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sfx")) :: any

-- per-name minimum gaps (the old pooled sounds restarted; Sfx overlaps, so busy names get a gap)
local function play(name: string, minGap: number?)
	Sfx.play(name, { gap = minGap or 0.15 })
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

-- HatchCue (a local bindable): the Eggs script - "beat" on every crack round of the 3D egg (value = round), "burst"
-- the moment it shatters (value = rarity, third arg = rarity name); TravelFx - "charge" pings while the portal charges,
-- "whoosh" as you vanish, "burst" on landing; UpgradeFx - "burst".
local MYTHIC = { Mythic = true, Supreme = true }
task.spawn(function()
	local cue = ReplicatedStorage:WaitForChild("HatchCue") :: BindableEvent
	cue.Event:Connect(function(kind: string, value: number, rarityName: string?)
		if kind == "beat" then
			Sfx.play(if value % 2 == 0 then "crack" else "crack2", { speed = 0.9 + value * 0.07, volume = 0.7 + value * 0.06, gap = 0.05 })
		elseif kind == "charge" then
			Sfx.play("clickBright", { speed = 0.9 + value * 0.12, volume = 0.8 + value * 0.05, gap = 0.05 })
		elseif kind == "whoosh" then
			Sfx.play("whooshBig")
		elseif kind == "burst" then
			if rarityName then
				Sfx.play("pop", { speed = 0.8 })
			end
			if rarityName and MYTHIC[rarityName] then
				Sfx.play("fanfare")
			else
				play(if value >= 3 then "big" else "win")
			end
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
		play("stinger")
	elseif name:match("^Desk%d+Tier$") or name == "DeskCount" then
		play("big", 1)
	end
end)
for name, value in player:GetAttributes() do
	if typeof(value) == "number" then
		known[name] = value
	end
end

-- a click on every button tap (the window's backdrop and click blockers stay quiet; a button can opt out with the
-- attribute NoClick). Window open / close sounds are played by Shared.Skin.window.
local QUIET = { Dim = true, ClickBlocker = true }
local function hookButton(d: Instance)
	if d:IsA("GuiButton") and not QUIET[d.Name] then
		d.Activated:Connect(function()
			if not d:GetAttribute("NoClick") then
				Sfx.play("click", { gap = 0.05 })
			end
		end)
	end
end
local playerGui = player:WaitForChild("PlayerGui")
for _, d in playerGui:GetDescendants() do
	hookButton(d)
end
playerGui.DescendantAdded:Connect(hookButton)
