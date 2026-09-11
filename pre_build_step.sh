#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

python3 "$ROOT/datafiles/Shaders/shader_replace.py"
python3 "$ROOT/datasrc/update.py"
python3 "$ROOT/pre_run.py"
