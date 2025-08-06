#version 410 compatibility

// ===============================================
// TONEMAP AND COMBINE
// ===============================================

#include "/lib/common.glsl"
#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"

#include "/lib/post/fog.glsl"

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  float depth = texture(depthtex0, texcoord).r;

  if (depth < 1.0) {
    color.rgb = reinhardJodie(color.rgb);
  }

  // inverse gamma correction
  color.rgb = pow(color.rgb, vec3(SRGB_GAMMA_INV));

  if (depth < 1.0) {
    // fog
    vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
    vec3 eyePos = txLinear(gbufferModelViewInverse, viewPos);

    float fog = getFog(eyePos);
    color.rgb = mix(color.rgb, fogColor, fog);
  }
}