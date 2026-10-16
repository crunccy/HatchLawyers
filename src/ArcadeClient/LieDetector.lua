--!strict
-- In-world lie detector. The booth meter needle and STOP plunger are the game controls.
local RunService = game:GetService("RunService")
local M = {}

function M.play(info: any, api: any)
	local kit = api.kit
	local station = api.station
	if not station then kit.toast("Walk up to the Lie Detector booth and try again."); return end
	local counter = station:FindFirstChild("CounterTop") :: BasePart?
	if not counter then return end
	local rounds = info.rounds
	local n = #rounds
	local slotLen = info.roundTime + info.gap
	local needlePart: BasePart? = nil
	for _, item in station:GetDescendants() do
		if item:IsA("BasePart") and item.Name == "Prop" and item.Size.Y >= 1.4 and item.Size.X <= 0.3 then needlePart = item; break end
	end
	local oldNeedle = needlePart and needlePart.CFrame
	local oldSize = needlePart and needlePart.Size
	local folder = Instance.new("Folder")
	folder.Name = "LocalLieDetectorGame"
	folder.Parent = station
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Parent = folder
		return p
	end
	local panelCF = counter.CFrame * CFrame.new(1.2, 1.25, -3.3)
	part("Meter Housing", Vector3.new(0.35, 1.55, 7.2), panelCF, Color3.fromRGB(42, 45, 58), Enum.Material.Brick)
	local band = part("Truth Band", Vector3.new(0.42, 1.28, 1), panelCF * CFrame.new(0.18, 0, 0), Color3.fromRGB(98, 205, 48), Enum.Material.Neon)
	local pointer = part("Truth Needle", Vector3.new(0.5, 1.34, 0.14), panelCF * CFrame.new(0.3, 0, 0), Color3.fromRGB(238, 62, 56), Enum.Material.Metal)
	local lights: { BasePart } = {}
	for r = 1, n do
		lights[r] = part("Round Light " .. r, Vector3.new(0.28, 0.22, 0.28), panelCF * CFrame.new(0.35, 0.94, (r - (n + 1) / 2) * 0.44), Color3.fromRGB(65, 68, 82), Enum.Material.SmoothPlastic)
		lights[r].Shape = Enum.PartType.Ball
	end
	local tapped: { [number]: number } = {}
	local button = part("STOP Button", Vector3.new(0.9, 0.35, 0.9), counter.CFrame * CFrame.new(0.6, 0.55, -5.2), Color3.fromRGB(98, 205, 48), Enum.Material.Neon)
	local prompt = kit.physicalPrompt(button, "STOP!", "Lie Detector", function()
		local t = kit.now()
		local since = t - info.startAt
		local r = math.floor(since / slotLen) + 1
		if r < 1 or r > n or tapped[r] then return end
		if since - (r - 1) * slotLen > info.roundTime then return end
		tapped[r] = t
		button.Color = Color3.fromRGB(255, 200, 46)
		api.send("Tap", { t = t })
	end)
	local missed: { [number]: boolean } = {}
	local function needleAt(r: number, t: number): number
		local rd = rounds[r]
		local t0 = info.startAt + (r - 1) * slotLen
		return math.sin(2 * math.pi * ((t - t0) / rd.period + rd.phase))
	end
	api.onAck(function(a: any)
		if lights[a.round] then lights[a.round].Color = if a.perfect then kit.GOLD elseif a.hit then kit.GREEN else kit.RED end
		if a.perfect then kit.sound("perfect") elseif a.hit then kit.sound("good") else kit.sound("bad") end
		kit.boothStatus(station, if a.perfect then "PERFECT TRUTH!" elseif a.hit then "TRUTH!" else "LIE!", if a.hit then kit.GREEN else kit.RED)
	end)
	local lastRound = 0
	local conn = RunService.RenderStepped:Connect(function()
		local t = kit.now()
		local since = t - info.startAt
		if since < 0 then
			kit.boothStatus(station, "READY...")
			return
		end
		local r = math.clamp(math.floor(since / slotLen) + 1, 1, n)
		local within = since - (r - 1) * slotLen
		if r ~= lastRound then lastRound = r; kit.boothStatus(station, string.format("ROUND %d / %d - STOP IN GREEN", r, n), kit.GREEN) end
		local rd = rounds[r]
		local x = needleAt(r, tapped[r] or math.min(t, info.startAt + (r - 1) * slotLen + info.roundTime))
		band.Size = Vector3.new(0.42, 1.28, math.max(0.35, rd.band * 5.8))
		band.CFrame = panelCF * CFrame.new(0.18, 0, rd.centre * 2.9)
		pointer.CFrame = panelCF * CFrame.new(0.3, 0, x * 2.9)
		if needlePart then
			needlePart.CFrame = CFrame.new(needlePart.Position.X, needlePart.Position.Y, panelCF.Position.Z + x * 2.8)
		end
		if within > info.roundTime and not tapped[r] and not missed[r] then
			missed[r] = true
			lights[r].Color = kit.RED
			kit.sound("bad")
		end
		if r >= n and within > info.roundTime then kit.boothStatus(station, "ROUND COMPLETE") end
	end)
	local res = api.result()
	conn:Disconnect()
	prompt:Destroy()
	folder:Destroy()
	if needlePart and needlePart.Parent and oldNeedle then needlePart.CFrame = oldNeedle end
	if needlePart and oldSize then needlePart.Size = oldSize end
	kit.boothStatus(station, "PLAY!")
	local gw = kit.window(api.cfg)
	kit.result(gw, res)
end

return M
