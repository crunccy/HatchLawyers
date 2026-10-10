-- Bow Tie Barrister (Uncommon) - block remake 2026-10-10. A short, round, dapper gentleman: a chubby purple tailcoat
-- body on short legs, a HUGE pink bow tie, a tall dark top hat with a pink band, a curly moustache, a monocle, and a
-- cane with a gold knob. Front-facing. Uncommon: 1 prop (cane), 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BowTieBarrister")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_DARK, PANTS, BOW = Color3.fromRGB(130, 70, 200), Color3.fromHex("5e3296"), Color3.fromRGB(55, 35, 90), Color3.fromRGB(255, 80, 170)
local HAT, SKIN, STACHE = Color3.fromRGB(45, 35, 60), Color3.fromHex("f2c8a0"), Color3.fromHex("4a2c18")
local T, H = "UpperTorso", "Head"

-- short legs + shiny shoes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.45, 0.8, 0.5), V(s * 0.33, 0.6, 0), PANTS)
	b:B(name, V(0.5, 0.24, 0.75), V(s * 0.33, 0.12, -0.12), C.Line)
end
-- round tailcoat body: wide middle, tails at the back, white shirt front, buttons
b:B(T, V(1.8, 1.5, 1.2), V(0, 1.75, 0), SUIT)
b:B(T, V(1.5, 1.7, 1.0), V(0, 1.8, 0), SUIT)
b:B(T, V(0.5, 0.9, 0.12), V(-0.35, 0.9, 0.55), SUIT_DARK)
b:B(T, V(0.5, 0.9, 0.12), V(0.35, 0.9, 0.55), SUIT_DARK)
b:B("HeadDetail", V(0.6, 1.2, 0.05), V(0, 1.9, -0.62), C.White)
for _, y in { 1.95, 1.6, 1.25 } do
	b:B("HeadDetail", V(0.1, 0.1, 0.04), V(0, y, -0.66), SUIT_DARK)
end
-- HUGE bow tie
b:W("HeadDetail", V(0.08, 0.55, 0.55), V(-0.35, 2.55, -0.67), BOW, V(0, 90, 0))
b:W("HeadDetail", V(0.08, 0.55, 0.55), V(0.35, 2.55, -0.67), BOW, V(0, -90, 0))
b:B("HeadDetail", V(0.22, 0.24, 0.1), V(0, 2.55, -0.7), Color3.fromHex("d8408e"))
-- arms; one rests on a cane
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.4, 1.1, 0.45), V(s * 1.05, 1.9, 0), SUIT, V(0, 0, s * 8))
	b:B(name, V(0.36, 0.3, 0.4), V(s * 1.12, 1.25, 0), C.White) -- gloves
end
b:B("RightUpperArm", V(0.1, 1.1, 0.1), V(1.15, 0.55, -0.25), C.Line)
b:B("RightUpperArm", V(0.22, 0.22, 0.22), V(1.15, 1.15, -0.25), C.Gold)
-- head: moustache, monocle, top hat
b:B(H, V(1.2, 1.1, 1.05), V(0, 3.15, 0), SKIN)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.26, 3.28, -0.53), 0.3, V(0, 0, -1), Vector2.new(0, 0))
	b:B("HeadDetail", V(0.32, 0.12, 0.05), V(s * 0.2, 2.92, -0.54), STACHE, V(0, 0, s * -10))
	b:B("HeadDetail", V(0.1, 0.14, 0.05), V(s * 0.4, 2.98, -0.54), STACHE, V(0, 0, s * 30)) -- curl
	b:brow(V(s * 0.27, 3.52, -0.54), 0.28, V(0, 0, -1), s * -6, STACHE)
end
for _, e in { { 0, 0.2, 0.42, 0.05 }, { 0, -0.2, 0.42, 0.05 }, { 0.2, 0, 0.05, 0.42 }, { -0.2, 0, 0.05, 0.42 } } do
	b:B("HeadDetail", V(e[3], e[4], 0.04), V(0.26 + e[1], 3.28 + e[2], -0.57), C.Gold) -- monocle
end
b:B("HeadDetail", V(0.04, 0.4, 0.04), V(0.46, 3.0, -0.56), C.Gold) -- monocle chain
b:B(H, V(1.5, 0.1, 1.35), V(0, 3.75, 0), HAT)
b:B(H, V(1.0, 1.0, 0.9), V(0, 4.3, 0), HAT)
b:B(H, V(1.04, 0.16, 0.94), V(0, 3.9, 0), BOW)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
