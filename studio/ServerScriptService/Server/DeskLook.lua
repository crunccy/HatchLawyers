--!strict
-- Dresses a desk model for its tier (Config.Desks.Tiers), in the game's chunky cartoon style.
-- Works on any Desk<N> that has a "Top" part: tier pieces are placed relative to Top, and the
-- desk's own "Leg"/"Pedestal" parts are hidden while panels replace them. Tier 1 restores the
-- original look. Calling it again swaps tiers cleanly.

local DeskLook = {}

type Style = {
	top: Color3,
	topMaterial: Enum.Material,
	body: Color3?, -- side and front panels; nil keeps the original legs (tier 1)
	trim: Color3?,
	extras: { string },
}

local GOLD = Color3.fromRGB(255, 205, 60)

local STYLES: { Style } = {
	{ top = Color3.new(), topMaterial = Enum.Material.Plastic, extras = {} }, -- tier 1: original folding table
	{ top = Color3.fromRGB(205, 140, 72), topMaterial = Enum.Material.Wood, body = Color3.fromRGB(176, 110, 52), extras = { "Knobs" } },
	{ top = Color3.fromRGB(112, 68, 42), topMaterial = Enum.Material.Wood, body = Color3.fromRGB(92, 54, 34), trim = GOLD, extras = { "Knobs", "Lamp" } },
	{ top = Color3.fromRGB(150, 40, 36), topMaterial = Enum.Material.Wood, body = Color3.fromRGB(118, 28, 28), trim = GOLD, extras = { "Knobs", "Lamp", "Plaque", "Trophy", "Sparkles" } },
}

local HIDE_WHEN_PANELLED = { Leg = true, Pedestal = true }

