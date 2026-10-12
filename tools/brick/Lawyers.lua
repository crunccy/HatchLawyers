-- The people-shaped lawyers in the brick style (2026-10-11, docs/CHARACTER_STYLE.md), rebuilt on BrickKit's frame.
-- Each keeps its 2026-10-10 design (tools/skins/<Id>.lua: colours, outfit, props, personality) on the chibi frame.
-- Rookie has its own file (tools/brick/Rookie.lua, the benchmark). The creature lawyers were converted in place
-- (tools/brick/ConvertLawyers.lua). Run: tools/brick/Run.lua with _G.BrickRun = { file = this, ids = {...} }.
-- Arms are built hanging (the rest pose) and posed with k:poseArm last, so props swing with them.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local HIP, SH, HY, HT, FZ = Kit.hipY, Kit.shoulderY, Kit.headY, Kit.headTop, Kit.faceZ
local AX, LX = Kit.armX, Kit.legX
local WHITE, INK, GOLD, GOLD_D, RARE = Kit.C.White, Kit.C.Ink, Kit.C.Gold, Kit.C.GoldDark, Kit.C.Rare

local L = {}

-- Intern Suit (Common): a nervous new intern in a slightly-too-big grey suit with a blue tie, a lanyard + ID badge,
-- messy hair, big worried eyes, a sweat drop, a tall wobbly stack of papers.
L.InternSuit = function(k)
	local SUIT, SUIT_D, PANTS, TIE = H("aaacba"), H("8e90a0"), H("464856"), H("508cff")
	local SKIN, HAIR, LANY = H("f0c8a0"), H("8a5a2e"), H("2f7bff")
	k:body({ skin = SKIN, shirt = SUIT, pants = PANTS, shoes = INK })
	k:brick("UpperTorso", V(D.torsoW + 0.1, 0.3, D.torsoD + 0.1), V(0, HIP - 0.05, 0), SUIT)
	for _, s in { -1, 1 } do
		k:brick(Kit.armName(s), V(D.armW + 0.06, 0.24, D.armD + 0.06), V(s * AX, SH - D.armH + D.handH - 0.1, 0), SUIT)
	end
	k:lapels(SUIT, WHITE, { lapel = SUIT_D, depth = 0.9 })
	k:tie(LANY:Lerp(TIE, 0.6), 0.6)
	local fz = k:frontZ()
	k:plate("UpperTorso", V(0.07, 0.75, 0.03), V(0.36, SH - 0.38, fz - 0.09), LANY, V(0, 0, 22))
	k:plate("UpperTorso", V(0.36, 0.44, 0.04), V(0.52, SH - 0.88, fz - 0.1), WHITE)
	k:plate("UpperTorso", V(0.14, 0.16, 0.03), V(0.45, SH - 0.84, fz - 0.13), SKIN)
	k:plate("UpperTorso", V(0.3, 0.07, 0.03), V(0.52, SH - 1.03, fz - 0.13), LANY)
	-- the wobbly paper stack in his right hand
	for i = 0, 5 do
		k:held(-1, V(0.72, 0.12, 0.58), V((i % 2) * 0.07 - 0.04, -0.1 + i * 0.13, -0.52), if i % 2 == 0 then WHITE else H("e6e6ea"), V(0, (i % 3 - 1) * 7, 0), true)
	end
	k:eyes({ w = 0.56, h = 0.62, look = Vector2.new(0, 0.15) })
	k:brows(HAIR, { tilt = -14, raise = 0.06 })
	k:nose()
	k:mouth("flat", { w = 0.3 })
	k:plate("HeadDetail", V(0.14, 0.24, 0.04), V(-0.82, HY + 0.4, FZ - 0.03), H("7cc8f0")) -- sweat drop
	k:hair("messy", HAIR)
end

