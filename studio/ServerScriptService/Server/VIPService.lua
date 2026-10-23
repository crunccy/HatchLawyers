--!strict
-- Benefits for the VIP game pass. ShopService verifies ownership; this module applies
-- the visual perks and handles the one daily VIP cash claim.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local VIPService = {}
local GOLD = Color3.fromRGB(255, 205, 55)
local DAY = 86400

function VIPService.decorateCharacter(player: Player, character: Model)
	if player:GetAttribute("PassVIP") ~= true or character:FindFirstChild("VIPGlow") then return end
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not head or not root then return end
	local glow = Instance.new("Highlight")
	glow.Name = "VIPGlow"
	glow.FillColor = GOLD
	glow.FillTransparency = 0.85
	glow.OutlineColor = GOLD
	glow.OutlineTransparency = 0.15
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = character
	local sparkle = Instance.new("Sparkles")
	sparkle.Name = "VIPSparkles"
	sparkle.SparkleColor = GOLD
	sparkle.Parent = root
	local tag = Instance.new("BillboardGui")
	tag.Name = "VIPNameplate"
	tag.Adornee = head
	tag.Size = UDim2.fromOffset(210, 52)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 120
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "★ VIP ★  " .. player.DisplayName
	label.TextColor3 = GOLD
	label.TextStrokeColor3 = Color3.fromRGB(40, 25, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = tag
end

function VIPService.decorateFirm(player: Player, firm: Model?)
	if player:GetAttribute("PassVIP") ~= true or not firm then return end
	for _, office in firm:GetChildren() do
		if office:IsA("Model") and office.Name:match("^Desk%d+$") and not office:FindFirstChild("VIPOfficeStar") then
			local star = Instance.new("Part")
			star.Name = "VIPOfficeStar"
			star.Shape = Enum.PartType.Ball
			star.Size = Vector3.new(0.65, 0.65, 0.65)
			star.CFrame = CFrame.new(office:GetPivot().Position + Vector3.new(0, 5, 0))
			star.Anchored = true
			star.CanCollide = false
			star.CanTouch = false
			star.CanQuery = false
			star.Material = Enum.Material.Neon
			star.Color = GOLD
			star.Parent = office
			local light = Instance.new("PointLight")
			light.Color = GOLD
			light.Brightness = 0.65
			light.Range = 8
			light.Parent = star
			local sign = Instance.new("BillboardGui")
			sign.Name = "VIPOfficePlaque"
			sign.Adornee = star
			sign.Size = UDim2.fromOffset(130, 32)
			sign.StudsOffsetWorldSpace = Vector3.new(0, 0.55, 0)
			sign.MaxDistance = 55
			sign.Parent = star
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Text = "★ VIP OFFICE ★"
			text.TextScaled = true
			text.Font = Enum.Font.GothamBold
			text.TextColor3 = GOLD
			text.TextStrokeTransparency = 0
			text.Parent = sign
		end
	end
end

function VIPService.claimDaily(player: Player): { [string]: any }
	if player:GetAttribute("PassVIP") ~= true then return { ok = false, reason = "VIP pass required" } end
	local data = PlayerData.get(player)
	if not data then return { ok = false, reason = "Still loading" } end
	local day = os.time() // DAY
	if data.VIP.LastClaimDay >= day then return { ok = false, reason = "Already claimed today" } end
	local RewardsService = require(script.Parent.RewardsService)
	local amount = math.max(5000, math.floor(RewardsService.incomePerMinute(data) * 5))
	data.VIP.LastClaimDay = day
	data.Coins += amount
	PlayerData.sync(player)
	if not PlayerData.saveNow(player) then warn("[VIPService] daily claim save pending", player.UserId) end
	player:SetAttribute("VIPLastClaimDay", day)
	local message = "+" .. Formulas.formatCoins(amount) .. " VIP coins"
	local rewardGranted = ReplicatedStorage.Remotes:FindFirstChild("RewardGranted") :: RemoteEvent?
	if rewardGranted then rewardGranted:FireClient(player, { kind = "Shop", title = "VIP Daily Reward", text = message }) end
	return { ok = true, text = message }
end

function VIPService.onDataLoaded(player: Player)
	local data = PlayerData.get(player)
	if data then player:SetAttribute("VIPLastClaimDay", data.VIP.LastClaimDay) end
end

function VIPService.start()
	local function track(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.defer(VIPService.decorateCharacter, player, character)
		end)
		if player.Character then task.defer(VIPService.decorateCharacter, player, player.Character) end
		player:GetAttributeChangedSignal("PassVIP"):Connect(function()
			if player.Character then task.defer(VIPService.decorateCharacter, player, player.Character) end
		end)
	end
	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do track(player) end
end

return VIPService