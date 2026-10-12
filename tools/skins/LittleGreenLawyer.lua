-- Little Green Zip (Common, Space egg) - block remake 2026-10-10. A classic little green alien in a black suit: a
-- big wide head with huge glossy black eyes, two antennae, a small body in a black suit + green tie, a tiny briefcase.
-- (Full-bodied + suited, unlike the Ziggy UFO's pilot.) Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("LittleGreenLawyer")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local GREEN, GREEN_DARK, SUIT = Color3.fromRGB(110, 220, 90), Color3.fromHex("4ea83a"), Color3.fromRGB(40, 40, 50)
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.3, 1.0, 0.34), V(s * 0.22, 0.7, 0), SUIT)
	b:B(name, V(0.34, 0.2, 0.5), V(s * 0.22, 0.1, -0.08), GREEN_DARK)
end
b:B(T, V(1.0, 1.1, 0.6), V(0, 1.75, 0), SUIT)
b:B("HeadDetail", V(0.3, 0.7, 0.05), V(0, 1.9, -0.32), C.White)
b:B("HeadDetail", V(0.12, 0.55, 0.04), V(0, 1.85, -0.35), GREEN)
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.26, 1.0, 0.3), V(s * 0.63, 1.7, 0), SUIT)
	b:B(name, V(0.24, 0.24, 0.26), V(s * 0.63, 1.12, 0), GREEN)
end
b:B("RightUpperArm", V(0.5, 0.36, 0.16), V(0.63, 0.82, 0), Color3.fromHex("7a4a26"))
-- big wide head, huge black eyes, antennae
b:B(H, V(1.6, 1.3, 1.2), V(0, 3.0, 0), GREEN)
b:B(H, V(1.2, 0.3, 1.0), V(0, 3.75, 0), GREEN)
b:B(H, V(0.8, 0.3, 0.8), V(0, 2.25, -0.05), GREEN) -- narrow chin
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.55, 0.42, 0.05), V(s * 0.38, 3.1, -0.61), C.Pupil, V(0, 0, s * -15))
	b:B("HeadDetail", V(0.14, 0.12, 0.04), V(s * 0.38 - 0.1, 3.18, -0.64), C.White)
	b:B(H, V(0.08, 0.6, 0.08), V(s * 0.35, 4.1, 0), GREEN_DARK, V(0, 0, s * -20))
	b:B(H, V(0.2, 0.2, 0.2), V(s * 0.45, 4.42, 0), GREEN)
end
b:mouth(V(0, 2.55, -0.61), 0.26, 0.06, V(0, 0, -1), 0, 18)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
