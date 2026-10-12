-- Dev tool (run from the command bar / MCP in Edit mode): require(game.ServerStorage.EggMachineFx:Clone()).apply()
-- Rebuilds every hub egg machine's looping VFX from Shared.Effects (VFX v2), replacing the old plain sparkles:
-- star glints + motes in the shell (themed per egg) and a spinning slash ring on the floor disc.
local Effects = require(game.ReplicatedStorage.Shared.Effects:Clone())
local T = Effects.TEXTURES
local M = {}
local THEMES = {
	EggMachine = { "star", ColorSequence.new(Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 130, 10)) },
	BrainrotEggMachine = { "energy", ColorSequence.new(Color3.fromRGB(255, 90, 210), Color3.fromRGB(150, 50, 255)) },
	PetEggMachine = { "star", ColorSequence.new(Color3.fromRGB(255, 110, 180), Color3.fromRGB(255, 60, 120)) },
	FoodEggMachine = { "fire" },
	OceanEggMachine = { "ice" },
	SpaceEggMachine = { "energy" },
}
function M.apply()
	local log = {}
	for name, th in THEMES do
		local machine = workspace.Hub:FindFirstChild(name)
		local egg = machine and machine:FindFirstChild("Egg")
		if egg then
			for _, p in { egg.Shell, egg.FX_Shell, egg.FX_Aura } do
				for _, e in p:GetChildren() do
					if e:IsA("ParticleEmitter") or (e:IsA("Attachment") and e.Name == "FxRing") then
						e:Destroy()
					end
				end
			end
			local made = Effects.ambient(egg.FX_Shell, th[1], th[2], 1.3)
			for _, e in made do
				e.Rate *= 1.6
			end
			local tint = th[2] or (if th[1] == "ice" then Effects.ICE elseif th[1] == "fire" then Effects.FIRE else Effects.ENERGY)
			local at = Instance.new("Attachment")
			at.Name = "FxRing"
			at.Position = Vector3.new(0, 0.5, 0)
			at.Parent = egg.FX_Aura
			local e = Instance.new("ParticleEmitter")
			e.Name = "FxRingSwirl"
			e.Texture = T.slashRing
			e.Color = if typeof(tint) == "ColorSequence" then tint else ColorSequence.new(tint)
			e.Rate = 0.8
			e.Lifetime = NumberRange.new(2.4)
			e.Speed = NumberRange.new(0.01)
			e.EmissionDirection = Enum.NormalId.Top
			e.SpreadAngle = Vector2.zero
			e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			e.LockedToPart = true
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(110)
			e.Size = NumberSequence.new(11, 13)
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1),
				NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1) })
			e.LightEmission = 0.2
			e.LightInfluence = 0
			e.Brightness = 2
			e.Parent = at
			table.insert(log, name .. ": " .. #made + 1)
		end
	end
	return table.concat(log, ", ")
end
return M
