# Cohesive map and model art pass

**Status (2026-10-16): stage 1 plan approved by crnuch; built: lighting grade, the Arcade Boardwalk (pier booths spread, staggered lamps, lighthouse end platform, BOARDWALK gateway) and the Egg Fountain (SESSION_LOG 2026-10-16). Stage 3 built the same day: Travel Portal frame (banded pylons, flags, bulb-lit TRAVEL sign), the Shop storefront and the Mutation Machine. Stages 4 (LOT SIGNs on empty plots) and 5 (zone statues on every License gate) built too - the stage 1 plan is done; polish / new ideas from here.** Claim each later stage in the session log before editing.

## Goal

Improve the map and major models: the firms, travel portal, shop, Mutation Machine, License Office/shop, and the back-of-map minigame area. The current layouts and concepts work, but the world feels plain and some assets do not match the chunky brick style. Keep the recognizable design while improving composition, landmark readability, and purposeful detail.

Read `CLAUDE.md` and the current `SESSION_LOG.md` first. Check active claims, Blender briefs, references, scripts, and Studio models before choosing a stage.

## Current map observations

From the current Studio overview and closer hub/pier views:

- The orange checker plaza is the dominant hub surface. Several destinations are grouped around its far/right side, leaving a large central area without a strong focal point or clear route between activities.
- The minigame pier is a long wooden deck with evenly spaced lamps and booths grouped toward one side. The adjacent `BigCaseBelt` attraction sits on its own orange pad, so the belt and pier do not yet read as one destination.
- The zone lane is long and straight. Color changes distinguish zones, and large entrance landmarks could make the progression easier to read from a distance.
- Unclaimed firm plots read as bright empty rectangles in the overview. Add only restrained lot framing or entry markers that leave future firm footprints clear.
- The capture looks very bright and saturated, which flattens some depth. Check exposure, Bloom, and color grading before adding more small details.

Use these as starting observations and verify them in a player-level view. Avoid filling empty space with clutter; retain room for movement and sightlines.

## Art direction

Use the established cartoony voxel toy-brick style: chunky block-built forms, studded Plastic surfaces, bold readable silhouettes, and the bright green, orange, warm wood, cream, and purple palette. Add purposeful detail through layered trim, frames, supports, roof shapes, contrasting panels, signage, and a few well-placed props. Build a shared material and proportion language so the areas feel related, while giving each attraction a distinct silhouette and identity.

Keep the current route, zone gates, egg and boss spaces, walkable areas, and major concepts recognizable.

## Scope

- **Firms:** Improve exteriors and visible office details. Keep firm stages distinct and readable as they grow.
- **Travel portal:** Make it a strong, recognizable landmark that reads clearly as the way to travel.
- **Shop:** Give it a clear storefront identity and richer brick-built detail.
- **Mutation Machine:** Make it feel special and exciting while keeping its purpose obvious.

- **License Office/shop:** Make it feel official, fit the zone lane, and make progression easy to understand.
- **Back-of-map minigame area:** Redesign the pier, existing minigames, `BigCaseBelt`, paths, signage, and surrounding scenery as one coherent attraction district.
- **Map:** Give the long lane more visual rhythm and distinct zone landmarks without obscuring the route.

### Mutation presentation (done 2026-10-16)

Built by Codex, finished and playtested by Claude (SESSION_LOG 2026-10-16): the lawyer walks up to the Mutation Machine, fidgets, the machine flashes, then it transforms or runs off. Polish only from here.

## Work in focused stages

Work on **one bounded deliverable at a time**. Plan how the whole hub and minigame district fit together first, then build and check components sequentially. Do not start another stage until the current one is integrated, visually reviewed, and its status is recorded in `SESSION_LOG.md`.

