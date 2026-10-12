-- Sandy Seahorse (Rare, Ocean egg) - block remake 2026-10-10. An upright orange seahorse, gently hovering:
-- stacked body with a pale ridged belly, head turned toward the viewer with a long tube snout, a little coronet on
-- top, a teal fin down the back, a tail curling under, tiny fins as "hands" holding a rolled scroll, a teal bow tie.
-- Front-facing, HOVERS. Rare: Neon bubbles, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("SeahorseSolicitor")
local V = Vector3.new
local C = Kit.C
local ORANGE, ORANGE_DARK, BELLY, TEAL = Color3.fromHex("e6783c"), Color3.fromHex("b86030"), Color3.fromHex("f6c48e"), Color3.fromHex("3cc8be")
local SCROLL, BUBBLE = Color3.fromHex("f3e2b8"), Color3.fromHex("bff4ff")
local T, H = "UpperTorso", "Head"

-- curled tail (stepped spiral at the bottom)
for _, tb in { { 0, 1.2, 0.1, 0.7 }, { 0.1, 0.7, 0.2, 0.55 }, { 0.3, 0.35, 0.15, 0.45 }, { 0.6, 0.25, -0.05, 0.38 }, { 0.75, 0.5, -0.2, 0.32 }, { 0.6, 0.72, -0.25, 0.26 } } do
	b:B("LeftUpperLeg", V(tb[4], tb[4], tb[4]), V(tb[1], tb[2], tb[3]), if tb[2] > 0.6 and tb[1] > 0.5 then ORANGE_DARK else ORANGE)
end
-- body: stacked, bulging belly with ridges
b:B(T, V(1.1, 0.8, 1.0), V(0, 1.8, 0.05), ORANGE)
b:B(T, V(1.25, 0.9, 1.15), V(0, 2.5, -0.05), ORANGE)
b:B(T, V(1.1, 0.6, 1.0), V(0, 3.15, 0), ORANGE)
b:B(T, V(0.8, 1.7, 0.12), V(0, 2.35, -0.66), BELLY)
for i = 0, 4 do
	b:B("HeadDetail", V(0.84, 0.05, 0.04), V(0, 1.65 + i * 0.32, -0.73), ORANGE_DARK)
end
-- teal bow tie
b:B("HeadDetail", V(0.22, 0.22, 0.05), V(-0.16, 3.2, -0.56), TEAL, V(0, 0, 45))
b:B("HeadDetail", V(0.22, 0.22, 0.05), V(0.16, 3.2, -0.56), TEAL, V(0, 0, 45))
b:B("HeadDetail", V(0.12, 0.12, 0.06), V(0, 3.2, -0.58), Color3.fromHex("2a9a92"))
-- dorsal fin down the back
for i = 0, 3 do
	b:B(T, V(0.08, 0.4, 0.35 - i * 0.04), V(0, 1.9 + i * 0.38, 0.68), TEAL)
end
-- head: block with the snout pointing at the viewer, coronet on top
b:B(H, V(1.0, 0.95, 1.0), V(0, 3.85, 0), ORANGE)
b:B(H, V(0.38, 0.32, 0.7), V(0, 3.62, -0.8), ORANGE)
b:B(H, V(0.44, 0.38, 0.1), V(0, 3.62, -1.18), ORANGE_DARK)
b:B(H, V(0.18, 0.08, 0.04), V(0, 3.6, -1.24), C.Mouth)
for i = -1, 1 do
	b:B(H, V(0.16, 0.3, 0.16), V(i * 0.28, 4.45, 0.05), ORANGE_DARK)
end
b:B(H, V(0.7, 0.12, 0.5), V(0, 4.36, 0.05), ORANGE_DARK)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.27, 3.98, -0.51), 0.34, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.28, 4.22, -0.52), 0.3, V(0, 0, -1), s * -6, ORANGE_DARK)
	b:B("HeadDetail", V(0.16, 0.08, 0.04), V(s * 0.38, 3.72, -0.51), Color3.fromHex("ff9aa8"))
end
-- little fins holding a rolled legal scroll
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.35, 0.18, 0.3), V(s * 0.72, 2.55, -0.45), TEAL, V(0, 0, s * -25))
end
b:B("RightUpperArm", V(1.3, 0.24, 0.24), V(0, 2.55, -0.72), SCROLL)
b:B("RightUpperArm", V(0.08, 0.28, 0.28), V(0.66, 2.55, -0.72), Color3.fromHex("d8c08a"))
b:B("RightUpperArm", V(0.08, 0.28, 0.28), V(-0.66, 2.55, -0.72), Color3.fromHex("d8c08a"))
b:B("RightUpperArm", V(0.14, 0.26, 0.06), V(0, 2.55, -0.86), Color3.fromHex("c0282e"))
-- Neon bubbles rising
for _, bb in { { 0.7, 4.7, -0.5, 0.2 }, { 0.95, 5.15, -0.4, 0.14 }, { 0.75, 5.5, -0.3, 0.1 } } do
	b:B(T, V(bb[4], bb[4], bb[4]), V(bb[1], bb[2], bb[3]), BUBBLE, nil, Enum.Material.Neon)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
b.hover = 0.4
print(b:preview())
_G.SkinBuild = b
