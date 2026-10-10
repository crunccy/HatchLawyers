-- Scoop Judge (Legendary) - block remake 2026-10-10. A floating ice-cream cone: waffle cone body (stepped, darker
-- waffle grid), three lumpy scoops - chocolate (with drips over the rim), vanilla (the face, wearing a white judge's
-- jabot under a black robe collar), strawberry (rainbow sprinkles) - a cherry on top inside a little gold crown,
-- wafer-stick arms with white gloves holding a gold gavel. Front-facing, HOVERS. Legendary: gold crown + gavel, 1.15x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("ScoopJudge")
local V = Vector3.new
local C = Kit.C
local CONE, CONE_DARK, CONE_LIGHT = Color3.fromHex("e0a458"), Color3.fromHex("b87a35"), Color3.fromHex("f0c07a")
local CHOC, CHOC_DARK = Color3.fromHex("7a4a2a"), Color3.fromHex("5c3520")
local VAN, VAN_DARK = Color3.fromHex("f8ebc8"), Color3.fromHex("e8d6a6")
local STRAW, STRAW_DARK = Color3.fromHex("f49ac1"), Color3.fromHex("e07aa6")
local CHERRY, STEM, ROBE = Color3.fromHex("d61f3a"), Color3.fromHex("4e7a2a"), Color3.fromHex("1c1c20")
local SPRINKLES = { Color3.fromHex("3fb8ff"), Color3.fromHex("ffd23f"), Color3.fromHex("6cd66c"), Color3.fromHex("ff6b3f"), Color3.fromHex("b07aff"), C.White }
local T, H = "UpperTorso", "Head"

-- waffle cone: square rows narrowing to the tip, with a darker grid on the front + sides
local rows = { { 0.4, 0.34 }, { 0.82, 0.68 }, { 1.24, 1.02 }, { 1.66, 1.36 }, { 2.08, 1.7 } }
for i, r in rows do
	b:B(T, V(r[2], 0.42, r[2]), V(0, r[1], 0), CONE)
	b:B(T, V(r[2] + 0.02, 0.05, r[2] + 0.02), V(0, r[1] + 0.19, 0), CONE_DARK)
	if r[2] > 0.6 then
		for k = -1, 1, 2 do
			b:B(T, V(0.05, 0.42, 0.03), V(k * r[2] * 0.22, r[1], -r[2] / 2 - 0.01), CONE_DARK)
		end
	end
end
b:B(T, V(2.05, 0.28, 2.05), V(0, 2.42, 0), CONE_LIGHT) -- rim
-- chocolate scoop with drips over the rim
b:B(T, V(2.15, 0.9, 2.0), V(0, 3.0, 0), CHOC)
b:B(T, V(1.9, 1.05, 1.8), V(0, 3.0, 0), CHOC)
for _, d in { { -0.7, 0.45, -1.0 }, { 0.2, 0.3, -1.0 }, { 0.8, 0.55, -1.0 }, { -1.08, 0.4, 0.3 }, { 1.08, 0.35, -0.4 } } do
	local sz = if math.abs(d[1]) > 1 then V(0.06, d[2], 0.24) else V(0.24, d[2], 0.06)
	b:B(T, sz, V(d[1], 2.55 - d[2] / 2 + 0.15, d[3]), CHOC_DARK)
end
-- black robe collar + white jabot on the chocolate scoop
b:B(T, V(2.2, 0.22, 2.06), V(0, 3.4, 0), ROBE)
b:B("HeadDetail", V(0.48, 0.5, 0.06), V(0, 3.12, -1.06), C.White)
b:B("HeadDetail", V(0.32, 0.2, 0.06), V(0, 2.8, -1.07), C.White)
-- vanilla scoop: the face
b:B(H, V(1.95, 1.15, 1.85), V(0, 4.05, 0), VAN)
b:B(H, V(1.7, 1.35, 1.6), V(0, 4.05, 0), VAN)
for i = 0, 5 do -- lumpy bottom edge
	local a = i / 6 * math.pi * 2
	b:B(H, V(0.4, 0.2, 0.4), V(math.sin(a) * 0.95, 3.5, math.cos(a) * 0.9), VAN_DARK)
end
for _, s in { -1, 1 } do
	b:eye(V(s * 0.4, 4.2, -0.94), 0.46, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.42, 4.58, -0.95), 0.46, V(0, 0, -1), s * 10, Color3.fromHex("8a6a44"))
	b:B("HeadDetail", V(0.24, 0.12, 0.04), V(s * 0.72, 3.9, -0.94), STRAW) -- blush
end
b:mouth(V(0, 3.82, -0.94), 0.5, 0.14, V(0, 0, -1), 5, 18)
-- strawberry scoop with sprinkles
b:B(H, V(1.6, 0.85, 1.5), V(0, 5.0, 0), STRAW)
b:B(H, V(1.35, 1.0, 1.3), V(0, 5.05, 0), STRAW)
b:B(H, V(1.66, 0.16, 1.56), V(0, 4.62, 0), STRAW_DARK)
for i, sp in { { -0.5, 5.3, -0.66 }, { 0.3, 5.45, -0.66 }, { 0.6, 5.1, -0.76 }, { -0.2, 4.95, -0.76 }, { 0.0, 5.56, -0.3 },
	{ -0.45, 5.56, 0.2 }, { 0.45, 5.56, 0.1 }, { -0.81, 5.0, 0.2 }, { 0.81, 5.2, -0.2 } } do
	b:B("HeadDetail", V(0.26, 0.09, 0.09), V(sp[1], sp[2], sp[3]), SPRINKLES[i % #SPRINKLES + 1], V(0, (i * 47) % 180, (i * 31) % 60))
end
-- gold crown ring + the cherry
b:B(H, V(0.9, 0.16, 0.9), V(0, 5.62, 0), C.Gold)
for _, p in { { -0.36, -0.36 }, { 0.36, -0.36 }, { -0.36, 0.36 }, { 0.36, 0.36 }, { 0, -0.4 } } do
	b:B(H, V(0.14, 0.26, 0.14), V(p[1], 5.8, p[2]), C.Gold)
end
b:B(H, V(0.5, 0.5, 0.5), V(0, 5.95, 0), CHERRY)
b:B(H, V(0.12, 0.12, 0.06), V(0.1, 6.08, -0.26), C.White) -- shine
b:B(H, V(0.06, 0.45, 0.06), V(0.08, 6.38, 0.02), STEM, V(0, 0, -15))
-- wafer-stick arms + gloves; gavel in the +X glove
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.7, 0.16, 0.16), V(s * 1.35, 3.0, -0.2), CONE_LIGHT, V(0, 0, s * 25))
	b:B(name, V(0.34, 0.34, 0.34), V(s * 1.72, 3.2, -0.25), C.White)
	b:B(name, V(0.4, 0.1, 0.4), V(s * 1.66, 3.03, -0.25), C.White)
end
b:B("RightUpperArm", V(0.12, 0.85, 0.12), V(1.72, 3.6, -0.3), CONE_DARK)
b:B("RightUpperArm", V(0.62, 0.32, 0.32), V(1.72, 4.05, -0.3), C.Gold)
b:B("RightUpperArm", V(0.08, 0.34, 0.34), V(1.48, 4.05, -0.3), C.GoldDark)
b:B("RightUpperArm", V(0.08, 0.34, 0.34), V(1.96, 4.05, -0.3), C.GoldDark)
b:B("LeftUpperArm", V(0.12, 0.26, 0.12), V(-1.72, 3.47, -0.3), C.White) -- thumbs up
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.15)
b.hover = 0.6
print(b:preview())
_G.SkinBuild = b
