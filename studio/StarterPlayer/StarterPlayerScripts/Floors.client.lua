--!strict
-- Floors (StarterPlayerScripts.Floors; 2026-10-13) - the panels of the UPSTAIRS ROOMS (server:
-- ServerScriptService.FloorRooms; tuning: Config.Floors). A room's prompt opens its panel with the server's state
-- (Remotes.FloorsEvent "Open"); its buttons call Remotes.Floors(action, ...) and redraw from the answer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local Effects = require(Shared:WaitForChild("Effects") :: ModuleScript) :: any
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Event = Remotes:WaitForChild("FloorsEvent") :: RemoteEvent
local Func = Remotes:WaitForChild("Floors") :: RemoteFunction

local CFG = Config.Floors
local GREEN = Color3.fromRGB(140, 240, 100)
local GOLD = Color3.fromRGB(255, 200, 40)
local SOFT = Skin.TextSoft

local function mmss(s: number): string
	local n = math.max(0, math.ceil(s))
	return string.format("%d:%02d", n // 60, n % 60)
end
local function rarityColor(r: number): Color3
	local tier = Config.Eggs.Skins[r]
	return (tier and Config.RarityColors[tier.Id]) or Color3.fromRGB(200, 200, 210)
end

------------------------------------------------------------------ toast
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "FloorsToast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 46
toastGui.IgnoreGuiInset = true
toastGui.Parent = player:WaitForChild("PlayerGui")
local function toast(text: string)
	local pill = Skin.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(620, 48),
		BackgroundColor3 = Skin.Panel, Parent = toastGui }, { Skin.corner(24), Skin.stroke(3) })
	Skin.text({ Position = UDim2.fromOffset(16, 4), Size = UDim2.new(1, -32, 1, -8), Text = text, Parent = pill }, 26, 3)
	Skin.pop(pill, 0.6)
	task.delay(3, function()
		pill:Destroy()
	end)
end

------------------------------------------------------------------ the window
local current: any = nil
local function openWindow(room: string): any
	if current then
		current.gui:Destroy()
		current = nil
	end
	local def = CFG.Rooms[room]
	local win = Skin.window({ Name = "FloorRoom", Title = def.Name, Color = def.Color, Size = Vector2.new(900, 560), DisplayOrder = 38 })
	current = win
	win.onClose(function()
		task.delay(0.2, function()
			if current == win then
				current = nil
			end
			win.gui:Destroy()
		end)
	end)
	win.open()
	return win
end
local function clear(body: Instance)
	for _, c in body:GetChildren() do
		if not c:IsA("UIComponent") then
			c:Destroy()
		end
	end
end
local function line(body: Instance, text: string, y: number, size: number?, color: Color3?, font: Font?): TextLabel
	return Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.new(1, -60, 0, (size or 28) + 6),
		Text = text, TextColor3 = color or Skin.White, FontFace = font or Skin.Fonts.Title, ZIndex = 3, Parent = body }, size or 28)
