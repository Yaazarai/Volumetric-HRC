varying vec2 in_TexelCoord;
uniform sampler2D vrays_radiance;
uniform sampler2D vrays_transmit;
uniform vec2 vrays_size;
uniform sampler2D prev_radiance;
uniform sampler2D prev_transmit;
uniform vec2 prev_size;
uniform vec2 cascade_size;
uniform vec2 cascade_index;

void mergeRadiance(vec4 nearR, vec4 nearT, vec4 farR, vec4 farT, out vec4 radiance, out vec4 transmit) {
	radiance = nearR + (farR * nearT);
	transmit = nearT * farT;
}

void getVolume(vec2 probe, float index, float interval, float lookupWidth, vec2 resolution, sampler2D txtR, sampler2D txtT, vec4 defValR, vec4 defValT, out vec4 rad, out vec4 trn) {
	vec2 samplePos = vec2(floor(probe.x / interval) * lookupWidth, probe.y) + vec2(0.5, 0.0);
	samplePos = vec2(samplePos.x + index, samplePos.y) / resolution;
	
	float weight = float(floor(samplePos) != vec2(0.0));
	rad = mix(texture2D(txtR, samplePos), defValR, weight);
	trn = mix(texture2D(txtT, samplePos), defValT, weight);
}

void mergeCone(vec2 probe, float plane, float intrv, float vrays, float index, float side, out vec4 radiance, out vec4 transmit) {
	float coneI = index * 2.0 + side;
	float vrayI = index + side;
	vec2  limit = vec2(intrv, -intrv);
	float align = 2.0 - mod(plane, 2.0);
	
	vec2  merge = probe + align * (limit + vec2(0.0, vrayI * 2.0));
	vec2  vrayLL = (limit * 2.0) + vec2(0.0, (coneI * 2.0));
	vec2  vrayRR = (limit * 2.0) + vec2(0.0, (coneI + 1.0) * 2.0);
	float coneW = atan(vrayRR.y / vrayRR.x) - atan(vrayLL.y / vrayLL.x);
	
	vec4  vrayR, vrayT, coneFarR, coneFarT;
	getVolume(probe, vrayI, intrv, vrays, vrays_size, vrays_radiance, vrays_transmit, vec4(0.0), vec4(1.0), vrayR, vrayT);
	getVolume(merge, coneI, 1.0, 1.0, prev_size, prev_radiance, prev_transmit, vec4(0.0), vec4(1.0), coneFarR, coneFarT);
	
	if (mod(plane, 2.0) == 0.0) {
		vec2 probeFar = probe + (limit + vec2(0.0, vrayI * 2.0));
		vec2 probeNear = probe;
		
		vec4  vrayR_Ext, vrayT_Ext, coneNearR, coneNearT;
		getVolume(probeFar, vrayI, intrv, vrays, vrays_size, vrays_radiance, vrays_transmit, vec4(0.0), vec4(1.0), vrayR_Ext, vrayT_Ext);
		getVolume(probeNear, coneI, 1.0, 1.0, prev_size, prev_radiance, prev_transmit, vec4(0.0), vec4(1.0), coneNearR, coneNearT);
		
		mergeRadiance(vrayR, vrayT, vrayR_Ext, vrayT_Ext, vrayR, vrayT);
		mergeRadiance(vrayR * coneW, vrayT, coneFarR, coneFarT, radiance, transmit);
		
		radiance = mix(radiance, coneNearR, 0.5);
		transmit = mix(transmit, coneNearT, 0.5);
	} else {
		radiance = (vrayR * coneW) + (coneFarR * vrayT);
		transmit = vrayT * coneFarT;
	}
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x - (plane * intrv));
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	
	vec4 radL, radR, trnL, trnR;
	mergeCone(probe, plane, intrv, vrays, index, 0.0, radL, trnL);
	mergeCone(probe, plane, intrv, vrays, index, 1.0, radR, trnR);
	
	gl_FragData[0] = radL + radR;
	gl_FragData[1] = trnL + trnR;
}

/*
	Merging in HRC does not work like merging in Vanilla RC.
		We have two different merging strategies, one for even-index planes and one for odd-index planes.
		Ray-Endpoints of odd-planes perfectly align with Ray-Startpoints of the nearest cN+1 plane.
		However this is not the case for even planes, so we must compute the merging at the closest near
			and far planes, compute merge results for both, then interpolate their fluence to get the
			final merge result for the non-existent plane that even-planes need to merge with.
		
		The general case merging startegy is that we must compute this current cone of cN by sampling
		the rays at the cone's left/right edges and merging each ray with its respective cN+1 cone.
		We then add the merge result of both the merged left/right rays to compute the cone's fluence.
*/