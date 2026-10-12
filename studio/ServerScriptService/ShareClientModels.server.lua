-- Copies the client characters (ServerStorage.Templates.Clients) to ReplicatedStorage.ClientModels so
-- the courtroom (StarterPlayerScripts.Courtroom) can dress the defendant as a different person than
-- the client. Players can't see ServerStorage, so without this the defendant was a clone of the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local source = ServerStorage:WaitForChild("Templates"):WaitForChild("Clients")
local copy = source:Clone()
copy.Name = "ClientModels"
for _, d in copy:GetDescendants() do
	if d:IsA("BaseScript") then
		d:Destroy()
	end
end
copy.Parent = ReplicatedStorage
