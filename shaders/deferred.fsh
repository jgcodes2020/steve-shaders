#version 410 compatibility

// ===============================================
// LIGHTING PASS
// ===============================================

#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

in vec2 texcoord;

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
      txLinear(gbufferModelViewInverse, normalize(shadowLightPosition));

  // shadow calculation
  vec4 shadowClipPos = screenToShadowClip(vec3(texcoord, info.depth));
  float shadow = computeShadowSoft(shadowClipPos, info.normal);
  if ((info.lightFlags & LTG_NO_SHADOW) != 0) {
    shadow = 1.0;
  }

  // LIGHTING CONSTANTS
  // ===============================================

  float cosSunToUp = dot(normalize(sunPosition), gbufferModelView[1].xyz);
  float dayFactor = horizonStep(cosSunToUp, daySatAngle);
  float nightFactor = horizonStep(cosSunToUp, nightSatAngle);
  vec3 skyLightColor =
      dayFactor * dayLightColor + nightFactor * nightLightColor;
  vec3 skyAmbientColor =
      dayFactor * dayAmbientColor + nightFactor * nightAmbientColor;

  skyAmbientColor = mix(skyAmbientColor, nightVisionAmbientColor, nightVision);

  // OPAQUE LIGHTING
  // ===============================================

  if (info.depth < 1.0) {
    vec3 skyLight = skyLightColor * clamp(dot(lightDir, info.normal), 0.0, 1.0);
    vec3 skyTotal = (skyAmbientColor + skyLight * shadow) *
                    max(info.light.g, nightVision);
    vec3 blockTotal = blockLightColor * info.light.r;

    info.color.rgb *= (skyTotal + blockTotal);
  }

  // composite translucent onto colour
  color.rgb = info.color.rgb;
}