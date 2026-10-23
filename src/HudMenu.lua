--!strict
-- HudMenu (ReplicatedStorage.Shared.HudMenu): the HUD's left-edge menu and its buttons, in one place
-- (user 2026-10-09: "the ui is cooked" - DAILY / LAWYERS / SHOP were three scripts each guessing a position
-- with different GUI insets, so they piled on top of each other). Every menu button is built here, laid out by
-- one UIGridLayout in one ScreenGui, so they can never overlap and always share the same look.
-- UI overhaul part 2 (2026-10-18): square glossy tiles in 2 columns, drawn by Shared.Skin.hudTile (gradient +
-- studs, white rim, the glossy PNG icon over the top, the label over the bottom edge, red badge / "!" top-right;
-- a note - the DAILY timer - shows as the label in lime).
--   local entry = HudMenu.button({ name = "Lawyers", label = "LAWYERS", icon = "Gavel", color = ..., order = 2 })
--   entry.button.Activated:Connect(...); entry.setBadge("3" | nil); entry.setAlert(true); entry.setNote("6:29" | nil)
--   HudMenu.wait("Lawyers") -> entry (yields until another script made it)
-- Icons is also the game's icon set for other screens (UIKit uses it too).

local Players = game:GetService("Players")

local Skin = require(script.Parent:WaitForChild("Skin")) :: any

local HudMenu = {}

