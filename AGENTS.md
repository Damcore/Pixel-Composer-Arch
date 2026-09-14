# AGENTS.md — Pixel-Composer-Arch

This file is the repository-level source of truth for autonomous coding agents.
Read [`docs/AGENT-SANDBOX.md`](docs/AGENT-SANDBOX.md) before changing Linux build or runtime code. For the user-facing Arch notes, also see [`ARCH-LINUX.md`](ARCH-LINUX.md).

## Scope and branch policy

- Work on `arch-linux` unless the user explicitly asks for another branch.
- Do not modify `main` as part of Arch/Linux compatibility work.
- Keep upstream Windows behavior intact; prefer small OS-gated fixes.
- Treat GameMaker `2026.100.0.1098` as the currently validated Linux runtime pin until a newer runtime is deliberately revalidated.
- Do not turn known headless/Xvfb limitations into application fixes without reproducing them on a real desktop.

## Canonical verification

The automated source-only Linux gate is:

```bash
./tools/arch-linux/sandbox-build-smoke.sh
```

It mirrors the proven path in [`.github/workflows/arch-linux-build-probe.yml`](.github/workflows/arch-linux-build-probe.yml): restore GameMaker prefabs, prepare generated data/Apollo fallbacks, install the pinned runtime, run `Linux Compile`, exercise the bundled ImageMagick proxy, and launch the VM build with the official Linux runner under Xvfb.

On hosts without an apt environment, [`tools/linux/build-in-container.sh`](tools/linux/build-in-container.sh) runs that same helper inside an Ubuntu 24.04 container, and [`tools/linux/install.sh`](tools/linux/install.sh) installs the resulting build as a desktop application. Keep both in sync with the canonical gate rather than growing a second build path.

A successful run must include `Final Compile finished`, create `assets/game.unx`, unpack Pixel Composer data into the isolated smoke-test home, reach `Entering main loop`, and survive the configured smoke window without a GameMaker runtime error or unresolved Lua symbol.

## Missing inputs and when to ask the user

A normal source-only compile and headless startup smoke test should require **no uploaded files and no GameMaker login**. Downloadable GameMaker CLI/runtime pieces are fetched by the sandbox helper.

Ask the user only when the task actually requires one of these external inputs:

- a real licensed Apollo extension if Lua nodes/custom Lua add-ons must work instead of the repository fallback;
- an authenticated GameMaker installation/license when the official `Linux Package`/distribution operation is required and GameMaker returns a permission error;
- access to a real Arch/Wayland or X11 desktop when compositor, drag/drop, clipboard, windowing, or interactive file-dialog behavior must be verified;
- a specific private/proprietary file that is neither in the repository nor legally downloadable by the agent.

Never ask for Apollo merely to compile or start the editor. [`pre_build_step.sh`](pre_build_step.sh) generates the source-only Linux fallback when Apollo is absent.

## Linux invariants

- Linux paths are case-sensitive. Never normalize real filesystem paths with `string_lower`.
- Pixel Composer intentionally writes runtime data below `$HOME/PixelComposer/`; [`options/linux/options_linux.yy`](options/linux/options_linux.yy) disables the GameMaker sandbox for this target.
- The bundled ImageMagick AppImage must remain usable with `APPIMAGE_EXTRACT_AND_RUN=1`; do not make FUSE a hard requirement.
- `Linux Compile` produces the VM payload, not a standalone runner. The test runner comes from the matching GameMaker runtime's `linux/runner.zip`.
- Missing proprietary Apollo code is handled by generated no-op GML bridges plus a small native shim. Lua initialization/custom Lua add-ons/Lua nodes remain disabled in that fallback mode.
- Unsupported nodes must fail closed rather than warn and continue into unavailable native code.
- Preserve the opt-in Linux UI snapshot workaround (`PXC_UI_FREEZE=1`): the user confirmed on 2026-09-12 that it eliminates menu/panel flicker during frame changes and animation on Arch/CachyOS + Plasma 6 Wayland/XWayland. Keep the last completed main UI image visible while `RENDERING` is pending. A graphics-state reset alone did not help. Read the [flicker findings and regression checks](docs/AGENT-SANDBOX.md#linux-ui-flicker-confirmed-workaround) before changing this path; the exact lower-level cause remains unproven. This is opt-in, so new installations need the launch variable and a build containing the workaround.
- Do not commit downloaded GameMaker runtimes, GameMaker IDE packages, proprietary Apollo files, restored prefab packages, build output, or generated smoke-test artifacts.

## Debugging discipline

- Start from the first causal compiler/runtime error, not later warnings.
- Reproduce before broad compatibility changes.
- For Wayland failures, compare XWayland/X11 before changing rendering/window code.
- Keep build failure, runtime failure, optional-feature limitation, and GameMaker licensing failure as separate categories.
- Steam/Tablet macros, unavailable Windows/macOS helper DLLs, missing headless audio hardware, and Xvfb display warnings are not blockers by themselves if the editor reaches the main loop.

## Documentation

- Keep durable sandbox/build knowledge in [`docs/AGENT-SANDBOX.md`](docs/AGENT-SANDBOX.md).
- Keep user-facing Arch setup/status in [`ARCH-LINUX.md`](ARCH-LINUX.md).
- Keep the concise handoff checklist in [`tools/arch-linux/LOCAL-AGENT-PROMPT.md`](tools/arch-linux/LOCAL-AGENT-PROMPT.md).
- Repository files mentioned in Markdown should be linked with relative links when practical.

## Git

- Commit only independently coherent changes.
- Commit messages use a short subject, at least one brief explanatory body sentence, and end with the actual runtime model/client trailer:

```text
<subject>

<body>

Agent: <exact model> in <client>
```

Example:

```text
docs: add Linux sandbox runbook

Document the validated source-only build path for fresh agent sandboxes.

Agent: GPT-5.6 Sol in ChatGPT
```

- Use the exact model/session identity available to the running agent; do not invent a more specific model.
- No `Co-Authored-By:` trailer unless the user explicitly requests it.
- Do not rewrite published history merely to repair an old missing/incorrect agent trailer; apply the rule to new commits unless the user explicitly asks for history surgery.
