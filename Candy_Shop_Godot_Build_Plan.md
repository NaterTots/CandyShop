# Candy Shop — Godot Build Plan

## 1. Assignment and intended result

Build a cohesive, playable first-person 3D candy-organizing prototype. The player restores one colorful candy shop by collecting scattered sweets and putting them into displays. The entire shop is accessible from the beginning. There are no stages, customers, timers, scores, penalties, or business-management systems.

Deliver a small playable milestone first, then expand and polish the same project. Use this document as the implementation specification and agent handoff. Do not expand scope to fill perceived gaps. Make routine implementation decisions independently, document changes, and preserve the rules below.

Working title: **Candy Shop**. Naming and commercial branding are outside this assignment.

## 2. Confirmed requirements versus implementation defaults

Confirmed by the owner:

- First-person 3D; Windows mouse/keyboard and controller support, including Steam Deck on SteamOS.
- Bright, cozy, stylized visuals with deliberately saturated candy colors.
- One room, fully accessible at the start; locked front entrance; a long rear counter with a walkable employee side.
- A handful of reusable candy models with visually distinct variants. Lollipops and double-twist wrapped candies are required.
- Approximately 300–500 pieces, favoring the lower end.
- Each variant belongs together, but the player chooses which eligible destination holds it. No preset flavor labels or ordering puzzle.
- A mix of display forms: bins/jars, shelves, and stands.
- Mixed inventory starting at about five items, a visible count, and a floating preview of the most recently collected item away from the center of the screen.
- One piece deposited per click. Mistakes are allowed and reversible.
- Stationary scattered objects, pickup animations, and deterministic display slots; no physical piles or throwing simulation.
- Automatic progression upgrades; relaxed play; a small completion celebration and restart option.
- Autosave/resume, settings, and help finding the last pieces.
- A cohesive playable prototype; suitable third-party assets are allowed.

Defaults selected to make the specification executable, rather than additional owner requirements:

- Typed GDScript, Godot 4 stable standard edition, Compatibility renderer initially.
- 320 pieces, 16 variants, 16 destinations; four families with four variants each, 20 copies per variant.
- Chocolate bars and boxed sweets are the other two base models.
- Inventory selection, reversible slot removal, and a safe drop action as specified below.
- Dimensions, controls, upgrade thresholds, and sample flavors below are initial tuning values.

## 3. Technology and delivery

Use **typed GDScript** to keep tooling and export setup small. Use one pinned stable Godot 4 version throughout the project; resolve and record the actual installed version before writing code. The official download page checked during planning on 2026-09-11 reports 4.7.2. If unavailable in the execution environment, use an available stable Godot 4 release, record it, and verify its APIs rather than mixing versions. Match export templates to the chosen editor.

Start with the Compatibility renderer and simple materials. Completion feedback must work through emission, color, and particles without depending on a postprocessing bloom effect. Avoid new plugins unless a concrete requirement needs one.

Prepare Windows x86_64 and native Linux x86_64 export presets. Native Linux is the initial SteamOS route; Windows under Proton is optional additional validation. No Steamworks integration, store publication, or Deck Verified claim is required. Provide instructions for adding the Linux build as a non-Steam game and using a standard gamepad layout. Actual Steam Deck testing must be reported separately from desktop gamepad testing.

## 4. Core game loop

1. Walk around the shop and aim at a piece of candy.
2. Pick up one piece into the mixed inventory if space is available.
3. Select the piece to place; the newest pickup is selected automatically.
4. Aim at a display belonging to that candy family and deposit one piece.
5. A full display containing only one variant becomes visibly complete.
6. Take misplaced pieces back out and reorganize them whenever desired.
7. Complete all displays to finish the shop.

Floor clutter disappears permanently as candy moves into displays. Keep the sensory reward focused on pickup, placement, neat visible filling, and completion.

## 5. Candy catalog and counts

| Family | Shared model | Four variants | Destination form | Pieces |
| --- | --- | --- | --- | ---: |
| Lollipops | Round candy head and stick | Strawberry, lemon, blueberry, grape | Four wide open jars/stands | 80 |
| Wrapped sweets | Rounded center and twist at both ends | Cherry, orange, apple, blackberry | Four open candy bins | 80 |
| Chocolate bars | Wrapped rectangular bar | Milk, dark, mint, caramel | Four shelf bays with stack slots | 80 |
| Boxed sweets | Small rectangular carton | Peach rings, sour watermelon, rainbow bites, berry chews | Four shelf bays with carton slots | 80 |
| **Total** | **Four base models** | **16 variants** | **16 destinations × 20 slots** | **320** |

