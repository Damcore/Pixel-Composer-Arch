#!/usr/bin/env bash
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo "error: cannot identify distribution" >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "warning: this helper is intended for Ubuntu 24.04; detected ${PRETTY_NAME:-unknown}." >&2
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "error: sudo is required inside the build box" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  ca-certificates \
  clang \
  curl \
  ffmpeg \
  git \
  libcurl4-openssl-dev \
  libfuse2 \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libopenal-dev \
  libssl-dev \
  libxfixes-dev \
  libxrandr-dev \
  libxxf86vm-dev \
  openssh-server \
  pkg-config \
  pulseaudio \
  unzip \
  xdg-utils \
  zip \
  zlib1g-dev

echo
echo "GameMaker Ubuntu build prerequisites installed."
echo "Next: install the current GameMaker 2026.100 Beta Ubuntu .deb, sign in, and open PixelComposer.yyp."
echo
echo "Note for Ubuntu 24.04: do NOT disable AppArmor user-namespace restrictions pre-emptively."
echo "Only apply GameMaker's documented sysctl workaround if the build actually fails because of that restriction."
