#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
  color = pow(color, vec3(SRGB_GAMMA_RCP));
}