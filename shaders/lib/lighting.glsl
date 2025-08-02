#ifndef LIGHTING_GLSL_INCLUDED
#define LIGHTING_GLSL_INCLUDED

#include "/lib/shadow.glsl"
#include "/lib/util.glsl"

// sRGB: 252, 252, 222
const vec3 blockLightColor = vec3(0.974, 0.974, 0.737);
const vec3 ambientColor = vec3(0.1);

const vec3 dayLightColor = vec3(1.0, 1.0, 1.0);
const vec3 dayAmbientColor = vec3(0.15, 0.15, 0.15);

const vec3 nightLightColor = vec3(0.02, 0.05, 0.1);
const vec3 nightAmbientColor = vec3(0.05, 0.05, 0.05);

const vec3 nightVisionAmbientColor = vec3(0.5, 0.5, 0.5);

// Angle cosines relative to the horizon where full
// brightness should be achieved.
// sin(25)  ~  0.258819
// sin(-10) ~ -0.173648
const float daySatAngle = 0.258819;
const float nightSatAngle = -0.173648;

// notes from vanilla lighting implementation
// sunrise: 22800 to 1000
// sunset: 11300 to 13200
// -> night: sun is ~10 degrees below horizon (theta = 100)
// -> day: sun is ~25 degrees above horizon (theta = 75)

// SHADOW-SPACE TRANSFORMATIONS
// ===============================================

vec3 shadowBias(vec3 clipPos, vec3 worldNormal) {
  // project the normal into shadow space.
  vec3 shadowNormal =
      mat3(shadowProjection) * (mat3(shadowModelView) * worldNormal);
  // Multiply by the inverse of the distortion factor. This is an idea inspired
  // by Complementary, but adapted to my own shader.
  shadowNormal = shadowNormal * (DISTORT_A + length(clipPos.xy)) /
                 (DISTORT_A + 1);
  return shadowNormal;
}

vec3 screenToShadowScreen(vec3 screenPos, vec3 normal) {
  // Convert screen space to shadow view space
  vec3 ndcPos = screenPos * 2.0 - 1.0;
  vec3 viewPos = txProjective(gbufferProjectionInverse, ndcPos);
  vec3 feetPlayerPos = txAffine(gbufferModelViewInverse, viewPos);
  vec3 shadowViewPos = txAffine(shadowModelView, feetPlayerPos);

  // Convert to shadow clip space, adjust coordinates
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  shadowClipPos.xyz += shadowBias(shadowClipPos.xyz, normal); // shadow bias
  shadowClipPos.xyz = shadowDistort(shadowClipPos.xyz); // shadow distortion

  // Do perspective divide, convert to screen-space
  vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
  return shadowNdcPos * 0.5 + 0.5;
}

// LIGHTING MODEL
// ===============================================

struct LightingInfo {
  vec4 color;
  vec2 lightmap;
  uint lightFlags;
  vec3 normal;
  float depth;

  vec4 tlColor;
  vec2 tlLightmap;
  uint tlLightFlags;
  vec3 tlNormal;
  float tlDepth;
};

bool readLightInfo(vec2 texcoord, out LightingInfo info) {
  // Fetch data values
  vec4 color1Sample = texture(colortex1, texcoord);
  vec4 color5Sample = texture(colortex5, texcoord);

  info = LightingInfo(texture(colortex0, texcoord),                // color
                      color1Sample.rg,                             // lightmap
                      colorToFlags(color1Sample.b),                // lightFlags
                      colorToNormal(texture(colortex2, texcoord)), // normal
                      texture(depthtex1, texcoord).r,              // depth
                      texture(colortex4, texcoord),                // tlColor
                      color5Sample.rg,                             // tlLightmap
                      colorToFlags(color5Sample.b), // tlLightFlags
                      colorToNormal(texture(colortex6, texcoord)), // tlNormal
                      texture(depthtex0, texcoord).r               // tlDepth
  );

  // gamma corection
  info.color.rgb = pow(info.color.rgb, vec3(SRGB_GAMMA));
  info.lightmap.rg = pow(info.lightmap.rg, vec2(SRGB_GAMMA));

  info.tlColor.rgb = pow(info.tlColor.rgb, vec3(SRGB_GAMMA));
  info.tlLightmap.rg = pow(info.tlLightmap.rg, vec2(SRGB_GAMMA));
  return info.tlDepth == 1.0;
}

#endif