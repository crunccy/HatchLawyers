-- The client cast in the brick style (2026-10-11, docs/CHARACTER_STYLE.md): one builder per client on BrickKit.
-- Each keeps its v3 design (tools/clients/Cast.lua: outfit, colours, props, personality) on the chibi frame, with a
-- brick face instead of the drawn decal. Tier ladder (light touch so the designs stay theirs): T3 a Rare-blue detail
-- or a standout feature, T4 an Epic-purple detail, T5 gold trim + a small Neon bit. Neighbor Dave has his own file.
-- Rig rule (Shared.Puppet): nothing in an arm may top the sleeve - props are held below the shoulder, big carried
-- things (the tuba, pizza boxes, the parrot) are torso parts. tools/brick/Run.lua checks it.
-- Run: tools/brick/Run.lua with _G.BrickRun = { file = this, kind = "client", ids = {...} }.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local HIP, SH, HY, HT, FZ = Kit.hipY, Kit.shoulderY, Kit.headY, Kit.headTop, Kit.faceZ
local AX, LX = Kit.armX, Kit.legX
local WHITE, INK, GOLD, GOLD_D = Kit.C.White, Kit.C.Ink, Kit.C.Gold, Kit.C.GoldDark
local RARE, EPIC = Kit.C.Rare, Kit.C.Epic
local BLACK = H("1e1e24")
local S1, S2, S3, S4, S5, S6 = H("f6d2b0"), H("f1c49a"), H("e0a87a"), H("c98b5f"), H("a86a42"), H("7a4a2c")
local leg, arm = Kit.legName, Kit.armName
local CUFF_LONG = SH - (D.armH - D.handH) + 0.07 -- where a long sleeve ends
local CUFF_SHORT = SH - 0.5 + 0.06

local function cuffs(k, y, color)
	for _, s in { -1, 1 } do
		k:plate(arm(s), V(D.armW + 0.1, 0.12, D.armD + 0.1), V(s * AX, y, 0), color)
	end
end
-- square patches on the torso front: { x, y, size, colour }
local function spots(k, list)
	local fz = k:frontZ()
	for _, p in list do
		k:plate("UpperTorso", V(p[3], p[3], 0.04), V(p[1], p[2], fz - 0.03), p[4])
	end
end
-- the whole face in one call: o.eyes / o.brows / o.mouth (style) / o.m (mouth options)
local function face(k, browColor, o)
	local opt = o or {}
	k:eyes(opt.eyes or {})
	k:brows(browColor, opt.brows or {})
	k:nose(nil, opt.nose)
	k:mouth(opt.mouth or "smile", opt.m or {})
end
-- a flat octagon (the STOP sign) cut at build time
local function octagon(k, name, w, t, pos, color)
	local base = Instance.new("Part")
	base.Size = V(w, w, t)
	base.CFrame = CFrame.new(k.origin + pos)
	base.Anchored = true
	base.Parent = workspace
	local cuts = {}
	for _, q in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		local c = Instance.new("Part")
		c.Size = V(w * 0.414, w * 0.414, t + 0.2)
		c.CFrame = base.CFrame * CFrame.new(q[1] * w / 2, q[2] * w / 2, 0) * CFrame.Angles(0, 0, math.rad(45))
		c.Anchored = true
		c.Parent = workspace
		table.insert(cuts, c)
	end
	local u = base:SubtractAsync(cuts)
	base:Destroy()
	for _, c in cuts do
		c:Destroy()
	end
	u.Name = name
	u.UsePartColor = true
	u.Color = color
	u.Material = Enum.Material.Plastic
	u.Anchored, u.CanCollide, u.CanTouch, u.CanQuery = true, false, false, false
	u.Parent = k.model
	k.count += 1
	return u
end

local C = {}

------------------------------------------------------------------ TIER 1
C.GrandmaPearl = function(k)
	local LAV, LAV_D, BLOUSE, SKIRT, HAIR = H("b49ae0"), H("8f74c2"), H("fbf6ee"), H("e07aa8"), H("e4e4ec")
	k:body({ skin = S1, shirt = LAV, pants = SKIRT, legs = "skirt", skirtLen = 0.9, tights = H("e8c4a8"), shoes = LAV_D, sole = H("5e4a80") })
	local fz = k:frontZ()
	k:lapels(LAV, BLOUSE, { depth = 0.75, lapel = LAV_D })
	k:buttons(3, H("fbe7ff"), 0, SH - 0.88, 0.26)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.44, 0.32, 0.05), V(s * 0.6, HIP + 0.35, fz - 0.03), LAV_D)
	end
	for i = -4, 4 do -- pearl necklace
		local t = i / 4
		k:plate("UpperTorso", V(0.12, 0.12, 0.05), V(t * 0.34, SH - 0.1 - (1 - t * t) * 0.3, fz - 0.08), WHITE)
	end
	k:hair("bun", HAIR, { fringe = 0 })
	for _, s in { -1, 1 } do
		for _, y in { 0.28, -0.05 } do
			k:brick("HeadDetail", V(0.24, 0.34, 0.44), V(s * (D.headW / 2 + 0.12), HY + y, 0.15), HAIR)
		end
	end
	face(k, H("c8c8d0"), { eyes = { look = Vector2.new(0, 0.25) }, brows = { tilt = -8, raise = 0.04 } })
	k:glasses(H("d4a640"))
	k:blush()
	k:held(-1, V(0.13, 1.72, 0.13), V(0, -0.66, -0.42), H("7a4a24")) -- cane with a crook
	k:held(-1, V(0.44, 0.13, 0.13), V(-0.16, 0.26, -0.42), H("7a4a24"))
	k:held(-1, V(0.13, 0.22, 0.13), V(-0.34, 0.16, -0.42), H("7a4a24"))
end

C.SkaterKev = function(k)
	local HOOD, HOOD_D, SHORTS, CAP, CAP_D, HAIR = H("ff8a2a"), H("d96a14"), H("4a5a7a"), H("3a6ad0"), H("2a4fa0"), H("4a2a14")
	k:body({ skin = S3, shirt = HOOD, pants = SHORTS, legs = "shorts", socks = WHITE, sockH = 0.36, shoes = H("2b2b33"), sole = H("ff4f4f") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, HOOD_D)
	k:brick("UpperTorso", V(1.4, 0.5, 0.35), V(0, SH + 0.05, 0.72), HOOD_D) -- hood down the back
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.06, 0.45, 0.04), V(s * 0.2, SH - 0.28, fz - 0.03), WHITE)
	end
	k:plate("UpperTorso", V(1.1, 0.42, 0.05), V(0, HIP + 0.3, fz - 0.03), HOOD_D)
	k:plate("UpperTorso", V(0.5, 0.36, 0.04), V(0, SH - 0.78, fz - 0.03), H("2b2b33"))
	k:plate("UpperTorso", V(0.24, 0.18, 0.03), V(0, SH - 0.78, fz - 0.06), H("ffe14a"))
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:cap(CAP, CAP_D, { backwards = true, down = 0.34 })
	face(k, HAIR, { eyes = { y = -0.02, lid = 0.18, look = Vector2.new(0.35, 0) }, brows = { y = -0.02, tilt = -4 }, m = { w = 0.5 } })
	local x = AX + D.armW / 2 + 0.1 -- skateboard under his left arm
	k:brick("LeftUpperArm", V(0.1, 1.6, 0.62), V(x, 1.95, 0), H("2b2b33"))
	k:plate("LeftUpperArm", V(0.03, 1.4, 0.5), V(x + 0.06, 1.95, 0), H("ff4f9a"))
	k:plate("LeftUpperArm", V(0.03, 0.36, 0.36), V(x + 0.08, 1.95, 0), H("ffe14a"))
	for _, y in { 1.35, 2.55 } do
		for _, z in { -0.2, 0.2 } do
			k:brick("LeftUpperArm", V(0.16, 0.18, 0.18), V(x - 0.13, y, z), H("f2f2f2"))
		end
	end
end

C.MailCarrierMo = function(k)
	local SHIRT, SHIRT_D, NAVY, BAG, BAG_D, HAIR = H("8fb8e8"), H("6a94c8"), H("26345e"), H("8a5a2e"), H("6b4426"), H("1e1410")
	k:body({ skin = S5, shirt = SHIRT, pants = NAVY, sleeves = "short", legs = "shorts", socks = NAVY, sockH = 0.3, shoes = H("1c1c22") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, SHIRT_D)
	k:collar(SHIRT_D)
	k:buttons(3, WHITE, 0, SH - 0.3, 0.3)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.42, 0.36, 0.05), V(s * 0.58, SH - 0.62, fz - 0.03), SHIRT_D)
	end
	k:plate("LeftUpperArm", V(0.05, 0.3, 0.32), V(AX + D.armW / 2 + 0.03, SH - 0.28, 0), H("e04040")) -- patch
	k:plate("UpperTorso", V(0.16, 2.0, 0.05), V(0, HIP + 0.75, fz - 0.08), BAG_D, V(0, 0, -36)) -- satchel strap
	k:brick("UpperTorso", V(0.9, 0.72, 0.42), V(-0.8, HIP + 0.05, -0.5), BAG)
	k:brick("UpperTorso", V(0.94, 0.36, 0.46), V(-0.8, HIP + 0.27, -0.51), BAG_D)
	k:plate("UpperTorso", V(0.16, 0.14, 0.05), V(-0.8, HIP + 0.12, -0.75), GOLD)
	k:hair("short", HAIR, { hat = true, noTop = true })
	local top = k:cap(NAVY, H("1c2848"), { down = 0.34 })
	k:plate("HeadDetail", V(0.42, 0.24, 0.05), V(0, top - 0.32, -(D.headD + 0.16) / 2 - 0.03), H("e8c050"))
	face(k, HAIR, { eyes = { y = -0.02 }, brows = { y = -0.02, tilt = -12 }, mouth = "flat", m = { w = 0.36 } })
	k:plate("HeadDetail", V(0.14, 0.24, 0.04), V(0.82, HY + 0.3, FZ - 0.03), H("7cc8f0")) -- sweat (that dog...)
	k:held(1, V(0.62, 0.44, 0.05), V(0, 0.24, -0.46), H("fffaf0"), V(0, 0, -10), true) -- a letter
	k:held(1, V(0.14, 0.16, 0.03), V(0.17, 0.36, -0.5), H("e04040"), V(0, 0, -10), true)
	k:brick("RightUpperLeg", V(D.legW - 0.06, 0.16, D.legD - 0.06), V(-LX, 0.74, 0), H("f6efe2")) -- bandage
end

C.LemonadeLily = function(k)
	local DRESS, LEAF, HAIR = H("ffd83a"), H("6cc53a"), H("e8742a")
	k:body({ skin = S1, shirt = DRESS, pants = DRESS, sleeves = "none", legs = "skirt", skirtLen = 0.7, flare = 0.34, tights = S1, shoes = WHITE, sole = H("ffb0c8") })
	local fz = k:frontZ()
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.5, 0.12, 0.4), V(s * 0.24, SH - 0.04, fz - 0.12), WHITE, V(0, 0, s * -10)) -- round collar
	end
	for _, p in { Vector2.new(-0.5, SH - 0.5), Vector2.new(0.5, SH - 0.85), Vector2.new(0.05, HIP + 0.35) } do -- lemon prints
		k:plate("UpperTorso", V(0.24, 0.2, 0.04), V(p.X, p.Y, fz - 0.03), H("fff3b0"))
		k:plate("UpperTorso", V(0.1, 0.08, 0.03), V(p.X + 0.12, p.Y + 0.11, fz - 0.05), LEAF)
	end
	k:torsoBand(HIP + 0.1, 0.14, H("ff8ab8")) -- sash
	k:hair("pigtails", HAIR, { band = H("ff5a8a") })
	face(k, H("c85a1a"), { eyes = { look = Vector2.new(0, 0.3) }, brows = { tilt = -6 }, mouth = "grin", m = { w = 0.5, h = 0.22 } })
	k:blush()
	for _, s in { -1, 1 } do -- freckles
		for i = 0, 2 do
			k:plate("HeadDetail", V(0.05, 0.05, 0.02), V(s * (0.5 + i * 0.12), HY - 0.24 - (i % 2) * 0.06, FZ - 0.03), H("c8784a"))
		end
	end
	local glass = k:held(-1, V(0.5, 0.62, 0.5), V(0, 0.2, -0.5), H("fffbe0"), nil, true) -- pitcher of lemonade
	glass.Transparency = 0.35
	k:held(-1, V(0.42, 0.46, 0.42), V(0, 0.12, -0.5), H("ffe14a"))
	k:held(-1, V(0.1, 0.4, 0.1), V(-0.3, 0.22, -0.5), H("fffbe0"), nil, true)
	k:held(-1, V(0.22, 0.22, 0.06), V(0.15, 0.55, -0.62), H("ffd21f"), nil, true)
