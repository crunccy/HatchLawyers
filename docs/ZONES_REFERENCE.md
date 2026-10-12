# Zones map: what the reference does, what ours needs (2026-10-12)

The user wants the egg zones (partner's design: firm = idle part, zones = active part, eggs scattered in zones,
carry them home, Law License gates) to look and connect like the reference game ("Break an Egg"). **Copy the
structure and the feel, not the content:** no names, characters, logos or exact layouts from it.

Reference shots (from the user's screen recording):
- `references/zones-ref-base-safezone.webp`: the base area, fenced pens, the Safe Zone line, the lane starting.
- `references/zones-ref-forest-eggs.webp`: the first zone from the Safe Zone line; eggs scattered in the grass.
- `references/zones-ref-desert-lane.webp`: looking down the lane: forest, then desert, then snow, then candy.
- `references/zones-ref-snow-lane.webp`: the snow zone from the desert edge, candy zone behind it.

Our map before the rebuild: `references/map-before-2026-10-11-island.webp`, `references/map-before-2026-10-11-plaza.webp`.

## What the reference does (and we copy)

**1. One long lane, zones in a row.** The zones aren't separate islands. They're one long straight lane running away
from the bases, cut into back-to-back sections. You always see the next zone (and the one after) at the end of the
lane, which pulls you forward. Each zone is about 2–3 screen-lengths long.

**2. A sunken lane between tall walls.** The lane is a wide trench. Tall brick walls on both sides (warm terracotta
`#C8645A`-ish, studded) are about 2–3 characters tall. The ground on TOP of the walls is the zone's ground colour,
packed with decoration. It frames the lane like a valley and hides the edge of the map. The walls keep players on
the path without invisible barriers.

**3. Each zone owns a colour.** Hard ground-colour change at the border (no blending), a slight step or a strip in
a darker shade marks it. Lime grass forest, then sand desert, then snow white, then candy pink. One look at the
ground tells you where you are.

**4. Decoration is dense and themed, on the walls AND in the lane.** Forest: chunky trees at 3–4 sizes, bushes,
mushrooms. Desert: cacti, dead trees, bones, rocks, a stepped pyramid in the background. Snow: snow-capped trees,
ice chunks, snow piles. Candy: lollipop trees, candy rocks. Big props along the wall tops, small clutter (rocks,
bones, tufts) scattered on the lane floor. Nothing floats; everything sits on the ground. There's no empty floor
bigger than ~2 character-lengths.

**5. Everything is brick.** Studs on every surface, chunky stepped shapes, the same look as our characters
(docs/CHARACTER_STYLE.md) and our trees. No smooth parts, no textures.

**6. Eggs are scattered, small and themed.** Eggs lie on the lane floor at random spots across the zone, not on
pedestals in a row. Each is about knee-high and styled for its zone (a rocky egg, a cactus egg, a frosty egg, a bone
egg), with a SMALL label above it: name on one line, rarity on a second line in the rarity colour. Rarer eggs are
fewer and glow.

**7. Roaming giants.** Each zone has one or two big creatures (2–3× a player) slowly wandering the lane. They're the
danger and the spectacle. A difficulty tag floats over each (an emoji face plus Easy / Medium / Hard / Extreme in a
colour).

**8. Clear guidance.** A white chevron trail on the floor points the way (to the next zone, or home when you carry
something). A red line across the lane plus big "Safe Zone" floor lettering marks where the base area ends. A big
"Your Base" house icon floats over your own base.

**9. Bases near spawn.** The player bases are fenced pens on open grass next to the lane's start, with each owner's
creatures shown inside, so you see other players' collections on the way out.

## Applying it to our game
| Reference | Ours |
| --- | --- |
| Lane of zones | Briefcase Bay (office park) → Pet Park → Brainrot zone → Food Court → Ocean Shore → Space Base, the 6 eggs in price order |
| Difficulty gates | **Law License** gates between zones (Bronze, Silver, Gold…): a big gate arch with the license badge and its price |
| Zone colours | Briefcase: office grey-blue carpet + green lawn · Pet: lime park grass · Brainrot: purple / magenta · Food: checkered red-white picnic + orange · Ocean: sand + shallow water strips · Space: dark purple floor with craters |
| Wall-top decoration | Briefcase: hedges, file-box towers, water coolers, office trees · Pet: dog houses, bones, ball piles · Brainrot: odd giant food-objects · Food: giant fruit, cupcakes, pizza slices · Ocean: palm trees, shells, coral · Space: rocks, antennas, little planets |
| Base pens with creatures | Our firms (the plots) stay where they are; the lane starts at the hub, next to the firms |
| Roaming giants | "Opposing Counsel" bosses, below (not built yet; decide first) |
| Chevrons / Safe Zone / Your Base | Same idea: chevrons to the next zone and back to your firm; "Safe Zone" where the hub ends; a marker over your own firm |

## Rules for the build (our existing ones still apply, CLAUDE.md)
- **Floating text must never overlap.** One label per thing, small, stacked at most two lines. No world-space price
  numbers floating loose in the lane (the "163.69M" in our current map).
- **Paths:** orange with white dashed edges (CLAUDE.md palette), not blue.
- **Phones:** every player sees this. Big chunky parts over many tiny ones, StreamingEnabled-friendly models
  (group decoration per zone), and the existing EffectsLod for particles. Keep the lane compact: one zone should
  take about 15–25 seconds to walk across.
- **The first zone is next to spawn** and the first egg is free (the tutorial target: first egg within 2 minutes).

## Bosses: idea for the user to decide
**Decided 2026-10-12 → [BOSSES.md](BOSSES.md):** any boss hit drops ALL your eggs (animated, no on-screen text) and
dropped eggs are free game for anyone;
Boss Cases parked for later. Boss names: The Senior Partner, Barrister Bulldog, Judge Martello, Prosecutor Big Cheese,
Magistrate Megalodon, Chief Justice Eclipse.

In the reference, giants roam the zones. Our version could be **"Opposing Counsel"**: a giant rival lawyer per zone
(a briefcase-swinging partner in Briefcase Bay, a huge bulldog attorney in Pet Park, and so on) walking the lane.
- **Simple version:** if it bumps you while you carry an egg, you drop the egg ("OBJECTION!") and it rolls back.
  It's danger without anyone losing anything they own (the design rule: no losses).
- **Bigger version later:** every so often a zone boss stops and a server-wide **Boss Case** starts: everyone
  nearby taps "Present Evidence" (the courtroom minigame already exists) to beat it together, and everyone who
  helped gets a rarer egg.
