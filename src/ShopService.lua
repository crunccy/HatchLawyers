--!strict
-- Robux shop, server side (Config.Shop; UI in StarterPlayerScripts.Shop). The server alone decides who owns
-- what: clients may only *prompt* purchases (MarketplaceService), never report them.
--   Game passes  owned = UserOwnsGamePassAsync on join, or PromptGamePassPurchaseFinished(purchased = true).
--                Mirrored as player attributes Pass<Key> = true; gameplay reads them via ShopService.has().
--   Products     granted ONLY in MarketplaceService.ProcessReceipt. Each PurchaseId is granted once:
--                recorded in PlayerData.Purchases and saved BEFORE returning PurchaseGranted. If the player
--                isn't loaded or the save fails we return NotProcessedYet and Roblox retries later.
-- Ids of 0 (not set up in the Creator Dashboard yet) are ignored everywhere.
-- Pass effects (Config.Shop.Effects): DoubleCash in CaseService (payout), SpeedyCases in CaseService (case
-- time), LuckyEggs + BigFirm in EggServer (roll weights, lawyer storage).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)

local ShopService = {}

local PURCHASE_HISTORY = 200
local passByKey: { [string]: any } = {}
local passById: { [number]: any } = {}
local productById: { [number]: any } = {}
for _, p in Config.Shop.Passes do
	passByKey[p.Key] = p
	if p.Id ~= 0 then
		passById[p.Id] = p
	end
end
for _, p in Config.Shop.Products do
	if p.Id ~= 0 then
		productById[p.Id] = p
	end
end

local owned: { [Player]: { [string]: boolean } } = {}

local function setOwned(player: Player, key: string)
	owned[player] = owned[player] or {}
	owned[player][key] = true
	player:SetAttribute("Pass" .. key, true)
end

-- Does this player own the pass with this Config key? (Server-side truth, not the attribute.)
function ShopService.has(player: Player, key: string): boolean
	local set = owned[player]
	return set ~= nil and set[key] == true
end

-- The pass's effect value (Config.Shop.Effects) if owned, else `default`.
function ShopService.effect(player: Player, key: string, default: number): number
	return if ShopService.has(player, key) then Config.Shop.Effects[key] else default
end

local function checkPasses(player: Player)
	for key, pass in passByKey do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and has then
				setOwned(player, key)
			elseif not ok then
				warn("[ShopService] couldn't check pass", key, has)
			end
		end
	end
end

-- Applies one developer product. Returns a short text for the client's pop-up.
local function grantProduct(player: Player, data: PlayerData.Data, product: any): string
	if product.Minutes then
		local RewardsService = require(script.Parent.RewardsService) :: any
		local coins = math.max(Config.Rewards.MinCoins, math.floor(RewardsService.incomePerMinute(data) * product.Minutes))
		data.Coins += coins -- bought, not earned: stays out of Stats.CoinsEarned
		return "+" .. Formulas.formatCoins(coins) .. " coins"
	elseif product.RareTokens then
		data.Eggs.RareTokens += product.RareTokens
		player:SetAttribute("FreeEgg", true)
		player:SetAttribute("RareEggTokens", data.Eggs.RareTokens)
		return product.RareTokens .. " guaranteed RARE eggs"
	end
	return product.Name
end

local function prune(purchases: { [string]: number })
	local list = {}
	for id, t in purchases do
		table.insert(list, { id = id, t = t })
	end
	if #list <= PURCHASE_HISTORY then
		return
	end
	table.sort(list, function(a, b)
		return a.t > b.t
	end)
	for i = PURCHASE_HISTORY + 1, #list do
		purchases[list[i].id] = nil
	end
end

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and PlayerData.get(player)
	if not (player and data) then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- not here / not loaded: Roblox retries later
	end
	if PlayerData.isPromo(player) then
		-- Leave receipts pending so a promo session cannot spend Robux on a grant that is intentionally not saved.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	data.Purchases = data.Purchases or {}
	if data.Purchases[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted (a retry)
	end
	local product = productById[receipt.ProductId]
	if not product then
		warn("[ShopService] receipt for an unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local text = grantProduct(player, data, product)
	data.Purchases[purchaseId] = os.time()
	prune(data.Purchases)
	PlayerData.sync(player)
	if not PlayerData.saveNow(player) then
		-- The grant is in memory and the receipt id is recorded, so when Roblox retries we answer
		-- PurchaseGranted without granting again.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local RewardGranted = ReplicatedStorage.Remotes:FindFirstChild("RewardGranted") :: RemoteEvent?
	if RewardGranted then
		RewardGranted:FireClient(player, { kind = "Shop", text = text, title = product.Name })
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopService.start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		local pass = passById[passId]
		if purchased and pass then
			setOwned(player, pass.Key)
			local RewardGranted = ReplicatedStorage.Remotes:FindFirstChild("RewardGranted") :: RemoteEvent?
			if RewardGranted then
				RewardGranted:FireClient(player, { kind = "Shop", text = pass.Text, title = pass.Name })
			end
		end
	end)
	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

-- Test hook for Studio only (Server.ShopService is never reachable from clients): runs the real receipt
-- handler with a fake receipt, so the grant + dedupe path can be checked without real Robux.
function ShopService._testReceipt(receipt: any): Enum.ProductPurchaseDecision
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	return processReceipt(receipt)
end
function ShopService._testProducts(map: { [number]: any })
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	for id, p in map do
		productById[id] = p
	end
end
function ShopService._testGivePass(player: Player, key: string)
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	setOwned(player, key)
end

return ShopService
