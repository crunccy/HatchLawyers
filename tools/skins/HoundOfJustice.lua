-- Thunder Hound (Legendary) - block remake 2026-10-10. A four-legged bloodhound standing side-on (body along X)
-- with its head turned to the viewer: tan coat with a dark saddle, long droopy ears, saggy jowls, sad-wise eyes,
-- a brown checked detective cap, a red collar with a big gold star badge, a short red cape. Legendary: gold badge +
-- cape clasp/hem, 1.45x. Sideways.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("HoundOfJustice")
local V = Vector3.new
local C = Kit.C
local TAN, TAN_LIGHT, SADDLE, EAR = Color3.fromHex("c98a4b"), Color3.fromHex("e2b07a"), Color3.fromHex("7a4a26"), Color3.fromHex("6b3d1e")
local NOSE, RED, RED_DARK = Color3.fromHex("1c1c20"), Color3.fromHex("c8282e"), Color3.fromHex("8e1a1f")
local CAP, CAP_CHECK = Color3.fromHex("8a6a44"), Color3.fromHex("6b4f30")
local T, H = "UpperTorso", "Head"

-- body (along X), saddle on the back, chest
b:B(T, V(2.6, 1.25, 1.2), V(-0.1, 1.75, 0), TAN)
b:B(T, V(2.1, 0.3, 1.24), V(-0.3, 2.3, 0), SADDLE)
b:B(T, V(0.6, 1.0, 1.0), V(1.15, 1.6, 0), TAN_LIGHT)
-- legs + paws (front pair at +X)
for _, x in { -1.0, 0.9 } do
	for _, z in { -0.38, 0.38 } do
		local name = (if z < 0 then "Left" else "Right") .. (if x > 0 then "UpperArm" else "UpperLeg")
		b:B(name, V(0.38, 1.0, 0.38), V(x, 0.62, z), TAN)
		b:B(name, V(0.46, 0.2, 0.52), V(x + 0.04, 0.1, z - 0.03), TAN_LIGHT)
	end
end
-- tail, wagging up
b:B(T, V(0.2, 0.8, 0.2), V(-1.55, 2.5, 0), TAN, V(0, 0, 35))
b:B(T, V(0.16, 0.3, 0.16), V(-1.8, 2.88, 0), TAN_LIGHT, V(0, 0, 35))
-- neck + head (turned to the viewer, -Z)
b:B(H, V(0.7, 0.7, 0.8), V(1.25, 2.4, -0.1), TAN)
b:B(H, V(1.2, 1.1, 1.1), V(1.4, 2.95, -0.2), TAN)
b:B(H, V(1.0, 0.18, 1.0), V(1.4, 3.55, -0.2), SADDLE) -- dark crown of the head
-- snout, nose, jowls
b:B(H, V(0.8, 0.55, 0.5), V(1.4, 2.62, -0.95), TAN_LIGHT)
b:B(H, V(0.36, 0.22, 0.12), V(1.4, 2.86, -1.22), NOSE)
for _, s in { -1, 1 } do
	b:B(H, V(0.24, 0.42, 0.42), V(1.4 + s * 0.42, 2.4, -0.95), TAN_LIGHT)
end
b:mouth(V(1.4, 2.48, -1.21), 0.46, 0.1, V(0, 0, -1), 0, 8)
-- eyes: a little droopy (lids), wise brows
for _, s in { -1, 1 } do
	b:eye(V(1.4 + s * 0.27, 3.1, -0.76), 0.36, V(0, 0, -1), Vector2.new(0, -0.05))
	b:B("HeadDetail", V(0.38, 0.12, 0.04), V(1.4 + s * 0.27, 3.24, -0.79), SADDLE) -- heavy lid
	b:brow(V(1.4 + s * 0.29, 3.38, -0.77), 0.36, V(0, 0, -1), s * -14, SADDLE)
end
-- long droopy ears
for _, s in { -1, 1 } do
	b:B(H, V(0.18, 1.1, 0.55), V(1.4 + s * 0.68, 2.62, -0.15), EAR)
	b:B(H, V(0.18, 0.3, 0.45), V(1.4 + s * 0.68, 2.0, -0.1), EAR)
end
-- detective cap: checked crown, front + back brims, gold button
b:B(H, V(1.1, 0.34, 1.06), V(1.4, 3.8, -0.2), CAP)
b:B(H, V(0.12, 0.35, 1.08), V(1.2, 3.8, -0.2), CAP_CHECK)
b:B(H, V(0.12, 0.35, 1.08), V(1.6, 3.8, -0.2), CAP_CHECK)
b:B(H, V(0.8, 0.1, 0.4), V(1.4, 3.66, -0.85), CAP)
b:B(H, V(0.8, 0.1, 0.4), V(1.4, 3.66, 0.45), CAP)
b:B(H, V(0.16, 0.1, 0.16), V(1.4, 4.02, -0.2), C.Gold)
-- red collar + big gold star badge facing the viewer
b:B(T, V(0.24, 0.3, 0.9), V(1.15, 2.2, -0.1), RED)
b:B("HeadDetail", V(0.42, 0.42, 0.06), V(1.2, 1.95, -0.62), C.Gold, V(0, 0, 45))
b:B("HeadDetail", V(0.42, 0.42, 0.06), V(1.2, 1.95, -0.62), C.Gold)
b:B("HeadDetail", V(0.2, 0.2, 0.04), V(1.2, 1.95, -0.66), C.GoldDark)
-- short red cape over the back with a gold clasp
b:B(T, V(1.8, 0.1, 1.36), V(-0.25, 2.48, 0), RED)
for _, z in { -0.66, 0.66 } do
	b:B(T, V(1.8, 0.5, 0.08), V(-0.25, 2.2, z), RED)
	b:B(T, V(1.8, 0.08, 0.1), V(-0.25, 1.93, z), C.Gold) -- gold trim along the cape hem
end
b:B(T, V(0.22, 0.22, 0.22), V(0.7, 2.5, -0.66), C.Gold)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.45) -- four-legged, so scaled up to stand eye-to-eye with a person (Legendary)
print(b:preview())
_G.SkinBuild = b