end

C.GamerGabe = function(k)
	local HOOD, NEON, JOG, PAD, HAIR = H("23232e"), H("5cf05a"), H("6a6a78"), H("3a3a46"), H("1a1a1a")
	k:body({ skin = S4, shirt = HOOD, pants = JOG, shoes = H("f2f2f2"), sole = NEON })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, NEON)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.1, D.torsoH - 0.1, 0.04), V(s * 0.66, HIP + 0.72, fz - 0.03), NEON)
		k:plate(leg(s), V(0.05, 0.9, 0.12), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), NEON)
	end
	k:brick("UpperTorso", V(1.4, 0.5, 0.35), V(0, SH + 0.05, 0.72), PAD) -- hood
	k:plate("UpperTorso", V(1.05, 0.42, 0.05), V(0, HIP + 0.3, fz - 0.03), PAD)
	k:plate("UpperTorso", V(0.44, 0.44, 0.04), V(0, SH - 0.72, fz - 0.03), NEON, V(0, 0, 45))
	k:plate("UpperTorso", V(0.24, 0.24, 0.03), V(0, SH - 0.72, fz - 0.06), HOOD, V(0, 0, 45))
	k:hair("messy", HAIR)
	local hw = D.headW / 2 -- gaming headset
	k:brick("HeadDetail", V(D.headW + 0.3, 0.14, 0.36), V(0, HT + 0.28, 0.05), PAD)
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.14, 0.6, 0.32), V(s * (hw + 0.16), HT - 0.05, 0.05), PAD)
		k:brick("HeadDetail", V(0.26, 0.62, 0.62), V(s * (hw + 0.14), HY, 0.05), BLACK)
		k:plate("HeadDetail", V(0.04, 0.4, 0.4), V(s * (hw + 0.28), HY, 0.05), NEON)
	end
	k:plate("HeadDetail", V(0.06, 0.06, 0.6), V(-(hw + 0.06), HY - 0.38, -0.5), PAD, V(0, -25, 0))
	k:brick("HeadDetail", V(0.14, 0.14, 0.14), V(-0.6, HY - 0.42, FZ - 0.1), NEON)
	face(k, HAIR, { eyes = { lid = 0.3, look = Vector2.new(0, -0.3) }, brows = { tilt = 6 }, mouth = "flat", m = { w = 0.36 } })
	k:held(-1, V(0.7, 0.24, 0.4), V(0, 0.16, -0.5), H("4a4a58")) -- controller
	for _, dx in { -0.3, 0.3 } do
		k:held(-1, V(0.26, 0.32, 0.34), V(dx, 0.08, -0.5), H("4a4a58"))
	end
	for i, c in { H("ff4f4f"), H("4fb6ff"), NEON } do
		k:held(-1, V(0.08, 0.05, 0.08), V(0.1 + i * 0.07, 0.3, -0.55), c, nil, true)
	end
end

C.GardenerGus = function(k)
	local SHIRT, OVER, OVER_D, HAT, HAT_D = H("d9483a"), H("4f9a4a"), H("3a7a36"), H("4a8a5a"), H("2f6a3a")
	k:body({ skin = S3, shirt = SHIRT, pants = OVER, shoes = H("3a7a36"), sole = H("2a5a26"), hands = H("f0c850") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, H("b8382c"))
	k:plate("UpperTorso", V(1.2, 0.9, 0.05), V(0, HIP + 0.45, fz - 0.03), OVER) -- overall bib
	k:plate("UpperTorso", V(0.5, 0.34, 0.04), V(0, HIP + 0.5, fz - 0.06), OVER_D)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.2, 0.7, 0.05), V(s * 0.45, SH - 0.35, fz - 0.03), OVER)
		k:plate("UpperTorso", V(0.14, 0.14, 0.04), V(s * 0.45, HIP + 0.9, fz - 0.07), GOLD)
	end
	for _, y in { 2.1, 2.45 } do
		k:armBand(y, 0.06, H("8a2a22")) -- plaid lines
	end
	k:boots(H("3a7a36"), 0.4, H("2a5a26"))
	k:hair("tufts", H("eeeeee"))
	k:brimHat(HAT, { band = HAT_D, brimW = D.headW + 1.2, crownH = 0.55 })
	k:mustache(H("eeeeee"), "droopy")
	face(k, H("dddddd"), { eyes = { y = -0.05, lid = 0.2 }, brows = { y = -0.05, tilt = -6 }, m = { y = -0.64, w = 0.4 } })
	k:held(-1, V(0.6, 0.55, 0.5), V(0, -0.3, -0.55), H("5ab0e0")) -- watering can
	k:held(-1, V(0.1, 0.1, 0.7), V(0, -0.15, -1.05), H("5ab0e0"), V(-30, 0, 0))
	k:held(-1, V(0.22, 0.22, 0.08), V(0, 0.05, -1.36), H("3a8ac0"))
	k:held(-1, V(0.08, 0.4, 0.4), V(0, 0.1, -0.55), H("3a8ac0"), nil, true)
end

C.IceCreamIvy = function(k)
	local PINK, MINT, HAIR = H("ff8ab8"), H("8fe8c8"), H("2a1810")
	k:body({ skin = S6, shirt = WHITE, pants = H("4a5a8a"), sleeves = "short", shoes = PINK, sole = WHITE })
	cuffs(k, CUFF_SHORT, PINK)
	for i = 0, 2 do
		k:torsoBand(HIP + 0.35 + i * 0.4, 0.14, PINK)
	end
	k:apron(WHITE, { length = 0.6, pocket = PINK })
	k:hair("bob", HAIR)
	k:brick("HeadDetail", V(0.8, 0.36, D.headD + 0.04), V(0, HT + 0.32, 0), WHITE) -- paper cap
	k:plate("HeadDetail", V(0.84, 0.08, D.headD + 0.08), V(0, HT + 0.16, 0), PINK)
	face(k, HAIR, { eyes = { look = Vector2.new(0, 0.3) }, brows = { tilt = -6 }, mouth = "grin", m = { w = 0.52 } })
	k:blush()
	k:held(-1, V(0.32, 0.5, 0.32), V(0, 0.1, -0.5), H("e0a458")) -- the cone
	k:held(-1, V(0.42, 0.36, 0.42), V(0, 0.52, -0.5), PINK)
	k:held(-1, V(0.38, 0.32, 0.38), V(0, 0.84, -0.5), MINT)
	k:held(-1, V(0.13, 0.13, 0.13), V(0, 1.06, -0.5), H("e8182e"))
end

C.BarberBob = function(k)
	local RED, HAIR = H("e03a3a"), H("1c1c1c")
	k:body({ skin = S2, shirt = WHITE, pants = BLACK, shoes = BLACK, sole = H("3a3a44") })
	local fz = k:frontZ()
	k:vest(RED, { gap = 0.5 })
	for _, x in { -0.75, -0.5, 0.5, 0.75 } do
		k:plate("UpperTorso", V(0.07, D.torsoH - 0.2, 0.03), V(x, HIP + 0.7, fz - 0.07), WHITE) -- barber-pole stripes
	end
	k:bowtie(BLACK)
	k:buttons(3, GOLD, 0, SH - 0.5, 0.3)
	k:badge(WHITE, -0.62, SH - 0.62, Vector2.new(0.36, 0.3)) -- pocket + comb
	k:plate("UpperTorso", V(0.08, 0.36, 0.04), V(-0.68, SH - 0.48, fz - 0.09), BLACK)
	k:hair("side", HAIR, { side = 1 })
	k:mustache(HAIR, "curly", { w = 0.6 })
	face(k, HAIR, { eyes = { lid = 0.15 }, brows = { tilt = 4 }, m = { y = -0.62, w = 0.4 } })
	for _, a in { -18, 18 } do -- scissors
		k:held(-1, V(0.06, 0.6, 0.04), V(0, 0.42, -0.48), H("c8ccd6"), V(0, 0, a), true)
	end
	for _, s in { -1, 1 } do
		k:held(-1, V(0.2, 0.2, 0.05), V(s * 0.12, 0.04, -0.48), BLACK, nil, true)
	end
end

C.CrossingGuardCarol = function(k)
	local VEST, REFL, NAVY, HAIR = H("ff7a1a"), H("e8ff4a"), H("26345e"), H("2a1810")
	k:body({ skin = S5, shirt = WHITE, pants = NAVY, shoes = BLACK, hands = WHITE })
	local fz = k:frontZ()
	k:brick("UpperTorso", V(D.torsoW + 0.06, D.torsoH - 0.1, D.torsoD + 0.06), V(0, HIP + (D.torsoH - 0.1) / 2, 0), VEST) -- safety vest
	k:plate("UpperTorso", V(0.5, 0.4, 0.04), V(0, SH - 0.22, fz - 0.07), WHITE)
	for _, y in { HIP + 0.3, HIP + 0.7 } do
		k:plate("UpperTorso", V(D.torsoW + 0.1, 0.12, D.torsoD + 0.1), V(0, y, 0), REFL)
	end
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.12, 0.9, 0.04), V(s * 0.45, SH - 0.5, fz - 0.07), REFL)
	end
	k:plate("UpperTorso", V(0.16, 0.2, 0.08), V(0.4, SH - 0.32, fz - 0.12), H("ffd21f")) -- whistle
	k:hair("ponytail", HAIR, { band = VEST, hat = true, noTop = true })
	k:cap(NAVY, H("1c2848"), { down = 0.34 })
	face(k, HAIR, { eyes = { y = -0.02 }, brows = { y = -0.02, tilt = 10 }, mouth = "flat", m = { w = 0.4 } })
	-- the STOP paddle: a pole + an octagon sign at shoulder height (below the shoulder, for Puppet)
	k:held(-1, V(0.1, 1.3, 0.1), V(0, 0.08, -0.45), H("c8ccd6"))
	local at = k:hand(-1) + V(0, 0.72, -0.45)
	octagon(k, "RightUpperArm", 0.92, 0.06, at + V(0, 0, 0.02), WHITE)
	local sign = octagon(k, "RightUpperArm", 0.84, 0.07, at - V(0, 0, 0.02), H("e02a2a"))
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

C.LibrarianLou = function(k)
	local CARD, CARD_D, SHIRT, TIE = H("c8963c"), H("a8782a"), H("f4eedc"), H("6a2a3a")
	k:body({ skin = S4, shirt = CARD, pants = H("6b4a2e"), shoes = H("5a3418") })
	cuffs(k, CUFF_LONG, CARD_D)
	k:lapels(CARD, SHIRT, { depth = 0.9, lapel = CARD_D })
	k:tie(TIE, 0.6)
	k:buttons(2, H("6b4a2e"), 0, HIP + 0.35, 0.28)
	k:badge(CARD_D, 0.6, HIP + 0.35, Vector2.new(0.4, 0.32))
	for _, s in { -1, 1 } do
		k:plate(arm(s), V(0.05, 0.36, 0.34), V(s * (AX + D.armW / 2 + 0.03), SH - 0.7, 0.05), H("8a6a3a")) -- elbow patches
	end
	k:hair("tufts", H("dcdcdc"))
	face(k, H("bbbbbb"), { eyes = { lid = 0.3, look = Vector2.new(0, -0.2) }, brows = { tilt = 6, raise = 0.06 }, mouth = "flat", m = { w = 0.26 } })
	k:glasses(H("2a2a2a"))
	for i, c in { H("3a6ad0"), H("d94a3a"), H("4f9a4a") } do -- a stack of books
		k:held(1, V(0.7, 0.18, 0.5), V(0.05, 0.05 + i * 0.19, -0.48), c, V(0, (i - 2) * 8, 0))
		k:held(1, V(0.64, 0.14, 0.46), V(0.08, 0.05 + i * 0.19, -0.5), H("fbf4e0"), V(0, (i - 2) * 8, 0), true)
	end
end

