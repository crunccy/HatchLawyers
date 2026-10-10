-- Whale Judge (Legendary) - block remake 2026-10-10. A big blue whale hovering side-on (body along X, head at +X,
-- the face side toward the viewer at -Z): chunky stepped body, pale grooved belly, tapering tail with flukes, a white
-- curly barrister's wig on top, a gold monocle (+ chain) over the eye, a happy wide mouth, a glowing water spout from
-- the blowhole, a front flipper holding a gold gavel. HOVERS. Sideways. Legendary: gold monocle/gavel, Neon spout, 1.05x (it is long).
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("WhaleJudge")
local V = Vector3.new
local C = Kit.C
local BLUE, BLUE_DARK, BELLY, GROOVE = Color3.fromHex("3f7fd6"), Color3.fromHex("2c5fa8"), Color3.fromHex("cfe3f5"), Color3.fromHex("a9c6e3")
local WIG, WIG_SHADE, SPOUT, CHEEK = Color3.fromHex("f4f1ea"), Color3.fromHex("d9d4c8"), Color3.fromHex("9fe8ff"), Color3.fromHex("ff9aa8")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"
local cy = 1.8

-- body: big block, rounded with crossing slabs; blunt head at +X
b:B(T, V(3.2, 1.9, 1.8), V(0.3, cy, 0), BLUE)
b:B(T, V(2.8, 2.2, 1.5), V(0.4, cy, 0), BLUE)
b:B(H, V(0.7, 1.7, 1.6), V(2.1, cy - 0.05, 0), BLUE)
b:B(H, V(0.3, 1.2, 1.2), V(2.55, cy - 0.1, 0), BLUE)
b:B(T, V(2.4, 0.2, 1.2), V(0.3, cy + 1.15, 0), BLUE_DARK) -- darker back ridge
-- pale belly with grooves along the near side
b:B(T, V(3.4, 0.55, 1.6), V(0.5, cy - 0.85, 0), BELLY)
for i = 0, 3 do
	b:B("HeadDetail", V(2.2 - i * 0.3, 0.05, 0.04), V(0.7 + i * 0.1, cy - 0.7 - i * 0.12, -0.82), GROOVE)
end
-- tail tapering to the flukes
b:B(T, V(1.1, 1.3, 1.25), V(-1.75, cy + 0.1, 0), BLUE)
b:B(T, V(0.9, 0.85, 0.85), V(-2.6, cy + 0.3, 0), BLUE)
b:B(T, V(0.6, 0.55, 0.55), V(-3.25, cy + 0.5, 0), BLUE_DARK)
for _, s in { -1, 1 } do
	b:B(T, V(0.75, 0.16, 1.0), V(-3.7, cy + 0.68, s * 0.55), BLUE_DARK, V(s * -18, s * 20, 10))
end
-- face (the -Z side): eye with brow, monocle, cheek, big smile
b:eye(V(1.45, cy + 0.25, -0.91), 0.5, V(0, 0, -1), Vector2.new(0.1, 0))
b:brow(V(1.47, cy + 0.65, -0.92), 0.48, V(0, 0, -1), 10, BLUE_DARK)
for _, e in { { 0, 0.36, 0.74, 0.07 }, { 0, -0.36, 0.74, 0.07 }, { 0.36, 0, 0.07, 0.74 }, { -0.36, 0, 0.07, 0.74 } } do
	b:B("HeadDetail", V(e[3], e[4], 0.06), V(1.45 + e[1], cy + 0.25 + e[2], -0.96), C.Gold)
end
for i = 1, 4 do -- monocle chain dangling back along the body
	b:B("HeadDetail", V(0.12, 0.08, 0.05), V(1.1 - i * 0.18, cy - 0.15 - math.sin(i / 4 * math.pi) * 0.25, -0.95), C.Gold)
end
b:B("HeadDetail", V(0.3, 0.14, 0.04), V(1.95, cy - 0.15, -0.91), CHEEK)
b:mouth(V(1.75, cy - 0.45, -0.91), 1.0, 0.14, V(0, 0, -1), 0, 18)
-- curly barrister's wig on the head
b:B(H, V(1.5, 0.3, 1.7), V(1.4, cy + 1.2, 0), WIG)
b:B(H, V(1.1, 0.22, 1.3), V(1.4, cy + 1.42, 0), WIG)
for _, s in { -1, 1 } do
	for i = 0, 2 do
		b:B(H, V(0.4, 0.3, 0.3), V(0.25 + i * 0.3, cy + 0.98, s * 0.92), if i % 2 == 0 then WIG else WIG_SHADE)
		b:B(H, V(0.4, 0.3, 0.3), V(0.25 + i * 0.3, cy + 0.68, s * 0.92), if i % 2 == 0 then WIG_SHADE else WIG)
	end
end
b:B(H, V(0.4, 0.5, 0.3), V(0.05, cy + 0.95, 0), WIG_SHADE) -- little tail at the back of the wig
-- water spout from the blowhole (behind the wig), with splash drops
b:B(T, V(0.3, 0.2, 0.3), V(0.3, cy + 1.3, 0), BLUE_DARK)
b:B(T, V(0.24, 1.1, 0.24), V(0.3, cy + 1.9, 0), SPOUT, nil, NEON)
for _, d in { { 0.35, 0 }, { -0.35, 0 }, { 0, 0.35 }, { 0, -0.35 } } do
	b:B(T, V(0.18, 0.18, 0.18), V(0.3 + d[1], cy + 2.4, d[2]), SPOUT, V(0, 45, 45), NEON)
end
b:B(T, V(0.14, 0.14, 0.14), V(0.3, cy + 2.62, 0), C.White, nil, NEON)
-- front flippers; the near one holds a gold gavel
for _, s in { -1, 1 } do
	local name = if s < 0 then "RightUpperArm" else "LeftUpperArm"
	b:B(name, V(0.9, 0.16, 0.6), V(0.2, cy - 0.65, s * 1.05), BLUE_DARK, V(s * 25, 0, -20))
end
b:B("RightUpperArm", V(0.12, 0.8, 0.12), V(-0.05, cy - 0.25, -1.35), Color3.fromHex("8a5a2e"))
b:B("RightUpperArm", V(0.6, 0.3, 0.3), V(-0.05, cy + 0.2, -1.35), C.Gold)
b:B("RightUpperArm", V(0.08, 0.32, 0.32), V(-0.29, cy + 0.2, -1.35), C.GoldDark)
b:B("RightUpperArm", V(0.08, 0.32, 0.32), V(0.19, cy + 0.2, -1.35), C.GoldDark)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05) -- long side-on body: kept ~7.3 studs so it fits the desk like Tralalero
b.hover = 0.8
print(b:preview())
_G.SkinBuild = b