All four variants in a family share geometry. Use color, wrapper patterns, and a simple icon together so identity does not depend solely on color. Within each family, ensure variants are recognizable at pickup distance on a 1280×800 screen. Keep branded real-world packaging out of the asset set.

Candy is deliberately oversized for easy targeting. Use a small sample of each family to choose readable scale before populating the whole room. Reuse the same model/material definitions for scattered, carried, and stored candy.

## 6. Destination rules — authoritative

Each destination has a fixed **family**, capacity, and ordered list of occupied slots. It does **not** have a fixed variant, and the first deposit does **not** lock it to a variant.

- Any lollipop variant can go into any of the four lollipop destinations.
- Same-family mixtures are allowed, including filling all 20 slots with a mixture.
- A destination is complete exactly when its count equals capacity and every stored item has the same variant ID.
- Wrong-family placement is rejected with gentle feedback: for example, “Lollipops go here.” It does not consume or move the item. This is a structural restriction; wrong flavors within a family remain allowed.
- A full destination rejects additional deposits; removal remains available.
- Empty or partially filled destinations are incomplete. A full mixed destination is also incomplete.
- Completed destinations remain editable. Removing an item immediately removes their completed appearance and updates current progress.
- There are exactly 20 items of every variant. Combined with conservation of items, this ensures a finished game has one complete destination per variant without needing a separate flavor-assignment mechanism.
- Family signage may use oversized candy sculptures or icons. Do not label an empty destination “strawberry,” precolor it by flavor, or highlight a unique correct flavor destination.

Examples: 20 strawberry lollipops in any lollipop jar = complete. 19 strawberry + 1 lemon = full but incomplete. Ten strawberry in each of two jars = both incomplete. Emptying a jar allows its role to change freely.

Show a targeted destination's count, such as `12/20`. For full mixed destinations show a neutral “Mixed varieties” prompt, not a penalty. Its contents must remain visually inspectable, with an aimed item's identity available in the HUD.

## 7. Inventory, placement, and mistake recovery

Inventory is an ordered list of individual candy IDs, initially capacity five. Do not introduce weight, stacking limits by family, inventory grids, or a separate bag screen.

- HUD always shows `held / capacity`, e.g. `2/5`.
- A newly collected or retrieved item becomes the selected item.
- Display one floating 3D preview at lower right, comfortably away from the crosshair. By default it is the latest pickup; cycling selection changes the preview to the selected item. This extension lets the player use a mixed inventory without forced last-in-first-out placement.
- A compact icon strip may show all carried items with a selection outline. Keep it readable at maximum capacity.
- One primary-action press picks up one loose item or deposits one selected item into an aimed destination. Holding the button must not repeat deposits or pickups.
- Deposits use the first free slot; the player does not position or rotate individual pieces.
- A separate retrieve action takes the specifically aimed stored piece. If the player aims at the container instead, it takes the most recently deposited remaining piece. Slot removal leaves a free slot; later deposits fill the earliest free slot.
- If inventory is full, retrieval is rejected without modifying the display. The player can deposit elsewhere or use safe drop to free a slot.
- Safe drop returns the selected item to a validated floor spot in front of the player. It snaps to a free position; it is never thrown or simulated. If no clear spot exists, leave inventory unchanged and show “No space here.”
- Include a guaranteed available recovery placement zone near the entrance. It is ordinary floor space reserved from initial scattering, sized to hold a full maximum inventory; use it as the safe-drop fallback if local space is unavailable. Explain this fallback briefly when used.
- All loose and stored pieces remain reachable. Never require crouching, jumping, moving furniture, or picking through opaque geometry to finish.

Logical transfers are atomic and precede their short visual animations. A piece has one owner at all times. Prevent repeated input from duplicating an item during a tween. Animation interruption, pause, or save/load must not lose candy.

## 8. Input and first-person movement

| Action | Mouse/keyboard | Controller / Deck |
| --- | --- | --- |
| Move | WASD | Left stick |
| Look | Mouse | Right stick |
| Pick up / deposit one | Left mouse | Right trigger, press edge |
| Retrieve stored candy | Right mouse | Left trigger, press edge |
| Previous / next carried item | Mouse wheel or Q/E | Left / right bumper |
| Safe drop selected item | G | B |
| Find candy | F | Y |
| Pause / menu | Escape | Menu/Start |
| UI confirm / back | Enter / Escape; mouse | A / B |

