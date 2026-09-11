#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /path/to/GameMaker-Beta-2026.100.0.1149.deb" >&2
  exit 2
fi

pkg="$1"
if [[ ! -f "$pkg" ]]; then
  echo "error: package not found: $pkg" >&2
  exit 1
fi

case "$pkg" in
  *.deb) ;;
  *) echo "error: expected a .deb package" >&2; exit 1 ;;
esac

sudo apt-get install -y "$pkg"

echo
echo "Installed GameMaker beta package: $pkg"
echo "Launch the Beta IDE, sign in, install/select the matching 2026.100 runtime, then open PixelComposer.yyp."