local function piece(desk: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Studs -- studded like the rest of the map
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("DeskTierPart", true)
	p.Parent = desk
	return p
end

-- Remembers a part's original look the first time, so tier 1 can put it back.
local function remember(p: BasePart)
	if p:GetAttribute("BaseColor") == nil then
		p:SetAttribute("BaseColor", p.Color)
		p:SetAttribute("BaseMaterial", p.Material.Name)
		p:SetAttribute("BaseTransparency", p.Transparency)
	end
end

local function restore(p: BasePart)
	local color = p:GetAttribute("BaseColor")
	if typeof(color) == "Color3" then
		p.Color = color
		p.Material = (Enum.Material :: any)[p:GetAttribute("BaseMaterial")]
		p.Transparency = p:GetAttribute("BaseTransparency") :: number
	end
end

function DeskLook.apply(desk: Model, tier: number)
	local top = desk:FindFirstChild("Top")
	if not (top and top:IsA("BasePart")) then
		return
	end
	for _, d in desk:GetChildren() do
		if d:GetAttribute("DeskTierPart") then
			d:Destroy()
		end
	end
	local style = STYLES[math.clamp(tier, 1, #STYLES)]
	desk:SetAttribute("DeskTier", tier)

	remember(top)
	restore(top)
	for _, p in desk:GetChildren() do
		if p:IsA("BasePart") and HIDE_WHEN_PANELLED[p.Name] then
			remember(p)
			restore(p)
		end
	end
	if tier <= 1 then
		return
	end

	top.Color = style.top
	top.Material = style.topMaterial
	local size = top.Size
	local base = top.CFrame
	local floorDrop = 0
	-- how far the top sits above the floor: use the hidden legs if there are any, else 3 studs
	for _, p in desk:GetChildren() do
		if p:IsA("BasePart") and HIDE_WHEN_PANELLED[p.Name] then
			floorDrop = math.max(floorDrop, base.Position.Y - (p.Position.Y - p.Size.Y / 2))
			p.Transparency = 1
		end
	end
	if floorDrop == 0 then
		floorDrop = 3
	end
	local height = floorDrop - size.Y / 2
	local body = style.body :: Color3

	-- chunky side pedestals and a front panel facing the client (-Z of the top)
	for _, side in { -1, 1 } do
		piece(desk, "SidePanel", Vector3.new(1.2, height, size.Z - 0.2), base * CFrame.new(side * (size.X / 2 - 0.7), -size.Y / 2 - height / 2, 0), body, Enum.Material.Wood)
	end
	piece(desk, "FrontPanel", Vector3.new(size.X - 2.6, height - 0.6, 0.3), base * CFrame.new(0, -size.Y / 2 - (height - 0.6) / 2, -size.Z / 2 + 0.3), body, Enum.Material.Wood)

	if style.trim then
		piece(desk, "Trim", Vector3.new(size.X + 0.1, 0.18, 0.15), base * CFrame.new(0, 0, -size.Z / 2 - 0.05), style.trim, Enum.Material.Metal)
		piece(desk, "Trim", Vector3.new(size.X + 0.1, 0.18, 0.15), base * CFrame.new(0, 0, size.Z / 2 + 0.05), style.trim, Enum.Material.Metal)
	end

	local onTop = base * CFrame.new(0, size.Y / 2, 0)
	for _, extra in style.extras do
		if extra == "Knobs" then
			for _, side in { -1, 1 } do
				for _, y in { 0.35, 0.65 } do
					piece(desk, "Knob", Vector3.new(0.35, 0.35, 0.35), base * CFrame.new(side * (size.X / 2 - 0.7), -size.Y / 2 - height * y, -size.Z / 2 + 0.05), style.trim or Color3.fromRGB(255, 230, 150), Enum.Material.Metal).Shape = Enum.PartType.Ball
				end
			end
		elseif extra == "Lamp" then
			-- cartoon banker's lamp
			local at = onTop * CFrame.new(-size.X / 2 + 1.1, 0, size.Z / 2 - 0.9)
			piece(desk, "LampBase", Vector3.new(0.8, 0.2, 0.8), at * CFrame.new(0, 0.1, 0), GOLD, Enum.Material.Metal)
			piece(desk, "LampStem", Vector3.new(0.18, 1.1, 0.18), at * CFrame.new(0, 0.75, 0), GOLD, Enum.Material.Metal)
			local shade = piece(desk, "LampShade", Vector3.new(1.4, 0.45, 0.7), at * CFrame.new(0, 1.4, 0), Color3.fromRGB(40, 170, 90), Enum.Material.Glass)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 225, 160)
			light.Range = 8
			light.Brightness = 0.8
			light.Shadows = false
			light.Parent = shade
		elseif extra == "Plaque" then
			local plaque = piece(desk, "Plaque", Vector3.new(2.6, 0.6, 0.3), onTop * CFrame.new(0, 0.3, -size.Z / 2 + 0.35), GOLD, Enum.Material.Metal)
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Front
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 60
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(110, 30, 30)
			label.Text = "PARTNER"
			label.Parent = gui
			gui.Parent = plaque
		elseif extra == "Trophy" then
			local at = onTop * CFrame.new(size.X / 2 - 1, 0, size.Z / 2 - 0.9)
			piece(desk, "TrophyBase", Vector3.new(0.9, 0.3, 0.9), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(60, 40, 30), Enum.Material.Wood)
			piece(desk, "TrophyStem", Vector3.new(0.25, 0.6, 0.25), at * CFrame.new(0, 0.6, 0), GOLD, Enum.Material.Metal)
			local cup = piece(desk, "TrophyCup", Vector3.new(0.9, 0.9, 0.9), at * CFrame.new(0, 1.3, 0), GOLD, Enum.Material.Metal)
			cup.Shape = Enum.PartType.Ball
			cup.Reflectance = 0.2
		elseif extra == "Sparkles" then
			for _, emitter in require(game:GetService("ReplicatedStorage").Shared.Effects).ambient(top, "star", GOLD, 0.6) do
				emitter:SetAttribute("DeskTierPart", true)
			end
		end
	end
end

-- One-off celebration burst when a desk is upgraded.
function DeskLook.celebrate(desk: Model)
	local top = desk:FindFirstChild("Top")
	if not (top and top:IsA("BasePart")) then
		return
	end
	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Lifetime = NumberRange.new(0.6, 1.2)
	burst.Speed = NumberRange.new(8, 14)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	burst.LightEmission = 0.8
	burst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)),
	})
	burst.Parent = top
	burst:Emit(60)
	task.delay(2, function()
		burst:Destroy()
	end)
end

return DeskLook
