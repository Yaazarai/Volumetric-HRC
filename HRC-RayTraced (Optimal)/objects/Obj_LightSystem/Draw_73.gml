var gpu_blend = gpu_get_blendenable();
var gpu_texrepeat = gpu_get_tex_repeat();
var gpu_filter = gpu_get_tex_filter();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);
gpu_set_tex_filter(false);

	shader_set(Shd_sRGBToLinear);
		surface_set_target(surface_source(render_linearEmsv));
			draw_surface(surface_source(render_emissivity), 0, 0);
		surface_reset_target();
	shader_reset();
	
	shader_set(Shd_sRGBToLinear);
		surface_set_target(surface_source(render_linearAbsr));
			draw_surface(surface_source(render_absorption), 0, 0);
		surface_reset_target();
	shader_reset();
	
	// Compute all four frustums:
	for(var j = 0; j < 4; j++) {
		// Merges cones into their appropriate fluence:
		for(var i = (render_cascades - 1); i >= 0; i--) {
			var surf_curr = (i == 0)? render_frustums[j] : render_radiance[i-1];
			var surf_next = (i == render_cascades - 1)? render_frustums[j] : render_radiance[i];
			
			shader_set(merginghrc_u_Shader);
			shader_vec2(merginghrc_u_Extent, render_expanses, render_expanses);
			shader_vec2(merginghrc_u_Indices, i, j);
			shader_texture(merginghrc_u_Prev, surface_source(surf_next));
			shader_texture(merginghrc_u_Emissivity, surface_source(render_linearEmsv));
			shader_texture(merginghrc_u_Absorption, surface_source(render_linearAbsr));
				surface_set_target(surface_source(surf_curr));
					draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, render_expanses, render_expanses);
				surface_reset_target();
			shader_reset();
		}
	}
	
	// Sum all 4 rendered frustum directions.
	shader_set(fluencehrc_u_Shader);
	shader_vec2(fluencehrc_u_Extent, render_expanses, render_expanses);
	shader_texture(fluencehrc_u_Frustum0, surface_source(render_frustums[0]));
	shader_texture(fluencehrc_u_Frustum1, surface_source(render_frustums[1]));
	shader_texture(fluencehrc_u_Frustum2, surface_source(render_frustums[2]));
	shader_texture(fluencehrc_u_Frustum3, surface_source(render_frustums[3]));
		surface_set_target(surface_source(render_fluences));
			draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, render_expanses, render_expanses);
		surface_reset_target();
	shader_reset();

gpu_set_blendenable(gpu_blend);
gpu_set_texrepeat(gpu_texrepeat);
gpu_set_tex_filter(gpu_filter);

var xx = 1024 / render_expanses;
draw_surface_ext(surface_source(render_fluences), 0, 0, xx, xx, 0, c_white, 1.0);

//var mm = 1024 / floor(render_expanses / power(2.0, render_index));
//draw_surface_ext(surface_source(render_mipmapsA[render_index]), 0, 0, mm, mm, 0, c_white, 1.0);

draw_set_color(c_yellow);
draw_set_font(Fnt_PixelFont);
draw_text(5,  5, "Frame Time:   " + string(delta_time / 1000) + "ms / " + string(1000 * (1.0/game_get_speed(gamespeed_fps))) + "ms");