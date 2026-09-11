#!/usr/bin/env bash
set -u

printf '== OS ==\n'
cat /etc/os-release 2>/dev/null || true
uname -a || true

printf '\n== Session ==\n'
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-}"
printf 'XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-}"
printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-}"
printf 'DISPLAY=%s\n' "${DISPLAY:-}"
printf 'QT_QPA_PLATFORM=%s\n' "${QT_QPA_PLATFORM:-}"
printf 'SDL_VIDEODRIVER=%s\n' "${SDL_VIDEODRIVER:-}"

printf '\n== KDE / compositor ==\n'
plasmashell --version 2>/dev/null || true
kwin_wayland --version 2>/dev/null || true

printf '\n== GPU ==\n'
command -v lspci >/dev/null 2>&1 && lspci -k | grep -EA3 'VGA|3D|Display' || true
command -v glxinfo >/dev/null 2>&1 && glxinfo -B || true
command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo --summary || true

printf '\n== GameMaker ==\n'
dpkg -l 2>/dev/null | grep -i gamemaker || true
find "$HOME/.local/share" -maxdepth 4 -type d -iname '*GameMaker*' -print 2>/dev/null || true

printf '\n== Helpers ==\n'
for tool in ffmpeg convert magick webpmux gifski; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-10s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '%-10s missing\n' "$tool"
  fi
done
