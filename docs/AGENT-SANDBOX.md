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
The project is archived from committed `HEAD` into the external cache before
prefab restore and compilation, so the verification run also leaves the source
checkout clean. Uncommitted edits are not included in this gate.

On a host that is not apt-based, or to keep build dependencies off the host
entirely, run the same gate inside a container:

```bash
./tools/linux/build-in-container.sh
```

It needs podman or docker, mounts the checkout read-only and executes the
canonical helper inside Ubuntu 24.04. The cache/output location is unchanged, so
[`tools/linux/install.sh`](../tools/linux/install.sh) can install the result
directly.

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
4. Archives committed `HEAD` into the external cache, then runs [`pre_build_step.sh`](../pre_build_step.sh) there. This regenerates shader/data packs and creates an Apollo compatibility fallback if the proprietary extension is absent without rewriting the checkout.
5. Downloads the official Linux Igor bootstrap from GameMaker and installs runtime `2026.100.0.1098` from the beta runtime feed.
6. Runs GameMaker `Linux Compile` against [`PixelComposer.yyp`](../PixelComposer.yyp).
7. Verifies `Final Compile finished` and extracts the resulting `PixelComposer.zip`.
8. Verifies that the VM payload exists at `assets/game.unx`.
9. Runs the bundled ImageMagick AppImage with `APPIMAGE_EXTRACT_AND_RUN=1` and proves 16-bit PNG -> 8-bit PNG plus WebP -> PNG proxy conversion.
10. Extracts the matching GameMaker Linux runner from the installed runtime and launches the compiled project under Xvfb.
11. Fails if the runtime log contains a GameMaker `ERR:{...}`, `ERROR!!!`, or unresolved `lua_*` loader function.
12. Verifies that Pixel Composer actually unpacked its theme data and stayed alive for the complete smoke window.

The CI build probe runs the same startup smoke with `PXC_UI_FREEZE=1` and
requires the corresponding activation marker. A replay marker needs a real
rendering interaction; Xvfb startup alone cannot establish that visual path.

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

### 10. Installing the build is a separate, scriptable step

`Linux Compile` plus the runtime's runner produce a directory, not an installed
application. [`tools/linux/install.sh`](../tools/linux/install.sh) is the
deployment side of that: application directory, launcher, desktop entry and
icon, with an `--uninstall` counterpart.

Two properties of the launcher are not cosmetic. `PXC_UI_FREEZE=1` has to be in
the launch environment because it is read at startup and never stored in
preferences, and the desktop entry sets `StartupNotify=false` because the
GameMaker runner sets no `WM_CLASS` and no startup notification id - verified
with `xprop` on a real Plasma session, where a startup notification would
otherwise hang until it times out.

### 10b. The command-line mode does not load a project yet

`--headless` exists and its switches are parsed in
[`objects/o_main/Create_0.gml`](../objects/o_main/Create_0.gml), but a run with a
project argument does not reach any output on this branch.

Measured with 1.21.9.210 on Debian 13, `xvfb-run ./runner <project>.pxc
--headless -out <dir>`:

1. The run died in panel construction reading
   `MENU_ITEMS.steam_workshop_panel`. `__initPanel` is skipped when `IS_CMD`, but
   a display refresh still rebuilt `Panel_Menu`. Fixed by gating the panel half
   of `display_refresh` on `IS_CMD` while still queueing the render pass.
2. It then reached project loading and died on
   `node_junction_surface_uv` in `node_value_surface` -> `Node_Shape` ->
   `nodeLoad`. That is a theme sprite; command-line runs use
   `__initThemeEmpty()` instead of `__initTheme()`.

**Unverified suspicion:** the command-line path is not maintained for runs with
a loaded project, because node construction reads theme data the empty theme does
not carry. Whether the second failure is the last one or the next in a chain is
open.

Not tried yet: running `__initTheme()` under `IS_CMD` and measuring the cost;
extending `__initThemeEmpty()` with the fields node construction reads; loading a
minimal project instead of a sample; `--server`/`--persist`, in case they take a
different startup path.

#### Headless project-loading investigation

On 2026-09-14, the documented sample-project reproduction still failed first in
`node_value_surface` while reading the missing
`THEME.node_junction_surface_uv`; the later connection and `setHeight` errors
were therefore not treated as independent failures. The empty command-line
theme initialized in `0.09 ms` in that run.

Loading the regular theme for command-line runs is being tested through
`__initTheme()` because a loaded project may construct any registered node and
therefore may read theme fields outside the manually maintained empty-theme
subset. If this route fails, record its first exact error and measured startup
cost here before trying to extend `__initThemeEmpty()`. A minimal project and
the `--server`/`--persist` start paths have not been tried in this investigation.

Building that commit through `sudo /usr/local/bin/pixel-composer-build
--build-only` in the agent session failed before the build started with
`sudo: a terminal is required to read the password` and `sudo: a password is
required`. This only establishes that the root-only local wrapper could not be
used through that session. A direct run of the canonical source-only helper
with a writable copy of the existing cache under `/tmp` is the next attempted
route; its result is not yet known.

### 11. Official packaging is a different gate from compilation

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
- [`tools/linux/build-in-container.sh`](../tools/linux/build-in-container.sh)
- [`tools/linux/install.sh`](../tools/linux/install.sh)
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