C.CamperCam = function(k)
	local FLANNEL, FLAN_D, KHAKI, PACK, PACK_D, HAIR = H("d9483a"), H("8a2a22"), H("c9a66b"), H("4a8a4a"), H("3a7a3a"), H("7a4422")
	k:body({ skin = S2, shirt = FLANNEL, pants = KHAKI, sleeves = "short", legs = "shorts", socks = H("8a8a94"), sockH = 0.3, shoes = H("6b4426"), sole = H("3a2a1e") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, FLAN_D)
	for _, x in { -0.45, 0.45 } do
		k:plate("UpperTorso", V(0.06, D.torsoH - 0.05, 0.03), V(x, HIP + 0.73, fz - 0.02), FLAN_D)
	end
	for _, y in { HIP + 0.5, HIP + 1.05 } do
		k:torsoBand(y, 0.06, FLAN_D)
	end
	k:collar(FLAN_D)
	k:brick("UpperTorso", V(1.5, 1.4, 0.6), V(0, HIP + 0.75, 0.86), PACK) -- backpack
	k:brick("UpperTorso", V(1.0, 0.5, 0.2), V(0, HIP + 0.4, 1.24), PACK_D)
	k:brick("UpperTorso", V(1.7, 0.42, 0.42), V(0, SH + 0.0, 0.9), H("ff8a2a")) -- bedroll
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.16, 1.3, 0.05), V(s * 0.55, SH - 0.6, fz - 0.05), H("2a5a2a"))
	end
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:beanie(H("2f7a4a"), H("245e3a"), WHITE)
	face(k, HAIR, { eyes = { y = -0.04, look = Vector2.new(0, 0.2) }, brows = { y = -0.06, tilt = -6 }, mouth = "grin", m = { w = 0.5 } })
	k:held(-1, V(0.06, 1.0, 0.06), V(-0.1, 0.45, -0.5), H("8a5a2e"), V(0, 0, 15), true) -- marshmallow on a stick
	k:held(-1, V(0.22, 0.26, 0.22), V(-0.25, 0.95, -0.5), H("fff8ee"))
end

C.YogaYasmin = function(k)
	local TANK, LEGGING, MAT, HAIR = H("2fc0b0"), H("7a4ad0"), H("ff7ab8"), H("1a1410")
	k:body({ skin = S4, shirt = TANK, pants = LEGGING, sleeves = "none", shoes = WHITE, sole = H("d8d8e0") })
	k:torsoBand(HIP + 0.06, 0.18, H("5a2ab0"))
	for _, s in { -1, 1 } do
		k:plate(leg(s), V(0.05, 0.9, 0.1), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), H("b89aff"))
	end
	k:hair("bun", HAIR)
	k:headband(MAT, 0.2)
	face(k, HAIR, { eyes = { lid = 0.5 }, brows = { tilt = -4 }, m = { w = 0.4 } })
	local x = AX + D.armW / 2 + 0.24 -- rolled yoga mat under her left arm
	k:brick("LeftUpperArm", V(0.44, 0.44, 1.5), V(x, 2.2, 0), MAT)
	k:plate("LeftUpperArm", V(0.3, 0.3, 0.04), V(x, 2.2, -0.77), H("ffb8d8"))
	k:plate("LeftUpperArm", V(0.06, 0.5, 0.06), V(x - 0.14, 2.42, 0), H("5a2ab0"))
end

------------------------------------------------------------------ TIER 2
C.RosaTheBaker = function(k)
	local SCARF, APRON, HAIR = H("d94a5a"), H("fbe6d6"), H("2a1810")
	k:body({ skin = H("c68a5e"), shirt = WHITE, pants = H("3a3a44"), sleeves = "short", shoes = BLACK })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, H("e8e8ec"))
	for _, x in { -0.32, 0.32 } do
		k:buttons(3, H("c8ccd6"), x, SH - 0.32, 0.3) -- double-breasted
	end
	k:plate("UpperTorso", V(0.7, 0.28, 0.06), V(0, SH - 0.14, fz - 0.05), SCARF) -- neckerchief
	k:apron(APRON, { length = 0.75, pocket = SCARF })
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:brick("HeadDetail", V(D.headW + 0.3, 0.6, D.headD + 0.3), V(0, HT - 0.02, 0), SCARF) -- headscarf (wider than the hair)
	k:brick("HeadDetail", V(0.4, 0.34, 0.3), V(0, HT - 0.15, D.headD / 2 + 0.2), SCARF) -- its knot
	for _, p in { V(-0.45, 0.12, 0), V(0.3, 0.2, 0), V(0.65, 0.05, 0) } do
		k:plate("HeadDetail", V(0.14, 0.12, 0.03), V(p.X, HT - 0.12 + p.Y, -(D.headD + 0.3) / 2 - 0.02), WHITE)
	end
	face(k, HAIR, { eyes = { y = -0.04 }, brows = { y = -0.04, tilt = 8 }, m = { w = 0.42 } })
	k:plate("HeadDetail", V(0.3, 0.16, 0.03), V(-0.62, HY - 0.36, FZ - 0.02), WHITE) -- flour smudge
	k:held(-1, V(0.32, 0.32, 1.0), V(0, 0.1, -0.5), H("e0b07a")) -- rolling pin
	for _, dz in { -0.62, 0.62 } do
		k:held(-1, V(0.16, 0.16, 0.3), V(0, 0.1, -0.5 + dz), H("b8864e"))
	end
end

C.CaptainBarnacle = function(k)
	local COAT, BEARD = H("1f2f5c"), H("f2f2f2")
	k:body({ skin = S3, shirt = COAT, pants = H("3a3a4a"), shoes = BLACK })
	cuffs(k, CUFF_LONG, GOLD)
	k:coat(COAT, 0.75, { open = true, gap = 0.2 })
	for _, x in { -0.32, 0.32 } do
		k:buttons(4, GOLD, x, SH - 0.4, 0.3)
	end
	k:brick("UpperTorso", V(1.2, 0.26, 1.0), V(0, SH + 0.02, 0.02), WHITE) -- turtleneck
	k:hair("short", BEARD, { hat = true, noTop = true })
	k:beard(BEARD, { length = 0.45, wide = true })
	k:brick("HeadDetail", V(D.headW + 0.3, 0.45, D.headD + 0.3), V(0, HT + 0.12, 0.02), WHITE) -- captain's hat
	k:brick("HeadDetail", V(D.headW + 0.12, 0.18, D.headD + 0.12), V(0, HT - 0.18, 0.02), BLACK)
	k:brick("HeadDetail", V(1.5, 0.1, 0.6), V(0, HT - 0.26, FZ - 0.3), BLACK, V(-12, 0, 0))
	k:plate("HeadDetail", V(0.36, 0.3, 0.05), V(0, HT + 0.08, -(D.headD + 0.3) / 2 - 0.03), GOLD)
	face(k, BEARD, { eyes = { y = -0.04, lid = 0.25 }, brows = { y = -0.04, tilt = -4 }, mouth = "flat", m = { y = -0.5, w = 0.36 } })
	-- fishing rod pointing out ahead, low (the rod lies along its Z axis: Puppet reads Size.Y without rotation)
	local hand = k:hand(-1)
	local tip = hand + V(-0.3, 0.95, -2.0)
	k:plate("RightUpperArm", V(0.07, 0.07, (tip - hand).Magnitude), CFrame.lookAt((hand + tip) / 2, tip), H("6b4426"))
	k:held(-1, V(0.26, 0.26, 0.14), V(0.05, 0.05, -0.42), H("c8ccd6")) -- reel
end

C.DrFizz = function(k)
	local SHIRT, TIE, GOG = H("7ad04a"), H("7a3ad0"), H("3a3a44")
	k:body({ skin = S1, shirt = WHITE, pants = H("4a4a5a"), shoes = H("3a3a3a") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, H("e8e8ec"))
	k:lapels(WHITE, SHIRT, { depth = 0.95, lapel = H("e4e4ea") })
	k:tie(TIE, 0.66)
	k:coat(WHITE, 0.85, { open = true, gap = 0.5 })
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.42, 0.38, 0.05), V(s * 0.6, HIP + 0.32, fz - 0.03), H("e4e4ea"))
	end
	for i, c in { H("e04040"), H("3a6ad0") } do
		k:plate("UpperTorso", V(0.06, 0.3, 0.06), V(0.42 + i * 0.1, SH - 0.5, fz - 0.07), c)
	end
	k:hair("tufts", WHITE)
	for _, p in { V(-0.6, 0.35, 30), V(0.6, 0.35, -30), V(-0.25, 0.5, 12), V(0.25, 0.5, -12) } do -- wild white spikes
		k:brick("HeadDetail", V(0.3, 0.5, 0.36), V(p.X, HT + p.Y - 0.25, 0.2), WHITE, V(0, 0, p.Z))
	end
	k:headband(GOG, 0.2) -- goggles pushed up on the forehead
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.42, 0.36, 0.16), V(s * 0.38, HT - 0.2, FZ - 0.08), GOG)
		k:plate("HeadDetail", V(0.3, 0.26, 0.04), V(s * 0.38, HT - 0.2, FZ - 0.17), H("9fe8c8"))
	end
	face(k, H("dddddd"), { eyes = { w = 0.6, h = 0.62, inward = -0.4, y = -0.05 }, brows = { y = -0.05, tilt = -10, raise = 0.04 }, mouth = "grin", m = { w = 0.58 } })
	local fl = k:held(-1, V(0.56, 0.5, 0.56), V(0, 0.25, -0.5), H("e8fff4"), nil, true) -- bubbling flask
	fl.Transparency = 0.35
	k:held(-1, V(0.46, 0.36, 0.46), V(0, 0.2, -0.5), H("5ae84a"))
	k:held(-1, V(0.2, 0.36, 0.2), V(0, 0.66, -0.5), H("e8fff4"), nil, true)
	k:held(-1, V(0.12, 0.12, 0.12), V(0.05, 0.98, -0.5), H("8af07a"))
end

