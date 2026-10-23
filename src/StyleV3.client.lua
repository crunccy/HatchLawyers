--!strict
-- StyleV3 (StarterPlayerScripts.StyleV3): brings EVERY screen to the UI v3 look (crnuch's reference video + the Shop,
-- docs/UI_STYLE_V3.md) - including the hand-built screens that opt out of UISkin (NoSkin): LAWYERS, Manager, Skills,
-- Rebirth, Courtroom, Rewards, Goals, Mutation Machine, Big Case, minigames ... until each is rebuilt on Skin v3.
--   buttons  -> the diagonal light bands, a press ripple, and a "//" glint on the screen's main actions
--   panels   -> gray / navy / charcoal window bodies and slots become deep purple (crnuch: "not gray")
-- Skin-built and UIKit-skinned elements already have all of this and are left alone. Client-only, cosmetic.
-- Opt out: attribute KeepStyle = true on an element or an ancestor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin") :: ModuleScript) :: any

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local SKIP_GUIS = { Freecam = true, TouchGui = true, BubbleChat = true, Chat = true, ProximityPrompts = true, Menu = true }
local MAIN_WORDS = { "BUY", "CLAIM", "UPGRADE", "HATCH", "EQUIP BEST", "MUTATE", "REBIRTH", "COLLECT", "ATTEND", "PLAY", "START", "HIRE" }

local PURPLE = Skin.Panel
local PURPLE_DEEP = Skin.PanelDeep
local SLOT = Color3.fromHex("4A2A85") -- cards / slots on the panel
local MUTED = Color3.fromHex("6E5A96") -- inactive buttons
local LAVENDER = Color3.fromHex("E6DAFF") -- light gray picture boxes

local function skipped(g: Instance): boolean
	if g:FindFirstAncestorWhichIsA("ViewportFrame") then
		return true
	end
	local a: Instance? = g
	while a and a ~= playerGui do
		if a:GetAttribute("KeepStyle") then
			return true
		end
		if a:IsA("ScreenGui") and SKIP_GUIS[a.Name] then
			return true
		end
		a = a.Parent
	end
	return false
end

-- dark and colourless: the old navy / charcoal / gray bodies (not black shades, not coloured cards)
local function isDullDark(c: Color3): boolean
	local h, s, v = c:ToHSV()
	local _ = h
	return v > 0.06 and v < 0.42 and s < 0.42
end

local function textOf(b: GuiButton): string
	if b:IsA("TextButton") and b.Text ~= "" then
		return string.upper(b.Text)
	end
	for _, d in b:GetDescendants() do
		if d:IsA("TextLabel") and d.Text ~= "" then
			return string.upper(d.Text)
		end
	end
	return ""
end

local done: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function styleButton(b: GuiButton)
	if b:GetAttribute("UIKit") or b:GetAttribute("SkinState") ~= nil or b:FindFirstChild("Stripes") or b:FindFirstChild("UIKitStripes") then
		return -- Skin v3 / UIKit v3 already did it
	end
	if b.BackgroundTransparency > 0.5 or b.AbsoluteSize.Y < 26 or b.AbsoluteSize.X < 40 then
		return -- icon buttons, click-catchers, tiny chips
	end
	if not b:FindFirstChildOfClass("UICorner") then
		return -- not a chunky button (full-screen dims, list rows)
	end
	-- gray buttons (the old "disabled" / secondary look) become a dim purple - crnuch: "not gray"
	local function ungray()
		local _, sat, v = b.BackgroundColor3:ToHSV()
		if sat < 0.15 and v > 0.3 and v < 0.85 then
			b.BackgroundColor3 = MUTED -- an inactive button: muted purple
		elseif isDullDark(b.BackgroundColor3) then
			b.BackgroundColor3 = SLOT -- dark slots / cards: a purple a step lighter than the panel
		end
	end
	ungray()
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(ungray)
	Skin.stripes(b, 0.82, 3, 0.08)
	if not b:FindFirstChild("PressScale") then -- Skin.pressable already ripples
		b.Activated:Connect(function(input: InputObject?)
			local at = if input and input.Position then Vector2.new(input.Position.X, input.Position.Y) else nil
			Skin.ripple(b, at)
		end)
	end
	local t = textOf(b)
	for _, w in MAIN_WORDS do
		if string.find(t, w, 1, true) then
			Skin.glint(b)
			break
		end
	end
end

local function stylePanel(f: Frame)
	if f.BackgroundTransparency > 0.6 then
		return
	end
	local function apply()
		local c = f.BackgroundColor3
		if isDullDark(c) then
			local _, _, v = c:ToHSV()
			f.BackgroundColor3 = if v < 0.2 then PURPLE_DEEP else PURPLE
		end
	end
	apply()
	f:GetPropertyChangedSignal("BackgroundColor3"):Connect(apply)
end

-- closed windows lay out late: wait until the element has a size, then style it once
local function whenSized(g: GuiObject, fn: () -> ())
	if g.AbsoluteSize.X > 0 then
		fn()
		return
	end
	local conn: RBXScriptConnection? = nil
	conn = g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if g.AbsoluteSize.X > 0 and conn then
			conn:Disconnect()
			conn = nil
			fn()
		end
	end)
end

local function visit(g: Instance)
	if done[g] or not g:IsA("GuiObject") then
		return
	end
	if skipped(g) then
		return
	end
	done[g] = true
	if g:IsA("GuiButton") then
		-- size is known once it's laid out
		task.defer(function()
			if g.Parent then
				whenSized(g, function()
					styleButton(g)
				end)
			end
		end)
	elseif g:IsA("ViewportFrame") or g:IsA("ImageLabel") or g:IsA("ScrollingFrame") then
		-- picture boxes and lists: light gray -> lavender, dark gray -> purple
		task.defer(function()
			local o = g :: GuiObject
			if not o.Parent or o.BackgroundTransparency > 0.6 then
				return
			end
			local function apply()
				local _, sat, v = o.BackgroundColor3:ToHSV()
				if sat < 0.12 and v >= 0.7 then
					o.BackgroundColor3 = LAVENDER
				elseif isDullDark(o.BackgroundColor3) then
					o.BackgroundColor3 = PURPLE_DEEP
				end
			end
			apply()
			o:GetPropertyChangedSignal("BackgroundColor3"):Connect(apply)
		end)
	elseif g:IsA("Frame") then
		task.defer(function()
			if g.Parent then
				whenSized(g, function()
					if g.AbsoluteSize.X >= 60 and g.AbsoluteSize.Y >= 40 then
						stylePanel(g)
					end
				end)
			end
		end)
	end
end

playerGui.DescendantAdded:Connect(visit)
for i, d in playerGui:GetDescendants() do
	visit(d)
	if i % 2000 == 0 then
		task.wait()
	end
end
