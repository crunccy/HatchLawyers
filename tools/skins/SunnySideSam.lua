-- Sunny-Side Sam (Common, Food egg) - block remake 2026-10-10. A walking fried egg standing up: a wobbly white
-- egg-white shape with a big round yellow yolk in the middle holding the face, a tiny white chef hat, stick legs and
-- arms. Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("SunnySideSam")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local WHITE, WHITE_SHADE, YOLK, YOLK_DARK, BLACK = Color3.fromHex("fcfcf8"), Color3.fromHex("e6e6ec"), Color3.fromHex("ffc828"), Color3.fromHex("f0a800"), Color3.fromHex("1c1c20")
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.18, 1.0, 0.18), V(s * 0.4, 0.6, 0), BLACK)
	b:B(name, V(0.4, 0.2, 0.6), V(s * 0.42, 0.1, -0.1), YOLK_DARK)
end
-- wobbly egg white: overlapping blobs
for _, w in { { 0, 2.4, 2.6, 2.0 }, { -0.6, 3.1, 1.5, 1.2 }, { 0.7, 1.7, 1.5, 1.1 }, { 0.8, 3.0, 1.0, 1.0 }, { -0.8, 1.7, 1.2, 1.0 } } do
	b:B(T, V(w[3], w[4], 0.3), V(w[1], w[2], 0.05), WHITE)
end
b:B(T, V(2.4, 1.8, 0.2), V(0.05, 2.4, 0.18), WHITE_SHADE)
-- yolk: rounded (crossed squares), face on it
b:B(H, V(1.3, 1.3, 0.5), V(0, 2.5, -0.2), YOLK)
b:B(H, V(1.3, 1.3, 0.5), V(0, 2.5, -0.2), YOLK, V(0, 0, 45))
b:B("HeadDetail", V(0.2, 0.12, 0.03), V(-0.35, 2.95, -0.47), C.White) -- shine
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, 2.6, -0.47), 0.3, V(0, 0, -1), Vector2.new(0, 0))
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.16, 0.16), V(s * 1.55, 2.3, -0.05), BLACK, V(0, 0, s * 20))
	b:B(name, V(0.28, 0.28, 0.28), V(s * 1.85, 2.15, -0.05), C.White)
end
b:mouth(V(0, 2.22, -0.47), 0.36, 0.1, V(0, 0, -1), 4, 20)
-- tiny chef hat
b:B(H, V(0.6, 0.2, 0.5), V(-0.5, 3.75, 0.05), WHITE_SHADE)
b:B(H, V(0.7, 0.5, 0.6), V(-0.5, 4.1, 0.05), WHITE)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
