Work on repository `Damcore/Pixel-Composer-Arch`, branch `arch-linux`.

Goal: perform the remaining **native Arch desktop QA**. Do not redo the already validated Linux port unless you reproduce a real failure. Do not touch `main`.

Already proven on Ubuntu 24.04 with GameMaker Runtime `2026.100.0.1098`:
- ProjectTool + automatic SDF prefab restore works.
- GameMaker `Linux Compile` completes successfully.
- The generated VM build starts with the official Linux runner.
- Pixel Composer completes initialization and reaches `Entering main loop` for a 45-second smoke window.
- `$HOME/PixelComposer/` data extraction works with the Linux GameMaker sandbox disabled.
- bundled ImageMagick works in extract-and-run mode;
- 16-bit PNG -> 8-bit PNG and WebP -> PNG proxy conversion works;
- unresolved Apollo/Lua symbols are fail-closed in CI.

Latest green CI evidence: run `36004994263`, commit `a0f5e03e76094d1c94b3b443155b6380ab4b8da8`.

Important expected behaviour:
- The public repo does not contain the proprietary Apollo implementation.
- The Linux source-only fallback disables Lua initialization, custom Lua add-ons and Lua nodes.
- Do not treat that as a regression unless a real Apollo Linux implementation is supplied.
- `Linux Package`/final official AppImage requires GameMaker execution/package permission. Do not bypass that licensing check.
- Steam/Tablet compile warnings and unavailable Windows/macOS-only helper DLL warnings are currently nonfatal.
- Real-desktop finding (2026-09-12): `PXC_UI_FREEZE=1` eliminated menu/panel flicker during frame changes and animation on Arch/CachyOS + Plasma 6 Wayland/XWayland. The prior UI graphics-state reset did not help. Preserve the completed-UI snapshot workaround; the exact lower-level cause is not proven. Read the [findings and regression checks](../../docs/AGENT-SANDBOX.md#linux-ui-flicker-confirmed-workaround).
- On a new installation, build the snapshot implementation and launch with `env -u PXC_UI_STATE_RESET PXC_UI_FREEZE=1 ./runner` from the VM build directory. This is opt-in on every launch, not a saved preference. Verify both activation and actual replay log markers, then test the affected project; Xvfb startup alone cannot verify the visual fix.

Tasks:
1. Pull the latest `arch-linux` and record Arch/CachyOS version, desktop, Wayland/X11, GPU/driver and exact GameMaker version if used.
2. Run `tools/arch-linux/preflight.sh`.
3. Launch Pixel Composer on the real desktop in the Wayland session through XWayland. Compare with an X11 session if anything is broken; `SDL_VIDEODRIVER=wayland` did not make this runner native Wayland in the documented test.
4. Verify startup reaches the editor without runtime errors.
5. Test open/save dialogs, including a path containing spaces.
6. Test image import with a normal PNG, a 16-bit PNG and a WebP file.
7. Test drag/drop if supported by the desktop/session.
8. Test PNG export plus the optional FFmpeg, WebP and gifski helpers.
9. Change a preference, restart Pixel Composer, and verify the preference persists.
10. Exercise the application's Restart action.
11. Create/save/reopen a small project and do a basic node-graph edit.
12. Report clipboard, screenshot, file-drop or window-decoration limitations separately instead of conflating them with startup/build failures.

If a test fails:
- capture the first causal runtime error and the exact reproduction;
- compare XWayland in a Wayland session with an X11 session before changing rendering/window code;
- make only the smallest Linux-gated fix;
- rerun the affected test and the existing `Arch Linux build probe` workflow;
- commit to `arch-linux` only.

Report back with only:
- environment;
- native Arch launch result;
- Wayland-session/XWayland result;
- X11-session comparison if tested;
- file dialog/import/export/restart/save results;
- first causal error if blocked;
- commits made;
- remaining blockers;
- whether official `Linux Package` was possible with the available GameMaker license.
