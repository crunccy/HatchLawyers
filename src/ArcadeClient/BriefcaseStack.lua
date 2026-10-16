--!strict
-- In-world briefcase tower. Drop is triggered on the moving brick case, not a UI button.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}
local HEIGHT = 0.52

local function tri(u: number): number
	local f = u - math.floor(u)
	return if f < 0.5 then -1 + 4 * f else 3 - 4 * f
end

function M.play(info: any, api: any)
	local kit = api.kit
	local station = api.station
	if not station then kit.toast("Walk up to Briefcase Stack and try again."); return end
	local counter = station:FindFirstChild("CounterTop") :: BasePart?
	if not counter then return end
	local folder = Instance.new("Folder")
	folder.Name = "LocalBriefcaseStackGame"
	folder.Parent = station
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Parent = folder
		return p
	end
	local tableCF = counter.CFrame * CFrame.new(-0.2, 0.45, -3.5)
	part("Stacking Pad", Vector3.new(1.8, 0.35, info.width + 0.5), tableCF, Color3.fromRGB(75, 53, 39), Enum.Material.Brick)
	part("Gold Edge", Vector3.new(1.85, 0.12, info.width + 0.6), tableCF * CFrame.new(0, -0.2, 0), kit.GOLD, Enum.Material.Metal)
	local function caseModel(width: number, level: number): Model
		local m = Instance.new("Model")
		m.Name = "Brick Briefcase " .. level
		local base = tableCF * CFrame.new(0, (level - 0.5) * HEIGHT, 0)
		local body = part("Case Body", Vector3.new(1.3, HEIGHT, math.max(0.2, width)), base, Color3.fromRGB(110 + (level * 29) % 70, 66 + (level * 23) % 70, 44 + (level * 17) % 55), Enum.Material.WoodPlanks)
		body.Parent = m
		local stripe = part("Brass Stripe", Vector3.new(1.34, 0.1, math.max(0.18, width * 0.82)), base * CFrame.new(0, 0.06, 0), kit.GOLD, Enum.Material.Metal)
		stripe.Parent = m
		local handle = part("Handle", Vector3.new(0.22, 0.18, math.min(1.3, math.max(0.18, width * 0.32))), base * CFrame.new(0.04, HEIGHT * 0.48, 0), Color3.fromRGB(66, 39, 24), Enum.Material.Wood)
		handle.Parent = m
		m.PrimaryPart = body
		m.Parent = folder
		return m
	end
	local function place(m: Model, left: number, right: number, level: number)
		local center = (left + right) / 2
		m:PivotTo(tableCF * CFrame.new(0, (level - 0.5) * HEIGHT, center))
	end
	local left, right = -info.width / 2, info.width / 2
	local level, slideAt, period, phase = 1, info.slideAt, info.period, info.phase
	local stacked: { [number]: Model } = {}
	local waiting, over = false, false
	local pendingLevel = 0
	local mover = caseModel(right - left, 1)
	local prompt = kit.physicalPrompt(mover.PrimaryPart :: BasePart, "DROP CASE", "Briefcase Stack", function()
		if waiting or over then return end
		local t = kit.now()
		if t < slideAt then return end
		waiting = true
		local x = info.travel * tri((math.max(t, slideAt) - slideAt) / period + phase)
		local center = (left + right) / 2
		local w = right - left
		local perfect = math.abs(x - center) <= info.perfectTol
		local l, r = left, right
		if not perfect then l, r = math.max(left, x - w / 2), math.min(right, x + w / 2) end
		local fell = r - l < info.minWidth
		mover.Parent = nil
		local dropped = caseModel(if fell then w else r - l, level)
		place(dropped, if fell then x - w / 2 else l, if fell then x + w / 2 else r, level)
		if not fell then stacked[level] = dropped end
		pendingLevel = level
		api.send("Drop", { t = t })
	end)
	local status = Instance.new("ScreenGui")
	status.Name = "BriefcaseStackStatus"
	status.IgnoreGuiInset, status.ResetOnSpawn, status.DisplayOrder = true, false, 36
	status.Parent = game:GetService("Players").LocalPlayer.PlayerGui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint, label.Position, label.Size = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.35, 0.06)
	label.FontFace = kit.Skin.Fonts.Number
	label.TextScaled, label.TextColor3, label.TextStrokeTransparency = true, kit.GOLD, 0.1
	label.Text = string.format("0 / %d", info.levels)
	label.Parent = status
	api.onAck(function(a: any)
		if a.level ~= pendingLevel and not a.auto then return end
		if a.auto then
			local w = right - left
			local localCase = caseModel(if a.fell then w else (a.right - a.left), a.level)
			if not a.fell then stacked[a.level] = localCase end
			place(localCase, if a.fell then a.x - w / 2 else a.left, if a.fell then a.x + w / 2 else a.right, a.level)
			mover.Parent = nil
		end
		if a.fell then
			local predicted = stacked[a.level]
			if predicted then predicted:Destroy(); stacked[a.level] = nil end
			over = true
			kit.sound("bad")
			kit.boothStatus(station, "OOPS! THE TOWER FELL")
			return
		end
		left, right = a.left, a.right
		local landed = stacked[a.level]
		if not landed then landed = caseModel(right - left, a.level); stacked[a.level] = landed end
		if landed.PrimaryPart then landed.PrimaryPart.Size = Vector3.new(1.3, HEIGHT, math.max(0.2, right - left)) end
		place(landed, left, right, a.level)
		label.Text = string.format("%d / %d", a.level, info.levels)
		kit.boothStatus(station, if a.perfect then "PERFECT STACK!" else string.format("LEVEL %d - DROP!", a.level + 1), if a.perfect then kit.GOLD else kit.GREEN)
		if a.perfect then kit.sound("perfect") else kit.sound("thud") end
		if a.top then
			over = true
			kit.boothStatus(station, "FULL TOWER!")
			kit.sound("big")
			return
		end
		if a.next then
			level, slideAt, period, phase = a.next.level, a.next.slideAt, a.next.period, a.next.phase
			mover = caseModel(right - left, level)
			prompt.Parent = mover.PrimaryPart
			waiting = false
		end
	end)
	local conn = RunService.RenderStepped:Connect(function()
		if over then return end
		local t = kit.now()
		if not waiting and t >= slideAt then
			local x = info.travel * tri((t - slideAt) / period + phase)
			local w = right - left
			place(mover, x - w / 2, x + w / 2, level)
		end
	end)
	local res = api.result()
	conn:Disconnect()
	prompt:Destroy()
	status:Destroy()
	folder:Destroy()
	kit.boothStatus(station, "PLAY!")
	local gw = kit.window(api.cfg)
	kit.result(gw, res)
end

return M
