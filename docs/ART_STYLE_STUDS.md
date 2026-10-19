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

## How it maps onto this game (proposed, not built yet)
Where we are on 2026-10-18: the map is Plastic Parts with `TopSurface = Studs` (flat texture, 1-stud spacing); the
characters use `MaterialService.BrickStuds` (a normal map, 0.5-stud spacing, docs/CHARACTER_STYLE.md). No raised studs
exist anywhere yet.

Proposed technique (to confirm with a test patch before rolling out):
1. **Stud tiles from Blender** (`tools/blender/stud_tiles.py`, new): one stud = a low cylinder with a small bevel,
   ~12-16 sides; baked into tile meshes (e.g. 4x4, 8x8, 16x16 studs) plus edge/corner strips, so a big surface is a
   handful of MeshParts, not thousands of stud instances. LOD variants: full, 8-sided, none.
2. **Collision stays the existing Parts.** Stud tiles sit on top as `CanCollide = false`, `CanQuery = false`,
   `CanTouch = false`, `CastShadow = false` MeshParts in a separate `Studs` folder per area, so gameplay, prompts and
   pathing never change.
3. **Distance / phone LOD:** a client script shows stud tiles only near the camera (radius set in Config, smaller on
   low graphics quality); beyond it the base Part keeps its flat stud look so the far view still reads as studded.
   StreamingEnabled-friendly.
4. **One stud scale for the world: 1-stud spacing** (crnuch's call 2026-10-18), same grid as the old `TopSurface = Studs`
   texture. Stud = 0.6 wide, 0.2 tall (LEGO proportions on a 1-stud pitch). Characters keep their finer 0.5 studs
   (small objects; the rule says no stud clutter on tiny things).
5. **Uploads by crnuch** (place owner) - meshes uploaded from another account fail to load (CLAUDE.md).
6. **Rollout order:** test patch (one plot + the hub plaza) -> check look + frame time at high and low graphics ->
   hub/plaza/street -> the six zones -> firms (x8 per server, watch the budget) -> props/decor -> far scenery (LOD only).
