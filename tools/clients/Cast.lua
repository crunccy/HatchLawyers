-- The client cast, v3 remodel (2026-10-10): one builder per client on ServerStorage.ClientKit (tools/clients/
-- ClientKit.lua). NeighborDave (tools/clients/NeighborDave.lua) is the quality benchmark; every one here follows it:
-- rounded CSG blocks, layered clothing, its own hair + hat + prop silhouette, a drawn face (tools/client_faces.py).
-- Run in Studio: _G.runCast("<Id>") builds + previews one; _G.installCast("<Id>") installs it (see InstallClients.lua).
local Kit = require(game.ServerStorage.ClientKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local HIP, SH, HY = Kit.hipY, Kit.shoulderY, Kit.headY
local HT = HY + D.headH / 2 -- top of the head
local AX = Kit.armX
local LX = Kit.legX
local S1, S2, S3, S4, S5, S6 = H("f6d2b0"), H("f1c49a"), H("e0a87a"), H("c98b5f"), H("a86a42"), H("7a4a2c")
local GOLD, GOLD_D, WHITE, BLACK = H("f2c234"), H("c8961c"), H("f8f8f6"), H("1e1e24")

local function leg(s)
	return if s < 0 then "RightUpperLeg" else "LeftUpperLeg"
end
local arm = Kit.armName
-- a ring of something round a limb / the torso at height y
local function band(k, name, w, d, y, h, color, x)
	k:rbox(name, V(w, h, d), V(x or 0, y, 0), color, math.min(0.06, h / 2.2))
end
local function legBand(k, y, h, color, extra)
	for _, s in { -1, 1 } do
		band(k, leg(s), D.legW + (extra or 0.04), D.legD + (extra or 0.04), y, h, color, s * LX)
	end
end
local function armBand(k, y, h, color, extra)
	for _, s in { -1, 1 } do
		band(k, arm(s), D.armW + (extra or 0.04), D.armD + (extra or 0.04), y, h, color, s * AX)
	end
end
-- two rows of buttons (double-breasted)
local function double(k, color, y0, n, dx)
	for _, x in { -(dx or 0.26), dx or 0.26 } do
		k:buttons(n, color, x, y0, 0.3)
	end
end
-- tall boot shafts over the lower leg
local function boots(k, color, h, cuff)
	for _, s in { -1, 1 } do
		k:rbox(leg(s), V(D.legW + 0.08, h, D.legD + 0.08), V(s * LX, 0.25 + h / 2, -0.02), color, 0.12)
		if cuff then
			k:rbox(leg(s), V(D.legW + 0.12, 0.14, D.legD + 0.12), V(s * LX, 0.25 + h - 0.04, -0.02), cuff, 0.05)
		end
	end
end
-- spots of colour scattered on the torso front
local function spots(k, list, z)
	for _, p in list do
		k:ell("UpperTorso", V(p[3], p[3] * 0.8, 0.06), V(p[1], p[2], z), p[4])
	end
end

local Cast = {}

------------------------------------------------------------------ COMMON
Cast.GrandmaPearl = function(k)
	local LAV, LAV_D, BLOUSE, SKIRT, HAIR = H("b49ae0"), H("8f74c2"), H("fbf6ee"), H("e07aa8"), H("e4e4ec")
	k:body({ skin = S1, shirt = LAV, pants = SKIRT, legs = "skirt", skirtLen = 1.3, socks = H("e8c4a8"), sockH = 1.2,
		shoes = LAV_D, sole = H("5e4a80"), cuff = LAV_D })
	k:lapels(LAV, BLOUSE, { depth = 0.75, width = 0.6 })
	k:buttons(3, H("fbe7ff"), 0, SH - 0.95, 0.26)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.42, 0.32, 0.06), V(s * 0.5, HIP + 0.45, k:frontZ(0.02)), LAV_D, 0.04)
	end
	for i = -4, 4 do -- pearl necklace
		local t = i / 4
		k:ball("UpperTorso", 0.11, V(t * 0.33, SH - 0.1 - (1 - t * t) * 0.32, k:frontZ(0.07)), WHITE)
	end
	k:hairStyle("bun", HAIR)
	for _, s in { -1, 1 } do
		for _, y in { 0.28, -0.04 } do
			k:ell("HeadDetail", V(0.34, 0.34, 0.4), V(s * 0.74, HY + y, 0.08), HAIR)
		end
	end
	k:glasses("round", H("d4a640"))
	local hx = -AX -- cane
	k:rbox("RightUpperArm", V(0.13, 2.05, 0.13), V(hx, 1.07, -0.45), H("7a4a24"), 0.05)
	k:rbox("RightUpperArm", V(0.42, 0.13, 0.13), V(hx - 0.15, 2.12, -0.45), H("7a4a24"), 0.06)
	k:ball("RightUpperArm", 0.18, V(hx - 0.36, 2.06, -0.45), H("7a4a24"))
end

Cast.SkaterKev = function(k)
	local HOOD, HOOD_D, SHORTS = H("ff8a2a"), H("d96a14"), H("4a5a7a")
	k:body({ skin = S3, shirt = HOOD, pants = SHORTS, sleeves = "long", cuff = HOOD_D, legs = "shorts", socks = WHITE,
		sockH = 0.7, shoes = H("2b2b33"), sole = H("ff4f4f") })
	k:rbox("UpperTorso", V(1.3, 0.55, 0.5), V(0, SH - 0.05, 0.56), HOOD_D, 0.2) -- hood down the back
	k:rbox("UpperTorso", V(1.0, 0.16, 0.92), V(0, SH, 0.02), HOOD_D, 0.07)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.05, 0.5, 0.05), V(s * 0.16, SH - 0.36, k:frontZ(0.04)), WHITE, 0.02)
		k:ball("UpperTorso", 0.08, V(s * 0.16, SH - 0.62, k:frontZ(0.05)), WHITE)
	end
	k:rbox("UpperTorso", V(1.1, 0.48, 0.08), V(0, HIP + 0.42, k:frontZ(0.03)), HOOD_D, 0.06) -- pocket
	k:ell("UpperTorso", V(0.5, 0.36, 0.05), V(0, SH - 0.82, k:frontZ(0.01)), H("2b2b33")) -- logo
	k:ell("UpperTorso", V(0.24, 0.18, 0.05), V(0, SH - 0.82, k:frontZ(0.03)), H("ffe14a"))
	k:hairStyle("short", H("4a2a14"), { hat = true })
	k:capHat(H("3a6ad0"), H("2a4fa0"), true)
	local x = AX + 0.44 -- skateboard under the arm
	k:rbox("LeftUpperArm", V(0.1, 2.1, 0.62), V(x, 2.35, 0), H("2b2b33"), 0.06)
	k:rbox("LeftUpperArm", V(0.02, 1.8, 0.5), V(x + 0.06, 2.35, 0), H("ff4f9a"), 0.04)
	k:ell("LeftUpperArm", V(0.03, 0.4, 0.4), V(x + 0.08, 2.35, 0), H("ffe14a"))
	for _, y in { 1.55, 3.15 } do
		for _, z in { -0.2, 0.2 } do
			k:cyl("LeftUpperArm", V(0.16, 0.2, 0.2), V(x - 0.15, y, z), H("f2f2f2"))
		end
	end
end

Cast.MailCarrierMo = function(k)
	local SHIRT, SHIRT_D, NAVY, BAG, BAG_D = H("8fb8e8"), H("6a94c8"), H("26345e"), H("8a5a2e"), H("6b4426")
	k:body({ skin = S5, shirt = SHIRT, pants = NAVY, sleeves = "short", cuff = SHIRT_D, legs = "shorts", socks = NAVY,
		sockH = 0.55, shoes = H("1c1c22") })
	k:collar(SHIRT_D)
	k:buttons(3, WHITE)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.42, 0.36, 0.06), V(s * 0.5, SH - 0.62, k:frontZ(0.02)), SHIRT_D, 0.04)
	end
	k:rbox("LeftUpperArm", V(0.06, 0.3, 0.32), V(AX + D.armW / 2 + 0.02, SH - 0.3, 0), H("e04040"), 0.03)
	k:rbox("UpperTorso", V(0.16, 2.35, 0.06), V(0, HIP + 0.95, k:frontZ(0.07)), BAG_D, 0.03, V(0, 0, -38))
	k:rbox("UpperTorso", V(0.16, 2.0, 0.06), V(0, HIP + 0.95, 0.53), BAG_D, 0.03, V(0, 0, 38))
	k:rbox("UpperTorso", V(0.92, 0.72, 0.42), V(-0.78, HIP + 0.02, -0.35), BAG, 0.1)
	k:rbox("UpperTorso", V(0.94, 0.38, 0.44), V(-0.78, HIP + 0.22, -0.36), BAG_D, 0.08)
	k:rbox("UpperTorso", V(0.16, 0.14, 0.05), V(-0.78, HIP + 0.06, -0.6), GOLD, 0.03)
	k:hairStyle("short", H("1e1410"), { hat = true })
	k:capHat(NAVY, H("1c2848"))
	k:rbox("HeadDetail", V(0.4, 0.22, 0.05), V(0, HT - 0.06, -0.73), H("e8c050"), 0.03, V(-20, 0, 0))
	local h = k:hand(1)
	k:rbox("LeftUpperArm", V(0.62, 0.44, 0.05), V(h.X, h.Y + 0.22, -0.46), H("fffaf0"), 0.02, V(0, 0, -10))
	k:rbox("LeftUpperArm", V(0.14, 0.16, 0.02), V(h.X + 0.17, h.Y + 0.34, -0.5), H("e04040"), 0.01, V(0, 0, -10))
	k:rbox("RightUpperLeg", V(D.legW - 0.04, 0.24, D.legD - 0.04), V(-LX, 1.0, 0), H("f6efe2"), 0.06) -- bandage
end

Cast.LemonadeLily = function(k)
	local DRESS, LEAF = H("ffd83a"), H("6cc53a")
	k:body({ skin = S1, shirt = DRESS, pants = DRESS, sleeves = "none", legs = "skirt", skirtLen = 1.0, flare = 0.34,
		shoes = WHITE, sole = H("ffb0c8"), socks = WHITE, sockH = 0.35 })
	for _, s in { -1, 1 } do
		k:ell("UpperTorso", V(0.52, 0.12, 0.4), V(s * 0.23, SH - 0.04, k:frontZ(-0.1)), WHITE) -- round collar
	end
	spots(k, { { -0.5, 2.95, 0.22, LEAF }, { 0.48, 3.25, 0.2, LEAF }, { 0.12, 2.45, 0.2, LEAF } }, k:frontZ(0.02))
	for _, p in { { -0.62, 1.55 }, { 0.15, 1.3 }, { 0.7, 1.6 }, { -0.25, 0.95 }, { 0.55, 0.95 } } do
		k:ell("UpperTorso", V(0.24, 0.17, 0.06), V(p[1], p[2], -(D.torsoD + 0.14 + 0.34) / 2 - 0.02), H("fff3b0"))
	end
	k:rbox("UpperTorso", V(D.torsoW + 0.14, 0.14, D.torsoD + 0.16), V(0, HIP + 0.22, 0), H("ff8ab8"), 0.05) -- sash
	k:hairStyle("pigtails", H("e8742a"), { tie = H("ff5a8a") })
	local h = k:hand(-1) -- pitcher of lemonade
	local glass = k:cyl("RightUpperArm", V(0.72, 0.52, 0.52), V(h.X, h.Y + 0.2, -0.48), H("fffbe0"), V(0, 0, 90))
	glass.Transparency = 0.3
	k:cyl("RightUpperArm", V(0.5, 0.44, 0.44), V(h.X, h.Y + 0.1, -0.48), H("ffe14a"), V(0, 0, 90))
	k:rbox("RightUpperArm", V(0.1, 0.42, 0.1), V(h.X - 0.33, h.Y + 0.22, -0.48), H("fffbe0"), 0.04)
	k:ell("RightUpperArm", V(0.24, 0.24, 0.08), V(h.X + 0.18, h.Y + 0.52, -0.58), H("ffd21f"))
