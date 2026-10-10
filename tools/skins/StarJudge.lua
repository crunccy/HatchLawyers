-- Star Judge (Legendary) - block remake 2026-10-10. A chunky hovering five-point star: golden-yellow block arms
-- tapering to glowing tips, a face in the middle (big eyes, rosy cheeks, smile), a white judge's jabot, a tiny black
-- mortarboard with a gold tassel on the top point, white gloves on the side points (one waving, one holding a gold
-- gavel), Neon sparkles around. Front-facing, HOVERS. Legendary: Neon glow + gold, 1.2x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("StarJudge")
local V = Vector3.new
local C = Kit.C
local STAR, STAR_DARK, STAR_GLOW = Color3.fromHex("ffd23f"), Color3.fromHex("f0a800"), Color3.fromHex("fff3a0")
local CHEEK, CAP, SPARK = Color3.fromHex("ff9a7a"), Color3.fromHex("1c1c20"), Color3.fromHex("fff8d0")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"
local cy = 2.0
local centre = CFrame.new(0, cy, 0)

-- centre: two crossed squares (an octagon-ish hub) with a darker rim behind
b:BAt(T, V(1.7, 1.7, 0.9), centre, STAR)
b:BAt(T, V(1.7, 1.7, 0.9), centre * CFrame.Angles(0, 0, math.rad(45)), STAR)
b:BAt(T, V(1.9, 1.9, 0.6), centre * CFrame.new(0, 0, 0.12) * CFrame.Angles(0, 0, math.rad(22.5)), STAR_DARK)
-- five arms, tapering, glowing tips; the top arm is the head point, side arms are arms, bottom two are legs
local partFor = { [0] = H, [1] = "LeftUpperArm", [-1] = "RightUpperArm", [2] = "LeftUpperLeg", [-2] = "RightUpperLeg" }
for k = -2, 2 do
	local arm = centre * CFrame.Angles(0, 0, math.rad(k * 72))
	local name = partFor[k]
	b:BAt(name, V(1.0, 0.8, 0.84), arm * CFrame.new(0, 1.05, 0), STAR)
	b:BAt(name, V(0.64, 0.6, 0.74), arm * CFrame.new(0, 1.65, 0), STAR)
	b:BAt(name, V(0.34, 0.42, 0.6), arm * CFrame.new(0, 2.1, 0), STAR_GLOW, NEON)
	b:BAt(name, V(1.04, 0.08, 0.6), arm * CFrame.new(0, 0.66, 0.15), STAR_DARK) -- seam where the arm meets the hub
end
-- face
for _, s in { -1, 1 } do
	b:eye(V(s * 0.36, cy + 0.22, -0.46), 0.44, V(0, 0, -1), Vector2.new(0, 0.02))
	b:brow(V(s * 0.38, cy + 0.6, -0.47), 0.4, V(0, 0, -1), s * 12, STAR_DARK)
	b:B("HeadDetail", V(0.26, 0.14, 0.04), V(s * 0.66, cy - 0.12, -0.46), CHEEK)
end
b:mouth(V(0, cy - 0.24, -0.46), 0.5, 0.14, V(0, 0, -1), 5, 20)
-- white jabot under the smile
b:B("HeadDetail", V(0.42, 0.36, 0.06), V(0, cy - 0.7, -0.47), C.White)
b:B("HeadDetail", V(0.28, 0.2, 0.06), V(0, cy - 0.96, -0.48), C.White)
b:B("HeadDetail", V(0.12, 0.12, 0.04), V(0, cy - 0.56, -0.51), C.Gold)
-- tiny mortarboard on the top point, gold tassel
b:B(H, V(0.4, 0.22, 0.4), V(0, cy + 2.35, 0), CAP)
b:B(H, V(0.85, 0.06, 0.85), V(0, cy + 2.48, 0), CAP, V(0, 45, 0))
b:B(H, V(0.06, 0.32, 0.06), V(0.3, cy + 2.32, -0.3), C.Gold)
b:B(H, V(0.1, 0.1, 0.1), V(0.3, cy + 2.14, -0.3), C.Gold)
-- gloves on the side points: -X waves, +X holds the gold gavel
local tipR = CFrame.Angles(0, 0, math.rad(-72)) * CFrame.new(0, 2.15, 0)
local tipL = CFrame.Angles(0, 0, math.rad(72)) * CFrame.new(0, 2.15, 0)
local rp, lp = (centre * tipR).Position, (centre * tipL).Position
b:B("RightUpperArm", V(0.42, 0.42, 0.42), rp + V(0.15, 0, -0.35), C.White)
b:B("RightUpperArm", V(0.48, 0.12, 0.48), rp + V(0.1, -0.24, -0.35), C.White)
b:B("RightUpperArm", V(0.12, 0.85, 0.12), rp + V(0.15, 0.5, -0.4), Color3.fromHex("8a5a2e"))
b:B("RightUpperArm", V(0.62, 0.3, 0.3), rp + V(0.15, 0.95, -0.4), C.Gold)
b:B("RightUpperArm", V(0.08, 0.32, 0.32), rp + V(-0.1, 0.95, -0.4), C.GoldDark)
b:B("RightUpperArm", V(0.08, 0.32, 0.32), rp + V(0.4, 0.95, -0.4), C.GoldDark)
b:B("LeftUpperArm", V(0.42, 0.42, 0.42), lp + V(-0.15, 0.05, -0.35), C.White)
b:B("LeftUpperArm", V(0.48, 0.12, 0.48), lp + V(-0.1, -0.2, -0.35), C.White)
for f = 0, 2 do -- spread fingers (waving)
	b:B("LeftUpperArm", V(0.08, 0.24, 0.1), lp + V(-0.3 + f * 0.13, 0.36, -0.35), C.White, V(0, 0, (f - 1) * -15))
end
-- sparkles: little Neon diamonds + plus-shapes floating around
for _, sp in { { -2.3, cy + 1.6, -0.2 }, { 2.4, cy + 1.9, 0.1 }, { -1.9, cy - 1.7, -0.4 }, { 2.0, cy - 1.5, 0.3 }, { 0.9, cy + 2.6, 0.2 } } do
	b:B(T, V(0.18, 0.18, 0.18), V(sp[1], sp[2], sp[3]), SPARK, V(0, 0, 45), NEON)
end
for _, sp in { { -1.2, cy + 2.4, 0 }, { 2.7, cy + 0.3, 0 } } do
	b:B(T, V(0.4, 0.08, 0.08), V(sp[1], sp[2], sp[3]), SPARK, nil, NEON)
	b:B(T, V(0.08, 0.4, 0.08), V(sp[1], sp[2], sp[3]), SPARK, nil, NEON)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.2)
b.hover = 0.9
print(b:preview())
_G.SkinBuild = b
