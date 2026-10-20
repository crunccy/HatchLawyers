--!strict
-- Shared.Sfx: centralized game audio. The main cues are the curated CC0 WAV library uploaded to this
-- experience; legacy Roblox library sounds remain for shell taps, props, and ambience.
--   Sfx.play(name, opts?)          a 2D one-shot through the SFX SoundGroup
--   Sfx.at(name, where, opts?)     a 3D one-shot at a part or a position (heard near it)
--   Sfx.loop(name, parent, opts?)  a looping 3D sound on a part (ambience); returns the Sound
-- opts: volume / speed multipliers, gap = the least time between two plays of that name (default 0.06 s).
-- Overlapping plays are fine (each one is its own Sound, cleaned up when it ends).

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Sfx = {}

type Def = { id: number, volume: number, speed: number, cut: number?, major: boolean? }
Sfx.LIST = {
	-- Curated CC0 library uploaded to this experience on 2026-10-20.
	click = { id = 102294954616042, volume = 0.55, speed = 1 },
	clickBright = { id = 123118026785931, volume = 0.38, speed = 1 },
	open = { id = 120678935291505, volume = 0.3, speed = 1 },
	close = { id = 106642611770961, volume = 0.3, speed = 1 },
	error = { id = 99407320871501, volume = 0.48, speed = 1 },
	notify = { id = 89980959833270, volume = 0.18, speed = 1 },
	stinger = { id = 72361405132252, volume = 1.2, speed = 1 },
	paper = { id = 90619584621099, volume = 0.7, speed = 1 },
	coin = { id = 90390591023027, volume = 0.65, speed = 1 },
	coins = { id = 115735231933057, volume = 0.55, speed = 1 },
	cash = { id = 135860085582072, volume = 0.32, speed = 1 },
	pop = { id = 131824203295793, volume = 0.7, speed = 1 },
	eggAppear = { id = 118588618694874, volume = 0.5, speed = 1 },
	eggShake = { id = 92741818047842, volume = 1.4, speed = 1 },
	eggBreak = { id = 131824203295793, volume = 0.7, speed = 1 },
	eggReveal = { id = 77579001934840, volume = 0.22, speed = 1 },
	eggLawyer = { id = 97556313335338, volume = 0.25, speed = 1 },
	revealCommon = { id = 113241967388335, volume = 0.65, speed = 1 },
	revealUncommon = { id = 134961296310184, volume = 0.25, speed = 1 },
	revealRare = { id = 139503286093529, volume = 0.28, speed = 1, major = true },
	revealEpic = { id = 89456559672829, volume = 1, speed = 1, major = true },
	revealLegendary = { id = 123808008046532, volume = 1, speed = 1, major = true },
	revealMythic = { id = 128049657943346, volume = 0.4, speed = 1, major = true },
	revealSupreme = { id = 78159695614988, volume = 0.4, speed = 1, major = true },
	caseBegin = { id = 81793317118620, volume = 0.55, speed = 1 },
	caseComplete = { id = 131212350471442, volume = 0.22, speed = 1 },
	lawyerEquip = { id = 75726604880465, volume = 1.1, speed = 1 },
	lawyerUnequip = { id = 97320540513943, volume = 0.5, speed = 1 },
	lawyerMerge = { id = 114809638231891, volume = 0.5, speed = 1, major = true },
	lawyerUnlock = { id = 120003832226186, volume = 0.55, speed = 1, major = true },
	officeUpgrade = { id = 81008028335263, volume = 1, speed = 1, major = true },
	areaUnlock = { id = 91778782974710, volume = 0.55, speed = 1, major = true },
	rebirth = { id = 136391427555100, volume = 1, speed = 1, major = true },
	rewardClaim = { id = 93147052015617, volume = 1.5, speed = 1, major = true },
	travel = { id = 117118307002866, volume = 0.45, speed = 1 },
	travelArrival = { id = 99390250906628, volume = 0.3, speed = 1 },
	whoosh = { id = 117118307002866, volume = 0.42, speed = 1 },
	whooshBig = { id = 117118307002866, volume = 0.5, speed = 1 },
	goodbye = { id = 97320540513943, volume = 0.5, speed = 1 },
	win = { id = 93147052015617, volume = 1.5, speed = 1, major = true },
	big = { id = 72361405132252, volume = 1.1, speed = 1, major = true },
	fanfare = { id = 128049657943346, volume = 0.26, speed = 1, major = true },
	hit = { id = 114809638231891, volume = 0.27, speed = 1, major = true },
	crack = { id = 9113959343, volume = 0.42, speed = 1 },
	crack2 = { id = 9113959332, volume = 0.42, speed = 1 },
	bonk = { id = 9114753510, volume = 0.48, speed = 1 },
	bubble = { id = 9112872239, volume = 0.4, speed = 1 },
	splash = { id = 9119293555, volume = 0.4, speed = 1 },
	gears = { id = 9116494032, volume = 0.3, speed = 1 },
	gavel = { id = 9125574353, volume = 0.5, speed = 1 },
	courtAlert = { id = 9045751375, volume = 0.12, speed = 1, cut = 1.5 },
	waves = { id = 9126201551, volume = 0.25, speed = 1 },
	gulls = { id = 9112870701, volume = 0.12, speed = 1 },
	fountain = { id = 9119293570, volume = 0.22, speed = 1 },
} :: { [string]: Def }

