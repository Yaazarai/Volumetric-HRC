varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform vec2 cascade_index;
uniform float cascade_frustum;
uniform sampler2D cascade_prev;
uniform sampler2D world_emissv;
uniform sampler2D world_absorp;

#define LINEAR(c) vec4(pow(c.rgb, vec3(2.2)), c.a)
#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

// Rotate any UV coordinate within its frustum to be right-frustum facing.
vec2 rotate(vec2 uvcoord, float frustum) {
	vec2 offsets[4];
	offsets[0] = uvcoord.xy;
	offsets[1] = 1.0 - uvcoord.yx;
	offsets[2] = 1.0 - uvcoord.xy;
	offsets[3] = uvcoord.yx;
	return offsets[int(frustum)];
}

// Raytrace the scene, but using rotated UV coordinates for right-facing only frustums.
void trace(vec2 rxy, vec2 dxy, float interval, out vec4 radiance, out vec4 transmit) {
	radiance = vec4(0.0);
	transmit = vec4(1.0);
	
	///////////////////////////////////////////////
	// Cosign term for sampling higher at an angle.
	float theta = atan(dxy.y / dxy.x);
	float step_size = abs(cos(theta));
	///////////////////////////////////////////////
	
	vec2 delta = dxy / max(abs(dxy.x), abs(dxy.y));
	vec2 inv_size = 1.0 / cascade_size;
	for(float ii = 0.0; ii < interval; ii += step_size) {
		vec2 ray = (rxy + (delta * min(ii, interval - 1.0))) * inv_size;
		if (floor(ray) != vec2(0.0)) break;
		vec4 emiss = LINEAR(texture2D(world_emissv, rotate(ray, cascade_frustum)));
		vec4 absrp = LINEAR(texture2D(world_absorp, rotate(ray, cascade_frustum)));
		
		// Covnert emissivity and absorption to radiance and transmittance.
		vec4 trans = exp(-absrp);
		vec4 radnc = (1.0 - trans) * emiss;
		
		// Merge the radiance and transmittance.
		radiance += radnc * transmit;
		transmit *= trans;
	}
}

// Merge Near and Far radiance intervals (when merging down we do not need to merge/store transmittance).
vec4 mergeRadiance(vec4 radiance, vec4 transmit, vec4 merged) {
	return radiance + (merged * transmit);
}

// Get the volumetric cone of cascade CN+1.
vec4 getConeVolume(vec2 probe, float index) {
	vec2 samplePos = vec2(floor(probe.x) + index + 0.5, floor(probe.y) + 0.5) / cascade_size;
	return mix(texture2D(cascade_prev, samplePos), vec4(0.0, 0.0, 0.0, 0.0), float(floor(samplePos) != vec2(0.0)));
}

// Trace the expected interval then merge with cN+1.
vec4 traceAndMerge(vec2 probe, vec2 merge, float intrv, float weight, float index) {
	vec4 radiance = vec4(0.0), transmit = vec4(1.0);
	trace(probe, merge, intrv, radiance, transmit);
	vec4 cone = getConeVolume(probe + merge, index);
	return mergeRadiance(radiance * weight, transmit, cone);
}

vec4 mergeCones(vec2 probe, float plane, float index, float intrv, float vrays) {
	float left = index, right = index + 1.0;
	vec2 limit = vec2(intrv, -intrv);
	float align = 2.0 - mod(plane, 2.0);
	
	// Compute the weight of this cone (total cone width).
	vec2  merge_left = align * (limit + vec2(0.0, left * 2.0));
	vec2  merge_right = align * (limit + vec2(0.0, right * 2.0));
	float weight = abs(atan(merge_right.y / merge_right.x) - atan(merge_left.y / merge_left.x));
	
	// Trace + Merge left & right side of the cone with the nearest far plane of cN+1.
	vec4 radiance_left = traceAndMerge(probe, merge_left, intrv * align, weight, index * 2.0);
	vec4 radiance_right = traceAndMerge(probe, merge_right, intrv * align, weight, (index * 2.0) + 1.0);
	
	// Fluence interpolation for even planes which have no immediate cN+1 plane to merge with.
	if (floor(mod(plane, 2.0)) == 0.0) {
		vec4 radiance_near_left = getConeVolume(probe, (index * 2.0));
		vec4 radiance_near_right = getConeVolume(probe, (index * 2.0) + 1.0);
		radiance_left = mix(radiance_left, radiance_near_left, 0.5);
		radiance_right = mix(radiance_right, radiance_near_right, 0.5);
	}
	
	// Return the total cone radiance.
	return radiance_left + radiance_right;
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x - (plane * intrv));
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	gl_FragColor = mergeCones(probe, plane, index, intrv, vrays);
}

/*
	This shader computes only 1/4th of the total frustum radiance.
	So the shader is run 4 times and ray-tracing using rotations into each respective frustum.
*/