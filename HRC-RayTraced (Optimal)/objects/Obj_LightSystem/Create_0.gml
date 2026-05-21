surface_resize(application_surface, 1024, 1024);
surface_depth_disable(false);
game_set_speed(144*8, gamespeed_fps);

render_index = 0;
render_expanses = 2048;
render_cascades = ceil(log2(render_expanses));

// DS-List of generated surfaces that we can auto re-build.
render_surflist = ds_list_create();

// Frustum Radiance Field for Merging:
render_radiance = array_create(render_cascades, INVALID_SURFACE);

// Scene: Emissivity, Absorption
render_emissivity = surface_build(render_expanses, render_expanses, surface_rgba8unorm, render_surflist);
render_absorption = surface_build(render_expanses, render_expanses, surface_rgba8unorm, render_surflist);
render_linearEmsv = surface_build(render_expanses, render_expanses, surface_rgba8unorm, render_surflist);
render_linearAbsr = surface_build(render_expanses, render_expanses, surface_rgba8unorm, render_surflist);

// Output Final Scene as Fluence:
render_fluences = surface_build(render_expanses, render_expanses, surface_rgba16float, render_surflist);

// Generate Array-Stored Multi-Stage Surfaces:
for(var i = 0; i < render_cascades - 1; i++)
	render_radiance[i] = surface_build(render_expanses, render_expanses, surface_rgba16float, render_surflist);

for(var i = 0; i < 4; i++)
	render_frustums[i] = surface_build(render_expanses, render_expanses, surface_rgba16float, render_surflist);

// Merge Frustum Radiance:
merginghrc_u_Shader     = Shd_MergingHRC;
merginghrc_u_Extent     = uniform(merginghrc_u_Shader, "merging_extent");
merginghrc_u_Indices    = uniform(merginghrc_u_Shader, "merging_indices");
merginghrc_u_MipIndex   = uniform(merginghrc_u_Shader, "merging_mipindex");
merginghrc_u_Prev       = texture(merginghrc_u_Shader, "merging_previous");
merginghrc_u_Emissivity = texture(merginghrc_u_Shader, "merging_emissivity");
merginghrc_u_Absorption = texture(merginghrc_u_Shader, "merging_absorption");

// Sum Fluence from all four Frustums:
fluencehrc_u_Shader     = Shd_FluenceHRC;
fluencehrc_u_Extent     = uniform(fluencehrc_u_Shader, "fluence_extent");
fluencehrc_u_Frustum0   = texture(fluencehrc_u_Shader, "fluence_frustum0");
fluencehrc_u_Frustum1   = texture(fluencehrc_u_Shader, "fluence_frustum1");
fluencehrc_u_Frustum2   = texture(fluencehrc_u_Shader, "fluence_frustum2");
fluencehrc_u_Frustum3   = texture(fluencehrc_u_Shader, "fluence_frustum3");