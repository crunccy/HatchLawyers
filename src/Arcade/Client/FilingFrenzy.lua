--!strict
-- ArcadeClient.FilingFrenzy (server: ArcadeServer.Games.FilingFrenzy) - papers ride the conveyor towards the shredder;
-- tap the bin that matches the FRONT paper (gold outline + arrow). Colours with a shape each, so it works without
-- reading and for colour-blind players: red circle, green square, blue diamond, yellow star. A paper flies into its
-- bin at once (predicted); the server's answer corrects the count. Shredded papers come from the server.

local RunService = game:GetService("RunService")

local M = {}

local BINS = {
	{ style = "Red", color = Color3.fromRGB(229, 57, 53), glyph = "●" },
	{ style = "Green", color = Color3.fromRGB(79, 203, 46), glyph = "■" },
	{ style = "Sky", color = Color3.fromRGB(60, 150, 240), glyph = "◆" },
	{ style = "Gold", color = Color3.fromRGB(255, 190, 31), glyph = "★" },
}

function M.play(info: any, api: any)
	local kit = api.kit
	local Skin = kit.Skin
	local gw = kit.window(api.cfg)
	local body = gw.body
	local papers = info.papers
	local nBins = math.clamp(info.colors, 2, #BINS)

	-- counters
	local filedLabel = Skin.text({ Position = UDim2.fromOffset(24, 10), Size = UDim2.fromOffset(300, 44), Text = "FILED 0",
		TextXAlignment = Enum.TextXAlignment.Left, FontFace = Skin.Fonts.Number, ZIndex = 5, Parent = body }, 40, 4)
	local xs: { TextLabel } = {}
	for k = 1, info.misses do
		xs[k] = Skin.text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24 - (info.misses - k) * 52, 0, 6), Size = UDim2.fromOffset(48, 48),
			Text = "X", TextColor3 = Color3.fromRGB(80, 82, 100), FontFace = Skin.Fonts.Number, ZIndex = 5, Parent = body }, 46, 4)
	end

	-- the belt + shredder
	local BX0, BX1, BY = 30, 780, 120
	local belt = Skin.make("Frame", { Position = UDim2.fromOffset(BX0, BY + 70), Size = UDim2.fromOffset(BX1 - BX0, 46), BackgroundColor3 = Color3.fromRGB(60, 62, 78),
		ClipsDescendants = true, ZIndex = 3, Parent = body }, { Skin.corner(10), Skin.stroke(4) })
	local stripes: { Frame } = {}
	for k = 0, 16 do
		stripes[k + 1] = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, k * 48, 0.5, 0), Size = UDim2.fromOffset(10, 60), Rotation = 20,
			BackgroundColor3 = Color3.fromRGB(90, 92, 110), BorderSizePixel = 0, ZIndex = 3, Parent = belt })
	end
	local shredder = Skin.make("Frame", { Position = UDim2.fromOffset(BX1 - 4, BY + 10), Size = UDim2.fromOffset(110, 130), BackgroundColor3 = Color3.fromRGB(200, 60, 60),
		ZIndex = 8, Parent = body }, { Skin.corner(10), Skin.stroke(4) })
	Skin.studs(shredder, 0.8, nil, 20)
	Skin.make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -2, 0.62, 0), Size = UDim2.fromOffset(36, 50), BackgroundColor3 = Color3.fromRGB(30, 30, 40), ZIndex = 9, Parent = shredder },
		{ Skin.corner(6) })
	Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(1, -10, 0, 30), Text = "SHRED", FontFace = Skin.Fonts.Number, ZIndex = 9, Parent = shredder }, 26, 3)

	-- the bins
	local binButtons: { any } = {}
	local binW = math.min(210, (860 - (nBins - 1) * 16) / nBins)
	for k = 1, nBins do
		local b = BINS[k]
		local x = 460 + (k - (nBins + 1) / 2) * (binW + 16)
		binButtons[k] = Skin.button({ Parent = body, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, x, 1, -14), Size = UDim2.fromOffset(binW, 120),
			Text = b.glyph, Style = b.style, TextSize = 72, ZIndex = 6, Font = Skin.Fonts.Number })
	end

	-- the papers
	local frames: { [number]: Frame } = {}
	local state: { [number]: string } = {} -- "ok" / "wrong" / "shred" once it's off the belt
	local front = 1
	local filed, misses = 0, 0
	local arrow = Skin.text({ AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(60, 50), Text = "▼", TextColor3 = kit.GOLD, FontFace = Skin.Fonts.Number,
		ZIndex = 12, Visible = false, Parent = body }, 48, 4)
	local function paperFrame(i: number): Frame
		local p = papers[i]
		local b = BINS[p.color] or BINS[1]
		local f = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(78, 96), BackgroundColor3 = Color3.fromRGB(250, 250, 246), ZIndex = 6, Parent = body },
			{ Skin.corner(6), Skin.stroke(3) })
		Skin.make("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = b.color, BorderSizePixel = 0, ZIndex = 7, Parent = f }, { Skin.corner(6) })
		Skin.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(60, 60), Text = b.glyph, TextColor3 = b.color,
			FontFace = Skin.Fonts.Number, ZIndex = 8, Parent = f }, 56, 3)
		Skin.make("Frame", { Position = UDim2.fromScale(0.15, 0.86), Size = UDim2.new(0.7, 0, 0, 3), BackgroundColor3 = Color3.fromRGB(190, 190, 200),
			BorderSizePixel = 0, ZIndex = 7, Parent = f })
		return f
	end
	local function xAt(i: number, t: number): number
		local p = papers[i]
		local u = (t - (info.startAt + p.at)) / p.travel
		return BX0 + 40 + (BX1 - BX0 - 40) * math.clamp(u, 0, 1.05)
	end
	local function setMisses(m: number)
		misses = m
		for k, x in xs do
			x.TextColor3 = if k <= m then kit.RED else Color3.fromRGB(80, 82, 100)
		end
	end
	local function leave(i: number, how: string, bin: number?)
		state[i] = how
		local f = frames[i]
		if not f then
			return
		end
		frames[i] = nil
		if how == "shred" then
			kit.tween(f, 0.25, { Position = UDim2.fromOffset(BX1 + 30, BY + 116), Size = UDim2.fromOffset(20, 96) })
			kit.sound("bad")
		else
			local target = (binButtons[bin or 1] :: any).button.Position
			kit.tween(f, 0.28, { Position = target - UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(30, 36), Rotation = if how == "ok" then 0 else 40 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.delay(0.32, function()
			f:Destroy()
		end)
	end

	local function sort(bin: number)
		if gw.quit then
			return
		end
		local t = kit.now()
		local p = papers[front]
		if not p or t < info.startAt + p.at - 0.05 or state[front] then
			return
		end
		local i = front
		local ok = bin == p.color
		front += 1
		leave(i, if ok then "ok" else "wrong", bin)
		local at = UDim2.new(0, xAt(i, t), 0, BY - 6)
		if ok then
			filed += 1
			filedLabel.Text = "FILED " .. filed
			kit.pop(body, "FILED!", Color3.fromRGB(150, 245, 130), at, 40, 40)
			kit.sound("good")
		else
			setMisses(misses + 1)
			kit.pop(body, "WRONG!", kit.RED, at, 40, 40)
			kit.sound("bad")
		end
		api.send("Sort", { i = i, bin = bin, t = t })
	end
	for k, b in binButtons do
		b.button.Activated:Connect(function()
			sort(k)
		end)
	end

	api.onAck(function(a: any)
		if a.shred then
			for j = front, a.shred do
				if not state[j] then
					leave(j, "shred")
				end
			end
			front = math.max(front, a.shred + 1)
		end
		if a.misses then
			setMisses(a.misses)
		end
	end)

	kit.countdown(body, info.startAt)
	local conn = RunService.RenderStepped:Connect(function()
		local t = kit.now()
		for k, s in stripes do
			s.Position = UDim2.new(0, ((k - 1) * 48 + (t * 90) % 48), 0.5, 0)
		end
		local shownArrow = false
		for i, p in papers do
			if state[i] then
				continue
			end
			local appear = info.startAt + p.at
			if t < appear - 0.05 then
				break
			end
			local f = frames[i]
			if not f then
				f = paperFrame(i)
				frames[i] = f
			end
			local x = xAt(i, t)
			f.Position = UDim2.fromOffset(x, BY + 76)
			local isFront = i == front
			local st = f:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = if isFront then kit.GOLD else Color3.fromRGB(21, 19, 28)
				st.Thickness = if isFront then 5 else 3
			end
			if isFront then
				shownArrow = true
				arrow.Position = UDim2.fromOffset(x, BY - 26 + math.sin(t * 8) * 4)
			end
		end
		arrow.Visible = shownArrow
	end)
	local res = api.result()
	conn:Disconnect()
	kit.result(gw, res)
end

return M
