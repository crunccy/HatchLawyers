-- Hub revamp asset library, modelled in Blender (HubAssets collection, 1 unit = 1 stud, asset front = -Y)
-- and rebuilt here from primitives. HubAssetLibrary.build(name, cframe, parent, labels?) places one asset with
-- its floor-level centre at `cframe` (front of the asset = cframe.LookVector).
local HttpService = game:GetService("HttpService")

local SPEC = HttpService:JSONDecode([==[
{"GateArch": [{"n": "PillarBase", "k": "box", "p": [-10, 0, 0.5], "s": [3.2, 3.2, 1], "m": "Gold"}, {"n": "Pillar", "k": "box", "p": [-10, 0, 6], "s": [2.4, 2.4, 10], "m": "White"}, {"n": "PillarCap", "k": "box", "p": [-10, 0, 11.5], "s": [3.0, 3.0, 1], "m": "Gold"}, {"n": "Lantern", "k": "box", "p": [-10, 0, 12.9], "s": [1.6, 1.6, 1.8], "m": "Glow"}, {"n": "PillarBase", "k": "box", "p": [10, 0, 0.5], "s": [3.2, 3.2, 1], "m": "Gold"}, {"n": "Pillar", "k": "box", "p": [10, 0, 6], "s": [2.4, 2.4, 10], "m": "White"}, {"n": "PillarCap", "k": "box", "p": [10, 0, 11.5], "s": [3.0, 3.0, 1], "m": "Gold"}, {"n": "Lantern", "k": "box", "p": [10, 0, 12.9], "s": [1.6, 1.6, 1.8], "m": "Glow"}, {"n": "Beam", "k": "box", "p": [0, 0, 12.4], "s": [23, 2, 1.6], "m": "White"}, {"n": "SignTrim", "k": "box", "p": [0, -0.9, 15.2], "s": [19, 0.4, 5.4], "m": "Gold"}, {"n": "Sign", "k": "box", "p": [0, -1.25, 15.2], "s": [18, 0.5, 4.6], "m": "Sienna"}], "ShopPad": [{"n": "Base", "k": "box", "p": [0, 0, 0.5], "s": [28, 22, 1], "m": "White"}, {"n": "Inset", "k": "box", "p": [0, 0, 1.05], "s": [25, 19, 0.1], "m": "ShopBlue"}, {"n": "FrontStep", "k": "box", "p": [0, -11.75, 0.25], "s": [14, 1.5, 0.5], "m": "White"}, {"n": "Post", "k": "box", "p": [-13.5, -10.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-13.5, -10.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [-13.5, 10.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-13.5, 10.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [13.5, -10.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [13.5, -10.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [13.5, 10.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [13.5, 10.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "SignPost", "k": "box", "p": [-8.5, -12.6, 2.6], "s": [0.6, 0.6, 5.2], "m": "Sienna"}, {"n": "Sign", "k": "box", "p": [-8.5, -12.95, 5.7], "s": [9, 0.5, 3.4], "m": "Sienna"}], "MergePad": [{"n": "Base", "k": "box", "p": [0, 0, 0.5], "s": [32, 26, 1], "m": "White"}, {"n": "Inset", "k": "box", "p": [0, 0, 1.05], "s": [29, 23, 0.1], "m": "MergePurple"}, {"n": "FrontStep", "k": "box", "p": [0, -13.75, 0.25], "s": [14, 1.5, 0.5], "m": "White"}, {"n": "Post", "k": "box", "p": [-15.5, -12.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-15.5, -12.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [-15.5, 12.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-15.5, 12.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [15.5, -12.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [15.5, -12.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [15.5, 12.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [15.5, 12.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "SignPost", "k": "box", "p": [-10.5, -14.6, 2.6], "s": [0.6, 0.6, 5.2], "m": "Sienna"}, {"n": "Sign", "k": "box", "p": [-10.5, -14.95, 5.7], "s": [9, 0.5, 3.4], "m": "Sienna"}, {"n": "Ring", "k": "cylz", "p": [0, 0, 1.14], "s": [20, 20, 0.08], "m": "Gold"}, {"n": "Disc", "k": "cylz", "p": [0, 0, 1.2], "s": [18, 18, 0.1], "m": "MergeLight"}], "SpecialPad": [{"n": "Base", "k": "box", "p": [0, 0, 0.5], "s": [20, 20, 1], "m": "White"}, {"n": "Inset", "k": "box", "p": [0, 0, 1.05], "s": [17, 17, 0.1], "m": "SpecialGreen"}, {"n": "FrontStep", "k": "box", "p": [0, -10.75, 0.25], "s": [14, 1.5, 0.5], "m": "White"}, {"n": "Post", "k": "box", "p": [-9.5, -9.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-9.5, -9.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [-9.5, 9.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [-9.5, 9.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [9.5, -9.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [9.5, -9.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "Post", "k": "box", "p": [9.5, 9.5, 3], "s": [1, 1, 4], "m": "Gold"}, {"n": "PostCap", "k": "box", "p": [9.5, 9.5, 5.3], "s": [1.4, 1.4, 0.6], "m": "Gold"}, {"n": "SignPost", "k": "box", "p": [-4.5, -11.6, 2.6], "s": [0.6, 0.6, 5.2], "m": "Sienna"}, {"n": "Sign", "k": "box", "p": [-4.5, -11.95, 5.7], "s": [9, 0.5, 3.4], "m": "Sienna"}], "LampPost": [{"n": "Base", "k": "box", "p": [0, 0, 0.3], "s": [1.8, 1.8, 0.6], "m": "Dark"}, {"n": "Pole", "k": "box", "p": [0, 0, 4.8], "s": [0.7, 0.7, 8.4], "m": "Dark"}, {"n": "Lantern", "k": "box", "p": [0, 0, 10], "s": [1.8, 1.8, 2], "m": "Glow"}, {"n": "Cap", "k": "box", "p": [0, 0, 11.25], "s": [2.4, 2.4, 0.5], "m": "Dark"}]}
]==])

local LOOK = {
	White        = { Color3.fromRGB(242, 243, 243), Enum.Material.Plastic },
	Gold         = { Color3.fromRGB(245, 180, 30),  Enum.Material.Metal },
	Sienna       = { Color3.fromRGB(143, 76, 42),   Enum.Material.Plastic },
	ShopBlue     = { Color3.fromRGB(70, 160, 240),  Enum.Material.Plastic },
	MergePurple  = { Color3.fromRGB(150, 90, 240),  Enum.Material.Plastic },
	MergeLight   = { Color3.fromRGB(215, 190, 255), Enum.Material.Neon },
	SpecialGreen = { Color3.fromRGB(75, 200, 120),  Enum.Material.Plastic },
	Dark         = { Color3.fromRGB(45, 47, 55),    Enum.Material.Metal },
	Glow         = { Color3.fromRGB(255, 214, 130), Enum.Material.Neon },
}

local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local Library = { SPEC = SPEC, LOOK = LOOK }

-- a sign face like the egg pads' signs: white title + gold subtitle (FredokaOne)
function Library.label(part: BasePart, title: string, subtitle: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local function text(t, y, h, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(0.92, h)
		l.Position = UDim2.fromScale(0.04, y)
		l.Text = t
		l.TextScaled = true
		l.FontFace = FONT
		l.TextColor3 = color
		l.Parent = gui
	end
	if subtitle then
		text(title, 0.06, 0.56, Color3.new(1, 1, 1))
		text(subtitle, 0.62, 0.32, Color3.fromRGB(255, 205, 60))
	else
		text(title, 0.12, 0.76, Color3.new(1, 1, 1))
	end
end

function Library.build(name: string, cf: CFrame, parent: Instance, labels: { [string]: { string } }?): Model
	local model = Instance.new("Model")
	model.Name = name
	for _, s in SPEC[name] do
		local p = Instance.new("Part")
		p.Name = s.n
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Color, p.Material = LOOK[s.m][1], LOOK[s.m][2]
		-- Blender (x, y, z) z-up, front -Y  ->  Roblox local (x, z, y), front -Z
		local pos = Vector3.new(s.p[1], s.p[3], s.p[2])
		if s.k == "cylz" then
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(s.s[3], s.s[1], s.s[2])
			p.CFrame = cf * CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		else
			p.Size = Vector3.new(s.s[1], s.s[3], s.s[2])
			p.CFrame = cf * CFrame.new(pos)
		end
		if s.m == "Glow" then
			p.CastShadow = false
			local light = Instance.new("PointLight")
			light.Color = LOOK.Glow[1]
			light.Brightness = 1.5
			light.Range = 14
			light.Parent = p
		end
		p.Parent = model
		local text = labels and labels[s.n]
		if text then
			Library.label(p, text[1], text[2])
		end
	end
	model.WorldPivot = cf
	model.Parent = parent
	return model
end

return Library
