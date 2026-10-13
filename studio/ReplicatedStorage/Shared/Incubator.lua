--!strict
-- Incubator (ReplicatedStorage.Shared.Incubator, client) - moves the v5 incubators (2026-10-12; model + clips made in
-- Blender: tools/blender/incubator.py -> tools/zones/BuildEggsV5.lua -> ServerStorage.Templates.IncubatorV5, cloned
-- into every firm by Server.FirmBuilder; clips in ReplicatedStorage.IncubatorAnims). The parts are anchored and the
-- server never moves them, so each client poses them locally (the owner's hatch, and other players watching it).
--   Incubator.find(near, maxDist) -> Model?       the v5 incubator nearest a point (tag "Incubator")
--   Incubator.play(model, clip, speed?, onFrame?)  plays "Open" / "Close" / "Cook" / "Overload" (yields)
--   Incubator.pose(model, clip, frame)             holds a frame (frame 0 = the first)
--   Incubator.rest(model)                          everything back in place
--   Incubator.eggSpot(model) -> CFrame            the top of the cradle (where an egg stands), upright
--   Incubator.glow(model, color?, t?)              the screen, heat ring, bulbs and tubes in a colour (nil = normal)
--   Incubator.front(model) -> Vector3             the way its control panel faces

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Incubator = {}

local anims: any = nil
local function clips(): any
	if anims == nil then
		local m = ReplicatedStorage:FindFirstChild("IncubatorAnims")
		anims = if m and m:IsA("ModuleScript") then require(m) :: any else false
	end
	return anims
end

function Incubator.isV5(model: Instance?): boolean
	return model ~= nil and model:IsA("Model") and model:GetAttribute("EggV5") == true
end

function Incubator.find(near: Vector3, maxDist: number): Model?
	local best, bestD = nil, maxDist
	for _, m in CollectionService:GetTagged("Incubator") do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			local d = (m:GetPivot().Position - near).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function partsOf(model: Model): { [string]: BasePart }
	local out = {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			out[p.Name] = p
		end
	end
	return out
end

function Incubator.pose(model: Model, clip: string, frame: number)
	local data = clips()
	local c = data and data.clips[clip]
	if not c then
		return
	end
	local root = model:GetPivot()
	local parts = partsOf(model)
	local f = math.clamp(frame, 0, c.frames - 1)
	local i = math.floor(f)
	local a = f - i
	local j = math.min(i + 1, c.frames - 1)
	for name, d in c.parts do
		local p = parts[name]
		if p then
			local k0, k1 = i * 7, j * 7
			local c0 = CFrame.new(d[k0 + 1], d[k0 + 2], d[k0 + 3], d[k0 + 4], d[k0 + 5], d[k0 + 6], d[k0 + 7])
			local c1 = CFrame.new(d[k1 + 1], d[k1 + 2], d[k1 + 3], d[k1 + 4], d[k1 + 5], d[k1 + 6], d[k1 + 7])
			p.CFrame = root * c0:Lerp(c1, a)
		end
	end
end

function Incubator.play(model: Model, clip: string, speed: number?, onFrame: ((frame: number) -> ())?)
	local data = clips()
	local c = data and data.clips[clip]
	if not c or not Incubator.isV5(model) then
		return
	end
	local fps = data.fps or 30
	local t0 = os.clock()
	while model.Parent do
		local f = (os.clock() - t0) * fps * (speed or 1)
		Incubator.pose(model, clip, f)
		if onFrame then
			onFrame(f)
		end
		if f >= c.frames - 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

-- ease the moving parts from wherever they are to a clip's frame (no snap between clips)
function Incubator.blendTo(model: Model, clip: string, frame: number, seconds: number)
	local data = clips()
	local c = data and data.clips[clip]
	if not c then
		return
	end
	local parts = partsOf(model)
	local from = {}
	for name in c.parts do
		if parts[name] then
			from[name] = parts[name].CFrame
		end
	end
	Incubator.pose(model, clip, frame)
	local to = {}
	for name in from do
		to[name] = parts[name].CFrame
		parts[name].CFrame = from[name]
	end
	local t0 = os.clock()
	while model.Parent do
		local a = math.min((os.clock() - t0) / seconds, 1)
		local e = a * a * (3 - 2 * a)
		for name, cf in from do
			parts[name].CFrame = cf:Lerp(to[name], e)
		end
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

function Incubator.rest(model: Model)
	local root = model:GetPivot()
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			local r = p:GetAttribute("Rest")
			if typeof(r) == "CFrame" then
				p.CFrame = root * r
			end
		end
	end
end

function Incubator.eggSpot(model: Model): CFrame
	local pad = model:FindFirstChild("CradlePad")
	local a = pad and pad:FindFirstChild("EggSpot")
	local root = model:GetPivot()
	if a and a:IsA("Attachment") then
		return CFrame.new(a.WorldPosition) * root.Rotation
	end
	return root * CFrame.new(0, 1.7, 0)
end

function Incubator.front(model: Model): Vector3
	return model:GetPivot().LookVector
end

local GLOW_PARTS = { "Screen", "HeatRing", "BulbL", "BulbR", "Liquid" }
function Incubator.glow(model: Model, color: Color3?, t: number?)
	for _, name in GLOW_PARTS do
		local p = model:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			if p:GetAttribute("BaseColor") == nil then
				p:SetAttribute("BaseColor", p.Color)
			end
			local goal = color or (p:GetAttribute("BaseColor") :: Color3)
			if (t or 0) > 0 then
				TweenService:Create(p, TweenInfo.new(t :: number), { Color = goal }):Play()
			else
				p.Color = goal
			end
		end
	end
end

return Incubator
