varying vec2 in_TexelCoord;
uniform vec2 cascade_size;
uniform sampler2D frustum_index0;
uniform sampler2D frustum_index1;
uniform sampler2D frustum_index2;
uniform sampler2D frustum_index3;

#define SRGB(c) vec4(pow(c.rgb, vec3(1.0 / 2.2)), 1.0)

vec4 textureRot2D(sampler2D text, int frust) {
	vec2 pixel = vec2(1.0, 0.0) / cascade_size;
	vec2 offsets[4];
	offsets[0] = vec2(in_TexelCoord + pixel.xy).xy;
	offsets[1] = 1.0 - vec2(in_TexelCoord - pixel.yx).yx;
	offsets[2] = 1.0 - vec2(in_TexelCoord - pixel.xy).xy;
	offsets[3] = vec2(in_TexelCoord + pixel.yx).yx;
	return texture2D(text, offsets[frust]);
}

void main() {
    vec4 radiance = vec4(0.0);
	radiance += textureRot2D(frustum_index0, 0);
	radiance += textureRot2D(frustum_index1, 1);
	radiance += textureRot2D(frustum_index2, 2);
	radiance += textureRot2D(frustum_index3, 3);
	gl_FragColor = SRGB((radiance / 4.0));
}

/*
	Sum of Fluence:
		Offset 1px into each frustum, otherwise you get sampling
		overlap between frustums.
		
		Each frustum is "right-facing," in memory. To fix this
		compute the offset in screen-space then rotate the offset
		coordinate so that it is rotated properly into the frustum.
*/