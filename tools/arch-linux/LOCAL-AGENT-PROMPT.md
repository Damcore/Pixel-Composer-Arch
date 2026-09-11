Work on repository `Damcore/Pixel-Composer-Arch`, branch `arch-linux`.

Goal: get Pixel Composer building and launching reliably on Arch Linux, preferably native Wayland but XWayland fallback is acceptable. Do not redesign the application and do not touch `main`.

Context already established:
- Upstream has substantial Linux support already; this is not a full port.
- Use GameMaker 2026.100 Beta Release 7 or a newer compatible 2026 beta, not the outdated 2024.11 version in upstream README.
- Start with Ubuntu 24.04 target + VM runtime. Only attempt AppImage/YYC after VM launch works.
- Existing helpers are in `tools/arch-linux/` and documentation in `ARCH-LINUX.md`.
- Known upstream Linux issues include native file dialogs, clipboard/file drop, borderless windows, Lua and HLSL.
- A recent upstream issue reports a startup failure on CachyOS/KDE/Wayland.
- Suspect case-sensitive path bugs: Linux code currently uses `string_lower(filepath_resolve(...))` in library lookup paths. Do not change this blindly; reproduce first.

Tasks:
1. Clone the repo and checkout `arch-linux`.
2. Record environment: Arch/CachyOS version, desktop, Wayland/X11, GPU/driver, GameMaker IDE/runtime exact versions.
3. Run `tools/arch-linux/preflight.sh`.
4. Open `PixelComposer.yyp` in GameMaker 2026 beta using Default config.
5. Build/run Ubuntu VM target first. Capture the complete compiler/runtime log.
6. If it fails, identify the first causal error, fix the smallest possible source/config issue, commit it to `arch-linux`, and rerun.
7. After launch succeeds, smoke-test: startup, create/open project, basic node graph, image import, PNG export, save/reopen project.
8. Then test optional export helpers: FFmpeg, ImageMagick, WebP, gifski. Prefer native Linux binaries and preserve case-sensitive paths. Fix `.exe`, backslash, or forced-lowercase assumptions when reproduced.
9. Test under Wayland and, if needed, XWayland/X11. Do not patch rendering merely because Wayland fails until X11 comparison is known.
10. Attempt AppImage package only after VM run is clean. YYC last.

Rules:
- Keep changes minimal and Linux-gated where appropriate.
- Do not remove upstream Windows functionality.
- Do not commit downloaded/proprietary binaries.
- Do not disable system security features globally unless absolutely required; report if GameMaker itself requires a host setting.
- Commit each independently verified fix with a descriptive message.
- Push changes to `arch-linux` if credentials allow.

Report back with only:
- exact GameMaker IDE/runtime version
- build/run result
- first failing error if blocked
- commits made
- remaining blockers
- whether VM, AppImage, Wayland and X11 each work
