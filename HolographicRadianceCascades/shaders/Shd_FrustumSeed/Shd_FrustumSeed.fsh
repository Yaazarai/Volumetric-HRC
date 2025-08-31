varying vec2 in_TexelCoord;
uniform sampler2D emissivity;
uniform sampler2D absorption;
uniform vec2 world_size;
uniform vec2 cascade_size;
uniform float frustum_index;

#define LINEAR(c) pow(c.rgb, vec3(2.2))

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, 0.0);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / vrays);
	vec2  probe = vec2((plane * intrv) + 0.5, texel.y) / world_size;
	
	vec2 offsets[4];
	offsets[0] = probe;
	offsets[1] = 1.0 - probe.yx;
	offsets[2] = 1.0 - probe;
	offsets[3] = probe.yx;
	
	vec3 emiss = LINEAR(texture2D(emissivity, offsets[int(frustum_index)]).rgb);
	vec3 absrp = LINEAR(texture2D(absorption, offsets[int(frustum_index)]).rgb);
	vec3 transmit = exp(-absrp);
	vec3 radiance = (1.0 - transmit) * emiss;
	gl_FragData[0] = vec4(radiance, 1.0);
	gl_FragData[1] = vec4(transmit, 1.0);
}

/*
	c0 has an interval length of 1px, so no raytracing is needed.
	Only comptue radiance/transmittance at each ray's origin.
	Get the probe's origin and rotate position for each frustum.
*/