end
local function card(body: Instance, x: number, y: number, w: number, h: number, color: Color3): Frame
	local c = Skin.make("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = Skin.PanelDeep, ZIndex = 3, Parent = body },
		{ Skin.corner(10), Skin.stroke(3) })
	Skin.make("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 4, Parent = c }, { Skin.corner(4) })
	return c
end
local function call(...: any): (boolean, any)
	local ok, a, b = pcall(Func.InvokeServer, Func, ...)
	if not ok then
		return false, "Try again"
	end
	if not a and type(b) == "string" then
		toast(b)
	end
	return a, b
end

local draw: { [string]: (win: any, state: any) -> () } = {}

-- MAIL ROOM: three letters
draw.MailRoom = function(win: any, state: any)
	local body = win.body
	clear(body)
	line(body, "Today's letters - new ones every day", 14, 24, SOFT, Skin.Fonts.Body)
	for i, l in state.letters do
		local c = card(body, 24 + (i - 1) * 288, 56, 268, 400, Color3.fromRGB(229, 57, 53))
		Skin.text({ Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -24, 0, 30), Text = "From " .. l.from, TextColor3 = GOLD, ZIndex = 5, Parent = c }, 24)
		Skin.text({ Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 0, 110), Text = "\"" .. l.text .. "\"", TextWrapped = true, FontFace = Skin.Fonts.Body, ZIndex = 5, Parent = c }, 28, 2)
		local bar = Skin.make("Frame", { Position = UDim2.fromOffset(16, 186), Size = UDim2.new(1, -32, 0, 24), BackgroundColor3 = Color3.fromRGB(30, 30, 44), ZIndex = 5, Parent = c },
			{ Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }), Skin.stroke(2) })
		Skin.make("Frame", { Size = UDim2.fromScale(math.clamp(l.progress / l.target, 0, 1), 1), BackgroundColor3 = GREEN, BorderSizePixel = 0, ZIndex = 6, Parent = bar },
			{ Skin.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		Skin.text({ Size = UDim2.fromScale(1, 1), Text = string.format("%d / %d", l.progress, l.target), ZIndex = 7, Parent = bar }, 18, 2)
		Skin.text({ Position = UDim2.fromOffset(12, 222), Size = UDim2.new(1, -24, 0, 60), TextWrapped = true,
			Text = string.format("Reward: %s min of cases%s", tostring(l.minutes), if l.egg then " + a FREE EGG" else ""), TextColor3 = GREEN, ZIndex = 5, Parent = c }, 22)
		local done = l.progress >= l.target
		local b = Skin.button({ Parent = c, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -32, 0, 64),
			Text = if l.claimed then "CLAIMED" elseif done then "CLAIM!" else "NOT YET", Style = if done and not l.claimed then "Green" else "Grey", ZIndex = 6, TextSize = 32 })
		b.button.Activated:Connect(function()
			if done and not l.claimed then
				local ok, s = call("claimMail", i)
				if ok then
					Effects.guiBurst(c, UDim2.fromScale(0.5, 0.5), 260, GOLD, 0.9, 8)
					draw.MailRoom(win, s)
				end
			end
		end)
	end
end

-- HALL OF FAME: the sets by egg, a frame per lawyer
draw.HallOfFame = function(win: any, state: any)
	local body = win.body
	clear(body)
	local pick = 1
	local tabs = Skin.make("Frame", { Position = UDim2.fromOffset(20, 10), Size = UDim2.new(1, -40, 0, 50), BackgroundTransparency = 1, ZIndex = 3, Parent = body },
		{ Skin.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })
	local grid = Skin.make("ScrollingFrame", { Position = UDim2.fromOffset(20, 104), Size = UDim2.new(1, -40, 1, -116), BackgroundColor3 = Skin.PanelDeep, BorderSizePixel = 0,
		ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 3, Parent = body }, {
		Skin.corner(10), Skin.stroke(3),
		Skin.make("UIGridLayout", { CellSize = UDim2.fromOffset(150, 74), CellPadding = UDim2.fromOffset(10, 10) }),
		Skin.make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
	local head = line(body, "", 64, 26)
	local function show(k: number)
		pick = k
		local set = state.sets[k]
		for _, c in grid:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		head.Text = string.format("%s: %d / %d found%s", set.name, set.have, set.total, if set.have >= set.total then "  -  SET COMPLETE! +" .. math.floor(CFG.Index.SetBonus * 100) .. "% cases" else "")
		head.TextColor3 = if set.have >= set.total then GOLD else Skin.White
		for _, l in set.lawyers do
			local owned = l.stars > 0
			local tile = Skin.make("Frame", { BackgroundColor3 = if owned then rarityColor(l.rarity):Lerp(Color3.new(0, 0, 0), 0.35) else Color3.fromRGB(50, 52, 68), ZIndex = 4, Parent = grid },
				{ Skin.corner(8), Skin.stroke(if owned and l.stars >= 2 then 4 else 3, if owned and l.stars >= 2 then GOLD else nil) })
			Skin.text({ Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), Text = if owned then l.name else "?", TextWrapped = true,
				TextColor3 = if owned then Skin.White else Color3.fromRGB(120, 122, 140), ZIndex = 5, Parent = tile }, 22, 2)
		end
	end
	for k, set in state.sets do
		local b = Skin.button({ Parent = tabs, Size = UDim2.fromOffset(132, 44), Text = set.name:gsub(" Egg", ""), Style = if set.have >= set.total then "Gold" else "Purple", TextSize = 20, ZIndex = 4 })
		b.button.Activated:Connect(function()
			show(k)
		end)
	end
	show(pick)
	Skin.text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 64), Size = UDim2.fromOffset(260, 30),
		Text = string.format("Total: +%d%% cases", math.floor(state.bonus * 100 + 0.5)), TextColor3 = GREEN, ZIndex = 3, Parent = body }, 24)
end

-- VIP LOUNGE
draw.VIPLounge = function(win: any, state: any)
	local body = win.body
	clear(body)
	if not state.vip then
		line(body, "No VIP right now", 140, 44)
		line(body, "The next one arrives in " .. mmss(state.nextIn), 200, 30, SOFT)
		return
	end
	local title = line(body, state.vip.name .. " (VIP) needs a lawyer!", 14, 36, GOLD)
	Skin.pop(title, 0.5)
	local timer = line(body, "", 56, 24, SOFT, Skin.Fonts.Body)
	local leaves = os.clock() + state.vip.leavesIn
	task.spawn(function()
		while timer.Parent do
			timer.Text = "Pick who takes the case - they leave in " .. mmss(leaves - os.clock())
			task.wait(0.5)
		end
	end)
	for i, l in state.lawyers do
		local col, row = (i - 1) % 3, (i - 1) // 3
		local b = Skin.button({ Parent = body, Position = UDim2.fromOffset(40 + col * 280, 100 + row * 96), Size = UDim2.fromOffset(260, 84),
			Text = string.format("%s\nEarns x%s", l.name, tostring(l.earn)), Style = rarityColor(l.rarity), TextSize = 24, ZIndex = 4 })
		b.button.Activated:Connect(function()
			local ok, s = call("greetVip", l.uid)
			if ok then
				draw.VIPLounge(win, s)
			end
		end)
	end