Use Godot InputMap actions. Mouse look uses relative motion; stick look uses time-scaled angular motion, sensitivity, and configurable deadzone. Prevent analog trigger jitter from producing repeated actions. Start with walking speed around 3.5 m/s and reach 2.0 m; tune in the graybox.

No sprint, jump, crouch, head bob, or camera shake is needed. Use collision against architecture; loose candy does not block walking. Aim assistance should modestly enlarge interactable targeting with line-of-sight checks, not reach through counters or shelves. When aiming at stored pieces, primary action still deposits into their owning destination; secondary action retrieves the piece.

Every menu must be fully navigable by controller, with explicit focus and a visible focus state. Change prompts based on meaningful recent input, without analog drift causing prompt flicker. Pause on focus loss or controller disconnect. Consume UI events so closing a menu cannot also drop candy or interact with the room.

## 9. Room layout based on the owner's sketch

Treat the sketch as a top-down arrangement reference, not exact measurements. Recreate its relationships without requiring the source image to be present in the repository:

- Rectangular single room, initially approximately 12 m wide × 16 m deep.
- Locked front door centered on the front wall. Spawn just inside, facing toward the back of the store.
- Long counter across most of the rear; provide an obvious walk-around gap at its right end and a continuous employee aisle behind it. The counter and all its displays are accessible from the beginning.
- Two freestanding square kiosks rotated about 45 degrees, staggered along the central aisle as in the sketch.
- Shelves/fixtures along both side walls, broken into sections with breathing room.
- Rear-wall decoration or shallow shelves behind the counter; no additional room or exit.
- Aim for at least 1.4 m clear passages and wider turning space around kiosks. Adjust the approximate room dimensions to maintain comfortable targeting and walking distances.

Put the four lollipop jars on one central kiosk and four wrapped-candy bins on the other. Use side-wall and/or counter shelving for the eight remaining destinations. Keep remaining fixtures decorative; do not imply that decoration is an unfinished sorting task. Oversized lollipop and wrapped-candy signs identify the kiosks without assigning flavors.

Scatter all 320 pieces in mixed, readable clusters on reachable floor and low counter surfaces. No items start already sorted. Use deterministic seeded placement from validated spawn slots; avoid intersections, hidden undersides, inaccessible counter backs, or pieces behind opaque furniture. Preserve walking lanes and the recovery zone. Save actual item positions so content does not reshuffle on resume.

## 10. Visual and audio direction

Use a saturated palette of strawberry pink, lemon yellow, turquoise, orange, and violet, balanced by cream shelving and readable neutral HUD panels. Favor chunky rounded shapes, cheerful trim, oversized sweets as signage, and warm soft lighting. The completed room should look intentionally arranged and richly stocked.

Open bins and display stands should expose the candy. Avoid deeply opaque jars and expensive layered glass. Represent lollipop jars with shallow sides or simplified transparent shells and fixed insertion slots; interiors must support mixed variants and targeted retrieval.

Add short pickup and placement tweens, gentle sound variation, and a brief sparkle/chime when a destination first completes. A complete destination retains an emissive rim or similarly cheerful indicator. Removal turns that persistent indicator off. Recompletion restores it without repeatedly playing an elaborate celebration.

Use a short room-wide celebration when the shop is first completed: confetti, a pleasant sound, and a completion panel with “Keep admiring” and “Restart.” Restart requires confirmation and creates a fresh shuffled run in the same room. The front door remains a boundary; no second scene or stage follows.

Third-party assets must have documented suitable licenses. Keep source/license/attribution records. Use procedural meshes or simple generated textures where faster. Do not rely on paid assets, runtime downloads, external AI services, or large asset packs. Audio may be sourced or simply synthesized; avoid missing-asset placeholders in the polished milestone.

## 11. Progress and automatic upgrades

Show current completed displays out of 16 and overall sorting progress as items contained in currently complete displays divided by 320. Targeted containers separately show occupancy; mixed full containers do not count as correctly sorted progress.

Track the highest number of simultaneously complete displays reached during the run. Use that high-water mark for permanent upgrades; repeatedly emptying and refilling one destination cannot farm unlocks. Current completion may decrease after removal, but unlocked upgrades never disappear.

| High-water mark | Automatic unlock |
| ---: | --- |
| 2 complete displays | Carry capacity 5 → 8 |
| 4 | Interaction reach 2.0 m → 3.0 m, for pickup/deposit/retrieve |
| 6 | Find matching candy ability |
| 10 | Carry capacity 8 → 12 |

Show a short nonblocking notification for each unlock. No currencies, purchases, skill tree, or upgrade screen.

