--!strict
-- Effects LOD (perf 2026-10-09): continuous particle emitters (lawyer auras, egg-machine fx, floor rings) far from
-- the camera stop emitting; they come back as you get near. Far away they're a few pixels anyway, but every one
-- of them was still spawning and simulating particles - with 8 firms of Rare+ lawyers that's 100+ emitters.
-- Only emitters that are ON and continuous (Rate > 0) are touched; bursts (:Emit) never are. If another script
-- switches an emitter off while it's paused here, that wins: it stays off and is forgotten.

local FAR = 150 -- studs: past this, continuous emitters pause
local NEAR = 130 -- and resume inside this (a gap so they don't flicker at the edge)
local CHECK_EVERY = 0.4
local BATCH = 150 -- emitters checked per step, so a huge map never spikes one frame

type Entry = { emitter: ParticleEmitter, paused: boolean, guard: boolean }
local entries: { [ParticleEmitter]: Entry } = {}
local list: { Entry } = {}

local function position(e: ParticleEmitter): Vector3?
	local p = e.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	elseif p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	return nil
end

local function add(d: Instance)
	if not d:IsA("ParticleEmitter") or entries[d] or d:GetAttribute("NoLod") then
		-- (NoLod: the emitter's own script handles distance - StarterPlayerScripts.Ambience, 2026-10-20)
		return
	end
	local entry: Entry = { emitter = d, paused = false, guard = false }
	entries[d] = entry
	table.insert(list, entry)
	d:GetPropertyChangedSignal("Enabled"):Connect(function()
		if entry.guard or not entry.paused then
			return
		end
		if d.Enabled then
			-- someone turned it on while it's far: keep it paused (it resumes when near)
			entry.guard = true
			d.Enabled = false
			entry.guard = false
		else
			entry.paused = false -- its owner wants it off: not ours any more
		end
	end)
end

local function remove(d: Instance)
	local entry = entries[d :: ParticleEmitter]
	if entry then
		entries[d :: ParticleEmitter] = nil
		local i = table.find(list, entry)
		if i then
			list[i] = list[#list]
			list[#list] = nil
		end
	end
end

workspace.DescendantAdded:Connect(add)
workspace.DescendantRemoving:Connect(remove)
for _, d in workspace:GetDescendants() do
	add(d)
end

local function set(entry: Entry, on: boolean)
	entry.guard = true
	entry.emitter.Enabled = on
	entry.guard = false
end

task.spawn(function()
	local cursor = 1
	while true do
		local camera = workspace.CurrentCamera
		if camera and #list > 0 then
			local eye = camera.CFrame.Position
			for _ = 1, math.min(BATCH, #list) do
				if cursor > #list then
					cursor = 1
				end
				local entry = list[cursor]
				cursor += 1
				local e = entry.emitter
				local at = position(e)
				if at then
					local dist = (at - eye).Magnitude
					if entry.paused then
						if dist < NEAR then
							entry.paused = false
							set(entry, true)
						end
					elseif e.Enabled and e.Rate > 0 and dist > FAR then
						entry.paused = true
						set(entry, false)
					end
				end
			end
		end
		task.wait(CHECK_EVERY)
	end
end)
