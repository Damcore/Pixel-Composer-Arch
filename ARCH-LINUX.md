# Pixel Composer on Arch Linux

This fork keeps upstream Pixel Composer close to source while adding a tested Linux/Arch build path.

## Status

The Linux VM path is now **validated end to end** with GameMaker Runtime `2026.100.0.1098` on Ubuntu 24.04:

- GameMaker project loads after automatic SDF prefab restore.
- `Linux Compile` completes with `Final Compile finished`.
- The generated VM build starts with the official GameMaker Linux runner.
- Pixel Composer completes initialization, unpacks its data into `$HOME/PixelComposer/`, and reaches `Entering main loop`.
- The bundled ImageMagick AppImage works without FUSE using `APPIMAGE_EXTRACT_AND_RUN=1`.
- 16-bit PNG -> 8-bit PNG and WebP -> PNG proxy conversions are covered by CI.
- The startup smoke test runs for 45 seconds and fails closed on GameMaker runtime errors or unresolved Lua symbols.

Latest green evidence: GitHub Actions run `34648573802` on commit `1a6f1db4a2aa4ce53f08c132c08fa7bfe8ca70c7`.

On 2026-09-12, a real Arch/CachyOS + KDE Plasma 6 Wayland/XWayland test confirmed that the opt-in UI snapshot workaround below removes menu/panel flicker during frame changes and animation. Broader native desktop QA remains open; the Ubuntu VM/runtime result does not prove every compositor integration.

## Flickering menus during animation: confirmed workaround

If large parts of the interface blink in time with frame changes, especially
while `Rendering...` appears, launch a build containing this branch's snapshot
workaround from the directory containing its matching `runner` and `assets/`:

```bash
env -u PXC_UI_STATE_RESET PXC_UI_FREEZE=1 ./runner
```

The workaround is **not enabled by default** and is not saved in preferences.
On another installation, use a build containing these changes and put
`PXC_UI_FREEZE=1` in the launch environment every time (including a desktop
shortcut or launcher). Setting the variable on an older build has no effect.
The startup log must contain `UI snapshot freeze enabled`; actual use logs
`Replaying completed UI snapshot during rendering` once per process.

The main menus/panels and preview retain their last completed image during node
rendering, then update when rendering finishes. This eliminated the reported
flicker in the user's project. UI controls drawn in that image temporarily stop
processing input, and the preview pauses while rendering is pending. This is a
confirmed workaround for the tested setup, not yet a generally validated
production fix.

