var gpu_blend = gpu_get_blendenable();
var gpu_texrepeat = gpu_get_tex_repeat();
var gpu_filter = gpu_get_tex_filter();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);
gpu_set_tex_filter(false);

	for(var j = 0; j < 4; j++) {
		// Copy the scene into the lowest cascade, rotated for the current frustum.
		var cascade_width = surface_get_width(surface_source(vrays_radiance[0]));
		var cascade_height = surface_get_height(surface_source(vrays_radiance[0]));
		shader_set(frustumseed_u_Shader);
		shader_texture(frustumseed_u_Emissivity, surface_source(render_emissivity));
		shader_texture(frustumseed_u_Absorption, surface_source(render_absorption));
		shader_vec2(frustumseed_u_WorldSize, render_extent, render_extent);
		shader_vec2(frustumseed_u_CascadeSize, cascade_width, cascade_height);
		shader_float(frustumseed_u_FrustumIndex, j);
			surface_set_target_ext(0, surface_source(vrays_radiance[0]));
			surface_set_target_ext(1, surface_source(vrays_transmit[0]));
				draw_clear_alpha(c_black, 0);
				draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, cascade_width, cascade_height);
			surface_reset_target();
		shader_reset();
		
		// Render Ray Extensions for N cascades for all 4 frustums in parallel.
		for(var i = 1; i < render_count; i++) {
			var cascadeN_width = surface_get_width(surface_source(vrays_radiance[i]));
			var cascadeN_height = surface_get_height(surface_source(vrays_radiance[i]));
			var cascadeNm1_width = surface_get_width(surface_source(vrays_radiance[i - 1]));
			var cascadeNm1_height = surface_get_height(surface_source(vrays_radiance[i - 1]));
			
			shader_set(extensions_u_Shader);
			shader_texture(extensions_u_PrevRadiance, surface_source(vrays_radiance[i - 1]));
			shader_texture(extensions_u_PrevTransmit, surface_source(vrays_transmit[i - 1]));
			shader_vec2(extensions_u_PrevSize, cascadeNm1_width, cascadeNm1_height);
			shader_vec2(extensions_u_CascadeSize, cascadeN_width, cascadeN_height);
			shader_vec2(extensions_u_CascadeIndex, i, render_count);
				surface_set_target_ext(0, surface_source(vrays_radiance[i]));
				surface_set_target_ext(1, surface_source(vrays_transmit[i]));
					draw_clear_alpha(c_black, 0);
					draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, cascadeN_width, cascadeN_height);
				surface_reset_target();
			shader_reset();
		}
		
		// Merges Ray Extensions into their appropriate cones / fluence:
		for(var i = (render_count - 1); i >= 0; i--) {
			var cascadeN_width = surface_get_width(surface_source(vrays_radiance[i]));
			var cascadeN_height = surface_get_height(surface_source(vrays_radiance[i]));
			var mergingN_width = surface_get_width(surface_source(merge_radiance[(i+1)%render_count]));
			var mergingN_height = surface_get_height(surface_source(merge_radiance[(i+1)%render_count]));
			var merging_width = surface_get_width(surface_source(merge_radiance[i]));
			var merging_height = surface_get_height(surface_source(merge_radiance[i]));
			
			shader_set(merging_u_Shader);
			shader_texture(merging_u_VraysRadiance, surface_source(vrays_radiance[i]));
			shader_texture(merging_u_VraysTransmit, surface_source(vrays_transmit[i]));
			shader_vec2(merging_u_VraysSize, cascadeN_width, cascadeN_height);
			shader_texture(merging_u_MergingR, surface_source(merge_radiance[(i+1) % render_count]));
			shader_texture(merging_u_MergingT, surface_source(merge_transmit[(i+1) % render_count]));
			shader_vec2(merging_u_MergingSize, mergingN_width, mergingN_height);
			shader_vec2(merging_u_CascadeSize, merging_width, merging_height);
			shader_vec2(merging_u_CascadeIndex, i, render_count);
				surface_set_target_ext(0, surface_source(merge_radiance[i]));
				surface_set_target_ext(1, surface_source(merge_transmit[i]));
					draw_clear_alpha(c_black, 0);
					draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, merging_width, merging_height);
				surface_reset_target();
			shader_reset();
		}
		
		surface_set_target(surface_source(render_frustum[j]));
			draw_clear_alpha(c_black, 0);
			draw_surface(surface_source(merge_radiance[0]), 0, 0);
		surface_reset_target();
	}
	
	// Sum all 4 rendered frustum directions.
	shader_set(fluencesum_u_Shader);
	shader_vec2(fluencesum_u_WorldSize, render_extent, render_extent);
	shader_texture(fluencesum_u_Frustum0, surface_source(render_frustum[0]));
	shader_texture(fluencesum_u_Frustum1, surface_source(render_frustum[1]));
	shader_texture(fluencesum_u_Frustum2, surface_source(render_frustum[2]));
	shader_texture(fluencesum_u_Frustum3, surface_source(render_frustum[3]));
		surface_set_target(surface_source(render_fluence));
		draw_clear_alpha(c_black, 0);
			draw_sprite_stretched(Spr_SurfaceTexture, 0, 0, 0, render_extent, render_extent);
		surface_reset_target();
	shader_reset();

gpu_set_blendenable(gpu_blend);
gpu_set_texrepeat(gpu_texrepeat);
gpu_set_tex_filter(gpu_filter);

var xx = view_hport[0] / render_extent;
draw_surface_ext(surface_source(render_fluence), 0, 0, xx, xx, 0, c_white, 1.0);
draw_set_color(c_yellow);
draw_set_font(Spr_PixelFont);
draw_text(5,  5, "Frame Time:   " + string(delta_time / 1000) + "ms / " + string(1000 * (1.0/game_get_speed(gamespeed_fps))) + "ms");