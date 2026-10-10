-- Ballerina Cappuccina (Rare, Brainrot egg) - block remake 2026-10-10. Reference: the meme character - a ballerina
-- whose head is a cappuccino cup. A white mug head (handle on the side, coffee + foam heart on top, face on the
-- mug), a slim pink leotard, a wide layered pink tutu, arms raised overhead in a ballet arch, thin legs on tiptoe in
-- pink pointe shoes with ribbons. Front-facing. Rare: Neon sparkle on the tutu, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BallerinaCappuccina")
local V = Vector3.new
local C = Kit.C
local PINK, PINK_LIGHT, PINK_DARK = Color3.fromHex("ff6eaf"), Color3.fromHex("ffa8d0"), Color3.fromHex("e04e92")
local SKIN, MUG, MUG_SHADE = Color3.fromHex("f4ceb4"), Color3.fromHex("faf8f4"), Color3.fromHex("e2ddd4")
local COFFEE, FOAM = Color3.fromHex("6b4426"), Color3.fromHex("f0dcb8")
local T, H = "UpperTorso", "Head"

-- legs on tiptoe + pointe shoes with ribbons
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.24, 1.7, 0.26), V(s * 0.2, 1.15, 0), SKIN)
	b:B(name, V(0.26, 0.35, 0.3), V(s * 0.2, 0.18, -0.02), PINK)
	b:B(name, V(0.28, 0.05, 0.32), V(s * 0.2, 0.42, -0.02), PINK_DARK)
	b:B(name, V(0.29, 0.05, 0.33), V(s * 0.2, 0.55, -0.02), PINK_DARK, V(0, 0, 20))
end
-- tutu: layered flat discs (two crossed squares each), lighter on top
for i, layer in { { 2.15, 1.95, PINK }, { 2.3, 2.05, PINK_LIGHT } } do
	b:B(T, V(layer[1], 0.14, layer[1] * 0.85), V(0, layer[2], 0), layer[3])
	b:B(T, V(layer[1] * 0.85, 0.14, layer[1]), V(0, layer[2], 0), layer[3], V(0, 45, 0))
end
-- leotard body
b:B(T, V(0.8, 1.0, 0.55), V(0, 2.55, 0), PINK)
b:B(T, V(0.6, 0.2, 0.5), V(0, 3.1, 0), SKIN) -- neck/shoulders
b:B("HeadDetail", V(0.2, 0.2, 0.05), V(0, 2.75, -0.29), PINK_LIGHT, V(0, 0, 45)) -- little bow
-- arms raised overhead in an arch
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.18, 0.8, 0.18), V(s * 0.62, 3.4, 0), SKIN, V(0, 0, s * -25))
	b:B(name, V(0.16, 0.75, 0.16), V(s * 0.72, 4.15, 0), SKIN, V(0, 0, s * 15))
	b:B(name, V(0.16, 0.5, 0.16), V(s * 0.38, 4.7, 0), SKIN, V(0, 0, s * 60))
end
-- the cappuccino mug head
b:B(H, V(1.2, 1.0, 1.1), V(0, 3.75, 0), MUG)
b:B(H, V(1.3, 0.1, 1.2), V(0, 4.26, 0), MUG_SHADE)      -- rim
b:B(H, V(1.1, 0.06, 1.0), V(0, 4.28, 0), COFFEE)
b:B(H, V(0.7, 0.04, 0.6), V(0, 4.32, 0), FOAM)
b:B(H, V(0.18, 0.12, 0.02), V(-0.06, 4.35, -0.04), COFFEE, V(0, 0, 30)) -- latte-art heart
b:B(H, V(0.18, 0.12, 0.02), V(0.06, 4.35, -0.04), COFFEE, V(0, 0, -30))
b:B(H, V(0.12, 0.6, 0.14), V(0.82, 3.75, 0), MUG)        -- handle
b:B(H, V(0.25, 0.12, 0.14), V(0.7, 4.0, 0), MUG)
b:B(H, V(0.25, 0.12, 0.14), V(0.7, 3.5, 0), MUG)
b:B(H, V(1.22, 0.1, 1.12), V(0, 3.3, 0), MUG_SHADE)      -- base band
for _, s in { -1, 1 } do
	b:eye(V(s * 0.27, 3.82, -0.56), 0.32, V(0, 0, -1), Vector2.new(0, 0.05))
	-- long lashes
	for l = -1, 1 do
		b:B("HeadDetail", V(0.04, 0.1, 0.03), V(s * 0.27 + l * 0.1, 4.03, -0.58), C.Line, V(0, 0, l * -20))
	end
	b:B("HeadDetail", V(0.16, 0.08, 0.04), V(s * 0.42, 3.6, -0.56), PINK_LIGHT)
end
b:mouth(V(0, 3.55, -0.56), 0.24, 0.08, V(0, 0, -1), 0, 22)
-- Neon sparkles on the tutu
for _, sp in { { -0.9, 2.12, -0.6 }, { 0.7, 2.12, -0.75 }, { 0.1, 2.12, -0.95 } } do
	b:B(T, V(0.1, 0.06, 0.1), V(sp[1], sp[2], sp[3]), C.White, V(0, 45, 0), Enum.Material.Neon)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
