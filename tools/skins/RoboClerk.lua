-- Robo Rex (Uncommon, Space egg) - block remake 2026-10-10. A boxy silver robot clerk: a square head with a dark
-- screen face (glowing green eyes + a pixel smile), an antenna, bolt "ears", a box body with a dial + buttons, stubby
-- piston arms with claw hands holding a clipboard, and a single wheel base instead of legs. Front-facing.
-- Uncommon: 1 prop, tiny Neon eyes, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("RoboClerk")
local V = Vector3.new
local C = Kit.C
local METAL, METAL_DARK, SCREEN, GLOW = Color3.fromHex("bec8d7"), Color3.fromHex("8a94a6"), Color3.fromHex("1c2230"), Color3.fromHex("6cff8a")
local CLIP, PAPER = Color3.fromHex("8a5a2e"), Color3.fromHex("f5f5f5")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"

-- wheel base
b:B("LeftUpperLeg", V(0.5, 0.7, 0.7), V(0, 0.35, 0), Color3.fromHex("2a2a30"))
b:B("LeftUpperLeg", V(0.56, 0.3, 0.3), V(0, 0.35, 0), METAL_DARK)
b:B("LeftUpperLeg", V(1.0, 0.3, 0.8), V(0, 0.85, 0), METAL_DARK)
b:B("LeftUpperLeg", V(0.4, 0.4, 0.4), V(0, 1.15, 0), METAL)
-- box body with a dial and buttons
b:B(T, V(1.6, 1.5, 1.1), V(0, 2.05, 0), METAL)
b:B(T, V(1.64, 0.12, 1.14), V(0, 1.4, 0), METAL_DARK)
b:B("HeadDetail", V(0.45, 0.45, 0.05), V(-0.35, 2.2, -0.57), METAL_DARK)
b:B("HeadDetail", V(0.06, 0.2, 0.04), V(-0.35, 2.27, -0.6), C.Line, V(0, 0, -30))
for i, col in { Color3.fromHex("e0303a"), Color3.fromHex("ffd23f"), Color3.fromHex("2f7bff") } do
	b:B("HeadDetail", V(0.16, 0.16, 0.05), V(0.25 + (i - 1) * 0.22, 2.2, -0.57), col)
end
b:B("HeadDetail", V(0.9, 0.08, 0.04), V(0.0, 1.75, -0.57), METAL_DARK)
-- piston arms with claws + a clipboard
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.3, 0.3, 0.3), V(s * 0.95, 2.5, 0), METAL_DARK)
	b:B(name, V(0.2, 0.8, 0.2), V(s * 1.05, 2.05, -0.1), METAL)
	b:B(name, V(0.3, 0.12, 0.3), V(s * 1.05, 1.6, -0.15), METAL_DARK)
	b:B(name, V(0.08, 0.2, 0.08), V(s * 1.05 - 0.08, 1.45, -0.15), METAL_DARK)
	b:B(name, V(0.08, 0.2, 0.08), V(s * 1.05 + 0.08, 1.45, -0.15), METAL_DARK)
end
b:B("LeftUpperArm", V(0.6, 0.8, 0.06), V(-1.05, 1.65, -0.45), CLIP, V(-15, 0, 0))
b:B("LeftUpperArm", V(0.5, 0.6, 0.03), V(-1.05, 1.62, -0.5), PAPER, V(-15, 0, 0))
b:B("LeftUpperArm", V(0.3, 0.08, 0.05), V(-1.05, 2.0, -0.55), METAL_DARK, V(-15, 0, 0))
-- square head: screen face, antenna, bolts
b:B(H, V(1.4, 1.1, 1.1), V(0, 3.4, 0), METAL)
b:B(H, V(1.1, 0.8, 0.06), V(0, 3.4, -0.56), SCREEN)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.2, 0.26, 0.04), V(s * 0.25, 3.5, -0.6), GLOW, nil, NEON)
	b:B(H, V(0.16, 0.3, 0.3), V(s * 0.76, 3.4, 0), METAL_DARK)
end
for i = -2, 2 do -- pixel smile
	b:B("HeadDetail", V(0.1, 0.08, 0.03), V(i * 0.1, 3.18 - (if math.abs(i) == 2 then -0.06 else 0), -0.6), GLOW, nil, NEON)
end
b:B(H, V(0.08, 0.5, 0.08), V(0, 4.15, 0), METAL_DARK)
b:B(H, V(0.2, 0.2, 0.2), V(0, 4.45, 0), Color3.fromHex("e0303a"))
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
