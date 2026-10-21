--!strict
-- Client-only recording controls. The server creates PromoControl and only fires it for the allowlisted user.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local control = remotes:WaitForChild("PromoControl") :: RemoteEvent
local travel = remotes:WaitForChild("Travel") :: RemoteFunction

local guiState: { [ScreenGui]: boolean }? = nil
local function setGui(mode: string)
	if mode == "toggle" then mode = if guiState then "show" else "hide" end
	if mode == "hide" then
		if guiState then return end
		guiState = {}
		for _, gui in player.PlayerGui:GetChildren() do
			if gui:IsA("ScreenGui") then
				guiState[gui] = gui.Enabled
				gui.Enabled = false
			end
		end
	else
		if not guiState then return end
		for gui, enabled in guiState do
			if gui.Parent == player.PlayerGui then gui.Enabled = enabled end
		end
		guiState = nil
	end
end
player.PlayerGui.ChildAdded:Connect(function(child)
	if guiState and child:IsA("ScreenGui") then
		guiState[child] = child.Enabled
		child.Enabled = false
	end
end)

local cameraOn = false
local camera: Camera? = nil
local priorType: Enum.CameraType? = nil
local priorSubject: Instance? = nil
local priorMouse: Enum.MouseBehavior? = nil
local priorIcon = true
local position = Vector3.zero
local yaw, pitch = 0, 0
local held: { [Enum.KeyCode]: boolean } = {}
local cameraSpeed = 45

local function setCamera(mode: string)
	if mode == "toggle" then mode = if cameraOn then "off" else "on" end
	if mode == "on" and not cameraOn then
		camera = workspace.CurrentCamera
		if not camera then return end
		cameraOn = true
		priorType = camera.CameraType
		priorSubject = camera.CameraSubject
		priorMouse = UserInputService.MouseBehavior
		priorIcon = UserInputService.MouseIconEnabled
		position = camera.CFrame.Position
		local look = camera.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(math.clamp(look.Y, -1, 1))
		camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UserInputService.MouseIconEnabled = false
	elseif mode == "off" and cameraOn then
		cameraOn = false
		if camera then
			camera.CameraType = priorType or Enum.CameraType.Custom
			camera.CameraSubject = priorSubject
		end
		UserInputService.MouseBehavior = priorMouse or Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = priorIcon
		table.clear(held)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not cameraOn or processed then return end
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.LeftShift then
		held[input.KeyCode] = true
	elseif input.KeyCode == Enum.KeyCode.Equals then
		cameraSpeed = math.min(240, cameraSpeed * 1.25)
	elseif input.KeyCode == Enum.KeyCode.Minus then
		cameraSpeed = math.max(5, cameraSpeed / 1.25)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	held[input.KeyCode] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	if not cameraOn or not camera or workspace.CurrentCamera ~= camera then return end
	local delta = UserInputService:GetMouseDelta()
	yaw -= delta.X * 0.0025
	pitch = math.clamp(pitch - delta.Y * 0.0025, math.rad(-85), math.rad(85))
	local rotation = CFrame.fromOrientation(pitch, yaw, 0)
	local direction = Vector3.zero
	if held[Enum.KeyCode.W] then direction += rotation.LookVector end
	if held[Enum.KeyCode.S] then direction -= rotation.LookVector end
	if held[Enum.KeyCode.D] then direction += rotation.RightVector end
	if held[Enum.KeyCode.A] then direction -= rotation.RightVector end
	if held[Enum.KeyCode.E] then direction += Vector3.yAxis end
	if held[Enum.KeyCode.Q] then direction -= Vector3.yAxis end
	local multiplier = if held[Enum.KeyCode.LeftShift] then 3 else 1
	if direction.Magnitude > 0 then position += direction.Unit * cameraSpeed * multiplier * dt end
	camera.CFrame = CFrame.new(position) * rotation
end)

control.OnClientEvent:Connect(function(action: string, value: string)
	if player:GetAttribute("PromoMode") ~= true then return end
	if action == "gui" then
		setGui(value)
	elseif action == "cam" then
		setCamera(value)
	elseif action == "travel" then
		task.spawn(function()
			local ok, success, reason = pcall(function() return travel:InvokeServer(value) end)
			if not ok or success ~= true then warn("[PromoAdmin] Travel failed", if ok then reason else success) end
		end)
	end
end)

player.CharacterAdded:Connect(function()
	if cameraOn then setCamera("off") end
end)
