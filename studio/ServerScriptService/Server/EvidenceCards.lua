--!strict
-- Courtroom prompts, one set per client tier (same order as Config.Clients). Server-only so the
-- answers never reach players. In every Cards list the FIRST card is the right one; the server
-- shuffles before sending. Keep it silly, kind and fictional.

export type Prompt = { Question: string, Cards: { string } }
export type CardSet = { Opponent: string, Prompts: { Prompt } }

local EvidenceCards: { CardSet } = {
	{ -- Common: Dave's parking ticket
		Opponent = "Officer Pam",
		Prompts = {
			{
				Question = "Dave parked in a No Parking zone. Which evidence helps him?",
				Cards = { "Photo: a tree branch was hiding the sign", "Dave's favorite sandwich", "A drawing of a cat" },
			},
			{
				Question = "The ticket says the car was red. Which proves it's a mix-up?",
				Cards = { "Dave's car is bright blue", "Dave really likes red apples", "A selfie with a parking meter" },
			},
			{
				Question = "Dave says he paid the meter. Prove it!",
				Cards = { "Meter receipt with the time on it", "Dave's library card", "A rubber duck" },
			},
			{
				Question = "The ticket was written on a Sunday. Why does that matter?",
				Cards = { "The sign says parking is free on Sundays", "Dave wore mismatched socks", "It was sunny outside" },
			},
			{
				Question = "Officer Pam says Dave parked too far from the curb. How far was it?",
				Cards = { "Photo with a ruler: exactly 12 inches, the legal limit", "A rubber band", "Dave's lucky penny" },
			},
			{
				Question = "Was Dave's car really parked there for 3 hours?",
				Cards = { "Store receipt: Dave was shopping for only 20 minutes", "A sleepy cat", "A box of crayons" },
			},
			{
				Question = "The ticket has the wrong license plate. Which proves it?",
				Cards = { "Dave's registration with a different plate number", "A plate of spaghetti", "Dave's library book" },
			},
			{
				Question = "Pam says Dave blocked a fire hydrant. Was there one?",
				Cards = { "City map: the nearest hydrant is down the block", "A water balloon", "A garden hose" },
			},
		},
	},
	{ -- Uncommon: the bakery's broken contract
		Opponent = "Flour Supplier Floyd",
		Prompts = {
			{
				Question = "The supplier promised 100 bags of flour but sent 10. Best evidence?",
				Cards = { "Signed order form for 100 bags", "A very tasty croissant", "Tomorrow's weather forecast" },
			},
			{
				Question = "The supplier says the bakery never paid. Prove it did!",
				Cards = { "Bank receipt for the flour payment", "A cupcake with sprinkles", "The bakery's playlist" },
			},
			{
				Question = "The flour came 3 weeks late. What shows the deadline?",
				Cards = { "Contract with the delivery date circled", "A calendar full of kittens", "The oven's instruction manual" },
			},
			{
				Question = "The supplier says the flour was fine. Show that it wasn't!",
				Cards = { "Photos of soggy, lumpy flour bags", "A photo of a perfect cake", "Grandma's cookie recipe" },
			},
			{
				Question = "Floyd says the bakery ordered sugar, not flour. What did they order?",
				Cards = { "Order email that says 'FLOUR, 100 bags'", "A bag of sprinkles", "A rolling pin" },
			},
			{
				Question = "The bakery had to close for a week. Why?",
				Cards = { "Calendar of empty shelves the week the flour was late", "A vacation postcard", "A broken oven mitt" },
			},
			{
				Question = "Floyd says he never signed the contract. Did he?",
				Cards = { "The contract with Floyd's signature on it", "A smiley-face sticker", "A napkin doodle" },
			},
			{
				Question = "How much money did the bakery lose?",
				Cards = { "Sales log comparing a normal week and the flour-less week", "A piggy bank", "A pile of buttons" },
			},
		},
	},
	{ -- Rare (fallback for a Rare client without its own ClientEvidence set): a midnight rampage
		Opponent = "Grumpy Neighbor Gus",
		Prompts = {
			{
				Question = "Someone was drumming at midnight. Where was your client?",
				Cards = { "Video: your client at a drum contest across town", "A very loud alarm clock", "A random log" },
			},
			{
				Question = "Giant footprints were found at the scene. Do they match?",
				Cards = { "The prints are size 20, your client wears size 9", "A muddy boot from the judge", "A sock puppet" },
			},
			{
				Question = "A fence was bonked with a bat. Whose bat was it?",
				Cards = { "The bat has someone else's name carved on it", "Your client's lunchbox", "A baseball trading card" },
			},
			{
				Question = "Gus heard banging all night. What else makes that sound?",
				Cards = { "Recording of Gus's leaky pipe going bang bang bang", "A sleeping goldfish", "A fluffy pillow" },
			},
			{
				Question = "Gus says your client broke his mailbox. When did it break?",
				Cards = { "Mail carrier's note: it was broken last month", "A bent spoon", "A birthday card" },
			},
			{
				Question = "Who really knocked over the garden gnomes?",
				Cards = { "Doorbell video of a raccoon tipping them over", "A box of cereal", "A toy drum" },
			},
			{
				Question = "Gus found splinters at the scene. Do they match your client's bat?",
				Cards = { "Lab test: the splinters are pine, the bat is oak", "A paintbrush", "A pinecone" },
			},
			{
				Question = "Your client says they were asleep at midnight. Prove it!",
				Cards = { "Sleep tracker showing they snored from 9 PM to 7 AM", "A loud trumpet", "A cup of coffee" },
			},
		},
	},
	{ -- Epic: the retired CEO's inheritance dispute
		Opponent = "Cousin Cornelius",
		Prompts = {
			{
				Question = "Twelve relatives say they were promised the yacht. What was the real plan?",
				Cards = { "The CEO's diary: 'The yacht goes to charity'", "A rubber bathtub yacht", "A postcard from Hawaii" },
			},
			{
				Question = "Cornelius says he gets the whole company. Prove who really does!",
				Cards = { "Signed papers giving the company to the workers", "A bag of golf balls", "A painting of a sunset" },
			},
			{
				Question = "The family says the CEO never signed her will. Did she?",
				Cards = { "The will with her signature and two witnesses", "An unsigned birthday card", "A grocery list" },
			},
			{
				Question = "Who gets the famous golden goldfish? Show the proof!",
				Cards = { "Photo of the CEO handing the goldfish to her niece", "A goldfish cracker", "The fish tank manual" },
			},
		},
	},
	{ -- Legendary: Chef Mega's cooking contest
		Opponent = "Contestant Carla",
		Prompts = {
			{
				Question = "Carla says the judges tasted her dish last, when they were full. Was it fair?",
				Cards = { "Random draw sheet showing the tasting order", "A shiny soup spoon", "A soggy taco" },
			},
			{
				Question = "Carla says Chef Mega told his friend the secret ingredient. Did he?",
				Cards = { "The ingredient list every cook got", "A jar of mystery sauce", "A tall chef hat" },
			},
			{
				Question = "Was the scoreboard broken during the final?",
				Cards = { "Repair report: scoreboard checked the day before", "A cracked egg", "A blender manual" },
			},
		},
	},
	{ -- Legendary: Rocket Baron Rex's rocket launch
		Opponent = "Neighbor Nadia",
		Prompts = {
			{
				Question = "Nadia says the rocket splashed down in her pool. Where did it land?",
				Cards = { "GPS tracker: it landed in the desert", "A wet beach towel", "A beach ball" },
			},
			{
				Question = "Did Rex have permission to launch?",
				Cards = { "Launch permit with the date stamped on it", "A paper airplane", "A shiny space helmet" },
			},
			{
				Question = "Nadia heard a boom at 3 PM. When did the rocket really launch?",
				Cards = { "Launch log: liftoff at 9 AM", "A loud alarm clock", "A pool party invitation" },
			},
		},
	},
	{ -- Legendary: Milo Vex's fashion contract
		Opponent = "Label Boss Lulu",
		Prompts = {
			{
				Question = "Lulu says Milo skipped the big fashion show. Did he?",
				Cards = { "Backstage photo of Milo on the runway", "A sparkly sock", "A sewing kit" },
			},
			{
				Question = "The contract says Milo must wear Lulu's shoes. What did he wear?",
				Cards = { "Receipt for Lulu-brand shoes", "A pair of flip-flops", "An empty shoe box" },
			},
			{
				Question = "Lulu says Milo was late to every photo shoot. Was he?",
				Cards = { "Sign-in sheet: Milo arrived early every day", "A broken watch", "A traffic cone" },
			},
		},
	},
	{ -- Legendary: DJ Beatbox's song
		Opponent = "DJ Rumble",
		Prompts = {
			{
				Question = "Rumble says Beatbox copied his song. Who made it first?",
				Cards = { "Beatbox's recording, saved a year before Rumble's", "A pair of headphones", "A disco ball" },
			},
			{
				Question = "Do the two songs even sound the same?",
				Cards = { "Music expert report: totally different beats", "A kazoo", "A party playlist" },
			},
			{
				Question = "Rumble says Beatbox took his lyrics notebook. Whose is it?",
				Cards = { "The notebook is in Beatbox's handwriting", "A blank napkin", "A microphone stand" },
			},
		},
	},
	{ -- Legendary: Kiki Glow's beauty brand
		Opponent = "Glimmer Co.",
		Prompts = {
			{
				Question = "Glimmer Co. says they used the name 'Glow' first. Who really did?",
				Cards = { "Kiki's trademark, registered five years earlier", "A shiny lipstick", "A hand mirror" },
			},
			{
				Question = "Do the two logos even look alike?",
				Cards = { "Side-by-side logos: different colors and shapes", "A jar of glitter", "A face mask" },
			},
			{
				Question = "Glimmer Co. says shoppers mixed up the brands. Did they?",
				Cards = { "Survey: 98% of shoppers could tell them apart", "A makeup brush", "A selfie stick" },
			},
		},
	},
}

return EvidenceCards
