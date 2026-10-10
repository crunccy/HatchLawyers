-- Navy Power Suit (Uncommon) - block remake 2026-10-10. A tall, broad-shouldered power lawyer: a V-shaped navy suit
-- with big shoulder pads, a red power tie, slicked-back hair, dark sunglasses, a confident smirk, a coffee cup in one
-- hand and a phone at the hip. Front-facing. Uncommon: 1-2 props, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("NavyPowerSuit")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_DARK, PANTS, TIE = Color3.fromRGB(40, 75, 170), Color3.fromHex("1f3c8a"), Color3.fromRGB(25, 35, 85), Color3.fromRGB(235, 45, 60)
local SKIN, HAIR, SHADES, CUP = Color3.fromHex("e8b48a"), Color3.fromHex("2a1c14"), Color3.fromRGB(20, 20, 24), Color3.fromHex("f5f5f5")
local T, H = "UpperTorso", "Head"

-- long legs, sharp shoes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.45, 1.8, 0.5), V(s * 0.27, 1.2, 0), PANTS)
	b:B(name, V(0.5, 0.24, 0.85), V(s * 0.27, 0.12, -0.15), C.Line)
end
-- V-shaped torso: narrow waist, wide padded shoulders, white shirt, red tie, lapels, pocket square
b:B(T, V(1.3, 0.8, 0.8), V(0, 2.5, 0), SUIT)
b:B(T, V(2.0, 0.9, 0.85), V(0, 3.3, 0), SUIT)
b:B(T, V(2.1, 0.25, 0.9), V(0, 3.68, 0), SUIT_DARK) -- shoulder pads
b:B("HeadDetail", V(0.45, 1.3, 0.05), V(0, 3.0, -0.44), C.White)
b:B("HeadDetail", V(0.18, 1.1, 0.04), V(0, 2.95, -0.47), TIE)
b:B("HeadDetail", V(0.24, 0.14, 0.04), V(0, 3.52, -0.47), TIE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.18, 1.1, 0.05), V(s * 0.35, 3.1, -0.45), SUIT_DARK, V(0, 0, s * 18))
end
b:B("HeadDetail", V(0.25, 0.14, 0.05), V(0.65, 3.35, -0.45), TIE) -- pocket square
-- arms: -X holds a coffee cup up, +X down with a phone
b:B("LeftUpperArm", V(0.45, 0.9, 0.5), V(-1.2, 3.1, 0), SUIT)
b:B("LeftUpperArm", V(0.42, 0.8, 0.45), V(-1.25, 2.85, -0.4), SUIT, V(70, 0, 0))
b:B("LeftUpperArm", V(0.36, 0.34, 0.36), V(-1.25, 2.95, -0.85), SKIN)
b:B("LeftUpperArm", V(0.32, 0.5, 0.32), V(-1.25, 3.3, -0.85), CUP)
b:B("LeftUpperArm", V(0.34, 0.12, 0.34), V(-1.25, 3.5, -0.85), Color3.fromHex("6b4426")) -- lid
b:B("LeftUpperArm", V(0.34, 0.16, 0.34), V(-1.25, 3.22, -0.85), Color3.fromHex("c8a06a")) -- sleeve
b:B("RightUpperArm", V(0.45, 1.5, 0.5), V(1.2, 2.85, 0), SUIT)
b:B("RightUpperArm", V(0.36, 0.34, 0.4), V(1.2, 1.95, 0), SKIN)
b:B("RightUpperArm", V(0.08, 0.5, 0.3), V(1.42, 1.95, -0.05), SHADES)
-- head: slicked-back hair, sunglasses, smirk
b:B(H, V(1.1, 1.15, 1.0), V(0, 4.35, 0), SKIN)
b:B(H, V(1.16, 0.3, 1.06), V(0, 4.98, 0.03), HAIR)
b:B(H, V(1.16, 0.7, 0.3), V(0, 4.65, 0.4), HAIR)
b:B(H, V(1.0, 0.12, 0.3), V(0, 5.12, 0.15), HAIR)
b:B(H, V(1.14, 0.3, 0.06), V(0, 4.48, -0.53), SHADES)
b:B(H, V(0.14, 0.06, 0.05), V(-0.3, 4.55, -0.57), Color3.fromHex("8a8a9a")) -- glint
for _, s in { -1, 1 } do
	b:B(H, V(0.06, 0.12, 0.9), V(s * 0.56, 4.5, -0.05), SHADES)
end
b:mouth(V(0.1, 4.05, -0.51), 0.34, 0.08, V(0, 0, -1), 0, 22)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
