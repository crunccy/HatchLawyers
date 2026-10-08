# Blender remake brief

Goal: replace the current placeholder models with nicer cartoony ones modeled in Blender, matching the
reference screenshots in `references/` (user's local folder — not in this repo yet) (ref1-roll-path, ref2-item-shop, ref3-plots-hud).

## The look (from the references)
- **Chunky voxel / toy-brick style.** Everything is built from stacked blocks with slightly rounded (beveled)
  edges and a subtle stud/tile pattern on flat surfaces. Not smooth realistic shapes.
- **Big, readable silhouettes**, oversized heads on characters, expressive cartoon faces (big eyes, eyebrows,
  grin) — like the monkeys in the references.
- **Bright saturated flat colors** — use the palette in [../CLAUDE.md](../CLAUDE.md). Wood is warm orange-brown, leaves lime green,
  paths orange. Minimal texture detail; color does the work.
- Low poly: these get copied per player (×8 per server) and must run on phones.
  Targets: character ≤ 3k tris, egg machine ≤ 5k, palm ≤ 1.5k, crate ≤ 300, desk ≤ 1.5k.

## Models to remake (priority order)
1. **Lawyer / client character** (most visible). Cartoon office worker with a big head, voxel hair,
   expressive face, simple suit. ~5.5 studs tall to match the current NPC.
2. **Egg machine** (hub): giant spotted egg on a chunky wooden stand with a cradle, slanted green "ROLL" sign
   board in a wood frame, odds board on a post, a couple of crates — ref1/ref2's Roll machine vibe.
3. **Voxel palm tree** — stacked-block trunk, blocky leaf fronds, coconuts (ref2).
4. **Props:** wooden crates (with plank/frame detail), a leafy bush, wood fence segment (ref1).
5. **Desk tiers:** Folding Table → Oak Desk → Executive Desk → Mahogany Partner's Desk, each visibly fancier.
6. Later: the courtroom pieces (judge bench, oversized gavel), grey block cliffs with mossy tops (ref1/ref3).

## Hard constraints so the game keeps working (do not skip)
- **Characters stay split into separate meshes with these exact names:** `Head`, `Torso`, `Left Arm`,
  `Right Arm`, `Left Leg`, `Right Leg` (+ an invisible `HumanoidRootPart` box at the torso as the model pivot/
  PrimaryPart). `SkinLook` recolors Torso/arms (suit) and legs (pants) and attaches tie/hat to Torso/Head;
  `CaseService` puts nameplates on `Head` and stands NPCs by their feet. Keep the character facing −Z.
  Suit/pants parts should be colorable (single material, white/neutral base so Roblox `Color` tints them).
- Egg machine must keep: model named `EggMachine` with children `Egg` (model, PrimaryPart `Shell`),
  `StandTop` (holds the `RollPrompt` ProximityPrompt), `Sign` (green face with the SurfaceGui text),
  `OddsBoard` (front face for the odds SurfaceGui). Text stays as Roblox SurfaceGuis, not baked into meshes.
- Firm template names must not change (see [../CLAUDE.md](../CLAUDE.md) "Never rename").
- Scale: 1 Blender meter = 1 Roblox stud when exporting (set unit scale so sizes match the current parts).
- Apply transforms, sensible origins (bottom-center for props, torso-center for characters).

## Pipeline
1. Model in Blender via blender-mcp, one object per part, named as above.
2. Export **.fbx** per model into `exports/` in the local HatchLawyers folder.
3. **The user imports** in Studio (Avatar/3D Importer → File → Import 3D), since Studio's MCP can't upload
   local files. Then Claude swaps the parts into the templates in Studio, keeping names/attributes/prompts,
   and playtests.
4. Do one model end-to-end first (the lawyer), confirm it works in-game, then batch the rest.
