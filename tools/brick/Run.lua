-- Run (2026-10-11): builds a batch of brick characters from a builder file onto a review stage, and installs them.
-- In Studio (Edit mode), with the _G helpers from the session (fetchSrc / runFile):
--   _G.BrickRun = { file = "tools/brick/Lawyers.lua", ids = { "InternSuit", ... }, kind = "lawyer" | "client" | "judge" }
--   _G.runFile("tools/brick/Run.lua")           -> builds them in a row on workspace._BrickStage (review)
--   _G.BrickRun.install = true; run again        -> builds and installs (old models kept, see BrickKit install*)
-- Builder files return { [Id] = function(k) ... end }; k is a fresh BrickKit builder for that Id.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local D = Kit.D
local run = _G.BrickRun
assert(run and run.file and run.ids, "set _G.BrickRun first")
local fn, err = loadstring(_G.fetchSrc(run.file))
assert(fn, err)
local builders = fn()

local stage = workspace:FindFirstChild("_BrickStage")
if stage then
	stage:Destroy()
end
stage = Instance.new("Folder")
stage.Name = "_BrickStage"
stage.Parent = workspace
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(#run.ids * 5 + 12, 1, 24)
floor.Position = Vector3.new(0, 499.5, 4)
floor.Color = Color3.fromRGB(110, 200, 70)
floor.TopSurface = Enum.SurfaceType.Studs
floor.Parent = stage

_G.BrickBuild = _G.BrickBuild or {}
local report = {}
for i, id in run.ids do
	local build = builders[id]
	if not build then
		table.insert(report, id .. ": NO BUILDER")
		continue
	end
	-- screen-right is -X with the camera looking +Z: lay them out toward -X so they read left to right
	local origin = Vector3.new((#run.ids - 1) * 2.5 - (i - 1) * 5, 500, 0)
	local k = Kit.new(id, origin)
	local ok, e = pcall(build, k, Kit)
	if not ok then
		table.insert(report, id .. ": ERROR " .. tostring(e))
		continue
	end
	if run.kind == "client" then
		k:finishClient()
	end
	-- rig check, done the way Shared.Puppet does it: the shoulder joint = the arm part with the highest
	-- (centre.Y + Size.Y / 2), minus half its thinner side. A prop held up high would win and move the joint.
	local warn = ""
	for _, side in { "LeftUpperArm", "RightUpperArm" } do
		local best, bestTop = nil, -math.huge
		for _, p in k.model:GetChildren() do
			if p:IsA("BasePart") and p.Name == side and p.Transparency < 1 then
				local top = p.Position.Y - origin.Y + p.Size.Y / 2
				if top > bestTop then
					best, bestTop = p, top
				end
			end
		end
		if best then
			local jointY = bestTop - math.min(best.Size.X, best.Size.Z) / 2
			local want = Kit.shoulderY - D.armW / 2
			if math.abs(jointY - want) > 0.2 then
				warn ..= string.format(" !! %s joint would be at y %.2f (want %.2f)", side, jointY, want)
			end
		end
	end
	_G.BrickBuild[id] = k
	local _, size = k.model:GetBoundingBox()
	if run.install then
		local copy = k.model:Clone()
		copy.Parent = stage
		if run.kind == "client" then
			k:installClient("brick rollout")
		elseif run.kind == "lawyer" then
			k:installLawyer("brick rollout")
		elseif run.kind == "judge" then
			k:installJudge(k.displayName or id)
		end
		table.insert(report, string.format("%s: %d parts, %.1f tall - INSTALLED%s", id, k.count, size.Y, warn))
	else
		k.model.Parent = stage
		table.insert(report, string.format("%s: %d parts, %.1f tall%s", id, k.count, size.Y, warn))
	end
end
return table.concat(report, "\n")
