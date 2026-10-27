--!strict
-- Dresses a desk model for its tier (Config.Desks.Tiers), in the game's chunky cartoon style.
-- v2 (2026-10-16, crnuch's bug report 7): tiers used to bolt side panels, knobs, a lamp and a trophy onto an older
-- desk that faced the other way, so on the kit desk (FirmBuilder: ServerStorage.Templates.FirmKitParts.LawyerDesk)
-- they cut through its pedestals, laptop, mug and lamp. Now a tier RECOLOURS the kit desk's own parts and adds only
-- a few pieces in the free spots of its top. Desk frame (= FirmBuilder.slotFrame): +X faces the client / the aisle,
-- the lawyer stands at -X, the long side runs along Z; the kit's top is 2.8 x 0.45 x 5.6 with its surface at y 2.645.
-- Kit parts are told apart by size (they are all called "Part"). Tier 1 restores the original look; calling it again
-- swaps tiers cleanly.

local DeskLook = {}

type Style = {
	top: Color3?, -- nil keeps the original look (tier 1)
	body: Color3?, -- pedestals, modesty panel, front strip
	handle: Color3?,
	trim: Color3?, -- gold band around the top's edge
	extras: { string },
}

local GOLD = Color3.fromRGB(255, 205, 60)

local STYLES: { Style } = {
	{ extras = {} }, -- tier 1: the kit desk as it is
	{ top = Color3.fromRGB(205, 140, 72), body = Color3.fromRGB(176, 110, 52), handle = Color3.fromRGB(255, 230, 150), extras = {} },
	{ top = Color3.fromRGB(112, 68, 42), body = Color3.fromRGB(92, 54, 34), handle = GOLD, trim = GOLD, extras = { "Lamp" } },
	{ top = Color3.fromRGB(150, 40, 36), body = Color3.fromRGB(118, 28, 28), handle = GOLD, trim = GOLD, extras = { "Lamp", "Plaque", "Trophy", "Sparkles" } },
}

local TOP_Y = 2.645 -- the kit desk's top surface, desk frame
local SLOT_TO_TOP = CFrame.new(-0.05, 2.45, 0) -- where FirmBuilder puts the Top marker in the desk frame

-- kit part roles by size (rounded to 0.05)
local function key(s: Vector3): string
	local function r(v: number): number
		return math.floor(v * 20 + 0.5)
	end
	return r(s.X) .. "," .. r(s.Y) .. "," .. r(s.Z)
end
local ROLES: { [string]: string } = {
	[key(Vector3.new(2.8, 0.45, 5.6))] = "top",
	[key(Vector3.new(2.3, 2.2, 1.5))] = "body", -- the two drawer pedestals
	[key(Vector3.new(0.3, 1.7, 2.0))] = "body", -- modesty panel (client side)
	[key(Vector3.new(0.1, 0.3, 1.8))] = "strip", -- the strip on the top's client edge
	[key(Vector3.new(0.15, 0.2, 0.6))] = "handle",
	[key(Vector3.new(0.5, 0.15, 0.5))] = "lampMetal", -- the kit's desk lamp: base, stem, shade
	[key(Vector3.new(0.1, 1.0, 0.1))] = "lampMetal",
	[key(Vector3.new(0.8, 0.45, 0.7))] = "lampShade",
}
-- the overhaul desk (2026-10-26, ServerStorage.Overhaul.Models.hall.hall_desk) is named per colour, so by NAME; it has
-- its own gold trim (Desk_Trim), so tiers don't add the band
local NAME_ROLES: { [string]: string } = {
	Desk_Top = "top",
	Desk_Body = "body",
	Desk_Drawer = "body",
	Desk_Front = "strip",
	Desk_Handle = "handle",
	Desk_Lamp = "lampMetal",
	Desk_LampShade = "lampShade",
	Desk_Plate = "plate", -- the brass name plate: the PARTNER plaque takes its place
}

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
	for _, d in desk:GetDescendants() do
		if d:GetAttribute("DeskTierPart") then
			d:Destroy()
		end
	end
	local style = STYLES[math.clamp(tier, 1, #STYLES)]
	desk:SetAttribute("DeskTier", tier)

	-- the kit desk's own parts, by role; each goes back to its original look first
	local parts: { [string]: { BasePart } } = {}
	local kit = desk:FindFirstChild("DeskMesh")
	local meshDesk = kit ~= nil and kit:FindFirstChild("Desk_Top") ~= nil
	if kit then
		for _, p in kit:GetDescendants() do
			if p:IsA("BasePart") then
				local role = NAME_ROLES[p.Name] or ROLES[key(p.Size)]
				if role then
					remember(p)
					restore(p)
					parts[role] = parts[role] or {}
					table.insert(parts[role], p)
				end
			end
		end
	end
	local function paint(role: string, color: Color3?, material: Enum.Material?)
		if color then
			for _, p in parts[role] or {} do
				p.Color = color
				if material then
					p.Material = material
				end
			end
		end
	end
	if tier <= 1 then
		return
	end

	paint("top", style.top)
	paint("body", style.body)
	paint("handle", style.handle, Enum.Material.Metal)
	paint("strip", style.trim or style.body, if style.trim then Enum.Material.Metal else nil)

	local base = top.CFrame * SLOT_TO_TOP:Inverse() -- the desk frame
	if style.trim and not meshDesk then
		-- a band around the top's edge, wrapping the top and the front strip (x 1.4..1.5): every face of it stays 0.05+
		-- away from theirs, so nothing flickers
		piece(desk, "Trim", Vector3.new(3.1, 0.14, 5.7), base * CFrame.new(0, 2.42, 0), style.trim, Enum.Material.Metal)
	end

	for _, extra in style.extras do
		if extra == "Lamp" then
			-- the kit's desk lamp becomes a banker's lamp (green shade, gold stand) and lights up
			paint("lampMetal", GOLD, Enum.Material.Metal)
			paint("lampShade", Color3.fromRGB(40, 170, 90))
			local shade = (parts.lampShade or {})[1]
			if shade then
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 225, 160)
				light.Range = 7
				light.Brightness = 0.6
				light.Shadows = false
				light:SetAttribute("DeskTierPart", true)
				light.Parent = shade
			end
		elseif extra == "Plaque" then
			-- standing on the client edge, facing the client: clear of the keyboard, laptop and lamp (on the overhaul
			-- desk: in place of its name plate, mid-edge)
			for _, p in parts.plate or {} do
				p.Transparency = 1
			end
			local plaque = piece(desk, "Plaque", Vector3.new(2.2, 0.6, 0.25),
				base * CFrame.new(1.05, TOP_Y + 0.3, if meshDesk then 0 else -0.75) * CFrame.Angles(0, -math.pi / 2, 0), GOLD, Enum.Material.Metal)
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
			-- the lawyer's far corner, past the laptop (the overhaul desk has its mug there: the client's far corner)
			local at = base * (if meshDesk then CFrame.new(0.85, TOP_Y, 2.1) else CFrame.new(-0.85, TOP_Y, 2.25))
			piece(desk, "TrophyBase", Vector3.new(0.9, 0.3, 0.9), at * CFrame.new(0, 0.15, 0), Color3.fromRGB(60, 40, 30))
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
