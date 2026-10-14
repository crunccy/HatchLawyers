--!strict
-- ArcadeClient.LieDetector (server: ArcadeServer.Games.LieDetector) - a polygraph: the needle swings across the meter;
-- press STOP while it's in the green TRUTH band. Draws the same needle formula as the server, from the round plan.
-- Built from frames: the meter (red LIE ends, green band, white needle), a paper trace strip that scrolls under it, a
-- row of round lights, a round timer, the STOP button.

local RunService = game:GetService("RunService")

local M = {}

function M.play(info: any, api: any)
	local kit = api.kit
	local Skin = kit.Skin
	local gw = kit.window(api.cfg)
	local body = gw.body
	local rounds = info.rounds
	local n = #rounds
	local slotLen = info.roundTime + info.gap

	-- the round lights
	local lights: { Frame } = {}
	local row = Skin.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(n * 52, 40),
		BackgroundTransparency = 1, ZIndex = 3, Parent = body,
	}, { Skin.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
	for r = 1, n do
		lights[r] = Skin.make("Frame", { Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Color3.fromRGB(70, 72, 92), ZIndex = 3, LayoutOrder = r, Parent = row },
			{ Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(3) })
	end
	local hint = Skin.text({
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(700, 34),
		Text = "Stop the needle on the green!", FontFace = Skin.Fonts.Body, TextColor3 = Skin.TextSoft, ZIndex = 3, Parent = body,
	}, 28, 2)

	-- the meter
	local MW, MH = 780, 84
	local meter = Skin.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 116), Size = UDim2.fromOffset(MW, MH),
		BackgroundColor3 = Color3.fromRGB(205, 60, 60), ClipsDescendants = true, ZIndex = 3, Parent = body,
	}, { Skin.corner(16), Skin.stroke(5) })
	Skin.studs(meter, 0.85, nil, 24)
	Skin.text({ Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(110, MH), Text = "LIE", TextColor3 = Color3.fromRGB(255, 220, 220),
		TextXAlignment = Enum.TextXAlignment.Left, FontFace = Skin.Fonts.Number, ZIndex = 4, Parent = meter }, 40, 3)
	Skin.text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(110, MH), Text = "LIE",
		TextColor3 = Color3.fromRGB(255, 220, 220), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Skin.Fonts.Number, ZIndex = 4, Parent = meter }, 40, 3)
	local band = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 215, 90), ZIndex = 5, Parent = meter }, {
		Skin.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 245, 130), Color3.fromRGB(60, 180, 60)) }),
	})
	local perfectBand = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 30, 1, 0), BackgroundColor3 = Color3.fromRGB(200, 255, 170), BackgroundTransparency = 0.25, ZIndex = 6, Parent = band })
	perfectBand.Position = UDim2.fromScale(0.5, 0)
	Skin.text({ Size = UDim2.fromScale(1, 1), Text = "TRUTH", FontFace = Skin.Fonts.Number, ZIndex = 7, Parent = band }, 30, 3)
	local needle = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, MH + 30),
		BackgroundColor3 = Skin.White, ZIndex = 9, Parent = body }, { Skin.corner(6), Skin.stroke(3) })
	local tip = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(26, 26), Rotation = 45,
		BackgroundColor3 = kit.GOLD, ZIndex = 10, Parent = needle }, { Skin.stroke(3) })
	local _ = tip

	-- the paper trace: dots of where the needle was, scrolling left
	local TW, TH = 780, 120
	local paper = Skin.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 220), Size = UDim2.fromOffset(TW, TH),
		BackgroundColor3 = Color3.fromRGB(250, 246, 232), ClipsDescendants = true, ZIndex = 3, Parent = body,
	}, { Skin.corner(10), Skin.stroke(4) })
	for k = 1, 5 do
		Skin.make("Frame", { Position = UDim2.new(0, 0, k / 6, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(220, 200, 200), BorderSizePixel = 0, ZIndex = 3, Parent = paper })
	end
	local DOTS = 70
	local dots: { Frame } = {}
	for k = 1, DOTS do
		dots[k] = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(40, 40, 60), BorderSizePixel = 0, ZIndex = 4, Parent = paper },
			{ Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local trace: { number } = {}

	-- the round timer + STOP
	local timer = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 352), Size = UDim2.fromOffset(500, 14),
		BackgroundColor3 = Color3.fromRGB(30, 30, 44), ZIndex = 3, Parent = body }, { Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(2) })
	local timerFill = Skin.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = kit.GOLD, BorderSizePixel = 0, ZIndex = 4, Parent = timer },
		{ Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local stop = Skin.button({ Parent = body, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(340, 100),
		Text = "STOP!", Style = "Green", TextSize = 60, ZIndex = 5 })

	local function needleAt(r: number, t: number): number
		local rd = rounds[r]
		local t0 = info.startAt + (r - 1) * slotLen
		return math.sin(2 * math.pi * ((t - t0) / rd.period + rd.phase))
	end
	local tapped: { [number]: number } = {} -- round -> when you pressed STOP
	local missed: { [number]: boolean } = {}
	local answered: { [number]: boolean } = {}
	local shownRound = 0
	local lastStyle = ""

	api.onAck(function(a: any)
		answered[a.round] = true
		local light = lights[a.round]
		if light then
			light.BackgroundColor3 = if a.perfect then kit.GOLD elseif a.hit then kit.GREEN else kit.RED
			Skin.pop(light, 1.6)
		end
		local at = UDim2.new(0.5, 0, 0, 120)
		if a.perfect then
			kit.pop(body, "PERFECT!", kit.GOLD, at, 64)
			kit.sound("perfect")
		elseif a.hit then
			kit.pop(body, "TRUTH!", Color3.fromRGB(150, 245, 130), at, 58)
			kit.sound("good")
		else
			kit.pop(body, "LIE!", kit.RED, at, 58)
			kit.sound("bad")
		end
	end)
	stop.button.Activated:Connect(function()
		local t = kit.now()
		local since = t - info.startAt
		local r = math.floor(since / slotLen) + 1
		if r < 1 or r > n or tapped[r] or since - (r - 1) * slotLen > info.roundTime then
			return
		end
		tapped[r] = t
		kit.sound("tap")
		api.send("Tap", { t = t })
	end)

	kit.countdown(body, info.startAt)
	local conn = RunService.RenderStepped:Connect(function()
		local t = kit.now()
		local since = t - info.startAt
		local r = math.clamp(math.floor(since / slotLen) + 1, 1, n)
		local inRound = since - (r - 1) * slotLen
		local rd = rounds[r]
		if r ~= shownRound then
			shownRound = r
			hint.Text = string.format("Round %d of %d", r, n)
			Skin.pop(meter, 0.94)
		end
		-- the band for this round (the meter runs -1 .. 1 across its width)
		band.Position = UDim2.new((rd.centre + 1) / 2, 0, 0, 0)
		band.Size = UDim2.new(0, rd.band * MW, 1, 0)
		perfectBand.Size = UDim2.new(info.perfect, 0, 1, 0)
		-- the needle: frozen where you stopped it, or swinging, or still at the round's end in the gap
		local tt = tapped[r] or math.min(t, info.startAt + (r - 1) * slotLen + info.roundTime)
		local x = if since < 0 then needleAt(1, info.startAt) else needleAt(r, tt)
		needle.Position = UDim2.new(0.5, (x * 0.5) * (MW - 16), 0, 116 + MH / 2)
		timerFill.Size = UDim2.fromScale(math.clamp(1 - inRound / info.roundTime, 0, 1), 1)
		local style = if tapped[r] or missed[r] or inRound > info.roundTime or since < 0 then "Grey" else "Green"
		if style ~= lastStyle then
			lastStyle = style
			stop.setStyle(style)
		end
		-- a missed round (no tap before its time ran out)
		if since >= 0 and inRound > info.roundTime and not tapped[r] and not missed[r] then
			missed[r] = true
			lights[r].BackgroundColor3 = kit.RED
			kit.pop(body, "TOO SLOW!", kit.RED, UDim2.new(0.5, 0, 0, 120), 50)
			kit.sound("bad")
		end
		-- the trace
		table.insert(trace, x)
		if #trace > DOTS then
			table.remove(trace, 1)
		end
		for k = 1, DOTS do
			local v = trace[#trace - DOTS + k]
			local dot = dots[k]
			if v then
				dot.Visible = true
				dot.Position = UDim2.new(k / DOTS, 0, 0.5 - v * 0.4, 0)
			else
				dot.Visible = false
			end
		end
	end)
	local res = api.result()
	conn:Disconnect()
	kit.result(gw, res)
end

return M
