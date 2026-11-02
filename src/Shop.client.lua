--!strict
-- Robux shop UI. Rebuilt 2026-10-10 on Shared.Skin after the user's reference recording (an egg-simulator Shop); v3
-- (2026-10-23, docs/UI_STYLE_V3.md): gold striped header, breathing pictures, glinting buy buttons, coloured side tabs.
-- v4 (2026-11-02, crnuch's shop redesign brief), top to bottom:
--   YOUR PICKS      bought pick-a-lawyer tokens waiting to be spent (unchanged)
--   FEATURED        ONE offer chosen for this player right now: a free gift ready to claim > VIP daily cash ready >
--                   the next cash-journey pack > the first pass they don't own > Pick a Legendary (featuredItem)
--   CASH JOURNEY    Config.Shop.CashJourney as numbered steps on a track: done (green check), available (lit, the
--                   only one that moves) or locked ("Finish step N first!"). FREE tags only on a claimable step.
--                   "+N% more" value tags only once BOTH live Robux prices are known (MarketplaceService)
--   PASSES          one-time game passes, 2 to a row with room for long names (Id 0 = not on sale = not shown)
--   CASH TOP-UPS    the repeatable income products, each with "about +X coins" from your income now (CoinsPerMinute)
--   PICK A LAWYER   the Legendary / Mythic / Supreme products as wide cards with the lawyer in 3D (2026-11-02)
-- Every item picture is a Blender render (tools/shop_icons.py -> Shared.ArtAssets.Shop[Key]); no 3D stand-ins.
-- Items, ids and prices: Config.Shop. Server: Server.ShopService. This script only PROMPTS purchases
-- (MarketplaceService); the server alone grants anything. Opened by the SHOP tile in the HUD's menu column
-- (Shared.HudMenu) and by the ShopPrompt on Hub.ShopStall.
-- PICK A LAWYER (2026-11-02, crnuch): a bought pick is a token (player attribute PickTokens "5:1,7:2") shown as a YOUR
-- PICKS card at the top, and the picker window lists every lawyer of that rarity - tap PICK, then SURE? (it can't be
-- undone) -> Remotes.PickLawyer. A new token opens the picker by itself.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local ArtAssets = require(Shared:WaitForChild("ArtAssets") :: ModuleScript) :: any
local Formulas = require(Shared:WaitForChild("Formulas") :: ModuleScript) :: any
local SkinLook = require(Shared:WaitForChild("SkinLook") :: ModuleScript) :: any

local make, text = Skin.make, Skin.text
local Icons = HudMenu.Icons
local W, H = 1000, 640
local WHITE = Color3.new(1, 1, 1)
local TITLE_GOLD = Color3.fromHex("FFE15A") -- v3: card titles are yellow with the ink outline
local MUTED = Color3.fromHex("6E5A96") -- locked (Skin's muted purple: no grey, crnuch)
local DONE = Color3.fromHex("4B2D86") -- a finished journey step: quiet, out of the way
local PASS_ORDER = { "VIP", "DoubleCash", "LuckyEggs", "SpeedyCases" } -- the featured spot's pass preference

------------------------------------------------------------------ the window
local win = Skin.window({ Name = "Shop", Title = "Shop", Color = "Gold", Icon = Icons.Cart, Size = Vector2.new(W, H), DisplayOrder = 32 }) -- above BigCase (30) toasts
local scroller = Skin.scroller(win.body)

------------------------------------------------------------------ item lookups + state (the server is the source of truth;
-- these only read the attributes it sets)
local function findItem(list: { any }, key: string): any?
	for _, it in list do
		if it.Key == key then
			return it
		end
	end
	return nil
end

local journeyIndex: { [string]: number } = {}
for i, key in Config.Shop.CashJourney do
	journeyIndex[key] = i
end

local prices: { [string]: number } = {} -- verified live Robux prices (GetProductInfo)
local offSale: { [string]: boolean } = {}
local pending: { [string]: boolean } = {}
local claimRemote = ReplicatedStorage.Remotes:WaitForChild("ClaimFreeShopReward") :: RemoteEvent
local vipClaim = ReplicatedStorage.Remotes:WaitForChild("ClaimVIPDaily") :: RemoteFunction

local function live(item: any): boolean
	return item.Id ~= nil and item.Id ~= 0 and not offSale[item.Key]
end

local function owns(item: any): boolean
	return player:GetAttribute("Pass" .. item.Key) == true
end

local function stepDone(key: string): boolean
	return player:GetAttribute("FreeShopClaim" .. key) == true or player:GetAttribute("CashPassClaim" .. key) == true
		or player:GetAttribute("Pass" .. key) == true
end

local function unlocked(item: any): boolean
	local previous = item.Prerequisite
	if not previous then
		return true
	end
	if string.sub(previous, 1, 4) == "Free" then
		return player:GetAttribute("FreeShopClaim" .. previous) == true
	end
	return player:GetAttribute("CashPassClaim" .. previous) == true
end

local function vipReady(): boolean
	return (player:GetAttribute("VIPLastClaimDay") or -1) < os.time() // 86400
end

local function lockReason(item: any): string
	local n = item.Prerequisite and journeyIndex[item.Prerequisite]
	return if n then "Finish step " .. n .. " first!" else "Claim the one before it first!"
end

local function priceText(item: any): string
	return Skin.ROBUX .. tostring(prices[item.Key] or item.Price)
end

-- what the item's button shows: state ("default" | "pending" | "owned" | "disabled"), label, reason
local function stateOf(item: any, kind: string): (string, string, string?)
	if kind == "free" then
		if player:GetAttribute("FreeShopClaim" .. item.Key) == true then
			return "owned", "CLAIMED", nil
		elseif not unlocked(item) then
			return "disabled", "LOCKED", lockReason(item)
		end
		return if pending[item.Key] then "pending" else "default", "CLAIM FREE", nil
	end
	if kind == "pass" then
		if item.Coins and stepDone(item.Key) then
			return "owned", "OWNED", nil
		elseif item.Key == "VIP" and owns(item) then
			if not vipReady() then
				return "owned", "CLAIMED TODAY", nil
			end
			return if pending[item.Key] then "pending" else "default", "DAILY CASH!", nil
		elseif owns(item) then
			return "owned", "OWNED", nil
		elseif not unlocked(item) then
			return "disabled", "LOCKED", lockReason(item)
		end
	end
	if not live(item) then
		return "disabled", "OFF SALE", "Not on sale right now"
	end
	return if pending[item.Key] then "pending" else "default", priceText(item), nil
end

-- coins per Robux against the journey's first pack; nil until both live prices are verified
local function moreCoins(item: any): number?
	local first = findItem(Config.Shop.Passes, Config.Shop.CashJourney[1])
	if not (item.Coins and first and first.Coins and item ~= first and prices[item.Key] and prices[first.Key]) then
		return nil
	end
	local more = math.floor(((item.Coins / prices[item.Key]) / (first.Coins / prices[first.Key]) - 1) * 100 + 0.5)
	return if more >= 5 then more else nil
end

-- an income product's payout right now (the server's formula: Config.Rewards.MinCoins floor)
local function estimate(item: any): number
	local perMinute = tonumber(player:GetAttribute("CoinsPerMinute")) or 0
	return math.max(Config.Rewards.MinCoins, math.floor(perMinute * item.Minutes))
end

------------------------------------------------------------------ pictures
local function picture(parent: GuiObject, key: string, z: number, alive: boolean): ImageLabel?
	local art = ArtAssets.Shop[key]
	if not art then
		warn("[Shop] no artwork for", key) -- run_checks: every shop item has ArtAssets.Shop art
		return nil
	end
	local img = make("ImageLabel", {
		Name = "Picture", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Fit, ZIndex = z, Parent = parent,
	})
	if alive then
		Skin.breathe(img, 4, 0.4) -- only what you can act on moves
	end
	return img
end

------------------------------------------------------------------ lawyers in 3D (the pick-a-lawyer cards + picker)
-- one posed model per lawyer id (Shared.SkinLook on an invisible stand-in, like the LAWYERS panel), cloned per viewport
local spinners: { { model: Model, base: CFrame } } = {}
local lawyerCache: { [string]: Model | false } = {}
local function lawyerModel(id: string): Model?
	local cached = lawyerCache[id]
	if cached == nil then
		cached = false
		local base = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "StandIn"
		body.Anchored = true
		body.Transparency = 1
		body.Size = Vector3.new(2, 5, 1)
		body.CFrame = CFrame.new(0, 2.5, 0)
		body.Parent = base
		base.PrimaryPart = body
		pcall(SkinLook.dress, base, id)
		if base:FindFirstChild("SkinModel") then
			for _, d in base:GetDescendants() do
				if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") or d:IsA("Sound")
					or d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("Highlight") or d:IsA("Humanoid") then
					d:Destroy()
				end
			end
			base.PrimaryPart = nil
			body:Destroy()
			cached = base
		else
			base:Destroy()
		end
		lawyerCache[id] = cached
	end
	return if cached then (cached :: Model):Clone() else nil
end

-- every lawyer of one rarity (Config.SkinCatalog order)
local function lawyersOf(rarity: number): { any }
	local list = {}
	for _, skin in Config.SkinCatalog do
		if skin.Rarity == rarity then
			table.insert(list, skin)
		end
	end
	return list
end

local function viewLawyer(parent: GuiObject, id: string, z: number)
	local vf = make("ViewportFrame", {
		Name = "Picture", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 205),
		LightColor = Color3.fromRGB(255, 250, 240), LightDirection = Vector3.new(-0.5, -1, -0.6), ZIndex = z, Parent = parent,
	})
	local m = lawyerModel(id)
	if not m then
		return
	end
	m.Parent = vf
	local box, size = m:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local h = math.max(size.Y, size.X * 0.8)
	cam.CFrame = CFrame.lookAt(box.Position + Vector3.new(0, h * 0.08, -h * 2.4), box.Position)
	cam.Parent = vf
	vf.CurrentCamera = cam
	table.insert(spinners, { model = m, base = m:GetPivot() })
