#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Apollo is optional/proprietary. The public checkout keeps the GameMaker
# descriptor, but the paid native/GML implementation is not part of the repo.
# On Linux, fill only missing bridge files with no-op fallbacks so the editor can
# start with Lua-backed features disabled. A supplied real Apollo install wins.
bash "$ROOT/tools/arch-linux/prepare-apollo-gml-stubs.sh" "$ROOT/extensions/Apollo"

APOLLO_SO="$ROOT/extensions/Apollo/Apollo.so"
if [[ ! -f "$APOLLO_SO" ]]; then
  if ! command -v cc >/dev/null 2>&1; then
    echo "error: a C compiler is required to build the Linux Apollo compatibility shim" >&2
    exit 1
  fi
  cc -shared -fPIC -O2 -Wall -Wextra -Werror \
    -Wl,-soname,Apollo.so \
    -o "$APOLLO_SO" \
    "$ROOT/tools/arch-linux/apollo_linux_stub.c"
fi

python3 "$ROOT/datafiles/Shaders/shader_replace.py"
python3 "$ROOT/datasrc/update.py"
python3 "$ROOT/pre_run.py"
