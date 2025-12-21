gpu_set_tex_filter(false);

var gpu_blend = gpu_get_blendenable();
var gpu_texrepeat = gpu_get_tex_repeat();
var gpu_filter = gpu_get_tex_filter();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);
gpu_set_tex_filter(false);

	for(var j = 0; j < 4; j++) {
		// Merges Cones into their appropriate fluence:
		for(var i = (render_count - 1); i >= 0; i--) {
			shader_set(merginghrc_u_Shader);
			shader_vec2(merginghrc_u_CascadeSize, render_extent, render_extent);
			shader_vec2(merginghrc_u_CascadeIndex, i, render_count);
			shader_float(merginghrc_u_CascadeFrustum, j);
			shader_texture(merginghrc_u_CascadePrev, surface_source(merge_radiance[(i+1) % render_count]));
			shader_texture(merginghrc_u_Emissivity, surface_source(render_emissv));
			shader_texture(merginghrc_u_Absorption, surface_source(render_absorp));
				surface_set_target(surface_source(merge_radiance[i]));
					draw_clear_alpha(c_black, 0);
					draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, render_extent, render_extent);
				surface_reset_target();
			shader_reset();
		}
		
		// Capture frustum fluence after merging.
		surface_set_target(surface_source(render_frustums[j]));
			draw_clear_alpha(c_black, 0);
			draw_surface(surface_source(merge_radiance[0]), 0, 0);
		surface_reset_target();
	}
	
	// Sum all 4 rendered frustum directions.
	shader_set(fluencesum_u_Shader);
	shader_vec2(fluencesum_u_CascadeSize, render_extent, render_extent);
	shader_texture(fluencesum_u_Frustum0, surface_source(render_frustums[0]));
	shader_texture(fluencesum_u_Frustum1, surface_source(render_frustums[1]));
	shader_texture(fluencesum_u_Frustum2, surface_source(render_frustums[2]));
	shader_texture(fluencesum_u_Frustum3, surface_source(render_frustums[3]));
		surface_set_target(surface_source(render_fluences));
			draw_clear_alpha(c_black, 0);
			draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, render_extent, render_extent);
		surface_reset_target();
	shader_reset();

gpu_set_blendenable(gpu_blend);
gpu_set_texrepeat(gpu_texrepeat);
gpu_set_tex_filter(gpu_filter);

var xx = 1024 / render_extent;
draw_surface_ext(surface_source(render_fluences), 0, 0, xx, xx, 0, c_white, 1.0);
//draw_surface_ext(surface_source(render_frustums[0]), 0, 0, xx, xx, 0, c_white, 1.0);

draw_set_color(c_yellow);
draw_set_font(Fnt_PixelFont);
draw_text(5,  5, "Frame Time:   " + string(delta_time / 1000) + "ms / " + string(1000 * (1.0/game_get_speed(gamespeed_fps))) + "ms");
draw_text(5,  25, "Light Size:   " + string(light_size));