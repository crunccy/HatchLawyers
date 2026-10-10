-- Cappuccino Assassino (Legendary, Brainrot egg; id CappuccinoAvvocato) - block remake 2026-10-10.
-- Reference (Wikimedia "Cappucino_assasino.webp"): a takeaway coffee cup ninja - cream cup widening to the top,
-- brown sleeve band across the middle (the "mask"), dark headband with a metal plate, cream lid rim, black lid with a
-- curly sip tab, headband tails flying to one side, huge round eyes + angry brows, thin black stick arms holding a
-- katana each, thin black legs, chunky sneakers. Front-facing. Legendary: gold katana guards/wraps + gold emblem
-- (a coffee bean - not the reference's leaf symbol), 1.2x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("CappuccinoAvvocato")
local V = Vector3.new
local C = Kit.C
local CREAM, CREAM_LIGHT = Color3.fromHex("f1e1c4"), Color3.fromHex("f8eedb")
local SLEEVE, BAND = Color3.fromHex("6b4426"), Color3.fromHex("3b2416")
local BLACK, STEEL, STEEL_DARK = Color3.fromHex("1c1c20"), Color3.fromHex("c3c9d2"), Color3.fromHex("8a929e")
local SHOE, SOLE = Color3.fromHex("4a2c18"), Color3.fromHex("f5f5f5")
local T, H = "UpperTorso", "Head"

-- the cup, widening upward (front face at z = -depth/2)
local rows = { -- y centre, height, width, depth, colour
	{ 1.32, 0.64, 1.70, 1.50, CREAM },
	{ 1.96, 0.64, 1.80, 1.58, CREAM },
	{ 2.62, 0.68, 1.98, 1.72, SLEEVE },      -- sleeve band (the ninja mask), sticks out a little
	{ 3.27, 0.62, 1.96, 1.66, CREAM },
	{ 3.80, 0.44, 2.04, 1.72, CREAM },
}
for _, r in rows do
	b:B(T, V(r[3], r[2], r[4]), V(0, r[1], 0), r[5])
end
b:B(T, V(2.0, 0.06, 1.74), V(0, 2.95, 0), Color3.fromHex("54331b"))     -- sleeve top seam
b:B(T, V(2.0, 0.06, 1.74), V(0, 2.29, 0), Color3.fromHex("54331b"))     -- sleeve bottom seam
-- headband + metal plate with a gold coffee-bean emblem
b:B(H, V(2.12, 0.46, 1.8), V(0, 4.25, 0), BAND)
b:B("HeadDetail", V(0.78, 0.34, 0.06), V(0, 4.25, -0.92), STEEL)
b:B("HeadDetail", V(0.8, 0.05, 0.07), V(0, 4.43, -0.92), STEEL_DARK)
b:B("HeadDetail", V(0.8, 0.05, 0.07), V(0, 4.07, -0.92), STEEL_DARK)
b:B("HeadDetail", V(0.24, 0.18, 0.05), V(0, 4.25, -0.96), C.Gold, nil, nil, Enum.PartType.Ball)
b:B("HeadDetail", V(0.03, 0.16, 0.04), V(0, 4.25, -0.99), C.GoldDark)
-- headband knot + two tails flying out to the right
b:B(H, V(0.3, 0.3, 0.3), V(1.1, 4.25, 0.45), BAND)
b:B(H, V(0.75, 0.16, 0.12), V(1.55, 4.05, 0.62), BAND, V(0, -20, -25))
b:B(H, V(0.65, 0.14, 0.12), V(1.5, 3.82, 0.7), BAND, V(0, -25, -45))
-- lid: cream rim, black top, curly sip tab
b:B(H, V(2.3, 0.24, 1.94), V(0, 4.6, 0), CREAM_LIGHT)
b:B(H, V(2.16, 0.22, 1.84), V(0, 4.83, 0), BLACK)
b:B(H, V(1.9, 0.08, 1.6), V(0, 4.97, 0), Color3.fromHex("2b2b31"))
b:B(H, V(0.22, 0.42, 0.22), V(0.7, 5.15, 0.3), BLACK)
b:B(H, V(0.36, 0.18, 0.22), V(0.85, 5.38, 0.3), BLACK)
b:B(H, V(0.18, 0.18, 0.22), V(1.0, 5.25, 0.3), BLACK)
-- the face: huge round eyes, angry brows (no mouth - the sleeve is the mask)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.45, 3.4, -0.86), 0.62, V(0, 0, -1), Vector2.new(-0.06 * s, 0.0))
	b:brow(V(s * 0.45, 3.82, -0.88), 0.66, V(0, 0, -1), s * 16)   -- angry: inner ends down
end
-- arms: thin black sticks, black fists, a katana each (steel blade, gold guard, black handle with gold wrap)
local function katana(grip: CFrame, side: number)
	b:BAt("RightUpperArm", V(0.28, 0.28, 0.28), grip, BLACK)                                         -- fist
	b:BAt("RightUpperArm", V(0.14, 0.55, 0.14), grip * CFrame.new(0, -0.18, 0), BLACK)              -- handle
	for i = 0, 2 do
		b:BAt("RightUpperArm", V(0.16, 0.05, 0.16), grip * CFrame.new(0, -0.05 - i * 0.14, 0), C.Gold) -- wrap
	end
	b:BAt("RightUpperArm", V(0.4, 0.06, 0.4), grip * CFrame.new(0, 0.2, 0), C.Gold)                 -- guard
	b:BAt("RightUpperArm", V(0.07, 2.0, 0.2), grip * CFrame.new(0, 1.24, 0), STEEL)                 -- blade
	b:BAt("RightUpperArm", V(0.075, 2.0, 0.05), grip * CFrame.new(0, 1.24, 0.08), STEEL_DARK)       -- spine
	b:BAt("RightUpperArm", V(0.07, 0.22, 0.14), grip * CFrame.new(0, 2.32, -0.03) * CFrame.Angles(math.rad(30), 0, 0), STEEL) -- tip
end
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	local shoulder = V(s * 1.0, 2.75, 0)
	-- upper + lower arm hanging out and down to the fist
	b:B(name, V(0.14, 0.62, 0.14), shoulder + V(s * 0.22, -0.25, 0), BLACK, V(0, 0, s * 40))
	b:B(name, V(0.14, 0.55, 0.14), shoulder + V(s * 0.48, -0.68, -0.12), BLACK, V(-20, 0, s * 10))
	local grip = CFrame.new(shoulder + V(s * 0.55, -1.0, -0.22))
	-- held low, both blades raised up and outward (like the reference)
	katana(grip * CFrame.Angles(math.rad(-12), 0, math.rad(-s * 38)), s)
end
-- legs + chunky sneakers
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.16, 0.85, 0.16), V(s * 0.45, 0.72, 0), BLACK)
	b:B(name, V(0.62, 0.12, 0.85), V(s * 0.48, 0.06, -0.1), SOLE)
	b:B(name, V(0.56, 0.3, 0.78), V(s * 0.48, 0.26, -0.1), SHOE)
	b:B(name, V(0.5, 0.12, 0.34), V(s * 0.48, 0.44, 0.1), SHOE)
	b:B(name, V(0.3, 0.05, 0.28), V(s * 0.48, 0.42, -0.25), SOLE)                                  -- laces
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.2)
print(b:preview())
_G.SkinBuild = b