-- 2026-10-18 UI overhaul: the glossy icon set (art/icons/hud_navigation_glossy, 512 px copies uploaded by crnuch).
-- Keys whose meaning matched were re-pointed (Gift, Goals, Coin, Travel, Cart, Shop); the rest are new.
-- Gavel / Trophy / Star / Scales / MoneyBag / GiftPink are still the older Creator Store images (court, rewards).
HudMenu.Icons = {
	Gift = "rbxassetid://71088033804308", -- glossy: daily-gift (yellow box, blue bow)
	Goals = "rbxassetid://80785439188685", -- glossy: goals (clipboard + tick)
	Lawyers = "rbxassetid://77103986819765", -- glossy: lawyers (brick lawyer, briefcase)
	Shop = "rbxassetid://124064224555649", -- glossy: shop (basket of gifts)
	Cart = "rbxassetid://124064224555649", -- = Shop (the Shop window's header used Cart)
	Rebirth = "rbxassetid://110198988697226", -- glossy: rebirth (purple loop + star)
	Travel = "rbxassetid://106112864052258", -- glossy: travel (gold portal)
	Money = "rbxassetid://136795484498427", -- glossy: money (cash stack + coins)
	Coin = "rbxassetid://136795484498427", -- = Money (the coin counter + coin rewards)
	Eggs = "rbxassetid://124018472915561", -- glossy: eggs (cracked star egg)
	Merge = "rbxassetid://71805052134273", -- glossy: merge (two lawyers -> one; the Mutation Machine)
	Upgrades = "rbxassetid://132845927465164", -- glossy: upgrades (arrow + bolt)
	VIP = "rbxassetid://84591968949157", -- glossy: vip (crown)
	Index = "rbxassetid://105898194017543", -- glossy: index (law book)
	-- older Creator Store images
	Gavel = "rbxassetid://18523351330", -- "gavel colored"
	GiftPink = "rbxassetid://114440493073627", -- outlined pink gift
	MoneyBag = "rbxassetid://5636506602",
	Star = "rbxassetid://15589354284", -- glossy yellow star
	Trophy = "rbxassetid://114221933505948", -- outlined cartoon trophy
	Scales = "rbxassetid://135009805354492", -- orange scales of justice
}
HudMenu.Studs = "rbxassetid://114488299634202" -- tools/ui_textures.py

local TILE = 88 -- px at a 720+ px tall screen
local GAP_X, GAP_Y = 16, 30 -- GAP_Y leaves room for the label under a tile and the icon over the next

export type Entry = {
	button: TextButton,
	setBadge: (string?) -> (),
	setAlert: (boolean) -> (),
	setNote: (string?) -> (),
}

-- tile colours by entry name (Skin.Palette), picked so each glossy icon stands out on its tile; others use opts.color
local TILE_COLORS = { Daily = "Pink", Lawyers = "Purple", Shop = "Green", Supreme = "Gold", Travel = "Sky" }

local entries: { [string]: Entry } = {}
local added = Instance.new("BindableEvent")
local column: Frame? = nil
local topRow: Frame? = nil -- v3: wide tiles (the SHOP, crnuch 2026-10-23) sit above the 2-column grid

function HudMenu.icon(name: string): string
	return HudMenu.Icons[name] or name
end

local function getColumn(): Frame
	if column and column.Parent then
		return column
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "Menu"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = playerGui
	-- the menu: a row of WIDE tiles on top (v3: the Shop), then the 2-column grid of square tiles ("Column")
	local menu = Skin.make("Frame", {
		Name = "Menu", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(TILE * 2 + GAP_X, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
	}, {
		Skin.make("UIListLayout", { Padding = UDim.new(0, GAP_Y), SortOrder = Enum.SortOrder.LayoutOrder }),
		Skin.make("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 18) }),
	})
	menu:SetAttribute("NoSkin", true)
	topRow = Skin.make("Frame", {
		Name = "Top", Size = UDim2.fromOffset(TILE * 2 + GAP_X, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 1, Parent = menu,
	}, { Skin.make("UIListLayout", { Padding = UDim.new(0, GAP_Y), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local frame = Skin.make("Frame", {
		Name = "Column", Size = UDim2.fromOffset(TILE * 2 + GAP_X, 10), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 2, Parent = menu,
	}, {
		Skin.make("UIGridLayout", {
			CellSize = UDim2.fromOffset(TILE, TILE), CellPadding = UDim2.fromOffset(GAP_X, GAP_Y),
			FillDirection = Enum.FillDirection.Horizontal, FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	frame:SetAttribute("NoSkin", true)
	-- phones: the whole menu shrinks with the screen height
	local scale = Skin.make("UIScale", { Parent = menu })
	local function fit()
		local camera = workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 720
		scale.Scale = if h < 200 then 1 else math.clamp(h / 760, 0.56, 1)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	column = frame
	return frame
end

-- names whose tile is WIDE (two columns) and sits on top, above the grid (crnuch 2026-10-23: "the shop button double
-- the width, at the top, over the other ones - stand out more")
local WIDE = { Shop = true }

-- opts: name, label, icon (HudMenu.Icons key or an image id), color, order
function HudMenu.button(opts: { name: string, label: string, icon: string, color: Color3, order: number }): Entry
	local existing = entries[opts.name]
	if existing then
		return existing
	end
	local grid = getColumn()
	local wide = WIDE[opts.name] == true
	local tile = Skin.hudTile({
		Name = opts.name, Parent = if wide then topRow else grid, Size = TILE, LayoutOrder = opts.order,
		Width = if wide then TILE * 2 + GAP_X else nil,
		Color = TILE_COLORS[opts.name] or opts.color,
		Icon = HudMenu.icon(opts.icon),
		Label = string.upper(string.sub(opts.label, 1, 1)) .. string.lower(string.sub(opts.label, 2)),
	})
	local entry: Entry = {
		button = tile.button,
		setBadge = tile.setBadge,
		setAlert = tile.setAlert,
		setNote = tile.setNote,
	}
	entries[opts.name] = entry
	added:Fire(opts.name)
	return entry
end

-- the entry another script made (yields until it exists)
function HudMenu.wait(name: string): Entry
	while not entries[name] do
		added.Event:Wait()
	end
	return entries[name]
end

-- (kept for scripts that want a heartbeat-safe check)
function HudMenu.get(name: string): Entry?
	return entries[name]
end

return HudMenu
