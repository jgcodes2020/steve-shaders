#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
	color = vec4(texture(colortex0, texcoord).rgb, 1.0);
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_RCP));
}