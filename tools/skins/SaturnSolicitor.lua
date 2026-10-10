-- Saturn Solicitor (Rare, Space egg) - block remake 2026-10-10. A lawyer whose whole head IS the planet Saturn: a
-- big cream/tan banded planet head with a tilted solid ring around it (deliberately unlike the Black Hole Barrister's
-- hovering orb - this one stands on legs in a purple suit), face on the planet, two tiny orbiting moons, a gold
-- star tie pin. Front-facing. Rare: small Neon moons, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("SaturnSolicitor")
local V = Vector3.new
local C = Kit.C
local PLANET, BAND1, BAND2 = Color3.fromHex("f0c878"), Color3.fromHex("d9a85a"), Color3.fromHex("e8b86a")
local RING, RING_DARK = Color3.fromHex("f6e3b4"), Color3.fromHex("c9a46a")
local SUIT, SUIT_DARK, SHIRT, TIE = Color3.fromHex("3c286e"), Color3.fromHex("2a1c52"), Color3.fromHex("f5f5f5"), Color3.fromHex("f0c878")
local T, H = "UpperTorso", "Head"

-- legs + shoes
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.45, 1.4, 0.5), V(s * 0.3, 1.0, 0), SUIT_DARK)
	b:B(name, V(0.5, 0.25, 0.75), V(s * 0.3, 0.13, -0.1), C.Line)
end
-- suit body: jacket, shirt, tie with a gold star pin, lapels, buttons
b:B(T, V(1.5, 1.5, 0.85), V(0, 2.45, 0), SUIT)
b:B("HeadDetail", V(0.5, 1.0, 0.05), V(0, 2.7, -0.44), SHIRT)
b:B("HeadDetail", V(0.16, 0.85, 0.04), V(0, 2.6, -0.47), TIE)
b:B("HeadDetail", V(0.16, 0.16, 0.04), V(0, 2.65, -0.5), C.Gold, V(0, 0, 45))
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.16, 0.85, 0.05), V(s * 0.32, 2.75, -0.45), SUIT_DARK, V(0, 0, s * 15))
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.42, 1.35, 0.5), V(s * 0.98, 2.4, 0), SUIT)
	b:B(name, V(0.4, 0.32, 0.45), V(s * 0.98, 1.6, 0), PLANET)
end
b:B("HeadDetail", V(0.1, 0.1, 0.04), V(0, 2.0, -0.45), C.Gold)
-- the planet head: rounded block with darker bands
local hy = 4.35
b:B(H, V(1.9, 1.6, 1.6), V(0, hy, 0), PLANET)
b:B(H, V(1.6, 1.9, 1.4), V(0, hy, 0), PLANET)
b:B(H, V(1.94, 0.12, 1.64), V(0, hy + 0.9, 0), BAND1)
b:B(H, V(1.94, 0.12, 1.64), V(0, hy - 0.62, 0), BAND2)
b:B(H, V(1.64, 0.12, 1.44), V(0, hy + 1.0, 0), BAND2)
-- the ring: 12 flat segments around the planet, tilted
local tilt = CFrame.new(0, hy - 0.05, 0) * CFrame.Angles(math.rad(-22), 0, math.rad(-12))
for i = 0, 11 do
	local a = i / 12 * math.pi * 2
	b:BAt(H, V(0.95, 0.1, 0.5), tilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 1.6), if i % 2 == 0 then RING else RING_DARK)
end
-- face on the planet (above the ring line)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.38, hy + 0.4, -0.81), 0.42, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.4, hy + 0.7, -0.82), 0.4, V(0, 0, -1), s * 6, BAND1)
	b:B("HeadDetail", V(0.22, 0.1, 0.04), V(s * 0.62, hy + 0.12, -0.81), Color3.fromHex("ff9a7a"))
end
b:mouth(V(0, hy - 0.02, -0.81), 0.4, 0.12, V(0, 0, -1), 4, 16)
-- tiny Neon moons
b:B(T, V(0.22, 0.22, 0.22), V(-1.7, hy + 0.9, 0.3), Color3.fromHex("cfd8ff"), nil, Enum.Material.Neon)
b:B(T, V(0.16, 0.16, 0.16), V(1.6, hy - 1.0, -0.4), Color3.fromHex("ffd9a8"), nil, Enum.Material.Neon)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