C.FirefighterFaye = function(k)
	local COAT, REFL, HELMET, HAIR = H("e8b830"), H("dfe4ea"), H("e02a2a"), H("3a1a10")
	k:body({ skin = S5, shirt = COAT, pants = COAT, shoes = BLACK, hands = H("3a3a3a") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, REFL)
	k:boots(BLACK, 0.45)
	for _, y in { HIP + 0.3, HIP + 0.95 } do
		k:torsoBand(y, 0.13, REFL)
	end
	k:armBand(SH - 0.75, 0.12, REFL)
	k:legBand(0.95, 0.12, REFL)
	for i = 0, 3 do
		k:plate("UpperTorso", V(0.24, 0.08, 0.05), V(0, SH - 0.3 - i * 0.36, fz - 0.03), BLACK) -- clasps
	end
	k:collar(H("c89a20"))
	k:hair("ponytail", HAIR, { band = HELMET, hat = true, noTop = true })
	local top = k:helmet(HELMET, { brimBack = true })
	k:brick("HeadDetail", V(0.16, 0.3, D.headD + 0.1), V(0, top + 0.1, 0.03), H("b81e1e")) -- ridge
	k:plate("HeadDetail", V(0.5, 0.44, 0.06), V(0, HT - 0.05, -(D.headD + 0.24) / 2 - 0.03), GOLD) -- badge
	face(k, HAIR, { eyes = { y = -0.06 }, brows = { y = -0.06, tilt = 6 }, m = { w = 0.44 } })
	k:held(1, V(0.46, 0.9, 0.46), V(0.05, -0.2, -0.52), H("e02a2a")) -- extinguisher
	k:held(1, V(0.22, 0.2, 0.22), V(0.05, 0.33, -0.52), H("c8ccd6"))
	k:held(1, V(0.08, 0.08, 0.5), V(-0.1, 0.36, -0.75), BLACK, V(-20, 0, 0))
	k:held(1, V(0.36, 0.2, 0.04), V(0.05, -0.15, -0.77), WHITE, nil, true)
end

C.MagicianMarvin = function(k)
	local COAT, RED, HAIR = H("1e1e2a"), H("c8203a"), H("1a1a1a")
	k:body({ skin = S2, shirt = COAT, pants = COAT, shoes = BLACK, hands = WHITE })
	cuffs(k, CUFF_LONG, WHITE)
	k:lapels(COAT, WHITE, { depth = 0.95, lapel = RED })
	k:bowtie(RED)
	k:buttons(2, GOLD, 0, HIP + 0.4, 0.28)
	k:cape(COAT, { length = 2.5, collar = RED })
	k:plate("UpperTorso", V(D.torsoW + 0.44, 2.4, 0.04), V(0, SH - 1.15, (k.td or D.torsoD) / 2 + 0.05), RED) -- the lining
	k:hair("side", HAIR, { side = -1 })
	k:topHat(COAT, RED, 0.95)
	face(k, HAIR, { eyes = { lid = 0.2 }, brows = { tilt = 10, lift = { [1] = 0.1, [-1] = 0 } }, m = { w = 0.36, y = -0.62 } })
	k:mustache(HAIR, "curly", { w = 0.5 })
	k:held(-1, V(0.09, 0.9, 0.09), V(0, 0.35, -0.5), BLACK, V(-25, 0, 10), true) -- wand
	k:held(-1, V(0.1, 0.2, 0.1), V(-0.08, 0.76, -0.7), WHITE, V(-25, 0, 10), true)
	k:held(1, V(0.36, 0.5, 0.03), V(0, 0.3, -0.48), WHITE, V(0, 0, -12), true) -- a playing card
	k:held(1, V(0.16, 0.16, 0.03), V(0, 0.3, -0.5), RED, V(0, 0, 57), true)
end

C.FarmerFrank = function(k)
	local SHIRT, SHIRT_D, DENIM, DENIM_D, STRAW, HAIR = H("d94a3a"), H("8a2a22"), H("3a6ab8"), H("2a4f8a"), H("e8c878"), H("8a5a2e")
	k:body({ skin = S3, shirt = SHIRT, pants = DENIM, sleeves = "short", shoes = H("6b4426"), sole = H("3a2a1e") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, SHIRT_D)
	k:collar(SHIRT_D)
	for _, x in { -0.3, 0.3 } do
		k:plate("UpperTorso", V(0.05, D.torsoH, 0.03), V(x, HIP + 0.75, fz - 0.02), SHIRT_D)
	end
	k:plate("UpperTorso", V(1.2, 0.9, 0.05), V(0, HIP + 0.45, fz - 0.04), DENIM) -- overall bib
	k:plate("UpperTorso", V(0.5, 0.36, 0.04), V(0, HIP + 0.5, fz - 0.07), DENIM_D)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.2, 0.7, 0.05), V(s * 0.45, SH - 0.35, fz - 0.04), DENIM)
		k:plate("UpperTorso", V(0.14, 0.14, 0.04), V(s * 0.45, HIP + 0.9, fz - 0.08), GOLD)
	end
	k:hair("messy", HAIR, { hat = true })
	k:brimHat(STRAW, { band = SHIRT, brimW = D.headW + 1.5, crownH = 0.55 })
	face(k, HAIR, { eyes = { y = -0.05, lid = 0.15 }, brows = { y = -0.05, tilt = -6 }, mouth = "grin", m = { w = 0.56 } })
	k:held(-1, V(0.9, 0.22, 0.9), V(0.1, 0.12, -0.6), H("c8862c")) -- a cherry pie
	k:held(-1, V(0.7, 0.04, 0.7), V(0.1, 0.24, -0.6), H("b8202a"), nil, true)
	for _, d in { -0.2, 0.2 } do
		k:held(-1, V(0.1, 0.05, 0.8), V(0.1 + d, 0.27, -0.6), H("e8b060"), nil, true)
		k:held(-1, V(0.8, 0.05, 0.1), V(0.1, 0.28, -0.6 + d), H("e8b060"), nil, true)
	end
end

C.NurseNina = function(k)
	local SCRUB, SCRUB_D, HAIR = H("3ab8b0"), H("2a908a"), H("1a1410")
	k:body({ skin = S6, shirt = SCRUB, pants = SCRUB, sleeves = "short", shoes = WHITE, sole = H("d8d8e0") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, SCRUB_D)
	k:lapels(SCRUB, S6, { depth = 0.5, lapel = SCRUB_D, panel = 0.5 })
	k:badge(SCRUB_D, -0.58, SH - 0.78, Vector2.new(0.42, 0.36)) -- pocket + pen
	k:plate("UpperTorso", V(0.06, 0.3, 0.06), V(-0.5, SH - 0.65, fz - 0.08), H("e04040"))
	k:badge(WHITE, 0.58, SH - 0.82, Vector2.new(0.36, 0.46)) -- ID badge
	k:plate("UpperTorso", V(0.24, 0.14, 0.03), V(0.58, SH - 0.72, fz - 0.07), H("3a6ad0"))
	for _, s in { -1, 1 } do -- stethoscope
		k:plate("UpperTorso", V(0.07, 0.85, 0.07), V(s * 0.3, SH - 0.38, fz - 0.1), H("3a3a44"), V(0, 0, s * -8))
	end
	k:brick("UpperTorso", V(0.26, 0.26, 0.1), V(0.27, SH - 0.88, fz - 0.12), H("c8ccd6"))
	k:hair("bun", HAIR)
	face(k, HAIR, { eyes = { lid = 0.15, look = Vector2.new(0, 0.15) }, brows = { tilt = -6 }, m = { w = 0.42 } })
	k:held(1, V(0.6, 0.8, 0.05), V(0, 0.3, -0.48), H("a8743a"), V(0, 0, -8), true) -- clipboard
	k:held(1, V(0.5, 0.64, 0.03), V(0, 0.27, -0.51), WHITE, V(0, 0, -8), true)
	k:held(1, V(0.26, 0.1, 0.06), V(0.05, 0.66, -0.52), H("c8ccd6"), V(0, 0, -8), true)
end

C.MechanicMax = function(k)
	local COVER, COVER_D, CAP, CAP_D, HAIR = H("3a5a9a"), H("2a4278"), H("ff7a1a"), H("d95a10"), H("1a1a1a")
	k:body({ skin = S4, shirt = COVER, pants = COVER, sleeves = "short", shoes = BLACK, hands = H("3a3a3a") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, COVER_D)
	k:collar(COVER_D)
	k:plate("UpperTorso", V(0.06, D.torsoH - 0.2, 0.03), V(0, HIP + 0.7, fz - 0.02), H("c8ccd6")) -- zip
	k:badge(WHITE, 0.55, SH - 0.6, Vector2.new(0.5, 0.3)) -- name patch
	k:plate("UpperTorso", V(0.3, 0.06, 0.03), V(0.55, SH - 0.6, fz - 0.07), H("e04040"))
	k:belt(BLACK, H("c8ccd6"))
	spots(k, { { -0.55, HIP + 0.55, 0.18, H("2a2a2a") }, { 0.35, HIP + 0.85, 0.12, H("2a2a2a") } }) -- grease
	k:plate("UpperTorso", V(0.3, 0.55, 0.05), V(-0.7, HIP - 0.15, (k.td or D.torsoD) / 2 + 0.05), H("e04040"), V(0, 0, 8)) -- rag
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:cap(CAP, CAP_D, { backwards = true, down = 0.34 })
	face(k, HAIR, { eyes = { y = -0.02 }, brows = { y = -0.02, tilt = -4 }, mouth = "grin", m = { w = 0.52 } })
	k:plate("HeadDetail", V(0.28, 0.12, 0.03), V(0.62, HY - 0.38, FZ - 0.02), H("4a4a4a")) -- grease smudge
	k:held(-1, V(0.12, 0.9, 0.07), V(0, 0.35, -0.5), H("b8bec8")) -- wrench
	k:held(-1, V(0.42, 0.3, 0.08), V(0, 0.85, -0.5), H("b8bec8"))
	k:held(-1, V(0.16, 0.18, 0.1), V(0, 0.93, -0.5), H("2a2a30"))
end

C.ArtistAria = function(k)
	local SMOCK, NAVY, HAIR = H("f4f0e8"), H("26345e"), H("2a1810")
	k:body({ skin = S1, shirt = SMOCK, pants = H("2a2a3a"), shoes = H("e04040") })
	cuffs(k, CUFF_LONG, NAVY)
	for _, y in { 2.0, 2.35 } do
		k:armBand(y, 0.1, NAVY) -- striped sleeves
	end
	k:coat(SMOCK, 0.55, {})
	spots(k, { { -0.5, SH - 0.35, 0.22, H("3a8bff") }, { 0.4, SH - 0.8, 0.26, H("ff4fa0") }, { -0.2, HIP + 0.55, 0.2, H("ffd21f") }, { 0.6, SH - 0.2, 0.16, H("5ae84a") } })
	k:hair("long", HAIR, { side = 1 })
	k:brick("HeadDetail", V(D.headW + 0.3, 0.3, D.headD + 0.2), V(0.12, HT + 0.2, 0.05), H("d92a3a"), V(0, 0, -8)) -- beret
	k:brick("HeadDetail", V(0.1, 0.16, 0.1), V(0.16, HT + 0.42, 0.05), H("d92a3a"))
	face(k, HAIR, { eyes = { look = Vector2.new(0.3, 0.5) }, brows = { tilt = -6 }, m = { w = 0.4 } })
	k:plate("HeadDetail", V(0.16, 0.16, 0.03), V(0.65, HY - 0.4, FZ - 0.02), H("3a8bff")) -- paint dot
	k:held(1, V(0.9, 0.06, 0.66), V(0.1, 0.15, -0.55), H("c8964e"), nil, true) -- palette
	for i, c in { H("3a8bff"), H("ff4fa0"), H("ffd21f"), H("5ae84a") } do
		k:held(1, V(0.14, 0.05, 0.14), V(0.3 - (i % 2) * 0.24, 0.2, -0.75 + math.floor((i - 1) / 2) * 0.24), c, nil, true)
	end
	k:held(-1, V(0.07, 0.8, 0.07), V(0, 0.35, -0.5), H("c8964e"), V(-20, 0, 0), true) -- brush
	k:held(-1, V(0.1, 0.18, 0.1), V(0, 0.76, -0.65), H("3a8bff"), V(-20, 0, 0), true)
end

C.WrestlerRonda = function(k)
	local SINGLET, HAIR = H("d92a4a"), H("ff4fa0")
	k:body({ skin = S3, shirt = SINGLET, pants = SINGLET, sleeves = "none", legs = "shorts", socks = SINGLET, sockH = 0.45, shoes = SINGLET, sole = WHITE, torsoD = 1.15 })
	local fz = k:frontZ()
	for _, s in { -1, 1 } do
		k:brick("UpperTorso", V(0.5, 0.35, (k.td or D.torsoD) + 0.02), V(s * 0.76, SH - 0.17, 0), S3) -- bare shoulders
		k:brick(leg(s), V(D.legW + 0.06, 0.26, D.legD + 0.06), V(s * LX, 0.85, 0), BLACK) -- knee pads
		k:brick(arm(s), V(D.armW + 0.04, 0.26, D.armD + 0.04), V(s * AX, SH - D.armH + D.handH + 0.1, 0), WHITE) -- wrist tape
	end
	k:brick("UpperTorso", V(D.torsoW + 0.1, 0.4, (k.td or D.torsoD) + 0.12), V(0, HIP + 0.2, 0), GOLD_D) -- the title belt
	k:brick("UpperTorso", V(0.85, 0.6, 0.1), V(0, HIP + 0.22, fz - 0.1), GOLD)
	k:plate("UpperTorso", V(0.36, 0.36, 0.05), V(0, HIP + 0.22, fz - 0.17), H("e04040"))
	k:hair("mohawk", HAIR)
	face(k, H("6a2a1a"), { eyes = { look = Vector2.new(0, 0.1) }, brows = { tilt = 14 }, mouth = "grin", m = { w = 0.58 } })
end

C.PilotPaige = function(k)
	local NAVY, NAVY_D, HAIR = H("1f2f5c"), H("15203e"), H("e0b85a")
	k:body({ skin = S2, shirt = NAVY, pants = NAVY, shoes = BLACK })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, GOLD)
	k:armBand(CUFF_LONG + 0.18, 0.06, GOLD)
	k:lapels(NAVY, WHITE, { depth = 0.9, lapel = NAVY_D })
	k:tie(BLACK, 0.6)
	k:buttons(2, GOLD, 0, HIP + 0.35, 0.28)
	k:badge(GOLD, 0.58, SH - 0.5, Vector2.new(0.56, 0.1)) -- wings pin
	k:plate("UpperTorso", V(0.16, 0.16, 0.04), V(0.58, SH - 0.5, fz - 0.08), GOLD_D)
	k:hair("bob", HAIR)
	k:brick("HeadDetail", V(D.headW + 0.2, 0.3, D.headD + 0.2), V(0, HT + 0.05, 0.02), NAVY) -- pilot's cap
	k:brick("HeadDetail", V(D.headW + 0.36, 0.2, D.headD + 0.3), V(0, HT + 0.28, 0.02), WHITE)
	k:brick("HeadDetail", V(1.4, 0.1, 0.55), V(0, HT - 0.12, FZ - 0.25), BLACK, V(-12, 0, 0))
	k:plate("HeadDetail", V(0.5, 0.14, 0.05), V(0, HT + 0.05, -(D.headD + 0.2) / 2 - 0.03), GOLD)
	face(k, H("b8903a"), { eyes = { look = Vector2.new(0, 0.1) }, brows = { tilt = 2 }, m = { w = 0.44 } })
	k:held(1, V(0.24, 0.12, 0.08), V(0, -0.08, -0.05), BLACK, nil, true) -- flight bag
	k:held(1, V(0.42, 0.75, 0.9), V(0.05, -0.55, -0.05), H("2a2a34"))
	k:held(1, V(0.44, 0.08, 0.92), V(0.05, -0.42, -0.05), H("c8ccd6"), nil, true)
end

C.MusicianMoe = function(k)
	local RED, RED_D, HAIR = H("c8203a"), H("9a1428"), H("1a1410")
	k:body({ skin = S6, shirt = RED, pants = WHITE, shoes = BLACK, hands = WHITE })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, GOLD)
	for i = 0, 3 do
		k:plate("UpperTorso", V(0.8, 0.07, 0.04), V(0, SH - 0.35 - i * 0.3, fz - 0.02), GOLD) -- frogging
	end
	for _, s in { -1, 1 } do
		k:brick(arm(s), V(D.armW + 0.2, 0.16, D.armD + 0.12), V(s * AX, SH - 0.1, 0), GOLD) -- epaulettes
		k:plate(leg(s), V(0.06, 0.9, 0.1), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), RED)
	end
	k:torsoBand(HIP + 0.08, 0.16, WHITE)
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:brick("HeadDetail", V(D.headW - 0.1, 0.95, D.headD - 0.1), V(0, HT + 0.3, 0.02), RED_D) -- shako
	k:plate("HeadDetail", V(D.headW - 0.06, 0.14, D.headD - 0.06), V(0, HT + 0.72, 0.02), GOLD)
	k:brick("HeadDetail", V(1.3, 0.1, 0.5), V(0, HT - 0.14, FZ - 0.2), BLACK, V(-12, 0, 0))
	k:plate("HeadDetail", V(0.36, 0.36, 0.05), V(0, HT + 0.3, -(D.headD - 0.1) / 2 - 0.03), GOLD)
	k:brick("HeadDetail", V(0.3, 0.7, 0.3), V(0, HT + 1.12, 0.02), WHITE) -- plume
	face(k, HAIR, { eyes = { y = -0.05 }, brows = { y = -0.05, tilt = -4 }, mouth = "open", m = { w = 0.36, h = 0.26 } })
	k:blush(H("c8506a"))
	-- the tuba, carried at his chest (torso parts: it stays put while he walks), the bell BESIDE his head
	local T = "UpperTorso"
	k:brick(T, V(0.8, 1.0, 0.55), V(0.5, HIP + 0.75, fz - 0.4), GOLD)
	k:brick(T, V(0.36, 1.1, 0.36), V(1.25, SH + 0.15, -0.35), GOLD, V(0, 0, 35))
	k:brick(T, V(1.1, 0.45, 1.1), V(1.78, HY + 0.1, -0.1), GOLD) -- the bell, opening up
	k:plate(T, V(0.85, 0.06, 0.85), V(1.78, HY + 0.34, -0.1), GOLD_D)
	for i = 0, 2 do
		k:brick(T, V(0.12, 0.2, 0.12), V(0.25 + i * 0.16, HIP + 1.35, fz - 0.6), GOLD_D) -- valves
	end
