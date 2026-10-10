-- Paw-ralegal Pup (Common, Pet egg) - block remake 2026-10-10. A small upright tan puppy with long floppy ears, a
-- white muzzle, a navy jacket, and a rolled newspaper/document held proudly in its paw. Smaller + floppier than the
-- Corgi. Front-facing. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("PawralegalPup")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local FUR, FUR_DARK, MUZZLE, JACKET = Color3.fromRGB(190, 130, 70), Color3.fromHex("8a5a2e"), Color3.fromHex("f8efe0"), Color3.fromRGB(70, 90, 150)
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.4, 0.6, 0.45), V(s * 0.3, 0.45, 0), FUR)
	b:B(name, V(0.44, 0.2, 0.55), V(s * 0.3, 0.1, -0.06), MUZZLE)
end
b:B(T, V(1.2, 1.2, 0.9), V(0, 1.35, 0), JACKET)
b:B("HeadDetail", V(0.5, 0.9, 0.05), V(0, 1.45, -0.47), MUZZLE)
b:B(T, V(0.25, 0.25, 0.5), V(0, 1.1, 0.6), FUR, V(-30, 0, 0)) -- wagging tail
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.32, 0.8, 0.36), V(s * 0.74, 1.4, 0), JACKET)
	b:B(name, V(0.32, 0.24, 0.36), V(s * 0.74, 0.92, 0), FUR)
end
b:B("RightUpperArm", V(0.24, 0.9, 0.24), V(0.74, 1.15, -0.3), Color3.fromHex("f3e2b8"), V(0, 0, -30)) -- rolled document
b:B("RightUpperArm", V(0.26, 0.1, 0.26), V(0.74, 1.15, -0.3), Color3.fromHex("c0282e"), V(0, 0, -30))
b:B(H, V(1.3, 1.1, 1.05), V(0, 2.5, 0), FUR)
b:B(H, V(0.7, 0.45, 0.4), V(0, 2.2, -0.6), MUZZLE)
b:B(H, V(0.26, 0.18, 0.1), V(0, 2.38, -0.82), C.Line)
b:mouth(V(0, 2.08, -0.81), 0.3, 0.08, V(0, 0, -1), 0, 18)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.3, 2.65, -0.53), 0.34, V(0, 0, -1), Vector2.new(0, 0.05))
	b:B(H, V(0.25, 1.0, 0.5), V(s * 0.72, 2.3, 0.05), FUR_DARK) -- long floppy ears
	b:brow(V(s * 0.3, 2.92, -0.54), 0.26, V(0, 0, -1), s * -8, FUR_DARK)
end
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
