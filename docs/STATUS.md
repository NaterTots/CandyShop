# Current state — 2026-09-11

**Milestones 1 and 2 are owner-accepted ("All tests passed"). Milestone 3 polish and standalone Windows/Linux exports are implemented. Awaiting the owner's packaged-build playtest and Steam Deck hardware validation.**

## Repository publication — 2026-09-18

- Published the complete source repository to the default `main` branch of `NaterTots/CandyShop` as the `POC commit` commit, preserving the repository's existing license and removing the temporary remote `master` branch. Godot editor state, generated exports, platform build intermediates, local environment overrides, export credentials, signing material, temporary files, and operating-system metadata are excluded by `.gitignore`.
- Reworked the root README as a present-tense project guide. It no longer uses milestone or acceptance-history framing; current gameplay, launch, validation, packaging, and playtest information remains documented.
- Automated checks: reviewed Git status and ignored-file coverage; scanned tracked candidates for credential filenames and common embedded GitHub/API token or password assignments. No credential candidates were found. This publication-only task did not rerun the game validation suites documented below.
- Visual inspection: not performed for this publication-only task; the prior Milestone 3 visual results remain unchanged.
- Hardware testing: not performed; controller and Steam Deck checks remain outstanding.

Engine reverified: **4.7.2.stable.official.ed1daf0bf**, standard Windows edition, Compatibility renderer. Launch the standalone `builds/windows/CandyShop.exe`, then Continue; `Launch Candy Shop.cmd` still runs from source. Close an older running copy first. Exact launch/validation commands and the playtest checklist are in the root README.

## Latest kiosk fit revision

- Aligned all eight kiosk bins and their candy slots with the diagonal kiosks. Each bin is now 1.84 m square; the unchanged 4.04 m tops leave about 12 cm of outer ledge and narrow center gaps.
- Spread the 20 slots across each larger bin; display targeting follows the new bin footprint. Kiosk collision footprints and walking clearances remain unchanged. Saved bin membership and slot indices restore automatically into the new arrangement.
- Rendered scene validation: **662 checks, zero failures**, including all 320 loose candies and all 320 stored slots at the original 2 m reach. Updated interaction-test approach positions to match the rotated fixtures. Inspected the filled-shop capture for aligned edges, ledges, and candy spacing. Physical controller testing remains unverified.
- Rule validation: **58,396 checks, zero failures**. Updated Windows and Linux startup checks passed; distribution archives and checksums are refreshed.
- The existing `builds/windows/CandyShop.exe` was still running and could not be replaced safely. The updated runnable Windows build is `builds/staging-windows/CandyShop.exe`, also included in the refreshed Windows ZIP. The source launcher and Linux build include the change.
- Next task: owner saves/quits the old game, launches the updated build, and checks the bin fit. Replace the old Windows executable once it is closed; continue the standalone-build playtest.

## Milestone 3

- Preserved the accepted candy art, chaotic floor layout, kiosk spacing, controller bindings, movement/reach, atomic transfers, save format, and player-chosen flavors.
- Added a neutral gold diamond crosshair for an in-reach target; it does not judge flavor choices or change ray targeting.
- Settings toggles retain controller focus after rebuilding their labels. Completion chimes use a separate audio player so immediate pickup/placement does not truncate them.
- Fixed upgrade progress-bar overlap and singular wording. Widescreen expands the view; verified actual rendered images are 1280 x 800 and 1920 x 1080, rather than a letterboxed inner viewport.
- Installed matching export templates and verified their SHA512 against the official Godot 4.7.2 release checksum. Added `build.ps1`, runtime/component license notices, portable play instructions, and archive checksums.
- Created standalone Windows x86_64 (embedded PCK) and native Linux x86_64 (adjacent PCK) packages. Existing user saves remain compatible.

## Accepted Milestone 2 feedback revision

