#!/usr/bin/env bash
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo "error: cannot identify distribution" >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "warning: this helper is tested for Ubuntu 24.04; detected ${PRETTY_NAME:-unknown}." >&2
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "error: sudo is required inside the build box" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  libglu1-mesa \
  libopenal1 \
  libpulse0 \
  libssl3 \
  libx11-6 \
  libxext6 \
  libxrandr2 \
  libxxf86vm1 \
  pkg-config \
  unzip \
  xdg-utils \
  zip

echo
echo "Base Ubuntu build dependencies installed."
echo "Next: install the current GameMaker 2026.100 Beta Ubuntu IDE/runtime from the official release page, then open PixelComposer.yyp."
