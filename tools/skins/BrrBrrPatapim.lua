-- Brr Brr Patapim (Rare, Brainrot egg) - block remake 2026-10-10. Reference: the meme character - a forest creature
-- that is part monkey, part tree: a brown tree-trunk body with bark ridges and twiggy branch arms, a monkey face with
-- a huge droopy nose, mossy green leaves on the head under a tiny red hat, long thin legs and big flat feet.
-- Front-facing. Rare: Neon firefly glints, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BrrBrrPatapim")
local V = Vector3.new
local C = Kit.C
local BARK, BARK_DARK, FACE, NOSE = Color3.fromHex("96643c"), Color3.fromHex("6e4628"), Color3.fromHex("e8c49a"), Color3.fromHex("e09a7a")
local LEAF, LEAF_DARK, HAT = Color3.fromHex("5aaa3c"), Color3.fromHex("3f8a2a"), Color3.fromHex("dc2832")
local T, H = "UpperTorso", "Head"

-- long thin legs + big flat feet
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.26, 1.6, 0.26), V(s * 0.38, 1.05, 0), BARK)
	b:B(name, V(0.75, 0.2, 1.1), V(s * 0.42, 0.1, -0.25), FACE)
	for t = -1, 1 do
		b:B(name, V(0.18, 0.14, 0.2), V(s * 0.42 + t * 0.24, 0.12, -0.85), FACE)
	end
end
-- trunk body with bark ridges and a knot
b:B(T, V(1.4, 1.7, 1.1), V(0, 2.65, 0), BARK)
for _, x in { -0.45, 0.05, 0.5 } do
	b:B(T, V(0.12, 1.6, 0.05), V(x, 2.65, -0.57), BARK_DARK)
end
b:B(T, V(0.3, 0.26, 0.06), V(0.25, 2.2, -0.58), BARK_DARK)
-- twiggy branch arms with little leaves
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.9, 0.2, 0.2), V(s * 1.05, 3.0, 0), BARK, V(0, 0, s * 20))
	b:B(name, V(0.18, 0.7, 0.18), V(s * 1.45, 2.65, -0.05), BARK, V(0, 0, s * -15))
	b:B(name, V(0.4, 0.14, 0.18), V(s * 1.6, 3.35, 0), BARK, V(0, 0, s * 35))
	b:B(name, V(0.3, 0.3, 0.12), V(s * 1.78, 3.5, 0), LEAF, V(0, 0, 45))
	for f = 0, 2 do
		b:B(name, V(0.08, 0.25, 0.08), V(s * (1.5 + f * 0.06), 2.2, -0.12 + f * 0.08), BARK_DARK, V(0, 0, s * (f - 1) * 15))
	end
end
-- head: bark block with a pale monkey face, big droopy nose, mossy leaf hair, tiny red hat
b:B(H, V(1.5, 1.3, 1.2), V(0, 4.1, 0), BARK)
b:B(H, V(1.15, 0.95, 0.06), V(0, 4.05, -0.62), FACE)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.3, 4.3, -0.66), 0.34, V(0, 0, -1), Vector2.new(0, -0.03))
	b:brow(V(s * 0.32, 4.56, -0.67), 0.32, V(0, 0, -1), s * -10, BARK_DARK)
	b:B(H, V(0.3, 0.6, 0.3), V(s * 0.85, 4.15, 0), FACE) -- ears
end
b:B(H, V(0.5, 0.55, 0.4), V(0, 3.85, -0.85), NOSE)
b:B(H, V(0.56, 0.3, 0.45), V(0, 3.5, -0.92), NOSE)
b:B("HeadDetail", V(0.1, 0.1, 0.04), V(-0.1, 3.42, -1.15), BARK_DARK)
b:B("HeadDetail", V(0.1, 0.1, 0.04), V(0.1, 3.42, -1.15), BARK_DARK)
b:mouth(V(0, 3.62, -0.66), 0.5, 0.08, V(0, 0, -1), 0, 10)
for _, lf in { { -0.55, 4.82, -0.2 }, { 0.0, 4.9, 0.1 }, { 0.5, 4.8, -0.15 }, { -0.25, 4.85, 0.4 }, { 0.35, 4.75, 0.45 } } do
	b:B(H, V(0.5, 0.25, 0.45), V(lf[1], lf[2], lf[3]), if lf[3] > 0 then LEAF_DARK else LEAF)
end
b:B(H, V(0.55, 0.3, 0.5), V(0.15, 5.1, 0.0), HAT)
b:B(H, V(0.8, 0.07, 0.75), V(0.15, 4.95, 0.0), HAT)
-- Neon firefly glints
for _, ff in { { -1.4, 4.7, -0.4 }, { 1.5, 4.3, 0.2 }, { -1.1, 1.6, -0.5 } } do
	b:B(T, V(0.12, 0.12, 0.12), V(ff[1], ff[2], ff[3]), Color3.fromHex("eaff7a"), nil, Enum.Material.Neon)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