### Linux UI flicker: confirmed workaround

**Real-desktop result, 2026-09-12:** the user reported that menu/panel flicker
disappeared with `PXC_UI_FREEZE=1`, after reporting no change with
`PXC_UI_STATE_RESET=1`. Environment: Arch/CachyOS, KDE Plasma 6, Wayland session;
GameMaker runtime `2026.100.0.1098` using X11/GLX via XWayland. The affected
project's large inner UI/menu areas blinked at the animation/frame-change rate,
particularly while `Rendering...` was displayed. The inspected desktop log
confirmed snapshot activation but did not show the replay marker. Therefore the
successful result cannot yet be attributed specifically to freezing: rendering
the main UI through the extra surface may itself be sufficient. The source build and
45-second Xvfb startup gate also passed with the snapshot mode enabled; the
visual result comes from the user, not the headless test.

**What this establishes:** enabling the UI snapshot drawing path avoids the
reported flicker on this setup. The
working hypothesis is that repeatedly drawing/compositing the UI during partial
node rendering exposes the problem. This does not prove a particular state
leak, surface corruption, driver bug or compositor fault: the extra surface
also changes the drawing path. Do not record an exact root cause as established.

#### Reproduce the working launch on another installation

Build this branch with the snapshot implementation, then run from the directory
containing the matching `runner` and `assets/`:

```bash
env -u PXC_UI_STATE_RESET PXC_UI_FREEZE=1 ./runner
```

The variable is read at startup; it is not a saved preference or enabled by
default. Carry it into each new installation's launcher/desktop shortcut. An
old build will not acquire the workaround just by setting the variable.
Required log markers are:

```text
[Linux diagnostic] UI snapshot freeze enabled
[Linux diagnostic] Replaying completed UI snapshot during rendering
```

The replay marker is printed once per process, when a ready snapshot is first
reused. For a control run, close the application and launch the same build with
both `PXC_UI_FREEZE` and `PXC_UI_STATE_RESET` unset. Avoid simultaneous instances.

#### Implementation and limits

- [Create event](../objects/o_main/Create_0.gml): Linux-only launch switches and
  snapshot state; the earlier state-reset diagnostic remains independently opt-in.
- [Main UI draw](../objects/o_main/Draw_64.gml): cache panels, menus, notes and
  window manager in a separate surface. Mark it ready only when `RENDERING` is
  undefined; replay it while rendering is pending. Resize/surface loss
  invalidates the cached image.
- [GUI-end draw](../objects/o_main/Draw_75.gml): skip the main object's overlays
  during replay. Other objects' independent draws are not captured.
- [Cleanup event](../objects/o_main/CleanUp_0.gml): release the snapshot surface.

Rendering and stepping continue, but controls processed by the cached draw
temporarily do not process input; the preview pauses until rendering finishes.
The new surface also adds GPU memory/copy overhead. This is a confirmed opt-in
workaround, not yet a general production fix. Do not remove it or replace it
with a state reset without equivalent real-desktop evidence. A future permanent
fix should retain stable completed UI imagery while preserving responsive input.

#### Previous negative results: do not repeat without new evidence

The user had already tested `SDL_VIDEODRIVER=x11`, VSync, Gamescope, increased
`render_max_time`, and continued Graph/Inspector drawing while rendering, with
no improvement. `SDL_VIDEODRIVER=wayland` did not force native Wayland.
Synchronous `RenderSync()` changed the flicker into a solid blocked area.
A surface-target guard found no target leak. Multiple instances were excluded;
the cogwheels animation worked. Logs showed no causal runtime/Lua error or crash.

The subsequent UI-entry reset of shader, blend, color-write, depth, alpha-test,
culling, scissor, world matrix and draw color/alpha also made no visible
difference. It did not cover all possible graphics state or surface contents.
No real X11-session comparison was established by these tests; selecting SDL's
X11 driver inside Wayland still uses XWayland.

#### Regression checks

1. Run the [canonical gate](../tools/arch-linux/sandbox-build-smoke.sh) with
   `PXC_UI_FREEZE=1`; verify compile, startup and the activation marker.
2. On a real desktop, open the affected project and test manual frame changes
   and playback long enough to trigger pending rendering. Verify the replay
   marker and stable menus/panels; a startup-only pass is insufficient.
3. Check that the preview advances after rendering completes and controls work
   again. Exercise stopping playback, resizing, minimize/restore and project
   switching. These broader interaction checks remain to be validated.
4. Compare the same build with both switches unset when investigating causality.
   Preserve Windows behaviour and do not claim universal GPU/compositor coverage.

Once the one-command sandbox gate is green, do not continue inventing Linux source fixes. Move to the real desktop checks in [`tools/arch-linux/LOCAL-AGENT-PROMPT.md`](../tools/arch-linux/LOCAL-AGENT-PROMPT.md): Wayland first, XWayland/X11 comparison if needed, file dialogs, normal/16-bit/WebP image import, PNG/export helpers, preferences/restart and save/reopen.

If native Arch fails, capture the first causal error and compare with the already-green Ubuntu/Xvfb baseline before changing application code.