-- Casual Friday (Common): dress-down day - an orange short-sleeve shirt with yellow flowers, jeans, flip-flops,
-- a red cap with sunglasses perched on it, a smoothie with a straw.
L.CasualFriday = function(k)
	local SHIRT, SHIRT_D, FLOWER, JEANS = H("ff8c3c"), H("e0702a"), H("ffdc50"), H("3c5aaa")
	local CAP, CAP_D, SKIN, HAIR = H("ff5050"), H("c83a3a"), H("e8b48a"), H("6b4226")
	k:body({ skin = SKIN, shirt = SHIRT, sleeves = "short", pants = JEANS, sandals = true, shoes = H("3cc8be") })
	k:collar(SHIRT_D)
	k:buttons(3, SHIRT_D, 0, SH - 0.3, 0.3)
	local fz = k:frontZ()
	for _, p in { Vector2.new(-0.6, SH - 0.42), Vector2.new(0.58, SH - 0.72), Vector2.new(-0.42, HIP + 0.32), Vector2.new(0.66, HIP + 0.2) } do
		k:plate("UpperTorso", V(0.24, 0.24, 0.04), V(p.X, p.Y, fz - 0.03), FLOWER)
		k:plate("UpperTorso", V(0.09, 0.09, 0.03), V(p.X, p.Y, fz - 0.06), SHIRT_D)
	end
	k:belt(H("7a4a24"))
	k:legBand(0.42, 0.12, H("5a7ac8")) -- rolled-up cuffs
	k:hair("short", HAIR, { hat = true, noTop = true })
	local capTop = k:cap(CAP, CAP_D, { down = 0.34 })
	local sy = capTop - 0.2
	for _, s in { -1, 1 } do
		k:plate("HeadDetail", V(0.44, 0.2, 0.05), V(s * 0.27, sy, -(D.headD + 0.16) / 2 - 0.03), INK)
	end
	k:plate("HeadDetail", V(0.16, 0.06, 0.05), V(0, sy + 0.04, -(D.headD + 0.16) / 2 - 0.03), INK)
	k:eyes({ lid = 0.28, look = Vector2.new(0.2, 0) })
	k:brows(HAIR, { tilt = -4 })
	k:nose()
	k:mouth("smile", { w = 0.48 })
	k:held(-1, V(0.38, 0.55, 0.38), V(0, 0.1, -0.5), H("ff8ab0"))
	k:held(-1, V(0.42, 0.08, 0.42), V(0, 0.41, -0.5), WHITE, nil, true)
	k:held(-1, V(0.07, 0.42, 0.07), V(0.08, 0.62, -0.5), H("5cdb4a"), V(0, 0, -12), true)
end

-- Bow Tie Benny (Uncommon): a short, round, dapper gentleman - a chubby purple tailcoat, a HUGE pink bow tie,
-- a tall top hat with a pink band, a curly moustache, a monocle, a cane with a gold knob.
L.BowTieBarrister = function(k)
	local SUIT, SUIT_D, PANTS, BOW, BOW_D = H("8246c8"), H("5e3296"), H("37235a"), H("ff50aa"), H("d8408e")
	local HAT, SKIN, STACHE = H("2d233c"), H("f2c8a0"), H("4a2c18")
	k:body({ skin = SKIN, shirt = SUIT, pants = PANTS, shoes = INK, torsoD = 1.25 })
	local fz = k:frontZ()
	k:lapels(SUIT, WHITE, { lapel = SUIT_D, depth = 0.7 })
	k:brick("UpperTorso", V(1.8, 0.85, 0.2), V(0, HIP + 0.5, fz - 0.08), SUIT) -- round tummy
	for _, y in { HIP + 0.72, HIP + 0.38 } do
		k:plate("UpperTorso", V(0.14, 0.14, 0.04), V(0, y, fz - 0.2), GOLD)
	end
	for _, s in { -1, 1 } do -- tailcoat tails
		k:brick("UpperTorso", V(0.9, 1.0, 0.12), V(s * 0.47, HIP - 0.35, 1.25 / 2 + 0.07), SUIT_D)
	end
	k:bowtie(BOW, { big = true, knot = BOW_D })
	k:hair("tufts", H("a8a8b0"))
	k:topHat(HAT, BOW, 1.25)
	k:eyes({ look = Vector2.new(0, 0.2) })
	k:brows(STACHE, { lift = { [1] = 0.1, [-1] = 0 } })
	k:nose()
	k:mustache(STACHE, "curly")
	k:mouth("smile", { w = 0.36, y = -0.62 })
	-- monocle on his left eye (+X) + its chain
	local mx, my, mz, mw = 0.46, HY + 0.05, FZ - 0.13, 0.72
	k:plate("HeadDetail", V(mw, 0.07, 0.05), V(mx, my + mw / 2, mz), GOLD)
	k:plate("HeadDetail", V(mw, 0.07, 0.05), V(mx, my - mw / 2, mz), GOLD)
	k:plate("HeadDetail", V(0.07, mw, 0.05), V(mx - mw / 2, my, mz), GOLD)
	k:plate("HeadDetail", V(0.07, mw, 0.05), V(mx + mw / 2, my, mz), GOLD)
	k:plate("UpperTorso", V(0.04, 0.5, 0.03), V(0.75, SH - 0.2, fz - 0.06), GOLD_D, V(0, 0, 10))
	-- cane in his left hand
	k:held(1, V(0.12, 1.45, 0.12), V(0, -0.7, -0.38), H("2a1e18"))
	k:held(1, V(0.26, 0.22, 0.26), V(0, 0.08, -0.38), GOLD)
