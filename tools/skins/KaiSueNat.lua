-- Selfie Star (Id KaiSueNat, Rare; renamed 2026-10-11) - block remake 2026-10-10. A GENERIC hype vlogger lawyer (original design - deliberately no real
-- person's likeness; no hairstyle, no signature outfit): a black hoodie with a red stripe and a red tie peeking out,
-- a backwards red cap, chunky headphones around the neck, a phone held up on a selfie stick, an excited face.
-- Front-facing. Rare: Neon "live" dot on the phone, 1.05x. Colours follow the catalog entry.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("KaiSueNat")
local V = Vector3.new
local C = Kit.C
local HOODIE, HOODIE_DARK, RED = Color3.fromRGB(25, 25, 30), Color3.fromHex("121216"), Color3.fromRGB(210, 30, 40)
local SKIN, SNEAK, PHONE = Color3.fromRGB(116, 76, 52), Color3.fromHex("f5f5f5"), Color3.fromHex("2a2a32")
local T, H = "UpperTorso", "Head"

-- legs: black joggers with a red side stripe, chunky white sneakers
for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.48, 1.5, 0.52), V(s * 0.3, 1.05, 0), HOODIE)
	b:B(name, V(0.05, 1.4, 0.1), V(s * 0.55, 1.05, 0), RED)
	b:B(name, V(0.58, 0.34, 0.85), V(s * 0.31, 0.17, -0.1), SNEAK)
	b:B(name, V(0.6, 0.06, 0.87), V(s * 0.31, 0.32, -0.1), RED)
end
-- hoodie: body, pocket, red chest stripe, drawstrings, red tie collar peeking out
b:B(T, V(1.55, 1.55, 0.85), V(0, 2.55, 0), HOODIE)
b:B(T, V(1.58, 0.2, 0.88), V(0, 1.85, 0), HOODIE_DARK)
b:B("HeadDetail", V(0.9, 0.35, 0.05), V(0, 2.1, -0.44), HOODIE_DARK)
b:B("HeadDetail", V(1.56, 0.14, 0.05), V(0, 2.65, -0.44), RED)
b:B("HeadDetail", V(0.3, 0.14, 0.05), V(0, 3.18, -0.44), C.White)
b:B("HeadDetail", V(0.12, 0.3, 0.04), V(0, 3.0, -0.46), RED)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.04, 0.4, 0.04), V(s * 0.2, 2.95, -0.46), C.White)
end
b:B(T, V(1.3, 0.35, 0.5), V(0, 3.2, 0.35), HOODIE_DARK) -- hood bunched at the back
-- headphones around the neck
b:B(T, V(1.2, 0.14, 0.14), V(0, 3.38, 0.25), C.Line)
for _, s in { -1, 1 } do
	b:B(T, V(0.24, 0.4, 0.4), V(s * 0.6, 3.3, -0.15), C.Line)
	b:B(T, V(0.06, 0.24, 0.24), V(s * 0.73, 3.3, -0.15), RED)
end
-- arms: -X holds a selfie stick up, +X fist pump
b:B("LeftUpperArm", V(0.42, 0.8, 0.46), V(-0.98, 2.95, 0), HOODIE, V(0, 0, 40))
b:B("LeftUpperArm", V(0.4, 0.7, 0.44), V(-1.35, 3.6, -0.1), HOODIE, V(0, 0, 10))
b:B("LeftUpperArm", V(0.34, 0.34, 0.34), V(-1.42, 4.0, -0.15), SKIN)
b:B("LeftUpperArm", V(0.08, 1.0, 0.08), V(-1.42, 4.55, -0.35), C.Line, V(-20, 0, 0))
b:B("LeftUpperArm", V(0.42, 0.7, 0.07), V(-1.42, 5.1, -0.55), PHONE, V(-20, 0, 0))
b:B("LeftUpperArm", V(0.1, 0.1, 0.04), V(-1.55, 5.33, -0.64), RED, nil, Enum.Material.Neon)
b:B("RightUpperArm", V(0.42, 1.3, 0.46), V(0.98, 2.5, 0), HOODIE)
b:B("RightUpperArm", V(0.4, 0.36, 0.42), V(0.98, 1.7, 0), SKIN)
-- head: excited face, backwards red cap
b:B(H, V(1.2, 1.2, 1.1), V(0, 3.95, 0), SKIN)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.27, 4.05, -0.56), 0.36, V(0, 0, -1), Vector2.new(s * -0.1, 0.05))
	b:brow(V(s * 0.29, 4.32, -0.57), 0.32, V(0, 0, -1), s * -5, C.Line)
end
b:mouth(V(0, 3.62, -0.56), 0.46, 0.18, V(0, 0, -1), 5, 20)
b:B(H, V(1.26, 0.35, 1.16), V(0, 4.68, 0), RED)
b:B(H, V(0.9, 0.08, 0.5), V(0, 4.55, 0.8), RED) -- brim at the back
b:B(H, V(0.4, 0.14, 0.06), V(0, 4.6, 0.6), C.White) -- adjuster strap... (back of the cap)
b.model.WorldPivot = CFrame.new(b.origin)
b.model:ScaleTo(1.05)
print(b:preview())
_G.SkinBuild = b
