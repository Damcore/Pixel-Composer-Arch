#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
RUNTIME_VERSION="${PXC_GM_RUNTIME_VERSION:-2026.100.0.1098}"
RUNTIME_FEED="${PXC_GM_RUNTIME_FEED:-https://gms.yoyogames.com/Zeus-Runtime-NuBeta.rss}"
CACHE_ROOT="${PXC_SANDBOX_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/pixel-composer-arch-sandbox}"
SMOKE_SECONDS="${PXC_SMOKE_SECONDS:-45}"

install_system_deps() {
  [[ "${PXC_SKIP_SYSTEM_DEPS:-0}" == "1" ]] && return 0
  command -v apt-get >/dev/null 2>&1 || return 0

  local -a apt=(apt-get)
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      apt=(sudo apt-get)
    else
      echo "warning: apt-get is available but root/sudo is not; skipping package installation" >&2
      return 0
    fi
  fi

  "${apt[@]}" update
  "${apt[@]}" install -y \
    build-essential ca-certificates clang curl ffmpeg git \
    libglu1-mesa libopenal1 libpulse0 nodejs npm python3 \
    unzip xauth xdg-utils xvfb zip
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

install_system_deps
for cmd in cc curl grep npm python3 unzip xvfb-run; do
  require_cmd "$cmd"
done

mkdir -p \
  "$CACHE_ROOT/gmtools" \
  "$CACHE_ROOT/igor-bootstrap" \
  "$CACHE_ROOT/runtimes" \
  "$CACHE_ROOT/gm-user" \
  "$CACHE_ROOT/gm-cache" \
  "$CACHE_ROOT/gm-build-temp"

if [[ ! -x "$CACHE_ROOT/gmtools/node_modules/@gm-tools/project-tool-linux-x64/ProjectTool" ]]; then
  (
    cd "$CACHE_ROOT/gmtools"
    npm install --registry=https://gmpm.gamemaker.io \
      @gm-tools/project-tool-linux-x64 \
      @gm-tools/package-tool-linux-x64 \
      @gm-tools/gmpm-linux-x64
  )
fi

PT="$CACHE_ROOT/gmtools/node_modules/@gm-tools/project-tool-linux-x64/ProjectTool"
PKG="$CACHE_ROOT/gmtools/node_modules/@gm-tools/package-tool-linux-x64/PackageTool"
GMPM="$CACHE_ROOT/gmtools/node_modules/@gm-tools/gmpm-linux-x64/gmpm.dll"
chmod +x "$PT" "$PKG"

"$PT" PREFABS RESTORE \
  SOURCE="$ROOT/PixelComposer.yyp" \
  PACKAGETOOL="$PKG" \
  GMPM_DLL="$GMPM"

(
  cd "$ROOT"
  bash ./pre_build_step.sh
)

test -s "$ROOT/extensions/Apollo/Apollo.so"
test -s "$ROOT/extensions/Apollo/apollo_call.gml"
test -s "$ROOT/datafiles/pack/collections.zip"
grep -q '"option_linux_disable_sandbox":true' "$ROOT/options/linux/options_linux.yy"

BOOTSTRAP_IGOR="$CACHE_ROOT/igor-bootstrap/linux/x64/Igor"
if [[ ! -x "$BOOTSTRAP_IGOR" ]]; then
  curl --fail --location --retry 3 \
    --output "$CACHE_ROOT/igor.zip" \
    https://gms.yoyogames.com/igor_linux-x64.zip
  rm -rf "$CACHE_ROOT/igor-bootstrap"
  mkdir -p "$CACHE_ROOT/igor-bootstrap"
  unzip -q "$CACHE_ROOT/igor.zip" -d "$CACHE_ROOT/igor-bootstrap"
  chmod +x "$BOOTSTRAP_IGOR"
fi

RUNTIME="$CACHE_ROOT/runtimes/runtime-$RUNTIME_VERSION"
IGOR="$RUNTIME/bin/igor/linux/x64/Igor"
if [[ ! -x "$IGOR" ]]; then
  "$BOOTSTRAP_IGOR" \
    /rp="$CACHE_ROOT/runtimes" \
    /ru="$RUNTIME_FEED" \
    /uf="$CACHE_ROOT/gm-user" \
    /m=linux,base,base-module-linux-x64 \
    -- Runtime Install "$RUNTIME_VERSION"
fi

chmod +x \
  "$IGOR" \
  "$RUNTIME/bin/assetcompiler/linux/x64/GMAssetCompiler" \
  "$PT"

"$IGOR" \
  /uf="$CACHE_ROOT/gm-user" \
  /rp="$RUNTIME" \
  /project="$ROOT/PixelComposer.yyp" \
  /cache="$CACHE_ROOT/gm-cache" \
  /temp="$CACHE_ROOT/gm-build-temp" \
  /pf="$ROOT/prefabs" \
  /pt="$PT" \
  -j="${PXC_BUILD_JOBS:-8}" \
  -- Linux Compile 2>&1 | tee "$CACHE_ROOT/linux-compile.log"

grep -q 'Final Compile finished' "$CACHE_ROOT/linux-compile.log"

BUILD_ZIP="$(find "$ROOT/output" -type f -name 'PixelComposer.zip' -print -quit)"
test -n "$BUILD_ZIP"
rm -rf "$CACHE_ROOT/vm-build"
mkdir -p "$CACHE_ROOT/vm-build"
unzip -q "$BUILD_ZIP" -d "$CACHE_ROOT/vm-build"
test -s "$CACHE_ROOT/vm-build/assets/game.unx"

IM="$(find "$CACHE_ROOT/vm-build" -type f -iname 'imagemagick.appimage' -print -quit)"
test -n "$IM"
chmod +x "$IM"
rm -rf "$CACHE_ROOT/image-proxy-test"
mkdir -p "$CACHE_ROOT/image-proxy-test"
APPIMAGE_EXTRACT_AND_RUN=1 "$IM" \
  -size 8x8 gradient: -depth 16 "$CACHE_ROOT/image-proxy-test/in16.png"
APPIMAGE_EXTRACT_AND_RUN=1 "$IM" \
  "$CACHE_ROOT/image-proxy-test/in16.png" -depth 8 "$CACHE_ROOT/image-proxy-test/out8.png"
APPIMAGE_EXTRACT_AND_RUN=1 "$IM" \
  "$CACHE_ROOT/image-proxy-test/out8.png" "$CACHE_ROOT/image-proxy-test/in.webp"
APPIMAGE_EXTRACT_AND_RUN=1 "$IM" \
  "$CACHE_ROOT/image-proxy-test/in.webp" "$CACHE_ROOT/image-proxy-test/webp-proxy.png"
test -s "$CACHE_ROOT/image-proxy-test/out8.png"
test -s "$CACHE_ROOT/image-proxy-test/webp-proxy.png"

rm -rf "$CACHE_ROOT/gm-runner" "$CACHE_ROOT/smoke-home"
mkdir -p "$CACHE_ROOT/gm-runner" "$CACHE_ROOT/smoke-home"
unzip -q "$RUNTIME/linux/runner.zip" -d "$CACHE_ROOT/gm-runner"
cp "$CACHE_ROOT/gm-runner/runner" "$CACHE_ROOT/vm-build/runner"
chmod +x "$CACHE_ROOT/vm-build/runner"

set +e
(
  cd "$CACHE_ROOT/vm-build"
  HOME="$CACHE_ROOT/smoke-home" \
  SDL_AUDIODRIVER=dummy \
  timeout "${SMOKE_SECONDS}s" \
    xvfb-run -a -s '-screen 0 1920x1080x24' ./runner \
    >"$CACHE_ROOT/vm-smoke.log" 2>&1
)
rc=$?
set -e

cat "$CACHE_ROOT/vm-smoke.log"
if grep -q 'ERR:{' "$CACHE_ROOT/vm-smoke.log"; then exit 1; fi
if grep -q 'ERROR!!!' "$CACHE_ROOT/vm-smoke.log"; then exit 1; fi
if grep -q 'Unable to find function lua_' "$CACHE_ROOT/vm-smoke.log"; then exit 1; fi
if grep -q 'Could not find function "lua_' "$CACHE_ROOT/vm-smoke.log"; then exit 1; fi
test -s "$CACHE_ROOT/smoke-home/PixelComposer/Themes/default HQ/graphics/graphics.json"
if [[ "$rc" -ne 124 ]]; then
  echo "error: Pixel Composer exited before the ${SMOKE_SECONDS}s smoke window completed (rc=$rc)" >&2
  exit 1
fi

echo
echo "Sandbox Linux build + smoke test passed."
echo "Build: $BUILD_ZIP"
echo "Logs:  $CACHE_ROOT/linux-compile.log"
echo "       $CACHE_ROOT/vm-smoke.log"
