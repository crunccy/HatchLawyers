-- Bombardiro Crocodilo (Legendary, Brainrot egg) - block remake 2026-10-10. Reference: the meme image (a crocodile's
-- head on a silver WWII bomber, propellers, a bomb dropping). Side-on, nose (the croc) toward +X, front = -Z,
-- HOVERS (attribute Hover) instead of standing. Legendary: big, gold trims (cowlings, hubs, goggles), red scarf.
local Kit = require(game.ServerStorage.SkinKit:Clone()) :: any
local b = Kit.new("Bombardiro")
local V = Vector3.new
local C = Kit.C
local METAL, METAL_MID, METAL_DARK = Color3.fromHex("a9b0bb"), Color3.fromHex("8e96a3"), Color3.fromHex("5f6672")
local CROC, CROC_DARK, CROC_PALE = Color3.fromHex("4f9a3a"), Color3.fromHex("3a7a2a"), Color3.fromHex("c9d98a")
local GLASS, BOMB, PROP = Color3.fromHex("8fd8ff"), Color3.fromHex("4a5a34"), Color3.fromHex("33363c")
local RED, BLUE = Color3.fromHex("e0303a"), Color3.fromHex("2f5fd0")
local CYL = Enum.PartType.Cylinder
local y0 = 1.32 -- fuselage centre line
local T = "UpperTorso"

-- fuselage: round body (cylinders along X), tapering tail, panel seams
b:B(T, V(3.4, 1.35, 1.35), V(0.1, y0, 0), METAL, nil, nil, CYL)
b:B(T, V(1.0, 1.05, 1.05), V(-2.05, y0 + 0.07, 0), METAL, nil, nil, CYL)
b:B(T, V(0.8, 0.7, 0.7), V(-2.9, y0 + 0.16, 0), METAL, nil, nil, CYL)
for _, x in { -1.1, 0.0, 1.1 } do
	b:B(T, V(0.05, 1.37, 1.37), V(x, y0, 0), METAL_DARK, nil, nil, CYL)
end
-- tail: vertical fin (red band) + stabilizers
b:B(T, V(0.85, 1.15, 0.12), V(-3.05, y0 + 0.85, 0), METAL_MID, V(0, 0, 16))
b:B(T, V(0.3, 1.05, 0.13), V(-2.98, y0 + 0.85, 0), RED, V(0, 0, 16))
b:B(T, V(0.75, 0.1, 2.1), V(-3.0, y0 + 0.22, 0), METAL_MID)
-- wings + darker tips
b:B(T, V(1.3, 0.14, 5.6), V(0.25, y0 - 0.08, 0), METAL_MID)
for _, s in { -1, 1 } do
	b:B(T, V(1.32, 0.16, 0.32), V(0.25, y0 - 0.08, s * 2.86), METAL_DARK)
	-- engine: nacelle, gold cowling ring, gold hub, two crossed propeller blades
	local z = s * 1.55
	b:B(T, V(1.2, 0.58, 0.58), V(0.75, y0 - 0.1, z), METAL_DARK, nil, nil, CYL)
	b:B(T, V(0.16, 0.66, 0.66), V(1.38, y0 - 0.1, z), C.Gold, nil, nil, CYL)
	b:B(T, V(0.3, 0.3, 0.3), V(1.5, y0 - 0.1, z), C.Gold, nil, nil, Enum.PartType.Ball)
	b:B(T, V(0.06, 1.45, 0.17), V(1.52, y0 - 0.1, z), PROP, V(25, 0, 0))
	b:B(T, V(0.06, 1.45, 0.17), V(1.52, y0 - 0.1, z), PROP, V(115, 0, 0))
	-- insignia on each side of the fuselage: white disc, blue ring, gold centre
	b:B(T, V(0.05, 0.62, 0.62), V(-1.55, y0 + 0.05, s * 0.6), C.White, V(0, 90, 0), nil, CYL)
	b:B(T, V(0.06, 0.44, 0.44), V(-1.55, y0 + 0.05, s * 0.62), BLUE, V(0, 90, 0), nil, CYL)
	b:B(T, V(0.07, 0.2, 0.2), V(-1.55, y0 + 0.05, s * 0.635), C.Gold, V(0, 90, 0), nil, CYL)
end
-- cockpit canopy with frame
b:B(T, V(0.8, 0.4, 0.72), V(1.0, y0 + 0.7, 0), GLASS)
b:B(T, V(0.06, 0.42, 0.74), V(1.0, y0 + 0.7, 0), METAL_DARK)
b:B(T, V(0.82, 0.06, 0.74), V(1.0, y0 + 0.92, 0), METAL_DARK)
-- the bomb under the belly: olive body, round nose, tail fins, hook
b:B(T, V(1.1, 0.44, 0.44), V(0.05, y0 - 1.05, 0), BOMB, nil, nil, CYL)
b:B(T, V(0.44, 0.44, 0.44), V(0.6, y0 - 1.05, 0), BOMB, nil, nil, Enum.PartType.Ball)
b:B(T, V(0.3, 0.06, 0.62), V(-0.6, y0 - 1.05, 0), METAL_DARK)
b:B(T, V(0.3, 0.62, 0.06), V(-0.6, y0 - 1.05, 0), METAL_DARK)
b:B(T, V(0.1, 0.36, 0.1), V(0.05, y0 - 0.7, 0), METAL_DARK)
b:B(T, V(0.06, 0.46, 0.46), V(0.25, y0 - 1.05, 0), C.Gold, nil, nil, CYL)

