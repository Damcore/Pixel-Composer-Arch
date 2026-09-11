# Pixel Composer on Arch Linux

This fork tracks upstream Pixel Composer and adds an Arch-focused build/run path.

## Current status

Upstream already contains substantial Linux support (`os_linux` branches, Linux helpers and Linux release handling). The remaining risk is distro/compositor compatibility rather than a full Windows-to-Linux port.

For this fork, use **GameMaker 2026.100 Beta (Release 7 / IDE 1149 / Runtime 1098) or newer in the same beta line**. The upstream README still names GameMaker 2024.11; that setup is kept only as historical upstream documentation and is not the target for this Arch branch.

Recommended development layout:

```text
Arch host
  -> Distrobox/Podman Ubuntu 24.04 build box
       -> GameMaker 2026.100 Beta Ubuntu IDE
       -> PixelComposer.yyp
       -> Ubuntu VM smoke test first
       -> AppImage package second
  -> run resulting AppImage on Arch
```

The Ubuntu build box is intentional: GameMaker officially targets Ubuntu 24.04 for its Linux IDE/build tooling, while the produced AppImage is intended to be distro-independent.

## 1. Arch host

Install the container tools if needed:

```bash
sudo pacman -S --needed podman distrobox
./tools/arch-linux/create-build-container.sh
```

Then enter the build box:

```bash
distrobox enter pxc-gamemaker
```

## 2. Ubuntu build box

From the repository checkout:

```bash
./tools/arch-linux/setup-ubuntu-build-env.sh
```

Install the current **GameMaker 2026.100 Beta Ubuntu** build from the official GameMaker release/download page and sign in normally.

Do not disable Ubuntu 24.04 AppArmor user-namespace restrictions globally unless GameMaker actually fails because of them. The official GameMaker setup guide documents that workaround, but this fork deliberately does not automate a system-wide security relaxation.

## 3. First build

Open `PixelComposer.yyp` using the `Default` configuration.

Start with:

1. Ubuntu target
2. VM runtime
3. Run/compile before packaging

Only after the VM build launches cleanly, create an AppImage. YYC is a later validation step; it is slower and introduces more native-toolchain variables.

## 4. Arch/Wayland validation

Run:

```bash
./tools/arch-linux/preflight.sh
```

Then test the produced AppImage normally. If it fails under Wayland, also test from an X11/XWayland session before changing application code. Upstream has had Linux issues around file dialogs, dependency lookup and compositor behaviour, so the diagnostic output should be kept with any failure report.

## Known upstream Linux limitations

Upstream currently documents these Linux limitations:

- native file browser support is incomplete
- clipboard interoperability is incomplete
- file dropping is incomplete
- borderless window support is incomplete
- Lua nodes are not fully supported
- HLSL nodes are unsupported/crash-prone on Linux

Recent upstream versions have fixed several Linux library/path issues, so keep this fork synced with upstream before carrying large compatibility patches.

## Fork policy

Arch-specific changes should stay small and auditable:

- prefer OS guards over Windows behaviour changes
- prefer fixing path handling over copying Windows binaries
- prefer system/native Linux helpers or upstream Linux helpers
- keep `main` close to upstream; develop compatibility changes on `arch-linux`
- verify VM launch before touching rendering/YYC code
