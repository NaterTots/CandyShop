# Architecture — Milestone 3

The accepted session/interaction separation remains. `scripts/core/session.gd` owns transfers, selection, slot lists, immutable variant membership, completion, high-water progression, first-completion history, finder decisions, and snapshots. IDs encode variant membership (`id / 20`); restart shuffles validated positions. Completion/unlocks are derived from contents/high water rather than trusted saved flags.

`resources/candy/catalog.gd` defines four families and 16 named/color/pattern/icon variants. `scripts/core/shop_layout.gd` supplies footprints, spawn/slot positions, orientations, floor validity, and recovery positions. Spawning, save validation, safe drop, and tests share its contracts. A seeded rejection sampler creates eight shallow stationary floor heaps plus broad strays, with planar clearance and saved Euler orientations; no grid or rigid bodies are used.

`scripts/main.gd` retains CharacterBody3D walking, look, InputMap bindings, ray targeting, mouse actions, trigger hysteresis, selection, and retrieval. Views update incrementally by stable ID and ownership/pose signature rather than rebuilding 320 models per transfer. Tweens never own state. Stored-piece primary action still resolves to its display.

`scripts/candy_art.gd` creates four shared model recipes, cached variant PackedScenes, shared materials, and generated mipmapped wrapper textures. `scripts/shop_room.gd` constructs the room, colliders, family signs, displays, and completion rims. Physics tests target every stored slot from a legal standing position at 2 m.

`scripts/core/settings.gd` validates/persists independent ConfigFile settings. `scripts/sweet_audio.gd` supplies synthesized streams and real Master/Music/Effects buses. Finder markers and CPU confetti are transient; final celebration and first-completed display history persist.

`scripts/core/save_service.gd` validates before temporary-file replacement and keeps a validated previous backup. Schema 2 / `shop-320-v1` uses `shop_save.json`; Milestone 1's `slice_save.json` remains untouched in the original application data directory. Layout revision 2 regenerates only loose poses in revision-1 full-shop saves, preserving stored/held ownership and progression. Invalid loads try backup, and replacement requires confirmation. Unsafe player poses restore to the entrance. Exit save failure leaves the run open.

The rule runner covers invariants, family rules, arbitrary flavor assignment, upgrades/no farming, assistance, corruption/round trips, settings, restart, and seeded transfers. The scene runner uses real physics for spawn/slot targets, checks integrated UI/feedback/input paths, and captures rendered views. Its test mode suppresses user-save/settings writes and fullscreen changes. No framework or plugin is required.

Milestone 3 adds a neutral in-reach crosshair cue, settings-toggle focus retention, an independent celebration audio player, and expanded widescreen canvas layout. `tests/polish_scene.gd` verifies rendered sizes, menu focus/layout, maximal inventory, and short frame samples at both target resolutions. `build.ps1` produces validated standalone Windows/Linux packages and notices without changing session/save contracts.

Kiosk destinations and stored-slot transforms share `ShopLayout.KIOSK_YAW`; `BIN_SIZE` controls visible trays and their target areas. The four-bin arrangement leaves a narrow ledge without changing the kiosk collision footprint.
