# Art style: studded brick world (non-negotiable)

**User's call, crnuch, 2026-10-18. Binding for every session.** Supersedes the old CLAUDE.md "Builds" rule
(plain Plastic Parts with `TopSurface = Studs`): a flat stud texture or normal map no longer counts as "studded".

## The directive (crnuch's words, condensed)
The whole map must look like a premium Roblox simulator built from chunky stylized toy bricks with **visible raised
circular studs**. That look is the game's identity.

- **Studs:** real raised 3D studs (not textures) on terrain, roads, rooftops, platforms, decorations and suitable
  architecture. One consistent proportion, spacing, orientation and scale across the whole world, visible at the
  normal gameplay camera distance. No stud clutter on tiny objects.
- **Built efficiently:** reusable studded-brick assets made in Blender (linked instances, generated meshes, modular
  pieces), never every stud modelled by hand.
- **Geometry:** semi-blocky voxel terrain, chunky layered floating-island cliffs, blocky trees with stylized foliage,
  detailed brick-built buildings, angular rocks, geometric landscaping, crisp paths and edges, selective bevels.
- **Polish comes from:** layered brick construction, interesting silhouettes, trims and accents, custom studded props,
  detailed landscaping, material variation, composed scenes, lighting and ambience.
- **Never:** remove the studs or smooth the geometry to look "more professional"; smooth low-poly scenes; generic voxel
  terrain without studs; plain Roblox parts.
- **Performance:** convincing studs without needless rendering cost; lower-detail versions for distant scenery and
  phones; decorative studs separate from gameplay collision.
- **Standard:** every island belongs to the same colorful, detailed, polished, unmistakably studded universe.

## How it maps onto this game
Where we are on 2026-10-18: the map is Plastic Parts with `TopSurface = Studs` (flat texture, 1-stud spacing); the
characters use `MaterialService.BrickStuds` (a normal map, 0.5-stud spacing, docs/CHARACTER_STYLE.md). No raised studs
exist anywhere yet.

Proposed technique (to confirm with a test patch before rolling out):
1. **Stud tiles from Blender** (`tools/blender/stud_tiles.py`): one stud shaped like **Roblox's own stud** (crnuch's call:
   "look like the roblox studs", not round LEGO ones) - a low rounded square with slanted sides, top 0.46 wide, foot
   0.60, 0.10 tall - as real raised geometry (60 tris; 24 in the low version). Studio side-by-side with the flat
   texture: `art/studs/studio_compare_3d_vs_texture.jpg`; baked into tile meshes (e.g. 4x4, 8x8, 16x16 studs) plus edge/corner strips, so a big surface is a
   handful of MeshParts, not thousands of stud instances. LOD variants: full, 8-sided, none.
2. **Collision stays the existing Parts.** Stud tiles sit on top as `CanCollide = false`, `CanQuery = false`,
   `CanTouch = false`, `CastShadow = false` MeshParts in a separate `Studs` folder per area, so gameplay, prompts and
   pathing never change.
3. **Distance / phone LOD:** a client script shows stud tiles only near the camera (radius set in Config, smaller on
   low graphics quality); beyond it the base Part keeps its flat stud look so the far view still reads as studded.
   StreamingEnabled-friendly.
4. **One stud scale for the world: 1-stud spacing** (crnuch's call 2026-10-18), same grid as the old `TopSurface = Studs`
   texture. Characters keep their finer 0.5 studs
   (small objects; the rule says no stud clutter on tiny things).
5. **Uploads by crnuch** (place owner) - meshes uploaded from another account fail to load (CLAUDE.md).
6. **Rollout order:** test patch (one plot + the hub plaza) -> check look + frame time at high and low graphics ->
   hub/plaza/street -> the six zones -> firms (x8 per server, watch the budget) -> props/decor -> far scenery (LOD only).

## Status (2026-10-18): test patch live
- **Live in Studio:** the 20 tile meshes (10 grids 8x8 ... 1x1, `full` 60 tris/stud + `low` 24) uploaded by crnuch
  -> `ReplicatedStorage.Studs.Tiles`; `StarterPlayerScripts.Studs` (src/Studs.client.lua); `Config.Studs`.
  Re-upload kit in ServerStorage: `StudTileData` (the JSON), `StudTileUpload` (tools/zones/BuildStudTiles.lua),
  `StudTileAssets` (ids). New stud shape: re-run stud_tiles.py, refresh StudTileData, delete StudTileAssets, re-run.
- **Tagged `StudTop`:** the hub Plaza's 312 up-facing bricks (Floor + Rim) and Plot1's Base + 4 Paths.
- **How a face is studded:** a stud goes in a cell only if no visible anchored part reaches into the stud's space,
  tested on part BOUNDS kept in a client-side index - not rays or spatial queries, because ~90% of firm parts have
  CanQuery off (rays went straight through them in the first try). Terrain is skipped (its box is the whole map).
  Chunks of 32 studs show within 140 studs of the camera (80 on phones / low graphics, which also get the `low`
  tiles); a part's flat stud texture turns Smooth only while raised studs cover it.
- **Playtested (crnuch's Studio, PC, high detail):** Plaza + a claimed plot with a full firm: studs stop cleanly at
  the firm walls, bushes and paths; 0 parts reach into any of 2,418 plot studs; ~13.7k studs / ~820k tris shown near
  the camera; fps the same with the layer on and off (but Studio was throttled at ~15 fps in the background, so
  that's a weak signal). Shots: `art/studs/playtest_plaza.jpg`, `art/studs/playtest_plot_lawn.jpg`.
- **Not checked yet:** the `low` tiles on a real phone / the Device emulator; frame time with Studio in front; 8 firms.
- **Rollout notes:** tag the 8 plots (any plot can be claimed: Plot1 is tagged, the test ran on Plot2 by a runtime
  tag), then the street, zones, decor. `touched()` loops over every studded face per added part - fine for 300 faces,
  index it by grid before tagging thousands. Watch the triangle count: ~60 tris per stud.
