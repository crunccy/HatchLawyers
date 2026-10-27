-- InstallOverhaulKit.lua (2026-10-26, mr.robe's session): swaps the staged overhaul meshes
-- (ServerStorage.Overhaul.Models.<group>.<model>) into the live gameplay models, keeping every name scripts look up.
-- A ModuleScript returning run(step); run it in Edit mode one step at a time (see the bottom).
-- Each swap: the old model keeps its pivot, tags, attributes and working parts (prompts, triggers, gui plates,
-- invisible zones); its look Parts go to ServerStorage.Old_KitParts.<name>; the meshes go in, lined up by their
-- bounding box (centre on x / z, bottom on y, turned by YAW degrees about the model's up axis). One undo step.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local KIT = ServerStorage.Overhaul.Models

local function archiveFolder(name: string): Folder
	local root = ServerStorage:FindFirstChild("Old_KitParts")
	if not root then
		root = Instance.new("Folder")
		root.Name = "Old_KitParts"
		root.Parent = ServerStorage
	end
	local f = root:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
	end
	return f :: Folder
end

-- a part scripts use: named in keep (or matching a "^pattern" there), invisible, tagged / with attributes (or inside a
-- tagged model other than the MinigameStation itself: the peekers, cases), or holding a prompt / gui / script / click. "hide" = it only holds a prompt / gui: the part goes
-- invisible and stops colliding, its prompt / gui keep working.
local function working(p: Instance, keep: { [string]: boolean }, root: Instance): (boolean, boolean)
	if keep[p.Name] then
		return true, false
	end
	if p:IsA("BasePart") and p.Transparency >= 1 then
		return true, false
	end
	for pat in keep do
		if string.sub(pat, 1, 1) == "^" and string.match(p.Name, pat) then
			return true, false
		end
	end
	if next(p:GetAttributes()) ~= nil or #CollectionService:GetTags(p) > 0 then
		return true, false
	end
	local node: Instance? = p.Parent
	while node and node ~= root do
		for _, tag in CollectionService:GetTags(node) do
			if tag ~= "MinigameStation" then
				return true, false
			end
		end
		node = node.Parent
	end
	for _, d in p:GetDescendants() do
		if d:IsA("ProximityPrompt") or d:IsA("LayerCollector") or d:IsA("LuaSourceContainer") or d:IsA("ClickDetector") then
			return true, true
		end
	end
	return false, false
end

-- the bounding box of a model's look (skips invisible parts)
local function lookBox(parts: { BasePart }, frame: CFrame): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in parts do
		local h = p.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = frame:PointToObjectSpace(p.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
					lo = lo:Min(w)
					hi = hi:Max(w)
				end
			end
		end
	end
	return lo, hi
end

-- splits a model's visible parts: look (goes) / hide (prompt or gui holders) / kept (everything else that works)
local function sortParts(root: Instance, keep: { [string]: boolean }): ({ BasePart }, { BasePart }, { BasePart })
	local look, hide, kept = {}, {}, {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local works, onlyHolds = working(d, keep, root)
			table.insert(if not works then look elseif onlyHolds then hide else kept, d)
		end
	end
	return look, hide, kept
end

-- the NormalId of part whose world direction is closest to dir
local function faceToward(part: BasePart, dir: Vector3): Enum.NormalId
	local best, bestDot = Enum.NormalId.Front, -2
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id)):Dot(dir)
		if d > bestDot then
			best, bestDot = id, d
		end
	end
	return best
end

type Opts = {
	keep: { string }?, -- part names to keep as they are
	anchor: { string }?, -- { oldPart, kitPart }: the yaw that lands kitPart nearest oldPart wins (else yaw)
	yaw: number?, -- degrees about the model's up axis
	offset: Vector3?, -- extra shift in the old frame
	guis: { [string]: string }?, -- old part name -> kit part name: its SurfaceGuis move onto the mesh
	drop: { string }?, -- kit mesh name patterns not to install (the live part stays instead)
	frame: CFrame?,
	dry: boolean?,
}

-- swap(old, kitModel, opts): see the header and Opts
local function swap(old: Model, kit: Model, opts: Opts): (Model | string)
	local keep = {}
	for _, n in opts.keep or {} do
		keep[n] = true
	end
	if old:GetAttribute("OverhaulKit") then
		error(old:GetFullName() .. " is already swapped")
	end
	local frame = opts.frame or old:GetPivot()
	local oldLook, hide, kept = sortParts(old, keep)
	if opts.dry then
		local function names(list)
			local t = {}
			for _, p in list do
				t[p.Name] = (t[p.Name] or 0) + 1
			end
			local s = {}
			for n, c in t do
				table.insert(s, n .. (if c > 1 then "x" .. c else ""))
			end
			return table.concat(s, " ")
		end
		return old:GetFullName() .. ": look " .. #oldLook .. " | hide " .. names(hide) .. " | kept " .. names(kept)
	end
	local olo, ohi = lookBox(if #oldLook > 0 then oldLook else hide, frame)
	local new = kit:Clone()
	for _, d in new:GetDescendants() do
		for _, pat in opts.drop or {} do
			if d:IsA("BasePart") and string.match(d.Name, pat) then
				d:Destroy()
				break
			end
		end
	end
	local kframe = CFrame.new(new:GetPivot().Position)
	local meshes, rel = {}, {}
	for _, d in new:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(meshes, d)
			rel[d] = kframe:ToObjectSpace(d.CFrame)
		end
	end
	-- put the kit model in the old frame, turned by yaw, its look box lined up with the old one
	local function place(yawDeg: number)
		local yaw = CFrame.Angles(0, math.rad(yawDeg), 0)
		for _, p in meshes do
			p.CFrame = frame * yaw * rel[p]
		end
		local nlo, nhi = lookBox(meshes, frame)
		local shift = Vector3.new((olo.X + ohi.X) / 2 - (nlo.X + nhi.X) / 2, olo.Y - nlo.Y, (olo.Z + ohi.Z) / 2 - (nlo.Z + nhi.Z) / 2)
			+ (opts.offset or Vector3.zero)
		local move = frame * CFrame.new(shift) * frame:Inverse()
		for _, p in meshes do
			p.CFrame = move * p.CFrame
			p.Anchored = true
		end
	end
	local yaw = opts.yaw or 0
	if opts.anchor then
		local a = old:FindFirstChild(opts.anchor[1], true) :: BasePart
		local bestD = math.huge
		for _, y in { 0, 90, 180, 270 } do
			place(y)
			local b = new:FindFirstChild(opts.anchor[2], true) :: BasePart
			local d = (a.Position - b.Position).Magnitude
			if d < bestD then
				bestD, yaw = d, y
			end
		end
	end
	place(yaw)
	-- guis onto the meshes (same world facing)
	for from, to in opts.guis or {} do
		for _, src in old:GetDescendants() do
			if src.Name == from and src:IsA("BasePart") then
				local dst = new:FindFirstChild(to, true) :: BasePart?
				if dst then
					for _, g in src:GetChildren() do
						if g:IsA("SurfaceGui") then
							local dir = src.CFrame:VectorToWorldSpace(Vector3.FromNormalId(g.Face))
							g.Face = faceToward(dst, dir)
							g.Parent = dst
						end
					end
				end
			end
		end
	end
	-- old look parts out (whole child branches when nothing in them works); prompt / gui holders go invisible
	local arch = archiveFolder(old.Name)
	for _, p in oldLook do
		if p.Parent then
			p.Parent = arch
		end
	end
	for _, p in hide do
		if #p:GetChildren() == 0 then
			p.Parent = arch -- its gui moved onto a mesh
		else
			p.Transparency = 1
			p.CanCollide = false
			p.CastShadow = false
			for _, d in p:GetChildren() do
				if d:IsA("Decal") or d:IsA("Texture") then
					d.Transparency = 1
				end
			end
		end
	end
	for _ = 1, 3 do
		for _, c in old:GetDescendants() do
			if (c:IsA("Model") or c:IsA("Folder")) and #c:GetDescendants() == 0 and #CollectionService:GetTags(c) == 0 then
				c.Parent = arch
			end
		end
	end
	for _, c in new:GetChildren() do
		c.Parent = old
	end
	new:Destroy()
	old:SetAttribute("OverhaulKit", kit.Name)
	return old
end

local function group(model: Instance, name: string, pattern: string): Model
	local g = Instance.new("Model")
	g.Name = name
	for _, c in model:GetChildren() do
		if c:IsA("BasePart") and string.match(c.Name, pattern) then
			c.Parent = g
		end
	end
	g.Parent = model
	return g
end

local STEPS = {}

-- Hub.TravelPortal: the round v2 portal mesh. Travel.client wants SwirlDisc, SwirlArms (Model), SwirlCore, Gem1-6
-- (attr Zone), FloatRing1-3 (Models), Beam, Sign* parts + SignPlate (SurfaceGui), Trigger.
function STEPS.portal()
	local old = workspace.Hub.TravelPortal
	local gems = {}
	for i = 1, 6 do
		local g = old:FindFirstChild("Gem" .. i)
		gems[i] = g and g:GetAttributes() or {}
	end
	local plate = old:FindFirstChild("SignPlate")
	local gui = plate and plate:FindFirstChildWhichIsA("SurfaceGui")
	if gui then
		gui.Parent = nil
	end
	swap(old, KIT.portal.TravelPortal, { keep = { "Trigger" } })
	for i = 1, 3 do
		group(old, "FloatRing" .. i, "^FloatRing" .. i .. "_")
	end
	group(old, "SwirlArms", "^SwirlArm%d$")
	for i = 1, 6 do
		local g = old:FindFirstChild("Gem" .. i)
		if g then
			for k, v in gems[i] do
				g:SetAttribute(k, v)
			end
		end
	end
	local newPlate = old:FindFirstChild("SignPlate")
	if gui and newPlate then
		gui.Face = Enum.NormalId.Front
		gui.Parent = newPlate
	end
end

local function at(path: string): Model
	local node: Instance = workspace
	for name in string.gmatch(path, "[^%.]+") do
		node = node:FindFirstChild(name) or error("nothing at Workspace." .. path)
	end
	return node :: Model
end

-- the plain swaps: { live model, kit group, kit model, opts }
local SIMPLE = {
	shop = { { "Hub.ShopStall", "gameplay", "gameplay_shop_stall", { anchor = { "Sign", "ShopStall_Sign" }, guis = { Sign = "ShopStall_Sign" } } } },
	counters = {},
	booths = {},
	boards = {},
	spots = {
		-- the judge stays a Part figure until the character stage (crnuch); peekers / cases / bulbs stay (tagged, animated).
		-- yaw, not a sign anchor: the kit's sign stands on the other side of the spot, so the anchor turned it 90 degrees
		-- (the spots' pivots are turned 90; 270 puts the kit's front on the old front)
		{ "Hub.SpecialSpots.SpecialSpot1", "minigames", "minigames_gavel_bonk", { yaw = 270, guis = { Sign = "GavelBonk_Sign" }, keep = { "^Judge" } } },
		{ "Hub.SpecialSpots.SpecialSpot2", "minigames", "minigames_lucky_briefcase", { yaw = 270, guis = { Sign = "LuckyBriefcase_Sign", Board = "LuckyBriefcase_Board" }, drop = { "^LuckyBriefcaseBulb_", "^LuckyBriefcaseCase_" } } },
	},
}
for _, id in { "License", "Carry", "Speed" } do
	table.insert(SIMPLE.counters, { "Zones.LicenseOffice.Counter_" .. id, "gameplay", "gameplay_counter_" .. id, { anchor = { "DeskTop", "Counter" .. id .. "_Top" } } })
end
for _, id in { "LieDetector", "BriefcaseStack", "FilingFrenzy" } do
	local b = "Booth" .. id .. "_"
	table.insert(SIMPLE.booths, { "ArcadePier.Booths." .. id, "minigames", "minigames_booth_" .. id, { anchor = { "Marquee", b .. "Marquee" }, guis = { Marquee = b .. "Marquee", Screen = b .. "Screen" } } })
end
for _, id in { "TopLawyer", "Wins", "Richest", "BestPayout" } do
	table.insert(SIMPLE.boards, { "Hub.Leaderboards." .. id, "gameplay", "gameplay_leaderboard", { anchor = { "Face", "Leaderboard_Face" }, guis = { Header = "Leaderboard_Header", Face = "Leaderboard_Face" } } })
end

local DRY = false
for name, list in SIMPLE do
	STEPS[name] = function()
		local report = {}
		for _, s in list do
			local opts = table.clone(s[4])
			opts.dry = DRY
			local r = swap(at(s[1]), KIT[s[2]][s[3]], opts)
			table.insert(report, if type(r) == "string" then r else s[1] .. " ok")
		end
		return table.concat(report, "\n")
	end
end

-- Hub.BigCaseBelt: the belt mesh, but the live slats stay (BigCase.client scrolls each part in Slats; the kit's slats
-- are one joined mesh), laid on the new belt in the slat mesh's colour
function STEPS.belt()
	local old = at("Hub.BigCaseBelt")
	local slats = old:FindFirstChild("Slats")
	if DRY then
		return swap(old, KIT.gameplay.gameplay_case_belt, { dry = true, drop = { "^BigCaseBelt_Slat$" } })
	end
	slats.Parent = nil
	swap(old, KIT.gameplay.gameplay_case_belt, { drop = { "^BigCaseBelt_Slat$" } })
	local belt = old:FindFirstChild("BigCaseBelt_Belt") :: BasePart
	local look = KIT.gameplay.gameplay_case_belt.BigCaseBelt_Slat
	local top = belt.Position.Y + belt.Size.Y / 2
	for _, p in slats:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame += Vector3.new(0, top + p.Size.Y / 2 + 0.02 - p.Position.Y, 0)
			p.Color = look.Color
			p.Material = look.Material
		end
	end
	slats.Parent = old
	return "belt ok"
end

-- as a ModuleScript (ServerStorage.InstallOverhaulKit while installing; removed after):
--   require(game.ServerStorage.InstallOverhaulKit:Clone())("portal")      (second arg true = dry run: report only)
return function(step: string, dry: boolean?)
	DRY = dry == true
	if DRY then
		return STEPS[step]()
	end
	local rec = ChangeHistoryService:TryBeginRecording("InstallOverhaulKit " .. step)
	local ok, err = pcall(STEPS[step])
	if rec then
		ChangeHistoryService:FinishRecording(rec, if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel)
	end
	if not ok then
		error(err)
	end
	return "done: " .. step .. (if type(err) == "string" then "\n" .. err else "")
end
