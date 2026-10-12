--!strict
-- The firm: EXPAND FIRM (buys the next office segment, Config.Firm.ExpandCosts; the building is rebuilt
-- one segment longer with 2 more EMPTY offices for hatched lawyers). Since v12 there is no hiring
-- (lawyers come from eggs and are placed via LawyerService) and no desk purchases (an office's look
-- follows its level, Config.Desks.Tiers). The EXPAND FIRM sign sits at the firm's UpgradeSpot in the
-- expansion area; only the owner can use its prompt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local CaseService = require(script.Parent.CaseService)
local DeskLook = require(script.Parent.DeskLook)
local FirmBuilder = require(script.Parent.FirmBuilder)

local UpgradeDesk = ReplicatedStorage.Remotes.UpgradeDesk :: RemoteFunction
local Templates = ServerStorage:WaitForChild("Templates")

local COOLDOWN = 0.3
local OWNER_ONLY_TAG = "OwnerOnlyPrompt" -- StarterPlayerScripts.OwnerPrompts hides these on other players' firms

local DeskService = {}

local lastRequest: { [Player]: number } = {}

local function deskModel(player: Player, index: number): Model?
	local firm = PlotService.getFirm(player)
	local desk = firm and firm:FindFirstChild("Desk" .. index)
	return if desk and desk:IsA("Model") then desk else nil
end

local function slotFor(firm: Model, index: number): BasePart?
	local slots = firm:FindFirstChild("DeskSlots")
	local slot = slots and slots:FindFirstChild("Slot" .. index)
	return if slot and slot:IsA("BasePart") then slot else nil
end

-- Builds Desk<index> at its slot from a clean copy of the template desk.
local function buildDesk(firm: Model, index: number): Model?
	local slot = slotFor(firm, index)
	local template = Templates.Firm:FindFirstChild("Desk1") :: Model?
	if not slot or not template or firm:FindFirstChild("Desk" .. index) then
		return nil
	end
	local desk = template:Clone()
	desk.Name = "Desk" .. index
	desk:SetAttribute("DeskIndex", index)
	desk:PivotTo(slot.CFrame)
	desk.Parent = firm
	return desk
end

local function cartoonPart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs -- studded like the rest of the map
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function expandCost(segment: number): number
	return Config.Firm.ExpandCosts[segment] or math.huge
end

