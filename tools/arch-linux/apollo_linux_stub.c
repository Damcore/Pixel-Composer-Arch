// Linux no-op bridge for the optional proprietary Apollo GameMaker extension.
//
// Pixel Composer currently documents Lua nodes as unsupported on Linux. The
// public source checkout contains Apollo's extension descriptor/GML bridge but
// not the proprietary Apollo.so. GameMaker otherwise aborts while resolving
// the bridge. This shim only supplies the native ABI symbols and intentionally
// implements no Lua functionality.

#define API __attribute__((visibility("default")))

API double lua_show_error(const char *s) { (void)s; return 0.0; }
API double lua_reset(void) { return 0.0; }
API const char *lua_get_cwd(void) { return ""; }
API double lua_set_cwd(const char *s) { (void)s; return 0.0; }
API double lua_state_create(void) { return 0.0; }
API double lua_state_destroy(double a) { (void)a; return 0.0; }
API double lua_thread_create(double a) { (void)a; return 0.0; }
API double lua_thread_destroy(double a) { (void)a; return 0.0; }
API double lua_state_exists(double a) { (void)a; return 0.0; }
API double lua_state_reuse_indexes(void) { return 0.0; }
API double lua_add_function_raw(double a, const char *b, double c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_state_get_interop_depth(double a) { (void)a; return 0.0; }
API double lua_state_exec_raw(const char *a) { (void)a; return 0.0; }
API double lua_call_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_add_code_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_add_file_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_global_get_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_global_set_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_global_type_raw(double a, const char *b) { (void)a; (void)b; return 0.0; }
API double lua_call_start_raw(double a, const char *b, const char *c) { (void)a; (void)b; (void)c; return 0.0; }
API double lua_call_next_raw(double a, const char *b) { (void)a; (void)b; return 0.0; }
API double lua_init_raw(const char *a) { (void)a; return 0.0; }
API double lua_update_method_gc(const char *a, double b) { (void)a; (void)b; return 0.0; }
API double lua_update_ref_gc(const char *a, double b) { (void)a; (void)b; return 0.0; }
