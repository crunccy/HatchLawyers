-- Chimpanzini Bananini (Uncommon, Brainrot egg) - block remake 2026-10-10. Reference: the meme character - a little
-- chimpanzee standing inside a peeled banana. The bottom half is a yellow banana (with a brown stalk tip at the
-- bottom) whose peel flaps hang down around it; the chimp's body, arms and head pop out of the top. Front-facing.
-- Uncommon: 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("ChimpanziniBananini")
local V = Vector3.new
local C = Kit.C
local PEEL, PEEL_DARK, FLESH, STALK = Color3.fromRGB(255, 220, 60), Color3.fromHex("e0b830"), Color3.fromHex("fff4c8"), Color3.fromHex("6b4426")
local FUR, FUR_DARK, FACE = Color3.fromRGB(110, 70, 40), Color3.fromHex("5a3820"), Color3.fromHex("e8c49a")
local T, H = "UpperTorso", "Head"

-- banana bottom: tapering stack, brown stalk tip, pale flesh inside the top
b:B("LeftUpperLeg", V(0.3, 0.35, 0.3), V(0, 0.18, 0), STALK)
b:B("LeftUpperLeg", V(0.7, 0.5, 0.7), V(0, 0.55, 0), PEEL)
b:B("LeftUpperLeg", V(1.0, 0.6, 1.0), V(0, 1.05, 0), PEEL)
b:B(T, V(1.2, 0.5, 1.2), V(0, 1.55, 0), PEEL)
b:B(T, V(1.0, 0.12, 1.0), V(0, 1.84, 0), FLESH)
for _, x in { -0.3, 0.3 } do
	b:B("HeadDetail", V(0.06, 1.1, 0.04), V(x, 1.15, -0.55), PEEL_DARK)
end
-- peel flaps hanging down on 4 sides
for i = 0, 3 do
	local a = i / 4 * math.pi * 2 + math.pi / 4
	local x, z = math.sin(a) * 0.75, math.cos(a) * 0.75
	b:B(T, V(0.5, 0.9, 0.12), V(x, 1.55, z), PEEL, V(0, math.deg(a), 0) + V(0, 0, 0))
	b:B(T, V(0.42, 0.12, 0.14), V(x * 1.05, 1.08, z * 1.05), PEEL_DARK, V(0, math.deg(a), 0))
end
-- chimp body popping out the top
b:B(T, V(1.0, 1.0, 0.8), V(0, 2.35, 0), FUR)
b:B("HeadDetail", V(0.6, 0.6, 0.05), V(0, 2.3, -0.42), FACE)
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.32, 1.1, 0.34), V(s * 0.7, 2.25, -0.1), FUR, V(0, 0, s * 25))
	b:B(name, V(0.34, 0.3, 0.34), V(s * 0.95, 1.75, -0.25), FACE)
end
-- head: fur, big ears, pale face + muzzle, happy grin
b:B(H, V(1.2, 1.05, 1.0), V(0, 3.35, 0), FUR)
b:B(H, V(0.9, 0.7, 0.06), V(0, 3.38, -0.51), FACE)
b:B(H, V(0.7, 0.4, 0.3), V(0, 3.05, -0.6), FACE)
for _, s in { -1, 1 } do
	b:B(H, V(0.3, 0.45, 0.2), V(s * 0.72, 3.4, 0), FACE)
	b:eye(V(s * 0.2, 3.5, -0.55), 0.28, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.22, 3.75, -0.55), 0.28, V(0, 0, -1), s * -6, FUR_DARK)
	b:B("HeadDetail", V(0.06, 0.06, 0.03), V(s * 0.07, 3.15, -0.76), FUR_DARK) -- nostrils
end
b:mouth(V(0, 2.96, -0.76), 0.4, 0.12, V(0, 0, -1), 5, 20)
b:B(H, V(0.5, 0.2, 0.5), V(0, 3.92, 0), FUR_DARK) -- tuft
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
