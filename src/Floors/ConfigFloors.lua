-- (this block goes into Shared.Config right after Config.Arcade - its own file so it can be merged into src/Config.lua
-- and the live Config separately)

-- UPSTAIRS ROOMS (2026-10-13; mr.robe's call: build the upper-floor ideas in docs/PROPOSAL_MINIGAMES_AND_UPPER_FLOORS.md,
-- everything but the Rooftop Helipad). ServerScriptService.FloorRooms stands the rooms (Blender sets:
-- tools/blender/floor_rooms.py -> ServerStorage.Templates.FloorRooms) on the firm building's upper floors as the firm
-- grows (Stage = Server.FirmStages' front building) and runs them; StarterPlayerScripts.Floors draws their panels.
-- Saved in data.Floors (PlayerData v18). Bonuses reach cases through FirmFeatures.buffSources. All numbers first guesses.
Config.Floors = {
	Rooms = {
		MailRoom = { Name = "Mail Room", Stage = 3, Color = Color3.fromRGB(229, 57, 53) },
		HallOfFame = { Name = "Hall of Fame", Stage = 3, Color = Color3.fromRGB(255, 190, 31) },
		VIPLounge = { Name = "VIP Lounge", Stage = 4, Color = Color3.fromRGB(170, 80, 210) },
		MootCourt = { Name = "Moot Court", Stage = 4, Color = Color3.fromRGB(150, 90, 50) },
		CaseArchive = { Name = "Case Files Archive", Stage = 4, Color = Color3.fromRGB(60, 150, 240) },
		PartnersOffice = { Name = "Partner's Office", Stage = 5, Color = Color3.fromRGB(58, 61, 85) },
		GuestLounge = { Name = "Guest Lounge", Stage = 5, Color = Color3.fromRGB(79, 203, 46) },
		PrivateCourtroom = { Name = "Private Courtroom", Stage = 6, Color = Color3.fromRGB(122, 70, 34) },
	},
	-- where each room stands in each building: firm-local { x, floor top y, z, turn in degrees } (0 = the room's front
	-- faces the street). Measured against Server.FirmStages' fronts: clear of the Showcase strip (z < 5.6), the bought
	-- areas' furniture and the elevator stop (back-right corner).
	Slots = {
		[3] = {
			MailRoom = { -12, 9.45, 13, 0 }, HallOfFame = { 3, 9.45, 12, 0 },
		},
		[4] = {
			MailRoom = { -12, 9.45, 13, 0 }, HallOfFame = { 3, 9.45, 12, 0 },
			VIPLounge = { -12, 18.45, 10, 0 }, MootCourt = { 3, 18.45, 10, 0 },
			CaseArchive = { -16.5, 27.45, 9, 0 },
		},
		[5] = {
			MailRoom = { -12, 18.45, 13, 0 }, HallOfFame = { 3, 18.45, 12, 0 },
			VIPLounge = { -15, 36.45, 12, 0 }, MootCourt = { -3, 36.45, 12, 0 }, PartnersOffice = { 8.5, 36.45, 11, 0 },
			CaseArchive = { -13, 45.45, 12, 0 }, GuestLounge = { 2, 45.45, 12, 0 },
		},
		[6] = { -- the tower's floors (FirmStages opened them up for these rooms)
			MailRoom = { -13.6, 20.0, 9, 0 }, HallOfFame = { -2, 20.0, 9, 0 }, VIPLounge = { 9, 20.0, 8, 0 },
			MootCourt = { -13, 29.0, 9, 0 }, CaseArchive = { 0, 29.0, 9, 0 }, PartnersOffice = { 10, 29.0, 8, 0 },
			GuestLounge = { -4, 38.0, 10, 0 },
			PrivateCourtroom = { -3, 65.0, 10, 0 },
		},
	},
	-- MAIL ROOM: three letters from clients every day, each a small task; the last one also holds a free egg
	Mail = {
		Minutes = { 2, 3, 5 }, -- minutes of income per letter
		EggOnLast = true,
		Tasks = { -- kinds GoalService.track sends; Target = how many
			{ Kind = "win", Target = 15, Text = "Win %d cases for me!" },
			{ Kind = "rareWin", Target = 3, Text = "Win %d Rare (or better) cases" },
			{ Kind = "train", Target = 10, Text = "Upgrade your offices %d times" },
			{ Kind = "courtCorrect", Target = 3, Text = "Pick the right evidence %d times" },
			{ Kind = "hatch", Target = 5, Text = "Hatch %d eggs" },
			{ Kind = "place", Target = 2, Text = "Put %d lawyers in offices" },
		},
	},
	-- HALL OF FAME: every lawyer you've ever owned gets a frame; a whole egg's set = a payout bonus for good
	Index = { SetBonus = 0.05 },
	-- VIP LOUNGE: a VIP client waits upstairs; greet them, pick one of your lawyers, the case pays at once
	VIP = {
		Every = 6 * 60, -- seconds between VIPs (one at a time)
		Wait = 3 * 60, -- they leave if nobody greets them
		Minutes = 3, -- minutes of income ...
		RarityBonus = 0.35, -- ... x (1 + RarityBonus x (the lawyer's rarity - 1))
	},
	-- MOOT COURT: send an office to practise; when it's done, that office gets a free skill roll
	Moot = { Booths = 2, Minutes = 15 },
	-- CASE FILES ARCHIVE: wins by client type; each milestone reached = a small payout bonus for good
	Archive = { Milestones = { 10, 50, 250, 1000 }, PerMilestone = 0.004 },
	-- PARTNER'S OFFICE: rules the firm follows on its own (checked every Every seconds)
	Partner = {
		Every = 20,
		Rules = {
			{ Id = "AutoUpgrade", Name = "Auto-upgrade", Text = "Upgrade the cheapest office when you have 3x its cost" },
			{ Id = "AutoEquip", Name = "Auto-equip best", Text = "Put your strongest lawyers in the offices" },
		},
		UpgradeReserve = 3, -- AutoUpgrade only spends when coins >= this x the cost
	},
	-- GUEST LOUNGE: a visitor who stays in your lounge gives you both a payout buff; visitors can like your firm
	Lounge = { Buff = 0.1, Minutes = 5, Stay = 4, Cooldown = 30 * 60, Radius = 9 },
	-- PRIVATE COURTROOM: hold court - three cases, pick the evidence that proves each one
	Court = {
		Cooldown = 10 * 60,
		MinMinutes = 1,
		MaxMinutes = 6,
		Cases = {
			{ Case = "Who ate the Judge's donut?", Cards = { "Sprinkles on the dog's nose", "A muddy boot", "A rainbow umbrella" }, Answer = 1 },
			{ Case = "Who painted the mayor's cat blue?", Cards = { "A banana peel", "Blue paw prints on the stairs", "A lost sock" }, Answer = 2 },
			{ Case = "Who took the trophy?", Cards = { "A toy car", "An empty pizza box", "Glitter on the thief's gloves" }, Answer = 3 },
			{ Case = "Who flooded the bakery?", Cards = { "A wet snorkel by the sink", "A birthday card", "A pair of sunglasses" }, Answer = 1 },
			{ Case = "Who let the goats into the park?", Cards = { "A gold coin", "An open gate key with goat hair", "A paper plane" }, Answer = 2 },
			{ Case = "Who switched the school bells?", Cards = { "A sandwich", "A comic book", "The bell tower's ladder with fresh paint" }, Answer = 3 },
			{ Case = "Who hid the rubber ducks?", Cards = { "Duck feathers in the laundry basket", "A tennis racket", "A broken pencil" }, Answer = 1 },
			{ Case = "Who ate all the cookies?", Cards = { "A clean plate", "Crumbs on the robot's chin", "A soccer ball" }, Answer = 2 },
		},
	},
}
