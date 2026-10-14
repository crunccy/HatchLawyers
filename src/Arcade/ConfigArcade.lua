-- (this block goes into Shared.Config right after Config.Minigames - kept here as its own file so it can be merged
-- into src/Config.lua and the live Config separately; see src/Arcade/README.md)

-- ARCADE PIER (2026-10-13, mr.robe's session; user's call: build the minigames in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md).
-- Booth games on the pier north of the hub (Workspace.ArcadePier, tools/blender/arcade_pier.py), run by
-- ServerScriptService.ArcadeServer (one module per game) + StarterPlayerScripts.Arcade. Like Config.Minigames: solo,
-- tap-only, a saved per-player Cooldown (seconds, kept in data.Minigames[id]) and a reward in minutes of the player's
-- own income: MinMinutes at a score of 0 .. MaxMinutes at a perfect score. All first guesses (put them in the zones sim).
Config.Arcade = {
	IntroTime = 2.6, -- "3, 2, 1, GO!" before a round
	LieDetector = {
		Name = "Lie Detector", Color = Color3.fromRGB(70, 200, 120), Cooldown = 4 * 60, MinMinutes = 0.2, MaxMinutes = 1,
		Rounds = 8, RoundTime = 2.6, Gap = 0.7, -- each round the needle swings for RoundTime s and you get one tap
		Period = { 1.6, 0.75 }, -- seconds per full swing, first round .. last
		Band = { 0.26, 0.11 }, -- half-width of the green TRUTH band (the meter runs -1 .. 1), first round .. last
		Perfect = 0.35, -- inside this share of the band = PERFECT
	},
	BriefcaseStack = {
		Name = "Briefcase Stack", Color = Color3.fromRGB(255, 160, 24), Cooldown = 5 * 60, MinMinutes = 0.2, MaxMinutes = 1.25,
		Levels = 20, -- a full tower
		Width = 6, -- the first briefcase's width (units; the slide runs -Travel .. Travel)
		Travel = 7,
		Period = { 2.4, 1 }, -- seconds per full slide, level 1 .. level Levels
		Perfect = 0.3, -- within this many units of the case below = PERFECT (no width lost)
		MinWidth = 0.45, -- a thinner overlap falls off: game over
		Settle = 0.4, -- seconds between a drop and the next case sliding
		MaxWait = 10, -- no tap by then: it drops by itself
	},
	FilingFrenzy = {
		Name = "Filing Frenzy", Color = Color3.fromRGB(60, 160, 255), Cooldown = 5 * 60, MinMinutes = 0.2, MaxMinutes = 1.25,
		Papers = 34,
		Colors = 3, -- bins: red, green, blue (4 adds yellow)
		Gap = { 1.15, 0.45 }, -- seconds between papers, first .. last
		Travel = { 4.4, 2.5 }, -- seconds a paper takes down the belt to the shredder, first .. last
		Misses = 3, -- this many shredded / wrong papers ends the round
	},
}
