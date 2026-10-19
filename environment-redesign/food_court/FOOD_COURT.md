# World 4 — Food Court (Stage 5, 2026-10-19) · waiting for crnuch's approval

An oversized, colourful food festival on its own floating island: a ketchup-and-mustard gate holding a giant hot dog,
an orange path past giant food, a checkered food-court plaza with a soda fountain and eight stalls, three egg fields
(picnic, desserts, veggies), restaurants round the edge, soda and chocolate waterfalls, and a giant cutting board
where Prosecutor Big Cheese rolls. Built in the shared kit (`../kit/`) plus this island's pieces in `fc_parts.py`.
```bash
Blender -b --python environment-redesign/food_court/fc_build.py              # .blend + layout JSON + renders
Blender -b --python environment-redesign/food_court/fc_ambience.py           # + the ambience, saved into the .blend
```

| Deliverable | File |
| --- | --- |
| Editable .blend (ambience animated: scrub the timeline) | `food_court.blend` |
| Aerial beauty render | `renders/fc_aerial.jpg` |
| Labelled top-down layout | `renders/fc_layout_topdown.jpg` |
| Ground views | `renders/fc_ground_arrival.jpg`, `fc_ground_plaza.jpg`, `fc_ground_fields.jpg`, `fc_ground_arena.jpg` |
| Cliff view | `renders/fc_cliff.jpg` |
| Positions (Blender + Roblox coords), steam / smoke / turning-sign points | `fc_layout.json` |

## The route (return portal past the boss, as decided)
```
ARRIVAL (south) ──> FOOD COURT gate ──> orange path (giant burger, fries box, food-lawyer statues, food trucks)
        ──> THE FOOD COURT PLAZA (soda fountain, 8 stalls, seating) ──> side paths to 3 EGG FIELDS
            (Picnic Park W · Dessert Garden E · Veggie Patch NE)
        ──> THE CHEESE BOARD (Prosecutor Big Cheese) ──> RETURN HOME portal (north)
```
| Place | Blender (x, y) | What |
| --- | --- | --- |
| Arrival pad + plaza | (0, −199) / (0, −193) | Orange studded plaza; Travel lands here |
| FOOD COURT gate | (0, −167) | A giant ketchup bottle and mustard bottle holding a hot dog on their nozzles, a red marquee |
| THE FOOD COURT PLAZA | (0, −40), r 34 | Red-and-white tablecloth floor; a giant striped soda cup (lid, bendy straw) pouring into a soda basin; eight stalls facing in (PIZZA, HOT DOGS, ICE CREAM, LEMONADE, DONUTS, POPCORN, NOODLES, BURGERS), each with a giant food on its roof; picnic tables; string lights from every stall to the straw. The four compass lanes stay open |
| Giant food | burger (−52, −70), fries box (52, −72), lawn pizzas (−42, 18) and (44, 2) | Studded sculptures; the pizzas lie flat and are walkable |
| Food-lawyer statues | Chili Prosecutor (−40, −140), Dragon Fruit Duke (36, −110), Grand Gâteau (−58, 0) | The game's own Food lawyers (from `tools/zones/lawyers_top.json`) at ~29 studs, on plinths, facing the path |
| Food trucks | ICE CREAM (−44, −112), HOT DOGS (40, −132) | Parked by the south path |
| Picnic Park | (−112, −10), r 34 | Checkered blankets with baskets, watermelon slices, giant apples, a BBQ grill (smoke), picnic tables |
| Dessert Garden | (112, −40), r 32 | Pink frosting floor with sprinkles; lollipops, cupcakes, candy canes, giant donuts |
| Veggie Patch | (92, 75), r 24 | Raised beds of giant carrots, broccoli trees, giant tomatoes |
| **THE CHEESE BOARD (boss arena)** | (0, 87), 72 × 130 | A giant studded wooden cutting board (planks along the roll), rounded corners, a low rim open at both ends, a cheese-wedge inlay, a handle on the west side; crackers, grapes, olive picks, cheese wedges and a butter knife round it; a THE CHEESE BOARD marquee at the south end |
| **RETURN HOME portal** | (0, 180) | Red / yellow (ketchup + mustard) ring, a cherry on top; the green home field is the same on every island |
| Restaurants | BURGER BARN (−118, 62), PIZZA PALACE (138, 26), FRY FACTORY (−128, −92), DONUT DINER (105, −118), TACO TOWER (−82, 150), NOODLE HOUSE (86, 150) | Decor shells with striped awnings and signs. Three signs TURN (ambience): the barn's burger, the diner's donut, the palace's pizza slice |
| Soda falls / chocolate falls | soda pond (-102, -126) at 231° · chocolate pond (122, -89) at 324° | An orange-soda pond + stream + waterfall; a chocolate one. The build picks angles clear of everything placed before it |

