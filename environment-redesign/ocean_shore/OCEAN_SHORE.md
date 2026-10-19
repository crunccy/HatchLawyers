# World 5 — Ocean Shore (Stage 5, 2026-10-19) · waiting for crnuch's approval

A sunny tropical beach on its own floating island: a sand beach all the way round a green middle, a surfboard gate,
a lighthouse, a seaside plaza with Big Blue the whale fountain and eight tiki beach shacks, three egg fields (coral,
tide pools, sandcastles), a turquoise lagoon, and the long wooden Shark Dock where Magistrate Megalodon charges.
Built in the shared kit (`../kit/`) plus this island's pieces in `os_parts.py`. Built on mr.robe's Windows PC
(Blender 5.2); the kit now also finds the Windows fonts.
```bash
Blender -b --python environment-redesign/ocean_shore/os_build.py              # .blend + layout JSON + renders
Blender -b --python environment-redesign/ocean_shore/os_ambience.py           # + the ambience, saved into the .blend
```

| Deliverable | File |
| --- | --- |
| Editable .blend (ambience animated: scrub the timeline) | `ocean_shore.blend` |
| Aerial beauty render | `renders/os_aerial.jpg` |
| Labelled top-down layout | `renders/os_layout_topdown.jpg` |
| Ground views | `renders/os_ground_arrival.jpg`, `os_ground_plaza.jpg`, `os_ground_fields.jpg`, `os_ground_arena.jpg` |
| Cliff view | `renders/os_cliff.jpg` |
| Positions (Blender + Roblox coords), spray / bubble / turning-sign points, gull rings | `os_layout.json` |

## The route (return portal past the boss, as decided)
```
ARRIVAL (south, on the beach) ──> OCEAN SHORE gate ──> orange path (lighthouse, giant sandcastles, Ocean-lawyer statues)
        ──> SEASIDE PLAZA (whale fountain, 8 beach shacks, umbrella tables) ──> side paths to 3 EGG FIELDS
            (Coral Garden W · Tide Pools E · Sandcastle Beach NE, off the east path)
        ──> THE SHARK DOCK over the lagoon (Magistrate Megalodon) ──> RETURN HOME portal (north)
```
| Place | Blender (x, y) | What |
| --- | --- | --- |
| Arrival pad + plaza | (0, −194) / (0, −188) | Orange studded plaza on the sand; Travel lands here |
| OCEAN SHORE gate | (0, −162) | Two giant surfboards (sky blue, coral) standing in the sand, a driftwood beam roped across their tops, a navy marquee, life rings, a starfish crest |
| SEASIDE PLAZA | (0, −47), r 34 | A wavy mosaic floor (white / sky / seafoam / sand rings); **Big Blue** the whale swimming through a round pool, facing south (eyes, smile, fins), spouting from his blowhole, tail up behind; eight tiki shacks facing in (SURF SHOP, SHAVED ICE, SMOOTHIES, SEASHELLS, BEACH TOYS, FISH & CHIPS, SNORKELS, FLOATS), each with a giant prop on its thatch roof; bunting round the ring; four umbrella tables. The four compass lanes stay open |
| Landmarks on the way | LIGHTHOUSE (−128, −100), giant sandcastles (−46, −66) and (50, −78), SHIPWRECK (−150, 18) | The lighthouse is red-and-white, 42 studs tall, with a keeper's cottage; its beam turns (ambience). The wreck is stuck in the west beach with a spilled treasure chest |
| Ocean-lawyer statues | Hammerhead (−40, −138), Narwhal (36, −112), Tidal Sovereign (−58, −8) | The game's own Ocean Epic / Mythic / Supreme lawyers (from `tools/zones/lawyers_top.json`) at ~28 studs, on plinths, facing the path |
| Coral Garden | (−114, −17), r 34 | Pink sand; branching corals, sea fans, brain corals, giant scallop shells, anemones, kelp, a treasure chest, starfish |
| Tide Pools | (116, −47), r 32 | Wet sand with five rock pools (bubbles in the ambience), rock piles, crabs, urchins, starfish |
| Sandcastle Beach | (122, 92), r 24 | On the beach: three sandcastles, buckets and spades, umbrellas with towels, a beach ball |
| **THE LAGOON** | round the dock's middle, 124 × 116 | Shallow turquoise water over wet sand with a little reef (corals, shells, starfish), two moored sailboats, two rowboats, four buoys, a sandy bank |
| **THE SHARK DOCK (boss arena)** | (0, 73), 72 × 148 | A wide studded wooden dock over the lagoon (planks along the charge, a dark sub-deck), pilings along both long sides with a low rope between them, open at both ends; a navy compass-rose inlay; a SHARK DOCK marquee, two SHARK ZONE! signs and tiki lamps at the south end; a lifeguard tower by the lagoon; crates, a drying net and a big anchor at the north end |
| **RETURN HOME portal** | (0, 175) | Sky-blue / blue / white ring, a scallop-shell keystone; the green home field is the same on every island |
| Buildings | SURF CLUB (−118, 62), AQUARIUM (138, 26), BOAT HOUSE (105, −118), BEACH CAFE (−82, 150), SEASIDE HOTEL (86, 150) | Decor shells. The SURF CLUB's surfboard sign and the AQUARIUM's fish sign TURN (ambience) |
| Waterfalls | west (−135, −60) at 204° · east (127, −93) at 324° | A rock pool, a stream and a waterfall off the edge each. The build picks angles clear of everything placed before it |

