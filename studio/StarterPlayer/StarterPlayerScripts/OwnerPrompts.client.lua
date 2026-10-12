--!strict
-- Prompts tagged OwnerOnlyPrompt (like the UPGRADE FIRM sign) only show on your own firm.
-- The server also checks who triggered them; this just keeps other players' screens clean.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function apply(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local node: Instance? = prompt
	while node and node:GetAttribute("OwnerUserId") == nil do
		node = node.Parent
	end
	prompt.Enabled = node ~= nil and node:GetAttribute("OwnerUserId") == player.UserId
end

CollectionService:GetInstanceAddedSignal("OwnerOnlyPrompt"):Connect(function(prompt)
	task.defer(apply, prompt) -- wait a frame so the prompt's firm is in place
end)
for _, prompt in CollectionService:GetTagged("OwnerOnlyPrompt") do
	apply(prompt)
end
