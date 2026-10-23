# Mobile presentation study — V21

2026-10-23. This focused follow-up partially closes the mobile-footage gap recorded in batches 3 and 4. It does not validate our game's touch usability.

## Source and evidence

[Grow a garden mobile gameplay — VelocityGrid](https://www.youtube.com/watch?v=ELNf6V_wsuY), channel handle `@AlexanderR-s8k`, runtime 10:19, listed one year old when inspected. This is older presentation evidence, not a current-build claim or popularity benchmark. Selected frames/playback were inspected; no direct audio listening or complete viewing.

The footage visibly includes a left movement joystick and right jump control. That supports treating it as a touch-control presentation reference. It does not establish the physical device model, touch target dimensions, finger trajectories, latency or whether the recording was made on physical hardware versus an emulator.

## Timestamped observations

| Timestamp | Visible evidence | Design implication for review |
| --- | --- | --- |
| [1:01](https://www.youtube.com/watch?v=ELNf6V_wsuY&t=61s) | Three large top navigation buttons: SEEDS, GARDEN, SELL. Movement joystick lower left; jump lower right. A dense bottom hotbar contains many small text labels. | Clear major destinations can coexist with crowded secondary controls. Preserve legible main actions and explicitly budget the lower corners. |
| [3:05](https://www.youtube.com/watch?v=ELNf6V_wsuY&t=185s) | Success message near upper center; hand-shaped Collect prompt near an outlined crop; selected hotbar slot has a blue border. Dense orange/red plants occupy much of the view. | Combine local target feedback, selected-tool state and a concise result. Test the same UI against busy scenery, not just empty grass. |
| [5:09](https://www.youtube.com/watch?v=ELNf6V_wsuY&t=309s) | No fruits to harvest! is displayed in the same general upper-center feedback area. The crop and persistent navigation remain visible. | Empty/unavailable outcomes need a short explanation in a predictable position, without becoming a full modal. |
| [7:13](https://www.youtube.com/watch?v=ELNf6V_wsuY&t=433s) | GEAR, COSMETICS and pet-egg stalls use related wooden frames with different signs and awning colors. Gear NPC dialogue options appear close to the character. | Repeated structural families support a coherent market/pier district. Interaction choices still need readable contrast and large enough targets on our own screens. |
| [7:18](https://www.youtube.com/watch?v=ELNf6V_wsuY&t=438s) | Three repeated Please wait before trying again! lines stack above a success message while a local Collect prompt is also present. | Repeated status feedback can consume the same space as meaningful information. Coalesce duplicate cooldown messages. |

These are frame observations. The quick change between the last two samples does not establish the intervening gesture sequence or exact message lifetimes.

## Concrete applications to Hatch a Lawyer

### A. Reserve space for touch controls

Keep existing HudMenu ownership. Inspect the column with the actual movement/jump controls visible and with phone safe-area insets applied. A panel that fits the screen can still conflict with the player's thumb or hide the jump region.

For an active boss encounter, keep the view of the player, warning edge and available escape route clear. Avoid placing a reward banner over the warning merely because that position is empty on desktop.

For a modal collection screen, define whether movement remains active and keep that behavior consistent with the current game. Do not silently change gameplay input handling as part of decoration.

### B. Make selection visible in the world and UI

For an existing place/swap action, show the selected lawyer consistently in the panel and highlight the eligible destination through the game's existing interaction system. State should persist independently of transient sparkles. Use an outline/label or existing selected treatment rather than relying only on rarity color.

Do not add a new interaction mode simply to reproduce the source game. This is guidance for the modes Hatch a Lawyer already has.

### C. Consolidate feedback

Recommended presentation policy for review:

- Repeating the same unavailable-action reason updates one existing message instead of creating another line.
- A successful action replaces its pending/cooldown message when appropriate.
- Different important outcomes can queue, but routine feedback should not displace the current task.
- Message fade must not remove the explanation before it can be read.
- An error should point back to the relevant control and preserve the player's selection where possible.

These are proposed behaviors, not claims about our current code. Preserve authoritative server results; suppressing duplicate display must not suppress required game logic.

### D. Use repeated stall forms to unify the pier

The 7:13 sample gives a concrete alternate to random small props: a repeatable wooden stall frame with shared proportions, a distinct awning/sign per activity, and a clear interaction side. Adapt this to the approved BigCaseBelt/minigame district using studded Plastic and original legal motifs. Keep the belt and minigame footprints intact; author new pieces in Blender.

## Suggested implementation review sheet

Capture each state on a small landscape viewport and a wider tablet/desktop viewport:

1. Walking with HUD and touch controls.
2. Standing at an interaction with the prompt visible.
3. Selecting a lawyer and inspecting its actions.
4. Unavailable action with one clear explanation.
5. Rapid repeated input while a response is pending.
6. Boss warning with a routine notification arriving.
7. Returning from a special hatch with camera/UI restored.

This is a proposed review sheet, not a playtest performed by the researcher. Device dimensions and text sizing should be chosen from supported targets, then measured in Studio/device captures.

## Engine reference and remaining gaps

The official [ScreenGui reference](https://create.roblox.com/docs/reference/engine/classes/ScreenGui) lists ScreenInsets, ClipToDeviceSafeArea, SafeAreaCompatibility and IgnoreGuiInset. Inspect these deliberately when reviewing our screens; do not assume a single scaling multiplier handles all device edges.

This study supplies visible touch controls and mobile-style feedback examples. It does **not** close controller navigation, current PS99 mobile behavior, physical-device ergonomics, direct audio audition, or continuous boss-warning timing gaps. Earlier batch statements about unverified mobile evidence describe their own samples and remain valid.
