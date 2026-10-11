-- ConvertLawyers (2026-10-11 brick style, docs/CHARACTER_STYLE.md): turns the 2026-10-10 block-remake lawyers that
-- are CREATURES (brainrot, pet, food, ocean, space - each keeps its own body plan) into the brick style IN PLACE:
--   * bodies: Plastic + the BrickStuds MaterialVariant (studs every 0.5 studs), smooth surfaces. Thin details
--     (any side <= 0.08), tiny bits (every side < 0.3), Neon, Glass / see-through parts, ForceField stay as they are.
--     Metal / SmoothPlastic / Foil become Plastic (no shine - user's call).
--   * eyes (SkinKit's white square + black pupil + white shine): the shine dot goes, the white and pupil move
--     0.02 forward and a thin dark rim (#1C1C20) takes the white's old place - the brick face kit.
-- The original is kept first as ServerStorage.RetiredSkinModels.<Id>_preBrick (move it back to undo).
-- Run: _G.runFile("tools/brick/ConvertLawyers.lua") in Studio (Edit mode); returns a report per lawyer.
-- The people-shaped lawyers are REBUILT on BrickKit instead (tools/brick/<Id>.lua), not converted.

local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local VARIANT = "BrickStuds"
local WHITE, PUPIL, RIM = Color3.fromHex("f5f5f5"), Color3.fromHex("0f0f12"), Color3.fromHex("1c1c20")

local CREATURES = {
	-- Briefcase egg creatures: a walking gavel and an ice golem
	"GoldenGavel", "IceJustice",
	-- brainrot (Tung Tung Tung Sahur is the Briefcase egg's PinstripePartner; its model is SkinModels.TungTungSahur)
	"TungTungSahur", "BonecaAmbalabu", "ChimpanziniBananini", "BallerinaCappuccina", "BrrBrrPatapim", "LiriliLarila",
	"Bombardiro", "CappuccinoAvvocato", "Tralalero",
	-- pet
	"PawralegalPup", "HamsterHustle", "WhiskersEsq", "BubblesGoldfish", "CorgiCounsel", "ParrotProsecutor", "SirFluffington", "HoundOfJustice",
	-- food
	"ToastAttorney", "SunnySideSam", "SushiSolicitor", "TacoTribunal", "PizzaProsecutor", "DonutDefender", "BurgerBoss", "ScoopJudge",
	-- ocean
	"CrabCounsel", "ClownfishClerk", "PufferPartner", "JellyJuror", "OctoAttorney", "SeahorseSolicitor", "WhaleJudge", "KrakenCounsel",
	-- space
	"MoonRockRookie", "LittleGreenLawyer", "AstroAttorney", "RoboClerk", "SaturnSolicitor", "UFOCounsel", "StarJudge", "BlackHoleBarrister",
}

local function near(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.03
end

local function surfaces(p: BasePart, s: Enum.SurfaceType)
	p.TopSurface, p.BottomSurface, p.FrontSurface = s, s, s
	p.BackSurface, p.LeftSurface, p.RightSurface = s, s, s
end

-- the thin axis of a plate (1 = X, 2 = Y, 3 = Z) or nil
local function thinAxis(p: BasePart): number?
	local s = p.Size
	local m = math.min(s.X, s.Y, s.Z)
	if m > 0.07 then
		return nil
	end
	return if s.Z == m then 3 elseif s.Y == m then 2 else 1
end

local function convert(model: Model): string
	local studded, kept, eyes, shines = 0, 0, 0, 0
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	-- 1) eyes: white plates with a pupil in front of them
	local whites, pupils = {}, {}
	for _, p in parts do
		if thinAxis(p) == 3 then
			if near(p.Color, WHITE) then
				table.insert(whites, p)
			elseif near(p.Color, PUPIL) then
				table.insert(pupils, p)
			end
		end
	end
	local removed: { [BasePart]: boolean } = {}
	for _, w in whites do
		if removed[w] or w:GetAttribute("Rimmed") then
			continue
		end
		local ws = w.Size
		if ws.X < 0.12 or ws.Y < 0.12 or ws.X / ws.Y > 1.8 or ws.Y / ws.X > 1.8 then
			continue -- teeth, shirt panels, paper: not an eye white
		end
		-- a pupil inside this white's square, just in front of it (black, or a coloured iris - cats' green eyes)
		local pupil
		local candidates = table.clone(pupils)
		for _, p in parts do
			if p ~= w and thinAxis(p) == 3 and not near(p.Color, WHITE) and not near(p.Color, PUPIL) and p.Size.X < ws.X * 0.8 then
				table.insert(candidates, p)
			end
		end
		for _, pu in candidates do
			local rel = w.CFrame:PointToObjectSpace(pu.Position)
			if math.abs(rel.X) < ws.X / 2 and math.abs(rel.Y) < ws.Y / 2 and rel.Z < 0 and rel.Z > -0.12 and pu.Size.X < ws.X then
				pupil = pu
				break
			end
		end
		if not pupil then
			continue
		end
		-- the shine: a small white plate in front of the pupil
		for _, s in whites do
			if s ~= w and not removed[s] then
				local rel = w.CFrame:PointToObjectSpace(s.Position)
				if s.Size.X <= ws.X * 0.4 and math.abs(rel.X) < ws.X / 2 and math.abs(rel.Y) < ws.Y / 2 and rel.Z < -0.01 then
					removed[s] = true
					s:Destroy()
					shines += 1
				end
			end
		end
		local rim = w:Clone()
		rim.Name = "HeadDetail"
		rim.Color = RIM
		local m = math.max(0.06, ws.X * 0.1)
		rim.Size = Vector3.new(ws.X + m, ws.Y + m, ws.Z)
		rim.Parent = w.Parent
		w.CFrame = w.CFrame * CFrame.new(0, 0, -0.02)
		pupil.CFrame = pupil.CFrame * CFrame.new(0, 0, -0.02)
		w:SetAttribute("Rimmed", true)
		rim:SetAttribute("Rimmed", true)
		eyes += 1
	end
	-- 1b) eyes with no white (solid black / coloured eyes, e.g. the alien, the hound, Sir Fluffington): only the shine
	--     dot goes - the brick face has no shine
	for _, pu in parts do
		if removed[pu] or not pu.Parent or near(pu.Color, WHITE) or thinAxis(pu) ~= 3 then
			continue
		end
		local ps = pu.Size
		if ps.X < 0.15 or ps.Y < 0.15 or ps.X > 0.8 or ps.Y > 0.8 then
			continue
		end
		for _, s in whites do
			if not removed[s] and s.Parent and s.Size.X <= ps.X * 0.5 and s.Size.Y <= ps.Y * 0.5 then
				local rel = pu.CFrame:PointToObjectSpace(s.Position)
				if math.abs(rel.X) < ps.X / 2 and math.abs(rel.Y) < ps.Y / 2 and rel.Z < 0 and rel.Z > -0.1 then
					removed[s] = true
					s:Destroy()
					shines += 1
				end
			end
		end
	end
	-- 2) bodies: studs; thin / tiny / glowing / see-through parts stay smooth
	for _, p in parts do
		if removed[p] or not p.Parent then
			continue
		end
		local s = p.Size
		local mat = p.Material
		local skip = mat == Enum.Material.Neon or mat == Enum.Material.Glass or mat == Enum.Material.ForceField
			or p.Transparency > 0.2 or p:FindFirstChildOfClass("SurfaceAppearance") ~= nil
			or p:FindFirstChildOfClass("Decal") ~= nil or p:FindFirstChildOfClass("Texture") ~= nil
		if skip then
			kept += 1
			continue
		end
		if mat == Enum.Material.Metal or mat == Enum.Material.SmoothPlastic or mat == Enum.Material.Foil or mat == Enum.Material.DiamondPlate then
			p.Material = Enum.Material.Plastic
		end
		p.Reflectance = 0
		if math.min(s.X, s.Y, s.Z) > 0.08 and math.max(s.X, s.Y, s.Z) >= 0.3 and p.Material == Enum.Material.Plastic then
			p.MaterialVariant = VARIANT
			surfaces(p, Enum.SurfaceType.Smooth)
			studded += 1
		else
			kept += 1
		end
	end
	model:SetAttribute("Style", "Brick")
	local note = tostring(model:GetAttribute("Remade") or "")
	if not string.find(note, "brick conversion", 1, true) then
		model:SetAttribute("Remade", note .. " | 2026-10-11 brick conversion")
	end
	return string.format("%s: %d studded, %d smooth/glow, %d eyes rimmed, %d shines removed", model.Name, studded, kept, eyes, shines)
end

local retired = SS:FindFirstChild("RetiredSkinModels") or Instance.new("Folder")
retired.Name = "RetiredSkinModels"
retired.Parent = SS
local report = {}
for _, id in (_G.ConvertOnly or CREATURES) do
	local m = RS.SkinModels:FindFirstChild(id)
	if not m then
		table.insert(report, id .. ": MISSING")
	elseif m:GetAttribute("Style") == "Brick" and not _G.ConvertEyesAgain then
		table.insert(report, id .. ": already brick")
	else
		if not retired:FindFirstChild(id .. "_preBrick") then
			local backup = m:Clone()
			backup.Name = id .. "_preBrick"
			backup.Parent = retired
		end
		table.insert(report, convert(m))
	end
end
return table.concat(report, "\n")