end

-- Navy Power Suit (Uncommon): a broad-shouldered power lawyer - navy suit with shoulder pads, red power tie,
-- slicked-back hair, dark sunglasses, a smirk, a coffee cup held up, a phone at the hip.
L.NavyPowerSuit = function(k)
	local SUIT, SUIT_D, PANTS, TIE = H("284baa"), H("1f3c8a"), H("192355"), H("eb2d3c")
	local SKIN, HAIR = H("e8b48a"), H("2a1c14")
	k:body({ skin = SKIN, shirt = SUIT, pants = PANTS, shoes = INK })
	for _, s in { -1, 1 } do
		k:brick(Kit.armName(s), V(D.armW + 0.16, 0.22, D.armD + 0.12), V(s * (AX + 0.04), SH + 0.02, 0), SUIT)
	end
	k:lapels(SUIT, WHITE, { lapel = SUIT_D, depth = 1.0 })
	k:tie(TIE, 0.72)
	k:badge(WHITE, 0.62, SH - 0.45, Vector2.new(0.26, 0.14)) -- pocket square
	k:plate("UpperTorso", V(0.12, 0.44, 0.26), V(D.torsoW / 2 + 0.07, HIP + 0.12, -0.12), INK) -- phone at the hip
	k:hair("slick", HAIR)
	k:eyes({})
	k:glasses(INK, { sun = true })
	k:brows(HAIR, { tilt = 8, y = 0.1 })
	k:nose()
	k:mouth("flat", { w = 0.36 })
	k:plate("HeadDetail", V(0.1, 0.16, 0.04), V(-0.2, HY - 0.5, FZ - 0.03), Kit.C.Mouth) -- the smirk's corner
	-- coffee cup in his right hand, held up
	k:held(-1, V(0.36, 0.48, 0.36), V(0, 0.12, -0.5), WHITE)
	k:held(-1, V(0.4, 0.16, 0.4), V(0, 0.08, -0.5), H("c8a06a"), nil, true)
	k:held(-1, V(0.4, 0.1, 0.4), V(0, 0.41, -0.5), H("6b4426"), nil, true)
	k:poseArm(-1, V(30, 0, 0))
end

-- Mic Drop (Id BensonBond, Uncommon; renamed 2026-10-11): an original showman lawyer - cream-white suit,
-- gold tie + buttons, dark shirt, one arm flung out for the big finish, a gold microphone, a big grin.
L.BensonBond = function(k)
	local SUIT, SUIT_S, TIE, SKIN, HAIR, SHIRT = H("faf8f0"), H("e2ddcc"), H("ffcd78"), H("f0c4a8"), H("6b4426"), H("1c1c20")
	k:body({ skin = SKIN, shirt = SUIT, pants = SUIT, shoes = H("8a5a2e") })
	k:lapels(SUIT, SHIRT, { lapel = SUIT_S, depth = 1.0 })
	k:tie(TIE, 0.62)
	k:buttons(2, GOLD, 0, HIP + 0.38, 0.26)
	k:badge(GOLD, 0.62, SH - 0.45, Vector2.new(0.26, 0.14))
	k:hair("short", HAIR, { top = 0.14 })
	k:eyes({ look = Vector2.new(0, 0.35) })
	k:brows(HAIR, { raise = 0.06, tilt = -6 })
	k:nose()
	k:mouth("grin", { w = 0.62, h = 0.26 })
	k:held(-1, V(0.14, 0.5, 0.14), V(0, 0.3, -0.25), INK)
	k:held(-1, V(0.3, 0.3, 0.3), V(0, 0.66, -0.25), GOLD)
	k:poseArm(-1, V(42, 0, 0))
	k:poseArm(1, V(0, 0, 48))
