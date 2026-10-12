-- Polly Parrot (Rare, Pet egg) - block remake 2026-10-10. A tall scarlet macaw standing upright: red body and
-- head, white face patch, a big hooked beak (pale top, black bottom), blue + yellow layered wings at the sides, long
-- red/blue tail feathers behind, grey grippy feet, a white shirt collar with a blue tie, and an "OBJECTION!" speech
-- bubble (white bubble, red "!") floating by its head. Front-facing. Rare: Neon-yellow wing tips, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("ParrotProsecutor")
local V = Vector3.new
local C = Kit.C
local RED, RED_DARK, BLUE, YELLOW = Color3.fromHex("e62828"), Color3.fromHex("b81c20"), Color3.fromHex("286ee6"), Color3.fromHex("ffd23f")
local BEAK, BEAK_DARK, FACE, FEET = Color3.fromHex("f0e6d2"), Color3.fromHex("2a2a30"), Color3.fromHex("fafafa"), Color3.fromHex("8a8a94")
local T, H = "UpperTorso", "Head"

-- feet + short legs
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.22, 0.5, 0.22), V(s * 0.35, 0.4, 0), FEET)
	for t = -1, 1 do
		b:B(name, V(0.12, 0.1, 0.4), V(s * 0.35 + t * 0.13, 0.05, -0.15), FEET, V(0, t * 15, 0))
	end
end
-- body: a tall egg-ish stack, lighter belly
b:B(T, V(1.3, 1.0, 1.1), V(0, 1.1, 0), RED)
b:B(T, V(1.4, 1.1, 1.2), V(0, 2.0, 0), RED)
b:B(T, V(0.9, 1.4, 0.1), V(0, 1.6, -0.6), Color3.fromHex("f04040"))
-- shirt collar + blue tie
b:B("HeadDetail", V(0.6, 0.2, 0.06), V(0, 2.5, -0.62), C.White)
b:B("HeadDetail", V(0.18, 0.5, 0.05), V(0, 2.18, -0.65), BLUE)
b:B("HeadDetail", V(0.22, 0.14, 0.05), V(0, 2.45, -0.66), BLUE)
-- head: red block with a white face patch, round eyes, hooked beak
b:B(H, V(1.3, 1.2, 1.2), V(0, 3.15, 0), RED)
b:B(H, V(1.0, 0.18, 1.0), V(0, 3.82, 0.05), RED_DARK) -- little crest
b:B(H, V(0.3, 0.3, 0.3), V(0, 3.98, 0.15), RED_DARK)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.5, 0.6, 0.05), V(s * 0.36, 3.2, -0.61), FACE)
	b:eye(V(s * 0.36, 3.28, -0.64), 0.34, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.38, 3.56, -0.65), 0.34, V(0, 0, -1), s * 18, RED_DARK) -- stern prosecutor brows
end
b:B(H, V(0.42, 0.45, 0.5), V(0, 3.05, -0.8), BEAK)          -- upper beak
b:B(H, V(0.36, 0.3, 0.22), V(0, 2.82, -1.0), BEAK, V(-30, 0, 0)) -- hook
b:B(H, V(0.34, 0.2, 0.36), V(0, 2.7, -0.72), BEAK_DARK)     -- lower beak
-- wings: layered red/yellow/blue blocks down the sides, Neon tips
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.3, 1.1, 1.0), V(s * 0.82, 2.0, 0.05), RED)
	b:B(name, V(0.3, 0.4, 0.95), V(s * 0.86, 1.35, 0.1), YELLOW)
	b:B(name, V(0.28, 0.75, 0.9), V(s * 0.88, 0.85, 0.15), BLUE)
	b:B(name, V(0.24, 0.2, 0.6), V(s * 0.9, 0.38, 0.2), YELLOW, nil, Enum.Material.Neon)
	b:B(name, V(0.32, 0.22, 0.08), V(s * 0.83, 1.75, -0.48), YELLOW) -- wing colours showing from the front
	b:B(name, V(0.32, 0.5, 0.08), V(s * 0.83, 1.38, -0.48), BLUE)
end
-- long tail feathers behind
b:B(T, V(0.5, 1.6, 0.2), V(-0.12, 0.6, 0.65), RED_DARK, V(-15, 0, 0))
b:B(T, V(0.4, 1.4, 0.2), V(0.22, 0.6, 0.72), BLUE, V(-15, 0, 0))
-- OBJECTION! bubble floating by the head
b:B(H, V(0.9, 0.7, 0.12), V(-1.25, 4.1, 0), C.White)
b:B(H, V(0.25, 0.25, 0.12), V(-0.9, 3.7, 0), C.White, V(0, 0, 45))
b:B("HeadDetail", V(0.12, 0.34, 0.04), V(-1.25, 4.18, -0.08), RED)
b:B("HeadDetail", V(0.12, 0.12, 0.04), V(-1.25, 3.88, -0.08), RED)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
