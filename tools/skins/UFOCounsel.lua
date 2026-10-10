-- UFO Counsel (Rare, Space egg) - block remake 2026-10-10. A hovering flying saucer piloted by a little green alien:
-- a wide grey disc (octagonal, darker rim) with a ring of glowing green lights, a see-through glass dome, inside it a
-- green alien with big glossy eyes, two antennae poking out through the top, a tiny red tie; a glowing green
-- beam emitter underneath. Front-facing, HOVERS. Rare: Neon lights, 1.25x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("UFOCounsel")
local V = Vector3.new
local C = Kit.C
local HULL, HULL_DARK, HULL_LIGHT = Color3.fromHex("7a7a90"), Color3.fromHex("4a4a5c"), Color3.fromHex("a0a0b8")
local ALIEN, ALIEN_DARK, GLOW, GLASS = Color3.fromHex("78e664"), Color3.fromHex("52b844"), Color3.fromHex("8dff6a"), Color3.fromHex("bfe8ff")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"
local dy = 1.4

-- saucer: underside, wide disc (two crossed squares), rim, top deck
b:B(T, V(1.8, 0.35, 1.8), V(0, dy - 0.32, 0), HULL_DARK)
b:B(T, V(2.7, 0.2, 2.5), V(0, dy - 0.15, 0), HULL_DARK)          -- stepped underside
b:B(T, V(1.0, 0.12, 1.0), V(0, dy - 0.46, 0), GLOW, nil, NEON) -- beam emitter
b:B(T, V(3.4, 0.36, 3.0), V(0, dy + 0.1, 0), HULL)
b:B(T, V(3.0, 0.36, 3.4), V(0, dy + 0.1, 0), HULL)
b:B(T, V(3.5, 0.1, 3.1), V(0, dy - 0.05, 0), HULL_DARK)
b:B(T, V(2.4, 0.2, 2.2), V(0, dy + 0.38, 0), HULL_LIGHT)
-- ring of glowing lights around the rim
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	b:B(T, V(0.28, 0.2, 0.28), V(math.sin(a) * 1.78, dy + 0.1, math.cos(a) * 1.66), if i % 2 == 0 then GLOW else Color3.fromHex("fff28a"), nil, NEON)
end
-- the alien pilot
b:B(T, V(0.8, 0.6, 0.6), V(0, dy + 0.75, 0), ALIEN_DARK)
b:B("HeadDetail", V(0.1, 0.35, 0.04), V(0, dy + 0.75, -0.32), Color3.fromHex("d62a36"))
b:B(H, V(1.1, 0.9, 0.95), V(0, dy + 1.45, 0), ALIEN)
b:B(H, V(0.9, 0.3, 0.8), V(0, dy + 1.98, 0), ALIEN)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, dy + 1.5, -0.48), 0.38, V(0, 0, -1), Vector2.new(0, 0)) -- big glossy eyes
	b:B(H, V(0.06, 0.6, 0.06), V(s * 0.25, dy + 2.4, 0), ALIEN_DARK, V(0, 0, s * -15))
	b:B(H, V(0.16, 0.16, 0.16), V(s * 0.33, dy + 2.72, 0), GLOW, nil, NEON)
end
b:mouth(V(0, dy + 1.18, -0.48), 0.28, 0.08, V(0, 0, -1), 0, 18)
-- glass dome over the pilot
for _, d in { { V(1.9, 1.3, 1.6), 1.45 }, { V(1.5, 0.35, 1.3), 2.25 } } do
	local p = b:B(T, d[1], V(0, dy + d[2], 0), GLASS)
	p.Transparency = 0.65
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.25)
b.hover = 1.0
print(b:preview())
_G.SkinBuild = b
