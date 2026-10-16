--!strict
-- BRIEFCASE STACK (ArcadeServer.Games.BriefcaseStack; client: ReplicatedStorage.ArcadeClient.BriefcaseStack). A
-- briefcase slides back and forth over the tower; tap to drop it. The part hanging over the case below falls off, so
-- the next case is that much narrower; a PERFECT drop (within cfg.Perfect of centre) loses nothing. An overlap thinner
-- than cfg.MinWidth falls off: game over. cfg.Levels cases = a full tower.
-- Units: the first case is cfg.Width wide centred on 0; the slide's centre runs -Travel .. Travel along a triangle
-- wave: x(t) = Travel * tri((t - slideAt) / period + phase). The server keeps slideAt / period / phase for the case
-- in play and sends the next one's in its answer; the client predicts the drop with the same formula and corrects to
-- the answer. No tap within cfg.MaxWait: the case drops where it is.
-- Score: cases stacked / Levels.

local M = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end
local function r3(x: number): number
	return math.floor(x * 1000 + 0.5) / 1000
end
local function tri(u: number): number
	local f = u - math.floor(u)
	return if f < 0.5 then -1 + 4 * f else 3 - 4 * f
end
local function period(cfg: any, level: number): number
	return r3(lerp(cfg.Period[1], cfg.Period[2], math.clamp((level - 1) / math.max(1, cfg.Levels - 1), 0, 1)))
end

function M.timeout(_s: any, cfg: any): number
	return cfg.Levels * (cfg.MaxWait + cfg.Settle) + 2
end

local drop: (s: any, cfg: any, t: number) -> ({ [string]: any }, boolean)

-- no tap in MaxWait: it drops by itself
local function arm(s: any, cfg: any)
	local st = s.state
	st.token += 1
	local token = st.token
	task.delay(math.max(0, st.slideAt - workspace:GetServerTimeNow()) + cfg.MaxWait, function()
		if not s.done and st.token == token then
			local reply, done = drop(s, cfg, workspace:GetServerTimeNow())
			reply.auto = true
			s.send(reply)
			if done then
				s.finish()
			end
		end
	end)
end

function M.start(s: any, cfg: any, rng: Random): { [string]: any }
	s.state = {
		level = 1, left = -cfg.Width / 2, right = cfg.Width / 2, slideAt = s.startAt, phase = r3(rng:NextNumber()),
		stacked = 0, perfect = 0, token = 0, rng = rng,
	}
	arm(s, cfg)
	return {
		width = cfg.Width, travel = cfg.Travel, levels = cfg.Levels, perfectTol = cfg.Perfect, minWidth = cfg.MinWidth,
		settle = cfg.Settle, slideAt = s.startAt, period = period(cfg, 1), phase = s.state.phase,
	}
end

drop = function(s: any, cfg: any, t: number): ({ [string]: any }, boolean)
	local st = s.state
	local w = st.right - st.left
	local x = cfg.Travel * tri((math.max(t, st.slideAt) - st.slideAt) / period(cfg, st.level) + st.phase)
	local centre = (st.left + st.right) / 2
	local perfect = math.abs(x - centre) <= cfg.Perfect
	local l, r
	if perfect then
		l, r, x = st.left, st.right, centre
	else
		l, r = math.max(st.left, x - w / 2), math.min(st.right, x + w / 2)
	end
	local level = st.level
	st.token += 1 -- (cancels the auto-drop)
	if r - l < cfg.MinWidth then
		return { level = level, x = r3(x), fell = true }, true
	end
	st.left, st.right = r3(l), r3(r)
	st.stacked += 1
	if perfect then
		st.perfect += 1
	end
	st.level += 1
	if st.level > cfg.Levels then
		return { level = level, x = r3(x), left = st.left, right = st.right, perfect = perfect, top = true }, true
	end
	st.slideAt = t + cfg.Settle
	st.phase = r3(st.rng:NextNumber())
	arm(s, cfg)
	return {
		level = level, x = r3(x), left = st.left, right = st.right, perfect = perfect,
		next = { level = st.level, slideAt = st.slideAt, period = period(cfg, st.level), phase = st.phase },
	}, false
end

function M.input(s: any, cfg: any, kind: string, _data: any, t: number): ({ [string]: any }?, boolean?)
	if kind ~= "Drop" then
		return nil
	end
	if t < s.state.slideAt - 0.05 then
		return nil -- (the last case is still settling)
	end
	return drop(s, cfg, t)
end

function M.finish(s: any, cfg: any): (number, { [string]: any })
	local st = s.state
	return st.stacked / cfg.Levels, {
		stacked = st.stacked,
		perfect = st.perfect,
		text = if st.stacked >= cfg.Levels then "A FULL TOWER!" else string.format("%d briefcases high", st.stacked),
	}
end

return M