end

Cast.GamerGabe = function(k)
	local HOOD, NEON, JOG, PAD = H("23232e"), H("5cf05a"), H("6a6a78"), H("3a3a46")
	k:body({ skin = S4, shirt = HOOD, pants = JOG, sleeves = "long", cuff = NEON, shoes = H("f2f2f2"), sole = NEON })
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.1, 1.72, 0.06), V(s * 0.64, HIP + 0.92, k:frontZ(0.01)), NEON, 0.03)
		k:rbox(leg(s), V(0.06, 1.5, 0.12), V(s * (LX + D.legW / 2 + 0.01), 1.05, 0), NEON, 0.02)
	end
	k:rbox("UpperTorso", V(1.3, 0.55, 0.5), V(0, SH - 0.05, 0.56), PAD, 0.2)
	k:rbox("UpperTorso", V(1.05, 0.46, 0.08), V(0, HIP + 0.42, k:frontZ(0.03)), PAD, 0.06)
	k:rbox("UpperTorso", V(0.44, 0.44, 0.05), V(0, SH - 0.72, k:frontZ(0.01)), NEON, 0.08, V(0, 0, 45)) -- logo
	k:rbox("UpperTorso", V(0.24, 0.24, 0.05), V(0, SH - 0.72, k:frontZ(0.03)), HOOD, 0.04, V(0, 0, 45))
	k:hairStyle("messy", H("1a1a1a"))
	-- headset
	k:rbox("HeadDetail", V(1.72, 0.14, 0.32), V(0, HT + 0.08, 0.05), PAD, 0.06)
	for _, s in { -1, 1 } do
		k:rbox("HeadDetail", V(0.14, 0.62, 0.3), V(s * 0.82, HY + 0.4, 0.05), PAD, 0.05)
		k:cyl("HeadDetail", V(0.24, 0.62, 0.62), V(s * 0.82, HY + 0.02, 0.05), BLACK)
		k:cyl("HeadDetail", V(0.05, 0.4, 0.4), V(s * 0.95, HY + 0.02, 0.05), NEON)
	end
	k:rbox("HeadDetail", V(0.07, 0.07, 0.55), V(-0.82, HY - 0.22, -0.32), PAD, 0.03, V(0, -20, 0))
	k:ball("HeadDetail", 0.14, V(-0.66, HY - 0.25, -0.6), NEON)
	local h = k:hand(-1) -- controller
	k:fuse("RightUpperArm", H("4a4a58"), {
		{ "rbox", V(0.7, 0.24, 0.4), V(h.X, h.Y + 0.16, -0.5), nil, 0.1 },
		{ "ball", V(0.34, 0.34, 0.34), V(h.X - 0.3, h.Y + 0.12, -0.5) },
		{ "ball", V(0.34, 0.34, 0.34), V(h.X + 0.3, h.Y + 0.12, -0.5) },
	})
	for i, c in { H("ff4f4f"), H("4fb6ff"), NEON } do
		k:ball("RightUpperArm", 0.08, V(h.X + 0.08 + i * 0.07, h.Y + 0.29, -0.52), c)
	end
end

Cast.GardenerGus = function(k)
	local SHIRT, OVER, OVER_D, HAT = H("d9483a"), H("4f9a4a"), H("3a7a36"), H("4a8a5a")
	k:body({ skin = S3, shirt = SHIRT, pants = OVER, sleeves = "long", cuff = H("b8382c"), shoes = H("3a7a36"),
		sole = H("2a5a26"), hands = H("f0c850") })
	k:rbox("UpperTorso", V(1.12, 0.95, 0.06), V(0, HIP + 0.5, k:frontZ(0.01)), OVER, 0.05)
	k:rbox("UpperTorso", V(0.5, 0.34, 0.06), V(0, HIP + 0.55, k:frontZ(0.04)), OVER_D, 0.04)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.18, 0.95, 0.06), V(s * 0.42, SH - 0.45, k:frontZ(0.01)), OVER, 0.03)
		k:ball("UpperTorso", 0.13, V(s * 0.42, HIP + 0.95, k:frontZ(0.05)), GOLD)
	end
	for _, y in { 2.4, 2.85, 3.3 } do -- plaid lines on the sleeves
		armBand(k, y, 0.06, H("8a2a22"), 0.02)
	end
	boots(k, H("3a7a36"), 0.55, H("2a5a26"))
	k:hairStyle("tufts", H("eeeeee"))
	k:brimHat(HAT, H("2f6a3a"), 1.95, 0.5)
	local h = k:hand(-1) -- watering can
	k:cyl("RightUpperArm", V(0.62, 0.62, 0.62), V(h.X - 0.05, h.Y - 0.28, -0.55), H("5ab0e0"), V(0, 0, 90))
	k:rbox("RightUpperArm", V(0.1, 0.1, 0.75), V(h.X - 0.05, h.Y - 0.12, -1.05), H("5ab0e0"), 0.04, V(-40, 0, 0))
	k:cyl("RightUpperArm", V(0.08, 0.22, 0.22), V(h.X - 0.05, h.Y + 0.16, -1.36), H("3a8ac0"), V(0, 90, 0))
	k:rbox("RightUpperArm", V(0.08, 0.42, 0.42), V(h.X - 0.05, h.Y + 0.12, -0.55), H("3a8ac0"), 0.04)
end

Cast.IceCreamIvy = function(k)
	local PINK, MINT = H("ff8ab8"), H("8fe8c8")
	k:body({ skin = S6, shirt = WHITE, pants = H("4a5a8a"), sleeves = "short", cuff = PINK, shoes = PINK, sole = WHITE })
	for i = 0, 3 do
		band(k, "UpperTorso", D.torsoW + 0.02, D.torsoD + 0.02, HIP + 0.45 + i * 0.4, 0.14, PINK)
	end
	k:apron(WHITE, { bib = false, length = 0.85, pocket = PINK })
	k:hairStyle("bob", H("2a1810"))
	k:rbox("HeadDetail", V(0.72, 0.36, 1.32), V(0, HT + 0.1, 0.0), WHITE, 0.1) -- paper cap
	k:rbox("HeadDetail", V(0.74, 0.08, 1.34), V(0, HT - 0.02, 0), PINK, 0.03)
	local h = k:hand(-1) -- ice cream cone
	k:fuse("RightUpperArm", H("e0a458"), {
		{ "wedge", V(0.32, 0.6, 0.32), V(h.X, h.Y + 0.15, -0.5), V(180, 0, 0) },
	})
	k:ball("RightUpperArm", 0.42, V(h.X, h.Y + 0.6, -0.5), PINK)
	k:ball("RightUpperArm", 0.38, V(h.X, h.Y + 0.92, -0.5), MINT)
	k:ball("RightUpperArm", 0.13, V(h.X, h.Y + 1.15, -0.5), H("e8182e"))
end

Cast.BarberBob = function(k)
	local RED = H("e03a3a")
	k:body({ skin = S2, shirt = WHITE, pants = BLACK, sleeves = "long", cuff = WHITE, shoes = BLACK, sole = H("3a3a44") })
	k:rbox("UpperTorso", V(D.torsoW + 0.04, 1.45, D.torsoD + 0.04), V(0, HIP + 0.72, 0), RED, 0.18) -- vest
	for i = -3, 3 do
		if i ~= 0 then
			k:rbox("UpperTorso", V(0.09, 1.4, 0.04), V(i * 0.23, HIP + 0.72, k:frontZ(0.03)), WHITE, 0.02)
		end
	end
	k:lapels(RED, WHITE, { depth = 0.62, width = 0.62, lapel = RED })
	k:bowtie(BLACK)
	k:buttons(3, GOLD, 0, HIP + 1.0, 0.3)
	k:rbox("UpperTorso", V(0.36, 0.3, 0.06), V(-0.52, SH - 0.62, k:frontZ(0.05)), WHITE, 0.03) -- pocket + comb
	k:rbox("UpperTorso", V(0.08, 0.36, 0.04), V(-0.58, SH - 0.48, k:frontZ(0.08)), BLACK, 0.02)
	k:hairStyle("swoop", H("1c1c1c"))
	local h = k:hand(-1) -- scissors
	for _, a in { -18, 18 } do
		k:rbox("RightUpperArm", V(0.06, 0.62, 0.04), V(h.X, h.Y + 0.42, -0.48), H("c8ccd6"), 0.02, V(0, 0, a))
	end
	for _, s in { -1, 1 } do
		k:ring("RightUpperArm", 0.24, 0.13, 0.05, V(h.X + s * 0.13, h.Y + 0.02, -0.48), BLACK)
	end
end

Cast.CrossingGuardCarol = function(k)
	local VEST, REFL, NAVY = H("ff7a1a"), H("e8ff4a"), H("26345e")
	k:body({ skin = S5, shirt = WHITE, pants = NAVY, sleeves = "long", cuff = WHITE, shoes = BLACK, hands = WHITE })
	k:rbox("UpperTorso", V(D.torsoW + 0.06, 1.6, D.torsoD + 0.06), V(0, HIP + 0.85, 0), VEST, 0.18)
	k:rbox("UpperTorso", V(0.5, 0.5, 0.04), V(0, SH - 0.25, k:frontZ(0.03)), WHITE, 0.03) -- shirt at the neck
	for _, y in { HIP + 0.32, HIP + 0.78 } do
		band(k, "UpperTorso", D.torsoW + 0.08, D.torsoD + 0.08, y, 0.12, REFL)
	end
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.12, 1.0, 0.04), V(s * 0.45, SH - 0.55, k:frontZ(0.05)), REFL, 0.03)
	end
	k:hairStyle("ponytail", H("2a1810"), { tie = VEST, hat = true })
	k:capHat(NAVY, H("1c2848"))
	local h = k:hand(-1) -- STOP paddle
	k:rbox("RightUpperArm", V(0.1, 1.45, 0.1), V(h.X, h.Y + 0.55, -0.45), H("c8ccd6"), 0.04)
	local sign = k:fuse("RightUpperArm", H("e02a2a"), {
		{ "block", V(0.95, 0.4, 0.08), V(h.X, h.Y + 1.6, -0.45) },
		{ "block", V(0.4, 0.95, 0.08), V(h.X, h.Y + 1.6, -0.45) },
		{ "block", V(0.66, 0.66, 0.08), V(h.X, h.Y + 1.6, -0.45), V(0, 0, 45) },
	})
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(200, 200)
	sg.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "STOP"
	t.TextScaled = true
	t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = sg
	sg.Parent = sign
end

Cast.LibrarianLou = function(k)
	local CARD, SHIRT, TIE = H("c8963c"), H("f4eedc"), H("6a2a3a")
	k:body({ skin = S4, shirt = CARD, pants = H("6b4a2e"), sleeves = "long", cuff = H("a8782a"), shoes = H("5a3418") })
	k:lapels(CARD, SHIRT, { depth = 0.9, width = 0.6 })
	k:tie(TIE, 0.62)
	k:buttons(2, H("6b4a2e"), 0, SH - 1.1, 0.32)
	k:rbox("UpperTorso", V(0.4, 0.34, 0.06), V(0.5, HIP + 0.45, k:frontZ(0.02)), H("a8782a"), 0.04)
	for _, s in { -1, 1 } do -- elbow patches
		k:ell(arm(s), V(0.08, 0.4, 0.34), V(s * (AX + D.armW / 2), 2.75, 0.05), H("8a6a3a"))
	end
	k:hairStyle("tufts", H("dcdcdc"))
	k:glasses("round", H("2a2a2a"))
	local h = k:hand(1) -- a stack of books
	for i, c in { H("3a6ad0"), H("d94a3a"), H("4f9a4a") } do
		k:rbox("LeftUpperArm", V(0.72, 0.18, 0.5), V(h.X + 0.05, h.Y + 0.05 + i * 0.19, -0.48), c, 0.04, V(0, (i - 2) * 8, 0))
		k:rbox("LeftUpperArm", V(0.66, 0.14, 0.46), V(h.X + 0.08, h.Y + 0.05 + i * 0.19, -0.5), H("fbf4e0"), 0.02, V(0, (i - 2) * 8, 0))
	end