end

-- MOOT COURT: two practice booths
draw.MootCourt = function(win: any, state: any)
	local body = win.body
	clear(body)
	line(body, string.format("Send an office to practise for %d minutes: it earns a FREE SKILL ROLL", state.minutes), 14, 24, SOFT, Skin.Fonts.Body)
	for b, booth in state.booths do
		local c = card(body, 40 + (b - 1) * 420, 60, 400, 400, Color3.fromRGB(150, 90, 50))
		Skin.text({ Position = UDim2.fromOffset(12, 18), Size = UDim2.new(1, -24, 0, 40), Text = "BOOTH " .. b, FontFace = Skin.Fonts.Number, ZIndex = 5, Parent = c }, 36)
		if booth.desk then
			Skin.text({ Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -24, 0, 40), Text = "Office " .. booth.desk .. " is practising", ZIndex = 5, Parent = c }, 28)
			local ends = os.clock() + booth.left
			local lbl = Skin.text({ Position = UDim2.fromOffset(12, 130), Size = UDim2.new(1, -24, 0, 70), Text = "", FontFace = Skin.Fonts.Number, TextColor3 = GOLD, ZIndex = 5, Parent = c }, 60)
			local btn = Skin.button({ Parent = c, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(1, -40, 0, 70), Text = "PRACTISING...", Style = "Grey", TextSize = 32, ZIndex = 6 })
			task.spawn(function()
				while lbl.Parent do
					local left = ends - os.clock()
					lbl.Text = if left > 0 then mmss(left) else "DONE!"
					if left <= 0 then
						btn.setStyle("Green")
						btn.setText("COLLECT!")
					end
					task.wait(0.5)
				end
			end)
			btn.button.Activated:Connect(function()
				if ends - os.clock() <= 0 then
					local ok, s = call("collect", b)
					if ok then
						draw.MootCourt(win, s)
					end
				end
			end)
		else
			Skin.text({ Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 30), Text = "Pick an office:", TextColor3 = SOFT, ZIndex = 5, Parent = c }, 24)
			local list = Skin.make("ScrollingFrame", { Position = UDim2.fromOffset(16, 106), Size = UDim2.new(1, -32, 1, -122), BackgroundTransparency = 1, BorderSizePixel = 0,
				ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 5, Parent = c },
				{ Skin.make("UIListLayout", { Padding = UDim.new(0, 6) }) })
			for _, o in state.offices do
				local ob = Skin.button({ Parent = list, Size = UDim2.new(1, -10, 0, 48), Text = string.format("Office %d - %s", o.index, o.name), Style = "Sky", TextSize = 22, ZIndex = 6 })
				ob.button.Activated:Connect(function()
					local ok, s = call("train", b, o.index)
					if ok then
						draw.MootCourt(win, s)
					end
				end)
			end
		end
	end
end

-- CASE FILES ARCHIVE: a shelf per client type
draw.CaseArchive = function(win: any, state: any)
	local body = win.body
	clear(body)
	line(body, string.format("Every case you win is filed here. Milestones: +%s%% cases each  -  total +%s%%",
		tostring(CFG.Archive.PerMilestone * 100), tostring(math.floor(state.bonus * 1000 + 0.5) / 10)), 12, 22, GREEN)
	for i, s in state.shelves do
		local col, row = (i - 1) % 3, (i - 1) // 3
		local c = card(body, 24 + col * 288, 52 + row * 140, 268, 128, rarityColor(math.min(s.tier, 7)))
		Skin.text({ Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -20, 0, 30), Text = s.name, ZIndex = 5, Parent = c }, 26)
		Skin.text({ Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 34), Text = tostring(s.wins) .. " won", FontFace = Skin.Fonts.Number, TextColor3 = GOLD, ZIndex = 5, Parent = c }, 30)
		local stars = ""
		for k = 1, #CFG.Archive.Milestones do
			stars ..= if k <= s.reached then "★" else "☆"
		end
		Skin.text({ Position = UDim2.fromOffset(10, 84), Size = UDim2.new(1, -20, 0, 32), Text = stars .. (if s.next then "  next: " .. s.next else "  ALL DONE"), ZIndex = 5, Parent = c }, 24)
	end
