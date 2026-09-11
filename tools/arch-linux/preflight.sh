#!/usr/bin/env bash
set -euo pipefail

echo "Pixel Composer Arch/Linux preflight"
echo "=================================="

printf 'Kernel: '; uname -srmo || true
printf 'Session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'Wayland display: %s\n' "${WAYLAND_DISPLAY:-none}"
printf 'X11 display: %s\n' "${DISPLAY:-none}"

echo
for cmd in ffmpeg magick convert webpmux gifski; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    printf '[ok] %-8s %s\n' "${cmd}" "$(command -v "${cmd}")"
  else
    printf '[--] %-8s not found\n' "${cmd}"
  fi
done

echo
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  echo "note: Wayland detected. If Pixel Composer fails to launch or behaves oddly, retest under X11/XWayland before patching rendering code."
fi

echo "note: optional export helpers are not required for the first VM launch test."
