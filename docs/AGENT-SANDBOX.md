# Fresh Sandbox Build and Recovery Notes

This is the durable runbook for a fresh coding sandbox working on `arch-linux`. It records the path that was actually proven in CI rather than the older upstream setup assumptions.

## Known-good baseline

Validated on Ubuntu 24.04 with GameMaker runtime:

```text
2026.100.0.1098
```

The successful path does **not** need the GameMaker GUI and did **not** need an authenticated GameMaker login for `Linux Compile`.

The canonical one-command reproduction is:

```bash
./tools/arch-linux/sandbox-build-smoke.sh
```

The script keeps downloaded GameMaker tooling/runtime data under:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/pixel-composer-arch-sandbox
```

Override it with `PXC_SANDBOX_CACHE=/some/path` if needed. It uses a separate smoke-test `$HOME`, so it does not delete or overwrite a developer's real `~/PixelComposer` data.

If the sandbox already has all required Ubuntu packages, skip package installation with:

```bash
PXC_SKIP_SYSTEM_DEPS=1 ./tools/arch-linux/sandbox-build-smoke.sh
```

Other useful overrides:

```bash
PXC_GM_RUNTIME_VERSION=2026.100.0.1098
PXC_BUILD_JOBS=8
PXC_SMOKE_SECONDS=45
```

## What the helper does

1. On apt-based systems, installs the small set of compiler/runtime/headless-display dependencies when root or `sudo` is available.
2. Installs GameMaker ProjectTool, PackageTool and GMPM from GameMaker's package registry into the external cache.
3. Restores the missing `io.gamemaker.sdfshaders-1.0.0` prefab package.
4. Runs [`pre_build_step.sh`](../pre_build_step.sh), which regenerates shader/data packs and creates an Apollo compatibility fallback if the proprietary extension is absent.
5. Downloads the official Linux Igor bootstrap from GameMaker and installs runtime `2026.100.0.1098` from the beta runtime feed.
6. Runs GameMaker `Linux Compile` against [`PixelComposer.yyp`](../PixelComposer.yyp).
7. Verifies `Final Compile finished` and extracts the resulting `PixelComposer.zip`.
8. Verifies that the VM payload exists at `assets/game.unx`.
9. Runs the bundled ImageMagick AppImage with `APPIMAGE_EXTRACT_AND_RUN=1` and proves 16-bit PNG -> 8-bit PNG plus WebP -> PNG proxy conversion.
10. Extracts the matching GameMaker Linux runner from the installed runtime and launches the compiled project under Xvfb.
11. Fails if the runtime log contains a GameMaker `ERR:{...}`, `ERROR!!!`, or unresolved `lua_*` loader function.
12. Verifies that Pixel Composer actually unpacked its theme data and stayed alive for the complete smoke window.

## Important learnings from the sandbox work

### 1. The upstream 2024-era GameMaker assumption is stale

Use the validated 2026 beta/runtime line for this branch. Do not spend time trying to make the old README toolchain authoritative before reproducing the current path.

### 2. Restore prefabs before compiling

A fresh checkout can fail project loading because `io.gamemaker.sdfshaders-1.0.0` is not present. ProjectTool + PackageTool + GMPM can restore it automatically from GameMaker's registry. No user upload is needed.

### 3. `Linux Compile` is enough for source/runtime validation

`Linux Compile` creates the project VM payload inside `PixelComposer.zip`. It does **not** create a standalone Linux runner. For a real smoke test, pair:

```text
PixelComposer.zip -> assets/game.unx
```

with:

```text
runtime-2026.100.0.1098/linux/runner.zip -> runner
```

This is why an early test that merely searched the compile output for an executable was invalid.

### 4. Pixel Composer needs filesystem access outside GameMaker's default sandbox

The application intentionally creates runtime content below `$HOME/PixelComposer/`. Without Linux target options disabling the GameMaker sandbox, initialization can fail later while loading unpacked themes/assets.

The required target configuration lives in [`options/linux/options_linux.yy`](../options/linux/options_linux.yy) and contains:

```json
"option_linux_disable_sandbox": true
```

Do not remove that flag unless the application's storage model is deliberately redesigned.

### 5. The public repository does not contain the real Apollo implementation

Apollo/Lua is optional/proprietary in this checkout. A missing Apollo binary originally caused startup errors such as unavailable `lua_*` functions.

The current source-only path is intentionally self-contained:

- [`tools/arch-linux/prepare-apollo-gml-stubs.sh`](../tools/arch-linux/prepare-apollo-gml-stubs.sh) creates missing GML bridge stubs only when real files are absent.
- [`tools/arch-linux/apollo_linux_stub.c`](../tools/arch-linux/apollo_linux_stub.c) builds the small native compatibility shim.
- [`pre_build_step.sh`](../pre_build_step.sh) orchestrates both.
- Lua initialization, custom Lua add-ons and Lua nodes are disabled while the fallback is active.

Do **not** ask the user for Apollo just to compile or launch Pixel Composer. Ask for the real licensed Apollo files only if actual Lua-backed functionality must be tested/enabled.

### 6. Unsupported-node checks must stop execution

A previous implementation warned that a node was unsupported on the current OS but continued constructing it anyway. On Linux that can flow into unavailable native functions. The branch now returns early for unsupported nodes. Preserve that fail-closed behavior.

### 7. Linux path case matters

Do not lowercase resolved filesystem paths. It can silently break helper discovery on Linux. The branch keeps actual path casing intact while still tolerating the historical bundled lowercase ImageMagick directory where needed.

Also keep Linux path separators correct in helper arguments, especially file-dialog preference paths.

### 8. Bundled ImageMagick can work without FUSE

The shipped ImageMagick AppImage successfully runs with:

```bash
APPIMAGE_EXTRACT_AND_RUN=1
```

This is now set for the Linux application path. Do not add a hard FUSE dependency merely because direct AppImage mounting fails in a container/sandbox.

### 9. Headless warnings are not automatically product failures

The proven Xvfb run still logs nonfatal warnings for some Windows/macOS-only extension binaries, Steam/Tablet extension macros, unavailable PulseAudio/ALSA hardware and Xvfb display details. The decisive signal is whether Pixel Composer completes initialization and reaches:

```text
Entering main loop.
```

Always separate warnings from the first causal runtime error.

### 10. Official packaging is a different gate from compilation

A source-only `Linux Compile` succeeded without login. An official `Linux Package`/distribution attempt can fail with GameMaker permission/licensing errors such as:

```text
Reason Code - 0000002A
Permission Error : Unable to obtain permission to execute
```

That is not evidence that the source port is broken. Do not bypass the permission check. Ask for an authenticated/licensed GameMaker environment if the user wants the final official package/AppImage produced.

## What should already be in the repository

A fresh agent should expect these files to exist on `arch-linux`:

- [`AGENTS.md`](../AGENTS.md)
- [`ARCH-LINUX.md`](../ARCH-LINUX.md)
- [`options/linux/options_linux.yy`](../options/linux/options_linux.yy)
- [`pre_build_step.sh`](../pre_build_step.sh)
- [`tools/arch-linux/sandbox-build-smoke.sh`](../tools/arch-linux/sandbox-build-smoke.sh)
- [`tools/arch-linux/prepare-apollo-gml-stubs.sh`](../tools/arch-linux/prepare-apollo-gml-stubs.sh)
- [`tools/arch-linux/apollo_linux_stub.c`](../tools/arch-linux/apollo_linux_stub.c)
- [`.github/workflows/arch-linux-build-probe.yml`](../.github/workflows/arch-linux-build-probe.yml)

Do not ask the user to upload any of those. If one is unexpectedly absent, first verify the checked-out branch/ref.

## Inputs that may legitimately require the user

Request external help only when one of these is actually needed:

| Need | Ask user? | Why |
| --- | --- | --- |
| Source-only Linux compile | No | Runtime/tooling are downloadable and automated |
| Headless VM startup smoke | No | Matching runner is part of downloaded GameMaker runtime |
| SDF prefab | No | Restored from GameMaker registry |
| Apollo just to launch | No | Repository fallback exists |
| Real Lua nodes/custom Lua add-ons | Yes | Requires the licensed Apollo implementation |
| Official `Linux Package`/release | Usually yes | Requires GameMaker execution/package permission |
| Native Arch Wayland behavior | Yes/local agent | Requires a real desktop/compositor, not Xvfb |
| Clipboard/drag-drop/window decorations | Yes/local agent | These are interactive desktop integrations |

## Native Arch handoff after sandbox success

Once the one-command sandbox gate is green, do not continue inventing Linux source fixes. Move to the real desktop checks in [`tools/arch-linux/LOCAL-AGENT-PROMPT.md`](../tools/arch-linux/LOCAL-AGENT-PROMPT.md): Wayland first, XWayland/X11 comparison if needed, file dialogs, normal/16-bit/WebP image import, PNG/export helpers, preferences/restart and save/reopen.

If native Arch fails, capture the first causal error and compare with the already-green Ubuntu/Xvfb baseline before changing application code.