end

-- PARTNER'S OFFICE: rules
draw.PartnersOffice = function(win: any, state: any)
	local body = win.body
	clear(body)
	line(body, "Rules your firm follows by itself", 16, 30)
	for i, r in state.rules do
		local c = card(body, 60, 70 + (i - 1) * 140, 780, 124, Color3.fromRGB(90, 200, 255))
		Skin.text({ Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -260, 0, 40), Text = r.name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = c }, 34)
		Skin.text({ Position = UDim2.fromOffset(20, 62), Size = UDim2.new(1, -260, 0, 44), Text = r.text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, FontFace = Skin.Fonts.Body, TextColor3 = SOFT, ZIndex = 5, Parent = c }, 22, 0)
		local b = Skin.button({ Parent = c, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 4), Size = UDim2.fromOffset(200, 72),
			Text = if r.on then "ON" else "OFF", Style = if r.on then "Green" else "Grey", TextSize = 40, ZIndex = 6 })
		b.button.Activated:Connect(function()
			local ok, s = call("setRule", r.id, not r.on)
			if ok then
				draw.PartnersOffice(win, s)
			end
		end)
	end
end

-- GUEST LOUNGE
draw.GuestLounge = function(win: any, state: any)
	local body = win.body
	clear(body)
	local heart = line(body, "♥ " .. tostring(state.likes), 30, 90, Color3.fromRGB(255, 110, 150), Skin.Fonts.Number)
	Skin.pop(heart, 0.5)
	line(body, "likes from visitors", 132, 26, SOFT)
	line(body, string.format("When a friend hangs out in your lounge, you BOTH get +%d%% cases for %d minutes.",
		math.floor(CFG.Lounge.Buff * 100), CFG.Lounge.Minutes), 190, 22, GREEN, Skin.Fonts.Body)
	line(body, "Visitors can sign your guestbook once a day.", 222, 22, SOFT, Skin.Fonts.Body)
	line(body, "Recent visitors", 280, 28)
	line(body, if #state.visitors > 0 then table.concat(state.visitors, ", ") else "No one yet - invite a friend!", 320, 24, SOFT, Skin.Fonts.Body)
end

-- PRIVATE COURTROOM
draw.PrivateCourtroom = function(win: any, state: any)
	local body = win.body
	clear(body)
	if state.readyIn > 0 then
		line(body, "Court is in recess", 140, 44)
		line(body, "Back in session in " .. mmss(state.readyIn), 200, 30, SOFT)
		return
	end
	line(body, "Three cases are waiting. Pick the evidence that proves each one!", 120, 26, SOFT, Skin.Fonts.Body)
	local go = Skin.button({ Parent = body, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 200), Size = UDim2.fromOffset(360, 100),
		Text = "HOLD COURT!", Style = "Orange", TextSize = 48, ZIndex = 4 })
	go.button.Activated:Connect(function()
		local ok, trial = call("courtStart")
		if not ok then
			return
		end
		local function round(r: number)
			clear(body)
			local c = trial.rounds[r]
			line(body, string.format("CASE %d of %d", r, #trial.rounds), 16, 30, GOLD, Skin.Fonts.Number)
			line(body, c.case, 66, 40)
			for k, text in c.cards do
				local b = Skin.button({ Parent = body, Position = UDim2.fromOffset(30 + (k - 1) * 284, 170), Size = UDim2.fromOffset(264, 220),
					Text = text, Style = "Sky", TextSize = 26, ZIndex = 4 })
				b.label.TextWrapped = true
				b.button.Activated:Connect(function()
					local ok2, res = call("courtAnswer", r, k)
					if not ok2 then
						return
					end
					local verdict = line(body, if res.correct then "OBJECTION SUSTAINED!" else "Not quite - it was: " .. c.cards[res.answer], 420, 34,
						if res.correct then GREEN else Color3.fromRGB(150, 190, 255), Skin.Fonts.Number)
					Skin.pop(verdict, 0.4)
					task.wait(1.6)
					if res.done then
						clear(body)
						line(body, string.format("VERDICT: %d of %d proven!", res.score, #trial.rounds), 120, 50, GOLD, Skin.Fonts.Number)
						line(body, res.reward or "", 200, 36, GREEN)
						Effects.guiBurst(body, UDim2.fromScale(0.5, 0.35), 380, GOLD, 1.2, 9)
					elseif body.Parent then
						round(r + 1)
					end
				end)
			end
		end
		round(1)
	end)
end

Event.OnClientEvent:Connect(function(kind: string, a: any, b: any)
	if kind == "Open" then
		local fn = draw[a]
		if fn then
			fn(openWindow(a), b or {})
		end
	elseif kind == "Note" then
		toast(tostring(a))
	end
end)
local _ = RunService
