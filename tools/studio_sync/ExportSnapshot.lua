-- Exports every script in the open place into the repo's studio/ folder (run from the Studio MCP execute_luau
-- in Edit mode, or the command bar, while tools/studio_sync/receive_snapshot.ps1 is listening on PORT).
-- Layout: studio/<Service>/<Parent>/.../<Name><suffix>  (.server.lua / .client.lua / .lua for ModuleScripts)
-- plus studio/MANIFEST.json (Studio path, class, Enabled, line count for every file). The snapshot is
-- READ-ONLY: it shows what is live; edit src/ (or Studio) instead, then re-export.

local HttpService = game:GetService("HttpService")
local PORT = 8767
local SERVICES = {
	"Workspace", "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
	"StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService", "Teams", "TextChatService",
}

local function suffix(s: LuaSourceContainer): string
	if s:IsA("LocalScript") then
		return ".client.lua"
	elseif s:IsA("Script") then
		return if (s :: Script).RunContext == Enum.RunContext.Client then ".client.lua" else ".server.lua"
	end
	return ".lua"
end

local function clean(name: string): string
	return (string.gsub(name, "[^%w%._%- ]", "_"))
end

local function post(rel: string, body: string)
	HttpService:PostAsync("http://localhost:" .. PORT .. "/save?path=" .. HttpService:UrlEncode(rel), body, Enum.HttpContentType.TextPlain)
end

local manifest = {}
local used: { [string]: boolean } = {}
for _, serviceName in SERVICES do
	local ok, service = pcall(game.GetService, game, serviceName)
	if not ok or not service then
		continue
	end
	for _, s in service:GetDescendants() do
		if not s:IsA("LuaSourceContainer") then
			continue
		end
		local parts = {}
		local node: Instance? = s
		while node and node ~= game do
			table.insert(parts, 1, clean(node.Name))
			node = node.Parent
		end
		local base = table.concat(parts, "/")
		local rel = base .. suffix(s)
		local n = 1
		while used[rel] do
			n += 1
			rel = base .. "_" .. n .. suffix(s)
		end
		used[rel] = true
		local source = (s :: any).Source :: string
		post(rel, source)
		local _, lines = string.gsub(source, "\n", "")
		table.insert(manifest, {
			file = rel,
			studio = s:GetFullName(),
			class = s.ClassName,
			enabled = if s:IsA("BaseScript") then (s :: BaseScript).Enabled else nil,
			lines = lines + 1,
		})
	end
end
table.sort(manifest, function(a, b)
	return a.file < b.file
end)
post("MANIFEST.json", HttpService:JSONEncode(manifest))
pcall(HttpService.GetAsync, HttpService, "http://localhost:" .. PORT .. "/done")
return #manifest .. " scripts exported"
