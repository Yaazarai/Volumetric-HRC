varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform vec2 cascade_index;
uniform float cascade_frustum;
uniform sampler2D cascade_prev;
uniform sampler2D world_emissv;
uniform sampler2D world_absorp;

#define LINEAR(c) vec4(pow(c.rgb, vec3(2.2)), c.a)
#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

// Rotate any UV coordinate wiothin its frustum to be right-frustum facing.
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
		vec4 trans = exp(-absrp);
		vec4 radnc = (1.0 - trans) * emiss;
		radiance += radnc * transmit;
		transmit *= trans;
	}
}

// Merge Near and Far radiance intervals.
vec3 mergeRadiance(vec3 radiance, vec3 transmit, vec3 merged) {
	return radiance + (merged * transmit);
}

// Get the volumetric cone of cascade CN+1.
vec4 getConeVolume(vec2 probe, float index) {
	vec2 samplePos = vec2(floor(probe.x) + index + 0.5, floor(probe.y) + 0.5) / cascade_size;
	return mix(texture2D(cascade_prev, samplePos), vec4(0.0), float(floor(samplePos) != vec2(0.0)));
}

// Merging strategy for for even (B-type) planes.
vec4 mergeConeEven(vec2 probe, float plane, float index, float intrv, float vrays) {
	float left = index, right = index + 1.0;
	vec2 limit = vec2(intrv, -intrv);
	
	// Compute the weight of this cone (total cone width).
	vec2  vrayLL = 2.0 * ((limit * 2.0) + vec2(0.0, ((index * 2.0) * 2.0)));
	vec2  vrayRR = 2.0 * ((limit * 2.0) + vec2(0.0, ((index * 2.0) + 1.0) * 2.0));
	float coneW = abs(atan(vrayRR.y / vrayRR.x) - atan(vrayLL.y / vrayLL.x));
	
	// Trace + Merge left side of the cone.
	vec2 merge_left = probe + (2.0 * (limit + vec2(0.0, left * 2.0)));
	vec4 vrayR_left, vrayT_left;
	trace(probe, merge_left - probe, intrv * 2.0, vrayR_left, vrayT_left);
	vrayR_left *= coneW;
	vec4 cone_left = getConeVolume(merge_left, index * 2.0);
	vrayR_left.rgb = mergeRadiance(vrayR_left.rgb, vrayT_left.rgb, cone_left.rgb);
	
	// Trace + Merge right side of the cone.
	vec2 merge_right = probe + (2.0 * (limit + vec2(0.0, right * 2.0)));
	vec4 vrayR_right, vrayT_right;
	trace(probe, merge_right - probe, intrv * 2.0, vrayR_right, vrayT_right);
	vrayR_right *= coneW;
	vec4 cone_right = getConeVolume(merge_right, (index * 2.0) + 1.0);
	vrayR_right.rgb = mergeRadiance(vrayR_right.rgb, vrayT_right.rgb, cone_right.rgb);
	
	// Interpolate Near + Far radiance samples when planes of CN and CN+1 align (even planes only).
	vec4 near_left = getConeVolume(probe, (index * 2.0));
	vec4 near_right = getConeVolume(probe, (index * 2.0) + 1.0);
	
	// Return the total cone radiance.
	return mix(vrayR_left, near_left, 0.5) + mix(vrayR_right, near_right, 0.5);
}

// Merging Strategy for odd (A-type) planes.
vec4 mergeConeOdd(vec2 probe, float plane, float index, float intrv, float vrays) {
	float left = index, right = index + 1.0;
	vec2 limit = vec2(intrv, -intrv);
	
	// Compute the weight of this cone (total cone width).
	vec2  vrayLL = (limit * 2.0) + vec2(0.0, (index * 2.0) * 2.0);
	vec2  vrayRR = (limit * 2.0) + vec2(0.0, ((index * 2.0) + 1.0) * 2.0);
	float coneW = abs(atan(vrayRR.y / vrayRR.x) - atan(vrayLL.y / vrayLL.x));
	
	// Trace + Merge left side of the cone.
	vec2 merge_left = probe + limit + vec2(0.0, left * 2.0);
	vec4 vrayR_left, vrayT_left;
	trace(probe, merge_left - probe, intrv, vrayR_left, vrayT_left);
	vrayR_left *= coneW;
	vec4 cone_left = getConeVolume(merge_left, index * 2.0);
	vrayR_left.rgb = mergeRadiance(vrayR_left.rgb, vrayT_left.rgb, cone_left.rgb);
	
	// Trace + Merge right side of the cone.
	vec2 merge_right = probe + limit + vec2(0.0, right * 2.0);
	vec4 vrayR_right, vrayT_right;
	trace(probe, merge_right - probe, intrv, vrayR_right, vrayT_right);
	vrayR_right *= coneW;
	vec4 cone_right = getConeVolume(merge_right, (index * 2.0) + 1.0);
	vrayR_right.rgb = mergeRadiance(vrayR_right.rgb, vrayT_right.rgb, cone_right.rgb);
	
	// Return the total cone radiance.
	return vrayR_left + vrayR_right;
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x - (plane * intrv));
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	
	if (mod(plane, 2.0) == 0.0) {
		gl_FragColor = mergeConeEven(probe, plane, index, intrv, vrays);
	} else {
		gl_FragColor = mergeConeOdd(probe, plane, index, intrv, vrays);
	}
	
	gl_FragColor.a = 1.0;
}

/*
	Thsi shader computes only 1/4th of the total frustum radiance.
	So the shader is run 4 times and ray-tracing using rotations into each respective frustum.
*/