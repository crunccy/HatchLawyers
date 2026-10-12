local Players = game:GetService("Players")

local DOUBLE_WALK_SPEED = 32 -- default is 16, doubled

local function onCharacterAdded(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = DOUBLE_WALK_SPEED
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	-- Handle the current character if it already exists
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end