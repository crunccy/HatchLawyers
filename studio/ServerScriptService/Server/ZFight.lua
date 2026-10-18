-- The z-fighting fixer lives in ReplicatedStorage.Shared.ZFight (the client's minigame scenes use it too); this
-- path stays for FirmBuilder, DeskService and the Studio builders (tools/zones/Build*.lua, tools/brick/Run.lua).
return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ZFight"))
