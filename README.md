# Candy Shop

Restore one colorful candy shop: **320 pieces, four families, 16 variants, 20 copies each, and 16 displays with 20 slots each**. Choose each eligible display's flavor. Mixtures are allowed and reversible. No stages, customers, scores, timers, or penalties.

## Launch

**Web:** play at [natertots.github.io/CandyShop](https://natertots.github.io/CandyShop/). The browser build requires WebGL 2; current Chrome, Edge, or Firefox is recommended. Click the game before using keyboard, mouse, audio, or controller input. Progress is stored in that browser's site data and does not persist in private/incognito browsing.

**Standalone Windows:** open `builds/windows/CandyShop.exe`, or extract `builds/CandyShop-Windows-x86_64.zip` and open its executable. No Godot installation is required. Existing full-shop saves are compatible.

**Linux / Steam Deck:** extract `builds/CandyShop-Linux-x86_64.tar.gz`, keep the executable and PCK together, then run `chmod +x CandyShop.x86_64` and `./CandyShop.x86_64`. See the included `PLAYING.txt` for Steam's non-Steam game setup and save transfer. Steam Deck hardware remains unverified.

**From source:**

Close an older running copy, double-click **`Launch Candy Shop.cmd`**, then choose **Continue** (controller A). Alternatively import `project.godot` in **Godot 4.7.2.stable.official.ed1daf0bf** and press **F5**. Exact PowerShell command:

```powershell
& 'C:\Users\hodge\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --path 'C:\Users\hodge\Development\CandyShop'
```

Progress is stored in **`shop_save.json`** and settings in **`settings.cfg`**. Open their directory through **Project → Open User Data Folder** in Godot.

## Controls

| Action | Keyboard / mouse | Controller |
| --- | --- | --- |
| Walk / look | WASD / mouse | Left / right stick |
| Pick up / deposit one selected piece | Left click | RT |
| Retrieve aimed stored piece | Right click | LT |
| Select previous / next held piece | Q / E or wheel | LB / RB |
| Safe drop selected piece | G | B |
| Find candy | F | Y |
| Pause / resume | Escape | Start / Menu |
| Navigate / confirm menu | Arrows / Enter or mouse | D-pad / A |
| Back from submenu | Escape | B |
| Adjust settings slider | Left / right or mouse | D-pad left / right |

The crosshair becomes a gold diamond when a piece or display is within reach. This confirms the target without assigning a flavor destination.

Walking speed is 3.5 m/s and starting reach is 2 m. Actions trigger once per press, controller triggers use hysteresis, the newest item is selected automatically, and every transfer is reversible. Primary action on stored candy deposits into its owning display. Retrieval takes the aimed piece; aiming at the container takes the latest remaining deposit. New deposits fill the earliest free slot. Walk around kiosks to inspect inner rows.

## Shop and progression

Lollipops and double-twist wrapped sweets each have a central kiosk with four open displays. Chocolate bars and boxed sweets occupy four open shelf bays on each side. The long rear counter has a right-side gap and employee aisle. Everything is accessible immediately. The room is tuned to 18 × 22 m for clear passages and larger displays.

Fresh runs scatter candy into irregular shallow floor heaps and individual strays, with varied orientations and no initial shelf/counter pieces. Chocolate bars are thin cocoa-ended slabs; boxed sweets use chunky hexagonal cartons, with flavor markings on top and bottom.

Every flavor combines saturated color, wrapper pattern, and icon: heart/stripes, sun/dots, diamond/checks, or star/chevrons within its family. Names/patterns appear when aimed at or selected. Inventory abbreviations and icons distinguish carried pieces; brackets mark selection. See `docs/candy-variants.png` for the full catalog.

Safe drop snaps to clear floor nearby. If blocked, it uses the entrance recovery mat: 45 reserved positions, exceeding maximum inventory. If every candidate is occupied, nothing moves and “No space here” appears. Clear space by picking up or placing pieces.

Only full, single-flavor displays count as sorted. Removal clears current completion and glow. Permanent upgrades use the highest **simultaneous** completion count:

| Displays reached | Automatic upgrade |
| --- | --- |
| 2 | Carry 8 pieces |
| 4 | Reach 3 m |
| 6 | Find matching loose candy |
| 10 | Carry 12 pieces |

The upper-right panel shows the next reward, completed displays still needed, and permanent high-water progress.

F/Y finds the selected flavor, or the aimed flavor when hands are empty. Matches pulse and the HUD points toward one. Repeatedly completing one display cannot farm upgrades.

At **32 or fewer pieces outside displays**, Find remaining works independently of upgrades. It points to loose candy, then reminds you to place held pieces. With everything stored in mixtures, it points to an incomplete display. The pause menu toggles remaining/matching mode. Remaining mode defaults on and uses matching mode until the endgame threshold is reached.

Finishing all displays plays confetti/chimes and offers **Keep admiring** or **Restart**. Displays remain editable. The final celebration plays once per run. Restart reshuffles positions and resets upgrades while retaining settings.

## Settings and saves

Pause → Settings provides mouse sensitivity, controller look speed/deadzone, invert Y, master/music/effects volume, fullscreen/windowed, and FOV. Changes apply immediately and persist separately. Music and effects are synthesized locally.

Autosave follows transfers/selection after a short debounce, and runs on pause, focus loss, disconnect, normal exit, initialization, and first completion. Snapshots validate ownership, family membership, capacities, positions, and progression. Temporary-file replacement retains a validated `.bak`. Invalid or missing active saves try the backup; replacing an unrecoverable run requires confirmation. Exit save failure keeps the run open.

## Validation and packaging

From the project directory:

```powershell
$godot = 'C:\Users\hodge\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path . --editor --import
& $godot --headless --path . --script tests/test_session.gd
& $godot --headless --path . --script tests/smoke_scene.gd
& $godot --headless --path . --quit-after 120
# Real rendering and screenshots at both required resolutions:
& $godot --path . --script tests/polish_scene.gd
& $godot --path . --script tests/smoke_scene.gd
# Resource pack, requiring the installed engine:
& $godot --headless --path . --export-pack 'Windows Desktop' builds/CandyShop.pck
& $godot --main-pack 'C:\Users\hodge\Development\CandyShop\builds\CandyShop.pck'
```

Tests use temporary save/settings files; scene test mode suppresses user persistence and fullscreen changes. See [docs/STATUS.md](docs/STATUS.md) for results and hardware limits.

Matching **4.7.2.stable** Windows/Linux templates are installed and their download SHA512 was verified against the official release checksums. Rebuild and package with `powershell -ExecutionPolicy Bypass -File build.ps1` (optional `-Godot` executable path). The script validates rules/scenes, exports both platforms, includes runtime license notices, and writes archive SHA256 checksums to `builds/SHA256SUMS.txt`.

Windows uses an embedded resource pack. Linux ships a separate PCK. Add the native executable to Steam with the extracted folder as its working directory and a standard Gamepad layout. No Proton override or Steamworks integration is required. WSL validation does not establish Steam Deck compatibility or performance.

## Playtest checklist

1. Launch the standalone build and Continue your existing progress.
2. Check candy identity and the gold aiming cue at pickup distance; walk behind both kiosks and the counter.
3. Navigate every settings page with the controller; toggle invert Y/fullscreen twice and check that focus stays on the toggle.
4. Check HUD, maximum inventory, and menus at 1280×800 and 1920×1080. Listen for comfortable pickup/placement audio and uninterrupted completion chimes.
5. Quit/relaunch and confirm progress/settings; verify cancel/restart and completion.
6. On Deck, test 1280×800 performance, disconnect/reconnect, and suspend/resume. Record actual results rather than assuming desktop checks cover them.

## Full-shop regression checklist

1. Inspect bars/boxes from above, the irregular floor piles, and the wider passage behind the wrapped-candy kiosk. Explore both kiosks, side shelves, and employee aisle; compare all four silhouettes and flavor markings.
2. Carry several families, cycle selection, reject a wrong-family deposit, mix a display, retrieve specific pieces, and safe drop with full hands.
3. Complete 2, 4, 6, and 10 displays to check upgrades. Remove/reinsert completed pieces; upgrades should remain.
4. Find a selected flavor. Near the end, test remaining mode with loose pieces, held pieces, and mixed displays.
5. Change settings, quit, and relaunch; check settings and mixed progress resume.
6. Finish, keep admiring, rearrange, then cancel and confirm Restart. Settings remain; upgrades reset.

Report playtest issues before adding further scope.
