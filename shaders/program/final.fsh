#version 460 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

// Reinhard-Jodie tonemapping function.
vec3 reinhardJodie(vec3 v) {
  float l = dot(v, LUMA_COEFFS);
  vec3 tv = v / (1.0 + v);
  return mix(v / (1.0 + l), tv, tv);
}

void main() {
	color = vec4(texture(colortex0, texcoord).rgb, 1.0);
  float depth = texture(depthtex0, texcoord).r;

  if (true) {
    color.rgb = reinhardJodie(color.rgb);
  }
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_RCP));
}