end

Cast.CamperCam = function(k)
	local FLANNEL, FLAN_D, KHAKI, PACK = H("d9483a"), H("8a2a22"), H("c9a66b"), H("4a8a4a")
	k:body({ skin = S2, shirt = FLANNEL, pants = KHAKI, sleeves = "short", cuff = FLAN_D, legs = "shorts",
		socks = H("8a8a94"), sockH = 0.55, shoes = H("6b4426"), sole = H("3a2a1e") })
	for _, x in { -0.4, 0.4 } do
		k:rbox("UpperTorso", V(0.06, 1.8, 0.04), V(x, HIP + 0.92, k:frontZ(0.01)), FLAN_D, 0.02)
	end
	for _, y in { HIP + 0.55, HIP + 1.25 } do
		band(k, "UpperTorso", D.torsoW + 0.01, D.torsoD + 0.01, y, 0.06, FLAN_D)
	end
	k:collar(FLAN_D)
	k:rbox("UpperTorso", V(1.4, 1.55, 0.62), V(0, HIP + 0.95, 0.8), PACK, 0.18) -- backpack
	k:rbox("UpperTorso", V(0.9, 0.5, 0.2), V(0, HIP + 0.55, 1.14), H("3a7a3a"), 0.08)
	k:cyl("UpperTorso", V(1.5, 0.5, 0.5), V(0, SH + 0.05, 0.85), H("ff8a2a")) -- bedroll
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.16, 1.4, 0.06), V(s * 0.55, SH - 0.65, k:frontZ(0.03)), H("2a5a2a"), 0.03)
	end
	k:hairStyle("short", H("7a4422"), { hat = true })
	k:beanie(H("2f7a4a"), H("245e3a"), WHITE)
	local h = k:hand(-1) -- marshmallow on a stick
	k:rbox("RightUpperArm", V(0.06, 1.1, 0.06), V(h.X, h.Y + 0.5, -0.5), H("8a5a2e"), 0.02, V(0, 0, 15))
	k:ell("RightUpperArm", V(0.2, 0.26, 0.2), V(h.X - 0.15, h.Y + 1.05, -0.5), H("fff8ee"))
end

Cast.YogaYasmin = function(k)
	local TANK, LEGGING, MAT = H("2fc0b0"), H("7a4ad0"), H("ff7ab8")
	k:body({ skin = S4, shirt = TANK, pants = LEGGING, sleeves = "none", shoes = WHITE, sole = H("d8d8e0") })
	k:rbox("UpperTorso", V(D.torsoW + 0.03, 0.2, D.torsoD + 0.03), V(0, HIP + 0.05, 0), H("5a2ab0"), 0.07) -- waistband
	for _, s in { -1, 1 } do
		k:rbox(leg(s), V(0.06, 1.5, 0.08), V(s * (LX + D.legW / 2 + 0.01), 1.05, 0), H("b89aff"), 0.02)
	end
	k:hairStyle("bun", H("1a1410"))
	band(k, "HeadDetail", D.headW + 0.06, D.headD + 0.06, HY + 0.45, 0.14, MAT)
	local x = AX + 0.42 -- rolled yoga mat under the arm
	k:cyl("LeftUpperArm", V(1.5, 0.44, 0.44), V(x, 2.7, 0), MAT, V(0, 90, 0))
	k:cyl("LeftUpperArm", V(0.04, 0.3, 0.3), V(x, 2.7, -0.76), H("ffb8d8"), V(0, 90, 0))
	k:rbox("LeftUpperArm", V(0.06, 0.8, 0.06), V(x - 0.12, 3.05, 0), H("5a2ab0"), 0.02)
end

------------------------------------------------------------------ UNCOMMON
Cast.RosaTheBaker = function(k)
	local SCARF, APRON = H("d94a5a"), H("fbe6d6")
	k:body({ skin = S3, shirt = WHITE, pants = H("3a3a44"), sleeves = "short", cuff = WHITE, shoes = BLACK })
	double(k, H("c8ccd6"), SH - 0.35, 3, 0.3)
	k:fuse("UpperTorso", SCARF, { { "wedge", V(0.7, 0.32, 0.1), V(0, SH - 0.2, k:frontZ(0.05)), V(0, 180, 180) } })
	k:apron(APRON, { length = 1.15, pocket = SCARF, tie = SCARF })
	k:hairStyle("bun", H("2a1810"))
	k:dome("HeadDetail", V(1.62, 1.0, 1.52), V(0, HT - 0.28, 0.03), SCARF) -- headscarf
	k:ell("HeadDetail", V(0.36, 0.3, 0.3), V(0, HT - 0.1, 0.8), SCARF)
	for _, p in { { -0.4, 0.12, -0.6 }, { 0.3, 0.3, -0.5 }, { 0.6, 0.0, -0.3 }, { -0.1, 0.42, -0.1 } } do
		k:ell("HeadDetail", V(0.12, 0.08, 0.12), V(p[1], HT - 0.28 + p[2], p[3]), WHITE)
	end
	local h = k:hand(-1) -- rolling pin
	k:cyl("RightUpperArm", V(1.0, 0.32, 0.32), V(h.X + 0.25, h.Y + 0.2, -0.5), H("e0b07a"), V(0, 0, 70))
	for _, d in { -0.62, 0.62 } do
		local a = math.rad(70)
		k:cyl("RightUpperArm", V(0.3, 0.14, 0.14), V(h.X + 0.25 + math.cos(a) * d, h.Y + 0.2 + math.sin(a) * d, -0.5), H("b8864e"), V(0, 0, 70))
	end
end

Cast.CaptainBarnacle = function(k)
	local COAT, BEARD = H("1f2f5c"), H("f2f2f2")
	k:body({ skin = S3, shirt = COAT, pants = H("3a3a4a"), sleeves = "long", cuff = GOLD, shoes = BLACK, torsoD = 1.06 })
	k:coatSkirt(COAT, 0.85, true)
	double(k, GOLD, SH - 0.45, 4, 0.32)
	k:rbox("UpperTorso", V(1.0, 0.26, 0.9), V(0, SH + 0.02, 0.04), WHITE, 0.1) -- turtleneck
	k:beard(BEARD, 0.72, true)
	-- captain's hat
	k:rbox("HeadDetail", V(1.62, 0.36, 1.5), V(0, HT + 0.05, 0.02), WHITE, 0.16)
	k:dome("HeadDetail", V(1.66, 0.4, 1.54), V(0, HT + 0.2, 0.02), WHITE)
	k:rbox("HeadDetail", V(1.5, 0.12, 1.38), V(0, HT - 0.07, 0.02), BLACK, 0.05)
	k:rbox("HeadDetail", V(1.2, 0.08, 0.5), V(0, HT - 0.12, -0.86), BLACK, 0.04, V(-12, 0, 0))
	k:rbox("HeadDetail", V(0.32, 0.26, 0.05), V(0, HT + 0.05, -0.77), GOLD, 0.04)
	local h = k:hand(-1) -- fishing rod
	k:rbox("RightUpperArm", V(0.07, 2.6, 0.07), V(h.X - 0.3, h.Y + 1.15, -0.62), H("6b4426"), 0.03, V(-18, 0, 15))
	k:cyl("RightUpperArm", V(0.14, 0.26, 0.26), V(h.X + 0.02, h.Y + 0.05, -0.46), H("c8ccd6"))
end

Cast.DrFizz = function(k)
	local LAB, SHIRT, TIE, GOG = WHITE, H("7ad04a"), H("7a3ad0"), H("3a3a44")
	k:body({ skin = S1, shirt = LAB, pants = H("4a4a5a"), sleeves = "long", cuff = H("e8e8ec"), shoes = H("3a3a3a") })
	k:lapels(LAB, SHIRT, { depth = 0.95, width = 0.62, lapel = H("ececf0") })
	k:tie(TIE, 0.68)
	k:coatSkirt(LAB, 1.05, true)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.42, 0.38, 0.06), V(s * 0.52, HIP + 0.4, k:frontZ(0.02)), H("e4e4ea"), 0.04)
	end
	for i, c in { H("e04040"), H("3a6ad0") } do -- pens in the chest pocket
		k:rbox("UpperTorso", V(0.06, 0.3, 0.06), V(0.42 + i * 0.1, SH - 0.5, k:frontZ(0.06)), c, 0.02)
	end
	k:hairStyle("tufts", WHITE)
	for _, p in { { -0.55, 0.42, 30 }, { 0.55, 0.42, -30 }, { -0.25, 0.62, 12 }, { 0.25, 0.62, -12 } } do
		k:fuse("HeadDetail", WHITE, { { "wedge", V(0.3, 0.5, 0.36), V(p[1], HT + p[2] - 0.3, 0.2), V(0, 0, p[3]) } })
	end
	band(k, "HeadDetail", D.headW + 0.06, D.headD + 0.06, HY + 0.46, 0.12, GOG) -- goggles on the forehead
	for _, s in { -1, 1 } do
		k:cyl("HeadDetail", V(0.16, 0.4, 0.4), V(s * 0.3, HY + 0.48, -0.7), GOG, V(0, 90, 0))
		k:cyl("HeadDetail", V(0.04, 0.3, 0.3), V(s * 0.3, HY + 0.48, -0.79), H("9fe8c8"), V(0, 90, 0))
	end
	local h = k:hand(-1) -- bubbling flask
	local fl = k:ball("RightUpperArm", 0.6, V(h.X, h.Y + 0.3, -0.5), H("e8fff4"))
	fl.Transparency = 0.35
	k:ball("RightUpperArm", 0.48, V(h.X, h.Y + 0.27, -0.5), H("5ae84a"))
	k:cyl("RightUpperArm", V(0.4, 0.2, 0.2), V(h.X, h.Y + 0.7, -0.5), H("e8fff4"), V(0, 0, 90))
	for _, b in { { 0.05, 1.0, 0.12 }, { -0.08, 1.22, 0.09 } } do
		k:ball("RightUpperArm", b[3], V(h.X + b[1], h.Y + b[2], -0.5), H("8af07a"))
	end
end

Cast.FirefighterFaye = function(k)
	local COAT, REFL, HELMET = H("e8b830"), H("dfe4ea"), H("e02a2a")
	k:body({ skin = S5, shirt = COAT, pants = COAT, sleeves = "long", cuff = REFL, shoes = BLACK, hands = H("3a3a3a") })
	boots(k, BLACK, 0.6)
	for _, y in { HIP + 0.3, HIP + 0.95 } do
		band(k, "UpperTorso", D.torsoW + 0.03, D.torsoD + 0.03, y, 0.13, REFL)
	end
	armBand(k, 2.75, 0.12, REFL)
	legBand(k, 1.15, 0.12, REFL)
	for i = 0, 3 do
		k:rbox("UpperTorso", V(0.24, 0.08, 0.06), V(0, SH - 0.3 - i * 0.38, k:frontZ(0.03)), BLACK, 0.02)
	end
	k:collar(H("c89a20"), 8)
	k:hairStyle("ponytail", H("3a1a10"), { tie = HELMET, hat = true })
	k:dome("HeadDetail", V(1.68, 1.15, 1.6), V(0, HT - 0.3, 0.03), HELMET)
	k:rbox("HeadDetail", V(1.86, 0.08, 2.0), V(0, HT - 0.26, 0.2), HELMET, 0.04, V(6, 0, 0)) -- brim, longer at the back
	k:rbox("HeadDetail", V(0.12, 0.36, 1.5), V(0, HT + 0.18, 0.03), H("b81e1e"), 0.05) -- ridge
	k:rbox("HeadDetail", V(0.5, 0.46, 0.06), V(0, HT - 0.02, -0.82), GOLD, 0.06, V(-15, 0, 0)) -- badge
	local h = k:hand(1) -- extinguisher
	k:rbox("LeftUpperArm", V(0.48, 0.95, 0.48), V(h.X + 0.05, h.Y - 0.2, -0.52), H("e02a2a"), 0.2)
	k:rbox("LeftUpperArm", V(0.22, 0.2, 0.22), V(h.X + 0.05, h.Y + 0.35, -0.52), H("c8ccd6"), 0.06)
	k:rbox("LeftUpperArm", V(0.08, 0.08, 0.5), V(h.X - 0.1, h.Y + 0.38, -0.72), BLACK, 0.03, V(-20, 0, 0))
	k:rbox("LeftUpperArm", V(0.4, 0.2, 0.05), V(h.X + 0.05, h.Y - 0.15, -0.78), WHITE, 0.03)
