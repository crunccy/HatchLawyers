# Zone bosses: "Opposing Counsel" (concepts, 2026-10-12)

One boss per egg zone, roaming the lane like the giants in the reference game (docs/ZONES_REFERENCE.md). **Concepts, not
specs:** a local session builds the models (brick style, docs/CHARACTER_STYLE.md) and the code. Nothing here is built.
Bosses are the only characters whose names carry legal titles (CHARACTER_STYLE.md → Naming rule).

## What a boss does (user's calls, 2026-10-12)
- **A boss hit knocks your eggs loose.** Carry eggs through a zone, get hit, and the top egg of your stack (more on the
  harder bosses, `EggsKnocked` below) pops off and bounces a few studs away.
- **A dropped egg is free game.** Anyone can grab it, the player who dropped it included, at no price (it was
  already paid for). That's the risk that makes the walk home exciting. *This is the one place a player can end up
  without something they paid for* - the user's call, so keep the rest fair:
  - every attack has a **clear wind-up** (at least 1 s, a warning ring on the floor + a sound) so a player who
    watches can always dodge;
  - after a hit you're **safe for 3 s** (no juggling, no losing the whole stack in one combo);
  - bosses never enter the **Safe Zone**, never stand on a **gate**, and never come near firms or incubators;
  - a player carrying **nothing** gets bumped back with a funny effect, nothing else.
- **Dropped eggs** keep their zone and Golden status, glow so they're easy to spot, and vanish after ~30 s if nobody
  takes them (a tunable; the user may prefer they turn back into a normal priced zone egg instead).
- **Words on screen:** "OBJECTION! Your egg went flying!", "Grab it back!", "You grabbed a dropped egg!" - never
  "lose" (CLAUDE.md). Floor warning rings are orange / yellow, not red.
- **Boss Cases** (a boss stops, the whole server fights it in a courtroom minigame for a rarer egg): **parked for
  later** (user). The bosses below are designed so each could get one without a redesign.

## The six bosses
Each is 2-3x a player, brick style (studded parts, square eyes), with a small difficulty tag above its head
("EASY" / "MEDIUM" / "HARD" / "EXTREME" in green / yellow / orange / purple, FredokaOne with a thick black outline -
no emoji). They get cooler down the lane, like the rarity ladder: plain → bigger silhouettes → glowing parts → Space.

### 1. Briefcase Bay: **The Senior Partner** (EASY)
- **Look:** a towering, grumpy old lawyer, 2x a player. Charcoal three-piece suit, a white walrus moustache, half-moon
  glasses, a grey comb-over, a huge battered leather briefcase in one hand. Paper sheets swirl around his ankles.
- **Moves:** strolls the middle of the lane, slow, checking a pocket watch now and then (a pause = easy timing).
- **Attack: Briefcase Swing.** Lifts the briefcase overhead (1.2 s, the warning ring appears in front of him), swings
  it in a wide arc. Hits in a cone. `EggsKnocked` 1.
- **Lines:** "In my day, we WALKED to court!" · "Billable hours, people!" · "Objection... sustained!"
- **Build notes:** the best first boss: plain shapes, ~120 parts. Animate: walk, watch check, swing. Effect: a paper
  burst on the swing (Effects.burst with a paper colour).

### 2. Pet Park: **Barrister Bulldog** (EASY)
- **Look:** a huge squat bulldog in a long black barrister's robe and a curly white court wig, a red bow tie, jowls,
  a stubby tail that wags. Drool drips are little white bricks.
- **Moves:** waddles in zig-zags, sniffs the ground, sits down to scratch (pauses).
- **Attack: OBJECTION Bark.** Plants its feet and puffs up its chest (1 s), then barks: a ring-shaped shockwave around
  it (a short-range circle). "OBJECTION!" pops up in comic letters. `EggsKnocked` 1.
- **Lines:** "WOOF! Objection!" · "Order in the dog park!" · "Who's a good barrister? ME."
- **Build notes:** wig = stacked white cylinders-as-blocks. The shockwave = an expanding flat ring part + the
  existing burst.

### 3. Brainrot Boulevard: **Judge Martello** (MEDIUM)
- **Look:** a walking giant wooden gavel, 2.5x a player. The hammer head is the body, with a face on the front, a
  tiny judge's collar and two little arms; the handle splits into two legs in black shoes. Very brainrot.
- **Moves:** hops instead of walking - big bouncy arcs down the lane, a little "boing" each landing.
- **Attack: Gavel Slam.** Hops high (1 s, the warning ring shows where it'll land - it lands where you WERE standing
  when it jumped, so moving dodges it), slams down: "ORDER!". Radius hit on landing. `EggsKnocked` 1.
