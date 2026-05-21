varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform vec2 cascade_index;
uniform float cascade_frustum;
uniform sampler2D cascade_prev;
uniform sampler2D world_emissv;
uniform sampler2D world_absorp;

#define LINEAR(c) vec4(pow(c.rgb, vec3(2.2)), c.a)
#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

vec4 textureRot2D(sampler2D text, vec2 uv, float frust) {
	vec2 offsets[4];
	offsets[0] = uv.xy, offsets[1] = 1.0 - uv.yx, offsets[2] = 1.0 - uv.xy, offsets[3] = uv.yx;
	return texture2D(text, offsets[int(frust)]);
}

void trace(vec2 rxy, vec2 dxy, float interval, inout vec4 radiance, inout vec4 transmit) {
	float step_size = 1.0;
	vec2 delta = dxy / max(abs(dxy.x), abs(dxy.y));
	float step_length = length(delta) * step_size;
	//vec2 inv_size = 1.0 / cascade_size;
	for(float ii = 0.0; ii < interval; ii += step_size) {
		vec2 ray = (rxy + (delta * ii)) / cascade_size;
		if (floor(ray) != vec2(0.0)) break;
		vec4 emiss = LINEAR(textureRot2D(world_emissv, ray, cascade_frustum));
		vec4 absrp = LINEAR(textureRot2D(world_absorp, ray, cascade_frustum));
		
		vec4 optic = absrp * step_length;
		vec4 trans = exp(-optic);
		vec4 radnc = emiss * (1.0 - trans);
		radiance += radnc * transmit;
		transmit *= trans;
	}
}

vec4 getConeVolume(vec2 probe, float index) {
	vec2 samplePos = vec2(probe.x + index, probe.y) / cascade_size;
	return texture2D(cascade_prev, samplePos) * float(floor(samplePos) == vec2(0.0));
}

vec4 traceAndMerge(vec2 probe, vec2 merge, float intrv, float weight, float index) {
	vec4 radiance = vec4(0.0), transmit = vec4(1.0);
	trace(probe, merge, intrv, radiance, transmit);
	vec4 volume = getConeVolume(probe + merge, index);
	return (radiance * weight) + (volume * transmit);
}

vec4 mergeCones(vec2 probe, float plane, float index, float intrv, float vrays) {
	float left = index, right = index + 1.0;
	vec2 limit = vec2(intrv, -intrv);
	float align = 2.0 - mod(plane, 2.0);
	
	vec2  merge_left = (limit + vec2(0.0, left * 2.0));
	vec2  merge_right = (limit + vec2(0.0, right * 2.0));
	float weight = 0.5 * (atan(merge_right.y, merge_right.x) - atan(merge_left.y, merge_left.x));
	
	vec4 radiance_left = traceAndMerge(probe, merge_left * align, intrv * align, weight, index * 2.0);
	vec4 radiance_right = traceAndMerge(probe, merge_right * align, intrv * align, weight, (index * 2.0) + 1.0);
	
	radiance_left = mix(radiance_left, getConeVolume(probe, (index * 2.0)), 0.5 * (align - 1.0));
	radiance_right = mix(radiance_right, getConeVolume(probe, (index * 2.0) + 1.0), 0.5 * (align - 1.0));
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