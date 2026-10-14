# Proposal: more minigames + what goes on the upper floors

## DECIDED 2026-10-13 (mr.robe, user's call): build all of it EXCEPT the Rooftop Helipad
"Add 2. and 3. I like these" - "not the rooftop helipad though" - "everything else". So: all 9 minigames and 8 of
the 9 floors. Built one at a time, each playtested and pushed before the next; progress is ticked here.

**Phase A: no save-format change** (uses `data.Minigames`, the existing cooldown map; runtime-only state):

| # | What | Status |
|---|---|---|
| A0 | Arcade framework: `Config.Arcade`, `Server.ArcadeService` + one module per game, `StarterPlayerScripts.Arcade` + one client module per game, booths built in Blender | to do |
| A1 | Lie Detector (S) | to do |
| A2 | Briefcase Stack (S) | to do |
| A3 | Filing Frenzy (S) | to do |
| A4 | Evidence Hunt (M) | to do |
| A5 | Courthouse Obby + server races (M) | to do |
| A6 | Objection! Duel (M) | to do |
| A7 | Evidence Relay, team event (M) | to do |
| A8 | Zone challenges: Pet Park, Food Court, Ocean Shore, Space Base (M each) | to do |
| A9 | Case Battles (L, a daily opponent - no ladder saved yet) | to do |
| A10 | VIP Client Floor (touches CaseService: heads-up line in the log) | to do |
| A11 | Private Courtroom hosts the Big Case trials | to do |

**Phase B: needs new saved fields** - after crnuch's mutations push (save v18, open item in SESSION_LOG), as v19:

| # | What | New saved field | Status |
|---|---|---|---|
| B1 | Hall of Fame / Lawyer Index | `Index` (every lawyer id ever owned + best mutation) | to do |
| B2 | Case Files Archive | `CaseFiles` (wins by client type) | to do |
| B3 | Moot Court | `Training` (booth slots) | to do |
| B4 | Partner's Office | `ManagerRules` | to do |
| B5 | Mail Room | `Mail` (daily quests) | to do |
| B6 | Guest Lounge | `Likes` / guestbook | to do |

mr.robe asked on 2026-10-13: "List me some minigames that we could continue to add that would be more intricate and
fun" and "Think of some ideas of what we could have on the upstairs floors of the buildings that would be meaningful
and actually would make sense." **Nothing here is built.** Pick ideas, write the picks down as "user's call",
and claim one in SESSION_LOG before building it.

## What's there today
- **Minigames:**
  - Gavel Bonk, a whack-a-mole, and Lucky Briefcase, a shell game, on the hub pads (`Config.Minigames`). Both are
    solo and tap-only, and pay minutes of your income.
  - The Big Case belt, the courtroom evidence cards, and the zone bosses.
- **Upper floors:** the elevator goes up, but the floors mostly hold rooms bought on the lawn (`Config.FirmAreas`).
  Each one is a passive +% (Rooftop Café, Coffee Break Room, Law Library, Conference Room, Atrium Coffee Bar,
  Rooftop Garden, Penthouse Suite, Private Courtroom). The Executive Lounge is the only room you go and stand in.
  So there's no reason to visit them twice.

The rule for both lists below: tie into the core loop (lawyers, clients, cases, eggs), keep it tap-friendly for
young players, and make it worth coming back to.

---

## Part 1: minigames (more intricate than tap-a-target)

Effort: S = a day or so with existing pieces, M = a few sessions, L = a system of its own.