- Island: ~350 × 430 studs; lime studded grass, warm rock cliffs, 12 fruit orchards (orange / apple / lemon trees).
- The board's north end is computed from the portal stairs (6 studs short), and the portal from the island's real
  north edge.

## Gameplay numbers (Prosecutor Big Cheese, `Config.Bosses`, `docs/BOSSES.md`)
| | Value | Arena check |
| --- | --- | --- |
| Size | Scale 3.2 → ~20 studs tall, 24 wide | Placed in the .blend at that scale (`Boss_BigCheese`, at (6, 75)) |
| Attack | **Line** (Cheese Roll): Length 110, Width 22, LineSpeed 120 (a roll takes ~0.9 s), Windup 1.2 s, every 3.5 s; WalkSpeed 40 | The board's long axis is 130, so a full 110-stud roll fits. In the 1.2 s windup a player runs ~38 studs sideways, and only 11 are needed to leave the 22-wide lane. The board is 72 wide, so there is room on both sides |
| Suggested boss area | Blender x −28…28, y 30…144 (Roblox x −28…28, z −144…−30, island-local) | 8 studs inside the board's edges: he stays on the board, and a roll along it can run its full 110. A roll across it stops at the edge (BossService clamps every Line to the area: "shorter at the zone's edge") |
| Distances (TriggerRange 60) | The plaza's north edge is 36 from his nearest point; the Veggie Patch ~40; Picnic Park ~59; Dessert Garden ~77 | His attacks are clamped to the area, so he can turn toward the Veggie Patch or Picnic Park but can't reach them: a scare, not a hit. **The real danger is crossing the board**, the only way to RETURN HOME, along his roll lane. The board's south entrance is inside his reach by design |

**Integration note (BossService today):** the boss's area is the zone's `Bounds` shrunk by `Margin` (40 along /
10 across). An island arena needs the area set directly (e.g. a per-boss `Arena` box), not derived from the
island's Bounds: see `../README.md` → "Notes for Stage 7".

## Egg spots — 24
| Where | Spots |
| --- | --- |
| Picnic Park / Dessert Garden | 8 each |
| Veggie Patch (beside the board) | 4 |
| THE CHEESE BOARD (bonus, on the board) | 4 |

- Spots are sampled on open ground inside each field, clear of props (including the raised beds), ≥ 7 studs apart.
  The board's bonus spots sit on the board's surface (z 1.2).
- The zone spawns up to 14 eggs at once (`Config.Zones.List` MaxEggs); it picks from these 24 spots.
- The **Food egg** design: a golden-brown bun egg with a pink frosting cap and rainbow sprinkles (golden variant).

## Models (`fc_parts.py`, studded brick, Blender-made)
| Group | Pieces |
| --- | --- |
| Giant food | Burger (bun, patty, cheese with drips, tomato, lettuce frill, sesame seeds), fries box, lawn pizza, upright pizza slice, hot dog, donuts (flat + upright), ice cream, cupcake, lollipop, candy cane, watermelon slice, apple, carrot, broccoli, tomato, grapes, olive pick, cheese wedge, crackers, butter knife |
| Buildings | Food stall (×8), food truck (×2), BURGER BARN, PIZZA PALACE, FRY FACTORY, DONUT DINER, TACO TOWER, NOODLE HOUSE (shared shell + each its own roof, sign and props) |
| Landmarks | FOOD COURT gate (giant squeeze bottles + hot dog), soda-cup fountain, THE CHEESE BOARD, cherry-keystone RETURN HOME portal, statue plinths |
| Street pieces | Condiment-bottle lamps, picnic tables with striped umbrellas, blankets + baskets, string lights, raised garden beds |
| Plants | Fruit trees (orange / apple / lemon) |
| Eggs | Food eggs + spot rings |

Every round food is a studded voxel round (stacked rings with studs on each exposed ledge); only the glowing bulbs
are smooth balls. Static props avoid the leaf looks, because the wind sways those looks' studs (`fc_parts.py`
header). Totals: 439k tris + 224k raised studs (one 48-tri stud mesh, instanced; 6.7 MB .blend).

