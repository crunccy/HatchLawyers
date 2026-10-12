-- Pizza Pete (Rare, Food egg) - block remake 2026-10-10. A walking pizza slice, crust up and point down: a
-- stepped cheesy triangle with red sauce showing at the edges, pepperoni, cheese drips, a thick golden crust on top,
-- a stern face, a green tie, thin legs at the point, one arm pointing an accusing finger ("You did it!"), the other on
-- its hip. Front-facing. Rare: Neon steam wisps off the hot slice, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("PizzaProsecutor")
local V = Vector3.new
local C = Kit.C
local CHEESE, CHEESE_DARK, SAUCE, PEPPERONI = Color3.fromHex("ffd250"), Color3.fromHex("f0b830"), Color3.fromHex("d8402a"), Color3.fromHex("b8282a")
local CRUST, CRUST_DARK, GREEN, BLACK = Color3.fromHex("e0a458"), Color3.fromHex("b87a35"), Color3.fromHex("3c783c"), Color3.fromHex("1c1c20")
local T, H = "UpperTorso", "Head"

-- the slice: rows narrowing downward; sauce layer behind each row peeks out at the edges
local rows = { { 4.0, 2.5 }, { 3.5, 2.1 }, { 3.0, 1.7 }, { 2.5, 1.3 }, { 2.0, 0.9 }, { 1.55, 0.5 } }
for i, r in rows do
	local name = if i <= 2 then H else T
	b:B(name, V(r[2] + 0.1, 0.5, 0.5), V(0, r[1], 0.04), SAUCE)
	b:B(name, V(r[2], 0.5, 0.56), V(0, r[1], 0), CHEESE)
end
-- crust on top
b:B(H, V(2.8, 0.5, 0.8), V(0, 4.45, 0.05), CRUST)
b:B(H, V(2.6, 0.18, 0.7), V(0, 4.75, 0.05), CRUST_DARK)
-- pepperoni + cheese drips
for _, p in { { -0.75, 3.35 }, { 0.65, 3.0 }, { -0.2, 2.35 }, { 0.15, 1.75 } } do
	b:B("HeadDetail", V(0.36, 0.36, 0.05), V(p[1], p[2], -0.3), PEPPERONI)
	b:B("HeadDetail", V(0.1, 0.1, 0.04), V(p[1] - 0.08, p[2] + 0.08, -0.33), Color3.fromHex("d84848"))
end
for _, d in { { -1.0, 3.6, 0.35 }, { 0.95, 3.1, 0.3 }, { -0.55, 2.1, 0.25 } } do
	b:B("HeadDetail", V(0.16, d[3], 0.05), V(d[1], d[2], -0.3), CHEESE_DARK)
end
-- stern prosecutor face
for _, s in { -1, 1 } do
	b:eye(V(s * 0.45, 3.85, -0.3), 0.4, V(0, 0, -1), Vector2.new(s * -0.05, 0))
	b:brow(V(s * 0.47, 4.13, -0.31), 0.42, V(0, 0, -1), s * 18, CRUST_DARK)
end
b:mouth(V(0, 3.45, -0.3), 0.36, 0.08, V(0, 0, -1), 0, 0) -- flat, stern
-- green tie hanging from under the crust collar
b:B("HeadDetail", V(0.2, 0.16, 0.05), V(0, 3.18, -0.31), GREEN)
b:B("HeadDetail", V(0.16, 0.5, 0.05), V(0, 2.85, -0.31), GREEN)
-- legs + black shoes at the point
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.16, 1.05, 0.16), V(s * 0.25, 0.75, 0), BLACK)
	b:B(name, V(0.4, 0.2, 0.6), V(s * 0.27, 0.1, -0.1), BLACK)
end
-- arms: -X points an accusing finger forward, +X on the hip
b:B("LeftUpperArm", V(0.7, 0.16, 0.16), V(-1.25, 3.0, -0.25), BLACK, V(0, 30, 0))
b:B("LeftUpperArm", V(0.32, 0.3, 0.3), V(-1.55, 3.0, -0.5), C.White)
b:B("LeftUpperArm", V(0.1, 0.1, 0.4), V(-1.6, 3.05, -0.8), C.White)
b:B("RightUpperArm", V(0.55, 0.16, 0.16), V(1.0, 2.45, -0.05), BLACK, V(0, 0, 40))
b:B("RightUpperArm", V(0.45, 0.16, 0.16), V(0.95, 2.0, -0.05), BLACK, V(0, 0, -40))
b:B("RightUpperArm", V(0.26, 0.26, 0.26), V(0.72, 1.8, -0.05), C.White)
-- Neon steam wisps
for _, w in { { -0.6, 5.2 }, { 0.1, 5.45 }, { 0.75, 5.15 } } do
	b:B(H, V(0.1, 0.4, 0.1), V(w[1], w[2], 0.05), Color3.fromHex("ffffff"), V(0, 0, 20), Enum.Material.Neon)
	b:B(H, V(0.1, 0.3, 0.1), V(w[1] + 0.1, w[2] + 0.32, 0.05), Color3.fromHex("ffffff"), V(0, 0, -20), Enum.Material.Neon)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
