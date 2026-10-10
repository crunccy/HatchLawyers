-- Burger Boss (Legendary, Food egg) - block remake 2026-10-10. The whole body IS a stacked burger: bottom bun,
-- patty (grill marks, toothy grin), cheese with drips, frilly lettuce, tomato, a domed sesame top bun with the
-- eyes; a gold crown, a gold chain with a "$" medallion, thin arms in white cartoon gloves holding a gold gavel,
-- black legs and shiny shoes. Front-facing. Legendary: 1.15x, lots of gold.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BurgerBoss")
local V = Vector3.new
local C = Kit.C
local BUN, BUN_DARK, BUN_LIGHT = Color3.fromHex("e2a04c"), Color3.fromHex("c27f32"), Color3.fromHex("f0b866")
local PATTY, PATTY_DARK = Color3.fromHex("6b3a1e"), Color3.fromHex("4a2410")
local CHEESE, LETTUCE, LETTUCE_DARK, TOMATO = Color3.fromHex("ffcf3a"), Color3.fromHex("6cc53a"), Color3.fromHex("4ea42a"), Color3.fromHex("e5463a")
local SEED, BLACK, GLOVE = Color3.fromHex("fff3d6"), Color3.fromHex("1c1c20"), Color3.fromHex("f7f7f7")
local RUBY = Color3.fromHex("e0303a")
local T, H = "UpperTorso", "Head"

-- bottom bun
b:B(T, V(2.3, 0.42, 2.1), V(0, 1.15, 0), BUN)
b:B(T, V(2.4, 0.12, 2.2), V(0, 1.4, 0), BUN_LIGHT)
-- patty with grill marks and a bumpy edge
b:B(T, V(2.62, 0.5, 2.36), V(0, 1.71, 0), PATTY)
for _, x in { -0.8, 0.8 } do
	b:B(T, V(0.4, 0.5, 0.06), V(x, 1.71, -1.19), PATTY_DARK)
end
-- cheese slab + drips down the front and sides
b:B(T, V(2.72, 0.12, 2.46), V(0, 2.02, 0), CHEESE)
for _, d in { { -0.95, 0.32 }, { 0.15, 0.22 }, { 1.0, 0.4 } } do
	b:B(T, V(0.24, d[2], 0.1), V(d[1], 2.02 - d[2] / 2, -1.25), CHEESE)
end
b:B(T, V(0.1, 0.3, 0.24), V(1.38, 1.88, 0.4), CHEESE)
-- frilly lettuce: a slab with leafy bits poking out all round
b:B(T, V(2.76, 0.12, 2.5), V(0, 2.14, 0), LETTUCE)
for i = 0, 6 do
	local x = -1.2 + i * 0.4
	b:B(T, V(0.3, 0.14, 0.14), V(x, 2.1 - (i % 2) * 0.06, -1.3), if i % 2 == 0 then LETTUCE else LETTUCE_DARK)
end
for _, s in { -1, 1 } do
	b:B(T, V(0.14, 0.14, 0.3), V(s * 1.4, 2.12, -0.5), LETTUCE_DARK)
	b:B(T, V(0.14, 0.14, 0.3), V(s * 1.4, 2.08, 0.6), LETTUCE)
end
-- tomato
b:B(T, V(2.4, 0.12, 2.2), V(0, 2.26, 0), TOMATO)
-- domed top bun (stepped) with sesame seeds
b:B(H, V(2.5, 0.56, 2.32), V(0, 2.6, 0), BUN)
b:B(H, V(2.2, 0.32, 2.04), V(0, 3.02, 0), BUN)
b:B(H, V(1.6, 0.18, 1.5), V(0, 3.26, 0), BUN_LIGHT)
for _, sd in { { -0.6, 3.36, -0.3 }, { 0.3, 3.36, 0.2 }, { -0.1, 3.36, -0.5 }, { 0.6, 3.36, -0.2 }, { -0.4, 3.19, 0.6 },
	{ 0.85, 3.19, 0.55 }, { -0.95, 3.07, -0.9 }, { 0.95, 3.07, -0.85 }, { 0.0, 3.07, -1.03 } } do
	b:B("HeadDetail", V(0.16, 0.07, 0.1), V(sd[1], sd[2], sd[3]), SEED)
end
-- face: eyes on the top bun, confident brows; a big toothy grin on the patty
for _, s in { -1, 1 } do
	b:eye(V(s * 0.48, 2.68, -1.17), 0.46, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.5, 3.02, -1.03), 0.48, V(0, 0, -1), s * 12, BUN_DARK)
end
b:mouth(V(0, 1.72, -1.19), 1.2, 0.26, V(0, 0, -1), 7, 18)
-- gold crown with a ruby
b:B(H, V(1.5, 0.22, 1.4), V(0, 3.46, 0), C.Gold)
for i = -2, 2 do
	b:B(H, V(0.18, 0.3, 0.18), V(i * 0.33, 3.72, -0.6), C.Gold)
end
b:B(H, V(0.2, 0.2, 0.08), V(0, 3.47, -0.72), RUBY)
-- gold chain + "$" medallion
for i = -3, 3 do
	b:B(T, V(0.16, 0.1, 0.06), V(i * 0.22, 1.98 - math.abs(i) * -0.02 - (3 - math.abs(i)) * 0.06, -1.26), C.Gold)
end
b:B(T, V(0.4, 0.4, 0.07), V(0, 1.58, -1.27), C.Gold)
b:B("HeadDetail", V(0.08, 0.3, 0.04), V(0, 1.58, -1.32), C.GoldDark)
b:B("HeadDetail", V(0.2, 0.06, 0.04), V(0, 1.67, -1.32), C.GoldDark)
b:B("HeadDetail", V(0.2, 0.06, 0.04), V(0, 1.49, -1.32), C.GoldDark)
-- arms: thin black, white cartoon gloves; right hand holds a gold gavel up, left gives a thumbs-up
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.18, 0.72, 0.18), V(s * 1.58, 2.0, -0.12), BLACK, V(0, 0, -s * 53))   -- from the burger's side up to the glove
	b:B(name, V(0.36, 0.36, 0.36), V(s * 1.85, 2.2, -0.15), GLOVE)
	b:B(name, V(0.4, 0.12, 0.4), V(s * 1.8, 2.0, -0.15), GLOVE)                -- glove cuff
end
b:B("LeftUpperArm", V(0.12, 0.26, 0.12), V(-1.85, 2.48, -0.2), GLOVE)         -- thumb up
b:B("RightUpperArm", V(0.12, 0.8, 0.12), V(1.9, 2.55, -0.15), BUN_DARK)       -- gavel handle
b:B("RightUpperArm", V(0.6, 0.3, 0.3), V(1.9, 2.98, -0.15), C.Gold)          -- gavel head
b:B("RightUpperArm", V(0.08, 0.32, 0.32), V(1.68, 2.98, -0.15), C.GoldDark)
b:B("RightUpperArm", V(0.08, 0.32, 0.32), V(2.12, 2.98, -0.15), C.GoldDark)
-- legs: black, shiny shoes with gold buckles
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.26, 0.8, 0.26), V(s * 0.5, 0.55, 0), BLACK)
	b:B(name, V(0.5, 0.24, 0.72), V(s * 0.52, 0.12, -0.12), BLACK)
	b:B(name, V(0.18, 0.1, 0.06), V(s * 0.52, 0.2, -0.49), C.Gold)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.35) -- a burger is squat: scaled so it still stands taller than a person (Legendary)
print(b:preview())
_G.SkinBuild = b
