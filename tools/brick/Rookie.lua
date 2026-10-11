-- Rookie Lawyer (Common, the starting lawyer) - brick style benchmark 2026-10-11 (docs/CHARACTER_STYLE.md).
-- A first-day lawyer in a hand-me-down navy suit one size too big: the jacket hangs past the hip and the sleeves
-- cover half the hand, a white shirt V with a red tie, side-parted brown hair with one cowlick brick sticking up,
-- a nervous-eager face (pupils up and in, brows raised, small straight mouth), a briefcase with a gold clasp.
-- Colours are his old ones so players still recognise him. Common: no trim.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local k = Kit.new("Rookie", (_G.BrickOrigin or {}).Rookie)

local SUIT, LAPEL, PANTS, SHIRT, TIE = H("2c3e60"), H("23324f"), H("202026"), H("f2efe8"), H("c82832")
local SKIN, HAIR, SHOES, CASE, CLASP = H("ffd3a8"), H("5a3a22"), H("24242c"), H("7a4a24"), H("ffc828")

k:body({ skin = SKIN, shirt = SUIT, pants = PANTS, shoes = SHOES })
local hipY, shY = Kit.hipY, Kit.shoulderY

-- one size too big: the jacket hem hangs past the hip, the sleeves come down over half the hand
k:brick("UpperTorso", V(D.torsoW + 0.1, 0.34, D.torsoD + 0.1), V(0, hipY - 0.05, 0), SUIT)
for _, s in { -1, 1 } do
	k:brick(Kit.armName(s), V(D.armW + 0.06, 0.24, D.armD + 0.06), V(s * Kit.armX, shY - D.armH + D.handH - 0.1, 0), SUIT)
end
k:lapels(SUIT, SHIRT, { lapel = LAPEL, depth = 0.9 })
k:tie(TIE, 0.6)
k:buttons(2, H("161e30"), 0, hipY + 0.42, 0.26)

-- face: nervous but eager
k:eyes({ look = Vector2.new(0, 0.55), inward = 0.2 })
k:brows(HAIR, { raise = 0.05 })
k:nose()
k:mouth("flat", { w = 0.36 })

-- side-parted hair: the cap, a swoop on his right (screen left) and one cowlick at the crown
local top = k:hairCap(HAIR, { top = 0.16, sideburn = 0.6, back = 1.15 })
k:brick("HeadDetail", V(1.2, 0.28, 0.7), V(-0.38, top + 0.1, Kit.faceZ + 0.3), HAIR)
k:brick("HeadDetail", V(0.22, 0.42, 0.22), V(0.42, top + 0.18, 0.35), HAIR, V(18, 0, -22))

-- briefcase in his right hand (the -X side), broad side along his leg
local hand = k:hand(-1)
local cx = hand.X - 0.06
k:plate("RightUpperArm", V(0.1, 0.1, 0.44), V(cx, hand.Y - D.handH / 2 - 0.04, 0), H("3a2414"))
k:brick("RightUpperArm", V(0.38, 0.74, 1.04), V(cx, hand.Y - D.handH / 2 - 0.12 - 0.37, 0), CASE)
k:plate("RightUpperArm", V(0.42, 0.12, 0.22), V(cx, hand.Y - D.handH / 2 - 0.22, 0), CLASP)

_G.BrickBuild = _G.BrickBuild or {}
_G.BrickBuild.Rookie = k
return k:preview(game:GetService("ReplicatedStorage").SkinModels:FindFirstChild("Rookie"))
