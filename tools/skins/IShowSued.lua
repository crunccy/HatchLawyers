-- IShowSued (Legendary) - block remake 2026-10-10. A GENERIC hype-streamer lawyer (original design - deliberately no
-- real person's likeness): big cartoon head with a shouting open mouth and wide eyes, short dark hair cap, a black
-- gaming headset with a gold boom mic, a red tracksuit-style jacket with green sleeve stripes, a gold chain, both arms
-- up celebrating with a gold-trimmed football in one hand, white sneakers with gold soles, a floating red "REC" light.
-- Front-facing. Legendary: gold + Neon REC light, 1.2x. Colours follow the catalog entry (Config.Lawyers IShowSued).
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("IShowSued")
local V = Vector3.new
local C = Kit.C
local SKIN, HAIR = Color3.fromRGB(120, 78, 54), Color3.fromHex("1c1c20")
local JACKET, JACKET_DARK, STRIPE = Color3.fromRGB(200, 18, 40), Color3.fromHex("9e0e22"), Color3.fromRGB(20, 140, 70)
local PANTS, HEADSET, REC = Color3.fromRGB(30, 30, 34), Color3.fromHex("26262c"), Color3.fromHex("ff2e3e")
local NEON = Enum.Material.Neon
local T, H = "UpperTorso", "Head"

-- legs + white sneakers with gold soles
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.52, 1.3, 0.55), V(s * 0.34, 1.05, 0), PANTS)
	b:B(name, V(0.62, 0.32, 0.88), V(s * 0.36, 0.22, -0.12), C.White)
	b:B(name, V(0.64, 0.08, 0.9), V(s * 0.36, 0.04, -0.12), C.Gold)
	b:B(name, V(0.4, 0.06, 0.3), V(s * 0.36, 0.39, -0.3), STRIPE) -- laces/flash
end
-- tracksuit jacket: red body, darker hem, white zip, collar
b:B(T, V(1.6, 1.5, 0.9), V(0, 2.45, 0), JACKET)
b:B(T, V(1.64, 0.2, 0.94), V(0, 1.78, 0), JACKET_DARK)
b:B(T, V(0.06, 1.4, 0.04), V(0, 2.45, -0.47), C.White)
b:B(T, V(1.0, 0.18, 0.96), V(0, 3.18, 0), JACKET_DARK)
-- gold chain + medallion
for i = -2, 2 do
	b:B("HeadDetail", V(0.16, 0.08, 0.05), V(i * 0.18, 3.0 - (2 - math.abs(i)) * 0.1, -0.48), C.Gold)
end
b:B("HeadDetail", V(0.3, 0.3, 0.06), V(0, 2.65, -0.5), C.Gold, V(0, 0, 45))
b:B("HeadDetail", V(0.14, 0.14, 0.05), V(0, 2.65, -0.54), C.GoldDark, V(0, 0, 45))
-- arms up celebrating (a "V"), green stripes down the sleeves
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	local sh = V(s * 0.95, 3.0, 0)
	b:B(name, V(0.42, 0.9, 0.46), sh + V(s * 0.28, 0.3, 0), JACKET, V(0, 0, -s * 35))
	b:B(name, V(0.12, 0.92, 0.48), sh + V(s * 0.46, 0.18, 0), STRIPE, V(0, 0, -s * 35)) -- stripe down the outer side
	b:B(name, V(0.4, 0.8, 0.44), sh + V(s * 0.55, 1.0, 0), JACKET, V(0, 0, -s * 10))
	b:B(name, V(0.42, 0.14, 0.46), sh + V(s * 0.6, 1.42, 0), C.White)                 -- cuff
	b:B(name, V(0.38, 0.38, 0.38), sh + V(s * 0.62, 1.66, 0), SKIN)                   -- fist
end
-- the football held up in the -X fist: white with black patches, gold seam (Legendary)
local ball = V(-1.57, 5.15, -0.05)
b:B("LeftUpperArm", V(0.62, 0.62, 0.62), ball, C.White)
b:B("LeftUpperArm", V(0.7, 0.5, 0.5), ball, C.White)
b:B("LeftUpperArm", V(0.5, 0.7, 0.5), ball, C.White)
b:B("LeftUpperArm", V(0.2, 0.2, 0.05), ball + V(0, 0, -0.34), HAIR)
b:B("LeftUpperArm", V(0.05, 0.2, 0.2), ball + V(0.36, 0.1, 0), HAIR)
b:B("LeftUpperArm", V(0.05, 0.2, 0.2), ball + V(-0.36, -0.1, 0), HAIR)
b:B("LeftUpperArm", V(0.2, 0.05, 0.2), ball + V(0, 0.36, 0.1), HAIR)
b:B("LeftUpperArm", V(0.72, 0.05, 0.05), ball + V(0, -0.15, -0.3), C.Gold)
-- big cartoon head, short dark hair cap
b:B(H, V(1.4, 1.35, 1.25), V(0, 3.95, 0), SKIN)
b:B(H, V(1.44, 0.24, 1.3), V(0, 4.6, 0.02), HAIR)
b:B(H, V(1.44, 0.4, 0.2), V(0, 4.35, 0.6), HAIR)
for _, s in { -1, 1 } do
	b:B(H, V(0.12, 0.3, 0.5), V(s * 0.71, 4.38, 0.25), HAIR)
	b:B(H, V(0.16, 0.3, 0.24), V(s * 0.72, 3.95, 0), SKIN) -- ears (under the headset cups)
end
-- face: wide hyped eyes, raised brows, big shouting mouth
for _, s in { -1, 1 } do
	b:eye(V(s * 0.32, 4.08, -0.63), 0.42, V(0, 0, -1), Vector2.new(0, 0.04))
	b:brow(V(s * 0.34, 4.36, -0.64), 0.4, V(0, 0, -1), 0, HAIR) -- high, flat: hyped
end
b:mouth(V(0, 3.6, -0.63), 0.56, 0.32, V(0, 0, -1), 6, 0)
b:B("HeadDetail", V(0.3, 0.1, 0.04), V(0, 3.5, -0.655), C.Tongue)
-- gaming headset: band over the hair, big ear cups, gold boom mic to the mouth
b:B(H, V(1.56, 0.14, 0.26), V(0, 4.78, 0), HEADSET)
for _, s in { -1, 1 } do
	b:B(H, V(0.14, 0.7, 0.26), V(s * 0.78, 4.45, 0), HEADSET)
	b:B(H, V(0.22, 0.56, 0.56), V(s * 0.82, 3.98, 0), HEADSET)
	b:B(H, V(0.06, 0.3, 0.3), V(s * 0.94, 3.98, 0), REC, nil, NEON) -- glowing cup ring
end
b:B(H, V(0.08, 0.08, 0.55), V(-0.84, 3.7, -0.4), C.Gold)
b:B(H, V(0.4, 0.08, 0.08), V(-0.66, 3.62, -0.66), C.Gold)
b:B(H, V(0.16, 0.16, 0.16), V(-0.44, 3.62, -0.68), HEADSET)
-- floating REC light above the head
b:B(H, V(0.7, 0.3, 0.1), V(0.55, 5.35, 0), HEADSET)
b:B(H, V(0.2, 0.2, 0.06), V(0.35, 5.35, -0.06), REC, nil, NEON)
b:B(H, V(0.3, 0.08, 0.06), V(0.68, 5.35, -0.06), C.White)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.2)
print(b:preview())
_G.SkinBuild = b
