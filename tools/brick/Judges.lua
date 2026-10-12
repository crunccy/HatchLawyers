-- The courtroom judges in the brick style (2026-10-11, docs/CHARACTER_STYLE.md): ReplicatedStorage.JudgeModels.
-- Each keeps its old look (robe colour, hair, glasses, trim) on BrickKit's frame: a robe to the ankles, a white
-- jabot, and the gavel in the +X hand inside a GavelArm model (Courtroom.client slams it).
-- Run: tools/brick/Run.lua with _G.BrickRun = { file = this, kind = "judge", ids = {...} }.
local Kit = require(game.ServerStorage.BrickKit:Clone()) :: any
local V, H = Vector3.new, Kit.hex
local D = Kit.D
local HIP, SH, HY, HT, FZ = Kit.hipY, Kit.shoulderY, Kit.headY, Kit.headTop, Kit.faceZ
local WHITE, INK, GOLD = Kit.C.White, Kit.C.Ink, Kit.C.Gold
local SHOES = H("0a0a0c")

local J = {}

-- the shared judge body: robe, jabot, stern face basics; returns the front z
local function judge(k, robe: Color3, skin: Color3, o: { [string]: any }?)
	local opt = o or {}
	k:body({ skin = skin, shirt = robe, pants = SHOES, shoes = SHOES })
	k:robe(robe, { open = opt.open, trim = opt.trim, gap = 0.34 })
	local fz = k:frontZ()
	-- the jabot: two white tabs under the chin
	k:plate("UpperTorso", V(0.5, 0.24, 0.06), V(0, SH - 0.14, fz - 0.05), WHITE)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.2, 0.42, 0.05), V(s * 0.11, SH - 0.42, fz - 0.06), WHITE, V(0, 0, s * 4))
	end
	k:nose()
	return fz
end

-- Judge Harold: the classic - black robe, white barrister's wig, black square glasses, stern
J.JudgeHarold = function(k)
	k.displayName = "Judge Harold"
	local SKIN = H("cd8769")
	judge(k, H("16161a"), SKIN)
	k:wig(H("f0f0ec"))
	k:eyes({ look = Vector2.new(0, -0.2) })
	k:glasses(INK)
	k:brows(H("8a8a92"), { tilt = 8, raise = 0.04 })
	k:mouth("flat", { w = 0.4 })
	k:gavelArm(H("5f2d12"))
end

-- Judge Maria: red robe with two white bands down the front and a gold chain of office, dark hair in a bun
J.JudgeMaria = function(k)
	k.displayName = "Judge Maria"
	local SKIN, HAIR = H("aa6e48"), H("2d190f")
	local fz = judge(k, H("a5141e"), SKIN)
	for _, s in { -1, 1 } do
		k:plate("UpperTorso", V(0.16, D.torsoH - 0.2, 0.04), V(s * 0.5, HIP + (D.torsoH - 0.2) / 2, fz - 0.03), WHITE)
	end
	for _, p in { Vector2.new(0.7, -0.06), Vector2.new(0.42, -0.3), Vector2.new(0.18, -0.52) } do -- the chain of office
		for _, s in { -1, 1 } do
			k:plate("UpperTorso", V(0.16, 0.14, 0.05), V(s * p.X, SH + p.Y, fz - 0.06), GOLD)
		end
	end
	k:plate("UpperTorso", V(0.3, 0.3, 0.05), V(0, SH - 0.75, fz - 0.07), GOLD)
	k:hair("bun", HAIR, { fringe = 0 })
	for _, s in { -1, 1 } do -- gold earrings
		k:plate("HeadDetail", V(0.05, 0.16, 0.12), V(s * (D.headW / 2 + 0.03), HY - 0.35, -0.2), GOLD)
	end
	k:eyes({})
	k:brows(HAIR, { tilt = 6 })
	k:mouth("flat", { w = 0.38 })
	k:gavelArm(H("5f2d12"))
end

-- Judge Okafor: navy robe with gold stripes on the sleeves, short grey hair and a grey beard
J.JudgeOkafor = function(k)
	k.displayName = "Judge Okafor"
	local SKIN, GREY = H("583420"), H("6e6e72")
	judge(k, H("142369"), SKIN)
	for _, s in { -1, 1 } do
		for _, dy in { 0.0, 0.18 } do
			k:plate(Kit.armName(s), V(D.armW + 0.24, 0.07, D.armD + 0.24), V(s * Kit.armX, SH - D.armH + D.handH + 0.28 + dy, 0), GOLD)
		end
	end
	k:hair("short", GREY, { top = 0.1 })
	k:beard(GREY, { length = 0.2 })
	k:eyes({})
	k:brows(GREY, { tilt = 6 })
	k:mouth("flat", { w = 0.36, y = -0.5 })
	k:gavelArm(H("5f2d12"))
end

-- Judge Mei: purple robe with a gold front trim, long straight black hair, red glasses
J.JudgeMei = function(k)
	k.displayName = "Judge Mei"
	local SKIN, HAIR = H("e8ba98"), H("0e0e12")
	local fz = judge(k, H("6923a0"), SKIN)
	k:plate("UpperTorso", V(0.1, D.torsoH - 0.6, 0.04), V(0, HIP + (D.torsoH - 0.6) / 2, fz - 0.03), GOLD)
	k:hair("long", HAIR, { side = 1 })
	k:eyes({})
	k:glasses(H("d83a3a"))
	k:brows(HAIR, { tilt = 6 })
	k:mouth("flat", { w = 0.34 })
	k:gavelArm(H("5f2d12"), H("ffaa28"))
end

-- Judge Rosa: green robe with a gold front trim, silver curly hair, a ruffled jabot
J.JudgeRosa = function(k)
	k.displayName = "Judge Rosa"
	local SKIN, SILVER = H("875537"), H("d7d7de")
	local fz = judge(k, H("14783c"), SKIN)
	k:plate("UpperTorso", V(0.1, D.torsoH - 0.6, 0.04), V(0, HIP + (D.torsoH - 0.6) / 2, fz - 0.03), H("e1c36e"))
	for i = 0, 2 do -- the ruffle
		k:plate("UpperTorso", V(0.62 - i * 0.1, 0.12, 0.08), V(0, SH - 0.2 - i * 0.13, fz - 0.1), WHITE)
	end
	k:hair("curly", SILVER)
	k:eyes({})
	k:brows(SILVER, { tilt = 4 })
	k:mouth("smile", { w = 0.36 })
	k:gavelArm(H("5f2d12"), H("e1c36e"))
end

return J
