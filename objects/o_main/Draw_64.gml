/// @description init
linux_ui_frozen = false;
if(IS_CMD) exit;
if(winMan_isMinimized()) exit;
if(USE_TEXTUREGROUP && texturegroup_get_status("UI") == texturegroup_status_loading) exit;

// Diagnostic only; leave GameMaker's GUI view/projection and target intact.
if(linux_ui_state_reset) {
	shader_reset();
	gpu_set_blendenable(true);
	gpu_set_blendmode(bm_normal);
	gpu_set_colorwriteenable(true, true, true, true);
	gpu_set_ztestenable(false);
	gpu_set_zwriteenable(false);
	gpu_set_alphatestenable(false);
	gpu_set_cullmode(cull_noculling);
	gpu_set_scissor(0, 0, WIN_W, WIN_H);
	matrix_set(matrix_world, matrix_build_identity());
	draw_set_color(c_white);
	draw_set_alpha(1);
}

if(linux_ui_freeze) {
	if(!surface_exists(linux_ui_snapshot)) {
		linux_ui_snapshot_ready = false;
	} else if(surface_get_width(linux_ui_snapshot) != WIN_W
		|| surface_get_height(linux_ui_snapshot) != WIN_H) {
		linux_ui_snapshot_ready = false;
	}
	linux_ui_snapshot = surface_verify(linux_ui_snapshot, WIN_W, WIN_H);
	linux_ui_frozen = linux_ui_snapshot_ready && RENDERING != undefined;
	if(linux_ui_frozen) {
		if(!linux_ui_freeze_logged) {
			show_debug_message("[Linux diagnostic] Replaying completed UI snapshot during rendering");
			linux_ui_freeze_logged = true;
		}
		draw_surface_ext(linux_ui_snapshot, 0, 0, 1, 1, 0, c_white, 1);
		exit;
	}
	surface_set_target(linux_ui_snapshot);
}

_MOUSE_BLOCK = MOUSE_BLOCK;
if(MOUSE_BLOCK) MOUSE_BLOCK--;
if(PREFERENCES.video_mode && key_press(ord("Z"), MOD_KEY.alt, true)) MOUSE_BLOCK = 1;

if(APP_SURF_OVERRIDE || DROPPER_DROPPING) {
	APP_SURF      = surface_verify(APP_SURF,      WIN_W, WIN_H);
	PRE_APP_SURF  = surface_verify(PRE_APP_SURF,  WIN_W, WIN_H);
	POST_APP_SURF = surface_verify(POST_APP_SURF, WIN_W, WIN_H);

	surface_set_target(APP_SURF);
}

draw_clear(COLORS.bg);

#region UI animation
	easerStep();
#endregion

#region widget scroll
	if(!WIDGET_TAB_BLOCK) {
		if(keyboard_check_pressed(vk_tab)) {
			if(key_mod_check(MOD_KEY.shift)) widget_previous();
			if(key_mod_check(MOD_KEY.none))  widget_next();
		}
		
		if(KEYBOARD_ENTER)
			widget_trigger();
		
		if(keyboard_check_pressed(vk_escape))
			widget_clear();
	}
	
	WIDGET_TAB_BLOCK = false;
#endregion

#region register UI element
	WIDGET_ACTIVE = [];
#endregion

#region panels
	if(PANEL_MAIN == 0) refreshPanel();
	
	var surf = surface_get_target();
	try {
		PANEL_MAIN.draw();
		PANEL_MAIN.drawFrame();
		
		if(THEME_VALUE.panel_separation_type == "line") 
			draw_sprite_stretched_ext(THEME.ui_panel, 1, 0, 0, WIN_W-1, WIN_H-1, COLORS.panel_frame);
			
	} catch(e) { 
		while(surface_get_target() != surf)
			surface_reset_target();
		
		noti_warning(exception_print(e));
	}
#endregion

#region notes
	for( var i = 0, n = array_length(PROJECT.notes); i < n; i++ )
		PROJECT.notes[i].draw();
#endregion

#region window
	winManDraw();
#endregion

#region debug
	// draw_set_color(c_red);  draw_circle(display_mouse_get_x(), display_mouse_get_y(), 6, false);
	// draw_set_color(c_lime); draw_circle(WIN_X, WIN_Y, 6, false);
	// draw_set_color(c_blue); draw_circle(mouse_mx, mouse_my, 8, true);
#endregion

if(DROPPER_DROPPING) {
	surface_reset_target();
	draw_surface(APP_SURF, 0, 0);
	
} else if(APP_SURF_OVERRIDE) {
	surface_reset_target();
	draw_surface(POST_APP_SURF, 0, 0);
	
	surface_set_target(PRE_APP_SURF);
		draw_surface(APP_SURF, 0, 0);
	surface_reset_target();
	
	surface_set_target(POST_APP_SURF);
		draw_surface(APP_SURF, 0, 0);
	surface_reset_target();
}

DROPPER_DROPPING = false;

if(linux_ui_freeze) {
	surface_reset_target();
	linux_ui_snapshot_ready = RENDERING == undefined;
	draw_surface_ext(linux_ui_snapshot, 0, 0, 1, 1, 0, c_white, 1);
}
