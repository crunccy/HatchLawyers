-- Builds a FirmKitParts piece (Model of Plastic Parts, pivot = kit origin) from compact rows
-- "x,y,z,sx,sy,sz,colorIndex;..." exported by HatchLawyers/tools (firm_boxes.json -> firm_parts_*.txt).
-- Colors index Palette (a StringValue "r,g,b;r,g,b;..." next to this module).
return function(name: string, data: string): number
	local folder = script.Parent
	local pal = {}
	for rgb in folder.Palette.Value:gmatch("[^;]+") do
		local r, g, b = rgb:match("(%d+),(%d+),(%d+)")
		table.insert(pal, Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
	end
	local old = folder:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = name
	local n = 0
	for row in data:gmatch("[^;]+") do
		local v = {}
		for num in row:gmatch("[^,]+") do
			table.insert(v, tonumber(num))
		end
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs -- like every part of the map (Plaza, IslandDecor, Ground)
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(v[4], v[5], v[6])
		p.CFrame = CFrame.new(v[1], v[2], v[3])
		p.Color = pal[v[7]]
		if math.min(v[4], v[5], v[6]) < 0.5 and math.max(v[4], v[5], v[6]) < 2 then
			p.CastShadow = false
		end
		p.Parent = m
		n += 1
	end
	m.WorldPivot = CFrame.new()
	m.Parent = folder
	return n
end