- **Lines:** "ORDER! ORDER!" · "Martello, Martello, sentenzaaa!" · "Boing... GUILTY of being too slow!"
- **Build notes:** one rigid body + two leg parts; the hop is a CFrame tween, no rig needed. Landing: dust burst +
  camera shake for players nearby.

### 4. Food Court: **Prosecutor Big Cheese** (MEDIUM)
- **Look:** a giant wheel of cheese standing on its edge, with holes, a smug face and a twirly moustache, a tiny
  prosecutor's tie, little arms holding a cocktail-stick sword with an olive on it.
- **Moves:** wobbles slowly upright, then sometimes tips onto its side and ROLLS.
- **Attack: Cheese Roll.** Tips over (1.2 s, a long warning lane appears on the floor), rolls straight down the lane
  fast, bouncing off the walls once. Anyone in the strip gets hit. `EggsKnocked` 1.
- **Lines:** "I'm the BIG cheese around here!" · "This case is... grate." · "You can't handle the cheese!"
- **Build notes:** the wheel is a ring of blocks around a cylinder of blocks (studded faces); the roll is a spin +
  move along the lane. A crumb trail of tiny yellow bricks behind it.

### 5. Ocean Shore: **Magistrate Megalodon** (HARD)
- **Look:** an enormous prehistoric shark, 3x a player, walking upright on stubby legs in a navy magistrate's robe with
  a gold chain of office. Jagged white teeth, little reading glasses, a gavel in one fin. A glowing blue lantern
  fish dangles from a badge.
- **Moves:** stalks the lane, then stops and turns toward the nearest player carrying eggs (it "smells" eggs).
- **Attack: Fin Charge.** Crouches and its dorsal fin glows (1 s, a warning lane toward its target), then charges.
  After a charge it's dizzy for 2 s (a free window to run past). `EggsKnocked` 2.
- **Lines:** "Court is in session... and you're LUNCH." · "Chomp chomp, case closed!" · "I find you... delicious."
  (playful, not scary - keep the face goofy)
- **Build notes:** big but simple: a stacked-block body; the robe is two flat panels. Effect: a water splash burst on
  the charge (the ICE ladder colours fit).

### 6. Space Base: **Chief Justice Eclipse** (EXTREME)
- **Look:** a tall robed judge, 3x a player, whose face is an eclipse - a black disc with a blazing gold corona.
  Deep purple robe with constellations, three gavels orbiting its head, floating a little off the ground. The
  coolest boss, like a Supreme lawyer is the coolest lawyer (rainbow / energy effects).
- **Moves:** glides slowly and silently, gavels spinning; now and then it rises up and looks around.
- **Attack 1: Gravity Pull.** Raises both arms (1.5 s, a big swirling warning circle), then pulls players inside it
  toward the centre for 2 s; the centre is a hit. Walking straight out of the circle escapes it. `EggsKnocked` 2.
- **Attack 2: Gavel Orbit.** The orbiting gavels fly out in a widening ring and come back (1 s warning glow).
- **Lines:** "The universe finds you... OUT OF ORDER." · "All rise. All of you. Into SPACE." · "Case dismissed... into
  orbit!"
- **Build notes:** the most effects: Effects.ENERGY for the pull, the Supreme rainbow for the corona. Keep parts
  modest (~200); the spectacle is in the effects.

## Numbers to put in Config (when it's built)
One `Config.Bosses` entry per zone, so a sim or a playtest can tune them without touching code:
`Zone`, `Name`, `Difficulty`, `WalkSpeed`, `AttackEvery` (s), `Windup` (s), `Radius` / `Length` (studs),
`EggsKnocked`, plus shared `SafeAfterHit` (3 s), `DroppedEggLifetime` (30 s), `DropScatter` (studs).
Starting guesses: Easy bosses attack every ~8 s, Medium ~6 s, Hard ~5 s, Extreme ~4 s.

## How it plugs into what's live (for the local session)
- The live zones (`Server.ZoneService`) already keep each player's carried eggs on the server (`Zones.Carried`) and
  know each zone's `Bounds`. A boss service only needs: move the boss inside its zone's bounds (away from the
  Safe Zone and gates), check hits on the server (distance / ring tests, never the client's word), and on a hit
  move the top `EggsKnocked` entries out of `Carried` into dropped eggs in the world.
- A dropped egg is a zone egg with price 0 and an owner-free pickup; picking it up goes through the same carry checks
  (bag space, lawyer room) as a normal zone egg.
- The hit check, the 3 s safe window and the drop all happen server-side; the client only shows warnings, effects,
  the difficulty tag and the lines.
- Phones: warnings must be readable from the default camera distance, and nothing should cover the jump button.
