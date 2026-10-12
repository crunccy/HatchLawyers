-- Brings the firms to life on this player's screen. Lawyers FLOAT: a gentle bob (each its own rhythm) and a hop
-- when your case is won - no limb animation, because since the 2026-10-10 model remakes every lawyer has its own
-- shape (a shark on three legs, a crocodile bomber...) and a humanoid rig pose doesn't fit them (user's call).
-- Clients are people: they're still animated with Shared.Puppet (fidget, watch their lawyer, react to the verdict).
-- Purely visual and local; only things near the camera and on screen move.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Puppet = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Puppet")) :: any
local CaseResult = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CaseResult") :: RemoteEvent

local player = Players.LocalPlayer
local ANIMATE_RANGE = 110 -- studs from the camera
local SCAN_EVERY = 0.5

type Tracked = { model: Model, desk: Instance, role: string, anim: any, dirty: boolean, conns: { RBXScriptConnection }, phase: number, hopAt: number }
local FLOAT = { rootPos = Vector3.zero, rootRot = Vector3.zero, head = Vector3.zero, armL = Vector3.zero, armR = Vector3.zero, legL = Vector3.zero, legR = Vector3.zero }
local BOB, HOP, HOP_TIME = 0.14, 0.7, 0.55

-- a lawyer's float: bob + (after a win) a quick hop arc
local function float(entry: Tracked, t: number)
	local y = 0.14 + math.sin(t * 2 + entry.phase) * BOB
	local since = t - entry.hopAt
	if since >= 0 and since < HOP_TIME then
		local u = since / HOP_TIME
		y += math.sin(u * math.pi) * HOP
	end
	FLOAT.rootPos = Vector3.new(0, y, 0)
	entry.anim.puppet:apply(FLOAT)
end
local tracked: { [Model]: Tracked } = {}

local function untrack(model: Model)
	local t = tracked[model]
	if not t then
		return
	end
	for _, c in t.conns do
		c:Disconnect()
	end
	if model.Parent then
		pcall(function()
			t.anim.puppet:reset()
		end)
	end
	tracked[model] = nil
end

local function track(model: Model, desk: Instance, role: string)
	if tracked[model] then
		return
	end
	local ok, puppet = pcall(Puppet.new, model)
	if not ok then
		return
	end
	local entry: Tracked = { model = model, desk = desk, role = role, anim = Puppet.animator(puppet, role), dirty = false, conns = {},
		phase = math.random() * 6.28, hopAt = -10 }
	-- a skin change adds/removes parts: re-sort the puppet on the next scan
	local function markDirty(d)
		if d:IsA("BasePart") then
			entry.dirty = true
		end
	end
	table.insert(entry.conns, model.DescendantAdded:Connect(markDirty))
	table.insert(entry.conns, model.DescendantRemoving:Connect(markDirty))
	tracked[model] = entry
end

local function scan()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	local seen = {}
	for _, plot in plots:GetChildren() do
		local firm = plot:FindFirstChild("Firm")
		if firm then
			for _, desk in firm:GetChildren() do
				if desk.Name:match("^Desk%d+$") then
					for _, child in desk:GetChildren() do
						if child:IsA("Model") and (child.Name == "Lawyer" or child.Name == "Client") then
							seen[child] = true
							track(child, desk, if child.Name == "Lawyer" then "lawyer" else "client")
						end
					end
				end
			end
		end
	end
	for model, entry in tracked do
		if not seen[model] or not model.Parent then
			untrack(model)
		elseif entry.dirty then
			entry.dirty = false
			pcall(function()
				entry.anim.puppet:rebuild()
			end)
		end
	end
	-- lawyers type during a case and look up between clients; clients watch their lawyer
	for _, entry in tracked do
		if entry.role == "lawyer" then
			local phase = entry.desk:GetAttribute("Phase")
			entry.anim.class = if phase == "Case" then "working" else "lawyer"
		else
			local lawyer = entry.desk:FindFirstChild("Lawyer")
			local head = lawyer and lawyer:FindFirstChild("Head")
			entry.anim.lookAt = if head and head:IsA("BasePart") then head.Position else nil
		end
	end
end

task.spawn(function()
	while true do
		local ok, err = pcall(scan)
		if not ok then
			warn("[DeskLife]", err)
		end
		task.wait(SCAN_EVERY)
	end
end)

-- only people near the camera AND on screen are animated (perf 2026-10-09: off-screen lawyers used to be re-posed
-- every frame too; a pose costs nothing to skip and they pick up exactly where the clock says when seen again)
RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local view = camera.ViewportSize
	local t = os.clock()
	for model, entry in tracked do
		local at = entry.anim.puppet.base.Position
		if (at - eye).Magnitude >= ANIMATE_RANGE then
			continue
		end
		local screen, inFront = camera:WorldToViewportPoint(at)
		local margin = 220
		if inFront and screen.X > -margin and screen.X < view.X + margin and screen.Y > -margin and screen.Y < view.Y + margin then
			local ok = pcall(if entry.role == "lawyer" then float else entry.anim.step, if entry.role == "lawyer" then entry else entry.anim, t)
			if not ok then
				untrack(model)
			end
		end
	end
end)

-- Your own desks react to the verdict.
CaseResult.OnClientEvent:Connect(function(result: { desk: number, outcome: string })
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local desk = firm and firm:FindFirstChild("Desk" .. tostring(result.desk))
	if not desk then
		return
	end
	for _, child in desk:GetChildren() do
		local entry = tracked[child :: any]
		if entry and entry.role == "lawyer" then
			if result.outcome == "Win" then
				entry.hopAt = os.clock() -- a happy hop
			end
		elseif entry then
			if result.outcome == "Win" then
				entry.anim:play(if entry.role == "lawyer" then "celebrate" else "cheer")
			elseif result.outcome == "Settlement" then
				entry.anim:play(if entry.role == "lawyer" then "shrug" else "nod")
			else
				entry.anim:play(if entry.role == "lawyer" then "slump" else "despair")
			end
		end
	end
end)
