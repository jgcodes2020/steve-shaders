#version 410 compatibility

// ===============================================
// TONEMAP AND COMBINE
// ===============================================

#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;

  // Reinhard-Jodie tonemap
  if (depth < 1.0) {
    color.rgb = reinhardJodie(color.rgb);
  }
  // inverse gamma correction
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_INV));
}