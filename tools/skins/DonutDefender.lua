-- Donut Dee (Rare, Food egg) - block remake 2026-10-10. A big upright ring donut (hole in the middle!): golden
-- dough, pink frosting on the front with drips and rainbow sprinkles, eyes on the upper ring, a grin on the lower
-- ring, little legs and arms, and a round knight's shield (with a donut emblem) - the "defender". Front-facing.
-- Rare: Neon pink shield rim, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("DonutDefender")
local V = Vector3.new
local C = Kit.C
local DOUGH, DOUGH_DARK, ICING, ICING_DARK = Color3.fromHex("dca05a"), Color3.fromHex("b87c3c"), Color3.fromHex("ff8cbe"), Color3.fromHex("e86aa4")
local SHIELD, SHIELD_DARK, BLACK = Color3.fromHex("c3c9d2"), Color3.fromHex("8a929e"), Color3.fromHex("1c1c20")
local SPRINKLES = { Color3.fromHex("3fb8ff"), Color3.fromHex("ffd23f"), Color3.fromHex("6cd66c"), C.White, Color3.fromHex("b07aff") }
local T, H = "UpperTorso", "Head"
local cy = 2.55
local centre = CFrame.new(0, cy, 0)

-- the ring: 10 dough blocks around a circle in the X-Y plane, pink icing slabs on their fronts (top 7 segments)
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	local seg = centre * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.25, 0)
	local name = if math.cos(a) > 0 then H else T
	b:BAt(name, V(0.95, 0.95, 1.0), seg, DOUGH)
	local top = math.cos(a) > -0.6
	if top then
		b:BAt(name, V(0.98, 0.98, 0.08), seg * CFrame.new(0, 0, -0.52), ICING)
	end
end
-- frosting drips + sprinkles on the front
for _, d in { { -1.3, cy - 0.45, 0.35 }, { 1.25, cy - 0.6, 0.4 }, { 0.55, cy - 0.85, 0.25 } } do
	b:B(T, V(0.22, d[3], 0.08), V(d[1], d[2], -0.52), ICING_DARK)
end
for i, sp in { { -0.6, cy + 1.45 }, { 0.3, cy + 1.5 }, { 0.95, cy + 1.05 }, { -1.15, cy + 0.85 }, { 1.35, cy + 0.2 }, { -1.4, cy - 0.05 } } do
	b:B("HeadDetail", V(0.24, 0.08, 0.05), V(sp[1], sp[2], -0.58), SPRINKLES[i % #SPRINKLES + 1], V(0, 0, i * 40))
end
-- face: eyes on the upper ring, grin on the lower ring
for _, s in { -1, 1 } do
	b:eye(V(s * 0.5, cy + 1.05, -0.58), 0.4, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.52, cy + 1.36, -0.59), 0.36, V(0, 0, -1), s * 14, ICING_DARK)
end
b:mouth(V(0, cy - 1.2, -0.52), 0.55, 0.16, V(0, 0, -1), 5, 18)
-- legs + shoes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.2, 0.9, 0.2), V(s * 0.45, 0.55, 0), BLACK)
	b:B(name, V(0.45, 0.22, 0.6), V(s * 0.47, 0.11, -0.1), DOUGH_DARK)
end
-- arms: thin, white gloves; the -X arm holds a round shield in front, the +X gives a thumbs up
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.16, 0.16), V(s * 1.9, cy - 0.3, -0.1), BLACK, V(0, 0, s * -20))
	b:B(name, V(0.32, 0.32, 0.32), V(s * 2.2, cy - 0.15, -0.2), C.White)
end
b:B("RightUpperArm", V(0.1, 0.24, 0.1), V(2.2, cy + 0.12, -0.25), C.White)
local sh = V(-2.2, cy - 0.15, -0.55)
b:B("LeftUpperArm", V(1.15, 1.15, 0.12), sh, SHIELD)
b:B("LeftUpperArm", V(1.15, 1.15, 0.12), sh, SHIELD, V(0, 0, 45))
b:B("LeftUpperArm", V(1.42, 1.42, 0.08), sh + V(0, 0, 0.06), ICING, V(0, 0, 22.5), Enum.Material.Neon) -- glowing rim
b:B("HeadDetail", V(0.55, 0.55, 0.05), sh + V(0, 0, -0.08), DOUGH)
b:B("HeadDetail", V(0.5, 0.25, 0.05), sh + V(0, 0.1, -0.1), ICING)
b:B("HeadDetail", V(0.18, 0.18, 0.05), sh + V(0, 0, -0.12), SHIELD_DARK)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
