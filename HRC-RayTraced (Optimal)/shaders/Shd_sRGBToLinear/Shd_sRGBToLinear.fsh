varying vec2 in_TexelCoord;

void main() {
	gl_FragColor = pow(texture2D(gm_BaseTexture, in_TexelCoord), vec4(2.2));
}