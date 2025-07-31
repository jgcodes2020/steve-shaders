#version 410 compatibility

// ===============================================
// LIGHTING PASS
// ===============================================

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
	LightingInfo info;
	if (readLightInfo(texcoord, info)) {
		color = info.color;
		return;
	}

	diffuseLighting(texcoord, info);
	
	// COMPOSITE AND TONEMAP
	// ===============================================

	// composite translucent onto colour
	info.color.rgb = info.color.rgb * (1.0 - info.tlColor.a) + info.tlColor.rgb;

	// this pass is done now
	color.rgb = info.color.rgb;
}