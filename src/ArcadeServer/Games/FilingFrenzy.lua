--!strict
-- FILING FRENZY (ArcadeServer.Games.FilingFrenzy; client: ReplicatedStorage.ArcadeClient.FilingFrenzy). Papers ride a
-- conveyor towards the shredder, one after another, faster and faster; tap the bin that matches the FRONT paper's
-- colour (red / green / blue, + yellow with Colors = 4). A wrong bin or a shredded paper is a miss; cfg.Misses misses
-- end the round. The server plans every paper (colour, when it enters the belt, how long it rides), checks each sort
-- against the front paper and its time, and shreds a paper that's still unsorted when it reaches the end.
-- Score: papers filed right / all papers.

local M = {}

local SLACK = 0.25 -- seconds past the end of the belt a sort still counts (network)

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end
local function r2(x: number): number
	return math.floor(x * 100 + 0.5) / 100
end

function M.timeout(s: any, _cfg: any): number
	local last = s.state.papers[#s.state.papers]
	return last.at + last.travel + 1
end

-- paper i reached the shredder: it (and anything before it still unsorted) is shredded
local function expire(s: any, cfg: any, i: number)
	local st = s.state
	if s.done or st.front > i then
		return
	end
	for j = st.front, i do
		if not st.result[j] then
			st.result[j] = "shred"
			st.misses += 1
		end
	end
	st.front = i + 1
	s.send({ shred = i, misses = st.misses })
	if st.misses >= cfg.Misses or st.front > #st.papers then
		s.finish()
	end
end

function M.start(s: any, cfg: any, rng: Random): { [string]: any }
	local papers = {}
	local t = 0.4
	for i = 1, cfg.Papers do
		local u = (i - 1) / math.max(1, cfg.Papers - 1)
		papers[i] = { color = rng:NextInteger(1, cfg.Colors), at = r2(t), travel = r2(lerp(cfg.Travel[1], cfg.Travel[2], u)) }
		t += lerp(cfg.Gap[1], cfg.Gap[2], u)
	end
	s.state = { papers = papers, front = 1, correct = 0, misses = 0, result = {} }
	local now = workspace:GetServerTimeNow()
	for i, p in papers do
		task.delay(math.max(0, s.startAt + p.at + p.travel + SLACK - now), expire, s, cfg, i)
	end
	return { papers = papers, colors = cfg.Colors, misses = cfg.Misses }
end

function M.input(s: any, cfg: any, kind: string, data: any, t: number): ({ [string]: any }?, boolean?)
	if kind ~= "Sort" then
		return nil
	end
	local st = s.state
	local i, bin = data.i, data.bin
	if type(i) ~= "number" or type(bin) ~= "number" or i ~= st.front then
		return nil
	end
	local p = st.papers[i]
	local appear = s.startAt + p.at
	if t < appear - 0.05 or t > appear + p.travel + SLACK then
		return nil
	end
	local ok = bin == p.color
	st.result[i] = if ok then "ok" else "wrong"
	if ok then
		st.correct += 1
	else
		st.misses += 1
	end
	st.front = i + 1
	return { i = i, ok = ok, misses = st.misses }, st.misses >= cfg.Misses or st.front > #st.papers
end

function M.finish(s: any, _cfg: any): (number, { [string]: any })
	local st = s.state
	return st.correct / #st.papers, {
		correct = st.correct,
		total = #st.papers,
		text = string.format("%d of %d papers filed", st.correct, #st.papers),
	}
end

return M