Find matching candy highlights loose pieces matching the selected variant for a short pulse. With empty inventory, use an aimed loose/stored candy's variant; if no variant is available, prompt the player to select or aim at one. Do not designate a flavor destination for the player.

Endgame assistance is separate and cannot be gated behind upgrades: once 32 or fewer loose/carried items remain, make a “Find remaining” mode available. It points toward a loose piece, then reminds the player to place carried pieces when none are loose. If all pieces are stored but the shop is incomplete, point toward an incomplete mixed display. Support a simple mode toggle in the pause menu using controller focus. This must also resolve a room where all candy is in mixed displays and no matching upgrade has unlocked.

## 12. Suggested architecture and state contracts

Keep game rules separate from scene presentation. Avoid an oversized framework.

| Component | Responsibility |
| --- | --- |
| CandyCatalog resource | Families, variants, mesh/material references, counts and icons |
| CandyState | Stable item ID, variant ID, location owner, world pose or slot ID |
| DestinationState | ID, family ID, capacity, slot item IDs; derived completion |
| InventoryState | Ordered item IDs, selected ID, capacity |
| GameSession | Authoritative transfers, validation, progress, upgrades, run seed |
| CandyView / DestinationView | Render state, targeting geometry, animations and feedback |
| PlayerController / Interactor | Movement, camera, aim resolution, action requests |
| HUD / Menus | Inventory preview, contextual prompts, progress, settings, focus |
| SaveService | Versioned snapshots, atomic replacement, backup and recovery |

Suggested directories: `scenes/`, `scripts/core/`, `scripts/player/`, `scripts/ui/`, `resources/candy/`, `assets/`, `tests/`, `docs/`.

Establish transfer entry points before splitting work: `try_pickup(item_id)`, `try_deposit(destination_id)`, `try_retrieve(destination_id, optional_slot_id)`, `try_drop_selected()`, and `select_inventory_item(index)`. Return success or a stable failure reason. The session emits state/progress changes; views do not modify inventory or counts directly.

Invariants:

1. Every one of the 320 unique IDs exists exactly once: world, inventory, or a destination slot.
2. Family/variant membership is immutable and comes from the catalog.
3. Inventory and destination counts never exceed capacity.
4. Destination slots accept only their declared family, while accepting all its variants.
5. Completion is derived from actual contents, not trusted saved booleans.
6. The whole shop is complete iff all 16 destinations are currently complete.
7. Cosmetic animations never own authoritative candy state.

At this scale ordinary lightweight nodes and shared meshes/materials are the starting point. Avoid hundreds of per-item processing loops, rigid bodies, or individual dynamic lights. Profile before adding MultiMesh or custom rendering complexity.

## 13. Save, settings, and restart

Autosave after state changes with a short debounce, on pause, on focus loss, and before normal exit. Save immediately after restart initialization and first whole-shop completion. Write a temporary file then replace the active snapshot; retain a last-known-good backup.

Persist schema version, content version, run seed, each item owner and pose/slot, ordered inventory and selection, destination contents, player position/yaw/pitch, progression high-water mark, unlocks, and whether the run's final celebration has already played. Save state, not animations; reconstruct views on load. Validate conservation and capacities before applying a snapshot. On invalid data, try the backup; if neither works, explain and offer a new run without crashing or silently discarding the save.

Settings persist separately: mouse sensitivity, controller look sensitivity/deadzone, invert Y, master/music/effects volume, fullscreen/windowed, and field of view. Use comfortable defaults, readable text, and no required configuration before playing. Restart clears run progress and upgrades but retains settings.

Resume should select “Continue” by default when a valid save exists. Support suspend/resume testing on Steam Deck when hardware is available.

## 14. Milestones and agent work packages

### Milestone 1 — playable sorting slice

Scope: one grayboxed version of the final room; one lollipop model; two variants; two destinations × 10 pieces = 20 pieces. The reduced catalog is a development fixture, not an in-game stage.

Implement walking, mouse and controller look, mixed five-item inventory, preview, selection, single-piece pickup/deposit, freely chosen flavor bins, mixed mistakes, retrieval, safe drop, counts, completion feedback, and basic save/resume. Use the same data-driven systems intended for the full game.

Acceptance: someone can launch, intentionally mix both jars, correct them, finish, save/reload, and restart using only a controller. Item conservation holds throughout. Supply a runnable slice and brief validation report before expanding content.

### Milestone 2 — complete shop

Expand to the exact 320-piece catalog and 16 destinations. Finish the sketch-based layout and four shared models, create distinct variant appearances, implement all upgrades, progress, finder/recovery assistance, final celebration, restart, robust saves, and settings. Replace graybox fixtures with coherent stylized assets.

