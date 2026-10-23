# Promo Admin / Creator Toolkit

Promo Admin is a limited recording toolkit for one explicitly allowlisted Roblox UserId. It is separate from the existing full-admin commands. Promo users receive a fresh in-memory profile: their saved profile is not read or written, autosaves and leaderboard writes are skipped, and shop purchase prompts are disabled in the client. This lets the creator play and earn temporary resources in a normal server without persisting test progress to their account.

## Enable in Studio

The repository's `studio/` directory is a read-only snapshot. Apply these working copies to the matching live Studio objects; do not hand-edit the snapshot.

| Repository file | Studio location / class |
| --- | --- |
| `src/PromoCharacter.lua` | `ServerScriptService.PromoCharacter` — ModuleScript |
| `src/PromoPolicy.lua` | `ServerScriptService.PromoPolicy` — ModuleScript |
| `src/AdminCommands.server.lua` | `ServerScriptService.AdminCommands` — Script |
| `src/PlayerData.lua` | `ServerScriptService.Server.PlayerData` — ModuleScript |
| `src/LeaderboardService.lua` | `ServerScriptService.Server.LeaderboardService` — ModuleScript |
| `src/ShopService.lua` | `ServerScriptService.Server.ShopService` — ModuleScript |
| `src/PromoAdmin.client.lua` | `StarterPlayer.StarterPlayerScripts.PromoAdmin` — LocalScript |
| `src/Shop.client.lua` | `StarterPlayer.StarterPlayerScripts.Shop` — LocalScript |

Keep `PromoPolicy` under ServerScriptService so clients cannot read or change the allowlist. The allowlisted accounts are `maddrummerman25` (`468598163`) and the owner (`2234491534`). Both receive disposable promo profiles while allowlisted; remove the owner entry to resume normal saved progression. The place owner retains control by editing this one server-only table.

After installing, re-export the Studio snapshot using the existing `tools/studio_sync/ExportSnapshot.lua` workflow and review the exported files against these sources. Test in a private Studio session before publishing.

## Commands

Commands work with `/` or `;`. Type `/promo help` in chat for the in-game summary.

| Command | Effect |
| --- | --- |
| `/promo fly on` / `off` / `toggle` | Fly your character using WASD and E/Q for up/down (keyboard). Server limits speed to 60 studs/second; no noclip. Free camera holds the character still while flying. |
| `/promo invisible on` / `off` / `toggle` | Hide your character, accessories, name tag and attached effects for everyone; restore their previous settings when disabled. `/promo invis` is an alias. Collision and damage remain unchanged. |
| `/promo reset` | Stop flight, restore visibility, restore game GUI and exit free camera. Does not clear temporary resources. |
| `/promo help` | Show the promo command summary. |
| `/promo resources` | Set temporary coins and guaranteed-rare egg tokens to a very large filming supply. |
| `/promo hatch <rarity> [egg] [golden]` | Play the normal hatch sequence with a random lawyer of that rarity from the selected egg. Supports every rarity in Config. |
| `/promo lawyer <id> [golden]` | Preview a specific existing lawyer in the hatch sequence. Use `/promo lawyers` to find IDs. |
| `/promo eggs [egg] [count] [golden]` | Put 1–30 temporary eggs in the player's carried-egg list; defaults to 30 Briefcase Eggs. These hatch using normal game odds and grant only to the temporary profile. |
| `/promo lawyers [search]` | List up to 20 lawyer IDs, optionally filtered by name or ID. |
| `/promo firm max` | Rebuild this player's temporary firm at the maximum size and Supreme Tower stage, with max-level offices. |
| `/promo worlds` | List travel IDs. |
| `/promo world <id|home>` | Travel to a world or return to the temporary firm. |
| `/promo gui hide` / `show` / `toggle` | Hide or restore local game ScreenGuis for recording. Roblox CoreGui is unaffected. |
| `/promo cam on` / `off` / `toggle` | Enable or restore the local free camera. Move with WASD, rise/fall with E/Q, hold Shift for faster motion, use the mouse to look, and use `+`/`-` to change speed. |

The existing `/hatch` admin command remains a non-saving hatch preview for full admins and Studio testing. Promo users can use `/promo hatch` or `/promo lawyer` without receiving full-admin permissions.

## Revoke access

Remove `[468598163] = true` from `ALLOWED_USER_IDS` in `src/PromoPolicy.lua`, install the updated ModuleScript, and restart live servers. The promo profile is selected on join, so removing the ID prevents new sessions from entering the sandbox; restarting servers also ends any already-running promo session. No saved profile migration or cleanup is needed.

## Safety boundaries

- The server checks UserId against an explicit allowlist; clients cannot grant themselves promo mode or invoke server mutations through `PromoControl`.
- Promo access is not added to the legacy full-admin `ADMINS` table.
- Promo profiles start from a fresh template and never acquire, save, or release the player's persistent DataStore record.
- Synthetic leaderboard scores are not written globally.
- Developer product receipts remain unprocessed during promo sessions, and the shop UI does not open purchase prompts.
- GUI hiding and camera movement are local presentation controls only.

## Access fix — 2026-10-23

The original dispatcher required full-admin permission before reaching `/promo`, accidentally blocking the allowlisted advertiser. It now checks promo authorization separately; all other commands retain their existing full-admin gate. Use `/promo resources`, not `/coins`.

Studio inspection on 2026-10-23 found no PromoPolicy or PromoAdmin client, and the installed AdminCommands had no promo handler. PR #9 is still pending; changing the GitHub allowlist alone does not install or publish the toolkit. Merge current Studio changes into each working copy before installing the complete dependency set above. Preserve the Studio-only `/island` and `/islands` commands added since the original snapshot. Do not install just AdminCommands: PlayerData isolation and the leaderboard/shop guards are required together. Rejoin a fresh server after installation and publication by the owner.

Flight input is a bounded Vector3, accepted only for an already-authorized flying promo session, rate-limited on the server, with a 0.3-second input timeout. The server owns flight physics. Flight and invisibility reset on character removal; off/reset restores prior character properties. Client input never enables flight or changes the allowlist. These movement controls currently require a keyboard.
