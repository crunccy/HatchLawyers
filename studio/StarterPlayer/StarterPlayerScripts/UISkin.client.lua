-- UISkin: dresses every screen in the UIKit style (Shared.UIKit, from the Figma "Hatch a Lawyer – UI Kit") without
-- touching the screens' own scripts. It watches PlayerGui and styles things as they appear:
--   buttons        -> chunky 3D buttons (gradient, gloss, lip, shine, bounce/squish); "X" -> red close button
--   outer panels   -> navy checker panels (white / cream frames with an outline that aren't inside another panel)
--   inner cards    -> light cards with the ink outline (rows, slots, answer cards stay light so dark text reads)
--   coloured bars  -> gradient + checker headers / banners
--   text on navy   -> white / soft lavender with an ink outline (re-applied when a script recolours it)
--   emoji icons    -> sprite-sheet icons
-- Opt out: set attribute NoSkin = true on any GuiObject (applies to its descendants too).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UIKit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- cinematic / system UIs keep their own look
local SKIP_GUIS = { Freecam = true, ProximityPrompts = true, EggHatch = true, BubbleChat = true, Chat = true, TouchGui = true }
-- big square menu buttons: their title word becomes an icon
local TITLE_ICONS = { DAILY = "Gift" }

local function screenGuiOf(inst: Instance): ScreenGui?
	return inst:FindFirstAncestorWhichIsA("ScreenGui")
end

local function skipped(inst: Instance): boolean
	local g = screenGuiOf(inst)
	if not g or SKIP_GUIS[g.Name] then
		return true
	end
	if inst:FindFirstAncestorWhichIsA("ViewportFrame") then
		return true
	end
	local a: Instance? = inst
	while a and a ~= g do
		if a:GetAttribute("NoSkin") then
			return true
		end
		a = a.Parent
	end
	return false
end

-- full-screen click-catchers / dimmers (see-through, or covering ~the whole screen; big panels on small
-- screens are not dims)
local function isDim(o: GuiObject): boolean
	if o.BackgroundTransparency >= 0.3 then
		return true
	end
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	return o.AbsoluteSize.X >= v.X * 0.9 and o.AbsoluteSize.Y >= v.Y * 0.9
end

local function nearestSurface(o: Instance): GuiObject?
	local a = o.Parent
	while a and a:IsA("GuiObject") do
		if a.BackgroundTransparency < 0.5 then
			return a
		end
		a = a.Parent
	end
	return nil
end

local function insidePanel(o: Instance): boolean
	local a = o.Parent
	while a and a:IsA("GuiObject") do
		if a:GetAttribute("UIKit") == "Panel" then
			return true
		end
		a = a.Parent
	end
	return false
end

------------------------------------------------------------------ text
local watched: { [Instance]: boolean } = {}
local function styleText(label: TextLabel | TextButton | TextBox)
	local surface = nearestSurface(label)
	local kind = surface and surface:GetAttribute("UIKit")
	if kind == "Panel" or kind == "Rarity" or kind == "Button:rarity" then
		UIKit.textOnDark(label)
	elseif kind == "Colored" or (kind and string.sub(kind, 1, 12) == "Button:color") then
		if UIKit.luminance(label.TextColor3) > 0.6 and label.TextStrokeTransparency > 0.5 then
			label.TextStrokeColor3 = UIKit.Colors.Ink
			label.TextStrokeTransparency = 0
		end
	end
	if not watched[label] then
		watched[label] = true
		local busy = false
		label:GetPropertyChangedSignal("TextColor3"):Connect(function()
			if busy then
				return
			end
			busy = true
			styleText(label)
			busy = false
		end)
		label.Destroying:Connect(function()
			watched[label] = nil
		end)
	end
end

local function restyleTextUnder(root: Instance)
	for _, d in root:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextBox") or (d:IsA("TextButton") and d.BackgroundTransparency > 0.2)) and not skipped(d) then
			styleText(d)
		end
	end
end

------------------------------------------------------------------ panel pop-in when shown
local function watchShow(panel: GuiObject)
	local g = screenGuiOf(panel)
	local chain: { GuiObject } = {}
	local a: Instance? = panel
	while a and a:IsA("GuiObject") do
		table.insert(chain, a)
		a = a.Parent
	end
	local function shown(): boolean
		if g and not g.Enabled then
			return false
		end
		for _, o in chain do
			if not o.Visible then
				return false
			end
		end
		return true
	end
	local was = shown()
	local function check()
		local now = shown()
		if now and not was then
			UIKit.popIn(panel)
		end
		was = now
	end
	for _, o in chain do
		o:GetPropertyChangedSignal("Visible"):Connect(check)
	end
	if g then
		g:GetPropertyChangedSignal("Enabled"):Connect(check)
	end
end

------------------------------------------------------------------ attention wiggle for menu buttons with a badge
local badged: { [GuiButton]: boolean } = {}
local function hasVisibleBadge(btn: GuiButton): boolean
	for _, c in btn:GetChildren() do
		if c:IsA("GuiObject") and c.Visible and c.BackgroundTransparency < 0.2 and c.AbsoluteSize.X <= 44 then
			local col = c.BackgroundColor3
			if col.R > 0.8 and col.G < 0.45 and col.B < 0.45 then
				return true
			end
		end
	end
	return false
end
task.spawn(function()
	while true do
		task.wait(3.2)
		for btn in badged do
			if btn.Parent and btn.Visible and btn.GuiState ~= Enum.GuiState.Hover and hasVisibleBadge(btn) then
				task.spawn(function()
					for _, r in { 9, -8, 6, -4, 0 } do
						UIKit.tween(btn, 0.07, { Rotation = r })
						task.wait(0.07)
					end
				end)
			end
		end
	end
end)

------------------------------------------------------------------ classify one element
local function classify(o: Instance)
	if not o.Parent or string.sub(o.Name, 1, 5) == "UIKit" or string.sub(o.Name, 1, 5) == "Icon_" or skipped(o) then
		return -- (UIKit's own decoration layers)
	end
	if o:IsA("GuiButton") then
		if o:GetAttribute("UIKit") or isDim(o) then
			return
		end
		if o.AbsoluteSize.X < 4 then
			-- not laid out yet (animated in from size 0): try again once it has a size
			local c
			c = o:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if o.AbsoluteSize.X >= 4 then
					c:Disconnect()
					classify(o)
				end
			end)
			return
		end
		if o:IsA("TextButton") and (o.Text == "X" or o.Text == "✕" or o.Text == "×") then
			UIKit.skinButton(o, "close")
			return
		end
		if o.BackgroundTransparency > 0.2 then
			if o:IsA("TextButton") then
				styleText(o)
			end
			return
		end
		UIKit.skinButton(o)
		if o.AbsoluteSize.X >= 70 and math.abs(o.AbsoluteSize.X - o.AbsoluteSize.Y) < 12 then
			badged[o] = true -- square menu button
			o.Destroying:Connect(function()
				badged[o] = nil
			end)
		end
		return
	end

	if o:IsA("Frame") then
		if o:GetAttribute("UIKit") or o.BackgroundTransparency > 0.2 or isDim(o) then
			return
		end
		local w, h = o.AbsoluteSize.X, o.AbsoluteSize.Y
		local col = o.BackgroundColor3
		local lum, sat = UIKit.luminance(col), UIKit.saturation(col)
		local stroke = o:FindFirstChildOfClass("UIStroke")
		if lum > 0.82 then
			if insidePanel(o) then
				if stroke and w >= 60 then
					UIKit.skinCard(o)
				end
			elseif stroke and w >= 120 and h >= 40 then
				UIKit.skinPanel(o)
				restyleTextUnder(o)
				if w >= 300 then
					watchShow(o)
				end
			end
		elseif lum < 0.3 and stroke and w >= 120 and h >= 30 and not insidePanel(o) then
			-- dark outlined banners (tutorial hints, toasts) join the navy panel style
			UIKit.skinPanel(o)
			restyleTextUnder(o)
		elseif sat > 0.35 and w >= 100 and h >= 18 then
			local p = o.Parent
			local squareOff = p ~= nil and p:IsA("GuiObject") and p.BackgroundColor3 == col
			UIKit.skinColored(o, squareOff)
			restyleTextUnder(o)
		end
		return
	end

	if o:IsA("TextLabel") then
		local t = string.gsub(o.Text, "^%s*(.-)%s*$", "%1")
		local icon = UIKit.EmojiIcons[t]
		local parent = o.Parent
		if not icon and parent and parent:IsA("GuiButton") then
			icon = TITLE_ICONS[string.upper(t)]
		end
		if icon then
			UIKit.replaceGlyph(o, icon)
			return
		end
		styleText(o)
	elseif o:IsA("TextBox") then
		styleText(o)
	end
end

------------------------------------------------------------------ queue: style things a frame after they appear
-- (scripts set properties after Instance.new; parents are styled before children so text knows its surface)
local pending: { [Instance]: boolean } = {}
local function depth(i: Instance): number
	local n = 0
	local a = i.Parent
	while a do
		n += 1
		a = a.Parent
	end
	return n
end

RunService.Heartbeat:Connect(function()
	if next(pending) == nil then
		return
	end
	local list = {}
	for i in pending do
		table.insert(list, i)
	end
	table.clear(pending)
	table.sort(list, function(a, b)
		return depth(a) < depth(b)
	end)
	for _, i in list do
		local ok, err = pcall(classify, i)
		if not ok then
			warn("[UISkin]", i:GetFullName(), err)
		end
	end
end)

playerGui.DescendantAdded:Connect(function(d)
	if d:IsA("GuiObject") then
		pending[d] = true
	end
end)
for _, d in playerGui:GetDescendants() do
	if d:IsA("GuiObject") then
		pending[d] = true
	end
end

-- safety net: anything that wasn't laid out (size 0) or didn't qualify yet when it appeared gets another look
task.spawn(function()
	while true do
		task.wait(2)
		for _, d in playerGui:GetDescendants() do
			if (d:IsA("GuiButton") or d:IsA("Frame")) and not d:GetAttribute("UIKit") then
				pending[d] = true
			elseif d:IsA("TextLabel") and not watched[d] then
				pending[d] = true
			end
		end
	end
end)
