--!strict
-- Tutorial guide line: a glowing beam from the player to where the tutorial step wants them to go (Shared.Tutorial,
-- the same steps as the HUD's STEP hints): the incubator for the free egg, the glowing empty office, the Travel
-- portal, the nearest egg on the island, the RETURN HOME portal, then the incubator again. Steps with nothing to walk
-- to (Dave's case, court, the free upgrade) have no line. It goes away by itself once a step is done.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local COLOR = Color3.fromRGB(120, 255, 120)

local beam = Instance.new("Beam")
beam.Name = "TutorialGuide"
beam.Color = ColorSequence.new(COLOR)
beam.LightEmission = 1
beam.LightInfluence = 0
beam.FaceCamera = true
beam.Width0 = 0.9
beam.Width1 = 0.5
beam.Segments = 1
beam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.6),
	NumberSequenceKeypoint.new(0.15, 0.15),
	NumberSequenceKeypoint.new(1, 0.15),
})
beam.Enabled = false

local fromAttachment = Instance.new("Attachment")
fromAttachment.Name = "GuideFrom"
fromAttachment.Position = Vector3.new(0, -1.5, 0) -- around the feet
local toAttachment = Instance.new("Attachment")
toAttachment.Name = "GuideTo"

local Tutorial = require(game:GetService("ReplicatedStorage").Shared:WaitForChild("Tutorial")) :: any

task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local _, _, goal = Tutorial.current(player)
		if root and goal then
			fromAttachment.Parent = root
			toAttachment.Parent = goal
			beam.Attachment0 = fromAttachment
			beam.Attachment1 = toAttachment
			beam.Parent = root
			beam.Enabled = true
		else
			beam.Enabled = false
		end
	end
end)
