varying vec2 in_TexelCoord;
uniform sampler2D vrays_radiance;
uniform sampler2D vrays_transmit;
uniform vec2 vrays_size;
uniform sampler2D prev_radiance;
uniform sampler2D prev_transmit;
uniform vec2 prev_size;
uniform vec2 cascade_size;
uniform vec2 cascade_index;

vec4 getSample(vec2 probe, float index, float interval, float lookupWidth, sampler2D sampler, vec2 resolution) {
	vec2 samplePos = vec2(floor(probe.x / interval) * lookupWidth, probe.y) + vec2(0.5, 0.0);
	samplePos = vec2(samplePos.x + index, samplePos.y) / resolution;
	return mix(texture2D(sampler, samplePos), vec4(0.0), float(floor(samplePos) != vec2(0.0)));
}

void mergeCone(vec2 probe, float plane, float intrv, float vrays, float index, float side, out vec4 mergedR, out vec4 mergedT) {
	float coneI = index * 2.0 + side;
	float vrayI = index + side;
	vec2  limit = vec2(intrv, -intrv);
	float align = 2.0 - mod(plane, 2.0);
	
	vec2  vrayL = (limit * 2.0) + vec2(0.0, (coneI * 2.0));
	vec2  vrayR = (limit * 2.0) + vec2(0.0, (coneI + 1.0) * 2.0);
	
	vec4  vrayHR = getSample(probe, vrayI, intrv, vrays, vrays_radiance, vrays_size);
	vec4  vrayHT = getSample(probe, vrayI, intrv, vrays, vrays_transmit, vrays_size);
	
	if (mod(plane, 2.0) == 0.0) {
		vec2  probe2 = probe + (limit + vec2(0.0, vrayI * 2.0));
		vec4  vrayHR2 = getSample(probe2, vrayI, intrv, vrays, vrays_radiance, vrays_size);
		vec4  vrayHT2 = getSample(probe2, vrayI, intrv, vrays, vrays_transmit, vrays_size);
		vrayHR = vrayHR + (vrayHR2 * vrayHT);
		vrayHT = vrayHT * vrayHT2;
	}
	
 	vec2  merge = probe + align * (limit + vec2(0.0, vrayI * 2.0));
	vec4  coneFR = getSample(merge, coneI, 1.0, 1.0, prev_radiance, prev_size);
	vec4  coneFT = getSample(merge, coneI, 1.0, 1.0, prev_transmit, prev_size);
	
	vrayHR *= atan(vrayR.y / vrayR.x) - atan(vrayL.y / vrayL.x);
	mergedR = vrayHR + (coneFR * vrayHT);
	mergedT = vrayHT * coneFT;
	
	if (mod(plane, 2.0) == 0.0) {
		vec4  coneNR = getSample(probe, coneI, 1.0, 1.0, prev_radiance, prev_size);
		vec4  coneNT = getSample(probe, coneI, 1.0, 1.0, prev_transmit, prev_size);
		mergedR = mix(mergedR, coneNR, 0.5);
		mergedT = mix(mergedT, coneNT, 0.5);
	}
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x) - (plane * intrv);
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