end

-- the product card's picture: the rarity's showiest lawyer (its last in the catalog), turning
local function lawyerPicture(parent: GuiObject, rarity: number, z: number)
	local list = lawyersOf(rarity)
	if #list > 0 then
		viewLawyer(parent, list[#list].Id, z)
	end
end

------------------------------------------------------------------ cards
type Card = { item: any, kind: string, price: any, frame: GuiObject }
local cards: { Card } = {}

local function refreshCard(c: Card)
	local state, label, why = stateOf(c.item, c.kind)
	c.price.setText(label)
	c.price.setState(state, why)
end

local function refreshKey(key: string?)
	for _, c in cards do
		if key == nil or c.item.Key == key then
			refreshCard(c)
		end
	end
end

local function hookPurchase(c: Card)
	local item, kind = c.item, c.kind
	c.price.button.Activated:Connect(function()
		if player:GetAttribute("PromoMode") == true then
			return
		end
		local state = stateOf(item, kind)
		if state ~= "default" then -- owned / locked / off sale / already waiting: nothing to do
			return
		end
		pending[item.Key] = true
		refreshKey(item.Key)
		if kind == "pass" and item.Key == "VIP" and owns(item) then
			task.spawn(function()
				local ok, result = pcall(function()
					return vipClaim:InvokeServer()
				end)
				pending[item.Key] = nil
				refreshKey(item.Key)
				if not ok then
					warn("[Shop] VIP claim failed", result)
				end
			end)
		elseif kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		elseif kind == "free" then
			claimRemote:FireServer(item.Key)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
		task.delay(20, function() -- safety: never leave a card stuck on "..."
			if pending[item.Key] then
				pending[item.Key] = nil
				refreshKey(item.Key)
			end
		end)
	end)
end

local function card(c: Card): Card
	table.insert(cards, c)
	hookPurchase(c)
	refreshCard(c)
	return c
end

local function buyButton(frame: GuiObject, z: number, props: { [string]: any }): any
	props.Parent = frame
	props.Style = props.Style or "Green"
	props.Font = Skin.Fonts.Number
	props.ZIndex = z + 1
	props.TextStroke = props.TextStroke or 3
	return Skin.button(props)
end

-- a card that keeps its sunburst inside (ClipsDescendants) in a plain holder that ribbons and tags can poke out of
local function heldCard(parent: GuiObject, opts: { [string]: any }): (Frame, Frame)
	local holder = make("Frame", { Name = "Holder", Size = opts.Size or UDim2.fromScale(1, 1), LayoutOrder = opts.LayoutOrder,
		BackgroundTransparency = 1, ZIndex = parent.ZIndex + 1, Parent = parent })
	opts.Size, opts.LayoutOrder = UDim2.fromScale(1, 1), nil
	return holder, Skin.card(holder, opts)
end

-- small print under a section title ("Buy once, yours forever")
local function caption(s: string, order: number)
	text({ Name = "Caption", Size = UDim2.new(1, -8, 0, 28), LayoutOrder = order, Text = s, FontFace = Skin.Fonts.Body,
		TextColor3 = Skin.TextSoft, ZIndex = scroller.ZIndex + 1, Parent = scroller }, 24, 2)
end

-- a white tick drawn from two bars (no font glyph to go missing)
local function tick(parent: GuiObject, px: number, z: number)
	local holder = make("Frame", { Name = "Tick", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(px, px), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	local w = math.max(4, math.floor(px * 0.2))
	make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.3, 0.62), Size = UDim2.fromOffset(w, px * 0.48),
		Rotation = -45, BackgroundColor3 = WHITE, ZIndex = z, Parent = holder }, { Skin.corner(w // 2), Skin.stroke(2) })
	make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.45), Size = UDim2.fromOffset(w, px * 0.86),
		Rotation = 40, BackgroundColor3 = WHITE, ZIndex = z, Parent = holder }, { Skin.corner(w // 2), Skin.stroke(2) })
end

------------------------------------------------------------------ FEATURED: what this player can buy or claim right now
type Pick = { item: any, kind: string, kicker: string, ribbon: string }
local function featuredItem(): Pick?
	for _, key in Config.Shop.CashJourney do -- 1. a free gift waiting
		local free = findItem(Config.Shop.FreeRewards, key)
		if free and stateOf(free, "free") == "default" then
			return { item = free, kind = "free", kicker = "FREE GIFT READY!", ribbon = "FREE!" }
		end
	end
	local vip = findItem(Config.Shop.Passes, "VIP")
	if vip and owns(vip) and vipReady() then -- 2. today's VIP cash
		return { item = vip, kind = "pass", kicker = "YOUR VIP CASH IS READY!", ribbon = "VIP" }
	end
	for i, key in Config.Shop.CashJourney do -- 3. the next pack on the journey
		local pass = findItem(Config.Shop.Passes, key)
		if pass and live(pass) and not stepDone(key) and unlocked(pass) then
			return { item = pass, kind = "pass", kicker = "CASH JOURNEY - STEP " .. i .. " OF " .. #Config.Shop.CashJourney,
				ribbon = if i == 1 then "START HERE" else "NEXT STEP" }
		end
	end
	for _, key in PASS_ORDER do -- 4. a pass they don't have yet
		local pass = findItem(Config.Shop.Passes, key)
		if pass and live(pass) and not owns(pass) then
			return { item = pass, kind = "pass", kicker = "FOREVER PASS", ribbon = "POPULAR" }
		end
	end
	for _, product in Config.Shop.Products do -- 5. choose your own lawyer
		if product.PickRarity and live(product) then
			return { item = product, kind = "product", kicker = "YOU CHOOSE THE LAWYER", ribbon = "YOU CHOOSE!" }
		end
	end
	return nil
end

local function featuredCard(f: Pick, order: number)
	local item = f.item
	local holder, frame = heldCard(scroller, { Color = item.Color, Size = UDim2.new(1, -8, 0, 236), LayoutOrder = order, GlowAt = Vector2.new(0.19, 0.5) })
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(18, 8), Size = UDim2.new(0, 300, 1, -16), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	if item.PickRarity then
		lawyerPicture(art, item.PickRarity, z)
	else
		picture(art, item.Key, z, true)
	end
	local left = 340
	text({ Name = "Kicker", Position = UDim2.fromOffset(left, 18), Size = UDim2.new(1, -left - 170, 0, 30), Text = f.kicker,
		TextColor3 = Skin.Lime, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 26, 3)
	text({ Name = "Name", Position = UDim2.fromOffset(left, 48), Size = UDim2.new(1, -left - 30, 0, 56), Text = string.upper(item.Name),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 50, 5)
	local info = item.Text
	if item.Minutes then
		info = "About +" .. Formulas.formatCoins(estimate(item)) .. " coins for you right now"
	end
	text({ Name = "Info", Position = UDim2.fromOffset(left, 108), Size = UDim2.new(1, -left - 30, 0, 32), Text = info, FontFace = Skin.Fonts.Body,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 26, 2)
	local price = buyButton(frame, z, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -18), Size = UDim2.fromOffset(280, 72),
		TextSize = 38, TextStroke = 4, Glint = true })
	Skin.ribbon(holder, f.ribbon, "Red", z + 3)
	local more = moreCoins(item)
	if more then
		Skin.tag(holder, "+" .. more .. "% MORE COINS", { Position = UDim2.new(1, -162, 1, -94), ZIndex = z + 4, Height = 38, TextSize = 28 })
	end
	card({ item = item, kind = f.kind, price = price, frame = frame })
end

------------------------------------------------------------------ CASH JOURNEY: numbered steps on a track
local ROW_H = 112
local function journeyRow(i: number, item: any, kind: string, order: number)
	local count = #Config.Shop.CashJourney
	local done = stepDone(item.Key)
	local state = stateOf(item, kind)
	local open = state == "default" or state == "pending"
	local row = make("Frame", { Name = "Step" .. i, Size = UDim2.new(1, -8, 0, ROW_H), LayoutOrder = order, BackgroundTransparency = 1,
		ZIndex = scroller.ZIndex + 1, Parent = scroller })
	local z = row.ZIndex
	-- the track: a rail through every node (green behind finished steps) and a numbered node
	local nodeX, nodeY = 38, ROW_H // 2
	local railTop = if i == 1 then nodeY else -6
	local railBottom = if i == count then nodeY else ROW_H + 6
	make("Frame", { Name = "Rail", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(nodeX, railTop),
		Size = UDim2.fromOffset(10, railBottom - railTop), BackgroundColor3 = if done then Skin.Palette.Green.base else MUTED,
		BorderSizePixel = 0, ZIndex = z, Parent = row }, { Skin.stroke(2) })
	local nodeSw = if done then Skin.Palette.Green elseif open then Skin.Palette.Gold else Skin.swatch(MUTED)
	local node = make("Frame", { Name = "Node", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(nodeX, nodeY),
		Size = UDim2.fromOffset(60, 60), BackgroundColor3 = WHITE, ZIndex = z + 1, Parent = row }, {
		Skin.corner(30), Skin.stroke(4),
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(nodeSw.light, nodeSw.base) }),
	})
	if done then
		tick(node, 34, z + 2)
	else
		text({ Size = UDim2.fromScale(1, 1), Text = tostring(i), ZIndex = z + 2, Parent = node }, 32, 3)
	end
	if open then
		Skin.breathe(node, 0, 1.1)
	end
	-- the step's card
	local color = if done then DONE elseif not open then MUTED elseif kind == "free" then Skin.Palette.Gold else Skin.Palette.Green
	local frame = Skin.card(row, { Color = color, Position = UDim2.fromOffset(84, 4), Size = UDim2.new(1, -84, 1, -8), GlowAt = Vector2.new(0.08, 0.5),
		Spin = open, Twinkle = open, ZIndex = z + 1 })
	local cz = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(8, 4), Size = UDim2.new(0, 110, 1, -8), BackgroundTransparency = 1, ZIndex = cz, Parent = frame })
	local img = picture(art, item.Key, cz, open)
	if img and not open then
		img.ImageTransparency = if done then 0.15 else 0.35
	end
	local title = text({ Name = "Name", Position = UDim2.fromOffset(128, 12), Size = UDim2.new(1, -128 - 250, 0, 40), Text = item.Name,
		TextColor3 = if open then TITLE_GOLD else WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = cz + 1, Parent = frame }, 32, 3)
	local sub = item.Text
	if state == "disabled" and not done then
		sub = (if kind == "free" then "Free gift - unlocks" else "Unlocks") .. " after step " .. tostring(item.Prerequisite and journeyIndex[item.Prerequisite] or i - 1)
	end
	local subtitle = text({ Name = "Info", Position = UDim2.fromOffset(128, 54), Size = UDim2.new(1, -128 - 250, 0, 44), Text = sub,
		FontFace = Skin.Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = cz + 1, Parent = frame }, 24, 2)
	if not open then
		title.TextTransparency = 0.15
		subtitle.TextTransparency = 0.2
	end
	local price = buyButton(frame, cz, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 2), Size = UDim2.fromOffset(220, 60),
		Style = if kind == "free" then "Orange" else "Green", TextSize = 32, Glint = open })
	if open and kind == "free" then
		Skin.tag(row, "FREE!", { Color = "Green", Position = UDim2.new(1, -126, 0, 4), ZIndex = cz + 4, Height = 38, TextSize = 28 }) -- on the row: the card clips
	elseif open then
		local more = moreCoins(item)
		if more then
			Skin.tag(row, "+" .. more .. "% MORE COINS", { Position = UDim2.new(1, -126, 0, 4), ZIndex = cz + 4, Height = 38, TextSize = 28 })
		end
	end
	card({ item = item, kind = kind, price = price, frame = frame })
