--!strict
-- Personal, non-spatial music for the six egg islands. Two channels crossfade as the player travels.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
local TRACKS: { [string]: string } = {
	BriefcaseBay = "rbxassetid://1836269931", -- Business As Usual, buoyant office
	PetPark = "rbxassetid://1839886691", -- Happy Larry, friendly and bouncy
	BrainrotBoulevard = "rbxassetid://1847418818", -- Crazy Toons C, cartoon chaos
	FoodCourt = "rbxassetid://9046742475", -- Baking Cookies, playful kitchen
	OceanShore = "rbxassetid://1837779005", -- Beach Party, sunny coastal groove
	SpaceBase = "rbxassetid://9045219902", -- Absolute Cosmos, synth space theme
}
local LEVEL: { [string]: number } = {
	BriefcaseBay = 0.34, PetPark = 0.32, BrainrotBoulevard = 0.28,
	FoodCourt = 0.32, OceanShore = 0.30, SpaceBase = 0.32,
}
local FADE = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local group = SoundService:FindFirstChild("Music") :: SoundGroup?
if not group then
	local g = Instance.new("SoundGroup")
	g.Name = "Music"
	g.Volume = 0.45
	g.Parent = SoundService
	group = g
end

local channels = {}
for i = 1, 2 do
	local s = Instance.new("Sound")
	s.Name = "ZoneMusic" .. i
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = group
	s.Parent = SoundService
	channels[i] = s
end

local active = 1
local current: string? = nil
local generation = 0
local fadeIn: Tween? = nil
local fadeOut: Tween? = nil

local function switch(id: string?)
	if id == current then return end
	current = id
	generation += 1
	local this = generation
	if fadeIn then fadeIn:Cancel() end
	if fadeOut then fadeOut:Cancel() end
	local old = channels[active]
	active = 3 - active
	local nextSound = channels[active]
	nextSound:Stop()
	if id then
		nextSound.SoundId = TRACKS[id]
		nextSound.Volume = 0
		nextSound:Play()
		fadeIn = TweenService:Create(nextSound, FADE, { Volume = LEVEL[id] })
		fadeIn:Play()
	end
	fadeOut = TweenService:Create(old, FADE, { Volume = 0 })
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		if generation == this then old:Stop() end
	end)
end

local function inBounds(pos: Vector3, lo: Vector3, hi: Vector3): boolean
	return pos.X >= lo.X and pos.X <= hi.X and pos.Z >= lo.Z and pos.Z <= hi.Z
end

local function zoneAt(pos: Vector3): string?
	if Config.Zones.Islands.Enabled then
		local wiring = workspace:FindFirstChild("IslandWiring")
		if wiring then
			for _, zone in Config.Zones.List do
				local folder = wiring:FindFirstChild(zone.Id)
				local lo = folder and folder:GetAttribute("BoundsMin")
				local hi = folder and folder:GetAttribute("BoundsMax")
				if typeof(lo) == "Vector3" and typeof(hi) == "Vector3" and inBounds(pos, lo, hi) then
					return zone.Id
				end
			end
		end
	else
		for _, zone in Config.Zones.List do
			local b = zone.Bounds
			if b and pos.X >= b[1] and pos.X <= b[3] and pos.Z >= b[2] and pos.Z <= b[4] then
				return zone.Id
			end
		end
	end
	return nil
end

local outsideSince: number? = nil
while true do
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local id = root and zoneAt(root.Position) or nil
	if id then
		outsideSince = nil
		switch(id)
	elseif current then
		outsideSince = outsideSince or os.clock()
		if os.clock() - outsideSince > 1 then switch(nil) end
	end
	task.wait(0.25)
end