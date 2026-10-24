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
local FONT = Font.fromEnum(Enum.Font.GothamBlack) -- (UI v3: one family, game-wide)
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

-- v3 (2026-10-23, docs/UI_STYLE_V3.md): pop-ups are SMALL (crnuch: "there are a lot of popups" - keep the sunburst
-- and stripes, just smaller): the stage-up is a small gold Skin card near the top; area / need = Skin.toast pills.
local Skin = require(ReplicatedStorage.Shared:WaitForChild("Skin")) :: any
StageUp.OnClientEvent:Connect(function(info)
	if info.kind == "Stage" then
		Sfx.play("officeUpgrade", { gap = 1.5 })
		-- (crnuch 2026-10-23: pop-ups SMALLER - same gold card with its sunburst + bands, about half the old size)
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Position = UDim2.fromScale(0.5, 0.15)
		holder.Size = UDim2.fromOffset(400, 112)
		holder.BackgroundTransparency = 1
		holder:SetAttribute("NoSkin", true) -- (UISkin checks NoSkin below the ScreenGui, not on it)
		holder.Parent = gui
		local fit = Instance.new("UIScale")
		local cam = workspace.CurrentCamera
		fit.Scale = if cam then math.clamp(cam.ViewportSize.X / 640, 0.6, 1) else 1
		fit.Parent = holder
		local f = Skin.card(holder, { Color = "Gold", ZIndex = 2, GlowAt = Vector2.new(0.5, 0.5) })
		local z = f.ZIndex + 3
		local title = Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(1, -30, 0, 46), Text = "FIRM UPGRADED!",
			ZIndex = z, Parent = f }, 40, 4)
		Skin.breathe(title, 2, 0.6)
		Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.new(1, -30, 0, 26), Text = string.upper(info.name or ""),
			TextColor3 = Color3.fromHex("FFF4C2"), ZIndex = z, Parent = f }, 24, 3)
		Skin.text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 86), Size = UDim2.new(1, -30, 0, 20), FontFace = Skin.Fonts.Body,
			Text = "New rooms to build on your lawn!", ZIndex = z, Parent = f }, 16, 2)
		popAndFade(holder, 4.5)
	elseif info.kind == "Area" or info.kind == "Need" then
		local good = info.kind == "Area"
		Sfx.play(if good then "areaUnlock" else "error", { gap = if good then 1.5 else 0.8, volume = if good then 1 else 0.65 })
		Skin.toast({
			Text = if good then "BUILT: " .. string.upper(info.name or "") .. (if info.text and info.text ~= "" then "  " .. info.text else "") else (info.text or ""),
			Color = if good then "Green" else "Red", Hold = if good then 3 else 2.2, Position = UDim2.new(0.5, 0, 0.15, 128), -- (under the stage card)
		})
	end
end)