end

Cast.MagicianMarvin = function(k)
	local COAT, RED = H("1e1e2a"), H("c8203a")
	k:body({ skin = S2, shirt = COAT, pants = COAT, sleeves = "long", cuff = WHITE, shoes = BLACK, hands = WHITE })
	k:lapels(COAT, WHITE, { depth = 0.95, width = 0.66, lapel = RED })
	k:bowtie(RED)
	k:buttons(2, GOLD, 0, HIP + 0.55, 0.3)
	k:rbox("UpperTorso", V(2.1, 2.5, 0.08), V(0, HIP + 0.55, 0.6), COAT, 0.06) -- cape
	k:rbox("UpperTorso", V(2.0, 2.4, 0.04), V(0, HIP + 0.55, 0.55), RED, 0.04)
	k:rbox("UpperTorso", V(1.9, 0.62, 0.1), V(0, SH + 0.15, 0.62), RED, 0.06, V(-12, 0, 0)) -- standing collar
	k:hairStyle("side", H("1a1a1a"))
	k:topHat(COAT, RED, 0.95)
	local h = k:hand(-1) -- wand
	k:rbox("RightUpperArm", V(0.09, 0.9, 0.09), V(h.X, h.Y + 0.4, -0.5), BLACK, 0.03, V(-25, 0, 10))
	k:rbox("RightUpperArm", V(0.1, 0.2, 0.1), V(h.X - 0.08, h.Y + 0.83, -0.7), WHITE, 0.03, V(-25, 0, 10))
	local h2 = k:hand(1) -- a playing card
	k:rbox("LeftUpperArm", V(0.36, 0.5, 0.03), V(h2.X, h2.Y + 0.3, -0.48), WHITE, 0.03, V(0, 0, -12))
	k:ell("LeftUpperArm", V(0.16, 0.16, 0.03), V(h2.X, h2.Y + 0.3, -0.5), RED)
end

Cast.FarmerFrank = function(k)
	local SHIRT, SHIRT_D, DENIM, DENIM_D, STRAW = H("d94a3a"), H("8a2a22"), H("3a6ab8"), H("2a4f8a"), H("e8c878")
	k:body({ skin = S3, shirt = SHIRT, pants = DENIM, sleeves = "short", cuff = SHIRT_D, shoes = H("6b4426"), sole = H("3a2a1e") })
	k:collar(SHIRT_D)
	for _, x in { -0.3, 0.3 } do
		k:rbox("UpperTorso", V(0.05, 1.8, 0.04), V(x, HIP + 0.92, k:frontZ(0.005)), SHIRT_D, 0.02)
	end
	k:rbox("UpperTorso", V(1.12, 0.95, 0.06), V(0, HIP + 0.5, k:frontZ(0.01)), DENIM, 0.05)
	k:rbox("UpperTorso", V(0.5, 0.36, 0.06), V(0, HIP + 0.55, k:frontZ(0.04)), DENIM_D, 0.04)
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.18, 0.95, 0.06), V(s * 0.42, SH - 0.45, k:frontZ(0.01)), DENIM, 0.03)
		k:ball("UpperTorso", 0.13, V(s * 0.42, HIP + 0.95, k:frontZ(0.05)), GOLD)
	end
	k:hairStyle("messy", H("8a5a2e"))
	k:brimHat(STRAW, SHIRT, 2.3, 0.55)
	local h = k:hand(-1) -- a cherry pie
	k:cyl("RightUpperArm", V(0.24, 0.9, 0.9), V(h.X + 0.1, h.Y + 0.12, -0.6), H("c8862c"), V(0, 0, 90))
	for _, d in { -0.2, 0.2 } do
		k:rbox("RightUpperArm", V(0.1, 0.06, 0.8), V(h.X + 0.1 + d, h.Y + 0.25, -0.6), H("e8b060"), 0.03)
		k:rbox("RightUpperArm", V(0.8, 0.06, 0.1), V(h.X + 0.1, h.Y + 0.26, -0.6 + d), H("e8b060"), 0.03)
	end
end

Cast.NurseNina = function(k)
	local SCRUB, SCRUB_D = H("3ab8b0"), H("2a908a")
	k:body({ skin = S6, shirt = SCRUB, pants = SCRUB, sleeves = "short", cuff = SCRUB_D, shoes = WHITE, sole = H("d8d8e0") })
	k:lapels(SCRUB, S6, { depth = 0.5, width = 0.5, lapel = SCRUB_D })
	k:rbox("UpperTorso", V(0.42, 0.36, 0.06), V(-0.5, SH - 0.7, k:frontZ(0.02)), SCRUB_D, 0.04)
	k:rbox("UpperTorso", V(0.06, 0.3, 0.06), V(-0.42, SH - 0.56, k:frontZ(0.06)), H("e04040"), 0.02)
	k:rbox("UpperTorso", V(0.36, 0.46, 0.04), V(0.5, SH - 0.75, k:frontZ(0.03)), WHITE, 0.04) -- ID badge
	k:rbox("UpperTorso", V(0.24, 0.16, 0.03), V(0.5, SH - 0.66, k:frontZ(0.05)), H("3a6ad0"), 0.02)
	for _, s in { -1, 1 } do -- stethoscope
		k:rbox("UpperTorso", V(0.07, 0.9, 0.07), V(s * 0.3, SH - 0.38, k:frontZ(0.08)), H("3a3a44"), 0.03, V(0, 0, s * -8))
	end
	k:rbox("UpperTorso", V(0.7, 0.07, 0.07), V(0, SH - 0.02, -0.3), H("3a3a44"), 0.03)
	k:cyl("UpperTorso", V(0.08, 0.26, 0.26), V(0.25, SH - 0.88, k:frontZ(0.1)), H("c8ccd6"), V(0, 90, 0))
	k:hairStyle("bun", H("1a1410"))
	local h = k:hand(1) -- clipboard
	k:rbox("LeftUpperArm", V(0.6, 0.8, 0.05), V(h.X, h.Y + 0.3, -0.48), H("a8743a"), 0.04, V(0, 0, -8))
	k:rbox("LeftUpperArm", V(0.5, 0.64, 0.03), V(h.X, h.Y + 0.27, -0.51), WHITE, 0.02, V(0, 0, -8))
	k:rbox("LeftUpperArm", V(0.26, 0.1, 0.06), V(h.X + 0.05, h.Y + 0.68, -0.52), H("c8ccd6"), 0.02, V(0, 0, -8))
end

Cast.MechanicMax = function(k)
	local COVER, COVER_D, CAP = H("3a5a9a"), H("2a4278"), H("ff7a1a")
	k:body({ skin = S4, shirt = COVER, pants = COVER, sleeves = "short", cuff = COVER_D, shoes = BLACK, hands = H("3a3a3a") })
	k:collar(COVER_D)
	k:rbox("UpperTorso", V(0.06, 1.6, 0.04), V(0, HIP + 0.85, k:frontZ(0.01)), H("c8ccd6"), 0.02) -- zip
	k:ell("UpperTorso", V(0.5, 0.3, 0.05), V(0.48, SH - 0.62, k:frontZ(0.01)), WHITE) -- name patch
	k:rbox("UpperTorso", V(0.3, 0.06, 0.03), V(0.48, SH - 0.62, k:frontZ(0.04)), H("e04040"), 0.02)
	k:belt(BLACK, H("c8ccd6"))
	spots(k, { { -0.5, 2.2, 0.18, H("2a2a2a") }, { 0.4, 2.55, 0.12, H("2a2a2a") } }, k:frontZ(0.005))
	k:rbox("UpperTorso", V(0.3, 0.55, 0.06), V(-0.62, HIP - 0.2, 0.52), H("e04040"), 0.04, V(0, 0, 8)) -- rag
	k:hairStyle("short", H("1a1a1a"), { hat = true })
	k:capHat(CAP, H("d95a10"), true)
	local h = k:hand(-1) -- wrench
	k:rbox("RightUpperArm", V(0.12, 1.0, 0.07), V(h.X, h.Y + 0.4, -0.5), H("b8bec8"), 0.03)
	k:carve("RightUpperArm", V(0.42, 0.34, 0.08), V(h.X, h.Y + 0.95, -0.5), H("b8bec8"), 0.06, { { V(0.18, 0.24, 0.3), V(h.X, h.Y + 1.06, -0.5) } })
end

Cast.ArtistAria = function(k)
	local SMOCK, NAVY = H("f4f0e8"), H("26345e")
	k:body({ skin = S1, shirt = SMOCK, pants = H("2a2a3a"), sleeves = "long", cuff = NAVY, shoes = H("e04040") })
	for _, y in { 2.35, 2.75, 3.15 } do
		armBand(k, y, 0.12, NAVY, 0.02)
	end
	k:coatSkirt(SMOCK, 0.7, false, 0.1)
	spots(k, { { -0.5, 3.1, 0.22, H("3a8bff") }, { 0.4, 2.6, 0.26, H("ff4fa0") }, { -0.2, 2.2, 0.2, H("ffd21f") },
		{ 0.55, 3.3, 0.16, H("5ae84a") }, { -0.6, 1.5, 0.24, H("ff7a1a") } }, k:frontZ(0.01))
	k:hairStyle("long", H("2a1810"))
	k:ell("HeadDetail", V(1.7, 0.36, 1.55), V(0.1, HT + 0.08, 0.05), H("d92a3a"), V(0, 0, -10)) -- beret
	k:rbox("HeadDetail", V(0.08, 0.16, 0.08), V(0.12, HT + 0.3, 0.05), H("d92a3a"), 0.03)
	local h = k:hand(1) -- palette
	k:carve("LeftUpperArm", V(0.9, 0.06, 0.66), V(h.X + 0.1, h.Y + 0.15, -0.55), H("c8964e"), 0.25, { { V(0.16, 0.2, 0.16), V(h.X - 0.2, h.Y + 0.15, -0.42) } })
	for i, c in { H("3a8bff"), H("ff4fa0"), H("ffd21f"), H("5ae84a") } do
		k:ell("LeftUpperArm", V(0.14, 0.06, 0.14), V(h.X + 0.25 - (i % 2) * 0.22, h.Y + 0.2, -0.75 + math.floor((i - 1) / 2) * 0.22), c)
	end
	local h2 = k:hand(-1) -- brush
	k:rbox("RightUpperArm", V(0.07, 0.8, 0.07), V(h2.X, h2.Y + 0.35, -0.5), H("c8964e"), 0.03, V(-20, 0, 0))
	k:rbox("RightUpperArm", V(0.1, 0.18, 0.1), V(h2.X, h2.Y + 0.78, -0.65), H("3a8bff"), 0.04, V(-20, 0, 0))
end