end

local function journeyHeader(order: number)
	local count, done = #Config.Shop.CashJourney, 0
	for _, key in Config.Shop.CashJourney do
		if stepDone(key) then
			done += 1
		end
	end
	local bar = make("Frame", { Name = "Progress", Size = UDim2.new(1, -8, 0, 40), LayoutOrder = order, BackgroundTransparency = 1,
		ZIndex = scroller.ZIndex + 1, Parent = scroller })
	local z = bar.ZIndex
	text({ Size = UDim2.new(0, 330, 1, 0), Text = if done >= count then "JOURNEY COMPLETE!" else done .. " OF " .. count .. " STEPS DONE",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z, Parent = bar }, 26, 3)
	local track = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(1, -350, 0, 22),
		BackgroundColor3 = Skin.PanelDeep, ZIndex = z, Parent = bar }, { Skin.corner(11), Skin.stroke(3) })
	make("Frame", { Size = UDim2.fromScale(done / count, 1), BackgroundColor3 = Skin.Lime, ZIndex = z + 1, Parent = track }, { Skin.corner(11) })
end

------------------------------------------------------------------ PASSES (one-time): 2 to a row, room for long names
local function passCard(parent: GuiObject, item: any, order: number)
	local state = stateOf(item, "pass")
	local active = state == "default" or state == "pending"
	local frame = Skin.card(parent, { Color = item.Color, LayoutOrder = order, GlowAt = Vector2.new(0.2, 0.5), Twinkle = false, Spin = active })
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(8, 10), Size = UDim2.new(0, 170, 1, -20), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	picture(art, item.Key, z, active)
	local nameH = if #item.Name > 14 then 72 else 38 -- long names get two lines instead of shrinking
	text({ Name = "Name", Position = UDim2.fromOffset(186, 14), Size = UDim2.new(1, -200, 0, nameH), Text = item.Name, TextColor3 = TITLE_GOLD,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = z + 1, Parent = frame }, 32, 3)
	text({ Name = "Info", Position = UDim2.fromOffset(186, 18 + nameH), Size = UDim2.new(1, -200, 0, 50), Text = item.Text, FontFace = Skin.Fonts.Body,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = z + 1, Parent = frame }, 21, 2)
	local price = buyButton(frame, z, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.new(1, -200, 0, 54),
		Style = if item.Key == "VIP" and owns(item) then "Gold" else "Green", TextSize = 30, Glint = active })
	card({ item = item, kind = "pass", price = price, frame = frame })
