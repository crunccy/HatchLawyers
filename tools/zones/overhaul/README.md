# Overhaul model exports (2026-10-26)

The MAP MODEL OVERHAUL models as meshes, made by `tools/blender/overhaul/export_models.py` (crnuch: "go export them").

- **`exports/overhaul/<group>.fbx`** (not in git: re-make them with the script): one file per group, each model an
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
- Units: 1 Blender metre = 1 stud. The FBX axis change makes Blender (x, y, z) -> Roblox (x, z, -y).

## Import (crnuch's Studio: meshes must be uploaded from the place owner's account)
1. Studio -> Import 3D -> pick `exports/overhaul/<group>.fbx`. Keep the meshes separate (don't merge), anchored.
   Check one model's size against its `min` / `max` in the JSON (studs); if it came in 100x off, set the importer's
   unit to metres / studs and import again.
2. Run `tools/zones/ApplyOverhaulLooks.lua` (Studio MCP execute_luau in Edit mode) with `LOOKS` = this group's JSON and
   `ROOT` = the imported model: it sets Color / Material / Transparency / Reflectance, anchors, renames `Foo.001`.
3. Swapping models into the game (firm stages, hub buildings, islands) is the install step after that: per model, by
   the names scripts look up (`Firm`, `Sign`, `Trigger`, `FloatRing1-3` ...), one at a time.

Re-export: `Blender -b --factory-startup --python tools/blender/overhaul/export_models.py -- models [<group> ...]`
or `-- island <name>` (one island per run).
