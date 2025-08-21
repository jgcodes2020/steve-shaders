#ifndef LIGHTING_SHADOW_GLSL_INCLUDED
#define LIGHTING_SHADOW_GLSL_INCLUDED

#include "/lib/common.glsl"
#include "/lib/math/noise.glsl"

// the constant "a" in the distortion function.
const float shadowDistortA = 0.1;

// Distorts a position in clip space to capture more detail near the center
vec3 shadowDistort(vec3 clipPos) {
  // XY distortion function:
  // (a + 1) * R
  // -----------
  // a + norm(R)
  // The extra (a + 1) factor on top improves usage of clip space by
  // stretching the furthest points to r = 1.
  // Any p-norm will work for this, but I chose the 4-norm since it uses
  // the shadow map much better than the 2-norm without being too expensive.

  vec2 hpos   = clipPos.xy;
  float denom = l4norm(hpos) + shadowDistortA;
  clipPos.xy  = fma(hpos, vec2(shadowDistortA), hpos) / denom;

  // Reduce range in Z. This apparently helps when the sun is lower in the sky.
  // clipPos.z *= 0.5;

  return clipPos;
}

// Biases a position in clip space to avoid shadow acne.
vec3 shadowBias(vec3 clipPos, vec3 worldNormal) {
  // project the normal into shadow space.
  vec3 shadowNormal =
    mat3(shadowProjection) * (mat3(shadowModelView) * worldNormal);
  // Multiply by the inverse of the distortion factor. This is an idea inspired
  // by Complementary, but adapted to my own shader.
  shadowNormal =
    shadowNormal * (shadowDistortA + l4norm(clipPos.xy)) / (shadowDistortA + 1.0);
  return shadowNormal;
}

// SOFT SHADOWS
// ===============================================
// PCF with shadow distortion is by far the best way to get good-looking shadows
// in Iris's current pipeline. Ideally we'd be using other techniques but
// this is as good as it gets with one shadow pass.

// The shadow test for opaque surfaces.
// Takes into account the transparency of the surface.
vec3 testShadow(vec3 shadowScreenPos) {
  float test   = texture(shadowtex1, shadowScreenPos);
  float tlTest = texture(shadowtex0, shadowScreenPos);
  vec4 tlColor = texture(shadowcolor0, shadowScreenPos.xy);

  return max(vec3(tlTest), tlColor.rgb * (1.0 - tlColor.a) * test);
}

// Function to perform PCF over an opaque surface.
vec3 computeShadowSoft(vec4 shadowClipPos, vec3 normal, ivec2 pixelCoord) {
  const int sampleCount = ST_SHADOW_SAMPLES * ST_SHADOW_SAMPLES * 4;
  const float offsetMul =
    ST_SHADOW_RADIUS / (float(ST_SHADOW_SAMPLES) * shadowMapResolution);

  vec3 accum = vec3(0.0);
  for (int x = -ST_SHADOW_SAMPLES; x < ST_SHADOW_SAMPLES; x++) {
    for (int y = -ST_SHADOW_SAMPLES; y < ST_SHADOW_SAMPLES; y++) {
      // compute offset, divide by shadow map resolution to put it in pixels
      vec2 offset = offsetMul * vec2(x, y);
      // bias and distort the clip space position
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
      offsetShadowClipPos.xyz += shadowBias(offsetShadowClipPos.xyz, normal);
      offsetShadowClipPos.xyz = shadowDistort(offsetShadowClipPos.xyz);
      // convert to screen space
      vec3 shadowNdcPos    = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
      vec3 shadowScreenPos = fma(shadowNdcPos, vec3(0.5), vec3(0.5));
      // add the shadow test from this pixel
      accum += testShadow(shadowScreenPos);
    }
  }

  return accum / float(sampleCount);
}

#endif