end

------------------------------------------------------------------ CASH TOP-UPS (repeatable income products)
local estimates: { { label: TextLabel, item: any } } = {}
local function topUpCard(parent: GuiObject, item: any, order: number, best: boolean)
	local holder, frame = heldCard(parent, { Color = item.Color, LayoutOrder = order, GlowAt = Vector2.new(0.5, 0.3), Twinkle = false })
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -32, 0, 140), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	picture(art, item.Key, z, true)
	text({ Name = "Name", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 146), Size = UDim2.new(1, -20, 0, 38), Text = item.Name,
		TextColor3 = TITLE_GOLD, ZIndex = z + 1, Parent = frame }, 32, 3)
	local est = text({ Name = "Estimate", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 184), Size = UDim2.new(1, -20, 0, 32),
		Text = "", TextColor3 = Skin.Lime, ZIndex = z + 1, Parent = frame }, 28, 3)
	table.insert(estimates, { label = est, item = item })
	text({ Name = "Info", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 216), Size = UDim2.new(1, -24, 0, 26),
		Text = item.Text, FontFace = Skin.Fonts.Body, ZIndex = z + 1, Parent = frame }, 20, 2)
	local price = buyButton(frame, z, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -36, 0, 54),
		TextSize = 32, Glint = true })
	if best then
		Skin.ribbon(holder, "BEST VALUE", "Red", z + 3)
	end
	card({ item = item, kind = "product", price = price, frame = frame })
