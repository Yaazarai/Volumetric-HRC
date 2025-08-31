////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
// The only relavant HRC setting is resolution, which must always be
// square and a power of 2. Clip the final scene from the output.
surface_depth_disable(false);
game_set_speed(144*16.0, gamespeed_fps);
render_extent = 2048;
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

render_count = ceil(log2(render_extent));
render_surflist = ds_list_create();
vrays_radiance = array_create(render_count, INVALID_SURFACE);
vrays_transmit = array_create(render_count, INVALID_SURFACE);
merge_radiance = array_create(render_count, INVALID_SURFACE);
merge_transmit = array_create(render_count, INVALID_SURFACE);
render_frustum = array_create(4, INVALID_SURFACE);

render_emissivity = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
render_absorption = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
render_fluence = surface_build(render_extent, render_extent, surface_rgba8unorm, render_surflist);

for(var i = 0; i < render_count; i++) {
	var interval = power(2, i);
	var rays = interval + 1;
	var cones = interval;
	var raysw = floor(render_extent / interval) * rays;
	var conew = floor(render_extent / interval) * cones;
	vrays_radiance[i] = surface_build(raysw, render_extent, surface_rgba8unorm, render_surflist);
	vrays_transmit[i] = surface_build(raysw, render_extent, surface_rgba8unorm, render_surflist);
	
	merge_radiance[i] = surface_build(conew, render_extent, surface_rgba16float, render_surflist);
	merge_transmit[i] = surface_build(conew, render_extent, surface_rgba8unorm, render_surflist);
}

for(var i = 0; i < 4; i++) {
	render_frustum[i] = surface_build(render_extent, render_extent, surface_rgba16float, render_surflist);
}

frustumseed_u_Shader       = Shd_FrustumSeed;
frustumseed_u_Emissivity   = texture(frustumseed_u_Shader, "emissivity");
frustumseed_u_Absorption   = texture(frustumseed_u_Shader, "absorption");
frustumseed_u_WorldSize    = uniform(frustumseed_u_Shader, "world_size");
frustumseed_u_CascadeSize  = uniform(frustumseed_u_Shader, "cascade_size");
frustumseed_u_FrustumIndex = uniform(frustumseed_u_Shader, "frustum_index");

extensions_u_Shader        = Shd_Extensions;
extensions_u_PrevRadiance  = texture(extensions_u_Shader, "prev_radiance");
extensions_u_PrevTransmit  = texture(extensions_u_Shader, "prev_transmit");
extensions_u_PrevSize      = uniform(extensions_u_Shader, "prev_size");
extensions_u_CascadeSize   = uniform(extensions_u_Shader, "cascade_size");
extensions_u_CascadeIndex  = uniform(extensions_u_Shader, "cascade_index");

merging_u_Shader           = Shd_MergingCones;
merging_u_VraysRadiance    = texture(merging_u_Shader, "vrays_radiance");
merging_u_VraysTransmit    = texture(merging_u_Shader, "vrays_transmit");
merging_u_VraysSize        = uniform(merging_u_Shader, "vrays_size");
merging_u_MergingR         = texture(merging_u_Shader, "prev_radiance");
merging_u_MergingT         = texture(merging_u_Shader, "prev_transmit");
merging_u_MergingSize      = uniform(merging_u_Shader, "prev_size");
merging_u_CascadeSize      = uniform(merging_u_Shader, "cascade_size");
merging_u_CascadeIndex     = uniform(merging_u_Shader, "cascade_index");

fluencesum_u_Shader    = Shd_FluenceSum;
fluencesum_u_WorldSize = uniform(fluencesum_u_Shader, "world_size");
fluencesum_u_Frustum0  = texture(fluencesum_u_Shader, "frustum_index0");
fluencesum_u_Frustum1  = texture(fluencesum_u_Shader, "frustum_index1");
fluencesum_u_Frustum2  = texture(fluencesum_u_Shader, "frustum_index2");
fluencesum_u_Frustum3  = texture(fluencesum_u_Shader, "frustum_index3");