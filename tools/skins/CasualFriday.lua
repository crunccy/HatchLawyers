-- Casual Friday (Common) - block remake 2026-10-10. A laid-back lawyer on dress-down day: an orange short-sleeve shirt
-- with yellow flowers, blue jeans, flip-flops, a red cap with sunglasses perched on it, and a smoothie with a straw.
-- Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("CasualFriday")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local SHIRT, FLOWER, JEANS, CAP, SKIN = Color3.fromRGB(255, 140, 60), Color3.fromRGB(255, 220, 80), Color3.fromRGB(60, 90, 170), Color3.fromRGB(255, 80, 80), Color3.fromHex("e8b48a")
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.46, 1.4, 0.5), V(s * 0.28, 0.95, 0), JEANS)
	b:B(name, V(0.4, 0.2, 0.4), V(s * 0.28, 0.15, 0), SKIN)
	b:B(name, V(0.5, 0.06, 0.8), V(s * 0.28, 0.03, -0.12), Color3.fromHex("3cc8be")) -- flip-flops
end
b:B(T, V(1.45, 1.45, 0.8), V(0, 2.4, 0), SHIRT)
for _, f in { { -0.4, 2.7 }, { 0.35, 2.3 }, { -0.1, 1.95 }, { 0.45, 2.85 } } do
	b:B("HeadDetail", V(0.22, 0.22, 0.04), V(f[1], f[2], -0.42), FLOWER, V(0, 0, 45))
end
b:B("HeadDetail", V(0.5, 0.2, 0.05), V(0, 3.05, -0.42), SKIN) -- open collar
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.44, 0.55, 0.48), V(s * 0.95, 2.8, 0), SHIRT)
	b:B(name, V(0.36, 0.85, 0.4), V(s * 0.95, 2.1, 0), SKIN)
end
b:B("RightUpperArm", V(0.4, 0.6, 0.4), V(0.95, 1.85, -0.35), Color3.fromHex("ff8ab0")) -- smoothie
b:B("RightUpperArm", V(0.06, 0.4, 0.06), V(1.02, 2.3, -0.35), C.White, V(0, 0, -15))
b:B(H, V(1.1, 1.15, 1.0), V(0, 3.7, 0), SKIN)
b:B(H, V(1.16, 0.3, 1.06), V(0, 4.38, 0), CAP)
b:B(H, V(0.9, 0.08, 0.5), V(0, 4.26, -0.7), CAP)
b:B(H, V(0.9, 0.18, 0.08), V(0, 4.5, -0.52), Color3.fromHex("1c1c20")) -- sunglasses on the cap
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, 3.8, -0.51), 0.3, V(0, 0, -1), Vector2.new(0, 0))
	b:B("HeadDetail", V(0.28, 0.1, 0.04), V(s * 0.25, 3.92, -0.53), SKIN) -- relaxed half-lids
end
b:mouth(V(0, 3.42, -0.51), 0.36, 0.1, V(0, 0, -1), 0, 20)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
