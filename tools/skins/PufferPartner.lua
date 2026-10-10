-- Puffer Partner (Uncommon, Ocean egg) - block remake 2026-10-10. A puffed-up pufferfish, hovering: a round body
-- (crossed slabs) with a blue back and pale-yellow belly, little spikes poking out all over, puffed cheeks, a tiny
-- pursed mouth, side fins, a tail fin, and a small blue tie. Front-facing, HOVERS. Uncommon: 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("PufferPartner")
local V = Vector3.new
local C = Kit.C
local BLUE, BLUE_DARK, BELLY, SPIKE, FIN = Color3.fromHex("3c78b4"), Color3.fromHex("2c5a8a"), Color3.fromHex("f0d25a"), Color3.fromHex("fff2c0"), Color3.fromHex("6aa8e0")
local T, H = "UpperTorso", "Head"
local cy = 1.8

-- round body: crossed slabs, blue on top, yellow belly
b:B(T, V(2.2, 2.2, 2.0), V(0, cy, 0), BELLY)
b:B(T, V(2.5, 1.7, 1.8), V(0, cy, 0), BELLY)
b:B(T, V(1.8, 2.5, 1.8), V(0, cy, 0), BELLY)
b:B(H, V(2.24, 1.0, 2.04), V(0, cy + 0.65, 0), BLUE)
b:B(H, V(1.84, 0.4, 1.84), V(0, cy + 1.1, 0), BLUE)
for _, sp in { { -0.6, cy + 0.9, -1.03 }, { 0.5, cy + 1.0, -1.03 }, { 0.0, cy + 1.2, -0.7 } } do
	b:B("HeadDetail", V(0.2, 0.2, 0.05), V(sp[1], sp[2], sp[3]), BLUE_DARK)
end
-- spikes: little pale pyramids (rotated cubes) all around
for i = 0, 11 do
	local a = i / 12 * math.pi * 2
	b:B(T, V(0.34, 0.34, 0.34), V(math.cos(a) * 1.42, cy + math.sin(a) * 1.42, -0.2), SPIKE, V(45, 0, 45))
end
for i = 0, 5 do
	local a = i / 6 * math.pi * 2
	b:B(T, V(0.26, 0.26, 0.26), V(math.cos(a) * 1.05, cy + math.sin(a) * 1.05, -1.08), SPIKE, V(45, 0, 45))
end
-- face: big eyes, puffed cheeks, tiny pursed mouth
for _, s in { -1, 1 } do
	b:eye(V(s * 0.45, cy + 0.35, -1.03), 0.44, V(0, 0, -1), Vector2.new(0, 0))
	b:B("HeadDetail", V(0.3, 0.18, 0.04), V(s * 0.72, cy - 0.15, -1.03), Color3.fromHex("ff9a7a"))
	-- side fins
	b:B(s < 0 and "LeftUpperArm" or "RightUpperArm", V(0.12, 0.5, 0.6), V(s * 1.3, cy - 0.1, 0.1), FIN, V(0, s * 20, s * -15))
end
b:B("HeadDetail", V(0.2, 0.16, 0.05), V(0, cy - 0.3, -1.04), C.Mouth)
-- tiny tie under the mouth
b:B("HeadDetail", V(0.14, 0.12, 0.04), V(0, cy - 0.6, -1.04), BLUE_DARK)
b:B("HeadDetail", V(0.12, 0.35, 0.04), V(0, cy - 0.82, -1.04), BLUE_DARK)
-- tail fin
b:B(T, V(0.12, 0.8, 0.6), V(0, cy, 1.25), FIN)
b:B(T, V(0.12, 0.5, 0.4), V(0, cy, 1.55), FIN)
b.model.WorldPivot = CFrame.new(b.origin)
b.hover = 0.6
print(b:preview())
_G.SkinBuild = b