end

------------------------------------------------------------------ TIER 3
C.BaronVonBanana = function(k)
	local FUR, FUR_L, VEST = H("7a4a2a"), H("e2bf92"), H("6a2a8a")
	k:body({ skin = FUR, shirt = VEST, pants = H("3a2a4a"), shoes = FUR_L, sole = FUR, hands = FUR_L })
	cuffs(k, CUFF_LONG, WHITE)
	k:lapels(VEST, WHITE, { depth = 0.9, lapel = H("4a1a62") })
	k:bowtie(GOLD)
	k:coat(VEST, 0.7, { open = true, gap = 0.3, trim = RARE })
	k:buttons(2, GOLD, 0, HIP + 0.4, 0.28)
	-- monkey face: a light face patch, a muzzle, round ears, a curly tail
	k:plate("HeadDetail", V(1.5, 1.05, 0.02), V(0, HY - 0.22, FZ - 0.006), FUR_L)
	k:brick("HeadDetail", V(1.0, 0.5, 0.26), V(0, HY - 0.58, FZ - 0.14), FUR_L)
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.2, 0.55, 0.55), V(s * (D.headW / 2 + 0.1), HY + 0.1, 0.05), FUR)
		k:plate("HeadDetail", V(0.04, 0.36, 0.36), V(s * (D.headW / 2 + 0.21), HY + 0.1, 0.05), FUR_L)
	end
	for _, p in { V(0, HIP - 0.05, 0.65), V(0, HIP - 0.2, 0.88), V(0, HIP - 0.08, 1.1), V(0, HIP + 0.15, 1.15), V(0, HIP + 0.32, 1.0) } do
		k:brick("UpperTorso", V(0.2, 0.2, 0.22), p, FUR)
	end
	k:topHat(BLACK, H("ffd23c"), 0.9)
	k:eyes({ lid = 0.3, look = Vector2.new(0.2, 0) })
	k:brows(H("4a2a14"), { lift = { [1] = 0.1, [-1] = 0 } })
	k:plate("HeadDetail", V(0.3, 0.18, 0.05), V(0, HY - 0.42, FZ - 0.28), INK) -- nose on the muzzle
	k:plate("HeadDetail", V(0.5, 0.08, 0.04), V(0, HY - 0.66, FZ - 0.28), Kit.C.Mouth) -- smirk
	k:plate("HeadDetail", V(0.1, 0.14, 0.04), V(0.25, HY - 0.62, FZ - 0.28), Kit.C.Mouth)
	local mx, my, mz, mw = 0.46, HY + 0.05, FZ - 0.13, 0.72 -- monocle
	k:plate("HeadDetail", V(mw, 0.07, 0.05), V(mx, my + mw / 2, mz), GOLD)
	k:plate("HeadDetail", V(mw, 0.07, 0.05), V(mx, my - mw / 2, mz), GOLD)
	k:plate("HeadDetail", V(0.07, mw, 0.05), V(mx - mw / 2, my, mz), GOLD)
	k:plate("HeadDetail", V(0.07, mw, 0.05), V(mx + mw / 2, my, mz), GOLD)
	k:held(-1, V(0.2, 0.42, 0.2), V(0, 0.42, -0.5), H("fff3c8")) -- a peeled banana
	for _, a in { -35, 35 } do
		k:held(-1, V(0.18, 0.4, 0.06), V(a / 140, 0.2, -0.5), H("ffd23f"), V(0, 0, a), true)
	end
	k:held(-1, V(0.06, 0.4, 0.18), V(0, 0.2, -0.62), H("ffd23f"), V(-35, 0, 0), true)
	k:held(-1, V(0.1, 0.12, 0.1), V(0, 0.68, -0.5), H("6b4426"))
end

C.BeepBot = function(k)
	local METAL, METAL_D, ORANGE, DARK = H("d8dde6"), H("aab2c0"), H("ff8a2a"), H("3a3f4a")
	k:body({ skin = METAL, shirt = METAL, pants = DARK, shoes = DARK, sole = ORANGE, hands = METAL_D })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, ORANGE)
	k:plate("UpperTorso", V(1.1, 0.95, 0.05), V(0, HIP + 0.85, fz - 0.03), ORANGE) -- delivery panel
	k:plate("UpperTorso", V(0.5, 0.5, 0.04), V(0, HIP + 0.9, fz - 0.06), WHITE)
	k:plate("UpperTorso", V(0.3, 0.08, 0.03), V(0, HIP + 0.9, fz - 0.09), ORANGE)
	k:plate("UpperTorso", V(0.08, 0.3, 0.03), V(0, HIP + 0.9, fz - 0.09), ORANGE)
	for _, s in { -1, 1 } do
		k:brick(leg(s), V(0.14, 0.42, 0.42), V(s * (LX + D.legW / 2 + 0.07), 0.25, -0.1), ORANGE) -- wheel hubs
		k:brick("HeadDetail", V(0.14, 0.4, 0.4), V(s * (D.headW / 2 + 0.07), HY, 0), ORANGE) -- ear bolts
		k:brick(arm(s), V(D.armW + 0.04, 0.14, D.armD + 0.04), V(s * AX, SH - 0.4, 0), DARK) -- joint rings
	end
	k:brick("HeadDetail", V(0.08, 0.5, 0.08), V(0.4, HT + 0.25, 0), DARK) -- antenna
	k:brick("HeadDetail", V(0.22, 0.22, 0.22), V(0.4, HT + 0.56, 0), ORANGE)
	k:plate("HeadDetail", V(1.6, 1.1, 0.03), V(0, HY - 0.05, FZ - 0.005), DARK) -- the face screen
	k:eyes({ border = false, look = Vector2.new(0, 0.2) })
	k:plate("HeadDetail", V(0.6, 0.1, 0.03), V(0, HY - 0.48, FZ - 0.03), H("4fd8ff")) -- speaker smile
	for _, s in { -1, 1 } do
		k:plate("HeadDetail", V(0.1, 0.1, 0.03), V(s * 0.68, HY + 0.38, FZ - 0.03), RARE) -- Rare-blue status lights
	end
	for i = 0, 2 do -- a stack of pizza boxes, carried in front (torso parts)
		k:brick("UpperTorso", V(1.3, 0.16, 1.0), V(0, HIP + 0.75 + i * 0.18, fz - 0.62), if i % 2 == 0 then H("f2ede0") else H("e2dcc8"), V(0, (i - 1) * 6, 0))
	end
	k:plate("UpperTorso", V(0.4, 0.04, 0.4), V(0, HIP + 0.75 + 2 * 0.18 + 0.1, fz - 0.62), H("e04040"))
end

C.PiratePatches = function(k)
	local COAT, COAT_D, PANTS, HAIR = H("b8282e"), H("8a1a20"), H("2a2a3a"), H("1a1a1a")
	k:body({ skin = S3, shirt = COAT, pants = PANTS, shoes = BLACK })
	cuffs(k, CUFF_LONG, GOLD)
	k:lapels(COAT, WHITE, { depth = 0.95, lapel = COAT_D })
	k:coat(COAT, 0.8, { open = true, gap = 0.4, trim = GOLD })
	for _, x in { -0.36, 0.36 } do
		k:buttons(3, GOLD, x, SH - 0.4, 0.3)
	end
	k:belt(H("3a2a1e"), GOLD)
	k:boots(BLACK, 0.5, H("2a2a2a"))
	k:hair("long", HAIR, { side = 1 })
	k:brimHat(BLACK, { cowboy = true, brimW = D.headW + 1.0, brimD = D.headD + 0.7, crownH = 0.6 }) -- tricorn-ish
	k:plate("HeadDetail", V(D.headW + 0.12, 0.06, 0.05), V(0, HT - 0.06, -(D.headD + 0.7) / 2 - 0.03), GOLD)
	k:plate("HeadDetail", V(0.32, 0.28, 0.05), V(0, HT + 0.2, -(D.headD - 0.1) / 2 - 0.03), WHITE) -- skull badge
	k:eye(-0.46, HY + 0.05, {})
	k:plate("HeadDetail", V(0.6, 0.62, 0.05), V(0.46, HY + 0.05, FZ - 0.04), BLACK) -- eye patch
	k:plate("HeadDetail", V(D.headW + 0.1, 0.06, 0.04), V(0.05, HY + 0.35, FZ - 0.03), BLACK, V(0, 0, -18))
	k:brows(HAIR, { tilt = 8, only = -1 })
	k:nose()
	k:mouth("grin", { w = 0.5 })
	local px, py = -1.3, SH + 0.32 -- the parrot on his right shoulder (torso parts)
	k:brick("UpperTorso", V(0.38, 0.55, 0.42), V(px, py, 0.05), H("3ac04a"))
	k:brick("UpperTorso", V(0.34, 0.34, 0.34), V(px, py + 0.42, -0.05), H("3ac04a"))
	k:brick("UpperTorso", V(0.14, 0.16, 0.18), V(px, py + 0.36, -0.28), H("ffc83a"))
	k:brick("UpperTorso", V(0.16, 0.5, 0.12), V(px, py - 0.3, 0.3), H("e03a3a"), V(30, 0, 0))
	k:plate("UpperTorso", V(0.08, 0.08, 0.03), V(px + 0.1, py + 0.48, -0.23), BLACK)
	k:held(1, V(0.7, 0.5, 0.04), V(0, 0.28, -0.48), H("f0dca8"), V(0, 0, -8), true) -- treasure map
	k:held(1, V(0.1, 0.1, 0.02), V(0.15, 0.25, -0.51), H("e04040"), V(0, 0, 45), true)
