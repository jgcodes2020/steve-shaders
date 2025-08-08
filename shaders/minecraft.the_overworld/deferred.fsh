#version 410 compatibility

// ===============================================
// LIGHTING PASS
// ===============================================

#include "/lib/lighting/model.glsl"
#include "/lib/lighting/shadow.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
layout(pixel_center_integer) in vec4 gl_FragCoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  LightingInfo info;
  if (readLightInfo(texcoord, info)) {
    color = info.color;
    return;
  }

  // SHADOW-SPACE CALCULATIONS
  // ===============================================

  // vector to sunlight
  vec3 lightDir =
    txLinear(gbufferModelViewInverse, shadowLightPosition * 0.01);

  // shadow calculation
  bool isHand = (info.lightFlags & LTG_HAND) != 0;
  vec4 shadowClipPos = screenToShadowClip(vec3(texcoord, info.depth), isHand && firstPersonCamera);
  float shadow =
    computeShadowSoft(shadowClipPos, info.normal, ivec2(gl_FragCoord.xy));
  if ((info.lightFlags & LTG_NO_SHADOW) != 0) {
    shadow = 1.0;
  }

  // LIGHTING CONSTANTS
  // ===============================================

  vec3 skyAmbientColor, skyLightColor;
  getSkyColors(skyAmbientColor, skyLightColor);

  // OPAQUE LIGHTING
  // ===============================================

  vec3 lightMult = diffuseLightModel(
    info.light, info.normal, lightDir, shadow, skyAmbientColor, skyLightColor);
  if (info.depth < 1.0) {
    info.color.rgb *= lightMult;
  }

  // composite translucent onto colour
  color.rgb = info.color.rgb;
}