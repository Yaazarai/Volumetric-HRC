surface_set_target(render_emissivity.memory);
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
	draw_set_color($FFFFFF);
	var xx = view_hport[0] / render_extent;
	var mx = floor(mouse_x / xx);
	var my = floor(mouse_y / xx);
	draw_circle(mx, my, light_size, false);
	
	var yy = render_extent / view_hport[0];
	draw_sprite_ext(Spr_EmissionTexture, 0, 0, 0, yy, yy, 0, c_white, 1);
gpu_set_blendmode(bm_normal);
	draw_set_color(c_black);
surface_reset_target();

surface_set_target(render_absorption.memory);
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
	draw_set_color($FFFFFF);
	var xx = view_hport[0] / render_extent;
	var mx = floor(mouse_x / xx);
	var my = floor(mouse_y / xx);
	draw_circle(mx, my, light_size, false);
	
	draw_sprite_ext(Spr_AbsorptionTexture, 0, 0, 0, yy, yy, 0, c_white, 1);
gpu_set_blendmode(bm_normal);
surface_reset_target();

/*
	This is how you build and render your volumetric scene:
		Emissivity - Amount of light each pixel must emit.
		Absorption - Amount of light each pixel must absorb.
	
	NOTE: Emissive objects MUST also have an absorption property
	to be rendered--this is conssitent with the real/physical world.
	
	NOTE: Absorption is SUBTRACTIVE, per RGB channel. If you set each
	individual R, G or B channel lower/higher more/less of that channel
	will be absorbed.
	
	NOTE: The order in which you draw your emissive and absorbing objects
	matters, you'll need to draw them in the relavant depth-order of your
	game to properly handle layering.
	
	NOTE: Think of the "brightness," of each object as how near/far away
	from the camera the object is. If doing a top-down game, far means
	close to the floor and near means close the camera. Doing this lets
	you layer the scene with more dimensionality.
*/