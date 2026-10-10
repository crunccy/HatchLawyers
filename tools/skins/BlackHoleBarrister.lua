-- Black Hole Barrister (Legendary, Space egg) - block remake 2026-10-10. A hovering chunky dark orb (rounded cube of
-- blocks) inside a tilted glowing accretion ring (Neon purple -> pink -> orange segments), a white barrister's curly
-- wig, white collar bands, cartoon eyes with purple pupils + angry brows, floating white gloves holding a gavel,
-- little glowing stars orbiting. Front-facing, HOVERS. Legendary: Neon glow, 1.2x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BlackHoleBarrister")
local V = Vector3.new
local C = Kit.C
local VOID, VOID_EDGE = Color3.fromHex("15111f"), Color3.fromHex("2a1f45")
local RING = { Color3.fromHex("8a3dff"), Color3.fromHex("b23dff"), Color3.fromHex("ff4fd8"), Color3.fromHex("ff8a3d"), Color3.fromHex("ff4fd8"), Color3.fromHex("b23dff") }
local WIG, WIG_SHADE, PURPLE = Color3.fromHex("f4f1ea"), Color3.fromHex("d9d4c8"), Color3.fromHex("9b4dff")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"
local cy = 1.6 -- orb centre

-- the orb: a rounded cube (core + three crossing slabs), a faint purple rim
b:B(T, V(2.2, 2.2, 2.2), V(0, cy, 0), VOID)
b:B(T, V(2.6, 1.6, 1.6), V(0, cy, 0), VOID)
b:B(T, V(1.6, 2.6, 1.6), V(0, cy, 0), VOID)
b:B(T, V(1.6, 1.6, 2.6), V(0, cy, 0), VOID_EDGE)
-- event-horizon glow: thin Neon purple strips framing the face side, and a swirl in the middle of the forehead
local GLOW = Color3.fromHex("7a2cff")
for _, s in { -1, 1 } do
	b:B(T, V(0.08, 1.7, 0.08), V(s * 1.3, cy, -0.82), GLOW, nil, NEON)
	b:B(T, V(1.7, 0.08, 0.08), V(0, cy + s * 1.3, -0.82), GLOW, nil, NEON)
	b:B(T, V(0.08, 0.08, 1.7), V(s * 1.3, cy + 0.82, 0), GLOW, nil, NEON)
end
b:B("HeadDetail", V(0.26, 0.26, 0.04), V(0, cy + 0.98, -1.31), GLOW, V(0, 0, 45), NEON)
-- accretion ring: 12 glowing segments on a circle, tilted toward the viewer
local tilt = CFrame.new(V(0, cy - 0.1, 0)) * CFrame.Angles(math.rad(-18), 0, math.rad(8))
for i = 0, 11 do
	local a = i / 12 * math.pi * 2
	local at = tilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.05)
	b:BAt(T, V(1.05, 0.14, 0.42), at, RING[i % #RING + 1], NEON)
end
-- face on the front of the orb
for _, s in { -1, 1 } do
	b:eye(V(s * 0.45, cy + 0.25, -1.31), 0.5, V(0, 0, -1), Vector2.new(0, 0), PURPLE)
	b:brow(V(s * 0.47, cy + 0.66, -1.32), 0.52, V(0, 0, -1), s * 18, Color3.fromHex("b9a8ff"))
end
b:mouth(V(0, cy - 0.4, -1.31), 0.7, 0.16, V(0, 0, -1), 0, 10)
-- barrister's collar bands under the face
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.18, 0.42, 0.05), V(s * 0.12, cy - 0.95, -1.08), C.White, V(-25, 0, 0))
end
-- the curly wig: a white cap with rows of curls down both sides and a little tail at the back
b:B(H, V(2.0, 0.36, 2.0), V(0, cy + 1.42, 0), WIG)
b:B(H, V(1.5, 0.24, 1.5), V(0, cy + 1.66, 0), WIG)
for _, s in { -1, 1 } do
	for row = 0, 2 do
		b:B(H, V(0.42, 0.3, 0.42), V(s * 1.18, cy + 1.05 - row * 0.34, -0.25), if row % 2 == 0 then WIG else WIG_SHADE)
		b:B(H, V(0.42, 0.3, 0.42), V(s * 1.18, cy + 1.05 - row * 0.34, 0.25), if row % 2 == 0 then WIG_SHADE else WIG)
	end
end
for i = -2, 2 do
	b:B(H, V(0.36, 0.22, 0.2), V(i * 0.38, cy + 1.23, -1.0), if i % 2 == 0 then WIG else WIG_SHADE) -- fringe curls
end
b:B(H, V(0.3, 0.6, 0.3), V(0, cy + 0.95, 1.15), WIG_SHADE)
-- floating white gloves: one holds a gavel, one points
b:B("RightUpperArm", V(0.42, 0.42, 0.42), V(1.85, cy - 0.3, -0.6), C.White)
b:B("RightUpperArm", V(0.46, 0.14, 0.46), V(1.85, cy - 0.55, -0.6), C.White)
b:B("RightUpperArm", V(0.12, 0.9, 0.12), V(1.85, cy + 0.2, -0.6), Color3.fromHex("6b4426"))
b:B("RightUpperArm", V(0.66, 0.32, 0.32), V(1.85, cy + 0.68, -0.6), Color3.fromHex("8a5a2e"))
b:B("RightUpperArm", V(0.08, 0.34, 0.34), V(1.6, cy + 0.68, -0.6), C.Gold)
b:B("RightUpperArm", V(0.08, 0.34, 0.34), V(2.1, cy + 0.68, -0.6), C.Gold)
b:B("LeftUpperArm", V(0.42, 0.42, 0.42), V(-1.85, cy - 0.2, -0.6), C.White)
b:B("LeftUpperArm", V(0.46, 0.14, 0.46), V(-1.75, cy - 0.45, -0.55), C.White)
b:B("LeftUpperArm", V(0.42, 0.12, 0.12), V(-2.2, cy - 0.12, -0.7), C.White)       -- pointing finger
-- little stars orbiting
for _, st in { { -2.3, cy + 1.6, 0.4 }, { 2.4, cy + 1.3, 0.6 }, { -1.6, cy - 1.4, -0.8 }, { 1.9, cy - 1.2, 0.9 }, { 0.3, cy + 2.4, -0.4 } } do
	b:B(T, V(0.16, 0.16, 0.16), V(st[1], st[2], st[3]), Color3.fromHex("fff4b0"), V(0, 45, 45), NEON)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.2)
b.hover = 1.4
print(b:preview())
_G.SkinBuild = b
