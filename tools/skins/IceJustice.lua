-- Ice Cold (Legendary) - block remake 2026-10-10. A big chunky ice golem judge: stacked pale-blue ice blocks
-- (a few slightly see-through shards), jagged crystal shoulders, glowing cyan eyes, a white judge's jabot, a navy
-- frost robe hanging open over the ice chest with a white frosted hem, a gold crown ringed with glowing icicles, and
-- a huge ice gavel held up. Front-facing. Legendary: Neon ice glints + gold, 1.25x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("IceJustice")
local V = Vector3.new
local C = Kit.C
local ICE, ICE_DARK, ICE_LIGHT = Color3.fromHex("a8e4ff"), Color3.fromHex("6cc4f0"), Color3.fromHex("dff6ff")
local GLOW, CAPE, CAPE_DARK, FROST = Color3.fromHex("7ff4ff"), Color3.fromHex("2b4a8a"), Color3.fromHex("1d3466"), Color3.fromHex("f4fbff")
local BROW = Color3.fromHex("2f6fa8")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"
local function shard(name, size, pos, rot)
	local p = b:B(name, size, pos, ICE_LIGHT, rot)
	p.Transparency = 0.25
	return p
end

-- legs: chunky ice pillars with darker feet
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.75, 1.0, 0.8), V(s * 0.55, 0.75, 0), ICE)
	b:B(name, V(0.85, 0.3, 0.95), V(s * 0.55, 0.15, -0.05), ICE_DARK)
end
-- torso: a big block with a lighter chest plate, cracks, and the white jabot
b:B(T, V(2.4, 1.85, 1.4), V(0, 2.15, 0), ICE)
b:B(T, V(2.0, 1.2, 0.1), V(0, 2.35, -0.72), ICE_LIGHT)
b:B(T, V(2.44, 0.3, 1.44), V(0, 1.3, 0), ICE_DARK)                       -- belt of darker ice
b:B(T, V(0.4, 0.3, 0.06), V(0, 1.3, -0.74), C.Gold)                       -- gold belt buckle
b:B(T, V(0.05, 0.6, 0.04), V(-0.35, 2.1, -0.78), ICE_DARK, V(0, 0, 25))   -- cracks
b:B(T, V(0.05, 0.4, 0.04), V(0.4, 2.5, -0.78), ICE_DARK, V(0, 0, -30))
b:B("HeadDetail", V(0.5, 0.55, 0.06), V(0, 2.75, -0.8), FROST)           -- jabot (judge's neck frill)
b:B("HeadDetail", V(0.36, 0.2, 0.06), V(0, 2.4, -0.81), FROST)
-- head: a chunky ice block, darker jaw, glowing eyes, scowl
b:B(H, V(1.4, 1.2, 1.2), V(0, 3.65, 0), ICE)
b:B(H, V(1.3, 0.3, 1.24), V(0, 3.18, 0), ICE_DARK)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.32, 3.75, -0.61), 0.4, V(0, 0, -1), Vector2.new(0, 0), Color3.fromHex("1aa0d8"))
	b:brow(V(s * 0.34, 4.05, -0.62), 0.46, V(0, 0, -1), s * 14, BROW)
end
b:mouth(V(0, 3.3, -0.63), 0.62, 0.14, V(0, 0, -1), 6, 0)
-- crown: gold band with a ring of glowing icicles
b:B(H, V(1.5, 0.22, 1.3), V(0, 4.36, 0), C.Gold)
b:B(H, V(1.54, 0.06, 1.34), V(0, 4.26, 0), C.GoldDark)
for i = -2, 2 do
	local h = 0.6 - math.abs(i) * 0.12
	b:B(H, V(0.2, h, 0.2), V(i * 0.3, 4.47 + h / 2, -0.55), GLOW, V(0, 45, 0), NEON)
end
for _, x in { -0.6, 0.6 } do
	b:B(H, V(0.18, 0.4, 0.18), V(x, 4.67, 0.1), GLOW, V(0, 45, 0), NEON)
end
b:B("HeadDetail", V(0.2, 0.2, 0.06), V(0, 4.36, -0.67), Color3.fromHex("3fb8ff"), V(0, 0, 45), NEON) -- gem
-- arms: big shoulder blocks with crystal shards, forearms, fists
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.9, 0.85, 0.95), V(s * 1.6, 2.75, 0), ICE_DARK)
	shard(name, V(0.3, 0.7, 0.3), V(s * 1.7, 3.35, 0.05), V(10, 30, s * -20))
	shard(name, V(0.22, 0.5, 0.22), V(s * 1.4, 3.25, 0.25), V(-15, 15, s * 15))
	b:B(name, V(0.7, 1.0, 0.75), V(s * 1.62, 1.95, -0.05), ICE)
	b:B(name, V(0.82, 0.7, 0.82), V(s * 1.62, 1.2, -0.1), ICE_LIGHT)
end
-- ice gavel held up in one fist: handle rising from the fist, big pale head with gold bands + a glowing core
b:B("RightUpperArm", V(0.18, 1.6, 0.18), V(1.62, 1.95, -0.62), ICE_DARK)
b:B("RightUpperArm", V(1.0, 0.5, 0.5), V(1.62, 2.95, -0.62), ICE_LIGHT)
b:B("RightUpperArm", V(0.1, 0.54, 0.54), V(1.17, 2.95, -0.62), C.Gold)
b:B("RightUpperArm", V(0.1, 0.54, 0.54), V(2.07, 2.95, -0.62), C.Gold)
b:B("RightUpperArm", V(0.3, 0.3, 0.3), V(1.62, 2.95, -0.89), GLOW, V(0, 0, 45), NEON)
-- frost robe: navy panel down the back, sides, open front panels with white piping, frosted hem, gold clasps
b:B(T, V(2.6, 2.6, 0.12), V(0, 1.95, 0.78), CAPE)
for _, s in { -1, 1 } do
	b:B(T, V(0.12, 2.1, 0.9), V(s * 1.27, 2.2, 0.35), CAPE_DARK)
	b:B(T, V(0.42, 1.65, 0.08), V(s * 0.98, 2.15, -0.74), CAPE)
	b:B(T, V(0.08, 1.65, 0.1), V(s * 0.75, 2.15, -0.75), FROST)
	b:B(T, V(0.3, 0.3, 0.12), V(s * 0.95, 2.95, -0.8), C.Gold)
end
for i = -3, 3 do
	b:B(T, V(0.36, 0.2 + (i % 2) * 0.12, 0.16), V(i * 0.37, 0.6 - (i % 2) * 0.06, 0.8), FROST)
end
b:B(T, V(2.7, 0.24, 1.6), V(0, 3.15, 0.05), FROST) -- frosty fur collar
-- floating snowflake glints
for _, st in { { -2.3, 4.2, -0.3 }, { 2.4, 3.9, 0.2 }, { -2.1, 1.0, -0.5 } } do
	b:B(T, V(0.16, 0.16, 0.16), V(st[1], st[2], st[3]), GLOW, V(0, 45, 45), NEON)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.25)
print(b:preview())
_G.SkinBuild = b
