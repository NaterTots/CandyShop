# Candy Shop

- Game specification: `Candy_Shop_Godot_Build_Plan.md`. Milestones 1 and 2 are owner-accepted. Milestone 3 polish and exports are authorized; preserve the accepted interactions and content.
- Engine: Godot **4.7.2.stable.official.ed1daf0bf**, standard edition, Compatibility renderer, typed GDScript.
- Local executable: `C:\Users\hodge\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Validate from the project root: `godot --headless --path . --editor --import`; `godot --headless --path . --script tests/test_session.gd`; `godot --headless --path . --script tests/smoke_scene.gd`; `godot --headless --path . --quit-after 120`. Substitute the executable above if Godot is not on PATH.
- Preserve the simple, relaxed one-room scope. Players choose flavor destinations; mixed same-family bins remain legal and reversible. Never assign or lock bins to flavors.
- Update `docs/STATUS.md` at the end of every task, distinguishing automated checks, visual inspection, and hardware testing.
- Milestone 3 presentation checks: `godot --path . --script tests/polish_scene.gd`. Rebuild/package: `powershell -ExecutionPolicy Bypass -File build.ps1`; matching 4.7.2.stable Windows/Linux x86_64 templates are installed.