local function group(): SoundGroup
	local g = SoundService:FindFirstChild("SFX")
	if g and g:IsA("SoundGroup") then
		return g
	end
	local created = Instance.new("SoundGroup")
	created.Name = "SFX"
	created.Volume = 0.6
	created.Parent = SoundService
	return created
end

local last: { [string]: number } = {}
local activeCount = 0
local activeMajor = 0
local lastMajor = 0
local activeByName: { [string]: number } = {}
local MAX_ONE_SHOTS = 8
local function make(name: string, opts: { volume: number?, speed: number?, gap: number? }?): (Sound?, Def?)
	local def = Sfx.LIST[name]
	if not def or activeCount >= MAX_ONE_SHOTS or (activeByName["Sfx_" .. name] or 0) >= 2 then
		return nil, nil
	end
	local now = os.clock()
	if def.major and (activeMajor >= 1 or now - lastMajor < 0.45) then
		return nil, nil
	end
	if now - (last[name] or 0) < ((opts and opts.gap) or 0.06) then
		return nil, nil
	end
	last[name] = now
	local s = Instance.new("Sound")
	s.Name = "Sfx_" .. name
	s.SoundId = "rbxassetid://" .. def.id
	s.Volume = def.volume * ((opts and opts.volume) or 1)
	s.PlaybackSpeed = def.speed * ((opts and opts.speed) or 1)
	s.SoundGroup = group()
	return s, def
end

local function start(s: Sound, def: Def, cutOverride: number?)
	activeCount += 1
	activeByName[s.Name] = (activeByName[s.Name] or 0) + 1
	if def.major then
		activeMajor += 1
		lastMajor = os.clock()
	end
	s.Destroying:Once(function()
		activeCount = math.max(0, activeCount - 1)
		activeByName[s.Name] = math.max(0, (activeByName[s.Name] or 1) - 1)
		if def.major then
			activeMajor = math.max(0, activeMajor - 1)
		end
	end)
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	local cut = cutOverride or def.cut
	task.delay(cut or 12, function()
		if s.Parent then
			if cut then
				local t = 0
				local v0 = s.Volume
				while t < 0.3 and s.Parent do -- a short fade instead of a click
					t += task.wait()
					s.Volume = v0 * (1 - t / 0.3)
				end
			end
			s:Destroy()
		end
	end)
end

function Sfx.play(name: string, opts: { volume: number?, speed: number?, gap: number? }?)
	local s, def = make(name, opts)
	if s and def then
		s.Parent = SoundService
		start(s, def)
	end
end

function Sfx.at(name: string, where: BasePart | Vector3, opts: { volume: number?, speed: number?, gap: number?, range: number?, cut: number? }?)
	local s, def = make(name, opts)
	if not (s and def) then
		return
	end
	local holder: Instance
	if typeof(where) == "Vector3" then
		local a = Instance.new("Attachment")
		a.WorldPosition = where
		a.Parent = Workspace.Terrain
		holder = a
		task.delay(6, function()
			a:Destroy()
		end)
	else
		holder = where
	end
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = (opts and opts.range) or 120
	s.Parent = holder
	start(s, def, opts and opts.cut)
end

function Sfx.loop(name: string, parent: Instance, opts: { volume: number?, speed: number?, range: number? }?): Sound?
	local def = Sfx.LIST[name]
	if not def then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "Sfx_" .. name
	s.SoundId = "rbxassetid://" .. def.id
	s.Volume = def.volume * ((opts and opts.volume) or 1)
	s.PlaybackSpeed = def.speed * ((opts and opts.speed) or 1)
	s.Looped = true
	s.SoundGroup = group()
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 12
	s.RollOffMaxDistance = (opts and opts.range) or 150
	s.Parent = parent
	s:Play()
	return s
end

Sfx.group = group

return Sfx