end

-- Neon Nate (Rare): a lean cyberpunk lawyer - dark suit with glowing cyan trim, a wraparound Neon visor, spiky
-- black hair with a cyan streak, a smirk, a see-through glowing holo-briefcase, sneakers with glowing soles.
L.NeonLitigator = function(k)
	local SUIT, SUIT_D, SKIN, HAIR, CYAN, CYAN_D, MAG = H("23232f"), H("16161e"), H("e8b48a"), H("141418"), H("00ffc8"), H("00c8a0"), H("ff3cc8")
	k:body({ skin = SKIN, shirt = SUIT, pants = SUIT_D, shoes = INK })
	for _, s in { -1, 1 } do
		k:glow(Kit.legName(s), V(D.legW + 0.08, 0.07, D.legD + 0.24), V(s * LX, 0.035, -0.1), CYAN)
		k:glow(Kit.armName(s), V(D.armW + 0.06, 0.08, D.armD + 0.06), V(s * AX, SH - D.armH + D.handH + 0.05, 0), CYAN)
		k:plate(Kit.legName(s), V(0.05, 0.9, 0.08), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), CYAN_D)
	end
	k:lapels(SUIT, H("2c2c3a"), { lapel = SUIT_D, depth = 1.0 })
	local fz = k:frontZ()
	for _, s in { -1, 1 } do -- cyan lapel edges
		k:plate("UpperTorso", V(0.05, 1.08, 0.03), V(s * 0.25, SH - 0.52, fz - 0.09), CYAN_D, V(0, 0, s * 22))
	end
	k:tie(MAG, 0.68)
	k:plate("UpperTorso", V(D.torsoW + 0.06, 0.06, D.torsoD + 0.06), V(0, HIP + 0.04, 0), CYAN_D) -- hem line
	local top = k:hair("spiky", HAIR)
	k:brick("HeadDetail", V(0.3, 0.5, 0.3), V(0.34, top + 0.2, -0.3), CYAN_D, V(-12, 0, -8)) -- the streak
	-- wraparound visor instead of eyes
	k:glow("HeadDetail", V(D.headW + 0.14, 0.34, 0.06), V(0, HY + 0.06, FZ - 0.1), CYAN)
	for _, s in { -1, 1 } do
		k:plate("HeadDetail", V(0.06, 0.34, 0.9), V(s * (D.headW / 2 + 0.06), HY + 0.06, -0.45), INK)
	end
	k:nose()
	k:mouth("flat", { w = 0.34 })
	k:plate("HeadDetail", V(0.1, 0.16, 0.04), V(0.17, HY - 0.5, FZ - 0.03), Kit.C.Mouth)
	-- holo-briefcase in his left hand
	k:held(1, V(0.1, 0.1, 0.44), V(0.04, -0.27, 0), INK, nil, true)
	local case = k:held(1, V(0.34, 0.66, 0.95), V(0.04, -0.66, 0), CYAN, nil, true)
	case.Material = Enum.Material.Neon
	case.Transparency = 0.45
end

