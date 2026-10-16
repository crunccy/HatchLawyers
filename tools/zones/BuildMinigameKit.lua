-- Install the version-2 Blender data into the shared cinematic renderer.
-- Run in Studio Edit mode while serve_files.ps1 serves tools/zones on :8766.
-- The client code that plays it lives in Studio (snapshot: studio/ReplicatedStorage/MinigameClient + ArcadeClient).
local HttpService=game:GetService('HttpService')
local RS=game:GetService('ReplicatedStorage')
local json=HttpService:GetAsync('http://localhost:8766/minigame_kit.json',true)
local data=HttpService:JSONDecode(json)
assert(data.version==2 and data.groups and data.clips,'Expected Blender minigame kit version 2')
local folder=RS:FindFirstChild('MinigameClient')
if not folder then folder=Instance.new('Folder');folder.Name='MinigameClient';folder.Parent=RS end
local source=folder:FindFirstChild('AssetData')
if not source then source=Instance.new('ModuleScript');source.Name='AssetData';source.Parent=folder end
source.Source='return game:GetService("HttpService"):JSONDecode([==['..json..']==])'
local models,parts,clips=0,0,0
for _,rows in data.models do models+=1;parts+=#rows end
for _ in data.clips do clips+=1 end
return string.format('Installed %d models, %d parts and %d Blender clips. Start a new Play session to refresh require caches.',models,parts,clips)
