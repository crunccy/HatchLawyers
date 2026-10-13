-- tools/zones/BuildLawyersTop.lua - turns tools/zones/lawyers_top.json (tools/blender/lawyers_top.py: the 18 Epic /
-- Mythic / Supreme lawyers, built in Blender as brick Parts) into ReplicatedStorage.SkinModels.<Id> (2026-10-13).
-- Parts: "brick" = Plastic + MaterialVariant BrickStuds (the cast's studded bricks), "plate" = smooth Plastic, "neon" =
-- Neon. Kinds: box / wedge (WedgePart) / cyl (Shape Cylinder) / ball. Moving bits get attributes Shared.Puppet plays:
--   FxKind ("rot" | "osc" | "bob"), FxAxis + FxPivot (Vector3s in the part's own space), FxAmp, FxRate, FxPhase,
--   FxSize (the part's size when built, to scale the pivot if the model is scaled). The model gets Style = "Brick", Rarity. Mythic is built 1.3x, Supreme 1.6x (already scaled in the JSON).
-- No parts are uploaded (plain Parts), so anyone's Studio can run it. A model it replaces goes to
-- ServerStorage.RetiredSkinModels.<Id>_preTop. Run in Edit mode with the JSON served on http://localhost:8766/.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local data = HttpService:JSONDecode(HttpService:GetAsync("http://localhost:8766/lawyers_top.json", true))
local skins = ReplicatedStorage:WaitForChild("SkinModels")
local hasStuds = game:GetService("MaterialService"):FindFirstChild("BrickStuds") ~= nil

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local rec = ChangeHistoryService:TryBeginRecording("Build Epic/Mythic/Supreme lawyers")
local report = {}
for id, def in data do
	local m = Instance.new("Model")
	m.Name = id
	for _, b in def.parts do
		local p: BasePart
		if b.k == "wedge" then
			p = Instance.new("WedgePart")
		else
			local part = Instance.new("Part")
			if b.k == "cyl" then
				part.Shape = Enum.PartType.Cylinder
			elseif b.k == "ball" then
				part.Shape = Enum.PartType.Ball
			end
			p = part
		end
		p.Name = b.n
		p.Size = v3(b.s)
		local r = b.r
		p.CFrame = CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if b.t == "neon" then
			p.Material = Enum.Material.Neon
			p.CastShadow = false
		elseif b.t == "brick" and hasStuds then
			p.Material = Enum.Material.Plastic
			p.MaterialVariant = "BrickStuds"
		else
			p.Material = Enum.Material.Plastic
		end
		if b.t ~= "neon" then
			p.CastShadow = p.Size.X * p.Size.Y * p.Size.Z > 0.02
		end
		local fx = b.fx
		if fx then
			-- (pivot + axis stored in the PART's own space, and its size, so the motion survives scaling and placing)
			p:SetAttribute("FxKind", fx.kind)
			p:SetAttribute("FxAxis", p.CFrame:VectorToObjectSpace(v3(fx.axis).Unit))
			p:SetAttribute("FxAmp", fx.amp)
			p:SetAttribute("FxRate", fx.rate or 0)
			p:SetAttribute("FxPhase", fx.phase or 0)
			p:SetAttribute("FxPivot", if fx.pivot then p.CFrame:PointToObjectSpace(v3(fx.pivot)) else Vector3.zero)
			p:SetAttribute("FxSize", p.Size)
		end
		p.Parent = m
	end
	m.WorldPivot = CFrame.new()
	m:SetAttribute("Style", "Brick")
	m:SetAttribute("Rarity", def.rarity)
	m:SetAttribute("Remade", "2026-10-13 Blender (tools/blender/lawyers_top.py)")
	local old = skins:FindFirstChild(id)
	if old then
		local folder = ServerStorage:FindFirstChild("RetiredSkinModels") or Instance.new("Folder")
		folder.Name = "RetiredSkinModels"
		folder.Parent = ServerStorage
		if folder:FindFirstChild(id .. "_preTop") then
			old:Destroy()
		else
			old.Name = id .. "_preTop"
			old.Parent = folder
		end
	end
	m.Parent = skins
	local _, size = m:GetBoundingBox()
	table.insert(report, string.format("%s %d parts %.1f tall", id, #def.parts, size.Y))
end
if rec then
	ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
end
table.sort(report)
return table.concat(report, "\n")
