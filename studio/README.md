# studio/ — snapshot of the live place (read-only)

Every script in the Team Create place "Hatch a Lawyer & Get Rich!" (placeId 94345095795403), exported as-is.
`MANIFEST.json` lists each file's Studio path, class, `Enabled` and line count.

- **Last export:** 2026-10-12 by mr.robe's local session (77 scripts).
- **Don't edit these files.** They show what is live. Work in `src/` (or in Studio directly), then re-export.
- **Re-export:** run `tools/studio_sync/receive_snapshot.ps1 -Root <repo>/studio` (Windows; on a Mac any small HTTP
  server that writes POST bodies to `studio/<path>` works), then run `tools/studio_sync/ExportSnapshot.lua` in Studio's
  Edit mode (Studio MCP `execute_luau` or the command bar). Delete `studio/` first if scripts were removed or renamed.
- Rules for moving changes between `studio/`, `src/` and Studio: CLAUDE.md → "Studio ↔ repo".
