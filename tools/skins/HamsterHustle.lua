-- Hamster Hustle (Common, Pet egg) - block remake 2026-10-10. A chubby round hamster in a red blazer: tan + white fur,
-- huge stuffed cheeks, tiny round ears, buck teeth, little pink paws holding a sunflower seed, short stubby feet.
-- Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("HamsterHustle")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local FUR, WHITE, PINK, BLAZER = Color3.fromRGB(230, 170, 100), Color3.fromHex("fbf3e6"), Color3.fromHex("f2a0b0"), Color3.fromRGB(160, 60, 60)
for _, s in { -1, 1 } do
	b:B(if s < 0 then "LeftUpperLeg" else "RightUpperLeg", V(0.45, 0.3, 0.6), V(s * 0.45, 0.15, -0.1), PINK)
end
b:B(T, V(1.9, 1.5, 1.5), V(0, 1.1, 0), BLAZER) -- round blazer body
b:B(T, V(1.6, 1.7, 1.3), V(0, 1.15, 0), BLAZER)
b:B("HeadDetail", V(0.9, 1.2, 0.05), V(0, 1.2, -0.77), WHITE) -- white tummy fur
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.12, 0.12, 0.04), V(s * 0.55, 1.3, -0.77), Color3.fromHex("d8c070")) -- buttons
	b:B(if s < 0 then "LeftUpperArm" else "RightUpperArm", V(0.3, 0.3, 0.3), V(s * 0.3, 1.5, -0.85), PINK)
end
b:B("RightUpperArm", V(0.2, 0.36, 0.1), V(0, 1.55, -0.95), Color3.fromHex("3a3a3a")) -- sunflower seed
b:B("RightUpperArm", V(0.06, 0.3, 0.04), V(0, 1.55, -1.01), C.White)
b:B(H, V(1.6, 1.25, 1.3), V(0, 2.5, 0), FUR)
for _, s in { -1, 1 } do
	b:B(H, V(0.55, 0.6, 0.9), V(s * 0.85, 2.3, -0.15), WHITE) -- stuffed cheeks
	b:B(H, V(0.4, 0.4, 0.2), V(s * 0.55, 3.2, 0), FUR)
	b:B("HeadDetail", V(0.22, 0.22, 0.04), V(s * 0.55, 3.2, -0.11), PINK)
	b:eye(V(s * 0.32, 2.65, -0.66), 0.32, V(0, 0, -1), Vector2.new(0, 0))
end
b:B(H, V(0.7, 0.4, 0.15), V(0, 2.25, -0.68), WHITE)
b:B("HeadDetail", V(0.16, 0.1, 0.04), V(0, 2.4, -0.76), PINK)
b:B("HeadDetail", V(0.16, 0.18, 0.04), V(0, 2.12, -0.76), C.White) -- buck teeth
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