Cast.WrestlerRonda = function(k)
	local SINGLET, SINGLET_D, HAIR = H("d92a4a"), H("a81e38"), H("ff4fa0")
	k:body({ skin = S3, shirt = SINGLET, pants = SINGLET, sleeves = "none", legs = "shorts", socks = SINGLET, sockH = 0.9,
		shoes = SINGLET, sole = WHITE, torsoD = 1.04 })
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.3, 0.3, 0.06), V(s * 0.55, SH - 0.2, k:frontZ(0.0)), S3, 0.08) -- singlet straps
		k:rbox(leg(s), V(D.legW + 0.06, 0.32, D.legD + 0.06), V(s * LX, 1.05, -0.02), BLACK, 0.1) -- knee pads
		k:rbox(arm(s), V(D.armW + 0.02, 0.3, D.armD + 0.02), V(s * AX, 2.1, 0), WHITE, 0.08) -- wrist tape
	end
	k:rbox("UpperTorso", V(D.torsoW + 0.1, 0.42, D.torsoD + 0.12), V(0, HIP + 0.2, 0), GOLD_D, 0.1) -- title belt
	k:rbox("UpperTorso", V(0.85, 0.62, 0.08), V(0, HIP + 0.22, k:frontZ(0.07)), GOLD, 0.12)
	k:ell("UpperTorso", V(0.38, 0.38, 0.06), V(0, HIP + 0.22, k:frontZ(0.11)), H("e04040"))
	k:rbox("UpperTorso", V(0.6, 0.12, 0.05), V(0, SH - 0.7, k:frontZ(0.01)), SINGLET_D, 0.03)
	k:hairStyle("mohawk", HAIR)
end

Cast.PilotPaige = function(k)
	local NAVY, NAVY_D = H("1f2f5c"), H("15203e")
	k:body({ skin = S2, shirt = NAVY, pants = NAVY, sleeves = "long", cuff = GOLD, shoes = BLACK })
	armBand(k, 2.32, 0.07, GOLD, 0.06)
	k:lapels(NAVY, WHITE, { depth = 0.9, width = 0.62, lapel = NAVY_D })
	k:tie(BLACK, 0.62)
	k:buttons(2, GOLD, 0, HIP + 0.6, 0.32)
	k:rbox("UpperTorso", V(0.56, 0.1, 0.05), V(0.48, SH - 0.5, k:frontZ(0.03)), GOLD, 0.03) -- wings pin
	k:ell("UpperTorso", V(0.16, 0.16, 0.06), V(0.48, SH - 0.5, k:frontZ(0.05)), GOLD_D)
	k:hairStyle("bob", H("e0b85a"))
	k:rbox("HeadDetail", V(1.6, 0.3, 1.5), V(0, HT + 0.0, 0.02), NAVY, 0.1) -- pilot cap
	k:rbox("HeadDetail", V(1.72, 0.18, 1.6), V(0, HT + 0.22, 0.02), WHITE, 0.08)
	k:rbox("HeadDetail", V(1.2, 0.08, 0.5), V(0, HT - 0.12, -0.86), BLACK, 0.04, V(-12, 0, 0))
	k:rbox("HeadDetail", V(0.5, 0.14, 0.05), V(0, HT + 0.03, -0.78), GOLD, 0.03)
	local h = k:hand(1) -- flight bag
	k:rbox("LeftUpperArm", V(0.24, 0.12, 0.08), V(h.X, h.Y - 0.08, -0.05), BLACK, 0.04)
	k:rbox("LeftUpperArm", V(0.42, 0.8, 0.9), V(h.X + 0.05, h.Y - 0.6, -0.05), H("2a2a34"), 0.1)
	k:rbox("LeftUpperArm", V(0.44, 0.08, 0.92), V(h.X + 0.05, h.Y - 0.45, -0.05), H("c8ccd6"), 0.03)
end

Cast.MusicianMoe = function(k)
	local RED, RED_D = H("c8203a"), H("9a1428")
	k:body({ skin = S6, shirt = RED, pants = WHITE, sleeves = "long", cuff = GOLD, shoes = BLACK, hands = WHITE })
	for i = 0, 3 do -- gold frogging
		k:rbox("UpperTorso", V(0.8, 0.07, 0.05), V(0, SH - 0.4 - i * 0.32, k:frontZ(0.02)), GOLD, 0.03)
	end
	k:buttons(4, GOLD, 0, SH - 0.4, 0.32)
	for _, s in { -1, 1 } do -- epaulettes
		k:rbox(arm(s), V(D.armW + 0.2, 0.16, D.armD + 0.12), V(s * AX, SH + 0.02, 0), GOLD, 0.06)
		k:rbox(leg(s), V(0.08, 1.5, 0.1), V(s * (LX + D.legW / 2 + 0.01), 1.05, 0), RED, 0.02)
	end
	k:rbox("UpperTorso", V(D.torsoW + 0.04, 0.16, D.torsoD + 0.04), V(0, HIP + 0.08, 0), WHITE, 0.06)
	k:hairStyle("short", H("1a1410"))
	k:rbox("HeadDetail", V(1.3, 1.0, 1.2), V(0, HT + 0.35, 0.02), RED_D, 0.12) -- shako
	k:rbox("HeadDetail", V(1.34, 0.14, 1.24), V(0, HT + 0.82, 0.02), GOLD, 0.05)
	k:rbox("HeadDetail", V(1.1, 0.08, 0.45), V(0, HT - 0.12, -0.78), BLACK, 0.04, V(-12, 0, 0))
	k:ell("HeadDetail", V(0.38, 0.38, 0.06), V(0, HT + 0.35, -0.62), GOLD)
	k:ell("HeadDetail", V(0.3, 0.75, 0.3), V(0, HT + 1.2, 0.02), WHITE) -- plume
	-- tuba
	local T = "LeftUpperArm"
	k:rbox(T, V(0.75, 1.0, 0.55), V(0.35, 2.55, -0.82), GOLD, 0.2)
	k:cyl(T, V(0.9, 0.38, 0.38), V(0.75, 3.35, -0.6), GOLD, V(0, 0, 70))
	k:cyl(T, V(0.38, 1.25, 1.25), V(0.95, 4.0, -0.55), GOLD, V(0, 0, 90))
	k:cyl(T, V(0.4, 1.0, 1.0), V(0.95, 4.02, -0.55), GOLD_D, V(0, 0, 90))
	k:cyl(T, V(0.6, 0.18, 0.18), V(0.0, 2.95, -0.9), GOLD, V(0, 90, 0))
	for i = 0, 2 do
		k:cyl(T, V(0.2, 0.12, 0.12), V(0.1 + i * 0.16, 3.12, -1.08), GOLD_D, V(0, 0, 90))
	end
end

------------------------------------------------------------------ RARE
Cast.BaronVonBanana = function(k)
	local FUR, FUR_L, VEST = H("7a4a2a"), H("e2bf92"), H("6a2a8a")
	k:body({ skin = FUR, shirt = VEST, pants = H("3a2a4a"), sleeves = "long", cuff = WHITE, shoes = FUR_L, sole = FUR, hands = FUR_L })
	k:lapels(VEST, WHITE, { depth = 0.9, width = 0.6, lapel = H("4a1a62") })
	k:bowtie(GOLD)
	k:coatSkirt(VEST, 0.9, true)
	k:buttons(2, GOLD, 0, HIP + 0.6, 0.3)
	for _, s in { -1, 1 } do -- monkey ears
		k:ell("HeadDetail", V(0.2, 0.52, 0.52), V(s * 0.8, HY + 0.1, 0.05), FUR)
		k:ell("HeadDetail", V(0.06, 0.34, 0.34), V(s * 0.9, HY + 0.1, 0.05), FUR_L)
	end
	k:topHat(BLACK, VEST, 0.9)
	k:ring("HeadDetail", 0.42, 0.33, 0.05, V(0.29, HY + 0.05, -0.7), GOLD) -- monocle
	k:rbox("HeadDetail", V(0.04, 0.6, 0.04), V(0.48, HY - 0.25, -0.68), GOLD, 0.02)
	k:fuse("UpperTorso", FUR, { -- curly tail
		{ "ball", V(0.22, 0.22, 0.22), V(0, HIP - 0.05, 0.62) }, { "ball", V(0.22, 0.22, 0.22), V(0, HIP - 0.2, 0.85) },
		{ "ball", V(0.22, 0.22, 0.22), V(0, HIP - 0.2, 1.08) }, { "ball", V(0.22, 0.22, 0.22), V(0, HIP + 0.02, 1.22) },
		{ "ball", V(0.22, 0.22, 0.22), V(0, HIP + 0.25, 1.15) }, { "ball", V(0.22, 0.22, 0.22), V(0, HIP + 0.36, 0.95) },
	})
	local h = k:hand(-1) -- banana
	for i = 0, 2 do
		k:rbox("RightUpperArm", V(0.2, 0.36, 0.2), V(h.X - 0.06 + i * 0.05, h.Y + 0.25 + i * 0.3, -0.5 - i * 0.04), H("ffd23f"), 0.08, V(-10, 0, -20 + i * 18))
	end
	k:rbox("RightUpperArm", V(0.1, 0.12, 0.1), V(h.X + 0.08, h.Y + 1.08, -0.62), H("6b4426"), 0.03)
end

Cast.BeepBot = function(k)
	local METAL, METAL_D, ORANGE, DARK = H("d8dde6"), H("aab2c0"), H("ff8a2a"), H("3a3f4a")
	k:body({ skin = METAL, shirt = METAL, pants = DARK, sleeves = "long", cuff = ORANGE, shoes = DARK, sole = ORANGE, hands = METAL_D })
	k:rbox("UpperTorso", V(1.1, 0.95, 0.06), V(0, HIP + 0.95, k:frontZ(0.01)), ORANGE, 0.08) -- delivery panel
	k:ell("UpperTorso", V(0.5, 0.5, 0.05), V(0, HIP + 1.0, k:frontZ(0.04)), WHITE)
	k:rbox("UpperTorso", V(0.3, 0.08, 0.04), V(0, HIP + 1.0, k:frontZ(0.07)), ORANGE, 0.02)
	k:rbox("UpperTorso", V(0.08, 0.3, 0.04), V(0, HIP + 1.0, k:frontZ(0.07)), ORANGE, 0.02)
	for _, s in { -1, 1 } do
		k:cyl(leg(s), V(0.12, 0.42, 0.42), V(s * (LX + D.legW / 2 + 0.07), 0.25, -0.1), ORANGE) -- wheel hubs
		k:cyl("HeadDetail", V(0.14, 0.36, 0.36), V(s * (D.headW / 2 + 0.06), HY, 0), ORANGE) -- ear bolts
		k:rbox(arm(s), V(D.armW + 0.04, 0.14, D.armD + 0.04), V(s * AX, 2.95, 0), DARK, 0.05)
	end
	k:rbox("HeadDetail", V(0.08, 0.5, 0.08), V(0.3, HT + 0.25, 0), DARK, 0.03) -- antenna
	k:ball("HeadDetail", 0.2, V(0.3, HT + 0.55, 0), ORANGE)
	for i = 0, 2 do -- a stack of pizza boxes carried in front
		k:rbox("UpperTorso", V(1.3, 0.16, 1.1), V(0, 2.25 + i * 0.18, -1.05), if i % 2 == 0 then H("f2ede0") else H("e2dcc8"), 0.03, V(0, (i - 1) * 6, 0))
	end
	k:ell("UpperTorso", V(0.4, 0.04, 0.4), V(0, 2.25 + 2 * 0.18 + 0.09, -1.05), H("e04040"))
end

