-- InstallAll (2026-10-10): rebuilds + installs every block-remade lawyer model from tools/skins/<Id>.lua in one go.
-- Use it if the place was closed without saving, or after editing SkinKit. Run in Studio's command bar (Edit mode)
-- with this repo served locally:  cd ~/HatchLawyers && python3 -m http.server 8766 --bind 127.0.0.1
-- It refreshes ServerStorage.SkinKit from tools/skins/SkinKit.lua first. Tralalero has no builder file (it was
-- built inline in Studio) - it is skipped here; it lives only in the saved place.
-- NOTE: the Hover/Sideways support lives in ReplicatedStorage.Shared.SkinLook / Puppet (Studio-only modules).
local BASE = "http://localhost:8766/tools/skins/"
local IDS = {
	-- Legendary
	"Bombardiro", "CappuccinoAvvocato", "TungTungSahur", "BurgerBoss", "BlackHoleBarrister", "HoundOfJustice",
	"IceJustice", "KrakenCounsel", "ScoopJudge", "SirFluffington", "StarJudge", "WhaleJudge", "IShowSued",
	-- Rare
	"CorgiCounsel", "ParrotProsecutor", "DonutDefender", "OctoAttorney", "SeahorseSolicitor", "PizzaProsecutor",
	"SaturnSolicitor", "UFOCounsel", "NeonLitigator", "GoldenGavel", "LiriliLarila", "BrrBrrPatapim",
	"BallerinaCappuccina", "KaiSueNat", "KhabyClaim",
	-- Uncommon
	"WhiskersEsq", "BubblesGoldfish", "SushiSolicitor", "TacoTribunal", "PufferPartner", "JellyJuror",
	"AstroAttorney", "RoboClerk", "BowTieBarrister", "NavyPowerSuit", "BensonBond", "ChimpanziniBananini",
	"BonecaAmbalabu",
	-- Common
	"InternSuit", "CasualFriday", "PawralegalPup", "HamsterHustle", "ToastAttorney", "SunnySideSam", "CrabCounsel",
	"ClownfishClerk", "MoonRockRookie", "LittleGreenLawyer",
}
local SIDEWAYS = { HoundOfJustice = true, WhaleJudge = true }

local Http = game:GetService("HttpService")
local wasEnabled = Http.HttpEnabled
Http.HttpEnabled = true
local ok, err = pcall(function()
	local kit = game.ServerStorage:FindFirstChild("SkinKit") or Instance.new("ModuleScript")
	kit.Name = "SkinKit"
	kit.Source = Http:GetAsync(BASE .. "SkinKit.lua")
	kit.Parent = game.ServerStorage
	local done = {}
	for _, id in IDS do
		local fn = assert(loadstring(Http:GetAsync(BASE .. id .. ".lua"), id))
		fn()
		local b = _G.SkinBuild
		b:install(id, "rebuilt by tools/skins/InstallAll.lua (builder: tools/skins/" .. id .. ".lua)", SIDEWAYS[id])
		table.insert(done, id)
	end
	local stage = workspace:FindFirstChild("_ModelStage")
	if stage then
		stage:Destroy()
	end
	print(("InstallAll: %d models installed"):format(#done))
end)
Http.HttpEnabled = wasEnabled
if not ok then
	warn("InstallAll failed:", err)
end
