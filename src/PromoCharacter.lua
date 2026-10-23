--!strict
-- Server-owned, disposable character controls for authenticated promo sessions only.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerData = require(script.Parent.Server.PlayerData) :: any
local Policy = require(script.Parent.PromoPolicy)
local Character = {}
local states: { [Player]: any } = {}
local SPEED = 60
local function allowed(player: Player): boolean
	return Policy.isAllowed(player.UserId) and PlayerData.isPromo(player)
end
local function state(player: Player): any
	if not states[player] then states[player] = { hidden = {}, flight = nil } end
	return states[player]
end
local function stopFlight(player: Player)
	local s = states[player]
	local f = s and s.flight
	if not f then return end
	s.flight = nil
	f.velocity:Destroy()
	f.attachment:Destroy()
	if f.humanoid.Parent then f.humanoid.AutoRotate = f.autoRotate end
	if f.root.Parent then
		f.root.AssemblyLinearVelocity = Vector3.zero
		pcall(function() f.root:SetNetworkOwnershipAuto() end)
	end
end
local function reveal(player: Player)
	local s = states[player]
	if not s then return end
	if s.added then s.added:Disconnect() s.added = nil end
	for object, properties in s.hidden do
		if object.Parent then
			for property, value in properties do (object :: any)[property] = value end
		end
	end
	table.clear(s.hidden)
	s.invisible = false
end
function Character.reset(player: Player)
	stopFlight(player)
	reveal(player)
end
function Character.set(player: Player, action: string, mode: string): boolean
	if not allowed(player) then Character.reset(player) return false end
	local model = player.Character
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not model or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return false end
	local s = state(player)
	local active = if action == "fly" then s.flight ~= nil else s.invisible == true
	local enable = mode == "on" or (mode == "toggle" and not active)
	if action == "fly" then
		stopFlight(player)
		if enable then
			local attachment = Instance.new("Attachment")
			attachment.Name = "PromoFlightAttachment"
			attachment.Parent = root
			local velocity = Instance.new("LinearVelocity")
			velocity.Name = "PromoFlightVelocity"
			velocity.Attachment0 = attachment
			velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			velocity.MaxForce = math.max(root.AssemblyMass * workspace.Gravity * 10, 10000)
			velocity.VectorVelocity = Vector3.zero
			velocity.Parent = root
			pcall(function() root:SetNetworkOwner(nil) end)
			s.flight = { root = root, humanoid = humanoid, autoRotate = humanoid.AutoRotate, attachment = attachment, velocity = velocity, lastInput = os.clock() }
			humanoid.AutoRotate = false
		end
	elseif action == "invisible" then
		reveal(player)
		if enable then
			s.invisible = true
			local function hide(object: Instance)
				local properties: any = nil
				if object:IsA("BasePart") or object:IsA("Decal") then properties = { Transparency = object.Transparency }
				elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("BillboardGui") then properties = { Enabled = object.Enabled }
				elseif object:IsA("Humanoid") then properties = { DisplayDistanceType = object.DisplayDistanceType } end
				if not properties or s.hidden[object] then return end
				s.hidden[object] = properties
				if properties.Transparency ~= nil then (object :: any).Transparency = 1
				elseif properties.Enabled ~= nil then (object :: any).Enabled = false
				else (object :: any).DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			end
			s.added = model.DescendantAdded:Connect(hide)
			for _, object in model:GetDescendants() do hide(object) end
		end
	end
	return true
end
function Character.isFlying(player: Player): boolean
	return states[player] ~= nil and states[player].flight ~= nil
end
function Character.bind(remote: RemoteEvent)
	remote.OnServerEvent:Connect(function(player: Player, direction: any)
		local s = states[player]
		local f = s and s.flight
		if not f then return end
		if not allowed(player) then Character.reset(player) return end
		local now = os.clock()
		if f.lastPacket and now - f.lastPacket < 0.04 then return end
		f.lastPacket = now
		if typeof(direction) ~= "Vector3" then return end
		if direction.X ~= direction.X or direction.Y ~= direction.Y or direction.Z ~= direction.Z or direction.Magnitude > 1.01 then return end
		f.lastInput = now
		f.velocity.VectorVelocity = direction * SPEED
	end)
	RunService.Heartbeat:Connect(function()
		for player, s in states do
			local f = s.flight
			if not allowed(player) or (f and (not f.root.Parent or f.humanoid.Health <= 0)) then
				Character.reset(player)
			elseif f and os.clock() - f.lastInput > 0.3 then
				f.velocity.VectorVelocity = Vector3.zero
			end
		end
	end)
	local function hook(player: Player)
		player.CharacterRemoving:Connect(function() Character.reset(player) end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do hook(player) end
	Players.PlayerRemoving:Connect(function(player) Character.reset(player) states[player] = nil end)
end
return Character
