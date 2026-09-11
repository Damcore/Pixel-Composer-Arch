#!/usr/bin/env bash
set -euo pipefail

name="${PXC_DISTROBOX_NAME:-pxc-gamemaker}"
image="${PXC_DISTROBOX_IMAGE:-ubuntu:24.04}"

if ! command -v distrobox >/dev/null 2>&1; then
  echo "error: distrobox is not installed" >&2
  echo "Arch: sudo pacman -S --needed podman distrobox" >&2
  exit 1
fi

if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
  echo "error: neither podman nor docker is installed" >&2
  exit 1
fi

if distrobox list 2>/dev/null | grep -Eq "(^|[[:space:]|])${name}([[:space:]|]|$)"; then
  echo "Distrobox '${name}' already exists."
else
  echo "Creating '${name}' from '${image}'..."
  distrobox create --yes --name "${name}" --image "${image}"
fi

echo
echo "Enter it with:"
echo "  distrobox enter ${name}"
echo
echo "Then, from this repository, run:"
echo "  ./tools/arch-linux/setup-ubuntu-build-env.sh"
