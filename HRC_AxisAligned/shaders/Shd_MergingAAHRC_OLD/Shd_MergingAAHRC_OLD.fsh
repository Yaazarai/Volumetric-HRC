varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform vec2 cascade_index;
uniform float cascade_frustum;
uniform float cascade_scalar;
uniform sampler2D cascade_prev;
uniform sampler2D world_emissv;
uniform sampler2D world_absorp;

#define LINEAR(c) vec4(pow(c.rgb, vec3(2.2)), c.a)
#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

vec2 rotate(vec2 uvcoord, float frustum) {
	vec2 offsets[4];
	offsets[0] = uvcoord.xy;
	offsets[1] = 1.0 - uvcoord.yx;
	offsets[2] = 1.0 - uvcoord.xy;
	offsets[3] = uvcoord.yx;
	return offsets[int(frustum)];
}

void trace(vec2 rxy, vec2 dxy, float interval, inout vec4 radiance, inout vec4 transmit) {
	float step_size = 1.0;
	vec2 delta = dxy / max(abs(dxy.x), abs(dxy.y));
	float step_length = length(delta) * step_size;
	vec2 inv_size = 1.0 / cascade_size;
	for(float ii = 0.0; ii < interval; ii += step_size) {
		vec2 ray = (rxy + (delta * min(ii, interval - 1.0))) * inv_size;
		if (floor(ray) != vec2(0.0)) break;
		
		vec4 emiss = LINEAR(texture2D(world_emissv, rotate(ray, cascade_frustum)));
		vec4 absrp = LINEAR(texture2D(world_absorp, rotate(ray, cascade_frustum)));
		vec4 optic = -absrp * step_length;
		vec4 trans = exp(optic);
		vec4 radnc = emiss * (1.0 - trans);
		radiance += radnc * transmit;
		transmit *= trans;
	}
}

float getSlope(float index, float intrv) { return 1.0 - (2.0 * (index / intrv)); }
vec2  getLimit(float intrv, float slope) { return vec2(intrv, -slope * intrv); }
vec2  getMemory(vec2 probe, float intrv, float index) { return vec2(floor(probe.x / intrv) * intrv + index + 0.5, probe.y) / cascade_size; }
vec4  getVolume(vec2 uv) { return texture2D(cascade_prev, uv) * float(floor(uv) == vec2(0.0)); }
vec4  getMerge(vec4 radiance, vec4 transmit, vec4 merged) { return radiance + (merged * transmit); }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
vec2  getAxis(vec2 probe, float intrv, float slope) {
	float bias = step(0.0, slope);
	float ypos = mix(cascade_size.x - probe.y, probe.y, bias);
	float skew = abs(ypos * slope);
	float skewX = probe.x + (ypos * abs(slope));
	float axis = mod(skewX, intrv);
	float offset = intrv - floor(intrv - axis);
	return probe + vec2(offset, 0.0);
}

float getOffset(vec2 probe, float intrvN1, float slopeN1) {
    float bias = step(0.0, slopeN1);
    float ypos = mix(cascade_size.x - probe.y, probe.y, bias);
    float skewX = (probe.x - 0.5) - (ypos * abs(slopeN1));
    float phase = mod(skewX, intrvN1);
    return intrvN1 - phase;
}

vec2 getPlane(vec2 probe, vec2 delta, float intrvN1, float slopeN1) {
	vec2  pvec = getLimit(intrvN1, slopeN1);
	
	float xoff = getOffset(probe, intrvN1, slopeN1);
	float ttf = (xoff * pvec.x) / dot(delta, pvec);
	vec2 ffp = probe + (ttf * delta);
	
	float xx = floor(probe.x - ((probe.y - ffp.y) * slopeN1)) + 0.5;
	float yy = floor(probe.y - (probe.y - ffp.y)) + 0.5;
	xoff = getOffset(vec2(xx, yy), intrvN1, slopeN1);
	return vec2(xx, yy) + vec2(xoff, 0.0);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec4 getCone(vec2 probe, float index, float side, float intrv, float slope, vec2 rayLimit, float weight) {
	vec2 offset = probe + (cascade_scalar * rayLimit);
	float intrvN1 = intrv * 2.0;
	float indexN1 = (index * 2.0) + side;
	float slopeN1 = getSlope(indexN1, intrvN1 - 1.0);
	vec2 limitN1 = getLimit(intrvN1, slopeN1);
	vec2 front = getPlane(offset, rayLimit, intrvN1, slopeN1);
	
	vec4 radiance = vec4(0.0), transmit = vec4(1.0);
	trace(probe, front - probe, length(front - probe), radiance, transmit);
	
	probe = getMemory(front, intrvN1, indexN1);
	vec4 volume = getVolume(probe);
	return getMerge(radiance * weight, transmit, volume);
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float vrays = intrv + 1.0;
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x - (plane * intrv));
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	
	float slope = (intrv == 1.0)? 0.0 : getSlope(index, intrv - 1.0);
	vec2 limit = getLimit(intrv, slope);
	probe = getAxis(probe, intrv, slope);
	
	float indexL = index + 0.0;
	float slopeL = getSlope(indexL, intrv);
	vec2  limitL = getLimit(intrv, slopeL);
	
	float indexR = index + 1.0;
	float slopeR = getSlope(indexR, intrv);
	vec2  limitR = getLimit(intrv, slopeR);
	
	vec4  coneVL = vec4(getLimit(intrv, slopeL), getLimit(intrv, slopeR));
	float weight = 0.5 * (atan(coneVL.w / coneVL.z) - atan(coneVL.y / coneVL.x));
	
	vec4 coneL = getCone(probe, index, 0.0, intrv, slopeL, limitL, weight);
	vec4 coneR = getCone(probe, index, 1.0, intrv, slopeR, limitR, weight);
	gl_FragColor = coneL + coneR;
}

/*
	Tracing & Axis-Alignment:
		* Its important to be consistent in how planes are rotated such that
		the lookups between CN and CN+1 are consistent.
		
		CN must trace to exactly the rotated plane/offset of CN+1 for each
		left and right side of the cone.
		
		Each cone of CN rotates to the middle-rotation of the left and right ray directions of the cone.
		Thus when tracing our left/right rays we must trace to the middle-rotation of the cones of those
		left/right rays we're looking up in CN+1.
*/
/*
	Axis-Aligned HRC:
		Similar to HRC we'll utilize spatial interpolation to compute the final fluence between
		axis-aligned planes. The catch however is that the planes we merge with are not aligned
		on any axis.
		
		In order to interpolate we have to get the nearest forward plane(s) P+1 and P+2 as the
		point P+I always lies on or between the probe pairs of [P+1,P+2].
		
		This is because we cannot see planes behind us, so the only option is to interpolate the
		nearest forward planes where the point I+1/2 lies between.
		
		NOTE: This scheme applies to all planes due to axis-alignment rather than right-aligned
		even/odd indexed planes in Vanilla HRC.
*/

/*
	The nearest P+1 and P+2 planes can get gotten by getting the nearest forward plane of P+0
	and then chaining this by getting the nearest forward plane of P+1 giving us all 3 planes.
	
	Probes between axis aligned planes of multiple directions [t-1,t,t+1] will always be within
	one probe of eachother, meaning we only have to trace in a straight line to the furthest probe
	P+2 and return two radiance values: one for P+1 (short ray) and P+2 (long ray) to solve occlusion.
	
	Naively we can just trace two rays, then optimize later to trace only once.
*/