- Chocolate bars are thin slabs with exposed cocoa ends; boxed sweets are chunky hexagonal cartons. Flavor-colored top/bottom faces carry the wrapper markings, including on the cartons' lids and bases.
- Moved the rear wrapped/swirl kiosk 1.2 m toward the entrance to widen the back passage.
- Added a persistent next-upgrade panel with the reward, remaining completed displays, and high-water progress bar.
- Replaced grid placement with eight irregular shallow heaps plus scattered floor pieces, randomized orientations, and a clear entrance lane. No initial candy is placed on shelves or counters; piles are stationary, without rigid-body physics.
- Layout revision 2 migrates existing full-shop saves by rearranging only loose candy. Held/stored pieces, selected inventory, and progression remain intact. New positions and rotations persist on subsequent saves.

## Implemented

- Exact full catalog: **320 unique pieces, four families, 16 variants, 20 copies per variant, 16 family-restricted displays with 20 slots each**. Flavor assignments remain entirely player-chosen; same-family mixtures are legal.
- Four shared procedural model recipes: round lollipops, double-twist wrapped sweets, wrapped bars, and cartons. Saturated color, wrapper patterns, and heart/sun/diamond/star icons distinguish variants. Materials/prefabs are cached; textures have mipmaps and rendering uses 4× MSAA.
- Cohesive cream, turquoise, pink, and gold shop: staggered diamond kiosks, four open displays per kiosk, eight open side shelf bays, long rear counter, employee aisle/right gap, front windows/locked door, lighting, signage, and reserved recovery mat. Irregular heaps and strays occupy validated floor positions with a clear entrance walking lane.
- Accepted interaction behavior retained: walking speed, initial reach, mouse/controller look, primary/retrieve bindings, trigger hysteresis, mixed ordered inventory, newest selection, lower-right preview, specific/latest retrieval, earliest-free-slot placement, and atomic reversible transfers. View updates are incremental instead of rebuilding every candy after each action.
- Automatic high-water upgrades at 2/4/6/10 displays: capacity 8, reach 3 m, matching finder, capacity 12. Current completion can decrease without losing upgrades or farming new ones.
- Matching pulses and directional guidance. Independent remaining assistance at 32 or fewer outside displays handles loose, carried, and fully stored mixed states. Pause-menu mode toggle supports controller focus.
- First-display sparkles/chimes, persistent completion rims, once-per-run room confetti/chime and completion menu. Confirmed restart resets the run and upgrades while retaining settings.
- Persistent mouse sensitivity, controller sensitivity/deadzone, invert Y, master/music/effects volume, fullscreen/windowed, and FOV. Focusable settings controls, meaningful displayed units, synthesized local music/effects, and real audio buses.
- Validated versioned saves with temporary-file replacement, last-known-good backup, graceful corruption handling, player pose, exact inventory/slot state, progression/history, finder mode, and celebration flag. New runs/first completion save immediately. Exit save failure leaves the game open.

## Automated validation

- Godot editor import/script registration: exit 0, no errors or warnings in `import-validation.log`.
- Rule runner: **58,396 assertions, zero failures** (`rule-validation.log`). This includes layout migration, next-upgrade progress, multiple scatter seeds, all spawn-pair separation checks, exact catalog/family constraints, immutable IDs, both flavor assignments, full/19+1 mixtures and correction, capacity rejection, newest/earliest slot behavior, all upgrades/no farming, finder edge cases, validated save/backup round trips, settings, restart, and 2,000 randomized requests with conservation checks.
- Rendered scene runner: **662 checks, zero failures** (`scene-validation.log`). Seed 42's **320/320 loose pieces and 320/320 occupied slots** are individually targetable from legal standing positions at the original **2 m reach**. Real physics sweeps verify the counter gap, employee aisle, and closed entrance.
- Integrated scene checks exercise trigger jitter/rearming/held-through-pause behavior, entrance fallback, menu input isolation/focus, focus-loss/disconnect signals, settings application, actual restart/settings retention, the final-placement completion panel/one-shot flag, maximum mixed inventory, and zero-upgrade mixed-display assistance.
- Presentation runner: **108 checks, zero failures**, including both actual rendered resolutions, menu bounds/focus traversal, toggle retention, inventory/HUD separation, and aim cues (`polish-validation.log`).
- Source 120-frame headless startup: exit 0 with no warnings. Fixed a headless audio playback shutdown warning; headless runs initialize audio resources without starting playback.
- Updated **`builds/CandyShop.pck`** exported successfully. Launched it headlessly for 120 frames from outside the project directory using the installed engine: exit 0, no warnings. It is a resource pack requiring Godot, not a standalone executable.

