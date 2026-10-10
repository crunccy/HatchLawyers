-- Intern Suit (Common) - block remake 2026-10-10. A skinny, nervous new intern: a slightly-too-big grey suit with a
-- blue tie, a lanyard with an ID badge, messy hair, big worried eyes, a sweat drop, and a tall wobbly stack of papers.
-- Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("InternSuit")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local SUIT, PANTS, TIE, SKIN, HAIR = Color3.fromRGB(170, 172, 186), Color3.fromRGB(70, 72, 86), Color3.fromRGB(80, 140, 255), Color3.fromHex("f0c8a0"), Color3.fromHex("8a5a2e")
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.4, 1.5, 0.5), V(s * 0.25, 1.00, 0), PANTS)
	b:B(name, V(0.44, 0.25, 0.75), V(s * 0.25, 0.13, -0.12), C.Line)
end
b:B(T, V(1.3, 1.5, 0.75), V(0, 2.5, 0), SUIT)
b:B("HeadDetail", V(0.4, 1.0, 0.05), V(0, 2.75, -0.4), C.White)
b:B("HeadDetail", V(0.14, 0.8, 0.04), V(0, 2.7, -0.43), TIE)
b:B("HeadDetail", V(0.05, 0.6, 0.04), V(-0.2, 2.9, -0.44), Color3.fromHex("2f7bff"), V(0, 0, 15)) -- lanyard
b:B("HeadDetail", V(0.05, 0.6, 0.04), V(0.2, 2.9, -0.44), Color3.fromHex("2f7bff"), V(0, 0, -15))
b:B("HeadDetail", V(0.32, 0.4, 0.04), V(0, 2.45, -0.46), C.White) -- ID badge
b:B("HeadDetail", V(0.14, 0.14, 0.03), V(-0.06, 2.5, -0.49), SKIN)
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.4, 1.3, 0.45), V(s * 0.86, 2.45, -0.15), SUIT, V(30, 0, 0)) -- both arms forward holding the stack
	b:B(name, V(0.34, 0.3, 0.36), V(s * 0.6, 1.95, -0.65), SKIN)
end
for i = 0, 5 do -- the wobbly paper stack
	b:B(T, V(0.9, 0.16, 0.65), V((i % 2) * 0.08 - 0.04, 2.05 + i * 0.17, -0.85), if i % 2 == 0 then C.White else Color3.fromHex("ececec"), V(0, (i % 3 - 1) * 6, 0))
end
b:B(H, V(1.1, 1.15, 1.0), V(0, 3.85, 0), SKIN)
b:B(H, V(1.16, 0.3, 1.06), V(0, 4.47, 0.03), HAIR)
for i = -2, 2 do
	b:B(H, V(0.2, 0.25, 0.2), V(i * 0.22, 4.68, (i % 2) * 0.15), HAIR, V(0, 0, i * 12)) -- messy tufts
end
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, 3.95, -0.51), 0.34, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.27, 4.22, -0.52), 0.28, V(0, 0, -1), s * -14, HAIR)
end
b:mouth(V(0, 3.55, -0.51), 0.3, 0.1, V(0, 0, -1), 0, -10)
b:B("HeadDetail", V(0.1, 0.18, 0.04), V(0.5, 4.1, -0.52), Color3.fromHex("7cc8f0")) -- sweat drop
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
