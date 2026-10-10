-- Octo-Attorney (Rare, Ocean egg) - block remake 2026-10-10. A small purple octopus in a dark suit (deliberately
-- unlike the Kraken: smaller, purple, office-y): round dome head with spots, big eyes behind square black glasses,
-- a dark jacket with a white shirt + purple tie, six curling tentacles below the jacket hem, two tentacle arms - one
-- with a briefcase, one with a fountain pen. Front-facing. Rare: Neon purple lapel pin, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("OctoAttorney")
local V = Vector3.new
local C = Kit.C
local PURPLE, PURPLE_DARK, SPOT, SUCKER = Color3.fromHex("aa50be"), Color3.fromHex("82389a"), Color3.fromHex("c97ad8"), Color3.fromHex("e8b8f0")
local SUIT, SUIT_DARK, CASE = Color3.fromHex("28283c"), Color3.fromHex("1c1c2a"), Color3.fromHex("7a4a26")
local T, H = "UpperTorso", "Head"

-- six tentacles curling out from under the jacket
for i = 0, 5 do
	local deg = -150 + i * 60
	local a = math.rad(deg)
	local base = CFrame.Angles(0, a, 0)
	local name = (if deg < 0 then "Left" else "Right") .. "UpperLeg"
	b:BAt(name, V(0.36, 0.6, 0.36), base * CFrame.new(0, 0.75, -0.5) * CFrame.Angles(math.rad(25), 0, 0), PURPLE)
	b:BAt(name, V(0.3, 0.45, 0.3), base * CFrame.new(0, 0.32, -0.78) * CFrame.Angles(math.rad(60), 0, 0), PURPLE)
	b:BAt(name, V(0.24, 0.3, 0.24), base * CFrame.new(0, 0.3, -1.1) * CFrame.Angles(math.rad(140), 0, 0), PURPLE_DARK)
	if math.abs(deg) < 90 then
		b:BAt("HeadDetail", V(0.12, 0.12, 0.05), base * CFrame.new(0, 0.7, -0.7) * CFrame.Angles(math.rad(25), 0, 0), SUCKER)
	end
end
-- suit jacket: dark body, white shirt V, purple tie, lapels, hem
b:B(T, V(1.4, 1.1, 1.1), V(0, 1.55, 0), SUIT)
b:B(T, V(1.44, 0.14, 1.14), V(0, 1.03, 0), SUIT_DARK)
b:B("HeadDetail", V(0.45, 0.7, 0.05), V(0, 1.75, -0.56), C.White)
b:B("HeadDetail", V(0.14, 0.55, 0.04), V(0, 1.7, -0.6), PURPLE)
b:B("HeadDetail", V(0.2, 0.12, 0.04), V(0, 2.02, -0.6), PURPLE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.14, 0.6, 0.05), V(s * 0.3, 1.8, -0.57), SUIT_DARK, V(0, 0, s * 15))
end
b:B("HeadDetail", V(0.12, 0.12, 0.05), V(0.42, 1.85, -0.6), Color3.fromHex("d77aff"), V(0, 0, 45), Enum.Material.Neon)
-- dome head with spots
b:B(H, V(1.6, 1.3, 1.45), V(0, 2.75, 0), PURPLE)
b:B(H, V(1.3, 0.45, 1.2), V(0, 3.55, 0), PURPLE)
b:B(H, V(0.8, 0.2, 0.8), V(0, 3.85, 0), PURPLE)
for _, sp in { { -0.45, 3.55, -0.61 }, { 0.35, 3.7, -0.5 }, { 0.65, 3.2, -0.74 } } do
	b:B("HeadDetail", V(0.2, 0.16, 0.05), V(sp[1], sp[2], sp[3]), SPOT)
end
-- face: big eyes behind square glasses, small smile
for _, s in { -1, 1 } do
	b:eye(V(s * 0.36, 2.85, -0.74), 0.4, V(0, 0, -1), Vector2.new(0, 0))
	for _, e in { { 0, 0.27, 0.56, 0.06 }, { 0, -0.27, 0.56, 0.06 }, { 0.27, 0, 0.06, 0.56 }, { -0.27, 0, 0.06, 0.56 } } do
		b:B("HeadDetail", V(e[3], e[4], 0.05), V(s * 0.36 + e[1], 2.85 + e[2], -0.79), C.Line)
	end
end
b:B("HeadDetail", V(0.16, 0.05, 0.05), V(0, 2.88, -0.79), C.Line) -- glasses bridge
b:mouth(V(0, 2.38, -0.74), 0.34, 0.1, V(0, 0, -1), 0, 18)
-- tentacle arms out of the sleeves
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.4, 0.4, 0.45), V(s * 0.85, 1.85, 0), SUIT)
	b:B(name, V(0.3, 0.7, 0.3), V(s * 1.05, 1.4, -0.1), PURPLE, V(0, 0, s * 15))
	b:B(name, V(0.26, 0.3, 0.26), V(s * 1.15, 1.02, -0.15), PURPLE_DARK)
end
b:B("RightUpperArm", V(0.24, 0.1, 0.08), V(1.15, 0.85, -0.15), C.Line)
b:B("RightUpperArm", V(0.7, 0.5, 0.2), V(1.15, 0.55, -0.15), CASE)
b:B("RightUpperArm", V(0.12, 0.1, 0.03), V(1.15, 0.66, -0.26), C.Gold)
b:B("LeftUpperArm", V(0.08, 0.55, 0.08), V(-1.18, 1.28, -0.3), C.Line, V(25, 0, -20)) -- fountain pen
b:B("LeftUpperArm", V(0.09, 0.12, 0.09), V(-1.27, 1.52, -0.42), C.Gold, V(25, 0, -20))
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
