#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# Apollo is optional/proprietary. The public checkout has its GameMaker bridge
# but not Apollo.so, and upstream documents Lua nodes as unsupported on Linux.
# Build a no-op ABI shim only when a real Apollo.so was not supplied.
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