Acceptance: the whole shop can be completed from a fresh run without debug tools; all candy and display slots are accessible; mixtures remain repairable even with full inventory; settings and progress survive relaunch.

### Milestone 3 — polish and exports

Tune candy readability, aiming, room traversal, sounds, animations, and menu focus. Verify UI at 1280×800 and 1920×1080, export Windows and Linux, and document actual hardware results and remaining limitations. Target stable 60 FPS on Steam Deck at 1280×800; this is a performance target until measured on hardware.

### Delegation structure for the implementing agents

The lead agent owns integration and specification fidelity. Define state contracts first; then delegate independent work with explicit file ownership:

| Work package | Owner scope | Dependency / handoff |
| --- | --- | --- |
| A: Session and persistence | Core states, transfers, saves, focused rule tests | Establish interfaces first; own save schema |
| B: Player and interaction | Movement, targeting, controller actions | Consume A's interfaces; lead owns shared InputMap edits |
| C: Room and candy art | Shop scene, models, materials, spawn/slot layouts | Use catalog IDs and view interface agreed with A |
| D: HUD and feedback | Inventory preview, focusable menus, audio, indicators | Consume events from A and prompts from B |
| Lead: Integration and validation | Main scene, project settings, export presets, build notes | Integrate slice before expanding; run full acceptance |

Use parallel agents only where the execution system supports them. A sequential agent can complete the same packages. Do not let multiple agents edit `project.godot`, the same `.tscn`, or shared catalog definitions concurrently. Each handoff lists changed files, provided interfaces, validation performed, and unresolved issues. Do not report a mocked system as integrated gameplay.

## 15. Focused acceptance checks

Automate the rules most likely to cause lost progress; use manual play for feel and presentation.

- Place the same variant in different eligible jars in different runs; both arrangements can finish.
- Fill a jar with 19 matching and one different flavor; it remains incomplete, then completes after correction.
- Wrong-family and over-capacity transfers fail without mutation.
- Retrieve a specific item, including a buried-looking slot; every visible stored item is selectable or otherwise reachable through removal.
- Fill inventory while displays contain mistakes; safe drop permits recovery without losing or duplicating candy.
- Remove from a complete destination; current completion decreases, persistent completion glow clears, upgrades remain.
- Recomplete the same destination repeatedly; unlock thresholds are not farmed.
- Save/load with mixed destinations, selected inventory, dropped pieces, and interrupted animations; IDs and counts remain identical.
- Rapid clicks and analog trigger noise do not create duplicate transfers.
- Arrange all candy into full mixed destinations; finder points to unfinished displays and the game remains solvable.
- New run creates exactly 20 copies of each of 16 variants and preserves settings.
- Walk all aisles and behind the counter; collect every spawn and interact with every destination at starting reach.
- Finish the slice using only a gamepad; verify full-game menus without mouse interaction.
- Verify focus loss, controller disconnect, pause, resume, and completion restart do not leak inputs into gameplay.
- On real Deck when available, check gamepad input, 1280×800 text, performance, and suspend/resume. Otherwise mark these as unverified, not passed.

Use a small headless GDScript test runner for state invariants if no test framework exists. Avoid adding a framework solely for this prototype. Run editor import/script validation, focused state tests, and an exported-build smoke test. Report unavailable tools or hardware clearly.

## 16. Deliverables and boundaries

Deliver the Godot source project, pinned engine version, Windows/Linux presets, any successfully produced builds, README run/export instructions, a short architecture note, asset licenses/credits, and a concise milestone validation report. Keep unverified checks separate from passed checks. A source-only handoff must explicitly state why exports were unavailable.

Do not add: more rooms or floors, level transitions, recipe/crafting systems, sales, customers, currency, story quests, physics piles, throwing, multiplayer, complex inventory UI, preset flavor assignments, mandatory flavor ordering, achievements, online services, or store publishing.

The finished prototype succeeds when collecting and placing candy feels pleasant, every mistake is recoverable, and the same messy room visibly becomes a completely organized candy shop.

## 17. Official technical references

Consult documentation matching the pinned engine version during implementation.

- [Godot downloads and stable release](https://godotengine.org/download/windows/) — choose the standard editor and matching export templates.
- [Controllers, gamepads, and joysticks](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html) — InputMap, analog input, deadzones, and platform input considerations.
- [Exporting for Linux](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_linux.html) — native Linux export setup.

The mechanics, counts, thresholds, layout dimensions, and architecture in this plan are project design decisions, not claims from these references.
