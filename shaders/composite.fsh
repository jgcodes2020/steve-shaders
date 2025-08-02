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
  vec3 shadowClipPos;
  vec3 shadowPos =
      screenToShadowScreen(vec3(texcoord, info.depth), info.normal, shadowClipPos);
  float shadow = computeShadowSoft(shadowPos, shadowClipPos.xy);
  if ((info.lightFlags & LTG_NO_SHADOW) != 0) {
    shadow = 1.0;
  }

  vec3 tlShadowClipPos;
  vec3 tlShadowPos =
      screenToShadowScreen(vec3(texcoord, info.tlDepth), info.tlNormal, tlShadowClipPos);
  float tlShadow = tlComputeShadowSoft(tlShadowPos, tlShadowClipPos.xy, info.tlColor.a);
  if ((info.tlLightFlags & LTG_NO_SHADOW) != 0) {
    tlShadow = 1.0;
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
                    max(info.lightmap.g, nightVision);
    vec3 blockTotal = blockLightColor * info.lightmap.r;

    info.color.rgb *= (skyTotal + blockTotal);
  }

  // TRANSLUCENT LIGHTING
  // ===============================================

  if (info.tlDepth < 1.0) {
    vec3 tlSkyLight =
        skyLightColor * clamp(dot(lightDir, info.tlNormal), 0.0, 1.0);
    vec3 tlSkyTotal = (skyAmbientColor + tlSkyLight * tlShadow) *
                      max(info.tlLightmap.g, nightVision);
    vec3 tlBlockTotal = blockLightColor * info.tlLightmap.r;

    info.tlColor.rgb *= (tlSkyTotal + tlBlockTotal);
  }

  // composite translucent onto colour
  color.rgb = info.color.rgb * (1.0 - info.tlColor.a) + info.tlColor.rgb;
}