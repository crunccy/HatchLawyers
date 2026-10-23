--!strict
-- Robux shop UI. Rebuilt 2026-10-10 on Shared.Skin after the user's reference recording (an egg-simulator Shop):
-- green glossy header with the title + red X, a dark studded body that scrolls through "-- SECTION --" groups
-- (FEATURED wide card with a BEST VALUE! ribbon, GAME PASSES and CASH as 3-card rows, EGGS as a wide card), every
-- card a bright sunburst tile with its Blender-rendered picture (Shared.ArtAssets, tools/shop_icons.py) floating
-- gently, the name over the picture and a chunky green Robux price button; icon shortcuts beside the window jump to
-- each section. Items without artwork fall back to a little spinning block model.
-- v3 (2026-10-23, docs/UI_STYLE_V3.md, crnuch's reference video): gold striped header, breathing pictures on turning
-- sunbursts, gold card titles, glinting buy buttons, red "+N% more" value tags on the cash packs (coins per Robux
-- against the first pack), coloured side tabs that follow the scroll, OWNED in gold, LOCKED / SOON greyed.
-- Items, ids and prices: Config.Shop. Server: Server.ShopService. This script only PROMPTS purchases
-- (MarketplaceService); the server alone grants anything. Opened by the SHOP tile in the HUD's menu column
-- (Shared.HudMenu) and by the ShopPrompt on Hub.ShopStall.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local HatchShells = require(Shared:WaitForChild("HatchShells") :: ModuleScript) :: any
local Skin = require(Shared:WaitForChild("Skin") :: ModuleScript) :: any
local HudMenu = require(Shared:WaitForChild("HudMenu") :: ModuleScript) :: any
local ArtAssets = require(Shared:WaitForChild("ArtAssets") :: ModuleScript) :: any

local make, text = Skin.make, Skin.text
local Icons = HudMenu.Icons
local W, H = 1000, 620
local FEATURED_KEY = "Cash100K" -- first cash pass starts the claim path

------------------------------------------------------------------ the window
local win = Skin.window({ Name = "Shop", Title = "Shop", Color = "Gold", Icon = Icons.Cart, Size = Vector2.new(W, H), DisplayOrder = 32 }) -- above BigCase (30) toasts
local scroller = Skin.scroller(win.body)

------------------------------------------------------------------ 3D item pictures (little voxel builds, spinning)
local spinners: { { model: Model, base: CFrame } } = {}
local function box(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = model
end
local WHITE = Color3.new(1, 1, 1)
local PICTURES: { [string]: (Model) -> number } = {
	cash = function(m) -- a fanned stack of bills and a pile of gold coins; returns its size
		for k = 0, 4 do
			box(m, Vector3.new(4.2, 0.45, 2.2), CFrame.new(-0.6, -1.2 + k * 0.47, 0) * CFrame.Angles(0, math.rad(k * 9 - 18), 0), Color3.fromRGB(70, 185, 75))
			box(m, Vector3.new(1.3, 0.47, 1.0), CFrame.new(-0.6, -1.2 + k * 0.47, 0) * CFrame.Angles(0, math.rad(k * 9 - 18), 0), Color3.fromRGB(45, 140, 55))
		end
		for k = 0, 5 do
			box(m, Vector3.new(0.4, 1.5, 1.5), CFrame.new(1.7 + (k % 2) * 0.5, -1.2 + k * 0.42, 1.2) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 196, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
		return 6
	end,
	egg = function(m) -- the real Briefcase egg (Shared.HatchShells, outer layer only)
		for _, s in HatchShells.EggMachine.shards do
			for _, b in s.boxes do
				if b[10] == 0 then
					box(m, Vector3.new(b[4], b[5], b[6]), CFrame.new(b[1], b[2], b[3]), Color3.new(b[7], b[8], b[9]))
				end
			end
		end
		return 9.5
	end,
	clock = function(m) -- a stopwatch
		box(m, Vector3.new(0.9, 5, 5), CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(235, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		box(m, Vector3.new(0.3, 4, 4), CFrame.new(0, 0, -0.35) * CFrame.Angles(0, math.pi / 2, 0), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		box(m, Vector3.new(0.25, 1.6, 0.12), CFrame.new(0, 0.7, -0.55), Color3.fromRGB(40, 40, 50))
		box(m, Vector3.new(1.2, 0.25, 0.12), CFrame.new(0.5, 0, -0.55), Color3.fromRGB(40, 40, 50))
		box(m, Vector3.new(0.9, 0.8, 0.9), CFrame.new(0, 2.9, 0), Color3.fromRGB(90, 90, 110))
		box(m, Vector3.new(1.5, 0.5, 0.9), CFrame.new(0, 3.4, 0), Color3.fromRGB(235, 60, 60))
		return 6.5
	end,
	briefcase = function(m) -- a lawyer's briefcase
		box(m, Vector3.new(5, 3.4, 1.4), CFrame.new(0, -0.4, 0), Color3.fromRGB(120, 72, 40))
		box(m, Vector3.new(5.1, 0.35, 1.5), CFrame.new(0, 0.5, 0), Color3.fromRGB(90, 52, 28))
		box(m, Vector3.new(0.7, 0.6, 1.6), CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 200, 40))
		box(m, Vector3.new(2, 0.4, 0.5), CFrame.new(0, 1.9, 0), Color3.fromRGB(70, 42, 22))
		box(m, Vector3.new(0.4, 0.8, 0.5), CFrame.new(-0.8, 1.5, 0), Color3.fromRGB(70, 42, 22))
		box(m, Vector3.new(0.4, 0.8, 0.5), CFrame.new(0.8, 1.5, 0), Color3.fromRGB(70, 42, 22))
		return 6
	end,
}
-- the rendered artwork floats and sways a little (cheap: one sine per card per frame)
local floaters: { { image: ImageLabel, phase: number } } = {}
local function picture(parent: GuiObject, kind: string, z: number, art: string?)
	if art then
		local img = make("ImageLabel", {
			Name = "Picture", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Fit, ZIndex = z, Parent = parent,
		})
		Skin.breathe(img, 5, 0.45) -- v3: the reference's pictures tilt + swell
		return
	end
	local vf = make("ViewportFrame", {
		Name = "Picture", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 205),
		LightColor = Color3.fromRGB(255, 250, 240), LightDirection = Vector3.new(-0.5, -1, -0.6), ZIndex = z, Parent = parent,
	})
	local m = Instance.new("Model")
	local size = (PICTURES[kind] or PICTURES.cash)(m)
	m.Parent = vf
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size * 0.35, -size * 2.3), Vector3.new(0, 0, 0))
	cam.Parent = vf
	vf.CurrentCamera = cam
	table.insert(spinners, { model = m, base = m:GetPivot() })
end

------------------------------------------------------------------ cards
type Card = { item: any, kind: string, price: any, frame: Frame }
local cards: { Card } = {}
local prices: { [string]: number } = {}
local pending: { [string]: boolean } = {}
local claimRemote = ReplicatedStorage.Remotes:WaitForChild("ClaimFreeShopReward") :: RemoteEvent
local vipClaim = ReplicatedStorage.Remotes:WaitForChild("ClaimVIPDaily") :: RemoteFunction

local function unlocked(item: any): boolean
	local previous = item.Prerequisite
	if not previous then return true end
	if string.sub(previous, 1, 4) == "Free" then
		return player:GetAttribute("FreeShopClaim" .. previous) == true
	end
	return player:GetAttribute("CashPassClaim" .. previous) == true
end

local function owns(item: any): boolean
	return player:GetAttribute("Pass" .. item.Key) == true
end

local function refreshCard(c: Card)
	local item, price = c.item, c.price
	-- v3: states, not just colours (Skin Button.setState): owned = gold, locked / soon = grey, waiting = "..."
	local function show(t: string, state: string, why: string?)
		price.setText(t)
		price.setState(state, why)
	end
	if c.kind == "free" and player:GetAttribute("FreeShopClaim" .. item.Key) == true then
		show("CLAIMED", "owned")
	elseif c.kind == "pass" and item.Key == "VIP" and owns(item) then
		if (player:GetAttribute("VIPLastClaimDay") or -1) >= os.time() // 86400 then
			show("CLAIMED TODAY", "owned")
		elseif pending[item.Key] then
			show("CLAIM VIP DAILY", "pending")
		else
			show("CLAIM VIP DAILY", "default")
		end
	elseif c.kind == "pass" and owns(item) then
		show("OWNED", "owned")
	elseif not unlocked(item) then
		show("LOCKED", "disabled", "Claim the one before it first!")
	elseif c.kind ~= "free" and item.Id == 0 then
		show("SOON", "disabled", "Coming soon!")
	elseif pending[item.Key] then
		show(Skin.ROBUX .. (prices[item.Key] or item.Price), "pending")
	elseif c.kind == "free" then
		show("CLAIM FREE", "default")
	else
		show(Skin.ROBUX .. (prices[item.Key] or item.Price), "default")
	end
end

local function hookPurchase(c: Card)
	local item, kind = c.item, c.kind
	c.price.button.Activated:Connect(function()
		if player:GetAttribute("PromoMode") == true then return end
		if not unlocked(item) or pending[item.Key] or (kind == "pass" and (item.Id == 0 or (owns(item) and item.Key ~= "VIP"))) 
			or (item.Key == "VIP" and owns(item) and (player:GetAttribute("VIPLastClaimDay") or -1) >= os.time() // 86400)
			or (kind == "free" and player:GetAttribute("FreeShopClaim" .. item.Key) == true)
			or (kind == "product" and item.Id == 0) then
			return
		end
		pending[item.Key] = true
		refreshCard(c)
		if kind == "pass" and item.Key == "VIP" and owns(item) then
			task.spawn(function()
				local ok, result = pcall(function() return vipClaim:InvokeServer() end)
				pending[item.Key] = nil
				refreshCard(c)
				if not ok then warn("[Shop] VIP claim failed", result) end
			end)
		elseif kind == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		elseif kind == "free" then
			claimRemote:FireServer(item.Key)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
		task.delay(20, function() -- safety: never leave a card stuck on "..."
			pending[item.Key] = nil
			refreshCard(c)
		end)
	end)
end

-- a 3-per-row card: picture on a sunburst, name over the picture's foot, one line of text, the price button
local CELL = Vector2.new(296, 300)
local TITLE_GOLD = Color3.fromHex("FFE15A") -- v3: card titles are yellow with the ink outline (the reference's "2x Speed Forever")
local function smallCard(parent: GuiObject, item: any, kind: string, order: number): Card
	local frame = Skin.card(parent, { Color = item.Color, LayoutOrder = order, GlowAt = Vector2.new(0.5, 0.34) })
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 172), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	picture(art, item.Icon, z, ArtAssets.Shop[item.Key])
	text({ Name = "Name", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.new(1, -16, 0, 42),
		Text = item.Name, TextColor3 = TITLE_GOLD, ZIndex = z + 1, Parent = frame }, 32, 4)
	text({ Name = "Info", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 192), Size = UDim2.new(1, -24, 0, 38),
		Text = item.Text, FontFace = Skin.Fonts.Body, TextWrapped = true, ZIndex = z + 1, Parent = frame }, 19, 2)
	local price = Skin.button({ Parent = frame, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -36, 0, 52), Style = "Green", Font = Skin.Fonts.Number, TextSize = 34, TextStroke = 3, ZIndex = z + 1,
		Glint = true })
	local c: Card = { item = item, kind = kind, price = price, frame = frame }
	hookPurchase(c)
	refreshCard(c)
	return c
end

-- a full-width card: picture on the left, big name + text + price on the right, optional ribbon
local function wideCard(parent: GuiObject, item: any, kind: string, order: number, ribbon: string?): Card
	local frame = Skin.card(parent, { Color = item.Color, Size = UDim2.new(1, -8, 0, 230), LayoutOrder = order, GlowAt = Vector2.new(0.2, 0.5) })
	frame.ClipsDescendants = false -- the ribbon pokes out over the corner
	local z = frame.ZIndex + 2
	local art = make("Frame", { Name = "Art", Position = UDim2.fromOffset(16, 6), Size = UDim2.new(0.36, 0, 1, -12), BackgroundTransparency = 1, ZIndex = z, Parent = frame })
	picture(art, item.Icon, z, ArtAssets.Shop[item.Key])
	text({ Name = "Name", Position = UDim2.new(0.39, 0, 0, 22), Size = UDim2.new(0.58, 0, 0, 60), Text = string.upper(item.Name),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 52, 5)
	text({ Name = "Perk", Position = UDim2.new(0.39, 0, 0, 84), Size = UDim2.new(0.58, 0, 0, 40), Text = item.Banner,
		TextColor3 = TITLE_GOLD, FontFace = Skin.Fonts.Number, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z + 1, Parent = frame }, 36, 4)
	text({ Name = "Info", Position = UDim2.new(0.39, 0, 0, 126), Size = UDim2.new(0.31, 0, 0, 72), Text = item.Text, FontFace = Skin.Fonts.Body,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = z + 1, Parent = frame }, 24, 2)
	local price = Skin.button({ Parent = frame, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -18),
		Size = UDim2.fromOffset(250, 64), Style = "Green", Font = Skin.Fonts.Number, TextSize = 40, TextStroke = 4, ZIndex = z + 1,
		Glint = true })
	if ribbon then
		Skin.ribbon(frame, ribbon, "Red", z + 3) -- v3: the reference's red BEST VALUE! ribbon
	end
	local c: Card = { item = item, kind = kind, price = price, frame = frame }
	hookPurchase(c)
	refreshCard(c)
	return c
end

------------------------------------------------------------------ layout: sections + shortcuts
local sections: { [string]: GuiObject } = {}
local function addSection(key: string, title: string, color: string, order: number): number
	sections[key] = Skin.section(scroller, title, color, order)
	return order + 1
end

local function findItem(list: { any }, key: string): any?
	for _, it in list do
		if it.Key == key then
			return it
		end
	end
	return nil
end

-- v3: the reference's red "+66% more" tag on every cash pack after the first (coins per Robux against the first pack),
-- and a green FREE! tag on the free claims
local function valueTag(c: Card, pass: any?, free: any?)
	c.frame.ClipsDescendants = false
	local z = c.frame.ZIndex + 6
	if free then
		Skin.tag(c.frame, "FREE!", { Color = "Green", Position = UDim2.new(0.5, 0, 0, 2), ZIndex = z })
		return
	end
	local first = findItem(Config.Shop.Passes, Config.Shop.CashJourney[1])
	if not (pass and pass.Coins and first and first.Coins and pass ~= first) then
		return
	end
	local function rate(it: any): number
		return it.Coins / math.max(1, prices[it.Key] or it.Price or 1)
	end
	local more = math.floor((rate(pass) / rate(first) - 1) * 100 + 0.5)
	if more >= 5 then
		Skin.tag(c.frame, "+" .. more .. "% more", { Position = UDim2.new(0.5, 0, 0, 2), ZIndex = z })
	end
end

local function build()
	for _, c in scroller:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	table.clear(cards)
	table.clear(spinners)
	table.clear(floaters)
	local order = 1
	-- FEATURED: one pass, big
	local featured = findItem(Config.Shop.Passes, FEATURED_KEY) or Config.Shop.Passes[1]
	order = addSection("Featured", "Featured", "Gold", order)
	if featured then
		table.insert(cards, wideCard(scroller, featured, "pass", order, "START HERE"))
	end
	order += 1
	-- GAME PASSES: the rest, 3 to a row
	order = addSection("Passes", "Passes", "Purple", order)
	local passGrid = Skin.grid(scroller, CELL, order)
	order += 1
	for i, item in Config.Shop.Passes do
		if item ~= featured and not item.Coins then
			table.insert(cards, smallCard(passGrid, item, "pass", i))
		end
	end
	-- Cash passes and the real, one-time free claims in purchase order.
	order = addSection("Cash", "Cash", "Green", order)
	local cashGrid = Skin.grid(scroller, CELL, order)
	order += 1
	for i, key in Config.Shop.CashJourney do
		local pass = findItem(Config.Shop.Passes, key)
		local free = findItem(Config.Shop.FreeRewards, key)
		local item = pass or free
		if item then
			local c = smallCard(cashGrid, item, if pass then "pass" else "free", i)
			table.insert(cards, c)
			valueTag(c, pass, free)
		end
	end
	local others = {}
	for i, item in Config.Shop.Products do
		if item.Id ~= 0 then
			if item.Minutes then
				table.insert(cards, smallCard(cashGrid, item, "product", i + #Config.Shop.CashJourney))
			else
				table.insert(others, item)
			end
		end
	end
	-- EGGS (and anything else): wide cards
	if #others > 0 then
		order = addSection("Eggs", "Eggs", "Orange", order)
		for _, item in others do
			table.insert(cards, wideCard(scroller, item, "product", order, if item.RareTokens then "ALWAYS RARE!" else nil))
			order += 1
		end
	end
	-- real prices for set-up items (Creator Dashboard is the source of truth)
	for _, c in cards do
		local item = c.item
		if item.Id and item.Id ~= 0 and not prices[item.Key] then
			task.spawn(function()
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, item.Id,
					if c.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
				if ok and info and info.PriceInRobux then
					prices[item.Key] = info.PriceInRobux
					refreshCard(c)
				end
			end)
		end
	end
end

-- shortcuts beside the window: jump the scroll to a section
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
for i, t in { { "Featured", "Featured", ArtAssets.Tabs.Featured, "Gold" }, { "Passes", "Passes", ArtAssets.Tabs.Passes, "Purple" },
	{ "Cash", "Cash", ArtAssets.Tabs.Cash, "Green" }, { "Eggs", "Eggs", ArtAssets.Tabs.Eggs, "Orange" } } do
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
	if best ~= litTab then
		litTab = best
		Skin.selectTab(win.sideRail, tabs[best])
	end
end
scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(lightTab)

------------------------------------------------------------------ purchase results
local function clearPending(key: string?)
	for _, c in cards do
		if key == nil or c.item.Key == key then
			pending[c.item.Key] = nil
			refreshCard(c)
		end
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, passId)
	if who == player then
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
	if string.sub(name, 1, 4) == "Pass" or string.sub(name, 1, 13) == "FreeShopClaim" or string.sub(name, 1, 13) == "CashPassClaim" or name == "VIPLastClaimDay" then
		clearPending(nil)
	end
end)

------------------------------------------------------------------ open / close
local function open()
	if win.isOpen() then
		return
	end
	build()
	scroller.CanvasPosition = Vector2.zero
	win.open()
	litTab = nil
	task.defer(lightTab)
	-- cards pop in one after another
	for i, c in cards do
		task.delay(0.05 * i, function()
			if c.frame.Parent then
				Skin.pop(c.frame, 0.6)
			end
		end)
	end
end
win.onClose(function()
	table.clear(spinners)
	table.clear(floaters)
end)

RunService.RenderStepped:Connect(function()
	if win.isOpen() then
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