1. **Composition and flow:** Make a simple layout/blockout plan for the plaza and back-of-map attractions. Establish a clear pedestrian route or loop between the pier, minigames, and `BigCaseBelt`; give the district a clear entrance and focal landmark. Balance the hub destinations around the open plaza.
2. **Minigame district:** Build the pier as the shared style anchor. Then remake one minigame at a time, integrating and checking each before moving to the next. Finish the `BigCaseBelt` treatment so it visibly belongs to the same district.
3. **Hub landmarks:** Remodel the travel portal, shop, and Mutation Machine one at a time, checking each in the plaza before starting another.
4. **Firms and plots:** Improve one representative firm stage and its lot entry, review it at player scale, then apply the approved language to the other stages.
5. **License Office and zone entrances:** Improve the office and one zone threshold, then check how the landmarks read along the route before applying any repeated treatment.
6. **Final visual pass:** Tune lighting and color for depth and readability, then check the whole map and affected interactions at desktop and phone scale.

Keep each stage as its own claim/session when practical. The hub and minigame district should share a layout plan, but detailed modeling and integration should happen one component at a time to preserve focus and make visual checks useful.

## Stage 1 - layout plan (2026-10-16, for crnuch's OK)

Overview: `art/map/hub-top-2026-10-16.jpg` (top-down, north = up = +Z). What is there: the octagon checker plaza in
the middle (the Gavel Bonk + Lucky Briefcase tents on its north side, the Mutation Machine SW, the Shop stall SE, the
Travel Portal and the License counter either side of the lane entrance on its south edge); the Big Case court north
of it (orange pad, belt in the middle); the Arcade Pier north of that (a long deck: the three booths huddle at its south end, x +-18.5, z 189-209, and
the rest is empty planks with a row of identical lamps);
the zone lane south; four plots each side, joined to the plaza by orange paths.

1. **One north district, "Arcade Boardwalk"** (plaza → court → pier as one walk):
   - a brick **gateway arch** where the plaza meets the court (name sign + lights), so the district has a front door;
   - the court's centre path continues straight up the pier (it stops at the court edge today);
   - **booths spread along the pier** instead of huddled at its start (room left for the later games), lamps every
     other bay instead of one identical row;
   - a **landmark at the pier's end** you can see from the plaza (a small brick lighthouse or a ferris wheel) - the
     district's focal point;
   - the Big Case court gets the same trim, rail and sign style as the pier, so it reads as part of it.
2. **Plaza focal point:** a centre piece on the empty middle of the octagon (a brick fountain with a giant golden
   gavel / egg on top), with the walking ring around it kept clear; the four plaza destinations (two tents, Machine,
   Shop) face the centre.
3. **Hub landmarks one at a time** (stage 3): Travel Portal, Shop, Mutation Machine - same spots, new Blender builds.
4. **Firms and plots** (stage 4): the plot squares already have orange frames; add only a small lot sign / entry
   marker per empty plot.
5. **Lane** (stage 5): one landmark per zone threshold (in BuildLane), no clutter on the route.
6. **Lighting** first, not last: a quick exposure / Bloom / ColorCorrection check before stage 2, so every model is
   judged in the final light.

Order to build after the OK: 6 (quick) → 1 (pier + booths, then arch, then pier-end landmark) → 2 → 3 → 4 → 5.

## Build and integration requirements

Use Blender for new or remade models, following the repo's Blender and Studio workflows. Keep assets light enough for Roblox, especially on phones; favor bold grouped shapes over tiny individual pieces.

Repo rules that apply to every stage (CLAUDE.md): anything the game loads (meshes, images, animations) must be
uploaded from crnuch's account; Part-built models end with `ServerScriptService.Server.ZFight.fix` (z-fighting); the
firm fronts are code (`Server.FirmStages` FRONTS + FirmFeatures' Area / Floor / ShowcaseSlot parts), not models; the
License Office, zone gates and lane are built by `tools/zones/BuildLane.lua` (change the builder, not the place - a
re-run archives hand edits); the Travel Portal's spot beside the lane entrance is crnuch's call (bug 4). Part budget:
keep a new hub landmark under ~600 parts and a minigame prop under ~150 (phones).

Preserve existing model names, paths, hierarchy, placement, prompts, SurfaceGuis, attributes, tags, and gameplay behavior. Keep interaction areas and collision surfaces clear. Check the repo's “Never rename” and Studio sync rules before replacing anything.

When each stage is finished, update `SESSION_LOG.md` with its files/assets, Studio checks, remaining follow-up, and commit. Keep the current claim accurate and release it before starting the next stage.
