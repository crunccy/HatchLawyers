-- Astro (Uncommon, Space egg) - block remake 2026-10-10. A chunky astronaut lawyer: puffy white space suit
-- with grey joint bands, a big round helmet with a see-through light-blue visor (face visible inside), a chest control
-- panel, a backpack, moon boots, and a silver briefcase. Front-facing. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("AstroAttorney")
local V = Vector3.new
local C = Kit.C
local SUIT, BAND, VISOR, SKIN = Color3.fromHex("f0f0f5"), Color3.fromHex("a0a4b0"), Color3.fromHex("b4dcff"), Color3.fromHex("f0c8a0")
local PANEL, RED, BLUE = Color3.fromHex("3a3f4a"), Color3.fromHex("e0303a"), Color3.fromHex("2f7bff")
local T, H = "UpperTorso", "Head"

-- legs + moon boots
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.6, 1.2, 0.65), V(s * 0.36, 1.0, 0), SUIT)
	b:B(name, V(0.64, 0.12, 0.69), V(s * 0.36, 1.1, 0), BAND)
	b:B(name, V(0.7, 0.45, 0.9), V(s * 0.37, 0.22, -0.08), BAND)
end
-- puffy torso, chest panel with buttons, backpack
b:B(T, V(1.7, 1.55, 1.1), V(0, 2.35, 0), SUIT)
b:B(T, V(1.74, 0.14, 1.14), V(0, 1.7, 0), BAND)
b:B("HeadDetail", V(0.8, 0.5, 0.06), V(0, 2.45, -0.57), PANEL)
for i, col in { RED, BLUE, Color3.fromHex("6cd66c") } do
	b:B("HeadDetail", V(0.14, 0.14, 0.04), V(-0.25 + (i - 1) * 0.25, 2.5, -0.61), col)
end
b:B(T, V(1.3, 1.3, 0.5), V(0, 2.4, 0.75), SUIT)
b:B(T, V(1.0, 0.3, 0.52), V(0, 2.7, 0.76), BAND)
-- puffy arms; one carries a silver briefcase
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.55, 1.25, 0.6), V(s * 1.12, 2.3, 0), SUIT)
	b:B(name, V(0.59, 0.12, 0.64), V(s * 1.12, 2.2, 0), BAND)
	b:B(name, V(0.5, 0.35, 0.55), V(s * 1.12, 1.55, 0), BAND) -- gloves
end
b:B("RightUpperArm", V(0.24, 0.1, 0.08), V(1.12, 1.35, 0), PANEL)
b:B("RightUpperArm", V(0.8, 0.55, 0.22), V(1.12, 1.05, 0), Color3.fromHex("c3c9d2"))
-- helmet: big round (crossed slabs), visor window with the face inside
b:B(H, V(1.7, 1.5, 1.2), V(0, 3.85, 0.15), SUIT)
b:B(H, V(1.5, 1.7, 1.0), V(0, 3.85, 0.15), SUIT)
b:B(H, V(1.2, 1.0, 0.3), V(0, 3.85, -0.45), SKIN) -- the face inside
for _, e in { { 0, 0.58, 1.5, 0.14 }, { 0, -0.58, 1.5, 0.14 }, { 0.72, 0, 0.14, 1.3 }, { -0.72, 0, 0.14, 1.3 } } do
	b:B(H, V(e[3], e[4], 0.3), V(e[1], 3.85 + e[2], -0.6), BAND) -- visor frame
end
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, 3.92, -0.61), 0.3, V(0, 0, -1), Vector2.new(0, 0))
end
b:mouth(V(0, 3.58, -0.61), 0.3, 0.08, V(0, 0, -1), 0, 20)
local v = b:B(H, V(1.3, 1.05, 0.06), V(0, 3.85, -0.7), VISOR)
v.Transparency = 0.55
b:B(H, V(0.22, 0.4, 0.04), V(-0.42, 4.05, -0.74), C.White).Transparency = 0.4 -- glare
b:B(H, V(0.1, 0.4, 0.1), V(0.5, 4.85, 0), BAND) -- antenna
b:B(H, V(0.18, 0.18, 0.18), V(0.5, 5.1, 0), RED)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
