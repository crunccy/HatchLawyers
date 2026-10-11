-- Neighbor Dave (Common client) - v3 remodel 2026-10-10, the quality benchmark for the cast.
-- "The king of dad jokes. Mows his lawn at 6 a.m., wears socks with sandals on principle, never lost a barbecue
-- argument." Sky-blue polo (collar, placket, buttons, cuffs) over a little dad belly, khaki cargo shorts with side
-- pockets and a belt, striped white tube socks IN sandals, a red dad cap over short brown hair, a mustache (face
-- decal), a BBQ spatula in his hand.
local Kit = require(game.ServerStorage.ClientKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local k = Kit.new("NeighborDave")
local D = Kit.D
local SKIN, POLO, POLO_D, KHAKI, KHAKI_D = H("f1c49a"), H("4f95dc"), H("3672b0"), H("c9a66b"), H("a8854e")
local HAIR, CAP, CAP_D, SOCK, BROWN = H("6b4226"), H("d93b3b"), H("a82424"), H("f6f6f2"), H("7a4a24")

k:body({
	skin = SKIN, shirt = POLO, pants = KHAKI, sleeves = "short", cuff = POLO_D, legs = "shorts",
	socks = SOCK, sockH = 0.78, sandals = true, shoes = BROWN, torsoD = 1.02,
})
local hip, sh = Kit.hipY, Kit.shoulderY

-- dad belly: a soft dome on the front of the polo
k:ell("UpperTorso", V(1.36, 0.98, 0.42), V(0, hip + 0.6, -0.44), POLO)
-- polo collar (two flaps folded down) + placket with two buttons
for _, s in { -1, 1 } do
	k:rbox("UpperTorso", V(0.5, 0.1, 0.36), V(s * 0.24, sh - 0.02, -0.38), POLO_D, 0.04, V(-25, s * -18, s * 12))
end
k:rbox("UpperTorso", V(1.0, 0.14, 0.9), V(0, sh + 0.0, 0.05), POLO_D, 0.06) -- collar band round the neck
k:rbox("UpperTorso", V(0.22, 0.55, 0.06), V(0, sh - 0.4, -0.52), POLO_D, 0.03)
for _, y in { sh - 0.27, sh - 0.52 } do
	k:cyl("UpperTorso", V(0.04, 0.09, 0.09), V(0, y, -0.56), H("f2f2f2"), V(0, 90, 0))
end
-- belt + buckle, cargo pockets with flaps on both legs
k:rbox("UpperTorso", V(D.torsoW + 0.05, 0.17, 1.07), V(0, hip + 0.06, 0), BROWN, 0.07)
k:rbox("UpperTorso", V(0.26, 0.2, 0.06), V(0, hip + 0.06, -0.55), H("e8c050"), 0.04)
for _, s in { -1, 1 } do
	local x = s * (Kit.legX + D.legW / 2 + 0.03)
	local leg = if s < 0 then "RightUpperLeg" else "LeftUpperLeg"
	k:rbox(leg, V(0.08, 0.44, 0.5), V(x, hip - 0.55, 0.0), KHAKI_D, 0.03)
	k:rbox(leg, V(0.1, 0.12, 0.54), V(x, hip - 0.33, 0.0), KHAKI_D, 0.03)
	-- sock stripes
	for _, sy in { 0.88, 0.98 } do
		k:rbox(leg, V(D.legW - 0.06, 0.06, D.legD - 0.06), V(s * Kit.legX, sy, 0), if sy < 0.9 then H("d93b3b") else H("3672b0"), 0.03)
	end
end
-- short brown hair under a red dad cap (dome + brim + button)
k:hair({ color = HAIR, top = -0.06, front = 0.26, back = -0.42, sides = 0.42, puff = 0.07, hat = true }) -- (stays under the cap)
k:capHat(CAP, CAP_D)
local capY = Kit.headY + D.headH / 2 - 0.3
k:rbox("HeadDetail", V(0.52, 0.28, 0.05), V(0, capY + 0.24, -0.77), H("ffffff"), 0.04) -- cap patch
k:rbox("HeadDetail", V(0.44, 0.22, 0.08), V(0, capY + 0.12, 0.8), H("e8e2d4"), 0.04) -- back strap adjuster
k:face("rbxassetid://83719909215242")
-- BBQ spatula in his right hand (the -X hand), held up
local hx, hy = -Kit.armX, sh - D.armH + 0.2
k:rbox("RightUpperArm", V(0.12, 0.95, 0.12), V(hx, hy + 0.4, -0.42), H("3a2a1e"), 0.05, V(-18, 0, 0))
k:carve("RightUpperArm", V(0.5, 0.56, 0.06), V(hx, hy + 1.08, -0.65), H("b8bec8"), 0.06, {
	{ V(0.06, 0.32, 0.2), V(hx - 0.12, hy + 1.1, -0.65), V(-18, 0, 0) },
	{ V(0.06, 0.32, 0.2), V(hx, hy + 1.1, -0.65), V(-18, 0, 0) },
	{ V(0.06, 0.32, 0.2), V(hx + 0.12, hy + 1.1, -0.65), V(-18, 0, 0) },
}, V(-18, 0, 0))

k:finish()
print(k:preview())
_G.ClientBuild = k
