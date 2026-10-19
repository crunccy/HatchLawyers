# UI overhaul (2026-10-18) — reference analysis, audit, plan

crnuch's brief: every interface in the game restyled to the reference recording's design language, using the
glossy PNG icons in `art/icons/hud_navigation_glossy/`. **Copy the look, not the features**: no battle pass, no
event pass, no new menus. Design pass in Figma first (crnuch asked for it), then Studio.

## 1. Reference analysis (Desktop recordings 2026-10-18 7.07.09 / 7.07.21, 9 s + 68 s)
One game ("Halloween Event Pass", "Item Index", "Shop"). What it does, measured off the frames:

| Element | Reference |
| --- | --- |
| Window body | Charcoal `#2E2E34`, an embossed lego-tile pattern at ~8% (not dots), 3-4 px near-black outline, radius ~6 (almost square). The world behind is **blurred** while a window is open. |
| Header | Full-width colour bar per window (Shop = lime `#5BFF3A`→`#2ED61C`, Index = sky `#6CCBFF`→`#3BA4F0` with 2 wide diagonal white shine bands), same tile pattern. Icon on the left (big, glossy, overlaps the bar edge), title in a heavy rounded sans, white, 4-5 px black stroke. |
| Close | Red square (`#E3262B`, darker red inset border), white X with black stroke, sits inside the header's right end. |
| Section titles | `-- PASSES --` yellow `#FFE13A` (or the section's colour) with black stroke, centred. |
| Product cards | Full-bleed saturated gradient per category (money = green, speed = blue, passes = purple→blue / orange), tile pattern, sunburst rays + soft glow behind a big item picture, name/amount white + stroke over the picture. Price = a **wide lime bar** (black outline, Robux glyph + number) with a **purple gift square** beside it. Bigger "deal" cards span 2 columns. |
| Ribbons | Red slanted tags `HOT`, `BEST VALUE`, `POPULAR`, `NEW`, white heavy text, pinned over a card's top-left, rotated ~-6°. |
| Index tiles | Solid rarity colour (grey / green / blue / purple / gold), tile pattern, diagonal gloss; "???" silhouettes; selected = white 3 px border. Progress = black track, lime fill, white "1/8". |
| Side tabs | Coloured stacked tabs outside the window's right edge (World / Limited / Halloween), active one bright, others dimmed. |
| HUD | Left column of **square** tiles (~72 px): gradient fill (rainbow / sky), white inner border + black outer outline, sparkle glints, the PNG icon fills the tile, the label overlaps the tile's bottom edge (white + stroke). Red circle badge (`!` or a count) top-right. Currencies bottom-left: icon + big white number with stroke, **no panel**. Top-centre info line: white + stroke, the value in green. Toggles: green square knob. |
| Motion | Windows pop in (scale ~0.85→1, back-out ~0.25 s) and the blur fades in; tiles grow on hover (~1.06); prices squish on press; the cursor list scrolls smoothly. |

Our `Shared.Skin` (2026-10-10) already follows most of this (built from an earlier recording of the same kind).
Gaps that are still visible in the game (playtest 2026-10-18, 1429x776):
- HUD tiles are wide labelled bars with low-res Creator Store icons (gavel, stall, trophy for Rebirth).
- Money is a dark pill top-centre; the reference has no panel.
- The top hint toast is grey text on a black bar.
- Goals card: UIKit's old purple bar with grey title + grey body text (low contrast).
- The egg bag (`Zones` "Bag", 0/12 bottom-centre) is a brown pill of dark circles — the "egg buttons at the bottom".
- World prompts are all Roblox's default grey ProximityPrompt (15 in Workspace).
- No blur behind open windows.

## 2. Icons (art/icons/hud_navigation_glossy, 1254 px PNGs)
**Uploaded 2026-10-18** as 512 px copies from crnuch's Studio (the place owner; all 12 preload "Success"). Live in
`HudMenu.Icons` (keys below). Re-pointed keys: Gift, Goals, Coin (= Money), Travel, Cart (= Shop), Shop.

| PNG | HudMenu.Icons key | rbxassetid | Used for |
| --- | --- | --- | --- |
| daily-gift | Gift | 71088033804308 | DAILY tile ✓, Daily Rewards header, playtime-gift toast |
| goals | Goals | 80785439188685 | Goals card header ✓ |
| lawyers | Lawyers | 77103986819765 | LAWYERS tile ✓ + panel header, "lawyer waiting" toast |
| shop | Shop, Cart | 124064224555649 | SHOP tile ✓ + Shop header, egg-shop prompts |
| rebirth | Rebirth | 110198988697226 | REBIRTH tile ✓ + the Rebirth (Supreme.client) header |
| travel | Travel | 106112864052258 | TRAVEL tile ✓, travel map header, travel confirm, zone-arrival banner |
| money | Money, Coin | 136795484498427 | coin counter ✓, coin rewards, coin packs, payout pop-ups |
| eggs | Eggs | 124018472915561 | egg bag counter, hatch screen, odds boards, egg prompts |
| merge | Merge | 71805052134273 | Mutation Machine (Merger) header + prompt |
| upgrades | Upgrades | 132845927465164 | office upgrade / Skills / zone Carry + Speed upgrades |
| vip | VIP | 84591968949157 | Shop passes section, VIP floors (Floors) |
| index | Index | 105898194017543 | the LAWYERS panel's collection / odds tab heading (no new Index menu) |
✓ = seen on screen in a playtest 2026-10-18 (HUD tiles, coin counter, Goals header). The panel headers use the same keys but weren't opened.
| settings, codes, achievements, friends | **unused** — the game has no settings, codes, achievements or friends menu, and the brief says no new features. Kept for later. |

Missing subjects (proposed, same glossy style, to make next): Courtroom/gavel (court, Big Case), Minigame/arcade
ticket (Arcade + Gavel Bonk / Lucky Briefcase), Briefcase (Carry upgrade), Lock (locked zones / eggs).

## 3. Audit — every player-facing surface
Layer: **Skin** = built on `Shared.Skin` (reference style) · **UIKit** = old screen auto-restyled by `UISkin.client`
· **Own** = hand-rolled styling. Action: R = rebuild on Skin, S = restyle details, ✓ = already close.
**Done (part 2, 2026-10-18)** = rebuilt on Skin v2, live in Studio, playtested at 1429x776 (phone size by layout maths only -
see SESSION_LOG).

| Surface | Script (StarterPlayerScripts unless noted) | Shown when | Layer | Action |
| --- | --- | --- | --- | --- |
| HUD menu column (Daily, Lawyers, Shop, Rebirth, Travel) | Shared.HudMenu | always | Skin | **Done**: `Skin.hudTile`, 88 px, 2 columns (Daily pink, Lawyers purple, Shop green, Rebirth gold, Travel sky), red badge / "!", DAILY timer as a lime label; all 5 clicked open in a playtest |
| Coin counter | Hud | always | Skin | **Done**: `Skin.counter` bottom-left, Money PNG, no panel, count-up + pop; case results float up above it |
| Hint toast ("A lawyer is waiting…") | Hud | events | Skin | **Done**: `Skin.toast` top-centre (y 62), icon by topic, CAPS words lime, gold STEP n/5 kept |
| Goals card | Goals | always | Skin | **Done**: charcoal card, purple striped header + Goals PNG, white text, real bars (lime, gold + DONE! when finished, n/m on the bar) |
| Daily Rewards window + reward toast | Rewards | join / tile | Skin | S: header PNG, blur (its window isn't a `Skin.window`, so no blur yet) |
| Egg bag counter (0/12) | Zones ("Bag") | always | Skin | **Done**: Skin plate, Eggs PNG, chips Empty / Filled / Golden (sparkle), count (orange when full), chip pops on pickup |
| Egg prompts, odds boards, locked-egg toast | Zones | in zones | Own/World | Zones' notes / "Got an egg!" toasts are `Skin.toast` now (done); R left: custom prompt (flip Style), board restyle |
| Zone arrival / zone name / License gate + upgrade prompts | Zones | entering a zone | Skin/World | Arrival **done**: `Skin.banner` (wood plank, red NOW ENTERING ribbon, Travel PNG, swing-in); R left: gate / upgrade prompts, GOLDEN EGG! + upgrade banners |
| Hatch screen, reveal, title cards, HatchBanner, HatchAnnounce | Eggs, Shared.HatchFx | hatching | Own (cinematic) | S: reveal card + names on Skin type; keep the cinematic |
| Incubator billboards | Eggs | at firm | World | S |
| LAWYERS panel (slots, office card, CLIENTS, BENCH, sell/lock) | Lawyers | tile | Skin | S + fix the short bench grid (open item); its window isn't a `Skin.window` - no blur yet |
| Skills | Skills | office card | Skin | S |
| Mutation Machine (Merger) | Merger | at machine | Skin | S: header PNG |
| Office upgrade celebrations | Shared.UpgradeFx | upgrading | Own | S |
| Shop | Shop | tile / stall | Skin | S: header PNG, red ribbons, gift squares stay off (no gifting feature) |
| Rebirth screen | Supreme | tile | Skin (partial) | R |
| Firm stage-up | FirmStageUp | stage up | UIKit | R |
| Travel map + travel confirm | Travel | tile / portal | Skin | S: header PNG, locked cards |
| Trip animation captions | Shared.TravelFx | travelling | Own | S: destination sign card |
| Courtroom (attend button, evidence, verdict) | Courtroom, AttendCourt | court case | Skin | S |
| Big Case (banner, toast, showdown) | BigCase | event | Own | R |
| Minigames: Gavel Bonk, Lucky Briefcase (prompt, countdown, score, result) | Minigames, MinigameClient.* | hub spots | UIKit/Own | R |
| Arcade booths (Lie Detector, Briefcase Stack, Filing Frenzy) | Arcade, ArcadeClient.Kit + games | pier booths | Skin | S |
| Upstairs rooms panels + toast | Floors | rooms | Skin | S |
| Manager | Manager | manager NPC | Skin | S |
| Name tags (lawyers, clients) | LawyerTags | always | World | ✓ (Steal-a-Brainrot style is the user's call) |
| Desk progress bars | DeskProgress | cases | World | S |
| Boss UI | Bosses | zone bosses | Own | S |
| World signs: lot signs, leaderboards, shop/merger stalls, portal, booths, gates | Workspace SurfaceGuis (~60) | world | World | S: one sign style per kind (CLAUDE.md) |
| ProximityPrompts (15) | Workspace | near objects | Roblox default | R: `Skin.prompt` is built + installed (Hud calls `Skin.installPrompts()`); part 3 sets `Style = Custom` on each prompt and playtests it in the world |
| Old skin inventory | SkinInventory (disabled) | — | — | skip |

Out of scope: Roblox's own core UI (chat, top bar, leaderboard), Freecam.

## 4. Plan
1. **Figma** — https://www.figma.com/design/PtgoaIbriizMlKEDFVxc8Q (crnuch's drafts, Starter plan: 3 pages max,
   and the MCP allows **20 calls a month** for a View seat - used up 2026-10-18, so further Figma work by Claude
   waits for next month or a Full seat). Built:
   - **Foundations**: variables `HAL UI` (40 colours = `Skin.Palette` swatches, surfaces, text, `Config.RarityColors`;
     descriptions name the Luau token), text styles (Title XL/L/M, Label S, Number L/M, Moment XL, Body M/S;
     Nunito stands in for Builder Sans), effect styles (Lip/Ink 4, Shadow/Window, Glow/Gloss), the 12 icons as
     `Icon/<name>` components + the studs tile.
   - **Components**: Button (6 colours x L/M), Close, Badge (Count / Alert), HUD Tile (6 colours, Icon swap, Label,
     badge toggle), Ribbon (red), Progress Bar, Money Counter (no panel, lime number), Section Title, Egg Slot
     (Empty / Filled / Golden), Window (6 header colours, Icon swap, Title), Product Card (4 colours, Picture swap,
     Amount, ribbon toggle), Toast (Plain / Notice), World Prompt (custom ProximityPrompt + hold ring), Arrival
     Banner. Each component's description has its motion spec + the Roblox function it maps to.
   - **Screens**: "HUD — Hub (1280x720)" on a real plaza capture: 2-column glossy tiles, money bottom-left, toast
     top-centre, Goals card, egg bag, prompt.
   - Known file defects (out of calls to fix; build them right in Studio instead): the Goals bars in the screen all
     show the same fill; the egg art doesn't scale with a resized Egg Slot instance; Empty slots should be a solid
     rim, not dashed. Not mocked: Shop open, zone arrival in context, minigame result, phone size.
2. **Icons to Roblox** — done 2026-10-18 (table above).
3. **Skin v2** — done 2026-10-18 (part 2): `Skin.Motion` (one motion table), `Skin.Lime`, `Skin.hudTile`, `Skin.toast`
   (+ `Skin.highlight`), `Skin.counter`, `Skin.banner`, `Skin.prompt` + `Skin.installPrompts`, `Skin.sparkle`,
   `Skin.overlay`, `Skin.icon`, world blur behind every `Skin.window` (`Skin.blurFor`), red default ribbon. Not built:
   `Skin.sign` (world signs, part 3).
4. Rebuild the R rows, then the S rows, screen by screen; each one playtested at desktop + phone size.
5. Retire UIKit / UISkin once nothing relies on them.
