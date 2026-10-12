-- Corgi Cooper (Rare, Pet egg) - block remake 2026-10-10. A short, chunky corgi standing upright: orange and white
-- coat, huge pointy ears (pink inside), white muzzle + blaze, black nose, tongue out, a navy vest over a white shirt
-- with a red bow tie, stubby legs, a fluffy white butt-floof, a little brown briefcase. Front-facing.
-- Rare: small Neon dog tag, 1.0x (corgis are short).
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("CorgiCounsel")
local V = Vector3.new
local C = Kit.C
local ORANGE, ORANGE_DARK, CREAM, PINK = Color3.fromHex("e68c3c"), Color3.fromHex("c46f26"), Color3.fromHex("faf5eb"), Color3.fromHex("f2a0b0")
local VEST, RED, CASE = Color3.fromHex("23305e"), Color3.fromHex("d62a36"), Color3.fromHex("7a4a26")
local T, H = "UpperTorso", "Head"

-- stubby legs: orange with white paws
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.45, 0.45, 0.5), V(s * 0.4, 0.42, 0), ORANGE)
	b:B(name, V(0.5, 0.22, 0.62), V(s * 0.4, 0.11, -0.06), CREAM)
end
-- chunky body: orange back + sides, white chest, navy vest, shirt + bow tie
b:B(T, V(1.5, 1.4, 1.2), V(0, 1.35, 0), ORANGE)
b:B(T, V(1.0, 1.3, 0.1), V(0, 1.38, -0.62), CREAM)
for _, s in { -1, 1 } do
	b:B(T, V(0.42, 1.0, 0.1), V(s * 0.55, 1.35, -0.64), VEST)
	b:B("HeadDetail", V(0.08, 0.08, 0.04), V(s * 0.42, 1.15 + 0.0, -0.7), C.Gold) -- vest buttons
end
b:B(T, V(1.52, 0.2, 1.22), V(0, 0.8, 0), VEST) -- vest hem
b:W("HeadDetail", V(0.05, 0.22, 0.2), V(-0.13, 2.0, -0.7), RED, V(0, 90, 90))
b:W("HeadDetail", V(0.05, 0.22, 0.2), V(0.13, 2.0, -0.7), RED, V(0, -90, -90))
b:B("HeadDetail", V(0.12, 0.12, 0.06), V(0, 2.0, -0.71), RED)
-- butt-floof + nub tail
b:B(T, V(1.2, 0.7, 0.3), V(0, 0.95, 0.7), CREAM)
b:B(T, V(0.3, 0.25, 0.25), V(0, 1.35, 0.78), ORANGE)
-- head: orange with a white blaze + muzzle, black nose, tongue
b:B(H, V(1.5, 1.2, 1.2), V(0, 2.7, 0), ORANGE)
b:B(H, V(0.36, 1.0, 0.06), V(0, 2.75, -0.61), CREAM)
b:B(H, V(0.9, 0.5, 0.45), V(0, 2.32, -0.75), CREAM)
b:B(H, V(0.3, 0.2, 0.1), V(0, 2.52, -0.99), C.Line)
b:mouth(V(0, 2.22, -0.98), 0.4, 0.1, V(0, 0, -1), 0, 18)
b:B("HeadDetail", V(0.18, 0.22, 0.05), V(0.06, 2.06, -0.98), C.Tongue)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.4, 2.85, -0.61), 0.38, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.42, 3.15, -0.62), 0.32, V(0, 0, -1), s * -8, ORANGE_DARK)
	b:B("HeadDetail", V(0.2, 0.1, 0.04), V(s * 0.62, 2.55, -0.61), PINK) -- blush
	-- huge pointy ears, stepped, pink inside
	b:B(H, V(0.55, 0.5, 0.3), V(s * 0.5, 3.5, 0.05), ORANGE)
	b:B(H, V(0.4, 0.4, 0.28), V(s * 0.56, 3.9, 0.05), ORANGE)
	b:B(H, V(0.22, 0.3, 0.26), V(s * 0.6, 4.22, 0.05), ORANGE)
	b:B("HeadDetail", V(0.3, 0.55, 0.04), V(s * 0.53, 3.7, -0.11), PINK)
end
-- collar + Neon tag (Rare accent)
b:B(T, V(1.3, 0.14, 1.1), V(0, 2.12, 0), RED)
b:B("HeadDetail", V(0.16, 0.16, 0.06), V(0.4, 2.0, -0.58), Color3.fromHex("5ff2ff"), V(0, 0, 45), Enum.Material.Neon)
-- arms: short, orange with white paws; one holds a briefcase
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.36, 0.75, 0.4), V(s * 0.92, 1.55, -0.05), ORANGE, V(0, 0, s * 10))
	b:B(name, V(0.38, 0.26, 0.42), V(s * 0.98, 1.1, -0.05), CREAM)
end
b:B("RightUpperArm", V(0.24, 0.12, 0.08), V(0.98, 0.92, -0.05), C.Line)        -- handle
b:B("RightUpperArm", V(0.75, 0.55, 0.22), V(0.98, 0.58, -0.05), CASE)
b:B("RightUpperArm", V(0.12, 0.1, 0.03), V(0.98, 0.7, -0.17), C.Gold)          -- clasp
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