end

local function refreshEstimates()
	for _, e in estimates do
		if e.label.Parent then
			e.label.Text = "about +" .. Formulas.formatCoins(estimate(e.item))
		end
	end
end

------------------------------------------------------------------ PICK A LAWYER: wide cards (as 2026-11-02)
local function pickCard(item: any, order: number)
	local holder, frame = heldCard(scroller, { Color = item.Color, Size = UDim2.new(1, -8, 0, 230), LayoutOrder = order, GlowAt = Vector2.new(0.2, 0.5) })
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(16, 6), Size = UDim2.new(0.36, 0, 1, -12), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	lawyerPicture(art, item.PickRarity, z)
	text({ Name = "Name", Position = UDim2.new(0.39, 0, 0, 22), Size = UDim2.new(0.58, 0, 0, 60), Text = string.upper(item.Name),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 52, 5)
	text({ Name = "Perk", Position = UDim2.new(0.39, 0, 0, 84), Size = UDim2.new(0.58, 0, 0, 40), Text = item.Banner,
		TextColor3 = TITLE_GOLD, FontFace = Skin.Fonts.Number, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 36, 4)
	text({ Name = "Info", Position = UDim2.new(0.39, 0, 0, 126), Size = UDim2.new(0.31, 0, 0, 72), Text = item.Text, FontFace = Skin.Fonts.Body,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = z + 1, Parent = frame }, 24, 2)
	local price = buyButton(frame, z, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -18), Size = UDim2.fromOffset(250, 64),
		TextSize = 40, TextStroke = 4, Glint = true })
	Skin.ribbon(holder, "YOU CHOOSE!", "Red", z + 3)
	card({ item = item, kind = "product", price = price, frame = frame })