- Island: ~370 × 420 studs; a sand beach (studded) outside a wavy shoreline at ~80 % of the radius, lime grass in
  the middle (a 0.06 step up with a darker lip), sandy cliff tops over the shared rock strata.
- Palm groves on the beach plus single palms leaning out to sea; round trees and five hills inland.
- 87 beach props scattered on the sand: umbrellas + towels, deck chairs, beach balls, small sandcastles, surfboards
  (standing and lying), pulled-up rowboats, driftwood, shells, starfish, rocks, buckets.
- The dock's north end is computed from the portal stairs (6 studs short), and the portal from the island's real
  north edge.

## Gameplay numbers (Magistrate Megalodon, `Config.Bosses`, `docs/BOSSES.md`)
| | Value | Arena check |
| --- | --- | --- |
| Size | Scale 3.2 → ~26 studs tall, 16 × 18 across | Placed in the .blend at that scale (`Boss_Megalodon`, at (6, 61), on the deck) |
| Attack | **Line** (Fin Charge): Length 130, Width 20, LineSpeed 150 (a charge takes ~0.9 s), Windup 1.0 s, every 2.8 s; then Dizzy 2 s; WalkSpeed 42 | The dock's long axis is 148, so a full 130-stud charge fits along it. In the 1.0 s windup a player runs ~32 studs sideways, and only 10 are needed to leave the 20-wide lane. The dock is 72 wide, so there is room on both sides (and the shallow lagoon beyond the rope) |
| Suggested boss area | Blender x −28…28, y 7…139 (Roblox x −28…28, z −139…−7, island-local) | 8 studs inside the dock's edges: he stays on the dock, and a charge along it can run its full 130 (the area is 132 long). A charge across it stops at the edge (BossService clamps every Line to the area) |
| Distances (TriggerRange 60) | The plaza's north edge is 20 from the area; Coral Garden 55; Sandcastle Beach 70; Tide Pools 71 | His attacks are clamped to the area, so the north half of the plaza and the Coral Garden can make him turn and charge, but the charge can't leave the dock: a scare, not a hit. **The real danger is crossing the dock**, the only way to RETURN HOME, along his charge lane. The Dizzy 2 s after each charge is the window to run past (Hard boss) |

**Integration note (BossService today):** the boss's area is the zone's `Bounds` shrunk by `Margin` (40 along /
10 across). An island arena needs the area set directly (e.g. a per-boss `Arena` box), not derived from the
island's Bounds: see `../README.md` → "Notes for Stage 7".

