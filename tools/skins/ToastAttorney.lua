-- Toasty (Common, Food egg) - block remake 2026-10-10. A walking slice of toast: a golden bread slice with a
-- darker crust edge and a bumpy rounded top, a melting pat of butter on its head, a face in the middle, a green tie,
-- stick legs and arms. Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("ToastAttorney")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local BREAD, CRUST, BUTTER, TIE, BLACK = Color3.fromHex("f0c070"), Color3.fromRGB(160, 90, 35), Color3.fromHex("ffe680"), Color3.fromRGB(90, 120, 80), Color3.fromHex("1c1c20")
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.18, 1.0, 0.18), V(s * 0.45, 0.6, 0), BLACK)
	b:B(name, V(0.4, 0.2, 0.6), V(s * 0.47, 0.1, -0.1), BLACK)
end
b:B(T, V(2.3, 2.3, 0.6), V(0, 2.3, 0), CRUST)             -- crust
b:B(T, V(2.1, 2.1, 0.64), V(0, 2.3, 0), BREAD)
for _, s in { -1, 1 } do                                      -- bumpy rounded top
	b:B(H, V(1.0, 0.7, 0.6), V(s * 0.65, 3.6, 0), CRUST)
	b:B(H, V(0.85, 0.55, 0.64), V(s * 0.65, 3.58, 0), BREAD)
end
b:B(H, V(0.7, 0.25, 0.6), V(0, 3.75, 0), CRUST)
b:B(H, V(0.7, 0.2, 0.5), V(0.1, 4.02, 0), BUTTER)            -- butter pat
b:B(H, V(0.18, 0.3, 0.1), V(0.3, 3.85, -0.3), BUTTER)        -- melting drip
for _, s in { -1, 1 } do
	b:eye(V(s * 0.4, 2.85, -0.33), 0.4, V(0, 0, -1), Vector2.new(0, 0))
	b:brow(V(s * 0.42, 3.15, -0.34), 0.36, V(0, 0, -1), s * 6, CRUST)
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.6, 0.16, 0.16), V(s * 1.4, 2.2, -0.05), BLACK, V(0, 0, s * -30))
	b:B(name, V(0.28, 0.28, 0.28), V(s * 1.68, 2.4, -0.05), C.White)
end
b:mouth(V(0, 2.42, -0.33), 0.44, 0.12, V(0, 0, -1), 4, 18)
b:B("HeadDetail", V(0.18, 0.14, 0.04), V(0, 2.0, -0.34), TIE)
b:B("HeadDetail", V(0.14, 0.5, 0.04), V(0, 1.68, -0.34), TIE)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