-- the crocodile head on the nose: open jaws, teeth top + bottom, eyes on top bumps, nostrils, scutes
local H = "Head"
b:B(H, V(1.05, 1.0, 1.15), V(2.25, y0 + 0.05, 0), CROC)
b:B(H, V(1.05, 0.25, 1.1), V(2.25, y0 - 0.4, 0), CROC_PALE)
b:B(H, V(1.45, 0.4, 0.92), V(3.4, y0 + 0.14, 0), CROC)                       -- upper snout
b:B(H, V(0.3, 0.32, 0.8), V(4.1, y0 + 0.16, 0), CROC)                        -- snout tip
b:B(H, V(1.4, 0.24, 0.86), V(3.32, y0 - 0.48, 0), CROC, V(0, 0, -11))        -- lower jaw (open)
b:B(H, V(1.4, 0.06, 0.82), V(3.32, y0 - 0.61, 0), CROC_PALE, V(0, 0, -11))   -- pale chin
b:B(H, V(1.3, 0.24, 0.8), V(3.3, y0 - 0.2, 0), C.Mouth, V(0, 0, -5))         -- inside of the mouth
b:B(H, V(0.7, 0.08, 0.5), V(3.0, y0 - 0.32, 0), C.Tongue, V(0, 0, -8))       -- tongue
for _, s in { -1, 1 } do
	for i = 0, 6 do                                                              -- top teeth (pointing down)
		b:B("HeadDetail", V(0.1, 0.17, 0.06), V(2.75 + i * 0.2, y0 - 0.13, s * 0.43), C.White)
	end
	for i = 0, 5 do                                                              -- bottom teeth (pointing up)
		local x = 2.8 + i * 0.2
		b:B("HeadDetail", V(0.1, 0.15, 0.06), V(x, y0 - 0.38 - (x - 2.6) * 0.19, s * 0.41), C.White)
	end
	-- eye bump on top, cartoon eye on its side, angry brow
	b:B(H, V(0.42, 0.34, 0.38), V(2.45, y0 + 0.66, s * 0.32), CROC)
	b:eye(V(2.47, y0 + 0.7, s * 0.52), 0.3, V(0, 0, s), Vector2.new(-0.18 * s, 0.05))
	b:brow(V(2.47, y0 + 0.92, s * 0.52), 0.36, V(0, 0, s), 14 * s)
	-- nostril
	b:B("HeadDetail", V(0.08, 0.06, 0.1), V(4.12, y0 + 0.34, s * 0.18), C.Line)
end
for i, x in { 2.0, 2.9, 3.35 } do                                              -- scutes along the back of the head
	b:B(H, V(0.18, 0.12, 0.18), V(x, y0 + (if x < 2.5 then 0.6 else 0.38), 0), CROC_DARK)
end
-- legendary aviator: gold goggles band over the head + a red scarf flapping back from the neck
b:B(H, V(0.14, 0.1, 1.2), V(2.0, y0 + 0.52, 0), C.Gold)
for _, s in { -1, 1 } do
	b:B("HeadDetail", V(0.3, 0.26, 0.08), V(1.95, y0 + 0.4, s * 0.6), C.GoldDark)
	b:B("HeadDetail", V(0.22, 0.18, 0.04), V(1.95, y0 + 0.4, s * 0.645), GLASS)
end
b:B(T, V(0.3, 0.28, 1.22), V(1.72, y0 + 0.05, 0), RED)                         -- scarf around the neck
b:B(T, V(0.75, 0.16, 0.34), V(1.2, y0 + 0.5, -0.66), RED, V(0, 0, -14))      -- tail of the scarf, flapping back
b:B(T, V(0.65, 0.15, 0.32), V(0.58, y0 + 0.62, -0.7), RED, V(0, 0, 10))
b:B(T, V(0.5, 0.14, 0.3), V(0.05, y0 + 0.55, -0.72), RED, V(0, 0, -8))
b:B(T, V(0.12, 0.15, 0.32), V(-0.24, y0 + 0.5, -0.72), C.Gold, V(0, 0, -8))   -- gold fringe

-- Legendary size: 1.2x, flying ~1.6 studs up (SkinLook reads Hover)
b.model.WorldPivot = CFrame.new(b.origin) -- scale about the feet
b.model:ScaleTo(1.2)
b.hover = 1.6
print(b:preview())
_G.SkinBuild = b
