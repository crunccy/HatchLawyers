-- tools/zones/BuildLotSigns.lua - puts the LOT SIGN (tools/zones/lot_sign.json, from tools/blender/lot_sign.py; art pass
-- stage 4, 2026-10-16) at every plot's entrance: Workspace.Plots.PlotN.LotSign, 20 studs in from the plot's middle on
-- its street side (plot-local -Z), on the grass. Server.PlotService hides it while the plot has a firm (and puts it back
-- when the owner leaves); a plot owned during an Edit-mode run keeps its sign hidden by PlotService at play time anyway.
-- Re-runnable (replaces the signs). Run in Edit mode with the JSON served at JSON_URL
-- (Mac: python3 -m http.server 8766 --directory tools/zones; Windows: tools/studio_sync/serve_files.ps1).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")

local JSON_URL = "http://localhost:8766/lot_sign.json"
local SPOT = CFrame.new(0, 0.48, -20) -- plot-local: the base's top, just inside the dashed border on the street side
local data = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
local md = data.models[1]
local recording = ChangeHistoryService:TryBeginRecording("BuildLotSigns")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local LUCKIEST = Font.new("rbxasset://fonts/families/LuckiestGuy.json")
local ZFight = require(game:GetService("ServerScriptService").Server.ZFight:Clone())

local function faceFor(p: BasePart, want: Vector3): Enum.NormalId
	local best, bestDot = Enum.NormalId.Front, -2
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(want)
		if d > bestDot then
			best, bestDot = id, d
		end
	end
	return best
end

local function build(place: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "LotSign"
	for _, b in md.parts do
		local p = Instance.new("Part")
		p.Name = b.n
		p.Anchored = true
		p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
		local r = b.r
		p.CFrame = place * CFrame.new(b.p[1], b.p[2], b.p[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p.Color = Color3.fromRGB(b.c[1], b.c[2], b.c[3])
		p.Material = Enum.Material.Plastic
		p.MaterialVariant = "BrickStuds"
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CastShadow = p.Size.Magnitude > 2
		p.CanCollide = b.n == "Post" or b.n == "PostFoot"
		if b.txt then
			local gui = Instance.new("SurfaceGui")
			gui.Name = "Sign"
			gui.Face = faceFor(p, place:VectorToWorldSpace(Vector3.new(b.fn[1], b.fn[2], b.fn[3]).Unit))
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 50
			gui.LightInfluence = 0
			local big = b.n == "Sign"
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0.04, 0.1)
			l.Size = UDim2.fromScale(0.92, 0.8)
			l.Text = b.txt
			l.TextScaled = true
			l.TextColor3 = if big then Color3.new(1, 1, 1) else Color3.fromRGB(40, 40, 52)
			l.FontFace = if big then LUCKIEST else FREDOKA
			if big then
				local st = Instance.new("UIStroke")
				st.Thickness = 4
				st.Parent = l
			end
			l.Parent = gui
			gui.Parent = p
		end
		p.Parent = m
	end
	m.WorldPivot = place
	for _ = 1, 3 do
		if ZFight.fix({ m }) == 0 then
			break
		end
	end
	return m
end

local n = 0
for _, plot in workspace:WaitForChild("Plots"):GetChildren() do
	if plot:IsA("Model") then
		local old = plot:FindFirstChild("LotSign")
		if old then
			old:Destroy()
		end
		local sign = build(plot:GetPivot() * SPOT)
		sign.Parent = plot
		n += 1
	end
end
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return ("LotSigns: %d plots, %d blocks each"):format(n, #md.parts)
