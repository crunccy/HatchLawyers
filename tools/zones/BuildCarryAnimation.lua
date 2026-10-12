-- tools/zones/BuildCarryAnimation.lua - turns tools/blender/carry_anim.json (made by tools/blender/carry_anim.py) into
-- ReplicatedStorage.Animations.CarryEggs: an Animation whose child "Source" is the KeyframeSequence (Action priority,
-- looped). StarterPlayerScripts.CarryPose plays it while a player carries zone eggs.
-- Until it's published, CarryEggs.AnimationId is empty and the animation only plays in Studio (CarryPose registers
-- Source). To publish: right-click Source > Save to Roblox (or open it in the Animation Editor > Publish), then set
-- CarryEggs.AnimationId = "rbxassetid://<id>". Re-running this keeps that id; if the Blender animation changed,
-- publish again and update the id.
-- Run in Edit mode with the JSON reachable at JSON_URL (tools/studio_sync/serve_files.ps1 -Root tools/blender).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSON_URL = "http://localhost:8766/carry_anim.json"

local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))

local folder = ReplicatedStorage:FindFirstChild("Animations")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Animations"
	folder.Parent = ReplicatedStorage
end
local anim = folder:FindFirstChild("CarryEggs")
if not anim then
	anim = Instance.new("Animation")
	anim.Name = "CarryEggs"
	anim.Parent = folder
end
local old = anim:FindFirstChild("Source")
if old then
	old:Destroy()
end

local kfs = Instance.new("KeyframeSequence")
kfs.Name = "Source"
kfs.Loop = data.looped
kfs.Priority = Enum.AnimationPriority.Action

local poses = 0
for _, key in data.keys do
	local kf = Instance.new("Keyframe")
	kf.Time = key.time
	local made = {}
	-- every keyed bone needs its whole chain up to HumanoidRootPart; the in-between ones get Weight 0 (not animated)
	local function poseFor(name: string): Pose
		if made[name] then
			return made[name]
		end
		local p = Instance.new("Pose")
		p.Name = name
		local c = key.poses[name]
		if c then
			p.CFrame = CFrame.new(table.unpack(c))
			p.Weight = 1
			poses += 1
		else
			p.Weight = 0
		end
		p.EasingStyle = Enum.PoseEasingStyle.Linear
		local parentName = data.parents[name]
		p.Parent = if parentName then poseFor(parentName) else kf
		made[name] = p
		return p
	end
	for name in key.poses do
		poseFor(name)
	end
	kf.Parent = kfs
end
kfs.Parent = anim
return ("CarryEggs: %d keyframes, %d keyed poses, %.1f s, AnimationId '%s'"):format(#data.keys, poses, data.length, anim.AnimationId)
