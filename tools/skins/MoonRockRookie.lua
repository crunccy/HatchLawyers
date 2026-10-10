-- Moon Rock Rookie (Common, Space egg) - block remake 2026-10-10. A lumpy grey moon rock with craters, a face, a
-- small navy tie, stubby legs and little rock arms. Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("MoonRockRookie")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local ROCK, ROCK_DARK, CRATER, TIE = Color3.fromRGB(170, 170, 175), Color3.fromHex("8a8a92"), Color3.fromHex("737380"), Color3.fromRGB(60, 70, 100)
for _, s in { -1, 1 } do
	b:B(if s < 0 then "LeftUpperLeg" else "RightUpperLeg", V(0.45, 0.6, 0.5), V(s * 0.4, 0.3, 0), ROCK_DARK)
end
-- lumpy body: offset overlapping blocks
for _, r in { { 0, 1.9, 2.0, 2.2, 1.6 }, { -0.4, 2.7, 1.3, 1.0, 1.4 }, { 0.5, 2.8, 1.0, 0.8, 1.3 }, { 0.75, 1.5, 0.8, 1.0, 1.3 }, { -0.8, 1.3, 0.6, 0.8, 1.2 } } do
	b:B(T, V(r[3], r[4], r[5]), V(r[1], r[2], 0), ROCK)
end
for _, c in { { -0.6, 2.9, 0.3 }, { 0.6, 1.4, 0.25 }, { 0.75, 2.9, 0.2 }, { -0.75, 1.5, 0.2 } } do
	b:B("HeadDetail", V(c[3], c[3], 0.05), V(c[1], c[2], -0.82), CRATER)
	b:B("HeadDetail", V(c[3] * 0.6, c[3] * 0.6, 0.04), V(c[1], c[2], -0.85), ROCK_DARK)
end
for _, s in { -1, 1 } do
	b:eye(V(s * 0.3, 2.3, -0.81), 0.36, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.32, 2.58, -0.82), 0.32, V(0, 0, -1), s * 8, ROCK_DARK)
	b:B(if s < 0 then "LeftUpperArm" else "RightUpperArm", V(0.4, 0.4, 0.4), V(s * 1.15, 1.9, -0.1), ROCK_DARK)
end
b:mouth(V(0, 1.95, -0.81), 0.36, 0.1, V(0, 0, -1), 4, 16)
b:B("HeadDetail", V(0.16, 0.12, 0.04), V(0, 1.68, -0.82), TIE)
b:B("HeadDetail", V(0.12, 0.38, 0.04), V(0, 1.42, -0.82), TIE)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
