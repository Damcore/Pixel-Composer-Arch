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

Native **Arch + Wayland/XWayland GUI behaviour still needs a real desktop smoke test**. The Ubuntu VM/runtime result proves the GameMaker project and Linux source path, not every compositor integration.

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

## Arch host workflow

Recommended host tools:

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

## Native Arch QA still required

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
