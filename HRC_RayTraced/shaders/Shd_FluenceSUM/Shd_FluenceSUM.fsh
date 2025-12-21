varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform sampler2D frustum_index0;
uniform sampler2D frustum_index1;
uniform sampler2D frustum_index2;
uniform sampler2D frustum_index3;

#define LINEAR(c) vec4(pow(c.rgb, vec3(2.2)), c.a)
#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

vec2 rotate(vec2 pixel, int frust) {
	vec2 offsets[4];
	offsets[0] = in_TexelCoord + pixel.xy; // +1.0, 0.0
	offsets[1] = in_TexelCoord - pixel.yx; // 0.0, -1.0
	offsets[2] = in_TexelCoord - pixel.xy; // -1.0, 0.0
	offsets[3] = in_TexelCoord + pixel.yx; // 0.0, +1.0
	
	offsets[0] = offsets[0].xy;
	offsets[1] = 1.0 - offsets[1].yx;
	offsets[2] = 1.0 - offsets[2].xy;
	offsets[3] = offsets[3].yx;
	return offsets[frust];
}

vec4 sample2D(sampler2D text, vec2 pixel_1, int frust) {
	return texture2D(text, rotate(pixel_1, frust));
}

void main() {
    vec4 radiance = vec4(0.0);
	radiance += sample2D(frustum_index0, vec2(1.0, 0.0) / cascade_size, 0);
	radiance += sample2D(frustum_index1, vec2(1.0, 0.0) / cascade_size, 1);
	radiance += sample2D(frustum_index2, vec2(1.0, 0.0) / cascade_size, 2);
	radiance += sample2D(frustum_index3, vec2(1.0, 0.0) / cascade_size, 3);
	gl_FragColor = vec4(SRGB((radiance / 4.0)).rgb, 1.0);
}

/*
	Sum of Fluence:
		Offset 1px into each frustum, otherwise you get sampling
		overlap between frustums.
		
		Each frustum is "right-facing," in memory. To fix this
		compute the offset in screen-space then rotate the offset
		coordinate so that it is rotated properly into the frustum.
*/