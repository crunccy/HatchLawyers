-- Sushi Solicitor (Uncommon, Food egg) - block remake 2026-10-10. A walking maki roll: a dark-green nori-wrapped
-- body with white rice showing at the top ring and a salmon + cucumber centre on top, face on the nori, little black
-- legs, thin arms, a pair of wooden chopsticks held like a pointer. Front-facing. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("SushiSolicitor")
local V = Vector3.new
local C = Kit.C
local NORI, NORI_DARK, RICE, SALMON, CUKE = Color3.fromHex("1e3c28"), Color3.fromHex("142a1c"), Color3.fromHex("faf8f2"), Color3.fromHex("ff8a5a"), Color3.fromHex("7ac850")
local CHOP, BLACK = Color3.fromHex("d8b07a"), Color3.fromHex("1c1c20")
local T, H = "UpperTorso", "Head"

for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.2, 0.8, 0.2), V(s * 0.4, 0.5, 0), BLACK)
	b:B(name, V(0.42, 0.18, 0.6), V(s * 0.42, 0.09, -0.1), BLACK)
end
-- the roll (rounded: two crossed slabs), nori seam, rice ring + filling on top
b:B(T, V(2.0, 2.4, 1.6), V(0, 2.1, 0), NORI)
b:B(T, V(1.6, 2.4, 2.0), V(0, 2.1, 0), NORI)
b:B(T, V(0.06, 2.3, 0.05), V(0.75, 2.1, -1.01), NORI_DARK)
b:B(H, V(1.8, 0.22, 1.4), V(0, 3.38, 0), RICE)
b:B(H, V(1.4, 0.22, 1.8), V(0, 3.38, 0), RICE)
for _, g in { { -0.6, -0.5 }, { 0.5, -0.6 }, { -0.5, 0.55 }, { 0.6, 0.4 } } do
	b:B(H, V(0.22, 0.12, 0.16), V(g[1], 3.52, g[2]), RICE) -- rice grains
end
b:B(H, V(0.75, 0.22, 0.75), V(-0.1, 3.52, 0), SALMON)
b:B(H, V(0.3, 0.24, 0.3), V(0.35, 3.54, 0.2), CUKE)
-- face on the nori
for _, s in { -1, 1 } do
	b:eye(V(s * 0.4, 2.6, -1.01), 0.42, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.42, 2.92, -1.02), 0.4, V(0, 0, -1), s * 8, Color3.fromHex("5a7a64"))
	b:B("HeadDetail", V(0.22, 0.1, 0.04), V(s * 0.66, 2.32, -1.01), Color3.fromHex("ff9aa8"))
end
b:mouth(V(0, 2.15, -1.01), 0.44, 0.12, V(0, 0, -1), 4, 18)
-- arms + chopsticks
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.16, 0.16), V(s * 1.25, 2.0, -0.1), BLACK, V(0, 0, s * -25))
	b:B(name, V(0.28, 0.28, 0.28), V(s * 1.52, 2.18, -0.15), C.White)
end
b:B("RightUpperArm", V(0.07, 1.3, 0.07), V(1.52, 2.6, -0.35), CHOP, V(-30, 0, -10))
b:B("RightUpperArm", V(0.07, 1.3, 0.07), V(1.62, 2.6, -0.35), CHOP, V(-30, 0, -14))
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
