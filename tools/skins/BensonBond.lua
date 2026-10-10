-- Benson Bond (Uncommon) - block remake 2026-10-10. A GENERIC showman lawyer (original design - deliberately no real
-- person's likeness): a cream-white suit with a gold tie and gold buttons, one arm flung up in a big finish, the
-- other holding a gold microphone, short neat hair, a big grin. Front-facing. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("BensonBond")
local V = Vector3.new
local C = Kit.C
local SUIT, SUIT_SHADE, TIE, SKIN, HAIR = Color3.fromRGB(250, 248, 240), Color3.fromHex("e2ddcc"), Color3.fromRGB(255, 205, 120), Color3.fromRGB(240, 196, 168), Color3.fromHex("6b4426")
local T, H = "UpperTorso", "Head"

for _, s in { -1, 1 } do
	local name = if s < 0 then "LeftUpperLeg" else "RightUpperLeg"
	b:B(name, V(0.46, 1.6, 0.5), V(s * 0.3 + s * 0.08, 1.05, 0), SUIT, V(0, 0, s * -5)) -- a wide showman stance
	b:B(name, V(0.5, 0.24, 0.8), V(s * 0.42, 0.12, -0.12), Color3.fromHex("8a5a2e"))
end
b:B(T, V(1.5, 1.6, 0.8), V(0, 2.65, 0), SUIT)
b:B(T, V(1.54, 0.12, 0.84), V(0, 1.9, 0), SUIT_SHADE)
b:B("HeadDetail", V(0.42, 1.1, 0.05), V(0, 2.9, -0.42), Color3.fromHex("1c1c20")) -- dark shirt
b:B("HeadDetail", V(0.16, 0.9, 0.04), V(0, 2.85, -0.45), TIE)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.16, 1.0, 0.05), V(s * 0.3, 2.95, -0.43), SUIT_SHADE, V(0, 0, s * 15))
end
for _, y in { 2.4, 2.1 } do
	b:B("HeadDetail", V(0.1, 0.1, 0.04), V(0.42, y, -0.43), C.Gold)
end
-- -X arm flung up for the big finish, +X holds a gold microphone
b:B("LeftUpperArm", V(0.42, 0.9, 0.45), V(-1.05, 3.55, 0), SUIT, V(0, 0, -35))
b:B("LeftUpperArm", V(0.4, 0.8, 0.42), V(-1.38, 4.25, 0), SUIT, V(0, 0, -15))
b:B("LeftUpperArm", V(0.34, 0.34, 0.34), V(-1.5, 4.75, 0), SKIN)
b:B("RightUpperArm", V(0.42, 0.85, 0.45), V(0.98, 2.95, 0), SUIT)
b:B("RightUpperArm", V(0.4, 0.75, 0.42), V(0.98, 2.5, -0.35), SUIT, V(60, 0, 0))
b:B("RightUpperArm", V(0.32, 0.32, 0.32), V(0.98, 2.55, -0.75), SKIN)
b:B("RightUpperArm", V(0.14, 0.5, 0.14), V(0.92, 2.85, -0.8), C.Line, V(0, 0, 15))
b:B("RightUpperArm", V(0.3, 0.3, 0.3), V(0.85, 3.15, -0.8), C.Gold)
-- head: neat short hair, big grin
b:B(H, V(1.1, 1.15, 1.0), V(0, 4.0, 0), SKIN)
b:B(H, V(1.16, 0.28, 1.06), V(0, 4.62, 0.03), HAIR)
b:B(H, V(1.16, 0.5, 0.2), V(0, 4.4, 0.45), HAIR)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.25, 4.1, -0.51), 0.3, V(0, 0, -1), Vector2.new(0, 0.05))
	b:brow(V(s * 0.27, 4.35, -0.52), 0.28, V(0, 0, -1), s * -8, HAIR)
end
b:mouth(V(0, 3.72, -0.51), 0.46, 0.16, V(0, 0, -1), 6, 20)
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
