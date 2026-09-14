#!/usr/bin/env bash
set -euo pipefail

# Build Pixel Composer for Linux inside a disposable Ubuntu 24.04 container.
#
#   ./tools/linux/build-in-container.sh
#
# This is a wrapper around the canonical gate
# tools/arch-linux/sandbox-build-smoke.sh. The gate itself needs an apt-based
# system with GameMaker's build dependencies; running it in a container keeps
# those dependencies off the host and makes the build reproducible on hosts
# that are not Ubuntu (Arch, Debian, Fedora, ...).
#
# Compared to tools/arch-linux/create-build-container.sh this needs no
# distrobox and no persistent container: plain podman or docker is enough.
#
# Overrides:
#   PXC_CONTAINER_ENGINE   podman | docker            (default: whichever exists)
#   PXC_CONTAINER_IMAGE    build image               (default: ubuntu:24.04)
#   PXC_SANDBOX_CACHE      cache/output directory    (default: see below)
#   PXC_BUILD_JOBS         compile jobs              (default: nproc)
#
# The finished build lands in "$PXC_SANDBOX_CACHE/vm-build" and can be
# installed with tools/linux/install.sh.

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
CACHE="${PXC_SANDBOX_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/pixel-composer-arch-sandbox}"
IMAGE="${PXC_CONTAINER_IMAGE:-docker.io/library/ubuntu:24.04}"
JOBS="${PXC_BUILD_JOBS:-$(nproc 2>/dev/null || echo 4)}"

engine="${PXC_CONTAINER_ENGINE:-}"
if [[ -z "$engine" ]]; then
  for candidate in podman docker; do
    if command -v "$candidate" >/dev/null 2>&1; then
      engine="$candidate"
      break
    fi
  done
fi
if [[ -z "$engine" ]] || ! command -v "$engine" >/dev/null 2>&1; then
  echo "error: no container engine found; install podman or docker" >&2
  echo "       (Arch: sudo pacman -S --needed podman)" >&2
  exit 1
fi

# The repository is mounted read-only on purpose: the gate archives committed
# HEAD into the cache and builds there, so it must not need write access to the
# checkout.
mkdir -p "$CACHE"
echo "Engine : $engine"
echo "Image  : $IMAGE"
echo "Source : $ROOT (read-only mount)"
echo "Cache  : $CACHE"

"$engine" run --rm \
  --volume "$ROOT":/src:ro \
  --volume "$CACHE":/cache \
  --env PXC_SANDBOX_CACHE=/cache \
  --env PXC_BUILD_JOBS="$JOBS" \
  --env PXC_GM_RUNTIME_VERSION="${PXC_GM_RUNTIME_VERSION:-}" \
  --env PXC_SMOKE_SECONDS="${PXC_SMOKE_SECONDS:-}" \
  --env DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -c '
    set -euo pipefail
    # Unset rather than forward empty values, so the gate keeps its own defaults.
    [[ -n "${PXC_GM_RUNTIME_VERSION:-}" ]] || unset PXC_GM_RUNTIME_VERSION
    [[ -n "${PXC_SMOKE_SECONDS:-}" ]] || unset PXC_SMOKE_SECONDS
    apt-get update -qq
    apt-get install -y -qq git >/dev/null
    # The checkout belongs to the host user, not to root inside the container.
    git config --global --add safe.directory /src
    exec /src/tools/arch-linux/sandbox-build-smoke.sh
  '

echo
echo "Build ready: $CACHE/vm-build"
echo "Install it with: $ROOT/tools/linux/install.sh"
