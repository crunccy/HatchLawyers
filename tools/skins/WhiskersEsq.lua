-- Whiskers, Esq. (Uncommon, Pet egg) - block remake 2026-10-10. A lean ginger tabby cat in a dark suit: orange head
-- with darker tabby stripes, pointy ears, a white muzzle, green eyes, whiskers, an orange striped tail curling out
-- behind, holding a little briefcase. Deliberately simpler + different from Sir Fluffington (white king cat).
-- Front-facing. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("WhiskersEsq")
local V = Vector3.new
local C = Kit.C
local GINGER, STRIPE, MUZZLE, PINK = Color3.fromHex("f0963c"), Color3.fromHex("c46a1e"), Color3.fromHex("fbeee0"), Color3.fromHex("f2a0b0")
local SUIT, SUIT_DARK, CASE = Color3.fromHex("282832"), Color3.fromHex("1c1c24"), Color3.fromHex("7a4a26")
local T, H = "UpperTorso", "Head"

for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.42, 1.3, 0.46), V(s * 0.27, 0.9, 0), SUIT_DARK)
	b:B(name, V(0.46, 0.26, 0.66), V(s * 0.27, 0.13, -0.1), GINGER) -- paws
end
b:B(T, V(1.3, 1.4, 0.8), V(0, 2.25, 0), SUIT)
b:B("HeadDetail", V(0.42, 0.9, 0.05), V(0, 2.45, -0.42), C.White)
b:B("HeadDetail", V(0.14, 0.7, 0.04), V(0, 2.4, -0.45), STRIPE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.14, 0.8, 0.05), V(s * 0.28, 2.5, -0.43), SUIT_DARK, V(0, 0, s * 15))
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.36, 1.2, 0.42), V(s * 0.84, 2.2, 0), SUIT)
	b:B(name, V(0.36, 0.3, 0.4), V(s * 0.84, 1.48, 0), GINGER)
end
b:B("RightUpperArm", V(0.24, 0.1, 0.08), V(0.84, 1.3, 0), C.Line)
b:B("RightUpperArm", V(0.7, 0.5, 0.2), V(0.84, 1.0, 0), CASE)
-- tail curling up behind
b:B(T, V(0.22, 0.22, 0.7), V(0.3, 1.6, 0.7), GINGER)
b:B(T, V(0.22, 0.9, 0.22), V(0.3, 2.0, 1.05), GINGER)
b:B(T, V(0.24, 0.14, 0.24), V(0.3, 2.2, 1.05), STRIPE)
-- head with tabby stripes, ears, muzzle, whiskers
b:B(H, V(1.4, 1.15, 1.1), V(0, 3.55, 0), GINGER)
for _, x in { -0.3, 0, 0.3 } do
	b:B("HeadDetail", V(0.12, 0.35, 0.04), V(x, 3.95, -0.56), STRIPE)
end
for _, s in { -1, 1 } do
	b:B(H, V(0.4, 0.4, 0.3), V(s * 0.48, 4.25, 0), GINGER)
	b:B(H, V(0.22, 0.25, 0.28), V(s * 0.52, 4.52, 0), GINGER)
	b:B("HeadDetail", V(0.24, 0.3, 0.04), V(s * 0.48, 4.28, -0.16), PINK)
	b:eye(V(s * 0.32, 3.62, -0.56), 0.34, V(0, 0, -1), Vector2.new(0, 0), Color3.fromHex("3cbf5a"))
	b:B("HeadDetail", V(0.12, 0.3, 0.04), V(s * 0.66, 3.5, -0.56), STRIPE) -- cheek stripes
	for k = 0, 1 do
		b:B("HeadDetail", V(0.5, 0.03, 0.03), V(s * 0.72, 3.28 - k * 0.1, -0.6), Color3.fromHex("6a6a6a"), V(0, 0, s * (5 - k * 12)))
	end
end
b:B(H, V(0.6, 0.32, 0.18), V(0, 3.28, -0.6), MUZZLE)
b:B("HeadDetail", V(0.18, 0.12, 0.04), V(0, 3.42, -0.7), PINK)
b:mouth(V(0, 3.2, -0.7), 0.24, 0.06, V(0, 0, -1), 0, 18)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