local function label(gui: SurfaceGui, text: string, y: number, h: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromScale(0.04, y)
	l.Size = UDim2.fromScale(0.92, h)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = text
	l.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	return l
end

-- Puts the "UPGRADE FIRM" faceplate at the firm's UpgradeSpot (or removes it at the top tier).
local function refreshUpgradeSign(player: Player)
	local firm = PlotService.getFirm(player)
	local data = PlayerData.get(player)
	if not firm or not data then
		return
	end
	local old = firm:FindFirstChild("UpgradeSign")
	if old then
		old:Destroy()
	end
	local index = data.Firm.Segments + 1
	local spot = firm:FindFirstChild("UpgradeSpot") :: BasePart?
	if index > Config.Firm.MaxSegments or not spot then
		return
	end
	-- floor level at the spot, turned to face the aisle / entrance
	local at = spot.CFrame * CFrame.new(0, -spot.Size.Y / 2, 0) * CFrame.Angles(0, math.pi, 0)

	local sign = Instance.new("Model")
	sign.Name = "UpgradeSign"
	sign:SetAttribute("NextTier", index)
	-- upright voxel billboard on two wood posts (like the reference "Roll" sign): dark wood frame,
	-- green board, terracotta cap, glowing pad on the floor in front
	local woodDark, wood = Color3.fromRGB(92, 48, 22), Color3.fromRGB(170, 104, 52) -- mr.robe's courtroom woods
	for _, x in { -3.9, 3.9 } do
		cartoonPart(sign, "Post", Vector3.new(0.9, 5.8, 0.9), at * CFrame.new(x, 2.9, 0.3), woodDark)
		cartoonPart(sign, "PostCap", Vector3.new(1.2, 0.4, 1.2), at * CFrame.new(x, 6.0, 0.3), wood)
	end
	cartoonPart(sign, "Frame", Vector3.new(8.4, 4.0, 0.5), at * CFrame.new(0, 3.9, 0.35), woodDark)
	cartoonPart(sign, "Cap", Vector3.new(9.0, 0.5, 1.0), at * CFrame.new(0, 6.15, 0.35), Color3.fromRGB(150, 30, 30))
	cartoonPart(sign, "Trim", Vector3.new(7.9, 3.6, 0.2), at * CFrame.new(0, 3.9, 0.08), Color3.fromRGB(255, 190, 50), Enum.Material.Metal)
	local board = cartoonPart(sign, "Faceplate", Vector3.new(7.6, 3.3, 0.3), at * CFrame.new(0, 3.9, 0.0), Color3.fromRGB(30, 110, 50))
	cartoonPart(sign, "Pad", Vector3.new(6, 0.12, 2.6), at * CFrame.new(0, 0.08, -2.2), Color3.fromRGB(80, 230, 110), Enum.Material.Neon)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	label(gui, "EXPAND FIRM", 0.06, 0.38, Color3.new(1, 1, 1))
	label(gui, "+2 offices for new lawyers", 0.46, 0.2, Color3.fromRGB(255, 240, 160)).Font = Enum.Font.BuilderSansMedium
	label(gui, Formulas.formatCoins(expandCost(index)) .. " coins", 0.68, 0.27, Color3.fromRGB(255, 210, 50))
	gui.Parent = board

	require(game:GetService("ReplicatedStorage").Shared.Effects).ambient(board, "star", Color3.fromRGB(120, 255, 140), 0.8)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.ActionText = "Expand Firm"
	prompt.ObjectText = Formulas.formatCoins(expandCost(index)) .. " coins"
	prompt.HoldDuration = 0.8 -- a short hold so nobody spends millions by accident
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	CollectionService:AddTag(prompt, OWNER_ONLY_TAG)
	prompt.Parent = board
	prompt.Triggered:Connect(function(who)
		if who ~= player then
			return
		end
		local ok, reason = DeskService.upgradeFirm(player)
		if not ok and prompt.Parent then
			prompt.ActionText = reason or "Can't expand yet"
			task.delay(1.5, function()
				if prompt.Parent then
					prompt.ActionText = "Expand Firm"
				end
			end)
		end
	end)

	sign.Parent = firm
end

-- Desks are built with the firm by FirmBuilder now; kept so callers don't need to change.
function DeskService.buildDesks(_player: Player) end

-- Puts up the EXPAND FIRM sign. Call once the firm is running (CaseService dresses each office).
function DeskService.dress(player: Player)
	if PlayerData.get(player) then
		refreshUpgradeSign(player)
	end
end

-- Expands the firm by one office segment: charges the player, rebuilds the building one segment longer
-- (2 empty offices to hire into) and restarts every desk on it. Cases in progress finish first and pay out
-- (CaseService.finishAll), so expanding never costs a case.
function DeskService.upgradeFirm(player: Player): (boolean, string?)
	local t = os.clock()
	if t - (lastRequest[player] or 0) < COOLDOWN then
		return false, "Slow down!"
	end
	lastRequest[player] = t

	local data = PlayerData.get(player)
	if not data or not PlotService.getFirm(player) then
		return false, "Still loading"
	end
	local index = data.Firm.Segments + 1
	if index > Config.Firm.MaxSegments then
		return false, "Biggest firm already!"
	end
	if not PlayerData.spendCoins(player, expandCost(index)) then
		return false, "Need " .. Formulas.formatCoins(expandCost(index)) .. "!"
	end
	data.Firm.Segments = index
	while #data.Desks < index * 2 do
		table.insert(data.Desks, PlayerData.newDesk()) -- 2 new empty offices
	end
	PlayerData.sync(player)
	task.spawn(require(script.Parent.BadgeAwards).award, player, "SecondLawyer") -- (badge calls can yield / throw)

	CaseService.finishAll(player) -- running cases pay out now instead of vanishing in the rebuild
	CaseService.stop(player)
	local firm = PlotService.rebuild(player)
	if firm then
		DeskService.buildDesks(player)
		CaseService.start(player, firm)
		DeskService.dress(player)
		require(script.Parent.ManagerService).setupFirm(player) -- the new building needs the Manager back
	end
	return true, nil
end

-- (Old desk purchases. Offices now change look with their level, so this only explains that.)
local function upgrade(_player: Player, _deskIndex: unknown): (boolean, string?)
	return false, "Offices upgrade with their level now!"
end

function DeskService.start()
	UpgradeDesk.OnServerInvoke = upgrade
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return DeskService