-- Selfie Star (Id KaiSueNat, Rare; renamed 2026-10-11): an original vlogger lawyer - black hoodie with a red stripe
-- and a red tie peeking out, joggers, a backwards red cap, headphones round the neck, a phone on a selfie stick.
L.KaiSueNat = function(k)
	local HOOD, HOOD_D, RED, RED_D = H("19191e"), H("121216"), H("d21e28"), H("a8141e")
	local SKIN, SNEAK, PHONE, HAIR = H("744c34"), H("f5f5f5"), H("2a2a32"), H("141418")
	k:body({ skin = SKIN, shirt = HOOD, pants = HOOD, shoes = SNEAK, sole = H("d0d0d4") })
	for _, s in { -1, 1 } do
		k:plate(Kit.legName(s), V(0.05, 0.95, 0.12), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), RED)
	end
	local fz = k:frontZ()
	k:torsoBand(SH - 0.6, 0.16, RED)
	k:plate("UpperTorso", V(1.1, 0.42, 0.05), V(0, HIP + 0.3, fz - 0.03), HOOD_D) -- pocket
	k:brick("UpperTorso", V(1.5, 0.55, 0.35), V(0, SH + 0.1, (k.td or D.torsoD) / 2 + 0.12), HOOD) -- the hood, down
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.06, 0.4, 0.03), V(s * 0.24, SH - 0.28, fz - 0.04), WHITE)
	end
	k:plate("UpperTorso", V(0.22, 0.18, 0.06), V(0, SH - 0.1, fz - 0.06), RED)
	k:plate("UpperTorso", V(0.16, 0.3, 0.05), V(0, SH - 0.33, fz - 0.06), RED)
	-- headphones round the neck (Rare-blue cups)
	k:brick("UpperTorso", V(1.5, 0.16, 1.25), V(0, SH + 0.06, 0), H("26262c"))
	for _, s in { -1, 1 } do
		k:brick("UpperTorso", V(0.36, 0.42, 0.24), V(s * 0.62, SH + 0.02, fz - 0.14), RARE)
	end
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:cap(RED, RED_D, { backwards = true, down = 0.34 })
	k:eyes({ w = 0.56, h = 0.62, look = Vector2.new(0, 0.4) })
	k:brows(HAIR, { raise = 0.08, tilt = -6 })
	k:nose()
	k:mouth("grin", { w = 0.62 })
	-- selfie stick + phone in his right hand, angled out in front of him (the whole prop stays below the shoulder:
	-- Puppet puts the shoulder at the top of the arm's highest part), a Neon "live" dot on the phone's back
	-- (the stick lies along its Z axis: Puppet reads a part's height from Size.Y without the rotation, so a tilted
	-- 1.6-tall stick would count as reaching above the shoulder)
	local hand, tip = k:hand(-1), k:hand(-1) + V(0.55, 0.92, -1.27)
	k:plate("RightUpperArm", V(0.08, 0.08, (tip - hand).Magnitude), CFrame.lookAt((hand + tip) / 2, tip), H("9aa0aa"))
	k:held(-1, V(0.5, 0.6, 0.07), V(0.55, 0.92, -1.27), PHONE, V(-8, -10, 0), true)
	k:plate("RightUpperArm", V(0.42, 0.5, 0.03), k:hand(-1) + V(0.55, 0.92, -1.23), H("4fb6ff"), V(-8, -10, 0)) -- the screen, facing him
	k:glow("RightUpperArm", V(0.12, 0.12, 0.03), k:hand(-1) + V(0.68, 1.1, -1.31), H("ff2e3e"), V(-8, -10, 0))
end

-- Obvious Ollie (Id KhabyClaim, Rare; renamed 2026-10-11): an original deadpan "it's that simple" lawyer - grey
-- suit, dark tie, arms out in an open-palms shrug, a flat unimpressed face with raised brows, a glowing idea bulb.
L.KhabyClaim = function(k)
	local SUIT, SUIT_D, TIE, SKIN, HAIR = H("787c84"), H("3c3e46"), H("1e1e22"), H("6c4630"), H("1c1c20")
	k:body({ skin = SKIN, shirt = SUIT, pants = SUIT_D, shoes = INK })
	k:lapels(SUIT, WHITE, { lapel = SUIT_D, depth = 0.95 })
	k:tie(TIE, 0.7)
	k:badge(RARE, 0.62, SH - 0.45, Vector2.new(0.26, 0.14)) -- Rare-blue pocket square
	k:hair("short", HAIR, { top = 0.12 })
	k:eyes({ lid = 0.42 })
	k:brows(HAIR, { raise = 0.14 })
	k:nose()
	k:mouth("flat", { w = 0.42 })
	-- the idea, floating over his head
	k:plate("HeadDetail", V(0.26, 0.18, 0.26), V(0.9, HT + 0.5, -0.3), H("9aa0aa"))
	k:glow("HeadDetail", V(0.44, 0.46, 0.44), V(0.9, HT + 0.82, -0.3), H("ffe86a"))
	for _, s in { -1, 1 } do
		k:poseArm(s, V(18, 0, s * 32))
	end
end

-- Livestreamer (Id IShowSued, Legendary; renamed 2026-10-11): an original hype-streamer lawyer - wide eyes,
-- a shouting open mouth, a gaming headset with a gold boom mic, a red tracksuit with green sleeve stripes, a gold
-- chain, arms out celebrating with a gold-trimmed football, white sneakers with gold soles, a floating Neon REC light.
L.IShowSued = function(k)
	local SKIN, HAIR, JACKET, JACKET_D, STRIPE = H("784e36"), H("1c1c20"), H("c81228"), H("9e0e22"), H("148c46")
	local PANTS, HEADSET, REC = H("1e1e22"), H("26262c"), H("ff2e3e")
	k:body({ skin = SKIN, shirt = JACKET, pants = PANTS, shoes = H("f5f5f5"), sole = GOLD })
	local fz = k:frontZ()
	k:torsoBand(HIP + 0.08, 0.16, JACKET_D)
	k:plate("UpperTorso", V(0.08, 1.35, 0.04), V(0, HIP + 0.72, fz - 0.03), WHITE) -- zip
	k:brick("UpperTorso", V(1.3, 0.2, 1.15), V(0, SH + 0.04, 0), JACKET_D) -- collar
	for _, s in { -1, 1 } do
		-- (starts below the sleeve top: an arm part as tall as the sleeve would become Puppet's shoulder once posed)
		k:plate(Kit.armName(s), V(0.06, 0.78, 0.18), V(s * (AX + D.armW / 2 + 0.02), SH - 0.2 - 0.39, 0), STRIPE)
		k:plate(Kit.legName(s), V(0.05, 0.95, 0.14), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), STRIPE)
	end
	-- gold chain + medallion
	for _, p in { V(0.42, -0.08, 0), V(0.3, -0.3, 0), V(0.16, -0.5, 0) } do
		for _, s in { -1, 1 } do
			k:plate("UpperTorso", V(0.13, 0.13, 0.04), V(s * p.X, SH + p.Y, fz - 0.05), GOLD)
		end
	end
	k:plate("UpperTorso", V(0.32, 0.32, 0.05), V(0, SH - 0.74, fz - 0.06), GOLD)
	k:plate("UpperTorso", V(0.16, 0.16, 0.03), V(0, SH - 0.74, fz - 0.1), GOLD_D)
	k:hair("short", HAIR, { top = 0.1 })
	-- gaming headset: band over the top, cups over the ears, a boom mic with a gold tip
	local hw = D.headW / 2
	k:brick("HeadDetail", V(D.headW + 0.4, 0.16, 0.42), V(0, HT + 0.2, 0.05), HEADSET)
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.14, 0.75, 0.36), V(s * (hw + 0.2), HT - 0.25, 0.05), HEADSET)
		k:brick("HeadDetail", V(0.3, 0.64, 0.64), V(s * (hw + 0.17), HY - 0.05, 0.05), HEADSET)
		k:plate("HeadDetail", V(0.04, 0.4, 0.4), V(s * (hw + 0.33), HY - 0.05, 0.05), GOLD)
	end
	k:plate("HeadDetail", V(0.06, 0.06, 0.8), V(-(hw + 0.08), HY - 0.45, -0.55), HEADSET, V(0, -32, 0))
	k:brick("HeadDetail", V(0.18, 0.18, 0.18), V(-0.62, HY - 0.48, FZ - 0.12), GOLD)
	k:eyes({ w = 0.6, h = 0.66, look = Vector2.new(0, 0.3) })
	k:brows(HAIR, { raise = 0.12, tilt = -8 })
	k:nose()
	k:mouth("open", { w = 0.72, h = 0.42, y = -0.6 })
	-- the REC light, floating
	k:plate("HeadDetail", V(0.42, 0.42, 0.06), V(1.3, HT + 0.5, -0.16), INK)
	k:glow("HeadDetail", V(0.3, 0.3, 0.06), V(1.3, HT + 0.5, -0.2), REC)
	-- the football in his right hand (gold bands at the tips)
	k:held(-1, V(0.6, 0.42, 0.42), V(0, 0.05, -0.48), H("8a4a22"))
	k:held(-1, V(0.3, 0.05, 0.04), V(0, 0.27, -0.6), WHITE, nil, true)
	for _, dx in { -0.28, 0.28 } do
		k:held(-1, V(0.06, 0.44, 0.44), V(dx, 0.05, -0.48), GOLD, nil, true)
	end
	k:poseArm(-1, V(30, 0, -28))
	k:poseArm(1, V(30, 0, 28))
end

return L
