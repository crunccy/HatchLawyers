--!strict
-- Animates the firms' client NPCs (tag FirmClient, set up by Server.CaseService): walking along the
-- server's WalkPath (WalkStart / WalkSpeed) and sitting on the waiting-room couches (Seated).
-- Local only, with Shared.Puppet; the server owns where they really stand. Once a client reaches a
-- desk, StarterPlayerScripts.DeskLife animates it like before.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Puppet = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Puppet") :: ModuleScript) :: any

local ANIMATE_RANGE = 140 -- studs from the camera

type Track = {
	model: Model,
	puppet: any?,
	mode: "walk" | "sit" | "none",
	path: { Vector3 },
	start: number,
	speed: number,
	lift: number, -- pivot height above the feet
	height: number,
	conns: { RBXScriptConnection },
}

local tracks: { [Model]: Track } = {}

local function stopPuppet(track: Track)
	if track.puppet then
		pcall(function()
			track.puppet:reset()
		end)
		track.puppet = nil
	end
end

local function measure(track: Track)
	local box, size = track.model:GetBoundingBox()
	track.lift = track.model:GetPivot().Position.Y - (box.Position.Y - size.Y / 2)
	track.height = size.Y
end

-- Re-reads the model's attributes and picks what to animate.
local function refresh(track: Track)
	local model = track.model
	if track.mode == "walk" then
		-- a plain reset would re-pose the parts at the last walking direction, over where the server just
		-- put the client (that's what sat clients facing the wall): snap to the server's RestPivot instead
		local rest = model:GetAttribute("RestPivot")
		if track.puppet and typeof(rest) == "CFrame" then
			pcall(function()
				track.puppet:apply(Puppet.emptyPose(), rest)
			end)
		end
		track.puppet = nil
	else
		stopPuppet(track)
	end
	if model:GetAttribute("Walking") then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, model:GetAttribute("WalkPath") or "[]")
		local path = {}
		if ok and type(decoded) == "table" then
			for _, p in decoded do
				table.insert(path, Vector3.new(p[1], p[2], p[3]))
			end
		end
		if #path >= 2 then
			track.path = path
			track.start = (model:GetAttribute("WalkStart") :: number?) or workspace:GetServerTimeNow()
			track.speed = (model:GetAttribute("WalkSpeed") :: number?) or 10
			measure(track)
			track.mode = "walk"
			return
		end
	elseif model:GetAttribute("Seated") then
		measure(track)
		track.mode = "sit"
		return
	end
	track.mode = "none"
end

local function untrack(model: Model)
	local track = tracks[model]
	if track then
		stopPuppet(track)
		for _, c in track.conns do
			c:Disconnect()
		end
		tracks[model] = nil
	end
end

local function track(model: Instance)
	if not model:IsA("Model") or tracks[model] then
		return
	end
	local t: Track = { model = model, mode = "none", path = {}, start = 0, speed = 10, lift = 3, height = 4.5, conns = {} }
	tracks[model] = t
	for _, name in { "Walking", "Seated", "WalkStart", "RestPivot" } do
		table.insert(t.conns, model:GetAttributeChangedSignal(name):Connect(function()
			-- let the server's final position arrive before re-measuring
			task.defer(refresh, t)
		end))
	end
	task.defer(refresh, t)
end

-- Where along the path the walk is: position and facing.
local function sample(path: { Vector3 }, distance: number): (Vector3, Vector3, boolean)
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local len = (b - a).Magnitude
		if distance <= len or i == #path then
			local u = if len > 0 then math.clamp(distance / len, 0, 1) else 1
			local dir = if len > 0 then (b - a).Unit else Vector3.new(0, 0, -1)
			return a:Lerp(b, u), dir, i == #path and u >= 1
		end
		distance -= len
	end
	return path[#path], Vector3.new(0, 0, -1), true
end

CollectionService:GetInstanceAddedSignal("FirmClient"):Connect(track)
CollectionService:GetInstanceRemovedSignal("FirmClient"):Connect(function(m)
	if m:IsA("Model") then
		untrack(m)
	end
end)
for _, m in CollectionService:GetTagged("FirmClient") do
	track(m)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local clock = os.clock()
	local serverNow = workspace:GetServerTimeNow()
	for model, t in tracks do
		if not model.Parent then
			untrack(model)
			continue
		end
		if t.mode == "none" then
			continue
		end
		local near = (model:GetPivot().Position - eye).Magnitude < ANIMATE_RANGE
		if t.mode == "walk" then
			local pos, dir, done = sample(t.path, (serverNow - t.start) * t.speed)
			if not t.puppet then
				local ok, puppet = pcall(Puppet.new, model)
				t.puppet = if ok then puppet else nil
			end
			if t.puppet and not done then
				local flat = Vector3.new(dir.X, 0, dir.Z)
				if flat.Magnitude < 0.01 then
					flat = Vector3.new(0, 0, -1)
				end
				local base = CFrame.lookAt(pos, pos + flat) + Vector3.new(0, t.lift, 0)
				t.puppet:apply(if near then Puppet.walkPose(clock) else Puppet.emptyPose(), base)
			end
		elseif t.mode == "sit" and near then
			if not t.puppet then
				local ok, puppet = pcall(Puppet.new, model)
				t.puppet = if ok then puppet else nil
			end
			if t.puppet then
				t.puppet:apply(Puppet.sitPose(clock, t.height))
			end
		end
	end
end)
