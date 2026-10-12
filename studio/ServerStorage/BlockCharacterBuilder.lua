-- Dev tool (Studio command bar / MCP only): builds a block-style character Model from the compact rows that
-- HatchLawyers/tools/themed_cast.py + lawyers_v2.py export (see SESSION_LOG 2026-10-09).
-- Row: "P,x,y,z,sx,sy,sz,RRGGBB[n|g][,r00..r22]" with P = H Head | D HeadDetail | T UpperTorso |
-- A LeftUpperArm | B RightUpperArm | L LeftUpperLeg | R RightUpperLeg; n = Neon, g = Glass.
-- Builder.build(id, rows, parent, isClient): lawyers go to ReplicatedStorage.SkinModels; clients
-- (isClient) get an invisible HumanoidRootPart as PrimaryPart, like the other Templates.Clients.
local Builder = {}

local NAMES = { H = "Head", D = "HeadDetail", T = "UpperTorso", A = "LeftUpperArm", B = "RightUpperArm", L = "LeftUpperLeg", R = "RightUpperLeg" }

function Builder.build(id: string, rows: string, parent: Instance, isClient: boolean?): Model
	local old = parent:FindFirstChild(id)
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = id
	m:SetAttribute("Style", "BlockV2")
	for row in string.gmatch(rows, "[^;]+") do
		local f = string.split(row, ",")
		local p = Instance.new("Part")
		p.Name = NAMES[f[1]]
		p.Size = Vector3.new(tonumber(f[5]), tonumber(f[6]), tonumber(f[7]))
		local x, y, z = tonumber(f[2]), tonumber(f[3]), tonumber(f[4])
		if #f >= 17 then
			local r = {}
			for i = 9, 17 do
				r[i - 8] = tonumber(f[i])
			end
			p.CFrame = CFrame.new(x, y, z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		else
			p.CFrame = CFrame.new(x, y, z)
		end
		local hex = f[8]
		p.Color = Color3.fromHex(string.sub(hex, 1, 6))
		local flag = string.sub(hex, 7, 7)
		if flag == "n" then
			p.Material = Enum.Material.Neon
		elseif flag == "g" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.55
		else
			p.Material = Enum.Material.Plastic
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Parent = m
	end
	if isClient then
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(1.44, 1.9, 0.9)
		hrp.CFrame = CFrame.new(0, 3, 0)
		hrp.Transparency = 1
		hrp.Anchored = true
		hrp.CanCollide = false
		hrp.CanQuery = false
		hrp.CanTouch = false
		hrp.Parent = m
		m.PrimaryPart = hrp
	else
		local box = m:GetBoundingBox()
		m.WorldPivot = CFrame.new(box.Position)
	end
	m.Parent = parent
	return m
end

return Builder
