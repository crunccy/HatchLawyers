--!strict
-- Fonts (StarterPlayerScripts.Fonts): the game uses ONE font family, the one in crnuch's reference video's UI
-- (crnuch's call 2026-10-23, docs/UI_STYLE_V3.md): Gotham Black for everything big, Gotham Bold for small print.
-- Shared.UIFonts and Shared.Skin already hand out those; this catches every other text object a script or a model
-- still sets to an older font (Fredoka One, Luckiest Guy, Builder Sans, Source Sans, Arial ...) - screens, name tags,
-- world signs, billboards - and converts it as it appears or whenever its font changes. Client-only; nothing replicates.
--   display fonts / heavy weights -> Gotham Black
--   text fonts at normal weights   -> Gotham Bold
-- Monospace (RobotoMono / Code) is left alone. Opt out: attribute KeepFont = true on the text object or an ancestor.

local Players = game:GetService("Players")

local BLACK = Font.fromEnum(Enum.Font.GothamBlack)
local BOLD = Font.fromEnum(Enum.Font.GothamBold)

local KEEP_FAMILIES = { GothamSSm = true, Montserrat = true, RobotoMono = true, Inconsolata = true, Code = true }
local DISPLAY_FAMILIES = {
	FredokaOne = true, LuckiestGuy = true, Bangers = true, ComicNeueAngular = true, DenkOne = true, PermanentMarker = true,
	Oswald = true, Sarpanch = true, TitilliumWeb = true, Fondamento = true, AccanthisADFStd = true,
}
local HEAVY = {
	[Enum.FontWeight.Bold] = false, [Enum.FontWeight.SemiBold] = false,
	[Enum.FontWeight.ExtraBold] = true, [Enum.FontWeight.Heavy] = true,
}
local SKIP_GUIS = { Freecam = true, TouchGui = true, BubbleChat = true, Chat = true }

local function family(f: Font): string
	-- "rbxasset://fonts/families/FredokaOne.json" -> "FredokaOne"
	return string.match(f.Family, "([%w_]+)%.json$") or f.Family
end

local function target(f: Font): Font?
	local fam = family(f)
	if KEEP_FAMILIES[fam] then
		return nil
	end
	if DISPLAY_FAMILIES[fam] or HEAVY[f.Weight] then
		return BLACK
	end
	return BOLD
end

local function kept(obj: Instance): boolean
	local a: Instance? = obj
	while a and a ~= game do
		if a:GetAttribute("KeepFont") then
			return true
		end
		if a:IsA("ScreenGui") and SKIP_GUIS[a.Name] then
			return true
		end
		a = a.Parent
	end
	return false
end

local hooked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function fix(obj: Instance)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
		return
	end
	if hooked[obj] or kept(obj) then
		return
	end
	hooked[obj] = true
	local t = obj :: TextLabel
	local function apply()
		local to = target(t.FontFace)
		if to then
			t.FontFace = to
		end
	end
	apply()
	t:GetPropertyChangedSignal("FontFace"):Connect(apply)
end

local function watch(root: Instance, chunk: number)
	root.DescendantAdded:Connect(fix)
	task.spawn(function()
		for i, d in root:GetDescendants() do
			fix(d)
			if i % chunk == 0 then
				task.wait()
			end
		end
	end)
end

watch(Players.LocalPlayer:WaitForChild("PlayerGui"), 4000)
watch(workspace, 6000) -- signs, billboards, name tags, odds boards
