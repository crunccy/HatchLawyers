-- Neighbor Dave (Tier 1 client) - brick style benchmark 2026-10-11 (docs/CHARACTER_STYLE.md).
-- The dad-joke neighbour who mows at 6 a.m.: sky-blue polo (collar flaps, placket, two buttons, cuffs) over a little
-- dad belly, khaki cargo shorts with side pockets and a belt, striped tube socks IN sandals, a red dad cap over
-- short brown hair, a brick mustache over a big grin, a BBQ spatula held up. Same outfit as his v3 model, rebuilt
-- in studded bricks with a brick face instead of the drawn decal. Tier 1: plain, no trim.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local k = Kit.new("NeighborDave", (_G.BrickOrigin or {}).NeighborDave)

local SKIN, POLO, POLO_D, KHAKI, KHAKI_D = H("f1c49a"), H("4f95dc"), H("3672b0"), H("c9a66b"), H("a8854e")
local HAIR, CAP, CAP_D, SOCK, BROWN = H("6b4226"), H("d93b3b"), H("a82424"), H("f6f6f2"), H("7a4a24")

k:body({
	skin = SKIN, shirt = POLO, pants = KHAKI, sleeves = "short", legs = "shorts",
	socks = SOCK, sockH = 0.42, sandals = true, shoes = BROWN,
})
local hipY, shY = Kit.hipY, Kit.shoulderY
local fz = k:frontZ()

-- dad belly, then the polo: collar band, two collar flaps, placket with two buttons, darker cuffs
k:brick("UpperTorso", V(1.6, 0.72, 0.24), V(0, hipY + 0.5, fz - 0.1), POLO)
k:brick("UpperTorso", V(1.2, 0.14, 1.0), V(0, shY + 0.02, 0.02), POLO_D)
for _, s in { -1, 1 } do
	k:plate("UpperTorso", V(0.42, 0.12, 0.3), V(s * 0.25, shY - 0.06, fz - 0.06), POLO_D, V(-30, s * -12, s * 14))
end
k:plate("UpperTorso", V(0.22, 0.48, 0.05), V(0, shY - 0.36, fz - 0.03), POLO_D)
k:buttons(2, H("fbfaf6"), 0, shY - 0.26, 0.2)
for _, s in { -1, 1 } do
	k:brick(Kit.armName(s), V(D.armW + 0.1, 0.12, D.armD + 0.1), V(s * Kit.armX, shY - 0.5 + 0.04, 0), POLO_D)
end
-- belt + buckle, cargo pockets on the outside of each leg, red / blue stripes on the tube socks
k:belt(BROWN, H("e8c050"))
for _, s in { -1, 1 } do
	local leg = Kit.legName(s)
	local x = s * (Kit.legX + D.legW / 2 + 0.04)
	k:plate(leg, V(0.08, 0.3, 0.5), V(x, hipY - 0.32, 0), KHAKI_D)
	k:plate(leg, V(0.1, 0.08, 0.54), V(x, hipY - 0.16, 0), KHAKI_D)
	for i, c in { H("d93b3b"), H("3672b0") } do
		k:plate(leg, V(D.legW - 0.02, 0.06, D.legD - 0.02), V(s * Kit.legX, 0.4 + 0.42 - 0.08 - (i - 1) * 0.12, 0), c)
	end
end

-- face: a big dad grin under a brick mustache, brows up
k:eyes({ y = -0.04, look = Vector2.new(0, 0.2) })
k:brows(HAIR, { y = -0.04, raise = 0.0, tilt = -6 }) -- low enough to show under the cap
k:nose(nil, { y = -0.2 })
k:mouth("grin", { w = 0.6, y = -0.64, h = 0.22 })
k:brick("HeadDetail", V(0.78, 0.16, 0.12), V(0, Kit.headY - 0.45, Kit.faceZ - 0.08), HAIR)
for _, s in { -1, 1 } do
	k:brick("HeadDetail", V(0.14, 0.2, 0.12), V(s * 0.42, Kit.headY - 0.51, Kit.faceZ - 0.08), HAIR)
end

-- short brown hair at the sides and back, under a red dad cap with a white front patch
k:hairCap(HAIR, { noTop = true, sideburn = 0.55, back = 1.0, hat = true })
local capTop = k:cap(CAP, CAP_D, { down = 0.34, crownH = 0.6 })
k:plate("HeadDetail", V(0.6, 0.3, 0.05), V(0, capTop - 0.3, Kit.faceZ - 0.1), H("fbfaf6"))

-- BBQ spatula held up in his right hand (the -X side)
local hand = k:hand(-1)
k:plate("RightUpperArm", V(0.12, 0.9, 0.12), V(hand.X, hand.Y + 0.38, -0.3), H("3a2a1e"), V(-24, 0, 0))
k:plate("RightUpperArm", V(0.5, 0.52, 0.06), V(hand.X, hand.Y + 0.98, -0.58), H("b8bec8"), V(-24, 0, 0))
for _, dx in { -0.12, 0, 0.12 } do
	k:plate("RightUpperArm", V(0.05, 0.28, 0.07), V(hand.X + dx, hand.Y + 1.02, -0.6), H("6c727c"), V(-24, 0, 0))
end

k:finishClient()
_G.BrickBuild = _G.BrickBuild or {}
_G.BrickBuild.NeighborDave = k
return k:preview(game:GetService("ServerStorage").Templates.Clients:FindFirstChild("NeighborDave"))