## Ambience
### Visual (`fc_ambience.py`, in the .blend: no preview clips, crnuch's call 2026-10-19)
Cheerful, busy, inviting. Nothing flashes faster than 3 Hz. Clearances are reasoned in the script's header, since
nobody previews it.
| Effect | How |
| --- | --- |
| **Steam** rises from every stall's roof vent and the FRY FACTORY chimney | Particles (soft white puffs), emitted where nothing is above |
| **Smoke**: a little from the PIZZA PALACE oven chimney and the picnic BBQ grill | Particles (grey puffs) |
| **Turning signs**: BURGER BARN's burger (9 s a turn), DONUT DINER's donut (10 s), PIZZA PALACE's slice (12 s) | Each its own object turning on its pole, its studs riding with it (`K.STUD_GROUP`) |
| Soda pours from the fountain cup; both falls flow; the soda and chocolate ponds ripple | Animated shaders (soda / chocolate highlights, not water blue) |
| String lights twinkle (bulbs blink ~1.4 Hz, the warm ones breathe); lamps and the noodle-house lanterns breathe | Emission drivers |
| Big Cheese wobbles upright (5°, a small bob) | Keyframes, pivoted at his base in the middle of the board |
| Orchard canopies sway (with their studs); clouds + islets drift (their studs ride along) | Shared `WindSway`; keyframes |

### Audio (research only, nothing downloaded or listened to; tiers as in `../central_hub/AUDIO.md`)
Licences below were read on each sound's own page (2026-10-19).
| Layer | Tier 1 (Creator Store search) | Tier 2 pick (licence checked) |
| --- | --- | --- |
| Primary bed: restaurant chatter, food-court activity | "restaurant ambience", "food court", "crowd chatter" | [German restaurant with a crowd.wav](https://freesound.org/people/BonnyOrbit/sounds/334140/) (BonnyOrbit, **CC0**, 2:16, 48 kHz stereo). Keep it low and listen for words before using (it's a real restaurant) |
| Cooking sounds: kitchen clatter, plates, cutlery | "kitchen ambience", "dishes" | [Kitchen Ambience](https://freesound.org/people/brunoboselli/sounds/512511/) (brunoboselli, **CC0**, 1:03, 48 kHz stereo; cutlery, glasses, cabinets, no voices) |
| Gentle sizzling (3D, at the stalls + the grill) | "sizzle", "frying" | [Bacon frying](https://freesound.org/people/odilonmarcenaro/sounds/579088/) (odilonmarcenaro, **CC0**, 0:42, 44.1 kHz stereo, marked loopable) |
| Occasional cash register (random, every 20–40 s, from a stall) | "cash register", "cha-ching" | [cash register.wav](https://freesound.org/people/monotraum/sounds/387992/) (monotraum, **CC0**, 0:07, 48 kHz stereo) |
| Soda fountain + falls | `Sfx` `fountain` (already licensed), pitched up for fizz | — |
| THE CHEESE BOARD | an APM tension sting when the boss targets you; the roll is the boss's own sound (BossService) | — |
| Music | APM "kids party", "happy ukulele", "summer festival" | — |

## Roblox compatibility notes (integration later, on approval)
**Dynamic, so not scenery:** eggs on `EggSpots`; the boss (BossService + Bosses.client, with its arena area above);
`Arrival`; RETURN HOME's carry rule (code later).

**Collision:**
- solid: ground, paths, the plaza, the board and its rim, stalls, restaurants, trucks, statues, giant food
  sculptures, garden beds
- no collision: steam, smoke, string lights, the soda pours, falls, canopies, sprinkles, lawn-pizza toppings (the
  pizza itself is a walkable floor)

**Mapping the look:**
- Turning signs → client-only rotation (like `WorldLife`), anchored, CanCollide off.
- Steam / smoke → ParticleEmitters at the `fc_layout.json` points (low Rate, LightEmission ≤ 0.3), culled by distance.
- Soda / chocolate → scrolling `Texture`s on the pours, falls and ponds.
- `glow_*` → Neon.

**Streaming:** the plaza, each field, the board and each restaurant are separate objects.

## Known weaknesses (honest)
- **Open lawn:** between the restaurants the island has wide lime lawns (orchards and hills fill some of it). It
  reads calm next to the busy plaza.
- **Plain interiors:** the restaurants and stalls are shells (awnings, signs, counters, props); no interiors.
- **Lollipops and the upright donut** use smooth upright rings (like the portal), not studded faces.
- **The board is wide open on purpose:** nothing stands on it, so from far away it reads as one big wooden plane.
  The planks, the rim and the decor around it carry the theme.
