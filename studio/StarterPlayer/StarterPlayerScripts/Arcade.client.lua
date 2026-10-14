--!strict
-- Arcade (StarterPlayerScripts.Arcade; 2026-10-13, mr.robe's session) - the client side of the Arcade Pier's booth
-- games (server: ServerScriptService.ArcadeServer; tuning: Config.Arcade; the games: ReplicatedStorage.ArcadeClient).
--   * "Start" from the server runs ArcadeClient.<game>.play(info, api); api.send(kind, data) sends an input (stamped
--     with the server time it happened), api.onAck(fn) hears the server's answers, api.result() waits for the score.
--   * the booth boards: every booth (tag ArcadeStation, attribute ArcadeGame) has a Board SurfaceGui (built by
--     tools/zones/BuildArcadePier.lua); this script writes PLAY! / READY IN m:ss on it from Arcade<Id>Ready.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript) :: any
local Client = ReplicatedStorage:WaitForChild("ArcadeClient")
local Kit = require(Client:WaitForChild("Kit") :: ModuleScript) :: any
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Arcade") :: RemoteEvent

local CFG = Config.Arcade

type Active = { id: number, acks: { (any) -> () }, result: any? }
local active: Active? = nil

Remote.OnClientEvent:Connect(function(kind: string, info: any)
	if kind == "Start" then
		local mod = Client:FindFirstChild(info.game)
		if not mod or not mod:IsA("ModuleScript") then
			return
		end
		local a: Active = { id = info.id, acks = {}, result = nil }
		active = a
		local api = {
			cfg = CFG[info.game],
			kit = Kit,
			send = function(k: string, data: { [string]: any }?)
				local d = data or {}
				if d.t == nil then
					d.t = workspace:GetServerTimeNow()
				end
				Remote:FireServer("Input", a.id, k, d)
			end,
			onAck = function(fn: (any) -> ())
				table.insert(a.acks, fn)
			end,
			-- waits for the server's score (it comes when the round ends; 25 s at most)
			result = function(): any?
				local t0 = os.clock()
				while not a.result and os.clock() - t0 < 25 do
					task.wait(0.05)
				end
				return a.result
			end,
		}
		task.spawn(function()
			local ok, err = pcall((require(mod) :: any).play, info, api)
			if not ok then
				warn("[Arcade] " .. tostring(info.game) .. ": " .. tostring(err))
			end
			if active == a then
				active = nil
			end
		end)
	elseif kind == "Ack" then
		local a = active
		if a and info.id == a.id then
			for _, fn in a.acks do
				task.spawn(fn, info)
			end
		end
	elseif kind == "Result" then
		local a = active
		if a and info.id == a.id then
			a.result = info
		elseif info.reward and info.reward ~= "" then
			Kit.toast(info.reward)
		end
	elseif kind == "Note" then
		Kit.toast(info.text or "")
	end
end)

------------------------------------------------------------------ booth boards
local boards: { [Instance]: { status: TextLabel, id: string } } = {}
local function addStation(m: Instance)
	local id = m:GetAttribute("ArcadeGame")
	if type(id) ~= "string" or boards[m] then
		return
	end
	task.spawn(function()
		local board = m:WaitForChild("Board", 20)
		local status = board and board:FindFirstChild("Status", true)
		if status and status:IsA("TextLabel") then
			boards[m] = { status = status, id = id }
		end
	end)
end
CollectionService:GetInstanceAddedSignal("ArcadeStation"):Connect(addStation)
CollectionService:GetInstanceRemovedSignal("ArcadeStation"):Connect(function(m)
	boards[m] = nil
end)
for _, m in CollectionService:GetTagged("ArcadeStation") do
	addStation(m)
end
task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		for m, b in boards do
			if not m.Parent then
				boards[m] = nil
				continue
			end
			local readyAt = player:GetAttribute("Arcade" .. b.id .. "Ready")
			local left = if typeof(readyAt) == "number" then readyAt - now else 0
			if left <= 0 then
				b.status.Text = "PLAY!"
				b.status.TextColor3 = Color3.fromRGB(140, 240, 100)
			else
				local s = math.ceil(left)
				b.status.Text = string.format("READY IN %d:%02d", s // 60, s % 60)
				b.status.TextColor3 = Color3.fromRGB(200, 204, 224)
			end
		end
		task.wait(0.5)
	end
end)
