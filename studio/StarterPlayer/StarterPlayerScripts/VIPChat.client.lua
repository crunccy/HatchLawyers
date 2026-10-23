--!strict
-- Shows a gold VIP tag in the modern Roblox chat.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local source = message.TextSource
	if not source then return nil end
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or player:GetAttribute("PassVIP") ~= true then return nil end
	local props = Instance.new("TextChatMessageProperties")
	props.PrefixText = '<font color="#FFCD37">[VIP]</font> ' .. message.PrefixText
	return props
end
