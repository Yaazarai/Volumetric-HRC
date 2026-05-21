varying vec2 in_TexelCoord;
uniform vec2 fluence_extent;
uniform sampler2D fluence_frustum0;
uniform sampler2D fluence_frustum1;
uniform sampler2D fluence_frustum2;
uniform sampler2D fluence_frustum3;

#define SRGB(c) vec4(pow((c).rgb, vec3(1.0 / 2.2)), 1.0)

vec4 textureRot2D(sampler2D text, int frust) {
	vec2 pixel = vec2(1.0, 0.0) / fluence_extent;
	vec2 offsets[4];
	offsets[0] = vec2(in_TexelCoord + pixel.xy).xy;
	offsets[1] = 1.0 - vec2(in_TexelCoord - pixel.yx).yx;
	offsets[2] = 1.0 - vec2(in_TexelCoord - pixel.xy).xy;
	offsets[3] = vec2(in_TexelCoord + pixel.yx).yx;
	return texture2D(text, offsets[frust]);
}

void main() {
    vec4 radiance = vec4(0.0);
	radiance += textureRot2D(fluence_frustum0, 0);
	radiance += textureRot2D(fluence_frustum1, 1);
	radiance += textureRot2D(fluence_frustum2, 2);
	radiance += textureRot2D(fluence_frustum3, 3);
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