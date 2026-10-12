--!strict
-- DEV ONLY: test coins (100M and 100T) behind every firm. Runs only in Studio playtests
-- (RunService:IsStudio()), so it never exists in live servers. Delete this script any time.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if not RunService:IsStudio() then
	return
end

local PlayerData = require(ServerScriptService:WaitForChild("Server"):WaitForChild("PlayerData") :: ModuleScript)

local RESPAWN = 10 -- seconds before a coin comes back
-- firm-local spots behind the back wall
local COINS = {
	{ amount = 100_000_000, label = "100M (TEST)", offset = CFrame.new(-6, 3.5, 20), color = Color3.fromRGB(255, 200, 40) },
	{ amount = 100_000_000_000_000, label = "100T (TEST)", offset = CFrame.new(6, 3.5, 20), color = Color3.fromRGB(80, 230, 255) },
}

local function placeCoin(firm: Model, which: number)
	local info = COINS[which]
	local coin = Instance.new("Part")
	coin.Name = "DevCoin" .. which
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.8, 5, 5)
	coin.Color = info.color
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	-- just behind the building's back wall, whatever size the firm is (it grows with expansions)
	local box, size = firm:GetBoundingBox()
	local backZ = firm:GetPivot():PointToObjectSpace(box.Position).Z + size.Z / 2
	coin.CFrame = firm:GetPivot() * CFrame.new(info.offset.X, info.offset.Y, backZ + 6) * CFrame.Angles(0, math.rad(90), 0)
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(200, 50)
	label.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	label.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = info.color
	text.TextStrokeTransparency = 0
	text.Text = info.label
	text.Parent = label
	label.Parent = coin
	coin.Parent = firm

	-- slow spin so it's easy to spot
	task.spawn(function()
		while coin.Parent do
			coin.CFrame *= CFrame.Angles(math.rad(3), 0, 0)
			task.wait(0.03)
		end
	end)

	local taken = false
	coin.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or not PlayerData.get(player) then
			return
		end
		taken = true
		PlayerData.addCoins(player, info.amount)
		coin:Destroy()
		task.delay(RESPAWN, function()
			if firm.Parent then
				placeCoin(firm, which)
			end
		end)
	end)
end

-- firms are built per player at runtime under Workspace.Plots.<Plot>.Firm
local plots = workspace:WaitForChild("Plots")
plots.DescendantAdded:Connect(function(instance)
	if instance:IsA("Model") and instance.Name == "Firm" and instance.Parent and instance.Parent.Parent == plots then
		for which in COINS do
			task.defer(placeCoin, instance, which)
		end
	end
end)
for _, plot in plots:GetChildren() do
	local firm = plot:FindFirstChild("Firm")
	if firm and firm:IsA("Model") then
		for which in COINS do
			placeCoin(firm, which)
		end
	end
end
