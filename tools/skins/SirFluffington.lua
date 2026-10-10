-- Sir Fluffington (Legendary) - block remake 2026-10-10. A chubby fluffy white king cat standing upright: big head
-- with cheek fluff, stepped pointy ears (pink inside), green eyes, pink nose + whiskers, a fluffy chest ruff, a gold
-- jewelled crown, a royal red ermine cape (white collar with black spots, gold clasp), a gold sceptre topped with a
-- blue orb, a big fluffy tail curling up. Front-facing. Legendary: crown + sceptre + cape, 1.2x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("SirFluffington")
local V = Vector3.new
local C = Kit.C
local FUR, FUR_SHADE, PINK = Color3.fromHex("f7f5f2"), Color3.fromHex("e0dbd2"), Color3.fromHex("f2a0b0")
local IRIS, WHISKER, BROW = Color3.fromHex("3cbf5a"), Color3.fromHex("8a8a8a"), Color3.fromHex("b8b0a4")
local CAPE, CAPE_DARK, SPOT = Color3.fromHex("a3203a"), Color3.fromHex("7a1529"), Color3.fromHex("1c1c20")
local RUBY, SAPPHIRE = Color3.fromHex("e0303a"), Color3.fromHex("2f7bff")
local T, H = "UpperTorso", "Head"

-- legs + paws
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.6, 0.7, 0.65), V(s * 0.48, 0.45, 0), FUR)
	b:B(name, V(0.66, 0.24, 0.8), V(s * 0.48, 0.12, -0.08), FUR_SHADE)
	b:B("HeadDetail", V(0.4, 0.12, 0.04), V(s * 0.48, 0.12, -0.49), PINK) -- toe beans
end
-- chubby body + fluffy chest ruff
b:B(T, V(1.9, 1.6, 1.5), V(0, 1.6, 0), FUR)
b:B(T, V(2.05, 1.2, 1.3), V(0, 1.6, 0), FUR)
for i = -2, 2 do
	b:B(T, V(0.36, 0.42 - math.abs(i) * 0.06, 0.2), V(i * 0.3, 2.15 - math.abs(i) * 0.05, -0.8), if i % 2 == 0 then FUR else FUR_SHADE)
end
b:B(T, V(1.0, 0.5, 0.15), V(0, 1.75, -0.78), FUR)
-- big head with cheek fluff
b:B(H, V(1.9, 1.45, 1.6), V(0, 3.15, 0), FUR)
for _, s in { -1, 1 } do
	b:B(H, V(0.35, 0.5, 1.2), V(s * 1.05, 2.9, -0.1), FUR)
	b:B(H, V(0.22, 0.3, 0.9), V(s * 1.28, 2.82, -0.1), FUR_SHADE)
	-- stepped pointy ears, pink inside
	b:B(H, V(0.5, 0.4, 0.4), V(s * 0.78, 4.02, 0.05), FUR)
	b:B(H, V(0.3, 0.35, 0.32), V(s * 0.86, 4.38, 0.05), FUR)
	b:B("HeadDetail", V(0.26, 0.4, 0.04), V(s * 0.8, 4.1, -0.16), PINK)
end
-- face
for _, s in { -1, 1 } do
	b:eye(V(s * 0.42, 3.3, -0.81), 0.5, V(0, 0, -1), Vector2.new(0, 0), IRIS)
	b:brow(V(s * 0.44, 3.7, -0.82), 0.44, V(0, 0, -1), s * 10, BROW)
	for k = 0, 1 do -- whiskers
		b:B("HeadDetail", V(0.6, 0.04, 0.03), V(s * 0.95, 2.86 - k * 0.12, -0.84), WHISKER, V(0, 0, s * (6 - k * 14)))
	end
end
b:B("HeadDetail", V(0.24, 0.16, 0.05), V(0, 2.98, -0.83), PINK)        -- nose
b:B(H, V(0.7, 0.36, 0.2), V(0, 2.75, -0.86), FUR)                        -- muzzle
b:mouth(V(0, 2.68, -0.97), 0.34, 0.1, V(0, 0, -1), 0, 22)
-- gold crown with gems
b:B(H, V(1.0, 0.3, 1.0), V(0, 4.05, 0), C.Gold)
b:B(H, V(1.24, 0.07, 1.04), V(0, 3.92, 0), C.GoldDark)
for i = -2, 2 do
	b:B(H, V(0.18, 0.28 + (if i == 0 then 0.14 else 0), 0.18), V(i * 0.22, 4.32 + (if i == 0 then 0.07 else 0), -0.4), C.Gold)