Cast.PiratePatches = function(k)
	local COAT, COAT_D, PANTS = H("b8282e"), H("8a1a20"), H("2a2a3a")
	k:body({ skin = S3, shirt = COAT, pants = PANTS, sleeves = "long", cuff = GOLD, shoes = BLACK })
	k:lapels(COAT, WHITE, { depth = 0.95, width = 0.7, lapel = COAT_D })
	k:coatSkirt(COAT, 0.95, true)
	double(k, GOLD, SH - 0.45, 3, 0.3)
	k:belt(H("3a2a1e"), GOLD)
	boots(k, BLACK, 0.7, H("2a2a2a"))
	legBand(k, 1.25, 0.1, WHITE, 0.01)
	legBand(k, 1.55, 0.1, WHITE, 0.01)
	k:hairStyle("long", H("1a1a1a"))
	-- tricorn hat
	k:dome("HeadDetail", V(1.6, 0.9, 1.5), V(0, HT - 0.12, 0.03), BLACK)
	for _, a in { 0, 120, 240 } do
		local r = math.rad(a - 90)
		k:rbox("HeadDetail", V(1.3, 0.42, 0.12), V(math.cos(r) * 0.62, HT + 0.08, math.sin(r) * 0.6 + 0.03), BLACK, 0.06, V(-15, -(a - 90) + 90, 0))
	end
	k:rbox("HeadDetail", V(1.32, 0.06, 0.13), V(0, HT + 0.28, -0.62), GOLD, 0.02)
	k:ell("HeadDetail", V(0.3, 0.26, 0.05), V(0, HT + 0.08, -0.69), WHITE) -- skull badge
	-- eye patch over one eye
	k:ell("HeadDetail", V(0.38, 0.34, 0.06), V(0.29, HY + 0.05, -0.68), BLACK)
	k:rbox("HeadDetail", V(1.5, 0.05, 0.05), V(0.05, HY + 0.3, -0.66), BLACK, 0.02, V(0, 0, -18))
	-- parrot on the shoulder
	local px, py = -1.15, SH + 0.32
	k:ell("UpperTorso", V(0.38, 0.55, 0.42), V(px, py, 0.05), H("3ac04a"))
	k:ball("UpperTorso", 0.34, V(px, py + 0.38, -0.05), H("3ac04a"))
	k:fuse("UpperTorso", H("ffc83a"), { { "wedge", V(0.12, 0.16, 0.16), V(px, py + 0.34, -0.26), V(180, 0, 0) } })
	k:rbox("UpperTorso", V(0.16, 0.5, 0.12), V(px, py - 0.3, 0.3), H("e03a3a"), 0.05, V(30, 0, 0))
	k:ball("UpperTorso", 0.08, V(px - 0.1, py + 0.44, -0.18), BLACK)
	local h = k:hand(1) -- treasure map
	k:rbox("LeftUpperArm", V(0.7, 0.5, 0.04), V(h.X, h.Y + 0.28, -0.48), H("f0dca8"), 0.03, V(0, 0, -8))
	k:rbox("LeftUpperArm", V(0.1, 0.1, 0.02), V(h.X + 0.15, h.Y + 0.25, -0.51), H("e04040"), 0.01, V(0, 0, 45))
end

Cast.CowboyCody = function(k)
	local SHIRT, VEST, JEANS, HAT, BANDANA = H("5a8ad0"), H("8a5a2e"), H("3a5a9a"), H("a8743a"), H("d92a3a")
	k:body({ skin = S3, shirt = SHIRT, pants = JEANS, sleeves = "long", cuff = H("4a78b8"), shoes = H("6b3a1e"), sole = H("3a2010") })
	for _, s in { -1, 1 } do -- open vest
		k:rbox("UpperTorso", V(0.62, 1.7, 0.08), V(s * 0.56, HIP + 0.9, k:frontZ(0.02)), VEST, 0.05)
		k:rbox("UpperTorso", V(0.1, 1.7, 0.08), V(s * 0.25, HIP + 0.9, k:frontZ(0.04)), H("6b4426"), 0.03)
	end
	k:rbox("UpperTorso", V(D.torsoW + 0.06, 1.7, 0.08), V(0, HIP + 0.9, 0.52), VEST, 0.05)
	k:buttons(3, WHITE)
	k:fuse("UpperTorso", BANDANA, { { "wedge", V(0.8, 0.4, 0.1), V(0, SH - 0.22, k:frontZ(0.06)), V(0, 180, 180) } })
	k:rbox("UpperTorso", V(1.0, 0.14, 0.92), V(0, SH + 0.0, 0.04), BANDANA, 0.06)
	k:belt(H("5a3418"), GOLD)
	k:rbox("UpperTorso", V(0.4, 0.3, 0.08), V(0, HIP + 0.07, k:frontZ(0.06)), GOLD, 0.06)
	boots(k, H("6b3a1e"), 0.65, H("8a5a2e"))
	k:hairStyle("short", H("6b3a1e"))
	k:brimHat(HAT, H("5a3418"), 2.4, 0.62, true)
	k:ring("RightUpperArm", 0.7, 0.5, 0.1, V(-AX - 0.42, 1.95, 0), H("d8b878"), V(0, 90, 0)) -- lasso on the hip
end

Cast.ZombieZeke = function(k)
	local SKIN, SHIRT, PANTS = H("98c880"), H("8aa8c8"), H("5a5a6a")
	k:body({ skin = SKIN, shirt = SHIRT, pants = PANTS, sleeves = "short", cuff = H("6a88a8"), shoes = H("4a3a2a") })
	k:collar(H("6a88a8"))
	k:rbox("UpperTorso", V(0.17, 0.15, 0.08), V(0.08, SH - 0.22, k:frontZ(0.06)), H("a83a3a"), 0.04, V(0, 0, 12)) -- loose tie
	k:rbox("UpperTorso", V(0.15, 0.7, 0.05), V(0.14, SH - 0.62, k:frontZ(0.06)), H("a83a3a"), 0.04, V(0, 0, 12))
	spots(k, { { -0.45, 2.35, 0.28, H("6a7a8a") }, { 0.5, 3.0, 0.2, H("6a7a8a") }, { 0.2, 1.95, 0.22, SKIN } }, k:frontZ(0.005))
	for i = -3, 3 do -- ragged hem
		k:fuse("UpperTorso", SHIRT, { { "wedge", V(0.2, 0.22, 0.1), V(i * 0.24, HIP - 0.08, k:frontZ(0.0)), V(180, 0, 0) } })
	end
	for _, s in { -1, 1 } do -- torn trouser hems
		k:fuse(leg(s), PANTS, { { "wedge", V(0.22, 0.2, 0.1), V(s * LX - 0.15, 0.35, -D.legD / 2 - 0.02), V(180, 0, 0) } })
	end
	k:rbox("LeftUpperArm", V(D.armW + 0.02, 0.32, D.armD + 0.02), V(AX, 2.65, 0), H("f2ece0"), 0.08) -- bandage
	k:hairStyle("messy", H("2a3a22"))
end

Cast.NinjaNoodle = function(k)
	local SUIT, SASH = H("23232e"), H("d92a3a")
	k:body({ skin = S4, shirt = SUIT, pants = SUIT, sleeves = "long", cuff = H("3a3a46"), shoes = SUIT, sole = H("3a3a46"), hands = SUIT })
	-- hood over the whole head, an eye slit open
	k:carve("HeadDetail", V(D.headW + 0.12, D.headH + 0.1, D.headD + 0.12), V(0, HY + 0.02, 0), SUIT, 0.32, {
		{ V(1.2, 0.42, 0.6), V(0, HY + 0.06, -0.6) },
	})
	k:rbox("HeadDetail", V(0.2, 0.2, 0.2), V(0, HY + 0.2, 0.75), SASH, 0.06)
	for _, s in { -1, 1 } do
		k:rbox("HeadDetail", V(0.14, 0.6, 0.08), V(s * 0.18, HY - 0.15, 0.82), SASH, 0.03, V(15, 0, s * 15))
		k:rbox(arm(s), V(D.armW + 0.04, 0.5, D.armD + 0.04), V(s * AX, 2.3, 0), H("3a3a46"), 0.08) -- arm wraps
	end
	k:rbox("UpperTorso", V(D.torsoW + 0.05, 0.26, D.torsoD + 0.05), V(0, HIP + 0.12, 0), SASH, 0.08)
	k:rbox("UpperTorso", V(0.26, 0.26, 0.12), V(0.45, HIP + 0.12, k:frontZ(0.05)), SASH, 0.06)
	k:rbox("UpperTorso", V(0.14, 0.6, 0.06), V(0.5, HIP - 0.25, k:frontZ(0.06)), SASH, 0.03, V(0, 0, -10))
	for _, s in { -1, 1 } do -- crossed front of the gi
		k:rbox("UpperTorso", V(0.1, 1.3, 0.04), V(s * 0.2, SH - 0.6, k:frontZ(0.01)), H("3a3a46"), 0.02, V(0, 0, s * 25))
	end
	-- katana on the back
	k:rbox("UpperTorso", V(0.14, 2.3, 0.14), V(0, SH - 0.3, 0.6), BLACK, 0.05, V(0, 0, 40))
	k:rbox("UpperTorso", V(0.4, 0.08, 0.3), V(-0.35, SH + 0.15, 0.6), GOLD, 0.03, V(0, 0, 40))
	k:rbox("UpperTorso", V(0.13, 0.55, 0.13), V(-0.62, SH + 0.45, 0.6), SASH, 0.05, V(0, 0, 40))
end

Cast.KnightKevin = function(k)
	local ARMOR, ARMOR_D, TABARD, PLUME = H("c8ccd6"), H("9aa0ae"), H("3a6ad0"), H("e03a3a")
	k:body({ skin = S2, shirt = ARMOR, pants = ARMOR, sleeves = "long", cuff = ARMOR_D, shoes = ARMOR_D, hands = ARMOR_D })
	k:rbox("UpperTorso", V(1.15, 2.1, 0.06), V(0, HIP + 0.4, k:frontZ(0.02)), TABARD, 0.04) -- tabard
	k:rbox("UpperTorso", V(0.18, 1.2, 0.04), V(0, HIP + 0.55, k:frontZ(0.06)), GOLD, 0.02)
	k:rbox("UpperTorso", V(0.7, 0.18, 0.04), V(0, HIP + 0.85, k:frontZ(0.06)), GOLD, 0.02)
	k:belt(H("6b4426"), GOLD)
	for _, s in { -1, 1 } do
		k:dome(arm(s), V(D.armW + 0.36, 0.6, D.armD + 0.3), V(s * AX, SH - 0.12, 0), ARMOR_D) -- pauldrons
		k:rbox(leg(s), V(D.legW + 0.06, 0.3, D.legD + 0.06), V(s * LX, 1.05, -0.02), ARMOR_D, 0.1)
	end
	-- helmet with the face open, visor raised, plume
	k:carve("HeadDetail", V(D.headW + 0.16, D.headH + 0.2, D.headD + 0.16), V(0, HY + 0.06, 0), ARMOR, 0.3, {
		{ V(1.1, 0.95, 0.6), V(0, HY - 0.06, -0.6) },
	})
	k:rbox("HeadDetail", V(1.4, 0.3, 0.12), V(0, HT + 0.1, -0.68), ARMOR_D, 0.05, V(-30, 0, 0))
	k:rbox("HeadDetail", V(0.2, 0.6, 1.2), V(0, HT + 0.35, 0.15), PLUME, 0.1, V(-10, 0, 0))
	local x = AX + 0.42 -- shield
	k:rbox("LeftUpperArm", V(0.14, 1.2, 0.95), V(x, 2.6, -0.05), TABARD, 0.12)
	k:rbox("LeftUpperArm", V(0.16, 1.22, 0.16), V(x + 0.01, 2.6, -0.05), GOLD, 0.04)
	k:rbox("LeftUpperArm", V(0.16, 0.16, 0.97), V(x + 0.01, 2.75, -0.05), GOLD, 0.04)
	local h = k:hand(-1) -- sword
	k:rbox("RightUpperArm", V(0.1, 1.3, 0.04), V(h.X, h.Y + 0.85, -0.48), H("e0e4ea"), 0.03)
	k:rbox("RightUpperArm", V(0.46, 0.08, 0.12), V(h.X, h.Y + 0.18, -0.48), GOLD, 0.03)
	k:ball("RightUpperArm", 0.14, V(h.X, h.Y - 0.1, -0.48), GOLD)
end

