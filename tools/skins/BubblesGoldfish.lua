-- Bubbles the Goldfish (Uncommon, Pet egg) - block remake 2026-10-10. A lawyer whose head is a fishbowl: a see-
-- through glass bowl (with a rim and blue water) with an orange goldfish face-forward inside it, on a blue suited
-- body with a light-blue tie. Front-facing. Uncommon: 1 prop (the bowl), 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BubblesGoldfish")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_DARK, TIE = Color3.fromHex("3c8cc8"), Color3.fromHex("2c6aa0"), Color3.fromHex("aae1ff")
local GLASS, WATER, FISH, FIN = Color3.fromHex("dff4ff"), Color3.fromHex("7cc8f0"), Color3.fromHex("ff8a2a"), Color3.fromHex("ffb060")
local T, H = "UpperTorso", "Head"

for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.46, 1.4, 0.5), V(s * 0.28, 0.95, 0), SUIT_DARK)
	b:B(name, V(0.5, 0.25, 0.75), V(s * 0.28, 0.13, -0.1), C.Line)
end
b:B(T, V(1.45, 1.5, 0.8), V(0, 2.4, 0), SUIT)
b:B("HeadDetail", V(0.45, 1.0, 0.05), V(0, 2.6, -0.42), C.White)
b:B("HeadDetail", V(0.16, 0.85, 0.04), V(0, 2.55, -0.45), TIE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.14, 0.85, 0.05), V(s * 0.3, 2.65, -0.43), SUIT_DARK, V(0, 0, s * 15))
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.4, 1.3, 0.45), V(s * 0.93, 2.35, 0), SUIT)
	b:B(name, V(0.36, 0.3, 0.4), V(s * 0.93, 1.55, 0), Color3.fromHex("f0d0b0"))
end
-- the fishbowl head: water inside, glass shell, rim
b:B(H, V(1.5, 0.9, 1.3), V(0, 3.65, 0.05), WATER).Transparency = 0.55
local g1 = b:B(H, V(1.7, 1.5, 1.6), V(0, 3.85, 0), GLASS); g1.Transparency = 0.82
b:B(H, V(1.3, 0.12, 1.2), V(0, 4.62, 0), GLASS)
b:B(H, V(1.1, 0.12, 1.0), V(0, 3.12, 0), SUIT_DARK) -- collar the bowl sits in
-- the goldfish inside, facing out
b:B(H, V(0.8, 0.6, 0.5), V(0, 3.75, -0.5), FISH)
b:B(H, V(0.3, 0.45, 0.12), V(0, 3.75, -0.15), FIN)
b:B(H, V(0.1, 0.3, 0.3), V(0, 4.1, -0.45), FIN)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.19, 3.85, -0.76), 0.24, V(0, 0, -1), Vector2.new(0, 0))
	b:B(H, V(0.14, 0.2, 0.2), V(s * 0.43, 3.65, -0.5), FIN)
end
b:B("HeadDetail", V(0.14, 0.1, 0.03), V(0, 3.6, -0.76), C.Mouth)
-- a couple of air bubbles in the water
for _, bb in { { 0.45, 4.2, -0.3, 0.12 }, { 0.55, 4.45, -0.2, 0.09 } } do
	b:B(H, V(bb[4], bb[4], bb[4]), V(bb[1], bb[2], bb[3]), C.White).Transparency = 0.3
end
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