## Standalone delivery and desktop measurements

- `build.ps1` completed successfully, including 58,396 rule checks, 662 headless scene checks, both release exports, notices, and archives. Windows: `builds/CandyShop-Windows-x86_64.zip`; Linux: `builds/CandyShop-Linux-x86_64.tar.gz`; checksums: `builds/SHA256SUMS.txt`.
- Both native executables and copies extracted from the final distribution archives passed 120-frame headless startup from outside the project (exit 0). Windows also launched with the real renderer (exit 0). Exported-build checks cover startup; the detailed rule/scene runners ran through the editor, not inside release templates.
- Ubuntu WSL x86_64 Linux rendered through Mesa llvmpipe software graphics. It warns that V-Sync changes are unsupported and no audio driver is available (dummy fallback). One forced-exit dummy-audio run also reported two leaked engine objects; the later verbose startup did not. Linux audio, native Linux desktop play, and hardware performance are not validated.
- Visually inspected Milestone 3 screenshots for floor candy, maximum inventory, pause and settings menus at both actual target resolutions. The initial upgrade-bar overlap and widescreen letterboxing were corrected and recaptured.
- Short editor-rendered desktop samples, RTX 3060 Laptop GPU, 180 frames per state after 30 warm-up frames: 1280 x 800 floor mean **8.13 ms**, p95 **9.27 ms**; filled/celebration mean **8.81 ms**, p95 **9.89 ms**. 1920 x 1080 floor mean **8.77 ms**, p95 **10.18 ms**; filled/celebration mean **9.26 ms**, p95 **10.68 ms**. These are stationary desktop samples, not a sustained benchmark or a Steam Deck 60 FPS claim.

## Visual inspection and unverified checks

Real rendering ran on **NVIDIA GeForce RTX 3060 Laptop GPU, OpenGL 3.3.0 NVIDIA 555.97**. Inspected 1280 × 800 viewport captures: `shop-gameplay.png`, `shop-menu.png`, `shop-settings.png`, `shop-complete.png`, `shop-inventory.png`, and `candy-variants.png`. Latest revision: additionally inspected the irregular floor piles, widened kiosk passage, next-upgrade panel, thin bars, hexagonal cartons, and colored cap markings. Checked four family silhouettes, 16 color/pattern/icon variants, open filled displays, 12-piece inventory/preview readability, menu layout, and confetti. Corrected dim lighting, protruding lollipop label corners, wrapper end orientation, distant texture aliasing, and settings focus/units.

**No physical controller was connected during agent validation.** The owner's Milestone 1 acceptance is recorded separately. The owner has accepted Milestone 2. Milestone 3 still needs a human packaged-build/controller playthrough, manual relaunch/settings/fullscreen checks, and audio comfort assessment. Synthetic disconnect/input checks are not hardware unplug/suspend tests. Steam Deck, hardware suspend/resume, and resolutions other than the two tested sizes remain unverified. WSL Linux checks are not SteamOS/Deck validation.

Matching export templates are now installed. Standalone packages and `build.ps1` include Godot/component notices and play instructions.

## Specification deviations / implementation choices

- **Room dimensions are 18 × 22 m**, expanded from the approximate 12 × 16 m default to accommodate the 320-piece fixtures and clear aisles. The plan explicitly permits dimensional tuning; the sketch relationships and single-room boundary remain.
- **The full catalog starts a separate save**, schema 2 / `shop-320-v1` in `shop_save.json`. The accepted `slice_save.json` is retained untouched in the original application data directory rather than migrated into a partially filled 320-piece shop. This is an explicit development-fixture boundary, not an in-game stage.
- Owner-requested art/layout changes supersede the original rectangular-carton and floor/counter scatter choices: hexagonal cartons and floor-only stationary heaps. No physics piles were added.
- Procedural art/synthesized audio and native Compatibility effects follow the permitted defaults. There are **no intentional gameplay-rule or catalog-count deviations**.

## Next task

**Owner playtests the Milestone 3 standalone build using the README checklist. On an available Steam Deck, measure 1280 x 800 performance and test controls, focus loss, and suspend/resume. Address observed issues without adding scope or changing the accepted interaction rules.**