end

C.CowboyCody = function(k)
	local SHIRT, VEST, JEANS, HAT, HAT_D, BANDANA, HAIR = H("5a8ad0"), H("8a5a2e"), H("3a5a9a"), H("a8743a"), H("5a3418"), H("d92a3a"), H("6b3a1e")
	k:body({ skin = S3, shirt = SHIRT, pants = JEANS, shoes = H("6b3a1e"), sole = H("3a2010") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, H("4a78b8"))
	k:vest(VEST, { gap = 0.6 })
	k:brick("UpperTorso", V(D.torsoW + 0.06, D.torsoH - 0.1, 0.08), V(0, HIP + 0.7, (k.td or D.torsoD) / 2 + 0.04), VEST)
	k:buttons(3, WHITE, 0, SH - 0.5, 0.28)
	k:wedge("UpperTorso", V(0.8, 0.4, 0.1), V(0, SH - 0.22, fz - 0.07), BANDANA, V(0, 180, 180), false)
	k:brick("UpperTorso", V(1.2, 0.14, 1.0), V(0, SH + 0.0, 0.02), BANDANA)
	k:belt(H("5a3418"), GOLD)
	k:plate("UpperTorso", V(0.4, 0.3, 0.08), V(0, HIP + 0.08, fz - 0.1), GOLD) -- big buckle
	k:boots(H("6b3a1e"), 0.5, H("8a5a2e"))
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:brimHat(HAT, { cowboy = true, band = HAT_D, brimW = D.headW + 1.4, crownH = 0.65 })
	face(k, HAIR, { eyes = { y = -0.06, lid = 0.25 }, brows = { y = -0.06, tilt = 4 }, mouth = "grin", m = { w = 0.5 } })
	local lx, ly, rope = -(AX + D.armW / 2 + 0.12), HIP + 0.1, H("d8b878") -- a coiled lasso on his hip
	for _, y in { -0.3, 0.3 } do
		k:brick("UpperTorso", V(0.1, 0.1, 0.7), V(lx, ly + y, 0), rope)
	end
	for _, z in { -0.3, 0.3 } do
		k:brick("UpperTorso", V(0.1, 0.7, 0.1), V(lx, ly, z), rope)
	end
end

C.ZombieZeke = function(k)
	local SKIN, SHIRT, SHIRT_D, PANTS, HAIR = H("98c880"), H("8aa8c8"), H("6a88a8"), H("5a5a6a"), H("2a3a22")
	k:body({ skin = SKIN, shirt = SHIRT, pants = PANTS, sleeves = "short", shoes = H("4a3a2a") })
	local fz = k:frontZ()
	cuffs(k, CUFF_SHORT, SHIRT_D)
	k:collar(SHIRT_D)
	k:plate("UpperTorso", V(0.2, 0.18, 0.07), V(0.1, SH - 0.14, fz - 0.06), H("a83a3a"), V(0, 0, 12)) -- a loose tie
	k:plate("UpperTorso", V(0.16, 0.7, 0.05), V(0.18, SH - 0.58, fz - 0.06), H("a83a3a"), V(0, 0, 12))
	spots(k, { { -0.5, SH - 0.5, 0.3, H("6a7a8a") }, { 0.55, HIP + 0.45, 0.24, H("6a7a8a") }, { -0.2, HIP + 0.25, 0.22, SKIN } })
	for i = -3, 3 do -- a ragged hem
		k:brick("UpperTorso", V(0.24, 0.22, D.torsoD + 0.04), V(i * 0.28, HIP - 0.05 - (i % 2) * 0.06, 0), SHIRT)
	end
	for _, s in { -1, 1 } do
		k:brick(leg(s), V(0.26, 0.2, 0.1), V(s * LX - 0.2, 0.36, -D.legD / 2 - 0.04), PANTS) -- torn trouser hems
	end
	k:brick("LeftUpperArm", V(D.armW - 0.02, 0.28, D.armD - 0.02), V(AX, SH - 0.75, 0), H("f2ece0")) -- bandage
	k:hair("messy", HAIR)
	k:eye(-0.46, HY + 0.08, { look = Vector2.new(-0.6, 0.3) })
	k:eye(0.46, HY + 0.0, { w = 0.44, h = 0.48, look = Vector2.new(0.5, -0.4), lid = 0.3 })
	k:brows(HAIR, { tiltL = 10, tiltR = -12 })
	k:nose()
	k:mouth("open", { w = 0.5, h = 0.26 })
end

C.NinjaNoodle = function(k)
	local SUIT, SUIT_L, SASH = H("23232e"), H("3a3a46"), H("d92a3a")
	k:body({ skin = S4, shirt = SUIT, pants = SUIT, shoes = SUIT, sole = SUIT_L, hands = SUIT })
	local fz = k:frontZ()
	-- the hood over the whole head, eyes showing through a slit
	local W, Dd, hw = D.headW + 0.12, D.headD + 0.12, D.headW / 2
	k:brick("HeadDetail", V(W, 0.68, Dd), V(0, HT - 0.3, 0), SUIT)
	k:brick("HeadDetail", V(W, 0.86, Dd), V(0, HY - 0.5, 0), SUIT)
	local slitY, slitH = HY + 0.08, 0.36
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.12, slitH, Dd), V(s * (hw + 0.06), slitY, 0), SUIT)
	end
	k:brick("HeadDetail", V(W, slitH, 0.12), V(0, slitY, D.headD / 2 + 0.06), SUIT)
	k:eyes({ y = 0.08, w = 0.42, h = 0.3, lid = 0.15, lidColor = SUIT })
	k:brick("HeadDetail", V(0.24, 0.24, 0.2), V(0, HY + 0.2, D.headD / 2 + 0.16), SASH) -- the knot + tails
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.14, 0.6, 0.08), V(s * 0.2, HY - 0.15, D.headD / 2 + 0.22), SASH, V(15, 0, s * 15))
		k:brick(arm(s), V(D.armW + 0.04, 0.45, D.armD + 0.04), V(s * AX, SH - 0.95, 0), SUIT_L) -- arm wraps
	end
	k:brick("UpperTorso", V(D.torsoW + 0.06, 0.24, D.torsoD + 0.06), V(0, HIP + 0.12, 0), SASH)
	k:brick("UpperTorso", V(0.26, 0.26, 0.12), V(0.45, HIP + 0.12, fz - 0.08), SASH)
	k:plate("UpperTorso", V(0.14, 0.55, 0.06), V(0.5, HIP - 0.22, fz - 0.06), SASH, V(0, 0, -10))
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.1, 1.3, 0.04), V(s * 0.22, SH - 0.62, fz - 0.03), SUIT_L, V(0, 0, s * 25)) -- crossed gi
	end
	local bz = (k.td or D.torsoD) / 2 + 0.1 -- katana across the back
	k:brick("UpperTorso", V(0.14, 2.1, 0.14), V(0, SH - 0.35, bz), BLACK, V(0, 0, 40))
	k:plate("UpperTorso", V(0.4, 0.08, 0.3), V(-0.35, SH + 0.1, bz), GOLD, V(0, 0, 40))
	k:brick("UpperTorso", V(0.13, 0.5, 0.13), V(-0.6, SH + 0.38, bz), SASH, V(0, 0, 40))
	k:plate("UpperTorso", V(0.16, 0.16, 0.04), V(-0.55, SH - 0.5, fz - 0.06), RARE) -- a Rare-blue throwing star badge
end

C.KnightKevin = function(k)
	local ARMOR, ARMOR_D, TABARD, PLUME = H("c8ccd6"), H("9aa0ae"), H("3a6ad0"), H("e03a3a")
	k:body({ skin = S2, shirt = ARMOR, pants = ARMOR, shoes = ARMOR_D, hands = ARMOR_D })
	local fz = k:frontZ()
	k:plate("UpperTorso", V(1.2, 1.9, 0.05), V(0, HIP + 0.4, fz - 0.03), TABARD)
	k:plate("UpperTorso", V(0.5, 0.5, 0.04), V(0, HIP + 0.75, fz - 0.07), GOLD, V(0, 0, 45))
	k:plate("UpperTorso", V(0.26, 0.26, 0.03), V(0, HIP + 0.75, fz - 0.1), H("e03a3a"), V(0, 0, 45))
	k:belt(H("6b4426"), GOLD)
	for _, s in { -1, 1 } do
		k:brick(arm(s), V(D.armW + 0.3, 0.4, D.armD + 0.24), V(s * AX, SH - 0.22, 0), ARMOR_D) -- pauldrons
		k:brick(leg(s), V(D.legW + 0.06, 0.26, D.legD + 0.06), V(s * LX, 0.85, 0), ARMOR_D)
	end
	local W, Dd = D.headW + 0.16, D.headD + 0.16 -- helmet, face open, visor raised, plume
	k:brick("HeadDetail", V(W, 0.55, Dd), V(0, HT - 0.12, 0), ARMOR)
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.16, D.headH - 0.3, Dd), V(s * (D.headW / 2 + 0.08), HY - 0.05, 0), ARMOR)
	end
	k:brick("HeadDetail", V(W, D.headH - 0.3, 0.16), V(0, HY - 0.05, D.headD / 2 + 0.08), ARMOR)
	k:brick("HeadDetail", V(W - 0.2, 0.26, 0.12), V(0, HT + 0.12, FZ - 0.12), ARMOR_D, V(-30, 0, 0))
	k:brick("HeadDetail", V(0.22, 0.6, 1.2), V(0, HT + 0.4, 0.15), PLUME, V(-10, 0, 0))
	face(k, H("8a5a2e"), { eyes = { y = -0.06 }, brows = { y = -0.08, tilt = 6 }, mouth = "grin", m = { w = 0.5 } })
	local x = AX + D.armW / 2 + 0.12 -- shield on his left arm, sword in his right hand (below the shoulder)
	k:brick("LeftUpperArm", V(0.14, 1.1, 0.95), V(x, 1.95, -0.05), TABARD)
	k:plate("LeftUpperArm", V(0.05, 1.3, 0.2), V(x + 0.09, 1.95, -0.05), GOLD, V(-38, 0, 0))
	k:held(-1, V(0.1, 1.0, 0.04), V(0, 0.65, -0.48), H("e0e4ea"), nil, true)
	k:held(-1, V(0.46, 0.08, 0.12), V(0, 0.12, -0.48), GOLD, nil, true)
	k:held(-1, V(0.14, 0.14, 0.14), V(0, -0.12, -0.48), GOLD)
end

C.MermaidMarina = function(k)
	local TAIL, TAIL_L, TOP, HAIR = H("2fb8a8"), H("8fe8d8"), H("b48ae0"), H("e04a3a")
	k:body({ skin = S1, shirt = TOP, pants = TAIL, sleeves = "none", legs = "skirt", skirtLen = 1.22, flare = 0.1, tights = TAIL, shoes = TAIL, sole = TAIL_L })
	local fz = k:frontZ()
	k:brick("UpperTorso", V(D.torsoW + 0.02, 0.55, (k.td or D.torsoD) + 0.02), V(0, HIP + 0.3, 0), S1) -- (a shell top)
	for i = 0, 2 do -- scale rows on the tail
		k:plate("UpperTorso", V(D.torsoW + 0.28, 0.08, (k.td or D.torsoD) + 0.28), V(0, HIP - 0.2 - i * 0.36, 0), TAIL_L)
	end
	for _, s in { -1, 1 } do -- fins flaring at the hem
		k:brick("UpperTorso", V(0.6, 0.14, 0.7), V(s * 1.25, 0.14, 0), TAIL_L, V(0, 0, s * 20))
	end
	for i = -3, 3 do -- shell necklace
		k:plate("UpperTorso", V(0.13, 0.11, 0.05), V(i * 0.12, SH - 0.12 - (9 - i * i) * 0.022, fz - 0.06), H("ffc8d8"))
	end
	k:hair("long", HAIR, { side = -1 })
	for _, a in { 0, 72, 144 } do -- starfish clip
		k:plate("HeadDetail", V(0.36, 0.1, 0.05), V(0.55, HT - 0.1, -(D.headD + 0.12) / 2 - 0.04), H("ff9a3a"), V(0, 0, a))
	end
	face(k, H("b83a2a"), { eyes = { look = Vector2.new(0.2, 0.3) }, brows = { tilt = -6 }, m = { w = 0.44 } })
	k:blush()
	k:held(-1, V(0.09, 2.2, 0.09), V(0, -0.38, -0.48), GOLD) -- trident, standing on the ground
	k:held(-1, V(0.5, 0.09, 0.09), V(0, 0.76, -0.48), GOLD)
	for _, d in { -0.22, 0, 0.22 } do
		k:held(-1, V(0.08, 0.34, 0.08), V(d, 0.94, -0.48), GOLD)
	end
	k:held(-1, V(0.14, 0.14, 0.14), V(0, 0.76, -0.56), RARE) -- a Rare-blue pearl on the trident