end

------------------------------------------------------------------ the pick-a-lawyer picker
-- unspent picks from the PickTokens attribute: { [rarity index] = count }
local function pickTokens(): { [number]: number }
	local out = {}
	local s = player:GetAttribute("PickTokens")
	if type(s) == "string" then
		for rarity, count in string.gmatch(s, "(%d+):(%d+)") do
			out[tonumber(rarity) :: number] = tonumber(count) :: number
		end
	end
	return out
end

local function rarityName(rarity: number): string
	local tier = Config.Eggs.Skins[rarity]
	return if tier then tier.Id else "?"
end

local picker = Skin.window({ Name = "LawyerPicker", Title = "Pick a Lawyer", Color = "Purple", Icon = Icons.Lawyers or Icons.Cart,
	Size = Vector2.new(940, 600), DisplayOrder = 34 })
local pickScroller = Skin.scroller(picker.body)
local pickToast = Skin.toast({ Name = "PickToast", Color = "Gold" })
local pickBusy = false

local function openPicker(rarity: number)
	for _, c in pickScroller:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local name = rarityName(rarity)
	picker.title.Text = "PICK A " .. string.upper(name)
	local color = (Config.RarityColors and Config.RarityColors[name]) or WHITE
	Skin.section(pickScroller, "Choose any one - it's yours to keep", color, 1)
	local grid = Skin.grid(pickScroller, Vector2.new(214, 318), 2)
	local tier = Config.Eggs.Skins[rarity]
	for i, skin in lawyersOf(rarity) do
		local frame = Skin.card(grid, { Color = color, LayoutOrder = i, GlowAt = Vector2.new(0.5, 0.3) })
		local z = frame.ZIndex + 2
		local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 168), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
		viewLawyer(art, skin.Id, z)
		text({ Name = "Name", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 170), Size = UDim2.new(1, -12, 0, 34),
			Text = skin.Name, TextColor3 = TITLE_GOLD, TextWrapped = true, ZIndex = z + 1, Parent = frame }, 24, 3)
		local egg = Formulas.themedEgg(skin.Egg)
		text({ Name = "Info", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 204), Size = UDim2.new(1, -16, 0, 40),
			Text = (if egg then egg.Name else "Briefcase Egg") .. "\nEarns x" .. tostring(tier and tier.Earn or 1), FontFace = Skin.Fonts.Body,
			TextWrapped = true, ZIndex = z + 1, Parent = frame }, 17, 2)
		local btn = Skin.button({ Parent = frame, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -28, 0, 48), Style = "Green", TextSize = 28, TextStroke = 3, ZIndex = z + 1, Glint = true })
		btn.setText("PICK")
		local armed = false
		btn.button.Activated:Connect(function()
			if pickBusy then
				return
			end
			if not armed then -- a pick can't be undone: tap again to be sure
				armed = true
				btn.setText("SURE?")
				btn.setStyle("Orange")
				task.delay(3, function()
					if armed and btn.button.Parent then
						armed = false
						btn.setText("PICK")
						btn.setStyle("Green")
					end
				end)
				return
			end
			armed = false
			pickBusy = true
			btn.setState("pending")
			local remote = ReplicatedStorage.Remotes:WaitForChild("PickLawyer", 5) :: RemoteFunction?
			local ok, msg = false, "Try again in a moment"
			if remote then
				local called, a, b = pcall(remote.InvokeServer, remote, skin.Id)
				if called then
					ok, msg = a, b
				end
			end
			pickBusy = false
			if ok then
				picker.hide()
				pickToast.set("You got " .. tostring(msg) .. "! Find them in LAWYERS")
				pickToast.show()
				task.delay(4, pickToast.hide)
			else
				btn.setState("default")
				btn.setText("PICK")
				btn.setStyle("Green")
				pickToast.set(tostring(msg))
				pickToast.show()
				task.delay(3, pickToast.hide)
			end
		end)
	end
	pickScroller.CanvasPosition = Vector2.zero
	picker.open()
end

------------------------------------------------------------------ live prices (Creator Dashboard is the source of truth)
local priceAsked: { [string]: boolean } = {}
local onPrices: () -> () = function() end
local function fetchPrices()
	local lists = { { Config.Shop.Passes, Enum.InfoType.GamePass }, { Config.Shop.Products, Enum.InfoType.Product } }
	for _, l in lists do
		for _, item in l[1] do
			if item.Id and item.Id ~= 0 and not priceAsked[item.Key] then
				priceAsked[item.Key] = true
				task.spawn(function()
					local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, item.Id, l[2])
					if not ok or not info then
						priceAsked[item.Key] = nil -- ask again on the next open
						return
					end
					if info.PriceInRobux then
						prices[item.Key] = info.PriceInRobux
					end
					if info.IsForSale == false then
						offSale[item.Key] = true
					end
					onPrices()
				end)
			end
		end
	end
