surface_resize(application_surface, 1024, 1024);
surface_depth_disable(false);
game_set_speed(144, gamespeed_fps);

light_size = 8;

render_extent = 256;
render_count = ceil(log2(render_extent));
render_extent = power(2, render_count);

render_surflist = ds_list_create();
render_radiance = array_create(render_count, INVALID_SURFACE);
render_transmit = array_create(render_count, INVALID_SURFACE);
render_frustums = array_create(4, INVALID_SURFACE);

render_emissv = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
render_absorp = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
render_fluences = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);

for(var i = 0; i < render_count; i++) {
	merge_radiance[i] = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
}

for(var i = 0; i < 4; i++)
	render_frustums[i] = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);

merginghrc_u_Shader         = Shd_MergingHRC;
merginghrc_u_CascadeSize    = uniform(merginghrc_u_Shader, "cascade_size");
merginghrc_u_CascadeIndex   = uniform(merginghrc_u_Shader, "cascade_index");
merginghrc_u_CascadeFrustum = uniform(merginghrc_u_Shader, "cascade_frustum");
merginghrc_u_CascadePrev    = texture(merginghrc_u_Shader, "cascade_prev");
merginghrc_u_Emissivity     = texture(merginghrc_u_Shader, "world_emissv");
merginghrc_u_Absorption     = texture(merginghrc_u_Shader, "world_absorp");

fluencesum_u_Shader         = Shd_FluenceSUM;
fluencesum_u_CascadeSize    = uniform(fluencesum_u_Shader, "cascade_size");
fluencesum_u_Frustum0       = texture(fluencesum_u_Shader, "frustum_index0");
fluencesum_u_Frustum1       = texture(fluencesum_u_Shader, "frustum_index1");
fluencesum_u_Frustum2       = texture(fluencesum_u_Shader, "frustum_index2");
fluencesum_u_Frustum3       = texture(fluencesum_u_Shader, "frustum_index3");