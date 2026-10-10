-- Neon Litigator (Rare) - block remake 2026-10-10. A tall, lean cyberpunk lawyer: dark suit with glowing cyan trim
-- (lapels, cuffs, hem), a wraparound Neon visor instead of shades, spiky slicked-up black hair with a cyan streak,
-- a confident smirk, a glowing see-through holo-briefcase, sneakers with glowing soles. Front-facing.
-- Rare: Neon is the theme here, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("NeonLitigator")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_DARK, SKIN, HAIR = Color3.fromHex("23232f"), Color3.fromHex("16161e"), Color3.fromHex("e8b48a"), Color3.fromHex("141418")
local CYAN, MAGENTA = Color3.fromHex("00ffc8"), Color3.fromHex("ff3cc8")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"

-- long legs, sneakers with glowing soles
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.42, 1.8, 0.48), V(s * 0.28, 1.25, 0), SUIT_DARK)
	b:B(name, V(0.5, 0.3, 0.78), V(s * 0.28, 0.2, -0.12), C.White)
	b:B(name, V(0.52, 0.08, 0.8), V(s * 0.28, 0.04, -0.12), CYAN, nil, NEON)
end
-- lean suit jacket with glowing trim
b:B(T, V(1.3, 1.7, 0.75), V(0, 3.0, 0), SUIT)
b:B(T, V(1.34, 0.08, 0.79), V(0, 2.18, 0), CYAN, nil, NEON)
b:B("HeadDetail", V(0.42, 1.1, 0.05), V(0, 3.25, -0.39), SUIT_DARK) -- dark shirt
b:B("HeadDetail", V(0.12, 0.9, 0.04), V(0, 3.15, -0.42), MAGENTA, nil, NEON) -- glowing tie
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.06, 1.0, 0.05), V(s * 0.26, 3.3, -0.4), CYAN, V(0, 0, s * 12), NEON) -- lapel lines
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.38, 1.55, 0.45), V(s * 0.85, 2.95, 0), SUIT)
	b:B(name, V(0.4, 0.08, 0.47), V(s * 0.85, 2.2, 0), CYAN, nil, NEON) -- cuff
	b:B(name, V(0.34, 0.3, 0.38), V(s * 0.85, 2.0, 0), SKIN)
end
-- holo-briefcase: glowing see-through box with a solid handle
local cs = b:B("RightUpperArm", V(0.85, 0.6, 0.26), V(0.85, 1.5, -0.05), CYAN, nil, NEON)
cs.Transparency = 0.45
b:B("RightUpperArm", V(0.3, 0.1, 0.08), V(0.85, 1.85, -0.05), SUIT_DARK)
-- head, spiky hair with a cyan streak, visor, smirk
b:B(H, V(1.1, 1.1, 1.0), V(0, 4.45, 0), SKIN)
b:B(H, V(1.16, 0.3, 1.06), V(0, 5.08, 0.02), HAIR)
for i = -2, 2 do
	b:B(H, V(0.22, 0.35 + (2 - math.abs(i)) * 0.08, 0.5), V(i * 0.22, 5.35 + (2 - math.abs(i)) * 0.04, 0.1), HAIR, V(-20, 0, i * -8))
end
b:B(H, V(0.22, 0.4, 0.5), V(0.22, 5.42, 0.1), CYAN, V(-20, 0, -8), NEON) -- the streak
b:B(H, V(1.16, 0.6, 0.3), V(0, 4.8, 0.4), HAIR)
b:B(H, V(1.2, 0.3, 0.12), V(0, 4.55, -0.52), CYAN, nil, NEON) -- visor across the eyes
for _, s in { -1, 1 } do
	b:B(H, V(0.1, 0.24, 0.9), V(s * 0.58, 4.55, -0.05), SUIT_DARK) -- visor arms
end
b:mouth(V(0.08, 4.12, -0.5), 0.34, 0.08, V(0, 0, -1), 0, 22)
-- extra glow detail: trouser stripes, jacket circuit lines, earpiece, a floating holo scales-of-justice icon
for _, s in { -1, 1 } do
	b:B(s < 0 and "LeftUpperLeg" or "RightUpperLeg", V(0.05, 1.6, 0.05), V(s * 0.5, 1.3, -0.1), CYAN, nil, NEON)
	b:B("HeadDetail", V(0.04, 0.5, 0.04), V(s * 0.55, 2.7, -0.39), CYAN, nil, NEON)
	b:B("HeadDetail", V(0.2, 0.04, 0.04), V(s * 0.46, 2.47, -0.39), CYAN, nil, NEON)
end
b:B(H, V(0.12, 0.2, 0.2), V(-0.6, 4.3, 0), MAGENTA, nil, NEON)
local holo = V(-1.25, 4.6, -0.2)
for _, part in { { V(0.06, 0.6, 0.04), V(0, 0, 0) }, { V(0.8, 0.05, 0.04), V(0, 0.28, 0) }, { V(0.3, 0.05, 0.04), V(-0.38, 0.0, 0) },
	{ V(0.3, 0.05, 0.04), V(0.38, 0.0, 0) }, { V(0.04, 0.26, 0.04), V(-0.38, 0.15, 0) }, { V(0.04, 0.26, 0.04), V(0.38, 0.15, 0) },
	{ V(0.36, 0.05, 0.04), V(0, -0.3, 0) } } do
	local p = b:B(T, part[1], holo + part[2], CYAN, nil, NEON)
	p.Transparency = 0.25
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