end

------------------------------------------------------------------ build
local sections: { [string]: GuiObject } = {}
local function addSection(key: string, title: string, color: string, order: number): number
	sections[key] = Skin.section(scroller, title, color, order)
	return order + 1
end

local function build()
	for _, c in scroller:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	table.clear(cards)
	table.clear(spinners)
	table.clear(estimates)
	table.clear(sections)
	local order = 1
	-- YOUR PICKS: bought pick-a-lawyer tokens waiting to be spent, on top
	local tokens = pickTokens()
	local rarities = {}
	for rarity in tokens do
		table.insert(rarities, rarity)
	end
	table.sort(rarities, function(a, b)
		return a > b
	end)
	if #rarities > 0 then
		order = addSection("Picks", "Your Picks", "Purple", order)
		for _, rarity in rarities do
			local name = rarityName(rarity)
			local frame = Skin.card(scroller, { Color = (Config.RarityColors and Config.RarityColors[name]) or WHITE, Size = UDim2.new(1, -8, 0, 130), LayoutOrder = order, GlowAt = Vector2.new(0.15, 0.5) })
			local z = frame.ZIndex + 2
			local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0, 150, 1, -8), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
			lawyerPicture(art, rarity, z)
			text({ Name = "Name", Position = UDim2.fromOffset(176, 20), Size = UDim2.new(1, -460, 0, 52), Text = "PICK YOUR " .. string.upper(name) .. "!",
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 40, 4)
			text({ Name = "Info", Position = UDim2.fromOffset(176, 74), Size = UDim2.new(1, -460, 0, 34), Text = "You have " .. tokens[rarity] .. " to choose",
				FontFace = Skin.Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 22, 2)
			local btn = Skin.button({ Parent = frame, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0),
				Size = UDim2.fromOffset(250, 64), Style = "Green", TextSize = 36, TextStroke = 4, ZIndex = z + 1, Glint = true })
			btn.setText("CHOOSE")
			btn.button.Activated:Connect(function()
				openPicker(rarity)
			end)
			order += 1
		end
	end
	-- FEATURED: one offer, chosen for this player
	local f = featuredItem()
	if f then
		order = addSection("Featured", "Featured", "Gold", order)
		featuredCard(f, order)
		order += 1
	end
	-- CASH JOURNEY
	order = addSection("Journey", "Cash Journey", "Green", order)
	caption("Buy a pack, unlock free gifts. Every step is once per player.", order)
	order += 1
	journeyHeader(order)
	order += 1
	for i, key in Config.Shop.CashJourney do
		local pass = findItem(Config.Shop.Passes, key)
		local free = findItem(Config.Shop.FreeRewards, key)
		if free then
			journeyRow(i, free, "free", order)
		elseif pass and (live(pass) or stepDone(key)) then
			journeyRow(i, pass, "pass", order)
		end
		order += 1
	end
	-- PASSES: one-time, the cash packs are on the journey
	local passes = {}
	for _, item in Config.Shop.Passes do
		if not item.Coins and (live(item) or owns(item)) then
			table.insert(passes, item)
		end
	end
	if #passes > 0 then
		order = addSection("Passes", "Passes", "Purple", order)
		caption("Buy once, yours forever", order)
		order += 1
		local grid = Skin.grid(scroller, Vector2.new(466, 200), order)
		order += 1
		for i, item in passes do
			passCard(grid, item, i)
		end
	end
	-- CASH TOP-UPS: repeatable, paid from your income
	local topUps, pickProducts = {}, {}
	for _, item in Config.Shop.Products do
		if live(item) then
			table.insert(if item.Minutes then topUps else pickProducts, item)
		end
	end
	if #topUps > 0 then
		order = addSection("TopUps", "Cash Top-Ups", "Sky", order)
		caption("Buy as often as you like - pays from your income right now", order)
		order += 1
		-- BEST VALUE = the most minutes per Robux, once every live price is in
		local best, bestRate = nil, 0
		for _, item in topUps do
			if not prices[item.Key] then
				best = nil
				break
			end
			local rate = item.Minutes / prices[item.Key]
			if rate > bestRate then
				best, bestRate = item, rate
			end
		end
		local grid = Skin.grid(scroller, Vector2.new(306, 316), order)
		order += 1
		for i, item in topUps do
			topUpCard(grid, item, i, item == best)
		end
		refreshEstimates()
	end
	-- PICK A LAWYER
	if #pickProducts > 0 then
		order = addSection("Lawyers", "Pick a Lawyer", "Orange", order)
		for _, item in pickProducts do
			pickCard(item, order)
			order += 1
		end
	end
end

-- rebuild in place (state changed while open): keeps the scroll position, one rebuild per frame at most
local rebuildQueued = false
local function rebuild()
	if rebuildQueued or not win.isOpen() then
		return
	end
	rebuildQueued = true
	task.defer(function()
		rebuildQueued = false
		if win.isOpen() then
			local y = scroller.CanvasPosition
			build()
			scroller.CanvasPosition = y
		end
	end)
end
onPrices = rebuild -- value tags, BEST VALUE and off-sale offers follow the verified prices

------------------------------------------------------------------ side tabs: jump the scroll to a section
local function jumpTo(key: string)
	local target = sections[key]
	if not target then
		return
	end
	local unscale = W / math.max(1, win.panel.AbsoluteSize.X) -- AbsolutePosition is in screen px (after the UIScale)
	local y = (target.AbsolutePosition.Y - scroller.AbsolutePosition.Y) * unscale + scroller.CanvasPosition.Y
	Skin.tween(scroller, 0.35, { CanvasPosition = Vector2.new(0, math.max(0, y - 4)) }, Enum.EasingStyle.Quart)
end
local tabs: { [string]: TextButton } = {}
for i, t in { { "Featured", "Featured", ArtAssets.Tabs.Featured, "Gold" }, { "Journey", "Journey", ArtAssets.Tabs.Journey, "Green" },
	{ "Passes", "Passes", ArtAssets.Tabs.Passes, "Purple" }, { "TopUps", "Cash", ArtAssets.Tabs.Cash, "Sky" },
	{ "Lawyers", "Lawyers", ArtAssets.Tabs.Eggs, "Orange" } } do
	local tab = Skin.sideTab(win.sideRail, { Label = t[2], Icon = t[3], Color = t[4], LayoutOrder = i })
	tabs[t[1]] = tab
	tab.Activated:Connect(function()
		jumpTo(t[1])
	end)
end
-- v3: the tab of the section you're looking at is lit, the others dimmed
local litTab: string? = nil
local function lightTab()
	local best, bestY = "Featured", -math.huge
	for key, sec in sections do
		if sec.Parent and tabs[key] then
			local y = sec.AbsolutePosition.Y - scroller.AbsolutePosition.Y
			if y <= 60 and y > bestY then
				best, bestY = key, y
			end
		end
	end
	if best ~= litTab and tabs[best] then
		litTab = best
		Skin.selectTab(win.sideRail, tabs[best])
	end
end
scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(lightTab)

------------------------------------------------------------------ purchase results
local function clearPending(key: string?)
	for k in pending do
		if key == nil or k == key then
			pending[k] = nil
		end
	end
	refreshKey(key)
end
local lastTokens = pickTokens()
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId)
	if who == player then -- bought or cancelled: the button comes back (a purchase also flips the Pass attribute)
		for _, p in Config.Shop.Passes do
			if p.Id == passId then
				clearPending(p.Key)
			end
		end
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId)
	if userId == player.UserId then
		for _, p in Config.Shop.Products do
			if p.Id == productId then
				clearPending(p.Key)
			end
		end
	end
