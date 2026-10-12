--!strict
-- Courtroom prompts per client CHARACTER (Config.ClientCharacters Id), so each client's court case is about
-- their own situation. Server.CourtService uses these first and falls back to Server.EvidenceCards (per
-- client tier; written for that tier's first character: Dave, Rosa, a generic Rare client, the CEO, the celebrities).
-- Same rules as EvidenceCards: the FIRST card is the right one (the server shuffles), server-only,
-- keep it silly, kind and fictional.

local EvidenceCards = require(script.Parent.EvidenceCards)

local function P(question: string, right: string, wrong1: string, wrong2: string): EvidenceCards.Prompt
	return { Question = question, Cards = { right, wrong1, wrong2 } }
end

local ByClient: { [string]: EvidenceCards.CardSet } = {
	-- Common -----------------------------------------------------------------------------------------
	GrandmaPearl = { Opponent = "Park Ranger Rick", Prompts = {
		P("The ranger says Pearl was going 4 mph over. How fast was she really going?", "Speed camera photo: 2 mph, the speed limit", "Pearl's favorite knitting needles", "A jar of hard candy"),
		P("Was Pearl even driving? Show who was at the wheel!", "Photo: her mobility scooter was parked at bingo", "A crossword puzzle", "Her cat's birthday card"),
		P("The ranger's radar gun was acting weird. Prove it!", "Repair note: radar gun broken since Tuesday", "A bag of birdseed", "Pearl's reading glasses"),
	} },
	SkaterKev = { Opponent = "Statue Keeper Stan", Prompts = {
		P("Stan says Kev scuffed the statue. When was it scuffed?", "Photo from last year: the scuff was already there", "Kev's lucky skateboard sticker", "A half-eaten sandwich"),
		P("Where was Kev when the statue got scuffed?", "Skate park sign-in sheet with Kev's name", "A really cool kickflip video", "His grandma's cookies"),
		P("What actually scuffed the statue?", "Video: a pigeon dropped a pinecone on it", "Kev's untied shoelace", "A pair of sunglasses"),
	} },
	MailCarrierMo = { Opponent = "Tiny Dog's Owner Tina", Prompts = {
		P("Tina says Mo scared her dog first. Did he?", "Doorbell video: Mo just said 'Good morning!'", "A stack of birthday cards", "Mo's favorite stamp"),
		P("Was the gate closed like the sign said?", "Photo: the gate was wide open", "A rubber band ball", "A postcard from Hawaii"),
		P("How bad was the bite?", "Doctor's note: tiny tooth marks, one bandage", "Mo's mail bag", "A very large bone"),
	} },
	LemonadeLily = { Opponent = "Inspector Sourpuss", Prompts = {
		P("The inspector says there was 'too much lemon'. What do the rules say?", "The town rulebook has no lemon limit", "Lily's jump rope", "A cloud-shaped cookie"),
		P("Did customers like the lemonade?", "50 happy customer smiley-face cards", "A bucket of ice", "Her lost tooth"),
		P("Did Lily have permission to run her stand?", "Permit signed by her mom AND the mayor", "A drawing of a lemon", "A lucky penny"),
	} },
	GamerGabe = { Opponent = "Arcade Manager Max", Prompts = {
		P("Max says Gabe was cheating. How did he win?", "Video: he just practiced for 400 hours", "An energy drink can", "A cool headset"),
		P("Does the arcade have a rule against winning?", "Rulebook: 'Have fun and try your best'", "A bag of tokens", "A pizza coupon"),
		P("Who really broke the claw machine?", "Security video: a raccoon got inside", "Gabe's high score", "A plush unicorn"),
	} },
	GardenerGus = { Opponent = "Pool Owner Priya", Prompts = {
		P("How did Gus's pumpkin end up in Priya's pool?", "Weather report: a freak windstorm that day", "A packet of seeds", "Gus's straw hat"),
		P("Was the pool damaged?", "Pool guy's report: 'Not a scratch, very clean pumpkin'", "A garden gnome", "A watering can"),
		P("Did Gus try to fix things?", "Receipt: he paid for pool cleaning AND gave her pie", "A muddy boot", "A ribbon from the fair"),
	} },
	IceCreamIvy = { Opponent = "Noise Officer Norm", Prompts = {
		P("Norm says Ivy's jingle is too catchy. Is that against the law?", "Town rules only limit how LOUD, not how catchy", "A melting popsicle", "A sprinkle jar"),
		P("How loud was the jingle really?", "Sound meter reading: quieter than a lawnmower", "A cone holder", "Ivy's sunglasses"),
		P("When was the truck playing music?", "Schedule: only 2-5pm, the allowed hours", "A rainbow sprinkle", "A napkin"),
	} },
	BarberBob = { Opponent = "Customer Carl", Prompts = {
		P("Carl says his haircut was 'too stylish'. What did he ask for?", "Order slip: 'Make me look AMAZING'", "A bottle of hair gel", "A striped barber pole"),
		P("Did Carl like it at first?", "Photo: Carl taking 40 selfies after", "A comb", "A magazine"),
		P("Why is Carl upset now?", "Text: 'Everyone keeps asking for my autograph'", "Bob's scissors", "A towel"),
	} },
	CrossingGuardCarol = { Opponent = "Late Driver Dwayne", Prompts = {
		P("Dwayne says Carol stopped traffic for no reason. What was crossing?", "Video: a mother duck and 11 ducklings", "Carol's whistle", "A traffic cone"),
		P("Why did it take 3 hours?", "Video: duckling #11 kept walking back to say goodbye", "Her stop sign", "A cup of coffee"),
		P("Is stopping for ducks allowed?", "Town law: 'Always stop for ducks'", "A reflective vest", "A parking ticket"),
	} },
	LibrarianLou = { Opponent = "Reader Ronnie", Prompts = {
		P("Lou charged a $9,000 late fee. How late was the book?", "Library card: borrowed in 1974", "A bookmark", "Lou's glasses"),
		P("What does the library sign say about late fees?", "Sign: 10 cents a day, no limit", "A dusty encyclopedia", "A 'Quiet Please' poster"),
		P("Did Ronnie get any warnings?", "48 years of reminder postcards", "A library cat", "A pencil"),
	} },
	CamperCam = { Opponent = "Mayor Marigold", Prompts = {
		P("The mayor says Cam's tent squished her roses. What happened?", "Weather report: surprise tornado-strength gust", "A bag of marshmallows", "A compass"),
		P("Did Cam stake his tent down?", "Photo: 12 stakes, all hammered in", "A flashlight", "A s'more"),
		P("Are the roses actually hurt?", "Gardener's note: 'They're fine, maybe happier'", "A canteen", "A ranger badge"),
	} },
	YogaYasmin = { Opponent = "Goat Farmer Gerald", Prompts = {
		P("Gerald says the mat was 'free goat food'. Was it?", "Receipt: Yasmin bought that mat for $40", "A water bottle", "A headband"),
		P("Was the goat supposed to be supervised?", "Class flyer: 'Goats supervised at all times'", "A meditation bell", "A smoothie"),
		P("Which goat ate it?", "Photo: Bartholomew the goat, mat in mouth", "A yoga block", "A scented candle"),
	} },
	-- Uncommon ---------------------------------------------------------------------------------------
	CaptainBarnacle = { Opponent = "Steve the Seagull", Prompts = {
		P("Steve says the fishing spot is his. Who was there first?", "Old photo: Barnacle fishing there in 1990", "A rubber boot", "A can of sardines"),
		P("Steve claims he has a permit. Does he?", "The permit office has never heard of Steve", "A seashell", "A captain's hat"),
		P("Who keeps stealing the fish?", "Video: Steve, with a whole sandwich too", "A fishing hook", "A treasure map"),
	} },
	DrFizz = { Opponent = "Science Fair Judge Jane", Prompts = {
		P("Jane says Fizz's volcano slimed the fair. Was it supposed to erupt?", "Project plan: 'medium-sized eruption'", "A pair of goggles", "A lab coat button"),
		P("Why was the eruption so big?", "Bottle label: someone swapped in EXTRA fizzy soda", "A test tube", "A periodic table"),
		P("Did Fizz warn people?", "Sign at his booth: 'SPLASH ZONE'", "A beaker", "A science trophy"),
	} },
	FirefighterFaye = { Opponent = "Mr. Whiskerton (a cat)", Prompts = {
		P("The cat says he didn't need rescuing. Was he stuck?", "Photo: he was meowing for help for an hour", "A fire hose", "A helmet"),
		P("Did Faye hurt anyone during the rescue?", "Video: very gentle, cat got a treat", "A ladder", "A sandwich"),
		P("Who called the fire station?", "Phone log: the cat's owner, crying", "A smoke detector", "A badge"),
	} },
	MagicianMarvin = { Opponent = "Hopsworth the Rabbit", Prompts = {
		P("Hopsworth says Marvin made him vanish on purpose. Did he?", "Show script: the rabbit was supposed to come back", "A deck of cards", "A magic wand"),
		P("Where is Hopsworth now?", "Postcard: 'Living my best life in the carrot fields'", "A top hat", "A silk scarf"),
		P("Did Hopsworth agree to the trick?", "Contract signed with a pawprint", "A trapdoor", "A bouquet of flowers"),
	} },
	FarmerFrank = { Opponent = "Pie Contest Judge Penny", Prompts = {
		P("Penny says cows can't enter the pie contest. Can they?", "Contest rules: 'Any farm resident may enter'", "A pitchfork", "A bale of hay"),
		P("Did the cow really bake the pie?", "Video: Bessie rolling dough with her hooves", "A milk bucket", "A cowbell"),
		P("Did Frank help the cow cheat?", "Witness: Frank was asleep the whole time", "A tractor key", "An apple"),
	} },
	NurseNina = { Opponent = "Hospital Boss Bertram", Prompts = {
		P("Bertram says 'more naps' isn't real medicine. Is it?", "Medical book: rest helps people heal", "A stethoscope", "A bandage"),
		P("Did the patients get better?", "Chart: every napper went home early", "A thermometer", "A lollipop"),
		P("Who else prescribes naps?", "Letter from 10 doctors agreeing with Nina", "A clipboard", "A pillow"),
	} },
	MechanicMax = { Opponent = "Car Owner Carla", Prompts = {
		P("Carla says her car drives itself now and it's Max's fault. What did he fix?", "Work order: 'Fixed the brakes, that's all'", "A wrench", "An oil can"),
		P("Who installed the self-driving part?", "Receipt: Carla bought a robot steering kit online", "A tire", "Max's cap"),
		P("Is the car driving safely?", "Report: zero accidents, always parks perfectly", "A spark plug", "A hubcap"),
	} },
	ArtistAria = { Opponent = "Mayor Bigglesworth", Prompts = {
		P("The mayor says his portrait is upside down. Is it?", "Aria's sketch: he asked to be painted doing a handstand", "A paintbrush", "A beret"),
		P("Did the mayor approve the painting?", "Signed note: 'Love it! - The Mayor'", "A palette", "An easel"),
		P("Who hung it upside down at the town hall?", "Video: the mayor's assistant, holding it wrong", "A frame", "A can of paint"),
	} },
	WrestlerRonda = { Opponent = "SnackMaster 3000 (a vending machine)", Prompts = {
		P("The vending machine says Ronda attacked it. Did it take her dollar first?", "Video: it ate her dollar and gave nothing", "A championship belt", "A protein bar"),
		P("Has the machine done this before?", "Complaint list: it stole from 37 people", "A wrestling mask", "A water bottle"),
		P("Is the machine actually damaged?", "Repair report: 'Fine. Dented its pride.'", "A towel", "A gym mat"),
	} },
	PilotPaige = { Opponent = "Airline Boss Bob", Prompts = {
		P("Bob says Paige landed on the wrong island. Why did she?", "Map: someone swapped the two island names", "A pilot hat", "Aviator sunglasses"),
		P("Were the passengers upset?", "30 postcards: 'Best vacation ever!'", "A peanut packet", "A seatbelt"),
		P("Did Paige land safely?", "Flight log: smoothest landing of the year", "A suitcase", "A paper airplane"),
	} },
	MusicianMoe = { Opponent = "Sleepy Neighbor Nell", Prompts = {
		P("Nell says Moe plays tuba at 4am. When does he really practice?", "Practice log: 4PM, not 4AM", "A tuba mouthpiece", "Sheet music"),
		P("Who was really making noise at 4am?", "Video: Nell's own rooster", "A metronome", "A music stand"),
		P("Did Moe try to be quiet?", "Receipt: he bought a tuba mute", "A concert ticket", "A trumpet"),
	} },
	-- Rare -------------------------------------------------------------------------------------------
	BaronVonBanana = { Opponent = "Grocer Greta", Prompts = {
		P("Greta says the Baron bought every banana in town. Is that against the rules?", "Store sign: 'No limit on bananas'", "A monocle", "A top hat"),
		P("Why did the Baron need so many bananas?", "Invitation: banana party for the whole town", "A banana peel", "A pocket watch"),
		P("Did anyone go without bananas?", "Party photo: everyone got free bananas", "A fruit basket", "A cane"),
	} },
	BeepBot = { Opponent = "Planet Zorb's Pizza Manager", Prompts = {
		P("300 pizzas landed on the wrong planet. Who typed the address?", "Order screen: the customer typed 'Zorb' not 'Zorp'", "A pizza box", "A delivery bag"),
		P("Did the pizzas arrive hot?", "Thermometer log: still piping hot on arrival", "A slice of pepperoni", "A robot antenna"),
		P("Did Beep try to fix the mistake?", "Flight log: delivered 300 more to the right planet", "A rocket booster", "A tip jar"),
	} },
	PiratePatches = { Opponent = "Park Keeper Polly", Prompts = {
		P("Polly says burying treasure in the park is illegal. Is it?", "Park rules: 'Digging allowed in the sandbox'", "An eyepatch", "A parrot feather"),
		P("Where exactly did Patches dig?", "Treasure map: X marks the sandbox", "A hook", "A ship in a bottle"),
		P("What was the treasure?", "Chest contents: free toys for kids", "A cannonball", "A pirate flag"),
	} },
	CowboyCody = { Opponent = "Sheriff Shirley", Prompts = {
		P("Cody's horse got a speeding ticket. How fast was it going?", "Radar photo: 20 mph in a 25 zone", "A lasso", "A cowboy hat"),
		P("Was the horse even on a road?", "Map: it was on the horse trail", "A horseshoe", "A bag of oats"),
		P("Who was really speeding?", "Video: a sports car right behind the horse", "A belt buckle", "A cactus"),
	} },
	ZombieZeke = { Opponent = "Office Boss Barb", Prompts = {
		P("Barb says Zeke is 'a little too undead' for work. Does he do his job?", "Report: Employee of the Month, 3 times", "A torn shirt", "A brain-shaped stress ball"),
		P("Is being a zombie against company rules?", "Handbook: 'All employees welcome'", "A coffee mug", "A graveyard map"),
		P("Did Zeke scare any customers?", "Reviews: 'Very polite, a bit slow'", "A bandage", "A name tag"),
	} },
	NinjaNoodle = { Opponent = "Party Host Patty", Prompts = {
		P("Patty says Noodle was 'too sneaky' at her surprise party. Was he invited?", "Invitation: 'Come be SUPER sneaky!'", "A throwing star", "A smoke bomb"),
		P("Did the surprise work?", "Video: the birthday girl screamed with joy", "A headband", "A paper lantern"),
		P("Who really ate all the cake?", "Crumbs trail leading to Patty's dog", "A katana-shaped balloon", "A party hat"),
	} },
	KnightKevin = { Opponent = "Grocery Manager Gwen", Prompts = {
		P("Gwen says Kevin jousted a shopping cart. Who challenged whom?", "Video: the cart rolled at him first", "A shield", "A helmet plume"),
		P("Was the cart damaged?", "Photo: not a scratch (foam sword)", "A suit of armor", "A banner"),
		P("Does the store allow knights?", "Store sign: 'Everyone welcome, even knights'", "A dragon tooth", "A royal decree"),
	} },
	MermaidMarina = { Opponent = "Town Planner Terry", Prompts = {
		P("Terry says Marina's concert flooded the square. Who turned on the water?", "Video: the fountain broke during her song", "A seashell microphone", "A tail fin"),
		P("Did Marina have a permit for the show?", "Permit: 'Water-friendly concert approved'", "A starfish", "A pearl"),
		P("Did anyone get hurt?", "Report: everyone just got a little splashy", "A trident", "A coral crown"),
	} },
	ClownChuckles = { Opponent = "Car Inspector Ivan", Prompts = {
		P("Ivan says 40 people can't fit in one tiny car. Can they?", "Video: they all fit, with room for a dog", "A red nose", "A squirting flower"),
		P("Was the car safe?", "Safety report: clown car approved by experts", "A balloon animal", "A pie"),
		P("Did all 40 people want to ride?", "40 signed forms: 'Best ride ever'", "A unicycle", "A rubber chicken"),
	} },
	-- Epic -------------------------------------------------------------------------------------------
	TechTed = { Opponent = "The Robot Vacuum Union", Prompts = {
		P("The vacuums say they work too hard. How many hours do they clean?", "Schedule: 1 hour a day, then charging naps", "A smartphone", "A hoodie"),
		P("Did Ted ever give the vacuums a break?", "Calendar: 'Vacuum Vacation Day' every Friday", "A laptop", "A coffee cup"),
		P("What do the vacuums actually want?", "Their list: 'More dust bunnies to play with'", "A charging cable", "A drone"),
	} },
	MovieStarMaya = { Opponent = "Stunt Double Stella", Prompts = {
		P("Stella says she did all of Maya's stunts. Did she?", "Behind-the-scenes video: Maya did the big jump", "A gold star", "Sunglasses"),
		P("What does the movie contract say about credits?", "Contract: both names in the end credits", "A red carpet", "A popcorn bucket"),
		P("Who really did the scene with the shark?", "Video: it was a rubber shark AND Stella", "A director's chair", "An autograph"),
	} },
	KingReginald = { Opponent = "Royal Crown Makers Ltd.", Prompts = {
		P("The King's crown is stuck. What size did he order?", "Order form: 'Size Large' - they sent Small", "A royal scepter", "A throne cushion"),
		P("Did the crown makers check his head size?", "Email: 'We guessed' - Crown Makers", "A royal decree", "A castle key"),
		P("Is the King hurt?", "Doctor's note: fine, just can't wear hats", "A golden goblet", "A cape"),
	} },
	AstronautAce = { Opponent = "Moon Parks Department", Prompts = {
		P("The Moon Parks Department says Ace needed a permit. Did the moon have rules?", "Moon rulebook: completely blank", "A space helmet", "A moon rock"),
		P("Did Ace damage the moon?", "Photo: one tiny footprint, very neat", "A rocket", "A flag"),
		P("Who told Ace to walk there?", "Radio log: Mission Control said 'Go for it!'", "A space suit glove", "Freeze-dried ice cream"),
	} },
}

return ByClient
