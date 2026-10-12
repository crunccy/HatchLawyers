-- Inky the Kraken (Legendary) - block remake 2026-10-10. A big red kraken: tall stepped mantle head with darker spots,
-- huge eyes and a toothy grin, a navy-and-white sea captain's hat with a gold anchor badge, four curling tentacle legs
-- (pale sucker dots) and two tentacle arms raised - one holding a big gold anchor, one a rolled legal scroll.
-- Front-facing, HOVERS a little so the tentacles dangle. Legendary: gold anchor + trims, 1.25x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("KrakenCounsel")
local V = Vector3.new
local C = Kit.C
local RED, RED_DARK, SPOT, SUCKER = Color3.fromHex("d9453a"), Color3.fromHex("a82e27"), Color3.fromHex("8e2420"), Color3.fromHex("f5b0a0")
local NAVY, CAPWHITE, BLACK, SCROLL = Color3.fromHex("1f2f5c"), Color3.fromHex("f5f5f5"), Color3.fromHex("1c1c20"), Color3.fromHex("f3e2b8")
local T, H = "UpperTorso", "Head"

-- mantle: a tall rounded head (core + crossing slabs) with a stepped dome
b:B(H, V(2.2, 2.0, 2.0), V(0, 3.0, 0), RED)
b:B(H, V(2.4, 1.5, 1.6), V(0, 3.0, 0), RED)
b:B(H, V(1.8, 0.5, 1.7), V(0, 4.2, 0), RED)
b:B(H, V(1.3, 0.3, 1.2), V(0, 4.55, 0.05), RED)
b:B(T, V(2.0, 0.3, 1.8), V(0, 1.9, 0), RED_DARK) -- underside where the tentacles start
for _, sp in { { -0.75, 4.1, -0.6 }, { 0.55, 4.35, -0.45 }, { 0.9, 3.7, -0.8 }, { -1.05, 3.4, -0.55 } } do
	b:B("HeadDetail", V(0.26, 0.2, 0.06), V(sp[1], sp[2], sp[3] - 0.27), SPOT)
end
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.06, 0.3, 0.3), V(s * 1.22, 3.4, 0.2), SPOT)
	b:B("HeadDetail", V(0.06, 0.22, 0.22), V(s * 1.22, 2.7, -0.3), SPOT)
end
-- face: huge eyes, cocky brows, toothy grin
for _, s in { -1, 1 } do
	b:eye(V(s * 0.5, 3.0, -1.01), 0.58, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.52, 3.46, -1.02), 0.56, V(0, 0, -1), s * 8, RED_DARK)
end
b:mouth(V(0, 2.38, -1.01), 0.85, 0.2, V(0, 0, -1), 7, 16)
-- captain's hat: white crown, navy band, black brim, gold anchor badge
b:B(H, V(1.6, 0.42, 1.5), V(0, 4.85, 0), CAPWHITE)
b:B(H, V(1.5, 0.24, 1.42), V(0, 4.55, 0), NAVY)
b:B(H, V(1.4, 0.08, 0.55), V(0, 4.46, -0.92), BLACK, V(-8, 0, 0))
b:B(H, V(1.52, 0.05, 0.06), V(0, 4.66, -0.72), C.Gold) -- gold cord over the brim
b:B("HeadDetail", V(0.08, 0.3, 0.05), V(0, 4.85, -0.77), C.Gold)  -- badge: little anchor
b:B("HeadDetail", V(0.26, 0.06, 0.05), V(0, 4.94, -0.77), C.Gold)
b:B("HeadDetail", V(0.3, 0.07, 0.05), V(0, 4.72, -0.77), C.Gold)
-- four tentacle legs, curling outward and up at the tips, sucker dots on the front ones
for _, deg in { -35, 35, -145, 145 } do
	local a = math.rad(deg)
	local base = CFrame.Angles(0, a, 0)
	local name = (if deg < 0 then "Left" else "Right") .. "UpperLeg"
	b:BAt(name, V(0.5, 0.8, 0.5), base * CFrame.new(0, 1.5, -0.8) * CFrame.Angles(math.rad(20), 0, 0), RED)
	b:BAt(name, V(0.42, 0.7, 0.42), base * CFrame.new(0, 0.85, -1.15) * CFrame.Angles(math.rad(40), 0, 0), RED)
	b:BAt(name, V(0.34, 0.5, 0.34), base * CFrame.new(0, 0.42, -1.55) * CFrame.Angles(math.rad(75), 0, 0), RED)
	b:BAt(name, V(0.28, 0.4, 0.28), base * CFrame.new(0, 0.5, -1.92) * CFrame.Angles(math.rad(150), 0, 0), RED_DARK) -- curled tip
	if math.abs(deg) < 90 then
		for i, at in { CFrame.new(0, 1.45, -1.06), CFrame.new(0, 0.85, -1.4) } do
			b:BAt("HeadDetail", V(0.16, 0.16, 0.06), base * at * CFrame.Angles(math.rad(20 * i), 0, 0), SUCKER)
		end
	end
end
-- tentacle arms raised to the sides
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.8, 0.45, 0.45), V(s * 1.45, 2.45, -0.2), RED, V(0, 0, s * 20))
	b:B(name, V(0.42, 0.8, 0.42), V(s * 1.9, 2.95, -0.3), RED, V(0, 0, s * -10))
	b:B(name, V(0.34, 0.5, 0.34), V(s * 1.95, 3.5, -0.35), RED_DARK)
	b:B("HeadDetail", V(0.14, 0.14, 0.05), V(s * 1.9, 2.9, -0.53), SUCKER)
end
-- big gold anchor in the +X tentacle
local ax, az = 1.95, -0.75
b:B("RightUpperArm", V(0.18, 1.8, 0.18), V(ax, 3.1, az), C.Gold)                 -- shank
b:B("RightUpperArm", V(0.8, 0.16, 0.16), V(ax, 3.7, az), C.Gold)                 -- stock
b:B("RightUpperArm", V(0.34, 0.34, 0.1), V(ax, 4.1, az), C.Gold)                 -- ring
b:B("RightUpperArm", V(0.18, 0.18, 0.12), V(ax, 4.1, az), RED_DARK)              -- (hole in the ring)
b:B("RightUpperArm", V(1.1, 0.18, 0.18), V(ax, 2.25, az), C.GoldDark)            -- crown
for _, s in { -1, 1 } do
	b:B("RightUpperArm", V(0.18, 0.45, 0.18), V(ax + s * 0.5, 2.48, az), C.GoldDark, V(0, 0, s * -20)) -- arms
	b:B("RightUpperArm", V(0.3, 0.2, 0.2), V(ax + s * 0.62, 2.72, az), C.Gold)                         -- flukes
end
-- rolled legal scroll in the -X tentacle, red wax seal
b:B("LeftUpperArm", V(0.32, 1.1, 0.32), V(-1.95, 3.5, -0.65), SCROLL, V(0, 0, 25))
b:B("LeftUpperArm", V(0.36, 0.1, 0.36), V(-1.73, 3.98, -0.65), Color3.fromHex("d8c08a"), V(0, 0, 25))
b:B("LeftUpperArm", V(0.2, 0.2, 0.08), V(-1.98, 3.45, -0.83), Color3.fromHex("c0282e"))
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.25)
b.hover = 0.5
print(b:preview())
_G.SkinBuild = b