Cast.MermaidMarina = function(k)
	local TAIL, TAIL_L, TOP, HAIR = H("2fb8a8"), H("8fe8d8"), H("b48ae0"), H("e04a3a")
	k:body({ skin = S1, shirt = TOP, pants = TAIL, sleeves = "none", legs = "skirt", skirtLen = 1.7, flare = 0.3,
		shoes = TAIL, sole = TAIL_L })
	for i = 0, 3 do -- scale rows
		local w = D.torsoW + 0.14 + (if i >= 2 then 0.3 else 0) + 0.02
		band(k, "UpperTorso", w, D.torsoD + 0.16 + (if i >= 2 then 0.3 else 0), HIP - 0.05 - i * 0.38, 0.08, TAIL_L)
	end
	for _, s in { -1, 1 } do -- tail fins at the hem
		k:fuse("UpperTorso", TAIL_L, { { "wedge", V(0.14, 0.55, 0.8), V(s * 1.25, 0.35, 0), V(0, s * 90, s * -30) } })
	end
	for i = -3, 3 do -- shell necklace
		k:ell("UpperTorso", V(0.13, 0.11, 0.06), V(i * 0.11, SH - 0.12 - (9 - i * i) * 0.025, k:frontZ(0.06)), H("ffc8d8"))
	end
	k:hairStyle("long", HAIR)
	k:fuse("HeadDetail", H("ff9a3a"), { -- starfish clip
		{ "block", V(0.36, 0.1, 0.06), V(0.55, HT - 0.1, -0.45), V(0, 0, 0) },
		{ "block", V(0.36, 0.1, 0.06), V(0.55, HT - 0.1, -0.45), V(0, 0, 72) },
		{ "block", V(0.36, 0.1, 0.06), V(0.55, HT - 0.1, -0.45), V(0, 0, 144) },
	})
	local h = k:hand(-1) -- trident
	k:rbox("RightUpperArm", V(0.09, 2.3, 0.09), V(h.X, h.Y + 0.35, -0.48), GOLD, 0.04)
	k:rbox("RightUpperArm", V(0.5, 0.09, 0.09), V(h.X, h.Y + 1.45, -0.48), GOLD, 0.04)
	for _, d in { -0.22, 0, 0.22 } do
		k:rbox("RightUpperArm", V(0.08, 0.4, 0.08), V(h.X + d, h.Y + 1.68, -0.48), GOLD, 0.03)
	end
end

Cast.ClownChuckles = function(k)
	local SUIT, RUFF = H("ffd23f"), WHITE
	k:body({ skin = H("fff3e6"), shirt = SUIT, pants = SUIT, sleeves = "long", cuff = H("ff4f9a"), shoes = H("e02a2a"), sole = H("fff3e6"), hands = WHITE })
	for _, s in { -1, 1 } do -- giant shoes
		k:rbox(leg(s), V(D.legW + 0.1, 0.36, 0.72), V(s * LX, 0.2, -0.72), H("e02a2a"), 0.16)
	end
	spots(k, { { -0.5, 3.1, 0.3, H("ff4f9a") }, { 0.45, 2.55, 0.3, H("3a8bff") }, { -0.2, 2.1, 0.28, H("5ae84a") }, { 0.5, 3.35, 0.24, H("b06aff") } }, k:frontZ(0.01))
	for _, s in { -1, 1 } do
		k:ell(leg(s), V(0.3, 0.3, 0.05), V(s * LX, 1.2, -D.legD / 2 - 0.02), if s < 0 then H("3a8bff") else H("ff4f9a"))
	end
	for i = 0, 9 do -- ruffle collar
		local a = math.rad(i * 36)
		k:ball("UpperTorso", 0.34, V(math.cos(a) * 0.55, SH + 0.05, math.sin(a) * 0.45 + 0.02), RUFF)
	end
	k:bowtie(H("3a8bff"), SH - 0.25)
	k:hairStyle("afro", H("ff5a2a"))
	for _, s in { -1, 1 } do
		k:ball("HeadDetail", 0.7, V(s * 0.95, HY + 0.15, 0.25), if s < 0 then H("3a8bff") else H("5ae84a"))
	end
	k:ball("HeadDetail", 0.3, V(0, HY - 0.08, -0.72), H("e8182e")) -- nose
end

------------------------------------------------------------------ EPIC + LEGENDARY
Cast.RetiredCEO = function(k)
	local VELVET, VELVET_D = H("7a1a2e"), H("5a1222")
	k:body({ skin = S1, shirt = VELVET, pants = H("2a2a34"), sleeves = "long", cuff = VELVET_D, shoes = BLACK })
	k:lapels(VELVET, WHITE, { depth = 0.85, width = 0.6, lapel = VELVET_D })
	k:ell("UpperTorso", V(0.36, 0.42, 0.14), V(0, SH - 0.32, k:frontZ(0.06)), GOLD) -- cravat
	k:ell("UpperTorso", V(0.18, 0.16, 0.12), V(0, SH - 0.12, k:frontZ(0.08)), GOLD_D)
	k:buttons(2, GOLD, 0, HIP + 0.65, 0.3)
	for i = 0, 4 do -- watch chain
		local t = (i - 2) / 2
		k:ball("UpperTorso", 0.07, V(0.15 + i * 0.12, HIP + 0.55 - (1 - t * t) * 0.15, k:frontZ(0.05)), GOLD)
	end
	k:cyl("UpperTorso", V(0.06, 0.22, 0.22), V(0.68, HIP + 0.5, k:frontZ(0.05)), GOLD, V(0, 90, 0))
	k:hairStyle("tufts", H("f0f0f0"))
	k:glasses("round", GOLD)
	local hx = -AX -- black cane with a gold knob
	k:rbox("RightUpperArm", V(0.13, 2.05, 0.13), V(hx, 1.07, -0.45), BLACK, 0.05)
	k:ball("RightUpperArm", 0.28, V(hx, 2.18, -0.45), GOLD)
end

Cast.ChefMega = function(k)
	local SCARF = H("d92a3a")
	k:body({ skin = S2, shirt = WHITE, pants = H("2a2a34"), sleeves = "long", cuff = GOLD, shoes = BLACK, torsoD = 1.06 })
	k:ell("UpperTorso", V(1.36, 1.0, 0.42), V(0, HIP + 0.65, -0.47), WHITE) -- belly
	double(k, GOLD, SH - 0.42, 4, 0.32)
	k:fuse("UpperTorso", SCARF, { { "wedge", V(0.8, 0.36, 0.1), V(0, SH - 0.2, k:frontZ(0.06)), V(0, 180, 180) } })
	k:rbox("UpperTorso", V(1.0, 0.14, 0.94), V(0, SH, 0.04), SCARF, 0.06)
	k:fuse("UpperTorso", GOLD, { -- star badge
		{ "block", V(0.34, 0.1, 0.06), V(0.5, SH - 0.6, k:frontZ(0.04)), V(0, 0, 0) },
		{ "block", V(0.34, 0.1, 0.06), V(0.5, SH - 0.6, k:frontZ(0.04)), V(0, 0, 72) },
		{ "block", V(0.34, 0.1, 0.06), V(0.5, SH - 0.6, k:frontZ(0.04)), V(0, 0, 144) },
	})
	for _, s in { -1, 1 } do -- checked trousers
		for _, y in { 0.7, 1.2 } do
			k:rbox(leg(s), V(0.2, 0.2, 0.04), V(s * LX - 0.18, y, -D.legD / 2 - 0.01), WHITE, 0.02)
			k:rbox(leg(s), V(0.2, 0.2, 0.04), V(s * LX + 0.18, y + 0.25, -D.legD / 2 - 0.01), WHITE, 0.02)
		end
	end
	k:hairStyle("short", H("1a1a1a"))
	k:chefHat(WHITE, GOLD, 1.15)
	local h = k:hand(-1) -- golden ladle
	k:rbox("RightUpperArm", V(0.09, 1.2, 0.09), V(h.X, h.Y + 0.5, -0.5), GOLD, 0.04, V(0, 0, 10))
	k:dome("RightUpperArm", V(0.5, 0.4, 0.5), V(h.X - 0.12, h.Y + 1.1, -0.5), GOLD, V(180, 0, 0))
end

Cast.RocketBaronRex = function(k)
	local SUIT, STRIPE, PACK = H("c8ccd6"), H("ff7a1a"), H("8a929e")
	k:body({ skin = S3, shirt = SUIT, pants = SUIT, sleeves = "long", cuff = STRIPE, shoes = STRIPE, sole = H("3a3a44"), hands = H("3a3a44") })
	k:rbox("UpperTorso", V(0.2, 2.2, 0.05), V(0, HIP + 0.9, k:frontZ(0.01)), STRIPE, 0.03, V(0, 0, 32))
	for _, s in { -1, 1 } do
		k:rbox(leg(s), V(0.08, 1.5, 0.1), V(s * (LX + D.legW / 2 + 0.01), 1.05, 0), STRIPE, 0.02)
		k:cyl("UpperTorso", V(1.4, 0.5, 0.5), V(s * 0.38, HIP + 1.0, 0.82), PACK, V(0, 0, 90)) -- jetpack
		k:cyl("UpperTorso", V(0.25, 0.36, 0.36), V(s * 0.38, HIP + 0.2, 0.82), H("e02a2a"), V(0, 0, 90))
		k:dome("UpperTorso", V(0.5, 0.4, 0.5), V(s * 0.38, HIP + 1.7, 0.82), PACK)
	end
	k:rbox("UpperTorso", V(0.6, 0.6, 0.06), V(-0.45, SH - 0.65, k:frontZ(0.02)), H("1f2f5c"), 0.1) -- mission patch
	k:ell("UpperTorso", V(0.2, 0.2, 0.05), V(-0.45, SH - 0.65, k:frontZ(0.05)), STRIPE)
	k:hairStyle("swoop", H("c8502a"))
	band(k, "HeadDetail", D.headW + 0.06, D.headD + 0.06, HY + 0.48, 0.12, H("6b4426")) -- goggles strap
	for _, s in { -1, 1 } do
		k:cyl("HeadDetail", V(0.18, 0.44, 0.44), V(s * 0.3, HY + 0.5, -0.7), H("6b4426"), V(0, 90, 0))
		k:cyl("HeadDetail", V(0.04, 0.32, 0.32), V(s * 0.3, HY + 0.5, -0.8), H("ffc83a"), V(0, 90, 0))
	end
	local h = k:hand(1) -- toy rocket
	k:cyl("LeftUpperArm", V(0.9, 0.36, 0.36), V(h.X, h.Y + 0.45, -0.5), WHITE, V(0, 0, 90))
	k:fuse("LeftUpperArm", H("e02a2a"), { { "wedge", V(0.36, 0.36, 0.36), V(h.X, h.Y + 1.08, -0.5) } })
	for _, s in { -1, 1 } do
		k:fuse("LeftUpperArm", H("e02a2a"), { { "wedge", V(0.06, 0.3, 0.26), V(h.X + s * 0.22, h.Y + 0.1, -0.5), V(0, s * 90, 0) } })
	end
	k:ell("LeftUpperArm", V(0.16, 0.16, 0.05), V(h.X, h.Y + 0.55, -0.69), H("4fb6ff"))
end

Cast.MiloVex = function(k)
	local PINK, PINK_D = H("ff4fa8"), H("d83088")
	k:body({ skin = S1, shirt = PINK, pants = BLACK, sleeves = "long", cuff = PINK_D, shoes = WHITE, sole = H("d8d8e0") })
	k:lapels(PINK, WHITE, { depth = 1.1, width = 0.7, lapel = PINK_D })
	k:buttons(1, BLACK, 0, HIP + 0.6)
	k:rbox("UpperTorso", V(0.3, 0.14, 0.05), V(0.5, SH - 0.55, k:frontZ(0.03)), WHITE, 0.03) -- pocket square
	k:hairStyle("swoop", H("f2d060"))
	k:glasses("shades", PINK, H("ff8ac8"))
	local h = k:hand(-1) -- shopping bags
	for i, c in { H("ff8ac8"), BLACK } do
		local x = h.X - 0.1 + (i - 1) * 0.3
		k:rbox("RightUpperArm", V(0.62, 0.72, 0.36), V(x, h.Y - 0.55, -0.15 - (i - 1) * 0.12), c, 0.04)
		k:ring("RightUpperArm", 0.4, 0.3, 0.04, V(x, h.Y - 0.12, -0.15 - (i - 1) * 0.12), c, V(0, 90, 0))
	end
end

