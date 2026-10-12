--!strict
-- Tutorial guide line: a glowing beam from the player to where the tutorial wants them to go, matching
-- the HUD's STEP hints: (1 the first client walks to the lawyer by themselves, 2 court and 3 the free upgrade are
-- on-screen, no line), 4 the firm's incubator for the free egg, 5 the glowing empty office for the hatched lawyer.
-- It goes away by itself once that step is done. Steps are worked out from attributes, so nothing is saved.

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

local function owned(): number
	return (player:GetAttribute("LawyersOwned") or 0) :: number
end
local function working(): number
	return (player:GetAttribute("LawyerCount") or 0) :: number
end

-- Where the tutorial wants the player right now, or nil.
local function target(): BasePart?
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = typeof(plotName) == "string" and plots and plots:FindFirstChild(plotName)
	local firm = plot and plot:FindFirstChild("Firm")
	local room = firm and firm:FindFirstChild("WaitingClients")
	if room and player:GetAttribute("FirstCaseDone") == false then
		for _, client in room:GetChildren() do
			local head = client:FindFirstChild("Head")
			if client:GetAttribute("Waiting") == true and head and head:IsA("BasePart") then
				return head
			end
		end
	end
	local upgradeFirst = ((player:GetAttribute("FreeLevelUps") or 0) :: number) > 0 -- step 3 comes before the egg
	if player:GetAttribute("FirstCaseDone") == true and not upgradeFirst and owned() <= 1 and player:GetAttribute("FreeEgg") == true then
		local incubators = firm and firm:FindFirstChild("Incubators")
		local inc = incubators and incubators:FindFirstChildWhichIsA("Model")
		local part = inc and inc:FindFirstChild("Base")
		return if part and part:IsA("BasePart") then part else nil
	end
	-- a hatched lawyer waiting in the inventory and an empty office: point at the office
	if firm and owned() > working() and owned() <= 2 then
		for i = 1, (player:GetAttribute("DeskCount") or 0) :: number do
			if player:GetAttribute("Desk" .. i .. "Lawyer") == nil then
				local desk = firm:FindFirstChild("Desk" .. i)
				local pad = desk and desk:FindFirstChild("EmptyOffice")
				return if pad and pad:IsA("BasePart") then pad else nil
			end
		end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local goal = target()
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
