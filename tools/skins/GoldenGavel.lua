-- Golden Gavel (Rare) - block remake 2026-10-10. A walking golden gavel: the big gold gavel head is the head/body
-- (face on its front, darker bands near the ends), a little gold crown on top, the wooden handle runs down as the
-- body to a round gold sound-block it stands on, with stubby arms + white gloves off the handle. Front-facing.
-- Rare: Neon gold sparkles, 1.05x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("GoldenGavel")
local V = Vector3.new
local C = Kit.C
local GOLD, GOLD_DARK, GOLD_LIGHT = Color3.fromHex("ffc828"), Color3.fromHex("d99a10"), Color3.fromHex("ffe27a")
local WOOD, WOOD_DARK = Color3.fromHex("8a5a2e"), Color3.fromHex("6b4426")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"

-- round sound-block base (the gavel's stand) with two little feet poking out
b:B("LeftUpperLeg", V(1.7, 0.35, 1.5), V(0, 0.18, 0), WOOD_DARK)
b:B("LeftUpperLeg", V(1.5, 0.35, 1.7), V(0, 0.18, 0), WOOD_DARK)
b:B("LeftUpperLeg", V(1.4, 0.1, 1.3), V(0, 0.4, 0), GOLD)
for _, s in { -1, 1 } do
	b:B(s < 0 and "LeftUpperLeg" or "RightUpperLeg", V(0.4, 0.22, 0.4), V(s * 0.35, 0.56, -0.55), C.White)
end
-- the handle: the body, a wooden pole with gold bands and a gold knob at the base
b:B(T, V(0.6, 2.2, 0.6), V(0, 1.7, 0), WOOD)
b:B(T, V(0.66, 0.14, 0.66), V(0, 1.1, 0), GOLD)
b:B(T, V(0.66, 0.14, 0.66), V(0, 2.3, 0), GOLD)
b:B(T, V(0.75, 0.3, 0.75), V(0, 0.6, 0), GOLD)
b:B(T, V(0.06, 1.8, 0.03), V(0.15, 1.7, -0.31), WOOD_DARK) -- grain
-- stubby arms + white gloves off the handle; one thumbs-up
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.16, 0.16), V(s * 0.55, 2.0, -0.1), WOOD_DARK, V(0, 0, s * -25))
	b:B(name, V(0.3, 0.3, 0.3), V(s * 0.85, 2.2, -0.15), C.White)
end
b:B("RightUpperArm", V(0.1, 0.22, 0.1), V(0.85, 2.44, -0.18), C.White)
-- the gavel head: wide gold block, darker end bands, lighter faces at the ends
b:B(H, V(2.8, 1.3, 1.3), V(0, 3.3, 0), GOLD)
b:B(H, V(2.6, 1.45, 1.1), V(0, 3.3, 0), GOLD)
for _, s in { -1, 1 } do
	b:B(H, V(0.18, 1.34, 1.34), V(s * 1.0, 3.3, 0), GOLD_DARK)
	b:B(H, V(0.12, 1.1, 1.1), V(s * 1.44, 3.3, 0), GOLD_LIGHT)
end
-- face on the front of the head (between the bands)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.38, 3.45, -0.66), 0.42, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.4, 3.76, -0.67), 0.4, V(0, 0, -1), s * 10, GOLD_DARK)
end
b:mouth(V(0, 3.0, -0.66), 0.5, 0.14, V(0, 0, -1), 5, 18)
-- little crown on top
b:B(H, V(0.9, 0.2, 0.7), V(0, 4.12, 0), GOLD_DARK)
for i = -1, 1 do
	b:B(H, V(0.18, 0.28 + (if i == 0 then 0.1 else 0), 0.18), V(i * 0.32, 4.34, -0.22), GOLD_DARK)
end
b:B(H, V(0.14, 0.14, 0.06), V(0, 4.12, -0.37), Color3.fromHex("e0303a"))
-- Neon sparkles
for _, sp in { { -1.9, 4.3, -0.2 }, { 1.85, 4.0, 0.1 }, { -1.7, 2.1, -0.3 }, { 1.6, 1.6, -0.2 } } do
	b:B(T, V(0.16, 0.16, 0.16), V(sp[1], sp[2], sp[3]), GOLD_LIGHT, V(0, 0, 45), NEON)
end
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