## Egg spots — 24
| Where | Spots |
| --- | --- |
| Coral Garden / Tide Pools | 8 each |
| Sandcastle Beach | 4 |
| THE SHARK DOCK (bonus, on the dock) | 4 |

- Spots are sampled on open ground inside each field, clear of props (rock pools, corals, castles), ≥ 7 studs apart.
  Field spots sit on the field floors (z 0.3); the dock's bonus spots on the deck (z 1.2).
- The zone spawns up to 14 eggs at once (`Config.Zones.List` MaxEggs); it picks from these 24 spots.
- The **Ocean egg** design: sea blue with a white wave crest and a seafoam band, a sandy base, a little starfish
  lying on top (golden variant).

## Models (`os_parts.py`, studded brick, Blender-made)
| Group | Pieces |
| --- | --- |
| Beach props | Surfboards (standing, lying), striped umbrellas with towels, deck chairs, beach balls, sandcastles, buckets + spades, life rings, starfish, scallop shells, driftwood, rowboats, sailboats, buoys, bollards, crates, a drying fishing net, an anchor, a lifeguard tower, tiki lamps, bunting |
| Sea life | Branching corals, sea fans, brain corals, tube corals, anemones, kelp, crabs, urchins, rock pools, a treasure chest, pixel fish (signs) |
| Buildings | Tiki beach shack (×8), LIGHTHOUSE (+ keeper's cottage), SURF CLUB, AQUARIUM, BOAT HOUSE, BEACH CAFE, SEASIDE HOTEL (a shared beach-house shell + each its own pieces), SHIPWRECK |
| Landmarks | OCEAN SHORE gate (giant surfboards + driftwood beam), Big Blue the whale fountain, THE SHARK DOCK, the lagoon, shell-keystone RETURN HOME portal, statue plinths |
| Eggs | Ocean eggs + spot rings |

Round things are studded voxel rounds (stacked rings with studs on each exposed ledge); only flames, buoy lights
and coral tips are smooth balls. Static props avoid the leaf looks, because the wind sways those looks' studs
(sea greens are `kelp` / `seafoam`). Totals: 579k tris + 238k raised studs (one 48-tri stud mesh, instanced;
8.6 MB .blend).

## Ambience
### Visual (`os_ambience.py`, in the .blend: no preview clips, crnuch's call 2026-10-19)
Sunny, breezy, relaxed. Nothing flashes faster than 3 Hz. Clearances are reasoned in the script's header, since
nobody previews it.
| Effect | How |
| --- | --- |
| **Lighthouse beam** sweeps round (8 s a turn) | Its own object (two see-through `beam_light` bars, r 3.2–40) turning on the lamp's centre, z 34.9 |
| **Turning signs**: SURF CLUB's surfboard (10 s), AQUARIUM's fish (12 s) | Each its own object turning on its pole, its studs riding with it (`K.STUD_GROUP`) |
| **Big Blue's spout** sprays and falls back into the pool | Particles (pale blue drops, gravity) from the spout top; the spout column flows |
| **Bubbles** rise in the five tide pools | Particles (small pale bubbles) |
| The lagoon, rock pools and fall ponds ripple; both falls flow | Animated shaders (water noise / falling bands) |
| **Gulls** circle over the beach (r 176–205, z 26–38) and the lagoon (r 30–55 round the dock's middle, z 26–34) | The shared flapping fliers (`A.butterflies`) with white wings |
| Tiki flames and lamps breathe (~0.35 Hz); marquee bulbs blink (~1.4 Hz) | Emission drivers |
| Megalodon sways upright (6°, a small bob) | Keyframes, pivoted at his feet on the dock |
| Palms and trees sway (with their studs); clouds + islets drift (their studs ride along) | Shared `WindSway`; keyframes |

### Audio (research only, nothing downloaded or listened to; tiers as in `../central_hub/AUDIO.md`)
Licences below were read on each sound's own page (2026-10-19, via curl).
| Layer | Tier 1 (Creator Store search) | Tier 2 pick (licence checked) |
| --- | --- | --- |
| Primary bed: waves on the shore | "ocean waves", "beach waves", "seaside" | [Ocean Waves.wav](https://freesound.org/people/Noted451/sounds/531015/) (Noted451, **CC0**, 1:11, 44.1 kHz stereo). Long alternative: [Waves at Baltic Sea shore.wav](https://freesound.org/people/pulswelle/sounds/339517/) (pulswelle, **CC0**, 26:05, 44.1 kHz stereo) |
| Gulls (random, every 15–30 s, 3D near the lighthouse + the dock) | "seagull", "gulls" | [Seagulls / gaviotas clean wildtrack](https://freesound.org/people/Soojay/sounds/462462/) (Soojay, **CC0**, 1:16, 48 kHz stereo); short one-shots: [Seagull on beach](https://freesound.org/people/squashy555/sounds/353416/) (squashy555, **CC0**, 0:34, 44.1 kHz stereo) |
| Beach life: distant children playing, low | "beach crowd", "kids playing" | [BEACH, SUMMER, CHILDREN - vers 1](https://freesound.org/people/Anya_Media/sounds/437459/) (Anya_Media, **CC0**, 2:54, 48 kHz stereo). Keep it low and listen for words before using (a real beach). Alternative: [Ipanema Beach Ambience](https://freesound.org/people/felix.blume/sounds/410432/) (felix.blume, **CC0**, 5:00, 96 kHz stereo) |
| Whale fountain + falls | `Sfx` `fountain` (already licensed) | — |
| THE SHARK DOCK | an APM tension sting when the boss targets you; the charge + splash is the boss's own sound (BossService) | — |
| Music | APM "tropical", "steel drum", "summer beach" | — |

## Roblox compatibility notes (integration later, on approval)
**Dynamic, so not scenery:** eggs on `EggSpots`; the boss (BossService + Bosses.client, with its arena area above);
`Arrival`; RETURN HOME's carry rule (code later).

**Collision:**
- solid: ground, paths, the plaza, the dock deck and its posts, shacks, buildings, the wreck, statues, sandcastles,
  rocks, boats on the sand, the fountain basin
- no collision: the lighthouse beam, spray, bubbles, bunting, the dock's ropes (so players can step off into the
  lagoon), the lagoon / rock-pool / fall water (wadeable: water sits 0.3 above the sand), canopies, coral tips,
  starfish, shells
- the lagoon could also be Terrain water (swimmable) if crnuch prefers; it is shallow by design

**Mapping the look:**
- Turning signs + the beam → client-only rotation (like `WorldLife`), anchored, CanCollide off; the beam is Neon
  with Transparency ~0.6.
- Spray / bubbles → ParticleEmitters at the `os_layout.json` points (low Rate, LightEmission ≤ 0.3), culled by distance.
- Water → Glass / Transparency parts with scrolling `Texture`s (or Terrain water for the lagoon).
- `glow_*` → Neon.

**Streaming:** the plaza, each field, the lagoon, the dock and each building are separate objects.

## Known weaknesses (honest)
- **Open lawns:** the green middle between the plaza, the fields and the lagoon is wide and plain (trees and hills
  fill some of it). The beach ring carries most of the detail.
- **Plain interiors:** the shacks and buildings are shells (porches, awnings, signs, props); no interiors.
- **Upright-only pieces:** the kit's bricks only turn round the vertical, so surfboards, life rings, sails and the
  whale's flukes stand upright (pixel rows), never tilted; the wreck sits level rather than listing.
- **The dock is wide open on purpose:** nothing stands on it, so from far away it reads as one big wooden plane. The
  planks, posts, compass rose and the lagoon round it carry the theme.
- **Shadow buffer:** EEVEE warned "shadow buffer full" on the ground renders (≈ 2070 / 2048 shadow tiles, many small
  props in view); the renders look right, but a few far shadows may be missing.
