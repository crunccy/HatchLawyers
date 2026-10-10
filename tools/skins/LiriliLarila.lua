-- Lirili Larila (Rare, Brainrot egg) - block remake 2026-10-10. Reference: the meme character - an elephant head on
-- a green cactus body, wearing sandals, holding a pocket watch. Grey elephant head with big flappy ears and a long
-- trunk curling down, small tusks; a tall ribbed cactus body with little spines and two cactus "arm" branches (one
-- holds a gold pocket watch); stubby green legs in brown sandals. Front-facing. Rare: Neon watch face, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("LiriliLarila")
local V = Vector3.new
local C = Kit.C
local GREY, GREY_DARK, PINK = Color3.fromHex("9698a0"), Color3.fromHex("74767e"), Color3.fromHex("e8a8b0")
local CACTUS, CACTUS_DARK, SPINE = Color3.fromHex("5aaa50"), Color3.fromHex("3f8a3a"), Color3.fromHex("f4ecc8")
local SANDAL, STRAP = Color3.fromHex("8a5a2e"), Color3.fromHex("6b4426")
local T, H = "UpperTorso", "Head"

-- stubby legs + sandals
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.45, 0.8, 0.45), V(s * 0.35, 0.55, 0), CACTUS)
	b:B(name, V(0.6, 0.1, 0.85), V(s * 0.37, 0.05, -0.12), SANDAL)
	b:B(name, V(0.5, 0.08, 0.1), V(s * 0.37, 0.2, -0.3), STRAP)
	b:B(name, V(0.08, 0.2, 0.5), V(s * 0.37, 0.14, -0.05), STRAP)
end
-- cactus body: tall, ribbed (darker vertical ribs), little spines, rounded top under the head
b:B(T, V(1.3, 2.0, 1.1), V(0, 1.95, 0), CACTUS)
b:B(T, V(1.1, 2.1, 1.25), V(0, 1.95, 0), CACTUS)
for _, x in { -0.4, 0, 0.4 } do
	b:B(T, V(0.08, 1.9, 0.04), V(x, 1.95, -0.64), CACTUS_DARK)
end
for _, sp in { { -0.2, 1.4 }, { 0.2, 2.2 }, { -0.2, 2.6 }, { 0.2, 1.2 }, { -0.6, 2.0 }, { 0.6, 1.7 } } do
	b:B("HeadDetail", V(0.04, 0.04, 0.16), V(sp[1], sp[2], -0.7), SPINE)
end
-- cactus arm branches: out then up; one holds a pocket watch
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.38, 0.38), V(s * 0.9, 1.9, 0), CACTUS)
	b:B(name, V(0.38, 0.8, 0.38), V(s * 1.1, 2.4, 0), CACTUS)
	b:B(name, V(0.04, 0.04, 0.14), V(s * 1.1, 2.5, -0.24), SPINE)
end
b:B("RightUpperArm", V(0.05, 0.3, 0.05), V(1.1, 2.85, -0.2), C.Gold)                 -- watch chain
b:B("RightUpperArm", V(0.5, 0.5, 0.12), V(1.1, 3.1, -0.3), C.Gold)
b:B("RightUpperArm", V(0.38, 0.38, 0.05), V(1.1, 3.1, -0.37), C.White, nil, Enum.Material.Neon)
b:B("RightUpperArm", V(0.03, 0.16, 0.03), V(1.1, 3.16, -0.4), C.Line)
b:B("RightUpperArm", V(0.12, 0.03, 0.03), V(1.15, 3.1, -0.4), C.Line)
-- elephant head: grey block, big flappy ears (pink inside), trunk curling down + forward, tusks
b:B(H, V(1.4, 1.2, 1.2), V(0, 3.55, 0), GREY)
b:B(H, V(1.2, 0.3, 1.0), V(0, 4.25, 0), GREY)
for _, s in { -1, 1 } do
	b:B(H, V(0.7, 1.1, 0.14), V(s * 1.0, 3.55, 0.15), GREY, V(0, s * -20, 0))
	b:B(H, V(0.5, 0.8, 0.05), V(s * 0.98, 3.55, 0.05), PINK, V(0, s * -20, 0))
	b:B(H, V(0.1, 0.1, 0.4), V(s * 0.3, 3.05, -0.7), C.White, V(-20, 0, 0)) -- tusks
	b:eye(V(s * 0.35, 3.78, -0.61), 0.34, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.37, 4.04, -0.62), 0.32, V(0, 0, -1), s * -6, GREY_DARK)
end
b:B(H, V(0.4, 0.5, 0.4), V(0, 3.2, -0.75), GREY)
b:B(H, V(0.34, 0.55, 0.34), V(0, 2.75, -0.9), GREY)
b:B(H, V(0.3, 0.3, 0.4), V(0, 2.42, -1.08), GREY_DARK)
for i = 0, 2 do
	b:B("HeadDetail", V(0.36, 0.04, 0.04), V(0, 3.05 - i * 0.22, -0.96 - i * 0.04), GREY_DARK) -- trunk wrinkles
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
