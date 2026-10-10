-- Khaby Claim (Rare) - block remake 2026-10-10. A GENERIC deadpan "it's that simple" lawyer (original design -
-- deliberately no real person's likeness): a grey suit with a dark tie, both arms out in an open-palms shrug, a flat
-- unimpressed face with raised brows, and a little glowing lightbulb idea floating overhead. Front-facing.
-- Rare: Neon bulb, 1.05x. Colours follow the catalog entry.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("KhabyClaim")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_DARK, TIE = Color3.fromRGB(120, 124, 132), Color3.fromRGB(60, 62, 70), Color3.fromRGB(30, 30, 34)
local SKIN, HAIR = Color3.fromRGB(108, 70, 48), Color3.fromHex("1c1c20")
local T, H = "UpperTorso", "Head"

-- legs + shoes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.48, 1.6, 0.52), V(s * 0.3, 1.1, 0), SUIT_DARK)
	b:B(name, V(0.52, 0.26, 0.8), V(s * 0.3, 0.13, -0.12), C.Line)
end
-- suit: jacket, shirt, dark tie, lapels, pocket square
b:B(T, V(1.55, 1.6, 0.85), V(0, 2.7, 0), SUIT)
b:B(T, V(1.58, 0.16, 0.88), V(0, 1.95, 0), SUIT_DARK)
b:B("HeadDetail", V(0.5, 1.1, 0.05), V(0, 2.95, -0.44), C.White)
b:B("HeadDetail", V(0.16, 0.9, 0.04), V(0, 2.85, -0.47), TIE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.16, 0.9, 0.05), V(s * 0.33, 3.0, -0.45), SUIT_DARK, V(0, 0, s * 15))
end
b:B("HeadDetail", V(0.24, 0.12, 0.05), V(0.5, 3.1, -0.45), C.White)
b:B("HeadDetail", V(0.1, 0.1, 0.04), V(0, 2.2, -0.45), C.Line)
-- the shrug: upper arms down/out, forearms out to the sides, open palms up
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.42, 0.9, 0.46), V(s * 1.0, 3.0, 0), SUIT, V(0, 0, s * 15))
	b:B(name, V(0.9, 0.38, 0.42), V(s * 1.5, 2.55, -0.25), SUIT)
	b:B(name, V(0.08, 0.4, 0.44), V(s * 1.94, 2.55, -0.25), C.White) -- cuff
	b:B(name, V(0.5, 0.12, 0.5), V(s * 2.2, 2.62, -0.25), SKIN)      -- open palm, facing up
	b:B(name, V(0.1, 0.18, 0.12), V(s * 2.0, 2.74, -0.48), SKIN)     -- thumb
end
-- head: flat deadpan face, raised brows, short hair cap
b:B(H, V(1.2, 1.25, 1.1), V(0, 4.15, 0), SKIN)
b:B(H, V(1.24, 0.25, 1.14), V(0, 4.85, 0.02), HAIR)
b:B(H, V(1.24, 0.4, 0.2), V(0, 4.6, 0.5), HAIR)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.27, 4.2, -0.56), 0.34, V(0, 0, -1), Vector2.new(0, -0.08))
	b:B("HeadDetail", V(0.36, 0.1, 0.04), V(s * 0.27, 4.33, -0.58), SKIN) -- half-lidded, unimpressed
	b:brow(V(s * 0.29, 4.5, -0.57), 0.34, V(0, 0, -1), s * -12, HAIR)
	b:B(H, V(0.14, 0.3, 0.24), V(s * 0.62, 4.15, 0), SKIN)
end
b:mouth(V(0, 3.78, -0.56), 0.4, 0.06, V(0, 0, -1), 0, 0)
-- the lightbulb idea floating overhead
b:B(H, V(0.4, 0.4, 0.4), V(0.75, 5.55, -0.2), Color3.fromHex("ffe86a"), nil, Enum.Material.Neon)
b:B(H, V(0.24, 0.16, 0.24), V(0.75, 5.27, -0.2), Color3.fromHex("a0a0a8"))
for _, r in { { 0.4, 0, 90 }, { -0.4, 0, 90 }, { 0, 0.4, 0 } } do
	b:B(H, V(0.05, 0.16, 0.05), V(0.75 + r[1], 5.6 + r[2], -0.2), Color3.fromHex("ffe86a"), V(0, 0, r[3]), Enum.Material.Neon)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
