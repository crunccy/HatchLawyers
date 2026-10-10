-- Tung Tung Tung Sahur (Legendary; catalog id PinstripePartner) - block remake 2026-10-10. Reference: the meme
-- image (a tall pale wooden log with big eyes, a long nose and a wide smile, long thin wooden arms and legs, bare
-- wooden feet, a baseball bat). Replaces mr.robe's imported rigged mesh (SkinModels.LawyerSkin_Legendary, kept)
-- with the game's block style. Front-facing. Legendary: tall (1.15x), gold-banded bat, gold eye glints.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("TungTungSahur")
local V = Vector3.new
local C = Kit.C
local WOOD, WOOD_LIGHT, WOOD_DARK, GRAIN = Color3.fromHex("d9a066"), Color3.fromHex("e8b67c"), Color3.fromHex("a8703d"), Color3.fromHex("bb8550")
local BAT, BAT_DARK = Color3.fromHex("c98a4b"), Color3.fromHex("8a5a2e")
local IRIS = Color3.fromHex("5a3518")
local T, H = "UpperTorso", "Head"

-- the log: tall block body with a rounded (stepped) top, wood grain strips, end-grain rings on top
b:B(T, V(1.5, 3.4, 1.2), V(0, 3.5, 0), WOOD)
b:B(H, V(1.36, 0.22, 1.08), V(0, 5.31, 0), WOOD)
b:B(H, V(1.12, 0.14, 0.9), V(0, 5.49, 0), WOOD_LIGHT)
b:B(H, V(0.7, 0.06, 0.56), V(0, 5.57, 0), GRAIN)
b:B(H, V(0.32, 0.07, 0.26), V(0, 5.59, 0), WOOD_LIGHT)
for _, g in { { -0.5, 2.3, 1.1 }, { 0.35, 2.9, 1.6 }, { 0.6, 1.9, 0.7 }, { -0.25, 4.5, 0.9 } } do
	b:B(T, V(0.08, g[3], 0.04), V(g[1], g[2], -0.61), GRAIN)                  -- grain lines on the front
end
b:B(T, V(0.3, 0.2, 0.04), V(0.42, 2.25, -0.61), WOOD_DARK)                   -- a knot
b:B(T, V(1.52, 0.1, 1.22), V(0, 1.85, 0), WOOD_DARK)                         -- a darker band low on the log
for _, sx in { -1, 1 } do                                                         -- bark strips down the sides
	b:B(T, V(0.05, 2.6, 0.22), V(sx * 0.76, 3.3, -0.25), WOOD_DARK)
	b:B(T, V(0.05, 1.8, 0.18), V(sx * 0.76, 3.6, 0.3), GRAIN)
end
b:B(T, V(0.22, 0.26, 0.04), V(-0.42, 4.95, -0.61), WOOD_DARK)                  -- another knot, up by the brow
-- face: big eyes with brown irises, thick brows, long nose, wide smile
for _, s in { -1, 1 } do
	b:eye(V(s * 0.36, 4.45, -0.62), 0.5, V(0, 0, -1), Vector2.new(0, -0.02), IRIS)
	b:brow(V(s * 0.38, 4.85, -0.63), 0.5, V(0, 0, -1), s * -8, WOOD_DARK)
end
b:B(H, V(0.22, 0.5, 0.3), V(0, 4.1, -0.75), WOOD_LIGHT)                       -- nose
b:B(H, V(0.24, 0.16, 0.36), V(0, 3.83, -0.78), WOOD_LIGHT)
b:mouth(V(0, 3.45, -0.62), 0.8, 0.2, V(0, 0, -1), 0, 22)                      -- wide smile
-- arms: long thin wooden sticks; the right hand holds the bat up over the shoulder
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.24, 1.2, 0.24), V(s * 0.92, 3.9, 0), WOOD, V(0, 0, s * 18))
	b:B(name, V(0.22, 1.1, 0.22), V(s * 1.12, 2.85, -0.15), WOOD, V(-15, 0, s * 6))
	b:B(name, V(0.32, 0.3, 0.3), V(s * 1.18, 2.25, -0.25), WOOD_LIGHT)         -- hand
	if s > 0 then
		b:B(name, V(0.3, 0.12, 0.3), V(s * 1.16, 2.47, -0.2), C.Gold)            -- gold wristband (bat hand)
	end
end
-- the bat, held in the right hand, swung up behind the shoulder; gold bands (Legendary)
local grip = CFrame.new(V(1.18, 2.25, -0.25)) * CFrame.Angles(math.rad(-10), 0, math.rad(-28))
b:BAt("RightUpperArm", V(0.16, 0.7, 0.16), grip * CFrame.new(0, 0.2, 0), BAT_DARK)              -- handle
b:BAt("RightUpperArm", V(0.28, 0.1, 0.28), grip * CFrame.new(0, -0.18, 0), C.Gold)            -- gold knob
b:BAt("RightUpperArm", V(0.28, 0.9, 0.28), grip * CFrame.new(0, 0.95, 0), BAT)
b:BAt("RightUpperArm", V(0.4, 1.25, 0.4), grip * CFrame.new(0, 2.0, 0), BAT)                   -- big barrel
b:BAt("RightUpperArm", V(0.08, 1.1, 0.03), grip * CFrame.new(0.1, 2.0, -0.21), BAT_DARK)       -- grain on the barrel
b:BAt("RightUpperArm", V(0.36, 0.12, 0.36), grip * CFrame.new(0, 2.68, 0), BAT_DARK)
for _, y in { 0.55, 1.4, 2.55 } do
	b:BAt("RightUpperArm", V(0.27, 0.07, 0.27), grip * CFrame.new(0, y, 0), C.Gold)            -- gold bands
end
-- legs + bare wooden feet with toes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.26, 1.1, 0.26), V(s * 0.38, 1.25, 0), WOOD)
	b:B(name, V(0.24, 0.6, 0.24), V(s * 0.38, 0.45, 0), WOOD)
	b:B(name, V(0.5, 0.18, 0.7), V(s * 0.4, 0.09, -0.15), WOOD_LIGHT)            -- foot
	for t = -1, 1 do
		b:B(name, V(0.13, 0.12, 0.13), V(s * 0.4 + t * 0.15, 0.13, -0.53), WOOD_LIGHT) -- toes
	end
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.15)
print(b:preview())
_G.SkinBuild = b
