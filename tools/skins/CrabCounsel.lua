-- Crab Counsel (Common, Ocean egg) - block remake 2026-10-10. A wide red crab standing upright-ish: a flat wide shell
-- body, eyes up on stalks, two big claws raised, little pointy legs either side, and a navy tie on its front.
-- Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("CrabCounsel")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local RED, RED_DARK, TIE = Color3.fromRGB(225, 70, 50), Color3.fromHex("a8301e"), Color3.fromRGB(40, 60, 120)
-- three little legs each side
for _, s in { -1, 1 } do
	for k = 0, 2 do
		b:B(if s < 0 then "LeftUpperLeg" else "RightUpperLeg", V(0.14, 0.9, 0.14), V(s * (0.9 + k * 0.25), 0.45, -0.3 + k * 0.3), RED_DARK, V(0, 0, s * 25))
	end
end
b:B(T, V(2.4, 1.2, 1.4), V(0, 1.4, 0), RED)
b:B(T, V(2.0, 0.3, 1.2), V(0, 2.1, 0), RED)
for _, sp in { { -0.6, 1.8 }, { 0.5, 1.85 }, { 0.0, 2.15 } } do
	b:B("HeadDetail", V(0.2, 0.14, 0.05), V(sp[1], sp[2], -0.71), RED_DARK)
end
b:B("HeadDetail", V(0.2, 0.14, 0.05), V(0, 1.45, -0.72), TIE)
b:B("HeadDetail", V(0.14, 0.45, 0.05), V(0, 1.15, -0.72), TIE)
b:mouth(V(0, 1.65, -0.71), 0.5, 0.1, V(0, 0, -1), 0, 18)
for _, s in { -1, 1 } do
	-- eye stalks
	b:B(H, V(0.14, 0.7, 0.14), V(s * 0.35, 2.55, -0.2), RED)
	b:B(H, V(0.42, 0.42, 0.42), V(s * 0.35, 3.05, -0.2), C.White)
	b:B(H, V(0.22, 0.26, 0.05), V(s * 0.35, 3.05, -0.43), C.Pupil)
	-- big claws raised
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.25, 0.7, 0.25), V(s * 1.45, 2.15, -0.1), RED, V(0, 0, s * -25))
	b:B(name, V(0.6, 0.5, 0.45), V(s * 1.75, 2.65, -0.1), RED)
	b:B(name, V(0.2, 0.45, 0.4), V(s * 1.95, 3.05, -0.1), RED_DARK, V(0, 0, s * -15))
	b:B(name, V(0.2, 0.35, 0.4), V(s * 1.6, 3.0, -0.1), RED, V(0, 0, s * 15))
end
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
