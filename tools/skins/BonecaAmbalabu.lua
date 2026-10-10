-- Boneca Ambalabu (Uncommon, Brainrot egg) - block remake 2026-10-10. Reference: the meme character - a frog head on
-- a car tyre body with human legs. A green frog head with bulging eyes on top and a wide mouth, sitting in a black
-- tyre (seen from the front: a thick ring with tread blocks, a grey hub in the middle), blue-jeans legs and red
-- sneakers. Front-facing. Uncommon: 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BonecaAmbalabu")
local V = Vector3.new
local C = Kit.C
local TYRE, TREAD, HUB, HUB_DARK = Color3.fromRGB(32, 32, 36), Color3.fromHex("4a4a52"), Color3.fromHex("a0a4b0"), Color3.fromHex("6a6e7a")
local JEANS, SHOE, FROG, FROG_DARK, BELLY = Color3.fromRGB(60, 70, 140), Color3.fromRGB(220, 40, 50), Color3.fromRGB(110, 190, 80), Color3.fromHex("4e9a3a"), Color3.fromHex("d8f0a0")
local T, H = "UpperTorso", "Head"
local cy = 2.35

-- jeans legs + red sneakers
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.42, 1.2, 0.46), V(s * 0.38, 0.75, 0), JEANS)
	b:B(name, V(0.5, 0.3, 0.78), V(s * 0.38, 0.15, -0.12), SHOE)
	b:B(name, V(0.52, 0.08, 0.8), V(s * 0.38, 0.02, -0.12), C.White)
end
-- the tyre: 10 blocks around a ring (front-facing), tread nubs on the outside, hub in the middle
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	b:BAt(T, V(0.75, 0.62, 1.0), CFrame.new(0, cy, 0) * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.05, 0), TYRE)
	b:BAt(T, V(0.3, 0.14, 1.04), CFrame.new(0, cy, 0) * CFrame.Angles(0, 0, a + 0.3) * CFrame.new(0, 1.38, 0), TREAD)
end
b:B(T, V(1.1, 1.1, 0.8), V(0, cy, 0), HUB)
b:B(T, V(1.1, 1.1, 0.8), V(0, cy, 0), HUB, V(0, 0, 45))
b:B(T, V(0.4, 0.4, 0.84), V(0, cy, 0), HUB_DARK)
for i = 0, 4 do
	local a = i / 5 * math.pi * 2
	b:B("HeadDetail", V(0.12, 0.12, 0.04), V(math.sin(a) * 0.33, cy + math.cos(a) * 0.33, -0.44), HUB_DARK) -- bolts
end
-- frog head on top of the tyre
b:B(H, V(1.6, 0.9, 1.3), V(0, 3.75, 0), FROG)
b:B(H, V(1.3, 0.3, 1.1), V(0, 3.4, -0.1), BELLY)
for _, s in { -1, 1 } do
	b:B(H, V(0.55, 0.5, 0.55), V(s * 0.45, 4.35, -0.15), FROG) -- eye bumps
	b:eye(V(s * 0.45, 4.38, -0.43), 0.4, V(0, 0, -1), Vector2.new(0, 0))
	b:B("HeadDetail", V(0.06, 0.06, 0.03), V(s * 0.15, 3.85, -0.66), FROG_DARK) -- nostrils
	b:B("HeadDetail", V(0.2, 0.1, 0.03), V(s * 0.6, 3.65, -0.66), Color3.fromHex("ff9aa8"))
end
b:mouth(V(0, 3.55, -0.66), 1.1, 0.1, V(0, 0, -1), 0, 14)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
