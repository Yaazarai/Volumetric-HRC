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
		vec2 ray = (rxy + (delta * ii)) * inv_size;
		if (floor(ray) != vec2(0.0)) break;
		
		vec4 emiss = (texture2D(world_emissv, rotate(ray, cascade_frustum)));
		vec4 absrp = (texture2D(world_absorp, rotate(ray, cascade_frustum)));
		vec4 optic = -absrp * step_length;
		vec4 trans = exp2(optic);
		vec4 radnc = emiss * (1.0 - trans);
		radiance += radnc * transmit;
		transmit *= trans;
	}
}

vec2 getLimit(float intrv, float index) { return vec2(-intrv, -intrv + (index * 2.0)); }
float getSlope(vec2 limit) { return -limit.y / limit.x; }
float coneIndex(float index) { return index + mod(index, 2.0); }
float getYoffset(vec2 probe, float slope) { return mix(cascade_size.x - probe.y, probe.y, step(0.0, slope)); }
vec2  getAxis(vec2 probe, float intrv, float slope) { return probe + vec2(mod(getYoffset(probe, slope) * abs(slope), intrv), 0.0); }
vec2  getMemory(vec2 probe, float intrv, float index) { return vec2(floor(probe.x / intrv) * intrv + index + 0.5, probe.y) / cascade_size; }
vec4  getVolume(vec2 uv) { return texture2D(cascade_prev, uv) * float(floor(uv) == vec2(0.0)); }
vec4  getMerge(vec4 radiance, vec4 transmit, vec4 merged) { return radiance + (merged * transmit); }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
vec2 getPlane(vec2 probe, float intrvN1, float slopeN1) {
	float skew = getYoffset(probe, slopeN1) * abs(slopeN1);
	
	vec2 cardinal = probe - vec2(skew, 0.0);
	cardinal = vec2(ceil(cardinal.x / intrvN1) * intrvN1, cardinal.y);
	cardinal += vec2(skew, 0.0);
	
	float theta = atan(slopeN1);
	float dcos = cos(theta) * length(cardinal - probe);
	probe += vec2(cos(theta), -sin(theta)) * dcos;
	return probe;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct volume { vec4 radiance, transmit, merge; float slope, weight; };
volume getCone(vec2 probe, float index, float side, float intrv, float multiplier) {
	float intrvN1 = intrv * 2.0;
	float indexN1 = (index * 2.0) + side;
	
	vec2 limitN1 = getLimit(intrvN1, coneIndex(indexN1));
	float slopeN1 = getSlope(limitN1);
	
	float theta = atan(slopeN1);
	vec2 offset = probe + (cascade_scalar * multiplier * cos(theta) * limitN1);
	vec2 front = getPlane(offset, intrvN1, slopeN1);
	
	vec4 radiance = vec4(0.0), transmit = vec4(1.0);
	trace(probe, front - probe, length(front - probe), radiance, transmit);
	
	vec4 mergeVolume = getVolume(getMemory(front, intrvN1, indexN1));
	return volume(radiance, transmit, mergeVolume, slopeN1, max(0.5, min(1.0, length(front-probe) / (intrvN1 * cascade_scalar * multiplier))));
}

void main() {
	vec2  texel = in_TexelCoord * cascade_size;
	float intrv = pow(2.0, cascade_index.x);
	float plane = floor(texel.x / intrv);
	float index = floor(texel.x - (plane * intrv));
	vec2  probe = vec2(plane * intrv, texel.y) + vec2(0.5, 0.0);
	
	vec2 limit = getLimit(intrv, coneIndex(index)); 
	float slope = getSlope(limit);
	probe = getAxis(probe, intrv, slope);
	
	// 1x Nearest Scheme:
	volume coneLV = getCone(probe, index, 0.0, intrv, 1.0);
	volume coneRV = getCone(probe, index, 1.0, intrv, 1.0);
	float weight = 0.5 * (atan(coneRV.slope) - atan(coneLV.slope));
	gl_FragColor += getMerge(coneLV.radiance * weight, coneLV.transmit, coneLV.merge);
	gl_FragColor += getMerge(coneRV.radiance * weight, coneRV.transmit, coneRV.merge);
	
	// 2x Interpolation Scheme:
	/*
	volume coneLV_Near = getCone(probe, index, 0.0, intrv, 1.0);
	volume coneRV_Near = getCone(probe, index, 1.0, intrv, 1.0);
	volume coneLV_Far  = getCone(probe, index, 0.0, intrv, 2.0);
	volume coneRV_Far  = getCone(probe, index, 1.0, intrv, 2.0);
	float weight = 0.5 * (atan(coneRV_Near.slope) - atan(coneLV_Near.slope));
	
	gl_FragColor += mix(getMerge(coneLV_Near.radiance * weight, coneLV_Near.transmit, coneLV_Near.merge),
		getMerge(coneLV_Far.radiance * weight, coneLV_Far.transmit, coneLV_Far.merge), coneLV_Near.weight);
	gl_FragColor += mix(getMerge(coneRV_Near.radiance * weight, coneRV_Near.transmit, coneRV_Near.merge),
		getMerge(coneRV_Far.radiance * weight, coneRV_Far.transmit, coneRV_Far.merge), coneRV_Near.weight);
	*/
}