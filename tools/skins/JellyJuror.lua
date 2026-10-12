-- Wobbly Jelly (Uncommon, Ocean egg) - block remake 2026-10-10. A hovering jellyfish: a see-through pink bell (stepped
-- dome) with a frilly rim, a cute face on the bell, wavy tentacles of different lengths hanging below, and a little
-- white juror number card held by one tentacle. Front-facing, HOVERS. Uncommon: 1 prop, 1.0x.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("JellyJuror")
local V = Vector3.new
local C = Kit.C
local BELL, BELL_DARK, CORE, TENT = Color3.fromHex("dc8cff"), Color3.fromHex("b468e0"), Color3.fromHex("f4c8ff"), Color3.fromHex("c87af0")
local T, H = "UpperTorso", "Head"
local by = 3.3

-- bell: stepped translucent dome, a brighter core inside, frilly rim
b:B(H, V(1.0, 0.8, 1.0), V(0, by + 0.3, 0), CORE)
local function bell(size, y)
	local p = b:B(H, size, V(0, y, 0), BELL)
	p.Transparency = 0.3
end
bell(V(2.2, 0.8, 2.0), by)
bell(V(1.8, 0.5, 1.7), by + 0.62)
bell(V(1.2, 0.3, 1.1), by + 0.98)
for i = 0, 9 do
	local a = i / 10 * math.pi * 2
	b:B(T, V(0.4, 0.2, 0.4), V(math.sin(a) * 1.05, by - 0.45 - (i % 2) * 0.06, math.cos(a) * 0.95), BELL_DARK)
end
-- face on the bell
for _, s in { -1, 1 } do
	b:eye(V(s * 0.38, by + 0.12, -1.01), 0.36, V(0, 0, -1), Vector2.new(0, 0))
	b:B("HeadDetail", V(0.22, 0.1, 0.04), V(s * 0.62, by - 0.12, -1.01), Color3.fromHex("ff7ab0"))
end
b:mouth(V(0, by - 0.18, -1.01), 0.26, 0.08, V(0, 0, -1), 0, 22)
-- wavy tentacles hanging down (zig-zag segments), different lengths
for k, tx in { { -0.7, -0.3, 4 }, { -0.25, -0.5, 5 }, { 0.25, -0.45, 5 }, { 0.7, -0.3, 4 }, { -0.45, 0.35, 3 }, { 0.45, 0.35, 3 } } do
	for j = 0, tx[3] - 1 do
		local wob = if j % 2 == 0 then 0.08 else -0.08
		b:B(k <= 2 and "LeftUpperLeg" or "RightUpperLeg", V(0.14, 0.5, 0.14), V(tx[1] + wob, by - 0.75 - j * 0.48, tx[2]), TENT, V(0, 0, wob * 150))
	end
end
-- juror card held up in a curled front tentacle
b:B("RightUpperArm", V(0.14, 0.6, 0.14), V(1.1, by - 0.75, -0.4), TENT, V(0, 0, -30))
b:B("RightUpperArm", V(0.55, 0.42, 0.05), V(1.35, by - 0.35, -0.5), C.White)
b:B("RightUpperArm", V(0.1, 0.24, 0.03), V(1.35, by - 0.35, -0.54), C.Line) -- the number "1"
b.model.WorldPivot = CFrame.new(b.origin)
b.hover = 0.5
print(b:preview())
_G.SkinBuild = b
