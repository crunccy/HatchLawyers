--!strict
-- Shared.Sfx (2026-10-16): the game's sound catalogue. Every id is licensed for use in any Roblox experience: Roblox's
-- own UI pack (creator "Roblox"), Pro Sound Effects and APM Music (Roblox's audio partners) - never random uploads
-- (copyright), and never rbxasset://sounds/swoosh.wav (not approved for this place).
--   Sfx.play(name, opts?)          a 2D one-shot through the SFX SoundGroup
--   Sfx.at(name, where, opts?)     a 3D one-shot at a part or a position (heard near it)
--   Sfx.loop(name, parent, opts?)  a looping 3D sound on a part (ambience); returns the Sound
-- opts: volume / speed multipliers, gap = the least time between two plays of that name (default 0.06 s).
-- Overlapping plays are fine (each one is its own Sound, cleaned up when it ends).

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Sfx = {}

type Def = { id: number, volume: number, speed: number, cut: number? }
Sfx.LIST = {
	-- UI (Roblox UI pack)
	click = { id = 15675032796, volume = 0.45, speed = 1 },
	clickBright = { id = 15675059323, volume = 0.45, speed = 1 },
	pop = { id = 15675055424, volume = 0.5, speed = 1 },
	open = { id = 15675046931, volume = 0.3, speed = 1.15 },
	close = { id = 15675012262, volume = 0.22, speed = 1.25 },
	whoosh = { id = 15675024286, volume = 0.5, speed = 1 },
	whooshBig = { id = 15674975792, volume = 0.6, speed = 0.9 },
	error = { id = 15675075163, volume = 0.45, speed = 1 },
	notify = { id = 15675085146, volume = 0.45, speed = 1 },
	stinger = { id = 15675043410, volume = 0.5, speed = 1 },
	goodbye = { id = 15675081158, volume = 0.5, speed = 1 },
	paper = { id = 15675037413, volume = 0.45, speed = 1 },
	-- money, eggs, props (Pro Sound Effects)
	coin = { id = 9113848518, volume = 0.3, speed = 1.15 },
	coins = { id = 9125444889, volume = 0.4, speed = 1.1, cut = 1.2 },
	cash = { id = 9113728049, volume = 0.5, speed = 1 },
	crack = { id = 9113959343, volume = 0.6, speed = 1 },
	crack2 = { id = 9113959332, volume = 0.6, speed = 1.1 },
	bonk = { id = 9114753510, volume = 0.6, speed = 1.1, cut = 0.6 },
	bubble = { id = 9112872239, volume = 0.5, speed = 1.2 },
	splash = { id = 9119293555, volume = 0.5, speed = 1, cut = 1.6 },
	gears = { id = 9116494032, volume = 0.45, speed = 1.1 },
	gavel = { id = 9125574353, volume = 0.8, speed = 1 },
	-- stings (APM Music)
	win = { id = 1844278029, volume = 0.5, speed = 1, cut = 2.4 },
	big = { id = 9045751375, volume = 0.55, speed = 1 },
	fanfare = { id = 1842130722, volume = 0.5, speed = 1, cut = 3 },
	hit = { id = 9046296613, volume = 0.5, speed = 1 },
	-- ambience loops (Pro Sound Effects)
	waves = { id = 9126201551, volume = 0.35, speed = 1 },
	gulls = { id = 9112870701, volume = 0.16, speed = 1 },
	fountain = { id = 9119293570, volume = 0.3, speed = 1 },
} :: { [string]: Def }

local function group(): SoundGroup?
	local g = SoundService:FindFirstChild("SFX")
	return if g and g:IsA("SoundGroup") then g else nil
end

local last: { [string]: number } = {}
local function make(name: string, opts: { volume: number?, speed: number?, gap: number? }?): (Sound?, Def?)
	local def = Sfx.LIST[name]
	if not def then
		return nil, nil
	end
	local now = os.clock()
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

local function start(s: Sound, def: Def)
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	local cut = def.cut
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

function Sfx.at(name: string, where: BasePart | Vector3, opts: { volume: number?, speed: number?, gap: number? }?)
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
	s.RollOffMaxDistance = 120
	s.Parent = holder
	start(s, def)
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

return Sfx
