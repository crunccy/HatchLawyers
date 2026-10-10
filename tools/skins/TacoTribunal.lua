-- Taco Tribunal (Uncommon, Food egg) - block remake 2026-10-10. A walking taco seen side-on: a golden U-shaped shell
-- (blocks around the bottom half of a circle) stuffed with frilly lettuce, tomato and cheese poking out of the top,
-- a face on the shell, short legs, little arms, a tiny gavel. Front-facing. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("TacoTribunal")
local V = Vector3.new
local C = Kit.C
local SHELL, SHELL_DARK, LETTUCE, LETTUCE_DARK = Color3.fromHex("f0be50"), Color3.fromHex("c88a28"), Color3.fromHex("6cc53a"), Color3.fromHex("4ea42a")
local TOMATO, CHEESE, MEAT, BLACK = Color3.fromHex("e5463a"), Color3.fromHex("ffd23f"), Color3.fromHex("8a4a26"), Color3.fromHex("1c1c20")
local T, H = "UpperTorso", "Head"
local cy = 2.9

for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.22, 1.0, 0.22), V(s * 0.45, 0.6, 0), BLACK)
	b:B(name, V(0.45, 0.2, 0.62), V(s * 0.47, 0.1, -0.1), SHELL_DARK)
end
-- filling first (it sits inside the U): meat, cheese shreds, lettuce frills, tomato
b:B(T, V(2.6, 0.5, 0.9), V(0, cy + 0.05, 0), MEAT)
for i = -3, 3 do
	b:B(H, V(0.36, 0.3, 1.0), V(i * 0.4, cy + 0.42 + (i % 2) * 0.08, 0), if i % 2 == 0 then LETTUCE else LETTUCE_DARK)
end
for _, t in { -0.9, 0.2, 1.0 } do
	b:B(H, V(0.45, 0.16, 0.8), V(t, cy + 0.66, 0), TOMATO)
end
for _, c in { -0.5, 0.6 } do
	b:B(H, V(0.5, 0.08, 0.7), V(c, cy + 0.6, 0), CHEESE, V(0, 30, 0))
end
-- the U-shaped shell: 9 blocks around the bottom half of a circle, front + back walls
for i = 0, 8 do
	local th = math.rad(-180 + i * 22.5)
	b:B(T, V(0.62, 0.62, 1.2), V(math.cos(th) * 1.45, cy + math.sin(th) * 1.45, 0), SHELL, V(0, 0, math.deg(th) + 90))
end
-- the flat side of the shell facing us: a stepped half-disc filling the U
for _, row in { { cy - 0.25, 2.75 }, { cy - 0.7, 2.45 }, { cy - 1.1, 1.85 }, { cy - 1.42, 1.05 } } do
	b:B(T, V(row[2], 0.46, 0.12), V(0, row[1], -0.55), SHELL)
end
for _, sp in { { -0.8, cy - 0.3 }, { 0.6, cy - 0.9 }, { 0.9, cy - 0.2 }, { -0.3, cy - 1.15 } } do
	b:B("HeadDetail", V(0.14, 0.14, 0.04), V(sp[1], sp[2], -0.62), SHELL_DARK)
end
-- face on the shell
for _, s in { -1, 1 } do
	b:eye(V(s * 0.38, cy - 0.45, -0.62), 0.38, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.4, cy - 0.15, -0.63), 0.36, V(0, 0, -1), s * 10, SHELL_DARK)
end
b:mouth(V(0, cy - 0.95, -0.62), 0.42, 0.12, V(0, 0, -1), 4, 18)
-- arms + tiny gavel
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.5, 0.16, 0.16), V(s * 1.85, cy - 0.75, -0.45), BLACK, V(0, 0, s * -25))
	b:B(name, V(0.28, 0.28, 0.28), V(s * 2.15, cy - 0.6, -0.5), C.White)
end
b:B("RightUpperArm", V(0.1, 0.6, 0.1), V(2.15, cy - 0.25, -0.55), MEAT)
b:B("RightUpperArm", V(0.45, 0.24, 0.24), V(2.15, cy + 0.08, -0.55), Color3.fromHex("8a5a2e"))
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
