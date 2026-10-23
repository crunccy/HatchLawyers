--!strict
-- Server-only list of accounts that receive a temporary promo/test profile.
-- Keep this separate from AdminCommands' full-admin list.
local PromoPolicy = {}

local ALLOWED_USER_IDS: { [number]: boolean } = {
	[468598163] = true, -- maddrummerman25; temporary promo profile only
	[2234491534] = true
}

function PromoPolicy.isAllowed(userId: number): boolean
	return ALLOWED_USER_IDS[userId] == true
end

return PromoPolicy
