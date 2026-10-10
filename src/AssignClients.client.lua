--!strict
-- [E] Assign Client prompts on waiting clients (user's call 2026-10-09). Walk up to one of YOUR waiting clients and
-- Roblox's standard ProximityPrompt shows "[E] Assign Client"; pressing E opens the LAWYERS panel's CLIENTS tab
-- (StarterPlayerScripts.Lawyers, lawyer-management overhaul 2026-10-09: assigning lives there now) with this
-- client highlighted and the best free office preselected. The client gets a gold outline while the panel is open.
-- Once a Manager is hired they assign clients themselves, so the prompts switch off. Prompts are made on this
-- client only (one per client model, tracked by the FirmClient tag), so other players never see prompts for your
-- clients. Clients carry ClientName / Tier / WaitingId / Waiting / OwnerUserId attributes (Server.CaseService).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GOLD = Color3.fromRGB(255, 200, 40)

local function lawyersUI(): BindableEvent
	local e = ReplicatedStorage:FindFirstChild("LawyersUI") :: BindableEvent?
	if not e then
		e = Instance.new("BindableEvent")
		;(e :: BindableEvent).Name = "LawyersUI"
		;(e :: BindableEvent).Parent = ReplicatedStorage
	end
	return e :: BindableEvent
end

local highlight = Instance.new("Highlight")
highlight.Name = "AssignTarget"
highlight.FillTransparency = 1
highlight.OutlineColor = GOLD
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = playerGui

local PROMPT_DISTANCE = 8 -- studs: walk right up to the client (sofas are close together)
local prompts: { [Model]: { prompt: ProximityPrompt, conns: { RBXScriptConnection } } } = {}

local function promptShouldShow(model: Model): boolean
	return model:GetAttribute("Waiting") == true and model:GetAttribute("OwnerUserId") == player.UserId
		and player:GetAttribute("ManagerHired") ~= true
end

local function refreshPrompt(model: Model)
	local entry = prompts[model]
	if entry then
		entry.prompt.Enabled = promptShouldShow(model)
		entry.prompt.ObjectText = (model:GetAttribute("ClientName") :: string?) or "Client"
	end
end

local function untrackClient(model: Instance)
	local entry = prompts[model :: Model]
	if entry then
		for _, c in entry.conns do
			c:Disconnect()
		end
		entry.prompt:Destroy()
		prompts[model :: Model] = nil
	end
end

local function trackClient(model: Instance)
	if not model:IsA("Model") or prompts[model] or model:GetAttribute("OwnerUserId") ~= player.UserId then
		return -- not mine (other players' clients never get a prompt here), or already has one
	end
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if not (root and root:IsA("BasePart")) then
		return
	end
	local old = root:FindFirstChild("AssignPrompt")
	if old then
		old:Destroy() -- never two prompts on one client
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AssignPrompt"
	prompt.ActionText = "Assign Client"
	prompt.ObjectText = (model:GetAttribute("ClientName") :: string?) or "Client"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false -- the couches' backs would otherwise block it
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton -- crowded sofas: only the nearest client
	prompt.Enabled = false
	prompt.Parent = root
	local entry = { prompt = prompt, conns = {} }
	prompts[model] = entry
	table.insert(entry.conns, prompt.Triggered:Connect(function()
		local id = model:GetAttribute("WaitingId")
		if promptShouldShow(model) and typeof(id) == "number" then
			highlight.Adornee = model
			highlight.Enabled = true
			lawyersUI():Fire({ client = id, tab = "Clients" })
		end
	end))
	table.insert(entry.conns, model:GetAttributeChangedSignal("Waiting"):Connect(function()
		refreshPrompt(model)
	end))
	table.insert(entry.conns, model:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		refreshPrompt(model)
	end))
	refreshPrompt(model)
end

CollectionService:GetInstanceAddedSignal("FirmClient"):Connect(function(model)
	task.defer(trackClient, model) -- let its parts and attributes replicate first
end)
CollectionService:GetInstanceRemovedSignal("FirmClient"):Connect(untrackClient)
for _, model in CollectionService:GetTagged("FirmClient") do
	trackClient(model)
end
player:GetAttributeChangedSignal("ManagerHired"):Connect(function()
	for model in prompts do
		refreshPrompt(model)
	end
end)

-- keep things fresh: late-streamed clients get prompts, gone ones lose them, the outline clears when the
-- LAWYERS panel closes or the client stops waiting
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, m in CollectionService:GetTagged("FirmClient") do
			if m:IsA("Model") and not prompts[m] and m:GetAttribute("Waiting") == true then
				trackClient(m)
			end
		end
		for model in prompts do
			if not model:IsDescendantOf(workspace) then
				untrackClient(model)
			end
		end
		local target = highlight.Adornee
		if target then
			local lawyersGui = playerGui:FindFirstChild("Lawyers")
			local panel = lawyersGui and lawyersGui:FindFirstChild("Panel") :: GuiObject?
			if not (panel and panel.Visible) or not target:IsDescendantOf(workspace) or target:GetAttribute("Waiting") ~= true then
				highlight.Adornee = nil
				highlight.Enabled = false
			end
		end
	end
end)
