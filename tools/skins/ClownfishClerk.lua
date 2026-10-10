-- Clownfish Clerk (Common, Ocean egg) - block remake 2026-10-10. A hovering orange clownfish facing you: a round
-- orange body with three white bands edged in black, black-tipped fins, a little tail, big eyes, a tiny pencil
-- behind one fin. Front-facing, HOVERS. Common: simple, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("ClownfishClerk")
local V = Vector3.new
local C = Kit.C
local T, H = "UpperTorso", "Head"
local ORANGE, BAND, EDGE = Color3.fromRGB(255, 130, 30), Color3.fromHex("fafafa"), Color3.fromRGB(40, 40, 50)
local cy = 1.8
b:B(T, V(1.8, 1.6, 1.8), V(0, cy, 0), ORANGE)
b:B(T, V(1.5, 1.9, 1.5), V(0, cy, 0), ORANGE)
-- white bands (front view: a white ring around the face + one behind)
b:B(T, V(1.84, 0.3, 1.84), V(0, cy + 0.55, 0), BAND)
b:B(T, V(1.88, 0.06, 1.88), V(0, cy + 0.72, 0), EDGE)
b:B(T, V(1.84, 0.3, 1.84), V(0, cy - 0.55, 0), BAND)
b:B(T, V(1.88, 0.06, 1.88), V(0, cy - 0.72, 0), EDGE)
for _, s in { -1, 1 } do
	b:eye(V(s * 0.38, cy + 0.08, -0.91), 0.4, V(0, 0, -1), Vector2.new(0, 0))
	local name = if s < 0 then "LeftUpperArm" else "RightUpperArm"
	b:B(name, V(0.12, 0.55, 0.5), V(s * 0.98, cy - 0.15, -0.1), ORANGE, V(0, 0, s * -20)) -- side fins
	b:B(name, V(0.13, 0.12, 0.5), V(s * 1.05, cy - 0.45, -0.1), EDGE, V(0, 0, s * -20))
end
b:mouth(V(0, cy - 0.3, -0.91), 0.3, 0.08, V(0, 0, -1), 0, 18)
b:B(H, V(0.12, 0.5, 0.9), V(0, cy + 1.15, 0.1), ORANGE) -- top fin
b:B(H, V(0.13, 0.1, 0.9), V(0, cy + 1.4, 0.1), EDGE)
b:B(T, V(0.12, 0.8, 0.5), V(0, cy, 1.15), ORANGE) -- tail
b:B(T, V(0.13, 0.8, 0.1), V(0, cy, 1.42), EDGE)
b:B("RightUpperArm", V(0.08, 0.6, 0.08), V(1.15, cy + 0.2, -0.2), Color3.fromHex("ffd23f"), V(0, 0, -30)) -- pencil
b:B("RightUpperArm", V(0.09, 0.12, 0.09), V(1.3, cy + 0.45, -0.2), Color3.fromHex("f2a0b0"), V(0, 0, -30))
b.hover = 0.5
b.model.WorldPivot = CFrame.new(b.origin)
print(b:preview())
_G.SkinBuild = b