end

C.ClownChuckles = function(k)
	local SUIT = H("ffd23f")
	k:body({ skin = H("fff3e6"), shirt = SUIT, pants = SUIT, shoes = H("e02a2a"), sole = H("fff3e6"), hands = WHITE })
	cuffs(k, CUFF_LONG, H("ff4f9a"))
	for _, s in { -1, 1 } do
		k:brick(leg(s), V(D.legW + 0.12, 0.34, 0.7), V(s * LX, 0.17, -0.7), H("e02a2a")) -- giant shoes
		k:plate(leg(s), V(0.3, 0.3, 0.04), V(s * LX, 0.9, -D.legD / 2 - 0.03), if s < 0 then H("3a8bff") else H("ff4f9a"))
	end
	spots(k, { { -0.5, SH - 0.35, 0.3, H("ff4f9a") }, { 0.45, SH - 0.85, 0.3, H("3a8bff") }, { -0.2, HIP + 0.35, 0.28, H("5ae84a") }, { 0.55, HIP + 0.2, 0.24, H("b06aff") } })
	for i = 0, 9 do -- ruffle collar
		local a = math.rad(i * 36)
		k:brick("UpperTorso", V(0.34, 0.3, 0.34), V(math.cos(a) * 0.62, SH + 0.06, math.sin(a) * 0.5), WHITE)
	end
	k:bowtie(H("3a8bff"), { down = 0.32 })
	k:hair("afro", H("ff5a2a"))
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.6, 0.6, 0.6), V(s * 1.32, HY + 0.1, 0.25), if s < 0 then H("3a8bff") else H("5ae84a"))
	end
	face(k, H("3a3a3a"), { eyes = { w = 0.56, h = 0.62, look = Vector2.new(0, 0.3) }, brows = { raise = 0.1, tilt = -10 }, mouth = "grin", m = { w = 0.8, h = 0.3 } })
	k:brick("HeadDetail", V(0.34, 0.34, 0.3), V(0, HY - 0.22, FZ - 0.15), H("e8182e")) -- the red nose
	k:blush(H("ff7a9a"))
end

------------------------------------------------------------------ TIER 4 (Epic)
C.RetiredCEO = function(k)
	local VELVET, VELVET_D = H("7a1a2e"), H("5a1222")
	k:body({ skin = S1, shirt = VELVET, pants = H("2a2a34"), shoes = BLACK })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, VELVET_D)
	k:lapels(VELVET, WHITE, { depth = 0.85, lapel = EPIC }) -- Epic-purple lapels
	k:plate("UpperTorso", V(0.34, 0.4, 0.12), V(0, SH - 0.32, fz - 0.08), GOLD) -- cravat
	k:plate("UpperTorso", V(0.18, 0.16, 0.1), V(0, SH - 0.12, fz - 0.1), GOLD_D)
	k:buttons(2, GOLD, 0, HIP + 0.45, 0.28)
	for i = 0, 4 do -- watch chain + watch
		local t = (i - 2) / 2
		k:plate("UpperTorso", V(0.08, 0.08, 0.04), V(0.15 + i * 0.12, HIP + 0.42 - (1 - t * t) * 0.15, fz - 0.05), GOLD)
	end
	k:plate("UpperTorso", V(0.22, 0.22, 0.06), V(0.72, HIP + 0.4, fz - 0.05), GOLD)
	k:hair("tufts", H("f0f0f0"))
	k:mustache(H("f0f0f0"), "droopy", { w = 0.9 })
	face(k, H("e0e0e0"), { eyes = { lid = 0.25, look = Vector2.new(0, -0.1) }, brows = { tilt = 12, raise = 0.02 }, mouth = "flat", m = { y = -0.64, w = 0.36 } })
	k:glasses(GOLD)
	k:held(-1, V(0.13, 1.72, 0.13), V(0, -0.66, -0.45), BLACK) -- black cane, gold knob
	k:held(-1, V(0.28, 0.28, 0.28), V(0, 0.32, -0.45), GOLD)
end

C.TechTed = function(k)
	local TURTLE, JEANS = H("1e1e24"), H("3a5a9a")
	k:body({ skin = S4, shirt = TURTLE, pants = JEANS, shoes = WHITE, sole = H("d8d8e0") })
	k:brick("UpperTorso", V(1.2, 0.34, 1.0), V(0, SH + 0.08, 0.02), TURTLE) -- turtleneck
	k:belt(H("3a2a1e"), H("c8ccd6"))
	k:badge(EPIC, 0.58, SH - 0.55, Vector2.new(0.2, 0.2)) -- Epic-purple logo pin
	k:hair("short", H("8a8a94"), { top = 0.1 })
	face(k, H("6a6a74"), { eyes = { lid = 0.2 }, brows = { tilt = 2 }, m = { w = 0.4 } })
	k:glasses(H("2a2a2a"))
	k:held(1, V(0.72, 0.95, 0.06), V(0, 0.35, -0.48), H("2a2a34"), V(-10, 0, -8), true) -- tablet
	k:held(1, V(0.6, 0.82, 0.03), V(0, 0.35, -0.52), H("4fb6ff"), V(-10, 0, -8), true)
	local x = -(AX + D.armW / 2 + 0.14) -- robot vacuum under his right arm
	k:brick("RightUpperArm", V(0.24, 1.0, 1.0), V(x, 2.0, 0), H("3a3a46"))
	k:plate("RightUpperArm", V(0.04, 0.3, 0.3), V(x - 0.14, 2.0, -0.2), H("5ae84a"))
end

C.MovieStarMaya = function(k)
	local GOWN, GOWN_D, FUR, HAIR = H("d81e3a"), H("a8142a"), H("fbf6ee"), H("2a1810")
	k:body({ skin = S5, shirt = GOWN, pants = GOWN, sleeves = "none", legs = "skirt", skirtLen = 1.22, flare = 0.3, tights = GOWN, shoes = GOLD, sole = GOLD_D })
	local fz = k:frontZ()
	k:plate("UpperTorso", V(0.14, 1.0, 0.04), V(0.3, 0.75, -((k.td or D.torsoD) + 0.12 + 0.3) / 2 - 0.03), GOWN_D) -- slit fold
	-- the fur stole draped round her shoulders: chunky blocks resting ON the shoulders and arm tops (UpperTorso parts, so
	-- they don't swing), sitting below the chin so the head never pokes into them
	local td = k.td or D.torsoD
	for _, p in { V(-1.05, -0.1, 0), V(1.05, -0.1, 0), V(-0.62, 0.02, -td / 2 - 0.1), V(0.62, 0.02, -td / 2 - 0.1), V(-0.62, 0.02, td / 2 + 0.1), V(0.62, 0.02, td / 2 + 0.1), V(0, -0.02, td / 2 + 0.12) } do
		k:brick("UpperTorso", V(0.55, 0.4, 0.5), V(p.X, SH + p.Y, p.Z), FUR)
	end
	k:plate("UpperTorso", V(0.22, 0.22, 0.05), V(0, SH - 0.5, fz - 0.04), EPIC) -- Epic-purple gem
	k:hair("long", HAIR, { side = 1 })
	k:plate("HeadDetail", V(1.3, 0.26, 0.08), V(0, HT + 0.06, -0.85), INK, V(-35, 0, 0)) -- sunglasses up on her head
	face(k, HAIR, { eyes = { lid = 0.3, look = Vector2.new(0.3, 0.2) }, brows = { tilt = -4 }, m = { w = 0.44 } })
	k:held(-1, V(0.4, 0.2, 0.4), V(0, 0.05, -0.5), BLACK) -- golden star trophy
	k:held(-1, V(0.12, 0.45, 0.12), V(0, 0.36, -0.5), GOLD)
	for _, a in { 0, 72, 144 } do
		k:held(-1, V(0.5, 0.14, 0.1), V(0, 0.78, -0.5), GOLD, V(0, 0, a))
	end
end

C.KingReginald = function(k)
	local ROBE, ERMINE, TUNIC = H("c8203a"), H("fbf6ee"), H("e8c050")
	k:body({ skin = S2, shirt = ROBE, pants = TUNIC, shoes = H("6a2a8a"), torsoD = 1.15 })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, ERMINE)
	k:plate("UpperTorso", V(0.6, D.torsoH, 0.05), V(0, HIP + 0.75, fz - 0.02), TUNIC)
	k:coat(ROBE, 1.2, { open = true, gap = 0.6, hem = ERMINE })
	k:brick("UpperTorso", V(D.torsoW + 0.4, 0.4, (k.td or D.torsoD) + 0.3), V(0, SH - 0.02, 0), ERMINE) -- ermine collar
	for _, p in { V(-0.6, 0, -0.75), V(-0.2, 0, -0.75), V(0.2, 0, -0.75), V(0.6, 0, -0.75) } do
		k:plate("UpperTorso", V(0.08, 0.16, 0.05), V(p.X, SH - 0.02, p.Z), BLACK)
	end
	k:hair("tufts", WHITE)
	k:beard(WHITE, { length = 0.3 })
	k:crown(GOLD, H("e8182e"), {})
	k:plate("HeadDetail", V(0.14, 0.14, 0.05), V(-0.5, HT + 0.18, -(D.headD - 0.2) / 2 - 0.03), EPIC) -- Epic-purple jewels
	k:plate("HeadDetail", V(0.14, 0.14, 0.05), V(0.5, HT + 0.18, -(D.headD - 0.2) / 2 - 0.03), EPIC)
	face(k, H("e0e0e0"), { eyes = { lid = 0.15 }, brows = { tilt = -6 }, m = { y = -0.5, w = 0.4 } })
	k:held(-1, V(0.12, 1.3, 0.12), V(0, 0.3, -0.48), GOLD) -- sceptre (below the shoulder)
	k:held(-1, V(0.34, 0.1, 0.1), V(0, 0.82, -0.48), GOLD)
	k:held(-1, V(0.3, 0.3, 0.3), V(0, 1.02, -0.48), H("e8182e"))
end

C.AstronautAce = function(k)
	local SUIT, PATCH, PACK, HAIR = H("f2f2f4"), H("ff7a1a"), H("c8ccd6"), H("1a1410")
	k:body({ skin = S5, shirt = SUIT, pants = SUIT, shoes = H("8a929e"), sole = H("5a606e"), hands = PACK, torsoD = 1.15 })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, PATCH)
	k:boots(PACK, 0.4, PATCH)
	k:brick("UpperTorso", V(1.5, 1.6, 0.6), V(0, HIP + 0.85, (k.td or D.torsoD) / 2 + 0.3), PACK) -- life support pack
	k:plate("UpperTorso", V(0.7, 0.5, 0.05), V(0, HIP + 0.45, fz - 0.03), H("8a929e"))
	for i, c in { H("e04040"), H("4fb6ff"), H("5ae84a") } do
		k:plate("UpperTorso", V(0.1, 0.1, 0.04), V(-0.2 + (i - 1) * 0.2, HIP + 0.45, fz - 0.07), c)
	end
	k:badge(H("1f2f5c"), -0.5, SH - 0.55, Vector2.new(0.5, 0.36))
	k:plate("UpperTorso", V(0.36, 0.08, 0.03), V(-0.5, SH - 0.55, fz - 0.07), WHITE)
	k:badge(EPIC, 0.55, SH - 0.55, Vector2.new(0.24, 0.24)) -- Epic-purple mission pin
	k:armBand(SH - 0.35, 0.12, PATCH)
	k:hair("short", HAIR)
	face(k, HAIR, { eyes = { w = 0.56, h = 0.62, look = Vector2.new(0, 0.4) }, brows = { raise = 0.08, tilt = -8 }, mouth = "open", m = { w = 0.36, h = 0.26 } })
	k:brick("HeadDetail", V(D.headW + 0.5, 0.24, D.headD + 0.4), V(0, SH + 0.12, 0.02), PACK) -- helmet neck ring
	local glass = k:plate("HeadDetail", V(D.headW + 0.5, D.headH + 0.5, D.headD + 0.45), V(0, HY + 0.12, 0.02), H("dff4ff"))
	glass.Transparency = 0.75
	glass.CastShadow = false
	k:held(-1, V(0.07, 1.3, 0.07), V(0, 0.3, -0.48), H("c8ccd6")) -- flag
	k:held(-1, V(0.7, 0.46, 0.03), V(0.36, 0.7, -0.48), H("4fb6ff"), nil, true)
	k:held(-1, V(0.2, 0.2, 0.04), V(0.36, 0.7, -0.51), WHITE, nil, true)
