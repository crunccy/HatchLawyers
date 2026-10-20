-- Firm stage-up banner and area toasts (server: Server.FirmFeatures fires Remotes.FirmStageUp).
--   { kind = "Stage", stage, name } -> big "FIRM UPGRADED!" banner with a spinning sunburst
--   { kind = "Area", name, text }   -> "BUILT: <name>" toast
--   { kind = "Need", text }         -> small red toast (not enough coins / stage too low)
-- Styled with Shared.UIKit (the Figma kit) directly; tagged NoSkin so UISkin leaves it alone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIKit"))
local Sfx = require(ReplicatedStorage.Shared:WaitForChild("Sfx"))
local StageUp = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FirmStageUp") :: RemoteEvent

local player = Players.LocalPlayer
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local INK = UIKit.Colors.Ink

local gui = Instance.new("ScreenGui")
gui.Name = "FirmStageUp"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.IgnoreGuiInset = true
gui:SetAttribute("NoSkin", true)
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent: Instance, text: string, y: number, h: number, color: Color3, stroke: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(0.92, h)
	l.FontFace = FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = stroke
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

local function panel(size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(UIKit.Colors.PanelTop, UIKit.Colors.PanelBottom)
	g.Rotation = 90
	g.Parent = f
	UIKit.corner(f, 22)
	UIKit.outline(f, 5)
	UIKit.checker(f, 0.9)
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(620, 300)
	c.Parent = f
	f.Parent = gui
	return f
end

local function popAndFade(f: Frame, hold: number)
	local s = Instance.new("UIScale")
	s.Scale = 0.3
	s.Parent = f
	TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(hold, function()
		TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.3)
		f:Destroy()
	end)
end

local toastY = 0.2
StageUp.OnClientEvent:Connect(function(info)
	if info.kind == "Stage" then
		Sfx.play("officeUpgrade", { gap = 1.5 })
		local f = panel(UDim2.fromScale(0.5, 0.32), UDim2.fromScale(0.5, 0.38))
		local burst = UIKit.burst(f, UIKit.Colors.Gold, 520)
		burst.ZIndex = 0
		label(f, "FIRM UPGRADED!", 0.1, 0.32, UIKit.Colors.TextGold, 4)
		label(f, string.upper(info.name or ""), 0.44, 0.26, Color3.new(1, 1, 1), 3.5)
		label(f, "New rooms to build on your lawn!", 0.74, 0.16, UIKit.Colors.TextSoft, 2)
		popAndFade(f, 4.5)
	elseif info.kind == "Area" or info.kind == "Need" then
		local good = info.kind == "Area"
		Sfx.play(if good then "areaUnlock" else "error", { gap = if good then 1.5 else 0.8, volume = if good then 1 else 0.65 })
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0)
		f.Position = UDim2.fromScale(0.5, toastY)
		f.Size = UDim2.new(0.4, 0, 0, if good then 84 else 56)
		f.BackgroundColor3 = if good then Color3.fromRGB(98, 205, 48) else Color3.fromRGB(240, 70, 70)
		UIKit.shade(f, 1.05, 0.7)
		UIKit.corner(f, 16)
		UIKit.outline(f, 4)
		local c = Instance.new("UISizeConstraint")
		c.MaxSize = Vector2.new(560, 100)
		c.Parent = f
		f.Parent = gui
		if good then
			label(f, "BUILT: " .. string.upper(info.name or ""), 0.08, 0.5, Color3.new(1, 1, 1), 3)
			label(f, info.text or "", 0.58, 0.34, Color3.new(1, 1, 1), 2)
		else
			label(f, info.text or "", 0.15, 0.7, Color3.new(1, 1, 1), 2.5)
		end
		popAndFade(f, if good then 3 else 2.2)
	end
end)
