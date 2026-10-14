--!strict
-- ArcadeClient.BriefcaseStack (server: ArcadeServer.Games.BriefcaseStack) - tap to drop the sliding briefcase on the
-- tower; what hangs over falls off. The drop is drawn at once with the server's own formula (no waiting on the
-- network), then corrected to the server's answer, which also brings the next case's slide.
-- Units -> pixels: U px per unit, cases H px tall; the view scrolls up as the tower grows.

local RunService = game:GetService("RunService")

local M = {}

local U, H = 30, 30
local COLORS = {
	Color3.fromRGB(150, 90, 50), Color3.fromRGB(55, 55, 68), Color3.fromRGB(200, 64, 64), Color3.fromRGB(52, 74, 150),
	Color3.fromRGB(40, 150, 150), Color3.fromRGB(130, 72, 190),
}

local function tri(u: number): number
	local f = u - math.floor(u)
	return if f < 0.5 then -1 + 4 * f else 3 - 4 * f
end

function M.play(info: any, api: any)
	local kit = api.kit
	local Skin = kit.Skin
	local gw = kit.window(api.cfg)
	local body = gw.body

	local SW, SHt = 840, 400
	local stage = Skin.make("TextButton", {
		Name = "Stage", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(SW, SHt),
		BackgroundColor3 = Skin.White, Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 3, Parent = body,
	}, {
		Skin.corner(12), Skin.stroke(4),
		Skin.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(205, 238, 255)) }),
	})
	local world = Skin.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = stage })
	local base = SHt - 26 -- the base's top (world y)
	local cx = SW / 2
	-- the base: a chunky desk
	Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(cx, base), Size = UDim2.fromOffset(info.width * U + 60, 30),
		BackgroundColor3 = Color3.fromRGB(214, 140, 70), ZIndex = 4, Parent = world }, { Skin.corner(4), Skin.stroke(3) })
	local levelLabel = Skin.text({ Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(220, 50), Text = string.format("0 / %d", info.levels),
		FontFace = Skin.Fonts.Number, ZIndex = 20, Parent = stage }, 44, 4)
	local drop = Skin.button({ Parent = body, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(320, 80),
		Text = "DROP!", Style = "Orange", TextSize = 50, ZIndex = 5 })

	local function caseFrame(w: number, level: number): Frame
		local col = COLORS[(level - 1) % #COLORS + 1]
		local f = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(w * U, H), BackgroundColor3 = col, ZIndex = 6, Parent = world },
			{ Skin.corner(5), Skin.stroke(2) })
		Skin.make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.62), Size = UDim2.new(1, 0, 0, 5),
			BackgroundColor3 = col:Lerp(Color3.new(0, 0, 0), 0.35), BorderSizePixel = 0, ZIndex = 7, Parent = f })
		Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 3), Size = UDim2.fromOffset(math.min(26, w * U * 0.4), 6),
			BackgroundColor3 = col:Lerp(Color3.new(0, 0, 0), 0.45), ZIndex = 7, Parent = f }, { Skin.corner(3) })
		for _, side in { 0.12, 0.88 } do
			Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(side, 0.32), Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = kit.GOLD, ZIndex = 8, Parent = f }, { Skin.stroke(1) })
		end
		return f
	end
	local function place(f: Frame, l: number, r: number, level: number)
		f.Size = UDim2.fromOffset((r - l) * U, H)
		f.Position = UDim2.fromOffset(cx + (l + r) / 2 * U, base - (level - 1) * H)
	end

	-- state (mirrors the server's)
	local L, R = -info.width / 2, info.width / 2
	local level, slideAt, period, phase = 1, info.slideAt, info.period, info.phase
	local waiting = false -- (a drop is out; the next case slides when the answer comes)
	local over = false
	local placed: { [number]: Frame } = {}
	local mover = caseFrame(R - L, 1)
	local scrollY = 0

	local function falling(l: number, r: number, lvl: number, dir: number)
		if r - l <= 0.02 then
			return
		end
		local f = caseFrame(r - l, lvl)
		place(f, l, r, lvl)
		f.ZIndex = 5
		kit.tween(f, 0.9, { Position = f.Position + UDim2.fromOffset(dir * 90, SHt), Rotation = dir * 80 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(1, function()
			f:Destroy()
		end)
	end

	-- the drop, at time t (predicted here; the server's answer corrects it)
	local function predict(t: number): (number, number, number, boolean, boolean)
		local w = R - L
		local x = info.travel * tri((math.max(t, slideAt) - slideAt) / period + phase)
		local centre = (L + R) / 2
		local perfect = math.abs(x - centre) <= info.perfectTol
		local l, r = L, R
		if perfect then
			x = centre
		else
			l, r = math.max(L, x - w / 2), math.min(R, x + w / 2)
		end
		return x, l, r, perfect, r - l < info.minWidth
	end
	local function showDrop(x: number, l: number, r: number, perfect: boolean, fell: boolean, lvl: number)
		local w = R - L
		mover.Visible = false
		if fell then
			falling(x - w / 2, x + w / 2, lvl, if x >= (L + R) / 2 then 1 else -1)
			kit.pop(body, "OOPS!", kit.RED, UDim2.new(0.5, 0, 0, 120), 64)
			kit.sound("bad")
			return
		end
		local f = caseFrame(r - l, lvl)
		place(f, l, r, lvl)
		Skin.pop(f, 1.12)
		placed[lvl] = f
		-- the overhang falls off
		if not perfect then
			if x - w / 2 < L - 0.001 then
				falling(x - w / 2, L, lvl, -1)
			elseif x + w / 2 > R + 0.001 then
				falling(R, x + w / 2, lvl, 1)
			end
			kit.sound("thud")
		else
			kit.pop(body, "PERFECT!", kit.GOLD, UDim2.new(0.5, 0, 0, 110), 58)
			kit.sound("perfect")
		end
		levelLabel.Text = string.format("%d / %d", lvl, info.levels)
	end

	local pending: { lvl: number, x: number, l: number, r: number, fell: boolean }? = nil
	local function tapDrop()
		if over or waiting or gw.quit then
			return
		end
		local t = kit.now()
		if t < slideAt then
			return
		end
		waiting = true
		local x, l, r, perfect, fell = predict(t)
		pending = { lvl = level, x = x, l = l, r = r, fell = fell }
		showDrop(x, l, r, perfect, fell, level)
		if not fell then
			L, R = l, r
		end
		api.send("Drop", { t = t })
	end
	drop.button.Activated:Connect(tapDrop)
	stage.Activated:Connect(tapDrop)

	api.onAck(function(a: any)
		local p = pending
		pending = nil
		if a.auto or not p or p.lvl ~= a.level then
			-- (the server dropped it by itself, or it saw a different case: draw its answer)
			showDrop(a.x, a.left or a.x, a.right or a.x, a.perfect == true, a.fell == true, a.level)
		elseif p.fell ~= (a.fell == true) then
			-- (the prediction and the server disagree about falling - rare, a timing edge: the server wins)
			if a.fell then
				local f = placed[a.level]
				if f then
					placed[a.level] = nil
					f:Destroy()
				end
				falling(p.l, p.r, a.level, 1)
				kit.pop(body, "OOPS!", kit.RED, UDim2.new(0.5, 0, 0, 120), 64)
				kit.sound("bad")
			else
				showDrop(a.x, a.left, a.right, a.perfect == true, false, a.level)
			end
		elseif not a.fell and (math.abs((a.left or 0) - p.l) > 0.05 or math.abs((a.right or 0) - p.r) > 0.05) then
			local f = placed[a.level]
			if f then
				place(f, a.left, a.right, a.level)
			end
		end
		if a.fell then
			over = true
			return
		end
		L, R = a.left, a.right
		if a.top then
			over = true
			kit.pop(body, "FULL TOWER!", kit.GOLD, UDim2.new(0.5, 0, 0, 140), 70)
			kit.sound("big")
			return
		end
		local nx = a.next
		level, slideAt, period, phase = nx.level, nx.slideAt, nx.period, nx.phase
		mover:Destroy()
		mover = caseFrame(R - L, level)
		mover.Visible = false
		waiting = false
	end)

	kit.countdown(body, info.startAt)
	local conn = RunService.RenderStepped:Connect(function(dt)
		local t = kit.now()
		if not over and not waiting and t >= slideAt then
			local x = info.travel * tri((t - slideAt) / period + phase)
			local w = R - L
			mover.Visible = true
			place(mover, x - w / 2, x + w / 2, level)
		end
		-- scroll so the top of the tower stays in view
		local want = math.max(0, (level - 1) * H - (SHt * 0.55))
		scrollY += (want - scrollY) * math.min(1, dt * 6)
		world.Position = UDim2.fromOffset(0, scrollY)
	end)
	local res = api.result()
	conn:Disconnect()
	kit.result(gw, res)
end

return M
