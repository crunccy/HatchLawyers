--!strict
-- Awards the badges listed in Config.Badges (ids of 0 are switched off). Safe to call often:
-- each player/badge is only tried once per session, in the background.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local BadgeAwards = {}

local tried: { [Player]: { [string]: boolean } } = {}

function BadgeAwards.award(player: Player, key: string)
	local id = (Config.Badges :: any)[key]
	if type(id) ~= "number" or id == 0 then
		return
	end
	local mine = tried[player] or {}
	tried[player] = mine
	if mine[key] then
		return
	end
	mine[key] = true
	task.spawn(function()
		local okHas, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, id)
		if okHas and not has and player.Parent then
			local ok, err = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, id)
			if not ok then
				warn("[Badges] couldn't award", key, err)
			end
		end
	end)
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	tried[player] = nil
end)

return BadgeAwards
