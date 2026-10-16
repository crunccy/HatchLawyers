--!strict
-- LIE DETECTOR (ArcadeServer.Games.LieDetector; client: ReplicatedStorage.ArcadeClient.LieDetector). A polygraph needle
-- swings across a meter; tap while it's inside the green TRUTH band. Rounds - Config.Arcade.LieDetector.Rounds of
-- them, each a fixed slot of RoundTime + Gap seconds - get faster and the band narrower. The server plans every round
-- (swing period, band centre + width, start phase) and judges each tap at its time with the same formula the client
-- draws: needle(t) = sin(2 pi ((t - roundStart) / period + phase)).
-- Score: a hit = 2 points, a PERFECT hit (inside cfg.Perfect of the band) = 3; out of 3 per round.

local M = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end
local function slot(cfg: any): number
	return cfg.RoundTime + cfg.Gap
end
local function r3(x: number): number
	return math.floor(x * 1000 + 0.5) / 1000
end

function M.timeout(_s: any, cfg: any): number
	return cfg.Rounds * slot(cfg) + 0.6
end

function M.start(s: any, cfg: any, rng: Random): { [string]: any }
	local rounds = {}
	for r = 1, cfg.Rounds do
		local u = (r - 1) / math.max(1, cfg.Rounds - 1)
		rounds[r] = {
			period = r3(lerp(cfg.Period[1], cfg.Period[2], u)),
			band = r3(lerp(cfg.Band[1], cfg.Band[2], u)),
			centre = r3(rng:NextNumber(-0.55, 0.55)),
			phase = r3(rng:NextNumber()),
		}
	end
	s.state = { rounds = rounds, tapped = {}, hits = 0, perfect = 0 }
	return { rounds = rounds, roundTime = cfg.RoundTime, gap = cfg.Gap, perfect = cfg.Perfect }
end

-- the needle (-1 .. 1) in round r at server time t
local function needle(s: any, cfg: any, r: number, t: number): number
	local rd = s.state.rounds[r]
	local t0 = s.startAt + (r - 1) * slot(cfg)
	return math.sin(2 * math.pi * ((t - t0) / rd.period + rd.phase))
end

function M.input(s: any, cfg: any, kind: string, _data: any, t: number): ({ [string]: any }?, boolean?)
	if kind ~= "Tap" then
		return nil
	end
	local st = s.state
	local since = t - s.startAt
	local r = math.floor(since / slot(cfg)) + 1
	if r < 1 or r > cfg.Rounds or st.tapped[r] then
		return nil
	end
	if since - (r - 1) * slot(cfg) > cfg.RoundTime + 0.05 then
		return nil -- (in the gap between rounds)
	end
	st.tapped[r] = true
	local rd = st.rounds[r]
	local x = needle(s, cfg, r, t)
	local d = math.abs(x - rd.centre)
	local hit = d <= rd.band
	local perfect = hit and d <= rd.band * cfg.Perfect
	if hit then
		st.hits += 1
	end
	if perfect then
		st.perfect += 1
	end
	return { round = r, hit = hit, perfect = perfect, x = r3(x) }, r == cfg.Rounds
end

function M.finish(s: any, cfg: any): (number, { [string]: any })
	local st = s.state
	local points = st.hits * 2 + st.perfect
	return points / (cfg.Rounds * 3), {
		hits = st.hits,
		perfect = st.perfect,
		rounds = cfg.Rounds,
		text = string.format("%d of %d truths found", st.hits, cfg.Rounds),
	}
end

return M
