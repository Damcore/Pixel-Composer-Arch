function Program_Close() {
	PREF_SAVE();
	game_end();
}

function Program_Restart() {
	if(OS == os_windows) {
		var _exePath = program_directory;
		shell_execute("", $"start \"\" /D \"{_exePath}\" \"PixelComposer.exe\"");
	} else {
		// On Linux/macOS parameter 0 is the current executable. Re-launch that
		// instead of assuming the Windows PixelComposer.exe filename.
		var _exe = parameter_string(0);
		if(_exe != "") shell_execute_async(string_quote(_exe), "");
	}
	Program_Close();
}

function window_close() {
	CALL("exit");
	
	var noSave = true;
	for( var i = 0, n = array_length(PROJECTS); i < n; i++ ) {
		var _project = PROJECTS[i];
		
		if(_project.modified && !_project.readonly) {
			var _hasExitDia = false;
			with(o_dialog_exit) {
				if(project == _project)
					_hasExitDia = true;
			}
			
			if(!_hasExitDia) {
				with(dialogCall(o_dialog_exit, noone, noone,, true))
					project = _project;
			}
			
			noSave = false;
		}
	}
	
	if(noSave) Program_Close();
}

	////- Winwin
	
function winwin_start(window, clear = undefined) {
	if(!is_winwin(window)) return;
	
	winwin_draw_begin(window); 
	winwin_draw_clear(COLORS.bg, 1);
	WINWIN_CURRENT = window;
}


function winwin_end() {
	checkTOOLTIP();
	if(is_winwin(WINWIN_CURRENT))
		winwin_draw_end();
	WINWIN_CURRENT = undefined;
}