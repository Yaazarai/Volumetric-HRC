varying vec2 in_TexelCoord;
uniform vec2 merging_extent;
uniform vec2 merging_indices;
uniform sampler2D merging_previous;
uniform sampler2D merging_emissivity;
uniform sampler2D merging_absorption;

vec4 coneVolume(vec2 probe, float index) {
	vec2 mem = vec2(probe.x + index, probe.y) / merging_extent;
	return texture2D(merging_previous, mem) * float(clamp(mem, 0.0, 1.0) == mem);
}

vec2 frustRot(vec2 probe) {
	vec2 rot = mix(probe, probe.yx, mod(merging_indices.y, 2.0));
	return mix(rot, merging_extent - rot, step(0.5, mod(merging_indices.y, 3.0)));
}

vec4 traceAndMerge(vec2 probe, vec2 merge, float weight, float palign, float index) {
	vec4 ray = vec4(frustRot(probe), frustRot(merge + probe) - frustRot(probe));
	ray.zw = ray.zw / max(abs(ray.z), abs(ray.w));
	float optlen = length(ray.zw);
	ray /= merging_extent.xyxy;
	
	vec4 radiance = vec4(0.0), transmit = vec4(1.0);
	for(float ii = 0.0; ii < merge.x; ii ++, ray.xy += ray.zw) {
		if (clamp(ray.xy, 0.0, 1.0) != ray.xy) break;
		vec4 tt = exp2(-texture2D(merging_absorption, ray.xy) * optlen);
		vec4 rr = texture2D(merging_emissivity, ray.xy) * (1.0 - tt);
		radiance += rr * transmit;
		transmit *= tt;
	}
	
	radiance = (radiance * weight) + (transmit * coneVolume(probe + merge, index));
	return mix(radiance, coneVolume(probe, index), 0.5 * (palign - 1.0));
}

void main() {
	vec2  texel = in_TexelCoord * merging_extent.xy;
	float intrv = exp2(merging_indices.x);
	float plane = floor(texel.x / intrv);
	float index = mod(texel.x, intrv) - 0.5;
	vec2  probe = vec2(plane * intrv + 0.5, texel.y);
	float align = 2.0 - mod(plane, 2.0);
	vec2  coneL = align * vec2(intrv, -intrv + index * 2.0);
	vec2  coneR = align * vec2(intrv, -intrv + (index + 1.0) * 2.0);
	float wedge = 0.5 * (atan(coneR.y, coneR.x) - atan(coneL.y, coneL.x));
	gl_FragColor = (probe.x < 1.0)? vec4(0.0)
		: traceAndMerge(probe, coneL, wedge, align, index * 2.0)
		+ traceAndMerge(probe, coneR, wedge, align, index * 2.0 + 1.0);
}