| # | Name | How it plays | Why it's fun / what it ties into | Effort |
|---|---|---|---|---|
| 1 | **Case Battles** | Pick 3 of your lawyers and face an "Opposing Counsel" team in a short auto-battle: 3 rounds, rarity + mutation + skills decide the swings, and you tap a SPECIAL when your lawyer's meter fills. Ladder of fictional opponents, a new one each day. | The first place your *collection* matters outside earnings. A reason to mutate and skill up lawyers; it reuses the boss characters as opponents. | L |
| 2 | **Evidence Hunt** | A small crime-scene room ("Who ate the Judge's donut?") with 5 glowing clues hidden; 60 s to find them, then pick the culprit from 3 suspects (pictures, no reading). A new seeded case every day. | Exploration + a light deduction "aha", still law-themed. Reuses the client roster as suspects and the Evidence card art. | M |
| 3 | **Objection! Duel** | 1v1 (or vs. an NPC) at the hub courthouse: "OBJECTION!", "HOLD IT!" and "TAKE THAT!" prompts flash in rhythm, you hit the matching big button, and combos push the jury meter your way. Spectators can watch. | The game's first social / competitive moment; short (30 s), loud and funny. | M |
| 4 | **Filing Frenzy** | Papers slide down a conveyor; tap or swipe each into the right coloured stamp bin. It speeds up; 3 misses jam the machine. High score per day. | An easy skill ceiling, readable at phone size. Fits a conveyor model (there's a ConveyorBelt Blender file in the repo folder). | S |
| 5 | **Courthouse Obby / Jury Run** | A parkour course over the courthouse roof: swinging gavels, rolling briefcases, stamp checkpoints. Solo for time; **every 15 min a server-wide race** for a golden egg. | A server event that gathers players. It's a format kids already love. | M |
| 6 | **Zone challenges**, one per zone | Pet Park: herd runaway pets into the pen. Food Court: "Order Up!", stack the right burger before the timer. Ocean Shore: fish evidence crates out of the water. Space Base: zero-gravity gem collecting. Each one pays that zone's egg. | Gives every zone its own flavour and a reason to go back after you've moved on. | M each |
| 7 | **Briefcase Stack** | One-tap tower stacking: a briefcase slides back and forth, tap to drop it; perfect drops keep the full width. Height = reward. | The simplest "one more try" loop; good while waiting for a cooldown. | S |
| 8 | **Lie Detector** | A needle swings over a TRUTH / LIE dial and you tap when it's in the green, faster every round; a streak multiplies the prize. | A reaction game that still fits the theme; tiny to build. | S |
| 9 | **Evidence Relay** (team event) | Two teams (Defence vs Prosecution) carry evidence boxes across the hub to their courthouse while dodging the Big Case belt; the winners get a 10-minute server buff. | Team play and talking to other players; ties into the hub layout. | M |

**My top three:**
1. **Case Battles.** It gives every lawyer, mutation and skill a second purpose. Big, but it's what turns
   collecting into playing.
2. **Evidence Hunt.** It's the most "law firm" of the ideas and has daily replay.
3. **Courthouse Obby with timed server races.** It's the cheapest way to get players together.

---

## Part 2: upper floors that mean something

The idea: each floor is **a place you go to do something** for your lawyers, clients or eggs, not a +% you buy
once. Floors unlock with the building stage, so the bigger buildings (Glass Office: 4 floors; Corporate HQ;
Supreme Tower: 12) fill up naturally. The existing paid rooms can keep their bonuses and gain the activity.

| Floor | What you do there | Why it makes sense | Fits stage |
|---|---|---|---|
| **VIP Client Floor** | Rare / Legendary clients don't walk in from the street any more: they arrive upstairs and wait. You ride up, greet them ([E]) and pick which lawyer takes the big case. Ignore them for too long and they leave. | Real law firms meet big clients privately. It turns rare clients into an *active* moment, and the elevator finally has a reason. (Builds on the Conference Room's "rare clients" bonus.) | 3+ |
| **Moot Court** (training floor) | Seat a bench lawyer in a practice booth; it trains over time and earns **free skill rolls** (`FreeSkillRolls`) or levels up a skill. You come back to collect. | Lawyers practise in mock trials. A use for the bench lawyers who aren't in an office, and the Skills system gets a home. | 4+ |
| **Case Files Archive** | Every case won files a folder; the shelves fill up by client type. Complete a shelf (e.g. 25 "Pet" cases) for a permanent badge + bonus. The Courtroom's evidence cards are kept here too. | A firm's records room. A visible, physical *collection* of your history, with long-term goals. (Upgrades the Law Library.) | 4+ |
| **Hall of Fame / Lawyer Index** | A gallery wall with a frame for every lawyer in the catalog: grey until you've hatched one, gold when it's mutated. Completing an egg's set gives a permanent bonus for that egg's lawyers. | The "Index" every pet game has, but as a room in *your* building that visitors can see. A strong reason to hatch everything. | 5+ |
| **Partner's Office** (control room) | Screens show every office's status. The Manager lives here: you set rules ("auto-assign rare clients to my best lawyer", "auto-upgrade the cheapest office") and buy its upgrades. | The boss's office is upstairs. It moves automation from a menu into the world, and it's the late-game sink. | 5+ |
| **Rooftop Helipad** | (a) Your private travel point: fly to any owned zone from your own roof (the same trip animations as the Travel Portal). (b) **Courier drones**: send a drone to a zone, and it comes back with an egg after N minutes (upgrade drones for more and faster trips). | A firm's helipad is the classic "we made it" sign. It gives the roof a job and is an idle way to get eggs, the game's main item. | 5-6 |
| **Mail Room** | Letters from clients arrive daily with small quests ("win 3 Pet cases", "hatch a Food egg") for eggs and coins; a mailbox you open each day. | Quests in a form kids get (letters!), and a daily return reason. Could absorb the Goals panel's job. | 3+ |
| **Guest Lounge** (social) | When friends visit your firm they can sit in your lounge: both get a small buff, and they sign a guestbook / leave a "like" that shows on your sign. | Visiting other firms becomes worthwhile; a light social loop and bragging rights. | 4+ |
| **Private Courtroom** (the existing room, made playable) | Big Case trials from the belt are played *in your own courtroom* upstairs, in front of your Showcase lawyers. | You already pay for the room; now it hosts your biggest moments. | 6 |

**My top three:**
1. **VIP Client Floor.** It's the most natural for a law firm and makes rare clients exciting.
2. **Hall of Fame / Lawyer Index.** It's the strongest long-term goal and is mostly UI + a wall of frames.
3. **Rooftop Helipad with courier drones.** It gives the roof a job and is an idle egg income that ties into
   zone travel.

## Notes for whoever builds these
- Models from Blender (user's call 2026-10-13), as brick Parts via JSON, like the travel portal and the lawyers.
- Anything paid that's random must show exact odds (CLAUDE.md → Robux). New saved fields bump `SCHEMA_VERSION`.
- Rewards in `Config`, and run the sim (`tools/economy_sim.py`) for anything that pays coins or eggs on a timer
  (drones, Mail Room, Moot Court).
