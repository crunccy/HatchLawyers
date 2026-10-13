--!strict
-- MutationLook (ReplicatedStorage.Shared.MutationLook, 2026-10-13): recolours a lawyer model for its mutation
-- (Config.Lawyers.Mutations: Shiny / Diamond / Cosmic - the saved `Stars` tier 2-4). User's call: no extra effects,
-- the WHOLE lawyer takes the mutation's colours, but its body parts must stay easy to tell apart.
-- The rule (same as tools/blender/mutation_preview.py, which renders it - keep the two in step):
--   * the head keeps its face colours (eye whites, pupils, mouth, teeth, tongue, ink brows / nose);
--   * every other colour on the model is ranked darkest -> lightest and placed along the mutation's Ramp (half by
--     rank, half by its real brightness), so parts that were different stay different, in the new palette;
--   * glowing (Neon) parts take the bright end of the ramp.
-- MutationLook.apply(model, stars) recolours (tier 1 = puts the original colours back; safe to call again: the
-- originals are kept in each part's "MutBase" attribute). Shared.SkinLook.dress calls it, so desks, the hatch reveal,
-- the LAWYERS panel and the Mutation Machine all match.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript) :: any

local MutationLook = {}

local function key(c: Color3): string
	return string.format("%d,%d,%d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end
-- face + outline colours of the brick kit (tools/brick/BrickKit.lua, tools/blender/brickkit.py), on the head only
local KEEP = {}
for _, rgb in { { 251, 250, 246 }, { 15, 15, 18 }, { 90, 20, 25 }, { 216, 74, 90 }, { 28, 28, 32 }, { 36, 36, 44 } } do
	KEEP[key(Color3.fromRGB(rgb[1], rgb[2], rgb[3]))] = true
end
local FACE = { Head = true, HeadDetail = true }

local function lum(c: Color3): number
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function rampAt(stops: { Color3 }, t: number): Color3
	local x = math.clamp(t, 0, 1) * (#stops - 1)
	local i = math.min(math.floor(x), #stops - 2)
	return stops[i + 1]:Lerp(stops[i + 2], x - i)
end

local function baseColor(p: BasePart): Color3
	local saved = p:GetAttribute("MutBase")
	if typeof(saved) == "Color3" then
		return saved
	end
	p:SetAttribute("MutBase", p.Color)
	return p.Color
end

-- the face test: a part on the head (named Head / HeadDetail, or inside a model named Head) in a kit face colour
local function isFace(p: BasePart, c: Color3): boolean
	if not KEEP[key(c)] then
		return false
	end
	return FACE[p.Name] == true or (p.Parent ~= nil and FACE[p.Parent.Name] == true)
end

function MutationLook.apply(model: Instance, stars: number?)
	local tier = stars or 1
	local mutation = Config.Lawyers.Mutations and Config.Lawyers.Mutations[tier]
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(parts, d)
		end
	end
	if not mutation then -- Normal: put the original colours back
		for _, p in parts do
			local saved = p:GetAttribute("MutBase")
			if typeof(saved) == "Color3" then
				p.Color = saved
			end
		end
		model:SetAttribute("Mutation", nil)
		return
	end
	local stops = mutation.Ramp
	-- the model's own colours, solid and glowing apart, darkest first
	local groups: { [boolean]: { Color3 } } = { [false] = {}, [true] = {} }
	local seen: { [string]: boolean } = {}
	for _, p in parts do
		local c = baseColor(p)
		if not isFace(p, c) then
			local neon = p.Material == Enum.Material.Neon
			local k = key(c) .. (if neon then "n" else "")
			if not seen[k] then
				seen[k] = true
				table.insert(groups[neon], c)
			end
		end
	end
	local map: { [string]: Color3 } = {}
	for neon, cols in groups do
		table.sort(cols, function(a, b)
			return lum(a) < lum(b)
		end)
		local n = #cols
		if n > 0 then
			local lo, hi = lum(cols[1]), lum(cols[n])
			for i, c in cols do
				local byRank = if n > 1 then (i - 1) / (n - 1) else 0.5
				local byLum = if hi > lo then (lum(c) - lo) / (hi - lo) else 0.5
				local t = 0.5 * byRank + 0.5 * byLum
				t = if neon then 0.7 + 0.3 * t else 0.08 + 0.84 * t
				map[key(c) .. (if neon then "n" else "")] = rampAt(stops, t)
			end
		end
	end
	for _, p in parts do
		local c = baseColor(p)
		if isFace(p, c) then
			p.Color = c
		else
			p.Color = map[key(c) .. (if p.Material == Enum.Material.Neon then "n" else "")] or c
		end
	end
	model:SetAttribute("Mutation", mutation.Id)
end

-- the mutation's name ("" for Normal) and colour, for labels
function MutationLook.info(stars: number?): (string, Color3?)
	local m = Config.Lawyers.Mutations and Config.Lawyers.Mutations[stars or 1]
	return if m then m.Id else "", if m then m.Color else nil
end

return MutationLook
