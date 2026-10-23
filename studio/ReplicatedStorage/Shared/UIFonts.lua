--!strict
-- The game's typography, in one place. v3 (crnuch's call 2026-10-23, docs/UI_STYLE_V3.md): ONE family, the one in
-- crnuch's reference video's UI - Gotham Black for everything big (buttons, headings, menus, HUD, money, big
-- moments), Gotham Bold for descriptions and small print. No Fredoka / Luckiest Guy / Builder Sans anywhere;
-- StarterPlayerScripts.Fonts converts any that a script still sets.
--   Primary  GothamBlack  buttons, headings, menus, HUD, money (big + outlined)
--   Title    GothamBlack  big moments: hatch reveals, WIN!, merges, rewards, unlocks
--   Body     GothamBold   descriptions and small print
-- Important text gets a thick black outline (UIFonts.outline). Use these instead of naming fonts in scripts.

local UIFonts = {}

UIFonts.Primary = Enum.Font.GothamBlack
UIFonts.Title = Enum.Font.GothamBlack
UIFonts.Body = Enum.Font.GothamBold

-- FontFace versions (for scripts that use FontFace)
UIFonts.PrimaryFace = Font.fromEnum(Enum.Font.GothamBlack)
UIFonts.TitleFace = Font.fromEnum(Enum.Font.GothamBlack)
UIFonts.BodyFace = Font.fromEnum(Enum.Font.GothamBold)

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

-- Big-moment text: Gotham Black + outline.
function UIFonts.title(label: TextLabel | TextButton, thickness: number?)
	label.Font = UIFonts.Title
	UIFonts.outline(label, thickness or 4)
end

-- Description / small print: Gotham Bold (no outline on light panels).
function UIFonts.body(label: TextLabel | TextButton)
	label.Font = UIFonts.Body
end

return UIFonts