The evidence points to the UI drawing/compositing path during unfinished node
rendering. It does not identify a particular faulty GPU call or prove that
GameMaker, XWayland or the driver alone is responsible. VSync, Gamescope and a
graphics-state reset did not resolve this case. See the [full findings and
regression checks](docs/AGENT-SANDBOX.md#linux-ui-flicker-confirmed-workaround).

## GameMaker toolchain

Validated runtime:

```text
2026.100.0.1098
```

The CI build installs the current Linux ProjectTool/PackageTool/GMPM packages from GameMaker's registry, restores `io.gamemaker.sdfshaders-1.0.0`, downloads the beta runtime through Igor, and runs a headless Linux VM compile.

A GameMaker login was **not required for `Linux Compile`** in the validated CI path.

The official `Linux Package` operation is different: without GameMaker execution/package permission it stops with:

```text
Reason Code - 0000002A
Permission Error : Unable to obtain permission to execute
```

Do not work around that permission check. Creating the final official distributable/AppImage remains a licensed GameMaker step.

## Important Linux fixes in this branch

- Added `options/linux/options_linux.yy` with `option_linux_disable_sandbox=true`, required because Pixel Composer intentionally writes/unpacks data outside GameMaker's default sandbox.
- Uses `$HOME/PixelComposer/` instead of assuming `/home/<user>/PixelComposer/`.
- Added a portable `pre_build_step.sh` and fixed the pre-run metadata updater.
- Build-time data packs now include `collections.zip`.
- Linux filesystem paths preserve case instead of forcing them to lowercase.
- `xdg-open`, file-dialog preference paths, restart behaviour and crash-reporter handling are Linux-safe.
- Image import proxy handling supports the bundled Linux ImageMagick AppImage for 16-bit images and WebP.
- The Linux file-selector helper has been smoke-tested to its event loop.
- Unsupported nodes now stop construction instead of only displaying a warning.

## Apollo / Lua

The public repository has the Apollo extension descriptor but not the paid/proprietary Apollo implementation.

For source-only Linux builds this branch generates a small compatibility shim plus GML no-op bridges **only when real Apollo files are absent**. With that fallback:

- Pixel Composer starts normally.
- Lua initialization and custom Lua add-ons are disabled.
- Lua nodes are marked unsupported on Linux.
- A supplied real Apollo implementation takes precedence and is not overwritten.

Do not commit proprietary Apollo binaries to this repository.

## Build and install without the GameMaker IDE

The shortest path from a checkout to a launchable editor needs only podman or
docker; the GameMaker toolchain stays inside a disposable Ubuntu 24.04
container:

```bash
./tools/linux/build-in-container.sh   # runs the canonical gate in a container
./tools/linux/install.sh              # installs the resulting build
./tools/linux/install.sh --uninstall  # removes it again
```

`build-in-container.sh` mounts the checkout read-only and runs
[`tools/arch-linux/sandbox-build-smoke.sh`](tools/arch-linux/sandbox-build-smoke.sh)
inside the container, so the container build is the same validated gate,
including the startup smoke test. Downloads and the finished build stay in
`${PXC_SANDBOX_CACHE:-~/.cache/pixel-composer-arch-sandbox}`.

`install.sh` installs system-wide when run as root (`/opt/pixel-composer`,
`/usr/local/bin`, `/usr/local/share`) and per-user otherwise
(`~/.local/lib`, `~/.local/bin`, `~/.local/share`); `--user`, `--app-dir`,
`--bin-dir` and `--data-dir` override that. It writes the application
directory, a launcher that carries `PXC_UI_FREEZE=1` (see above - the variable
is read at startup, so every launcher and desktop shortcut has to set it), a
desktop entry and the application icon.

Afterwards it checks the installed runner with `ldd` and fails if a shared
library is missing. That check exists because the build container has libraries
a fresh desktop may not: without `libGLU.so.1` the runner aborts with
`error while loading shared libraries` and never opens a window.

```bash
sudo pacman -S --needed glu openal libpulse      # Arch
sudo apt install libglu1-mesa libopenal1 libpulse0  # Debian/Ubuntu
```

This is still the VM build plus the official GameMaker runner, not an official
`Linux Package`; see the toolchain section above.

## Arch host workflow

For an interactive build box instead of the one-shot container above,
recommended host tools:

```bash
sudo pacman -S --needed podman distrobox
./tools/arch-linux/create-build-container.sh
```

Enter the Ubuntu 24.04 build box:

```bash
distrobox enter pxc-gamemaker
./tools/arch-linux/setup-ubuntu-build-env.sh
```

For host diagnostics:

```bash
./tools/arch-linux/preflight.sh
```

The Ubuntu build box is deliberate: it matches GameMaker's supported Linux build environment while the resulting Linux application is then tested on Arch.

A verified example of the container path: on Debian 13 (in an unprivileged LXC
container with root podman - rootless podman failed there in `newuidmap`), a
warm-cache `build-in-container.sh` run reproduced the gate and `install.sh`
produced a working KDE Plasma 6 menu entry. The build cache was 1.3 GB, the
installed application 255 MB.

## Native Arch QA still required

The current branch was also smoke-launched on the local CachyOS desktop on
2026-09-12 using the isolated VM build and
`env -u PXC_UI_STATE_RESET PXC_UI_FREEZE=1 ./runner`. The session was KDE
Plasma 6.7.4 on Wayland with the GameMaker X11/GLX runner through XWayland,
AMD Radeon RX 9070/amdgpu and Mesa 26.2.2. It reached `Entering main loop` and
remained alive for 30 seconds without a GameMaker runtime error. The existing
flicker result remains the user's visual confirmation; this smoke does not
replace the interaction checks below.

On a real Arch desktop, test at minimum:

1. native Wayland launch;
2. XWayland/X11 comparison if Wayland has issues;
3. open/save dialogs and paths containing spaces;
4. drag/drop if available;
5. normal PNG import plus 16-bit PNG and WebP import;
6. PNG export and optional FFmpeg/WebP/gifski helpers;
7. preferences persistence across restart;
8. application restart;
9. project save/reopen.

Known nonfatal CI warnings include unavailable Windows/macOS-only extension binaries, Steam/Tablet extension macros, missing headless audio hardware and Xvfb display limitations. They did not prevent Pixel Composer from reaching the main loop.

## Fork policy

- keep `main` close to upstream;
- develop Linux compatibility on `arch-linux`;
- prefer small OS-gated fixes over changing Windows behaviour;
- preserve case-sensitive Linux paths;
- do not add downloaded/proprietary binaries;
- distinguish an actual Arch/Wayland failure from a GameMaker packaging/license limitation.
