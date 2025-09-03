varying vec2 in_TexelCoord;
uniform sampler2D prev_radiance;
uniform sampler2D prev_transmit;
uniform vec2 prev_size;
uniform vec2 cascade_size;
uniform vec2 cascade_index;

#define FRUSTUM_COUNT 4.0

void getVolumetricSample(vec2 probe, float index, float interval, float lookupWidth, vec2 resolution, sampler2D txtR, sampler2D txtT, vec4 defValR, vec4 defValT, out vec4 rad, out vec4 trn) {
	vec2 samplePos = vec2(floor(probe.x / interval) * lookupWidth, probe.y) + vec2(0.5, 0.0);
	samplePos = vec2(samplePos.x + index, samplePos.y) / resolution;
	
	float weight = float(floor(samplePos) != vec2(0.0));
	rad = mix(texture2D(txtR, samplePos), defValR, weight);
	trn = mix(texture2D(txtT, samplePos), defValT, weight);
}

void extendRay(vec2 probe, float lo_index, float hi_index, float prev_intrv, float prev_vrays, sampler2D samplerRadiance, sampler2D sampleTransmit, out vec4 radiance, out vec4 transmit) {
	vec2 merge_pos = probe + vec2(prev_intrv, -prev_intrv + (lo_index * 2.0));
	
	vec4  radiance_min, transmit_min, radiance_max, transmit_max;
	getVolumetricSample(probe, lo_index, prev_intrv, prev_vrays, prev_size, prev_radiance, prev_transmit, vec4(0.0), vec4(1.0), radiance_min, transmit_min);
	getVolumetricSample(merge_pos, hi_index, prev_intrv, prev_vrays, prev_size, prev_radiance, prev_transmit, vec4(0.0), vec4(1.0), radiance_max, transmit_max);
	
	radiance = radiance_min + (transmit_min * radiance_max);
	transmit = transmit_min * transmit_max;
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / vrays);
	float index = floor(texel.x) - (plane * vrays);
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	
	float prev_intrv = pow(2.0, cascade_index.x - 1.0);
	float prev_vrays = prev_intrv + 1.0;
	float lower = floor(index / 2.0);
	float upper = ceil(index / 2.0);
	
	vec4 radianceL, radianceU, transmitL, transmitU;
	extendRay(probe, lower, upper, prev_intrv, prev_vrays, prev_radiance, prev_transmit, radianceL, transmitL);
	extendRay(probe, upper, lower, prev_intrv, prev_vrays, prev_radiance, prev_transmit, radianceU, transmitU);
	
	gl_FragData[0] = mix(radianceL, radianceU, 0.5);
	gl_FragData[1] = mix(transmitL, transmitU, 0.5);
}

/*
	For each ray of cN compute the ray-extension from 4 smaller left and right rays of cN-1.
	
		R /\ L
		L \/ R
	
	Two rays of cN-1 diverge and then converge when their directions are swapped.
	For the left ray extent the L -> R ray(s) indices at the near/far planes.
	For the right ray extent the R -> L ray(s) indices at the near/far planes.
	Interpolate the final result to converge back to the extended cN ray direction.
	
	Even ray indices will have the same left/right ray indices as their directions
	in cN will be the same as the lower cascade cN-1.
*/