Cast.DJBeatbox = function(k)
	local HOOD, NEON = H("1e1e26"), H("ff3cc8")
	k:body({ skin = S6, shirt = HOOD, pants = HOOD, sleeves = "long", cuff = NEON, shoes = WHITE, sole = NEON })
	for _, s in { -1, 1 } do
		k:rbox("UpperTorso", V(0.12, 1.72, 0.06), V(s * 0.62, HIP + 0.92, k:frontZ(0.01)), NEON, 0.03)
		k:rbox(arm(s), V(0.08, 1.2, 0.1), V(s * (AX + D.armW / 2 + 0.01), 2.85, 0), NEON, 0.02)
	end
	k:rbox("UpperTorso", V(1.3, 0.55, 0.5), V(0, SH - 0.05, 0.56), H("2a2a34"), 0.2)
	for i = -3, 3 do -- gold chain
		local t = i / 3
		k:ball("UpperTorso", 0.1, V(t * 0.36, SH - 0.12 - (1 - t * t) * 0.42, k:frontZ(0.06)), GOLD)
	end
	k:ell("UpperTorso", V(0.3, 0.3, 0.08), V(0, SH - 0.62, k:frontZ(0.08)), GOLD)
	k:hairStyle("short", H("1a1a1a"), { hat = true })
	k:capHat(BLACK, NEON, true)
	k:rbox("HeadDetail", V(1.76, 0.14, 0.32), V(0, HT + 0.32, 0.05), H("3a3a46"), 0.06) -- headphones
	for _, s in { -1, 1 } do
		k:rbox("HeadDetail", V(0.14, 0.5, 0.3), V(s * 0.84, HY + 0.6, 0.05), H("3a3a46"), 0.05)
		k:cyl("HeadDetail", V(0.3, 0.72, 0.72), V(s * 0.84, HY + 0.1, 0.05), BLACK)
		k:cyl("HeadDetail", V(0.05, 0.44, 0.44), V(s * 0.99, HY + 0.1, 0.05), NEON)
	end
	local h = k:hand(1) -- vinyl record
	k:cyl("LeftUpperArm", V(0.05, 0.95, 0.95), V(h.X, h.Y + 0.35, -0.5), BLACK, V(0, 90, 0))
	k:cyl("LeftUpperArm", V(0.06, 0.32, 0.32), V(h.X, h.Y + 0.35, -0.53), NEON, V(0, 90, 0))
end

Cast.KikiGlow = function(k)
	local DRESS, DRESS_D, HAIR = H("c8a8f0"), H("a888e0"), H("ff8ad0")
	k:body({ skin = S1, shirt = DRESS, pants = DRESS, sleeves = "none", legs = "skirt", skirtLen = 1.7, flare = 0.4,
		shoes = H("ff8ad0"), sole = WHITE })
	k:rbox("UpperTorso", V(D.torsoW + 0.14, 0.16, D.torsoD + 0.16), V(0, HIP + 0.25, 0), DRESS_D, 0.06)
	for _, p in { { -0.5, 3.1 }, { 0.4, 2.6 }, { -0.2, 2.25 }, { 0.6, 1.5 }, { -0.6, 1.1 }, { 0.2, 0.75 }, { -0.1, 1.45 } } do
		local z = if p[2] < HIP then -(D.torsoD + 0.14 + 0.4) / 2 - 0.02 else k:frontZ(0.02)
		k:rbox("UpperTorso", V(0.13, 0.13, 0.04), V(p[1], p[2], z), WHITE, 0.02, V(0, 0, 45)) -- sparkles
	end
	k:hairStyle("long", HAIR)
	k:crown(H("e0e8ff"), H("ff6ad0"), 5) -- tiara
	local h = k:hand(-1) -- hand mirror
	k:rbox("RightUpperArm", V(0.1, 0.55, 0.1), V(h.X, h.Y + 0.2, -0.48), GOLD, 0.04)
	k:ring("RightUpperArm", 0.6, 0.46, 0.08, V(h.X, h.Y + 0.72, -0.48), GOLD)
	k:cyl("RightUpperArm", V(0.05, 0.48, 0.48), V(h.X, h.Y + 0.72, -0.48), H("d8f0ff"), V(0, 90, 0))
end

Cast.TechTed = function(k)
	local TURTLE, JEANS = H("1e1e24"), H("3a5a9a")
	k:body({ skin = S4, shirt = TURTLE, pants = JEANS, sleeves = "long", cuff = TURTLE, shoes = WHITE, sole = H("d8d8e0") })
	k:rbox("UpperTorso", V(1.0, 0.36, 0.92), V(0, SH + 0.08, 0.04), TURTLE, 0.14) -- turtleneck
	k:belt(H("3a2a1e"), H("c8ccd6"))
	k:hairStyle("short", H("8a8a94"))
	k:glasses("round", H("2a2a2a"))
	local h = k:hand(1) -- tablet
	k:rbox("LeftUpperArm", V(0.72, 0.95, 0.06), V(h.X, h.Y + 0.35, -0.48), H("2a2a34"), 0.06, V(-10, 0, -8))
	k:rbox("LeftUpperArm", V(0.6, 0.82, 0.03), V(h.X, h.Y + 0.35, -0.52), H("4fb6ff"), 0.04, V(-10, 0, -8))
	local x = -AX - 0.42 -- robot vacuum under the arm
	k:cyl("RightUpperArm", V(0.22, 1.1, 1.1), V(x, 2.6, 0), H("3a3a46"))
	k:cyl("RightUpperArm", V(0.24, 0.3, 0.3), V(x, 2.6, -0.2), H("5ae84a"))
end

Cast.MovieStarMaya = function(k)
	local GOWN, GOWN_D, FUR = H("d81e3a"), H("a8142a"), H("fbf6ee")
	k:body({ skin = S5, shirt = GOWN, pants = GOWN, sleeves = "none", legs = "skirt", skirtLen = 1.72, flare = 0.36,
		shoes = GOLD, sole = GOLD_D })
	k:rbox("UpperTorso", V(0.14, 1.5, 0.04), V(0.3, 1.0, -(D.torsoD + 0.14 + 0.36) / 2 - 0.02), GOWN_D, 0.03) -- slit fold
	k:fuse("UpperTorso", FUR, { -- fur stole round the shoulders
		{ "ball", V(0.5, 0.5, 0.5), V(-0.7, SH + 0.02, -0.15) }, { "ball", V(0.5, 0.5, 0.5), V(-0.35, SH + 0.06, -0.38) },
		{ "ball", V(0.5, 0.5, 0.5), V(0.35, SH + 0.06, -0.38) }, { "ball", V(0.5, 0.5, 0.5), V(0.7, SH + 0.02, -0.15) },
		{ "ball", V(0.5, 0.5, 0.5), V(-0.6, SH + 0.05, 0.3) }, { "ball", V(0.5, 0.5, 0.5), V(0.6, SH + 0.05, 0.3) },
		{ "ball", V(0.5, 0.5, 0.5), V(0, SH + 0.05, 0.45) },
	})
	k:hairStyle("long", H("2a1810"))
	k:rbox("HeadDetail", V(1.2, 0.26, 0.08), V(0, HT - 0.02, -0.55), BLACK, 0.1, V(-35, 0, 0)) -- sunglasses up on her head
	local h = k:hand(-1) -- golden star trophy
	k:rbox("RightUpperArm", V(0.4, 0.2, 0.4), V(h.X, h.Y + 0.05, -0.5), BLACK, 0.06)
	k:rbox("RightUpperArm", V(0.12, 0.5, 0.12), V(h.X, h.Y + 0.4, -0.5), GOLD, 0.05)
	k:fuse("RightUpperArm", GOLD, {
		{ "block", V(0.5, 0.14, 0.1), V(h.X, h.Y + 0.85, -0.5), V(0, 0, 0) },
		{ "block", V(0.5, 0.14, 0.1), V(h.X, h.Y + 0.85, -0.5), V(0, 0, 72) },
		{ "block", V(0.5, 0.14, 0.1), V(h.X, h.Y + 0.85, -0.5), V(0, 0, 144) },
	})
end

Cast.KingReginald = function(k)
	local ROBE, ROBE_D, ERMINE = H("c8203a"), H("9a1428"), H("fbf6ee")
	k:body({ skin = S2, shirt = ROBE, pants = H("e8c050"), sleeves = "long", cuff = ERMINE, shoes = H("6a2a8a"), torsoD = 1.06 })
	k:coatSkirt(ROBE, 1.45, true, 0.14)
	k:rbox("UpperTorso", V(0.5, 1.8, 0.04), V(0, HIP + 0.6, k:frontZ(0.01)), H("e8c050"), 0.03) -- gold tunic front
	k:rbox("UpperTorso", V(D.torsoW + 0.34, 0.4, D.torsoD + 0.3), V(0, SH - 0.05, 0.02), ERMINE, 0.16) -- ermine collar
	for _, p in { { -0.6, -0.5 }, { -0.2, -0.56 }, { 0.2, -0.56 }, { 0.6, -0.5 }, { -0.85, 0.1 }, { 0.85, 0.1 } } do
		k:rbox("UpperTorso", V(0.07, 0.16, 0.05), V(p[1], SH - 0.05, p[2] - 0.12), BLACK, 0.02)
	end
	k:beard(WHITE, 0.4, false)
	k:hairStyle("tufts", WHITE)
	k:crown(GOLD, H("e8182e"), 5)
	local h = k:hand(-1) -- sceptre
	k:rbox("RightUpperArm", V(0.12, 1.6, 0.12), V(h.X, h.Y + 0.55, -0.48), GOLD, 0.05)
	k:ball("RightUpperArm", 0.32, V(h.X, h.Y + 1.42, -0.48), H("e8182e"))
	k:rbox("RightUpperArm", V(0.36, 0.1, 0.1), V(h.X, h.Y + 1.2, -0.48), GOLD, 0.04)
end

Cast.AstronautAce = function(k)
	local SUIT, PATCH, PACK = H("f2f2f4"), H("ff7a1a"), H("c8ccd6")
	k:body({ skin = S5, shirt = SUIT, pants = SUIT, sleeves = "long", cuff = PATCH, shoes = H("8a929e"), sole = H("5a606e"), hands = H("c8ccd6"), torsoD = 1.04 })
	boots(k, H("c8ccd6"), 0.5, PATCH)
	k:rbox("UpperTorso", V(1.4, 1.7, 0.6), V(0, HIP + 0.95, 0.8), PACK, 0.18) -- life support pack
	k:rbox("UpperTorso", V(0.7, 0.5, 0.06), V(0, HIP + 0.5, k:frontZ(0.02)), H("8a929e"), 0.08) -- chest control unit
	for i, c in { H("e04040"), H("4fb6ff"), H("5ae84a") } do
		k:ball("UpperTorso", 0.1, V(-0.2 + (i - 1) * 0.2, HIP + 0.52, k:frontZ(0.06)), c)
	end
	k:rbox("UpperTorso", V(0.5, 0.36, 0.05), V(-0.45, SH - 0.55, k:frontZ(0.02)), H("1f2f5c"), 0.08)
	k:rbox("UpperTorso", V(0.36, 0.08, 0.04), V(-0.45, SH - 0.55, k:frontZ(0.05)), WHITE, 0.02)
	armBand(k, 3.15, 0.12, PATCH)
	k:hairStyle("short", H("1a1410"))
	k:rbox("HeadDetail", V(1.7, 0.24, 1.6), V(0, SH + 0.1, 0.02), H("c8ccd6"), 0.1) -- helmet ring
	local glass = k:ball("HeadDetail", 2.15, V(0, HY + 0.05, 0.02), H("dff4ff"))
	glass.Transparency = 0.72
	local h = k:hand(-1) -- flag
	k:rbox("RightUpperArm", V(0.07, 1.6, 0.07), V(h.X, h.Y + 0.6, -0.48), H("c8ccd6"), 0.03)
	k:rbox("RightUpperArm", V(0.7, 0.46, 0.03), V(h.X + 0.36, h.Y + 1.15, -0.48), H("4fb6ff"), 0.02)
	k:ell("RightUpperArm", V(0.2, 0.2, 0.04), V(h.X + 0.36, h.Y + 1.15, -0.51), WHITE)
end

return Cast