end)
player.AttributeChanged:Connect(function(name)
	if name == "PickTokens" then -- a pick was bought (open the picker) or spent (refresh the shop)
		local now = pickTokens()
		for rarity, count in now do
			if count > (lastTokens[rarity] or 0) and not picker.isOpen() then
				task.defer(openPicker, rarity)
				break
			end
		end
		lastTokens = now
		rebuild()
	elseif string.sub(name, 1, 4) == "Pass" or string.sub(name, 1, 13) == "FreeShopClaim" or string.sub(name, 1, 13) == "CashPassClaim"
		or name == "VIPLastClaimDay" then
		for k in pending do
			pending[k] = nil
		end
		rebuild() -- the featured offer, the journey track and the pass states all follow
	elseif name == "CoinsPerMinute" then
		refreshEstimates()
	end
end)

------------------------------------------------------------------ open / close
local function open()
	if win.isOpen() then
		return
	end
	fetchPrices()
	build()
	scroller.CanvasPosition = Vector2.zero
	win.open()
	litTab = nil
	task.defer(lightTab)
	-- cards pop in one after another (the first screenful; the rest are off-screen anyway)
	for i, c in cards do
		if i > 8 then
			break
		end
		task.delay(0.04 * i, function()
			if c.frame.Parent then
				Skin.pop(c.frame, 0.7)
			end
		end)
	end
end
win.onClose(function()
	table.clear(spinners)
end)

RunService.RenderStepped:Connect(function()
	if win.isOpen() or picker.isOpen() then
		local t = os.clock()
		for i, s in spinners do
			s.model:PivotTo(s.base * CFrame.Angles(0, t * 0.8 + i, 0))
		end
	end
end)

------------------------------------------------------------------ the HUD button: SHOP tile in the shared menu column
local menuEntry = HudMenu.button({ name = "Shop", label = "SHOP", icon = "Shop", color = Color3.fromRGB(70, 200, 40), order = 3 })
menuEntry.setAlert(true) -- "come look" until the first visit
menuEntry.button.Activated:Connect(function()
	menuEntry.setAlert(false)
	if win.isOpen() then
		win.hide()
	else
		open()
	end
end)

-- the stall in the hub (streams in late / re-streams as new instances: listen by prompt name)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
	if prompt.Name == "ShopPrompt" then
		open()
	end
end)

task.defer(fetchPrices) -- prices are ready before the first open
task.spawn(function() -- and the pictures (no blank cards on the first open)
	local list = {}
	for _, id in ArtAssets.Shop do
		local d = Instance.new("Decal")
		d.Texture = id
		table.insert(list, d)
	end
	pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), list)
end)
