#version 330 compatibility

uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightInfo;
layout(location = 2) out vec4 normInfo;

#include "/lib/util.glsl"

void main() {
	color = glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}

	lightInfo = vec4(lmcoord, 0.0, 1.0);
	normInfo = COL_NORMAL_NONE;
}