end

------------------------------------------------------------------ TIER 5 (Legendary): gold trim + a Neon touch
C.ChefMega = function(k)
	local SCARF, HAIR = H("d92a3a"), H("1a1a1a")
	k:body({ skin = H("8d5a3b"), shirt = WHITE, pants = H("2a2a34"), shoes = BLACK, torsoD = 1.15 })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, GOLD)
	k:brick("UpperTorso", V(1.6, 0.8, 0.2), V(0, HIP + 0.45, fz - 0.08), WHITE) -- belly
	for _, x in { -0.36, 0.36 } do -- double-breasted gold buttons (above the belly, then on it)
		k:plate("UpperTorso", V(0.12, 0.12, 0.05), V(x, SH - 0.45, fz - 0.04), GOLD)
		k:plate("UpperTorso", V(0.12, 0.12, 0.05), V(x, HIP + 0.6, fz - 0.2), GOLD)
		k:plate("UpperTorso", V(0.12, 0.12, 0.05), V(x, HIP + 0.3, fz - 0.2), GOLD)
	end
	k:wedge("UpperTorso", V(0.8, 0.36, 0.1), V(0, SH - 0.2, fz - 0.07), SCARF, V(0, 180, 180), false)
	k:brick("UpperTorso", V(1.2, 0.14, (k.td or D.torsoD) + 0.04), V(0, SH, 0), SCARF)
	for _, a in { 0, 72, 144 } do
		k:plate("UpperTorso", V(0.34, 0.1, 0.05), V(0.58, SH - 0.6, fz - 0.06), GOLD, V(0, 0, a)) -- star badge
	end
	for _, s in { -1, 1 } do -- checked trousers
		for _, y in { 0.55, 0.95 } do
			k:plate(leg(s), V(0.2, 0.2, 0.04), V(s * LX - 0.2, y, -D.legD / 2 - 0.02), WHITE)
			k:plate(leg(s), V(0.2, 0.2, 0.04), V(s * LX + 0.2, y + 0.2, -D.legD / 2 - 0.02), WHITE)
		end
	end
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:chefHat(WHITE, 1.6)
	k:plate("HeadDetail", V(D.headW + 0.18, 0.08, D.headD + 0.18), V(0, HT - 0.02, 0), GOLD) -- gold band
	k:mustache(HAIR, "curly", { w = 0.6 })
	face(k, HAIR, { eyes = { lid = 0.15, y = -0.04 }, brows = { y = -0.04, tilt = -4 }, mouth = "grin", m = { y = -0.64, w = 0.5 } })
	k:held(-1, V(0.09, 1.0, 0.09), V(0, 0.35, -0.5), GOLD, V(0, 0, 10)) -- golden ladle
	k:held(-1, V(0.44, 0.3, 0.44), V(-0.12, 0.9, -0.5), GOLD)
	k:glow("RightUpperArm", V(0.14, 0.14, 0.04), k:hand(-1) + V(-0.12, 0.92, -0.74), H("fff4a0"))
end

C.RocketBaronRex = function(k)
	local SUIT, STRIPE, PACK = H("c8ccd6"), H("ff7a1a"), H("8a929e")
	k:body({ skin = S3, shirt = SUIT, pants = SUIT, shoes = STRIPE, sole = H("3a3a44"), hands = H("3a3a44") })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, STRIPE)
	k:plate("UpperTorso", V(0.2, 2.0, 0.05), V(0, HIP + 0.72, fz - 0.03), STRIPE, V(0, 0, 32))
	local bz = (k.td or D.torsoD) / 2 + 0.3
	for _, s in { -1, 1 } do
		k:plate(leg(s), V(0.06, 0.9, 0.1), V(s * (LX + D.legW / 2 + 0.02), HIP - 0.5, 0), STRIPE)
		k:brick("UpperTorso", V(0.5, 1.3, 0.5), V(s * 0.4, HIP + 0.8, bz), PACK) -- jetpack tanks
		k:brick("UpperTorso", V(0.36, 0.25, 0.36), V(s * 0.4, HIP + 0.02, bz), H("e02a2a"))
		k:brick("UpperTorso", V(0.44, 0.2, 0.44), V(s * 0.4, HIP + 1.55, bz), GOLD)
		k:glow("UpperTorso", V(0.2, 0.3, 0.2), V(s * 0.4, HIP - 0.27, bz), H("ffb030")) -- flame
	end
	k:badge(H("1f2f5c"), -0.5, SH - 0.6, Vector2.new(0.56, 0.56))
	k:plate("UpperTorso", V(0.2, 0.2, 0.04), V(-0.5, SH - 0.6, fz - 0.08), STRIPE)
	k:hair("side", H("c8502a"), { side = 1 })
	k:headband(H("6b4426"), 0.3) -- goggles
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.44, 0.4, 0.16), V(s * 0.38, HT - 0.3, FZ - 0.08), H("6b4426"))
		k:plate("HeadDetail", V(0.32, 0.28, 0.04), V(s * 0.38, HT - 0.3, FZ - 0.17), H("ffc83a"))
	end
	face(k, H("a83a1a"), { eyes = { y = -0.1, look = Vector2.new(0, 0.3) }, brows = { y = -0.12, tilt = -8 }, mouth = "grin", m = { w = 0.58 } })
	k:held(1, V(0.36, 0.8, 0.36), V(0, 0.4, -0.5), WHITE) -- toy rocket
	k:held(1, V(0.36, 0.3, 0.36), V(0, 0.93, -0.5), H("e02a2a"))
	for _, s in { -1, 1 } do
		k:held(1, V(0.08, 0.3, 0.3), V(s * 0.22, 0.1, -0.5), H("e02a2a"))
	end
	k:held(1, V(0.16, 0.16, 0.04), V(0, 0.5, -0.69), H("4fb6ff"), nil, true)
end

C.MiloVex = function(k)
	local PINK, PINK_D = H("ff4fa8"), H("d83088")
	k:body({ skin = S1, shirt = PINK, pants = BLACK, shoes = WHITE, sole = H("d8d8e0") })
	cuffs(k, CUFF_LONG, PINK_D)
	k:lapels(PINK, WHITE, { depth = 1.1, lapel = GOLD })
	k:buttons(1, BLACK, 0, HIP + 0.3)
	k:badge(WHITE, 0.62, SH - 0.5, Vector2.new(0.3, 0.14))
	k:hair("side", H("f2d060"), { side = -1 })
	face(k, H("c8a040"), { eyes = { lid = 0.1 }, brows = { tilt = 4 }, m = { w = 0.4 } })
	k:glasses(PINK, { sun = true, lens = H("ff8ac8") })
	k:glow("HeadDetail", V(0.12, 0.06, 0.03), V(-0.3, HY + 0.2, FZ - 0.17), WHITE) -- a glint
	for i, c in { H("ff8ac8"), BLACK } do -- shopping bags
		local x = -0.1 + (i - 1) * 0.3
		k:held(-1, V(0.6, 0.7, 0.36), V(x, -0.58, -0.15 - (i - 1) * 0.12), c)
		k:held(-1, V(0.06, 0.3, 0.3), V(x, -0.12, -0.15 - (i - 1) * 0.12), c)
	end
end

C.DJBeatbox = function(k)
	local HOOD, NEON, HAIR = H("1e1e26"), H("ff3cc8"), H("1a1a1a")
	k:body({ skin = S6, shirt = HOOD, pants = HOOD, shoes = WHITE, sole = NEON })
	local fz = k:frontZ()
	cuffs(k, CUFF_LONG, NEON)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.1, D.torsoH - 0.1, 0.04), V(s * 0.66, HIP + 0.72, fz - 0.03), NEON)
		k:plate(arm(s), V(0.06, 0.78, 0.12), V(s * (AX + D.armW / 2 + 0.02), SH - 0.6, 0), NEON)
	end
	k:brick("UpperTorso", V(1.4, 0.5, 0.35), V(0, SH + 0.05, 0.72), H("2a2a34")) -- hood
	for i = -3, 3 do -- gold chain + medallion with a Neon gem
		local t = i / 3
		k:plate("UpperTorso", V(0.1, 0.1, 0.05), V(t * 0.38, SH - 0.12 - (1 - t * t) * 0.42, fz - 0.07), GOLD)
	end
	k:plate("UpperTorso", V(0.32, 0.32, 0.06), V(0, SH - 0.66, fz - 0.08), GOLD)
	k:glow("UpperTorso", V(0.14, 0.14, 0.03), V(0, SH - 0.66, fz - 0.12), NEON)
	k:hair("short", HAIR, { hat = true, noTop = true })
	k:cap(BLACK, NEON, { backwards = true, down = 0.34 })
	local hw = D.headW / 2 -- big headphones over the cap
	k:brick("HeadDetail", V(D.headW + 0.36, 0.14, 0.36), V(0, HT + 0.36, 0.05), H("3a3a46"))
	for _, s in { -1, 1 } do
		k:brick("HeadDetail", V(0.14, 0.5, 0.32), V(s * (hw + 0.2), HT + 0.05, 0.05), H("3a3a46"))
		k:brick("HeadDetail", V(0.3, 0.72, 0.72), V(s * (hw + 0.16), HY + 0.05, 0.05), BLACK)
		k:plate("HeadDetail", V(0.04, 0.42, 0.42), V(s * (hw + 0.32), HY + 0.05, 0.05), NEON)
	end
	face(k, HAIR, { eyes = { y = -0.02, lid = 0.35 }, brows = { y = -0.02, tilt = 2 }, mouth = "grin", m = { w = 0.52 } })
	k:held(1, V(0.05, 0.95, 0.95), V(0, 0.35, -0.5), BLACK, nil, true) -- vinyl record
	k:held(1, V(0.06, 0.32, 0.32), V(0, 0.35, -0.53), NEON, nil, true)
end

C.KikiGlow = function(k)
	local DRESS, DRESS_D, HAIR = H("c8a8f0"), H("a888e0"), H("ff8ad0")
	k:body({ skin = S1, shirt = DRESS, pants = DRESS, sleeves = "none", legs = "skirt", skirtLen = 1.22, flare = 0.4, tights = DRESS, shoes = H("ff8ad0"), sole = WHITE })
	local fz = k:frontZ()
	k:torsoBand(HIP + 0.25, 0.14, DRESS_D)
	local skirtZ = -((k.td or D.torsoD) + 0.12 + 0.4) / 2 - 0.03
	for i, p in { { -0.5, SH - 0.3 }, { 0.4, SH - 0.8 }, { -0.2, HIP + 0.55 }, { 0.6, HIP - 0.25 }, { -0.6, HIP - 0.6 }, { 0.2, HIP - 0.9 } } do
		local z = if p[2] < HIP then skirtZ else fz - 0.03
		if i <= 2 then
			k:glow("UpperTorso", V(0.13, 0.13, 0.04), V(p[1], p[2], z), WHITE, V(0, 0, 45)) -- sparkles (two glow)
		else
			k:plate("UpperTorso", V(0.13, 0.13, 0.04), V(p[1], p[2], z), WHITE, V(0, 0, 45))
		end
	end
	k:hair("long", HAIR, { side = 1 })
	k:crown(GOLD, H("ff6ad0"), { w = 1.2, d = 1.1, lift = 0.1 }) -- gold tiara
	face(k, H("d86aa8"), { eyes = { look = Vector2.new(0, 0.4) }, brows = { tilt = -6 }, mouth = "grin", m = { w = 0.5 } })
	k:blush()
	k:held(-1, V(0.1, 0.5, 0.1), V(0, 0.2, -0.48), GOLD) -- hand mirror
	k:held(-1, V(0.6, 0.6, 0.08), V(0, 0.72, -0.48), GOLD)
	k:held(-1, V(0.46, 0.46, 0.05), V(0, 0.72, -0.53), H("d8f0ff"), nil, true)
end

return C
