--!strict
-- The game's typography, in one place (bold Roblox-simulator style, young audience):
--   Primary  FredokaOne        buttons, headings, menus, HUD, money (big + outlined)
--   Title    LuckiestGuy       big moments only: hatch reveals, WIN!, merges, rewards, unlocks
--   Body     BuilderSansMedium descriptions and small print (readable at small sizes)
-- Important text gets a thick black outline (UIFonts.outline). Use these instead of naming fonts in scripts.

local UIFonts = {}

UIFonts.Primary = Enum.Font.FredokaOne
UIFonts.Title = Enum.Font.LuckiestGuy
UIFonts.Body = Enum.Font.BuilderSansMedium

-- FontFace versions (for scripts that use FontFace)
UIFonts.PrimaryFace = Font.fromEnum(Enum.Font.FredokaOne)
UIFonts.TitleFace = Font.fromEnum(Enum.Font.LuckiestGuy)
UIFonts.BodyFace = Font.fromEnum(Enum.Font.BuilderSansMedium)

-- Thick black rounded outline on a text object (adds or updates its UIStroke).
function UIFonts.outline(label: TextLabel | TextButton, thickness: number?): UIStroke
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = label
	end
	local s = stroke :: UIStroke
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = thickness or 3
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	return s
end

-- Big-moment text: LuckiestGuy + outline.
function UIFonts.title(label: TextLabel | TextButton, thickness: number?)
	label.Font = UIFonts.Title
	UIFonts.outline(label, thickness or 4)
end

-- Description / small print: BuilderSansMedium (no outline on light panels).
function UIFonts.body(label: TextLabel | TextButton)
	label.Font = UIFonts.Body
end

return UIFonts
