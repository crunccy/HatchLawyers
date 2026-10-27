# Overhaul model exports (2026-10-26)

The MAP MODEL OVERHAUL models as meshes, made by `tools/blender/overhaul/export_models.py` (crnuch: "go export them").

- **`exports/overhaul/<group>_phone<EDITION>.fbx`** (not in git: re-make them with the script; `_FULL` with `full`). Bump
  `EDITION` in export_models.py for every re-export crnuch imports: Studio's importer reuses a same-named file (2026-10-26).: one file per group, each model an
  empty holding its meshes, laid out in a row along X. Groups: `trees shack portal props hub gameplay minigames firms
  hall bay kit pet rot food ocean space` + one per island `island_<hub|bay|pet|rot|food|ocean|space>` (a whole island:
  its terrain / scenery / landmarks collections + the overhaul models, at the island's own origin).
- **`<group>.json` (here)**: the looks the .fbx can't carry. Per model: `origin` (its place in the row, Blender x y z),
  `min` / `max` (size); per mesh: `name`, `fbx_name` (Blender adds `.001` to a repeated name), `look`, `color` (RGB),
  `material` (`Plastic` = studded, `Neon` = glow, `SmoothPlastic` = water / glass / see-through, no studs),
  `transparency`, `reflectance`, `tris`.
- Every mesh has **stud UVs** (1 UV unit = 1 stud, box-projected on each face's main axis; curved faces sit on a plain
  spot between studs), so `MaterialService.BrickStuds` (the Plastic override, StudsPerTile 1) lays the same Grow a
  Garden half-stud grid as on the Parts. No mesh is over 19,500 triangles (a MeshPart takes 20,000).
- Units: 1 Blender metre = 1 stud. After Studio's import a Blender (x, y, z) lands as Roblox (-x, z, y) (the importer
  turns it 180 degrees), so a Blender front (-Y) faces Roblox -Z.

## Installed 2026-10-26 (the phone / tablet budget versions)
- ALL SEVEN ISLANDS are these meshes: `Workspace.WorldRedesign.<CentralHub|BriefcaseBay|PetPark|BrainrotZone|FoodCourt|
  OceanShore|SpaceBase>` (top-level `Island_Top` / `Island_Underside` / `Water` / `Landmarks` / `Vegetation` for
  Ambience). Put in by `tools/zones/SwapOverhaulIslands.lua`: lined up on what was there by `Island_Top`, turned 180
  degrees (portals ~4 studs from each `IslandWiring.<zone>.ReturnHome`); the hub's copies of the pieces HubMap moves
  onto it carry the `HubLookalike` tag (39 models), so HubMap parks them at start as it parked the Part hub's.
- Archives: `ServerStorage.Old_WorldRedesign_Parts` (the Part islands, hub included), `ServerStorage.Old_Overhaul_FullDetail`
  (the first full-detail mesh islands + kit; safe to delete once nobody wants them back).
- Staged, not in the world: `ServerStorage.Overhaul.Models.<group>` (the kit models, each at its true size): firm stages,
  hall pieces, props, trees - each swap needs the names scripts look up.
- Swapped in 2026-10-26 (mr.robe's session, `tools/zones/InstallOverhaulKit.lua`): the portal, shop, belt, the three
  counters, the three booths, the four leaderboards, both minigame spots (old look parts: `ServerStorage.Old_KitParts`).
- **Re-export needed (2026-10-26):** the first exports gave a mesh with several looks ONE colour (the hub's roads all
  grey, its grass all dirt); `by_material` now splits them (`<name>_<look>`). The island JSONs here are the split ones:
  re-export, re-import and re-run ApplyOverhaulLooks + SwapOverhaulIslands before using them.
- Phone / tablet budget: islands 5.2M -> 1.94M triangles (the hub 2.11M -> 0.80M), kit 0.70M -> 0.49M; Workspace went
  from ~140k parts to ~3k. Roblox's own LOD (RenderFidelity Automatic) lowers distant meshes further.

## What the importer does (seen 2026-10-26)
- It picks its own scale per file (2x for an island, up to 200x for a row of props) and turns the file 180 degrees.
- In a row file the models' positions get a different scale from their shapes: scale each model to its own JSON size
  (`ApplyOverhaulLooks.lua` scales the whole file - right for the islands, whose pieces share one origin - then each kit
  model was rescaled on its own, 2026-10-26).
- Precise collision is slow: run the looks script as a background thread (`task.spawn`) and read its progress from an
  attribute, or the MCP call times out while Studio works.

## Import (crnuch's Studio: meshes must be uploaded from the place owner's account)
1. Studio -> Import 3D -> pick `exports/overhaul/<group>.fbx`. Keep the meshes separate (don't merge), anchored.
   It lands in Workspace as a Model named <group>, at its own scale (see above).
2. Serve this folder's JSONs under the imported names (`<group>_phone.json` copies) with `python3 -m http.server 8772`,
   then run `tools/zones/ApplyOverhaulLooks.lua` (Studio MCP execute_luau, Edit mode) with `GROUPS` set: scale back (row
   files per model), looks, phone collision, `Foo.001` names. It runs in the background: read workspace's
   `OverhaulLooks` attribute.
3. Islands: `tools/zones/SwapOverhaulIslands.lua`.
4. Swapping kit models into the game (firm stages, hall, gameplay pieces) is the next install step: per model, by
   the names scripts look up (`Firm`, `Sign`, `Trigger`, `FloatRing1-3` ...), one at a time.

Re-export: `Blender -b --factory-startup --python tools/blender/overhaul/export_models.py -- models [<group> ...]`
or `-- island <name>` (one island per run).
