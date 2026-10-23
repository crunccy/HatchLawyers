# UI v3 — the reference-video style (2026-10-23)

**crnuch's call (2026-10-23):** every button and pop-up in the game gets "exactly that sort of artistic style" as the
reference video (a 62 s portrait clip of a Roblox simulator shop, `~/Downloads/v15025gf0000dbc1psfog65g6ag34m9g.MP4`,
creator @palm_dev — the creator's captions and talking head are NOT part of the style; the game UI shown is).
Stills: `references/ui-v3/ref_*.jpg` (timestamps in the file names). Supersedes the v2 look in docs/UI_OVERHAUL.md
where they disagree; the audit table there is still the list of screens.

Also crnuch's calls the same day: **the fonts are the video UI's fonts, game-wide** ("none of your default AI fonts
anymore"), **no gold hover ring**, and **no gray window backgrounds** (deep purple instead).

## 1. Fonts — one family

The video's UI is one geometric typeface with flat (not rounded) stroke ends: **Gotham Black** for everything big —
window titles ("Shop", "MY TRAILS"), card titles ("STARTER PACK", "2x Speed Forever"), tags ("BEST VALUE!",
"+66% more"), tab labels ("PACKS"), amounts ("x10k", "+$100,000 Cash"), prices — and the same family in **Bold** for small
print ("Buy slingshot sets!", "Equipped: BREEZE"). White text, thick dark outline; coloured words (yellow titles,
lime numbers) keep the outline.

| Role | Font | Where it's set |
| --- | --- | --- |
| Titles, buttons, numbers, HUD, big moments | `Enum.Font.GothamBlack` | `Shared.UIFonts.Primary/Title`, `Skin.Fonts.Title/Number/Heavy` |
| Descriptions, small print | `Enum.Font.GothamBold` | `Shared.UIFonts.Body`, `Skin.Fonts.Body` |

`StarterPlayerScripts.Fonts` converts any other font a script or model still sets (screens, name tags, world signs)
as it appears: display fonts and heavy weights -> Black, text fonts -> Bold. Opt out with attribute `KeepFont`.
Fredoka One, Luckiest Guy and Builder Sans are retired. (Gotham is drawn as Montserrat by Roblox now; same shapes.)

## 2. Look, element by element (what the stills show)

| Element | Reference | Skin v3 |
| --- | --- | --- |
| Window body | plain dark charcoal, no pattern, thick ink outline | `Skin.Panel` **deep purple 3A1F6B** (crnuch's call 2026-10-23: no gray), no pattern |
| Header | per-screen colour (Shop yellow-orange, Upgrades purple), visible stud bricks, 3-4 wide diagonal light bands, white title left, red square X right | `Skin.stripes` on the header; icon bigger than the header, poking out of its top-left corner, tilted |
| Card | saturated colour lit from the top-left, white sunburst behind the picture, soft diagonal bands, studs, light inner bevel | brighter 60° gradient, rays visible, `Skin.stripes`, twinkling sparkles |
| Hero picture | big, outlined, overlapping the card edge | `Skin.breathe` |
| Reward tiles | small squares in their own colour, picture + "x10k" on the foot | `Skin.tile` |
| Buy button | lime/green with diagonal bands, currency icon + number | every `Skin.button` has bands; `Glint = true` on the one buy/claim per card |
| Value tag | red, tilted, straddling the card's top edge: "+66% more", "BEST VALUE!" | `Skin.tag` (and `Skin.ribbon` for corner ribbons) |
| Section label | small white "~Cash~" between groups | `Skin.section` |
| Side tabs | coloured blocks beside the window (PACKS orange, PASSES purple, UPGRADES blue, CURRENCY green), the current one bright, the rest dimmed | `Skin.sideTab` (`Color`), `Skin.selectTab` |
| Announcement | sky-blue pill, diagonal bands, white text: "ENZO HIT A THUNDER SHOT!" | `Skin.toast` is that pill now |
| Unavailable | grey "LOCKED" bar; red text "You need more Wins." | `Button.setState("disabled", reason)` |

Grey is only for locked / owned / unavailable. Everything else carries a colour.

## 3. Motion (from frame-difference maps over the still-camera stretches, not guessed)

Measured by diffing consecutive frames where the creator's camera wasn't moving (1.5-3.8 s, 4.1-5.5, 7.1-8.0,
9.6-13.3, 24.6-26.0, 29.3-31.2, 40.5-42.7 s):

| What moves | How | Skin v3 |
| --- | --- | --- |
| Hero pictures (gift box, trophy pile) | slow tilt + small swell, continuous | `Skin.breathe(gui, 5, 0.45)` |
| Sunburst behind them | turns slowly | `Skin.spin(rays, 10)` (cards spin by default) |
| Sparkle stars on cards | twinkle (grow, turn, shrink) at random | `Skin.sparkle` x2 per card |
| Buy buttons | a "//" glint (wide + thin bar) sweeps across every few seconds | `Skin.glint` |
| Pressing a buy bar | the bar squishes, a white ring spreads from the press point, a few dots fly out | `Skin.ripple` in `Skin.pressable` |
| Hover | the button grows (the video also shows a gold outline: **not used**, crnuch's call) | `Skin.pressable` |
| Announcement pill | drops in, holds, slides up and fades | `Skin.toast` |
| Window | pops in | `Skin.window` open (Back ease) |

Everything that loops runs from one RenderStepped loop and skips screens that are closed.

## 4. Rollout

1. **Skin v3 + fonts** (2026-10-23): every `Skin` screen (Shop, Travel, Floors, Arcade kit, HUD tiles, toasts,
   banners, prompts, counters) and every font in the game change at once.
2. **Shop rebuilt to the reference** (tiers with "+N% more" tags, reward tiles, gold header, coloured tabs).
3. **The older screens** (LAWYERS, Daily Rewards, Rebirth, Firm stage-up, Big Case, Minigames, Skills, Manager,
   Courtroom, Mutation Machine) move onto Skin v3 one at a time — each its own session, the screen list and status in
   docs/UI_OVERHAUL.md §3. Their buttons are UIKit-skinned until then (UIKit gets the v3 bands + fonts meanwhile).

Monetization ideas from the same video (not visual; each needs its own call): a cheap one-time Starter Pack, a very
cheap 2x pass, prompting the smallest cash pack that covers a shortfall when you can't afford something, and putting
paid items on the map and the HUD as well as in the Shop.
