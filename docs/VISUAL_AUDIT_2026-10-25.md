# Visual audit — map model overhaul (2026-10-25)

crnuch's local session. **No fixes were applied in this pass:** this is the audit and the fix order only. Read
alongside the research handoff (`codex/visual-polish-research`, docs/VISUAL_RESEARCH_START_HERE.md); where it and
current main differ, current main and current Studio win.

## What was inspected, and how

| Subject | How | Coverage |
| --- | --- | --- |
| **The new overhaul models** (122 models in `tools/blender/overhaul/`: props, hub buildings, gameplay pieces, minigames, firm stages 2-6, office hall, six islands' landmarks) | Blender only - **none of them is in the place yet** (no upload / install). Four renders each at a player's eye height (front, front-left, back-right, side) at normal viewing distance, with a player for scale (`audit_views.py`); the island renders from the approved v2 cameras (`art/overhaul/islands/`) | All 122, every side |
| Same models, geometry | `check_models.py` (floating pieces: 0) and the new **`check_models.py -- zfight`** (coplanar faces of two colours that face the same way, overlap, and are not hidden inside other geometry) | All 122 |
| **The hub as players see it** (HubMap wiring) | Studio, Edit mode + a local Play session (HubMap ran: 25 models moved, 2363 look-alike parts parked). Captures in `art/audit/E*`, `P*` | Hub only |
| Characters, animation, effects, UI previews, phone, the six islands in Play | **Not inspected in this pass** (crnuch: focus on the new models). Nothing below claims anything about them | - |

Evidence levels used below: **Observed** = seen in a Studio capture or a render of the model; **Check** = found by an
automated geometry check (real, but the in-game flicker itself is not seen yet: the meshes are not in Roblox);
**Source** = read from code / instance data; **Proposed** = an art suggestion, not a defect.

Studio captures could not be saved by macOS screen capture; the MCP's own captures are the files in `art/audit/`,
each with its camera below so it can be repeated (`screen_capture` with `camera_position` / `look_at_position`).

## Ranked findings

### Must fix (before the overhaul goes in)

**M1 · Z-fighting in 45 of the new models (124 visible spots)** - Check
- Where: builders in `tools/blender/overhaul/` (`hub_gameplay.case_belt`, `firm_stages` stage 2-6, `hub_license`,
  `hub_services.upgrades`, `firm_hall.back_wall`, `island_briefcase_bay.lighthouse`, `island_food_court`
  pizza / taco / donut / watermelon, `island_pet_park` barkery / paw clinic, `hub_minigames` booths + gavel bonk, ...).
  Full list with centres and overlap areas: `art/audit/zfight_report.txt` (x is offset by the checker: model index × 400).
- Wrong: two colours share one plane over real visible area. Worst: Big Case belt top vs chassis top (~359 sq
  studs, the slats ride on it); firm floor slabs flush with the outer walls (stages 3-6); showcase glass vs its gold
  / trim frame (stages 4-6); the watermelon slice's red / white / rind faces; door steps flush with their base tops in
  9 buildings (License, Upgrades, lighthouse, Barkery, Paw Clinic, Pizza, Donut, Taco, Observatory); booth floors vs
  planks; window glass vs "shine" streaks (13 pairs).
- Fix: per pair, inset the decal-like piece 0.03 (or stand it 0.03 proud); never two colours in one plane.
- Accept: `Blender -b --factory-startup --python tools/blender/overhaul/check_models.py -- zfight` reports **0 pairs**.
- **Done 2026-10-25** (crnuch's side session): 0 pairs, 0 floating pieces; review renders unchanged apart from the
  flicker spots. The checker was made exact first: 10 of the listed pairs were its own rounding, and the exact check
  found 127 real pairs in these models (11 more than listed), all fixed (SESSION_LOG 2026-10-25, "z-fighting sweep").

**M2 · Carry and Speed counters overlap at the Upgrades building** - Observed (Play)
- Where: `Workspace.HubWiring.Counter_Carry` (3667, 155, -1136) and `Counter_Speed` (3664, 155, -1133), 5.7 studs
  apart; owner `tools/zones/BuildHubWiring.lua` (**mr.robe's hub-wiring claim** - coordinate, don't edit around it).
- Wrong: their floating info panels overlap, so SHOES / its price is unreadable; both counters stand across the
  Upgrades door. The new counter model is 4.3 wide, so at this spacing the two new desks would touch.
- Screenshot: `art/audit/P04_carry_speed_counters_overlap.jpg`, camera (3650, 159, -1152) → (3666, 155, -1133).
- Fix: move the two markers onto the building's existing left / right pedestals (≈ 16 studs apart, door clear).
- Accept: same camera, both panels fully readable, nothing in front of the door.

**M3 · Arcade booths face sideways, their blank backs face the plaza** - Observed (Play) + Source
- Where: `HubWiring.FilingFrenzy` / `BriefcaseStack` / `LieDetector` markers (rotY -120 / -133 / -146), moving
  `ArcadePier.Booths.*`; owner BuildHubWiring.lua (mr.robe). New booth model: `hub_minigames.arcade_booth`.
- Wrong: each booth's prompt side points along the ring (dot with the plaza direction ≈ -0.07), so from the plaza path
  you see backs, from the ring road you see sides. The new booths' backs and sides are plain walls, so this gets worse.
- Screenshots: `P07_arcade_booths_from_plaza.jpg` (3556, 163, -1232) → (3524, 157, -1270);
  `P08_arcade_booths_from_road.jpg` (3496, 163, -1306) → (3526, 157, -1266); `B_booth_blank_back_4views.jpg`.
- Fix: turn the three markers so the counters face the plaza approach; optionally carry the side stripes onto the
  back wall of the new booth.
- Accept: dot(prompt direction, plaza direction) > 0.7 for all three; from the plaza path you read all three signs.

**M4 · Plaza centre: the new fountain has no place at runtime** - Observed (Edit vs Play) + Source - **decision**
- Where: `WorldRedesign.CentralHub.Statue_Fountain` is tagged `HubLookalike` (parked at runtime); `HubWiring.TravelPortal`
  sits at the plaza centre (3600, 150, -1200). New models: `island_hub.fountain` + `statue_lawyer`.
- Wrong: the overhaul re-made the fountain for the plaza centre and the hub renders show it there, but players get the
  Travel portal in that spot. The hub renders therefore don't show what players will see.
- Screenshots: `E01_hub_centre_edit.jpg` vs `P01_spawn_view_play.jpg`, both (3600, 160, -1140) → (3600, 156, -1200).
- Fix: crnuch + mr.robe choose: (a) portal stays in the centre, the fountain moves to another open spot (or is
  dropped); or (b) move the TravelPortal marker and un-park the fountain.
- Accept: one centrepiece, the same in renders and in Play.

**M5 · TRAVEL sign unreadable from the spawn** - Observed (Play) + Source; fixed by the new portal *if* installed right
- Where: today's `Hub.TravelPortal.SignPlate.SurfaceGui` is on Face = Back; the marker turns the portal -47°.
- Wrong: the first thing a player sees is a blank black board (P01); from behind, a pylon flag covers the last letter
  (`P02_travel_portal_sign_side.jpg`, (3600, 160, -1255) → (3600, 166, -1200)).
- Fix: at install, the new portal (`portal.py`, approved) has a two-sided spinning sign - put the SurfaceGui on both
  `SignPlate` and `Sign_PlateBack`.
- Accept: TRAVEL readable from the spawn camera above.

### Noticeable polish

**N1 · Same Return Home portal (Ocean Shore rock + palms) on Pet Park, Brainrot and Food Court** - Observed (renders) / Proposed
- Where: `island_kit.rock_portal`, dressed through `island_kit.PORTAL` (Space Base already has its own preset).
- Wrong: grey rock, green moss and palm trees are off-theme on the neon Brainrot island and the candy Food Court, and
  palms are off-theme in Pet Park's temperate park. Screenshot: `B_portals_same_dressing.jpg`.
- Fix: one `IK.PORTAL.update(...)` per island script (Brainrot: dark violet rock + glow crystals + pixel trees; Food
  Court: biscuit / wafer rock + candy canes + lollipops; Pet Park: grey stone + bushes / pines). Re-render the travel
  card if the portal shows in it (`art/travel/travel_*.png` all show the portal).
- Accept: each island's portal uses only that island's palette and plants; `check_models.py` still 0 floating.
- **Done 2026-10-25** (crnuch's side session, Blender only): a `portal_preset()` per island script - Pet Park grey stone + a pine and bushes each side; Brainrot
  dark violet rock, mint moss, magenta / lime flowers, a pixel tree + glow crystals each side; Food Court biscuit rock
  with cream + pink icing, a candy cane + swirl lollipop each side (`PORTAL["side_local"]`: the side plants turn with the
  portal). `check_models` builds all three (0 floating, 0 z-fighting). The travel cards (`art/travel/`) are today's live v2
  renders: re-render them from the overhaul islands at install. Before / afters: `art/overhaul/fixes/audit_N1_*`,
  `audit_*_ground_portal_*`.

**N2 · Egg-field clutter that looks like eggs** - Observed (renders) + Source
- Where: `island_pet_park.floor_bit` (yellow-green tennis balls, r 0.6) and `island_food_court.floor_bit` (purple
  grape spheres, r 0.5, in clusters), scattered across the egg areas.
- Wrong: round, saturated, near egg size, right next to real eggs - they compete with the thing players hunt.
  Screenshot: `B_eggfield_lookalikes.jpg`.
- Fix: inside the egg area use only flat / long clutter (frisbees, bones, paw prints; crumbs, napkins, crackers);
  keep round items to the edges.
- Accept: no round item ≥ 0.8 studs across inside any island's EggSpots area.
- **Done 2026-10-25** (crnuch's side session, Blender only): tennis balls (Pet Park), grapes (Food Court) and Brainrot's eyeballs now only by the floor's rim
  (the v2 frame's `edge`) and never within 3 studs of an egg region (`island_kit.in_egg_area`, reading the island's
  `REGIONS`); flat bones / crackers / glitch tiles there instead; Space Base pebbles stay under 0.8 in egg areas. A geometry
  check over all six islands finds 0 round pieces (sphericity ≥ 0.6) ≥ 0.8 across in any egg region (the pre-fix Pet Park:
  3 tennis balls). The few egg-sized pieces left in egg regions are none of them round (a die or flower head,
  crystals, corals, Briefcase Bay's flower tufts).

**N3 · Hub incubator's halo rings cut through its gold cage** - Observed (renders)
- Where: `hub_services.incubator` (`Incubator_Halo`). Screenshot: `B_incubator_halo_4views.jpg`.
- Fix: halo radius outside the ribs' outer edge + 0.4 (or tuck it between egg and ribs).
- Accept: no ring crosses a rib or arm from any of the four views (and through a full turn if it spins in game).
- **Done 2026-10-25** (crnuch's side session, Blender only): one ring round the egg's waist above the heat lamps' bowls (z 12.8, R 10.4, tilt 2.5),
  one round its crown above the orbs (z 21.3); a BVH test over a full turn: 0 overlaps, smallest gap 0.58 (the old rings
  cut the boiler and a lamp arm in a turn). `audit_N3_incubator_*`.

**N4 · Hub "EGG INCUBATOR" attraction promises an interaction that isn't there** - Source (Studio: 0 prompts) / Proposed
- Where: `WorldRedesign.CentralHub["Egg Incubator"]` (stays at runtime) and its overhaul remake (attraction sign
  `props.attraction_sign`). Players hatch at their own firm's incubators.
- Fix: wayfinding style (wood board) with "HATCH AT YOUR FIRM", or make it a monument without the attraction sign.
- Accept: no attraction-style sign without a prompt behind it.

**N5 · Blank side / back walls on the tall firms and the island shops** - Observed (renders)
- Where: `firm_stages` stage 4 (side windows only in the first bay), stage 5 (4 storeys of plain side + back),
  Food Court eateries (`B_taco_blank_back_4views.jpg`), booths, shop stall back. Screenshots:
  `B_firm4_blank_sides_4views.jpg`, `B_firm5_blank_sides_4views.jpg`.
- Fix: repeat the front's window module along the sides, at least the two bays nearest the street; leave the hall
  join wall plain.
- Accept: from the side at street height every storey shows windows.
- **Done 2026-10-25** (crnuch's side session, Blender only): Glass Office + Corporate HQ: the front's glass + mullion module round both sides on every floor (3 bays
  from the street to the hall join, the HQ atrium split by a transom; opaque `glass_side`, the tone the see-through front
  reads as); the back (hall join) stays plain. Food Court: Pizza Palace / Donut Diner / Burger Barn side windows, Taco Tower
  windows on all four faces. `audit_N5_*`.

**N6 · License building stair cheeks crowded** - Observed (`art/overhaul/hub/license_front.jpg`)
- Where: `hub_license` - a scales statue and a double lamp on each cheek; from the approach the lamp post runs
  through the scales. Fix: move each lamp 3 studs back or to the foot of the stairs. Accept: no overlap from the
  front camera.
- **Done 2026-10-25** (crnuch's side session, Blender only): each double lamp now stands on the ground beside its cheek (x ±25, y -22), clear of the scales from
  `license_front`'s camera; the cheek holds only the scales. `audit_N6_license_*`, `audit_license_front_*`.

**N7 · Fuel depot's hazard band shows only in patches** - Observed (`B_fuel_depot_band_4views.jpg`)
- Where: `island_space_base.fuel_depot`: the band (r 5.03) sits inside the faceted sphere's faces in places.
  Fix: band at r 5.15, or a smoother tank. Accept: a continuous band from all four views.
- **Done 2026-10-25** (crnuch's side session, Blender only): the band's lathe had no centre, so both rings sat at the origin between the tanks; now one
  round each tank, following its curve 0.12 proud, and the tanks are smooth lathes. `audit_N7_*`.

**N8 · Upside-down house: the roof ridge sticks out like a fallen pipe** - Observed (`B_upside_house_ridge_4views.jpg`)
- Where: `island_brainrot.upside_down_house`, `_Ridge` tube 14.4 long vs a shorter roof. Fix: trim it to the roof
  length. Accept: nothing lying on the ground beside the roof.
- **Done 2026-10-25** (crnuch's side session, Blender only): the tube ran ACROSS the roof; it now lies along the ridge, the roof's length. `audit_N8_*`.

**N9 · Counter icons hover above the desks** - Observed + Source (allowed in the attachment check)
- Where: `hub_gameplay.counter` icons (briefcase / boot / diploma). Fine only if the game bobs or spins them; nothing
  does yet. Fix at install: a client bob/spin, or seat them on a small stand. Accept: decided and recorded.

**N10 · Driftwood across the Return Home approach (Ocean Shore)** - Observed (`art/overhaul/islands/ocean_ground_portal.jpg`)
- Where: `island_ocean_shore` driftwood swap on the v2 scatter. Fix: skip driftwood within ~25 studs of
  ReturnHome / Arrival and on paths. Accept: clear approach in the same shot.
- **Done 2026-10-25** (crnuch's side session, Blender only): no driftwood within 25 studs (+ half its length) of the portal and its 30-stud approach, the
  dock landing or the pad, nor within 6 of the landing-to-portal walk; nearest log now 72 studs from the approach.
  `audit_ocean_ground_portal_*`.

**N11 · Corgi statue reads small on its plinth** - Observed (`B_corgi_scale_4views.jpg`) / Proposed
- Where: `island_pet_park.giant_corgi`. Fix: corgi 1.3-1.4× or a smaller plinth, so the landmark reads from the
  spawn. Accept: recognisable from `pet_ground_spawn`'s camera.
- **Done 2026-10-25** (crnuch's side session, Blender only): the dog 1.35x on the same plinth (about 28 studs tall). `audit_N11_*`, `audit_pet_ground_spawn_*`.

### Optional (art suggestions)

- **O1** Giant ice cream balanced on its tip (`B_ice_cream_tip_4views.jpg`): add a melted puddle base for grounding.
- **O2** Giant fries carton is red with yellow marks (`B_fries_carton_4views.jpg`), close to a real fast-food chain's
  look; the game uses fictional brands only. Re-colour or put a gavel / briefcase emblem on it.
- **O3** Pizza Palace's slice sign is paper-thin from the side: give it a crust edge.
- **O4** Soda fountain jets are straight blue rods: bend them into arcs.
- **O5** Cupcake sprinkles are too small to read and look like specks.
- **O6** Shop (today's model, Play): a floating "SHOP / Passes & Boosts" label sits above the marquee that already
  says SHOP (`P03_shop_stall.jpg`, (3556, 158, -1156) → (3528, 160, -1128)).
- **O7** Lucky Briefcase (today's model, Play): the three cases hide the board's "EVERY CASE WINS!"
  (`P06_bigcase_minigames.jpg`, (3662, 162, -1200) → (3705, 156, -1200)). The new model keeps its text clear.
- **O8** HUD (Play): the tutorial STEP banner and the BIG CASES INCOMING banner overlap at the top (`P01`). That's
  inside crnuch's UI v3 claim; noted only.

## Recommended fix order

1. **M4** decide the plaza centrepiece (blocks the hub install).
2. **M2, M3** marker positions / turns (mr.robe's hub wiring) - independent of the models, fixes today's game too.
3. **M1** z-fighting sweep, then keep `-- zfight` at 0 next to the floating-piece check.
4. **N3, N6, N7, N8, N11, N5** model fixes in their builders; re-run both checks and the four-view renders.
5. **N1, N2, N10** island dressing; re-render the islands (and travel cards if the portal changed).
6. Install-time: **M5, N4, N9**. Then the optional list.

Baseline for later fixes: today's renders (`art/overhaul/`), this audit's captures (`art/audit/`), and the review
renders reproducible with `audit_views.py`. Out of scope here: characters, animation, effects, UI previews, phone,
the six islands in Play.
