#version 410 compatibility

// ===============================================
// TONEMAP AND COMBINE
// ===============================================

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	// Reinhard-Jodie tonemap
	color.rgb = reinhardJodie(color.rgb);
	// inverse gamma correction
	color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_INV));	
}