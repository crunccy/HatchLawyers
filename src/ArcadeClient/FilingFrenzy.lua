--!strict
-- In-world Filing Frenzy. Papers travel on the booth belt; physical color bins are the controls.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}
local BINS = {
	{ color = Color3.fromRGB(229, 57, 53), text = "RED", glyph = "CIRCLE" },
	{ color = Color3.fromRGB(79, 203, 46), text = "GREEN", glyph = "SQUARE" },
	{ color = Color3.fromRGB(60, 150, 240), text = "BLUE", glyph = "DIAMOND" },
	{ color = Color3.fromRGB(255, 190, 31), text = "YELLOW", glyph = "STAR" },
}

function M.play(info: any, api: any)
	local kit = api.kit
	local station = api.station
	if not station then kit.toast("Walk up to Filing Frenzy and try again."); return end
	local counter = station:FindFirstChild("CounterTop") :: BasePart?
	if not counter then return end
	local folder = Instance.new("Folder")
	folder.Name = "LocalFilingFrenzyGame"
	folder.Parent = station
	local prompts: { ProximityPrompt } = {}
	local papers = info.papers
	local count, front, filed, misses = #papers, 1, 0, 0
	local parts: { [number]: BasePart } = {}
	local tabs: { [number]: BasePart } = {}
	local state: { [number]: string } = {}
	local pendingBin: { [number]: number } = {}
	local function paperColor(index: number): Color3
		return (BINS[papers[index].color] or BINS[1]).color
	end
	local function makePaper(index: number): BasePart
		local paper = Instance.new("Part")
		paper.Name = "Case File " .. index
		paper.Size = Vector3.new(0.95, 0.1, 0.72)
		paper.Color = Color3.fromRGB(248, 246, 232)
		paper.Material = Enum.Material.SmoothPlastic
		paper.Anchored, paper.CanCollide, paper.CanTouch, paper.CanQuery = true, false, false, false
		paper.Parent = folder
		local tab = Instance.new("Part")
		tab.Name = (BINS[papers[index].color] or BINS[1]).glyph
		tab.Size = Vector3.new(0.78, 0.08, 0.14)
		tab.Color = paperColor(index)
		tab.Material = Enum.Material.Neon
		tab.Anchored, tab.CanCollide, tab.CanTouch, tab.CanQuery = true, false, false, false
		tab.CFrame = paper.CFrame * CFrame.new(0, 0.06, -0.27)
		tab.Parent = folder
		tabs[index] = tab
		paper:SetAttribute("TabName", tab.Name)
		return paper
	end
	local binParts: { BasePart } = {}
	local expected = { Color3.fromRGB(229, 57, 53), Color3.fromRGB(79, 203, 46), Color3.fromRGB(60, 150, 240), Color3.fromRGB(255, 190, 31) }
	for bin = 1, math.clamp(info.colors, 2, #BINS) do
		local found: BasePart? = nil
		for _, item in station:GetDescendants() do
			if item:IsA("BasePart") and item.Name == "Prop" then
				local c = item.Color
				local e = expected[bin]
				if (c.R-e.R)^2 + (c.G-e.G)^2 + (c.B-e.B)^2 < 0.012 then found = item; break end
			end
		end
		if not found then
			local button = Instance.new("Part")
			button.Name = BINS[bin].text .. " Sort Button"
			button.Size = Vector3.new(1.1, 0.45, 1.1)
			button.CFrame = counter.CFrame * CFrame.new(0.7, 0.75, (bin - 2) * 1.5)
			button.Color = BINS[bin].color
			button.Material = Enum.Material.Brick
			button.Anchored, button.CanCollide, button.CanTouch, button.CanQuery = true, false, false, false
			button.Parent = folder
			found = button
		end
		binParts[bin] = found
	end
	local sort: (number) -> ()
	sort = function(bin: number)
		local i = front
		local data = papers[i]
		local paper = parts[i]
		if not data or not paper or state[i] or kit.now() < info.startAt + data.at - 0.04 then return end
		local t = kit.now()
		state[i] = "pending"
		pendingBin[i] = bin
		front += 1
		api.send("Sort", { i = i, bin = bin, t = t })
		kit.boothStatus(station, string.format("FILE %s INTO THE MATCHING BIN", BINS[data.color].text), BINS[data.color].color)
		if bin == data.color then kit.sound("good") else kit.sound("bad") end
	end
	for bin, target in binParts do
		local prompt = kit.physicalPrompt(target, "SORT " .. BINS[bin].text, "File Bin", function() sort(bin) end)
		table.insert(prompts, prompt)
	end
	local function positionPaper(i: number, t: number)
		local data = papers[i]
		local u = math.clamp((t - (info.startAt + data.at)) / data.travel, 0, 1)
		local z = -3.4 + u * 6.2
		return counter.CFrame * CFrame.new(-0.2, 0.62, z)
	end
	api.onAck(function(a: any)
		if a.i then
			local i = a.i
			misses = a.misses or misses
			if a.ok then filed += 1; state[i] = "ok" else state[i] = "wrong" end
			local p = parts[i]
			if p and p.Parent then
				local bin = pendingBin[i] or papers[i].color
				local target = binParts[bin]
				local goal = if a.ok and target then target.Position + Vector3.new(0, 1, 0) else positionPaper(i, kit.now()).Position + Vector3.new(0, -1, 0)
				TweenService:Create(p, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = goal, Transparency = 0.25 }):Play()
				task.delay(0.27, function() if p.Parent then p:Destroy() end end)
			end
			kit.boothStatus(station, string.format("%d FILED  |  MISSES %d / %d", filed, misses, info.misses), if a.ok then kit.GREEN else kit.RED)
			if a.ok then kit.sound("perfect") else kit.sound("bad") end
		end
		if a.shred then
			misses = a.misses or misses
			for i = front, a.shred do
				if not state[i] then
					state[i] = "shred"
					front = math.max(front, i + 1)
					local p = parts[i]
					if p and p.Parent then TweenService:Create(p, TweenInfo.new(0.18), { Position = p.Position + Vector3.new(0, -0.8, 0), Transparency = 1 }):Play(); task.delay(0.2, function() if p.Parent then p:Destroy() end end) end
				end
			end
			kit.boothStatus(station, string.format("MISSES %d / %d - KEEP FILING!", misses, info.misses), kit.RED)
		end
	end)
	kit.boothStatus(station, "SORT EACH FILE BEFORE IT REACHES THE END")
	local conn = RunService.RenderStepped:Connect(function()
		local t = kit.now()
		for i, data in papers do
			if state[i] then continue end
			local appear = info.startAt + data.at
			if t < appear then break end
			local paper = parts[i]
			if not paper then
				paper = makePaper(i)
				parts[i] = paper
			end
			paper.CFrame = positionPaper(i, t)
			local tab = tabs[i]
			if tab and tab.Parent then tab.CFrame = paper.CFrame * CFrame.new(0, 0.06, -0.27) end
		end
	end)
	local res = api.result()
	conn:Disconnect()
	kit.clearPhysicalPrompts(prompts)
	folder:Destroy()
	kit.boothStatus(station, "PLAY!")
	local gw = kit.window(api.cfg)
	kit.result(gw, res)
end

return M
