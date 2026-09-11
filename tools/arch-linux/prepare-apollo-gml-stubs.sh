#!/usr/bin/env bash
set -euo pipefail

APOLLO_DIR="${1:?usage: prepare-apollo-gml-stubs.sh <extensions/Apollo>}"
mkdir -p "$APOLLO_DIR"

write_if_missing() {
  local target="$1"
  if [[ -f "$target" ]]; then
    echo "Apollo bridge present: $target"
    return 0
  fi
  cat > "$target"
  echo "Created Linux Apollo fallback: $target"
}

write_if_missing "$APOLLO_DIR/apollo_buffer.gml" <<'EOF'
/// Linux compatibility stubs for the optional Apollo/Lua integration.
#define lua_buffer_write
return false;

#define lua_buffer_read
return undefined;
EOF

write_if_missing "$APOLLO_DIR/apollo_call.gml" <<'EOF'
/// Linux compatibility stubs for the optional Apollo/Lua integration.
#define lua_call
return undefined;

#define lua_call_w
return undefined;

#define lua_call_m
return [];

#define lua_call_xm
return 0;

#define lua_call_wm
return [];

#define lua_call_wxm
return 0;

#define lua_return
return undefined;

#define lua_return_w
return undefined;

#define lua_return_add
return undefined;

#define lua_call_start
return false;

#define lua_call_next
return false;
EOF

{
  echo '/// Linux compatibility stubs for the optional Apollo/Lua integration.'
  echo '#define lua_script_execute'
  echo 'return undefined;'
  for i in $(seq 0 32); do
    printf '\n#define lua_script_execute_%s\nreturn undefined;\n' "$i"
  done
} > "$APOLLO_DIR/.apollo_script_execute.gml.tmp"
if [[ -f "$APOLLO_DIR/apollo_script_execute.gml" ]]; then
  rm -f "$APOLLO_DIR/.apollo_script_execute.gml.tmp"
  echo "Apollo bridge present: $APOLLO_DIR/apollo_script_execute.gml"
else
  mv "$APOLLO_DIR/.apollo_script_execute.gml.tmp" "$APOLLO_DIR/apollo_script_execute.gml"
  echo "Created Linux Apollo fallback: $APOLLO_DIR/apollo_script_execute.gml"
fi

write_if_missing "$APOLLO_DIR/apollo_core.gml" <<'EOF'
/// Linux compatibility stubs for the optional Apollo/Lua integration.
#define lua_init
return false;

#define lua_update
return false;

#define lua_bool
return argument_count > 0 && argument0 != 0;

#define lua_print_value
return argument_count > 0 ? string(argument0) : "undefined";

#define lua_state_exec
return false;

#define lua_add_code
return false;

#define lua_add_file
return false;

#define lua_add_function
return false;

#define lua_global_get
return undefined;

#define lua_global_set
return false;

#define lua_global_typeof
return "nil";

#define lua_global_type
return 0;
EOF

write_if_missing "$APOLLO_DIR/apollo_ref.gml" <<'EOF'
/// Linux compatibility stubs for the optional Apollo/Lua integration.
#define lua_byref
var _recursive = argument_count > 1 ? argument1 : false;
return argument_count > 0 ? argument0 : undefined;

#define lua_script
return argument_count > 0 ? argument0 : undefined;

#define lua_internal_array_get
return undefined;

#define lua_internal_array_set
return false;

#define lua_internal_array_len
return 0;

#define lua_internal_struct_get
return undefined;

#define lua_internal_struct_set
return false;

#define lua_internal_struct_len
return 0;

#define lua_internal_struct_keys
return [];
EOF
