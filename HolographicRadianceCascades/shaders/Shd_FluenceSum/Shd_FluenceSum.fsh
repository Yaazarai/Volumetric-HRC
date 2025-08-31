varying vec2 in_TexelCoord;
uniform vec2 world_size;
uniform sampler2D frustum_index0;
uniform sampler2D frustum_index1;
uniform sampler2D frustum_index2;
uniform sampler2D frustum_index3;

#define SRGB(c) pow(c.rgb, vec3(1.0 / 2.2))

void main() {
	vec2 pixel = vec2(1.0, 0.0) / world_size;
	vec2 offsets[4];
	offsets[0] = in_TexelCoord + pixel.xy; // +1.0, 0.0
	offsets[1] = in_TexelCoord - pixel.yx; // 0.0, -1.0
	offsets[2] = in_TexelCoord - pixel.xy; // -1.0, 0.0
	offsets[3] = in_TexelCoord + pixel.yx; // 0.0, +1.0
	
    vec3 radiance = vec3(0.0);
	radiance += texture2D(frustum_index0, offsets[0]).rgb;
	radiance += texture2D(frustum_index1, 1.0 - offsets[1].yx).rgb;
	radiance += texture2D(frustum_index2, 1.0 - offsets[2]).rgb;
	radiance += texture2D(frustum_index3, offsets[3].yx).rgb;
	gl_FragColor = vec4(SRGB((radiance / 4.0)), 1.0);
}

/*
	Sum of Fluence:
		Offset 1px into each frustum, otherwise you get sampling
		overlap between frustums.
		
		Each frustum is "right-facing," in memory. To fix this
		compute the offset in screen-space then rotate the offset
		coordinate so that it is rotated properly into the frustum.
*/