end
b:B(H, V(0.14, 0.14, 0.14), V(0, 4.6, -0.4), RUBY)
b:B("HeadDetail", V(0.2, 0.2, 0.05), V(0, 4.05, -0.52), RUBY)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.14, 0.14, 0.05), V(s * 0.32, 4.05, -0.52), SAPPHIRE)
end
-- ermine cape: red, hangs down the back + wraps the sides, white spotted collar, gold clasp
b:B(T, V(2.3, 2.3, 0.14), V(0, 1.45, 0.82), CAPE)
for _, s in { -1, 1 } do
	b:B(T, V(0.14, 2.0, 1.1), V(s * 1.1, 1.55, 0.3), CAPE_DARK)
end
b:B(T, V(2.4, 0.18, 0.18), V(0, 0.32, 0.82), C.Gold) -- gold hem
for _, s in { -1, 1 } do -- the robe hangs open down the front: red panels, white ermine edges, gold hems
	b:B(T, V(0.5, 1.9, 0.12), V(s * 0.85, 1.4, -0.82), CAPE)
	b:B(T, V(0.14, 1.9, 0.14), V(s * 0.55, 1.4, -0.84), C.White)
	b:B("HeadDetail", V(0.06, 0.14, 0.04), V(s * 0.55, 1.75, -0.92), SPOT)
	b:B("HeadDetail", V(0.06, 0.14, 0.04), V(s * 0.55, 1.15, -0.92), SPOT)
	b:B(T, V(0.52, 0.12, 0.14), V(s * 0.85, 0.5, -0.84), C.Gold)
end
b:B(T, V(2.4, 0.42, 1.8), V(0, 2.5, 0.05), C.White)  -- ermine collar
for _, sp in { { -0.8, -0.91 }, { 0.8, -0.91 }, { -0.3, -0.91 }, { 0.3, -0.91 }, { -1.21, 0.0 }, { 1.21, 0.0 }, { -0.4, 0.96 }, { 0.4, 0.96 } } do
	local onSide = math.abs(sp[1]) > 1.1
	b:B("HeadDetail", if onSide then V(0.04, 0.2, 0.1) else V(0.1, 0.2, 0.04), V(sp[1], 2.45, sp[2]), SPOT)
end
b:B(T, V(0.3, 0.3, 0.1), V(0, 2.32, -0.9), C.Gold)
-- arms: short fluffy, paws; the +X paw holds the sceptre
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.5, 0.9, 0.55), V(s * 1.2, 1.9, -0.2), FUR, V(0, 0, s * 12))
	b:B(name, V(0.5, 0.42, 0.55), V(s * 1.3, 1.35, -0.3), FUR_SHADE)
end
b:B("RightUpperArm", V(0.14, 2.2, 0.14), V(1.32, 2.0, -0.62), C.Gold)
b:B("RightUpperArm", V(0.28, 0.12, 0.28), V(1.32, 3.0, -0.62), C.GoldDark)
b:B("RightUpperArm", V(0.42, 0.42, 0.42), V(1.32, 3.3, -0.62), SAPPHIRE, V(0, 45, 0))
b:B("RightUpperArm", V(0.12, 0.25, 0.12), V(1.32, 3.6, -0.62), C.Gold)
b:B("RightUpperArm", V(0.24, 0.08, 0.08), V(1.32, 3.62, -0.62), C.Gold)
b:B("RightUpperArm", V(0.24, 0.2, 0.2), V(1.32, 0.85, -0.62), C.GoldDark)
-- big fluffy tail curling up beside the cape
b:B(T, V(0.45, 0.45, 0.9), V(-0.9, 0.6, 1.2), FUR)
b:B(T, V(0.5, 1.2, 0.5), V(-1.2, 1.3, 1.5), FUR)
b:B(T, V(0.45, 0.45, 0.45), V(-1.05, 2.05, 1.45), FUR_SHADE)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.2)
print(b:preview())
_G.SkinBuild = b
